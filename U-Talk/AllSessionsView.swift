//
//  AllSessionsView.swift
//  U-Talk
//
//  Created by Jana Almuhayzi on 08/06/1448 AH.
//

import SwiftUI

struct UTalkSession: Identifiable, Codable {
    enum PracticeMode: String, Codable {
        case conversation = "Conversation"
        case script = "Script"
    }
    enum SessionStatus: String, Codable {
        case completed = "Completed"
        case endedEarly = "Ended early"
    }
    var id: UUID = UUID()
    var title: String
    var mode: PracticeMode
    var date: Date
    var durationSeconds: Int
    var status: SessionStatus
}

struct AllSessionsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("uTalkSavedSessions") private var savedSessionsData: Data = Data()
    @State private var selectedFilter: SessionFilter = .all
    @State private var confirmClearAll = false
    private let forest = Color(red: 39/255, green: 79/255, blue: 72/255)
    private let paleLime = Color(red: 237/255, green: 252/255, blue: 214/255)
    private let softCyan = Color(red: 204/255, green: 241/255, blue: 253/255)
    private enum SessionFilter: String, CaseIterable {
        case all = "All"
        case conversation = "Conversation"
        case script = "Script"
    }
    private var sessions: [UTalkSession] {
        (try? JSONDecoder().decode([UTalkSession].self, from: savedSessionsData)) ?? []
    }
    private var filteredSessions: [UTalkSession] {
        sessions.filter { session in
            switch selectedFilter {
            case .all: return true
            case .conversation: return session.mode == .conversation
            case .script: return session.mode == .script
            }
        }.sorted { $0.date > $1.date }
    }
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    filterBar
                        .padding(.top, 18)
                    if filteredSessions.isEmpty {
                        emptyState
                            .padding(.top, 78)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredSessions) { session in
                                NavigationLink {
                                    SessionDetailView(session: session)
                                } label: {
                                    sessionRow(session)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation { SessionHistory.delete(id: session.id) }
                                    } label: {
                                        Label("Delete session", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                    Spacer(minLength: 90)
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height, alignment: .top)
                .background(alignment: .topTrailing) {
                    Circle()
                        .fill(paleLime)
                        .frame(width: 320, height: 320)
                        .offset(x: 100, y: -120)
                        .allowsHitTesting(false)
                }
                .background(alignment: .bottomLeading) {
                    Circle()
                        .fill(softCyan)
                        .frame(width: 260, height: 260)
                        .offset(x: -130, y: 90)
                        .allowsHitTesting(false)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color.white)
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        #endif
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(forest)
                        .frame(width: 52, height: 52)
                        .background(.white, in: Circle())
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
                }
                .buttonStyle(.plain)

                Spacer()

                if !sessions.isEmpty {
                    Button("Clear history") { confirmClearAll = true }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(forest)
                        .padding(.horizontal, 16)
                        .frame(height: 43)
                        .background(.white, in: Capsule())
                        .overlay(Capsule().stroke(forest.opacity(0.16), lineWidth: 1))
                        .buttonStyle(.plain)
                }
            }
            .confirmationDialog("Clear all practice history?", isPresented: $confirmClearAll, titleVisibility: .visible) {
                Button("Clear history", role: .destructive) {
                    withAnimation { SessionHistory.clearAll() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes every saved session and its feedback from this iPhone. Your roadmap progress stays.")
            }
            Text("All")
                .font(.system(size: 49, weight: .bold, design: .serif))
                .foregroundStyle(forest)
            Text("sessions")
                .font(.system(size: 43, weight: .bold, design: .serif))
                .foregroundStyle(forest)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.top, 12)
    }
    private var filterBar: some View {
        HStack(spacing: 9) {
            ForEach(SessionFilter.allCases, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(selectedFilter == filter ? .white : forest)
                        .padding(.horizontal, 16)
                        .frame(height: 43)
                        .background(selectedFilter == filter ? forest : .white, in: Capsule())
                        .overlay(Capsule().stroke(forest.opacity(0.16), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: selectedFilter == .script ? "doc.text" : "bubble.left.and.bubble.right")
                .font(.system(size: 35, weight: .regular))
                .foregroundStyle(forest)
                .frame(width: 90, height: 90)
                .background(paleLime, in: Circle())
            Text("No sessions yet")
                .font(.system(size: 25, weight: .bold, design: .serif))
                .foregroundStyle(forest)
            Text("Your practice sessions will appear here once you complete your first session.")
                .font(.system(size: 15))
                .foregroundStyle(forest.opacity(0.72))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 285)
        }
        .frame(maxWidth: .infinity)
    }
    private func sessionRow(_ session: UTalkSession) -> some View {
        HStack(spacing: 13) {
            VStack(spacing: 0) {
                Text(session.date.formatted(.dateTime.day()))
                    .font(.system(size: 25, weight: .bold, design: .serif))
                Text(session.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(forest)
            .frame(width: 45)
            Image(systemName: session.mode == .conversation ? "bubble.left" : "doc.text")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(forest)
                .frame(width: 52, height: 52)
                .background(session.mode == .conversation ? Color(red: 183/255, green: 209/255, blue: 251/255) : paleLime,
                            in: RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .lineLimit(1)
                Text("\(session.mode.rawValue) · \(Int(ceil(Double(session.durationSeconds) / 60))) min")
                    .font(.system(size: 13))
                Text(session.status.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(session.status == .completed ? paleLime : softCyan, in: Capsule())
            }
            .foregroundStyle(forest)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(forest)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(forest.opacity(0.15), lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        AllSessionsView()
    }
}
