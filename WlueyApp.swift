// Copyright (c) 2026 Satriya Dwi Mahardhika

import SwiftUI
import SwiftData

@main
struct WlueyApp: App {
    
    @State private var cycleViewModel = CycleViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(cycleViewModel)
        }
        .modelContainer(for: DailyLog.self)
    }
}
