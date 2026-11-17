# Release v0.2.0

- Source commit: `3b708e178e52f9c9fbe6aad5a6e2880ccab267d9` (branch `feat/release`)
- Published: 2026-11-17T10:24:33Z
- Server build host: Darwin-arm64, Zig 0.16.0
- Stage build host: h20b (container linyu-dev), CUDA 12.4

## Build commands

```sh
git archive 3b708e178e52f9c9fbe6aad5a6e2880ccab267d9 | tar -x -C src && cd src
zig build -Doptimize=ReleaseFast -Ddeps-prefix=$DEPS_PREFIX -Dcurl-prefix=$CURL_PREFIX
cmake -S native/stage_cli -B build -DUMM_STAGE_CUDA=ON -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=$DEPS_PREFIX
cmake --build build -j 8
```

## Files

| File | Bytes | SHA256 |
| --- | ---: | --- |
| `darwin-arm64/umm-infer` | 3411592 | `d0ca42c20d7e6a866b50491cb62fd1985dbe2c0f5f86dd5635c0069ce824acd2` |
| `linux-x86_64/lib/libcurl.so.4` | 747912 | `f79bdaeb5164abf02fa5586912b90f35269c21afc76963854a1074cd22e48b91` |
| `linux-x86_64/umm-infer` | 36888392 | `a77970218193f22d2e9a16e9af30992310bb886e9625be0652419b6fbf4ffb02` |
| `linux-x86_64/umm-native-stage-asr` | 1416760 | `26ebc2881d709965ebc159c61571a7668071a2aa562c97d994d515057966fd99` |
| `linux-x86_64/umm-native-stage-image` | 1550760 | `3cdd263844078570ed301b4c8e9132fb471988989684a1bfea5a7cf7f9b5f598` |
| `linux-x86_64/umm-native-stage-omni` | 1879752 | `5f49dcf7fa0e47de87e7ebb80babd92add4b3c4195392ab2890ef23da40bef3f` |
| `linux-x86_64/umm-native-stage-qwen38` | 1787544 | `80096d0a0cfd3ae41ab01c9c752e30fe5a3b3ab3d363119a562edb7d2a218f67` |
| `linux-x86_64/umm-native-stage-tts` | 1697240 | `a80241bbd6903d886566c8f9392ee142cab5d367d85d44d7c0d29ae8113eaa42` |

## Reproducibility

A rebuild from the same commit produces the same artifact set, not the
same bytes. The macOS binary embeds a per-run linker UUID, and nvcc gives
each anonymous-namespace kernel symbol a per-compilation suffix. The
input commit, build commands and file list are reproducible; these
SHA256 values pin the published bytes.
