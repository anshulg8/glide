import Foundation
import AppKit
import CoreGraphics

public final class TrackpadGestureManager {
    public static let shared = TrackpadGestureManager()

    private enum ControlType {
        case brightness
        case volume
    }

    private struct ActiveGesture {
        let control: ControlType
        let touchID: Int32
        let startX: Float
        let startY: Float
        var lastY: Float
        var hasEngaged: Bool
        var lastHapticValue: Float
    }

    private struct TapRecord {
        let time: TimeInterval
        let x: Float
        let y: Float
    }

    private let bridge = MultitouchSupportBridge()
    private let brightnessController = BrightnessController.shared
    private let volumeController = VolumeController.shared
    private let config = GestureConfiguration.shared

    private let queue = DispatchQueue(label: "xyz.edgebar.glide.gestures", qos: .userInteractive)
    private var activeGesture: ActiveGesture?
    private var lastTapRecord: TapRecord?

    /// State for freezing the mouse cursor during edge sliding
    private var isCursorFrozen: Bool = false
    private var frozenCursorLocation: CGPoint? = nil

    /// Minimum vertical movement before gesture engages (prevents accidental taps/clicks)
    private let engagementThreshold: Float = 0.008
    /// Scaling multiplier for natural feel across the physical trackpad height
    private let baseGain: Float = 1.4

    private init() {}

    deinit {
        unfreezeCursorIfNeeded()
    }

    public var isAvailable: Bool {
        bridge.isAvailable
    }

    public func start() {
        guard bridge.isAvailable else {
            NSLog("[Glide] MultitouchSupportBridge is not available on this system.")
            return
        }

        let started = bridge.start { [weak self] touches in
            self?.processFrame(touches)
        }

        if started {
            NSLog("[Glide] TrackpadGestureManager started successfully.")
        } else {
            NSLog("[Glide] TrackpadGestureManager failed to start bridge.")
        }
    }

    public func stop() {
        bridge.stop()
        queue.sync {
            cancelGesture()
        }
        NSLog("[Glide] TrackpadGestureManager stopped.")
    }

    // MARK: - Cursor Freeze

    private func currentCursorLocation() -> CGPoint {
        if let loc = CGEvent(source: nil)?.location {
            return loc
        }
        let mouseLoc = NSEvent.mouseLocation
        let screenHeight = NSScreen.screens.first?.frame.height ?? 1080
        return CGPoint(x: mouseLoc.x, y: screenHeight - mouseLoc.y)
    }

    private func freezeCursor() {
        guard !isCursorFrozen else { return }
        let loc = currentCursorLocation()
        frozenCursorLocation = loc
        CGAssociateMouseAndMouseCursorPosition(0)
        CGWarpMouseCursorPosition(loc)
        isCursorFrozen = true
    }

    private func unfreezeCursorIfNeeded() {
        guard isCursorFrozen else { return }
        if let loc = frozenCursorLocation {
            CGWarpMouseCursorPosition(loc)
        }
        CGAssociateMouseAndMouseCursorPosition(1)
        isCursorFrozen = false
        frozenCursorLocation = nil
    }

    private func cancelGesture() {
        activeGesture = nil
        unfreezeCursorIfNeeded()
    }

    // MARK: - Frame Processing

    private func processFrame(_ touches: [MTTouch]) {
        queue.async { [weak self] in
            guard let self else { return }
            self.handleTouches(touches)
        }
    }

