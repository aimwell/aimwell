#
# timezone.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/timezone.pl,v 2.12.2.1 2006/04/25 19:48:25 rus Exp $
#

# need external POSIX library... hopefully it is installed
require POSIX;

##############################################################################

sub timezoneSet
{
  local($timzeone) = @_;

  $ENV{'TZ'} = $timezone;
  POSIX::tzset();
}

##############################################################################
# eof
  
1;

