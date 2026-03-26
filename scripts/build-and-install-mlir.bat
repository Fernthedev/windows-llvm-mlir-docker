@echo off
REM Build and install LLVM/MLIR tools on Windows (Visual Studio Build Tools)
REM Usage: run from an elevated Developer Command Prompt or regular shell after calling vcvarsall.bat

REM 1) Ensure Visual Studio environment is set up (adjust path if Build Tools installed elsewhere)
dir "C:\"
dir "C:\BuildTools\"

call "C:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
IF ERRORLEVEL 1 (
  echo Failed to set Visual Studio environment.
  EXIT /B 1
)

REM 2) Expect `llvm-project` as a git submodule in repository root
if not exist llvm-project (
  echo Submodule 'llvm-project' not found.
  echo Initialize it locally with:
  echo   git submodule update --init --recursive
  echo Then re-run this script.
  EXIT /B 1
)

REM 3) Configure build
if exist llvm-project\build (
  rd /s /q llvm-project\build
) 
@echo off
setlocal

REM build-and-install-mlir.bat
REM Purpose: configure, build, and install LLVM/MLIR from a local `llvm-project` source tree.
REM Usage: run inside a Windows environment with Visual Studio Build Tools available.
REM        The Docker builder copies `llvm-project` into the image and calls this script.

REM Configurable variables
set "SRC_DIR=C:\llvm-project"
set "BUILD_DIR=%SRC_DIR%\build"
set "INSTALL_PREFIX=C:\mlir-install"

REM Initialise Visual Studio environment if available (no-op otherwise)
@REM if exist "C:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" (
@REM   call "C:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64 || exit /b %errorlevel%
@REM ) else (
@REM   echo WARNING: vcvarsall.bat not found; continuing without VS env
@REM   EXIT /B 1
@REM )

REM Ensure source is present (we expect a checked-out submodule at %SRC_DIR%)
if not exist "%SRC_DIR%" (
  echo ERROR: Source not found at %SRC_DIR%
  echo Run: git submodule update --init --recursive
  exit /b 1
)

REM Prepare build directory
if exist "%BUILD_DIR%" rd /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%"
pushd "%BUILD_DIR%"

REM CMake generator can be provided via environment variable CMAKE_GENERATOR
if not defined CMAKE_GENERATOR set "CMAKE_GENERATOR=Visual Studio 17 2022"
echo Using CMAKE_GENERATOR=%CMAKE_GENERATOR%

REM Configure, build (validate with check-mlir), and install
cmake ..\llvm -G "%CMAKE_GENERATOR%" -A x64 -DLLVM_ENABLE_PROJECTS=mlir -DLLVM_BUILD_EXAMPLES=ON -DLLVM_TARGETS_TO_BUILD=Native -DCMAKE_INSTALL_PREFIX="%INSTALL_PREFIX%" -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=ON -Thost=x64 || (popd & exit /b %errorlevel%)

cmake --build . --config Release --target tools/mlir/test/check-mlir || (popd & exit /b %errorlevel%)
cmake --build . --config Release --target install || (popd & exit /b %errorlevel%)

echo Installed to %INSTALL_PREFIX%
popd
endlocal
exit /b 0
)
