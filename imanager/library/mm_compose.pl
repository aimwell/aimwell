#
# mm_compose.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/mm_compose.pl,v 2.12.2.9 2006/04/25 19:48:24 rus Exp $
#
# compose, forward, reply mail message functions
#

##############################################################################

sub mailmanagerCheckComposeMessageComposition
{
  local(@errors, $error, $tmpfilename);

  # check the send_to specification; must contain at least one valid address
  if ($g_form{'send_to'}) {
    # should probably check here to if this is a valid address or alias
    # on the server, but I'm feeling lazy
  }
  else {
    push(@errors, ">>> $MAILMANAGER_SEND_ERROR_TO_EMPTY <<<");
  }

  # check the send_from specification; same criteria as send_to
  if ($g_form{'send_from'}) {
    # should probably check here to if this is a valid address or alias
    # on the server, but I'm feeling lazy
  }
  else {
    push(@errors, ">>> $MAILMANAGER_SEND_ERROR_FROM_EMPTY <<<");
  }

  # did user want to attach any local files
  if (($g_prefs{'mail__local_attach_elements'} == 0) &&
      (defined($g_form{'filelocal1'}))) {  
    # mailing file as attachment via link from filemanager
    $g_prefs{'mail__local_attach_elements'} = 1;
  }
  for ($index=1; $index<=$g_prefs{'mail__local_attach_elements'};
       $index++) {
    $key = "filelocal$index";
    if ($g_form{$key}) {
      $tmpfilename = mailmanagerBuildFullPath($g_form{$key});
      unless (-e "$tmpfilename") {
        # specified filename does not exist
        $error = $MAILMANAGER_LOCAL_ATTACHMENT_NOT_EXIST;
        $error =~ s/__FILE__/$g_form{$key}/;
        push(@errors, ">>> $error <<<");
      }
    }
  }

  # if errors, then prompt again
  if ($#errors > -1) {
    mailmanagerComposeMessageForm(@errors);
  }
}

##############################################################################

sub mailmanagerComposeMessageForm
{
  local(@errors) = @_;
  local($mid, $size, $send_to, $string, $title);
  local($rows, $msgbody, $from, $date, $recipient, $subject);
  local($cols, $pos, $nextpos, $ontap);
  local($key, $index, $mid, $ctype, $cdisp, $ctenc);
  local($curline, $buffer, $curfilepos, $endfilepos);
  local($a_num, $a_type, $a_enc, $a_size, $a_disp);
  local($incstring, $filename, $javascript);
  local(@addresses, $useraddress, $addr, $homedir);
  local($pci, $spci, $tpci, $fullpath, $authval);
  local($languagepref);

  $languagepref = encodingGetLanguagePreference();

  # set the action type
  if ($g_form{'type'} eq "compose") {
    $title = $MAILMANAGER_COMPOSE;
    $mid = "";
  }
  elsif ($g_form{'type'} eq "forward") {
    $title = $MAILMANAGER_FORWARD;
    $incstring = $MAILMANAGER_ATTACHMENT_INCLUDE_FORWARD;
    $mid = $g_form{'messageid'};
  }
  elsif ($g_form{'type'} eq "reply") {
    $title = $MAILMANAGER_REPLY;
    $incstring = $MAILMANAGER_ATTACHMENT_INCLUDE_RESPONSE;
    $mid = $g_form{'messageid'};
  }
  elsif ($g_form{'type'} eq "groupreply") {
    $title = $MAILMANAGER_REPLY_GROUP;
    $incstring = $MAILMANAGER_ATTACHMENT_INCLUDE_RESPONSE;
    $mid = $g_form{'messageid'};
  }

  if ($g_form{'abclistid'}) {
    $filename = "$g_tmpdir/.abclist-" . $g_form{'abclistid'};
    if (open(ABCLIST, "$filename")) {
      $g_form{'send_to'} = <ABCLIST>;
      close(ABCLIST);
      chomp($g_form{'send_to'});
      unlink($filename);
    }
    $g_form{'abclistid'} = "";
  }

  initUploadCookieSetSessionID();
  htmlResponseHeader("Content-type: $g_default_content_type");
  $MAILMANAGER_TITLE =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
  $string = "$MAILMANAGER_TITLE : ";
  if ($g_form{'type'} ne "compose") {
    if ($g_email{$mid}->{'subject'}) {
      $subject = $g_email{$mid}->{'subject'};
      if ($languagepref eq "ja") {
        $subject = mailmanagerMimeDecodeHeaderJP_QP($subject);
        $subject = jcode'euc(mimedecode($subject));
      }
      $subject = mailmanagerMimeDecodeHeader($subject);
    }            
    else {
      $subject = $MAILMANAGER_NO_SUBJECT;
    }
    $string .= "$subject : ";
  }
  $string .= $title;
  $javascript = javascriptCheckMessageFields();
  labelCustomHeader($string, "", $javascript);

  if ($#errors > -1) {
    foreach $string (@errors) {
      htmlTextColorBold($string, "#cc0000");
      htmlBR();
    }
    # check for the existence of any file upload sourcepaths
    for ($index=1; $index<=$g_prefs{'mail__upload_attach_elements'};
         $index++) {
      $key = "fileupload$index";
      if (defined($g_form{$key}->{'sourcepath'})) {
        htmlTextColorBold(">>> $MAILMANAGER_SEND_ERROR_UPLOAD_FILE_LOST <<<",
                          "#cc0000");
        last;
      }
    }
    htmlP();
  }

  #
  # compose mail message table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;");
  if ($subject) {
    htmlTextBold("$g_mailbox_virtualpath : $subject -- ");
    $string = $g_email{$mid}->{'from'};
    if ($languagepref eq "ja") {
      $string = mailmanagerMimeDecodeHeaderJP_QP($string);
      $string = jcode'euc(mimedecode($string));
    }
    htmlTextBold("$string : ");
  }
  htmlTextBold($title);
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

  formOpen("method", "POST", "enctype", "multipart/form-data",
           "name", "formfields", "style", "display:inline;");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "type", "value", $g_form{'type'});
  if ($mid) {
    formInput("type", "hidden", "name", "messageid", "value", $mid);
  }
  htmlTable("border", "0");
  # row 1: to 
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$MAILMANAGER_MESSAGE_TO\:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $send_to = "";
  if ($g_form{'send_to'}) {
    $send_to = $g_form{'send_to'};
  }
  elsif (($g_form{'type'} eq "reply") || ($g_form{'type'} eq "groupreply")) { 
    $send_to = $g_email{$mid}->{'reply-to'} || $g_email{$mid}->{'from'} ||
               $g_email{$mid}->{'__delivered_from__'};
  }
  if ($languagepref eq "ja") {
    $send_to = mailmanagerMimeDecodeHeaderJP_QP($send_to);
    $send_to = jcode'euc(mimedecode($send_to));
  }
  $size = formInputSize(60);
  formInput("size", $size, "name", "send_to", "value", $send_to);
  htmlImg("width", "10", "height", "1", "src", "$g_graphicslib/sp.gif");
  $authval = ($g_auth{'type'} eq "form") ? "&AUTH=$g_auth{'KEY'}" : "";
  $string = $MAILMANAGER_ADDRESSBOOK_SELECT_ADD_TITLE;
  $string =~ s/__FIELD__/$MAILMANAGER_MESSAGE_TO/;
  $string =~ s/\s+/ /g;
  $title = $string;
  $string =~ s/'/\\\\'/g;
  print <<ENDTEXT;
<script language="JavaScript1.1">
<!--
  function abSelect_To()
  {
    var auth = "$authval";
    var url = "mm_addressbook.cgi?action=select&field=send_to" + auth;
    var options = \"width=505,height=375,\";
    options += \"resizable=yes,scrollbars=yes,status=yes,\";
    options += \"menubar=no,toolbar=no,location=no,directories=no\";
    var selectWin = window.open(url, 'selectWin', options);
    selectWin.opener = self;
    selectWin.focus();
  }
  document.write("<a onClick=\\\"abSelect_To(); return false\\\" ");
  document.write("onMouseOver=\\\"window.status='$string'; return true\\\" ");
  document.write("onMouseOut=\\\"window.status=''; return true\\\" ");
  document.write("title=\\\"$title\\\" ");
  document.write("href=\\\"mm_addressbook.cgi?action=select&field=send_to\\\">");
  document.write("<img border=\\\"0\\\" width=\\\"14\\\" height=\\\"14\\\" ");
  document.write("src=\\\"$g_graphicslib/mm_cab.jpg\\\">");
  document.write("</a>");
//-->
</script>
ENDTEXT
  $string = $MAILMANAGER_ADDRESSBOOK_SELECT_CLEAR_TITLE;
  $string =~ s/__FIELD__/$MAILMANAGER_MESSAGE_TO/;
  $string =~ s/\s+/ /g;
  $title = $string;
  $string =~ s/'/\\\\'/g;
  print <<ENDTEXT;
<script language="JavaScript1.1">
<!--
  function abClear_To()
  {
    document.formfields.send_to.value = '';
  }
  document.write("<a onClick=\\\"abClear_To(); return false\\\" ");
  document.write("onMouseOver=\\\"window.status='$string'; return true\\\" ");
  document.write("onMouseOut=\\\"window.status=''; return true\\\" ");
  document.write("title=\\\"$title\\\" ");
  document.write("href=\\\"donothing.cgi\\\">");
  document.write("<img border=\\\"0\\\" width=\\\"14\\\" height=\\\"14\\\" ");
  document.write("src=\\\"$g_graphicslib/mm_ccf.jpg\\\">");
  document.write("</a>");
