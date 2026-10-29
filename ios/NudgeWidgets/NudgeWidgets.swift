// Nudge home-screen widgets (WidgetKit).
//
// This file is ready to drop into a Widget Extension target — see README.md
// in this folder for the three Xcode setup steps. The widget kinds
// ("NudgeUpNextWidget", "NudgeFocusWidget"), the app group and the data keys
// must stay in sync with lib/services/home_widget_service.dart.

import SwiftUI
import WidgetKit

private let appGroup = "group.com.abrar118.nudge"
private let upNextKey = "widget_up_next"
private let focusKey = "widget_focus"

/// Builds a deep link the home_widget plugin will actually forward to Dart.
///
/// Its iOS side ignores any incoming URL without a `homeWidget` query item
/// (`isWidgetUrl` in HomeWidgetPlugin.swift), unlike Android, which passes the
/// launch intent's data through untouched. The `nudge` scheme also has to be
/// registered under `CFBundleURLTypes` in Runner/Info.plist or the URL never
/// reaches the app at all. Dart routes on host + path segments, so both stay
/// as `lib/services/home_widget_service.dart` expects.
private func deepLink(_ path: String) -> URL {
    URL(string: "nudge://\(path)?homeWidget=true")!
}

// MARK: - Shared data

struct WidgetTask: Decodable, Identifiable {
    let id: String
    let title: String
    let due: String?
    let dueMinutes: Int?
    let priority: String?
    let subtasks: String?
    let progress: Int?
    let tags: [String]?
    let recurring: Bool?
    let reminders: Bool?
    let alarm: Bool?
    let focusedMinutes: Int?

    var dueDate: Date? {
        guard let due else { return nil }
        let components = due.split(separator: "-").compactMap { Int($0) }
        guard components.count == 3 else { return nil }
        var date = DateComponents(
            year: components[0], month: components[1], day: components[2])
        if let minutes = dueMinutes {
            date.hour = minutes / 60
            date.minute = minutes % 60
        }
        return Calendar.current.date(from: date)
    }

    func isOverdue(now: Date) -> Bool {
        guard let deadline = dueDate else { return false }
        if dueMinutes == nil {
            return Calendar.current.startOfDay(for: deadline)
                < Calendar.current.startOfDay(for: now)
        }
        return deadline < now
    }

    func deadlineLabel(now: Date) -> String? {
        guard let deadline = dueDate else { return nil }
        let calendar = Calendar.current
        if isOverdue(now: now) {
            let days = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: deadline),
                to: calendar.startOfDay(for: now)
            ).day ?? 0
            if days >= 2 { return "\(days) days overdue" }
            if days == 1 { return "1 day overdue" }
            return "Overdue"
        }
        let base: String
        if calendar.isDateInToday(deadline) {
            base = "Today"
        } else if calendar.isDateInTomorrow(deadline) {
            base = "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            base = formatter.string(from: deadline)
        }
        guard dueMinutes != nil else { return base }
        let time = DateFormatter()
        time.timeStyle = .short
        return "\(base) \(time.string(from: deadline))"
    }

    func deadlineLine(now: Date) -> String {
        deadlineLabel(now: now) ?? "No deadline"
    }

    var detailLine: String {
        var parts: [String] = []
        if let subtasks {
            parts.append("\(subtasks) subtasks")
        } else if let progress {
            parts.append("\(progress)% done")
        }
        if let tags, !tags.isEmpty {
            parts.append(tags.prefix(2).map { "#\($0)" }.joined(separator: " "))
        }
        if recurring == true { parts.append("Repeats") }
        if alarm == true {
            parts.append("Alarm")
        } else if reminders == true {
            parts.append("Reminder")
        }
        if let focusedMinutes, focusedMinutes > 0 {
            parts.append("\(focusedMinutes)m focused")
        }
        return parts.joined(separator: " · ")
    }

    func compactMetaLine(now: Date) -> String {
        detailLine.isEmpty ? deadlineLine(now: now) : "\(deadlineLine(now: now)) · \(detailLine)"
    }

    var priorityLabel: String? {
        switch priority {
        case "high": return "HIGH"
        case "medium": return "MEDIUM"
        case "low": return "LOW"
        default: return nil
        }
    }

    var priorityColor: Color {
        switch priority {
        case "high": return nudgeOverdue
        // Priority is ink except high, as in the app.
        case "medium", "low": return nudgeSecondary
        default: return Color(white: 0.45)
        }
    }
}

private struct FocusPayload: Decodable {
    let items: [WidgetTask]
    let total: Int?
    let overdue: Int?
    let today: Int?
}

private struct UpNextPayload: Decodable {
    let empty: Bool?
    let id: String?
    let title: String?
}

private func loadUpNext() -> WidgetTask? {
    guard
        let raw = UserDefaults(suiteName: appGroup)?.string(forKey: upNextKey),
        let data = raw.data(using: .utf8)
    else { return nil }
    if let probe = try? JSONDecoder().decode(UpNextPayload.self, from: data),
        probe.empty == true {
        return nil
    }
    return try? JSONDecoder().decode(WidgetTask.self, from: data)
}

private func loadFocus() -> FocusPayload {
    guard
        let raw = UserDefaults(suiteName: appGroup)?.string(forKey: focusKey),
        let data = raw.data(using: .utf8),
        let payload = try? JSONDecoder().decode(FocusPayload.self, from: data)
    else { return FocusPayload(items: [], total: 0, overdue: 0, today: 0) }
    return payload
}

// MARK: - Palette

