//
//  ContentView.swift
//  Upcycled 2045
//
//  Created by Rivian Pratama on 23/02/25
//


import SwiftUI
import SceneKit
import UIKit

class GameTime: ObservableObject {
    @Published var totalMinutes: Int = 360
    @Published var days: Int = 1
    private var timerInterval: TimeInterval = 1.0
    private var timer: Timer?

    var currentTime: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%02d:%02d", hours, minutes)
    }

    var isWorkingHours: Bool {
        let current = totalMinutes % 1440
        return current >= 540 && current < 1020
    }

    func start() {
        timerInterval = 1.0
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.totalMinutes += self.isWorkingHours ? 6 : 60
            if self.totalMinutes >= 1440 {
                self.days += 1
                self.totalMinutes %= 1440
            }
        }
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        totalMinutes = 540
        days = 1
        start()
    }
    
    func stopClockAtSix() {
        timerInterval = 10.0
        timer?.invalidate()
        timer = nil
        days = 1
        totalMinutes = 360
    }
}

class GlobalTrashSupply: ObservableObject {
    @Published var amount: Int = Int.random(in: 100_000...500_000)
    func addDailySupply() { amount += Int.random(in: 1000...5000) }
}

struct Material: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    let uiColor: UIColor

    static let all: [Material] = [
        Material(name: "Cans", color: Color(red: 0.47, green: 0.85, blue: 0.47), uiColor: UIColor(red: 0.47, green: 0.85, blue: 0.47, alpha: 1)),
        
        Material(name: "Wrap", color: Color(red: 0.95, green: 0.95, blue: 0.45), uiColor: UIColor(red: 0.95, green: 0.95, blue: 0.45, alpha: 1)),
        
        Material(name: "Cups", color: Color(red: 0.95, green: 0.47, blue: 0.95), uiColor: UIColor(red: 0.95, green: 0.47, blue: 0.95, alpha: 1)),
        
        Material(name: "Mask", color: Color(red: 0.47, green: 0.85, blue: 0.95), uiColor: UIColor(red: 0.47, green: 0.85, blue: 0.95, alpha: 1)),
        
        Material(name: "Sack", color: Color(red: 0.47, green: 0.47, blue: 0.95), uiColor: UIColor(red: 0.47, green: 0.47, blue: 0.95, alpha: 1))
    ]
}

struct TextureGenerator {
    static func generateTexture(size: CGSize, noiseLevel: Double, baseColor: UIColor, speckleColor: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let context = ctx.cgContext
            context.setFillColor(baseColor.cgColor)
            context.fill(CGRect(origin: .zero, size: size))

            let baseMultiplier = 5000.0
            let dynamicSizeRange = 4.0 + (noiseLevel * 12)
            let speckleCount = Int(baseMultiplier * noiseLevel)
            for _ in 0..<speckleCount {
                context.saveGState()
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let rotation = CGFloat.random(in: 0...(2 * .pi))
                let size = CGFloat.random(in: 2...dynamicSizeRange)
                context.translateBy(x: x, y: y)
                context.rotate(by: rotation)
                context.setFillColor(speckleColor.cgColor)
                drawRandomShape(context: context, size: size)
                context.restoreGState()
            }
        }
    }

    private static func drawRandomShape(context: CGContext, size: CGFloat) {
        switch Int.random(in: 0...2) {
        case 0: drawRectangle(context: context, size: size)
        case 1: drawTriangle(context: context, size: size)
        default: drawBlob(context: context, size: size)
        }
    }

    private static func drawRectangle(context: CGContext, size: CGFloat) {
        let rect = CGRect(x: -size/2, y: -size/2, width: size, height: size)
        context.fill(rect)
    }

    private static func drawTriangle(context: CGContext, size: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: -size/2))
        path.addLine(to: CGPoint(x: size/2, y: size/2))
        path.addLine(to: CGPoint(x: -size/2, y: size/2))
        path.close()
        context.addPath(path.cgPath)
        context.fillPath()
    }

    private static func drawBlob(context: CGContext, size: CGFloat) {
        let path = UIBezierPath()
        let points = (0..<8).map { _ in
            CGPoint(
                x: CGFloat.random(in: -size/2...size/2),
                y: CGFloat.random(in: -size/2...size/2)
            )
        }
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.close()
        context.addPath(path.cgPath)
        context.fillPath()
    }
}

class SceneCoordinator: ObservableObject {
    let scene = SCNScene()
    let material = SCNMaterial()
    let cameraNode = SCNNode()
    private let modelName: String
    
    init(modelName: String) {
        self.modelName = modelName
        setupScene()
        setupCamera()
        setupLighting()
    }
    
    private func setupScene() {
        guard let modelScene = SCNScene(named: modelName) else {
            fatalError("3D model \(modelName) not found")
        }
        let modelRoot = modelScene.rootNode.clone()
        modelRoot.position = SCNVector3(0, 0.1, 0)
        modelRoot.enumerateHierarchy { node, _ in
            node.geometry?.materials = [self.material]
            node.castsShadow = true
        }
        scene.rootNode.addChildNode(modelRoot)
        
       
        let floor = SCNFloor()
        floor.reflectivity = 0.1
        floor.firstMaterial?.diffuse.contents = UIColor(white: 0.9, alpha: 1)
        floor.firstMaterial?.lightingModel = .physicallyBased
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(floorNode)
    }
    
    private func setupCamera() {
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 10, 10)
        cameraNode.camera?.fieldOfView = 40
        cameraNode.eulerAngles = SCNVector3(-Float.pi / 6, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
    }


    
    private func setupLighting() {
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.5, alpha: 1)
        ambientLight.light?.intensity = 300
        scene.rootNode.addChildNode(ambientLight)
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.color = UIColor.white
        directionalLight.light?.intensity = 1200
        directionalLight.light?.castsShadow = true
        directionalLight.light?.shadowMode = .deferred
        directionalLight.light?.shadowSampleCount = 16
        directionalLight.light?.shadowRadius = 3.0
        directionalLight.light?.shadowColor = UIColor(white: 0, alpha: 0.5)
        
