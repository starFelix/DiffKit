//
//  ArraySection.m
//  DiffKit
//
//  Created by Star Zhu on 2022/10/16.
//

#import "ArraySection.h"

@implementation ArraySection

- (nonnull id)differenceIdentifier {
    return self.model.differenceIdentifier;
}

- (id)initWithModel:(id<Differentiable>)model elements:(NSArray<id<Differentiable>> *)elements {
    self = [super init];
    if (self) {
        self.model = model;
        self.elements = elements;
    }
    return self;
}

- (id)initWithSource:(ArraySection *)source elements:(NSArray<id<Differentiable>> *)elements{
    return [self initWithModel:source.model elements:elements];
}

- (BOOL)isContentEqualTo:(ArraySection *)source {
    return [self.model isContentEqualTo:source.model];
}

- (BOOL)isEqual:(ArraySection *)object {
    if (![object isKindOfClass:[ArraySection class]]) {
        return NO;
    }
    //TODO: 数组判等是不是有问题
    return [object.model isEqual:self.model] && [object.elements isEqualToArray:self.elements];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"ArraySection(\n\tmodel: %@,\n\telements: %@\n)\n", self.model, self.elements];
}

@end
