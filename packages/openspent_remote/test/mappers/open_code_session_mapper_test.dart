import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_remote/src/mappers/open_code_session_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('OpenCodeSessionMapper', () {
    test('aggregates assistant messages and ignores parts', () {
      const mapper = OpenCodeSessionMapper();

      final session = mapper.map(
        session: <String, dynamic>{
          'id': 'session-1',
          'time': <String, dynamic>{'created': 1715000000000},
        },
        messages: <Map<String, dynamic>>[
          <String, dynamic>{
            'info': <String, dynamic>{
              'role': 'user',
              'time': <String, dynamic>{'created': 1715000000100},
            },
            'parts': <Map<String, dynamic>>[
              <String, dynamic>{'type': 'text', 'text': 'prompt'},
            ],
          },
          <String, dynamic>{
            'info': <String, dynamic>{
              'role': 'assistant',
              'time': <String, dynamic>{'created': 1715000000200},
              'modelID': 'gpt-4.1',
              'cost': 0.25,
              'tokens': <String, dynamic>{'input': 10, 'output': 20},
            },
            'parts': <Map<String, dynamic>>[
              <String, dynamic>{'type': 'text', 'text': 'ignored'},
              <String, dynamic>{'type': 'tool', 'cost': 999},
            ],
          },
          <String, dynamic>{
            'info': <String, dynamic>{
              'role': 'assistant',
              'time': <String, dynamic>{'created': 1715000000300},
              'modelID': 'gpt-5.4',
              'cost': 0.5,
              'tokens': <String, dynamic>{'input': 30, 'output': 40},
            },
            'parts': <Map<String, dynamic>>[
              <String, dynamic>{'type': 'text', 'text': 'also ignored'},
            ],
          },
        ],
      );

      expect(
        session,
        OpenCodeSession(
          id: 'session-1',
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            1715000000000,
            isUtc: true,
          ),
          modelName: 'gpt-5.4',
          inputTokens: 40,
          outputTokens: 60,
          totalCostUsd: 0.75,
          subagentCategory: null,
        ),
      );
    });

    test('leaves aggregated assistant fields null when none exist', () {
      const mapper = OpenCodeSessionMapper();

      final session = mapper.map(
        session: <String, dynamic>{
          'id': 'session-2',
          'time': <String, dynamic>{'created': 1715000100000},
        },
        messages: <Map<String, dynamic>>[
          <String, dynamic>{
            'info': <String, dynamic>{
              'role': 'user',
              'time': <String, dynamic>{'created': 1715000100100},
            },
            'parts': <Map<String, dynamic>>[],
          },
        ],
      );

      expect(
        session,
        OpenCodeSession(
          id: 'session-2',
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            1715000100000,
            isUtc: true,
          ),
        ),
      );
    });
  });
}
