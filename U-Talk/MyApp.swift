import SwiftUI

@main struct MyApp: App {
    init() {
        // Demo mode: start fresh on every launch (see AppReset.swift). Set the flag to false for real users.
        if AppReset.resetOnEveryLaunch { AppReset.resetAllData() }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}
