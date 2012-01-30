#
# mm_save.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/mm_save.pl,v 2.12.2.10 2006/04/25 19:48:24 rus Exp $
#
# mail manager save message functions
#

##############################################################################

sub mailmanagerHandleSaveMessageRequest
{
  local($fullpath, $tmpfile, $errmsg);

  encodingIncludeStringLibrary("mailmanager");

  if ($g_form{'message'}) {
    # special case: viewing a message/rfc822 attachment
    mailmanagerSaveAttachedMessage();
  }

  if ($g_form{'midfile'}) {
    # read in selected messages from file
    $tmpfile = $g_tmpdir . "/.saveselectedmid-" . $g_form{'midfile'};
    open(TFP, "$tmpfile") ||
      mailmanagerResourceError("open(TFP, >$tmpfile)");
    $g_form{'selected'} = <TFP>;
    chomp($g_form{'selected'});
    $g_form{'messageid'} = <TFP>;
    chomp($g_form{'selected'});
    $g_form{'messagepart'} = <TFP>;
    chomp($g_form{'messagepart'});
    close(TFP);
  }
  else {
    if ((!$g_form{'selected'}) && $g_form{'messageid'}) {
      # saving from view message (as opposed to saving tagged)
      $g_form{'selected'} = $g_form{'messageid'};
    }
    # build a temporary file to store the selected message ids
    $g_form{'midfile'} = $g_curtime . "-" . $$;
    $tmpfile = $g_tmpdir . "/.saveselectedmid-" . $g_form{'midfile'};
    open(TFP, ">$tmpfile") ||
      mailmanagerResourceError("open(TFP, >$tmpfile)");
    print TFP "$g_form{'selected'}\n";
    print TFP "$g_form{'messageid'}\n";
    print TFP "$g_form{'messagepart'}\n";
    close(TFP);
  }

  # check for permission to use wizard
  if ($g_form{'messagepart'}) {
    # is user allowed to save a mail attachment or encoded mail message body?
    unless ($g_users{$g_auth{'login'}}->{'ftp'}) {
      # denied privileges ... ftp group membership is required
      redirectLocation("mailmanager.cgi", 
                       $MAILMANAGER_SAVE_ATTACHMENT_DENIED_TEXT); 
    }
  }
  else {
    # is user allowed to save mail to a different folder?
    if ((($g_users{$g_auth{'login'}}->{'ftp'} == 0) &&
         ($g_users{$g_auth{'login'}}->{'imap'} == 0)) ||
        ($g_users{$g_auth{'login'}}->{'mail_access_level'} ne "full")) {
      # denied privileges ... ftp or imap group membership is required
      redirectLocation("mailmanager.cgi", $MAILMANAGER_SAVE_DENIED_TEXT); 
    }
  }

  # handle cancel requests
  if ($g_form{'action'} && ($g_form{'action'} eq "$CANCEL_STRING")) {
    if ($g_form{'midfile'}) {
      $tmpfile = $g_tmpdir . "/.saveselectedmid-" . $g_form{'midfile'};
      unlink($tmpfile);
    }
    if ($g_form{'messagepart'}) {
      # cancelling saving a message part
      redirectLocation("mailmanager.cgi", 
                       $MAILMANAGER_SAVE_ATTACHMENT_CANCEL_TEXT); 
    }
    else {
      # cancelling saving a message to a mail folder
      redirectLocation("mailmanager.cgi", $MAILMANAGER_SAVE_CANCEL_TEXT); 
    }
  }

  # build new destination full path spec
  if ($g_form{'destfile'}) {
    if ($g_form{'destfile'} eq "!") {
      $fullpath = mailmanagerGetDefaultIncomingMailbox();
    }
    else {
      $fullpath = mailmanagerBuildFullPath($g_form{'destfile'});
      $g_form{'destfile'} = $fullpath;
      if ($g_users{$g_auth{'login'}}->{'chroot'}) {
        $g_form{'destfile'} =~ s/^$g_users{$g_auth{'login'}}->{'home'}//;
      }
      else {
        $g_form{'destfile'} =~ s/^$g_users{$g_auth{'login'}}->{'home'}/\~/;
      }
    }
  }
  else {
    if ($g_form{'messagepart'}) {
      # saving a message part to a file
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

  if ($g_form{'messagepart'}) {
    # messagepart exists: saving a message part (i.e. attachment) to a file
    mailmanagerSaveAttachmentQuotaCheck();
    if ($fullpath && (!(-d "$fullpath"))) {
      # have a valid full pathname; save attachment to file
      if ((-e "$fullpath") && ($g_form{'confirm'} ne "yes") &&
          ($g_prefs{'ftp__confirm_file_overwrite'} eq "yes")) {
        # print out an overwrite confirm form
        mailmanagerSaveAttachmentConfirmForm($fullpath);
      }
      else {
        mailmanagerSaveAttachmentToFile($fullpath);
        redirectLocation("mailmanager.cgi", 
                         $MAILMANAGER_SAVE_ATTACHMENT_SUCCESS_TEXT);
        exit(0);
      }
    }
  }
  else {
    # messagepart does not exist: saving a message to a mailbox
    if ($fullpath && ((-T "$fullpath") || (!(-e "$fullpath")))) {
      # fullpath is an existing text file or does not exist at all
      if ($g_mailbox_fullpath eq $fullpath) {
        # source folder and target folder are the same
        $errmsg = $MAILMANAGER_SAVE_IDENTICAL_FOLDER_ERROR;
        mailmanagerSelectSaveMessageDestinationForm($fullpath, $errmsg);
      }
      else {
        # save selected messages to mailbox
        mailmanagerSaveSelectedMessages($fullpath);
      }
    }
  }

  # if we have made it this far, then print out the select target destination
  # form that is specific to the selected save request type
  if ($g_form{'messagepart'}) {
    mailmanagerSelectSaveAttachmentDestinationForm($fullpath);
  }
  else {
    mailmanagerSelectSaveMessageDestinationForm($fullpath);
  }
}

##############################################################################

sub mailmanagerSaveAttachedMessage
{
  local($mid, $nmesg, $smbox, $fullpath, $curline);
  local($newmid, $header);

  $mid = $g_form{'messageid'} = $g_form{'selected'};
  ($nmesg) = (mailmanagerReadMail())[0];
  if ($nmesg == 0) {
    $string = $MAILMANAGER_MESSAGE_NOT_FOUND_TEXT;
    $string =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
    $string =~ s/__MESSAGEID__/$g_form{'messageid'}/g;
    delete($g_form{'messageid'});
    redirectLocation("mailmanager.cgi", $string);
  }

  # parse the message body into parts (always applicable)
  mailmanagerParseBodyIntoParts();

  # create the new mailbox and populate it with the message attachment
  $smbox = $g_tmpdir . "/.message_" . $g_form{'message'};
  mailmanagerSaveAttachmentToFile("$smbox-$$");
  open(MESGFP, ">$smbox") || 
    mailmanagerResourceError("open(TFP, >$smbox)");
  print MESGFP "From ";
  print MESGFP "$g_email{$mid}->{'__delivered_from__'} ";
  print MESGFP "$g_email{$mid}->{'__delivered_date__'}\n";
  $newmid = "";
  if (open(ATTACHFP, "$smbox-$$")) {
    $header = 1;
    while (<ATTACHFP>) {
      $curline = $_;
      if ($header && ($curline eq "\n")) {
        # end of headers; build a new message id if applicable 
        unless($newmid) {
           $newmid = $g_form{'messageid'};
           print MESGFP "Message-Id: $newmid\n";
        }
        $header = 0;
      }
      elsif ($header) {
        if ($curline =~ /^message-id:\ +(.*)/i) {
          $newmid = $1;
        }
      }
      print MESGFP $curline;
    }
    close(ATTACHFP);
  }
  close(MESGFP);
  unlink("$smbox-$$");

  unless ($g_users{$g_auth{'login'}}->{'path'} eq "/") {
    $smbox =~ s/^$g_users{$g_auth{'login'}}->{'path'}//;
  }
  $g_form{'mbox'} = $smbox; 
  $g_form{'messageid'} = $newmid;
  delete($g_form{'mpos'});
  delete($g_form{'mrange'});
  delete($g_form{'msort'});
  delete($g_form{'selected'});
  delete($g_form{'message'});
  delete($g_form{'messagepart'});
  redirectLocation("mailmanager.cgi");
  exit(0);
}

##############################################################################

sub mailmanagerSaveAttachmentConfirmForm
{
  local($fullpath, $errmsg) = @_;
  local($title);

  encodingIncludeStringLibrary("filemanager");

  $MAILMANAGER_TITLE =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
  if (($g_form{'messagepart'}) && ($g_form{'messagepart'} > -1)) {
    $title = $MAILMANAGER_SAVE_ATTACHMENT;
  }
  else {
    $title = $MAILMANAGER_SAVE_MESSAGE_BODY;
  }
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader("$MAILMANAGER_TITLE : $title");

  #
  # save attachment confirm table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$title");
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

  formOpen("name", "selectForm", "method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "confirm", "value", "yes");
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "midfile", 
            "value", $g_form{'midfile'});
  formInput("type", "hidden", "name", "destfile", 
            "value", $g_form{'destfile'});
  if ($errmsg) {
    htmlTextColorBold(">>> $errmsg <<<", "#cc0000");
    htmlP();
  }
  $FILEMANAGER_ACTIONS_NEWFILE_CONFIRM_OVERWRITE_TEXT =~ 
     s/__FILE__/$g_form{'destfile'}/;
  htmlText($FILEMANAGER_ACTIONS_NEWFILE_CONFIRM_OVERWRITE_TEXT);
  htmlP();
  formInput("type", "submit", "name", "action", "value", 
            $FILEMANAGER_CONFIRM_OVERWRITE);
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "action", "value", $CANCEL_STRING);
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

sub mailmanagerSaveAttachmentQuotaCheck
{
  local($nmesg, $mid, $string, $pci, $spci, $tpci);
  local($used, $bfilepos, $efilepos, $fsize, $ctenc, $sizetxt); 

  # load up the selected message
  $mid = $g_form{'messageid'} = $g_form{'selected'};
  ($nmesg) = (mailmanagerReadMail())[0];
  if ($nmesg == 0) {
    $string = $MAILMANAGER_MESSAGE_NOT_FOUND_TEXT;
    $string =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
    $string =~ s/__MESSAGEID__/$g_form{'selected'}/g;
    delete($g_form{'messageid'});
    redirectLocation("mailmanager.cgi", $string);
  }

  # parse the message body into parts (always applicable)
  mailmanagerParseBodyIntoParts();

  # get the current quota use
  require "$g_includelib/fm_util.pl";
  $used = filemanagerGetQuotaUsage();

  # get the size of the selected attachment (or message body)
  ($pci,$spci,$tpci) = split(/\./, $g_form{'messagepart'});
  if ($pci == -1) { 
    $ctenc = $g_email{$mid}->{'content-transfer-encoding'};
    $bfilepos = $g_email{$mid}->{'__filepos_message_body__'};
    $efilepos = $g_email{$mid}->{'__filepos_message_end__'};
  }
  elsif (!$spci) {
    $pci--;
    $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'content-transfer-encoding'};
    $bfilepos = $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_body__'};
    $efilepos = $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_end__'};
  }
  elsif (!$tpci) {
    $pci--;
    $spci--;
    $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-transfer-encoding'};
    $bfilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_body__'};
    $efilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_end__'};
  }
  else {
    $pci--;
    $spci--;
    $tpci--;
    $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-transfer-encoding'};
    $bfilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_body__'};
    $efilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_end__'};
  }
  $fsize = $efilepos - $bfilepos;
  # adjust the size down by 75% if base64 encoding (it's a rough guestimate)
  if ($ctenc =~ /base64/i) {
    $fsize = sprintf "%d", ($fsize * 0.75);
  }

  # does the user have enough room?
  if ($g_users{$g_auth{'login'}}->{'ftpquota'}) {
    if (($fsize + $used) > ($g_users{$g_auth{'login'}}->{'ftpquota'} * 1048576)) {
      # user doesn't have enough room
      if ($g_form{'messagepart'} > -1) {
        $MAILMANAGER_SAVE_ATTACHMENT_QUOTA_ERROR =~ 
          s/__ATYPE__/$MAILMANAGER_CONTENT_DISPOSITION_ATTACHMENT/g;
      }
      else {
        $MAILMANAGER_SAVE_ATTACHMENT_QUOTA_ERROR =~ 
          s/__ATYPE__/$MAILMANAGER_CONTENT_DISPOSITION_BODY/g;
      }
      if ($fsize < 1024) {
        $sizetxt = sprintf("%s $BYTES", $fsize);
      }
      elsif ($fsize < 1048576) {
        $sizetxt = sprintf("%1.1f $KILOBYTES", ($fsize / 1024));
      }
      else {
        $sizetxt = sprintf("%1.2f $MEGABYTES", ($fsize / 1048576));
      }
      $MAILMANAGER_SAVE_ATTACHMENT_QUOTA_ERROR =~ s/__SIZE__/$sizetxt/;
      htmlResponseHeader("Content-type: $g_default_content_type");
      labelCustomHeader($MAILMANAGER_RESOURCE_ERROR_TITLE);
      htmlText($MAILMANAGER_SAVE_ATTACHMENT_QUOTA_ERROR);
      htmlP();
      labelCustomFooter();
      exit(0);
    }
  }
}

##############################################################################

sub mailmanagerSaveAttachmentToFile
{
  local($fulltargetpath) = @_;

  local($mid, $pci, $spci, $tpci, $ctenc, $ctype);
  local($curline, $string, $buffer, $languagepref);
  local($bfilepos, $efilepos, $curfilepos);

  $mid = $g_form{'messageid'} = $g_form{'selected'};
  ($pci,$spci,$tpci) = split(/\./, $g_form{'messagepart'});

  $languagepref = encodingGetLanguagePreference();

  if ($pci == -1) {
    $ctype = $g_email{$mid}->{'content-type'};
    $ctenc = $g_email{$mid}->{'content-transfer-encoding'};
    $bfilepos = $g_email{$mid}->{'__filepos_message_body__'};
    $efilepos = $g_email{$mid}->{'__filepos_message_end__'};
  }
  elsif (!$spci) {
    $pci--;
    $ctype = $g_email{$mid}->{'parts'}[$pci]->{'content-type'};
    $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'content-transfer-encoding'};
    $bfilepos = $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_body__'};
    $efilepos = $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_end__'};
  }
  elsif (!$tpci) {
    $pci--;
    $spci--;
    $ctype = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-type'};
    $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-transfer-encoding'};
    $bfilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_body__'};  
    $efilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_end__'};
  }
  else {
    $pci--;
    $spci--;
    $tpci--;
    $ctype = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-type'};
    $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-transfer-encoding'};
    $bfilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_body__'};  
    $efilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_end__'};
  }

  open(TFP, ">$fulltargetpath") || 
    mailmanagerResourceError("open(TFP, >$fulltargetpath)");
  unless (open(MFP, "$g_mailbox_fullpath")) {
    mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
  } 
  seek(MFP, $bfilepos, 0);
  $buffer = "";
  while (<MFP>) {
    $curline = $_;
    # decode the current line
    if ($ctenc && ($ctenc =~ /quoted-printable/i)) {
      $string = mailmanagerDecodeQuotedPrintable($curline);
      $buffer .= $string;
      next if ($curline =~ /=\r?\n$/);  # keep reading the file
    }
    elsif ($ctenc && ($ctenc =~ /base64/i)) {
      $buffer = mailmanagerDecode64($curline);
    }
    else {
      $buffer = $curline;
    }
    # print out the current buffer
    if (($ctype =~ /text\//i) || ($ctype =~ /application\/text/i)) {
      # plain text ... markup as required 
      if ($languagepref eq "ja") {
        $buffer = mailmanagerMimeDecodeHeaderJP_QP($buffer);
        $buffer = jcode'euc($buffer);
      }
    }
    print TFP $buffer;
    $buffer = "";
    $curfilepos = tell(MFP);
    last if ($curfilepos >= $efilepos);
  }
  close(MFP);
  close(TFP);

  # remove any temporary files
  if ($g_form{'midfile'}) {
    $tmpfile = $g_tmpdir . "/.saveselectedmid-" . $g_form{'midfile'};
    unlink($tmpfile);
  }

  # saved a message part; redirect show success message
  if ($g_form{'messagepart'} > -1) {
    $MAILMANAGER_SAVE_ATTACHMENT_SUCCESS_TEXT =~ 
      s/__ATYPE__/$MAILMANAGER_CONTENT_DISPOSITION_ATTACHMENT/g;
  }
  else {
    $MAILMANAGER_SAVE_ATTACHMENT_SUCCESS_TEXT =~ 
      s/__ATYPE__/$MAILMANAGER_CONTENT_DISPOSITION_BODY/g;
  }
  $g_form{'messageid'} = $g_form{'selected'};
  $g_form{'selected'} = "";
}

##############################################################################

sub mailmanagerSaveSelectedMessages
{
  local($fulltargetpath) = @_;
  local($parentdir, $curmessageid, $tmpmessageid);
  local(@selected_mids, $smid, $message_is_selected, $msgcount);
  local($curline, $header, @curheaders, $index);
  local($numnewlinechars, $lastchar, $secondlastchar);
  local($tmpfile, %existing_mids, $errmsg);

  if ($ENV{'SCRIPT_NAME'} !~ /wizards\/mm_save.cgi/) {
    $ENV{'SCRIPT_NAME'} =~ /wizards\/([a-z_]*).cgi$/;
    $ENV{'SCRIPT_NAME'} =~ s/$1/mm_save/;
  }

  # figure out if we need to add a new line to the target file to provide
  # some spacing for the new messages
  $numnewlinechars = 0;
  if (-e "$fulltargetpath") {
    open(TFP, "$fulltargetpath");
    seek(TFP, -2, 2); 
    read(TFP, $secondlastchar, 1);
    read(TFP, $lastchar, 1);
    close(TFP);
    $numnewlinechars++ unless ($lastchar eq "\n");
    $numnewlinechars++ unless ($secondlastchar eq "\n");
  }
  else {
    # create any directories necessary to create non-existing target file
    $parentdir = $fulltargetpath;
    $parentdir =~ s/[^\/]+$//g;
    $parentdir =~ s/\/+$//g;
    mailmanagerCreateDirectory($parentdir);
  }

  # open source mailbox read only; target mailbox write (append) only
  open(SFP, "$g_mailbox_fullpath") ||
    mailmanagerResourceError("open(SFP, $g_mailbox_virtualpath)");
  open(TFP, ">>$fulltargetpath") || 
    mailmanagerResourceError("open(TFP, >>$fulltargetpath)");

  #  prime the error message
  $errmsg = "hard failure in mailmanagerSaveSelectedMessages ... ";
  $errmsg .= "server quota exceeded?";

  print TFP "\n" x $numnewlinechars;
  # step through the mailbox
  if ($g_form{'selected'} eq "__ALL__") {
    while (<SFP>) {
      print TFP $_;
    }
  }
  else {
    @selected_mids = split(/\|\|\|/, $g_form{'selected'});
    # march through the mailbox
    $msgcount = 1;   
    $curmessageid = "";
    $header = 0;     
    $message_is_selected = 0;
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
        # now check to see if the current messageid matches one we are
        # looking for... that is, if we are looking for any in particular
        $message_is_selected = 0;
        foreach $smid (@selected_mids) {
          if ($smid eq $curmessageid) {
            $message_is_selected = 1;
            last;
          }
        }
        if ($curmessageid && $message_is_selected) {
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
        if ($curmessageid && $message_is_selected) {
          print TFP "$curline" || mailmanagerResourceError($errmsg);
        }
      }
    }
  }

  # close the file handles
  close(SFP);
  close(TFP);

  # remove any temporary files
  if ($g_form{'midfile'}) {
    $tmpfile = $g_tmpdir . "/.saveselectedmid-" . $g_form{'midfile'};
    unlink($tmpfile);
  }

  if ($g_form{'rfs'} eq "yes") {  # rfs == removefromsource
    # remove selected message from source folder 
    require "$g_includelib/mm_delete.pl";
    mailmanagerDeleteSelectedMessages();
    # reset variable values and redirect
    $g_form{'selected'} = "" if ($g_form{'selected'});
    $g_form{'messageid'} = "" if ($g_form{'messageid'});
    redirectLocation("mailmanager.cgi", $MAILMANAGER_MOVE_SUCCESS_TEXT);
  }
  else {
    # reset variable values and redirect
    $g_form{'selected'} = "" if ($g_form{'selected'});
    redirectLocation("mailmanager.cgi", $MAILMANAGER_SAVE_SUCCESS_TEXT);
  }
}

