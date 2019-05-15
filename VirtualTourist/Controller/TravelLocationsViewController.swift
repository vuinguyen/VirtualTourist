//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Vui Nguyen on 4/28/19.
//  Copyright © 2019 SunfishEmpire. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate {

  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var tapPinsToDeleteButton: UIButton!
  
  @IBOutlet weak var editPinsButton: UIBarButtonItem!
  @IBAction func editPins(_ sender: Any) {
    print("tapped on edit button")

    inEditPinsMode = !inEditPinsMode
    checkPinsMode()
  }

  var pins: [NSManagedObject] = []
  var annotations = [MKPointAnnotation]()
  var inEditPinsMode = false

  var appDelegate: AppDelegate!
  var managedContext: NSManagedObjectContext!

  @IBAction func dropPin(_ gestureRecognizer: UILongPressGestureRecognizer) {
    //sender.minimumPressDuration
    if gestureRecognizer.state == .ended {
      print("I did a long press!")

      // create annotation here
      let touchPoint = gestureRecognizer.location(in: mapView)
      let annotation = addPin(touchPoint: touchPoint)
      //let annotation = addAnnotation(touchPoint: touchPoint)
      mapView.addAnnotation(annotation)
      //appDelegate.saveContext()
    }
  }

  // depending on inEditPinsMode, make sure the correct system button is displayed,
  // the delete Pins button is displayed if applicable
  func checkPinsMode() {
    if inEditPinsMode == false {
      self.view.frame.origin.y = 0
      editPinsButton.title = "Edit"
    } else {
      self.view.frame.origin.y = -(tapPinsToDeleteButton.frame.size.height)
      editPinsButton.title = "Done"
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.

    checkPinsMode()

    //annotations.append(defaultAnnotation())
    //mapView.addAnnotations(annotations)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    appDelegate = UIApplication.shared.delegate as? AppDelegate
    managedContext = appDelegate.persistentContainer.viewContext

    mapView.addAnnotations(fetchAllPins())
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

  /*
  func addAnnotationWithCoodinate(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> MKPointAnnotation{
    let lat = CLLocationDegrees(latitude)
    let long = CLLocationDegrees(longitude)
    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)

    // Here we create the annotation and set its coordiate, title, and subtitle properties
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    annotation.title = "current location"
    annotation.subtitle = "more info"

 //   annotation.title = "\(firstName ) \(lastName)"
 //   if let mediaURL = mediaURL {
 //     annotation.subtitle = mediaURL
 //   }

    return annotation
  }
 */

  func addAnnotation(touchPoint: CGPoint) -> MKPointAnnotation {
    let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
    let annotation = MKPointAnnotation()
    annotation.coordinate = newCoordinates
    annotation.title = "current location"
    return annotation
  }

  func addPin(touchPoint: CGPoint) -> MKPointAnnotation {
    let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
    let annotation = MKPointAnnotation()
    annotation.coordinate = coordinate
    annotation.title = "current location"

    // save to Core Data
    let entity =
      NSEntityDescription.entity(forEntityName: "Pin",
                                 in: managedContext)!

    let pin = NSManagedObject(entity: entity,
                                 insertInto: managedContext)

    pin.setValue(coordinate.latitude, forKeyPath: "latitude")
    pin.setValue(coordinate.longitude, forKeyPath: "longitude")

    do {
      try managedContext.save()
      pins.append(pin)
    } catch let error as NSError {
      print("Could not save. \(error), \(error.userInfo)")
    }

    return annotation
  }

  func fetchAllPins() -> [MKAnnotation] {
    var annotations: [MKAnnotation] = []
    do {
      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Pin")
      let pins = try managedContext.fetch(fetchRequest)
      for pin in pins {
        if let latitude = pin.value(forKeyPath: "latitude") as? Double,
          let longitude = pin.value(forKeyPath: "longitude") as? Double {

          let annotation = MKPointAnnotation()
          annotation.coordinate.latitude = latitude
          annotation.coordinate.longitude = longitude
          annotations.append(annotation)
        }
      }
    } catch let error as NSError {
      print("Could not fetch. \(error), \(error.userInfo)")
    }
    return annotations
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

    if inEditPinsMode {
      if let annotation = view.annotation {
        mapView.removeAnnotation(annotation)
        print("annotation removed!")
      } else {
        print("in edit pin mode but cannot grab the pin!")
      }
    } else {
    // segue into next viewcontroller here
      performSegue(withIdentifier: "photoAlbumSegue", sender: self)
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "photoAlbumSegue" {
      let controller = segue.destination as! PhotoAlbumViewController
      print("I'm going to the photo album!")
    }
  }

}

