#!/usr/local/bin/sperl5.6.1 -U
#
# groups_edit.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/groups_edit.cgi,v 2.12.2.2 2006/04/25 19:48:29 rus Exp $
#
# edit groups wizard
#

%g_form = ();

require '../library/init.pl';
initEnvironment();

require '../library/iroot.pl';
irootInit();

require '../library/groups.pl';
if ($g_form{'submit'}) {
  groupsCheckFormValidity("edit");
  groupsCommitChanges("edit");
}
else {
  groupsDisplayForm("edit");
}

##############################################################################
# eof

