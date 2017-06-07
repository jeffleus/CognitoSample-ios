//
//  ViewController.m
//  CognitoSample
//
//  Created by Jeff Leininger on 5/27/17.
//  Copyright © 2017 Jeff Leininger. All rights reserved.
//

#import "ViewController.h"
#import "CognitoPoolIdentityProvider.h"
#import "CognitoCordovaPlugin.h"

@interface ViewController ()

@end

@implementation ViewController
    CognitoCordovaPlugin *plugin;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    plugin = [[CognitoCordovaPlugin alloc] init];
    
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:
                             @"***IDENTITY POOL ARN", @"arnIdentityPoolId",
                             @"***USER POOL CLIENT ID***", @"CognitoIdentityUserPoolAppClientId",
                             @"***USER POOL ID***", @"CognitoIdentityUserPoolId", nil];
    NSLog(@"\n\n**********\nClient Starting INIT process...\n\n");
    [plugin initPlugin:options];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didTouchLogin:(id)sender {
    NSLog(@"\n\n**********\nClient Starting LOGIN process...\n\n");
    
    NSString *username = @"***USERNAME***";
    NSString *password = @"***PASSSWORD***";
    [plugin loginUser:username withPassword:password];
    
}

- (IBAction)didTouchLogout:(id)sender {
    
    NSLog(@"\n\n**********\nClient Starting LOGOUT process...\n\n");
    [plugin logout];
    
}

- (IBAction)didTouchGetToken:(id)sender {
    
    NSLog(@"\n\n**********\nClient Starting REFRESH process...\n\n");
    [plugin refreshSession];
    
}

- (void)getCurrentSession {
        
}

@end
