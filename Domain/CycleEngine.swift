// Copyright (c) 2026 Satriya Dwi Mahardhika

import Foundation

struct CycleSummary {
    let averageCycleLength: Int
    let averagePeriodLength: Int
    let currentCycleDay: Int
    
    let predictedOvulationDay: Int
    let fertileWindow: ClosedRange<Int>
    let ovulationUncertainty: ClosedRange<Int>
    
    let confidenceScore: Int
    let isIrregular: Bool
    
    let adaptiveLutealLength: Int
    
    let longPeriodWarning: Bool
    let shortLutealWarning: Bool
    
    let pregnancyProbability: Double
    
    let hormonalEnergyScore: Int
    let pmsProbability: Double
    let anomalyScore: Int
    let possibleEarlyPregnancy: Bool
    let implantationWindow: ClosedRange<Int>
    let fertilityRiskIndex: Int
    let lutealDefectRisk: Bool
    let pcosRisk: Bool
}

struct CycleEngine {
    
    static func analyze(logs: [DailyLog]) -> CycleSummary {
        
        let periods = PeriodExtractor.extractPeriods(from: logs)
        let rawCycles = buildCycleLengths(from: periods)
        
        let filtered = removeOutliers(from: rawCycles)
        let smoothed = exponentialSmoothing(filtered)
        
        let avgCycle = weightedRobustAverage(smoothed, defaultValue: 28)
        let avgPeriod = averagePeriodLength(periods: periods)
        let currentDay = currentCycleDay(from: periods)
        
        let adaptiveLuteal = calculateAdaptiveLuteal(diffs: smoothed)
        
        let baselineOvulation = avgCycle - adaptiveLuteal
        
        let ovulation = max(
            recalibratedOvulationDay(
                baseline: baselineOvulation,
                cycles: smoothed
            ),
            1
        )
        
        let fertile = max(ovulation - 5, 1)...ovulation
        
        let stdDev = standardDeviation(smoothed)
        
        let ovulationRange: ClosedRange<Int> = {
            if stdDev > 4 {
                return max(ovulation - 2, 1)...min(ovulation + 2, avgCycle)
            } else {
                return max(ovulation - 1, 1)...min(ovulation + 1, avgCycle)
            }
        }()
        
        var confidence = enhancedConfidence(
            diffs: smoothed,
            luteal: adaptiveLuteal
        )
        
        let irregular = detectIrregular(diffs: smoothed)
        let longPeriod = avgPeriod > 10
        let shortLuteal = adaptiveLuteal < 11
        
        let pregnancyChance = fertilityProbability(
            currentDay: currentDay,
            ovulation: ovulation
        )
        
        let implantation = adaptiveImplantationWindow(
            ovulation: ovulation,
            lutealLength: adaptiveLuteal,
            cycleLength: avgCycle
        )
        
        let fertilityIndex = fertilityHeatmapIndex(
            day: currentDay,
            ovulation: ovulation
        )
        
        let lutealRisk = adaptiveLuteal < 11
        
        let pcos = detectPCOSPattern(cycles: smoothed)
        
        let anomaly = anomalyScoring(
            cycles: smoothed,
            currentLength: avgCycle
        )
        
        let earlyPregnancy = detectEarlyPregnancy(
            currentDay: currentDay,
            cycleLength: avgCycle
        )
        
        let energy = hormonalEnergyPrediction(
            day: currentDay,
            cycleLength: avgCycle
        )
        
        let pms = pmsProbabilityModel(
            day: currentDay,
            cycleLength: avgCycle
        )
        
        if lutealRisk { confidence -= 8 }
        if pcos { confidence -= 12 }
        if anomaly > 40 { confidence -= 5 }
        
        confidence = Int(max(min(confidence, 92), 35))
        
        return CycleSummary(
            averageCycleLength: avgCycle,
            averagePeriodLength: avgPeriod,
            currentCycleDay: currentDay,
            predictedOvulationDay: ovulation,
            fertileWindow: fertile,
            ovulationUncertainty: ovulationRange,
            confidenceScore: confidence,
            isIrregular: irregular,
            adaptiveLutealLength: adaptiveLuteal,
            longPeriodWarning: longPeriod,
            shortLutealWarning: shortLuteal,
            pregnancyProbability: pregnancyChance,
            hormonalEnergyScore: energy,
            pmsProbability: pms,
            anomalyScore: anomaly,
            possibleEarlyPregnancy: earlyPregnancy,
            implantationWindow: implantation,
            fertilityRiskIndex: fertilityIndex,
            lutealDefectRisk: lutealRisk,
            pcosRisk: pcos
        )
    }
}

