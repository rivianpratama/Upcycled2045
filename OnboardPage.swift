//
//  OnboardPage.swift
//  Upcycled 2045
//
//  Created by Rivian Pratama on 23/02/25
//

import SwiftUI

struct OnboardPage: View {
    @State private var offset: CGFloat = 100
    @State private var opacity: CGFloat = 0
    @State private var showCreditsModal = false
    @State private var isStartGamePressed = false
    @State private var isCreditsPressed = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background Image with Scale and Fade Animation
                Image("Intro")
                    .resizable()
                    .scaledToFill()
                    .aspectRatio(contentMode: .fill)
                    .scaleEffect(opacity == 1 ? 1 : 1.1) // Scales from 1.1 to 1
                    .offset(y: offset)
                    .opacity(opacity)
                    .animation(.easeIn(duration: 1).delay(0), value: opacity)
                    .animation(.easeIn(duration: 1).delay(0), value: offset)

                VStack {
                    // Title Image with Bouncing Spring Animation
                    Image("Title")
                        .resizable()
                        .frame(width: 800, height: 600)
                        .aspectRatio(contentMode: .fill)
                        .offset(y: offset)
                        .opacity(opacity)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5), value: offset)
                        .animation(.easeIn(duration: 1).delay(0.5), value: opacity)
                        .onAppear(){
                            BackgroundMusicPlayer.shared.playSoundEffect("storeOpen")
                        }

                    // Start Game Button with Interactive Scaling
                    NavigationLink(destination: DialogView().transition(.scaleAndFade)) {                        Image("StartGame")
                            .padding(10)
                            .scaledToFit()
                            .scaleEffect(isStartGamePressed ? 1.1 : 1) // Scales up on press
                            .opacity(opacity)
                            .animation(.easeIn(duration: 1).delay(1), value: opacity)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        BackgroundMusicPlayer.shared.playSoundEffect("buttonClick")
                    })
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged({ _ in isStartGamePressed = true })
                            .onEnded({ _ in isStartGamePressed = false })
                    )

                    // Credits Button with Interactive Scaling
                    Button(action: {
                        BackgroundMusicPlayer.shared.playSoundEffect("buttonClick")
                        showCreditsModal = true
                    }) {
                        Image("Credits")
                            .padding(10)
                            .scaledToFit()
                            .scaleEffect(isCreditsPressed ? 1.1 : 1) // Scales up on press
                            .opacity(opacity)
                            .animation(.easeIn(duration: 1).delay(1.5), value: opacity)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged({ _ in isCreditsPressed = true })
                            .onEnded({ _ in isCreditsPressed = false })
                    )

                    Spacer()
                }
            }
            .onAppear {
                offset = -2
                opacity = 1
                BackgroundMusicPlayer.shared.play()
            }
        }
        .navigationViewStyle(.stack)
        .navigationBarHidden(true)
        .sheet(isPresented: $showCreditsModal) {
            CreditsView()
        }
    }
}

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var opacity: CGFloat = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Credits")
                .font(Font(CustomFonts.custom1.font1(size: 60)))
                .foregroundColor(.black)
                .opacity(opacity)
                .animation(.easeIn(duration: 0.5).delay(0), value: opacity)

            VStack(spacing: 15) {
                Text("Developed with Love")
                    .font(Font(CustomFonts.custom1.font1(size: 35)))
                    .foregroundColor(.black)
                    .opacity(opacity)
                    .animation(.easeIn(duration: 0.5).delay(0.5), value: opacity)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Visuals & Assets")
                        .font(Font(CustomFonts.custom1.font1(size: 35)))
                        .underline()
                    
                    Text("Photo: Creative Commons Source")
                    Text("Stable Diffusion Generations")
                    Text("Post-processed with Photoshop")
                    Text("Fonts by Google Fonts")
                }
                .opacity(opacity)
                .animation(.easeIn(duration: 0.5).delay(1), value: opacity)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Audio")
                        .font(Font(CustomFonts.custom1.font1(size: 35)))
                        .underline()
                    
                    Text("Music & SFX: GarageBand")
                    Text("Mixkit.co • Suno AI")
                }
                .opacity(opacity)
                .animation(.easeIn(duration: 0.5).delay(1.5), value: opacity)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Sprites & Textures")
                        .font(Font(CustomFonts.custom1.font1(size: 35)))
                        .underline()
                    
                    Text("Hand-drawn in Procreate")
                    Text("Pixel-perfected with Resprite")
                }
                .opacity(opacity)
                .animation(.easeIn(duration: 0.5).delay(2), value: opacity)
            }
            .padding(.horizontal)

            Button("Close") {
                BackgroundMusicPlayer.shared.playSoundEffect("pageChanging")
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .opacity(opacity)
            .animation(.easeIn(duration: 0.5).delay(2.5), value: opacity)
        }
        .padding()
        .padding(.leading, 100)
        .padding(.trailing, 100)
        .background(Color(red: 1.0, green: 0.95, blue: 0.7))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(red: 0.4, green: 0.2, blue: 0.1), lineWidth: 2)
        )
        .shadow(radius: 10)
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .padding(20)
        .background(
            Color(red: 0.4, green: 0.2, blue: 0.1)
                .edgesIgnoringSafeArea(.all)
        )
        .onAppear {
            opacity = 1
        }
    }
}

extension AnyTransition {
    static var scaleAndFade: AnyTransition {
        AnyTransition.scale(scale: 0.9).combined(with: .opacity)
    }
}


struct OnboardPage_Previews: PreviewProvider {
    static var previews: some View {
        OnboardPage()
            .previewInterfaceOrientation(.landscapeLeft)
    }
}
