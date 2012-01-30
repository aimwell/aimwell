#
# mailaccess.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/mailaccess.pl,v 2.12.2.3 2006/04/25 19:48:23 rus Exp $
#
# add/edit/remove/view mailaccess functions
#

##############################################################################

sub mailaccessByPreference
{
  if (($a =~ /^__NEWENTRY/) || ($b =~ /^__NEWENTRY/)) {
    return($a cmp $b);
  }

  if ($g_form{'sort_submit'} &&
      ($g_form{'sort_submit'} eq $MAILACCESS_SORT_BY_NAME)) {
    return($a cmp $b);
  }
  elsif ($g_form{'sort_submit'} &&
         ($g_form{'sort_submit'} eq $MAILACCESS_SORT_BY_ACTION)) {
    return($g_mailaccess{$a}->{'action'} cmp $g_mailaccess{$b}->{'action'});
  }
  else {
    # default... in order
    return($g_mailaccess{$a}->{'order'} <=> $g_mailaccess{$b}->{'order'});
  }
}

##############################################################################

sub mailaccessCheckFormValidity
{
  local($type) = @_;
  local($mesg, $mae, @selectedmailaccess, $macount, $nkey, $akey);
  local($errmsg, $errcode, %errors, %newmae); 
  
  encodingIncludeStringLibrary("mailaccess");
  
  if (($g_form{'submit'} && ($g_form{'submit'} eq "$CANCEL_STRING")) ||
      ($g_form{'select_submit'} && ($g_form{'select_submit'} eq "$CANCEL_STRING"))) {
    if ($type eq "add") {  
      $mesg = $MAILACCESS_CANCEL_ADD_TEXT;
    }
    elsif ($type eq "edit") {
      $mesg = $MAILACCESS_CANCEL_EDIT_TEXT;
    }
    elsif ($type eq "remove") {
      $mesg = $MAILACCESS_CANCEL_REMOVE_TEXT;
    } 
    redirectLocation("iroot.cgi", $mesg);
  } 

  # perform error checking on form data
  if (($type eq "add") || ($type eq "edit")) {
    $macount = 0;
    %errors = %newmae = ();
    @selectedmailaccess = split(/\|\|\|/, $g_form{'mailaccess'});
    foreach $mae (@selectedmailaccess) {
      $nkey = $mae . "_name"; 
      $akey = $mae . "_action"; 
      # next if new and left blank
      next if (($mae =~ /^__NEWENTRY/) && (!$g_form{$nkey}) && (!$g_form{$akey}));
      # next if no change was made (only applicable for type == edit)
      if (($type eq "edit") &&
          ($g_form{$nkey} eq $g_mailaccess{$mae}->{'name'}) &&
          ($g_form{$akey} eq $g_mailaccess{$mae}->{'action'})) {
        $g_form{'mailaccess'} =~ s/^\Q$mae\E$//;
        $g_form{'mailaccess'} =~ s/^\Q$mae\E\|\|\|//;
        $g_form{'mailaccess'} =~ s/\|\|\|\Q$mae\E\|\|\|/\|\|\|/;
        $g_form{'mailaccess'} =~ s/\|\|\|\Q$mae\E$//;
        next;
      }
      $macount++;
      # check to see if both name and action are specified (if one is 
      # specified, then require both ... if neither are specified, then
      # assume removal is wanted
      if ((!$g_form{$nkey}) && $g_form{$akey}) {
        push(@{$errors{$mae}}, $MAILACCESS_ERROR_ENTRY_FIELD_IS_BLANK);
      }
      if ($g_form{$nkey} && (!$g_form{$akey})) {
        push(@{$errors{$mae}}, $MAILACCESS_ERROR_ACTION_FIELD_IS_BLANK);
      }
      # mail access entry name checks
      if (($type eq "add") && (defined($g_mailaccess{$g_form{$nkey}}))) {
        # no duplicates allowed
        $errmsg = $MAILACCESS_ERROR_DUPLICATE_ADDITION;
        $errmsg =~ s/__ENTRY__/$g_form{$nkey}/;
        push(@{$errors{$mae}}, $errmsg);
      }
      if (defined($newmae{$g_form{$nkey}})) {
        $errmsg = $MAILACCESSS_ERROR_VIRTUAL_FIELD_REPEATED;
        $errmsg =~ s/__ENTRY__/$g_form{$nkey}/;
        push(@{$errors{$mae}}, $errmsg);
      }
      $newmae{$g_form{$nkey}} = "dau!";
      if ($g_form{$nkey} =~ m{\b([\w.\-\&]+?@[\w.-]+?)(?=[.-]*(?:[^\w.-]|$))}) {
        # set name value to be first e-mail address found
        $g_form{$nkey} = $1;
      }
      # mail access entry action checks
      # valid values include "OK", "RELAY", "REJECT", "DISCARD", and
      #                      "### text" where '###' is an RFC 821 error code
      #                      permanent error codes begin with a five ('5yz')
      #                      for example, '550 No such user here'
      if ($g_form{$akey}) {
        if ($g_form{$akey} =~ /^([0-9]+)/) {
          # check error code... should be in the 500 range.  fix if it isn't
          $errcode = $1;
          if (($errcode < 500) || ($errcode > 599)) {
            $errcode = 550;
          }
          $g_form{$akey} =~ /^[0-9]+\s+(.*)/;
          $errmsg = $1 || $MAILACCESS_DEFAULT_ERROR_CODE_TEXT;
          $g_form{$akey} = "$errcode $errmsg";
        }
        elsif ($g_form{$akey} =~ /^\S+\s+\S+/) {
          # multiple word response (that doesn't begin with an error code)
          # fix by prepending with an error code
          $g_form{$akey} = "550 $g_form{$akey}";
        }
        else {
          # only remaining options are OK, REJECT, and RELAY
          if (($g_form{$akey} =~ /^ok$/i) ||
              ($g_form{$akey} =~ /^reject$/i) ||
              ($g_form{$akey} =~ /^relay$/i)) {
            $g_form{$akey} =~ tr/a-z/A-Z/;
          }
          else {
            push(@{$errors{$mae}}, $MAILACCESS_ERROR_ACTION_FIELD_IS_INVALID);
          }
        }
      }
    }
    if (keys(%errors)) {
      mailaccessDisplayForm($type, %errors);
    }
    if ($macount == 0) {
      # nothing to do!
      mailaccessNoChangesExist($type);
    }
    # print out a confirm form if necessary
    $g_form{'confirm'} = "no" unless ($g_form{'confirm'});
    if ($g_form{'confirm'} ne "yes") {
      mailaccessConfirmChanges($type);
    }
  }
}

