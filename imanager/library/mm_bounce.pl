#
# mm_bounce.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/mm_bounce.pl,v 2.12.2.4 2006/04/25 19:48:24 rus Exp $
#
# bounce message functions
#

##############################################################################

sub mailmanagerBounceMessage
{
  local($mid, $nlines, $index, $curheader, $curdate, $statusmsg);
  local($buffer, $messagefilename, $sendmail_args, $errmsg, $homedir);

  # build a filename which will store the message; we don't store messages
  # in memory any longer to keep the memory use as light as possible
  $messagefilename = $g_tmpdir . "/.message-" . $g_curtime . "-" . $$;
  $messagefilename .= "_bounce";
  open(MESSAGE, ">$messagefilename") || mailmanagerResourceError(
     "open(MESSAGE, '>$messagefilename') failed in mailmanagerBounceMessage");

  # prime the error message
  $errmsg = "write failed in mailmanagerBounceMessage() -- ";
  $errmsg .= "check available disk space";

  # bounce the message as-is... just add a few additional headers
  $mid = $g_form{'messageid'};
  unless (print MESSAGE "From $g_email{$mid}->{'__delivered_from__'}") {
    close(MESSAGE);
    mailmanagerResourceError($errmsg);
  }
  unless (print MESSAGE " $g_email{$mid}->{'__delivered_date__'}\n") {
    close(MESSAGE);
    mailmanagerResourceError($errmsg);
  }
  $nlines = $#{$g_email{$mid}->{'headers'}};
  for ($index=0; $index<=$nlines; $index++) {
    $curheader = $g_email{$mid}->{'headers'}[$index];
    next if ($curheader =~ /^__/);
    next if ($curheader =~ /^\>/);
    next if ($curheader =~ /^Resent-To: /);
    next if ($curheader =~ /^Resent-From: /);
    next if ($curheader =~ /^Resent-Date: /);
    next if ($curheader =~ /^Status: /);
    next if ($curheader =~ /^X-Resent-By: /);
    next if ($curheader =~ /^X-Remote-Addr: /);
    next if ($curheader =~ /^X-Remote-Host: /);
    unless (print MESSAGE "$curheader\n") {
      close(MESSAGE);
      mailmanagerResourceError($errmsg);
    }
  }
  unless (print MESSAGE "Resent-To: $g_form{'send_to'}\n") {
    close(MESSAGE);
    mailmanagerResourceError($errmsg);
  }
  unless (print MESSAGE "Resent-From: $g_form{'send_from'}\n") {
    close(MESSAGE);
    mailmanagerResourceError($errmsg);
  }
  $curdate = dateBuildTimeString("numeric");
  unless (print MESSAGE "Resent-Date: $curdate\n") {
    close(MESSAGE);
    mailmanagerResourceError($errmsg);
  }
  require "$g_includelib/info.pl";
  infoLoadVersion();
  unless (print MESSAGE "X-Resent-By: $g_info{'version'}\n") {
    close(MESSAGE);
    mailmanagerResourceError($errmsg);
  }
  unless (print MESSAGE "X-Remote-Addr: $ENV{'REMOTE_ADDR'}\n") {
    close(MESSAGE);
    mailmanagerResourceError($errmsg);
  }
  if ($ENV{'REMOTE_HOST'}) {
    unless (print MESSAGE "X-Remote-Host: $ENV{'REMOTE_HOST'}\n") {
      close(MESSAGE);
      mailmanagerResourceError($errmsg);
    }
  }
  unless (print MESSAGE "\n") {
    close(MESSAGE);
    mailmanagerResourceError($errmsg);
  }
  # print out the body of the message
  unless (open(MFP, "$g_mailbox_fullpath")) {
    close(MESSAGE);
    mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
  }
  seek(MFP, $g_email{$mid}->{'__filepos_message_body__'}, 0);
  for ($index=$g_email{$mid}->{'__filepos_message_body__'};
       $index<$g_email{$mid}->{'__filepos_message_end__'};
       $index++) {
    read(MFP, $buffer, 1);
    unless (print MESSAGE $buffer) {
      close(MFP);
      close(MESSAGE);
      mailmanagerResourceError($errmsg);
    }
  }
  close(MFP);
  close(MESSAGE);

  # bounce the message
  # -oi: ignore dots in incoming message
  # -oem: mail back errors
  # -f: set the name of the from person
  $sendmail_args = "-oi -oem -f$g_auth{'login'} $g_form{'send_to'}";
  $statusmsg = mailmanagerInvokeSendmail($sendmail_args, $messagefilename);

  # store 'from' email address to last.emailaddress 
  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  if (open(LEFP, ">$homedir/.imanager/last.emailaddress.$$")) {
    print LEFP "$g_form{'send_from'}\n";
    close(LEFP);
    rename("$homedir/.imanager/last.emailaddress.$$",
           "$homedir/.imanager/last.emailaddress");
  }

  # redirect
  $MAILMANAGER_SEND_SUCCESS_BOUNCE =~ s/__ADDRESS__/$g_form{'send_to'}/;
  $statusmsg = $MAILMANAGER_SEND_SUCCESS_BOUNCE unless ($statusmsg);
  redirectLocation("mailmanager.cgi", $statusmsg);
}

