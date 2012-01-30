#
# mm_addressbook.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/mm_addressbook.pl,v 2.12.2.6 2006/04/25 19:48:24 rus Exp $
#
# functions to show, edit, remove address book entries
#

##############################################################################

sub mailmanagerAddressBookByPreference
{
  if (!$g_form{'sort_by'}) {
    return($g_addressbook{$a}->{'name'} cmp $g_addressbook{$b}->{'name'});
  }
  elsif ($g_form{'sort_by'} eq "email") {
    return($g_addressbook{$a}->{'email'} cmp $g_addressbook{$b}->{'email'});
  }
}

##############################################################################

sub mailmanagerAddressBookBySelection
{
  if (($a =~ /__NEWABC/) || ($a =~ /__NEWABC/)) {
    return($a cmp $b);
  }
  else {
    return($g_addressbook{$a}->{'name'} cmp $g_addressbook{$b}->{'name'});
  }
}

##############################################################################

sub mailmanagerAddressBookCheckRequest
{
  local(@selected, $contact, %errors, $nkey, $ekey);
  local($ampcount, $changes, $mesg);
  local($languagepref);

  $languagepref = encodingGetLanguagePreference();

  if (($g_form{'action'} eq "add") || ($g_form{'action'} eq "edit")) {
    if ($g_form{'absubmit'} &&
        (($g_form{'absubmit'} eq $SUBMIT_STRING) ||
         ($g_form{'absubmit'} eq $CONFIRM_STRING))) {
      # perform error checks on data submission
      @selected = split(/\|\|\|/, $g_form{'selected'});
      foreach $contact (@selected) {
        $nkey = $contact . "_name";
        $ekey = $contact . "_email";
        if (((!$g_form{$nkey}) && ($g_form{$ekey})) ||
            (($g_form{$nkey}) && (!$g_form{$ekey}))) {
          # both fields must be filled in
          $errors{$contact} = $MAILMANAGER_ADDRESSBOOK_ERROR_INCOMPLETE;
        }
      }
      if (keys(%errors)) {
        mailmanagerAddressBookEditContactForm("", %errors);
      }
      # scrub up user submitted data
      foreach $contact (@selected) {
        $nkey = $contact . "_name";
        $ekey = $contact . "_email";
        $g_form{$nkey} =~ s/^\s+//;
        $g_form{$nkey} =~ s/\s+$//;
        if ($languagepref eq "ja") {
          $g_form{$nkey} = jcode'euc($g_form{$nkey});
        }
        $g_form{$ekey} =~ s/^\s+//;
        $g_form{$ekey} =~ s/\s+$//;
        $g_form{$ekey} =~ s/\r\n/\n/g;
        $g_form{$ekey} =~ s/\r//g;
        $g_form{$ekey} =~ s/\n//g;
        $ampcount = $g_form{$ekey} =~ tr/\@/\@/;
        if ($ampcount > 1) {
          # filename will be "P_NAME" (P for "plural list")
          $g_form{$nkey} = mailmanagerAddressBookSanitizePath($g_form{$nkey});
        }
        else {
          # filename will be "A_ADDRESS" (A for "address")
          $g_form{$ekey} = mailmanagerAddressBookSanitizePath($g_form{$ekey});
        }
      }
      # check to see if any changes were made
      $changes = 0;
      foreach $contact (@selected) {
        $nkey = $contact . "_name";
        $ekey = $contact . "_email";
        if (($g_form{$nkey} ne $g_addressbook{$contact}->{'name'}) ||
            ($g_form{$ekey} ne $g_addressbook{$contact}->{'email'})) {
          $changes = 1;
          last;
        }
      }
      $mesg = $MAILMANAGER_ADDRESSBOOK_CHANGE_NONE_FOUND;
      mailmanagerAddressBookEditContactForm($mesg) unless ($changes);
      # changes exist; remove any entries that haven't been changed
      foreach $contact (@selected) {
        $nkey = $contact . "_name";
        $ekey = $contact . "_email";
        if ((($g_form{'action'} eq "add") &&
             (!$g_form{$nkey}) && (!$g_form{$ekey})) ||
            (($g_form{'action'} eq "edit") &&
             ($g_form{$nkey} eq $g_addressbook{$contact}->{'name'}) &&
             ($g_form{$ekey} eq $g_addressbook{$contact}->{'email'}))) {
          # nothing has changed
          $g_form{'selected'} =~ s/^\Q$contact\E$//;
          $g_form{'selected'} =~ s/^\Q$contact\E\|\|\|//;
          $g_form{'selected'} =~ s/\|\|\|\Q$contact\E\|\|\|/\|\|\|/;
          $g_form{'selected'} =~ s/\|\|\|\Q$contact\E$//;
        }
      }
    }
  }
  elsif ($g_form{'action'} eq "import") {
    # no checks need to be made here since the import procedures parse
    # and scrub the incoming data 
  }
}

##############################################################################

