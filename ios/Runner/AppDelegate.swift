import UIKit
import Flutter
import UserNotifications

// Firebase est initialisé côté Dart par FcmService.initialize() via FirebaseOptions
// (dart-define injectés par Codemagic). Plus besoin de FirebaseApp.configure() ici
// ni de GoogleService-Info.plist dans le bundle → élimine SWBUtil.PropertyListConversionError.

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Délégué notifications push — Firebase Messaging plugin gère le reste
    UNUserNotificationCenter.current().delegate = self

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Deep Link handling — URL scheme
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    guard url.scheme == "gbairai" else { return false }
    return super.application(app, open: url, options: options)
  }

  // Universal Links
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL,
       url.host?.hasSuffix("gbairai.ci") == true {
      return super.application(
        application,
        continue: userActivity,
        restorationHandler: restorationHandler
      )
    }
    return false
  }
}

// FCM token refresh géré par le plugin firebase_messaging via FcmService.dart
