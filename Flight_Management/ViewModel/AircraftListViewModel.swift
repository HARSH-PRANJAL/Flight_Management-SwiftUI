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
            var descriptor = FetchDescriptor<Aircraft>()
            descriptor.fetchLimit = batchSize
            descriptor.fetchOffset = offset
            descriptor.sortBy = [
                SortDescriptor(\Aircraft.registrationNumber, order: .forward)
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
            print("❌ Failed to fetch aircraft batch: \(error)")
            hasMore = false
        }
    }

    private func makePredicate(searchText: String) -> Predicate<Aircraft>? {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return nil
        }

        return #Predicate<Aircraft> {
            $0.registrationNumber.contains(trimmed)
        }
    }
}
