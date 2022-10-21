//
//  ContentIdentifiable.h
//  DiffKit
//
//  Created by Star Zhu on 2022/10/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ContentIdentifiable <NSObject>

- (id)differenceIdentifier;

@end

NS_ASSUME_NONNULL_END
