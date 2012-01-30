#!/usr/local/bin/sperl5.6.1 -U
#
# fm_remove.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/fm_remove.cgi,v 2.12.2.2 2006/04/25 19:48:29 rus Exp $
#
# remove file wizard
#

%g_form = ();
%g_prefs = ();

require '../library/init.pl';
initEnvironment();

require '../library/fm_util.pl';
require '../library/fm_remove.pl';
filemanagerInit();
if ($g_prefs{'ftp__confirm_file_remove'} eq "yes") {
  unless ($g_form{'confirm'} && ($g_form{'confirm'} eq "yes")) {
    filemanagerRemoveFileConfirmForm();
  }
}
filemanagerCheckRemoveFileTarget();
filemanagerRemoveTarget();

##############################################################################
# eof

