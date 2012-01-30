#
# mm_autoresponder.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/mm_autoresponder.pl,v 2.12.2.8 2006/04/25 19:48:24 rus Exp $
#
# functions to show, create, remove an autoresponder
#

##############################################################################

sub mailmanagerAutoresponderDisplaySummary
{
  local($mesg) = @_;
  local($title, $encpath, $encargs, $size, $date, $num);
  local($ar_enabled, $ar_mode, $ar_mesgpath, @lines, $index);
  local($a_num, $a_type, $a_enc, $a_disp, $a_size, $string);
  local($languagepref, $validshell);

  $languagepref = encodingGetLanguagePreference();

  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_AUTOREPLY_TITLE";
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);

  if (!$mesg && $g_form{'msgfileid'}) {
    # read message from temporary state message file
    $mesg = redirectMessageRead($g_form{'msgfileid'});
  }
  if ($mesg) {
    @lines = split(/\n/, $mesg);
    foreach $mesg (@lines) {
      htmlTextColorBold(">>> $mesg <<<", "#cc0000");
      htmlBR();
    }
    htmlBR();
  }

  $encpath = encodingStringToURL($g_form{'mbox'});
  $encargs = "mbox=$encpath&mpos=$g_form{'mpos'}";

  $ar_enabled = mailmanagerNemetonAutoreplyGetStatus();
  $ar_mode = mailmanagerAutoresponderGetMode();
  $validshell = 1;
  if (($ar_enabled) && ($g_platform_type eq "dedicated")) {
    $validshell = mailmanagerValidShell();
  }
  $ar_mesgpath = mailmanagerGetDirectoryPath("autoresponder");
  $ar_mesgpath .= "/message";

  #
  # autoresponder display summary table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_AUTOREPLY_TITLE");
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

  htmlText($MAILMANAGER_AUTOREPLY_HELP_TEXT);
  htmlP();
  htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  htmlTextBold("$MAILMANAGER_AUTOREPLY_STATUS:");
  htmlText("&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("align", "left");
  if ($ar_enabled) {
    htmlText($MAILMANAGER_AUTOREPLY_STATUS_ON);
    if ($validshell == 0) {
      htmlText("&#185;");
    }
  }
  else {
    htmlText($MAILMANAGER_AUTOREPLY_STATUS_OFF);
  }
  htmlTableDataClose();
  htmlTableData("align", "left");
  htmlNoBR();
  htmlText("&#160; &#160; [ ");
  if ($ar_enabled) {
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=disable",
               "title", "$MAILMANAGER_AUTOREPLY_DISABLE");
    htmlAnchorText($MAILMANAGER_AUTOREPLY_DISABLE);
    htmlAnchorClose();
  }
  else {
    if ((-e "$ar_mesgpath") && ((stat("$ar_mesgpath"))[7] > 0)) {
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=enable",
                 "title", "$MAILMANAGER_AUTOREPLY_ENABLE");
      htmlAnchorText($MAILMANAGER_AUTOREPLY_ENABLE);
      htmlAnchorClose();
    }
    else {
      htmlTextItalic($MAILMANAGER_AUTOREPLY_ENABLE_DENIED);
    }
  }
  htmlText(" ]");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  htmlTextBold("$MAILMANAGER_AUTOREPLY_MODE:");
  htmlText("&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("align", "left");
  if ($ar_mode eq "n/a") {
    htmlText($MAILMANAGER_AUTOREPLY_MODE_UNDEFINED);
  }
  elsif ($ar_mode eq "vacation") {
    htmlText($MAILMANAGER_AUTOREPLY_MODE_VACATION);
  }
  else {
    htmlText($MAILMANAGER_AUTOREPLY_MODE_AUTOREPLY);
  }
  htmlTableDataClose();
  htmlTableData("align", "left");
  htmlNoBR();
  htmlText("&#160; &#160; [ ");
  htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=edit_mode",
             "title", "$MAILMANAGER_AUTOREPLY_MODE_CHANGE");
  htmlAnchorText($MAILMANAGER_AUTOREPLY_MODE_CHANGE);
  htmlAnchorClose();
  htmlText(" ]");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  htmlTextBold("$MAILMANAGER_AUTOREPLY_LOG_SIZE:");
  htmlText("&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("align", "left");
  $adir = mailmanagerGetDirectoryPath("autoresponder");
  ($size) = (stat("$adir/log"))[7];
  if ($size < 1024) {
    $size = sprintf("%s $BYTES", $size);
  }
  elsif ($size < 1048576) {
    $size = sprintf("%1.1f $KILOBYTES", ($size / 1024));
  }
  else {
    $size = sprintf("%1.2f $MEGABYTES", ($size / 1048576));
  }
  htmlText("$size; ");
  $num = 0;
  if (open(MFP, "$adir/log")) {
    $num++ while (<MFP>);
    close(MFP);
  }
  if ($num == 1) {
    htmlText($MAILMANAGER_AUTOREPLY_LOG_ONE_ENTRY);
  }
  else {
    $MAILMANAGER_AUTOREPLY_LOG_NUM_ENTRIES =~ s/__NUM__/$num/;
    htmlText($MAILMANAGER_AUTOREPLY_LOG_NUM_ENTRIES);
  }
  htmlTableDataClose();
  htmlTableData("align", "left");
  htmlNoBR();
  htmlText("&#160; &#160; [ ");
  htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=view_log",
             "title", "$MAILMANAGER_AUTOREPLY_LOG_VIEW");
  htmlAnchorText($MAILMANAGER_AUTOREPLY_LOG_VIEW);
  htmlAnchorClose();
  htmlText(" ]");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableRowClose();
  if ((-e "$ar_mesgpath") && ((stat("$ar_mesgpath"))[7] > 0)) {
    ($size, $date) = (stat("$ar_mesgpath"))[7,9];
    htmlTableRow();
    htmlTableData();
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextBold("$MAILMANAGER_AUTOREPLY_CONTENT_DATE:");
    htmlText("&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("align", "left");
    $date = dateBuildTimeString("alpha", $date);
    $date = dateLocalizeTimeString($date);
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlText($date);
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlNoBR();
    htmlText("&#160; &#160; [ ");
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=edit_message",
               "title", "$MAILMANAGER_AUTOREPLY_CONTENT_EDIT");
    htmlAnchorText($MAILMANAGER_AUTOREPLY_CONTENT_EDIT);
    htmlAnchorClose();
    htmlText(" ]");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextBold("$MAILMANAGER_AUTOREPLY_CONTENT_SIZE:");
    htmlText("&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("align", "left");
    if ($size < 1024) {
      $size = sprintf("%s $BYTES", $size);
    }
    elsif ($size < 1048576) {
      $size = sprintf("%1.1f $KILOBYTES", ($size / 1024));
    }
    else {
      $size = sprintf("%1.2f $MEGABYTES", ($size / 1048576));
    }
    htmlText($size);
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextBold("$MAILMANAGER_AUTOREPLY_CONTENT:");
    htmlText("&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlText("&#160;");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData();
    htmlTable("cellspacing", "1", "cellpadding", "0", "border", "0",
              "bgcolor", "#333333");
    htmlTableRow();
    htmlTableData();
    htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0",
              "bgcolor", "#ffffff");
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;");
    htmlTableData();
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    mailmanagerAutoresponderMessageRead();
    if (($g_message{'from'}) || ($g_message{'subject'}) || 
        ($g_message{'reply-to'})) {
      if ($g_message{'from'}) {
        htmlTextCodeColor("$MAILMANAGER_MESSAGE_SENDER\:&#160;", "#666666");
        $string = $g_message{'from'};
        if ($languagepref eq "ja") {
          $string = mailmanagerMimeDecodeHeaderJP_QP($string);
          $string = jcode'euc(mimedecode($string));
        }
        htmlTextCodeColor($string, "#666666");
        htmlBR();
      }
      if ($g_message{'subject'}) {
        htmlTextCodeColor("$MAILMANAGER_MESSAGE_SUBJECT\:&#160;", "#666666");
        $string = $g_message{'subject'};
        if ($languagepref eq "ja") {
          $string = mailmanagerMimeDecodeHeaderJP_QP($string);
          $string = jcode'euc(mimedecode($string));
        }
        htmlTextCodeColor($string, "#666666");
        htmlBR();
      }
      if ($g_message{'reply-to'}) {
        htmlTextCodeColor("$MAILMANAGER_MESSAGE_REPLY_TO\:&#160;", "#666666");
        $string = $g_message{'reply-to'};
        if ($languagepref eq "ja") {
          $string = mailmanagerMimeDecodeHeaderJP_QP($string);
          $string = jcode'euc(mimedecode($string));
        }
        htmlTextCodeColor($string, "#666666");
        htmlBR();
      }
      htmlBR();
    }
    if ($g_message{'auto_body'}) {
      @lines = split(/\n/, $g_message{'auto_body'});
      for ($index=0; $index<=$#lines; $index++) {
        $string = $lines[$index];
        if ($languagepref eq "ja") {
          $string = mailmanagerMimeDecodeHeaderJP_QP($string);
          $string = jcode'euc($string);
        }
        $string = htmlSanitize($string);
        $string =~ s/\ \ /\&\#160\;\ /g;
        htmlTextCodeColor($string, "#666666");
        htmlBR();
      } 
      #if ($#lines >= 10) {
      #  htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
      #  htmlBR();
      #  htmlTextCodeColor("&#160;[$MAILMANAGER_AUTOREPLY_CONTENT_CROPPED]",
      #                    "#666666");
      #  htmlBR();
      #}
    }
    if ($#{$g_message{'attachments'}} > -1) {
      for ($index=0; $index<=$#{$g_message{'attachments'}}; $index++) {
        htmlBR();
        $a_num = $MAILMANAGER_ATTACHMENT_NUMBER;
        $id = $index + 1;
        $a_num =~ s/__NUM__/$id/;
        $a_type = (split(/\;/, $g_message{'attachments'}[$index]->{'content-type'}))[0] || "???";
        $a_enc = $g_message{'attachments'}[$index]->{'content-transfer-encoding'};
        $a_disp = $g_message{'attachments'}[$index]->{'content-disposition'};
        $a_size = $g_message{'attachments'}[$index]->{'__filepos_end__'} -
                  $g_message{'attachments'}[$index]->{'__filepos_body__'};
        if ($a_size < 1024) {
          $a_size = sprintf("%s $BYTES", $a_size);
        }
        elsif ($a_size < 1048576) {
          $a_size = sprintf("%1.1f $KILOBYTES", ($a_size / 1024));
        }
        else {
          $a_size = sprintf("%1.2f $MEGABYTES", ($a_size / 1048576));
        }
        $string = "[ $a_num";
        if ($a_disp) {
          $a_disp =~ s/attachment; //;
          $a_disp =~ s/inline; //;
          $a_disp =~ s/filename=/$MAILMANAGER_CONTENT_DISPOSITION_FILENAME=/;
          if ($languagepref eq "ja") {
            $a_disp = mailmanagerMimeDecodeHeaderJP_QP($a_disp);
            $a_disp = jcode'euc(mimedecode($a_disp));
          }
          $string .= "; $a_disp";
        }
        $string .= "]";
        htmlTextCodeColor($string, "#666666");
        htmlBR();
        $string = "[ $MAILMANAGER_ATTACHMENT_TYPE: $a_type; ";
        if ($a_enc) {
          $string .= "$MAILMANAGER_ATTACHMENT_ENCODING: $a_enc; ";
        }
        $string .= "$MAILMANAGER_ATTACHMENT_SIZE: $a_size ]";
        htmlTextCodeColor($string, "#666666");
        htmlBR();
      } 
    }
    htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlTableDataClose();
    htmlTableData();
    htmlText("&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTableDataClose();
    htmlTableRowClose();
  }
  else {
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextBold("$MAILMANAGER_AUTOREPLY_CONTENT:");
    htmlText("&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlText($MAILMANAGER_AUTOREPLY_CONTENT_UNDEFINED);
    htmlTableDataClose();
    htmlTableData();
    htmlNoBR();
    htmlText("&#160; &#160; [ ");
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=edit_message",
               "title", "$MAILMANAGER_AUTOREPLY_CONTENT_EDIT");
    htmlAnchorText($MAILMANAGER_AUTOREPLY_CONTENT_EDIT);
    htmlAnchorClose();
    htmlText(" ]");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
  }
  htmlTableClose();
  formOpen();
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
  if (-e "$ar_mesgpath") {
    # show the submission buttons if a message summary is displayed so
    # that the user doesn't have to scroll up and down on the page
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData();
    if ($ar_enabled) {
      formInput("type", "submit", "name", "action", "value", 
                $MAILMANAGER_AUTOREPLY_DISABLE);
    }
    else {
      formInput("type", "submit", "name", "action", "value", 
                $MAILMANAGER_AUTOREPLY_ENABLE);
    }
    htmlTableDataClose();
    htmlTableData();
    htmlText("&#160;");
    formInput("type", "submit", "name", "action", "value", 
              $MAILMANAGER_AUTOREPLY_MODE_CHANGE);
    htmlTableDataClose();
    htmlTableData();
    htmlText("&#160;");
    formInput("type", "submit", "name", "action", "value", 
              $MAILMANAGER_AUTOREPLY_CONTENT_EDIT);
    htmlTableDataClose();
    htmlTableRowClose();
  }
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("colspan", "3");
  if (-e "$ar_mesgpath") {
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    if (-e "$adir/log") {
      formInput("type", "submit", "name", "action", "value", 
                $MAILMANAGER_AUTOREPLY_LOG_VIEW);
      htmlText("&#160;");
    }
  }
  formInput("type", "submit", "name", "action", "value", $MAILMANAGER_RETURN);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  formClose();
  htmlP();

  if ($validshell == 0) {
    htmlBR();
    htmlText("&#185; - ");
    htmlTextItalic("$MAILMANAGER_AUTOREPLY_INVALID_SHELL");
    htmlP();
  }

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

sub mailmanagerAutoresponderEditMessageForm
{
  local($title, $size, $value, $rows, $mai, $key, $id);
  local($a_num, $a_type, $a_enc, $a_disp, $a_size, $string, $authval);
  local($languagepref);

  $languagepref = encodingGetLanguagePreference();

  # get information about the current outgoing message
  mailmanagerAutoresponderMessageRead();

  initUploadCookieSetSessionID();
  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_AUTOREPLY_CONTENT";
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);

  #
  # autoresponder edit message table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_AUTOREPLY_TITLE : $MAILMANAGER_AUTOREPLY_CONTENT");
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

  $size = formInputSize(40);

  htmlText($MAILMANAGER_AUTOREPLY_CONTENT_HELP);
  htmlP();
  formOpen("method", "POST", "enctype", "multipart/form-data",
           "name", "formfields");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "action", "value", "store_message");
  htmlTable("border", "0");
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  htmlTable("border", "0");
  # row 2: from
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$MAILMANAGER_AUTOREPLY_CONTENT_FROM\:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $value = $g_form{'from'} || $g_message{'from'} || 
           mailmanagerUserEmailAddress();
  if ($languagepref eq "ja") {
    $value = mailmanagerMimeDecodeHeaderJP_QP($value);
    $value = jcode'euc(mimedecode($value));
  }
  formInput("size", $size, "name", "from", "value", $value);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$MAILMANAGER_AUTOREPLY_CONTENT_SUBJECT\:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $value = $g_form{'subject'} || $g_message{'subject'};
  if ($languagepref eq "ja") {
    $value = mailmanagerMimeDecodeHeaderJP_QP($value);
    $value = jcode'euc(mimedecode($value));
  }
  formInput("size", $size, "name", "subject", "value", $value);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$MAILMANAGER_AUTOREPLY_CONTENT_REPLY_TO\:");
  htmlTableData("valign", "middle");
  $value = $g_form{'reply-to'} || $g_message{'reply-to'};
  if ($languagepref eq "ja") {
    $value = mailmanagerMimeDecodeHeaderJP_QP($value);
    $value = jcode'euc(mimedecode($value));
  }
  formInput("size", $size, "name", "reply-to", "value", $value);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlTable("border", "0");
  htmlTableRow();
  htmlTableData();
  htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  htmlTextBold("$MAILMANAGER_AUTOREPLY_CONTENT_BODY\:");
  htmlBR();
  $value = $g_form{'auto_body'} || $g_message{'auto_body'};
  if ($languagepref eq "ja") {
    $value = mailmanagerMimeDecodeHeaderJP_QP($value);
    $value =  jcode'euc(mimedecode($value));
  }
  $rows = ($value =~ tr/\n/\n/) || 6;
  $rows += 2;
  formTextArea($value, "name", "auto_body", "rows", $rows,
               "cols", 80, "_FONT_", "fixed", "wrap", "physical");
  htmlP();
  if ($#{$g_message{'attachments'}} > -1) {
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "bgcolor", "#999999", "width", "100\%");
    htmlTableRow();
    htmlTableData();
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlP();
    htmlTextBold("$MAILMANAGER_AUTOREPLY_CONTENT_ATTACHMENTS_EXISTING\:");
    htmlBR();
    htmlTable("border", "0");  
    for ($mai=0; $mai<=$#{$g_message{'attachments'}}; $mai++) {
      htmlTableRow();
      htmlTableData("valign", "top");
      $key = "_include" . $mai;
      formInput("type", "checkbox", "name", $key, "value", "yes",
                "_OTHER_", "CHECKED");    
      htmlTableDataClose();
      htmlTableData("valign", "top");
      $a_num = $MAILMANAGER_ATTACHMENT_NUMBER;
      $id = $mai + 1;
      $a_num =~ s/__NUM__/$id/;
      $a_type = (split(/\;/, $g_message{'attachments'}[$mai]->{'content-type'}))[0] || "???";
      $a_enc = $g_message{'attachments'}[$mai]->{'content-transfer-encoding'};
      $a_disp = $g_message{'attachments'}[$mai]->{'content-disposition'};
      $a_size = $g_message{'attachments'}[$mai]->{'__filepos_end__'} -
                $g_message{'attachments'}[$mai]->{'__filepos_body__'};
      if ($a_size < 1024) {
        $a_size = sprintf("%s $BYTES", $a_size);
      }
      elsif ($a_size < 1048576) {
        $a_size = sprintf("%1.1f $KILOBYTES", ($a_size / 1024));
      }
      else {
        $a_size = sprintf("%1.2f $MEGABYTES", ($a_size / 1048576));
      }
      $string = "$a_num";
      if ($a_disp) {
        $a_disp =~ s/attachment; //;
        $a_disp =~ s/inline; //;
        $a_disp =~ s/filename=/$MAILMANAGER_CONTENT_DISPOSITION_FILENAME=/;
        if ($languagepref eq "ja") {
          $a_disp = mailmanagerMimeDecodeHeaderJP_QP($a_disp);
          $a_disp = jcode'euc(mimedecode($a_disp));
        }
        $string .= "; $a_disp";
      }
      htmlText($string);
      print "&#160;&#160;";
      $string = "action=vma&attachment=$id";
      $title = $MAILMANAGER_ATTACHMENT_VIEW_SEPARATELY_HELP;
      $title =~ s/\s+/\ /g;
      $title =~ s/__TYPE__/$a_type/;
      htmlAnchor("target", "_blank", "href", "$ENV{'SCRIPT_NAME'}?$string",
                 "title", $title);
      htmlAnchorText(">>> $MAILMANAGER_ATTACHMENT_VIEW_SEPARATELY <<<");
      htmlAnchorClose();
      htmlBR();
      $string = "$MAILMANAGER_ATTACHMENT_TYPE: $a_type; ";
      if ($a_enc) {
        $string .= "$MAILMANAGER_ATTACHMENT_ENCODING: $a_enc; ";
      }
      $string .= "$MAILMANAGER_ATTACHMENT_SIZE: $a_size";
      htmlText($string);
      htmlTableDataClose();
      htmlTableRowClose();
    } 
    htmlTableClose();
    htmlBR();
  }
  formInput("type", "submit", "name", "submit", "value", $SUBMIT_STRING);
  formInput("type", "reset", "value", $RESET_STRING);
  htmlP();
  htmlTable("cellpadding", "0", "cellspacing", "0",
            "border", "0", "bgcolor", "#999999", "width", "100\%");
  htmlTableRow();
  htmlTableData();
  htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  htmlTextBold($MAILMANAGER_MESSAGE_UPLOAD_ATTACHMENTS);
  htmlBR();
  htmlTable();
  $size = formInputSize(50);
  for ($index=1; $index<=2; $index++) {
    htmlTableRow();
    htmlTableData("valign", "middle");
    htmlText("$index\.");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    $key = "fileupload$index";
    formInput("type", "file", "name", $key, "size", $size);
    htmlTableDataClose();
    htmlTableRowClose();
  }
  htmlTableClose();
  htmlP();
  if ($g_users{$g_auth{'login'}}->{'ftp'}) {
    htmlTextBold($MAILMANAGER_MESSAGE_LOCAL_ATTACHMENTS);
    print <<ENDTEXT;
<script language="JavaScript1.1">
</script>
<noscript>
ENDTEXT
    htmlText("&#160; &#160; &#160; &#160; [&#160;");
    $title = $MAILMANAGER_MESSAGE_LOCAL_ATTACHMENTS_BROWSE_HELP;
    $title =~ s/\s+/\ /g;
    htmlAnchor("target", "browseWin", "href", "filemanager.cgi", 
               "title", $title);
    htmlAnchorText($MAILMANAGER_MESSAGE_LOCAL_ATTACHMENTS_BROWSE);
    htmlAnchorClose();
    htmlText("&#160;]");
    print "\n</noscript>\n";
    htmlBR();
    htmlTable();
    for ($index=1; $index<=2; $index++) {
      htmlTableRow();
      htmlTableData("valign", "middle");
      htmlText("$index\.");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      $key = "filelocal$index";
      formInput("name", $key, "size", $size, "value", $g_form{$key});
      htmlTableDataClose();
      $authval = ($g_auth{'type'} eq "form") ? "&AUTH=$g_auth{'KEY'}" : "";
      print <<ENDTEXT;
<script language="JavaScript1.1">
<!--
  function fileSelect_$index()
  {
    var auth = "$authval";
    var path = document.formfields.filelocal$index.value;
    var url = "mm_select.cgi?localattach=$index&destfile=" + path + auth;
    var options = \"width=575,height=375,\";
    options += \"resizable=yes,scrollbars=yes,status=yes,\";
    options += \"menubar=no,toolbar=no,location=no,directories=no\";
    var selectWin = window.open(url, 'selectWin', options);
    selectWin.opener = self;
    selectWin.focus();
  }
  document.write("<td>");
  document.write("<font face=\\\"arial, helvetica\\\" size=\\\"2\\\">");
  document.write("[&#160;");
  document.write("<a onClick=\\\"fileSelect_$index(); return false\\\" ");
  document.write("onMouseOver=\\\"window.status='$MAILMANAGER_MESSAGE_LOCAL_ATTACHMENTS_BROWSE: $MAILMANAGER_MESSAGE_LOCAL_ATTACHMENTS ($index)'; return true\\\" ");
  document.write("onMouseOut=\\\"window.status=''; return true\\\" ");
  document.write("title=\\\"$title\\\" ");
  document.write("href=\\\"mm_select.cgi?localattach=$index\\\">");
  document.write("$MAILMANAGER_MESSAGE_LOCAL_ATTACHMENTS_BROWSE");
  document.write("</a>");
  document.write("&#160;]");
  document.write("</font>");
  document.write("</td>");
//-->
</script>
ENDTEXT
      htmlTableRowClose();
    }
    htmlTableClose();
    htmlP();
  }
  htmlTableClose();
  htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
  htmlTableRow();
  htmlTableData("valign", "top");
  formInput("type", "submit", "name", "submit", "value", $SUBMIT_STRING);
  formInput("type", "reset", "value", $RESET_STRING);
  formClose();
  htmlTableDataClose();
  htmlTableData("valign", "top");
  # put cancel in its own form so that files aren't uploaded
  formOpen();
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "action", "value", "store_message");
  htmlText("&#160;");
  formInput("type", "submit", "name", "proceed", "value", $CANCEL_STRING);
  formClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();

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

