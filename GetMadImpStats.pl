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

sub HandleEnd
{
 my ($aExitCode) = shift (@_);
 update_log ($StrAppName . " stopped ...", $StrLogFile);
 exit ($aExitCode) if (defined ($aExitCode));
 return (0);
}

sub GetCMDParameter
{
 my ($aPara) = "";
 while (@ARGV)
  {
   $aPara = shift (@ARGV);
   if ($aPara =~ /-d/)
    {
     $aPara = shift (@ARGV);
     chomp ($StrToday = `date -d '$aPara +1 day' +'%Y%m%d'`);
     chomp ($StrYesterday = `date -d '$aPara' +'%Y%m%d'`);
    }
  }
}

sub InitAll
{
 chomp ($StrToday = `date +'%Y%m%d'`);
 chomp ($StrYesterday = `date -d yesterday +'%Y%m%d'`);
 $StrAppName = GetAppName();
 $StrLogFile = $ENV{"OMCLOGDIR"} . "/" . $StrAppName . "_" . $StrToday . ".log";
 $StrMadImpDir = $ENV{"NMSTRACEDIR"} . "/madimp";
 $StrRegion = GetRegion ();
 GetCMDParameter ();
}

sub HandleStart
{

 InitAll ();
 update_log ($StrAppName . " started ...", $StrLogFile);

 if ( ! ( -d $StrMadImpDir))
  {
   update_log ("MADIMP dir : " . $StrMadImpDir . " does not exist!", $StrLogFile);
   HandleEnd (1);
  }

 if (GetHostPurpose() =~ /DS/)
  {
   update_log ("Is not running on DS", $StrLogFile);
   HandleEnd (1);
  }
}

sub GetMadImpBufferFiles
{
 my ($aRef) = shift (@_);
 my ($aAda) = shift (@_);
 my (@aTodayList) = ();
 my (%aTodayHash) = ();
 my ($aFile)      = "";
 my (@aTmp)       = ();

 @{$aRef} = grep ( /$StrToday/ || /$StrYesterday/, search_dir ($StrMadImpDir, "BUFFERING"));

 # get adaptor names
 foreach $aFile (@{$aRef})
  {
   @aTmp = split ("_", $aFile);
   ${$aAda} {shift (@aTmp)."_".shift (@aTmp)."_".shift (@aTmp)} = 0;
  }

 # now get first file of the day to complete the files to be parsed
 @aTodayList = grep ( /$StrToday/, @{$aRef});
 # i can delete now the todays files from ref
 @{$aRef} = grep ( /$StrYesterday/, @{$aRef});

 foreach $aFile (@aTodayList)
  {
   @aTmp = split ('\.', $aFile);
   $aTodayHash {shift (@aTmp)} = 0;
  }

 foreach $aFile (keys (%aTodayHash))
  {
   # get first adaptor file per day
   @aTmp = sort (grep ( /$aFile/, @aTodayList));
   # here I get the first madimp file name from the day, using sort
   push (@{$aRef}, shift (@aTmp));
  }
 return ((scalar (@{$aRef}) > 0) && (scalar (keys %{$aAda}) > 0));
}

sub ProcessFile
{
 my ($aFN)   = shift (@_);
 my ($aRef)  = shift (@_);
 my ($aHsh)  = shift (@_);
 my ($aLine) = "";
 my (@aTmp)  = ();
 my (@aRes)  = ();
 my ($aMIFN) = "";
 my ($aTS)   = "";

 # if it is a todays file, just concider timestamps with yesterdays format
 chomp ($aTS = `date -d $StrYesterday +'%a %b %d'`);

 # filter actual work lines
 @{$aRef} = grep ( /Created at/ && /$aTS/, @{$aRef});

 # I hope this is in every file
 # @{$aRef} = grep ( /$StrYesterday/, @{$aRef});

 if (scalar (@{$aRef}) == 0)
  {
   update_log ("Nothing happened in file " . $aFN, $StrLogFile);
   return (0);
  }

 foreach $aLine (@{$aRef})
  {
   $aLine =~ s/Created at(.+)//g;
   @aRes = split (": ", $aLine);
   if (scalar (@aRes) == 2)
    {
     $aRes[1] =~ s/^\s+|\s+$//g;
     $aMIFN =  pop (@aRes);
     ${$aHsh} {$aMIFN}++;
    }
   else
    {
     update_log ("Something wrong with format in file " . $aFN, $StrLogFile);
    }
  }
}

