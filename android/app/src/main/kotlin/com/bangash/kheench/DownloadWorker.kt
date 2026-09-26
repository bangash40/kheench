package com.bangash.kheench

import android.content.Context
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.SystemClock
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.Data
import androidx.work.ForegroundInfo
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLException
import com.yausername.youtubedl_android.YoutubeDLRequest
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.runInterruptible
import java.io.File
import java.util.Collections

/**
 * Runs one yt-dlp download in the background, then publishes the file to
 * shared storage. Progress goes to Dart through [ProgressBus].
 */
class DownloadWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {

    private val taskId = inputData.getString(KEY_TASK_ID)!!
    private val title = inputData.getString(KEY_TITLE) ?: "Download"
    private val kind = inputData.getString(KEY_KIND) ?: "video"
    private val parts = inputData.getInt(KEY_PARTS, 1).coerceAtLeast(1)

    private var part = 0
    private var stage = "waiting"
    private var lastEvent = 0L
    private var lastNotify = 0L

    override suspend fun doWork(): Result {
        val dir = File(applicationContext.cacheDir, "tasks/$taskId").apply { mkdirs() }
        DownloadNotifications.ensureChannels(applicationContext)
        emit(stage = "waiting", percent = 0.0)
        updateForeground("Waiting for a free slot", 0, indeterminate = true)

        waitForSlot()
        try {
            EngineCore.ensureReady(applicationContext)
            stage = "downloading"
            emit(stage = stage, percent = 0.0)
            updateForeground("Starting", 0, indeterminate = true)

            val request = YoutubeDLRequest(inputData.getString(KEY_URL)!!)
                .addOption("-f", inputData.getString(KEY_SELECTOR) ?: "bv*+ba/b")
                .addOption("-o", "${dir.absolutePath}/%(title).120B [%(id)s].%(ext)s")
                .addOption("--no-playlist")
                .addOption("--no-mtime")
                .addCommands(inputData.getStringArray(KEY_ARGS)?.toList().orEmpty())

            EngineCore.withDefaults(applicationContext, request, inputData.getString(KEY_URL)!!)
            runWithRetries(request)

            stage = "saving"
            emit(stage = stage, percent = 100.0)
            updateForeground("Saving", 100, indeterminate = true)
            val file = finishedFile(dir) ?: throw IllegalStateException("Download produced no file")
            val published = MediaPublisher.publish(applicationContext, file, kind)
            dir.deleteRecursively()

            val mime = MediaPublisher.mimeFor(file.extension.lowercase(), kind == "audio")
            DownloadNotifications.done(applicationContext, taskId, title, published.uri, mime)
            val output = workDataOf(
                KEY_STATUS to "done",
                KEY_OUT_URI to published.uri,
                KEY_OUT_PATH to published.path,
                KEY_OUT_NAME to published.name,
                KEY_OUT_SIZE to published.size,
                KEY_OUT_MIME to mime,
            )
            ProgressBus.post(eventOf(output) + ("taskId" to taskId))
            return Result.success(output)
        } catch (e: CancellationException) {
            // Pause keeps partial files so yt-dlp can resume; cancel removes them.
            if (!paused.remove(taskId)) {
                dir.deleteRecursively()
                // Covers "Cancel" tapped on the notification.
                ProgressBus.post(mapOf("taskId" to taskId, "status" to "cancelled"))
            }
            YoutubeDL.getInstance().destroyProcessById(taskId)
            throw e
        } catch (e: YoutubeDL.CanceledException) {
            if (!paused.remove(taskId)) dir.deleteRecursively()
            return Result.failure(workDataOf(KEY_STATUS to "cancelled"))
        } catch (e: Throwable) {
            Log.w(TAG, "download $taskId failed", e)
            dir.deleteRecursively()
            val message = e.message?.trim().orEmpty().ifEmpty { e.toString() }
            DownloadNotifications.failed(applicationContext, taskId, title)
            val output = workDataOf(KEY_STATUS to "failed", KEY_ERROR to message.take(4000))
            ProgressBus.post(eventOf(output) + ("taskId" to taskId))
            return Result.failure(output)
        } finally {
            synchronized(active) { active.remove(taskId) }
        }
    }

    /**
     * YouTube sometimes refuses a stream with a one-off HTTP 403; trying again
     * (yt-dlp resumes partial files) usually works.
     */
    private suspend fun runWithRetries(request: YoutubeDLRequest) {
        var attempt = 0
        while (true) {
            try {
                runInterruptible(Dispatchers.IO) {
                    YoutubeDL.getInstance().execute(request, taskId) { progress, eta, line ->
                        onOutput(progress, eta, line)
                    }
                }
                return
            } catch (e: YoutubeDLException) {
                val transient = e.message.orEmpty().contains("HTTP Error 403")
                if (!transient || attempt >= MAX_RETRIES) throw e
                attempt++
                Log.i(TAG, "download $taskId got HTTP 403, retry $attempt")
                part = 0
                stage = "downloading"
                delay(1500L * attempt)
            }
        }
    }

    private suspend fun waitForSlot() {
        while (true) {
            val limit = parallelLimit(applicationContext)
            synchronized(active) {
                if (active.size < limit) {
                    active.add(taskId)
                    return
                }
            }
            delay(700)
        }
    }

