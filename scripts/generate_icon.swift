import AppKit

func generateIconSet() {
    let sizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]
    let iconsetDir = "AppIcon.iconset"
    let fileManager = FileManager.default
    try? fileManager.removeItem(atPath: iconsetDir)
    try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

    let colorSpace = CGColorSpaceCreateDeviceRGB()

    for s in sizes {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: s,
            pixelsHigh: s,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!

        NSGraphicsContext.saveGraphicsState()
        let ctx = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = ctx
        guard let cg = ctx?.cgContext else { continue }

        let sf = CGFloat(s)

        // 1. Squircle App Background
        let margin = sf * 0.08
        let boxRect = CGRect(x: margin, y: margin, width: sf - 2 * margin, height: sf - 2 * margin)
        let cornerRadius = sf * 0.22
        let squirclePath = CGPath(roundedRect: boxRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

        // Drop shadow for the app icon container
        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: -sf * 0.025), blur: sf * 0.05, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.45))
        cg.addPath(squirclePath)

        // Deep obsidian-slate gradient fill
        let bgColors = [
            CGColor(red: 0.11, green: 0.10, blue: 0.17, alpha: 1.0),
            CGColor(red: 0.05, green: 0.04, blue: 0.08, alpha: 1.0)
        ] as CFArray
        let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!
        cg.saveGState()
        cg.addPath(squirclePath)
        cg.clip()
        cg.drawLinearGradient(bgGradient, start: CGPoint(x: sf * 0.5, y: sf - margin), end: CGPoint(x: sf * 0.5, y: margin), options: [])
        cg.restoreGState()
        cg.restoreGState()

        // Subtle squircle border highlight
        cg.saveGState()
        cg.addPath(squirclePath)
        cg.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.14))
        cg.setLineWidth(max(1.0, sf * 0.012))
        cg.strokePath()
        cg.restoreGState()

        // 2. Inner Trackpad Surface
        let trackpadMargin = sf * 0.16
        let trackpadRect = CGRect(x: trackpadMargin, y: trackpadMargin, width: sf - 2 * trackpadMargin, height: sf - 2 * trackpadMargin)
        let trackpadRadius = sf * 0.13
        let trackpadPath = CGPath(roundedRect: trackpadRect, cornerWidth: trackpadRadius, cornerHeight: trackpadRadius, transform: nil)

        // Trackpad surface gradient
        let tpColors = [
            CGColor(red: 0.18, green: 0.17, blue: 0.27, alpha: 0.95),
            CGColor(red: 0.09, green: 0.08, blue: 0.15, alpha: 0.98)
        ] as CFArray
        let tpGradient = CGGradient(colorsSpace: colorSpace, colors: tpColors, locations: [0.0, 1.0])!

        cg.saveGState()
        cg.addPath(trackpadPath)
        cg.clip()
        cg.drawLinearGradient(tpGradient, start: CGPoint(x: sf * 0.5, y: trackpadRect.maxY), end: CGPoint(x: sf * 0.5, y: trackpadRect.minY), options: [])

        // Ambient lavender center glow
        let glowColors = [
            CGColor(red: 0.56, green: 0.48, blue: 0.92, alpha: 0.22),
            CGColor(red: 0.56, green: 0.48, blue: 0.92, alpha: 0.0)
        ] as CFArray
        let glowGradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0])!
        cg.drawRadialGradient(glowGradient, startCenter: CGPoint(x: sf * 0.5, y: sf * 0.5), startRadius: 0, endCenter: CGPoint(x: sf * 0.5, y: sf * 0.5), endRadius: sf * 0.32, options: [])
        cg.restoreGState()

        // Trackpad surface border
        cg.saveGState()
        cg.addPath(trackpadPath)
        cg.setStrokeColor(CGColor(red: 0.56, green: 0.48, blue: 0.92, alpha: 0.25))
        cg.setLineWidth(max(1.0, sf * 0.008))
        cg.strokePath()
        cg.restoreGState()

        // 3. Central "Glide" Fluid Arc / Wave Symbol
        let wavePath = CGMutablePath()
        let waveStartX = trackpadRect.minX + trackpadRect.width * 0.28
        let waveEndX = trackpadRect.maxX - trackpadRect.width * 0.28
        let midY = trackpadRect.midY

        wavePath.move(to: CGPoint(x: waveStartX, y: midY - sf * 0.05))
        wavePath.addCurve(
            to: CGPoint(x: sf * 0.5, y: midY + sf * 0.04),
            control1: CGPoint(x: waveStartX + sf * 0.08, y: midY - sf * 0.08),
            control2: CGPoint(x: sf * 0.5 - sf * 0.06, y: midY + sf * 0.08)
        )
        wavePath.addCurve(
            to: CGPoint(x: waveEndX, y: midY - sf * 0.05),
            control1: CGPoint(x: sf * 0.5 + sf * 0.06, y: midY),
            control2: CGPoint(x: waveEndX - sf * 0.08, y: midY - sf * 0.08)
        )

        cg.saveGState()
        cg.setShadow(offset: CGSize.zero, blur: sf * 0.04, color: CGColor(red: 0.56, green: 0.48, blue: 0.92, alpha: 0.6))
        cg.addPath(wavePath)
        cg.setStrokeColor(CGColor(red: 0.68, green: 0.60, blue: 0.98, alpha: 0.85))
        cg.setLineWidth(max(1.5, sf * 0.022))
        cg.setLineCap(.round)
        cg.strokePath()
        cg.restoreGState()

        // 4. Left Edge Gesture Rail (Brightness — Amber / Sunburst)
        let railW = sf * 0.045
        let railH = trackpadRect.height * 0.62
        let leftRailX = trackpadRect.minX + sf * 0.032
        let railY = trackpadRect.midY - railH / 2

        // Recessed groove
        let leftGrooveRect = CGRect(x: leftRailX, y: railY, width: railW, height: railH)
        let leftGroovePath = CGPath(roundedRect: leftGrooveRect, cornerWidth: railW / 2, cornerHeight: railW / 2, transform: nil)
        cg.saveGState()
        cg.addPath(leftGroovePath)
        cg.setFillColor(CGColor(red: 0.05, green: 0.04, blue: 0.08, alpha: 0.6))
        cg.fillPath()
        cg.restoreGState()

        // Glowing active slider track
        let leftActiveH = railH * 0.72
        let leftActiveRect = CGRect(x: leftRailX, y: railY, width: railW, height: leftActiveH)
        let leftActivePath = CGPath(roundedRect: leftActiveRect, cornerWidth: railW / 2, cornerHeight: railW / 2, transform: nil)

        let leftColors = [
            CGColor(red: 1.0, green: 0.68, blue: 0.15, alpha: 1.0),
            CGColor(red: 0.98, green: 0.38, blue: 0.12, alpha: 1.0)
        ] as CFArray
        let leftGradient = CGGradient(colorsSpace: colorSpace, colors: leftColors, locations: [0.0, 1.0])!

        cg.saveGState()
        cg.setShadow(offset: CGSize.zero, blur: sf * 0.035, color: CGColor(red: 1.0, green: 0.55, blue: 0.12, alpha: 0.85))
        cg.addPath(leftActivePath)
        cg.clip()
        cg.drawLinearGradient(leftGradient, start: CGPoint(x: leftRailX, y: leftActiveRect.maxY), end: CGPoint(x: leftRailX, y: railY), options: [])
        cg.restoreGState()

        // Sliding touch puck indicator (Brightness)
        let leftPuckY = railY + leftActiveH - railW / 2
        let puckRadius = railW * 0.85
        let leftPuckRect = CGRect(x: leftRailX + (railW - puckRadius) / 2, y: leftPuckY - puckRadius / 2, width: puckRadius, height: puckRadius)
        cg.saveGState()
        cg.setShadow(offset: CGSize.zero, blur: sf * 0.02, color: CGColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 0.95))
        cg.setFillColor(CGColor(red: 1.0, green: 0.96, blue: 0.85, alpha: 1.0))
        cg.fillEllipse(in: leftPuckRect)
        cg.restoreGState()

        // 5. Right Edge Gesture Rail (Volume — Electric Lavender-Cyan)
        let rightRailX = trackpadRect.maxX - sf * 0.032 - railW
        let rightGrooveRect = CGRect(x: rightRailX, y: railY, width: railW, height: railH)
        let rightGroovePath = CGPath(roundedRect: rightGrooveRect, cornerWidth: railW / 2, cornerHeight: railW / 2, transform: nil)

        // Recessed groove
        cg.saveGState()
        cg.addPath(rightGroovePath)
        cg.setFillColor(CGColor(red: 0.05, green: 0.04, blue: 0.08, alpha: 0.6))
        cg.fillPath()
        cg.restoreGState()

        // Glowing active slider track
        let rightActiveH = railH * 0.55
        let rightActiveRect = CGRect(x: rightRailX, y: railY, width: railW, height: rightActiveH)
        let rightActivePath = CGPath(roundedRect: rightActiveRect, cornerWidth: railW / 2, cornerHeight: railW / 2, transform: nil)

        let rightColors = [
            CGColor(red: 0.56, green: 0.48, blue: 0.98, alpha: 1.0),
            CGColor(red: 0.15, green: 0.72, blue: 0.98, alpha: 1.0)
        ] as CFArray
        let rightGradient = CGGradient(colorsSpace: colorSpace, colors: rightColors, locations: [0.0, 1.0])!

        cg.saveGState()
        cg.setShadow(offset: CGSize.zero, blur: sf * 0.035, color: CGColor(red: 0.40, green: 0.55, blue: 0.98, alpha: 0.85))
        cg.addPath(rightActivePath)
        cg.clip()
        cg.drawLinearGradient(rightGradient, start: CGPoint(x: rightRailX, y: rightActiveRect.maxY), end: CGPoint(x: rightRailX, y: railY), options: [])
        cg.restoreGState()

        // Sliding touch puck indicator (Volume)
        let rightPuckY = railY + rightActiveH - railW / 2
        let rightPuckRect = CGRect(x: rightRailX + (railW - puckRadius) / 2, y: rightPuckY - puckRadius / 2, width: puckRadius, height: puckRadius)
        cg.saveGState()
        cg.setShadow(offset: CGSize.zero, blur: sf * 0.02, color: CGColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 0.95))
        cg.setFillColor(CGColor(red: 0.90, green: 0.95, blue: 1.0, alpha: 1.0))
        cg.fillEllipse(in: rightPuckRect)
        cg.restoreGState()

        NSGraphicsContext.restoreGraphicsState()

        if let pngData = rep.representation(using: .png, properties: [:]) {
            let filename: String
            if s == 16 {
                filename = "icon_16x16.png"
            } else if s == 32 {
                try? pngData.write(to: URL(fileURLWithPath: "\(iconsetDir)/icon_16x16@2x.png"))
                filename = "icon_32x32.png"
            } else if s == 64 {
                try? pngData.write(to: URL(fileURLWithPath: "\(iconsetDir)/icon_32x32@2x.png"))
                filename = "icon_32x32@2x.png"
            } else if s == 128 {
                filename = "icon_128x128.png"
            } else if s == 256 {
                try? pngData.write(to: URL(fileURLWithPath: "\(iconsetDir)/icon_128x128@2x.png"))
                filename = "icon_256x256.png"
            } else if s == 512 {
                try? pngData.write(to: URL(fileURLWithPath: "\(iconsetDir)/icon_256x256@2x.png"))
                filename = "icon_512x512.png"
            } else {
                try? pngData.write(to: URL(fileURLWithPath: "\(iconsetDir)/icon_512x512@2x.png"))
                filename = "icon_1024x1024.png"
            }
            try? pngData.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(filename)"))
        }
    }

    print("Iconset generated successfully.")
}

generateIconSet()
