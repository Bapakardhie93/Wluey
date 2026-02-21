// Copyright (c) 2026 Satriya Dwi Mahardhika

import Foundation
import SwiftData

enum FlowLevel: Int, Codable, CaseIterable {
    case none = 0
    case spotting
    case light
    case medium
    case heavy
}

@Model
final class DailyLog {
    
    //--------------------------------------------------
    // MARK: - Identity
    //--------------------------------------------------
    
    @Attribute(.unique)
    var date: Date   // 🔥 Unique by date, not id
    
    var id: UUID
    
    
    //--------------------------------------------------
    // MARK: - Menstrual Data
    //--------------------------------------------------
    
    var flowLevelRaw: Int
    var painLevel: Int
    var bloodColor: String?
    
    var symptomTags: [String]
    var moodTags: [String]
    
    var energyLevel: Int
    var libidoLevel: Int
    
    var notes: String?
    
    
    //--------------------------------------------------
    // MARK: - Metadata
    //--------------------------------------------------
    
    var createdAt: Date
    var updatedAt: Date
    
    
    //--------------------------------------------------
    // MARK: - Init
    //--------------------------------------------------
    
    init(date: Date) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        
        self.flowLevelRaw = FlowLevel.none.rawValue
        self.painLevel = 0
        self.bloodColor = nil
        
        self.symptomTags = []
        self.moodTags = []
        
        self.energyLevel = 3
        self.libidoLevel = 2
        
        self.notes = nil
        
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    
    //--------------------------------------------------
    // MARK: - Computed Properties
    //--------------------------------------------------
    
    var flowLevel: FlowLevel {
        get { FlowLevel(rawValue: flowLevelRaw) ?? .none }
        set {
            flowLevelRaw = newValue.rawValue
            touch()
        }
    }
    
    var isMenstruating: Bool {
        flowLevel != .none
    }
    
    
    //--------------------------------------------------
    // MARK: - Safe Setters
    //--------------------------------------------------
    
    func setEnergy(_ value: Int) {
        energyLevel = min(max(value, 1), 5)
        touch()
    }
    
    func setLibido(_ value: Int) {
        libidoLevel = min(max(value, 1), 5)
        touch()
    }
    
    
    //--------------------------------------------------
    // MARK: - Update Timestamp
    //--------------------------------------------------
    
    func touch() {
        updatedAt = Date()
    }
}
