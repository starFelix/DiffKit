//
//  Algorithm.m
//  DiffKit
//
//  Created by Star Zhu on 2022/10/16.
//

#import "Algorithm.h"

typedef id(^IndexMapAction)(NSInteger);

@class DiffResult;

extern DiffResult* diff(NSArray<Differentiable> *source,
                        NSArray<Differentiable> *target,
                        BOOL useTargetIndexForUpdated,
                        IndexMapAction mapIndex,
                        NSMutableArray* __nullable updatedElements,
                        NSMutableArray* __nullable notDeletedElements);

typedef id(^MapAction)(id, NSUInteger);
NSArray* map(NSArray *origin, MapAction action);
NSMutableArray* map_mutable(NSArray *origin, MapAction action);

@interface Trace<Type: id> : NSObject

@property (nonatomic, strong, nullable) Type reference;
@property (nonatomic, assign) NSInteger deleteOffset;
@property (nonatomic, assign) BOOL isTracked;

@end

@implementation Trace

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"Trace(isTracked:%@, deleteOffset:%ld, reference:%@)",
            self.isTracked ? @"YES" : @"NO",
            self.deleteOffset,
            [(NSObject *)self.reference debugDescription]];
}

@end

typedef enum : NSUInteger {
    OccurrenceTypeUnique,
    OccurrenceTypeDuplicate,
} OccurrenceType;

@interface IndicesReference : NSObject

@property (nonatomic, strong) NSMutableArray<NSNumber *> *indices;
@property (nonatomic, assign) NSInteger position;

@end

@implementation IndicesReference

- (instancetype)initWithIndices:(NSArray<NSNumber *> *)indices {
    self = [super init];
    if (self) {
        self.indices = [NSMutableArray arrayWithArray:indices];
        self.position = 0;
    }
    return self;
}

- (instancetype)init {
    return [self initWithIndices:@[]];
}

- (void)push:(NSInteger)index {
    [self.indices addObject:@(index)];
}

- (NSInteger)next {
    if (self.position >= self.indices.count || self.position < 0) {
        return NSNotFound;
    }
    NSInteger pos = [self.indices[self.position] integerValue];
    self.position += 1;
    return pos;
}

@end

@interface Occurrence : NSObject

@property (nonatomic, assign) OccurrenceType type;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) IndicesReference *reference;

@end

@implementation Occurrence

- (instancetype)initWithIndex:(NSInteger)index {
    self = [super init];
    if (self) {
        self.type = OccurrenceTypeUnique;
        self.index = index;
    }
    return self;
}

- (instancetype)initWithReference:(IndicesReference *)reference {
    self = [super init];
    if (self) {
        self.type = OccurrenceTypeDuplicate;
        self.reference = reference;
    }
    return self;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"Occurrence(type:%@,index:%ld,reference:%@)",
            self.type == OccurrenceTypeUnique ? @".unique" : @".duplicate",
            self.index,
            [(NSObject *)self.reference debugDescription]
    ];
}

@end

@interface DiffResult<Type: id> : NSObject

@property (nonatomic, copy) NSArray<Type> *deleted;
@property (nonatomic, copy) NSArray<Type> *inserted;
@property (nonatomic, copy) NSArray<Type> *updated;
@property (nonatomic, copy) NSArray<ChangeSetIdPair<Type> *> *moved;
@property (nonatomic, copy) NSArray<Trace<NSNumber *> *> *sourceTraces;
@property (nonatomic, copy) NSArray *targetReferences;

@end

@implementation DiffResult

@end

@implementation StagedChangeset (Algorithm)

