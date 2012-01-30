#
# prefs.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/prefs.pl,v 2.12.2.10 2006/04/25 19:48:25 rus Exp $
#
# user preferences functions
#

##############################################################################

sub prefsCheck
{
  # general prefs
  if (($g_prefs{'general__startup_menu'} ne "main") && 
      ($g_prefs{'general__startup_menu'} ne "profile") &&
      ($g_prefs{'general__startup_menu'} ne "filemanager") &&
      ($g_prefs{'general__startup_menu'} ne "mailmanager") &&
      ($g_prefs{'general__startup_menu'} ne "iroot")) {
    $g_prefs{'general__startup_menu'} = "main";
  }
  $g_prefs{'general__auth_duration'} =~ s/[^0-9]//g;
  $g_prefs{'general__auth_duration'} =~ s/^0+//;
  if (!$g_prefs{'general__auth_duration'}) {
    $g_prefs{'general__auth_duration'} = 20;
  }

  # language prefs
  if ($g_prefs{'general__language'}) {
    if (($g_prefs{'general__language'} ne "en") && 
        (!(-e "$g_stringlib/$g_prefs{'general__language'}/"))) {
      $g_prefs{'general__language'} = "default";
    }
  }

  # filemanager prefs
  if (($g_prefs{'ftp__hide_entries_that_begin_with_a_dot'} ne "yes") && 
      ($g_prefs{'ftp__hide_entries_that_begin_with_a_dot'} ne "no")) {
    $g_prefs{'ftp__hide_entries_that_begin_with_a_dot'} = "yes";
  }
  if (($g_prefs{'ftp__confirm_file_remove'} ne "yes") && 
      ($g_prefs{'ftp__confirm_file_remove'} ne "no")) {
    $g_prefs{'ftp__confirm_file_remove'} = "yes";
  }
  if (($g_prefs{'ftp__confirm_file_overwrite'} ne "yes") && 
      ($g_prefs{'ftp__confirm_file_overwrite'} ne "no")) {
    $g_prefs{'ftp__confirm_file_overwrite'} = "yes";
  }
  if (($g_prefs{'ftp__confirm_dir_create'} ne "yes") && 
      ($g_prefs{'ftp__confirm_dir_create'} ne "no")) {
    $g_prefs{'ftp__confirm_dir_create'} = "yes";
  }
  if (($g_prefs{'ftp__chmod_options'} ne "basic") && 
      ($g_prefs{'ftp__chmod_options'} ne "advanced")) {
    $g_prefs{'ftp__chmod_options'} = "basic";
  }
  $g_prefs{'ftp__upload_file_elements'} =~ s/[^0-9]//g;
  if (!$g_prefs{'ftp__upload_file_elements'}) {
    $g_prefs{'ftp__upload_file_elements'} = 4;
  }

  # mailmanager prefs
  $g_prefs{'mail__num_messages'} =~ s/[^0-9]//g;
  $g_prefs{'mail__num_messages'} =~ s/^0+//;
  if (!$g_prefs{'mail__num_messages'}) {
    $g_prefs{'mail__num_messages'} = 25;
  }
  $g_prefs{'mail__inbox_refresh_rate'} =~ s/[^0-9]//g;
  if ((!defined($g_prefs{'mail__inbox_refresh_rate'})) || 
      (($g_prefs{'mail__inbox_refresh_rate'} != 0) &&
       ($g_prefs{'mail__inbox_refresh_rate'} < 15))) {
    $g_prefs{'mail__inbox_refresh_rate'} = 180;
  }
  if (($g_prefs{'mail__sort_option'} ne "by_date") &&
      ($g_prefs{'mail__sort_option'} ne "by_size") &&
      ($g_prefs{'mail__sort_option'} ne "by_sender") &&
      ($g_prefs{'mail__sort_option'} ne "by_subject") &&
      ($g_prefs{'mail__sort_option'} ne "by_thread") &&
      ($g_prefs{'mail__sort_option'} ne "in_order")) {
    $g_prefs{'mail__sort_option'} = "by_date";
  }
  if (($g_prefs{'mail__confirm_message_remove'} ne "yes") && 
      ($g_prefs{'mail__confirm_message_remove'} ne "no")) {
    $g_prefs{'mail__confirm_message_remove'} = "yes";
  }
  $g_prefs{'mail__upload_attach_elements'} =~ s/[^0-9]//g;
  if (!defined($g_prefs{'mail__upload_attach_elements'})) {
    # 0 is ok
    $g_prefs{'mail__upload_attach_elements'} = 2;
  }
  $g_prefs{'mail__local_attach_elements'} =~ s/[^0-9]//g;
  if (!defined($g_prefs{'mail__local_attach_elements'})) {
    # 0 is ok
    $g_prefs{'mail__local_attach_elements'} = 2;
  }
  if (($g_prefs{'mail__address_book_confirm_changes'} ne "yes") && 
      ($g_prefs{'mail__address_book_confirm_changes'} ne "no")) {
    $g_prefs{'mail__address_book_confirm_changes'} = "yes";
  }
  $g_prefs{'mail__address_book_elements'} =~ s/[^0-9]//g;
  if (!$g_prefs{'mail__address_book_elements'}) {
    $g_prefs{'mail__address_book_elements'} = 8;
  }

  # iroot prefs
  $g_prefs{'iroot__num_newusers'} =~ s/[^0-9]//g;
  if (!$g_prefs{'iroot__num_newusers'}) {
    $g_prefs{'iroot__num_newusers'} = 1;
  }
  $g_prefs{'iroot__num_newgroups'} =~ s/[^0-9]//g;
  if (!$g_prefs{'iroot__num_newgroups'}) {
    $g_prefs{'iroot__num_newgroups'} = 1;
  }
  $g_prefs{'iroot__num_newaliases'} =~ s/[^0-9]//g;
  if (!$g_prefs{'iroot__num_newaliases'}) {
    $g_prefs{'iroot__num_newaliases'} = 3;
  }
  $g_prefs{'iroot__num_newvirtmaps'} =~ s/[^0-9]//g;
  if (!$g_prefs{'iroot__num_newvirtmaps'}) {
    $g_prefs{'iroot__num_newvirtmaps'} = 5;
  }
  $g_prefs{'iroot__num_newspammers'} =~ s/[^0-9]//g;
  if (!$g_prefs{'iroot__num_newspammers'}) {
    $g_prefs{'iroot__num_newspammers'} = 5;
  }
  $g_prefs{'iroot__num_newmailaccess'} =~ s/[^0-9]//g;
  if (!$g_prefs{'iroot__num_newmailaccess'}) {
    $g_prefs{'iroot__num_newmailaccess'} = 5;
  }
  $g_prefs{'iroot__num_newvhosts'} =~ s/[^0-9]//g;
  if (!$g_prefs{'iroot__num_newvhosts'}) {
    $g_prefs{'iroot__num_newvhosts'} = 1;
  }

  # security prefs
  if (($g_prefs{'security__force_ssl_connection'} ne "yes") && 
      ($g_prefs{'security__force_ssl_connection'} ne "no")) {
    $g_prefs{'security__force_ssl_connection'} = "no";
  }
  if (($g_prefs{'security__require_hostname_authentication'} ne "yes") && 
      ($g_prefs{'security__require_hostname_authentication'} ne "no")) {
    $g_prefs{'security__require_hostname_authentication'} = "yes";
  }
  if (($g_prefs{'security__enforce_strict_password_rules'} ne "yes") && 
      ($g_prefs{'security__enforce_strict_password_rules'} ne "no")) {
    $g_prefs{'security__enforce_strict_password_rules'} = "yes";
  }
  if (($g_platform_type eq "dedicated") &&
      ($g_auth{'login'} ne "root") &&
      (($g_auth{'login'} =~ /^_.*root$/) ||
       ($g_auth{'login'} eq $g_users{'__rootid'}) ||
       (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}})))) {
    if (($g_prefs{'security__allow_root_login'} ne "yes") && 
        ($g_prefs{'security__allow_root_login'} ne "no")) {
      $g_prefs{'security__allow_root_login'} = "yes";
    }
    if (($g_prefs{'security__elevate_admin_ftp_privs'} ne "yes") && 
        ($g_prefs{'security__elevate_admin_ftp_privs'} ne "no")) {
      $g_prefs{'security__elevate_admin_ftp_privs'} = "no";
    }
  }
}

