//
//  ChangeSet.m
//  DiffKit
//
//  Created by Star Zhu on 2022/10/16.
//

#import "ChangeSet.h"

@implementation ChangeSetIndexPair

- (BOOL)isEqual:(ChangeSetIndexPair *)object {
    if (![object isKindOfClass:[ChangeSetIndexPair class]]) {
        return NO;
    }
    return self.source == object.source && self.target == object.target;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"(source: %ld, target: %ld)", self.source, self.target];
}

@end

@implementation ChangeSetIdPair

- (BOOL)isEqual:(ChangeSetIdPair *)object {
    if (![object isKindOfClass:[ChangeSet class]]) {
        return NO;
    }
    return [self.source isEqual:object.source] && [self.target isEqual:object.target];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"(source: %@, target: %@)", ((NSObject *)(self.source)).debugDescription, ((NSObject *)(self.target)).debugDescription];
}

@end

@implementation ChangeSet

- (instancetype)initWithData:(NSArray *)data {
    self = [super init];
    if (self) {
        self.data = data;
    }
    return self;
}

- (NSInteger)sectionChangeCount {
    return self.sectionDeleted.count
        + self.sectionInserted.count
        + self.sectionUpdated.count
        + self.sectionMoved.count;
}

- (NSInteger)elementChangeCount {
    return self.elementDeleted.count
        + self.elementInserted.count
        + self.elementUpdated.count
        + self.elementMoved.count;
}

- (NSInteger)changeCount {
    return self.sectionChangeCount + self.elementChangeCount;
}

- (BOOL)hasSectionChanges {
    return self.sectionChangeCount > 0;
}

- (BOOL)hasElementChanges {
    return self.elementChangeCount > 0;
}

- (BOOL)hasChanges {
    return self.changeCount > 0;
}

- (BOOL)isEqual:(ChangeSet *)object {
    if (![object isKindOfClass:[ChangeSet class]]) {
        return NO;
    }
    return [self.data isEqual:object]
        && [[NSSet setWithArray:self.sectionDeleted] isEqual:[NSSet setWithArray:object.sectionDeleted]]
        && [[NSSet setWithArray:self.sectionInserted] isEqual:[NSSet setWithArray:object.sectionInserted]]
        && [[NSSet setWithArray:self.sectionUpdated] isEqual:[NSSet setWithArray:object.sectionUpdated]]
        && [[NSSet setWithArray:self.sectionMoved] isEqual:[NSSet setWithArray:object.sectionMoved]]
        && [[NSSet setWithArray:self.elementDeleted] isEqual:[NSSet setWithArray:object.elementDeleted]]
        && [[NSSet setWithArray:self.elementInserted] isEqual:[NSSet setWithArray:object.elementInserted]]
        && [[NSSet setWithArray:self.elementUpdated] isEqual:[NSSet setWithArray:object.elementUpdated]]
        && [[NSSet setWithArray:self.elementMoved] isEqual:[NSSet setWithArray:object.elementMoved]];
}

- (NSString *)debugDescription {
    if (self.data.count == 0 && ![self hasChanges]) {
        return [NSString stringWithFormat:@"Changeset(\n    data: []\n)"];
    }
    __block NSMutableString *dataDescription = [NSMutableString string];
    if (self.data.count == 0) {
        dataDescription.string = @"[]";
    } else {
        NSMutableArray *dataStrings = [NSMutableArray arrayWithCapacity:self.data.count];
        for (NSObject *single in self.data) {
            [dataStrings addObject:single.debugDescription];
        }
        NSString *dataString = [[[dataStrings componentsJoinedByString:@",\n"] componentsSeparatedByString:@"\n"] componentsJoinedByString:@"\n        "];
        dataDescription.string = [NSString stringWithFormat:@"[\n        %@\n    ]", dataString];
    }
    dataDescription.string = [NSString stringWithFormat:@"Changeset(\n    data: %@", dataDescription];
    
    void(^appendDescription)(NSString *, NSArray *) = ^(NSString *name, NSArray *elements) {
        if (elements.count == 0 ) {
            return;
        }
        NSMutableArray *elementStrings = [NSMutableArray arrayWithCapacity:elements.count];
        for (NSObject *element in elements) {
            [elementStrings addObject:element.debugDescription];
        }
        NSString *description = [NSString stringWithFormat:@",\n    %@: [\n        %@\n    ]",
                           name,
                           [[[elementStrings componentsJoinedByString:@",\n"] componentsSeparatedByString:@"\n"] componentsJoinedByString:@"\n        "]
        ];
        [dataDescription appendString:description];
    };
    
    appendDescription(@"sectionDeleted", self.sectionDeleted);
    appendDescription(@"sectionInserted", self.sectionInserted);
    appendDescription(@"sectionUpdated", self.sectionUpdated);
    appendDescription(@"sectionMoved", self.sectionMoved);
    appendDescription(@"elementDeleted", self.elementDeleted);
    appendDescription(@"elementInserted", self.elementInserted);
    appendDescription(@"elementUpdated", self.elementUpdated);
    appendDescription(@"elementMoved", self.elementMoved);
    
    [dataDescription appendString:@"\n)"];
    return [dataDescription copy];
}

@end
