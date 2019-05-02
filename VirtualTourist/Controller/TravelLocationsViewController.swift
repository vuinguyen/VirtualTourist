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
  }

  // persist zoom level and map center here
  func setMapDefaults() {

  }

  func addAnnotation(touchPoint: CGPoint) -> MKPointAnnotation {
    let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
    let annotation = MKPointAnnotation()
    annotation.coordinate = newCoordinates
    return annotation
  }

}

