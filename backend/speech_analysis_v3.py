
import json
import re
from pathlib import Path
from collections import Counter

import numpy as np
import soundfile as sf
import mlx_whisper

import torch
import torch.nn as nn
import torch.nn.functional as F

from transformers import WavLMConfig, WavLMModel
from peft import LoraConfig, get_peft_model


# ============================================================
# CONFIGURATION
# ============================================================

SAMPLE_RATE = 16000
WHISPER_MODEL = "mlx-community/whisper-small-mlx"

AUDIO_FILES = ["test2.wav", "test3.wav"]

CHECKPOINT_PATH = Path(
    "models/stuttering/best_model_wavlm_lora.pt"
)

REPORT_DIR = Path("analysis_reports/v3")

WINDOW_SECONDS = 3
HOP_SECONDS = 1

LABELS = [
    "Prolongation",
    "Repetition",
    "Block",
    "Interjection",
    "Fluent"
]

FILLERS = [
    "you know",
    "i mean",
    "um",
    "uh",
    "erm",
    "ah",
    "hmm",
    "like",
    "basically",
    "actually",
    "well",
    "so"
]


# ============================================================
# AUDIO LOADING
# ============================================================

def load_audio(path):
    audio, sample_rate = sf.read(
        str(path),
        dtype="float32",
        always_2d=False
    )

    if audio.ndim > 1:
        audio = audio.mean(axis=1)

    if sample_rate != SAMPLE_RATE:
        raise ValueError(
            f"{path}: expected {SAMPLE_RATE} Hz, "
            f"got {sample_rate} Hz"
        )

    duration = len(audio) / sample_rate

    print(f"Loaded: {path}")
    print(f"Duration: {duration:.2f} seconds")

    return audio, duration


# ============================================================
# WHISPER TRANSCRIPTION
# ============================================================

def transcribe_audio(path):
    print("\nTranscribing audio...")

    result = mlx_whisper.transcribe(
        str(path),
        path_or_hf_repo=WHISPER_MODEL,
        language="en",
        condition_on_previous_text=False
    )

    transcript = result.get("text", "").strip()

    segments = []

    for segment in result.get("segments", []):
        segments.append({
            "start": round(segment["start"], 2),
            "end": round(segment["end"], 2),
            "text": segment["text"].strip()
        })

    return transcript, segments


# ============================================================
# TEXT ANALYSIS
# ============================================================

def assess_transcript_quality(transcript):
    non_latin_letters = [
        char for char in transcript
        if char.isalpha() and not ("A" <= char <= "Z" or "a" <= char <= "z")
    ]

    warnings = []

    if non_latin_letters:
        warnings.append(
            "Transcript contains non-Latin characters; English word metrics "
            "may be unreliable."
        )

    return {
        "contains_non_latin_characters": bool(non_latin_letters),
        "non_latin_character_count": len(non_latin_letters),
        "word_metrics_reliable": not bool(non_latin_letters),
        "warnings": warnings
    }


def analyze_text(transcript, duration):
    words = re.findall(
        r"\b[\w']+\b",
        transcript.lower()
    )

    total_words = len(words)
    unique_words = sorted(set(words))

    frequencies = Counter(words)

    # Candidate filler detection
    filler_counts = {}

    for filler in FILLERS:
        pattern = (
            r"(?<!\w)"
            + re.escape(filler)
            + r"(?!\w)"
        )

        count = len(
            re.findall(pattern, transcript.lower())
        )

        if count:
            filler_counts[filler] = count

    # Adjacent repeated words
    repeated_words = []

    for i in range(1, len(words)):
        if words[i] == words[i - 1]:
            repeated_words.append(words[i])

    # Frequent words, including function words
    repeated_vocabulary = {
        word: count
        for word, count in frequencies.most_common(15)
        if count > 1
    }

    wpm = (
        total_words / duration * 60
        if duration > 0 else 0
    )

    return {
        "total_words": total_words,
        "unique_words": len(unique_words),
        "unique_word_list": unique_words,
        "vocabulary_diversity": round(
            len(unique_words) / total_words, 3
        ) if total_words else 0,
        "top_words": dict(frequencies.most_common(10)),
        "repeated_vocabulary": repeated_vocabulary,
        "adjacent_repeated_words": repeated_words,
        "filler_counts": filler_counts,
        "total_candidate_fillers": sum(
            filler_counts.values()
        ),
        "recording_wpm": round(wpm, 2)
    }


# ============================================================
# PAUSE AND SPEECH ACTIVITY ANALYSIS
# ============================================================

def get_runs(mask):
    padded = np.concatenate(([False], mask, [False]))

    changes = np.diff(padded.astype(int))

    starts = np.where(changes == 1)[0]
    ends = np.where(changes == -1)[0]

    return list(zip(starts, ends))


