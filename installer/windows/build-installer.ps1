# Colophon の Windows 用インストーラーを作る（Windows PowerShell 5.1 / PowerShell 7 の両方で動く）
#
# 使い方（リポジトリのどこからでも）:
#   powershell -ExecutionPolicy Bypass -File installer\windows\build-installer.ps1
#
# 必要なもの: Flutter、Visual Studio 2022（C++ によるデスクトップ開発）、Inno Setup 6
# 出力: build\installer\Colophon-Setup-<版>.exe

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

# --- 版番号（pubspec.yaml の version: 1.2.3+4 の 1.2.3）
$versionLine = Select-String -Path (Join-Path $repo 'pubspec.yaml') -Pattern '^version:\s*([0-9.]+)' | Select-Object -First 1
if (-not $versionLine) { throw 'pubspec.yaml に version が見つかりません' }
$version = $versionLine.Matches[0].Groups[1].Value
Write-Host "Colophon $version のインストーラーを作ります"

# --- Inno Setup のコンパイラ（ISCC.exe）
$isccCandidates = @(
  (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'),
  (Join-Path $env:ProgramFiles 'Inno Setup 6\ISCC.exe')
)
$iscc = $isccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 が見つかりません（winget install JRSoftware.InnoSetup）' }

# --- VC++ ランタイムの再配布用 DLL のフォルダ（Visual Studio の Redist\MSVC\<版>\x64\Microsoft.VC14x.CRT）
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path $vswhere)) { throw 'Visual Studio が見つかりません' }
$vsPath = & $vswhere -latest -products * -property installationPath
$crtDir = Get-ChildItem (Join-Path $vsPath 'VC\Redist\MSVC') -Directory |
  Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
  Sort-Object { [version]$_.Name } -Descending |
  ForEach-Object { Get-ChildItem (Join-Path $_.FullName 'x64') -Directory -Filter 'Microsoft.VC*.CRT' -ErrorAction SilentlyContinue } |
  Select-Object -First 1
if (-not $crtDir) { throw 'VC++ ランタイムの再配布用 DLL が見つかりません' }
Write-Host "VC++ ランタイム: $($crtDir.FullName)"

# --- リリース版をビルドする。
# 繰り返しビルドするとアイコン用フォントの間引き結果が古いまま残り、新しく使ったアイコンが
# 空白になることがあるため、毎回 clean してから作る。
flutter clean
if ($LASTEXITCODE -ne 0) { throw 'flutter clean に失敗しました' }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get に失敗しました' }
flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw 'flutter build windows に失敗しました' }

# --- インストーラーを作る
& $iscc "/DAppVersion=$version" "/DCrtDir=$($crtDir.FullName)" (Join-Path $PSScriptRoot 'colophon.iss')
if ($LASTEXITCODE -ne 0) { throw 'インストーラーの作成に失敗しました' }

$output = Join-Path $repo "build\installer\Colophon-Setup-$version.exe"
Write-Host ''
Write-Host "完成: $output"
