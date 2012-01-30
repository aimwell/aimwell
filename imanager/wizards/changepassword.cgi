#!/usr/local/bin/sperl5.6.1 -U
#
# changepassword.cgi
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/wizards/changepassword.cgi,v 2.12.2.2 2006/04/25 19:48:29 rus Exp $
#
# change login password wizard
#

%g_auth = %g_form = ();

require '../library/init.pl';
initEnvironment();

require '../library/profile.pl';
if ($g_form{'submit'}) {
  profileCheckNewPassword();
  profileChangePassword($g_auth{'login'}, $g_form{'newpasswd'});
}
else {
  profileChangePasswordForm();
}

##############################################################################
# eof

