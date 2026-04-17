@echo off
setlocal

REM build-and-install-mlir.bat
REM Assumes VS environment is already initialised by the caller (VsDevCmd.bat).

set "SRC_DIR=C:\llvm-project"
set "BUILD_DIR=%SRC_DIR%\build"
set "INSTALL_PREFIX=C:\mlir-install"

if not exist "%SRC_DIR%" (
    echo ERROR: Source not found at %SRC_DIR%
    exit /b 1
)

if exist "%BUILD_DIR%" rd /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%"
pushd "%BUILD_DIR%"

if not defined CMAKE_GENERATOR set "CMAKE_GENERATOR=Visual Studio 17 2022"
echo Using CMAKE_GENERATOR=%CMAKE_GENERATOR%

cmake ..\llvm ^
    -G "%CMAKE_GENERATOR%" ^
    -A x64 ^
    -Thost=x64 ^
    -DLLVM_ENABLE_PROJECTS=mlir ^
    -DLLVM_BUILD_EXAMPLES=ON ^
    -DLLVM_TARGETS_TO_BUILD=Native ^
    -DCMAKE_INSTALL_PREFIX="%INSTALL_PREFIX%" ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DLLVM_ENABLE_ASSERTIONS=ON ^
    || (popd & exit /b %errorlevel%)

cmake --build . --config Release --target tools/mlir/test/check-mlir ^
    || (popd & exit /b %errorlevel%)

cmake --build . --config Release --target install ^
    || (popd & exit /b %errorlevel%)

echo Installed to %INSTALL_PREFIX%
popd
endlocal
exit /b 0