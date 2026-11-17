# Release process

The source repository is private. Public releases live in
`github.com:thinkseek/ummInfer-releases`. That repository contains build
artifacts, documentation and checksums only. It contains no source code and no
model weights.

## Artifacts

One release directory, `dist/<version>/`, contains:

| Path | Content |
| --- | --- |
| `darwin-arm64/umm-infer` | macOS arm64 control plane |
| `linux-x86_64/umm-infer` | Linux x86_64 control plane |
| `linux-x86_64/umm-native-stage-asr` | Qwen3-ASR stage |
| `linux-x86_64/umm-native-stage-omni` | Qwen3-Omni stage |
| `linux-x86_64/umm-native-stage-qwen38` | Qwen3.8-27B stage |
| `linux-x86_64/umm-native-stage-tts` | Qwen3-TTS stage |
| `linux-x86_64/umm-native-stage-image` | Qwen-Image-2512 stage |
| `linux-x86_64/lib/libcurl.so.4` | libcurl 8.5.0 with WebSocket support |
| `SHA256SUMS` | SHA256 of every file above |
| `MANIFEST.md` | source commit, build hosts, commands, file table |

The repository root also has `README.md`, `LICENSE`,
`THIRD_PARTY_NOTICES.md`, `docs/architecture.md`, `docs/models.md`,
`docs/release.md` and `tools/verify.sh`.

## Build hosts

The server builds on macOS or Linux with Zig 0.16.0. The stage binaries need
Linux x86_64 with CUDA 12.4. The publish script builds the stages on a remote
CUDA host when the local host is macOS.

macOS build host:

- Zig 0.16.0
- `brew install zeromq msgpack-c curl libwebsockets`

Linux CUDA build host (reference: H20B, container `linyu-dev`):

- Zig 0.16.0
- CUDA 12.4 toolkit, `cmake` 3.24 or newer
- zmq, msgpack-c, nlohmann-json headers
- libcurl built with WebSocket support
- ICU development package
- `patchelf`

## Publish

Commit the release tooling first. The script archives `main`, so the templates
must be on that branch.

```sh
DEPS_PREFIX=/opt/homebrew \
CURL_PREFIX=/opt/homebrew/opt/curl \
STAGE_SSH=h20b \
STAGE_CONTAINER=linyu-dev \
STAGE_DEPS_PREFIX=/root/umm-c6rt-ckl/deps \
STAGE_CURL_PREFIX=/root/umm-c6rt-ckl/curl-prefix \
STAGE_ZIG=/root/umm-c6rt-ckl/zig/zig \
tools/publish-release.sh v0.2.0
```

Environment variables:

| Variable | Meaning |
| --- | --- |
| `SOURCE_REF` | git ref to build, default `main` |
| `DEPS_PREFIX` | local prefix with zmq, msgpack-c, nlohmann-json |
| `CURL_PREFIX` | local libcurl prefix with WebSocket support |
| `ZIG` | local Zig binary, default `zig` |
| `STAGE_BUILD` | `local` or `remote`, default `auto` |
| `STAGE_SSH` | SSH target of the CUDA build host |
| `STAGE_CONTAINER` | container on that host, optional |
| `STAGE_DEPS_PREFIX` | dependency prefix on the CUDA host |
| `STAGE_CURL_PREFIX` | libcurl prefix on the CUDA host |
| `STAGE_ZIG` | Zig binary on the CUDA host |
| `JOBS` | parallel build jobs, default 8 |
| `RELEASE_REPO` | release repository URL |
| `FORCE` | `1` allows re-use of an existing tag |

The script does these steps:

1. Refuses a dirty working tree.
2. Runs `git archive` on `SOURCE_REF` into a temporary directory.
3. Builds `umm-infer` with `zig build -Doptimize=ReleaseFast`.
4. Builds the five stages from `native/stage_cli` with `-DUMM_STAGE_CUDA=ON`.
5. Sets the Linux server run path to `$ORIGIN/lib` and copies `libcurl.so.4`
   next to it.
6. Writes `SHA256SUMS` and `MANIFEST.md`.
7. Commits the new `dist/<version>/` and documentation to the release
   repository, creates the tag, and pushes both.

Then create the GitHub release page for the tag:

```sh
gh release create v0.2.0 --repo thinkseek/ummInfer-releases \
  --title v0.2.0 --notes-file /tmp/v0.2.0-notes.md
```

Use the release notes to link `dist/v0.2.0/MANIFEST.md`.

## Verify

On a clone of the release repository:

```sh
./tools/verify.sh v0.2.0
```

The script checks every SHA256 value, runs `umm-infer serve --help`, starts
`umm-infer serve --demo`, and sends one chat request. It exits non-zero on a
checksum mismatch or a failed request.

Check the checksums alone:

```sh
cd dist/v0.2.0
sha256sum -c SHA256SUMS   # Linux
shasum -a 256 -c SHA256SUMS  # macOS
```

A real model inference needs a GPU host and a model directory. Start the server
with `--entry` and `--vlm-entry`, then start the ASR stage and one VLM stage.
The commands are in the release repository `README.md`.

## Reproducibility

A rebuild from the same commit produces the same artifact set, but not the
same bytes. Two causes, both measured on the reference hosts:

- The macOS `umm-infer` differs from run to run. The linker writes a new
  Mach-O image UUID on each link.
- The CUDA stage binaries differ from run to run. `nvcc` gives each
  anonymous-namespace kernel symbol a per-compilation suffix, for example
  `_GLOBAL__N__4180a646_15_cuda_kernels_cu_...` and
  `_GLOBAL__N__921bbabd_15_cuda_kernels_cu_...`. Stripping does not remove it;
  the suffix also reaches the fatbin segment.

Reproducibility here means the same source commit, the same commands, and the
same file list. `SHA256SUMS` pins the published bytes. Record the source
commit in `MANIFEST.md`, and keep the build hosts documented above. Do not use
a rebuild hash as an equality test.

## Rollback

A published release is a git commit and a tag in the release repository. To
withdraw it:

1. Add a warning to the release notes and mark the GitHub release as a
   pre-release, or delete the release page.
2. Revert the publish commit on `main`:
   `git revert <commit> && git push origin main`.
3. Move users to the previous tag. Tags are immutable by default; do not
   force-push a tag that users already cloned. Publish a new patch version
   instead.

To rebuild a bad artifact under the same version, run the script with
`FORCE=1`. This deletes and re-creates the local tag and pushes it with
`--force`, so do this before users clone the tag.

Source-side rollback: revert the commit on `main` in the private repository,
then publish a new version from the reverted commit.
