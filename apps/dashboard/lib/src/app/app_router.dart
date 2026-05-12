import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:openspent_core/openspent_core.dart';

import '../screens/exchange_rates/cubit/exchange_rates_cubit.dart';
import '../screens/sessions/cubit/sessions_cubit.dart';
import '../sessions/import_selection.dart';
import '../screens/dashboard/dashboard_shell_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => <AutoRoute>[
    AutoRoute(
      path: '/',
      page: DashboardShellRoute.page,
      initial: true,
      children: <AutoRoute>[
        CustomRoute(
          path: '',
          page: DashboardMetricsRoute.page,
          transitionsBuilder: TransitionsBuilders.noTransition,
        ),
        CustomRoute(
          path: 'sessions',
          page: DashboardSessionsRoute.page,
          transitionsBuilder: TransitionsBuilders.noTransition,
        ),
        CustomRoute(
          path: 'exchange-rates',
          page: DashboardExchangeRatesRoute.page,
          transitionsBuilder: TransitionsBuilders.noTransition,
        ),
        CustomRoute(
          path: 'state',
          page: DashboardStateRoute.page,
          transitionsBuilder: TransitionsBuilders.noTransition,
        ),
      ],
    ),
  ];
}
