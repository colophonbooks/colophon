# Building Colophon

[日本語](BUILDING.ja.md) | English

How to set up a development environment and build Colophon on Windows, macOS, and Linux.

## Before you start

- **Each desktop version can only be built on its own OS.** Build the Windows version on Windows, the macOS version on a Mac, and the Linux version on Linux (Flutter does not support cross-compiling desktop apps).
- **The first build needs an internet connection.** It downloads the package dependencies and a prebuilt SQLite library.
- You need **Flutter 3.47 or later (stable channel)**. `pubspec.yaml` requires Dart 3.13.5 or later, so older Flutter versions cannot build the app.

| | Windows | macOS | Linux |
|---|---|---|---|
| OS | Windows 10 / 11 (64-bit) | The latest or previous macOS | Ubuntu 22.04 or later, etc. (64-bit) |
| Required tools | Git, Visual Studio 2022 (Desktop development with C++) | Xcode | Git, clang, CMake, Ninja, GTK 3 development packages |
| OS settings | Enable Developer Mode | Accept the Xcode license | — |
| Build output | `build\windows\x64\runner\Release\` | `build/macos/Build/Products/Release/Colophon.app` | `build/linux/x64/release/bundle/` |

---

## Windows

### 1. Install Git

Install [Git for Windows](https://git-scm.com/download/win). The default installer options are fine.

### 2. Install Visual Studio 2022

Install one of the following, and select the **Desktop development with C++** workload in the installer:

- [Visual Studio 2022 Community](https://visualstudio.microsoft.com/vs/community/) (free IDE)
- [Build Tools for Visual Studio 2022](https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022) (build tools only; lighter, and enough if you don't need the IDE)

> Visual Studio and Visual Studio **Code** are different products. Even if you use VS Code as your editor, you still need one of the above to build.

### 3. Enable Developer Mode

Flutter plugins use symbolic links, which require Windows Developer Mode.

- Windows 11: **Settings** → **System** → **For developers** → turn on **Developer Mode**
- Windows 10: **Settings** → **Update & Security** → **For developers** → turn on **Developer Mode**

You can also open the same settings page by running `start ms-settings:developers` in PowerShell.

### 4. Install the Flutter SDK

Run the following in PowerShell (this example installs to `C:\src\flutter`; avoid paths containing spaces or non-ASCII characters):

```powershell
New-Item -ItemType Directory -Force C:\src | Out-Null
git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter

# Add Flutter to your user PATH (takes effect in newly opened terminals)
$p = [Environment]::GetEnvironmentVariable('Path', 'User')
[Environment]::SetEnvironmentVariable('Path', "$p;C:\src\flutter\bin", 'User')
```

Open a new terminal and check your environment:

```powershell
flutter --version
flutter doctor
```

You are ready when `flutter doctor` shows `[√]` for **Flutter** and **Visual Studio - develop Windows apps**. (The Android and Chrome items are not needed for the Windows build.)

### 5. Build

→ Continue with [Building (all platforms)](#building-all-platforms). The build command is `flutter build windows --release`.

### Distributing

- Distribute the **whole** `build\windows\x64\runner\Release\` folder. `colophon.exe` alone will not run; it needs the DLLs and the `data` folder next to it.
- The app is not code-signed, so Windows SmartScreen may show a warning on first launch (click **More info** → **Run anyway**).

---

## macOS

### 1. Install Xcode

Install [Xcode](https://apps.apple.com/app/xcode/id497799835) from the App Store, then launch it once to finish installing its additional components.

Next, run the following in Terminal to configure the command-line tools and accept the license:

```sh
sudo sh -c 'xcode-select -s /Applications/Xcode.app/Contents/Developer && xcodebuild -runFirstLaunch'
sudo xcodebuild -license
```

> **CocoaPods is not required.** Since Flutter 3.44, native dependencies are managed with Swift Package Manager, and every plugin this app uses supports it.

### 2. Install the Flutter SDK

Git comes with the Xcode command-line tools.

```sh
mkdir -p ~/development
git clone https://github.com/flutter/flutter.git -b stable ~/development/flutter

