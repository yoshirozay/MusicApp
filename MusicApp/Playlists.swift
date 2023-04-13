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
            ShowingPlaylist
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
                                Image(item.playlistPhoto)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
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
                                            }
                                        }
                                    }
                                    .matchedGeometryEffect(id: item.id, in: animation2)
                                
                                Text(item.playlistName)
                                    .foregroundColor(.black)
                                    .font(.callout.weight(.semibold))
                                    .offset(x: 2, y: 24)
                                    .opacity(item.id - scrolled <= 0 ? 1 : 0)
                            }
                        }
                        .frame(width: size.width - 120)
                        .offset(x: item.id - scrolled <= 3 ? CGFloat(item.id - scrolled) * 90 : 60)
                        Spacer()
                    }
                    .frame(width: size.width)
                    .contentShape(Rectangle())
                    .offset(x: item.offset)
                    .gesture(DragGesture().onChanged({ (value) in
                        
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
                        withAnimation(.easeIn(duration: 0.2)) {
                            music.selectedPlaylist = item
                            showingPlaylist = true
                        }
                    }
                }
            }
            .frame(height: 200, alignment: .leading)
        }
        //        .matchedGeometryEffect(id: "albumArt", in: animation)
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
    @State var isAnimating = false
    @GestureState private var offsetX: CGSize = .zero
    @GestureState var dragProgression: CGFloat = 0
    @Binding var showingPlaylist: Bool
    @State var animateBackgroundImage = false
    @State var animation = true
    var body: some View {
        GeometryReader {
            let size = $0.size
            var dragProgress = 1.0 - (-offsetX.width / (300))
            VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0){
                        //                    if animation != true {
                        HeaderView(offsetX: offsetX)
                        SongList
                        //                    }
                    }
                    .opacity(animation ? 0 : 1)
//                    .opacity(animation ? 0 : offsetX.width < 0 ? dragProgress : 1)
//                    .opacity(offsetX.width < 0 ? 1 - offsetX.width : 1)
//                    .offset(x: (offsetX.width < 0 ? -offsetX.width/2 : 0), y: (offsetX.width < 0 ? -offsetX.width/2 : 0))
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
                    withAnimation(.linear(duration: 0.4)) {
                        isAnimating = true
                    }
                    withAnimation(.easeIn(duration: 0.4)) {
                        animateBackgroundImage = true
                    }
                }
            }
            .matchedGeometryEffect(id: "background", in: animation2)
            .frame(width: size.width + (offsetX.width < 0 && offsetX.width > -250 ? offsetX.width : 0), height: size.height + ((offsetX.width < 0 && offsetX.width*4 < size.height-1) ? offsetX.width*4 : 0))
            .cornerRadius(deviceCornerRadius/2)
            .clipped()
            .offset(x: offsetX.width < 0 ? offsetX.width/3 : 0)
//            .offset(x: (offsetX.width < 0 ? -offsetX.width/2 : 0), y: (offsetX.width < 0 ? -offsetX.width/2 : 0))
//                    , y: offsetX.width/2)
            .gesture(
                DragGesture()
                    .updating($offsetX) { value, state, transaction in
                        withAnimation {
                            state = value.translation
                        }
                    }
                    .updating($dragProgression) { value, state, transaction in
                        state = value.translation.width
                    }
            )
            .onChange(of: offsetX) { offset in
                if (-offset.width - (dragProgression * 0.3)) >= 200 {
                    animateBackgroundImage = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        animation = true
                        showingPlaylist = false
                     }
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.3)) {
                    animation = false
                }
            }
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
                .frame(width: size.width, height: height > 0 ? height : 0,alignment: .top)
                .matchedGeometryEffect(id: music.selectedPlaylist.id, in: animation2)
                .overlay(content: {
                    ZStack(alignment: .topLeading) {
                        //                        .background(Color.red)
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
                        //                        Button(action: {
                        
                        //                        }) {
                        ZStack {
                            Circle()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.black.opacity(0.2))
                            //                                    .overlay (
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.title3.weight(.semibold))
                            //                                    )
                        }
                        //                        }
                        .frame(width: 30, height: 30)
                        
                        .contentShape(Circle())
                        .onTapGesture {
                            animateBackgroundImage = false
                            withAnimation {
                                showingPlaylist = false
                            }
                        }
                        .padding()
                        .padding(.top)
                    }
                })
                .cornerRadius(1)
                .offset(y: -minY)
        }
        //        .opacity(isAnimating ? 1 : 0)
        .frame(height: 250 + (offsetX.width < 0 && offsetX.width > -250 ? offsetX.width*1.3  : 0))
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
