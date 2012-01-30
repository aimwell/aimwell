#!/usr/local/bin/sperl5.6.1 -U
#
# filemanager.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/filemanager.cgi,v 2.12.2.2 2006/04/25 19:48:29 rus Exp $
#
# file manager wizard
#

%g_form = ();

require '../library/init.pl';
initEnvironment();

require '../library/fm_util.pl';
filemanagerInit();

require '../library/fm_browse.pl';
if ($g_form{'submit'}) {
  # copy, move, or delete selected
  filemanagerHandleActionOnSelectedRequest();
}
else {
  filemanagerBrowseSpecifiedPath();
}

##############################################################################
# eof