        directionalLight.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/4, 0)
        directionalLight.position = SCNVector3(0, 5, 5)
        scene.rootNode.addChildNode(directionalLight)
        
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .omni
        fillLight.light?.color = UIColor(white: 0.7, alpha: 1)
        fillLight.light?.intensity = 500
        fillLight.position = SCNVector3(-5, 3, 5)
        scene.rootNode.addChildNode(fillLight)
    }

    
    func updateTexture(_ texture: UIImage) {
        material.diffuse.contents = texture
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat
        material.diffuse.contentsTransform = SCNMatrix4MakeScale(3, 3, 1)
    }
}

struct ContentView: View {
    @StateObject private var gameTime = GameTime()
    @StateObject private var globalSupply = GlobalTrashSupply()
    @State private var showResignView = false
    @State private var materialCounts: [String: Int] = [:]
    @State private var materialSupplies: [Material: Int] = [:]
    @State private var previewTexture: UIImage?
    @State private var generatedTexture: UIImage?
    @State private var totalClicks = 0
    @State private var money = 0
    @State private var isGenerated = false
    @State private var lastSavedMaterialSupplies: [Material: Int] = [:]
    @State private var playedStoreOpen = false
    @State private var playedStoreClose = false
    @State private var firstClickedMaterial: Material? = nil
    @State private var electricity = 10
    @State private var fiberglass = 50
    @State private var lastSavedFiberglass = 50
    @State private var lastSavedElectricity = 10
    @State private var showingShop = false
    @State private var selectedModel = "Chair.obj"
    @State private var column1: String = ""
    @State private var column2: String = ""
    @State private var column3: String = ""
    @State private var column4: String = ""
    @State private var potentialSellingPrice = 0
    @State private var dailySalesCount = 0
    @State private var totalCorrectSales = 0
    @State private var customerSatisfactionRating = 5
    @State private var lastProcessedDay = 1
    @State private var showingSatisfactionAlert = false
    @State private var satisfactionBonus: Int = 0
    @State private var dailyProfit = 0
    @State private var isFabricated = false
    @State private var dailyMaterialPurchases = 0
    @State private var previousDayStats: (sold: Int, profit: Int, materials: Int) = (0, 0, 0)
    @State private var showIntroduction = true
    @State private var currentDialogIndex = 0
    @State private var showFabricatedMessage = false
    @State private var showSoldMessage = false
    private let introductionDialogs = [
        "Welcome to Upcycled 2045! In this game, your mission is to transform waste into valuable products by combining trash materials.",
        "How to Play: You’ll receive orders from The Dealer asking for bespoke upcycled product. Your task is to pick the correct trash items—each with a distinct color and type—to match The Dealer request.",
        "Resource Management: Keep a close eye on your consumables. Energy powers your fabrication process, while Catalyst boosts the transformation of materials. If your supplies run low, visit the shop to recharge.",
        "Fabrication Flow: Once you’ve selected the right materials, you’ll enter the fabrication phase. A preview window will show the object as it’s being created. This is your chance to verify that you’ve assembled the correct combination. Materials and consumables that already fabricated cannot be recovered!",
        "Quality Control: You can pinch to zoom, drag to rotate, and scroll to move the fabricated product with your fingers. Check every angle to make sure it’s perfect before selling!",
        "Satisfaction Rating: After fabrication, the product is evaluated against the trader’s order. A higher satisfaction rating—based on how accurately you match the request—yields bonus earnings. Missed matches lower your rating and your potential profit.",
        "Time & Shop Rules: Remember, the shop is only open from 6:00 AM to 5:00 PM. You must manage your time well, ensuring you fabricate and sell products within these hours.",
        "Sales Objective: Your ultimate goal is to sell as many products as possible, reducing the global landfill’s waste supply. But beware—the landfill is resupplied with waste every morning at 6:00 AM!",
        "The Shop: You can buy materials, consumables, and machine upgrades. Running out of Energy or Catalyst means you won’t be able to fabricate products. Make sure to restock before you run out!",
        "Upgrading Machines: Invest in upgrades to improve fabrication speed, reduce energy consumption, and expand storage capacity. Better machines help you stay ahead of waste resupply!",
        "Plan Ahead: If you don’t sell enough products, the landfill might keep growing instead of shrinking! You’ll need to stay efficient, upgrade your resources, and maximize sales to stay ahead of waste accumulation.",
        "Master the Mechanics: Use the trader’s instructions, monitor your resource meters, and aim for high satisfaction ratings to maximize bonuses. Every decision counts!",
        "Let's get started! Tap to continue and begin your journey—master the mechanics and clear the landfill in Upcycled 2045!"
    ]
    
    private let maxTotalClicks = 6
    private let startingMaterialCount = 10
    private let maxSelectedMaterials = 2
    
    private var textureBaseMaterial: Material {
        firstClickedMaterial ?? Material.all[2]
    }
    
    private var selectedMaterialsCount: Int {
        materialCounts.values.filter { $0 > 0 }.count
    }
    
    private var baseMaterial: Material {
        firstClickedMaterial ?? Material.all[2]
    }
    
    private var speckleColor: UIColor {
        var colors: [UIColor] = []
        for material in Material.all where material != textureBaseMaterial {
            colors += Array(repeating: material.uiColor, count: materialCounts[material.name, default: 0])
        }
        return colors.randomElement() ?? textureBaseMaterial.uiColor
    }
    
    private var noiseLevel: Double {
        guard totalClicks > 0 else { return 0 }
        let nonBaseClicks = totalClicks - materialCounts[textureBaseMaterial.name, default: 0]
        return Double(nonBaseClicks) / Double(maxTotalClicks)
    }
    
