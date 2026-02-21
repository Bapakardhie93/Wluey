// Copyright (c) 2026 Satriya Dwi Mahardhika

import SwiftUI
import SwiftData

struct HistoryView: View {
    
    @Query(sort: \DailyLog.date, order: .forward)
    private var logs: [DailyLog]
    
    @State private var selectedDate: Date? = nil
    @State private var displayedYear = Calendar.current.component(.year, from: Date())
    
    @State private var showPopup = false
    @State private var navigateToMonitor = false
    
    private let calendar = Calendar.current
    private let weekdays = ["M","S","S","R","K","J","S"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                ScrollView {
                    VStack(spacing: 40) {
                        
                        yearHeader
                        
                        ForEach(monthsInYear(displayedYear), id: \.self) { month in
                            monthSection(for: month)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
                .navigationTitle("Riwayat")
                .blur(radius: showPopup ? 6 : 0)
                .animation(.easeInOut(duration: 0.2), value: showPopup)
                
                if showPopup, let date = selectedDate {
                    popupOverlay(for: date)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .navigationDestination(isPresented: $navigateToMonitor) {
                if let date = selectedDate {
                    MonitorView(selectedDate: date)
                }
            }
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - Year Header
//////////////////////////////////////////////////////////

extension HistoryView {
    
    private var yearHeader: some View {
        HStack {
            Button { displayedYear -= 1 } label: {
                Image(systemName: "chevron.left")
            }
            
            Spacer()
            
            Text(String(displayedYear))
                .font(.title.bold())
            
            Spacer()
            
            Button { displayedYear += 1 } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.vertical)
    }
}

//////////////////////////////////////////////////////////
// MARK: - Month Section
//////////////////////////////////////////////////////////

extension HistoryView {
    
    private func monthSection(for month: Date) -> some View {
        
        VStack(alignment: .leading, spacing: 12) {
            
            Text(monthTitle(month))
                .font(.title3.bold())
            
            weekdayHeader
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7),
                spacing: 10
            ) {
                ForEach(generateGridDates(for: month), id: \.self) { date in
                    
                    if calendar.isDate(date, equalTo: month, toGranularity: .month) {
                        dayCell(for: date)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - Weekday Header
//////////////////////////////////////////////////////////

extension HistoryView {
    
    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.secondary)
            }
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - Day Cell
//////////////////////////////////////////////////////////

extension HistoryView {
    
    private func dayCell(for date: Date) -> some View {
        
        let day = calendar.component(.day, from: date)
        
        let isPeriod = isMenstruation(date)
        let cycleData = cycleInfo(for: date)
        
        let isFertile = cycleData?.isFertile ?? false
        let isOvulation = cycleData?.isOvulation ?? false
        
        let isSelected = selectedDate != nil &&
            calendar.isDate(selectedDate!, inSameDayAs: date)
        
        return ZStack {
            
            if isFertile {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.teal.opacity(0.85))
            }
            
            if isPeriod {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.pink.opacity(0.9))
            }
            
            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.teal, lineWidth: 3)
            }
            
            VStack(spacing: 3) {
                Text("\(day)")
                    .foregroundColor(
                        (isPeriod || isFertile) ? .white : .primary
                    )
                
                if isOvulation {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(height: 44)
        .onTapGesture {
            selectedDate = date
            withAnimation {
                showPopup = true
            }
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - Modern Popup
//////////////////////////////////////////////////////////

extension HistoryView {
    
    private func popupOverlay(for date: Date) -> some View {
        
        let log = logs.first {
            calendar.isDate($0.date, inSameDayAs: date)
        }
        
        return ZStack {
            
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showPopup = false
                    }
                }
            
            VStack(spacing: 20) {
                
                Capsule()
                    .frame(width: 40, height: 5)
                    .foregroundColor(.gray.opacity(0.4))
                    .padding(.top, 8)
                
                Text(formattedDate(date))
                    .font(.title3.bold())
                
                Divider()
                
                if let log = log {
                    
                    VStack(alignment: .leading, spacing: 10) {
                        infoRow("Aliran", label(for: log.flowLevel))
                        infoRow("Nyeri", "\(log.painLevel)/10")
                        infoRow("Energi", "\(log.energyLevel)/5")
                        
                        if let notes = log.notes, !notes.isEmpty {
                            Text("Catatan")
                                .font(.headline)
                                .padding(.top, 6)
                            Text(notes)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                } else {
                    Text("Belum ada catatan untuk tanggal ini.")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        showPopup = false
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        navigateToMonitor = true
                    }
                    
                } label: {
                    Text("Edit Selengkapnya")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 420)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(UIColor.systemBackground))
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showPopup)
        }
    }
    
    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: date)
    }
    
    private func label(for level: FlowLevel) -> String {
        switch level {
        case .none: return "Tidak"
        case .spotting: return "Flek"
        case .light: return "Sedikit"
        case .medium: return "Sedang"
        case .heavy: return "Banyak"
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - Logic
//////////////////////////////////////////////////////////

extension HistoryView {
    
    private func isMenstruation(_ date: Date) -> Bool {
        logs.contains {
            calendar.isDate($0.date, inSameDayAs: date)
            && $0.flowLevel != .none
        }
    }
    
    private func cycleInfo(for date: Date) -> CycleDayInfo? {
        
        let periods = PeriodExtractor.extractPeriods(from: logs)
        guard periods.count >= 1 else { return nil }
        
        let sorted = periods.sorted { $0.startDate < $1.startDate }
        
        guard let index = sorted.lastIndex(where: { $0.startDate <= date }) else {
            return nil
        }
        
        let start = sorted[index].startDate
        
        let cycleLength: Int
        
        if index < sorted.count - 1 {
            let nextStart = sorted[index + 1].startDate
            cycleLength = calendar.dateComponents(
                [.day],
                from: start,
                to: nextStart
            ).day ?? 28
        } else {
            cycleLength = CycleEngine.analyze(logs: logs).averageCycleLength
        }
        
        let day = calendar.dateComponents(
            [.day],
            from: start,
            to: date
        ).day ?? 0
        
        let cycleDay = day + 1
        
        let summary = CycleEngine.analyze(logs: logs)
        let luteal = summary.adaptiveLutealLength
        
        let ovulation = max(cycleLength - luteal, 1)
        let fertileStart = max(ovulation - 5, 1)
        let fertileEnd = min(ovulation + 1, cycleLength)
        
        return CycleDayInfo(
            isFertile: (fertileStart...fertileEnd).contains(cycleDay),
            isOvulation: cycleDay == ovulation
        )
    }
}

//////////////////////////////////////////////////////////
// MARK: - Date Helpers
//////////////////////////////////////////////////////////

extension HistoryView {
    
    private func monthsInYear(_ year: Int) -> [Date] {
        let months = (1...12).compactMap { month in
            calendar.date(from: DateComponents(year: year, month: month))
        }
        
        return displayedYear < Calendar.current.component(.year, from: Date())
            ? months.reversed()
            : months
    }
    
    private func generateGridDates(for month: Date) -> [Date] {
        
        guard let firstDay = calendar.date(
            from: calendar.dateComponents([.year, .month], from: month)
        ) else { return [] }
        
        let weekday = calendar.component(.weekday, from: firstDay)
        let offset = weekday - calendar.firstWeekday
        
        let startDate = calendar.date(byAdding: .day,
                                      value: -offset,
                                      to: firstDay)!
        
        return (0..<42).map {
            calendar.date(byAdding: .day, value: $0, to: startDate)!
        }
    }
    
    private func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale(identifier: "id_ID")
        return formatter.string(from: date)
    }
}

struct CycleDayInfo {
    let isFertile: Bool
    let isOvulation: Bool
}
