import torch
import torch.nn as nn
import torch.nn.functional as F

from transformers import WavLMConfig, WavLMModel
from peft import LoraConfig, get_peft_model

CHECKPOINT_PATH = "models/stuttering/best_model_wavlm_lora.pt"
MODEL_NAME = "microsoft/wavlm-base-plus"

LABELS = [
    "Prolongation",
    "Repetition",
    "Block",
    "Interjection",
    "Fluent"
]

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
            weights * (x - mean.unsqueeze(1)) ** 2,
            dim=1
        )
        std = torch.sqrt(variance.clamp(min=1e-8))
        return torch.cat([mean, std], dim=1)


class WavLMLoRAClassifier(nn.Module):
    def __init__(self):
        super().__init__()

        config = WavLMConfig.from_pretrained(MODEL_NAME)
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
        outputs = self.wavlm(input_values)
        features = outputs.last_hidden_state
        pooled = self.pooling(features)
        return self.classifier(pooled)


device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
print("Using device:", device)

print("Building model...")
model = WavLMLoRAClassifier()

print("Loading checkpoint...")
checkpoint = torch.load(
    CHECKPOINT_PATH,
    map_location="cpu",
    weights_only=True
)

result = model.load_state_dict(
    checkpoint["model_state_dict"],
    strict=True
)

print("Checkpoint loaded:", result)
print("Training epoch:", checkpoint["epoch"])
print("Validation F1:", checkpoint["val_f1"])

model = model.to(device)
model.eval()

print("Testing 3-second input...")
dummy_audio = torch.zeros(1, 48000, device=device)

with torch.no_grad():
    logits = model(dummy_audio)
    probabilities = F.softmax(logits, dim=1)

print("Output shape:", logits.shape)
print("Predictions:")
for label, probability in zip(LABELS, probabilities[0].cpu().tolist()):
    print(f"  {label}: {probability:.4f}")

print("\nMODEL LOAD AND INFERENCE TEST PASSED")
