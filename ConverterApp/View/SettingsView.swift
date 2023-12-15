//
//  SettingsView.swift
//  ConverterApp
//
//  Created by Murat Menzilci on 15.12.2023.
//

import SwiftUI
import StoreKit

struct SettingsView: View {
    @AppStorage("is24HourFormat") private var is24HourFormat = false
    @AppStorage("showTimeZoneNames") private var showTimeZoneNames = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @ObservedObject var userSettings: UserSettings

    var body: some View {
        NavigationView {
            Form {
                Toggle(isOn: $userSettings.is24HourFormat) {
                    Text("Change Time Format (24-Hour)")
                }

                Toggle(isOn: $showTimeZoneNames) {
                    Text("Show Time Zone Names")
                }

                Button(action: {
                    // Code to leave a review
                    if let windowScene = UIApplication.shared.windows.first?.windowScene {
                        SKStoreReviewController.requestReview(in: windowScene)
                    }
                }) {
                    Text("Leave a Review")
                }

                Toggle(isOn: $isDarkMode) {
                    Text("Dark Mode")
                }
                .onChange(of: isDarkMode) { newValue in
                    UIApplication.shared.windows.first?.overrideUserInterfaceStyle = newValue ? .dark : .light
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

class UserSettings: ObservableObject {
    @Published var is24HourFormat: Bool {
        didSet {
            UserDefaults.standard.set(is24HourFormat, forKey: "is24HourFormat")
        }
    }

    init() {
        // Load the initial value from UserDefaults
        self.is24HourFormat = UserDefaults.standard.bool(forKey: "is24HourFormat")
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView(userSettings: UserSettings())
        }
    }
}
