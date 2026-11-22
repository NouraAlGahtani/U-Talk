import SwiftUI

/// Opened from a row in AllSessionsView: the full conversation (or script) and the feedback of one session.
struct SessionDetailView: View {
    let session: UTalkSession

    @Environment(\.dismiss) private var dismiss
    @State private var details: SessionDetails?
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                UTalkBackButton { dismiss() }
                    .padding(.bottom, 14)

                Text(session.title)
                    .font(UTalk.serif(32))
                    .foregroundStyle(UTalk.ink)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(UTalk.muted)
                    .padding(.top, 4)

                if let details {
                    feedback(details)
                    transcript(details)
                    ratingSection(details)
                } else if loaded {
                    Text("The details of this session weren't saved. Sessions you finish from now on will show the full conversation and feedback here.")
                        .font(.system(size: 15))
                        .foregroundStyle(UTalk.muted)
                        .padding(.top, 28)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 48)
        }
        .scrollIndicators(.hidden)
        .background(Color.white.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.layoutDirection, .leftToRight)
        .onAppear {
            details = SessionHistory.details(for: session.id)
            loaded = true
        }
    }

    private var subtitle: String {
        var parts: [String] = []
        if let day = details?.day { parts.append("Day \(day)") }
        parts.append(session.mode.rawValue)
        parts.append(UTalk.duration(TimeInterval(session.durationSeconds)))
        parts.append(session.date.formatted(date: .abbreviated, time: .shortened))
        return parts.joined(separator: " · ")
    }

    // MARK: Feedback

    @ViewBuilder
    private func feedback(_ details: SessionDetails) -> some View {
        SectionLabel(text: "Feedback")
            .padding(.top, 26)
            .padding(.bottom, 10)

        if details.metrics.isEmpty {
            Text(details.analysisMessage ?? "The analysis didn't finish for this session.")
                .font(.system(size: 14))
                .foregroundStyle(UTalk.muted)
        } else {
            VStack(spacing: 10) {
                ForEach(details.metrics, id: \.self) { metric in
                    HStack(spacing: 12) {
                        Image(systemName: metric.symbol)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(UTalk.forest)
                            .frame(width: 38, height: 38)
                            .background(UTalk.paleLime, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(metric.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(UTalk.ink)
                            Text(metric.caption)
                                .font(.system(size: 12))
                                .foregroundStyle(UTalk.muted)
                        }
                        Spacer(minLength: 8)
                        if let value = metric.value {
                            Text(value)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(UTalk.forest)
                        } else {
                            LevelBars(level: metric.level)
                        }
                    }
                    .padding(12)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(UTalk.track, lineWidth: 1))
                }
            }
        }

        if let counts = details.segmentCounts {
            let events = StutterLabel.allCases.filter { $0 != .fluent && (counts[$0.name] ?? 0) > 0 }
            if !events.isEmpty {
                UTalkFlowLayout(spacing: 8) {
                    ForEach(events) { label in
                        GoalChip(text: "\(label.name) · \(counts[label.name] ?? 0)")
                    }
                }
                .padding(.top, 12)
            }
            Text("Segments are 3-second windows classified by the on-device model. This is practice feedback, not a diagnosis.")
                .font(.system(size: 11))
                .foregroundStyle(UTalk.muted)
                .padding(.top, 8)
        }
    }

    // MARK: Conversation / script

    @ViewBuilder
    private func transcript(_ details: SessionDetails) -> some View {
        SectionLabel(text: details.isConversation ? "Conversation" : "Script")
            .padding(.top, 26)
            .padding(.bottom, 10)

        if details.lines.isEmpty {
            Text("No messages were saved.")
                .font(.system(size: 14))
                .foregroundStyle(UTalk.muted)
        } else if details.isConversation {
            VStack(spacing: 10) {
                ForEach(Array(details.lines.enumerated()), id: \.offset) { _, line in
                    bubble(line, aiLabel: details.aiRoleLabel)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(details.lines.enumerated()), id: \.offset) { index, line in
                    NumberedRow(index: index + 1, text: line.text, tint: UTalk.paleLime)
                }
            }
        }
    }

    private func bubble(_ line: SavedLine, aiLabel: String) -> some View {
        let isUser = line.role == "user"
        return VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
            Text(isUser ? "YOU" : aiLabel)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(UTalk.muted)
            Text(line.text)
                .font(.system(size: 15))
                .foregroundStyle(UTalk.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? UTalk.paleLime : UTalk.periwinkle.opacity(0.45),
                            in: RoundedRectangle(cornerRadius: 18))
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .padding(.leading, isUser ? 40 : 0)
        .padding(.trailing, isUser ? 0 : 40)
    }

    // MARK: Rating

    @ViewBuilder
    private func ratingSection(_ details: SessionDetails) -> some View {
        if details.rating != nil || details.note != nil {
            SectionLabel(text: "Your notes")
                .padding(.top, 26)
                .padding(.bottom, 10)
            if let rating = details.rating {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundStyle(UTalk.forest)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Rated \(rating) of 5")
            }
            if let note = details.note {
                Text(note)
                    .font(.system(size: 15))
                    .foregroundStyle(UTalk.ink)
                    .padding(.top, 8)
            }
        }
    }
}
