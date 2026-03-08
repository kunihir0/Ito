//
//  ItoApp.swift
//  Ito
//
//  Created by caocao on 3/3/26.
//

import SwiftUI

@main
struct ItoApp: App {
    @StateObject private var appearanceManager = AppearanceManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(ReadProgressManager.shared)
                .preferredColorScheme(appearanceManager.selectedTheme.colorScheme)
        }
    }
}
