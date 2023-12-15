//
//  LocationsList.swift
//  ConverterApp
//
//  Created by Murat Menzilci on 15.12.2023.
//

import SwiftUI
import CoreLocation

struct LocationsList: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var locationManager: LocationManager
    @State private var searchText = ""
    @State private var showingPermissionAlert = false
    let addLocation: (Location) -> Void

    // Predefined list of popular cities
    let popularCities: [City] = [
        City(name: "Current Location", timeZoneIdentifier: "TimeZone.current"),
        City(name: "New York", timeZoneIdentifier: "America/New_York"),
        City(name: "London", timeZoneIdentifier: "Europe/London"),
        City(name: "Tokyo", timeZoneIdentifier: "Asia/Tokyo"),
        City(name: "Paris", timeZoneIdentifier: "Europe/Paris"),
        City(name: "Sydney", timeZoneIdentifier: "Australia/Sydney"),
        City(name: "Dubai", timeZoneIdentifier: "Asia/Dubai"),
        City(name: "Los Angeles", timeZoneIdentifier: "America/Los_Angeles"),
        City(name: "Singapore", timeZoneIdentifier: "Asia/Singapore"),
        City(name: "Hong Kong", timeZoneIdentifier: "Asia/Hong_Kong"),
        City(name: "Berlin", timeZoneIdentifier: "Europe/Berlin")
    ]

    let timeZones = TimeZone.knownTimeZoneIdentifiers

    // Filtered list of time zones based on search text
    var filteredTimeZones: [String] {
        if searchText.isEmpty {
            return timeZones
        } else {
            return timeZones.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            List {
                SearchBar(text: $searchText)

                Section(header: Text("Popular Cities")) {
                    ForEach(popularCities, id: \.name) { city in
                        Button(action: {
                            if city.name == "Current Location" {
                                handleCurrentLocationSelection()
                            } else {
                                addCityLocation(city: city)
                            }
                        }) {
                            Text(city.name)
                        }
                    }
                }

                Section(header: Text("All Time Zones")) {
                    ForEach(filteredTimeZones, id: \.self) { timeZoneIdentifier in
                        Button(action: {
                            let newLocation = Location(name: timeZoneIdentifier, timeZone: TimeZone(identifier: timeZoneIdentifier) ?? TimeZone.current)
                            addLocation(newLocation)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text(timeZoneIdentifier)
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Time Zones"), displayMode: .inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            ).alert(isPresented: $showingPermissionAlert) {
                Alert(title: Text("Permission Required"),
                      message: Text("You need to give permission to view your current location."),
                      primaryButton: .default(Text("Yes"), action: {
                          print("asked")
                    DispatchQueue.main.async {
                        locationManager.requestAuthorization()
                    }
                      }),
                      secondaryButton: .cancel()
                )
            }
        }
    }
    
    
    
    private func handleCurrentLocationSelection() {
        if locationManager.locationPermissionGranted {
            addCurrentLocation()
        } else {
            showingPermissionAlert = true
        }
    }
    

    private func addCurrentLocation() {
        let newLocation = Location(name: "Current Location", timeZone: TimeZone.current)
        addLocation(newLocation)
        presentationMode.wrappedValue.dismiss()
    }

    private func addCityLocation(city: City) {
        let newLocation = Location(name: city.name, timeZone: TimeZone(identifier: city.timeZoneIdentifier) ?? TimeZone.current)
        addLocation(newLocation)
        presentationMode.wrappedValue.dismiss()
    }
    
}


struct City {
    var name: String
    var timeZoneIdentifier: String
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            TextField("Search", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)

                        if !text.isEmpty {
                            Button(action: { self.text = "" }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
        }
    }
}


struct LocationsList_Previews: PreviewProvider {
    static var previews: some View {
        LocationsList(locationManager: LocationManager(), addLocation: { _ in })
    }
}
