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

  var inEditPinsMode = false

  var appDelegate: AppDelegate!
  var managedContext: NSManagedObjectContext!
  var selectedAnnotation: MKPointAnnotation?
  var selectedPin: Pin?

  let centerLatitude = "centerLatitude"
  let centerLongitude = "centerLongitude"
  let latitudeDelta = "latitudeDelta"
  let longitudeDelta = "longitudeDelta"

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

    appDelegate = UIApplication.shared.delegate as? AppDelegate
    managedContext = appDelegate.persistentContainer.viewContext

    mapView.addAnnotations(fetchAllPins())
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    appDelegate = UIApplication.shared.delegate as? AppDelegate
    managedContext = appDelegate.persistentContainer.viewContext

    // this is where map's center and region is loaded
    getMapDefaults()
  }


  func getMapDefaults() {
    if UserDefaults.standard.object(forKey: centerLatitude)  != nil &&
       UserDefaults.standard.object(forKey: centerLongitude) != nil &&
       UserDefaults.standard.object(forKey: latitudeDelta)   != nil &&
       UserDefaults.standard.object(forKey: longitudeDelta)  != nil {
      let latitude = CLLocationDegrees(UserDefaults.standard.double(forKey: centerLatitude))
      let longitude = CLLocationDegrees(UserDefaults.standard.double(forKey: centerLongitude))
      let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      let latDelta = CLLocationDegrees(UserDefaults.standard.double(forKey: latitudeDelta))
      let longDelta = CLLocationDegrees(UserDefaults.standard.double(forKey: longitudeDelta))
      mapView.centerCoordinate = coordinate
      mapView.region = MKCoordinateRegion(center: coordinate,
                                          span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta))
      print("got user defaults!")
    } else {
      print("dont have user defaults yet")
    }
  }

  // persist zoom level and map center here
  func setMapDefaults(centerLatitude: CLLocationDegrees, centerLongitude: CLLocationDegrees,
                      latitudeDelta: CLLocationDegrees, longitudeDelta: CLLocationDegrees) {

    UserDefaults.standard.set(Double(centerLatitude), forKey: "centerLatitude")
    UserDefaults.standard.set(Double(centerLongitude), forKey: "centerLongitude")
    UserDefaults.standard.set(Double(latitudeDelta), forKey: "latitudeDelta")
    UserDefaults.standard.set(Double(longitudeDelta), forKey: "longitudeDelta")
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
    getPinFromAnnotation(selectedAnnotation: annotation) { (pin, error) in
      guard let pin = pin else {
        print("couldn't find pin to delete!")
        return
      }

      do {
        self.managedContext.delete(pin)
        try self.managedContext.save()
        self.mapView.removeAnnotation(annotation)
      } catch let error as NSError {
        print("Could not save delete. \(error), \(error.userInfo)")
      }
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
    } catch let error as NSError {
      print("Could not save. \(error), \(error.userInfo)")
    }

    return annotation
  }

  func fetchAllPins() -> [MKAnnotation] {
    var annotations: [MKAnnotation] = []
    do {
      let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
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
    // use predicate to look for the Pin to delete and remove it
    // from the current context
    print("latitude is \(selectedAnnotation.coordinate.latitude)")
    print("longitude is \(selectedAnnotation.coordinate.longitude)")
    let latitudePredicate = NSPredicate(format: "latitude = %lf", selectedAnnotation.coordinate.latitude)
    let longitudePredicate = NSPredicate(format: "longitude = %lf", selectedAnnotation.coordinate.longitude)
    let coordinatePredicate = NSCompoundPredicate(type: .and, subpredicates: [latitudePredicate, longitudePredicate])

    do {
      let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
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
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "photoAlbumSegue" {
      let controller = segue.destination as! PhotoAlbumViewController
      controller.mapAnnotation = selectedAnnotation
      controller.pin = selectedPin
      //print("I'm going to the photo album!")
    }
  }

  // MARK: MKMapViewDelegate
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

  func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
    print("map region changed, yo!")
    // this is where we save to user defaults
    // and then it gets re-read in viewwillappear

    let currentRegion = mapView.region
    let center = currentRegion.center
    let centerLatitude = center.latitude  // persist this in UserDefaults
    let centerLongitude = center.longitude  // persist this in UserDefaults

    let span = currentRegion.span
    let latitudeDelta = span.latitudeDelta  // persist this in UserDefaults
    let longitudeDelta = span.longitudeDelta  // persist this in UserDefaults

    setMapDefaults(centerLatitude: centerLatitude, centerLongitude: centerLongitude, latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
  }
}

