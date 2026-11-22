import SwiftUI

struct SetupCompleteView: View {
    @AppStorage("userName") private var userName: String = ""
    var onContinue: (() -> Void)? = nil
    @State private var showHome = false
    
    let forestGreen = Color(red: 39/255, green: 79/255, blue: 72/255)
    let paleLime = Color(red: 237/255, green: 252/255, blue: 214/255)
    
    private var displayName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "friend" : trimmed
    }
    
    var body: some View {
        GeometryReader { screen in
            ZStack {
                forestGreen.ignoresSafeArea()
                
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 400, height: 400)
                    .position(x: screen.size.width, y: 15)
                
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 200, height: 200)
                    .position(x: 0, y: screen.size.height * 0.72)
                
                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        StampBadge()
                            .fill(paleLime)
                            .frame(width: 230, height: 230)

                        AnimatedUMascot(style: .excitedWink, winks: false)
                            .frame(width: 190, height: 190)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    Text("YOUR PLAN IS READY")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(Color(red: 183/255, green: 209/255, blue: 251/255))
                    
                    Text("You're all set,\n\(displayName)!")
                        .font(.system(size: 48, weight: .bold, design: .serif))
                        .lineSpacing(-3)
                        .foregroundStyle(paleLime)
                        .padding(.top, 6)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        detailRow(
                            icon: "point.3.connected.trianglepath.dotted",
                            title: "Focus:",
                            description: "restaurants and small talk"
                        )
                        
                        detailRow(
                            icon: "lightbulb",
                            title: "Support:",
                            description: "hints and extra thinking time"
                        )
                        
                        detailRow(
                            icon: "star",
                            title: "Feedback:",
                            description: "encouraging"
                        )
                    }
                    .padding(.top, 26)
                    
                    Spacer()
                    
                    Button {
                        if let onContinue = onContinue {
                            onContinue()
                        } else {
                            showHome = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text("Go to Home")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(forestGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(paleLime, in: Capsule())
                    }
                    .padding(.bottom, 15)
                }
                .padding(.horizontal, 24)
            }
            .navigationDestination(isPresented: $showHome) {
                HomeView()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    func detailRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(paleLime)
                .frame(width: 34, height: 34)
                .background(
                    .white.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 9)
                )
            
            HStack(spacing: 4) {
                Text(title)
                    .bold()
                
                Text(description)
            }
            .font(.system(size: 15))
            .foregroundStyle(.white)
        }
    }
}

#Preview {
    SetupCompleteView()
}
