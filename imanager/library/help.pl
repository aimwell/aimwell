#
# help.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/help.pl,v 2.12.2.1 2006/04/25 19:48:23 rus Exp $
#
# display help topic
#

##############################################################################

sub helpDisplayTopic
{
  # parse any form data
  require "$g_includelib/form.pl";
  formParseData();

  # include common libraries
  require "$g_includelib/html.pl";
  require "$g_includelib/label.pl";
  require "$g_includelib/encoding.pl";

  encodingIncludeStringLibrary("main");

  # load backroom preferences
  require "$g_includelib/prefs.pl";
  prefsLoad();

  # set default content type for output
  encodingSetDefaultContentType();

  htmlResponseHeader("Content-type: $g_default_content_type");

  # get selected help topic information
  if ($g_form{'s'} eq "cookie") {
    encodingIncludeStringLibrary("auth");
    labelCustomHeader($AUTH_SETCOOKIE, "help");
    htmlH3($AUTH_SETCOOKIE);
    htmlP();
    htmlText($AUTH_SETCOOKIE_HELP_TEXT);
    htmlP();
  }
  elsif ($g_form{'s'} eq "wrap") {
    encodingIncludeStringLibrary("filemanager");
    labelCustomHeader($FILEMANAGER_ACTIONS_EDIT_WRAP_HELP_TITLE, "help");
    htmlH3($FILEMANAGER_ACTIONS_EDIT_WRAP_HELP_TITLE);
    htmlP();
    htmlText($FILEMANAGER_ACTIONS_EDIT_WRAP_HELP_TEXT);
    htmlP();
    htmlText($FILEMANAGER_ACTIONS_EDIT_WRAP_HELP_TEXT_SOFT);
    htmlP();
    htmlText($FILEMANAGER_ACTIONS_EDIT_WRAP_HELP_TEXT_HARD);
    htmlP();
  }
  elsif ($g_form{'s'} =~ /^flags_/) {
    encodingIncludeStringLibrary("mailmanager");
    labelCustomHeader($MAILMANAGER_FLAGS_TITLE, "help");
    htmlH3($MAILMANAGER_FLAGS_TITLE);
    htmlP();
    htmlText($MAILMANAGER_FLAGS_HELP_TEXT);
    htmlPre();
    htmlTextCode("$MAILMANAGER_FLAGS_HELP_N\n");
    htmlTextCode("$MAILMANAGER_FLAGS_HELP_r\n");
    htmlTextCode("\n");
    htmlTextCode("$MAILMANAGER_FLAGS_HELP_PLUS\n");
    htmlTextCode("$MAILMANAGER_FLAGS_HELP_T\n");
    htmlTextCode("$MAILMANAGER_FLAGS_HELP_C\n");
    htmlTextCode("$MAILMANAGER_FLAGS_HELP_F\n");
    htmlPreClose();
    htmlP();
  }
  else {
    labelCustomHeader("???", "help");
    htmlH3("???");
  }

  labelCustomFooter("help");
  exit(0);
}

##############################################################################
# eof

1;

