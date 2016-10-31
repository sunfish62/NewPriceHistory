#!/usr/bin/perl -w

###########################################################################
#
# nph.pm is a perl script that clears all previous Finance::Quote* entries
# from a GnuCash SQLite datafile and replaces them with monthly price entries
# for all STOCK and MUTUAL FUND type commodities in the file.
# It retrieves prices for the period that a given commodity is held.
#
# Note that it operates on a backup copy of the data file.
#
# Usage:
#
# >nph.pm FILENAME [CURRENCYCODE] [STARTDATE]
# 
# CURRENCYCODE allows command line specification of the currency to be 
# associated with each price. This defaults to USD. If the code you supply 
# is not in your commodities table, then no prices will be added, since
# the prices table requires a currency guid for each price entry. 
#
# STARTDATE (not yet implemented) will allow command line limitation of the
# date range, so that future iterations of the program would only modify the
# prices table after this date. This will allow ongoing maintenance of prices
# without requiring all past history to be cleared.
#
###########################################################################

use strict;
use File::Copy;
use DBI;
use Data::GUID;
use Finance::QuoteHist;

$VERSION = '0.9';

# Command line processing
my $dflttext  = "Creates new price-db with monthly prices for all holdings in a copy of the source file.
  Usage: $0 FILENAME [CURRENCYCODE] [STARTDATE]
  Note that STARTDATE is not implemented yet.
   ";
my $dfile; # destination file
my $nfile = shift or die $dflttext; 
my $default_currency = shift; # Allow currency to be set from command line
my $startpoint = shift; # Allow user to select a start point, helpful for updating
my $progress = "."; 

if (!defined $default_currency) { $default_currency = "USD"; } 

# Copy source file to new location
my @arr = split(/\./, $nfile);
$arr[$#arr-1] .= "-nph"; 
$dfile = join(".", @arr);
copy($nfile, $dfile) or die "File $nfile not copied to $dfile.\nProcess aborted.\n";

# Set database connection
my @driver_names = DBI->available_drivers;
my %drivers      = DBI->installed_drivers;
#my @data_sources = DBI->data_sources(my $driver_name, \%attr);
my ($username, $auth, $sth, $sql);
my $dsn = "dbi:SQLite:dbname=" . $dfile;
my $dbh = DBI->connect($dsn, $username, $auth, {
   PrintError       => 0,
   RaiseError       => 1,
   AutoCommit       => 1,
   FetchHashKeyName => 'NAME_lc',
}) or die "Cannot connect to database.";

# Clear prices table of old F::Q entries in GCFilename-nph
$sql = "DELETE FROM prices WHERE source like 'Finance%';";
$sth = $dbh->do($sql);

# Retrieve currency guid and denominator
$sql = "SELECT guid, fraction FROM commodities WHERE mnemonic='$default_currency';";
my ($currencyguid, $denom) = $dbh->selectrow_array($sql);

my ($DAY, $MONTH, $YEAR) = (localtime)[3,4,5];
my $daynow = $YEAR + 1900 . $MONTH + 1 . $DAY;
my $source = "Finance::QuoteHist";
my $stype = "last";

# Retrieve commodities in file
my ($symbol, $comguid, $shares, $startdate, $enddate);

$sql  = "SELECT c.mnemonic, c.guid, 
  ROUND(SUM((s.quantity_num*1.0/s.quantity_denom)), LENGTH(REPLACE(c.fraction, '1', ''))), 
  MIN(t.post_date), MAX(t.post_date) 
  FROM accounts as a, commodities as c, splits as s, transactions as t 
  WHERE (a.account_type='MUTUAL' OR a.account_type='STOCK') 
  AND a.guid=s.account_guid AND s.tx_guid=t.guid AND a.commodity_guid=c.guid 
  GROUP BY c.mnemonic
  ;";
 
$sth = $dbh->prepare($sql);
$sth->execute();

while ( my @row = $sth->fetchrow_array ) {
  ($symbol, $comguid, $shares, $startdate, $enddate) = @row;
  # if (defined $startpoint) { $startdate = $startpoint; }
  if ($shares > 0) { $enddate = $daynow; }

  # with each commodity, run Finance::QuoteHist
  my $q = Finance::QuoteHist->new
    (
      symbols    => $symbol,
      start_date => $startdate,
      end_date   => $enddate,
      granularity => "monthly",
    ); 
  
  $sql = "INSERT into prices VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
  my $sth2 = $dbh->prepare($sql);
  $dbh->begin_work();
  foreach my $qrow ($q->quotes()) {
    my $pguid = lc Data::GUID->new;
    $pguid =~ s/-//g;
    my ($name,$date, $open, $high, $low, $close, $volume) = @$qrow;
    my $closeint = $close * $denom;
    $sth2->execute($pguid, $comguid, $currencyguid, $date, $source, $stype, $closeint, $denom);
    undef $pguid ;
  }
  $dbh->commit();
}
print "\nDone.\n";
