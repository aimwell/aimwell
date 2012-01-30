#
# group_util.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/group_util.pl,v 2.12.2.3 2006/05/01 23:12:01 rus Exp $
#
# group file subroutines
#

##############################################################################

sub groupGetNameFromID
{
  local($gid) = @_;
  local($groupname);

  return("") unless (defined($gid));

  foreach $groupname (keys(%g_groups)) {
    if ($g_groups{$groupname}->{'gid'} == $gid) {
      return($groupname);
    }
  }
  return($gid);
}

##############################################################################

sub groupGetNewGroupID
{
  local($gid, $found, $gkey);

  # get the next group id available above 1000
  for ($gid=1000; $gid<65533; $gid++) {
    $found = 0;
    foreach $gkey (keys(%g_groups)) {
      if ($g_groups{$gkey}->{'gid'} == $gid) {
        $found = 1;
        last;
      }
    }  
    return($gid) unless ($found);
  }
  return(-1);
}

##############################################################################

sub groupGetUsersGroupMembership
{
  local($user) = @_;
  local(@mgroups);

  @mgroups = ();
  foreach $groupname (keys(%g_groups)) {
    if (($g_groups{$groupname}->{'gid'} == $g_users{$user}->{'gid'}) ||
        (defined($g_groups{$groupname}->{'m'}->{$user}))) {
      push(@mgroups, $groupname);
    }
  }
  return(@mgroups);
}

##############################################################################

sub groupPurgeUserFromAllGroups
{
  local($user) = @_;
  local($locked, $curgroupdef);

  # backup old file
  require "$g_includelib/backup.pl";
  backupSystemFile("/etc/group") if (-e "/etc/group");

  # write out new group file... purging user from group lists as encountered
  # first check for a lock file
  if (-f "/etc/gtmptmp$$.$g_curtime") {
    groupResourceError(
        "-f '/etc/gtmptmp$$.$g_curtime' returned 1 in groupPurgeUser");
  }    
  # no obvious lock... use link() for atomicity to avoid race conditions
  open(PTMP, ">/etc/gtmptmp$$.$g_curtime") ||
    groupResourceError(
        "open(PTMP, '>/etc/gtmptmp$$.$g_curtime') in groupPurgeUser");
  close(PTMP);
  $locked = link("/etc/gtmptmp$$.$g_curtime", "/etc/gtmp");
  unlink("/etc/gtmptmp$$.$g_curtime");
  $locked || groupResourceError(
     "link('/etc/gtmptmp$$.$g_curtime', '/etc/gtmp') failed in groupPurgeUser");
  open(OGFP, "/etc/group") ||
    groupResourceError("open(OGFP, '/etc/group') in groupPurgeUser");
  open(NGFP, ">/etc/gtmp")  ||
    groupResourceError("open(NGFP, '>/etc/gtmp') in groupPurgeUser");
  flock(NGFP, 2);  # exclusive lock
  while (<OGFP>) {
    if (/^\#/) {
      print NGFP $_;
      next;
    }
    $curgroupdef = $_;
    $curgroupdef =~ s/\s+$//;
    if (($curgroupdef =~ /\:\Q$user\E$/) || 
        ($curgroupdef =~ /\:\Q$user\E\,/) ||
        ($curgroupdef =~ /\,\Q$user\E\,/) || 
        ($curgroupdef =~ /\,\Q$user\E$/)) {
      # purge user
      $curgroupdef =~ s/\:\Q$user\E$/\:/;
      $curgroupdef =~ s/\:\Q$user\E\,/\:/;
      $curgroupdef =~ s/\,\Q$user\E\,/\,/;
      $curgroupdef =~ s/\,\Q$user\E$//;
      $curgroupdef =~ s/\,\,/\,/g;
      $curgroupdef =~ s/\,$//;
    }
    print NGFP "$curgroupdef\n" ||
      groupResourceError("print to NGFP failed -- disk quota exceeded?");
  }
  close(OGFP);
  flock(NGFP, 8);  # unlock
  close(NGFP);
  rename("/etc/gtmp", "/etc/group") ||
     groupResourceError(
         "rename('/etc/gtmp', '/etc/group') in groupPurgeUserFromAllGroups");
  chmod(0644, "/etc/group");
}

##############################################################################

