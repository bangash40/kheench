package com.bangash.kheench

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.IOException
import java.io.InputStream

/** Copies files into shared storage (Movies, Music or Pictures /Kheench). */
object MediaPublisher {
    data class Published(val uri: String, val path: String, val name: String, val size: Long)

    fun publish(context: Context, file: File, kind: String): Published =
        publish(context, { file.inputStream() }, file.name, kind, subfolder = null, sizeHint = file.length())

    /**
     * Copies a stream into shared storage: videos → Movies/Kheench, audio →
     * Music/Kheench, photos → Pictures/Kheench, plus an optional [subfolder].
     */
    fun publish(
        context: Context,
        open: () -> InputStream,
        name: String,
        kind: String,
        subfolder: String?,
        sizeHint: Long,
    ): Published {
        val folder = when (kind) {
            "audio" -> Environment.DIRECTORY_MUSIC
            "photo" -> Environment.DIRECTORY_PICTURES
            else -> Environment.DIRECTORY_MOVIES
        }
        val album = if (subfolder == null) ALBUM else "$ALBUM/$subfolder"
        val mime = mimeFor(name.substringAfterLast('.', "").lowercase(), kind)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            publishScoped(context, open, name, "$folder/$album", mime, kind, sizeHint)
        } else {
            publishLegacy(context, open, name, folder, album, mime)
        }
    }

    private fun publishScoped(
        context: Context,
        open: () -> InputStream,
        name: String,
        relativePath: String,
        mime: String,
        kind: String,
        sizeHint: Long,
    ): Published {
        val resolver = context.contentResolver
        val volume = MediaStore.VOLUME_EXTERNAL_PRIMARY
        val collection = when (kind) {
            "audio" -> MediaStore.Audio.Media.getContentUri(volume)
            "photo" -> MediaStore.Images.Media.getContentUri(volume)
            else -> MediaStore.Video.Media.getContentUri(volume)
        }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values)
            ?: throw IOException("Could not create a file in $relativePath")
        try {
            resolver.openOutputStream(uri)?.use { out ->
                open().use { it.copyTo(out) }
            } ?: throw IOException("Could not write to $relativePath")
            resolver.update(uri, ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
        // MediaStore may rename on clashes ("name (1).mp4"); read the final name back.
        val finalName = resolver.query(
            uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null,
        )?.use { c -> if (c.moveToFirst()) c.getString(0) else null } ?: name
        return Published(uri.toString(), "$relativePath/$finalName", finalName, sizeHint)
    }

    @Suppress("DEPRECATION")
    private fun publishLegacy(
        context: Context,
        open: () -> InputStream,
        name: String,
        folder: String,
        album: String,
        mime: String,
    ): Published {
        val dir = File(Environment.getExternalStoragePublicDirectory(folder), album)
        if (!dir.exists() && !dir.mkdirs()) throw IOException("Could not create $dir")
        val base = name.substringBeforeLast('.')
        val ext = name.substringAfterLast('.', "")
        var target = File(dir, name)
        var n = 1
        while (target.exists()) {
            target = File(dir, "$base ($n).$ext")
            n++
        }
        open().use { input -> target.outputStream().use { input.copyTo(it) } }
        MediaScannerConnection.scanFile(context, arrayOf(target.absolutePath), arrayOf(mime), null)
        return Published(
            Uri.fromFile(target).toString(),
            "$folder/$album/${target.name}",
            target.name,
            target.length(),
        )
    }

    fun mimeFor(ext: String, audio: Boolean): String = mimeFor(ext, if (audio) "audio" else "video")

    fun mimeFor(ext: String, kind: String): String = if (kind == "photo") {
        when (ext) {
            "png" -> "image/png"
            "webp" -> "image/webp"
            "gif" -> "image/gif"
            else -> "image/jpeg"
        }
    } else if (kind == "audio") {
        when (ext) {
            "mp3" -> "audio/mpeg"
            "m4a", "mp4", "aac" -> "audio/mp4"
            "opus", "ogg" -> "audio/ogg"
            "webm" -> "audio/webm"
            "flac" -> "audio/flac"
            "wav" -> "audio/wav"
            else -> "audio/mpeg"
        }
    } else {
        when (ext) {
            "webm" -> "video/webm"
            "mkv" -> "video/x-matroska"
            "3gp" -> "video/3gpp"
            "mov" -> "video/quicktime"
            else -> "video/mp4"
        }
    }

    private const val ALBUM = "Kheench"
}
