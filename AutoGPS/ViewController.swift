//
//  ViewController.swift
//  AutoGPS
//
//  Created by TashiroTomohiro on 2016/02/15.
//  Copyright © 2016年 Weathernews. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    @IBOutlet weak var autoGPSsw :UISwitch!
    @IBOutlet weak var infoLabel :UILabel!
    @IBOutlet weak var serverLabel :UILabel!
    @IBOutlet weak var mapView :MKMapView!
    
    private let dateFormatter = NSDateFormatter()

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "locationUpdated", name: AutoGPS.sharedInstance.notificationKey, object: nil)
        
        self.dateFormatter.locale = NSLocale.systemLocale()
        self.dateFormatter.dateFormat = "HH:mm:ss"
        self.infoLabel.text = "starting GPS..."
        self.serverLabel.text = ""
        
        self.autoGPSsw.on = AutoGPS.sharedInstance.autoGPSenabled
        self.autoGPSsw.addTarget(self, action: "swChanged", forControlEvents: .ValueChanged)
        
        self.mapView.showsUserLocation = true
        self.mapView.userTrackingMode = .Follow
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func locationUpdated() {
        LOG(__FUNCTION__)
        let autoGPS = AutoGPS.sharedInstance
        self.infoLabel.text = String(format: "📡[%@] lat:%.4f, lon:%.4f",
            self.dateFormatter.stringFromDate(autoGPS.gpsDate!), autoGPS.gpslat, autoGPS.gpslon)
        
        self.serverLabel.text = String(format: "🏢[%@] lat:%.4f, lon:%.4f\ninterval: %.0fsec.",
            self.dateFormatter.stringFromDate(autoGPS.lastReportDate),
            autoGPS.lastReportLocation.coordinate.latitude,
            autoGPS.lastReportLocation.coordinate.longitude,
            autoGPS.autoGPSinterval)
    }
    
    func swChanged() {
        LOG( String(format: "%@ :%@", __FUNCTION__, self.autoGPSsw.on ? "On":"Off" ) )
        AutoGPS.sharedInstance.autoGPSenabled = self.autoGPSsw.on
    }
}

