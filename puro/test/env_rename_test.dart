import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:puro2/src/config.dart';
import 'package:puro2/src/env/default.dart';
import 'package:puro2/src/env/rename.dart';
import 'package:puro2/src/logger.dart';
import 'package:puro2/src/provider.dart';
import 'package:puro2/src/terminal.dart';
import 'package:puro2/src/version.dart';
import 'package:test/test.dart';

/// A scope whose current project is [currentProject], with the environment
/// `old` installed.
Scope _createScope(Directory tempDir, Directory currentProject) {
  final root = tempDir.childDirectory('.puro')..createSync();
  final config = PuroConfig(
    fileSystem: tempDir.fileSystem,
    gitExecutable: tempDir.fileSystem.file('git'),
    globalPrefsJsonFile: root.childFile('prefs.json'),
    puroRoot: root,
    legacyPubCacheDir: root.childDirectory('pub_cache'),
    legacyPubCache: false,
    homeDir: tempDir,
    projectDir: currentProject,
    parentProjectDir: currentProject,
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
  );
  config.getEnv('old').flutterDir.createSync(recursive: true);
  final scope = RootScope();
  scope.add(PuroLogger.provider, PuroLogger());
  scope.add(PuroConfig.provider, config);
  scope.add(globalPrefsJsonFileProvider, config.globalPrefsJsonFile);
  scope.add(Terminal.provider, Terminal(stdout: stdout));
  return scope;
}

Directory _createTempDir() {
  const fileSystem = LocalFileSystem();
  final tempDir = fileSystem.systemTempDirectory.createTempSync('puro2_test');
  addTearDown(() => tempDir.deleteSync(recursive: true));
  return tempDir;
}

/// Creates a project using the environment [envName] and registers it.
Future<Directory> _createProject(
  Scope scope,
  Directory tempDir,
  String name,
  String envName,
) async {
  final project = tempDir.childDirectory(name)..createSync();
  final dotfile = project.childFile(ProjectConfig.dotfileName)
    ..writeAsStringSync(jsonEncode({'env': envName}));
  await registerDotfile(scope: scope, dotfile: dotfile);
  return project;
}

String _readEnv(Directory project) {
  final dotfile = project.childFile(ProjectConfig.dotfileName);
  final data = jsonDecode(dotfile.readAsStringSync()) as Map<String, dynamic>;
  return data['env'] as String;
}

void main() {
  test('updates the project using the environment', () async {
    final tempDir = _createTempDir();
    final elsewhere = tempDir.childDirectory('elsewhere')..createSync();
    final scope = _createScope(tempDir, elsewhere);
    final project = await _createProject(scope, tempDir, 'app', 'old');

    await renameEnvironment(scope: scope, name: 'old', newName: 'new');

    expect(_readEnv(project), 'new');
  });

  test('leaves the current project on its own environment alone', () async {
    final tempDir = _createTempDir();
    final current = tempDir.childDirectory('current')..createSync();
    final scope = _createScope(tempDir, current);
    await _createProject(scope, tempDir, 'current', 'other');
    await _createProject(scope, tempDir, 'app', 'old');

    await renameEnvironment(scope: scope, name: 'old', newName: 'new');

    expect(_readEnv(current), 'other');
  });

  test('moves the global default to the new name', () async {
    final tempDir = _createTempDir();
    final elsewhere = tempDir.childDirectory('elsewhere')..createSync();
    final scope = _createScope(tempDir, elsewhere);
    await setDefaultEnvName(scope: scope, envName: 'old');

    await renameEnvironment(scope: scope, name: 'old', newName: 'new');

    final config = PuroConfig.of(scope);
    expect(await getDefaultEnvName(scope: scope), 'new');
    expect(
      config.defaultEnvLink.targetSync(),
      config.getEnv('new').envDir.path,
    );
  });

  test('keeps another global default', () async {
    final tempDir = _createTempDir();
    final elsewhere = tempDir.childDirectory('elsewhere')..createSync();
    final scope = _createScope(tempDir, elsewhere);
    await setDefaultEnvName(scope: scope, envName: 'other');

    await renameEnvironment(scope: scope, name: 'old', newName: 'new');

    expect(await getDefaultEnvName(scope: scope), 'other');
  });

  test('points the IntelliJ config at the new environment', () async {
    final tempDir = _createTempDir();
    final elsewhere = tempDir.childDirectory('elsewhere')..createSync();
    final scope = _createScope(tempDir, elsewhere);
    final project = await _createProject(scope, tempDir, 'app', 'old');
    final config = PuroConfig.of(scope);
    final oldDartSdk = config.getEnv('old').flutter.cache.dartSdk;
    oldDartSdk.internalLibrariesDartFile
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'const Map<String, LibraryInfo> libraries = const {\n'
        '  "core": const LibraryInfo("core/core.dart"),\n'
        '};\n',
      );
    final sdkFile =
        project
            .childDirectory('.idea')
            .childDirectory('libraries')
            .childFile('Dart_SDK.xml')
          ..createSync(recursive: true);
    sdkFile.writeAsStringSync(
      '<component name="libraryTable"><library name="Dart SDK"><CLASSES>'
      '<root url="${oldDartSdk.libDir.uri}core" />'
      '</CLASSES></library></component>',
    );

    await renameEnvironment(scope: scope, name: 'old', newName: 'new');

    final newDartSdk = config.getEnv('new').flutter.cache.dartSdk;
    expect(sdkFile.readAsStringSync(), contains('envs/new/'));
    expect(sdkFile.readAsStringSync(), isNot(contains('envs/old/')));
    expect(newDartSdk.internalLibrariesDartFile.existsSync(), isTrue);
  });

  test('points the package config at the new environment', () async {
    final tempDir = _createTempDir();
    final elsewhere = tempDir.childDirectory('elsewhere')..createSync();
    final scope = _createScope(tempDir, elsewhere);
    final project = await _createProject(scope, tempDir, 'app', 'old');
    final config = PuroConfig.of(scope);
    final oldUri = config.getEnv('old').flutterDir.uri;
    final newUri = config.getEnv('new').flutterDir.uri;
    final otherUri = config.getEnv('old2').flutterDir.uri;
    final packageConfig =
        project.childDirectory('.dart_tool').childFile('package_config.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            jsonEncode({
              'flutterRoot': '$oldUri',
              'packages': [
                {'name': 'flutter', 'rootUri': '${oldUri}packages/flutter'},
                {'name': 'other', 'rootUri': '${otherUri}packages/other'},
              ],
            }),
          );

    await renameEnvironment(scope: scope, name: 'old', newName: 'new');

    final data =
        jsonDecode(packageConfig.readAsStringSync()) as Map<String, dynamic>;
    expect(data['flutterRoot'], '$newUri');
    expect(data['packages'], [
      {'name': 'flutter', 'rootUri': '${newUri}packages/flutter'},
      {'name': 'other', 'rootUri': '${otherUri}packages/other'},
    ]);
  });
}
