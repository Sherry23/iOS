#import <Foundation/Foundation.h>
#import "MCCategory.h"

static NSString * const recommendedCategory = @"RECOMMENDED";

@interface MCCategorySourceService : NSObject

+ (MCCategorySourceService *)sharedInstance;

- (void)importCategories;

//get/set user selected categories. Returns an array of NSString * in block.
- (void)fetchSelectedCategoriesAsync:(BOOL)shouldFetchAsync
                           withBlock:(void(^)(NSArray *, NSError *))block;

// Takes an array of NSString * categories.
- (void)storeSelectedCategories:(NSArray *)categories
                          async:(BOOL)shouldFetchAsync
                      withBlock:(void(^)(NSError *))block;

//Given a category name, return an array of MCSource Object corresponding to this category
- (void)fetchSourceByCategory:(NSString *)categoryName
                        async:(BOOL)shouldFetchAsync
                    withBlock:(void(^)(NSArray *, NSError *))block;

//Given a category name, return an MCCategory Object corresponding to this category
- (void)fetchCategory:(NSString *)categoryName
                async:(BOOL)shouldFetchAsync
            withBlock:(void(^)(MCCategory *, NSError *))block;

//Get an array of MCCategory for all categories
- (void) fetchAllCategoriesAsync:(BOOL)shouldFetchAsync
                       withBlock:(void(^)(NSArray *, NSError *))block;

@end
