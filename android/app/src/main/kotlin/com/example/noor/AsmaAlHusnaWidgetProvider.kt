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

class AsmaAlHusnaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                    val dailyName = widgetData.getString("daily_name", null)?.takeIf { it.isNotBlank() } ?: "الرَّحْمَن"
                    val subtitle = widgetData.getString("daily_subtitle", null)?.takeIf { it.isNotBlank() } ?: "وَلِلَّهِ الْأَسْمَاءُ الْحُسْنَىٰ"

                    setTextViewText(R.id.widget_title, dailyName)
                    setTextViewText(R.id.widget_subtitle, subtitle)

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
                    setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                Log.e("AsmaWidget", "خطأ أثناء تحديث ودجت أسماء الله الحسنى: ${e.message}", e)
            }
        }
    }
}
