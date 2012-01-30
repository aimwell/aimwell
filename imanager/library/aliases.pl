#
# aliases.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/aliases.pl,v 2.12.2.4 2006/04/25 19:48:22 rus Exp $
#
# add/edit/remove/view aliases functions
#

##############################################################################

sub aliasesByPreference
{
  if (($a =~ /^__NEWALIAS/) || ($b =~ /^__NEWALIAS/)) {
    return($a cmp $b);
  }

  if ($g_form{'sort_submit'} &&
      ($g_form{'sort_submit'} eq $ALIASES_SORT_BY_ORDER)) {
    return($g_aliases{$a}->{'order'} <=> $g_aliases{$b}->{'order'});
  }
  else {
    # default... by name
    return($a cmp $b);
  }
}

##############################################################################

sub aliasesCheckFormValidity
{
  local($type) = @_;
  local($mesg, $alias, @selectedaliases, $acount, $nkey, $vkey);
  local($errmsg, %errors, %newaliases);

  encodingIncludeStringLibrary("aliases");

  if (($g_form{'submit'} && ($g_form{'submit'} eq "$CANCEL_STRING")) ||
      ($g_form{'select_submit'} && ($g_form{'select_submit'} eq "$CANCEL_STRING"))) {
    if ($type eq "add") {
      $mesg = $ALIASES_CANCEL_ADD_TEXT;
    }
    elsif ($type eq "edit") {
      $mesg = $ALIASES_CANCEL_EDIT_TEXT;
    }
    elsif ($type eq "remove") {
      $mesg = $ALIASES_CANCEL_REMOVE_TEXT;
    }
    redirectLocation("iroot.cgi", $mesg);
  }

  # perform error checking on form data
  if (($type eq "add") || ($type eq "edit")) {
    $acount = 0;
    %errors = %newaliases = ();
    @selectedaliases = split(/\|\|\|/, $g_form{'aliases'});
    foreach $alias (@selectedaliases) {
      $nkey = $alias . "_name";
      $vkey = $alias . "_value";
      # next if new and left blank
      next if (($alias =~ /^__NEWALIAS/) && (!$g_form{$nkey}) && (!$g_form{$vkey}));
      # next if no change was made (only applicable for type == edit)
      if (($type eq "edit") &&
          ($g_form{$nkey} eq $g_aliases{$alias}->{'name'}) &&
          ($g_form{$vkey} eq $g_aliases{$alias}->{'value'})) {
        $g_form{'aliases'} =~ s/^\Q$alias\E$//;
        $g_form{'aliases'} =~ s/^\Q$alias\E\|\|\|//;
        $g_form{'aliases'} =~ s/\|\|\|\Q$alias\E\|\|\|/\|\|\|/;
        $g_form{'aliases'} =~ s/\|\|\|\Q$alias\E$//;
        next;
      }
      $acount++;
      # check to see if both name and value are specified (if one is
      # specified, then require both ... if neither are specified, then
      # assume removal is wanted
      if ((!$g_form{$nkey}) && $g_form{$vkey}) {
        push(@{$errors{$alias}}, $ALIASES_ERROR_NAME_FIELD_IS_BLANK);
      }
      if ($g_form{$nkey} && (!$g_form{$vkey})) {
        push(@{$errors{$alias}}, $ALIASES_ERROR_VALUE_FIELD_IS_BLANK);
      }
      # alias name checks
      if (($type eq "add") && (defined($g_aliases{$g_form{$nkey}}))) {
        # no duplicates allowed
        $errmsg = $ALIASES_ERROR_DUPLICATE_ADDITION;
        $errmsg =~ s/__ALIAS__/$g_form{$nkey}/;
        push(@{$errors{$alias}}, $errmsg);
      }
      if (defined($newaliases{$g_form{$nkey}})) {
        $errmsg = $ALIASES_ERROR_NAME_REPEATED;
        $errmsg =~ s/__ALIAS__/$g_form{$nkey}/;
        push(@{$errors{$alias}}, $errmsg);
      }
      if (($g_form{$nkey} =~ /\@/) || ($g_form{$nkey} =~ /\:/)) {
        $errmsg = $ALIASES_ERROR_NAME_INVALID_CHARS;
        $errmsg =~ s/__ALIAS__/$g_form{$nkey}/;
        push(@{$errors{$alias}}, $errmsg);
      }
      $newaliases{$g_form{$nkey}} = "dau!";
      # alias value checks
      # maybe insert some checks here later
    }
    if (keys(%errors)) {
      aliasesDisplayForm($type, %errors);
    }
    if ($acount == 0) {
      # nothing to do!
      aliasesNoChangesExist($type);
    }
    # print out a confirm form if necessary
    $g_form{'confirm'} = "no" unless ($g_form{'confirm'});
    if ($g_form{'confirm'} ne "yes") {
      aliasesConfirmChanges($type);
    }
  }
}

