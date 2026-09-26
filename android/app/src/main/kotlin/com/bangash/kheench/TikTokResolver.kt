package com.bangash.kheench

import android.annotation.SuppressLint
import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.webkit.CookieManager
import android.webkit.WebView
import android.webkit.WebViewClient
import org.json.JSONArray
import org.json.JSONObject
import org.json.JSONTokener
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * TikTok answers anything that isn't a real browser with a JavaScript
 * challenge, so yt-dlp can't read it on Android. This loads the page in a
 * hidden WebView (real Chromium, passes the challenge), reads the video data
 * TikTok embeds in the page, and writes it as yt-dlp info JSON plus the
 * session cookies. Downloads then use `--load-info-json` and never touch the
 * challenge.
 */
object TikTokResolver {
    private const val TAG = "KheenchTikTok"
    private const val TIMEOUT_S = 40L
    const val UA =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
            "(KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"

    /** Messages starting with this are shown to the user as they are. */
    const val USER_MESSAGE = "KHEENCH:"

    fun handles(url: String): Boolean {
        val host = Uri.parse(url).host?.lowercase() ?: return false
        return host == "tiktok.com" || host.endsWith(".tiktok.com")
    }

    private fun dir(context: Context) = File(context.filesDir, "tiktok").apply { mkdirs() }
    private fun key(url: String) = url.hashCode().toUInt().toString(16)
    fun infoFile(context: Context, url: String) = File(dir(context), "${key(url)}.info.json")
    fun cookieFile(context: Context, url: String) = File(dir(context), "${key(url)}.cookies.txt")

    /** Blocking; call off the main thread. Returns yt-dlp style info JSON. */
    fun resolve(context: Context, url: String): String {
        val raw = loadPageData(context.applicationContext, url)
            ?: throw IllegalStateException(
                "${USER_MESSAGE}TikTok didn't load. Check your connection, or open the video in the TikTok app to be sure it still exists.",
            )
        val scope = JSONObject(raw).getJSONObject("__DEFAULT_SCOPE__")
        val detail = scope.optJSONObject("webapp.video-detail")
            ?: throw IllegalStateException("${USER_MESSAGE}This TikTok link isn't a video.")
        val status = detail.optInt("statusCode", 0)
        if (status != 0) {
            throw IllegalStateException(
                "ERROR: [TikTok] video not available (status $status: ${detail.optString("statusMsg")})",
            )
        }
        val item = detail.getJSONObject("itemInfo").getJSONObject("itemStruct")
        if (item.has("imagePost")) {
            throw IllegalStateException("${USER_MESSAGE}TikTok photo slideshows aren't supported yet.")
        }
        val info = toInfo(item, url)
        infoFile(context, url).writeText(info.toString())
        writeCookies(context, url)
        return info.toString()
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun loadPageData(context: Context, url: String): String? {
        val result = AtomicReference<String?>(null)
        val latch = CountDownLatch(1)
        val main = Handler(Looper.getMainLooper())
        var web: WebView? = null

        val probe = """(function(){var e=document.getElementById('__UNIVERSAL_DATA_FOR_REHYDRATION__');return e?e.textContent:null})()"""

        main.post {
            val w = WebView(context)
            web = w
            CookieManager.getInstance().setAcceptCookie(true)
            CookieManager.getInstance().setAcceptThirdPartyCookies(w, true)
            w.settings.javaScriptEnabled = true
            w.settings.domStorageEnabled = true
            w.settings.userAgentString = UA
            // Skip images and media: only the page data is needed.
            w.settings.blockNetworkImage = true
            w.settings.mediaPlaybackRequiresUserGesture = true

            fun check() {
                w.evaluateJavascript(probe) { value ->
                    if (latch.count == 0L || value == null || value == "null") return@evaluateJavascript
                    val text = JSONTokener(value).nextValue() as? String ?: return@evaluateJavascript
                    if (text.contains("webapp.video-detail")) {
                        result.set(text)
                        latch.countDown()
                    }
                }
            }

            val poll = object : Runnable {
                override fun run() {
                    if (latch.count == 0L) return
                    check()
                    main.postDelayed(this, 1000)
                }
            }
            w.webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView, url: String) = check()
            }
            w.loadUrl(url)
            main.postDelayed(poll, 1500)
        }

