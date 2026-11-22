import SwiftUI

struct NameStepView: View {
    @Binding var name: String
    var onBack: () -> Void
    var onContinue: () -> Void

    @State private var appeared = false
    @State private var waveTilt = false

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        OnboardingScaffold(
            step: 1,
            totalSteps: 4,
            onBack: onBack,
            continueEnabled: !trimmedName.isEmpty,
            onContinue: onContinue
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("What should we\ncall you?")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(.forestGreen)
                    .lineSpacing(-2)

                Text("We'll use it to make your plan feel like yours.")
                    .font(.system(size: 14))
                    .foregroundColor(.forestGreen.opacity(0.75))

                Text("Your first name")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.forestGreen)
                    .padding(.top, 18)

                TextField("Enter your name", text: $name)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.forestGreen)
                    .padding(.horizontal, 18)
                    .frame(height: 58)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.forestGreen.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.03), radius: 8, y: 4)

                HStack(spacing: 14) {
                    ZStack(alignment: .topTrailing) {
                        UMascotView(size: 46)
                            .rotationEffect(.degrees(waveTilt ? -6 : 4))

                        VStack(spacing: 3) {
                            Capsule().fill(Color.forestGreen).frame(width: 7, height: 2).rotationEffect(.degrees(-25))
                            Capsule().fill(Color.forestGreen).frame(width: 8, height: 2)
                            Capsule().fill(Color.forestGreen).frame(width: 7, height: 2).rotationEffect(.degrees(25))
                        }
                        .offset(x: 10, y: 2)
                        .opacity(waveTilt ? 1 : 0.3)
                    }

                    HStack(spacing: 4) {
                        Text("Nice to meet you,")
                            .font(.system(size: 14))
                            .foregroundColor(.forestGreen)
                        Text("\(trimmedName.isEmpty ? "friend" : trimmedName)!")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.forestGreen)
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.paleLime)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.top, 18)
                .scaleEffect(appeared ? 1 : 0.9)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                appeared = true
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                waveTilt = true
            }
        }
    }
}
