//
//  FlowersViewController.swift
//  Flowers
//
//  Created by PID-PRODUCTENGINEER-EO2180 on 10/11/21.
//

import UIKit

class FlowersViewController: UIViewController {
    @IBOutlet weak var flowerTableView: UITableView!
    
    var flowers: [Flower] = [Flower]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Flower List"
        
        flowers = FlowerManager().getFlowers()
        
        flowerTableView.register(UITableViewCell.self, forCellReuseIdentifier: "flowerCell")
        
        flowerTableView.delegate = self
        flowerTableView.dataSource = self
    }
    

}

extension FlowersViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flowers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "flowerCell")
        let data = flowers[indexPath.row]
        
        cell.textLabel?.text = data.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let flower = flowers[indexPath.row]
        
        if let vc = storyboard.instantiateViewController(withIdentifier: "FlowerDetailsViewController") as? FlowerDetailsViewController {
            vc.flowerImage = flower.name
            vc.flowerTitle = flower.name
            vc.flowerDescription = flower.description
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}
