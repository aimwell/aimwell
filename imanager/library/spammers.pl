#
# spammers.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/spammers.pl,v 2.12.2.3 2006/04/25 19:48:25 rus Exp $
#
# add/edit/remove/view spammers functions
#

##############################################################################

sub spammersByPreference
{
  if (($a =~ /^__NEWSPAMMER/) || ($b =~ /^__NEWSPAMMER/)) {
    return($a cmp $b);
  }

  if ($g_form{'sort_submit'} &&
      ($g_form{'sort_submit'} eq $SPAMMERS_SORT_BY_ORDER)) {
    return($g_spammers{$a}->{'order'} <=> $g_spammers{$b}->{'order'});
  }
  else {
    # default... by name
    return($a cmp $b);
  }
}

##############################################################################

sub spammersCheckFormValidity
{
  local($type) = @_;
  local($mesg, $spammer, @selectedspammers, $scount, $dkey);
  local($errmsg, %errors, %newspammers);

  encodingIncludeStringLibrary("spammers");

  if (($g_form{'submit'} && ($g_form{'submit'} eq "$CANCEL_STRING")) ||
      ($g_form{'select_submit'} && ($g_form{'select_submit'} eq "$CANCEL_STRING"))) {
    if ($type eq "add") {
      $mesg = $SPAMMERS_CANCEL_ADD_TEXT;
    }
    elsif ($type eq "edit") {
      $mesg = $SPAMMERS_CANCEL_EDIT_TEXT;
    }
    elsif ($type eq "remove") {
      $mesg = $SPAMMERS_CANCEL_REMOVE_TEXT;
    }
    redirectLocation("iroot.cgi", $mesg);
  }

  # perform error checking on form data
  if (($type eq "add") || ($type eq "edit")) {
    $scount = 0;
    %errors = %newspammers = ();
    @selectedspammers = split(/\|\|\|/, $g_form{'spammers'});
    foreach $spammer (@selectedspammers) {
      $dkey = $spammer . "_definition";
      # next if new and left blank
      next if (($spammer =~ /^__NEWSPAMMER/) && (!$g_form{$dkey}));
      # next if no change was made (only applicable for type == edit)
      next if (($type eq "edit") &&
               ($g_form{$dkey} eq $g_spammers{$spammer}->{'definition'}));
      $scount++;
      # definition checks
      if (($type eq "add") && (defined($g_spammers{$g_form{$dkey}}))) {
        # no duplicates allowed
        $errmsg = $SPAMMERS_ERROR_DUPLICATE_ADDITION;
        $errmsg =~ s/__SPAMMER__/$g_form{$dkey}/;
        push(@{$errors{$spammer}}, $errmsg);
      }
      if (defined($newspammers{$g_form{$dkey}})) {
        $errmsg = $SPAMMERS_ERROR_VIRTUAL_FIELD_REPEATED;
        $errmsg =~ s/__SPAMMER__/$g_form{$dkey}/;
        push(@{$errors{$spammer}}, $errmsg);
      }
      $newspammers{$g_form{$dkey}} = "dau!";
      if ($g_form{$dkey} =~ /\@/) {
        # an e-mail address spammer definition
        # maybe insert some checks here later
      }
      else {
        # a hostname spammer definition
        # maybe insert some checks here later
      }
    }
    if (keys(%errors)) {
      spammersDisplayForm($type, %errors);
    }
    if ($scount == 0) {
      # nothing to do!
      spammersNoChangesExist($type);
    }
    # print out a confirm form if necessary
    $g_form{'confirm'} = "no" unless ($g_form{'confirm'});
    if ($g_form{'confirm'} ne "yes") {
      spammersConfirmChanges($type);
    }
  }
}

##############################################################################

