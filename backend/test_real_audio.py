import wave
import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
import torchaudio

from transformers import WavLMConfig, WavLMModel
from peft import LoraConfig, get_peft_model

AUDIO_PATH = "andrew_test.wav"
CHECKPOINT_PATH = "models/stuttering/best_model_wavlm_lora.pt"

LABELS = [
    "Prolongation",
    "Repetition",
    "Block",
    "Interjection",
    "Fluent"
]

def read_wav(path):
    with wave.open(path, "rb") as wav:
        channels = wav.getnchannels()
        sample_rate = wav.getframerate()
        width = wav.getsampwidth()
        frames = wav.readframes(wav.getnframes())

    if width == 1:
        audio = (np.frombuffer(frames, dtype=np.uint8).astype(np.float32) - 128) / 128
    elif width == 2:
        audio = np.frombuffer(frames, dtype="<i2").astype(np.float32) / 32768
    elif width == 3:
        raw = np.frombuffer(frames, dtype=np.uint8).reshape(-1, 3)
        values = (
            raw[:, 0].astype(np.int32)
            | (raw[:, 1].astype(np.int32) << 8)
            | (raw[:, 2].astype(np.int32) << 16)
        )
        values = np.where(values & 0x800000, values - 0x1000000, values)
        audio = values.astype(np.float32) / 8388608
    elif width == 4:
        audio = np.frombuffer(frames, dtype="<i4").astype(np.float32) / 2147483648
    else:
        raise ValueError(f"Unsupported WAV sample width: {width} bytes")

    audio = audio.reshape(-1, channels).T
    return torch.from_numpy(audio.copy()), sample_rate


class AttentiveStatisticsPooling(nn.Module):
    def __init__(self, input_dim):
        super().__init__()
        self.attention = nn.Sequential(
            nn.Linear(input_dim, input_dim // 4),
            nn.Tanh(),
            nn.Linear(input_dim // 4, 1)
        )

    def forward(self, x):
        weights = F.softmax(self.attention(x), dim=1)
        mean = torch.sum(x * weights, dim=1)
        variance = torch.sum(
            weights * (x - mean.unsqueeze(1)) ** 2, dim=1
        )
        std = torch.sqrt(variance.clamp(min=1e-8))
        return torch.cat([mean, std], dim=1)


class WavLMLoRAClassifier(nn.Module):
    def __init__(self):
        super().__init__()
        config = WavLMConfig.from_pretrained("microsoft/wavlm-base-plus")
        wavlm = WavLMModel(config)

        lora_config = LoraConfig(
            r=8,
            lora_alpha=16,
            lora_dropout=0.1,
            target_modules=["q_proj", "v_proj"],
            bias="none"
        )

        self.wavlm = get_peft_model(wavlm, lora_config)
        self.pooling = AttentiveStatisticsPooling(config.hidden_size)
        self.classifier = nn.Sequential(
            nn.Linear(config.hidden_size * 2, 256),
            nn.GELU(),
            nn.LayerNorm(256),
            nn.Dropout(0.2),
            nn.Linear(256, 5)
        )

    def forward(self, input_values):
        features = self.wavlm(input_values).last_hidden_state
        return self.classifier(self.pooling(features))


print("Reading WAV...")
waveform, sample_rate = read_wav(AUDIO_PATH)
print("Original sample rate:", sample_rate)
print("Original audio shape:", waveform.shape)

# Convert stereo to mono
if waveform.shape[0] > 1:
    waveform = waveform.mean(dim=0, keepdim=True)

# Resample to 16 kHz
if sample_rate != 16000:
    waveform = torchaudio.functional.resample(
        waveform, orig_freq=sample_rate, new_freq=16000
    )

waveform = waveform.squeeze(0)

# Match the model's exact 3-second input
if waveform.shape[0] < 48000:
    waveform = F.pad(waveform, (0, 48000 - waveform.shape[0]))
else:
    waveform = waveform[:48000]

device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
waveform = waveform.unsqueeze(0).to(device)

print("Prepared input:", waveform.shape)
print("Loading classifier...")

model = WavLMLoRAClassifier()
checkpoint = torch.load(
    CHECKPOINT_PATH, map_location="cpu", weights_only=True
)
model.load_state_dict(checkpoint["model_state_dict"], strict=True)
model = model.to(device)
model.eval()

print("Running inference...")
with torch.no_grad():
    logits = model(waveform)
    probabilities = F.softmax(logits, dim=1)[0].cpu()

print("\nREAL AUDIO RESULTS")
print("-" * 35)

for label, probability in zip(LABELS, probabilities.tolist()):
    print(f"{label:15}: {probability:.4f} ({probability * 100:.2f}%)")

print("\nPredicted class:", LABELS[probabilities.argmax().item()])
print("INFERENCE COMPLETED")
