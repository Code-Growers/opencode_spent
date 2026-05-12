import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openspent_core/openspent_core.dart';
import 'package:openspent_local/openspent_local.dart';

final class SessionsCubitDependencies {
  const SessionsCubitDependencies({
    required this.localRepository,
    required this.jsonParser,
    required this.remoteRepositoryFactory,
    this.importedSqlitePathRepositoryFactory,
    this.importedSqliteBytesRepositoryFactory,
  });

  final OpenCodeSessionRepository localRepository;
  final OpenCodeSessionJsonParser jsonParser;
  final OpenCodeSessionRepository Function(OpenCodeSettings settings)
  remoteRepositoryFactory;
  final OpenCodeSessionRepository Function(String path)?
  importedSqlitePathRepositoryFactory;
  final OpenCodeSessionRepository Function(Uint8List bytes)?
  importedSqliteBytesRepositoryFactory;
}

final class SessionsState {
  const SessionsState({
    this.isLoading = false,
    this.message,
    this.isError = false,
    this.isWalModeImportError = false,
    this.sessions = const [],
    this.lastOperationType,
    this.lastOperationSuccess,
    this.lastOperationSourceLabel,
    this.lastOperationCachedCount,
  });

  static const Object _messageUnchanged = Object();
  static const Object _sourceLabelUnchanged = Object();

  final bool isLoading;
  final String? message;
  final bool isError;
  final bool isWalModeImportError;
  final List<OpenCodeSession> sessions;
  final String? lastOperationType;
  final bool? lastOperationSuccess;
  final String? lastOperationSourceLabel;
  final int? lastOperationCachedCount;

  SessionsState copyWith({
    bool? isLoading,
    Object? message = _messageUnchanged,
    bool? isError,
    bool? isWalModeImportError,
    List<OpenCodeSession>? sessions,
    String? lastOperationType,
    bool? lastOperationSuccess,
    Object? lastOperationSourceLabel = _sourceLabelUnchanged,
    int? lastOperationCachedCount,
  }) {
    return SessionsState(
      isLoading: isLoading ?? this.isLoading,
      message: identical(message, _messageUnchanged)
          ? this.message
          : message as String?,
      isError: isError ?? this.isError,
      isWalModeImportError: isWalModeImportError ?? this.isWalModeImportError,
      sessions: sessions ?? this.sessions,
      lastOperationType: lastOperationType ?? this.lastOperationType,
      lastOperationSuccess: lastOperationSuccess ?? this.lastOperationSuccess,
      lastOperationSourceLabel:
          identical(lastOperationSourceLabel, _sourceLabelUnchanged)
          ? this.lastOperationSourceLabel
          : lastOperationSourceLabel as String?,
      lastOperationCachedCount:
          lastOperationCachedCount ?? this.lastOperationCachedCount,
    );
  }
}

final class SessionsCubit extends Cubit<SessionsState> {
  SessionsCubit({required SessionsCubitDependencies dependencies})
    : _dependencies = dependencies,
      super(const SessionsState());

