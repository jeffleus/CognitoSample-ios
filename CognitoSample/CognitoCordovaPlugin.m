//
//  CognitoCordovaPlugin.m
//  CognitoSample
//
//  Created by Jeff Leininger on 5/31/17.
//  Copyright © 2017 Jeff Leininger. All rights reserved.
//

#import "CognitoCordovaPlugin.h"
#import "CognitoPoolIdentityProvider.h"

@implementation CognitoCordovaPlugin

    //hard-coded region constant for the USWest2 region based on current project
    AWSRegionType const CognitoIdentityUserPoolRegion = AWSRegionUSWest2;

    //Config options for the AWS Cognito services to use my identityPool, userPool, and clientId
    NSString *CognitoIdentityUserPoolId;
    NSString *CognitoIdentityUserPoolAppClientId;
    NSString *CognitoIdentityUserPoolAppClientSecret;
    NSString *CognitoIdentityPoolId;
    //hard-coded for now, but need to include in config args from teh plugin calls
    NSString *USER_POOL_NAME = @"FuelStationApp";
    NSString *CognitoIdentityUserPoolRegionString = @"us-west-2";

    //AWS Objects to handle the service interactions
    AWSCognitoIdentityUserPool *pool;
    AWSCognitoIdentityUser *user;
    AWSCognitoIdentityUserPoolConfiguration *configuration;
    AWSServiceConfiguration *serviceConfiguration;
    AWSCognitoCredentialsProvider *credentialsProvider;
    //needed this second svcConfig when cobbling together code, need to revisit this
    AWSServiceConfiguration *serviceConfig;

- (id) init {
    if ( self = [super init] ) {
        return self;
    } else
        return nil;
}

- (void)readOptions:(NSDictionary *)options {
    
    CognitoIdentityPoolId = [options objectForKey:@"arnIdentityPoolId"];
    CognitoIdentityUserPoolId = [options objectForKey:@"CognitoIdentityUserPoolId"];
    CognitoIdentityUserPoolAppClientId = [options objectForKey:@"CognitoIdentityUserPoolAppClientId"];
    //I do not use the Client Secret in my configurations
    CognitoIdentityUserPoolAppClientSecret = nil;
    
}

- (void)initPlugin:(NSDictionary *)options {
    NSLog(@"\n\n**********\nPLUGIN_initPlugin START\n\n");
    [self readOptions:options];
    
    // We can then set this as the default configuration for all AWS SDKs
    serviceConfiguration = [[AWSServiceConfiguration alloc] initWithRegion:CognitoIdentityUserPoolRegion credentialsProvider:nil];
    
    // Setup the pool
    configuration = [[AWSCognitoIdentityUserPoolConfiguration alloc]
                                                              initWithClientId:CognitoIdentityUserPoolAppClientId
                                                              clientSecret:CognitoIdentityUserPoolAppClientSecret
                                                              poolId:CognitoIdentityUserPoolId];
    //register the pool using the serviceConfig and poolConfig for the given poolName as key
    [AWSCognitoIdentityUserPool registerCognitoIdentityUserPoolWithConfiguration:serviceConfiguration
                                                           userPoolConfiguration:configuration
                                                                          forKey:USER_POOL_NAME];
    // Get the pool object now
    pool = [AWSCognitoIdentityUserPool CognitoIdentityUserPoolForKey:USER_POOL_NAME];
    
    // The Credentials Provider holds our identity pool which allows access to AWS resources
    credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                           initWithRegionType:CognitoIdentityUserPoolRegion
                           identityPoolId:CognitoIdentityPoolId
                           identityProviderManager:pool];
    
    //init a new serviceConfig this time providing the credentialsProvider
    AWSServiceConfiguration *svcConfig = [[AWSServiceConfiguration alloc]
                                          initWithRegion:CognitoIdentityUserPoolRegion
                                          credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = svcConfig;
    
    NSLog(@"\n\n**********\nPLUGIN_initPlugin END\n\n");

}

// loginUser: withPassword:
// uses the getSession method of a poolUser to login and return a userSession (idToken, accessToken, refreshToken, expTime)
// the idToken is then used to create a token string w/ the identity pool id, which is used to configure a credentials provider
// for auto-refreshing the session after the 1hr expiration.  Don't really understand this but it seems to work...
//
- (void)loginUser:(NSString *)username withPassword:(NSString *)password {

    NSLog(@"\n\n**********\nPLUGIN_loginUser:withPassword START\n\n");
    // Get the user from the pool
    user = [pool getUser:username];
    
    // getSession with uname/pwd appears to be equivalent of authenticateUser in the javascript SDK
    [[user getSession:username password:password validationData:nil]
     continueWithBlock:^id(AWSTask<AWSCognitoIdentityUserSession *> *task) {
        if (task.error) {
            NSLog(@"\n\nCould not get user session.\n\nError: %@", task.error);
            
        } else {
            NSLog(@"\n\nSuccessfully retrieved user session data");
            
            // Get the session object from our result
            AWSCognitoIdentityUserSession *session = (AWSCognitoIdentityUserSession *) task.result;
            NSLog(@"\n\nTOKEN: %@", [session.idToken.tokenString substringFromIndex:([session.idToken.tokenString length] - 8)]);
            NSLog(@"\n\nEXPIRATION: %@", session.expirationTime);
            
            // Build a token string
            NSString *key = [NSString
                             stringWithFormat:@"cognito-idp.%@.amazonaws.com/%@",
                             CognitoIdentityUserPoolRegionString,
                             CognitoIdentityUserPoolId];
            NSString *tokenStr = [session.idToken tokenString];
            NSDictionary *tokens = [[NSDictionary alloc] initWithObjectsAndKeys:tokenStr, key,  nil];
            
            CognitoPoolIdentityProvider *idProvider = [[CognitoPoolIdentityProvider alloc] init];
            [idProvider addTokens:tokens];
            
            AWSCognitoCredentialsProvider *creds = [[AWSCognitoCredentialsProvider alloc]
                                                    initWithRegionType:CognitoIdentityUserPoolRegion
                                                    identityPoolId:CognitoIdentityPoolId
                                                    identityProviderManager:idProvider];
            
            serviceConfig = [[AWSServiceConfiguration alloc]
                             initWithRegion:CognitoIdentityUserPoolRegion
                             credentialsProvider:creds];
            
            // This sets the default service configuration to allow the API gateway access to user authentication
            AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = serviceConfig;
            
            // Register the pool
            [AWSCognitoIdentityUserPool
             registerCognitoIdentityUserPoolWithConfiguration:serviceConfig
             userPoolConfiguration:configuration
             forKey:USER_POOL_NAME];
        }
        return nil;
    }];
}

