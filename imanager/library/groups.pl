#
# groups.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/groups.pl,v 2.12.2.3 2006/04/25 19:48:23 rus Exp $
#
# add/edit/remove/view groups functions
#

##############################################################################

sub groupsByPreference
{
  if (($a =~ /^__NEWGROUP/) || ($b =~ /^__NEWGROUP/)) {
    return($a cmp $b);
  }

  if ($g_form{'sort_by'} && ($g_form{'sort_by'} eq "gid")) {
    return($g_groups{$a}->{'gid'} <=> $g_groups{$b}->{'gid'});
  }
  else {
    return($a cmp $b);
  }
}

##############################################################################

sub groupsCheckFormValidity
{
  local($type) = @_;
  local($mesg, $group, @selectedgroups, $gcount, $nkey, $mkey);
  local(@users, $user, %newgroups);
  local($errmsg, %errors);

  encodingIncludeStringLibrary("group");

  if (($g_form{'submit'} && ($g_form{'submit'} eq "$CANCEL_STRING")) ||
      ($g_form{'select_submit'} && ($g_form{'select_submit'} eq "$CANCEL_STRING"))) {
    if ($type eq "add") {
      $mesg = $GROUP_CANCEL_ADD_TEXT;
    }
    elsif ($type eq "edit") {
      $mesg = $GROUP_CANCEL_EDIT_TEXT;
    }
    elsif ($type eq "remove") {
      $mesg = $GROUP_CANCEL_REMOVE_TEXT;
    }
    redirectLocation("iroot.cgi", $mesg);
  }

  # perform error checking on form data
  if (($type eq "add") || ($type eq "edit")) {
    $gcount = 0;
    %errors = %newgroups = ();
    @selectedgroups = split(/\|\|\|/, $g_form{'groups'});
    foreach $group (@selectedgroups) {
      $nkey = $group . "_groupname";
      $mkey = $group . "_members";
      # next if new and left blank
      next if (($group =~ /^__NEWGROUP/) && (!$g_form{$nkey}) && (!$g_form{$mkey}));
      # next if no change was made (only applicable for type == edit)
      next if (($type eq "edit") && 
               ($g_form{$nkey} eq $group) &&
               ($g_form{$mkey} eq $g_groups{$group}->{'members'})); 
      $gcount++;
      # group name checks
      $g_form{$nkey} =~ tr/A-Z/a-z/;
      if ($g_form{$nkey}) {
        if ($g_form{$nkey} =~ /[^a-z0-9\.\-\_]/) {
          $errmsg = $GROUP_ERROR_GROUP_NAME_CONTAINS_INVALID_CHARS;
          $errmsg =~ s/__GROUP__/$g_form{$nkey}/;
          push(@{$errors{$group}}, $errmsg);
        }
        if ($g_form{$nkey} =~ /^[0-9\-\_]/) {
          $errmsg = $GROUP_ERROR_GROUP_NAME_MUST_BEGIN_WITH_LETTER;
          $errmsg =~ s/__GROUP__/$g_form{$nkey}/;
          push(@{$errors{$group}}, $errmsg);
        }
      }
      else {
        push(@{$errors{$group}}, $GROUP_ERROR_GROUP_NAME_IS_BLANK);
      }
      # no duplicates allowed
      if (($g_form{$nkey} ne $group) && (defined($g_groups{$g_form{$nkey}}))) {
        # no duplicates allowed
        $errmsg = $GROUP_ERROR_GROUP_NAME_EXISTS;
        $errmsg =~ s/__GROUP__/$g_form{$nkey}/;
        push(@{$errors{$group}}, $errmsg);
      }
      if (defined($newgroups{$g_form{$nkey}})) {
        $errmsg = $GROUP_ERROR_GROUP_NAME_DUPLICATE;
        $errmsg =~ s/__GROUP__/$g_form{$nkey}/;
        push(@{$errors{$group}}, $errmsg);
      }
      $newgroups{$g_form{$nkey}} = "dau!";
      # member list checks
      $g_form{$mkey} =~ s/\s//;
      $g_form{$mkey} =~ s/^\,//;
      $g_form{$mkey} =~ s/\,$//;
      $g_form{$mkey} =~ s/\,+/\,/;
      @users = split(/\,/, $g_form{$mkey});
      foreach $user (@users) {
        unless (defined($g_users{$user})) {
          $errmsg = $GROUP_ERROR_GROUP_MEMBER_LIST_USER_UNKNOWN;
          $errmsg =~ s/__GROUP__/$g_form{$nkey}/;
          $errmsg =~ s/__USER__/$user/;
          push(@{$errors{$group}}, $errmsg);
        }
      }
    }
    if (keys(%errors)) {
      groupsDisplayForm($type, %errors);
    }
    if ($gcount == 0) {
      # nothing to do!
      groupsNoChangesExist($type);
    }
    # print out a confirm form if necessary
    $g_form{'confirm'} = "no" unless ($g_form{'confirm'});
    if ($g_form{'confirm'} ne "yes") {
      groupsConfirmChanges($type);
    }
  }
}

