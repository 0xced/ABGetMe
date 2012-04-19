About
=====

Unlike the Mac Address Book API, the iOS Address Book API does not come with the [ABGetMe](http://developer.apple.com/library/mac/documentation/userexperience/Reference/AddressBook/C/ABAddressBookRef/Reference/reference.html#//apple_ref/c/func/ABGetMe) function. **ABGetMe** circumvents this limitation by trying to read *My Info* from the Contacts settings.

![Contacts Settings](https://raw.github.com/0xced/ABGetMe/master/MyInfo.png "My Info")

If *My Info* is not found, then **ABGetMe** tries to match the configured e-mail account addresses with the records of the address book to find the *me* record.

If the *me* record is still not found, then **ABGetMe** finally tries to extract the device owner's full name from the device name in order to find the *me* record. This technique was explained by John Feminella in his answer to [How does Square know my name in their app's registration process?](http://www.quora.com/Square-company/How-does-Square-know-my-name-in-their-apps-registration-process/answer/John-Feminella) on Quora.

Requirements
============
* **ABGetMe** requires iOS 4.0 or later.
* **ABGetMe** can be compiled either with or without Automatic Reference Counting (ARC).

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

* Reading *My Info* from the Contacts settings uses undocumented APIs.
* Reading configured e-mail account addresses uses undocumented APIs.
* Reading the device name is a public API.

You can disable private APIs by setting `ABGETME_ENABLE_PRIVATE_APIS` to `0` instead of `1` at the top of the `ABGetMe.m` file. Note that disabling private APIs considerably reduces the chances of finding the *me* record. The only method left to find the *me* record when disabling private APIs is the last one (i.e. matching the device name) which only works if the device owner never changed the default device name.
