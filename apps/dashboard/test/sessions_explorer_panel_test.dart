import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_dashboard/l10n/app_localizations.dart';
import 'package:openspent_dashboard/src/screens/sessions/cubit/sessions_cubit.dart';
import 'package:openspent_dashboard/src/sessions/import_selection.dart';
import 'package:openspent_dashboard/src/sessions/sessions_explorer_panel.dart';
import 'package:openspent_local/openspent_local.dart';

class _FakeSessionRepository implements OpenCodeSessionRepository {
  _FakeSessionRepository([List<OpenCodeSession>? sessions])
    : _sessions = sessions ?? <OpenCodeSession>[];

  final List<OpenCodeSession> _sessions;

  @override
  Future<List<OpenCodeSession>> readSessions() async {
    return List<OpenCodeSession>.from(_sessions);
  }

  @override
  Future<void> writeSessions(Iterable<OpenCodeSession> sessions) async {
    _sessions
      ..clear()
      ..addAll(sessions);
  }
}

OpenCodeSession _session({
  required String id,
  required DateTime createdAt,
  String? modelName,
  int? inputTokens,
  int? outputTokens,
  double? totalCostUsd,
  String? subagentCategory,
}) {
  return OpenCodeSession(
    id: id,
    createdAt: createdAt,
    modelName: modelName,
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    totalCostUsd: totalCostUsd,
    subagentCategory: subagentCategory,
  );
}

SessionsCubitDependencies _buildDependencies({
  List<OpenCodeSession>? sessions,
  OpenCodeSessionRepository Function(OpenCodeSettings settings)?
  remoteRepositoryFactory,
  OpenCodeSessionRepository Function(String path)?
  importedSqlitePathRepositoryFactory,
  OpenCodeSessionRepository Function(Uint8List bytes)?
  importedSqliteBytesRepositoryFactory,
}) {
  return SessionsCubitDependencies(
    localRepository: _FakeSessionRepository(sessions),
    jsonParser: const OpenCodeSessionJsonParser(),
    remoteRepositoryFactory:
        remoteRepositoryFactory ?? (_) => _FakeSessionRepository(),
    importedSqlitePathRepositoryFactory: importedSqlitePathRepositoryFactory,
    importedSqliteBytesRepositoryFactory: importedSqliteBytesRepositoryFactory,
  );
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required SessionsCubit cubit,
  required bool isConnected,
  Uri? serverUrl,
  Future<ImportSelection?> Function()? pickImportSource,
  VoidCallback? onDataChanged,
  String? selectedModelFilter,
  DateTime? selectedDay,
  int? selectedUtcHour,
  VoidCallback? onClearModelFilter,
  DateTime? windowFrom,
  DateTime? windowTo,
  bool wrapInScrollView = true,
}) async {
  tester.view.physicalSize = const Size(1440, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<SessionsCubit>.value(
          value: cubit,
          child: wrapInScrollView
              ? SingleChildScrollView(
                  child: SessionsExplorerPanel(
                    serverUrl: serverUrl,
                    isConnected: isConnected,
                    onDataChanged: onDataChanged ?? () {},
                    pickImportSource: pickImportSource ?? (() async => null),
                    selectedModelFilter: selectedModelFilter,
                    selectedDay: selectedDay,
                    selectedUtcHour: selectedUtcHour,
                    onClearModelFilter: onClearModelFilter,
                    windowFrom: windowFrom,
                    windowTo: windowTo,
                  ),
                )
              : SessionsExplorerPanel(
                  serverUrl: serverUrl,
                  isConnected: isConnected,
                  onDataChanged: onDataChanged ?? () {},
                  pickImportSource: pickImportSource ?? (() async => null),
                  selectedModelFilter: selectedModelFilter,
                  selectedDay: selectedDay,
                  selectedUtcHour: selectedUtcHour,
                  onClearModelFilter: onClearModelFilter,
                  windowFrom: windowFrom,
                  windowTo: windowTo,
                ),
        ),
      ),
    ),
  );

  await tester.binding.setLocale('en', 'US');
  await tester.pumpAndSettle();
}

