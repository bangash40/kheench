package com.bangash.kheench

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.workDataOf
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Dart bridge to the bundled yt-dlp + FFmpeg engine (channel `kheench/engine`).
 *
 * Every call runs off the main thread; the first one also unpacks the engine,
 * which takes a few seconds on a fresh install.
 */
class EngineChannel(
    private val context: Context,
    private val requestDownloadPermissions: () -> Unit,
) : MethodChannel.MethodCallHandler {

    private val executor = Executors.newCachedThreadPool()
    private val main = Handler(Looper.getMainLooper())
    private val work get() = WorkManager.getInstance(context)

    @Volatile private var cachedVersion: String? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "prepare", "engineVersion" -> run(result) { version() }
            "fetchInfo" -> {
                val url = call.argument<String>("url")
                if (url.isNullOrBlank()) {
                    result.error("BAD_ARGS", "url is required", null)
                    return
                }
                run(result) { fetchInfo(url) }
            }
            "updateEngine" -> run(result) { update() }
            "enqueue" -> {
                requestDownloadPermissions()
                run(result) { enqueue(call) }
            }
            "pause" -> run(result) { stop(call.argument<String>("taskId")!!, pause = true) }
            "cancel" -> run(result) { stop(call.argument<String>("taskId")!!, pause = false) }
            "taskStates" -> run(result) { taskStates() }
            "isUnmetered" -> result.success(isUnmetered())
            "setParallel" -> {
                DownloadWorker.setParallelLimit(context, call.argument<Int>("value") ?: 2)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    /** True on Wi-Fi or another connection that isn't billed by data. */
    private fun isUnmetered(): Boolean {
        val cm = context.getSystemService(ConnectivityManager::class.java) ?: return false
        val caps = cm.getNetworkCapabilities(cm.activeNetwork) ?: return false
        return caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
            caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
    }

    private fun version(): String {
        EngineCore.ensureReady(context)
        cachedVersion?.let { return it }
        val out = YoutubeDL.getInstance()
            .execute(YoutubeDLRequest(emptyList()).addOption("--version"))
            .out.trim()
        cachedVersion = out
        return out
    }

    private fun fetchInfo(url: String): String {
        EngineCore.ensureReady(context)
        val request = YoutubeDLRequest(url)
            .addOption("--dump-single-json")
            .addOption("--no-playlist")
            .addOption("--no-warnings")
        return YoutubeDL.getInstance().execute(EngineCore.withDefaults(context, request)).out
    }

    private fun update(): String {
        EngineCore.ensureReady(context)
        val status = YoutubeDL.getInstance()
            .updateYoutubeDL(context, YoutubeDL.UpdateChannel.STABLE)
        cachedVersion = null
        return status?.name ?: "ALREADY_UP_TO_DATE"
    }

    private fun enqueue(call: MethodCall): String {
        val taskId = call.argument<String>("taskId")!!
        val args = call.argument<List<String>>("args").orEmpty()
        val input = workDataOf(
            DownloadWorker.KEY_TASK_ID to taskId,
            DownloadWorker.KEY_URL to call.argument<String>("url"),
            DownloadWorker.KEY_SELECTOR to call.argument<String>("selector"),
            DownloadWorker.KEY_ARGS to args.toTypedArray(),
            DownloadWorker.KEY_KIND to (call.argument<String>("kind") ?: "video"),
            DownloadWorker.KEY_TITLE to call.argument<String>("title"),
            DownloadWorker.KEY_PARTS to (call.argument<Int>("parts") ?: 1),
        )
        DownloadWorker.paused.remove(taskId)
        val request = OneTimeWorkRequestBuilder<DownloadWorker>()
            .setInputData(input)
            .addTag(DownloadWorker.TAG_ALL)
            .addTag("$TASK_TAG$taskId")
            .build()
        work.enqueueUniqueWork(taskId, ExistingWorkPolicy.REPLACE, request)
        return taskId
    }

    private fun stop(taskId: String, pause: Boolean): Boolean {
        if (pause) DownloadWorker.paused.add(taskId) else DownloadWorker.paused.remove(taskId)
        work.cancelUniqueWork(taskId).result.get()
        YoutubeDL.getInstance().destroyProcessById(taskId)
        if (!pause) java.io.File(context.cacheDir, "tasks/$taskId").deleteRecursively()
        ProgressBus.post(mapOf("taskId" to taskId, "status" to if (pause) "paused" else "cancelled"))
        return true
    }

    /** Current and recently finished tasks, so Dart can catch up after a restart. */
    private fun taskStates(): List<Map<String, Any?>> =
        work.getWorkInfosByTag(DownloadWorker.TAG_ALL).get().mapNotNull { info ->
            val taskId = info.tags.firstOrNull { it.startsWith(TASK_TAG) }
                ?.removePrefix(TASK_TAG) ?: return@mapNotNull null
            val state = when (info.state) {
                WorkInfo.State.ENQUEUED, WorkInfo.State.BLOCKED -> "waiting"
                WorkInfo.State.RUNNING -> "running"
                WorkInfo.State.SUCCEEDED -> "done"
                WorkInfo.State.FAILED -> info.outputData.getString(DownloadWorker.KEY_STATUS) ?: "failed"
                WorkInfo.State.CANCELLED -> "cancelled"
            }
            val data = if (info.state.isFinished) info.outputData else info.progress
            DownloadWorker.eventOf(data) + mapOf("taskId" to taskId, "status" to state)
        }

    private fun run(result: MethodChannel.Result, block: () -> Any?) {
        executor.execute {
            try {
                val value = block()
                main.post { result.success(value) }
            } catch (e: Throwable) {
                Log.w(TAG, "engine call failed", e)
                val message = e.message?.trim().orEmpty().ifEmpty { e.toString() }
                main.post { result.error("ENGINE_ERROR", message, null) }
            }
        }
    }

    companion object {
        private const val CHANNEL = "kheench/engine"
        private const val TAG = "KheenchEngine"
        private const val TASK_TAG = "task:"
    }
}
