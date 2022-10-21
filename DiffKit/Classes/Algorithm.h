//
//  Algorithm.h
//  DiffKit
//
//  Created by Star Zhu on 2022/10/16.
//

#import <Foundation/Foundation.h>
#import "StagedChangeset.h"
#import "DifferentiableSection.h"

NS_ASSUME_NONNULL_BEGIN

@interface StagedChangeset (Algorithm)

- (instancetype)initWithSource:(NSArray<Differentiable> *)source target:(NSArray<Differentiable> *)target section:(NSInteger)section;

- (instancetype)initWithSource:(NSArray<DifferentiableSection> *)source
                        target:(NSArray<DifferentiableSection> *)target;

@end

NS_ASSUME_NONNULL_END