##############################################################################

sub mailmanagerSelectSaveAttachmentDestinationForm
{
  local($fullpath, $errmsg) = @_;
  local($title, $mid, $languagepref, $size);
  local($mid, $pci, $spci, $tpci, $ctype, $cdisp, $desc, $ctenc);
  local($bfilepos, $efilepos, $fsize, $sizestring, $fname);

  if ($ENV{'SCRIPT_NAME'} !~ /wizards\/mm_save.cgi/) {
    $ENV{'SCRIPT_NAME'} =~ /wizards\/([a-z_]*).cgi$/;
    $ENV{'SCRIPT_NAME'} =~ s/$1/mm_save/;
  }

  # set the view type
  if ((!$g_form{'viewtype'}) || 
      (($g_form{'viewtype'} ne "short") && 
       ($g_form{'viewtype'} ne "long"))) {
    $g_form{'viewtype'} = "short";
  }

  $languagepref = encodingGetLanguagePreference();

  # get information about selected attachment (or message body)
  ($pci,$spci) = split(/\./, $g_form{'messagepart'});
  $mid = $g_form{'messageid'};
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
    $fname = "attachment." . $pci;
    $fname .= "-" . $spci if ($spci);
  }     
  if ($languagepref eq "ja") {
    $fname = mailmanagerMimeDecodeHeaderJP_QP($fname);
    $fname = jcode'euc(mimedecode($fname));
  }

  # figure out the size 
  $fsize = $efilepos - $bfilepos + 1; 
  # adjust the size down by 75% if base64 encoding (it's a rough guestimate)
  if ($ctenc =~ /base64/i) {
    $fsize = sprintf "%d", ($fsize * 0.75);
  }

  # tweak the content type a wee bit if applicable
  $ctype .= "; name=\"$fname\"" if ($ctype !~ /name=/);
  ($ctype) = (split(/\;/, $ctype))[0];

  $MAILMANAGER_TITLE =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
  if ($g_form{'messagepart'} > -1) {
    $title = $MAILMANAGER_SAVE_ATTACHMENT;
  }
  else {
    $title = $MAILMANAGER_SAVE_MESSAGE_BODY;
  }
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader("$MAILMANAGER_TITLE : $title");

  #
  # save attachment table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$title");
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

  formOpen("name", "selectForm", "method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "viewtype", 
            "value", $g_form{'viewtype'});
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "cwd", "value", $g_form{'destfile'});
  formInput("type", "hidden", "name", "midfile", 
            "value", $g_form{'midfile'});
  if ($errmsg) {
    htmlTextColorBold(">>> $errmsg <<<", "#cc0000");
    htmlP();
  }
  if ($g_form{'messagepart'} > -1) {
    $MAILMANAGER_SAVE_ATTACHMENT_SELECT_HELP_TEXT =~ 
      s/__ATYPE__/$MAILMANAGER_CONTENT_DISPOSITION_ATTACHMENT/g;
  }
  else {
    $MAILMANAGER_SAVE_ATTACHMENT_SELECT_HELP_TEXT =~ 
      s/__ATYPE__/$MAILMANAGER_CONTENT_DISPOSITION_BODY/g;
  }
  htmlText($MAILMANAGER_SAVE_ATTACHMENT_SELECT_HELP_TEXT);
  htmlP();
  # table of information about selected attachment (or message body)
  htmlTable();
  htmlTableRow();
  htmlTableData();
  htmlTextBold("&#160;&#160; $MAILMANAGER_CONTENT_TYPE:");
  htmlTableDataClose();
  htmlTableData();
  htmlText($ctype);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlTextBold("&#160;&#160; $MAILMANAGER_MESSAGE_SIZE_ABBREVIATED:");
  htmlTableDataClose();
  htmlTableData();
  if ($fsize < 1024) {
    $sizestring = sprintf("%s $BYTES", $fsize);
  }
  elsif ($fsize < 1048576) {
    $sizestring = sprintf("%1.1f $KILOBYTES", ($fsize / 1024));
  }
  else {
    $sizestring = sprintf("%1.2f $MEGABYTES", ($fsize / 1048576));
  }
  htmlText($sizestring);
  htmlTableDataClose();
  htmlTableRowClose();
  if ($ctenc) {
    htmlTableRow();
    htmlTableData();
    htmlTextBold("&#160;&#160; $MAILMANAGER_CONTENT_TRANSFER_ENCODING:");
    htmlTableDataClose();
    htmlTableData();
    htmlText($ctenc);
    htmlTableDataClose();
    htmlTableRowClose();
  }
  htmlTableRow();
  htmlTableData();
  htmlTextBold("&#160;&#160; $MAILMANAGER_CONTENT_DISPOSITION:");
  htmlTableDataClose();
  htmlTableData();
  if ($g_form{'messagepart'} > -1) {
    $desc = $MAILMANAGER_CONTENT_DISPOSITION_ATTACHMENT;
  }
  else {
    $desc = $MAILMANAGER_CONTENT_DISPOSITION_BODY;
  }
  if ($cdisp) {
    $desc .= "; $MAILMANAGER_CONTENT_DISPOSITION_FILENAME=\"$fname\"";
  }
  htmlText($desc);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  $size = formInputSize(45);
  $fname = $g_form{'destfile'} . "/" . $fname;
  $fname =~ s/\/\//\//g;
  formInput("size", $size, "name", "destfile", "value", $fname);
  htmlBR();
  formInput("type", "submit", "name", "action", "value", $SUBMIT_STRING);
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "action", "value", $CANCEL_STRING);
  formClose();
  htmlP();
  # separator
  htmlTable("cellpadding", "0", "cellspacing", "0", "border", "0", 
            "background", "$g_graphicslib/dotted.png", "width", "100\%");
  htmlTableRow();
  htmlTableData();
  htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  mailmanagerSelectDestinationFileFromList($fullpath);

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