    var body: some View {
        NavigationStack{
        ZStack{
            ZStack{
                Image("BackgroundImage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .ignoresSafeArea()
                    .zIndex(0)
                Image("Convo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 175)
                    .position(x:1020, y: 815)
                    .opacity(gameTime.isWorkingHours ? 1 : 0)
                    .animation(.easeInOut, value: gameTime.isWorkingHours)
                Image("openWindow")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .position(x:1350, y: 250)
                    .opacity(gameTime.isWorkingHours ? 1 : 0)
                    .animation(.easeInOut, value: gameTime.isWorkingHours)
                Image("closeWindow")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .position(x:1350, y: 250)
                    .opacity(gameTime.isWorkingHours ? 0 : 1)
                    .animation(.easeInOut, value: gameTime.isWorkingHours)
                Image("Clerk")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .position(x:500, y: 950)
                    .opacity(gameTime.isWorkingHours ? 1 : 0)
                    .animation(.easeInOut, value: gameTime.isWorkingHours)
                Image("Trader")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .position(x:1100, y: 950)
                    .opacity(gameTime.isWorkingHours ? 1 : 0)
                    .animation(.easeInOut, value: gameTime.isWorkingHours)
                Image("Close")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .position(x:800, y: 975)
                    .opacity(gameTime.isWorkingHours ? 0 : 1)
                    .animation(.easeInOut, value: gameTime.isWorkingHours)
                if showFabricatedMessage {
                                    Text("Fabricated!")
                        .font(Font(CustomFonts.custom1.font1(size: 120)))
                                        .foregroundColor(.white)
                                        .shadow(color: .black, radius: 5)
                                        .transition(.opacity)
                                        .animation(.easeInOut(duration: 0.5), value: showFabricatedMessage)
                                        .position(x: UIScreen.main.bounds.width / 4,
                                                 y: UIScreen.main.bounds.height / 4)
                                }
                                
                                if showSoldMessage {
                                    Text("Sold!")
                                        .font(Font(CustomFonts.custom1.font1(size: 120)))
                                        .foregroundColor(.white)
                                        .shadow(color: .black, radius: 5)
                                        .transition(.opacity)
                                        .animation(.easeInOut(duration: 0.5), value: showSoldMessage)
                                        .position(x: UIScreen.main.bounds.width / 4,
                                                 y: UIScreen.main.bounds.height / 4)
                                }
                Button(action: {
                              resetAllGame()
                            
                              showResignView = true
                          }) {
                              Image("resignButton")
                                  .resizable()
                                  .scaledToFit()
                                  .frame(height: 70)
                                  .padding(20)
                                  .contentShape(Rectangle())
                          }
                          .position(x: 1275, y: 975)
                          .zIndex(100)

                          NavigationLink(destination: ResignView(), isActive: $showResignView) {
                              EmptyView()
                          }
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("DAY \(gameTime.days)")
                                .font(Font(CustomFonts.custom1.font1(size: 50)))
                                .foregroundColor(.black)
                            Text("\(gameTime.currentTime) - \(gameTime.isWorkingHours ? "WORKING" : "CLOSED")")
                                .font(Font(CustomFonts.custom1.font1(size: 50)))
                                .foregroundColor(gameTime.isWorkingHours ? .green : .red)
                            HStack {
                                Text("Satisfaction:")
                                    .font(Font(CustomFonts.custom1.font1(size: 50)))
                                    .foregroundColor(.black)
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= customerSatisfactionRating ? "star.fill" : "star")
                                        .foregroundColor(.black)
                                        .font(.system(size: 25))
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sell the products until nothing left in the landfill!")
                                .font(Font(CustomFonts.custom1.font1(size:35)))
                                .foregroundColor(.black)
                            Text("Landfill: \(globalSupply.amount) Tonnage")
                                .font(Font(CustomFonts.custom1.font1(size: 35)))
                                .foregroundColor(.black)
                                .padding(.bottom, 75)
                                .padding(.top,-10)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 15)
                    }
                    .padding()
                    .padding(.horizontal)
                    HStack(spacing: 250) {
                        VStack {
                            Spacer()
                            HStack(spacing: 0){
                                Spacer()
                                Spacer()
                                Spacer()
                                Spacer()
                                Spacer()
                                MaterialsGrid(
                                    materialCounts: $materialCounts,
                                    materialSupplies: $materialSupplies,
                                    isGenerated: isGenerated,
                                    selectedMaterialsCount:
                                        selectedMaterialsCount,
                                    firstClickedMaterial: $firstClickedMaterial,
                                    handleMaterialTap: handleMaterialTap
                                )
                                VStack{
                                    Spacer()
                                    ZStack{
                                        FinancialInfo(money: money,
                                                      globalSupply: globalSupply.amount,
                                                      electricity: $electricity,
                                                      fiberglass: $fiberglass,
                                                      customerSatisfactionRating: customerSatisfactionRating,
                                                      showShop: { showingShop = true })
                                        .padding(.top, 155)
                                        .padding(.leading, -5)
                                        SelectionCounter(totalClicks: totalClicks, maxTotalClicks: maxTotalClicks)
                                            .zIndex(1)
                                            .position(x:130 ,y: 260)
                                        
                                        PreviewWindow(previewTexture: previewTexture)
                                            .zIndex(0)
                                            .padding(.top, 50)
                                    }
                                    HStack(spacing: -10) {
                                        Button(action: {
                                            BackgroundMusicPlayer.shared.playSoundEffect("modelClick")
                                            selectedModel = "Chair.obj"
                                        }) {
                                            Image("Chair")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 40)
                                                .grayscale(selectedModel == "Chair.obj" ? 0 : 1)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: {
                                            BackgroundMusicPlayer.shared.playSoundEffect("modelClick")
                                            selectedModel = "Cabinet.obj"
                                        }) {
                                            Image("Cabinet")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 40)
                                                .grayscale(selectedModel == "Cabinet.obj" ? 0 : 1)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Button(action: {
                                            BackgroundMusicPlayer.shared.playSoundEffect("modelClick")
                                            selectedModel = "Desk.obj"
                                        }) {
                                            Image("Desk")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(height: 40)
                                                .grayscale(selectedModel == "Desk.obj" ? 0 : 1)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }                          .position(x:185, y: 235)
                                    ActionButtons(
                                        isGenerated: isGenerated,
                                        totalClicks: totalClicks,
                                        gameTime: gameTime,
                                        money: $money,
                                        electricity: electricity,
                                        isFabricated: isFabricated,
                                        generateObject: generateObject,
                                        sellObject: sellObject,
                                        resetAll: resetAll
                                    )
                                    .position(x:187, y: 100 )
                                }
                                .padding(.top,30)
                            }
                        }
                        .padding(.leading, 50)
                        VStack {
                            ObjectWindow(generatedTexture: generatedTexture, modelName: selectedModel)
                            Spacer()
                            ConversationBox(
                                isGenerated: isGenerated,
                                column1: column1,
                                column2: column2,
                                column3: column3,
                                column4: column4,
                                sellingPrice: potentialSellingPrice,
                                gameTime: gameTime
                            )
                            .disabled(!isFabricated)
                            .position(x: 120, y:85)
                            Spacer()
                        }
                        .padding(.trailing, 150)
                        .frame(width: 400)
                    }
                    .padding(.trailing, 80)
                    HStack {
                        VStack {
                            Text("Balance: $\(money)")
                                .foregroundColor(.black)
                                .font(Font(CustomFonts.custom1.font1(size: 50)))
                                .padding(.bottom,10)
                            Button(action: {
                                showingShop = true
                                BackgroundMusicPlayer.shared.playSoundEffect("shopClick")
                            }) {
                                Image("OpenShop")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 200)
                            }
                        }
                        .padding(.leading, 50)
                        .padding(.bottom, 35)
                        Spacer()
                    }
                }
                .onAppear {
                    initializeSupplies()
                    generateColumns()
                }
                .onChange(of: materialCounts) { _ in updatePreview() }
                .onChange(of: gameTime.days) { newDay in
                    if newDay > lastProcessedDay {
                        previousDayStats = (dailySalesCount, dailyProfit, dailyMaterialPurchases)
                        calculateSatisfactionRating()
                        lastProcessedDay = newDay
                        dailySalesCount = 0
                        dailyProfit = 0
                        dailyMaterialPurchases = 0
                        totalCorrectSales = 0
                        showingSatisfactionAlert = true
                    }
                }
                .sheet(isPresented: $showingShop) {
                    ShopView(
                        electricity: $electricity,
                        fiberglass: $fiberglass,
                        money: $money,
                        materialSupplies: $materialSupplies,
                        globalSupply: $globalSupply.amount,
                        handleReplenishElectricity: handleReplenishElectricity,
                        handleReplenishFiberglass: handleReplenishFiberglass,
                        handleReplenishMaterial: handleReplenishMaterial
                    )
                }
                .sheet(isPresented: $showingSatisfactionAlert) {
                    SatisfactionRatingView(
                        rating: customerSatisfactionRating,
                        bonus: satisfactionBonus,
                        soldItems: previousDayStats.sold,
                        profit: previousDayStats.profit,
                        materialsBought: previousDayStats.materials
                    )
                }
            }
            .disabled(showIntroduction)
            if showIntroduction {
                IntroductionView(
                    currentDialog: introductionDialogs[currentDialogIndex],
                    progress: Double(currentDialogIndex + 1) / Double(introductionDialogs.count),
                    onContinue: {
                        if currentDialogIndex < introductionDialogs.count - 1 {
                            currentDialogIndex += 1
                        } else {
                            withAnimation {
                                showIntroduction = false
                                gameTime.start()
                            }
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .onAppear {
            BackgroundMusicPlayer.shared.play()
        }
        .onChange(of: gameTime.totalMinutes) { newMinutes in
            if newMinutes == 540 && !playedStoreOpen {
                BackgroundMusicPlayer.shared.playSoundEffect("storeOpen")
                playedStoreOpen = true
            }
            if newMinutes == 1020 && !playedStoreClose {
                BackgroundMusicPlayer.shared.playSoundEffect("storeClose")
                playedStoreClose = true
            }
            
           
            if newMinutes < 360 {
                playedStoreOpen = false
                playedStoreClose = false
            }
        }
    }
        .navigationViewStyle(StackNavigationViewStyle())
}

    private func resetAllGame() {
        gameTime.stopClockAtSix()
        gameTime.totalMinutes = 360
        gameTime.days = 1
        globalSupply.amount = Int.random(in: 100_000...500_000)
        materialCounts = [:]
        totalClicks = 0
        isGenerated = false
        generatedTexture = nil
        previewTexture = nil
        var newMaterialSupplies: [Material: Int] = [:]
        for material in Material.all {
            newMaterialSupplies[material] = 10
        }
        materialSupplies = newMaterialSupplies
        lastSavedMaterialSupplies = newMaterialSupplies
        fiberglass = 50
        lastSavedFiberglass = 50
        electricity = 10
        lastSavedElectricity = 10
        firstClickedMaterial = nil
        isFabricated = false
        potentialSellingPrice = 0
        dailySalesCount = 0
        totalCorrectSales = 0
        customerSatisfactionRating = 5
        lastProcessedDay = 1
        showingSatisfactionAlert = false
        satisfactionBonus = 0
        dailyProfit = 0
        dailyMaterialPurchases = 0
        previousDayStats = (sold: 0, profit: 0, materials: 0)
        playedStoreOpen = false
        playedStoreClose = false
        showingShop = false
        selectedModel = "Chair.obj"
        generateColumns()
        showIntroduction = true
        currentDialogIndex = 0
    }
    
    private func displayFabricatedAlert() {
            withAnimation {
                showFabricatedMessage = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    showFabricatedMessage = false
                }
            }
        }
        
        private func displaySoldAlert() {
            withAnimation {
                showSoldMessage = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    showSoldMessage = false
                }
            }
        }

    private func generateColumns() {
        let colors = ["green", "yellow", "pink", "blue", "purple"]
        let intensities = ["hint of", "touch of", "moderate", "strong", "rich of"]

        guard let firstColor = colors.randomElement() else { return }
        let remainingColors = colors.filter { $0 != firstColor }

        column1 = firstColor
        column2 = intensities.randomElement() ?? "moderate"
        column3 = remainingColors.randomElement() ?? "blue"
        column4 = ["Chair", "Desk", "Cabinet"].randomElement() ?? "Chair"
    }

    private func modelDisplayName(for modelName: String) -> String {
        switch modelName {
        case "Chair.obj": return "Chair"
        case "Cabinet.obj": return "Cabinet"
        case "Desk": return "Desk"
        default: return ""
        }
    }

    private func initializeSupplies() {
        Material.all.forEach { materialSupplies[$0] = startingMaterialCount }
        lastSavedMaterialSupplies = materialSupplies
        lastSavedFiberglass = 50
        lastSavedElectricity = 10
        fiberglass = 50
        electricity = 10
        previewTexture = nil
        generateColumns()
    }

    private func handleMaterialTap(_ material: Material) {
        let newTotalClicks = totalClicks + 1
        let requiresFiberglass = (newTotalClicks % 2 == 0)

        guard totalClicks < maxTotalClicks,
              !isGenerated,
              (materialCounts[material.name, default: 0] > 0 || selectedMaterialsCount < maxSelectedMaterials),
              (!requiresFiberglass || fiberglass > 0) else { return }

        let wasFirstClick = (totalClicks == 0)

        if wasFirstClick {
            guard materialSupplies[material, default: 0] >= 5 else { return }
            materialSupplies[material]! -= 5
            firstClickedMaterial = material
        } else {
            guard materialSupplies[material, default: 0] >= 1 else { return }
            materialSupplies[material]! -= 1
        }

        materialCounts[material.name, default: 0] += 1
        totalClicks = newTotalClicks

        if requiresFiberglass {
            fiberglass = max(fiberglass - 1, 0)
        }

        updatePreview()
    }

    private func updatePreview() {
        guard totalClicks > 0 else {
            previewTexture = nil
            return
        }

        previewTexture = TextureGenerator.generateTexture(
            size: CGSize(width: 820, height: 470),
            noiseLevel: noiseLevel,
            baseColor: textureBaseMaterial.uiColor,
            speckleColor: speckleColor
        )
    }

    private func generateObject() {
        displayFabricatedAlert()
        BackgroundMusicPlayer.shared.playSoundEffect("fabricateClick")
        guard electricity > 0 else { return }
        electricity -= 1
        generatedTexture = previewTexture
        isGenerated = true
        isFabricated = true
        potentialSellingPrice = calculateSellingPrice()
        lastSavedMaterialSupplies = materialSupplies
        lastSavedFiberglass = fiberglass
        lastSavedElectricity = electricity
    }

    private func sellObject() {
        displaySoldAlert()
        BackgroundMusicPlayer.shared.playSoundEffect("sellClick")
        let isCorrect = isCorrectSale()
        dailySalesCount += 1
        if isCorrect {
            totalCorrectSales += 1
        }

        let basePrice = potentialSellingPrice
        let bonus = customerSatisfactionRating * 10
        let totalEarnings = basePrice + bonus

        money += totalEarnings
        dailyProfit += totalEarnings
        potentialSellingPrice = 0
        generatedTexture = nil
        previewTexture = nil
        materialCounts = [:]
        totalClicks = 0
        isGenerated = false
        firstClickedMaterial = nil
        generateColumns()
        isFabricated = false
    }

    private func calculateSellingPrice() -> Int {
        var reward = 0

        let baseColor = colorName(for: baseMaterial).lowercased()
        if baseColor == column1.lowercased() {
            reward += 50
        }

        var accentCounts = materialCounts
        accentCounts[baseMaterial.name] = 0
        if let accentMaterialName = accentCounts.max(by: { $0.value < $1.value })?.key,
           let accentMaterial = Material.all.first(where: { $0.name == accentMaterialName }),
           colorName(for: accentMaterial).lowercased() == column3.lowercased() {
            reward += 20
        }

        let baseCount = materialCounts[baseMaterial.name, default: 0]
        let speckleClicks = totalClicks - baseCount
        let intensityLevel = getIntensityLevel(speckleClicks)

        if intensityLevel == column2.lowercased() {
            reward += 10
        }

        let modelCategory = modelDisplayName(for: selectedModel)
        if modelCategory == column4 {
            switch modelCategory {
            case "Chair": reward += 50
            case "Cabinet": reward += 100
            case "Desk": reward += 150
            default: break
            }
        }

        return reward
    }

    private func isCorrectSale() -> Bool {
        let baseMatch = colorName(for: baseMaterial).lowercased() == column1.lowercased()

        let accentMatch: Bool = {
            var accentCounts = materialCounts
            accentCounts[baseMaterial.name] = 0
            guard let accentMaterialName = accentCounts.max(by: { $0.value < $1.value })?.key,
                  let accentMaterial = Material.all.first(where: { $0.name == accentMaterialName }) else {
                return false
            }
            return colorName(for: accentMaterial).lowercased() == column3.lowercased()
        }()

        let intensityMatch = getIntensityLevel(totalClicks - materialCounts[baseMaterial.name, default: 0]) == column2.lowercased()
        let modelMatch = modelDisplayName(for: selectedModel) == column4

        return baseMatch && accentMatch && intensityMatch && modelMatch
    }

    private func getIntensityLevel(_ speckleClicks: Int) -> String {
        switch speckleClicks {
        case 1: return "hint of"
        case 2: return "touch of"
        case 3: return "moderate"
        case 4: return "strong"
        default: return "rich of"
        }
    }

    private func calculateSatisfactionRating() {
        let volumeScore = min(dailySalesCount / 2, 3)
        let accuracy = dailySalesCount > 0 ? Double(totalCorrectSales) / Double(dailySalesCount) : 0
        let accuracyScore = Int(round(accuracy * 2))

        let rawRating = volumeScore + accuracyScore
        customerSatisfactionRating = min(max(rawRating, 1), 5)
        satisfactionBonus = customerSatisfactionRating * 10
    }

    private func colorName(for material: Material) -> String {
        switch material.name {
        case "Cans": return "green"
        case "Wrap": return "yellow"
        case "Cups": return "pink"
        case "Mask": return "blue"
        case "Sack": return "purple"
        default: return ""
        }
    }

    private func resetAll() {
        BackgroundMusicPlayer.shared.playSoundEffect("resetClick")
        materialCounts = [:]
        totalClicks = 0
        isGenerated = false
        generatedTexture = nil
        previewTexture = nil
        materialSupplies = lastSavedMaterialSupplies
        fiberglass = lastSavedFiberglass
        electricity = lastSavedElectricity
        firstClickedMaterial = nil
        isFabricated = false
    }

    private func handleReplenishElectricity() {
        let maxElectricity = 100
        let amountToAdd = min(10, maxElectricity - electricity)
        BackgroundMusicPlayer.shared.playSoundEffect("resetClick")
        guard money >= 15,
              amountToAdd > 0
        else { return }

        money -= 15
        electricity += amountToAdd
        lastSavedElectricity = electricity
    }

    private func handleReplenishMaterial(_ material: Material) {
        let currentSupply = materialSupplies[material, default: 0]
        BackgroundMusicPlayer.shared.playSoundEffect("resetClick")
        guard money >= 10,
              globalSupply.amount >= 10,
              currentSupply < 100
        else { return }

        let availableSpace = 100 - currentSupply
        let amountToAdd = min(10, availableSpace)

        money -= 10
        globalSupply.amount -= 10
        materialSupplies[material] = currentSupply + amountToAdd
        dailyMaterialPurchases += amountToAdd
        lastSavedMaterialSupplies = materialSupplies
    }

    private func handleReplenishFiberglass() {
        let maxFiberglass = 100
        let amountToAdd = min(10, maxFiberglass - fiberglass)
        BackgroundMusicPlayer.shared.playSoundEffect("resetClick")
        guard money >= 20,
              amountToAdd > 0
        else { return }

        money -= 20
        fiberglass += amountToAdd
        lastSavedFiberglass = fiberglass
    }
}
    
struct IntroductionView: View {
    let currentDialog: String
    let progress: Double
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                Spacer()
                Spacer()
                HStack{
                    Spacer()
                    Button(action: onContinue) {
                        Text(progress == 1.0 ? "Start Game" : "Continue")
                            .font(Font(CustomFonts.custom1.font1(size: 35)))
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.trailing, 60)
                Image("ConversationBox")
                    .overlay(
                        Text(currentDialog)
                            .font(Font(CustomFonts.custom1.font1(size: 45)))
                            .foregroundColor(.black)
                            .padding(40)
                            .multilineTextAlignment(.center),
                        alignment: .center
                    )
                
                
            
                .padding(.bottom, 80)
                
              
            }
        }
        .onTapGesture {
            onContinue()
            BackgroundMusicPlayer.shared.playSoundEffect("confirmClick")
        }
    }
}
                                  

