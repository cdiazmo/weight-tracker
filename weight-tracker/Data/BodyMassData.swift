//
//  BodyMassData.swift
//  Weight Tracker
//
//  Created by Carlos Diaz on 11/20/19.
//
import Foundation
import RealmSwift

class BodyMassData: Object {
    
    @objc dynamic var clientID: String = ""
    @objc dynamic var measure: Float = 0
    @objc dynamic var unitCode: String = "weight_kg"
    @objc dynamic var source: String = "Apple/Scale/Healthkit"
    @objc dynamic var recordedTimestamp: String?
    @objc dynamic var timeStamp: String = Date().formatted()
    @objc dynamic var sync: Bool = false
    @objc dynamic var invalidate: Bool = false

    override static func primaryKey() -> String? {
        return "clientID"
    }
    
    public func toJson() -> [String: Any] {
        var jsonObject = [String: Any]()
        jsonObject["clientID"] = clientID
        jsonObject["measure"] = measure
        jsonObject["unit-code"] = unitCode
        jsonObject["source"] = source
        jsonObject["timestamp"] = timeStamp
        jsonObject["recorded-timestamp"] = recordedTimestamp
        return jsonObject
    }
}

