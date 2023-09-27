//
//  MapsViewController.swift
//  NavigationProject
//
//  Created by Oğuzhan Tekiroğlu on 24.09.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var isimTF: UITextField!
    @IBOutlet weak var notTF: UITextField!
    
    let locationManager = CLLocationManager()
    var secilenIsim = ""
    var secilenId : UUID?
    var secilenLongitude = Double()
    var secilenLatitude = Double()
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    let annotation = MKPointAnnotation()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
               
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 1.5
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if secilenIsim != ""{
            if let uuidString = secilenId?.uuidString{
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yerler")
                fetchRequest.predicate = NSPredicate(format: " id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do{
                    let sonuclar = try context.fetch(fetchRequest)
                    if sonuclar.count > 0{
                        for sonuc in sonuclar as! [NSManagedObject]{
                            
                            if let isim = sonuc.value(forKey: "isim") as? String{
                                annotationTitle = isim
                                
                                if let not = sonuc.value(forKey: "not") as? String{
                                    annotationSubtitle = not
                                    
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double{
                                        annotationLatitude = latitude
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double{
                                            annotationLongitude = longitude
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            mapView.addAnnotation(annotation)
                                            
                                            
                                            
                                            isimTF.text = annotationTitle
                                            notTF.text = annotationSubtitle
                                            locationManager.stopUpdatingLocation()
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                            
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch{
                    print("Hata")
                }
            }
            
        }
    }
    
    @objc func konumSec(gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began{
            let dokunulanNokta = gestureRecognizer.location(in: mapView)
            let dokunulanKordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView)
            
            secilenLatitude = dokunulanKordinat.latitude
            secilenLongitude = dokunulanKordinat.longitude
            
            annotation.title = isimTF.text
            annotation.subtitle = notTF.text
            annotation.coordinate = dokunulanKordinat
            mapView.addAnnotation(annotation)
            
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }
        let reuseId = "benimAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .purple
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else{
            pinView?.annotation = annotation
        }
        return pinView
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if secilenIsim != ""{
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            
            
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkDizisi, hata) in
                
                if let placemarks = placemarkDizisi{
        
                    if placemarks.count > 0 {
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: yeniPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if secilenIsim == ""{
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
            let annotation = MKPointAnnotation()
            annotation.title = "Buradasınız"
            annotation.coordinate = location
            mapView.addAnnotation(annotation)
        }
    }
    
    @IBAction func kaydetButtonTiklandi(_ sender: Any) {
        if secilenIsim == ""{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let yer = NSEntityDescription.insertNewObject(forEntityName: "Yerler", into: context)
            
            yer.setValue(isimTF.text, forKey: "isim")
            yer.setValue(notTF.text, forKey: "not")
            yer.setValue(secilenLatitude, forKey: "latitude")
            yer.setValue(secilenLongitude, forKey: "longitude")
            yer.setValue(UUID(), forKey: "id")
            
            do{
                try context.save()
                print("Kaydedildi")
            } catch{
                print("Hata!")
            }
            
            NotificationCenter.default.post(name: NSNotification.Name("veriGonderildi"), object: nil)
            navigationController?.popViewController(animated: true)
        }
        
    }
    
}
