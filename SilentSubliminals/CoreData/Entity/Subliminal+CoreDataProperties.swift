//
//  Subliminal+CoreDataProperties.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 27.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//
//

import Foundation
import CoreData


extension Subliminal {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Subliminal> {
        return NSFetchRequest<Subliminal>(entityName: "Subliminal")
    }

    @NSManaged public var order: Int16
    @NSManaged public var text: String?
    @NSManaged public var libraryItem: LibraryItem?

}

extension Subliminal : Identifiable {

}
