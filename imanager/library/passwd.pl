#
# passwd.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/passwd.pl,v 2.12.2.10 2006/04/25 19:48:25 rus Exp $
#
# passwd file subroutines
#

##############################################################################

sub passwdGetNewUserID
{
  local($uid, $found, $ukey);

  # get the next user id available above 1000
  for ($uid=1000; $uid<=65533; $uid++) {
    $found = 0;
    foreach $ukey (keys(%g_users)) {
      if ($g_users{$ukey}->{'uid'} == $uid) {
        $found = 1;
        last;
      }
    }
    return($uid) unless ($found);
  }
  return(-1);
}

##############################################################################

sub passwdReadFile
{
  local($pfile, $password, $uid, $gid);
  local($name, $path, $shell, $privileges);
  local($warning, $index, $groupname, %validshells);

  if ($g_platform_type eq "virtual") {
    $pfile = "/etc/passwd";
    # figure out who the 'administrative' user is... if applicable
    if (open(ID, "/etc/id")) {
      $g_users{'__rootid'} = <ID>;
      close(ID);
      chomp($g_users{'__rootid'});
    }
  }
  else {
    $pfile = "/etc/master.passwd";
    require "$g_includelib/quota.pl";
    if (open(SFP, "/etc/shells")) {
      while (<SFP>) {
        next unless (/^\//);
        $shell = $_;
        chomp($shell);
        $validshells{$shell} = "dau!";
      }
      close(SFP);
    }
  }

  open(PASSWD, "$pfile") ||
      passwdResourceError("open(PASSWD, $pfile) in passwdReadFile");
  while (<PASSWD>) {
    next if (/^\#/);
    chop;
    if ($g_platform_type eq "virtual") {
      ($login, $password, $uid, $gid, $name, $path, $privileges) = split(/:/); 
      $shell = "";
    }
    else {
      ($login, $password, $uid, $gid, $name, $path, $shell) = 
                                                  (split(/:/))[0,1,2,3,7,8,9];
    }
    # no need to load up information about all of the users in the 
    # password file; only load up in memory what is required
    if (($g_auth{'login'} ne "root") &&
        ($g_auth{'login'} !~ /^_.*root$/) &&
        ($g_auth{'login'} ne $g_users{'__rootid'}) &&
        (!(defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}})))) {
      next unless ($login eq $g_auth{'login'});
    }
    if (defined($g_users{$login})) {
      $warning = $PASSWD_WARNING_DUPLICATE_LOGIN;
      $warning =~ s/__LOGIN__/$login/g;
      print STDERR "$warning\n";
      next;
    }
    $g_users{$login}->{'login'} = $login;
    $g_users{$login}->{'password'} = $password;
    if ($g_platform_type eq "virtual") {
      # print out some warnings and set uid and gid appropriately
      if ($login eq "root") {
        if ($uid != 0) {
          $warning = $PASSWD_WARNING_ROOT_UID;
          $warning =~ s/__UID__/$uid/g;
          print STDERR "$warning\n";
        }
        if (($gid != 0) && ($gid != $g_gid)) {
          $warning = $PASSWD_WARNING_ROOT_GID;
          $warning =~ s/__GID__/$gid/g;
          print STDERR "$warning\n";
        }
        $g_users{$login}->{'uid'} = 0;
        $g_users{$login}->{'gid'} = 0;
      }
      else {
        if ($uid != $g_uid) {
          $warning = $PASSWD_WARNING_NONROOT_UID;
          $warning =~ s/__UID__/$uid/g;
          $warning =~ s/__EUID__/$g_uid/g;
          $warning =~ s/__LOGIN__/$login/g;
          print STDERR "$warning\n";
        }
        if ($gid != $g_gid) {
          $warning = $PASSWD_WARNING_NONROOT_GID;
          $warning =~ s/__GID__/$gid/g;
          $warning =~ s/__EGID__/$g_gid/g;
          $warning =~ s/__LOGIN__/$login/g;
          print STDERR "$warning\n";
        }
        $g_users{$login}->{'uid'} = $g_uid;  # the global virtual user id
        $g_users{$login}->{'gid'} = $g_gid;  # the global virtual group id
      }
    }
    else {
      # dedicated server environment
      $g_users{$login}->{'uid'} = $uid;
      $g_users{$login}->{'gid'} = $gid;
      $groupname = groupGetNameFromID($gid);
      $g_groups{$groupname}->{'m'}->{$login} = "dau!";
    }
    # gecos (name)
    $g_users{$login}->{'name'} = $name;
    # shell
    $g_users{$login}->{'shell'} = $shell;
    # home directory (path)
    $path =~ s/\/$//;  # take out trailing slashes
    $path = "/" unless ($path);
    $g_users{$login}->{'path'} = $path;
    $g_users{$login}->{'home'} = $path;
    $g_users{$login}->{'chroot'} = 1;
    # in a dedicated environment; certain users are allowed access to
    # the entire directory file structure such as root users (uid == 0)
    # or users that are part of the 'wheel' group or any user with a 
    # valid shell found in /etc/shells.  
    if (($g_platform_type eq "dedicated") &&
        (($g_users{$login}->{'uid'} == 0) ||
         (defined($g_groups{'wheel'}->{'m'}->{$login})) ||
         (defined($validshells{$g_users{$login}->{'shell'}})))) {
      $g_users{$login}->{'path'} = "/";
      $g_users{$login}->{'chroot'} = 0;
    }
    # privileges
    if ($g_platform_type eq "virtual") {
      # virtual user privileges
      $g_users{$login}->{'ftp'} = ($privileges =~ /ftp/);
      $g_users{$login}->{'ftpquota'} = 0;
      if (($g_users{$login}->{'ftp'}) && ($privileges =~ /ftp,([0-9]*)/)) {
        $g_users{$login}->{'ftpquota'} = $1;
      }
      $g_users{$login}->{'mail'} = ($privileges =~ /mail/);
      $g_users{$login}->{'mailquota'} = 0;
      if (($g_users{$login}->{'mail'}) && ($privileges =~ /mail,([0-9]*)/)) {
        $g_users{$login}->{'mailquota'} = $1;
      }
      $g_users{$login}->{'imap'} = 0;  # just for good measure
      if ($login eq "root") {
        # root gets access to everything
        $g_users{$login}->{'ftp'} = 1;
        $g_users{$login}->{'mail'} = 1;
      }
    }
    else {
      # populate privileges and quota with "real" information from server
      $g_users{$login}->{'ftp'} = 0;   # special group 'ftp'
      $g_users{$login}->{'imap'} = 0;  # special group 'imap'
      $g_users{$login}->{'pop'} = 0;   # special group 'pop'
      $g_users{$login}->{'mail'} = 0;  # for historical purposes
      if (defined($g_groups{'ftp'}->{'m'}->{$login})) {
        $g_users{$login}->{'ftp'} = 1;
      }
      if (defined($g_groups{'imap'}->{'m'}->{$login})) {
        $g_users{$login}->{'imap'} = 1;
        $g_users{$login}->{'mail'} = 1;
      }
      if (defined($g_groups{'pop'}->{'m'}->{$login})) {
        $g_users{$login}->{'pop'} = 1;
        $g_users{$login}->{'mail'} = 1;
      }
      # set both ftp and mail quotas to be user's server quota (if exists)
      if (($login eq $g_auth{'login'}) ||
          ($ENV{'SCRIPT_NAME'} =~ /wizards\/users_.*.cgi/) ||
          (($ENV{'SCRIPT_NAME'} =~ /wizards\/profile.cgi/) &&
           (($g_form{'ssa'} || $g_form{'sua'})))) {
        $quota = quotaGetLimit($g_users{$login}->{'uid'});
      }
      $quota /= 1024;  # convert to MB
      $g_users{$login}->{'quota'} = $quota;
      $g_users{$login}->{'ftpquota'} = $quota;   # for historical purposes
      $g_users{$login}->{'mailquota'} = $quota;  # for historical purposes
      if ($login eq "root") {
        # root gets access to everything
        $g_users{$login}->{'ftp'} = 1;
        $g_users{$login}->{'imap'} = 1;
        $g_users{$login}->{'pop'} = 1;
        $g_users{$login}->{'mail'} = 1;
      }
    }
  }
  close(PASSWD);

  if ($g_platform_type eq "virtual") {
    # open up the vpriv.conf file if applicable
    if (-e "/etc/vpriv.conf") {
      open(VPRIV, "/etc/vpriv.conf");
      while (<VPRIV>) {
        chop;
        $index = index($_, ":"); 
        $login = substr($_, 0, $index);
        # no need to load up information about all of the users in the 
        # password file; only load up in memory what is required
        if (($g_auth{'login'} ne "root") &&
            ($g_auth{'login'} !~ /^_.*root$/) &&
            ($g_auth{'login'} ne $g_users{'__rootid'}) &&
            (!(defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}})))) {
          next unless ($login eq $g_auth{'login'});
        }
        $privileges = substr($_, $index+1);
        $g_users{$login}->{'ftp'} = ($privileges =~ /ftp/);
        $g_users{$login}->{'ftpquota'} = 0;
        if (($g_users{$login}->{'ftp'}) && ($privileges =~ /ftp,([0-9]*)/)) {
          $g_users{$login}->{'ftpquota'} = $1;
        }
        $g_users{$login}->{'mail'} = ($privileges =~ /mail/);
        $g_users{$login}->{'mailquota'} = 0;
        if (($g_users{$login}->{'mail'}) && ($privileges =~ /mail,([0-9]*)/)) {
          $g_users{$login}->{'mailquota'} = $1;
        }
      }
      close(VPRIV);
    }
    # open up the shadow file if applicable
    if ((-e "/etc/shadow") &&
        (($g_platform_os =~ /sunos/) || ($g_platform_os =~ /solaris/))) {
      chmod(0600, "/etc/shadow");  # just for good measure
      open(SHADOW, "/etc/shadow");
      while (<SHADOW>) {
        chop;
        ($login, $password) = (split(/\:/))[0,1];
        # no need to load up information about all of the users in the 
        # password file; only load up in memory what is required
        if (($g_auth{'login'} ne "root") &&
            ($g_auth{'login'} !~ /^_.*root$/) &&
            ($g_auth{'login'} ne $g_users{'__rootid'}) &&
            (!(defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}})))) {
          next unless ($login eq $g_auth{'login'});
        }
        $g_users{$login}->{'password'} = $password;
      }
      close(SHADOW);
    }
  }
}

