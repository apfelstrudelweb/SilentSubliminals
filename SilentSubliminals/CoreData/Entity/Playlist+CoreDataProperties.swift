//
//  Playlist+CoreDataProperties.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 25.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//
//

import Foundation
import CoreData


extension Playlist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Playlist> {
        return NSFetchRequest<Playlist>(entityName: "Playlist")
    }

    @NSManaged public var icon: Data?
    @NSManaged public var title: String?
    @NSManaged public var isDefault: Bool
    @NSManaged public var creationDate: Date?
    @NSManaged public var libraryItems: NSSet?

}

// MARK: Generated accessors for libraryItems
extension Playlist {

    @objc(addLibraryItemsObject:)
    @NSManaged public func addToLibraryItems(_ value: LibraryItem)

    @objc(removeLibraryItemsObject:)
    @NSManaged public func removeFromLibraryItems(_ value: LibraryItem)

    @objc(addLibraryItems:)
    @NSManaged public func addToLibraryItems(_ values: NSSet)

    @objc(removeLibraryItems:)
    @NSManaged public func removeFromLibraryItems(_ values: NSSet)

}

extension Playlist : Identifiable {

}
