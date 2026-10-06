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
    
    // 🟢 Flag คุมการแสดง Spinner (บังคับให้หมุนแสดงผลอย่างน้อย 1 วินาที)
    @State private var isShowingSpinner = true

    // ⏱ กำหนดเวลาแสดง Spinner ขั้นต่ำ (1.0 วินาที)
    private let minLoadingDuration: TimeInterval = 1.0

    var body: some View {
        NavigationStack {
            Group {
                // 🟢 1. ตราบใดที่ยังโหลดไม่เสร็จ หรือยังอยู่ในช่วง 1 วินาทีแรก -> ต้องแสดง Spinner เสมอ!
                if isShowingSpinner || (gameManager.isLoading && !hasInitialLoaded) {
                    MaterialSpinner(isLoading: .constant(true))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                } 
                // 🟢 2. พอพ้น 1 วินาทีและดึงข้อมูลเสร็จแล้ว ค่อยมาเช็ครายการเกม
                else if gameManager.targetApps.isEmpty {
                    // โหลดเสร็จแล้วแต่ไม่มีเกม -> แสดง EmptyState
                    EmptyStateView(type: .noGames)
                } else {
                    // มีรายการเกม -> แสดง List
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
        // 🟢 ตรวจจับเมื่อสลับแอปกลับเข้ามา (.active) แล้วดึงข้อมูลใหม่
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
        
        // บังคับแสดง Spinner เสมอเมื่อเริ่มกระบวนการโหลด
        isShowingSpinner = true

        // 🟢 1. ยิง API ดึงข้อมูลรายการเกม
        await gameManager.fetchTargetGames(showHUD: false, force: force)

        // 🟢 2. คำนวณเวลาที่ใช้ไปในการดึงข้อมูลจริง
        let elapsedTime = Date().timeIntervalSince(startTime)

        // 🟢 3. หากใช้เวลาน้อยกว่า minLoadingDuration (1 วินาที) ให้รอให้ครบ 1 วินาที
        if elapsedTime < minLoadingDuration {
            let remainingTime = UInt64((minLoadingDuration - elapsedTime) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: remainingTime)
        }

        // 🟢 4. ปิด Spinner พร้อม Animation จางออกอย่างนุ่มนวล
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