struct ConversationBox: View {
    let isGenerated: Bool
    let column1: String
    let column2: String
    let column3: String
    let column4: String
    let sellingPrice: Int
    @ObservedObject var gameTime: GameTime

    var body: some View {
        Text(message)
            .foregroundColor(.black)
            .padding()
            .frame(width: 300)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .font(Font(CustomFonts.custom1.font1(size: 20)))
            .opacity(gameTime.isWorkingHours ? 1 : 0)
            .animation(.easeInOut, value: gameTime.isWorkingHours)
    }

    private var message: String {
        if !gameTime.isWorkingHours {
            return ""
        }
        return isGenerated ?
            "I would buy for $\(sellingPrice), deal?" :
            "I'm interested in a \(column4) with \(column1) base, \(column2) \(column3) accent. Can you make this?"
    }
}

struct SatisfactionRatingView: View {
    @Environment(\.dismiss) private var dismiss
    let rating: Int
    let bonus: Int
    let soldItems: Int
    let profit: Int
    let materialsBought: Int

    var body: some View {
        VStack(spacing: 20) {
            Text("Daily Report")
                .foregroundColor(.black)
                .font(Font(CustomFonts.custom1.font1(size: 60)))
            VStack {
                Text("Customer Satisfaction")
                    .foregroundColor(.black)
                    .font(Font(CustomFonts.custom1.font1(size: 30)))
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(.black)
                            .font(.system(size: 30))
                    }
                }
            }
            .padding(.bottom)

