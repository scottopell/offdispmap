//
//  offdispmapApp.swift
//  offdispmap
//
//  Created by Scott Opell on 6/16/24.
//

import SwiftUI

@main
struct offdispmapApp: App {
    let persistenceController = CoreDataManager.shared

    var body: some Scene {  
        WindowGroup {
           ContentView()
               .environment(\.managedObjectContext, persistenceController.context)
       }
    }
}
