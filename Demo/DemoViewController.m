//
//  ViewController.m
//  ABGetMe
//
//  Created by Cédric Luthi on 13.01.12.
//  Copyright (c) 2012 Cédric Luthi. All rights reserved.
//

#import "DemoViewController.h"

#import "ABGetMe.h"

@implementation DemoViewController
{
	ABAddressBookRef addressBook;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
		return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
	else
		return YES;
}

- (id) init
{
	if (!(self = [super initWithNibName:@"DemoViewController" bundle:nil]))
		return nil;
	
	addressBook = ABAddressBookCreate();
	
	return self;
}

- (void) dealloc
{
	CFRelease(addressBook);
	[super dealloc];
}

// MARK: - Actions

- (IBAction) me
{
	ABRecordRef me = ABGetMe(addressBook);
	
	NSLog(@"me = %@", me);
}

@end
