// Copyright (c) 2026 Satriya Dwi Mahardhika

import Foundation

struct CycleResult {
    
    let summary: CycleSummary
    let warnings: [HealthWarning]
    
    init(logs: [DailyLog]) {
        let summary = CycleEngine.analyze(logs: logs)
        
        self.summary = summary
        self.warnings = HealthWarningEngine.evaluate(
            summary: summary,
            logs: logs
        )
    }
}
