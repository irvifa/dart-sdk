// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonDecode;

import 'package:analysis_server/src/edit/nnbd_migration/migration_info.dart';
import 'package:analysis_server/src/edit/nnbd_migration/path_mapper.dart';
import 'package:analysis_server/src/edit/nnbd_migration/region_renderer.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'nnbd_migration_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RegionRendererTest);
  });
}

@reflectiveTest
class RegionRendererTest extends NnbdMigrationTestBase {
  /// Render [libraryInfo], using a [MigrationInfo] which knows only about this
  /// library.
  String renderRegion(int offset) {
    String packageRoot = convertPath('/package');
    MigrationInfo migrationInfo =
        MigrationInfo(infos, {}, resourceProvider.pathContext, packageRoot);
    var unitInfo = infos.single;
    var region = unitInfo.regionAt(offset);
    return RegionRenderer(
            region, unitInfo, migrationInfo, PathMapper(resourceProvider))
        .render();
  }

  test_modifiedOutput_containsDetail() async {
    await buildInfoForSingleTestFile('int a = null;',
        migratedContent: 'int? a = null;');
    var response = jsonDecode(renderRegion(3));
    expect(response['details'], hasLength(1));
    var detail = response['details'].single;
    expect(detail['description'],
        equals("This variable is initialized to an explicit 'null'"));
    expect(detail['link']['text'], equals('test.dart'));
    expect(detail['link']['href'], equals('test.dart?offset=8&line=1'));
  }

  test_modifiedOutput_containsExplanation() async {
    await buildInfoForSingleTestFile('int a = null;',
        migratedContent: 'int? a = null;');
    var response = jsonDecode(renderRegion(3));
    expect(
        response['explanation'], equals("Changed type 'int' to be nullable"));
  }

  test_modifiedOutput_containsPath() async {
    await buildInfoForSingleTestFile('int a = null;',
        migratedContent: 'int? a = null;');
    var response = jsonDecode(renderRegion(3));
    expect(response['path'], equals(convertPath('/project/bin/test.dart')));
    expect(response['line'], equals(1));
  }

  test_unmodifiedOutput_containsDetail() async {
    await buildInfoForSingleTestFile('f(int a) => a.isEven;',
        migratedContent: 'f(int a) => a.isEven;');
    var response = jsonDecode(renderRegion(2));
    expect(response['details'], hasLength(1));
    var detail = response['details'].single;
    expect(
        detail['description'],
        equals('This value is unconditionally used in a '
            'non-nullable context'));
    expect(detail['link']['text'], equals('test.dart'));
    expect(detail['link']['href'], equals('test.dart?offset=12&line=1'));
  }

  test_unmodifiedOutput_containsExplanation() async {
    await buildInfoForSingleTestFile('f(int a) => a.isEven;',
        migratedContent: 'f(int a) => a.isEven;');
    var response = jsonDecode(renderRegion(2));
    expect(
        response['explanation'],
        equals(
            'This type is not changed; it is determined to be non-nullable'));
  }

  test_unmodifiedOutput_containsPath() async {
    await buildInfoForSingleTestFile('f(int a) => a.isEven;',
        migratedContent: 'f(int a) => a.isEven;');
    var response = jsonDecode(renderRegion(2));
    expect(response['path'], equals(convertPath('/project/bin/test.dart')));
    expect(response['line'], equals(1));
  }
}
