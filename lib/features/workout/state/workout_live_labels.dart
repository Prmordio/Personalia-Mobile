import '../../../l10n/app_localizations.dart';

/// The same app-selected language is persisted for suspended native controls.
Map<String, String> workoutLiveLabels(AppLocalizations l) => {
  'rest': l.restStatusRest,
  'paused': l.restStatusPaused,
  'nextSet': l.restNextSet,
  'betweenSets': l.restBetweenSets,
  'done': l.restExerciseDone,
  'weightRequired': l.restWeightHint,
  'startRest': l.restBtnStartRest,
  'nextExercise': l.restBtnNextExercise,
  'pause': l.restPause,
  'resume': l.restResume,
  'endRest': l.restEndRest,
  'sets': l.restStatSeries,
  'reps': l.restStatReps,
  'workout': l.todayWorkoutTitle,
  'restFinished': l.restFinishedTitle,
  'nextSetMessage': l.restSetFinishedMsg,
  'nextExerciseMessage': l.restInterExerciseMsg,
  'nextPrefix': l.restNextNamed(''),
};
