// lib/core/errors/failures.dart
/// Failure types used to represent app-level errors in the domain layer.

import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred.']);
}

class LocalStorageFailure extends Failure {
  const LocalStorageFailure([super.message = 'Local storage error.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied.']);
}