private extension CycleEngine {
    
    static func buildCycleLengths(from periods: [Period]) -> [Int] {
        guard periods.count >= 2 else { return [] }
        return (0..<periods.count-1).map {
            Calendar.current.dateComponents(
                [.day],
                from: periods[$0].startDate,
                to: periods[$0+1].startDate
            ).day ?? 28
        }
    }
    
    static func removeOutliers(from values: [Int]) -> [Int] {
        guard values.count >= 4 else { return values }
        
        let sorted = values.sorted()
        let q1 = sorted[sorted.count / 4]
        let q3 = sorted[(sorted.count * 3) / 4]
        let iqr = q3 - q1
        
        let lower = q1 - Int(Double(iqr) * 1.5)
        let upper = q3 + Int(Double(iqr) * 1.5)
        
        return values.filter { $0 >= lower && $0 <= upper }
    }
    
    static func exponentialSmoothing(_ values: [Int]) -> [Int] {
        guard values.count >= 2 else { return values }
        var result: [Int] = []
        var previous = Double(values[0])
        result.append(values[0])
        let alpha = 0.4
        
        for i in 1..<values.count {
            let newValue = alpha * Double(values[i]) +
                           (1 - alpha) * previous
            previous = newValue
            result.append(Int(round(newValue)))
        }
        return result
    }
    
    static func weightedRobustAverage(_ values: [Int], defaultValue: Int) -> Int {
        guard !values.isEmpty else { return defaultValue }
        let sorted = values.sorted()
        let median = sorted[sorted.count / 2]
        
        let weighted = values.enumerated().map { index, value in
            Double(value) * pow(1.12, Double(index))
        }.reduce(0,+)
        
        let weightSum = values.enumerated().map {
            pow(1.12, Double($0.offset))
        }.reduce(0,+)
        
        let weightedAvg = weighted / weightSum
        let final = (Double(median) * 0.5) + (weightedAvg * 0.5)
        
        return Int(round(final))
    }
    
    static func calculateAdaptiveLuteal(diffs: [Int]) -> Int {
        guard diffs.count >= 3 else { return 13 }
        
        let stdDev = standardDeviation(diffs)
        
        if stdDev < 1.5 { return 14 }
        if stdDev < 3.5 { return 13 }
        return 12
    }
    
    static func recalibratedOvulationDay(
        baseline: Int,
        cycles: [Int]
    ) -> Int {
        guard cycles.count >= 3 else { return baseline }
        
        let last = cycles.last!
        let avg = Double(cycles.reduce(0,+)) / Double(cycles.count)
        
        if Double(last) > avg + 2 { return baseline + 1 }
        if Double(last) < avg - 2 { return baseline - 1 }
        return baseline
    }
    
    static func enhancedConfidence(
        diffs: [Int],
        luteal: Int
    ) -> Int {
        guard !diffs.isEmpty else { return 40 }
        
        let stdDev = standardDeviation(diffs)
        
        var score = 85 - (stdDev * 4)
        let dataBonus = min(Double(diffs.count) * 3, 18)
        score += dataBonus
        
        if luteal < 11 || luteal > 15 {
            score -= 8
        }
        
        score -= 4
        
        return Int(score)
    }
    
