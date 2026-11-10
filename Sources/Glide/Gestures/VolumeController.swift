import Foundation
import CoreAudio
import AudioToolbox

/// Controls macOS system audio volume and mute state via native CoreAudio APIs.
public final class VolumeController {
    public static let shared = VolumeController()

    public var onVolumeChanged: ((Float, Bool) -> Void)?

    private init() {}

    /// Retrieves default audio output device ID.
    private func defaultOutputDeviceID() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = kAudioObjectUnknown
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        guard status == noErr, deviceID != kAudioObjectUnknown else { return nil }
        return deviceID
    }

    /// Reads current system output volume (0.0 ... 1.0).
    public func currentVolume() -> Float {
        guard let deviceID = defaultOutputDeviceID() else { return 0.5 }

        // Primary: Virtual Main Volume
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var volume: Float32 = 0.0
        var size = UInt32(MemoryLayout<Float32>.size)
        var status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume)

        if status == noErr {
            return max(0.0, min(1.0, volume))
        }

        // Secondary fallback: scalar volume on channel 1 (Left/Master)
        address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 1
        )
        status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume)
        if status == noErr {
            return max(0.0, min(1.0, volume))
        }

        return 0.5
    }

    /// Sets system output volume (0.0 ... 1.0).
    @discardableResult
    public func setVolume(_ value: Float) -> Float {
        let clamped = max(0.0, min(1.0, value))
        guard let deviceID = defaultOutputDeviceID() else { return clamped }

        // Unmute if raising volume above 0 while muted
        if clamped > 0 && isMuted() {
            setMuted(false)
        }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var volume = Float32(clamped)
        let size = UInt32(MemoryLayout<Float32>.size)

        let status = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &volume)
        if status != noErr {
            // Fallback: set channel 1 and channel 2 if available
            for channel: UInt32 in [1, 2] {
                var chanAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyVolumeScalar,
                    mScope: kAudioDevicePropertyScopeOutput,
                    mElement: channel
                )
                _ = AudioObjectSetPropertyData(deviceID, &chanAddress, 0, nil, size, &volume)
            }
        }

        onVolumeChanged?(clamped, isMuted())
        return clamped
    }

    /// Adjusts volume by a relative delta.
    @discardableResult
    public func adjustVolume(by delta: Float) -> Float {
        let current = currentVolume()
        let target = current + delta
        return setVolume(target)
    }

    /// Checks if default output device is muted.
    public func isMuted() -> Bool {
        guard let deviceID = defaultOutputDeviceID() else { return false }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var muted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &muted)
        return status == noErr && muted != 0
    }

    /// Mutes or unmutes default output device.
    public func setMuted(_ muted: Bool) {
        guard let deviceID = defaultOutputDeviceID() else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var val: UInt32 = muted ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        _ = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &val)
        onVolumeChanged?(currentVolume(), muted)
    }

    /// Toggles mute state of default output device.
    @discardableResult
    public func toggleMute() -> Bool {
        let newMuted = !isMuted()
        setMuted(newMuted)
        return newMuted
    }
}

