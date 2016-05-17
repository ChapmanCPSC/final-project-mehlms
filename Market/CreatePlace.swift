import UIKit
import MapKit

class CreatePlace: UIViewController, MKMapViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var nav: UINavigationBar!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var arrow: UIImageView!
    @IBOutlet weak var nameField: UITextField!
    
    var center = CLLocationCoordinate2D()
    var willShowKeyBoard = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        map.setRegion(MKCoordinateRegionMakeWithDistance(Global.lastLocation.coordinate, 0, 5000), animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        map.setRegion(MKCoordinateRegionMakeWithDistance(Global.lastLocation.coordinate, 0, 200), animated: true)
        willShowKeyBoard = true
    }
    
    @IBAction func TapOnNav(sender: AnyObject) {
        nameField.becomeFirstResponder()
    }
    
    @IBAction func Done(sender: AnyObject) {
        for i in 0 ..< Global.waypointsPlaces.count {
            if nav.topItem!.title!.lowercaseString == Global.waypointsPlaces[i].name.lowercaseString {
                Global.waypointsPlaces.removeAtIndex(i)
                break
            }
        }
        
        var distance = 0.0
        if Global.lastLocation.coordinate.latitude != 0 {
            let x1 = Global.lastLocation.coordinate.latitude * M_PI/180.0
            let y1 = Global.lastLocation.coordinate.longitude * M_PI/180.0
            let x2 = self.center.latitude * M_PI/180.0
            let y2 = self.center.longitude * M_PI/180.0
            distance = 3959 * acos(sin(x1)*sin(x2) + cos(x1)*cos(x2)*cos(y1-y2))
        }
        
        Global.waypointsPlaces.insert(Waypoint(_name: nav.topItem!.title!, _x: self.center.latitude, _y: self.center.longitude, _distance: distance), atIndex: 0)
        Global.select = true
        self.view.endEditing(true)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onTextChange(sender: AnyObject) {
        if nameField.text! == "" {
            nav.topItem!.title = "Waypoint"
        } else {
            nav.topItem!.title = nameField.text!
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        self.view.endEditing(true)
        center = map.centerCoordinate
        if willShowKeyBoard {
            nameField.becomeFirstResponder()
            willShowKeyBoard = false
        }
    }
    
    @IBAction func Close(sender: AnyObject) {
        self.view.endEditing(true)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