- (instancetype)initWithSource:(NSArray<Differentiable> *)source target:(NSArray<Differentiable> *)target section:(NSInteger)section {
    NSArray<Differentiable> *sourceElements = source;
    NSArray<Differentiable> *targetElements = target;
    if (sourceElements.count == 0 && targetElements.count == 0) {
        return [self init];
    }
    
    // Return changesets that all deletions if source is not empty and target is empty.
    if (sourceElements.count > 0 && targetElements.count == 0) {
        ChangeSet *set = [[ChangeSet alloc] initWithData:target];
        set.elementDeleted = map(sourceElements, ^id(id element, NSUInteger index) {
            return [[ElementPath alloc] initWithElement:index section:section];
        });
        return [self initWithChangesets:@[set]];
    }
    
    // Return changesets that all insertions if source is empty and target is not empty.
    if (sourceElements.count == 0 && targetElements.count > 0) {
        ChangeSet *set = [[ChangeSet alloc] initWithData:target];
        set.elementInserted = map(targetElements, ^id(id element, NSUInteger index) {
            return [[ElementPath alloc] initWithElement:index section:section];
        });
        return [self initWithChangesets:@[set]];
    }
    
    NSMutableArray *firstStageElements = [NSMutableArray array];
    NSMutableArray *secondStageElements = [NSMutableArray array];
    
    DiffResult<ElementPath *> *result = diff(sourceElements,
                                             targetElements,
                                             NO,
                                             ^(NSInteger index) { return [[ElementPath alloc] initWithElement:index section:section];},
                                             firstStageElements,
                                             secondStageElements);
    
    NSMutableArray<ChangeSet *> *changesets = [NSMutableArray array];
    
    if (result.updated.count > 0) {
        ChangeSet *set = [[ChangeSet alloc] initWithData:[firstStageElements copy]];
        set.elementUpdated = result.updated;
        [changesets addObject:set];
    }
    if (result.deleted.count > 0) {
        ChangeSet *set = [[ChangeSet alloc] initWithData:[secondStageElements copy]];
        set.elementDeleted = result.deleted;
        [changesets addObject:set];
    }
    if (result.inserted.count > 0 || result.moved.count > 0) {
        ChangeSet *set = [[ChangeSet alloc] initWithData:target];
        set.elementInserted = result.inserted;
        set.elementMoved = result.moved;
        [changesets addObject:set];
    }
    if (changesets.count > 0) {
        NSInteger lastIndex = changesets.count - 1;
        changesets[lastIndex].data = target;
    }
    
    return [self initWithChangesets:changesets];
}