sub spammersCommitChanges
{
  local($type) = @_;
  local($spammer, @selectedspammers, @spammerlist, $dkey);
  local($success_mesg, $output);

  @selectedspammers = split(/\|\|\|/, $g_form{'spammers'});
  foreach $spammer (@selectedspammers) {
    if (($type eq "add") || ($type eq "edit")) {
      $dkey = $spammer . "_definition";
      # next if new and left blank
      next if (($spammer =~ /^__NEWSPAMMER/) && (!$g_form{$dkey}));
      # next if no change was made (only applicable for type == edit)
      if (($type eq "edit") &&
          ($g_form{$dkey} eq $g_spammers{$spammer}->{'definition'})) {
        $g_form{'spammers'} =~ s/^\Q$spammer\E$//;
        $g_form{'spammers'} =~ s/^\Q$spammer\E\|\|\|//;
        $g_form{'spammers'} =~ s/\|\|\|\Q$spammer\E\|\|\|/\|\|\|/;
        $g_form{'spammers'} =~ s/\|\|\|\Q$spammer\E$//;
        next;
      }
      if ($g_form{$dkey}) {
        $g_spammers{$spammer}->{'new_definition'} = $g_form{$dkey};
      }
      else {
        # poor man's way of removing a spammer, i.e. editing it and 
        # setting its value to "" ...tag it for removal
        $g_spammers{$spammer}->{'new_definition'} = "__REMOVE";
      }
      push(@spammerlist, $spammer);
    }
    elsif ($type eq "remove") {
      $g_spammers{$spammer}->{'new_definition'} = "__REMOVE";
      push(@spammerlist, $spammer);
    }
  }
  $output = spammersSaveChanges(@spammerlist);
  
  # now redirect back to iroot index and show success message
  if ($type eq "add") {
    $success_mesg = $SPAMMERS_SUCCESS_ADD_TEXT;
  }
  elsif ($type eq "edit") {
    $success_mesg = $SPAMMERS_SUCCESS_EDIT_TEXT;
  }
  elsif ($type eq "remove") {
    $success_mesg = $SPAMMERS_SUCCESS_REMOVE_TEXT;
  }
  $success_mesg .= "\n$output" if ($output);
  redirectLocation("iroot.cgi", $success_mesg);
}

##############################################################################
         
