package com.example.bitcoin_checker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

/**
 * Native Android Home Screen AppWidget Provider for Alarmer.
 * Shows multi-alert list with pair symbol, last checked price, target/notes, and colored change/Done badges.
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

            // Read JSON payload from SharedPreferences
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val jsonStr = prefs.getString("flutter.widget_alerts_json", null)

            if (jsonStr != null && jsonStr.isNotEmpty()) {
                try {
                    val root = JSONObject(jsonStr)
                    val activeCount = root.optInt("activeCount", 0)
                    val headerTitle = root.optString("title", "Alarmer Live")
                    val items = root.optJSONArray("items")

                    views.setTextViewText(R.id.widget_header_title, headerTitle)
                    views.setTextViewText(R.id.widget_active_badge, "⚡ $activeCount Active")

                    val rowRoots = intArrayOf(R.id.item_1_root, R.id.item_2_root, R.id.item_3_root)
                    val rowSymbols = intArrayOf(R.id.item_1_symbol, R.id.item_2_symbol, R.id.item_3_symbol)
                    val rowPrices = intArrayOf(R.id.item_1_price, R.id.item_2_price, R.id.item_3_price)
                    val rowInfos = intArrayOf(R.id.item_1_info, R.id.item_2_info, R.id.item_3_info)
                    val rowBadges = intArrayOf(R.id.item_1_badge, R.id.item_2_badge, R.id.item_3_badge)

                    val count = items?.length() ?: 0
                    if (count == 0) {
                        views.setViewVisibility(R.id.widget_empty_text, View.VISIBLE)
                        for (rootId in rowRoots) {
                            views.setViewVisibility(rootId, View.GONE)
                        }
                    } else {
                        views.setViewVisibility(R.id.widget_empty_text, View.GONE)
                        for (i in 0 until 3) {
                            if (i < count) {
                                val item = items!!.getJSONObject(i)
                                val symbol = item.optString("symbol", "—")
                                val price = item.optString("price", "—")
                                val badge = item.optString("badge", "—")
                                val info = item.optString("info", "")
                                val isDone = item.optBoolean("isDone", false)
                                val isPositive = item.optBoolean("isPositive", false)
                                val isNegative = item.optBoolean("isNegative", false)

                                views.setViewVisibility(rowRoots[i], View.VISIBLE)
                                views.setTextViewText(rowSymbols[i], symbol)
                                views.setTextViewText(rowPrices[i], price)
                                views.setTextViewText(rowInfos[i], info)
                                views.setTextViewText(rowBadges[i], badge)

                                // Badge styling per condition & direction
                                if (isDone) {
                                    views.setInt(rowBadges[i], "setBackgroundResource", R.drawable.badge_done)
                                    views.setTextColor(rowBadges[i], 0xFFE3B341.toInt()) // Gold
                                } else if (isPositive) {
                                    views.setInt(rowBadges[i], "setBackgroundResource", R.drawable.badge_green)
                                    views.setTextColor(rowBadges[i], 0xFF3FB950.toInt()) // Green
                                } else if (isNegative) {
                                    views.setInt(rowBadges[i], "setBackgroundResource", R.drawable.badge_red)
                                    views.setTextColor(rowBadges[i], 0xFFF85149.toInt()) // Red
                                } else {
                                    views.setInt(rowBadges[i], "setBackgroundResource", R.drawable.widget_badge_bg)
                                    views.setTextColor(rowBadges[i], 0xFF58A6FF.toInt()) // Blue
                                }
                            } else {
                                views.setViewVisibility(rowRoots[i], View.GONE)
                            }
                        }
                    }
                } catch (e: Exception) {
                    views.setViewVisibility(R.id.widget_empty_text, View.VISIBLE)
                }
            } else {
                // Fallback default
                views.setViewVisibility(R.id.item_1_root, View.VISIBLE)
                views.setViewVisibility(R.id.item_2_root, View.GONE)
                views.setViewVisibility(R.id.item_3_root, View.GONE)
                views.setViewVisibility(R.id.widget_empty_text, View.GONE)
                views.setTextViewText(R.id.item_1_symbol, "BTC/USDT")
                views.setTextViewText(R.id.item_1_price, "$87,420.00")
                views.setTextViewText(R.id.item_1_info, "Real-time Monitoring")
                views.setTextViewText(R.id.item_1_badge, "+3.52% ▲")
            }

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
