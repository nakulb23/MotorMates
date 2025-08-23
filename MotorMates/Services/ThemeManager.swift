//
//  ThemeManager.swift
//  MotorMates
//
//  Created by Nakul Bhatnagar on 8/18/25.
//

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    @Published var isAutoThemeEnabled: Bool = true
    @Published var manualDarkMode: Bool = false
    
    private var timer: Timer?
    
    init() {
        startThemeMonitoring()
    }
    
    private func startThemeMonitoring() {
        // Check theme immediately
        updateThemeBasedOnTime()
        
        // Update theme every minute
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updateThemeBasedOnTime()
        }
    }
    
    func updateThemeBasedOnTime() {
        guard isAutoThemeEnabled else {
            isDarkMode = manualDarkMode
            return
        }
        
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Dark mode from 7 PM (19:00) to 7 AM (07:00)
        // Light mode from 7 AM to 7 PM
        isDarkMode = hour >= 19 || hour < 7
        
        // Theme updated automatically based on time
    }
    
    func toggleAutoTheme() {
        isAutoThemeEnabled.toggle()
        if isAutoThemeEnabled {
            updateThemeBasedOnTime()
        } else {
            isDarkMode = manualDarkMode
        }
    }
    
    func setManualTheme(isDark: Bool) {
        manualDarkMode = isDark
        if !isAutoThemeEnabled {
            isDarkMode = isDark
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Theme Colors
extension Color {
    static let mmBackground = Color("MMBackground")
    static let mmCardBackground = Color("MMCardBackground")
    static let mmPrimaryText = Color("MMPrimaryText")
    static let mmSecondaryText = Color("MMSecondaryText")
    static let mmAccent = Color.orange
    
    // Dynamic colors that change with theme
    static func dynamicBackground(isDark: Bool) -> Color {
        isDark ? Color(UIColor.systemBackground) : Color.white
    }
    
    static func dynamicCard(isDark: Bool) -> Color {
        isDark ? Color(UIColor.secondarySystemBackground) : Color.white
    }
    
    static func dynamicText(isDark: Bool) -> Color {
        isDark ? Color.white : Color.black
    }
    
    static func dynamicSecondaryText(isDark: Bool) -> Color {
        isDark ? Color.gray : Color.secondary
    }
    
    static func dynamicShadow(isDark: Bool) -> Color {
        isDark ? Color.clear : Color.black.opacity(0.1)
    }
}