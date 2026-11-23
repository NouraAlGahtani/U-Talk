import SwiftUI
import UIKit
import UserNotifications
import AVFoundation
import Speech

// Daily practice reminders, themed to the next roadmap lesson (local notifications, scheduled on the iPhone; nothing goes through a server)
// and the microphone / speech permission request used by onboarding.
//
// Saved settings (shared by onboarding NotificationsView and Profile → Settings):
//   "utalk.dailyReminder"            Bool   reminders on/off (default on)
//   "utalk.reminderTimes"            String selected slots, e.g. "Morning,Evening"
//   "utalk.reminderTime.<Slot>"      Int    minutes after midnight the user picked for that slot

enum ReminderSlot: String, CaseIterable, Identifiable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"

    var id: String { rawValue }

    var defaultMinutes: Int {
        switch self {
        case .morning: return 8 * 60
        case .afternoon: return 13 * 60
        case .evening: return 19 * 60
        }
    }

    var timeKey: String { "utalk.reminderTime.\(rawValue)" }
    var notificationID: String { "utalk.reminder.\(rawValue)" }
}

enum PracticeReminders {
    static let enabledKey = "utalk.dailyReminder"
    static let slotsKey = "utalk.reminderTimes"

    // MARK: Settings

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    static var selectedSlots: [ReminderSlot] {
        let raw = UserDefaults.standard.string(forKey: slotsKey) ?? "Morning"
        let names = Set(raw.split(separator: ",").map(String.init))
        return ReminderSlot.allCases.filter { names.contains($0.rawValue) }
    }

    static func minutes(for slot: ReminderSlot) -> Int {
        UserDefaults.standard.object(forKey: slot.timeKey) as? Int ?? slot.defaultMinutes
    }

    static func setTime(_ date: Date, for slot: ReminderSlot) {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        UserDefaults.standard.set((parts.hour ?? 0) * 60 + (parts.minute ?? 0), forKey: slot.timeKey)
    }

