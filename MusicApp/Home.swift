//
//  Home.swift
//  MusicApp
//
//  Created by Carson O'Sullivan on 4/6/23.
//

import SwiftUI


struct Main: View {
    @StateObject var music = MusicObservable()
    @Namespace private var animation
    var body: some View {
        TabView {
            Songs(music: music)
                .setTabItem("Listen Now", "play.circle.fill")
                .setTabBarBackground(.init(.ultraThickMaterial))
                .hideTabBar(music.hideTabBar)
            SampleTab("Browse", "square.grid.2x2.fill")
            SampleTab("Radio", "dot.radiowaves.left.and.right")
            SampleTab("Music", "play.square.stack")
            SampleTab("Search", "magnifyingglass")
        }
        .tint(.red)
        .safeAreaInset(edge: .bottom) {
            MusicPlayerFooter()
        }
        .overlay {
            if music.showingMediaPlayer {
                FullScreenMediaPlayer(music: music, animation: animation)
                    .transition(.asymmetric(insertion: .identity, removal: .offset(y: -5)))
            }
        }
        .onChange(of: music.showingMediaPlayer) { newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + (newValue ? 0.06 : 0.03)) {
                music.toggleTabBar(newValue: newValue)
            }
        }
    }
    @ViewBuilder
    func MusicPlayerFooter() -> some View {
        ZStack {
            if music.showingMediaPlayer {
                Rectangle()
                    .fill(.clear)
            } else {
                Rectangle()
                    .fill(.ultraThickMaterial)
                    .overlay {
                        /// Music Info
                        MusicInfo(music: music, animation: animation)
                            .opacity(music.selectedSong.songName == "" ? 0 : 1)
                    }
                    .matchedGeometryEffect(id: "background", in: animation)
            }
        }
        .frame(height: music.selectedSong.songName == "" ? 0 : 70)
        .overlay(alignment: .bottom, content: {
            Rectangle()
                .fill(Color.white)
                .frame(height: 1)
        })
        .offset(y: -49)
    }
    @ViewBuilder
    func SampleTab(_ title: String, _ icon: String) -> some View {
        Text(title)
            .padding(.top, 25)
            .setTabItem(title, icon)
            .setTabBarBackground(.init(.ultraThickMaterial))
            .hideTabBar(music.hideTabBar)
    }
}

struct MusicInfo: View {
    @ObservedObject var music:  MusicObservable
    var animation: Namespace.ID
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                if !music.showingMediaPlayer {
                    GeometryReader {
                        let size = $0.size
                        
                        Image(music.selectedSong.albumPhoto)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: music.showingMediaPlayer ? 15 : 5, style: .continuous))
                    }
                    .matchedGeometryEffect(id: "albumArt", in: animation)
                }
            }
            .frame(width: 45, height: 45)
            
            Text(music.selectedSong.songName)
                .fontWeight(.semibold)
                .lineLimit(1)
                .padding(.horizontal, 15)
            
            Spacer(minLength: 0)
            
            Button {
                
            } label: {
                Image(systemName: "pause.fill")
                    .font(.title2)
            }
            
            Button {
                
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
            }
            .padding(.leading, 25)
        }
        .foregroundColor(.primary)
        .padding(.horizontal)
        .padding(.bottom, 5)
        .frame(height: 70)
        .contentShape(Rectangle())
        .onTapGesture {
            music.showMediaPlayer()
        }
    }
}

struct FullScreenMediaPlayer: View {
    @ObservedObject var music:  MusicObservable
    var animation: Namespace.ID
    @State private var animateContent: Bool = false
    @State private var offsetY: CGFloat = 0
    @State private var animateDrake: Bool = false
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = $0.safeAreaInsets
            let dragProgress = 1.0 - (offsetY / (size.height * 0.5))
            let cornerProgress = max(0, dragProgress)
            
