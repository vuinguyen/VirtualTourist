//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Vui Nguyen on 4/28/19.
//  Copyright © 2019 SunfishEmpire. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsViewController: UIViewController, MKMapViewDelegate {

  @IBOutlet weak var mapView: MKMapView!

  var annotations = [MKPointAnnotation]()


  @IBAction func addPin(_ gestureRecognizer: UILongPressGestureRecognizer) {
    //sender.minimumPressDuration
    if gestureRecognizer.state == .ended {
      print("I did a long press!")

      // create annotation here
      let touchPoint = gestureRecognizer.location(in: mapView)
      let annotation = addAnnotation(touchPoint: touchPoint)
      mapView.addAnnotation(annotation)
    }
  }
 


  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.

    //addDefaultData()

    var annotations = [MKPointAnnotation]()
    let location = "Seattle, WA"


    let geocoder = CLGeocoder()
    geocoder.geocodeAddressString(location) { (locations, error) in
      var annotation: MKPointAnnotation
      guard let locations = locations else {
        let alert = UIAlertController(title: "Error Geocoding Location", message: error?.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                      style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        return
      }

      guard let latitude = locations[0].location?.coordinate.latitude else {
        return
      }
      print("latitude is \(latitude)")

      guard let longitude = locations[0].location?.coordinate.longitude else {
        return
      }
      print("longitude is \(longitude)")

      annotation = self.addAnnotationWithCoodinate(latitude: latitude, longitude: longitude)
      annotations.append(annotation)
      self.mapView.addAnnotations(annotations)

    }

    // Finally we place the  in an array of annotations.
    //annotations.append(annotation)

    // Place the annotations on the map, center map around coordinate, and zoom in.
    //self.mapView.addAnnotations(annotations)
    //self.mapView.centerCoordinate = coordinate
  }

  // persist zoom level and map center here
  func setMapDefaults() {

  }

  func addDefaultData() {
    /*

    var annotations = [MKPointAnnotation]()
    let location = "Seattle, WA"

    let geocoder = CLGeocoder()
    geocoder.geocodeAddressString(location) { (locations, error) in
      guard let locations = locations else {
        let alert = UIAlertController(title: "Error Geocoding Location", message: error?.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"),
                                      style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        return
      }

      guard let latitude = locations[0].location?.coordinate.latitude else {
        return
      }
      print("latitude is \(latitude)")

      guard let longitude = locations[0].location?.coordinate.longitude else {
        return
      }
      print("longitude is \(longitude)")

      let annotation = self.addAnnotationWithCoodinate(latitude: latitude, longitude: longitude)
    }

    // Finally we place the annotation in an array of annotations.
    annotations.append(annotation)

    // Place the annotations on the map, center map around coordinate, and zoom in.
    self.mapView.addAnnotations(annotations)
    self.mapView.centerCoordinate = coordinate
 */

  }

  func addAnnotationWithCoodinate(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> MKPointAnnotation{
    let lat = CLLocationDegrees(latitude)
    let long = CLLocationDegrees(longitude)
    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)

    // Here we create the annotation and set its coordiate, title, and subtitle properties
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    annotation.title = "current location"
    annotation.subtitle = "more info"
    /*
    annotation.title = "\(firstName ) \(lastName)"
    if let mediaURL = mediaURL {
      annotation.subtitle = mediaURL
    }
 */

    return annotation


    /*
    self.mapView.region = MKCoordinateRegion(center: coordinate,
                                             span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
*/
  }

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

    let reuseId = "pin"

    var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

    if pinView == nil {
      pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
      pinView!.canShowCallout = true
      pinView!.isEnabled = true
      pinView!.pinTintColor = .red
      pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
    }
    else {
      pinView!.annotation = annotation
    }

    return pinView
  }

  // This delegate method is implemented to respond to taps. It opens the system browser
  // to the URL specified in the annotationViews subtitle property.
  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    if control == view.rightCalloutAccessoryView {

      /*
      let app = UIApplication.shared
      if let toOpen = view.annotation?.subtitle! {
        app.open(URL(string: toOpen)!, options: [:], completionHandler: nil)
      }
 */

      print("tapped call out button")
    }
    print("really tapped call out button")
    let info = view.annotation

    let ac = UIAlertController(title: info?.title ?? "some title", message: info?.subtitle ?? "some subtitle", preferredStyle: .alert)
    ac.addAction(UIAlertAction(title: "OK", style: .default))
    present(ac, animated: true)
  }

  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    print("please I just want to select this!")
  }


  func addAnnotation(touchPoint: CGPoint) -> MKPointAnnotation {
    let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
    let annotation = MKPointAnnotation()
    annotation.coordinate = newCoordinates
    annotation.title = "current location"
    return annotation
  }


  

  /*

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

    let reuseId = "pin"

    var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

    if pinView == nil {
      pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
      pinView!.canShowCallout = true
      pinView!.pinTintColor = .red
      pinView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapPin)))
      pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
      pinView?.isEnabled = true
    }
    else {
      pinView!.annotation = annotation
    }

    return pinView
  }


  @objc func tapPin(_ sender: UITapGestureRecognizer) {
    if sender.state == .ended {

    print("Trying to tap this pin!!")
    }
    let alert = UIAlertController(title: "My Alert", message: "This is an alert.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
      NSLog("The \"OK\" alert occured.")
    }))
    self.present(alert, animated: true, completion: nil)
  }

  func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    print("Annotation pin tapped, yo!")
    if control == view.rightCalloutAccessoryView {
      //let app = UIApplication.shared
     // if let toOpen = view.annotation?.subtitle! {
       // app.open(URL(string: toOpen)!, options: [:], completionHandler: nil)
      print("Annotation pin REALLY tapped, yo!")

    }
  }


  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    //mapView.deselectAnnotation(view.annotation, animated: true)
    //if view.isSelected
    //{
      print("User tapped on annotation")
   // }
    let alert = UIAlertController(title: "My Alert", message: "This is an alert.", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
      NSLog("The \"OK\" alert occured.")
    }))
    self.present(alert, animated: true, completion: nil)


  }
 */

}

