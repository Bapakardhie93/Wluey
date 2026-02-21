// Copyright (c) 2026 Satriya Dwi Mahardhika

import SwiftUI
import SwiftData

struct DashboardView: View {
    
    @Query(sort: \DailyLog.date, order: .forward)
    private var logs: [DailyLog]
    
    @State private var isAnimating = false
    @State private var showCards = false // Untuk animasi bertahap
    
    private var summary: CycleSummary {
        CycleEngine.analyze(logs: logs)
    }
    
    private var periods: [Period] {
        PeriodExtractor.extractPeriods(from: logs)
    }
    
    private var currentCycleStart: Date? {
        periods.sorted { $0.startDate < $1.startDate }.last?.startDate
    }
    
    private var cycleLength: Int {
        summary.averageCycleLength
    }
    
    // Konfigurasi Grid 2 Kolom
    private let gridColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        header
                            .opacity(showCards ? 1 : 0)
                            .offset(y: showCards ? 0 : 10)
                        
                        // Circular View
                        if let start = currentCycleStart {
                            CircularCycleView(
                                startDate: start,
                                cycleLength: cycleLength,
                                periodLength: summary.averagePeriodLength,
                                fertileWindow: summary.fertileWindow,
                                ovulationDay: summary.predictedOvulationDay
                            )
                            .padding(.vertical, 8)
                            .scaleEffect(showCards ? 1 : 0.9)
                            .opacity(showCards ? 1 : 0)
                        }
                        
                        // Metrik Grid
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            dashboardMetricCard(
                                title: "Akurasi\nPrediksi",
                                value: "\(summary.confidenceScore)%",
                                progress: Double(summary.confidenceScore) / 100,
                                color: .orange,
                                icon: "chart.xyaxis.line"
                            )
                            
                            dashboardMetricCard(
                                title: "Energi\nHormonal",
                                value: "\(summary.hormonalEnergyScore)%",
                                progress: Double(summary.hormonalEnergyScore) / 100,
                                color: .blue,
                                icon: "bolt.fill"
                            )
                            
                            dashboardMetricCard(
                                title: "Indeks\nKesuburan",
                                value: "\(summary.fertilityRiskIndex)%",
                                progress: Double(summary.fertilityRiskIndex) / 100,
                                color: .teal,
                                icon: "heart.fill"
                            )
                            
                            dashboardMetricCard(
                                title: "Probabilitas\nPMS",
                                value: "\(Int(summary.pmsProbability * 100))%",
                                progress: summary.pmsProbability,
                                color: .pink,
                                icon: "moon.fill"
                            )
                        }
                        .opacity(showCards ? 1 : 0)
                        .offset(y: showCards ? 0 : 20)
                        
                        implantationCard
                            .opacity(showCards ? 1 : 0)
                        
                        riskAlerts
                            .opacity(showCards ? 1 : 0)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Dashboard") // Opsional, hapus jika tidak perlu
            .navigationBarHidden(true)
        }
        .onAppear {
            // Animasi masuk yang lebih halus dan bertahap
            withAnimation(.easeOut(duration: 0.4)) {
                showCards = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    isAnimating = true
                }
            }
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: - Components
//////////////////////////////////////////////////////////

extension DashboardView {
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ringkasan Siklus")
                .font(.system(.largeTitle, design: .rounded).bold())
            
            Text("Pantau fase dan prediksi tubuhmu hari ini.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // Kartu Metrik Baru (Berbentuk Kotak / Compact untuk Grid)
    private func dashboardMetricCard(title: String, value: String, progress: Double, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Spacer()
                
                Text(value)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 40, alignment: .topLeading) // Menjaga tinggi teks tetap seragam
            
            // Progress Bar Mini
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .frame(height: 6)
                        .foregroundColor(Color.gray.opacity(0.15))
                    
                    Capsule()
                        .frame(width: isAnimating ? geometry.size.width * CGFloat(progress) : 0, height: 6)
                        .foregroundColor(color)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
    
    private var implantationCard: some View {
        let window = summary.implantationWindow
        
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Jendela Implantasi")
                    .font(.headline)
                
                Text("Hari ke-\(window.lowerBound) sampai \(window.upperBound)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        // Menggunakan overlay stroke tipis memberikan kesan elegan
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var riskAlerts: some View {
        VStack(spacing: 12) {
            if summary.lutealDefectRisk {
                alertCard(
                    text: "Fase luteal terdeteksi lebih pendek dari normal. Konsultasikan jika sedang promil.",
                    color: .orange
                )
            }
            
            if summary.pcosRisk {
                alertCard(
                    text: "Variasi siklus tinggi. Evaluasi medis disarankan.",
                    color: .red
                )
            }
            
            if summary.possibleEarlyPregnancy {
                alertCard(
                    text: "Siklus melebihi prediksi normal. Pertimbangkan tes kehamilan.",
                    color: .purple
                )
            }
        }
        .padding(.top, 8)
    }
    
    private func alertCard(text: String, color: Color) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(color)
                .font(.title2)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}
