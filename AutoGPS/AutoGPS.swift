//
//  AutoGPS.swift
//  AutoGPS
//
//  Created by TashiroTomohiro on 2016/02/15.
//  Copyright © 2016年 Weathernews. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

enum AutoGPSMode {
    case NotRunning
    case StartupGPS
    case Significant
}

class AutoGPS : NSObject, CLLocationManagerDelegate
{
    let notificationKey = "AutoGPSLocationUpdated"
    private let defaultsKey_AutoGPSenabled  = "AutoGPSenabled"
    private let defaultsKey_AutoGPSinterval = "AutoGPSinterval"
    private let defaultsKey_LastReportDate  = "LastReportDate"
    private let defaultsKey_LastReportLat   = "LastReportLat"
    private let defaultsKey_LastReportLon   = "LastReportLon"
    private let api_url = "http://pt-roman.wni.co.jp/ip/tashiro/update_position.cgi"
    
    var mode :AutoGPSMode = .NotRunning
    var gpslat = 0.0
    var gpslon = 0.0
    var gpsDate :NSDate?
    var autoGPSsupporting :Bool {
        return CLLocationManager.significantLocationChangeMonitoringAvailable()
    }
    var autoGPSenabled :Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(defaultsKey_AutoGPSenabled)
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: defaultsKey_AutoGPSenabled)
            NSUserDefaults.standardUserDefaults().synchronize()
            
            if newValue == true {
                if self.gpsDate == nil {
                    self.startGpsLog()
                } else {
                    self.startSigLog()
                }
            } else {
                self.stopAllLog()
            }
        }
    }
    
    var autoGPSinterval :NSTimeInterval {
        get {
            let t = NSUserDefaults.standardUserDefaults().doubleForKey(self.defaultsKey_AutoGPSinterval)
            if t > 0 && t <= 86400 {
                return t
            } else {
                return 600
            }
        }
        set {
            if newValue > 0 && newValue <= 86400 {
                NSUserDefaults.standardUserDefaults().setDouble(newValue, forKey:self.defaultsKey_AutoGPSinterval)
                NSUserDefaults.standardUserDefaults().synchronize()
            }
        }
    }

    var lastReportDate :NSDate {
        get {
            let t = NSUserDefaults.standardUserDefaults().doubleForKey(self.defaultsKey_LastReportDate)
            if t > 0 {
                return NSDate(timeIntervalSince1970: t)
            } else {
                return NSDate(timeIntervalSinceNow: -86400.0)
            }
        }
        set {
            NSUserDefaults.standardUserDefaults().setDouble(newValue.timeIntervalSince1970, forKey:self.defaultsKey_LastReportDate)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }

    var lastReportLocation :CLLocation {
        get {
            let lat = NSUserDefaults.standardUserDefaults().doubleForKey(defaultsKey_LastReportLat)
            let lon = NSUserDefaults.standardUserDefaults().doubleForKey(defaultsKey_LastReportLon)
            return CLLocation(latitude: lat, longitude: lon)
        }
        set {
            NSUserDefaults.standardUserDefaults().setDouble(newValue.coordinate.latitude,  forKey: defaultsKey_LastReportLat)
            NSUserDefaults.standardUserDefaults().setDouble(newValue.coordinate.longitude, forKey: defaultsKey_LastReportLon)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    private let locationManager = CLLocationManager()
    private var HTTPLoader :WNHTTPLoader?
    private let dateFormatter = NSDateFormatter()
    private let distanceFilter = 1000.0
    private var serverSendStartTime = NSDate(timeIntervalSinceNow: -600)

    // MARK: -
    /* こちらは swift 1.2以前の古い書き方
    class var sharedInstance : AutoGPS {
        struct Static {
            static let instance : AutoGPS = AutoGPS()
        }
        return Static.instance
    }
    */
    static let sharedInstance = AutoGPS()  // swift 1.2以降のシングルトンはこれで良いらしい http://qiita.com/kmagai/items/7c501185ca82de6dbcd5
    
    override init() {
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        if #available(iOS 8.0, *) {
            //LOG("show GPS dialog for iOS 8+ if needed")
            self.locationManager.requestAlwaysAuthorization()

        } else if CLLocationManager.authorizationStatus() == .NotDetermined {
            // iOS7 で、GPS利用許可が未定の場合、位置情報取得を開始することで、利用許可のダイアログを表示させる
            LOG("show GPS dialog for iOS 7")
            self.locationManager.startUpdatingLocation()
        }

        self.dateFormatter.locale = NSLocale.systemLocale()
        self.dateFormatter.dateFormat = "HH:mm"
    }
    
    deinit {
        self.stopAllLog()
        self.locationManager.delegate = nil
        
        self.HTTPLoader?.cancel()
        self.HTTPLoader?.delegate = nil
    }
    
    // MARK: - pubclic function
    func startSigLog() {
        LOG(__FUNCTION__)
        if self.autoGPSsupporting == false {
            // 端末が significantLocationChange をサポートしていない
            LOG("[AutoGPS] Location not available.(Start Sig, enable)");
            return
        }
        
        if self.mode == .Significant {
            LOG("[AutoGPS] SignificantLocationChanges already running")
            return
        }
        
        switch CLLocationManager.authorizationStatus() {
        case .Restricted, .Denied:
            LOG("[AutoGPS] Location not available.(Start Sig, authorize)")
            
        case .AuthorizedAlways, .AuthorizedWhenInUse, .NotDetermined:
            LOG("[AutoGPS] Start SignificantLocationChanges logging.")
            self.mode = .Significant
            self.locationManager.distanceFilter = 1000.0  // significant の場合は km単位で位置が取れれば良い
            self.locationManager.startMonitoringSignificantLocationChanges()
            //self.showLocalNotification("Start SignificantLocationChanges logging.")
        }
    }
    
    func startGpsLog() {
        LOG(__FUNCTION__)
        if CLLocationManager.locationServicesEnabled() == false  {
            // 端末が GPS をサポートしていない
            LOG("[AutoGPS] Location not available.(Start GPS, enable)")
            return
        }
        
        if self.mode == .StartupGPS {
            LOG("[AutoGPS] GPS logging already running")
            return;
        }

        switch CLLocationManager.authorizationStatus() {
        case .Restricted, .Denied:
            LOG("[AutoGPS] Location not available.(Start Sig, authorize)")
            
        case .AuthorizedAlways, .AuthorizedWhenInUse, .NotDetermined:
            LOG("[AutoGPS] Start GPS logging.")
            self.mode = .StartupGPS
            self.locationManager.distanceFilter = 100.0  // GPS の場合は 100m単位でフィルターする
            self.locationManager.startUpdatingLocation()
            //self.showLocalNotification("Start GPS logging.")
        }
    }
    
    func stopAllLog() {
        LOG("[AutoGPS] Stop All logging.")
        self.mode = .NotRunning
        
        if self.autoGPSsupporting {
            self.locationManager.stopMonitoringSignificantLocationChanges()
        }
        self.locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    @objc func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            self.startGpsLog()

        default:
            break
        }
    }
    
    @objc func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last
        if newLocation == nil {
            return
        }
        LOG("[GPS] newLocation:\(newLocation!) from \(locations.count) locations.")
        
        if fabs(newLocation!.timestamp.timeIntervalSinceNow) > 15.0 {
            LOG("[GPS] timestamp is not latest:\(newLocation!.timestamp)")
            return;
        }
        
        self.gpslat = newLocation!.coordinate.latitude
        self.gpslon = newLocation!.coordinate.longitude
        self.gpsDate = newLocation!.timestamp

        // 位置情報の更新を他の class に通知
        NSNotificationCenter.defaultCenter().postNotification( NSNotification(name: self.notificationKey, object: self) )
        
        
        // サーバー通知を行うか判定、最初のGPS取得なら以降 Significant に切り替え
        let distance = newLocation!.distanceFromLocation(self.lastReportLocation)
        let interval = NSDate().timeIntervalSinceDate(self.lastReportDate)
        LOG(String(format:"[AutoGPS] distance:%.0fm, time interval:%.0fsec, filter:%.0fsec.", distance, interval, self.autoGPSinterval))
        
        switch self.mode {
        case .StartupGPS:
            self.stopAllLog()
            if self.autoGPSenabled {
                // １回サーバーに一送信したら、Significant に切り替え
                self.sendLocationToServer(newLocation!)
                self.startSigLog()
            }
            
        case .Significant:
            if interval > self.autoGPSinterval && distance > distanceFilter {
                self.sendLocationToServer(newLocation!)
            }
            
        default:
            break
        }
    }
    
    @objc func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        LOG("[AutoGPS] error: \(error.localizedDescription)")
        #if DEBUG
            if #available(iOS 8.0, *) {
