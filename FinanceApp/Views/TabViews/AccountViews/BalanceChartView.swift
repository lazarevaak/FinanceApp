import SwiftUI
import Charts

public struct BalanceEntry: Identifiable, Equatable {
    public let id = UUID()
    public let date: Date
    public let balance: Decimal

    public init(date: Date, balance: Decimal) {
        self.date = date
        self.balance = balance
    }

    var doubleBalance: Double {
        NSDecimalNumber(decimal: balance).doubleValue
    }
}

public struct BalanceChartView: View {
    let entries: [BalanceEntry]
    @State private var selectedEntry: BalanceEntry? = nil

    public init(entries: [BalanceEntry]) {
        self.entries = entries
    }

    public var body: some View {
        Chart(entries) { entry in
            BarMark(
                x: .value("Date", entry.date),
                y: .value("Balance", entry.doubleBalance)
            )
            .foregroundStyle(entry.doubleBalance < 0 ? Color.red : Color.green)
            .annotation(position: .top) {
                if selectedEntry == entry {
                    Text(entry.doubleBalance,
                         format: .number.precision(.fractionLength(0)))
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(5)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                AxisValueLabel(format: .dateTime.day().month(.twoDigits))
            }
        }
        .chartYScale(domain: .automatic)
        .frame(height: 200)
        .padding(.horizontal, 16)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        LongPressGesture(minimumDuration: 0.3)
                            .sequenced(before: DragGesture(minimumDistance: 0))
                            .onChanged { value in
                                if case .second(true, let drag?) = value {
                                    let loc = drag.location
                                    let plotArea = geo[proxy.plotAreaFrame]
                                    let xIn = loc.x - plotArea.minX
                                    if let date: Date = proxy.value(atX: xIn),
                                       let nearest = entries.min(by: {
                                        abs($0.date.timeIntervalSince(date)) <
                                        abs($1.date.timeIntervalSince(date))
                                       }) {
                                        selectedEntry = nearest
                                    }
                                }
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    selectedEntry = nil
                                }
                            }
                    )
            }
        }
    }
}

struct BalanceChartView_Previews: PreviewProvider {
    static var previews: some View {
        let now = Date()
        let sample = (0..<30).map { i in
            BalanceEntry(
                date: Calendar.current.date(byAdding: .day, value: -i, to: now)!,
                balance: Decimal(Int.random(in: -500...500))
            )
        }.sorted { $0.date < $1.date }
        BalanceChartView(entries: sample)
            .previewLayout(.sizeThatFits)
    }
}
