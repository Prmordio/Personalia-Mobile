import ActivityKit
import SwiftUI
import WidgetKit

@main
struct WorkoutLiveBundle: WidgetBundle {
    var body: some Widget { WorkoutLiveWidget() }
}

struct WorkoutClock: View {
    let workout: WorkoutSnapshot
    var body: some View {
        if workout.running && workout.phase == "rest" {
            Text(timerInterval: min(Date(), workout.clockDate)...max(Date(), workout.clockDate), countsDown: true)
                .monospacedDigit()
        } else {
            Text(String(format: "%02d:%02d", workout.seconds / 60, workout.seconds % 60)).monospacedDigit()
        }
    }
}

struct WorkoutButtons: View {
    let workout: WorkoutSnapshot
    func button(_ title: String, _ action: String) -> some View {
        Button(title, intent: WorkoutActionIntent(action, workout: workout))
            .buttonStyle(.bordered).tint(.orange)
    }
    var body: some View {
        HStack {
            switch workout.phase {
            case "ready": button(workout.text("startRest", "Start rest"), "rest")
            case "rest":
                Button(intent: WorkoutActionIntent("toggle", workout: workout)) {
                    WorkoutClock(workout: workout)
                }.buttonStyle(.borderedProminent).tint(.orange)
                button("+30 s", "add")
            case "done":
                if workout.hasWeight {
                    if workout.hasNext { button(workout.text("nextExercise", "Next exercise"), "next") }
                } else { Text(workout.text("weightRequired", "Enter weight to finish")) }
            default: EmptyView()
            }
        }.font(.subheadline)
    }
}

private func displayedWorkout(_ context: ActivityViewContext<WorkoutAttributes>) -> WorkoutSnapshot {
    var workout = context.state.workout
    workout.migrateRestFlow()
    if context.isStale { workout.resolveRest() }
    return workout
}

struct WorkoutLiveWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutAttributes.self) { context in
            let workout = displayedWorkout(context)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "dumbbell.fill").foregroundStyle(.orange)
                    Text(workout.exercise.name).font(.headline).lineLimit(1)
                    Spacer()
                    if workout.phase == "rest" {
                        WorkoutClock(workout: workout).font(.title2)
                    }
                }
                Text("\(workout.seriesLabel) · \(workout.exercise.reps) \(workout.text("reps", "Reps"))")
                    .font(.subheadline)
                Text(workout.label).font(.caption)
                if workout.phase == "done" && workout.hasNext {
                    Text(workout.nextLabel).font(.caption)
                }
                WorkoutButtons(workout: workout)
            }.padding().activityBackgroundTint(.black.opacity(0.85)).activitySystemActionForegroundColor(.white)
                .foregroundStyle(.white)
        } dynamicIsland: { context in
            let workout = displayedWorkout(context)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(workout.seriesLabel, systemImage: "dumbbell.fill")
                }
                DynamicIslandExpandedRegion(.trailing) { WorkoutClock(workout: workout) }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack {
                        Text(workout.exercise.name).font(.headline)
                        Text(workout.label).font(.caption)
                        WorkoutButtons(workout: workout)
                    }
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill").foregroundStyle(.orange)
            } compactTrailing: {
                WorkoutClock(workout: workout).frame(maxWidth: 64)
            } minimal: {
                Image(systemName: "dumbbell.fill")
            }
        }
    }
}
