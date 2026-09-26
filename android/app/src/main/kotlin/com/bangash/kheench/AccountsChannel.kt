package com.bangash.kheench

import android.app.Activity
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Platform logins for private content (channel `kheench/accounts`). */
class AccountsChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private var pendingLogin: MethodChannel.Result? = null

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> result.success(SessionStore.status(activity))
            "login" -> {
                pendingLogin?.success(false)
                pendingLogin = result
                activity.startActivityForResult(
                    Intent(activity, LoginActivity::class.java)
                        .putExtra(LoginActivity.EXTRA_PLATFORM, call.argument<String>("platform")),
                    REQUEST_LOGIN,
                )
            }
            "logout" -> {
                SessionStore.logout(activity, SessionStore.platform(call.argument<String>("platform")!!))
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != REQUEST_LOGIN) return false
        pendingLogin?.success(resultCode == Activity.RESULT_OK)
        pendingLogin = null
        return true
    }

    companion object {
        private const val CHANNEL = "kheench/accounts"
        private const val REQUEST_LOGIN = 4001
    }
}
