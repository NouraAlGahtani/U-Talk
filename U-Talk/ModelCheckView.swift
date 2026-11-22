import SwiftUI
import UIKit
import Darwin

/// Developer screen: confirms the Core ML model loads on this device and measures
/// inference latency with the same procedure as backend/benchmark_coreml.py
/// (5 warm-up runs, 30 timed runs, random-normal 1 x 48,000 input, compute units ALL).
struct ModelCheckView: View {
    @State private var running = false
    @State private var benchmark: ModelBenchmark?
    @State private var error: String?

    var body: some View {
        List {
            Section {
                Button {
                    run()
                } label: {
                    HStack {
                        Text(running ? "Running…" : "Run benchmark")
                        if running { Spacer(); ProgressView() }
                    }
                }
                .disabled(running)
            } footer: {
                Text("Keep the app open until it finishes. The first run includes model loading, which can take a while.")
            }

            if let error {
                Section("Error") {
                    Text(error).foregroundStyle(.red)
                }
            }

            if let b = benchmark {
                Section("Result") {
                    if b.isSimulator {
                        Text("Simulator: these timings come from the Mac, not an iPhone.")
                            .foregroundStyle(.orange)
                    }
                    row("Device", value: deviceDescription)
                    if let load = b.modelLoadMs { row("Model load", value: String(format: "%.0f ms", load)) }
                    row("Average", value: String(format: "%.1f ms", b.averageMs))
                    row("Median", value: String(format: "%.1f ms", b.medianMs))
                    row("Fastest", value: String(format: "%.1f ms", b.fastestMs))
                    row("Slowest", value: String(format: "%.1f ms", b.slowestMs))
                    row("Real-time factor", value: String(format: "%.1fx", b.realTimeFactor))
                    if let mem = b.memoryFootprintMB { row("App memory", value: String(format: "%.0f MB", mem)) }
                    row("Runs", value: "\(b.warmupRuns) warm-up + \(b.timedRuns) timed")
                }
            }
        }
        .navigationTitle("AI model check")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var deviceDescription: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafeBytes(of: &systemInfo.machine) { raw in
            String(decoding: raw.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
        return "\(machine), iOS \(UIDevice.current.systemVersion)"
    }

    private func row(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).monospacedDigit().foregroundStyle(.secondary)
        }
    }

    private func run() {
        running = true
        error = nil
        Task { @MainActor in
            do {
                benchmark = try await StutterClassifier.shared.benchmark()
            } catch {
                self.error = error.localizedDescription
            }
            running = false
        }
    }
}

#Preview {
    NavigationStack { ModelCheckView() }
}
