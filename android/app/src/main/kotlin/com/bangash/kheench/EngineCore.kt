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
     * Options every yt-dlp call needs:
     * - the site's login cookies, when the user has logged in there;
     * - a JavaScript runtime, which YouTube needs to solve its player
     *   challenges (the engine ships QuickJS as libqjs.so; without it streams
     *   can fail with HTTP 403);
     * - a longer network timeout for slow short-link redirects.
     */
    fun withDefaults(context: Context, request: YoutubeDLRequest, url: String): YoutubeDLRequest {
        // Logged-in session for this site, so private content the account can see works.
        SessionStore.cookiesFor(context, url)?.let { request.addOption("--cookies", it.absolutePath) }
        val qjs = File(context.applicationInfo.nativeLibraryDir, "libqjs.so")
        if (qjs.exists()) request.addOption("--js-runtimes", "quickjs:${qjs.absolutePath}")
        // Some short-link redirects (e.g. vm.tiktok.com) take 10+ seconds.
        request.addOption("--socket-timeout", 30)
        return request
    }
}
