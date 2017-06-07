//
//  CognitoPoolIdentityProvider.m
//  CognitoSample
//
//  Created by Jeff Leininger on 5/27/17.
//  Copyright © 2017 Jeff Leininger. All rights reserved.
//

#import "CognitoPoolIdentityProvider.h"

@implementation CognitoPoolIdentityProvider

- (AWSTask<NSDictionary *> *)logins {
    return [AWSTask taskWithResult:self.tokens];
}

- (void)addTokens:(NSDictionary *)tokens {
    self.tokens = tokens;
}

@end
