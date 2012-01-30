#!/usr/local/bin/sperl5.6.1 -U
#
# aliases_remove.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/aliases_remove.cgi,v 2.12.2.2 2006/04/25 19:48:29 rus Exp $
#
# remove aliases wizard
#

%g_form = ();

require '../library/init.pl';
initEnvironment();

require '../library/iroot.pl';
irootInit();

require '../library/aliases.pl';
aliasesLoad();
if ($g_form{'submit'}) {
  aliasesCheckFormValidity("remove");
  aliasesCommitChanges("remove");
}
else {
  aliasesDisplayForm("remove");
}

##############################################################################
# eof

