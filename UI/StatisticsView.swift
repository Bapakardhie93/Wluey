// Copyright (c) 2026 Satriya Dwi Mahardhika

import SwiftUI
import SwiftData

struct StatisticsView: View {
    
    @Query(sort: \DailyLog.date, order: .forward)
    private var logs: [DailyLog]
    
    @State private var isAnimating = false
    
    private var summary: CycleSummary {
        // Asumsi CycleEngine sudah kamu definisikan di tempat lain
        CycleEngine.analyze(logs: logs)
    }
    
    // Setup Grid (ditambahkan alignment .top agar kartu sejajar jika panjang teks berbeda)
    private let columns = [
        GridItem(.flexible(), alignment: .top),
        GridItem(.flexible(), alignment: .top)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        headerSection
                        
                        if logs.count >= 2 {
                            
                            // Highlight Section
                            VStack(spacing: 16) {
                                highlightCard(
                                    title: "Durasi Siklus",
                                    description: "Jarak antara hari pertama haid ke haid berikutnya.",
                                    value: "\(summary.averageCycleLength)",
                                    unit: "hari rata-rata",
                                    statusText: summary.isIrregular ? "Tidak Stabil" : "Tipikal",
                                    statusColor: summary.isIrregular ? .orange : .green,
                                    icon: "calendar.badge.clock"
                                )
                                
                                highlightCard(
                                    title: "Durasi Haid",
                                    description: "Lama hari terjadinya perdarahan.",
                                    value: "\(summary.averagePeriodLength)",
                                    unit: "hari rata-rata",
                                    statusText: summary.longPeriodWarning ? "Terlalu Lama" : "Normal",
                                    statusColor: summary.longPeriodWarning ? .orange : .green,
                                    icon: "drop.fill"
                                )
                            }
                            
                            implantationSection
                            
                            // Grid Section
                            Text("Analisis Lanjutan")
                                .font(.title3.bold())
                                .padding(.top, 8)
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                gridCard(
                                    title: "Akurasi Prediksi",
                                    description: "Tingkat keyakinan algoritma dari data log kamu.",
                                    value: "\(summary.confidenceScore)",
                                    progress: Double(summary.confidenceScore) / 100,
                                    color: summary.confidenceScore > 75 ? .mint : .orange,
                                    icon: "chart.xyaxis.line"
                                )
                                
                                gridCard(
                                    title: "Energi Hormonal",
                                    description: "Estimasi energimu dari fluktuasi hormon saat ini.",
                                    value: "\(summary.hormonalEnergyScore)",
                                    progress: Double(summary.hormonalEnergyScore) / 100,
                                    color: summary.hormonalEnergyScore > 70 ? .blue : .orange,
                                    icon: "bolt.fill"
                                )
                                
                                gridCard(
                                    title: "Indeks Kesuburan",
                                    description: "Peluang kehamilan di fase siklus hari ini.",
                                    value: "\(summary.fertilityRiskIndex)",
                                    progress: Double(summary.fertilityRiskIndex) / 100,
                                    color: summary.fertilityRiskIndex > 70 ? .teal : .gray,
                                    icon: "heart.fill"
                                )
                                
                                gridCard(
                                    title: "Anomali Siklus",
                                    description: "Penyimpangan siklus bulan ini dari rata-ratamu.",
                                    value: "\(summary.anomalyScore)",
                                    progress: Double(summary.anomalyScore) / 100,
                                    color: summary.anomalyScore > 60 ? .red : .green,
                                    icon: "waveform.path.ecg"
                                )
                                
                                gridCard(
                                    title: "Risiko PMS",
                                    description: "Potensi kram atau perubahan mood dalam waktu dekat.",
                                    value: "\(Int(summary.pmsProbability * 100))",
                                    progress: summary.pmsProbability,
                                    color: summary.pmsProbability > 0.6 ? .pink : .gray,
                                    icon: "moon.fill"
                                )
                            }
                            
                            riskWarnings
                            
                        } else {
                            emptyStateCard
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Analisis")
        }
        .onAppear {
            // Jeda singkat agar GeometryReader selesai kalkulasi ukuran layar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - Components

extension StatisticsView {
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Insight Siklusmu")
                .font(.largeTitle.bold())
            
            Text("Pahami pola tubuhmu berdasarkan data klinis.")
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 8)
    }
    
    // Update parameter ditambahkan "description"
    private func highlightCard(title: String, description: String, value: String, unit: String, statusText: String, statusColor: Color, icon: String) -> some View {
        HStack(alignment: .top, spacing: 20) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(statusColor)
                .frame(width: 50, height: 50)
                .background(statusColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    
                    // Status Badge dipindah ke atas agar lebih rapi
                    Text(statusText)
                        .font(.caption2.bold())
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text(unit)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    // Update parameter ditambahkan "description"
    private func gridCard(title: String, description: String, value: String, progress: Double, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.body.bold())
                Spacer()
                Text("\(value)%")
                    .font(.system(.headline, design: .rounded))
                    .bold()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 8) // Memastikan progress bar selalu ada di paling bawah kartu
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .frame(height: 6)
                        .foregroundColor(Color.gray.opacity(0.15))
                    
                    Capsule()
                        .frame(width: isAnimating ? geometry.size.width * CGFloat(progress) : 0, height: 6)
                        .foregroundColor(color)
                        // Tambahan animasi di sini agar pergerakan lebarnya terlihat
                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: isAnimating)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // Memastikan kartu sama tinggi
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    private var implantationSection: some View {
        let window = summary.implantationWindow
        
        return HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Jendela Implantasi")
                    .font(.headline)
                
                Text("Masa di mana sel telur menempel ke rahim. Peluang tertinggi pada hari ke-\(window.lowerBound) hingga \(window.upperBound).")
                    .font(.caption) // Diubah jadi caption agar konsisten
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundColor(.purple)
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var riskWarnings: some View {
        VStack(spacing: 12) {
            if summary.shortLutealWarning || summary.lutealDefectRisk {
                warningCard("Fase luteal terpantau pendek. Konsultasikan jika sedang promil.")
            }
            if summary.pcosRisk {
                warningCard("Variasi siklus sangat tinggi. Evaluasi medis disarankan.")
            }
            if summary.possibleEarlyPregnancy {
                warningCard("Siklus melewati prediksi normal. Pertimbangkan tes kehamilan.")
            }
        }
        .padding(.top, 8)
    }
    
    private func warningCard(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var emptyStateCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubbles.and.sparkles")
                .font(.system(size: 64))
                .foregroundColor(.blue.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("Butuh Lebih Banyak Data")
                    .font(.title3.bold())
                
                Text("Catat minimal 2 siklus untuk membuka akses ke analisis pintar dan prediksi akurat tentang tubuhmu.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.top, 20)
    }
}
