; HMG5 Setup - Inno Setup 6 script
;
; Input : the folder made by tools\make-dist.ps1 (default ..\..\HMG5, override with /DSrc=...)
; Output: dist\Output\HMG5-Setup.exe
;
;   iscc dist\HMG5.iss
;   iscc /DSrc=D:\HMG5 dist\HMG5.iss
;
; Installs to C:\HMG5 by default. The path must not contain spaces: build64.bat and
; the IDE are not tested with spaces in HMGPATH.

#ifndef Src
  #define Src "..\..\HMG5"
#endif
#define AppVer "5.0-test"

[Setup]
AppId={{DBC9F845-3CE9-4FD9-BFCA-CE3CBE31DE41}
AppName=HMG 5
AppVersion={#AppVer}
AppVerName=HMG {#AppVer} (64-bit)
AppPublisher=HMG community
AppPublisherURL=https://github.com/SRathinaGiri/HMG64
DefaultDirName=C:\HMG5
DisableDirPage=no
DefaultGroupName=HMG 5
DisableProgramGroupPage=yes
; A normal user can create a folder in C:\, so no admin rights are needed by default.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Windows 10+: executables use the Universal C Runtime.
MinVersion=10.0
LicenseFile={#Src}\license.txt
InfoAfterFile={#Src}\README-HMG5.txt
OutputDir=Output
OutputBaseFilename=HMG5-Setup
Compression=lzma2/max
SolidCompression=yes
; ISCC 6 is 32-bit: ultra64 + block threads runs it out of memory. A separate
; compressor process gets its own address space.
LZMAUseSeparateProcess=yes
WizardStyle=modern
UninstallDisplayName=HMG {#AppVer} (64-bit)
UninstallDisplayIcon={app}\IDE\IDE.exe

[Files]
; hmg.ini holds the IDE's HMG path; the IDE writes it on first run, so it is never shipped.
Source: "{#Src}\*"; DestDir: "{app}"; Excludes: "\IDE\hmg.ini,\tests\out"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\HMG IDE";               Filename: "{app}\IDE\IDE.exe"; WorkingDir: "{app}\IDE"
Name: "{group}\HMG Samples";           Filename: "{app}\SAMPLES"
Name: "{group}\HMG Documentation";     Filename: "{app}\doc"
Name: "{group}\HMG Command Prompt";    Filename: "{cmd}"; Parameters: "/k ""set PATH={app};%PATH%"" && cd /d ""%USERPROFILE%"""; WorkingDir: "{%USERPROFILE}"
Name: "{group}\Read me";               Filename: "{app}\README-HMG5.txt"
Name: "{group}\Uninstall HMG 5";       Filename: "{uninstallexe}"
Name: "{autodesktop}\HMG IDE";         Filename: "{app}\IDE\IDE.exe"; WorkingDir: "{app}\IDE"; Tasks: desktopicon

[Tasks]
Name: desktopicon; Description: "Create a desktop shortcut for the HMG IDE"

[Code]
function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID = wpSelectDir) and (Pos(' ', WizardDirValue) > 0) then
  begin
    MsgBox('Please choose a folder without spaces (for example C:\HMG5).' + #13#10 +
           'HMG build scripts do not support spaces in the HMG path.', mbError, MB_OK);
    Result := False;
  end;
end;

[Run]
Filename: "{app}\IDE\IDE.exe"; Description: "Start the HMG IDE"; Flags: postinstall nowait skipifsilent unchecked