- (instancetype)initWithSource:(NSArray<DifferentiableSection> *)source
                        target:(NSArray<DifferentiableSection> *)target {
    NSArray<NSArray<Differentiable> *> *contiguousSourceSections = map(source, ^id(id<DifferentiableSection> section, NSUInteger index) {
        return section.elements;
    });
    NSArray<NSArray<Differentiable> *> *contiguousTargetSections = map(target, ^id(id<DifferentiableSection> section, NSUInteger index) {
        return section.elements;
    });
    
    NSMutableArray *firstStageSections = [NSMutableArray arrayWithArray:source];
    NSMutableArray *secondStageSections = [NSMutableArray array];
    NSMutableArray *thirdStageSections = [NSMutableArray array];
    NSMutableArray *fourthStageSections = [NSMutableArray array];
    
    NSMutableArray<NSMutableArray<Trace<ElementPath *> *> *> *sourceElementTraces = map_mutable(contiguousSourceSections, ^id(NSArray *section, NSUInteger index) {
        return map_mutable(section, ^id(id element, NSUInteger index) {
            return [[Trace alloc] init];
        });
    });
    NSMutableArray<NSMutableArray *> *targetElementReferences = map_mutable(contiguousTargetSections, ^id(NSArray* section, NSUInteger index) {
        return map_mutable(section, ^id(id element, NSUInteger index) {
            return [[NSObject alloc] init];
        });
    });
    
    NSInteger flattenSourceCount = 0;
    for (id<DifferentiableSection> section in source) {
        flattenSourceCount += section.elements.count;
    }
    NSMutableArray *flattenSourceIdentifiers = [NSMutableArray array];
    NSMutableArray<ElementPath *> *flattenSourceElementPaths = [NSMutableArray array];
    
    DiffResult<NSNumber *> *sectionResult = diff(source,
                                                 target,
                                                 YES,
                                                 ^(NSInteger e) {return @(e);},
                                                 nil,
                                                 nil);
    
    NSMutableArray *elementDeleted = [NSMutableArray array];
    NSMutableArray *elementInserted = [NSMutableArray array];
    NSMutableArray *elementUpdated = [NSMutableArray array];
    NSMutableArray<ChangeSetIdPair<ElementPath *> *> *elementMoved = [NSMutableArray array];
    
    for (NSInteger sourceSectionIndex = 0; sourceSectionIndex < [contiguousSourceSections count]; sourceSectionIndex++) {
        for (NSInteger sourceElementIndex = 0; sourceElementIndex < [contiguousSourceSections[sourceSectionIndex] count]; sourceElementIndex++) {
            ElementPath *sourceElementPath = [[ElementPath alloc] initWithElement:sourceElementIndex section:sourceSectionIndex];
            id<Differentiable> sourceElement = contiguousSourceSections[sourceSectionIndex][sourceElementIndex];
            [flattenSourceIdentifiers addObject:[sourceElement differenceIdentifier]];
            [flattenSourceElementPaths addObject:sourceElementPath];
        }
    }
    
    NSMutableDictionary<NSNumber *,Occurrence *> *sourceOccurrencesTable = [NSMutableDictionary dictionary];
    for (NSInteger flattenSourceIndex = 0; flattenSourceIndex < [flattenSourceIdentifiers count]; flattenSourceIndex++) {
        id key = flattenSourceIdentifiers[flattenSourceIndex];
        Occurrence *occurrence = sourceOccurrencesTable[key];
        
        if (occurrence) {
            switch (occurrence.type) {
                case OccurrenceTypeUnique:{
                    NSInteger otherIndex = occurrence.index;
                    IndicesReference *reference = [[IndicesReference alloc] initWithIndices:@[@(otherIndex), @(flattenSourceIndex)]];
                    sourceOccurrencesTable[key] = [[Occurrence alloc] initWithReference:reference];
                    break;
                }
                case OccurrenceTypeDuplicate: {
                    IndicesReference *reference = occurrence.reference;
                    [reference push:flattenSourceIndex];
                    break;
                }
                default:
                    break;
            }
        } else {
            sourceOccurrencesTable[key] = [[Occurrence alloc] initWithIndex:flattenSourceIndex];
        }
    }
    for (NSInteger targetSectionIndex = 0; targetSectionIndex < [contiguousTargetSections count]; targetSectionIndex++) {
        NSArray<Differentiable> *targetElements = contiguousTargetSections[targetSectionIndex];
        
        for (NSInteger targetElementIndex = 0; targetElementIndex < [targetElements count]; targetElementIndex++) {
            id key = [targetElements[targetElementIndex] differenceIdentifier];
            Occurrence *occurrence = sourceOccurrencesTable[key];
            
            if (occurrence) {
                switch (occurrence.type) {
                    case OccurrenceTypeUnique:{
                        NSInteger flattenSourceIndex = occurrence.index;
                        ElementPath *sourceElementPath = flattenSourceElementPaths[flattenSourceIndex];
                        ElementPath *targetElementPath = [[ElementPath alloc] initWithElement:targetElementIndex section:targetSectionIndex];
                        
                        if (sourceElementTraces[sourceElementPath.section][sourceElementPath.element].reference == nil) {
                            targetElementReferences[targetElementPath.section][targetElementPath.element] = sourceElementPath;
                            sourceElementTraces[sourceElementPath.section][sourceElementPath.element].reference = targetElementPath;
                        }
                        break;
                    }
                    case OccurrenceTypeDuplicate: {
                        IndicesReference *reference = occurrence.reference;
                        NSInteger flattenSourceIndex = [reference next];
                        if (flattenSourceIndex != NSNotFound) {
                            ElementPath *sourceElementPath = flattenSourceElementPaths[flattenSourceIndex];
                            ElementPath *targetElementPath = [[ElementPath alloc] initWithElement:targetElementIndex section:targetSectionIndex];
                            targetElementReferences[targetSectionIndex][targetElementIndex] = sourceElementPath;
                            sourceElementTraces[sourceElementPath.section][sourceElementPath.element].reference = targetElementPath;
                        }
                        break;
                    }
                    default:
                        break;
                }
            }
        }
    }
    
    for (NSInteger sourceSectionIndex = 0; sourceSectionIndex < [contiguousSourceSections count]; sourceSectionIndex++) {
        id<DifferentiableSection> sourceSection = source[sourceSectionIndex];
        NSArray *sourceElements = contiguousSourceSections[sourceSectionIndex];
        NSMutableArray *firstStageElements = [sourceElements mutableCopy];
        if (sectionResult.sourceTraces[sourceSectionIndex].reference != nil) {
            NSInteger offsetByDelete = 0;
            NSMutableArray *secondStageElements = [NSMutableArray array];
            
            for (NSInteger sourceElementIndex = 0; sourceElementIndex < [sourceElements count]; sourceElementIndex++) {
                ElementPath *sourceElementPath = [[ElementPath alloc] initWithElement:sourceElementIndex section:sourceSectionIndex];
                
                sourceElementTraces[sourceElementPath.section][sourceElementPath.element].deleteOffset = offsetByDelete;
                
                ElementPath *targetElementPath = sourceElementTraces[sourceElementPath.section][sourceElementPath.element].reference;
                if (targetElementPath && [sectionResult.targetReferences[targetElementPath.section] isKindOfClass:[NSNumber class]]) {
                    id<Differentiable> targetElement = contiguousTargetSections[targetElementPath.section][targetElementPath.element];
                    firstStageElements[sourceElementIndex] = targetElement;
                    [secondStageElements addObject:targetElement];
                    continue;;
                }
                
                [elementDeleted addObject:sourceElementPath];
                sourceElementTraces[sourceElementPath.section][sourceElementPath.element].isTracked = YES;
                offsetByDelete++;
            }
            
            id<DifferentiableSection> secondStageSection = [[[source.firstObject class] alloc] initWithSource: sourceSection elements: secondStageElements];
            [secondStageSections addObject:secondStageSection];
        }
        
        id<DifferentiableSection> firstStageSection = [[[source.firstObject class] alloc] initWithSource: sourceSection elements: firstStageElements];
        firstStageSections[sourceSectionIndex] = firstStageSection;
    }
    
    for (NSInteger targetSectionIndex = 0; targetSectionIndex < [contiguousTargetSections count]; targetSectionIndex++) {
        NSNumber *sourceSectionIndexNum = sectionResult.targetReferences[targetSectionIndex];
        if (![sourceSectionIndexNum isKindOfClass:[NSNumber class]]) {
            [thirdStageSections addObject:target[targetSectionIndex]];
            [fourthStageSections addObject:target[targetSectionIndex]];
            continue;;
        }
        NSInteger sourceSectionIndex = [sourceSectionIndexNum integerValue];
        
        NSNumber *untrackedSourceIndexNum = @(0);
        NSArray<Differentiable> *targetElements = contiguousTargetSections[targetSectionIndex];
        
        NSInteger sectionDeleteOffset = sectionResult.sourceTraces[sourceSectionIndex].deleteOffset;
        
        id<DifferentiableSection> thirdStageSection = secondStageSections[sourceSectionIndex - sectionDeleteOffset];
        [thirdStageSections addObject:thirdStageSection];
        
        NSMutableArray<Differentiable> *fourthStageElements = [NSMutableArray<Differentiable> array];
        
        for (NSInteger targetElementIndex = 0; targetElementIndex < [targetElements count]; targetElementIndex++) {
            if (untrackedSourceIndexNum != nil) {
                NSInteger untrackedSourceIndex = [untrackedSourceIndexNum integerValue];
                for (NSInteger traceIndex = untrackedSourceIndex; traceIndex < [sourceElementTraces[sourceSectionIndex] count]; traceIndex++) {
                    Trace *trace = sourceElementTraces[sourceSectionIndex][traceIndex];
                    if (![trace isTracked]) {
                        untrackedSourceIndexNum = @(traceIndex);
                        break;
                    }
                }
            }
            
            ElementPath *targetElementPath = [[ElementPath alloc] initWithElement:targetElementIndex section:targetSectionIndex];
            id<Differentiable> targetElement = contiguousTargetSections[targetSectionIndex][targetElementIndex];
            
            ElementPath *sourceElementPath = targetElementReferences[targetElementPath.section][targetElementPath.element];
            NSNumber *movedSourceSectionIndex = nil;
            if ([sourceElementPath isKindOfClass:[ElementPath class]]) {
                movedSourceSectionIndex = sectionResult.sourceTraces[sourceElementPath.section].reference;
            }
            if (![sourceElementPath isKindOfClass:[ElementPath class]] || !movedSourceSectionIndex) {
                [fourthStageElements addObject:targetElement];
                [elementInserted addObject:targetElementPath];
                continue;;
            }
            
            sourceElementTraces[sourceElementPath.section][sourceElementPath.element].isTracked = YES;
            
            id<Differentiable> sourceElement = contiguousSourceSections[sourceElementPath.section][sourceElementPath.element];
            [fourthStageElements addObject:targetElement];
            
            if (![targetElement isContentEqualTo:sourceElement]) {
                [elementUpdated addObject:sourceElementPath];
            }
            
            if (sourceElementPath.section != sourceSectionIndex || ![@(sourceElementPath.element) isEqual:untrackedSourceIndexNum]) {
                NSInteger deleteOffset = sourceElementTraces[sourceElementPath.section][sourceElementPath.element].deleteOffset;
                ElementPath *moveSourceElementPath = [[ElementPath alloc] initWithElement:sourceElementPath.element - deleteOffset section:[movedSourceSectionIndex integerValue]];
                ChangeSetIdPair<ElementPath *> *changeset = [[ChangeSetIdPair alloc] init];
                changeset.source = moveSourceElementPath;
                changeset.target = targetElementPath;
                [elementMoved addObject:changeset];
            }
        }
        
        id<DifferentiableSection> fourthStageSection = [[[source.firstObject class] alloc] initWithSource: thirdStageSection elements: fourthStageElements];
        [fourthStageSections addObject:fourthStageSection];
    }
    
    NSMutableArray<ChangeSet *> *changesets = [NSMutableArray array];
    
    if (elementUpdated.count > 0) {
        ChangeSet *set = [[ChangeSet alloc] initWithData:firstStageSections];
        set.elementUpdated = elementUpdated;
        [changesets addObject:set];
    }
    if (sectionResult.deleted.count > 0 || elementDeleted.count > 0) {
        ChangeSet *set = [[ChangeSet alloc] initWithData:secondStageSections];
        set.sectionDeleted = sectionResult.deleted;
        set.elementDeleted = elementDeleted;
        [changesets addObject:set];
    }
    if (sectionResult.inserted.count > 0 || sectionResult.moved.count > 0) {
        ChangeSet *set = [[ChangeSet alloc] initWithData:thirdStageSections];
        set.sectionInserted = sectionResult.inserted;
        set.sectionMoved = map(sectionResult.moved, ^id(ChangeSetIdPair<NSNumber *> *set, NSUInteger index) {
            ChangeSetIndexPair *pair = [[ChangeSetIndexPair alloc] init];
            pair.source = [set.source integerValue];
            pair.target = [set.target integerValue];
            return pair;
        });
        [changesets addObject:set];
    }
    if (elementInserted.count > 0 || elementMoved.count > 0) {
        ChangeSet *set = [[ChangeSet alloc] initWithData:fourthStageSections];
        set.elementInserted = elementInserted;
        set.elementMoved = elementMoved;
        [changesets addObject:set];
    }
    if (sectionResult.updated.count > 0) {
        ChangeSet *set = [[ChangeSet alloc] initWithData:target];
        set.sectionUpdated = sectionResult.updated;
        [changesets addObject:set];
    }
    if (changesets.count > 0) {
        changesets[changesets.count - 1].data = target;
    }
    return [self initWithChangesets:changesets];
}

