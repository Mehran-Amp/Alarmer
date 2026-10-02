package com.example.bitcoin_checker

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.bitcoin_checker/app_lifecycle"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendToBackground" -> {
                    val moved = moveTaskToBack(true)
                    result.success(moved)
                }
                "updateWidgetList" -> {
                    val json = call.argument<String>("json") ?: ""
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString("flutter.widget_alerts_json", json)
                        .apply()

                    AlarmerAppWidgetProvider.updateAllWidgets(this)
                    result.success(true)
                }
                "updateWidget" -> {
                    val symbol = call.argument<String>("symbol") ?: "BTC/USDT"
                    val price = call.argument<String>("price") ?: "$87,420.00"
                    val change = call.argument<String>("change") ?: "+3.52% ▲"
                    val exchange = call.argument<String>("exchange") ?: "Binance • Live"
                    val status = call.argument<String>("status") ?: "⚡ Active Alerts Monitored"

                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    prefs.edit()
                        .putString("flutter.widget_symbol", symbol)
                        .putString("flutter.widget_price", price)
                        .putString("flutter.widget_change", change)
                        .putString("flutter.widget_exchange", exchange)
                        .putString("flutter.widget_status", status)
                        .apply()

                    AlarmerAppWidgetProvider.updateAllWidgets(this)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onBackPressed() {
        // Keep app running in background when Back is pressed
        moveTaskToBack(true)
    }
}
