import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let originX: CGFloat
    let originY: CGFloat
    let vx: CGFloat
    let vy: CGFloat
    let width: CGFloat
    let height: CGFloat
    let color: Color
    let spinSpeed: Double
    let wobbleFrequency: Double
    let wobbleAmplitude: CGFloat
    let phase: Double
    let shapeType: Int
}

struct CommitmentView: View {
    var onBack: (() -> Void)? = nil
    var onContinue: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var strokes: [[CGPoint]] = []
    @State private var currentStroke: [CGPoint] = []
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var celebrationStartTime: Date? = nil
    @State private var isCelebrating = false
    @State private var pulseRing = false
    
    let forestGreen = Color(red: 39/255, green: 79/255, blue: 72/255)
    let paleLime = Color(red: 237/255, green: 252/255, blue: 214/255)
    let softCyan = Color(red: 204/255, green: 241/255, blue: 253/255)
    let periwinkle = Color(red: 183/255, green: 209/255, blue: 251/255)
    
    private var hasSignature: Bool {
        !strokes.isEmpty || !currentStroke.isEmpty
    }
    
    var body: some View {
        GeometryReader { screen in
            ZStack(alignment: .topLeading) {
                Color.white.ignoresSafeArea()
                
                Circle()
                    .fill(paleLime)
                    .frame(width: 230, height: 230)
                    .position(x: screen.size.width - 10, y: 0)
                
                Circle()
                    .fill(softCyan)
                    .frame(width: 210, height: 210)
                    .position(x: 0, y: screen.size.height * 0.75)
                
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        if let onBack = onBack {
                            onBack()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(forestGreen)
                            .frame(width: 36, height: 36)
                            .background(.white, in: Circle())
                            .shadow(color: .black.opacity(0.06), radius: 4)
                    }
                    .disabled(isCelebrating)
                    .opacity(isCelebrating ? 0.4 : 1.0)
                    
                    Text("Make yourself a\npromise")
                        .font(.system(size: 31, weight: .bold, design: .serif))
                        .foregroundStyle(forestGreen)
                        .padding(.top, 18)
                    
                    Text("Small and steady beats big and rare.")
                        .font(.system(size: 12))
                        .foregroundStyle(forestGreen)
                        .padding(.top, 5)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        promiseRow("I'll practise a little, most days.")
                        promiseRow("I'll be patient with myself.")
                        promiseRow("I'll speak up, even when it feels wobbly.")
                    }
                    .padding(.top, 22)
                    
                    Text("SIGN YOUR NAME")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(forestGreen)
                        .padding(.top, 26)
                    
                    // Constrained Signature Box
                    GeometryReader { box in
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white)
                            
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isCelebrating ? forestGreen : forestGreen.opacity(0.6),
                                    style: StrokeStyle(lineWidth: isCelebrating ? 2 : 1.2, dash: isCelebrating ? [] : [4, 4])
                                )
                            
                            if !hasSignature {
                                Label("Tap here to sign", systemImage: "pencil")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(forestGreen)
                            }
                            
                            Path { path in
                                for stroke in strokes {
                                    addStroke(stroke, to: &path)
                                }
                                addStroke(currentStroke, to: &path)
                            }
                            .stroke(
                                forestGreen,
                                style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round)
                            )
                        }
                        .scaleEffect(isCelebrating ? 1.02 : 1.0)
                        .shadow(color: forestGreen.opacity(isCelebrating ? 0.14 : 0.03), radius: 10, y: 4)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard !isCelebrating else { return }
                                    let clampedX = min(max(value.location.x, 6), box.size.width - 6)
                                    let clampedY = min(max(value.location.y, 6), box.size.height - 6)
                                    currentStroke.append(CGPoint(x: clampedX, y: clampedY))
                                }
                                .onEnded { _ in
                                    if !currentStroke.isEmpty {
                                        strokes.append(currentStroke)
                                        currentStroke = []
                                    }
                                }
                        )
                    }
                    .frame(height: 115)
                    .padding(.top, 10)
                    
                    HStack(spacing: 0) {
                        Text("Note: ")
                            .bold().foregroundStyle(.black)
                        
                        Text("The signature will not be saved.")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
                    .padding(.top, 8)
                    
                    if hasSignature && !isCelebrating {
                        Button("Clear signature") {
                            withAnimation(.easeOut(duration: 0.2)) {
                                strokes.removeAll()
                                currentStroke.removeAll()
                            }
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(forestGreen)
                        .padding(.top, 5)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        if isCelebrating {
                            Capsule()
                                .stroke(paleLime, lineWidth: 3)
                                .frame(height: 50)
                                .scaleEffect(pulseRing ? 1.18 : 1.0)
                                .opacity(pulseRing ? 0 : 0.9)
                        }
                        
                        Button {
                            guard !isCelebrating else { return }
                            startCelebration(in: screen.size)
                        } label: {
                            HStack(spacing: 8) {
                                if isCelebrating {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 16))
                                        .transition(.scale.combined(with: .opacity))
                                }
                                Text(isCelebrating ? "Promise locked in!" : "Sign to continue")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                !hasSignature
                                ? Color(red: 0.86, green: 0.90, blue: 0.89)
                                : forestGreen,
                                in: Capsule()
                            )
                            .foregroundStyle(!hasSignature ? forestGreen : (isCelebrating ? paleLime : .white))
                            .scaleEffect(isCelebrating ? 1.03 : 1.0)
                        }
                        .disabled(!hasSignature || isCelebrating)
                    }
                    .padding(.bottom, 15)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                // 60fps Physics Confetti Overlay
                if let startTime = celebrationStartTime {
                    TimelineView(.animation) { timeline in
                        let elapsed = timeline.date.timeIntervalSince(startTime)
                        Canvas { context, _ in
                            for piece in confettiPieces {
                                let t = CGFloat(elapsed)
                                let drag: CGFloat = 0.88
                                let effectiveT = (1 - pow(drag, t * 60)) / (1 - drag) * (1.0 / 60.0)
                                let gravity: CGFloat = 680
                                
                                let sway = sin(elapsed * piece.wobbleFrequency + piece.phase) * piece.wobbleAmplitude * min(t * 2, 1.0)
                                let currentX = piece.originX + piece.vx * effectiveT + sway
                                let currentY = piece.originY + piece.vy * effectiveT + 0.5 * gravity * t * t
                                
                                guard currentY < screen.size.height + 60 else { continue }
                                
                                let fade = elapsed > 1.45 ? max(0, 1.0 - (elapsed - 1.45) / 0.45) : 1.0
                                let tumble = cos(elapsed * piece.spinSpeed + piece.phase)
                                let angle = Angle.degrees(elapsed * piece.spinSpeed * 45 + piece.phase * 57.3)
                                
                                var pieceContext = context
                                pieceContext.opacity = fade
                                pieceContext.translateBy(x: currentX, y: currentY)
                                pieceContext.rotate(by: angle)
                                pieceContext.scaleBy(x: 1.0, y: max(0.25, abs(tumble)))
                                
                                let rect = CGRect(
                                    x: -piece.width / 2,
                                    y: -piece.height / 2,
                                    width: piece.width,
                                    height: piece.height
                                )
                                
                                if piece.shapeType == 0 {
                                    pieceContext.fill(Path(ellipseIn: rect), with: .color(piece.color))
                                } else {
                                    pieceContext.fill(
                                        Path(roundedRect: rect, cornerRadius: 2),
                                        with: .color(piece.color)
                                    )
                                }
                            }
                        }
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private func addStroke(_ points: [CGPoint], to path: inout Path) {
        guard let first = points.first else { return }
        path.move(to: first)
        if points.count == 1 {
            path.addLine(to: CGPoint(x: first.x + 0.5, y: first.y + 0.5))
        } else {
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
    }
    
    func promiseRow(_ title: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(forestGreen)
                .frame(width: 23, height: 23)
                .background(paleLime, in: Circle())
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(forestGreen)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func startCelebration(in size: CGSize) {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
            isCelebrating = true
        }
        withAnimation(.easeOut(duration: 0.7)) {
            pulseRing = true
        }
        
        let palette: [Color] = [
            forestGreen,
            paleLime,
            softCyan,
            periwinkle,
            Color(red: 255/255, green: 214/255, blue: 102/255)
        ]
        
        let centerX = size.width / 2
        let centerY = size.height - 95
        
        var pieces: [ConfettiPiece] = []
        for i in 0..<95 {
            // Mix of wide fan burst and high center fountain
            let spread = Double.random(in: -1.15...1.15)
            let angle = -Double.pi / 2 + spread
            let speed = CGFloat.random(in: 900...1600)
            
            pieces.append(
                ConfettiPiece(
                    originX: centerX + CGFloat.random(in: -40...40),
                    originY: centerY,
                    vx: cos(angle) * speed,
                    vy: sin(angle) * speed,
                    width: CGFloat.random(in: 7...13),
                    height: CGFloat.random(in: 5...9),
                    color: palette[i % palette.count],
                    spinSpeed: Double.random(in: 4...10),
                    wobbleFrequency: Double.random(in: 4...8),
                    wobbleAmplitude: CGFloat.random(in: 12...28),
                    phase: Double.random(in: 0...(Double.pi * 2)),
                    shapeType: i % 3 == 0 ? 0 : 1
                )
            )
        }
        
        confettiPieces = pieces
        celebrationStartTime = Date()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) {
            onContinue()
        }
    }
}

#Preview {
    CommitmentView(onContinue: {})
}
