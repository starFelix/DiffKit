//
//  ContentEquatable.h
//  DiffKit
//
//  Created by Star Zhu on 2022/10/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ContentEquatable <NSObject>

- (BOOL)isContentEqualTo:(id)source;

@end

NS_ASSUME_NONNULL_END