Future<SessionsCubit> _buildLoadedCubit({
  List<OpenCodeSession>? sessions,
  OpenCodeSessionRepository Function(OpenCodeSettings settings)?
  remoteRepositoryFactory,
  OpenCodeSessionRepository Function(String path)?
  importedSqlitePathRepositoryFactory,
  OpenCodeSessionRepository Function(Uint8List bytes)?
  importedSqliteBytesRepositoryFactory,
}) async {
  final cubit = SessionsCubit(
    dependencies: _buildDependencies(
      sessions: sessions,
      remoteRepositoryFactory: remoteRepositoryFactory,
      importedSqlitePathRepositoryFactory: importedSqlitePathRepositoryFactory,
      importedSqliteBytesRepositoryFactory:
          importedSqliteBytesRepositoryFactory,
    ),
  );
  await cubit.load();
  return cubit;
}

String _renderedText(Widget widget) {
  if (widget is Text) {
    return widget.data ?? widget.textSpan?.toPlainText() ?? '';
  }
  return '';
}

List<String> _rowIdTexts(Finder root) {
  final ids = <String>[];

  for (final element
      in find.descendant(of: root, matching: find.byType(Text)).evaluate()) {
    final text = _renderedText(element.widget);
    final marker = text.indexOf('ID: ');
    if (marker != -1) {
      ids.add(text.substring(marker));
    }
  }

  return ids;
}

List<String> _spotlightRowIds(WidgetTester tester, {int count = 3}) {
  final ids = _rowIdTexts(find.byKey(const Key('sessions-spotlight-panel')));
  expect(ids.length, greaterThanOrEqualTo(count));
  return ids.take(count).toList();
}

List<String> _listRowIds(WidgetTester tester) {
  return _rowIdTexts(find.byKey(const Key('sessions-list')));
}

Future<void> _expectSpotlightMatchesListFirstThree(WidgetTester tester) async {
  final listIds = _listRowIds(tester);
  final spotlightIds = _spotlightRowIds(tester);

  expect(listIds.length, greaterThanOrEqualTo(3));
  expect(spotlightIds, listIds.take(3).toList());
}

