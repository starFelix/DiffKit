//
//  UIKitExtension.m
//  DiffKit
//
//  Created by Star Zhu on 2022/10/17.
//

#import "UIKitExtension.h"

@implementation UITableView (Diff)

- (void)reloadUsing:(StagedChangeset *)stagedChangeset
      withAnimation:(RowAnimatioin)animation
            setData:(DataAction) setData {
    NSArray<ChangeSet *> *changeSets = stagedChangeset.changesets;
    if (self.window == nil && [changeSets lastObject].data != nil) {
        id data = [changeSets lastObject].data;
        setData(data);
        [self reloadData];
        return;
    }
    
    for (ChangeSet *changeset in changeSets) {
        [self _performBatchUpdates:^{
            setData(changeset.data);
            
            if (changeset.sectionDeleted.count > 0) {
                NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
                for (NSNumber *index in changeset.sectionDeleted) {
                    [set addIndex:[index integerValue]];
                }
                [self deleteSections:set withRowAnimation:animation()];
            }
            if (changeset.sectionInserted.count > 0) {
                NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
                for (NSNumber *index in changeset.sectionInserted) {
                    [set addIndex:[index integerValue]];
                }
                [self insertSections:set withRowAnimation:animation()];
            }
            if (changeset.sectionUpdated.count > 0) {
                NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
                for (NSNumber *index in changeset.sectionUpdated) {
                    [set addIndex:[index integerValue]];
                }
                [self reloadSections:set withRowAnimation:animation()];
            }
            
            for (ChangeSetIndexPair *pair in  changeset.sectionMoved) {
                [self moveSection:pair.source toSection:pair.target];
            }
            
            if (changeset.elementDeleted.count > 0) {
                NSMutableArray<NSIndexPath *> *indexPathes = [[NSMutableArray alloc] init];
                for (ElementPath *path in changeset.elementDeleted) {
                    [indexPathes addObject:[NSIndexPath indexPathForRow:path.element inSection:path.section]];
                }
                [self deleteRowsAtIndexPaths:indexPathes withRowAnimation:animation()];
            }
            if (changeset.elementInserted.count > 0) {
                NSMutableArray<NSIndexPath *> *indexPathes = [[NSMutableArray alloc] init];
                for (ElementPath *path in changeset.elementInserted) {
                    [indexPathes addObject:[NSIndexPath indexPathForRow:path.element inSection:path.section]];
                }
                [self insertRowsAtIndexPaths:indexPathes withRowAnimation:animation()];
            }
            if (changeset.elementUpdated.count > 0) {
                NSMutableArray<NSIndexPath *> *indexPathes = [[NSMutableArray alloc] init];
                for (ElementPath *path in changeset.elementUpdated) {
                    [indexPathes addObject:[NSIndexPath indexPathForRow:path.element inSection:path.section]];
                }
                [self reloadRowsAtIndexPaths:indexPathes withRowAnimation:animation()];
            }
            for (ChangeSetIdPair<ElementPath *> *pair in changeset.elementMoved) {
                [self moveRowAtIndexPath:[NSIndexPath indexPathForRow:pair.source.element inSection:pair.source.section]
                             toIndexPath:[NSIndexPath indexPathForRow:pair.target.element inSection:pair.target.section]];
            }
        }];
    }
}

- (void)_performBatchUpdates:(void (NS_NOESCAPE ^ _Nullable)(void))updates {
    if (@available(iOS 11.0, tvOS 11.0, *)) {
        [self performBatchUpdates:updates completion:nil];
    }
    else {
        [self beginUpdates];
        if (updates) {
            updates();
        }
        [self endUpdates];
    }
}

@end


@implementation UICollectionView (Diff)

- (void)reloadUsing:(StagedChangeset *)stagedChangeset
            setData:(DataAction) setData {
    NSArray<ChangeSet *> *changeSets = stagedChangeset.changesets;
    if (self.window == nil && [changeSets lastObject].data != nil) {
        id data = [changeSets lastObject].data;
        setData(data);
        [self reloadData];
        return;
    }
    
    for (ChangeSet *changeset in changeSets) {
        [self performBatchUpdates:^{
            setData(changeset.data);
            
            if (changeset.sectionDeleted.count > 0) {
                NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
                for (NSNumber *index in changeset.sectionDeleted) {
                    [set addIndex:[index integerValue]];
                }
                [self deleteSections:set];
            }
            if (changeset.sectionInserted.count > 0) {
                NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
                for (NSNumber *index in changeset.sectionInserted) {
                    [set addIndex:[index integerValue]];
                }
                [self insertSections:set];
            }
            if (changeset.sectionUpdated.count > 0) {
                NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
                for (NSNumber *index in changeset.sectionUpdated) {
                    [set addIndex:[index integerValue]];
                }
                [self reloadSections:set];
            }
            
            for (ChangeSetIndexPair *pair in  changeset.sectionMoved) {
                [self moveSection:pair.source toSection:pair.target];
            }
            
            if (changeset.elementDeleted.count > 0) {
                NSMutableArray<NSIndexPath *> *indexPathes = [[NSMutableArray alloc] init];
                for (ElementPath *path in changeset.elementDeleted) {
                    [indexPathes addObject:[NSIndexPath indexPathForItem:path.element inSection:path.section]];
                }
                [self deleteItemsAtIndexPaths:indexPathes];
            }
            if (changeset.elementInserted.count > 0) {
                NSMutableArray<NSIndexPath *> *indexPathes = [[NSMutableArray alloc] init];
                for (ElementPath *path in changeset.elementInserted) {
                    [indexPathes addObject:[NSIndexPath indexPathForItem:path.element inSection:path.section]];
                }
                [self insertItemsAtIndexPaths:indexPathes];
            }
            if (changeset.elementUpdated.count > 0) {
                NSMutableArray<NSIndexPath *> *indexPathes = [[NSMutableArray alloc] init];
                for (ElementPath *path in changeset.elementUpdated) {
                    [indexPathes addObject:[NSIndexPath indexPathForItem:path.element inSection:path.section]];
                }
                [self reloadItemsAtIndexPaths:indexPathes];
            }
            for (ChangeSetIdPair<ElementPath *> *pair in changeset.elementMoved) {
                [self moveItemAtIndexPath:[NSIndexPath indexPathForItem:pair.source.element inSection:pair.source.section]
                              toIndexPath:[NSIndexPath indexPathForItem:pair.target.element inSection:pair.target.section]];
            }
        } completion: nil];
    }
}

@end
