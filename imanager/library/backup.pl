#
# backup.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/backup.pl,v 2.12.2.2 2006/04/25 19:48:23 rus Exp $
#
# backup file functions
#

##############################################################################

sub backupSystemFile
{
  local($systemfile) = @_;
  local($filename, $index, $maxindex);
  local($source, $destination);

  unless (-d "/etc/backup") {
    mkdir("/etc/backup", 0700) || return;
  }
  chmod(0700, "/etc/backup");

  $systemfile =~ /([^\/]+$)/;
  $filename = $1;

  # keep 20 backup copies of system files on hand
  $maxindex = 20;  
  for ($index=$maxindex-1; $index>0; $index--) {
    $source = "/etc/backup/" . $filename . "." . ($index-1);
    next unless (-e "$source");
    $destination = "/etc/backup/" . $filename . "." . $index;
    rename($source, $destination);
    chmod(0600, $destination);
  }

  # copy the last file (don't rename)
  $destination = "/etc/backup/" . $filename . ".0";
  open(DFP, ">$destination");
  open(SFP, "$systemfile");
  print DFP $_ while (<SFP>);
  close(SFP);
  close(DFP);
  chmod(0600, $destination);
}

##############################################################################

sub backupUserFile
{
  local($userfile) = @_;
  local($homedir, $backupdir, $size);
  local($filename, $index, $maxindex);
  local($source, $destination);

  # assumptions: userfile is provided as full pathname spec

  # only backup a file if it has non-zero length
  ($size) = (stat($userfile))[7];
  return unless($size > 0);

  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  if ((-e "$homedir") && 
      (($g_platform_type eq "virtual") || ($homedir ne "/"))) {
    $backupdir = "$homedir/.imanager";
    mkdir("$backupdir", 0700) unless (-e "$backupdir");
    chown($g_users{$g_auth{'login'}}->{'uid'},
          $g_users{$g_auth{'login'}}->{'gid'}, $backupdir);
    chmod(0700, $backupdir);
    $backupdir .= "/backup";
    mkdir("$backupdir", 0700) unless (-e "$backupdir");
    chown($g_users{$g_auth{'login'}}->{'uid'},
          $g_users{$g_auth{'login'}}->{'gid'}, $backupdir);
    chmod(0700, $backupdir);
  }
  else {
    # home directory doesn't exist or is "/" ... use a specification in
    # no man's land (see above), i.e. /tmp/.imanager/login
    $backupdir = "/tmp/.imanager/$g_auth{'login'}";
    mkdir("$backupdir", 0700) unless (-e "$backupdir");
    chown($g_users{$g_auth{'login'}}->{'uid'},
          $g_users{$g_auth{'login'}}->{'gid'}, $backupdir);
    chmod(0700, $backupdir);
    $backupdir .= "/tmp";
    mkdir("$backupdir", 0700) unless (-e "$backupdir");
    chown($g_users{$g_auth{'login'}}->{'uid'},
          $g_users{$g_auth{'login'}}->{'gid'}, $backupdir);
    chmod(0700, $backupdir);
  }

  unless (-d "$backupdir") {
    mkdir("$backupdir", 0700) || return;
  }
  chmod(0700, "$backupdir");

  $userfile =~ /([^\/]+$)/;
  $filename = $1;

  # keep 20 backup copies of system files on hand
  $maxindex = 20;  
  for ($index=$maxindex-1; $index>0; $index--) {
    $source = "$backupdir/" . $filename . "." . ($index-1);
    next unless (-e "$source");
    $destination = "$backupdir/" . $filename . "." . $index;
    rename($source, $destination);
    chmod(0600, $destination);
  }

  # copy the last file (don't rename)
  $destination = "$backupdir/" . $filename . ".0";
  open(DFP, ">$destination");
  open(SFP, "$userfile");
  print DFP $_ while (<SFP>);
  close(SFP);
  close(DFP);
  chmod(0600, $destination);
}

##############################################################################
# eof

1;

