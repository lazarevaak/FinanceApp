import UIKit

public class PieChartView: UIView {
    // MARK: — Public API
    public var entities: [Entity] = [] {
        didSet {
            setNeedsDisplay()
            setupLegend()
        }
    }

    private let segmentColors: [UIColor] = [
        .systemGreen,
        .systemYellow,
        .systemRed,
        .systemBlue,
        .systemOrange,
        .systemPurple
    ]

    private var legendStack: UIStackView?

    // MARK: — Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        isOpaque = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .systemBackground
        isOpaque = true
    }

    // MARK: — Drawing
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        ctx.setFillColor((backgroundColor ?? .white).cgColor)
        ctx.fill(rect)

        guard !entities.isEmpty else { return }

        let total = entities.reduce(Decimal(0)) { $0 + $1.value }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) * 0.4
        let innerRadius = outerRadius * 0.9

        var startAngle = -CGFloat.pi / 2

        var drawing = Array(entities.prefix(5))
        if entities.count > 5 {
            let othersValue = entities.dropFirst(5).reduce(Decimal(0)) { $0 + $1.value }
            drawing.append(Entity(value: othersValue, label: "Остальные"))
        }

        for (i, e) in drawing.enumerated() {
            let fraction = total == 0 ? Decimal(0) : e.value / total
            let angle = CGFloat(NSDecimalNumber(decimal: fraction).doubleValue) * .pi * 2

            let path = UIBezierPath()
            path.addArc(withCenter: center,
                        radius: outerRadius,
                        startAngle: startAngle,
                        endAngle: startAngle + angle,
                        clockwise: true)
            path.addArc(withCenter: center,
                        radius: innerRadius,
                        startAngle: startAngle + angle,
                        endAngle: startAngle,
                        clockwise: false)
            path.close()

            ctx.setFillColor(segmentColors[i % segmentColors.count].cgColor)
            ctx.addPath(path.cgPath)
            ctx.fillPath()

            startAngle += angle
        }
    }

    // MARK: — Legend
    private func setupLegend() {
        legendStack?.removeFromSuperview()

        let total = entities.reduce(Decimal(0)) { $0 + $1.value }
        var drawing = Array(entities.prefix(5))
        if entities.count > 5 {
            let othersValue = entities.dropFirst(5).reduce(Decimal(0)) { $0 + $1.value }
            drawing.append(Entity(value: othersValue, label: "Остальные"))
        }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        addSubview(stack)

        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        for (i, e) in drawing.enumerated() {
            let pct: Double
            if total == 0 {
                pct = 0
            } else {
                let frac = NSDecimalNumber(decimal: e.value / total)
                pct = frac.multiplying(by: 100).doubleValue
            }
            let pctText = String(format: "%.0f%%", pct)

            let dot = UIView()
            dot.backgroundColor = segmentColors[i % segmentColors.count]
            dot.layer.cornerRadius = 4
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true

            let label = UILabel()
            label.font = .systemFont(ofSize: 11)
            label.textColor = .secondaryLabel
            label.text = "\(pctText)  \(e.label)"

            let row = UIStackView(arrangedSubviews: [dot, label])
            row.axis = .horizontal
            row.spacing = 6
            stack.addArrangedSubview(row)
        }

        legendStack = stack
    }

    // MARK: — Animation
    public func animateTransition(to newEntities: [Entity],
                                  duration: TimeInterval = 1.0) {
        guard duration > 0.1 else {
            entities = newEntities
            return
        }

        let half = duration / 2.0

        UIView.animateKeyframes(withDuration: duration,
                                delay: 0,
                                options: [.calculationModeLinear]) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.5) {
                self.transform = CGAffineTransform(rotationAngle: .pi)
                self.alpha = 0
            }
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                self.transform = CGAffineTransform(rotationAngle: .pi * 2)
                self.alpha = 1
            }
        } completion: { _ in
            self.transform = .identity
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + half) {
            self.entities = newEntities
        }
    }
}
