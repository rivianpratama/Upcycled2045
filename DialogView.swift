//
//  DialogView.swift
//  Upcycled 2045
//
//  Created by Rivian Pratama on 23/02/25
//

import SwiftUI

struct DialogueBoxView: View {
    let text: String

    var body: some View {
        Image("ConversationBox")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 2000)
            .overlay(
                Text(text)
                    .font(Font(CustomFonts.custom1.font1(size: 30)))
                    .foregroundColor(.black)
                    .padding(40)
                    .multilineTextAlignment(.center),
                alignment: .center
            )
    }
}

struct DialogView: View {
    let dialogs = [
        (text: "2030: The day when our trash problem became too big to ignore.\n\n" +
               "It started in Jakarta. The government had been dumping trash into the " +
               "ocean for years. One day, there was a big explosion from all the trash " +
               "gases under the water. This caused a huge wave that brought all our " +
               "garbage back to the city. Plastic, electronic waste, everything came " +
               "back with the water.\n\n" +
               "Many people were dying. This disaster showed us that we can't keep " +
               "throwing away our trash without thinking.",
         image: "bg_trash_tsunami"),
        
        (text: "2040: The world is in big trouble.\n\n" +
               "There are riots and fights everywhere because we ran out of places to put our trash. " +
               "Cities are becoming unlivable. Mountains of garbage are taller than " +
               "buildings. Scientists say if we don't fix this in 5 years, we won't " +
               "be able to live on Earth anymore.\n\n" +
               "We need to find a solution as soon as possible.",
         image: "bg_last_warung"),
        
        (text: "For 50 years, someone was working on a solution.\n\n" +
               "There was a great inventor who didn't give up. They spent their whole " +
               "life trying to build a machine that could turn trash into useful things. " +
               "They failed many times but kept trying.\n\n" +
               "People thought they were crazy, but finally, their machine worked.",
         image: "bg_machine_heart"),
        
        (text: "2045: The machine is completed!\n\n" +
               "After years of hard work, the inventor finished the machine. It can " +
               "take any kind of trash and turn it into useful products that people " +
               "want to buy. The inventor chose you to run this machine.\n\n" +
               "You'll work with 'The Dealer' who know how to sell these products. " +
               "They will help you set the right prices and find customers.",
         image: "bg_awakening"),
        
        (text: "You are the 'The Clerk' - the chosen one to operate this machine.\n\n" +
               "Your mission is simple: use the machine to make new products from trash, " +
               "then sell these products through the traders. The more you sell, " +
               "the more trash you clean up. If you can sell enough products, you'll " +
               "help clean up all the landfills.\n\n" +
               "Can you help save the world?",
         image: "bg_mission")
    ]
    
    let backgroundImages = ["bg1", "bg2", "bg3", "bg4", "bg5"]
    
    @State private var currentDialogIndex = 0
    @State private var showContentView = false
    @State private var pulseAnimation = false

    var body: some View {
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
        .onAppear { pulseAnimation = true }
        .onTapGesture { handleTap() }
        .onAppear {
            BackgroundMusicPlayer.shared.play()
        }
        .fullScreenCover(isPresented: $showContentView) {
            ContentView()
        }
    }
    
    private func handleTap() {
        BackgroundMusicPlayer.shared.playSoundEffect("pageChanging")
        if currentDialogIndex < dialogs.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentDialogIndex += 1
            }
        } else {
            showContentView = true
        }
    }
}

struct DialogView_Previews: PreviewProvider {
    static var previews: some View {
        DialogView()
    }
}
