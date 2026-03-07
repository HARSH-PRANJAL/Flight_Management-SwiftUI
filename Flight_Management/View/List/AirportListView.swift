import SwiftData
import SwiftUI

struct AirportListView: View {

    @Environment(\.modelContext) private var context
    @Environment(NotificationManager.self) private var notificationManager

    @State private var viewModel = AirportListViewModel()
    @State private var searchText: String = ""

    @State private var showAddSheet = false
    @State private var airportToEdit: Airport? = nil
    @State private var airportToDelete: Airport? = nil
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if viewModel.items.isEmpty && !viewModel.isLoading {
                fallbackBackground
            } else {
                list
                    .scrollDismissesKeyboard(.immediately)
                    .refreshable {
                        await viewModel.loadInitial(
                            context: context,
                            searchText: searchText
                        )
                    }
            }
        }
        .navigationTitle("Airports")
        .toolbar { addButton }
        .searchable(
            text: $searchText,
            placement: .toolbar,
            prompt: "Search by name, code, city or country"
        )
        .searchToolbarBehavior(.minimize)
        .task {
            await viewModel.loadInitial(context: context, searchText: "")
        }
        .onChange(of: searchText) { _, newValue in
            Task {
                await viewModel.loadInitial(
                    context: context,
                    searchText: newValue
                )
            }
        }
        .sheet(item: $airportToEdit) { airport in
            NavigationStack {
                AirportRegistrationContent(
                    airport: airport,
                    isPresented: Binding(
                        get: { airportToEdit != nil },
                        set: { if !$0 { airportToEdit = nil } }
                    )
                )
            }
            .onDisappear {
                Task {
                    await viewModel.loadInitial(
                        context: context,
                        searchText: searchText
                    )
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            NavigationStack {
                AirportRegistrationContent(isPresented: $showAddSheet)
            }
            .onDisappear {
                Task {
                    await viewModel.loadInitial(
                        context: context,
                        searchText: searchText
                    )
                }
            }
        }
        .alert("Delete Airport?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let airport = airportToDelete {
                    viewModel.softDelete(airport, context: context)
                    notificationManager.showSuccess(
                        "\(airport.code) is deleted"
                    )
                    airportToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                airportToDelete = nil
            }
        } message: {
            if let airport = airportToDelete {
                Text(
                    "\(airport.name) will be removed from the airport list. Existing routes that reference it will remain unaffected."
                )
            }
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.items, id: \.id) { airport in
                ListRow(airport: airport)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            airportToEdit = airport
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Color(.systemBlue))
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            airportToDelete = airport
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .onAppear {
                        if airport.id == viewModel.items.last?.id {
                            Task {
                                await viewModel.loadMore(
                                    context: context,
                                    searchText: searchText
                                )
                            }
                        }
                    }
            }

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
    }

    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    private var fallbackBackground: some View {
        ContentUnavailableView {
            Label("No Airports", systemImage: "airplane.landed")
        } description: {
            Text("Add airports to get started.")
        }
    }
}

#Preview {
    NavigationStack {
        AirportListView()
    }
    .modelContainer(for: Airport.self, inMemory: true)
    .environment(NotificationManager.shared)
}
