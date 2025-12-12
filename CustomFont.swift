//
//  CustomFont.swift
//  Upcycled 2045
//
//  Created by Rivian Pratama on 23/02/25
//

import Foundation
import UIKit
import SwiftUI

struct CustomFonts {
    private init() {
        if let fontURL = Bundle.main.url(forResource: "VT323-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, CTFontManagerScope.process, nil)
        } else {
            print("Failed to find test in the bundle.")
        }
    }
    
    static let custom1 = CustomFonts()
    
    func font1(size: CGFloat) -> UIFont {
        if let font = UIFont(name: "VT323-Regular", size: size) {
            return font
        } else {
            return UIFont.systemFont(ofSize: size)
        }
    }
}

struct CustomFonts2 {
    private init() {
        if let fontURL = Bundle.main.url(forResource: "Trispace-Bold", withExtension: "otf") {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, CTFontManagerScope.process, nil)
        } else {
            print("Failed to find Trispace-Bold.otf in the bundle.")
        }
    }
    
    static let custom2 = CustomFonts2()
    
    func font2(size: CGFloat) -> UIFont {
        if let font = UIFont(name: "Trispace-Bold", size: size) {
            return font
        } else {
            return UIFont.boldSystemFont(ofSize: size)
        }
    }
}

struct CustomFonts3 {
    private init() {
        if let fontURL = Bundle.main.url(forResource: "Jua-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, CTFontManagerScope.process, nil)
        } else {
            print("Failed to find Jua-Regular.ttf in the bundle.")
        }
    }
    
    static let custom3 = CustomFonts3()
    
    func font3(size: CGFloat) -> UIFont {
        if let font = UIFont(name: "Jua-Regular", size: size) {
            return font
        } else {
            return UIFont.boldSystemFont(ofSize: size)
        }
    }
}
