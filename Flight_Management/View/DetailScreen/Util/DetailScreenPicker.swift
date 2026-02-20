import SwiftUI

enum DetailTab: String, CaseIterable {
    case detail = "Detail"
    case tripHistory = "Trips"
}

func detailScreenPicker<T>(selectedTab: Binding<T>) -> some View where T: CaseIterable & Hashable & RawRepresentable, T.RawValue == String {
    Picker("View Mode", selection: selectedTab) {
        ForEach(Array(T.allCases), id: \.self) { tab in
            Text(tab.rawValue).tag(tab)
        }
    }
    .pickerStyle(.segmented)
    .padding(.horizontal, 16)
}
