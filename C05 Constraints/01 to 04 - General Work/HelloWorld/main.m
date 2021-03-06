/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 6.x Edition
 BSD License, Use at your own risk
 */

#import <UIKit/UIKit.h>
#import "UIView-BasicConstraints.h"
#import "Utility.h"

@interface TestBedViewController : UIViewController
@end

@implementation TestBedViewController
- (UILabel *) createLabel: (NSString *) aTitle
{
    UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    aLabel.font = [UIFont fontWithName:@"Futura" size:24.0f];
    aLabel.textAlignment = NSTextAlignmentCenter;
    aLabel.textColor = [UIColor darkGrayColor];
    aLabel.text = aTitle;

    [aLabel constrainSize:CGSizeMake(100.0f, 100.0f)];

    return aLabel;
}

- (void) viewDidAppear:(BOOL)animated
{
    // 查看子視圖的位置
    /*
    for (UIView *subview in self.view.subviews)
        NSLog(@"View #%d (%@): location: %@", [self.view.subviews indexOfObject:subview], subview.debugName, NSStringFromCGRect(subview.frame));
     */
}

- (void) action: (id) sender
{
    // 說來遺憾，我們不能讓約束規則的變化產生動畫效果
    /* UIView *view1 = self.view.subviews[0];
    
    [UIView animateWithDuration:1.0f animations:^(){
        [view1 removeVisualFormat: @"V:|[self]"];
        [view1 addVisualFormat: @"V:[self]|"];
    }];*/
}

enum {foo, bar, blort};

- (void) loadView
{
    [super loadView];
    self.view.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.85f];
	self.navigationItem.rightBarButtonItem = BARBUTTON(@"Action", @selector(action:));
    
    // 建立視圖
    
    UILabel *view1 = [self createLabel:@"View 1"];
    view1.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.25f];
    UILabel *view2 = [self createLabel:@"View 2"];
    view2.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.25f];
    UILabel *view3 = [self createLabel:@"View 3"];
    view3.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.25f];
    UILabel *view4 = [self createLabel:@"View 4"];
    view4.backgroundColor = [[UIColor yellowColor] colorWithAlphaComponent:0.25f];
    
    // 隱藏非使用中的視圖
    // view1.alpha = 0.0f;
    // view2.alpha = 0.0f;
    // view3.alpha = 0.0f;
    view4.alpha = 0.0f;
    
    // 加入視圖到畫面裡
    [self.view addSubviewAndConstrainToBounds:view1];
    [self.view addSubviewAndConstrainToBounds:view2];
    [self.view addSubviewAndConstrainToBounds:view3];
    [self.view addSubviewAndConstrainToBounds:view4];
    
    // 垂直對齊
    /* for (UIView *subview in self.view.subviews)
        [subview setAlignmentInSuperview:NSLayoutFormatAlignAllTop]; */
    
    // 加入你自己的規則，看看產生出來的約束規則
    // [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[view1]-[view2]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(view1, view2)]];
    ALIGN_VIEW_LEFT(self.view, view1);
    ALIGN_VIEW_TOP(self.view, view1);
    CONSTRAIN_ORDER_H(self.view, view1, view2);
    CONSTRAIN_ORDER_V(self.view, view1, view2);
    CONSTRAIN_ORDER_H(self.view, view2, view3);
    [self.view showConstraints];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}
@end

#pragma mark -

#pragma mark Application Setup
@interface TestBedAppDelegate : NSObject <UIApplicationDelegate>
{
	UIWindow *window;
}
@end
@implementation TestBedAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{	
    // [application setStatusBarHidden:YES];
    [[UINavigationBar appearance] setTintColor:COOKBOOK_PURPLE_COLOR];
    
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	TestBedViewController *tbvc = [[TestBedViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:tbvc];
    window.rootViewController = nav;
	[window makeKeyAndVisible];
    return YES;
}
@end
int main(int argc, char *argv[]) {
    @autoreleasepool {
        int retVal = UIApplicationMain(argc, argv, nil, @"TestBedAppDelegate");
        return retVal;
    }
}