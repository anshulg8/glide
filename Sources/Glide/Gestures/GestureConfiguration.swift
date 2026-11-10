import Foundation
import SwiftUI
import ServiceManagement

/// Persistent user configuration for Glide trackpad gestures.
@Observable
public final class GestureConfiguration {
    public static let shared = GestureConfiguration()

    // MARK: - Keys
    public static let brightnessEnabledKey = "glide_brightness_enabled"
    public static let volumeEnabledKey = "glide_volume_enabled"
    public static let brightnessSensitivityKey = "glide_brightness_sensitivity"
    public static let volumeSensitivityKey = "glide_volume_sensitivity"
    public static let edgeZoneWidthKey = "glide_edge_zone_width"
    public static let showOverlayKey = "glide_show_overlay"
    public static let cursorFreezeEnabledKey = "glide_cursor_freeze_enabled"
    public static let hapticStrengthKey = "glide_haptic_strength" // 0: Off, 1: Subtle, 2: Strong
    public static let swapSidesKey = "glide_swap_sides"
    public static let edgeZoneHeightModeKey = "glide_edge_zone_height_mode" // 0: Entire Edge, 1: Bottom Half, 2: Bottom Quarter
    public static let quickMuteEnabledKey = "glide_quick_mute_enabled"
    public static let requireModifierKey = "glide_require_modifier"
    public static let fineControlEnabledKey = "glide_fine_control_enabled"
    public static let appearanceKey = "glide_appearance" // "system", "light", "dark"
    public static let autoCheckUpdatesKey = "glide_auto_check_updates"

    // MARK: - Defaults
    public static let defaultBrightnessEnabled: Bool = true
    public static let defaultVolumeEnabled: Bool = true
    public static let defaultBrightnessSensitivity: Double = 1.0
    public static let defaultVolumeSensitivity: Double = 1.0
    public static let defaultEdgeZoneWidth: Double = 0.06 // 6% of trackpad width
    public static let defaultShowOverlay: Bool = true
    public static let defaultCursorFreezeEnabled: Bool = true
    public static let defaultHapticStrength: Int = 2 // Strong
    public static let defaultSwapSides: Bool = false
    public static let defaultEdgeZoneHeightMode: Int = 0 // Entire Edge
    public static let defaultQuickMuteEnabled: Bool = true
    public static let defaultRequireModifier: Bool = false
    public static let defaultFineControlEnabled: Bool = true
    public static let defaultAppearance: String = "system"
    public static let defaultAutoCheckUpdates: Bool = true

    // MARK: - Observable Properties with UserDefaults backing

    public var isBrightnessEnabled: Bool {
        didSet { UserDefaults.standard.set(isBrightnessEnabled, forKey: Self.brightnessEnabledKey) }
    }

    public var isVolumeEnabled: Bool {
        didSet { UserDefaults.standard.set(isVolumeEnabled, forKey: Self.volumeEnabledKey) }
    }

    public var brightnessSensitivity: Double {
        didSet { UserDefaults.standard.set(brightnessSensitivity, forKey: Self.brightnessSensitivityKey) }
    }

    public var volumeSensitivity: Double {
        didSet { UserDefaults.standard.set(volumeSensitivity, forKey: Self.volumeSensitivityKey) }
    }

    public var edgeZoneWidth: Double {
        didSet { UserDefaults.standard.set(edgeZoneWidth, forKey: Self.edgeZoneWidthKey) }
    }

    public var showOverlay: Bool {
        didSet { UserDefaults.standard.set(showOverlay, forKey: Self.showOverlayKey) }
    }

    public var isCursorFreezeEnabled: Bool {
        didSet { UserDefaults.standard.set(isCursorFreezeEnabled, forKey: Self.cursorFreezeEnabledKey) }
    }

    public var hapticStrength: Int {
        didSet { UserDefaults.standard.set(hapticStrength, forKey: Self.hapticStrengthKey) }
    }

    public var isSwapSides: Bool {
        didSet { UserDefaults.standard.set(isSwapSides, forKey: Self.swapSidesKey) }
    }

    public var edgeZoneHeightMode: Int {
        didSet { UserDefaults.standard.set(edgeZoneHeightMode, forKey: Self.edgeZoneHeightModeKey) }
    }

    public var isQuickMuteEnabled: Bool {
        didSet { UserDefaults.standard.set(isQuickMuteEnabled, forKey: Self.quickMuteEnabledKey) }
    }

