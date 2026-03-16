import Foundation
import SwiftData
import SwiftUI

@Observable
final class RouteListViewModel {
    var items: [Route] = []
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
        filter: RouteStatus?,
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
        filter: RouteStatus?,
        searchText: String
    ) async {
        guard !isLoading, hasMore else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            var descriptor = FetchDescriptor<Route>()
            descriptor.fetchLimit = batchSize
            descriptor.fetchOffset = offset
            descriptor.sortBy = [
                SortDescriptor(\Route.name, order: .forward)
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
            print("❌ Failed to fetch route batch: \(error)")
            hasMore = false
        }
    }

    private func makePredicate(filter: RouteStatus?, searchText: String)
        -> Predicate<Route>?
    {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let normalisedSearch = Route.normalisedSearchKey(from: trimmed)
        if filter == nil && normalisedSearch.isEmpty {
            return nil
        }

        if !normalisedSearch.isEmpty {
            return #Predicate<Route> {
                $0.nameSearchKey.contains(normalisedSearch)
            }
        }

        if let filter {
            switch filter {
            case .inactive:
                if !normalisedSearch.isEmpty {
                    return #Predicate<Route> {
                        $0.nameSearchKey.contains(normalisedSearch)
                            && !$0.isActive
                    }
                } else {
                    return #Predicate<Route> {
                        !$0.isActive
                    }
                }
            case .active:
                if !normalisedSearch.isEmpty {
                    return #Predicate<Route> {
                        $0.nameSearchKey.contains(normalisedSearch)
                            && $0.isActive
                    }
                } else {
                    return #Predicate<Route> {
                        $0.isActive
                    }
                }
            }
        } else {
            return #Predicate<Route> {
                $0.nameSearchKey.contains(normalisedSearch)
            }
        }
    }
}