    static func time(for slot: ReminderSlot) -> Date {
        let m = minutes(for: slot)
        return Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Date()) ?? Date()
    }

    /// e.g. "8:00 AM" (follows the iPhone's 12/24-hour setting)
    static func timeText(for slot: ReminderSlot) -> String {
        time(for: slot).formatted(date: .omitted, time: .shortened)
    }

    // MARK: Scheduling

    /// Asks for notification permission (iOS only shows the prompt the first time), then schedules.
    @discardableResult
    static func requestAndSchedule() async -> Bool {
        guard isEnabled, !selectedSlots.isEmpty else {
            await reschedule()
            return false
        }
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await reschedule()
        return granted
    }

    /// Replaces the scheduled reminders with the current settings. Call after any change to the
    /// reminder settings and when the roadmap moves to a new day (the text names today's lesson).
    static func reschedule() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ReminderSlot.allCases.map(\.notificationID))

        guard isEnabled else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        for slot in selectedSlots {
            let message = reminderMessage(for: slot)
            let content = UNMutableNotificationContent()
            content.title = message.title
            content.body = message.body
            // Custom sound (utalk_reminder.wav in the app bundle); iOS uses the default sound if it's missing.
            content.sound = UNNotificationSound(named: UNNotificationSoundName("utalk_reminder.wav"))

            let m = minutes(for: slot)
            let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: m / 60, minute: m % 60),
                                                        repeats: true)
            let request = UNNotificationRequest(identifier: slot.notificationID, content: content, trigger: trigger)
            do {
                try await center.add(request)
            } catch {
                print("[U-TALK reminders] Could not schedule \(slot.rawValue): \(error)")
            }
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private static var displayName: String {
        let name = (UserDefaults.standard.string(forKey: "userName") ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "friend" : name
    }

    /// Reminder text themed to the next roadmap lesson, with a different line for each time of day.
    static func reminderMessage(for slot: ReminderSlot) -> (title: String, body: String) {
        let defaults = UserDefaults.standard
        let name = displayName
        let completed = defaults.integer(forKey: PracticeProgress.completedDaysKey)
        guard completed < PracticeProgress.totalDays else {
            return ("Roadmap complete, \(name)! 🏆", "Keep your voice warm with a quick practice. Any scenario you like.")
        }
        let day = completed + 1
        let lesson = RoadmapPlan.lesson(day: day, focus: defaults.string(forKey: RoadmapPlan.focusKey) ?? "")
        let footer = "Day \(day) · about \(lesson.minutes) min"

        // [morning, afternoon, evening]
        let lines: [(title: String, body: String)]
        switch lesson.scenarioID {
        case "restaurant":
            lines = [("Breakfast order, \(name)? ☕", "Your AI waiter is setting the table. Practice ordering. \(footer)"),
                     ("Lunch rush! 🍔", "The waiter is ready to take your order. \(footer)"),
                     ("Table for one, \(name)? 🍝", "Order dinner with your AI waiter tonight. \(footer)")]
        case "airport":
            lines = [("Flight check-in is open ✈️", "Your gate agent is waiting, \(name). Practice checking in. \(footer)"),
                     ("Now boarding: practice time 🛫", "Check your bag and ask about your gate. \(footer)"),
                     ("Last call, \(name)! ✈️", "A quick airport check-in before bed. \(footer)")]
        case "interview":
            lines = [("Your interview is this morning 💼", "Rehearse your answers with the AI interviewer, \(name). \(footer)"),
                     ("The interviewer will see you now 💼", "Talk about your strengths. \(footer)"),
                     ("Interview prep, \(name)? 🌙", "A few calm answers before the day ends. \(footer)")]
        case "presentation":
            lines = [("The stage is yours, \(name) 🎤", "Practice presenting your idea this morning. \(footer)"),
                     ("Slides ready? 📊", "Your audience is waiting. Present your idea. \(footer)"),
                     ("One more run-through 🎤", "Present your idea, slow and steady. \(footer)")]
        case "phone-call":
            lines = [("Ring ring, \(name)! 📞", "Someone's waiting on the line. Practice your call. \(footer)"),
                     ("You have a call to make 📞", "Explain what you need, at your own pace. \(footer)"),
                     ("Quick call before the day ends? 📱", "Your support agent is ready. \(footer)")]
        case "appointment":
            lines = [("Time to book that appointment 📅", "The receptionist is ready, \(name). \(footer)"),
                     ("Let's find a time that works 🗓️", "Practice booking and confirming. \(footer)"),
                     ("Booking before bed? 📅", "A short call to set up your appointment. \(footer)")]
        default: // about-you (Introducing Yourself, Small Talk)
            lines = [("Good morning, \(name)! ☀️", "\(lesson.title): tell U a little about yourself. \(footer)"),
                     ("Got a minute to chat? 👋", "\(lesson.title) is ready for you. \(footer)"),
                     ("Evening chat, \(name)? 🌙", "Relax and talk about your day. \(footer)")]
        }

        switch slot {
        case .morning: return lines[0]
        case .afternoon: return lines[1]
        case .evening: return lines[2]
        }
    }
}

// MARK: - Microphone + speech permission

enum PracticePermissions {
    /// Shows the iOS microphone prompt, then the speech recognition prompt (each only the first time).
    @discardableResult
    static func requestMicrophoneAndSpeech() async -> Bool {
        let micAllowed = await AVAudioApplication.requestRecordPermission()
        let speechAllowed = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        return micAllowed && speechAllowed
    }

    static func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Time pickers (used in onboarding and in Settings)

/// One row per selected slot, each with a time picker. Changing a time reschedules the reminders.
struct ReminderTimeRows: View {
    let slots: [ReminderSlot]
    var tint: Color = UTalk.forest

    var body: some View {
        VStack(spacing: 8) {
            ForEach(slots) { slot in
                HStack {
                    Text(slot.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(tint)
                    Spacer()
                    DatePicker(slot.rawValue,
                               selection: Binding(
                                get: { PracticeReminders.time(for: slot) },
                                set: { newValue in
                                    PracticeReminders.setTime(newValue, for: slot)
                                    Task { await PracticeReminders.reschedule() }
                                }),
                               displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(tint)
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(tint.opacity(0.15), lineWidth: 1))
            }
        }
    }
}

/// Shown in Settings when reminders are on but notifications are turned off for U-Talk in iOS Settings.
struct NotificationsOffNote: View {
    var tint: Color = UTalk.forest
    @State private var denied = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if denied {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notifications are turned off for U-Talk, so reminders can't appear.")
                        .font(.system(size: 13))
                        .foregroundStyle(tint)
                    Button("Open iPhone Settings") { PracticePermissions.openAppSettings() }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(tint)
                        .underline()
                }
            }
        }
        .task { await refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refresh() } }
        }
    }

    private func refresh() async {
        denied = await PracticeReminders.authorizationStatus() == .denied
        if !denied { await PracticeReminders.reschedule() }
    }
}
