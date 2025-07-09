@echo off
set SCRIPT_AES256_ENCRYPTION_KEY=

chcp 65001
scons platform=windows windows_subsystem=console target=editor arch=x86_64 compiledb=yes deprecated=yes minizip=yes
if %errorlevel% neq 0 (
  echo Error: Build failure target=editor
  pause
  exit /b %errorlevel%
)
scons platform=windows windows_subsystem=console target=template_release arch=x86_64 compiledb=yes deprecated=yes minizip=yes
if %errorlevel% neq 0 (
  echo Error: Build failure target=template_release
  pause
  exit /b %errorlevel%
)

bin\godot.windows.editor.x86_64.exe --headless --path modules\gdtr\standalone --import
if %errorlevel% neq 0 (
  echo Error: Import failure
  pause
  exit /b %errorlevel%
)

mkdir modules\gdtr\standalone\.export
(
echo [preset.0]
echo script_encryption_key="%SCRIPT_AES256_ENCRYPTION_KEY%"
) >> modules\gdtr\standalone\.godot\export_credentials.cfg
bin\godot.windows.editor.x86_64.exe --headless --path modules\gdtr\standalone --export-release "Windows Desktop No Encrypt" .export\gdtr-tools.exe
if %errorlevel% neq 0 (
  echo Error: Export failure
  pause
  exit /b %errorlevel%
)

echo Build successful