def analyze_pauses(audio):
    frame_size = int(SAMPLE_RATE * 0.02)  # 20 ms

    usable_length = (len(audio) // frame_size) * frame_size

    if usable_length == 0:
        return {
            "speech_active_seconds": 0,
            "pause_count": 0,
            "pauses": [],
            "long_pauses": [],
            "total_pause_seconds": 0,
            "leading_silence_seconds": 0,
            "trailing_silence_seconds": 0
        }

    frames = audio[:usable_length].reshape(-1, frame_size)
    rms = np.sqrt(np.mean(frames ** 2, axis=1))

    noise_floor = np.percentile(rms, 20)
    threshold = max(0.008, noise_floor * 2.5)
    speech_mask = rms > threshold

    # Merge gaps of 140 ms or less.
    speech_runs = get_runs(speech_mask)

    for i in range(len(speech_runs) - 1):
        gap = speech_runs[i + 1][0] - speech_runs[i][1]
        if gap <= 7:
            speech_mask[speech_runs[i][1]:speech_runs[i + 1][0]] = True

    # Remove speech detections shorter than 120 ms.
    for start_frame, end_frame in get_runs(speech_mask):
        if end_frame - start_frame < 6:
            speech_mask[start_frame:end_frame] = False

    speech_runs = get_runs(speech_mask)
    total_frames = len(speech_mask)

    if not speech_runs:
        return {
            "speech_active_seconds": 0,
            "pause_count": 0,
            "pauses": [],
            "long_pauses": [],
            "total_pause_seconds": 0,
            "leading_silence_seconds": round(total_frames * 0.02, 2),
            "trailing_silence_seconds": 0,
            "energy_threshold": round(float(threshold), 5)
        }

    # Recording boundary silence is reported separately.
    leading_silence = speech_runs[0][0] * 0.02
    trailing_silence = (total_frames - speech_runs[-1][1]) * 0.02

    # Only gaps between detected speech runs count as internal pauses.
    pauses = []

    for i in range(len(speech_runs) - 1):
        previous_end = speech_runs[i][1]
        next_start = speech_runs[i + 1][0]
        pause_duration = (next_start - previous_end) * 0.02

        if pause_duration >= 0.35:
            pauses.append({
                "start": round(previous_end * 0.02, 2),
                "end": round(next_start * 0.02, 2),
                "duration": round(pause_duration, 2)
            })

    long_pauses = [
        pause for pause in pauses
        if pause["duration"] >= 0.7
    ]

    active_seconds = np.sum(speech_mask) * 0.02

    return {
        "speech_active_seconds": round(float(active_seconds), 2),
        "pause_count": len(pauses),
        "pauses": pauses,
        "long_pause_count": len(long_pauses),
        "long_pauses": long_pauses,
        "total_pause_seconds": round(
            sum(p["duration"] for p in pauses), 2
        ),
        "leading_silence_seconds": round(leading_silence, 2),
        "trailing_silence_seconds": round(trailing_silence, 2),
        "energy_threshold": round(float(threshold), 5)
    }


# ============================================================
# WAVLM MODEL ARCHITECTURE
# ============================================================

class AttentiveStatisticsPooling(nn.Module):

    def __init__(self, input_dim):
        super().__init__()

        self.attention = nn.Sequential(
            nn.Linear(input_dim, input_dim // 4),
            nn.Tanh(),
            nn.Linear(input_dim // 4, 1)
        )

    def forward(self, x):
        weights = F.softmax(
            self.attention(x),
            dim=1
        )

        mean = torch.sum(
            x * weights,
            dim=1
        )

        variance = torch.sum(
            weights * (
                x - mean.unsqueeze(1)
            ) ** 2,
            dim=1
        )

        std = torch.sqrt(
            variance.clamp(min=1e-8)
        )

        return torch.cat([mean, std], dim=1)


class WavLMLoRAClassifier(nn.Module):

    def __init__(self):
        super().__init__()

        config = WavLMConfig.from_pretrained(
            "microsoft/wavlm-base-plus"
        )

        wavlm = WavLMModel(config)

        lora_config = LoraConfig(
            r=8,
            lora_alpha=16,
            lora_dropout=0.1,
            target_modules=["q_proj", "v_proj"],
            bias="none"
        )

        self.wavlm = get_peft_model(
            wavlm,
            lora_config
        )

        self.pooling = AttentiveStatisticsPooling(
            config.hidden_size
        )

        self.classifier = nn.Sequential(
            nn.Linear(config.hidden_size * 2, 256),
            nn.GELU(),
            nn.LayerNorm(256),
            nn.Dropout(0.2),
            nn.Linear(256, 5)
        )

    def forward(self, input_values):
        features = self.wavlm(
            input_values
        ).last_hidden_state

        pooled = self.pooling(features)

        return self.classifier(pooled)


# ============================================================
# LOAD WAVLM CHECKPOINT
# ============================================================

def load_stuttering_model():
    print("\nLoading WavLM checkpoint...")

    if not CHECKPOINT_PATH.exists():
        raise FileNotFoundError(
            f"Checkpoint not found: {CHECKPOINT_PATH}"
        )

    device = torch.device(
        "mps" if torch.backends.mps.is_available()
        else "cpu"
    )

    model = WavLMLoRAClassifier()

    checkpoint = torch.load(
        CHECKPOINT_PATH,
        map_location="cpu",
        weights_only=True
    )

    state_dict = checkpoint.get(
        "model_state_dict",
        checkpoint
    )

    model.load_state_dict(
        state_dict,
        strict=True
    )

    model.to(device)
    model.eval()

    print(f"WavLM ready on {device}")

    return model, device


# ============================================================
# WAVLM WINDOW ANALYSIS
# ============================================================

def analyze_stuttering(audio, model, device):
    print("\\nAnalyzing speech patterns with WavLM...")

    window_size = WINDOW_SECONDS * SAMPLE_RATE
    hop_size = HOP_SECONDS * SAMPLE_RATE
    results = []

    for start in range(0, len(audio), hop_size):
        chunk = audio[start:start + window_size]

        if len(chunk) < SAMPLE_RATE:
            continue

        original_length = len(chunk)

        if len(chunk) < window_size:
            chunk = np.pad(chunk, (0, window_size - len(chunk)))

        input_values = torch.tensor(
            chunk, dtype=torch.float32
        ).unsqueeze(0).to(device)

        with torch.inference_mode():
            logits = model(input_values)
            probabilities = F.softmax(logits, dim=-1)[0]

        predicted_index = int(torch.argmax(probabilities).item())

        results.append({
            "start": round(start / SAMPLE_RATE, 2),
            "end": round((start + original_length) / SAMPLE_RATE, 2),
            "prediction": LABELS[predicted_index],
            "probabilities": {
                LABELS[i]: round(float(probabilities[i].item()), 4)
                for i in range(len(LABELS))
            }
        })

    prediction_counts = Counter(
        item["prediction"] for item in results
    )

    average_probabilities = {
        label: round(float(np.mean([
            item["probabilities"][label] for item in results
        ])), 4) if results else 0
        for label in LABELS
    }

    # Group consecutive overlapping windows into candidate regions.
    # These are model-flagged regions, not confirmed stuttering events.
    candidate_regions = []

    thresholds = {
        "Repetition": 0.45,
        "Prolongation": 0.45,
        "Block": 0.35,
        "Interjection": 0.50
    }

    for label, threshold in thresholds.items():
        matching = [
            item for item in results
            if item["probabilities"][label] >= threshold
        ]

        if not matching:
            continue

        groups = []
        current_group = [matching[0]]

        for item in matching[1:]:
            previous = current_group[-1]

            # Adjacent windows overlap or touch.
            if item["start"] <= previous["end"] + 0.01:
                current_group.append(item)
            else:
                groups.append(current_group)
                current_group = [item]

        groups.append(current_group)

        for group in groups:
            candidate_regions.append({
                "pattern": label,
                "start": round(min(x["start"] for x in group), 2),
                "end": round(max(x["end"] for x in group), 2),
                "duration": round(
                    max(x["end"] for x in group)
                    - min(x["start"] for x in group), 2
                ),
                "window_count": len(group),
                "mean_probability": round(float(np.mean([
                    x["probabilities"][label] for x in group
                ])), 4),
                "max_probability": round(max(
                    x["probabilities"][label] for x in group
                ), 4)
            })

    candidate_regions.sort(key=lambda x: x["start"])

    return {
        "window_count": len(results),
        "window_predictions": results,
        "prediction_counts": dict(prediction_counts),
        "average_probabilities": average_probabilities,
        "candidate_regions": candidate_regions,
        "region_method": (
            "Consecutive overlapping windows grouped by class probability; "
            "regions are candidate acoustic patterns, not confirmed events."
        )
    }


# ============================================================
# RECORDING ANALYSIS
# ============================================================

def analyze_recording(filename, model, device):
    path = Path(filename)

    print("\n" + "=" * 60)
    print(f"ANALYZING {filename}")
    print("=" * 60)

    if not path.exists():
        print(f"File not found: {filename}")
        return None

    audio, duration = load_audio(path)

    transcript, segments = transcribe_audio(path)
    transcript_quality = assess_transcript_quality(transcript)

    text_results = analyze_text(
        transcript,
        duration
    )

    pause_results = analyze_pauses(audio)

    speech_active = pause_results[
        "speech_active_seconds"
    ]

    active_wpm = (
        text_results["total_words"] / speech_active * 60
        if speech_active > 0 else 0
    )

    if not transcript_quality["word_metrics_reliable"]:
        active_wpm = None

    stuttering_results = analyze_stuttering(
        audio,
        model,
        device
    )

    report = {
        "filename": filename,
        "duration_seconds": round(duration, 2),
        "transcript": transcript,
        "transcript_segments": segments,
        "transcript_quality": transcript_quality,
        "user_validation_context": (
            {
                "description": "User-described normal speech",
                "patterns": []
            }
            if Path(filename).stem == "test2"
            else {
                "description": "User intentionally demonstrated these patterns",
                "patterns": [
                    "Repetition",
                    "Repeated initial sounds",
                    "Long pauses"
                ]
            }
            if Path(filename).stem == "test3"
            else None
        ),
        "repeated_initial_sound_detection": {
            "status": "not_supported_by_current_wavlm_model",
            "note": (
                "The current model has no dedicated repeated-initial-sound "
                "class. User annotations are kept separate from predictions."
            )
        },
        "text_analysis": text_results,
        "pause_analysis": pause_results,
        "active_speech_wpm": (
            round(active_wpm, 2)
            if active_wpm is not None else None
        ),
        "active_speech_wpm_reliable": (
            transcript_quality["word_metrics_reliable"]
        ),
        "stuttering_analysis": stuttering_results
    }

    print("\nTRANSCRIPT:")
    print(transcript)

    print("\nTEXT METRICS:")
    print(json.dumps(
        text_results,
        indent=2
    ))

    print("\nPAUSE METRICS:")
    print(json.dumps(
        pause_results,
        indent=2
    ))

    print("\nSPEAKING PACE:")
    print(
        f"Recording WPM: "
        f"{text_results['recording_wpm']}"
    )

    print(
        f"Active speech WPM: "
        f"{report['active_speech_wpm']}"
    )

    print("\nWAVLM PREDICTIONS:")
    print(json.dumps(
        stuttering_results["prediction_counts"],
        indent=2
    ))

    return report


# ============================================================
# COMPARISON
# ============================================================

def create_comparison(reports):
    comparison = {}

    for report in reports:
        if report is None:
            continue

        name = report["filename"]

        comparison[name] = {
            "duration_seconds": report[
                "duration_seconds"
            ],
            "total_words": report[
                "text_analysis"
            ]["total_words"],
            "unique_words": report[
                "text_analysis"
            ]["unique_words"],
            "candidate_fillers": report[
                "text_analysis"
            ]["total_candidate_fillers"],
            "adjacent_repetitions": len(
                report["text_analysis"][
                    "adjacent_repeated_words"
                ]
            ),
            "pause_count": report[
                "pause_analysis"
            ]["pause_count"],
            "total_pause_seconds": report[
                "pause_analysis"
            ]["total_pause_seconds"],
            "recording_wpm": report[
                "text_analysis"
            ]["recording_wpm"],
            "active_speech_wpm": report[
                "active_speech_wpm"
            ],
            "active_speech_wpm_reliable": report[
                "active_speech_wpm_reliable"
            ],
            "transcript_quality": report[
                "transcript_quality"
            ],
            "long_pause_count": report[
                "pause_analysis"
            ].get("long_pause_count", 0),
            "wavlm_candidate_region_count": len(
                report["stuttering_analysis"].get(
                    "candidate_regions", []
                )
            ),
            "user_validation_context": report[
                "user_validation_context"
            ],
            "wavlm_predictions": report[
                "stuttering_analysis"
            ]["prediction_counts"],
            "wavlm_average_probabilities": report[
                "stuttering_analysis"
            ]["average_probabilities"]
        }

    return comparison


# ============================================================
# MAIN
# ============================================================

def main():
    REPORT_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    model, device = load_stuttering_model()

    reports = []

    for filename in AUDIO_FILES:
        report = analyze_recording(
            filename,
            model,
            device
        )

        if report is not None:
            reports.append(report)

            output_path = (
                REPORT_DIR
                / f"{Path(filename).stem}.json"
            )

            with open(
                output_path,
                "w",
                encoding="utf-8"
            ) as file:
                json.dump(
                    report,
                    file,
                    indent=2,
                    ensure_ascii=False
                )

            print(
                f"\nSaved report: {output_path}"
            )

    comparison = create_comparison(reports)

    comparison_path = (
        REPORT_DIR / "comparison.json"
    )

    with open(
        comparison_path,
        "w",
        encoding="utf-8"
    ) as file:
        json.dump(
            comparison,
            file,
            indent=2,
            ensure_ascii=False
        )

    print("\n" + "=" * 60)
    print("FINAL COMPARISON")
    print("=" * 60)

    print(json.dumps(
        comparison,
        indent=2
    ))

    print("\nAll analysis completed.")
    print(f"Reports saved in: {REPORT_DIR}")


if __name__ == "__main__":
    main()
