import SwiftUI

struct SplashView: View {
    var onFinished: () -> Void
    @State private var pulseRings = false
    @State private var showContent = false
    @State private var animateBars = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // Centred on the screen. Previously a pair of Spacers centred this
            // between the top edge and the level bars, which pushed it high.
            VStack(spacing: 0) {
                ZStack {
                    Circle().stroke(Color.periwinkle.opacity(0.6), lineWidth: 2).frame(width: 196, height: 196).scaleEffect(pulseRings ? 1.06 : 0.94)
                    Circle().stroke(Color.periwinkle, lineWidth: 2.5).frame(width: 176, height: 176).scaleEffect(pulseRings ? 1.03 : 0.97)
                    Circle().fill(Color.softCyan.opacity(0.55)).frame(width: 152, height: 152)
                    Circle().fill(Color.paleLime.opacity(0.75)).frame(width: 112, height: 112)
                    UMascotView(size: 72).scaleEffect(showContent ? 1.0 : 0.6).opacity(showContent ? 1.0 : 0)
                }
                .padding(.bottom, 32)

                Text("U-Talk").font(.system(size: 46, weight: .bold, design: .serif)).foregroundColor(.forestGreen)
                Text("Practise out loud. Build\nconfidence. Speak more freely.")
                    .font(.system(size: 15)).foregroundColor(.forestGreen.opacity(0.8)).multilineTextAlignment(.center).padding(.top, 8)
            }

            // Pinned to the bottom so it no longer shifts the block above it.
            VStack(spacing: 10) {
                HStack(spacing: 5) {
                    ForEach(0..<7, id: \.self) { i in
                        Capsule().fill([Color.mutedGreen, .periwinkle, .softCyan, .periwinkle, .mutedGreen, .periwinkle, .mutedGreen][i])
                            .frame(width: 4.5, height: animateBars ? [28, 16, 32, 18, 28, 14, 24][i] : 10)
                            .animation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(Double(i) * 0.08), value: animateBars)
                    }
                }.frame(height: 34)
                Text("WARMING UP").font(.system(size: 10, weight: .bold)).tracking(1.5).foregroundColor(.forestGreen)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 36)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) { showContent = true }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { pulseRings = true }
            animateBars = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { onFinished() }
        }
    }
}
