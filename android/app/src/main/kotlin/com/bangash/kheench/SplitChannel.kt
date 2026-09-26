package com.bangash.kheench

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.Transformer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Cuts a video into WhatsApp-status-length parts with Media3 Transformer
 * (channel `kheench/split`, progress on `kheench/split_progress`).
 * Parts are saved to Movies/Kheench/Split/<video name>/part-01.mp4 ...
 */
class SplitChannel(private val activity: Activity) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val main = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private var sink: EventChannel.EventSink? = null
    private var pendingPick: MethodChannel.Result? = null
    private var job: Job? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
        EventChannel(messenger, PROGRESS).setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickVideo" -> pickVideo(result)
            "probe" -> io.execute {
                val info = try {
                    probe(Uri.parse(call.argument<String>("uri")!!))
                } catch (e: Exception) {
                    null
                }
                main.post { result.success(info) }
            }
            "split" -> split(call, result)
            "cancel" -> {
                job?.cancel()
                result.success(true)
            }
            "share" -> result.success(share(call.argument<List<String>>("uris").orEmpty(), call.argument<Boolean>("whatsapp") == true))
            else -> result.notImplemented()
        }
    }

    // --- picking & probing ---------------------------------------------

    private fun pickVideo(result: MethodChannel.Result) {
        pendingPick?.success(null)
        pendingPick = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("video/*")
        try {
            activity.startActivityForResult(intent, REQUEST_PICK)
        } catch (e: ActivityNotFoundException) {
            pendingPick = null
            result.success(null)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK) return false
        val result = pendingPick ?: return true
        pendingPick = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
        } else {
            try {
                activity.contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } catch (_: SecurityException) {
                // Not every provider offers lasting access; this session is enough.
            }
            result.success(uri.toString())
        }
        return true
    }

    /** { durationMs, width, height, name, size } */
    private fun probe(uri: Uri): Map<String, Any?> {
        val r = MediaMetadataRetriever()
        try {
            r.setDataSource(activity, uri)
            fun meta(key: Int) = r.extractMetadata(key)?.toLongOrNull()
            var w = meta(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)
            var h = meta(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)
            val rotation = meta(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION) ?: 0
            if (rotation == 90L || rotation == 270L) w = h.also { h = w }
            var name: String? = null
            var size: Long? = null
            activity.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)
                ?.use { c ->
                    if (c.moveToFirst()) {
                        name = c.getString(0)
                        size = if (c.isNull(1)) null else c.getLong(1)
                    }
                }
            return mapOf(
                "durationMs" to meta(MediaMetadataRetriever.METADATA_KEY_DURATION),
                "width" to w,
                "height" to h,
                "name" to (name ?: uri.lastPathSegment ?: "video.mp4"),
                "size" to size,
            )
        } finally {
            r.release()
        }
    }

    // --- splitting ---------------------------------------------------------

    private fun split(call: MethodCall, result: MethodChannel.Result) {
        if (job != null) {
            result.error("BUSY", "A split is already running", null)
            return
        }
        val uri = Uri.parse(call.argument<String>("uri")!!)
        val partMs = (call.argument<Number>("partSeconds")!!.toLong() * 1000).coerceAtLeast(1000)
        val start = call.argument<Number>("trimStartMs")?.toLong() ?: 0L
        val end = call.argument<Number>("trimEndMs")!!.toLong()
        val folder = safeName(call.argument<String>("name") ?: "video")

        val ranges = partRanges(start, end, partMs)
        if (ranges.isEmpty()) {
            result.error("EMPTY", "Nothing to split", null)
            return
        }
        job = Job(uri, ranges, folder, result).also { it.next() }
    }

    /** Parts of [partMs]; a last sliver under 1 s joins the part before it. */
    private fun partRanges(start: Long, end: Long, partMs: Long): List<LongRange> {
        val out = mutableListOf<LongRange>()
        var s = start
        while (s < end) {
            val e = minOf(s + partMs, end)
            if (e - s < 1000 && out.isNotEmpty()) {
                out[out.lastIndex] = out.last().first..e
            } else {
                out += s..e
            }
            s = e
        }
        return out
    }

    private inner class Job(
        val uri: Uri,
        val ranges: List<LongRange>,
        val folder: String,
        val result: MethodChannel.Result,
    ) {
        private var index = -1
        private var transformer: Transformer? = null
        private val saved = mutableListOf<Map<String, Any?>>()
        private val holder = ProgressHolder()
        private var cancelled = false
        private val tmpDir = File(activity.cacheDir, "split").apply { mkdirs() }

        private val poll = object : Runnable {
            override fun run() {
                val t = transformer ?: return
                val state = t.getProgress(holder)
                val partPct = if (state == Transformer.PROGRESS_STATE_AVAILABLE) holder.progress else 0
                emit(((index * 100 + partPct).toDouble() / ranges.size))
                main.postDelayed(this, 300)
            }
        }

        fun next() {
            index++
            if (cancelled) return
            if (index >= ranges.size) {
                finish()
                return
            }
            val range = ranges[index]
            val out = File(tmpDir, "part-%02d.mp4".format(index + 1)).apply { delete() }
            val item = MediaItem.Builder()
                .setUri(uri)
                .setClippingConfiguration(
                    MediaItem.ClippingConfiguration.Builder()
                        .setStartPositionMs(range.first)
                        .setEndPositionMs(range.last)
                        .build(),
                )
                .build()
            val t = Transformer.Builder(activity)
                .setVideoMimeType(MimeTypes.VIDEO_H264)
                .setAudioMimeType(MimeTypes.AUDIO_AAC)
                // Copy the untouched middle of each part; only re-encode the edges.
                .experimentalSetTrimOptimizationEnabled(true)
                .addListener(object : Transformer.Listener {
                    override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                        main.removeCallbacks(poll)
                        io.execute { publish(out) }
                    }

                    override fun onError(
                        composition: Composition,
                        exportResult: ExportResult,
                        exception: ExportException,
                    ) {
                        main.removeCallbacks(poll)
                        Log.w(TAG, "part ${index + 1} failed", exception)
                        fail(exception.message ?: "Splitting failed")
                    }
                })
                .build()
            transformer = t
            t.start(EditedMediaItem.Builder(item).build(), out.absolutePath)
            main.postDelayed(poll, 300)
        }

        private fun publish(file: File) {
            try {
                val p = MediaPublisher.publish(
                    activity,
                    open = { file.inputStream() },
                    name = "part-%02d.mp4".format(index + 1),
                    kind = "video",
                    subfolder = "Split/$folder",
                    sizeHint = file.length(),
                )
                file.delete()
                saved += mapOf("uri" to p.uri, "path" to p.path, "name" to p.name, "size" to p.size)
                main.post { next() }
            } catch (e: Exception) {
                Log.w(TAG, "saving part failed", e)
                main.post { fail(e.message ?: "Couldn't save a part") }
            }
        }

        private fun emit(percent: Double) {
            sink?.success(mapOf("part" to index + 1, "parts" to ranges.size, "percent" to percent))
        }

        private fun finish() {
            emit(100.0)
            job = null
            result.success(saved)
        }

        private fun fail(message: String) {
            job = null
            tmpDir.listFiles()?.forEach { it.delete() }
            result.error("SPLIT_FAILED", message, saved)
        }

        fun cancel() {
            cancelled = true
            main.removeCallbacks(poll)
            transformer?.cancel()
            tmpDir.listFiles()?.forEach { it.delete() }
            job = null
            result.error("CANCELLED", "Cancelled", saved)
        }
    }

    // --- sharing -----------------------------------------------------------

    /** Sends all parts in order; straight to WhatsApp when asked and installed. */
    private fun share(uris: List<String>, whatsapp: Boolean): Boolean {
        if (uris.isEmpty()) return false
        val list = ArrayList(uris.map { Uri.parse(it) })
        val send = Intent(Intent.ACTION_SEND_MULTIPLE).apply {
            type = "video/mp4"
            putParcelableArrayListExtra(Intent.EXTRA_STREAM, list)
            // Read access for every part needs them in ClipData too.
            clipData = ClipData.newRawUri(null, list.first()).also { clip ->
                list.drop(1).forEach { clip.addItem(ClipData.Item(it)) }
            }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        if (whatsapp) {
            for (pkg in listOf("com.whatsapp", "com.whatsapp.w4b")) {
                try {
                    activity.startActivity(Intent(send).setPackage(pkg))
                    return true
                } catch (_: ActivityNotFoundException) {
                }
            }
        }
        return try {
            activity.startActivity(Intent.createChooser(send, null))
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    private fun safeName(name: String): String =
        name.substringBeforeLast('.')
            .replace(Regex("""[\\/:*?"<>|\n\r\t]"""), " ")
            .replace(Regex("""\s+"""), " ")
            .trim()
            .take(60)
            .ifEmpty { "video" }

    companion object {
        private const val CHANNEL = "kheench/split"
        private const val PROGRESS = "kheench/split_progress"
        private const val TAG = "KheenchSplit"
        private const val REQUEST_PICK = 5001
    }
}
