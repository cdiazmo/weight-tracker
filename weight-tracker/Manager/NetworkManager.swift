//
//  NetworkManager.swift
//  Weight Tracker
//
//  Created by Carlos Diaz on 11/20/19.
//

import UIKit

import Alamofire
import RealmSwift
class NetworkManager {
    
    public static let shared = NetworkManager()
    private var listeningForNetworkChange: Bool = false
    var networkReachabilityManager: NetworkReachabilityManager?
    private init() {
        networkReachabilityManager = Alamofire.NetworkReachabilityManager()
        networkReachabilityManager?.listener = { status in
            if (status != .notReachable) {
                NotificationCenter.default.post(name: .networkStatusChanged, object: nil)
            }
        }
    }
    
    public func syncronize(url: String, upserts: Results<BodyMassData>, deletes: Results<BodyMassData>, completion: @escaping (_ success: Bool, _ upserts: [[String: Any]]?, _ deletes: [String]?)->Void ) {
        
        let headers: HTTPHeaders = ["Content-Type": "application/json"]
        let toDeletes = getArrayDelete(deletes: deletes)
        let toCreate = getArrayCreate(upserts: upserts)
        let json = getBody(upserts: toCreate, deletes: toDeletes)
        //print("Request: \(json)")
        Alamofire.request(url, method: .post, parameters: json, encoding: JSONEncoding.default, headers: headers).response { (response) in
//            if let data = response.data,
//                let json = try? JSONSerialization.jsonObject(with: data, options: []) {
//                print("Response: \(json)")
//            }
//
            switch (response.response?.statusCode ?? 0) {
            case 200 ... 299:
                completion(true, toCreate, toDeletes)
            default:
                completion(false, nil, nil)
            }
        }
    }
    
    public func getBody(upserts: [[String: Any]], deletes: [String]) -> [String: Any] {
        var json = [String: Any]()
        json["upserts"] = upserts
        json["deletes"] = deletes
        return json
    }
    
    func getArrayDelete(deletes: Results<BodyMassData>) -> [String] {
        var toDelete = [String]()
        for body in deletes {
            toDelete.append(body.clientID)
        }
        return toDelete
    }
    
    func getArrayCreate(upserts: Results<BodyMassData>) -> [[String: Any]] {
        var toCreate = [[String: Any]]()
        for body in upserts {
            toCreate.append(body.toJson())
        }
        return toCreate
    }
    
    public func isNetworkAvailable() -> Bool {
        let networkAvailable = networkReachabilityManager?.isReachable ?? false
        networkAvailable ? stopNotifier() : startNotifier()
        return networkAvailable
    }
    
    public func startNotifier() {
        if (!listeningForNetworkChange) {
            networkReachabilityManager?.startListening()
            listeningForNetworkChange = true
        }
    }
    
    public func stopNotifier() {
        if (listeningForNetworkChange) {
            networkReachabilityManager?.stopListening()
            listeningForNetworkChange = false
        }
    }
}
