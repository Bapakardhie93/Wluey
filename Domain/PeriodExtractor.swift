// Copyright (c) 2026 Satriya Dwi Mahardhika

import Foundation



struct Period {
    let startDate: Date
    let endDate: Date
    
    var duration: Int {
        let calendar = Calendar.current
        
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        
        let diff = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        
        return max(diff + 1, 1)
    }
}

struct PeriodExtractor {
    
    static func extractPeriods(from logs: [DailyLog]) -> [Period] {
        
        let calendar = Calendar.current
        
        // 🔥 Filter hanya hari haid dan normalize ke startOfDay
        let periodDays = logs
            .filter { $0.flowLevel != .none }
            .map { calendar.startOfDay(for: $0.date) }
            .sorted()
        
        guard !periodDays.isEmpty else { return [] }
        
        var periods: [Period] = []
        
        var currentStart = periodDays[0]
        var previousDate = periodDays[0]
        
        for day in periodDays.dropFirst() {
            
            let diff = calendar.dateComponents(
                [.day],
                from: previousDate,
                to: day
            ).day ?? 0
            
            // Jika lompat lebih dari 1 hari → periode baru
            if diff > 2 { //sebelumnya  >1
                periods.append(
                    Period(
                        startDate: currentStart,
                        endDate: previousDate
                    )
                )
                
                currentStart = day
            }
            
            previousDate = day
        }
        
        // Tambahkan periode terakhir
        periods.append(
            Period(
                startDate: currentStart,
                endDate: previousDate
            )
        )
        
        return periods
    }
}
