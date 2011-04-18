// Application must link with the MessageUI framework
NSArray* AccountEmailAddresses(void)
{
	NSMutableArray *emailAddresses = [NSMutableArray array];
	@try
	{
		Class MailComposeController = NSClassFromString(@"MailComposeController") ?: NSClassFromString(@"MFMailComposeController");
		NSArray *accountEmailAddresses = [MailComposeController performSelector:@selector(accountEmailAddresses)];
		for (id address in accountEmailAddresses)
		{
			if ([address isKindOfClass:[NSString class]])
				[emailAddresses addObject:address];
		}
	}
	@catch (NSException *e) {}
	
	return [NSArray arrayWithArray:emailAddresses];
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
