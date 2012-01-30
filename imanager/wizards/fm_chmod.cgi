#!/usr/local/bin/sperl5.6.1 -U
#
# fm_chmod.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/fm_chmod.cgi,v 2.12.2.2 2006/04/25 19:48:29 rus Exp $
#
# chmod file wizard
#

%g_form = ();

require '../library/init.pl';
initEnvironment();

require '../library/fm_util.pl';
require '../library/fm_chmod.pl';
filemanagerInit();
if ($g_form{'submit'}) {
  filemanagerCheckChmodTarget();
  filemanagerChangeTargetPermissions();
}
else {
  filemanagerChmodForm();
}

##############################################################################
# eof

