# ummInfer releases

This repository publishes ummInfer binaries, release notes and SHA256
checksums. Source code is kept in a private repository.

## Download

Use the Releases page. Every release asset has a matching entry in
`SHA256SUMS`.

## Verify

```sh
shasum -a 256 -c SHA256SUMS
```

## Status

No release has been published yet. The first release will be created only
after a build passes the project's real-device acceptance gate.
