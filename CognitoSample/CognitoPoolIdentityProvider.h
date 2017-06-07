//
//  CognitoPoolIdentityProvider.h
//  CognitoSample
//
//  Created by Jeff Leininger on 5/27/17.
//  Copyright © 2017 Jeff Leininger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSCore/AWSCore.h>


@interface CognitoPoolIdentityProvider : NSObject <AWSIdentityProviderManager>
    @property (strong, nonatomic) NSDictionary *tokens;

    - (AWSTask<NSDictionary *> *)logins;
    - (void)addTokens:(NSDictionary *)tokens;

@end
