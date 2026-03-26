
# Stage 1: Install Visual Studio Build Tools
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS vs-buildtools
SHELL ["cmd", "/S", "/C"]
RUN mkdir C:\TEMP
ADD https://aka.ms/vs/17/release/vs_buildtools.exe C:\\TEMP\\vs_buildtools.exe

RUN C:\TEMP\vs_buildtools.exe --wait --norestart --nocache \
    --installPath "C:\BuildTools" \
    --add Microsoft.VisualStudio.Workload.VCTools \
    --add Microsoft.Component.MSBuild \
    --add Microsoft.VisualStudio.Component.CoreEditor \
    --add Microsoft.VisualStudio.Component.DiagnosticTools \
    --add Microsoft.VisualStudio.Component.Roslyn.Compiler \
    --add Microsoft.VisualStudio.Component.TextTemplating \
    --add Microsoft.VisualStudio.Component.VC.CMake.Project \
    --add Microsoft.VisualStudio.Component.VC.CoreIde \
    --add Microsoft.VisualStudio.Component.VC.Llvm.Clang \
    --add Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset \
    --add Microsoft.VisualStudio.Component.VC.Redist.14.Latest \
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 \
    --add Microsoft.VisualStudio.Component.Vcpkg \
    --add Microsoft.VisualStudio.Component.Windows11SDK.26100 \
    --add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core \
    --add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Llvm.Clang \
    --add Microsoft.VisualStudio.Workload.CoreEditor \
    --add Microsoft.VisualStudio.Workload.NativeDesktop \
    --add Microsoft.VisualStudio.Component.Git \
    --includeRecommended \
    || IF "%ERRORLEVEL%"=="3010" EXIT 0

# Stage 2: Build MLIR (and optionally clang)
FROM vs-buildtools AS build-mlir
SHELL ["cmd", "/S", "/C"]
ARG CMAKE_GENERATOR="Visual Studio 17 2022"
ENV CMAKE_GENERATOR=${CMAKE_GENERATOR}
# Copy only what is needed for the build
COPY scripts/build-and-install-mlir.bat C:/BuildTools/build-and-install-mlir.bat
COPY llvm-project C:/llvm-project
RUN C:\BuildTools\build-and-install-mlir.bat

# Stage 3: Final dev image with only VS Build Tools and MLIR install
FROM vs-buildtools AS dev
SHELL ["cmd", "/S", "/C"]
# Copy only the installed MLIR tools/binaries
COPY --from=build-mlir C:/mlir-install C:/mlir-install
COPY scripts/entrypoint-vcvars.bat C:/init-vcvars.bat
ENV PATH="C:\mlir-install\bin;%PATH%"
ENTRYPOINT ["C:\\init-vcvars.bat"]
CMD ["cmd"]
