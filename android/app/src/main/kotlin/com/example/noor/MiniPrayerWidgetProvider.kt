package com.example.noor

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MiniPrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.mini_prayer_widget_layout).apply {
                    val prayerName = widgetData.getString("prayer_name", null)?.takeIf { it.isNotBlank() } ?: "الفجر"
                    val prayerTime = widgetData.getString("prayer_time", null)?.takeIf { it.isNotBlank() } ?: "05:10 ص"

                    setTextViewText(R.id.mini_prayer_name, prayerName)
                    setTextViewText(R.id.mini_prayer_time, prayerTime)

                    val intent = Intent(context, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }

                    val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    } else {
                        PendingIntent.FLAG_UPDATE_CURRENT
                    }

                    val pendingIntent = PendingIntent.getActivity(context, widgetId, intent, flags)
                    setOnClickPendingIntent(R.id.mini_prayer_widget_container, pendingIntent)
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                Log.e("MiniPrayerWidget", "خطأ أثناء تحديث ودجت موعد الصلاة المصغرة: ${e.message}", e)
            }
        }
    }
}
