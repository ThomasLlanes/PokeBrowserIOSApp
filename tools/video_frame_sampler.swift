import AVFoundation
import AppKit

let arguments = CommandLine.arguments
guard arguments.count >= 3 else {
    fputs("Usage: swift video_frame_sampler.swift <input.mov> <output-dir>\n", stderr)
    exit(2)
}

let inputURL = URL(fileURLWithPath: arguments[1])
let outputDir = URL(fileURLWithPath: arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let asset = AVURLAsset(url: inputURL)
let duration = CMTimeGetSeconds(asset.duration)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.maximumSize = CGSize(width: 360, height: 780)
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero

let step = 5.0
let times = stride(from: 0.0, through: duration, by: step).map {
    NSValue(time: CMTime(seconds: $0, preferredTimescale: 600))
}

for timeValue in times {
    let seconds = CMTimeGetSeconds(timeValue.timeValue)
    do {
        let cgImage = try generator.copyCGImage(at: timeValue.timeValue, actualTime: nil)
        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            continue
        }
        let fileName = String(format: "frame_%05.1fs.png", seconds)
        try png.write(to: outputDir.appendingPathComponent(fileName))
        print(fileName)
    } catch {
        fputs("Could not sample \(seconds): \(error)\n", stderr)
    }
}
