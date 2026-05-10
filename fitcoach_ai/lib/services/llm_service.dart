import 'dart:async';
import 'dart:convert';

import 'package:fitcoach_ai/models/user_profile.dart';
import 'package:fitcoach_ai/models/weekly_plan.dart';
import 'package:fitcoach_ai/utils/constants.dart';
import 'package:fitcoach_ai/utils/prompt_builder.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LLMService {
  LLMService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<WeeklyPlan> generateWeeklyPlan(UserProfile profile) async {
    final provider = (dotenv.env['LLM_PROVIDER'] ?? '').toLowerCase();
    final apiKey = dotenv.env['LLM_API_KEY'] ?? '';
    final model = dotenv.env['LLM_MODEL'] ?? '';
    final apiUrl = dotenv.env['LLM_API_URL'] ?? '';

    if (provider.isEmpty || apiKey.isEmpty || model.isEmpty || apiUrl.isEmpty) {
      throw const FormatException('Faltan variables de entorno para LLM');
    }

    final userPrompt = PromptBuilder.buildUserPrompt(profile);

    final response = await _postWithRetry(
      provider: provider,
      apiUrl: apiUrl,
      apiKey: apiKey,
      model: model,
      systemPrompt: PromptBuilder.systemPrompt,
      userPrompt: userPrompt,
    );

    if (response.statusCode != 200) {
      throw LLMApiException(response.statusCode, response.body);
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    final rawText = _extractText(provider, responseBody);
    final cleaned = _cleanJsonContent(rawText);

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      throw LLMJsonParseException(cleaned);
    }

    final now = DateTime.now().toUtc();
    final weekLabel = _isoWeekLabel(now);
    final enriched = {
      'plan_id': '${profile.uid}_$weekLabel',
      'uid': profile.uid,
      'generated_at': now.toIso8601String(),
      'week_label': weekLabel,
      ...decoded,
    };

    final weeklyPlan = WeeklyPlan.fromJson(enriched);
    if (weeklyPlan.trainingDays.length != profile.trainingDaysPerWeek) {
      throw LLMValidationException(
        'training_days esperado: ${profile.trainingDaysPerWeek}, recibido: ${weeklyPlan.trainingDays.length}',
      );
    }

    return weeklyPlan;
  }

  Future<http.Response> _postWithRetry({
    required String provider,
    required String apiUrl,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final delays = [2, 4, 8];
    Exception? lastError;

    for (var attempt = 0; attempt <= delays.length; attempt++) {
      try {
        if (provider == 'openai') {
          return await _httpClient
              .post(
                Uri.parse(apiUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $apiKey',
                },
                body: jsonEncode({
                  'model': model,
                  'temperature': 0.7,
                  'max_tokens': 4000,
                  'messages': [
                    {'role': 'system', 'content': systemPrompt},
                    {'role': 'user', 'content': userPrompt},
                  ],
                }),
              )
              .timeout(const Duration(seconds: 30));
        }

        return await _httpClient
            .post(
              Uri.parse('$apiUrl?key=$apiKey'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': '$systemPrompt\n\n$userPrompt'}
                    ]
                  }
                ],
                'generationConfig': {
                  'temperature': 0.7,
                  'maxOutputTokens': 4000,
                  'responseMimeType': 'application/json',
                },
              }),
            )
            .timeout(const Duration(seconds: 30));
      } on Exception catch (e) {
        lastError = e;
        if (attempt < delays.length) {
          await Future<void>.delayed(Duration(seconds: delays[attempt]));
          continue;
        }
      }
    }

    throw lastError ?? Exception('Error desconocido en solicitud LLM');
  }

  String _extractText(String provider, Map<String, dynamic> body) {
    if (provider == 'openai') {
      return body['choices'][0]['message']['content'] as String;
    }
    return body['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  String _cleanJsonContent(String rawText) {
    return rawText
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
  }

  String _isoWeekLabel(DateTime date) {
    final target = date.add(Duration(days: 4 - (date.weekday == 7 ? 7 : date.weekday)));
    final firstThursday = DateTime.utc(target.year, 1, 4);
    final firstWeekStart = firstThursday.subtract(Duration(days: firstThursday.weekday - 1));
    final currentWeekStart = target.subtract(Duration(days: target.weekday - 1));
    final weekNumber = ((currentWeekStart.difference(firstWeekStart).inDays) / 7).floor() + 1;
    return '${target.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }
}
