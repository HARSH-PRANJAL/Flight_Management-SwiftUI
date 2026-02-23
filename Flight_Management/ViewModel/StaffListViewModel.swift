import Foundation
import SwiftData
import SwiftUI

@Observable
final class StaffListViewModel {
    var items: [Staff] = []
    var isLoading: Bool = false
    var hasMore: Bool = true

    private var offset: Int = 0
    private let batchSize: Int = 50

    func reset() {
        items = []
        offset = 0
        hasMore = true
    }

    func loadInitial(
        context: ModelContext,
        filter: StaffAvailabilityStatus?,
        searchText: String
    ) async {
        reset()
        await loadMore(
            context: context,
            filter: filter,
            searchText: searchText
        )
    }

    func loadMore(
        context: ModelContext,
        filter: StaffAvailabilityStatus?,
        searchText: String
    ) async {
        guard !isLoading, hasMore else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            var descriptor = FetchDescriptor<Staff>()
            descriptor.fetchLimit = batchSize
            descriptor.fetchOffset = offset
            descriptor.sortBy = [
                SortDescriptor(\Staff.name, order: .forward)
            ]

            if let predicate = makePredicate(
                filter: filter,
                searchText: searchText
            ) {
                descriptor.predicate = predicate
            }

            let result = try context.fetch(descriptor)
            items.append(contentsOf: result)
            offset += result.count
            if result.count < batchSize {
                hasMore = false
            }
        } catch {
            print("❌ Failed to fetch staff batch: \(error)")
            hasMore = false
        }
    }

    private func makePredicate(
        filter: StaffAvailabilityStatus?,
        searchText: String
    ) -> Predicate<Staff>? {

        let trimmed =
            searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if filter == nil && trimmed.isEmpty {
            return nil
        }

        let normalisedSearch =
            trimmed
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        let designationSearch = StaffRole.allCases.first { role in
            role.rawValue
                .lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "-", with: "")
                == normalisedSearch
        }

        if let filter {
            switch filter {

            case .available:
                return #Predicate<Staff> {
                    !$0.isMarkedUnavailable && $0.currentTrip == nil
                        && (trimmed.isEmpty || $0.name.contains(trimmed)
                            || (designationSearch != nil
                                && $0.designation == designationSearch!)
                            || ($0.currentTrip?.flightNumber.contains(trimmed)
                                ?? false))
                }

            case .onDuty:
                return #Predicate<Staff> {
                    !$0.isMarkedUnavailable && $0.currentTrip != nil
                        && (trimmed.isEmpty || $0.name.contains(trimmed)
                            || (designationSearch != nil
                                && $0.designation == designationSearch!)
                            || ($0.currentTrip?.flightNumber.contains(trimmed)
                                ?? false))
                }

            case .unavailable:
                return #Predicate<Staff> {
                    $0.isMarkedUnavailable
                        && (trimmed.isEmpty || $0.name.contains(trimmed)
                            || (designationSearch != nil
                                && $0.designation == designationSearch!)
                            || ($0.currentTrip?.flightNumber.contains(trimmed)
                                ?? false))
                }
            }

        } else {
            return #Predicate<Staff> {
                $0.name.contains(trimmed)
                    || (designationSearch != nil
                        && $0.designation == designationSearch!)
                    || ($0.currentTrip?.flightNumber.contains(trimmed) ?? false)
            }
        }
    }

}
