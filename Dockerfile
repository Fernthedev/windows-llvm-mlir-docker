# Stage 1: Install Visual Studio Build Tools
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS vs-buildtools
SHELL ["cmd", "/S", "/C"]
RUN mkdir C:\TEMP

ADD https://aka.ms/vscollect.exe C:\\TEMP\\collect.exe
ADD https://aka.ms/vs/17/release/vs_buildtools.exe C:\\TEMP\\vs_buildtools.exe
RUN C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache \
    --installPath "C:\BuildTools" \
    --add Microsoft.VisualStudio.Workload.VCTools \
    --add Microsoft.Component.MSBuild \
    --add Microsoft.VisualStudio.Component.VC.CMake.Project \
    --add Microsoft.VisualStudio.Component.VC.CoreIde \
    --add Microsoft.VisualStudio.Component.VC.Llvm.Clang \
    --add Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset \
    --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest \
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 \
    --add Microsoft.VisualStudio.Component.Vcpkg \
    --add Microsoft.VisualStudio.Component.Windows11SDK.26100 \
    --add Microsoft.VisualStudio.Component.VC.ATLMFC \
    --add Microsoft.VisualStudio.Component.VC.ATL \
    --add Microsoft.VisualStudio.Workload.Python \
    --add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core \
    --add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Llvm.Clang \
    --add Microsoft.VisualStudio.Workload.NativeDesktop \
    --add Microsoft.VisualStudio.Component.Git \
    --includeRecommended \
    || IF "%ERRORLEVEL%"=="3010" EXIT 0

RUN dir C:
RUN dir C:\BuildTools
RUN dir C:\TEMP
RUN type C:\TEMP\dd_vs_buildtools*.log || echo "No log found"

# Stage 2: Build MLIR
FROM vs-buildtools AS build-mlir
SHELL ["cmd", "/S", "/C"]

ARG CMAKE_GENERATOR="Visual Studio 17 2022"
ENV CMAKE_GENERATOR=${CMAKE_GENERATOR}

COPY scripts/build-and-install-mlir.bat C:/BuildTools/build-and-install-mlir.bat
COPY llvm-project C:/llvm-project

ADD https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe C:\\TEMP\\python-installer.exe
# Install Python system-wide, add to PATH
RUN C:\TEMP\python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0

# Verify
RUN python --version || true

# VsDevCmd sets up MSVC + Python (from Workload.Python) in one call
RUN "C:\BuildTools\Common7\Tools\VsDevCmd.bat" -arch=amd64 && \
    C:\BuildTools\build-and-install-mlir.bat

# Stage 3: Final dev image
FROM vs-buildtools AS dev
SHELL ["cmd", "/S", "/C"]

COPY --from=build-mlir C:/mlir-install C:/mlir-install
# COPY scripts/entrypoint-vcvars.bat C:/init-vcvars.bat

ENV PATH="C:\mlir-install\bin;%PATH%"

ENTRYPOINT ["C:\\BuildTools\\Common7\\Tools\\VsDevCmd.bat", "-arch=amd64", "&&", "powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
CMD ["cmd"]