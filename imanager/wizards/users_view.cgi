#!/usr/local/bin/sperl5.6.1 -U
#
# users_view.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/users_view.cgi,v 2.12.2.1 2006/04/25 19:48:30 rus Exp $
#
# view users wizard
#

require '../library/init.pl';
initEnvironment();

require '../library/iroot.pl';
irootInit();

require '../library/users.pl';
usersDisplayForm("view");

##############################################################################
# eof

