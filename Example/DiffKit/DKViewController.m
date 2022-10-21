//
//  DKViewController.m
//  DiffKit
//
//  Created by StarFelix on 10/16/2022.
//  Copyright (c) 2022 StarFelix. All rights reserved.
//

#import "DKViewController.h"
#import <DiffKit/Algorithm.h>
#import <DiffKit/Differentiable.h>
#import <DiffKit/UIKitExtension.h>
#import <DiffKit/DifferentiableSection.h>
#import <DiffKit/ArraySection.h>

@interface NSNumber (Diff) <Differentiable>

@end

@interface DKViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<ArraySection *> *datas;

@end

@implementation DKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    self.tableView = tableView;
    [self.view addSubview:tableView];
    self.datas = @[[[ArraySection alloc] initWithModel:@(0) elements:@[@(100),@(200),@(300)]],
                    [[ArraySection alloc] initWithModel:@(1) elements:@[@(400),@(500),@(600)]],
                    [[ArraySection alloc] initWithModel:@(2) elements:@[@(700),@(800),@(900)]]
                   ];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 500, 40, 40)];
    button.backgroundColor = [UIColor redColor];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(onChange:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray* a = @[@(199),@(200)];
    NSArray* b = @[@(200)];
    StagedChangeset *set = [[StagedChangeset alloc] initWithSource:a target:b section:0];
    NSLog(@"%@",set);
}

- (void)onChange:(id)target {
    NSArray<ArraySection *> *datas = @[
                        [[ArraySection alloc] initWithModel:@(0) elements:@[@(300),@(200),@(400)]],
                       [[ArraySection alloc] initWithModel:@(3) elements:@[@(100),@(401),@(600)]],
                       [[ArraySection alloc] initWithModel:@(1) elements:@[@(700),@(500),@(800)]]
                      ];
    
    StagedChangeset *set = [[StagedChangeset alloc] initWithSource:self.datas target:datas];
    [self.tableView reloadUsing:set
                  withAnimation:^UITableViewRowAnimation{
        return UITableViewRowAnimationFade;
    } setData:^(id data) {
        self.datas = data;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.datas count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.datas[section].elements count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.datas[section].model.differenceIdentifier stringValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"abc"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"abc"];
        cell.textLabel.text = [(NSNumber *)self.datas[indexPath.section].elements[indexPath.row] stringValue];
    }
    return cell;
}

@end

@implementation NSNumber (Diff)

- (id)differenceIdentifier {
    return self;
}

- (BOOL)isContentEqualTo:(NSNumber *)source {
    if (![source isKindOfClass:[NSNumber class]]) {
        return NO;
    }
    return [self isEqual:source];
}

@end
