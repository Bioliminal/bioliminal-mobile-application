import Flutter
import Foundation

/// Flutter plugin bridging Dart → native MediaPipe Tasks PoseLandmarker.
///
/// Channel: `bioliminal.app/pose`. Inference runs on a serial background
/// queue; concurrent frames are dropped via an atomic flag (defense in
/// depth — Dart side also drops while busy).
public class PosePlugin: NSObject, FlutterPlugin {

    private static let channelName = "bioliminal.app/pose"

    private let helper = PoseLandmarkerHelper()
    private let queue = DispatchQueue(label: "com.bioliminal.app.pose", qos: .userInitiated)
    private var isProcessing = false
    private let lock = NSLock()
    private weak var registrar: FlutterPluginRegistrar?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = PosePlugin(registrar: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize": handleInitialize(call, result: result)
        case "processFrame": handleProcessFrame(call, result: result)
        case "dispose": handleDispose(result: result)
        default: result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Methods

    private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let registrar = self.registrar,
              let args = call.arguments as? [String: Any],
              let assetPath = args["assetPath"] as? String else {
            DispatchQueue.main.async { result(false) }
            return
        }
        let delegate = (args["delegate"] as? String) ?? "cpu"
        let key = registrar.lookupKey(forAsset: assetPath)
        guard let modelPath = Bundle.main.path(forResource: key, ofType: nil) else {
            DispatchQueue.main.async { result(false) }
            return
        }
        queue.async { [weak self] in
            guard let self = self else { return }
            do {
                try self.helper.setup(modelAssetPath: modelPath, delegate: delegate)
                DispatchQueue.main.async { result(true) }
            } catch {
                DispatchQueue.main.async { result(false) }
            }
        }
    }

    private func handleProcessFrame(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let bytesData = args["bytes"] as? FlutterStandardTypedData,
              let width = args["width"] as? Int,
              let height = args["height"] as? Int,
              let bytesPerRow = args["bytesPerRow"] as? Int,
              let rotationDegrees = args["rotationDegrees"] as? Int,
              let timestampMs = args["timestampMs"] as? Int else {
            result([] as [[String: Double]])
            return
        }

        lock.lock()
        if isProcessing {
            lock.unlock()
            result([] as [[String: Double]])
            return
        }
        isProcessing = true
        lock.unlock()

        let bgra = bytesData.data
        queue.async { [weak self] in
            guard let self = self else { return }
            let landmarks = self.helper.detectForVideo(
                bgra: bgra,
                width: width,
                height: height,
                bytesPerRow: bytesPerRow,
                rotationDegrees: rotationDegrees,
                timestampMs: timestampMs
            )
            self.lock.lock()
            self.isProcessing = false
            self.lock.unlock()
            DispatchQueue.main.async { result(landmarks) }
        }
    }

    private func handleDispose(result: @escaping FlutterResult) {
        queue.async { [weak self] in
            self?.helper.close()
            DispatchQueue.main.async { result(nil) }
        }
    }
}
