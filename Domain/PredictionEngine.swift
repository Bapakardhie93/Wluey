// Copyright (c) 2026 Satriya Dwi Mahardhika

import Foundation

struct PredictionResult {
    let nextPeriodDate: Date?
    let ovulationDate: Date?
    let daysUntilNextPeriod: Int?
    let currentPhase: String
}

struct PredictionEngine {
    
    static func predict(
        today: Date,
        logs: [DailyLog],
        summary: CycleSummary
    ) -> PredictionResult {
        
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)
        
        guard let lastStart = lastCycleStart(from: logs) else {
            return PredictionResult(
                nextPeriodDate: nil,
                ovulationDate: nil,
                daysUntilNextPeriod: nil,
                currentPhase: "Belum cukup data"
            )
        }
        
        let cycleLength = summary.averageCycleLength
        
        //--------------------------------------------------
        // 🔥 Drift Correction (antisipasi telat input)
        //--------------------------------------------------
        
        let daysSinceLast = calendar.dateComponents(
            [.day],
            from: lastStart,
            to: todayStart
        ).day ?? 0
        
        let cyclesPassed = max(daysSinceLast / cycleLength, 0)
        
        let adjustedStart = calendar.date(
            byAdding: .day,
            value: cyclesPassed * cycleLength,
            to: lastStart
        ) ?? lastStart
        
        //--------------------------------------------------
        // 🔥 Next Period
        //--------------------------------------------------
        
        let nextPeriod = calendar.date(
            byAdding: .day,
            value: cycleLength,
            to: adjustedStart
        )
        
        //--------------------------------------------------
        // 🔥 Ovulation Date
        //--------------------------------------------------
        
        let ovulation = calendar.date(
            byAdding: .day,
            value: summary.predictedOvulationDay - 1,
            to: adjustedStart
        )
        
        //--------------------------------------------------
        // 🔥 Days Until
        //--------------------------------------------------
        
        var daysUntil: Int? = nil
        
        if let next = nextPeriod {
            let diff = calendar.dateComponents(
                [.day],
                from: todayStart,
                to: next
            ).day ?? 0
            
            daysUntil = max(diff, 0)
        }
        
        //--------------------------------------------------
        // 🔥 Phase
        //--------------------------------------------------
        
        let phase = determinePhase(
            today: todayStart,
            lastStart: adjustedStart,
            summary: summary
        )
        
        return PredictionResult(
            nextPeriodDate: nextPeriod,
            ovulationDate: ovulation,
            daysUntilNextPeriod: daysUntil,
            currentPhase: phase
        )
    }
}

//////////////////////////////////////////////////////////
// MARK: - Phase Logic
//////////////////////////////////////////////////////////

private extension PredictionEngine {
    
    static func determinePhase(
        today: Date,
        lastStart: Date,
        summary: CycleSummary
    ) -> String {
        
        let calendar = Calendar.current
        
        let diff = calendar.dateComponents(
            [.day],
            from: lastStart,
            to: today
        ).day ?? 0
        
        let day = max(diff + 1, 1)
        
        let periodEnd = summary.averagePeriodLength
        let fertile = summary.fertileWindow
        let ovulationRange = summary.ovulationUncertainty
        let cycleLength = summary.averageCycleLength
        
        if day <= periodEnd {
            return "Menstruasi"
        }
        
        if ovulationRange.contains(day) {
            return "Ovulasi"
        }
        
        if fertile.contains(day) {
            return "Masa Subur"
        }
        
        if day < fertile.lowerBound {
            return "Folikular"
        }
        
        if day <= cycleLength {
            return "Luteal"
        }
        
        if day <= cycleLength + 5 {
            return "Luteal (Terlambat)"
        }
        
        return "Menunggu data"
    }
    
    //--------------------------------------------------
    // 🔥 Ambil hari pertama blok period terakhir
    //--------------------------------------------------
    
    static func lastCycleStart(from logs: [DailyLog]) -> Date? {
        
        let calendar = Calendar.current
        let sorted = logs.sorted { $0.date < $1.date }
        
        var lastBlockStart: Date? = nil
        var inBlock = false
        
        for log in sorted {
            let isPeriod = log.flowLevel != .none
            
            if isPeriod && !inBlock {
                lastBlockStart = calendar.startOfDay(for: log.date)
                inBlock = true
            }
            
            if !isPeriod {
                inBlock = false
            }
        }
        
        return lastBlockStart
    }
}
