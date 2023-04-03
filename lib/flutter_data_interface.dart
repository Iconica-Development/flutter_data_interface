// SPDX-FileCopyrightText: 2022 Iconica
//
// SPDX-License-Identifier: BSD-3-Clause

library plugin_platform_interface;

import 'package:meta/meta.dart';

/// Base class for data interfaces.
///
/// Provides a static helper method for ensuring that data interfaces are
/// implemented using `extends` instead of `implements`.
///
/// Data interface classes are expected to have a private static token object which will be
/// be passed to [verify] along with a data interface object for verification.
///
/// Sample usage:
///
///
/// Mockito mocks of data interfaces will fail the verification, in test code only it is possible
/// to include the [MockDataInterfaceMixin] for the verification to be temporarily disabled. See
/// [MockDataInterfaceMixin] for a sample of using Mockito to mock a data interface.
abstract class DataInterface {
  /// Constructs a DataInterface, for use only in constructors of abstract
  /// derived classes.
  ///
  /// @param token The same, non-`const` `Object` that will be passed to `verify`.
  DataInterface({required Object token}) {
    _instanceTokens[this] = token;
  }

  /// Expando mapping instances of DataInterface to their associated tokens.
  /// The reason this is not simply a private field of type `Object?` is because
  /// as of the implementation of field promotion in Dart
  /// (https://github.com/dart-lang/language/issues/2020), it is a runtime error
  /// to invoke a private member that is mocked in another library.  The expando
  /// approach prevents [_verify] from triggering this runtime exception when
  /// encountering an implementation that uses `implements` rather than
  /// `extends`.  This in turn allows [_verify] to throw an [AssertionError] (as
  /// documented).
  static final Expando<Object> _instanceTokens = Expando<Object>();

  /// Ensures that the data instance was constructed with a non-`const` token
  /// that matches the provided token and throws [AssertionError] if not.
  ///
  /// This is used to ensure that implementers are using `extends` rather than
  /// `implements`.
  ///
  /// Subclasses of [MockDataInterfaceMixin] are assumed to be valid in debug
  /// builds.
  ///
  /// This is implemented as a static method so that it cannot be overridden
  /// with `noSuchMethod`.
  static void verify(DataInterface instance, Object token) {
    _verify(instance, token, preventConstObject: true);
  }

  /// Performs the same checks as `verify` but without throwing an
  /// [AssertionError] if `const Object()` is used as the instance token.
  ///
  /// This method will be deprecated in a future release.
  static void verifyToken(DataInterface instance, Object token) {
    _verify(instance, token, preventConstObject: false);
  }

  static void _verify(
    DataInterface instance,
    Object token, {
    required bool preventConstObject,
  }) {
    if (instance is MockDataInterfaceMixin) {
      bool assertionsEnabled = false;
      assert(() {
        assertionsEnabled = true;
        return true;
      }());
      if (!assertionsEnabled) {
        throw AssertionError(
            '`MockDataInterfaceMixin` is not intended for use in release builds.');
      }
      return;
    }
    if (preventConstObject &&
        identical(_instanceTokens[instance], const Object())) {
      throw AssertionError('`const Object()` cannot be used as the token.');
    }
    if (!identical(token, _instanceTokens[instance])) {
      throw AssertionError(
          'Data interfaces must not be implemented with `implements`');
    }
  }
}

/// A [DataInterface] mixin that can be combined with fake or mock objects,
/// such as test's `Fake` or mocktail's `Mock`.
///
/// It passes the [DataInterface.verify] check even though it isn't
/// using `extends`.
///
/// This class is intended for use in tests only.
///
@visibleForTesting
abstract class MockDataInterfaceMixin implements DataInterface {}
