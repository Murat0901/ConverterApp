//
//  MeetingSchedulerView.swift
//  ConverterApp
//
//  Created by Murat Menzilci on 16.12.2023.
//

import SwiftUI
import EventKit
import EventKitUI

struct MeetingSchedulerView: View {
    @AppStorage("is24HourFormat") private var is24HourFormat = false
    @State private var timeZones: [TimeZoneItem] = [
        TimeZoneItem(name: "Local", timeZone: .current),
        TimeZoneItem(name: "New York", timeZone: TimeZone(identifier: "America/New_York")!),
        TimeZoneItem(name: "London", timeZone: TimeZone(identifier: "Europe/London")!),
        TimeZoneItem(name: "Tokyo", timeZone: TimeZone(identifier: "Asia/Tokyo")!)
    ]
    @State private var selectedTime = Date()
    @State private var showingAddTimeZone = false
    @State private var showingEventEditView = false
    @State private var eventStore = EKEventStore()

    var body: some View {
        NavigationView {
            List {
                DatePicker("Select Time", selection: $selectedTime, displayedComponents: [.date, .hourAndMinute])

                ForEach(timeZones) { timeZoneItem in
                    HStack {
                        Text(timeZoneItem.name)
                        Spacer()
                        Text(timeZoneItem.formattedTime(for: selectedTime, is24HourFormat: is24HourFormat))
                    }
                }
                .onDelete(perform: deleteTimeZone)

                Button("Add Time Zone") {
                    showingAddTimeZone = true
                }

                Button("Schedule a Meeting") {
                    requestAccessAndShowEventEditView()
                }
            }
            .navigationBarTitle("Meeting Scheduler")
            .sheet(isPresented: $showingAddTimeZone) {
                AddTimeZoneView { newTimeZone in
                    self.timeZones.append(newTimeZone)
                }
            }
            .sheet(isPresented: $showingEventEditView) {
                EventEditView(eventStore: eventStore, event: createEvent())
            }
        }
    }

    private func updateTimeZones(to newTime: Date) {
        for i in 0..<timeZones.count {
            let difference = Calendar.current.dateComponents([.hour, .minute], from: timeZones[i].selectedTime, to: newTime)
            if let adjustedTime = Calendar.current.date(byAdding: difference, to: timeZones[i].selectedTime) {
                timeZones[i].selectedTime = adjustedTime
            }
        }
    }

    private func deleteTimeZone(at offsets: IndexSet) {
        timeZones.remove(atOffsets: offsets)
    }

    private func requestAccessAndShowEventEditView() {
        eventStore.requestAccess(to: .event) { granted, error in
            if granted && error == nil {
                DispatchQueue.main.async {
                    self.showingEventEditView = true
                }
            } else {
                // Handle the error or lack of permissions
            }
        }
    }

    private func createEvent() -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = "Scheduled Meeting"
        event.startDate = selectedTime  // Use the selected date and time directly
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: selectedTime)  // End date is 1 hour after start date
        return event
    }

}

struct AddTimeZoneView: View {
    var addTimeZone: (TimeZoneItem) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTimeZoneIdentifier = TimeZone.current.identifier

    let popularCities: [PopularCity] = [
        PopularCity(name: "New York", timeZoneIdentifier: "America/New_York"),
        PopularCity(name: "London", timeZoneIdentifier: "Europe/London"),
        PopularCity(name: "Tokyo", timeZoneIdentifier: "Asia/Tokyo"),
        PopularCity(name: "Paris", timeZoneIdentifier: "Europe/Paris"),
        PopularCity(name: "Sydney", timeZoneIdentifier: "Australia/Sydney"),
        PopularCity(name: "Dubai", timeZoneIdentifier: "Asia/Dubai"),
        PopularCity(name: "Los Angeles", timeZoneIdentifier: "America/Los_Angeles"),
        PopularCity(name: "Singapore", timeZoneIdentifier: "Asia/Singapore"),
        PopularCity(name: "Hong Kong", timeZoneIdentifier: "Asia/Hong_Kong"),
        PopularCity(name: "Berlin", timeZoneIdentifier: "Europe/Berlin")
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Popular Cities")) {
                    ForEach(popularCities, id: \.name) { city in
                        Button(action: {
                            addTimeZone(TimeZoneItem(name: city.name, timeZone: TimeZone(identifier: city.timeZoneIdentifier) ?? TimeZone.current))
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text(city.name)
                        }
                    }
                }

                Section(header: Text("All Time Zones")) {
                    Picker("Select Time Zone", selection: $selectedTimeZoneIdentifier) {
                        ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { identifier in
                            Text(identifier).tag(identifier)
                        }
                    }

                    Button("Add") {
                        if let timeZone = TimeZone(identifier: selectedTimeZoneIdentifier) {
                            addTimeZone(TimeZoneItem(name: selectedTimeZoneIdentifier, timeZone: timeZone))
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .navigationBarTitle("Add Time Zone")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}


struct PopularCity {
    var name: String
    var timeZoneIdentifier: String
}


struct TimeZoneItem: Identifiable {
    let id = UUID()
    var name: String
    var timeZone: TimeZone
    var selectedTime: Date = Date()

    func formattedTime(for time: Date, is24HourFormat: Bool) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = is24HourFormat ? "HH:mm" : "h:mm a"
        return formatter.string(from: time)
    }
}

struct EventEditView: UIViewControllerRepresentable {
    let eventStore: EKEventStore
    let event: EKEvent

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let viewController = EKEventEditViewController()
        viewController.eventStore = eventStore
        viewController.event = event
        return viewController
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {
        // No update needed
    }
}

struct MeetingSchedulerView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingSchedulerView()
    }
}
