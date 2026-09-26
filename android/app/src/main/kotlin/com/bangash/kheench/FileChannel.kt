package com.bangash.kheench

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Opens, shares and deletes saved files (channel `kheench/files`).
 * Deleting media the app no longer owns needs the user's confirmation, which
 * comes back through [onActivityResult].
 */
class FileChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private var pendingDelete: MethodChannel.Result? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val uri = call.argument<String>("uri")
        val mime = call.argument<String>("mime") ?: "*/*"
        when (call.method) {
            "open" -> result.success(start(Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(shareable(uri!!), mime)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }))
            "share" -> result.success(start(Intent.createChooser(
                Intent(Intent.ACTION_SEND).apply {
                    type = mime
                    putExtra(Intent.EXTRA_STREAM, shareable(uri!!))
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                },
                null,
            )))
            "openFolder" -> result.success(openFolder(call.argument<String>("folder")!!))
            "exists" -> result.success(exists(uri!!))
            "delete" -> delete(uri!!, result)
            else -> result.notImplemented()
        }
    }

    private fun start(intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (e: ActivityNotFoundException) {
        false
    }

    /** Turns legacy file:// paths into content:// URIs other apps may read. */
    private fun shareable(raw: String): Uri {
        val uri = Uri.parse(raw)
        if (uri.scheme != "file") return uri
        return FileProvider.getUriForFile(activity, "${activity.packageName}.files", File(uri.path!!))
    }

    /** Tries the system file manager at e.g. `Movies/Kheench`. */
    private fun openFolder(folder: String): Boolean {
        val doc = DocumentsContract.buildDocumentUri(
            "com.android.externalstorage.documents",
            "primary:$folder",
        )
        return start(Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(doc, DocumentsContract.Document.MIME_TYPE_DIR)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        })
    }

    private fun exists(raw: String): Boolean {
        val uri = Uri.parse(raw)
        if (uri.scheme == "file") return File(uri.path!!).exists()
        return try {
            activity.contentResolver.openFileDescriptor(uri, "r")?.use { true } ?: false
        } catch (e: Exception) {
            false
        }
    }

    private fun delete(raw: String, result: MethodChannel.Result) {
        val uri = Uri.parse(raw)
        if (uri.scheme == "file") {
            result.success(if (File(uri.path!!).delete() || !exists(raw)) "deleted" else "failed")
            return
        }
        try {
            val rows = activity.contentResolver.delete(uri, null, null)
            result.success(if (rows > 0 || !exists(raw)) "deleted" else "failed")
        } catch (e: SecurityException) {
            // Files saved before a reinstall belong to the old install; ask the user.
            val sender = when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.R ->
                    MediaStore.createDeleteRequest(activity.contentResolver, listOf(uri)).intentSender
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && e is RecoverableSecurityException ->
                    e.userAction.actionIntent.intentSender
                else -> null
            }
            if (sender == null) {
                result.success("failed")
                return
            }
            pendingDelete?.success("cancelled")
            pendingDelete = result
            activity.startIntentSenderForResult(sender, REQUEST_DELETE, null, 0, 0, 0)
        }
    }

    /** Returns true when the result belonged to this channel. */
    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != REQUEST_DELETE) return false
        val result = pendingDelete ?: return true
        pendingDelete = null
        result.success(if (resultCode == Activity.RESULT_OK) "confirm" else "cancelled")
        return true
    }

    companion object {
        private const val CHANNEL = "kheench/files"
        private const val REQUEST_DELETE = 2001
    }
}
