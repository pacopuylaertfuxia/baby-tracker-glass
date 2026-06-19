import SwiftUI

// MARK: - Adaptive color system (Light + Dark)

extension Color {
    // Core palette — adaptive
    static let moonClay = Color("moonClay")
    static let moonOlive = Color("moonOlive")
    static let moonCreme = Color("moonCreme")
    static let moonApricot = Color("moonApricot")
    static let moonStone = Color("moonStone")
    static let moonWhite = Color("moonWhite")
    static let moonBlack = Color("moonBlack")
    static let moonObsidian = Color("moonObsidian")

    // Feedback
    static let moonSuccess = Color("moonSuccess")
    static let moonError = Color(red: 185/255, green: 74/255, blue: 72/255)
    static let moonInfo = Color(red: 74/255, green: 106/255, blue: 133/255)

    // Timeline event colors
    static let moonSleep = Color(red: 74/255, green: 106/255, blue: 133/255)
    static let moonWake = Color(red: 255/255, green: 203/255, blue: 79/255)
    static let moonFood = Color(red: 138/255, green: 170/255, blue: 104/255)
    static let moonChange = Color(red: 168/255, green: 198/255, blue: 134/255)

    // Surfaces — for card/overlay backgrounds
    static let moonCardBg = Color("moonCardBg")
    static let moonOverlay = Color("moonOverlay")
}

extension ShapeStyle where Self == Color {
    static var moonClay: Color { .moonClay }
    static var moonOlive: Color { .moonOlive }
    static var moonCreme: Color { .moonCreme }
    static var moonApricot: Color { .moonApricot }
    static var moonStone: Color { .moonStone }
    static var moonWhite: Color { .moonWhite }
    static var moonBlack: Color { .moonBlack }
    static var moonObsidian: Color { .moonObsidian }
    static var moonSuccess: Color { .moonSuccess }
    static var moonError: Color { .moonError }
    static var moonInfo: Color { .moonInfo }
    static var moonSleep: Color { .moonSleep }
    static var moonWake: Color { .moonWake }
    static var moonFood: Color { .moonFood }
    static var moonChange: Color { .moonChange }
    static var moonCardBg: Color { .moonCardBg }
    static var moonOverlay: Color { .moonOverlay }
}
