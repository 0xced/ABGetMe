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
		Class MFMailAccountProxy = NSClassFromString([@"MF" stringByAppendingString:MailAccountProxy]) ?: NSClassFromString(MailAccountProxy);
		Class MFMailAccountProxyGenerator = NSClassFromString([[NSArray arrayWithObjects:@"MF", @"Mail", @"Account", @"Proxy", @"Generator", nil] componentsJoinedByString:@""]);
		SEL sel_reloadAccounts = NSSelectorFromString([[NSArray arrayWithObjects:@"reload", @"Accounts", nil] componentsJoinedByString:@""]);
		SEL sel_mailAccounts = NSSelectorFromString([[NSArray arrayWithObjects:@"mail", @"Accounts", nil] componentsJoinedByString:@""]);
		SEL sel_emailAddresses = NSSelectorFromString([[NSArray arrayWithObjects:@"email", @"Addresses", nil] componentsJoinedByString:@""]);
		SEL sel_allAccountProxies = NSSelectorFromString([[NSArray arrayWithObjects:@"all", @"Account", @"Proxies", nil] componentsJoinedByString:@""]);
		
		NSArray *mailAccounts = nil;
		if (MFMailAccountProxyGenerator)
		{
			id mailAccountProxyGenerator = [[MFMailAccountProxyGenerator alloc] init];
			mailAccounts = [mailAccountProxyGenerator performSelector:sel_allAccountProxies];
		}
		else
		{
			[MFMailAccountProxy performSelector:sel_reloadAccounts];
			mailAccounts = [MFMailAccountProxy performSelector:sel_mailAccounts];
		}
		
		for (id mailAccount in mailAccounts)
		{
			for (id emailAddress in [mailAccount performSelector:sel_emailAddresses])
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
	NSArray *defaultNameFormats = [NSArray arrayWithObjects:@"%@ de (.*)", // Catalan, French, Portuguese, Spanish
	                                                        @"%@ di (.*)", // Italian
	                                                        @"%@ od (.*)", // Croatian
	                                                        @"%@ van (.*)", // Dutch
	                                                        @"%@ von (.*)", // German
	                                                        @"%@ u\u017e\u00edvate\u013ea (.*)", // Slovak
	                                                        @"%@ \u03c4\u03bf\u03c5 \u03c7\u03c1\u03ae\u03c3\u03c4\u03b7 \u00ab(.*)\u00bb", // Greek
	                                                        @"%@ \u0e02\u0e2d\u0e07 (.*)", // Thai
	                                                        @"%@ \\((.*)\\)", // Polish
	                                                        @"%@ - (.*)", // Romanian
	                                                        @"K\u00e4ytt\u00e4j\u00e4n (.*) %@", // Finnish
	                                                        @"\u201c(.*)\u201d\u7684 %@", // Chinese (China)
	                                                        @"(.*)\u00a0\u2014 %@", // Ukrainian
	                                                        @"(.*)\uc758 %@", // Korean
	                                                        @"(.*)\u2019s %@", // English
	                                                        @"(.*)s %@", // Danish, Norwegian, Swedish
	                                                        @"(.*) \u7684 %@", // Chinese (Taiwan)
	                                                        @"(.*) %@'u", // Turkish (iPhone, iPod)
	                                                        @"(.*) %@'i", // Turkish (iPad)
	                                                        @"(.*) %@ k\u00e9sz\u00fcl\u00e9ke", // Hungarian
	                                                        @"(.*) \u306e %@", // Japanese
	                                                        @"(.*) - %@", // Czech
	                                                        @"%@ (.*)", // Russian
	                                                        nil];
	NSArray *models = [NSArray arrayWithObjects:@"iPad", @"iPhone", @"iPod", @"iPod touch", nil];
	for (NSString *model in models)
	{
		for (NSString *defaultNameFormat in defaultNameFormats)
		{
			NSString *defaultNamePattern = [NSString stringWithFormat:defaultNameFormat, model];
			NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:defaultNamePattern options:NSRegularExpressionCaseInsensitive error:NULL];
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