sub spammersConfirmChanges
{
  local($type) = @_;
  local($subtitle, $title);
  local($spammer, @selectedspammers, $dkey);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("spammers");

  if ($type eq "add") {
    $subtitle = "$IROOT_ADD_TEXT: $CONFIRM_STRING";
  }
  elsif ($type eq "edit") {
    $subtitle = "$IROOT_EDIT_TEXT: $CONFIRM_STRING";
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_SPAMMERS_TITLE: $subtitle";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlText($SPAMMERS_CONFIRM_TEXT);
  htmlP();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "type", "value", $type);
  formInput("type", "hidden", "name", "confirm", "value", "yes");
  formInput("type", "hidden", "name", "spammers", 
            "value", $g_form{'spammers'});
  htmlUL();
  @selectedspammers = split(/\|\|\|/, $g_form{'spammers'});
  foreach $spammer (@selectedspammers) {
    $dkey = $spammer . "_definition";
    # next if new and left blank
    next if (($spammer =~ /^__NEWSPAMMER/) && (!$g_form{$dkey}));
    # next if no change was made (only applicable for type == edit)
    next if (($type eq "edit") &&
               ($g_form{$dkey} eq $g_spammers{$spammer}->{'definition'}));
    # print out the hidden field
    formInput("type", "hidden", "name", $dkey, "value", $g_form{$dkey});
    htmlListItem();
    if ($g_form{$dkey}) {
      if ($spammer =~ /^__NEWSPAMMER/) {
        # confirm addition
        htmlTextBold($SPAMMERS_CONFIRM_ADD_NEW);
        htmlBR();
        htmlText("&#160;&#160;&#160;&#160;");
        htmlTextCode($g_form{$dkey});
        htmlBR();
      }
      else {
        # confirm edition
        htmlTextBold($SPAMMERS_CONFIRM_CHANGE_VALUE);
        htmlTable("border", "0", "cellspacing", "0", "cellpadding", "0");
        htmlTableRow();
        htmlTableData();
        htmlNoBR();
        htmlText("&#160;&#160;&#160;&#160;");
        htmlText("$SPAMMERS_CONFIRM_CHANGE_VALUE_OLD:");
        htmlText("&#160;&#160;");
        htmlNoBRClose();
        htmlTableDataClose();
        htmlTableData();
        htmlTextCode($g_spammers{$spammer}->{'definition'});
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData();
        htmlNoBR();
        htmlText("&#160;&#160;&#160;&#160;");
        htmlText("$SPAMMERS_CONFIRM_CHANGE_VALUE_NEW:");
        htmlText("&#160;&#160;");
        htmlNoBRClose();
        htmlTableDataClose();
        htmlTableData();
        htmlTextCode($g_form{$dkey});
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableClose();
        htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
        htmlBR();
      }
    }
    else {
      # poor man's way of removing a spammer, i.e. editing it and 
      # setting its value to "" ...confirm it's removal
      htmlTextBold($SPAMMERS_CONFIRM_REMOVE_OLD);
      htmlBR();
      htmlText("&#160;&#160;&#160;&#160;");
      htmlTextCode($g_spammers{$spammer}->{'definition'});
      htmlBR();
    }
  }
  htmlULClose();
  htmlP();
  formInput("type", "submit", "name", "submit", "value", $CONFIRM_STRING);
  formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  formClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub spammersDisplayForm
{
  local($type, %errors) = @_;
  local($title, $subtitle, $helptext, $buttontext, $mesg, $spamlist);
  local(@selectedspammers, $spammer, $index, $singlespammer);
  local($size30, $key, $value);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("spammers");

  if ($type eq "add") {
    $subtitle = $IROOT_ADD_TEXT;
    if ($g_form{'spammers'}) {
      @selectedspammers = split(/\|\|\|/, $g_form{'spammers'});
    }
    else {
      for ($index=1; $index<=$g_prefs{'iroot__num_newspammers'}; $index++) {
        push(@selectedspammers, "__NEWSPAMMER$index");
        $spamlist .= "__NEWSPAMMER$index\|\|\|";
      }
      $spamlist =~ s/\|+$//g;
      $g_form{'spammers'} = $spamlist;
    }
    $helptext = $SPAMMERS_ADD_HELP_TEXT;
    $buttontext = $SPAMMERS_ADD_SUBMIT_TEXT;
  } 
  elsif ($type eq "edit") {
    $subtitle = $IROOT_EDIT_TEXT;
    @selectedspammers = split(/\|\|\|/, $g_form{'spammers'}) if ($g_form{'spammers'});
    $helptext = $SPAMMERS_EDIT_HELP_TEXT;
    $buttontext = $SPAMMERS_EDIT_SUBMIT_TEXT;
  } 
  elsif ($type eq "remove") {
    $subtitle = $IROOT_REMOVE_TEXT;
    @selectedspammers = split(/\|\|\|/, $g_form{'spammers'}) if ($g_form{'spammers'});
    $helptext = $SPAMMERS_REMOVE_HELP_TEXT;
    $buttontext = $SPAMMERS_REMOVE_SUBMIT_TEXT;
  }
  elsif ($type eq "view") {
    $subtitle = $IROOT_VIEW_TEXT;
    foreach $spammer (keys(%g_spammers)) {
      push(@selectedspammers, $spammer);
    }
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_SPAMMERS_TITLE: $subtitle";

  if ($#selectedspammers == -1) {
    # oops... no spammers in selected spammer list.
    if (($type eq "edit") || ($type eq "remove")) {
      $singlespammer = spammersSelectForm($type);
      @selectedspammers = ("$singlespammer");
    } 
    else {
      spammersEmptyFile();
    }
  }  

  $size30 = formInputSize(30);

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);

  if (keys(%errors)) {
    htmlTextColorBold(">>> $IROOT_ERRORS_FOUND <<<", "#cc0000");
    htmlP();
  }

  # show some help
  if ($type ne "view") {
    htmlText($helptext);
    htmlP();
    if (($type eq "add") || ($type eq "edit")) {
      htmlText($SPAMMERS_OVERVIEW_HELP_TEXT);
      htmlP();
      htmlText($SPAMMERS_EXAMPLES_HELP_TEXT_1);
      htmlP();
      htmlPre();
      htmlFont("class", "fixed", "face", "courier new, courier", "size", "2",
               "style", "font-family:courier new, courier; font-size:12px");
      print "$SPAMMERS_EXAMPLES_HELP_TEXT_2";
      htmlFontClose();
      htmlPreClose();
#      htmlText($SPAMMERS_SOURCES_HELP_TEXT_1);
#      htmlP();
#      htmlPre();
#      htmlFont("class", "fixed", "face", "courier new, courier", "size", "2",
#               "style", "font-family:courier new, courier; font-size:12px");
#      print "$SPAMMERS_SOURCES_HELP_TEXT_2";
#      htmlFontClose();
#      htmlPreClose();
    }
  }
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "view", "value", $type);
  formInput("type", "hidden", "name", "spammers", 
            "value", $g_form{'spammers'});
  htmlTable();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "bottom");
  htmlTextBold($SPAMMERS_VALUE);
  htmlTableDataClose();
  if (($type eq "add") || ($type eq "edit")) {
    # error column
    htmlTableData();
    htmlTableDataClose();
  }
  htmlTableRowClose();
  foreach $spammer (sort spammersByPreference(@selectedspammers)) {
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    if (($type eq "view") || ($type eq "remove")) {
      htmlTableData();
      htmlText($spammer);
      htmlTableDataClose();
    }
    else {
      htmlTableData("valign", "middle");
      $key = $spammer . "_definition";
      $value = (defined($g_form{'sort_submit'}) ||
                defined($g_form{'submit'})) ? 
                $g_form{$key} : $g_spammers{$spammer}->{'definition'};
      formInput("name", $key, "size", $size30, "value", $value);
      htmlTableDataClose();
      # error column
      htmlTableData("valign", "middle");
      if ($#{$errors{$spammer}} > -1) {
        foreach $mesg (@{$errors{$spammer}}) {
          htmlTextColorBold(">>> $mesg <<<", "#cc0000");
          htmlBR();
        }
      }
      htmlTableDataClose();
    }
    htmlTableRowClose();
  }
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("rowspan", "2");
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  if ($type eq "view") {
    if ($g_form{'sort_submit'} &&
        ($g_form{'sort_submit'} eq $SPAMMERS_SORT_BY_ORDER)) {
      formInput("type", "submit", "name", "sort_submit", "value",
                $SPAMMERS_SORT_BY_NAME);
    }
    else {
      formInput("type", "submit", "name", "sort_submit", "value",
                $SPAMMERS_SORT_BY_ORDER);
    }
  }
  else { 
    formInput("type", "submit", "name", "submit", "value", $buttontext);
    if ($type ne "remove") {
      formInput("type", "reset", "value", $RESET_STRING);
    }
    formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  }
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  formClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub spammersEmptyFile
{
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlText($SPAMMERS_NO_MAPPINGS_EXIST);
  htmlP();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub spammersLoad
{
  local($lcount, $curline, $name);

  %g_spammers = ();
  $lcount = 1;
  open(VFP, "/etc/spammers");
  while (<VFP>) {
    $curline = $_;
    next if ($curline =~ /^#/);
    $curline =~ s/^\s+//;
    $curline =~ s/\s+$//;
    next unless ($curline);
    $name = $curline;
    $g_spammers{$name}->{'definition'} = $name;
    $g_spammers{$name}->{'order'} = $lcount;
    $lcount++;
  }
  close(VFP);
}

##############################################################################

sub spammersNoChangesExist
{
  local($type) = @_;
  local($subtitle, $title);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("spammers");

  if ($type eq "add") {
    $subtitle = "$IROOT_ADD_TEXT";
  }
  elsif ($type eq "edit") {
    $subtitle = "$IROOT_EDIT_TEXT";
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_SPAMMERS_TITLE: $subtitle";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlText($SPAMMERS_NO_CHANGES_FOUND);
  htmlP();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub spammersRebuild
{
  local($output);

  $output = spammersRebuildDB();
  redirectLocation("iroot.cgi", $output);
}

##############################################################################

sub spammersRebuildDB
{
  local($tmpfile, $scount, $output);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("spammers");

  open(SPFP, "/etc/spammers") ||
      irootResourceError($IROOT_SPAMMERS_TITLE,
        "call to open(/etc/spammers) in spammersRebuildDB");
  $tmpfile = $g_tmpdir . "/.spammers-" . $g_curtime . "-" . $$;
  open(TMPFP, ">$tmpfile") ||
      irootResourceError($IROOT_SPAMMERS_TITLE,
        "call to open(>$tmpfile) in spammersRebuildDB");
  $scount = 0;
  while (<SPFP>) {
    $curline = $_;
    next if (($curline =~ /(^#)|(^$)/) || ($curline eq "\n"));
    chop($curline);
    print TMPFP "$curline\t\" $SPAMMERS_REJECT_MESSAGE\"\n";
    $scount++;
  }
  close(SPFP);
  close(TMPFP);

  initPlatformLocalBin();
  open(MAP, "$g_localbin/makemap hash /etc/spammers.db < $tmpfile 2>&1 |") ||
      irootResourceError($IROOT_SPAMMERS_TITLE,
        "call to open($g_localbin/makemap hash \
         /etc/spammers.db < $tmpfile) in spammersRebuildDB");
  $output = "";
  while (<MAP>) {
    s/^$g_localbin\/makemap://;
    $output .= $_;
  }
  close(MAP);
  unlink($tmpfile);

  # default output language from vnewspammers is english... change this?
  unless ($output) {
    $output = "/etc/spammers: $scount hostnames/addresses\n";
  }
  return($output);
}

##############################################################################

sub spammersSaveChanges
{
  local(@spammer_ids) = @_;
  local($spammer, %entries, $curentry, $match, $output);
  local($locked, $lastchar);

  foreach $spammer (@spammer_ids) {
    # sift through the spammer ids one by one
    if ($g_spammers{$spammer}->{'new_definition'} eq "__REMOVE") {
      # this is a subtle expectation in the code that may be missed.  set
      # the new definition value for a spammer to "__REMOVE" if you want
      # to remove the spammer from the spammers file.
      $entries{$spammer} = "__REMOVE";
      next;
    }
    $entries{$spammer} = $g_spammers{$spammer}->{'new_definition'};
  }

  # add a newline character to the file if necessary
  if (-e "/etc/spammers") {
    open(OLDSPAMFP, "/etc/spammers") ||
      irootResourceError($IROOT_SPAMMERS_TITLE,
          "open(OLDSPAMFP, '/etc/spammers') in spammersSaveChanges");
    seek(OLDSPAMFP, -1, 2);
    read(OLDSPAMFP, $lastchar, 1);
    close(OLDSPAMFP);
    if ($lastchar ne "\n") {
      open(OLDSPAMFP, ">>/etc/spammers") ||
        irootResourceError($IROOT_SPAMMERS_TITLE,
            "open(OLDSPAMFP, '>>/etc/spammers') in spammersSaveChanges");
      print OLDSPAMFP "\n";
      close(OLDSPAMFP);
    }
  }

  # backup old file
  require "$g_includelib/backup.pl";
  backupSystemFile("/etc/spammers");

  # write out new spammers file
  # first check for a lock file
  if (-f "/etc/stmptmp$$.$g_curtime") {
    irootResourceError($IROOT_SPAMMERS_TITLE,
        "-f '/etc/stmptmp$$.$g_curtime' returned 1 in spammersSaveChanges");
  }
  # no obvious lock... use link() for atomicity to avoid race conditions
  open(STMP, ">/etc/stmptmp$$.$g_curtime") ||
    irootResourceError($IROOT_SPAMMERS_TITLE,
        "open(STMP, '>/etc/stmptmp$$.$g_curtime') in spammersSaveChanges");
  close(STMP);
  $locked = link("/etc/stmptmp$$.$g_curtime", "/etc/stmp");
  unlink("/etc/stmptmp$$.$g_curtime");
  $locked || irootResourceError($IROOT_SPAMMERS_TITLE,
     "link('/etc/stmptmp$$.$g_curtime', '/etc/stmp') \
      failed in spammersSaveChanges");
  open(NEWSPAMFP, ">/etc/stmp")  ||
    irootResourceError($IROOT_SPAMMERS_TITLE,
        "open(NEWSPAMFP, '>/etc/stmp') in spammersSaveChanges");
  flock(NEWSPAMFP, 2);  # exclusive lock
  open(OLDSPAMFP, "/etc/spammers");
  while (<OLDSPAMFP>) {
    $curentry = $_;
    # print out curentry, replace, or ignore?
    $match = 0;
    foreach $spammer (@spammer_ids) {
      if ($curentry =~ /^$spammer\s/) {
        $match = 1;
        # we have a match, replace or ignore?
        if ($entries{$spammer} eq "__REMOVE") {
          # ignore
        }
        else {
          # replace
          print NEWSPAMFP "$entries{$spammer}\n" ||
            irootResourceError($IROOT_SPAMMERS_TITLE,
              "print to NEWSPAMFP failed -- server quota exceeded?");
        }
        delete($entries{$spammer});
      }
    }
    if ($match == 0) {
      print NEWSPAMFP "$curentry" ||
        irootResourceError($IROOT_SPAMMERS_TITLE,
          "print to NEWSPAMFP failed -- server quota exceeded?");
    }
  }     
  close(OLDSPAMFP);
  # append new entries
  foreach $entry (keys(%entries)) {
    next if ($entries{$entry} eq "__REMOVE");
    print NEWSPAMFP "$entries{$entry}\n" ||
      irootResourceError($IROOT_SPAMMERS_TITLE,
        "print to NEWSPAMFP failed -- server quota exceeded?");
  }     
  flock(NEWSPAMFP, 8);  # unlock
  close(NEWSPAMFP);
  rename("/etc/stmp", "/etc/spammers") ||
     irootResourceError($IROOT_SPAMMERS_TITLE, 
       "rename('/etc/stmp', '/etc/spammers') in spammersSaveChanges");
  chmod(0644, "/etc/spammers");
  
  # rebuild the spammers db file
  $output = spammersRebuildDB();
  return($output);
}

##############################################################################

sub spammersSelectForm
{
  local($type) = @_;
  local($title, $subtitle, $spammer, $scount);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("spammers");

  $subtitle = "$IROOT_SPAMMERS_TITLE: ";
  if ($type eq "edit") {
    $subtitle .= "$IROOT_EDIT_TEXT: $SPAMMERS_SELECT_TITLE";;
  }
  elsif ($type eq "remove") {
    $subtitle .= "$IROOT_REMOVE_TEXT: $SPAMMERS_SELECT_TITLE";;
  }

  $title = "$IROOT_MAINMENU_TITLE: $subtitle";

  # first check and see if there are more than one spammer to select
  $scount = 0;
  foreach $spammer (keys(%g_spammers)) {
    $scount++;
  }
  if ($scount == 0) {
    # oops.  no spammer definitions in spammers file.
    spammersEmptyFile();
  }
  elsif ($scount == 1) {
    $g_form{'spammers'} = (keys(%g_spammers))[0];
    return($g_form{'spammers'});
  }

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlTextLargeBold($subtitle);
  htmlBR();
  if ($g_form{'select_submit'} &&
      ($g_form{'select_submit'} eq $SPAMMERS_SELECT_TITLE)) {
    htmlBR();
    htmlTextColorBold(">>> $SPAMMERS_SELECT_HELP <<<", "#cc0000");
  }
  else {
    htmlText($SPAMMERS_SELECT_HELP);
  }
  htmlP();
  htmlUL();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "view", "value", $type);
  formSelect("name", "spammers", "size", formSelectRows($scount),
             "_OTHER_", "MULTIPLE");
  foreach $spammer (sort spammersByPreference(keys(%g_spammers))) {
    formSelectOption($spammer, $g_spammers{$spammer}->{'definition'});
  }
  formSelectClose();
  htmlP();
  formInput("type", "submit", "name", "select_submit",
            "value", $SPAMMERS_SELECT_TITLE);
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  formClose();
  htmlULClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################
# eof
  
1;