            ZStack {
                BackgroundDesign(cornerProgress: cornerProgress)
                VStack(spacing: 15) {
                    AlbumArtwork(cornerProgress: cornerProgress, size: size)
                    PlayerView(size)
                        .offset(y: animateContent ? 0 : size.height)
                }
                .padding(.top, safeArea.top + (safeArea.bottom == 0 ? 10 : 0))
                .padding(.bottom, safeArea.bottom == 0 ? 10 : safeArea.bottom)
                .padding(.horizontal, 25)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .clipped()
            }
            .contentShape(Rectangle())
            .offset(y: offsetY)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        let translationY = value.translation.height
                        offsetY = (translationY > 0 ? translationY : 0)
                    }).onEnded({ value in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if (offsetY + (value.velocity.height * 0.3)) > size.height * 0.4 {
                                music.showMediaPlayer()
                                animateContent = false
                                animateDrake = false
                            } else {
                                offsetY = .zero
                            }
                        }
                    })
            )
            .ignoresSafeArea(.container, edges: .all)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.25)) {
                animateContent = true
            }
            withAnimation(.easeInOut(duration: 0.5)) {
                animateDrake = true
            }
        }
    }
    
    func BackgroundDesign(cornerProgress: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius * cornerProgress : 0, style: .continuous)
            .fill(.ultraThickMaterial)
            .overlay(content: {
                Image("takeCare")
                    .resizable()
                    .offset(y: 250)
                    .opacity(animateDrake ? 1 : 0)
                VisualEffectBlur(blurStyle: .systemMaterial)
                    .ignoresSafeArea()
                RoundedRectangle(cornerRadius: animateContent ? deviceCornerRadius * cornerProgress : 0, style: .continuous)
                    .fill(Color.clear)
                    .opacity(animateContent ? 1 : 0)
                
            })
            .overlay(alignment: .top) {
                MusicInfo(music: music, animation: animation)
                    .allowsHitTesting(false)
                    .opacity(animateContent ? 0 : 1)
            }
            .matchedGeometryEffect(id: "background", in: animation)
        
    }
    func AlbumArtwork(cornerProgress: CGFloat, size: CGSize) -> some View {
        Group {
            Capsule()
                .fill(.gray)
                .frame(width: 40, height: 5)
                .opacity(animateContent ? cornerProgress : 0)
                .offset(y: animateContent ? 0 : size.height)
                .clipped()
            
            GeometryReader {
                let size = $0.size
                
                Image(music.selectedSong.albumPhoto)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: animateContent ? 15 : 5, style: .continuous))
            }
            .matchedGeometryEffect(id: "albumArt", in: animation)
            .frame(height: size.width - 50)
            .padding(.vertical, size.height < 700 ? 10 : 30)
            
        }
    }
    @ViewBuilder
    func PlayerView(_ mainSize: CGSize) -> some View {
        GeometryReader {
            let size = $0.size
            let spacing = size.height * 0.04
            VStack(spacing: spacing) {
                VStack(spacing: spacing) {
                    SongName
                    SongLength(spacing: spacing)
                }
                .frame(height: size.height / 2.5, alignment: .top)
                PauseOrSkip(size: size)
                
                VStack(spacing: spacing) {
                    AudioSlider
                    AirpodControls(size: size)
                        .padding(.top, spacing)
                }
                .frame(height: size.height / 2.5, alignment: .bottom)
            }
        }
    }
    
    var SongName: some View {
        HStack(alignment: .center, spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text(music.selectedSong.songName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(music.selectedSong.artistName)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Button {
                
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.white)
                    .padding(12)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .light)
                    }
            }
        }
    }
    func PauseOrSkip(size: CGSize) -> some View {
        HStack(spacing: size.width * 0.18) {
            Button {
                
            } label: {
                Image(systemName: "backward.fill")
                    .font(size.height < 300 ? .title3 : .title)
            }
            
            Button {
                
            } label: {
                Image(systemName: "pause.fill")
                    .font(size.height < 300 ? .largeTitle : .system(size: 50))
            }
            
            Button {
                
            } label: {
                Image(systemName: "forward.fill")
                    .font(size.height < 300 ? .title3 : .title)
            }
        }
        .foregroundColor(.white)
        .frame(maxHeight: .infinity)
    }
    func SongLength(spacing: CGFloat) -> some View {
        Group {
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .light)
                .frame(height: 5)
                .padding(.top, spacing)
            
            HStack {
                Text("0:00")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer(minLength: 0)
                
                Text("3:33")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    var AudioSlider: some View {
        HStack(spacing: 15) {
            Image(systemName: "speaker.fill")
                .foregroundColor(.gray)
            
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .light)
                .frame(height: 5)
            
            Image(systemName: "speaker.wave.3.fill")
                .foregroundColor(.gray)
        }
    }
    func AirpodControls(size: CGSize) -> some View {
        HStack(alignment: .top, spacing: size.width * 0.18) {
            Button {
                
            } label: {
                Image(systemName: "quote.bubble")
                    .font(.title2)
            }
            
            VStack(spacing: 6) {
                Button {
                    
                } label: {
                    Image(systemName: "airpods.gen3")
                        .font(.title2)
                }
                
                Text("Carson's Airpods")
                    .font(.caption)
            }
            
            Button {
                
            } label: {
                Image(systemName: "list.bullet")
                    .font(.title2)
            }
        } .foregroundColor(.white)
            .blendMode(.overlay)
    }
}

class MusicObservable: ObservableObject {
    @Published var showingMediaPlayer = false
    @Published var hideTabBar = false
    @Published var songs: [Song] = readSongFile(fileName: "songs")
    @Published var selectedSong: Song = Song(songName: "", albumPhoto: "", artistName: "", id: 4)
    func showMediaPlayer() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingMediaPlayer.toggle()
        }
    }
    func toggleTabBar(newValue: Bool) {
        withAnimation(.easeInOut(duration: 0.3)) {
            hideTabBar = newValue
        }
    }
    func selectSong(song: Song) {
        withAnimation {
            selectedSong = song
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Main()
    }
}