##############################################################################

sub groupsCommitChanges
{
  local($type) = @_;
  local($group, @selectedgroups, @grouplist, $nkey, $mkey);
  local($success_mesg, $output);

  @selectedgroups = split(/\|\|\|/, $g_form{'groups'}) if ($g_form{'groups'});
  foreach $group (@selectedgroups) {
    if (($type eq "add") || ($type eq "edit")) {
      $nkey = $group . "_groupname";
      $mkey = $group . "_members";
      # next if new and left blank
      next if (($group =~ /^__NEWGROUP/) && (!$g_form{$nkey}) && (!$g_form{$mkey}));
      # next if no change was made (only applicable for type == edit)
      if (($type eq "edit") && 
          ($g_form{$nkey} eq $group) &&
          ($g_form{$mkey} eq $g_groups{$group}->{'members'})) {
        $g_form{'groups'} =~ s/^\Q$group\E$//;
        $g_form{'groups'} =~ s/^\Q$group\E\|\|\|//;
        $g_form{'groups'} =~ s/\|\|\|\Q$group\E\|\|\|/\|\|\|/;
        $g_form{'groups'} =~ s/\|\|\|\Q$group\E$//;
        next;
      }
      if ((!$g_form{$nkey}) && (!$g_form{$mkey})) {
        # poor man's way of removing a group, i.e. editing it and
        # setting its name and memberlist to "" ...tag it for removal
        $g_groups{$group}->{'new_groupname'} = "__REMOVE";
      }
      else {
        $g_groups{$group}->{'new_groupname'} = $g_form{$nkey};
        $g_groups{$group}->{'new_members'} = $g_form{$mkey};
      }
      push(@grouplist, $group);
    }
    elsif ($type eq "remove") {
      $g_groups{$group}->{'new_groupname'} = "__REMOVE";
      push(@grouplist, $group);
    }
  }
  $output = groupsSaveChanges(@grouplist);
        
  # now redirect back to iroot index and show success message
  if ($type eq "add") {
    $success_mesg = $GROUP_SUCCESS_ADD_TEXT;
  }
  elsif ($type eq "edit") {
    $success_mesg = $GROUP_SUCCESS_EDIT_TEXT;
  }
  elsif ($type eq "remove") {
    $success_mesg = $GROUP_SUCCESS_REMOVE_TEXT;
  }
  $success_mesg .= "\n$output" if ($output);
  redirectLocation("iroot.cgi", $success_mesg);
}

##############################################################################

