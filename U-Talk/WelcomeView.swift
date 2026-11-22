import SwiftUI

struct WelcomeView: View {
    var onStart: () -> Void
    @State private var appeared = false
    @State private var mascotFloat = false

    var body: some View {
        ZStack {
            Color.softCyan.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("U-Talk").font(.system(size: 18, weight: .bold, design: .serif)).foregroundColor(.forestGreen).padding(.top, 16)
                Text("Let's\nget to\nknow").font(.system(size: 54, weight: .bold, design: .serif)).foregroundColor(.forestGreen).lineSpacing(-6).padding(.top, 24)

                ZStack(alignment: .topLeading) {
                    Text("you!").font(.system(size: 20, weight: .bold, design: .serif)).italic().foregroundColor(.forestGreen)
                        .padding(.horizontal, 16).padding(.vertical, 8).background(Color.paleLime).clipShape(Capsule()).rotationEffect(.degrees(-6)).padding(.top, 16)
                    HStack {
                        Spacer()
                        UMascotView(size: 175, showStickerBorder: true)
                            .rotationEffect(.degrees(mascotFloat ? 3 : -2)).offset(y: mascotFloat ? -6 : 6)
                    }.padding(.top, 12)
                }

                Spacer()
                Text("Four quick questions. Your answers shape your practice plan.").font(.system(size: 14)).foregroundColor(.forestGreen.opacity(0.85)).padding(.bottom, 18)

                Button(action: onStart) {
                    HStack(spacing: 8) {
                        Text("Say hi to U").font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right").font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 56).background(Color.forestGreen).clipShape(Capsule())
                }.buttonStyle(TactileButtonStyle()).padding(.bottom, 24)
            }.padding(.horizontal, 26)
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.78)) { appeared = true }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { mascotFloat = true }
        }
    }
}
