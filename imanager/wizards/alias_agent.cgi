#!/usr/local/bin/sperl5.6.1 -U
#
# alias_agent.cgi
# Copyright (c) 1996-2000 SurfUtah.Com
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/alias_agent.cgi,v 2.12 2004/08/27 18:27:53 rus Exp $
#
# alias agent
#

require '../library/init.pl';
initEnvironment();

require '../library/iroot.pl';
irootInit();

require '../library/aliases.pl';
aliasesLoad();
if ($g_form{'submit'} eq "") {
  aliasesDisplayForm("add");
}
else {
  aliasesCheckFormValidity("add");
  aliasesCommitChanges("add");
}

##############################################################################
# eof