        latch.await(TIMEOUT_S, TimeUnit.SECONDS)
        main.post {
            web?.stopLoading()
            web?.destroy()
        }
        if (result.get() == null) Log.w(TAG, "no page data for $url")
        return result.get()
    }

    /** Builds the fields Kheench's parser and yt-dlp's --load-info-json need. */
    private fun toInfo(item: JSONObject, url: String): JSONObject {
        val id = item.optString("id")
        val video = item.getJSONObject("video")
        val author = item.optJSONObject("author")
        val headers = JSONObject()
            .put("Referer", "https://www.tiktok.com/")
            .put("User-Agent", UA)
        val formats = JSONArray()

        fun add(formatId: String, playUrl: String?, codec: String, w: Int, h: Int, size: Long, kbps: Double?, note: String?) {
            if (playUrl.isNullOrBlank()) return
            formats.put(
                JSONObject()
                    .put("format_id", formatId)
                    .put("url", playUrl)
                    .put("ext", "mp4")
                    .put("protocol", "https")
                    .put("vcodec", codec)
                    .put("acodec", "aac")
                    .put("width", w)
                    .put("height", h)
                    .apply { if (size > 0) put("filesize", size) }
                    .apply { if (kbps != null) put("tbr", kbps) }
                    .apply { if (note != null) put("format_note", note) }
                    .put("http_headers", headers),
            )
        }

        val bitrates = video.optJSONArray("bitrateInfo") ?: JSONArray()
        for (i in 0 until bitrates.length()) {
            val b = bitrates.getJSONObject(i)
            val play = b.optJSONObject("PlayAddr") ?: continue
            val urls = play.optJSONArray("UrlList") ?: continue
            val codec = b.optString("CodecType").let {
                if (it.contains("265") || it.contains("hvc") || it.contains("bytevc1")) "h265" else "h264"
            }
            add(
                formatId = b.optString("GearName", "play_$i"),
                playUrl = urls.optString(0),
                codec = codec,
                w = play.optInt("Width"),
                h = play.optInt("Height"),
                size = play.optLong("DataSize"),
                kbps = b.optDouble("Bitrate").takeIf { !it.isNaN() }?.div(1000),
                note = "No watermark",
            )
        }
        val w = video.optInt("width")
        val h = video.optInt("height")
        if (formats.length() == 0) {
            add("play", video.optString("playAddr"), "h264", w, h, 0, null, "No watermark")
        }
        // Watermarked original, listed last so it's never the default pick.
        add("watermarked", video.optString("downloadAddr"), "h264", w, h, 0, null, "Watermarked")

        return JSONObject()
            .put("_type", "video")
            .put("id", id)
            .put("title", item.optString("desc").ifBlank { "TikTok video $id" })
            .put("uploader", author?.optString("nickname"))
            .put("uploader_id", author?.optString("uniqueId"))
            .put("duration", video.optInt("duration"))
            .put("thumbnail", video.optString("cover").ifBlank { video.optString("originCover") })
            .put("webpage_url", url)
            .put("original_url", url)
            .put("extractor", "TikTok")
            .put("extractor_key", "TikTok")
            .put("webpage_url_domain", "tiktok.com")
            .put("formats", formats)
    }

    private fun writeCookies(context: Context, url: String) {
        val manager = CookieManager.getInstance()
        manager.flush()
        val header = manager.getCookie("https://www.tiktok.com").orEmpty()
        val expiry = System.currentTimeMillis() / 1000 + 24 * 3600
        val text = buildString {
            append("# Netscape HTTP Cookie File\n")
            header.split(';').forEach { part ->
                val i = part.indexOf('=')
                if (i > 0) {
                    append(".tiktok.com\tTRUE\t/\tTRUE\t$expiry\t${part.substring(0, i).trim()}\t${part.substring(i + 1).trim()}\n")
                }
            }
        }
        cookieFile(context, url).writeText(text)
    }
}
