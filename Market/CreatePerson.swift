import UIKit
import Contacts

class CreatePerson: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var tempContacts:[Contact] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let store = CNContactStore()
        let id = store.defaultContainerIdentifier()
        let predicate: NSPredicate = CNContact.predicateForContactsInContainerWithIdentifier(id)
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        
        do {
            var cncontacts = try store.unifiedContactsMatchingPredicate(predicate, keysToFetch: keys)
            cncontacts.sortInPlace {$0.givenName.localizedCaseInsensitiveCompare($1.givenName) == NSComparisonResult.OrderedAscending}
            var parameters = ""
            
            for i in 0 ..< cncontacts.count {
                let name = "\(cncontacts[i].givenName.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).capitalizedString) \(cncontacts[i].familyName.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).capitalizedString)".stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                if cncontacts[i].phoneNumbers.count >= 1 && name != "" {
                    tempContacts.append(Contact(_name: name))
                    for labeledValue in cncontacts[i].phoneNumbers {
                        let numberObject = labeledValue.value as! CNPhoneNumber
                        var number = numberObject.stringValue.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("")
                        if number.characters.count > 10 {
                            number = number[number.endIndex.advancedBy(-10) ..< number.endIndex]
                        }
                        parameters += "\(self.tempContacts.count-1):\(number)::"
                    }
                }
            }
            fetchUsersUsingWaypoint(parameters)
        } catch { }
    }

    func fetchUsersUsingWaypoint(dataString:String) {
        let parameters = "key=Cocokai1&data=" + dataString
        let url = NSMutableURLRequest(URL: NSURL(string: "http://melms.net/waypoint/accounts.php")!)
        url.HTTPMethod = "POST"
        url.HTTPBody = parameters.dataUsingEncoding(NSUTF8StringEncoding)
        
        NSURLSession.sharedSession().dataTaskWithRequest(url) { (data, response, error) -> Void in
            Global.contacts.removeAll()
            if error == nil {
                for line in NSString(data: data!, encoding: NSUTF8StringEncoding)!.componentsSeparatedByString("::") {
                    let array = line.componentsSeparatedByString(":")
                    if array.count == 2 {
                        let i = Int(array[0])!
                        let phone = Int(array[1])!
                        self.tempContacts[i].phone = phone
                        var shouldAdd = true
                        for waypoint in Global.waypointsPeople {
                            if waypoint.phone == phone {
                                shouldAdd = false
                                break
                            }
                        }
                        if shouldAdd {
                            Global.contacts.append(self.tempContacts[i])
                        }
                    }
                }
            } else {
                let alert = UIAlertController(title: "Feature Disabled", message:
                    "An internet connection is required to use this feature.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    self.dismissViewControllerAnimated(true, completion: nil)
                }) )
                self.presentViewController(alert, animated: true, completion: nil)
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
            })
        }.resume()
    }
    
    override func viewDidAppear(animated: Bool) {
        if CNContactStore.authorizationStatusForEntityType(.Contacts) != CNAuthorizationStatus.Authorized {
            let alert = UIAlertController(title: "Feature Disabled", message: "Enable Contacts in Settings -> Waypoint to use this feature.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
            }) )
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    internal func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Global.contacts.count
    }
    
    internal func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        cell.textLabel?.text = "\(Global.contacts[indexPath.row].name)"
        return cell
    }
    
    internal func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let contact = Global.contacts.removeAtIndex(indexPath.row)
        let waypoint = Waypoint(_name: contact.name, _phone: contact.phone)
        Global.waypointsPeople.insert(waypoint, atIndex: 0)
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)
    }
    
    @IBAction func Close(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
