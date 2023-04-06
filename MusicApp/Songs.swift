//
//  Songs.swift
//  MusicApp
//
//  Created by Carson O'Sullivan on 4/6/23.
//

import SwiftUI

struct Songs: View {
    @ObservedObject var music:  MusicObservable
    var body: some View {
        ZStack {
            Image("takeCare")
                .resizable()
                .opacity(0.85)
                .scaledToFit()
            
            VisualEffectBlur(blurStyle: .systemMaterial)
                .ignoresSafeArea()
            
            ScrollView (showsIndicators: false){
                VStack  {
                    ForEach(music.songs, id: \.self) { item in
                        IndividualSong(song: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    music.selectSong(song: item)
                                    music.showMediaPlayer()
                                }
                            }
                    }
                }
            }
        }
    }
    
}

struct IndividualSong: View {
    var song: Song
    var body: some View {
        VStack {
            ZStack (alignment: .bottomTrailing) {
                HStack {
                    Image(song.albumPhoto)
                        .resizable()
                        .frame(width: 175, height: 175)
                        .cornerRadius(10)
                    Spacer()
                    VStack (spacing: 2) {
                        Text(song.songName)
                            .font(.title3.weight(.semibold))
                        Text(song.artistName)
                            .font(.body)
                    }
                    Spacer()
                }
                Image(systemName: "play.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .padding()
            Rectangle()
                .frame(height: 2)
                .foregroundColor(.white)
        }
    }
}

struct Song: Identifiable, Hashable, Decodable {
    let songName: String
    let albumPhoto: String
    let artistName: String
    let id: Int
}


struct Songs_Previews: PreviewProvider {
    static var previews: some View {
        Songs(music: MusicObservable())
    }
}
