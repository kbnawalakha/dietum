import SwiftUI

private struct BleepyPointer: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

/// A vertical prize-wheel drum: readable outcome names pass a fixed center pointer.
struct BleepyWheelView: View {
    let effect: BleepyEffect
    let progress: Double
    let spinning: Bool
    let message: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let rowHeight = 34.0
    private var position: Double {
        BleepyWheelMath.reelPosition(progress: reduceMotion ? (spinning ? 0 : 1) : progress, effect: effect)
    }

    private func color(_ value: BleepyEffect, index: Int) -> Color {
        switch value {
        case .complete: return Color(red: 0.06, green: 0.45, blue: 0.18)
        case .ultrafast: return Color(red: 0.65, green: 0.08, blue: 0.08)
        case .superSlow: return Color(red: 0.06, green: 0.25, blue: 0.56)
        default: return index % 2 == 0 ? .black : Color(white: 0.12)
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        ForEach(0..<(BleepyEffect.allCases.count * 5), id: \.self) { index in
                            let value = BleepyEffect.allCases[index % BleepyEffect.allCases.count]
                            Text(value.title)
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity).frame(height: rowHeight)
                                .background(color(value, index: index))
                                .overlay(alignment: .bottom) { Rectangle().fill(.white.opacity(0.22)).frame(height: 1) }
                        }
                    }
                    .offset(y: geometry.size.height / 2 - rowHeight / 2 - position * rowHeight)
                    .animation(reduceMotion ? nil : .linear(duration: 0.05), value: progress)
                    LinearGradient(stops: [.init(color: .black.opacity(0.85), location: 0),
                                           .init(color: .clear, location: 0.4), .init(color: .clear, location: 0.6),
                                           .init(color: .black.opacity(0.85), location: 1)], startPoint: .top, endPoint: .bottom)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    RoundedRectangle(cornerRadius: 3).stroke(.yellow, lineWidth: 2)
                        .frame(height: rowHeight).offset(y: geometry.size.height / 2 - rowHeight / 2)
                    BleepyPointer().fill(.yellow).frame(width: 12, height: 16)
                        .offset(x: geometry.size.width / 2 - 7, y: geometry.size.height / 2 - 8)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                .clipped()
                .background(.black)
            }
            .frame(width: 174, height: 136)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.yellow.opacity(0.8), lineWidth: 2))
            .accessibilityHidden(true)
            Text(spinning ? "Bleepy · Spinning…" : "Selected: \(effect.title)")
                .font(.caption.bold()).multilineTextAlignment(.center).lineLimit(2)
            if !spinning { Text(message).font(.caption2).multilineTextAlignment(.center).lineLimit(2) }
        }
        .frame(width: 174)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spinning ? "Bleepy prize wheel is moving through the outcomes" : "Bleepy selected \(effect.title). \(message)")
    }
}
