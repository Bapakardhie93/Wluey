// Copyright (c) 2026 Satriya Dwi Mahardhika

import SwiftUI
import SwiftData

struct ProfileView: View {
    
    @Query private var logs: [DailyLog]
    @Environment(\.modelContext) private var context
    
    @AppStorage("username") private var username: String = "Pengguna"
    
    @State private var showDeleteAlert = false
    @State private var isEditingName = false
    @State private var tempName = ""
    
    var body: some View {
        
        NavigationStack {
            
            List {
                
                // MARK: - Profile Header
                
                Section {
                    HStack(spacing: 16) {
                        
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.pink.opacity(0.7), .purple.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            
                            if isEditingName {
                                TextField("Nama", text: $tempName)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit {
                                        saveName()
                                    }
                            } else {
                                Text(username)
                                    .font(.title3.bold())
                                    .onTapGesture {
                                        tempName = username
                                        isEditingName = true
                                    }
                            }
                            
                            Text("Aplikasi Siklus Haid")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                
                // MARK: - Ringkasan
                
                Section("Ringkasan") {
                    
                    HStack {
                        Text("Total Catatan")
                        Spacer()
                        Text("\(logs.count)")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Data Tersimpan")
                        Spacer()
                        Text(logs.isEmpty ? "Belum ada" : "Aktif")
                            .foregroundColor(.gray)
                    }
                }
                
                
                // MARK: - Aksi
                
                Section("Aksi") {
                    
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Hapus Semua Data", systemImage: "trash")
                    }
                }
                
                
                // MARK: - App Info
                
                Section("Tentang Aplikasi") {
                    
                    HStack {
                        Text("Versi")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Dibuat dengan")
                        Spacer()
                        Text("SwiftUI")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Dibuat oleh")
                        Spacer()
                        Text("Bapakardhie")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Hapus Semua Data?", isPresented: $showDeleteAlert) {
                
                Button("Hapus", role: .destructive) {
                    deleteAllData()
                }
                
                Button("Batal", role: .cancel) { }
                
            } message: {
                Text("Semua data siklus akan dihapus permanen.")
            }
        }
    }
    
    private func saveName() {
        username = tempName.isEmpty ? "Pengguna" : tempName
        isEditingName = false
    }
    
    private func deleteAllData() {
        for log in logs {
            context.delete(log)
        }
        try? context.save()
    }
}
