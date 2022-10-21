//
//  StagedChangeset.m
//  DiffKit
//
//  Created by Star Zhu on 2022/10/16.
//

#import "StagedChangeset.h"

@interface StagedChangeset<Type> ()

@property (nonatomic, copy) NSArray<ChangeSet *> *changesets;

@end

@implementation StagedChangeset

- (instancetype)initWithChangesets:(NSArray *)changesets {
    self = [super init];
    if (self) {
        self.changesets = [NSMutableArray arrayWithArray:changesets];
    }
    return self;
}

- (instancetype)init {
    return [self initWithChangesets:@[]];
}

- (BOOL)isEqual:(StagedChangeset *)object {
    if (![object isKindOfClass:[StagedChangeset class]]) {
        return NO;
    }
    return [self.changesets isEqualToArray:object.changesets];
}

- (NSString *)debugDescription {
    if (self.changesets.count == 0) {
        return @"[]";
    }
    NSMutableArray *results = [NSMutableArray array];
    for (NSInteger i = 0; i < [self.changesets count]; i++) {
        ChangeSet *set = self.changesets[i];
        [results addObject:[[set.debugDescription componentsSeparatedByString:@"\n"] componentsJoinedByString:@"\n    "]];
    }
    return [NSString stringWithFormat:
                @"[\n%@\n]", [results componentsJoinedByString:@",\n"]
    ];
}

@end
