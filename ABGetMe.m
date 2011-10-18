// Application must link with the MessageUI framework
NSArray* AccountEmailAddresses(void)
{
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
	ABRecordRef me = NULL;
	NSArray *accountEmailAddresses = AccountEmailAddresses();
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
					if ([accountEmailAddresses containsObject:(id)email])
						me = record;
					
					CFRelease(email);
				}
				if (me)
					break;
			}
			CFRelease(emails);
		}
		if (me)
			break;
	}
	CFRelease(people);
	
	return me;
}
