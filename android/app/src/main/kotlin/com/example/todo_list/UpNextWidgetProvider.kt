package com.example.todo_list

import android.appwidget.AppWidgetManager
import android.os.Bundle
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.time.LocalDateTime

/** Small widget showing the single most important task (Focus spotlight #1). */
class UpNextWidgetProvider : es.antonborri.home_widget.HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val task = WidgetData.upNext(context)
        val now = LocalDateTime.now()
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_up_next)
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 70)
            val showDetails = minHeight >= EXPANDED_HEIGHT_DP
            val showProgress = minHeight >= PROGRESS_HEIGHT_DP
            if (task == null) {
                views.setViewVisibility(R.id.up_next_title, View.GONE)
                views.setViewVisibility(R.id.up_next_meta, View.GONE)
                views.setViewVisibility(R.id.up_next_details, View.GONE)
                views.setViewVisibility(R.id.up_next_progress, View.GONE)
                views.setViewVisibility(R.id.up_next_priority, View.GONE)
                views.setViewVisibility(R.id.up_next_check, View.GONE)
                views.setViewVisibility(R.id.up_next_empty, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.up_next_title, View.VISIBLE)
                views.setViewVisibility(R.id.up_next_meta, View.VISIBLE)
                views.setViewVisibility(R.id.up_next_check, View.VISIBLE)
                views.setViewVisibility(R.id.up_next_empty, View.GONE)
                views.setTextViewText(R.id.up_next_title, task.title)
                views.setInt(R.id.up_next_title, "setMaxLines", if (showDetails) 2 else 1)
                views.setTextViewText(R.id.up_next_meta, task.deadlineLine(now))
                views.setTextColor(
                    R.id.up_next_meta,
                    context.getColor(
                        if (task.isOverdue(now)) R.color.widget_overdue
                        else R.color.widget_text_secondary
                    ),
                )
                val details = task.detailLine()
                views.setViewVisibility(
                    R.id.up_next_details,
                    if (showDetails && details.isNotEmpty()) View.VISIBLE else View.GONE,
                )
                views.setTextViewText(R.id.up_next_details, details)
                views.setViewVisibility(
                    R.id.up_next_progress,
                    if (showProgress && task.progress != null) View.VISIBLE else View.GONE,
                )
                task.progress?.let {
                    views.setProgressBar(R.id.up_next_progress, 100, it, false)
                }
                views.setViewVisibility(
                    R.id.up_next_priority,
                    if (task.priorityLabel != null) View.VISIBLE else View.GONE,
                )
                views.setTextViewText(R.id.up_next_priority, task.priorityLabel ?: "")
                views.setTextColor(
                    R.id.up_next_priority,
                    context.getColor(
                        if (task.isOverdue(now)) R.color.widget_overdue
                        else when (task.priority) {
                            "high" -> R.color.widget_text_primary
                            "medium" -> R.color.widget_medium
                            "low" -> R.color.widget_low
                            else -> R.color.widget_text_muted
                        },
                    ),
                )
                // Complete without opening the app (Dart background callback).
                views.setOnClickPendingIntent(
                    R.id.up_next_check,
                    HomeWidgetBackgroundIntent.getBroadcast(
                        context,
                        Uri.parse("nudge://complete/${task.id}"),
                    ),
                )
            }
            val uri = task?.let { Uri.parse("nudge://task/${it.id}") }
            views.setOnClickPendingIntent(
                R.id.up_next_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        onUpdate(
            context,
            appWidgetManager,
            intArrayOf(appWidgetId),
            HomeWidgetPlugin.getData(context),
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // Refresh relative labels when the day/clock/zone changes.
        when (intent.action) {
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                val manager = AppWidgetManager.getInstance(context)
                val ids = manager.getAppWidgetIds(ComponentName(context, javaClass))
                if (ids.isNotEmpty()) {
                    onUpdate(context, manager, ids, HomeWidgetPlugin.getData(context))
                }
            }
        }
    }

    private companion object {
        const val EXPANDED_HEIGHT_DP = 100
        const val PROGRESS_HEIGHT_DP = 125
    }
}
