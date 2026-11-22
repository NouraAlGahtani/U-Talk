
import csv
import re
from pathlib import Path

import numpy as np
import soundfile as sf
import torch
import torch.nn.functional as F
from scipy.signal import resample_poly

from evaluate_sep28k_reviewed import (
    StutteringClassifier,
    CHECKPOINT,
    LABELS,
)

AUDIO = Path.home() / "Desktop/download/M_1064_47y0m_1.wav"
WORD_GRID = Path.home() / "Desktop/download/M_1064_47y0m_1.word.grid.txt"
SYLL_GRID = Path.home() / "Desktop/download/M_1064_47y0m_1.syll.grid.txt"

OUT = Path("analysis_reports/uclass")
OUT.mkdir(parents=True, exist_ok=True)

SR = 16000
WINDOW = 3 * SR
HOP = SR


def load_audio(path):
    audio, sr = sf.read(path, dtype="float32", always_2d=False)

    if audio.ndim > 1:
        audio = audio.mean(axis=1)

    if sr != SR:
        divisor = np.gcd(sr, SR)
        audio = resample_poly(
            audio,
            SR // divisor,
            sr // divisor
        ).astype(np.float32)

    return audio


def load_annotations(path):
    text = path.read_text(errors="replace")
    points = re.findall(
        r'^\s*(\d+(?:\.\d+)?)\s+"(.*)"\s*$',
        text,
        re.M
    )

    return [
        (float(t), label)
        for t, label in points
        if label != "TextTier"
    ]


def main():
    if not AUDIO.exists():
        raise FileNotFoundError(AUDIO)

    if not CHECKPOINT.exists():
        raise FileNotFoundError(CHECKPOINT)

    device = torch.device(
        "mps" if torch.backends.mps.is_available() else "cpu"
    )

    print("Loading WavLM architecture...")
    model = StutteringClassifier()

    checkpoint = torch.load(
        CHECKPOINT,
        map_location="cpu",
        weights_only=False
    )

    model.load_state_dict(
        checkpoint["model_state_dict"],
        strict=True
    )

    model.to(device)
    model.eval()

    print("Checkpoint loaded:", CHECKPOINT)
    print("Device:", device)

    audio = load_audio(AUDIO)
    duration = len(audio) / SR

    print(f"Audio duration: {duration:.2f}s")
    print(f"Resampled audio: {SR} Hz")

    results = []

    for start in range(0, len(audio), HOP):
        chunk = audio[start:start + WINDOW]

        if len(chunk) < SR:
            continue

        actual_length = len(chunk)

        if actual_length < WINDOW:
            chunk = np.pad(
                chunk,
                (0, WINDOW - actual_length)
            )

        x = torch.from_numpy(
            np.asarray(chunk, dtype=np.float32)
        ).unsqueeze(0).to(device)

        with torch.inference_mode():
            logits = model(x)
            probs = F.softmax(logits, dim=-1)[0]

        predicted = int(torch.argmax(probs).item())

        row = {
            "start": round(start / SR, 3),
            "end": round((start + actual_length) / SR, 3),
            "prediction": LABELS[predicted],
            "confidence": float(probs[predicted].item()),
        }

        for i, label in enumerate(LABELS):
            row[f"prob_{label}"] = float(probs[i].item())

        results.append(row)

        if len(results) % 50 == 0:
            print(f"Processed {len(results)} windows...")

    prediction_file = OUT / "uclass_window_predictions.csv"

    with prediction_file.open("w", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=results[0].keys()
        )
        writer.writeheader()
        writer.writerows(results)

    for name, path in [
        ("word", WORD_GRID),
        ("syll", SYLL_GRID),
    ]:
        if not path.exists():
            print("Annotation missing:", path)
            continue

        points = load_annotations(path)
        annotation_file = OUT / f"uclass_{name}_annotations.csv"

        with annotation_file.open("w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["timestamp", "annotation"])
            writer.writerows(points)

        print(f"{name} annotation points:", len(points))
        print("Saved:", annotation_file)

    print("\nEvaluation complete.")
    print("Windows:", len(results))
    print("Duration:", round(duration, 2), "seconds")
    print("Predictions:", prediction_file)
    print("Mean model probabilities:")

    for label in LABELS:
        mean = np.mean([
            row[f"prob_{label}"] for row in results
        ])
        print(f"{label}: {mean:.2%}")


if __name__ == "__main__":
    main()