##############################################################################

sub prefsLoad
{
  local($defaultsfile, $userfile, $name, $value);

  $defaultsfile = "$g_prefslib/_default";
  if ($g_auth{'login'}) {
    if ($g_platform_type eq "virtual") {
      if (($g_auth{'login'} eq "root") ||
          ($g_auth{'login'} =~ /^_.*root$/) ||
          ($g_auth{'login'} eq $g_users{'__rootid'})) {
        $userfile = "$g_prefslib/root";
      }
      else {
        $userfile = "$g_prefslib/$g_auth{'login'}";
      }
    }
    else {
      # dedicated env... prefs are stored in user subdirectory
      if (($g_auth{'login'} eq "root") ||
          ($g_auth{'login'} =~ /^_.*root$/) ||
          ($g_auth{'login'} eq $g_users{'__rootid'})) {
        $userfile = "/root/.imanager/user_prefs";
      }
      else {
        $userfile = "$g_userprefsdir/user_prefs";
      }
    }
  }

  # first load the defaults (this guarantees new prefs are always present)
  if (open(FP, "$defaultsfile")) {
    while (<FP>) {
      next if ($_ =~ /^#/);
      next if ($_ !~ /:/);
      s/^\s+//g;
      s/\s+$//g;
      ($name, $value) = split(/\:/);
      $g_prefs{$name} = $value;
    }
    close(FP);
  }

  # then load with user preferences, overriding defaults
  if ($userfile && (open(FP, "$userfile"))) {
    while (<FP>) {
      next if ($_ =~ /^#/);
      next if ($_ !~ /:/);
      s/^\s+//g;
      s/\s+$//g;
      ($name, $value) = split(/\:/);
      $g_prefs{$name} = $value;
      # rewrite poorly chosen defaults from the past
      if (($name eq "mail__default_folder") && ($value eq "/Mail")) {
        $g_prefs{$name} = "~/Mail";
      }
    }
    close(FP);
  }

  # reset the security options
  prefsLoadGlobalSecurityOptions();

  # check prefs validity (resets invalid entries to default values)
  prefsCheck();
}

##############################################################################

sub prefsLoadGlobalSecurityOptions
{
  local($defaultsfile, $rootfile, $name, $value);

  $defaultsfile = "$g_prefslib/_default";

  if ($g_platform_type eq "virtual") {
    $rootfile = "$g_prefslib/root";
  }
  else {
    $rootfile = "/root/.imanager/user_prefs";
  }

  # first load the defaults (guarantees security prefs are always present)
  if (open(FP, "$defaultsfile")) {
    while (<FP>) {
      next if ($_ =~ /^#/);
      next if ($_ !~ /:/);
      s/^\s+//g;
      s/\s+$//g;
      ($name, $value) = split(/\:/);
      next unless ($name =~ /^security__/);
      $g_prefs{$name} = $value;
    }
    close(FP);
  }

  # then load with root preferences, overriding defaults
  open(FP, "$rootfile") || return;
  while (<FP>) {
    next if ($_ =~ /^#/);
    next if ($_ !~ /:/);
    s/^\s+//g;
    s/\s+$//g;
    ($name, $value) = split(/\:/);
    next unless ($name =~ /^security__/);
    $g_prefs{$name} = $value;
  }
  close(FP);
}

##############################################################################

sub prefsRedirect
{
  # redirect back to main menu
  encodingIncludeStringLibrary("prefs");
  $g_form{'preftype'} = "";
  redirectLocation("prefs.cgi", $PREFS_SUCCESS_TEXT);
}

##############################################################################

sub prefsSave
{
  local($key, $userfile, $rootfile, $pref);
  local($oldlanguagepref, $newlanguagepref);

  # set some vars
  $oldlanguagepref = $g_prefs{'general__language'};
  $newlanguagepref = $g_form{'general__language'} || $oldlanguagepref;

  # first parse g_form and store selections in g_prefs  
  foreach $key (%g_form) {
    $g_prefs{$key} = $g_form{$key} if (defined($g_prefs{$key}));
  }

  # check prefs validity (resets invalid entries to default values)
  prefsCheck();

  if ($g_platform_type eq "virtual") {
    if (($g_auth{'login'} eq "root") ||
        ($g_auth{'login'} =~ /^_.*root$/) ||
        ($g_auth{'login'} eq $g_users{'__rootid'})) {
      $userfile = "$g_prefslib/root";
    }
    else {
      $userfile = "$g_prefslib/$g_auth{'login'}";
    }
  }
  else {
    # dedicated env... prefs are stored in user subdirectory
    if (($g_auth{'login'} eq "root") ||
        ($g_auth{'login'} =~ /^_.*root$/) ||
        ($g_auth{'login'} eq $g_users{'__rootid'})) {
      $userfile = "/root/.imanager/user_prefs";
    }
    else {
      $userfile = "$g_userprefsdir/user_prefs";
    }
  }

  open(FP, ">$userfile") || return;
  print FP "#\n";
  print FP "# user preferences for $g_auth{'login'}\n";
  print FP "#\n";
  foreach $pref (sort(keys(%g_prefs))) { 
    next if (($pref =~ /^ftp__/) && (!($g_users{$g_auth{'login'}}->{'ftp'})));
    next if (($pref =~ /^mail__/) && 
             (!($g_users{$g_auth{'login'}}->{'mail'})));
    next if (($pref =~ /^iroot__/) && 
             (!(($g_auth{'login'} eq "root") || 
                ($g_auth{'login'} =~ /^_.*root$/) || 
                ($g_auth{'login'} eq $g_users{'__rootid'}) || 
                (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}})))));
    next if ($pref =~ /^security__/);  # save these later 
    print FP "$pref:$g_prefs{$pref}\n";
  }
  close(FP);

  prefsSaveGlobalSecurityOptions();

  # some of the scoring rules for spamassassin are language dependent;
  # need to update those rules based on the language preference if the
  # language preference has changed
  if ($newlanguagepref ne $oldlanguagepref) {
    require "$g_includelib/mm_util.pl";
    require "$g_includelib/mm_filters.pl";
    mailmanagerFiltersUpdateChineseJapaneseKoreanCharsetRules();
  }
}

##############################################################################

sub prefsSaveGlobalSecurityOptions
{
  local($rootfile);

  return unless (($g_auth{'login'} eq "root") || 
                 ($g_auth{'login'} =~ /^_.*root$/) || 
                 ($g_auth{'login'} eq $g_users{'__rootid'}) || 
                 (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}})));

  if ($g_platform_type eq "virtual") {
    $rootfile = "$g_prefslib/root";
    open(SFP, "$rootfile") || return;
    open(TFP, "+<$rootfile");
    while (<SFP>) {
      $curline = $_;
      if ($curline =~/^security__/) {
        $curline =~ s/^\s+//g;
        $curline =~ s/\s+$//g;
        ($name, $value) = split(/\:/);
        $curline = "$name:$g_prefs{$name}\n";
        delete($g_prefs{$name});  # remove it from the hash
      }
      print TFP "$curline";
    }
    # write out the security prefs which were not replaced above
    foreach $name (keys(%g_prefs)) {
      next unless ($name =~ /^security__/);
      print TFP "$name:$g_prefs{$name}\n";
    }
    # close the file handles and truncate
    close(SFP);
    $curpos = tell(TFP);
    truncate(TFP, $curpos);
    close(TFP);
  }
  else {
    $rootfile = "/root/.imanager/user_prefs";
    REWT: {
      local $> = 0;
      mkdir("/root/.imanager", 0750) unless (-e "/root/.imanager");
      if (-e "$rootfile") {
        open(SFP, "$rootfile");
        open(TFP, "+<$rootfile");
      }
      else {
        open(TFP, ">$rootfile");
      }
      while (<SFP>) {
        $curline = $_;
        if ($curline =~/^security__/) {
          $curline =~ s/^\s+//g;
          $curline =~ s/\s+$//g;
          ($name, $value) = split(/\:/);
          $curline = "$name:$g_prefs{$name}\n";
          delete($g_prefs{$name});  # remove it from the hash
        }
        print TFP "$curline";
      }
      # write out the security prefs which were not replaced above
      foreach $name (keys(%g_prefs)) {
        next unless ($name =~ /^security__/);
        print TFP "$name:$g_prefs{$name}\n";
      }
      # close the file handles and truncate
      close(SFP);
      $curpos = tell(TFP);
      truncate(TFP, $curpos);
      close(TFP);
    }
  }
}

