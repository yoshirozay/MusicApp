//
//  Albums.swift
//  MusicApp
//
//  Created by Carson O'Sullivan on 4/7/23.
//

import SwiftUI

struct Albums: View {
    @ObservedObject var music:  MusicObservable
    @State private var index: Int = 0
    var body: some View {
        GeometryReader {
            let size = $0.size
            VStack {
                OpenedAlbum(music: music)
                AlbumCarousel
                    .frame(height: 120)
                    .offset(y: music.selectedSong.songName == "" ? -4 : -74)
            }
        }
        .task {
            music.selectAlbum(album: music.albums[1])
        }
    }
    var AlbumCarousel: some View {
        ZStack {
            GeometryReader { geometry in
                let size = geometry.size
                let pageWidth: CGFloat = size.width / 3
                
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { scrollViewProxy in
                        LazyHStack(spacing: 0) {
                            ForEach(music.albums.indices, id: \.self) { index in
                                ZStack {
                                    Image(music.albums[index].albumPhoto)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .frame(width: pageWidth, height: size.height)
                            }
                        }
                        .padding(.horizontal, (size.width - pageWidth) / 2)
                        .background {
                            SnapCarouselHelper(pageWidth: pageWidth, pageCount: music.albums.count, index: $index)
                        }
                        .task {
                            scrollViewProxy.scrollTo(2)
                        }
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.red, lineWidth: 3.5)
                        .frame(width: 120, height: 120)
                        .allowsHitTesting(false)
                }
            }
        }
        .onChange(of: index) { newValue in
            guard newValue < music.albums.count else { return }
            music.selectAlbum(album: music.albums[newValue])
        }
    }
}

struct OpenedAlbum: View {
    @ObservedObject var music:  MusicObservable
    var body: some View {
        GeometryReader {
            let size = $0.size
            VStack(spacing: 0) {
                AlbumHeader(size: size)
                SongList
            }
        }
    }
    func AlbumHeader(size: CGSize) -> some View {
        HStack {
            GeometryReader {
                let size = $0.size
                HStack {
                    Image(music.selectedAlbum.albumPhoto)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    //                                .frame(width: size.width/2, height: size.height)
                        .frame(width: 175, height: 175)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .animation(nil, value: music.selectedAlbum)
                    Spacer()
                    VStack {
                        Text(music.selectedAlbum.albumName)
                            .font(.title3.weight(.semibold))
                        Text(music.selectedAlbum.artistName)
                            .font(.body.weight(.light))
                    }
                    Spacer()
                }
                .offset(y: 7)
            }
            .frame(height: size.width/2 - 10)
            //            .matchedGeometryEffect(id: "albumArt", in: animation)
        }
        .padding([.horizontal, .top])
    }
    var SongList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16)  {
                ForEach(music.selectedAlbum.songs, id: \.self) { item in
                    IndividualSong(song: item)
                    Rectangle()
                        .frame(height: 1)
                }
            } .padding([.horizontal, .top])
        }
    }
    func IndividualSong(song: Song) -> some View {
        HStack {
            Text("#\(song.id+1)")
                .font(.subheadline)
                .frame(width: 40)
            VStack (alignment: .leading, spacing: 2) {
                Text(song.songName)
                    .font(.title3.weight(.medium))
                Text(song.artistName)
                    .font(.subheadline.weight(.light))
            }
            Spacer()
            Text(song.length)
                .font(.caption.weight(.regular))
        }
    }
}

struct Albums_Previews: PreviewProvider {
    static var previews: some View {
        Albums(music: MusicObservable())
    }
}

struct Album: Identifiable, Hashable, Decodable {
    let id: Int
    let artistName: String
    let albumName: String
    let albumPhoto: String
    let songs: [Song]
}