##############################################################################

sub mailaccessCommitChanges
{
  local($type) = @_;
  local($mae, @selectedmailaccess, @malist, $nkey, $akey, $pkey);
  local($success_mesg, $output);

  @selectedmailaccess = split(/\|\|\|/, $g_form{'mailaccess'});
  foreach $mae (@selectedmailaccess) {
    if (($type eq "add") || ($type eq "edit")) {
      $nkey = $mae . "_name";
      $akey = $mae . "_action";
      if ($mae =~ /^__NEWENTRY/) {
        $pkey = $mae . "_placement";
      }
      # next if new and left blank
      next if (($mae =~ /^__NEWENTRY/) && (!$g_form{$nkey}) && (!$g_form{$akey}));
      # next if no change was made (only applicable for type == edit)
      next if (($type eq "edit") &&
               ($g_form{$nkey} eq $g_mailaccess{$mae}->{'name'}) &&
               ($g_form{$akey} eq $g_mailaccess{$mae}->{'action'}));
      if ((!$g_form{$nkey}) && (!$g_form{$akey})) {
        # poor man's way of removing a mail access entry, i.e. editing it and
        # setting its definition and action values to "" ...tag it for removal
        $g_mailaccess{$mae}->{'new_name'} = "__REMOVE";
      }
      else {
        $g_mailaccess{$mae}->{'new_name'} = $g_form{$nkey};
        $g_mailaccess{$mae}->{'new_action'} = $g_form{$akey};
        $g_mailaccess{$mae}->{'placement'} = $g_form{$pkey};
      }
      push(@malist, $mae);
    }
    elsif ($type eq "remove") {
      $g_mailaccess{$mae}->{'new_name'} = "__REMOVE";
      push(@malist, $mae);
    }
  }
  $output = mailaccessSaveChanges(@malist);

  # now redirect back to iroot index and show success message
  if ($type eq "add") {
    $success_mesg = $MAILACCESS_SUCCESS_ADD_TEXT;
  }
  elsif ($type eq "edit") {
    $success_mesg = $MAILACCESS_SUCCESS_EDIT_TEXT;
  }
  elsif ($type eq "remove") {
    $success_mesg = $MAILACCESS_SUCCESS_REMOVE_TEXT;
  }
  $success_mesg .= "\n$output" if ($output);
  redirectLocation("iroot.cgi", $success_mesg);
}

##############################################################################

