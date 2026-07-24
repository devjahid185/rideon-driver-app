
import UIKit
import Flutter
import GoogleMaps
import FirebaseCore
import CoreLocation
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    var audioPlayer: AVAudioPlayer? // ✅ Add audio player instance

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize Google Maps
        GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")

        // Initialize Firebase
        FirebaseApp.configure()

        // Initialize location manager
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.showsBackgroundLocationIndicator = true

        setupAudioSession()

        // Set up existing method channel
        let controller = window?.rootViewController as! FlutterViewController
        let bubbleChannel = FlutterMethodChannel(name: "com.sizh.rideon.driver.taxiapp/floating_bubble", binaryMessenger: controller.binaryMessenger)
        bubbleChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate not available", details: nil))
                return
            }
            switch call.method {
                case "startBackgroundLocation":
                    self.startBackgroundLocation()
                    result(nil)
                case "showBubble":
                    print("Show bubble called")
                    result(nil)
                case "hideBubble":
                    print("Hide bubble called")
                    result(nil)
                case "setupAudioSession":
                    self.setupAudioSession()
                    result(nil)
                case "requestMicrophonePermission":
                    self.requestMicrophonePermission(result: result)
                case "deactivateAudioSession":
                    self.deactivateAudioSession(result: result)
                default:
                    result(FlutterMethodNotImplemented)
            }
        }

        // ✅ Set up new ringtone channel
        let ringtoneChannel = FlutterMethodChannel(name: "com.sizh.rideon.driver.taxiapp/ringtone", binaryMessenger: controller.binaryMessenger)
        ringtoneChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate not available", details: nil))
                return
            }
            switch call.method {
                case "playRingtone":
                    self.playRingtone()
                    result(true)
                case "stopRingtone":
                    self.stopRingtone()
                    result(true)
                default:
                    result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetooth, .allowAirPlay])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error.localizedDescription)")
        }
    }

    func deactivateAudioSession(result: @escaping FlutterResult) {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            print("Audio session deactivated successfully.")
            result(true)
        } catch {
            result(FlutterError(code: "AUDIO_ERROR", message: "Failed to deactivate audio session: \(error.localizedDescription)", details: nil))
        }
    }

    private func requestMicrophonePermission(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                result(granted)
            }
        }
    }

    func startBackgroundLocation() {
        locationManager?.requestAlwaysAuthorization()
        locationManager?.startUpdatingLocation()
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let channel = FlutterMethodChannel(name: "com.sizh.rideon.driver.taxiapp/floating_bubble", binaryMessenger: (window?.rootViewController as! FlutterViewController).binaryMessenger)
        channel.invokeMethod("locationUpdate", arguments: [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy
        ]) { result in
            if let error = result as? FlutterError {
                print("Error sending location to Flutter: \(error.message ?? "Unknown error")")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }

    func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        if backgroundTask == .invalid {
            startBackgroundLocation()
        }
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        locationManager?.stopUpdatingLocation()
        endBackgroundTask()
    }

    func playRingtone() {
        guard let url = Bundle.main.url(forResource: "call_tune", withExtension: "mp3") else {
            print("Ringtone file not found")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()

            // Configure the session for playback even in background/lock screen
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])

            // Use this before .setActive(true) to avoid conflicts with previous session
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            // Initialize and play the audio
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // infinite loop
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            print("Native ringtone started successfully")

        } catch {
            print("Error setting up and starting ringtone: \(error.localizedDescription)")
        }
    }


    // ✅ Stop Ringtone Method
    func stopRingtone() {
        audioPlayer?.stop()
        print("Native ringtone stopped")
    }
}