            VStack(spacing: 15) {
                StatItem(icon: "📦", title: "Items Sold", value: "\(soldItems)")
                StatItem(icon: "💰", title: "Total Profit", value: "$\(profit)")
                StatItem(icon: "🛒", title: "Materials Bought", value: "\(materialsBought) units")
                StatItem(icon: "🎯", title: "Accuracy", value: "\(accuracyPercentage)%")
                StatItem(icon: "⭐️", title: "Bonus Rate", value: "+\(bonus)/sale")
            }

            Button("Continue") {
                BackgroundMusicPlayer.shared.playSoundEffect("pageChanging")
                dismiss()
            }
                .buttonStyle(PrimaryButtonStyle())
            
        }
        .padding()
        .background(Color(red: 1.0, green: 0.95, blue: 0.7))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(red: 0.4, green: 0.2, blue: 0.1), lineWidth: 2)
        )
        .shadow(radius: 10)
        .contentShape(Rectangle())
        .onTapGesture {
            BackgroundMusicPlayer.shared.playSoundEffect("pageChanging")
            dismiss()
        }
        .padding(20)
        .background(Color(red: 0.4, green: 0.2, blue: 0.1).edgesIgnoringSafeArea(.all))
        .onAppear {
         
            BackgroundMusicPlayer.shared.playSoundEffect("dailyReport")
        }
    }

    private var accuracyPercentage: Int {
        guard soldItems > 0 else { return 0 }
        return Int(Double(rating - min(rating, 3)) / 2 * 50)
    }
}

