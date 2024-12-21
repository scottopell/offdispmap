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
        #if os(iOS)
            ContentViewiOS(viewModel: MainViewModel())
                .environment(\.managedObjectContext, persistenceController.context)
        #else
            ContentView(viewModel: MainViewModel())
                .environment(\.managedObjectContext, persistenceController.context)
        #endif
           
       }
    }
}
