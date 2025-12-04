//
//  EnvironmentPreference.swift
//  InkFiction
//
//  Environment settings for avatar generation (background, lighting, style)
//

import Foundation
import SwiftUI

// MARK: - EnvironmentPreference

struct EnvironmentPreference: Codable, Equatable {
    var setting: EnvironmentSetting
    var lightingStyle: LightingStyle
    var timeOfDay: AvatarTimeOfDay
    var weather: Weather
    var season: Season
    var colorPalette: ColorPalette
    var backgroundStyle: BackgroundStyle
    var cameraAngle: CameraAngle

    init(
        setting: EnvironmentSetting = .studioPortrait,
        lightingStyle: LightingStyle = .softNatural,
        timeOfDay: AvatarTimeOfDay = .daylight,
        weather: Weather = .clear,
        season: Season = .neutral,
        colorPalette: ColorPalette = .natural,
        backgroundStyle: BackgroundStyle = .solidColor,
        cameraAngle: CameraAngle = .straightOn
    ) {
        self.setting = setting
        self.lightingStyle = lightingStyle
        self.timeOfDay = timeOfDay
        self.weather = weather
        self.season = season
        self.colorPalette = colorPalette
        self.backgroundStyle = backgroundStyle
        self.cameraAngle = cameraAngle
    }

    var description: String {
        [
            setting.promptDescription,
            lightingStyle.promptDescription,
            timeOfDay.promptDescription,
            backgroundStyle.promptDescription,
        ].joined(separator: ", ")
    }
}

// MARK: - Environment Setting

enum EnvironmentSetting: String, Codable, CaseIterable {
    case studioPortrait = "studio_portrait"
    case naturalOutdoor = "natural_outdoor"
    case urbanStreet = "urban_street"
    case cozyIndoor = "cozy_indoor"
    case minimalistStudio = "minimalist_studio"
    case dreamy = "dreamy"
    case abstract = "abstract"

    var displayName: String {
        switch self {
        case .studioPortrait: return "Studio Portrait"
        case .naturalOutdoor: return "Natural Outdoor"
        case .urbanStreet: return "Urban Street"
        case .cozyIndoor: return "Cozy Indoor"
        case .minimalistStudio: return "Minimalist Studio"
        case .dreamy: return "Dreamy"
        case .abstract: return "Abstract"
        }
    }

    var promptDescription: String {
        switch self {
        case .studioPortrait: return "professional studio portrait background"
        case .naturalOutdoor: return "natural outdoor setting, nature background"
        case .urbanStreet: return "urban street scene, city background"
        case .cozyIndoor: return "cozy indoor setting, warm interior"
        case .minimalistStudio: return "minimalist white studio background"
        case .dreamy: return "dreamy ethereal background, soft bokeh"
        case .abstract: return "abstract artistic background"
        }
    }

    var icon: String {
        switch self {
        case .studioPortrait: return "camera.aperture"
        case .naturalOutdoor: return "leaf.fill"
        case .urbanStreet: return "building.2.fill"
        case .cozyIndoor: return "house.fill"
        case .minimalistStudio: return "square.fill"
        case .dreamy: return "sparkles"
        case .abstract: return "scribble.variable"
        }
    }
}

// MARK: - Lighting Style

enum LightingStyle: String, Codable, CaseIterable {
    case softNatural = "soft_natural"
    case goldenHour = "golden_hour"
    case dramatic = "dramatic"
    case highKey = "high_key"
    case lowKey = "low_key"
    case neon = "neon"
    case candlelight = "candlelight"
    case backlit = "backlit"

    var displayName: String {
        switch self {
        case .softNatural: return "Soft Natural"
        case .goldenHour: return "Golden Hour"
        case .dramatic: return "Dramatic"
        case .highKey: return "High Key"
        case .lowKey: return "Low Key"
        case .neon: return "Neon"
        case .candlelight: return "Candlelight"
        case .backlit: return "Backlit"
        }
    }

    var promptDescription: String {
        switch self {
        case .softNatural: return "soft natural lighting"
        case .goldenHour: return "golden hour warm lighting"
        case .dramatic: return "dramatic cinematic lighting"
        case .highKey: return "bright high key lighting"
        case .lowKey: return "moody low key lighting"
        case .neon: return "colorful neon lighting"
        case .candlelight: return "warm candlelight glow"
        case .backlit: return "beautiful backlit silhouette"
        }
    }
}

// MARK: - Avatar Time of Day

enum AvatarTimeOfDay: String, Codable, CaseIterable {
    case dawn
    case morning
    case daylight
    case afternoon
    case goldenHour = "golden_hour"
    case dusk
    case night
    case bluehour = "blue_hour"

    var displayName: String {
        switch self {
        case .dawn: return "Dawn"
        case .morning: return "Morning"
        case .daylight: return "Daylight"
        case .afternoon: return "Afternoon"
        case .goldenHour: return "Golden Hour"
        case .dusk: return "Dusk"
        case .night: return "Night"
        case .bluehour: return "Blue Hour"
        }
    }

    var promptDescription: String {
        switch self {
        case .dawn: return "early dawn light"
        case .morning: return "fresh morning light"
        case .daylight: return "bright daylight"
        case .afternoon: return "warm afternoon sun"
        case .goldenHour: return "golden hour sunlight"
        case .dusk: return "dusk twilight"
        case .night: return "night atmosphere"
        case .bluehour: return "blue hour ambient light"
        }
    }
}

