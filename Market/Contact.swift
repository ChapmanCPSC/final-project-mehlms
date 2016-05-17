import Foundation

class Contact: NSObject, NSCoding {
    var name: String
    var phone: Int
    
    init(_name:String) {
        name = _name
        phone = 0
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(name, forKey: "name")
        aCoder.encodeObject(phone, forKey: "phone")
    }
    
    required init?(coder aDecoder: NSCoder) {
        name = aDecoder.decodeObjectForKey("name") as! String
        phone = aDecoder.decodeObjectForKey("phone") as! Int
    }
}