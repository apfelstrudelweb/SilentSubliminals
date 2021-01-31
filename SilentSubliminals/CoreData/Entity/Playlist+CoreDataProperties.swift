//
//  Playlist+CoreDataProperties.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 30.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//
//

import Foundation
import CoreData


extension Playlist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Playlist> {
        return NSFetchRequest<Playlist>(entityName: "Playlist")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var icon: Data?
    @NSManaged public var isDefault: Bool
    @NSManaged public var title: String?
    @NSManaged public var libraryItems: NSOrderedSet?

}

// MARK: Generated accessors for libraryItems
extension Playlist {

    @objc(insertObject:inLibraryItemsAtIndex:)
    @NSManaged public func insertIntoLibraryItems(_ value: LibraryItem, at idx: Int)

    @objc(removeObjectFromLibraryItemsAtIndex:)
    @NSManaged public func removeFromLibraryItems(at idx: Int)

    @objc(insertLibraryItems:atIndexes:)
    @NSManaged public func insertIntoLibraryItems(_ values: [LibraryItem], at indexes: NSIndexSet)

    @objc(removeLibraryItemsAtIndexes:)
    @NSManaged public func removeFromLibraryItems(at indexes: NSIndexSet)

    @objc(replaceObjectInLibraryItemsAtIndex:withObject:)
    @NSManaged public func replaceLibraryItems(at idx: Int, with value: LibraryItem)

    @objc(replaceLibraryItemsAtIndexes:withLibraryItems:)
    @NSManaged public func replaceLibraryItems(at indexes: NSIndexSet, with values: [LibraryItem])

    @objc(addLibraryItemsObject:)
    @NSManaged public func addToLibraryItems(_ value: LibraryItem)

    @objc(removeLibraryItemsObject:)
    @NSManaged public func removeFromLibraryItems(_ value: LibraryItem)

    @objc(addLibraryItems:)
    @NSManaged public func addToLibraryItems(_ values: NSOrderedSet)

    @objc(removeLibraryItems:)
    @NSManaged public func removeFromLibraryItems(_ values: NSOrderedSet)

}

extension Playlist : Identifiable {

}
