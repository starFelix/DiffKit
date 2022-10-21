//
//  ElementPath.h
//  DiffKit
//
//  Created by Star Zhu on 2022/10/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ElementPath : NSObject

@property (nonatomic, assign) NSInteger element;
@property (nonatomic, assign) NSInteger section;

- (instancetype)initWithElement:(NSInteger)element section:(NSInteger)section;

@end

NS_ASSUME_NONNULL_END
