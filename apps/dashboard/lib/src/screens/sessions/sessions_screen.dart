import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openspent_core/openspent_core.dart';

import '../../sessions/import_selection.dart';
import '../../sessions/sessions_explorer_panel.dart';
import 'cubit/sessions_cubit.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({
    super.key,
    required this.dependencies,
    required this.dataRevision,
    required this.serverSettings,
    required this.isConnected,
    required this.onDataChanged,
    required this.pickImportSource,
    this.selectedHarness,
    this.pricingRepository,
    this.selectedModelFilter,
    this.selectedDay,
    this.selectedUtcHour,
    this.onClearModelFilter,
    this.windowFrom,
    this.windowTo,
  });

  final SessionsCubitDependencies dependencies;
  final int dataRevision;
  final OpenCodeSettings serverSettings;
  final bool isConnected;
  final VoidCallback onDataChanged;
  final Future<ImportSelection?> Function() pickImportSource;
  final UsageHarness? selectedHarness;
  final PricingRepository? pricingRepository;
  final String? selectedModelFilter;
  final DateTime? selectedDay;
  final int? selectedUtcHour;
  final VoidCallback? onClearModelFilter;
  final DateTime? windowFrom;
  final DateTime? windowTo;

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  late SessionsCubit _sessionsCubit;

  @override
  void initState() {
    super.initState();
    _sessionsCubit = SessionsCubit(dependencies: widget.dependencies);
    _sessionsCubit.load();
  }

  @override
  void didUpdateWidget(covariant SessionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dependencies != widget.dependencies) {
      _sessionsCubit.close();
      _sessionsCubit = SessionsCubit(dependencies: widget.dependencies);
      _sessionsCubit.load();
      return;
    }

    if (oldWidget.dataRevision != widget.dataRevision) {
      _sessionsCubit.load();
    }
  }

  @override
  void dispose() {
    _sessionsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SessionsCubit>.value(
      value: _sessionsCubit,
      child: SessionsExplorerPanel(
        serverSettings: widget.serverSettings,
        isConnected: widget.isConnected,
        onDataChanged: widget.onDataChanged,
        pickImportSource: widget.pickImportSource,
        dataRevision: widget.dataRevision,
        selectedHarness: widget.selectedHarness,
        pricingRepository: widget.pricingRepository,
        selectedModelFilter: widget.selectedModelFilter,
        selectedDay: widget.selectedDay,
        selectedUtcHour: widget.selectedUtcHour,
        onClearModelFilter: widget.onClearModelFilter,
        windowFrom: widget.windowFrom,
        windowTo: widget.windowTo,
      ),
    );
  }
}