//-->
</script>
ENDTEXT
  htmlTableDataClose();
  htmlTableRowClose();
  # row 2: from
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
  # row 3: subject
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$MAILMANAGER_MESSAGE_SUBJECT\:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $subject = $g_form{'send_subj'} || $g_email{$mid}->{'subject'} || "";
  if ((!$subject) && ($g_form{'type'} ne "compose")) {
    $subject = ($g_form{'type'} eq "forward") ? $MAILMANAGER_NO_SUBJECT :
                                                $MAILMANAGER_NO_SUBJECT_REPLY;
  }
  else {
    if ($languagepref eq "ja") {
      $subject = mailmanagerMimeDecodeHeaderJP_QP($subject);
      $subject = jcode'euc(mimedecode($subject));
    }
    $subject = mailmanagerMimeDecodeHeader($subject);
  }
  if (($g_form{'type'} eq "reply") || ($g_form{'type'} eq "groupreply")) {
    $subject = "Re: $subject" if ($subject !~ /^re: /i);
  }
  elsif ($g_form{'type'} eq "forward") {
    $subject = "$subject (fwd)" if ($subject !~ /\(fwd\)$/i);
  }
  $size = formInputSize(60);
  formInput("size", $size, "name", "send_subj", "value", $subject);
  htmlTableDataClose();
  htmlTableRowClose();
  # row 4: carbon-copy
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$MAILMANAGER_MESSAGE_CC\:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $string = "";
  if ($g_form{'send_cc'}) {
    $string = $g_form{'send_cc'};
  }
  elsif ($g_form{'type'} eq "groupreply") {
    $string = $g_email{$mid}->{'to'};
    $string .= ", $g_email{$mid}->{'cc'}" if ($g_email{$mid}->{'cc'});
    # now remove user from the CC list
    $useraddress = mailmanagerUserSystemEmailAddress();
    @addresses = split(/\,/, $string);
    $string = "";
    foreach $addr (@addresses) {
      if (($addr !~ /$useraddress/) &&
          ((!$g_auth{'email'}) || ($addr !~ /$g_auth{'email'}/))) {
        $string .= "$addr, ";
      }
    }
    chop($string);
    chop($string);
  }
  if ($languagepref eq "ja") {
    $string = mailmanagerMimeDecodeHeaderJP_QP($string);
    $string = jcode'euc(mimedecode($string));
  }
  formInput("size", $size, "name", "send_cc", "value", $string);
  htmlImg("width", "10", "height", "1", "src", "$g_graphicslib/sp.gif");
  $authval = ($g_auth{'type'} eq "form") ? "&AUTH=$g_auth{'KEY'}" : "";
  $string = $MAILMANAGER_ADDRESSBOOK_SELECT_ADD_TITLE;
  $string =~ s/__FIELD__/$MAILMANAGER_MESSAGE_CC/;
  $string =~ s/\s+/ /g;
  $title = $string;
  $string =~ s/'/\\\\'/g;
  print <<ENDTEXT;
<script language="JavaScript1.1">
<!--
  function abSelect_CC()
  {
    var auth = "$authval";
    var url = "mm_addressbook.cgi?action=select&field=send_cc" + auth;
    var options = \"width=505,height=375,\";
    options += \"resizable=yes,scrollbars=yes,status=yes,\";
    options += \"menubar=no,toolbar=no,location=no,directories=no\";
    var selectWin = window.open(url, 'selectWin', options);
    selectWin.opener = self;
    selectWin.focus();
  }
  document.write("<a onClick=\\\"abSelect_CC(); return false\\\" ");
  document.write("onMouseOver=\\\"window.status='$string'; return true\\\" ");
  document.write("onMouseOut=\\\"window.status=''; return true\\\" ");
  document.write("title=\\\"$title\\\" ");
  document.write("href=\\\"mm_addressbook.cgi?action=select&field=send_cc\\\">");
  document.write("<img border=\\\"0\\\" width=\\\"14\\\" height=\\\"14\\\" ");
  document.write("src=\\\"$g_graphicslib/mm_cab.jpg\\\">");
  document.write("</a>");
//-->
</script>
ENDTEXT
  $string = $MAILMANAGER_ADDRESSBOOK_SELECT_CLEAR_TITLE;
  $string =~ s/__FIELD__/$MAILMANAGER_MESSAGE_CC/;
  $string =~ s/\s+/ /g;
  $title = $string;
  $string =~ s/'/\\\\'/g;
  print <<ENDTEXT;
<script language="JavaScript1.1">
<!--
  function abClear_CC()
  {
    document.formfields.send_cc.value = '';
  }
  document.write("<a onClick=\\\"abClear_CC(); return false\\\" ");
  document.write("onMouseOver=\\\"window.status='$string'; return true\\\" ");
  document.write("onMouseOut=\\\"window.status=''; return true\\\" ");
  document.write("title=\\\"$title\\\" ");
  document.write("href=\\\"donothing.cgi\\\">");
  document.write("<img border=\\\"0\\\" width=\\\"14\\\" height=\\\"14\\\" ");
  document.write("src=\\\"$g_graphicslib/mm_ccf.jpg\\\">");
  document.write("</a>");
//-->
</script>
ENDTEXT
  htmlTableDataClose();
  htmlTableRowClose();
  # row 5: blind carbon-copy
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$MAILMANAGER_MESSAGE_BCC\:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $string = $g_form{'send_bcc'} || "";
  if ($languagepref eq "ja") {
    $string = jcode'euc($string);
  }
  formInput("size", $size, "name", "send_bcc", "value", $string);
  htmlImg("width", "10", "height", "1", "src", "$g_graphicslib/sp.gif");
  $authval = ($g_auth{'type'} eq "form") ? "&AUTH=$g_auth{'KEY'}" : "";
  $string = $MAILMANAGER_ADDRESSBOOK_SELECT_ADD_TITLE;
  $string =~ s/__FIELD__/$MAILMANAGER_MESSAGE_BCC/;
  $string =~ s/\s+/ /g;
  $title = $string;
  $string =~ s/'/\\\\'/g;
  print <<ENDTEXT;
<script language="JavaScript1.1">
<!--
  function abSelect_BCC()
  {
    var auth = "$authval";
    var url = "mm_addressbook.cgi?action=select&field=send_bcc" + auth;
    var options = \"width=505,height=375,\";
    options += \"resizable=yes,scrollbars=yes,status=yes,\";
    options += \"menubar=no,toolbar=no,location=no,directories=no\";
    var selectWin = window.open(url, 'selectWin', options);
    selectWin.opener = self;
    selectWin.focus();
  }
  document.write("<a onClick=\\\"abSelect_BCC(); return false\\\" ");
  document.write("onMouseOver=\\\"window.status='$string'; return true\\\" ");
  document.write("onMouseOut=\\\"window.status=''; return true\\\" ");
  document.write("title=\\\"$title\\\" ");
  document.write("href=\\\"mm_addressbook.cgi?action=select&field=send_bcc\\\">");
  document.write("<img border=\\\"0\\\" width=\\\"14\\\" height=\\\"14\\\" ");
  document.write("src=\\\"$g_graphicslib/mm_cab.jpg\\\">");
  document.write("</a>");
//-->
</script>
ENDTEXT
  $string = $MAILMANAGER_ADDRESSBOOK_SELECT_CLEAR_TITLE;
  $string =~ s/__FIELD__/$MAILMANAGER_MESSAGE_BCC/;
  $string =~ s/\s+/ /g;
  $title = $string;
  $string =~ s/'/\\\\'/g;
  print <<ENDTEXT;
<script language="JavaScript1.1">
<!--
  function abClear_BCC()
  {
    document.formfields.send_bcc.value = '';
  }
  document.write("<a onClick=\\\"abClear_BCC(); return false\\\" ");
  document.write("onMouseOver=\\\"window.status='$string'; return true\\\" ");
  document.write("onMouseOut=\\\"window.status=''; return true\\\" ");
  document.write("title=\\\"$title\\\" ");
  document.write("href=\\\"donothing.cgi\\\">");
  document.write("<img border=\\\"0\\\" width=\\\"14\\\" height=\\\"14\\\" ");
  document.write("src=\\\"$g_graphicslib/mm_ccf.jpg\\\">");
  document.write("</a>");