##############################################################################

sub passwdRebuildDB
{
  local($ucount, $output, $user, $command);

  initPlatformLocalBin();
  if (($g_platform_os =~ /sunos/) || ($g_platform_os =~ /solaris/)) {
    if (-e "/etc/shadow") {
      # backup old file
      require "$g_includelib/backup.pl";
      backupSystemFile("/etc/shadow");
      chmod(0600, "/etc/shadow");  # just for good measure (overkill?)
    }
    # run pwconv
    $command = "/usr/sbin/pwconv";
    open(PFP, "$command 2>&1 |") ||
      passwdResourceError("call to open(PFP, $command) in passwdRebuildDB");
    $output = "";
    while (<PFP>) {
      $output .= $_;
    }
    close(PFP);
  }
  else {
    # run pwd_mkdb
    if ($g_platform_type eq "virtual") {
      $command = "$g_localbin/pwd_mkdb";
    }
    else {
      $command = "/usr/sbin/pwd_mkdb";
    }
    if ($g_platform_os =~ /freebsd/) {
      $command .= " -V" if ($g_platform_type eq "virtual");
      $command .= " -d /etc";
    }
    if ($g_platform_type eq "virtual") {
      $command .= " /etc/passwd";
    }
    else {
      $command .= " /etc/master.passwd";
    }
    open(PFP, "$command 2>&1 |") ||
      passwdResourceError("call to open(PFP, $command) in passwdRebuildDB");
    $output = "";
    while (<PFP>) {
      $output .= $_;
    }
    close(PFP);
  }

  $ucount = 0;
  open(PASSWD, "/etc/passwd");
  while (<PASSWD>) {
    next if (/^\#/);
    $ucount++;
  }
  close(PASSWD);

  # default output language from pwd_mkdb is english... change this?
  $output .= "/etc/passwd: $ucount users\n";
  return($output);
}

##############################################################################

sub passwdResourceError
{
  local($errmsg) = @_;
  local($os_error);

  $os_error = $!;

  # do some housekeeping
  unlink("/etc/ptmp");
  unlink("/etc/vtmp");

  unless ($g_response_header_sent) {
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($PASSWD_RESOURCE_ERROR_TITLE);
    htmlText($PASSWD_RESOURCE_ERROR_TEXT);
    htmlP();
    if ($errmsg) {
      htmlUL();
      htmlTextCode($errmsg);
      htmlULClose();
      htmlP();
    }
    if ($os_error) {
      htmlUL();
      htmlTextCode($os_error);
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

sub passwdSaveChanges
{
  local(@user_ids) = @_;
  local($user, %entries, %vprivs, $entry, $newentry, $curentry);
  local($mylogin, $mypasswd, $myname, $mypath, $myshell);
  local($myprivs, $mygroups, $myuid, $mygid);
  local(@passwdfiles, $pfile, $locked, $match);
  local($output);

  foreach $user (@user_ids) {
    # sift through the login ids one by one
    if ($g_users{$user}->{'new_login'} eq "__REMOVE") {
      # this is a subtle expectation in the code that may be missed.  set 
      # the new login value for a user to "__REMOVE" if you want to remove
      # the user from the password and the vpriv.conf file.  
      $entries{$user} = "__REMOVE";
      $vprivs{$user} = "__REMOVE";
      next;
    }
    # build new entry for password file
    $mylogin = $g_users{$user}->{'new_login'};
    $mypasswd = $g_users{$user}->{'new_password'};
    $myname = $g_users{$user}->{'new_name'};
    $mypath = $g_users{$user}->{'new_path'};
    if ($g_platform_type eq "virtual") {
      # set up virtual privileges and virtual quotas for VPS user
      $myprivs = "";
      # virtual privleges: ftp
      if ($g_users{$user}->{'ftp_checked'}) {
        $myprivs .= "ftp";
        if ($g_users{$user}->{'new_ftpquota'}) {
          $myprivs .= ",$g_users{$user}->{'new_ftpquota'}";
        }
      }
      # virtual privleges: mail
      if ($g_users{$user}->{'mail_checked'}) {
        $myprivs .= ";" if ($myprivs);
        $myprivs .= "mail";
        if ($g_users{$user}->{'new_mailquota'}) {
          $myprivs .= ",$g_users{$user}->{'new_mailquota'}";
        }
      }
      # build the virtual passwd entries
      if (-e "/etc/vpriv.conf") {
        $newentry = "$mylogin:$mypasswd:$g_uid:$g_gid:";
        $newentry .= "$myname:$mypath:noshell";
        $entries{$user}->{'/etc/passwd'} = $newentry; 
        $newentry = "$mylogin:$myprivs";
        $newentry =~ s/\;/\:/g;
        $vprivs{$user} = $newentry; 
      }
      else {
        # set privileges to "noshell" if neither ftp or mail privs are granted
        $myprivs = "noshell" unless ($myprivs);
        $newentry = "$mylogin:$mypasswd:$g_uid:$g_gid:";
        $newentry .= "$myname:$mypath:$myprivs";
        $entries{$user}->{'/etc/passwd'} = $newentry; 
      }
    }
    else {
      # set up username and uid
      if (defined($g_users{$user}->{'uid'})) {
        $myuid = $g_users{$user}->{'uid'};  # existing user
      }
      else {
        $myuid = passwdGetNewUserID();  # new user
        $g_users{$user}->{'uid'} = $myuid;
      }
      $entries{$user}->{'username'} = $mylogin;
      $entries{$user}->{'uid'} = $myuid;
      # set up main login group for dedicated server user and group id
      $entries{$user}->{'logingroup'} = $g_users{$user}->{'new_logingroup'};
      if (defined($g_groups{$entries{$user}->{'logingroup'}})) {
        $mygid = $g_groups{$entries{$user}->{'logingroup'}}->{'gid'};
      }
      else {
        # new group
        $mygid = groupGetNewGroupID();  # new group
        # set the gid field so that the next call to get a new group ID
        # does not return a GID that is to be used by a newly created group
        $g_groups{$entries{$user}->{'logingroup'}}->{'gid'} = $mygid;
        # set the 'new' field; groupSyncUserMembership looks for this
        $g_groups{$entries{$user}->{'logingroup'}}->{'new'} = 1;
      }
      $entries{$user}->{'gid'} = $g_users{$user}->{'gid'} = $mygid;
      # set up privileges (othergroups) for dedicated server user
      $mygroups = "";
      # dedicated user group membership: 'ftp'
      $mygroups .= "ftp," if ($g_users{$user}->{'ftp_checked'});
      # dedicated user group membership: 'pop'
      $mygroups .= "pop," if ($g_users{$user}->{'pop_checked'});
      # dedicated user group membership: 'imap'
      $mygroups .= "imap," if ($g_users{$user}->{'imap_checked'});
      # dedicated user group membership: others specified by client
      if (($g_users{$user}->{'othergroups_checked'}) && 
          ($g_users{$user}->{'new_othergrouplist'})) {
        $mygroups .= "$g_users{$user}->{'new_othergrouplist'},";
      }
      $mygroups =~ s/\,$//;
      $entries{$user}->{'othergroups'} = $mygroups; 
      # file system quota for user
      $entries{$user}->{'quota'} = $g_users{$user}->{'new_quota'};
      # build the passwd entries
      $myshell = $g_users{$user}->{'new_shell'};
      $newentry = "$mylogin:$mypasswd:$myuid:$mygid\:\:0:0:";
      $newentry .= "$myname:$mypath:$myshell";
      $entries{$user}->{'/etc/master.passwd'} = $newentry; 
      $newentry = "$mylogin:\*:$myuid:$mygid:$myname:$mypath:$myshell";
      $entries{$user}->{'/etc/passwd'} = $newentry; 
    }
  }

  if ($g_platform_type eq "dedicated") {
    push(@passwdfiles, "/etc/master.passwd");
  }
  push(@passwdfiles, "/etc/passwd");
  foreach $pfile (@passwdfiles) {
    # add a newline character to the file if necessary
    open(OPFP, "$pfile") ||
      passwdResourceError("open(OPFP, '$pfile') in passwdSaveChanges");
    seek(OPFP, -1, 2);
    read(OPFP, $lastchar, 1);
    close(OPFP);
    if ($lastchar ne "\n") {
      open(OPFP, ">>$pfile") ||
        passwdResourceError("open(OPFP, '>>$pfile') in passwdSaveChanges");
      print OPFP "\n";
      close(OPFP);
    }

    # backup old file
    require "$g_includelib/backup.pl";
    backupSystemFile("$pfile");

    # write out new password file
    # first check for a lock file
    if (-f "/etc/ptmptmp$$.$g_curtime") {
      passwdResourceError(
          "-f '/etc/ptmptmp$$.$g_curtime' returned 1 in passwdSaveChanges");
    } 
    # no obvious lock... use link() for atomicity to avoid race conditions
    open(PTMP, ">/etc/ptmptmp$$.$g_curtime") ||
      passwdResourceError(
          "open(PTMP, '>/etc/ptmptmp$$.$g_curtime') in passwdSaveChanges");
    close(PTMP);
    $locked = link("/etc/ptmptmp$$.$g_curtime", "/etc/ptmp");
    unlink("/etc/ptmptmp$$.$g_curtime");
    $locked || passwdResourceError(
       "link('/etc/ptmptmp$$.$g_curtime', '/etc/ptmp') \
        failed in passwdSaveChanges");
    open(NPFP, ">/etc/ptmp")  ||
      passwdResourceError("open(NPFP, '>/etc/ptmp') in passwdSaveChanges");
    flock(NPFP, 2);  # exclusive lock
    open(OPFP, "$pfile");
    while (<OPFP>) {
      $curentry = $_;
      # print out curentry, replace, or ignore?
      $match = 0;
      foreach $user (@user_ids) {
        if ($curentry =~ /^\Q$user\E:/) {
          $match = 1;
          # we have a match, replace or ignore?
          if ($entries{$user} eq "__REMOVE") {
            # ignore
            if (($g_platform_type eq "dedicated") &&
                ($pfile eq "/etc/master.passwd")) {
              groupPurgeUserFromAllGroups($user);
            }
          }
          else {
            # replace
            print NPFP "$entries{$user}->{$pfile}\n" ||
              passwdResourceError(
                "print to NPFP failed -- disk quota exceeded?");
            if (($g_platform_type eq "dedicated") &&
                ($pfile eq "/etc/master.passwd")) {
              groupSyncUserMembership($entries{$user}->{'username'},
                                      $entries{$user}->{'gid'},
                                      $entries{$user}->{'logingroup'},
                                      $entries{$user}->{'othergroups'});
              quotaSet($entries{$user}->{'uid'}, $entries{$user}->{'quota'});
            }
          }
          delete($entries{$user}->{$pfile});
        }
      }
      if ($match == 0) {
        print NPFP "$curentry" ||
          passwdResourceError("print to NPFP failed -- disk quota exceeded?");
      }
    }
    close(OPFP);
    # append new entries
    foreach $entry (keys(%entries)) {
      next if ($entries{$entry} eq "__REMOVE");
      next unless ($entries{$entry}->{$pfile});
      print NPFP "$entries{$entry}->{$pfile}\n" ||
        passwdResourceError("print to NPFP failed -- disk quota exceeded?");
      if ($pfile eq "/etc/master.passwd") {
        groupSyncUserMembership($entries{$entry}->{'username'},
                                $entries{$entry}->{'gid'},
                                $entries{$entry}->{'logingroup'},
                                $entries{$entry}->{'othergroups'});
        quotaSet($entries{$entry}->{'uid'}, $entries{$entry}->{'quota'});
      }
    }
    flock(NPFP, 8);  # unlock
    close(NPFP);
    rename("/etc/ptmp", "$pfile") ||
       passwdResourceError(
         "rename('/etc/ptmp', '$pfile') in passwdSaveChanges");
  }
  chmod(0644, "/etc/passwd");

  if (($g_platform_type eq "virtual") && (-e "/etc/vpriv.conf")) {
    # backup old file
    backupSystemFile("/etc/vpriv.conf") if (-e "/etc/vpriv.conf");
    # write out new vpriv.conf file
    # first check for a lock file
    if (-f "/etc/vtmptmp$$.$g_curtime") {
      passwdResourceError(
          "-f '/etc/vtmptmp$$.$g_curtime' returned 1 in passwdSaveChanges");
    } 
    # no obvious lock... use link() for atomicity to avoid race conditions
    open(PTMP, ">/etc/vtmptmp$$.$g_curtime") ||
      passwdResourceError(
          "open(PTMP, '>/etc/vtmptmp$$.$g_curtime') in passwdSaveChanges");
    close(PTMP);
    $locked = link("/etc/vtmptmp$$.$g_curtime", "/etc/vtmp");
    unlink("/etc/vtmptmp$$.$g_curtime");
    $locked || passwdResourceError(
       "link('/etc/vtmptmp$$.$g_curtime', '/etc/vtmp') \
        failed in passwdSaveChanges");
    open(OVFP, "/etc/vpriv.conf") ||
      passwdResourceError("open(OVFP, '/etc/vpriv.conf') in passwdSaveChanges");
    open(NVFP, ">/etc/vtmp")  ||
      passwdResourceError("open(NVFP, '>/etc/vtmp') in passwdSaveChanges");
    flock(NVFP, 2);  # exclusive lock
    while (<OVFP>) {
      $curentry = $_;
      # print out curentry, replace, or ignore?
      $match = 0;
      foreach $user (@user_ids) {
        if ($curentry =~ /^\Q$user\E:/) {
          $match = 1;
          # we have a match, replace or ignore?
          if ($vprivs{$user} eq "__REMOVE") {
            # ignore
          }
          else {
            # replace
            print NVFP "$vprivs{$user}\n" ||
              passwdResourceError(
                "print to NVFP failed -- disk quota exceeded?");
          }
          delete($vprivs{$user});
        }
      }
      # remove blank lines -- have to do this because a bug in previous
      # versions introduced blank lines into the vpriv.conf file ... drat
      next if ((!$curentry) || ($curentry eq "\n"));
      if ($match == 0) {
        print NVFP "$curentry" ||
          passwdResourceError("print to NVFP failed -- disk quota exceeded?");
      }
    }
    # append new privilege entries
    foreach $entry (keys(%vprivs)) {
      next if ($vprivs{$entry} eq "__REMOVE");
      print NVFP "$vprivs{$entry}\n" ||
        passwdResourceError("print to NVFP failed -- disk quota exceeded?");
    }
    close(OVFP);
    flock(NVFP, 8);  # unlock
    close(NVFP);
    rename("/etc/vtmp", "/etc/vpriv.conf") ||
       passwdResourceError(
         "rename('/etc/vtmp', '/etc/vpriv.conf') in passwdSaveChanges");
    chmod(0644, "/etc/vpriv.conf");
  }

  # rebuild the passwd db file
  $output = passwdRebuildDB();
  return($output);
}

##############################################################################

sub passwdSaveNewPassword
{
  local($user, $newpassword) = @_;
  local($pfile);

  # new passsword is presumed to be passed in crypted

  if ($g_platform_type eq "dedicated") {
    $pfile = "/etc/master.passwd";
  }
  else {
    $pfile = "/etc/passwd";
  }

  # add a newline character to the file if necessary
  open(OPFP, "$pfile") ||
    passwdResourceError("open(OPFP, '$pfile') in passwdSaveNewPassword");
  seek(OPFP, -1, 2);
  read(OPFP, $lastchar, 1);
  close(OPFP);
  if ($lastchar ne "\n") {
    open(OPFP, ">>$pfile") ||
      passwdResourceError("open(OPFP, '>>$pfile') in passwdSaveNewPassword");
    print OPFP "\n";
    close(OPFP);
  }

  # backup old file
  require "$g_includelib/backup.pl";
  backupSystemFile("$pfile");

  # write out new password file
  # first check for a lock file
  if (-f "/etc/ptmptmp$$.$g_curtime") {
    passwdResourceError(
        "-f '/etc/ptmptmp$$.$g_curtime' returned 1 in passwdSaveNewPassword");
  } 
  # no obvious lock... use link() for atomicity to avoid race conditions
  open(PTMP, ">/etc/ptmptmp$$.$g_curtime") ||
    passwdResourceError(
        "open(PTMP, '>/etc/ptmptmp$$.$g_curtime') in passwdSaveNewPassword");
  close(PTMP);
  $locked = link("/etc/ptmptmp$$.$g_curtime", "/etc/ptmp");
  unlink("/etc/ptmptmp$$.$g_curtime");
  $locked || passwdResourceError(
     "link('/etc/ptmptmp$$.$g_curtime', '/etc/ptmp') \
      failed in passwdSaveNewPassword");
  open(OPFP, "$pfile") ||
    passwdResourceError("open(OPFP, '$pfile') in passwdSaveNewPassword");
  open(NPFP, ">/etc/ptmp")  ||
    passwdResourceError("open(NPFP, '>/etc/ptmp') in passwdSaveNewPassword");
  flock(NPFP, 2);  # exclusive lock
  while (<OPFP>) {
    $curentry = $_;
    if ($curentry =~ /^$user:.*?:(.*)/) {
      # replace old password with new password
      $curentry = "$user:$newpassword:$1\n";
    }
    print NPFP "$curentry" ||
        passwdResourceError("print to NPFP failed -- disk quota exceeded?");
  }
  close(OPFP);
  flock(NPFP, 8);  # unlock
  close(NPFP);
  rename("/etc/ptmp", "$pfile") ||
     passwdResourceError(
       "rename('/etc/ptmp', '$pfile') in passwdSaveNewPassword");

  # rebuild the passwd db file
  passwdRebuildDB();
}

##############################################################################
# eof
  
1;

