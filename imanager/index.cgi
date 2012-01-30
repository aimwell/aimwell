#!/usr/local/bin/sperl5.6.1 -U
#
# index.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/index.cgi,v 2.12.2.1 2006/04/25 19:48:22 rus Exp $
#
# virtual server administration suite main menu
#

require './library/init.pl';
initEnvironment();

require './library/imanager.pl';
imanagerMainMenu();

##############################################################################
# eof

