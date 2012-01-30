#!/usr/local/bin/sperl5.6.1 -U
#
# mailmanager.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/mailmanager.cgi,v 2.12.2.2 2006/04/25 19:48:30 rus Exp $
#
# mail manager wizard
#

%g_form = ();

require '../library/init.pl';
initEnvironment();

require '../library/mm_util.pl';
mailmanagerInit();

require '../library/mm_browse.pl';
if ($g_form{'submit'}) {
  # delete selected or move selected
  mailmanagerHandleActionOnSelectedRequest();
}
elsif ($g_form{'messageid'}) {
  mailmanagerShowMessage();
}
else {
  mailmanagerShowMailbox();
}

##############################################################################
# eof

