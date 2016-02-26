//
//  AppDelegate.swift
//  AutoGPS
//
//  Created by TashiroTomohiro on 2016/02/15.
//  Copyright © 2016年 Weathernews. All rights reserved.
//

import UIKit
import Foundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let defaultsKey_BackgroundEnterTime = "BackgroundEnterTime"
    //private let backgroundMaxDuration = 600.0
    private let backgroundMaxDuration = 10.0
    
    var window: UIWindow?
    var autoGPS = AutoGPS.sharedInstance

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // print appName, version, etc...
        let dictionary = NSBundle.mainBundle().infoDictionary!
        LOG("iOS version: \(UIDevice.currentDevice().systemVersion)")
        LOG(String(format: "appName: %@ (%@), version %@, build %@",
            dictionary[kCFBundleNameKey as String] as! String,
            dictionary[kCFBundleIdentifierKey as String] as! String,
            dictionary["CFBundleShortVersionString"] as! String,
            dictionary[kCFBundleVersionKey as String] as! String))
        LOG("id4vendor: \(UIDevice.currentDevice().identifierForVendor!.UUIDString)")
        LOG("launchOptions: \(launchOptions)")
        
        // iOS8 以降で LocalNotification を表示するための許可
        if #available(iOS 8.0, *) {
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }

        // AutoGPS
        if (launchOptions?[UIApplicationLaunchOptionsLocationKey] != nil) {
            // 位置情報をトリガに、バックグラウンドで起動された場合、AutoGPSだけ有効にして終了。
            LOG("App restart by Location !!!")
            autoGPS.startSigLog()
            return true
            
        } else if autoGPS.autoGPSenabled {
            LOG("AutoGPS enabled, Start GPS.")
            autoGPS.startGpsLog()
        }
    
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        //LOG(__FUNCTION__)
    }

    func applicationDidEnterBackground(application: UIApplication) {
        LOG(__FUNCTION__)
        
        // バックグラウンドに移行した時刻を記録
        NSUserDefaults.standardUserDefaults().setDouble(NSDate().timeIntervalSince1970, forKey: defaultsKey_BackgroundEnterTime)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        LOG(__FUNCTION__)
        
        // バックグラウンドで一定以上時間経過した場合
        let backgroundDuration = NSDate().timeIntervalSince1970 - NSUserDefaults.standardUserDefaults().doubleForKey(defaultsKey_BackgroundEnterTime)
        if backgroundDuration > backgroundMaxDuration {
            if autoGPS.autoGPSenabled {
                LOG("AutoGPS enabled, Start GPS.")
                autoGPS.startGpsLog()
            }
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        LOG(__FUNCTION__)
    }

    func applicationWillTerminate(application: UIApplication) {
        LOG(__FUNCTION__)
    }

}

