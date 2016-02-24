//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Isaac Albets Ramonet on 19/02/16.
//  Copyright © 2016 team. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionToolbar: UIToolbar!
    @IBOutlet weak var actionableButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var pin: Pin!
    
    var selectedIndexes = [NSIndexPath]()
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    var numberOfPhotoCurrentlyDownloading = 0
    
    
    let noImage = NSData(data: UIImagePNGRepresentation(UIImage(named: "noImage")!)!)

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back to Map", style: .Plain, target: self, action: nil)
        self.tabBarController?.title = "Pictures"
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        
        mapView.userInteractionEnabled = false
        actionableButton.title = ToolbarButtonTitle.newCollection
        newCollectionToolbar.hidden = true

        let logo = UIImage(named: "Logo")
        let imageView = UIImageView(image:logo)
        self.navigationItem.titleView = imageView
        // Do any additional setup after loading the view, typically from a nib.
        let space: CGFloat = 3.0
        let interSpace: CGFloat = 2.0
        let layoutWidth = (view.frame.size.width - (2 * space)) / 2.0
        let layoutHeight = (view.frame.size.height - (2 * space)) / 3.0
        
        // Flow layout interface spacing
        flowLayout.minimumInteritemSpacing = interSpace
        flowLayout.minimumLineSpacing = interSpace
        
        // Create item size depending on Meme View  - depending on screen
        flowLayout.itemSize = CGSizeMake(layoutWidth, layoutHeight)
        
        
        
        // MARK: - Core Data
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            NSLog("Fetch failed: \(error)")
        }
        
        if pin.pictures.isEmpty{
            
        }
        
        let region = MKCoordinateRegionMakeWithDistance(pin.coordinate, 100_000, 100_000)
        mapView.setRegion(region, animated: false)
        mapView.addAnnotation(pin)
        
        enableToolbar()
    }
    
    // MARK: - Set toolbar and button layouts
    struct ToolbarButtonTitle{
        static let newCollection = "New Collection"
        static let deleteImages = "Delete Selected Images"
    }
    
    func setToolbarButtonTitle() {
        if selectedIndexes.count > 0 {
            actionableButton.title = ToolbarButtonTitle.deleteImages
        } else {
            actionableButton.title = ToolbarButtonTitle.newCollection
        }
    }
    
    func enableToolbar(){
        if actionableButton.title == ToolbarButtonTitle.newCollection{
            if pin.isDownloading == true || numberOfPhotoCurrentlyDownloading > 0{
                actionableButton.enabled = false
            } else {
                actionableButton.enabled = true
            }
        } else {
            actionableButton.enabled = true
        }
    }
    
    // MARK: - Core Data
    
    var sharedContext: NSManagedObjectContext{
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let performFetch = NSFetchRequest(entityName: "Picture")
        performFetch.predicate = NSPredicate(format: "pin ==%@", self.pin)
        performFetch.sortDescriptors = [NSSortDescriptor(key: "imageName", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: performFetch, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    


    func newPhotoCollection(){
        if let fetchedObjects = fetchedResultsController.fetchedObjects{
            for x in fetchedObjects{
                let picture = x as! Pictures
                sharedContext.deleteObject(picture)
            }
            CoreDataStackManager.sharedInstance().saveContext()
        }
        downloadImages(pin)
    }
    
    func deletePhotos(){
        var deletedPictures = [Pictures]()
        for indexPath in selectedIndexes{
            deletedPictures.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Pictures)
            }
        for picture in deletedPictures{
            sharedContext.deleteObject(picture)
        }
        CoreDataStackManager.sharedInstance().saveContext()
        selectedIndexes = [NSIndexPath]()
        setToolbarButtonTitle()
    }
    
    // MARK: - Configure Cell
    func configureCell(cell: PhotoAlbumCollectionViewCell, atIndexPath indexPath: NSIndexPath){
        let picture = fetchedResultsController.objectAtIndexPath(indexPath) as! Pictures
    
        if let imageData = picture.imageData{
            cell.backgroundView = UIImageView(image: UIImage(data: imageData))
        }else {
            cell.backgroundView = UIImageView(image: UIImage(data: noImage))
            cell.activityIndicatorView.startAnimating()
        }
    }

    // MARK: - CollectionView

    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let picture = fetchedResultsController.objectAtIndexPath(indexPath) as! Pictures
        if picture.isFetched == false {
            return false
        }
        return true
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let picture = fetchedResultsController.objectAtIndexPath(indexPath) as! Pictures
        if picture.isFetched == false {
            return false
        }
        return true

    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedIndexes.append(indexPath)
        setToolbarButtonTitle()
        enableToolbar()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        }
        setToolbarButtonTitle()
        enableToolbar()
        
    }
    // MARK: - CollectionView Data Source

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CellForPicture", forIndexPath: indexPath) as! PhotoAlbumCollectionViewCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    // MARK: - Networking

    func downloadImages(annotation: MKAnnotation){
        
        if pin.isDownloading == true{
            return
        } else {
            pin.isDownloading = true
        }
        
        let resource = FlickrClient.Methods.FindByLatLon
        let params: [String:AnyObject] = [
            FlickrClient.ParameterKeys.ApiKey: FlickrClient.Constants.ApiKey,
            FlickrClient.ParameterKeys.Lat:  (annotation.coordinate.latitude),
            FlickrClient.ParameterKeys.Long: (annotation.coordinate.longitude),
            FlickrClient.ParameterKeys.Extras: FlickrClient.ParameterValues.Extras,
            FlickrClient.ParameterKeys.DataFormatFormat: FlickrClient.ParameterValues.DataFormat,
            FlickrClient.ParameterKeys.CallBackKey: FlickrClient.ParameterValues.CallBack,
        ]
        
        if hasConnectivity(){
            
            FlickrClient.sharedInstance().taskForGet(resource, parameters: params){ (jsonDict, error) in
                // Handle the error case
                if let error = error {
                    print("Error searching for actors: \(error.localizedDescription)")
                    return
                }
                
                if let photoDict = jsonDict.valueForKey("photos") as? [String: AnyObject] {
                    let fetchedPics = Pictures(imageName: photoDict["imageName"]! as! String, context: self.sharedContext)
                    //fetchedPics.pin = pin
                    print(photoDict)
                }
                dispatch_async(dispatch_get_main_queue()){
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                
            }
            self.pin.isDownloading = false
        }
    }
    
    /* Helper: Check Connectivity */
    func hasConnectivity() -> Bool{
        let reachable: Reachability = Reachability.reachabilityForInternetConnection()
        let networkStatus: Int = reachable.currentReachabilityStatus().rawValue
        if networkStatus != 0{
            return true
        } else {
            return false
        }
    }

    // MARK: - NSFetchedResultsController delegates

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        self.activityIndicatorView.stopAnimating()
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
        case .Delete:
            deletedIndexPaths.append(indexPath!)
        case .Update:
            updatedIndexPaths.append(indexPath!)
        default:
            return
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView.performBatchUpdates({
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            }, completion: nil)
    }






}