package com.example.bitcoin_checker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Native Android Home Screen AppWidget Provider for Alarmer (BitcoinChecker).
 * Appears in the launcher widget selector list and renders real-time market data.
 */
class AlarmerAppWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.alarmer_appwidget_layout)

            // Intent to open the main app when widget is tapped
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // Read latest saved data if available in SharedPreferences
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val savedSymbol = prefs.getString("flutter.widget_symbol", "BTC/USDT") ?: "BTC/USDT"
            val savedPrice = prefs.getString("flutter.widget_price", "$87,420.00") ?: "$87,420.00"
            val savedChange = prefs.getString("flutter.widget_change", "+3.52% ▲") ?: "+3.52% ▲"
            val savedExchange = prefs.getString("flutter.widget_exchange", "Binance • Live") ?: "Binance • Live"
            val savedStatus = prefs.getString("flutter.widget_status", "⚡ Active Alerts Monitored") ?: "⚡ Active Alerts Monitored"

            views.setTextViewText(R.id.widget_pair_symbol, savedSymbol)
            views.setTextViewText(R.id.widget_price, savedPrice)
            views.setTextViewText(R.id.widget_change_badge, savedChange)
            views.setTextViewText(R.id.widget_exchange, savedExchange)
            views.setTextViewText(R.id.widget_alert_status, savedStatus)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, AlarmerAppWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }
}
