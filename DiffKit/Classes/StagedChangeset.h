//
//  StagedChangeset.h
//  DiffKit
//
//  Created by Star Zhu on 2022/10/16.
//

#import <Foundation/Foundation.h>
#import "ChangeSet.h"

NS_ASSUME_NONNULL_BEGIN

@interface StagedChangeset<Type: id> : NSObject

@property (nonatomic, copy, readonly) NSArray<ChangeSet<Type> *> *changesets;

- (instancetype)initWithChangesets:(NSArray<ChangeSet<Type> *> *)changesets;

@end

NS_ASSUME_NONNULL_END
