import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName") private var userName: String = ""
    
    var onBack: (() -> Void)? = nil
    var onContinue: () -> Void
    
    @State private var reminderEnabled = true
    @State private var selectedTime = "Morning"
    
    let forestGreen = Color(red: 39/255, green: 79/255, blue: 72/255)
    let paleLime = Color(red: 237/255, green: 252/255, blue: 214/255)
    let softCyan = Color(red: 204/255, green: 241/255, blue: 253/255)
    
    private var displayName: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "friend" : trimmed
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
                    
                    Text("Stay on track")
                        .font(.system(size: 31, weight: .bold, design: .serif))
                        .foregroundStyle(forestGreen)
                        .padding(.top, 18)
                    
                    Text("One gentle nudge a day keeps your streak alive.")
                        .font(.system(size: 12))
                        .foregroundStyle(forestGreen)
                        .padding(.top, 5)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "bell")
                            .foregroundStyle(forestGreen)
                            .frame(width: 36, height: 36)
                            .background(paleLime, in: RoundedRectangle(cornerRadius: 10))
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("U-TALK · NOW")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(softCyan)
                            
                            Text("Ready when you are, \(displayName).\nToday's practice takes 6 minutes.")
                                .font(.system(size: 12))
                                .foregroundStyle(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(forestGreen, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.top, 20)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Daily reminder")
                                .font(.system(size: 17, weight: .bold, design: .serif))
                            
                            Text("On. You can change this in Settings.")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(forestGreen)
                        
                        Spacer()
                        
                        Toggle("", isOn: $reminderEnabled)
                            .labelsHidden()
                            .tint(forestGreen)
                    }
                    .padding(14)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(forestGreen.opacity(0.12))
                    }
                    .padding(.top, 18)
                    
                    Text("REMIND ME IN THE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(forestGreen)
                        .padding(.top, 25)
                    
                    HStack(spacing: 8) {
                        timeButton("Morning", time: "8:00")
                        timeButton("Afternoon", time: "13:00")
                    }
                    .padding(.top, 10)
                    
                    timeButton("Evening", time: "19:00")
                        .padding(.top, 8)
                    
                    Spacer()
                    
                    Button {
                        onContinue()
                    } label: {
                        HStack(spacing: 8) {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(forestGreen, in: Capsule())
                    }
                    .padding(.bottom, 15)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    func timeButton(_ title: String, time: String) -> some View {
        Button {
            selectedTime = title
        } label: {
            Text("\(title) · \(time)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(selectedTime == title ? .white : forestGreen)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(
                    selectedTime == title ? forestGreen : .white,
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(forestGreen.opacity(0.15))
                }
        }
    }
}

