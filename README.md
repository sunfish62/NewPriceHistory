# NewPriceHistory
nph.pm is a perl script that clears all previous Finance::Quote entries
from a GnuCash SQLite datafile and replaces them with monthly price entries
for all STOCK and MUTUAL FUND type commodities in the file.

IMPORTANT! This script writes DIRECTLY to the GnuCash database without using the GnuCash API! 

IT HAS THE POTENTIAL TO CORRUPT YOUR DATABASE AND RENDER IT UNUSABLE, SO MAKE SURE YOU HAVE A GOOD BACKUP BEFORE YOU BEGIN!

Note, however, that the script operates on a copy of your file, and that the prices table is a stand-alone part of the data file. No core GnuCash data or processes depend on it, so the worst that will happen (aside from GnuCash crashing on startup) is that all of the values in the Accounts page, the summary bar, and reports will be wrong for every stock and mutual fund account.

This script has the following steps:
1 - Copies your data file to a new file.
2 - Clears the prices table of all price entries that have Finance* as their source (leaving user-supplied prices intact).
3 - Retrieves a complete list of the stocks and mutual funds in the file.
4 - Retrieves monthly price quotes for all holdings.
5 - Inserts them into the prices table

USAGE:

>nph.pm FILENAME [CURRENCYCODE] [STARTDATE]

CURRENCYCODE allows command line specification of the currency to be 
associated with each price. This defaults to USD. If the code you supply 
is not in your commodities table, then no prices will be added, since
the prices table requires a currency guid for each price entry. 

STARTDATE (not yet implemented) will allow command line limitation of the
date range, so that future iterations of the program would only modify the
prices table after this date. This will allow ongoing maintenance of prices
without requiring all past history to be cleared.

CONDITIONS FOR USE:

This script operates on SQLite GnuCash files; if your data file is XML (which is the default), then you must save it as a SQLite database before using. You can always Save As to go back to XML. 

If you are using one of the other database back ends supported by GnuCash, you will no doubt have to change things. 

It has been tested only with USD as the currency; if you have stocks or mutual funds denominated in another currency, you should monitor the results closely and alter the script accordingly. 

The script assumes that all stocks and mutual funds are denominated in the SAME currency, so if you have a file that contains commodities denominated in more than one currency, you should monitor the results closely and alter the script accordingly. 

If a ticker cannot be found by Finance::QuoteHist, it outputs a number of ugly messages to the console that don’t affect the results of this script.


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                !
!         WARNING! WARNING! WARNING!             !
!                                                !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 

This script is offered as is, with NO GUARANTEES.

USE AT YOUR OWN RISK.

MAKE SURE YOU HAVE A GOOD BACKUP!

This script writes DIRECTLY to the GnuCash database without using the GnuCash API!

THIS SCRIPT HAS THE POTENTIAL TO CORRUPT YOUR DATABASE AND RENDER IT UNUSABLE. 

Because the script modifies the data directly, if something goes wrong, the GnuCash developers can offer no help, beyond suggesting reloading a backup.

