#!/usr/local/bin/sperl5.6.1 -U
#
# users_add.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/users_add.cgi,v 2.12.2.2 2006/04/25 19:48:30 rus Exp $
#
# add users wizard
#

%g_form = ();

require '../library/init.pl';
initEnvironment();

require '../library/iroot.pl';
irootInit();

require '../library/users.pl';
if ($g_form{'submit'}) {
  usersCheckFormValidity("add");
  usersCommitChanges("add");
}
else {
  usersDisplayForm("add");
}

##############################################################################
# eof

