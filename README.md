# VS + MLIR Windows Docker
This is a docker container that provides VS 2022 build tools and MLIR tools.

# Usage:
```sh
docker pull ghcr.io/Fernthedev/vs-mlir-windows:latest
```

```dockerfile
# Dockerfile — extend the published MLIR runtime image
FROM ghcr.io/Fernthedev/vs-mlir-windows:latest

SHELL ["cmd", "/S", "/C"]

# copy a local MLIR file into the image
COPY hello.mlir C:\\workspace\\hello.mlir

# run mlir-opt by default on the copied file
ENTRYPOINT ["C:\\mlir-install\\bin\\mlir-opt.exe", "C:\\workspace\\hello.mlir"]
```

```sh
docker run --rm -v "$(pwd)/hello.mlir":C:/workspace/hello.mlir --platform=windows/amd64 ghcr.io/Fernthedev/vs-mlir-windows:latest C:\\mlir-install\\bin\\mlir-opt.exe C:\\workspace\\hello.mlir
```