#
# mm_select.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/mm_select.pl,v 2.12.2.7 2006/05/30 19:03:27 rus Exp $
#
# mail manager select active folder functions
#

##############################################################################

sub mailmanagerHandleSelectFolderRequest
{
  local($fullpath, $errmesg);

  encodingIncludeStringLibrary("mailmanager");

  # check for permission to use wizard
  if ((($g_users{$g_auth{'login'}}->{'ftp'} == 0) &&
       ($g_users{$g_auth{'login'}}->{'imap'} == 0)) ||
      ($g_users{$g_auth{'login'}}->{'mail_access_level'} ne "full")) {
    redirectLocation("mailmanager.cgi", $MAILMANAGER_SELECT_DENIED_TEXT); 
  }

  # handle cancel requests
  if ($g_form{'action'} && ($g_form{'action'} eq "$CANCEL_STRING")) {
    redirectLocation("mailmanager.cgi", $MAILMANAGER_SELECT_CANCEL_TEXT); 
  }

  # build new mailbox full path spec
  if ($g_form{'destfile'}) {
    if (($g_form{'destfile'} eq "!") ||
        ($g_form{'destfile'} =~ /^$MAILMANAGER_DEFAULT_FOLDER$/i) ||
        ($g_form{'destfile'} eq $MAILMANAGER_DEFAULT_FOLDER) ||
        ($g_form{'destfile'} eq "{$MAILMANAGER_DEFAULT_FOLDER}")) {
      $fullpath = mailmanagerGetDefaultIncomingMailbox();
      $g_form{'destfile'} = "";
    }
    else {
      $fullpath = mailmanagerBuildFullPath($g_form{'destfile'});
      $g_form{'destfile'} = $fullpath;
      if (($g_users{$g_auth{'login'}}->{'path'}) &&
          ($g_users{$g_auth{'login'}}->{'path'} ne "/")) {
        $g_form{'destfile'} =~ s/^$g_users{$g_auth{'login'}}->{'path'}//;
      }
      unless (-e "$fullpath") {
        $errmesg = $MAILMANAGER_SELECT_ERROR_FOLDER_DOES_NOT_EXIST; 
      }
    }
  }
  else {
    if ((defined($g_form{'fcc_folder'})) || (defined($g_form{'localattach'}))) {
      $g_form{'destfile'} = (!$g_users{$g_auth{'login'}}->{'chroot'}) ?
                             $g_users{$g_auth{'login'}}->{'home'} : "/";
      $fullpath = mailmanagerBuildFullPath($g_form{'destfile'});
    }
    else {
      if ($g_form{'mbox'}) {
        $g_form{'destfile'} = $g_form{'mbox'};
        $fullpath = mailmanagerBuildFullPath($g_form{'destfile'});
        $fullpath =~ s/\/$//;
        $fullpath =~ s/[^\/]+$//g;
      }
      else {
        # mbox is "" (fullpath is [usr|var]/mail), set fullpath to the
        # preferential default mail folder (g_prefs{'mail__default_folder'})
        if ((!$g_users{$g_auth{'login'}}->{'chroot'}) &&
            ($g_prefs{'mail__default_folder'} =~ /^\//) &&
            ($g_prefs{'mail__default_folder'} !~ /^\Q$g_users{$g_auth{'login'}}->{'home'}\E/)) {
          # old installations of iManager had the value for the preference
          # 'mail__default_folder' set to be an absolute '/Mail' which was
          # ok on a virtual env; but not ok on a dedicated env.  so this
          # little kludge accounts for portability problem of my previously
          # chosen default (if only I had keener foresight)
          $g_form{'destfile'} = $g_users{$g_auth{'login'}}->{'home'};
          $g_form{'destfile'} .= "/" . $g_prefs{'mail__default_folder'};
          $g_form{'destfile'} =~ s/\/+/\//g;
        }
        else {
          $g_form{'destfile'} = $g_prefs{'mail__default_folder'};
        }
        # make sure g_prefs{'mail__default_folder'} exists
        $fullpath = mailmanagerBuildFullPath($g_form{'destfile'});
        mailmanagerCreateDefaultMailFolder($fullpath);
      }
      if ($g_users{$g_auth{'login'}}->{'chroot'}) {
        $g_form{'destfile'} =~ s/^\~//;
      }
    }
  }

  if ((defined($g_form{'fcc_folder'})) || (defined($g_form{'localattach'}))) {
    if ($fullpath && (-f "$fullpath") && 
        ($g_form{'action'} eq "$SUBMIT_STRING")) {
      # using file selector to select local server files as attachments.
      # user selected the Submit button... path selected is a plain file.
      # the target form field in the parent has been updated... so we 
      # just need to close down the window making the request.
      htmlResponseHeader("Content-type: $g_default_content_type");
      htmlHtml();
      htmlHead();
      print <<ENDTEXT;
<script language="JavaScript1.1">
<!--
  self.close();
//-->
</script>
ENDTEXT
      htmlHeadClose();
      htmlHtmlClose();
    }
  }
  else {
    if ($fullpath && (-T "$fullpath")) {
      # fullpath is not a directory; set value for mbox and mpos and redirect
      $g_form{'mbox'} = $g_form{'destfile'};
      delete($g_form{'mpos'});
      redirectLocation("mailmanager.cgi");
    }
  }

  # print out select mail folder form
  mailmanagerSelectActiveMailFolderForm($fullpath, $errmesg);
}

##############################################################################

sub mailmanagerSelectActiveMailFolderForm
{
  local($fullpath, $errmsg) = @_;
  local($size);

  encodingIncludeStringLibrary("profile");

  # set the view type
  if ((!$g_form{'viewtype'}) || 
      (($g_form{'viewtype'} ne "short") && 
       ($g_form{'viewtype'} ne "long"))) {
    $g_form{'viewtype'} = "short";
  }

  htmlResponseHeader("Content-type: $g_default_content_type");
  if (defined($g_form{'fcc_folder'})) { 
    # selector for the fcc outgoing folder stuff when composing a message
    # don't show a custom header for this... keep it simple
    $MAILMANAGER_TITLE =~ s/__MAILBOX__/$MAILMANAGER_MESSAGE_FCC_SELECT/g;
    htmlHtml();
    htmlHead();
    htmlTitle($MAILMANAGER_TITLE);
    htmlHeadClose();
    htmlBody("bgcolor", "#ffffff");
  }
  elsif (defined($g_form{'localattach'})) {
    if (defined($g_form{'abi'})) {
      # selector for the filelocal stuff when importing address book contacts
      $MAILMANAGER_TITLE =~ s{__MAILBOX__}
                             {$MAILMANAGER_ADDRESSBOOK_IMPORT_LOCAL_FILE};
    }
    else {
      # selector for the filelocal stuff when composing a message
      $MAILMANAGER_TITLE =~ s{__MAILBOX__}
                             {$MAILMANAGER_MESSAGE_LOCAL_ATTACHMENTS};
    }
    htmlHtml();
    htmlHead();
    htmlTitle($MAILMANAGER_TITLE);
    htmlHeadClose();
    htmlBody("bgcolor", "#ffffff");
  }
  else {
    $MAILMANAGER_TITLE =~ s/__MAILBOX__/$MAILMANAGER_SELECT_MAILBOX/g;
    labelCustomHeader($MAILMANAGER_TITLE);
    #
    # select mail folder table (2 cells: sidebar, contents)
    # 
    htmlTable("border", "0", "cellspacing", "0",
              "cellpadding", "0", "bgcolor", "#000000");
    htmlTableRow();
    htmlTableData();
    htmlTable("border", "0", "cellspacing", "1", "cellpadding", "0");
    htmlTableRow();
    htmlTableData("bgcolor", "#999999", "valign", "top");
    #
    # begin sidebar table cell
    # 
    mailmanagerShowMailSidebar();
    #
    # end sidebar table cell
    #
    htmlTableDataClose();
    htmlTableData("bgcolor", "#ffffff", "valign", "top");
    # 
    # begin message table cell
    #
    htmlTable("cellpadding", "2", "cellspacing", "0",
              "border", "0", "width", "100\%", "bgcolor", "#9999cc");
    htmlTableRow();
    htmlTableData("align", "left", "valign", "middle");
    htmlTextBold("&#160;$MAILMANAGER_SELECT_MAILBOX");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
              "cellpadding", "0", "bgcolor", "#666666");
    htmlTableRow();
    htmlTableData("bgcolor", "#666666");
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    # begin encapsulation table
    htmlTable();
    htmlTableRow();
    htmlTableData();
  }
  if ((defined($g_form{'fcc_folder'})) || (defined($g_form{'localattach'}))) {
    print <<ENDTEXT;
<script language="JavaScript1.1">
<!--
  function updateParent()
  {
ENDTEXT
    if (defined($g_form{'fcc_folder'})) {
      print <<ENDTEXT;
    window.opener.document.formfields.fcc_folder.value = 
       document.selectForm.destfile.value;
ENDTEXT
    }
    else {
      print <<ENDTEXT;
    window.opener.document.formfields.filelocal$g_form{'localattach'}.value = 
       document.selectForm.destfile.value;
ENDTEXT
    }
    print <<ENDTEXT;
  }
//-->
</script>
ENDTEXT
    formOpen("name", "selectForm", "method", "POST",
             "onSubmit", "return(updateParent()); return true");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "viewtype", 
              "value", $g_form{'viewtype'});
    if (defined($g_form{'fcc_folder'})) {
      formInput("type", "hidden", "name", "fcc_folder", 
                "value", $g_form{'fcc_folder'});
      htmlTextBold("$MAILMANAGER_MESSAGE_FCC : ");
      htmlTextBold($MAILMANAGER_MESSAGE_FCC_SELECT);
    }
    else {
      formInput("type", "hidden", "name", "localattach", 
                "value", $g_form{'localattach'});
      if (defined($g_form{'abi'})) {
        htmlTextBold($MAILMANAGER_ADDRESSBOOK_IMPORT_LOCAL_FILE);
      }
      else {
        htmlTextBold("$MAILMANAGER_MESSAGE_LOCAL_ATTACHMENTS : ");
        $MAILMANAGER_ATTACHMENT_NUMBER =~ s/__NUM__/$g_form{'localattach'}/;
        htmlTextBold($MAILMANAGER_ATTACHMENT_NUMBER);
      }
    }
    htmlP();
  }
  else {
    formOpen("name", "selectForm", "method", "POST");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "viewtype", 
              "value", $g_form{'viewtype'});
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
    formInput("type", "hidden", "name", "cwd", "value", $g_form{'destfile'});
    if ($errmsg) {
      htmlTextColorBold(">>> $errmsg <<<", "#cc0000");
      htmlP();
    }
    htmlText($MAILMANAGER_SELECT_MAILBOX_HELP_TEXT);
    htmlP();
    if ($g_form{'mbox'}) {
      htmlTextItalic($MAILMANAGER_SELECT_INCOMING);
      htmlP();
    }
  }
  $size = formInputSize(35);
  formInput("size", $size, "name", "destfile", "value", $g_form{'destfile'});
  htmlBR();
  formInput("type", "submit", "name", "action", "value", $SUBMIT_STRING);
  formInput("type", "reset", "value", $RESET_STRING);
  if ((defined($g_form{'fcc_folder'})) || (defined($g_form{'localattach'}))) {
    formInput("type", "submit", "name", "action", "value", $CANCEL_STRING,
              "onClick", "self.close(); return false");
  }
  else {
    formInput("type", "submit", "name", "action", "value", $CANCEL_STRING);
  }
  formClose();
  htmlP();
  # separator
  htmlTable("cellpadding", "0", "cellspacing", "0",
            "border", "0", "bgcolor", "#000000", "width", "100\%");
  htmlTableRow();
  htmlTableData();
  htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  mailmanagerSelectDestinationFileFromList($fullpath);
  if ((defined($g_form{'fcc_folder'})) || (defined($g_form{'localattach'}))) {
    # simple footer when selecting from a pop-up window
    htmlBodyClose();
    htmlHtmlClose();
  }
  else {
    # end encapsulation table
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    #
    # end contents table cell
    #
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    #
    # end parent table
    #
    labelCustomFooter();
  }
  exit(0);
}

##############################################################################
# eof

1;

