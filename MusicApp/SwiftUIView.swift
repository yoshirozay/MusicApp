//
//  SwiftUIView.swift
//  MusicApp
//
//  Created by Carson O'Sullivan on 4/15/23.
//

import SwiftUI

class Observable: ObservableObject {
    @Published var someVariable = true
    
    func toggleVariable() {
        withAnimation {
            someVariable.toggle()
        }
    }
}
class Observable2: ObservableObject {
    @Published var anotherVariable = false
    init(variable: Bool) {
        anotherVariable = variable
    }
}

struct View1: View {
    @StateObject var observable = Observable()
    var body: some View {
            View2(observable: observable, observable2: Observable2(variable: observable.someVariable))
    }
}

struct View2: View {
    @ObservedObject var observable: Observable
    @StateObject var observable2: Observable2
    var body: some View {
        VStack {
            Text(observable2.anotherVariable ? "Hello" : "Goodbye")
        }
    }
}


struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        View1(observable: Observable())
    }
}
