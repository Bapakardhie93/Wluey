// Copyright (c) 2026 Satriya Dwi Mahardhika

import Foundation

struct CycleStatistics {
    let averageCycleLength: Double
    let averagePeriodLength: Double
    let standardDeviation: Double
    let cycleCount: Int
}

struct StatisticsEngine {
    
    static func calculateStatistics(
        logs: [DailyLog],
        summary: CycleSummary
    ) -> CycleStatistics {
        
        //--------------------------------------------------
        // 1️⃣ Extract Periods (untuk hitung count saja)
        //--------------------------------------------------
        
        let periods = PeriodExtractor.extractPeriods(from: logs)
        let cycleCount = max(periods.count - 1, 0)
        
        //--------------------------------------------------
        // 2️⃣ Gunakan data dari CycleEngine (Single Source)
        //--------------------------------------------------
        
        return CycleStatistics(
            averageCycleLength: Double(summary.averageCycleLength),
            averagePeriodLength: Double(summary.averagePeriodLength),
            standardDeviation: estimateDisplayStdDev(
                isIrregular: summary.isIrregular,
                confidence: summary.confidenceScore
            ),
            cycleCount: cycleCount
        )
    }
}

private extension StatisticsEngine {
    
    // Estimasi ringan untuk display saja
    static func estimateDisplayStdDev(
        isIrregular: Bool,
        confidence: Int
    ) -> Double {
        
        if isIrregular {
            return 6.0
        }
        
        if confidence < 70 {
            return 4.0
        }
        
        return 2.0
    }
}
