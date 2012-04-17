#import "ABGetMe.h"

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

static ABRecordRef Me(void);
static ABRecordRef Me(void)
{
	ABRecordRef me = NULL;
	
	@try
	{
		Class ABHelper = NSClassFromString([@"AB" stringByAppendingString:@"Helper"]);
		SEL sel_sharedHelper = NSSelectorFromString([@"shared" stringByAppendingString:@"Helper"]);
		SEL sel_me = NSSelectorFromString([@"m" stringByAppendingString:@"e"]);
		me = (__bridge ABRecordRef)[[ABHelper performSelector:sel_sharedHelper] performSelector:sel_me];
	}
	@catch (NSException *exception)
	{
		me = NULL;
	}
	
	return me;
}

static ABRecordRef PersonMatchingEmailAddresses(ABAddressBookRef addressBook, NSArray *emailAddresses);
static ABRecordRef PersonMatchingEmailAddresses(ABAddressBookRef addressBook, NSArray *emailAddresses)
{
	ABRecordRef person = NULL;
	CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
	CFIndex peopleCount = CFArrayGetCount(people);
	for (CFIndex i = 0; i < peopleCount; i++)
	{
		ABRecordRef record = CFArrayGetValueAtIndex(people, i);
		ABMultiValueRef emails = ABRecordCopyValue(record, kABPersonEmailProperty);
		if (emails)
		{
			CFIndex emailCount = ABMultiValueGetCount(emails);
			for (CFIndex j = 0; j < emailCount; j++)
			{
				CFStringRef email = ABMultiValueCopyValueAtIndex(emails, j);
				if (email)
				{
					if ([emailAddresses containsObject:(__bridge id)email])
						person = record;
					
					CFRelease(email);
				}
				if (person)
					break;
			}
			CFRelease(emails);
		}
		if (person)
			break;
	}
	CFRelease(people);
	
	return person;
}

NSArray *AccountEmailAddresses(void)
{
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		NSString *systemLibraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSSystemDomainMask, NO) lastObject];
		NSString *messageUIPath = [[systemLibraryPath stringByAppendingPathComponent:@"Frameworks"] stringByAppendingPathComponent:@"MessageUI.framework"];
		NSBundle *messageUI = [NSBundle bundleWithPath:messageUIPath];
		[messageUI load];
	});
	
	NSMutableArray *addresses = [NSMutableArray array];
	@try
	{
		NSString *MailAccountProxy = [[NSArray arrayWithObjects:@"Mail", @"Account", @"Proxy", nil] componentsJoinedByString:@""];
		NSString *MFMailAccountProxy = [@"MF" stringByAppendingString:MailAccountProxy];
		Class MailAccountProxyClass = NSClassFromString(MFMailAccountProxy) ?: NSClassFromString(MailAccountProxy);
		SEL reloadAccounts = NSSelectorFromString([[NSArray arrayWithObjects:@"reload", @"Accounts", nil] componentsJoinedByString:@""]);
		SEL mailAccounts = NSSelectorFromString([[NSArray arrayWithObjects:@"mail", @"Accounts", nil] componentsJoinedByString:@""]);
		SEL emailAddresses = NSSelectorFromString([[NSArray arrayWithObjects:@"email", @"Addresses", nil] componentsJoinedByString:@""]);
		
		[MailAccountProxyClass performSelector:reloadAccounts];
		for (id mailAccount in [MailAccountProxyClass performSelector:mailAccounts])
		{
			for (id emailAddress in [mailAccount performSelector:emailAddresses])
			{
				if ([emailAddress isKindOfClass:[NSString class]])
					[addresses addObject:emailAddress];
			}
		}
	}
	@catch (NSException *e) {}
	
	return [NSArray arrayWithArray:addresses];
}

ABRecordRef ABGetMe(ABAddressBookRef addressBook)
{
	ABRecordRef me = Me();
	if (me)
		return me;
	
	me = PersonMatchingEmailAddresses(addressBook, AccountEmailAddresses());
	if (me)
		return me;
	
	return NULL;
}
