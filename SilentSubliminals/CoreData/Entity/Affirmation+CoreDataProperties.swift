//
//  Affirmation+CoreDataProperties.swift
//  
//
//  Created by Ullrich Vormbrock on 03.01.21.
//
//

import Foundation
import CoreData


extension Affirmation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Affirmation> {
        return NSFetchRequest<Affirmation>(entityName: "Affirmation")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var icon: Data?
    @NSManaged public var id: Int16
    @NSManaged public var lastPlayedDate: Date?
    @NSManaged public var text: String?
    @NSManaged public var title: String?
    @NSManaged public var soundfile: String?
    @NSManaged public var order: Int16
    @NSManaged public var isActive: Bool

}
