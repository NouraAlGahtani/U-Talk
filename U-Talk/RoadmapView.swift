
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
                                .position(x: -82, y: 505)

                            roadmapSegment(
                                from: CGPoint(x: leftX, y: 36),
                                to: CGPoint(x: rightX, y: 145),
                                control1: CGPoint(x: leftX - 8, y: 103),
                                control2: CGPoint(x: rightX + 25, y: 82),
                                completed: completedDays >= 1
                            )

                            roadmapSegment(
                                from: CGPoint(x: rightX, y: 145),
                                to: CGPoint(x: leftX, y: 254),
                                control1: CGPoint(x: rightX + 25, y: 217),
                                control2: CGPoint(x: leftX - 30, y: 188),
                                completed: completedDays >= 2
                            )

                            roadmapSegment(
                                from: CGPoint(x: leftX, y: 254),
                                to: CGPoint(x: rightX, y: 363),
                                control1: CGPoint(x: leftX - 20, y: 322),
                                control2: CGPoint(x: rightX + 20, y: 310),
                                completed: completedDays >= 3
                            )

                            roadmapSegment(
                                from: CGPoint(x: rightX, y: 363),
                                to: CGPoint(x: leftX, y: 472),
                                control1: CGPoint(x: rightX + 18, y: 426),
                                control2: CGPoint(x: leftX - 25, y: 420),
                                completed: completedDays >= 4
                            )

                            roadmapSegment(
                                from: CGPoint(x: leftX, y: 472),
                                to: CGPoint(x: rightX, y: 581),
                                control1: CGPoint(x: leftX - 25, y: 535),
                                control2: CGPoint(x: rightX + 20, y: 523),
                                completed: completedDays >= 5
                            )

                            // Roadmap Days
                            roadmapDay(number: 1, title: plan[0].title, x: leftX, y: 36, side: .right, width: width)
                            roadmapDay(number: 2, title: plan[1].title, x: rightX, y: 145, side: .left, width: width)
                            roadmapDay(number: 3, title: plan[2].title, x: leftX, y: 254, side: .right, width: width)
                            roadmapDay(number: 4, title: plan[3].title, x: rightX, y: 363, side: .left, width: width)
                            roadmapDay(number: 5, title: plan[4].title, x: leftX, y: 472, side: .right, width: width)
                            roadmapDay(number: 6, title: plan[5].title, x: rightX, y: 581, side: .left, width: width)
                        }
                    }
                    .frame(height: 635)

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
