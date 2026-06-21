#!/usr/bin/env swift
// Generates a 1024×1024 master app-icon PNG: a teal-gradient rounded-rect with
// the mosque SVG rendered in white. The same SVG backs the menu bar glyph.
// Usage: swift scripts/make-icon.swift <mosque.svg> <output.png>
import AppKit

let args = CommandLine.arguments
guard args.count > 2 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <svg> <out.png>\n".utf8)); exit(1)
}
let svgPath = args[1]
let outPath = args[2]
let size = 1024.0

// Load the mosque SVG (NSImage supports SVG on macOS 13+) and tint it white.
guard let mosque = NSImage(contentsOfFile: svgPath) else {
    FileHandle.standardError.write(Data("could not load svg: \(svgPath)\n".utf8)); exit(1)
}
func tintedWhite(_ image: NSImage) -> NSImage {
    let out = NSImage(size: image.size)
    out.lockFocus()
    image.draw(at: .zero, from: NSRect(origin: .zero, size: image.size), operation: .sourceOver, fraction: 1)
    NSColor.white.set()
    NSRect(origin: .zero, size: image.size).fill(using: .sourceAtop)
    out.unlockFocus()
    return out
}
let whiteMosque = tintedWhite(mosque)

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

// Rounded-rect "body" (macOS-style margins + corner radius).
let inset = size * 0.092
let body = CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
let radius = body.width * 0.2237

ctx.saveGState()
NSBezierPath(roundedRect: body, xRadius: radius, yRadius: radius).addClip()
NSGradient(colors: [
    NSColor(srgbRed: 0.22, green: 0.62, blue: 0.30, alpha: 1),   // green
    NSColor(srgbRed: 0.09, green: 0.40, blue: 0.18, alpha: 1),   // deep green
])!.draw(in: body, angle: -90)
ctx.restoreGState()

// Draw the white mosque centered, ~58% of the body.
let side = body.height * 0.58
let rect = NSRect(x: body.midX - side / 2, y: body.midY - side / 2, width: side, height: side)
whiteMosque.draw(in: rect, from: NSRect(origin: .zero, size: whiteMosque.size),
                 operation: .sourceOver, fraction: 1)

NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("failed to encode PNG\n".utf8)); exit(1)
}
try! data.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