sub mailmanagerAutoresponderEditModeForm
{
  local($title, $ar_mode);

  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_AUTOREPLY_MODE";
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);

  #
  # autoresponder edit mode table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_AUTOREPLY_TITLE : $MAILMANAGER_AUTOREPLY_MODE");
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

  $ar_mode = mailmanagerAutoresponderGetMode();

  htmlText($MAILMANAGER_AUTOREPLY_MODE_HELP);
  htmlP();
  formOpen();
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "action", "value", "set_mode");
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "radio", "name", "mode", "value", "autoreply", 
            "_OTHER_", (($ar_mode ne "vacation") ? "CHECKED" : ""));
  htmlText("&#160;$MAILMANAGER_AUTOREPLY_MODE_AUTOREPLY");
  htmlBR();
  htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "radio", "name", "mode", "value", "vacation",
            "_OTHER_", (($ar_mode eq "vacation") ? "CHECKED" : ""));
  htmlText("&#160;$MAILMANAGER_AUTOREPLY_MODE_VACATION");
  htmlP();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "submit", "name", "proceed", "value", 
            $MAILMANAGER_AUTOREPLY_MODE_SET);
  formInput("type", "submit", "name", "proceed", "value", $CANCEL_STRING);
  formClose();
  htmlP();

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

