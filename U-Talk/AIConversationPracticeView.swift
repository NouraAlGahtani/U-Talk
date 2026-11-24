import SwiftUI
import Combine

// MARK: - Screen 2: live AI conversation (dark green)

struct AIConversationPracticeView: View {
    let scenario: PracticeScenario
    let onFinish: (PracticeSessionResult) -> Void
    let onExit: () -> Void

    @StateObject private var speech = CapturingSpeechManager()   // on-device speech-to-text + saves each answer for analysis
    @StateObject private var voice = PracticeVoice()
    @StateObject private var ambience = AmbiencePlayer()
    @AppStorage("utalk.ambienceLevel") private var ambienceLevel: Double = 0.18
    @Environment(\.scenePhase) private var scenePhase
    @State private var storyComplete = false
    @AppStorage("utalk.hintsEnabled") private var hintsEnabled = true   // Profile > Settings > Hints
    @State private var messages: [ChatMessage] = []
    @State private var aiLine = ""
    @State private var completedTurns = 0
    @State private var loading = false
    @State private var showHint = false
    @State private var offline = false
    /// False once the conversation is ended or left; late replies must not speak after that.
    @State private var isActive = true
    @State private var notice: String?
    @State private var startedAt = Date()
    private let api = APIClient()

    // Unlimited turns: the conversation continues until the user taps "End conversation".
    private var currentTurn: Int { completedTurns + 1 }

    var body: some View {
        ZStack {
            UTalk.forest.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 18)
                    .padding(.top, 8)

                avatar
                    .padding(.top, 24)

                VStack(alignment: .leading, spacing: 10) {
                    Text(scenario.aiRoleLabel)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.75))
                    Text(aiLine)
                        .font(UTalk.serif(26))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .animation(.easeInOut, value: aiLine)

                    if speech.listening && !speech.transcript.isEmpty {
                        Text(speech.transcript)
                            .font(.system(size: 15))
                            .italic()
                            .foregroundStyle(UTalk.periwinkle)
                            .padding(.top, 6)
                    }
                    if offline {
                        Text("Offline practice: AI backend unavailable, using sample replies.")
                            .font(.caption)
                            .foregroundStyle(UTalk.paleLime.opacity(0.8))
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.top, 20)

                Spacer(minLength: 12)

                if showHint {
                    hintCard.padding(.horizontal, 22).padding(.bottom, 14)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Text(promptText)
                    .font(UTalk.serif(20))
                    .foregroundStyle(UTalk.paleLime)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)

