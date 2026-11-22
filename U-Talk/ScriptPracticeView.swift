import SwiftUI
import Combine

// MARK: - Screen 4: script practice (read, record, listen back)

struct ScriptPracticeView: View {
    let scenario: PracticeScenario
    let onFinish: (PracticeSessionResult) -> Void
    let onExit: () -> Void

    @StateObject private var recorder = ScriptRecorder()
    @StateObject private var voice = PracticeVoice()
    @State private var takes = 0
    @State private var startedAt = Date()

    private var isRecording: Bool { recorder.phase == .recording }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                scriptCard
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 12)
            }

            if let error = recorder.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 6)
            }

            statusLine
                .padding(.bottom, 10)

            controls
                .padding(.horizontal, 28)
                .padding(.bottom, 18)

            UTalkPrimaryButton(title: recorder.hasRecording ? "Finish" : "Record once to finish",
                               enabled: recorder.hasRecording && !isRecording) {
                finish()
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
        }
        .utalkCyanBlob(size: 260, offset: CGSize(width: -130, height: -150))
        .background(Color.white.ignoresSafeArea())
        .environment(\.layoutDirection, .leftToRight)
        .task {
            // Warm the model while the user reads, so analysis after "Finish" is quicker.
            _ = try? await StutterClassifier.shared.loadIfNeeded()
        }
        .onDisappear {
            recorder.stopAll()
            voice.stop()
        }
    }

    // MARK: Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                UTalkBackButton {
                    recorder.discard()
                    onExit()
                }
                Spacer()
                TagPill(text: PracticeKind.script.tag)
            }
            Text(scenario.title)
                .font(UTalk.serif(30))
                .foregroundStyle(UTalk.ink)
                .padding(.top, 6)
            Text("Read it aloud at your own pace. Tap the mic to record.")
                .font(.system(size: 14))
                .foregroundStyle(UTalk.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 18)
        .background(UTalk.paleLime.ignoresSafeArea(edges: .top))
    }

    private var scriptCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionLabel(text: "Your script")
                Spacer()
                Button {
                    voice.speak(scenario.scriptLines.joined(separator: " "), rate: 0.44)
                } label: {
                    Label("Preview", systemImage: "eye")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(UTalk.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .overlay(Capsule().stroke(UTalk.track))
                }
                .buttonStyle(.plain)
                .disabled(isRecording)
                .accessibilityHint("Listen to the script read aloud")
            }

            ForEach(scenario.scriptLines, id: \.self) { line in
                Text(line)
                    .font(UTalk.serif(20))
                    .foregroundStyle(UTalk.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(UTalk.track))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }

    @ViewBuilder
    private var statusLine: some View {
        switch recorder.phase {
        case .recording:
            HStack(spacing: 6) {
                Circle().fill(Color.red.opacity(0.8)).frame(width: 7, height: 7)
                Text("Recording · \(UTalk.clock(recorder.elapsed))")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(UTalk.ink)
        case .recorded, .playing:
            Text("Take saved · \(UTalk.clock(recorder.recordedDuration))")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(UTalk.muted)
        case .idle:
            Text(" ").font(.system(size: 13))   // keeps layout height stable
        }
    }

    private var controls: some View {
        HStack {
            sideButton(symbol: "arrow.counterclockwise", title: "Retry",
                       enabled: recorder.hasRecording && !isRecording) {
                recorder.discard()
            }

            Spacer()

            Button {
                if isRecording {
                    recorder.stopRecording()
                    if recorder.hasRecording { takes += 1 }
                } else {
                    voice.stop()
                    Task { await recorder.startRecording() }
                }
            } label: {
                Image(systemName: isRecording ? "stop.fill" : "mic")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(UTalk.forest)
                    .frame(width: 76, height: 76)
                    .background(isRecording ? UTalk.periwinkle : UTalk.paleLime, in: Circle())
                    .overlay(Circle().stroke(UTalk.forest.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isRecording ? "Stop recording" : (recorder.hasRecording ? "Record again" : "Start recording"))

            Spacer()

            sideButton(symbol: recorder.phase == .playing ? "stop.fill" : "play",
                       title: recorder.phase == .playing ? "Stop" : "My recording",
                       enabled: recorder.hasRecording) {
                recorder.togglePlayback()
            }
        }
    }

    private func sideButton(symbol: String, title: String, enabled: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 18))
                Text(title).font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(UTalk.forest)
            .frame(width: 84)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
    }

    // MARK: Actions

    private func finish() {
        recorder.stopAll()
        voice.stop()
        onFinish(PracticeSessionResult(kind: .script,
                                       duration: Date().timeIntervalSince(startedAt),
                                       turns: max(takes, 1),
                                       plannedTurns: 1,
                                       recordingURL: recorder.fileURL,
                                       recordingDuration: recorder.recordedDuration))
    }
}

#Preview {
    ScriptPracticeView(scenario: .restaurant, onFinish: { _ in }, onExit: {})
}
