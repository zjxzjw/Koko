import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:koko/providers/providers.dart';

void main() {
  group('activeProviderProvider', () {
    test('returns null when no providers', () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());

      final result = container.read(activeProviderProvider);
      expect(result, isNull);
    });
  });
}
