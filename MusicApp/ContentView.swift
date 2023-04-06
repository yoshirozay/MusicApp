//
//  ContentView.swift
//  MusicApp
//
//  Created by Carson O'Sullivan on 4/5/23.
//

import SwiftUI

@main
struct MusicApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        Main()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

