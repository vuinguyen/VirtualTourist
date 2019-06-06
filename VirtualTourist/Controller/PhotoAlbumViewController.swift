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
  
  @IBOutlet weak var noPicturesLabel: UILabel!
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

    updateWithPics(picsUpdated: false)

    if picSelectionMode {
      print("we're in pic selection mode, yo!")
      print("Indices of pics to remove, BEFORE: \(indexPathsOfPicsToRemove)")

      FlickrClient.getFlickrPhotos(latitude: latitude,
                                   longitude: longitude,
                                   totalNumPicsAvailable: totalNumPicsAvailable,
                                   updatedNumPicsToDisplay: indexPathsOfPicsToRemove.count,
                                   maxNumPicsDisplayed: maxPicsDisplayed) { (flickrPhotos, totalNums, error) in
                                    self.updateCollectionView(flickrPhotos: flickrPhotos, totalNumPics: totalNums, error: error, updateAllPics: false)
      }

    } else {
      print("we're getting all new pics!")

      // let's call flickr here
      print("downloading data from Flickr!")
      FlickrClient.getFlickrPhotos(latitude: latitude,
                                   longitude: longitude,
                                   totalNumPicsAvailable: totalNumPicsAvailable,
                                   updatedNumPicsToDisplay: maxPicsDisplayed,
                                   maxNumPicsDisplayed: maxPicsDisplayed) { (flickrPhotos, totalNums, error) in
                                    self.updateCollectionView(flickrPhotos: flickrPhotos, totalNumPics: totalNums, error: error)

      }

    }

  }

  private let reusePhotoCellIdentifier = "PhotoCollectionViewCell"

  // This will be OBE soon
  var pics = [UIImage]()

  var mapAnnotation: MKPointAnnotation?
  var pin: Pin?
  var latitude: Double?
  var longitude: Double?
  var picSelectionMode = false
  var indexPathsOfPicsToRemove = [IndexPath]()

  // total number of pics available on Flickr for this latitude and longitude
  var totalNumPicsAvailable: Int = 0

  let maxPicsDisplayed = 12
  var flickrPhotos = [FlickrPhoto]()

  var appDelegate: AppDelegate!
  var managedContext: NSManagedObjectContext!
  var fetchedResultsController:NSFetchedResultsController<Photo>!

  var blockOperations: [BlockOperation] = []

  deinit {
    // Cancel all block operations when VC deallocates
    for operation: BlockOperation in blockOperations {
      operation.cancel()
    }

    blockOperations.removeAll(keepingCapacity: false)
  }

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
  }


  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    guard let latitude  = latitude,
      let longitude = longitude else {
        print("don't have valid coordinates here")
        return
    }

    updateWithPics(picsUpdated: false)

    // check to see if we have any photos persisted, if not, let's get them!
    do {
      //let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Photo")

      guard let pin = pin else {
        return
      }
      let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
      let predicate = NSPredicate(format: "pin == %@", pin)
      fetchRequest.predicate = predicate
      let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
      fetchRequest.sortDescriptors = [sortDescriptor]

      fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext
        , sectionNameKeyPath: nil, cacheName: "\(pin)-photos")
      fetchedResultsController.delegate = self
      //let photos = try managedContext.fetch(fetchRequest)
      try fetchedResultsController.performFetch()
      guard let photos = fetchedResultsController.fetchedObjects else {
        return
      }
      if photos.count > 0 {
        // This must be completely rewritten to use data
        // saved from Flickr

        flickrPhotos = []
        //pics = []
        for photo in photos {
          if let image = photo.value(forKey: "image") as? UIImage,
             let id    = photo.value(forKey: "id") as? String,
             let farm = photo.value(forKey: "farm") as? Int,
             let server = photo.value(forKey: "server") as? String,
             let secret = photo.value(forKey: "secret") as? String {
            flickrPhotos.append(FlickrPhoto(photoID: id, farm: farm, server: server, secret: secret, photoImage: image))
          }

        }
        DispatchQueue.main.async {
          print("displaying photos from Core Data!")
          self.updateWithPics(picsUpdated: true)
        }
      } else {
        FlickrClient.getFlickrPhotos(latitude: latitude,
                                     longitude: longitude,
                                     totalNumPicsAvailable: totalNumPicsAvailable,
                                     updatedNumPicsToDisplay: maxPicsDisplayed,
                                     maxNumPicsDisplayed: maxPicsDisplayed) { (flickrPhotos, totalNums, error) in
          self.updateCollectionView(flickrPhotos: flickrPhotos, totalNumPics: totalNums, error: error)
        } // end gotPhotoList
      } // end else
    } // end do

    catch let error as NSError {
      print("Could not fetch data for photos. \(error), \(error.userInfo)")
    }

  }

  // This should be OBE soon
  /*
  func getDefaultPics() {
    for _ in 0..<maxPicsDisplayed {
      if let image = UIImage(named: "Placeholder1") {
        pics.append(image)
      }
    }
    photoCollectionView.reloadData()
  }
 */

  func updateCollectionView(flickrPhotos: [FlickrPhoto]?, totalNumPics: Int?, error: Error?, updateAllPics: Bool = true) {

    guard let flickrPhotos = flickrPhotos,
      let totalNumPics = totalNumPics else
    {
      self.flickrPhotos = []
      noPicturesLabel.isHidden = false
      updateWithPics(picsUpdated: true)

      if let error = error {
        print("we got an error \(error)")
      }
      return
    }

    // keep the total number of pics available for location current
    self.totalNumPicsAvailable = totalNumPics

    if updateAllPics == true {
      self.flickrPhotos = []
      // TODO: Add here AND in Core Data
      //self.flickrPhotos = flickrPhotos

    } else {
      // Remove old pictures from collection view first

      // I have to do this weird thing where I sort and reverse the indexPaths to fix a bug
      // I was getting as pictures were being deleted
      // see stackoverflow below for explanation:
      // https://stackoverflow.com/a/42432585
      for indexPath in indexPathsOfPicsToRemove.sorted().reversed() {
        // TODO: remove from here, AND from CoreData
        //self.flickrPhotos.remove(at: indexPath.row)
        //deletePhoto(at: indexPath)
        deletePhoto(at: indexPath)

        // deselect the pictures that were removed
        let cell = photoCollectionView.cellForItem(at: indexPath) as! PhotoCollectionViewCell
        cell.backgroundColor = .none
      }

      // TODO: add here, AND in CoreData
      //self.flickrPhotos.append(contentsOf: flickrPhotos)


      // set everything back to original settings
      collectionEditButton.setTitle("New Collection", for: .normal)
      picSelectionMode = false
      indexPathsOfPicsToRemove = []
      print("Indices of pics to remove, AFTER: \(indexPathsOfPicsToRemove)")
    }

    for photo in flickrPhotos {
      addPhoto(flickrPhoto: photo)
    }

    updateWithPics(picsUpdated: true)
  }

  // other items to update, before or after pictures are updated
  func updateWithPics(picsUpdated: Bool = true) {

    // setting things up after update
    if picsUpdated {
      photoCollectionView.reloadData()
      collectionEditButton.isEnabled = true
      activityIndicator.stopAnimating()
    } else {
      // set things up before picture update
      noPicturesLabel.isHidden = true
      collectionEditButton.isEnabled = false
      activityIndicator.startAnimating()
    }
  }

  func addPhoto(flickrPhoto: FlickrPhoto) {
    // add to Core Data

    // add to collection view
    flickrPhotos.append(flickrPhoto)
  }

  func deletePhoto(at indexPath: IndexPath) {
    // delete from Core Data

    /*
    do {
      let photoToDelete = fetchedResultsController.object(at: indexPath)
      if photoToDelete != nil {
        managedContext.delete(photoToDelete)
      }

      try managedContext.save()

    } catch _ as NSError {
      print("unable to delete photo")
    }
*/
    // delete from collection view
    self.flickrPhotos.remove(at: indexPath.row)
  }

  // OBE: will remove soon
  /*
  func updateCollectionViewOld(flickrPhotos: [FlickrPhoto]?, totalNumPics: Int?, error: Error?, updateAllPics: Bool = true) {
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
 */


  
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

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    if type == NSFetchedResultsChangeType.insert {
      print("Insert Object: \(String(describing: newIndexPath))")

      blockOperations.append(
        BlockOperation(block: { [weak self] in
          if self != nil {
            self?.photoCollectionView!.insertItems(at: [newIndexPath!])
          }
        })
      )
    }
    else if type == NSFetchedResultsChangeType.update {
      print("Update Object: \(String(describing: indexPath))")
      blockOperations.append(
        BlockOperation(block: { [weak self] in
          if self != nil {
            self?.photoCollectionView!.reloadItems(at: [indexPath!])
          }
        })
      )
    }
    else if type == NSFetchedResultsChangeType.move {
      print("Move Object: \(String(describing: indexPath))")

      blockOperations.append(
        BlockOperation(block: { [weak self] in
          if self != nil {
            self?.photoCollectionView!.moveItem(at: indexPath!, to: newIndexPath!)
          }
        })
      )
    }
    else if type == NSFetchedResultsChangeType.delete {
      print("Delete Object: \(String(describing: indexPath))")

      blockOperations.append(
        BlockOperation(block: { [weak self] in
          if self != nil {
            self?.photoCollectionView!.deleteItems(at: [indexPath!])
          }
        })
      )
    }
  }

  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    if type == NSFetchedResultsChangeType.insert {
      print("Insert Section: \(sectionIndex)")

      blockOperations.append(
        BlockOperation(block: { [weak self] in
          if self != nil {
            self?.photoCollectionView!.insertSections(NSIndexSet(index: sectionIndex) as IndexSet)
          }
        })
      )
    }
    else if type == NSFetchedResultsChangeType.update {
      print("Update Section: \(sectionIndex)")
      blockOperations.append(
        BlockOperation(block: { [weak self] in
          if self != nil {
            self?.photoCollectionView!.reloadSections(NSIndexSet(index: sectionIndex) as IndexSet)
          }
        })
      )
    }
    else if type == NSFetchedResultsChangeType.delete {
      print("Delete Section: \(sectionIndex)")

      blockOperations.append(
        BlockOperation(block: { [weak self] in
          if self != nil {
            self?.photoCollectionView!.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet)
          }
        })
      )
    }
  }

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    photoCollectionView.performBatchUpdates({ () -> Void in
      for operation: BlockOperation in self.blockOperations {
        operation.start()
      }
    }, completion: { (finished) -> Void in
      self.blockOperations.removeAll(keepingCapacity: false)
    })
  }
}
