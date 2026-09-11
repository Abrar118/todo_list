package com.example.todo_list

import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.Locale

/**
 * One task as exported by the Flutter side (lib/services/widget_snapshot.dart).
 * Only raw fields cross the bridge; deadline labels are computed here at
 * render time so the widget stays correct when the date rolls over while the
 * app is closed.
 */
data class WidgetTask(
    val id: String,
    val title: String,
    val due: LocalDate?,
    val dueMinutes: Int?,
    val priority: String,
    val subtasks: String?,
    val progress: Int?,
    val tags: List<String>,
    val recurring: Boolean,
    val reminders: Boolean,
    val alarm: Boolean,
    val focusedMinutes: Int?,
) {
    fun isOverdue(now: LocalDateTime): Boolean {
        val date = due ?: return false
        val minutes = dueMinutes
            ?: return date.isBefore(now.toLocalDate())
        val deadline = date.atStartOfDay().plusMinutes(minutes.toLong())
        return deadline.isBefore(now)
    }

    /** "Today", "Tomorrow 5:30 PM", "Mon, Jul 14", or "2 days overdue". */
    fun deadlineLabel(now: LocalDateTime): String? {
        val date = due ?: return null
        val today = now.toLocalDate()
        if (isOverdue(now)) {
            val days = java.time.temporal.ChronoUnit.DAYS.between(date, today)
            return when {
                days >= 2L -> "$days days overdue"
                days == 1L -> "1 day overdue"
                else -> "Overdue"
            }
        }
        val base = when (date) {
            today -> "Today"
            today.plusDays(1) -> "Tomorrow"
            else -> date.format(
                DateTimeFormatter.ofPattern(
                    if (date.year == today.year) "EEE, MMM d" else "EEE, MMM d, yyyy",
                    Locale.getDefault(),
                )
            )
        }
        val minutes = dueMinutes ?: return base
        val time = LocalDateTime.of(date, java.time.LocalTime.of(minutes / 60, minutes % 60))
            .format(DateTimeFormatter.ofPattern("h:mm a", Locale.getDefault()))
        return "$base $time"
    }

    fun deadlineLine(now: LocalDateTime): String = deadlineLabel(now) ?: "No deadline"

    /** Secondary details, ordered by usefulness when the line is truncated. */
    fun detailLine(): String {
        val parts = mutableListOf<String>()
        subtasks?.let { parts.add("$it subtasks") }
            ?: progress?.let { parts.add("$it% done") }
        if (tags.isNotEmpty()) parts.add(tags.take(2).joinToString(" ") { "#$it" })
        if (recurring) parts.add("Repeats")
        if (alarm) parts.add("Alarm") else if (reminders) parts.add("Reminder")
        focusedMinutes?.takeIf { it > 0 }?.let { parts.add("${it}m focused") }
        return parts.joinToString(" · ")
    }

    fun compactMetaLine(now: LocalDateTime): String {
        val details = detailLine()
        return if (details.isEmpty()) deadlineLine(now) else "${deadlineLine(now)} · $details"
    }

    val priorityLabel: String?
        get() = when (priority) {
            "high" -> "HIGH"
            "medium" -> "MEDIUM"
            "low" -> "LOW"
            else -> null
        }

    val dotDrawable: Int
        get() = when (priority) {
            "high" -> R.drawable.widget_dot_high
            "medium" -> R.drawable.widget_dot_medium
            "low" -> R.drawable.widget_dot_low
            else -> R.drawable.widget_dot_none
        }
}

data class FocusWidgetData(
    val items: List<WidgetTask>,
    val total: Int,
    val overdue: Int,
    val today: Int,
) {
    val summary: String
        get() = when {
            overdue > 0 && today > 0 -> "$overdue overdue · $today today"
            overdue > 0 -> "$overdue overdue"
            today > 0 -> "$today today"
            total > 0 -> "$total in focus"
            else -> ""
        }
}

object WidgetData {
    private const val UP_NEXT_KEY = "widget_up_next"
    private const val FOCUS_KEY = "widget_focus"

    fun upNext(context: Context): WidgetTask? {
        val raw = HomeWidgetPlugin.getData(context).getString(UP_NEXT_KEY, null)
            ?: return null
        return try {
            val obj = JSONObject(raw)
            if (obj.optBoolean("empty", false)) null else parseTask(obj)
        } catch (e: JSONException) {
            null
        }
    }

    fun focus(context: Context): FocusWidgetData {
        val raw = HomeWidgetPlugin.getData(context).getString(FOCUS_KEY, null)
            ?: return FocusWidgetData(emptyList(), 0, 0, 0)
        return try {
            val payload = JSONObject(raw)
            val items: JSONArray = payload.optJSONArray("items")
                ?: return FocusWidgetData(emptyList(), 0, 0, 0)
            val parsed = (0 until items.length()).mapNotNull { i ->
                items.optJSONObject(i)?.let(::parseTask)
            }
            FocusWidgetData(
                items = parsed,
                total = payload.optInt("total", parsed.size),
                overdue = payload.optInt("overdue", 0),
                today = payload.optInt("today", 0),
            )
        } catch (e: JSONException) {
            FocusWidgetData(emptyList(), 0, 0, 0)
        }
    }

    private fun parseTask(obj: JSONObject): WidgetTask = WidgetTask(
        id = obj.optString("id"),
        title = obj.optString("title"),
        due = obj.optString("due", "").takeIf { it.isNotEmpty() }?.let {
            try {
                LocalDate.parse(it)
            } catch (e: Exception) {
                null
            }
        },
        dueMinutes = if (obj.has("dueMinutes")) obj.optInt("dueMinutes") else null,
        priority = obj.optString("priority", "none"),
        subtasks = obj.optString("subtasks", "").takeIf { it.isNotEmpty() },
        progress = if (obj.has("progress")) obj.optInt("progress").coerceIn(0, 100) else null,
        tags = obj.optJSONArray("tags")?.let { array ->
            (0 until array.length()).mapNotNull { index ->
                array.optString(index).takeIf { it.isNotEmpty() }
            }
        } ?: emptyList(),
        recurring = obj.optBoolean("recurring", false),
        reminders = obj.optBoolean("reminders", false),
        alarm = obj.optBoolean("alarm", false),
        focusedMinutes = if (obj.has("focusedMinutes")) obj.optInt("focusedMinutes") else null,
    )
}
