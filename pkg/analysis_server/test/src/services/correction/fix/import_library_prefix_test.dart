// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLibraryPrefixTest);
    defineReflectiveTests(ImportLibraryPrefixWithExtensionMethodsTest);
  });
}

@reflectiveTest
class ImportLibraryPrefixTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PREFIX;

  test_withClass() async {
    await resolveTestUnit('''
import 'dart:collection' as pref;
main() {
  pref.HashMap s = null;
  LinkedHashMap f = null;
  print('\$s \$f');
}
''');
    await assertHasFix('''
import 'dart:collection' as pref;
main() {
  pref.HashMap s = null;
  pref.LinkedHashMap f = null;
  print('\$s \$f');
}
''');
  }

  test_withTopLevelVariable() async {
    await resolveTestUnit('''
import 'dart:math' as pref;
main() {
  print(pref.E);
  print(PI);
}
''');
    await assertHasFix('''
import 'dart:math' as pref;
main() {
  print(pref.E);
  print(pref.PI);
}
''');
  }
}

@reflectiveTest
class ImportLibraryPrefixWithExtensionMethodsTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PREFIX;

  @override
  void setUp() {
    createAnalysisOptionsFile(experiments: ['extension-methods']);
    super.setUp();
  }

  test_withExtension() async {
    addSource('/home/test/lib/lib.dart', '''
class C {}
extension E on int {
  static String m() => '';
}
''');
    await resolveTestUnit('''
import 'lib.dart' as p;
void f(p.C c) {
  print(E.m());
}
''');
    await assertHasFix('''
import 'lib.dart' as p;
void f(p.C c) {
  print(p.E.m());
}
''');
  }
}
