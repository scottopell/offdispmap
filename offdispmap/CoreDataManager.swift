//
//  CoreDataManager.swift
//  offdispmap
//
//  Created by Scott Opell on 7/5/24.
//

import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DispensaryModel")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func fetchDispensaries() -> [Dispensary] {
        let request: NSFetchRequest<Dispensary> = Dispensary.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching dispensaries: \(error)")
            return []
        }
    }
    
    func createOrUpdateDispensary(
        name: String,
        address: String,
        city: String,
        zipCode: String,
        website: String,
        isTemporaryDeliveryOnly: Bool,
        isNYC: Bool
    ) -> Dispensary? {
        let fetchRequest: NSFetchRequest<Dispensary> = Dispensary.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        do {
            let results = try context.fetch(fetchRequest)
            let managedDispensary: Dispensary
            
            if let existingDispensary = results.first {
                managedDispensary = existingDispensary
            } else {
                managedDispensary = Dispensary(context: context)
            }
            
            // Update properties
            managedDispensary.name = name
            managedDispensary.address = address
            managedDispensary.city = city
            managedDispensary.zipCode = zipCode
            managedDispensary.website = website
            managedDispensary.isTemporaryDeliveryOnly = isTemporaryDeliveryOnly
            managedDispensary.isNYC = isNYC
            
            saveContext()
            return managedDispensary
        } catch {
            print("Error creating/updating dispensary: \(error)")
            return nil
        }
    }

    func deleteAllData() {
        let entities = persistentContainer.managedObjectModel.entities
        entities.compactMap({ $0.name }).forEach(clearEntity)
        saveContext()
        Logger.info("Deleted all managedObjectModel.entities")
    }
    
    private func clearEntity(_ entityName: String) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try persistentContainer.viewContext.execute(deleteRequest)
        } catch {
            print("Failed to clear entity \(entityName): \(error)")
        }
    }
}
