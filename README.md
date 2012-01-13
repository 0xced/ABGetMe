About
=====

Unlike the Mac Address Book API, the iOS Address Book API does not come with the [ABGetMe](http://developer.apple.com/library/mac/documentation/userexperience/Reference/AddressBook/C/ABAddressBookRef/Reference/reference.html#//apple_ref/c/func/ABGetMe) function. **ABGetMe** circumvents this limitation by trying to read *My Info* from the Contacts settings.

![Contacts Settings](https://raw.github.com/0xced/ABGetMe/master/MyInfo.png "My Info")

If *My Info* is not found, then **ABGetMe** will try to match your e-mail account addresses to find the *me* record.

Usage
=====

1. Copy `ABGetMe.h` and `ABGetMe.m` into your Xcode project
2. Use the `ABGetMe()` function and don’t forget to check if the result is not `NULL`.

		ABAddressBookRef addressBook = ABAddressBookCreate();
		ABRecordRef me = ABGetMe(addressBook);
		if (me) {
			// do something with "me"
		}	
		CFRelease(addressBook);

Limitations
===========

**ABGetMe** is not *legally* App Store compliant because it uses undocumented APIs which is proscribed by clause 3.3.1 of the iPhone Developer Program License Agreement. It is *technically* App Store compliant though as it will pass the App Store validation. Moreover, it should not crash even if the undocumented APIs change in the future.
