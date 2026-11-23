import SwiftUI

// Profile (designed by Maysam). Opened from the profile button at the top of Home.
// Changes from the original file: no separate @main app; uses Home's NavigationStack; no bottom bar;
// name and progress come from the onboarding/home data; settings are saved.

// MARK: - 1. Profile Menu View

struct ProfileMenuView: View {
    let darkGreen = Color(red: 21.0/255, green: 83.0/255, blue: 75.0/255)
    let lightGreen = Color(red: 232.0/255, green: 250.0/255, blue: 210.0/255)
    let skyBlue = Color(red: 185.0/255, green: 239.0/255, blue: 250.0/255)
    let badgeBlue = Color(red: 174.0/255, green: 207.0/255, blue: 250.0/255)
    let borderColor = Color(red: 220.0/255, green: 230.0/255, blue: 228.0/255)

    @AppStorage("userName") private var name: String = ""
    @AppStorage("userAge") private var age: String = ""
    @AppStorage("currentPracticeDay") private var currentDay: Int = 1
    @Environment(\.dismiss) private var dismiss

    private var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Friend" : trimmed
    }

    var body: some View {
        Group {
            GeometryReader { geometry in
                ZStack {
                    Color.white
                        .ignoresSafeArea()

                    Circle()
                        .fill(lightGreen)
                        .frame(width: 290, height: 290)
                        .position(
                            x: geometry.size.width * 0.90,
                            y: 55
                        )

                    Circle()
                        .fill(skyBlue)
                        .frame(width: 250, height: 250)
                        .position(
                            x: -65,
                            y: geometry.size.height * 0.79
                        )

                    VStack(spacing: 0) {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 17.5, weight: .semibold))
                                    .foregroundColor(darkGreen)
                                    .frame(width: 40, height: 40)
                                    .background(.white)
                                    .clipShape(Circle())
                                    .shadow(color: darkGreen.opacity(0.08), radius: 7, x: 0, y: 3)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Back")
                            Spacer()
                        }
                        .padding(.top, 8)

                        HStack(spacing: 15) {
                            SealShape()
                                .fill(badgeBlue)
                                .frame(width: 100, height: 100)
                                .overlay {
                                    Text(String(displayName.prefix(1)).uppercased())
                                        .font(.custom("Georgia-Bold", size: 50))
                                        .foregroundColor(darkGreen)
                                }

                            VStack(alignment: .leading, spacing: 5) {
                                Text(displayName)
                                    .font(.custom("Georgia-Bold", size: 38))
                                    .foregroundColor(darkGreen)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                Text("Day \(min(currentDay, 6)) of 6")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(darkGreen.opacity(0.8))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.top, 8)

                        VStack(spacing: 16) {
                            NavigationLink {
                                AccountDetailView(name: $name, age: $age)
                                    .toolbar(.hidden, for: .navigationBar)
                            } label: {
                                menuCardContent(
                                    icon: "person",
                                    title: "Account",
                                    subtitle: "Name, email, sign out",
                                    color: badgeBlue
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                SettingsDetailView()
                                    .toolbar(.hidden, for: .navigationBar)
                            } label: {
                                menuCardContent(
                                    icon: "slider.horizontal.3",
                                    title: "Settings",
                                    subtitle: "Reminders, feedback, support",
                                    color: lightGreen
                                )
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                HelpSupportView()
                                    .toolbar(.hidden, for: .navigationBar)
                            } label: {
                                menuCardContent(
                                    icon: "questionmark.circle",
                                    title: "Help & Support",
                                    subtitle: "Common questions and contact",
                                    color: skyBlue
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 40)

                        Spacer(minLength: 15)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    func statButton(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(darkGreen)
            .fixedSize()
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(color)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(borderColor, lineWidth: 1.2)
            }
    }

    private func menuCardContent(
        icon: String,
        title: String,
        subtitle: String,
        color: Color
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(darkGreen)
                .frame(width: 58, height: 58)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(borderColor.opacity(0.8), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("Georgia-Bold", size: 20))
                    .foregroundColor(darkGreen)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(darkGreen.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 2)

            Image(systemName: "chevron.right")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(darkGreen)
        }
        .padding(.horizontal, 15)
        .frame(height: 80)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(borderColor, lineWidth: 1.2)
        }
        .shadow(
            color: darkGreen.opacity(0.04),
            radius: 6,
            x: 0,
            y: 3
        )
        .contentShape(RoundedRectangle(cornerRadius: 28))
    }
}

// MARK: - 2. Account Detail View

struct AccountDetailView: View {
    @Binding var name: String
    @Binding var age: String
    @Environment(\.dismiss) private var dismiss

    private let darkGreen = Color(red: 21.0/255, green: 83.0/255, blue: 75.0/255)
    private let lightGreen = Color(red: 232.0/255, green: 250.0/255, blue: 210.0/255)
    private let skyBlue = Color(red: 185.0/255, green: 239.0/255, blue: 250.0/255)
    private let borderColor = Color(red: 220.0/255, green: 230.0/255, blue: 228.0/255)

    @State private var draftName = ""
    @State private var draftAge = ""
    @State private var savedToast = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case name, age
    }

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()
                .ignoresSafeArea(.keyboard, edges: .all)

            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        focusedField = nil
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundColor(darkGreen)
                            .frame(width: 42, height: 42)
                            .background(.white)
                            .clipShape(Circle())
                            .shadow(
                                color: darkGreen.opacity(0.13),
                                radius: 10,
                                x: 0,
                                y: 4
                            )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.top, 4)

                HStack {
                    Text("Account")
                        .font(.custom("Georgia-Bold", size: 40))
                        .foregroundColor(darkGreen)

                    Spacer()
                }
                .padding(.top, 18)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.custom("Georgia-Bold", size: 19))
                        .foregroundColor(darkGreen)
                        .padding(.leading, 10)

                    TextField("Name", text: $draftName)
                        .font(.custom("Georgia-Bold", size: 16))
                        .foregroundColor(darkGreen)
                        .focused($focusedField, equals: .name)
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(borderColor, lineWidth: 1)
                        }
                }
                .padding(.top, 50)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Age")
                        .font(.custom("Georgia-Bold", size: 19))
                        .foregroundColor(darkGreen)
                        .padding(.leading, 10)

                    TextField("Age", text: $draftAge)
                        .font(.custom("Georgia-Bold", size: 16))
                        .foregroundColor(darkGreen)
                        .focused($focusedField, equals: .age)
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(borderColor, lineWidth: 1)
                        }
                }
                .padding(.top, 16)

                Button(action: {
                    focusedField = nil
                    let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedAge = draftAge.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedName.isEmpty { name = trimmedName }
                    if !trimmedAge.isEmpty { age = trimmedAge }
                    withAnimation { savedToast = true }
                }) {
                    HStack(spacing: 12) {
                        Text("Save changes")
                            .font(.system(size: 16, weight: .bold))

                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(darkGreen)
                    .clipShape(Capsule())
                    .shadow(
                        color: darkGreen.opacity(0.15),
                        radius: 10,
                        x: 0,
                        y: 4
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 15)

                if savedToast {
                    Text("Changes saved.")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(darkGreen)
                        .padding(.top, 10)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 150)

            VStack(spacing: 14) {
                Rectangle()
                    .fill(darkGreen.opacity(0.35))
                    .frame(height: 1.2)

                Text(
                    "Signing out takes you back to the start screen.\nYour sessions and journal stay saved."
                )
                .font(.system(size: 14))
                .foregroundColor(darkGreen.opacity(0.75))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .lineSpacing(4)

                Button(action: {
                    // Back to the start screen (ContentView watches this key). History is kept.
                    UserDefaults.standard.set(false, forKey: "utalk.onboardingComplete")
                }) {
                    HStack(spacing: 12) {
                        Text("Sign out")
                            .font(.system(size: 16, weight: .bold))

                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(darkGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.white)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .stroke(borderColor, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .onAppear {
            draftName = name
            draftAge = age
        }
    }

    private var backgroundLayer: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                Color.white

                Circle()
                    .fill(lightGreen)
                    .frame(width: 300, height: 300)
                    .position(
                        x: width * 0.95,
                        y: 45
                    )

                Circle()
                    .fill(skyBlue)
                    .frame(width: 220, height: 220)
                    .position(
                        x: -5,
                        y: height * 0.78
                    )
            }
        }
    }
}

// MARK: - 3. Settings Detail View

struct SettingsDetailView: View {
    @Environment(\.dismiss) private var dismiss

    private let darkGreen = Color(red: 21/255, green: 83/255, blue: 75/255)
    private let lightGreen = Color(red: 232/255, green: 250/255, blue: 210/255)
    private let skyBlue = Color(red: 185/255, green: 239/255, blue: 250/255)
    private let borderColor = Color(red: 215/255, green: 228/255, blue: 225/255)
    private let dividerColor = Color(red: 224/255, green: 244/255, blue: 204/255)

    // Saved between launches. "utalk.hintsEnabled" also controls the hint button in AI conversations.
    @AppStorage("utalk.dailyReminder") private var dailyReminder = true
    @AppStorage("utalk.reminderTimes") private var reminderTimesRaw = "Morning"
    @AppStorage("utalk.feedbackStyle") private var selectedFeedbackStyle = "Encouraging"
    @AppStorage("utalk.hintsEnabled") private var hintsEnabled = true
    @AppStorage("utalk.suggestedResponses") private var suggestedResponsesEnabled = false
    @AppStorage("utalk.extraThinkingTime") private var extraThinkingTimeEnabled = true

    private var selectedTimes: Set<String> {
        get { Set(reminderTimesRaw.split(separator: ",").map(String.init)) }
        nonmutating set { reminderTimesRaw = times.filter { newValue.contains($0) }.joined(separator: ",") }
    }

    private let times = ["Morning", "Afternoon", "Evening"]
    private let feedbackStyles = ["Encouraging", "Suggestions", "Both"]

    var body: some View {
        ZStack {
            backgroundView
                .ignoresSafeArea()
                .ignoresSafeArea(.keyboard, edges: .all)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    backButton
                    titleView
                    remindersSection
                    feedbackSection
                    supportSection
                    footerNote
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private var backgroundView: some View {
        GeometryReader { geo in
            ZStack {
                Color.white

                Circle()
                    .fill(lightGreen)
                    .frame(width: 300, height: 300)
                    .position(x: geo.size.width * 0.96, y: 55)

                Circle()
                    .fill(skyBlue)
                    .frame(width: 235, height: 235)
                    .position(x: 20, y: geo.size.height * 0.76)
            }
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17.5, weight: .semibold))
                .foregroundColor(darkGreen)
                .frame(width: 40, height: 40)
                .background(.white)
                .clipShape(Circle())
                .shadow(color: darkGreen.opacity(0.08), radius: 7, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    private var titleView: some View {
        Text("Settings")
            .font(.custom("Georgia-Bold", size: 36))
            .foregroundColor(darkGreen)
            .padding(.top, 20)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .tracking(1.5)
            .foregroundColor(darkGreen)
            .padding(.leading, 8)
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("REMINDERS")
                .padding(.top, 28)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Daily reminder")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(darkGreen)

                        Text("One nudge a day")
                            .font(.system(size: 13))
                            .foregroundColor(darkGreen.opacity(0.72))
                    }

                    Spacer()

                    Toggle("", isOn: $dailyReminder.animation(.easeInOut(duration: 0.22)))
                        .labelsHidden()
                        .tint(darkGreen)
                        .scaleEffect(0.92)
                }

                if dailyReminder {
                    HStack(spacing: 8) {
                        ForEach(times, id: \.self) { time in
                            let active = selectedTimes.contains(time)
                            Button {
                                if selectedTimes.contains(time) {
                                    selectedTimes.remove(time)
                                } else {
                                    selectedTimes.insert(time)
                                }
                            } label: {
                                Text(time)
                                    .font(.system(size: 13.5, weight: .semibold))
                                    .foregroundColor(active ? .white : darkGreen)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                    .padding(.horizontal, 14)
                                    .frame(height: 38)
                                    .background(Capsule().fill(active ? darkGreen : .white))
                                    .overlay(Capsule().stroke(active ? darkGreen : borderColor, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Pick the exact time for each selected reminder.
                    ReminderTimeRows(slots: ReminderSlot.allCases.filter { selectedTimes.contains($0.rawValue) },
                                     tint: darkGreen)

                    NotificationsOffNote(tint: darkGreen)
                }
            }
            .onChange(of: dailyReminder) { _, _ in
                Task { await PracticeReminders.requestAndSchedule() }
            }
            .onChange(of: reminderTimesRaw) { _, _ in
                Task { await PracticeReminders.requestAndSchedule() }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white.opacity(0.95)))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(borderColor, lineWidth: 1))
            .padding(.top, 12)
        }
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("FEEDBACK STYLE")
                .padding(.top, 30)

            HStack(spacing: 8) {
                ForEach(feedbackStyles, id: \.self) { style in
                    let active = selectedFeedbackStyle == style
                    Button {
                        selectedFeedbackStyle = style
                    } label: {
                        Text(style)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundColor(active ? .white : darkGreen)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .padding(.horizontal, 14)
                            .frame(height: 38)
                            .background(Capsule().fill(active ? darkGreen : .white))
                            .overlay(Capsule().stroke(active ? darkGreen : borderColor, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 12)
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("CONVERSATION SUPPORT")
                .padding(.top, 30)

            VStack(spacing: 0) {
                supportRow(title: "Hints", subtitle: "A nudge when you get stuck", isOn: $hintsEnabled)
                dividerLine
                supportRow(title: "Suggested responses", subtitle: "Example lines to borrow", isOn: $suggestedResponsesEnabled)
                dividerLine
                supportRow(title: "Extra thinking time", subtitle: "A slower pace before you answer", isOn: $extraThinkingTimeEnabled)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white.opacity(0.95)))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(borderColor, lineWidth: 1))
            .padding(.top, 12)
        }
    }

    private func supportRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(darkGreen)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(darkGreen.opacity(0.72))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(darkGreen)
                .scaleEffect(0.92)
        }
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(height: 1.5)
            .padding(.vertical, 13)
    }

    private var footerNote: some View {
        Text("Changes apply right away to your practice sessions.")
            .font(.system(size: 12.5))
            .foregroundColor(darkGreen.opacity(0.72))
            .padding(.leading, 8)
            .padding(.top, 16)
    }
}

// MARK: - 4. Help & Support View

private struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss

    private let darkGreen = Color(red: 21/255, green: 83/255, blue: 75/255)
    private let lightGreen = Color(red: 232/255, green: 250/255, blue: 210/255)
    private let skyBlue = Color(red: 185/255, green: 239/255, blue: 250/255)
    private let borderColor = Color(red: 215/255, green: 228/255, blue: 225/255)

    @State private var expandedIDs: Set<UUID> = []

    private let faqs: [FAQItem] = [
        FAQItem(
            question: "How does AI Conversation work?",
            answer: "Our AI works in two ways:\n\n1. Interactive Conversation: Choose a scenario and press the microphone button. The AI asks questions and you reply naturally by speaking, just like a real conversation.\n\n2. Guided Practice: Follow a written script and read it aloud while your voice is being recorded.\n\nAfter each session, you can replay your recordings, repeat exercises, and practice again to build confidence in everyday conversations."
        ),
        FAQItem(
            question: "What if I miss a day?",
            answer: "If you miss a day, your streak for that lesson resets and you can start building a new streak.\n\nYour overall progress and completed sessions remain saved, so you can return anytime and pick up right where you left off."
        ),
        FAQItem(
            question: "How is feedback worked out?",
            answer: "At the end of each session, you receive feedback showing how often you stuttered during practice.\n\nYou also get an overview of your performance and progress so you can track your improvement over time."
        )
    ]

    var body: some View {
        ZStack {
            backgroundCircles
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    backButtonView
                    titleView
                    faqSectionView
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 44)
            }
        }
    }

    private var backgroundCircles: some View {
        GeometryReader { geo in
            ZStack {
                Color.white
                Circle()
                    .fill(lightGreen)
                    .frame(width: 310, height: 310)
                    .position(x: geo.size.width * 0.96, y: 55)
                Circle()
                    .fill(skyBlue)
                    .frame(width: 245, height: 245)
                    .position(x: 10, y: geo.size.height * 0.77)
            }
        }
    }

    private var backButtonView: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(darkGreen)
                .frame(width: 42, height: 42)
                .background(.white)
                .clipShape(Circle())
                .shadow(color: darkGreen.opacity(0.08), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .padding(.top, 10)
    }

    private var titleView: some View {
        HStack(spacing: 6) {
            Text("Help")
                .font(.custom("Georgia-Bold", size: 38))
                .foregroundColor(darkGreen)
            Text("&")
                .font(.custom("Georgia", size: 34))
                .foregroundColor(darkGreen)
            Text("Support")
                .font(.custom("Georgia-Bold", size: 38))
                .foregroundColor(darkGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 8)
        .padding(.top, 22)
    }

    private var faqSectionView: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("COMMON QUESTIONS")
                .font(.custom("Georgia-Bold", size: 12.5))
                .tracking(1.4)
                .foregroundColor(darkGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
                .padding(.top, 52)

            ForEach(faqs) { item in
                faqCard(for: item)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func faqCard(for item: FAQItem) -> some View {
        let isOpen = expandedIDs.contains(item.id)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    if isOpen {
                        expandedIDs.remove(item.id)
                    } else {
                        expandedIDs.insert(item.id)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Text(item.question)
                        .font(.custom("Georgia-Bold", size: 16))
                        .foregroundColor(darkGreen)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isOpen ? "minus" : "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(darkGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .frame(minHeight: 66)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isOpen {
                Divider()
                    .background(borderColor.opacity(0.8))
                    .padding(.horizontal, 18)

                Text(item.answer)
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(darkGreen.opacity(0.88))
                    .lineSpacing(6.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.white.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Shared Components

struct SealShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.48
        let scallops = 12
        let steps = scallops * 2

        for i in 0...steps {
            let angle = (Double(i) / Double(steps)) * .pi * 2
            let r = (i % 2 == 0) ? radius : radius * 0.88
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * r,
                y: center.y + CGFloat(sin(angle)) * r
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    NavigationStack { ProfileMenuView() }
}
