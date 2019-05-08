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

  @IBAction func editPins(_ sender: Any) {

    print("tapped on edit button")

    if inEditPinsMode == false {
      //self.navigationItem.rightBarButtonItem = editButton
      self.view.frame.origin.y = 0
    } else {
     // self.navigationItem.rightBarButtonItem = doneButton
      self.view.frame.origin.y = -75
    }

    inEditPinsMode = !inEditPinsMode
  }

  let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: nil)
  let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: nil)
  var annotations = [MKPointAnnotation]()
  var inEditPinsMode = false

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


   // inEditPinsMode = true
    // check for edit pins mode
    //checkPinsMode()

   // configureRightBarButtonItem()

    annotations.append(defaultAnnotation())
    mapView.addAnnotations(annotations)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    /*
    inEditPinsMode = true
    // check for edit pins mode
    //checkPinsMode()
    configureRightBarButtonItem()
 */

  }

  func configureRightBarButtonItem() {
    if inEditPinsMode == false {
      self.navigationItem.rightBarButtonItem = editButton
      self.view.frame.origin.y = 200
    } else {
      self.navigationItem.rightBarButtonItem = doneButton
      self.view.frame.origin.y = 0
    }

    inEditPinsMode = !inEditPinsMode
  }

  func checkPinsMode() {
    if inEditPinsMode == true {
      view.frame.origin.y = 0
    } else {
      view.frame.origin.y = -75
    }
  }

  // persist zoom level and map center here
  func setMapDefaults() {

  }

  func defaultAnnotation() -> MKPointAnnotation {

    let annotation = MKPointAnnotation()

    // location is Seattle, WA
    let latitude = CLLocationDegrees(47.60621)
    let longitude = CLLocationDegrees(-122.3321)
    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    annotation.coordinate = coordinate
    annotation.title = "current location"
    annotation.subtitle = "more info"

    return annotation
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
  }

  func addAnnotation(touchPoint: CGPoint) -> MKPointAnnotation {
    let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
    let annotation = MKPointAnnotation()
    annotation.coordinate = newCoordinates
    annotation.title = "current location"
    return annotation
  }

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

    let reuseId = "pin"

    var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

    if pinView == nil {
      pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
      pinView!.pinTintColor = .red
    }
    else {
      pinView!.annotation = annotation
    }

    return pinView
  }

  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    print("I've selected this annotation!")

    mapView.deselectAnnotation(view.annotation, animated: true)

    // segue into next viewcontroller here
    performSegue(withIdentifier: "photoAlbumSegue", sender: self)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "photoAlbumSegue" {
      let controller = segue.destination as! PhotoAlbumViewController
      print("I'm going to the photo album!")
    }
  }

}

