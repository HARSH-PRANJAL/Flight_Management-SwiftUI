import Foundation
import SwiftData
import SwiftUI

@Observable
final class TripListViewModel {
    var items: [Trip] = []
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
        filter: TripStatus?,
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
        filter: TripStatus?,
        searchText: String
    ) async {
        guard !isLoading, hasMore else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            var descriptor = FetchDescriptor<Trip>()
            descriptor.fetchLimit = batchSize
            descriptor.fetchOffset = offset
            descriptor.sortBy = [
                SortDescriptor(\Trip.scheduledDepartureTime, order: .forward)
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
            print("❌ Failed to fetch trip batch: \(error)")
            hasMore = false
        }
    }

    private func makePredicate(
        filter: TripStatus?,
        searchText: String
    ) -> Predicate<Trip>? {
        let trimmed = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let normalisedSearch = Trip.normalisedSearchKey(from: trimmed)

        if filter == nil && normalisedSearch.isEmpty {
            return nil
        }

        if let filter {
            switch filter {
            case .cancelled:
                if normalisedSearch.isEmpty {
                    return #Predicate<Trip> { trip in
                        trip.isCancelled
                    }
                } else {
                    return #Predicate<Trip> { trip in
                        trip.isCancelled
                            && (trip.flightNumberSearchKey.contains(
                                normalisedSearch
                            )
                                || trip.route.nameSearchKey.contains(
                                    normalisedSearch
                                ))
                    }
                }
            case .completed:
                if normalisedSearch.isEmpty {
                    return #Predicate<Trip> { trip in
                        trip.isCompleted && !trip.isCancelled
                    }
                } else {
                    return #Predicate<Trip> { trip in
                        trip.isCompleted && !trip.isCancelled
                            && (trip.flightNumberSearchKey.contains(
                                normalisedSearch
                            )
                                || trip.route.nameSearchKey.contains(
                                    normalisedSearch
                                ))
                    }
                }
            case .scheduled, .onTime, .delayed:
                if normalisedSearch.isEmpty {
                    return #Predicate<Trip> { trip in
                        !trip.isCancelled && !trip.isCompleted
                    }
                } else {
                    return #Predicate<Trip> { trip in
                        !trip.isCancelled && !trip.isCompleted
                            && (trip.flightNumberSearchKey.contains(
                                normalisedSearch
                            )
                                || trip.route.nameSearchKey.contains(
                                    normalisedSearch
                                ))
                    }
                }
            }
        } else {
            // No status filter, only search
            return #Predicate<Trip> { trip in
                trip.flightNumberSearchKey.contains(normalisedSearch)
                    || trip.route.nameSearchKey.contains(normalisedSearch)
            }
        }
    }
}

