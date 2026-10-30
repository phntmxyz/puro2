import 'dart:io';

import 'package:file/local.dart';
import 'package:puro2/src/install/bin.dart';
import 'package:test/test.dart';

void main() {
  for (final exitCode in [0, 3]) {
    test(
      'the trampoline exits with $exitCode when the executable does',
      () {
        const fileSystem = LocalFileSystem();
        final tempDir = fileSystem.systemTempDirectory.createTempSync(
          'puro2_test',
        );
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final script = tempDir.childFile('puro2.bat')
          ..writeAsStringSync(
            windowsTrampolineScript(
              header: '@echo off',
              command: 'cmd /c exit $exitCode',
            ),
          );

        final result = Process.runSync('cmd', ['/c', script.path]);

        expect(result.exitCode, exitCode);
      },
      skip: Platform.isWindows ? false : 'cmd only runs on Windows',
    );
  }
}
