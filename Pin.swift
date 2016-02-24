//
//  Pin.swift
//  VirtualTourist
//
//  Created by Isaac Albets Ramonet on 19/02/16.
//  Copyright © 2016 team. All rights reserved.
//

import MapKit
import CoreData

class Pin: NSManagedObject, MKAnnotation {
    
    @NSManaged var lat: Double
    @NSManaged var long: Double
    @NSManaged var isDownloading: Bool
    @NSManaged var pictures: [Pictures]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(latitude: Double, longitude: Double , context: NSManagedObjectContext){
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.lat = latitude
        self.long = longitude
    }
    
    var coordinate: CLLocationCoordinate2D{
        get {
            let coordinate =  CLLocationCoordinate2DMake(lat as CLLocationDegrees, long as CLLocationDegrees)
            return coordinate
        }
        
        set (newValue){
            lat = newValue.latitude
            long = newValue.longitude
        }
    }


}