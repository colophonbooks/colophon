; Colophon の Windows 用インストーラー（Inno Setup 6）
; 通常は build-installer.ps1 から作る。手で作る場合:
;   ISCC.exe /DAppVersion=1.0.0 /DCrtDir="<VC++ 再配布 DLL のフォルダ>" colophon.iss

#define AppName "Colophon"
#define AppPublisher "colophonbooks"
#define AppExeName "colophon.exe"
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif

[Setup]
; AppId はアップデートとアンインストールの識別に使う。一度公開したら変えない
AppId={{5C45DCEB-65C4-4875-90F0-193FC057D99B}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL=https://github.com/colophonbooks
AppSupportURL=https://github.com/colophonbooks
VersionInfoVersion={#AppVersion}
; 使う人ごとのインストール（管理者権限不要）。{autopf} は %LOCALAPPDATA%\Programs になる
PrivilegesRequired=lowest
DefaultDirName={autopf}\{#AppName}
DisableProgramGroupPage=yes
LicenseFile=..\..\LICENSE
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
OutputDir=..\..\build\installer
OutputBaseFilename=Colophon-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; 起動中の Colophon があれば、閉じるよう促す
CloseApplications=yes
RestartApplications=no
ShowLanguageDialog=auto

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "ja"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "zh"; MessagesFile: "Languages\ChineseSimplified.isl"
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"
Name: "ko"; MessagesFile: "compiler:Languages\Korean.isl"

[CustomMessages]
en.DeleteUserData=Do you also want to delete your Colophon library (books, notes, tags, and settings)?%n%nChoose "No" to keep it, for example when reinstalling or updating.%n%nDeleted data cannot be restored.
ja.DeleteUserData=Colophon の書籍データ（書籍・ノート・タグ・設定）も削除しますか？%n%n再インストールや更新のためにデータを残す場合は「いいえ」を選んでください。%n%n削除したデータは元に戻せません。
zh.DeleteUserData=是否同时删除 Colophon 的数据（书籍、笔记、标签和设置）？%n%n如需重新安装或更新而保留数据，请选择“否”。%n%n删除的数据无法恢复。
fr.DeleteUserData=Voulez-vous aussi supprimer votre bibliothèque Colophon (livres, notes, étiquettes et réglages) ?%n%nChoisissez « Non » pour la conserver, par exemple pour une réinstallation ou une mise à jour.%n%nLes données supprimées ne peuvent pas être restaurées.
es.DeleteUserData=¿Quieres eliminar también tu biblioteca de Colophon (libros, notas, etiquetas y ajustes)?%n%nElige «No» para conservarla, por ejemplo al reinstalar o actualizar.%n%nLos datos eliminados no se pueden recuperar.
de.DeleteUserData=Soll auch die Colophon-Bibliothek (Bücher, Notizen, Tags und Einstellungen) gelöscht werden?%n%nWählen Sie „Nein“, um sie zu behalten, zum Beispiel bei einer Neuinstallation oder einem Update.%n%nGelöschte Daten können nicht wiederhergestellt werden.
ko.DeleteUserData=Colophon 데이터(책, 노트, 태그, 설정)도 삭제할까요?%n%n다시 설치하거나 업데이트하기 위해 데이터를 남기려면 "아니요"를 선택하세요.%n%n삭제한 데이터는 복구할 수 없습니다.

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
#ifdef CrtDir
; VC++ ランタイム（アプリと同じフォルダに置く方式。Microsoft が認める配布方法）
Source: "{#CrtDir}\msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#CrtDir}\vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#CrtDir}\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion
#endif

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[Code]
// アンインストールの最後に、書籍データ（データベースと設定）を消すか確認する。
// 既定は「いいえ」（再インストール・更新でデータを失わないように）。
// 画面を出さないアンインストール（/SILENT など）では確認できないので、消さずに残す。
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  DataDir, ParentDir: String;
begin
  if CurUninstallStep <> usPostUninstall then
    Exit;
  DataDir := ExpandConstant('{userappdata}\colophonbooks\Colophon');
  if UninstallSilent or not DirExists(DataDir) then
    Exit;
  if MsgBox(CustomMessage('DeleteUserData'), mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES then
  begin
    DelTree(DataDir, True, True, True);
    // 親フォルダ（colophonbooks）は空のときだけ消える
    ParentDir := ExpandConstant('{userappdata}\colophonbooks');
    RemoveDir(ParentDir);
  end;
end;
