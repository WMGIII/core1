//
//  core1App.swift
//  core1
//
//  Created by WMIII on 2021/4/3.
//

import SwiftUI
import CoreData

@main
struct core1App: App {
    
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
