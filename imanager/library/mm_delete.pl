#
# mm_delete.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/mm_delete.pl,v 2.12.2.3 2006/04/25 19:48:24 rus Exp $
#
# mail manager delete message functions
#

##############################################################################

sub mailmanagerDeleteMessageConfirmForm
{
  local($nmesg, $mid, $string, $title, $languagepref, $subject);
  local($fsize, $sizetext);

  $languagepref = encodingGetLanguagePreference();

  if ($g_form{'selected'} ne "__ALL__") {
    # load up the selected message or messages
    $g_form{'messageid'} = $g_form{'selected'};
    ($nmesg) = (mailmanagerReadMail())[0];
    if ($nmesg == 0) {
      $string = $MAILMANAGER_MESSAGE_NOT_FOUND_TEXT;
      $string =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
      $string =~ s/__MESSAGEID__/$g_form{'selected'}/g;
      redirectLocation("mailmanager.cgi", $string);
    }
  }

  if ($ENV{'SCRIPT_NAME'} !~ /wizards\/mm_delete.cgi/) {
    $ENV{'SCRIPT_NAME'} =~ /wizards\/([a-z_]*).cgi$/;
    $ENV{'SCRIPT_NAME'} =~ s/$1/mm_delete/;
  }

  $MAILMANAGER_TITLE =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
  if ($g_form{'selected'} eq "__ALL__") {
    $title = $MAILMANAGER_DELETE_ALL;
  }
  elsif ($nmesg > 1) {
    $title = $MAILMANAGER_DELETE_TAGGED;
  }
  else {
    $title = $MAILMANAGER_DELETE_SINGLE;
  }
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader("$MAILMANAGER_TITLE : $title");

  #
  # delete mail message table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$g_mailbox_virtualpath : $title");
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

  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "confirm", "value", "yes");
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "selected", 
            "value", $g_form{'selected'});
  if ($g_form{'selected'} eq "__ALL__") {
    $string = $MAILMANAGER_DELETE_CONFIRM_ALL_TEXT;
    $string =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
    htmlText($string);
    htmlP();
    htmlTextItalic($MAILMANAGER_DELETE_CONFIRM_ALL_UNDONE_TEXT);
    htmlP();
    formInput("type", "submit", "name", "submit", "value",
              $MAILMANAGER_DELETE_ALL);
  }
  else {
    htmlText($MAILMANAGER_DELETE_CONFIRM_TEXT);
    htmlP();
    htmlTable();
    htmlTableRow();
    htmlTableData();
    htmlTextBold($MAILMANAGER_MESSAGE_DATE);
    htmlTableDataClose();
    htmlTableData();
    htmlTextBold($MAILMANAGER_MESSAGE_SENDER);
    htmlTableDataClose();
    htmlTableData();
    htmlTextBold($MAILMANAGER_MESSAGE_SUBJECT);
    htmlTableDataClose();
    htmlTableData("align", "right");
    htmlTextBold("&#160;$MAILMANAGER_MESSAGE_SIZE_ABBREVIATED&#160;");
    htmlTableDataClose();
    htmlTableRowClose();
    foreach $mid (sort mailmanagerByPreference(keys(%g_email))) {
      htmlTableRow();
      htmlTableData("valign", "middle");
      htmlNoBR();
      $string = "$g_email{$mid}->{'__display_date__'} ";
      $string = dateLocalizeTimeString($string);
      $string =~ s/\ /\&\#160\;/g;
      htmlText("$string&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      htmlNoBR();
      $string = "$g_email{$mid}->{'__from_name__'} ";
      $string =~ s/\ /\&\#160\;/g;
      if ($languagepref eq "ja") {
        $string = mailmanagerMimeDecodeHeaderJP_QP($string);
        $string = jcode'euc(mimedecode($string));
      }
      htmlText("$string&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      htmlNoBR();
      $string = "mbox=";
      $string .= encodingStringToURL($g_form{'mbox'});
      $string .= "&mpos=$g_form{'mpos'}&mrange=$g_form{'mrange'}&msort=$g_form{'msort'}&messageid=";
      $string .= encodingStringToURL($mid);
      if ($g_email{$mid}->{'subject'}) {
        $subject = $g_email{$mid}->{'subject'};
        if ($languagepref eq "ja") {
          $subject = mailmanagerMimeDecodeHeaderJP_QP($subject);
          $subject = jcode'euc(mimedecode($subject));
        }
        $subject = mailmanagerMimeDecodeHeader($subject);
        if (($languagepref ne "ja") && (length($subject) > 60)) {
          $subject = substr($subject, 0, 59) . "&#133;";
        }
      }
      else {
        $subject = $MAILMANAGER_NO_SUBJECT;
      }
      $title = $MAILMANAGER_MESSAGE_VIEW;
      $title =~ s/__SUBJECT__/$subject/;
      htmlAnchor("href", "mailmanager.cgi?$string", "title", $title);
      htmlAnchorText($subject);
      htmlAnchorClose();
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "right");
      $fsize = $g_email{$mid}->{'__size__'};
      if ($fsize < 1048576) {
        $sizetext = sprintf("%1.1f $KILOBYTES", ($fsize / 1024));
      } 
      else {
        $sizetext = sprintf("%1.2f $MEGABYTES", ($fsize / 1048576));
      }
      htmlNoBR();
      htmlText("&#160;&#160;$sizetext&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableRowClose();
    }
    htmlTableClose();
    htmlP();
    if ($nmesg == 1) {
      formInput("type", "submit", "name", "submit", "value",
                $MAILMANAGER_DELETE_SINGLE);
    }
    else {
      formInput("type", "submit", "name", "submit", "value",
                $MAILMANAGER_DELETE_TAGGED);
    }
  }
  formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
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

sub mailmanagerDeleteSelectedMessages
{
  local($curmessageid, $tmpmessageid);
  local(@selected_mids, $smid, $message_is_not_selected, $msgcount);
  local($tmpfile, $mbox, $curline, $header, @curheaders, $index);
  local(%existing_mids, $errmsg, $curpos);

  $mbox = $g_mailbox_fullpath;
  $mbox =~ s/\//\_/g;
  $tmpfile = "$g_tmpdir/.mailbox-" . $g_auth{'login'};
  $tmpfile .= "-" . $g_curtime . "-" . $$ . $mbox;

  # open source mailbox read only; tmp mailbox write only
  open(SFP, "$g_mailbox_fullpath") ||
    mailmanagerResourceError("open(SFP, $g_mailbox_virtualpath)");
  open(TFP, "+<$g_mailbox_fullpath") ||
    mailmanagerResourceError("open(TFP, $g_mailbox_virtualpath)");

  # prime the error message
  $errmsg = "hard failure in mailmanagerDeleteSelectedMessages ... ";
  $errmsg .= "server quota exceeded?";

  # step through the mailbox if necessary
  if ($g_form{'selected'} ne "__ALL__") {
    @selected_mids = split(/\|\|\|/, $g_form{'selected'});
    # march through the mailbox
    $msgcount = 1;
    $curmessageid = "";
    $header = 0;
    $message_is_not_selected = 1;
    @curheaders = ();
    while (<SFP>) {
      $curline = $_;
      # look for message demarcation lines in the format of
      #     "From sender@domain wday mon day hour:min:sec year"
      if ($curline =~ /^From\ ([^\s]*)\s+(Mon|Tue|Wed|Thu|Fri|Sat|Sun)\s(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+([0-9]*)\s([0-9]*):([0-9]*):([0-9]*)\s([0-9]*)/) {
        # store a temporary message id
        $tmpmessageid = $msgcount;
        # reset important variables
        $curmessageid = "";
        $header = 1;
        push(@curheaders, $curline);
        $msgcount++;
      }
      elsif ($header && ($curline eq "\n")) {
        # that's the end of the headers for the current message... what next?
        # if we don't have a curmessageid then use the tmpmessageid.  the
        # tmpmessageid is simply the order of the message in the file... this
        # may cause problems with coherency... but I can't think of any other
        # way keep track of a unique message id when no 'Message-Id' headers
        # are found in the message file.  my poor feeble brain.
        $curmessageid = $tmpmessageid unless ($curmessageid);
        $existing_mids{$curmessageid} = "dau!";
        # now check to see if the current messageid matches the one we are
        # looking for... that is, if we are looking for any in particular
        $message_is_not_selected = 1;
        foreach $smid (@selected_mids) {
          if ($smid eq $curmessageid) {
            $message_is_not_selected = 0;
            last;
          }
        }
        if ($curmessageid && $message_is_not_selected) {
          for ($index=0; $index<=$#curheaders; $index++) {
            print TFP "$curheaders[$index]" || 
              mailmanagerResourceError($errmsg);
          }
          print TFP "$curline" || mailmanagerResourceError($errmsg);
        }
        # reset important variables
        $header = 0;
        @curheaders = ();
      }
      elsif ($header) {
        # message header for current message
        push(@curheaders, $curline);
        $curheader = $curline;
        $curheader =~ s/\s+$//; 
        if ($curheader =~ /^message-id:\ +(.*)/i) {
          # found a 'Message-Id' header... this makes a nice hash key
          $curmessageid = $1;
          if (defined($existing_mids{$curmessageid})) {
            # only use Message-Id if it isn't already defined (this can occur
            # when the same message is saved to a folder more than once)
            $curmessageid = "";
          }
        }   
      }
      else {
        # body of a message
        if ($curmessageid && $message_is_not_selected) {
          print TFP "$curline" || mailmanagerResourceError($errmsg);
        }
      }
    }
  }

  # close the file handles and truncate
  close(SFP);
  $curpos = tell(TFP);
  truncate(TFP, $curpos);
  close(TFP);
}

##############################################################################

sub mailmanagerHandleDeleteMessageRequest
{
  encodingIncludeStringLibrary("mailmanager");

  $g_form{'confirm'} = "no" if (!$g_form{'confirm'});
  if (($g_form{'confirm'} ne "yes") &&
      (($g_prefs{'mail__confirm_message_remove'} eq "yes") ||
       ($g_form{'selected'} eq "__ALL__"))) {  # always confirm delete all
    mailmanagerDeleteMessageConfirmForm();
  }

  if ($g_form{'submit'} eq "$CANCEL_STRING") {
    redirectLocation("mailmanager.cgi", $MAILMANAGER_DELETE_CANCEL_TEXT);
  }

  mailmanagerDeleteSelectedMessages();

  # reset messageid to "" and redirect
  $g_form{'selected'} = "" if ($g_form{'selected'});
  $g_form{'messageid'} = "" if ($g_form{'messageid'});
  redirectLocation("mailmanager.cgi", $MAILMANAGER_DELETE_SUCCESS_TEXT);
}

##############################################################################
# eof

1;

