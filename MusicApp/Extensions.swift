//
//  Extensions.swift
//  MusicApp
//
//  Created by Carson O'Sullivan on 4/6/23.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func setTabItem(_ title: String, _ icon: String) -> some View {
        self
            .tabItem {
                Image(systemName: icon)
                Text(title)
            }
    }
    
    @ViewBuilder
    func setTabBarBackground(_ style: AnyShapeStyle) -> some View {
        self
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(style, for: .tabBar)
    }
    @ViewBuilder
    func hideTabBar(_ status: Bool) -> some View {
        self
            .toolbar(status ? .hidden : .visible, for: .tabBar)
    }
}

extension View {
    var deviceCornerRadius: CGFloat {
        let key = "_displayCornerRadius"
        if let screen = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen {
            if let cornerRadius = screen.value(forKey: key) as? CGFloat {
                return cornerRadius
            }
            
            return 0
        }
        
        return 0
    }
}

extension DragGesture.Value {
    /// Returns Velocity of Drag Gesture (Which is not available in SwiftUI)
    internal var velocity: CGSize {
        let valueMirror = Mirror(reflecting: self)
        for valueChild in valueMirror.children {
            if valueChild.label == "velocity" {
                let velocityMirror = Mirror(reflecting: valueChild.value)
                for velocityChild in velocityMirror.children {
                    if velocityChild.label == "valuePerSecond" {
                        if let velocity = velocityChild.value as? CGSize {
                            return velocity
                        }
                    }
                }
            }
        }
        fatalError("Unable to retrieve velocity from \(Self.self)")
    }
    
}

#if os(iOS)
// MARK: - VisualEffectBlur

struct VisualEffectBlur<Content: View>: View {
    var blurStyle: UIBlurEffect.Style
    var vibrancyStyle: UIVibrancyEffectStyle?
    var content: Content
    
    init(blurStyle: UIBlurEffect.Style = .systemMaterial, vibrancyStyle: UIVibrancyEffectStyle? = nil, @ViewBuilder content: () -> Content) {
        self.blurStyle = blurStyle
        self.vibrancyStyle = vibrancyStyle
        self.content = content()
    }
    
    var body: some View {
        Representable(blurStyle: blurStyle, vibrancyStyle: vibrancyStyle, content: ZStack { content })
            .accessibility(hidden: Content.self == EmptyView.self)
    }
}

// MARK: - Representable

extension VisualEffectBlur {
    struct Representable<Content: View>: UIViewRepresentable {
        var blurStyle: UIBlurEffect.Style
        var vibrancyStyle: UIVibrancyEffectStyle?
        var content: Content
        
        func makeUIView(context: Context) -> UIVisualEffectView {
            context.coordinator.blurView
        }
        
        func updateUIView(_ view: UIVisualEffectView, context: Context) {
            context.coordinator.update(content: content, blurStyle: blurStyle, vibrancyStyle: vibrancyStyle)
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(content: content)
        }
    }
}

// MARK: - Coordinator

extension VisualEffectBlur.Representable {
    class Coordinator {
        let blurView = UIVisualEffectView()
        let vibrancyView = UIVisualEffectView()
        let hostingController: UIHostingController<Content>
        
        init(content: Content) {
            hostingController = UIHostingController(rootView: content)
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostingController.view.backgroundColor = nil
            blurView.contentView.addSubview(vibrancyView)
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            vibrancyView.contentView.addSubview(hostingController.view)
            vibrancyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
        
        func update(content: Content, blurStyle: UIBlurEffect.Style, vibrancyStyle: UIVibrancyEffectStyle?) {
            hostingController.rootView = content
            let blurEffect = UIBlurEffect(style: blurStyle)
            blurView.effect = blurEffect
            if let vibrancyStyle = vibrancyStyle {
                vibrancyView.effect = UIVibrancyEffect(blurEffect: blurEffect, style: vibrancyStyle)
            } else {
                vibrancyView.effect = nil
            }
            hostingController.view.setNeedsDisplay()
        }
    }
}

// MARK: - Content-less Initializer

extension VisualEffectBlur where Content == EmptyView {
    init(blurStyle: UIBlurEffect.Style = .systemMaterial) {
        self.init( blurStyle: blurStyle, vibrancyStyle: nil) {
            EmptyView()
        }
    }
}

// MARK: - Previews

struct VisualEffectBlur_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.red, .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VisualEffectBlur(blurStyle: .systemUltraThinMaterial, vibrancyStyle: .fill) {
                Text("Hello World!")
                    .frame(width: 200, height: 100)
            }
        }
        .previewLayout(.sizeThatFits)
    }
}


#endif

