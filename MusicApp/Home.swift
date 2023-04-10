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
    @State var selectedTab = "songs"
    var body: some View {
        TabView(selection: $selectedTab) {
            Songs(music: music)
                .setTabItem("Songs", "play.circle.fill")
                .setTabBarBackground(.init(.ultraThickMaterial))
                .hideTabBar(music.hideTabBar)
                .tag("songs")
            Albums(music: music)
                .setTabItem("Albums", "square.grid.2x2.fill")
                .setTabBarBackground(.init(.ultraThickMaterial))
                .hideTabBar(music.hideTabBar)
                .tag("albums")
//            SampleTab("Radio", "dot.radiowaves.left.and.right")
            SampleTab("Music", "play.square.stack")
            SampleTab("Search", "magnifyingglass")
        }
        .tint(.red)
        .safeAreaInset(edge: .bottom) {
            MusicPlayerFooter()
        }
        .overlay {
            if music.showingMediaPlayer {
                OpenedSong(music: music, animation: animation)
                    .transition(.asymmetric(insertion: .identity, removal: .offset(y: -5)))
            }
        }
        .onChange(of: music.showingMediaPlayer) { newValue in
            if selectedTab == "songs" {
                DispatchQueue.main.asyncAfter(deadline: .now() + (newValue ? 0.06 : 0.03)) {
                    music.toggleTabBar(newValue: newValue)
                }
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

class MusicObservable: ObservableObject {
    @Published var showingMediaPlayer = false
    @Published var hideTabBar = false
    @Published var songs: [Song] = readSongFile(fileName: "songs")
    @Published var selectedSong: Song = Song(songName: "", albumPhoto: "", artistName: "", id: 4, length: "")
    @Published var albums: [Album] = readAlbumFile(fileName: "albumList")
    @Published var selectedAlbum: Album = Album(id: 0, artistName: "", albumName: "", albumPhoto: "", songs: [Song(songName: "", albumPhoto: "", artistName: "", id: 0, length: "")])
    init() {
        selectAlbum(album: albums[1])
    }
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
    func selectAlbum(album: Album) {
        withAnimation(.easeIn(duration: 0.05)) {
            selectedAlbum = album
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Main()
    }
}