struct StatItem: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(icon)
                .font(.title)
                .foregroundColor(.black)
            VStack(alignment: .leading) {
                Text(title)
                    .font(Font(CustomFonts.custom1.font1(size: 20)))
                    .foregroundColor(.black)
                Text(value)
                    .font(Font(CustomFonts.custom1.font1(size: 20)))
                    .foregroundColor(.black)
            }
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}



struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .font(Font(CustomFonts.custom1.font1(size: 25)))
    }
}

struct PreviewWindow: View {
    let previewTexture: UIImage?

    var body: some View {
        ZStack {
            Color.gray.opacity(0.1)
                .cornerRadius(12)
            if let texture = previewTexture {
                Image(uiImage: texture)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 265, height: 200)
            } else {
                Text("Select materials to preview")
                    .foregroundColor(.black)
                    .font(Font(CustomFonts.custom1.font1(size: 35)))
            }
        }
        .position(x: 172, y: 257)
        .padding()
    }
}

struct MaterialsGrid: View {
    @Binding var materialCounts: [String: Int]
    @Binding var materialSupplies: [Material: Int]
    let isGenerated: Bool
    let selectedMaterialsCount: Int
    @Binding var firstClickedMaterial: Material?
    let handleMaterialTap: (Material) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: -25) {
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            Spacer()
            ForEach(Material.all) { material in
                Button {
                    BackgroundMusicPlayer.shared.playSoundEffect("materialClick")
                    handleMaterialTap(material)
                } label: {
                    MaterialButtonView(
                        material: material,
                        count: materialCounts[material.name, default: 0],
                        supply: materialSupplies[material, default: 0],
                        disabled: isGenerated ||
                                  (materialCounts[material.name, default: 0] == 0 && selectedMaterialsCount >= 2) ||
                                  material == firstClickedMaterial
                    )
                }
                .disabled(isGenerated ||
                          (materialCounts[material.name, default: 0] == 0 && selectedMaterialsCount >= 2) ||
                          material == firstClickedMaterial)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct MaterialButtonView: View {
    let material: Material
    let count: Int
    let supply: Int
    let disabled: Bool

    private func getImageName(for material: Material) -> String {
        switch material.name {
        case "Cans": return "Cans"
        case "Wrap": return "Wrap"
        case "Cups": return "Cups"
        case "Mask": return "Mask"
        case "Sack": return "Sack"
        default: return ""
        }
    }

    var body: some View {
        ZStack{
            HStack(spacing: 8) {
                ZStack {
                    Image(getImageName(for: material))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 145, height: 90)
                        .grayscale(disabled ? 1 : 0)
                    HStack{
                        ZStack{

                            VStack {
                                Text("\(count)")
                                    .foregroundColor(.black)
                                    .font(.system(size: 20, weight: .bold))
                                Text("\(supply)")
                                    .foregroundColor(.black)
                                    .font(.system(size: 12))
                            }
                        }
                    }
                    .padding(.leading,85)
                }
            }
            .padding(5)
        }
    }
}

struct SelectionCounter: View {
    let totalClicks: Int
    let maxTotalClicks: Int

    var body: some View {
        VStack {
            Text("Selections: \(totalClicks)/\(maxTotalClicks)")
                .font(Font(CustomFonts.custom1.font1(size: 20)))
                .foregroundColor(.black)
        }
        .padding()
    }
}

struct ObjectWindow: View {
    let generatedTexture: UIImage?
    let modelName: String

    var body: some View {
        ZStack {
            if let texture = generatedTexture {
                Model3DView(textureImage: texture, modelName: modelName)
                    .frame(width: 410, height: 400)
            } else {
                Text("Fabricate to see object")
                    .frame(width: 420, height: 420)
                    .font(Font(CustomFonts.custom1.font1(size: 35)))
                    .foregroundColor(.black)
            }
        }
        .padding()
        .padding(.trailing, 10)
        .padding(.bottom, 40)

        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ActionButtons: View {
    let isGenerated: Bool
    let totalClicks: Int
    let gameTime: GameTime
    @Binding var money: Int
    let electricity: Int
    let isFabricated: Bool
    let generateObject: () -> Void
    let sellObject: () -> Void
    let resetAll: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: isGenerated ? sellObject : generateObject) {
                Image(isGenerated ? "Sell" : "fabricate")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 125, height: 60)
                    .grayscale(isGenerated ? 0 : (totalClicks > 0 && electricity > 0) ? 0 : 1)
            }
            .disabled(isGenerated ? false : (totalClicks == 0 || !gameTime.isWorkingHours || electricity <= 0))

            Button(action: resetAll) {
                Image("Reset")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 125, height: 60)
            }
        }
    }
}

