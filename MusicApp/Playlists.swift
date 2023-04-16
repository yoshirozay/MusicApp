//
//  Playlists.swift
//  MusicApp
//
//  Created by Carson O'Sullivan on 4/12/23.
//

import SwiftUI

struct Playlist: Identifiable, Hashable, Decodable {
    let id: Int
    let playlistName: String
    let playlistPhoto: String
    let songs: [Song]
    let monthlyListeners: Int
    var offset : CGFloat = 0
}

struct Playlists: View {
    @ObservedObject var music: MusicObservable
    @State var showingPlaylist = false
    @Namespace private var animation2
    @ObservedObject var animations: AnimationObservable
    var body: some View {
        ZStack {
            VStack (alignment: .leading, spacing: 0) {
                Text("Trending Now")
                    .font(.title.weight(.semibold))
                    .padding(.leading, 16)
                PlaylistCarousel(music: music, showingPlaylist: $showingPlaylist, animation2: animation2)
                    .padding(.trailing, 64)
                    .padding(.top, 16)
            }
            .fullSwipePop2(show: $showingPlaylist, animating: _animations) {
                ZStack {
                    if showingPlaylist {
                        OpenedPlaylist2(music: music, animation2: animation2, showingPlaylist: $showingPlaylist, animations: animations)
                            .transition(.asymmetric(insertion: .identity, removal: .offset(y: -5)))
//
                            .ignoresSafeArea()
                    }
                }
            }
            .onChange(of: showingPlaylist) { change in
                if change == false {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        animations.resetAnimations()
                    }
                }
            }

//            ShowingPlaylist
        }
        .background(
            GlossyBackground()
        )
    }
    @ViewBuilder var ShowingPlaylist: some View {
        if showingPlaylist {
            OpenedPlaylist(music: music, animation2: animation2, showingPlaylist: $showingPlaylist)
                .transition(.asymmetric(insertion: .identity, removal: .offset(y: -5)))
                .clipped()
                .ignoresSafeArea()
        }
    }
}

struct PlaylistCarousel: View {
    @State var index = 0
    @State var scrolled = 0
    @ObservedObject var music: MusicObservable
    @Binding var showingPlaylist: Bool
    var animation2: Namespace.ID
    var body: some View {
        GeometryReader {
            let size = $0.size
            ZStack{
                ForEach(music.playlists.reversed()){ item in
                    HStack{
                        ZStack(alignment: Alignment(horizontal: .leading, vertical: .bottom)){
                            if !showingPlaylist || item.id - scrolled > 0 {
                                playlistArtwork(item: item)
                            }
                        }
                        
                        .frame(width: size.width - 120)
                        .offset(x: item.id - scrolled <= 3 ? CGFloat(item.id - scrolled) * 90 : 60)
                        Spacer()
                    }
                    .frame(width: size.width)
                    .contentShape(Rectangle())
                    
                    .offset(x: item.offset)
                    .highPriorityGesture(DragGesture().onChanged({ (value) in
                        withAnimation{
                            disableDragForLastPlaylist(playlist: item, value: value, size: size)
                        }
                    })
                        .onEnded({ (value) in
                            withAnimation{
                                navigatePlaylists(playlist: item, value: value, size: size)
                            }
                            
                        }))
                    .onTapGesture {
                        withAnimation(.linear(duration: 0.2)) {
                            music.selectedPlaylist = item
                            showingPlaylist = true
                        }
                    }
                }
            }
            .frame(height: 200, alignment: .leading)
        }
    }
    func playlistArtwork(item: Playlist) -> some View {
        Group {
            Image(item.playlistPhoto)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .matchedGeometryEffect(id: item.id, in: animation2)
                .frame(width:
                        175
                       - CGFloat(item.id - scrolled) * 25
                       , height: 175 - CGFloat(item.id - scrolled) * 25)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    ZStack {
                        if item.id - scrolled <= 0  {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.clear)
                                .frame(width: 175, height: 175)
                                .matchedGeometryEffect(id: "background", in: animation2)
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(.white, lineWidth: 3.5)
                                .frame(width: 175, height: 175)
                                .allowsHitTesting(false)
                                .opacity(showingPlaylist ? 0 : 1)
//                                .opacity(showingPlaylist ? 0 : 1)
                        }
                    }
                }
            
