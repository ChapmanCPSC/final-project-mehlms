import UIKit
import CoreMotion
import CoreLocation

class Main: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var filter:[Waypoint] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.keyboardAppearance = .Dark
        let searchText = searchBar.valueForKey("searchField") as? UITextField
        searchText?.textColor = UIColor(white: 0.8, alpha: 1)
        searchText?.returnKeyType = .Done
        searchText?.enablesReturnKeyAutomatically = false
        
        promptLogIn()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        segmentChange(self)
        if Global.select {
            tableView(self.tableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
            Global.select = false
        }
    }
    
    func promptLogIn() {
        if Global.account == 0 {
            let alert = UIAlertController(title: "First time?", message:
                "Enter your 10 digit phone number to begin using Waypoint!", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addTextFieldWithConfigurationHandler({ (textField:UITextField) -> Void in
                textField.keyboardAppearance = .Dark
                textField.keyboardType = .NumberPad
                textField.textAlignment = .Center
            })
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                if alert.textFields![0].text!.characters.count == 10 {
                    Global.account = Int(alert.textFields![0].text!)!
                    self.restoreFromServer()
                } else {
                    self.promptLogIn()
                }
            }))
            self.navigationController!.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func restoreFromServer() {
        let parameters = "key=Cocokai1&account="+String(Global.account)
        let url = NSMutableURLRequest(URL: NSURL(string: "http://melms.net/waypoint/backup.php")!)
        url.HTTPMethod = "POST"
        url.HTTPBody = parameters.dataUsingEncoding(NSUTF8StringEncoding)
        NSURLSession.sharedSession().dataTaskWithRequest(url) { (data, response, error) -> Void in
            if error == nil {
                for line in NSString(data: data!, encoding: NSUTF8StringEncoding)!.componentsSeparatedByString("::") {
                    let array = line.componentsSeparatedByString(":")
                    if array.count == 5 {
                        let name = array[0]
                        let x = Double(array[1])!
                        let y = Double(array[2])!
                        let phone = Int(array[3])!
                        let status = Int(array[4])!
                        if status == 0 {
                            Global.waypointsPlaces.append(Waypoint(_name: name, _x: x, _y: y, _phone: phone, _status: status))
                        } else {
                            Global.waypointsPeople.append(Waypoint(_name: name, _x: x, _y: y, _phone: phone, _status: status))
                        }
                    }
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.updateFilter()
                    self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
                })
            }
        }.resume()
    }
    
    @IBAction func AddBtn(sender: AnyObject) {
        if Global.peoplePlaces == 0 {
            performSegueWithIdentifier("CreatePerson", sender: self)
        } else {
            performSegueWithIdentifier("CreatePlace", sender: self)
        }
    }
    
    @IBAction func segmentChange(sender: AnyObject) {
        Global.peoplePlaces = segmentControl.selectedSegmentIndex
        tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        view.endEditing(true)
        searchBar.text = ""
        updateFilter()
        tableView.reloadData()
    }
    
    internal func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell

        let waypoint = filter[indexPath.row]
        let x1 = Global.lastLocation.coordinate.latitude * M_PI/180.0
        let y1 = Global.lastLocation.coordinate.longitude * M_PI/180.0
        let x2 = waypoint.x * M_PI/180.0
        let y2 = waypoint.y * M_PI/180.0
        
        cell.textLabel?.text = waypoint.name.uppercaseString
        if waypoint.status == 1 {
            cell.detailTextLabel!.text = "START WAYPOINT"
        } else if waypoint.status == 2 {
            cell.detailTextLabel!.text = "ACCEPT OR DENY"
        } else if waypoint.status == 3 {
            cell.detailTextLabel!.text = "START WAYPOINT"
        } else if x1 == 0 && y1 == 0 {
            cell.detailTextLabel!.text = String(round(waypoint.distance*10)/10.0) + " MI"
        } else {
            waypoint.distance = 3959 * acos(sin(x1)*sin(x2) + cos(x1)*cos(x2)*cos(y1-y2))
            cell.detailTextLabel!.text = String(round(waypoint.distance*10)/10.0) + " MI"
        }
        return cell
    }
    
    internal func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.view.endEditing(true)
        
        Global.currentWaypoint = filter[indexPath.row]
        if Global.peoplePlaces == 0 {
            Global.waypointsPeople.insert(Global.waypointsPeople.removeAtIndex(Global.waypointsPeople.indexOf(Global.currentWaypoint)!), atIndex: 0)
        } else {
            Global.waypointsPlaces.insert(Global.waypointsPlaces.removeAtIndex(Global.waypointsPlaces.indexOf(Global.currentWaypoint)!), atIndex: 0)
        }
        
        performSegueWithIdentifier("Detail", sender: self)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            if Global.peoplePlaces == 0 {
                Global.waypointsPeople.removeAtIndex(Global.waypointsPeople.indexOf(filter[indexPath.row])!)
            } else {
                Global.waypointsPlaces.removeAtIndex(Global.waypointsPlaces.indexOf(filter[indexPath.row])!)
            }
            updateFilter()
            tableView.reloadData()
        }
    }
    
    internal func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filter.count
    }
    
    func updateFilter() {
        if Global.peoplePlaces == 0 {
            if searchBar.text == "" {
                filter = Global.waypointsPeople
            } else {
                filter = Global.waypointsPeople.filter() { $0.name.lowercaseString.containsString(searchBar.text!.lowercaseString) }
            }
        } else {
            if searchBar.text == "" {
                filter = Global.waypointsPlaces
            } else {
                filter = Global.waypointsPlaces.filter() { $0.name.lowercaseString.containsString(searchBar.text!.lowercaseString) }
            }
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        updateFilter()
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
}

class Global {
    static let defaults = NSUserDefaults.standardUserDefaults()
    
    static var account = 0
    static var waypointsPeople:[Waypoint] = []
    static var waypointsPlaces:[Waypoint] = []
    static var contacts:[Contact] = []
    
    static var peoplePlaces = 0
    static var currentWaypoint = Waypoint()
    
    static var motion = CMMotionManager()
    static var location = CLLocationManager()
    static var lastLocation = CLLocation()
    static var lastHeading:CLHeading?
    static let fps:Double = 15
    static var select = false
}
