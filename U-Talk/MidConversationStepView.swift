import SwiftUI

struct MidConversationStepView: View {
    @Binding var selected: Set<String>
    var onBack: () -> Void
    var onContinue: () -> Void

    let options = [
        ("Hints when I get stuck", "A nudge towards the next thing to say"),
        ("Suggested responses", "Example lines I can borrow"),
        ("More time to think", "A slower pace before I answer"),
        ("Simple tips before I start", "One or two pointers per scene")
    ]

    var body: some View {
        OnboardingScaffold(step: 3, totalSteps: 4, onBack: onBack, continueEnabled: !selected.isEmpty, onContinue: onContinue) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What helps you\nmid-\nconversation?").font(.system(size: 32, weight: .bold, design: .serif)).foregroundColor(.forestGreen).lineSpacing(-3)
                Text("Choose as many as you like.").font(.system(size: 14)).foregroundColor(.forestGreen.opacity(0.75)).padding(.bottom, 12)

                VStack(spacing: 12) {
                    ForEach(options, id: \.0) { title, subtitle in
                        let isSelected = selected.contains(title)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if isSelected { selected.remove(title) } else { selected.insert(title) }
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(isSelected ? Color.forestGreen : Color.clear).frame(width: 24, height: 24)
                                        .overlay(Circle().stroke(isSelected ? Color.forestGreen : Color.gray.opacity(0.25), lineWidth: 1.5))
                                    if isSelected { Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white) }
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(.forestGreen)
                                    Text(subtitle).font(.system(size: 12)).foregroundColor(.forestGreen.opacity(0.75))
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .background(isSelected ? Color.softCyan : Color.white).clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? Color.forestGreen.opacity(0.25) : Color.gray.opacity(0.15), lineWidth: 1))
                        }.buttonStyle(TactileButtonStyle(scaleAmount: 0.97))
                    }
                }
            }
        }
    }
}
