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

/**
 * List widget mirroring the Focus screen: spotlight, overdue, today and the
 * short upcoming preview.
 *
 * Rows are built statically (no ListView/RemoteViewsService) because a
 * collection widget funnels every click through a single PendingIntent
 * template, which cannot mix "open the app" (activity) with "complete in the
 * background" (broadcast). Static rows give each view its own intent; the
 * trade-off is a fixed row cap instead of scrolling.
 */
class FocusListWidgetProvider : es.antonborri.home_widget.HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val data = WidgetData.focus(context)
        val now = LocalDateTime.now()
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_focus_list)
            views.setTextViewText(R.id.focus_count, data.summary)
            views.setOnClickPendingIntent(
                R.id.focus_add,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("nudge://quickadd"),
                ),
            )
            views.setOnClickPendingIntent(
                R.id.focus_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            views.removeAllViews(R.id.focus_container)
            views.setViewVisibility(
                R.id.focus_container,
                if (data.items.isEmpty()) View.GONE else View.VISIBLE,
            )
            views.setViewVisibility(
                R.id.focus_empty,
                if (data.items.isEmpty()) View.VISIBLE else View.GONE,
            )
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 180)
            val detailed = minHeight >= DETAILED_HEIGHT_DP
            val rowHeight = if (detailed) DETAILED_ROW_HEIGHT_DP else COMPACT_ROW_HEIGHT_DP
            val rowLimit = ((minHeight - HEADER_HEIGHT_DP) / rowHeight).coerceIn(1, MAX_ROWS)
            for (task in data.items.take(rowLimit)) {
                views.addView(R.id.focus_container, buildRow(context, task, now, detailed))
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun buildRow(
        context: Context,
        task: WidgetTask,
        now: LocalDateTime,
        detailed: Boolean,
    ): RemoteViews =
        RemoteViews(context.packageName, R.layout.widget_row).apply {
            setTextViewText(R.id.row_title, task.title)
            setTextViewText(
                R.id.row_meta,
                if (detailed) task.deadlineLine(now) else task.compactMetaLine(now),
            )
            setTextColor(
                R.id.row_meta,
                context.getColor(
                    if (task.isOverdue(now)) R.color.widget_overdue
                    else R.color.widget_text_secondary
                ),
            )
            val details = task.detailLine()
            setViewVisibility(
                R.id.row_details,
                if (detailed && details.isNotEmpty()) View.VISIBLE else View.GONE,
            )
            setTextViewText(R.id.row_details, details)
            setImageViewResource(R.id.row_dot, task.dotDrawable)
            setViewVisibility(
                R.id.row_priority,
                if (task.priorityLabel != null) View.VISIBLE else View.GONE,
            )
            setTextViewText(R.id.row_priority, task.priorityLabel ?: "")
            setTextColor(
                R.id.row_priority,
                context.getColor(
                    when (task.priority) {
                        "high" -> R.color.widget_overdue
                        "medium" -> R.color.widget_medium
                        "low" -> R.color.widget_low
                        else -> R.color.widget_text_muted
                    },
                ),
            )
            setOnClickPendingIntent(
                R.id.row_root,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("nudge://task/${task.id}"),
                ),
            )
            // Complete without opening the app: home_widget runs the Dart
            // background callback, which applies the shared task mutations.
            setOnClickPendingIntent(
                R.id.row_check,
                HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("nudge://complete/${task.id}"),
                ),
            )
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
        /** Static rows don't scroll; cap what a tall widget can show. */
        const val MAX_ROWS = 8
        const val HEADER_HEIGHT_DP = 52
        const val COMPACT_ROW_HEIGHT_DP = 44
        const val DETAILED_ROW_HEIGHT_DP = 58
        const val DETAILED_HEIGHT_DP = 240
    }
}
