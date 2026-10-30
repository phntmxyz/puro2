## 2.0.1

### Fixes

- Web builds no longer fail with "SDK root directory not found" ([#10](https://github.com/phntmxyz/puro2/pull/10))
- `puro2 dart pub` finds the Flutter SDK again ([pingbird/puro#147](https://github.com/pingbird/puro/issues/147), [#11](https://github.com/phntmxyz/puro2/pull/11), thx @nielsenko)
- `puro2 rename` keeps the global default, the package config of your projects and their IDE configs on the renamed environment, and no longer changes the `.puro.json` of the project you are in ([#15](https://github.com/phntmxyz/puro2/pull/15))
- `puro2 upgrade --force` no longer crashes, and it repairs an environment whose checkout is broken ([#14](https://github.com/phntmxyz/puro2/pull/14))
- `--root` is no longer ignored, it also applies to `upgrade-puro2` and to the `bin/puro2` script of a standalone executable ([#18](https://github.com/phntmxyz/puro2/pull/18))
- `prefs.json` stays readable for Puro 1.4.9 and older, an existing file gets fixed on its next update, for example with `puro2 use --global <env>` ([#20](https://github.com/phntmxyz/puro2/pull/20))

### Windows

- Installing into a path with spaces or `[` no longer crashes while unzipping the engine ([#13](https://github.com/phntmxyz/puro2/pull/13))
- Environment paths over about 63 characters no longer break Flutter checkouts: `puro2 upgrade` failed and `puro2 create` silently left files out ([#16](https://github.com/phntmxyz/puro2/pull/16))
- `bin\puro2.bat` of a standalone executable returns the exit code of the command instead of always 0, existing scripts get this with `puro2 install-puro2 --force` ([#21](https://github.com/phntmxyz/puro2/pull/21))

[diff 2.0.0...2.0.1](https://github.com/phntmxyz/puro2/compare/2.0.0...2.0.1)

## 2.0.0

The first release of Puro2, phntm's fork of [Puro](https://github.com/pingbird/puro).

### Switching from Puro

Puro2 takes over an existing Puro installation in `~/.puro`.
Your environments, the global default and the `.puro.json` of your projects carry over, and no Flutter version is downloaded again.
`puro upgrade-puro` can't do the switch, it only ever installs the original Puro.

1. Install Puro2 with the command for your platform from [puro2.phntm.xyz](https://puro2.phntm.xyz), on macOS and Linux:

   ```bash
   curl -o- https://puro2.phntm.xyz/install.sh | bash
   ```

   This puts `puro2` next to `puro` in `~/.puro/bin` and points the `flutter` and `dart` commands of every environment at `puro2`.
2. Open a new terminal and run `puro2 ls`, which lists your existing environments.
3. Delete the old executable with `rm ~/.puro/bin/puro`, on Windows `del %USERPROFILE%\.puro\bin\puro.exe`.
   Environments that the old `puro` creates still call the original Puro.

From then on, use `puro2` where you used `puro`.
`install-puro`, `upgrade-puro` and `uninstall-puro` are now `install-puro2`, `upgrade-puro2` and `uninstall-puro2`, and `puro2` still accepts the old names.

### Updates

- `puro2 upgrade-puro2` downloads new versions from [GitHub Releases](https://github.com/phntmxyz/puro2/releases)
- GitHub Releases is the only way to get Puro2, `dart pub global activate` and the `master` build channel are gone

## 1.5.0

- Fixed several major bugs
- Added native arm64 mac build

## 1.4.11

- Bug fixes
- Added `-d` flag to `puro ls` to show dart versions

## 1.4.10

- Bug fixes

## 1.4.9

- Bug fixes

## 1.4.8

- Bug fixes
- Support for newer versions of Flutter that use the monorepo

## 1.4.7

- Bug fixes

## 1.4.6

- Bug fixes

## 1.4.5

- Bug fixes

## 1.4.4

- Bug fixes

## 1.4.3

- Absolutely nothing, the `+1` of the previous release broke CloudFront lol

## 1.4.2+1

- Bug fixes

## 1.4.2

- Bug fixes
- Unused caches are now cleaned up automatically

## 1.4.1

- Bug fixes
- Added the `build-shell` command to open a shell for building the Flutter engine manually
- Added the `--projects`/`-p` flag to `ls` to show which projects are using each environment

## 1.4.0

- Bug fixes
- Added support for versioned environments, you can now `puro use <version>` to switch to a specific version instead of
  creating one manually

## 1.3.8

- Bug fixes

## 1.3.7

- Bug fixes
- The `ls` command now has a separate indicator for the global default
- The `create` and `upgrade` commands now recognize tags without an official release

## 1.3.6

- Bug fixes
- Now using 7zip to speed up engine unzipping on Windows
- Added 'downgrade' as an alias for the 'upgrade' command
- Added the `rename` command
- The `rm` command now warns if known projects are using the environment

## 1.3.5

- Bug fixes

## 1.3.4

- Bug fixes

## 1.3.3

- Bug fixes

## 1.3.2

- Bug fixes

## 1.3.1

- Bug fixes

## 1.3.0

- Bug fixes
- Added the `uninstall-puro` command

## 1.2.6

- Bug fixes

## 1.2.5

- Bug fixes

## 1.2.4

- Added the `--extra` option to to `eval`
- Added the `repl` command

## 1.2.3

- Bug fixes

## 1.2.2

- Bug fixes

## 1.2.1

- Bug fixes
- Added package support to eval

## 1.2.0

- Bug fixes
- Added the `eval` command

## 1.1.13

- Bug fixes

## 1.1.12

- Bug fixes

## 1.1.11

- Bug fixes
- Added support for Google storage mirrors with FLUTTER_STORAGE_BASE_URL
- Added the `engine prepare` command
- Added the `engine build-env` command

## 1.1.10

- Bug fixes

## 1.1.9

- Bug fixes

## 1.1.8

- Bug fixes

## 1.1.7

- Bug fixes
- Added global configuration for bash/zsh profiles
- Improved Windows installer

## 1.1.6

- Bug fixes

## 1.1.5

- Bug fixes

## 1.1.4

- Bug fixes
- Improved installing puro inside symlinks and non-standard paths

## 1.1.3

- Bug fixes
- Added support for older versions of Flutter

## 1.1.2

- Bug fixes

## 1.1.1

- Bug fixes

## 1.1.0

- Bug fixes
- Added the `ls-versions` command
- Added the `gc` command

## 1.0.1

- Bug fixes
- Better support for standalone and pub installs

## 1.0.0

- Bug fixes
- First stable release

## 0.6.1

- Fix small issue with upgrades

## 0.6.0

- Bug fixes
- Added automatic update checks
- Changed the default pub root to ~/.puro/shared/pub_cache
- Upgrades now infer the branch
- Added the `--fork` option to `puro create`

## 0.5.0

- Bug fixes
- Added the `pub` command
- Added the `upgrade-puro` command
- Added dart/flutter shims to .puro/bin
- Improved bash/zsh profile updating mechanism
- Added the hidden `install-puro` command
- Added PATH conflict detection to the `version` command

## 0.4.1

- Bug fixes
- Added the `--global` flag to `puro use` to set the default environment
- Implemented default environments

## 0.4.0

- Bug fixes
- Performance improvements
- Added the `upgrade` command for upgrading environments
- Added the `--vscode` and `--intellij` flags to `puro use` which override whether their configs are generated
- Added the `version` command

## 0.3.0

- Bug fixes

## 0.2.0

- Bug fixes
- Performance improvements

## 0.1.0

- Added progress bars
- Added puro as an executable

## 0.0.1

Initial version
