// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:neat_cache/cache_provider.dart';
import 'utils.dart';

void testCacheProvider({
  String name,
  Future<CacheProvider<String>> Function() create,
  Future Function() destroy,
}) =>
    group(name, () {
      CacheProvider<String> cache;
      setUpAll(() async => cache = await create());
      tearDownAll(() => destroy != null ? destroy() : null);

      test('get empty key', () async {
        await cache.purge('test-key');
        final r = await cache.get('test-key');
        expect(r, isNull);
      });

      test('get/set key', () async {
        await cache.set('test-key-2', 'hello-world-42');
        final r = await cache.get('test-key-2');
        expect(r, equals('hello-world-42'));
      });

      test('set key (overwrite)', () async {
        await cache.set('test-key-3', 'hello-once');
        final r = await cache.get('test-key-3');
        expect(r, equals('hello-once'));

        await cache.set('test-key-3', 'hello-again');
        final r2 = await cache.get('test-key-3');
        expect(r2, equals('hello-again'));
      });

      test('purge key', () async {
        await cache.set('test-key-4', 'hello-once');
        final r = await cache.get('test-key-4');
        expect(r, equals('hello-once'));

        await cache.purge('test-key-4');
        final r2 = await cache.get('test-key-4');
        expect(r2, isNull);
      });

      test('set key w. ttl', () async {
        await cache.set('test-key-5', 'should-expire', Duration(seconds: 2));
        final r = await cache.get('test-key-5');
        expect(r, equals('should-expire'));

        await Future.delayed(Duration(seconds: 3));

        final r2 = await cache.get('test-key-5');
        expect(r2, isNull);
      }, tags: ['ttl']);
    });

void main() {
  setupLogging();

  testCacheProvider(
    name: 'in-memory cache',
    create: () async => StringCacheProvider(
      cache: Cache.inMemoryCacheProvider(4096),
      codec: utf8,
    ),
  );

  CacheProvider<List<int>> p;
  testCacheProvider(
    name: 'redis cache',
    create: () async {
      p = Cache.redisCacheProvider('redis://localhost:6379');
      return StringCacheProvider(cache: p, codec: utf8);
    },
    destroy: () => p.close(),
  );
}
