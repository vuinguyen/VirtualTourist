//
//  FlickrClient.swift
//  HelloFlickr
//
//  Created by Vui Nguyen on 5/26/19.
//  Copyright © 2019 SunfishEmpire. All rights reserved.
//

import UIKit

class FlickrClient {

  enum Error: Swift.Error {
    case unknownAPIResponse
    case generic
  }

  class func getPhotoList(latitude: Double, longitude: Double, completion: @escaping ([FlickrPhoto]?, Error?) -> Void) {
    let radius = 20
    let perPage = 20
    let pageNum = 2
    let searchURLString = "https://www.flickr.com/services/rest/?method=flickr.photos.search" +
      "&api_key=\(APIKeys.ApplicationID)" +
      "&lat=\(latitude)" +
      "&lon=\(longitude)" +
      "&radius=\(radius)" +
      "&per_page=\(perPage)" +
      "&page=\(pageNum)" +
    "&format=json&nojsoncallback=1"

    guard let searchURL = URL(string: searchURLString) else {
      return
    }
    let searchRequest = URLRequest(url: searchURL)

    let task = URLSession.shared.dataTask(with: searchRequest) { (data, response, error) in
      if let error = error {
        print("there is an error!: \(error)")
        return
      }

      guard let data = data else {
        return
      }

      print("we got a response back!: \(data)")

      // parse into Results, which contains photos (json objects)
      // from each photo json object, build a URL and grab data from the url
      // (this downloads the picture)
      // and then create an image object (UIImage) out of the downloaded data
      // (place into a Photo class?)
      // run completion handler of array of Photo objects
      // ie reload collection view with new data

      do {
        guard
          let resultsDictionary = try JSONSerialization.jsonObject(with: data) as? [String: AnyObject],
          let stat = resultsDictionary["stat"] as? String
          else {
            DispatchQueue.main.async {
              //completion(Result.error(Error.unknownAPIResponse))
              completion(nil, Error.unknownAPIResponse)
              print("error in getting data")

            }
            return
        }

        // check value of stat

        switch (stat) {
        case "ok":
          print("Results processed OK")
        case "fail":
          DispatchQueue.main.async {
            print("error in parsing stat")
            completion(nil, (Error.generic))
          }
          return
        default:
          DispatchQueue.main.async {
            print("error in parsing stat, in default")
            completion(nil, (Error.unknownAPIResponse))
          }
          return
        }

        guard
          let photosContainer = resultsDictionary["photos"] as? [String: AnyObject],
          let photosReceived = photosContainer["photo"] as? [[String: AnyObject]]
          else {
            DispatchQueue.main.async {
              print("photos not in proper format")
              completion(nil, (Error.unknownAPIResponse))
            }
            return
        }

        let flickrPhotos: [FlickrPhoto] = photosReceived.compactMap { photoObject in
          guard
            let photoID = photoObject["id"] as? String,
            let farm = photoObject["farm"] as? Int ,
            let server = photoObject["server"] as? String ,
            let secret = photoObject["secret"] as? String
            else {
              return nil
          }

          let flickrPhoto = FlickrPhoto(photoID: photoID, farm: farm, server: server, secret: secret)

          guard
            let url = flickrPhoto.flickrImageURL(),
            let imageData = try? Data(contentsOf: url as URL)
            else {
              return nil
          }

          if let image = UIImage(data: imageData) {
            flickrPhoto.photoImage = image
            return flickrPhoto
          } else {
            return nil
          }

        } // end of map here


        DispatchQueue.main.async {
          print("successfully downloaded pics!")
          completion(flickrPhotos, nil)
        }

      } catch {
        print("error yo!")
        return
      }

    }
    task.resume()

    /* https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=64e233835212207bf629d1cf4e11706f&lat=42.51089531399634&lon=-96.40061478111414&radius=20&per_page=12&page=2&format=json&nojsoncallback=1
     */


  }


}
