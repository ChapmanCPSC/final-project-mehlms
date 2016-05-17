import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // LOAD DATA
        if let account = Global.defaults.objectForKey("account") {
            Global.account = account as! Int
            
            if let data = Global.defaults.objectForKey("waypointsPeople") {
                Global.waypointsPeople = NSKeyedUnarchiver.unarchiveObjectWithData(data as! NSData) as! [Waypoint]
            }
            if let data = Global.defaults.objectForKey("waypointsPlaces") {
                Global.waypointsPlaces = NSKeyedUnarchiver.unarchiveObjectWithData(data as! NSData) as! [Waypoint]
            }
            if let data = Global.defaults.objectForKey("contacts") {
                Global.contacts = NSKeyedUnarchiver.unarchiveObjectWithData(data as! NSData) as! [Contact]
            }
        }
    
        // STYLING
        let selectionView = UIView()
        selectionView.backgroundColor = UIColor(white: 0.6, alpha: 1)
        UITableViewCell.appearance().selectedBackgroundView = selectionView
        
        // START GYRO
        if Global.motion.deviceMotionAvailable {
            Global.motion.deviceMotionUpdateInterval = 1/Global.fps
        }
        
        // START LOCATION
        Global.location.delegate = self
        Global.location.requestWhenInUseAuthorization()
        
        return true
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        if Global.account != 0 {
            // SAVE DATA LOCALLY
            Global.defaults.setObject(Global.account, forKey: "account")
            Global.defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(Global.waypointsPeople), forKey: "waypointsPeople")
            Global.defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(Global.waypointsPlaces), forKey: "waypointsPlaces")
            Global.defaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(Global.contacts), forKey: "contacts")
            
            // SAVE DATA REMOTE
            var dataString = ""
            for waypoint in Global.waypointsPeople+Global.waypointsPlaces {
                dataString += waypoint.saveString()
            }
            let parameters = "key=Cocokai1&account="+String(Global.account)+"&data="+dataString
            let url = NSMutableURLRequest(URL: NSURL(string: "http://melms.net/waypoint/backup.php")!)
            url.HTTPMethod = "POST"
            url.HTTPBody = parameters.dataUsingEncoding(NSUTF8StringEncoding)
            
            NSURLSession.sharedSession().dataTaskWithRequest(url) { (data, response, error) -> Void in
                //
            }.resume()
        }
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse || status == CLAuthorizationStatus.AuthorizedAlways {
            Global.location.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            Global.location.startUpdatingLocation()
            Global.location.startUpdatingHeading()
        } else {
            let alert = UIAlertController(title: "Features Disabled", message:
                "Enable Location in Settings -> Waypoint to use this app.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            }) )
            UIApplication.sharedApplication().windows.first?.rootViewController!.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Global.lastLocation = locations[0]
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Global.lastHeading = newHeading
    }
}

