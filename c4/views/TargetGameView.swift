import SwiftUI
import Network

struct TargetGameView: View {
    // 🟢 ดึงข้อมูลผ่าน TargetGameManager.shared
    @StateObject private var gameManager = TargetGameManager.shared

    // 🟢 ตรวจจับ สถานะการทำงานของแอป (Active, Inactive, Background)
    @Environment(\.scenePhase) private var scenePhase

    // 🟢 ตัว Monitor สำหรับตรวจจับการเชื่อมต่ออินเทอร์เน็ต
    @State private var networkMonitor: NWPathMonitor?
    
    // 🟢 Flag เช็คว่าเคยโหลดครั้งแรกสุดเสร็จสิ้นไปแล้วหรือยัง
    @State private var hasInitialLoaded = false
    
    // 🟢 Flag คุมการแสดง Spinner โหลดข้อมูล
    @State private var isShowingSpinner = true

    // ⏱️️ กำหนดเวลาแสดง Spinner ขั้นต่ำ (1.0 วินาที)
    private let minLoadingDuration: TimeInterval = 1.0

    var body: some View {
        NavigationStack {
            Group {
                if gameManager.targetApps.isEmpty {
                    if isShowingSpinner || (gameManager.isLoading && !hasInitialLoaded) {
                        // 🟢 โหลดครั้งแรกสุด -> แสดง MaterialSpinner ล้วนๆ ตรงกลางหน้าจออย่างน้อย 1 วินาที
                        MaterialSpinner(isLoading: .constant(true))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.opacity)
                    } else {
                        // 🟢 ถ้าเคยโหลดไปแล้ว หรือโหลดเสร็จแล้วแต่ไม่มีเกม -> แสดง EmptyState
                        EmptyStateView(type: .noGames)
                    }
                } else {
                    // 🟢 แสดง List เสมอ (ไม่ซ่อน List แม้กำลังเช็คข้อมูลเบื้องหลัง)
                    List {
                        Section {
                            ForEach(gameManager.targetApps) { app in
                                NavigationLink(value: app) {
                                    HStack(spacing: 12) {
                                        if let icon = app.icon {
                                            Image(uiImage: icon)
                                                .resizable()
                                                .frame(width: 32, height: 32)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } else {
                                            Image(systemName: SecretKeys.iconAppWindowCheckmark)
                                                .font(.title2)
                                                .foregroundStyle(Color.primary)
                                        }

                                        Text(app.name)
                                            .font(.headline)
                                    }
                                    .contentShape(Rectangle())
                                }
                            }
                        } header: {
                            Text(SecretKeys.textSelectGameSection)
                        }
                    }
                    .listStyle(.plain)
                    // 🟢 ลากลงเพื่อบังคับรีเฟรชข้อมูลใหม่ (Pull to Refresh)
                    .refreshable {
                        await loadTargetGamesWithMinDuration(force: true)
                    }
                }
            }
            .navigationTitle(SecretKeys.textHomeNavigationTitle)
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: TargetGameApp.self) { app in
                QuickApplyView(selectedApp: app)
            }
        }
        .onAppear {
            Task {
                await loadTargetGamesWithMinDuration(force: false)
            }
            startNetworkMonitoring()
        }
        .onDisappear {
            stopNetworkMonitoring()
        }
        // 🟢 ตรวจจับเมื่อสลับแอปกลับเข้ามา (.active) แล้วดึงข้อมูลใหม่แบบเงียบๆ
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                Task {
                    await loadTargetGamesWithMinDuration(force: false)
                }
            }
        }
    }

    // MARK: - Core Load Logic with Minimum Duration (ขั้นต่ำ 1 วินาที)

    @MainActor
    private func loadTargetGamesWithMinDuration(force: Bool) async {
        let startTime = Date()
        
        // หากยังไม่เคยโหลด ให้เปิด Spinner ไว้
        if !hasInitialLoaded {
            isShowingSpinner = true
        }

        // 🟢 1. เรียกยิง API ดึงข้อมูลรายการเกม
        await gameManager.fetchTargetGames(showHUD: false, force: force)

        // 🟢 2. คำนวณเวลาที่ใช้ไปทั้งหมดในการดึงข้อมูล
        let elapsedTime = Date().timeIntervalSince(startTime)

        // 🟢 3. ถ้าใช้เวลาน้อยกว่า 1 วินาที ให้รอจนกว่าจะครบ 1 วินาที
        if elapsedTime < minLoadingDuration {
            let remainingTime = UInt64((minLoadingDuration - elapsedTime) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: remainingTime)
        }

        // 🟢 4. ปิดการแสดง Spinner พร้อม Animation นุ่มนวล
        withAnimation(.easeInOut(duration: 0.25)) {
            self.hasInitialLoaded = true
            self.isShowingSpinner = false
        }
    }

    // MARK: - Network Monitoring Logic

    private func startNetworkMonitoring() {
        stopNetworkMonitoring()
        
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                Task { @MainActor in
                    if self.gameManager.targetApps.isEmpty && !self.gameManager.isLoading {
                        await self.loadTargetGamesWithMinDuration(force: false)
                    }
                }
            }
        }
        
        let queue = DispatchQueue(label: "TargetGameViewNetworkMonitor")
        monitor.start(queue: queue)
        self.networkMonitor = monitor
    }

    private func stopNetworkMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
    }
}

#Preview {
    TargetGameView()
        .environmentObject(AppState())
}
