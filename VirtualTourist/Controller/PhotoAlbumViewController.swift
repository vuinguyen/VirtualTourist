//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Vui Nguyen on 5/3/19.
//  Copyright © 2019 SunfishEmpire. All rights reserved.
//

import UIKit
import MapKit
import CoreData

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

      FlickrClient.getPhotoList(latitude: latitude,
                                longitude: longitude,
                                totalNumPicsAvailable: totalNumPicsAvailable,
                                updatedNumPicsToDisplay: indexPathsOfPicsToRemove.count,
                                maxNumPicsDisplayed: maxPicsDisplayed) { (flickrPhotos, totalNumPics, error) in
                                  self.updateCollectionView(flickrPhotos: flickrPhotos, totalNumPics: totalNumPics, error: error,
                                                            updateAllPics: false)
      }

    } else {
      print("we're getting all new pics!")

      // let's call flickr here
      print("downloading data from Flickr!")
      //let latitude  = 40.52972239576226
      //let longitude = -96.65559787790511
/*
      FlickrClient.getPhotoList(latitude: latitude,
                                longitude: longitude,
                                totalNumPicsAvailable: totalNumPicsAvailable,
                                updatedNumPicsToDisplay: maxPicsDisplayed,
                                maxNumPicsDisplayed: maxPicsDisplayed) { (flickrPhotos, totalNumPics, error) in
                                  self.updateCollectionView(flickrPhotos: flickrPhotos, totalNumPics: totalNumPics, error: error)
      }
*/
      FlickrClient.getFlickrPhotos(latitude: latitude, longitude: longitude) { (flickrPhotos, totalNums, error) in
        self.updateCollectionView2(flickrPhotos: flickrPhotos, totalNumPics: totalNums, error: error)

      }

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
  var flickrPhotos = [FlickrPhoto]()

  var appDelegate: AppDelegate!
  var managedContext: NSManagedObjectContext!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // Do any additional setup after loading the view.

    appDelegate = UIApplication.shared.delegate as? AppDelegate
    managedContext = appDelegate.persistentContainer.viewContext

    if let mapAnnotation = mapAnnotation {
      latitude  = mapAnnotation.coordinate.latitude
      longitude = mapAnnotation.coordinate.longitude
    }

    displayMapPin()

    // collection view setup
    let space:CGFloat = 3.0
    let dimension = (view.frame.size.width - (2 * space)) / 3.0
    flowLayout.minimumInteritemSpacing = space
    flowLayout.minimumLineSpacing = space
    flowLayout.itemSize = CGSize(width: dimension, height: dimension)

    getDefaultPics()
    //(pics, resultsPageNumber) = PhotoRequest.getPics() as! ([UIImage], Int)
  }


  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    guard let latitude  = latitude,
      let longitude = longitude else {
        print("don't have valid coordinates here")
        return
    }

    activityIndicator.startAnimating()

    // check to see if we have any photos persisted, if not, let's get them!

    do {
      let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Photo")
      let photos = try managedContext.fetch(fetchRequest)
      if photos.count > 0 {
        pics = []
        for photo in photos {
          if let image = photo.value(forKey: "image") as? UIImage {
            pics.append(image)
          }
        }
        DispatchQueue.main.async {
          print("displaying photos from Core Data!")
          self.photoCollectionView.reloadData()
          self.activityIndicator.stopAnimating()
        }
      } else {

        /*
         FlickrClient.getPhotoList(latitude: latitude,
         longitude: longitude,
         totalNumPicsAvailable: totalNumPicsAvailable,
         updatedNumPicsToDisplay: maxPicsDisplayed,
         maxNumPicsDisplayed: maxPicsDisplayed) { (flickrPhotos, totalNumPics, error) in
         self.updateCollectionView(flickrPhotos: flickrPhotos, totalNumPics: totalNumPics, error: error)
         }
         */
        FlickrClient.getFlickrPhotos(latitude: latitude, longitude: longitude) { (flickrPhotos, totalNums, error) in
/*
          guard let flickrPhotos = flickrPhotos,
            let totalNumPics = totalNums else
          {
            self.activityIndicator.stopAnimating()
            if let error = error {
              print("we got an error \(error)")
            }
            return
          }

          self.flickrPhotos = flickrPhotos
          self.totalNumPicsAvailable = totalNumPics

          self.photoCollectionView.reloadData()
          self.activityIndicator.stopAnimating()
*/
          self.updateCollectionView2(flickrPhotos: flickrPhotos, totalNumPics: totalNums, error: error)
        } // end gotPhotoList
      } // end else
    } // end do

    catch let error as NSError {
      print("Could not fetch data for photos. \(error), \(error.userInfo)")
    }

  }
  /*
   // Function: OBE
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
   */

  func getDefaultPics() {
    for _ in 0..<maxPicsDisplayed {
      if let image = UIImage(named: "Placeholder1") {
        pics.append(image)
      }
    }
    photoCollectionView.reloadData()
  }

  func updateCollectionView2(flickrPhotos: [FlickrPhoto]?, totalNumPics: Int?, error: Error?, updateAllPics: Bool = true) {

    guard let flickrPhotos = flickrPhotos,
      let totalNumPics = totalNumPics else
    {
      self.activityIndicator.stopAnimating()
      if let error = error {
        print("we got an error \(error)")
      }
      return
    }

    self.flickrPhotos = flickrPhotos
    self.totalNumPicsAvailable = totalNumPics

    self.photoCollectionView.reloadData()
    self.activityIndicator.stopAnimating()

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

  func addPhoto() {

  }

  func removePhoto() {

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
    //return pics.count
    return flickrPhotos.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reusePhotoCellIdentifier, for: indexPath) as! PhotoCollectionViewCell
    //let pic = self.pics[(indexPath as NSIndexPath).row]

   // cell.photoImageView.image = pic

    // first, we'll put a placeholder here
    // then, we'll check to see if FlickerPhoto.photoImage exists, display that
    // else download the image from flickr

    cell.photoImageView.image = UIImage(named: "Placeholder1")

    let flickrPhoto = self.flickrPhotos[(indexPath as NSIndexPath).row]
    if let image = flickrPhoto.photoImage {
      cell.photoImageView.image = image
    } else {
      FlickrClient.downloadImage(imageURL: flickrPhoto.flickrImageURL()) { (data, error) in
        guard let data = data else {
          return
        }
        let image = UIImage(data: data)
        cell.photoImageView.image = image
      }
    }
  
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
