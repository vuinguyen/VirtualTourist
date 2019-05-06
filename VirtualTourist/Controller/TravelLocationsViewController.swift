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

  /*
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
 */


  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.

    addDefaultData()
  }

  // persist zoom level and map center here
  func setMapDefaults() {

  }

  func addDefaultData() {
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

      self.addAnnotationWithCoodinate(latitude: latitude, longitude: longitude)
    }

  }

  func addAnnotationWithCoodinate(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
    let lat = CLLocationDegrees(latitude)
    let long = CLLocationDegrees(longitude)
    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)

    // Here we create the annotation and set its coordiate, title, and subtitle properties
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    /*
    annotation.title = "\(firstName ) \(lastName)"
    if let mediaURL = mediaURL {
      annotation.subtitle = mediaURL
    }
 */

    // Finally we place the annotation in an array of annotations.
    annotations.append(annotation)

    // Place the annotations on the map, center map around coordinate, and zoom in.
    self.mapView.addAnnotations(annotations)
    self.mapView.centerCoordinate = coordinate
    /*
    self.mapView.region = MKCoordinateRegion(center: coordinate,
                                             span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
*/
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

