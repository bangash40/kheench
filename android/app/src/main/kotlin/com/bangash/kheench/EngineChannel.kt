package com.bangash.kheench

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.yausername.ffmpeg.FFmpeg
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
class EngineChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    private val executor = Executors.newCachedThreadPool()
    private val main = Handler(Looper.getMainLooper())

    @Volatile private var ready = false
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
            else -> result.notImplemented()
        }
    }

    private fun ensureReady() {
        if (ready) return
        synchronized(this) {
            if (ready) return
            YoutubeDL.getInstance().init(context)
            FFmpeg.getInstance().init(context)
            ready = true
        }
    }

    private fun version(): String {
        ensureReady()
        cachedVersion?.let { return it }
        val out = YoutubeDL.getInstance()
            .execute(YoutubeDLRequest(emptyList()).addOption("--version"))
            .out.trim()
        cachedVersion = out
        return out
    }

    private fun fetchInfo(url: String): String {
        ensureReady()
        val request = YoutubeDLRequest(url)
            .addOption("--dump-single-json")
            .addOption("--no-playlist")
            .addOption("--no-warnings")
        return YoutubeDL.getInstance().execute(request).out
    }

    private fun update(): String {
        ensureReady()
        val status = YoutubeDL.getInstance()
            .updateYoutubeDL(context, YoutubeDL.UpdateChannel.STABLE)
        cachedVersion = null
        return status?.name ?: "ALREADY_UP_TO_DATE"
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
    }
}
