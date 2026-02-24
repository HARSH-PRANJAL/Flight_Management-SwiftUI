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
        searchText: String
    ) async {
        reset()
        await loadMore(
            context: context,
            searchText: searchText
        )
    }

    func loadMore(
        context: ModelContext,
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

            if let predicate = makePredicate(searchText: searchText) {
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

    private func makePredicate(searchText: String) -> Predicate<Route>? {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return nil
        }

        return #Predicate<Route> {
            $0.name.contains(trimmed)
        }
    }
}