// WIP - Async loginUser
// Trying to use the completion handler to provide a callback mechanism so that this can work async on background thread
// but my obj-c skills are very rusty and need time or help to get this setup...
//
- (void)loginUser:(NSString *)username withPassword:(NSString *)password withCompletionHandler:(void(^)(AWSCognitoIdentityUserSession *session)) completion {
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       // Get the user from the pool
                       //    user = [pool currentUser];
                       user = [pool getUser:username];
                       
                       // Make a call to get hold of the users session
                       [[user getSession:username password:password validationData:nil]
                        continueWithBlock:^id(AWSTask<AWSCognitoIdentityUserSession *> *task) {
                            if (task.error) {
                                NSLog(@"Could not get user session. Error: %@", task.error);
                                
                            } else {
                                NSLog(@"Successfully retrieved user session data");
                                
                                // Get the session object from our result
                                AWSCognitoIdentityUserSession *session = (AWSCognitoIdentityUserSession *) task.result;
                                NSLog(@"TOKEN: %@", session.idToken.tokenString);
                                
                                // Build a token string
                                NSString *key = [NSString
                                                 stringWithFormat:@"cognito-idp.%@.amazonaws.com/%@",
                                                 CognitoIdentityUserPoolRegionString,
                                                 CognitoIdentityUserPoolId];
                                NSString *tokenStr = [session.idToken tokenString];
                                NSDictionary *tokens = [[NSDictionary alloc] initWithObjectsAndKeys:tokenStr, key,  nil];
                                
                                CognitoPoolIdentityProvider *idProvider = [[CognitoPoolIdentityProvider alloc] init];
                                [idProvider addTokens:tokens];
                                
                                AWSCognitoCredentialsProvider *creds = [[AWSCognitoCredentialsProvider alloc]
                                                                        initWithRegionType:CognitoIdentityUserPoolRegion
                                                                        identityPoolId:CognitoIdentityPoolId
                                                                        identityProviderManager:idProvider];
                                
                                serviceConfig = [[AWSServiceConfiguration alloc]
                                                 initWithRegion:CognitoIdentityUserPoolRegion
                                                 credentialsProvider:creds];
                                
                                // This sets the default service configuration to allow the API gateway access to user authentication
                                AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = serviceConfig;
                                
                                // Register the pool
                                [AWSCognitoIdentityUserPool
                                 registerCognitoIdentityUserPoolWithConfiguration:serviceConfig
                                 userPoolConfiguration:configuration
                                 forKey:USER_POOL_NAME];
                            }
                            completion(task.result);
                            return nil;
                        }];
                   });
}

// refreshSession
// used to pull a userSession from the pool for the current user.  in cases where the idToken has expired, the SDK
// uses the refreshToken to get a new userSession, which includes a new idToken.  Running the code prints the expiration
// and last (6) char of the idToken.  If the app is left open and running, the logs will show the token remains the same
// until the expiration is reached (about 1hr) and then a new token is issued.
//
- (void)refreshSession {
    
    // Get the user from the pool
    user = [pool currentUser];
    // Get the session for the current user and refresh if needed...
    [[user getSession] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserSession *> * _Nonnull t) {
        if (t.error) {
            NSLog(@"\n\nCould not get user session.\n\nError: %@", t.error);
            NSLog(@"\n\nPlease Login Again...\n");
        } else {
            NSLog(@"\n\n**********\nSession was refreshed!!! Yay!!!\n\n**********\n");
            AWSCognitoIdentityUserSession *session = (AWSCognitoIdentityUserSession *) t.result;
            NSLog(@"\n\nTOKEN: %@", [session.idToken.tokenString substringFromIndex:([session.idToken.tokenString length] - 8)]);
            NSLog(@"\n\nEXPIRATION: %@", session.expirationTime);
        }
        return nil;
    }];
    
}

// logout
// used to logout the userSession and revoke the refresh token, the one flaw is that the idToken appears
// to remain valid for whatever time remains for the current idToken.  I would think the token should be
// revoked once a user logs out.
//
- (void)logout {
    NSLog(@"\n\n**********\nPLUGIN_logout START\n\n");
    
    // Get the user from the pool
    user = [pool currentUser];
    [user globalSignOut];
    
}
@end
