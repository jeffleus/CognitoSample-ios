//
//  CognitoCordovaPlugin.h
//  CognitoSample
//
//  Created by Jeff Leininger on 5/31/17.
//  Copyright © 2017 Jeff Leininger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSCognitoIdentityProvider/AWSCognitoIdentityProvider.h>
#import <AWSCore/AWSCore.h>

@interface CognitoCordovaPlugin : NSObject
    - (void)initPlugin:(NSDictionary *)options;
    - (void)loginUser:(NSString *)username withPassword:(NSString *)password;
    - (void)refreshSession;
    - (void)logout;

@end
