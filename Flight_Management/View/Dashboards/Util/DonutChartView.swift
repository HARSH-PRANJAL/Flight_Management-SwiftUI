import Charts
import SwiftUI

struct DonutChartView: View {
    let data: [(category: String, count: Int, color: Color)]
    let defaultTitle: String

    @State private var selectedCategory: String? = nil
    @State private var selectedAngle: Double? = nil

    var body: some View {
        if total == 0 {
            VStack(spacing: 12) {
                Image(systemName: "chart.pie")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundStyle(.gray.opacity(0.3))

                Text("No data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: 280)
        } else {
            VStack(spacing: 20) {
                chartView
                legendView
            }
            .animation(.smooth, value: selectedCategory)
            .animation(.smooth, value: selectedAngle)
            .padding(.horizontal)
        }
    }
}

// MARK: UI
extension DonutChartView {
    private var chartView: some View {
        Chart(data.indices, id: \.self) { index in
            let item = data[index]

            SectorMark(
                angle: .value("Count", item.count),
                innerRadius: .ratio(0.618),
                angularInset: 1
            )
            .foregroundStyle(item.color)
            .cornerRadius(5)
            .opacity(
                selectedCategory == nil || selectedCategory == item.category
                    ? 1.0
                    : 0.35
            )
        }
        .frame(minWidth: 250, maxWidth: 500, minHeight: 250, maxHeight: 500)
        .chartAngleSelection(value: $selectedAngle)
        .onChange(of: selectedAngle) { oldValue, newValue in
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
        .chartBackground { proxy in
            GeometryReader { geo in
                if let plotFrame = proxy.plotFrame {
                    let frame = geo[plotFrame]
                    let center = CGPoint(x: frame.midX, y: frame.midY)

                    internalLegendView
                        .multilineTextAlignment(.center)
                        .position(center)
                }
            }
        }
    }

    private var internalLegendView: some View {
        VStack(spacing: 6) {
            Text(selectedCategory ?? defaultTitle)
                .font(
                    .system(
                        .title3,
                        design: .rounded,
                        weight: selectedCategory != nil
                            ? .bold : .medium
                    )
                )
                .foregroundStyle(
                    selectedCategory != nil ? .primary : .secondary
                )

            if let cat = selectedCategory,
                let item = data.first(where: { $0.category == cat })
            {
                Text(
                    "\(item.count) • \(percentage(for: item.count))%"
                )
                .font(
                    .system(
                        .title3,
                        design: .rounded,
                        weight: .semibold
                    )
                )
                .foregroundStyle(item.color)
            } else {
                Text("\(total)")
                    .font(
                        .system(
                            .title2,
                            design: .rounded,
                            weight: .bold
                        )
                    )
            }
        }
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(data, id: \.category) { item in
                if item.count > 0 {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(item.color)
                            .overlay(
                                Circle().stroke(
                                    .gray.opacity(0.3),
                                    lineWidth: 0.5
                                )
                            )
                            .frame(width: 13, height: 13)

                        Text(item.category)
                            .font(
                                .system(
                                    .body,
                                    design: .rounded,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(item.count) • \(percentage(for: item.count))%")
                            .font(
                                .system(
                                    .body,
                                    design: .rounded,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                Color(.systemGray6).opacity(
                                    selectedCategory == item.category ? 0.6 : 0
                                )
                            )
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4)) {
                            selectedCategory =
                                (selectedCategory == item.category)
                                ? nil : item.category
                        }
                    }
                    .accessibilityAddTraits(.isButton)
                    .accessibilityLabel(
                        "\(item.category): \(item.count) items, \(percentage(for: item.count)) percent"
                    )
                    .accessibilityHint("Tap to highlight or show details")
                }
            }
        }
    }
}

// MARK: Util
extension DonutChartView {
    private func percentage(for count: Int) -> String {
        guard total > 0 else { return "0" }
        let percent = Double(count) / Double(total) * 100
        return percentageValues(value: percent)
    }

    var total: Int {
        data.reduce(0) { $0 + $1.count }
    }

    private func percentageValues(value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        } else {
            return String(format: "%.1f", value)
        }
    }
}

#Preview {
    let sampleData = [
        (category: "Available", count: 42, color: Color.green),
        (category: "On Duty", count: 0, color: Color.blue),
        (category: "Unavailable", count: 15, color: Color.red.opacity(0.85)),
        (category: "Leave", count: 0, color: Color.orange),
    ]

    DonutChartView(
        data: sampleData,
        defaultTitle: "Staff Status"
    )
    .padding()
}
