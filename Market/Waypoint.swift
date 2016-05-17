import Foundation
import UIKit

class Waypoint: NSObject, NSCoding {
    var name: String
    var x: Double
    var y: Double
    var distance: Double
    var phone: Int
    var status: Int // 0 - Place, 1 - Invite Sent, 2 - Invite Recieved, 3 - Paired
    
    override init() {
        name = ""
        x = 0.0
        y = 0.0
        distance = 0.0
        phone = 0
        status = 0
    }
    
    init(_name: String, _x: Double, _y: Double, _distance: Double) {
        name = _name
        x = _x
        y = _y
        distance = _distance
        phone = 0
        status = 0
    }
    
    init(_name: String, _phone: Int) {
        name = _name
        x = 0.0
        y = 0.0
        distance = 0.0
        phone = _phone
        status = 1
    }
    
    init(_name: String, _x: Double, _y: Double, _phone: Int, _status:Int) {
        name = _name
        x = _x
        y = _y
        distance = 0
        phone = _phone
        status = _status
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(name, forKey: "name")
        aCoder.encodeObject(x, forKey: "x")
        aCoder.encodeObject(y, forKey: "y")
        aCoder.encodeObject(distance, forKey: "distance")
        aCoder.encodeObject(phone, forKey: "phone")
        aCoder.encodeObject(status, forKey: "status")
    }
    
    required init?(coder aDecoder: NSCoder) {
        name = aDecoder.decodeObjectForKey("name") as! String
        x = aDecoder.decodeObjectForKey("x") as! Double
        y = aDecoder.decodeObjectForKey("y") as! Double
        distance = aDecoder.decodeObjectForKey("distance") as! Double
        phone = aDecoder.decodeObjectForKey("phone") as! Int
        status = aDecoder.decodeObjectForKey("status") as! Int
    }
    
    func saveString() -> String {
        return "\(name):\(x):\(y):\(phone):\(status)::"
    }
}