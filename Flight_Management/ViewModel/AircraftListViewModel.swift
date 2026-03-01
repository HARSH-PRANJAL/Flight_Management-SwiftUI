import Foundation
import SwiftData
import SwiftUI

@Observable
final class AircraftListViewModel {
    var items: [Aircraft] = []
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
        statusFilter: AircraftStatus?,
        searchText: String
    ) async {
        reset()
        await loadMore(
            context: context,
            statusFilter: statusFilter,
            searchText: searchText
        )
    }

    func loadMore(
        context: ModelContext,
        statusFilter: AircraftStatus?,
        searchText: String
    ) async {
        guard !isLoading, hasMore else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            var descriptor = FetchDescriptor<Aircraft>()
            descriptor.fetchLimit = batchSize
            descriptor.fetchOffset = offset
            descriptor.sortBy = [
                SortDescriptor(\Aircraft.registrationNumber, order: .forward)
            ]

            if let predicate = makePredicate(
                statusFilter: statusFilter,
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
            print("❌ Failed to fetch aircraft batch: \(error)")
            hasMore = false
        }
    }

    private func makePredicate(
        statusFilter: AircraftStatus?,
        searchText: String
    ) -> Predicate<Aircraft>? {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalisedSearch = Aircraft.normalisedSearchKey(from: trimmed)

        if statusFilter == nil && normalisedSearch.isEmpty {
            return nil
        }

        if let statusFilter {
            switch statusFilter {
            case .available:
                if normalisedSearch.isEmpty {
                    return #Predicate<Aircraft> { aircraft in
                        aircraft.currentTrip == nil
                    }
                } else {
                    return #Predicate<Aircraft> { aircraft in
                        aircraft.currentTrip == nil
                            && aircraft.registrationNumberSearchKey.contains(
                                normalisedSearch
                            )
                    }
                }
            case .assigned:
                if normalisedSearch.isEmpty {
                    return #Predicate<Aircraft> { aircraft in
                        aircraft.currentTrip != nil
                    }
                } else {
                    return #Predicate<Aircraft> { aircraft in
                        aircraft.currentTrip != nil
                            && aircraft.registrationNumberSearchKey.contains(
                                normalisedSearch
                            )
                    }
                }
            }
        } else {
            return #Predicate<Aircraft> { aircraft in
                aircraft.registrationNumberSearchKey.contains(normalisedSearch)
            }
        }
    }
}
