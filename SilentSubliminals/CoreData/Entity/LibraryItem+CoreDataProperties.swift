//
//  LibraryItem+CoreDataProperties.swift
//  FREE UR SPIRIT
//
//  Created by Ullrich Vormbrock on 05.01.21.
//  Copyright © 2021 Ullrich Vormbrock. All rights reserved.
//
//

import Foundation
import CoreData


extension LibraryItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LibraryItem> {
        return NSFetchRequest<LibraryItem>(entityName: "LibraryItem")
    }

    @NSManaged public var icon: Data?
    @NSManaged public var title: String?
    @NSManaged public var lastUsedDate: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var creationDate: Date?
    @NSManaged public var soundFileName: String?
    @NSManaged public var hasOwnIcon: Bool
    @NSManaged public var playlist: Playlist?
    @NSManaged public var subliminals: NSSet?

}

// MARK: Generated accessors for subliminals
extension LibraryItem {

    @objc(addSubliminalsObject:)
    @NSManaged public func addToSubliminals(_ value: Subliminal)

    @objc(removeSubliminalsObject:)
    @NSManaged public func removeFromSubliminals(_ value: Subliminal)

    @objc(addSubliminals:)
    @NSManaged public func addToSubliminals(_ values: NSSet)

    @objc(removeSubliminals:)
    @NSManaged public func removeFromSubliminals(_ values: NSSet)

}

extension LibraryItem : Identifiable {

}
