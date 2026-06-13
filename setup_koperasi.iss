; Script Inno Setup untuk Aplikasi TPK Koperasi Sawit

#define MyAppName "TPK Koperasi Sawit KUD Berkat"
#define MyAppVersion "2.0.0"
#define MyAppPublisher "KUD Berkat"
#define MyAppExeName "tpk_koperasi.exe"
#define MyAppBuildPath "c:\Users\yoru\Documents\College\Project\Aplikasi Koperasi\build\windows\x64\runner\Release"

[Setup]
AppId={{A8F4C69D-B1C8-4DE3-A0A3-9F93E4E81A2C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
; Tempat menyimpan file installer setup yang dihasilkan
OutputDir=c:\Users\yoru\Documents\College\Project\Aplikasi Koperasi\build\windows\installer
OutputBaseFilename=TPK_Koperasi_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

; PENTING: Memaksa instalasi berjalan pada mode 64-bit
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; 1. Menyertakan executable utama aplikasi
Source: "{#MyAppBuildPath}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; 2. Menyertakan seluruh file pendukung (.dll dan folder data/) dari hasil build release
Source: "{#MyAppBuildPath}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; 3. Menyertakan VC++ Redistributable installer ke folder temp saat instalasi
Source: "c:\Users\yoru\Documents\College\Project\Aplikasi Koperasi\installer\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; 4. Menjalankan VC++ Redistributable secara otomatis di latar belakang (tanpa tampilan popup instalasi yang rumit bagi user)
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/passive /norestart"; Flags: runascurrentuser; StatusMsg: "Menginstal dependensi sistem (Microsoft Visual C++)..."

; 5. Menjalankan aplikasi setelah instalasi selesai
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
