#!/opt/nokia/oss/perl/bin/perl

use strict;
use Utils;
use DBI;

my (%PeriodDuration) = ('madera' => 15,
                        'madawp' => 15);

my ($IntDefPeridoD) = 60;
my ($StrAppName)    = "";
my ($StrLogFile)    = "";
my ($StrMadImpDir)  = "";
my ($StrYesterday)  = "";
my ($StrToday)      = "";
my ($BoolUpdateDB)  = 1;
my ($StrDate)       = "";
my ($StrRegion)     = "";

Main ();



sub Main
{
 my (%Adaptors)    = ();
 my (@MadImpFiles) = ();
 HandleStart();

 if (GetMadImpBufferFiles (\@MadImpFiles, \%Adaptors))
  {
   ProcessMadImpFiles (\@MadImpFiles, \%Adaptors);
  }
 HandleEnd ();
}
