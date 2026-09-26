package com.bangash.kheench

import android.annotation.SuppressLint
import android.app.Activity
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.webkit.CookieManager
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView

/**
 * Shows a platform's own login page. When the site sets its session cookie,
 * the cookies are saved for yt-dlp and the screen closes with RESULT_OK.
 */
class LoginActivity : Activity() {

    private lateinit var platform: SessionStore.Platform
    private lateinit var web: WebView
    private val handler = Handler(Looper.getMainLooper())
    private var done = false

    private val poll = object : Runnable {
        override fun run() {
            checkLoggedIn()
            if (!done) handler.postDelayed(this, 1000)
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        platform = SessionStore.platform(intent.getStringExtra(EXTRA_PLATFORM) ?: "instagram")
        window.statusBarColor = INK

        val bar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setBackgroundColor(INK)
            setPadding(dp(4), dp(4), dp(16), dp(4))
        }
        bar.addView(ImageButton(this).apply {
            setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
            background = ColorDrawable(Color.TRANSPARENT)
            setColorFilter(Color.WHITE)
            contentDescription = "Close"
            setOnClickListener { finish() }
        }, LinearLayout.LayoutParams(dp(48), dp(48)))
        bar.addView(TextView(this).apply {
            text = "Log in to ${title(platform.id)}"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            setPadding(dp(8), 0, 0, 0)
        }, LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f))

        val progress = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 100
            progressTintList = android.content.res.ColorStateList.valueOf(SAFFRON)
        }

        CookieManager.getInstance().setAcceptCookie(true)
        web = WebView(this).apply {
            CookieManager.getInstance().setAcceptThirdPartyCookies(this, true)
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            // Some sites refuse logins from embedded browsers; present as Chrome.
            settings.userAgentString = settings.userAgentString
                .replace("; wv", "")
                .replace(Regex("Version/\\d+\\.\\d+ "), "")
            webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView, url: String) = checkLoggedIn()
            }
            webChromeClient = object : WebChromeClient() {
                override fun onProgressChanged(view: WebView, p: Int) {
                    progress.progress = p
                    progress.visibility = if (p >= 100) View.INVISIBLE else View.VISIBLE
                }
            }
        }

        setContentView(LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            addView(bar, LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT))
            addView(progress, LinearLayout.LayoutParams(MATCH_PARENT, dp(3)))
            addView(web, LinearLayout.LayoutParams(MATCH_PARENT, 0, 1f))
        })

        web.loadUrl(platform.loginUrl)
        handler.postDelayed(poll, 1000)
    }

    private fun checkLoggedIn() {
        if (done || !SessionStore.hasSession(platform)) return
        done = true
        // Give the site a moment to set its remaining cookies.
        handler.postDelayed({
            SessionStore.save(this, platform)
            setResult(RESULT_OK)
            finish()
        }, 1500)
    }

    @Deprecated("Handles WebView back navigation")
    override fun onBackPressed() {
        if (web.canGoBack()) web.goBack() else super.onBackPressed()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        web.destroy()
        super.onDestroy()
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    companion object {
        const val EXTRA_PLATFORM = "platform"
        private const val INK = 0xFF12262B.toInt()
        private const val SAFFRON = 0xFFF2A93B.toInt()

        fun title(id: String) = when (id) {
            "instagram" -> "Instagram"
            "facebook" -> "Facebook"
            "x" -> "X"
            "tiktok" -> "TikTok"
            else -> id
        }
    }
}
