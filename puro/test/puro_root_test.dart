import 'package:file/memory.dart';
import 'package:puro2/src/config.dart';
import 'package:puro2/src/logger.dart';
import 'package:puro2/src/provider.dart';
import 'package:test/test.dart';

void main() {
  test('rootOverride replaces the default root', () {
    final fileSystem = MemoryFileSystem();
    final scope = RootScope();
    scope.add(PuroLogger.provider, PuroLogger());

    final root = PuroConfig.getPuroRoot(
      scope: scope,
      fileSystem: fileSystem,
      homeDir: fileSystem.directory('/home'),
      rootOverride: '/custom/root',
    );

    expect(root.path, '/custom/root');
  });
}
