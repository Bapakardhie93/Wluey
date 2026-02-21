// Copyright (c) 2026 Satriya Dwi Mahardhika

import Foundation


struct HealthWarning: Identifiable, Equatable {
    let id: String
    let message: String
    
    init(message: String) {
        self.message = message
        self.id = message
    }
}

struct HealthWarningEngine {
    
    static func evaluate(
        summary: CycleSummary,
        logs: [DailyLog]
    ) -> [HealthWarning] {
        
        var warnings: [HealthWarning] = []
        let calendar = Calendar.current
        
        //--------------------------------------------------
        // 1️⃣ Long Period
        //--------------------------------------------------
        
        if summary.longPeriodWarning {
            warnings.append(
                HealthWarning(
                    message: "Durasi haid lebih panjang dari normal. Jika berulang, pertimbangkan konsultasi medis."
                )
            )
        }
        
        //--------------------------------------------------
        // 2️⃣ Irregular Cycle
        //--------------------------------------------------
        
        if summary.isIrregular {
            warnings.append(
                HealthWarning(
                    message: "Siklus tampak tidak stabil. Prediksi mungkin kurang akurat."
                )
            )
        }
        
        //--------------------------------------------------
        // 3️⃣ Short Luteal
        //--------------------------------------------------
        
        if summary.lutealDefectRisk {
            warnings.append(
                HealthWarning(
                    message: "Fase luteal lebih pendek dari normal."
                )
            )
        }
        
        //--------------------------------------------------
        // 4️⃣ PCOS Pattern
        //--------------------------------------------------
        
        if summary.pcosRisk {
            warnings.append(
                HealthWarning(
                    message: "Pola siklus menunjukkan variasi yang perlu dipantau."
                )
            )
        }
        
        //--------------------------------------------------
        // 5️⃣ Low Confidence
        //--------------------------------------------------
        
        if summary.confidenceScore < 65 {
            warnings.append(
                HealthWarning(
                    message: "Data belum cukup stabil untuk prediksi yang konsisten."
                )
            )
        }
        
        //--------------------------------------------------
        // 6️⃣ Very Late Period (> 60 hari)
        //--------------------------------------------------
        
        if let lastStart = logs
            .filter({ $0.flowLevel != .none })
            .sorted(by: { $0.date < $1.date })
            .last?
            .date {
            
            let daysSinceLast = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: lastStart),
                to: Date()
            ).day ?? 0
            
            if daysSinceLast > 60 {
                warnings.append(
                    HealthWarning(
                        message: "Sudah lebih dari 60 hari sejak haid terakhir."
                    )
                )
            }
        }
        
        return warnings
    }
}
