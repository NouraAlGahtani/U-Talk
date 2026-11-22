import SwiftUI

struct FeedbackStepView: View {
    @Binding var selected: String
    var onBack: () -> Void
    var onContinue: () -> Void

    let options = [
        ("Encouraging", "Tell me what went well"),
        ("Suggestions to Improve", "Tell me how to sound more natural"),
        ("Both", "A bit of praise, then one thing to work on")
    ]

    var body: some View {
        OnboardingScaffold(step: 4, totalSteps: 4, onBack: onBack, continueEnabled: !selected.isEmpty, onContinue: onContinue) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How should\nfeedback sound?").font(.system(size: 32, weight: .bold, design: .serif)).foregroundColor(.forestGreen).lineSpacing(-2)
                Text("Choose one. You can change it later in Settings.").font(.system(size: 14)).foregroundColor(.forestGreen.opacity(0.75)).padding(.bottom, 12)

                VStack(spacing: 12) {
                    ForEach(options, id: \.0) { title, subtitle in
                        let isSelected = (selected == title)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selected = title }
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
