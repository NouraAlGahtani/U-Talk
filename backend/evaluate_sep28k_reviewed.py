import torch
import torch.nn as nn
import soundfile as sf
import numpy as np

from pathlib import Path
from transformers import AutoModel
from peft import LoraConfig, TaskType, get_peft_model

CHECKPOINT = Path("models/stuttering/best_model_wavlm_lora.pt")
CLIP_DIR = Path("datasets/sep28k/validation_clips")

LABELS = [
    "Prolongation",
    "Repetition",
    "Block",
    "Interjection",
    "Fluent"
]

REVIEWED_CLIPS = {
    "StutterTalk_62_Clip24.wav": {
        "dataset": "SoundRep=2",
        "human": "Unclear/gibberish; unreliable"
    },
    "StutterTalk_62_Clip30.wav": {
        "dataset": "Prolongation=3, WordRep=2",
        "human": "Prolonged sounds heard"
    },
    "StutterTalk_62_Clip1.wav": {
        "dataset": "Block=3",
        "human": "Normal speech then stopped; block not confirmed"
    },
    "StutterTalk_62_Clip10.wav": {
        "dataset": "Interjection=3",
        "human": "Fillers heard"
    },
    "StutterTalk_62_Clip34.wav": {
        "dataset": "WordRep=3, Interjection=3",
        "human": "Repeated words heard"
    }
}


class AttentiveStatsPooling(nn.Module):
    def __init__(self, hidden_size=768):
        super().__init__()
        self.attention = nn.Sequential(
            nn.Linear(hidden_size, 192),
            nn.Tanh(),
            nn.Linear(192, 1)
        )

    def forward(self, x):
        weights = torch.softmax(self.attention(x), dim=1)

        mean = torch.sum(weights * x, dim=1)
        variance = torch.sum(
            weights * (x - mean.unsqueeze(1)) ** 2,
            dim=1
        )
        std = torch.sqrt(variance + 1e-9)

        return torch.cat([mean, std], dim=1)


class StutteringClassifier(nn.Module):
    def __init__(self):
        super().__init__()

        base_model = AutoModel.from_pretrained(
            "microsoft/wavlm-base-plus"
        )

        lora_config = LoraConfig(
            task_type=TaskType.FEATURE_EXTRACTION,
            r=8,
            lora_alpha=16,
            lora_dropout=0.1,
            target_modules=["q_proj", "v_proj"],
            bias="none"
        )

        self.wavlm = get_peft_model(base_model, lora_config)
        self.pooling = AttentiveStatsPooling(768)

        self.classifier = nn.Sequential(
            nn.Linear(1536, 256),
            nn.GELU(),
            nn.LayerNorm(256),
            nn.Dropout(0.2),
            nn.Linear(256, 5)
        )

    def forward(self, input_values):
        features = self.wavlm(
            input_values=input_values
        ).last_hidden_state

        pooled = self.pooling(features)
        return self.classifier(pooled)


def load_clip(path):
    audio, sr = sf.read(path, dtype="float32")

    if audio.ndim > 1:
        audio = audio.mean(axis=1)

    if sr != 16000:
        raise ValueError(f"{path.name}: expected 16000 Hz, got {sr}")

    target_length = 48000

    if len(audio) < target_length:
        audio = np.pad(audio, (0, target_length - len(audio)))
    else:
        audio = audio[:target_length]

    return torch.from_numpy(audio).unsqueeze(0)


def main():
    if not CHECKPOINT.exists():
        raise FileNotFoundError(CHECKPOINT)

    device = torch.device(
        "mps" if torch.backends.mps.is_available() else "cpu"
    )

    print("Device:", device)
    print("Loading WavLM model...")

    model = StutteringClassifier()

    checkpoint = torch.load(
        CHECKPOINT,
        map_location="cpu",
        weights_only=True
    )

    result = model.load_state_dict(
        checkpoint["model_state_dict"],
        strict=True
    )

    print("Checkpoint loaded:", result)
    model.to(device)
    model.eval()

    print("\nModel validation F1:", checkpoint["val_f1"])
    print("\n" + "=" * 65)
    print("SEP-28k MANUALLY REVIEWED CLIP EVALUATION")
    print("=" * 65)

    with torch.no_grad():
        for filename, review in REVIEWED_CLIPS.items():
            path = CLIP_DIR / filename

            if not path.exists():
                print(f"\nMissing clip: {path}")
                continue

            waveform = load_clip(path).to(device)

            logits = model(waveform)
            probabilities = torch.softmax(logits, dim=1)[0]

            predicted_index = probabilities.argmax().item()

            print(f"\nClip: {filename}")
            print("Dataset:", review["dataset"])
            print("Human review:", review["human"])
            print("AI prediction:", LABELS[predicted_index])

            print("Probabilities:")
            for label, probability in zip(LABELS, probabilities):
                print(f"  {label:15s}: {probability.item() * 100:.2f}%")

            print("-" * 65)


if __name__ == "__main__":
    main()