sub ProcessAdaptorFiles
{
 my ($aAda) = shift (@_);
 my ($aRef) = shift (@_);
 my ($aHash)= shift (@_);
 my ($aFile)     = "";
 my ($aFilePath) = "";
 my (@aFileLines)= ();

 if (scalar (@{$aRef}) > 0)
  {
   foreach $aFile (sort @{$aRef})
    {
     @aFileLines = ();
     $aFilePath = $StrMadImpDir . "/" . $aFile;
     update_log ("Processing " . $aFilePath, $StrLogFile);
     if (read_file ($aFilePath, \@aFileLines))
      {
       ProcessFile ($aFilePath, \@aFileLines, $aHash);
      }
     else
      {
       update_log ("Could not read file " . $aFilePath, $StrLogFile);
      }
    }
  }
 else
  {
   update_log ("Something wrong with adaptor files for " . $aAda, $StrLogFile);
  }
}

sub Update_DB
{

 my ($aRegion) = shift (@_);
 my ($aAda)    = shift (@_);
 my ($aDesc)   = shift (@_);
 my ($aPST)    = shift (@_);
 my ($aSum)    = shift (@_);
 my ($aPeriod) = shift (@_);
 my ($aDup)    = shift (@_);

 return (0) if ($BoolUpdateDB == 0);

 my ($db_name) = 'oss';
 my ($user)    = 'tcmadm';
 my ($pass)    = 'tcmadm';
 my ($dbh)     = DBI->connect( "dbi:Oracle:$db_name",
                               $user, $pass ,
                              { RaiseError => 1,ShowErrorStatement => 1, AutoCommit => 1});
 my ($DBQuery) = "INSERT INTO TCMADM_P_NUMOFILES_HOUR " .
                 "(REGION,ADAPTATION,ADAPTATION_DESC,PERIOD_START_TIME,NUMOF_FILES,PERIOD_DURATION,NUMBER_OF_DUP,TIME_STAMP) " .
                 "values(?,?,?,to_date(?,'yyyymmdd hh24mi'),?,?,?,SYSDATE)";
 if (! $dbh)
  {
   update_log ("Error opening the DB", $StrLogFile);
   return (0);
  }

 my  ($sth);

 $sth = $dbh->prepare($DBQuery);
 if ($DBI::err)
  {
    update_log ("Error preparing the query: " . $DBQuery, $StrLogFile);
    return (0);
  }

 $sth->execute ($aRegion, $aAda, $aDesc, $aPST, $aSum, $aPeriod, $aDup);
 if ($DBI::err)
  {
    update_log ("Error executing the query: " . $DBQuery, $StrLogFile);
  }
 $sth->finish();
}

sub WriteReport
{
 my ($aAda) = shift (@_);
 my ($aRef) = shift (@_);
 my ($aSum) = 0;
 my ($aDup) = 0;
 my ($aKey) = "";
 my ($aLn)  = "";
 my ($aPD)  = 0;
 my (@aTmp) = ();

 $aSum = keys (%{$aRef}) if (scalar (keys (%{$aRef})) > 0);

 foreach $aKey (keys %{$aRef})
  {
   $aDup += (${$aRef}{$aKey} - 1) if (${$aRef}{$aKey} > 1);
  }

 $aAda =~ s/_BUFFERING_/ /g;
 $aLn = $StrYesterday . " " . $aAda . " " . $aSum . " files and " . $aDup . " duplicates - so " . ($aSum + $aDup);
 update_log ($aLn, $StrLogFile);

 $aPD = $IntDefPeridoD;
 foreach $aLn (keys (%PeriodDuration))
  {
   if (grep ( /$aLn/, $aAda))
    {
     $aPD = $PeriodDuration{$aLn};
     last;
    }
  }

 @aTmp = split (" ", $aAda);
 $aLn = $StrRegion . "," . $aTmp[0] . "," . $aTmp[1] . "," . $StrYesterday .
                     "," . ($aSum + $aDup) . "," . $aPD . "," . $aDup ;
 update_log ("DB parameter: " . $aLn, $StrLogFile);

 Update_DB ($StrRegion,$aTmp[0],$aTmp[1],$StrYesterday,($aSum + $aDup),$aPD,$aDup);

}

sub ProcessMadImpFiles
{
 my ($aRef) = shift (@_);
 my ($aAda) = shift (@_);
 my ($aAdaptor)  = "";
 my (@aFileList) = ();
 my (%aHash)     = ();
 my ($aAdaptor)  = "";

 update_log ("I found " . join (" ", keys %{$aAda}) . " Adaptors to process!", $StrLogFile);
 update_log ("I found " . scalar (@{$aRef}) . " madimp files to process!", $StrLogFile);


 foreach $aAdaptor (sort keys %{$aAda})
  {
   %aHash = ();
   update_log ("Processing adaptor files for " . $aAdaptor, $StrLogFile);
   @aFileList = grep ( /$aAdaptor/, @{$aRef});
   ProcessAdaptorFiles ($aAdaptor, \@aFileList, \%aHash);
   WriteReport ($aAdaptor, \%aHash);
  }
}

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
