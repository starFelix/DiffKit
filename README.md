# DiffKit

[![CI Status](https://img.shields.io/travis/StarFelix/DiffKit.svg?style=flat)](https://travis-ci.org/StarFelix/DiffKit)
[![Version](https://img.shields.io/cocoapods/v/DiffKit.svg?style=flat)](https://cocoapods.org/pods/DiffKit)
[![License](https://img.shields.io/cocoapods/l/DiffKit.svg?style=flat)](https://cocoapods.org/pods/DiffKit)
[![Platform](https://img.shields.io/cocoapods/p/DiffKit.svg?style=flat)](https://cocoapods.org/pods/DiffKit)

---

## Features

💡 Fastest **O(n)** diffing algorithm optimized for Objective-C collection

💡 Calculate diffs for batch updates of list UI in `UIKit` and [Texture](https://github.com/TextureGroup/Texture)

💡 Supports both linear and sectioned collection even if contains duplicates

💡 Supports **all kind of diffs** for animated UI batch updates

---
## Algorithm

The algorithm optimized based on the Paul Heckel's algorithm. 
See also his paper ["A technique for isolating differences between files"](https://dl.acm.org/citation.cfm?id=359467) released in 1978. 
It allows all kind of diffs to be calculated in linear time **O(n)**. 
[RxDataSources](https://github.com/RxSwiftCommunity/RxDataSources) and [IGListKit](https://github.com/Instagram/IGListKit) are also implemented based on his algorithm. 

However, in `performBatchUpdates` of `UITableView`, `UICollectionView`, etc, there are combinations of diffs that cause crash when applied simultaneously.  

To solve this problem, `DifferenceKit` takes an approach of split the set of diffs at the minimal stages that can be perform batch updates with no crashes.

This git is translated from [DifferenceKit](https://github.com/ra1028/DifferenceKit) which used for Swift.

---

## Basic Use

The type of the element that to take diffs must be conform to the `Differentiable` protocol.

And the `differenceIdentifier`'s type **must** be `Hashable`.

~~~objective-c
@interface User: NSObject <Differentiable>

@property (nonatomic, copy) NSString *userId;
@property (nonatomic, assign) NSUInteger age;

@end

@implementation User

- (id)differenceIdentifier {
    return self.userId;
}

- (BOOL)isContentEqualTo:(User *)source {
    if (![source isKindOfClass:[User class]]) {
        return NO;
    }
    return self.age == source.age;
}

@end
~~~

In the case of definition above, `userId` uniquely identifies the element and get to know the user updated by comparing equality of `age` of the elements in source and target.

Calculate the diffs by creating `StagedChangeset` from two collections of elements conforming to `Differentiable`:

```objective-c
NSArray<Differentiable> *a = @[
    [[User alloc] initWithId:@"00" age:10],
    [[User alloc] initWithId:@"01" age:11],
    [[User alloc] initWithId:@"02" age:12]
];
NSArray<Differentiable> *b = @[
    [[User alloc] initWithId:@"00" age:10],
    [[User alloc] initWithId:@"03" age:12]
];
StagedChangeset *set = [[StagedChangeset alloc] initWithSource:a target:b section:0];
```

> if your dataSources are all in one groups, you should prefer to use `initWithSource:target:section`.

If you want to compare groups in the collection, write code like below:

```objective-c
@interface NSString (Diff) <Differentiable>

@end

@implementation NSString(Diff)

- (id)differenceIdentifier {
    return self;
}

- (BOOL)isContentEqualTo:(id)source {
    if (![source isKindOfClass:[NSString class]]) {
        return NO;
    }
    return [self isEqual:source];
}

@end

void test() {
    NSArray<ArraySection *> *a = @[
        [[ArraySection alloc] initWithModel:@"groupA" elements:@[
            [[User alloc] initWithId:@"00" age:10],
            [[User alloc] initWithId:@"01" age:11],
            [[User alloc] initWithId:@"02" age:12]
        ]],
        [[ArraySection alloc] initWithModel:@"groupB" elements:@[
            [[User alloc] initWithId:@"10" age:10],
            [[User alloc] initWithId:@"11" age:11],
            [[User alloc] initWithId:@"12" age:12]
        ]]
    ];
    NSArray<ArraySection *> *b = @[
        [[ArraySection alloc] initWithModel:@"groupA" elements:@[
            [[User alloc] initWithId:@"00" age:10],
            [[User alloc] initWithId:@"13" age:16],
            [[User alloc] initWithId:@"12" age:12]
        ]],
        [[ArraySection alloc] initWithModel:@"groupB" elements:@[
            [[User alloc] initWithId:@"10" age:10],
            [[User alloc] initWithId:@"02" age:12]
        ]]
    ];
    StagedChangeset *set = [[StagedChangeset alloc] initWithSource:a target:b];
    return set;
}
```

You can perform diffing batch updates of `UITableView` and `UICollectionView` using the created `StagedChangeset`.  

⚠️ **Don't forget** to **synchronously** update the data referenced by the data-source, with the data passed in the `setData` closure. The diffs are applied in stages, and failing to do so is bound to create a crash:

```objective-c
[self.tableView reloadUsing:set
              withAnimation:^UITableViewRowAnimation{
    return UITableViewRowAnimationFade;
} setData:^(id data) {
    self.datas = data;
}];
```

Batch updates using too large amount of diffs may adversely affect to performance. If the diffs are too large, use `reloadData` instead.

## Requirements

- Objective-C
- iOS: 9+

## Installation

DiffKit is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'DiffKit', :git => 'https://github.com/starFelix/DiffKit'
```

---

## Contribution

Pull requests, bug reports and feature requests are welcome 🚀

---

## License

DiffKit is available under the MIT license. See the LICENSE file for more info.
