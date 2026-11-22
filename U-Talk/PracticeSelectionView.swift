//
//  PracticeSelectionView.swift
//  U-Talk
//
//  Created by Jana Almuhayzi on 08/06/1448 AH.
//


import SwiftUI

struct PracticeSelectionView: View {
    let day: Int
    let scenario: String

    @Environment(\.dismiss) private var dismiss
    @AppStorage("userName") private var userName: String = ""
    
    private var displayName: String {
        let t = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "friend" : t
    }
    
    private let forest = Color(red: 39/255, green: 79/255, blue: 72/255)
    private let deepGreen = Color(red: 21/255, green: 78/255, blue: 70/255)
    private let lime = Color(red: 237/255, green: 252/255, blue: 214/255)
    private let blue = Color(red: 183/255, green: 209/255, blue: 251/255)

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(forest)
                                .frame(width: 48, height: 48)
                                .background(.white, in: Circle())
                                .shadow(color: .black.opacity(0.08), radius: 8, y: 3)
                        }
                        Spacer()
                        Text("Day \(day) · \(scenario)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(forest)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 9)
                            .background(blue, in: Capsule())
                    }
                    .padding(.top, 18)

                    Text("Pick your practice,\n\(displayName).")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundStyle(forest)
                        .minimumScaleFactor(0.7)
                        .lineLimit(2)

                    // AI Conversation
                    VStack(alignment: .leading, spacing: 17) {
                            VStack(spacing: 8) {
                                HStack {
                                    Text(exampleQuestion)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 11)
                                        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 17))
                                    Spacer(minLength: 0)
                                }
                                HStack {
                                    Spacer(minLength: 0)
                                    Text(exampleAnswer)
                                        .foregroundStyle(forest)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 11)
                                        .background(blue, in: RoundedRectangle(cornerRadius: 17))
                                }
                            }
                            .font(.system(size: 13, weight: .medium))

                            HStack(alignment: .center) {
                                Text("AI Conversation")
                                    .font(.system(size: 29, weight: .bold, design: .serif))
                                Spacer(minLength: 8)
                                NavigationLink {
                                    LessonPracticeDestination(kind: .aiConversation, day: day, lessonTitle: scenario)
                                } label: {
                                    arrowCircle(background: lime, foreground: forest)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Start AI Conversation")
                            }
                            Text("A live back-and-forth with AI. You speak, it listens and answers.")
                                .font(.system(size: 14))
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(3)
                            HStack(spacing: 6) {
                                pill("Real-time", dark: true)
                                pill("Speak + listen", dark: true)
                                pill("About 6 min", dark: true)
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(deepGreen, in: RoundedRectangle(cornerRadius: 28))
                        .shadow(color: forest.opacity(0.12), radius: 10, y: 4)

                    // Script Practice
                    VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 9) {
                                    scriptLine(width: 170, color: deepGreen)
                                    scriptLine(width: 120, color: deepGreen)
                                    scriptLine(width: 145, color: Color(red: 145/255, green: 194/255, blue: 137/255))
                                    scriptLine(width: 90, color: deepGreen)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 94)
                                .background(.white, in: RoundedRectangle(cornerRadius: 17))
                                .overlay(RoundedRectangle(cornerRadius: 17).stroke(forest.opacity(0.12)))

                                Image(systemName: "mic")
                                    .font(.system(size: 21))
                                    .foregroundStyle(.white)
                                    .frame(width: 50, height: 50)
                                    .background(deepGreen, in: Circle())
                            }
                            HStack {
                                Text("Script Practice")
                                    .font(.system(size: 30, weight: .bold, design: .serif))
                                Spacer(minLength: 8)
                                NavigationLink {
                                    LessonPracticeDestination(kind: .script, day: day, lessonTitle: scenario)
                                } label: {
                                    arrowCircle(background: deepGreen, foreground: .white)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Start Script Practice")
                            }
                            Text("Read a prepared script aloud, record yourself and play it back.")
                                .font(.system(size: 14))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 6) {
                                pill("Guided", dark: false)
                                pill("Record + replay", dark: false)
                                pill("About 4 min", dark: false)
                            }
                        }
                        .foregroundStyle(forest)
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(lime, in: RoundedRectangle(cornerRadius: 28))
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(forest.opacity(0.10)))
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 45)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(.white)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var exampleQuestion: String {
        day == 1 ? "Hi! What's your name?" : "What would you like to say?"
    }

    private var exampleAnswer: String {
        guard day == 1 else { return "I'd like to practice, please." }
        let name = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Hi, nice to meet you." : "Hi, I'm \(name)."
    }

    private func arrowCircle(background: Color, foreground: Color) -> some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: 46, height: 46)
            .background(background, in: Circle())
    }

    private func scriptLine(width: CGFloat, color: Color) -> some View {
        Capsule().fill(color).frame(width: width, height: 9)
    }

    private func pill(_ text: String, dark: Bool) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(dark ? Color.white.opacity(0.13) : .white, in: Capsule())
    }
}

// Temporary destinations until practice screens are built
private struct PracticeModePlaceholder: View {
    let mode: String
    let day: Int
    let scenario: String

    var body: some View {
        VStack(spacing: 16) {
            Text(mode).font(.largeTitle.bold())
            Text("Day \(day) · \(scenario)")
            Text("Practice screen coming next")
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        PracticeSelectionView(day: 1, scenario: "Introducing Yourself")
    }
}
