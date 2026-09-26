package com.bangash.kheench

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel

/**
 * Forwards download progress from workers to Dart (channel `kheench/progress`).
 * Events are dropped while no Flutter UI is listening; Dart catches up on
 * final states through `taskStates` when it comes back.
 */
object ProgressBus : EventChannel.StreamHandler {
    private const val CHANNEL = "kheench/progress"
    private val main = Handler(Looper.getMainLooper())
    @Volatile private var sink: EventChannel.EventSink? = null

    fun register(messenger: BinaryMessenger) {
        EventChannel(messenger, CHANNEL).setStreamHandler(this)
    }

    fun post(event: Map<String, Any?>) {
        main.post { sink?.success(event) }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }
}