struct ActionButtonLabel: View {
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(label)
        }
        .padding(.top,20)
        .padding(.bottom,20)
        .frame(width: 125)
        .background(color)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}

struct FinancialInfo: View {
    let money: Int
    let globalSupply: Int
    @Binding var electricity: Int
    @Binding var fiberglass: Int
    let customerSatisfactionRating: Int
    var showShop: () -> Void

    var body: some View {
        HStack(spacing: -10) {

            ResourceIndicator(
                icon: "",
                label: "Energy",
                current: electricity,
                max: 100,
                color: .yellow
            )
            ResourceIndicator(
                icon: "",
                label: "     Catalyst",
                current: fiberglass,
                max: 100,
                color: .blue
            )

        }
        .padding()
    }
}

struct ResourceIndicator: View {
    let icon: String
    let label: String
    let current: Int
    let max: Int
    let color: Color

    var body: some View {
        HStack {
            Text(icon)
            Text("\(label): \(current)/\(max)")
                .font(Font(CustomFonts.custom1.font1(size: 20)))
                .foregroundColor(.black)
        }
    }
}

struct ShopView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var electricity: Int
    @Binding var fiberglass: Int
    @Binding var money: Int
    @Binding var materialSupplies: [Material: Int]
    @Binding var globalSupply: Int

    let handleReplenishElectricity: () -> Void
    let handleReplenishFiberglass: () -> Void
    let handleReplenishMaterial: (Material) -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("⚡️ Workshop Store")
                    .font(Font(CustomFonts.custom1.font1(size: 50)))
                    .foregroundColor(.black)
                Spacer()
                Button(action: {
                    BackgroundMusicPlayer.shared.playSoundEffect("pageChanging")
                    dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)

            ScrollView {
                VStack(spacing: 25) {
                    VStack(alignment: .leading) {
                        SectionHeader(title: "Raw Materials", icon: "cube.box")
                        ForEach(Material.all) { material in
                            HStack {
                                MaterialShopRow(
                                    name: material.name,
                                    color: material.color,
                                    current: materialSupplies[material, default: 0],
                                    price: 10,
                                    max: 100
                                )
                                Spacer()
                                PurchaseButton(
                                    action: {
                                        handleReplenishMaterial(material) },
                                    disabled: !canPurchaseMaterial(material),
                                    label: "+10"
                                )
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    VStack(alignment: .leading) {
                        SectionHeader(title: "Power Supplies", icon: "bolt.fill")
                        HStack {
                            ResourceShopRow(
                                icon: "bolt.fill",
                                name: "Energy",
                                current: electricity,
                                max: 100,
                                price: 15,
                                unit: "units"
                            )
                            Spacer()
                            PurchaseButton(
                                action: handleReplenishElectricity,
                                disabled: money < 15 || electricity >= 100,
                                label: "+10"
                            )
                        }
                        .padding(.vertical, 4)
                        HStack {
                            ResourceShopRow(
                                icon: "circle.dashed",
                                name: "Catalyst",
                                current: fiberglass,
                                max: 100,
                                price: 20,
                                unit: "units"
                            )
                            Spacer()
                            PurchaseButton(
                                action: handleReplenishFiberglass,
                                disabled: money < 20 || fiberglass >= 100,
                                label: "+10"
                            )
                        }
                        .padding(.vertical, 4)
                    }

                    VStack(alignment: .leading) {
                        SectionHeader(title: "Capacity Upgrades", icon: "chart.bar.fill")
                        UpgradeButton(
                            title: "⚡ Energy Vault",
                            cost: 3000,
                            description: "Increase electricity capacity to 150 units",
                            progress: 0.0,
                            color: .yellow
                        )
                        UpgradeButton(
                            title: "🧊 Fiberglass Silo",
                            cost: 3000,
                            description: "Expand fiberglass storage to 150 units",
                            progress: 0.0,
                            color: .blue
                        )
                        UpgradeButton(
                            title: "📦 Material Matrix",
                            cost: 3000,
                            description: "Enhance material container to 150 units",
                            progress: 0.0,
                            color: .green
                        )
                    }

                    VStack(alignment: .leading) {
                        SectionHeader(title: "Factory Upgrades", icon: "gear")
                        UpgradeButton(
                            title: "🤖 Mega Combiner",
                            cost: 100_000,
                            description: "Increase maximum combinations by 50%",
                            progress: 0.0,
                            color: .purple
                        )
                        UpgradeButton(
                            title: "🎨 Exotic Materials",
                            cost: 200_000,
                            description: "Unlock 3 new rare materials",
                            progress: 0.0,
                            color: .pink
                        )
                        UpgradeButton(
                            title: "🏗️ Advanced Fabricator",
                            cost: 300_000,
                            description: "Unlock 5 new production models",
                            progress: 0.0,
                            color: .orange
                        )
                    }
                }
                .padding()
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Landfill supply:")
                        .font(Font(CustomFonts.custom1.font1(size: 20)))
                        .foregroundColor(.black)
                    Text("\(globalSupply)")
                        .font(Font(CustomFonts.custom1.font1(size: 20)))
                        .foregroundColor(.black)
                    Spacer()
                    Text("Balance:")
                        .font(Font(CustomFonts.custom1.font1(size: 20)))
                        .foregroundColor(.black)
                    Text("$\(money)")
                        .font(Font(CustomFonts.custom1.font1(size: 20)))
                        .foregroundColor(.black)
                }
                .font(.footnote)
                ProgressView(value: Double(money), total: 300_000)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .padding(.vertical)
            .background(Color(red: 1.0, green: 0.95, blue: 0.7))
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.5), .purple.opacity(0.5)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: .gray.opacity(0.2), radius: 10, x: 0, y: 5)
            .padding(20)
            .background(
                Color(red: 0.4, green: 0.2, blue: 0.1)
                    .edgesIgnoringSafeArea(.all)
            )
    }

    private func canPurchaseMaterial(_ material: Material) -> Bool {
        let currentSupply = materialSupplies[material, default: 0]
        return money >= 10 &&
               globalSupply >= 10 &&
               currentSupply < 100
    }
}

