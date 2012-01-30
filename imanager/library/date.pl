#
# date.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/date.pl,v 2.12.2.1 2006/04/25 19:48:23 rus Exp $
#
# date functions
#

##############################################################################

sub dateBuildTimeString
{
  local($tztype, $epoch) = @_;
  local($datestring, $mytime, $isdst);
  local($lsec, $lmin, $lhour, $lmday, $lmon, $lyear, $lwday, $yday);
  local($gsec, $gmin, $ghour, $gmday, $gmon, $gyear, $gwday);
  local($ltzmin, $gtzmin, $tzdiff, $tzstring, $fmtstring);
  local($languagepref); 

  # returns a nicely formatted date string based on the current time
  # localtime and gmtime return something like "Sun May  7 16:27:07 2000"
  # what we really want is something like "Sun, 07 May 2000 16:27:07 -0600"
  #
  # Note: the curious reader may be wondering why I didn't just use 
  # something like POSIX::strftime to build a date string.  well, that is 
  # a good question...  of course if would be easier to just require the
  # appropriate module and 'plug and play', but then, I don't want to rely
  # on the availability of such libraries, since if they don't exist on 
  # some system somewhere out there, I'll probably get an e-mail that says
  # something like "why doesn't your stupid piece of sh-t software work? 
  # damnit!".  It has happened before... so I'll (hopefully) sidestep the
  # issue by keeping everything self-contained.
  #
  # now back to our regularly scheduled programming
  #

  $mytime = $epoch || $g_curtime;
  ($lsec,$lmin,$lhour,$lmday,$lmon,$lyear,
                      $lwday,$yday,$isdst) = localtime($mytime);
  $ltzmin = $lhour * 60 + $lmin;
  ($gsec,$gmin,$ghour,$gmday,$gmon,$gyear,$gwday) = gmtime($mytime);
  $gtzmin = $ghour * 60 + $gmin;

  # need to add or substract 60 * 24 from gtzmin?
  if ($lmday != $gmday) {
    if ($lmon == $gmon) {
      $gtzmin += (($gmday - $lmday) * 60 * 24);
    }
    elsif ($lmday == 1) {
      # gmday must be on the last day of previous month
      $gtzmin -= (60 * 24);
    }
    elsif ($gmday == 1) {
      # lmday must be on the last day of previous month
      $gtzmin += (60 * 24);
    }
  }

  $tzdiff = $ltzmin - $gtzmin;
  $tzstring = ($tzdiff < 0) ? "-" : "+";
  $tzdiff *= -1 if ($tzdiff < 0); 
  $tzstring .= sprintf "%02d", ($tzdiff / 60);
  $tzstring .= sprintf "%02d", ($tzdiff % 60);

  if ($tztype eq "alpha") {
    $languagepref = encodingGetLanguagePreference();
    if ($languagepref eq "en") {
      # map the numeric time zone to an alpha specification for some
      # very common time zones (only applicable for english language)
      if (($tzstring eq "-0400") && $isdst) {
        $tzstring = "EDT";
      }
      elsif ($tzstring eq "-0500") {
        $tzstring = ($isdst) ? "CDT" : "EST";
      }
      elsif ($tzstring eq "-0600") {
        $tzstring = ($isdst) ? "MDT" : "CST";
      }
      elsif ($tzstring eq "-0700") {
        $tzstring = ($isdst) ? "PDT" : "MST";
      }
      elsif (($tzstring eq "-0800") && !$isdst) {
        $tzstring = "PST";
      }
      elsif ($tzstring eq "+0000") {
        $tzstring = "GMT";
      }
    }
    $fmtstring = "%s, %s %02d %d, %02d:%02d:%02d %s";
  }
  else {
    # numeric (for e-mail 'Date' header) 
    $fmtstring = "%s, %02d %s %d %02d:%02d:%02d %s";
  }

  # construct the string and return
  $lyear += 1900;
  $lmon = $g_months[$lmon];
  $lwday = $g_weekdays[$lwday];
  
  if ($tztype eq "alpha") {
    $datestring = sprintf "$fmtstring", $lwday, $lmon, $lmday, $lyear, 
                          $lhour, $lmin, $lsec, $tzstring;
  }
  else {
    $datestring = sprintf "$fmtstring", $lwday, $lmday, $lmon, $lyear, 
                          $lhour, $lmin, $lsec, $tzstring;
  }

  return($datestring);
}

##############################################################################