@end

DiffResult* diff(NSArray<Differentiable> *source,
                 NSArray<Differentiable> *target,
                 BOOL useTargetIndexForUpdated,
                 IndexMapAction mapIndex,
                 NSMutableArray* __nullable updatedElements,
                 NSMutableArray* __nullable notDeletedElements) {
    NSMutableArray *deleted = [NSMutableArray array];
    NSMutableArray *inserted = [NSMutableArray array];
    NSMutableArray *updated = [NSMutableArray array];
    NSMutableArray<ChangeSetIdPair *> *moved = [NSMutableArray array];
    
    NSMutableArray<Trace<NSNumber *> *> *sourceTraces = [NSMutableArray array];
    NSMutableArray *sourceIdentifiers = [NSMutableArray array];
    NSMutableArray *targetReferences = [[NSMutableArray alloc] initWithCapacity:target.count];
    for (NSInteger i = 0; i < [target count]; i++) {
        [targetReferences addObject:[NSObject new]];
    }
    
    for (id<Differentiable> sourceElement in source) {
        [sourceTraces addObject:[[Trace alloc] init]];
        [sourceIdentifiers addObject:[sourceElement differenceIdentifier]];
    }
    
    NSMutableDictionary<NSNumber *, Occurrence *> *sourceOccurrencesTable = [[NSMutableDictionary alloc] initWithCapacity:source.count];
    for (NSInteger sourceIndex = 0; sourceIndex < [sourceIdentifiers count]; sourceIndex++) {
        id sourceIdentifier = sourceIdentifiers[sourceIndex];
        NSNumber *key = @((uintptr_t)sourceIdentifier);
        Occurrence *occurrence = sourceOccurrencesTable[key];
        if (occurrence) {
            switch (occurrence.type) {
                case OccurrenceTypeUnique: {
                    NSInteger otherIndex = occurrence.index;
                    IndicesReference *reference = [[IndicesReference alloc] initWithIndices:@[@(otherIndex), @(sourceIndex)]];
                    sourceOccurrencesTable[key] = [[Occurrence alloc] initWithReference:reference];
                    break;
                }
                case OccurrenceTypeDuplicate: {
                    IndicesReference *reference = occurrence.reference;
                    [reference push: sourceIndex];
                    break;
                }
            }
        } else {
            sourceOccurrencesTable[key] = [[Occurrence alloc] initWithIndex:sourceIndex];
        }
    }
    
    for (NSInteger targetIndex = 0; targetIndex < [target count]; targetIndex++) {
        id targetIdentifier = [target[targetIndex] differenceIdentifier];
        NSNumber *key = @((uintptr_t)targetIdentifier);
        Occurrence *occurrence = sourceOccurrencesTable[key];
        if (occurrence) {
            switch (occurrence.type) {
                case OccurrenceTypeUnique: {
                    NSInteger sourceIndex = occurrence.index;
                    id reference = [sourceTraces[sourceIndex] reference];
                    if (reference == nil) {
                        targetReferences[targetIndex] = @(sourceIndex);
                        sourceTraces[sourceIndex].reference = @(targetIndex);
                    }
                    break;
                }
                case OccurrenceTypeDuplicate: {
                    IndicesReference *reference = occurrence.reference;
                    NSInteger sourceIndex = [reference next];
                    if (sourceIndex != NSNotFound) {
                        targetReferences[targetIndex] = @(sourceIndex);
                        sourceTraces[sourceIndex].reference = @(targetIndex);
                    }
                    break;
                }
            }
        }
    }
    
    NSInteger offsetByDelete = 0;
    NSNumber* __nullable untrackedSourceIndex = @(0);
    
    for (NSInteger sourceIndex = 0; sourceIndex < [source count]; sourceIndex++ ) {
        sourceTraces[sourceIndex].deleteOffset = offsetByDelete;
        
        NSNumber *targetNumber = sourceTraces[sourceIndex].reference;
        if (targetNumber) {
            NSInteger targetIndex = [targetNumber integerValue];
            id targetElement = target[targetIndex];
            [updatedElements addObject:targetElement];
            [notDeletedElements addObject:targetElement];
        } else {
            id sourceElement = source[sourceIndex];
            [deleted addObject:mapIndex(sourceIndex)];
            sourceTraces[sourceIndex].isTracked = YES;
            offsetByDelete += 1;
            [updatedElements addObject:sourceElement];
        }
    }
    
    for (NSInteger targetIndex = 0; targetIndex < [target count]; targetIndex++ ) {
        if (untrackedSourceIndex != nil) {
            NSInteger untrackedSourceIndexValue = [untrackedSourceIndex integerValue];
            untrackedSourceIndex = nil;
            for (NSInteger traceIndex = untrackedSourceIndexValue; traceIndex < [sourceTraces count]; traceIndex++) {
                Trace *trace = sourceTraces[traceIndex];
                if (![trace isTracked]) {
                    untrackedSourceIndex = @(traceIndex);
                    break;
                }
            }
        }
        
        NSNumber *sourceIndexNum = targetReferences[targetIndex];
        if ([sourceIndexNum isKindOfClass:[NSNumber class]]) {
            NSInteger sourceIndex = [sourceIndexNum integerValue];
            sourceTraces[sourceIndex].isTracked = YES;
            
            id<Differentiable> sourceElement = source[sourceIndex];
            id<Differentiable> targetElement = target[targetIndex];
            
            if ([sourceElement respondsToSelector:@selector(isContentEqualTo:)]
                && ![targetElement isContentEqualTo:sourceElement]) {
                [updated addObject:mapIndex(useTargetIndexForUpdated ? targetIndex : sourceIndex)];
            }
            
            NSInteger untrackedSourceIndexValue = [untrackedSourceIndex integerValue];
            if (untrackedSourceIndex == nil || sourceIndex != untrackedSourceIndexValue) {
                NSInteger deleteOffset = sourceTraces[sourceIndex].deleteOffset;
                ChangeSetIdPair *pair = [[ChangeSetIdPair alloc] init];
                pair.source = mapIndex(sourceIndex - deleteOffset);
                pair.target = mapIndex(targetIndex);
                [moved addObject: pair];
            }
        } else {
            [inserted addObject:mapIndex(targetIndex)];
        }
    }
    
    DiffResult *result = [[DiffResult alloc] init];
    result.deleted = deleted;
    result.inserted = inserted;
    result.updated = updated;
    result.moved = moved;
    result.sourceTraces = sourceTraces;
    result.targetReferences = targetReferences;
    
    return result;
}

NSMutableArray* map_mutable(NSArray *origin, MapAction action) {
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:origin.count];
    for (NSUInteger i = 0; i < [origin count]; i++) {
        [result addObject:action(origin[i], i)];
    }
    return result;
}
NSArray* map(NSArray *origin, MapAction action) {
    return [map_mutable(origin, action) copy];
}
