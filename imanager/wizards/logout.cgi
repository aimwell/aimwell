#!/usr/local/bin/sperl5.6.1 -U
#
# logout.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/logout.cgi,v 2.12.2.1 2006/04/25 19:48:30 rus Exp $
#
# logout script
#

require '../library/auth.pl';
authCookieExpire();

require '../library/init.pl';
initEnvironment();

##############################################################################
# eof