void main() {
  testWidgets('shows disconnected empty state and disabled sync', (
    WidgetTester tester,
  ) async {
    final cubit = await _buildLoadedCubit();
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: false,
      serverUrl: Uri.parse('http://localhost:4096'),
    );

    expect(
      find.text(
        '> No cached sessions found. Connect to the local server or import data to begin.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows imported session after successful import', (
    WidgetTester tester,
  ) async {
    var callbackCount = 0;
    final cubit = await _buildLoadedCubit();
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      serverUrl: Uri.parse('http://localhost:4096'),
      pickImportSource: () async => ImportSelection.json(
        '[{"id":"ses_imported","createdAt":"2026-05-08T12:00:00Z","modelName":"o4-mini","inputTokens":10,"outputTokens":5,"totalCostUsd":0.05}]',
        sourceLabel: 'test.json',
      ),
      onDataChanged: () {
        callbackCount++;
      },
    );

    await tester.tap(find.byKey(const Key('sessions-import-button')));
    await tester.pumpAndSettle();

    expect(find.text('> Import completed successfully.'), findsOneWidget);
    expect(find.textContaining('ses_impo'), findsWidgets);
    expect(callbackCount, 1);

    // Check cached history and last operation render correctly
    expect(find.text('-- CACHED HISTORY --'), findsOneWidget);
    expect(find.text('> Sessions .......... 1'), findsOneWidget);
    expect(find.text('-- LAST OPERATION --'), findsOneWidget);
    expect(find.text('> Type .............. IMPORT JSON'), findsOneWidget);
    expect(find.text('> Status ............ SUCCESS'), findsOneWidget);
    expect(find.text('> Source ............ test.json'), findsOneWidget);
  });

  testWidgets('shows invalid import message for broken json', (
    WidgetTester tester,
  ) async {
    final cubit = await _buildLoadedCubit();
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      serverUrl: Uri.parse('http://localhost:4096'),
      pickImportSource: () async => ImportSelection.json('{bad json}'),
    );

    await tester.tap(find.byKey(const Key('sessions-import-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('> Import failed: invalid format or error.'),
      findsOneWidget,
    );
  });

  testWidgets('shows imported session after successful sqlite import', (
    WidgetTester tester,
  ) async {
    var callbackCount = 0;
    String? importedPath;
    const sqlitePath = '/tmp/opencode.db';
    final cubit = await _buildLoadedCubit(
      importedSqlitePathRepositoryFactory: (path) {
        importedPath = path;
        return _FakeSessionRepository([
          _session(
            id: 'ses_sqlite',
            createdAt: DateTime.utc(2026, 5, 8, 12),
            modelName: 'o4-mini',
            inputTokens: 11,
            outputTokens: 7,
            totalCostUsd: 0.42,
          ),
        ]);
      },
    );
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      serverUrl: Uri.parse('http://localhost:4096'),
      pickImportSource: () async =>
          const ImportSelection.sqlitePath(sqlitePath),
      onDataChanged: () {
        callbackCount++;
      },
    );

    await tester.tap(find.byKey(const Key('sessions-import-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('> Import completed successfully.'), findsOneWidget);
    expect(find.textContaining('ses_sqli'), findsWidgets);
    expect(callbackCount, 1);
    expect(importedPath, sqlitePath);
  });

  testWidgets('shows error when sqlite import fails due to invalid file', (
    WidgetTester tester,
  ) async {
    final cubit = await _buildLoadedCubit();
    addTearDown(cubit.close);
    final sqliteFile = File('/does/not/exist.db');

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      serverUrl: Uri.parse('http://localhost:4096'),
      pickImportSource: () async => ImportSelection.sqlitePath(sqliteFile.path),
    );

    await tester.tap(find.byKey(const Key('sessions-import-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('> Import failed: invalid format or error.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows imported session after successful uploaded sqlite import',
    (WidgetTester tester) async {
      var callbackCount = 0;
      Uint8List? importedBytes;
      final sqliteBytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
      final cubit = await _buildLoadedCubit(
        importedSqliteBytesRepositoryFactory: (bytes) {
          importedBytes = bytes;
          return _FakeSessionRepository([
            _session(
              id: 'ses_sqlite_web',
              createdAt: DateTime.utc(2026, 5, 8, 12),
              modelName: 'o4-mini',
              inputTokens: 11,
              outputTokens: 7,
              totalCostUsd: 0.42,
            ),
          ]);
        },
      );
      addTearDown(cubit.close);

      await _pumpPanel(
        tester,
        cubit: cubit,
        isConnected: true,
        serverUrl: Uri.parse('http://localhost:4096'),
        pickImportSource: () async =>
            ImportSelection.sqliteBytes(sqliteBytes, sourceLabel: 'upload.db'),
        onDataChanged: () {
          callbackCount++;
        },
      );

      await tester.tap(find.byKey(const Key('sessions-import-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('> Import completed successfully.'), findsOneWidget);
      expect(find.textContaining('ses_sqli'), findsWidgets);
      expect(callbackCount, 1);
      expect(importedBytes, same(sqliteBytes));
    },
  );

  testWidgets('shows explicit WAL upload message for browser sqlite import', (
    WidgetTester tester,
  ) async {
    final walBytes = Uint8List(100)
      ..setRange(
        0,
        'SQLite format 3\u0000'.length,
        'SQLite format 3\u0000'.codeUnits,
      )
      ..[18] = 2
      ..[19] = 2;

    final cubit = await _buildLoadedCubit(
      importedSqliteBytesRepositoryFactory: (bytes) =>
          OpenCodeUploadedSqliteSessionRepository(
            bytes,
            onWillAttemptDatabaseOpen: () {
              fail('WAL upload should be rejected before DB open');
            },
          ),
    );
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      serverUrl: Uri.parse('http://localhost:4096'),
      pickImportSource: () async =>
          ImportSelection.sqliteBytes(walBytes, sourceLabel: 'upload.db'),
    );

    await tester.tap(find.byKey(const Key('sessions-import-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        '> Browser import requires a standalone SQLite file. WAL-mode OpenCode databases are not supported for single-file uploads yet.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        '> Error ............. operation failed. Check source data or server status.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'keeps spotlight ranking aligned with the scoped list across sort toggles',
    (WidgetTester tester) async {
      final cubit = await _buildLoadedCubit(
        sessions: [
          _session(
            id: 'alpha111',
            createdAt: DateTime.utc(2026, 5, 8, 9, 5),
            modelName: 'gpt-5.4',
            inputTokens: 10,
            outputTokens: 5,
            totalCostUsd: 0.10,
          ),
          _session(
            id: 'beta2222',
            createdAt: DateTime.utc(2026, 5, 8, 9, 15),
            modelName: 'gpt-5.4',
            inputTokens: 30,
            outputTokens: 9,
            totalCostUsd: 0.30,
          ),
          _session(
            id: 'gamma333',
            createdAt: DateTime.utc(2026, 5, 8, 9, 25),
            modelName: 'gpt-5.4',
            inputTokens: 20,
            outputTokens: 7,
            totalCostUsd: 0.20,
          ),
          _session(
            id: 'delta444',
            createdAt: DateTime.utc(2026, 5, 8, 9, 35),
            modelName: 'gpt-5.4',
            inputTokens: 40,
            outputTokens: 11,
            totalCostUsd: 0.40,
          ),
          _session(
            id: 'outside1',
            createdAt: DateTime.utc(2026, 5, 8, 9, 45),
            modelName: 'claude-3',
            inputTokens: 100,
            outputTokens: 50,
            totalCostUsd: 1.00,
          ),
          _session(
            id: 'outside2',
            createdAt: DateTime.utc(2026, 5, 8, 10, 5),
            modelName: 'gpt-5.4',
            inputTokens: 100,
            outputTokens: 50,
            totalCostUsd: 1.00,
          ),
        ],
      );
      addTearDown(cubit.close);

      await _pumpPanel(
        tester,
        cubit: cubit,
        isConnected: true,
        serverUrl: Uri.parse('http://localhost:4096'),
        selectedModelFilter: 'gpt-5.4',
        selectedDay: DateTime.utc(2026, 5, 8),
        selectedUtcHour: 9,
        windowFrom: DateTime.utc(2026, 5, 8, 9),
        windowTo: DateTime.utc(2026, 5, 8, 9, 59, 59),
        wrapInScrollView: true,
      );

      expect(find.textContaining('outside1'), findsNothing);
      expect(find.textContaining('outside2'), findsNothing);

      for (final sortKey in <String>[
        'sessions-sort-latest',
        'sessions-sort-cost',
        'sessions-sort-tokens',
      ]) {
        await tester.tap(find.byKey(Key(sortKey)));
        await tester.pumpAndSettle();
        await _expectSpotlightMatchesListFirstThree(tester);
      }
    },
  );

  testWidgets('sync success reports status and notifies parent once', (
    WidgetTester tester,
  ) async {
    var callbackCount = 0;
    final cubit = await _buildLoadedCubit(
      remoteRepositoryFactory: (_) => _FakeSessionRepository([
        _session(id: 'ses_synced', createdAt: DateTime.utc(2026, 5, 8, 13)),
      ]),
    );
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      serverUrl: Uri.parse('http://localhost:4096'),
      onDataChanged: () {
        callbackCount++;
      },
    );

    await tester.tap(find.byKey(const Key('sessions-sync-button')));
    await tester.pumpAndSettle();

    expect(find.text('> Sync completed successfully.'), findsOneWidget);
    expect(find.textContaining('ses_sync'), findsWidgets);
    expect(callbackCount, 1);
  });

  testWidgets('filters sessions by selected model and clears filter', (
    WidgetTester tester,
  ) async {
    final cubit = await _buildLoadedCubit(
      sessions: [
        _session(
          id: 'ses_gpt',
          createdAt: DateTime.utc(2026, 5, 8, 12),
          modelName: 'gpt-4o',
          inputTokens: 100,
          outputTokens: 50,
          totalCostUsd: 0.42,
        ),
        _session(
          id: 'ses_claude',
          createdAt: DateTime.utc(2026, 5, 8, 11),
          modelName: 'claude-3',
          inputTokens: 200,
          outputTokens: 100,
          totalCostUsd: 0.84,
        ),
      ],
    );
    addTearDown(cubit.close);

    bool clearFilterCalled = false;

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      serverUrl: Uri.parse('http://localhost:4096'),
      selectedModelFilter: 'gpt-4o',
      onClearModelFilter: () {
        clearFilterCalled = true;
      },
    );

    // The clear filter banner should be visible
    expect(find.text('> Model filter ...... gpt-4o'), findsOneWidget);
    expect(find.text('[ CLEAR ]'), findsOneWidget);

    // Only 'gpt-4o' session should be shown
    expect(find.textContaining('ses_gpt'), findsWidgets);
    expect(find.textContaining('ses_clau'), findsNothing);

    // Tap clear filter
    await tester.tap(find.byKey(const Key('sessions-clear-filter')));
    await tester.pumpAndSettle();
    expect(clearFilterCalled, isTrue);
  });

  testWidgets('shows empty state when no sessions match filter', (
    WidgetTester tester,
  ) async {
    final cubit = await _buildLoadedCubit(
      sessions: [
        _session(
          id: 'ses_claude',
          createdAt: DateTime.utc(2026, 5, 8, 11),
          modelName: 'claude-3',
        ),
      ],
    );
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      serverUrl: Uri.parse('http://localhost:4096'),
      selectedModelFilter: 'gpt-4o',
    );

    expect(
      find.text('> No sessions match the active filters.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('sessions-list')), findsNothing);
  });

  testWidgets(
    'shows an empty panel when selected day is outside the visible window',
    (WidgetTester tester) async {
      final cubit = await _buildLoadedCubit(
        sessions: [
          _session(
            id: 'ses_window',
            createdAt: DateTime.utc(2026, 5, 8, 11),
            modelName: 'gpt-5.4',
          ),
        ],
      );
      addTearDown(cubit.close);

      await _pumpPanel(
        tester,
        cubit: cubit,
        isConnected: true,
        serverUrl: Uri.parse('http://localhost:4096'),
        selectedDay: DateTime.utc(2026, 5, 8),
        windowFrom: DateTime.utc(2026, 5, 9),
        windowTo: DateTime.utc(2026, 5, 9, 23, 59, 59),
        wrapInScrollView: true,
      );

      expect(find.text('> Day filter ........ 2026-05-08'), findsOneWidget);
      expect(find.byKey(const Key('sessions-empty-state')), findsOneWidget);
      expect(find.byKey(const Key('sessions-list')), findsNothing);
      expect(find.textContaining('ses_window'), findsNothing);
    },
  );

  testWidgets('breaks equal cost and token ties by newer createdAt then id', (
    WidgetTester tester,
  ) async {
    final cubit = await _buildLoadedCubit(
      sessions: [
        _session(
          id: 'b1111111',
          createdAt: DateTime.utc(2026, 5, 8, 10),
          modelName: 'gpt-5.4',
          inputTokens: 100,
          outputTokens: 50,
          totalCostUsd: 1.00,
        ),
        _session(
          id: 'a2222222',
          createdAt: DateTime.utc(2026, 5, 8, 11),
          modelName: 'gpt-5.4',
          inputTokens: 100,
          outputTokens: 50,
          totalCostUsd: 1.00,
        ),
        _session(
          id: 'c3333333',
          createdAt: DateTime.utc(2026, 5, 8, 11),
          modelName: 'gpt-5.4',
          inputTokens: 100,
          outputTokens: 50,
          totalCostUsd: 1.00,
        ),
      ],
    );
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      serverUrl: Uri.parse('http://localhost:4096'),
      selectedModelFilter: 'gpt-5.4',
      selectedDay: DateTime.utc(2026, 5, 8),
      wrapInScrollView: true,
    );

    for (final sortKey in <String>[
      'sessions-sort-cost',
      'sessions-sort-tokens',
    ]) {
      await tester.tap(find.byKey(Key(sortKey)));
      await tester.pumpAndSettle();

      final spotlightIds = _spotlightRowIds(tester, count: 3);
      final listIds = _listRowIds(tester);

      expect(spotlightIds, <String>[
        'ID: a2222222',
        'ID: c3333333',
        'ID: b1111111',
      ]);
      expect(listIds, <String>['ID: a2222222', 'ID: c3333333', 'ID: b1111111']);
    }
  });

  testWidgets('matches model filter with trimmed case-insensitive names', (
    WidgetTester tester,
  ) async {
    final cubit = await _buildLoadedCubit(
      sessions: [
        _session(
          id: 'ses_gpt',
          createdAt: DateTime.utc(2026, 5, 8, 12),
          modelName: '  GPT-4O  ',
        ),
        _session(
          id: 'ses_other',
          createdAt: DateTime.utc(2026, 5, 8, 11),
          modelName: 'claude-3',
        ),
      ],
    );
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      serverUrl: Uri.parse('http://localhost:4096'),
      selectedModelFilter: ' gpt-4o ',
    );

    expect(find.textContaining('ses_gpt'), findsWidgets);
    expect(find.textContaining('ses_othe'), findsNothing);
    expect(find.text('> Model filter ...... gpt-4o'), findsOneWidget);
  });

  testWidgets('filters sessions by selected day', (WidgetTester tester) async {
    final cubit = await _buildLoadedCubit(
      sessions: [
        _session(
          id: 'ses_day1',
          createdAt: DateTime.utc(2026, 5, 8, 12),
          modelName: 'gpt-4o',
        ),
        _session(
          id: 'ses_day2',
          createdAt: DateTime.utc(2026, 5, 9, 11),
          modelName: 'gpt-4o',
        ),
      ],
    );
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      serverUrl: Uri.parse('http://localhost:4096'),
      selectedDay: DateTime.utc(2026, 5, 8),
    );

    expect(find.text('> Day filter ........ 2026-05-08'), findsOneWidget);
    expect(find.byKey(const Key('sessions-clear-filter')), findsNothing);

    expect(find.textContaining('ses_day1'), findsWidgets);
    expect(find.textContaining('ses_day2'), findsNothing);
  });

  testWidgets('filters sessions by both model and day', (
    WidgetTester tester,
  ) async {
    final cubit = await _buildLoadedCubit(
      sessions: [
        _session(
          id: 'ses_gpt_day1',
          createdAt: DateTime.utc(2026, 5, 8, 12),
          modelName: 'gpt-4o',
        ),
        _session(
          id: 'ses_gpt_day2',
          createdAt: DateTime.utc(2026, 5, 9, 11),
          modelName: 'gpt-4o',
        ),
        _session(
          id: 'ses_claude_day1',
          createdAt: DateTime.utc(2026, 5, 8, 11),
          modelName: 'claude-3',
        ),
      ],
    );
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      serverUrl: Uri.parse('http://localhost:4096'),
      selectedModelFilter: 'gpt-4o',
      selectedDay: DateTime.utc(2026, 5, 8),
    );

    expect(find.text('> Model filter ...... gpt-4o'), findsOneWidget);
    expect(find.text('> Day filter ........ 2026-05-08'), findsOneWidget);

    expect(find.textContaining('ses_gpt_'), findsWidgets);
    expect(find.textContaining('ses_gpt_day2'), findsNothing);
    expect(find.textContaining('ses_clau'), findsNothing);
  });

  testWidgets('filters sessions by model, day, and hour', (
    WidgetTester tester,
  ) async {
    final cubit = await _buildLoadedCubit(
      sessions: [
        _session(
          id: 'ses_h09g',
          createdAt: DateTime.utc(2026, 5, 8, 9, 5),
          modelName: 'gpt-4o',
        ),
        _session(
          id: 'ses_h14g',
          createdAt: DateTime.utc(2026, 5, 8, 14, 10),
          modelName: 'gpt-4o',
        ),
        _session(
          id: 'ses_h09c',
          createdAt: DateTime.utc(2026, 5, 8, 9, 30),
          modelName: 'claude-3',
        ),
      ],
    );
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      serverUrl: Uri.parse('http://localhost:4096'),
      selectedModelFilter: 'gpt-4o',
      selectedDay: DateTime.utc(2026, 5, 8),
      selectedUtcHour: 9,
    );

    expect(find.text('> Model filter ...... gpt-4o'), findsOneWidget);
    expect(find.text('> Day filter ........ 2026-05-08'), findsOneWidget);
    expect(find.text('> Hour filter ....... 09:00 UTC'), findsOneWidget);

    expect(find.textContaining('ses_h09g'), findsWidgets);
    expect(find.textContaining('ses_h14g'), findsNothing);
    expect(find.textContaining('ses_h09c'), findsNothing);
  });
  testWidgets('filters sessions using local metadata search', (
    WidgetTester tester,
  ) async {
    final cubit = await _buildLoadedCubit(
      sessions: [
        _session(
          id: 'test_id',
          createdAt: DateTime.utc(2026, 5, 8, 12),
          modelName: 'gpt-4o',
          subagentCategory: 'test_category_unique',
        ),
        _session(
          id: 'other_id',
          createdAt: DateTime.utc(2026, 5, 8, 11),
          modelName: 'claude-3',
        ),
      ],
    );
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      wrapInScrollView: true,
    );

    expect(find.textContaining('test_id'), findsWidgets);
    expect(find.textContaining('other_id'), findsWidgets);
    expect(find.text('> Results ........... 2'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('sessions-search-field')),
      'test_category_unique',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('test_id'), findsWidgets);
    expect(find.textContaining('other_id'), findsNothing);
    expect(find.text('> Results ........... 1'), findsOneWidget);

    // Test zero-results search
    await tester.enterText(
      find.byKey(const Key('sessions-search-field')),
      'something_that_will_never_match',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('test_id'), findsNothing);
    expect(find.textContaining('other_id'), findsNothing);
    expect(find.text('> Results ........... 0'), findsOneWidget);
    expect(
      find.text('> No sessions match the active filters.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('sessions-search-clear-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('test_id'), findsWidgets);
    expect(find.textContaining('other_id'), findsWidgets);
    expect(find.text('> Results ........... 2'), findsOneWidget);
  });

  testWidgets(
    'SessionsExplorerPanel constrained-width spotlight/search/filter regression',
    (tester) async {
      final cubit = await _buildLoadedCubit();
      addTearDown(cubit.close);

      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlocProvider<SessionsCubit>.value(
              value: cubit,
              child: SingleChildScrollView(
                child: SessionsExplorerPanel(
                  isConnected: true,
                  onDataChanged: () {},
                  pickImportSource: () async => null,
                  selectedModelFilter: 'model',
                  selectedDay: DateTime.utc(2025, 1, 1),
                  selectedUtcHour: 12,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SessionsExplorerPanel), findsOneWidget);
    },
  );
  testWidgets(
    'SessionsExplorerPanel wide layout stacks explorer above full-width records and enlarges spotlight pie',
    (tester) async {
      final cubit = await _buildLoadedCubit(
        sessions: [_session(id: '1', createdAt: DateTime.now())],
      );
      addTearDown(cubit.close);

      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlocProvider<SessionsCubit>.value(
              value: cubit,
              child: SessionsExplorerPanel(
                isConnected: true,
                onDataChanged: () {},
                pickImportSource: () async => null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final listColumn = find.byKey(const Key('sessions-list-column'));
      final sidebarColumn = find.byKey(const Key('sessions-sidebar-column'));
      final panel = find.byKey(const Key('sessions-panel'));
      final spotlightPie = find.byKey(const Key('sessions-top-model-pie'));

      expect(panel, findsOneWidget);
      expect(listColumn, findsOneWidget);
      expect(sidebarColumn, findsOneWidget);
      expect(spotlightPie, findsOneWidget);

      final panelRect = tester.getRect(panel);
      final sidebarRect = tester.getRect(sidebarColumn);
      final listRect = tester.getRect(listColumn);
      final pieSize = tester.getSize(spotlightPie);

      expect(sidebarRect.top, lessThan(listRect.top));
      expect(listRect.left, closeTo(panelRect.left + 8, 1));
      expect(listRect.width, greaterThan(panelRect.width * 0.9));
      expect(pieSize.height, greaterThan(300));

      expect(
        find.descendant(
          of: listColumn,
          matching: find.byKey(const Key('sessions-list-header')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: listColumn,
          matching: find.byKey(const Key('sessions-search-field')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: listColumn,
          matching: find.byKey(const Key('sessions-search-results-count')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: listColumn,
          matching: find.byKey(const Key('sessions-list')),
        ),
        findsOneWidget,
      );

      expect(
        find.descendant(
          of: sidebarColumn,
          matching: find.byKey(const Key('sessions-spotlight-panel')),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'SessionsExplorerPanel row-hierarchy displays tested substrings',
    (tester) async {
      final cubit = await _buildLoadedCubit(
        sessions: [
          _session(
            id: 'test_session_id',
            createdAt: DateTime.utc(2026, 5, 8, 12),
            modelName: 'gpt-4o',
            inputTokens: 1000,
            outputTokens: 500,
            totalCostUsd: 0.1234,
          ),
        ],
      );
      addTearDown(cubit.close);

      await _pumpPanel(tester, cubit: cubit, isConnected: true);

      expect(find.textContaining('ID: test_ses'), findsWidgets);
      expect(find.textContaining('gpt-4o • 1.5K TOK'), findsWidgets);
      expect(find.textContaining('USD 0.1234'), findsWidgets);
    },
  );

  testWidgets(
    'SessionsExplorerPanel search field maintains filled decoration and semantics',
    (WidgetTester tester) async {
      final cubit = await _buildLoadedCubit();
      addTearDown(cubit.close);

      await _pumpPanel(
        tester,
        cubit: cubit,
        isConnected: true,
        wrapInScrollView: true,
      );

      final textField = tester.widget<TextField>(
        find.byKey(const Key('sessions-search-field')),
      );
      final decoration = textField.decoration!;
      expect(decoration.filled, isTrue);
      expect(
        decoration.fillColor,
        const Color(0xFF0D0E10),
      ); // dashboardBackgroundColor
      expect(decoration.isDense, isTrue);

      final enabledBorder = decoration.enabledBorder as OutlineInputBorder;
      expect(
        enabledBorder.borderSide.color,
        const Color(0xFF2B2D31),
      ); // dashboardBorderColor
      expect(enabledBorder.borderRadius, BorderRadius.circular(4.0));

      final focusedBorder = decoration.focusedBorder as OutlineInputBorder;
      expect(
        focusedBorder.borderSide.color,
        const Color(0xFF3B82F6),
      ); // dashboardAccentColor
      expect(focusedBorder.borderRadius, BorderRadius.circular(4.0));
    },
  );

  testWidgets('SessionsExplorerPanel phase 11 focused regressions', (
    tester,
  ) async {
    final cubit = await _buildLoadedCubit();
    addTearDown(cubit.close);

    // 1. Polished empty list panel preserving disconnected text while sessions-list is absent
    await _pumpPanel(tester, cubit: cubit, isConnected: false);
    expect(
      find.text(
        '> No cached sessions found. Connect to the local server or import data to begin.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('sessions-list')), findsNothing);

    // 2. Spotlight fallback distinction between scoped-empty and globally-empty states
    expect(
      find.text('> Ranked evidence unavailable.'),
      findsOneWidget,
    ); // globally-empty

    // 3. Wide layout still showing cached history and last operation in the sidebar after the polish
    expect(find.text('-- CACHED HISTORY --'), findsOneWidget);
    expect(find.text('-- LAST OPERATION --'), findsOneWidget);
  });

  testWidgets('clears local status message on load transition', (
    WidgetTester tester,
  ) async {
    final cubit = await _buildLoadedCubit();
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit: cubit,
      isConnected: true,
      serverUrl: Uri.parse('http://localhost:4096'),
      pickImportSource: () async => ImportSelection.json(
        '[{"id":"ses_imported","createdAt":"2026-05-08T12:00:00Z","modelName":"o4-mini","inputTokens":10,"outputTokens":5,"totalCostUsd":0.05}]',
        sourceLabel: 'test.json',
      ),
    );

    // Initial empty state
    expect(find.text('> Import completed successfully.'), findsNothing);

    // Simulate an import success
    await tester.tap(find.byKey(const Key('sessions-import-button')));
    await tester.pumpAndSettle();

    // Status message should be visible
    expect(find.text('> Import completed successfully.'), findsOneWidget);

    // Trigger a load which causes isLoading = true
    await cubit.load();

    // The success message should be cleared immediately when loading starts
    await tester.pumpAndSettle();
    expect(find.text('> Import completed successfully.'), findsNothing);
  });
}
