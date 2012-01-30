#!/usr/local/bin/sperl5.6.1 -U
#
# aliases_rebuild.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/aliases_rebuild.cgi,v 2.12.2.1 2006/04/25 19:48:29 rus Exp $
#
# vnewaliases tool
#

require '../library/init.pl';
initEnvironment();

require '../library/iroot.pl';
irootInit();

require '../library/aliases.pl';
aliasesRebuild();

##############################################################################
# eof

