import SwiftData
import SwiftUI

struct SplashView: View {
    @Environment(\.modelContext) private var context
    @Environment(SessionManager.self) var session
    @State private var showContent = false

    var body: some View {
        Group {
            if showContent {
                ContentView()
                    .environment(session)
            } else {
                ZStack {
                    Color(.systemBackground).ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image("AppIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)

                        Text("Flight Management")
                            .font(.title2)
                            .bold()
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeOut) {
                            showContent = true
                        }
                    }
                    Task {
                        await DemoDataAPI.seedIfNeeded(in: context)
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
        .modelContainer(for: User.self, inMemory: true)
        .environment(SessionManager.shared)
}
