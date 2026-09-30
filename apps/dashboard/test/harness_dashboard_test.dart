import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_local/openspent_local.dart';
import 'package:openspent_dashboard/src/app/open_spent_app.dart';
import 'package:openspent_dashboard/src/demo/dashboard_demo.dart';
import 'package:openspent_dashboard/src/screens/sessions/cubit/sessions_cubit.dart';
import 'package:openspent_dashboard/src/screens/settings/widgets/usage_sources_section.dart';
import 'package:openspent_dashboard/src/screens/settings/widgets/api_pricing_section.dart';
import 'package:openspent_dashboard/l10n/app_localizations.dart';

void main() {
  for (final width in [390.0, 900.0, 1400.0]) {
    for (final mode in DashboardDataMode.values) {
      testWidgets(
        'harness controls, usage comparison and sessions in ${mode.name} mode at $width px',
        (tester) async {
          await tester.runAsync(() async {
            final loader = FontLoader('Necto Mono')
              ..addFont(rootBundle.load('assets/fonts/NectoMono-Regular.ttf'));
            await loader.load();
          });
          tester.view.physicalSize = Size(width, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final db = OpenSpentLocalDatabase.inMemory();
          addTearDown(db.close);
          final real = LocalOpenCodeSessionRepository(db);
          final fixture = buildDashboardMockSessions(DateTime.utc(2026, 9, 30));
          await real.writeSessions(fixture);
          final mock = MockOpenCodeSessionRepository(fixture);
          final controller = DemoModeController(mode);
          addTearDown(controller.dispose);
          final repository = DelegatingSessionRepository(
            real,
            mock,
            controller,
          );
          final settings = LocalSettingsRepository(_Store());
          final pricing = LocalPricingRepository(_Store());
          final service = MonetizedMetricsService(
            settingsRepository: settings,
            metricsRepository: LocalMetricsRepository(
              repository,
              pricingRepository: pricing,
            ),
            composer: MonetizedMetricsComposer(
              exchangeRateRepository: MockExchangeRateRepository(),
            ),
          );
          final sources = _Sources();
          await tester.pumpWidget(
            RepaintBoundary(
              key: const Key('harness-preview'),
              child: DemoModeScope(
                controller: controller,
                child: OpenSpentApp(
                  metricsService: service,
                  settingsRepository: settings,
                  localUsageSources: sources,
                  pricingRepository: pricing,
                  sessionsDependencies: SessionsCubitDependencies(
                    localRepository: repository,
                    jsonParser: const OpenCodeSessionJsonParser(),
                    remoteRepositoryFactory: (_) => repository,
                  ),
                  pickImportSource: () async => null,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Usage by harness'), findsOneWidget);
          expect(
            find.text('28 of 28 usage records priced', skipOffstage: false),
            findsNothing,
          ); // Label includes harness.
          expect(
            find.textContaining('28 of 28 usage records priced'),
            findsNWidgets(2),
          );
          expect(sources.connectCount, 0);
          expect(sources.refreshCount, mode == DashboardDataMode.real ? 1 : 0);
          if (mode == DashboardDataMode.mock && width == 1400) {
            await tester.runAsync(() async {
              final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
                find.byKey(const Key('harness-preview')),
              );
              final image = await boundary.toImage(pixelRatio: 1);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '/tmp/openspent-harness-preview.png',
              ).writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.ensureVisible(find.byKey(const Key('harness-codex')));
          await tester.tap(find.byKey(const Key('harness-codex')));
          await tester.pumpAndSettle();
          expect(find.textContaining('Claude Code: 28'), findsNothing);
          expect(find.textContaining('Codex: 100% · 28'), findsOneWidget);
          final navSemantics = tester.getSemantics(
            find.byKey(const Key('dashboard-nav-sessions')),
          );
          expect(navSemantics.label, contains('Sessions'));
          expect(
            navSemantics.getSemanticsData().hasAction(ui.SemanticsAction.tap),
            isTrue,
          );
          expect(find.byType(NestedScrollView), findsNothing);
          expect(
            find
                .descendant(
                  of: find.byKey(const Key('dashboard-shell-route-area')),
                  matching: find.byType(Scrollable),
                )
                .evaluate()
                .where((e) => (e.widget as Scrollable).axis == Axis.vertical),
            hasLength(1),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'source connect is explicit; refresh and disconnect controls work',
    (tester) async {
      final sources = _Sources();
      await tester.pumpWidget(
        _localized(UsageSourcesSection(sources: sources, onChanged: () {})),
      );
      await tester.pumpAndSettle();
      expect(sources.connectCount, 0);
      await tester.tap(find.byKey(const Key('connect-codex')));
      await tester.pumpAndSettle();
      expect(sources.connectCount, 1);
      await tester.tap(find.byKey(const Key('refresh-codex')));
      await tester.pumpAndSettle();
      expect(sources.refreshCount, 1);
      await tester.tap(find.text('Disconnect'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('connect-codex')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('pricing editor validates, saves and resets rates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _Store();
    final pricing = LocalPricingRepository(store);
    await tester.pumpWidget(
      _localized(
        ApiPricingSection(
          repository: pricing,
          sessions: MockOpenCodeSessionRepository(),
          onChanged: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('api-rate-0')), '-1');
    await tester.tap(find.text('Save rates'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter finite'), findsOneWidget);
    expect((await pricing.readPricing()).overrides, isEmpty);
    await tester.enterText(find.byKey(const Key('api-rate-0')), '2');
    await tester.tap(find.text('Save rates'));
    await tester.pumpAndSettle();
    expect((await pricing.readPricing()).overrides, hasLength(1));
    await tester.tap(find.text('Reset to published rates'));
    await tester.pumpAndSettle();
    expect((await pricing.readPricing()).overrides, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

Widget _localized(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('en'),
  home: Scaffold(
    body: SingleChildScrollView(child: SizedBox(width: 480, child: child)),
  ),
);

class _Store implements KeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> readString(String key) async => values[key];
  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}

class _Sources implements LocalUsageSources {
  bool connected = false;
  int connectCount = 0, refreshCount = 0;
  @override
  Future<List<LocalUsageSourceStatus>> statuses() async => [
    LocalUsageSourceStatus(harness: UsageHarness.codex, connected: connected),
  ];
  @override
  Future<bool> connect(UsageHarness harness, {String? directory}) async {
    connectCount++;
    connected = true;
    return true;
  }

  @override
  Future<void> disconnect(UsageHarness harness) async {
    connected = false;
  }

  @override
  Future<void> refresh({UsageHarness? harness}) async {
    refreshCount++;
  }
}
