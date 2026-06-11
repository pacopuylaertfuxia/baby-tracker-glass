import SwiftUI
import Charts

struct WeeklyChart: View {
    private let data: [(day: String, hours: Double)] = [
        ("Mon", 3.5), ("Tue", 4.2), ("Wed", 3.8),
        ("Thu", 5.0), ("Fri", 4.5), ("Sat", 3.2), ("Sun", 4.0)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This week")
                .font(.body.weight(.medium))
                .foregroundStyle(.moonOlive)

            Chart(data, id: \.day) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Hours", item.hours)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.moonClay, .moonApricot],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
            }
            .chartYAxis {
                AxisMarks(values: [0, 2, 4, 6]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(.moonStone)
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)h")
                            .font(.footnote)
                            .foregroundStyle(.moonOlive)
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        Text(value.as(String.self) ?? "")
                            .font(.footnote)
                            .foregroundStyle(.moonOlive)
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(20)
        .background(.moonWhite, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 16)
    }
}
