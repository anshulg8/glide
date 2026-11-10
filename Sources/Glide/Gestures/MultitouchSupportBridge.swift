import Foundation
import CoreFoundation
import AppKit

public struct MTPoint {
    public var x: Float
    public var y: Float
    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}

public struct MTVector {
    public var position: MTPoint
    public var velocity: MTPoint
    public init(position: MTPoint, velocity: MTPoint) {
        self.position = position
        self.velocity = velocity
    }
}

public struct MTTouch {
    public var frame: Int32
    public var timestamp: Double
    public var identifier: Int32
    public var state: Int32         // 2 = TouchBegan, 3 = MakeTouch, 4 = Touching/Moving, 5 = BreakTouch
    public var fingerID: Int32
    public var handID: Int32
    public var normalized: MTVector // position.x: 0.0 (left) ... 1.0 (right); position.y: 0.0 (bottom) ... 1.0 (top)
    public var size: Float
    public var zero1: Int32
    public var angle: Float
    public var majorAxis: Float
    public var minorAxis: Float
    public var unknown: MTVector
    public var zero2_0: Int32
    public var zero2_1: Int32
    public var density: Float
}

/// Dynamic bridge for Apple's private MultitouchSupport.framework.
public final class MultitouchSupportBridge {
    public typealias FrameHandler = ([MTTouch]) -> Void

    private typealias MTDeviceRef = UnsafeMutableRawPointer
    private typealias MTActuatorRef = UnsafeMutableRawPointer

    private typealias MTContactCallbackWithRefcon = @convention(c) (
        UnsafeMutableRawPointer,
        UnsafeRawPointer,
        Int32,
        Double,
        Int32,
        UnsafeMutableRawPointer?
    ) -> Int32

    private typealias MTDeviceCreateDefaultFunc = @convention(c) () -> MTDeviceRef?
    private typealias MTRegisterContactFrameCallbackWithRefconFunc = @convention(c) (
        MTDeviceRef,
        MTContactCallbackWithRefcon,
        UnsafeMutableRawPointer?
    ) -> Void
    private typealias MTDeviceStartFunc = @convention(c) (MTDeviceRef, Int32) -> Void
    private typealias MTDeviceStopFunc = @convention(c) (MTDeviceRef) -> Void
    private typealias MTDeviceGetDeviceIDFunc = @convention(c) (MTDeviceRef, UnsafeMutablePointer<UInt64>) -> Int32
    private typealias MTActuatorCreateFromDeviceIDFunc = @convention(c) (UInt64) -> MTActuatorRef?
    private typealias MTActuatorOpenFunc = @convention(c) (MTActuatorRef) -> Int32
    private typealias MTActuatorCloseFunc = @convention(c) (MTActuatorRef) -> Int32
    private typealias MTActuatorActuateFunc = @convention(c) (MTActuatorRef, Int32, UInt32, Float, Float) -> Int32

    private var handle: UnsafeMutableRawPointer?
    private var mtDeviceCreateDefault: MTDeviceCreateDefaultFunc?
    private var mtRegisterContactCallback: MTRegisterContactFrameCallbackWithRefconFunc?
    private var mtDeviceStart: MTDeviceStartFunc?
    private var mtDeviceStop: MTDeviceStopFunc?
    private var mtDeviceGetDeviceID: MTDeviceGetDeviceIDFunc?
    private var mtActuatorCreateFromDeviceID: MTActuatorCreateFromDeviceIDFunc?
    private var mtActuatorOpen: MTActuatorOpenFunc?
    private var mtActuatorClose: MTActuatorCloseFunc?
    private var mtActuatorActuate: MTActuatorActuateFunc?

    private var activeDevice: MTDeviceRef?
    private var activeActuator: MTActuatorRef?
    private var frameHandler: FrameHandler?
    private var isRunning: Bool = false

    public init() {
        loadFramework()
    }

    deinit {
        stop()
        if let handle {
            dlclose(handle)
        }
    }

