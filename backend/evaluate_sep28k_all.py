import csv
import torch
import torch.nn.functional as F

from pathlib import Path
from evaluate_sep28k_reviewed import (
    StutteringClassifier,
    load_clip,
    LABELS,
    CHECKPOINT,
    CLIP_DIR,
)

MANIFEST = CLIP_DIR / "validation_manifest.csv"
OUTPUT = Path("analysis_reports/sep28k_all_results.csv")

THRESHOLD = 2

# Preserve the exact original training order and mapping.
EVENT_COLUMNS = [
    ("Prolongation", "Prolongation"),
    ("Block", "Block"),
    ("SoundRep", "Repetition"),
    ("WordRep", "Repetition"),
    ("Interjection", "Interjection"),
]

QUALITY_FLAGS = [
    "Unsure",
    "PoorAudioQuality",
    "DifficultToUnderstand",
    "Music",
    "NoSpeech",
]


def number(row, column):
    return int(row[column].strip())


def original_training_label(row):
    scores = {}

    for column, label in EVENT_COLUMNS:
        votes = number(row, column)

        if votes >= THRESHOLD:
            scores[label] = max(scores.get(label, 0), votes)

    if scores:
        # Python preserves insertion order for ties,
        # matching the original notebook's behavior.
        best_label = max(scores, key=scores.get)
        return best_label

    if number(row, "NoStutteredWords") >= THRESHOLD:
        return "Fluent"

    return None


def has_quality_flag(row):
    return any(
        number(row, flag) >= THRESHOLD
        for flag in QUALITY_FLAGS
    )


def calculate_metrics(records, title):
    print("\n" + "=" * 72)
    print(title)
    print("=" * 72)

    if not records:
        print("No clips available.")
        return

    total = len(records)
    correct = sum(
        r["true_label"] == r["prediction"]
        for r in records
    )

    print(f"Samples: {total}")
    print(f"Accuracy: {correct / total:.4f} ({correct}/{total})")

    f1_values = []
    weighted_f1 = 0

    print("\nPer-class results:")

    for label in LABELS:
        tp = sum(
            r["true_label"] == label and r["prediction"] == label
            for r in records
        )
        fp = sum(
            r["true_label"] != label and r["prediction"] == label
            for r in records
        )
        fn = sum(
            r["true_label"] == label and r["prediction"] != label
            for r in records
        )

        support = sum(r["true_label"] == label for r in records)

        precision = tp / (tp + fp) if tp + fp else 0
        recall = tp / (tp + fn) if tp + fn else 0
        f1 = (
            2 * precision * recall / (precision + recall)
            if precision + recall else 0
        )

        f1_values.append(f1)
        weighted_f1 += f1 * support

        print(
            f"{label:15s} "
            f"Support={support:3d} "
            f"Precision={precision:.3f} "
            f"Recall={recall:.3f} "
            f"F1={f1:.3f}"
        )

    print(f"\nMacro F1:    {sum(f1_values) / len(LABELS):.4f}")
    print(f"Weighted F1: {weighted_f1 / total:.4f}")


def main():
    if not CHECKPOINT.exists():
        raise FileNotFoundError(CHECKPOINT)

    if not MANIFEST.exists():
        raise FileNotFoundError(MANIFEST)

    with open(MANIFEST, newline="", encoding="utf-8-sig") as f:
        rows = list(csv.DictReader(f))

    device = torch.device(
        "mps" if torch.backends.mps.is_available() else "cpu"
    )

    print("Device:", device)
    print("Manifest clips:", len(rows))
    print("Loading WavLM model...")

    model = StutteringClassifier()

    checkpoint = torch.load(
        CHECKPOINT,
        map_location="cpu",
        weights_only=True
    )

    model.load_state_dict(
        checkpoint["model_state_dict"],
        strict=True
    )

    model.to(device)
    model.eval()

    print("Checkpoint loaded successfully.")
    print("Checkpoint validation F1:", checkpoint["val_f1"])

    results = []
    skipped = []

    with torch.no_grad():
        for index, row in enumerate(rows, start=1):
            filename = row["filename"].strip()
            path = CLIP_DIR / filename

            true_label = original_training_label(row)

            if true_label is None:
                skipped.append((filename, "No qualifying training label"))
                continue

            if not path.exists():
                skipped.append((filename, "Audio file missing"))
                continue

            try:
                waveform = load_clip(path).to(device)
                logits = model(waveform)
                probabilities = F.softmax(logits, dim=1)[0]

                predicted_index = probabilities.argmax().item()
                prediction = LABELS[predicted_index]

                result = {
                    "filename": filename,
                    "true_label": true_label,
                    "prediction": prediction,
                    "correct": prediction == true_label,
                    "quality_flagged": has_quality_flag(row),
                    "quality_flags": ";".join(
                        flag for flag in QUALITY_FLAGS
                        if number(row, flag) >= THRESHOLD
                    ),
                    "event_votes": ";".join(
                        f"{column}={number(row, column)}"
                        for column, _ in EVENT_COLUMNS
                        if number(row, column) >= THRESHOLD
                    ),
                }

                for label, probability in zip(LABELS, probabilities):
                    result[f"prob_{label}"] = round(
                        probability.item(), 6
                    )

                results.append(result)

                print(
                    f"[{index}/{len(rows)}] {filename}: "
                    f"true={true_label}, predicted={prediction}, "
                    f"{'MATCH' if result['correct'] else 'MISMATCH'}"
                )

            except Exception as exc:
                skipped.append((filename, str(exc)))
                print(f"[{index}/{len(rows)}] ERROR {filename}: {exc}")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    if results:
        with open(OUTPUT, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(
                f,
                fieldnames=list(results[0].keys())
            )
            writer.writeheader()
            writer.writerows(results)

    print("\nEvaluated:", len(results))
    print("Skipped:", len(skipped))
    print("Results saved to:", OUTPUT)

    calculate_metrics(
        results,
        "ALL LABELED CLIPS — ORIGINAL TRAINING LABELS"
    )

    clean_results = [
        r for r in results
        if not r["quality_flagged"]
    ]

    calculate_metrics(
        clean_results,
        "QUALITY-FILTERED CLIPS"
    )

    if skipped:
        print("\nSkipped clips:")
        for filename, reason in skipped:
            print(f"  {filename}: {reason}")

    print("\nQuality-flagged clips:")
    flagged = [r for r in results if r["quality_flagged"]]

    if not flagged:
        print("  None")
    else:
        for r in flagged:
            print(
                f"  {r['filename']}: "
                f"{r['quality_flags']} "
                f"(true={r['true_label']}, "
                f"predicted={r['prediction']})"
            )


if __name__ == "__main__":
    main()
