
import SwiftUI

struct RoadmapView: View {
    private let forestGreen = Color(red: 39/255, green: 79/255, blue: 72/255)
    private let paleLime = Color(red: 237/255, green: 252/255, blue: 214/255)
    private let softCyan = Color(red: 204/255, green: 241/255, blue: 253/255)
    private let periwinkle = Color(red: 183/255, green: 209/255, blue: 251/255)
    private let completedGreen = Color(red: 145/255, green: 194/255, blue: 137/255)

    @AppStorage("completedRoadmapDays") private var completedDays = 0
    @AppStorage("userName") private var userName: String = ""
    /// Situations chosen in onboarding; the order of the days comes from RoadmapPlan.
    @AppStorage(RoadmapPlan.focusKey) private var focus: String = ""

    private var plan: [RoadmapLesson] { RoadmapPlan.lessons(focus: focus) }

    /// Same initial Home shows, instead of a hard-coded letter.
    private var initialLetter: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return String((trimmed.isEmpty ? "friend" : trimmed).prefix(1)).uppercased()
    }

    var body: some View {
        GeometryReader { screen in
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    ZStack(alignment: .top) {
                        // Kept, but further off-screen and softer, so it reads
                        // as a tint behind the title rather than a shape.
                        Circle()
                            .fill(paleLime.opacity(0.55))
                            .frame(width: 215, height: 215)
                            .offset(x: screen.size.width * 0.46, y: -186)

                        HStack(alignment: .top) {
                            Text("Your\nroadmap")
                                .font(.system(size: 40, weight: .bold, design: .serif))
                                .foregroundStyle(forestGreen)
                                .lineSpacing(-3)

                            Spacer()

                            ProfileAvatarLink(initial: initialLetter)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                    }
                    .frame(height: 125, alignment: .top)

                    // Roadmap Path
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let leftX = width * 0.20
                        let rightX = width * 0.79

                        ZStack(alignment: .topLeading) {
                            Circle()
                                .fill(softCyan.opacity(0.55))
                                .frame(width: 195, height: 195)
                                .position(x: -82, y: min(505, dayY(plan.count - 1) - 40))

                            // Path pieces and day bubbles, only as many as this user's roadmap has.
                            ForEach(0..<max(plan.count - 1, 0), id: \.self) { i in
                                let seg = segment(i, leftX: leftX, rightX: rightX)
                                roadmapSegment(from: seg.from, to: seg.to,
                                               control1: seg.c1, control2: seg.c2,
                                               completed: completedDays >= i + 1)
                            }

                            // Roadmap Days
                            ForEach(Array(plan.enumerated()), id: \.offset) { i, lesson in
                                roadmapDay(number: i + 1, title: lesson.title,
                                           x: i.isMultiple(of: 2) ? leftX : rightX,
                                           y: dayY(i),
                                           side: i.isMultiple(of: 2) ? .right : .left,
                                           width: width)
                            }
                        }
                    }
                    .frame(height: dayY(plan.count - 1) + 54)

                    Text("One step at a time.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(forestGreen.opacity(0.7))
                        .padding(.bottom, 56)
                }
            }
            .scrollIndicators(.hidden)
            .background(.white)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Vertical position of day `i` (0-based); days are 109 pt apart, zig-zagging left and right.
    private func dayY(_ i: Int) -> CGFloat { 36 + 109 * CGFloat(max(i, 0)) }

    /// Curve from day `i` to day `i + 1`, with the same hand-tuned bends as the original six-day map.
    private func segment(_ i: Int, leftX: CGFloat, rightX: CGFloat)
        -> (from: CGPoint, to: CGPoint, c1: CGPoint, c2: CGPoint) {
        // (x offset of control 1, its y relative to the start day, x offset of control 2, its y)
        let bends: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (-8, 67, 25, 46), (25, 72, -30, 43), (-20, 68, 20, 56), (18, 63, -25, 57), (-25, 63, 20, 51)
        ]
        let b = bends[i % bends.count]
        let startsLeft = i.isMultiple(of: 2)
        let fromX = startsLeft ? leftX : rightX
        let toX = startsLeft ? rightX : leftX
        let y = dayY(i)
        return (CGPoint(x: fromX, y: y), CGPoint(x: toX, y: dayY(i + 1)),
                CGPoint(x: fromX + b.0, y: y + b.1), CGPoint(x: toX + b.2, y: y + b.3))
    }

    // Roadmap Lines
    private func roadmapSegment(from start: CGPoint, to end: CGPoint,
                                control1: CGPoint, control2: CGPoint,
                                completed: Bool) -> some View {
        Path { path in
            path.move(to: start)
            path.addCurve(to: end, control1: control1, control2: control2)
        }
        .stroke(
            completed ? forestGreen : completedGreen,
            style: StrokeStyle(
                lineWidth: completed ? 6 : 5,
                lineCap: .round,
                dash: completed ? [] : [1, 11]
            )
        )
    }

    // Roadmap Days
    private enum LabelSide { case left, right }

    @ViewBuilder
    private func roadmapDay(number: Int, title: String, x: CGFloat, y: CGFloat, side: LabelSide, width: CGFloat) -> some View {
        if number <= completedDays {
            completedDay(number: number, title: title, x: x, y: y, side: side, width: width)
        } else if number == completedDays + 1 {
            currentDay(number: number, title: title, x: x, y: y, side: side, width: width)
        } else {
            lockedDay(number: number, title: title, x: x, y: y, side: side, width: width)
        }
    }

    private func currentDay(number: Int, title: String, x: CGFloat, y: CGFloat, side: LabelSide, width: CGFloat) -> some View {
        Group {
            NavigationLink {
                practiceDestination(for: number)
            } label: {
                Text("\(number)")
                    .font(.system(size: 44, weight: .bold, design: .serif))
                    .foregroundStyle(forestGreen)
                    .frame(width: 100, height: 100)
                    .background(ScallopedShape().fill(periwinkle))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .position(x: x, y: y)

            VStack(alignment: side == .right ? .leading : .trailing, spacing: 3) {
                Text("DAY \(number)").font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                Text("Today · about \(RoadmapPlan.lesson(day: number, focus: focus).duration)").font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(forestGreen)
            .frame(width: width * 0.53, alignment: side == .right ? .leading : .trailing)
            .position(x: side == .right ? width * 0.64 : width * 0.37, y: y)
        }
    }

    private func practiceDestination(for day: Int) -> some View {
        PracticeSelectionView(day: day, scenario: RoadmapPlan.lesson(day: day, focus: focus).title)
            .modifier(HidesUTalkTabBar())
    }

    private func completedDay(number: Int, title: String, x: CGFloat, y: CGFloat, side: LabelSide, width: CGFloat) -> some View {
        Group {
            // Completed days can be practiced again; replaying doesn't change progress.
            NavigationLink {
                practiceDestination(for: number)
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(forestGreen)
                    .frame(width: 60, height: 60)
                    .background(completedGreen, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Day \(number), \(title), done. Practice again")
            .position(x: x, y: y)

            VStack(alignment: side == .right ? .leading : .trailing, spacing: 3) {
                Text("DAY \(number)")
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                Text("Done · tap to repeat")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(forestGreen)
            .frame(width: width * 0.53, alignment: side == .right ? .leading : .trailing)
            .position(x: side == .right ? width * 0.64 : width * 0.37, y: y)
        }
    }

    private func lockedDay(number: Int, title: String, x: CGFloat, y: CGFloat, side: LabelSide, width: CGFloat) -> some View {
        Group {
            Circle()
                .fill(.white)
                .frame(width: 60, height: 60)
                .overlay(Circle().strokeBorder(forestGreen.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [2, 3])))
                .overlay(Image(systemName: "lock").font(.system(size: 18)).foregroundStyle(forestGreen))
                .position(x: x, y: y)

            VStack(alignment: side == .right ? .leading : .trailing, spacing: 3) {
                Text("DAY \(number)")
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                Text("Locked")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(forestGreen.opacity(0.75))
            .frame(width: width * 0.53, alignment: side == .right ? .leading : .trailing)
            .position(x: side == .right ? width * 0.64 : width * 0.37, y: y)
        }
    }

    // Navigation Item
}

#Preview {
    NavigationStack {
        RoadmapView()
    }
}

// Current Day Badge
private struct ScallopedShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let points = 16
        for index in 0..<(points * 2) {
            let angle = Double(index) * .pi / Double(points) - .pi / 2
            let r = index.isMultiple(of: 2) ? radius : radius * 0.92
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * r,
                                y: center.y + CGFloat(sin(angle)) * r)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