##############################################################################

sub prefsSelectForm
{
  local($value, $loginstr);

  encodingIncludeStringLibrary("prefs");

  $loginstr = $g_auth{'email'} || $g_auth{'login'};
  $loginstr = "VROOT" if ($loginstr =~ /^_.*root$/);

  htmlResponseHeader("Content-type: $g_default_content_type");
  $PREFS_TITLE =~ s/__USER_ID__/$loginstr/;
  $PREFS_EXPLANATION =~ s/__USER_ID__/$loginstr/;
  labelCustomHeader($PREFS_TITLE);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlUL();  
  formOpen("method", "POST");
  authPrintHiddenFields();
  if ($g_form{'preftype'} eq "general") {
    # general preferences
    formInput("type", "hidden", "name", "preftype", "value", "general");
    htmlTextLargeBold($PREFS_GENERAL_TEXT);
    htmlP();
    # general preference: start up menu
    $value = $g_prefs{'general__startup_menu'};
    htmlTextBold($PREFS_STARTUP_MENU_TEXT);
    htmlBR();
    htmlText($PREFS_STARTUP_MENU_HELP);
    htmlBR();
    formInput("type", "radio", "name", "general__startup_menu",
              "value", "main", "_OTHER_", 
              ($value eq "main") ? "CHECKED" : "");
    htmlText($MAINMENU_TITLE);
    htmlBR();
    formInput("type", "radio", "name", "general__startup_menu",
              "value", "profile", "_OTHER_", 
              ($value eq "profile") ? "CHECKED" : "");
    htmlText($MAINMENU_USERPROFILE_TITLE);
    htmlBR();
    if ($g_users{$g_auth{'login'}}->{'ftp'}) {
      formInput("type", "radio", "name", "general__startup_menu",
                "value", "filemanager", "_OTHER_", 
                ($value eq "filemanager") ? "CHECKED" : "");
      htmlText($MAINMENU_FILEMANAGER_TITLE);
      htmlBR();
    }
    if ($g_users{$g_auth{'login'}}->{'mail'}) {
      formInput("type", "radio", "name", "general__startup_menu",
                "value", "mailmanager", "_OTHER_", 
                ($value eq "mailmanager") ? "CHECKED" : "");
      htmlText($MAINMENU_MAILMANAGER_TITLE);
      htmlBR();
    }
    if (($g_auth{'login'} eq "root") || 
        ($g_auth{'login'} =~ /^_.*root$/) || 
        ($g_auth{'login'} eq $g_users{'__rootid'}) ||
        (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}}))) {
      formInput("type", "radio", "name", "general__startup_menu",
                "value", "iroot", "_OTHER_", 
                ($value eq "iroot") ? "CHECKED" : "");
      htmlText($MAINMENU_IROOT_TITLE);
      htmlBR();
    }
    htmlP();
    # general preference: authorization duration
    htmlTextBold($PREFS_AUTH_DURATION_TEXT);
    htmlBR();
    htmlText($PREFS_AUTH_DURATION_HELP);
    htmlBR();
    formInput("size", "5", "name", "general__auth_duration", 
              "value", $g_prefs{'general__auth_duration'});
    htmlText($PREFS_AUTH_DURATION_UNITS);
    htmlP();
    formInput("type", "submit", "name", "submit", "value", $SUBMIT_STRING);
    formInput("type", "reset", "value", $RESET_STRING);
  }
  elsif ($g_form{'preftype'} eq "language") {
    # language preferences
    formInput("type", "hidden", "name", "preftype", "value", "general");
    htmlTextLargeBold($PREFS_LANGUAGE_TEXT);
    htmlP();
    # general preference: start up menu
    $value = encodingGetLanguagePreference();
    htmlTextBold($PREFS_DEFAULT_LANGUAGE_TEXT);
    htmlBR();
    htmlText($PREFS_DEFAULT_LANGUAGE_HELP);
    htmlBR();
    if ((-e "$g_stringlib/da/main") &&
        (((stat("$g_stringlib/da/MAINTAINER"))[7]) > 0)) {
      formInput("type", "radio", "name", "general__language",
                "value", "da", "_OTHER_", ($value eq "da") ? "CHECKED" : "");
      htmlText($PREFS_DEFAULT_LANGUAGE_DA);
      htmlBR();
    }
    if ((-e "$g_stringlib/de/main") &&
        (((stat("$g_stringlib/de/MAINTAINER"))[7]) > 0)) {
      formInput("type", "radio", "name", "general__language",
                "value", "de", "_OTHER_", ($value eq "de") ? "CHECKED" : "");
      htmlText($PREFS_DEFAULT_LANGUAGE_DE);
      htmlBR();
    }
    if ((-e "$g_stringlib/en/main") &&
        (((stat("$g_stringlib/en/MAINTAINER"))[7]) > 0)) {
      formInput("type", "radio", "name", "general__language",
                "value", "en", "_OTHER_", ($value eq "en") ? "CHECKED" : "");
      htmlText($PREFS_DEFAULT_LANGUAGE_EN);
      htmlBR();
    }
    if ((-e "$g_stringlib/es/main") &&
        (((stat("$g_stringlib/es/MAINTAINER"))[7]) > 0)) {
      formInput("type", "radio", "name", "general__language",
                "value", "es", "_OTHER_", ($value eq "es") ? "CHECKED" : "");
      htmlText($PREFS_DEFAULT_LANGUAGE_ES);
      htmlBR();
    }
    if ((-e "$g_stringlib/fr/main") &&
        (((stat("$g_stringlib/fr/MAINTAINER"))[7]) > 0)) {
      formInput("type", "radio", "name", "general__language",
                "value", "fr", "_OTHER_", ($value eq "fr") ? "CHECKED" : "");
      htmlText($PREFS_DEFAULT_LANGUAGE_FR);
      htmlBR();
    }
    if ((-e "$g_stringlib/it/main") &&
        (((stat("$g_stringlib/it/MAINTAINER"))[7]) > 0)) {
      formInput("type", "radio", "name", "general__language",
                "value", "it", "_OTHER_", ($value eq "it") ? "CHECKED" : "");
      htmlText($PREFS_DEFAULT_LANGUAGE_IT);
      htmlBR();
    }
    if ((-e "$g_stringlib/ja/main") &&
        (((stat("$g_stringlib/ja/MAINTAINER"))[7]) > 0)) {
      formInput("type", "radio", "name", "general__language",
                "value", "ja", "_OTHER_", ($value eq "ja") ? "CHECKED" : "");
      htmlText($PREFS_DEFAULT_LANGUAGE_JA);
      htmlBR();
    }
    if ((-e "$g_stringlib/nl/main") &&
        (((stat("$g_stringlib/nl/MAINTAINER"))[7]) > 0)) {
      formInput("type", "radio", "name", "general__language",
                "value", "nl", "_OTHER_", ($value eq "nl") ? "CHECKED" : "");
      htmlText($PREFS_DEFAULT_LANGUAGE_NL);
      htmlBR();
    }
    if ((-e "$g_stringlib/pt/main") &&
        (((stat("$g_stringlib/pt/MAINTAINER"))[7]) > 0)) {
      formInput("type", "radio", "name", "general__language",
                "value", "pt", "_OTHER_", ($value eq "pt") ? "CHECKED" : "");
      htmlText($PREFS_DEFAULT_LANGUAGE_PT);
      htmlBR();
    }
    if ((-e "$g_stringlib/pt-br/main") &&
        (((stat("$g_stringlib/pt-br/MAINTAINER"))[7]) > 0)) {
      formInput("type", "radio", "name", "general__language", "value", 
                "pt-br", "_OTHER_", ($value eq "pt-br") ? "CHECKED" : "");
      htmlText($PREFS_DEFAULT_LANGUAGE_PTBR);
      htmlBR();
    }
    if ((-e "$g_stringlib/se/main") &&
        (((stat("$g_stringlib/se/MAINTAINER"))[7]) > 0)) {
      formInput("type", "radio", "name", "general__language",
                "value", "se", "_OTHER_", ($value eq "se") ? "CHECKED" : "");
      htmlText($PREFS_DEFAULT_LANGUAGE_SE);
      htmlBR();
    }
    htmlP();
    formInput("type", "submit", "name", "submit", "value", $SUBMIT_STRING);
    formInput("type", "reset", "value", $RESET_STRING);
  }
  elsif ($g_form{'preftype'} eq "filemanager") {
    if ($g_users{$g_auth{'login'}}->{'ftp'}) {
      # file manager preferences
      formInput("type", "hidden", "name", "preftype", "value", "filemanager");
      encodingIncludeStringLibrary("filemanager");
      htmlTextLargeBold("$PREFS_FILEMANAGER_TEXT");
      htmlP();
      # file manager preference: hide entries that begin with a dot
      $value = $g_prefs{'ftp__hide_entries_that_begin_with_a_dot'};
      htmlTextBold($PREFS_HIDE_ENTRIES_THAT_BEGIN_WITH_A_DOT_TEXT);
      htmlBR(); 
      htmlText($PREFS_HIDE_ENTRIES_THAT_BEGIN_WITH_A_DOT_HELP);
      htmlBR();
      formInput("type", "radio", "name", 
                "ftp__hide_entries_that_begin_with_a_dot",
                "value", "yes", "_OTHER_", ($value eq "yes") ? "CHECKED" : "");
      htmlText($YES_STRING);
      htmlBR();
      formInput("type", "radio", "name", 
                "ftp__hide_entries_that_begin_with_a_dot",
                "value", "no", "_OTHER_", ($value eq "no") ? "CHECKED" : "");
      htmlText($NO_STRING);
      htmlP();
      # file manager preference: confirm file remove
      $value = $g_prefs{'ftp__confirm_file_remove'};
      htmlTextBold($PREFS_CONFIRM_FILE_REMOVE_TEXT);
      htmlBR(); 
      htmlText($PREFS_CONFIRM_FILE_REMOVE_HELP);
      htmlBR();
      formInput("type", "radio", "name", "ftp__confirm_file_remove",
                "value", "yes", "_OTHER_", ($value eq "yes") ? "CHECKED" : "");
      htmlText($YES_STRING);
      htmlBR();
      formInput("type", "radio", "name", "ftp__confirm_file_remove",
                "value", "no", "_OTHER_", ($value eq "no") ? "CHECKED" : "");
      htmlText($NO_STRING);
      htmlP();
      # file manager preference: confirm file overwrite
      $value = $g_prefs{'ftp__confirm_file_overwrite'};
      htmlTextBold($PREFS_CONFIRM_FILE_OVERWRITE_TEXT);
      htmlBR(); 
      htmlText($PREFS_CONFIRM_FILE_OVERWRITE_HELP);
      htmlBR();
      formInput("type", "radio", "name", "ftp__confirm_file_overwrite",
                "value", "yes", "_OTHER_", ($value eq "yes") ? "CHECKED" : "");
      htmlText($YES_STRING);
      htmlBR();
      formInput("type", "radio", "name", "ftp__confirm_file_overwrite",
                "value", "no", "_OTHER_", ($value eq "no") ? "CHECKED" : "");
      htmlText($NO_STRING);
      htmlP();
      # file manager preference: confirm directory creation
      $value = $g_prefs{'ftp__confirm_dir_create'};
      htmlTextBold($PREFS_CONFIRM_DIR_CREATE_TEXT);
      htmlBR(); 
      htmlText($PREFS_CONFIRM_DIR_CREATE_HELP);
      htmlBR();
      formInput("type", "radio", "name", "ftp__confirm_dir_create",
                "value", "yes", "_OTHER_", ($value eq "yes") ? "CHECKED" : "");
      htmlText($YES_STRING);
      htmlBR();
      formInput("type", "radio", "name", "ftp__confirm_dir_create",
                "value", "no", "_OTHER_", ($value eq "no") ? "CHECKED" : "");
      htmlText($NO_STRING);
      htmlP();
      # file manager preference: advanced or basic chmod options by default
      $value = $g_prefs{'ftp__chmod_options'};
      htmlTextBold($PREFS_CHMOD_DEFAULT_OPTION_TEXT);
      htmlBR();
      htmlText($PREFS_CHMOD_DEFAULT_OPTION_HELP);
      htmlBR();
      formInput("type", "radio", "name", "ftp__chmod_options",
                "value", "basic", "_OTHER_", 
                ($value eq "basic") ? "CHECKED" : "");
      htmlText($FILEMANAGER_ACTIONS_CHMOD_BASIC_OPTS);
      htmlBR();
      formInput("type", "radio", "name", "ftp__chmod_options",
                "value", "advanced", "_OTHER_", 
                ($value eq "advanced") ? "CHECKED" : "");
      htmlText($FILEMANAGER_ACTIONS_CHMOD_ADVANCED_OPTS);
      htmlP();
      # file manager preference: number of upload file elements 
      htmlTextBold($PREFS_UPLOAD_FILE_ELEMENTS_TEXT);
      htmlBR();
      htmlText($PREFS_UPLOAD_FILE_ELEMENTS_HELP);
      htmlBR();
      formInput("size", "5", "name", "ftp__upload_file_elements", 
                "value", $g_prefs{'ftp__upload_file_elements'});
      htmlText($PREFS_UPLOAD_FILE_ELEMENTS_UNITS);
      htmlP();
      formInput("type", "submit", "name", "submit", "value", $SUBMIT_STRING);
      formInput("type", "reset", "value", $RESET_STRING);
    }
    else {
      htmlText($PREFS_FILEMANAGER_DENIED_TEXT);
      htmlP();
    }
  }
  elsif ($g_form{'preftype'} eq "mailmanager") {
    if ($g_users{$g_auth{'login'}}->{'mail'}) {
      # mail manager preferences
      formInput("type", "hidden", "name", "preftype", "value", "mailmanager");
      htmlTextLargeBold("$PREFS_MAILMANAGER_TEXT");
      htmlP();
      # mail manager preference: number of messages to view at once
      htmlTextBold($PREFS_NUM_MESSAGES_TEXT);
      htmlBR();
      htmlText($PREFS_NUM_MESSAGES_HELP);
      htmlBR();
      formInput("size", "5", "name", "mail__num_messages", 
                "value", $g_prefs{'mail__num_messages'});
      htmlText($PREFS_NUM_MESSAGES_UNITS);
      htmlP();
      # mail manager preference: number of messages to view at once
      htmlTextBold($PREFS_INBOX_REFRESH_RATE_TEXT);
      htmlBR();
      htmlText($PREFS_INBOX_REFRESH_RATE_HELP);
      htmlBR();
      formInput("size", "5", "name", "mail__inbox_refresh_rate", 
                "value", $g_prefs{'mail__inbox_refresh_rate'});
      htmlText($PREFS_INBOX_REFRESH_RATE_UNITS);
      htmlP();
      # mail manager preference: default mail sorting option
      encodingIncludeStringLibrary("mailmanager");
      $value = $g_prefs{'mail__sort_option'};
      htmlTextBold($PREFS_DEFAULT_MAIL_SORTING_TEXT);
      htmlBR(); 
      htmlText($PREFS_DEFAULT_MAIL_SORTING_HELP);
      htmlBR();
      formInput("type", "radio", "name", "mail__sort_option",
                "value", "by_date", 
                "_OTHER_", ($value eq "by_date") ? "CHECKED" : "");
      htmlText($MAILMANAGER_SORT_BY_DATE);
      htmlBR();
      formInput("type", "radio", "name", "mail__sort_option",
                "value", "by_sender", 
                "_OTHER_", ($value eq "by_sender") ? "CHECKED" : "");
      htmlText($MAILMANAGER_SORT_BY_SENDER);
      htmlBR();
      formInput("type", "radio", "name", "mail__sort_option",
                "value", "by_subject", 
                "_OTHER_", ($value eq "by_subject") ? "CHECKED" : "");
      htmlText($MAILMANAGER_SORT_BY_SUBJECT);
      htmlBR();
      formInput("type", "radio", "name", "mail__sort_option",
                "value", "by_size", 
                "_OTHER_", ($value eq "by_size") ? "CHECKED" : "");
      htmlText($MAILMANAGER_SORT_BY_SIZE);
      htmlBR();
      formInput("type", "radio", "name", "mail__sort_option",
                "value", "by_thread", 
                "_OTHER_", ($value eq "by_thread") ? "CHECKED" : "");
      htmlText($MAILMANAGER_SORT_BY_THREAD);
      htmlBR();
      formInput("type", "radio", "name", "mail__sort_option",
                "value", "in_order", 
                "_OTHER_", ($value eq "in_order") ? "CHECKED" : "");
      htmlText($MAILMANAGER_SORT_IN_ORDER);
      htmlBR();
      htmlP();
      # mail manager preference: confirm message remove
      $value = $g_prefs{'mail__confirm_message_remove'};
      htmlTextBold($PREFS_CONFIRM_MAIL_REMOVE_TEXT);
      htmlBR(); 
      htmlText($PREFS_CONFIRM_MAIL_REMOVE_HELP);
      htmlBR();
      formInput("type", "radio", "name", "mail__confirm_message_remove",
                "value", "yes", "_OTHER_", ($value eq "yes") ? "CHECKED" : "");
      htmlText($YES_STRING);
      htmlBR();
      formInput("type", "radio", "name", "mail__confirm_message_remove",
                "value", "no", "_OTHER_", ($value eq "no") ? "CHECKED" : "");
      htmlText($NO_STRING);
      htmlP();
      if ($g_users{$g_auth{'login'}}->{'ftp'}) {
        # mail manager preference: default mail folder
        htmlTextBold($PREFS_DEFAULT_MAIL_FOLDER_TEXT);
        htmlBR();
        htmlText($PREFS_DEFAULT_MAIL_FOLDER_HELP);
        htmlBR();
        formInput("size", "30", "name", "mail__default_folder", 
                  "value", $g_prefs{'mail__default_folder'});
        htmlP();
      }
      # mail manager preference: number of mail attach elements 
      htmlTextBold($PREFS_MAIL_ATTACH_ELEMENTS_TEXT);
      htmlBR();
      if ($g_users{$g_auth{'login'}}->{'ftp'}) {
        htmlText($PREFS_MAIL_ATTACH_ELEMENTS_HELP_FULL_PRIVS);
      }
      else {
        htmlText($PREFS_MAIL_ATTACH_ELEMENTS_HELP_NO_FTP_PRIVS);
      }
      htmlBR();
      formInput("size", "5", "name", "mail__upload_attach_elements", 
                "value", $g_prefs{'mail__upload_attach_elements'});
      htmlText($PREFS_UPLOAD_ATTACH_ELEMENTS_UNITS);
      if ($g_users{$g_auth{'login'}}->{'ftp'}) {
        htmlBR();
        formInput("size", "5", "name", "mail__local_attach_elements", 
                  "value", $g_prefs{'mail__local_attach_elements'});
        htmlText($PREFS_LOCAL_ATTACH_ELEMENTS_UNITS);
      }
      htmlP();
      # mail manager preference: confirm address book changes
      $value = $g_prefs{'mail__address_book_confirm_changes'};
      htmlTextBold($PREFS_CONFIRM_ADDRESS_BOOK_CHANGES_TEXT);
      htmlBR(); 
      htmlText($PREFS_CONFIRM_ADDRESS_BOOK_CHANGES_HELP);
      htmlBR();
      formInput("type", "radio", "name", "mail__address_book_confirm_changes",
                "value", "yes", "_OTHER_", ($value eq "yes") ? "CHECKED" : "");
      htmlText($YES_STRING);
      htmlBR();
      formInput("type", "radio", "name", "mail__address_book_confirm_changes",
                "value", "no", "_OTHER_", ($value eq "no") ? "CHECKED" : "");
      htmlText($NO_STRING);
      htmlP();
      # mail manager preference: number of address book elements 
      htmlTextBold($PREFS_MAIL_ADDRESSBOOK_ELEMENTS_TEXT);
      htmlBR();
      htmlText($PREFS_MAIL_ADDRESSBOOK_ELEMENTS_HELP);
      htmlBR();
      formInput("size", "5", "name", "mail__address_book_elements", 
                "value", $g_prefs{'mail__address_book_elements'});
      htmlText($PREFS_MAIL_ADDRESSBOOK_ELEMENTS_UNITS);
      htmlP();
      formInput("type", "submit", "name", "submit", "value", $SUBMIT_STRING);
      formInput("type", "reset", "value", $RESET_STRING);
    }
    else {
      htmlText($PREFS_MAILMANAGER_DENIED_TEXT);
      htmlP();
    }
  }
  elsif ($g_form{'preftype'} eq "iroot") {
    if (($g_auth{'login'} eq "root") ||
        ($g_auth{'login'} =~ /^_.*root$/) ||
        ($g_auth{'login'} eq $g_users{'__rootid'}) ||
        (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}}))) {
      # iroot preferences
      formInput("type", "hidden", "name", "preftype", "value", "iroot");
      htmlTextLargeBold("$PREFS_IROOT_TEXT");
      htmlP();
      # iroot preference: number of new users added at one time
      htmlTextBold($PREFS_NUM_NEWUSERS_TEXT);
      htmlBR();
      htmlText($PREFS_NUM_NEWUSERS_HELP);
      htmlBR();
      formInput("size", "5", "name", "iroot__num_newusers", 
                "value", $g_prefs{'iroot__num_newusers'});
      htmlText($PREFS_NUM_NEWUSERS_UNITS);
      htmlP();
      if ($g_platform_type eq "dedicated") {
        # iroot preference: number of new groups added at one time
        htmlTextBold($PREFS_NUM_NEWGROUPS_TEXT);
        htmlBR();
        htmlText($PREFS_NUM_NEWGROUPS_HELP);
        htmlBR();
        formInput("size", "5", "name", "iroot__num_newgroups", 
                  "value", $g_prefs{'iroot__num_newgroups'});
        htmlText($PREFS_NUM_NEWGROUPS_UNITS);
        htmlP();
      }
      # iroot preference: number of new aliases added at one time
      htmlTextBold($PREFS_NUM_NEWALIASES_TEXT);
      htmlBR();
      htmlText($PREFS_NUM_NEWALIASES_HELP);
      htmlBR();
      formInput("size", "5", "name", "iroot__num_newaliases", 
                "value", $g_prefs{'iroot__num_newaliases'});
      htmlText($PREFS_NUM_NEWALIASES_UNITS);
      htmlP();
      # iroot preference: number of new virtmaps added at one time
      htmlTextBold($PREFS_NUM_NEWVIRTMAPS_TEXT);
      htmlBR();
      htmlText($PREFS_NUM_NEWVIRTMAPS_HELP);
      htmlBR();
      formInput("size", "5", "name", "iroot__num_newvirtmaps", 
                "value", $g_prefs{'iroot__num_newvirtmaps'});
      htmlText($PREFS_NUM_NEWVIRTMAPS_UNITS);
      htmlP();
      if ($g_platform_type eq "virtual") {
        # iroot preference: number of new spammers added at one time
        htmlTextBold($PREFS_NUM_NEWSPAMMERS_TEXT);
        htmlBR();
        htmlText($PREFS_NUM_NEWSPAMMERS_HELP);
        htmlBR();
        formInput("size", "5", "name", "iroot__num_newspammers", 
                  "value", $g_prefs{'iroot__num_newspammers'});
        htmlText($PREFS_NUM_NEWSPAMMERS_UNITS);
        htmlP();
      }
      else {
        # iroot preference: number of new mail access entries that can 
        #                   added at one time
        htmlTextBold($PREFS_NUM_NEWMAILACCESS_TEXT);
        htmlBR();
        htmlText($PREFS_NUM_NEWMAILACCESS_HELP);
        htmlBR();
        formInput("size", "5", "name", "iroot__num_newmailaccess", 
                  "value", $g_prefs{'iroot__num_newmailaccess'});
        htmlText($PREFS_NUM_NEWMAILACCESS_UNITS);
        htmlP();
      }
      # iroot preference: number of new spammers added at one time
      htmlTextBold($PREFS_NUM_NEWVHOSTS_TEXT);
      htmlBR();
      htmlText($PREFS_NUM_NEWVHOSTS_HELP);
      htmlBR();
      formInput("size", "5", "name", "iroot__num_newvhosts", 
                "value", $g_prefs{'iroot__num_newvhosts'});
      htmlText($PREFS_NUM_NEWVHOSTS_UNITS);
      htmlP();
      formInput("type", "submit", "name", "submit", "value", $SUBMIT_STRING);
      formInput("type", "reset", "value", $RESET_STRING);
    }
    else {
      htmlText($PREFS_IROOT_DENIED_TEXT);
      htmlP();
    }
  }
  elsif ($g_form{'preftype'} eq "security") {
    if (($g_auth{'login'} eq "root") ||
        ($g_auth{'login'} =~ /^_.*root$/) ||
        ($g_auth{'login'} eq $g_users{'__rootid'}) ||
        (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}}))) {
      # security preferences
      formInput("type", "hidden", "name", "preftype", "value", "security");
      htmlTextLargeBold("$PREFS_SECURITY_TEXT");
      htmlP();
      # security preference: force SSL connections
      $value = $g_prefs{'security__force_ssl_connection'};
      htmlTextBold($PREFS_SECURITY_FORCE_HTTPS_TEXT);
      htmlBR(); 
      htmlText($PREFS_SECURITY_FORCE_HTTPS_HELP);
      htmlBR();
      formInput("type", "radio", "name", "security__force_ssl_connection",
                "value", "yes", "_OTHER_", ($value eq "yes") ? "CHECKED" : "");
      htmlText($PREFS_SECURITY_FORCE_HTTPS_YES);
      htmlBR();
      formInput("type", "radio", "name", "security__force_ssl_connection",
                "value", "no", "_OTHER_", ($value eq "no") ? "CHECKED" : "");
      htmlText($PREFS_SECURITY_FORCE_HTTPS_NO);
      htmlP();
      # security preference: require hostname authentication (IP checking)
      $value = $g_prefs{'security__require_hostname_authentication'};
      htmlTextBold($PREFS_SECURITY_IP_CHECK_TEXT);
      htmlBR(); 
      htmlText($PREFS_SECURITY_IP_CHECK_HELP);
      htmlBR();
      formInput("type", "radio", "name", 
                "security__require_hostname_authentication",
                "value", "yes", "_OTHER_", ($value eq "yes") ? "CHECKED" : "");
      htmlText($PREFS_SECURITY_IP_CHECK_YES);
      htmlBR();
      formInput("type", "radio", "name",
                "security__require_hostname_authentication",
                "value", "no", "_OTHER_", ($value eq "no") ? "CHECKED" : "");
      htmlText($PREFS_SECURITY_IP_CHECK_NO);
      htmlP();
      # security preference: enforce 'strict' password selection rules
      $value = $g_prefs{'security__enforce_strict_password_rules'};
      htmlTextBold($PREFS_SECURITY_STRICT_PASSWORD_TEXT);
      htmlBR(); 
      htmlText($PREFS_SECURITY_STRICT_PASSWORD_HELP);
      htmlBR();
      formInput("type", "radio", "name", 
                "security__enforce_strict_password_rules",
                "value", "yes", "_OTHER_", ($value eq "yes") ? "CHECKED" : "");
      htmlText($PREFS_SECURITY_STRICT_PASSWORD_YES);
      htmlBR();
      formInput("type", "radio", "name",
                "security__enforce_strict_password_rules",
                "value", "no", "_OTHER_", ($value eq "no") ? "CHECKED" : "");
      htmlText($PREFS_SECURITY_STRICT_PASSWORD_NO);
      if (($g_platform_type eq "dedicated") &&
          ($g_auth{'login'} ne "root") &&
          (($g_auth{'login'} =~ /^_.*root$/) ||
           ($g_auth{'login'} eq $g_users{'__rootid'}) ||
           (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}})))) {
        htmlP();
        # security preference: allow root login
        $value = $g_prefs{'security__allow_root_login'};
        htmlTextBold($PREFS_SECURITY_ROOT_LOGIN_TEXT);
        htmlBR(); 
        htmlText($PREFS_SECURITY_ROOT_LOGIN_HELP);
        htmlBR();
        formInput("type", "radio", "name", 
                  "security__allow_root_login",
                  "value", "yes", "_OTHER_", ($value eq "yes") ? "CHECKED" : "");
        htmlText($PREFS_SECURITY_ROOT_LOGIN_YES);
        htmlBR();
        formInput("type", "radio", "name",
                  "security__allow_root_login",
                  "value", "no", "_OTHER_", ($value eq "no") ? "CHECKED" : "");
        htmlText($PREFS_SECURITY_ROOT_LOGIN_NO);
      }
      if (($g_platform_type eq "dedicated") &&
          (($g_auth{'login'} eq "root") ||
           ($g_auth{'login'} =~ /^_.*root$/))) {
        htmlP();
        # security preference: elevate admin ftp privs
        $value = $g_prefs{'security__elevate_admin_ftp_privs'};
        htmlTextBold($PREFS_SECURITY_ELEVATE_ADMIN_FTP_PRIVS_TEXT);
        htmlBR(); 
        htmlText($PREFS_SECURITY_ELEVATE_ADMIN_FTP_PRIVS_HELP);
        htmlBR();
        formInput("type", "radio", "name", 
                  "security__elevate_admin_ftp_privs",
                  "value", "yes", "_OTHER_", ($value eq "yes") ? "CHECKED" : "");
        htmlText($PREFS_SECURITY_ELEVATE_ADMIN_FTP_PRIVS_YES);
        htmlBR();
        formInput("type", "radio", "name",
                  "security__elevate_admin_ftp_privs",
                  "value", "no", "_OTHER_", ($value eq "no") ? "CHECKED" : "");
        htmlText($PREFS_SECURITY_ELEVATE_ADMIN_FTP_PRIVS_NO);
      }
      htmlP();
      formInput("type", "submit", "name", "submit", "value", $SUBMIT_STRING);
      formInput("type", "reset", "value", $RESET_STRING);
    }
    else {
      htmlText($PREFS_SECURITY_DENIED_TEXT);
      htmlP();
    }
  }
  else {
    $value = $PREFS_UNKNOWN_TEXT;
    $value =~ s/__TYPE__/$g_form{'preftype'}/;
    htmlText($value);
    htmlP();
  }
  formClose();
  htmlULClose();  
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub prefsSelectMenu
{
  local($mesg, $loginstr);

  encodingIncludeStringLibrary("prefs");

  $loginstr = $g_auth{'email'} || $g_auth{'login'};
  $loginstr = "VROOT" if ($loginstr =~ /^_.*root$/);

  htmlResponseHeader("Content-type: $g_default_content_type");
  $PREFS_TITLE =~ s/__USER_ID__/$loginstr/;
  $PREFS_EXPLANATION =~ s/__USER_ID__/$loginstr/;
  labelCustomHeader($PREFS_TITLE);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();

  if ($g_form{'msgfileid'}) {
    $mesg = redirectMessageRead($g_form{'msgfileid'});
  }
  if ($mesg) {
    # read message from temporary state message file
    htmlTextColorBold(">>> $mesg <<<", "#cc0000");
    htmlP();
  }

  htmlText($PREFS_EXPLANATION);
  htmlP();
  htmlUL();  
  htmlTable();
  # general prefences option
  htmlTableRow();
  htmlTableData();
  htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?preftype=general",
             "title", $PREFS_GENERAL_TEXT);
  htmlImg("border", "0", "width", "25", "height", "25", 
          "alt", $PREFS_GENERAL_TEXT,
          "src", "$g_graphicslib/pb.jpg");
  htmlAnchorClose();
  htmlTableDataClose();
  htmlTableData();
  htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?preftype=general", 
             "title", $PREFS_GENERAL_TEXT);
  htmlAnchorTextLargeBold($PREFS_GENERAL_TEXT);
  htmlAnchorClose();
  htmlTableDataClose();
  htmlTableRowClose();
  # language prefences option
  htmlTableRow();
  htmlTableData();
  htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?preftype=language",
             "title", PREFS_LANGUAGE_TEXT);
  htmlImg("border", "0", "width", "25", "height", "25", 
          "alt", $PREFS_LANGUAGE_TEXT,
          "src", "$g_graphicslib/pb.jpg");
  htmlAnchorClose();
  htmlTableDataClose();
  htmlTableData();
  htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?preftype=language",
             "title", $PREFS_LANGUAGE_TEXT);
  htmlAnchorTextLargeBold($PREFS_LANGUAGE_TEXT);
  htmlAnchorClose();
  htmlTableDataClose();
  htmlTableRowClose();
  if ($g_users{$g_auth{'login'}}->{'ftp'}) {
    # file manager preferences option
    htmlTableRow();
    htmlTableData();
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?preftype=filemanager",
               "title", $PREFS_FILEMANAGER_TEXT);
    htmlImg("border", "0", "width", "25", "height", "25", 
            "alt", $PREFS_FILEMANAGER_TEXT,
            "src", "$g_graphicslib/pb.jpg");
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableData();
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?preftype=filemanager",
               "title", $PREFS_FILEMANAGER_TEXT);
    htmlAnchorTextLargeBold($PREFS_FILEMANAGER_TEXT);
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableRowClose();
  }
  if ($g_users{$g_auth{'login'}}->{'mail'}) {
    # mail manager preferences option
    htmlTableRow();
    htmlTableData();
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?preftype=mailmanager",
               "title", $PREFS_MAILMANAGER_TEXT);
    htmlImg("border", "0", "width", "25", "height", "25", 
            "alt", $PREFS_MAILMANAGER_TEXT,
            "src", "$g_graphicslib/pb.jpg");
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableData();
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?preftype=mailmanager",
               "title", $PREFS_MAILMANAGER_TEXT);
    htmlAnchorTextLargeBold($PREFS_MAILMANAGER_TEXT);
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableRowClose();
  }
  if (($g_auth{'login'} eq "root") ||
      ($g_auth{'login'} =~ /^_.*root$/) ||
      ($g_auth{'login'} eq $g_users{'__rootid'}) ||
      (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}}))) {
    # iroot preferences option
    htmlTableRow();
    htmlTableData();
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?preftype=iroot",
               "title", $PREFS_IROOT_TEXT);
    htmlImg("border", "0", "width", "25", "height", "25", 
            "alt", $PREFS_IROOT_TEXT,
            "src", "$g_graphicslib/pb.jpg");
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableData();
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?preftype=iroot",
               "title", $PREFS_IROOT_TEXT);
    htmlAnchorTextLargeBold($PREFS_IROOT_TEXT);
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableRowClose();
    # security preferences
    htmlTableRow();
    htmlTableData();
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?preftype=security",
               "title", $PREFS_SECURITY_TEXT);
    htmlImg("border", "0", "width", "25", "height", "25", 
            "alt", $PREFS_SECURITY_TEXT,
            "src", "$g_graphicslib/pb.jpg");
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableData();
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?preftype=security",
               "title", $PREFS_SECURITY_TEXT);
    htmlAnchorTextLargeBold($PREFS_SECURITY_TEXT);
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableRowClose();
  }
  htmlTableClose();
  htmlBR();
  formOpen("method", "POST", "action", "../index.cgi");
  authPrintHiddenFields();
  formInput("type", "submit", "name", "submit", "value", $MAINMENU_TITLE);
  formClose();
  htmlULClose();  
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################
# eof

1;

