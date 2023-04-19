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
    @Namespace private var animation3
    @ObservedObject var animations: AnimationObservable
    @State var isFromLargeCarousel = false
    var body: some View {
        ZStack {
            GeometryReader {
                let size = $0.size
                VStack {
                    
                    VStack (alignment: .leading, spacing: 16) {
                        
                        HStack {
                            
                            Text("Recently Played")
                                .font(.title2.weight(.semibold))
                            Spacer()
                            Image(systemName: "magnifyingglass")
                                .font(.title3)
                            
                        }
                        PlaylistCarousel(music: music, showingPlaylist: $showingPlaylist, animation2: animation2, size: size)
                    }
                    .padding(.bottom, 32)
                    
                    VStack (alignment: .leading, spacing: 16) {
                        Text("Trending Now")
                            .font(.title2.weight(.semibold))
                        PlaylistCarousel2(music: music, showingPlaylist: $showingPlaylist, animation3: animation3, size: size, isFromLargeCarousel: $isFromLargeCarousel)
                            .offset(x: 8)
                    }
                }
                .padding(.horizontal)
            }
            .shrinkingView(show: $showingPlaylist, animating: _animations) {
                OpenPlaylist
            }
            .onChange(of: showingPlaylist) { change in
                if change == false {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        animations.resetAnimations()
                        isFromLargeCarousel = false
                    }
                }
            }
        }
        .background(
            GlossyBackground()
        )
    }
    @ViewBuilder var OpenPlaylist: some View {
        if showingPlaylist {
            OpenedPlaylist(music: music, animation2: animation2, animation3: animation3, showingPlaylist: $showingPlaylist, animations: animations, isFromLargeCarousel: isFromLargeCarousel)
                .transition(.asymmetric(insertion: .identity, removal: .offset(y: -5)))
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
    @State var size: CGSize
    var body: some View {
        ZStack {
            ForEach(music.playlists.reversed()){ item in
                HStack{
                    ZStack(alignment: Alignment(horizontal: .leading, vertical: .bottom)){
                        if !showingPlaylist || item.id - scrolled > 0 {
                            
                            playlistArtwork(item: item, size: size)
                            
                        }
                    }
                    
                    .frame(width: size.width - 120)
                    .offset(x: item.id - scrolled <= 3 ? CGFloat(item.id - scrolled) * 90 : 60)
                    .opacity(item.id - scrolled <= 3 ? 1 : 0)
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
        .frame(width: size.width, height: 175)
    }
    func playlistArtwork(item: Playlist, size: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            HStack {
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
                        ZStack(alignment: .bottom) {
//                            LinearGradient(colors: [.clear,.black.opacity(0.3)], startPoint: .top, endPoint: .bottom)
//                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            Color.clear
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
                                }
                            }
                            .shadow(color: .black.opacity(item.id - scrolled <= 0 ? 0.25 : 0), radius: 4, x: 0, y: 2)
                            
                            TextAnimation()
                                .mask(
                                    Text(item.playlistName.uppercased())
                                        .foregroundColor(.black)
                                        .font(.caption.weight(.semibold))
                                        .tracking(5)
                                )
                                .offset(y: 30)
                                .opacity(item.id - scrolled <= 0 ? 1 : 0)
                        }
                    }
                Spacer()
            }
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
struct PlaylistCarousel2: View {
    @State var index = 0
    @State var scrolled = 0
    @ObservedObject var music: MusicObservable
    @Binding var showingPlaylist: Bool
    var animation3: Namespace.ID
    @State var size: CGSize
    @Binding var isFromLargeCarousel: Bool
    var body: some View {
        ZStack {
            ForEach(music.playlists2.reversed()){ item in
                HStack{
                    ZStack(alignment: Alignment(horizontal: .leading, vertical: .bottom)){
                        if !showingPlaylist || item.id - scrolled > 0 {
                            playlistArtwork(item: item, size: size)
                        }
                    }
                    
                    .frame(width: size.width - 120)
                    .offset(x: item.id - scrolled <= 2 ? CGFloat(item.id - scrolled) * 70 : 60)
                    .opacity(item.id - scrolled <= 2 ? 1 : 0)
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
                    isFromLargeCarousel = true
                    withAnimation(.easeInOut(duration: 0.2)) {
                        music.selectedPlaylist = item
                        showingPlaylist = true
                    }
                }
            }
        }
        .padding(.leading, 6)
        .frame(width: size.width, height: size.width*1.05)
    }
    func playlistArtwork(item: Playlist, size: CGSize) -> some View {
        ZStack(alignment: .bottom) {
            Image(item.playlistPhoto)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .matchedGeometryEffect(id: item.id, in: animation3)
                .frame(width:
                        size.width*0.75
                       - CGFloat(item.id - scrolled) * 25
                       , height: size.width*1.05 - CGFloat(item.id - scrolled) * 25)
            //                .rotationEffect(.degrees(30))
            
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    LinearGradient(colors: [.clear,.black.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    ZStack {
                        //                        if item.id - scrolled <= 0  {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.clear)
                            .matchedGeometryEffect(id: "background", in: animation3)
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(.white, lineWidth: 3.5)
                            .allowsHitTesting(false)
                            .opacity(showingPlaylist ? 0 : 1)
                        //                        }
                    }
                    .frame(width:
                            size.width*0.75
                           - CGFloat(item.id - scrolled) * 25
                           , height: size.width*1.05 - CGFloat(item.id - scrolled) * 25)
                    
                }
                .shadow(color: .black.opacity(item.id - scrolled <= 0 ? 0.25 : 0), radius: 4, x: 0, y: 4)
            ZStack {
                if item.id - scrolled == 0 {
                    Rectangle()
                        .frame(height: 30)
                        .foregroundColor(.white)
                    Image("laser")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 30)
                        .mask(
                            Text(item.playlistName.uppercased())
                                .foregroundColor(.black)
                                .font(.body.weight(.semibold))
                                .tracking(5)
                        )
                }
            }
            .offset(y: -70)
            .opacity(item.id - scrolled <= 0 ? 1 : 0)
        }
    }
    func disableDragForLastPlaylist(playlist: Playlist, value: DragGesture.Value, size: CGSize) {
        if value.translation.width < 0 && playlist.id != music.playlists2.last!.id{
            music.playlists2[playlist.id].offset = value.translation.width
        }
        else{
            if playlist.id > 0{
                music.playlists2[playlist.id - 1].offset = -((size.width - 60) + 60) + value.translation.width
            }
        }
        
    }
    func navigatePlaylists(playlist: Playlist, value: DragGesture.Value, size: CGSize) {
        if value.translation.width < 0{
            if -value.translation.width > 10 && playlist.id != music.playlists2.last!.id{
                music.playlists2[playlist.id].offset = -((size.width - 60) + 60)
                scrolled += 1
            }
            else{
                music.playlists2[playlist.id].offset = 0
            }
        }
        else{
            if playlist.id > 0{
                if value.translation.width > 10{
                    music.playlists2[playlist.id - 1].offset = 0
                    scrolled -= 1
                }
                else{
                    music.playlists2[playlist.id - 1].offset = -((size.width - 60) + 60)
                }
            }
        }
    }
}

struct TextAnimation: View {
    @State var animation = false
    var body: some View {
        ZStack {
            Image("laser")
                .resizable()
                .scaledToFill()
            LinearGradient(colors: [Color.teal, Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing)
                .opacity(animation ? 1: 0)
        }
        .frame(height: 30)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
                withAnimation(.linear(duration: 2).delay(1).repeatForever()) {
                    animation.toggle()
                }
            }
        }
    }
}
struct OpenedPlaylist: View {
    @ObservedObject var music: MusicObservable
    @State var headerOffsets: (CGFloat,CGFloat) = (0,0)
    var animation2: Namespace.ID
    var animation3: Namespace.ID
    @Binding var showingPlaylist: Bool
    @State var animation = true
    @ObservedObject var animations: AnimationObservable
    @State var isFromLargeCarousel = false
    var body: some View {
        
        VStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0){
                    HeaderView
                        .opacity(animation ? isFromLargeCarousel != true ? 0 : 1 : 1)
                    SongList
                        .opacity(animations.animation2 ? 0 : 1)
                }
                
            }
            .background(
                Color.clear
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThickMaterial)
                            .overlay (
                                GlossyBackground()
                            )
                            .clipped()
                            .opacity(animations.animation4 ? 0 : 1)
                    }
            )
            .coordinateSpace(name: "SCROLL")
            .ignoresSafeArea(.container, edges: .vertical)
        }
        .matchedGeometryEffect(id: "background", in: isFromLargeCarousel ? animation3 : animation2)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4)) {
                animation = false
            }
        }
    }
    @ViewBuilder
    var HeaderView: some View {
        GeometryReader{proxy in
            let minY = proxy.frame(in: .named("SCROLL")).minY
            let size = proxy.size
            let height = (size.height + minY)
            
            Image(music.selectedPlaylist.playlistPhoto)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .matchedGeometryEffect(id: music.selectedPlaylist.id, in: isFromLargeCarousel ? animation3 : animation2)
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
                            animations.toggleAnimation(animation: 1, value: true)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                animations.toggleAnimation(animation: 3, value: true)
                            }
                            withAnimation(.linear(duration: 0.2)) {
                                showingPlaylist = false
                                animations.toggleAnimation(animation: 2, value: true)
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
        //        ColorAnimation()
        Main(selectedTab: "playlists")
        //        OpenedPlaylist(music: MusicObservable())
    }
}
