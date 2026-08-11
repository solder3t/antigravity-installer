# Antigravity Installer

A secure, robust, and native installation script for Antigravity 2.0 on Linux. This installer supports installing both the standalone **Antigravity IDE** and the **Antigravity Agent**, with automated desktop integration and version management.

## Features

- 🚀 **Automated Version Detection**: Automatically queries Google servers to pull the absolute latest stable release (with a bundled offline fallback).
- 🔄 **Unified Installation Modes**: Install the IDE, the Agent, or both sequentially using an interactive menu or command-line flags.
- 🐧 **Native Desktop Integration**: Automatically generates `.desktop` shortcuts and handles Wayland window rendering flags out of the box.
- 🧹 **Clean Uninstallation**: The bundled `uninstall.sh` lets you surgically remove the IDE, the Agent, or cleanly wipe both from your system.
- 🛡️ **Flexible Scope**: Install system-wide via `sudo` (`/opt`) or to user-space (`~/.local`) without requiring root privileges.

## Usage

You can run the installer interactively:
```bash
./install.sh
```

Or you can use command-line flags to automate the installation:

```bash
# Install the IDE only
./install.sh --mode ide

# Install the Agent only
./install.sh --mode agent

# Install both the IDE and the Agent sequentially
./install.sh --mode both

# Install to user-space (no root required)
./install.sh --mode both --user

# Force offline mode (skip version auto-detection)
./install.sh --mode ide --offline
```

### Options

| Flag | Description |
| :--- | :--- |
| `--mode <ide\|agent\|both>` | Choose target application variant. |
| `--user` | Install to user space (`~/.local`) without requiring root privileges. |
| `--url <url>` | Override the default download URL with a custom tarball link. |
| `--offline` | Skip the version feed check and use the bundled fallback version. |
| `--dry-run` | Perform pre-flight checks and package download only. No files written. |
| `--check-update` | Check if an update is available for the currently installed version. |
| `-y, --yes` | Automatic yes to prompts (bypass confirmation). |

## Uninstallation

To cleanly remove Antigravity from your system, use the uninstaller:

```bash
./uninstall.sh
```

You can also pass flags directly:
```bash
# Remove IDE only
./uninstall.sh --ide

# Remove Agent only
./uninstall.sh --agent

# Completely remove both
./uninstall.sh --both
```

## Troubleshooting

- **Permissions**: If the scripts are not executable, run `chmod +x install.sh uninstall.sh`.
- **Dock Grouping**: The installer assigns unique window classes (`AntigravityIDE` and `Antigravity`) to ensure your dock correctly separates the two applications.

## Credits

This installer adapts logic and templates from the [Antigravity 2 Fedora Installer](https://github.com/jrobertogarcia/antigravity-2-fedora-installer) by [jrobertogarcia](https://github.com/jrobertogarcia). Thank you for the foundational inspiration!

## License

This project (the installer utility) is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

> **Note**: The upstream Antigravity 2.0 binaries packaged and downloaded by this utility are proprietary and subject to the [Google Terms of Service](https://policies.google.com/terms) and any applicable Antigravity specific end-user license agreements.
