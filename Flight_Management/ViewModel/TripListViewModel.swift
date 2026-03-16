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
        searchText: String,
        sort: TripSort = .departure,
        sortOrder: SortOrder = .ascending
    ) async {
        reset()
        await loadMore(
            context: context,
            filter: filter,
            searchText: searchText,
            sort: sort,
            sortOrder: sortOrder
        )
    }

    func loadMore(
        context: ModelContext,
        filter: TripStatus?,
        searchText: String,
        sort: TripSort = .departure,
        sortOrder: SortOrder = .ascending
    ) async {
        guard !isLoading, hasMore else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            var descriptor = FetchDescriptor<Trip>()
            descriptor.fetchLimit = batchSize
            descriptor.fetchOffset = offset

            let order: Foundation.SortOrder =
                sortOrder == .ascending ? .forward : .reverse

            switch sort {
            case .departure:
                descriptor.sortBy = [
                    SortDescriptor(\Trip.scheduledDepartureTime, order: order)
                ]
            }

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
        let normalisedSearch = Trip.normalisedSearchKey(from: searchText)
        let normalisedRouteSearch = Route.normalisedSearchKey(from: searchText)

        if filter == nil && normalisedSearch.isEmpty {
            return nil
        }

        if !normalisedSearch.isEmpty {
            return #Predicate<Trip> { trip in
                (trip.tripNumberSearchKey.contains(
                    normalisedSearch
                )
                    || trip.route.nameSearchKey.contains(
                        normalisedRouteSearch
                    ))
            }
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
                            && (trip.tripNumberSearchKey.contains(
                                normalisedSearch
                            )
                                || trip.route.nameSearchKey.contains(
                                    normalisedRouteSearch
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
                            && (trip.tripNumberSearchKey.contains(
                                normalisedSearch
                            )
                                || trip.route.nameSearchKey.contains(
                                    normalisedRouteSearch
                                ))
                    }
                }
            case .scheduled, .onTime:
                if normalisedSearch.isEmpty {
                    return #Predicate<Trip> { trip in
                        !trip.isCancelled && !trip.isCompleted
                    }
                } else {
                    return #Predicate<Trip> { trip in
                        !trip.isCancelled && !trip.isCompleted
                            && (trip.tripNumberSearchKey.contains(
                                normalisedSearch
                            )
                                || trip.route.nameSearchKey.contains(
                                    normalisedRouteSearch
                                ))
                    }
                }
            case .delayed:
                if normalisedSearch.isEmpty {
                    return #Predicate<Trip> { trip in
                        !trip.isCancelled
                    }
                } else {
                    return #Predicate<Trip> { trip in
                        !trip.isCompleted
                            && (trip.tripNumberSearchKey.contains(
                                normalisedSearch
                            )
                                || trip.route.nameSearchKey.contains(
                                    normalisedRouteSearch
                                ))
                    }
                }
            }
        } else {
            return #Predicate<Trip> { trip in
                trip.tripNumberSearchKey.contains(normalisedSearch)
                    || trip.route.nameSearchKey.contains(normalisedRouteSearch)
            }
        }
    }
}
