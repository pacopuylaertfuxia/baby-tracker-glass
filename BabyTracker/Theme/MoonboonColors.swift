import SwiftUI

extension Color {
    // Core palette
    static let moonClay = Color(red: 181/255, green: 158/255, blue: 133/255)
    static let moonOlive = Color(red: 112/255, green: 105/255, blue: 95/255)
    static let moonCreme = Color(red: 241/255, green: 232/255, blue: 222/255)
    static let moonApricot = Color(red: 229/255, green: 213/255, blue: 197/255)
    static let moonStone = Color(red: 221/255, green: 214/255, blue: 204/255)
    static let moonWhite = Color(red: 255/255, green: 254/255, blue: 251/255)
    static let moonBlack = Color(red: 1/255, green: 1/255, blue: 1/255)
    static let moonObsidian = Color(red: 70/255, green: 69/255, blue: 69/255)

    // Feedback
    static let moonSuccess = Color(red: 94/255, green: 138/255, blue: 102/255)
    static let moonError = Color(red: 185/255, green: 74/255, blue: 72/255)
    static let moonInfo = Color(red: 74/255, green: 106/255, blue: 133/255)

    // Timeline event colors (from Figma vision)
    static let moonSleep = Color(red: 74/255, green: 106/255, blue: 133/255)     // #4A6A85 blue
    static let moonWake = Color(red: 255/255, green: 203/255, blue: 79/255)       // #FFCB4F warm gold
    static let moonFood = Color(red: 138/255, green: 170/255, blue: 104/255)      // soft green
    static let moonChange = Color(red: 168/255, green: 198/255, blue: 134/255)    // light green
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
}