                if let notice {
                    Text(notice)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 6)
                }

                if storyComplete && !speech.listening && !loading {
                    Button { finish() } label: {
                        HStack(spacing: 6) {
                            Text("See feedback")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(UTalk.forest)
                        .padding(.horizontal, 22)
                        .frame(height: 46)
                        .background(UTalk.paleLime, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                    .transition(.opacity)
                }

                WaveformBars(active: speech.listening, color: UTalk.periwinkle)
                    .padding(.top, 14)

                bottomControls
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 12)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .alert("Speech recognition", isPresented: Binding(
            get: { speech.errorMessage != nil },
            set: { if !$0 { speech.errorMessage = nil } }
        )) {
            Button("OK") { speech.errorMessage = nil }
        } message: {
            Text(speech.errorMessage ?? "")
        }
        .task {
            guard messages.isEmpty else { return }
            startedAt = Date()
            aiLine = scenario.aiOpening
            messages.append(ChatMessage(role: "assistant", content: scenario.aiOpening))
            ambience.load(scenario.ambienceAsset)
            ambience.setLevel(Float(ambienceLevel), resumeIfNeeded: true)
            await say(scenario.aiOpening)
        }
        .onChange(of: ambienceLevel) { _, newLevel in
            ambience.setLevel(Float(newLevel), resumeIfNeeded: !speech.listening)
        }
        .onChange(of: scenePhase) { _, phase in
            // No background sound while the app isn't on screen (battery).
            if phase != .active { ambience.pauseNow() } else if !speech.listening { ambience.resume() }
        }
        .onChange(of: speech.listening) { _, isListening in
            // Background sound comes back as soon as the microphone is off.
            if !isListening { ambience.resume() }
        }
        .onDisappear {
            isActive = false
            speech.stop()
            voice.stop()
            ambience.stop()
        }
    }

    // MARK: Pieces

    private var topBar: some View {
        HStack {
            Button {
                endConversation()
            } label: {
                Label("End conversation", systemImage: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(.white.opacity(0.1), in: Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            if ambience.isAvailable {
                Menu {
                    Picker("Background sound", selection: $ambienceLevel) {
                        Text("Off").tag(0.0)
                        Text("Low").tag(0.1)
                        Text("Medium").tag(0.18)
                        Text("High").tag(0.28)
                    }
                } label: {
                    Image(systemName: ambienceLevel > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.1), in: Circle())
                }
                .accessibilityLabel("Background sound")
            }

            HStack(spacing: 6) {
                Circle().fill(UTalk.forest).frame(width: 6, height: 6)
                Text(statusText).font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(UTalk.forest)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(speech.listening ? UTalk.periwinkle : UTalk.paleLime, in: Capsule())
            .animation(.easeInOut, value: statusText)
        }
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(.white.opacity(0.05)).frame(width: 220, height: 220)
            Circle().fill(.white.opacity(0.08)).frame(width: 160, height: 160)
            // The U dressed for this scenario (waiter, pilot, interviewer…) inside the pale-lime badge,
            // green U like the logo; its mouth moves while the AI speaks.
            Circle().fill(UTalk.paleLime).frame(width: 150, height: 150)
            ScenarioMascot(scenarioID: scenario.id, talking: voice.isSpeaking)
                .frame(width: 150, height: 150)
                .clipShape(Circle())
        }
        .scaleEffect(loading ? 0.96 : 1)
        .animation(loading ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                   value: loading)
    }

    private var hintCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb")
                .foregroundStyle(UTalk.forest)
            Text(scenario.aiHints[completedTurns % scenario.aiHints.count])
                .font(.system(size: 14))
                .foregroundStyle(UTalk.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(UTalk.paleLime, in: RoundedRectangle(cornerRadius: 18))
    }

    private var bottomControls: some View {
        ZStack {
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showHint.toggle() }
                } label: {
                    Image(systemName: showHint ? "lightbulb.fill" : "lightbulb")
                        .font(.system(size: 18))
                        .foregroundStyle(UTalk.paleLime)
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showHint ? "Hide hint" : "Show hint")
                .opacity(hintsEnabled ? 1 : 0)
                .disabled(!hintsEnabled)
                .accessibilityHidden(!hintsEnabled)

                Spacer()

                VStack(spacing: 0) {
                    Text("\(currentTurn)").font(UTalk.serif(22))
                    Text("turn").font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Turn \(currentTurn)")
            }

            micButton
        }
    }

    private var micButton: some View {
        Button { micTapped() } label: {
            Image(systemName: speech.listening ? "stop.fill" : "mic")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(UTalk.forest)
                .frame(width: 84, height: 84)
                .background(speech.listening ? UTalk.periwinkle : UTalk.paleLime, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(loading)
        .opacity(loading ? 0.5 : 1)
        .accessibilityLabel(speech.listening ? "Stop and send answer" : "Start answering")
    }

    private var statusText: String {
        if speech.listening { return "Listening" }
        if loading { return "Thinking…" }
        if storyComplete { return "The End" }
        return "Your turn"
    }

    private var promptText: String {
        if speech.listening { return "Take your time. Tap again when you're done" }
        if loading { return "One moment…" }
        if storyComplete { return "The story is complete. Keep talking, or see your feedback" }
        return "Tap the mic and answer"
    }

    // MARK: Actions

    private func micTapped() {
        if speech.listening {
            let said = speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            speech.stop()
            guard !said.isEmpty else {
                speech.discardLastTurn()     // nothing recognized, so don't analyze this audio
                notice = "We didn't catch any words that time. Tap the mic to try again, no rush."
                return
            }
            notice = nil
            Task { await send(said) }
        } else {
            voice.stop()
            notice = nil
            withAnimation { showHint = false }
            Task {
                await ambience.fadeOut()      // keep background sound out of the recording
                await speech.start()
            }
        }
    }

    private func send(_ text: String) async {
        messages.append(ChatMessage(role: "user", content: text))
        completedTurns += 1
        loading = true

        let reply: String
        do {
            reply = try await api.reply(scenarioMode: scenario.backendMode, messages: messages)
            offline = false
        } catch {
            offline = true
            reply = scenario.offlineReplies[(completedTurns - 1) % scenario.offlineReplies.count]
        }

        let (line, ended) = Self.removeEndMarker(reply)
        messages.append(ChatMessage(role: "assistant", content: line))
        aiLine = line
        loading = false
        if ended { withAnimation { storyComplete = true } }
        await say(line)
    }

    /// Andrew (backend /speak, in this scenario's tone) first; on-device voice as fallback.
    private func say(_ text: String) async {
        if !offline, let data = try? await api.voiceAudio(text: text,
                                                          voice: scenario.voiceName,
                                                          style: scenario.voiceStyle,
                                                          rate: scenario.voiceRate) {
            // The answer may arrive after the conversation was ended (Azure can be slow): stay quiet then.
            guard isActive, !Task.isCancelled, !speech.listening else { return }
            if (try? voice.play(data)) != nil {
                ambience.resume()                     // voice playback resets the audio session
                return
            }
        }
        // Don't fall back to the iPhone voice if the request failed only because the screen was closed
        // (that's what made the robot voice speak on the Roadmap).
        guard isActive, !Task.isCancelled, !speech.listening else { return }
        voice.speak(text)
        ambience.resume()
    }

    /// Role-play characters end the story with "[END]"; it is removed before showing or speaking the line.
    static func removeEndMarker(_ text: String) -> (String, Bool) {
        guard text.range(of: "[END]", options: .caseInsensitive) != nil else { return (text, false) }
        let cleaned = text.replacingOccurrences(of: "[END]", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (cleaned.isEmpty ? "The end." : cleaned, true)
    }

    private func endConversation() {
        isActive = false
        speech.stop()
        voice.stop()
        ambience.stop()
        if completedTurns > 0 { finish() } else { onExit() }
    }

    private func finish() {
        isActive = false
        voice.stop()
        speech.stop()
        voice.stop()
        ambience.stop()
        let userSpeech = messages.filter { $0.role == "user" }.map(\.content).joined(separator: " ")
        onFinish(PracticeSessionResult(kind: .aiConversation,
                                       duration: Date().timeIntervalSince(startedAt),
                                       turns: completedTurns,
                                       plannedTurns: 0,
                                       recordingURL: nil,
                                       recordingDuration: nil,
                                       turnRecordingURLs: speech.turnFiles,
                                       transcript: userSpeech,
                                       conversation: messages))
    }
}

#Preview {
    AIConversationPracticeView(scenario: .restaurant, onFinish: { _ in }, onExit: {})
}
