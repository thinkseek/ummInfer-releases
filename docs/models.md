# Models

ummInfer does not distribute model weights. Each stage reads a model directory
in Hugging Face safetensors layout. The operator supplies the directory with
`--model`.

## Supported models

Measured on H20B, BF16, greedy decoding, one request in flight.

| Model | Stage binary | GPU | Measured |
| --- | --- | --- | --- |
| Qwen3-ASR 0.6B | `umm-native-stage-asr` | 2 | 15.05 s clip to 46 tokens in about 1.0 s after a 4.8 s model load |
| Qwen3.8-27B | `umm-native-stage-qwen38` | 3 | text: 0.16 s prefill, 42.0 tok/s; 512x512 image: 1.05 s prefill, 29.2 tok/s |
| Qwen3-Omni thinker (MoE, 57.87 GiB) | `umm-native-stage-omni` | 3 | vision 0.363 s, prefill 0.231 s, decode 30.6 tok/s |
| Qwen3-TTS 0.6B CustomVoice | `umm-native-stage-tts` | 5 | 4.24 s speech in 7.2 s |
| Qwen-Image-2512 | `umm-native-stage-image` | 4 | 512x512, 50 steps: 228.8 s |

Qwen3.8-27B is the default VLM stage. It has a text decoder and a vision tower
but no audio tower. The stage rejects audio parts, video parts, more than one
image, `http(s)` image URLs, and `modalities` that contain `audio`. The error
names the rejected field.

ASR, Omni and TTS output is greedy and deterministic.

## Model directory layout

Each model directory must contain `config.json`, the tokenizer files, and the
safetensors shards. The stage reads the index and maps the shards. No
conversion step is required.

## GPU placement

Assign one GPU per stage process with `--gpu`. The reference layout uses GPU 2
for ASR, GPU 3 for the VLM leg, GPU 4 for image, GPU 5 for TTS. Qwen3.8-27B
needs about 51 GiB of device memory. Check `nvidia-smi` before you start a
stage.

Only one VLM stage may run at a time. Use either `qwen38` or `omni`, not both.
