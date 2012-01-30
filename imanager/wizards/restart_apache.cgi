#!/usr/local/bin/sperl5.6.1 -U
#
# restart_apache.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/restart_apache.cgi,v 2.12.2.2 2006/04/25 19:48:30 rus Exp $
#
# restart apache wizard
#

%g_form = ();

require '../library/init.pl';
initEnvironment();

require '../library/iroot.pl';
irootInit();

require '../library/apache.pl';
if ($g_form{'confirm'}) {
  apacheRestart();
}
else {
  apacheRestartConfirm();
}

##############################################################################
# eof

