#!/usr/local/bin/sperl5.6.1 -U
#
# mailaccess_rebuild.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/mailaccess_rebuild.cgi,v 2.12.2.1 2006/04/25 19:48:30 rus Exp $
#
# vnewmailaccess tool
#

require '../library/init.pl';
initEnvironment();

require '../library/iroot.pl';
irootInit();

require '../library/mailaccess.pl';
mailaccessRebuild();

##############################################################################
# eof