struct UpgradeButton: View {
    let title: String
    let cost: Int
    let description: String
    let progress: Double
    let color: Color

    var body: some View {
        Button(action: {}) {
            HStack(alignment: .center, spacing: 15) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 45, height: 45)
                    Text(title.prefix(2))
                        .font(Font(CustomFonts.custom1.font1(size: 20)))
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(Font(CustomFonts.custom1.font1(size: 20)))
                            .foregroundColor(.black)

                        Spacer()
                        Text("$\(cost)")
                            .font(Font(CustomFonts.custom1.font1(size: 20)))
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(color.opacity(0.2))
                            .cornerRadius(6)
                    }
                    Text(description)
                        .font(Font(CustomFonts.custom1.font1(size: 20)))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                    ProgressView(value: progress)
                        .tint(color)
                        .padding(.top, 4)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .opacity(progress >= 1.0 ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(true)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .font(Font(CustomFonts.custom1.font1(size: 35)))
            Spacer()
        }
        .padding(.vertical)
        .foregroundColor(.blue)
    }
}

struct MaterialShopRow: View {
    let name: String
    let color: Color
    let current: Int
    let price: Int
    let max: Int

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
            VStack(alignment: .leading) {
                Text(name)
                    .font(Font(CustomFonts.custom1.font1(size: 25)))
                    .foregroundColor(.black)
                Text("\(current)/\(max)")
                    .font(Font(CustomFonts.custom1.font1(size: 20)))
                    .foregroundColor(.black)
            }
            .frame(width: 120, alignment: .leading)
            Text("$\(price)")
                .font(Font(CustomFonts.custom1.font1(size: 25)))
                .foregroundColor(.black)
                .frame(width: 60)
        }
    }
}

struct ResourceShopRow: View {
    let icon: String
    let name: String
    let current: Int
    let max: Int
    let price: Int
    let unit: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.black)
                .frame(width: 30)
            VStack(alignment: .leading) {
                Text(name)
                    .font(Font(CustomFonts.custom1.font1(size: 25)))
                    .foregroundColor(.black)
                Text("\(current)/\(max) \(unit)")
                    .font(Font(CustomFonts.custom1.font1(size: 25)))
                    .foregroundColor(.black)
            }
            .frame(width: 120, alignment: .leading)
            Text("$\(price)")
                .frame(width: 60)
                .font(Font(CustomFonts.custom1.font1(size: 25)))
                .foregroundColor(.black)
        }
    }
}

struct PurchaseButton: View {
    let action: () -> Void
    let disabled: Bool
    let label: String

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Font(CustomFonts.custom1.font1(size: 20)))
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(disabled ? Color.gray : Color.black)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .disabled(disabled)
    }
}

struct Model3DView: View {
    let textureImage: UIImage
    let modelName: String
    @StateObject private var coordinator: SceneCoordinator

    init(textureImage: UIImage, modelName: String) {
        self.textureImage = textureImage
        self.modelName = modelName
        _coordinator = StateObject(wrappedValue: SceneCoordinator(modelName: modelName))
    }

    var body: some View {
        SceneView(scene: coordinator.scene, options: [.allowsCameraControl])
            .onAppear { coordinator.updateTexture(textureImage) }
    }
}

extension View {
    func hidden(_ shouldHide: Bool) -> some View {
        opacity(shouldHide ? 0 : 1)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
