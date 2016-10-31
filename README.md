# NewPriceHistory
nph.pm is a perl script that clears all previous Finance::Quote* entries
from a GnuCash SQLite datafile and replaces them with monthly price entries
for all STOCK and MUTUAL FUND type commodities in the file.
It retrieves prices for the period that a given commodity is held.

Note that it operates on a backup copy of the data file.

Usage:

>nph.pm FILENAME [CURRENCYCODE] [STARTDATE]

CURRENCYCODE allows command line specification of the currency to be 
associated with each price. This defaults to USD. If the code you supply 
is not in your commodities table, then no prices will be added, since
the prices table requires a currency guid for each price entry. 

STARTDATE (not yet implemented) will allow command line limitation of the
date range, so that future iterations of the program would only modify the
prices table after this date. This will allow ongoing maintenance of prices
without requiring all past history to be cleared.
