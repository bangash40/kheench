package com.bangash.kheench

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Reads WhatsApp / WhatsApp Business statuses (channel `kheench/status`).
 *
 * Android 10 and older read the folder directly after the storage permission.
 * Android 11+ can't, so the user grants the folder once through the system
 * picker and the grant is kept. The picker also serves as a manual fallback
 * if WhatsApp ever moves the folder.
 */
class StatusChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    private val executor = Executors.newFixedThreadPool(3)
    private val main = Handler(Looper.getMainLooper())
    private val prefs get() = activity.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private var pendingPermission: MethodChannel.Result? = null
    private var pendingPick: Pair<String, MethodChannel.Result>? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val app = call.argument<String>("app") ?: "whatsapp"
        when (call.method) {
            "access" -> result.success(access(app))
            "request" -> request(app, result)
            "pickFolder" -> pick(app, result)
            "list" -> background(result) { list(app) }
            "thumbnail" -> background(result) {
                thumbnail(call.argument<String>("uri")!!, call.argument<String>("type")!!)
            }
            "localCopy" -> background(result) { localCopy(call.argument<String>("uri")!!) }
            "save" -> background(result) {
                save(call.argument<List<Map<String, Any?>>>("items").orEmpty())
            }
            else -> result.notImplemented()
        }
    }

    // --- access -----------------------------------------------------------

    private fun useDirectFiles() = Build.VERSION.SDK_INT <= Build.VERSION_CODES.Q

    private fun hasReadPermission() = ContextCompat.checkSelfPermission(
        activity, Manifest.permission.READ_EXTERNAL_STORAGE,
    ) == PackageManager.PERMISSION_GRANTED

    private fun savedTree(app: String): Uri? {
        val raw = prefs.getString("tree_$app", null) ?: return null
        val uri = Uri.parse(raw)
        val held = activity.contentResolver.persistedUriPermissions
            .any { it.uri == uri && it.isReadPermission }
        return if (held) uri else null
    }

    /** { granted, mode: file|saf|none, installed } */
    private fun access(app: String): Map<String, Any?> {
        val tree = savedTree(app)
        val mode = when {
            tree != null -> "saf"
            useDirectFiles() && hasReadPermission() -> "file"
            else -> "none"
        }
        return mapOf(
            "granted" to (mode != "none"),
            "mode" to mode,
            "installed" to isInstalled(app),
            "folder" to relativeFolder(app),
            "needsPicker" to !useDirectFiles(),
        )
    }

    private fun isInstalled(app: String): Boolean = try {
        activity.packageManager.getPackageInfo(packageOf(app), 0)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    private fun request(app: String, result: MethodChannel.Result) {
        if (!useDirectFiles()) {
            pick(app, result)
            return
        }
        if (hasReadPermission()) {
            result.success(true)
            return
        }
        pendingPermission?.success(false)
        pendingPermission = result
        activity.requestPermissions(arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE), REQUEST_READ)
    }

    private fun pick(app: String, result: MethodChannel.Result) {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Open the picker right at the status folder.
                putExtra(
                    DocumentsContract.EXTRA_INITIAL_URI,
                    DocumentsContract.buildDocumentUri(
                        EXTERNAL_DOCS,
                        "primary:${relativeFolder(app)}",
                    ),
                )
            }
        }
        pendingPick?.second?.success(false)
        pendingPick = app to result
        activity.startActivityForResult(intent, REQUEST_TREE)
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQUEST_READ) return false
        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        pendingPermission?.success(granted)
        pendingPermission = null
        return true
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_TREE) return false
        val (app, result) = pendingPick ?: return true
        pendingPick = null
        val tree = data?.data
        if (resultCode != Activity.RESULT_OK || tree == null) {
            result.success(false)
            return true
        }
        activity.contentResolver.takePersistableUriPermission(tree, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        prefs.edit().putString("tree_$app", tree.toString()).apply()
        result.success(true)
        return true
    }

    // --- listing ----------------------------------------------------------

    private fun list(app: String): List<Map<String, Any?>> {
        val tree = savedTree(app)
        val items = when {
            tree != null -> listTree(tree)
            useDirectFiles() && hasReadPermission() -> listFiles(app)
            else -> emptyList()
        }
        return items.sortedByDescending { it["modified"] as Long }
    }

    private fun listFiles(app: String): List<Map<String, Any?>> {
        val root = Environment.getExternalStorageDirectory()
        val dirs = listOf(File(root, relativeFolder(app)), File(root, legacyFolder(app)))
        return dirs.filter { it.isDirectory }
            .flatMap { it.listFiles()?.toList().orEmpty() }
            .mapNotNull { f ->
                val type = typeOf(f.name) ?: return@mapNotNull null
                mapOf(
                    "uri" to Uri.fromFile(f).toString(),
                    "name" to f.name,
                    "type" to type,
                    "modified" to f.lastModified(),
                    "size" to f.length(),
                )
            }
    }

    private fun listTree(tree: Uri): List<Map<String, Any?>> {
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(
            tree, DocumentsContract.getTreeDocumentId(tree),
        )
        val columns = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            DocumentsContract.Document.COLUMN_SIZE,
        )
        val out = mutableListOf<Map<String, Any?>>()
        activity.contentResolver.query(children, columns, null, null, null)?.use { c ->
            while (c.moveToNext()) {
                val name = c.getString(1) ?: continue
                val type = typeOf(name) ?: continue
                out += mapOf(
                    "uri" to DocumentsContract.buildDocumentUriUsingTree(tree, c.getString(0)).toString(),
                    "name" to name,
                    "type" to type,
                    "modified" to c.getLong(2),
                    "size" to c.getLong(3),
                )
            }
        }
        return out
    }

    // --- thumbnails -------------------------------------------------------

    /**
     * `{ path, durationMs }`: a small cached JPEG for [raw] (made once per file)
     * and, for videos, the length.
     */
    private fun thumbnail(raw: String, type: String): Map<String, Any?>? {
        val dir = File(activity.cacheDir, "status_thumbs").apply { mkdirs() }
        val key = raw.hashCode().toUInt().toString(16)
        val out = File(dir, "$key.jpg")
        val durFile = File(dir, "$key.dur")
        val cached = out.exists() && out.length() > 0 && (type != "video" || durFile.exists())
        if (cached) {
            return mapOf("path" to out.absolutePath, "durationMs" to durFile.takeIf { it.exists() }?.readText()?.toLongOrNull())
        }
        val uri = Uri.parse(raw)
        var duration: Long? = null
        val bitmap = try {
            if (type == "video") {
                val (frame, ms) = videoFrame(uri)
                duration = ms
                frame
            } else {
                scaledPhoto(uri)
            }
        } catch (e: Exception) {
            Log.w(TAG, "thumbnail failed for $raw", e)
            null
        } ?: return null
        out.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, 80, it) }
        bitmap.recycle()
        duration?.let { durFile.writeText(it.toString()) }
        return mapOf("path" to out.absolutePath, "durationMs" to duration)
    }

    private fun videoFrame(uri: Uri): Pair<Bitmap?, Long?> {
        val r = MediaMetadataRetriever()
        return try {
            r.setDataSource(activity, uri)
            val ms = r.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull()
            val frame = r.getFrameAtTime(1_000_000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                ?: r.frameAtTime
            frame?.let { scaleDown(it) } to ms
        } finally {
            r.release()
        }
    }

    /** A readable local path for [raw]; picker (content://) files are copied to cache once. */
    private fun localCopy(raw: String): String? {
        val uri = Uri.parse(raw)
        if (uri.scheme == "file") return uri.path
        val dir = File(activity.cacheDir, "status_view").apply { mkdirs() }
        val name = DocumentsContract.getDocumentId(uri).substringAfterLast('/')
        val out = File(dir, "${raw.hashCode().toUInt().toString(16)}_$name")
        if (!out.exists() || out.length() == 0L) {
            activity.contentResolver.openInputStream(uri)?.use { input ->
                out.outputStream().use { input.copyTo(it) }
            } ?: return null
        }
        return out.absolutePath
    }

    private fun scaledPhoto(uri: Uri): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        activity.contentResolver.openInputStream(uri)?.use { BitmapFactory.decodeStream(it, null, bounds) }
        var sample = 1
        while (bounds.outWidth / (sample * 2) >= THUMB_WIDTH) sample *= 2
        val opts = BitmapFactory.Options().apply { inSampleSize = sample }
        return activity.contentResolver.openInputStream(uri)?.use {
            BitmapFactory.decodeStream(it, null, opts)
        }
    }

    private fun scaleDown(src: Bitmap): Bitmap {
        if (src.width <= THUMB_WIDTH) return src
        val h = src.height * THUMB_WIDTH / src.width
        return Bitmap.createScaledBitmap(src, THUMB_WIDTH, h, true).also {
            if (it != src) src.recycle()
        }
    }

    // --- saving -----------------------------------------------------------

    /** Copies statuses into Movies/Kheench/Status and Pictures/Kheench/Status. */
    private fun save(items: List<Map<String, Any?>>): List<Map<String, Any?>> = items.map { item ->
        val raw = item["uri"] as String
        val type = item["type"] as String
        val uri = Uri.parse(raw)
        try {
            val saved = MediaPublisher.publish(
                activity,
                open = {
                    if (uri.scheme == "file") File(uri.path!!).inputStream()
                    else activity.contentResolver.openInputStream(uri)
                        ?: throw java.io.IOException("Can't read $raw")
                },
                name = item["name"] as String,
                kind = if (type == "video") "video" else "photo",
                subfolder = "Status",
                sizeHint = (item["size"] as Number?)?.toLong() ?: 0L,
            )
            mapOf("uri" to raw, "ok" to true, "savedUri" to saved.uri, "path" to saved.path)
        } catch (e: Exception) {
            Log.w(TAG, "saving $raw failed", e)
            mapOf("uri" to raw, "ok" to false, "error" to (e.message ?: e.toString()))
        }
    }

    // --- helpers ----------------------------------------------------------

    private fun background(result: MethodChannel.Result, block: () -> Any?) {
        executor.execute {
            try {
                val value = block()
                main.post { result.success(value) }
            } catch (e: Throwable) {
                Log.w(TAG, "status call failed", e)
                main.post { result.error("STATUS_ERROR", e.message ?: e.toString(), null) }
            }
        }
    }

    companion object {
        private const val CHANNEL = "kheench/status"
        private const val TAG = "KheenchStatus"
        private const val PREFS = "kheench_status"
        private const val EXTERNAL_DOCS = "com.android.externalstorage.documents"
        private const val REQUEST_READ = 3001
        private const val REQUEST_TREE = 3002
        private const val THUMB_WIDTH = 360

        fun packageOf(app: String) = if (app == "business") "com.whatsapp.w4b" else "com.whatsapp"

        fun relativeFolder(app: String) = if (app == "business") {
            "Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses"
        } else {
            "Android/media/com.whatsapp/WhatsApp/Media/.Statuses"
        }

        /** Where older WhatsApp versions kept statuses. */
        fun legacyFolder(app: String) = if (app == "business") {
            "WhatsApp Business/Media/.Statuses"
        } else {
            "WhatsApp/Media/.Statuses"
        }

        fun typeOf(name: String): String? = when (name.substringAfterLast('.', "").lowercase()) {
            "mp4", "3gp", "mkv", "webm" -> "video"
            "jpg", "jpeg", "png", "webp" -> "photo"
            else -> null
        }
    }
}
