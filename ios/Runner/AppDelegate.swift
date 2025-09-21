import UIKit
import Flutter
import flutter_local_notifications
import GoogleMaps
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      // Configure Google Maps
      GMSServices.provideAPIKey("AIzaSyCh3-iIiDfJWQOxsJISRaCMj5b2CS_2okw")
      
      // Set up local notifications callback BEFORE registering plugins
      FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
      }

      if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
      }
      
      // Register plugins AFTER all setup is complete
      GeneratedPluginRegistrant.register(with: self)
      
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
