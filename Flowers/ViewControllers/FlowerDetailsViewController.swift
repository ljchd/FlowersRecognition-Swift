//
//  FlowerDetailsViewController.swift
//  Flowers
//
//  Created by PID-PRODUCTENGINEER-EO2180 on 10/11/21.
//

import UIKit

class FlowerDetailsViewController: UIViewController {
    
    @IBOutlet weak var flowerImageView: UIImageView!
    @IBOutlet weak var flowerTitleLabel: UILabel!
    @IBOutlet weak var flowerDescriptionLabel: UILabel!
    
    var flowerImage: String = ""
    var flowerTitle: String = ""
    var flowerDescription: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

//         Image
        flowerImageView.image = UIImage(named: flowerImage)
        flowerImageView.layer.cornerRadius = flowerImageView.frame.height / 2
        flowerImageView.contentMode = .scaleAspectFill

//         Title
        flowerTitleLabel.text = flowerTitle
        flowerTitleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        flowerTitleLabel.textAlignment = .left
        flowerTitleLabel.numberOfLines = 0

        // Description
        flowerDescriptionLabel.text = flowerDescription
        flowerDescriptionLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        flowerDescriptionLabel.textAlignment = .justified
        flowerDescriptionLabel.numberOfLines = 0
    }

}
