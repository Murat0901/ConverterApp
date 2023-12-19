//
//  ContentView.swift
//  ConverterApp
//
//  Created by Murat Menzilci on 15.12.2023.
//

import SwiftUI
import CoreLocation
import StoreKit

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @AppStorage("isOnboardingViewShowing") var isOnboardingViewShowing = true
    @AppStorage("isFirstLaunch") var isFirstLaunch: Bool = true
    @State private var onboardingPageIndex: Int = 0
    let onboardingPages: [(imageName: String, title: String, description: String)] = [
        ("onboarding-1", "Welcome to Time Zone Converter", "Easily convert times across different time zones."),
        ("onboarding-2", "Stay Organized", "Manage international meetings and calls with ease."),
        ("onboarding-3", "Help Us Grow", "Give us 5 stars to support us! We really appreciate your support!")
    ]

    var body: some View {
        if isOnboardingViewShowing {
            ZStack {
                VStack {
                    OnboardingScreen(imageName: onboardingPages[onboardingPageIndex].imageName, title: onboardingPages[onboardingPageIndex].title, description: onboardingPages[onboardingPageIndex].description)
                    Spacer() // Push the button to the bottom
                }
                
                VStack {
                    Spacer()
                    Button(action: {
                        if onboardingPageIndex == 1 {
                            // Request rating when the second "Continue" button is clicked
                            if let scene = UIApplication.shared.windows.first?.windowScene {
                                SKStoreReviewController.requestReview(in: scene)
                            }
                        }

                        if onboardingPageIndex < onboardingPages.count - 1 {
                            onboardingPageIndex += 1
                        } else {
                            self.showOnboarding = false
                             UserDefaults.standard.set(false, forKey: "isOnboardingViewShowing")
                                if isFirstLaunch {
                                // Trigger campaign and show paywall here
                                /*
                                 Superwall.shared.register(event: "campaign_trigger")
                                 isFirstLaunch = false
                                 */
                                // Add code to show the paywall
                            }
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Continue")
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 15) // Vertical padding for button height
                        .background(Color.blue) // Background color of the button
                    }
                    .cornerRadius(10)
                    .padding(.horizontal, 15) // Horizontal padding for space from the sides
                    .padding(.bottom, 35) // Add padding at the bottom
                }


            }
            .background(Color.black.ignoresSafeArea())
            .foregroundColor(Color.primary)
            .navigationBarHidden(true)
            .onAppear{
                 //ATT
                /*
                 DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                     if #available(iOS 14, *) {
                         ATTrackingManager.requestTrackingAuthorization { (status) in
                             //print("IDFA STATUS: \(status.rawValue)")
                         }
                     }
                 
                 
                 DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                     fetchUserSubscriptionStatus()
                 }
                 */
            }
        } else {
            ContentView()
        }
    }

    /*
     func fetchUserSubscriptionStatus() {
         Purchases.shared.getCustomerInfo { (purchaserInfo, error) in
             guard let proEntitlement = purchaserInfo?.entitlements["pro"], proEntitlement.isActive else {
                 return
             }
         }
     }
     */
}

struct OnboardingScreen: View {
    var imageName: String
    var title: String
    var description: String

    var body: some View {
        VStack(spacing: 20) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: UIScreen.main.bounds.height / 3)
                .padding()
            Text(title)
                .font(.largeTitle)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text(description)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .padding(.top, 50)
    }
}

struct ContentView: View {
    @State private var showOnboarding = UserDefaults.standard.bool(forKey: "isOnboardingViewShowing")
    @State private var selectedTime: Date = Date()
    @StateObject private var locationManager = LocationManager()
    @State private var locations: [Location]
    @State private var showingMeetingSchedulerView = false
    @State private var showingSettings = false
    @State private var showingLocationsList = false
    @State private var showingEditAlert = false
    @State private var editingLocationIndex: Int?
    @State private var newLocationName = ""
    @State private var editMode = EditMode.inactive
    @StateObject private var userSettings = UserSettings()
    @AppStorage("showTimeZoneNames") private var showTimeZoneNames = false
    @AppStorage("is24HourFormat") private var is24HourFormat = false


