//
//  ContentView.swift
//  ConverterApp
//
//  Created by Murat Menzilci on 15.12.2023.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var locations: [Location] {
        didSet {
            saveLocations()
        }
    }

    @State private var showingSettings = false
    @State private var showingLocationsList = false
    @State private var showingEditAlert = false
    @State private var editingLocationIndex: Int?
    @State private var newLocationName = ""
    @State private var editMode = EditMode.inactive  // State for edit mode
    @StateObject private var userSettings = UserSettings()
    @AppStorage("showTimeZoneNames") private var showTimeZoneNames = false

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
                }
            )
            .environment(\.editMode, $editMode)  // Bind editMode
            .sheet(isPresented: $showingSettings) {
                SettingsView(userSettings: userSettings)
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

    private var locationRows: some View {
        ForEach(locations.indices, id: \.self) { index in
            HStack {
                Image(systemName: locations[index].isDayTime ? "sun.max.fill" : "moon.stars.fill")
                Text(locations[index].name)
                Spacer()
                Text(locations[index].formattedTime(is24HourFormat: userSettings.is24HourFormat))
                    .font(.title)
                    .bold()
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


struct Location: Codable {
    var name: String
    var timeZone: TimeZone
    
    func formattedTime(is24HourFormat: Bool) -> String {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = is24HourFormat ? "HH:mm" : "h:mm a"
        return dateFormatter.string(from: Date())
    }
    
    var timeZoneAbbreviation: String {
        timeZone.abbreviation() ?? ""
    }
    
    var isDayTime: Bool {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: Date())
        return hour >= 6 && hour < 18    }

    var currentTime: String {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: Date())
        let minute = calendar.component(.minute, from: Date())

        let is24HourFormat = UserDefaults.standard.bool(forKey: "is24HourFormat")
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = is24HourFormat ? "HH:mm" : "h:mm a"

        return dateFormatter.string(from: Date())
    }

    // Custom CodingKeys to exclude properties that should not be encoded/decoded
    enum CodingKeys: String, CodingKey {
        case name
        case timeZone
    }

    // Custom initializer for decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let timeZoneIdentifier = try container.decode(String.self, forKey: .timeZone)
        timeZone = TimeZone(identifier: timeZoneIdentifier) ?? TimeZone.current
    }

    // Custom method for encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(timeZone.identifier, forKey: .timeZone)
    }

    // Standard initializer
    init(name: String, timeZone: TimeZone) {
        self.name = name
        self.timeZone = timeZone
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