//-->
</script>
ENDTEXT
  htmlTableDataClose();
  htmlTableRowClose();
  # row 6: the body of the message
  htmlTableRow();
  htmlTableData("colspan", "2");
  if ($g_form{'send_body'}) {
    $msgbody = $g_form{'send_body'};
  }
  else {
    # build the message body (if applicable)
    $msgbody = "";
    if ($g_form{'type'} ne "compose") {
      $ctype = $g_email{$mid}->{'content-type'};
      $ctenc = $g_email{$mid}->{'content-transfer-encoding'};
      if ($#{$g_email{$mid}->{'parts'}} > -1) {
        # multipart message; print out the message part by part
        for ($pci=0; $pci<=$#{$g_email{$mid}->{'parts'}}; $pci++) {
          $ctype = $g_email{$mid}->{'parts'}[$pci]->{'content-type'};
          $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'content-transfer-encoding'};
          if ($#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}} > -1) {
            # here we have a message part that has subparts.... this is going to
            # get real ugly, real fast; i'm crapping you negative
            for ($spci=0; $spci<=$#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}}; $spci++) {
              $subctype = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-type'};
              $subctenc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-transfer-encoding'};
              if ($#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}} > -1) {
                # here we have a message subpart that has subparts.... eek
                for ($tpci=0; $tpci<=$#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}}; $tpci++) {
                  $subctype = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-type'};
                  $subctenc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-transfer-encoding'};
                  if (($subctype =~ /text\/plain/i) || ($subctype =~ /application\/text/i)) {
                    # message sub-part's sub-part is plain text; so just print out the body 
                    # of the sub-part's sub-part line by line
                    unless (open(MFP, "$g_mailbox_fullpath")) {
                      mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
                    }
                    seek(MFP, $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_body__'}, 0);
                    $endfilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_end__'};

                    $buffer = "";
                    while (<MFP>) {
                      $curline = $_;
                      # decode the current line
                      if ($subctenc =~ /quoted-printable/i) {
                        $string = mailmanagerDecodeQuotedPrintable($curline);
                        $buffer .= $string;
                        next if ($curline =~ /=\r?\n$/);  # keep reading the file
                      }
                      elsif ($subctenc =~ /base64/i) {
                        $buffer = mailmanagerDecode64($curline);
                      }
                      else {
                        $buffer = $curline;
                      }
                      # append the current buffer to message body
                      if ($languagepref eq "ja") {
                        $buffer = jcode'euc($buffer);
                      }
                      $msgbody .= $buffer;
                      $buffer = "";
                      $curfilepos = tell(MFP);
                      last if ($curfilepos >= $endfilepos);
                    }
                    close(MFP);
                  }
                  else {
                    # message sub-part sub-part must be viewed separately (non text)
                    # ignore here... (shown below)
                  }
                }
              }
              elsif (($subctype =~ /text\/plain/i) || ($subctype =~ /application\/text/i)) {
                # message part sub-part is plain text; so just print out the body 
                # of the part sub-part line by line
                unless (open(MFP, "$g_mailbox_fullpath")) {
                  mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
                }
                seek(MFP, $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_body__'}, 0);
                $endfilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_end__'};
                $buffer = "";
                while (<MFP>) {
                  $curline = $_;
                  # decode the current line
                  if ($subctenc =~ /quoted-printable/i) {
                    $string = mailmanagerDecodeQuotedPrintable($curline);
                    $buffer .= $string;
                    next if ($curline =~ /=\r?\n$/);  # keep reading the file
                  }
                  elsif ($subctenc =~ /base64/i) {
                    $buffer = mailmanagerDecode64($curline);
                  }
                  else {
                    $buffer = $curline;
                  }
                  # append the current buffer to message body
                  if ($languagepref eq "ja") {
                    $buffer = jcode'euc($buffer);
                  }
                  $msgbody .= $buffer;
                  $buffer = "";
                  $curfilepos = tell(MFP);
                  last if ($curfilepos >= $endfilepos);
                }
                close(MFP);
              }
              else {
                # message part sub-part must be viewed separately (non text)
                # ignore here... (shown below)
              }
            }
          }
          elsif ($ctype && 
                 ($ctype !~ /text\/plain/i) && ($ctype !~ /application\/text/i)) {
            # no sub-parts, but not just plain text; must view separately
            # ignore here... (shown below)
          }
          else {
            # no sub-parts, and just a plain text attachment; so just print out 
            # the body of the message part line by line
            unless (open(MFP, "$g_mailbox_fullpath")) {
              mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
            }
            seek(MFP, $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_body__'}, 0);
            $endfilepos = $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_end__'};
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
              # append the current buffer to message body
              if ($languagepref eq "ja") {
                $buffer = jcode'euc($buffer);
              }
              $msgbody .= $buffer;
              $buffer = "";
              $curfilepos = tell(MFP);
              last if ($curfilepos >= $endfilepos);
            }
            close(MFP); 
          }
        }
      }
      elsif ($ctype && 
             ($ctype !~ /text\/plain/i) && ($ctype !~ /application\/text/i)) {
        # ignore here... (shown below)
      }
      else {
        # no parts, and just a plain text message; so just print out the body 
        # of the message line by line
        unless (open(MFP, "$g_mailbox_fullpath")) {
          mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
        }
        seek(MFP, $g_email{$mid}->{'__filepos_message_body__'}, 0);
        $endfilepos = $g_email{$mid}->{'__filepos_message_end__'};
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
          # append the current buffer to message body
          if ($languagepref eq "ja") {
            $buffer = jcode'euc($buffer);
          }
          $msgbody .= $buffer;
          $buffer = "";
          $curfilepos = tell(MFP);
          last if ($curfilepos >= $endfilepos);
        }
        close(MFP); 
      }
      # now add some additional text to the message body depending on 
      # whether the message is being forwarded or replied to
      if ($g_form{'type'} eq "forward") {
        $string = "\n$MAILMANAGER_FORWARD_STRING_BEGIN\n";
        $from = $g_email{$mid}->{'from'} ||
                $g_email{$mid}->{'__delivered_from__'};
        if ($languagepref eq "ja") {
          $from = mailmanagerMimeDecodeHeaderJP_QP($from);
          $from = jcode'euc(mimedecode($from));
        }
        $string =~ s/__EMAIL__/$from/;
        $string .= "\n";
        $string .= "$MAILMANAGER_MESSAGE_SENDER\: $from\n";
        if ($g_email{$mid}->{'reply-to'}) {
          $string .= "$MAILMANAGER_MESSAGE_REPLY_TO\: ";
          $string .= "$g_email{$mid}->{'reply-to'}\n";
        }
        $recipient = $g_email{$mid}->{'to'};
        if ($languagepref eq "ja") {
          $recipient = mailmanagerMimeDecodeHeaderJP_QP($recipient);
          $recipient = jcode'euc(mimedecode($recipient));
        }
        $recipient =~ s/\,/\,\n   /g;
        $string .= "$MAILMANAGER_MESSAGE_TO\: $recipient\n";
        if ($g_email{$mid}->{'subject'}) {
          $string .= "$MAILMANAGER_MESSAGE_SUBJECT\: ";
          $subject = $g_email{$mid}->{'subject'};
          if ($languagepref eq "ja") {
            $subject = mailmanagerMimeDecodeHeaderJP_QP($subject);
            $subject = jcode'euc(mimedecode($subject));
          }
          $subject = mailmanagerMimeDecodeHeader($subject);
          $string .= "$subject\n";
        }
        $date = dateLocalizeTimeString($g_email{$mid}->{'date'});
        $string .= "$MAILMANAGER_MESSAGE_DATE\: $date\n";
        $msgbody = "$string\n$msgbody\n$MAILMANAGER_FORWARD_STRING_END\n";
      }
      elsif (($g_form{'type'} eq "reply") || 
             ($g_form{'type'} eq "groupreply")) {
        $string = "\n$MAILMANAGER_REPLY_STRING\n>\n";
        $date = $g_email{$mid}->{'__display_date__'} || 
                $g_email{$mid}->{'date'};
        $date = dateLocalizeTimeString($date);
        $string =~ s/__DATE__/$date/;
        $from = $g_email{$mid}->{'from'} ||
                $g_email{$mid}->{'__delivered_from__'};
        if ($languagepref eq "ja") {
          $from = mailmanagerMimeDecodeHeaderJP_QP($from);
          $from = jcode'euc(mimedecode($from));
        }
        $string =~ s/__EMAIL__/$from/;
        if ($g_email{$mid}->{'subject'}) {
          $string .= "> $MAILMANAGER_MESSAGE_SUBJECT\: ";
          $subject = $g_email{$mid}->{'subject'};
          if ($languagepref eq "ja") {
            $subject = mailmanagerMimeDecodeHeaderJP_QP($subject);
            $subject = jcode'euc(mimedecode($subject));
          }
          $subject = mailmanagerMimeDecodeHeader($subject);
          $string .= "$subject\n";
        }
        $msgbody = "\n" . $msgbody;
        $msgbody =~ s/\n/\n\> /g;
        $msgbody = $string . ">" . $msgbody;
        $msgbody .= "\n";
      }
    }
    if ($g_prefs{'mail__signature_automatic_append'} eq "yes") {
      $homedir = $g_users{$g_auth{'login'}}->{'home'};
      if (-e "$homedir/.signature") {
        ($size) = (stat("$homedir/.signature"))[7];
        if ($size > 0) {
          $msgbody .= "\n--\n";
          open(FP, "$homedir/.signature");
          $msgbody .= $_ while (<FP>);
          close(FP);
        }   
      }   
    }
  }
  if ($g_form{'type'} eq "compose") {
    $rows = 25;
  }
  else {
    $rows = formTextAreaRows($msgbody);
    $rows += 5;
  }
  $cols = 80;
  if ($msgbody) {
    # adjust based on line length
    $pos = $nextpos = 0;
    while ($nextpos >= 0) {
      $nextpos = index($msgbody, "\n", $pos);
      if (($nextpos - $pos) > $cols) {
        $cols = $nextpos - $pos;
      }
      $pos = $nextpos+1;
    }
    $cols = 82 if ($cols > 90);  # not too wide
  }
  formTextArea($msgbody, "name", "send_body", "rows", $rows, 
               "cols", $cols, "_FONT_", "fixed", "wrap", "physical");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();

  # provide option to save outbound message to a folder
  if ((($g_users{$g_auth{'login'}}->{'ftp'}) ||
       ($g_users{$g_auth{'login'}}->{'imap'})) &&
      ($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full")) {
    htmlTable();
    htmlTableRow();
    htmlTableData("valign", "middle");
    if (($#errors == -1) && (!$g_form{'send_fcc'})) {
      $g_form{'send_fcc'} = "yes";
    }
    htmlNoBR();
    formInput("type", "checkbox", "name", 'send_fcc', "value", "yes",
              "_OTHER_", ($g_form{'send_fcc'} eq "yes") ? "CHECKED" : "");
    htmlText("$MAILMANAGER_MESSAGE_FCC\:");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    $string = "";
    if ($g_form{'fcc_folder'}) {
      $string = $g_form{'fcc_folder'};
    }
    elsif (($g_form{'mbox'}) && ($g_form{'mbox'} != "~/Mail/spam")) {
      $string = $g_form{'mbox'};
    }
    elsif ($g_prefs{'mail__default_folder'}) {
      $send_to =~ /([A-Za-z0-9\-\_\.]*?)\@/;
      if ((!$g_users{$g_auth{'login'}}->{'chroot'}) &&
          ($g_prefs{'mail__default_folder'} =~ /^\//) &&
          ($g_prefs{'mail__default_folder'} !~ /^\Q$g_users{$g_auth{'login'}}->{'home'}\E/)) {
        # old installations of iManager had the value for the preference
        # 'mail__default_folder' set to be an absolute '/Mail' which was
        # ok on a virtual env; but not ok on a dedicated env.  so this
        # little kludge accounts for portability problem of my previously
        # chosen default (if only I had keener foresight)
        $string = $g_users{$g_auth{'login'}}->{'home'} . "/";
        $string .= $g_prefs{'mail__default_folder'} . "/" . ($1 || "outgoing");
      }
      else {
        $string = $g_prefs{'mail__default_folder'} . "/" . ($1 || "outgoing");
      }
      # here is a philsophical decision... should I default to "outgoing"
      # or use the folder name built from the send_to address?  in the
      # end I decided to mimic the behavior of mutt and revert to the
      # "outgoing" box unless the one built from the send_to address 
      # already exists
      $fullpath = mailmanagerBuildFullPath($string);
      unless (-e "$fullpath") {
        # path does not exist... does the default mail folder exist?
        $fullpath =~ s/[^\/]+$//g;
        $fullpath =~ s/\/+$//g;
        unless (-e "$fullpath") {
          mailmanagerCreateDefaultMailFolder($fullpath);
        }
        if ((!$g_users{$g_auth{'login'}}->{'chroot'}) &&
            ($g_prefs{'mail__default_folder'} =~ /^\//) &&
            ($g_prefs{'mail__default_folder'} !~ /^\Q$g_users{$g_auth{'login'}}->{'home'}\E/)) {
          # old installations of iManager had the value for the preference
          # 'mail__default_folder' set to be an absolute '/Mail' which was
          # ok on a virtual env; but not ok on a dedicated env.  so this
          # little kludge accounts for portability problem of my previously
          # chosen default (if only I had keener foresight)
          $string = $g_users{$g_auth{'login'}}->{'home'} . "/";
          $string .= $g_prefs{'mail__default_folder'} . "/outgoing";
        }
        else {
          $string = $g_prefs{'mail__default_folder'} . "/outgoing";
        }
      }
      $string =~ s/\/+/\//g;
    }
    $size = formInputSize(30);
    formInput("size", $size, "name", "fcc_folder", "value", $string);
    htmlTableDataClose();
    $authval = ($g_auth{'type'} eq "form") ? "&AUTH=$g_auth{'KEY'}" : "";
    $title = $MAILMANAGER_MESSAGE_FCC_BROWSE_HELP;
    $title =~ s/\s+/\ /g;
    print <<ENDTEXT;
<script language="JavaScript1.1">
<!--
  function fileSelectFccFolder()
  {
    var auth = "$authval";
    var path = document.formfields.fcc_folder.value;
    var url = "mm_select.cgi?fcc_folder=1&destfile=" + path + auth;
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
  document.write("<a onClick=\\\"fileSelectFccFolder(); return false\\\" ");
  document.write("onMouseOver=\\\"window.status='$MAILMANAGER_MESSAGE_FCC_BROWSE: $MAILMANAGER_MESSAGE_FCC_SELECT'; return true\\\" ");
  document.write("onMouseOut=\\\"window.status=''; return true\\\" ");
  document.write("title=\\\"$title\\\" ");
  document.write("href=\\\"mm_select.cgi?fcc_folder=1\\\">");
  document.write("$MAILMANAGER_MESSAGE_FCC_BROWSE");
  document.write("</a>");
  document.write("&#160;]");
  document.write("</font>");
  document.write("</td>");
//-->
</script>
ENDTEXT
    htmlTableRowClose();
    htmlTableClose();
  }
  htmlP();

  # print out information about any attachments in original message
  if ($g_form{'type'} ne "compose") {
    $ctype = $g_email{$mid}->{'content-type'};
    $ctenc = $g_email{$mid}->{'content-transfer-encoding'};
    if ($#{$g_email{$mid}->{'parts'}} > -1) {
      # multipart message; print out the message part by part
      $ontap = 0;  # Original Non-Text Attachments Present (ontap)
      for ($pci=0; $pci<=$#{$g_email{$mid}->{'parts'}}; $pci++) {
        $ctype = $g_email{$mid}->{'parts'}[$pci]->{'content-type'};
        $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'content-transfer-encoding'};
        if ($#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}} > -1) {
          # here we have a message part that has subparts.... this is going to
          # get real ugly, real fast; i'm crapping you negative
          for ($spci=0; $spci<=$#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}}; $spci++) {
            $subctype = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-type'};
            $subctenc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-transfer-encoding'};
            if ($#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}} > -1) {
              # here we have a message sub-part that has subparts.... eeek
              # get real ugly, real fast; i'm crapping you negative
              for ($tpci=0; $tpci<=$#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}}; $tpci++) {
                $subctype = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-type'};
                $subctenc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-transfer-encoding'};
                if (($subctype =~ /text\/plain/i) || ($subctype =~ /application\/text/i)) {
                  # message part sub-part is plain text
                  # ignore here... (shown above in message body)
                }
                else {
                  # non-text message part sub-part; give option to attach
                  if ($ontap == 0) {  # i suck and my code sucks
                    $ontap = 1;
                    htmlTable("cellpadding", "0", "cellspacing", "0",
                              "border", "0", "bgcolor", "#999999", "width", "100\%");
                    htmlTableRow();
                    htmlTableData();
                    htmlImg("width", "1", "height", "1", 
                            "src", "$g_graphicslib/sp.gif");
                    htmlTableDataClose();
                    htmlTableRowClose();
                    htmlTableClose();
                    htmlP();
                    htmlTextBold($MAILMANAGER_MESSAGE_ORIGINAL_ATTACHMENTS);
                    htmlText("&#160;");
                    htmlNoBR();
                    if ($g_form{'type'} eq "forward") {
                      htmlTextBold($MAILMANAGER_FORWARD_INCLUDE_HELP);
                    }
                    else {
                      htmlTextBold($MAILMANAGER_REPLY_INCLUDE_HELP);
                    }
                    htmlNoBRClose();
                    htmlBR();
                    htmlTable("border", "0");
                  }
                  htmlTableRow();
                  htmlTableData("valign", "top");
                  $messagepartid = sprintf "%d.%d.%d", ($pci+1), ($spci+1), ($tpci+1);
                  $key = "_include" . $messagepartid;
                  if (($#errors == -1) && (!$g_form{$key}) &&
                      ($g_form{'type'} eq "forward")) {
                    $g_form{$key} = "yes";
                  }
                  formInput("type", "checkbox", "name", $key, "value", "yes",
                            "_OTHER_", ($g_form{$key} eq "yes") ? "CHECKED" : "");
                  htmlTableDataClose();
                  htmlTableData("valign", "top");
                  $a_num = $MAILMANAGER_ATTACHMENT_NUMBER;
                  $a_num =~ s/__NUM__/$messagepartid/;
                  $a_type = (split(/\;/, $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-type'}))[0] || "???";
                  $a_enc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-transfer-encoding'};
                  $a_disp = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-disposition'};
                  $a_size = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_end__'} - 
                            $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_body__'};
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
                    if ($languagepref eq "ja") {
                      $a_disp = mailmanagerMimeDecodeHeaderJP_QP($a_disp);
                      $a_disp = jcode'euc(mimedecode($a_disp));
                    }
                    $string .= "; $a_disp";
                  }
                  htmlText($string);
                  print "&#160;&#160;";
                  $string = "mbox=";
                  $string .= encodingStringToURL($g_form{'mbox'});
                  $string .= "&mpos=$g_form{'mpos'}";
                  $string .= "&mrange=$g_form{'mrange'}&msort=$g_form{'msort'}&messageid=";
                  $string .= encodingStringToURL($g_form{'messageid'});
                  $string .= "&messagepart=$messagepartid";
                  $ENV{'SCRIPT_NAME'} =~ s/mm_compose/mailmanager/;
                  $title = $MAILMANAGER_ATTACHMENT_VIEW_SEPARATELY_HELP;
                  $title =~ s/\s+/\ /g;
                  $title =~ s/__TYPE__/$a_type/;
                  htmlAnchor("target", "_blank", "title", $title,
                             "href", "$ENV{'SCRIPT_NAME'}?$string");
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
              }
            }
            elsif (($subctype =~ /text\/plain/i) || ($subctype =~ /application\/text/i)) {
              # message part sub-part is plain text
              # ignore here... (shown above in message body)
            }
            else {
              # non-text message part sub-part; give option to attach
              if ($ontap == 0) {  # i suck and my code sucks
                $ontap = 1;
                htmlTable("cellpadding", "0", "cellspacing", "0",
                          "border", "0", "bgcolor", "#999999", "width", "100\%");
                htmlTableRow();
                htmlTableData();
                htmlImg("width", "1", "height", "1", 
                        "src", "$g_graphicslib/sp.gif");
                htmlTableDataClose();
                htmlTableRowClose();
                htmlTableClose();
                htmlP();
                htmlTextBold($MAILMANAGER_MESSAGE_ORIGINAL_ATTACHMENTS);
                htmlText("&#160;");
                htmlNoBR();
                if ($g_form{'type'} eq "forward") {
                  htmlTextBold($MAILMANAGER_FORWARD_INCLUDE_HELP);
                }
                else {
                  htmlTextBold($MAILMANAGER_REPLY_INCLUDE_HELP);
                }
                htmlNoBRClose();
                htmlBR();
                htmlTable("border", "0");
              }
              htmlTableRow();
              htmlTableData("valign", "top");
              $messagepartid = sprintf "%d.%d", ($pci+1), ($spci+1);
              $key = "_include" . $messagepartid;
              if (($#errors == -1) && (!$g_form{$key}) &&
                  ($g_form{'type'} eq "forward")) {
                $g_form{$key} = "yes";
              }
              formInput("type", "checkbox", "name", $key, "value", "yes",
                        "_OTHER_", ($g_form{$key} eq "yes") ? "CHECKED" : "");
              htmlTableDataClose();
              htmlTableData("valign", "top");
              $a_num = $MAILMANAGER_ATTACHMENT_NUMBER;
              $a_num =~ s/__NUM__/$messagepartid/;
              $a_type = (split(/\;/, $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-type'}))[0] || "???";
              $a_enc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-transfer-encoding'};
              $a_disp = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-disposition'};
              $a_size = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_end__'} - 
                        $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_body__'};
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
                if ($languagepref eq "ja") {
                  $a_disp = mailmanagerMimeDecodeHeaderJP_QP($a_disp);
                  $a_disp = jcode'euc(mimedecode($a_disp));
                }
                $string .= "; $a_disp";
              }
              htmlText($string);
              print "&#160;&#160;";
              $string = "mbox=";
              $string .= encodingStringToURL($g_form{'mbox'});
              $string .= "&mpos=$g_form{'mpos'}";
              $string .= "&mrange=$g_form{'mrange'}&msort=$g_form{'msort'}&messageid=";
              $string .= encodingStringToURL($g_form{'messageid'});
              $string .= "&messagepart=$messagepartid";
              $ENV{'SCRIPT_NAME'} =~ s/mm_compose/mailmanager/;
              $title = $MAILMANAGER_ATTACHMENT_VIEW_SEPARATELY_HELP;
              $title =~ s/\s+/\ /g;
              $title =~ s/__TYPE__/$a_type/;
              htmlAnchor("target", "_blank", "title", $title,
                         "href", "$ENV{'SCRIPT_NAME'}?$string");
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
          }
        }
        elsif ($ctype && 
               ($ctype !~ /text\/plain/i) && ($ctype !~ /application\/text/i)) {
          # non-text message part; give option to attach
          if ($ontap == 0) {  # i suck and my code sucks
            $ontap = 1;
            htmlTable("cellpadding", "0", "cellspacing", "0",
                      "border", "0", "bgcolor", "#999999", "width", "100\%");
            htmlTableRow();
            htmlTableData();
            htmlImg("width", "1", "height", "1", 
                    "src", "$g_graphicslib/sp.gif");
            htmlTableDataClose();
            htmlTableRowClose();
            htmlTableClose();
            htmlP();
            htmlTextBold($MAILMANAGER_MESSAGE_ORIGINAL_ATTACHMENTS);
            htmlText("&#160;");
            if ($g_form{'type'} eq "forward") {
              htmlTextBold($MAILMANAGER_FORWARD_INCLUDE_HELP);
            }
            else {
              htmlTextBold($MAILMANAGER_REPLY_INCLUDE_HELP);
            }
            htmlBR();
            htmlTable("border", "0");
          }
          htmlTableRow();
          htmlTableData("valign", "top");
          $messagepartid = $pci+1;
          $key = "_include" . $messagepartid;
          if (($#errors == -1) && (!$g_form{$key}) &&
              ($g_form{'type'} eq "forward")) {
            $g_form{$key} = "yes";
          }
          formInput("type", "checkbox", "name", $key, "value", "yes",
                    "_OTHER_", ($g_form{$key} eq "yes") ? "CHECKED" : "");
          htmlTableDataClose();
          htmlTableData("valign", "top");
          $a_num = $MAILMANAGER_ATTACHMENT_NUMBER;
          $a_num =~ s/__NUM__/$messagepartid/;
          $a_type = (split(/\;/, $g_email{$mid}->{'parts'}[$pci]->{'content-type'}))[0] || "???";
          $a_enc = $g_email{$mid}->{'parts'}[$pci]->{'content-transfer-encoding'};
          $a_disp = $g_email{$mid}->{'parts'}[$pci]->{'content-disposition'};
          $a_size = $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_end__'} - 
                    $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_body__'};
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
            if ($languagepref eq "ja") {
              $a_disp = mailmanagerMimeDecodeHeaderJP_QP($a_disp);
              $a_disp = jcode'euc(mimedecode($a_disp));
            }
            $string .= "; $a_disp";
          }
          htmlText($string);
          print "&#160;&#160;";
          $string = "mbox=";
          $string .= encodingStringToURL($g_form{'mbox'});
          $string .= "&mpos=$g_form{'mpos'}&mrange=$g_form{'mrange'}&msort=$g_form{'msort'}&messageid=";
          $string .= encodingStringToURL($g_form{'messageid'});
          $string .= "&messagepart=$messagepartid";
          $ENV{'SCRIPT_NAME'} =~ s/mm_compose/mailmanager/;
          $title = $MAILMANAGER_ATTACHMENT_VIEW_SEPARATELY_HELP;
          $title =~ s/\s+/\ /g;
          $title =~ s/__TYPE__/$a_type/;
          htmlAnchor("target", "_blank", "title", $title,
                     "href", "$ENV{'SCRIPT_NAME'}?$string");
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
        else {
          # no sub-parts, and just a plain text attachment
          # ignore here... (shown above in message body)
        }
      }
      # close out the table (if open)
      if ($ontap) {
        htmlTableClose();
        htmlP();
      }
    }
    elsif ($ctype && 
           ($ctype !~ /text\/plain/i) && ($ctype !~ /application\/text/i)) {
      # non-text message; give option to attach 
      htmlTable("cellpadding", "0", "cellspacing", "0",
                "border", "0", "bgcolor", "#999999", "width", "100\%");
      htmlTableRow();
      htmlTableData();
      htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlP();
      htmlTextBold($MAILMANAGER_BOUNCE_ORIGINAL_MESSAGE);
      htmlText("&#160;");
      if ($g_form{'type'} eq "forward") {
        htmlTextBold($MAILMANAGER_FORWARD_INCLUDE_HELP);
      }
      else {
        htmlTextBold($MAILMANAGER_REPLY_INCLUDE_HELP);
      }
      htmlBR();
      htmlTable("border", "0");
      htmlTableRow();
      htmlTableData("valign", "middle");
      $messagepartid = -1;
      $key = "_include" . $messagepartid;
      if (($#errors == -1) && (!$g_form{$key}) &&
          ($g_form{'type'} eq "forward")) {
        $g_form{$key} = "yes";
      }
      formInput("type", "checkbox", "name", $key, "value", "yes",
                "_OTHER_", ($g_form{$key} eq "yes") ? "CHECKED" : "");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      $a_type = (split(/\;/, $g_email{$mid}->{'content-type'}))[0] || "???";
      $a_enc = $g_email{$mid}->{'content-transfer-encoding'};
      $a_disp = $g_email{$mid}->{'content-disposition'};
      $a_size = $g_email{$mid}->{'__filepos_message_end__'} - 
                $g_email{$mid}->{'__filepos_message_body__'};
      if ($a_size < 1024) {
        $a_size = sprintf("%s $BYTES", $a_size);
      }
      elsif ($a_size < 1048576) {
        $a_size = sprintf("%1.1f $KILOBYTES", ($a_size / 1024));
      }
      else {
        $a_size = sprintf("%1.2f $MEGABYTES", ($a_size / 1048576));
      }
      $string = "$MAILMANAGER_ATTACHMENT_TYPE: $a_type; ";
      if ($a_enc) {
        $string .= "$MAILMANAGER_ATTACHMENT_ENCODING: $a_enc; ";
      }
      $string .= "$MAILMANAGER_ATTACHMENT_SIZE: $a_size";
      htmlText($string);
      print "&#160;&#160;";
      $string = "mbox=";
      $string .= encodingStringToURL($g_form{'mbox'});
      $string .= "&mpos=$g_form{'mpos'}&mrange=$g_form{'mrange'}&msort=$g_form{'msort'}&messageid=";
      $string .= encodingStringToURL($g_form{'messageid'});
      $string .= "&messagepart=$messagepartid";
      $ENV{'SCRIPT_NAME'} =~ s/mm_compose/mailmanager/;
      $title = $MAILMANAGER_MESSAGE_VIEW_SEPARATELY_HELP;
      $title =~ s/\s+/\ /g;
      $title =~ s/__TYPE__/$a_type/;
      htmlAnchor("target", "_blank", "title", $title,
                 "href", "$ENV{'SCRIPT_NAME'}?$string");
      htmlAnchorText(">>> $MAILMANAGER_MESSAGE_VIEW_SEPARATELY <<<");
      htmlAnchorClose();
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlP();
    }
    else {
      # no parts, and just a plain text message
      # ignore here... (shown above in message body)
    }
  }

  # display any other applicable attachment options
  if (($g_prefs{'mail__upload_attach_elements'} > 0) ||
      (($g_users{$g_auth{'login'}}->{'ftp'}) &&
       (($g_prefs{'mail__local_attach_elements'} > 0) ||
        (defined($g_form{'filelocal1'}))))) {
    # print out some submission buttons
    formInput("type", "submit", "name", "sendsubmit", 
              "value", $MAILMANAGER_SEND, "onClick", "return verify(this);");
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
    if ($g_prefs{'mail__upload_attach_elements'} > 0) {
      htmlTextBold($MAILMANAGER_MESSAGE_UPLOAD_ATTACHMENTS);
      htmlBR();
      htmlTable();
      $size = formInputSize(60);
      for ($index=1; $index<=$g_prefs{'mail__upload_attach_elements'};
           $index++) {
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
    }
    if ($g_users{$g_auth{'login'}}->{'ftp'} &&
        (($g_prefs{'mail__local_attach_elements'} > 0) ||
         (defined($g_form{'filelocal1'})))) {
      htmlTextBold($MAILMANAGER_MESSAGE_LOCAL_ATTACHMENTS);
      print <<ENDTEXT;
<script language="JavaScript1.1">
</script>
<noscript>
ENDTEXT
      htmlText("&#160; &#160; &#160; &#160; [&#160;");
      $title = $MAILMANAGER_MESSAGE_LOCAL_ATTACHMENTS_BROWSE_HELP;
      $title =~ s/\s+/\ /g;
      htmlAnchor("target", "browseWin", "title", $title,
                 "href", "filemanager.cgi");
      htmlAnchorText($MAILMANAGER_MESSAGE_LOCAL_ATTACHMENTS_BROWSE);
      htmlAnchorClose();
      htmlText("&#160;]");
      print "\n</noscript>\n";
      htmlBR();
      htmlTable();
      $size = formInputSize(60);
      if (($g_prefs{'mail__local_attach_elements'} == 0) &&
          (defined($g_form{'filelocal1'}))) {  
        # mailing file as attachment via link from filemanager
        $g_prefs{'mail__local_attach_elements'} = 1;
      }
      for ($index=1; 
           $index<=$g_prefs{'mail__local_attach_elements'}; $index++) {
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
  }

  # print out some submission buttons
  htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
  htmlTableRow();
  htmlTableData("valign", "top");
  formInput("type", "submit", "name", "sendsubmit", "value", $MAILMANAGER_SEND,
            "onClick", "return verify(this);");
  formInput("type", "reset", "value", $RESET_STRING);
  formClose();
  htmlTableDataClose();
  htmlTableData("valign", "top");
  # put cancel in its own form so that files aren't uploaded
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "type", "value", $g_form{'type'});
  if ($mid) {
    formInput("type", "hidden", "name", "messageid", "value", $mid);
  }
  htmlText("&#160;");
  formInput("type", "submit", "name", "sendsubmit", "value", $CANCEL_STRING);
  formClose();
  htmlTableRowClose();
  htmlTableClose();

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

sub mailmanagerHandleComposeMessageRequest
{
  local($string, $sessionid, $tmpfilename, @pids, $index, $key);

  encodingIncludeStringLibrary("mailmanager");

  $g_form{'type'} = "compose" unless ($g_form{'type'});
  if (($g_form{'type'} eq "forward") || ($g_form{'type'} eq "reply") || 
      ($g_form{'type'} eq "groupreply")) {
    # load up the message to be forwarded, replied to
    ($nmesg) = (mailmanagerReadMail())[0];
    if ($nmesg == 0) {
      $string = $MAILMANAGER_MESSAGE_NOT_FOUND_TEXT;
      $string =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
      $string =~ s/__MESSAGEID__/$g_form{'messageid'}/g;
      redirectLocation("mailmanager.cgi", $string);
    }
    # parse the message body into parts if applicable
    mailmanagerParseBodyIntoParts();
  }
  else {
    $g_form{'messageid'} = "";
  }

  if (!$g_form{'sendsubmit'}) {
    mailmanagerComposeMessageForm();
  }
  elsif ($g_form{'sendsubmit'} eq "$CANCEL_STRING") {
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
        for ($index=1; $index<=$g_prefs{'mail__upload_attach_elements'}; $index++) {
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
          for ($index=1; $index<=$g_prefs{'mail__upload_attach_elements'}; $index++) {
            $key = "fileupload$index";
            $tmpfilename = $g_tmpdir . "/.upload-" . $sessionid . "-" . $key;
            unlink($tmpfilename);
          }
        }
      }
    }
    # cleaning is done... redirect
    if ((!$g_form{'type'}) || ($g_form{'type'} eq "compose")) {
      redirectLocation("mailmanager.cgi", $MAILMANAGER_COMPOSE_CANCEL_TEXT);
    }
    elsif ($g_form{'type'} eq "forward") {
      redirectLocation("mailmanager.cgi", $MAILMANAGER_FORWARD_CANCEL_TEXT);
    }
    elsif (($g_form{'type'} eq "reply") || 
           ($g_form{'type'} eq "groupreply")) {
      redirectLocation("mailmanager.cgi", $MAILMANAGER_REPLY_CANCEL_TEXT);
    }
  }

  # check for errors; then bounce message if ok
  mailmanagerCheckComposeMessageComposition();
  mailmanagerSendMessage();
}

##############################################################################

sub mailmanagerSendMessage
{
  local($mid, $nmesg, $string);
  local($index, $messageid, $key);
  local($multipart_message, $boundary, $fullpath, $parentdir, $errmsg);
  local($addnewline, $secondlastchar, $lastchar, $filename, $tmpfilename);
  local($host, $content_length, $numlines);
  local($mimetype, $char, $xsender);
  local($languagepref, $subject, $status);
  local($headersfilename, $bodyfilename);
  local($buffer, $encbuffer);
  local($messagepartid,  $pci, $spci, $tpci, $ctype, $cdisp, $ctenc);
  local($bfilepos, $efilepos, $curfilepos, $homedir);
  local($datestring, $fromstring, $fsize, $msgsize, $used);

  $languagepref = encodingGetLanguagePreference();

  # build filenames which will store the message headers and the message
  # body; we don't store messages in memory any longer to keep the memory
  # use as light as possible
  $headersfilename = $g_tmpdir . "/.message-" . $g_curtime . "-" . $$;
  $headersfilename .= "_" . $g_form{'type'} . "_headers";
  open(HEADERS, ">$headersfilename") || mailmanagerResourceError(
     "open(HEADERS, '>$headersfilename') failed in mailmanagerSendMessage");
  $bodyfilename = $g_tmpdir . "/.message-" . $g_curtime . "-" . $$;
  $bodyfilename .= "_" . $g_form{'type'} . "_body";
  unless (open(BODY, ">$bodyfilename")) {
     close(HEADERS);
     mailmanagerResourceError("open(BODY, '>$bodyfilename') failed \
                               in mailmanagerSendMessage");
  }

  # prime the error message
  $errmsg = "write failure in mailmanagerSendMessage() -- ";
  $errmsg .= "check available disk space";

  # read the mail message and parse the message body 
  $mid = $g_form{'messageid'};
  if ($mid) {
    ($nmesg) = (mailmanagerReadMail())[0];
    if ($nmesg == 0) {
      $string = $MAILMANAGER_MESSAGE_NOT_FOUND_TEXT;
      $string =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
      $string =~ s/__MESSAGEID__/$mid/g;
      redirectLocation("mailmanager.cgi", $string);
    }
    # parse the message body into parts if applicable 
    mailmanagerParseBodyIntoParts();
    # figure out if we have attachments and need to send a mime message
    $multipart_message = 0;
    # did user want to include attachments from original message?
    foreach $key (keys(%g_form)) { 
      if (($g_form{$key} eq "yes") && ($key =~ /^_include/)) {
        $multipart_message = 1;
        last;
      }
    }
  }
  # did user upload any files to attach
  for ($index=1; $index<=$g_prefs{'mail__upload_attach_elements'}; 
       $index++) {
    $key = "fileupload$index";
    next unless ($g_form{$key}->{'content-filename'});
    $multipart_message = 1;
    last;
  }
  # did user want to attach any local files
  if (($g_prefs{'mail__local_attach_elements'} == 0) &&
      (defined($g_form{'filelocal1'}))) {  
    # mailing file as attachment via link from filemanager
    $g_prefs{'mail__local_attach_elements'} = 1;
  }
  for ($index=1; $index<=$g_prefs{'mail__local_attach_elements'};
       $index++) {
    $key = "filelocal$index";
    if ($g_form{$key}) {
      $multipart_message = 1;
      last;
    }
  }

  # make a message id for outgoing message
  $messageid = "<" . $g_curtime . "." . $$ . "\@";
  $host = mailmanagerHostAddress();
  $messageid .= $host . ">";

  # build message headers from the form submission
  # 'from' header
  $string = $g_form{'send_from'};
  if ($languagepref eq "ja") {
    $string = mailmanagerEncodeAddressHeaderToJIS($string);
  }
  $buffer = "From: $string\n";
  # 'to' header
  $string = $g_form{'send_to'};
  if ($languagepref eq "ja") {
    $string = mailmanagerEncodeAddressHeaderToJIS($string);
  }
  $buffer .= "To: $string\n";
  # 'cc' header
  if ($g_form{'send_cc'}) {
    $string = $g_form{'send_cc'};
    if ($languagepref eq "ja") {
      $string = mailmanagerEncodeAddressHeaderToJIS($string);
    }
    $buffer .= "Cc: $string\n";
  }
  # 'bcc' header
  if ($g_form{'send_bcc'}) {
    $string = $g_form{'send_bcc'};
    if ($languagepref eq "ja") {
      $string = mailmanagerEncodeAddressHeaderToJIS($string);
    }
    $buffer .= "Bcc: $string\n";
  }
  # 'subject' header
  $subject = $g_form{'send_subj'};
  if ($languagepref eq "ja") {
    $subject = mimeencode(jcode'jis($subject));
  }
  $buffer .= "Subject: $subject\n";
  # 'message-id' header
  $buffer .= "Message-Id: $messageid\n";
  # 'in-reply-to' header
  if (($g_form{'type'} eq "reply") || ($g_form{'type'} eq "groupreply")) {
    $buffer .= "In-Reply-To: $g_form{'messageid'}\n";
  }
  # 'X-sender' header
  $xsender = mailmanagerUserSystemEmailAddress();
  $buffer .= "X-Sender: $xsender\n";
  # 'x-mailer' header
  require "$g_includelib/info.pl";
  infoLoadVersion();
  $buffer .= "X-Mailer: $g_info{'version'}\n";
  # 'x-remote-addr' and 'x-remote-host' headers
  $buffer .= "X-Remote-Addr: $ENV{'REMOTE_ADDR'}\n";
  if ($ENV{'REMOTE_HOST'}) {
    $buffer .= "X-Remote-Host: $ENV{'REMOTE_HOST'}\n";
  }
  # 'mime-version' header
  $buffer .= "MIME-Version: 1.0\n";

  # append current buffer of headers to headers file
  unless (print HEADERS $buffer) {
    close(HEADERS);
    close(BODY);
    unlink($bodyfilename);
    unlink($headersfilename);
    mailmanagerResourceError($errmsg);
  }

  # clean up text area message body form data
  if ($g_form{'send_body'}) {
    $g_form{'send_body'} =~ s/\r\n/\n/g;
    $g_form{'send_body'} =~ s/\r//g;
    $g_form{'send_body'} =~ s/\nFrom/\n\\From/;
    $g_form{'send_body'} .= "\n" if ($g_form{'send_body'} !~ /\n$/); 
    if ($languagepref eq "ja") {
      $g_form{'send_body'} = jcode'jis($g_form{'send_body'});
    }
  }

  # build message body from the form submission
  if ($multipart_message) {
    $boundary = authGetRandomChars(rand(6)+0.5);
    $boundary .= $g_curtime % $$;
    $boundary .= authGetRandomChars(rand(6)+0.5);
    $boundary .= "0123456789";
    $boundary =~ s/\///g;
    $index = sprintf "%d", (rand(9)+0.5);
    $boundary =~ s/$index/\_/g;
    $buffer = "Content-Type: multipart/mixed; boundary=\"$boundary\"\n";
    unless (print HEADERS $buffer) {
      close(HEADERS);
      close(BODY);
      unlink($bodyfilename);
      unlink($headersfilename);
      mailmanagerResourceError($errmsg);
    }
    if ($g_form{'send_body'}) {
      $buffer = "--" . $boundary . "\n";
      if ($languagepref eq "ja") {
        $buffer .= "Content-Type: text/plain; charset=iso-2022-jp\n\n";
      }
      else {
        $buffer .= "Content-Type: text/plain\n\n";
      }
      $buffer .= $g_form{'send_body'};  # trailing newline appended above
      unless (print BODY $buffer) {
        close(HEADERS);
        close(BODY);
        unlink($bodyfilename);
        unlink($headersfilename);
        mailmanagerResourceError($errmsg);
      }
    }
    # did user want to include attachments from original message?
    foreach $key (keys(%g_form)) {
      if (($g_form{$key} eq "yes") && ($key =~ /^_include([0-9\-\.]*)/)) {
        $messagepartid = $1;
        # include attachment (or message body) from original message 
        $buffer = "--" . $boundary . "\n";
        ($pci,$spci,$tpci) = split(/\./, $messagepartid);
        if ($pci == -1) {
          $ctype = $g_email{$mid}->{'content-type'};
          $cdisp = $g_email{$mid}->{'content-disposition'};
          $ctenc = $g_email{$mid}->{'content-transfer-encoding'};
          $bfilepos = $g_email{$mid}->{'__filepos_message_body__'};
          $efilepos = $g_email{$mid}->{'__filepos_message_end__'};
        }
        elsif (!$spci) {
          $pci--;
          $ctype = $g_email{$mid}->{'parts'}[$pci]->{'content-type'};
          $cdisp = $g_email{$mid}->{'parts'}[$pci]->{'content-disposition'};
          $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'content-transfer-encoding'};
          $bfilepos = $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_body__'};
          $efilepos = $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_end__'};
        }
        elsif (!$tpci) {
          $pci--;
          $spci--;
          $ctype = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-type'};
          $cdisp = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-disposition'};
          $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-transfer-encoding'};
          $bfilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_body__'};
          $efilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_end__'};
        }
        else {
          $pci--;
          $spci--;
          $tpci--;
          $ctype = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-type'};
          $cdisp = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-disposition'};
          $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-transfer-encoding'};
          $bfilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_body__'};
          $efilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_end__'};
        }
        $buffer .= "Content-Type: $ctype\n";
        if ($cdisp) {
          $buffer .= "Content-Disposition: $cdisp\n";
        }
        if ($ctenc) {
          $buffer .= "Content-Transfer-Encoding: $ctenc\n";
        }
        $buffer .= "\n";
        unless (print BODY $buffer) {
          close(HEADERS);
          close(BODY);
          unlink($bodyfilename);
          unlink($headersfilename);
          mailmanagerResourceError($errmsg);
        }
        unless (open(MFP, "$g_mailbox_fullpath")) {
          mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
        }
        seek(MFP, $bfilepos, 0);
        while (read(MFP, $buffer, 1)) {
          $curfilepos = tell(MFP);
          unless (print BODY "$buffer") {
            close(HEADERS);
            close(BODY);
            unlink($bodyfilename);
            unlink($headersfilename);
            mailmanagerResourceError($errmsg);
          }
          last if ($curfilepos >= $efilepos);
        }
        close(MFP);
      }
    }
    # did user upload any files to attach
    for ($index=1; $index<=$g_prefs{'mail__upload_attach_elements'}; $index++) {
      $key = "fileupload$index";
      next unless ($g_form{$key}->{'content-filename'});
      $filename = $g_form{$key}->{'sourcepath'};
      if ($languagepref eq "ja") {
        $filename = mimeencode(jcode'jis($filename));
      }
      $buffer = "--" . $boundary . "\n";
      $buffer .= "Content-Type: $g_form{$key}->{'content-type'}; ";
      $buffer .= "name=\"$filename\"\n";
      $buffer .= "Content-Disposition: attachment; ";
      $buffer .= "filename=\"$filename\"\n";
      unless (print BODY $buffer) {
        close(HEADERS);
        close(BODY);
        unlink($bodyfilename);
        unlink($headersfilename);
        mailmanagerResourceError($errmsg);
      }
      # do we need to encode the uploaded file or not?
      if ((-T "$g_form{$key}->{'content-filename'}") &&
          ($g_form{$key}->{'content-type'} !~ /pdf$/)) {
        # plain text file
        unless (print BODY "\n") {
          close(HEADERS);
          close(BODY);
          unlink($bodyfilename);
          unlink($headersfilename);
          mailmanagerResourceError($errmsg);
        }
        open(CONTENTFP, "$g_form{$key}->{'content-filename'}");
        while (<CONTENTFP>) {
          $buffer = $_;
          $buffer =~ s/\r\n/\n/g;
          $buffer =~ s/\r//g;
          $buffer .= "\n" unless ($buffer =~ /\n$/);
          unless (print BODY "$buffer") {
            close(HEADERS);
            close(BODY);
            unlink($bodyfilename);
            unlink($headersfilename);
            mailmanagerResourceError($errmsg);
          } 
        }
        close(CONTENTFP);
      }
      else {
        # binary file ... encode 54 bytes at a time
        unless (print BODY "Content-Transfer-Encoding: base64\n\n") {
          close(HEADERS);
          close(BODY);
          unlink($bodyfilename);
          unlink($headersfilename);
          mailmanagerResourceError($errmsg);
        }
        open(CONTENTFP, "$g_form{$key}->{'content-filename'}");
        while (read(CONTENTFP, $buffer, 54)) {
          $encbuffer = mailmanagerEncode64($buffer);
          unless (print BODY "$encbuffer") {
            close(HEADERS);
            close(BODY);
            unlink($bodyfilename);
            unlink($headersfilename);
            mailmanagerResourceError($errmsg);
          }
        }
        # if necessary, close current message part with a newline
        if ($encbuffer !~ /\n$/) {
          unless (print BODY "\n") {
            close(HEADERS);
            close(BODY);
            unlink($bodyfilename);
            unlink($headersfilename);
            mailmanagerResourceError($errmsg);
          }
        }
        close(CONTENTFP);
      }
      unlink($g_form{$key}->{'content-filename'});
    }
    # did user want to attach any local files
    for ($index=1; $index<=$g_prefs{'mail__local_attach_elements'}; $index++) {
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
          require "$g_includelib/fm_util.pl";
          $mimetype = filemanagerGetMimeType($tmpfilename);
          $buffer = "--" . $boundary . "\n";
          $buffer .= "Content-Type: $mimetype; ";
          $buffer .= "name=\"$filename\"\n";
          $buffer .= "Content-Disposition: attachment; ";
          $buffer .= "filename=\"$filename\"\n";
          unless (print BODY $buffer) {
            close(HEADERS);
            close(BODY);
            unlink($bodyfilename);
            unlink($headersfilename);
            mailmanagerResourceError($errmsg);
          }
          # do we need to encode the local file or not?
          if ((-T "$tmpfilename") && ($tmpfilename !~ /pdf$/)) {
            unless (print BODY "\n") {
              close(HEADERS);
              close(BODY);
              unlink($bodyfilename);
              unlink($headersfilename);
              mailmanagerResourceError($errmsg);
            }
            open(CONTENTFP, "$tmpfilename");
            while (<CONTENTFP>) {
              $buffer = $_;
              $buffer =~ s/\r\n/\n/g;
              $buffer =~ s/\r//g;
              $buffer .= "\n" unless ($buffer =~ /\n$/);
              unless (print BODY "$buffer") {
                close(HEADERS);
                close(BODY);
                unlink($bodyfilename);
                unlink($headersfilename);
                mailmanagerResourceError($errmsg);
              } 
            }
            close(CONTENTFP);
          }
          else {
            unless (print BODY "Content-Transfer-Encoding: base64\n\n") {
              close(HEADERS);
              close(BODY);
              unlink($bodyfilename);
              unlink($headersfilename);
              mailmanagerResourceError($errmsg);
            }
            open(CONTENTFP, "$tmpfilename");
            while (read(CONTENTFP, $buffer, 54)) {
              $encbuffer = mailmanagerEncode64($buffer);
              unless (print BODY "$encbuffer") {
                close(HEADERS);
                close(BODY);
                unlink($bodyfilename);
                unlink($headersfilename);
                mailmanagerResourceError($errmsg);
              }
            }  
            # if necessary, close current message part with a newline
            if ($encbuffer !~ /\n$/) {
              unless (print BODY "\n") {
                close(HEADERS);
                close(BODY);
                unlink($bodyfilename);
                unlink($headersfilename);
                mailmanagerResourceError($errmsg);
              }
            }
            close(CONTENTFP);
          }
        }
      }
    }
    unless (print BODY "--" . $boundary . "--\n") {
      close(HEADERS);
      close(BODY);
      unlink($bodyfilename);
      unlink($headersfilename);
      mailmanagerResourceError($errmsg);
    }
  }
  else {
    # single part (text-only) message
    if ($languagepref eq "ja") {
      $buffer = "Content-Type: text/plain; charset=iso-2022-jp\n";
      unless (print HEADERS $buffer) {
        close(HEADERS);
        close(BODY);
        unlink($bodyfilename);
        unlink($headersfilename);
        mailmanagerResourceError($errmsg);
      }
    }
    unless (print BODY "$g_form{'send_body'}") {
      close(HEADERS);
      close(BODY);
      unlink($bodyfilename);
      unlink($headersfilename);
      mailmanagerResourceError($errmsg);
    }
  }

  # close the message body file descriptor
  close(BODY);

  # add just a couple more headers based on the message body just built
  $content_length = (stat($bodyfilename))[7];
  unless (print HEADERS "Content-Length: $content_length\n") {
    close(HEADERS);
    unlink($bodyfilename);
    unlink($headersfilename);
    mailmanagerResourceError($errmsg);
  }
  $numlines = 0;
  open(BODY, "$bodyfilename");
  $numlines++ while(<BODY>);
  close(BODY);
  unless (print HEADERS "Lines: $numlines\n") {
    close(HEADERS);
    unlink($bodyfilename);
    unlink($headersfilename);
    mailmanagerResourceError($errmsg);
  }

  # write a blank space to the message headers file descriptor and close
  unless (print HEADERS "\n") {
    close(HEADERS);
    unlink($bodyfilename);
    unlink($headersfilename);
    mailmanagerResourceError($errmsg);
  }
  close(HEADERS);

  # save outgoing message to file if applicable
  if ($g_form{'send_fcc'} && ($g_form{'send_fcc'} eq "yes")) {
    # build some headers that are only stored to the fcc folder
    $datestring = localtime($g_curtime);
    $g_form{'send_from'} =~ m{\b([\w.\-\&]+?@[\w.-]+?)(?=[.-]*(?:[^\w.-]|$))};
    $fromstring = $1 || mailmanagerUserSystemEmailAddress();
    $fromstring = "From $xsender $datestring\n";
    $datestring = dateBuildTimeString("numeric");
    $datestring = "Date: $datestring\n";
    $status = "Status: RO\n\n";
    # does the user have adequate disk space, check to see if the
    # user if over quota
    $msgsize = length($fromstring) + length($datestring) + length($status);
    ($fsize) = (stat($headersfilename))[7];
    $msgsize += $fsize;
    ($fsize) = (stat($bodyfilename))[7];
    $msgsize += $fsize;
    # get the current quota use
    require "$g_includelib/fm_util.pl";
    $used = filemanagerGetQuotaUsage();
    if (($g_users{$g_auth{'login'}}->{'ftpquota'} == 0) ||
        (($msgsize + $used) < ($g_users{$g_auth{'login'}}->{'ftpquota'} * 1048576))) {
      # user has enough room to save a copy to the fcc folder
      # get the full path of the fcc folder
      $fullpath =  mailmanagerBuildFullPath($g_form{'fcc_folder'});
      $addnewline = 0;
      if (-e "$fullpath") {
        $addnewline = 1;
        open(TFP, "$fullpath");
        seek(TFP, -2, 2);
        read(TFP, $secondlastchar, 1);
        read(TFP, $lastchar, 1);
        if (($secondlastchar eq "\n") && ($lastchar eq "\n")) {
          $addnewline = 0;
        }
        close(TFP);
      }
      else {
        # create any parent directories necessary to fulfill the request
        $parentdir = $fullpath;
        $parentdir =~ s/[^\/]+$//g;
        $parentdir =~ s/\/+$//g;
        mailmanagerCreateDirectory($parentdir);
      }
      # open mailbox and append message
      open(TFP, ">>$fullpath") || mailmanagerResourceError(
         "open(TFP, >>$fullpath) failed in mailmanagerSendMessage");
      print TFP "\n" if ($addnewline);
      # doctor up the headers so it looks like a folder message instead
      # of an outgoing message (i.e. add the "From " and "Date:" headers)
      print TFP $fromstring;
      print TFP $datestring;
      open(HEADERS, "$headersfilename");
      while (<HEADERS>) {
        last if ($_ eq "\n");  # ignore last \n; write after Status (see below)
        print TFP $_;
      }
      close(HEADERS);
      print TFP $status;
      open(BODY, "$bodyfilename");
      print TFP $_ while (<BODY>);
      close(BODY);
      close(TFP);
    }
  }

  # call sendmail and send message
  # -oi: ignore dots in incoming message
  # -oem: mail back errors
  # -t: read body of message for recipient list
  # -f: set the name of the from person
  $status = mailmanagerInvokeSendmail("-oi -oem -t -f$g_auth{'login'}", 
                                      $headersfilename, $bodyfilename);

  # store 'from' email address to last.emailaddress 
  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  if (open(LEFP, ">$homedir/.imanager/last.emailaddress.$$")) {
    print LEFP "$g_form{'send_from'}\n";
    close(LEFP);
    rename("$homedir/.imanager/last.emailaddress.$$",
           "$homedir/.imanager/last.emailaddress");
  }

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

  # do some miscellaneous tasks and redirect
  if (($g_form{'type'} eq "reply") || ($g_form{'type'} eq "groupreply")) {
    mailmanagerUpdateMessageStatusFlag("A");
    $g_form{'type'} = "";
    $status = $MAILMANAGER_SEND_SUCCESS_REPLY if (!$status);
    redirectLocation("mailmanager.cgi", $status);
  }
  else {
    $g_form{'type'} = "";
    $status = $MAILMANAGER_SEND_SUCCESS if (!$status);
    redirectLocation("mailmanager.cgi", $status);
  }
}

##############################################################################
# eof

1;

