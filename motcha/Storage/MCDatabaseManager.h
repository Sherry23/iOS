#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

// A local storage manager that creates/deletes/fetches entities from a local database.
@interface MCDatabaseManager : NSObject

@property(nonatomic, readonly) NSManagedObjectContext *context;
@property(nonatomic, readonly) NSManagedObjectModel *model;

//- (instancetype)initWithName:(NSString *)name entities:(NSArray *)entities;
- (instancetype)initWithName:(NSString *)name;

- (NSManagedObject *)createEntityWithName:(NSString *)name;

- (NSArray *)fetchForEntitiesWithName:(NSString *)name
                          onPredicate:(NSPredicate *)predicate
                               onSort:(NSArray *)sortDescriptors;

- (void)deleteEntitiesWithName:(NSString *)name
                   onPredicate:(NSPredicate *)predicate;

@end