    init() {
        if let savedLocations = UserDefaults.standard.object(forKey: "SavedLocations") as? Data,
           let decodedLocations = try? JSONDecoder().decode([Location].self, from: savedLocations) {
            _locations = State(initialValue: decodedLocations)
        } else {
            _locations = State(initialValue: [
                Location(name: "London", timeZone: TimeZone(identifier: "Europe/London")!),
                Location(name: "New York", timeZone: TimeZone(identifier: "America/New_York")!),
                Location(name: "Tokyo", timeZone: TimeZone(identifier: "Asia/Tokyo")!)
            ])
        }
    }
    
    var body: some View {
        if showOnboarding {
            OnboardingView(showOnboarding: $showOnboarding)
        } else {
            NavigationView {
                List {
                    // Show permission denied button only if location permission is denied
                    if locationManager.locationPermissionDenied && locations.first?.name == "Current Location" {
                        Button("Please allow your location usage") {
                            DispatchQueue.main.async {
                                locationManager.requestAuthorization()
                            }
                        }
                    }
                    
                    TimelineView(selectedTime: $selectedTime, is24HourFormat: is24HourFormat) // Pass is24HourFormat here
                        .frame(height: 60) // Set the height for the ScrollView
                        .onChange(of: selectedTime) { newTime in
                            updateLocationsTimes(to: newTime)
                        }
                    
                    Button(action: resetToCurrentTime) {
                        Text("Reset to Current Time")
                            .foregroundColor(.blue) // Use your theme color here
                            .font(.subheadline) // Smaller font size
                            .multilineTextAlignment(.center) // Center-align the text
                    }
                    .padding(.vertical, 4)
                    
                    // List of locations. Always displayed regardless of location permission status.
                    ForEach(locations.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: locations[index].isDayTime ? "sun.max.fill" : "moon.stars.fill")
                            Text(locations[index].name)
                            Spacer()
                            Text(locations[index].currentTime)
                                .font(.title)
                                .bold()
                            if showTimeZoneNames {
                                Text(locations[index].timeZoneAbbreviation)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 8)
                        .swipeActions {
                            Button(role: .none) {
                                editingLocationIndex = index
                                newLocationName = locations[index].name
                                showingEditAlert = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                            
                            Button(role: .destructive) {
                                delete(at: index)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onMove(perform: move)
                }
                .navigationBarTitle("Time Zones")
                .navigationBarItems(
                    leading: Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    },
                    trailing: HStack {
                        if locations.count > 1 {
                            EditButton()  // Add an EditButton to enable list editing
                        }
                        Button(action: {
                            showingLocationsList = true
                        }) {
                            Image(systemName: "plus")
                        }
                        Button(action: {
                            showingMeetingSchedulerView = true
                        }) {
                            Image(systemName: "calendar.badge.plus")
                        }
                    }
                )
                .environment(\.editMode, $editMode)  // Bind editMode
                .sheet(isPresented: $showingSettings) {
                    SettingsView(userSettings: userSettings)
                }
                .sheet(isPresented: $showingMeetingSchedulerView) {
                    MeetingSchedulerView()
                }
                .sheet(isPresented: $showingLocationsList) {
                    LocationsList(locationManager: locationManager, addLocation: { newLocation in
                        if newLocation.name == "Current Location" {
                            if locationManager.locationPermissionGranted {
                                self.locations.append(newLocation)
                            } else if !locationManager.locationPermissionDenied {
                                print("permission asked")
                                locationManager.requestAuthorization()
                            } // No action if permission is explicitly denied
                        } else {
                            self.locations.append(newLocation)
                        }
                    })
                }
                .alert("Edit Location", isPresented: $showingEditAlert) {
                    TextField("Enter new location name", text: $newLocationName)
                    Button("Save") {
                        if let index = editingLocationIndex {
                            editLocation(at: index, newName: newLocationName)
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Enter a new name for the location.")
                }
            }
        }
    }
    
    private func resetToCurrentTime() {
            selectedTime = Date()
            updateLocationsTimes(to: Date())
        }
    
    private func updateLocationsTimes(to newTime: Date) {
        for i in 0..<locations.count {
            locations[i].updateSelectedDate(newDate: newTime, is24HourFormat: is24HourFormat)
        }
    }
    
    private var locationRows: some View {
        ForEach($locations.indices, id: \.self) { index in
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: locations[index].isDayTime ? "sun.max.fill" : "moon.stars.fill")
                        .font(.system(size: 30))
                    Text(locations[index].name)
                    Spacer()
                    Text(locations[index].currentTime)
                        .font(.title)
                        .bold()
                }

                if showTimeZoneNames {
                    Text(locations[index].timeZoneAbbreviation)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 32) // Align with location name
                }
            }
            .padding(.vertical, 8)
            .swipeActions {
                Button(role: .none) {
                    editingLocationIndex = index
                    newLocationName = locations[index].name
                    showingEditAlert = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)

                Button(role: .destructive) {
                    delete(at: index)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .onMove(perform: move)
    }

    private func editLocation(at index: Int, newName: String) {
        locations[index].name = newName
    }

    func delete(at index: Int) {
        locations.remove(at: index)
    }

    func move(from source: IndexSet, to destination: Int) {
        locations.move(fromOffsets: source, toOffset: destination)
    }
    
    private func saveLocations() {
        if let encoded = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(encoded, forKey: "SavedLocations")
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var locationPermissionDenied = false
    @Published var locationPermissionGranted = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    
    func requestAuthorization() {
        DispatchQueue.main.async {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationPermissionDenied = false
            locationPermissionGranted = true
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            locationPermissionDenied = true
            locationPermissionGranted = false
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates
    }
    
}


struct Location: Codable, Identifiable {
    let id = UUID()
    var name: String
    var timeZone: TimeZone
    var selectedDate: Date

    init(name: String, timeZone: TimeZone, selectedDate: Date = Date()) {
        self.name = name
        self.timeZone = timeZone
        self.selectedDate = selectedDate
    }

    var currentTime: String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: selectedDate)
    }

    var timeZoneAbbreviation: String {
        timeZone.abbreviation() ?? ""
    }

    var isDayTime: Bool {
        let adjustedDate = selectedDate.adjusted(to: timeZone)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: adjustedDate)
        return hour >= 6 && hour < 18
    }

    mutating func updateSelectedDate(newDate: Date, is24HourFormat: Bool) {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        if is24HourFormat {
            calendar.locale = Locale(identifier: "en_GB")
        } else {
            calendar.locale = Locale(identifier: "en_US")
        }
        if let newTime = calendar.date(bySettingHour: calendar.component(.hour, from: newDate), minute: calendar.component(.minute, from: newDate), second: 0, of: selectedDate) {
            self.selectedDate = newTime
        }
    }

    // Implement the necessary Codable protocol methods
    enum CodingKeys: String, CodingKey {
        case name
        case timeZone
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let timeZoneIdentifier = try container.decode(String.self, forKey: .timeZone)
        timeZone = TimeZone(identifier: timeZoneIdentifier) ?? TimeZone.current
        selectedDate = Date() // Initialize with current date
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(timeZone.identifier, forKey: .timeZone)
    }
}


struct TimelineView: View {
    @Binding var selectedTime: Date
    var is24HourFormat: Bool
    let timeIncrements = generateTimeIncrements()

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(timeIncrements, id: \.self) { time in
                    TimeSlotView(time: time, isSelected: isSelectedTime(time), is24HourFormat: is24HourFormat)
                        .onTapGesture {
                            self.selectedTime = time
                        }
                }
            }
        }
    }

    private func isSelectedTime(_ time: Date) -> Bool {
        return Calendar.current.isDate(selectedTime, equalTo: time, toGranularity: .minute)
    }

    private static func generateTimeIncrements() -> [Date] {
        // Generate time increments for the next 24 hours in 15-minute intervals
        var times: [Date] = []
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date()) // Start at the beginning of the current day
        for i in 0..<96 { // 96 increments for 24 hours
            if let time = calendar.date(byAdding: .minute, value: i * 15, to: startDate) {
                times.append(time)
            }
        }
        return times
    }
}

// Extension to adjust a date to a specific timezone
extension Date {
    func adjusted(to timeZone: TimeZone) -> Date {
        let seconds = TimeInterval(timeZone.secondsFromGMT(for: self))
        return self.addingTimeInterval(seconds)
    }
}

struct TimeSlotView: View {
    let time: Date
    let isSelected: Bool
    var is24HourFormat: Bool

    var body: some View {
        Text(formatTime(time))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(8)
            .foregroundColor(isSelected ? Color.white : Color.primary)
            .overlay(
                isSelected ? RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 3) : nil
            )
            .animation(.easeInOut, value: isSelected)
            .transition(.scale)
    }

    private func formatTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = is24HourFormat ? "HH:mm" : "h:mm a"
        return formatter.string(from: time)
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
