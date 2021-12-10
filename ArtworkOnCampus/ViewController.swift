//
//  ViewController.swift
//  ArtworkOnCampus
//
//  Created by Boateng, Emanuel on 07/12/2021.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var myMap: MKMapView!
    
    @IBOutlet weak var myTable: UITableView!
    
    var locationManager = CLLocationManager()
    
    var firstRun = true
    var startTrackingTheUser = false
    
    var campusartList : campusarts? = nil
    var locations : [String : [campusart]] = [:]
    var thumbnails : [String: UIImage] = [:]
    
    var selectedCampusInfo: campusart? = nil
    
    // Set number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.locations.count
    }
    
    // Set header titles
    func tableView(_ tableView: UITableView, titleForHeaderInSection
                    section: Int) -> String? {
        if(self.locations.count != 0){
            return Array(self.locations.keys)[section]
        }
        
        else {return ""}

    }
    
    // Sets number of rows needed per section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.locations[Array(self.locations.keys)[section]]!.count
    }
    
    // Set individual cell settings
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Init a custom cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell") as! CustomTableViewCell
        
        // Get campus artwork based on current section we are on
        let campusArtWork = locations[Array(self.locations.keys)[indexPath.section]]![indexPath.row]
        
        // Send over custom cell settings
        cell.thumbnailImage.image = thumbnails[campusArtWork.thumbnail]
        cell.titleLabel.text = campusArtWork.title
        cell.artistLabel.text = campusArtWork.artist
        
        return cell
    }
    
    // Prepare segue by sending artwork data over to ArtDetailsController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "toArtDetail"){
            let artDetailsViewController = segue.destination as! ArtDetailsController
            artDetailsViewController.artistText = selectedCampusInfo!.artist
            artDetailsViewController.yearOfWorkText =
                selectedCampusInfo!.yearOfWork
            artDetailsViewController.descriptionText = selectedCampusInfo!.Information
            artDetailsViewController.nameText = selectedCampusInfo!.title
            artDetailsViewController.imageURL = selectedCampusInfo!.ImagefileName
            artDetailsViewController.locationText = selectedCampusInfo!.location
        }
    }
    
    // If we select a cell send user to art details
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Set selected campus variable
        selectedCampusInfo = locations[Array(self.locations.keys)[indexPath.section]]![indexPath.row]
        performSegue(withIdentifier: "toArtDetail", sender: nil)
    }

    // Adds annotations to the map
    func addMapAnnotations(map: MKMapView!, campusarts: campusarts?){
        var artworkLocations : [artworkLocation] = []
        // Gather artworkLocations that is feteched from getCampusInfo
        if(campusarts != nil){
            for i in 0...(campusarts?.campusart.count)! - 1 {
                let location : String = (campusarts?.campusart[i].locationNotes)!
                let lat : Double =  Double((campusarts?.campusart[i].lat)!)!
                let long: Double = Double((campusarts?.campusart[i].long)!)!
                let artworklocation = artworkLocation(name: location, lat: lat, long: long)
                
                if(campusarts?.campusart[i].enabled == "1"){
                    artworkLocations.append(artworklocation)
                }
                
            }
        }
        
        for artworkLocation in artworkLocations {
            let annotations = MKPointAnnotation()
            annotations.title = artworkLocation.name
            annotations.coordinate = CLLocationCoordinate2D(latitude:
                                                                artworkLocation.lat, longitude: artworkLocation.long)
            map.addAnnotation(annotations)
        }
    }
    
    // Groups campusarts by location notes
    func updateLocations(campusarts: campusarts?) -> [String : [campusart]]{
        var locations : [String : [campusart]] = [:]
        if(campusarts != nil){
            for i in 0...(campusarts?.campusart.count)! - 1 {
                let location : String = (campusarts?.campusart[i].locationNotes)!
                var campusartsInLocation : [campusart] = []
                for j in 0...(campusarts?.campusart.count)! - 1 {
                    if campusarts?.campusart[j].locationNotes ==  location && campusarts?.campusart[j].enabled == "1" {
                        campusartsInLocation.append((campusarts?.campusart[j])!)
                        // Download thumbnail image
                        self.downloadThumbnailImage(thumbnail: (campusarts?.campusart[j].thumbnail)!)
                    }
                }
                
                // Download thumbnail image here
                locations[location] = campusartsInLocation
            }
        }
        return locations
    }
    
    // Updates table groupings and map. Function is carried out anytime campus data is fetech
    func updateData(){
        // Map out locations on map
        addMapAnnotations(map: myMap, campusarts: campusartList)
        
        // Update the different locations available
        self.locations = updateLocations(campusarts: campusartList)
        
        // Update table
        myTable.reloadData()
        
        print("UPDATING...")
    }
    
    // Function douwnloads thumbnails and stores locally in a dictionary called thumbnails. Image data is accessed through name of thumbnail
    func downloadThumbnailImage(thumbnail: String) {
        let session = URLSession.shared
        let thumbnailURL = URL(string: thumbnail)!
        session.dataTask(with: thumbnailURL) { (data, response, err) in
            guard let imageData = data else {
                return
            }
            do {
                DispatchQueue.main.async {
                    self.thumbnails[thumbnail] = UIImage(data: imageData)
                    // Table needs to be updated
                    self.myTable.reloadData()
                }
            }
        }.resume()
    }
    
    // Scrolls table and centers map when an annotation is selected
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let selectedAnnotation = view.annotation as? MKPointAnnotation
        
        if(selectedAnnotation != nil){
            mapView.setCenter(selectedAnnotation!.coordinate, animated: true)
            let indexPath = IndexPath(row: 0, section: Array(self.locations.keys).firstIndex(of: (selectedAnnotation?.title)!)!)
            myTable.scrollToRow(at: indexPath, at: .top, animated: true)
        }
        
        
    }
    
    // Feteches campusart data from URL
    func fetchCampusArt(url: String) {
        if let url = URL(string: url) {
            let session = URLSession.shared
            session.dataTask(with: url) { (data, response, err) in
                guard let jsonData = data else {
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let campusartList = try decoder.decode(campusarts.self, from: jsonData)
                    self.campusartList = campusartList
                    DispatchQueue.main.async {
                        self.updateData()
                    }
                } catch let jsonErr {
                    print("Error decoding JSON", jsonErr)
                }
            }.resume()
        }
    }
    
    // Function to center user location (Copied and edited from COURSEWORK 218)
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let locationOfUser = locations[0]
        let latitude = locationOfUser.coordinate.latitude
        let longitude = locationOfUser.coordinate.longitude
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        if firstRun {
            firstRun = false
            let latDelta: CLLocationDegrees = 0.0025
            let lonDelta: CLLocationDegrees = 0.0025
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            let region = MKCoordinateRegion(center: location, span: span)
            self.myMap.setRegion(region, animated: true)
            
            //the following code is to prevent a bug which affects the zooming of the map to the user's location.
            //We have to leave a little time after our initial setting of the map's location and span,
            //before we can start centering on the user's location, otherwise the map never zooms in because the
            //intial zoom level and span are applied to the setCenter( ) method call, rather than our "requested"
            //ones, once they have taken effect on the map.
            //we setup a timer to set our boolean to true in 5 seconds.
            _ = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(startUserTracking), userInfo: nil, repeats: false)
        }
        if startTrackingTheUser == true {
            myMap.setCenter(location, animated: true)
        }
    }
    
    //this method sets the startTrackingTheUser boolean class property to true. Once it's true, subsequent calls
    //to didUpdateLocations will cause the map to center on the user's location.
    @objc func startUserTracking() {
        startTrackingTheUser = true
    }
    
    // Entry point
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Fetch campus art work
        fetchCampusArt(url: "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP228/artworksOnCampus/data.php?class=campusart&lastModified=2017-12-01")
        
        // Update map and table
        updateData()
        
        // Get User's Location
        locationManager.delegate = self as CLLocationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        myMap.showsUserLocation = true
    }
    
}

struct artworkLocation {
    var name: String
    var lat: CLLocationDegrees
    var long: CLLocationDegrees
}

struct campusart: Decodable {
    let id: String
    let title: String
    let artist: String
    let yearOfWork: String
    let type: String?
    let Information: String
    let lat: String
    let long: String
    let location: String
    let locationNotes: String
    let ImagefileName: String
    let thumbnail: String
    let lastModified: String
    let enabled: String
}
struct campusarts: Decodable {
    let campusart: [campusart]
}

