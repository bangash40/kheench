package com.bangash.kheench

import android.Manifest
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.view.textclassifier.TextClassifier
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var files: FileChannel? = null
    private var status: StatusChannel? = null
    private var accounts: AccountsChannel? = null
    private var split: SplitChannel? = null
    private var shareChannel: MethodChannel? = null

    /** Text shared into the app before Flutter was ready to take it. */
    private var pendingShare: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EngineChannel(applicationContext) { runOnUiThread(::requestDownloadPermissions) }
            .register(messenger)
        ProgressBus.register(messenger)
        files = FileChannel(this).also { it.register(messenger) }
        status = StatusChannel(this).also { it.register(messenger) }
        accounts = AccountsChannel(this).also { it.register(messenger) }
        split = SplitChannel(this).also { it.register(messenger) }

        pendingShare = takeShared(intent)
        shareChannel = MethodChannel(messenger, "kheench/share").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "takePending" -> {
                        result.success(pendingShare)
                        pendingShare = null
                    }
                    "clipboardHint" -> result.success(clipboardHint())
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val text = takeShared(intent) ?: return
        val channel = shareChannel
        if (channel == null) pendingShare = text else channel.invokeMethod("shared", text)
    }

    /**
     * Whether the clipboard may hold a link, decided *without reading it*
     * (reading shows a "pasted from your clipboard" toast on Android 12+).
     * `stamp` changes when the clipboard does, so Dart reads each clip once.
     */
    private fun clipboardHint(): Map<String, Any?> {
        val cm = getSystemService(ClipboardManager::class.java)
        val d = cm?.primaryClipDescription ?: return mapOf("mayHaveLink" to false)
        val text = d.hasMimeType("text/*")
        val mayHaveLink = when {
            !text -> false
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                d.classificationStatus == ClipDescription.CLASSIFICATION_COMPLETE ->
                d.getConfidenceScore(TextClassifier.TYPE_URL) > 0.5f
            else -> true
        }
        val stamp = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) d.timestamp else null
        return mapOf("mayHaveLink" to mayHaveLink, "stamp" to stamp)
    }

    /** Shared text from a share-sheet intent; consumed so it isn't re-shared on rotation. */
    private fun takeShared(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND) return null
        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            ?: intent.getStringExtra(Intent.EXTRA_SUBJECT)
        intent.action = null
        return text?.takeIf { it.isNotBlank() }
    }

    @Deprecated("Needed for startIntentSenderForResult on older APIs")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (files?.onActivityResult(requestCode, resultCode) == true) return
        if (status?.onActivityResult(requestCode, resultCode, data) == true) return
        if (accounts?.onActivityResult(requestCode, resultCode) == true) return
        if (split?.onActivityResult(requestCode, resultCode, data) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (status?.onRequestPermissionsResult(requestCode, grantResults) == true) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    /** Notifications (Android 13+) and storage (Android 9 and older), asked once when needed. */
    private fun requestDownloadPermissions() {
        val needed = buildList {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                add(Manifest.permission.POST_NOTIFICATIONS)
            }
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            }
        }.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (needed.isNotEmpty()) requestPermissions(needed.toTypedArray(), 1001)
    }
}
