import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:puro2/src/config.dart';
import 'package:puro2/src/env/create.dart';
import 'package:puro2/src/env/version.dart';
import 'package:puro2/src/logger.dart';
import 'package:puro2/src/provider.dart';
import 'package:puro2/src/terminal.dart';
import 'package:puro2/src/version.dart';
import 'package:test/test.dart';

/// Runs git in [repository] and returns its trimmed output.
String _git(Directory repository, List<String> args) {
  final result = Process.runSync('git', [
    '-c',
    'user.name=test',
    '-c',
    'user.email=test@example.com',
    ...args,
  ], workingDirectory: repository.path);
  if (result.exitCode != 0) {
    throw StateError('git $args: ${result.stderr}');
  }
  return (result.stdout as String).trim();
}

/// Commits a Flutter lookalike whose tracked `bin/dart` differs per [version].
String _commitVersion(Directory repository, String version) {
  repository.childFile('README.md').writeAsStringSync(version);
  repository.childDirectory('bin').createSync();
  for (final name in ['dart', 'dart.bat', 'flutter', 'flutter.bat']) {
    repository.childFile('bin/$name').writeAsStringSync(version);
  }
  _git(repository, ['add', '-A']);
  _git(repository, ['commit', '-m', version]);
  return _git(repository, ['rev-parse', 'HEAD']);
}

/// An environment and a shared repository holding two Flutter versions.
class _Fixture {
  _Fixture(this.scope, this.environment, this.v1, this.v2);

  final Scope scope;
  final EnvConfig environment;
  final String v1;
  final String v2;

  File get readme => environment.flutterDir.childFile('README.md');

  Future<void> checkout(String commit, {bool force = false}) async {
    await cloneFlutterWithSharedRefs(
      scope: scope,
      repository: environment.flutterDir,
      environment: environment,
      flutterVersion: FlutterVersion(commit: commit, branch: 'stable'),
      force: force,
    );
  }
}

_Fixture _createFixture() {
  const fileSystem = LocalFileSystem();
  final tempDir = fileSystem.systemTempDirectory.createTempSync('puro2_test');
  addTearDown(() => tempDir.deleteSync(recursive: true));
  final root = tempDir.childDirectory('.puro')..createSync();
  final config = PuroConfig(
    fileSystem: fileSystem,
    gitExecutable: fileSystem.file('git'),
    globalPrefsJsonFile: root.childFile('prefs.json'),
    puroRoot: root,
    legacyPubCacheDir: root.childDirectory('pub_cache'),
    legacyPubCache: false,
    homeDir: tempDir,
    projectDir: null,
    parentProjectDir: null,
    flutterGitUrl: root.childDirectory('shared').childDirectory('flutter').path,
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
  );
  final scope = RootScope();
  scope.add(PuroLogger.provider, PuroLogger());
  scope.add(PuroConfig.provider, config);
  scope.add(Terminal.provider, Terminal(stdout: stdout));

  final shared = config.sharedFlutterDir..createSync(recursive: true);
  _git(shared, ['init', '-b', 'stable']);
  final v1 = _commitVersion(shared, 'v1');
  final v2 = _commitVersion(shared, 'v2');
  return _Fixture(scope, config.getEnv('test'), v1, v2);
}

void main() {
  test('force upgrades over the installed shims', () async {
    final fixture = _createFixture();
    await fixture.checkout(fixture.v1);

    await fixture.checkout(fixture.v2, force: true);

    final head = _git(fixture.environment.flutterDir, ['rev-parse', 'HEAD']);
    expect(head, fixture.v2);
    expect(fixture.readme.readAsStringSync(), 'v2');
  });

  test('force restores a checkout that is missing files', () async {
    final fixture = _createFixture();
    await fixture.checkout(fixture.v1);
    fixture.readme.deleteSync();

    await fixture.checkout(fixture.v1, force: true);

    expect(fixture.readme.readAsStringSync(), 'v1');
  });

  test('force overwrites local changes', () async {
    final fixture = _createFixture();
    await fixture.checkout(fixture.v1);
    fixture.readme.writeAsStringSync('local');

    await fixture.checkout(fixture.v2, force: true);

    expect(fixture.readme.readAsStringSync(), 'v2');
  });

  test('without force a local change aborts the upgrade', () async {
    final fixture = _createFixture();
    await fixture.checkout(fixture.v1);
    fixture.readme.writeAsStringSync('local');

    await expectLater(fixture.checkout(fixture.v2), throwsA(isA<Exception>()));
  });
}
