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
  
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var collectionEditButton: UIButton!
  @IBOutlet weak var photoCollectionView: UICollectionView!
  @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
  @IBOutlet weak var mapView: MKMapView!

  @IBAction func getNewCollection(_ sender: Any) {

    guard let latitude  = latitude,
      let longitude = longitude else {
        print("don't have valid coordinates here")
        return
    }

    activityIndicator.startAnimating()

    if picSelectionMode {
      print("we're in pic selection mode, yo!")
      print("Indices of pics to remove, BEFORE: \(indexPathsOfPicsToRemove)")

      // here is where we remove the pictures from the collection view
      // we've kept track of the indices of the pictures we need to remove from
      // the collection view, so we can remove them easily
      //replacePics()

      FlickrClient.getPhotoList(latitude: latitude,
                                longitude: longitude,
                                totalNumPicsAvailable: totalNumPicsAvailable,
                                updatedNumPicsToDisplay: indexPathsOfPicsToRemove.count,
                                maxNumPicsDisplayed: maxPicsDisplayed) { (flickrPhotos, totalNumPics, error) in
                                  self.updateCollectionView(flickrPhotos: flickrPhotos, totalNumPics: totalNumPics, error: error,
                                                            updateAllPics: false)
      }

      // set everything back to original settings
      /*
      collectionEditButton.setTitle("New Collection", for: .normal)
      picSelectionMode = false
      indexPathsOfPicsToRemove = []
      print("Indices of pics to remove, AFTER: \(indexPathsOfPicsToRemove)")
*/
    } else {
      /*
      let currentNumber = resultsPageNumber

      (pics, resultsPageNumber) = PhotoRequest.getPics(currentNumber) as! ([UIImage], Int)
      photoCollectionView.reloadData()
       */


      print("we're getting all new pics!")

      // let's call flickr here
      print("downloading data from Flickr!")
      //let latitude  = 40.52972239576226
      //let longitude = -96.65559787790511

      FlickrClient.getPhotoList(latitude: latitude,
                                longitude: longitude,
                                totalNumPicsAvailable: totalNumPicsAvailable,
                                updatedNumPicsToDisplay: maxPicsDisplayed,
                                maxNumPicsDisplayed: maxPicsDisplayed) { (flickrPhotos, totalNumPics, error) in
                                  self.updateCollectionView(flickrPhotos: flickrPhotos, totalNumPics: totalNumPics, error: error)
                                  }
      /*
        // update collection view

        print("returned from getPhotoList")

        guard let flickrPhotos = flickrPhotos,
              let totalNumPics = totalNumPics else
        {
          self.activityIndicator.stopAnimating()
          if let error = error {
            print("we got an error \(error)")
          }
          return
        }
        self.totalNumPicsAvailable = totalNumPics
        self.pics = []
        self.pics = (flickrPhotos.compactMap({ flickerPhoto in
          return flickerPhoto.photoImage
        }))
        self.photoCollectionView.reloadData()

        self.activityIndicator.stopAnimating()
      }
*/
    }

  }

  private let reusePhotoCellIdentifier = "PhotoCollectionViewCell"

  var resultsPageNumber: Int = 0
  var pics = [UIImage]()
  var mapAnnotation: MKPointAnnotation?
  var latitude: Double?
  var longitude: Double?
  var picSelectionMode = false
  var indexPathsOfPicsToRemove = [IndexPath]()
  var totalNumPicsAvailable: Int = 0
  let maxPicsDisplayed = 12

  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.
    let space:CGFloat = 3.0
    let dimension = (view.frame.size.width - (2 * space)) / 3.0

    flowLayout.minimumInteritemSpacing = space
    flowLayout.minimumLineSpacing = space
    flowLayout.itemSize = CGSize(width: dimension, height: dimension)

    (pics, resultsPageNumber) = PhotoRequest.getPics() as! ([UIImage], Int)

    if let mapAnnotation = mapAnnotation {
      latitude  = mapAnnotation.coordinate.latitude
      longitude = mapAnnotation.coordinate.longitude
    }
    displayMapPin()
  }

  func replacePics() {
    let numPicsToReplace = indexPathsOfPicsToRemove.count

    // I have to do this weird thing where I sort and reverse the indexPaths to fix a bug
    // I was getting as pictures were being deleted
    // see stackoverflow below for explanation:
    // https://stackoverflow.com/a/42432585
    for indexPath in indexPathsOfPicsToRemove.sorted().reversed() {
      pics.remove(at: indexPath.row)

      // deselect the pictures that were removed
      let cell = photoCollectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
      cell.backgroundColor = .none
    }

    let (picsToReplace, resultsPageNum) = PhotoRequest.getPics(resultsPageNumber, numPicsToReplace) as! ([UIImage], Int)
    resultsPageNumber = resultsPageNum
    pics.append(contentsOf: picsToReplace)
    photoCollectionView.reloadData()
  }

  func getDefaultPics() {
    for _ in 0...11 {
      if let image = UIImage(named: "Placeholder2") {
        pics.append(image)
      }
    }
  }

  func updateCollectionView(flickrPhotos: [FlickrPhoto]?, totalNumPics: Int?, error: Error?, updateAllPics: Bool = true) {
    print("returned from getPhotoList")

    guard let flickrPhotos = flickrPhotos,
      let totalNumPics = totalNumPics else
    {
      self.activityIndicator.stopAnimating()
      if let error = error {
        print("we got an error \(error)")
      }
      return
    }

    let images: [UIImage] = flickrPhotos.compactMap({ flickerPhoto in
      return flickerPhoto.photoImage
    })

    self.totalNumPicsAvailable = totalNumPics
    if updateAllPics == true {
      self.pics = []
      self.pics = images
    } else {
      // Remove old pictures from collection view first

      // I have to do this weird thing where I sort and reverse the indexPaths to fix a bug
      // I was getting as pictures were being deleted
      // see stackoverflow below for explanation:
      // https://stackoverflow.com/a/42432585
      for indexPath in indexPathsOfPicsToRemove.sorted().reversed() {
        pics.remove(at: indexPath.row)

        // deselect the pictures that were removed
        let cell = photoCollectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        cell.backgroundColor = .none
      }

      pics.append(contentsOf: images)

      // set everything back to original settings
      collectionEditButton.setTitle("New Collection", for: .normal)
      picSelectionMode = false
      indexPathsOfPicsToRemove = []
      print("Indices of pics to remove, AFTER: \(indexPathsOfPicsToRemove)")

    }
    self.photoCollectionView.reloadData()

    self.activityIndicator.stopAnimating()
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
    cell.backgroundColor = .lightGray
    indexPathsOfPicsToRemove.append(indexPath)

    // go into edit mode
    collectionEditButton.setTitle("Remove Selected Pictures", for: .normal)
    picSelectionMode = true
  }
}
