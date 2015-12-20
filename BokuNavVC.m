//
//  BokuNavVC.m
//  Boku
//
//  Created by Ghanshyam on 8/14/15.
//  Copyright (c) 2015 Plural Voice. All rights reserved.
//

#import "BokuNavVC.h"


@interface BokuNavVC ()

@end


@implementation BokuNavVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapNavigationAction:)];
    [self.navigationBar addGestureRecognizer:tapGesture];
    
    NSLog(@"BokuNavVC loaded");
}

-(void)dealloc{
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    if (self.topViewController != nil)
        return [self.topViewController shouldAutorotate];
    else
        return [super shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations {
    if (self.topViewController != nil)
        return [self.topViewController supportedInterfaceOrientations];
    else
        return [super supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if (self.topViewController != nil)
        return [self.topViewController preferredInterfaceOrientationForPresentation];
    else
        return [super preferredInterfaceOrientationForPresentation];
}


// Hijack the push method to disable the gesture


- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([[Contacts sharedInstance] isContactsContainerVerified] && ![[Contacts sharedInstance] isProcessing]) {
        
        //getting weak refrence of Contact container
        NSMutableArray *arrPersons;
        
        [[Contacts sharedInstance] sharedContactsWeakReference:&arrPersons];
        //@synchronized(arrPersons) {
            //Lock to shared Person container
            
            if (arrPersons.count>0) {
                
                [arrPersons makeObjectsPerformSelector:NSSelectorFromString(@"removeReferenceObjectFromMemory")];
            }
            
        //}
        
    }
    
    NSLog(@"disabling gesture");
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)])
        self.interactivePopGestureRecognizer.enabled = NO;
    
    [super pushViewController:viewController animated:animated];
}


-(UIViewController *)childViewControllerForStatusBarHidden{
    return self.visibleViewController;
}

-(UIViewController *)childViewControllerForStatusBarStyle{
    return self.visibleViewController;
}


#pragma mark -
#pragma mark C methods
-(void)tapNavigationAction:(UITapGestureRecognizer *)tapGesture{
    NSLog(@"tap navigation action");
    [self.view endEditing:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NAVIGATION_BAR_TAP_NOTIFICATION object:nil];
}




@end