sub mailmanagerAddressBookConfirmForm
{
  local($title, $subtitle);
  local(@selected, $contact, $nkey, $ekey, $ampcount);
  local($abdir, $filename, $cstr);

  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_ADDRESSBOOK_TITLE : ";
  if ($g_form{'action'} eq "add") {
    $subtitle = $MAILMANAGER_ADDRESSBOOK_ADD;
  }
  elsif ($g_form{'action'} eq "edit") {
    $subtitle = $MAILMANAGER_ADDRESSBOOK_EDIT_TITLE;
  }
  elsif ($g_form{'action'} eq "remove") {
    $subtitle = $MAILMANAGER_ADDRESSBOOK_REMOVE_TITLE;
  }
  elsif ($g_form{'action'} eq "purge") {
    $subtitle = $MAILMANAGER_ADDRESSBOOK_REMOVE_TITLE;
  }
  elsif ($g_form{'action'} eq "remove") {
    $subtitle = $MAILMANAGER_ADDRESSBOOK_REMOVE_TITLE;
  }
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader("$title $subtitle");

  #
  # confirm address book changes table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_ADDRESSBOOK_TITLE : $subtitle");
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

  if (($g_form{'action'} eq "add") || ($g_form{'action'} eq "edit") || 
      ($g_form{'action'} eq "import")) {
    htmlText($MAILMANAGER_ADDRESSBOOK_CHANGE_CONFIRM_TEXT);
  }
  elsif ($g_form{'action'} eq "remove") {
    htmlText($MAILMANAGER_ADDRESSBOOK_REMOVE_CONFIRM_TEXT);
  }
  elsif ($g_form{'action'} eq "purge") {
    htmlText($MAILMANAGER_ADDRESSBOOK_PURGE_CONFIRM_TEXT);
  }
  htmlP();

  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "confirm", "value", "yes");
  formInput("type", "hidden", "name", "action", "value", $g_form{'action'});
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "messageid", 
            "value", $g_form{'messageid'});
  formInput("type", "hidden", "name", "selected", "value", $g_form{'selected'});
  @selected = split(/\|\|\|/, $g_form{'selected'}) if ($g_form{'selected'});
  foreach $contact (@selected) {
    $nkey = $contact . "_name";
    $ekey = $contact . "_email";
    formInput("type", "hidden", "name", $nkey, "value", $g_form{$nkey});
    formInput("type", "hidden", "name", $ekey, "value", $g_form{$ekey});
  }
  if ($g_form{'action'} eq "add") {
    htmlUL();
    # confirm overwrites
    foreach $contact (sort mailmanagerAddressBookBySelection(@selected)) {
      $nkey = $contact . "_name";
      $ekey = $contact . "_email";
      next unless ($g_form{$nkey} || $g_form{$ekey});
      $abdir = mailmanagerGetDirectoryPath("addressbook");
      $ampcount = $g_form{$ekey} =~ tr/\@/\@/;
      if ($ampcount > 1) {
        $filename = "P_" . $g_form{$nkey};
      }
      else {
        $filename = "A_" . $g_form{$ekey};
      }
      if (-e "$abdir/$filename") {
        # address book entry already exists ... confirm overwrite
        $cstr = $MAILMANAGER_ADDRESSBOOK_CHANGE_CONFIRM_OVERWRITE;
        if ($ampcount > 1) {
          $cstr =~ s/__ENTRY__/$g_form{$nkey}/;
        }
        else {
          $cstr =~ s/__ENTRY__/$g_form{$ekey}/;
        }
        htmlListItem();
        htmlTextBold($cstr);
        htmlBR();
        htmlTable("border", "0", "cellspacing", "0", "cellpadding", "0");
        htmlTableRow();
        htmlTableData("valign", "top");
        htmlNoBR();
        htmlText("&#160;&#160;&#160;&#160;");
        htmlText("$MAILMANAGER_ADDRESSBOOK_CHANGE_CONFIRM_OLD_VALUE:");
        htmlText("&#160;&#160;");
        htmlNoBRClose();
        htmlTableDataClose();
        htmlTableData("valign", "top");
        htmlNoBR();
        htmlText($g_addressbook{$filename}->{'name'});
        htmlNoBRClose();
        htmlTableDataClose();
        htmlTableData("valign", "top");
        htmlText("&#160;=>&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "top");
        htmlFont("class", "text", "face", "arial, helvetica", "size", "2",
                 "style", "font-family:arial, helvetica; font-size:12px");
        $cstr = htmlSanitize($g_addressbook{$filename}->{'email'});
        $cstr = "<nobr>$cstr</nobr>";
        $cstr =~ s/\,(\ )?/\<\/nobr\>\,\ \<nobr\>/g;
        print "$cstr";
        htmlFontClose();  
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("valign", "top");
        htmlNoBR();
        htmlText("&#160;&#160;&#160;&#160;");
        htmlText("$MAILMANAGER_ADDRESSBOOK_CHANGE_CONFIRM_NEW_VALUE:");
        htmlText("&#160;&#160;");
        htmlNoBRClose();
        htmlTableDataClose();
        htmlTableData("valign", "top");
        htmlNoBR();
        htmlText($g_form{$nkey});
        htmlNoBRClose();
        htmlTableDataClose();
        htmlTableData("valign", "top");
        htmlText("&#160;=>&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "top");
        htmlFont("class", "text", "face", "arial, helvetica", "size", "2",
                 "style", "font-family:arial, helvetica; font-size:12px");
        $cstr = htmlSanitize($g_form{$ekey});
        $cstr = "<nobr>$cstr</nobr>";
        $cstr =~ s/\,(\ )?/\<\/nobr\>\,\ \<nobr\>/g;
        print "$cstr";
        htmlFontClose();  
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableClose();
        htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
        htmlBR();
      }
    }
    htmlULClose();
    htmlP();
  }
  elsif ($g_form{'action'} eq "edit") {
    htmlUL();
    # confirm editions
    foreach $contact (sort mailmanagerAddressBookBySelection(@selected)) {
      $nkey = $contact . "_name";
      $ekey = $contact . "_email";
      next unless ($g_form{$nkey} || $g_form{$ekey});
      if ($g_form{$nkey} ne $g_addressbook{$contact}->{'name'}) {
        # name has changed ... confirm edit
        $cstr = $MAILMANAGER_ADDRESSBOOK_CHANGE_CONFIRM_EDIT_NAME;
        $cstr =~ s/__ENTRY__/$g_addressbook{$contact}->{'name'}/;
        $cstr =~ s/__NEWENTRY__/$g_form{$nkey}/;
        htmlListItem();
        htmlTextBold($cstr);
        htmlBR();
      }
      if ($g_form{$ekey} ne $g_addressbook{$contact}->{'email'}) {
        # email has changed ... confirm edit
        $cstr = $MAILMANAGER_ADDRESSBOOK_CHANGE_CONFIRM_EDIT_VALUE;
        if ($g_form{$nkey} ne $g_addressbook{$contact}->{'name'}) {
          $cstr =~ s/__ENTRY__/$g_form{$nkey}/;
        }
        else {
          $cstr =~ s/__ENTRY__/$g_addressbook{$contact}->{'name'}/;
        }
        htmlListItem();
        htmlTextBold($cstr);
        htmlBR();
        htmlTable("border", "0", "cellspacing", "0", "cellpadding", "0");
        htmlTableRow();
        htmlTableData("valign", "top");
        htmlNoBR();
        htmlText("&#160;&#160;&#160;&#160;");
        htmlText("$MAILMANAGER_ADDRESSBOOK_CHANGE_CONFIRM_OLD_VALUE:");
        htmlText("&#160;&#160;");
        htmlNoBRClose();
        htmlTableDataClose();
        htmlTableData("valign", "top");
        htmlFont("class", "text", "face", "arial, helvetica", "size", "2",
                 "style", "font-family:arial, helvetica; font-size:12px");
        $cstr = htmlSanitize($g_addressbook{$contact}->{'email'});
        $cstr = "<nobr>$cstr</nobr>";
        $cstr =~ s/\,(\ )?/\<\/nobr\>\,\ \<nobr\>/g;
        print "$cstr";
        htmlFontClose();  
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("valign", "top");
        htmlNoBR();
        htmlText("&#160;&#160;&#160;&#160;");
        htmlText("$MAILMANAGER_ADDRESSBOOK_CHANGE_CONFIRM_NEW_VALUE:");
        htmlText("&#160;&#160;");
        htmlNoBRClose();
        htmlTableDataClose();
        htmlTableData("valign", "top");
        htmlFont("class", "text", "face", "arial, helvetica", "size", "2",
                 "style", "font-family:arial, helvetica; font-size:12px");
        $cstr = htmlSanitize($g_form{$ekey});
        $cstr = "<nobr>$cstr</nobr>";
        $cstr =~ s/\,(\ )?/\<\/nobr\>\,\ \<nobr\>/g;
        print "$cstr";
        htmlFontClose();  
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableClose();
        htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
        htmlBR();
      }
    }
    # confirm removals
    foreach $contact (sort mailmanagerAddressBookBySelection(@selected)) {
      $nkey = $contact . "_name";
      $ekey = $contact . "_email";
      unless ($g_form{$nkey} || $g_form{$ekey}) {
        # both name and email set to "" ... confirm removal
        $cstr = $MAILMANAGER_ADDRESSBOOK_CHANGE_CONFIRM_REMOVE;
        $cstr =~ s/__ENTRY__/$g_addressbook{$contact}->{'name'}/;
        htmlListItem();
        htmlTextBold($cstr);
        htmlBR();
      }
    }
    htmlULClose();
    htmlP();
  }
  elsif ($g_form{'action'} eq "import") {
    # confirm overwrites?  not now... maybe in the future.
  }
  elsif ($g_form{'action'} eq "remove") {
    htmlTable("border", "0", "cellspacing", "0", "cellpadding", "2");
    htmlTableRow();
    htmlTableData();
    htmlNoBR();
    htmlTextBold("&#160;$MAILMANAGER_ADDRESSBOOK_CONTACT_NAME&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData();
    htmlNoBR();
    htmlTextBold($MAILMANAGER_ADDRESSBOOK_CONTACT_EMAIL);
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    foreach $contact (sort mailmanagerAddressBookBySelection(@selected)) {
      htmlTableRow();
      htmlTableData("valign", "top");
      htmlNoBR();
      htmlText("&#160;$g_addressbook{$contact}->{'name'}&#160;&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableData("valign", "top");
      htmlFont("class", "text", "face", "arial, helvetica", "size", "2",
               "style", "font-family:arial, helvetica; font-size:12px");
      $cstr = htmlSanitize($g_addressbook{$contact}->{'email'});
      $cstr = "<nobr>$cstr</nobr>";
      $cstr =~ s/\,(\ )?/\<\/nobr\>\,\ \<nobr\>/g;
      print "$cstr";
      htmlFontClose();  
      htmlTableDataClose();
      htmlTableRowClose();
    }
    htmlTableClose();
    htmlP();
  }
  formInput("type", "submit", "name", "absubmit", "value", $CONFIRM_STRING);
  formInput("type", "submit", "name", "absubmit", "value", $CANCEL_STRING);
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

sub mailmanagerAddressBookConfirmRequest
{
  local(@selected, $contact, %errors, $nkey, $ekey, $ampcount);
  local($abdir, $fullpath);

  return if ($g_form{'confirm'} eq "yes");

  if (($g_form{'action'} eq "add") || ($g_form{'action'} eq "edit")) {
    # is a confirmation of actions even necessary?
    if ($g_prefs{'mail__address_book_confirm_changes'} ne "yes") {
      $g_form{'confirm'} = "yes";
      return;
    }
    # check submission
    if ($g_form{'absubmit'} eq $SUBMIT_STRING) {
      # editions, removals, and overwrites need a confirmation
      @selected = split(/\|\|\|/, $g_form{'selected'});
      foreach $contact (@selected) {
        $nkey = $contact . "_name";
        $ekey = $contact . "_email";
        if ($contact =~ /__NEWABC/) { 
          # confirm overwrites when adding new contacts
          next unless ($g_form{$nkey} || $g_form{$ekey});
          $abdir = mailmanagerGetDirectoryPath("addressbook");
          $ampcount = $g_form{$ekey} =~ tr/\@/\@/;
          if ($ampcount > 1) {
            $fullpath .= "/P_" . $g_form{$nkey};
          }
          else {
            $fullpath .= "/A_" . $g_form{$ekey};
          }
          if (-e "$fullpath") {
            # address book entry already exists ... confirm overwrite
            mailmanagerAddressBookConfirmForm();
          }
        }
        else {
          # confirm removals and editions when editing contacts
          if ($contact !~ /__NEWABC/) {
            if ((!$g_form{$nkey}) && (!$g_form{$ekey})) {
              # both name and email set to "" ... confirm removal
              mailmanagerAddressBookConfirmForm();
            }
            elsif (($g_form{$nkey} ne $g_addressbook{$contact}->{'name'}) ||
                   ($g_form{$ekey} ne $g_addressbook{$contact}->{'email'})) {
              # name or email has changed ... confirm edit
              mailmanagerAddressBookConfirmForm();
            }
          }
        }
      }
      # if we make it here, then there was nothing that the user submitted
      # that requies confirmation; set 'confirm' equal to yes so that the
      # requested action can be perfomed back in the HandleRequest func
      $g_form{'confirm'} = "yes";
    }
  }
  elsif ($g_form{'action'} eq "import") {
    # confirm overwrites?  not now... maybe in the future.
  }
  elsif (($g_form{'action'} eq "remove") || ($g_form{'action'} eq "purge")) {
    # is a confirmation of actions even necessary?
    if ($g_prefs{'mail__address_book_confirm_changes'} ne "yes") {
      $g_form{'confirm'} = "yes";
      return;
    }
    # confirm removal
    mailmanagerAddressBookConfirmForm();
  }
}

##############################################################################

sub mailmanagerAddressBookDisplay
{
  local($mesg) = @_;
  local(@msglines, $javascript, $css);
  local($title, $ncontacts, $contact, $count, $encoded, $encargs);
  local($string, $sizetext, $etxt, $low);

  $javascript = javascriptTagUntagAll();
  $javascript .= javascriptHighlightUnhighlightRow();

  $css = "<style type=\"text/css\">
.highlighted { background:#dddddd }
.unhighlighted { background:#ffffff }
</style>";

  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_ADDRESSBOOK_TITLE";
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title, "", $javascript, $css);

  if (!$mesg && $g_form{'msgfileid'}) {
    # read message from temporary state message file
    $mesg = redirectMessageRead($g_form{'msgfileid'});
  }
  if ($mesg) {
    @msglines = split(/\n/, $mesg);
    foreach $mesg (@msglines) {
      htmlTextColorBold(">>> $mesg <<<", "#cc0000");
      htmlBR();
    }
    htmlBR();
  }

  #
  # address book table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_ADDRESSBOOK_TITLE");
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

  $encoded = encodingStringToURL($g_form{'mbox'});
  $encargs = htmlAnchorArgs("mbox", $encoded, "mpos", $g_form{'mpos'}, 
                            "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'});
  if ($g_form{'messageid'}) {
    $encoded = encodingStringToURL($g_form{'messageid'});
    $encargs .= "&messageid=$encoded";
  }

  # determine the address book size
  if ($g_addressbook{'__size__'} < 1024) {
    $sizetext = sprintf("%s $BYTES", $g_addressbook{'__size__'});
  }
  elsif ($g_addressbook{'__size__'} < 1048576) {
    $sizetext = sprintf("%1.1f $KILOBYTES", 
                        ($g_addressbook{'__size__'} / 1024));
  }
  else {
    $sizetext = sprintf("%1.2f $MEGABYTES", 
                        ($g_addressbook{'__size__'} / 1048576));
  }
  delete($g_addressbook{'__size__'});  # don't need this anymore
  $ncontacts = keys(%g_addressbook);

  # button bar
  htmlImg("width", "3", "height", "50", "src", "$g_graphicslib/sp.gif");
  htmlAnchor("href", "mm_addressbook.cgi?action=add&$encargs",
             "title", "$MAILMANAGER_ADDRESSBOOK_ADD");
  htmlImg("border", "0", "width", "50", "height", "50", "alt",
          "$MAILMANAGER_ADDRESSBOOK_ADD", "src", "$g_graphicslib/mm_aba.jpg");
  htmlAnchorClose();
  htmlAnchor("href", "mm_addressbook.cgi?action=import&$encargs",
             "title", "$MAILMANAGER_ADDRESSBOOK_IMPORT");
  htmlImg("border", "0", "width", "50", "height", "50", "alt",
          "$MAILMANAGER_ADDRESSBOOK_IMPORT", 
          "src", "$g_graphicslib/mm_abi.jpg");
  htmlAnchorClose();
  htmlAnchor("href", "mm_addressbook.cgi?action=purge&absubmit=1&$encargs",
             "title", "$MAILMANAGER_ADDRESSBOOK_PURGE");
  htmlImg("border", "0", "width", "50", "height", "50", "alt",
          "$MAILMANAGER_ADDRESSBOOK_PURGE", 
          "src", "$g_graphicslib/mm_abp.jpg");
  htmlAnchorClose();
  htmlImg("width", "15", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlAnchor("href", "mailmanager.cgi?$encargs",
             "title", "$MAILMANAGER_RETURN");
  htmlImg("border", "0", "width", "50", "height", "50", "alt",
          "$MAILMANAGER_RETURN", "src", "$g_graphicslib/mm_abr.jpg");
  htmlAnchorClose();
  htmlImg("width", "3", "height", "50", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
  htmlBR();

  # summary table
  htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
            "cellpadding", "0");
  htmlTableRow();
  htmlTableData("bgcolor", "#666666", "colspan", "3");
  htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
            "cellpadding", "2", "bgcolor", "#BBBBBB");
  htmlTableRow();
  htmlTableData("align", "left");
  $string = $MAILMANAGER_ADDRESSBOOK_RANGE_SUMMARY;
  $low = ($ncontacts) ? 1 : 0;
  $string =~ s/__LOW__/$low/;
  $string =~ s/__HIGH__/$ncontacts/;
  $string =~ s/__TOTAL__/$ncontacts/;
  htmlTextSmall("&#160;$string");
  htmlTableDataClose();
  #htmlTableData("align", "center");
  #$string = "$MAILMANAGER_ADDRESSBOOK_SIZE_ENTRIES\:&#160;$ncontacts";
  #htmlTextSmall($string);
  #htmlTableDataClose();
  htmlTableData("align", "right");
  $string = "$MAILMANAGER_ADDRESSBOOK_SIZE_BYTES\:&#160;$sizetext&#160;";
  htmlTextSmall($string);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
            "cellpadding", "0");
  htmlTableRow();
  htmlTableData("bgcolor", "#666666", "colspan", "3");
  htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
  htmlBR();

  if ($ncontacts > 0) {
    if ($g_form{'sort_submit'} eq $MAILMANAGER_ADDRESSBOOK_SORT_BY_NAME) {
      $g_form{'sort_by'} = "";
    }
    elsif ($g_form{'sort_submit'} eq $MAILMANAGER_ADDRESSBOOK_SORT_BY_ADDRESS) {
      $g_form{'sort_by'} = "email";
    }
    # the address book contacts
    formOpen("method", "POST", "style", "display:inline;");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
    formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
    formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
    formInput("type", "hidden", "name", "messageid", 
              "value", $g_form{'messageid'});
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "width", "100\%");
    htmlTableRow();
    if ($ncontacts > 1) {
      htmlTableData();
      htmlTextBold("&#160;&#160;#&#160;");
      htmlTableDataClose();
      htmlTableData("align", "center");
      htmlNoBR();
      htmlTextBold("&#160;$MAILMANAGER_ADDRESSBOOK_CONTACT_TAG&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
    }
    htmlTableData();
    htmlNoBR();
    htmlTextBold("&#160;$MAILMANAGER_ADDRESSBOOK_CONTACT_NAME");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData();
    htmlNoBR();
    htmlTextBold($MAILMANAGER_ADDRESSBOOK_CONTACT_EMAIL);
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData();
    htmlNoBR();
    htmlTextBold($MAILMANAGER_ADDRESSBOOK_ACTIONS);
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    $count = 0;
    foreach $contact (sort mailmanagerAddressBookByPreference(keys(%g_addressbook))) {
      if ($g_form{'selected'} =~ /\Q$contact\E/) {
        htmlTableRow("class", "highlighted");
      }
      else {
        htmlTableRow("class", "unhighlighted");
      }
      $count++;
      # tag
      if ($ncontacts > 1) {
        htmlTableData("valign", "top");
        htmlText("&#160;&#160;$count\.&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "top", "align", "center");
        if (($ENV{'HTTP_USER_AGENT'} =~ /MSIE/) && 
            ($ENV{'HTTP_USER_AGENT'} !~ /Opera/)) {
          formInput("type", "checkbox", "name", "selected",
                    "style", "display:inline; margin-top:-2px; margin-bottom:-2px; margin-left:0px; margin-right:0px; padding:0px",
                    "value", $contact, "onClick", "toggle_row(this)",
                    "_OTHER_", ($g_form{'selected'} =~ /\Q$contact\E/) ? "CHECKED" : "");
        }
        else {
          formInput("type", "checkbox", "name", "selected",
                    "value", $contact, "onClick", "toggle_row(this)",
                    "_OTHER_", ($g_form{'selected'} =~ /\Q$contact\E/) ? "CHECKED" : "");
        }
        htmlTableDataClose();
      }
      # name
      htmlTableData("valign", "top");
      htmlNoBR();
      htmlText("&#160;$g_addressbook{$contact}->{'name'}&#160;&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      # email
      htmlTableData("valign", "top");
      htmlFont("class", "text", "face", "arial, helvetica", "size", "2",
               "style", "font-family: arial, helvetica; font-size: 12px");
      $etxt = htmlSanitize($g_addressbook{$contact}->{'email'});
      $etxt = "<nobr>$etxt</nobr>";
      $etxt =~ s/\,(\ )?/\<\/nobr\>\,\ \<nobr\>/g;
      print "$etxt&#160;&#160;";
      htmlFontClose();  
      htmlTableDataClose();
      # actions
      htmlTableData("valign", "top");
      htmlNoBR();
      $string = encodingStringToURL($contact);
      $title = "$MAILMANAGER_ADDRESSBOOK_WRITE_SINGLE: ";
      $title .= "'$g_addressbook{$contact}->{'name'}'";
      htmlAnchor("href", 
                 "$ENV{'SCRIPT_NAME'}?selected=$string&action=write&$encargs",
                 "title", $title);
      htmlAnchorText($MAILMANAGER_ADDRESSBOOK_WRITE);
      htmlAnchorClose();
      htmlText(",&#160;");
      $title = "$MAILMANAGER_ADDRESSBOOK_EDIT_SINGLE: ";
      $title .= "'$g_addressbook{$contact}->{'name'}'";
      htmlAnchor("href", 
                 "$ENV{'SCRIPT_NAME'}?selected=$string&action=edit&$encargs",
                 "title", $title);
      htmlAnchorText($MAILMANAGER_ADDRESSBOOK_EDIT);
      htmlAnchorClose();
      htmlText(",&#160;");
      $title = "$MAILMANAGER_ADDRESSBOOK_REMOVE_SINGLE: ";
      $title .= "'$g_addressbook{$contact}->{'name'}'";
      htmlAnchor("href", 
                 "$ENV{'SCRIPT_NAME'}?selected=$string&action=remove&absubmit=1&$encargs",
                 "title", $title);
      htmlAnchorText($MAILMANAGER_ADDRESSBOOK_REMOVE);
      htmlAnchorClose();
      htmlText("&#160;&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableRowClose();
    }
    htmlTableClose();
    # separator
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "width", "100\%");
    htmlTableRow();
    htmlTableData("bgcolor", "#ffffff", "colspan", "2");
    htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    # separator
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "width", "100\%");
    htmlTableRow();
    htmlTableData("bgcolor", "#999999", "colspan", "2");
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    # submission buttons
    htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    if ($ncontacts > 1) {
      htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
      formInput("type", "submit", "name", "absubmit",
                "value", $MAILMANAGER_ADDRESSBOOK_WRITE_TAGGED);
      formInput("type", "submit", "name", "absubmit",
                "value", $MAILMANAGER_ADDRESSBOOK_EDIT_TAGGED);
      formInput("type", "submit", "name", "absubmit",
                "value", $MAILMANAGER_ADDRESSBOOK_REMOVE_TAGGED);
      print <<ENDTEXT;
&#160;
<script language="JavaScript1.1">
  document.write("<input type=\\\"button\\\" ");
  document.write("style=\\\"font-family:arial, helvetica; font-size:13px\\\" ");
  document.write("value=\\\"$TAG_ALL\\\" onClick=\\\"");
  document.write("this.value=tag_untag_all(this.form.selected)\\\">");
</script>
ENDTEXT
      htmlBR();
      htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
      htmlBR();
      htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
      if ($g_form{'sort_by'}) {
        formInput("type", "submit", "name", "sort_submit",
                  "value", $MAILMANAGER_ADDRESSBOOK_SORT_BY_NAME); 
      }
      if ($g_form{'sort_by'} ne "email") {
        formInput("type", "submit", "name", "sort_submit",
                  "value", $MAILMANAGER_ADDRESSBOOK_SORT_BY_ADDRESS);
      }
    }
    else {
      # just one contact in the address book
      ($contact) = (keys(%g_addressbook))[0];
      formInput("type", "hidden", "name", "selected", "value", $contact);
      formInput("type", "submit", "name", "absubmit",
                "value", $MAILMANAGER_ADDRESSBOOK_WRITE_SINGLE);
      formInput("type", "submit", "name", "absubmit",
                "value", $MAILMANAGER_ADDRESSBOOK_EDIT_SINGLE);
      formInput("type", "submit", "name", "absubmit",
                "value", $MAILMANAGER_ADDRESSBOOK_REMOVE_SINGLE);
    }
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "width", "100\%");
    htmlTableRow();
    htmlTableData("bgcolor", "#ffffff");
    htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData("bgcolor", "#000000");
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    formClose();
  }
  else {
    # specified mailbox is empty
    htmlTable("width", "550");
    htmlTableRow();
    htmlTableData();
    htmlText($MAILMANAGER_ADDRESSBOOK_EMPTY);
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlP();
  }

  # print out the address book summary and available actions
  htmlTable("border", "0");
  htmlTableRow();
  htmlTableData();
  htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableData("valign", "top", "colspan", "2");
  htmlNoBR();
  htmlTextBold("$MAILMANAGER_ADDRESSBOOK_TITLE");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("valign", "top", "rowspan", "3");
  $string = "&#160; " x 10;
  htmlNoBR();
  htmlText($string);
  htmlTextBold("$MAILMANAGER_ADDRESSBOOK_ACTIONS\:&#160;&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("valign", "top", "rowspan", "3");
  htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?action=add&$encargs",
             "title", "$MAILMANAGER_ADDRESSBOOK_ADD");
  htmlAnchorText($MAILMANAGER_ADDRESSBOOK_ADD);
  htmlAnchorClose();
  htmlBR();
  htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?action=import&$encargs",
             "title", "$MAILMANAGER_ADDRESSBOOK_IMPORT");
  htmlAnchorText($MAILMANAGER_ADDRESSBOOK_IMPORT);
  htmlAnchorClose();
  htmlBR();
  if ($ncontacts > 0) {
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?action=purge&absubmit=1&$encargs",
               "title", "$MAILMANAGER_ADDRESSBOOK_PURGE");
    htmlAnchorText($MAILMANAGER_ADDRESSBOOK_PURGE);
    htmlAnchorClose();
    htmlBR();
  }
  htmlAnchor("href", "mailmanager.cgi?$encargs",
               "title", "$MAILMANAGER_RETURN");
  htmlAnchorText($MAILMANAGER_RETURN);
  htmlAnchorClose();
  htmlBR();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableData("valign", "top");
  htmlTextBold("&#160;&#160;$MAILMANAGER_ADDRESSBOOK_SIZE_ENTRIES\:&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "top");
  htmlText($ncontacts);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableData("valign", "top");
  htmlTextBold("&#160;&#160;$MAILMANAGER_ADDRESSBOOK_SIZE_BYTES\:&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "top");
  htmlText($sizetext);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();

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

sub mailmanagerAddressBookEditContactForm
{
  local($mesg, %errors) = @_;
  local($title, $subtitle, $idx, @selected, $contact, $key, $value);
  local($bgcolor, $size25, $size45, $rows, $count, $colspan, $acount);

  # set up the selected list for adding new contacts (if applicable)
  if (($g_form{'action'} eq "add") && ($g_form{'raw_abc'})) {
    $g_form{'selected'} = "__NEWABC1";
    $g_form{'raw_abc'} =~ s/\,\,\,/\|/g;
    $acount = $g_form{'raw_abc'} =~ tr/\|/\|/;
    $g_form{'raw_abc'} =~ s/\|/\,/g;
    if ($acount > 0) {
      $g_form{'__NEWABC1_name'} = "";
      $g_form{'__NEWABC1_email'} = $g_form{'raw_abc'};
    }
    else {
      $g_form{'raw_abc'} =~ m{\b([\w.\-\&]+?@[\w.-]+?)(?=[.-]*(?:[^\w.-]|$))};
      $g_form{'__NEWABC1_email'} = $1;
      $g_form{'__NEWABC1_name'} = $g_form{'raw_abc'};
      $g_form{'__NEWABC1_name'} =~ s/$g_form{'__NEWABC1_email'}//;
      $g_form{'__NEWABC1_name'} =~ s/[\<\>\(\)\[\]\"\']//g;
      $g_form{'__NEWABC1_name'} =~ s/^\s+//g;
      $g_form{'__NEWABC1_name'} =~ s/\s+$//g;
      $g_form{'__NEWABC1_name'} =~ s/\s+/\ /g;
    }
  }
  elsif (($g_form{'action'} eq "add") && (!$g_form{'selected'})) {
    for ($idx=1; $idx<=$g_prefs{'mail__address_book_elements'}; $idx++) {
      $g_form{'selected'} .= "__NEWABC$idx\|\|\|";
    }
    $g_form{'selected'} =~ s/\|+$//g;
  }

  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_ADDRESSBOOK_TITLE : ";
  if ($g_form{'action'} eq "add") {
    $subtitle = $MAILMANAGER_ADDRESSBOOK_ADD;
  }
  elsif ($g_form{'action'} eq "edit") {
    $subtitle = $MAILMANAGER_ADDRESSBOOK_EDIT_TITLE;
  }
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader("$title $subtitle");
  if ($mesg) {
    htmlTextColorBold(">>> $mesg <<<", "#cc0000");
    htmlP();
  }

  #
  # add/edit contact table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_ADDRESSBOOK_TITLE : $subtitle");
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

  if ($g_form{'action'} eq "add") {
    htmlText($MAILMANAGER_ADDRESSBOOK_ADD_HELP_TEXT);
  }
  elsif ($g_form{'action'} eq "edit") {
    htmlText($MAILMANAGER_ADDRESSBOOK_EDIT_HELP_TEXT);
  }
  htmlP();

  $size25 = formInputSize(25);
  $size45 = formInputSize(40);

  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "action", "value", $g_form{'action'});
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "messageid", 
            "value", $g_form{'messageid'});
  formInput("type", "hidden", "name", "selected", "value", $g_form{'selected'});
  @selected = split(/\|\|\|/, $g_form{'selected'});
  htmlTable("cellpadding", "0", "cellspacing", "0", "border", "0");
  htmlTableRow();
  if ($#selected > 0) {
    htmlTableData("align", "center");
    htmlTextBold("#");
    htmlTableDataClose();
  }
  htmlTableData();
  htmlNoBR();
  htmlTextBold("&#160;$MAILMANAGER_ADDRESSBOOK_CONTACT_NAME&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData();
  htmlNoBR();
  htmlTextBold("&#160;$MAILMANAGER_ADDRESSBOOK_CONTACT_EMAIL&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableRowClose();
  $count = 0;
  $colspan = ((keys(%errors)) && ($#selected > 0)) ? 3 : 2;
  foreach $contact (sort mailmanagerAddressBookBySelection(@selected)) {
    $count++;
    $bgcolor = (defined($errors{$contact})) ? "eeeeee" : "white";
    if (defined($errors{$contact})) {
      htmlTableRow();
      htmlTableData("valign", "middle", "bgcolor", "white", 
                    "colspan", $colspan);
      htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "bgcolor", $bgcolor, 
                    "colspan", $colspan);
      htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
      htmlTableDataClose();
      htmlTableRowClose();
    }
    htmlTableRow();
    if ($#selected > 0) {
      htmlTableData("valign", "top", "align", "left", "bgcolor", $bgcolor);
      htmlTable("cellpadding", "3", "cellspacing", "0", "border", "0", 
                "bgcolor", $bgcolor);
      htmlTableRow();
      htmlTableData("bgcolor", $bgcolor);
      htmlText("$count\.");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlTableDataClose();
    }
    htmlTableData("valign", "top", "bgcolor", $bgcolor);
    htmlNoBR();
    htmlText("&#160;");
    $key = $contact . "_name";
    $value = $g_form{$key} || $g_addressbook{$contact}->{'name'};
    formInput("name", $key, "size", $size25, "value", $value);
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("valign", "top", "bgcolor", $bgcolor);
    htmlText("&#160;");
    $key = $contact . "_email";
    $value = $g_form{$key} || $g_addressbook{$contact}->{'email'};
    if ($value && (length($value) > 40)) {
      $rows = $value =~ tr/\,/\,/ + 1;
      $value =~ s/\,(\s+)?/\,\ \n/g;
      formTextArea($value, "name", $key, "rows", $rows,
                   "cols", 45, "wrap", "physical");
    }
    else {
      formInput("name", $key, "size", $size45, "value", $value);
    }
    htmlTableDataClose();
    htmlTableRowClose();
    if (defined($errors{$contact})) {
      htmlTableRow();
      htmlTableData("align", "center", "valign", "middle", 
                    "bgcolor", $bgcolor, "colspan", $colspan);
      htmlTextColorBold(">>> $errors{$contact} <<<", "#cc0000");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "bgcolor", $bgcolor, 
                    "colspan", $colspan);
      htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "bgcolor", "#ffffff", 
                    "colspan", $colspan);
      htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
      htmlTableDataClose();
      htmlTableRowClose();
    }
  } 
  htmlTableRow();
  htmlTableData("valign", "middle", "bgcolor", "#ffffff", "colspan", "2");
  htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlText("&#160;");
  formInput("type", "submit", "name", "absubmit", "value", $SUBMIT_STRING);
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "absubmit", "value", $CANCEL_STRING);
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

sub mailmanagerAddressBookHandleRequest
{
  local($string, $sessionid, $tmpfilename, @pids);

  encodingIncludeStringLibrary("mailmanager");

  # load up the address book contacts
  mailmanagerAddressBookRead();

  # check for cancelled actions first
  if ($g_form{'absubmit'} && ($g_form{'absubmit'} eq "$CANCEL_STRING")) {
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
        $tmpfilename = $g_tmpdir . "/.upload-" . $sessionid . "-fileupload1";
        unlink($tmpfilename);
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
          $tmpfilename = $g_maintmpdir . "/.upload-" . $sessionid . "-fileupload1";
          unlink($tmpfilename);
        }
      }
    }
    # cleaning done... redirect
    if ($g_form{'action'} eq "add") {
      $string = $MAILMANAGER_ADDRESSBOOK_ADD_CANCEL;
    }
    elsif ($g_form{'action'} eq "edit") {
      $string = $MAILMANAGER_ADDRESSBOOK_EDIT_CANCEL;
    }
    elsif ($g_form{'action'} eq "import") {
      $string = $MAILMANAGER_ADDRESSBOOK_IMPORT_CANCEL;
    }
    elsif ($g_form{'action'} eq "purge") {
      $string = $MAILMANAGER_ADDRESSBOOK_PURGE_CANCEL;
    }
    elsif ($g_form{'action'} eq "remove") {
      $string = $MAILMANAGER_ADDRESSBOOK_REMOVE_CANCEL;
    }
    if ($g_form{'messageid'}) {
      redirectLocation("mailmanager.cgi", $string);
    }
    else {
      redirectLocation("mm_addressbook.cgi", $string);
    }
  }

  # if no actions to process... print out contents of the address book or
  # print out an appropriate form based on a selection
  if (!$g_form{'action'}) {
    if ((!$g_form{'absubmit'}) || $g_form{'sort_submit'}) {
      # dump the contents of the saved address book
      mailmanagerAddressBookDisplay();
    }
    elsif (($g_form{'absubmit'} eq "$MAILMANAGER_ADDRESSBOOK_WRITE_SINGLE") ||
           ($g_form{'absubmit'} eq "$MAILMANAGER_ADDRESSBOOK_WRITE_TAGGED")) {
      # write tagged contacts or write single contact button selected
      if ($g_form{'selected'}) {
        mailmanagerAddressBookWriteToSelected();
      }
      else {
        mailmanagerAddressBookDisplay($MAILMANAGER_ADDRESSBOOK_NONE_SELECTED);
      }
    }
    elsif (($g_form{'absubmit'} eq "$MAILMANAGER_ADDRESSBOOK_EDIT_SINGLE") ||
           ($g_form{'absubmit'} eq "$MAILMANAGER_ADDRESSBOOK_EDIT_TAGGED")) {
      # edit tagged contacts or edit single contact button selected
      if ($g_form{'selected'}) {
        $g_form{'action'} = "edit";
        mailmanagerAddressBookEditContactForm();
      }
      else {
        mailmanagerAddressBookDisplay($MAILMANAGER_ADDRESSBOOK_NONE_SELECTED);
      }
    }
    elsif (($g_form{'absubmit'} eq "$MAILMANAGER_ADDRESSBOOK_REMOVE_SINGLE") ||
           ($g_form{'absubmit'} eq "$MAILMANAGER_ADDRESSBOOK_REMOVE_TAGGED")) {
      # remove tagged contacts or remove single contact button selected
      if ($g_form{'selected'}) {
        $g_form{'action'} = "remove";
        # the confirmation and/or execution will be processed below
      }
      else {
        mailmanagerAddressBookDisplay($MAILMANAGER_ADDRESSBOOK_NONE_SELECTED);
      }
    }
  }

  # check data submitted with request
  mailmanagerAddressBookCheckRequest();

  $g_form{'confirm'} = "no" unless($g_form{'confirm'});

  if ($g_form{'absubmit'}) {
    # get confirmation for request
    mailmanagerAddressBookConfirmRequest();
  }

  # if a confirmed actions exists, then process it
  if ($g_form{'confirm'} eq "yes") {
    if ($g_form{'action'} eq "add") {
      mailmanagerAddressBookSaveChanges();
      $string = $MAILMANAGER_ADDRESSBOOK_ADD_SUCCESS;
    }
    elsif ($g_form{'action'} eq "edit") {
      mailmanagerAddressBookSaveChanges();
      $string = $MAILMANAGER_ADDRESSBOOK_EDIT_SUCCESS;
    }
    elsif ($g_form{'action'} eq "import") {
      mailmanagerAddressBookSaveChanges();
      $string = $MAILMANAGER_ADDRESSBOOK_IMPORT_SUCCESS;
    }
    elsif ($g_form{'action'} eq "purge") {
      mailmanagerAddressBookPurge();
      $string = $MAILMANAGER_ADDRESSBOOK_PURGE_SUCCESS;
    }
    elsif ($g_form{'action'} eq "remove") {
      mailmanagerAddressBookSaveChanges();
      $string = $MAILMANAGER_ADDRESSBOOK_REMOVE_SUCCESS;
    }
    if ($g_form{'messageid'}) {
      redirectLocation("mailmanager.cgi", $string);
    }
    else {
      redirectLocation("mm_addressbook.cgi", $string);
    }
  }
  else {
    # an action has been requested; print out an appropriate input form
    if ($g_form{'action'} eq "add") {
      mailmanagerAddressBookEditContactForm();
    }
    elsif ($g_form{'action'} eq "edit") {
      mailmanagerAddressBookEditContactForm();
    }
    elsif ($g_form{'action'} eq "import") {
      if ($g_form{'parse'}) {
        mailmanagerAddressBookImportParseFile();
      }
      else {
        mailmanagerAddressBookImportSelectFile();
      }
    }
    elsif ($g_form{'action'} eq "remove") {
      # no user input required ... action is simply confirmed and executed
    }
    elsif ($g_form{'action'} eq "purge") {
      # no user input required ... action is simply confirmed and executed
    }
    elsif ($g_form{'action'} eq "write") {
      mailmanagerAddressBookWriteToSelected();
    }
    elsif ($g_form{'action'} eq "select") {
      # selecting a "to" address from the compose message form
      mailmanagerAddressBookSelect();
    }
  }
}

##############################################################################

sub mailmanagerAddressBookImportParseFile
{
  local(@filenames, $filename, $errmsg, $count, $size25, $size40);
  local(@df, %abic, $key, $index, $title, $selected, $ampcount);
  local($languagepref, $sessionid);

  $languagepref = encodingGetLanguagePreference();

  # determine filenames of interest
  if ($g_form{'fileupload1'}->{'content-filename'}) {
    push(@filenames, $g_form{'fileupload1'}->{'content-filename'}); 
  }
  if ($g_form{'filelocal1'}) {
    $filename = "$g_users{$g_auth{'login'}}->{'path'}/$g_form{'filelocal1'}";
    $filename =~ s/\/+/\//g;
    push(@filenames, $filename);
  }
  if ($#filenames == -1) {
    $errmsg = $MAILMANAGER_ADDRESSBOOK_IMPORT_NO_FILENAME;
    mailmanagerAddressBookImportSelectFile($errmsg);
  }

  # parse the files
  $count = 0;
  foreach $filename (@filenames) {
    open(FP, "$filename");
    while (<FP>) {
      chomp;
      # only parse lines that appear to have an e-mail address in them
      if (/\b([\w.\-\&]+?@[\w.-]+?)(?=[.-]*(?:[^\w.-]|$))/) {
        if (/\"/) {
          # quoted fields; include space as delimiter
          @df = mailmanagerParseString('\t|,|:|;|\ |\|', 0, $_);
        }
        else {
          # non-quoted fields
          @df = mailmanagerParseString('\t|,|:|;|\|', 0, $_);
        }
        next if ($#df == -1);
        $count++;
        $key = "__NEWABC" . $count;
        # first try and match against entries where the e-mail address and 
        # name are embedded together, i.e. "name <email>"
        for ($index=0; $index<=$#df; $index++) {
          if ($df[$index] =~ /(.*)\s+[\(|\<]([\w.\-\&]+?@[\w.-]+?)[\)|\>]/) {
            $abic{$key}->{'name'} = $1;
            $abic{$key}->{'email'} = $2;
            last;
          }
          elsif ($df[$index] =~ /([\w.\-\&]+?@[\w.-]+?)\s+[\(|\<](.*)[\)|\>]/) {
            $abic{$key}->{'email'} = $1;
            $abic{$key}->{'name'} = $2;
            last;
          }
        }
        # if no embedded name/e-mail field found, then just look for an e-mail
        # address separately and hope for the best with the name
        unless ($abic{$key}->{'email'}) {
          for ($index=0; $index<=$#df; $index++) {
            if ($df[$index] =~ /\b([\w.\-\&]+?@[\w.-]+?)(?=[.-]*(?:[^\w.-]|$))/) {
              if ($abic{$key}->{'email'}) {
                $abic{$key}->{'email'} .= ", $df[$index]";
              }
              else {
                $abic{$key}->{'email'} = $df[$index];
              }
            }
          }
          # look in the first 5 fields or so to construct the name
          for ($index=0; $index<=4; $index++) {
            next unless ($df[$index]);
            next if ($df[$index] =~ /\b([\w.\-\&]+?@[\w.-]+?)(?=[.-]*(?:[^\w.-]|$))/);
            $abic{$key}->{'name'} .= "$df[$index] ";
            last if ($df[$index] =~ /\s/);
          }
        }
        # scrub up the data
        $abic{$key}->{'name'} =~ s/^\s+//;
        $abic{$key}->{'name'} =~ s/\s+$//;
        if ($languagepref eq "ja") {
          $abic{$key}->{'name'} = jcode'euc($abic{$key}->{'name'});
        }
        $abic{$key}->{'email'} =~ s/^\s+//;
        $abic{$key}->{'email'} =~ s/\s+$//;
        $ampcount = $abic{$key}->{'email'} =~ tr/\@/\@/;
        if ($ampcount > 1) {
          # filename will be "P_NAME" (P for "plural list")
          $abic{$key}->{'name'} = 
             mailmanagerAddressBookSanitizePath($abic{$key}->{'name'});
          $abic{$key}->{'value'} =~ s/\,(\s+)?/\,\ /g;
        }
        elsif ($ampcount == 1) {
          # filename will be "A_ADDRESS" (A for "address")
          $abic{$key}->{'email'} = 
             mailmanagerAddressBookSanitizePath($abic{$key}->{'email'});
        }
        else {
          delete($abic{$key});
        }
      }
    }
    close(FP);
  }

  # do some housekeeping
  if ($g_form{'fileupload1'}->{'content-filename'}) {
    unlink($g_form{'fileupload1'}->{'content-filename'});
  }
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

  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_ADDRESSBOOK_TITLE : ";
  $title .= $MAILMANAGER_ADDRESSBOOK_IMPORT;
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);

  #
  # parse import file results table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_ADDRESSBOOK_TITLE : $MAILMANAGER_ADDRESSBOOK_IMPORT");
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

  # was anything found?
  if ($count == 0) {
    # nothing was found... bummer
    htmlText($MAILMANAGER_ADDRESSBOOK_IMPORT_PARSE_FAILURE);
    htmlP();
    formOpen("method", "POST");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "action", "value", $g_form{'action'});
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
    formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
    formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
    formInput("type", "hidden", "name", "messageid", 
              "value", $g_form{'messageid'});
    formInput("type", "submit", "name", "absubmit", 
              "value", $MAILMANAGER_ADDRESSBOOK_IMPORT);
    formInput("type", "submit", "name", "absubmit", "value", $CANCEL_STRING);
    formClose();
  }
  else {
    $size25 = formInputSize(25);
    $size40 = formInputSize(40);
    htmlText($MAILMANAGER_ADDRESSBOOK_IMPORT_PARSE_SUCCESS);
    htmlP();
    formOpen("method", "POST");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "action", "value", $g_form{'action'});
    formInput("type", "hidden", "name", "confirm", "value", "yes");
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
    formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
    formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
    formInput("type", "hidden", "name", "messageid", 
              "value", $g_form{'messageid'});
    htmlTable();
    htmlTableRow();
    htmlTableData("valign", "top");
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    htmlTableData();
    htmlNoBR();
    htmlTextBold($MAILMANAGER_ADDRESSBOOK_CONTACT_NAME);
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("valign", "top");
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    htmlTableData();
    htmlNoBR();
    htmlTextBold($MAILMANAGER_ADDRESSBOOK_CONTACT_EMAIL);
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    foreach $key (sort {$abic{$a}->{'name'} cmp $abic{$b}->{'name'}}
                  keys(%abic)) {
      $selected .= "$key|||";
      htmlTableRow();
      htmlTableData("valign", "top");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "top");
      htmlNoBR();
      formInput("size", $size25, "name", "$key\_name", "value", 
                $abic{$key}->{'name'});
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableData("valign", "top");
      htmlText("&#160;=>&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "top");
      formInput("size", $size40, "name", "$key\_email", "value", 
                $abic{$key}->{'email'});
      htmlTableDataClose();
      htmlTableRowClose();
    }
    htmlTableClose();
    htmlBR();
    $selected =~ s/\|+$//;
    formInput("type", "hidden", "name", "selected", "value", $selected);
    formInput("type", "submit", "name", "absubmit", 
              "value", $MAILMANAGER_ADDRESSBOOK_IMPORT_PARSE_INSERT);
    formInput("type", "submit", "name", "absubmit", "value", $CANCEL_STRING);
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

sub mailmanagerAddressBookImportSelectFile
{
  local($mesg) = @_;
  local($title, $size);

  initUploadCookieSetSessionID();
  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_ADDRESSBOOK_TITLE : ";
  $title .= $MAILMANAGER_ADDRESSBOOK_IMPORT;
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  if ($mesg) {
    htmlTextColorBold(">>> $mesg <<<", "#cc0000");
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
  htmlTextBold("&#160;$MAILMANAGER_ADDRESSBOOK_TITLE : $MAILMANAGER_ADDRESSBOOK_IMPORT");
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

  htmlText($MAILMANAGER_ADDRESSBOOK_IMPORT_HELP_TEXT);
  htmlP();
  if ($g_users{$g_auth{'login'}}->{'ftp'}) {
    htmlText($MAILMANAGER_ADDRESSBOOK_IMPORT_HELP_TEXT_2);
    htmlP();
  }

  $size = formInputSize(40);

  formOpen("method", "POST", "enctype", "multipart/form-data", 
           "name", "formfields");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "action", "value", $g_form{'action'});
  formInput("type", "hidden", "name", "parse", "value", "1");
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "messageid", 
            "value", $g_form{'messageid'});
  htmlTable("border", "0");
  htmlTableRow();
  htmlTableData("valign", "top");
  htmlImg("width", "15", "height", "3", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  htmlTableDataClose();
  htmlTableData("valign", "top");
  htmlTextBold($MAILMANAGER_ADDRESSBOOK_IMPORT_UPLOAD_FILE);
  htmlBR();
  formInput("type", "file", "name", "fileupload1", "size", $size);
  htmlTableDataClose();
  htmlTableRowClose();
  if ($g_users{$g_auth{'login'}}->{'ftp'}) {
    htmlTableRow();
    htmlTableData("valign", "top");
    htmlImg("width", "15", "height", "5", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlTableDataClose();
    htmlTableData("valign", "top");
    htmlImg("width", "15", "height", "5", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlTextBold($MAILMANAGER_ADDRESSBOOK_IMPORT_LOCAL_FILE);
    htmlBR();
    htmlTable("cellpadding", "0", "cellspacing", "0", "border", "0");
    htmlTableRow();
    htmlTableData("valign", "middle");
    formInput("name", "filelocal1", "size", $size, "value", "");
    htmlTableDataClose();
    htmlTableData();
    htmlText("&#160");
    htmlTableDataClose();
    $title = $MAILMANAGER_ADDRESSBOOK_IMPORT_BROWSE_HELP;
    $title =~ s/\s+/\ /g;
    print <<ENDTEXT;
<script language="JavaScript1.1">
<!--
  function importSelect()
  {
    var path = document.formfields.filelocal1.value;
    var url = "mm_select.cgi?abi=1&localattach=1&destfile=" + path;
    var options = \"width=575,height=375,\";
    options += \"resizable=yes,scrollbars=yes,status=yes,\";
    options += \"menubar=no,toolbar=no,location=no,directories=no\";
    var selectWin = window.open(url, 'selectWin', options);
    selectWin.opener = self;
    selectWin.focus();
  }
  document.write("<td valign=\\\"middle\\\">");
  document.write("<font face=\\\"arial, helvetica\\\" size=\\\"2\\\">");
  document.write("[&#160;");
  document.write("<a onClick=\\\"importSelect(); return false\\\" ");
  document.write("onMouseOver=\\\"window.status='$MAILMANAGER_ADDRESSBOOK_IMPORT_LOCAL_FILE'; return true\\\" ");
  document.write("onMouseOut=\\\"window.status=''; return true\\\" ");
  document.write("title=\\\"$title\\\" ");
  document.write("href=\\\"mm_select.cgi?localattach=1\\\">");
  document.write("$MAILMANAGER_ADDRESSBOOK_IMPORT_BROWSE");
  document.write("</a>");
  document.write("&#160;]");
  document.write("</font>");
  document.write("</td>");
//-->
</script>
ENDTEXT
    htmlTableRowClose();
    htmlTableClose();
    htmlTableDataClose();
    htmlTableRowClose();
  }
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;");
  htmlTableDataClose();
  htmlTableData();
  htmlTable("border", "0", "cellpadding", "0", "cellspacing", "0");
  htmlTableRow();
  htmlTableData("valign", "top");
  htmlImg("width", "15", "height", "5", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  formInput("type", "submit", "name", "absubmit", "value", $SUBMIT_STRING);
  formInput("type", "reset", "value", $RESET_STRING);
  formClose();
  htmlTableDataClose();
  htmlTableData("valign", "top");
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "action", "value", $g_form{'action'});
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "messageid", 
            "value", $g_form{'messageid'});
  htmlImg("width", "15", "height", "5", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  htmlText("&#160;");
  formInput("type", "submit", "name", "absubmit", "value", $CANCEL_STRING);
  formClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
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

sub mailmanagerAddressBookPurge
{
  local($abdir, $fullpath, $filename);

  $abdir = mailmanagerGetDirectoryPath("addressbook");
  opendir(ABD, "$abdir");
  foreach $filename (readdir(ABD)) {
    $fullpath = "$abdir/$filename";
    next if (-d "$fullpath");
    if (($filename =~ /^A_/) || ($filename =~ /^P_/)) {
      unlink($fullpath);
    }
    else {
      # ignore
    }
  }
  closedir(ABD);
}

##############################################################################

sub mailmanagerAddressBookRead
{
  local($abdir, $fullpath, $filename, $fsize, $contactname, $emailaddress);

  %g_addressbook = ();
  $g_addressbook{'__size__'} = 0;
  $abdir = mailmanagerGetDirectoryPath("addressbook");
  opendir(ABD, "$abdir");
  foreach $filename (readdir(ABD)) {
    $fullpath = "$abdir/$filename";
    next if (-d "$fullpath");
    # there are two types of address book files.  the first type is for a 
    # single address mapped to name (or a 'simple' entry), the second type
    # is for a single name mapped to multiple e-mail addresses (or a 'plural'
    # entry).  why did I do this?  well, I wanted to be able to quickly tell
    # if an e-mail address already exists in the address book... so for 
    # 'simple' address book entries, I can just do an if (-e) check and bang
    # it's nice and simple.  if ! (-e) then print out an icon to allow the
    # user to add the address to the address book.  
    ($fsize) = (stat($fullpath))[7];
    $contactname = $emailaddress = "";
    if ($filename =~ /^A_/) {
      # simple address to name map
      $emailaddress = $filename;
      $emailaddress =~ s/^A_//;
      open(FP, "$fullpath");
      $contactname = <FP>;
      close(FP);
      chomp($contactname);
      $g_addressbook{$filename}->{'name'} = $contactname;
      $g_addressbook{$filename}->{'email'} = $emailaddress;
      $g_addressbook{'__size__'} += $fsize;
    }
    elsif ($filename =~ /^P_/) {
      # plural address to name map
      $contactname = $filename;
      $contactname =~ s/^P_//;
      open(FP, "$fullpath");
      $emailaddress = <FP>;
      close(FP);
      chomp($emailaddress);
      $g_addressbook{$filename}->{'name'} = $contactname;
      $g_addressbook{$filename}->{'email'} = $emailaddress;
      $g_addressbook{'__size__'} += $fsize;
    }
    else {
      # ignore everything else
    }
  }
  closedir(ABD);
}

##############################################################################

sub mailmanagerAddressBookSanitizePath
{
  local($filename) = @_;

  # scrub up an e-mail address or a e-mail alias (name) to make it nice 
  # and happy to use as a filename... there are several guidelines we
  # could consider.  for example, the POSIX recommendation to only use a 
  # limited set of characters -- letters, numbers, period, hyphen, and 
  # underscore.  however, some of our filenames will have special chars
  # (like Japanese chars) so we will use a defintion as broad as can be
  # expected without expecting any trouble.
  #
  # so, '/' is out, and ':' is out, and (NULL) is out.  
  # 
  # everything else is probably ok... I guess. 

  $filename =~ s/\%00//g;
  $filename =~ s/\://g;
  $filename =~ s#/##g;

  return($filename);
}

##############################################################################

sub mailmanagerAddressBookSaveChanges
{
  local(@selected, $contact, $nkey, $ekey, $ampcount);
  local($abdir, $filename, $content);

  $abdir = mailmanagerGetDirectoryPath("addressbook");
  @selected = split(/\|\|\|/, $g_form{'selected'});
  foreach $contact (@selected) {
    $nkey = $contact . "_name";
    $ekey = $contact . "_email";
    unless ($contact =~ /^__NEWABC/) {
      # editing/removing contact currently defined in address book
      $ampcount = $g_addressbook{$contact}->{'email'} =~ tr/\@/\@/;
      if ($ampcount > 1) {
        $filename = "P_" . $g_addressbook{$contact}->{'name'};
      }
      else {
        $filename = "A_" . $g_addressbook{$contact}->{'email'};
      }
      # unlink old contact
      unlink("$abdir/$filename");
    }
    if (($contact =~ /^__NEWABC/) || ($g_form{$nkey} && $g_form{$ekey})) {
      # adding new contact or saving edited contact to address book
      $ampcount = $g_form{$ekey} =~ tr/\@/\@/;
      if ($ampcount > 1) {
        $filename = "P_" . $g_form{$nkey};
        $content = $g_form{$ekey};
      }
      else {
        $filename = "A_" . $g_form{$ekey};
        $content = $g_form{$nkey};
      }
      next unless (open(FP, ">$abdir/$filename"));
      print FP "$content";
      close(FP);
    }
  }
}

##############################################################################

sub mailmanagerAddressBookSelect
{
  local($title, $value);

  encodingIncludeStringLibrary("mailmanager");

  $title = $MAILMANAGER_ADDRESSBOOK_SELECT_ADD_TITLE;
  $title =~ s/\s+/ /g;
  if ($g_form{'field'} eq "send_to") {
    $title =~ s/__FIELD__/$MAILMANAGER_MESSAGE_TO/;
  }
  elsif ($g_form{'field'} eq "send_cc") {
    $title =~ s/__FIELD__/$MAILMANAGER_MESSAGE_CC/;
  }
  else {
    $title =~ s/__FIELD__/$MAILMANAGER_MESSAGE_BCC/;
  }
  htmlResponseHeader("Content-type: $g_default_content_type");
  htmlHtml();
  htmlHead();
  htmlTitle($title);

  print <<ENDTEXT;
<script language="JavaScript1.1">
<!--
  function isblank(s)
  {
    for (var i=0; i<s.length; i++) {
      var c=s.charAt(i);
      if ((c != ' ') && (c != '\\n') && (c != '\\t')) return false;
    }
    return true;
  }

  function updateParent(ev)
  {
    if (isblank(window.opener.document.formfields.$g_form{'field'}.value)) {
      window.opener.document.formfields.$g_form{'field'}.value = ev;
    }
    else {
      window.opener.document.formfields.$g_form{'field'}.value += ", ";
      window.opener.document.formfields.$g_form{'field'}.value += ev;
    }
  }

  function clearParent()
  {
    window.opener.document.formfields.$g_form{'field'}.value = "";
  }
//-->
</script>
ENDTEXT

  htmlHeadClose();
  htmlBody("bgcolor", "#ffffff");

  delete($g_addressbook{'__size__'});  # don't need this here
  $ncontacts = keys(%g_addressbook);
  if ($ncontacts > 0) {
    htmlText($title);
    formOpen("name", "selectForm", "method", "POST", "action", "donothing.cgi");
    # the address book contacts
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "width", "100\%");
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;");
    htmlTableDataClose();
    htmlTableData();
    htmlNoBR();
    htmlTextBold("&#160;$MAILMANAGER_ADDRESSBOOK_CONTACT_NAME&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData();
    htmlTextBold($MAILMANAGER_ADDRESSBOOK_CONTACT_EMAIL);
    htmlTableDataClose();
    htmlTableRowClose();
    foreach $contact (sort mailmanagerAddressBookByPreference(keys(%g_addressbook))) {
      htmlTableRow();
      # add button
      htmlTableData("valign", "top");
      htmlNoBR();
      $ampcount = $g_addressbook{$contact}->{'email'} =~ tr/\@/\@/;
      if ($ampcount == 1) {
        $value = "&quot;$g_addressbook{$contact}->{'name'}&quot; ";
        $value .= "<$g_addressbook{$contact}->{'email'}>";
        $value =~ s/\"/\&quot\;/g;
        formInput("type", "submit", "name", "submit", "style", 
          "display:inline; font-size:9px; font-family: Arial, Helvetica",
          "value", $MAILMANAGER_ADDRESSBOOK_SELECT_ADD, "onClick", 
          "updateParent('$value'); return false");
      }
      else {
        $value = $g_addressbook{$contact}->{'email'};
        $value =~ s/\"/\&quot\;/g;
        formInput("type", "submit", "name", "submit", "style", 
          "display:inline; font-size:9px; font-family: Arial, Helvetica",
          "value", $MAILMANAGER_ADDRESSBOOK_SELECT_ADD, "onClick", 
          "updateParent('$value'); return false");
      }
      htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
      htmlNoBRClose();
      htmlTableDataClose();
      # name
      htmlTableData("valign", "top");
      htmlNoBR();
      htmlText("&#160;$g_addressbook{$contact}->{'name'}&#160;&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      # email
      htmlTableData("valign", "top");
      htmlFont("class", "text", "face", "arial, helvetica", "size", "2",
               "style", "font-family:arial, helvetica; font-size:12px");
      $etxt = htmlSanitize($g_addressbook{$contact}->{'email'});
      $etxt = "<nobr>$etxt</nobr>";
      $etxt =~ s/\,(\ )?/\<\/nobr\>\,\ \<nobr\>/g;
      print "$etxt&#160;&#160;";
      htmlFontClose();  
      htmlTableDataClose();
      htmlTableRowClose();
    }
    htmlTableClose();
    htmlP();
    # separator
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "width", "100\%");
    htmlTableRow();
    htmlTableData("bgcolor", "#666666", "colspan", "2");
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlTable("cellpadding", "0", "cellspacing", "0", "border", "0");
    htmlTableRow();
    # clear button
    htmlTableData("valign", "top");
    htmlNoBR();
    formInput("type", "submit", "name", "submit", "style", 
      "display:inline; font-size:9px; font-family: Arial, Helvetica",
      "value", $MAILMANAGER_ADDRESSBOOK_SELECT_CLEAR, 
      "onClick", "clearParent(); return false");
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    $title = $MAILMANAGER_ADDRESSBOOK_SELECT_CLEAR_TITLE;
    if ($g_form{'field'} eq "send_to") {
      $title =~ s/__FIELD__/$MAILMANAGER_MESSAGE_TO/;
    }
    elsif ($g_form{'field'} eq "send_cc") {
      $title =~ s/__FIELD__/$MAILMANAGER_MESSAGE_CC/;
    }
    else {
      $title =~ s/__FIELD__/$MAILMANAGER_MESSAGE_BCC/;
    }
    htmlText("&#160;$title");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    # separator
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "width", "100\%");
    htmlTableRow();
    htmlTableData("bgcolor", "#666666", "colspan", "2");
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlP();
    formInput("type", "submit", "name", "submit", "value", $CLOSE_STRING,
              "onClick", "self.close(); return false");
    formClose();
    htmlP();
  }
  else {
    htmlText($MAILMANAGER_ADDRESSBOOK_EMPTY);
  }

  htmlBodyClose();
  htmlHtmlClose();
}

##############################################################################

sub mailmanagerAddressBookWriteToSelected
{
  local(@selected, $contact, $nkey, $ekey, $abclist, $filename);

  $abclist = "";
  @selected = split(/\|\|\|/, $g_form{'selected'});
  foreach $contact (@selected) {
    $nkey = $contact . "_name";
    $ekey = $contact . "_email";
    if ($contact =~ /^P_/) {
      $abclist .= "$g_addressbook{$contact}->{'email'}, ";
    }
    else {
      if ($g_addressbook{$contact}->{'name'} =~ /[^A-Za-z0-9\ \-]/) {
        $abclist .= "\"";
      }
      $abclist .= "$g_addressbook{$contact}->{'name'}";
      if ($g_addressbook{$contact}->{'name'} =~ /[^A-Za-z0-9\ \-]/) {
        $abclist .= "\"";
      }
      $abclist .= " <$g_addressbook{$contact}->{'email'}>, ";
    }
  }
  chop($abclist);  # trailing space
  chop($abclist);  # trailing comma

  $g_form{'abclistid'} = $g_curtime . "-" . $$;
  $filename = "$g_tmpdir/.abclist-" . $g_form{'abclistid'};
  if (open(MESGFP, ">$filename")) {
    print MESGFP "$abclist";
    close(MESGFP);
  }
  redirectLocation("mm_compose.cgi");
}

##############################################################################
# eof

1;

