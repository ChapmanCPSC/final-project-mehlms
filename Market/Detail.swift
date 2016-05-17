import UIKit

class Detail: UIViewController {

    @IBOutlet weak var arrow: UIImageView!
    @IBOutlet weak var ghost: UIView!
    @IBOutlet weak var distance: UILabel!
    
    var timer = NSTimer()
    var timer2 = NSTimer()
    var gyroToNorth = 0.0
    var calibrating = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(Detail.calibrate), name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        title = Global.currentWaypoint.name
        distance.text = ""
        
        arrow.image = arrow.image!.imageWithRenderingMode(.AlwaysTemplate)
        ghost.layer.anchorPoint = CGPoint(x: 1, y: 100)
        timer = NSTimer.scheduledTimerWithTimeInterval(1/Global.fps, target: self, selector: #selector(Detail.updateArrow), userInfo: nil, repeats: true)
        
        if Global.currentWaypoint.status == 1 {
            timer2 = NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: #selector(Detail.track), userInfo: nil, repeats: true)
            track()
        }
    }
    
    func track() {
        let parameters = "key=Cocokai1&account=\(Global.account)&account2=\(Global.currentWaypoint.phone)&x=\(Global.lastLocation.coordinate.latitude)&y=\(Global.lastLocation.coordinate.longitude)"
        let url = NSMutableURLRequest(URL: NSURL(string: "http://melms.net/waypoint/track.php")!)
        url.HTTPMethod = "POST"
        url.HTTPBody = parameters.dataUsingEncoding(NSUTF8StringEncoding)
        
        NSURLSession.sharedSession().dataTaskWithRequest(url) { (data, response, error) -> Void in
            if error == nil {
                let array = NSString(data: data!, encoding: NSUTF8StringEncoding)!.componentsSeparatedByString(":")
                if array.count == 2 {
                    let x = Double(array[0])!
                    let y = Double(array[1])!
                    Global.currentWaypoint.x = x
                    Global.currentWaypoint.y = y
                }
            }
        }.resume()
    }
    
    @IBAction func calibrateBtn(sender: AnyObject) {
        arrow.tintColor = UIColor(red: 229/255.0, green: 169/255.0, blue: 0, alpha: 1)
        calibrate()
    }
    
    func calibrate() {
        if !calibrating {
            calibrating = true
            Global.motion.stopDeviceMotionUpdates()
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                Global.motion.startDeviceMotionUpdates()
                if var heading = Global.lastHeading?.trueHeading {
                    heading = -heading*M_PI/180
                    self.gyroToNorth = (heading+4*M_PI) % (2*M_PI)
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                    self.calibrating = false
                    self.arrow.tintColor = UIColor.whiteColor()
                }
            }
        }
    }
    
    func updateArrow() {
        if !calibrating {
            if let gyro = Global.motion.deviceMotion?.attitude {
                let x1 = Global.lastLocation.coordinate.latitude * M_PI/180.0
                let y1 = Global.lastLocation.coordinate.longitude * M_PI/180.0
                let x2 = Global.currentWaypoint.x * M_PI/180.0
                let y2 = Global.currentWaypoint.y * M_PI/180.0
                
                Global.currentWaypoint.distance = 3959 * acos(sin(x1)*sin(x2) + cos(x1)*cos(x2)*cos(y1-y2))
                if Global.currentWaypoint.distance >= 10 {
                    self.distance.text = "\(Int(round(Global.currentWaypoint.distance))) mi"
                } else if Global.currentWaypoint.distance*5280 > 999 {
                    self.distance.text = "\(round(Global.currentWaypoint.distance*10)/10.0) mi"
                } else if Global.currentWaypoint.distance*5280 <= 20 {
                    self.distance.text = "u there"
                } else {
                    self.distance.text = "\(Int(Global.currentWaypoint.distance * 5280)) ft"
                }
                
                let bearing = atan2(y2 - y1, log(tan(x2/2 + M_PI/4) / tan(x1/2 + M_PI/4)))
                
                if Global.motion.deviceMotion?.gravity.z < -0.6 {
                    if var heading = Global.lastHeading?.trueHeading {
                        heading = -heading*M_PI/180+4*M_PI
                        let target = (heading - gyro.yaw) % (2*M_PI)
                        if target - gyroToNorth > M_PI {
                            gyroToNorth += 2*M_PI
                        } else if gyroToNorth - target > M_PI {
                            gyroToNorth -= 2*M_PI
                        }
                        gyroToNorth += (target - gyroToNorth) * 0.08
                    }
                }

                let x = CATransform3DMakeRotation(CGFloat(gyro.pitch), 1, 0, 0)
                let y = CATransform3DMakeRotation(CGFloat(-gyro.roll), 0, 1, 0)
                let z = CATransform3DMakeRotation(CGFloat(gyroToNorth+gyro.yaw+bearing), 0, 0, 1)
                self.ghost.layer.transform = CATransform3DConcat(CATransform3DConcat(z, x), y)
                let rot = CGFloat(M_PI/2) + atan2(self.ghost.frame.origin.y-self.ghost.center.y, self.ghost.frame.origin.x-self.ghost.center.x)
                
                UIView.animateWithDuration(1.5/Global.fps) { () -> Void in
                    self.arrow.transform = CGAffineTransformMakeRotation(rot)
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        Global.motion.startDeviceMotionUpdates()
        if var heading = Global.lastHeading?.trueHeading {
            heading = -heading*M_PI/180
            gyroToNorth = (heading+4*M_PI) % (2*M_PI)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        timer.invalidate()
        if Global.currentWaypoint.status == 1 {
            timer2.invalidate()
        }
        Global.motion.stopDeviceMotionUpdates()
    }
}
