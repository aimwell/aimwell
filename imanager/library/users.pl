#
# users.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/users.pl,v 2.12.2.12 2006/04/25 19:48:25 rus Exp $
#
# add/edit/remove/view users functions
#

##############################################################################

sub usersByPreference
{
  local($pav, $pbv, $sav, $sbv, $tav, $tbv, $formkey);

  # the 'zzz' assignment forces blank login names to the bottom of the 
  # sort.  this came up when a multiple add user form which was partially 
  # populated but contained some errors -- the blank login fields bubbled
  # up to the top above the add user rows that actually contained data.

  if ($g_form{'sort_by'} && ($g_form{'sort_by'} eq "uid")) {
    # only applicable for type == view
    return(($g_users{$a}->{'uid'} <=> $g_users{$b}->{'uid'}) || ($a cmp $b));
  }
  elsif ($g_form{'sort_by'} && ($g_form{'sort_by'} eq "name")) {
    $formkey = $a . "_name";
    $pav = $g_form{$formkey} || $g_users{$a}->{'name'};
    $formkey = $b . "_name";
    $pbv = $g_form{$formkey} || $g_users{$b}->{'name'};
    $formkey = $a . "_login";
    $sav = $g_form{$formkey} || $g_users{$a}->{'login'} || "zzz"; # see above
    $formkey = $b . "_login";
    $sbv = $g_form{$formkey} || $g_users{$b}->{'login'} || "zzz"; # see above
    $formkey = $a . "_path";
    $tav = $g_form{$formkey} || $g_users{$a}->{'home'};
    $formkey = $b . "_path";
    $tbv = $g_form{$formkey} || $g_users{$b}->{'home'};
  }
  elsif ($g_form{'sort_by'} && ($g_form{'sort_by'} eq "path")) {
    $formkey = $a . "_path";
    $pav = $g_form{$formkey} || $g_users{$a}->{'home'};
    $formkey = $b . "_path";
    $pbv = $g_form{$formkey} || $g_users{$b}->{'home'};
    $formkey = $a . "_login";
    $sav = $g_form{$formkey} || $g_users{$a}->{'login'} || "zzz"; # see above
    $formkey = $b . "_login";
    $sbv = $g_form{$formkey} || $g_users{$b}->{'login'} || "zzz"; # see above
    $formkey = $a . "_name";
    $tav = $g_form{$formkey} || $g_users{$a}->{'name'};
    $formkey = $b . "_name";
    $tbv = $g_form{$formkey} || $g_users{$b}->{'name'};
  }
  else {
    # sort by username, the default
    $formkey = $a . "_login";
    $pav = $g_form{$formkey} || $g_users{$a}->{'login'} || "zzz"; # see above
    $formkey = $b . "_login";
    $pbv = $g_form{$formkey} || $g_users{$b}->{'login'} || "zzz"; # see above
    $formkey = $a . "_name";
    $sav = $g_form{$formkey} || $g_users{$a}->{'name'};
    $formkey = $b . "_name";
    $sbv = $g_form{$formkey} || $g_users{$b}->{'name'};
    $formkey = $a . "_path";
    $tav = $g_form{$formkey} || $g_users{$a}->{'home'};
    $formkey = $b . "_path";
    $tbv = $g_form{$formkey} || $g_users{$b}->{'home'};
  }

  if ($pav eq $pbv) {
    if ($sav eq $sbv) {
      return($tav cmp $tbv);
    }
    else {
      return($sav cmp $sbv);
    }
  }
  else {
    return($pav cmp $pbv);
  }
}

##############################################################################

sub usersCheckFormValidity
{
  local($type) = @_;
  local($mesg, $user, @selectedusers, $ucount);
  local($lkey, $pkey, $pckey, $nkey, $pokey, $pathkey);
  local($ftpkey, $ftpqkey, $mailkey, $mailqkey, %newlogins);
  local($popkey, $imapkey, $ogckey, $oglkey, $quotakey);
  local($lgkey, $new_othergroups, $orig_othergroups, $group, $userpath);
  local($sokey, $shellkey, $newshell, $errmsg, %errors);

  encodingIncludeStringLibrary("users");

  if ($g_form{'submit'} eq "$CANCEL_STRING") {
    if ($type eq "add") {
      $mesg = $USERS_CANCEL_ADD_TEXT;
    }
    elsif ($type eq "edit") {
      $mesg = $USERS_CANCEL_EDIT_TEXT;
    }
    elsif ($type eq "remove") {
      $mesg = $USERS_CANCEL_REMOVE_TEXT;
    }
    redirectLocation("iroot.cgi", $mesg); 
  }

  # perform error checking on form data
  if (($type eq "add") || ($type eq "edit")) {
    $ucount = 0;
    %errors = %newlogins = ();
    @selectedusers = split(/\|\|\|/, $g_form{'users'});
    foreach $user (@selectedusers) {
      $lkey = $user . "_login";
      $pkey = $user . "_password";
      $pckey = $user . "_password_confirm";
      $nkey = $user . "_name";
      $pokey = $user . "_path_option";
      $pathkey = $user . "_path";
      # get rid of evil spirits
      $g_form{$nkey} =~ s/\://g if ($g_form{$nkey});
      $g_form{$pokey} =~ s/\://g if ($g_form{$pokey});
      $g_form{$pathkey} =~ s/\://g if ($g_form{$pathkey});
      # set up some other info based on platform type
      if ($g_platform_type eq "virtual") {
        $ftpkey = $user . "_ftp";
        $ftpqkey = $user . "_ftpquota";
        $mailkey = $user . "_mail";
        $mailqkey = $user . "_mailquota";
        # be gone ye devils!
        $g_form{$ftpkey} =~ s/\://g if ($g_form{$ftpkey});
        $g_form{$ftpqkey} =~ s/\://g if ($g_form{$ftpqkey});
        $g_form{$mailkey} =~ s/\://g if ($g_form{$mailkey});
        $g_form{$mailqkey} =~ s/\://g if ($g_form{$mailqkey});
        # next if new and left blank
        if (($user =~ /__NEWUSER/) && 
            (!$g_form{$lkey}) && (!$g_form{$pkey}) && 
            (!$g_form{$pckey}) && (!$g_form{$nkey})) {
          $g_form{'users'} =~ s/^\Q$user\E$//;
          $g_form{'users'} =~ s/^\Q$user\E\|\|\|//;
          $g_form{'users'} =~ s/\|\|\|\Q$user\E\|\|\|/\|\|\|/;
          $g_form{'users'} =~ s/\|\|\|\Q$user\E$//;
          next;
        }
        # next if no change was made (only applicable for type == edit)
        if (($type eq "edit") && 
            ($g_form{$lkey} eq $g_users{$user}->{'login'}) &&
            (!$g_form{$pkey}) && (!$g_form{$pckey}) && 
            ($g_form{$nkey} eq $g_users{$user}->{'name'}) &&
            ($g_form{$pathkey} eq $g_users{$user}->{'path'}) &&
            ($g_form{$ftpkey} eq $g_users{$user}->{'ftp'}) &&
            ($g_form{$ftpqkey} eq $g_users{$user}->{'ftpquota'}) &&
            ($g_form{$mailkey} eq $g_users{$user}->{'mail'}) &&
            ($g_form{$mailqkey} eq $g_users{$user}->{'mailquota'})) {
          $g_form{'users'} =~ s/^\Q$user\E$//;
          $g_form{'users'} =~ s/^\Q$user\E\|\|\|//;
          $g_form{'users'} =~ s/\|\|\|\Q$user\E\|\|\|/\|\|\|/;
          $g_form{'users'} =~ s/\|\|\|\Q$user\E$//;
          next;
        }
      }
      else {
        # dedicated platform
        $sokey = $user . "_shell_option";
        $shellkey = $user . "_shell";
        $lgkey = $user . "_logingroup";
        $ftpkey = $user . "_ftp";
        $popkey = $user . "_pop";
        $imapkey = $user . "_imap";
        $ogckey = $user . "_othergroups";
        $oglkey = $user . "_othergrouplist";
        $quotakey = $user . "_quota";
        # be gone ye devils!
        $g_form{$shellkey} =~ s/\://g;
        $g_form{$lgkey} =~ s/\://g;
        $g_form{$oglkey} =~ s/\://g;
        # next if new and left blank
        if (($user =~ /__NEWUSER/) && 
            (!$g_form{$lkey}) && (!$g_form{$pkey}) &&
            (!$g_form{$pckey}) && (!$g_form{$nkey})) {
          $g_form{'users'} =~ s/^\Q$user\E$//;
          $g_form{'users'} =~ s/^\Q$user\E\|\|\|//;
          $g_form{'users'} =~ s/\|\|\|\Q$user\E\|\|\|/\|\|\|/;
          $g_form{'users'} =~ s/\|\|\|\Q$user\E$//;
          next;
        }
        # were any changes made?  build new and original group list to help
        # determine if we should skip the user or not
        $new_othergroups = "";
        if ($g_form{$ogckey}) {
          $new_othergroups = $g_form{$oglkey};
          $new_othergroups =~ s/[^A-Za-z0-9]/\,/g;
          $new_othergroups =~ s/\,+/\,/g;
        }
        $orig_othergroups = "";
        foreach $group (sort(keys(%g_groups))) {
          next if ($group eq "ftp");
          next if ($group eq "imap");
          next if ($group eq "pop");
          next if ($g_groups{$group}->{'gid'} == $g_users{$user}->{'gid'});
          next unless (defined($g_groups{$group}->{'m'}->{$user}));
          $orig_othergroups .= "$group,";
        }
        chop($orig_othergroups);
        # next if no change was made (only applicable for type == edit)
        $g_form{$ftpkey} = $g_form{$ftpkey} || 0;
        $g_form{$popkey} = $g_form{$popkey} || 0;
        $g_form{$imapkey} = $g_form{$imapkey} || 0;
        $userpath = $g_users{$user}->{'home'};
        $newshell = ($g_form{$sokey} eq "nologin") ?
                       "/sbin/nologin" : $g_form{$shellkey};
        if (($type eq "edit") && 
            ($g_form{$lkey} eq $g_users{$user}->{'login'}) &&
            (!$g_form{$pkey}) && (!$g_form{$pckey}) && 
            ($g_form{$nkey} eq $g_users{$user}->{'name'}) &&
            ($g_form{$pathkey} eq $userpath) &&
            ($g_form{$lgkey} eq groupGetNameFromID($g_users{$user}->{'gid'})) &&
            ($newshell eq $g_users{$user}->{'shell'}) &&
            ($g_form{$ftpkey} eq $g_users{$user}->{'ftp'}) &&
            ($g_form{$imapkey} eq $g_users{$user}->{'imap'}) &&
            ($g_form{$popkey} eq $g_users{$user}->{'pop'}) &&
            ($g_form{$quotakey} eq $g_users{$user}->{'quota'}) &&
            ($new_othergroups eq $orig_othergroups)) {
          $g_form{'users'} =~ s/^\Q$user\E$//;
          $g_form{'users'} =~ s/^\Q$user\E\|\|\|//;
          $g_form{'users'} =~ s/\|\|\|\Q$user\E\|\|\|/\|\|\|/;
          $g_form{'users'} =~ s/\|\|\|\Q$user\E$//;
          next;
        }
      }
      $ucount++;
      # login checks
      $g_form{$lkey} =~ tr/A-Z/a-z/;
      if ($g_form{$lkey}) {
        if ($g_form{$lkey} =~ /[^a-z0-9\.\-\_]/) {
          $errmsg = $USERS_ERROR_LOGIN_CONTAINS_INVALID_CHARS;
          $errmsg =~ s/__VALUE__/$g_form{$lkey}/;
          push(@{$errors{$user}}, $errmsg);
        }
        if ($g_form{$lkey} =~ /^[0-9\.\-]/) {
          $errmsg = $USERS_ERROR_LOGIN_MUST_BEGIN_WITH_LETTER;
          $errmsg =~ s/__VALUE__/$g_form{$lkey}/;
          push(@{$errors{$user}}, $errmsg);
        }
      }
      else {
        push(@{$errors{$user}}, $USERS_ERROR_LOGIN_IS_BLANK);
      }
      if (($g_form{$lkey} ne $user) && (defined($g_users{$g_form{$lkey}}))) {
        $errmsg = $USERS_ERROR_LOGIN_EXISTS;
        $errmsg =~ s/__VALUE__/$g_form{$lkey}/;
        push(@{$errors{$user}}, $errmsg);
      }
      if (defined($newlogins{$g_form{$lkey}})) {
        $errmsg = $USERS_ERROR_LOGIN_DUPLICATE;
        $errmsg =~ s/__VALUE__/$g_form{$lkey}/;
        push(@{$errors{$user}}, $errmsg);
      }
      $newlogins{$g_form{$lkey}} = "dau!";
      # password checks
      if (($type eq "add") || $g_form{$pkey} || $g_form{$pckey}) {
        if (!$g_form{$pkey}) {
          push(@{$errors{$user}}, $USERS_ERROR_PASSWORD_IS_BLANK);
        }
        if (!$g_form{$pckey}) {
          push(@{$errors{$user}}, $USERS_ERROR_PASSWORD_CONFIRM_IS_BLANK);
        }
      }
      if ($g_form{$pkey} ne $g_form{$pckey}) {
        push(@{$errors{$user}}, $USERS_ERROR_PASSWORD_MISMATCH);
      }
      if ($g_form{$pkey} || $g_form{$pckey}) {
        if ($g_form{$pkey} eq $g_form{$lkey}) {
          push(@{$errors{$user}}, $USERS_ERROR_PASSWORD_SAME_AS_LOGIN_ID);
        }
        if ($g_prefs{'security__enforce_strict_password_rules'} eq "yes") {
          if (length($g_form{$pkey}) < 7) {
            push(@{$errors{$user}}, $USERS_ERROR_PASSWORD_TOO_SHORT);
          }
          if ($g_form{$pkey} !~ /[^a-zA-Z]/) {
            push(@{$errors{$user}}, $USERS_ERROR_PASSWORD_ALL_LETTERS);
          }
          if (($g_form{$pkey} !~ /[a-z]/) || ($g_form{$pkey} !~ /[A-Z]/)) {
            push(@{$errors{$user}}, $USERS_ERROR_PASSWORD_NO_MIXED_CASE_LETTERS);
          }
        }
      }
      # full name check
      if (!$g_form{$nkey}) {
        push(@{$errors{$user}}, $USERS_ERROR_FULLNAME_IS_BLANK);
      }
      if ($type eq "add") {
        # path name check ... path cannot be blank if path_option is 
        # something other 'htdocs', 'vhosts', 'standard', or 'ftp'.  
        if (($g_form{$pokey} ne "htdocs") && ($g_form{$pokey} ne "vhosts") &&
            ($g_form{$pokey} ne "standard") && ($g_form{$pokey} ne "ftp")) {
          if ($g_form{$pathkey}) {
            $g_form{$pathkey} =~ s/\\/\//g;
          }
          else {
            push(@{$errors{$user}}, $USERS_ERROR_PATHNAME_IS_BLANK);
          }
        }
      }
      else {  
        # type eq "edit" ... path is required
        if ($g_form{$pathkey}) {
          $g_form{$pathkey} =~ s/\\/\//g;
        }
        else {
          push(@{$errors{$user}}, $USERS_ERROR_HOMEDIR_IS_BLANK);
        }
      }
      if ($g_platform_type eq "virtual") {
        # checks for user in "virtual" environment
        # privileges checks ... just scrub up disk quota fields
        $g_form{$ftpqkey} =~ s/[^0-9]//g;
        $g_form{$mailqkey} =~ s/[^0-9]//g;
      }
      else {
        # checks for user in "dedicated" environment
        # shell check ... shell cannot be blank if shell_option is 
        # something other than 'nologin'
        if ($g_form{$sokey} ne "nologin") {
          if ($g_form{$shellkey}) {
            $g_form{$shellkey} =~ s/\\/\//g;
          }
          else {
            push(@{$errors{$user}}, $USERS_ERROR_SHELL_IS_BLANK);
          }
        }
        # login group specification is required
        if (!$g_form{$lgkey}) {
          # Note: login group can be left blank.  if left blank, value 
          #       of login name is set for login group 
          #push(@{$errors{$user}}, $USERS_ERROR_LOGINGROUP_IS_BLANK);
          $g_form{$lgkey} = $g_form{$lkey};
        }
        # scrub up disk quota field
        $g_form{$quotakey} =~ s/[^0-9]//g;
      }
    }
    if (keys(%errors)) {
      usersDisplayForm($type, %errors);
    }
    if ($ucount == 0) {
      # nothing to do!
      usersNoChangesExist($type);
    }
    # print out a confirm form if necessary
    $g_form{'confirm'} = "no" unless ($g_form{'confirm'});
    if ($g_form{'confirm'} ne "yes") {
      usersConfirmChanges($type);
    }
  }
}

