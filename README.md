airport-autojoin
================

**TL;DR Summary:** a [mac os x specific] shell script to automatically join Wi-Fi/AirPort networks


## Details ##

I came across [this question on AskDifferent] and it reminded me that I had run into that same problem with one of my Macs awhile ago.

I dug out the shell script that I had written to "solve" the problem, and then (of course) decided to re-write it, even though I'm not having the problem now.

The idea is very simple:

* use the `airport` command[^airportcommand] to check to see if we are connected to a Wi-Fi network

	* If we are connected to a Wi-Fi network already, exit

	* If we are *not* connected to a Wi-Fi network, scan for local available networks.

* Compare available SSIDs against a list of "known SSIDs" (which you have to add to the script)
	* if none are available, exit
	* if one is available, try to join it using the `networksetup` command.

That's pretty much it.





[^airportcommand]: You know about the `airport` command, right? It's located at /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport although I always link it to /usr/local/bin/airport as soon as I setup a new Mac.


[this question on AskDifferent]: http://apple.stackexchange.com/questions/89616/osx-wont-automatically-connect-to-wifi