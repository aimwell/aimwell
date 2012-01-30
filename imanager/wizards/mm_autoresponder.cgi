#!/usr/local/bin/sperl5.6.1 -U
#
# mm_autoresponder.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/mm_autoresponder.cgi,v 2.12.2.1 2006/04/25 19:48:30 rus Exp $
#
# mail autoresponder wizard
#

require '../library/init.pl';
initEnvironment();

require '../library/mm_util.pl';
mailmanagerInit();

require '../library/mm_autoresponder.pl';
mailmanagerAutoresponderHandleRequest();

##############################################################################
# eof

