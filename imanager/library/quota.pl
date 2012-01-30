#
# quota.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/quota.pl,v 2.12.2.4 2006/04/25 19:48:25 rus Exp $
#
# quota support for "dedicated" environment
#

# need external Quota library... hopefully it is installed
require Quota;

##############################################################################

sub quotaGetLimit
{
  local($userid) = @_;
  local($block_hard);

  # make sure quotas are turned on for the file system
  quotaSystemCheck();

  ($block_hard) = (Quota::query(Quota::getqcarg('/home'), $userid, 0))[2];
  $block_hard = 0 unless ($block_hard);  # zero infers no limit
  return($block_hard);
}

##############################################################################

sub quotaGetUsed
{
  local($userid) = @_;
  local($block_curr);

  # make sure quotas are turned on for the file system
  quotaSystemCheck();

  GETQUOTA: {
    local $> = 0;
    ($block_curr) = (Quota::query(Quota::getqcarg('/home'), $userid, 0))[0];
  }
  return($block_curr);
}

##############################################################################
    
sub quotaSet
{ 
  local($userid, $quota) = @_;
  local($oldquota);

  if ($quota == 0) {
    $oldquota = quotaGetLimit($userid);
    return if ($oldquota == 0);  # do nothing
  }

  # quota is presumed to have been passed in specified in megabytes (MB)
  $quota *= 1024;

  # make sure quotas are turned on for the file system
  quotaSystemCheck();

  # set the quota
  SETQUOTA: {
    local $> = 0;
    Quota::setqlim(Quota::getqcarg('/home'), $userid, $quota, $quota, 0, 0, 0);
  }
}   

##############################################################################

sub quotaSystemCheck
{
  local($turnedon, $locked, $enabled);

  # return if !root
  return if (($g_auth{'login'} ne "root") &&
             ($g_auth{'login'} !~ /^_.*root$/) &&
             ($g_auth{'login'} ne $g_users{'__rootid'}) &&
             (!(defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}}))));

  # make sure quotas are turned on in file system table
  $turnedon = 0;
  open(FP, "/etc/fstab");
  while (<FP>) {
    if (m#^\S+\s+/\s+ufs\s+rw\S+userquota#) {
      $turnedon = 1;
      last;
    }
  }
  close(FP);
  unless ($turnedon) {
    REWT: {
      local $> = 0;
      # rewrite fstab
      # backup old file first
      require "$g_includelib/backup.pl";
      backupSystemFile("/etc/fstab");
      # write out new fstab file
      # first check for a lock file
      if (-f "/etc/ftmptmp$$.$g_curtime") {
        return;
      }
      # no obvious lock... use link() for atomicity to avoid race conditions
      open(FTMP, ">/etc/ftmptmp$$.$g_curtime") || return;
      close(FTMP);
      $locked = link("/etc/ftmptmp$$.$g_curtime", "/etc/ftmp");
      unlink("/etc/ftmptmp$$.$g_curtime");
      $locked || return;
      open(NEWFSTAB, ">/etc/ftmp")  || return;
      flock(NEWFSTAB, 2);  # exclusive lock
      open(OLDFSTAB, "/etc/fstab");
      while (<OLDFSTAB>) {
        s{^(\S+\s+/\s+ufs\s+rw.*)$}{$1,userquota};
        print NEWFSTAB $_;
      }
      close(OLDFSTAB);
      flock(NEWFSTAB, 8);  # unlock
      close(NEWFSTAB);
      rename("/etc/ftmp", "/etc/fstab") || return;
      chmod(0644, "/etc/fstab");
    }
  }

  # make sure quotas are enabled
  $enabled = "";
  open(FP, "/etc/rc.conf");
  while (<FP>) {
    if (m#^enable_quotas="?yes"?$#i) {
      $enabled = "yes" unless ($enabled);
    }
    elsif (m#^enable_quotas="?no"?$#i) {
      $enabled = "no";
    }
  }
  close(FP);
  if ($enabled ne "yes") {
    REWT: {
      local $> = 0;
      # rewrite rc.conf
      # backup old file first
      require "$g_includelib/backup.pl";
      backupSystemFile("/etc/rc.conf");
      # write out new rc.conf file
      # first check for a lock file
      if (-f "/etc/rctmptmp$$.$g_curtime") {
        return;
      }
      # no obvious lock... use link() for atomicity to avoid race conditions
      open(FTMP, ">/etc/rctmptmp$$.$g_curtime") || return;
      close(FTMP);
      $locked = link("/etc/rctmptmp$$.$g_curtime", "/etc/rctmp");
      unlink("/etc/rctmptmp$$.$g_curtime");
      $locked || return;
      open(NEWFSTAB, ">/etc/rctmp")  || return;
      flock(NEWFSTAB, 2);  # exclusive lock
      open(OLDFSTAB, "/etc/rc.conf");
      while (<OLDFSTAB>) {
        next if (/^enable_quotas=/i);
        print NEWFSTAB $_;
      }
      close(OLDFSTAB);
      print NEWFSTAB "enable_quotas=\"YES\"\n";
      flock(NEWFSTAB, 8);  # unlock
      close(NEWFSTAB);
      rename("/etc/rctmp", "/etc/rc.conf") || return;
      chmod(0644, "/etc/rc.conf");
    }
  }

  # code copied from vadduser ... thanks Scott!
  # turn the quota on for the filesystem
  EDQUOTA: {
    local $> = 0;
    system('touch', '/quota.user') unless -f '/quota.user';
    chmod 0640, '/quota.user' if -f '/quota.user';
    local $ENV{'EDITOR'} = 'true';
    system('edquota', '-t');
  }
  system('quotaon', '/')

}

##############################################################################
# eof
  
1;

