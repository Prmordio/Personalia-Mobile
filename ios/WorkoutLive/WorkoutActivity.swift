import ActivityKit
import AppIntents
import Foundation
import UserNotifications

struct WorkoutExerciseState: Codable, Hashable {
    var name: String
    var reps: String
    var sets: Int
    var restSeconds: Int
}

struct WorkoutSnapshot: Codable, Hashable {
    var id: String
    var date: String
    var day: String
    var exercises: [WorkoutExerciseState]
    var index: Int
    var completed: [Int]
    var phase: String
    var running: Bool
    var seconds: Int
    var anchor: Double
    var revision: Int
    var restExpiredFromRevision: Int? = nil
    var flowVersion: Int? = nil
    var pendingRestCounted: Bool? = nil
    var labels: [String: String]? = nil
    var startedAt: Double? = nil
    var weights: [String: String]? = nil
    var hasWeight: Bool { !(weights?[exercise.name] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func text(_ key: String, _ fallback: String) -> String { labels?[key] ?? fallback }
    var seriesLabel: String { "\(text("sets", "Sets")) \(currentSet)/\(exercise.sets)" }
    var nextLabel: String { text("nextPrefix", "Next: ") + exercises[index + 1].name }

    var exercise: WorkoutExerciseState { exercises[index] }
    var currentSet: Int { min(max(1, phase == "rest" || pendingRestCounted == true ? completed[index] : completed[index] + 1), exercise.sets) }
    var hasNext: Bool { index + 1 < exercises.count }
    var clockDate: Date {
        Date(timeIntervalSince1970: anchor / 1000 + Double(phase == "rest" ? seconds : -seconds))
    }
    var label: String {
        switch phase {
        case "ready": return completed[index] > 0 ? text("nextSet", "Next set") : text("betweenSets", "Rest between sets")
        case "awaitRest": return text("nextSet", "Next set")
        case "rest": return running ? text("rest", "Rest") : text("paused", "Rest paused")
        case "done": return text("done", "Exercise completed!")
        default: return text("paused", "Rest paused")
        }
    }

    @discardableResult mutating func migrateRestFlow() -> Bool {
        guard flowVersion != 2 else { return false }
        if phase == "awaitRest" { pendingRestCounted = true }
        if phase == "exercise" || phase == "awaitRest" { phase = "ready"; running = false; seconds = 0 }
        flowVersion = 2; revision += 1
        return true
    }

    mutating func act(_ action: String, now: Date = Date()) {
        migrateRestFlow()
        resolveRest(now: now)
        let time = now.timeIntervalSince1970 * 1000
        if running && phase == "rest" { seconds = max(0, seconds - Int((time - anchor) / 1000)) }
        anchor = time
        switch (action, phase) {
        case ("rest", "ready") where completed[index] < exercise.sets:
            if startedAt == nil { startedAt = time }
            if pendingRestCounted != true { completed[index] += 1 }
            pendingRestCounted = nil
            phase = "rest"; running = true; seconds = exercise.restSeconds
        case ("toggle", "rest"):
            running.toggle()
        case ("add", "rest"):
            seconds += 30
        case ("skip", "rest"):
            phase = completed[index] >= exercise.sets ? "done" : "ready"
            running = false; seconds = 0
        case ("next", "done") where hasNext && hasWeight:
            index += 1; phase = "ready"; running = false; seconds = 0
        default: return
        }
        restExpiredFromRevision = nil
        revision += 1
        resolveRest(now: now)
    }

    @discardableResult mutating func resolveRest(now: Date = Date()) -> Bool {
        guard phase == "rest", running, now >= clockDate else { return false }
        restExpiredFromRevision = revision
        phase = completed[index] >= exercise.sets ? "done" : "ready"
        running = false; seconds = 0; revision += 1
        return true
    }
}

@available(iOS 17.0, *)
struct WorkoutAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var workout: WorkoutSnapshot
    }
    var sessionID: String
}

/// LiveActivityIntent runs in the app process, so its storage is the same as
/// the Flutter bridge. The widget only reads ActivityKit's content state.
@available(iOS 17.0, *)
@MainActor enum WorkoutActivityStore {
    static let key = "personalia.workout.live"
    static let alarmID = "personalia.workout.rest"

    static func read() -> WorkoutSnapshot? {
        guard let raw = UserDefaults.standard.data(forKey: key),
              var state = try? JSONDecoder().decode(WorkoutSnapshot.self, from: raw) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard state.date == formatter.string(from: Date()) else {
            UserDefaults.standard.removeObject(forKey: key)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarmID])
            Task {
                for activity in Activity<WorkoutAttributes>.activities where activity.attributes.sessionID == state.id {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
            return nil
        }
        let migrated = state.migrateRestFlow()
        let expired = state.resolveRest()
        if migrated || expired {
            try? save(state)
            let resolved = state
            Task {
                for activity in Activity<WorkoutAttributes>.activities where activity.attributes.sessionID == resolved.id {
                    let latest = read() ?? resolved
                    await activity.update(ActivityContent(state: WorkoutAttributes.ContentState(workout: latest),
                        staleDate: latest.phase == "rest" && latest.running ? latest.clockDate : nil))
                }
            }
        }
        return state
    }