sub mailmanagerAutoresponderGetMode
{
  local($mode, $path, $filters_active, $homedir);

  # returns one of ("n/a", "vacation", "autoreply")

  $homedir = $g_users{$g_auth{'login'}}->{'home'};

  # check .forward first
  if (-e "$homedir/.forward") {
    open(MYFP, "$homedir/.forward");
    while (<MYFP>) {
      if ((/^\"/) && (/imanager.autoreply/)) {
        $mode = (/\-c\ 0/) ? "autoreply" : "vacation";
        close(MYFP);
        return($mode);
      }
    }
    close(MYFP);
  }

  if ((-e "/usr/local/bin/spamassassin") && (-e "/usr/local/bin/procmail")) {
    # check procmailrc file if filters are enabled
    $filters_active = mailmanagerSpamAssassinGetStatus();
    if ($filters_active) {
      $path = "$homedir/.procmailrc";
      if (-e "$path") {
        open(MYFP, "$path");
        while (<MYFP>) {
          if ((/^\*/) && (/imanager.autoreply/)) {
            $mode = (/\-c\ 0/) ? "autoreply" : "vacation";
            close(MYFP);
            return($mode);
          }
        }
        close(MYFP);
      }
    }
  }

  # if mode is still unknown; get last known mode
  $path = mailmanagerGetDirectoryPath("autoresponder");
  $path .= "/last.mode";
  if (-e "$path") {
    open(MFP, "$path");
    $mode = <MFP>;
    close(MFP);
    chomp($mode);
    return($mode) if ($mode);
  }

  # return default
  return("n/a");
}

##############################################################################

sub mailmanagerAutoresponderHandleRequest
{
  local($mesg, $ar_enabled, $sessionid, $tmpfilename, @pids, $index, $key);

  encodingIncludeStringLibrary("mailmanager");

  # check first for cancel requests
  if ($g_form{'proceed'} eq $CANCEL_STRING) {
    # first do some cleanup
    $sessionid = initUploadCookieGetSessionID();
    if ($sessionid) {
      if ($g_platform_type eq "virtual") {
        $tmpfilename = $g_tmpdir . "/.upload-" . $sessionid . "-pid";
        if (open(PIDFP, "$tmpfilename")) {
          while (<PIDFP>) {
            chomp;
            push(@pids, $_);
          }
          close(PIDFP);
          kill('TERM', @pids);
        }
        unlink($tmpfilename);
        for ($index=1; $index<=2; $index++) {
          $key = "fileupload$index";
          $tmpfilename = $g_tmpdir . "/.upload-" . $sessionid . "-" . $key;
          unlink($tmpfilename);
        }
      }
      else {
        HOUSEKEEPING: {
          local $> = 0;
          $tmpfilename = $g_maintmpdir . "/.upload-" . $sessionid . "-pid";
          if (open(PIDFP, "$tmpfilename")) {
            while (<PIDFP>) {
              chomp;
              push(@pids, $_);
            }
            close(PIDFP);
            kill('TERM', @pids);
          }
          unlink($tmpfilename);
          for ($index=1; $index<=2; $index++) {
            $key = "fileupload$index";
            $tmpfilename = $g_maintmpdir . "/.upload-" . $sessionid . "-" . $key;
            unlink($tmpfilename);
          }
        }
      }
    }
    # cleaning is done... redirect
    if ($g_form{'action'} eq "set_mode") {
      $mesg = $MAILMANAGER_AUTOREPLY_MODE_SET_CANCEL;
    }
    elsif ($g_form{'action'} eq "store_message") {
      $mesg = $MAILMANAGER_AUTOREPLY_CONTENT_EDIT_CANCEL;
    }
    elsif ($g_form{'action'} eq "reset_log") {
      $mesg = $MAILMANAGER_AUTOREPLY_LOG_RESET_CANCEL;
    }
    redirectLocation("mm_autoresponder.cgi", $mesg);
  }

  # process action
  if ((!$g_form{'action'}) ||
      ($g_form{'action'} eq $MAILMANAGER_AUTOREPLY_RETURN)) {
    mailmanagerAutoresponderDisplaySummary();
  }
  elsif (($g_form{'action'} eq "enable") ||
         ($g_form{'action'} eq $MAILMANAGER_AUTOREPLY_ENABLE)) {
    mailmanagerAutoresponderSanityCheck("enable");
    mailmanagerAutoresponderSetStatus("enable");
  }
  elsif (($g_form{'action'} eq "disable") ||
         ($g_form{'action'} eq $MAILMANAGER_AUTOREPLY_DISABLE)) {
    mailmanagerAutoresponderSanityCheck("disable");
    mailmanagerAutoresponderSetStatus("disable");
  }
  elsif (($g_form{'action'} eq "set_mode") ||
         ($g_form{'action'} eq $MAILMANAGER_AUTOREPLY_MODE_SET)) {
    $ar_enabled = mailmanagerNemetonAutoreplyGetStatus();
    mailmanagerAutoresponderSanityCheck("set_mode") if ($ar_enabled);
    mailmanagerAutoresponderSetMode();
  }
  elsif (($g_form{'action'} eq "edit_mode") ||
         ($g_form{'action'} eq $MAILMANAGER_AUTOREPLY_MODE_CHANGE)) {
    mailmanagerAutoresponderEditModeForm();
  }
  elsif (($g_form{'action'} eq "edit_message") ||
         ($g_form{'action'} eq $MAILMANAGER_AUTOREPLY_CONTENT_EDIT)) {
    mailmanagerAutoresponderEditMessageForm();
  }
  elsif ($g_form{'action'} eq "store_message") {
    mailmanagerAutoresponderMessageSave();
  }
  elsif (($g_form{'action'} eq "view_log") ||
         ($g_form{'action'} eq $MAILMANAGER_AUTOREPLY_LOG_VIEW)) {
    mailmanagerAutoresponderViewLog();
  }
  elsif (($g_form{'action'} eq "reset_log") ||
         ($g_form{'action'} eq $MAILMANAGER_AUTOREPLY_LOG_RESET)) {
    mailmanagerAutoresponderResetLog();
  }
  elsif ($g_form{'action'} eq "vma") {
    # view autoresponder message attachment (vma)
    mailmanagerAutoresponderViewMessageAttachment();
  }
  elsif ($g_form{'action'} eq $MAILMANAGER_RETURN) {
    redirectLocation("mailmanager.cgi");
  }
}

##############################################################################

sub mailmanagerAutoresponderMessageRead
{
  local($path, $curline, $mimemessage, $name, $value, $mai); 
  local($ctype, $boundary, $header, $curfilepos, $lastfilepos);
  local($savebody);

  # read the outgoing autoresponder message and populate into g_message hash
  $path = mailmanagerGetDirectoryPath("autoresponder");
  $path .= "/message";

  open(MFP, "$path");

  # first read the headers
  $mimemessage = 0;
  while (<MFP>) {
    $curline = $_;
    if ($curline eq "\n") {
      # that's the end of the headers
      last;
    } 
    else {
      # store message header for current message  
      push(@{$g_message{'headers'}}, $curline);
      $curline =~ s/\s+$//;
      $curline =~ /^(.*?)\:\ (.*)/;
      $name = $1;  $value = $2;
      $name =~ tr/A-Z/a-z/;
      if (($name eq "from") || ($name eq "reply-to") ||
          ($name eq "subject") || ($name eq "mime-version") || 
          ($name eq "content-type") || ($name eq "content-length") || 
          ($name eq "precedence")) {
        $value =~ s/^\s+//;
        $g_message{$name} = $value;
        if (($name eq "content-type") && ($value =~ /boundary\=/)) {
          $mimemessage = 1 
        }
      }
    }
  }

  # next read the body of the message
  if ($mimemessage) {
    # parse the message body into parts
    $ctype = $g_message{'content-type'};
    if (($ctype =~ /^multipart\/[a-z]*?\;.*boundary=\"(.*)\"/i) ||
        ($ctype =~ /^multipart\/[a-z]*?\;.*boundary=(.*)/i)) {  # no quotations
      $boundary = $1;
    }
    else {
      close(MFP);
      return;
    }
    $curfilepos = tell(MFP);
    $mai = $header = 0;
    while (<MFP>) {
      $curline = $_;
      $lastfilepos = $curfilepos;
      $curfilepos = tell(MFP);
      if (($curline =~ /^\-\-\Q$boundary\E/) && ($curline =~ /\-\-\n$/)) {
        # that's it... end of parts!  sayonara.
        $g_message{'attachments'}[$mai-1]->{'__filepos_end__'} = $lastfilepos;
        last;
      }
      elsif ($curline =~ /^\-\-\Q$boundary\E/) {
        $header = 1;
        if ($mai > 0) {
          $g_message{'attachments'}[$mai-1]->{'__filepos_end__'} = $lastfilepos;
        }
        $g_message{'attachments'}[$mai]->{'__filepos_begin__'} = $curfilepos;
      }
      elsif ($header && ($curline eq "\n")) {
        # the end of the current attachment header section
        $header = 0;
        $g_message{'attachments'}[$mai]->{'__filepos_body__'} = $curfilepos;
        $ctype = (split(/\;/, $g_message{'attachments'}[$mai]->{'content-type'}))[0];
        if ((!$g_message{'auto_body'}) &&
            (($ctype =~ /text\/plain/i) || ($ctype =~ /application\/text/i))) {
          $savebody = 1;
          %{$g_message{'attachments'}[$mai]} = ();  # empty hash
        }
        else {
          $savebody = 0;
          $mai++;
        }
      }
      elsif ($header) {
        push(@{$g_message{'attachments'}[$mai]->{'headers'}}, $curline);
        $curline =~ /^(.*?)\:\ (.*)/;
        $name = $1;
        $value = $2;
        $name =~ tr/A-Z/a-z/;
        $g_message{'attachments'}[$mai]->{$name} = $value;
      }
      else {
        # the body of the attachment
        $g_message{'auto_body'} .= $curline if ($savebody);
      }
    }
    close(MFP);
  }
  else {
    $g_message{'auto_body'} .= $_ while (<MFP>);
    close(MFP);
  }
}

##############################################################################

sub mailmanagerAutoresponderMessageSave
{
  local($path, $mimemessage, $key, $boundary, $index);
  local($string, $content_length, $numlines, $languagepref);
  local($ctype, $cdisp, $ctenc, $bfilepos, $efilepos);
  local($filename, $tmpfilename, $buffer, $encbuffer);
  local($sessionid);

  $languagepref = encodingGetLanguagePreference();

  $path = mailmanagerGetDirectoryPath("autoresponder");
  $path .= "/message";

  # read the original autoresponder message into memory...
  mailmanagerAutoresponderMessageRead();
  # ...and figure out if we need to send a mime message
  $mimemessage = 0; 
  # did user want to include attachments from original message?
  foreach $key (keys(%g_form)) {
    if (($key =~ /^_include/) && ($g_form{$key} eq "yes")) {
      $mimemessage = 1;
      last;
    }
  }
  # did the user upload any files to attach
  for ($index=1; $index<=2; $index++) {
    $key = "fileupload$index";
    next unless ($g_form{$key}->{'content-filename'});
    $mimemessage = 1;
    last;
  }
  # did the user want to attach any local files
  for ($index=1; $index<=2; $index++) {
    $key = "filelocal$index";
    if ($g_form{$key}) {
      $mimemessage = 1;
      last;
    }
  }

  if ((!$g_form{'from'}) && (!$g_form{'subject'}) &&
      (!$g_form{'reply-to'}) && ($mimemessage == 0)) {
    # blank form submission
    if (-e "$path") {
      unlink($path);
      redirectLocation("mm_autoresponder.cgi", 
                       $MAILMANAGER_AUTOREPLY_CONTENT_REMOVE_SUCCESS);
    }
    else {
      redirectLocation("mm_autoresponder.cgi"); 
    }
  }

  # open up the main file handle
  open(MSG, ">$path.save-$$") || mailmanagerResourceError(
       "open(MSG, '>$path.save-$$') failed in AutoresponderMessageSave");

  # print out the basic headers to the new message file
  if ($g_form{'from'}) {
    $string = $g_form{'from'};
    if ($languagepref eq "ja") {
      $string = mailmanagerEncodeAddressHeaderToJIS($string);
    }
    print MSG "From: $string\n"
  }
  if ($g_form{'subject'}) {
    $string = $g_form{'subject'};
    if ($languagepref eq "ja") {
      $string = mailmanagerMimeDecodeHeaderJP_QP($string);
      $string = mimeencode(jcode'jis($string));
    }
    print MSG "Subject: $string\n";
  }
  if ($g_form{'reply-to'}) {
    $string = $g_form{'reply-to'};
    if ($languagepref eq "ja") {
      $string = mailmanagerEncodeAddressHeaderToJIS($string);
    }
    print MSG "Reply-To: $string\n";
  }

  # print out the rest of the message
  # clean up the body content first
  if ($g_form{'auto_body'}) {
    $g_form{'auto_body'} =~ s/\r\n/\n/g;
    $g_form{'auto_body'} =~ s/\r//g;
    $g_form{'auto_body'} =~ s/\nFrom/\n\\From/;
    $g_form{'auto_body'} .= "\n" if ($g_form{'auto_body'} !~ /\n$/);
    if ($languagepref eq "ja") {
      $g_form{'auto_body'} = jcode'jis($g_form{'auto_body'});
    }
  }
  if ($mimemessage) {
    print MSG "Mime-Version: 1.0\n";
    $boundary = authGetRandomChars(rand(6)+0.5);
    $boundary .= $g_curtime % $$;
    $boundary .= authGetRandomChars(rand(6)+0.5);
    $boundary .= "0123456789";
    $boundary =~ s/\///g;
    $index = sprintf "%d", (rand(9)+0.5);
    $boundary =~ s/$index/\_/g;
    print MSG "Content-Type: multipart/mixed; boundary=\"$boundary\"\n";
    # save the body in a separate file first (to get Content-Length later) 
    open(BODY, ">$path.body-$$") || mailmanagerResourceError(
         "open(BODY, '>$path.body-$$') failed in AutoresponderMessageSave");
    if ($g_form{'auto_body'}) {
      print BODY "--" . $boundary . "\n";
      print BODY "Content-type: text/plain\n\n";
      print BODY $g_form{'auto_body'} . "\n";
    }
    # did user want to include attachments from original message?
    foreach $key (keys(%g_form)) {
      if (($g_form{$key} eq "yes") && ($key =~ /^_include([0-9\-\.]*)/)) {
        # include attachment
        $index = $1;
        $index--;
        $ctype = $g_message{'attachments'}[$index]->{'content-type'};
        $cdisp = $g_message{'attachments'}[$index]->{'content-disposition'};
        $ctenc = $g_message{'attachments'}[$index]->{'content-transfer-encoding'};
        $bfilepos = $g_message{'attachments'}[$index]->{'__filepos_body__'};
        $efilepos = $g_message{'attachments'}[$index]->{'__filepos_end__'};
        print BODY "--" . $boundary . "\n";
        print BODY "Content-Type: $ctype\n";
        if ($cdisp) {
          print BODY "Content-Disposition: $cdisp\n";
        }
        if ($ctenc) {
          print BODY "Content-Transfer-Encoding: $ctenc\n";
        }
        print BODY "\n";
        unless (open(MFP, "$path")) {
          mailmanagerResourceError(
              "open(MFP, $path) in mailmanagerAutoresponderMessageSave");
        }
        seek(MFP, $bfilepos, 0);
        while (read(MFP, $buffer, 1)) {
          $curfilepos = tell(MFP);
          print BODY "$buffer";
          last if ($curfilepos >= $efilepos);
        }
        close(MFP);
      }
    }
    # did user upload any files to attach
    for ($index=1; $index<=2; $index++) {
      $key = "fileupload$index";
      next unless ($g_form{$key}->{'content-filename'});
      $filename = $g_form{$key}->{'sourcepath'};
      if ($languagepref eq "ja") {
        $filename = mimeencode(jcode'jis($filename));
      }
      print BODY "--" . $boundary . "\n";
      print BODY "Content-Type: $g_form{$key}->{'content-type'}; ";
      print BODY "name=\"$filename\"\n";
      print BODY "Content-Disposition: attachment; ";
      print BODY "filename=\"$filename\"\n";
      # do we need to encode the uploaded file or not?
      if ((-T "$g_form{$key}->{'content-filename'}") &&
          ($g_form{$key}->{'content-type'} !~ /pdf$/)) {
        # plain text file
        print BODY "\n";
        open(CONTENTFP, "$g_form{$key}->{'content-filename'}");
        while (<CONTENTFP>) {
          $buffer = $_;
          $buffer =~ s/\r\n/\n/g;
          $buffer =~ s/\r//g;
          print BODY "$buffer";
        }
        close(CONTENTFP);
      }
      else {
        # binary file ... encode 54 bytes at a time
        print BODY "Content-Transfer-Encoding: base64\n";
        print BODY "\n";
        open(CONTENTFP, "$g_form{$key}->{'content-filename'}");
        while (read(CONTENTFP, $buffer, 54)) {
          $encbuffer = mailmanagerEncode64($buffer);
          print BODY "$encbuffer";
        }
        close(CONTENTFP);
      }
      unlink($g_form{$key}->{'content-filename'});
    }
    # did user want to attach any local files
    for ($index=1; $index<=2; $index++) {
      $key = "filelocal$index";
      if ($g_form{$key}) {
        $tmpfilename = mailmanagerBuildFullPath($g_form{$key});
        if (-e "$tmpfilename") {
          $filename = $g_form{$key};
          $filename =~ /([^\/]+$)/;
          $filename = $1;
          if ($languagepref eq "ja") {
            $filename = mimeencode(jcode'jis($filename));
          }
          print BODY "--" . $boundary . "\n";
          require "$g_includelib/fm_util.pl";
          $mimetype = filemanagerGetMimeType($tmpfilename);
          print BODY "Content-Type: $mimetype; ";
          print BODY "name=\"$filename\"\n";
          print BODY "Content-Disposition: attachment; ";
          print BODY "filename=\"$filename\"\n";
          # do we need to encode the uploaded file or not?
          if ((-T "$tmpfilename") && ($tmpfilename !~ /pdf$/)) {
            print BODY "\n";
            open(CONTENTFP, "$tmpfilename");
            while (read(CONTENTFP, $buffer, 1024)) {
              print BODY "$buffer";
            }
            close(CONTENTFP);
          }
          else {
            print BODY "Content-Transfer-Encoding: base64\n";
            print BODY "\n";
            open(CONTENTFP, "$tmpfilename");
            while (read(CONTENTFP, $buffer, 54)) {
              $encbuffer = mailmanagerEncode64($buffer);
              print BODY "$encbuffer";
            }
            close(CONTENTFP);
          }
        }
      }
    }
    print BODY "--" . $boundary . "--\n";
    close(BODY);
    $content_length = (stat("$path.body-$$"))[7];
    print MSG "Content-Length: $content_length\n";
    print MSG "Precedence: bulk\n";
    print MSG "\n";
    $numlines = 0;
    open(BODY, "$path.body-$$");
    print MSG $_ while(<BODY>);
    close(BODY);
    unlink("$path.body-$$");
  }
  else {
    print MSG "\n";
    print MSG "$g_form{'auto_body'}";
  }
  close(MSG);
  rename("$path.save-$$", "$path");

  # some housekeeping
  $sessionid = initUploadCookieGetSessionID();
  if ($sessionid) {
    if ($g_platform_type eq "virtual") {
      $tmpfilename = $g_tmpdir . "/.upload-" . $sessionid . "-pid";
      unlink($tmpfilename);
    }
    else {
      HOUSEKEEPING: {
        local $> = 0;
        $tmpfilename = $g_maintmpdir . "/.upload-" . $sessionid . "-pid";
        unlink($tmpfilename);
      }
    }
  }

  # redirect back to the autorepsonder summary
  redirectLocation("mm_autoresponder.cgi", 
                   $MAILMANAGER_AUTOREPLY_CONTENT_EDIT_SUCCESS);
}

##############################################################################

sub mailmanagerAutoresponderResetLog
{
  local($path);

  $path = mailmanagerGetDirectoryPath("autoresponder");

  # nuke history file
  unlink("$path/history");

  # nuke log file
  unlink("$path/log");

  # redirect back to the autorepsonder summary
  redirectLocation("mm_autoresponder.cgi", 
                   $MAILMANAGER_AUTOREPLY_LOG_RESET_SUCCESS);
}

##############################################################################

sub mailmanagerAutoresponderSanityCheck
{
  local($action) = @_;
  local(%statinfo, $path, $size, $date, $atxt);
  local($filters_active, $homedir, $idir, $sa_version);
  local($title, $subtitle);

  # function looks at ~/.forward and ~/.procmailrc and compares the size
  # and modification date to those of ~/.imanager/last.forward and 
  # ~/.imanager/last.procmailrc respectively... if there are differences,
  # then external modifications have been made (or, if this is the first
  # time the check has been made, the .forward and the .procmailrc files
  # were pre-existing).  if the check succeeds (i.e.  differences exist)
  # then the files may need to be rebuilt from the original files (which
  # are found in the ~imanager/skel directory).

  return if ($g_form{'sanitycheck'} eq "yes");

  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  $idir = mailmanagerGetDirectoryPath("autoresponder");
  $idir =~ s/[^\/]+$//g;
  $idir =~ s/\/+$//g;

  $statinfo{'forward_current'}->{'size'} = 0;
  $statinfo{'forward_current'}->{'date'} = 0;
  $statinfo{'forward_archive'}->{'size'} = 0;
  $statinfo{'forward_archive'}->{'date'} = 0;
  # forward_current
  $path = "$homedir/.forward";
  if (-e "$path") {
    ($size, $date) = (stat("$path"))[7,9];
    $statinfo{'forward_current'}->{'size'} = $size;
    $statinfo{'forward_current'}->{'date'} = $date;
  }
  # forward_archive
  $path = "$idir/last.forward";
  if (-e "$path") {
    ($size, $date) = (stat("$path"))[7,9];
  }
  else {
    ($size, $date) = (stat("$g_skeldir/dot.forward_autoreply"))[7,9];
  }
  $statinfo{'forward_archive'}->{'size'} = $size;
  $statinfo{'forward_archive'}->{'date'} = $date;

  $filters_active = mailmanagerSpamAssassinGetStatus();
  if ($filters_active) {
    $statinfo{'procmailrc_current'}->{'size'} = 0;
    $statinfo{'procmailrc_current'}->{'date'} = 0;
    $statinfo{'procmailrc_archive'}->{'size'} = 0;
    $statinfo{'procmailrc_archive'}->{'date'} = 0;
    # procmailrc_current
    $path = "$homedir/.procmailrc";
    if (-e "$path") {
      ($size, $date) = (stat("$path"))[7,9];
      $statinfo{'procmailrc_current'}->{'size'} = $size;
      $statinfo{'procmailrc_current'}->{'date'} = $date;
    }
    # procmailrc_archive
    $path = "$idir/last.procmailrc";
    if (-e "$path") {
      ($size, $date) = (stat("$path"))[7,9];
    }
    else {
      $sa_version = mailmanagerSpamAssassinGetVersion();
      if (mailmanagerSpamAssassinDaemonEnabled()) {
        ($size, $date) = (stat("$g_skeldir/dot.procmailrc_spamc"))[7,9];
      }
      else {
        ($size, $date) = (stat("$g_skeldir/dot.procmailrc"))[7,9];
      }
    }
    $statinfo{'procmailrc_archive'}->{'size'} = $size;
    $statinfo{'procmailrc_archive'}->{'date'} = $date;
  }

  if ((($statinfo{'forward_current'}->{'size'} > 0) &&
       (($statinfo{'forward_current'}->{'size'} !=
         $statinfo{'forward_archive'}->{'size'}) ||
        ($statinfo{'forward_current'}->{'date'} >
         $statinfo{'forward_archive'}->{'date'}))) ||
      ($filters_active &&
       (($statinfo{'procmailrc_current'}->{'size'} > 0) &&
        (($statinfo{'procmailrc_current'}->{'size'} !=
          $statinfo{'procmailrc_archive'}->{'size'}) ||
         ($statinfo{'procmailrc_current'}->{'date'} >
          $statinfo{'procmailrc_archive'}->{'date'}))))) {
    # something has changed externally -- print out a warning
    $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_AUTOREPLY_TITLE : ";
    if ($action eq "enable") {
      $subtitle = $MAILMANAGER_AUTOREPLY_ENABLE;
    }
    elsif ($action eq "disable") {
      $subtitle = $MAILMANAGER_AUTOREPLY_DISABLE;
    }
    else {
      $subtitle = $MAILMANAGER_AUTOREPLY_MODE_SET;
    }
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader("$title $subtitle");
    #
    # sanity check table (2 cells: sidebar, contents)
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
    htmlTextBold("&#160;$MAILMANAGER_AUTOREPLY_TITLE : $subtitle");
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
    formOpen();
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
    formInput("type", "hidden", "name", "sanitycheck", "value", "yes");
    formInput("type", "hidden", "name", "action", "value", $action);
    if ($g_form{'mode'}) {
      formInput("type", "hidden", "name", "mode", "value", $g_form{'mode'});
    }
    htmlText($MAILMANAGER_AUTOREPLY_CONFIRM_WARNING_TEXT_1);
    htmlP();
    if (($statinfo{'forward_current'}->{'size'} > 0) &&
        (($statinfo{'forward_current'}->{'size'} !=
          $statinfo{'forward_archive'}->{'size'}) ||
         ($statinfo{'forward_current'}->{'date'} >
          $statinfo{'forward_archive'}->{'date'}))) {
      # .forward externally modified
      htmlUL();
      htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_FILENAME:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      htmlText(".forward");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_CURSIZE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $size = $statinfo{'forward_current'}->{'size'};
      if ($size < 1024) {
        $size = sprintf("%s $BYTES", $size);
      }
      elsif ($size < 1048576) {
        $size = sprintf("%1.1f $KILOBYTES", ($size / 1024));
      }
      else {
        $size = sprintf("%1.2f $MEGABYTES", ($size / 1048576));
      }
      htmlText($size);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_LASTSIZE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $size = $statinfo{'forward_archive'}->{'size'};
      if ($size < 1024) {
        $size = sprintf("%s $BYTES", $size);
      }
      elsif ($size < 1048576) {
        $size = sprintf("%1.1f $KILOBYTES", ($size / 1024));
      }
      else {
        $size = sprintf("%1.2f $MEGABYTES", ($size / 1048576));
      }
      htmlText($size);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_CURDATE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $date = $statinfo{'forward_current'}->{'date'};
      $date = dateBuildTimeString("alpha", $date);
      $date = dateLocalizeTimeString($date);
      htmlText($date);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_LASTDATE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $date = $statinfo{'forward_archive'}->{'date'};
      $date = dateBuildTimeString("alpha", $date);
      $date = dateLocalizeTimeString($date);
      htmlText($date);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlULClose();
      htmlP();
    }
    if ($filters_active &&
        (($statinfo{'procmailrc_current'}->{'size'} > 0) &&
         (($statinfo{'procmailrc_current'}->{'size'} !=
           $statinfo{'procmailrc_archive'}->{'size'}) ||
          ($statinfo{'procmailrc_current'}->{'date'} >
           $statinfo{'procmailrc_archive'}->{'date'})))) {
      # .procmailrc externally modified
      htmlUL();
      htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_FILENAME:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      htmlText(".procmailrc");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_CURSIZE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $size = $statinfo{'procmailrc_current'}->{'size'};
      if ($size < 1024) {
        $size = sprintf("%s $BYTES", $size);
      }
      elsif ($size < 1048576) {
        $size = sprintf("%1.1f $KILOBYTES", ($size / 1024));
      }
      else {
        $size = sprintf("%1.2f $MEGABYTES", ($size / 1048576));
      }
      htmlText($size);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_LASTSIZE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $size = $statinfo{'procmailrc_archive'}->{'size'};
      if ($size < 1024) {
        $size = sprintf("%s $BYTES", $size);
      }
      elsif ($size < 1048576) {
        $size = sprintf("%1.1f $KILOBYTES", ($size / 1024));
      }
      else {
        $size = sprintf("%1.2f $MEGABYTES", ($size / 1048576));
      }
      htmlText($size);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_CURDATE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $date = $statinfo{'procmailrc_current'}->{'date'};
      $date = dateBuildTimeString("alpha", $date);
      $date = dateLocalizeTimeString($date);
      htmlText($date);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_LASTDATE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $date = $statinfo{'procmailrc_archive'}->{'date'};
      $date = dateBuildTimeString("alpha", $date);
      $date = dateLocalizeTimeString($date);
      htmlText($date);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlULClose();
      htmlP();
    }
    if ($action eq "enable") {
      $atxt = $MAILMANAGER_AUTOREPLY_ENABLE;
    }
    elsif ($action eq "disable") {
      $atxt = $MAILMANAGER_AUTOREPLY_DISABLE;
    }
    else {
      $atxt = $MAILMANAGER_AUTOREPLY_MODE_SET;
    }
    $MAILMANAGER_AUTOREPLY_CONFIRM_WARNING_TEXT_2 =~ s/__ACTION__/$atxt/;
    htmlText($MAILMANAGER_AUTOREPLY_CONFIRM_WARNING_TEXT_2);
    htmlP();
    formInput("type", "submit", "name", "proceed", "value",
              $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_IGNORE);
    formInput("type", "submit", "name", "proceed", "value",
              $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_RESTORE);
    formInput("type", "submit", "name", "proceed", "value", $CANCEL_STRING);
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
}

##############################################################################

sub mailmanagerAutoresponderSetMode
{
  # if mail filtering is enabled:
  #   leave HOME/.forward alone ... autoresponder will be exec'd by procmail
  #   update HOME/.procmailrc and edit autoresponder recipe block
  #
  # if mail filtering is not enabled:
  #   change HOME/.forward (according to current mode) and 
  #     link HOME/.imanager/last.forward with HOME/.forward

  local($mode, $ar_enabled, $path, $ar_command, $ar_recipe);
  local($filters_active, $homedir, $idir, $adir);

  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  $adir = mailmanagerGetDirectoryPath("autoresponder");
  $idir = $adir;
  $idir =~ s/[^\/]+$//g;
  $idir =~ s/\/+$//g;

  $mode = $g_form{'mode'};
  $ar_enabled = mailmanagerNemetonAutoreplyGetStatus();
  if ($ar_enabled) {
    # autoresponder is currently live
    $path = ($mode eq "vacation") ? "$g_skeldir/dot.forward_vacation" :
                                    "$g_skeldir/dot.forward_autoreply";
    $filters_active = mailmanagerSpamAssassinGetStatus();
    if ($filters_active) {
      # filters are enabled... do nothing to .forward file; instead, edit
      # the autoresponder recipe block in the .procmailrc file 
      # so... backup .procmailrc first
      require "$g_includelib/backup.pl";
      backupUserFile("$homedir/.procmailrc");
      # make the change according to user preference
      open(DFP, "$path");
      $ar_command = <DFP>;
      close(DFP);
      chomp($ar_command);
      $ar_command =~ s/__HOME__/$homedir/g;
      $ar_command =~ s/\/+/\//g;
      $ar_command =~ s/\"//g;
      if ($g_form{'proceed'} eq $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_IGNORE) {
        # change HOME/.procmailrc (according to specified mode)... scan 
        # current .procmailrc file and replace/insert appropriate line
        open(TFP, ">$homedir/.procmailrc.$$");
        open(SFP, "$homedir/.procmailrc");
        while (<SFP>) {
          if (/imanager.autoreply/) {
            print TFP "$ar_command\n";
          }
          else {
            print TFP $_;
          }
        } 
        close(SFP);
        close(TFP);
        rename("$homedir/.procmailrc.$$", "$homedir/.procmailrc");
        # copy .procmailrc to last.procmailrc (only require the proceed
        # and ignore conflicts warning one time... after that, it will be
        # presumed that the user has an ample supply of rope)
        open(SFP, "$homedir/.procmailrc");
        open(LFP, ">$idir/last.procmailrc");
        print LFP $_ while (<SFP>);
        close(LFP);
        close(SFP);
      }
      else {
        # rebuild HOME/.procmailrc from original file in skel and include
        # the autoresponder (according to specified mode)
        mailmanagerSpamAssassinLoadSettings();
        $ar_recipe = ":0 c\n\* \!^X-autoreply:\n$ar_command";
        open(TFP, ">$homedir/.procmailrc");
        open(LFP, ">$idir/last.procmailrc");
        $sa_version = mailmanagerSpamAssassinGetVersion();
        if (mailmanagerSpamAssassinDaemonEnabled()) {
          open(SFP, "$g_skeldir/dot.procmailrc_spamc");
        }
        else {  
          open(SFP, "$g_skeldir/dot.procmailrc");
        }
        while (<SFP>) {
          s/__USER__/$g_auth{'login'}/;
          s/__LOGFILE__/$g_filters{'logfile'}/;
          s/__LOGABSTRACT__/$g_filters{'logabstract'}/;
          s/__SPAMFOLDER__/$g_filters{'spamfolder'}/;
          s/__AUTORESPONDER__/$ar_recipe/;
          print TFP $_;
          print LFP $_;
        }
        close(SFP);
        close(LFP);
        close(TFP);
      }
      # link last.procmailrc with HOME/.procmailrc
      utime($g_curtime, $g_curtime, "$homedir/.procmailrc");
      utime($g_curtime, $g_curtime, "$idir/last.procmailrc");
    }
    else {
      # filters are not enabled... autoreply is exec'd from .forward file
      # so... backup current .forward first
      require "$g_includelib/backup.pl";
      backupUserFile("$homedir/.forward");
      # make change according to user preference
      if ($g_form{'proceed'} eq $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_IGNORE) {
        # change HOME/.forward (according to specified mode)... print out
        # appropriate pipe to autoreply as first line in .forward file and
        # scan the rest of the file and remove the old occurrence (if exists)
        open(TFP, ">$homedir/.forward.$$");
        open(SFP, "$homedir/.forward");
        open(DFP, "$path");
        $ar_command = <DFP>;
        close(DFP);
        chomp($ar_command);
        $ar_command =~ s/__HOME__/$homedir/g;
        $ar_command =~ s/\/+/\//g;
        print TFP "$ar_command\n";
        while (<SFP>) {
          next if (/imanager.autoreply/);
          print TFP $_;
        } 
        close(SFP);
        close(TFP);
        rename("$homedir/.forward.$$", "$homedir/.forward");
        # copy .forward to last.forward (only require the proceed and
        # ignore conflicts warning one time... after that, it will be
        # presumed that the user has an ample supply of rope)
        open(SFP, "$homedir/.forward");
        open(LFP, ">$idir/last.forward");
        print LFP $_ while (<SFP>);
        close(LFP);
        close(SFP);
      }
      else {
        # change HOME/.forward (according to specified mode)... use
        # original file from skel and build new .forward file
        open(TFP, ">$homedir/.forward"); 
        open(LFP, ">$idir/last.forward"); 
        open(SFP, "$path");
        while (<SFP>) {
          s/__HOME__/$homedir/g;
          s/__USER__/$g_auth{'login'}/g;
          s/\/+/\//g;
          print TFP $_;
        }
        close(SFP);
        close(LFP);
        close(TFP);
      }
      # link last.forward with HOME/.forward
      utime($g_curtime, $g_curtime, "$homedir/.forward");
      utime($g_curtime, $g_curtime, "$idir/last.forward");
    }
  }

  # update the last.mode file 
  $path = "$adir/last.mode";
  open(MFP, ">$path");
  print MFP "$mode\n";
  close(MFP);

  # redirect
  redirectLocation("mm_autoresponder.cgi", 
                   $MAILMANAGER_AUTOREPLY_MODE_SET_SUCCESS);
}

##############################################################################

sub mailmanagerAutoresponderSetStatus
{
  local($action) = @_;  # is either "enable" or "disable"

  # if mail filtering is enabled:
  #   leave HOME/.forward alone ... autoresponder will be exec'd by procmail
  #   update HOME/.procmailrc and insert/remove autoresponder recipe block
  #
  # if mail filtering is not enabled:
  #   change HOME/.forward (according to current mode) and 
  #     link HOME/.imanager/last.forward with HOME/.forward

  local($ar_mode, $path, $ar_command, $ar_recipe, $mesg);
  local($filters_active, $homedir, $idir, $adir);
  local($currentblock, $insideblock, $curline);

  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  $adir = mailmanagerGetDirectoryPath("autoresponder");
  $idir = $adir;
  $idir =~ s/[^\/]+$//g;
  $idir =~ s/\/+$//g;

  $ar_mode = mailmanagerAutoresponderGetMode();
  $ar_mode = "autoreply" if ($ar_mode eq "n/a");
  $path = ($ar_mode eq "vacation") ? "$g_skeldir/dot.forward_vacation" :
                                     "$g_skeldir/dot.forward_autoreply";
  $filters_active = mailmanagerSpamAssassinGetStatus();
  if ($filters_active) {
    # filters are enabled; need to fiddle with .procmailrc instead of .forward
    # so.... backup .procmailrc first
    require "$g_includelib/backup.pl";
    backupUserFile("$homedir/.procmailrc");
    # commit changes according to user preferences
    if ($g_form{'proceed'} eq $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_IGNORE) {
      # remove the imanager.autoreply recipe if found in the current 
      # dot.procmailrc file; then (if enabling), append new recipe block
      open(SFP, "$homedir/.procmailrc");
      open(TFP, ">$homedir/.procmailrc.$$");
      $insideblock = 0;
      $currentblock = "";
      while (<SFP>) {
        $curline = $_;
        if ($curline =~ /^\:/) {
          $insideblock = 1;
          print TFP $currentblock;
          $currentblock = $curline;
        }
        elsif ($curline =~ /imanager.autoreply/) {
          $insideblock = 0;
          $currentblock = "";
        }
        elsif ($insideblock) {
          $currentblock .= $curline;
        }
        else {
          print TFP $curline;
        } 
      }
      # print out the last current block?
      print TFP $currentblock if ($currentblock !~ /imanager.autoreply/);
      close(SFP);
      if ($action eq "enable") {
        open(DFP, "$path");
        $ar_command = <DFP>;
        close(DFP);
        chomp($ar_command);
        $ar_command =~ s/__HOME__/$homedir/g;
        $ar_command =~ s/\/+/\//g;
        $ar_command =~ s/\"//g;
        $ar_recipe = ":0 c\n\* \!^X-autoreply:\n$ar_command";
        print TFP "$ar_recipe\n";
      }
      close(TFP);
      rename("$homedir/.procmailrc.$$", "$homedir/.procmailrc");
      # copy .procmailrc to last.procmailrc (only require the proceed
      # and ignore conflicts warning one time... after that, it will be
      # presumed that the user has an ample supply of rope)
      open(SFP, "$homedir/.procmailrc");
      open(LFP, ">$idir/last.procmailrc");
      print LFP $_ while (<SFP>);
      close(LFP);
      close(SFP);
    }
    else {
      # rebuild .procmailrc from the template files found in skel
      mailmanagerSpamAssassinLoadSettings();
      open(TFP, ">$homedir/.procmailrc");
      open(LFP, ">$idir/last.procmailrc");
      $sa_version = mailmanagerSpamAssassinGetVersion();
      if (mailmanagerSpamAssassinDaemonEnabled()) {
        open(SFP, "$g_skeldir/dot.procmailrc_spamc");
      }
      else {
        open(SFP, "$g_skeldir/dot.procmailrc");
      }
      while (<SFP>) {
        $curline = $_;
        $curline =~ s/__USER__/$g_auth{'login'}/;
        $curline =~ s/__LOGFILE__/$g_filters{'logfile'}/;
        $curline =~ s/__LOGABSTRACT__/$g_filters{'logabstract'}/;
        $curline =~ s/__SPAMFOLDER__/$g_filters{'spamfolder'}/; 
        if (/__AUTORESPONDER__/) {
          if ($action eq "enable") {
            open(DFP, "$path");
            $ar_command = <DFP>;
            close(DFP);
            chomp($ar_command);
            $ar_command =~ s/__HOME__/$homedir/g;
            $ar_command =~ s/\/+/\//g;
            $ar_command =~ s/\"//g;
            $ar_recipe = ":0 c\n\* \!^X-autoreply:\n$ar_command";
            $curline =~ s/__AUTORESPONDER__/$ar_recipe/;
          }
          else {
            $curline =~ s/__AUTORESPONDER__//;
          }
        }
        print TFP $curline;
        print LFP $curline;
      }
      close(SFP);
      close(LFP);
      close(TFP);
    }
    # link last.procmailrc with HOME/.procmailrc
    utime($g_curtime, $g_curtime, "$homedir/.procmailrc");
    utime($g_curtime, $g_curtime, "$idir/last.procmailrc");
  }
  else {
    # filters are not enabled; only need to make changes to .forward file
    # so.... backup .forward first
    require "$g_includelib/backup.pl";
    backupUserFile("$homedir/.forward");
    # commit changes according to user preferences
    if ($g_form{'proceed'} eq $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_IGNORE) {
      # change HOME/.forward (according to current mode)... scan 
      # current .forward file and remove/replace/insert appropriate line
      open(TFP, ">$homedir/.forward.$$");
      open(SFP, "$homedir/.forward");
      if ($action eq "enable") {
        open(DFP, "$path");
        $ar_command = <DFP>;
        close(DFP);
        chomp($ar_command);
        $ar_command =~ s/__HOME__/$homedir/g;
        $ar_command =~ s/\/+/\//g;
        print TFP "$ar_command\n";
      }
      while (<SFP>) {
        next if (/imanager.autoreply/);
        print TFP $_;
      } 
      close(SFP);
      close(TFP);
      rename("$homedir/.forward.$$", "$homedir/.forward");
      # copy .forward to last.forward (only require the proceed and
      # ignore conflicts warning one time... after that, it will be
      # presumed that the user has an ample supply of rope)
      open(SFP, "$homedir/.forward");
      open(LFP, ">$idir/last.forward");
      print LFP $_ while (<SFP>);
      close(LFP);
      close(SFP);
      # link last.forward with HOME/.forward
      utime($g_curtime, $g_curtime, "$homedir/.forward");
      utime($g_curtime, $g_curtime, "$idir/last.forward");
    }
    else {
      # rebuild from the template files found in skel
      if ($action eq "enable") {
        # change HOME/.forward (according to current mode)... use
        # original file from skel and build new .forward file
        open(TFP, ">$homedir/.forward"); 
        open(LFP, ">$idir/last.forward"); 
        open(SFP, "$path");
        while (<SFP>) {
          s/__HOME__/$homedir/g;
          s/__USER__/$g_auth{'login'}/g;
          s/\/+/\//g;
          print TFP $_;
          print LFP $_;
        }
        close(SFP);
        close(LFP);
        close(TFP);
        # link last.forward with HOME/.forward
        utime($g_curtime, $g_curtime, "$homedir/.forward");
        utime($g_curtime, $g_curtime, "$idir/last.forward");
      }
      else {  # disable
        # nuke HOME/.forward and last.forward files
        unlink("$homedir/.forward");
        unlink("$idir/last.forward");
      }
    }
  }

  # nuke history file whenever autoresponder status changes
  unlink("$adir/history");

  # save autoresponder mode if applicable
  $path = "$adir/last.mode";
  if (($action eq "enable") && (!(-e "$path"))) {
    open(MFP, ">$path");
    print MFP "$ar_mode\n";
    close(MFP);
  }

  # redirect
  if ($action eq "enable") {
    $mesg = $MAILMANAGER_AUTOREPLY_STATUS_SET_SUCCESS;
    $mesg =~ s/__ACTION__/$MAILMANAGER_AUTOREPLY_ENABLE/;
  }
  else {
    $mesg = $MAILMANAGER_AUTOREPLY_STATUS_SET_SUCCESS;
    $mesg =~ s/__ACTION__/$MAILMANAGER_AUTOREPLY_DISABLE/;
  }
  redirectLocation("mm_autoresponder.cgi", $mesg);
}

##############################################################################

sub mailmanagerAutoresponderViewLog
{
  local($title, $path, $size);
  local($date, $email, $header, $curline, $logtext, $adir);

  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_AUTOREPLY_TITLE";
  $title .= " : $MAILMANAGER_AUTOREPLY_LOG_VIEW";
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);

  #
  # autoresponder display summary table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_AUTOREPLY_TITLE : $MAILMANAGER_AUTOREPLY_LOG_VIEW");
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

  $adir = mailmanagerGetDirectoryPath("autoresponder");
  $path .= "$adir/log";
  ($size) = (stat("$path"))[7] if (-e "$path");
  if ((-e "$path") && ($size > 0)) {
    # show log entries
    htmlText($MAILMANAGER_AUTOREPLY_LOG_ENTRIES);
    htmlP();
    formOpen();
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
    htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
    open(LOG, "$path");
    while (<LOG>) {
      $curline = $_;
      chomp($curline);
      if ($curline =~ /(.*) msgid=\<.*\> replied to (.*)/) {
        # "replied to <__EMAIL__>" entry
        $date = $1;
        $email = $2;
        $logtext = $MAILMANAGER_AUTOREPLY_LOG_FORMAT;
        $logtext =~ s/__EMAIL__/$email/;
      }
      elsif ($curline =~ /(.*) msgid=\<.*\> suppressed reply to (.*) within interval/) {
        # "suppressed reply to __EMAIL__ within interval" entry
        $date = $1;
        $email = $2;
        $logtext = $MAILMANAGER_AUTOREPLY_LOG_SUPPRESS_DUE_TO_INTERVAL;
        $logtext =~ s/__EMAIL__/\<$email\>/;
      }
      elsif ($curline =~ /(.*) msgid=\<.*\> suppressed reply to (.*): rate exceeded/) {
        # "suppressed reply to __EMAIL__: rate exceeded" entry
        $date = $1;
        $email = $2;
        $logtext = $MAILMANAGER_AUTOREPLY_LOG_SUPPRESS_DUE_TO_RATE;
        $logtext =~ s/__EMAIL__/\<$email\>/;
      }
      elsif ($curline =~ /(.*) msgid=\<.*\> suppress response to bounce address (.*)/) {
        # "suppress response to bounce address <__EMAIL__>" entry
        $date = $1;
        $email = $2;
        $logtext = $MAILMANAGER_AUTOREPLY_LOG_SUPPRESS_BOUNCE_ADDRESS;
        $logtext =~ s/__EMAIL__/$email/;
      }
      elsif ($curline =~ /(.*) msgid=\<.*\> disallow response to (.*)/) {
        # "disallow response to __EMAIL__" entry
        $date = $1;
        $email = $2;
        $logtext = $MAILMANAGER_AUTOREPLY_LOG_DISALLOW_DUE_TO_SENDER;
        $logtext =~ s/__EMAIL__/\<$email\>/;
      }
      elsif ($curline =~ /(.*) msgid=\<.*\> disallow reply due to header (.*)/) {
        # "disallow reply due to header __HEADER__" entry
        $date = $1;
        $header = $2;
        $logtext = $MAILMANAGER_AUTOREPLY_LOG_DISALLOW_DUE_TO_HEADER;
        $logtext =~ s/__HEADER__/$header/;
      }
      elsif ($curline =~ /(.*) msgid=\<.*\> disallow reply due to value (.*)/) {
        # "disallow reply due to header __HEADER__" entry
        $date = $1;
        $header = "Precendence: $2";
        $logtext = $MAILMANAGER_AUTOREPLY_LOG_DISALLOW_DUE_TO_HEADER;
        $logtext =~ s/__HEADER__/$header/;
      }
      elsif ($curline =~ /(.*) msgid=\<.*\> (.*)/) {
        # other entry... such as a "disallow reply"
        $date = $1;
        $logtext = $2;
      }
      $date = dateLocalizeTimeString($date);
      $logtext = htmlSanitize($logtext);
      htmlTableRow();
      htmlTableData("valign", "top");
      htmlNoBR();
      htmlTextCode("&#160;$date");
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableData("valign", "top");
      htmlTextCode("&#160;=>&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "top");
      htmlTextCode("$logtext");
      htmlTableDataClose();
      htmlTableRowClose();
    }
    close(LOG);
    htmlTableClose();
    htmlP();
    formInput("type", "hidden", "name", "action", "value", "reset_log");
    formInput("type", "submit", "name", "submit", "value", 
              $MAILMANAGER_AUTOREPLY_LOG_RESET);
    formInput("type", "submit", "name", "proceed", "value", $CANCEL_STRING);
    formClose();
  }
  else {
    htmlText($MAILMANAGER_AUTOREPLY_LOG_EMPTY);
    htmlP();
    formOpen();
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
    formInput("type", "submit", "name", "action", "value", 
              $MAILMANAGER_AUTOREPLY_RETURN);
    formClose();
  }

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

sub mailmanagerAutoresponderViewMessageAttachment
{
  local($mai, $ctype, $cdisp, $ctenc);
  local($fname, $path, $adir);
  local($curline, $string, $buffer, $languagepref);
  local($bfilepos, $efilepos, $curfilepos);

  $languagepref = encodingGetLanguagePreference();

  mailmanagerAutoresponderMessageRead();

  $mai = $g_form{'attachment'};
  $mai--;
  $ctype = $g_message{'attachments'}[$mai]->{'content-type'};
  $cdisp = $g_message{'attachments'}[$mai]->{'content-disposition'};
  $ctenc = $g_message{'attachments'}[$mai]->{'content-transfer-encoding'};
  $bfilepos = $g_message{'attachments'}[$mai]->{'__filepos_body__'};
  $efilepos = $g_message{'attachments'}[$mai]->{'__filepos_end__'};

  # figure out what filename should be sent   
  if ($cdisp && ($cdisp =~ /filename=\"(.*)\"/)) {
    $fname = $1;
  }
  elsif ($cdisp && ($cdisp =~ /filename=(.*)/)) {
    $fname = $1;
  }
  elsif ($ctype && ($ctype =~ /name=\"(.*)\"/)) { 
    $fname = $1;
  }
  elsif ($ctype && ($ctype =~ /name=(.*)/)) { 
    $fname = $1;
  }
  elsif ($ctype =~ /(\w*?)\/(\w*)/) {
    $fname = $1 . "." . $2;
    $fname =~ s/plain$/txt/;
  }
  else {
    $fname = "attachment." . $mai;
  }
  if ($languagepref eq "ja") {
    $fname = mailmanagerMimeDecodeHeaderJP_QP($fname);
    $code = jcode'getcode($fname);
    if ($code eq "jis") {
      $fname = jcode::convert(\$fname, 'sjis', 'jis');
    }
    else {
      $fname = jcode'sjis(mimedecode($fname));
    }
  }

  # tweak the content type a wee bit if applicable
  $ctype .= "; name=\"$fname\"" if ($ctype !~ /name=/);

  # print out the response header
  htmlResponseHeader("Content-type: $ctype; name=\"$fname\"",
                     "Content-Disposition: attachment; filename=\"$fname\"");

  # print out the data
  $adir = mailmanagerGetDirectoryPath("autoresponder");
  $path = "$adir/message";
  unless (open(MFP, "$path")) {
    mailmanagerResourceError(
        "open(MFP, $path) in AutoresponderViewMessageAttachment");
  }
  seek(MFP, $bfilepos, 0);
  $buffer = "";
  while (<MFP>) {
    $curline = $_;
    # decode the current line
    if ($ctenc =~ /quoted-printable/i) {
      $string = mailmanagerDecodeQuotedPrintable($curline);
      $buffer .= $string;
      next if ($curline =~ /=\r?\n$/);  # keep reading the file
    }
    elsif ($ctenc =~ /base64/i) {
      $buffer = mailmanagerDecode64($curline);
    }
    else {
      $buffer = $curline;
    }
    # print out the current buffer
    if (($ctype =~ /text\//i) || ($ctype =~ /application\/text/i)) {
      # plain text ... markup as required
      if ($languagepref eq "ja") {
        $buffer = jcode'euc($buffer);
      }
    }
    print $buffer;
    $buffer = "";
    $curfilepos = tell(MFP);
    last if ($curfilepos >= $efilepos);
  } 
  close(MFP);

  exit(0);
}

##############################################################################
# eof

1;

