package com.example.bitcoin_checker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.bitcoin_checker/app_lifecycle"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendToBackground") {
                val moved = moveTaskToBack(true)
                result.success(moved)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onBackPressed() {
        // Keep app running in background when Back is pressed
        moveTaskToBack(true)
    }
}
