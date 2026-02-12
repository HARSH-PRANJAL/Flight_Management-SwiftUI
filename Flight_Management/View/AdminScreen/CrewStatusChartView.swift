import Charts
import SwiftUI

struct CrewStatusChartView: View {
    let data: [(String, Int, Color)]
    var metaData: Int {
        data.reduce(0) { $0 + $1.1 }
    }
    var body: some View {
        if metaData != 0 {
            Chart {
                ForEach(Array(data.enumerated()), id: \.0) { _, tuple in
                    let (label, value, color) = tuple
                    SectorMark(
                        angle: .value("Count", value),
                        innerRadius: .ratio(0.4),
                        angularInset: 1
                    )
                    .foregroundStyle(color)
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

struct CrewStatusChartView_Previews: PreviewProvider {
    static var previews: some View {
        CrewStatusChartView(data: [
            ("Active", 10, .orange), ("On Duty", 8, .teal),
            ("Inactive", 4, .blue),
        ])
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
