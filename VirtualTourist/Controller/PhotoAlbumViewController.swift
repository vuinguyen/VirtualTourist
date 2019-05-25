//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Vui Nguyen on 5/3/19.
//  Copyright © 2019 SunfishEmpire. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UICollectionViewController, MKMapViewDelegate {
  
  @IBOutlet weak var collectionEditButton: UIButton!
  @IBOutlet weak var photoCollectionView: UICollectionView!
  @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
  @IBOutlet weak var mapView: MKMapView!

  @IBAction func getNewCollection(_ sender: Any) {
    if picSelectionMode {
      print("we're in pic selection mode, yo!")
      print("Indices of pics to remove, BEFORE: \(indicesOfPicsToRemove)")

      // here is where we remove the pictures from the collection view
      // somehow, keep track of the indices of the pictures we need to remove from
      // the collection view, so we can remove them easily
      replacePics()

      collectionEditButton.setTitle("New Collection", for: .normal)
      // deselect all pictures


      picSelectionMode = false
      indicesOfPicsToRemove = []
      indexPathsOfPicsToRemove = []
      print("Indices of pics to remove, AFTER: \(indicesOfPicsToRemove)")
    } else {
      let currentNumber = resultsPageNumber

      (pics, resultsPageNumber) = PhotoRequest.getPics(currentNumber) as! ([UIImage], Int)
      photoCollectionView.reloadData()
    }
  }

  private let reusePhotoCellIdentifier = "PhotoCollectionViewCell"

  var resultsPageNumber: Int = 0
  var pics = [UIImage]()
  var mapAnnotation: MKPointAnnotation?
  var picSelectionMode = false
  var indicesOfPicsToRemove = [Int]()
  var indexPathsOfPicsToRemove = [IndexPath]()

  override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    let space:CGFloat = 3.0
    let dimension = (view.frame.size.width - (2 * space)) / 3.0

    flowLayout.minimumInteritemSpacing = space
    flowLayout.minimumLineSpacing = space
    flowLayout.itemSize = CGSize(width: dimension, height: dimension)

    (pics, resultsPageNumber) = PhotoRequest.getPics() as! ([UIImage], Int)

    displayMapPin()
  }

  func replacePics() {
    for index in indicesOfPicsToRemove {
      pics.remove(at: index)
    }

    for indexPath in indexPathsOfPicsToRemove {
      let cell = photoCollectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
      cell.backgroundColor = .none
    }

    let numPicsToReplace = indexPathsOfPicsToRemove.count
    let (picsToReplace, resultsPageNum) = PhotoRequest.getPics(resultsPageNumber, numPicsToReplace)
    resultsPageNumber = resultsPageNum!
    pics.append(contentsOf: picsToReplace!)
    photoCollectionView.reloadData()
  }

  func getDefaultPics() {
    for _ in 0...11 {
      if let image = UIImage(named: "Placeholder2") {
        pics.append(image)
      }
    }
  }

  func displayMapPin() {
    if let annotation = mapAnnotation {
      mapView.addAnnotations([annotation])

      mapView.centerCoordinate = annotation.coordinate
      mapView.region = MKCoordinateRegion(center: annotation.coordinate,
                                          span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015))
    }
  }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

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

  // MARK: UICollectionViewDataSource
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return pics.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reusePhotoCellIdentifier, for: indexPath) as! PhotoCollectionViewCell
    let pic = self.pics[(indexPath as NSIndexPath).row]

    cell.photoImageView.image = pic
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    print("I selected a pic")

    let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
    // highlight the item
    //cell.photoImageView.backgroundColor = .lightGray
    cell.backgroundColor = .lightGray
    indicesOfPicsToRemove.append(indexPath.row)
    indexPathsOfPicsToRemove.append(indexPath)

    // if in edit mode
    collectionEditButton.setTitle("Remove Selected Pictures", for: .normal)
    picSelectionMode = true
  }

  /*
  override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    print("I deselected a pic")
    let cell = collectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
    //cell.photoImageView.backgroundColor = .none
    cell.backgroundColor = .none
  }
 */

}
