#!/usr/local/bin/sperl5.6.1 -U
#
# vhosts_template.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/vhosts_template.cgi,v 2.12.2.2 2006/04/25 19:48:30 rus Exp $
#
# edit vhosts template wizard
#

%g_form = ();

require '../library/init.pl';
initEnvironment();

require '../library/iroot.pl';
irootInit();

require '../library/vhosts.pl';
if ($g_form{'submit'}) {
  vhostsTemplateSave();
}
else {
  vhostsTemplateEditForm();
}

##############################################################################
# eof

