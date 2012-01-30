#
# mm_signature.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/mm_signature.pl,v 2.12.2.5 2006/04/25 19:48:25 rus Exp $
#
# functions to show, edit, remove mail signature
#

##############################################################################

sub mailmanagerSignatureDisplayForm
{
  local($mesg) = @_;
  local($value, $rows, $homedir);

  $homedir = $g_users{$g_auth{'login'}}->{'home'};

  # load up the signature text; determine text area rows
  unless ($g_form{'sigtext'}) {
    if (-e "$homedir/.signature") {
      open(SFP, "$homedir/.signature");
      $g_form{'sigtext'} .= $_ while (<SFP>);
      close(SFP);
    }
  }
  $rows = formTextAreaRows($g_form{'sigtext'});

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader("$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_SIGNATURE_TITLE");
  if ($mesg) {
    htmlTextColorBold(">>> $mesg <<<", "#cc0000");
    htmlP();
  }

  #
  # mail signature table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_SIGNATURE_TITLE");
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

  htmlText($MAILMANAGER_SIGNATURE_HELP_TEXT);
  htmlP();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  htmlTable();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("colspan", "2");
  htmlTextBold($MAILMANAGER_SIGNATURE_APPEND_TEXT);
  htmlBR();
  $value = $g_prefs{'mail__signature_automatic_append'};
  htmlText("&#160;&#160;");
  formInput("type", "radio", "name", "mail__signature_automatic_append",
            "value", "yes", "_OTHER_", ($value eq "yes") ? "CHECKED" : "");
  htmlText($YES_STRING);
  htmlText("&#160;&#160;");
  formInput("type", "radio", "name", "mail__signature_automatic_append",
            "value", "no", "_OTHER_", ($value eq "no") ? "CHECKED" : "");
  htmlText($NO_STRING);
  htmlBR();
  htmlBR();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("rowspan", "2");
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("colspan", "2");
  htmlTextBold("$MAILMANAGER_SIGNATURE_TITLE:");
  htmlBR();
  formTextArea($g_form{'sigtext'}, "name", "sigtext", "rows", $rows, 
               "cols", 80, "wrap", "physical", "_FONT_", "fixed");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("align", "left");
  formInput("type", "submit", "name", "sigsubmit",
            "value", $MAILMANAGER_SIGNATURE_STORE);
  formInput("type", "submit", "name", "sigsubmit", "value", $CANCEL_STRING);
  htmlTableDataClose();
  htmlTableData("align", "right");
  if (-e "$homedir/.signature") {
    formInput("type", "submit", "name", "sigsubmit",
              "value", $MAILMANAGER_SIGNATURE_REMOVE);
  }
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  formClose();

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
  exit(0);
}

##############################################################################

sub mailmanagerSignatureHandleRequest
{
  local($string);

  encodingIncludeStringLibrary("mailmanager");

  if (!$g_form{'sigsubmit'}) {
    # display the view/edit signature form
    mailmanagerSignatureDisplayForm();
  }
  elsif ($g_form{'sigsubmit'} eq "$CANCEL_STRING") {
    $string = $MAILMANAGER_SIGNATURE_CANCEL_TEXT;
  }
  elsif ($g_form{'sigsubmit'} eq "$MAILMANAGER_SIGNATURE_STORE") {
    # check the size of the submitted text
    if (length($g_form{'sigtext'}) > 1e5) {
      mailmanagerSignatureDisplayForm($MAILMANAGER_SIGNATURE_TOO_LARGE);
    }
    elsif (length($g_form{'sigtext'}) == 0) {
      # uh... whatever
      mailmanagerSignatureRemove();
    }
    else {
      mailmanagerSignatureStore();
    }
    $string = $MAILMANAGER_SIGNATURE_STORE_SUCCESS_TEXT;
  }
  elsif ($g_form{'sigsubmit'} eq "$MAILMANAGER_SIGNATURE_REMOVE") {
    mailmanagerSignatureRemove();
    $string = $MAILMANAGER_SIGNATURE_REMOVE_SUCCESS_TEXT;
  }
  redirectLocation("mailmanager.cgi", $string);
}

##############################################################################

sub mailmanagerSignatureRemove
{
  local($homedir);

  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  unlink("$homedir/.signature");
}

##############################################################################

sub mailmanagerSignatureStore
{
  local($homedir);

  $homedir = $g_users{$g_auth{'login'}}->{'home'};

  # backup old .sig file
  require "$g_includelib/backup.pl";
  backupUserFile("$homedir/.signature");

  # save signature content
  $g_form{'sigtext'} =~ s/\r\n/\n/g; 
  $g_form{'sigtext'} =~ s/\r//g;
  open(SFP, ">$homedir/.signature") ||
    mailmanagerResourceError($MAILMANAGER_SIGNATURE_STORE,
                             "failed to open($homedir/.signature)");
  print SFP "$g_form{'sigtext'}";
  close(SFP);

  # save append signature preference
  $value = $g_form{'mail__signature_automatic_append'};
  if (($g_form{'mail__signature_automatic_append'} ne "no") && 
      ($g_form{'mail__signature_automatic_append'} ne "yes")) {
    $g_form{'mail__signature_automatic_append'} = "yes";
  }
  require "$g_includelib/prefs.pl";
  prefsSave();
}

##############################################################################
# eof

1;

