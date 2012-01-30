#!/usr/local/bin/sperl5.6.1 -U
#
# aliases_add.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/aliases_add.cgi,v 2.12.2.2 2006/04/25 19:48:29 rus Exp $
#
# add aliases wizard
#

%g_form = ();

require '../library/init.pl';
initEnvironment();

require '../library/iroot.pl';
irootInit();

require '../library/aliases.pl';
aliasesLoad();
if ($g_form{'submit'}) {
  aliasesCheckFormValidity("add");
  aliasesCommitChanges("add");
}
else {
  aliasesDisplayForm("add");
}

##############################################################################
# eof