##############################################################################

sub usersCommitChanges
{
  local($type) = @_;
  local($user, @selectedusers, @userlist, @vhostlist);
  local($lkey, $pkey, $pckey, $nkey, $pokey, $pathkey, $dokey);
  local($ftpkey, $ftpqkey, $mailkey, $mailqkey, $vhostkey, $newpath);
  local($popkey, $imapkey, $ogckey, $oglkey, $quotakey);
  local($lgkey, $new_othergroups, $orig_othergroups, $group, $userpath);
  local($success_mesg, $output, $dotfile, $tdotfile, %aud);
  local($sokey, $shellkey, $newshell, @grouplist, $groupname);
  local($www_prefix);

  $www_prefix = initPlatformApachePrefix();

  if ($g_platform_type eq "dedicated") {
    %aud = usersLoadNewUserDefaults();
  }

  @selectedusers = split(/\|\|\|/, $g_form{'users'});
  foreach $user (@selectedusers) {
    if (($type eq "add") || ($type eq "edit")) {
      $lkey = $user . "_login";
      $pkey = $user . "_password";
      $pckey = $user . "_password_confirm";
      $nkey = $user . "_name";
      $pokey = $user . "_path_option";
      $pathkey = $user . "_path";
      $dokey = $user . "_directory_option";
      if ($g_platform_type eq "virtual") {
        $ftpkey = $user . "_ftp";
        $ftpqkey = $user . "_ftpquota";
        $mailkey = $user . "_mail";
        $mailqkey = $user . "_mailquota";
        # next if new and left blank
        next if (($user =~ /__NEWUSER/) && 
                 (!$g_form{$lkey}) && (!$g_form{$pkey}) && 
                 (!$g_form{$pckey}) && (!$g_form{$nkey}));
        # next if no change was made (only applicable for type == edit)
        next if (($type eq "edit") && 
                 ($g_form{$lkey} eq $g_users{$user}->{'login'}) &&
                 (!$g_form{$pkey}) && (!$g_form{$pckey}) && 
                 ($g_form{$nkey} eq $g_users{$user}->{'name'}) &&
                 ($g_form{$pathkey} eq $g_users{$user}->{'path'}) &&
                 ($g_form{$ftpkey} eq $g_users{$user}->{'ftp'}) &&
                 ($g_form{$ftpqkey} eq $g_users{$user}->{'ftpquota'}) &&
                 ($g_form{$mailkey} eq $g_users{$user}->{'mail'}) &&
                 ($g_form{$mailqkey} eq $g_users{$user}->{'mailquota'}));
      }
      else {
        # dedicated platform
        $sokey = $user . "_shell_option";
        $shellkey = $user . "_shell";
        $lgkey = $user . "_logingroup";
        $ftpkey = $user . "_ftp";
        $popkey = $user . "_pop";
        $imapkey = $user . "_imap";
        $ogckey = $user . "_othergroups";
        $oglkey = $user . "_othergrouplist";
        $quotakey = $user . "_quota";
        # next if new and left blank
        next if (($user =~ /__NEWUSER/) && 
                 (!$g_form{$lkey}) && (!$g_form{$pkey}) && 
                 (!$g_form{$pckey}) && (!$g_form{$nkey}));
        # were any changes made?  build new and original group list to help
        # determine if we should skip the user or not
        $new_othergroups = "";
        if ($g_form{$ogckey}) {
          $new_othergroups = $g_form{$oglkey};
          $new_othergroups =~ s/[^A-Za-z0-9]/\,/g;
          $new_othergroups =~ s/\,+/\,/g;
        }
        $orig_othergroups = "";
        foreach $group (sort(keys(%g_groups))) {
          next if ($group eq "ftp");
          next if ($group eq "imap");
          next if ($group eq "pop");
          next if ($g_groups{$group}->{'gid'} == $g_users{$user}->{'gid'});
          $orig_othergroups .= "$group,";
        }
        chop($orig_othergroups);
        # next if no change was made (only applicable for type == edit)
        $userpath = $g_users{$user}->{'home'};
        next if (($type eq "edit") && 
                 ($g_form{$lkey} eq $g_users{$user}->{'login'}) &&
                 (!$g_form{$pkey}) && (!$g_form{$pckey}) && 
                 ($g_form{$nkey} eq $g_users{$user}->{'name'}) &&
                 ($g_form{$pathkey} eq $userpath) &&
                 ($g_form{$shellkey} eq $g_users{$user}->{'shell'}) &&
                 ($g_form{$ftpkey} eq $g_users{$user}->{'ftp'}) &&
                 ($g_form{$imapkey} eq $g_users{$user}->{'imap'}) &&
                 ($g_form{$popkey} eq $g_users{$user}->{'pop'}) &&
                 ($g_form{$quotakey} eq $g_users{$user}->{'quota'}) &&
                 ($new_othergroups eq $orig_othergroups));
      }
      #
      # set new login value
      #
      if ($g_form{$lkey}) {
        $g_users{$user}->{'new_login'} = $g_form{$lkey};
      }
      else {
        # left blank -- error check should have caught this
        $g_users{$user}->{'new_login'} = $g_users{$user}->{'login'};
      }
      #
      # set new password value
      #
      if ($g_form{$pkey}) {
        $g_users{$user}->{'new_password'} = authCryptPassword($g_form{$pkey});
      }
      else {
        # left blank -- just use old password
        $g_users{$user}->{'new_password'} = $g_users{$user}->{'password'};
      }
      #
      # set new user full name
      #
      if ($g_form{$nkey}) {
        $g_users{$user}->{'new_name'} = $g_form{$nkey};
      }
      else {
        # left blank -- error check should have caught this
        $g_users{$user}->{'new_name'} = $g_users{$user}->{'name'};
      }
      #
      # set new path key; create path directories, etc
      #
      if ($g_form{$pokey} eq "htdocs") {
        $newpath = "$www_prefix/htdocs/$g_form{$lkey}";
      }
      elsif ($g_form{$pokey} eq "vhosts") {
        $newpath = "$www_prefix/vhosts/$g_form{$lkey}";
      }
      elsif ($g_form{$pokey} eq "standard") {
        if ($g_platform_type eq "virtual") {
          $newpath = "/usr/home";
        }
        else {
          $newpath = $aud{'home'} || "/home";
        }
        $newpath .= "/$g_form{$lkey}";
      }
      elsif ($g_form{$pokey} eq "ftp") {
        $newpath = "/ftp/pub/$g_form{$lkey}";
      }
      else {
        $newpath = $g_form{$pathkey};
      }
      if ($newpath) {
        $g_users{$user}->{'new_path'} = $newpath;
      }
      else {
        # left blank -- error check should have caught this
        $g_users{$user}->{'new_path'} = $g_users{$user}->{'home'};
      }
      #
      # set dedicated environment specific info
      # 
      if ($g_platform_type eq "dedicated") {
        # login shell
        if ($g_form{$sokey} eq "nologin") {
          $newshell = "/sbin/nologin";
        }
        else {
          $newshell = $g_form{$shellkey};
        }
        if ($g_form{$shellkey}) {
          $g_users{$user}->{'new_shell'} = $newshell;
        }
        else {
          # left blank -- error check should have caught this
          $g_users{$user}->{'new_shell'} = $g_users{$user}->{'shell'};
        }
        # login group
        if ($g_form{$lgkey}) {
          $g_users{$user}->{'new_logingroup'} = $g_form{$lgkey};
        }
        else {
          # left blank -- just set to same as login
          $g_users{$user}->{'new_logingroup'} = $g_users{$user}->{'new_login'};
        }
      }
      #
      # set up privileges (and groups)
      #
      if ($g_platform_type eq "virtual") { 
        # virtual server privileges
        $g_users{$user}->{'ftp_checked'} = $g_form{$ftpkey} || '0';
        $g_users{$user}->{'new_ftpquota'} = $g_form{$ftpqkey} || '0';
        $g_users{$user}->{'mail_checked'} = $g_form{$mailkey} || '0';
        $g_users{$user}->{'new_mailquota'} = $g_form{$mailqkey} || '0';
      }
      else {
        # dedicated server groups and privileges
        $g_users{$user}->{'ftp_checked'} = $g_form{$ftpkey} || '0';
        $g_users{$user}->{'pop_checked'} = $g_form{$popkey} || '0';
        $g_users{$user}->{'imap_checked'} = $g_form{$imapkey} || '0';
        $g_users{$user}->{'othergroups_checked'} = $g_form{$ogckey} || '0';
        $g_users{$user}->{'new_othergrouplist'} = $new_othergroups;
        $g_users{$user}->{'new_quota'} = $g_form{$quotakey} || '0';
      }
      # push user to list ... list is sent down to passwdSaveChanges
      push(@userlist, $user);
      # push user to vhostlist if applicable
      $vhostkey = $user . "_configvhost";
      if (($type eq "add") && $g_form{$vhostkey}) {
        push(@vhostlist, $g_form{$lkey}) 
      }
    }
    elsif ($type eq "remove") {
      # remove virtual host definition(s)?
      if ($g_form{'removevhost'}) {
        require "$g_includelib/vhost_util.pl";
        vhostHashInit();
        vhostMapHostnames($user);
        foreach $vhostkey (@{$g_users{$user}->{'vhostkeys'}}) {
          push(@vhostlist, $vhostkey);
          $g_vhosts{$vhostkey}->{'new_hostnames'} = "__REMOVE";
        }
      }
      # remove home directory?
      if ($g_form{'removeftp'}) {
        $userpath = $g_users{$user}->{'home'};
        if ((-e "$userpath") && ($userpath ne "/")) {
          # is the path really a directory or is it a symbolic link?
          if ((-d "$userpath") && (!(-l "$userpath"))) {
            usersRemoveHomeDirectory($userpath); 
          }
          else {
            unlink($userpath); 
          }
        }
      }
      # remove mail file(s)?
      if ($g_form{'removemail'}) {
        unlink("/usr/mail/$user") if (-e "/usr/mail/$user");
        unlink("/var/mail/$user") if (-e "/var/mail/$user");
      }
      # remove group entry?  (if platform == dedicated)
      if ($g_platform_type eq "dedicated") {
        $groupname = groupGetNameFromID($g_users{$user}->{'gid'});
        delete($g_groups{$groupname}->{'m'}->{$user});
        if (keys(%{$g_groups{$groupname}->{'m'}}) == 0) {
          # empty group; schedule it for removal by setting the
          # new_groupname to "__REMOVE"
          $g_groups{$groupname}->{'new_groupname'} = "__REMOVE";
          push(@grouplist, $groupname);
        } 
      }
      # finally, set the new_login to "__REMOVE".  why do I do this?  this 
      # is how the function passwdSaveChanges recognizes that this login
      # should be removed.  but why did I do that?  uh.... because.
      $g_users{$user}->{'new_login'} = "__REMOVE";
      push(@userlist, $user);
    }
  }
  $output = passwdSaveChanges(@userlist);

  if ($type eq "remove") {
    if ($#grouplist > -1) {
      require "$g_includelib/groups.pl";
      groupsSaveChanges(@grouplist);
    }
    if ($#vhostlist > -1) {
      require "$g_includelib/vhosts.pl";
      vhostsSaveChanges(@vhostlist);
    }
  }

  # manage home directories for selected users
  if (($type eq "add") || ($type eq "edit")) {
    foreach $user (@selectedusers) {
      $userpath = $g_users{$user}->{'home'};
      if ($user =~ /__NEWUSER/) {
        # create directory for new user 
        unless (-e "$g_users{$user}->{'new_path'}") {
          usersDirectoryCreate($g_users{$user}->{'new_path'});
          chown($g_users{$user}->{'uid'}, $g_users{$user}->{'gid'},
                $g_users{$user}->{'new_path'});
        }
        if (($g_platform_type eq "dedicated") && (-e "/usr/share/skel")) {
          # copy over default dot files from skel 
          opendir(SKEL, "/usr/share/skel");
          foreach $dotfile (readdir(SKEL)) {
            next unless ($dotfile =~ /^dot\./);
            $tdotfile = $dotfile;
            $tdotfile =~ s/^dot//;
            open(TFP, ">$g_users{$user}->{'new_path'}/$tdotfile");
            open(SFP, "/usr/share/skel/$dotfile") || next;
            while (read(SFP, $curchar, 1024)) {
              print TFP "$curchar";
            }
            close(SFP);
            close(TFP);
            chown($g_users{$user}->{'uid'}, $g_users{$user}->{'gid'},
                  "$g_users{$user}->{'new_path'}/$tdotfile");
          }
          closedir(SKEL);
        }
      }
      elsif ($g_users{$user}->{'new_path'} ne $userpath) {
        unless (-e "$g_users{$user}->{'new_path'}") {
          # path change for an existing user
          # depending on specified option on confirmation, either need to:
          #   1) rename old directory to new directory
          #   2) copy contents of old directory to new directory
          #   3) make new directory only
          if ($g_form{$dokey} eq "rename") {
            # rename old directory to new
            usersDirectoryRename($userpath, $g_users{$user}->{'new_path'});
          }
          elsif ($g_form{$dokey} eq "copy") {
            # copy old directory to new
            usersDirectoryCopy($userpath,
                               $g_users{$user}->{'new_path'},
                               $g_users{$user}->{'new_path'});
          }
          else {  
            # create new directory only
            unless (-e "$g_users{$user}->{'new_path'}") {
              usersDirectoryCreate($g_users{$user}->{'new_path'});
              chown($g_users{$user}->{'uid'}, $g_users{$user}->{'gid'},
                    $g_users{$user}->{'new_path'});
            }
          }
        }
      }
    }
  }

  # build a success mesg
  if ($type eq "add") {
    $success_mesg = $USERS_SUCCESS_ADD_TEXT;
  }
  elsif ($type eq "edit") {
    $success_mesg = $USERS_SUCCESS_EDIT_TEXT;
  }
  elsif ($type eq "remove") {
    $success_mesg = $USERS_SUCCESS_REMOVE_TEXT;
  }
  $success_mesg .= "\n$output" if ($output);

  if (($#vhostlist > -1) && ($type eq "remove")) {
    encodingIncludeStringLibrary("vhosts");
    $success_mesg =~ s/\s+$//g;
    $success_mesg .= "\n$VHOSTS_SUCCESS_REMOVE_TEXT";
    $success_mesg .= "\n$VHOSTS_SUCCESS_RESTART";
  }
  if (($#grouplist > -1) && ($type eq "remove")) {
    # append some kind of message here when groups are removed?
    # hmmm... maybe later
  }

  # redirect back to iroot or redirect forward to vhosts_add
  if (($#vhostlist > -1) && ($type ne "remove")) {
    # need to redirect to vhosts_add.cgi; set a special variable with
    # the set of users to config that will be read by redirectLocation()
    $g_form{'vhostuserlist'} = "";
    foreach $user (sort(@vhostlist)) {
      $g_form{'vhostuserlist'} .= "$user\|\|\|";
    }
    $g_form{'vhostuserlist'} =~ s/\|+$//;
    redirectLocation("vhosts_add.cgi", $success_mesg);
  }
  else {
    # redirect back to iroot.cgi
    redirectLocation("iroot.cgi", $success_mesg);
  }
}

##############################################################################

sub usersConfirmChanges
{
  local($type) = @_;
  local($title, $newpath, $text, $ogtext, $group);
  local($lkey, $pkey, $pckey, $nkey, $pokey, $pathkey, $dokey, $vhostkey);
  local($ftpkey, $ftpqkey, $mailkey, $mailqkey, $quotakey, $userpath);
  local($lgkey, $popkey, $imapkey, $ogckey, $oglkey);
  local($sokey, $shellkey, $newshell, %aud, $www_prefix);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("users");

  $www_prefix = initPlatformApachePrefix();

  if ($g_platform_type eq "dedicated") {
    %aud = usersLoadNewUserDefaults();
  }

  if ($type eq "add") {
    $subtitle = "$IROOT_ADD_TEXT: $CONFIRM_STRING";
  }
  elsif ($type eq "edit") {
    $subtitle = "$IROOT_EDIT_TEXT: $CONFIRM_STRING";
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_USERS_TITLE: $subtitle";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlText($USERS_CONFIRM_TEXT);
  htmlP();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "type", "value", $type);
  formInput("type", "hidden", "name", "confirm", "value", "yes");
  formInput("type", "hidden", "name", "users", "value", $g_form{'users'});
  htmlUL();
  @selectedusers = split(/\|\|\|/, $g_form{'users'});
  foreach $user (@selectedusers) {
    $lkey = $user . "_login";
    $pkey = $user . "_password";
    $pckey = $user . "_password_confirm";
    $nkey = $user . "_name";
    $pokey = $user . "_path_option";
    $pathkey = $user . "_path";
    $dokey = $user . "_directory_option";
    $vhostkey = $user . "_configvhost";
    formInput("type", "hidden", "name", $lkey, "value", $g_form{$lkey});
    formInput("type", "hidden", "name", $pkey, "value", $g_form{$pkey});
    formInput("type", "hidden", "name", $pckey, "value", $g_form{$pckey});
    formInput("type", "hidden", "name", $nkey, "value", $g_form{$nkey});
    formInput("type", "hidden", "name", $pokey, "value", $g_form{$pokey});
    formInput("type", "hidden", "name", $pathkey, "value", $g_form{$pathkey});
    formInput("type", "hidden", "name", $vhostkey, "value", $g_form{$vhostkey});
    if ($g_platform_type eq "virtual") {
      $ftpkey = $user . "_ftp";
      $ftpqkey = $user . "_ftpquota";
      $mailkey = $user . "_mail";
      $mailqkey = $user . "_mailquota";
      formInput("type", "hidden", "name", $ftpkey, "value", $g_form{$ftpkey});
      formInput("type", "hidden", "name", $ftpqkey, "value", $g_form{$ftpqkey});
      formInput("type", "hidden", "name", $mailkey, "value", $g_form{$mailkey});
      formInput("type", "hidden", "name", $mailqkey, 
                                  "value", $g_form{$mailqkey});
    }
    else {
      # dedicated platform
      $sokey = $user . "_shell_option";
      $shellkey = $user . "_shell";
      $lgkey = $user . "_logingroup";
      $ftpkey = $user . "_ftp";
      $popkey = $user . "_pop";
      $imapkey = $user . "_imap";
      $ogckey = $user . "_othergroups";
      $oglkey = $user . "_othergrouplist";
      $quotakey = $user . "_quota";
      formInput("type", "hidden", "name", $sokey, "value", $g_form{$sokey});
      formInput("type", "hidden", "name", $shellkey, 
                "value", $g_form{$shellkey});
      formInput("type", "hidden", "name", $lgkey, "value", $g_form{$lgkey});
      formInput("type", "hidden", "name", $ftpkey, "value", $g_form{$ftpkey});
      formInput("type", "hidden", "name", $popkey, "value", $g_form{$popkey});
      formInput("type", "hidden", "name", $imapkey, "value", $g_form{$imapkey});
      formInput("type", "hidden", "name", $ogckey, "value", $g_form{$ogckey});
      formInput("type", "hidden", "name", $oglkey, "value", $g_form{$oglkey});
      formInput("type", "hidden", "name", $quotakey, 
                                  "value", $g_form{$quotakey});
    }
    if ($g_form{$pokey} && ($g_form{$pokey} eq "htdocs")) {
      $newpath = "$www_prefix/htdocs/$g_form{$lkey}";
    }
    elsif ($g_form{$pokey} && ($g_form{$pokey} eq "vhosts")) {
      $newpath = "$www_prefix/vhosts/$g_form{$lkey}";
    }
    elsif ($g_form{$pokey} && ($g_form{$pokey} eq "standard")) {
      if ($g_platform_type eq "virtual") {
        $newpath = "/usr/home";
      }
      else {
        $newpath = $aud{'home'} || "/home";
      }
      $newpath .= "/$g_form{$lkey}";
    }
    elsif ($g_form{$pokey} && ($g_form{$pokey} eq "ftp")) {
      $newpath = "/ftp/pub/$g_form{$lkey}";
    }
    else {
      $newpath = $g_form{$pathkey};
    }
    $g_users{$user}->{'new_path'} = $newpath;
    htmlListItem();
    if ($user =~ /^__NEWUSER/) {
      # confirm addition
      htmlTextBold($USERS_CONFIRM_ADD_NEW);
      htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$USERS_LOGIN\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;$g_form{$lkey}");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$USERS_NAME\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;$g_form{$nkey}");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$USERS_PATH\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;$newpath");
      htmlTableDataClose();
      htmlTableRowClose();
      if ($g_platform_type eq "virtual") {
        # virtual platform privileges and quota
        if ($g_form{$ftpkey} || $g_form{$mailkey}) {
          htmlTableRow();
          htmlTableData("valign", "middle", "align", "left");
          htmlTextCode("&#160;&#160;$USERS_PRIVILEGES&#160;($USERS_QUOTA)\:");
          htmlTableDataClose();
          htmlTableData("valign", "middle", "align", "left");
          if ($g_form{$ftpkey}) {
            htmlTextCode("&#160;$USERS_FTP");
            if ($g_form{$ftpqkey}) {
              htmlTextCode("&#160;($g_form{$ftpqkey}&#160;$MEGABYTES)");
            }
            else {
              htmlTextCode("&#160;($USERS_QUOTA_NONE)");
            }
            if ($g_form{$mailkey}) {
              htmlTextCode(",");
            }
          }
          if ($g_form{$mailkey}) {
            htmlTextCode("&#160;$USERS_MAIL");
            if ($g_form{$mailqkey}) {
              htmlTextCode("&#160;($g_form{$mailqkey}&#160;$MEGABYTES)");
            }
            else {
              htmlTextCode("&#160;($USERS_QUOTA_NONE)");
            }
          }
          htmlTableDataClose();
          htmlTableRowClose();
        }
      }
      else {
        # dedicated platform group membership and quota
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextCode("&#160;&#160;$USERS_LOGIN_GROUP\:");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextCode("&#160;$g_form{$lgkey}");
        htmlTableDataClose();
        htmlTableRowClose();
        $text = "";
        $text .= "$USERS_GROUP_FTP," if ($g_form{$ftpkey});
        $text .= "$USERS_GROUP_POP," if ($g_form{$popkey});
        $text .= "$USERS_GROUP_IMAP," if ($g_form{$imapkey});
        if ($g_form{$ogckey}) {
          $ogtext = $g_form{$oglkey};
          $ogtext =~ s/[^A-Za-z0-9]/\,/g;
          $ogtext =~ s/\,+/\,/g;
          $text .= $ogtext;
        }
        $text =~ s/\,$//g;
        if ($text) {
          htmlTableRow();
          htmlTableData("valign", "middle", "align", "left");
          htmlTextCode("&#160;&#160;$USERS_OTHER_GROUPS\:");
          htmlTableDataClose();
          htmlTableData("valign", "middle", "align", "left");
          htmlTextCode("&#160;$text");
          htmlTableDataClose();
          htmlTableRowClose();
        }
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextCode("&#160;&#160;$USERS_QUOTA\:");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        if ($g_form{$quotakey}) {
          htmlTextCode("&#160;$g_form{$quotakey}&#160;$MEGABYTES");
        }
        else {
          htmlTextCode("&#160;$USERS_QUOTA_NONE");
        }
        htmlTableDataClose();
        htmlTableRowClose();
        if ($g_form{$sokey} eq "nologin") {
          $newshell = "/sbin/nologin";
        }
        else {
          $newshell = $g_form{$shellkey};
        }
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextCode("&#160;&#160;$USERS_SHELL\:");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextCode("&#160;$newshell");
        htmlTableDataClose();
        htmlTableRowClose();
      }
      htmlTableClose();
    }
    else {
      # confirm edition
      htmlTextBold($USERS_CONFIRM_CHANGE_FROM);
      htmlBR();
      # old user info table
      htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$USERS_LOGIN\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;$g_users{$user}->{'login'}");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$USERS_NAME\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;$g_users{$user}->{'name'}");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$USERS_PATH\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      $userpath = $g_users{$user}->{'home'};
      htmlTextCode("&#160;$userpath");
      htmlTableDataClose();
      htmlTableRowClose();
      if ($g_platform_type eq "virtual") {
        # virtual platform privileges and quota
        if ($g_users{$user}->{'ftp'} || $g_users{$user}->{'mail'}) {
          htmlTableRow();
          htmlTableData("valign", "middle", "align", "left");
          htmlTextCode("&#160;&#160;$USERS_PRIVILEGES&#160;($USERS_QUOTA)\:");
          htmlTableDataClose();
          htmlTableData("valign", "middle", "align", "left");
          if ($g_users{$user}->{'ftp'}) {
            htmlTextCode("&#160;$USERS_FTP");
            if ($g_users{$user}->{'ftpquota'}) {
              htmlTextCode("&#160;($g_users{$user}->{'ftpquota'}");
              htmlTextCode("&#160;$MEGABYTES)");
            }
            else {
              htmlTextCode("&#160;($USERS_QUOTA_NONE)");
            }
            if ($g_users{$user}->{'mail'}) {
              htmlTextCode(",");
            }
          }
          if ($g_users{$user}->{'mail'}) {
            htmlTextCode("&#160;$USERS_MAIL");
            if ($g_users{$user}->{'mailquota'}) {
              htmlTextCode("&#160;($g_users{$user}->{'mailquota'}");
              htmlTextCode("&#160;$MEGABYTES)");
            }
            else {
              htmlTextCode("&#160;($USERS_QUOTA_NONE)");
            }
          }
          htmlTableDataClose();
          htmlTableRowClose();
        }
      }
      else {
        # dedicated platform group membership and quota
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextCode("&#160;&#160;$USERS_LOGIN_GROUP\:");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        $group = groupGetNameFromID($g_users{$user}->{'gid'});
        htmlTextCode("&#160;$group");
        htmlTableDataClose();
        htmlTableRowClose();
        $text = "";
        $text .= "$USERS_GROUP_FTP," if ($g_users{$user}->{'ftp'});
        $text .= "$USERS_GROUP_POP," if ($g_users{$user}->{'pop'});
        $text .= "$USERS_GROUP_IMAP," if ($g_users{$user}->{'imap'});
        $ogtext = "";
        foreach $group (sort(keys(%g_groups))) {
          next if ($group eq "ftp");
          next if ($group eq "imap");
          next if ($group eq "pop");
          next unless (defined($g_groups{$group}->{'m'}->{$user}));
          next if ($g_groups{$group}->{'gid'} == $g_users{$user}->{'gid'});
          $ogtext .= "$group,";
        }
        if ($ogtext) {
          chop($ogtext);
          $text .= $ogtext;
        }
        $text =~ s/\,$//g;
        if ($text) {
          htmlTableRow();
          htmlTableData("valign", "middle", "align", "left");
          htmlTextCode("&#160;&#160;$USERS_OTHER_GROUPS\:");
          htmlTableDataClose();
          htmlTableData("valign", "middle", "align", "left");
          htmlTextCode("&#160;$text");
          htmlTableDataClose();
          htmlTableRowClose();
        }
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextCode("&#160;&#160;$USERS_QUOTA\:");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        if ($g_users{$user}->{'quota'}) {
          htmlTextCode("&#160;$g_users{$user}->{'quota'}&#160;$MEGABYTES");
        }
        else {
          htmlTextCode("&#160;$USERS_QUOTA_NONE");
        }
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextCode("&#160;&#160;$USERS_SHELL\:");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextCode("&#160;$g_users{$user}->{'shell'}");
        htmlTableDataClose();
        htmlTableRowClose();
      }
      htmlTableClose();
      # change user to....
      htmlTextBold($USERS_CONFIRM_CHANGE_TO);
      htmlBR();
      # new user info table
      htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$USERS_LOGIN\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;$g_form{$lkey}");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$USERS_NAME\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;$g_form{$nkey}");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;&#160;$USERS_PATH\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextCode("&#160;$newpath");
      htmlTableDataClose();
      htmlTableRowClose();
      if ($g_platform_type eq "virtual") {
        # virtual platform privileges and quota
        if ($g_form{$ftpkey} || $g_form{$mailkey}) {
          htmlTableRow();
          htmlTableData("valign", "middle", "align", "left");
          htmlTextCode("&#160;&#160;$USERS_PRIVILEGES&#160;($USERS_QUOTA)\:");
          htmlTableDataClose();
          htmlTableData("valign", "middle", "align", "left");
          if ($g_form{$ftpkey}) {
            htmlTextCode("&#160;$USERS_FTP");
            if ($g_form{$ftpqkey}) {
              htmlTextCode("&#160;($g_form{$ftpqkey}&#160;$MEGABYTES)");
            }
            else {
              htmlTextCode("&#160;($USERS_QUOTA_NONE)");
            }
            if ($g_form{$mailkey}) {
              htmlTextCode(",");
            }
          }
          if ($g_form{$mailkey}) {
            htmlTextCode("&#160;$USERS_MAIL");
            if ($g_form{$mailqkey}) {
              htmlTextCode("&#160;($g_form{$mailqkey}&#160;$MEGABYTES)");
            }
            else {
              htmlTextCode("&#160;($USERS_QUOTA_NONE)");
            }
          }
          htmlTableDataClose();
          htmlTableRowClose();
        }
      }
      else {
        # dedicated platform group membership and quota
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextCode("&#160;&#160;$USERS_LOGIN_GROUP\:");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextCode("&#160;$g_form{$lgkey}");
        htmlTableDataClose();
        htmlTableRowClose();
        $text = "";
        $text .= "$USERS_GROUP_FTP," if ($g_form{$ftpkey});
        $text .= "$USERS_GROUP_POP," if ($g_form{$popkey});
        $text .= "$USERS_GROUP_IMAP," if ($g_form{$imapkey});
        if ($g_form{$ogckey}) {
          $ogtext = $g_form{$oglkey};
          $ogtext =~ s/[^A-Za-z0-9]/\,/g;
          $ogtext =~ s/\,+/\,/g;
          $text .= $ogtext;
        }
        $text =~ s/\,$//g;
        if ($text) {
          htmlTableRow();
          htmlTableData("valign", "middle", "align", "left");
          htmlTextCode("&#160;&#160;$USERS_OTHER_GROUPS\:");
          htmlTableDataClose();
          htmlTableData("valign", "middle", "align", "left");
          htmlTextCode("&#160;$text");
          htmlTableDataClose();
          htmlTableRowClose();
        }
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextCode("&#160;&#160;$USERS_QUOTA\:");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        if ($g_form{$quotakey}) {
          htmlTextCode("&#160;$g_form{$quotakey}&#160;$MEGABYTES");
        }
        else {
          htmlTextCode("&#160;$USERS_QUOTA_NONE");
        }
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextCode("&#160;&#160;$USERS_SHELL\:");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        if ($g_form{$sokey} eq "nologin") {
          htmlTextCode("&#160;/sbin/nologin");
        }
        else {
          htmlTextCode("&#160;$g_form{$shellkey}");
        }
        htmlTableDataClose();
        htmlTableRowClose();
      }
      htmlTableClose();
      # check to see if path has changed
      $userpath = $g_users{$user}->{'home'};
      if ($g_users{$user}->{'new_path'} ne $userpath) {
        unless (-e "$g_users{$user}->{'new_path'}") {
          # path change for an existing user, prompt user for action:
          #   1) rename old directory to new directory
          #   2) copy contents of old directory to new directory 
          #   3) make new directory only
          htmlTable("cellpadding", "0", "cellspacing", "0", "border", "0");
          htmlTableRow();
          htmlTextCode("&#160; &#160;");
          $text = $USERS_CONFIRM_DIRECTORY_OPTION_ALERT;
          $text =~ s/__USER__/$user/;
          htmlTextCode(">>> $text");
          htmlTableRowClose();
          if ($userpath ne "/") {
            htmlTableRow();
            htmlTableData();
            htmlTextCode("&#160; &#160; &#160; ");
            formInput("type", "radio", "name", $dokey, "value", "rename",
                      "_OTHER_", "CHECKED");
            htmlTableDataClose();
            htmlTableData();
            $text = $USERS_CONFIRM_DIRECTORY_OPTION_RENAME;
            $text =~ s/__OLDDIR__/$userpath/;
            $text =~ s/__NEWDIR__/$g_form{$pathkey}/;
            htmlTextCode("&#160;$text");
            htmlTableDataClose();
            htmlTableRowClose();
          }
          htmlTableRow();
          htmlTableData();
          htmlTextCode("&#160; &#160; &#160; ");
          if ($userpath eq "/") {
            formInput("type", "radio", "name", $dokey, "value", "copy",
                      "_OTHER_", "CHECKED");
          }
          else {
            formInput("type", "radio", "name", $dokey, "value", "copy");
          }
          htmlTableDataClose();
          htmlTableData();
          $text = $USERS_CONFIRM_DIRECTORY_OPTION_COPY;
          $text =~ s/__OLDDIR__/$userpath/;
          $text =~ s/__NEWDIR__/$g_form{$pathkey}/;
          htmlTextCode("&#160;$text");
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableRow();
          htmlTableData();
          htmlTextCode("&#160; &#160; &#160; ");
          formInput("type", "radio", "name", $dokey, "value", "newdironly");
          htmlTableDataClose();
          htmlTableData();
          $text = $USERS_CONFIRM_DIRECTORY_OPTION_NEWDIRONLY;
          $text =~ s/__NEWDIR__/$g_form{$pathkey}/;
          htmlTextCode("&#160;$text");
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableClose();
          htmlP();
        }
      }
    }
  }
  htmlULClose();
  htmlP();
  formInput("type", "submit", "name", "submit", "value", $CONFIRM_STRING);
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  formClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub usersDirectoryCopy
{
  local($sourcepath, $targetpath, $origtargetpath) = @_;
  local($filename, $newsourcepath, $newtargetpath);
  local($linktarget, $curchar, $fmode, $fuid, $fgid);
  local(*CURDIR, *SOURCEFP, *TARGETFP);

  # function to copy existing home directory to new
  if (-e "$targetpath") {
    if (-d "$targetpath") {
      # return if directory already exists
      return;
    }
    else {
      # target exists, but is a file... remove first
      unlink($targetpath);
    }
  }

  # create the directory
  usersDirectoryCreate($targetpath);
  # now copy any files in the source directory
  opendir(CURDIR, "$sourcepath") || return;
  foreach $filename (readdir(CURDIR)) {
    next if (($filename eq ".") || ($filename eq ".."));
    $newsourcepath = "$sourcepath/$filename";
    $newtargetpath = "$targetpath/$filename";
    # don't get caught in a recursive loop
    next if ($newsourcepath eq $origtargetpath);
    # recurse or copy?
    if (-l "$newsourcepath") {
      # copy symbolic link
      ($fmode,$fuid,$fgid) = (lstat($newsourcepath))[2,4,5];
      $linktarget = readlink($newsourcepath);
      symlink($linktarget, $newtargetpath);
      chmod($fmode, $newtargetpath);
      chown($fuid, $fgid, $newtargetpath);
    }
    elsif (-d "$newsourcepath") {
      # recurse
      usersDirectoryCopy($newsourcepath, $newtargetpath, $origtargetpath);
    }
    else {
      # copy file
      ($fmode,$fuid,$fgid) = (stat($newsourcepath))[2,4,5];
      open(SOURCEFP, "$newsourcepath") || next;
      unless (open(TARGETFP, ">$newtargetpath")) {
        close(SOURCEFP);
        next;
      }
      while (read(SOURCEFP, $curchar, 1024)) {
        print TARGETFP "$curchar";
      }
      close(SOURCEFP);
      close(TARGETFP);
      chmod($fmode, $newtargetpath);
      chown($fuid, $fgid, $newtargetpath);
    }
  }
  closedir(CURDIR);
}

##############################################################################

sub usersDirectoryCreate
{
  local($targetpath) = @_;
  local(@subpaths, $index, $curpath);

  # function to create to home directory for a new or existing user
  if (-e "$targetpath") {
    if (-d "$targetpath") {
      # return if directory already exists
      return;
    }
    else {
      # target exists, but is a file... remove first
      unlink($targetpath);
    }
  }

  $targetpath =~ s/\/+$//;
  @subpaths = split(/\//, $targetpath);
  for ($index=0; $index<=$#subpaths; $index++) {
    next unless ($subpaths[$index]);
    $curpath .= "/$subpaths[$index]";
    $curpath =~ s/\/\//\//g;
    if (!(-d "$curpath")) {
      mkdir($curpath, 0755) ||
        irootResourceError($USERS_ACTIONS_CREATEDIR,
            "call to mkdir($curpath, 0755) in usersDirectoryCreate");
    }
    chmod(0755, $curpath);
  }
}

##############################################################################

sub usersDirectoryRename
{
  local($sourcepath, $targetpath) = @_;
  local($parentdir);

  # function to rename existing home directory to new directory
  # function to create to home directory for a new or existing user
  if (-e "$targetpath") {
    if (-d "$targetpath") {
      # return if directory already exists
      return;
    }
    else {
      # target exists, but is a file... remove first
      unlink($targetpath);
    }
  }

  # create any directories necessary to fulfill the request
  $parentdir = $targetpath;
  $parentdir =~ s/\/$//;
  $parentdir =~ s/[^\/]+$//g;
  usersDirectoryCreate($parentdir);

  # rename directory
  rename($sourcepath, $targetpath) ||
    irootResourceError($USERS_ACTIONS_RENAME,
      "call to rename($sourcepath, $targetpath) in usersDirectoryRename");
}

##############################################################################

sub usersDisplayForm
{
  local($type, %errors) = @_;
  local($title, $subtitle, $helptext, $buttontext, $mesg, $userlist);
  local($size3, $size16, $size20, $size30);
  local($key, $value, $okey, $ovalue);
  local(@selectedusers, $user, $index, $singleuser, $privstext);
  local($vhostexists, $mailexists, $javascript, $userpath);
  local($groupname, $grouplist, $num_system_users, %aud);
  local($donothide, $hostname, $www_prefix);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("users");

  $www_prefix = initPlatformApachePrefix();

  if ($g_platform_type eq "dedicated") {
    %aud = usersLoadNewUserDefaults();
    # need this for $FILEMANAGER_ACTIONS_VIEW
    encodingIncludeStringLibrary("filemanager");  
  }

  # set the new sort_by preference (if applicable)
  if ($g_form{'sort_submit'}) {
    if ($g_form{'sort_submit'} eq $USERS_SORT_BY_LOGIN) {
      $g_form{'sort_by'} = "";
    }
    elsif ($g_form{'sort_submit'} eq $USERS_SORT_BY_NAME) {
      $g_form{'sort_by'} = "name";
    }
    elsif ($g_form{'sort_submit'} eq $USERS_SORT_BY_PATH) {
      $g_form{'sort_by'} = "path";
    }
    elsif ($g_form{'sort_submit'} eq $USERS_SYSTEM_SORT_BY_UID) {
      $g_form{'sort_by'} = "uid";
    }
  }

  # set the new show_system_users preference (if applicable)
  if ($g_form{'su_submit'}) {
    if ($g_form{'su_submit'} eq $USERS_SYSTEM_HIDE) {
      $g_form{'show_system_users'} = "";
    }
    elsif ($g_form{'su_submit'} eq $USERS_SYSTEM_SHOW) {
      $g_form{'show_system_users'} = "yes";
    }
  }

  # reset sort_by eq uid if not showing system users
  if ($g_form{'sort_by'} && ($g_form{'sort_by'} eq "uid") && 
      ($g_form{'show_system_users'} ne "yes")) {
    $g_form{'sort_by'} = "";
  }

  @selectedusers = ();
  if ($type eq "add") {
    $subtitle = $IROOT_ADD_TEXT;
    if ($g_form{'users'}) {
      @selectedusers = split(/\|\|\|/, $g_form{'users'});
    }
    else {
      for ($index=1; $index<=$g_prefs{'iroot__num_newusers'}; $index++) {
        push(@selectedusers, "__NEWUSER$index"); 
        $userlist .= "__NEWUSER$index\|\|\|";
      }
      $userlist =~ s/\|+$//g;
      $g_form{'users'} = $userlist 
    }
    $helptext = $USERS_ADD_HELP_TEXT;
    $buttontext = $USERS_ADD_SUBMIT_TEXT;
  }
  elsif ($type eq "edit") {
    $subtitle = $IROOT_EDIT_TEXT;
    @selectedusers = split(/\|\|\|/, $g_form{'users'}) if ($g_form{'users'});
    $helptext = $USERS_EDIT_HELP_TEXT;
    $buttontext = $USERS_EDIT_SUBMIT_TEXT;
  }
  elsif ($type eq "remove") {
    $subtitle = $IROOT_REMOVE_TEXT;
    @selectedusers = split(/\|\|\|/, $g_form{'users'}) if ($g_form{'users'});
    $helptext = $USERS_REMOVE_HELP_TEXT;
    $buttontext = $USERS_REMOVE_SUBMIT_TEXT;
    $mailexists = 0;
  }
  elsif ($type eq "view") {
    $num_system_users = 0;
    $subtitle = $IROOT_VIEW_TEXT;
    if ($g_form{'users'}) {
      @selectedusers = split(/\|\|\|/, $g_form{'users'});
    }
    else {
      foreach $user (keys(%g_users)) {
        next if ($user =~ /^_.*root$/);
        if ($g_platform_type eq "virtual") {
          next if (($user eq "root") || ($user eq "__rootid") || 
                   ($user eq $g_users{'__rootid'}));
        }
        else {
          if (($g_users{$user}->{'uid'} < 1000) || 
              ($g_users{$user}->{'uid'} > 65533)) {
            $num_system_users++;
            next unless ($g_form{'show_system_users'} eq "yes");
          }
        }
        push(@selectedusers, $user);
      }
    }
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_USERS_TITLE: $subtitle";

  if ($#selectedusers == -1) {
    # oops... no users in selected user list.
    if (($type eq "edit") || ($type eq "remove")) {
      $singleuser = usersSelectForm($type);
      @selectedusers = ("$singleuser");
    }
    else {
      if ($g_platform_type eq "dedicated") {
        # no selected users... just populate with all users
        @selectedusers = keys(%g_users);
        $g_form{'show_system_users'} = "all";
        $donothide = 1;
      }
      # if no users in file then put up the empty file notice
      usersEmptyFile();
    }
  }

  if ($type ne "add") {
    require "$g_includelib/vhost_util.pl";
    vhostHashInit();
  }
  
  $size3 = formInputSize(3);
  $size16 = formInputSize(16);
  $size20 = formInputSize(20);
  $size30 = formInputSize(30);

  if (($g_platform_type eq "dedicated") && 
      (($type eq "add") || ($type eq "edit"))) {
    $javascript = javascriptOpenWindow();
  }

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title, "", $javascript);

  if (keys(%errors)) {
    htmlTextColorBold(">>> $IROOT_ERRORS_FOUND <<<", "#cc0000");
    htmlP();
  }

  # show some help
  if ($type ne "view") {
    htmlText($helptext);
    htmlP();
    if (($type eq "add") || ($type eq "edit")) {
      htmlText($USERS_LOGIN_HELP_TEXT);
      htmlP();
      $helptext = $USERS_PASSWORD_BASIC_HELP_TEXT;
      if (authSupportsMD5()) {
        $helptext =~ s/__LEN__/128/;
      }
      else {
        $helptext =~ s/__LEN__/8/;
      }
      htmlText("$helptext ");
      if ($g_prefs{'security__enforce_strict_password_rules'} eq "yes") {
        htmlText("$USERS_PASSWORD_SECURITY_HELP_TEXT ");
      }
      htmlText("$USERS_PASSWORD_CONFIRM_HELP_TEXT ");
      htmlP();
      htmlText($USERS_FULL_NAME_HELP_TEXT);
      htmlP();
      if ($g_platform_type eq "virtual") {
        htmlText($USERS_HOME_DIRECTORY_HELP_TEXT_VIRTUAL);
        htmlP();
        htmlText($USERS_PRIVILEGES_HELP_TEXT_VIRTUAL);
        htmlP();
      }
      else {
        htmlText($USERS_HOME_DIRECTORY_HELP_TEXT_DEDICATED);
        htmlP();
        htmlText($USERS_LOGIN_GROUP_HELP_TEXT);
        htmlP();
        htmlText($USERS_PRIVILEGES_HELP_TEXT_DEDICATED);
        htmlP();
        htmlText($USERS_SHELL_HELP_TEXT);
        htmlP();
      }
      if ($type eq "add") {
        htmlText($USERS_ADD_NEW_VIRTUALHOST_HELP_TEXT);
        htmlP();
      }
    }
  }

  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "view", "value", $type);
  formInput("type", "hidden", "name", "users", "value", $g_form{'users'});
  if (($#selectedusers == 0) || ($type eq "add") || ($type eq "edit")) {
    foreach $user (sort usersByPreference(@selectedusers)) {
      next if (($user eq "root") || ($user eq "__rootid") || 
               ($user eq $g_users{'__rootid'}));
      if (($#selectedusers > 0) && (($type eq "add") || ($type eq "edit"))) {
        # user separator (a fine gray line)
        htmlTable("width", "100%");
        htmlTableRow();
        htmlTableData();
        htmlTable("cellpadding", "0", "cellspacing", "0", 
                  "border", "0", "bgcolor", "#999999", "width", "100\%");
        htmlTableRow();
        htmlTableData();
        htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableClose();
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableClose();
        htmlBR();
      }
      if (($type eq "add") || ($type eq "edit")) {
        if ($type eq "add") {
          if ($#selectedusers > 0) {
            $subtitle = $USERS_LOGIN_PROFILE_NEW;
            $user =~ /__NEWUSER([0-9]*)/;
            $subtitle .= " \#$1";
            htmlTextBold($subtitle);
          }
        }
        else {
          $subtitle = $USERS_LOGIN_PROFILE_EXISTING;
          $subtitle =~ s/__USER__/\'$user\'/;
          htmlTextBold($subtitle);
        }
      }
      htmlUL();
      # spit out errors if any exist
      if ($#{$errors{$user}} > -1) {
        foreach $mesg (@{$errors{$user}}) {
          htmlTextColorBold(">>> $mesg <<<", "#cc0000");
          htmlBR();
        }
        htmlP();
      }
      # single user form table
      htmlTable("cellpadding", "0", "cellspacing", "0", "border", "0");
      htmlTableRow();
      htmlTableData("valign", "middle");
      htmlTextBold("$USERS_LOGIN\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      if ($type eq "remove") {
        htmlText($user);
      }
      elsif ($type eq "view") {
        if (($g_platform_type eq "dedicated") && 
            (($g_users{$user}->{'uid'} < 1000) ||
             ($g_users{$user}->{'uid'} > 65533))) {
          htmlText($user);
        }
        else {
          htmlAnchor("href", "users_edit.cgi?users=$user",
                     "title", "$IROOT_USERS_TITLE: $IROOT_EDIT_TEXT: $user");
          htmlAnchorText($user);
          htmlAnchorClose();
        }
      }
      else {
        $key = $user . "_login";
        $value = (defined($g_form{'sort_submit'}) ||
                  defined($g_form{'submit'})) ? $g_form{$key} : 
                                                $g_users{$user}->{'login'};
        formInput("name", $key, "size", $size16, "value", $value,
                  "maxlength", 16);
      }
      htmlTableDataClose();
      htmlTableRowClose();
      if (($type eq "add") || ($type eq "edit")) {
        # spacer
        htmlTableRow();
        htmlTableData("colspan", "2");
        htmlText("&#160;");
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableRow();
      }
      htmlTableData("valign", "middle");
      htmlTextBold("$USERS_PASSWORD\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      if (($type eq "remove") || ($type eq "view")) {
        htmlText("########");
      }
      else {
        $key = $user . "_password";
        $value = (defined($g_form{'sort_submit'}) ||
                  defined($g_form{'submit'})) ? $g_form{$key} : "";
        formInput("type", "password", "name", $key,
                  "size", $size16, "value", $value);
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("valign", "middle");
        htmlTextBold("&#160;($USERS_PASSWORD_CONFIRM\):");
        htmlTableDataClose();
        htmlTableData("valign", "middle");
        $key = $user . "_password_confirm";
        $value = (defined($g_form{'sort_submit'}) ||
                  defined($g_form{'submit'})) ? $g_form{$key} : "";
        formInput("type", "password", "name", $key,
                  "size", $size16, "value", $value);
      }
      htmlTableDataClose();
      htmlTableRowClose();
      if (($type eq "add") || ($type eq "edit")) {
        # spacer
        htmlTableRow();
        htmlTableData("colspan", "2");
        htmlText("&#160;");
        htmlTableDataClose();
        htmlTableRowClose();
      }
      htmlTableRow();
      htmlTableData("valign", "middle");
      htmlTextBold("$USERS_NAME\:");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      if (($type eq "remove") || ($type eq "view")) {
        $g_users{$user}->{'name'} =~ s/^\s+//;
        $g_users{$user}->{'name'} =~ s/\s+$//;
        $g_users{$user}->{'name'} =~ s/\s+/ /g;
        $g_users{$user}->{'name'} =~ s/ /\&\#160\;/g;
        htmlText($g_users{$user}->{'name'});
      }
      else {
        $key = $user . "_name";
        $value = (defined($g_form{'sort_submit'}) ||
                  defined($g_form{'submit'})) ? $g_form{$key} :
                                                $g_users{$user}->{'name'};
        formInput("name", $key, "size", $size20, "value", $value);
      }
      htmlTableDataClose();
      htmlTableRowClose();
      if (($type eq "add") || ($type eq "edit")) {
        # spacer
        htmlTableRow();
        htmlTableData("colspan", "2");
        htmlText("&#160;");
        htmlTableDataClose();
        htmlTableRowClose();
      }
      htmlTableRow();
      htmlTableData("valign", "middle");
      htmlTextBold("$USERS_PATH\: &#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      if (($type eq "remove") || ($type eq "view")) {
        $userpath = $g_users{$user}->{'home'};
        htmlText($userpath);
      }
      else {
        if ($type eq "add") {
          $key = $user . "_path_option";
          $value = (defined($g_form{'sort_submit'}) ||
                    defined($g_form{'submit'})) ? $g_form{$key} : "standard";
          formInput("type", "radio", "name", $key, "value", "standard",
                    "_OTHER_", (($value eq "standard") ? "CHECKED" : ""));
          if ($g_platform_type eq "virtual") {
            htmlText("/usr/home/LOGIN");
          }
          else {
            if ($aud{'home'}) { 
              htmlText("$aud{'home'}/LOGIN");
            }
            else {
              htmlText("/home/LOGIN");
            }
          }
          htmlText(" &#160; $USERS_HOME_DIRECTORY_HELP_STANDARD_TEXT");
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableRow();
          htmlTableData("valign", "middle");
          htmlText("&#160;");
          htmlTableDataClose();
          htmlTableData("valign", "middle");
          if ($g_platform_type eq "virtual") {
            formInput("type", "radio", "name", $key, "value", "vhosts",
                      "_OTHER_", (($value eq "vhosts") ? "CHECKED" : ""));
            htmlText("/usr/local/etc/httpd/vhosts/LOGIN");
            htmlText(" &#160; $USERS_HOME_DIRECTORY_HELP_SUBHOST_VHOSTS_TEXT");
            htmlBR();
            formInput("type", "radio", "name", $key, "value", "htdocs",
                      "_OTHER_", (($value eq "htdocs") ? "CHECKED" : ""));
            htmlText("$www_prefix/htdocs/LOGIN");
            htmlText(" &#160; $USERS_HOME_DIRECTORY_HELP_SUBHOST_HTDOCS_TEXT");
            htmlBR();
            formInput("type", "radio", "name", $key, "value", "ftp",
                      "_OTHER_", (($value eq "ftp") ? "CHECKED" : ""));
            htmlText("/ftp/pub/LOGIN");
            htmlText(" &#160; $USERS_HOME_DIRECTORY_HELP_FTP_TEXT");
            htmlBR();
          }
          formInput("type", "radio", "name", $key, "value", "custom",
                    "_OTHER_", (($value eq "custom") ? "CHECKED" : ""));
          $key = $user . "_path";
          $value = (defined($g_form{'sort_submit'}) ||
                    defined($g_form{'submit'})) ? $g_form{$key} :
                    $g_users{$user}->{'path'} || "/some/custom/LOGIN_path";
        }
        else {
          $key = $user . "_path";
          $value = (defined($g_form{'sort_submit'}) ||
                    defined($g_form{'submit'})) ? $g_form{$key} :
                                                  $g_users{$user}->{'home'};
        }
        formInput("name", $key, "size", $size30, "value", $value);
      }
      htmlTableDataClose();
      htmlTableRowClose();
      if (($type eq "add") || ($type eq "edit")) {
        # spacer
        htmlTableRow();
        htmlTableData("colspan", "2");
        htmlText("&#160;");
        htmlTableDataClose();
        htmlTableRowClose();
      }
      if ($g_platform_type eq "dedicated") {
        htmlTableRow();
        htmlTableData("valign", "middle");
        htmlTextBold("$USERS_LOGIN_GROUP\:");
        htmlTableDataClose();
        htmlTableData("valign", "middle");
        $groupname = groupGetNameFromID($g_users{$user}->{'gid'});
        if (($type eq "remove") || ($type eq "view")) {
          htmlText($groupname);
        }
        else {
          $key = $user . "_logingroup";
          $value = (defined($g_form{'sort_submit'}) ||
                    defined($g_form{'submit'})) ? $g_form{$key} : $groupname;
          formInput("name", $key, "size", $size16, "value", $value);
        }
        htmlTableDataClose();
        htmlTableRowClose();
        if (($type eq "add") || ($type eq "edit")) {
          # spacer
          htmlTableRow();
          htmlTableData("colspan", "2");
          htmlText("&#160;");
          htmlTableDataClose();
          htmlTableRowClose();
        }
      }
      htmlTableRow();
      htmlTableData("valign", "middle");
      if ($g_platform_type eq "virtual") {
        htmlTextBold("$USERS_PRIVILEGES&#160;($USERS_QUOTA): &#160;");
      }
      else {
        htmlTextBold("$USERS_OTHER_GROUPS: &#160;");
      }
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      if (($type eq "remove") || ($type eq "view")) {
        if ($g_platform_type eq "virtual") {
          if ($g_users{$user}->{'ftp'}) {
            htmlText($USERS_FTP);
            if ($g_users{$user}->{'ftpquota'}) {
              htmlText("&#160;($g_users{$user}->{'ftpquota'}&#160;$MEGABYTES)");
            }
            else {
              htmlText("&#160;($USERS_QUOTA_NONE)");
            }
          }
          if ($g_users{$user}->{'mail'}) {
            htmlText(",&#160;") if ($g_users{$user}->{'ftp'});
            htmlText($USERS_MAIL);
            if ($g_users{$user}->{'mailquota'}) {
              htmlText("&#160;($g_users{$user}->{'mailquota'}");
              htmlText("&#160;$MEGABYTES)");
            }                        
            else {
              htmlText("&#160;($USERS_QUOTA_NONE)");
            }
            $mailexists = 1 if (-e "/usr/mail/$user");
            $mailexists = 1 if (-e "/var/mail/$user");
          }
          if ((!($g_users{$user}->{'ftp'})) &&
              (!($g_users{$user}->{'mail'}))) {
            htmlText($USERS_QUOTA_NONE);
          }
        }
        else {
          $grouplist = "";
          foreach $groupname (sort(keys(%g_groups))) {
            if ($g_groups{$groupname}->{'gid'} == $g_users{$user}->{'gid'}) {
              # skip primary group in other group list
              next;
            }
            next unless (defined($g_groups{$groupname}->{'m'}->{$user}));
            $grouplist .= "$groupname,";
          }
          if ($grouplist) {
            chop($grouplist);
            htmlText($grouplist);
          }
          else {
            htmlText("&#171;$USERS_GROUP_NONE&#187;");
          }
        }
      }
      else {
        if ($g_platform_type eq "virtual") {
          $key = $user . "_ftp";
          $value = (defined($g_form{'sort_submit'}) ||
                    defined($g_form{'submit'})) ? $g_form{$key} :
                    $g_users{$user}->{'ftp'} || "";
          formInput("type", "checkbox", "name", $key, "value", "1",
                    "_OTHER_", ($value ? "CHECKED" : ""));
          htmlText($USERS_FTP);
          $key = $user . "_ftpquota";
          $value = (defined($g_form{'sort_submit'}) ||
                    defined($g_form{'submit'})) ? $g_form{$key} : 
                    $g_users{$user}->{'ftpquota'} || "0";
          htmlText("&#160;(&#160;");
          formInput("name", $key, "size", $size3, "value", $value);
          htmlText(")");
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableRow();
          htmlTableData("valign", "middle");
          htmlText("&#160;");
          htmlTableDataClose();
          htmlTableData("valign", "middle");
          $key = $user . "_mail";
          $value = (defined($g_form{'sort_submit'}) ||
                    defined($g_form{'submit'})) ? $g_form{$key} :
                    $g_users{$user}->{'mail'} || "";
          formInput("type", "checkbox", "name", $key, "value", "1",
                    "_OTHER_", ($value ? "CHECKED" : ""));
          htmlText($USERS_MAIL);
          $key = $user . "_mailquota";
          $value = (defined($g_form{'sort_submit'}) ||
                    defined($g_form{'submit'})) ? $g_form{$key} :
                    $g_users{$user}->{'mailquota'} || "0";
          htmlText("&#160;(&#160;");
          formInput("name", $key, "size", $size3, "value", $value);
          htmlText(")");
        }
        else {
          # dedicated platform
          $key = $user . "_ftp";
          $value = (defined($g_form{'sort_submit'}) ||
                    defined($g_form{'submit'})) ? $g_form{$key} :
                    $g_groups{'ftp'}->{'m'}->{$user} || "";
          formInput("type", "checkbox", "name", $key, "value", "1",
                    "_OTHER_", ($value ? "CHECKED" : ""));
          htmlText("$USERS_GROUP_FTP&#160;&#160;");
          $key = $user . "_imap";
          $value = (defined($g_form{'sort_submit'}) ||
                    defined($g_form{'submit'})) ? $g_form{$key} : 
                    $g_groups{'imap'}->{'m'}->{$user} || "";
          formInput("type", "checkbox", "name", $key, "value", "1",
                    "_OTHER_", ($value ? "CHECKED" : ""));
          htmlText("$USERS_GROUP_IMAP&#160;&#160;");
          $key = $user . "_pop";
          $value = (defined($g_form{'sort_submit'}) ||
                    defined($g_form{'submit'})) ? $g_form{$key} : 
                    $g_groups{'pop'}->{'m'}->{$user} || "";
          formInput("type", "checkbox", "name", $key, "value", "1",
                    "_OTHER_", ($value ? "CHECKED" : ""));
          htmlText("$USERS_GROUP_POP&#160;&#160;");
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableRow();
          htmlTableData();
          htmlText("&#160;");
          htmlTableData("valign", "middle");
          $grouplist = "";
          if (defined($g_form{'sort_submit'}) || defined($g_form{'submit'})) {
            $key = $user . "_othergroups";
            $value = $g_form{$key};
            $key = $user . "_othergrouplist";
            $grouplist = $g_form{$key};
          }
          else {
            foreach $groupname (sort(keys(%g_groups))) {
              next if ($groupname eq "ftp");
              next if ($groupname eq "imap");
              next if ($groupname eq "pop");
              if ($g_groups{$groupname}->{'gid'} == $g_users{$user}->{'gid'}) {
                # skip primary group in other group list
                next;
              }
              next unless (defined($g_groups{$groupname}->{'m'}->{$user}));
              $grouplist .= "$groupname,";
            }
            chop($grouplist) if ($grouplist);
            $value = ($grouplist ne "");
          }
          htmlTable("cellpadding", "0", "cellspacing", "0", "border", "0");
          htmlTableRow();
          htmlTableData("valign", "middle");
          $key = $user . "_othergroups";
          formInput("type", "checkbox", "name", $key, "value", "1",
                    "_OTHER_", ($value ? "CHECKED" : ""));
          htmlText("$USERS_GROUP_OTHER:&#160;");
          htmlTableDataClose();
          htmlTableData("valign", "middle");
          $key = $user . "_othergrouplist";
          formInput("name", $key, "size", $size20, "value", $grouplist);
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableClose();
          htmlTableDataClose();
          htmlTableData("valign", "middle");
          htmlTableDataClose();
          htmlTableRowClose();
        }
      }
      htmlTableDataClose();
      htmlTableRowClose();
      if ($g_platform_type eq "dedicated") {
        if (($type eq "add") || ($type eq "edit")) {
          # spacer
          htmlTableRow();
          htmlTableData("colspan", "2");
          htmlText("&#160;");
          htmlTableDataClose();
          htmlTableRowClose();
        }
        # quota for user in dedicated environment
        $key = $user . "_quota";
        htmlTableRow();
        htmlTableData("valign", "middle");
        htmlTextBold("$USERS_QUOTA\:");
        htmlTableDataClose();
        htmlTableData("valign", "middle");
        if (($type eq "remove") || ($type eq "view")) {
          if ($g_users{$user}->{'quota'}) {
            htmlText("$g_users{$user}->{'quota'}&#160;$MEGABYTES");
          }                        
          else {
            htmlText("&#171;$USERS_QUOTA_NONE&#187;");
          }
        }
        else {
          $value = (defined($g_form{'sort_submit'}) ||
                    defined($g_form{'submit'})) ? $g_form{$key} :
                    $g_users{$user}->{'quota'} || 0;
          formInput("name", $key, "size", $size3, "value", $value);
        }
        htmlTableDataClose();
        htmlTableRowClose();
        if (($type eq "add") || ($type eq "edit")) {
          # spacer
          htmlTableRow();
          htmlTableData("colspan", "2");
          htmlText("&#160;");
          htmlTableDataClose();
          htmlTableRowClose();
        }
        # shell for user in dedicated environment
        htmlTableRow();
        htmlTableData("valign", "middle");
        htmlTextBold("$USERS_SHELL\:");
        htmlTableDataClose();
        htmlTableData("valign", "middle");
        if (($type eq "remove") || ($type eq "view")) {
          htmlText($g_users{$user}->{'shell'});
        }
        else {
          $key = $user . "_shell";
          $okey = $user . "_shell_option";
          if (defined($g_form{'sort_submit'}) || defined($g_form{'submit'})) { 
            $value = $g_form{$key};
            $ovalue = $g_form{$okey};
          }
          elsif ($g_users{$user}->{'shell'}) {
            $value = $g_users{$user}->{'shell'};
            if ($value eq "/sbin/nologin") {
              $ovalue = "nologin";
              $value = "/bin/tcsh";
            }
            else {
              $ovalue = "loginallowed";
            }
          }
          else {
            $value = $aud{'shell'} || "/bin/tcsh";
            #$ovalue = ($value eq "/sbin/nologin") ? "nologin" : "loginallowed";
            $ovalue = "nologin";  # QA suggests default should be no shell
          }
          formInput("type", "radio", "name", $okey, "value", "nologin",
                    "_OTHER_", (($ovalue eq "nologin") ? "CHECKED" : "")); 
          htmlText($USERS_SHELL_DISABLE_TEXT);
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableRow();
          htmlTableData("valign", "middle");
          htmlText("&#160;");
          htmlTableDataClose();
          htmlTableData("valign", "middle");
          formInput("type", "radio", "name", $okey, "value", "loginallowed",
                    "_OTHER_", (($ovalue eq "loginallowed") ? "CHECKED" : ""));
          formInput("name", $key, "size", $size16, "value", $value);
          # print out link to shell file
          if (-e "/etc/shells") {
            htmlText("&#160;&#160;&#160;[&#160;");
            htmlAnchor("href", "fm_view.cgi?path=%2Fetc%2Fshells", 
                       "title", "$FILEMANAGER_ACTIONS_VIEW : /etc/shells",
                       "onClick",
                       "openWindow('fm_view.cgi?path=%2Fetc%2Fshells', 575, 375); return false");
            htmlAnchorText("/etc/shells");
            htmlAnchorClose();
            htmlText("&#160;]");
          }
        }
        htmlTableDataClose();
        htmlTableRowClose();
      }
      if ($type eq "add") {
        htmlTableRow();
        htmlTableData("colspan", "2");
        htmlText("&#160;");
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableRow();
        htmlTableData("valign", "middle");
        htmlTextBold("$USERS_VIRTUALHOST:&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle");
        $key = $user . "_configvhost";
        $value = (defined($g_form{'sort_submit'}) ||
                  defined($g_form{'submit'})) ? $g_form{$key} : "";
        formInput("type", "checkbox", "name", $key, "value", "1",
                  "_OTHER_", ($value ? "CHECKED" : ""));
        htmlText($USERS_ADD_NEW_VIRTUALHOST);
        htmlTableDataClose();
        htmlTableRowClose();
      }
      else {
        vhostMapHostnames($user);
        if (defined($g_users{$user}->{'hostnames'})) {
          $vhostexists = 1;
          if ($type eq "edit") {
            htmlTableRow();
            htmlTableData("colspan", "2");
            htmlText("&#160;");
            htmlTableDataClose();
            htmlTableRowClose();
          }
          htmlTableRow();
          htmlTableData("valign", "top");
          htmlTextBold("$USERS_VIRTUALHOST:&#160;");
          htmlTableDataClose();
          htmlTableData("valign", "middle");
          for ($index=0; $index<=$#{$g_users{$user}->{'hostnames'}};
               $index++) {
            $hostname = $g_users{$user}->{'hostnames'}[$index];
            $title = $URL_OPEN_STRING;
            $title =~ s/__URL__/http:\/\/$hostname\//;
            htmlAnchor("href", "http://$hostname/",
                       "target", "_blank", "title", $title);
            htmlAnchorText($hostname);
            htmlAnchorClose();
            if ($index != $#{$g_users{$user}->{'hostnames'}}) {
              htmlText(", ");
            }
          }
          htmlTableDataClose();
          htmlTableRowClose();
        }
      }
      htmlTableClose();
      if (($g_platform_type eq "dedicated") && ($num_system_users > 0)) {
        if ($g_form{'show_system_users'} ne "yes") {
          htmlBR();
          formInput("type", "submit", "name", "su_submit",
                    "value", $USERS_SYSTEM_SHOW);
        }
      }
      htmlULClose();
    }
  }
  else {
    # go through the selectedusers and see if any have virtual hosts
    $vhostexists = 0;
    foreach $user (@selectedusers) {
      vhostMapHostnames($user);
      if (defined($g_users{$user}->{'hostnames'})) {
        $vhostexists = 1;
      }
    }
    # spit out summary table when mulitple users selected and type is
    # equal to "remove" or "view"
    htmlTable();
    htmlTableRow();
    htmlTableData("valign", "bottom");
    htmlTextBold("$USERS_LOGIN&#160;");
    htmlTableDataClose();
    if (($g_platform_type eq "dedicated") && ($num_system_users > 0) &&
        ($g_form{'show_system_users'} eq "yes")) {
      htmlTableData("valign", "bottom", "align", "right");
      htmlTextBold("$USERS_SYSTEM_UID&#160;");
      htmlTableDataClose();
    }
    htmlTableData("valign", "bottom");
    htmlTextBold("$USERS_NAME&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "bottom");
    htmlTextBold("$USERS_PATH&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "bottom");
    if ($g_platform_type eq "virtual") {
      htmlTextBold("$USERS_PRIVILEGES&#160;($USERS_QUOTA)&#160;");
    }
    else {
      htmlNoBR();
      htmlTextBold("$USERS_GROUP&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableData("valign", "bottom");
      htmlTextBold("$USERS_QUOTA&#160;");
    }
    htmlTableDataClose();
    if ($vhostexists) {
      htmlTableData("valign", "bottom");
      htmlNoBR();
      htmlTextBold($USERS_VIRTUALHOST);
      htmlNoBRClose();
      htmlTableDataClose();
    }
    htmlTableRowClose();
    foreach $user (sort usersByPreference(@selectedusers)) {
      htmlTableRow();
      htmlTableData("valign", "top");
      if ($type eq "remove") {
        htmlText($user);
      }
      else {
        htmlAnchor("href", "users_view.cgi?users=$user", 
                   "title", "$USERS_VIEW_USER_PROFILE: $user");
        htmlAnchorText($user);
        htmlAnchorClose();
      }
      htmlText("&#160;");
      htmlTableDataClose();
      if (($g_platform_type eq "dedicated") && ($num_system_users > 0) &&
          ($g_form{'show_system_users'} eq "yes")) {
        htmlTableData("valign", "top", "align", "right");
        htmlText("$g_users{$user}->{'uid'}&#160;");
        htmlTableDataClose();
      }
      htmlTableData("valign", "top");
      $g_users{$user}->{'name'} =~ s/^\s+//;
      $g_users{$user}->{'name'} =~ s/\s+$//;
      $g_users{$user}->{'name'} =~ s/\s+/ /g;
      $g_users{$user}->{'name'} =~ s/ /\&\#160\;/g;
      htmlText("$g_users{$user}->{'name'}&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "top");
      htmlNoBR();
      $userpath = $g_users{$user}->{'home'};
      htmlText("$userpath&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableData("valign", "top");
      if ($g_platform_type eq "virtual") {
        # display virtual privileges
        $privstext = "";
        if ($g_users{$user}->{'ftp'}) {
          $privstext .= "$USERS_FTP&#160;";
          if ($g_users{$user}->{'ftpquota'}) {
            $privstext .= "($g_users{$user}->{'ftpquota'}";
            $privstext .= "&#160;$MEGABYTES)";
          }
          else {
            $privstext .= "($USERS_QUOTA_NONE)";
          }
        }
        if ($g_users{$user}->{'mail'}) {
          $privstext .= ",&#160;" if ($g_users{$user}->{'ftp'});
          $privstext .= "$USERS_MAIL&#160;";
          if ($g_users{$user}->{'mailquota'}) {
            $privstext .= "($g_users{$user}->{'mailquota'}";
            $privstext .= "&#160;$MEGABYTES)";
          }
          else {
            $privstext .= "($USERS_QUOTA_NONE)";
          }
          $mailexists = 1 if (-e "/usr/mail/$user");
          $mailexists = 1 if (-e "/var/mail/$user");
        }
        $privstext .= "&#160;";
        htmlText($privstext);
      }
      else {
        # display user login group and quota
        $groupname = groupGetNameFromID($g_users{$user}->{'gid'});
        htmlText("$groupname&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "top");
        if ($g_users{$user}->{'quota'}) {
          htmlText("$g_users{$user}->{'quota'}&#160;$MEGABYTES&#160;");
        }
        else {
          htmlText("&#171;$USERS_QUOTA_NONE&#187;&#160;");
        }
      }
      htmlTableDataClose();
      if ($vhostexists) {
        htmlTableData("valign", "top");
        if (defined($g_users{$user}->{'hostnames'})) {
          for ($index=0; $index<=$#{$g_users{$user}->{'hostnames'}};
               $index++) {
            $hostname = $g_users{$user}->{'hostnames'}[$index];
            $title = $URL_OPEN_STRING;
            $title =~ s/__URL__/http:\/\/$hostname\//;
            htmlAnchor("href", "http://$hostname/",
                       "target", "_blank", "title", $title);
            htmlAnchorText($hostname);
            htmlAnchorClose();
            if ($index != $#{$g_users{$user}->{'hostnames'}}) {
              htmlText(",");
              htmlBR();
            }
          }
        }
        else {
          htmlText("&#160;");
        }
        htmlTableDataClose();
      }
      htmlTableRowClose();
    }
    htmlTableClose();
  }
  if ($type eq "remove") {
    htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlText("&#160; &#160;");
    formInput("type", "checkbox", "name", "removeftp", "value", "yes");
    htmlText($USERS_REMOVE_HOME_DIRECTORY);
    if ($mailexists) {
      htmlText("&#160; &#160; &#160; &#160;");
      formInput("type", "checkbox", "name", "removemail", "value", "yes");
      htmlText($USERS_REMOVE_MAIL_FILE);
    }
    else {
      # set remove mail to 'yes' as a hidden field, it won't hurt anything
      formInput("type", "hidden", "name", "removemail", "value", "yes");
    }
    if ($vhostexists) {
      htmlText("&#160; &#160; &#160; &#160;");
      formInput("type", "checkbox", "name", "removevhost", "value", "yes");
      htmlText($USERS_REMOVE_VHOST_ENTRY);
    }
    htmlP();
  }
  if ($type ne "view") {
    formInput("type", "submit", "name", "submit", "value", $buttontext);
    formInput("type", "reset", "value", $RESET_STRING);
    formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  }
  if (($type ne "add") && ($#selectedusers > 0)) {
    htmlP();
    if ($g_form{'sort_by'}) {
      formInput("type", "submit", "name", "sort_submit",
                "value", $USERS_SORT_BY_LOGIN);
    }
    if ((!$g_form{'sort_by'}) || ($g_form{'sort_by'} ne "name")) {
      formInput("type", "submit", "name", "sort_submit",
                "value", $USERS_SORT_BY_NAME);
    }
    if ((!$g_form{'sort_by'}) || ($g_form{'sort_by'} ne "path")) {
      formInput("type", "submit", "name", "sort_submit",
                "value", $USERS_SORT_BY_PATH);
    }
    if ($type eq "view") {
      if (($g_platform_type eq "dedicated") && ($num_system_users > 0)) {
        if ($g_form{'show_system_users'} eq "yes") {
          if ($g_form{'sort_by'} ne "uid") {
            formInput("type", "submit", "name", "sort_submit",
                      "value", $USERS_SYSTEM_SORT_BY_UID);
          }
          unless ($donothide) {
            htmlP();
            formInput("type", "submit", "name", "su_submit",
                      "value", $USERS_SYSTEM_HIDE);
          }
        }
        else {
          htmlP();
          formInput("type", "submit", "name", "su_submit",
                    "value", $USERS_SYSTEM_SHOW);
        }
        formInput("type", "hidden", "name", "show_system_users", 
                  "value", $g_form{'show_system_users'});
        formInput("type", "hidden", "name", "sort_by", 
                  "value", $g_form{'sort_by'});
      }
    }
  }
  formClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub usersEmptyFile
{
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  if ($g_platform_type eq "virtual") {
    $USERS_ADMINISTRATIVE_ONLY_ERROR =~ s/__USER__/$g_users{'__rootid'}/g;
    htmlText($USERS_ADMINISTRATIVE_ONLY_ERROR);
  }
  else {
    htmlText($USERS_ADMINISTRATIVE_ONLY_ERROR_DEDICATED);
    htmlP();
    formOpen("method", "POST", "action", "users_view.cgi");
    formInput("type", "submit", "name", "su_submit", 
              "value", $USERS_SYSTEM_SHOW);
    formClose();
  }
  htmlP();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub usersLoadNewUserDefaults
{
  local(%defaults, $shell);

  # load up the adduser.conf defaults when in a dedicated environment
  if (($g_platform_type eq "dedicated") && (-e "/etc/adduser.conf")) {
    if (open(AUC, "/etc/adduser.conf")) {
      while (<AUC>) {
        chomp;
        # look for default home partition 
        if (/^home\s+=\s+?\"([^\"]*)?\"/i) {
          $defaults{'home'} = $1;
        }
        elsif (/^defaultshell\s+=\s+?\"(.*)?\"/i) {
          $shell = $1;
          if (-e "/bin/$shell") {
            $defaults{'shell'} = "/bin/$shell";
          }
          elsif (-e "/usr/bin/$shell") {
            $defaults{'shell'} = "/usr/bin/$shell";
          }
          elsif (-e "/usr/local/bin/$shell") {
            $defaults{'shell'} = "/usr/local/bin/$shell";
          }
        }
      }
      close(AUC);
    }
  }
  return(%defaults);
}

##############################################################################

sub usersNoChangesExist
{
  local($type) = @_;
  local($subtitle, $title);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("users");

  if ($type eq "add") {
    $subtitle = "$IROOT_ADD_TEXT";
  }
  elsif ($type eq "edit") {
    $subtitle = "$IROOT_EDIT_TEXT";
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_USERS_TITLE: $subtitle";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlText($USERS_NO_CHANGES_FOUND);
  htmlP();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub usersRebuild
{
  local($output);

  $output = passwdRebuildDB();
  redirectLocation("iroot.cgi", $output);
}

##############################################################################

sub usersRemoveHomeDirectory
{
  local($fullpath) = @_;
  local($filename, $ftp);
  local(*CURDIR);

  opendir(CURDIR, "$fullpath") || return;
  foreach $filename (readdir(CURDIR)) {
     next if (($filename eq ".") || ($filename eq ".."));
     $ftp = "$fullpath/$filename";
     if ((-d "$ftp") && (!(-l "$ftp"))) {
       usersRemoveHomeDirectory($ftp);
     }
     else {
       unlink($ftp);
     }
  }
  closedir(CURDIR);
  rmdir($fullpath);
}

##############################################################################

sub usersSelectForm
{
  local($type) = @_;
  local($title, $subtitle, $user, $ucount);
  local($num_system_users, $donothide);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("users");

  # set the new show_system_users preference (if applicable)
  if ($g_form{'su_submit'}) {
    if ($g_form{'su_submit'} eq $USERS_SYSTEM_HIDE) {
      $g_form{'show_system_users'} = "";
    }
    elsif ($g_form{'su_submit'} eq $USERS_SYSTEM_SHOW) {
      $g_form{'show_system_users'} = "yes";
    }
  }

  $subtitle = "$IROOT_USERS_TITLE: ";
  if ($type eq "edit") {
    $subtitle .= "$IROOT_EDIT_TEXT: $USERS_SELECT_TITLE";
  }
  elsif ($type eq "remove") {
    $subtitle .= "$IROOT_REMOVE_TEXT: $USERS_SELECT_TITLE";
  }

  $title = "$IROOT_MAINMENU_TITLE: $subtitle";

  # first check and see if there are more than one user to select
  $ucount = 0;
  foreach $user (keys(%g_users)) { 
    next if ($user =~ /^_.*root$/);
    next if (($user eq "root") || ($user eq "__rootid") || 
             ($user eq $g_users{'__rootid'}));
    if ($g_platform_type eq "dedicated") {
      if (($g_users{$user}->{'uid'} < 1000) ||
          ($g_users{$user}->{'uid'} > 65533)) {
        $num_system_users++;
        next unless ($g_form{'show_system_users'} eq "yes");
      }
    }
    $ucount++;
    $g_form{'users'} = $user;
  }

  if (($ucount == 0) && ($g_platform_type eq "dedicated")) {
    # if no non-system users counted... get count of all users
    $ucount = keys(%g_users);
    $donothide = 1;
    $g_form{'show_system_users'} = "yes";
  }

  if ($ucount == 0) {
    # oops.  no users in password file.
    usersEmptyFile();
  }
  elsif ($ucount == 1) {
    return($g_form{'users'});
  }

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlTextLargeBold($subtitle);
  htmlBR();
  if ($g_form{'select_submit'} && ($g_form{'select_submit'} eq $USERS_SELECT_TITLE)) {
    htmlBR();
    htmlTextColorBold(">>> $USERS_SELECT_HELP <<<", "#cc0000");
  }
  else {
    htmlText($USERS_SELECT_HELP);
  }
  htmlP();
  htmlUL();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "view", "value", $type);
  formSelect("name", "users", "size", formSelectRows($ucount),
             "_OTHER_", "MULTIPLE");
  foreach $user (sort usersByPreference(keys(%g_users))) { 
    next if (($user eq "root") || ($user eq "__rootid") ||
             ($user eq $g_users{'__rootid'}));
    if ($g_platform_type eq "dedicated") {
      if (($g_users{$user}->{'uid'} < 1000) ||
          ($g_users{$user}->{'uid'} > 65533)) {
        next unless ($g_form{'show_system_users'} eq "yes");
      }
    }
    formSelectOption($user, "$user ($g_users{$user}->{'name'})");
  }
  formSelectClose();
  htmlP();
  formInput("type", "submit", "name", "select_submit", 
            "value", $USERS_SELECT_TITLE);
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  if (($g_platform_type eq "dedicated") && ($num_system_users > 0)) {
    if ($g_form{'show_system_users'} eq "yes") {
      unless ($donothide) {
        htmlP();
        formInput("type", "submit", "name", "su_submit",
                  "value", $USERS_SYSTEM_HIDE);
      }
    }
    else {
      htmlP();
      formInput("type", "submit", "name", "su_submit",
                "value", $USERS_SYSTEM_SHOW);
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