    static func detectIrregular(diffs: [Int]) -> Bool {
        guard let max = diffs.max(),
              let min = diffs.min()
        else { return false }
        return (max - min) > 7
    }
    
    static func averagePeriodLength(periods: [Period]) -> Int {
        guard !periods.isEmpty else { return 5 }
        
        let durations = periods.map { $0.duration }.sorted()
        let median = durations[durations.count / 2]
        
        let filtered = durations.filter {
            abs($0 - median) <= 3
        }
        
        let avg = Double(filtered.reduce(0,+)) / Double(filtered.count)
        return Int(round(avg))
    }
    
    static func currentCycleDay(from periods: [Period]) -> Int {
        guard let last = periods.last else { return 1 }
        let diff = Calendar.current.dateComponents(
            [.day],
            from: last.startDate,
            to: Date()
        ).day ?? 0
        return max(diff + 1, 1)
    }
    
    static func fertilityProbability(
        currentDay: Int,
        ovulation: Int
    ) -> Double {
        
        let offset = currentDay - ovulation
        
        let probability: Double
        
        switch offset {
        case -5: probability = 0.03
        case -4: probability = 0.06
        case -3: probability = 0.12
        case -2: probability = 0.22
        case -1: probability = 0.30
        case 0:  probability = 0.20
        case 1:  probability = 0.08
        default: probability = 0.01
        }
        
        return min(max(probability, 0.01), 0.33)
    }
    
    static func adaptiveImplantationWindow(
        ovulation: Int,
        lutealLength: Int,
        cycleLength: Int
    ) -> ClosedRange<Int> {
        let start = ovulation + max(5, lutealLength / 2 - 2)
        let end = min(ovulation + 10, cycleLength)
        return start...end
    }
    
    static func fertilityHeatmapIndex(
        day: Int,
        ovulation: Int
    ) -> Int {
        let distance = abs(day - ovulation)
        let score = max(0, 100 - distance * 15)
        return min(score, 100)
    }
    
    static func detectPCOSPattern(cycles: [Int]) -> Bool {
        guard cycles.count >= 4 else { return false }
        
        let longCycles = cycles.filter { $0 > 35 }.count
        let variability = (cycles.max() ?? 0) - (cycles.min() ?? 0)
        
        return longCycles >= 2 && variability > 10
    }
    
    static func anomalyScoring(
        cycles: [Int],
        currentLength: Int
    ) -> Int {
        guard !cycles.isEmpty else { return 0 }
        let avg = Double(cycles.reduce(0,+)) / Double(cycles.count)
        let deviation = abs(Double(currentLength) - avg)
        return Int(min(deviation * 4, 100))
    }
    
    static func detectEarlyPregnancy(
        currentDay: Int,
        cycleLength: Int
    ) -> Bool {
        return currentDay > cycleLength + 3
    }
    
    static func hormonalEnergyPrediction(
        day: Int,
        cycleLength: Int
    ) -> Int {
        let phase = Double(day) / Double(cycleLength)
        let energy = 60 + 22 * sin(phase * 2 * .pi)
        return Int(max(min(energy, 95), 35))
    }
    
    static func pmsProbabilityModel(
        day: Int,
        cycleLength: Int
    ) -> Double {
        let lutealStart = cycleLength - 10
        let x = Double(day - lutealStart)
        let sigmoid = 1 / (1 + exp(-0.7 * x))
        return min(max(sigmoid * 0.75, 0.05), 0.85)
    }
    
    static func standardDeviation(_ values: [Int]) -> Double {
        guard !values.isEmpty else { return 0 }
        let avg = Double(values.reduce(0,+)) / Double(values.count)
        let variance = values.map {
            pow(Double($0) - avg, 2)
        }.reduce(0,+) / Double(values.count)
        return sqrt(variance)
    }
}
