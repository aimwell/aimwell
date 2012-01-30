#!/usr/local/bin/sperl5.6.1 -U
#
# virtmaps_remove.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/virtmaps_remove.cgi,v 2.12.2.2 2006/04/25 19:48:30 rus Exp $
#
# remove virtmaps wizard
#

%g_form = ();

require '../library/init.pl';
initEnvironment();

require '../library/iroot.pl';
irootInit();

require '../library/virtmaps.pl';
virtmapsLoad();
if ($g_form{'submit'}) {
  virtmapsCheckFormValidity("remove");
  virtmapsCommitChanges("remove");
}
else {
  virtmapsDisplayForm("remove");
}

##############################################################################
# eof

