// Copyright (c) 2026 Satriya Dwi Mahardhika

import Foundation
import SwiftData
import SwiftUI

@Observable
final class CycleViewModel {
    
    var summary: CycleSummary?
    var prediction: PredictionResult?
    var statistics: CycleStatistics?
    var warnings: [HealthWarning] = []
    
    
    func recalculate(from logs: [DailyLog]) {
        
        guard !logs.isEmpty else {
            summary = nil
            prediction = nil
            statistics = nil
            warnings = []
            return
        }
        
        //--------------------------------------------------
        // 1️⃣ Core Engine (Single Source of Truth)
        //--------------------------------------------------
        
        let cycleSummary = CycleEngine.analyze(logs: logs)
        summary = cycleSummary
        
        
        //--------------------------------------------------
        // 2️⃣ Prediction (Date Conversion Only)
        //--------------------------------------------------
        
        prediction = PredictionEngine.predict(
            today: Date(),
            logs: logs,
            summary: cycleSummary
        )
        
        
        //--------------------------------------------------
        // 3️⃣ Statistics (Display Layer Only)
        //--------------------------------------------------
        
        statistics = StatisticsEngine.calculateStatistics(
            logs: logs,
            summary: cycleSummary
        )
        
        
        //--------------------------------------------------
        // 4️⃣ Health Warnings (Mapping Only)
        //--------------------------------------------------
        
        warnings = HealthWarningEngine.evaluate(
            summary: cycleSummary,
            logs: logs
        )
    }
}
