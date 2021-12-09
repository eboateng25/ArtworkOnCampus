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
    
    var locationManager = CLLocationManager()
    
    var firstRun = true
    var startTrackingTheUser = false
    
    var campusartList : campusarts? = nil
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell")!
        
        
        
        return cell
    }
    
    
    @IBOutlet weak var myMap: MKMapView!
    
    @IBOutlet weak var myTable: UITableView!
    
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
    
    func updateData(){
        // Map out locations on map
        addMapAnnotations(map: myMap, campusarts: campusartList)
        
        print("UPDATING...")
    }
    
    func addMapAnnotations(map: MKMapView!, campusarts: campusarts?){
        var artworkLocations : [ArtworkLocation] = []
        if(campusarts != nil){
            for i in 0...(campusarts?.campusart.count)! - 1 {
                let location : String = (campusarts?.campusart[i].location)!
                let lat : Double =  Double((campusarts?.campusart[i].lat)!)!
                let long: Double = Double((campusarts?.campusart[i].long)!)!
                let artworklocation = ArtworkLocation(name: location, lat: lat, long: long)
                
                artworkLocations.append(artworklocation)
                
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
            _ = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(startUserTracking), userInfo: nil, repeats: false)
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
    
}

struct ArtworkLocation {
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
    let thumbnail: URL
    let lastModified: String
    let enabled: String
}
struct campusarts: Decodable {
    let campusart: [campusart]
}