            Text(item.playlistName)
                .foregroundColor(.black)
                .font(.callout.weight(.semibold))
                .offset(x: 2, y: 24)
                .opacity(item.id - scrolled <= 0 ? 1 : 0)
        }
    }
    func disableDragForLastPlaylist(playlist: Playlist, value: DragGesture.Value, size: CGSize) {
        if value.translation.width < 0 && playlist.id != music.playlists.last!.id{
            music.playlists[playlist.id].offset = value.translation.width
        }
        else{
            if playlist.id > 0{
                music.playlists[playlist.id - 1].offset = -((size.width - 60) + 60) + value.translation.width
            }
        }
        
    }
    func navigatePlaylists(playlist: Playlist, value: DragGesture.Value, size: CGSize) {
        if value.translation.width < 0{
            if -value.translation.width > 10 && playlist.id != music.playlists.last!.id{
                music.playlists[playlist.id].offset = -((size.width - 60) + 60)
                scrolled += 1
            }
            else{
                music.playlists[playlist.id].offset = 0
            }
        }
        else{
            if playlist.id > 0{
                if value.translation.width > 10{
                    music.playlists[playlist.id - 1].offset = 0
                    scrolled -= 1
                }
                else{
                    music.playlists[playlist.id - 1].offset = -((size.width - 60) + 60)
                }
            }
        }
    }
}
struct OpenedPlaylist: View {
    @ObservedObject var music: MusicObservable
    @State var headerOffsets: (CGFloat,CGFloat) = (0,0)
    var animation2: Namespace.ID
    @GestureState private var offsetX: CGSize = .zero
    @GestureState var dragProgression: CGFloat = 0
    @Binding var showingPlaylist: Bool
    @State var animateBackgroundImage = false
    @State var animation = true
    @State var showingDetails = true
    var body: some View {
        GeometryReader {
            let size = $0.size
            VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0){
                        HeaderView(offsetX: offsetX)
                        if showingDetails {
                            SongList
                        }
                    }
                    .opacity(animation ? 0 : 1)

                }
                .background(
                    ZStack {
                        Image("ckay")
                            .resizable()
                            .opacity(0.5)
                            .scaledToFill()
                            .opacity(animateBackgroundImage ? 1 : 0)
                        VisualEffectBlur(blurStyle: .systemMaterial)
                            .ignoresSafeArea()
                    }
                )
                .coordinateSpace(name: "SCROLL")
                .ignoresSafeArea(.container, edges: .vertical)
                .onAppear {
                    withAnimation(.easeIn(duration: 0.4)) {
                        animateBackgroundImage = true
                    }
                }
            }
            .matchedGeometryEffect(id: "background", in: animation2)
            .frame(width: size.width - shrinkWidth(frame: size.width), height: showingDetails ? size.height - shrinkHeight(frame: size.height) : 250)
            .clipped()
            .gesture(
                DragGesture()
                    .updating($offsetX) { value, state, transaction in
                        withAnimation {
                            if value.translation.width < 0 {
                                state = value.translation
                            }
                        }
                    }
                    .updating($dragProgression) { value, state, transaction in
                        state = value.translation.width
                    }
            )
            .onChange(of: offsetX) { offset in
                if (-offset.width - (dragProgression * 0.3)) >= 270 {
                    animateBackgroundImage = false
                    withAnimation(.linear(duration: 0.15)) {
                        animation = true
                        showingPlaylist = false
                    }
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4)) {
                    animation = false
                }
            }
        }
    }
    func shrinkWidth(frame: Double) -> Double  {

        if -offsetX.width/1.5 < frame {
            return -offsetX.width/1.5
        } else {
            return 0.0
        }
    }
    func shrinkHeight(frame: Double) -> Double  {
        if -offsetX.width*3.1 < frame {
            return -offsetX.width*3.1
        } else {
            return 0.0
        }
    }
    @ViewBuilder
    func HeaderView(offsetX: CGSize) -> some View {
        GeometryReader{proxy in
            let minY = proxy.frame(in: .named("SCROLL")).minY
            let size = proxy.size
            let height = (size.height + minY)
            
            Image(music.selectedPlaylist.playlistPhoto)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .matchedGeometryEffect(id: music.selectedPlaylist.id, in: animation2)
                .frame(width: size.width, height: height > 0 ? height : 0, alignment: .top)
                .overlay(content: {
                    ZStack(alignment: .topLeading) {
                        ZStack(alignment: .bottom) {
                            LinearGradient(colors: [
                                .clear,
                                .black.opacity(0.3)
                            ], startPoint: .top, endPoint: .bottom)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 10) {
                                    Text(music.selectedPlaylist.playlistName)
                                        .font(.title.bold())
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.blue)
                                        .background{
                                            Circle()
                                                .fill(.white)
                                                .padding(3)
                                        }
                                }
                                HStack {
                                    
                                    Text("\(music.selectedPlaylist.monthlyListeners)")
                                        .font(.callout.weight(.semibold))
                                    
                                    Text("Monthly Listeners")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.white)
                                    
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom,25)
                            .frame(maxWidth: .infinity,alignment: .leading)
                            .opacity(offsetX.width >= 0 ? showingDetails ? 1 : 0 : 0)
                            .animation(.easeOut(duration: 0.3), value: offsetX.width)
                        }

                        ZStack {
                            Circle()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.black.opacity(0.2))
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.title3.weight(.semibold))
                        }
                        .frame(width: 30, height: 30)
                        .contentShape(Circle())
                        .onTapGesture {
                            animateBackgroundImage = false
                            showingDetails = false
                            withAnimation {
                                showingPlaylist = false
                            }
                        }
                        .padding()
                        .padding(.top)
                    }
                })
                .cornerRadius(showingPlaylist ? 1 : 10)
                .offset(y: -minY)
        }
        .frame(height: 250)
    }
    @ViewBuilder
    var SongList: some View{
        VStack(spacing: 20){
            ForEach(music.selectedPlaylist.songs, id: \.self){ item in
                IndividualSong(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            music.selectSong(song: item)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                music.showMediaPlayer()
                            }
                        }
                    }
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .padding(.top, 8)
        .padding(.bottom, music.selectedSong.songName == "" ? 78 : 148)
    }
    func IndividualSong(item: Song) -> some View {
        HStack(spacing: 8){
            
            Text("#\(item.id+1)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(width: 30, alignment: .leading)
                .animation(nil, value: music.selectedPlaylist)
            HStack(spacing: 12) {
                Image(item.albumPhoto)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 55, height: 55)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.songName)
                        .fontWeight(.semibold)
                    
                    Text(item.artistName)
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            Spacer()
            Text(item.length)
                .foregroundColor(.gray)
                .font(.caption)
                .frame(width: 30, alignment: .leading)
            
        }
    }
}
struct OpenedPlaylist2: View {
    @ObservedObject var music: MusicObservable
    @State var headerOffsets: (CGFloat,CGFloat) = (0,0)
    var animation2: Namespace.ID
    @GestureState private var offsetX: CGSize = .zero
    @GestureState var dragProgression: CGFloat = 0
    @Binding var showingPlaylist: Bool
    @State var animateBackgroundImage = false
    @State var animation = true
    @State var showingDetails = true
    @ObservedObject var animations: AnimationObservable
    var body: some View {

            VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0){
                        HeaderView(offsetX: offsetX)
//                        if animations.animation2 != true {
                            SongList
                                .opacity(animations.animation2 ? 0 : 1)
//                        }
                    }
                    .opacity(animation ? 0 : 1)
                    
                }
                .background(
//                        ZStack {
//                            if animations.animation3 != true {
//                            Image("ckay")
//                                .resizable()
//                                .opacity(0.5)
//                                .scaledToFill()
//
//                            VisualEffectBlur(blurStyle: .systemMaterial)
////                                .ignoresSafeArea()
//                        }
//                    }
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThickMaterial)
                        .overlay (
                            ZStack {
                                Image("ckay")
                                    .resizable()
                                    .opacity(0.5)
                                    .scaledToFill()
                                VisualEffectBlur(blurStyle: .systemMaterial)
                                                                .ignoresSafeArea()
                            }
                        )
                        .clipped()
               