##############################################################################

sub mailmanagerBounceMessageForm
{
  local(@errors) = @_;
  local($size, $send_to, $string, $subject);
  local($javascript, $languagepref);

  $languagepref = encodingGetLanguagePreference();

  htmlResponseHeader("Content-type: $g_default_content_type");
  $MAILMANAGER_TITLE =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
  $string = "$MAILMANAGER_TITLE : ";
  if ($g_email{$g_form{'messageid'}}->{'subject'}) {
    $subject = $g_email{$g_form{'messageid'}}->{'subject'};
    if ($languagepref eq "ja") {
      $subject = mailmanagerMimeDecodeHeaderJP_QP($subject);
      $subject = jcode'euc(mimedecode($subject));
    }
    $subject = mailmanagerMimeDecodeHeader($subject);
  }
  else {
    $subject = $MAILMANAGER_NO_SUBJECT;
  }
  $string .= $subject;
  $string .= " : $MAILMANAGER_BOUNCE";
  $javascript = javascriptCheckMessageFields();
  labelCustomHeader($string, "", $javascript);

  if ($#errors > -1) {
    foreach $string (@errors) {
      htmlTextColorBold($string, "#cc0000");
      htmlBR();
    }
    htmlP();
  }

  #
  # bounce mail message table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_BOUNCE : $subject");
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

  formOpen("method", "POST", "name", "formfields"); 
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "messageid", "value", 
            $g_form{'messageid'});
  htmlTable("border", "0", "cellpadding", "0", "cellspacing", "1",
            "bgcolor", "#000000");
  htmlTableRow();
  htmlTableData("bgcolor", "#ffffff");
  htmlTextBold("&#160;$MAILMANAGER_BOUNCE_ORIGINAL_MESSAGE");
  htmlTableDataClose();
  htmlTableRowClose();
  # to
  htmlTableRow();
  htmlTableData("bgcolor", "#ffffff");
  htmlTable("border", "0", "cellpadding", "0", "cellspacing", "1", 
            "width", "100%");
  htmlTableRow();
  htmlTableData("valign", "top");
  htmlNoBR();
  htmlTextBold("&#160;$MAILMANAGER_MESSAGE_TO\:&#160;&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("valign", "top");
  $string = $g_email{$g_form{'messageid'}}->{'to'};
  if ($languagepref eq "ja") {
    $string = mailmanagerMimeDecodeHeaderJP_QP($string);
    $string = jcode'euc(mimedecode($string));
  }
  htmlText($string);
  htmlTableDataClose();
  htmlTableRowClose();
  # date
  htmlTableRow();
  htmlTableData("valign", "top");
  htmlNoBR();
  htmlTextBold("&#160;$MAILMANAGER_MESSAGE_DATE\:&#160;&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("valign", "top");
  $string = dateLocalizeTimeString($g_email{$g_form{'messageid'}}->{'date'});
  htmlText("$string&#160;");
  htmlTableDataClose();
  htmlTableRowClose();
  # from
  htmlTableRow();
  htmlTableData("valign", "top");
  htmlNoBR();
  htmlTextBold("&#160;$MAILMANAGER_MESSAGE_SENDER\:&#160;&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("valign", "top");
  $string = $g_email{$g_form{'messageid'}}->{'from'} ||
            $g_email{$g_form{'messageid'}}->{'__delivered_from__'};
  if ($languagepref eq "ja") {
    $string = mailmanagerMimeDecodeHeaderJP_QP($string);
    $string = jcode'euc(mimedecode($string));
  }
  htmlText("$string&#160;");
  htmlTableDataClose();
  htmlTableRowClose();
  if ($g_email{$g_form{'messageid'}}->{'reply-to'}) {
    # reply-to
    htmlTableRow();
    htmlTableData("valign", "top");
    htmlNoBR();
    htmlTextBold("&#160;$MAILMANAGER_MESSAGE_REPLY_TO\:&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("valign", "top");
    $string = $g_email{$g_form{'messageid'}}->{'reply-to'};
    if ($languagepref eq "ja") {
      $string = mailmanagerMimeDecodeHeaderJP_QP($string);
      $string = jcode'euc(mimedecode($string));
    }
    htmlText("$string&#160;");
    htmlTableDataClose();
    htmlTableRowClose();
  }
  # subject
  htmlTableRow();
  htmlTableData("valign", "top");
  htmlNoBR();
  htmlTextBold("&#160;$MAILMANAGER_MESSAGE_SUBJECT\:&#160;&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("valign", "top");
  htmlText("$subject&#160;");
  htmlTableDataClose();
  htmlTableRowClose();
  #if ($g_email{$g_form{'messageid'}}->{'cc'}) {
  #  # cc
  #  htmlTableRow();
  #  htmlTableData("valign", "top");
  #  htmlNoBR();
  #  htmlTextBold("&#160;$MAILMANAGER_MESSAGE_CC\:&#160;&#160;");
  #  htmlNoBRClose();
  #  htmlTableDataClose();
  #  htmlTableData("valign", "top");
  #  $string = $g_email{$g_form{'messageid'}}->{'cc'};
  #  if ($languagepref eq "ja") {
  #    $string = mailmanagerMimeDecodeHeaderJP_QP($string);
  #    $string = jcode'euc(mimedecode($string));
  #  }
  #  htmlText("$string&#160;");
  #  htmlTableDataClose();
  #  htmlTableRowClose();
  #}
  # size
  htmlTableRow();
  htmlTableData("valign", "top");
  htmlNoBR();
  htmlTextBold("&#160;$MAILMANAGER_MESSAGE_SIZE_ABBREVIATED\:&#160;&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("valign", "top");
  htmlText("$g_email{$g_form{'messageid'}}->{'__size__'} $BYTES&#160;");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  htmlText($MAILMANAGER_BOUNCE_HELP_TEXT);
  htmlBR();
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  htmlTable();
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$MAILMANAGER_MESSAGE_TO\:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $send_to = "";
  if ($g_form{'send_to'}) {
    $send_to = $g_form{'send_to'};
  }
  elsif (($type eq "reply") || ($type eq "groupreply")) { 
    $send_to = $g_email{$g_form{'messageid'}}->{'reply-to'} ||
               $g_email{$g_form{'messageid'}}->{'from'} ||
               $g_email{$g_form{'messageid'}}->{'__delivered_from__'};
  }
  if ($languagepref eq "ja") {
    $send_to = mailmanagerMimeDecodeHeaderJP_QP($send_to);
    $send_to = jcode'euc(mimedecode($send_to));
  }
  $size = formInputSize(40);
  formInput("size", $size, "name", "send_to", "value", $send_to);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$MAILMANAGER_MESSAGE_SENDER\:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  if ($g_form{'send_from'}) {
    $string = $g_form{'send_from'};
  }
  else {
    $string = mailmanagerUserEmailAddress();
  }
  formInput("size", $size, "name", "send_from", "value", $string);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  formInput("type", "submit", "name", "submit", "value", $MAILMANAGER_SEND,
            "onClick", "return verify();");
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
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

sub mailmanagerCheckBounceMessageComposition
{
  local(@errors); 

  # check the send_to specification
  # hmmmm.... if bouncing mail, we won't be calling sendmail with the -t
  # flag, instead we will send the address in as a command line argument.
  # so for bounced messages, we should be pretty strict with regard to
  # what characters are allowed to be specified in the 'send_to' address
  if (!$g_form{'send_to'}) {
    push(@errors, ">>> $MAILMANAGER_SEND_ERROR_TO_EMPTY <<<");
  }
  elsif ($g_form{'send_to'} =~ /[^\w\.\,\-\@\ ]/) {
    $MAILMANAGER_SEND_ERROR_TO_INVALID =~ s/__EMAIL__/$g_form{'send_to'}/g;
    push(@errors, ">>> $MAILMANAGER_SEND_ERROR_TO_INVALID <<<");
  }

  # check the send_from specification
  if ($g_form{'send_from'}) {
    # should probably check here to if this is a valid address or alias
    # on the server, but I'm feeling lazy
  }
  else {
    push(@errors, ">>> $MAILMANAGER_SEND_ERROR_FROM_EMPTY <<<");
  }

  # if errors, then prompt again
  if ($#errors > -1) {
    mailmanagerBounceMessageForm(@errors);
  }
}

##############################################################################

sub mailmanagerHandleBounceMessageRequest
{
  local($string);

  encodingIncludeStringLibrary("mailmanager");

  # load up the message that is to be bounced
  ($nmesg) = (mailmanagerReadMail())[0];
  if ($nmesg == 0) {
    $string = $MAILMANAGER_MESSAGE_NOT_FOUND_TEXT;
    $string =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
    $string =~ s/__MESSAGEID__/$g_form{'messageid'}/g;
    redirectLocation("mailmanager.cgi", $string);
  }

  if (!$g_form{'submit'}) {
    mailmanagerBounceMessageForm();
  }
  elsif ($g_form{'submit'} eq "$CANCEL_STRING") {
    redirectLocation("mailmanager.cgi", $MAILMANAGER_BOUNCE_CANCEL_TEXT);
  }

  # check for errors; then bounce message if ok
  mailmanagerCheckBounceMessageComposition();
  mailmanagerBounceMessage();
}

##############################################################################
# eof

1;

