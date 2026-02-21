// Copyright (c) 2026 Satriya Dwi Mahardhika

import SwiftUI
import SwiftData

struct MonitorView: View {
    
    @Environment(\.modelContext) private var context
    @Query(sort: \DailyLog.date, order: .reverse) private var logs: [DailyLog]
    
    // Hapus nilai default Date() di sini agar bisa di-inject via init
    @State private var selectedDate: Date
    @State private var flowLevel: FlowLevel = .none
    @State private var painLevel: Int = 0
    @State private var selectedSymptoms: Set<String> = []
    @State private var selectedMoods: Set<String> = []
    @State private var energy: Int = 3
    @State private var libido: Int = 2
    @State private var notes: String = ""
    
    // Pemetaan data ke ikon
    private let symptomsData: [(name: String, icon: String)] = [
        ("Kram", "bolt.fill"), ("Sakit Kepala", "waveform.path.ecg"),
        ("Mual", "cross.pills.fill"), ("Jerawat", "sparkles"),
        ("Kembung", "wind"), ("Payudara Nyeri", "heart.circle.fill")
    ]
    
    private let moodsData: [(name: String, icon: String)] = [
        ("Senang", "face.smiling"), ("Sedih", "cloud.rain.fill"),
        ("Marah", "flame.fill"), ("Cemas", "aqi.medium"),
        ("Tenang", "leaf.fill"), ("Sensitif", "bolt.heart.fill")
    ]
    
    // MARK: - Initializer Baru
    // Ini memungkinkan HistoryView mengirimkan tanggal spesifik. Jika tidak ada, default ke hari ini.
    init(selectedDate: Date = Date()) {
        _selectedDate = State(initialValue: selectedDate)
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    headerSection
                    
                    VStack(spacing: 16) {
                        flowSection
                        painSection
                        symptomSection
                        moodSection
                        energyLibidoSection
                        notesSection
                    }
                    
                    saveButton
                        .padding(.top, 10)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .onAppear {
            loadExistingLog()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SetSelectedDate"))) { notification in
            if let date = notification.object as? Date {
                selectedDate = date
                loadExistingLog()
            }
        }
    }
}

// MARK: - UI Sections

