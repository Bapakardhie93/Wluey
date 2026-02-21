// Copyright (c) 2026 Satriya Dwi Mahardhika

import Foundation

struct ConfidenceResult {
    let score: Int          // 55 – 95
    let label: String       // Rendah / Sedang / Tinggi
}

struct ConfidenceEngine {
    
    static func calculateConfidence(
        cycleCount: Int,
        standardDeviation: Double
    ) -> ConfidenceResult {
        
        guard cycleCount > 0 else {
            return ConfidenceResult(score: 55, label: "Rendah")
        }
        
        //--------------------------------------------------
        //  DATA VOLUME FACTOR (0.4 – 1.0)
        //--------------------------------------------------
        
        // Maksimal dianggap stabil setelah 8 siklus
        let normalizedCycle = min(Double(cycleCount) / 8.0, 1.0)
        
        // Tidak pernah terlalu kecil
        let cycleFactor = 0.4 + (normalizedCycle * 0.6)
        
        
        //--------------------------------------------------
        //  STABILITY FACTOR (berdasarkan std deviation)
        //--------------------------------------------------
        
        // Deviasi 0–2 = sangat stabil
        // 3–4 = normal
        // 5–6 = mulai irregular
        // >6 = sangat irregular
        
        let stabilityFactor: Double
        
        switch standardDeviation {
        case 0..<2:
            stabilityFactor = 1.0
        case 2..<4:
            stabilityFactor = 0.9
        case 4..<6:
            stabilityFactor = 0.75
        case 6..<8:
            stabilityFactor = 0.6
        default:
            stabilityFactor = 0.45
        }
        
        
        //--------------------------------------------------
        //   FINAL SCORE
        //--------------------------------------------------
        
        var rawScore = cycleFactor * stabilityFactor * 100
        
        // Clamp realistic medical range
        rawScore = max(55, min(rawScore, 95))
        
        let finalScore = Int(round(rawScore))
        
        
        //--------------------------------------------------
        //   LABEL
        //--------------------------------------------------
        
        let label: String
        
        switch finalScore {
        case 85...:
            label = "Tinggi"
        case 70..<85:
            label = "Sedang"
        default:
            label = "Rendah"
        }
        
        return ConfidenceResult(
            score: finalScore,
            label: label
        )
    }
}