sub groupReadFile
{
  local($groupname, $passwd, $gid, $member, @members);

  open(GROUP, "/etc/group") ||
    groupResourceError("open(GROUP, '/etc/group') in groupReadFile");
  while (<GROUP>) {
    next if (/^\#/);
    chop;
    ($groupname, $passwd, $gid, $member) = split(/:/);
    $g_groups{$groupname}->{'group'} = $groupname;
    $g_groups{$groupname}->{'passwd'} = $passwd;
    $g_groups{$groupname}->{'gid'} = $gid;
    $g_groups{$groupname}->{'members'} = $member;
    if ($member) {
      @members = split(/\,/, $member);
      # hash each member of group for easy access later
      foreach $member (@members) {
        $g_groups{$groupname}->{'m'}->{$member} = "dau!";
      }
    }
  }
  close(GROUP);
}

##############################################################################
    
sub groupResourceError
{ 
  local($errmsg) = @_;
  local($os_error);

  $os_error = $!;
  
  # do some housekeeping
  unlink("/etc/gtmp");
    
  encodingIncludeStringLibrary("group");

  unless ($g_response_header_sent) {
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($GROUP_RESOURCE_ERROR_TITLE);
    htmlText($GROUP_RESOURCE_ERROR_TEXT);
    htmlP();
    if ($errmsg) {
      htmlUL();
      htmlTextCode($errmsg);
      htmlULClose(); 
      htmlP();
    }
    if ($os_error) {
      htmlUL();
      htmlTextCode("$os_error");
      htmlULClose();
      htmlP();
    }
    labelCustomFooter();
    exit(0);
  }
  else {
    print STDERR "$errmsg\n" if ($errmsg);
    print STDERR "$os_error\n" if ($os_error);
  }
}   

##############################################################################

sub groupSyncUserMembership
{
  local($user, $user_gid, $user_logingroup, $othergrouplist) = @_;
  local(@ogl, %othergroups, $groupname, $locked, $curgroupdef, $gid);
  local($addnewgroup);

  $addnewgroup = (defined($g_groups{$user_logingroup}->{'new'}));

  # split groups in other group list 
  @ogl = split(/\,/, $othergrouplist);

  # hash the other group names
  foreach $groupname (@ogl) {
    next unless ($groupname);  # just in case
    next if ($groupname eq $user_logingroup);  # not necessary
    $othergroups{$groupname} = "dau!"; 
  }

  # backup old file
  require "$g_includelib/backup.pl";
  backupSystemFile("/etc/group") if (-e "/etc/group");

  # write out new group file... purging user from group lists as encountered
  # first check for a lock file
  if (-f "/etc/gtmptmp$$.$g_curtime") {
    groupResourceError(
        "-f '/etc/gtmptmp$$.$g_curtime' returned 1 in groupPurgeUser");
  }    
  # no obvious lock... use link() for atomicity to avoid race conditions
  open(PTMP, ">/etc/gtmptmp$$.$g_curtime") ||
    groupResourceError(
        "open(PTMP, '>/etc/gtmptmp$$.$g_curtime') in groupPurgeUser");
  close(PTMP);
  $locked = link("/etc/gtmptmp$$.$g_curtime", "/etc/gtmp");
  unlink("/etc/gtmptmp$$.$g_curtime");
  $locked || groupResourceError(
     "link('/etc/gtmptmp$$.$g_curtime', '/etc/gtmp') failed in groupPurgeUser");
  open(OGFP, "/etc/group") ||
    groupResourceError("open(OGFP, '/etc/group') in groupPurgeUser");
  open(NGFP, ">/etc/gtmp")  ||
    groupResourceError("open(NGFP, '>/etc/gtmp') in groupPurgeUser");
  flock(NGFP, 2);  # exclusive lock
  while (<OGFP>) {
    if (/^\#/) {
      print NGFP $_;
      next;
    }
    $curgroupdef = $_;
    $curgroupdef =~ s/\s+$//;
    ($groupname,$gid) = (split(/:/))[0,2];
    if ($addnewgroup && ($user_gid < $gid)) {
      # add new group here
      print NGFP "$user_logingroup:\*:$user_gid:\n" ||
        groupResourceError("print to NGFP failed -- disk quota exceeded?");
      $addnewgroup = 0;
    }
    # sanitize the other group membership list in current group definition
    if (($curgroupdef =~ /\:\Q$user\E$/) || 
        ($curgroupdef =~ /\:\Q$user\E\,/) ||
        ($curgroupdef =~ /\,\Q$user\E\,/) || 
        ($curgroupdef =~ /\,\Q$user\E$/)) {
      # remove user or keep user in group def?
      if (defined($othergroups{$groupname})) {
        # keep... do nothing
      }
      else {
        # remove
        $curgroupdef =~ s/\:\Q$user\E$/\:/;
        $curgroupdef =~ s/\:\Q$user\E\,/\:/;
        $curgroupdef =~ s/\,\Q$user\E\,/\,/;
        $curgroupdef =~ s/\,\Q$user\E$//;
        $curgroupdef =~ s/\,\,/\,/g;
        $curgroupdef =~ s/\,$//;
      }
    }
    elsif (defined($othergroups{$groupname})) {
      $curgroupdef .= "," unless ($curgroupdef =~ /\:$/);
      $curgroupdef .= $user;
    }
    print NGFP "$curgroupdef\n" ||
      groupResourceError("print to NGFP failed -- disk quota exceeded?");
  }
  # append any new groups
  if ($addnewgroup) {
    print NGFP "$user_logingroup:\*:$user_gid:\n" ||
        groupResourceError("print to NGFP failed -- disk quota exceeded?");
  }
  # close the filehandles, unlock, etc
  close(OGFP);
  flock(NGFP, 8);  # unlock
  close(NGFP);
  rename("/etc/gtmp", "/etc/group") ||
     groupResourceError(
         "rename('/etc/gtmp', '/etc/group') in groupPurgeUserFromAllGroups");
  chmod(0644, "/etc/group");
}

##############################################################################
# eof
  
1;