//                            .opacity(animations.animation3 ? 0 : 1)
//                            .frame(width: size.width, height: size.height)
//                            .clipped()
//\\
                )
                .coordinateSpace(name: "SCROLL")
                .ignoresSafeArea(.container, edges: .vertical)
                .onAppear {
                    withAnimation(.easeIn(duration: 0.4)) {
//                        animateBackgroundImage = true
//                        animations.toggleAnimation(animation: 3, value: true)
                    }
                }
            }
            .matchedGeometryEffect(id: "background", in: animation2)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4)) {
                    animation = false
                }
            }
//            .cornerRadius(animations.animation2 ? 100 : 0)
//            .frame(width: size.width, height: animations.animation2 != true ? size.height : 250)
//            .frame(width: size.width, height: size.height)
    }
    @ViewBuilder
    func HeaderView(offsetX: CGSize) -> some View {
        GeometryReader{proxy in
            let minY = proxy.frame(in: .named("SCROLL")).minY
            let size = proxy.size
            let height = (size.height + minY)
            
            Image(music.selectedPlaylist.playlistPhoto)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .matchedGeometryEffect(id: music.selectedPlaylist.id, in: animation2)
                .frame(width: size.width, height: height > 0 ? height : 0, alignment: .top)
                .overlay(content: {
                    ZStack(alignment: .topLeading) {
                        ZStack(alignment: .bottom) {
                            LinearGradient(colors: [
                                .clear,
                                .black.opacity(0.3)
                            ], startPoint: .top, endPoint: .bottom)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 10) {
                                    Text(music.selectedPlaylist.playlistName)
                                        .font(.title.bold())
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.blue)
                                        .background{
                                            Circle()
                                                .fill(.white)
                                                .padding(3)
                                        }
                                }
                                HStack {
                                    
                                    Text("\(music.selectedPlaylist.monthlyListeners)")
                                        .font(.callout.weight(.semibold))
                                    
                                    Text("Monthly Listeners")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.white)
                                    
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom,25)
                            .frame(maxWidth: .infinity,alignment: .leading)
                            .opacity(offsetX.width >= 0 ? showingDetails ? 1 : 0 : 0)
                            .animation(.easeOut(duration: 0.3), value: offsetX.width)
                        }

                        ZStack {
                            Circle()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.black.opacity(0.2))
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.title3.weight(.semibold))
                        }
                        .frame(width: 30, height: 30)
                        .contentShape(Circle())
                        .onTapGesture {
//                            animateBackgroundImage = false
//                            showingDetails = false
                            animations.toggleAnimation(animation: 1, value: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                animations.toggleAnimation(animation: 3, value: true)
                            }
                            withAnimation(.linear(duration: 0.2)) {
                                showingPlaylist = false
                                animations.toggleAnimation(animation: 2, value: true)
//                                animations.toggleAnimation(animation: 1, value: true)
//                                animations.animation1 = true
                            }
                        }
                        .padding()
                        .padding(.top)
                    }
                    .opacity(animations.animation1 ? 0 : 1)
                })
                .cornerRadius(showingPlaylist ? 1 : 10)
                .offset(y: -minY)
        }
        .frame(height: 250)
    }
    @ViewBuilder
    var SongList: some View{
        VStack(spacing: 20){
            ForEach(music.selectedPlaylist.songs, id: \.self){ item in
                IndividualSong(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            music.selectSong(song: item)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                music.showMediaPlayer()
                            }
                        }
                    }
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .padding(.top, 8)
        .padding(.bottom, music.selectedSong.songName == "" ? 78 : 148)
    }
    func IndividualSong(item: Song) -> some View {
        HStack(spacing: 8){
            
            Text("#\(item.id+1)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(width: 30, alignment: .leading)
                .animation(nil, value: music.selectedPlaylist)
            HStack(spacing: 12) {
                Image(item.albumPhoto)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 55, height: 55)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.songName)
                        .fontWeight(.semibold)
                    
                    Text(item.artistName)
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            Spacer()
            Text(item.length)
                .foregroundColor(.gray)
                .font(.caption)
                .frame(width: 30, alignment: .leading)
            
        }
    }
}

struct Playlists_Previews: PreviewProvider {
    static var previews: some View {
        //        Playlists(music: MusicObservable())
        Main(selectedTab: "playlists")
        //        OpenedPlaylist(music: MusicObservable())
    }
}
