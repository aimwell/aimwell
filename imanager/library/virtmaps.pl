#
# virtmaps.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/virtmaps.pl,v 2.12.2.4 2006/04/25 19:48:25 rus Exp $
#
# add/edit/remove/view virtmaps functions
#

##############################################################################

sub virtmapsByPreference
{
  if (($a =~ /^__NEWVIRTMAP/) || ($b =~ /^__NEWVIRTMAP/)) {
    return($a cmp $b);
  }

  if (($g_form{'sort_submit'} && 
      ($g_form{'sort_submit'} eq $VIRTMAPS_SORT_BY_NAME))) {
    return($a cmp $b);
  }
  else {
    # default... by order
    return($g_virtmaps{$a}->{'order'} <=> $g_virtmaps{$b}->{'order'});
  }
}

##############################################################################

sub virtmapsCheckFormValidity
{
  local($type) = @_;
  local($mesg, $virtmap, @selectedvirtmaps, $vcount, $vkey, $rkey);
  local($errmsg, %errors, %newvirtmaps); 
  
  encodingIncludeStringLibrary("virtmaps");
  
  if (($g_form{'submit'} && ($g_form{'submit'} eq "$CANCEL_STRING")) ||
      ($g_form{'select_submit'} && ($g_form{'select_submit'} eq "$CANCEL_STRING"))) {
    if ($type eq "add") {  
      $mesg = $VIRTMAPS_CANCEL_ADD_TEXT;
    }
    elsif ($type eq "edit") {
      $mesg = $VIRTMAPS_CANCEL_EDIT_TEXT;
    }
    elsif ($type eq "remove") {
      $mesg = $VIRTMAPS_CANCEL_REMOVE_TEXT;
    } 
    redirectLocation("iroot.cgi", $mesg);
  } 

  # perform error checking on form data
  if (($type eq "add") || ($type eq "edit")) {
    $vcount = 0;
    %errors = %newvirtmaps = ();
    @selectedvirtmaps = split(/\|\|\|/, $g_form{'virtmaps'});
    foreach $virtmap (@selectedvirtmaps) {
      $vkey = $virtmap . "_virtual"; 
      $rkey = $virtmap . "_real"; 
      # next if new and left blank
      next if (($virtmap =~ /^__NEWVIRTMAP/) && (!$g_form{$vkey}) && (!$g_form{$rkey}));
      # next if no change was made (only applicable for type == edit)
      if (($type eq "edit") &&
          ($g_form{$vkey} eq $g_virtmaps{$virtmap}->{'virtual'}) &&
          ($g_form{$rkey} eq $g_virtmaps{$virtmap}->{'real'})) {
        $g_form{'virtmaps'} =~ s/^\Q$virtmap\E$//;
        $g_form{'virtmaps'} =~ s/^\Q$virtmap\E\|\|\|//;
        $g_form{'virtmaps'} =~ s/\|\|\|\Q$virtmap\E\|\|\|/\|\|\|/;
        $g_form{'virtmaps'} =~ s/\|\|\|\Q$virtmap\E$//;
        next;
      }
      $vcount++;
      # check to see if both virtual and real are specified (if one is 
      # specified, then require both ... if neither are specified, then
      # assume removal is wanted
      if ((!$g_form{$vkey}) && $g_form{$rkey}) {
        push(@{$errors{$virtmap}}, $VIRTMAPS_ERROR_VIRTUAL_FIELD_IS_BLANK);
      }
      if ($g_form{$vkey} && (!$g_form{$rkey})) {
        push(@{$errors{$virtmap}}, $VIRTMAPS_ERROR_REAL_FIELD_IS_BLANK);
      }
      # virtual address checks
      if (($type eq "add") && (defined($g_virtmaps{$g_form{$vkey}}))) {
        # no duplicates allowed
        $errmsg = $VIRTMAPS_ERROR_DUPLICATE_ADDITION;
        $errmsg =~ s/__VIRTMAP__/$g_form{$vkey}/;
        push(@{$errors{$virtmap}}, $errmsg);
      }
      if (defined($newvirtmaps{$g_form{$vkey}})) {
        $errmsg = $VIRTMAPS_ERROR_VIRTUAL_FIELD_REPEATED;
        $errmsg =~ s/__VIRTMAP__/$g_form{$vkey}/;
        push(@{$errors{$virtmap}}, $errmsg);
      }
      $newvirtmaps{$g_form{$vkey}} = "dau!";
      if ($g_platform_type eq "virtual") {
        if ($g_form{$vkey} =~ /\@/) {
          # an e-mail address virtual virtmap definition
          # maybe insert some checks here later
        }
        else {
          # a hostname catch-all virtual virtmap definition
          # maybe insert some checks here later
        }
      }
      else {  # dedicated env
        if (($g_form{$vkey} =~ /\@/) && ($g_form{$vkey} !~ /^\@/)) {
          # an e-mail address virtual virtmap definition
          # maybe insert some checks here later
        }
        elsif ($g_form{$vkey} =~ /^\@/) {
          # a hostname catch-all virtual virtmap definition
          # maybe insert some checks here later
        }
        elsif (($g_form{$vkey} =~ /\./) && ($g_form{$vkey} !~ /\@/)) {
          # domain name with no '@' sign... assume that it should be a 
          # catch-all and prepend an 'at' sign
          $g_form{$vkey} = "\@" . $g_form{$vkey};
        }
      }
      # real address checks
      if ($g_form{$rkey} =~ /\,/) {
        # simple check to make sure only one target address is entered
        ($g_form{$rkey}) = (split(/\,/, $g_form{$rkey}))[0];
      }
      if ($g_form{$rkey} =~ /\@/) {
        # remote real address
        # maybe insert some checks here later
      }
      else {
        # local real address or alias
        # maybe insert some checks here later
      }
    }
    if (keys(%errors)) {
      virtmapsDisplayForm($type, %errors);
    }
    if ($vcount == 0) {
      # nothing to do!
      virtmapsNoChangesExist($type);
    }
    # print out a confirm form if necessary
    $g_form{'confirm'} = "no" unless ($g_form{'confirm'});
    if ($g_form{'confirm'} ne "yes") {
      virtmapsConfirmChanges($type);
    }
  }
}

