import SwiftUI
import Network

struct TargetGameView: View {
    // 🟢 ดึงข้อมูลผ่าน TargetGameManager.shared
    @StateObject private var gameManager = TargetGameManager.shared

    // 🟢 ตรวจจับ สถานะการทำงานของแอป (Active, Inactive, Background)
    @Environment(\.scenePhase) private var scenePhase

    // 🟢 ตัว Monitor สำหรับตรวจจับการเชื่อมต่ออินเทอร์เน็ต
    @State private var networkMonitor: NWPathMonitor?
    
    // 🟢 Flag เช็คว่าเคยโหลดครั้งแรกสุดไปแล้วหรือยัง (ป้องกันหน้ากระพริบเมื่อสั่ง Fetch เบื้องหลัง)
    @State private var hasInitialLoaded = false

    var body: some View {
        NavigationStack {
            Group {
                if gameManager.targetApps.isEmpty {
                    if gameManager.isLoading && !hasInitialLoaded {
                        // 🟢 โหลดครั้งแรกสุด -> แสดง MaterialSpinner ล้วนๆ ตรงกลางหน้าจอ
                        MaterialSpinner(isLoading: .constant(true))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .transition(.opacity)
                    } else {
                        // 🟢 ถ้าเคยโหลดไปแล้ว หรือโหลดเสร็จแล้วแต่ไม่มีเกม -> แสดง EmptyState สถิตไว้ ไม่กระพริบ
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
                        await gameManager.fetchTargetGames(showHUD: false, force: true)
                        self.hasInitialLoaded = true
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
            // 🟢 โหลดข้อมูลเบื้องหลังโดยไม่ขึ้น HUD
            gameManager.fetchTargetGames(showHUD: false) { _ in
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.hasInitialLoaded = true
                }
            }
            startNetworkMonitoring()
        }
        .onDisappear {
            stopNetworkMonitoring()
        }
        // 🟢 ตรวจจับเมื่อสลับแอปกลับเข้ามา (.active) แล้วดึงข้อมูลใหม่แบบเงียบๆ
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                gameManager.fetchTargetGames(showHUD: false) { _ in
                    self.hasInitialLoaded = true
                }
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
                    if self.gameManager.targetApps.isEmpty && !self.gameManager.isLoading {
                        self.gameManager.fetchTargetGames(showHUD: false) { _ in
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
