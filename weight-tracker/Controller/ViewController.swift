//
//  ViewController.swift
//  Weight Tracker
//
//  Created by Carlos Diaz on 11/18/19.
//

import UIKit
import RealmSwift

class ViewController: UIViewController {
    
    var registerArray: Results<BodyMassData>?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateData), name: .newDataAvailable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.networkStatusChanged), name: .networkStatusChanged, object: nil)
        updateData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .newDataAvailable, object: nil)
        NotificationCenter.default.removeObserver(self, name: .networkStatusChanged, object: nil)
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        self.tableView.register(UINib(nibName: String(describing: BodyMassTableViewCell.self), bundle: nil), forCellReuseIdentifier:"dataCell")
    }
    
    @objc func updateData() {
        let dataManager = BodyMassManager()
        registerArray = dataManager.getAllElements()
        tableView.reloadData()
    }
    
    @objc func networkStatusChanged() {
        if NetworkManager.shared.isNetworkAvailable() {
            print("Network is back, scheduling sync...")
        //    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
                HealthKitManager.shared.syncronizeData { [weak self] (newData) in
                    DispatchQueue.main.async {
                        self?.updateData()
                    }
                }
        //    }
        } else {
            print("Network is still unavailable")
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return registerArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "dataCell") as? BodyMassTableViewCell else {
            return UITableViewCell()
        }
        if let data = registerArray?[indexPath.row] {
            
            cell.dateLabel.text = data.recordedTimestamp
            
            var weight = String(data.measure)
            switch data.unitCode {
            case "weight_kg":
                weight = String(format: "%.2f Kg", data.measure)
            case "weight_st":
                weight = String(format: "%.2f st", data.measure)
            case "weight_lb":
                weight = String(format: "%.2f lb", data.measure)
            default: break
            }
            
            cell.weightLabel.text = weight
            
            if #available(iOS 13.0, *) {
                cell.syncStatusImageView.image = (registerArray?[indexPath.row].sync ?? false) ? UIImage.init(systemName: "icloud.and.arrow.up.fill") : UIImage.init(systemName: "icloud.slash.fill")
            } else {
                let imageSize = cell.syncStatusImageView.frame.size
                cell.syncStatusImageView.image = (registerArray?[indexPath.row].sync ?? false) ? "✅".image(with: imageSize) : "🚫".image(with: imageSize)
            }
        }
        return cell
    }
}