sub mailmanagerSelectSaveMessageDestinationForm
{
  local($fullpath, $errmsg) = @_;
  local($nmesg, $title, $string, $mid, $size, $mcount, $checked);
  local($languagepref, $subject);

  if ($g_form{'selected'} ne "__ALL__") {
    # load up the selected message or messages
    $g_form{'messageid'} = $g_form{'selected'};
    ($nmesg) = (mailmanagerReadMail())[0];
    if ($nmesg == 0) {
      $string = $MAILMANAGER_MESSAGE_NOT_FOUND_TEXT;
      $string =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
      $string =~ s/__MESSAGEID__/$g_form{'selected'}/g;
      delete($g_form{'messageid'});
      redirectLocation("mailmanager.cgi", $string);
    }
  }

  if ($ENV{'SCRIPT_NAME'} !~ /wizards\/mm_save.cgi/) {
    $ENV{'SCRIPT_NAME'} =~ /wizards\/([a-z_]*).cgi$/;
    $ENV{'SCRIPT_NAME'} =~ s/$1/mm_save/;
  }

  # set the view type
  if ((!$g_form{'viewtype'}) || 
      (($g_form{'viewtype'} ne "short") && 
       ($g_form{'viewtype'} ne "long"))) {
    $g_form{'viewtype'} = "short";
  }

  $languagepref = encodingGetLanguagePreference();

  $MAILMANAGER_TITLE =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
  if ($g_form{'selected'} eq "__ALL__") {
    $title = $MAILMANAGER_SAVE_ALL;
  }
  elsif ($nmesg > 1) {
    $title = $MAILMANAGER_SAVE_TAGGED;
  }
  else {
    $title = $MAILMANAGER_SAVE_SINGLE;
  }
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader("$MAILMANAGER_TITLE : $title");

  #
  # save message confirm table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$title");
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

  formOpen("name", "selectForm", "method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "viewtype", 
            "value", $g_form{'viewtype'});
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "cwd", "value", $g_form{'destfile'});
  if ($g_form{'messageid'}) {
    formInput("type", "hidden", "name", "messageid", 
              "value", $g_form{'messageid'});
  }
  formInput("type", "hidden", "name", "midfile", 
            "value", $g_form{'midfile'});
  if ($errmsg) {
    htmlTextColorBold(">>> $errmsg <<<", "#cc0000");
    htmlP();
  }
  if ($g_form{'selected'} eq "__ALL__") {
    $string = $MAILMANAGER_SAVE_ALL_HELP_TEXT;
    $string =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
    htmlText($string);
    htmlP();
  } 
  else {
    $MAILMANAGER_SAVE_SELECTED_HELP_TEXT =~ s/__NUMBER__/$nmesg/;
    htmlText($MAILMANAGER_SAVE_SELECTED_HELP_TEXT);
    htmlP();
    # table of selected message(s)
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
    htmlTextBold("&#160;$MAILMANAGER_MESSAGE_SIZE_ABBREVIATED");
    htmlTableDataClose();
    htmlTableRowClose();
    $mcount = 0;
    foreach $mid (sort mailmanagerByPreference(keys(%g_email))) {
      $mcount++;
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
      $string = mailmanagerMimeDecodeHeader($string);
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
      htmlNoBR();
      htmlText("&#160;$g_email{$mid}->{'__size__'}");
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableRowClose();
#      if (($mcount == 4) && ($nmesg > 4)) {
#        htmlTableRow();
#        htmlTableData("colspan", "4");
#        $string = $MAILMANAGER_SAVE_SELECTED_CROPPED_TEXT;
#        $nmesg -= 4;
#        $string =~ s/__NUMBER__/$nmesg/;
#        htmlTextSmall("&#160;>> $string <<&#160;");
#        htmlTableDataClose();
#        htmlTableRowClose();
#        last;
#      }
    }
    htmlTableClose();
    htmlP();
  }
  if ($g_form{'cwd'} && (($g_form{'destfile'} eq "") || 
                         ($g_form{'cwd'} eq $g_form{'destfile'}))) {
    htmlTextColorBold(">>> $MAILMANAGER_SAVE_SELECT_HELP_TEXT <<<", "#cc0000");
  }
  else {
    htmlText($MAILMANAGER_SAVE_SELECT_HELP_TEXT);
  }
  htmlP();
  $size = formInputSize(45);
  formInput("size", $size, "name", "destfile", "value", $g_form{'destfile'});
  htmlBR();
  formInput("type", "submit", "name", "action", "value", $SUBMIT_STRING);
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "action", "value", $CANCEL_STRING);
  htmlP();
  $checked = ($g_form{'rfs'} eq "yes") ? "CHECKED" : "";
  print <<ENDTEXT;
<script language="JavaScript1.1">
  document.write("&#160; ");
  document.write("<input type=\\\"checkbox\\\" name=\\\"rfs\\\" ");
  document.write("value=\\\"yes\\\" $checked> ");
  document.write("<font face=\\\"arial, helvetica\\\" size=\\\"2\\\">");
  document.write("$MAILMANAGER_SAVE_SELECTED_REMOVE_FROM_SOURCE");
  document.write("</font>");
</script>
ENDTEXT
  formClose();
  htmlP();
  # separator
  htmlTable("cellpadding", "0", "cellspacing", "0", "border", "0", 
            "background", "$g_graphicslib/dotted.png", "width", "100\%");
  htmlTableRow();
  htmlTableData();
  htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  mailmanagerSelectDestinationFileFromList($fullpath);

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
# eof

1;

