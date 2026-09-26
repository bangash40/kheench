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

/** Copies finished files from app cache into shared storage (Movies/Music/Kheench). */
object MediaPublisher {
    data class Published(val uri: String, val path: String, val name: String, val size: Long)

    fun publish(context: Context, file: File, kind: String): Published {
        val audio = kind == "audio"
        val folder = if (audio) Environment.DIRECTORY_MUSIC else Environment.DIRECTORY_MOVIES
        val mime = mimeFor(file.extension.lowercase(), audio)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            publishScoped(context, file, "$folder/$ALBUM", mime, audio)
        } else {
            publishLegacy(context, file, folder, mime)
        }
    }

    private fun publishScoped(
        context: Context,
        file: File,
        relativePath: String,
        mime: String,
        audio: Boolean,
    ): Published {
        val resolver = context.contentResolver
        val collection = if (audio) {
            MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        }
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, file.name)
            put(MediaStore.MediaColumns.MIME_TYPE, mime)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values)
            ?: throw IOException("Could not create a file in $relativePath")
        try {
            resolver.openOutputStream(uri)?.use { out ->
                file.inputStream().use { it.copyTo(out) }
            } ?: throw IOException("Could not write to $relativePath")
            resolver.update(uri, ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
        // MediaStore may rename on clashes ("name (1).mp4"); read the final name back.
        val name = resolver.query(
            uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null, null, null,
        )?.use { c -> if (c.moveToFirst()) c.getString(0) else null } ?: file.name
        return Published(uri.toString(), "$relativePath/$name", name, file.length())
    }

    @Suppress("DEPRECATION")
    private fun publishLegacy(context: Context, file: File, folder: String, mime: String): Published {
        val dir = File(Environment.getExternalStoragePublicDirectory(folder), ALBUM)
        if (!dir.exists() && !dir.mkdirs()) throw IOException("Could not create $dir")
        var target = File(dir, file.name)
        var n = 1
        while (target.exists()) {
            target = File(dir, "${file.nameWithoutExtension} ($n).${file.extension}")
            n++
        }
        file.copyTo(target)
        MediaScannerConnection.scanFile(context, arrayOf(target.absolutePath), arrayOf(mime), null)
        return Published(
            Uri.fromFile(target).toString(),
            "$folder/$ALBUM/${target.name}",
            target.name,
            target.length(),
        )
    }

    fun mimeFor(ext: String, audio: Boolean): String = if (audio) {
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