sub groupsConfirmChanges
{
  local($type) = @_;
  local($subtitle, $title);
  local($group, @selectedgroups, $nkey, $mkey);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("group");

  if ($type eq "add") {
    $subtitle = "$IROOT_ADD_TEXT: $CONFIRM_STRING";
  }
  elsif ($type eq "edit") {
    $subtitle = "$IROOT_EDIT_TEXT: $CONFIRM_STRING";
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_GROUPS_TITLE: $subtitle";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlText($GROUP_CONFIRM_TEXT);
  htmlP();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "type", "value", $type);
  formInput("type", "hidden", "name", "confirm", "value", "yes");
  formInput("type", "hidden", "name", "groups", "value", $g_form{'groups'});
  htmlUL();
  @selectedgroups = split(/\|\|\|/, $g_form{'groups'});
  foreach $group (@selectedgroups) {
    $nkey = $group . "_groupname";
    $mkey = $group . "_members";
    # next if new and left blank
    next if (($group =~ /^__NEWGROUP/) && (!$g_form{$nkey}) && (!$g_form{$mkey}));
    # next if no change was made (only applicable for type == edit)
    next if (($type eq "edit") && 
             ($g_form{$nkey} eq $group) &&
             ($g_form{$mkey} eq $g_groups{$group}->{'members'})); 
    # print out the hidden field
    formInput("type", "hidden", "name", $nkey, "value", $g_form{$nkey});
    formInput("type", "hidden", "name", $mkey, "value", $g_form{$mkey});
    htmlListItem();
    if ($group =~ /^__NEWGROUP/) {
      # confirm addition
      htmlTextBold($GROUP_CONFIRM_ADD_NEW);
      htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$GROUP_NAME\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;$g_form{$nkey}");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$GROUP_MEMBER_LIST\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      if ($g_form{$mkey}) {
        htmlTextCode("&#160;$g_form{$mkey}");
      }
      else {
        htmlTextCode("&#160;&#171;$GROUP_NO_EXPLICIT_MEMBERS&#187;");
      }
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlBR();
    }
    else {
      # confirm edition
      htmlTextBold($GROUP_CONFIRM_CHANGE_FROM);
      htmlBR();
      # old user info table
      htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$GROUP_NAME\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;$group");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$GROUP_MEMBER_LIST\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      if ($g_groups{$group}->{'members'}) {
        htmlTextCode("&#160;$g_groups{$group}->{'members'}");
      }
      else {
        htmlTextCode("&#160;&#171;$GROUP_NO_EXPLICIT_MEMBERS&#187;");
      }
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableClose();
      # change user to....
      htmlTextBold($GROUP_CONFIRM_CHANGE_TO);
      htmlBR();
      # new user info table
      htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$GROUP_NAME\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;$g_form{$nkey}");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$GROUP_MEMBER_LIST\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      if ($g_form{$mkey}) {
        htmlTextCode("&#160;$g_form{$mkey}");
      }
      else {
        htmlTextCode("&#160;&#171;$GROUP_NO_EXPLICIT_MEMBERS&#187;");
      }
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
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

