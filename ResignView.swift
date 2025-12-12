//
//  ResignPage.swift
//  Upcycled 2045
//
//  Created by Rivian Pratama on 23/02/25
//

import SwiftUI

struct ResignView: View {
    let dialogs = [
        (text: "You've made a difficult choice to resign...\n\n" +
               "The landfills grew faster than the machine could process. Even running " +
               "24 hours a day, it wasn't enough. As the only Clerk chosen by the inventor, " +
               "your resignation means humanity has lost its best chance. The inventor " +
               "searched desperately for someone else who could operate the machine, " +
               "but found no one.\n\n" +
               "Without a solution, more people died each day from pollution and disease.",
         image: "bg_trash_tsunami"),
        (text: "The inventor disappeared without a trace.\n\n" +
               "World leaders offered billions to find them. Search teams looked " +
               "everywhere. The inventor's workshop was empty, their notes scattered. " +
               "The machine stood silent, a reminder of what could have been.\n\n" +
               "People began to lose hope. Without the inventor or the Clerk, " +
               "humanity's last chance was slipping away.",
         image: "bg_last_warung"),
        (text: "2075: Only 10,000 humans remain on Earth.\n\n" +
               "Someone found the inventor's hidden diary. It revealed an incredible " +
               "truth - they built a time machine! Their plan was to travel back to " +
               "the Industrial Revolution, to stop excessive consumption before it " +
               "began.\n\n" +
               "But did they make it? Did they change anything? The diary ends here.",
         image: "bg_machine_heart"),
        (text: "2100: A final message arrives from the past.\n\n" +
               "The inventor's words are clear but sad: 'I tried to warn them about " +
               "their wasteful ways. About how their choices would destroy the future. " +
               "But no one listened. They called me a threat, a madman. Now I face " +
               "death for speaking the truth.'\n\n" +
               "The message ends. Humanity's last hope died with them.",
         image: "bg_awakening"),
        (text: "This is more than just a game. It's a warning.\n\n" +
               "Every piece of trash we create today shapes tomorrow. Small choices " +
               "matter - choosing reusable items, refusing unnecessary packaging, " +
               "repairing instead of replacing. We don't need one hero or one " +
               "magical machine. We need everyone to act.\n\n" +
               "The future isn't written yet. Think before you buy. Think before " +
               "you throw away. Because in the real world, we can't resign and " +
               "start over. We only have one Earth.\n\n" +
               "Would you like to try again?",
         image: "bg_mission")
    ]
    
    let backgroundImages = ["bg6", "bg7", "bg8", "bg9", "bg10"]
    
    @State private var currentDialogIndex = 0
    @State private var showOnboardPage = false
    @State private var pulseAnimation = false

    var body: some View {
        NavigationStack {
            ZStack {
              
                Image(backgroundImages[currentDialogIndex])
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(Color.black.opacity(0.3))
                    .animation(.easeInOut(duration: 0.5), value: currentDialogIndex)
                
                VStack {
                    Spacer()
                    
                    if currentDialogIndex < dialogs.count - 1 {
                        Text("[ TAP TO CONTINUE ]")
                            .font(Font(CustomFonts.custom1.font1(size: 40)))
                            .foregroundColor(.yellow)
                            .opacity(pulseAnimation ? 1 : 0.6)
                            .animation(Animation.easeInOut(duration: 1.0).repeatForever(), value: pulseAnimation)
                            .padding(.bottom, 10)
                    }
                    
                    DialogueBoxView(text: dialogs[currentDialogIndex].text)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
            }
            .onTapGesture { handleTap() }
            .onAppear {
                pulseAnimation = true
                BackgroundMusicPlayer.shared.play()
            }
            .navigationDestination(isPresented: $showOnboardPage) {
                OnboardPage()
            }
        }
    }
    
    private func handleTap() {
        BackgroundMusicPlayer.shared.playSoundEffect("pageChanging")
        if currentDialogIndex < dialogs.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentDialogIndex += 1
            }
        } else {
            showOnboardPage = true
        }
    }
}

struct ResignView_Previews: PreviewProvider {
    static var previews: some View {
        ResignView()
    }
}
