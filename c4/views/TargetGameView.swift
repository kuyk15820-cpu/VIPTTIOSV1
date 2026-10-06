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

    var body: some View {
        NavigationStack {
            Group {
                // 🟢 1. หน้าแรกสุด หรือตราบใดที่ยังโหลดครั้งแรกไม่เสร็จ -> แสดง Spinner
                if !hasInitialLoaded || (gameManager.isLoading && gameManager.targetApps.isEmpty) {
                    MaterialSpinner(isLoading: .constant(true))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                } 
                // 🟢 2. โหลดเสร็จแล้วแต่ไม่มีข้อมูลรายการเกม -> แสดง EmptyState
                else if gameManager.targetApps.isEmpty {
                    EmptyStateView(type: .noGames)
                } 
                // 🟢 3. มีรายการเกม -> แสดง List
                else {
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
                        await gameManager.fetchTargetGames(showHUD: false, force: true)
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
            if !hasInitialLoaded {
                Task {
                    await gameManager.fetchTargetGames(showHUD: false, force: true)
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.hasInitialLoaded = true
                    }
                }
            }
            startNetworkMonitoring()
        }
        .onDisappear {
            stopNetworkMonitoring()
        }
        // 🟢 ตรวจจับเมื่อสลับแอปกลับเข้ามา (.active) -> ดึงข้อมูลอัปเดตแบบเงียบๆ เบื้องหลัง
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active && hasInitialLoaded {
                gameManager.fetchTargetGames(showHUD: false, force: true)
            }
        }
    }

    // MARK: - Network Monitoring Logic

    private func startNetworkMonitoring() {
        stopNetworkMonitoring()
        
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                Task { @MainActor in
                    if self.hasInitialLoaded {
                        // ถ้าเคยโหลดสำเร็จแล้ว ให้อัปเดตข้อมูลเงียบๆ
                        self.gameManager.fetchTargetGames(showHUD: false, force: true)
                    } else if !self.gameManager.isLoading {
                        // ถ้ายังไม่เคยโหลด ให้ยิงโหลดและแสดง Spinner 1 วินาที
                        await self.gameManager.fetchTargetGames(showHUD: false, force: true)
                        withAnimation(.easeInOut(duration: 0.25)) {
                            self.hasInitialLoaded = true
                        }
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
