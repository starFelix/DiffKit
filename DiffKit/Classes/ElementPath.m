//
//  ElementPath.m
//  DiffKit
//
//  Created by Star Zhu on 2022/10/16.
//

#import "ElementPath.h"

@implementation ElementPath

- (instancetype)initWithElement:(NSInteger)element section:(NSInteger)section {
    self = [super init];
    if (self) {
        self.element = element;
        self.section = section;
    }
    return self;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"[element: %ld, section: %ld]", (long)self.element, (long)self.section];
}

@end
