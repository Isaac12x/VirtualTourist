//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Isaac Albets Ramonet on 19/02/16.
//  Copyright © 2016 team. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var barButtonActionable: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var toolBarToDelete: UIToolbar!
    @IBOutlet weak var toolBarButtonToDisplay: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    var editingModeIsActive = false
    var longPressGestureRecognizer: UILongPressGestureRecognizer!
    var dropedPin: Pin? = nil
    var areWeEditing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup
        self.navigationItem.title = "Virtual Tourist"
        barButtonActionable.title = EditPinsOnMap.startEditing
        

        
        mapView.delegate = self
        addLongPressGestureToDropPinOnMap()

        toolBarToDelete.hidden = true
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        
        
        // MARK: - Add pins to map from Core Data
        let pins = fetchAllPins()
        if !pins.isEmpty{
            for x in pins{
                mapView.addAnnotation(x)
            }
        }

    }
    
    // MARK: - Setup GestureRecognizer, navbar and toolbar
    func addLongPressGestureToDropPinOnMap(){
        longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "dropNewPin:")
        longPressGestureRecognizer.minimumPressDuration = 0.4
        view.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    func removeLongPressDropPinGestureRecognizer(){
        view.removeGestureRecognizer(longPressGestureRecognizer)
    }
    
    struct EditPinsOnMap{
        static let startEditing = "Edit"
        static let doneEditing = "Done"
    }
    
    
    // MARK: - Enter in edit mode
    @IBAction func editModeButtonAction(sender: UIBarButtonItem){
        areWeEditing = areWeEditing == true ? false : true
        
        if areWeEditing == true{
            barButtonActionable.title = EditPinsOnMap.doneEditing
            animateMapViewConstraintChange()
            removeLongPressDropPinGestureRecognizer()
        } else {
            barButtonActionable.title = EditPinsOnMap.startEditing
            animateMapViewConstraintChange()
            addLongPressGestureToDropPinOnMap()
        }
    }

    // MARK: - Drop new pin on the map
    func dropNewPin(gestureRecognizer: UIGestureRecognizer){
        
        let touchPoint = gestureRecognizer.locationInView(mapView)
        let touchCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)

        
        if gestureRecognizer.state != UIGestureRecognizerState.Began{
            
            let pinAsDict = [
                "lat": NSNumber(double: touchCoordinate.latitude),
                "long": NSNumber(double: touchCoordinate.longitude),
            ]
            
            dropedPin = Pin(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude, context: sharedContext)
            dropedPin!.coordinate = touchCoordinate
            mapView.addAnnotation(dropedPin!)
        } else if gestureRecognizer.state == UIGestureRecognizerState.Changed{
        dropedPin!.willChangeValueForKey("coordinate")
            dropedPin?.coordinate = touchCoordinate
        dropedPin!.didChangeValueForKey("coordinate")
        } else if gestureRecognizer.state == UIGestureRecognizerState.Ended{
            self.downloadImages(dropedPin!)
        }
        
    }
    
    
    // MARK: - Mapview delegates
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let mapPin = "droppedPin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(mapPin) as? MKPinAnnotationView
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: mapPin)
        } else {
            pinView!.annotation = annotation
        }
        
        pinView!.animatesDrop = true
        pinView!.draggable = true
        pinView!.setSelected(true, animated: true)
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        view.setSelected(true, animated: true)
        
        let pin = view.annotation as! Pin
        
        
        if editingModeIsActive == true {
            deleteSelectedPin(pin)
        } else {
            dropedPin = pin
            performSegueWithIdentifier("PhotoAlbumSegue", sender: self)
        }
        
    }
    
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        if fullyRendered.boolValue == true{
            activityIndicator.hidden = true
            activityIndicator.stopAnimating()
            
        } else {
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
        }
    }
    
    // MARK: - Networking - request to Flickr

    func downloadImages(annotation: MKAnnotation){
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
            
            }
        }


    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PhotoAlbumSegue"{
            let PhotoAlbumVC = segue.destinationViewController as! PhotoAlbumViewController
            PhotoAlbumVC.pin = dropedPin
            
            //Data to be passed
        }
    }
    
    // MARK: - CoreData
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func fetchAllPins() -> [Pin] {
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: sharedContext)
        
        do {
            let results = try sharedContext.executeFetchRequest(fetchRequest)
            return results as! [Pin]
        } catch {
            return [Pin]()
        }
    }
    
    // MARK: - Delete Pin
    func deleteSelectedPin(pin: Pin){
        mapView.removeAnnotation(pin)
        sharedContext.deleteObject(pin)
        CoreDataStackManager.sharedInstance().saveContext()
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
    
    func animateMapViewConstraintChange(){
        if areWeEditing {
        // slide up
            toolBarToDelete.hidden = false
            UIView.animateWithDuration(0.4) {
                self.view.layoutIfNeeded()
        }
        
        } else {
            // slide down
            toolBarToDelete.hidden = true
            UIView.animateWithDuration(0.4) {
            self.view.layoutIfNeeded()
        }
        }
    }


}