##############################################################################

sub virtmapsCommitChanges
{
  local($type) = @_;
  local($virtmap, @selectedvirtmaps, @virtmaplist, $vkey, $rkey, $pkey);
  local($success_mesg, $output);

  @selectedvirtmaps = split(/\|\|\|/, $g_form{'virtmaps'});
  foreach $virtmap (@selectedvirtmaps) {
    if (($type eq "add") || ($type eq "edit")) {
      $vkey = $virtmap . "_virtual";
      $rkey = $virtmap . "_real";
      if ($virtmap =~ /^__NEWVIRTMAP/) {
        $pkey = $virtmap . "_placement";
      }
      # next if new and left blank
      next if (($virtmap =~ /^__NEWVIRTMAP/) && (!$g_form{$vkey}) && (!$g_form{$rkey}));
      # next if no change was made (only applicable for type == edit)
      next if (($type eq "edit") &&
               ($g_form{$vkey} eq $g_virtmaps{$virtmap}->{'virtual'}) &&
               ($g_form{$rkey} eq $g_virtmaps{$virtmap}->{'real'}));
      if ((!$g_form{$vkey}) && (!$g_form{$rkey})) {
        # poor man's way of removing a virtmap, i.e. editing it and setting
        # its virtual or real address value to "" ...tag it for removal
        $g_virtmaps{$virtmap}->{'new_virtual'} = "__REMOVE";
      }
      else {
        $g_virtmaps{$virtmap}->{'new_virtual'} = $g_form{$vkey};
        $g_virtmaps{$virtmap}->{'new_real'} = $g_form{$rkey};
        $g_virtmaps{$virtmap}->{'placement'} = $g_form{$pkey};
      }
      push(@virtmaplist, $virtmap);
    }
    elsif ($type eq "remove") {
      $g_virtmaps{$virtmap}->{'new_virtual'} = "__REMOVE";
      push(@virtmaplist, $virtmap);
    }
  }
  $output = virtmapsSaveChanges(@virtmaplist);

  # now redirect back to iroot index and show success message
  if ($type eq "add") {
    $success_mesg = $VIRTMAPS_SUCCESS_ADD_TEXT;
  }
  elsif ($type eq "edit") {
    $success_mesg = $VIRTMAPS_SUCCESS_EDIT_TEXT;
  }
  elsif ($type eq "remove") {
    $success_mesg = $VIRTMAPS_SUCCESS_REMOVE_TEXT;
  }
  $success_mesg .= "\n$output" if ($output);
  redirectLocation("iroot.cgi", $success_mesg);
}

##############################################################################