##############################################################################

sub aliasesCommitChanges
{
  local($type) = @_;
  local($alias, @selectedaliases, @aliaslist, $nkey, $vkey, $pkey);
  local($success_mesg, $output);

  @selectedaliases = split(/\|\|\|/, $g_form{'aliases'});
  foreach $alias (@selectedaliases) {
    if (($type eq "add") || ($type eq "edit")) {
      $nkey = $alias . "_name";
      $vkey = $alias . "_value";
      if ($alias =~ /^__NEWALIAS/) {
        $pkey = $alias . "_placement";
      }
      # next if new and left blank
      next if (($alias =~ /^__NEWALIAS/) && (!$g_form{$nkey}) && (!$g_form{$vkey}));
      # next if no change was made (only applicable for type == edit)
      next if (($type eq "edit") &&
               ($g_form{$nkey} eq $g_aliases{$alias}->{'name'}) &&
               ($g_form{$vkey} eq $g_aliases{$alias}->{'value'}));
      if ((!$g_form{$nkey}) && (!$g_form{$vkey})) {
        # poor man's way of removing an alias, i.e. editing it and setting
        # its name and value to "" ...tag it for removal
        $g_aliases{$alias}->{'new_name'} = "__REMOVE";
      }
      else {
        $g_aliases{$alias}->{'new_name'} = $g_form{$nkey};
        $g_aliases{$alias}->{'new_value'} = $g_form{$vkey};
        if ($alias =~ /^__NEWALIAS/) {
          $g_aliases{$alias}->{'placement'} = $g_form{$pkey};
        }
      }
      push(@aliaslist, $alias);
    }
    elsif ($type eq "remove") {
      $g_aliases{$alias}->{'new_name'} = "__REMOVE";
      push(@aliaslist, $alias);
    }
  }
  $output = aliasesSaveChanges(@aliaslist);

  # now redirect back to iroot index and show success message
  if ($type eq "add") {
    $success_mesg = $ALIASES_SUCCESS_ADD_TEXT;
  }
  elsif ($type eq "edit") {
    $success_mesg = $ALIASES_SUCCESS_EDIT_TEXT;
  }
  elsif ($type eq "remove") {
    $success_mesg = $ALIASES_SUCCESS_REMOVE_TEXT;
  }
  $success_mesg .= "\n$output" if ($output);
  redirectLocation("iroot.cgi", $success_mesg);
}

##############################################################################

