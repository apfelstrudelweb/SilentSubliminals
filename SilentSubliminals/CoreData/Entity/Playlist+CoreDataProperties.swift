//
//  Playlist+CoreDataProperties.swift
//  
//
//  Created by Ullrich Vormbrock on 03.01.21.
//
//

import Foundation
import CoreData


extension Playlist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Playlist> {
        return NSFetchRequest<Playlist>(entityName: "Playlist")
    }

    @NSManaged public var affirmations: NSOrderedSet?

}

// MARK: Generated accessors for affirmations
extension Playlist {

    @objc(insertObject:inAffirmationsAtIndex:)
    @NSManaged public func insertIntoAffirmations(_ value: Affirmation, at idx: Int)

    @objc(removeObjectFromAffirmationsAtIndex:)
    @NSManaged public func removeFromAffirmations(at idx: Int)

    @objc(insertAffirmations:atIndexes:)
    @NSManaged public func insertIntoAffirmations(_ values: [Affirmation], at indexes: NSIndexSet)

    @objc(removeAffirmationsAtIndexes:)
    @NSManaged public func removeFromAffirmations(at indexes: NSIndexSet)

    @objc(replaceObjectInAffirmationsAtIndex:withObject:)
    @NSManaged public func replaceAffirmations(at idx: Int, with value: Affirmation)

    @objc(replaceAffirmationsAtIndexes:withAffirmations:)
    @NSManaged public func replaceAffirmations(at indexes: NSIndexSet, with values: [Affirmation])

    @objc(addAffirmationsObject:)
    @NSManaged public func addToAffirmations(_ value: Affirmation)

    @objc(removeAffirmationsObject:)
    @NSManaged public func removeFromAffirmations(_ value: Affirmation)

    @objc(addAffirmations:)
    @NSManaged public func addToAffirmations(_ values: NSOrderedSet)

    @objc(removeAffirmations:)
    @NSManaged public func removeFromAffirmations(_ values: NSOrderedSet)

}
