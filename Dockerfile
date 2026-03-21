# Multi-stage Dockerfile for building LLVM/MLIR (builder) and producing images
#
# Targets:
#  - default (dev): image with both MLIR installed and Visual Studio C++ Build Tools
#    build default (dev): `docker build -t mlir-windows .`  # produces dev image
#  - runtime: small image with only installed MLIR artifacts in C:\mlir-install
#    build runtime only: `docker build --target runtime -t mlir-windows:runtime .`
#
# Build args:
#  - CMAKE_GENERATOR: override the Visual Studio CMake generator (default: "Visual Studio 17 2022")
#    example: `docker build --build-arg CMAKE_GENERATOR="Visual Studio 15 2017 Win64" .`

# Builder stage: install VS Build Tools, clone and build LLVM/MLIR
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS builder

SHELL ["cmd", "/S", "/C"]

ARG CMAKE_GENERATOR="Visual Studio 17 2022"
ENV CMAKE_GENERATOR=${CMAKE_GENERATOR}

RUN mkdir C:\\TEMP

# download VS Build Tools bootstrapper
ADD https://aka.ms/vs/17/release/vs_buildtools.exe C:\\TEMP\\vs_buildtools.exe

RUN C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache \
    --installPath "C:\BuildTools" \
    --add Microsoft.VisualStudio.Workload.VCTools \
    --add Microsoft.Component.MSBuild \
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 \
    --add Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset \
    --add Microsoft.VisualStudio.Component.VC.CMake.Project \
    --add Microsoft.VisualStudio.Component.Git \
    --add Microsoft.VisualStudio.Component.Windows11SDK.26100 \
    --includeRecommended \
    || IF "%ERRORLEVEL%"=="3010" EXIT 0

# Cleanup
# RUN del C:\TEMP\vs_buildtools.exe

# copy build helper script into the builder image (use forward slashes for build context)
COPY scripts/build-and-install-mlir.bat C:/BuildTools/build-and-install-mlir.bat

# Copy pre-populated llvm-project submodule into image (must be initialized locally)
COPY llvm-project C:/llvm-project

# Run the helper script to clone, build, and install MLIR into C:\mlir-install
RUN C:\BuildTools\build-and-install-mlir.bat

COPY scripts/entrypoint-vcvars.bat C:/init-vcvars.bat
ENTRYPOINT ["C:\\\\init-vcvars.bat"]
CMD ["cmd"]


# # Runtime stage: keep only the installed artifacts
# FROM mcr.microsoft.com/windows/nanoserver:ltsc2022 AS runtime

# SHELL ["cmd", "/S", "/C"]

# # Copy installed MLIR artifacts from the builder stage
# COPY --from=builder C:/mlir-install C:/mlir-install

# # Add mlir tools to PATH
# ENV PATH="C:\mlir-install\bin;%PATH%"

# CMD ["cmd", "/S", "/C", "echo MLIR runtime image ready. Use C:\\mlir-install\\bin\\mlir-* tools."]

# # Dev image: includes both MLIR install and the C++ Build Tools for development/testing.
# # Use this target when you want the build environment present inside the image.
# FROM builder AS dev

# SHELL ["cmd", "/S", "/C"]

# # Copy build tools and mlir install from builder
# # COPY --from=builder C:/BuildTools C:/BuildTools
# COPY --from=builder C:/mlir-install C:/mlir-install

# ENV PATH="C:\\mlir-install\\bin;%PATH%"

# # Add entrypoint that initialises VS vars then launches the requested command (or cmd)
# COPY scripts/entrypoint-vcvars.bat C:/init-vcvars.bat
# ENTRYPOINT ["C:\\\\init-vcvars.bat"]
# CMD ["cmd"]
