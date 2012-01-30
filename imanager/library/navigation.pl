#
# navigation.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/navigation.pl,v 2.12.2.1 2006/04/25 19:48:25 rus Exp $
#
# navigation menu functions
#

##############################################################################

sub navigationMenu
{
  local($mainurl, $upurl, $fmurl, $mmurl, $irurl, $lourl, $dnurl);
  local($prefsurl, $genprefsurl, $fmprefsurl, $mmprefsurl, $irprefsurl);
  local($tmpfile, $oldfh, $lostring);

  $fg_opencharacter = "[";

  encodingIncludeStringLibrary("prefs");

  if ($ENV{'SCRIPT_NAME'} =~ /index.cgi$/) {
    $lourl = "wizards/logout.cgi";
    $dnurl = "wizards/donothing.cgi";
  }
  else {
    $mainurl = "../index.cgi";
    $upurl = "profile.cgi";
    $fmurl = "filemanager.cgi";
    $mmurl = "mailmanager.cgi";
    $irurl = "iroot.cgi";
    $lourl = "logout.cgi";
    $prefsurl = "prefs.cgi";
    $genprefsurl = "prefs.cgi?preftype=general"; 
    $fmprefsurl = "prefs.cgi?preftype=filemanager"; 
    $mmprefsurl = "prefs.cgi?preftype=mailmanager"; 
    $irprefsurl = "prefs.cgi?preftype=iroot"; 
    $dnurl = "donothing.cgi";
  }

  if ($g_auth{'login'} =~ /^_.*root$/) {
    $lourl .= "?login=$g_auth{'login'}";
  }

  htmlTable("width", "100%", "border", "0", 
            "cellpadding", "0", "cellspacing", "0");
  htmlTableRow();
  htmlTableData("align", "right");
  if ($ENV{'SCRIPT_NAME'} !~ /index.cgi$/) {
    navigationPrintMenuOpenCharacter();
    htmlAnchor("href", $mainurl, "title", $MAINMENU_TITLE);
    htmlAnchorText($MAINMENU_TITLE);
    htmlAnchorClose();
  }
  if ($ENV{'SCRIPT_NAME'} =~ /changepassword.cgi$/) {
    navigationPrintMenuOpenCharacter();
    htmlAnchor("href", $upurl, "title", $MAINMENU_USERPROFILE_TITLE);
    htmlAnchorText($MAINMENU_USERPROFILE_TITLE);
    htmlAnchorClose();
  }
  if (($ENV{'SCRIPT_NAME'} =~ /prefs.cgi$/) && 
      ($ENV{'QUERY_STRING'} =~ /preftype=/)) {
    navigationPrintMenuOpenCharacter();
    htmlAnchor("href", $prefsurl, "title", $PREFS_MAINMENU_TITLE);
    htmlAnchorText($PREFS_MAINMENU_TITLE);
    htmlAnchorClose();
  }
  if ($g_users{$g_auth{'login'}}->{'ftp'}) {
    if (($ENV{'SCRIPT_NAME'} =~ /fm_(.*).cgi$/) ||
        (($ENV{'SCRIPT_NAME'} =~ /prefs.cgi$/) && 
         (($ENV{'QUERY_STRING'} !~ /preftype=/) ||
          ($ENV{'QUERY_STRING'} =~ /filemanager/)))) {
      navigationPrintMenuOpenCharacter();
      htmlAnchor("href", $fmurl, "title", $MAINMENU_FILEMANAGER_TITLE);
      htmlAnchorText($MAINMENU_FILEMANAGER_TITLE);
      htmlAnchorClose();
    }
    if (($ENV{'SCRIPT_NAME'} =~ /filemanager.cgi$/) ||
        ($ENV{'SCRIPT_NAME'} =~ /fm_(.*).cgi$/)) {
      navigationPrintMenuOpenCharacter();
      htmlAnchor("href", $fmprefsurl, "title", $PREFS_FILEMANAGER_TEXT);
      htmlAnchorText($PREFS_FILEMANAGER_TEXT);
      htmlAnchorClose();
    }
  }
  if ($g_users{$g_auth{'login'}}->{'mail'}) {
    if (($ENV{'SCRIPT_NAME'} =~ /mm_(.*).cgi$/) ||
        (($ENV{'SCRIPT_NAME'} =~ /prefs.cgi$/) && 
         (($ENV{'QUERY_STRING'} !~ /preftype=/) ||
          ($ENV{'QUERY_STRING'} =~ /mailmanager/)))) {
      navigationPrintMenuOpenCharacter();
      htmlAnchor("href", $mmurl, "title", $MAINMENU_MAILMANAGER_TITLE);
      htmlAnchorText($MAINMENU_MAILMANAGER_TITLE);
      htmlAnchorClose();
    }
    if (($ENV{'SCRIPT_NAME'} =~ /mailmanager.cgi$/) ||
        ($ENV{'SCRIPT_NAME'} =~ /mm_(.*).cgi$/)) {
      navigationPrintMenuOpenCharacter();
      htmlAnchor("href", $mmprefsurl, "title", $PREFS_MAILMANAGER_TEXT);
      htmlAnchorText($PREFS_MAILMANAGER_TEXT);
      htmlAnchorClose();
    }
  }
  if (($g_auth{'login'} eq "root") ||
      ($g_auth{'login'} =~ /_.*root$/) ||
      ($g_auth{'login'} eq $g_users{'__rootid'}) ||
      (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}}))) {
    if (($ENV{'SCRIPT_NAME'} =~ /aliases_(.*).cgi$/) ||
        ($ENV{'SCRIPT_NAME'} =~ /spammers_(.*).cgi$/) ||
        ($ENV{'SCRIPT_NAME'} =~ /users_(.*).cgi$/) ||
        ($ENV{'SCRIPT_NAME'} =~ /virtmaps_(.*).cgi$/) ||
        ($ENV{'SCRIPT_NAME'} =~ /vhosts_(.*).cgi$/) ||
        ($ENV{'SCRIPT_NAME'} =~ /restart_apache.cgi/) ||
        (($ENV{'SCRIPT_NAME'} =~ /prefs.cgi$/) && 
         (($ENV{'QUERY_STRING'} !~ /preftype=/) ||
          ($ENV{'QUERY_STRING'} =~ /iroot/)))) {
      navigationPrintMenuOpenCharacter();
      htmlAnchor("href", $irurl, "title", $MAINMENU_IROOT_TITLE);
      htmlAnchorText($MAINMENU_IROOT_TITLE);
      htmlAnchorClose();
    }
    if (($ENV{'SCRIPT_NAME'} =~ /iroot.cgi$/) ||
        ($ENV{'SCRIPT_NAME'} =~ /aliases_(.*).cgi$/) ||
        ($ENV{'SCRIPT_NAME'} =~ /spammers_(.*).cgi$/) ||
        ($ENV{'SCRIPT_NAME'} =~ /users_(.*).cgi$/) ||
        ($ENV{'SCRIPT_NAME'} =~ /virtmaps_(.*).cgi$/) ||
        ($ENV{'SCRIPT_NAME'} =~ /vhosts_(.*).cgi$/)) {
      navigationPrintMenuOpenCharacter();
      htmlAnchor("href", $irprefsurl, "title", $PREFS_IROOT_TEXT);
      htmlAnchorText($PREFS_IROOT_TEXT);
      htmlAnchorClose();
    }
  }
  if ($g_auth{'type'} eq "cookie") {
    navigationPrintMenuOpenCharacter();
    htmlAnchor("href", $lourl, "title", $LOGOUT_STRING);
    htmlAnchorText($LOGOUT_STRING);
    htmlAnchorClose();
  }
  else {
    # auth type is form ... print out a javascript:self.close() logout link
    $tmpfile = $g_tmpdir . "/.navmenu-" . $g_curtime . "-" . $$;
    open(TMP, ">$tmpfile");
    $oldfh = select(TMP);
    if ($fg_opencharacter eq "[") {
      htmlText(" &#160; &#160; [&#160;");
    }
    else {
      htmlText("&#160;|&#160;");
    }
    htmlAnchor("href", "$dnurl", "title", $LOGOUT_STRING, "onClick", 
               "window.confirm('$LOGOUT_CONFIRM') && self.close();");
    htmlAnchorText($LOGOUT_STRING);
    htmlAnchorClose();
    if ($fg_opencharacter eq "[") {
      htmlText("&#160;] &#160;");
    }
    close(TMP);
    select($oldfh);
    open(TMP, "$tmpfile");
    $lostring .= $_ while (<TMP>);
    close(TMP);
    unlink($tmpfile);
    $lostring =~ s/\n//g;
    $lostring =~ s/"/\\"/g;
    print "<script language=\"JavaScript1.1\">";
    print "document.write(\"$lostring\");</script>";
  }
  navigationPrintMenuClosingCharacter();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose("width", "100%");
}

##############################################################################

sub navigationPrintMenuOpenCharacter
{
  if ($fg_opencharacter eq "[") {
    htmlText(" &#160; &#160; [&#160;");
    $fg_opencharacter = "|";
  }
  else {
    htmlText("&#160;|&#160;");
  }
}

##############################################################################

sub navigationPrintMenuClosingCharacter
{
  if ($fg_opencharacter eq "|") {
    htmlText("&#160;] &#160;");
  }
}

##############################################################################
# eof

1;

