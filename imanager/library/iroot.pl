#
# iroot.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/iroot.pl,v 2.12.2.2 2006/04/25 19:48:23 rus Exp $
#
# iroot main menu and init function
#

##############################################################################

sub irootInit
{
  # check for iroot privileges
  if (($g_auth{'login'} ne "root") &&
      ($g_auth{'login'} !~ /^_.*root$/) &&
      ($g_auth{'login'} ne $g_users{'__rootid'}) &&
      (!(defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}})))) {
    encodingIncludeStringLibrary("iroot");
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($IROOT_DENIED_TITLE);
    htmlText($IROOT_DENIED_TEXT);
    htmlP();
    labelCustomFooter();
    exit(0);
  }
}

##############################################################################

sub irootMainMenu
{
  local($mesg, @lines);

  if ($g_form{'msgfileid'}) {
    # read message from temporary state message file
    $mesg = redirectMessageRead($g_form{'msgfileid'});
  }

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("apache");

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($IROOT_MAINMENU_TITLE); 

  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();

  if ($mesg) {
    @lines = split(/\n/, $mesg);
    foreach $mesg (@lines) {
      htmlTextColorBold(">>>&#160;$mesg&#160;<<<", "#cc0000");
      htmlBR();
    }
    htmlP();
  }

  htmlText($IROOT_MAINMENU_TEXT);
  htmlP();

  htmlTable("border", "0");

  # users
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "top", "align", "center");
  htmlImg("src", "$g_graphicslib/profile.jpg", "alt", "$IROOT_USERS_TITLE");
  htmlTableDataClose();
  htmlTableData();
  htmlNoBR();
  htmlH3($IROOT_USERS_TITLE);
  htmlTextBold("&#160; &#160; [&#160;");
  htmlAnchor("href", "users_view.cgi",
             "title", "$IROOT_USERS_TITLE : $IROOT_VIEW_TEXT");
  htmlAnchorTextBold($IROOT_VIEW_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;|&#160;");
  htmlAnchor("href", "users_add.cgi",
             "title", "$IROOT_USERS_TITLE : $IROOT_ADD_TEXT");
  htmlAnchorTextBold($IROOT_ADD_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;|&#160;");
  htmlAnchor("href", "users_edit.cgi",
             "title", "$IROOT_USERS_TITLE : $IROOT_EDIT_TEXT");
  htmlAnchorTextBold($IROOT_EDIT_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;|&#160;");
  htmlAnchor("href", "users_remove.cgi",
             "title", "$IROOT_USERS_TITLE : $IROOT_REMOVE_TEXT");
  htmlAnchorTextBold($IROOT_REMOVE_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;|&#160;");
  htmlAnchor("href", "users_rebuild.cgi",
             "title", "$IROOT_USERS_TITLE : $IROOT_REBUILD_TEXT");
  htmlAnchorTextBold($IROOT_REBUILD_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;]");
  htmlNoBRClose();
  htmlBR();
  htmlText($IROOT_USERS_HELP);
  htmlBR();
  htmlBR();
  htmlTableDataClose();
  htmlTableRowClose();

  if ($g_platform_type eq "dedicated") {
    # groups
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top", "align", "center");
    htmlImg("src", "$g_graphicslib/groups.jpg", "alt", "$IROOT_GROUPS_TITLE");
    htmlTableDataClose();
    htmlTableData();
    htmlNoBR();
    htmlH3($IROOT_GROUPS_TITLE);
    htmlTextBold("&#160; &#160; [&#160;");
    htmlAnchor("href", "groups_view.cgi",
               "title", "$IROOT_GROUPS_TITLE : $IROOT_VIEW_TEXT");
    htmlAnchorTextBold($IROOT_VIEW_TEXT);
    htmlAnchorClose();
    htmlTextBold("&#160;|&#160;");
    htmlAnchor("href", "groups_add.cgi",
               "title", "$IROOT_GROUPS_TITLE : $IROOT_ADD_TEXT");
    htmlAnchorTextBold($IROOT_ADD_TEXT);
    htmlAnchorClose();
    htmlTextBold("&#160;|&#160;");
    htmlAnchor("href", "groups_edit.cgi",
               "title", "$IROOT_GROUPS_TITLE : $IROOT_EDIT_TEXT");
    htmlAnchorTextBold($IROOT_EDIT_TEXT);
    htmlAnchorClose();
    htmlTextBold("&#160;|&#160;");
    htmlAnchor("href", "groups_remove.cgi",
               "title", "$IROOT_GROUPS_TITLE : $IROOT_REMOVE_TEXT");
    htmlAnchorTextBold($IROOT_REMOVE_TEXT);
    htmlAnchorClose();
    htmlTextBold("&#160;]");
    htmlNoBRClose();
    htmlBR();
    htmlText($IROOT_GROUPS_HELP);
    htmlBR();
    htmlBR();
    htmlTableDataClose();
    htmlTableRowClose();
  }

  # aliases
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "top", "align", "center");
  htmlImg("src", "$g_graphicslib/mm.jpg", "alt", "$IROOT_ALIASES_TITLE");
  htmlTableDataClose();
  htmlTableData();
  htmlNoBR();
  htmlH3($IROOT_ALIASES_TITLE);
  htmlTextBold("&#160; &#160; [&#160;");
  htmlAnchor("href", "aliases_view.cgi",
             "title", "$IROOT_ALIASES_TITLE : $IROOT_VIEW_TEXT");
  htmlAnchorTextBold($IROOT_VIEW_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;|&#160;");
  htmlAnchor("href", "aliases_add.cgi",
             "title", "$IROOT_ALIASES_TITLE : $IROOT_ADD_TEXT");
  htmlAnchorTextBold($IROOT_ADD_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;|&#160;");
  htmlAnchor("href", "aliases_edit.cgi",
             "title", "$IROOT_ALIASES_TITLE : $IROOT_EDIT_TEXT");
  htmlAnchorTextBold($IROOT_EDIT_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;|&#160;");
  htmlAnchor("href", "aliases_remove.cgi",
             "title", "$IROOT_ALIASES_TITLE : $IROOT_REMOVE_TEXT");
  htmlAnchorTextBold($IROOT_REMOVE_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;|&#160;");
  htmlAnchor("href", "aliases_rebuild.cgi",
             "title", "$IROOT_ALIASES_TITLE : $IROOT_REBUILD_TEXT");
  htmlAnchorTextBold($IROOT_REBUILD_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;]");
  htmlNoBRClose();
  htmlBR();
  htmlText($IROOT_ALIASES_HELP);
  htmlBR();
  htmlBR();
  htmlTableDataClose();
  htmlTableRowClose();

  # virtmaps
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "top", "align", "center");
  htmlImg("src", "$g_graphicslib/mm.jpg", "alt", "$IROOT_VIRTMAPS_TITLE");
  htmlTableDataClose();
  htmlTableData();
  htmlNoBR();
  htmlH3($IROOT_VIRTMAPS_TITLE);
  htmlTextBold("&#160; &#160; [&#160;");
  htmlAnchor("href", "virtmaps_view.cgi",
             "title", "$IROOT_VIRTMAPS_TITLE : $IROOT_VIEW_TEXT");
  htmlAnchorTextBold($IROOT_VIEW_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;|&#160;");
  htmlAnchor("href", "virtmaps_add.cgi",
             "title", "$IROOT_VIRTMAPS_TITLE : $IROOT_ADD_TEXT");
  htmlAnchorTextBold($IROOT_ADD_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;|&#160;");
  htmlAnchor("href", "virtmaps_edit.cgi",
             "title", "$IROOT_VIRTMAPS_TITLE : $IROOT_EDIT_TEXT");
  htmlAnchorTextBold($IROOT_EDIT_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;|&#160;");
  htmlAnchor("href", "virtmaps_remove.cgi",
             "title", "$IROOT_VIRTMAPS_TITLE : $IROOT_REMOVE_TEXT");
  htmlAnchorTextBold($IROOT_REMOVE_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;|&#160;");
  htmlAnchor("href", "virtmaps_rebuild.cgi",
             "title", "$IROOT_VIRTMAPS_TITLE : $IROOT_REBUILD_TEXT");
  htmlAnchorTextBold($IROOT_REBUILD_TEXT);
  htmlAnchorClose();
  htmlTextBold("&#160;]");
  htmlNoBRClose();
  htmlBR();
  htmlText($IROOT_VIRTMAPS_HELP);
  htmlBR();
  htmlBR();
  htmlTableDataClose();
  htmlTableRowClose();

  if ($g_platform_type eq "virtual") {
    # spammmers
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top", "align", "center");
    htmlImg("src", "$g_graphicslib/mm.jpg", "alt", "$IROOT_SPAMMERS_TITLE");
    htmlTableDataClose();
    htmlTableData();
    htmlNoBR();
    htmlH3($IROOT_SPAMMERS_TITLE);
    htmlTextBold("&#160; &#160; [&#160;");
    htmlAnchor("href", "spammers_view.cgi",
               "title", "$IROOT_SPAMMERS_TITLE : $IROOT_VIEW_TEXT");
    htmlAnchorTextBold($IROOT_VIEW_TEXT);
    htmlAnchorClose();
    htmlTextBold("&#160;|&#160;");
    htmlAnchor("href", "spammers_add.cgi",
               "title", "$IROOT_SPAMMERS_TITLE : $IROOT_ADD_TEXT");
    htmlAnchorTextBold($IROOT_ADD_TEXT);
    htmlAnchorClose();
    htmlTextBold("&#160;|&#160;");
    htmlAnchor("href", "spammers_edit.cgi",
               "title", "$IROOT_SPAMMERS_TITLE : $IROOT_EDIT_TEXT");
    htmlAnchorTextBold($IROOT_EDIT_TEXT);
    htmlAnchorClose();
    htmlTextBold("&#160;|&#160;");
    htmlAnchor("href", "spammers_remove.cgi",
               "title", "$IROOT_SPAMMERS_TITLE : $IROOT_REMOVE_TEXT");
    htmlAnchorTextBold($IROOT_REMOVE_TEXT);
    htmlAnchorClose();
    htmlTextBold("&#160;|&#160;");
    htmlAnchor("href", "spammers_rebuild.cgi",
               "title", "$IROOT_SPAMMERS_TITLE : $IROOT_REBUILD_TEXT");
    htmlAnchorTextBold($IROOT_REBUILD_TEXT);
    htmlAnchorClose();
    htmlTextBold("&#160;]");
    htmlNoBRClose();
    htmlBR();
    htmlText($IROOT_SPAMMERS_HELP);
    htmlBR();
    htmlBR();
    htmlTableDataClose();
    htmlTableRowClose();
  }
  else {
    # mail access
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top", "align", "center");
    htmlImg("src", "$g_graphicslib/mm.jpg", "alt", "$IROOT_MAILACCESS_TITLE");
    htmlTableDataClose();
    htmlTableData();
    htmlNoBR();
    htmlH3($IROOT_MAILACCESS_TITLE);
    htmlTextBold("&#160; &#160; [&#160;");
    htmlAnchor("href", "mailaccess_view.cgi",
               "title", "$IROOT_MAILACCESS_TITLE : $IROOT_VIEW_TEXT");
    htmlAnchorTextBold($IROOT_VIEW_TEXT);
    htmlAnchorClose();
    htmlTextBold("&#160;|&#160;");
    htmlAnchor("href", "mailaccess_add.cgi",
               "title", "$IROOT_MAILACCESS_TITLE : $IROOT_ADD_TEXT");
    htmlAnchorTextBold($IROOT_ADD_TEXT);
    htmlAnchorClose();
    htmlTextBold("&#160;|&#160;");
    htmlAnchor("href", "mailaccess_edit.cgi",
               "title", "$IROOT_MAILACCESS_TITLE : $IROOT_EDIT_TEXT");
    htmlAnchorTextBold($IROOT_EDIT_TEXT);
    htmlAnchorClose();
    htmlTextBold("&#160;|&#160;");
    htmlAnchor("href", "mailaccess_remove.cgi",
               "title", "$IROOT_MAILACCESS_TITLE : $IROOT_REMOVE_TEXT");
    htmlAnchorTextBold($IROOT_REMOVE_TEXT);
    htmlAnchorClose();
    htmlTextBold("&#160;|&#160;");
    htmlAnchor("href", "mailaccess_rebuild.cgi",
               "title", "$IROOT_MAILACCESS_TITLE : $IROOT_REBUILD_TEXT");
    htmlAnchorTextBold($IROOT_REBUILD_TEXT);
    htmlAnchorClose();
    htmlTextBold("&#160;]");
    htmlNoBRClose();
    htmlBR();
    htmlText($IROOT_MAILACCESS_HELP);
    htmlBR();
    htmlBR();
    htmlTableDataClose();
    htmlTableRowClose();
  }

  # virtual hosts
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "top", "align", "center");
  htmlImg("src", "$g_graphicslib/apache.jpg", "alt", "$IROOT_VHOSTS_TITLE");
  htmlTableDataClose();
  htmlTableData();
  htmlNoBR();
  htmlH3($IROOT_VHOSTS_TITLE);
  htmlTextBold("&#160; &#160; [&#160;");
  htmlAnchor("href", "vhosts_view.cgi",
             "title", "$IROOT_VHOSTS_TITLE : $IROOT_VIEW_TEXT");
  htmlAnchorTextBold($IROOT_VIEW_TEXT);
  htmlAnchorClose();
  htmlAnchorTextBold("&#160;|&#160;");
  htmlAnchor("href", "vhosts_add.cgi",
             "title", "$IROOT_VHOSTS_TITLE : $IROOT_ADD_TEXT");
  htmlAnchorTextBold($IROOT_ADD_TEXT);
  htmlAnchorClose();
  htmlAnchorTextBold("&#160;|&#160;");
  htmlAnchor("href", "vhosts_edit.cgi",
             "title", "$IROOT_VHOSTS_TITLE : $IROOT_EDIT_TEXT");
  htmlAnchorTextBold($IROOT_EDIT_TEXT);
  htmlAnchorClose();
  htmlAnchorTextBold("&#160;|&#160;");
  htmlAnchor("href", "vhosts_remove.cgi",
             "title", "$IROOT_VHOSTS_TITLE : $IROOT_REMOVE_TEXT");
  htmlAnchorTextBold($IROOT_REMOVE_TEXT);
  htmlAnchorClose();
  htmlAnchorTextBold("&#160;|&#160;");
  htmlAnchor("href", "restart_apache.cgi", "title", "$APACHE_RESTART_TITLE");
  htmlAnchorTextBold($APACHE_RESTART_TITLE);
  htmlAnchorClose();
  htmlTextBold("&#160;]");
  htmlNoBRClose();
  htmlBR();
  htmlText("$IROOT_VHOSTS_HELP $IROOT_VHOSTS_TEMPLATES_HELP [&#160;");
  htmlAnchor("href", "vhosts_template.cgi?template=user", 
             "title", "$IROOT_VHOSTS_TEMPLATES_EDIT_USER");
  htmlAnchorText($IROOT_VHOSTS_TEMPLATES_EDIT_USER);
  htmlAnchorClose();
  htmlText("&#160;|&#160;");
  htmlAnchor("href", "vhosts_template.cgi?template=admin", 
             "title", "$IROOT_VHOSTS_TEMPLATES_EDIT_ADMIN");
  htmlAnchorText($IROOT_VHOSTS_TEMPLATES_EDIT_ADMIN);
  htmlAnchorClose();
  htmlText("&#160;]");
  htmlBR();
  htmlBR();
  htmlTableDataClose();
  htmlTableRowClose();

  htmlTableClose();

  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();

  labelCustomFooter();
  exit(0);
}

##############################################################################

sub irootResourceError
{
  local($resource, $errmsg) = @_;
  local($os_error);

  $os_error = $!;

  # do some housekeeping
  if ($g_platform_type eq "virtual") {
    unlink("/etc/atmp");     # aliases
    unlink("/etc/stmp");     # spammers
    unlink("/etc/ptmp");     # users
    unlink("/etc/htmp");     # vhosts (httpd.conf)
    unlink("/etc/vmaptmp");  # virtmaps
  }
  else {
    unlink("/etc/mail/atmp");     # aliases
    unlink("/etc/mail/matmp");    # mail access
    unlink("/etc/ptmp");          # users
    unlink("/etc/htmp");          # vhosts (httpd.conf)
    unlink("/etc/mail/vmaptmp");  # virtmaps
  }

  encodingIncludeStringLibrary("iroot");

  unless ($g_response_header_sent) {
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($IROOT_RESOURCE_ERROR_TITLE);
    $IROOT_RESOURCE_ERROR_TEXT =~ s/__RESOURCE__/$resource/;
    htmlText($IROOT_RESOURCE_ERROR_TEXT);
    htmlP();
    if ($errmsg) {
      htmlUL();
      htmlTextCode($errmsg);
      htmlULClose();
      htmlP();
    }
    if ($os_error) {
      htmlUL();
      htmlTextCode($os_error);
      htmlULClose();
      htmlP();
    }
    labelCustomFooter();
    exit(0);
  }
  else {
    print STDERR "$errmsg\n" if ($errmsg);
    print STDERR "$os_error\n" if ($os_error);
  }
}

##############################################################################
# eof

1;

