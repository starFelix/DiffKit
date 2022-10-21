//
//  DifferentiableSection.h
//  DiffKit
//
//  Created by Star Zhu on 2022/10/16.
//

#import <Foundation/Foundation.h>
#import "Differentiable.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DifferentiableSection <Differentiable>

- (NSArray<Differentiable> *)elements;

- (instancetype)initWithSource:(id<DifferentiableSection>)source elements:(NSArray<id<Differentiable>> *)elements;

@end

NS_ASSUME_NONNULL_END
