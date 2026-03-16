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
        searchText: String,
        sort: StaffSort = .name,
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
        filter: StaffAvailabilityStatus?,
        searchText: String,
        sort: StaffSort = .name,
        sortOrder: SortOrder = .ascending
    ) async {
        guard !isLoading, hasMore else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            var descriptor = FetchDescriptor<Staff>()
            descriptor.fetchLimit = batchSize
            descriptor.fetchOffset = offset

            let order: Foundation.SortOrder =
                sortOrder == .ascending ? .forward : .reverse
            switch sort {
            case .name:
                descriptor.sortBy = [SortDescriptor(\Staff.name, order: order)]
            case .experience:
                descriptor.sortBy = [
                    SortDescriptor(\Staff.totalTripHours, order: order)
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

        let normalisedSearch = Staff.normalisedSearchKey(from: trimmed)

        if filter == nil && normalisedSearch.isEmpty {
            return nil
        }

        let designationSearch = StaffRole.allCases.first { role in
            role.rawValue
                .lowercased()
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "-", with: "")
                == normalisedSearch
        }
        
        if !normalisedSearch.isEmpty {
            return #Predicate<Staff> {
                ($0.nameSearchKey.contains(normalisedSearch)
                    || (designationSearch != nil
                        && $0.designation == designationSearch!))
            }
        }

        if let filter {
            switch filter {

            case .available:
                if normalisedSearch.isEmpty {
                    return #Predicate<Staff> {
                        !$0.isMarkedUnavailable && $0.currentTrip == nil
                    }
                } else {
                    return #Predicate<Staff> {
                        !$0.isMarkedUnavailable && $0.currentTrip == nil
                            && ($0.nameSearchKey.contains(normalisedSearch)
                                || (designationSearch != nil
                                    && $0.designation == designationSearch!)
                                || ($0.currentTrip?
                                    .tripNumberSearchKey
                                    .contains(normalisedSearch)
                                    ?? false))
                    }
                }

            case .onDuty:
                if normalisedSearch.isEmpty {
                    return #Predicate<Staff> {
                        !$0.isMarkedUnavailable && $0.currentTrip != nil
                    }
                } else {
                    return #Predicate<Staff> {
                        !$0.isMarkedUnavailable && $0.currentTrip != nil
                            && ($0.nameSearchKey.contains(normalisedSearch)
                                || (designationSearch != nil
                                    && $0.designation == designationSearch!)
                                || ($0.currentTrip?
                                    .tripNumberSearchKey
                                    .contains(normalisedSearch)
                                    ?? false))
                    }
                }

            case .unavailable:
                if normalisedSearch.isEmpty {
                    return #Predicate<Staff> {
                        $0.isMarkedUnavailable
                    }
                } else {
                    return #Predicate<Staff> {
                        $0.isMarkedUnavailable
                            && ($0.nameSearchKey.contains(normalisedSearch)
                                || (designationSearch != nil
                                    && $0.designation == designationSearch!)
                                || ($0.currentTrip?
                                    .tripNumberSearchKey
                                    .contains(normalisedSearch)
                                    ?? false))
                    }
                }
            }

        } else {
            return #Predicate<Staff> {
                $0.nameSearchKey.contains(normalisedSearch)
                    || (designationSearch != nil
                        && $0.designation == designationSearch!)
                    || ($0.currentTrip?
                        .tripNumberSearchKey
                        .contains(normalisedSearch) ?? false)
            }
        }
    }

}
