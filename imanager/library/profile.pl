#
# profile.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/profile.pl,v 2.12.2.8 2006/04/25 19:48:25 rus Exp $
#
# user profile functions
#

##############################################################################

sub profileChangePassword
{
  local($login, $passwd) = @_;
  local($cryptedpasswd);

  $cryptedpasswd = authCryptPassword($passwd);
  passwdSaveNewPassword($login, $cryptedpasswd);
  $g_auth{'password'} = $passwd;
  $g_auth{'KEY'} = "";
  authStateSet();
  encodingIncludeStringLibrary("profile");
  redirectLocation("profile.cgi", $PROFILE_CHPASS_SUCCESS);
}

##############################################################################

sub profileChangePasswordForm
{
  local($errmsg) = @_;
  local($isize, $loginstr, $errmsgtxt, $helptext);

  $isize = formInputSize(20);

  encodingIncludeStringLibrary("profile");
  encodingIncludeStringLibrary("users");

  $loginstr = $g_auth{'email'} || $g_auth{'login'};
  $loginstr = "VROOT" if ($loginstr =~ /^_.*root$/);

  htmlResponseHeader("Content-type: $g_default_content_type");
  $PROFILE_CHPASS_TITLE =~ s/__USER_ID__/$loginstr/;
  $PROFILE_CHPASS_TEXT =~ s/__USER_ID__/$loginstr/;
  labelCustomHeader($PROFILE_CHPASS_TITLE); 

  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();

  formOpen("method", "POST");
  authPrintHiddenFields();
  htmlText($PROFILE_CHPASS_TEXT);
  htmlP();
  $helptext = $USERS_PASSWORD_BASIC_HELP_TEXT;
  if (authSupportsMD5()) {
    $helptext =~ s/__LEN__/128/;
  }
  else {
    $helptext =~ s/__LEN__/8/;
  }
  htmlText("$helptext ");
  if ($g_prefs{'security__enforce_strict_password_rules'} eq "yes") {
    htmlText("$USERS_PASSWORD_SECURITY_HELP_TEXT ");
  }
  htmlText("$USERS_PASSWORD_CONFIRM_HELP_TEXT ");
  if ($errmsg) {
    htmlP();
    if ($errmsg eq "PASSWORD_MISMATCH") {
      $errmsgtxt = $PROFILE_CHPASS_ERROR;
    }
    elsif ($errmsg eq "INCORRECT_PASSWORD") {
      $errmsgtxt = $PROFILE_INCORRECT_PASSWORD;
    }
    elsif ($errmsg eq "PASSWORD_IS_BLANK") {
      $errmsgtxt = $USERS_ERROR_PASSWORD_IS_BLANK;
    }
    elsif ($errmsg eq "PASSWORD_CONFIRM_IS_BLANK") {
      $errmsgtxt = $USERS_ERROR_PASSWORD_CONFIRM_IS_BLANK;
    }
    elsif ($errmsg eq "PASSWORD_SAME_AS_LOGIN_ID") {
      $errmsgtxt = $USERS_ERROR_PASSWORD_SAME_AS_LOGIN_ID;
    }
    elsif ($errmsg eq "PASSWORD_TOO_SHORT") {
      $errmsgtxt = $USERS_ERROR_PASSWORD_TOO_SHORT;
    }
    elsif ($errmsg eq "PASSWORD_ALL_LETTERS") {
      $errmsgtxt = $USERS_ERROR_PASSWORD_ALL_LETTERS;
    }
    elsif ($errmsg eq "PASSWORD_NO_MIXED_CASE_LETTERS") {
      $errmsgtxt = $USERS_ERROR_PASSWORD_NO_MIXED_CASE_LETTERS;
    }
    htmlTextColorBold(">>> $errmsgtxt <<<", "#cc0000");
  }
  htmlP();
  htmlUL();
  htmlTextBold("$PROFILE_OLDPASS:");
  htmlBR();
  formInput("type", "password", "size", $isize, "name", "oldpasswd",
            "value", "");
  htmlP();
  htmlTextBold("$PROFILE_NEWPASS:");
  htmlBR();
  formInput("type", "password", "size", $isize, "name", "newpasswd",
            "value", $g_form{'newpasswd'});
  htmlP();
  htmlTextBold("$PROFILE_NEWPASS_CONFIRM:");
  htmlBR();
  formInput("type", "password", "size", $isize, "name", "newpasswdconfirm",
            "value", $g_form{'newpasswdconfirm'});
  htmlP();
  formInput("type", "submit", "name", "submit", "value", $SUBMIT_STRING);
  formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  htmlULClose();

  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();

  formClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub profileCheckNewPassword
{
  local($crypted_oldpasswd);

  if ($g_form{'submit'} eq $CANCEL_STRING) {
    encodingIncludeStringLibrary("profile");
    redirectLocation("profile.cgi", $PROFILE_CHPASS_CANCEL);
  }

  if (($g_platform_type eq "virtual") && 
      (($g_auth{'login'} eq "root") || 
       ($g_auth{'login'} =~ /^_.*root$/) || 
       ($g_auth{'login'} eq $g_users{'__rootid'}))) {
    # can't change the primary login password
    htmlResponseHeader("Status: 204 Do Nothing");
    exit(1);
  }
  unless ($g_form{'oldpasswd'}) {
    profileChangePasswordForm("INCORRECT_PASSWORD");
  }
  $crypted_oldpasswd = crypt($g_form{'oldpasswd'}, 
                             $g_users{$g_auth{'login'}}->{'password'});
  if ($crypted_oldpasswd ne $g_users{$g_auth{'login'}}->{'password'}) {
    profileChangePasswordForm("INCORRECT_PASSWORD");
  }
  unless ($g_form{'newpasswd'}) {
    profileChangePasswordForm("PASSWORD_IS_BLANK");
  } 
  unless ($g_form{'newpasswdconfirm'}) {
    profileChangePasswordForm("PASSWORD_CONFIRM_IS_BLANK");
  }
  if ($g_form{'newpasswd'} ne $g_form{'newpasswdconfirm'}) {
    profileChangePasswordForm("PASSWORD_MISMATCH");
  }
  if ($g_form{'newpasswd'} eq $g_auth{'login'}) {
    profileChangePasswordForm("PASSWORD_SAME_AS_LOGIN_ID");
  }
  if ($g_prefs{'security__enforce_strict_password_rules'} eq "yes") {
    if (length($g_form{'newpasswd'}) < 7) {
      profileChangePasswordForm("PASSWORD_TOO_SHORT");
    }
    if ($g_form{'newpasswd'} !~ /[^a-zA-Z]/) {
      profileChangePasswordForm("PASSWORD_ALL_LETTERS");
    }
    if (($g_form{'newpasswd'} !~ /[a-z]/) || 
        ($g_form{'newpasswd'} !~ /[A-Z]/)) {
      profileChangePasswordForm("PASSWORD_NO_MIXED_CASE_LETTERS");
    }
  }
}

##############################################################################

sub profileDisplay
{
  local($mesg) = @_;
  local($used, $percent, $usagestring, $index, $host);
  local($blocks, $avail, $loginstr, $namestr, $homedir);
  local($bfactor, $user, $nua, $nsa, $title, $uid);
  local($shownote, $args, $first, $groupname);

  if (!$mesg && ($g_form{'msgfileid'})) {
    # read message from temporary state message file
    $mesg = redirectMessageRead($g_form{'msgfileid'});
  }

  encodingIncludeStringLibrary("profile");

  $loginstr = $g_auth{'email'} || $g_auth{'login'};
  $loginstr = "VROOT" if ($loginstr =~ /^_.*root$/);
  $namestr = $g_users{$g_auth{'login'}}->{'name'};

  htmlResponseHeader("Content-type: $g_default_content_type");
  $PROFILE_TITLE =~ s/__USER_ID__/$loginstr/;
  $PROFILE_TEXT =~ s/__USER_ID__/$loginstr/;
  if ($g_form{'print_submit'}) {
    htmlHtml();
    htmlTitle($PROFILE_TITLE);
    htmlHeadClose();
    htmlBody("bgcolor", "#ffffff");
  }
  else {
    labelCustomHeader($PROFILE_TITLE); 
  }

  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();

  if ($mesg) {
    htmlTextColorBold(">>> $mesg <<<", "#cc0000");
    htmlP();
  }
  htmlText($PROFILE_TEXT);
  htmlUL();
  htmlTable("border", "0", "cellpadding", "1", "cellspacing", "1");
  htmlTableRow();
  htmlTableData("valign", "middle", "align", "left");
  htmlTextBold("$PROFILE_LOGIN:&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left");
  htmlText($loginstr);
  htmlTableDataClose();
  htmlTableData();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle", "align", "left");
  htmlTextBold("$PROFILE_NAME:&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left");
  htmlText($namestr);
  htmlTableDataClose();
  htmlTableData();
  htmlTableDataClose();
  htmlTableRowClose();
  #
  # user profile information
  #
  if (($g_auth{'login'} eq "root") || 
      ($g_auth{'login'} =~ /^_.*root$/) ||
      ($g_auth{'login'} eq $g_users{'__rootid'})) {
    # spit out root profile info based on platform
    if ($g_platform_type eq "virtual") {
      # not much to do here
    }
    else {
      # change password link; shell
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$PROFILE_PASSWORD:&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextItalic("########");
      htmlTableDataClose();
      htmlTableData();
      unless ($g_form{'print_submit'}) {
        htmlNoBR();
        htmlText("&#160; [ ");
        htmlAnchor("href", "changepassword.cgi", 
                   "title", $PROFILE_PASSWORD_CHANGE);
        htmlAnchorText($PROFILE_PASSWORD_CHANGE);
        htmlAnchorClose();
        htmlText(" ]");
        htmlNoBRClose();
      }
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("colspan", "2");
      htmlTextSmall("&#160;");
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$PROFILE_SHELL:&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlText($g_users{$g_auth{'login'}}->{'shell'});
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
    }
  }
  else {
    htmlTableRow();
    htmlTableData("valign", "middle", "align", "left");
    htmlTextBold("$PROFILE_PASSWORD:&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "left");
    htmlTextItalic("########");
    htmlTableDataClose();
    htmlTableData();
    htmlText("&#160; [ ");
    htmlAnchor("href", "changepassword.cgi",
               "title", $PROFILE_PASSWORD_CHANGE);
    htmlAnchorText($PROFILE_PASSWORD_CHANGE);
    htmlAnchorClose();
    htmlText(" ]");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData("colspan", "2");
    htmlTextSmall("&#160;");
    htmlTableDataClose();
    htmlTableData();
    htmlTableDataClose();
    htmlTableRowClose();
    if ($g_platform_type eq "virtual") {
      # summary of ftp privileges
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$PROFILE_FTP:&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlText($g_users{$g_auth{'login'}}->{'ftp'} ? 
               $YES_STRING : $NO_STRING);
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
      if ($g_users{$g_auth{'login'}}->{'ftp'}) {
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextBold("$PROFILE_FTPQUOTA:&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        htmlText($g_users{$g_auth{'login'}}->{'ftpquota'} ? 
                 "$g_users{$g_auth{'login'}}->{'ftpquota'} $MEGABYTES" : 
                 $NONE_STRING);
        htmlTableDataClose();
        htmlTableData();
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextBold("$PROFILE_FTPUSAGE:&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        require "$g_includelib/fm_util.pl";
        $homedir = $g_users{$g_auth{'login'}}->{'home'};
        $used = filemanagerGetDiskUtilization($homedir);
        if ($used < 1048576) {
          $used /= 1024;
          $usagestring = sprintf("%1.2f $KILOBYTES", $used);
          $used /= 1024;
        }
        else {
          $used /= 1048576;
          $usagestring = sprintf("%1.2f $MEGABYTES", $used);
        }
        if ($g_users{$g_auth{'login'}}->{'ftpquota'} > 0) {
          $percent = $used / $g_users{$g_auth{'login'}}->{'ftpquota'} * 100;
          $percent = sprintf("%1.2f\%", $percent);
          $usagestring .= " ($percent)";
        }
        htmlText($usagestring);
        htmlTableDataClose();
        htmlTableData();
        htmlTableDataClose();
        htmlTableRowClose();
      }
      htmlTableRow();
      htmlTableData("colspan", "2");
      htmlTextSmall("&#160;");
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
      # summary of mail privileges
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$PROFILE_MAIL:&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlText($g_users{$g_auth{'login'}}->{'mail'} ? 
               $YES_STRING : $NO_STRING);
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
      if ($g_users{$g_auth{'login'}}->{'mail'}) {
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextBold("$PROFILE_MAILQUOTA:&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        htmlText($g_users{$g_auth{'login'}}->{'mailquota'} ? 
                 "$g_users{$g_auth{'login'}}->{'mailquota'} $MEGABYTES" : 
                 $NONE_STRING);
        htmlTableDataClose();
        htmlTableData();
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextBold("$PROFILE_MAILUSAGE:&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        require "$g_includelib/fm_util.pl";
        if (-e "/usr/mail/$g_auth{'login'}") {
          $used = filemanagerGetDiskUtilization("/usr/mail/$g_auth{'login'}");
        }
        elsif (-e "/var/mail/$g_auth{'login'}") {
          $used = filemanagerGetDiskUtilization("/var/mail/$g_auth{'login'}");
        }
        else {
          $used = 0;
        }
        if ($used < 1048576) {
          $used /= 1024;
          $usagestring = sprintf("%1.2f $KILOBYTES", $used);
          $used /= 1024;
        }
        else {
          $used /= 1048576;
          $usagestring = sprintf("%1.2f $MEGABYTES", $used);
        }
        if ($g_users{$g_auth{'login'}}->{'mailquota'} > 0) {
          $percent = $used / $g_users{$g_auth{'login'}}->{'mailquota'} * 100;
          $percent = sprintf("%1.2f\%", $percent);
          $usagestring .= " ($percent)";
        }
        htmlText($usagestring);
        htmlTableDataClose();
        htmlTableData();
        htmlTableDataClose();
        htmlTableRowClose();
      }
    }
    else {
      # summary of user privileges
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$PROFILE_FTP:&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlText($g_users{$g_auth{'login'}}->{'ftp'} ? 
               $YES_STRING : $NO_STRING);
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$PROFILE_MAIL:&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlText($g_users{$g_auth{'login'}}->{'mail'} ? 
               $YES_STRING : $NO_STRING);
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
      #
      # no longer a web group per Kay Johansen
      #
      #htmlTableRow();
      #htmlTableData("valign", "middle", "align", "left");
      #htmlTextBold("$PROFILE_WEB:&#160;");
      #htmlTableDataClose();
      #htmlTableData("valign", "middle", "align", "left");
      #htmlText($g_groups{'web'}->{'m'}->{$g_auth{'login'}} ?
      #         $YES_STRING : $NO_STRING);
      #htmlTableDataClose();
      #htmlTableData();
      #htmlTableDataClose();
      #htmlTableRowClose();
      #
      htmlTableData("colspan", "2");
      htmlTextSmall("&#160;");
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$PROFILE_GROUP_MEMBERSHIP:&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      $groupname = groupGetNameFromID($g_users{$g_auth{'login'}}->{'gid'});
      htmlText($groupname);
      foreach $groupname (sort(keys(%g_groups))) {
        if ($g_groups{$groupname}->{'gid'} == 
            $g_users{$g_auth{'login'}}->{'gid'}) {
          next;
        }
        if (defined($g_groups{$groupname}->{'m'}->{$g_auth{'login'}})) {
          htmlText(",&#160;$groupname");
        }
      }
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("colspan", "2");
      htmlTextSmall("&#160;");
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
      # disk quota and disk usage
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$PROFILE_OVERALLQUOTA:&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlText($g_users{$g_auth{'login'}}->{'quota'} ? 
               "$g_users{$g_auth{'login'}}->{'quota'} $MEGABYTES" : 
               $NONE_STRING);
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$PROFILE_OVERALLUSAGE:&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      $used = quotaGetUsed($g_users{$g_auth{'login'}}->{'uid'});
      $used *= 1024;  # convert to bytes
      if ($used < 1048576) {
        $used /= 1024;
        $usagestring = sprintf("%1.2f $KILOBYTES", $used);
        $used /= 1024;
      }
      else {
        $used /= 1048576;
        $usagestring = sprintf("%1.2f $MEGABYTES", $used);
      }
      if ($g_users{$g_auth{'login'}}->{'quota'}) {
        $percent = $used / $g_users{$g_auth{'login'}}->{'quota'} * 100;
        $percent = sprintf("%1.2f\%", $percent);
        $usagestring .= " ($percent)";
      }
      htmlText($usagestring);
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("colspan", "2");
      htmlTextSmall("&#160;");
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$PROFILE_SHELL:&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlText($g_users{$g_auth{'login'}}->{'shell'});
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
    }
    # summary of virtual hosts
    if ($g_platform_type eq "virtual") {
      require "$g_includelib/vhost_util.pl";
      vhostHashInit();
    }
    else {
      # dedicated environment loads vhosts hash in initSetUID() before a
      # step down in privileges is made
    }
    vhostMapHostnames($g_auth{'login'});
    if (defined($g_users{$g_auth{'login'}}->{'hostnames'})) {
      htmlTableRow();
      htmlTableData("colspan", "2");
      htmlTextSmall("&#160;");
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$PROFILE_VIRTUALHOST:&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      for ($index=0; $index<=$#{$g_users{$g_auth{'login'}}->{'hostnames'}};
           $index++) {
        $host = $g_users{$g_auth{'login'}}->{'hostnames'}[$index];
        $title = $URL_OPEN_STRING;
        $title =~ s/__URL__/http:\/\/$host\//;
        htmlAnchor("href", "http://$host/", "title", $title); 
        htmlAnchorText($host);
        htmlAnchorClose();
        if ($index != $#{$g_users{$g_auth{'login'}}->{'hostnames'}}) {
          htmlText(", ");
        }
      }
      htmlTableDataClose();
      htmlTableData();
      htmlTableDataClose();
      htmlTableRowClose();
    }
  }
  #
  # system profile information
  #
  if (($g_auth{'login'} eq "root") || 
      ($g_auth{'login'} =~ /^_.*root$/) ||
      ($g_auth{'login'} eq $g_users{'__rootid'}) ||
      (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}}))) {
    htmlTableClose();
    # root stuff -- load up any cached stuff out of root profile info file
    open(PFP, "$g_tmpdir/rpi");
    while (<PFP>) {
      chomp;
      if (/(.*)\:(.*)/) {
        $rpi{$1} = $2;
      }
    }
    close(PFP);
    # separator
    htmlULClose();
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "bgcolor", "#999999", "width", "100\%");
    htmlTableRow();
    htmlTableData();
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlP();
    htmlText($PROFILE_ROOT_SYSTEM_INFORMATION);
    htmlUL();
    htmlTable("border", "0", "cellpadding", "0", "cellspacing", "0");
    if ($g_platform_type eq "virtual") {
      # can't change password, but can show disk utilization
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$PROFILE_OVERALLUSAGE:&#160;");
      htmlTableDataClose();
      $used = -1;
      if ($g_form{'calc_root'} eq "yes") {
        require "$g_includelib/fm_util.pl";
        $used = filemanagerGetDiskUtilization("/");
        # cache the data
        open(NFP, ">$g_tmpdir/rpi.$$");
        open(OFP, "$g_tmpdir/rpi");
        while (<OFP>) {
          next if (/^root\:/);
          print NFP $_;
        }
        close(OFP);
        print NFP "root:$used\n";
        close(NFP);
        rename("$g_tmpdir/rpi.$$", "$g_tmpdir/rpi");
      }
      else {
        $used = $rpi{'root'} || -1;
      }
      if ($used == -1) {
        htmlTableData("valign", "middle", "align", "left");
        htmlText($PROFILE_DISK_USAGE_UNDETERMINED);
        htmlTableDataClose();
      }
      else {
        if ($used < 1048576) {
          $used /= 1024;
          $usagestring = sprintf("%1.2f $KILOBYTES", $used);
        }
        else {
          $used /= 1048576;
          $usagestring = sprintf("%1.2f $MEGABYTES", $used);
        }
        htmlTableData("valign", "middle", "align", "left");
        htmlText("$usagestring&#185;");
        htmlTableDataClose();
        $shownote = 1;
      }
      # calc or recalc link
      htmlTableData();
      unless ($g_form{'print_submit'}) {
        htmlText("[&#160;");
        if ($used == -1) {
          $title = $PROFILE_DISK_USAGE_CALCULATE_TITLE;
          $title =~ s/__USER_ID__/$loginstr/;
          htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?calc_root=yes",
                     "title", $title);
          htmlAnchorText($PROFILE_DISK_USAGE_CALCULATE);
          htmlAnchorClose();
        }
        else {
          $title = $PROFILE_DISK_USAGE_RECALCULATE_TITLE;
          $title =~ s/__USER_ID__/$loginstr/;
          htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?calc_root=yes",
                     "title", $title);
          htmlAnchorText($PROFILE_DISK_USAGE_RECALCULATE);
          htmlAnchorClose();
        }
        htmlText("&#160;]");
      }
      htmlTableDataClose();
      htmlTableRowClose();
    }
    else {
      # df derived info
      if (-e "/bin/df") {
        $bfactor = 1;
        open(SHELLFP, "/bin/df |");
        while (<SHELLFP>) {
          chomp;
          if ((/^Filesystem/) && (/512/)) {
            $bfactor = 0.5;
          }
          if (/\/$/) {   # looking for the mounted on '/' entry
            s/\s+/\ /g;
            ($blocks, $used, $avail) = (split(/\ /))[1,2,3];
            $blocks *= $bfactor;
            $used *= $bfactor;
            $avail *= $bfactor;
            $blocks /= 1024;
            $used /= 1024;
            $avail /= 1024;
            if ($blocks > 0) {
              $percent = $used / $blocks * 100;
              $percent = sprintf("%1.2f\%", $percent);
            }
            else {
              $percent = "0\%";
            }
            htmlTableRow();
            htmlTableData("colspan", "2");
            htmlTextSmall("&#160;");
            htmlTableDataClose();
            htmlTableData();
            htmlTableDataClose();
            htmlTableRowClose();
            htmlTableRow();
            htmlTableData("valign", "middle", "align", "left");
            htmlTextBold("$PROFILE_ROOT_FILESYSTEM_SIZE:&#160;&#160;");
            htmlTableDataClose();
            htmlTableData("valign", "middle", "align", "left");
            htmlText("$blocks $MEGABYTES");
            htmlTableDataClose();
            htmlTableData();
            htmlTableDataClose();
            htmlTableRowClose();
            htmlTableRow();
            htmlTableData("valign", "middle", "align", "left");
            htmlTextBold("$PROFILE_ROOT_FILESYSTEM_USAGE:&#160;&#160;");
            htmlTableDataClose();
            htmlTableData("valign", "middle", "align", "left");
            $used *= 1048576;   # convert to bytes
            if ($used < 1048576) {
              $used /= 1024;
              $usagestring = sprintf("%1.2f $KILOBYTES", $used);
              $used /= 1024;
            }
            else {
              $used /= 1048576;
              $usagestring = sprintf("%1.2f $MEGABYTES", $used);
            }
            $usagestring .= " ($percent)";
            htmlText($usagestring);
            htmlTableDataClose();
            htmlTableData();
            htmlTableDataClose();
            htmlTableRowClose();
            last;
          }
        }
        close(SHELLFP); 
      }
    }
    # number of user accounts (nua); number of system accounts (nsa)
    $nua = $nsa = 0;
    foreach $user (keys(%g_users)) {
      next if ($user =~ /^_.*root$/);
      if ($g_platform_type eq "virtual") { 
        next if (($user eq "root") || ($user eq "__rootid") ||
                 ($user eq $g_users{'__rootid'}));
        $nua++;
      }
      else {
        if (($g_users{$user}->{'uid'} < 1000) || 
            ($g_users{$user}->{'uid'} > 65533)) {
          $nsa++;
        }
        else {
          $nua++;
        }
      }
    }
    htmlTableRow();
    htmlTableData("colspan", "2");
    htmlTextSmall("&#160;");
    htmlTableDataClose();
    htmlTableData();
    htmlTableDataClose();
    htmlTableRowClose();
    # sua = show user accounts
    # ssa = show system account
    $g_form{'sua'} = 0 unless ($g_form{'sua'});
    if ($g_platform_type eq "dedicated") {
      $g_form{'ssa'} = 0 unless ($g_form{'ssa'});
    }
    htmlTableRow();
    htmlTableData("colspan", "2");
    htmlTable("border", "0", "cellpadding", "0", "cellspacing", "0");
    htmlTableRow();
    htmlTableData();
    htmlTextBold("$PROFILE_ROOT_NUM_USER_ACCOUNTS:&#160;");
    htmlTableDataClose();
    htmlTableData();
    htmlText("$nua&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableRowClose();
    if ($g_platform_type eq "dedicated") {
      htmlTableRow();
      htmlTableData();
      htmlNoBR();
      htmlTextBold("$PROFILE_ROOT_NUM_SYSTEM_ACCOUNTS:&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableData();
      htmlText("$nsa&#160;&#160;&#160;");
      htmlTableDataClose();
      htmlTableRowClose();
    }
    htmlTableClose();
    htmlTableDataClose();
    htmlTableData();
    unless ($g_form{'print_submit'}) {
      htmlTable("border", "0", "cellpadding", "0", "cellspacing", "0");
      htmlTableRow();
      htmlTableData();
      htmlText("[&#160;");
      if ($g_form{'sua'}) {
        $args = "sua=0&ssa=$g_form{'ssa'}";
        htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$args",
                   "title", $PROFILE_ROOT_ACCOUNTS_USER_SHOW);
        htmlAnchorText($PROFILE_ROOT_ACCOUNTS_USER_HIDE);
        htmlAnchorClose();
      }
      else {
        $args = "sua=1&ssa=$g_form{'ssa'}";
        htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$args",
                   "title", $PROFILE_ROOT_ACCOUNTS_USER_SHOW);
        htmlAnchorText($PROFILE_ROOT_ACCOUNTS_USER_SHOW);
        htmlAnchorClose();
      }
      htmlText("&#160;]");
      htmlTableDataClose();
      htmlTableRowClose();
      if ($g_platform_type eq "dedicated") {
        htmlTableRow();
        htmlTableData();
        htmlText("[&#160;");
        if ($g_form{'ssa'}) {
          $args = "ssa=0&sua=$g_form{'sua'}";
          htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$args",
                     "title", $PROFILE_ROOT_ACCOUNTS_SYSTEM_SHOW);
          htmlAnchorText($PROFILE_ROOT_ACCOUNTS_SYSTEM_HIDE);
          htmlAnchorClose();
        }
        else {
          $args = "ssa=1&sua=$g_form{'sua'}";
          htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$args",
                     "title", $PROFILE_ROOT_ACCOUNTS_SYSTEM_SHOW);
          htmlAnchorText($PROFILE_ROOT_ACCOUNTS_SYSTEM_SHOW);
          htmlAnchorClose();
        }
        htmlText("&#160;]");
        htmlTableDataClose();
        htmlTableRowClose();
      }
      htmlTableClose();
    }
    htmlTableDataClose();
    htmlTableRowClose();
    if ($g_form{'sua'}) {
      htmlTableClose();
      htmlP();
      # separator
      htmlTable("cellpadding", "0", "cellspacing", "0",
                "border", "0", "bgcolor", "#999999", "width", "100\%");
      htmlTableRow();
      htmlTableData();
      htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlP();
      htmlText($PROFILE_ROOT_ACCOUNTS_USER);
      htmlP();
      htmlTable("border", "0", "cellpadding", "0", "cellspacing", "0");
      $first = 1;
      foreach $user (sort(keys(%g_users))) {
        next if ($user =~ /^_.*root$/);
        if ($g_platform_type eq "virtual") { 
          next if (($user eq "root") || ($user eq "__rootid") ||
                   ($user eq $g_users{'__rootid'}));
        }
        else {
          next if (($g_users{$user}->{'uid'} < 1000) || 
                   ($g_users{$user}->{'uid'} > 65533));
        }
        unless ($first) {
          htmlTableRow();
          htmlTableData("colspan", "2");
          htmlTextSmall("&#160;");
          htmlTableDataClose();
          htmlTableData();
          htmlTableDataClose();
          htmlTableRowClose();
        }
        $first = 0;
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextBold("$PROFILE_LOGIN:&#160;&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        htmlText($user);
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextBold("$PROFILE_NAME:&#160;&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        htmlText($g_users{$user}->{'name'});
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextBold("$PROFILE_HOME_DIRECTORY:&#160;&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        $homedir = $g_users{$user}->{'home'};
        htmlText($homedir);
        htmlTableDataClose();
        htmlTableRowClose();
        if ($g_platform_type eq "virtual") {
          # summary of ftp privileges
          htmlTableRow();
          htmlTableData("colspan", "2");
          htmlTable("border", "0", "cellpadding", "0", "cellspacing", "0");
          htmlTableRow();
          htmlTableData();
          htmlImg("width", "1", "height", "2", "src", "$g_graphicslib/sp.gif");
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableClose();
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableRow();
          htmlTableData("valign", "middle", "align", "left");
          htmlTextBold("$PROFILE_FTP:&#160;&#160;");
          htmlTableDataClose();
          htmlTableData("valign", "middle", "align", "left");
          htmlText($g_users{$user}->{'ftp'} ? 
                   $YES_STRING : $NO_STRING);
          htmlTableDataClose();
          htmlTableRowClose();
          if ($g_users{$user}->{'ftp'}) {
            htmlTableRow();
            htmlTableData("valign", "middle", "align", "left");
            htmlTextBold("$PROFILE_FTPQUOTA:&#160;&#160;");
            htmlTableDataClose();
            htmlTableData("valign", "middle", "align", "left");
            htmlText($g_users{$user}->{'ftpquota'} ? 
                     "$g_users{$user}->{'ftpquota'} $MEGABYTES" : 
                     $NONE_STRING);
            htmlTableDataClose();
            htmlTableRowClose();
            htmlTableRow();
            htmlTableData("valign", "middle", "align", "left");
            htmlTextBold("$PROFILE_FTPUSAGE:&#160;&#160;");
            htmlTableDataClose();
            htmlTableData("valign", "middle", "align", "left");
            require "$g_includelib/fm_util.pl";
            $homedir = $g_users{$user}->{'home'};
            $used = filemanagerGetDiskUtilization($homedir);
            if ($used < 1048576) {
              $used /= 1024;
              $usagestring = sprintf("%1.2f $KILOBYTES", $used);
              $used /= 1024;
            }
            else {
              $used /= 1048576;
              $usagestring = sprintf("%1.2f $MEGABYTES", $used);
            }
            if ($g_users{$user}->{'ftpquota'} > 0) {
              $percent = $used / $g_users{$user}->{'ftpquota'} * 100;
              $percent = sprintf("%1.2f\%", $percent);
              $usagestring .= " ($percent)";
            }
            htmlText($usagestring);
            htmlTableDataClose();
            htmlTableRowClose();
          }
          # summary of mail privileges
          htmlTableRow();
          htmlTableData("colspan", "2");
          htmlTable("border", "0", "cellpadding", "0", "cellspacing", "0");
          htmlTableRow();
          htmlTableData();
          htmlImg("width", "1", "height", "2", "src", "$g_graphicslib/sp.gif");
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableClose();
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableRow();
          htmlTableData("valign", "middle", "align", "left");
          htmlTextBold("$PROFILE_MAIL:&#160;&#160;");
          htmlTableDataClose();
          htmlTableData("valign", "middle", "align", "left");
          htmlText($g_users{$user}->{'mail'} ? 
                   $YES_STRING : $NO_STRING);
          htmlTableDataClose();
          htmlTableRowClose();
          if ($g_users{$user}->{'mail'}) {
            htmlTableRow();
            htmlTableData("valign", "middle", "align", "left");
            htmlTextBold("$PROFILE_MAILQUOTA:&#160;&#160;");
            htmlTableDataClose();
            htmlTableData("valign", "middle", "align", "left");
            htmlText($g_users{$user}->{'mailquota'} ? 
                     "$g_users{$user}->{'mailquota'} $MEGABYTES" : 
                     $NONE_STRING);
            htmlTableDataClose();
            htmlTableRowClose();
            htmlTableRow();
            htmlTableData("valign", "middle", "align", "left");
            htmlTextBold("$PROFILE_MAILUSAGE:&#160;&#160;");
            htmlTableDataClose();
            htmlTableData("valign", "middle", "align", "left");
            require "$g_includelib/fm_util.pl";
            if (-e "/usr/mail/$user") {
              $used = filemanagerGetDiskUtilization("/usr/mail/$user");
            }
            elsif (-e "/var/mail/$user") {
              $used = filemanagerGetDiskUtilization("/var/mail/$user");
            }
            else {
              $used = 0;
            }
            if ($used < 1048576) {
              $used /= 1024;
              $usagestring = sprintf("%1.2f $KILOBYTES", $used);
              $used /= 1024;
            }
            else {
              $used /= 1048576;
              $usagestring = sprintf("%1.2f $MEGABYTES", $used);
            }
            if ($g_users{$user}->{'mailquota'} > 0) {
              $percent = $used / $g_users{$user}->{'mailquota'} * 100;
              $percent = sprintf("%1.2f\%", $percent);
              $usagestring .= " ($percent)";
            }
            htmlText($usagestring);
            htmlTableDataClose();
            htmlTableRowClose();
          }
        }
        else {
          # group membership
          htmlTableRow();
          htmlTableData("valign", "middle", "align", "left");
          htmlTextBold("$PROFILE_GROUP_MEMBERSHIP:&#160;&#160;");
          htmlTableDataClose();
          htmlTableData("valign", "middle", "align", "left");
          $groupname = groupGetNameFromID($g_users{$user}->{'gid'});
          htmlText($groupname);
          foreach $groupname (sort(keys(%g_groups))) {
            if ($g_groups{$groupname}->{'gid'} == $g_users{$user}->{'gid'}) {
              next;
            }
            if (defined($g_groups{$groupname}->{'m'}->{$user})) {
              htmlText(",&#160;$groupname");
            }
          }
          htmlTableDataClose();
          htmlTableRowClose();
          # disk quota and disk usage
          htmlTableRow();
          htmlTableData("valign", "middle", "align", "left");
          htmlTextBold("$PROFILE_OVERALLQUOTA:&#160;&#160;");
          htmlTableDataClose();
          htmlTableData("valign", "middle", "align", "left");
          htmlText($g_users{$user}->{'quota'} ? 
                   "$g_users{$user}->{'quota'} $MEGABYTES" : $NONE_STRING);
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableRow();
          htmlTableData("valign", "middle", "align", "left");
          htmlTextBold("$PROFILE_OVERALLUSAGE:&#160;&#160;");
          htmlTableDataClose();
          htmlTableData("valign", "middle", "align", "left");
          $used = quotaGetUsed($g_users{$user}->{'uid'});
          $used *= 1024;  # convert to bytes
          if ($used < 1048576) {
            $used /= 1024;
            $usagestring = sprintf("%1.2f $KILOBYTES", $used);
            $used /= 1024;
          }
          else {
            $used /= 1048576;
            $usagestring = sprintf("%1.2f $MEGABYTES", $used);
          }
          if ($g_users{$user}->{'quota'}) {
            $percent = $used / $g_users{$user}->{'quota'} * 100;
            $percent = sprintf("%1.2f\%", $percent);
            $usagestring .= " ($percent)";
          }
          htmlText($usagestring);
          htmlTableDataClose();
          htmlTableRowClose();
        }
      }
    }
    if (($g_platform_type eq "dedicated") && ($g_form{'ssa'})) {
      htmlTableClose();
      htmlP();
      # separator
      htmlTable("cellpadding", "0", "cellspacing", "0",
                "border", "0", "bgcolor", "#999999", "width", "100\%");
      htmlTableRow();
      htmlTableData();
      htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlP();
      htmlText($PROFILE_ROOT_ACCOUNTS_SYSTEM);
      htmlP();
      htmlTable("border", "0", "cellpadding", "0", "cellspacing", "0");
      $first = 1;
      foreach $user (sort(keys(%g_users))) {
        next if ($user =~ /^_.*root$/);
        next unless (($g_users{$user}->{'uid'} < 1000) || 
                     ($g_users{$user}->{'uid'} > 65533));
        unless ($first) {
          htmlTableRow();
          htmlTableData("colspan", "2");
          htmlTextSmall("&#160;");
          htmlTableDataClose();
          htmlTableData();
          htmlTableDataClose();
          htmlTableRowClose();
        }
        $first = 0;
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextBold("$PROFILE_LOGIN:&#160;&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        htmlText($user);
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextBold("$PROFILE_NAME:&#160;&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        htmlText($g_users{$user}->{'name'});
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextBold("$PROFILE_HOME_DIRECTORY:&#160;&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        $homedir = $g_users{$user}->{'home'};
        htmlText($homedir);
        htmlTableDataClose();
        htmlTableRowClose();
      }
    }
  }
  htmlTableClose();
  htmlBR();

  if ($g_form{'sua'} || 
      (($g_platform_type eq "dedicated") && $g_form{'ssa'})) {
    # separator
    htmlULClose();
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "bgcolor", "#999999", "width", "100\%");
    htmlTableRow();
    htmlTableData();
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlP();
    htmlUL();
  }

  unless ($g_form{'print_submit'}) {
    htmlTable("border", "0", "cellpadding", "1", "cellspacing", "1");
    htmlTableRow();
    if ($g_form{'sua'} || 
        (($g_platform_type eq "dedicated") && $g_form{'ssa'})) {
      htmlTableData();
      formOpen("method", "POST", "action", "$ENV{'SCRIPT_NAME'}");
      authPrintHiddenFields();
      formInput("type", "hidden", "name", "sua", "value", $g_form{'sua'});
      if ($g_platform_type eq "dedicated") {
        formInput("type", "hidden", "name", "ssa", "value", $g_form{'ssa'});
      }
      formInput("type", "submit", "name", "print_submit", "value", 
                $PROFILE_PRINTER_FRIENDLY_FORMAT); 
      formClose();
      htmlTableDataClose();
    }
    htmlTableData();
    formOpen("method", "POST", "action", "../index.cgi");
    authPrintHiddenFields();
    formInput("type", "submit", "name", "submit", "value", $MAINMENU_TITLE); 
    formClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
  }
  if ($shownote) {
    htmlBR();
    htmlTextItalic("&#185; - $PROFILE_DISK_USAGE_NOTE");
    htmlBR();
  }
  htmlULClose();

  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();

  htmlP();

  if ($g_form{'print_submit'}) {
    htmlBodyClose();
    htmlHtmlClose();
  }
  else {
    labelCustomFooter();
  }
  exit(0);
}

##############################################################################
# eof

1;

