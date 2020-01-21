//
//  ViewController.swift
//  Map
//
//  Created by maika on 1/12/20.
//  Copyright © 2020 maika. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController,UIGestureRecognizerDelegate {
    
    var locationManager = CLLocationManager()
    var authrizationStatus = CLLocationManager.authorizationStatus()
    var regionRadius: Double = 1000
    var spinner: UIActivityIndicatorView?
    var progressLbl: UILabel?
    var flowLayout = UICollectionViewFlowLayout()
    var collectionView: UICollectionView?
    var imageArrayUrls = [String]()
    var imageArray = [UIImage]()
    var screenSize = UIScreen.main.bounds
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var heightViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        mapView.delegate = self
        configurLocationService()
        addDoubleTap()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 1, green: 0.6241641045, blue: 0, alpha: 1)
        pullUpView.addSubview(collectionView!)
    }
    
    func addDoubleTap(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    @IBAction func centerMapBtn(_ sender: Any) {
        if authrizationStatus == .authorizedAlways || authrizationStatus == .authorizedWhenInUse{
            centerMapOnUserLocation()
        }
    }
    func swapping(){
        let swapping  = UISwipeGestureRecognizer(target: self, action: #selector(animatViewDown))
        swapping.direction = .down
        pullUpView.addGestureRecognizer(swapping)
    }
    
    
    func animatViewUp(){
        heightViewConstraint.constant = 300
        UIView.animate(withDuration: 0.3){
            self.view.layoutIfNeeded()
        }
    }
    @objc func animatViewDown(){
        cancelAllSession()
        heightViewConstraint.constant = 0
        UIView.animate(withDuration: 0.3){
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner(){
    spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2)-((spinner?.frame.width)! / 2), y: 150)
        spinner?.style = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
        
    }
    
    func removeSpinner(){
        if spinner != nil{
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLbl(){
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: (screenSize.width / 2) - 100, y: 165, width: 200, height: 40)
        progressLbl?.textAlignment = .center
        progressLbl?.text = "PHOTOS LOAD..."
        progressLbl?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        collectionView?.addSubview(progressLbl!)
    }
    
    func removeProgressLbl(){
        if progressLbl != nil{
            progressLbl?.removeFromSuperview()
        }
    }
}
extension MapVC: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 1, green: 0.6241641045, blue: 0, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func centerMapOnUserLocation(){
        guard let coordinate = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc func dropPin(sender: UIGestureRecognizer){
        removePin()
        removeSpinner()
        removeProgressLbl()
        cancelAllSession()
        animatViewUp()
        swapping()
        addSpinner()
        addProgressLbl()
        
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        let coordinateRegion = MKCoordinateRegion(center: touchCoordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        retrieveUrl(forAnnotation: annotation) { (finished) in
            if finished {
                self.retreiveImage(handler: { (finished) in
                    if finished{
                        self.removeSpinner()
                        self.removeProgressLbl()
                        //reload collection view
                    }
                })
            }
            
        }
        
    }
    
    func removePin() {
        for annotation in mapView.annotations{
            mapView.removeAnnotation(annotation)
        }
    }
    
    func retrieveUrl(forAnnotation annotation: DroppablePin, handler: @escaping (_ status: Bool) -> ()){
        imageArrayUrls = []
        
        Alamofire.request(flickerUrl(forApiKey: apikey, withAnnotation: annotation, numberOfPhotos: 40)).responseJSON{(response) in
            guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
            let dictPhoto = json["photos"] as! Dictionary<String, AnyObject>
            let dictPhotosArray = dictPhoto["photo"] as! [Dictionary<String, AnyObject>]
            for photo in dictPhotosArray{
                let postUrl = "https://live.staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_q_d.jpg"
                //https://live.staticflickr.com/3943/15764107365_59966860b5_5k_d.jpg
                self.imageArrayUrls.append(postUrl)
            }
            handler(true)
        }
    }
    func retreiveImage(handler: @escaping (_ status: Bool) -> ()){
        imageArray = []
        for url in imageArrayUrls{
            Alamofire.request(url).responseImage { (response) in
                guard let image = response.result.value else { return }
                self.imageArray.append(image)
                self.progressLbl?.text = "\(self.imageArray.count)/40 IMAGES DOWNLOADED"
                if self.imageArray.count == self.imageArrayUrls.count {
                    handler(true)
                }
            }
        }
    }
    
    func cancelAllSession(){
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler{(sessionData, uploadData, downloadData) in
            sessionData.forEach({ $0.cancel() })
            downloadData.forEach({ $0.cancel() })
        }
    }
}
extension MapVC: CLLocationManagerDelegate{
    func configurLocationService(){
        if authrizationStatus == .notDetermined{
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell
        return cell!
    }
    
    
}
