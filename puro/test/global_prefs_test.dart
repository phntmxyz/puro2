import 'dart:convert';
import 'dart:io';

import 'package:file/local.dart';
import 'package:puro2/src/config.dart';
import 'package:puro2/src/logger.dart';
import 'package:puro2/src/provider.dart';
import 'package:puro2/src/terminal.dart';
import 'package:test/test.dart';

void main() {
  test('updating the prefs removes the field older Puro fails on', () async {
    const fileSystem = LocalFileSystem();
    final tempDir = fileSystem.systemTempDirectory.createTempSync('puro2_test');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final prefsFile = tempDir.childFile('prefs.json')
      ..writeAsStringSync(jsonEncode({'legacyPubCache': true}));
    final scope = RootScope();
    scope.add(PuroLogger.provider, PuroLogger());
    scope.add(globalPrefsJsonFileProvider, prefsFile);
    scope.add(Terminal.provider, Terminal(stdout: stdout));

    await updateGlobalPrefs(
      scope: scope,
      fn: (prefs) {
        prefs.defaultEnvironment = 'stable';
      },
    );

    expect(jsonDecode(prefsFile.readAsStringSync()), {
      'defaultEnvironment': 'stable',
    });
  });
}
