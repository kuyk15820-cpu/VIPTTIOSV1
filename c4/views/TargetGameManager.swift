import Foundation
import UIKit
import SwiftUI
import TrustKit

// MARK: - TargetGameManager
class TargetGameManager: ObservableObject {
    
    static let shared = TargetGameManager()
    
    typealias FetchGamesHandler = (_ games: [TargetGameApp]) -> Void
    
    private var fetchHandler: FetchGamesHandler?
    
    // Key สำหรับดึง Token จาก UserDefaults
    private let tokenKey = "user_session_token"
    
    // MARK: - Target Games State
    @Published var targetApps: [TargetGameApp] = []
    @Published var isLoading: Bool = false
    
    // MARK: - Private Configuration
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: config, delegate: TargetGameDelegate.shared, delegateQueue: OperationQueue.main)
    }()
    
    private init() {
        // 🟢 ดักรับสัญญาณ Real-time จาก Pusher ( event: game_updated )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGameUpdateNotification),
            name: NSNotification.Name(SecretKeys.notificationRefreshTargetGames),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleGameUpdateNotification() {
        Task { @MainActor in
            self.fetchTargetGames(showHUD: false, force: true)
        }
    }
    
    // MARK: - Lazy Loading Helper
    /// สั่งโหลดข้อมูลเฉพาะเมื่อยังไม่มีข้อมูลใน Cache และไม่ได้กำลังโหลดอยู่
    func loadIfNeeded() {
        guard targetApps.isEmpty && !isLoading else { return }
        fetchTargetGames(showHUD: false)
    }
    
    // MARK: - Fetch Dynamic Games from Server
    func fetchTargetGames(showHUD: Bool = false, force: Bool = false, handler: FetchGamesHandler? = nil) {
        if let customHandler = handler {
            self.fetchHandler = customHandler
        }
        
        // 🟢 กรณีมีข้อมูลอยู่แล้ว และไม่ได้สั่งบังคับโหลดใหม่ (force: true) ให้คืนค่าจาก Cache ทันที (Lazy Loading Optimizing)
        if !targetApps.isEmpty && !force {
            self.fetchHandler?(self.targetApps)
            return
        }
        
        // 🟢 พ่วงแอบตรวจเช็คเวอร์ชันระบบไปด้วยทุกครั้ง
        AppUpdateCheckerManager.shared.checkVersion()
        
        guard let url = URL(string: SecretKeys.targetGamesURL) else {
            self.fetchHandler?(self.targetApps)
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            if showHUD {
                HUDHelper.show(message: "")
            }
        }
        
        let startTime = Date()
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 15.0
        request.setValue(SecretKeys.userAgentValue, forHTTPHeaderField: SecretKeys.userAgentHeader)
        
        // 🔒 ยืนยันตัวตน: แนบ Bearer Token ไปใน Authorization Header ทุกครั้ง
        if let token = UserDefaults.standard.string(forKey: tokenKey), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 🟢 ใช้ urlSession ที่ผูก Delegate SSL Pinning ผ่าน TrustKit
        urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            var fetchedApps: [TargetGameApp] = self.targetApps
            
            if let error = error {
                print("⚠ [Fetch Games Error / SSL Blocked]: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse {
                // 🔒 กรณี Token หมดอายุ / บัญชีถูกระงับสิทธิ์ (HTTP 401)
                if httpResponse.statusCode == 401 {
                    print("🔴 [Unauthorized Access]: Token invalid or user banned.")
                    // ⚡ สั่งยิงเช็ค Auth ทันทีเพื่อสลับหน้าไป BannedView / AccountDeletedView
                    Task { @MainActor in
                        await AuthManager.shared.checkAuthStatus()
                    }
                } else if (200...299).contains(httpResponse.statusCode), let data = data {
                    if let decodedGames = try? JSONDecoder().decode([TargetGameApp].self, from: data) {
                        // กรองเอาเฉพาะเกมที่ active != false
                        fetchedApps = decodedGames.filter { $0.active ?? true }
                    }
                }
            }
            
            // 🟢 การันตีเวลาโหลดอย่างน้อย 1.0 วินาทีเพื่อความสม่ำเสมอของการแสดงผล UI (Spinner/HUD)
            let elapsedTime = Date().timeIntervalSince(startTime)
            let minDuration: TimeInterval = 1.0
            let remainingTime = max(0, minDuration - elapsedTime)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                // 🟢 ใส่ Animation ลื่นๆ เมื่อรายการเกมมีการอัปเดต/เปลี่ยนแปลง
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.targetApps = fetchedApps
                }
                self.isLoading = false
                if showHUD {
                    HUDHelper.hide()
                }
                self.fetchHandler?(fetchedApps)
            }
        }.resume()
    }
    
    // MARK: - Safe Async Wrapper
    /// Async/Await Wrapper สำหรับใช้งานร่วมกับ `.task` หรือ `.refreshable` ใน SwiftUI
    func fetchTargetGames(showHUD: Bool = false, force: Bool = false) async {
        await withCheckedContinuation { continuation in
            var isResumed = false
            let lock = NSLock()
            
            fetchTargetGames(showHUD: showHUD, force: force) { _ in
                lock.lock()
                defer { lock.unlock() }
                
                if !isResumed {
                    isResumed = true
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - SSL Pinning Delegate for TargetGameManager
class TargetGameDelegate: NSObject, URLSessionDataDelegate {
    static let shared = TargetGameDelegate()
    
    // 🟢 ส่ง Authentication Challenge ไปให้ TrustKit ตรวจสอบ Certificate สไตล์เดียวกับ AppUpdate
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let validator = TrustKit.sharedInstance().pinningValidator
        let handled = validator.handle(challenge, completionHandler: completionHandler)
        if handled {
            return
        }
        completionHandler(.performDefaultHandling, nil)
    }
}