# Add Flutter to the PATH for zsh (the default macOS shell)
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Check your environment:

```sh
flutter --version
flutter doctor
```

You are ready when `flutter doctor` shows `[√]` for **Flutter** and **Xcode - develop for iOS and macOS**.

### 3. Build

→ Continue with [Building (all platforms)](#building-all-platforms). The build command is `flutter build macos --release`.

### Distributing

- Distribute `build/macos/Build/Products/Release/Colophon.app`.
- Gatekeeper may refuse to open apps that are not signed and notarized. To try it on your own Mac, right-click `Colophon.app` in Finder and choose **Open**.
- Distributing to other people at scale requires enrollment in the Apple Developer Program and code signing plus notarization (outside the scope of this guide).

---

## Linux

These steps are for Ubuntu / Debian-based distributions. On other distributions, install the equivalent packages with your package manager.

### 1. Install the required packages

```sh
sudo apt-get update -y
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa \
  clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev
```

> If `libstdc++-12-dev` is not available, use the version your distribution provides (for example, `libstdc++-14-dev`).

### 2. Install the Flutter SDK

```sh
mkdir -p ~/development
git clone https://github.com/flutter/flutter.git -b stable ~/development/flutter

# Add Flutter to the PATH for bash (use ~/.zshrc if you use zsh)
echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Check your environment:

```sh
flutter --version
flutter doctor
```

You are ready when `flutter doctor` shows `[√]` for **Flutter** and **Linux toolchain - develop for Linux desktop**.

### 3. Build

→ Continue with [Building (all platforms)](#building-all-platforms). The build command is `flutter build linux --release`.

### Running and distributing

- Distribute the **whole** `build/linux/x64/release/bundle/` folder and run the `colophon` executable inside it (on ARM64 machines: `build/linux/arm64/release/bundle/`).
- The dialogs for choosing a cover image and an export location use **xdg-desktop-portal**. Common desktop environments such as GNOME and KDE include it by default. If the file dialog does not open on a minimal setup, install `xdg-desktop-portal` and a backend that matches your desktop (such as `xdg-desktop-portal-gtk`).

---

## Building (all platforms)

The following steps are the same on every OS.

### 1. Get the source code

```sh
git clone https://github.com/colophonbooks/colophon.git
cd colophon
```

### 2. Fetch dependencies

```sh
flutter pub get
```

The localization code generated from the UI strings (`lib/l10n/app_*.arb`) is created automatically by `flutter pub get`, `flutter run`, and `flutter build`.

### 3. Run the tests (optional)

```sh
flutter test
```

If every test passes, the output ends with `All tests passed!`.

### 4. Run during development

To try changes as you edit the source, launch a debug build. While it is running, press `r` in the terminal to apply your changes instantly (hot reload).

```sh
flutter run -d windows   # use -d macos on macOS, -d linux on Linux
```

### 5. Build a release version

```sh
flutter build windows --release   # Windows
flutter build macos --release     # macOS
flutter build linux --release     # Linux
```

See the "Build output" row of the [table at the top](#before-you-start) for where the result is placed.

The app version comes from `version:` in `pubspec.yaml` (for example `1.0.0+1`; the number after `+` is the build number).

---

## Building distribution packages (installers)

The scripts for each OS are in `installer/`. Each one cleans old build output (`flutter clean`), builds a release version, and writes to `build/installer/`.

| OS | Package | Command | Output |
|---|---|---|---|
| Windows | Installer (Inno Setup) | `powershell -ExecutionPolicy Bypass -File installer\windows\build-installer.ps1` | `Colophon-Setup-<version>.exe` |
| macOS | Disk image | `bash installer/macos/build-dmg.sh` | `Colophon-<version>.dmg` |
| Linux | Flatpak | `bash installer/linux/build-flatpak.sh` | `Colophon-<version>.flatpak` |
| Linux | .deb (Ubuntu / Debian) | `bash installer/linux/build-deb.sh` | `colophon_<version>_<arch>.deb` |

The version number comes from `version:` in `pubspec.yaml`.

### Windows

- **Also required**: Inno Setup 6 (`winget install --id JRSoftware.InnoSetup -e --scope user` installs it without administrator rights).
- **Install location**: per user (`%LOCALAPPDATA%\Programs\Colophon`). No administrator rights needed.
- **VC++ runtime**: three DLLs from Visual Studio's redistributable folder are bundled, so the app starts even on PCs without the runtime installed.
- **Uninstalling**: done from **Settings → Apps**. At the end it asks whether to delete the library as well; the default is "No" (keep the data). Silent uninstalls (`/SILENT`, etc.) always keep the data.

### macOS

- Open the `.dmg` and drag Colophon to "Applications" to install it.
- macOS has no uninstaller mechanism, so the `.dmg` includes `How to uninstall.txt` explaining how to delete the data: use **Settings → Data → Delete all data** in the app, or delete `~/Library/Containers/io.github.colophonbooks.colophon`.
- The app is not signed or notarized. Distributing it widely requires enrollment in the Apple Developer Program.

### Linux

| Format | Also required | Install | Uninstall |
|---|---|---|---|
| Flatpak | `flatpak`, `flatpak-builder`, the Flathub remote | `flatpak install --user Colophon-<version>.flatpak` | `flatpak uninstall --delete-data io.github.colophonbooks.colophon` (also deletes the library) |
| .deb | `dpkg-deb` (standard on Debian-based systems) | `sudo apt install ./colophon_<version>_amd64.deb` | `sudo apt remove colophon` (the library is kept) |

- Uninstalling the `.deb` keeps the library (`~/.local/share/io.github.colophonbooks.colophon`), because Debian packages never touch users' home folders. To delete it, use **Delete all data** in the app first.
- The Flatpak version stores its data in `~/.var/app/io.github.colophonbooks.colophon`.
- Update `runtime-version` in the Flatpak manifest when a newer runtime is released.

### Regenerating the app icon

The icon's artwork and colors are defined in `tool/icon/generate.mjs`. After changing it, run the commands below to regenerate the icons for Windows (`.ico`), macOS (`AppIcon.appiconset`), and Linux (`installer/linux/icons/`) in one go. Commit the generated files too (building the app itself does not need Node.js).

```bash
npm install --prefix tool/icon      # first time only; also downloads Chrome for rendering
node tool/icon/generate.mjs
```

- **Requires**: Node.js 18 or later.
- To use an installed Chrome instead, set `CHROME_PATH` to the path of its executable.
- Windows tends to keep the old icon in previous build output, so run `flutter clean` before building after regenerating (the packaging scripts always clean).

---
## Troubleshooting

| Symptom | What to do |
|---|---|
| Not sure what is missing | Run `flutter doctor -v` and follow the instructions for items marked `[X]` or `[!]` |
| Windows: `Building with plugins requires symlink support.` | Enable Developer Mode ([Windows step 3](#3-enable-developer-mode)) |
| Windows: `Unable to find suitable Visual Studio toolchain` | In the Visual Studio Installer, check that **Desktop development with C++** is installed |
| Linux: errors about GTK or `pkg-config` | Check that every package from [Linux step 1](#1-install-the-required-packages) is installed |
| A build that used to work suddenly fails | Run `flutter clean`, then `flutter pub get`, and build again |
| In a release build, newly used icons (such as ★) are blank | Release builds shrink the icon font to the icons in use, and repeated builds can reuse a stale font. Run `flutter clean`, then `flutter pub get`, and build again (this does not happen in debug builds or `flutter test`) |
| Flutter says your version is too old | Run `flutter upgrade` to update to the latest stable release |

For the app's features and data format, see [README.md](README.md).
