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
}

// MARK: - Actions

- (void) done
{
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction) me
{
	ABRecordRef me = ABGetMe(addressBook);
	
	if (!me)
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"ABGetMe" message:@"The “me” card was not found." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
		[alertView show];
		return;
	}
	
	ABPersonViewController *personViewController = [[ABPersonViewController alloc] init];
	personViewController.displayedPerson = me;
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:personViewController];
	[self presentModalViewController:navigationController animated:YES];
	
	personViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];

}

@end
