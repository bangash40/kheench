package com.bangash.kheench

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import java.util.UUID

object DownloadNotifications {
    private const val PROGRESS_CHANNEL = "downloads"
    private const val DONE_CHANNEL = "downloads_done"
    private const val INK = 0xFF12262B.toInt()
    private const val SAFFRON = 0xFFF2A93B.toInt()

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(PROGRESS_CHANNEL, "Downloads in progress", NotificationManager.IMPORTANCE_LOW)
                .apply { setShowBadge(false) },
        )
        manager.createNotificationChannel(
            NotificationChannel(DONE_CHANNEL, "Finished downloads", NotificationManager.IMPORTANCE_DEFAULT),
        )
    }

    fun progressId(taskId: String) = taskId.hashCode()
    private fun doneId(taskId: String) = taskId.hashCode() + 1

    fun progress(
        context: Context,
        workId: UUID,
        title: String,
        text: String,
        percent: Int,
        indeterminate: Boolean,
    ) = NotificationCompat.Builder(context, PROGRESS_CHANNEL)
        .setSmallIcon(R.drawable.ic_stat_download)
        .setColor(SAFFRON)
        .setContentTitle(title)
        .setContentText(text)
        .setProgress(100, percent.coerceIn(0, 100), indeterminate)
        .setOngoing(true)
        .setOnlyAlertOnce(true)
        .setSilent(true)
        .setContentIntent(openApp(context))
        .addAction(
            0,
            "Cancel",
            androidx.work.WorkManager.getInstance(context).createCancelPendingIntent(workId),
        )
        .build()

    @SuppressLint("MissingPermission")
    fun done(context: Context, taskId: String, title: String, uri: String, mime: String) {
        if (!canNotify(context)) return
        val view = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(Uri.parse(uri), mime)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        val tap = if (uri.startsWith("content://")) {
            PendingIntent.getActivity(context, doneId(taskId), view, pendingFlags())
        } else {
            openApp(context)
        }
        val n = NotificationCompat.Builder(context, DONE_CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_download)
            .setColor(INK)
            .setContentTitle("Saved")
            .setContentText(title)
            .setAutoCancel(true)
            .setContentIntent(tap)
            .build()
        NotificationManagerCompat.from(context).notify(doneId(taskId), n)
    }

    @SuppressLint("MissingPermission")
    fun failed(context: Context, taskId: String, title: String) {
        if (!canNotify(context)) return
        val n = NotificationCompat.Builder(context, DONE_CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_download)
            .setColor(0xFFB42318.toInt())
            .setContentTitle("Download failed")
            .setContentText(title)
            .setAutoCancel(true)
            .setContentIntent(openApp(context))
            .build()
        NotificationManagerCompat.from(context).notify(doneId(taskId), n)
    }

    private fun canNotify(context: Context) =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(context, android.Manifest.permission.POST_NOTIFICATIONS) ==
            android.content.pm.PackageManager.PERMISSION_GRANTED

    private fun openApp(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(context, 0, intent, pendingFlags())
    }

    private fun pendingFlags() = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
}
