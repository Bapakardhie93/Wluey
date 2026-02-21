// Copyright (c) 2026 Satriya Dwi Mahardhika

import SwiftUI

struct MainTabView: View {
    
    var body: some View {
        
        TabView {
            
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
            
            MonitorView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Monitor")
                }
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Statistik")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profile")
                }
        }
        .tint(.pink) // bisa ganti sesuai branding app
    }
}
