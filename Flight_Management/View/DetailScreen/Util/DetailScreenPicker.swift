import SwiftUI

enum DetailTripTab: String, CaseIterable, Hashable {
    case detail = "Detail"
    case tripHistory = "Trips"
}

enum DetailAirportTab: String, CaseIterable, Hashable {
    case detail = "Detail"
    case legDetail = "Leg"
}

func detailScreenPicker<T>(selectedTab: Binding<T>) -> some View
where T: CaseIterable & Hashable & RawRepresentable, T.RawValue == String {
    Picker("View Mode", selection: selectedTab) {
        ForEach(Array(T.allCases), id: \.self) { tab in
            Text(" \(tab.rawValue)    ").tag(tab)
        }
    }
    .pickerStyle(.segmented)
}
