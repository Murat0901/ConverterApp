//
//  ConverterAppApp.swift
//  ConverterApp
//
//  Created by Murat Menzilci on 15.12.2023.
//

import SwiftUI

@main
struct ConverterAppApp: App {
    @State private var hasShownOnboarding = UserDefaults.standard.bool(forKey: UserDefaults.hasShownOnboardingKey)

    var body: some Scene {
        WindowGroup {
            if hasShownOnboarding {
                ContentView()
            } else {
                OnboardingView(showOnboarding: $hasShownOnboarding)
            }
        }
    }
}

extension UserDefaults {
    static let hasShownOnboardingKey = "hasShownOnboarding"
}
