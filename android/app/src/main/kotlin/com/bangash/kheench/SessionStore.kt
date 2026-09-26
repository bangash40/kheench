package com.bangash.kheench

import android.content.Context
import android.net.Uri
import android.webkit.CookieManager
import java.io.File

/**
 * Login sessions per platform, kept as Netscape `cookies.txt` files in the
 * app's private storage (`files/sessions/<platform>.txt`) for yt-dlp's
 * `--cookies`. Passwords never pass through the app; only the cookies the
 * site sets after its own login page.
 */
object SessionStore {

    data class Platform(
        val id: String,
        val loginUrl: String,
        /** Pages whose cookies make up the session. */
        val cookieUrls: List<String>,
        /** Cookie domains written to cookies.txt. */
        val domains: List<String>,
        /** Cookie that only exists once logged in. */
        val sessionCookie: String,
        /** Hosts whose links use this session. */
        val hosts: List<String>,
    )

    val platforms = listOf(
        Platform(
            id = "instagram",
            loginUrl = "https://www.instagram.com/accounts/login/",
            cookieUrls = listOf("https://www.instagram.com"),
            domains = listOf(".instagram.com"),
            sessionCookie = "sessionid",
            hosts = listOf("instagram.com", "instagr.am"),
        ),
        Platform(
            id = "facebook",
            loginUrl = "https://m.facebook.com/login/",
            cookieUrls = listOf("https://www.facebook.com", "https://m.facebook.com"),
            domains = listOf(".facebook.com"),
            sessionCookie = "c_user",
            hosts = listOf("facebook.com", "fb.watch", "fb.com"),
        ),
        Platform(
            id = "x",
            loginUrl = "https://x.com/i/flow/login",
            cookieUrls = listOf("https://x.com"),
            domains = listOf(".x.com", ".twitter.com"),
            sessionCookie = "auth_token",
            hosts = listOf("x.com", "twitter.com", "t.co"),
        ),
        Platform(
            id = "tiktok",
            loginUrl = "https://www.tiktok.com/login",
            cookieUrls = listOf("https://www.tiktok.com"),
            domains = listOf(".tiktok.com"),
            sessionCookie = "sessionid",
            hosts = listOf("tiktok.com"),
        ),
    )

    fun platform(id: String) = platforms.first { it.id == id }

    private fun dir(context: Context) = File(context.filesDir, "sessions").apply { mkdirs() }

    fun file(context: Context, id: String) = File(dir(context), "$id.txt")

    /** { platform: loggedInAtMillis } for saved sessions. */
    fun status(context: Context): Map<String, Long?> = platforms.associate { p ->
        val f = file(context, p.id)
        p.id to (if (f.exists() && f.length() > 0) f.lastModified() else null)
    }

    /** True when the WebView now holds a logged-in session for [p]. */
    fun hasSession(p: Platform): Boolean {
        val cookies = CookieManager.getInstance()
        return p.cookieUrls.any { url ->
            parse(cookies.getCookie(url)).any { (name, value) ->
                name == p.sessionCookie && value.isNotBlank()
            }
        }
    }

    /** Writes the WebView's cookies for [p] as a Netscape cookies.txt. */
    fun save(context: Context, p: Platform) {
        val manager = CookieManager.getInstance()
        manager.flush()
        val pairs = linkedMapOf<String, String>()
        p.cookieUrls.forEach { url -> parse(manager.getCookie(url)).forEach { pairs[it.first] = it.second } }
        // WebView doesn't expose expiry dates; a year ahead is plenty, the
        // site still decides when the session really ends.
        val expiry = System.currentTimeMillis() / 1000 + 365L * 24 * 3600
        val text = buildString {
            append("# Netscape HTTP Cookie File\n")
            for (domain in p.domains) {
                for ((name, value) in pairs) {
                    append("$domain\tTRUE\t/\tTRUE\t$expiry\t$name\t$value\n")
                }
            }
        }
        file(context, p.id).writeText(text)
    }

    /** Deletes the saved session and the WebView's cookies for [p]. */
    fun logout(context: Context, p: Platform) {
        file(context, p.id).delete()
        val manager = CookieManager.getInstance()
        for (url in p.cookieUrls) {
            val host = Uri.parse(url).host ?: continue
            for ((name, _) in parse(manager.getCookie(url))) {
                for (domain in p.domains + host) {
                    manager.setCookie(url, "$name=; Max-Age=0; Path=/; Domain=$domain")
                }
                manager.setCookie(url, "$name=; Max-Age=0; Path=/")
            }
        }
        manager.flush()
    }

    /** The cookies file to pass to yt-dlp for [url], if logged in there. */
    fun cookiesFor(context: Context, url: String): File? {
        val host = Uri.parse(url).host?.lowercase() ?: return null
        val p = platforms.firstOrNull { p ->
            p.hosts.any { host == it || host.endsWith(".$it") }
        } ?: return null
        return file(context, p.id).takeIf { it.exists() && it.length() > 0 }
    }

    private fun parse(header: String?): List<Pair<String, String>> =
        header.orEmpty().split(';').mapNotNull { part ->
            val i = part.indexOf('=')
            if (i <= 0) null else part.substring(0, i).trim() to part.substring(i + 1).trim()
        }
}
