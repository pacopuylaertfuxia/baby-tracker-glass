import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

    /// The "moonApricot" asset catalog color resource.
    static let moonApricot = DeveloperToolsSupport.ColorResource(name: "moonApricot", bundle: resourceBundle)

    /// The "moonBlack" asset catalog color resource.
    static let moonBlack = DeveloperToolsSupport.ColorResource(name: "moonBlack", bundle: resourceBundle)

    /// The "moonCardBg" asset catalog color resource.
    static let moonCardBg = DeveloperToolsSupport.ColorResource(name: "moonCardBg", bundle: resourceBundle)

    /// The "moonClay" asset catalog color resource.
    static let moonClay = DeveloperToolsSupport.ColorResource(name: "moonClay", bundle: resourceBundle)

    /// The "moonCreme" asset catalog color resource.
    static let moonCreme = DeveloperToolsSupport.ColorResource(name: "moonCreme", bundle: resourceBundle)

    /// The "moonObsidian" asset catalog color resource.
    static let moonObsidian = DeveloperToolsSupport.ColorResource(name: "moonObsidian", bundle: resourceBundle)

    /// The "moonOlive" asset catalog color resource.
    static let moonOlive = DeveloperToolsSupport.ColorResource(name: "moonOlive", bundle: resourceBundle)

    /// The "moonOverlay" asset catalog color resource.
    static let moonOverlay = DeveloperToolsSupport.ColorResource(name: "moonOverlay", bundle: resourceBundle)

    /// The "moonStone" asset catalog color resource.
    static let moonStone = DeveloperToolsSupport.ColorResource(name: "moonStone", bundle: resourceBundle)

    /// The "moonSuccess" asset catalog color resource.
    static let moonSuccess = DeveloperToolsSupport.ColorResource(name: "moonSuccess", bundle: resourceBundle)

    /// The "moonWhite" asset catalog color resource.
    static let moonWhite = DeveloperToolsSupport.ColorResource(name: "moonWhite", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "baby_avatar" asset catalog image resource.
    static let babyAvatar = DeveloperToolsSupport.ImageResource(name: "baby_avatar", bundle: resourceBundle)

    /// The "icon_bedtime" asset catalog image resource.
    static let iconBedtime = DeveloperToolsSupport.ImageResource(name: "icon_bedtime", bundle: resourceBundle)

    /// The "icon_diaper" asset catalog image resource.
    static let iconDiaper = DeveloperToolsSupport.ImageResource(name: "icon_diaper", bundle: resourceBundle)

    /// The "icon_feed" asset catalog image resource.
    static let iconFeed = DeveloperToolsSupport.ImageResource(name: "icon_feed", bundle: resourceBundle)

    /// The "icon_medicine" asset catalog image resource.
    static let iconMedicine = DeveloperToolsSupport.ImageResource(name: "icon_medicine", bundle: resourceBundle)

    /// The "icon_moon" asset catalog image resource.
    static let iconMoon = DeveloperToolsSupport.ImageResource(name: "icon_moon", bundle: resourceBundle)

    /// The "icon_nap" asset catalog image resource.
    static let iconNap = DeveloperToolsSupport.ImageResource(name: "icon_nap", bundle: resourceBundle)

    /// The "icon_night_waking" asset catalog image resource.
    static let iconNightWaking = DeveloperToolsSupport.ImageResource(name: "icon_night_waking", bundle: resourceBundle)

    /// The "icon_nursing" asset catalog image resource.
    static let iconNursing = DeveloperToolsSupport.ImageResource(name: "icon_nursing", bundle: resourceBundle)

    /// The "icon_pumping" asset catalog image resource.
    static let iconPumping = DeveloperToolsSupport.ImageResource(name: "icon_pumping", bundle: resourceBundle)

    /// The "icon_solids" asset catalog image resource.
    static let iconSolids = DeveloperToolsSupport.ImageResource(name: "icon_solids", bundle: resourceBundle)

    /// The "icon_sun" asset catalog image resource.
    static let iconSun = DeveloperToolsSupport.ImageResource(name: "icon_sun", bundle: resourceBundle)

    /// The "icon_temperature" asset catalog image resource.
    static let iconTemperature = DeveloperToolsSupport.ImageResource(name: "icon_temperature", bundle: resourceBundle)

    /// The "session_monitor" asset catalog image resource.
    static let sessionMonitor = DeveloperToolsSupport.ImageResource(name: "session_monitor", bundle: resourceBundle)

    /// The "session_motor" asset catalog image resource.
    static let sessionMotor = DeveloperToolsSupport.ImageResource(name: "session_motor", bundle: resourceBundle)

}

