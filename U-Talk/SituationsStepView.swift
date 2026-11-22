import SwiftUI

struct SituationItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
}

struct SituationsStepView: View {
    @Binding var selected: Set<String>
    var onBack: () -> Void
    var onContinue: () -> Void

    @State private var appeared = false
    @State private var shakingCard: String? = nil

    private let items: [SituationItem] = [
        SituationItem(title: "Ordering at a\nrestaurant", icon: "bubble.left"),
        SituationItem(title: "Travel and\nbooking", icon: "airplane"),
        SituationItem(title: "Small talk", icon: "person"),
        SituationItem(title: "Job interview", icon: "star"),
        SituationItem(title: "Presentations", icon: "chart.bar"),
        SituationItem(title: "Phone calls", icon: "bell")
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        OnboardingScaffold(
            step: 2,
            totalSteps: 4,
            onBack: onBack,
            continueEnabled: !selected.isEmpty,
            onContinue: onContinue
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Which situations\nfeel hardest?")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(.forestGreen)
                    .lineSpacing(-2)

                Text("Choose up to three. Your roadmap starts with these.")
                    .font(.system(size: 14))
                    .foregroundColor(.forestGreen.opacity(0.75))
                    .padding(.bottom, 12)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        let key = item.title.replacingOccurrences(of: "\n", with: " ")
                        let isSelected = selected.contains(key)
                        let isShaking = (shakingCard == key)

                        Button {
                            toggleSelection(key)
                        } label: {
                            VStack(alignment: .leading, spacing: 18) {
                                HStack {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 17, weight: isSelected ? .semibold : .medium))
                                        .foregroundColor(.forestGreen)
                                        .scaleEffect(isSelected ? 1.15 : 1.0)
                                        .rotationEffect(.degrees(isSelected ? -8 : 0))

                                    Spacer()

                                    ZStack {
                                        Circle()
                                            .fill(isSelected ? Color.forestGreen : Color.clear)
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle()
                                                    .stroke(isSelected ? Color.forestGreen : Color.gray.opacity(0.25), lineWidth: 1.5)
                                            )
                                            .scaleEffect(isSelected ? 1.08 : 1.0)

                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }

                                Text(item.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.forestGreen)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
                            .background(isSelected ? Color.softCyan : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(isSelected ? Color.forestGreen.opacity(0.35) : Color.gray.opacity(0.15), lineWidth: isSelected ? 1.5 : 1)
                            )
                            .scaleEffect(isSelected ? 1.025 : 1.0)
                            .offset(x: isShaking ? -7 : 0)
                        }
                        .buttonStyle(TactileButtonStyle(scaleAmount: 0.93))
                    }
                }

                Text("\(selected.count) of 3 chosen")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.forestGreen)
                    .padding(.top, 8)
            }
        }
        .onAppear { appeared = true }
    }

    private func toggleSelection(_ key: String) {
        if selected.contains(key) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.62)) {
                _ = selected.remove(key)
            }
        } else if selected.count < 3 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.56)) {
                _ = selected.insert(key)
            }
        } else {
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            #endif
            withAnimation(.spring(response: 0.12, dampingFraction: 0.25)) {
                shakingCard = key
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.45)) {
                    shakingCard = nil
                }
            }
        }
    }
}
