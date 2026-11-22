# U-Talk: complete app (onboarding, home, roadmap, challenge mode, AI practice)

## Before the first run

1. Copy the AI model into the app folder. It isn't included because it's 363 MB:
   ```bash
   cp -R ~/Desktop/U-TALK/backend/analysis_reports/coreml/U_TALK_WavLM.mlpackage ~/Desktop/U-Talk/U-Talk/
   ```
2. Point the app at your backend's current IP:
   ```bash
   IP=$(ipconfig getifaddr en0) && sed -i '' -E "s#http://[0-9.]+:8000#http://$IP:8000#" ~/Desktop/U-Talk/U-Talk/Conversation.swift
   ```
3. Start the backend: `~/Desktop/U-TALK/backend/start_backend.sh`
4. Open `U-Talk.xcodeproj`, select your iPhone, then Clean Build Folder (⇧⌘K) and Run (⌘R).

## Project setup

- Every file in the `U-Talk/` folder is part of the app automatically (synchronized folder), so there's nothing to add by hand.
- Settings match the original U-Talk project: default MainActor isolation, approachable concurrency, Swift 5, iOS 27, iPhone only.
- The microphone, speech recognition and local network permissions are already set. HTTP to the local backend is allowed for development only.
- Signing team ZDC5U7W2VC, bundle ID `com.yusr.utalk`. If you sign with another team, change both under Signing & Capabilities.
- Lessons map to practice scenarios in `PracticeIntegration.swift`. "At the Airport" shows "coming soon".

## Setup

### 1. AI model (required to build the app)
The Core ML model is too large for git, so it is attached to a release.
1. Download `U_TALK_WavLM.mlpackage.zip` from [Releases → model-v1](https://github.com/NouraAlGahtani/U-Talk/releases/tag/model-v1).
2. Unzip it and put `U_TALK_WavLM.mlpackage` inside the `U-Talk/` folder (next to `ContentView.swift`).
3. Open `U-Talk.xcodeproj` in Xcode, choose your iPhone, and press ⌘R.

The model runs on the iPhone only; recordings are not uploaded anywhere.

### 2. Backend (AI conversation partner + Azure voices)
Runs on a Mac on the same Wi-Fi as the iPhone.
1. Store the Azure Speech key in the Mac Keychain (once):
   `security add-generic-password -U -a "$USER" -s utalk-azure-speech -w`
2. Start the backend: `./backend/start_backend.sh`
3. Point the app at this Mac's IP, then rebuild in Xcode (⌘R):
   `IP=$(ipconfig getifaddr en0) && sed -i '' -E "s#http://[0-9.]+:8000#http://$IP:8000#" U-Talk/Conversation.swift`

### Not in this repo
Python virtual environments, the PyTorch training checkpoint, dataset audio (SEP-28k, UCLASS) and test recordings stay local because of size, dataset licences and privacy.

### Note
The stutter classifier gives practice feedback. It has not been clinically validated and is not a diagnostic tool.