sub aliasesConfirmChanges
{
  local($type) = @_;
  local($subtitle, $title);
  local($alias, @selectedaliases, $nkey, $vkey, $pkey, $entry);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("aliases");

  if ($type eq "add") {
    $subtitle = "$IROOT_ADD_TEXT: $CONFIRM_STRING";
  }
  elsif ($type eq "edit") {
    $subtitle = "$IROOT_EDIT_TEXT: $CONFIRM_STRING";
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_ALIASES_TITLE: $subtitle";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlText($ALIASES_CONFIRM_TEXT);
  htmlP();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "type", "value", $type);
  formInput("type", "hidden", "name", "confirm", "value", "yes");
  formInput("type", "hidden", "name", "aliases",
            "value", $g_form{'aliases'});
  htmlUL();
  @selectedaliases = split(/\|\|\|/, $g_form{'aliases'});
  foreach $alias (@selectedaliases) {
    $nkey = $alias . "_name";
    $vkey = $alias . "_value";
    $pkey = $alias . "_placement";
    # next if new and left blank
    next if (($alias =~ /^__NEWALIAS/) && (!$g_form{$nkey}) && (!$g_form{$vkey}));
    # next if no change was made (only applicable for type == edit)
    next if (($type eq "edit") &&
             ($g_form{$nkey} eq $g_aliases{$alias}->{'name'}) &&
             ($g_form{$vkey} eq $g_aliases{$alias}->{'value'}));
    # print out the hidden fields
    formInput("type", "hidden", "name", $nkey, "value", $g_form{$nkey});
    formInput("type", "hidden", "name", $vkey, "value", $g_form{$vkey});
    if (defined($g_form{$pkey})) {
      formInput("type", "hidden", "name", $pkey, "value", $g_form{$pkey});
    }
    if ((!$g_form{$nkey}) && (!$g_form{$vkey})) {
      # poor man's way of removing an alias, i.e. editing it and
      # setting its value to "" ...confirm it's removal
      htmlListItem();
      htmlTextBold($ALIASES_CONFIRM_REMOVE_OLD);
      htmlBR();
      htmlText("&#160;&#160;&#160;&#160;");
      htmlTextCode($g_aliases{$alias}->{'name'});
      htmlTextCode(" => ");
      htmlTextCode($g_aliases{$alias}->{'value'});
      htmlBR();
    }
    else {
      if ($alias =~ /^__NEWALIAS/) {
        # confirm addition
        htmlListItem();
        htmlTextBold($ALIASES_CONFIRM_ADD_NEW);
        htmlBR();
        htmlText("&#160;&#160;&#160;&#160;");
        htmlTextCode($g_form{$nkey});
        htmlTextCode(" => ");
        htmlTextCode($g_form{$vkey});
        htmlBR();
      }
      else {
        if ($g_form{$nkey} ne $g_aliases{$alias}->{'name'}) {
          # confirm name edit
          $entry = $ALIASES_CONFIRM_CHANGE_NAME;
          $entry =~ s/__NAME__/$g_aliases{$alias}->{'name'}/;
          $entry =~ s/__NEWNAME__/$g_form{$nkey}/;
          htmlListItem();
          htmlTextBold($entry);
          htmlBR();
          if ($g_form{$vkey} eq $g_aliases{$alias}->{'value'}) {
            htmlTable("border", "0", "cellspacing", "0", "cellpadding", "0");
            htmlTableRow();
            htmlTableData();
            htmlNoBR();
            htmlText("&#160;&#160;&#160;&#160;");
            htmlText("$ALIASES_CONFIRM_CHANGE_VALUE_OLD:");
            htmlText("&#160;&#160;");
            htmlNoBRClose();
            htmlTableDataClose();
            htmlTableData();
            htmlNoBR();
            htmlTextCode($g_aliases{$alias}->{'name'});
            htmlTextCode(" => ");
            htmlTextCode($g_aliases{$alias}->{'value'});
            htmlNoBRClose();
            htmlTableDataClose();
            htmlTableRowClose();
            htmlTableRow();
            htmlTableData();
            htmlNoBR();
            htmlText("&#160;&#160;&#160;&#160;");
            htmlText("$ALIASES_CONFIRM_CHANGE_VALUE_NEW:");
            htmlText("&#160;&#160;");
            htmlNoBRClose();
            htmlTableDataClose();
            htmlTableData();
            htmlNoBR();
            htmlTextCode($g_form{$nkey});
            htmlTextCode(" => ");
            htmlTextCode($g_aliases{$alias}->{'value'});
            htmlNoBRClose();
            htmlTableDataClose();
            htmlTableRowClose();
            htmlTableClose();
          }
          htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
          htmlBR();
        }
        if ($g_form{$vkey} ne $g_aliases{$alias}->{'value'}) {
          $entry = $ALIASES_CONFIRM_CHANGE_VALUE;
          if ($g_form{$nkey} ne $g_aliases{$alias}->{'name'}) {
            $entry =~ s/__NAME__/$g_form{$nkey}/;
          }
          else {
            $entry =~ s/__NAME__/$g_aliases{$alias}->{'name'}/;
          }
          htmlListItem();
          htmlTextBold($entry);
          htmlBR();
          htmlTable("border", "0", "cellspacing", "0", "cellpadding", "0");
          htmlTableRow();
          htmlTableData();
          htmlNoBR();
          htmlText("&#160;&#160;&#160;&#160;");
          htmlText("$ALIASES_CONFIRM_CHANGE_VALUE_OLD:");
          htmlText("&#160;&#160;");
          htmlNoBRClose();
          htmlTableDataClose();
          htmlTableData();
          htmlNoBR();
          htmlTextCode($g_aliases{$alias}->{'name'});
          htmlTextCode(" => ");
          htmlTextCode($g_aliases{$alias}->{'value'});
          htmlNoBRClose();
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableRow();
          htmlTableData();
          htmlNoBR();
          htmlText("&#160;&#160;&#160;&#160;");
          htmlText("$ALIASES_CONFIRM_CHANGE_VALUE_NEW:");
          htmlText("&#160;&#160;");
          htmlNoBRClose();
          htmlTableDataClose();
          htmlTableData();
          htmlNoBR();
          if ($g_form{$nkey} eq $g_aliases{$alias}->{'name'}) {
            htmlTextCode($g_aliases{$alias}->{'name'});
          }
          else {
            htmlTextCode($g_form{$nkey});
          }
          htmlTextCode(" => ");
          htmlTextCode($g_form{$vkey});
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

sub aliasesDisplayForm
{
  local($type, %errors) = @_;
  local($title, $subtitle, $helptext, $buttontext, $mesg, $aliaslist);
  local(@selectedaliases, $alias, $index, $singlealias, $aliasoption);
  local($size20, $size40, $key, $value);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("aliases");

  if ($type eq "add") {
    $subtitle = $IROOT_ADD_TEXT;
    if ($g_form{'aliases'}) {
      @selectedaliases = split(/\|\|\|/, $g_form{'aliases'});
    }
    else {
      for ($index=1; $index<=$g_prefs{'iroot__num_newaliases'}; $index++) {
        push(@selectedaliases, "__NEWALIAS$index");
        $aliaslist .= "__NEWALIAS$index\|\|\|";
      }
      $aliaslist =~ s/\|+$//g;
      $g_form{'aliases'} = $aliaslist;
    }
    $helptext = $ALIASES_ADD_HELP_TEXT;
    $buttontext = $ALIASES_ADD_SUBMIT_TEXT;
  }
  elsif ($type eq "edit") {
    $subtitle = $IROOT_EDIT_TEXT;
    @selectedaliases = split(/\|\|\|/, $g_form{'aliases'}) if ($g_form{'aliases'});
    $helptext = $ALIASES_EDIT_HELP_TEXT;
    $buttontext = $ALIASES_EDIT_SUBMIT_TEXT;
  }
  elsif ($type eq "remove") {
    $subtitle = $IROOT_REMOVE_TEXT;
    @selectedaliases = split(/\|\|\|/, $g_form{'aliases'}) if ($g_form{'aliases'});
    $helptext = $ALIASES_REMOVE_HELP_TEXT;
    $buttontext = $ALIASES_REMOVE_SUBMIT_TEXT;
  }
  elsif ($type eq "view") {
    $subtitle = $IROOT_VIEW_TEXT;
    foreach $alias (keys(%g_aliases)) {
      push(@selectedaliases, $alias);
    }
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_ALIASES_TITLE: $subtitle";

  if ($#selectedaliases == -1) {
    # oops... no aliases in selected alias list.
    if (($type eq "edit") || ($type eq "remove")) {
      $singlealias = aliasesSelectForm($type);
      @selectedaliases = ("$singlealias");
    }
    else {
      aliasesEmptyFile();
    }
  }
  else {
    # have selected aliases, are we re-sorting?
    if (($type eq "edit") || ($type eq "remove")) {
      aliasesSelectForm($type) if ($g_form{'sort_select'});
    }
  }

  $size20 = formInputSize(20);
  $size40 = formInputSize(40);

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
      htmlText($ALIASES_OVERVIEW_HELP_TEXT);
      htmlP();
      htmlText($ALIASES_EXAMPLES_HELP_TEXT_1);
      htmlP();
      htmlPre();
      htmlFont("class", "fixed", "face", "courier new, courier", "size", "2",
               "style", "font-family:courier new, courier; font-size:12px");
      print "$ALIASES_EXAMPLES_HELP_TEXT_2";
      htmlFontClose();
      htmlPreClose();
    }
  }
  formOpen("name", "aliasesForm", "method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "view", "value", $type);
  formInput("type", "hidden", "name", "aliases",
            "value", $g_form{'aliases'});
  htmlTable();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "bottom");
  htmlTextBold($ALIASES_ALIAS_NAME);
  htmlTableDataClose();
  htmlTableData("valign", "bottom");
  htmlText("&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "bottom");
  htmlTextBold($ALIASES_ALIAS_VALUE);
  htmlTableDataClose();
  if ($type eq "add") {
    # placement column
    htmlTableData("valign", "bottom");
    htmlTextBold($ALIASES_ALIAS_PLACEMENT);
    htmlTableDataClose();
  }
  if (($type eq "add") || ($type eq "edit")) {
    # error column
    htmlTableData();
    htmlTableDataClose();
  }
  htmlTableRowClose();
  foreach $alias (sort aliasesByPreference(@selectedaliases)) {
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    if (($type eq "view") || ($type eq "remove")) {
      htmlTableData();
      htmlText($g_aliases{$alias}->{'name'});
      htmlTableDataClose();
      htmlTableData();
      htmlText("=>");
      htmlTableDataClose();
      htmlTableData();
      htmlText($g_aliases{$alias}->{'value'});
      htmlTableDataClose();
    }
    else {
      if ($#{$errors{$alias}} > -1) {
        htmlTableData("colspan", (($type eq "add") ? "4" : "3"));
        htmlTable("bgcolor", "#cc0000", "cellspacing", "1", "cellpadding", "0");
        htmlTableRow();
        htmlTableData();
        htmlTable("bgcolor", "#eeeeee");
        htmlTableRow();
      }
      htmlTableData("valign", "middle");
      $key = $alias . "_name";
      $value = (defined($g_form{'sort_submit'}) ||   
                defined($g_form{'submit'})) ? $g_form{$key} :
                                              $g_aliases{$alias}->{'name'};
      formInput("name", $key, "size", $size20, "value", $value);
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      htmlText("=>");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      $key = $alias . "_value";
      $value = (defined($g_form{'sort_submit'}) ||   
                defined($g_form{'submit'})) ? $g_form{$key} :
                                              $g_aliases{$alias}->{'value'};
      formInput("name", $key, "size", $size40, "value", $value);
      htmlTableDataClose();
      if ($type eq "add") {
        # placement column
        htmlTableData("valign", "middle");
        $key = $alias . "_placement";
        formSelect("name", $key);
        formSelectOption("__APPEND", $ALIASES_ALIAS_PLACEMENT_APPEND, 
                         ((!$g_form{$key}) || ($g_form{$key} eq "__APPEND")));
        foreach $aliasoption (sort aliasesByPreference(keys(%g_aliases))) {
          next if ($aliasoption =~ /^__NEWALIAS/);
          $value = $ALIASES_ALIAS_PLACEMENT_INSERT;
          $value =~ s/__ALIAS__/$aliasoption/;
          formSelectOption($aliasoption, $value, 
                           (defined($g_form{$key}) && ($g_form{$key} eq $aliasoption)));
        }
        formSelectClose();
        htmlTableDataClose();
      }
      # error column
      if ($#{$errors{$alias}} > -1) {
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("colspan", (($type eq "add") ? "4" : "3"));  
        foreach $mesg (@{$errors{$alias}}) {
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
    if ($g_form{'sort_submit'} &&
        ($g_form{'sort_submit'} eq $ALIASES_SORT_BY_ORDER)) {
      formInput("type", "submit", "name", "sort_submit", "value", 
                $ALIASES_SORT_BY_NAME);
    }
    else {
      formInput("type", "submit", "name", "sort_submit", "value", 
                $ALIASES_SORT_BY_ORDER);
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

sub aliasesEmptyFile
{
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlText($ALIASES_NO_MAPPINGS_EXIST);
  htmlP();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub aliasesLoad
{
  local($lcount, $curline, $name, $value);
  local($whitespace, $len, $fci, $args, $prevkey);

  %g_aliases = ();
  $lcount = 1;
  $prevkey = "";
  if ($g_platform_type eq "virtual") {
    open(VFP, "/etc/aliases");
  }
  else {
    open(VFP, "/etc/mail/aliases");
  }
  while (<VFP>) {
    $curline = $_;
    next if ($curline =~ /^#/);
    $curline =~ s/\s+$//;
    next unless ($curline);
    if ($curline =~ /^\s/) {
      # continuation line begins with a space; append to previous alias 
      next unless ($prevkey);
      $curline =~ s/^\s+//;
      $g_aliases{$prevkey}->{'value'} .= " $curline";
    }
    else {
      $fci = index($curline, ":");
      $name = substr($curline, 0, $fci);
      $value = substr($curline, $fci+1);
      $name =~ s/\s+$//;
      $value =~ s/(^\s+)//;
      $whitespace = $1;
      $whitespace =~ s/\t/\ \ \ \ \ \ \ \ /g;
      $g_aliases{$name}->{'name'} = $name;
      $g_aliases{$name}->{'value'} = $value;
      $g_aliases{$name}->{'order'} = $lcount;
      $len = length($name) + length($whitespace) + 1;  # plus 1 for the colon
      # store left position; use this later to preserve original formatting
      $g_aliases{$name}->{'leftpos'} = $len;
      $g_lastleftpos = $len;
      $lcount++;
      $prevkey = $name;
    }
  }
  close(VFP);
 
  # loop through each alias and attempt to determine the alias type from 
  # recognizable patterns 
  foreach $name (keys(%g_aliases)) {
    $value = $g_aliases{$name}->{'value'};
    if ($value =~ /^:include:([A-Za-z0-9_\-\.\/])$/) {
      $g_aliases{$name}->{'list'} = $1;
      $g_aliases{$name}->{'type'} = "include";
    }
    elsif ($value =~ /(.*)\,\ \"\|\/usr\/bin\/autoreply (.*)\"$/) {
      $g_aliases{$name}->{'other_addresses'} = $1;
      $args = $2;
      if ($args =~ /\-f\ (\w*)\ /) {
        $g_aliases{$name}->{'from'} = $1;
      }
      if ($args =~ /\-m\ (\w*)\ /) {
        $g_aliases{$name}->{'message'} = $1;
      }
      if ($args =~ /\-a\ (\w*)\ /) {
        $g_aliases{$name}->{'address'} = $1;
      }
      $g_aliases{$name}->{'type'} = "autoreply";
    }
    else {
      $g_aliases{$name}->{'type'} = "simple";
    }
  }
}

##############################################################################

sub aliasesNoChangesExist
{
  local($type) = @_;
  local($subtitle, $title);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("aliases");

  if ($type eq "add") {
    $subtitle = "$IROOT_ADD_TEXT";
  }
  elsif ($type eq "edit") {
    $subtitle = "$IROOT_EDIT_TEXT";
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_ALIASES_TITLE: $subtitle";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlText($ALIASES_NO_CHANGES_FOUND);
  htmlP();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub aliasesRebuild
{
  local($output);

  $output = aliasesRebuildDB();
  redirectLocation("iroot.cgi", $output);
}

##############################################################################

sub aliasesRebuildDB
{
  local($output);

  encodingIncludeStringLibrary("iroot");

  open(SMFP, "/usr/sbin/sendmail -bi 2>&1 |") ||
      irootResourceError($IROOT_ALIASES_TITLE,
          "call to open(SMFP, /usr/sbin/sendmail -bi) in aliasesRebuildDB");
  $output = "";
  while (<SMFP>) {
    $output .= $_;
  }
  close(SMFP);

  # default output language from sendmail is english... change this?
  return($output);
}

##############################################################################

sub aliasesSaveChanges
{
  local(@alias_ids) = @_;
  local($alias, $newentry, %entries, $curentry, $match);
  local($entry_name, $entry_value, $numspaces, $output);
  local($locked, $lastchar, $adir, $afile);

  foreach $alias (@alias_ids) {
    # sift through the alias ids one by one
    if ($g_aliases{$alias}->{'new_name'} eq "__REMOVE") {
      # this is a subtle expectation in the code that may be missed.  set
      # the new name value for an alias to "__REMOVE" if you want to
      # remove the alias from the aliases file.
      $entries{$alias} = "__REMOVE";
      next;
    }
    $entry_name = $g_aliases{$alias}->{'new_name'};
    $entry_value = $g_aliases{$alias}->{'new_value'};
    $newentry = $entry_name . ":";
    if ($alias =~ /^__NEWALIAS/) {
      # figure out how to line up the left hand column
      if ($g_aliases{$alias}->{'placement'} eq "__APPEND") {
        $g_aliases{$alias}->{'leftpos'} = $g_lastleftpos;
      }
      else {
        $g_aliases{$alias}->{'leftpos'} = 
               $g_aliases{$g_aliases{$alias}->{'placement'}}->{'leftpos'};
      }
    }
    $numspaces = $g_aliases{$alias}->{'leftpos'} - length($newentry);
    $numspaces = 8 if ($numspaces <= 0);
    $newentry .= " " x $numspaces;
    $newentry .= $entry_value;
    $entries{$alias} = $newentry;
  }

  if ($g_platform_type eq "virtual") {
    $adir = "/etc";
  }
  else {
    $adir = "/etc/mail";
  }
  $afile = "aliases";

  # add a newline character to the file if necessary
  if (-e "$adir/$afile") {
    open(OLDALIASFP, "$adir/$afile") ||
      irootResourceError($IROOT_ALIASES_TITLE,
          "open(OLDALIASFP, '$adir/$afile') in aliasesSaveChanges");
    seek(OLDALIASFP, -1, 2);
    read(OLDALIASFP, $lastchar, 1);
    close(OLDALIASFP);
    if ($lastchar ne "\n") {
      open(OLDALIASFP, ">>$adir/$afile") ||
        irootResourceError($IROOT_ALIASES_TITLE,
            "open(OLDALIASFP, '>>$adir/$afile') in aliasesSaveChanges");
      print OLDALIASFP "\n";
      close(OLDALIASFP);
    }
  }

  # backup old file
  require "$g_includelib/backup.pl";
  backupSystemFile("$adir/$afile");

  # write out new aliases file
  # first check for a lock file
  if (-f "$adir/atmptmp$$.$g_curtime") {
    irootResourceError($IROOT_ALIASES_TITLE, 
        "-f '$adir/atmptmp$$.$g_curtime' returned 1 in aliasesSaveChanges");
  }
  # no obvious lock... use link() for atomicity to avoid race conditions
  open(ATMP, ">$adir/atmptmp$$.$g_curtime") ||
    irootResourceError($IROOT_ALIASES_TITLE,
        "open(ATMP, '>$adir/atmptmp$$.$g_curtime') in aliasesSaveChanges");
  close(ATMP);
  $locked = link("$adir/atmptmp$$.$g_curtime", "$adir/atmp");
  unlink("$adir/atmptmp$$.$g_curtime");
  $locked || irootResourceError($IROOT_ALIASES_TITLE,
     "link('$adir/atmptmp$$.$g_curtime', '$adir/atmp') \
      failed in aliasesSaveChanges");
  open(NEWALIASFP, ">$adir/atmp")  ||
    irootResourceError($IROOT_ALIASES_TITLE,
        "open(NEWALIASFP, '>$adir/atmp') in aliasesSaveChanges");
  flock(NEWALIASFP, 2);  # exclusive lock
  open(OLDALIASFP, "$adir/$afile");
  while (<OLDALIASFP>) {
    $curentry = $_;
    # print out curentry, replace, or ignore?
    $match = 0;
    foreach $alias (@alias_ids) {
      if ($curentry =~ /^$alias\:/) {
        $match = 1;
        # we have a match, replace or ignore?
        if ($entries{$alias} eq "__REMOVE") {
          # ignore
        }
        else {
          # replace
          print NEWALIASFP "$entries{$alias}\n" ||
            irootResourceError($IROOT_ALIASES_TITLE,
              "print to NEWALIASFP failed -- server quota exceeded?");
        }
        delete($entries{$alias});
      }
    }
    if ($match == 0) {
      print NEWALIASFP "$curentry" ||
        irootResourceError($IROOT_ALIASES_TITLE,
          "print to NEWALIASFP failed -- server quota exceeded?");
    }
    # append any new aliases after current entry if applicable
    foreach $alias (@alias_ids) {
      next unless ($alias =~ /^__NEWALIAS/);
      if ($curentry =~ /^$g_aliases{$alias}->{'placement'}\s/) {
        print NEWALIASFP "$entries{$alias}\n" ||
          irootResourceError($IROOT_ALIASES_TITLE,
            "print to NEWALIASFP failed -- server quota exceeded?");
        delete($entries{$alias});
      }
    }
  }
  close(OLDALIASFP);
  # append new entries
  foreach $entry (keys(%entries)) {
    next if ($entries{$entry} eq "__REMOVE");
    print NEWALIASFP "$entries{$entry}\n" ||
      irootResourceError($IROOT_ALIASES_TITLE,
        "print to NEWALIASFP failed -- server quota exceeded?");
  }
  flock(NEWALIASFP, 8);  # unlock
  close(NEWALIASFP);
  rename("$adir/atmp", "$adir/$afile") ||
     irootResourceError($IROOT_ALIASES_TITLE, 
       "rename('$adir/atmp', '$adir/$afile') in aliasesSaveChanges");
  chmod(0644, "$adir/$afile");

  # rebuild the aliases db file 
  $output = aliasesRebuildDB();
  return($output);
}

##############################################################################

sub aliasesSelectForm
{
  local($type) = @_;
  local($title, $subtitle, $alias, $acount, $optiontxt);
  local(@selectedaliases, $salias, $selected);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("aliases");

  $subtitle = "$IROOT_ALIASES_TITLE: ";
  if ($type eq "edit") {
    $subtitle .= "$IROOT_EDIT_TEXT: $ALIASES_SELECT_TITLE";
  }
  elsif ($type eq "remove") {
    $subtitle .= "$IROOT_REMOVE_TEXT: $ALIASES_SELECT_TITLE";
  }

  $title = "$IROOT_MAINMENU_TITLE: $subtitle";

  # first check and see if there are more than one alias to select
  $acount = 0;
  foreach $alias (keys(%g_aliases)) {
    $acount++;
  }
  if ($acount == 0) {
    # oops.  no alias definitions in aliases file.
    aliasesEmptyFile();
  }
  elsif ($acount == 1) {
    $g_form{'aliases'} = (keys(%g_aliases))[0];
    return($g_form{'aliases'});
  }

  @selectedaliases = split(/\|\|\|/, $g_form{'aliases'}) if ($g_form{'aliases'});

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTextLargeBold($subtitle);
  htmlBR();
  if ($g_form{'select_submit'} && 
      ($g_form{'select_submit'} eq $ALIASES_SELECT_TITLE)) {
    htmlBR();
    htmlTextColorBold(">>> $ALIASES_SELECT_HELP <<<", "#cc0000");
  }
  else {
    htmlText($ALIASES_SELECT_HELP);
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
  formSelect("name", "aliases", "size", formSelectRows($acount),
             "_OTHER_", "MULTIPLE", "_FONT_", "fixed");
  $g_form{'sort_submit'} = $g_form{'sort_select'};  # for sort subroutine
  foreach $alias (sort aliasesByPreference(keys(%g_aliases))) {
    $selected = 0;
    foreach $salias (@selectedaliases) {
      if ($salias eq $alias) {
        $selected = 1;
        last;
      }
    }
    $optiontxt = "$alias => $g_aliases{$alias}->{'value'}";
    if (length($optiontxt) > 70) {
      $optiontxt = substr($optiontxt, 0, 70) . "&#133;";
    }
    formSelectOption($alias, $optiontxt, $selected);
  }
  formSelectClose();
  htmlTableDataClose();
  htmlTableData("valign", "top");
  if ($g_form{'sort_select'} &&
      ($g_form{'sort_select'} eq "$ALIASES_SORT_BY_ORDER")) {
    formInput("type", "submit", "name", "sort_select", "value", 
              $ALIASES_SORT_BY_NAME);
  }
  else {
    formInput("type", "submit", "name", "sort_select", "value", 
              $ALIASES_SORT_BY_ORDER);
  }
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("colspan", "2");
  formInput("type", "submit", "name", "select_submit",
            "value", $ALIASES_SELECT_TITLE);
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