    private func loadFramework() {
        guard let lib = dlopen("/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport", RTLD_LAZY) else {
            NSLog("[Glide] Failed to dlopen MultitouchSupport.framework")
            return
        }
        self.handle = lib

        if let createDef = dlsym(lib, "MTDeviceCreateDefault") {
            mtDeviceCreateDefault = unsafeBitCast(createDef, to: MTDeviceCreateDefaultFunc.self)
        }
        if let reg = dlsym(lib, "MTRegisterContactFrameCallbackWithRefcon") {
            mtRegisterContactCallback = unsafeBitCast(reg, to: MTRegisterContactFrameCallbackWithRefconFunc.self)
        }
        if let start = dlsym(lib, "MTDeviceStart") {
            mtDeviceStart = unsafeBitCast(start, to: MTDeviceStartFunc.self)
        }
        if let stop = dlsym(lib, "MTDeviceStop") {
            mtDeviceStop = unsafeBitCast(stop, to: MTDeviceStopFunc.self)
        }
        if let getDevID = dlsym(lib, "MTDeviceGetDeviceID") {
            mtDeviceGetDeviceID = unsafeBitCast(getDevID, to: MTDeviceGetDeviceIDFunc.self)
        }
        if let createAct = dlsym(lib, "MTActuatorCreateFromDeviceID") {
            mtActuatorCreateFromDeviceID = unsafeBitCast(createAct, to: MTActuatorCreateFromDeviceIDFunc.self)
        }
        if let openAct = dlsym(lib, "MTActuatorOpen") {
            mtActuatorOpen = unsafeBitCast(openAct, to: MTActuatorOpenFunc.self)
        }
        if let closeAct = dlsym(lib, "MTActuatorClose") {
            mtActuatorClose = unsafeBitCast(closeAct, to: MTActuatorCloseFunc.self)
        }
        if let actuate = dlsym(lib, "MTActuatorActuate") {
            mtActuatorActuate = unsafeBitCast(actuate, to: MTActuatorActuateFunc.self)
        }
    }

    public var isAvailable: Bool {
        mtDeviceCreateDefault != nil && mtRegisterContactCallback != nil && mtDeviceStart != nil
    }

    public func start(onFrame: @escaping FrameHandler) -> Bool {
        guard isAvailable, !isRunning else { return isRunning }
        guard let createDef = mtDeviceCreateDefault, let device = createDef() else {
            NSLog("[Glide] MTDeviceCreateDefault returned nil.")
            return false
        }
        guard let registerCallback = mtRegisterContactCallback, let startFunc = mtDeviceStart else { return false }

        self.frameHandler = onFrame
        self.activeDevice = device

        // Setup hardware Force Touch actuator
        var deviceID: UInt64 = 0
        if let getDevID = mtDeviceGetDeviceID, getDevID(device, &deviceID) == 0 {
            if let createAct = mtActuatorCreateFromDeviceID, let actuator = createAct(deviceID) {
                if let openAct = mtActuatorOpen, openAct(actuator) == 0 {
                    self.activeActuator = actuator
                }
            }
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        registerCallback(device, cContactCallback, selfPtr)
        startFunc(device, 0)
        self.isRunning = true
        NSLog("[Glide] MultitouchSupportBridge started. Actuator active: \(self.activeActuator != nil)")
        return true
    }

    public func stop() {
        guard isRunning else { return }
        if let act = activeActuator, let closeAct = mtActuatorClose {
            _ = closeAct(act)
            activeActuator = nil
        }
        if let dev = activeDevice, let stopFunc = mtDeviceStop {
            stopFunc(dev)
            activeDevice = nil
        }
        frameHandler = nil
        isRunning = false
        NSLog("[Glide] MultitouchSupportBridge stopped.")
    }

    /// Triggers physical hardware haptic feedback on the trackpad.
    /// - Parameter actuationID: 1 = ratchet micro-tick, 6 = crisp click (engagement / quick mute)
    public func performHaptic(actuationID: Int32 = 1, strengthMultiplier: Float = 1.0) {
        let hapticLevel = GestureConfiguration.shared.hapticStrength
        guard hapticLevel > 0 else { return }

        let scale: Float = (hapticLevel == 1) ? 0.5 * strengthMultiplier : 1.0 * strengthMultiplier

        if let actuator = activeActuator, let actuate = mtActuatorActuate {
            if actuationID == 6 || actuationID == 2 {
                // Crisp click: ID 6 requires strengthScale > 0 and durationScale = 0 on Apple Silicon
                _ = actuate(actuator, 6, 0, max(0.2, scale), 0.0)
            } else {
                // Subtle ratchet micro-tick: ID 1 with strengthScale = 1.0, durationScale = 1.0
                _ = actuate(actuator, 1, 0, max(0.2, scale), 1.0)
            }
        }

        // Companion AppKit haptic manager trigger
        DispatchQueue.main.async {
            let pattern: NSHapticFeedbackManager.FeedbackPattern = (actuationID == 6 || actuationID == 2) ? .alignment : .levelChange
            NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
        }
    }

    fileprivate func handleTouches(rawTouches: UnsafeRawPointer, count: Int32) {
        guard let handler = frameHandler, count > 0 else { return }
        let touches = rawTouches.assumingMemoryBound(to: MTTouch.self)
        let buffer = UnsafeBufferPointer(start: touches, count: Int(count))
        let array = Array(buffer)
        handler(array)
    }
}

private func cContactCallback(
    device: UnsafeMutableRawPointer,
    touches: UnsafeRawPointer,
    numTouches: Int32,
    timestamp: Double,
    frame: Int32,
    refcon: UnsafeMutableRawPointer?
) -> Int32 {
    guard let refcon else { return 0 }
    let bridge = Unmanaged<MultitouchSupportBridge>.fromOpaque(refcon).takeUnretainedValue()
    bridge.handleTouches(rawTouches: touches, count: numTouches)
    return 0
}