    static func json(_ state: WorkoutSnapshot?) throws -> String? {
        guard let state else { return nil }
        return String(data: try JSONEncoder().encode(state), encoding: .utf8)
    }

    static func prepare(_ raw: String) async throws -> WorkoutSnapshot {
        let state = try JSONDecoder().decode(WorkoutSnapshot.self, from: Data(raw.utf8))
        await end()
        try save(state)
        await scheduleRestNotification(state)
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            _ = try? Activity.request(attributes: WorkoutAttributes(sessionID: state.id),
                content: ActivityContent(state: WorkoutAttributes.ContentState(workout: state), staleDate: nil), pushType: nil)
        }
        return state
    }

    static func localize(_ raw: String) async throws -> WorkoutSnapshot? {
        guard var state = read() else { return nil }
        state.labels = try JSONDecoder().decode([String: String].self, from: Data(raw.utf8))
        try save(state)
        await scheduleRestNotification(state)
        for activity in Activity<WorkoutAttributes>.activities where activity.attributes.sessionID == state.id {
            await activity.update(ActivityContent(state: WorkoutAttributes.ContentState(workout: state),
                staleDate: state.phase == "rest" && state.running ? state.clockDate : nil))
        }
        return state
    }

    private static func scheduleRestNotification(_ state: WorkoutSnapshot) async {
        guard state.phase == "rest", state.running else { return }
        let content = UNMutableNotificationContent()
        let lastSet = state.completed[state.index] >= state.exercise.sets
        content.title = lastSet ? state.text("nextExercise", "Next exercise") : state.text("nextSet", "Next set")
        content.body = (lastSet ? state.text("nextExerciseMessage", "Ready for the next exercise.") :
            state.text("nextSetMessage", "Time for the next set!")) + " " + state.exercise.name
        content.sound = .default
        let seconds = max(1, state.clockDate.timeIntervalSinceNow)
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: alarmID, content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)))
    }

    static func weight(id: String, name: String, value: String) async throws -> WorkoutSnapshot? {
        guard var state = read() else { return nil }
        guard state.id == id, state.exercises.contains(where: { $0.name == name }) else { return state }
        if state.weights == nil { state.weights = [:] }
        state.weights?[name] = value
        try save(state)
        for activity in Activity<WorkoutAttributes>.activities where activity.attributes.sessionID == state.id {
            await activity.update(ActivityContent(state: WorkoutAttributes.ContentState(workout: state),
                staleDate: state.phase == "rest" && state.running ? state.clockDate : nil))
        }
        return state
    }

    private static func save(_ state: WorkoutSnapshot) throws {
        UserDefaults.standard.set(try JSONEncoder().encode(state), forKey: key)
    }

    static func end() async {
        UserDefaults.standard.removeObject(forKey: key)
        let notifications = UNUserNotificationCenter.current()
        notifications.removePendingNotificationRequests(withIdentifiers: [alarmID])
        notifications.removeDeliveredNotifications(withIdentifiers: [alarmID])
        for activity in Activity<WorkoutAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    static func action(_ action: String, id: String, revision: Int) async throws -> WorkoutSnapshot? {
        guard var state = read() else { return nil }
        guard state.id == id && (state.revision == revision ||
            (action == "rest" && state.restExpiredFromRevision == revision)) else { return state }
        state.act(action)
        try save(state)
        let notifications = UNUserNotificationCenter.current()
        notifications.removePendingNotificationRequests(withIdentifiers: [alarmID])
        notifications.removeDeliveredNotifications(withIdentifiers: [alarmID])
        await scheduleRestNotification(state)
        let content = ActivityContent(state: WorkoutAttributes.ContentState(workout: state),
            staleDate: state.phase == "rest" && state.running ? state.clockDate : nil)
        if let activity = Activity<WorkoutAttributes>.activities.first(where: { $0.attributes.sessionID == state.id }) {
            await activity.update(content)
        } else if ActivityAuthorizationInfo().areActivitiesEnabled {
            // A denied/disabled Live Activity must never block exercise controls.
            _ = try? Activity.request(attributes: WorkoutAttributes(sessionID: state.id), content: content, pushType: nil)
        }
        return state
    }
}

@available(iOS 17.0, *)
struct WorkoutActionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Controlar treino"
    static var openAppWhenRun = false
    @Parameter(title: "Ação") var action: String
    @Parameter(title: "Sessão") var sessionID: String
    @Parameter(title: "Revisão") var revision: Int

    init() {}
    init(_ action: String, workout: WorkoutSnapshot) {
        self.action = action; self.sessionID = workout.id; self.revision = workout.revision
    }
    func perform() async throws -> some IntentResult {
        _ = try await WorkoutActivityStore.action(action, id: sessionID, revision: revision)
        return .result()
    }
}
