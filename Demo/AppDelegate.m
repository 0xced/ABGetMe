//
//  AppDelegate.m
//  ABGetMe
//
//  Created by Cédric Luthi on 13.01.12.
//  Copyright (c) 2012 Cédric Luthi. All rights reserved.
//

#import "AppDelegate.h"

#import "DemoViewController.h"

@implementation AppDelegate

@synthesize window = _window;

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = [[DemoViewController alloc] init];
	[self.window makeKeyAndVisible];
	
	return YES;
}

@end
