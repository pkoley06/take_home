import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../platform/native_channels.dart';
import 'failure.dart';

/// Turns whatever a repository/datasource/plugin call threw into a typed
/// [Failure] with a message safe to show directly in the UI. Every bloc
/// catch block should route its caught exception through this instead of
/// stringifying the exception itself, so a raw `DatabaseException` or
/// `PlatformException` never reaches a SnackBar/dialog verbatim.
Failure mapExceptionToFailure(Object error) {
  if (error is Failure) return error;
  if (error is DatabaseException) {
    return DatabaseFailure(_databaseMessage(error));
  }
  if (error is NativeChannelUnavailableException) {
    return const PlatformFailure("Couldn't reach that device feature.");
  }
  if (error is PlatformException) {
    return PlatformFailure(
      error.message ?? 'A device feature is unavailable right now.',
    );
  }
  if (error is FileSystemException) {
    return const PlatformFailure('That file could not be read.');
  }
  if (error is ArgumentError || error is FormatException) {
    return ValidationFailure(error.toString());
  }
  return const UnknownFailure();
}

String _databaseMessage(DatabaseException e) {
  if (e.isUniqueConstraintError()) return 'That already exists.';
  return 'A local storage error occurred. Please try again.';
}