sub groupsDisplayForm
{
  local($type, %errors) = @_;
  local($title, $subtitle, $helptext, $buttontext, $mesg, $grouplist);
  local(@selectedgroups, $group, $index, $singlegroup, $first);
  local($size25, $size40, $key, $value, $user, $num_system_groups);
  local($donothide);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("group");

  # set the new sort_by preference (if applicable)
  if ($g_form{'sort_submit'} &&
      ($g_form{'sort_submit'} eq $GROUP_SORT_BY_NAME)) {
    $g_form{'sort_by'} = "";
  }
  elsif ($g_form{'sort_submit'} &&
         ($g_form{'sort_submit'} eq $GROUP_SORT_BY_GID)) {
    $g_form{'sort_by'} = "gid";
  }

  # set the new show_system_groups preference (if applicable)
  if ($g_form{'sg_submit'} && 
      ($g_form{'sg_submit'} eq $GROUP_SYSTEM_HIDE)) {
    $g_form{'show_system_groups'} = "";
  }
  elsif ($g_form{'sg_submit'} && 
         ($g_form{'sg_submit'} eq $GROUP_SYSTEM_SHOW)) {
    $g_form{'show_system_groups'} = "yes";
  }

  # reset sort_by eq gid if not showing system groups
  if (($g_form{'sort_by'} && ($g_form{'sort_by'} eq "gid")) &&
      ($g_form{'show_system_groups'} ne "yes")) {
    $g_form{'sort_by'} = "";
  }
      
  if ($type eq "add") {
    $subtitle = $IROOT_ADD_TEXT;
    if ($g_form{'groups'}) {
      @selectedgroups = split(/\|\|\|/, $g_form{'groups'});
    }
    else {
      for ($index=1; $index<=$g_prefs{'iroot__num_newgroups'}; $index++) {
        push(@selectedgroups, "__NEWGROUP$index");
        $grouplist .= "__NEWGROUP$index\|\|\|";
      }
      $grouplist =~ s/\|+$//g;
      $g_form{'groups'} = $grouplist;
    }
    $helptext = $GROUP_ADD_HELP_TEXT;
    $buttontext = $GROUP_ADD_SUBMIT_TEXT;
  }
  elsif ($type eq "edit") {
    $subtitle = $IROOT_EDIT_TEXT;
    @selectedgroups = split(/\|\|\|/, $g_form{'groups'}) if ($g_form{'groups'});
    $helptext = $GROUP_EDIT_HELP_TEXT;
    $buttontext = $GROUP_EDIT_SUBMIT_TEXT;
  }
  elsif ($type eq "remove") {
    $subtitle = $IROOT_REMOVE_TEXT;
    @selectedgroups = split(/\|\|\|/, $g_form{'groups'}) if ($g_form{'groups'});
    $helptext = $GROUP_REMOVE_HELP_TEXT;
    $buttontext = $GROUP_REMOVE_SUBMIT_TEXT;
  }
  elsif ($type eq "view") {
    $num_system_groups = 0;
    $subtitle = $IROOT_VIEW_TEXT;
    foreach $group (keys(%g_groups)) {
      if ($g_platform_type eq "dedicated") {
        if (($g_groups{$group}->{'gid'} < 1000) ||
            ($g_groups{$group}->{'gid'} >= 65533)) {
          $num_system_groups++;
          next unless ($g_form{'show_system_groups'} eq "yes");
        }
      }
      push(@selectedgroups, $group);
    }
    $g_form{'sg_submit'} = "";
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_GROUPS_TITLE: $subtitle";

  if ($#selectedgroups == -1) {
    # oops... no groups in selected group list.
    if (($type eq "edit") || ($type eq "remove")) {
      $singlegroup = groupsSelectForm($type);
      @selectedgroups = ("$singlegroup");
    }
    else {
      if ($g_platform_type eq "dedicated") {
        # no selected groups... just populate with all groups
        @selectedgroups = keys(%g_groups);
        $g_form{'show_system_groups'} = "all";
        $donothide = 1;
      }
      # if no groups in file then put up the empty file notice
      groupsEmptyFile() if ($#selectedgroups == -1);
    }
  } 
  else {
    # have selected groups, but are we expanding or contracting the display?
    groupsSelectForm($type) if ($g_form{'sg_submit'}); 
  } 

  $size25 = formInputSize(25);
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
      htmlText($GROUP_OVERVIEW_HELP_TEXT);
      htmlP();
    }
  }
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "view", "value", $type);
  formInput("type", "hidden", "name", "groups", "value", $g_form{'groups'});
  htmlTable();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "bottom");
  htmlNoBR();
  htmlTextBold("$GROUP_NAME&#160;&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  if (($type eq "view") && 
      (defined($g_form{'show_system_groups'})) && 
      ($g_form{'show_system_groups'} eq "yes")) {
    htmlTableData("valign", "bottom", "align", "right");
    htmlTextBold("$GROUP_ID&#160;&#160;");
    htmlTableDataClose();
  }
  htmlTableData("valign", "bottom");
  htmlNoBR();
  htmlTextBold($GROUP_MEMBER_LIST);
  htmlNoBRClose();
  htmlText(" ");
  htmlNoBR();
  htmlTextBold("$GROUP_EXPLICIT_MEMBERS&#160;&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  if ($type ne "add") {
    htmlTableData("valign", "bottom");
    htmlNoBR();
    htmlTextBold($GROUP_MEMBER_LIST);
    htmlNoBRClose();
    htmlText(" ");
    htmlNoBR();
    htmlTextBold("$GROUP_IMPLICIT_MEMBERS&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
  }
  if (($type eq "add") || ($type eq "edit")) {
    # error column
    htmlTableData();
    htmlTableDataClose();
  }
  htmlTableRowClose();
  foreach $group (sort groupsByPreference(@selectedgroups)) {
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    if (($type eq "view") || ($type eq "remove")) {
      # group name
      htmlTableData("valign", "middle");
      if ($type eq "view") {
        htmlAnchor("href", "groups_edit.cgi?groups=$group",
                   "title", "$IROOT_GROUPS_TITLE: $IROOT_EDIT_TEXT: $group");
        htmlAnchorText($group);
        htmlAnchorClose();
        htmlText("&#160;&#160;");
      }
      else {
        htmlText("$group&#160;&#160;");
      }
      htmlTableDataClose();
      # group id
      if (($type eq "view") && 
          (defined($g_form{'show_system_groups'})) &&
          ($g_form{'show_system_groups'} eq "yes")) {
        htmlTableData("valign", "middle", "align", "right");
        htmlText("$g_groups{$group}->{'gid'}&#160;&#160;");
        htmlTableDataClose();
      }
      # membership list from group file
      htmlTableData("valign", "middle");
      if ($g_groups{$group}->{'members'}) {
        htmlText("$g_groups{$group}->{'members'}&#160;&#160;");
      }
      else {
        htmlNoBR();
        htmlText("&#171;$GROUP_NO_EXPLICIT_MEMBERS&#187;&#160;&#160;");
        htmlNoBRClose();
      }
      htmlTableDataClose();
      # implied members from passwd file
      htmlTableData("valign", "middle");
      $first = 1;
      foreach $user (sort {$a cmp $b} (keys(%g_users))) {
        next unless (defined($g_users{$user}->{'gid'}));
        if ($g_users{$user}->{'gid'} == $g_groups{$group}->{'gid'}) {
          htmlText(",") unless ($first);
          htmlText($user);
          $first = 0;
        }
      }
      if ($first == 1) {
        # no implicit members
        htmlNoBR();
        htmlText("&#171;$GROUP_NO_IMPLICIT_MEMBERS&#187;");
        htmlNoBRClose();
      }
      htmlTableDataClose();
    }
    else {
      # group name 
      htmlTableData("valign", "middle");
      $key = $group . "_groupname";
      $value = (defined($g_form{'sort_submit'}) ||
                defined($g_form{'submit'})) ?  $g_form{$key} : 
                                               $g_groups{$group}->{'group'};
      formInput("name", $key, "size", $size25, "value", $value);
      htmlTableDataClose();
      # group membership list from group file
      htmlTableData("valign", "middle");
      $key = $group . "_members";
      $value = (defined($g_form{'sort_submit'}) ||
                defined($g_form{'submit'})) ?
                $g_form{$key} : $g_groups{$group}->{'members'};
      formInput("name", $key, "size", $size40, "value", $value);
      htmlTableDataClose();
      if ($type ne "add") {
        # group membership list from passwd file
        htmlTableData("valign", "middle");
        $first = 1;
        foreach $user (sort {$a cmp $b} (keys(%g_users))) {
          next unless (defined($g_users{$user}->{'gid'}));
          if ($g_users{$user}->{'gid'} == $g_groups{$group}->{'gid'}) {
            htmlText(",") unless ($first);
            htmlAnchor("href", "users_edit.cgi?users=$user", "title", 
                       "$IROOT_USERS_TITLE: $IROOT_EDIT_TEXT: $user");
            htmlAnchorText($user);
            htmlAnchorClose();
            $first = 0;
          }
        }
        if ($first == 1) {
          # no implicit members
          htmlNoBR();
          htmlText("&#171;$GROUP_NO_IMPLICIT_MEMBERS&#187;");
          htmlNoBRClose();
        }
        htmlTableDataClose();
      }
      # error column
      htmlTableData("valign", "middle");
      if ($#{$errors{$group}} > -1) {
        foreach $mesg (@{$errors{$group}}) {
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
  htmlTableData("colspan", "3");
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  if ($type eq "view") {
    if (($g_platform_type eq "dedicated") && ($num_system_groups > 0)) {
      if ($g_form{'show_system_groups'} eq "yes") {
        if ($g_form{'sort_by'} eq "gid") {
          formInput("type", "submit", "name", "sort_submit", "value",
                    $GROUP_SORT_BY_NAME);
        }
        else {
          formInput("type", "submit", "name", "sort_submit", "value",
                    $GROUP_SORT_BY_GID);
        }
        unless ($donothide) {
          htmlP();
          formInput("type", "submit", "name", "sg_submit",
                    "value", $GROUP_SYSTEM_HIDE);
        }
      }
      else {
        formInput("type", "submit", "name", "sg_submit",
                  "value", $GROUP_SYSTEM_SHOW);
      }
      formInput("type", "hidden", "name", "show_system_groups",
                "value", $g_form{'show_system_groups'});
      formInput("type", "hidden", "name", "sort_by",
                "value", $g_form{'sort_by'});
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

sub groupsEmptyFile
{
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlText($GROUP_NONE_EXIST);
  htmlP();
  htmlTableDataClose();
  htmlTableRowClose();  
  htmlTableClose();
  labelCustomFooter();
  exit(0);
}

##############################################################################
   
sub groupsNoChangesExist
{
  local($type) = @_;
  local($subtitle, $title);
     
  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("group");
  
  if ($type eq "add") {
    $subtitle = "$IROOT_ADD_TEXT";
  }
  elsif ($type eq "edit") {
    $subtitle = "$IROOT_EDIT_TEXT";
  }
 
  $title = "$IROOT_MAINMENU_TITLE: $IROOT_GROUPS_TITLE: $subtitle";
 
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlText($GROUP_NO_CHANGES_FOUND);
  htmlP();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub groupsSaveChanges
{
  local(@group_ids) = @_;
  local($group, %entries, $entry, $newentry, $curentry);
  local($mygroupname, $mypasswd, $mygid, $mymemberlist);
  local($locked, $match, $curgid);

  foreach $group (@group_ids) {
    # sift through the login ids one by one
    if ($g_groups{$group}->{'new_groupname'} eq "__REMOVE") {
      # this is a subtle expectation in the code that may be missed.  set 
      # the new login value for a group to "__REMOVE" if you want to remove
      # the group from the password and the vpriv.conf file.  
      $entries{$group} = "__REMOVE";
      next;
    }
    # build new entry for group file
    $mygroupname = $g_groups{$group}->{'new_groupname'};
    $mypasswd = $g_groups{$group}->{'new_password'} || "*";
    if ($g_groups{$mygroupname}->{'gid'}) {
      $mygid = $g_groups{$mygroupname}->{'gid'};
    }
    else {
      $mygid = groupGetNewGroupID();
      # set the gid field so that the next call to get a new group ID 
      # does not return a GID that is to be used by a newly created group
      $g_groups{$mygroupname}->{'gid'} = $mygid;
    }
    $mymemberlist = $g_groups{$group}->{'new_members'};
    $mymemberlist =~ s/\,$//;
    $newentry = "$mygroupname:$mypasswd:$mygid:$mymemberlist";
    $entries{$group} = $newentry;
  }

  # add a newline character to the file if necessary
  open(OGFP, "/etc/group") ||
    groupResourceError("open(OGFP, '/etc/group') in groupsSaveChanges");
  seek(OGFP, -1, 2);
  read(OGFP, $lastchar, 1);
  close(OGFP);
  if ($lastchar ne "\n") {
    open(OGFP, ">>/etc/group") ||
      groupResourceError("open(OGFP, '>>/etc/group') in groupsSaveChanges");
    print OGFP "\n";
    close(OGFP);
  }

  # backup old file
  require "$g_includelib/backup.pl";
  backupSystemFile("/etc/group") if (-e "/etc/group");

  # write out new group file
  # first check for a lock file
  if (-f "/etc/gtmptmp$$.$g_curtime") {
    groupResourceError(
        "-f '/etc/gtmptmp$$.$g_curtime' returned 1 in groupsSaveChanges");
  } 
  # no obvious lock... use link() for atomicity to avoid race conditions
  open(PTMP, ">/etc/gtmptmp$$.$g_curtime") ||
    groupResourceError(
        "open(PTMP, '>/etc/gtmptmp$$.$g_curtime') in groupsSaveChanges");
  close(PTMP);
  $locked = link("/etc/gtmptmp$$.$g_curtime", "/etc/gtmp");
  unlink("/etc/gtmptmp$$.$g_curtime");
  $locked || groupResourceError(
     "link('/etc/gtmptmp$$.$g_curtime', '/etc/gtmp') \
      failed in groupsSaveChanges");
  open(NGFP, ">/etc/gtmp")  ||
    groupResourceError("open(NGFP, '>/etc/gtmp') in groupsSaveChanges");
  flock(NGFP, 2);  # exclusive lock
  open(OGFP, "/etc/group");
  while (<OGFP>) {
    $curentry = $_;
    # print out curentry, replace, or ignore?
    $match = 0;
    foreach $group (@group_ids) {
      if ($curentry =~ /^\Q$group\E:/) {
        $match = 1;
        # we have a match, replace or ignore?
        if ($entries{$group} eq "__REMOVE") {
          # ignore
        }
        else {
          # replace
          print NGFP "$entries{$group}\n" ||
            groupResourceError(
              "print to NGFP failed -- disk quota exceeded?");
        }
        delete($entries{$group});
      }
    }
    if ($match == 0) {
      # append any new groups before current entry (if applicable).
      # a check here (before the curentry is written) presumes that 
      # the groups are ordered per group id from low to high.  thus,
      # when we encounter the first current entry in the group file 
      # where the group id for current entry is greater than the new 
      # group id for the new group, then we want to write the new
      # group entry before the current entry is rewritten to the file
      foreach $group (@group_ids) {
        next unless ($group =~ /^__NEWGROUP/);
        next unless (defined($entries{$group})); # don't add twice
        ($curgid) = (split(/\:/, $curentry))[2];
        ($mygid) = (split(/\:/, $entries{$group}))[2];
        if ($mygid < $curgid) {
          print NGFP "$entries{$group}\n" ||
            groupResourceError(
              "print to NGFP failed -- disk quota exceeded?");
          delete($entries{$group});
        }
      }
      print NGFP "$curentry" ||
        groupResourceError("print to NGFP failed -- disk quota exceeded?");
    }
  }
  close(OGFP);
  # append new entries
  foreach $entry (keys(%entries)) {
    next if ($entries{$entry} eq "__REMOVE");
    print NGFP "$entries{$entry}\n" ||
      groupResourceError("print to NGFP failed -- disk quota exceeded?");
  }
  flock(NGFP, 8);  # unlock
  close(NGFP);
  rename("/etc/gtmp", "/etc/group") ||
     groupResourceError(
       "rename('/etc/gtmp', '/etc/group') in groupsSaveChanges");
  chmod(0644, "/etc/group");

  # return an error message (reserved for later use)
  return("");
}

##############################################################################
        
sub groupsSelectForm
{
  local($type) = @_;
  local($title, $subtitle, $group, $gcount);
  local($num_system_groups, $donothide, $selected, $sgroup);
  
  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("group");
  
  # set the new show_system_groups preference (if applicable)
  if ($g_form{'sg_submit'} && ($g_form{'sg_submit'} eq $GROUP_SYSTEM_HIDE)) {
    $g_form{'show_system_groups'} = "";
  }
  elsif ($g_form{'sg_submit'} && ($g_form{'sg_submit'} eq $GROUP_SYSTEM_SHOW)) {
    $g_form{'show_system_groups'} = "yes";
  }

  $subtitle = "$IROOT_GROUPS_TITLE: ";
  if ($type eq "edit") {
    $subtitle .= "$IROOT_EDIT_TEXT: $GROUP_SELECT_TITLE";;
  }
  elsif ($type eq "remove") {
    $subtitle .= "$IROOT_REMOVE_TEXT: $GROUP_SELECT_TITLE";;
  }   

  $title = "$IROOT_MAINMENU_TITLE: $subtitle";
      
  # first check and see if there are more than one group to select
  $gcount = 0;
  foreach $group (keys(%g_groups)) {
    if ($g_platform_type eq "dedicated") {
      if (($g_groups{$group}->{'gid'} < 1000) ||
          ($g_groups{$group}->{'gid'} >= 65533)) {
        $num_system_groups++;
        next unless ($g_form{'show_system_groups'} eq "yes");
      }
    }
    $gcount++;
    $g_form{'groups'} = $group;
  }

  if (($gcount == 0) && ($g_platform_type eq "dedicated")) {
    # if no non-system group counted... get count of all group 
    $gcount = keys(%g_groups);
    $donothide = 1;
    $g_form{'show_system_groups'} = "yes";
  }

  if ($gcount == 0) {
    # oops.  no group definitions in groups file.
    groupsEmptyFile();
  }
  elsif ($gcount == 1) {
    return($g_form{'groups'});
  }

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlTextLargeBold($subtitle);
  htmlBR();
  if ($g_form{'select_submit'} && 
      ($g_form{'select_submit'} eq $GROUP_SELECT_TITLE)) {
    htmlBR();
    htmlTextColorBold(">>> $GROUP_SELECT_HELP <<<", "#cc0000");
  }
  else {
    htmlText($GROUP_SELECT_HELP);
  }
  htmlP();
  htmlUL();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "view", "value", $type);
  formSelect("name", "groups", "size", formSelectRows($gcount),
             "_OTHER_", "MULTIPLE");
  foreach $group (sort groupsByPreference(keys(%g_groups))) {
    if ($g_platform_type eq "dedicated") {
      if (($g_groups{$group}->{'gid'} < 1000) ||
          ($g_groups{$group}->{'gid'} >= 65533)) {
        next unless ($g_form{'show_system_groups'} eq "yes");
      }
    }
    $selected = 0;
    foreach $sgroup (@selectedgroups) { 
      if ($sgroup eq $group) {
        $selected = 1;
        last;
      }
    }
    formSelectOption($group, $group, $selected);
  }
  formSelectClose();
  htmlP();
  formInput("type", "submit", "name", "select_submit",
            "value", $GROUP_SELECT_TITLE);
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  if (($g_platform_type eq "dedicated") && ($num_system_groups > 0)) {
    if ($g_form{'show_system_groups'} eq "yes") {
      unless ($donothide) {
        htmlP(); 
        formInput("type", "submit", "name", "sg_submit",
                  "value", $GROUP_SYSTEM_HIDE);
      }
    }
    else {
      htmlP();
      formInput("type", "submit", "name", "sg_submit",
                "value", $GROUP_SYSTEM_SHOW);
    }
  }
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