    public var requireModifier: Bool {
        didSet { UserDefaults.standard.set(requireModifier, forKey: Self.requireModifierKey) }
    }

    public var isFineControlEnabled: Bool {
        didSet { UserDefaults.standard.set(isFineControlEnabled, forKey: Self.fineControlEnabledKey) }
    }

    public var appearanceMode: String {
        didSet {
            UserDefaults.standard.set(appearanceMode, forKey: Self.appearanceKey)
            NotificationCenter.default.post(name: Notification.Name("GlideAppearanceChanged"), object: nil)
        }
    }

    public var autoCheckUpdates: Bool {
        didSet { UserDefaults.standard.set(autoCheckUpdates, forKey: Self.autoCheckUpdatesKey) }
    }

    public var isHapticFeedbackEnabled: Bool {
        get { hapticStrength > 0 }
        set { hapticStrength = newValue ? 2 : 0 }
    }

    public var launchAtLogin: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                NSLog("[Glide] Failed to toggle launch at login: \(error.localizedDescription)")
            }
        }
    }

    private init() {
        let defaults = UserDefaults.standard

        self.isBrightnessEnabled = defaults.object(forKey: Self.brightnessEnabledKey) as? Bool ?? Self.defaultBrightnessEnabled
        self.isVolumeEnabled = defaults.object(forKey: Self.volumeEnabledKey) as? Bool ?? Self.defaultVolumeEnabled

        let bSens = defaults.double(forKey: Self.brightnessSensitivityKey)
        self.brightnessSensitivity = bSens > 0 ? bSens : Self.defaultBrightnessSensitivity

        let vSens = defaults.double(forKey: Self.volumeSensitivityKey)
        self.volumeSensitivity = vSens > 0 ? vSens : Self.defaultVolumeSensitivity

        let eWidth = defaults.double(forKey: Self.edgeZoneWidthKey)
        self.edgeZoneWidth = eWidth > 0 ? eWidth : Self.defaultEdgeZoneWidth

        self.showOverlay = defaults.object(forKey: Self.showOverlayKey) as? Bool ?? Self.defaultShowOverlay
        self.isCursorFreezeEnabled = defaults.object(forKey: Self.cursorFreezeEnabledKey) as? Bool ?? Self.defaultCursorFreezeEnabled
        self.hapticStrength = defaults.object(forKey: Self.hapticStrengthKey) as? Int ?? Self.defaultHapticStrength
        self.isSwapSides = defaults.object(forKey: Self.swapSidesKey) as? Bool ?? Self.defaultSwapSides
        self.edgeZoneHeightMode = defaults.object(forKey: Self.edgeZoneHeightModeKey) as? Int ?? Self.defaultEdgeZoneHeightMode
        self.isQuickMuteEnabled = defaults.object(forKey: Self.quickMuteEnabledKey) as? Bool ?? Self.defaultQuickMuteEnabled
        self.requireModifier = defaults.object(forKey: Self.requireModifierKey) as? Bool ?? Self.defaultRequireModifier
        self.isFineControlEnabled = defaults.object(forKey: Self.fineControlEnabledKey) as? Bool ?? Self.defaultFineControlEnabled
        self.appearanceMode = defaults.string(forKey: Self.appearanceKey) ?? Self.defaultAppearance
        self.autoCheckUpdates = defaults.object(forKey: Self.autoCheckUpdatesKey) as? Bool ?? Self.defaultAutoCheckUpdates
    }

    public func resetToDefaults() {
        isBrightnessEnabled = Self.defaultBrightnessEnabled
        isVolumeEnabled = Self.defaultVolumeEnabled
        brightnessSensitivity = Self.defaultBrightnessSensitivity
        volumeSensitivity = Self.defaultVolumeSensitivity
        edgeZoneWidth = Self.defaultEdgeZoneWidth
        showOverlay = Self.defaultShowOverlay
        isCursorFreezeEnabled = Self.defaultCursorFreezeEnabled
        hapticStrength = Self.defaultHapticStrength
        isSwapSides = Self.defaultSwapSides
        edgeZoneHeightMode = Self.defaultEdgeZoneHeightMode
        isQuickMuteEnabled = Self.defaultQuickMuteEnabled
        requireModifier = Self.defaultRequireModifier
        isFineControlEnabled = Self.defaultFineControlEnabled
        appearanceMode = Self.defaultAppearance
        autoCheckUpdates = Self.defaultAutoCheckUpdates
    }
}

