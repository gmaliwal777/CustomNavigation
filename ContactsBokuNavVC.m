//
//  ContactsBokuNavVC.m
//  
//
//  Created by Ghanshyam on 10/14/15.
//
//

#import "ContactsBokuNavVC.h"
#import "WSVerifyContacts.h"

@interface ContactsBokuNavVC ()

@end

@implementation ContactsBokuNavVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapNavigationAction:)];
    [self.navigationBar addGestureRecognizer:tapGesture];
    
    NSLog(@"BokuNavVC loaded");
    
}

-(void)dealloc{
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //UIViewController *topViewController = ;
    NSLog(@"contacts boku nav vc view will appear");
    if (dispatchCodeOnce) {
        
        //Used to verify remaining contacts if any
        [CommonFunctions verifyRemainingContactsIfAny];
        
        //This if clause will not call first time view will appear of this current context . next other time its called.
        
        
        //we set required block to Address Book Handler , so we can get  Address Book changes here.
        dispatch_queue_t myQueue = dispatch_queue_create("CONTACT_ADDRESS_FETCH", NULL);
        dispatch_async(myQueue, ^{
            [[Contacts sharedInstance] setAdderssBookHandler:^{
                BokuContactsReadyHandler(self);
            }];
        });
        
        
        //we set required block which can be called on Contact list refresh .
        dispatch_queue_t refreshQueue = dispatch_queue_create("CONTACT_refreshQueue_ADDRESS_FETCH", NULL);
        dispatch_async(refreshQueue, ^{
            [[Contacts sharedInstance] setContactListRefreshHandler:^{
                ContactsRefreshHandler(self);
            }];
        });
        
        
        if (![Contacts sharedInstance].isContactsContainerVerified &&
            ![Contacts sharedInstance].isProcessing) {
            //We came from another context here and we check we have any contacts in contacts container which is not verified yet . so we again calll verify contacts here.
            [self verifyContacts];
        }else{
            [APPDELEGATE.multiCastDelegate ContactsReadyToUse];
        }
    }
    
    dispatch_once(&dispatchCodeOnce, ^{
        //NSLog(@"verified");
        dispatch_queue_t myQueue = dispatch_queue_create("CONTACT_ADDRESS_FETCH", NULL);
        dispatch_async(myQueue, ^{
            
            NSLog(@"calling in view will appear");
            //Used to connect with xmpp server
            [self makeXMPPConnected];
            
            if ([[Contacts sharedInstance] isProcessing]) {
                NSLog(@"processing");
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [APPDELEGATE.loader show];
                    NSLog(@"loader show in contacts nav processing once dispatch");
                });
                
                [[Contacts sharedInstance] setAdderssBookHandler:^{
                    BokuContactsReadyHandler(self);
                }];
                
                
            }else{
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    BokuContactsReadyHandler(self);
                    
                });
                
            }
        });
    });
    
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
    
    //getting weak refrence of Contact container
    NSMutableArray *arrPersons;
    [[Contacts sharedInstance] sharedContactsWeakReference:&arrPersons];
    
    //@synchronized(arrPersons) {
        //Lock to shared Person container
        
        if (arrPersons.count>0) {
            [arrPersons makeObjectsPerformSelector:NSSelectorFromString(@"removeReferenceObjectFromMemory")];
        }
    //}
    
    
    
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

#pragma mark - Class Methods
-(void)makeXMPPConnected{
    //Increasing loader count for xmpp connecting
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [APPDELEGATE.loader show];
        NSLog(@"loader show in contacts nav makeXMPPConnected");
    });
    
    
    [APPDELEGATE.xmppDelegate setSpecificHandler:InitialRosterDidEndPopulating handlerCode:InitialRosterPopulating];
    
    [APPDELEGATE.xmppDelegate setSpecificHandler:StreamingFailureHandler handlerCode:StreamingFailure];
    
    
    [APPDELEGATE.xmppDelegate connect];
}

/**
 *  Used to call verify local contacts with boku contacts
 */
-(void)verifyContacts{
    if ([CommonFunctions networkConnectionAvailability]) {
        
        self.verifyContactWS = [[WSVerifyContacts alloc] init];
        self.verifyContactWS.delegate = self;
        [_verifyContactWS callServiceWithSuccessBlock:VerifyContactsSuccessBlock withFailureBlock:VerifyContactFailureBlock];
        
    }else{
        
        //We make isContactsContainerVerified = YES , because service is not called
        [Contacts sharedInstance].isContactsContainerVerified = YES;
        
        [CommonFunctions showAlertViewWithoutAnyHandlerWithErrorMessage:NETWORK_ERROR_MESSAGE];
    }
}



