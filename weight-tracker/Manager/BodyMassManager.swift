//
//  BodyMassManager.swift
//  Weight Tracker
//
//  Created by Carlos Diaz on 11/20/19.
//

import UIKit
import RealmSwift
import HealthKit
class BodyMassManager {
    
    var realm: Realm!
    
    init() {
        realm = try! Realm()
    }
    
    func createBodyMass(from array: [HKSample]?) -> [BodyMassData] {
        var arrayOfElements = [BodyMassData]()
        for sample in array ?? [] {
            if let object = createBodyMass(from: sample) {
                arrayOfElements.append(object)
            }
        }
        if (!arrayOfElements.isEmpty) {
            try! realm.write {
                realm.add(arrayOfElements, update: .modified)
            }
        }
        return arrayOfElements
    }
    
    func createBodyMass(from sample: HKSample) -> BodyMassData? {
        if let quantitySample = sample as? HKQuantitySample {
            let measurement = Float(quantitySample.quantity.doubleValue(for: HKUnit.gram()) / 1000.0)
            let dateRegistered = quantitySample.endDate.formatted()
            let bodyMass = BodyMassData()
            bodyMass.clientID = quantitySample.uuid.uuidString
            bodyMass.measure = measurement
            bodyMass.recordedTimestamp = dateRegistered
            return bodyMass
        }
        return nil
    }
    
    func deleteBodyMass(for deleted: HKDeletedObject?) {
        if let clientID = deleted?.uuid.uuidString, let object = getBodyMass(by: clientID).first {
            try! realm.write {
                realm.delete(object)
            }
        }
    }
    
    func deleteBodyMass(for array: [HKDeletedObject?]?) -> [String] {
        var clientIDs = [String]()
        var stringToSearch = ""
        for object in array ?? [] {
            if let clientID = object?.uuid.uuidString {
                if !stringToSearch.hasSuffix(" OR ") && !stringToSearch.isEmpty {
                    stringToSearch += " OR "
                }
                stringToSearch += "clientID = '\(clientID)'"
                clientIDs.append(clientID)
            }
        }
        if(stringToSearch != "") {
            let objects = realm.objects(BodyMassData.self).filter(stringToSearch)
            if !objects.isEmpty {
                try! realm.write {
                    realm.delete(objects)
                }
            }
        }
        return clientIDs
    }
    
    
    func getBodyMass(by id: String) -> Results<BodyMassData> {
        return realm.objects(BodyMassData.self).filter("clientID = '\(id)'")
    }
    
    func getUnsyncBodyMass() -> Results<BodyMassData> {
        return realm.objects(BodyMassData.self).filter("sync = false AND invalidate = false")
    }
    
    func getInvalidatedBodyMass() -> Results<BodyMassData> {
        return realm.objects(BodyMassData.self).filter("invalidate = true")
    }
    
    func getAllElements() -> Results<BodyMassData> {
        return realm.objects(BodyMassData.self).sorted(byKeyPath: "recordedTimestamp")
    }
    
    func setInvalidateBodyMass(for array: [HKDeletedObject?]?) {
        var clientIDs = [String]()
        var stringToSearch = ""
        for object in array ?? [] {
            if let clientID = object?.uuid.uuidString {
                if !stringToSearch.hasSuffix(" OR ") && !stringToSearch.isEmpty {
                    stringToSearch += " OR "
                }
                stringToSearch += "clientID = '\(clientID)'"
                clientIDs.append(clientID)
            }
        }
        
        if(stringToSearch != "") {
            let objects = realm.objects(BodyMassData.self).filter(stringToSearch)
            if !objects.isEmpty {
                try! realm.write {
                    for bodyMass in objects {
                        if(bodyMass.sync){
                            bodyMass.sync = false
                            bodyMass.invalidate = true
                        } else {
                            realm.delete(bodyMass)
                        }
                    }
                }
            }
        }
    }
    
    func deleteBodyMass(for array: [String]?) {
        var clientIDs = [String]()
        var stringToSearch = ""
        for clientID in array ?? [] {
            if !stringToSearch.hasSuffix(" OR ") && !stringToSearch.isEmpty {
                stringToSearch += " OR "
            }
            stringToSearch += "clientID = '\(clientID)'"
            clientIDs.append(clientID)
        }
        if(stringToSearch != "") {
            let realm = try! Realm()
            
            let objects = realm.objects(BodyMassData.self).filter(stringToSearch)
            if !objects.isEmpty {
                try! realm.write {
                    realm.delete(objects)
                }
            }
        }
    }
    
    func updateBodyMass(for array: [[String:Any]]?) {
        var clientIDs = [String]()
        var stringToSearch = ""
        for object in array ?? [] {
            if let clientID = object["clientID"] as? String {
                if !stringToSearch.hasSuffix(" OR ") && !stringToSearch.isEmpty {
                    stringToSearch += " OR "
                }
                stringToSearch += "clientID = '\(clientID)'"
                clientIDs.append(clientID)
            }
        }
        if(stringToSearch != "") {
            let realm = try! Realm()
            
            let objects = realm.objects(BodyMassData.self).filter(stringToSearch)
            if !objects.isEmpty {
                try! realm.write {
                    for created in objects {
                        created.sync = true
                    }
                }
            }
        }
    }
    
    func syncronize(created: [[String:Any]]?, deleted: [String]?) {
        DispatchQueue.main.async {
            autoreleasepool{
                self.updateBodyMass(for: created)
                self.deleteBodyMass(for: deleted)
            }
        }
    }
    
}

