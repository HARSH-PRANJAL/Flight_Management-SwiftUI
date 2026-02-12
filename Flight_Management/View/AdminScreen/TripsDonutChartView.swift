import Charts
import SwiftUI

struct TripsDonutChartView: View {
    let data: [(String, Int, Color)]
    var metaData: Int {
        data.reduce(0) {
            let (_, count, _) = $1
            return $0 + count
        }
    }
    var body: some View {
        if metaData != 0 {
            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) {
                    index,
                    tuple in
                    let (_, value, color) = tuple
                    SectorMark(
                        angle: .value("Count", value),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(color)
                    .annotation(position: .overlay) {
                        // small labels could be added here if desired
                        EmptyView()
                    }
                }
            }
            .chartLegend(.visible)
        } else {
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
        }
    }
}

#Preview("With data") {
    TripsDonutChartView(data: [("On-Time", 5, .green), ("Delayed", 2, .orange)])
}

#Preview("Without data") {
    TripsDonutChartView(data: [])
}
