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

        if filter == nil && trimmed.isEmpty {
            return nil
        }

        if let filter {
            switch filter {
            case .cancelled:
                return #Predicate<Trip> { trip in
                    trip.isCancelled
                        && (trimmed.isEmpty
                            || trip.flightNumber.contains(trimmed)
                            || trip.route.name.contains(trimmed))
                }
            case .completed:
                return #Predicate<Trip> { trip in
                    trip.isCompleted && !trip.isCancelled
                        && (trimmed.isEmpty
                            || trip.flightNumber.contains(trimmed)
                            || trip.route.name.contains(trimmed))
                }
            case .scheduled, .onTime, .delayed:
                // These require derived state (currentStatus/totalDelayedMinutes);
                // constrain only by cancellation/completion flags here, and let
                // the view refine by currentStatus on the loaded batch.
                return #Predicate<Trip> { trip in
                    !trip.isCancelled && !trip.isCompleted
                        && (trimmed.isEmpty
                            || trip.flightNumber.contains(trimmed)
                            || trip.route.name.contains(trimmed))
                }
            }
        } else {
            // No status filter, only search
            return #Predicate<Trip> { trip in
                trip.flightNumber.contains(trimmed)
                    || trip.route.name.contains(trimmed)
            }
        }
    }
}

