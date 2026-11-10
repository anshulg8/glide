import AppKit

func generateIconSet() {
    let sizes: [Int] = [16, 32, 64, 128, 256, 512, 1024]
    let iconsetDir = "AppIcon.iconset"
    let fileManager = FileManager.default
    try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

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

        // Squircle App Background
        let margin = sf * 0.08
        let boxRect = CGRect(x: margin, y: margin, width: sf - 2 * margin, height: sf - 2 * margin)
        let cornerRadius = sf * 0.22
        let path = CGPath(roundedRect: boxRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

        // Drop shadow for the app icon container
        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: -sf * 0.02), blur: sf * 0.04, color: CGColor(gray: 0, alpha: 0.25))
        cg.setFillColor(CGColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1.0))
        cg.addPath(path)
        cg.fillPath()
        cg.restoreGState()

        // Subtle gradient on trackpad body
        cg.addPath(path)
        cg.setStrokeColor(CGColor(gray: 0.8, alpha: 0.8))
        cg.setLineWidth(sf * 0.015)
        cg.strokePath()

        // Trackpad glass bevel
        let bevelMargin = sf * 0.16
        let bevelRect = CGRect(x: bevelMargin, y: bevelMargin, width: sf - 2 * bevelMargin, height: sf - 2 * bevelMargin)
        let bevelRadius = sf * 0.14
        let bevelPath = CGPath(roundedRect: bevelRect, cornerWidth: bevelRadius, cornerHeight: bevelRadius, transform: nil)

        cg.setFillColor(CGColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0))
        cg.addPath(bevelPath)
        cg.fillPath()

        cg.setStrokeColor(CGColor(gray: 0.88, alpha: 0.9))
        cg.setLineWidth(sf * 0.01)
        cg.addPath(bevelPath)
        cg.strokePath()

        // Left Edge Bar (Brightness - Vibrant Amber/Orange)
        let barW = sf * 0.045
        let barH = bevelRect.height * 0.65
        let leftBarRect = CGRect(x: bevelRect.minX + sf * 0.035, y: bevelRect.midY - barH / 2, width: barW, height: barH)
        let leftBarPath = CGPath(roundedRect: leftBarRect, cornerWidth: barW / 2, cornerHeight: barW / 2, transform: nil)

        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: 0), blur: sf * 0.03, color: CGColor(red: 0.96, green: 0.58, blue: 0.12, alpha: 0.6))
        cg.setFillColor(CGColor(red: 0.98, green: 0.55, blue: 0.12, alpha: 1.0))
        cg.addPath(leftBarPath)
        cg.fillPath()
        cg.restoreGState()

        // Right Edge Bar (Volume - Electric Blue)
        let rightBarRect = CGRect(x: bevelRect.maxX - sf * 0.035 - barW, y: bevelRect.midY - barH / 2, width: barW, height: barH)
        let rightBarPath = CGPath(roundedRect: rightBarRect, cornerWidth: barW / 2, cornerHeight: barW / 2, transform: nil)

        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: 0), blur: sf * 0.03, color: CGColor(red: 0.22, green: 0.52, blue: 0.98, alpha: 0.6))
        cg.setFillColor(CGColor(red: 0.22, green: 0.52, blue: 0.98, alpha: 1.0))
        cg.addPath(rightBarPath)
        cg.fillPath()
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
}

generateIconSet()