sub virtmapsConfirmChanges
{
  local($type) = @_;
  local($subtitle, $title);
  local($virtmap, @selectedvirtmaps, $vkey, $rkey, $pkey, $entry);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("virtmaps");

  if ($type eq "add") {
    $subtitle = "$IROOT_ADD_TEXT: $CONFIRM_STRING";
  }
  elsif ($type eq "edit") {
    $subtitle = "$IROOT_EDIT_TEXT: $CONFIRM_STRING";
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_VIRTMAPS_TITLE: $subtitle";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlText($VIRTMAPS_CONFIRM_TEXT);
  htmlP();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "type", "value", $type);
  formInput("type", "hidden", "name", "confirm", "value", "yes");
  formInput("type", "hidden", "name", "virtmaps",
            "value", $g_form{'virtmaps'});
  htmlUL();
  @selectedvirtmaps = split(/\|\|\|/, $g_form{'virtmaps'});
  foreach $virtmap (@selectedvirtmaps) {
    $vkey = $virtmap . "_virtual";
    $rkey = $virtmap . "_real";
    $pkey = $virtmap . "_placement";
    # next if new and left blank
    next if (($virtmap =~ /^__NEWVIRTMAP/) && (!$g_form{$vkey}) && (!$g_form{$rkey}));
    # next if no change was made (only applicable for type == edit)
    next if (($type eq "edit") &&
             ($g_form{$vkey} eq $g_virtmaps{$virtmap}->{'virtual'}) &&
             ($g_form{$rkey} eq $g_virtmaps{$virtmap}->{'real'}));
    # print out the hidden fields
    formInput("type", "hidden", "name", $vkey, "value", $g_form{$vkey});
    formInput("type", "hidden", "name", $rkey, "value", $g_form{$rkey});
    if (defined($g_form{$pkey})) {
      formInput("type", "hidden", "name", $pkey, "value", $g_form{$pkey});
    }
    if ((!$g_form{$vkey}) && (!$g_form{$rkey})) {
      # poor man's way of removing a virtmap, i.e. editing it and
      # setting its value to "" ...confirm it's removal
      htmlListItem();
      htmlTextBold($VIRTMAPS_CONFIRM_REMOVE_OLD);
      htmlBR();
      htmlText("&#160;&#160;&#160;&#160;");
      htmlTextCode($g_virtmaps{$virtmap}->{'virtual'});
      htmlTextCode(" => ");
      htmlTextCode($g_virtmaps{$virtmap}->{'real'});
      htmlBR();
    }
    else {
      if ($virtmap =~ /^__NEWVIRTMAP/) {
        # confirm addition
        htmlListItem();
        htmlTextBold($VIRTMAPS_CONFIRM_ADD_NEW);
        htmlBR();
        htmlText("&#160;&#160;&#160;&#160;");
        htmlTextCode($g_form{$vkey});
        htmlTextCode(" => ");
        htmlTextCode($g_form{$rkey});
        htmlBR();
      }
      else {
        if ($g_form{$vkey} ne $g_virtmaps{$virtmap}->{'virtual'}) {
          # confirm name edit
          $entry = $VIRTMAPS_CONFIRM_CHANGE_NAME;
          $entry =~ s/__NAME__/$g_virtmaps{$virtmap}->{'virtual'}/;
          $entry =~ s/__NEWNAME__/$g_form{$vkey}/;
          htmlListItem();
          htmlTextBold($entry);
          htmlBR();
          if ($g_form{$rkey} eq $g_virtmaps{$virtmap}->{'real'}) {
            htmlTable("border", "0", "cellspacing", "0", "cellpadding", "0");
            htmlTableRow();
            htmlTableData();
            htmlNoBR();
            htmlText("&#160;&#160;&#160;&#160;");
            htmlText("$VIRTMAPS_CONFIRM_CHANGE_VALUE_OLD:");
            htmlText("&#160;&#160;");
            htmlNoBRClose();
            htmlTableDataClose();
            htmlTableData();
            htmlNoBR();
            htmlTextCode($g_virtmaps{$virtmap}->{'virtual'});
            htmlTextCode(" => ");
            htmlTextCode($g_virtmaps{$virtmap}->{'real'});
            htmlNoBRClose();
            htmlTableDataClose();
            htmlTableRowClose();
            htmlTableRow();
            htmlTableData();
            htmlNoBR();
            htmlText("&#160;&#160;&#160;&#160;");
            htmlText("$VIRTMAPS_CONFIRM_CHANGE_VALUE_NEW:");
            htmlText("&#160;&#160;");
            htmlNoBRClose();
            htmlTableDataClose();
            htmlTableData();
            htmlNoBR();
            htmlTextCode($g_form{$vkey});
            htmlTextCode(" => ");
            htmlTextCode($g_virtmaps{$virtmap}->{'real'});
            htmlNoBRClose();
            htmlTableDataClose();
            htmlTableRowClose();
            htmlTableClose();
          }
          htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
          htmlBR();
        }
        if ($g_form{$rkey} ne $g_virtmaps{$virtmap}->{'real'}) {
          $entry = $VIRTMAPS_CONFIRM_CHANGE_VALUE;
          if ($g_form{$vkey} ne $g_virtmaps{$virtmap}->{'virtual'}) {
            $entry =~ s/__NAME__/$g_form{$vkey}/;
          }
          else {
            $entry =~ s/__NAME__/$g_virtmaps{$virtmap}->{'virtual'}/;
          }
          htmlListItem();
          htmlTextBold($entry);
          htmlBR();
          htmlTable("border", "0", "cellspacing", "0", "cellpadding", "0");
          htmlTableRow();
          htmlTableData();
          htmlNoBR();
          htmlText("&#160;&#160;&#160;&#160;");
          htmlText("$VIRTMAPS_CONFIRM_CHANGE_VALUE_OLD:");
          htmlText("&#160;&#160;");
          htmlNoBRClose();
          htmlTableDataClose();
          htmlTableData();
          htmlNoBR();
          htmlTextCode($g_virtmaps{$virtmap}->{'virtual'});
          htmlTextCode(" => ");
          htmlTextCode($g_virtmaps{$virtmap}->{'real'});
          htmlNoBRClose();
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableRow();
          htmlTableData();
          htmlNoBR();
          htmlText("&#160;&#160;&#160;&#160;");
          htmlText("$VIRTMAPS_CONFIRM_CHANGE_VALUE_NEW:");
          htmlText("&#160;&#160;");
          htmlNoBRClose();
          htmlTableDataClose();
          htmlTableData();
          htmlNoBR();
          if ($g_form{$vkey} eq $g_virtmaps{$virtmap}->{'virtual'}) {
            htmlTextCode($g_virtmaps{$virtmap}->{'virtual'});
          }
          else {
            htmlTextCode($g_form{$vkey});
          }
          htmlTextCode(" => ");
          htmlTextCode($g_form{$rkey});
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

sub virtmapsDisplayForm
{
  local($type, %errors) = @_;
  local($title, $subtitle, $helptext, $buttontext, $mesg, $vmaplist);
  local(@selectedvirtmaps, $virtmap, $index, $singlevirtmap, $vmapoption);
  local($size25, $key, $value);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("virtmaps");

  if ($type eq "add") {
    $subtitle = $IROOT_ADD_TEXT;
    if ($g_form{'virtmaps'}) {
      @selectedvirtmaps = split(/\|\|\|/, $g_form{'virtmaps'});
    }
    else {
      for ($index=1; $index<=$g_prefs{'iroot__num_newvirtmaps'}; $index++) {
        push(@selectedvirtmaps, "__NEWVIRTMAP$index");
        $vmaplist .= "__NEWVIRTMAP$index\|\|\|";
      }
      $vmaplist =~ s/\|+$//g;
      $g_form{'virtmaps'} = $vmaplist;
    }
    $helptext = $VIRTMAPS_ADD_HELP_TEXT;
    $buttontext = $VIRTMAPS_ADD_SUBMIT_TEXT;
  } 
  elsif ($type eq "edit") {
    $subtitle = $IROOT_EDIT_TEXT;
    @selectedvirtmaps = split(/\|\|\|/, $g_form{'virtmaps'}) if ($g_form{'virtmaps'});
    $helptext = $VIRTMAPS_EDIT_HELP_TEXT;
    $buttontext = $VIRTMAPS_EDIT_SUBMIT_TEXT;
  } 
  elsif ($type eq "remove") {
    $subtitle = $IROOT_REMOVE_TEXT;
    @selectedvirtmaps = split(/\|\|\|/, $g_form{'virtmaps'}) if ($g_form{'virtmaps'});
    $helptext = $VIRTMAPS_REMOVE_HELP_TEXT;
    $buttontext = $VIRTMAPS_REMOVE_SUBMIT_TEXT;
  }
  elsif ($type eq "view") {
    $subtitle = $IROOT_VIEW_TEXT;
    foreach $virtmap (keys(%g_virtmaps)) {
      push(@selectedvirtmaps, $virtmap);
    }
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_VIRTMAPS_TITLE: $subtitle";

  if ($#selectedvirtmaps == -1) {
    # oops... no virtmaps in selected virtmap list.
    if (($type eq "edit") || ($type eq "remove")) {
      $singlevirtmap = virtmapsSelectForm($type);
      @selectedvirtmaps = ("$singlevirtmap");
    } 
    else {
      virtmapsEmptyFile();
    } 
  }
  else {
    # have selected virtmaps, are we re-sorting?
    if (($type eq "edit") || ($type eq "remove")) {
      virtmapsSelectForm($type) if ($g_form{'sort_select'});
    }
  }

  $size25 = formInputSize(25);

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
      htmlText($VIRTMAPS_OVERVIEW_HELP_TEXT);
      htmlP();
      htmlText($VIRTMAPS_EXAMPLES_HELP_TEXT_1);
      htmlP();
      htmlPre();
      htmlFont("class", "fixed", "face", "courier new, courier", "size", "2",
               "style", "font-family:courier new, courier; font-size:12px");
      if ($g_platform_type eq "virtual") {
        print "$VIRTMAPS_EXAMPLES_HELP_TEXT_2";
      }
      else {
        print "$VIRTMAPS_EXAMPLES_HELP_TEXT_2_DEDICATED";
      }
      htmlFontClose();
      htmlPreClose();
    }
  }
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "view", "value", $type);
  formInput("type", "hidden", "name", "virtmaps", 
            "value", $g_form{'virtmaps'});
  htmlTable();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "bottom");
  htmlTextBold($VIRTMAPS_VIRTUAL_EMAIL_ADDRESS);
  htmlTableDataClose();
  htmlTableData("valign", "bottom");
  htmlText("&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "bottom");
  htmlTextBold($VIRTMAPS_REAL_EMAIL_ADDRESS);
  htmlTableDataClose();
  if ($type eq "add") {
    # placement column
    htmlTableData("valign", "bottom");
    htmlTextBold($VIRTMAPS_VIRTMAP_PLACEMENT);
    htmlTableDataClose();
  }
  if (($type eq "add") || ($type eq "edit")) {
    # error column
    htmlTableData();
    htmlTableDataClose();
  }
  htmlTableRowClose();
  foreach $virtmap (sort virtmapsByPreference(@selectedvirtmaps)) {
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    if (($type eq "view") || ($type eq "remove")) {
      htmlTableData();
      htmlText($g_virtmaps{$virtmap}->{'virtual'});
      htmlTableDataClose();
      htmlTableData();
      htmlText("=>");
      htmlTableDataClose();
      htmlTableData();
      htmlText($g_virtmaps{$virtmap}->{'real'});
      htmlTableDataClose();
    }
    else {
      if ($#{$errors{$virtmap}} > -1) {
        htmlTableData("colspan", (($type eq "add") ? "4" : "3"));
        htmlTable("bgcolor", "#cc0000", "cellspacing", "1", "cellpadding", "0");
        htmlTableRow();
        htmlTableData();
        htmlTable("bgcolor", "#eeeeee");
        htmlTableRow();
      }
      htmlTableData("valign", "middle");
      $key = $virtmap . "_virtual";
      $value = (defined($g_form{'sort_submit'}) ||   
                defined($g_form{'submit'})) ? $g_form{$key} :
                                           $g_virtmaps{$virtmap}->{'virtual'};
      formInput("name", $key, "size", $size25, "value", $value);
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      htmlText("=>");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      $key = $virtmap . "_real";
      $value = (defined($g_form{'sort_submit'}) ||   
                defined($g_form{'submit'})) ? $g_form{$key} : 
                                              $g_virtmaps{$virtmap}->{'real'};
      formInput("name", $key, "size", $size25, "value", $value);
      htmlTableDataClose();
      if ($type eq "add") {
        # placement column
        htmlTableData("valign", "middle");
        $key = $virtmap . "_placement";
        formSelect("name", $key);
        formSelectOption("__APPEND", $VIRTMAPS_VIRTMAP_PLACEMENT_APPEND, 
                         ((!$g_form{$key}) || ($g_form{$key} eq "__APPEND")));
        foreach $vmapoption (sort virtmapsByPreference(keys(%g_virtmaps))) {
          next if ($vmapoption =~ /^__NEWVIRTMAP/);
          $value = $VIRTMAPS_VIRTMAP_PLACEMENT_INSERT;
          $value =~ s/__VIRTMAP__/$vmapoption/;
          formSelectOption($vmapoption, $value, 
                           (defined($g_form{$key}) && ($g_form{$key} eq $vmapoption)));
        }
        formSelectClose();
        htmlTableDataClose();
      }
      # error column
      if ($#{$errors{$virtmap}} > -1) {
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("colspan", (($type eq "add") ? "4" : "3"));
        foreach $mesg (@{$errors{$virtmap}}) {
          htmlTextColorBold(">>> $mesg <<<", "#cc0000");
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
  htmlTableData("colspan", "3");
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  if ($type eq "view") {
    if ($g_form{'sort_submit'} eq $VIRTMAPS_SORT_BY_NAME) {
      formInput("type", "submit", "name", "sort_submit", "value",
                $VIRTMAPS_SORT_BY_ORDER);
    } 
    else {
      formInput("type", "submit", "name", "sort_submit", "value",
                $VIRTMAPS_SORT_BY_NAME);
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

sub virtmapsEmptyFile
{
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlText($VIRTMAPS_NO_MAPPINGS_EXIST);
  htmlP();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub virtmapsLoad
{
  local($lcount, $curline, $name, $value, $whitespace, $len, $sindex);

  %g_virtmaps = ();
  $lcount = 1;
  if ($g_platform_type eq "virtual") {
    open(VFP, "/etc/virtmaps");
  }
  else {
    open(VFP, "/etc/mail/virtusertable");
  }
  while (<VFP>) {
    $curline = $_;
    next if ($curline =~ /^#/);
    $curline =~ s/^\s+//;
    $curline =~ s/\s+$//;
    next unless ($curline);
    $curline =~ s/(\s+)/ /g;
    $whitespace = $1;
    $whitespace =~ s/\t/\ \ \ \ \ \ \ \ /g;
    $sindex = index($curline, " ");
    $name = substr($curline, 0, $sindex);
    $value = substr($curline, $sindex+1);
    $g_virtmaps{$name}->{'virtual'} = $name;
    $g_virtmaps{$name}->{'real'} = $value;
    $g_virtmaps{$name}->{'order'} = $lcount;
    $len = length($name) + length($whitespace);
    # store left position; use this later to preserve original formatting
    $g_virtmaps{$name}->{'leftpos'} = $len;
    $g_lastleftpos = $len;
    $lcount++;
  }
  close(VFP);
}

##############################################################################

sub virtmapsNoChangesExist
{
  local($type) = @_;
  local($subtitle, $title);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("virtmaps");

  if ($type eq "add") {
    $subtitle = "$IROOT_ADD_TEXT";
  }
  elsif ($type eq "edit") {
    $subtitle = "$IROOT_EDIT_TEXT";
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_VIRTMAPS_TITLE: $subtitle";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlText($VIRTMAPS_NO_CHANGES_FOUND);
  htmlP();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub virtmapsRebuild
{
  local($output);

  $output = virtmapsRebuildDB();
  redirectLocation("iroot.cgi", $output);
}

##############################################################################

sub virtmapsRebuildDB
{
  local($tmpfile, $vcount, $output, $vdir, $vfile);

  encodingIncludeStringLibrary("iroot");

  if ($g_platform_type eq "virtual") {
    $vdir = "/etc";
    $vfile = "virtmaps";
  }
  else {
    $vdir = "/etc/mail";
    $vfile = "virtusertable";
  }

  unless (-e "$vdir/$vfile") {
    # create a empty (zero byte) file
    open(VMFP, ">$vdir/$vfile") ||
      irootResourceError($IROOT_VIRTMAPS_TITLE,
        "call to open(>$vdir/$vfile) in virtmapsRebuildDB");
    close(VMFP);
  }

  open(VMFP, "$vdir/$vfile") ||
      irootResourceError($IROOT_VIRTMAPS_TITLE,
        "call to open($vdir/$vfile) in virtmapsRebuildDB");
  $tmpfile = $g_tmpdir . "/.virtmaps-" . $g_curtime . "-" . $$;
  open(TMPFP, ">$tmpfile") ||
      irootResourceError($IROOT_VIRTMAPS_TITLE,
        "call to open(>$tmpfile) in virtmapsRebuildDB");
  $vcount = 0;
  while (<VMFP>) {
    $curline = $_;
    next if (($curline =~ /^#/) || ($curline eq "\n"));
    print TMPFP $curline;
    $vcount++;
  }
  close(VMFP);
  close(TMPFP);

  initPlatformLocalBin();
  open(MAP, "$g_localbin/makemap hash $vdir/$vfile.db < $tmpfile 2>&1 |") ||
      irootResourceError($IROOT_VIRTMAPS_TITLE,
        "call to open($g_localbin/makemap hash \
         $vdir/$vfile.db < $tmpfile) in virtmapsRebuildDB");
  $output = "";
  while (<MAP>) {
    s/^$g_localbin\/makemap://;
    $output .= $_;
  }
  close(MAP);
  unlink($tmpfile);

  # default output language from vnewvirtmaps is english... change this?
  unless ($output) {
    $output = "$vdir/$vfile: $vcount virtual user/host mappings\n";
  }
  return($output);
}

##############################################################################

sub virtmapsSaveChanges
{
  local(@virtmap_ids) = @_;
  local($virtmap, $newentry, %entries, $curentry, $match);
  local($entry_virtual, $entry_real, $numspaces, $output);
  local($locked, $lastchar, $vdir, $vfile);

  foreach $virtmap (@virtmap_ids) {
    # sift through the virtmap ids one by one
    if ($g_virtmaps{$virtmap}->{'new_virtual'} eq "__REMOVE") {
      # this is a subtle expectation in the code that may be missed.  set
      # the new virtual value for a virtmap to "__REMOVE" if you want to 
      # remove the virtmap from the virtmaps file.
      $entries{$virtmap} = "__REMOVE";
      next;
    }
    $entry_virtual = $g_virtmaps{$virtmap}->{'new_virtual'};
    $entry_real = $g_virtmaps{$virtmap}->{'new_real'};
    $newentry = $entry_virtual;
    if ($virtmap =~ /^__NEWVIRTMAP/) {
      # figure out how to line up the left hand column
      if ($g_virtmaps{$virtmap}->{'placement'} eq "__APPEND") {
        $g_virtmaps{$virtmap}->{'leftpos'} = $g_lastleftpos;
      }
      else {
        $g_virtmaps{$virtmap}->{'leftpos'} =
               $g_virtmaps{$g_virtmaps{$virtmap}->{'placement'}}->{'leftpos'};
      }
    }
    $numspaces = $g_virtmaps{$virtmap}->{'leftpos'} - length($newentry);
    $numspaces = 8 if ($numspaces <= 0);
    $newentry .= " " x $numspaces;
    $newentry .= $entry_real;
    $entries{$virtmap} = $newentry;
  }

  if ($g_platform_type eq "virtual") {
    $vdir = "/etc";
    $vfile = "virtmaps";
  }
  else {
    $vdir = "/etc/mail";
    $vfile = "virtusertable";
  }

  # add a newline character to the file if necessary
  if (-e "$vdir/$vfile") {
    open(OLDVMAPFP, "$vdir/$vfile") ||
      irootResourceError($IROOT_VIRTMAPS_TITLE,
          "open(OLDVMAPFP, '$vdir/$vfile') in virtmapsSaveChanges");
    seek(OLDVMAPFP, -1, 2);
    read(OLDVMAPFP, $lastchar, 1);
    close(OLDVMAPFP);
    if ($lastchar ne "\n") {
      open(OLDVMAPFP, ">>$vdir/$vfile") ||
        irootResourceError($IROOT_VIRTMAPS_TITLE,
            "open(OLDVMAPFP, '>>$vdir/$vfile') in virtmapsSaveChanges");
      print OLDVMAPFP "\n";
      close(OLDVMAPFP);
    }
  }

  # backup old file
  require "$g_includelib/backup.pl";
  backupSystemFile("$vdir/$vfile");

  # write out new virtmaps file
  # first check for a lock file
  if (-f "$vdir/vmaptmptmp$$.$g_curtime") {
    irootResourceError($IROOT_VIRTMAPS_TITLE,
        "-f '$vdir/vmaptmptmp$$.$g_curtime' returned 1 in virtmapsSaveChanges");
  }
  # no obvious lock... use link() for atomicity to avoid race conditions
  open(VTMP, ">$vdir/vmaptmptmp$$.$g_curtime") ||
    irootResourceError($IROOT_VIRTMAPS_TITLE,
        "open(VTMP, '>$vdir/vmaptmptmp$$.$g_curtime') in virtmapsSaveChanges");
  close(VTMP);
  $locked = link("$vdir/vmaptmptmp$$.$g_curtime", "$vdir/vmaptmp");
  unlink("$vdir/vmaptmptmp$$.$g_curtime");
  $locked || irootResourceError($IROOT_VIRTMAPS_TITLE,
     "link('$vdir/vmaptmptmp$$.$g_curtime', '$vdir/vmaptmp') \
      failed in virtmapsSaveChanges");
  open(NEWVMAPFP, ">$vdir/vmaptmp")  ||
    irootResourceError($IROOT_VIRTMAPS_TITLE,
        "open(NEWVMAPFP, '>$vdir/vmaptmp') in virtmapsSaveChanges");
  flock(NEWVMAPFP, 2);  # exclusive lock
  open(OLDVMAPFP, "$vdir/$vfile");
  while (<OLDVMAPFP>) {
    $curentry = $_;
    # print out curentry, replace, or ignore?
    $match = 0;
    foreach $virtmap (@virtmap_ids) {
      if ($curentry =~ /^$virtmap\s/) {
        $match = 1;
        # we have a match, replace or ignore?
        if ($entries{$virtmap} eq "__REMOVE") {
          # ignore
        }
        else {
          # replace
          print NEWVMAPFP "$entries{$virtmap}\n" ||
            irootResourceError($IROOT_VIRTMAPS_TITLE,
              "print to NEWVMAPFP failed -- server quota exceeded?");
        }
        delete($entries{$virtmap});
      }
    }
    if ($match == 0) {
      print NEWVMAPFP "$curentry" ||
        irootResourceError($IROOT_VIRTMAPS_TITLE,
          "print to NEWVMAPFP failed -- server quota exceeded?");
    }
    # append any new virtmaps after current entry if applicable
    foreach $virtmap (@virtmap_ids) {
      next unless ($virtmap =~ /^__NEWVIRTMAP/);
      if ($curentry =~ /^$g_virtmaps{$virtmap}->{'placement'}\s/) {
        print NEWVMAPFP "$entries{$virtmap}\n" ||
          irootResourceError($IROOT_VIRTMAPS_TITLE,
            "print to NEWVMAPFP failed -- server quota exceeded?");
        delete($entries{$virtmap});
      }
    }
  } 
  close(OLDVMAPFP);
  # append new entries
  foreach $entry (keys(%entries)) {
    next if ($entries{$entry} eq "__REMOVE");
    print NEWVMAPFP "$entries{$entry}\n" ||
      irootResourceError($IROOT_VIRTMAPS_TITLE,
        "print to NEWVMAPFP failed -- server quota exceeded?");
  } 
  flock(NEWVMAPFP, 8);  # unlock
  close(NEWVMAPFP);
  rename("$vdir/vmaptmp", "$vdir/$vfile") ||
     irootResourceError($IROOT_VIRTMAPS_TITLE, 
       "rename('$vdir/vmaptmp', '$vdir/$vfile') in virtmapsSaveChanges");
  chmod(0644, "$vdir/$vfile");
  
  # rebuild the virtmaps db file
  $output = virtmapsRebuildDB();
  return($output);
}

##############################################################################

sub virtmapsSelectForm
{
  local($type) = @_;
  local($title, $subtitle, $virtmap, $vcount, $optiontxt);
  local(@selectedvirtmaps, $svirtmap, $selected);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("virtmaps");

  $subtitle = "$IROOT_VIRTMAPS_TITLE: ";
  if ($type eq "edit") {
    $subtitle .= "$IROOT_EDIT_TEXT: $VIRTMAPS_SELECT_TITLE";;
  }
  elsif ($type eq "remove") {
    $subtitle .= "$IROOT_REMOVE_TEXT: $VIRTMAPS_SELECT_TITLE";;
  }

  $title = "$IROOT_MAINMENU_TITLE: $subtitle";

  # first check and see if there are more than one virtmap to select
  $vcount = 0;
  foreach $virtmap (keys(%g_virtmaps)) {
    $vcount++;
  }
  if ($vcount == 0) {
    # oops.  no virtmap definitions in virtmaps file.
    virtmapsEmptyFile();
  }
  elsif ($vcount == 1) {
    $g_form{'virtmaps'} = (keys(%g_virtmaps))[0]; 
    return($g_form{'virtmaps'});
  }

  @selectedvirtmaps = split(/\|\|\|/, $g_form{'virtmaps'}) if ($g_form{'virtmaps'});

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTextLargeBold($subtitle);
  htmlBR();
  if ($g_form{'select_submit'} &&
      ($g_form{'select_submit'} eq $VIRTMAPS_SELECT_TITLE)) {
    htmlBR();
    htmlTextColorBold(">>> $VIRTMAPS_SELECT_HELP <<<", "#cc0000");
  }
  else {
    htmlText($VIRTMAPS_SELECT_HELP);
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
  formSelect("name", "virtmaps", "size", formSelectRows($vcount),
             "_OTHER_", "MULTIPLE", "_FONT_", "fixed");
  $g_form{'sort_submit'} = $g_form{'sort_select'};  # for sort subroutine
  foreach $virtmap (sort virtmapsByPreference(keys(%g_virtmaps))) {
    $selected = 0;
    foreach $svirtmap (@selectedvirtmaps) {
      if ($svirtmap eq $virtmap) {
        $selected = 1;
        last;
      }
    }
    $optiontxt = "$g_virtmaps{$virtmap}->{'virtual'} => ";
    $optiontxt .= "$g_virtmaps{$virtmap}->{'real'}";
    if (length($optiontxt) > 70) {
      $optiontxt = substr($optiontxt, 0, 70) . "&#133;";
    }
    formSelectOption($virtmap, $optiontxt, $selected);
  }
  formSelectClose();
  htmlTableDataClose();
  htmlTableData("valign", "top");
  if ((!$g_form{'sort_select'}) ||
      ($g_form{'sort_select'} eq $VIRTMAPS_SORT_BY_ORDER)) {
    formInput("type", "submit", "name", "sort_select", "value",
              $VIRTMAPS_SORT_BY_NAME);
  }
  else {
    formInput("type", "submit", "name", "sort_select", "value",
              $VIRTMAPS_SORT_BY_ORDER);
  }
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("colspan", "2");
  formInput("type", "submit", "name", "select_submit",
            "value", $VIRTMAPS_SELECT_TITLE);
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