  final SessionsCubitDependencies _dependencies;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, isWalModeImportError: false));

    try {
      final sessions = await _readSortedSessions();
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoading: false,
          sessions: sessions,
          isError: false,
          isWalModeImportError: false,
          message: null,
          lastOperationType: 'load',
          lastOperationSuccess: true,
          lastOperationSourceLabel: null,
          lastOperationCachedCount: sessions.length,
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoading: false,
          isError: true,
          isWalModeImportError: false,
          message: error.toString(),
          lastOperationType: 'load',
          lastOperationSuccess: false,
          lastOperationSourceLabel: null,
          lastOperationCachedCount: state.sessions.length,
        ),
      );
    }
  }

  Future<bool> syncNow(OpenCodeSettings settings) async {
    emit(
      state.copyWith(
        isLoading: true,
        message: null,
        isError: false,
        isWalModeImportError: false,
      ),
    );

    try {
      final remoteRepository = _dependencies.remoteRepositoryFactory(settings);
      final syncService = OpenCodeSessionSyncService(
        remoteRepository: remoteRepository,
        localRepository: _dependencies.localRepository,
      );
      await syncService.syncSessions();

      final sessions = await _readSortedSessions();
      if (isClosed) {
        return false;
      }

      emit(
        state.copyWith(
          isLoading: false,
          sessions: sessions,
          isError: false,
          isWalModeImportError: false,
          message: null,
          lastOperationType: 'sync',
          lastOperationSuccess: true,
          lastOperationSourceLabel: null,
          lastOperationCachedCount: sessions.length,
        ),
      );
      return true;
    } catch (error) {
      if (isClosed) {
        return false;
      }

      emit(
        state.copyWith(
          isLoading: false,
          isError: true,
          isWalModeImportError: false,
          message: error.toString(),
          lastOperationType: 'sync',
          lastOperationSuccess: false,
          lastOperationSourceLabel: null,
          lastOperationCachedCount: state.sessions.length,
        ),
      );
      return false;
    }
  }

  Future<bool> importJson(String jsonString, {String? sourceLabel}) async {
    emit(
      state.copyWith(
        isLoading: true,
        message: null,
        isError: false,
        isWalModeImportError: false,
      ),
    );

    try {
      final importedSessions = _dependencies.jsonParser.parse(jsonString);
      await _dependencies.localRepository.writeSessions(importedSessions);

      final sessions = await _readSortedSessions();
      if (isClosed) {
        return false;
      }

      emit(
        state.copyWith(
          isLoading: false,
          sessions: sessions,
          isError: false,
          isWalModeImportError: false,
          message: null,
          lastOperationType: 'import-json',
          lastOperationSuccess: true,
          lastOperationSourceLabel: sourceLabel,
          lastOperationCachedCount: sessions.length,
        ),
      );
      return true;
    } catch (error) {
      if (isClosed) {
        return false;
      }

      emit(
        state.copyWith(
          isLoading: false,
          isError: true,
          isWalModeImportError: false,
          message: error.toString(),
          lastOperationType: 'import-json',
          lastOperationSuccess: false,
          lastOperationSourceLabel: sourceLabel,
          lastOperationCachedCount: state.sessions.length,
        ),
      );
      return false;
    }
  }

  Future<bool> importSqlitePath(String path, {String? sourceLabel}) async {
    emit(
      state.copyWith(
        isLoading: true,
        message: null,
        isError: false,
        isWalModeImportError: false,
      ),
    );

    try {
      final importedRepository = _dependencies
          .importedSqlitePathRepositoryFactory
          ?.call(path);
      if (importedRepository == null) {
        throw UnsupportedError('SQLite path import is not available.');
      }
      final syncService = OpenCodeSessionSyncService(
        remoteRepository: importedRepository,
        localRepository: _dependencies.localRepository,
      );
      await syncService.syncSessions();

      final sessions = await _readSortedSessions();
      if (isClosed) {
        return false;
      }

      emit(
        state.copyWith(
          isLoading: false,
          sessions: sessions,
          isError: false,
          isWalModeImportError: false,
          message: null,
          lastOperationType: 'import-sqlite',
          lastOperationSuccess: true,
          lastOperationSourceLabel: sourceLabel,
          lastOperationCachedCount: sessions.length,
        ),
      );
      return true;
    } catch (error) {
      if (isClosed) {
        return false;
      }

      emit(
        state.copyWith(
          isLoading: false,
          isError: true,
          isWalModeImportError: false,
          message: error.toString(),
          lastOperationType: 'import-sqlite',
          lastOperationSuccess: false,
          lastOperationSourceLabel: sourceLabel,
          lastOperationCachedCount: state.sessions.length,
        ),
      );
      return false;
    }
  }

  Future<bool> importSqliteBytes(Uint8List bytes, {String? sourceLabel}) async {
    emit(
      state.copyWith(
        isLoading: true,
        message: null,
        isError: false,
        isWalModeImportError: false,
      ),
    );

    try {
      final importedRepository = _dependencies
          .importedSqliteBytesRepositoryFactory
          ?.call(bytes);
      if (importedRepository == null) {
        throw UnsupportedError('SQLite byte import is not available.');
      }
      final syncService = OpenCodeSessionSyncService(
        remoteRepository: importedRepository,
        localRepository: _dependencies.localRepository,
      );
      await syncService.syncSessions();

      final sessions = await _readSortedSessions();
      if (isClosed) {
        return false;
      }

      emit(
        state.copyWith(
          isLoading: false,
          sessions: sessions,
          isError: false,
          isWalModeImportError: false,
          message: null,
          lastOperationType: 'import-sqlite',
          lastOperationSuccess: true,
          lastOperationSourceLabel: sourceLabel,
          lastOperationCachedCount: sessions.length,
        ),
      );
      return true;
    } catch (error) {
      if (isClosed) {
        return false;
      }

      emit(
        state.copyWith(
          isLoading: false,
          isError: true,
          isWalModeImportError:
              OpenCodeUploadedSqliteSessionRepository.isWalModeUploadError(
                error,
              ),
          message: error.toString(),
          lastOperationType: 'import-sqlite',
          lastOperationSuccess: false,
          lastOperationSourceLabel: sourceLabel,
          lastOperationCachedCount: state.sessions.length,
        ),
      );
      return false;
    }
  }

  Future<List<OpenCodeSession>> _readSortedSessions() async {
    final sessions = await _dependencies.localRepository.readSessions();
    final mutableSessions = sessions.toList();
    mutableSessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mutableSessions;
  }
}
