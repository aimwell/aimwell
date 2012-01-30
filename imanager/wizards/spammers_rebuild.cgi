#!/usr/local/bin/sperl5.6.1 -U
#
# spammers_rebuild.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/spammers_rebuild.cgi,v 2.12.2.1 2006/04/25 19:48:30 rus Exp $
#
# vnewspammers tool
#

require '../library/init.pl';
initEnvironment();

require '../library/iroot.pl';
irootInit();

require '../library/spammers.pl';
spammersRebuild();

##############################################################################
# eof

