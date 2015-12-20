//
//  ContactsBokuNavVC.h
//  
//
//  Created by Ghanshyam on 10/14/15.
//
//

#import <UIKit/UIKit.h>

@class WSVerifyContacts;

@interface ContactsBokuNavVC : UINavigationController{
    /**
     *  Dispatch identifier to execute specific code once in current context.
     */
    dispatch_once_t     dispatchCodeOnce;
}


/**
 *  Referencet to WSVerifyContacts http service , used to verify local contacts with boku contacts
 */
@property (nonatomic,strong)    WSVerifyContacts    *verifyContactWS;


@property (nonatomic, assign)   BOOL    isContactsHandlerNavigation;

/**
 *  Used to call verify local contacts with boku contacts
 */
-(void)verifyContacts;

@end
