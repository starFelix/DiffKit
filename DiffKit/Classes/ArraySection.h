//
//  ArraySection.h
//  DiffKit
//
//  Created by Star Zhu on 2022/10/16.
//

#import <Foundation/Foundation.h>
#import "DifferentiableSection.h"

NS_ASSUME_NONNULL_BEGIN

@interface ArraySection : NSObject<DifferentiableSection>

@property (nonatomic, strong) id<Differentiable> model;
@property (nonatomic, strong) NSArray<Differentiable> *elements;

- (id)initWithModel:(id<Differentiable>)model elements:(NSArray<Differentiable> *)elements;

@end

NS_ASSUME_NONNULL_END
