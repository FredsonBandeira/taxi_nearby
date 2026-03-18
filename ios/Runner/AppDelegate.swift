import UIKit
import Flutter
import GoogleMaps // <- importante importar

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Inicializa Google Maps
        GMSServices.provideAPIKey("key_api_google_maps_ios")
        
        // Configura FlutterImplicitEngineDelegate
        FlutterEngineGroup.shared().addDelegate(self)
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Callback do FlutterImplicitEngine
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
}