//
//  UIKitExtension.h
//  DiffKit
//
//  Created by Star Zhu on 2022/10/17.
//

#import <Foundation/Foundation.h>
#import "ChangeSet.h"
#import "StagedChangeset.h"

NS_ASSUME_NONNULL_BEGIN

typedef UITableViewRowAnimation(^RowAnimatioin)(void);
typedef void(^DataAction) (id);

@interface UITableView (Diff)

- (void)reloadUsing:(StagedChangeset *)stagedChangeset
      withAnimation:(RowAnimatioin)animation
            setData:(DataAction)setData;

@end

@interface UICollectionView (Diff)

- (void)reloadUsing:(StagedChangeset *)stagedChangeset
            setData:(DataAction) setData;

@end

NS_ASSUME_NONNULL_END
