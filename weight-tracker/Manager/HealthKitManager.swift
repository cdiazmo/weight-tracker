//
//  HealthKitManager.swift
//  Weight Tracker
//
//  Created by Carlos Diaz on 11/19/19.
//

import UIKit
import HealthKit
class HealthKitManager {
    
    public static let shared = HealthKitManager()
    
    public let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
    private let operationQueue = DispatchQueue(label: "SynchronizedAccess", attributes: .concurrent)
    private let semaphore = DispatchSemaphore(value: 0)
    private init() {}
    
    public lazy var healthStore: HKHealthStore = {
        return HKHealthStore()
    }()
    
    public func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    public func requestAuthorization (completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        let allTypes = Set([bodyMassType])
        healthStore.requestAuthorization(toShare: [], read: allTypes) { (success, error) in
            completion(success, error)
        }
    }
    
    public func enableBackgroundDelivery(completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        self.healthStore.enableBackgroundDelivery(for: bodyMassType, frequency: .immediate) { (success, error) in
            completion(success, error)
        }
    }
    
    public func registerQuery(cleanStart: Bool = false, completion: ((_ newData: Bool) -> Void)? = nil) {
        queryBodyMass(cleanStart: cleanStart, completion: { newData in
            DispatchQueue.main.async {
                if newData {
                    NotificationCenter.default.post(name: .newDataAvailable, object: nil)
                }
            }
            completion?(newData)
        })
    }
    
    public func queryBodyMass(cleanStart: Bool, completion: @escaping (_ newData: Bool) -> Void) {
        var anchor = getAnchor()
        let query = HKAnchoredObjectQuery(type: bodyMassType,
                                          predicate: getDatePredicate(cleanStart: cleanStart),
                                          anchor: anchor,
                                          limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, newAnchor, error) in
                                            guard let samples = samples, let deletedObjects = deletedObjects else {
                                                completion(false)
                                                return
                                            }
                                            anchor = newAnchor!
                                            self.updateAnchor(newAnchor: newAnchor)
                                            self.processFetchedResults(addedSamples: samples, removedSamples: deletedObjects) { newData in
                                                completion(newData)
                                            }
        }
        
        query.updateHandler = { (query, samples, deletedObjects, newAnchor, error) in
            guard let samples = samples, let deletedObjects = deletedObjects else {
                completion(false)
                return
            }
            self.operationQueue.async{
                anchor = newAnchor!
                self.updateAnchor(newAnchor: newAnchor)
                self.processFetchedResults(addedSamples: samples, removedSamples: deletedObjects) { newData in
                    completion(newData)
                    self.semaphore.signal()
                }
            }
            self.semaphore.wait()
        }
        healthStore.execute(query)
    }
    
    func getDatePredicate(cleanStart: Bool) -> NSPredicate? {
        if cleanStart {
            var date: Date
            if let installTime = UserDefaults.standard.value(forKey: "installDate") as? Double {
                date = Date(timeIntervalSince1970: installTime)
            } else {
                date = Date()
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "installDate")
            }
            return HKQuery.predicateForSamples(withStart: date, end: nil, options: .strictStartDate)
        }
        return nil
    }
    
    private func processFetchedResults(addedSamples: [HKSample]?, removedSamples: [HKDeletedObject]?, completion: @escaping (_ newData: Bool) -> Void) {
        print("Fetching elements from Health Kit...")
        let manager = BodyMassManager()
        _ = manager.createBodyMass(from: addedSamples)
        manager.setInvalidateBodyMass(for: removedSamples)
        self.syncronizeData { newData in
            completion(newData)
        }
        
    }
    
    public func syncronizeData(completion: @escaping (_ newData: Bool) -> Void) {
        
        operationQueue.async {
            self.semaphore.signal()
            let url = "<url to send data>"
            let manager = BodyMassManager()
            let toCreate = manager.getUnsyncBodyMass()
            let toRemove = manager.getInvalidatedBodyMass()
            if (!toCreate.isEmpty || !toRemove.isEmpty) {
                if NetworkManager.shared.isNetworkAvailable() {
                    print("Syncronizing data...")
                    NetworkManager.shared.syncronize(url: url, upserts: toCreate, deletes: toRemove) { (success, created, removed) in
                        if success {
                            manager.syncronize(created: created, deleted: removed)
                            print("Data syncronized with success!")
                        } else {
                            print("There was an error while syncing the registers")
                        }
                        self.semaphore.signal()
                        completion(true)
                    }
                } else {
                    print("There is data to sync but the network is not available")
                    self.semaphore.signal()
                    completion(true)
                }
            } else {
                self.semaphore.signal()
                print("Nothing to sync!")
                completion(false)
            }
        }
        semaphore.wait()
    }
}

extension HealthKitManager {
    func updateAnchor(newAnchor: HKQueryAnchor?) {
        let data : Data = NSKeyedArchiver.archivedData(withRootObject: newAnchor as Any)
        UserDefaults.standard.set(data, forKey: "Anchor")
    }
    
    func getAnchor() -> HKQueryAnchor {
        if let data = UserDefaults.standard.object(forKey: "Anchor") as? Data, let anchor = NSKeyedUnarchiver.unarchiveObject(with: data) as? HKQueryAnchor {
            return anchor
        }
        return HKQueryAnchor.init(fromValue: 0)
    }
}
