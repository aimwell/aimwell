#!/usr/local/bin/sperl5.6.1 -U
#
# fm_view.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/fm_view.cgi,v 2.12.2.1 2006/04/25 19:48:29 rus Exp $
#
# view a specified file
#

require '../library/init.pl';
initEnvironment();

require '../library/fm_util.pl';
require '../library/fm_view.pl';
filemanagerInit();
filemanagerViewFile();

##############################################################################
# eof

