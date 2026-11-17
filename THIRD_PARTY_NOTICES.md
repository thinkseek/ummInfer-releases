# Third-party notices

The ummInfer binaries link the components below. The components are not
modified. License texts are in each component's own distribution.

| Component | Version | License | Linked by |
| --- | --- | --- | --- |
| cpp-httplib | 0.65.0 Linux, 0.66.0 macOS | MIT | server (header only) |
| nlohmann/json | 3.11.3 Linux, 3.12.0 macOS | MIT | server, stages (header only) |
| ZeroMQ (libzmq) | 4.3.5 | MPL-2.0 | server, stages |
| msgpack-c (libmsgpackc) | 4.0.0 Linux, 7.0.2 macOS | BSL-1.0 | server, stages |
| libwebsockets | 4.3.3 Linux, 5.1.0 macOS | MIT | server |
| curl (libcurl) | 8.5.0 bundled on Linux, 8.23.0 macOS | curl | server |
| ICU (libicuuc, libicui18n) | 74.2 | Unicode-3.0 | TTS stage |
| zlib | 1.3 Linux, 1.4 macOS | Zlib | server, image stage |
| NVIDIA CUDA Runtime | 12.4 | NVIDIA CUDA Toolkit EULA | stages |

## Runtime-only components

These are required on the host and are not distributed here:

- NVIDIA display driver and `libcudart.so.12` — NVIDIA driver license
- `libzmq5`, `libmsgpackc2`, `libwebsockets19t64`, `libicu74`, `zlib1g` —
  Debian and Ubuntu package licenses
- Model weights — each model keeps its own license. Model weights are not
  distributed in this repository.

## Bundled files

`dist/*/linux-x86_64/lib/libcurl.so.4` is a libcurl 8.5.0 shared library with
WebSocket support. The Ubuntu 24.04 system libcurl does not include the
WebSocket API. The server needs that API for the realtime client. The curl
license permits redistribution.
