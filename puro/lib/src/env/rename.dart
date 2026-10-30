import 'dart:convert';

import 'package:file/file.dart';

import '../../models.dart';
import '../command_result.dart';
import '../config.dart';
import '../logger.dart';
import '../progress.dart';
import '../provider.dart';
import '../terminal.dart';
import '../workspace/install.dart';
import 'default.dart';

/// Points a project's package config at the renamed environment.
///
/// It holds absolute uris into the Flutter SDK. The flutter tool sees an up to
/// date config, doesn't run pub get, and then fails to find the Flutter
/// packages.
void _updatePackageConfig({
  required Directory projectDir,
  required EnvConfig from,
  required EnvConfig to,
}) {
  final file = projectDir
      .childDirectory('.dart_tool')
      .childFile('package_config.json');
  if (!file.existsSync()) {
    return;
  }
  final pathContext = file.fileSystem.path;
  final fromUri = '${pathContext.toUri(from.envDir.path)}/';
  final toUri = '${pathContext.toUri(to.envDir.path)}/';
  file.writeAsStringSync(file.readAsStringSync().replaceAll(fromUri, toUri));
}

/// Renames an environment and updates the projects and the global default that
/// use it.
Future<void> renameEnvironment({
  required Scope scope,
  required String name,
  required String newName,
}) async {
  final config = PuroConfig.of(scope);
  final env = config.getEnv(name);
  final log = PuroLogger.of(scope);
  env.ensureExists();
  final newEnv = config.getEnv(newName);

  if (newEnv.exists) {
    throw CommandError('Environment `$newName` already exists');
  } else if (env.name == newEnv.name) {
    throw CommandError('Environment `$name` is already named `$newName`');
  } else if (isPseudoEnvName(newName)) {
    throw CommandError(
      'Environment `$newName` is already pinned to a version, use `puro2 create $newName` to create it',
    );
  }

  final dotfiles = await getDotfilesUsingEnv(scope: scope, environment: env);
  final isDefault = await getDefaultEnvName(scope: scope) == env.name;

  if (env.updateLockFile.existsSync()) {
    await env.updateLockFile.delete();
  }
  await env.envDir.rename(newEnv.envDir.path);

  if (isDefault) {
    await setDefaultEnvName(scope: scope, envName: newEnv.name);
  }

  final updated = <File>[];

  await ProgressNode.of(scope).wrap((scope, node) async {
    node.description = 'Updating projects';
    for (final dotfile in dotfiles) {
      try {
        await switchEnvironment(
          scope: scope,
          envName: newName,
          projectConfig: ProjectConfig(
            parentConfig: config,
            projectDir: dotfile.parent,
            parentProjectDir: dotfile.parent,
          ),
          passive: true,
        );
        _updatePackageConfig(projectDir: dotfile.parent, from: env, to: newEnv);
        updated.add(dotfile);
      } catch (exception, stackTrace) {
        log.e('Exception while switching environment of ${dotfile.parent}');
        log.e('$exception\n$stackTrace');
      }
      final data = jsonDecode(dotfile.readAsStringSync());
      final model = PuroDotfileModel.create();
      model.mergeFromProto3Json(data);
      model.env = newName;
      dotfile.writeAsStringSync(
        prettyJsonEncoder.convert(model.toProto3Json()),
      );
    }
  });

  if (dotfiles.isNotEmpty) {
    CommandMessage(
      'Updated the following projects:\n'
      '${dotfiles.map((p) => '* ${p.parent.path}').join('\n')}',
      type: CompletionType.info,
    ).queue(scope);
  }
}
