import SwiftUI

struct MicrophonePermissionView: View {
    var onBack: () -> Void
    var onAllow: () -> Void
    var onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.offWhite.ignoresSafeArea()
            GeometryReader { geo in
                Circle().fill(Color.paleLime.opacity(0.8)).frame(width: 280, height: 280).position(x: geo.size.width * 0.8, y: 50)
                Circle().fill(Color.softCyan.opacity(0.9)).frame(width: 250, height: 250).position(x: 20, y: geo.size.height * 0.82)
            }.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold)).foregroundColor(.forestGreen)
                        .frame(width: 40, height: 40).background(Color.white).clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                }.buttonStyle(TactileButtonStyle(scaleAmount: 0.9)).padding(.top, 12)

                Spacer()

                VStack(alignment: .center, spacing: 20) {
                    ZStack(alignment: .topTrailing) {
                        Text("Can I listen in?")
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(.forestGreen)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                            .offset(x: 24, y: -28)

                        ZStack {
                            Circle().fill(Color.periwinkle.opacity(0.4)).frame(width: 170, height: 170)
                            Circle().fill(Color.softCyan.opacity(0.7)).frame(width: 140, height: 140)
                            AnimatedUMascot(style: .talking)
                                .frame(width: 116, height: 116)

                            Circle().fill(Color.forestGreen).frame(width: 36, height: 36)
                                .overlay(Image(systemName: "mic.fill").foregroundColor(.paleLime).font(.system(size: 14)))
                                .offset(x: 35, y: 30)
                        }
                    }

                    Text("U would love to\nhear you").font(.system(size: 30, weight: .bold, design: .serif)).foregroundColor(.forestGreen).multilineTextAlignment(.center)
                    Text("U is your practice partner, and can only help if it can hear you.").font(.system(size: 13)).foregroundColor(.forestGreen.opacity(0.8)).multilineTextAlignment(.center).padding(.horizontal, 20)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "bubble.left.fill").foregroundColor(.forestGreen).frame(width: 24)
                        Text("So U can hear you in AI conversations.").font(.system(size: 13, weight: .medium)).foregroundColor(.forestGreen)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "waveform").foregroundColor(.forestGreen).frame(width: 24)
                        Text("So you can record yourself in script practice.").font(.system(size: 13, weight: .medium)).foregroundColor(.forestGreen)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill").foregroundColor(.forestGreen).frame(width: 24)
                        Text("Only while you practise. Turn it off anytime in Settings.").font(.system(size: 13, weight: .medium)).foregroundColor(.forestGreen)
                    }
                }
                .padding(.horizontal, 12).padding(.bottom, 24)

                VStack(spacing: 14) {
                    Button(action: onAllow) {
                        HStack(spacing: 8) {
                            Text("Allow microphone")
                        }
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 56).background(Color.forestGreen).clipShape(Capsule())
                    }.buttonStyle(TactileButtonStyle())

                    Button(action: onSkip) {
                        Text("Not now").font(.system(size: 14, weight: .semibold)).foregroundColor(.forestGreen.opacity(0.7))
                    }.frame(maxWidth: .infinity)
                }.padding(.bottom, 24)
            }.padding(.horizontal, 24)
        }
    }
}
