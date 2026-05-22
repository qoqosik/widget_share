package com.example.widget_share

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class WidgetShareHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val noteText = widgetData.getString("latest_note_text", null)
                ?.takeIf { it.isNotBlank() }
                ?: "No note yet"
            val noteType = widgetData.getString("latest_note_type", null)
                ?.takeIf { it.isNotBlank() }
                ?: "empty"
            val statusText = when (noteType) {
                "empty" -> "Open Widget Share to sync"
                else -> "Tap to refresh"
            }

            val views = RemoteViews(context.packageName, R.layout.widget_share_home_widget).apply {
                setTextViewText(R.id.widget_note_text, noteText)
                setTextViewText(R.id.widget_status_text, statusText)
                setTextViewText(R.id.widget_refresh_text, "Open")
                setOnClickPendingIntent(
                    R.id.widget_container,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
                setOnClickPendingIntent(
                    R.id.widget_refresh_text,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