    private fun onOutput(progress: Float, eta: Long, line: String) {
        when {
            line.startsWith("[download] Destination:") ||
                line.endsWith("has already been downloaded") -> part = (part + 1).coerceAtMost(parts)
            line.startsWith("[Merger]") -> stage = "merging"
            line.startsWith("[ExtractAudio]") || line.startsWith("[VideoConvertor]") -> stage = "converting"
        }
        val now = SystemClock.elapsedRealtime()
        if (now - lastEvent < 300) return
        lastEvent = now

        val filePercent = progress.coerceIn(0f, 100f).toDouble()
        val overall = if (stage == "downloading") {
            ((part.coerceAtLeast(1) - 1) * 100 + filePercent) / parts
        } else {
            100.0
        }
        val speed = SPEED.find(line)?.groupValues?.get(1)?.replace("i", "")
        emit(stage, overall, speed, if (stage == "downloading") eta else -1)

        if (now - lastNotify >= 1000) {
            lastNotify = now
            val text = when (stage) {
                "merging" -> "Merging video and audio"
                "converting" -> "Converting audio"
                else -> buildString {
                    append("${overall.toInt()}%")
                    if (speed != null) append(" · $speed")
                    if (eta > 0) append(" · ${formatEta(eta)} left")
                }
            }
            setProgressAsync(workDataOf(KEY_PERCENT to overall, KEY_STAGE to stage))
            updateForegroundAsync(text, overall.toInt(), stage != "downloading")
        }
    }

    private fun emit(stage: String, percent: Double, speed: String? = null, eta: Long = -1) {
        ProgressBus.post(
            mapOf(
                "taskId" to taskId,
                "status" to "running",
                "stage" to stage,
                "percent" to percent,
                "speed" to speed,
                "eta" to eta,
            ),
        )
    }

    private suspend fun updateForeground(text: String, percent: Int, indeterminate: Boolean) {
        try {
            setForeground(foregroundInfo(text, percent, indeterminate))
        } catch (e: Exception) {
            // Can fail if the app is in the background on Android 12+; the
            // download still runs, just without the ongoing notification.
            Log.w(TAG, "could not show progress notification", e)
        }
    }

    private fun updateForegroundAsync(text: String, percent: Int, indeterminate: Boolean) {
        try {
            setForegroundAsync(foregroundInfo(text, percent, indeterminate))
        } catch (e: Exception) {
            Log.w(TAG, "could not update progress notification", e)
        }
    }

    private fun foregroundInfo(text: String, percent: Int, indeterminate: Boolean): ForegroundInfo {
        val n = DownloadNotifications.progress(applicationContext, id, title, text, percent, indeterminate)
        val nid = DownloadNotifications.progressId(taskId)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ForegroundInfo(nid, n, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            ForegroundInfo(nid, n)
        }
    }

    private fun finishedFile(dir: File): File? = dir.listFiles()
        ?.filter { f ->
            f.isFile && !f.name.endsWith(".part") && !f.name.endsWith(".ytdl") &&
                !f.name.contains(".temp.") && !f.name.endsWith(".json")
        }
        ?.maxByOrNull { it.length() }

    companion object {
        private const val TAG = "KheenchDownload"
        private const val MAX_RETRIES = 2
        const val TAG_ALL = "kheench-download"

        const val KEY_TASK_ID = "taskId"
        const val KEY_URL = "url"
        const val KEY_SELECTOR = "selector"
        const val KEY_ARGS = "args"
        const val KEY_KIND = "kind"
        const val KEY_TITLE = "title"
        const val KEY_PARTS = "parts"

        const val KEY_STATUS = "status"
        const val KEY_STAGE = "stage"
        const val KEY_PERCENT = "percent"
        const val KEY_ERROR = "error"
        const val KEY_OUT_URI = "uri"
        const val KEY_OUT_PATH = "path"
        const val KEY_OUT_NAME = "name"
        const val KEY_OUT_SIZE = "size"
        const val KEY_OUT_MIME = "mime"

        private val SPEED = Regex("""at\s+([\d.]+\s*[KMG]i?B/s)""")

        /** Tasks paused by the user; their partial files are kept for resume. */
        val paused: MutableSet<String> = Collections.synchronizedSet(mutableSetOf())

        private val active = mutableSetOf<String>()

        private const val PREFS = "kheench_downloads"
        private const val PREF_PARALLEL = "parallel"

        /** Parallel download limit (1–3), kept across restarts. */
        fun parallelLimit(context: Context) =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getInt(PREF_PARALLEL, 2).coerceIn(1, 3)

        fun setParallelLimit(context: Context, value: Int) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putInt(PREF_PARALLEL, value.coerceIn(1, 3)).apply()
        }

        fun eventOf(data: Data): Map<String, Any?> = data.keyValueMap

        private fun formatEta(seconds: Long): String = when {
            seconds >= 3600 -> "${seconds / 3600}h ${(seconds % 3600) / 60}m"
            seconds >= 60 -> "${seconds / 60}m ${seconds % 60}s"
            else -> "${seconds}s"
        }
    }
}