sub dateLocalizeTimeString
{
  local($datestring) = @_;
  local($languagepref); 

  # include the date library
  encodingIncludeStringLibrary("date");

  # reformat the date string parts to be a little happier for locale
  $languagepref = encodingGetLanguagePreference();
  if ($languagepref eq "ja") {
    if ($datestring =~ /([A-Za-z]+?),\s+(\d+?)\s+([A-Za-z]+?)\s+(\d{4}?),?\s+(\d{2}?):(\d{2}?):(\d{2}?)\s+(.*)/) {
      # in --> www, dd MMM yyyy hh:mm:ss timezone
      # out -> yyyy MMM dd (www) hh:mm:ss timezone
      $datestring = "$4年$3月$2日 ($1) $5:$6:$7 $8";
    }
    elsif ($datestring =~ /([A-Za-z]+?),\s+([A-Za-z]+?)\s+(\d+?)\s+(\d{4}?),?\s+(\d{2}?):(\d{2}?):(\d{2}?)(.*)/) {
      # in --> www, MMM dd yyyy hh:mm:ss timezone
      # out -> yyyy MMM dd (www) hh:mm:ss timezone
      $datestring = "$4年$2月$3日 ($1) $5:$6:$7 $8";
    }
    elsif ($datestring =~ /([A-Za-z]+?)\s+([A-Za-z]+?)\s+(\d+?)\s+(\d{2}?):(\d{2}?):(\d{2}?)\s+(\d{4}?)/) {
      # in --> www MMM dd hh:mm:ss yyyy
      # out -> yyyy MMM dd (www) hh:mm:ss
      $datestring = "$7年$2月$3日 ($1) $4:$5:$6";
    }
    elsif ($datestring =~ /(\d+?)\s+([A-Za-z]+?)\s+(\d{4}?)\s+(\d{2}?):(\d{2}?):(\d{2}?)(.*)/) {
      # in --> dd MMM yyyy hh:mm:ss timezone
      # out -> yyyy MMM dd hh:mm:ss timezone
      $datestring = "$3年$2月$1日 $4:$5:$6 $7";
    }
    elsif ($datestring =~ /([A-Za-z]+?)\s+([A-Za-z]+?)\s+(\d+?)\s+(\d{2}?):(\d{2}?):(\d{2}?)\s+(\d{4}?)/) {
      # in --> www MMM dd hh:mm:ss yyyy
      # out -> yyyy MMM dd (www) hh:mm:ss
      $datestring = "$7年$2月$3日 ($1) $4:$5:$6";
    }
    elsif ($datestring =~ /([A-Za-z]+?)\s+(\d+?)\s+(\d{2}?):(\d{2}?):(\d{2}?)/) {
      # in --> MMM dd hh:mm:ss
      # out -> MMM dd hh:mm:ss
      $datestring = "$1月$2日 $3:$4:$5";
    }
    elsif ($datestring =~ /([A-Za-z]+?)\s+(\d+?)\s+(\d{4}?)/) {
      # in --> MMM dd yyyy
      # out -> yyyy MMM dd
      $datestring = "$3年$1月$2日";
    }
    $datestring =~ s/\s+/ /g;
    $datestring =~ s/Jan/0$MONTHS_JAN/i;
    $datestring =~ s/Feb/0$MONTHS_FEB/i;
    $datestring =~ s/Mar/0$MONTHS_MAR/i;
    $datestring =~ s/Apr/0$MONTHS_APR/i;
    $datestring =~ s/May/0$MONTHS_MAY/i;
    $datestring =~ s/Jun/0$MONTHS_JUN/i;
    $datestring =~ s/Jul/0$MONTHS_JUL/i;
    $datestring =~ s/Aug/0$MONTHS_AUG/i;
    $datestring =~ s/Sep/0$MONTHS_SEP/i;
  }
  else {
    $datestring =~ s/Jan/$MONTHS_JAN/i;
    $datestring =~ s/Feb/$MONTHS_FEB/i;
    $datestring =~ s/Mar/$MONTHS_MAR/i;
    $datestring =~ s/Apr/$MONTHS_APR/i;
    $datestring =~ s/May/$MONTHS_MAY/i;
    $datestring =~ s/Jun/$MONTHS_JUN/i;
    $datestring =~ s/Jul/$MONTHS_JUL/i;
    $datestring =~ s/Aug/$MONTHS_AUG/i;
    $datestring =~ s/Sep/$MONTHS_SEP/i;
  }
  $datestring =~ s/Oct/$MONTHS_OCT/i;
  $datestring =~ s/Nov/$MONTHS_NOV/i;
  $datestring =~ s/Dec/$MONTHS_DEC/i;

  $datestring =~ s/Mon/$WEEKDAYS_MON/i;
  $datestring =~ s/Tue/$WEEKDAYS_TUE/i;
  $datestring =~ s/Wed/$WEEKDAYS_WED/i;
  $datestring =~ s/Thu/$WEEKDAYS_THU/i;
  $datestring =~ s/Fri/$WEEKDAYS_FRI/i;
  $datestring =~ s/Sat/$WEEKDAYS_SAT/i;
  $datestring =~ s/Sun/$WEEKDAYS_SUN/i;

  return($datestring);
}

##############################################################################
# eof

1;