// MARK: - Weather

enum Weather: String, Codable, CaseIterable {
    case clear
    case cloudy
    case rainy
    case snowy
    case foggy
    case stormy

    var displayName: String {
        rawValue.capitalized
    }

    var promptDescription: String {
        switch self {
        case .clear: return "clear weather"
        case .cloudy: return "soft cloudy sky"
        case .rainy: return "rainy atmosphere"
        case .snowy: return "snowy winter scene"
        case .foggy: return "mysterious foggy atmosphere"
        case .stormy: return "dramatic stormy sky"
        }
    }
}

// MARK: - Season

enum Season: String, Codable, CaseIterable {
    case spring
    case summer
    case autumn
    case winter
    case neutral

    var displayName: String {
        rawValue.capitalized
    }

    var promptDescription: String {
        switch self {
        case .spring: return "spring atmosphere, fresh greenery"
        case .summer: return "summer vibes, warm weather"
        case .autumn: return "autumn colors, fall foliage"
        case .winter: return "winter scene, cold atmosphere"
        case .neutral: return ""
        }
    }
}

// MARK: - Color Palette

enum ColorPalette: String, Codable, CaseIterable {
    case natural
    case warm
    case cool
    case vibrant
    case pastel
    case monochrome
    case vintage
    case neon

    var displayName: String {
        rawValue.capitalized
    }

    var promptDescription: String {
        switch self {
        case .natural: return "natural color palette"
        case .warm: return "warm color tones"
        case .cool: return "cool color palette"
        case .vibrant: return "vibrant saturated colors"
        case .pastel: return "soft pastel colors"
        case .monochrome: return "monochrome color scheme"
        case .vintage: return "vintage color grading"
        case .neon: return "neon color palette"
        }
    }
}

// MARK: - Background Style

enum BackgroundStyle: String, Codable, CaseIterable {
    case solidColor = "solid_color"
    case gradient
    case bokeh
    case textured
    case scenic
    case abstract
    case transparent

    var displayName: String {
        switch self {
        case .solidColor: return "Solid Color"
        case .gradient: return "Gradient"
        case .bokeh: return "Bokeh"
        case .textured: return "Textured"
        case .scenic: return "Scenic"
        case .abstract: return "Abstract"
        case .transparent: return "Transparent"
        }
    }

    var promptDescription: String {
        switch self {
        case .solidColor: return "clean solid color background"
        case .gradient: return "smooth gradient background"
        case .bokeh: return "beautiful bokeh background"
        case .textured: return "subtle textured background"
        case .scenic: return "scenic environment background"
        case .abstract: return "artistic abstract background"
        case .transparent: return "transparent background"
        }
    }
}

// MARK: - Camera Angle

enum CameraAngle: String, Codable, CaseIterable {
    case straightOn = "straight_on"
    case slightlyAbove = "slightly_above"
    case slightlyBelow = "slightly_below"
    case profileLeft = "profile_left"
    case profileRight = "profile_right"
    case threeQuarterLeft = "three_quarter_left"
    case threeQuarterRight = "three_quarter_right"

    var displayName: String {
        switch self {
        case .straightOn: return "Straight On"
        case .slightlyAbove: return "Slightly Above"
        case .slightlyBelow: return "Slightly Below"
        case .profileLeft: return "Profile Left"
        case .profileRight: return "Profile Right"
        case .threeQuarterLeft: return "3/4 Left"
        case .threeQuarterRight: return "3/4 Right"
        }
    }

    var promptDescription: String {
        switch self {
        case .straightOn: return "front view portrait"
        case .slightlyAbove: return "slightly elevated camera angle"
        case .slightlyBelow: return "low angle portrait"
        case .profileLeft: return "left profile view"
        case .profileRight: return "right profile view"
        case .threeQuarterLeft: return "three quarter view from left"
        case .threeQuarterRight: return "three quarter view from right"
        }
    }
}

// MARK: - Environment Presets

extension EnvironmentPreference {
    static let studioPortrait = EnvironmentPreference(
        setting: .studioPortrait,
        lightingStyle: .softNatural,
        backgroundStyle: .solidColor
    )

    static let naturalOutdoor = EnvironmentPreference(
        setting: .naturalOutdoor,
        lightingStyle: .goldenHour,
        timeOfDay: .goldenHour,
        backgroundStyle: .scenic
    )

    static let urbanStreet = EnvironmentPreference(
        setting: .urbanStreet,
        lightingStyle: .dramatic,
        backgroundStyle: .bokeh
    )

    static let cozyIndoor = EnvironmentPreference(
        setting: .cozyIndoor,
        lightingStyle: .candlelight,
        colorPalette: .warm,
        backgroundStyle: .bokeh
    )

    static let dreamy = EnvironmentPreference(
        setting: .dreamy,
        lightingStyle: .softNatural,
        colorPalette: .pastel,
        backgroundStyle: .gradient
    )

    static var allPresets: [EnvironmentPreference] {
        [.studioPortrait, .naturalOutdoor, .urbanStreet, .cozyIndoor, .dreamy]
    }
}
