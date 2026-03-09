import Foundation
import SwiftData
import SwiftUI

@Observable
final class AirportListViewModel {
    var items: [Airport] = []
    var isLoading: Bool = false
    var hasMore: Bool = true

    private var offset: Int = 0
    private let batchSize: Int = 50
    
    func reset() {
        items = []
        offset = 0
        hasMore = true
    }

    func loadInitial(context: ModelContext, searchText: String) async {
        reset()
        await loadMore(context: context, searchText: searchText)
    }

    func loadMore(context: ModelContext, searchText: String) async {
        guard !isLoading, hasMore else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            var descriptor = FetchDescriptor<Airport>()
            descriptor.fetchLimit = batchSize
            descriptor.fetchOffset = offset
            descriptor.sortBy = [SortDescriptor(\Airport.name, order: .forward)]
            descriptor.predicate = makePredicate(searchText: searchText)

            let result = try context.fetch(descriptor)
            items.append(contentsOf: result)
            offset += result.count
            if result.count < batchSize { hasMore = false }
        } catch {
            print("❌ Failed to fetch airport batch: \(error)")
            hasMore = false
        }
    }
    
    private func makePredicate(searchText: String) -> Predicate<Airport> {
        let trimmed = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        if trimmed.isEmpty {
            return #Predicate<Airport> { !$0.isRemoved }
        }

        return #Predicate<Airport> {
            !$0.isRemoved && $0.searchKey.contains(trimmed)
        }
    }
    
    func softDelete(_ airport: Airport, context: ModelContext) {
        airport.isRemoved = true
        try? context.save()
        withAnimation {
            items.removeAll { $0.id == airport.id }
        }
    }
}
