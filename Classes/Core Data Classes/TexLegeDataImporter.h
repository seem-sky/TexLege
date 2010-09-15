//
//  TexLegeDataImporter.h
//  TexLege
//
//  Created by Gregory Combs on 9/15/10.
//  Copyright 2010 Gregory S. Combs. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface TexLegeDataImporter : NSObject {

}
@property (nonatomic,retain) NSManagedObjectContext *managedObjectContext;

- (id) initWithManagedObjectContext:(NSManagedObjectContext*)newContext;
- (void)importAllDataObjects;
- (void)importObjectsWithEntityName:(NSString *)entityName;
	
@end
