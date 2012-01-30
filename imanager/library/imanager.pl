#
# imanager.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/imanager.pl,v 2.12.2.2 2006/04/25 19:48:23 rus Exp $
#
# main menu function
#

##############################################################################

sub imanagerMainMenu
{
  local($mesg, $javascript, $loginstr);

  if (($g_form{'login_submit'}) && 
      ($g_prefs{'general__startup_menu'} ne "main")) {
    if ($g_prefs{'general__startup_menu'} eq "profile") {
      redirectLocation("wizards/profile.cgi");
    }
    elsif ($g_prefs{'general__startup_menu'} eq "filemanager") {
      redirectLocation("wizards/filemanager.cgi");
    }
    elsif ($g_prefs{'general__startup_menu'} eq "mailmanager") {
      redirectLocation("wizards/mailmanager.cgi");
    }
    elsif (($g_prefs{'general__startup_menu'} eq "iroot") &&
           (($g_auth{'login'} eq "root") || 
            ($g_auth{'login'} =~ /^_.*root$/) || 
            ($g_auth{'login'} eq $g_users{'__rootid'}) ||
            (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}})))) {
      redirectLocation("wizards/iroot.cgi");
    }
  }

  $loginstr = $g_auth{'email'} || $g_auth{'login'};
  $loginstr = "VROOT" if ($loginstr =~ /^_.*root$/);

  htmlResponseHeader("Content-type: $g_default_content_type");

  $javascript = "";
  if (($g_auth{'login'} eq "root") ||
      ($g_auth{'login'} =~ /^_.*root$/) ||
      ($g_auth{'login'} eq $g_users{'__rootid'}) ||    
      (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}}))) {
    $javascript = javascriptOpenWindow();
  }
  labelCustomHeader($MAINMENU_TITLE, "", $javascript); 
  $MAINMENU_TEXT =~ s/__USER_ID__/$loginstr/;

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

  htmlText($MAINMENU_TEXT);
  htmlP();
  htmlTable();
  htmlTableRow();
  htmlTableData("valign", "top");
  htmlTable("cellpadding", "0", "cellspacing", "3", "border", "0");
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("width", "42", "valign", "middle", "align", "right");
  htmlAnchor("href", "wizards/profile.cgi",
             "title", "$MAINMENU_USERPROFILE_TITLE - $loginstr");
  htmlImg("border", "0", "width", "42", "height", "46", 
          "src", "graphics/profile.jpg",
          "alt", "$MAINMENU_USERPROFILE_TITLE - $loginstr");
  htmlAnchorClose();
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left");
  htmlNoBR();
  htmlAnchor("href", "wizards/profile.cgi",
             "title", "$MAINMENU_USERPROFILE_TITLE - $loginstr");
  htmlAnchorTextHeader("$MAINMENU_USERPROFILE_TITLE - $loginstr");
  htmlAnchorClose();
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableRowClose();
  if ($g_users{$g_auth{'login'}}->{'ftp'}) {
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("width", "42", "valign", "middle", "align", "right");
    htmlAnchor("href", "wizards/filemanager.cgi",
               "title", "$MAINMENU_FILEMANAGER_TITLE");
    htmlImg("border", "0", "width", "42", "height", "46", 
            "src", "graphics/fm.jpg", "alt", "$MAINMENU_FILEMANAGER_TITLE");
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "left");
    htmlAnchor("href", "wizards/filemanager.cgi",
               "title", "$MAINMENU_FILEMANAGER_TITLE");
    htmlAnchorTextHeader($MAINMENU_FILEMANAGER_TITLE);
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableRowClose();
  }
  if ($g_users{$g_auth{'login'}}->{'mail'}) {
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("width", "42", "valign", "middle", "align", "right");
    htmlAnchor("href", "wizards/mailmanager.cgi",
               "title", "$MAINMENU_MAILMANAGER_TITLE");
    htmlImg("border", "0", "width", "42", "height", "46", 
            "src", "graphics/mm.jpg", "alt", "$MAINMENU_MAILMANAGER_TITLE");
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "left");
    htmlAnchor("href", "wizards/mailmanager.cgi",
               "title", "$MAINMENU_MAILMANAGER_TITLE");
    htmlAnchorTextHeader($MAINMENU_MAILMANAGER_TITLE);
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableRowClose();
  }
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("width", "42", "valign", "middle", "align", "right");
  htmlAnchor("href", "wizards/prefs.cgi",
             "title", "$MAINMENU_PREFERENCES_TITLE");
  htmlImg("border", "0", "width", "42", "height", "46", 
          "src", "graphics/prefs.jpg", "alt", "$MAINMENU_PREFERENCES_TITLE");
  htmlAnchorClose();
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left");
  htmlAnchor("href", "wizards/prefs.cgi",
             "title", "$MAINMENU_PREFERENCES_TITLE");
  htmlAnchorTextHeader($MAINMENU_PREFERENCES_TITLE);
  htmlAnchorClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlTableDataClose();
  if (($g_auth{'login'} eq "root") ||
      ($g_auth{'login'} =~ /^_.*root$/) ||
      ($g_auth{'login'} eq $g_users{'__rootid'}) ||    
      (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}}))) {
    htmlTableData("valign", "top");
    htmlTable("cellpadding", "0", "cellspacing", "3", "border", "0");
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("width", "42", "valign", "middle", "align", "right");
    htmlAnchor("href", "wizards/iroot.cgi",
               "title", "$MAINMENU_IROOT_TITLE");
    htmlImg("border", "0", "width", "42", "height", "46", 
            "src", "graphics/tools.jpg", "alt", "$MAINMENU_IROOT_TITLE");
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "left");
    htmlAnchor("href", "wizards/iroot.cgi",
               "title", "$MAINMENU_IROOT_TITLE");
    htmlAnchorTextHeader($MAINMENU_IROOT_TITLE);
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("width", "42", "valign", "middle", "align", "right");
    htmlText("&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "left");
    htmlText("&#160;");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("width", "42", "valign", "middle", "align", "right");
    htmlAnchor("href", "info.cgi",
               "title", "$MAINMENU_UPDATE_TITLE", "onClick",
               "openWindow('info.cgi', 525, 425); return false");
    htmlImg("border", "0", "width", "42", "height", "46", 
            "src", "graphics/help.jpg", "alt", "$MAINMENU_UPDATE_TITLE");
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "left");
    htmlAnchor("href", "info.cgi",
               "title", "$MAINMENU_UPDATE_TITLE", "onClick",
               "openWindow('info.cgi', 525, 425); return false");
    htmlAnchorTextHeader($MAINMENU_UPDATE_TITLE);
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("width", "42", "valign", "middle", "align", "right");
    htmlAnchor("href", "about.cgi",
               "title", "$MAINMENU_ABOUT_TITLE", "onClick",
               "openWindow('about.cgi', 475, 400); return false");
    htmlImg("border", "0", "width", "42", "height", "46", 
            "src", "graphics/help.jpg", "alt", "$MAINMENU_ABOUT_TITLE");
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "left");
    htmlAnchor("href", "about.cgi",
               "title", "$MAINMENU_ABOUT_TITLE", "onClick",
               "openWindow('about.cgi', 475, 400); return false");
    htmlAnchorTextHeader($MAINMENU_ABOUT_TITLE);
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTableDataClose();
  }
  htmlTableRowClose();
  htmlTableClose();
  htmlP();

  labelCustomFooter();
  exit(0);
}

##############################################################################
# eof

1;

