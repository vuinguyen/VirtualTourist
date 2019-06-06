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
  var selectedAnnotation: MKPointAnnotation?
  var selectedPin: Pin?

  @IBAction func dropPin(_ gestureRecognizer: UILongPressGestureRecognizer) {
    if gestureRecognizer.state == .ended {
      print("I did a long press!")

      // create annotation here
      let touchPoint = gestureRecognizer.location(in: mapView)
      let annotation = addPin(touchPoint: touchPoint)
      mapView.addAnnotation(annotation)
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

  func addAnnotation(touchPoint: CGPoint) -> MKPointAnnotation {
    let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
    let annotation = MKPointAnnotation()
    annotation.coordinate = newCoordinates
    return annotation
  }

  func deletePin(annotation: MKAnnotation) {
    /*
    let annotationToDelete = annotation

    // use predicate to look for the Pin to delete and remove it
    // from the current context
    print("latitude is \(annotationToDelete.coordinate.latitude)")
    print("longitude is \(annotationToDelete.coordinate.longitude)")
    let latitudePredicate = NSPredicate(format: "latitude = %lf", annotationToDelete.coordinate.latitude)
    let longitudePredicate = NSPredicate(format: "longitude = %lf", annotationToDelete.coordinate.longitude)
    let coordinatePredicate = NSCompoundPredicate(type: .and, subpredicates: [latitudePredicate, longitudePredicate])

    do {
      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Pin")
      let pins = try managedContext.fetch(fetchRequest)
      let PinToDelete = (pins as NSArray).filtered(using: coordinatePredicate) as! [NSManagedObject]
      if PinToDelete.count >= 1 {

        // Now, remove it from Core Data
        managedContext.delete(PinToDelete[0])
        try managedContext.save()

        // remove it from the map
        DispatchQueue.main.async {
          self.mapView.removeAnnotation(annotation)
        }

        print("annotation removed!")
      }
    } catch let error as NSError {
      print("Could not fetch or save from context. \(error), \(error.userInfo)")
    }
 */
    getPinFromAnnotation(selectedAnnotation: annotation) { (pin, error) in
      self.managedContext.delete(pin!)
      self.mapView.removeAnnotation(annotation)
    }
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

    print("latitude: \(coordinate.latitude), longitude: \(coordinate.longitude)")
    pin.setValue(coordinate.latitude, forKeyPath: "latitude")
    pin.setValue(coordinate.longitude, forKeyPath: "longitude")
    pin.setValue(Date(), forKey: "creationDate")

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

          print("latitude: \(latitude), longitude: \(longitude)")
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

  func getPinFromAnnotation(selectedAnnotation: MKAnnotation, completion: @escaping (Pin?, Error?) -> Void) {
    //var pinFound: Pin?
    // use predicate to look for the Pin to delete and remove it
    // from the current context
    print("latitude is \(selectedAnnotation.coordinate.latitude)")
    print("longitude is \(selectedAnnotation.coordinate.longitude)")
    let latitudePredicate = NSPredicate(format: "latitude = %lf", selectedAnnotation.coordinate.latitude)
    let longitudePredicate = NSPredicate(format: "longitude = %lf", selectedAnnotation.coordinate.longitude)
    let coordinatePredicate = NSCompoundPredicate(type: .and, subpredicates: [latitudePredicate, longitudePredicate])

    do {
      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Pin")
      let pins = try managedContext.fetch(fetchRequest)
      let pinsFound = (pins as NSArray).filtered(using: coordinatePredicate) as! [NSManagedObject]
      if pinsFound.count >= 1 {

        if let pinFound = pinsFound[0] as? Pin {
          DispatchQueue.main.async {
            completion(pinFound, nil)
          }
        }
      }
    } catch let error as NSError {

      print("Could not fetch or save from context. \(error), \(error.userInfo)")
      completion(nil, error)
    }

   // return pinFound
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
   // print("I've selected this annotation!")

    mapView.deselectAnnotation(view.annotation, animated: true)

    guard let annotation = view.annotation else {
      return
    }

    if inEditPinsMode {
      deletePin(annotation: annotation)
    } else {
    // segue into next viewcontroller here
      if let annotation = annotation as? MKPointAnnotation {
        getPinFromAnnotation(selectedAnnotation: annotation) { (pin, error) in
          self.selectedAnnotation = annotation
          self.selectedPin = pin
          self.performSegue(withIdentifier: "photoAlbumSegue", sender: self)
        }

      }
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "photoAlbumSegue" {
      let controller = segue.destination as! PhotoAlbumViewController
      controller.mapAnnotation = selectedAnnotation
      controller.pin = selectedPin
      //print("I'm going to the photo album!")
    }
  }

}

