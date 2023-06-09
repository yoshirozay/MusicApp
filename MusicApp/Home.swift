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
    @StateObject var animations = AnimationObservable()
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
            Playlists(music: music, animations: animations)
                .setTabItem("Playlists", "play.square.stack")
                .setTabBarBackground(.init(.ultraThickMaterial))
                .hideTabBar(music.hideTabBar)
                .tag("playlists")
//            SampleTab("Playlist", "play.square.stack")
            SampleTab("Social", "magnifyingglass")
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
    @Published var playlists = [Playlist]()
    @Published var playlists2 = [Playlist]()
    @Published var selectedPlaylist = Playlist(id: 0, playlistName: "Friday Night", playlistPhoto: "ckay", songs: readSongFile(fileName: "songs"), monthlyListeners: 6432321)
    init() {
        selectAlbum(album: albums[1])
        createPlaylists()
        createPlaylists2()
    }
    func showMediaPlayer() {
        withAnimation(.easeInOut(duration: 0.3)) {
            guard selectedSong.songName != "" else { return }
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
            selectedAlbum = album
    }
    func selectPlaylist(playlist: Playlist) {
        withAnimation {
            selectedPlaylist = playlist
        }
    }
//    1. haze wave
//    2. vibe tribe
//    3. dream flow
//    4. neon nights
//    5. sunburst
//    6. moonbeam
//    7. cosmic crush
//    8. starlight
//    9. electric echo
//    10. velvet visions
//    11. golden hour
//    12. wildflower
//    13. oceanic
//    14. midnight muse
//    15. solar flare
//    16. honeydew
//    17. bluebird
//    18. cherry blossom
//    19. rainbow road
//    20. silver lining
    func createPlaylists() {
        let playlistNames = ["haze wave", "neon nights", "starlight", "dream flow", "bluebird 5", "silver lining"]
        var allArtwork = [String]()
        for (index, item) in playlistNames.enumerated() {
            var songs = [Song]()
            while songs.count < 12 {
                songs.append(getRandomSong(playlistSongs: songs))
            }
            let artwork = getRandomArtwork(allArtwork: allArtwork)
            allArtwork.append(artwork)
            let playlist = Playlist(id: index, playlistName: item, playlistPhoto: artwork, songs: songs, monthlyListeners: Int.random(in: 1_000_000...100_000_000))
            playlists.append(playlist)
            
        }
    }
    func createPlaylists2() {
        let playlistNames = ["cherry blossom", "rainbow road", "solar flare", "golden hour", "velvet visions", "sunburst"]
        var allArtwork = [String]()
        for (index, item) in playlistNames.enumerated() {
            var songs = [Song]()
            while songs.count < 12 {
                songs.append(getRandomSong(playlistSongs: songs))
            }
            let artwork = getRandomArtwork(allArtwork: allArtwork)
            allArtwork.append(artwork)
            let playlist = Playlist(id: index, playlistName: item, playlistPhoto: artwork, songs: songs, monthlyListeners: Int.random(in: 1_000_000...100_000_000))
            playlists2.append(playlist)
            
        }
    }

    func getRandomSong(playlistSongs: [Song]) -> Song {
        var song: Song
        repeat {
            guard let randomAlbum = albums.randomElement() else {
                fatalError("There are no albums in the library.")
            }
            guard let randomSong = randomAlbum.songs.randomElement() else {
                fatalError("There are no songs in the selected album.")
            }
            song = randomSong
        } while playlistSongs.contains(where: { $0 == song })
        
        // Set the song ID to the current count of the playlistSongs array minus 1
        song.id = playlistSongs.count
        
        return song
    }
    func getRandomArtwork(allArtwork: [String]) -> String {
        var artwork: String
        repeat {
            artwork = "playlist\(Int.random(in: 1...17))"
        } while allArtwork.contains(where: { $0 == artwork || artwork == "playlist7" })
        
        return artwork
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Main()
    }
}
