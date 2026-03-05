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
        searchText: String,
        sort: AircraftSort = .registration,
        sortOrder: SortOrder = .ascending
    ) async {
        reset()
        await loadMore(
            context: context,
            statusFilter: statusFilter,
            searchText: searchText,
            sort: sort,
            sortOrder: sortOrder
        )
    }

    func loadMore(
        context: ModelContext,
        statusFilter: AircraftStatus?,
        searchText: String,
        sort: AircraftSort = .registration,
        sortOrder: SortOrder = .ascending
    ) async {
        guard !isLoading, hasMore else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            var descriptor = FetchDescriptor<Aircraft>()
            let order: Foundation.SortOrder =
                sortOrder == .ascending ? .forward : .reverse

            descriptor.fetchLimit = batchSize
            descriptor.fetchOffset = offset
            switch sort {
            case .registration:
                descriptor.sortBy = [
                    SortDescriptor(\Aircraft.registrationNumber, order: order)
                ]
            case .seatingCapacity:
                descriptor.sortBy = [
                    SortDescriptor(\Aircraft.seatingCapacity, order: order)
                ]
            }

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
            return #Predicate<Aircraft> { aircraft in
                !aircraft.isDecommissioned
            }
        }

        if let statusFilter {
            switch statusFilter {
            case .available:
                if normalisedSearch.isEmpty {
                    return #Predicate<Aircraft> { aircraft in
                        aircraft.currentTrip == nil
                            && !aircraft.isDecommissioned
                    }
                } else {
                    return #Predicate<Aircraft> { aircraft in
                        aircraft.currentTrip == nil
                            && aircraft.registrationNumberSearchKey.contains(
                                normalisedSearch
                            )
                            && !aircraft.isDecommissioned
                    }
                }
            case .assigned:
                if normalisedSearch.isEmpty {
                    return #Predicate<Aircraft> { aircraft in
                        aircraft.currentTrip != nil
                            && !aircraft.isDecommissioned
                    }
                } else {
                    return #Predicate<Aircraft> { aircraft in
                        aircraft.currentTrip != nil
                            && aircraft.registrationNumberSearchKey.contains(
                                normalisedSearch
                            )
                            && !aircraft.isDecommissioned
                    }
                }
            default:
                return #Predicate<Aircraft> { aircraft in
                    aircraft.registrationNumberSearchKey.contains(
                        normalisedSearch
                    )
                        && !aircraft.isDecommissioned
                }
            }
        } else {
            return #Predicate<Aircraft> { aircraft in
                aircraft.registrationNumberSearchKey.contains(normalisedSearch)
                    && !aircraft.isDecommissioned
            }
        }
    }
}
