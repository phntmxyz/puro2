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

void main() {
  test('checks out paths over the Windows limit', () async {
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
      flutterGitUrl: root
          .childDirectory('shared')
          .childDirectory('flutter')
          .path,
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

    // Written to the index only, the shared repository is never checked out.
    final shared = config.sharedFlutterDir..createSync(recursive: true);
    _git(shared, ['init', '-b', 'stable']);
    final blob = shared.childFile('blob')..writeAsStringSync('content');
    final hash = _git(shared, ['hash-object', '-w', blob.path]);
    blob.deleteSync();
    final longPath = List.filled(8, 'd' * 40).join('/');
    for (final path in ['bin/flutter', longPath]) {
      _git(shared, [
        'update-index',
        '--add',
        '--cacheinfo',
        '100644,$hash,$path',
      ]);
    }
    _git(shared, ['commit', '-m', 'long path']);
    final commit = _git(shared, ['rev-parse', 'HEAD']);

    final environment = config.getEnv('test');
    await cloneFlutterWithSharedRefs(
      scope: scope,
      repository: environment.flutterDir,
      environment: environment,
      flutterVersion: FlutterVersion(commit: commit, branch: 'stable'),
    );

    final repository = environment.flutterDir;
    expect(_git(repository, ['rev-parse', 'HEAD']), commit);
    expect(_git(repository, ['ls-files', '--deleted']), isEmpty);
  });
}
