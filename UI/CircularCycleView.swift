// Copyright (c) 2026 Satriya Dwi Mahardhika

import SwiftUI

struct CircularCycleView: View {
    
    let startDate: Date
    let cycleLength: Int
    let periodLength: Int
    let fertileWindow: ClosedRange<Int>
    let ovulationDay: Int
    
    // 1. Ketebalan disesuaikan, tidak berlebihan tapi tetap tebal
    private let circleSize: CGFloat = 280
    private let lineWidth: CGFloat = 36
    
    @State private var dragProgress: Double? = nil
    @State private var isDragging: Bool = false
    @State private var isBreathing: Bool = false
    
    private var calendar: Calendar { .current }
    
    var body: some View {
        ZStack {
            // Organic Breathing Glow di belakang lingkaran
            Circle()
                .fill(Color(UIColor.systemBackground))
                .frame(width: circleSize)
                .shadow(color: phaseColor(for: currentDisplayedDay()).opacity(0.15),
                        radius: isBreathing ? 40 : 20,
                        x: 0, y: isBreathing ? 10 : 0)
                .scaleEffect(isBreathing ? 1.02 : 0.98)
            
            baseTrack
            periodArc
            fertileArc
            ovulationArc
            
            centerContent
            draggableBubble
        }
        .frame(width: circleSize, height: circleSize)
        .padding()
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                isBreathing.toggle()
            }
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - Base & Arcs
//////////////////////////////////////////////////////////

extension CircularCycleView {
    
    private var baseTrack: some View {
        Circle()
            .stroke(Color.gray.opacity(0.15),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: [6, 8]))
            .rotationEffect(.degrees(-90))
    }
    
    private var periodArc: some View {
        Circle()
            .trim(from: 0, to: Double(periodLength) / Double(cycleLength))
            .stroke(
                AngularGradient(gradient: Gradient(colors: [Color.pink.opacity(0.6), Color.red]),
                                center: .center, startAngle: .degrees(-90), endAngle: .degrees(90)),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .shadow(color: Color.red.opacity(0.3), radius: isBreathing ? 8 : 4)
    }
    
    private var fertileArc: some View {
        Circle()
            .trim(from: Double(fertileWindow.lowerBound) / Double(cycleLength),
                  to: Double(fertileWindow.upperBound) / Double(cycleLength))
            .stroke(
                AngularGradient(gradient: Gradient(colors: [Color.teal.opacity(0.5), Color.blue]),
                                center: .center),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
            .shadow(color: Color.blue.opacity(0.3), radius: isBreathing ? 8 : 4)
    }
    
    private var ovulationArc: some View {
        Circle()
            .trim(from: Double(ovulationDay - 1) / Double(cycleLength),
                  to: Double(ovulationDay) / Double(cycleLength))
            .stroke(Color.purple, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .shadow(color: Color.purple.opacity(0.6), radius: isBreathing ? 12 : 6)
    }
}

//////////////////////////////////////////////////////////
// MARK: - Draggable Bubble
//////////////////////////////////////////////////////////

extension CircularCycleView {
    
    private var draggableBubble: some View {
        let baseProgress = Double(currentDay() - 1) / Double(cycleLength)
        let progress = dragProgress ?? baseProgress
        let angle = progress * 360
        
        let radius = circleSize / 2
        let radians = (angle - 90) * .pi / 180
        
        let x = cos(radians) * radius
        let y = sin(radians) * radius
        
        let currentDayVal = dayFromProgress(progress)
        let color = phaseColor(for: currentDayVal)
        
        // 2. Lingkaran hari dan font diperbesar
        let bubbleSize: CGFloat = isDragging ? 80 : 64
        let fontSize: CGFloat = isDragging ? 26 : 22
        
        return ZStack {
            Circle()
                .fill(.ultraThickMaterial)
                .frame(width: bubbleSize, height: bubbleSize)
                .shadow(color: color.opacity(isDragging ? 0.4 : 0.2),
                        radius: isDragging ? 15 : 8, y: isDragging ? 8 : 4)
            
            Circle()
                .stroke(color, lineWidth: isDragging ? 4 : 2)
                .frame(width: bubbleSize, height: bubbleSize)
            
            Text("\(currentDayVal)")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .offset(x: x, y: y)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isDragging)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    let vector = CGVector(dx: value.location.x - circleSize/2,
                                          dy: value.location.y - circleSize/2)
                    var degrees = atan2(vector.dy, vector.dx) * 180 / .pi
                    degrees += 90
                    if degrees < 0 { degrees += 360 }
                    
                    withAnimation(.interactiveSpring()) {
                        dragProgress = degrees / 360
                    }
                }
                .onEnded { _ in
                    isDragging = false
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        dragProgress = nil
                    }
                }
        )
    }
}

//////////////////////////////////////////////////////////
// MARK: - Center Content
//////////////////////////////////////////////////////////

extension CircularCycleView {
    
    private var centerContent: some View {
        let day = currentDisplayedDay()
        let remaining = max(cycleLength - day, 0)
        
        let safeStart = calendar.startOfDay(for: startDate)
        let safeDate = calendar.startOfDay(for:
            calendar.date(byAdding: .day, value: day - 1, to: safeStart) ?? safeStart
        )
        let currentColor = phaseColor(for: day)
        
        return VStack(spacing: 4) {
            Text(formatted(safeDate).uppercased())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(2)
                .foregroundColor(currentColor.opacity(0.8))
                .animation(.easeInOut, value: currentColor)
            
            Text("\(remaining)")
                .font(.system(size: 84, weight: .thin, design: .rounded))
                .foregroundColor(.primary)
                .contentTransition(.numericText())
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: remaining)
            
            Text("~ Hari menuju haid 🌸 ~")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
            
            Spacer().frame(height: 12)
            
            Text(phaseLabel(for: day))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(currentColor)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(currentColor.opacity(0.15))
                        .overlay(
                            Capsule().stroke(currentColor.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .frame(width: circleSize * 0.7) // Menjaga konten di dalam radius terdalam
    }
}

//////////////////////////////////////////////////////////
// MARK: - Helpers
//////////////////////////////////////////////////////////

extension CircularCycleView {
    
    private func currentDay() -> Int {
        let safeStart = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: Date())
        let diff = calendar.dateComponents([.day], from: safeStart, to: today).day ?? 0
        return max(diff + 1, 1)
    }
    
    private func currentDisplayedDay() -> Int {
        let progress = dragProgress ?? Double(currentDay() - 1) / Double(cycleLength)
        return dayFromProgress(progress)
    }
    
    private func dayFromProgress(_ progress: Double) -> Int {
        min(max(Int(progress * Double(cycleLength)) + 1, 1), cycleLength)
    }
    
    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "id_ID")
        return f.string(from: date)
    }
    
    private func phaseLabel(for day: Int) -> String {
        if day <= periodLength { return "Menstruasi" }
        if day == ovulationDay { return "Ovulasi" }
        if fertileWindow.contains(day) { return "Masa Subur" }
        if day < ovulationDay { return "Folikular" }
        return "Luteal"
    }
    
    private func phaseColor(for day: Int) -> Color {
        if day <= periodLength { return .pink }
        if day == ovulationDay { return .purple }
        if fertileWindow.contains(day) { return .teal }
        return Color.gray.opacity(0.6)
    }
}