extension MonitorView {
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Catatan Harian")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                Text("Bagaimana keadaan Anda?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            DatePicker(
                "",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .tint(.pink)
            .onChange(of: selectedDate) {
                withAnimation {
                    loadExistingLog()
                }
            }
        }
        .padding(.vertical, 10)
    }
    
    private var flowSection: some View {
        CardView {
            SectionHeader(title: "Aliran Menstruasi", icon: "drop.fill", color: .red)
            
            HStack(spacing: 8) {
                ForEach([FlowLevel.none, .spotting, .light, .medium, .heavy], id: \.self) { level in
                    Button {
                        withAnimation(.spring()) { flowLevel = level }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: flowLevel == level ? "drop.fill" : "drop")
                                .font(.title3)
                                .foregroundColor(flowLevel == level ? .red : .gray)
                            
                            Text(label(for: level))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(flowLevel == level ? .red : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(flowLevel == level ? Color.red.opacity(0.15) : Color(UIColor.tertiarySystemFill))
                        )
                    }
                }
            }
        }
    }
    
    private var painSection: some View {
        CardView {
            HStack {
                SectionHeader(title: "Tingkat Nyeri", icon: "waveform.path", color: .orange)
                Spacer()
                Text("\(painLevel)/10")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundColor(.orange)
            }
            
            HStack(spacing: 16) {
                Image(systemName: "face.smiling")
                    .foregroundColor(.green)
                
                Slider(
                    value: Binding(
                        get: { Double(painLevel) },
                        set: { painLevel = Int($0) }
                    ),
                    in: 0...10,
                    step: 1
                )
                .tint(.orange)
                
                Image(systemName: "face.dashed")
                    .foregroundColor(.red)
            }
        }
    }
    
    private var symptomSection: some View {
        CardView {
            SectionHeader(title: "Gejala Fisik", icon: "bandage.fill", color: .purple)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(symptomsData, id: \.name) { symptom in
                    SelectablePill(
                        title: symptom.name,
                        icon: symptom.icon,
                        isSelected: selectedSymptoms.contains(symptom.name)
                    ) {
                        toggleSelection(for: symptom.name, in: $selectedSymptoms)
                    }
                }
            }
        }
    }
    
    private var moodSection: some View {
        CardView {
            SectionHeader(title: "Perasaan & Emosi", icon: "heart.text.square.fill", color: .pink)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(moodsData, id: \.name) { mood in
                    SelectablePill(
                        title: mood.name,
                        icon: mood.icon,
                        isSelected: selectedMoods.contains(mood.name)
                    ) {
                        toggleSelection(for: mood.name, in: $selectedMoods)
                    }
                }
            }
        }
    }
    
    private var energyLibidoSection: some View {
        CardView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Level Energi", icon: "bolt.fill", color: .yellow)
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= energy ? "bolt.fill" : "bolt")
                                .font(.title2)
                                .foregroundColor(index <= energy ? .yellow : .gray.opacity(0.3))
                                .onTapGesture {
                                    withAnimation { energy = index }
                                }
                        }
                    }
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Gairah (Libido)", icon: "flame.fill", color: .red)
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= libido ? "flame.fill" : "flame")
                                .font(.title2)
                                .foregroundColor(index <= libido ? .red : .gray.opacity(0.3))
                                .onTapGesture {
                                    withAnimation { libido = index }
                                }
                        }
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        CardView {
            SectionHeader(title: "Catatan Tambahan", icon: "square.and.pencil", color: .blue)
            
            TextEditor(text: $notes)
                .font(.system(.body, design: .rounded))
                .frame(minHeight: 100)
                .padding(12)
                .background(Color(UIColor.tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var saveButton: some View {
        Button {
            saveLog()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Simpan Jurnal")
            }
            .font(.system(.headline, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.primary)
            .foregroundColor(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Reusable UI Components

struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}

struct SelectablePill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.pink.opacity(0.15) : Color(UIColor.tertiarySystemFill))
            .foregroundColor(isSelected ? .pink : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.pink.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Logic

extension MonitorView {
    
    private func loadExistingLog() {
        let normalized = Calendar.current.startOfDay(for: selectedDate)
        
        if let existing = logs.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: normalized)
        }) {
            flowLevel = existing.flowLevel
            painLevel = existing.painLevel
            selectedSymptoms = Set(existing.symptomTags)
            selectedMoods = Set(existing.moodTags)
            energy = existing.energyLevel
            libido = existing.libidoLevel
            notes = existing.notes ?? ""
        } else {
            flowLevel = .none
            painLevel = 0
            selectedSymptoms = []
            selectedMoods = []
            energy = 3
            libido = 2
            notes = ""
        }
    }
    
    
    private func saveLog() {
        
        let normalized = Calendar.current.startOfDay(for: selectedDate)
        
        if isFirstDayOfNewPeriod(normalized) {
            autoFillPeriod(from: normalized, summary: nil) // atau inject dari ViewModel
        } else {
            saveSingleDay(normalized)
        }
        
        try? context.save()
    }
    
    private func autoFillPeriod(
        from startDate: Date,
        summary: CycleSummary?
    ) {
        
        let predictedLength = max(summary?.averagePeriodLength ?? 5, 3)
        
        for i in 0..<predictedLength {
            
            if let newDate = Calendar.current.date(byAdding: .day, value: i, to: startDate) {
                
                let normalized = Calendar.current.startOfDay(for: newDate)
                
                if logs.contains(where: {
                    Calendar.current.isDate($0.date, inSameDayAs: normalized)
                }) {
                    continue
                }
                
                let newLog = DailyLog(date: normalized)
                newLog.flowLevel = .medium
                
                context.insert(newLog)
            }
        }
    }
    
    private func isFirstDayOfNewPeriod(_ date: Date) -> Bool {
        
        guard flowLevel != .none else { return false }
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        
        let yesterdayLog = logs.first {
            Calendar.current.isDate($0.date, inSameDayAs: yesterday)
        }
        
        if let yesterday = yesterdayLog {
            return yesterday.flowLevel == .none
        } else {
            return true
        }
    }
    
    
    private func saveSingleDay(_ date: Date) {
        if let existing = logs.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }) {
            existing.flowLevel = flowLevel
            existing.painLevel = painLevel
            existing.symptomTags = Array(selectedSymptoms)
            existing.moodTags = Array(selectedMoods)
            existing.energyLevel = energy
            existing.libidoLevel = libido
            existing.notes = notes
            existing.touch()
        } else {
            let newLog = DailyLog(date: date)
            newLog.flowLevel = flowLevel
            newLog.painLevel = painLevel
            newLog.symptomTags = Array(selectedSymptoms)
            newLog.moodTags = Array(selectedMoods)
            newLog.energyLevel = energy
            newLog.libidoLevel = libido
            newLog.notes = notes
            
            context.insert(newLog)
        }
    }
    
    
    ////////////////////////////////////////////////////////
    // MARK: - AUTO FILL 7 HARI
    ////////////////////////////////////////////////////////
    
    private func autoFillSevenDays(from startDate: Date) {
        
        for i in 0..<7 {
            if let newDate = Calendar.current.date(byAdding: .day, value: i, to: startDate) {
                
                let normalized = Calendar.current.startOfDay(for: newDate)
                
                if let existing = logs.first(where: {
                    Calendar.current.isDate($0.date, inSameDayAs: normalized)
                }) {
                    
                    existing.flowLevel = FlowLevel.medium
                    existing.touch()
                    
                } else {
                    
                    let newLog = DailyLog(date: normalized)
                    newLog.flowLevel = FlowLevel.medium
                    context.insert(newLog)
                }
            }
        }
    }
    
    
    ////////////////////////////////////////////////////////
    // MARK: - Toggle Selection
    ////////////////////////////////////////////////////////
    
    private func toggleSelection(for item: String, in set: Binding<Set<String>>) {
        if set.wrappedValue.contains(item) {
            set.wrappedValue.remove(item)
        } else {
            set.wrappedValue.insert(item)
        }
    }
    
    
    private func label(for level: FlowLevel) -> String {
        switch level {
        case .none: return "Tidak"
        case .spotting: return "Flek"
        case .light: return "Sedikit"
        case .medium: return "Sedang"
        case .heavy: return "Banyak"
        }
    }
}
