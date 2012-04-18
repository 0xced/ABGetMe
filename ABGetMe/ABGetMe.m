#import "ABGetMe.h"

#import <Foundation/Foundation.h>

#define ABGETME_ENABLE_PRIVATE_APIS 1

#if ABGETME_ENABLE_PRIVATE_APIS

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
						person = ABAddressBookGetPersonWithRecordID(addressBook, ABRecordGetRecordID(record));
					
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

static NSArray *AccountEmailAddresses(void);
static NSArray *AccountEmailAddresses(void)
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

#endif

static ABRecordRef PersonMatchingDeviceName(ABAddressBookRef addressBook);
static ABRecordRef PersonMatchingDeviceName(ABAddressBookRef addressBook)
{
	NSString *ownerName = nil;
	NSString *deviceName = [[UIDevice currentDevice] name];
	// Default device names extracted from iTunes 10.6.1 Localizable.strings files
	NSSet *defaultNameFormats = [NSSet setWithObjects:@"%@ de (.*)", @"(.*) - %@", @"(.*)s %@", @"%@ van (.*)", @"%@ \u03c4\u03bf\u03c5 \u03c7\u03c1\u03ae\u03c3\u03c4\u03b7 \u00ab(.*)\u00bb", @"(.*)\u2019s %@", @"K\u00e4ytt\u00e4j\u00e4n (.*) %@", @"%@ von (.*)", @"%@ od (.*)", @"(.*) %@ k\u00e9sz\u00fcl\u00e9ke", @"%@ di (.*)", @"(.*) \u306e %@", @"(.*)\uc758 %@", @"%@ ((.*))", @"%@ - (.*)", @"%@ (.*)", @"%@ u\u017e\u00edvate\u013ea (.*)", @"%@ \u0e02\u0e2d\u0e07 (.*)", @"(.*) %@'u", @"(.*) %@'i", @"(.*)\u00a0\u2014 %@", @"\u201c(.*)\u201d\u7684 %@", @"(.*) \u7684 %@", nil];
	NSSet *models = [NSSet setWithObjects:@"iPad", @"iPhone", @"iPod", nil];
	for (NSString *model in models)
	{
		for (NSString *defaultNameFormat in defaultNameFormats)
		{
			NSString *defaultNamePattern = [NSString stringWithFormat:defaultNameFormat, model];
			NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:defaultNamePattern options:0 error:NULL];
			NSTextCheckingResult *result = [regularExpression firstMatchInString:deviceName options:0 range:NSMakeRange(0, [deviceName length])];
			if (result)
			{
				ownerName = [deviceName substringWithRange:[result rangeAtIndex:1]];
				break;
			}
		}
		if (ownerName)
			break;
	}
	
	if (!ownerName)
		return NULL;

	ABRecordRef person = NULL;
	CFArrayRef people = ABAddressBookCopyPeopleWithName(addressBook, (__bridge CFStringRef)ownerName);
	if (people)
	{
		if (CFArrayGetCount(people) == 1)
			person = ABAddressBookGetPersonWithRecordID(addressBook, ABRecordGetRecordID(CFArrayGetValueAtIndex(people, 0)));
		
		CFRelease(people);
	}
	
	return person;
}

ABRecordRef ABGetMe(ABAddressBookRef addressBook)
{
	ABRecordRef me = NULL;
	
#if ABGETME_ENABLE_PRIVATE_APIS
	me = Me();
	if (me)
		return me;
	
	me = PersonMatchingEmailAddresses(addressBook, AccountEmailAddresses());
	if (me)
		return me;
#endif
	
	me = PersonMatchingDeviceName(addressBook);
	if (me)
		return me;
	
	return NULL;
}