private let nudgeBackground = Color(red: 0.071, green: 0.086, blue: 0.098)
private let nudgeAccent = Color(red: 0.933, green: 0.945, blue: 0.953)
private let nudgePrimary = Color(red: 0.933, green: 0.945, blue: 0.953)
private let nudgeSecondary = Color(red: 0.667, green: 0.702, blue: 0.733)
private let nudgeOverdue = Color(red: 1.0, green: 0.455, blue: 0.408)

// MARK: - Timeline

struct NudgeEntry: TimelineEntry {
    let date: Date
    let upNext: WidgetTask?
    let items: [WidgetTask]
    let total: Int
    let overdue: Int
    let today: Int
}

struct NudgeProvider: TimelineProvider {
    func placeholder(in context: Context) -> NudgeEntry {
        NudgeEntry(date: Date(), upNext: nil, items: [], total: 0, overdue: 0, today: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (NudgeEntry) -> Void) {
        let focus = loadFocus()
        completion(NudgeEntry(
            date: Date(),
            upNext: loadUpNext(),
            items: focus.items,
            total: focus.total ?? focus.items.count,
            overdue: focus.overdue ?? 0,
            today: focus.today ?? 0))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NudgeEntry>) -> Void) {
        let focus = loadFocus()
        let entry = NudgeEntry(
            date: Date(),
            upNext: loadUpNext(),
            items: focus.items,
            total: focus.total ?? focus.items.count,
            overdue: focus.overdue ?? 0,
            today: focus.today ?? 0)
        // Refresh every 30 minutes so relative labels roll over; the app also
        // pushes updates on every change.
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Views

struct UpNextView: View {
    let entry: NudgeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("UP NEXT")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1.1)
                    .foregroundColor(nudgeAccent)
                Spacer()
                if let task = entry.upNext, let label = task.priorityLabel {
                    Text(label)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(task.priorityColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(task.priorityColor.opacity(0.13), in: Capsule())
                }
            }
            if let task = entry.upNext {
                Text(task.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(nudgePrimary)
                    .lineLimit(2)
                Text(task.deadlineLine(now: entry.date))
                    .font(.system(size: 11))
                    .foregroundColor(
                        task.isOverdue(now: entry.date) ? nudgeOverdue : nudgeSecondary)
                    .lineLimit(1)
                if !task.detailLine.isEmpty {
                    Text(task.detailLine)
                        .font(.system(size: 9.5))
                        .foregroundColor(nudgeSecondary)
                        .lineLimit(1)
                }
                if let progress = task.progress {
                    ProgressView(value: Double(progress), total: 100)
                        .tint(nudgeAccent)
                }
            } else {
                Text("You are clear for now.")
                    .font(.system(size: 13))
                    .foregroundColor(nudgeSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(entry.upNext.map { deepLink("task/\($0.id)") })
        .containerBackground(nudgeBackground, for: .widget)
    }
}

struct FocusListView: View {
    let entry: NudgeEntry
    @Environment(\.widgetFamily) private var family

    private var summary: String {
        if entry.overdue > 0 && entry.today > 0 {
            return "\(entry.overdue) overdue · \(entry.today) today"
        }
        if entry.overdue > 0 { return "\(entry.overdue) overdue" }
        if entry.today > 0 { return "\(entry.today) today" }
        return entry.total > 0 ? "\(entry.total) in focus" : ""
    }

    private var rowLimit: Int { family == .systemLarge ? 7 : 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("FOCUS")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(nudgeAccent)
                Spacer()
                if !entry.items.isEmpty {
                    Text(summary)
                        .font(.system(size: 11))
                        .foregroundColor(nudgeSecondary)
                }
                Link(destination: deepLink("quickadd")) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(nudgeAccent))
                }
            }
            if entry.items.isEmpty {
                Spacer()
                Text("You are clear for now.")
                    .font(.system(size: 13))
                    .foregroundColor(nudgeSecondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(entry.items.prefix(rowLimit)) { task in
                    Link(destination: deepLink("task/\(task.id)")) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(task.priorityColor)
                                .frame(width: 6, height: 6)
                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 5) {
                                    Text(task.title)
                                        .font(.system(size: 12.5, weight: .medium))
                                        .foregroundColor(nudgePrimary)
                                        .lineLimit(1)
                                    Spacer(minLength: 2)
                                    if let label = task.priorityLabel {
                                        Text(label)
                                            .font(.system(size: 7.5, weight: .bold))
                                            .foregroundColor(task.priorityColor)
                                    }
                                }
                                Text(
                                    family == .systemLarge
                                        ? task.deadlineLine(now: entry.date)
                                        : task.compactMetaLine(now: entry.date)
                                )
                                    .font(.system(size: 10))
                                    .foregroundColor(
                                        task.isOverdue(now: entry.date)
                                            ? nudgeOverdue : nudgeSecondary)
                                    .lineLimit(1)
                                if family == .systemLarge && !task.detailLine.isEmpty {
                                    Text(task.detailLine)
                                        .font(.system(size: 9))
                                        .foregroundColor(nudgeSecondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .widgetURL(deepLink("focus"))
        .containerBackground(nudgeBackground, for: .widget)
    }
}

// MARK: - Widgets

struct NudgeUpNextWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NudgeUpNextWidget", provider: NudgeProvider()) {
            UpNextView(entry: $0)
        }
        .configurationDisplayName("Up next")
        .description("Your top task with its deadline, priority, and progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NudgeFocusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NudgeFocusWidget", provider: NudgeProvider()) {
            FocusListView(entry: $0)
        }
        .configurationDisplayName("Tasks")
        .description("Your focus list with deadlines, priorities, tags, and progress.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

@main
struct NudgeWidgetBundle: WidgetBundle {
    var body: some Widget {
        NudgeUpNextWidget()
        NudgeFocusWidget()
    }
}
