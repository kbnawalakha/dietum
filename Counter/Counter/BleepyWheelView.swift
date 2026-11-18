import SwiftUI

private struct BleepySector: Shape {
    let index: Int
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let step = 360.0 / Double(BleepyEffect.allCases.count)
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: min(rect.width, rect.height) / 2,
                    startAngle: .degrees(-90 + Double(index) * step - step / 2),
                    endAngle: .degrees(-90 + Double(index) * step + step / 2), clockwise: false)
        path.closeSubpath()
        return path
    }
}

private struct BleepyPointer: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

struct BleepyWheelView: View {
    let effect: BleepyEffect
    let progress: Double
    let spinning: Bool
    let message: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let diameter = 124.0
    private var count: Double { Double(BleepyEffect.allCases.count) }

    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .top) {
                ZStack {
                    ForEach(Array(BleepyEffect.allCases.enumerated()), id: \.offset) { index, _ in
                        BleepySector(index: index)
                            .fill(Color(hue: Double(index) / count, saturation: 0.62, brightness: 0.8))
                            .overlay(BleepySector(index: index).stroke(.black.opacity(0.25), lineWidth: 1))
                        let angle = (-90 + Double(index) * 360 / count) * .pi / 180
                        Text("\(index + 1)").font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .offset(x: cos(angle) * diameter * 0.375, y: sin(angle) * diameter * 0.375)
                    }
                }
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(reduceMotion ? (spinning ? 0 : BleepyWheelMath.rotation(progress: 1, effect: effect)) : BleepyWheelMath.rotation(progress: progress, effect: effect)))
                .animation(reduceMotion ? nil : .linear(duration: 0.05), value: progress)
                Circle().fill(.black.opacity(0.8)).frame(width: 38, height: 38)
                    .overlay(Text("B").font(.headline.bold()).foregroundStyle(.mint))
                    .offset(y: (diameter - 38) / 2)
                BleepyPointer().fill(.white).frame(width: 16, height: 13).offset(y: -3)
            }
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
            Text(spinning ? "Bleepy · Spinning…" : effect.title)
                .font(.caption.bold()).multilineTextAlignment(.center)
            if !spinning { Text(message).font(.caption2).multilineTextAlignment(.center).lineLimit(2) }
        }
        .frame(width: 174)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spinning ? "Bleepy wheel is choosing an outcome" : "Bleepy selected \(effect.title). \(message)")
    }
}