/*
                let alert = UIAlertController(title: "error", message: error.localizedDescription, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                var baseView = UIApplication.sharedApplication().keyWindow?.rootViewController
                while( baseView?.presentedViewController != nil && ! baseView?.presentedViewController?.isBeingDismissed ){
                    baseView = baseView?.presentedViewController
                    baseView!.presentViewController(alert, animated: true, completion: nil)
                }
*/
            }
        #endif
    }
    
    // MARK: - WNHTTPLoaderDelegate
    override func loader(loader: WNHTTPLoader!, didReceiveData data: NSData!, loaderID: String!) {
        do {
            let jsonValue = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
            if jsonValue["status"]!["auth"] as! String == "OK" {
                // json auth OK
                let interval :NSTimeInterval = jsonValue["status"]!["interval"] as! Double
                self.autoGPSinterval = interval
                self.lastReportDate = NSDate()
                self.lastReportLocation = CLLocation(latitude: self.gpslat, longitude: self.gpslon)

#if DEBUG
                NSNotificationCenter.defaultCenter().postNotification( NSNotification(name: self.notificationKey, object: self) )
#endif
            } else {
                // json auth NG
                LOG("[AutoGPS] json auth NG, \(String(data: data, encoding: NSUTF8StringEncoding)!)")
            }
        } catch {
            // json parse error
            LOG("[AutoGPS] json error, \(String(data: data, encoding: NSUTF8StringEncoding)!)")
        }
    }
    
    override func loader(loader: WNHTTPLoader!, didFailWithError error: NSError!, loaderID: String!) {
        // http error
        LOG("[AutoGPS] http error:\(error.localizedDescription)")
    }
    
    
    // MARK: - private fuction
    private func sendLocationToServer(location: CLLocation) {
        if abs(serverSendStartTime.timeIntervalSinceNow) < 10 {
            // サーバーに連続して位置情報を送信しないよう、前回送信開始直後なら送信しない
            LOG("\(__FUNCTION__) 連続送信回避, skip")
            return
        }
        
        serverSendStartTime = NSDate()
        let akey = UIDevice.currentDevice().identifierForVendor!.UUIDString  // DEBUG
        let url = api_url + String(format: "?carrier=APPL&akey=%@&lat=%f&lon=%f", akey, location.coordinate.latitude, location.coordinate.longitude)
        //LOG("url:\(url)")
        
        let req = NSURLRequest(URL: NSURL(string: url)!)
        HTTPLoader = WNHTTPLoader(request: req, delegate: self, loaderID: "AutoGPS")
        
        #if DEBUG
            let message = String(format: "[%@] lat:%.4f, lon:%.4f",
                self.dateFormatter.stringFromDate(location.timestamp), location.coordinate.latitude, location.coordinate.longitude)
            self.showLocalNotification(message)
        #endif
    }
    
    // DEBUG用
    private func showLocalNotification(message: String) {
        //LOG("showLocalNotification: \(message)")
        
        let localNotif = UILocalNotification()
        localNotif.userInfo = [ "Title": "AutoGPS", "Message": message ]
        localNotif.alertBody = message
        localNotif.alertAction = "OK"
        localNotif.hasAction = false
        localNotif.soundName = "Purr.aiff"
        
        UIApplication.sharedApplication().presentLocalNotificationNow(localNotif)
    }
}
