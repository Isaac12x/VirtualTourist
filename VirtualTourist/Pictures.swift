//
//  Pictures.swift
//  VirtualTourist
//
//  Created by Isaac Albets Ramonet on 20/02/16.
//  Copyright © 2016 team. All rights reserved.
//

import Foundation
import CoreData

class Pictures: NSManagedObject {
    
    @NSManaged var imageName: String
    @NSManaged var isFetched: Bool
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?){
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imageName: String, context: NSManagedObjectContext){
        let entity = NSEntityDescription.entityForName("Pictures", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.imageName = imageName
    }
    
    
    var localURL: NSURL{
        let url = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first!
        return url.URLByAppendingPathComponent(imageName)
    }
    
    var imageData: NSData? {
        var imageData: NSData? = nil
        if NSFileManager.defaultManager().fileExistsAtPath(localURL.path!){
            imageData = NSData(contentsOfURL: localURL)
        }
        return imageData
    }

    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        if NSFileManager.defaultManager().fileExistsAtPath(localURL.path!){
            do {
             //try NSFileManager.defaultManager().removeItemAtPath(localURL)
            }  catch {
                NSLog("Couldn't remove image: \(imageName)")
            }
        }
    }
    
}