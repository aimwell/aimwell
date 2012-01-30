#!/usr/local/bin/sperl5.6.1 -U
#
# prefs.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/prefs.cgi,v 2.12.2.3 2006/04/25 19:48:30 rus Exp $
#
# change user preferences wizard
#

%g_form = ();

require '../library/init.pl';
initEnvironment();

require '../library/prefs.pl';
if (!$g_form{'preftype'}) {
  prefsSelectMenu();
}
elsif (!$g_form{'submit'}) {
  prefsSelectForm();
}
else {
  prefsSave();
  prefsRedirect();
}

##############################################################################
# eof

