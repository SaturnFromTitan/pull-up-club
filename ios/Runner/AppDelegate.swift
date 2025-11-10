import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var audioEngine: AVAudioEngine?
  private var playerNodes: [AVAudioPlayerNode] = []

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    GeneratedPluginRegistrant.register(with: self)

    guard let controller = window?.rootViewController as? FlutterViewController else {
      return result
    }

    let soundChannel = FlutterMethodChannel(
      name: "pull_up_club/sounds",
      binaryMessenger: controller.binaryMessenger
    )

    soundChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else {
        result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate not available", details: nil))
        return
      }

      switch call.method {
      case "playBeep":
        guard let args = call.arguments as? [String: Any],
              let frequency = args["frequency"] as? Double,
              let duration = args["duration"] as? Double else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
          return
        }
        self.playBeep(frequency: frequency, duration: duration)
        result(nil)

      case "stopAll":
        self.stopAll()
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return result
  }

  private func playBeep(frequency: Double, duration: Double) {
    // Create audio engine if it doesn't exist
    if audioEngine == nil {
      audioEngine = AVAudioEngine()
    }

    guard let engine = audioEngine else { return }

    // Create oscillator node (similar to Web Audio API oscillator)
    let oscillator = AVAudioPlayerNode()
    let mixer = engine.mainMixerNode

    // Generate audio buffer with sine wave
    let sampleRate = Double(engine.outputNode.outputFormat(forBus: 0).sampleRate)
    let frameCount = AVAudioFrameCount(sampleRate * duration)
    let buffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!, frameCapacity: frameCount)!

    buffer.frameLength = frameCount

    // Fill buffer with sine wave
    let channelData = buffer.floatChannelData![0]
    for frame in 0..<Int(frameCount) {
      let time = Double(frame) / sampleRate
      let sample = sin(2.0 * Double.pi * frequency * time)
      // Apply exponential fade-out (similar to Web Audio API gain envelope)
      let fadeOut = exp(-time * 5.0) // Exponential decay
      channelData[frame] = Float(sample * 0.3 * fadeOut) // 0.3 is the initial gain
    }

    // Attach and connect nodes
    engine.attach(oscillator)
    engine.connect(oscillator, to: mixer, format: buffer.format)

    // Start engine if not running
    if !engine.isRunning {
      do {
        try engine.start()
      } catch {
        return
      }
    }

    // Play the buffer
    oscillator.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    oscillator.play()

    // Store reference to clean up later
    playerNodes.append(oscillator)

    // Auto-cleanup after duration
    DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) { [weak self] in
      self?.cleanupNode(oscillator)
    }
  }

  private func stopAll() {
    for node in playerNodes {
      node.stop()
      if let engine = audioEngine {
        engine.detach(node)
      }
    }
    playerNodes.removeAll()
  }

  private func cleanupNode(_ node: AVAudioPlayerNode) {
    node.stop()
    if let engine = audioEngine {
      engine.detach(node)
    }
    if let index = playerNodes.firstIndex(where: { $0 === node }) {
      playerNodes.remove(at: index)
    }
  }
}
