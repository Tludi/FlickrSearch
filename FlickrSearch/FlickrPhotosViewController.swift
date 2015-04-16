//
//  FlickrPhotosViewController.swift
//  
//
//  Created by manatee on 4/15/15.
//
//

import UIKit

// let reuseIdentifier = "Cell"

class FlickrPhotosViewController: UICollectionViewController {
  // the CollectionView object to be reused when iterating
  // In this case it is the view with the Identifier of FlickrCell
  private let reuseIdentifier = "FlickrCell"
  // sets the margins of the object on the view. In this case the FlickrCell
  private let sectionInsets = UIEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
  
  private var searches = [FlickrSearchResults]()
  private let flickr = Flickr()
  
  func photoForIndexPath(indexPath: NSIndexPath) -> FlickrPhoto {
    return searches[indexPath.section].searchResults[indexPath.row]
  }
  

}

extension FlickrPhotosViewController : UITextFieldDelegate {
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    textField.addSubview(activityIndicator)
    activityIndicator.frame = textField.bounds
    activityIndicator.startAnimating()
    flickr.searchFlickrForTerm(textField.text) {
      results, error in
      
      activityIndicator.removeFromSuperview()
      if error != nil {
        println("Error searching \(error)")
      }
      if results != nil {
        println("Found \(results!.searchResults.count) matching \(results!.searchTerm)")
        self.searches.insert(results!, atIndex: 0)
        
        self.collectionView?.reloadData()
      }
    }
  
    textField.text = nil
    textField.resignFirstResponder()
    return true
  }
}

extension FlickrPhotosViewController : UICollectionViewDataSource {
  
  //1
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return searches.count
  }
  
  //2
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return searches[section].searchResults.count
  }
  
  //3
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! FlickrPhotoCell
    let flickrPhoto = photoForIndexPath(indexPath)
    cell.backgroundColor = UIColor.blackColor()
    cell.imageView.image = flickrPhoto.thumbnail
    return cell
  }
}

extension FlickrPhotosViewController : UICollectionViewDelegateFlowLayout {
  //1
  func collectionView(collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
      
      let flickrPhoto =  photoForIndexPath(indexPath)
  //2
      if var size = flickrPhoto.thumbnail?.size {
        size.width += 10
        size.height += 10
        return size
      }
      return CGSize(width: 100, height: 100)
  }
  
  //3
  func collectionView(collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAtIndex section: Int) -> UIEdgeInsets {
      return sectionInsets
  }
}

