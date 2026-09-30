; Script de Instalacao do ArkZ3dhedron
; Gerado para Inno Setup

#define MyAppName "ArkZ 3D Hedron"
#ifndef MyAppVersion
  #define MyAppVersion "260915"
#endif
#define MyAppPublisher "ARK-Z ARQUITETURA"
#define MyAppURL "https://em-rezende.github.io"

[Setup]
AppId={{6C0E608A-3EAA-4F09-8CB2-77A098B13CC2}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
; Pastas que o Autoloader do AutoCAD varre na inicializacao:
;   %APPDATA%\Autodesk\ApplicationPlugins               (somente o usuario atual)
;   %PROGRAMDATA%\Autodesk\ApplicationPlugins           (todos os usuarios)
;   C:\Program Files (x86)\Autodesk\ApplicationPlugins  (todos os usuarios - padrao ARK-Z,
;                                                        mesmo local dos outros plugins ARK-Z)
; O destino e decidido no assistente ("para todos os usuarios" x "somente para mim"):
;   para todos os usuarios -> C:\Program Files (x86)\Autodesk\ApplicationPlugins
;   somente para mim       -> %APPDATA%\Autodesk\ApplicationPlugins   (sem admin)
; Ver GetDestinoPadrao em [Code].
DefaultDirName={code:GetDestinoPadrao}
DefaultGroupName=ARK-Z\ArkZ3dhedron
AllowNoIcons=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog commandline
OutputDir=.\Instalador
OutputBaseFilename=ArkZ3dhedron_v_{#MyAppVersion}_Setup
SetupIconFile=.\Support\Ark-Z.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
WizardImageFile=.\Support\ArkZ_large.bmp
WizardSmallImageFile=.\Support\ArkZ_small.bmp
UninstallDisplayIcon={app}\Contents\Resources\Ark-Z.ico
UninstallDisplayName={#MyAppName} v{#MyAppVersion}
AppCopyright=(c) 2026 ARK-Z ARQUITETURA

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
; ============================================================
; BUNDLE COMPLETO (PackageContents.xml + Contents\...)
; ============================================================
; O curinga copia a pasta ArkZ3dhedron.bundle inteira para {app}, que termina
; exatamente em "...\ArkZ3dhedron.bundle" - exigencia do Autoloader do AutoCAD
; (PackageContents.xml na raiz do bundle).
; IMPORTANTE: o parametro Excludes evita que arquivos que NAO fazem parte do
; pacote sejam embutidos pelo curinga recursivo (era o caso do proprio .iss,
; quando o Source apontava para ".\Fonts\*").

; Source: ".\ArkZ3dhedron.bundle\*"; DestDir: "{app}"; Excludes: "*.iss,.gitignore,.git*,*.bak,Thumbs.db,desktop.ini"; Flags: ignoreversion recursesubdirs
; Source: "README.MD";          DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
; Source: "LICENSE";            DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
; Source: "Instrucoes.txt";     DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
; Source: "docs\PROTOCOL.md";   DestDir: "{app}\docs"; Flags: ignoreversion skipifsourcedoesntexist

; Arquivos de suporte adicionais (fontes, etc.), se existirem.
; Nao use {autopf} aqui: no modo "somente para mim" o destino e o {app}.
Source: ".\Fonts\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs skipifsourcedoesntexist


[UninstallDelete]
; ============================================================
; REMOVE TODOS OS ARQUIVOS DO ArkZ3dhedron
; ============================================================
Type: filesandordirs; Name: "{app}"
Type: filesandordirs; Name: "{group}"


; ============================================================
; CODIGO PASCAL
; ============================================================
[Code]

// ============================================================
// FUNCAO PARA VERIFICAR SE O AUTOCAD ESTA INSTALADO
// ============================================================
function IsAutoCADInstalled: Boolean;
var
  RegKey: string;
  i: Integer;
  SubKeys: TArrayOfString;
  j: Integer;
begin
  Result := False;
  RegKey := 'Software\Autodesk\AutoCAD\';
  
  for i := 19 to 26 do
  begin
    if RegKeyExists(HKEY_CURRENT_USER, RegKey + 'R' + IntToStr(i) + '.0') then
    begin
      if RegGetSubkeyNames(HKEY_CURRENT_USER, RegKey + 'R' + IntToStr(i) + '.0', SubKeys) then
      begin
        for j := 0 to GetArrayLength(SubKeys) - 1 do
        begin
          if Pos('ACAD-', SubKeys[j]) = 1 then
          begin
            Result := True;
            Exit;
          end;
        end;
      end;
    end;
    
    if RegKeyExists(HKEY_CURRENT_USER, RegKey + 'R' + IntToStr(i) + '.1') then
    begin
      if RegGetSubkeyNames(HKEY_CURRENT_USER, RegKey + 'R' + IntToStr(i) + '.1', SubKeys) then
      begin
        for j := 0 to GetArrayLength(SubKeys) - 1 do
        begin
          if Pos('ACAD-', SubKeys[j]) = 1 then
          begin
            Result := True;
            Exit;
          end;
        end;
      end;
    end;
  end;
end;

// ============================================================
// TELA DE BOAS-VINDAS PERSONALIZADA
// ============================================================
function InitializeSetup(): Boolean;
begin
  Result := True;
  
  if not IsAutoCADInstalled then
  begin
    MsgBox('ATENCAO: Nenhuma versao do AutoCAD foi encontrada neste computador.' + #13#10 +
           'O ArkZ3dhedron requer AutoCAD 2013 ou superior para funcionar.' + #13#10 + #13#10 +
           'A instalacao continuara, mas o programa pode nao funcionar corretamente.',
           mbInformation, MB_OK);
  end;
end;

// ============================================================
// FUNCAO DE LIMPEZA - REMOVE ARQUIVOS CUIX/MNR DO ArkZ3dhedron
// ============================================================
procedure DeleteArkZ3dhedronFiles(const RootPath: string);
var
  FindRec: TFindRec;
  FilePath: string;
  FileName: string;
begin
  if FindFirst(RootPath + '\*', FindRec) then
  begin
    try
      repeat
        if (FindRec.Name <> '.') and (FindRec.Name <> '..') then
        begin
          FilePath := RootPath + '\' + FindRec.Name;
          FileName := LowerCase(FindRec.Name);

          if FindRec.Attributes and FILE_ATTRIBUTE_DIRECTORY <> 0 then
            DeleteArkZ3dhedronFiles(FilePath)
          else if (Pos('ArkZ3dhedron', FileName) > 0) and   // <<< tudo minusculo
                  ((Pos('.cuix', FileName) > 0) or
                   (Pos('.mnr', FileName) > 0)) then
            DeleteFile(FilePath);
        end;
      until not FindNext(FindRec);
    finally
      FindClose(FindRec);
    end;
  end;
end;

// =====================================================================
// DESTINO PADRAO (conforme o modo escolhido no assistente)
// =====================================================================
// "para todos os usuarios" -> C:\Program Files (x86)\Autodesk\ApplicationPlugins
// "somente para mim"       -> %APPDATA%\Autodesk\ApplicationPlugins  (sem admin)
function GetDestinoPadrao(Param: String): String;
begin
  if IsAdminInstallMode then
    Result := ExpandConstant('{commonpf32}\Autodesk\ApplicationPlugins\ArkZ3dhedron.bundle')
  else
    Result := ExpandConstant('{userappdata}\Autodesk\ApplicationPlugins\ArkZ3dhedron.bundle');
end;

// ============================================================
// EVENTO DE DESINSTALACAO
// ============================================================
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  i: Integer;
  Versions: array of string;
  SupportPath: string;
begin
  if CurUninstallStep = usUninstall then
  begin
    Versions := ['2013', '2014', '2015', '2016', '2017', '2018', 
                 '2019', '2020', '2021', '2022', '2023', '2024', '2025', '2026'];
    
    for i := 0 to GetArrayLength(Versions) - 1 do
    begin
      SupportPath := ExpandConstant('{userappdata}') + 
                     '\Autodesk\AutoCAD ' + Versions[i];
      
      if DirExists(SupportPath) then
        DeleteArkZ3dhedronFiles(SupportPath);
    end;
  end;
end;