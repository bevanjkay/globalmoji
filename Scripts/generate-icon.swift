#!/usr/bin/env swift
// Renders the Globalmoji app icon into App/Assets.xcassets/AppIcon.appiconset.
// Usage: swift Scripts/generate-icon.swift [output-dir]
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "App/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

func squircle(in rect: CGRect) -> CGPath {
    // Apple's icon grid: corner radius ≈ 22.37% of the side, drawn as a continuous curve.
    let path = CGMutablePath()
    let r = rect.width * 0.2237
    path.addRoundedRect(in: rect, cornerWidth: r, cornerHeight: r)
    return path
}

func draw(size: CGFloat, into ctx: CGContext) {
    let s = size
    // macOS icons sit inside a ~10% transparent margin.
    let inset = s * 0.0977
    let box = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)

    // Drop shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.012), blur: s * 0.03, color: CGColor(gray: 0, alpha: 0.35))
    ctx.addPath(squircle(in: box))
    ctx.setFillColor(CGColor(gray: 0.1, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    // Background gradient
    ctx.saveGState()
    ctx.addPath(squircle(in: box))
    ctx.clip()
    let colors = [
        CGColor(red: 0.42, green: 0.29, blue: 0.98, alpha: 1),
        CGColor(red: 0.20, green: 0.50, blue: 1.00, alpha: 1),
    ] as CFArray
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: box.minX, y: box.maxY), end: CGPoint(x: box.maxX, y: box.minY), options: [])
    // Soft highlight
    ctx.setFillColor(CGColor(gray: 1, alpha: 0.10))
    ctx.fillEllipse(in: CGRect(x: box.minX - box.width * 0.2, y: box.midY, width: box.width * 1.4, height: box.height * 0.9))
    ctx.restoreGState()

    // Colon (two rounded dots)
    let dot = box.width * 0.13
    let colonX = box.minX + box.width * 0.24
    for y in [box.midY - box.height * 0.11, box.midY + box.height * 0.11] {
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.006), blur: s * 0.015, color: CGColor(gray: 0, alpha: 0.25))
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.fillEllipse(in: CGRect(x: colonX - dot / 2, y: y - dot / 2, width: dot, height: dot))
        ctx.restoreGState()
    }

    // Smiley face
    let face = box.width * 0.44
    let faceRect = CGRect(x: box.minX + box.width * 0.42, y: box.midY - face / 2, width: face, height: face)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.008), blur: s * 0.02, color: CGColor(gray: 0, alpha: 0.3))
    ctx.setFillColor(CGColor(red: 1.0, green: 0.80, blue: 0.20, alpha: 1))
    ctx.fillEllipse(in: faceRect)
    ctx.restoreGState()
    // Face shading
    ctx.saveGState()
    ctx.addEllipse(in: faceRect)
    ctx.clip()
    let faceGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [CGColor(red: 1.0, green: 0.88, blue: 0.35, alpha: 1), CGColor(red: 0.98, green: 0.68, blue: 0.10, alpha: 1)] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(faceGradient, start: CGPoint(x: faceRect.midX, y: faceRect.maxY), end: CGPoint(x: faceRect.midX, y: faceRect.minY), options: [])
    ctx.restoreGState()

    // Eyes
    let eye = face * 0.11
    let eyeY = faceRect.midY + face * 0.14
    ctx.setFillColor(CGColor(red: 0.30, green: 0.18, blue: 0.05, alpha: 1))
    for x in [faceRect.midX - face * 0.2, faceRect.midX + face * 0.2] {
        ctx.fillEllipse(in: CGRect(x: x - eye / 2, y: eyeY - eye / 2, width: eye * 1.0, height: eye * 1.25))
    }
    // Smile
    ctx.setStrokeColor(CGColor(red: 0.30, green: 0.18, blue: 0.05, alpha: 1))
    ctx.setLineWidth(face * 0.075)
    ctx.setLineCap(.round)
    ctx.addArc(center: CGPoint(x: faceRect.midX, y: faceRect.midY + face * 0.02), radius: face * 0.3,
               startAngle: .pi * 1.2, endAngle: .pi * 1.8, clockwise: false)
    ctx.strokePath()
}

func render(_ pixels: Int) -> Data {
    let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high
    draw(size: CGFloat(pixels), into: ctx)
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    return rep.representation(using: .png, properties: [:])!
}

struct Entry { let size: Int; let scale: Int }
let entries = [16, 32, 128, 256, 512].flatMap { [Entry(size: $0, scale: 1), Entry(size: $0, scale: 2)] }
var images: [[String: String]] = []
for entry in entries {
    let pixels = entry.size * entry.scale
    let filename = "icon_\(entry.size)x\(entry.size)@\(entry.scale)x.png"
    try render(pixels).write(to: root.appendingPathComponent(filename))
    images.append(["filename": filename, "idiom": "mac", "scale": "\(entry.scale)x", "size": "\(entry.size)x\(entry.size)"])
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
let json = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
try json.write(to: root.appendingPathComponent("Contents.json"))
print("Wrote \(images.count) icons to \(root.path)")
