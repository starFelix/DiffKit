//
//  ChangeSet.h
//  DiffKit
//
//  Created by Star Zhu on 2022/10/16.
//

#import <Foundation/Foundation.h>
#import "ElementPath.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChangeSetIndexPair : NSObject

@property (nonatomic, assign) NSInteger source;
@property (nonatomic, assign) NSInteger target;

@end

@interface ChangeSetIdPair<Type:id> : NSObject

@property (nonatomic, strong) Type source;
@property (nonatomic, strong) Type target;

@end

@interface ChangeSet<DataType: id> : NSObject

@property (nonatomic, strong) NSArray<DataType> *data;
@property (nonatomic, strong) NSArray<NSNumber *> *sectionDeleted;
@property (nonatomic, strong) NSArray<NSNumber *> *sectionInserted;
@property (nonatomic, strong) NSArray<NSNumber *> *sectionUpdated;
@property (nonatomic, strong) NSArray<ChangeSetIndexPair *> *sectionMoved;

@property (nonatomic, strong) NSArray<ElementPath *> *elementDeleted;
@property (nonatomic, strong) NSArray<ElementPath *> *elementInserted;
@property (nonatomic, strong) NSArray<ElementPath *> *elementUpdated;
@property (nonatomic, strong) NSArray<ChangeSetIdPair<ElementPath *> *> *elementMoved;

- (instancetype)initWithData:(NSArray<DataType> *)data;

- (NSInteger)sectionChangeCount;
- (NSInteger)elementChangeCount;
- (NSInteger)changeCount;
- (BOOL)hasSectionChanges;
- (BOOL)hasElementChanges;
- (BOOL)hasChanges;

@end

NS_ASSUME_NONNULL_END
