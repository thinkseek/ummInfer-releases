# ummInfer releases

Public build artifacts for ummInfer, an inference runtime for unified
multimodal models. This repository contains binaries, documentation and
checksums only. It does not contain source code or model weights.

The source repository is private. Every artifact here is built from a
recorded source commit. See `dist/<version>/MANIFEST.md`.

## Latest release

`v0.2.0`

## Download

```sh
git clone --depth 1 --branch v0.2.0 \
  https://github.com/thinkseek/ummInfer-releases.git
cd ummInfer-releases
```

Artifacts are stored in `dist/v0.2.0/`:

| Platform | Files |
| --- | --- |
| `darwin-arm64/` | `umm-infer` |
| `linux-x86_64/` | `umm-infer`, `umm-native-stage-{asr,omni,qwen38,tts,image}`, `lib/libcurl.so.4` |

## Verify

One command checks every SHA256 value, runs `--help`, and runs the demo
server with one HTTP request:

```sh
./tools/verify.sh
```

To check only the checksums:

```sh
cd dist/v0.2.0
shasum -a 256 -c SHA256SUMS      # macOS
sha256sum -c SHA256SUMS          # Linux
```

## Requirements

Linux server and stage binaries:

- Ubuntu 24.04 x86_64
- NVIDIA driver with CUDA 12.4 runtime (`libcudart.so.12`)
- `libzmq5`, `libmsgpackc2`, `libwebsockets19t64`, `libicu74`, `zlib1g`
- One model directory per stage (model weights are not distributed here)

macOS server binary:

```sh
brew install zeromq msgpack-c libwebsockets curl
```

The Linux server needs the bundled `lib/libcurl.so.4`; the binary has a
relative `$ORIGIN/lib` run path. Do not move the binary out of its folder.

## Run the server without a model

```sh
./dist/v0.2.0/linux-x86_64/umm-infer serve --demo --model qwen3-native --port 43991
```

`--demo` runs one in-process echo stage. It checks the HTTP and SSE path.
Send a request:

```sh
curl -sS http://127.0.0.1:43991/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3-native","messages":[{"role":"user","content":"hello"}]}'
```

## Run with a model

The server hosts the control plane. Each stage process loads one model on one
GPU. Start the server, then the ASR stage and one VLM stage. The endpoint names
must match.

```sh
IPC=$(mktemp -d /tmp/umminfer.XXXXXX)

dist/v0.2.0/linux-x86_64/umm-infer serve --host 127.0.0.1 --port 43301 \
  --model qwen3-native \
  --entry asr --entry-endpoint "ipc://$IPC/asr" \
  --vlm-entry qwen38 --vlm-entry-endpoint "ipc://$IPC/qwen38" \
  --completion "ipc://$IPC/completion" --abort "ipc://$IPC/abort"

dist/v0.2.0/linux-x86_64/umm-native-stage-asr --kind asr --name asr \
  --model "$ASR_MODEL" --gpu 2 --recv-endpoint "ipc://$IPC/asr" \
  --coordinator-endpoint "ipc://$IPC/completion" \
  --abort-endpoint "ipc://$IPC/abort"

dist/v0.2.0/linux-x86_64/umm-native-stage-qwen38 --kind qwen38 --name qwen38 \
  --model "$QWEN38_MODEL" --gpu 3 --max-new-tokens 96 \
  --recv-endpoint "ipc://$IPC/qwen38" \
  --coordinator-endpoint "ipc://$IPC/completion" \
  --abort-endpoint "ipc://$IPC/abort"
```

`/ready` returns 200 after the entry stage and the VLM stage register.

```sh
curl -sS http://127.0.0.1:43301/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model":"qwen3-native","max_tokens":32,
       "messages":[{"role":"user","content":"What is the sea?"}]}'
```

## Documentation

- `docs/architecture.md` — components and request paths
- `docs/models.md` — supported models, stages and GPU placement
- `docs/release.md` — release process, artifact list, verification, rollback
- `THIRD_PARTY_NOTICES.md` — third-party components and licenses

## License

Apache-2.0. See `LICENSE`.
