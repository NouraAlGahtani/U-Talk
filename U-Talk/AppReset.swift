import Foundation
import UserNotifications

/// Demo / testing mode: every launch starts like a brand-new install.
///
/// Clears the name, onboarding answers, roadmap progress, settings, practice history and scheduled reminders.
///
/// It cannot bring back the iPhone's own permission pop-ups (microphone, speech recognition, notifications):
/// iOS shows each of those only once per install. To see them again, delete the app from the iPhone and run it
/// from Xcode again.
///
/// ⚠️ Set `resetOnEveryLaunch` to false before giving the app to real users, or they'll lose their progress.
enum AppReset {
    static let resetOnEveryLaunch = false

    static func resetAllData() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        SessionHistory.clearAll()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        // Tells ContentView (which watches this key) to return to onboarding.
        UserDefaults.standard.set(false, forKey: "utalk.onboardingComplete")
    }
}