    private func handleTouches(_ touches: [MTTouch]) {
        // Enforce pinned cursor position on every single frame while frozen
        if isCursorFrozen, let loc = frozenCursorLocation {
            CGWarpMouseCursorPosition(loc)
        }

        let edgeWidth = Float(config.edgeZoneWidth)

        if var gesture = activeGesture {
            // Check if our tracked finger is still present on the surface
            guard let tracked = touches.first(where: { $0.identifier == gesture.touchID }) else {
                cancelGesture()
                return
            }

            // Finger lifted or stopped touching (state 0 = NotTouching, 5 = BreakTouch, 7 = OutOfRange)
            if tracked.state == 0 || tracked.state >= 5 {
                checkQuickTap(touch: tracked, wasEngaged: gesture.hasEngaged)
                cancelGesture()
                return
            }

            // Check if user is doing a deliberate multi-finger gesture in the body of the trackpad
            let centerTouches = touches.filter { touch in
                touch.identifier != gesture.touchID &&
                touch.state == 4 &&
                touch.normalized.position.x > (edgeWidth * 1.5) &&
                touch.normalized.position.x < (1.0 - (edgeWidth * 1.5))
            }
            if centerTouches.count >= 2 {
                cancelGesture()
                return
            }

            let x = tracked.normalized.position.x
            let y = tracked.normalized.position.y

            if !gesture.hasEngaged {
                let verticalMovement = abs(y - gesture.startY)
                let inwardMovement: Float = (gesture.startX < 0.5) ? (x - gesture.startX) : (gesture.startX - x)

                // If user drifted inward into main trackpad area before vertical movement,
                // they are moving the pointer, so cancel edge lock.
                if inwardMovement > 0.05 {
                    cancelGesture()
                    return
                }

                if verticalMovement >= engagementThreshold {
                    gesture.hasEngaged = true
                    gesture.lastY = y
                    activeGesture = gesture

                    // Physical Force Touch click upon engagement (Actuation ID 6)
                    if config.isHapticFeedbackEnabled {
                        bridge.performHaptic(actuationID: 6)
                    }
                }
            }

            if gesture.hasEngaged {
                let deltaY = y - gesture.lastY
                gesture.lastY = y

                if abs(deltaY) > 0.0001 {
                    // Check for Fine Control: ⇧ Shift or ⌥ Option
                    let flags = CGEventSource.flagsState(.combinedSessionState)
                    let isFineControlModifier = flags.contains(.maskShift) || flags.contains(.maskAlternate)
                    let fineMultiplier: Float = (config.isFineControlEnabled && isFineControlModifier) ? 0.25 : 1.0

                    switch gesture.control {
                    case .brightness:
                        guard config.isBrightnessEnabled else { return }
                        let sensitivity = Float(config.brightnessSensitivity)
                        let delta = deltaY * sensitivity * baseGain * fineMultiplier
                        let newBrightness = brightnessController.adjustBrightness(by: delta)

                        // Ratchet micro-tick for every ~3.5% adjustment (Actuation ID 1)
                        if abs(newBrightness - gesture.lastHapticValue) >= 0.035 {
                            gesture.lastHapticValue = newBrightness
                            if config.isHapticFeedbackEnabled {
                                bridge.performHaptic(actuationID: 1)
                            }
                        }

                        if config.showOverlay {
                            DispatchQueue.main.async {
                                GestureOverlayController.shared.show(type: .brightness, value: newBrightness)
                            }
                        }

                    case .volume:
                        guard config.isVolumeEnabled else { return }
                        let sensitivity = Float(config.volumeSensitivity)
                        let delta = deltaY * sensitivity * baseGain * fineMultiplier
                        let newVolume = volumeController.adjustVolume(by: delta)
                        let isMuted = volumeController.isMuted()

                        // Ratchet micro-tick for every ~3.5% adjustment (Actuation ID 1)
                        if abs(newVolume - gesture.lastHapticValue) >= 0.035 {
                            gesture.lastHapticValue = newVolume
                            if config.isHapticFeedbackEnabled {
                                bridge.performHaptic(actuationID: 1)
                            }
                        }

                        if config.showOverlay {
                            DispatchQueue.main.async {
                                GestureOverlayController.shared.show(type: .volume, value: newVolume, isMuted: isMuted)
                            }
                        }
                    }
                }

                activeGesture = gesture
            }
        } else {
            // Idle state: Check if a finger lands strictly within the edge activation zone
            let physicalTouches = touches.filter { $0.state >= 2 && $0.state <= 4 }
            guard physicalTouches.count >= 1 && physicalTouches.count <= 2 else { return }

            guard let touch = physicalTouches.first(where: {
                $0.normalized.position.x <= edgeWidth || $0.normalized.position.x >= (1.0 - edgeWidth)
            }) else { return }

            let x = touch.normalized.position.x
            let y = touch.normalized.position.y

            // Check if modifier key is required
            if config.requireModifier {
                let flags = CGEventSource.flagsState(.combinedSessionState)
                let hasRequiredModifier = flags.contains(.maskAlternate) || flags.contains(.maskSecondaryFn)
                if !hasRequiredModifier {
                    return
                }
            }

            // Check Active Height Zone mode
            // Mode 0: Entire edge (y <= 1.0)
            // Mode 1: Bottom half (y <= 0.55)
            // Mode 2: Bottom quarter (y <= 0.30)
            let heightMode = config.edgeZoneHeightMode
            if heightMode == 1 && y > 0.55 { return }
            if heightMode == 2 && y > 0.30 { return }

            let isLeft = x <= edgeWidth
            let isSwap = config.isSwapSides

            // Determine target control based on edge side and swap setting
            let targetControl: ControlType
            if isLeft {
                targetControl = isSwap ? .volume : .brightness
            } else {
                targetControl = isSwap ? .brightness : .volume
            }

            let isEnabled = (targetControl == .brightness) ? config.isBrightnessEnabled : config.isVolumeEnabled
            guard isEnabled else { return }

            let initialValue = (targetControl == .brightness) ? brightnessController.currentBrightness() : volumeController.currentVolume()

            activeGesture = ActiveGesture(
                control: targetControl,
                touchID: touch.identifier,
                startX: x,
                startY: y,
                lastY: y,
                hasEngaged: false,
                lastHapticValue: initialValue
            )

            // Freeze cursor immediately so the pointer stays rock-solid
            if config.isCursorFreezeEnabled {
                freezeCursor()
            }
        }
    }

    // MARK: - Quick Mute Handling

    private func checkQuickTap(touch: MTTouch, wasEngaged: Bool) {
        guard !wasEngaged, config.isQuickMuteEnabled else { return }

        let edgeWidth = Float(config.edgeZoneWidth)
        let x = touch.normalized.position.x
        let y = touch.normalized.position.y

        // Top-right corner zone: right edge and upper quarter
        let isTopRight = x >= (1.0 - edgeWidth * 1.5) && y >= 0.70
        guard isTopRight else { return }

        let now = ProcessInfo.processInfo.systemUptime
        if let last = lastTapRecord, (now - last.time) <= 0.45 {
            // Second tap detected within 450ms -> Toggle Mute!
            lastTapRecord = nil
            let newMuted = volumeController.toggleMute()
            let currentVol = volumeController.currentVolume()

            if config.isHapticFeedbackEnabled {
                bridge.performHaptic(actuationID: 6)
            }

            if config.showOverlay {
                DispatchQueue.main.async {
                    GestureOverlayController.shared.show(type: .volume, value: currentVol, isMuted: newMuted)
                }
            }
            NSLog("[Glide] Quick Mute toggled: muted=\(newMuted)")
        } else {
            lastTapRecord = TapRecord(time: now, x: x, y: y)
        }
    }
}