#pragma mark - Blocks

void(^InitialRosterDidEndPopulating)() = ^{
    NSLog(@"InitialRosterDidEndPopulating");
    
    [APPDELEGATE.loader hide];
    NSLog(@"loader hide in contacts nav InitialRosterDidEndPopulating");
    
    //Subscribe request to all boku contacts
    //[[Contacts sharedInstance] makeSubscribeRequest];
    [[Contacts sharedInstance] userSynchronizationWithBlockStatus];
    
    
    [APPDELEGATE processOfflineMedias];
};

void(^StreamingFailureHandler)() = ^{
    NSLog(@"StreamingFailureHandler");
    [APPDELEGATE.loader hide];
    
    NSLog(@"loader hide in contacts nav StreamingFailureHandler");
    
};


void (^ContactsRefreshHandler)(ContactsBokuNavVC *navVC) = ^(ContactsBokuNavVC *navVC){
    
    NSLog(@"contact refreshing called");
    //[contactVC.tableViewContacts reloadData];
    
};

void(^BokuContactsReadyHandler)(ContactsBokuNavVC *navVC) = ^(ContactsBokuNavVC *navVC){
    //Having shared contacts weak reference
    NSLog(@"ready handler");
    
    [[Contacts sharedInstance] setContactListRefreshHandler:^{
        BokuContactsReadyHandler(navVC);
    }];
    
    //Assigning handler to Singleton Contacts class , so it can be used to decide when to start implementing logic basis on Contacts
    [[Contacts sharedInstance] setAdderssBookHandler:^{
        
        if (![Contacts sharedInstance].isContactsContainerVerified) {
            //we have address book change notification and verifying is still NO. so we call verifyContacts again to sync
            NSLog(@"calling verify contacts ");
            [navVC verifyContacts];
            
        }else{
            NSLog(@"reloading contacts");
            [APPDELEGATE.multiCastDelegate ContactsReadyToUse];
        }
    }];
    
    
    [APPDELEGATE.multiCastDelegate ContactsReadyToUse];
    
    //Calling verifying contacts service
    [navVC verifyContacts];
};



/**
 *  Block called on VerifyContacts Success
 *
 *  @param response     : response of service
 *  @param serviceClass : Service Class which is triggering block execution
 *  @param delegate     : delegate
 *
 *  @return : none
 */

void(^VerifyContactsSuccessBlock)(id response, Class serviceClass , id delegate) = ^(id response, Class serviceClass , id delegate){
    // NSLog(@"response is == %@",response);
    [APPDELEGATE.loader show];
    
    ContactsBokuNavVC *navVC = (ContactsBokuNavVC *)delegate;
    if(serviceClass == [WSVerifyContacts class]){
        if([response objectForKey:@"status_code"] &&
           [[response objectForKey:@"status_code"] intValue] ==200){
            
            //Subscribe request to all boku contacts
            //[[Contacts sharedInstance] makeSubscribeRequest];
            [[Contacts sharedInstance] userSynchronizationWithBlockStatus];
            
            [APPDELEGATE.multiCastDelegate ContactsVerified];
            
        }else{
            [CommonFunctions showAlertViewWithoutAnyHandlerWithErrorMessage:[[response objectForKey:@"data"] objectForKey:@"msg"]];
        }
        navVC.verifyContactWS = nil;
    }
    [APPDELEGATE.loader hide];
    
};


/**
 *  Block called on VerifyContacts Failure
 *
 *  @param response     : response of service
 *  @param serviceClass : Service Class which is triggering block execution
 *  @param delegate     : delegate
 *
 *  @return : none
 */
void(^VerifyContactFailureBlock)(id response, Class serviceClass , id delegate) = ^(id response, Class serviceClass , id delegate){
    //NSLog(@"response is == %@",response);
    ContactsBokuNavVC *navVC = (ContactsBokuNavVC *)delegate;
    if(serviceClass == [WSVerifyContacts class]){
        NSError *error = (NSError *)response;
        [CommonFunctions showAlertViewWithoutAnyHandlerWithErrorMessage:[error.userInfo objectForKey:NSLocalizedDescriptionKey]];
        navVC.verifyContactWS = nil;
    }
};


@end