func readSongFile(fileName: String) -> [Song] {
    if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
        do {
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let decoder = JSONDecoder()
            let albums = try decoder.decode([Song].self, from: jsonData)
            return albums
        } catch {
            print("Error reading JSON file: \(error)")
        }
    }
    return [Song(songName: "", albumPhoto: "", artistName: "", id: 0, length: "")]
}
func readAlbumFile(fileName: String) -> [Album] {
    if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
        do {
            let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let decoder = JSONDecoder()
            let albums = try decoder.decode([Album].self, from: jsonData)
            return albums
        } catch {
            print("Error reading JSON file: \(error)")
        }
    }
    return [Album(id: 0, artistName: "", albumName: "", albumPhoto: "", songs: [Song(songName: "", albumPhoto: "", artistName: "", id: 0, length: "")])]
}
struct SnapCarouselHelper: UIViewRepresentable {
    /// Retreive what ever properties you needed from the ScrollView with the help of @Binding
    var pageWidth: CGFloat
    var pageCount: Int
    @Binding var index: Int
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UIView {
        return UIView()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let scrollView = uiView.superview?.superview?.superview as? UIScrollView {
                scrollView.decelerationRate = .fast
                scrollView.delegate = context.coordinator
                context.coordinator.pageCount = pageCount
                context.coordinator.pageWidth = pageWidth
            }
        }
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: SnapCarouselHelper
        var pageCount: Int = 0
        var pageWidth: CGFloat = 0
        init(parent: SnapCarouselHelper) {
            self.parent = parent
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            // print(scrollView.contentOffset.x)
        }
        
        func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            /// Adding Velocity too, for making perfect scroll animation
            let targetEnd = scrollView.contentOffset.x + (velocity.x * 60)
            let targetIndex = (targetEnd / pageWidth).rounded()
            
            /// Updating Current Index
            let index = min(max(Int(targetIndex), 0), pageCount - 1)
            parent.index = index
            
            targetContentOffset.pointee.x = targetIndex * pageWidth
        }
    }
}

struct GlossyBackground: View {
    var body: some View {
        ZStack {
            Image("ckay")
                .resizable()
                .opacity(0.5)
                .scaledToFill()
            VisualEffectBlur(blurStyle: .systemMaterial)
        }
        .ignoresSafeArea()
//        ZStack {
//            Image("takeCare")
//                .resizable()
//                .opacity(0.75)
//                .scaledToFit()
//            VisualEffectBlur(blurStyle: .systemMaterial)
//                .ignoresSafeArea()
//        }
    }
}

extension View{
    
    // Creating a Property for View to access easily...
    func fullSwipePop<Content: View>(show: Binding<Bool>, content: @escaping () -> Content)-> some View{
        
        return FullSwipePopHelper(show: show, mainContent: self, content: content())
    }
}

private struct FullSwipePopHelper<MainContent: View,Content: View>: View{
    
    // Where main Content will be our main view...
    // since we are moving our main left when overlay view shows....
    var mainContent: MainContent
    var content: Content
    @Binding var show: Bool
    init(show: Binding<Bool>, mainContent: MainContent,content: Content){
        self._show = show
        self.content = content
        self.mainContent = mainContent
    }
    
    // Gesture Properties...
    @GestureState var gestureOffset: CGFloat = 0
    @State var offset: CGFloat = 0
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View{
        
        // Geometry Reader for Getting Screen width for gesture calc...
        GeometryReader{proxy in
            
            mainContent
            // Moving main Content Slightly....
                .offset(x: show && offset >= 0 ? getOffset(size: proxy.size.width) : 0)
                .overlay(
                    
                    ZStack{
                        
                        if show{
                            
                            content
                            // adding Bg same as Color scheme...
                                .background(
                                    
                                    (colorScheme == .dark ? Color.black : Color.white)
                                    // shadow...
                                        .shadow(radius: 1.3)
                                        .ignoresSafeArea()
                                )
                                .offset(x: offset > 0 ? offset : 0)
                            // Adding Gesture...
                                .gesture(DragGesture().updating($gestureOffset, body: { value, out, _ in
                                    
                                    out = value.translation.width
                                }).onEnded({ value in
                                    
                                    // Close if pass...
                                    withAnimation(.linear.speed(2)){
                                                                                offset = 0
                                        
                                        let translation = value.translation.width
                                        
                                        let maxtranslation = proxy.size.width / 5
                                        
                                        if translation > maxtranslation{
                                            show = false
                                        }
                                    }
                                    
                                }))
                                .transition(.move(edge: .trailing))
                        }
                    }
                )
            // Updating Offset...
            // This is why bcx it will update only for valid touch....
                .onChange(of: gestureOffset) { newValue in
                    offset = gestureOffset
                }
        }
    }
    
    func getOffset(size: CGFloat)->CGFloat{
        
        let progress = offset / size
        
        // Were slighlty moving the view 80 towards left side...
        // and getting back to 0 based on user drag.....
        let start: CGFloat = -80
        let progressWidth = (progress * 90) <= 90 ? (progress * 90) : 90
        
        let mainOffset = (start + progressWidth) < 0 ? (start + progressWidth) : 0
        
        return mainOffset
    }
}
