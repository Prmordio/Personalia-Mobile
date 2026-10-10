import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personalia_app/features/assistant/data/assistant_api.dart';
import 'package:personalia_app/features/assistant/state/assistant_chat_controller.dart';
import 'package:personalia_app/features/home/data/app_api.dart';
import 'package:personalia_app/features/workout/data/exercise_image_provider.dart';
import 'package:personalia_app/features/workout/presentation/widgets/exercise_list.dart';

class _FakeAssistantApi extends AssistantApi {
  _FakeAssistantApi() : super(Dio());

  Completer<String>? pendingAnswer;
  EquipmentIdentification photoResult = EquipmentIdentification(found: false, message: 'Não identifiquei.');
  int statusCode = 0;

  @override
  Future<String> ask(String text) async {
    if (pendingAnswer != null) return pendingAnswer!.future;
    return 'Resposta para: $text';
  }

  @override
  Stream<String> askStream(String text) async* {
    if (statusCode != 0) {
      throw DioException(
        requestOptions: RequestOptions(path: '/app/assistant/message-stream'),
        response: Response(
          requestOptions: RequestOptions(path: '/app/assistant/message-stream'),
          statusCode: statusCode,
          data: {'message': 'Você fez muitas perguntas nesta hora.'},
        ),
      );
    }
    if (pendingAnswer != null) {
      yield await pendingAnswer!.future;
    } else {
      yield 'Resposta para: $text';
    }
  }

  @override
  Future<EquipmentIdentification> identifyEquipment(Uint8List bytes, String mimeType) async => photoResult;
}

void main() {
  late _FakeAssistantApi api;
  late AssistantChatController chat;

  setUp(() {
    api = _FakeAssistantApi();
    chat = AssistantChatController(api);
  });

  test('should_start_with_a_welcome_message', () {
    expect(chat.state, hasLength(1));
    expect(chat.state.first.fromUser, isFalse);
  });

  test('should_show_typing_while_waiting_and_block_new_messages', () async {
    api.pendingAnswer = Completer<String>();

    final sending = chat.send('Quanto de proteína?');
    expect(chat.state.last.pending, isTrue);
    expect(chat.isWaiting, isTrue);

    await chat.send('outra');
    expect(chat.state.where((m) => m.fromUser), hasLength(1));

    api.pendingAnswer!.complete('Uns 1,6 g/kg.');
    await sending;
    expect(chat.state.last.text, 'Uns 1,6 g/kg.');
    expect(chat.state.any((m) => m.pending), isFalse);
  });

  test('should_ignore_blank_messages', () async {
    await chat.send('   ');
    expect(chat.state, hasLength(1));
  });

  test('should_show_the_backend_message_on_errors', () async {
    api.statusCode = 429;

    await chat.send('oi');

    expect(chat.state.last.text, 'Você fez muitas perguntas nesta hora.');
    expect(chat.isWaiting, isFalse);
  });

  test('should_describe_an_identified_machine_and_offer_videos', () async {
    api.photoResult = EquipmentIdentification(
      found: true,
      equipmentName: 'Leg Press 45°',
      primaryExercise: 'Leg Press 45',
      muscleGroups: ['Quadríceps', 'Glúteos'],
      description: 'Empurre a plataforma...',
    );

    await chat.sendPhoto(Uint8List.fromList([1, 2, 3]), 'image/jpeg');

    final reply = chat.state.last;
    expect(chat.state[chat.state.length - 2].image, isNotNull);
    expect(reply.text, contains('Leg Press 45°'));
    expect(reply.text, contains('Quadríceps, Glúteos'));
    expect(reply.exerciseName, 'Leg Press 45');
  });

  test('should_explain_when_the_photo_is_not_a_machine', () async {
    await chat.sendPhoto(Uint8List.fromList([1]), 'image/jpeg');

    expect(chat.state.last.text, 'Não identifiquei.');
    expect(chat.state.last.exerciseName, isNull);
  });

  testWidgets('should_render_exercise_cards_with_icon_fallback_and_details', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [exerciseImageProvider.overrideWith((ref, name) async => null)],
        child: MaterialApp(
          home: Scaffold(
            body: ExerciseList(
              exercises: [
                WorkoutExercise.fromJson({'nome': 'Supino Reto', 'series': '4', 'repeticoes': '8-10', 'intervaloDescanso': '90seg'}),
                WorkoutExercise.fromJson({'nome': 'Esteira ou Caminhada', 'series': '1', 'repeticoes': '10 min'}),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supino Reto'), findsOneWidget);
    expect(find.text('4 × 8-10'), findsOneWidget);
    expect(find.text('90seg'), findsOneWidget);
    expect(find.byIcon(Icons.directions_run), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
