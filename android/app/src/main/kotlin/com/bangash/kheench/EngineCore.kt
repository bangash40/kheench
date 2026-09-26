package com.bangash.kheench

import android.content.Context
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import java.io.File

/** One-time engine setup shared by the method channel and download workers. */
object EngineCore {
    @Volatile private var ready = false

    fun ensureReady(context: Context) {
        if (ready) return
        synchronized(this) {
            if (ready) return
            val app = context.applicationContext
            YoutubeDL.getInstance().init(app)
            FFmpeg.getInstance().init(app)
            ready = true
        }
    }

    /**
     * Options every yt-dlp call needs. YouTube wants a JavaScript runtime to
     * solve its player challenges; the engine ships QuickJS as libqjs.so, so
     * point yt-dlp at it (otherwise streams can fail with HTTP 403).
     */
    fun withDefaults(context: Context, request: YoutubeDLRequest): YoutubeDLRequest {
        val qjs = File(context.applicationInfo.nativeLibraryDir, "libqjs.so")
        if (qjs.exists()) request.addOption("--js-runtimes", "quickjs:${qjs.absolutePath}")
        return request
    }
}
