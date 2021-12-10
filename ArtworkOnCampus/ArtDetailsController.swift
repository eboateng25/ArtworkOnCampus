//
//  artDetailsController.swift
//  ArtworkOnCampus
//
//  Created by Boateng, Emanuel on 10/12/2021.
//

import UIKit

class ArtDetailsController: UIViewController {

    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var yearOfWorkLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    var artistText : String = ""
    var nameText: String = ""
    var yearOfWorkText : String = ""
    var descriptionText : String = ""
    var locationText : String = ""
    
    var imageURL : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        artistLabel.text = "By \(artistText)"
        nameLabel.text = "\(nameText)"
        if(yearOfWorkText != ""){
            yearOfWorkLabel.text = "Made in \(yearOfWorkText)"
        } else{
            yearOfWorkLabel.text = ""
        }
        descriptionLabel.text = "\(descriptionText)"
        var fullImageURL : String = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP228/artwork_images/\(imageURL)"
        fullImageURL = fullImageURL.replacingOccurrences(of: " ", with: "%20") // Replace spaces in URL
        downloadImage(url: URL(string: fullImageURL)!) // Download image
        locationLabel.text = "\(locationText)"
    }
    
    func downloadImage(url: URL) {
        let session = URLSession.shared
        session.dataTask(with: url) { (data, response, err) in
            guard let imageData = data else {
                return
            }
            do {
                DispatchQueue.main.async {
                    self.image.image = UIImage(data: imageData)
                }
            }
        }.resume()
    }

}
