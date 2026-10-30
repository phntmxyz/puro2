import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:puro2/src/config.dart';
import 'package:puro2/src/env/engine.dart';
import 'package:puro2/src/logger.dart';
import 'package:puro2/src/provider.dart';
import 'package:puro2/src/version.dart';
import 'package:test/test.dart';

/// A zip holding `hello.txt` with the content `hello`.
final _zipBytes = base64Decode(
  'UEsDBBQAAAAAAB1zXl2GphA2BQAAAAUAAAAJAAAAaGVsbG8udHh0aGVsbG9QSwECFAMUAAAAAAAd'
  'c15dhqYQNgUAAAAFAAAACQAAAAAAAAAAAAAAgAEAAAAAaGVsbG8udHh0UEsFBgAAAAABAAEANwAA'
  'ACwAAAAAAA==',
);

/// Builds a scope in which `unzip` can look up programs in the PATH.
Scope _createScope(Directory root) {
  final puroRoot = root.childDirectory('.puro')..createSync();
  final scope = RootScope();
  scope.add(PuroLogger.provider, PuroLogger());
  scope.add(
    PuroConfig.provider,
    PuroConfig(
      fileSystem: root.fileSystem,
      gitExecutable: root.childFile('git'),
      globalPrefsJsonFile: puroRoot.childFile('prefs.json'),
      puroRoot: puroRoot,
      legacyPubCacheDir: puroRoot.childDirectory('pub_cache'),
      legacyPubCache: false,
      homeDir: root,
      projectDir: null,
      parentProjectDir: null,
      flutterGitUrl: '',
      engineGitUrl: '',
      dartSdkGitUrl: '',
      releasesJsonUrl: Uri.parse('https://example.com/releases.json'),
      flutterStorageBaseUrl: Uri.parse('https://example.com'),
      environmentOverride: null,
      puroBuildsUrl: Uri.parse('https://example.com/builds'),
      buildTarget: PuroBuildTarget.linuxX64,
      enableShims: false,
      shouldInstall: false,
      shouldSkipCacheSync: true,
    ),
  );
  return scope;
}

void main() {
  test('unzip handles spaces and quotes in the paths', () async {
    const fileSystem = LocalFileSystem();
    final root = fileSystem.systemTempDirectory.createTempSync('puro2 test');
    addTearDown(() => root.deleteSync(recursive: true));
    final zipFile = root.childFile("engine's archive.zip")
      ..writeAsBytesSync(_zipBytes);
    final destination = root.childDirectory('John Doe').childDirectory('cache');

    await unzip(
      scope: _createScope(root),
      zipFile: zipFile,
      destination: destination,
    );

    expect(destination.childFile('hello.txt').readAsStringSync(), 'hello');
  });

  test(
    'expandArchiveCommand unzips with PowerShell',
    () {
      // unzip prefers 7z when it is installed, like on the CI runners.
      const fileSystem = LocalFileSystem();
      final root = fileSystem.systemTempDirectory.createTempSync('puro2 test');
      addTearDown(() => root.deleteSync(recursive: true));
      final zipFile = root.childFile("engine's archive.zip")
        ..writeAsBytesSync(_zipBytes);
      final destination = root.childDirectory('John [Doe]')..createSync();

      final result = Process.runSync('powershell', [
        '-command',
        expandArchiveCommand(
          zipPath: zipFile.path,
          destinationPath: destination.path,
        ),
      ]);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(destination.childFile('hello.txt').readAsStringSync(), 'hello');
    },
    skip: Platform.isWindows ? false : 'PowerShell only runs on Windows',
  );

  test('expandArchiveCommand quotes both paths', () {
    expect(
      expandArchiveCommand(
        zipPath: r'C:\Users\John Doe\.puro\engine.zip',
        destinationPath: 'C:\\Users\\John O\'Doe\u2019s \$dir\\cache',
      ),
      'Add-Type -AssemblyName System.IO.Compression.FileSystem; '
      '[System.IO.Compression.ZipFile]::ExtractToDirectory('
      r"'C:\Users\John Doe\.puro\engine.zip', "
      '\'C:\\Users\\John O\'\'Doe\u2019\u2019s \$dir\\cache\')',
    );
  });
}