sub mailaccessConfirmChanges
{
  local($type) = @_;
  local($subtitle, $title);
  local($mae, @selectedmailaccess, $nkey, $akey, $pkey, $entry);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("mailaccess");

  if ($type eq "add") {
    $subtitle = "$IROOT_ADD_TEXT: $CONFIRM_STRING";
  }
  elsif ($type eq "edit") {
    $subtitle = "$IROOT_EDIT_TEXT: $CONFIRM_STRING";
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_MAILACCESS_TITLE: $subtitle";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlText($MAILACCESS_CONFIRM_TEXT);
  htmlP();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "type", "value", $type);
  formInput("type", "hidden", "name", "confirm", "value", "yes");
  formInput("type", "hidden", "name", "mailaccess",
            "value", $g_form{'mailaccess'});
  htmlUL();
  @selectedmailaccess = split(/\|\|\|/, $g_form{'mailaccess'});
  foreach $mae (@selectedmailaccess) {
    $nkey = $mae . "_name";
    $akey = $mae . "_action";
    $pkey = $mae . "_placement";
    # next if new and left blank
    next if (($mae =~ /^__NEWENTRY/) && (!$g_form{$nkey}) && (!$g_form{$akey}));
    # next if no change was made (only applicable for type == edit)
    next if (($type eq "edit") &&
             ($g_form{$nkey} eq $g_mailaccess{$mae}->{'name'}) &&
             ($g_form{$akey} eq $g_mailaccess{$mae}->{'action'}));
    # print out the hidden fields
    formInput("type", "hidden", "name", $nkey, "value", $g_form{$nkey});
    formInput("type", "hidden", "name", $akey, "value", $g_form{$akey});
    if (defined($g_form{$pkey})) {
      formInput("type", "hidden", "name", $pkey, "value", $g_form{$pkey});
    }
    if ((!$g_form{$nkey}) && (!$g_form{$akey})) {
      # poor man's way of removing a mail access entry, i.e. editing it and
      # setting its name and action to "" ...confirm it's removal
      htmlListItem();
      htmlTextBold($MAILACCESS_CONFIRM_REMOVE_OLD);
      htmlBR();
      htmlText("&#160;&#160;&#160;&#160;");
      htmlTextCode($g_mailaccess{$mae}->{'name'});
      htmlTextCode(" => ");
      htmlTextCode($g_mailaccess{$mae}->{'action'});
      htmlBR();
    }
    else {
      if ($mae =~ /^__NEWENTRY/) {
        # confirm addition
        htmlListItem();
        htmlTextBold($MAILACCESS_CONFIRM_ADD_NEW);
        htmlBR();
        htmlText("&#160;&#160;&#160;&#160;");
        htmlTextCode($g_form{$nkey});
        htmlTextCode(" => ");
        htmlTextCode($g_form{$akey});
        htmlBR();
      }
      else {
        if ($g_form{$nkey} ne $g_mailaccess{$mae}->{'name'}) {
          # confirm name edit
          $entry = $MAILACCESS_CONFIRM_CHANGE_NAME;
          $entry =~ s/__NAME__/$g_mailaccess{$mae}->{'name'}/;
          $entry =~ s/__NEWNAME__/$g_form{$nkey}/;
          htmlListItem();
          htmlTextBold($entry);
          htmlBR();
          if ($g_form{$akey} eq $g_mailaccess{$mae}->{'action'}) {
            htmlTable("border", "0", "cellspacing", "0", "cellpadding", "0");
            htmlTableRow();
            htmlTableData();
            htmlNoBR();
            htmlText("&#160;&#160;&#160;&#160;");
            htmlText("$MAILACCESS_CONFIRM_CHANGE_VALUE_OLD:");
            htmlText("&#160;&#160;");
            htmlNoBRClose();
            htmlTableDataClose();
            htmlTableData();
            htmlNoBR();
            htmlTextCode($g_mailaccess{$mae}->{'name'});
            htmlTextCode(" => ");
            htmlTextCode($g_mailaccess{$mae}->{'action'});
            htmlNoBRClose();
            htmlTableDataClose();
            htmlTableRowClose();
            htmlTableRow();
            htmlTableData();
            htmlNoBR();
            htmlText("&#160;&#160;&#160;&#160;");
            htmlText("$MAILACCESS_CONFIRM_CHANGE_VALUE_NEW:");
            htmlText("&#160;&#160;");
            htmlNoBRClose();
            htmlTableDataClose();
            htmlTableData();
            htmlNoBR();
            htmlTextCode($g_form{$nkey});
            htmlTextCode(" => ");
            htmlTextCode($g_mailaccess{$mae}->{'action'});
            htmlNoBRClose();
            htmlTableDataClose();
            htmlTableRowClose();
            htmlTableClose();
          }
          htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
          htmlBR();
        }
        if ($g_form{$akey} ne $g_mailaccess{$mae}->{'action'}) {
          $entry = $MAILACCESS_CONFIRM_CHANGE_VALUE;
          if ($g_form{$nkey} ne $g_mailaccess{$mae}->{'name'}) {
            $entry =~ s/__NAME__/$g_form{$nkey}/;
          }
          else {
            $entry =~ s/__NAME__/$g_mailaccess{$mae}->{'name'}/;
          }
          htmlListItem();
          htmlTextBold($entry);
          htmlBR();
          htmlTable("border", "0", "cellspacing", "0", "cellpadding", "0");
          htmlTableRow();
          htmlTableData();
          htmlNoBR();
          htmlText("&#160;&#160;&#160;&#160;");
          htmlText("$MAILACCESS_CONFIRM_CHANGE_VALUE_OLD:");
          htmlText("&#160;&#160;");
          htmlNoBRClose();
          htmlTableDataClose();
          htmlTableData();
          htmlNoBR();
          htmlTextCode($g_mailaccess{$mae}->{'name'});
          htmlTextCode(" => ");
          htmlTextCode($g_mailaccess{$mae}->{'action'});
          htmlNoBRClose();
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableRow();
          htmlTableData();
          htmlNoBR();
          htmlText("&#160;&#160;&#160;&#160;");
          htmlText("$MAILACCESS_CONFIRM_CHANGE_VALUE_NEW:");
          htmlText("&#160;&#160;");
          htmlNoBRClose();
          htmlTableDataClose();
          htmlTableData();
          htmlNoBR();
          if ($g_form{$nkey} eq $g_mailaccess{$mae}->{'name'}) {
            htmlTextCode($g_mailaccess{$mae}->{'name'});
          }
          else {
            htmlTextCode($g_form{$nkey});
          }
          htmlTextCode(" => ");
          htmlTextCode($g_form{$akey});
          htmlNoBRClose();
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableClose();
          htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
          htmlBR();
        }
      }
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

sub mailaccessDisplayForm
{
  local($type, %errors) = @_;
  local($title, $subtitle, $helptext, $buttontext, $mesg, $maelist);
  local(@selectedmailaccess, $mae, $index, $singlemae, $maeoption);
  local($size25, $size35, $key, $value);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("mailaccess");

  if ($type eq "add") {
    $subtitle = $IROOT_ADD_TEXT;
    if ($g_form{'mailaccess'}) {
      @selectedmailaccess = split(/\|\|\|/, $g_form{'mailaccess'});
    }
    else {
      for ($index=1; $index<=$g_prefs{'iroot__num_newmailaccess'}; $index++) {
        push(@selectedmailaccess, "__NEWENTRY$index");
        $maelist .= "__NEWENTRY$index\|\|\|";
      }
      $maelist =~ s/\|+$//g;
      $g_form{'mailaccess'} = $maelist;
    }
    $helptext = $MAILACCESS_ADD_HELP_TEXT;
    $buttontext = $MAILACCESS_ADD_SUBMIT_TEXT;
  } 
  elsif ($type eq "edit") {
    $subtitle = $IROOT_EDIT_TEXT;
    @selectedmailaccess = split(/\|\|\|/, $g_form{'mailaccess'}) if ($g_form{'mailaccess'});;
    $helptext = $MAILACCESS_EDIT_HELP_TEXT;
    $buttontext = $MAILACCESS_EDIT_SUBMIT_TEXT;
  } 
  elsif ($type eq "remove") {
    $subtitle = $IROOT_REMOVE_TEXT;
    @selectedmailaccess = split(/\|\|\|/, $g_form{'mailaccess'}) if ($g_form{'mailaccess'});;
    $helptext = $MAILACCESS_REMOVE_HELP_TEXT;
    $buttontext = $MAILACCESS_REMOVE_SUBMIT_TEXT;
  }
  elsif ($type eq "view") {
    $subtitle = $IROOT_VIEW_TEXT;
    foreach $mae (keys(%g_mailaccess)) {
      push(@selectedmailaccess, $mae);
    }
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_MAILACCESS_TITLE: $subtitle";

  if ($#selectedmailaccess == -1) {
    # oops... no entries in selected mail access list.
    if (($type eq "edit") || ($type eq "remove")) {
      $singlemae = mailaccessSelectForm($type);
      @selectedmailaccess = ("$singlemae");
    } 
    else {
      mailaccessEmptyFile();
    } 
  }
  else {
    # have selected mailaccess, are we re-sorting?
    if (($type eq "edit") || ($type eq "remove")) {
      mailaccessSelectForm($type) if ($g_form{'sort_select'});
    }
  }

  $size25 = formInputSize(25);
  $size35 = formInputSize(35);

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
      htmlText($MAILACCESS_OVERVIEW_HELP_TEXT_1);
      htmlP();
      htmlText($MAILACCESS_OVERVIEW_HELP_TEXT_2);
      htmlP();
      htmlText($MAILACCESS_EXAMPLES_HELP_TEXT_1);
      htmlP();
      htmlPre();
      htmlFont("class", "fixed", "face", "courier new, courier", "size", "2",
               "style", "font-family:courier new, courier; font-size:12px");
      print "$MAILACCESS_EXAMPLES_HELP_TEXT_2";
      htmlFontClose();
      htmlPreClose();
    }
  }
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "view", "value", $type);
  formInput("type", "hidden", "name", "mailaccess", 
            "value", $g_form{'mailaccess'});
  htmlTable();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "bottom");
  htmlTextBold($MAILACCESS_ENTRY);
  htmlTableDataClose();
  htmlTableData("valign", "bottom");
  htmlText("&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "bottom");
  htmlTextBold($MAILACCESS_ACTION);
  htmlTableDataClose();
  if ($type eq "add") {
    # placement column
    htmlTableData("valign", "bottom");
    htmlTextBold($MAILACCESS_ENTRY_PLACEMENT);
    htmlTableDataClose();
  }
  if (($type eq "add") || ($type eq "edit")) {
    # error column
    htmlTableData();
    htmlTableDataClose();
  }
  htmlTableRowClose();
  foreach $mae (sort mailaccessByPreference(@selectedmailaccess)) {
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    if (($type eq "view") || ($type eq "remove")) {
      htmlTableData();
      htmlText($g_mailaccess{$mae}->{'name'});
      htmlTableDataClose();
      htmlTableData();
      htmlText("=>");
      htmlTableDataClose();
      htmlTableData();
      htmlText($g_mailaccess{$mae}->{'action'});
      htmlTableDataClose();
    }
    else {
      if ($#{$errors{$mae}} > -1) {
        htmlTableData("colspan", (($type eq "add") ? "4" : "3"));
        htmlTable("bgcolor", "#cc0000", "cellspacing", "1", "cellpadding", "0");
        htmlTableRow();
        htmlTableData();
        htmlTable("bgcolor", "#eeeeee");
        htmlTableRow();
      }
      htmlTableData("valign", "middle");
      $key = $mae . "_name";
      $value = (defined($g_form{'sort_submit'}) ||
                defined($g_form{'submit'})) ? $g_form{$key} : 
                                              $g_mailaccess{$mae}->{'name'};
      formInput("name", $key, "size", $size25, "value", $value);
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      htmlText("=>");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      $key = $mae . "_action";
      $value = (defined($g_form{'sort_submit'}) ||
                defined($g_form{'submit'})) ? $g_form{$key} :
                                              $g_mailaccess{$mae}->{'action'};
      formInput("name", $key, "size", $size35, "value", $value);
      htmlTableDataClose();
      if ($type eq "add") {
        # placement column
        htmlTableData("valign", "middle");
        $key = $mae . "_placement";
        formSelect("name", $key);
        formSelectOption("__APPEND", $MAILACCESS_ENTRY_PLACEMENT_APPEND, 
                         ((!$g_form{$key}) || ($g_form{$key} eq "__APPEND")));
        foreach $maeoption (sort mailaccessByPreference(keys(%g_mailaccess))) {
          next if ($maeoption =~ /^__NEWENTRY/);
          $value = $MAILACCESS_ENTRY_PLACEMENT_INSERT;
          $value =~ s/__ENTRY__/$maeoption/;
          formSelectOption($maeoption, $value, ($g_form{$key} eq $maeoption));
        }
        formSelectClose();
        htmlTableDataClose();
      }
      if ($#{$errors{$mae}} > -1) {
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("colspan", (($type eq "add") ? "4" : "3"));
        foreach $mesg (@{$errors{$mae}}) {
          htmlNoBR();
          htmlTextColorBold(">>> $mesg <<<", "#cc0000");
          htmlNoBRClose();
          htmlBR();
        }
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableClose();
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableClose();
        htmlTableDataClose();
      }
    }
    htmlTableRowClose();
  }
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("colspan", "4");
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  if ($type eq "view") {
    if ((!$g_form{'sort_submit'}) ||
        ($g_form{'sort_submit'} ne $MAILACCESS_SORT_BY_NAME)) {
      formInput("type", "submit", "name", "sort_submit", "value",
                $MAILACCESS_SORT_BY_NAME);
    } 
    if ((!$g_form{'sort_submit'}) ||
        ($g_form{'sort_submit'} ne $MAILACCESS_SORT_BY_ACTION)) {
      formInput("type", "submit", "name", "sort_submit", "value",
                $MAILACCESS_SORT_BY_ACTION);
    }
    if (($g_form{'sort_submit'}) &&
        ($g_form{'sort_submit'} ne $MAILACCESS_SORT_BY_ORDER)) {
      formInput("type", "submit", "name", "sort_submit", "value",
                $MAILACCESS_SORT_BY_ORDER);
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

sub mailaccessEmptyFile
{
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlText($MAILACCESS_NO_ENTRIES_EXIST);
  htmlP();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub mailaccessLoad
{
  local($lcount, $curline, $name, $value, $whitespace, $len, $idx);

  %g_mailaccess = ();
  $lcount = 1;
  open(VFP, "/etc/mail/access");
  while (<VFP>) {
    $curline = $_;
    next if ($curline =~ /^#/);
    $curline =~ s/^\s+//;
    $curline =~ s/\s+$//;
    next unless ($curline);
    $curline =~ s/^(\S+)(\s+)(.*)/ /g;
    $name = $1;
    $value = $3;
    $whitespace = $2;
    $whitespace =~ s/\t/\ \ \ \ \ \ \ \ /g;
    $g_mailaccess{$name}->{'name'} = $name;
    $g_mailaccess{$name}->{'action'} = $value;
    $g_mailaccess{$name}->{'order'} = $lcount;
    $len = length($name) + length($whitespace);
    # store left position; use this later to preserve original formatting
    $g_mailaccess{$name}->{'leftpos'} = $len;
    $g_lastleftpos = $len;
    $lcount++;
  }
  close(VFP);
}

##############################################################################

sub mailaccessNoChangesExist
{
  local($type) = @_;
  local($subtitle, $title);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("mailaccess");

  if ($type eq "add") {
    $subtitle = "$IROOT_ADD_TEXT";
  }
  elsif ($type eq "edit") {
    $subtitle = "$IROOT_EDIT_TEXT";
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_MAILACCESS_TITLE: $subtitle";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlText($MAILACCESS_NO_CHANGES_FOUND);
  htmlP();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub mailaccessRebuild
{
  local($output);

  $output = mailaccessRebuildDB();
  redirectLocation("iroot.cgi", $output);
}

##############################################################################

sub mailaccessRebuildDB
{
  local($tmpfile, $macount, $output, $madir, $mafile);

  encodingIncludeStringLibrary("iroot");

  $madir = "/etc/mail";
  $mafile = "access";

  unless (-e "$madir/$mafile") {
    # create a empty (zero byte) file
    open(MAFP, ">$madir/$mafile") ||
      irootResourceError($IROOT_MAILACCESS_TITLE,
        "call to open(>$madir/$mafile) in mailaccessRebuildDB");
    close(MAFP);
  }

  open(MAFP, "$madir/$mafile") ||
      irootResourceError($IROOT_MAILACCESS_TITLE,
        "call to open($madir/$mafile) in mailaccessRebuildDB");
  $tmpfile = $g_tmpdir . "/.mailaccess-" . $g_curtime . "-" . $$;
  open(TMPFP, ">$tmpfile") ||
      irootResourceError($IROOT_MAILACCESS_TITLE,
        "call to open(>$tmpfile) in mailaccessRebuildDB");
  $macount = 0;
  while (<MAFP>) {
    $curline = $_;
    next if (($curline =~ /^#/) || ($curline eq "\n"));
    print TMPFP $curline;
    $macount++;
  }
  close(MAFP);
  close(TMPFP);

  initPlatformLocalBin();
  open(MAP, "$g_localbin/makemap hash $madir/$mafile.db < $tmpfile 2>&1 |") ||
      irootResourceError($IROOT_MAILACCESS_TITLE,
        "call to open($g_localbin/makemap hash \
         $madir/$mafile.db < $tmpfile) in mailaccessRebuildDB");
  $output = "";
  while (<MAP>) {
    s/^$g_localbin\/makemap://;
    $output .= $_;
  }
  close(MAP);
  unlink($tmpfile);

  # default output language from vnewmailaccess is english... change this?
  unless ($output) {
    $output = "$madir/$mafile: $macount mail access entries\n";
  }
  return($output);
}

##############################################################################

sub mailaccessSaveChanges
{
  local(@ma_ids) = @_;
  local($mae, $newentry, %entries, $curentry, $match);
  local($entry_name, $entry_action, $numspaces, $output);
  local($locked, $lastchar, $madir, $mafile);

  foreach $mae (@ma_ids) {
    # sift through the mail access entry ids one by one
    if ($g_mailaccess{$mae}->{'new_name'} eq "__REMOVE") {
      # this is a subtle expectation in the code that may be missed.  set
      # the new name value for a mail access entry to "__REMOVE" if you want
      # to remove the entry from the mailaccess file.
      $entries{$mae} = "__REMOVE";
      next;
    }
    $entry_name = $g_mailaccess{$mae}->{'new_name'};
    $entry_action = $g_mailaccess{$mae}->{'new_action'};
    $newentry = $entry_name;
    if ($mae =~ /^__NEWENTRY/) {
      # figure out how to line up the left hand column
      if ($g_mailaccess{$mae}->{'placement'} eq "__APPEND") {
        $g_mailaccess{$mae}->{'leftpos'} = $g_lastleftpos;
      }
      else {
        $g_mailaccess{$mae}->{'leftpos'} =
               $g_mailaccess{$g_mailaccess{$mae}->{'placement'}}->{'leftpos'};
      }
    }
    $numspaces = $g_mailaccess{$mae}->{'leftpos'} - length($newentry);
    $numspaces = 8 if ($numspaces <= 0);
    $newentry .= " " x $numspaces;
    $newentry .= $entry_action;
    $entries{$mae} = $newentry;
  }

  $madir = "/etc/mail";
  $mafile = "access";

  unless (-e "$madir/$mafile") {
    # create a empty (zero byte) file
    open(MAFP, ">$madir/$mafile") ||
      irootResourceError($IROOT_MAILACCESS_TITLE,
        "call to open(>$madir/$mafile) in mailaccessRebuildDB");
    close(MAFP);
  }

  # add a newline character to the file if necessary
  if (-e "$madir/$mafile") {
    open(OLDMAFP, "$madir/$mafile") ||
      irootResourceError($IROOT_MAILACCESS_TITLE,
          "open(OLDMAFP, '$madir/$mafile') in mailaccessSaveChanges");
    seek(OLDMAFP, -1, 2);
    read(OLDMAFP, $lastchar, 1);
    close(OLDMAFP);
    if ($lastchar ne "\n") {
      open(OLDMAFP, ">>$madir/$mafile") ||
        irootResourceError($IROOT_MAILACCESS_TITLE,
            "open(OLDMAFP, '>>$madir/$mafile') in mailaccessSaveChanges");
      print OLDMAFP "\n";
      close(OLDMAFP);
    }
  }

  # backup old file
  require "$g_includelib/backup.pl";
  backupSystemFile("$madir/$mafile");

  # write out new mailaccess file
  # first check for a lock file
  if (-f "$madir/matmptmp$$.$g_curtime") {
    irootResourceError($IROOT_MAILACCESS_TITLE,
        "-f '$madir/matmptmp$$.$g_curtime' returned 1 in mailaccessSaveChanges");
  }
  # no obvious lock... use link() for atomicity to avoid race conditions
  open(VTMP, ">$madir/matmptmp$$.$g_curtime") ||
    irootResourceError($IROOT_MAILACCESS_TITLE,
        "open(VTMP, '>$madir/matmptmp$$.$g_curtime') in mailaccessSaveChanges");
  close(VTMP);
  $locked = link("$madir/matmptmp$$.$g_curtime", "$madir/matmp");
  unlink("$madir/matmptmp$$.$g_curtime");
  $locked || irootResourceError($IROOT_MAILACCESS_TITLE,
     "link('$madir/matmptmp$$.$g_curtime', '$madir/matmp') \
      failed in mailaccessSaveChanges");
  open(NEWMAFP, ">$madir/matmp")  ||
    irootResourceError($IROOT_MAILACCESS_TITLE,
        "open(NEWMAFP, '>$madir/matmp') in mailaccessSaveChanges");
  flock(NEWMAFP, 2);  # exclusive lock
  open(OLDMAFP, "$madir/$mafile");
  while (<OLDMAFP>) {
    $curentry = $_;
    # print out curentry, replace, or ignore?
    $match = 0;
    foreach $mae (@ma_ids) {
      if ($curentry =~ /^$mae\s/) {
        $match = 1;
        # we have a match, replace or ignore?
        if ($entries{$mae} eq "__REMOVE") {
          # ignore
        }
        else {
          # replace
          print NEWMAFP "$entries{$mae}\n" ||
            irootResourceError($IROOT_MAILACCESS_TITLE,
              "print to NEWMAFP failed -- server quota exceeded?");
        }
        delete($entries{$mae});
      }
    }
    if ($match == 0) {
      print NEWMAFP "$curentry" ||
        irootResourceError($IROOT_MAILACCESS_TITLE,
          "print to NEWMAFP failed -- server quota exceeded?");
    }
    # append any new mailaccess after current entry if applicable
    foreach $mae (@ma_ids) {
      next unless ($mae =~ /^__NEWENTRY/);
      if ($curentry =~ /^$g_mailaccess{$mae}->{'placement'}\s/) {
        print NEWMAFP "$entries{$mae}\n" ||
          irootResourceError($IROOT_MAILACCESS_TITLE,
            "print to NEWMAFP failed -- server quota exceeded?");
        delete($entries{$mae});
      }
    }
  } 
  close(OLDMAFP);
  # append new entries
  foreach $entry (keys(%entries)) {
    next if ($entries{$entry} eq "__REMOVE");
    print NEWMAFP "$entries{$entry}\n" ||
      irootResourceError($IROOT_MAILACCESS_TITLE,
        "print to NEWMAFP failed -- server quota exceeded?");
  } 
  flock(NEWMAFP, 8);  # unlock
  close(NEWMAFP);
  rename("$madir/matmp", "$madir/$mafile") ||
     irootResourceError($IROOT_MAILACCESS_TITLE, 
       "rename('$madir/matmp', '$madir/$mafile') in mailaccessSaveChanges");
  chmod(0644, "$madir/$mafile");
  
  # rebuild the mailaccess db file
  $output = mailaccessRebuildDB();
  return($output);
}

##############################################################################

sub mailaccessSelectForm
{
  local($type) = @_;
  local($title, $subtitle, $mae, $macount, $optiontxt);
  local(@selectedmailaccess, $smae, $selected);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("mailaccess");

  $subtitle = "$IROOT_MAILACCESS_TITLE: ";
  if ($type eq "edit") {
    $subtitle .= "$IROOT_EDIT_TEXT: $MAILACCESS_SELECT_TITLE";;
  }
  elsif ($type eq "remove") {
    $subtitle .= "$IROOT_REMOVE_TEXT: $MAILACCESS_SELECT_TITLE";;
  }

  $title = "$IROOT_MAINMENU_TITLE: $subtitle";

  # first check and see if there are more than one mail access entry to select
  $macount = 0;
  foreach $mae (keys(%g_mailaccess)) {
    $macount++;
  }
  if ($macount == 0) {
    # oops.  no mail access definitions in mailaccess file.
    mailaccessEmptyFile();
  }
  elsif ($macount == 1) {
    $g_form{'mailaccess'} = (keys(%g_mailaccess))[0]; 
    return($g_form{'mailaccess'});
  }

  @selectedmailaccess = split(/\|\|\|/, $g_form{'mailaccess'}) if ($g_form{'mailaccess'});

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTextLargeBold($subtitle);
  htmlBR();
  if ($g_form{'select_submit'} &&
      ($g_form{'select_submit'} eq $MAILACCESS_SELECT_TITLE)) {
    htmlBR();
    htmlTextColorBold(">>> $MAILACCESS_SELECT_HELP <<<", "#cc0000");
  }
  else {
    htmlText($MAILACCESS_SELECT_HELP);
  }
  htmlP();
  formOpen("method", "POST");
  authPrintHiddenFields();
  htmlTable();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  formInput("type", "hidden", "name", "view", "value", $type);
  formSelect("name", "mailaccess", "size", formSelectRows($macount),
             "_OTHER_", "MULTIPLE", "_FONT_", "fixed");
  $g_form{'sort_submit'} = $g_form{'sort_select'};
  foreach $mae (sort mailaccessByPreference(keys(%g_mailaccess))) {
    $selected = 0;
    foreach $smae (@selectedmailaccess) {
      if ($smae eq $mae) {
        $selected = 1;
        last;
      }
    }
    $optiontxt = "$g_mailaccess{$mae}->{'name'} => ";
    $optiontxt .= "$g_mailaccess{$mae}->{'action'}";
    if (length($optiontxt) > 70) {
      $optiontxt = substr($optiontxt, 0, 70) . "&#133;";
    }
    formSelectOption($mae, $optiontxt, $selected);
  }
  formSelectClose();
  htmlTableDataClose();
  htmlTableData("valign", "top");
  if ((!$g_form{'sort_select'}) ||
      ($g_form{'sort_select'} ne "$MAILACCESS_SORT_BY_NAME")) {
    formInput("type", "submit", "name", "sort_select", "value",
              $MAILACCESS_SORT_BY_NAME);
    htmlBR();
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
  }
  if ((!$g_form{'sort_select'}) ||
      ($g_form{'sort_select'} ne "$MAILACCESS_SORT_BY_ACTION")) {
    formInput("type", "submit", "name", "sort_select", "value",
              $MAILACCESS_SORT_BY_ACTION);
    htmlBR();
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
  }
  if (($g_form{'sort_select'}) &&
      ($g_form{'sort_select'} ne "$MAILACCESS_SORT_BY_ORDER")) {
    formInput("type", "submit", "name", "sort_select", "value",
              $MAILACCESS_SORT_BY_ORDER);
    htmlBR();
  }
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("colspan", "2");
  formInput("type", "submit", "name", "select_submit",
            "value", $MAILACCESS_SELECT_TITLE);
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  formClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################
# eof
  
1;

