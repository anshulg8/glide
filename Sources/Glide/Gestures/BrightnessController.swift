import Foundation
import CoreGraphics

/// Controls display brightness on macOS using private DisplayServices.framework.
public final class BrightnessController {
    public static let shared = BrightnessController()

    private typealias DisplayServicesGetBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias DisplayServicesSetBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32

    private var getBrightnessPtr: DisplayServicesGetBrightnessFunc?
    private var setBrightnessPtr: DisplayServicesSetBrightnessFunc?
    private var isAvailable: Bool = false

    public var onBrightnessChanged: ((Float) -> Void)?

    private init() {
        loadDisplayServices()
    }

    private func loadDisplayServices() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY) else {
            NSLog("[Glide] Failed to dlopen DisplayServices.framework")
            return
        }

        if let getSym = dlsym(handle, "DisplayServicesGetBrightness"),
           let setSym = dlsym(handle, "DisplayServicesSetBrightness") {
            getBrightnessPtr = unsafeBitCast(getSym, to: DisplayServicesGetBrightnessFunc.self)
            setBrightnessPtr = unsafeBitCast(setSym, to: DisplayServicesSetBrightnessFunc.self)
            isAvailable = true
        }
    }

    /// Resolves built-in display ID or falls back to main display ID.
    public func targetDisplayID() -> CGDirectDisplayID {
        var count: UInt32 = 0
        CGGetOnlineDisplayList(0, nil, &count)
        guard count > 0 else { return CGMainDisplayID() }

        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetOnlineDisplayList(count, &displays, &count)

        if let builtin = displays.first(where: { CGDisplayIsBuiltin($0) != 0 }) {
            return builtin
        }
        return CGMainDisplayID()
    }

    /// Reads current display brightness (0.0 to 1.0).
    public func currentBrightness() -> Float {
        guard isAvailable, let getBrightness = getBrightnessPtr else { return 0.5 }
        let display = targetDisplayID()
        var value: Float = 0.0
        let err = getBrightness(display, &value)
        if err == 0 {
            return max(0.0, min(1.0, value))
        }
        return 0.5
    }

    /// Sets display brightness (0.0 to 1.0).
    @discardableResult
    public func setBrightness(_ value: Float) -> Float {
        let clamped = max(0.0, min(1.0, value))
        guard isAvailable, let setBrightness = setBrightnessPtr else { return clamped }
        let display = targetDisplayID()
        _ = setBrightness(display, clamped)
        onBrightnessChanged?(clamped)
        return clamped
    }

    /// Adjusts brightness by a relative delta.
    @discardableResult
    public func adjustBrightness(by delta: Float) -> Float {
        let current = currentBrightness()
        let target = current + delta
        return setBrightness(target)
    }
}

