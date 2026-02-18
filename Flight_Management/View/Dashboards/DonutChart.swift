import Charts
import SwiftUI

struct DonutChartView: View {
    let data: [(category: String, count: Int)]
    let defaultTitle: String

    @State private var selectedAngle: Double? = nil
    @State private var selectedCategory: String? = nil

    var total: Int {
        data.reduce(0) { $0 + $1.count }
    }

    var body: some View {
        if total == 0 {
            VStack {
                Image(systemName: "chart.bar")
                    .resizable()
                    .foregroundStyle(Color(.systemGray))
                    .opacity(0.2)
                Text("No data to display.")
                    .font(.callout)
                    .opacity(0.5)
            }
            .frame(width: 200, height: 200)
        } else {
            chart
        }
    }

    var chart: some View {
        Chart(data.indices, id: \.self) { index in
            let item = data[index]

            SectorMark(
                angle: .value("Count", item.count),
                innerRadius: .ratio(0.6),
                angularInset: 2
            )
            .foregroundStyle(by: .value("Category", item.category))
            .opacity(
                selectedCategory == nil || selectedCategory == item.category
                    ? 1 : 0.4
            )
        }
        .scaledToFit()
        .chartAngleSelection(value: $selectedAngle)
        .onChange(of: selectedAngle) { _, newValue in
            guard let angle = newValue else {
                selectedCategory = nil
                return
            }

            // Convert angle to category
            var cumulative: Double = 0

            for item in data {
                cumulative += Double(item.count)
                if angle <= cumulative {
                    selectedCategory = item.category
                    break
                }
            }
        }
        // WWDC 23 to place the details in the centre of the chart
        .chartBackground { proxy in
            GeometryReader { geo in
                if let plotFrame = proxy.plotFrame {
                    let frame = geo[plotFrame]
                    let center = CGPoint(x: frame.midX, y: frame.midY)

                    VStack(spacing: 4) {
                        Text(selectedCategory ?? defaultTitle)
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Text(
                            selectedCategory == nil
                                ? "\(total)"
                                : "\(data.first { $0.category == selectedCategory }?.count ?? 0)"
                        )
                        .font(.title2.bold())
                    }
                    .position(center)
                }
            }
        }
    }
}

#Preview {
    DonutChartView(
        data: [
            (category: "Available", count: 30),
            (category: "Unavailable", count: 30),
            (category: "On Duty", count: 30),
        ],
        defaultTitle: ""
    )
}
