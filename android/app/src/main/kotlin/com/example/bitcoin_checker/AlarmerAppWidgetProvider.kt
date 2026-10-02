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
 * - Dynamic theme & background contrast matching active app theme (light, dark, amoled)
 * - Exact alert order
 * - Pure percentage change + arrow (+X.XX% ▲ / -X.XX% ▼)
 * - Dynamic compact height wrapping around active alerts
 * - 100% RemoteViews safe
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
            try {
                val views = RemoteViews(context.packageName, R.layout.alarmer_appwidget_layout)

                // Intent to open main app on widget click
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

                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                val jsonStr = prefs.getString("flutter.widget_alerts_json", null)

                val rowRoots = intArrayOf(R.id.item_1_root, R.id.item_2_root, R.id.item_3_root)
                val rowSymbols = intArrayOf(R.id.item_1_symbol, R.id.item_2_symbol, R.id.item_3_symbol)
                val rowPrices = intArrayOf(R.id.item_1_price, R.id.item_2_price, R.id.item_3_price)
                val rowBadges = intArrayOf(R.id.item_1_badge, R.id.item_2_badge, R.id.item_3_badge)

                if (jsonStr != null && jsonStr.isNotEmpty()) {
                    try {
                        val root = JSONObject(jsonStr)
                        val activeCount = root.optInt("activeCount", 0)
                        val headerTitle = root.optString("title", "Alarmer Live Widget")
                        val subtitle = root.optString("subtitle", "$activeCount active alerts • Live")
                        val footerText = root.optString("footerText", "Tap to open Alarmer")
                        val items = root.optJSONArray("items")
                        val themeObj = root.optJSONObject("theme")

                        // Active Theme Colors
                        val isDark = themeObj?.optInt("isDark", 1) == 1
                        val primaryColor = themeObj?.optLong("primary", if (isDark) 0xFF10B981 else 0xFF059669)?.toInt()
                            ?: if (isDark) 0xFF10B981.toInt() else 0xFF059669.toInt()
                        val textPrimaryColor = themeObj?.optLong("textPrimary", if (isDark) 0xFFF9FAFB else 0xFF111827)?.toInt()
                            ?: if (isDark) 0xFFF9FAFB.toInt() else 0xFF111827.toInt()
                        val textSecondaryColor = themeObj?.optLong("textSecondary", if (isDark) 0xFF9CA3AF else 0xFF4B5563)?.toInt()
                            ?: if (isDark) 0xFF9CA3AF.toInt() else 0xFF4B5563.toInt()
                        val borderColor = themeObj?.optLong("border", if (isDark) 0xFF374151 else 0xFFD1D5DB)?.toInt()
                            ?: if (isDark) 0xFF374151.toInt() else 0xFFD1D5DB.toInt()
                        val priceColor = themeObj?.optLong("price", if (isDark) 0xFFF59E0B else 0xFFD97706)?.toInt()
                            ?: if (isDark) 0xFFF59E0B.toInt() else 0xFFD97706.toInt()

                        // Header & Dividers styling
                        views.setTextViewText(R.id.widget_header_title, headerTitle)
                        views.setTextColor(R.id.widget_header_title, textPrimaryColor)

                        views.setTextViewText(R.id.widget_subtitle, subtitle)
                        views.setTextColor(R.id.widget_subtitle, textSecondaryColor)

                        views.setTextViewText(R.id.widget_active_badge, "⚡ LIVE")
                        views.setTextColor(R.id.widget_active_badge, primaryColor)

                        views.setTextViewText(R.id.widget_footer_text, footerText)
                        views.setTextColor(R.id.widget_footer_text, primaryColor)

                        views.setInt(R.id.widget_divider_1, "setBackgroundColor", borderColor)
                        views.setInt(R.id.widget_divider_2, "setBackgroundColor", borderColor)

                        val count = items?.length() ?: 0
                        if (count == 0) {
                            views.setViewVisibility(R.id.widget_empty_text, View.VISIBLE)
                            views.setTextColor(R.id.widget_empty_text, textSecondaryColor)
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
                                    val isDone = item.optBoolean("isDone", false)
                                    val isPositive = item.optBoolean("isPositive", true)

                                    views.setViewVisibility(rowRoots[i], View.VISIBLE)
                                    views.setTextViewText(rowSymbols[i], symbol)
                                    views.setTextColor(rowSymbols[i], textPrimaryColor)

                                    views.setTextViewText(rowPrices[i], price)
                                    views.setTextColor(rowPrices[i], priceColor)

                                    views.setTextViewText(rowBadges[i], badge)

                                    // Badge contrast color
                                    if (isDone) {
                                        views.setTextColor(rowBadges[i], if (isDark) 0xFFE3B341.toInt() else 0xFFD97706.toInt())
                                    } else if (isPositive) {
                                        views.setTextColor(rowBadges[i], if (isDark) 0xFF3FB950.toInt() else 0xFF16A34A.toInt())
                                    } else {
                                        views.setTextColor(rowBadges[i], if (isDark) 0xFFF85149.toInt() else 0xFFDC2626.toInt())
                                    }
                                } else {
                                    views.setViewVisibility(rowRoots[i], View.GONE)
                                }
                            }
                        }
                    } catch (_: Exception) {
                        views.setViewVisibility(R.id.widget_empty_text, View.VISIBLE)
                        for (rootId in rowRoots) {
                            views.setViewVisibility(rootId, View.GONE)
                        }
                    }
                } else {
                    // Default fallback
                    views.setTextViewText(R.id.widget_header_title, "Alarmer Live Widget")
                    views.setTextViewText(R.id.widget_subtitle, "1 active alert • Live")
                    views.setTextViewText(R.id.widget_active_badge, "⚡ LIVE")
                    views.setViewVisibility(R.id.item_1_root, View.VISIBLE)
                    views.setViewVisibility(R.id.item_2_root, View.GONE)
                    views.setViewVisibility(R.id.item_3_root, View.GONE)
                    views.setViewVisibility(R.id.widget_empty_text, View.GONE)
                    views.setTextViewText(R.id.item_1_symbol, "BTC/USDT")
                    views.setTextViewText(R.id.item_1_price, "$87,420.00")
                    views.setTextViewText(R.id.item_1_badge, "+3.45% ▲")
                    views.setTextColor(R.id.item_1_badge, 0xFF3FB950.toInt())
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (_: Exception) {}
        }

        fun updateAllWidgets(context: Context) {
            try {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val componentName = ComponentName(context, AlarmerAppWidgetProvider::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
                if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                    for (appWidgetId in appWidgetIds) {
                        updateAppWidget(context, appWidgetManager, appWidgetId)
                    }
                }
            } catch (_: Exception) {}
        }
    }
}
