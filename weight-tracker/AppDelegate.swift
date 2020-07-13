//
//  AppDelegate.swift
//  Weight Tracker
//
//  Created by Carlos Diaz on 11/18/19.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        registerHealthKit()
        return true
    }
    
    func registerHealthKit() {
        if (HealthKitManager.shared.isHealthDataAvailable()) {
            HealthKitManager.shared.requestAuthorization { (success, error) in
                if success {
                    HealthKitManager.shared.enableBackgroundDelivery { (success, error) in
                        if success {
                            HealthKitManager.shared.registerQuery()
                        } else {
                            self.showAlert(title: "Error", message: "The background mode couldn't be enabled", buttonTitle: "OK")
                        }
                    }
                } else {
                    self.showAlert(title: "Error", message: "The app doesn't have permissions to read the Body Mass", buttonTitle: "OK")
                }
            }
        } else {
            self.showAlert(title: "Error", message: "The app doesn't have Health Data Available", buttonTitle: "OK")//
        }
    }
    
    func showAlert(title: String, message: String, buttonTitle: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: UIAlertAction.Style.default, handler: nil))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        HealthKitManager.shared.syncronizeData { (newData) in
            completionHandler(newData ? .newData : .noData)
        }
    }
    
}
