import SwiftUI

struct SunPositionView: View {

    let progress: Double
    let sunriseTime: String
    let sunsetTime: String

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let radius = min(width / 2 - 20, height - 20)
                let centerX = width / 2
                let baseY = height - 4

                ZStack {
                    // Horizon line
                    Path { path in
                        path.move(to: CGPoint(x: 16, y: baseY))
                        path.addLine(to: CGPoint(x: width - 16, y: baseY))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(.secondary.opacity(0.5))

                    // Full arc (background)
                    arcPath(center: CGPoint(x: centerX, y: baseY), radius: radius)
                        .stroke(.secondary.opacity(0.2), lineWidth: 2)

                    // Traversed arc
                    if progress > 0 {
                        arcPath(
                            center: CGPoint(x: centerX, y: baseY),
                            radius: radius,
                            endProgress: min(progress, 1.0)
                        )
                        .stroke(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2.5
                        )
                    }

                    // Sun icon
                    let sunPosition = sunPoint(
                        center: CGPoint(x: centerX, y: baseY),
                        radius: radius,
                        progress: progress
                    )
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.yellow)
                        .shadow(color: .orange.opacity(0.5), radius: 4)
                        .position(sunPosition)
                }
            }
            .frame(height: 80)

            // Time labels
            HStack {
                Text(sunriseTime)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(sunsetTime)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Geometry

    private func arcPath(
        center: CGPoint,
        radius: CGFloat,
        endProgress: Double = 1.0
    ) -> Path {
        Path { path in
            let startAngle = Angle.degrees(180)
            let endAngle = Angle.degrees(180 - endProgress * 180)
            path.addArc(
                center: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: false
            )
        }
    }

    private func sunPoint(center: CGPoint, radius: CGFloat, progress: Double) -> CGPoint {
        let clampedProgress = min(max(progress, 0), 1)
        let angle = Double.pi - clampedProgress * Double.pi
        let x = center.x + radius * cos(angle)
        let y = center.y - radius * sin(angle)
        return CGPoint(x: x, y: y)
    }
}
