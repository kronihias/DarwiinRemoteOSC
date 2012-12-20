//
//  KeyConfiguration_AppDelegate.h
//  KeyConfiguration
//
//  Created by KIMURA Hiroaki on 06/12/16.
//  Copyright KIMURA Hiroaki 2006 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KeyConfiguration_AppDelegate : NSObject 
{    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (IBAction)saveAction:sender;

@end
