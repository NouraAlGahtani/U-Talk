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
