#
# mm_util.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/mm_util.pl,v 2.12.2.18 2006/05/30 19:03:27 rus Exp $
#
# mail manager functions
#
##############################################################################

sub mailmanagerBuildFullPath
{
  local($userpath) = @_;
  local($fullpath, @subpaths, $index, $mypath);

  if ($userpath =~ /^=/) {
    $userpath =~ s#^=#$g_prefs{'mail__default_folder'}/#;
  }
  if ($userpath =~ m#^~/#) {
    if (($g_platform_type eq "dedicated") &&
        (!$g_users{$g_auth{'login'}}->{'chroot'})) {
      # substitute full path for ~/PATH
      $userpath =~ s#^~/#$g_users{$g_auth{'login'}}->{'home'}/#;
    }
    else {
      $userpath =~ s#^~/#/#;
    }
  }
  elsif ($userpath =~ m#^~([^/]+)/#) {
    $userpath =~ s#^~[^/]+#$g_users{$1}->{'home'}/#;
  }

  if ($userpath !~ /^\//) {
    # build a fullpath relative to current working directory... whatever
    # that happens to be... if no relative directory can be determined,
    # then presume path specification is relative to the users home dir
    if ($g_form{'cwd'}) {
      $mypath = $g_form{'cwd'};
      $g_form{'cwd'} = "";
      $fullpath = mailmanagerBuildFullPath($mypath);
    }
    else {
      $fullpath = $g_users{$g_auth{'login'}}->{'home'} ||
                  $g_users{$g_auth{'login'}}->{'path'};
    }
    $fullpath .= "/" . $userpath;
  }
  else {
    $fullpath = $g_users{$g_auth{'login'}}->{'path'} . "/" . $userpath;
  }
  $fullpath =~ s/\/+/\//g;
  @subpaths = split(/\//, $fullpath);
  $mypath = "";
  for ($index=0; $index<=$#subpaths; $index++) {
    next if ((!$subpaths[$index]) || ($subpaths[$index] eq "."));
    if ($subpaths[$index] eq "..") {
      # remove the last subpath
      $mypath =~ s/[^\/]+$//g;
      $mypath =~ s/\/+$//g;
    }
    else {
      $mypath .= "/$subpaths[$index]";
    }
  }
  $mypath = "/" unless ($mypath);
  if ($mypath !~ /^$g_users{$g_auth{'login'}}->{'path'}/) {
    # resulting testpath is not prefixed by home directory
    encodingIncludeStringLibrary("mailmanager");
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($MAILMANAGER_DENIED_TITLE);
    $MAILMANAGER_PERMISSION_DENIED =~ s/__PATH__/$userpath/g;
    htmlText($MAILMANAGER_PERMISSION_DENIED);
    htmlP();
    labelCustomFooter();
    exit(0);
  }
  $fullpath = $mypath;
  $fullpath = "/" unless ($fullpath);
  return($fullpath);
}

##############################################################################

sub mailmanagerByDate
{
  # sort by date... oldest to newest
  return($g_email{$a}->{'__sort_date__'} <=> $g_email{$b}->{'__sort_date__'});
}

##############################################################################

sub mailmanagerByThread
{
  return($g_email{$a}->{'__thread_order__'} <=> $g_email{$b}->{'__thread_order__'});
}

##############################################################################

sub mailmanagerByPreference
{
  if ($g_form{'msort'} eq "by_subject") {
    if ($g_email{$a}->{'subject'} eq $g_email{$b}->{'subject'}) {
      if ($g_email{$a}->{'__sort_date__'} == $g_email{$b}->{'__sort_date__'}) {
        if ($g_email{$a}->{'__from_name__'} eq 
            $g_email{$b}->{'__from_name__'}) {
          return($g_email{$b}->{'__size__'} <=> $g_email{$a}->{'__size__'});
        }
        else {
          return($g_email{$a}->{'__from_name__'} cmp
                 $g_email{$b}->{'__from_name__'});
        }
      }
      else {
        return($g_email{$b}->{'__sort_date__'} <=> 
               $g_email{$a}->{'__sort_date__'});
      }
    }
    else {
      return($g_email{$a}->{'subject'} cmp $g_email{$b}->{'subject'});
    }
  }
  elsif ($g_form{'msort'} eq "by_sender") {
    if ($g_email{$a}->{'__from_name__'} eq $g_email{$b}->{'__from_name__'}) {
      if ($g_email{$a}->{'__sort_date__'} == $g_email{$b}->{'__sort_date__'}) {
        if ($g_email{$a}->{'subject'} eq $g_email{$b}->{'subject'}) {
          return($g_email{$b}->{'__size__'} <=> $g_email{$a}->{'__size__'});
        }
        else {
          return($g_email{$a}->{'subject'} cmp $g_email{$b}->{'subject'});
        }
      }
      else {
        return($g_email{$b}->{'__sort_date__'} <=> 
               $g_email{$a}->{'__sort_date__'});
      }
    }
    else {
      return($g_email{$a}->{'__from_name__'} cmp 
             $g_email{$b}->{'__from_name__'});
    }
  }
  elsif ($g_form{'msort'} eq "by_size") {
    if ($g_email{$a}->{'__size__'} == $g_email{$b}->{'__size__'}) {
      if ($g_email{$a}->{'__sort_date__'} == $g_email{$b}->{'__sort_date__'}) {
        if ($g_email{$a}->{'__from_name__'} eq 
            $g_email{$b}->{'__from_name__'}) {
          return($g_email{$a}->{'subject'} cmp $g_email{$b}->{'subject'});
        }
        else {
          return($g_email{$a}->{'__from_name__'} cmp
                 $g_email{$b}->{'__from_name__'});
        }
      }
      else {
        return($g_email{$b}->{'__sort_date__'} <=> 
               $g_email{$a}->{'__sort_date__'});
      }
    }
    else {
      return($g_email{$b}->{'__size__'} <=> $g_email{$a}->{'__size__'});
    }
  }
  elsif ($g_form{'msort'} eq "in_order") {
    return($g_email{$a}->{'__order__'} <=> $g_email{$b}->{'__order__'});
  }
  elsif ($g_form{'msort'} eq "by_thread") {
    return($g_email{$a}->{'__thread_order__'} <=> $g_email{$b}->{'__thread_order__'});
  }
  else {
    # msort == "by_date", the default
    if ($g_email{$a}->{'__sort_date__'} == $g_email{$b}->{'__sort_date__'}) {
      if ($g_email{$a}->{'__from_name__'} eq $g_email{$b}->{'__from_name__'}) {
        if ($g_email{$a}->{'subject'} eq $g_email{$b}->{'subject'}) {
          return($g_email{$b}->{'__size__'} <=> $g_email{$a}->{'__size__'});
        }
        else {
          return($g_email{$a}->{'subject'} cmp $g_email{$b}->{'subject'});
        }
      }
      else {
        return($g_email{$a}->{'__from_name__'} cmp
               $g_email{$b}->{'__from_name__'});
      }
    }
    else {
      return($g_email{$b}->{'__sort_date__'} <=> 
             $g_email{$a}->{'__sort_date__'});
    }
  }
}

##############################################################################

sub mailmanagerByListingType
{
  if ($g_form{'viewtype'} eq "short") {
    if ($fg_files{$a}->{'row'} eq $fg_files{$b}->{'row'}) {
      if ($fg_files{$a}->{'type'} eq $fg_files{$b}->{'type'}) {
        return($a cmp $b);
      }
      if ($fg_files{$a}->{'type'} eq "directory") {
        return(-1);  # do nothing
      }
      elsif ($fg_files{$b}->{'type'} eq "directory") {
        return(1);  # switch
      }
      else {
        return($a cmp $b);
      }
    }
    else {
      return($fg_files{$a}->{'row'} <=> $fg_files{$b}->{'row'});
    }
  }
  else {
    if ($fg_files{$a}->{'type'} eq $fg_files{$b}->{'type'}) {
      return($a cmp $b);
    }
    if ($fg_files{$a}->{'type'} eq "directory") {
      return(-1);  # do nothing
    }
    elsif ($fg_files{$b}->{'type'} eq "directory") {
      return(1);  # switch
    }
    else {
      return($a cmp $b);
    }
  }
}

##############################################################################

sub mailmanagerCountMessages
{
  local($fullpath) = @_;
  local($count);

  $count = 0;
  open(MAILBOX, "$fullpath");
  while (<MAILBOX>) {
    $count++ if (/^From\ /);
  }
  close(MAILBOX);
  return($count);
}

##############################################################################

sub mailmanagerCreateDefaultMailFolder
{
  local($directory) = @_;
  local($filename);

  # create the directory (if it doesn't already exist)
  mailmanagerCreateDirectory($directory);

  # make sure an appropriate .htaccess file exists
  $filename = $directory;
  $filename .= "/" if ($filename !~ /\/$/);
  $filename .= ".htaccess";
  unless (-e "$filename") {
    open(HTFP, ">$filename") || return;
    print HTFP <<ENDTEXT;
<Limit GET POST DELETE PUT>
deny from all
</Limit>

ENDTEXT
    close(HTFP);
  }
}

##############################################################################

sub mailmanagerCreateDirectory
{
  local($directory) = @_;
  local(@subpaths, $index, $curpath);
    
  return if (-e "$directory");

  $directory =~ s/\/+$//;
  @subpaths = split(/\//, $directory);
  for ($index=0; $index<=$#subpaths; $index++) {
    next unless ($subpaths[$index]);
    $curpath .= "/$subpaths[$index]";
    $curpath =~ s/\/\//\//g; 
    unless (-d "$curpath") {
      mkdir($curpath, 0700) ||
        mailmanagerResourceError($MAILMANAGER_CREATEDIR,
            "call to mkdir($curpath, 0700) in mailmanagerCreateDirectory");
      chmod(0700, $curpath);
    }
  }
} 

##############################################################################

sub mailmanagerDecode64
{
  local($str) = @_;
  local($res);      

  # code provided courtesy the perl5 MIME library

  $res = "";
  $str =~ tr|A-Za-z0-9+=/||cd;            # remove non-base64 chars
  $str =~ s/=+$//;                        # remove padding
  $str =~ tr|A-Za-z0-9+/| -_|;            # convert to uuencoded format
  while ($str =~ /(.{1,60})/gs) {
      my $len = chr(32 + length($1)*3/4); # compute length byte
      $res .= unpack("u", $len . $1 );    # uudecode
  }
  return($res);
}

##############################################################################

sub mailmanagerDecodeQuotedPrintable
{
  local($str) = @_;

  # code provided courtesy the perl5 MIME library
  $str =~ s/[ \t]+?(\r?\n)/$1/g;  # rule #3 (trailing space must be deleted)
  $str =~ s/=\r?\n//g;            # rule #5 (soft line breaks)
  $str =~ s/=([\da-fA-F]{2})/pack("C", hex($1))/ge;
  return($str);
}

##############################################################################

sub mailmanagerEncode64
{
  local($str, $eol) = @_;
  local($res);

  # code provided courtesy the perl5 MIME library

  $eol = "\n" unless defined $eol;
  pos($str) = 0;                          # ensure start at the beginning
  while ($str =~ /(.{1,45})/gs) {
    $res .= substr(pack('u', $1), 1);
    chop($res);
  }
  $res =~ tr|` -_|AA-Za-z0-9+/|;               # `# help emacs  (?)
  # fix padding at the end
  my $padding = (3 - length($str) % 3) % 3;
  $res =~ s/.{$padding}$/'=' x $padding/e if $padding;
  # break encoded string into lines of no more than 72 characters each
  if (length($eol)) {
    $res =~ s/(.{1,72})/$1$eol/g;
  }
  return($res);
}

##############################################################################

sub mailmanagerEncodeAddressHeaderToJIS
{
  local($header) = @_;
  local(@parts, $part, $name, $address, $jisheader, $count);

  # break header into parts, dissect, and encode
  $jisheader = "";
  @parts = mailmanagerParseString(',', 0, $header);
  foreach $part (@parts) {
    if ($part =~ /\b([\w.\-\&]+?@[\w.-]+?)(?=[.-]*(?:[^\w.-]|$))/) {
      $email = $1;
      $part =~ s/\b([\w.\-\&]+?@[\w.-]+?)(?=[.-]*(?:[^\w.-]|$))//g;
      $part =~ s/\<\>//;
      $name = $part;
    }
    else {
      $name = "";
      $email = $part;
    }
    $name =~ s/^[\s\"\(\<\']+//g;
    $name =~ s/[\s\"\)\>\']+$//g;
    $email =~ s/^\s+//g;
    $email =~ s/\s+$//g;
    next unless ($name || $email);
    $count = $name =~ tr/\(/\(/;
    $name .= ")" x $count;
    $name =~ s/\s+/ /g;
    if ($name) {
      $name = mimeencode(jcode'jis($name));
      $jisheader .= " \"$name\" <$email>,";
    }
    else {
      $jisheader .= " $email,";
    }
  }
  $jisheader =~ s/\,$//;
  $jisheader = $header unless ($jisheader);
  return($jisheader);
}

##############################################################################

sub mailmanagerGetDefaultIncomingMailbox
{
  local($incoming_mail_folder);

  # someday I expect that default mail folders will live in /var/mail
  # instead of the current /usr/mail.  if /var/mail/{folder} exists
  # use it instead of /usr/mail/{folder}
  if (-e "/var/mail/$g_auth{'login'}") {
    $incoming_mail_folder = "/var/mail/$g_auth{'login'}";
  }
  else {
    # default for now is /usr/mail ... this will probably change
    $incoming_mail_folder = "/usr/mail/$g_auth{'login'}";
  }
  return($incoming_mail_folder);
}

##############################################################################

sub mailmanagerGetDirectoryPath
{
  local($subdir) = @_;
  local($homedir, $pathname);
    
  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  if ((-e "$homedir") &&
      (($g_platform_type eq "virtual") || ($homedir ne "/"))) {
    $pathname = $homedir . "/.imanager";
    unless (-e "$pathname") {
      mkdir("$pathname", 0700);
      chmod(0700, "$pathname");
    }
    $pathname .= "/$subdir";
    unless (-e "$pathname") {
      mkdir("$pathname", 0700);
      chmod(0700, "$pathname");
    }
  }
  else {
    $pathname = "/tmp/.imanager/$g_auth{'login'}";
    unless (-e "$pathname") {
      mkdir("$pathname", 0700);
      chmod(0700, "$pathname");
    }
    $pathname .= "/$subdir";
    unless (-e "$pathname") {
      mkdir("$pathname", 0700);
      chmod(0700, "$pathname");
    }
  }
  return($pathname);
}

##############################################################################

sub mailmanagerGetLocalDeliveryAgent
{
  local($sendmailcf, $lda);
  
  # check the local mailer definition
  $sendmailcf = ($g_platform_type eq "dedicated") ?
                 "/etc/mail/sendmail.cf" : "/etc/sendmail.cf";
  open(MYFP, "$sendmailcf");
  while (<MYFP>) {
    if ((/^Mlocal/) && (/P=(.*?)\,/)) {
      $lda = $1;
      last;
    }
  }
  close(MYFP);
  
  return($lda);
}
  
##############################################################################

sub mailmanagerGetLocalHostnames
{
  local($configfile, @domains, $domain, $filename, $host, $ipaddr);

  # populate a global g_localhostnames hash with all of the host names that
  # can be determined to be 'local'
  if ($g_platform_type eq "virtual") {
    $configfile = "/etc/sendmail.cf";
  }
  else {
    $configfile = "/etc/mail/sendmail.cf";
  }
  open(SENDMAILCF, "$configfile");
  while (<SENDMAILCF>) {
    if (/^Cw/) {
      s/\s+/ /g;
      @domains = split(/\ /);
      foreach $domain (@domains) {
        $g_localhostnames{$domain} = "dau!";
      }
    }
    elsif (/^Fw/) {
      s/\s+/ /g;
      ($filename) = (split(/\ /))[1];
      if (open(LHN, $filename)) {
        while (<LHN>) {
          chomp;
          $g_localhostnames{$_} = "dau!";
        }
        close(LHN);
      }
    }
  }
  close(SENDMAILCF);

  # add the HTTP_HOST
  if ($ENV{'HTTP_HOST'} && ($ENV{'HTTP_HOST'} =~ /[^0-9\.]/)) {
    $host = $ENV{'HTTP_HOST'};
    $host =~ s/^(www\.|ftp\.|mail\.|smtp\.|pop\.|imap\.|imanager\.)//;
    $g_localhostnames{$host} = "dau!";
  }
  # add the SERVER_NAME
  if ($ENV{'SERVER_NAME'} && ($ENV{'SERVER_NAME'} =~ /[^0-9\.]/)) {
    $host = $ENV{'SERVER_NAME'};
    $host =~ s/^(www\.|ftp\.|mail\.|smtp\.|pop\.|imap\.|imanager\.)//;
    $g_localhostnames{$host} = "dau!";
  }
  else {
    $ipaddr = pack("C4", split(/\./, $ENV{'SERVER_NAME'}));
    $host = gethostbyaddr($ipaddr, 2) || $ENV{'SERVER_NAME'};
    $host =~ s/^(www\.|ftp\.|mail\.|smtp\.|pop\.|imap\.|imanager\.)//;
    $g_localhostnames{$host} = "dau!";
  }
}

##############################################################################

sub mailmanagerHostAddress
{
  local($host, $ipaddr);

  if ($ENV{'HTTP_HOST'} && ($ENV{'HTTP_HOST'} =~ /[^0-9\.]/)) {
    $host = $ENV{'HTTP_HOST'};
  }
  else {
    if ($ENV{'SERVER_NAME'} && ($ENV{'SERVER_NAME'} =~ /[^0-9\.]/)) {
      $host = $ENV{'SERVER_NAME'};
    }
    else {
      $ipaddr = pack("C4", split(/\./, $ENV{'SERVER_NAME'}));
      $host = gethostbyaddr($ipaddr, 2) || $ENV{'SERVER_NAME'};
    }
  }

  # get rid of any "www." or other annoying prefixes
  $host =~ s/^(www\.|ftp\.|mail\.|smtp\.|pop\.|imap\.|imanager\.)//;

  return($host);
}

##############################################################################

sub mailmanagerInit
{
  encodingIncludeStringLibrary("mailmanager");

  # check for mail privileges
  if ($g_users{$g_auth{'login'}}->{'mail'} == 0) {
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($MAILMANAGER_DENIED_TITLE);
    htmlText($MAILMANAGER_DENIED_TEXT);
    htmlP();
    labelCustomFooter();
    exit(0);
  }

  # <kludgealert>
  # 
  # non-root users on a dedicated platform who have a home directory  
  # path set to "/" will not be able to access certain mail utilities.
  # these utilities include: 
  #
  #   - creating, managing, and saving messages to mail folders
  #   - using the address book
  #   - configuring mail filters
  #   - using the autoresponder
  #   - setting a mail signature
  #
  # set a flag here which will be checked later (as required) to 
  # signify that this user has "full" access to all mail utilities
  # or "restricted" access to a subset of the mail utilities.
  #
  # </kludgealert>
  #
  $g_users{$g_auth{'login'}}->{'mail_access_level'} = "full";
  if (($g_platform_type eq "dedicated") &&
      ((!$g_users{$g_auth{'login'}}->{'home'}) || 
       ($g_users{$g_auth{'login'}}->{'home'} eq "/"))) {
    $g_users{$g_auth{'login'}}->{'mail_access_level'} = "restricted";
  }

  # check for a submitted mailbox
  if ($g_form{'mbox'} &&
      (($g_form{'mbox'} eq "!") || 
       ($g_form{'mbox'} =~ /^$MAILMANAGER_DEFAULT_FOLDER$/i) ||
       ($g_form{'mbox'} eq $MAILMANAGER_DEFAULT_FOLDER) ||
       ($g_form{'mbox'} eq "{$MAILMANAGER_DEFAULT_FOLDER}"))) {
    $g_form{'mbox'} = "";
  }
  if ($g_form{'mbox'}) {
    $g_mailbox_fullpath = mailmanagerBuildFullPath($g_form{'mbox'}); 
    $g_mailbox_virtualpath = $g_form{'mbox'};
  }

  unless ($g_mailbox_fullpath) {
    $g_mailbox_fullpath = mailmanagerGetDefaultIncomingMailbox();
    $g_mailbox_virtualpath = "\{$MAILMANAGER_DEFAULT_FOLDER\}";
  }

  # set the default mail sortion option
  unless ($g_form{'msort'}) {
    $g_form{'msort'} = $g_prefs{'mail__sort_option'} || "by_date"; 
  }

  # set default range
  unless ($g_form{'mrange'}) {
    $g_form{'mrange'} = $g_prefs{'mail__num_messages'};
  }

  # check for a mail message range specification
  if ($g_form{'mpos'} && ($g_form{'mpos'} =~ /([0-9\-]*)-([0-9\-]*)/)) {
    $g_form{'mpos'} = $1;
    $g_form{'mrange'} = $2-$1+1 unless (($2-$1+1) <= 0);
    $g_form{'mpos'} = 1 if ($g_form{'mpos'} <= 0);
  }

  # reset mail position if bad value detected
  if ($g_form{'mpos'} && 
      (($g_form{'mpos'} <= 0) || ($g_form{'mpos'} =~ /[^0-9]/))) {  
    $g_form{'mpos'} = ""; 
  }

  # load up the date functions
  require "$g_includelib/date.pl";
}

##############################################################################

sub mailmanagerInvokeSendmail
{
  local($args, @mfilenames) = @_;
  local($tmpfile, $statusmsg, $mfilename, $rootpath);
  local($errmsg);

  # create a temporary file to store sendmail messages
  $tmpfile = "$g_tmpdir/.message-" . $g_auth{'login'};
  $tmpfile .= "-" . $g_curtime . "-" . $$;
  # open up a pipe to sendmail
  unless (open(SMPIPE, "| /usr/sbin/sendmail $args 1>$tmpfile")) {
    foreach $mfilename (@mfilenames) {
      unlink($mfilename);
    }
    mailmanagerResourceError("open(SMPIPE, \"| /usr/sbin/sendmail $args\")");
  }
  # prime the error message
  $errmsg = "write failure in mailmanagerInvokeSendmail() -- ";
  $errmsg .= "check available disk space";
  # write the message to the pipe
  foreach $mfilename (@mfilenames) {
    open(MESGFP, "$mfilename");
    while (<MESGFP>) {
      chomp;
      s/^\.$/\\\./ unless ($args =~ /\-oi/);
      unless (print SMPIPE "$_\n") {
        foreach $mfilename (@mfilenames) {
          unlink($mfilename);
        }
        mailmanagerResourceError($errmsg);
      }
    }
    close(MESGFP);
    # do some housekeeping
    unlink($mfilename);
  }
  # close pipe (send)
  close(SMPIPE);

  # check the tmpfile for any sendmail burps
  $statusmsg = ""; 
  open(TMPFP, "$tmpfile");
  $statusmsg .= $_ while (<TMPFP>);
  close(TMPFP);
  unlink($tmpfile);

  # sanitize the status mesg (don't give away too much information)
  $rootpath = $g_users{$g_auth{'login'}}->{'path'};
  $statusmsg =~ s/$rootpath//g if ($rootpath ne "/");

  return($statusmsg);
}

##############################################################################

sub mailmanagerMailboxCacheClear
{
  local($mbox, $msort);
  local($mcdir, $mcbox, $mcdir, $mcfile, $fullpath);
  local($mboxsize, $mboxtime);

  $mbox = $g_form{'mbox'};
  $msort = $g_form{'msort'};
  $msort = "by_date" unless ($msort);

  $mcdir = mailmanagerGetDirectoryPath("mboxcache");
  if ($mbox) {
    $fullpath = mailmanagerBuildFullPath($mbox); 
    $mcbox = $fullpath;
    $mcbox =~ s#^$g_users{$g_auth{'login'}}->{'home'}/##;
    $mcbox =~ s#/#,#g;
  }
  else {
    $fullpath = mailmanagerGetDefaultIncomingMailbox();
    $mcbox = "INBOX";
  }
  $mcdir = $mcdir . "/" . $mcbox . "/" . $msort;
  opendir(CACHEDIR, "$mcdir");
  foreach $mcfile (readdir(CACHEDIR)) {
    unlink("$mcdir/$mcfile");
  }
  closedir(CACHEDIR);

  # do some housecleaning
  mailmanagerMailboxCacheTidy();
}

##############################################################################

sub mailmanagerMailboxCacheGetMessageInfo
{
  local($cmid) = @_;
  local($mbox, $msort, $mcdir, $mcbox, $mcfile);
  local($c_prev, $c_next, $c_date, $c_from, $c_subject, $c_size);

  $cmid = $g_form{'messageid'} unless ($cmid);

  $c_prev = $c_next = $c_date = $c_from = $c_subject = $c_size = "";

  if ($msort && ($msort eq "in_order")) {
    # no cache ... just return what is in memory
    $c_prev = $g_email{$cmid}->{'__prevmessageid__'};
    $c_next = $g_email{$cmid}->{'__nextmessageid__'};
  }
  else {
    $mbox = $g_form{'mbox'};
    $msort = $g_form{'msort'};
    $msort = "by_date" unless ($msort);
    $mcdir = mailmanagerGetDirectoryPath("mboxcache");
    if ($mbox) {
      $mcbox = mailmanagerBuildFullPath($mbox); 
      $mcbox =~ s#^$g_users{$g_auth{'login'}}->{'home'}/##;
      $mcbox =~ s#/#,#g;
    }
    else {
      $mcbox = "INBOX";
    }
    $cmid =~ s/[^A-Za-z0-9\-\.\_]/\_/g;
    $mcfile = $mcdir . "/" . $mcbox . "/" . $msort . "/" . $cmid;
    if (-e "$mcfile") {
      if (open(MCFP, "$mcfile")) {
        $c_prev = <MCFP>;
        chomp($c_prev);
        $c_next = <MCFP>;
        chomp($c_next);
        $c_date = <MCFP>;
        chomp($c_date);
        $c_from = <MCFP>;
        chomp($c_from);
        $c_subject = <MCFP>;
        chomp($c_subject);
        $c_size = <MCFP>;
        chomp($c_size);
        close(MCFP);
      }
    }
  }

  return($c_prev, $c_next, $c_date, $c_from, $c_subject, $c_size);
}

##############################################################################

sub mailmanagerMailboxCacheGetMessageSlot
{
  local($cmid) = @_;
  local($mbox, $msort, $mcdir, $mcbox, $mcfile);
  local($mcslot);

  $cmid = $g_form{'messageid'} unless ($cmid);

  $mcslot = -1;

  $mbox = $g_form{'mbox'};
  $msort = $g_form{'msort'};
  $msort = "by_date" unless ($msort);
  $mcdir = mailmanagerGetDirectoryPath("mboxcache");
  if ($mbox) {
    $mcbox = mailmanagerBuildFullPath($mbox); 
    $mcbox =~ s#^$g_users{$g_auth{'login'}}->{'home'}/##;
    $mcbox =~ s#/#,#g;
  }
  else {
    $mcbox = "INBOX";
  }
  $mcfile = $mcdir . "/" . $mcbox . "/" . $msort . "/__ORDER";
  if (-e "$mcfile") {
    if (open(MCOFP, "$mcfile")) {
      $mcslot = 1;
      while (<MCOFP>) {
        chomp;
        last if ($_ eq $cmid);
        $mcslot++;
      }
      close(MCOFP);
    }
  }
  return($mcslot);
}

##############################################################################

sub mailmanagerMailboxCacheSaveMessageInfo
{
  local($mid) = @_;
  local($mbox, $msort, $mcdir, $mcbox, $mcfile, $cmid);

  $mbox = $g_form{'mbox'};
  $msort = $g_form{'msort'};
  $msort = "by_date" unless ($msort);

  $mcdir = mailmanagerGetDirectoryPath("mboxcache");
  if ($mbox) {
    $mcbox = mailmanagerBuildFullPath($mbox); 
    $mcbox =~ s#^$g_users{$g_auth{'login'}}->{'home'}/##;
    $mcbox =~ s#/#,#g;
  }
  else {
    $mcbox = "INBOX";
  }
  $mcfile = $mcdir . "/" . $mcbox;
  unless (-e "$mcfile") {
    mkdir("$mcfile", 0700);
    chmod(0700, "$mcfile");
  }
  $mcfile .= "/" . $msort;
  unless (-e "$mcfile") {
    mkdir("$mcfile", 0700);
    chmod(0700, "$mcfile");
  }
  $cmid = $mid;
  $cmid =~ s/[^A-Za-z0-9\-\.\_]/\_/g;
  $mcfile .= "/" . $cmid;
  if (open(MCFP, ">$mcfile")) {
    print MCFP "$g_email{$mid}->{'__prevmessageid__'}\n";
    print MCFP "$g_email{$mid}->{'__nextmessageid__'}\n";
    print MCFP "$g_email{$mid}->{'date'}\n";
    if ($g_email{$mid}->{'from'}) {
      print MCFP "$g_email{$mid}->{'from'}\n";
    }
    else {
      print MCFP "$g_email{$mid}->{'__delivered_from__'}\n";
    }
    print MCFP "$g_email{$mid}->{'subject'}\n";
    print MCFP "$g_email{$mid}->{'__size__'}\n";
    close(MCFP);
  }
}

##############################################################################

sub mailmanagerMailboxCacheStatusStale
{
  local($mbox, $msort, $mcdir, $mcbox, $mcfile);
  local($mcsize, $mctime, $mboxsize, $mboxtime);
  local($fullpath, $stale);

  $stale = 1;

  $mbox = $g_form{'mbox'};
  $msort = $g_form{'msort'};
  $msort = "by_date" unless ($msort);

  $mcdir = mailmanagerGetDirectoryPath("mboxcache");
  unless ($mbox) {
    $fullpath = mailmanagerGetDefaultIncomingMailbox();
    $mcbox = "INBOX";
  }
  else {
    $fullpath = mailmanagerBuildFullPath($mbox); 
    $mcbox = $fullpath;
    $mcbox =~ s#^$g_users{$g_auth{'login'}}->{'home'}/##;
    $mcbox =~ s#/#,#g;
  }
  $mcfile = $mcdir . "/" . $mcbox . "/" . $msort . "/__STATUS";
  if (-e "$mcfile") {
    if (open(MCFP, "$mcfile")) {
      $mcsize = <MCFP>;
      chomp($mcsize);
      $mctime = <MCFP>;
      chomp($mctime);
      close(MCFP);
      ($mboxsize, $mboxtime) = (stat("$fullpath"))[7,9];
      if (($mcsize == $mboxsize) && ($mctime == $mboxtime)) {
        $stale = 0;
      }
    }
  }
  return($stale);
}

##############################################################################

sub mailmanagerMailboxCacheStatusUpdate
{
  local($mclist) = @_;
  local($mbox, $msort);
  local($mcdir, $mcbox, $mcfile, $fullpath);
  local($mboxsize, $mboxtime);

  $mbox = $g_form{'mbox'};
  $msort = $g_form{'msort'};
  $msort = "by_date" unless ($msort);

  $mcdir = mailmanagerGetDirectoryPath("mboxcache");
  if ($mbox) {
    $fullpath = mailmanagerBuildFullPath($mbox); 
    $mcbox = $fullpath;
    $mcbox =~ s#^$g_users{$g_auth{'login'}}->{'home'}/##;
    $mcbox =~ s#/#,#g;
  }
  else {
    $fullpath = mailmanagerGetDefaultIncomingMailbox();
    $mcbox = "INBOX";
  }
  $mcfile = $mcdir . "/" . $mcbox . "/" . $msort . "/__STATUS";
  if (open(MCSFP, ">$mcfile")) {
    ($mboxsize, $mboxtime) = (stat("$fullpath"))[7,9];
    print MCSFP "$mboxsize\n";
    print MCSFP "$mboxtime\n";
    close(MCSFP);
  }
  $mcfile = $mcdir . "/" . $mcbox . "/" . $msort . "/__ORDER";
  if (open(MCOFP, ">$mcfile")) {
    print MCOFP "$mclist\n";
    close(MCOFP);
  }
}

##############################################################################

sub mailmanagerMailboxCacheTidy
{
  local($mcdir, $mcache, $mcsubdir, $msubname, $fullpath, $count, $mtime);

  $mcdir = mailmanagerGetDirectoryPath("mboxcache");
  opendir(CACHEDIR, "$mcdir");
  foreach $mcache (readdir(CACHEDIR)) {
    next if (($mcache eq ".") || ($mcache eq ".."));
    # this should be a directory
    $mcsubdir = $mcdir . "/" . $mcache;
    if (-d "$mcsubdir") {
      $count = 0;
      opendir(CACHESUBDIR, "$mcsubdir");
      foreach $msubname (readdir(CACHESUBDIR)) {
        next if (($msubname eq ".") || ($msubname eq ".."));
        # these should be a directories as well
        $fullpath = $mcsubdir . "/" . $msubname;
        ($mtime) = (stat("$fullpath"))[9];
        if (($g_curtime - $mtime) > (7 * 24 * 60 * 60)) {
          # hasn't been accessed for more than a week... tidy it up
          system('rm', '-rf', $fullpath)
        }
        else {
          $count++;
        }
      }
      closedir(CACHESUBDIR);
      system('rm', '-rf', $mcsubdir) unless ($count);
    }
  }
  closedir(CACHEDIR);
}

##############################################################################

sub mailmanagerMimeDecodeHeader
{
  # decode an MIME'd mail header

  local($string) = @_;

  while (($string =~ /iso-8859-1/i) || ($string =~ /iso8859-1/i)) {
    if (($string =~ /(.*?)\=\?iso-8859-1\?b\?(.*?)\?\=(.*)/i) ||
        ($string =~ /(.*?)\=\?iso8859-1\?b\?(.*?)\?\=(.*)/i)) {
      $string = $1 . mailmanagerDecode64($2) . $3;
    }
    elsif (($string =~ /^\=\?iso-8859-1\?b\?(.*?)(\?\=){0,1}$/i) ||
           ($string =~ /^\=\?iso8859-1\?b\?(.*?)(\?\=){0,1}$/i)) {
      $string = mailmanagerDecode64($1);
    }
    elsif (($string =~ /(.*?)\=\?iso-8859-1\?q\?(.*?)\?\=(.*)/i) ||
        ($string =~ /(.*?)\=\?iso8859-1\?q\?(.*?)\?\=(.*)/i)) {
      $string = $1 . mailmanagerDecodeQuotedPrintable($2) . $3;
    }
    elsif (($string =~ /^\=\?iso-8859-1\?q\?(.*?)(\?\=){0,1}$/i) ||
           ($string =~ /^\=\?iso8859-1\?q\?(.*?)(\?\=){0,1}$/i)) {
      $string = mailmanagerDecodeQuotedPrintable($1);
    }
    else {
      last;
    }
  }
  while ($string =~ /us-ascii/i) {
    if ($string =~ /(.*?)\=\?us-ascii\?b\?(.*?)\?\=(.*)/i) {
      $string = $1 . mailmanagerDecode64($2) . $3;
    }
    elsif ($string =~ /^\=\?us-ascii\?b\?(.*?)(\?\=){0,1}$/i) {
      $string = mailmanagerDecode64($1);
    }
    elsif ($string =~ /(.*?)\=\?us-ascii\?b\?(.*?)\?\=(.*)/i) {
      $string = $1 . mailmanagerDecodeQuotedPrintable($2) . $3;
    }
    elsif ($string =~ /^\=\?us-ascii\?q\?(.*?)(\?\=){0,1}$/i) {
      $string = mailmanagerDecodeQuotedPrintable($1);
    }
    else {
      last;
    }
  }
  while ($string =~ /utf-8/i) {
    if ($string =~ /(.*?)\=\?utf-8\?b\?(.*?)\?\=(.*)/i) {
      $string = $1 . mailmanagerDecode64($2) . $3;
    }
    elsif ($string =~ /^\=\?utf-8\?b\?(.*?)(\?\=){0,1}$/i) {
      $string = mailmanagerDecode64($1);
    }
    elsif ($string =~ /(.*?)\=\?utf-8\?b\?(.*?)\?\=(.*)/i) {
      $string = $1 . mailmanagerDecodeQuotedPrintable($2) . $3;
    }
    elsif ($string =~ /^\=\?utf-8\?q\?(.*?)(\?\=){0,1}$/i) {
      $string = mailmanagerDecodeQuotedPrintable($1);
    }
    else {
      last;
    }
  }
  return($string);
}

##############################################################################

sub mailmanagerMimeDecodeHeaderJP_QP
{
  # decode an =?iso-2022-jp?q?= (quoted printable) mail header 

  local($string) = @_;

  if ($string =~ /iso-2022-jp/i) {
    while ($string =~ /iso-2022-jp/i) {
      if ($string =~ /(.*?)\=\?iso-2022-jp\?b\?(.*?)\?\=(.*)/i) {
        $string = $1 . mailmanagerDecode64($2) . $3;
      }
      elsif ($string =~ /^\=\?iso-2022-jp\?b\?(.*?)(\?\=){0,1}$/i) {
        $string = mailmanagerDecode64($1);
      }
      elsif ($string =~ /(.*?)\=\?iso-2022-jp\?q\?(.*?)\?\=(.*)/i) {
        $string = $1 . mailmanagerDecodeQuotedPrintable($2) . $3;
      }
      elsif ($string =~ /^\=\?iso-2022-jp\?q\?(.*?)(\?\=){0,1}$/i) {
        $string = mailmanagerDecodeQuotedPrintable($1);
      }
      else {
        last;
      }
    }
  }
  elsif ($string =~ /shift_jis/i) {
    while ($string =~ /shift_jis/i) {
      if ($string =~ /(.*?)\=\?shift_jis\?b\?(.*?)\?\=(.*)/i) {
        $string = $1 . mailmanagerDecode64($2) . $3;
      }
      elsif ($string =~ /^\=\?shift_jis\?b\?(.*?)(\?\=){0,1}$/i) {
        $string = mailmanagerDecode64($1);
      }
      elsif ($string =~ /(.*?)\=\?shift_jis\?q\?(.*?)\?\=(.*)/i) {
        $string = $1 . mailmanagerDecodeQuotedPrintable($2) . $3;
      }
      elsif ($string =~ /^\=\?shift_jis\?q\?(.*?)(\?\=){0,1}$/i) {
        $string = mailmanagerDecodeQuotedPrintable($1);
      }
      else {
        last;
      }
    }
  }
  return($string);
}

##############################################################################

sub mailmanagerNemetonAutoreplyGetStatus
{
  local($path, $filters_active, $homedir);

  $homedir = $g_users{$g_auth{'login'}}->{'home'};

  # check .forward first
  if (-e "$homedir/.forward") {
    open(MYFP, "$homedir/.forward");
    while (<MYFP>) {
      if ((/^\"/) && (/imanager.autoreply/)) {
        close(MYFP);
        return(1);
      }
    }
    close(MYFP);
  }

  if ((-e "/usr/local/bin/spamassassin") && (-e "/usr/local/bin/procmail")) {
    # check procmailrc file if filters are enabled
    $filters_active = mailmanagerSpamAssassinGetStatus();
    if ($filters_active) {
      $path = "$homedir/.procmailrc";
      if (-e "$path") {
        open(MYFP, "$path");
        while (<MYFP>) {
          if ((/^\|/) && (/imanager.autoreply/)) {
            close(MYFP);
            return(1);
          }
        }
        close(MYFP);
      }
    }
  }

  # return default
  return(0);
}

##############################################################################

sub mailmanagerParseBodyIntoParts
{
  local($mid, $boundary, $ctype, $pci, $curline, $header, $lastkey);
  local($endfilepos, $curfilepos, $lastfilepos, $name, $value, $li);
  local($nparts, $spci, $nsparts, $tpci, $contentid);

  $mid = $g_form{'messageid'};

  # determine if we have a multipart message or not
  $boundary = "";
  $ctype = $g_email{$mid}->{'content-type'};
  $ctype =~ s/;boundary/; boundary/;
  if (($ctype =~ /^multipart\/[a-z]*?\;.*boundary=\"(.*?)\"/i) ||
      ($ctype =~ /^multipart\/[a-z]*?\;.*boundary=(.*)/i)) {
    $boundary = $1;
  }
  return unless ($boundary);
  $g_email{$mid}->{'__boundary__'} = $boundary;

  # step through the message body; split up the message into parts, divide 
  # each part into its headers and content body
  $pci = 0;  # part content index
  unless (open(MFP, "$g_mailbox_fullpath")) {
    mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
  }
  seek(MFP, $g_email{$mid}->{'__filepos_message_body__'}, 0);
  $endfilepos = $g_email{$mid}->{'__filepos_message_end__'};
  $curfilepos = tell(MFP);
  $header = 0;
  while (<MFP>) {
    $curline = $_;
    if ($curfilepos >= $endfilepos) {
      $g_email{$mid}->{'parts'}[$pci-1]->{'__filepos_part_end__'} = $lastfilepos;
      last;
    }
    $lastfilepos = $curfilepos;
    $curfilepos = tell(MFP);
    if ($curline =~ /^\-\-\Q$boundary\E\-\-/) {
      # that's it... end of parts!  sayonara.
      $g_email{$mid}->{'parts'}[$pci-1]->{'__filepos_part_end__'} = $lastfilepos;
      last;
    }
    elsif ($curline =~ /^\-\-\Q$boundary\E/) {
      $header = 1;
      if ($pci > 0) {
        $g_email{$mid}->{'parts'}[$pci-1]->{'__filepos_part_end__'} = $lastfilepos;
      }
      $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_begin__'} = $curfilepos;
    }
    elsif ($header && ($curline eq "\n")) {
      # the end of the message part header section
      $header = 0;
      $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_body__'} = $curfilepos;
      $pci++;
    }
    elsif ($header) {
      $curline =~ s/\s+$//;
      if ($curline =~ /^\s/) {
        $curline =~ s/^\s+//;
        $g_email{$mid}->{'parts'}[$pci]->{$lastkey} .= " $curline";
        $li = $#{$g_email{$mid}->{'parts'}[$pci]->{'headers'}};
        $g_email{$mid}->{'parts'}[$pci]->{'headers'}[$li] .= " $curline";
      }
      else {
        push(@{$g_email{$mid}->{'parts'}[$pci]->{'headers'}}, $curline);
        $curline =~ /^(.*?)\:\ (.*)/;
        $name = $1;
        $value = $2;
        $name =~ tr/A-Z/a-z/;
        $g_email{$mid}->{'parts'}[$pci]->{$name} = $value;
        if (($name eq "content-id") && ($value =~ /\<(.*)\>/)) {
          # hash these content-id for use when viewing the parent content
          $contentid = $1;
          $g_email{$mid}->{'content-id'}->{$contentid} = $pci+1;
        }
        $lastkey = $name;
      }
    }
    else {
      # the body of the message part... the file position at the beginning 
      # of the part body is saved (see above) for easy access later (should
      # access be required)
    }
  }
  close(MFP);

  # now check for nested secondary level parts within the primary parts 
  $nparts = $#{$g_email{$mid}->{'parts'}};
  for ($pci=0; $pci<=$nparts; $pci++) {
    $ctype = $g_email{$mid}->{'parts'}[$pci]->{'content-type'};
    if (($ctype =~ /^multipart\/[a-z]*?\;.*boundary=\"(.*?)\"/i) ||
        ($ctype =~ /^multipart\/[a-z]*?\;.*boundary=(.*)/i)) {
      $boundary = $1;
      next unless ($boundary);
      $g_email{$mid}->{'parts'}[$pci]->{'__boundary__'} = $boundary;
      $spci = 0;  # secondary-part content index
      unless (open(MFP, "$g_mailbox_fullpath")) {
        mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
      }
      seek(MFP, $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_body__'}, 0);
      $endfilepos = $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_end__'};
      $curfilepos = tell(MFP);
      $header = 0;
      while (<MFP>) {
        $curline = $_;
        if ($curfilepos >= $endfilepos) {
          $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci-1]->{'__filepos_part_end__'} = $lastfilepos;
          last;
        }
        $lastfilepos = $curfilepos;
        $curfilepos = tell(MFP);
        if ($curline =~ /^\-\-\Q$boundary\E\-\-/) {
          # that's it... end of secondary-parts!  sayonara.
          $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci-1]->{'__filepos_part_end__'} = $lastfilepos;
          last;
        }
        elsif ($curline =~ /^\-\-\Q$boundary\E/) {
          $header = 1;
          if ($spci > 0) {
            $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci-1]->{'__filepos_part_end__'} = $lastfilepos;
          }
          $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_begin__'} = $curfilepos;
        }
        elsif ($header && ($curline eq "\n")) {
          # the end of the message part header section
          $header = 0;
          $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_body__'} = $curfilepos;
          $spci++;
        }
        elsif ($header) {
          $curline =~ s/\s+$//;
          if ($curline =~ /^\s/) {
            $curline =~ s/^\s+//;
            $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{$lastkey} .= " $curline";
            $li = $#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'headers'}};
            $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'headers'}[$li] .= " $curline";
          }
          else {
            push(@{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'headers'}}, $curline);
            $curline =~ /^(.*?)\:\ (.*)/;
            $name = $1;
            $value = $2;
            $name =~ tr/A-Z/a-z/;
            $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{$name} = $value;
            if (($name eq "content-id") && ($value =~ /\<(.*)\>/)) {
              # hash these content-id for use when viewing the parent content
              $contentid = $1;
              $g_email{$mid}->{'content-id'}->{$contentid} = $pci+1;
              $g_email{$mid}->{'content-id'}->{$contentid} .= ".";
              $g_email{$mid}->{'content-id'}->{$contentid} .= $spci+1;
            }
            $lastkey = $name;
          }
        }
        else {
          # the body of the message secondary-part... the file position at the
          # beginning of the secondary-part body is saved (see above) for easy
          # access later (should access be required)
        }
      }
      close(MFP);
    }
  }

  # now check for nested tertiary level parts within the secondary parts 
  $nparts = $#{$g_email{$mid}->{'parts'}};
  for ($pci=0; $pci<=$nparts; $pci++) {
    $nsparts = $#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}};
    for ($spci=0; $spci<=$nsparts; $spci++) {
      $ctype = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-type'};
      if (($ctype =~ /^multipart\/[a-z]*?\;.*boundary=\"(.*?)\"/i) ||
          ($ctype =~ /^multipart\/[a-z]*?\;.*boundary=(.*)/i)) {
        $boundary = $1;
        next unless ($boundary);
        $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__boundary__'} = $boundary;
        $tpci = 0;  # tertiary part content index
        unless (open(MFP, "$g_mailbox_fullpath")) {
          mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
        }
        seek(MFP, $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_body__'}, 0);
        $endfilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_end__'};
        $curfilepos = tell(MFP);
        $header = 0;
        while (<MFP>) {
          $curline = $_;
          if ($curfilepos >= $endfilepos) {
            $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci-1]->{'__filepos_part_end__'} = $lastfilepos;
            last;
          }
          $lastfilepos = $curfilepos;
          $curfilepos = tell(MFP);
          if ($curline =~ /^\-\-\Q$boundary\E\-\-/) {
            # that's it... end of sub-parts!  sayonara.
            $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci-1]->{'__filepos_part_end__'} = $lastfilepos;
            last;
          }
          elsif ($curline =~ /^\-\-\Q$boundary\E/) {
            $header = 1;
            if ($tpci > 0) {
              $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci-1]->{'__filepos_part_end__'} = $lastfilepos;
            }
            $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_begin__'} = $curfilepos;
          }
          elsif ($header && ($curline eq "\n")) {
            # the end of the message part header section
            $header = 0;
            $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_body__'} = $curfilepos;
            $tpci++;
          }
          elsif ($header) {
            $curline =~ s/\s+$//;
            if ($curline =~ /^\s/) {
              $curline =~ s/^\s+//;
              $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{$lastkey} .= " $curline";
              $li = $#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'headers'}};
              $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'headers'}[$li] .= " $curline";
            }
            else {
              push(@{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'headers'}}, $curline);
              $curline =~ /^(.*?)\:\ (.*)/;
              $name = $1;
              $value = $2;
              $name =~ tr/A-Z/a-z/;
              $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{$name} = $value;
              if (($name eq "content-id") && ($value =~ /\<(.*)\>/)) {
                # hash these content-id for use when viewing the parent content
                $contentid = $1;
                $g_email{$mid}->{'content-id'}->{$contentid} = $pci+1;
                $g_email{$mid}->{'content-id'}->{$contentid} .= ".";
                $g_email{$mid}->{'content-id'}->{$contentid} .= $spci+1;
                $g_email{$mid}->{'content-id'}->{$contentid} .= ".";
                $g_email{$mid}->{'content-id'}->{$contentid} .= $tpci+1;
              }
              $lastkey = $name;
            }
          }
          else {
            # the body of the message sub-part... the file position at the
            # beginning of the sub-part body is saved (see above) for easy
            # access later (should access be required)
          }
        }
        close(MFP);
      }
    }
  }
}

##############################################################################

sub mailmanagerParseString
{
  # code provided courtesy the perl5 Text::ParseWords library.
  # the author appreciates not having to reinvent the wheel.

  # We will be testing undef strings
  local($^W) = 0;

  my($delimiter, $keep, $string) = @_;
  my($quote, $quoted, $unquoted, $delim, $word, @pieces);
        
  while (length($string)) {
    ($quote, $quoted, undef, $unquoted, $delim, undef) =
    $string =~ m/^(["'])                 # a $quote
                  ((?:\\.|(?!\1)[^\\])*) # and $quoted text
                  \1                         # followed by the same quote
                  ([\000-\377]*)         # and the rest
                 |                       # --OR--
                 ^((?:\\.|[^\\"'])*?)    # an $unquoted text
                  (\Z(?!\n)|(?-x:$delimiter)|(?!^)(?=["']))
                                         # plus EOL, delimiter, or quote
                  ([\000-\377]*)         # the rest
                /x;                      # extended layout
    return() unless( $quote || length($unquoted) || length($delim));
    $string = $+;
    if ($keep) {
      $quoted = "$quote$quoted$quote";
    }
    else {
      $unquoted =~ s/\\(.)/$1/g;
      if (defined $quote) {
        $quoted =~ s/\\(.)/$1/g if ($quote eq '"');
        $quoted =~ s/\\([\\'])/$1/g if ($PERL_SINGLE_QUOTE && $quote eq "'");
      }
    }
    $word .= defined $quote ? $quoted : $unquoted;
    if (length($delim)) {
      push(@pieces, $word);
      push(@pieces, $delim) if ($keep eq 'delimiters');
      undef $word;
    }
    unless (length($string)) {
      push(@pieces, $word);
    }
  }
  return(@pieces);
}

##############################################################################

sub mailmanagerReadMail
{
  local($nselmsg, $curmessageid, $tmpmessageid);
  local(@selected_mids, $smid, $load_message, $msgcount, $msgslot);
  local(@curheaders, $curheader, $header, $regexmatch1, $regexmatch2);
  local($curline, $from_name, $from_email, $sortdate, $displaydate, $msize);
  local($day, $month, $year, $hour, $minute, $second, $tzsign, $tzval);
  local(%existing_mids, $curfilepos, $lastfilepos, $tmpfilepos);
  local($prevmessageid, $nextmessageid, $lmpos); 

  $nselmsg = 0;
  if ($g_form{'messageid'}) {
    @selected_mids = split(/\|\|\|/, $g_form{'messageid'});
  }

  # check if mailbox exits or is a directory?
  if ((!(-e "$g_mailbox_fullpath")) || (-d "$g_mailbox_fullpath")) {
    # uh... damnit beavis
    return(0, 0, 0, 0);
  }

  unless (open(MFP, "$g_mailbox_fullpath")) {
    mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
  }

  # <kludgealert>
  #
  # when displaying mailboxes that contain a large amount of e-mail 
  # messages with a sorting option enabled,  it is possible, in fact,
  # it is very likely that the perl process will run out of memory and
  # be killed by the watcher daemon.  so, in order to account for this,
  # the process will create a temporary kludge filename that is specific
  # to both the user, the mailbox, and process ID.  if everything proceeds 
  # normally then this file will be removed before the function returns.
  #
  # </kludgealert>
  if (mailmanagerReadMail_CheckForDeadProcessIDs()) {
    # uh oh... must have crashed last time we were trying to read this
    # mail folder.  suggest that the user view the folder unsorted.
    if ($g_form{'msort'} ne "in_order") {
      mailmanagerTrapFolderOutOfMemoryCrash();
    }
  }
  else {
    mailmanagerReadMail_StoreProcessID();
    $SIG{'TERM'} = \&mailmanagerReadMail_TermSignalHandler;
  }

  %g_email = ();

  # initialize the load_message flag
  if ($#selected_mids == -1) {
    # no messages are selected... initialize the load_message flag
    # based on the currently selected sorting option.  for any sorting
    # option other than 'in_order' we will need to load every message 
    # into memory (well... at least some specific message headers)
    if ($g_form{'msort'} eq "in_order") {
      $load_message = 0;
      $lmpos = $g_form{'mpos'};
      unless ($lmpos) {
        $msgcount = mailmanagerCountMessages($g_mailbox_fullpath);
        $lmpos = sprintf "%d", (($msgcount-1) / $g_form{'mrange'});
        $lmpos *= $g_form{'mrange'};
        $lmpos += 1;
      }
    }
    else {
      $load_message = 1;
    }
  }
  else {
    # messages are selected; only load selected messages in memory.
    # therefore, initialize the load_message flag to zero
    $load_message = 0;
  }

  # march through the mailbox
  $msgslot = -1;
  $msgcount = 0;
  $curmessageid = $prevmessageid = "";
  $msize = $header = 0;
  $curfilepos = tell(MFP);
  while (<MFP>) {
    $lastfilepos = $curfilepos;
    $curfilepos = tell(MFP);
    $curline = $_;
    # look for message demarcation lines in the format of
    #     "From sender@domain wday mon day hour:min:sec year"
    if ($curline =~ /^From\ ([^\s]*)\s+(Mon|Tue|Wed|Thu|Fri|Sat|Sun)\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+([0-9]*)\s+([0-9]*):([0-9]*):([0-9]*)\s+([0-9]*)/) {
      $regexmatch1 = $1;  # email
      $regexmatch2 = "$2 $3 $4 $5:$6:$7 $8";
      push(@curheaders, "__delivered_from__: $regexmatch1");
      push(@curheaders, "__delivered_date__: $regexmatch2");
      $tmpfilepos = $lastfilepos;
      # store a temporary message id
      $msgcount++;
      $tmpmessageid = $msgcount;
      # save the size of last message and file position at the end of the
      # message (if applicable... i.e. the message is selected)
      if ($curmessageid && $load_message) {
        $g_email{$curmessageid}->{'__size__'} = $msize;
        $g_email{$curmessageid}->{'__filepos_message_end__'} = $lastfilepos;
        if (($g_form{'msort'} eq "in_order") && ($#selected_mids == 0)) {
          # set prevmessageid and nextmessageid
          $g_email{$curmessageid}->{'__prevmessageid__'} = $prevmessageid;
          $nextmessageid = "";
          while (<MFP>) {
            $curline = $_;
            if ($curline eq "\n") {
              $nextmessageid = $tmpmessageid;
              last;
            }
            elsif ($curline =~ /^message-id:\ +(.*)/i) {
              $nextmessageid = $1;
              last;
            }
          }
          $g_email{$curmessageid}->{'__nextmessageid__'} = $nextmessageid;
        }
      }
      if (($g_form{'msort'} eq "in_order") &&
          ($#selected_mids > -1) && ($nselmesg > $#selected_mids)) {
        # drop out after all the selected messages have been loaded
        $load_message = 0;
        last;
      } 
      # reset important variables
      $prevmessageid = $curmessageid;
      $curmessageid = "";
      $msize = 0;
      $header = 1;
    }
    elsif ($header && ($curline eq "\n")) {
      # that's the end of the headers for the current message... what next?
      # if we don't have a curmessageid then use the tmpmessageid.  the
      # tmpmessageid is simply the order of the message in the file... this
      # may cause problems with coherency... but I can't think of any other
      # way keep track of a unique message id if no 'Message-Id' headers 
      # are found in the message file.  my poor feeble brain.
      $curmessageid = $tmpmessageid unless ($curmessageid);
      $existing_mids{$curmessageid} = "dau!";
      # now check to see if the current messageid matches one we are 
      # looking for... that is, if we are looking for any in particular
      # don't waste memory storing information about messages that aren't
      # selected... this would be very wasteful and pretty stupid too.
      if ($#selected_mids > -1) {
        # only load message headers if current message is selected
        $load_message = 0;
        foreach $smid (@selected_mids) {
          if ($smid eq $curmessageid) {
            $load_message = 1;
            last;
          }
        }
      }
      else {
        # no messages selected
        if ($g_form{'msort'} eq "in_order") {
          # only load message headers if current message is within the
          # range defined by mpos to mpos+g_form{mrange}-1
          $load_message = 0;
          if (($msgcount >= $lmpos) &&
              ($msgcount < ($lmpos + $g_form{'mrange'}))) {
            $load_message = 1;
          }
        }
        else {
          # sorting... load up all message headers
          $load_message = 1;
        }
      }
      # ignore x-imap messages
      for ($index=0; $index<=$#curheaders; $index++) {
        $curheaders[$index] =~ /^(.*?)\:\ (.*)/;
        if ($1 =~ /^x-imap$/i) {
          $load_message = 0;
          $msgcount--;
          last;
        }
      }
      if ($load_message) {
        $msgslot = $tmpmessageid if ($msgslot < 0);
        $nselmesg++;
        for ($index=0; $index<=$#curheaders; $index++) {
          $g_email{$curmessageid}->{'headers'}[$index] = $curheaders[$index];
          # look for specific headers like "to", "from", "subject", etc
          # build out hash structure for these headers for convenient and
          # quick access later
          $curheaders[$index] =~ /^(.*?)\:\ (.*)/;
          $regexmatch1 = $1;
          $regexmatch2 = $2;
          $regexmatch1 =~ tr/A-Z/a-z/;
          if (($regexmatch1 eq "to") || ($regexmatch1 eq "from") || 
              ($regexmatch1 eq "reply-to") || ($regexmatch1 eq "subject") ||
              ($regexmatch1 eq "cc") || ($regexmatch1 eq "date") || 
              ($regexmatch1 eq "status") || ($regexmatch1 eq "x-status") || 
              ($regexmatch1 eq "in-reply-to") || ($regexmatch1 eq "references") ||
              ($regexmatch1 eq "content-type") || 
              ($regexmatch1 eq "content-transfer-encoding") || 
              ($regexmatch1 =~ /^__/)) {
            $regexmatch2 =~ s/^\s+//;
            $g_email{$curmessageid}->{$regexmatch1} = $regexmatch2;
          }
        }
        # build up additional information from headers for sorting and for 
        # display of mailbox messages, specifically need to build out hashes
        # for "from", "date", and "size"
        #
        # build up additional "from" information
        $from_name = $g_email{$curmessageid}->{'__delivered_from__'};
        $from_email = $g_email{$curmessageid}->{'__delivered_from__'};
        if ($g_email{$curmessageid}->{'from'}) {
          if ($g_email{$curmessageid}->{'from'} =~ /(\"|)(.*?)(\"|)\s+(\<|\[|\()(.*)(\>|\]|\))/) {
            $regexmatch1 = $2;
            $regexmatch2 = $5;
            if ($regexmatch1 =~ /\@/) {
              $from_name = $regexmatch2;
              $from_email = $regexmatch1;
            }
            else {
              $from_name = $regexmatch1;
              $from_email = $regexmatch2;
            }
          }
          elsif ($g_email{$curmessageid}->{'from'} =~ /([^\s]*)\@([^\s]*)/) {
            $from_email = "$1\@$2";
            $from_name = $from_email;
          }
        }
        $g_email{$curmessageid}->{'__from_name__'} = $from_name || $from_email;
        $g_email{$curmessageid}->{'__from_email__'} = $from_email;
        # build up additional "date" information
        if ($g_email{$curmessageid}->{'date'} =~ /(\d*)\s+([A-Za-z]*)\s+(\d*)\s+(\d*):(\d*):(\d*)\s+(\+|\-)(\d*)/) {
          # dd MMM yyyy hh:mm:ss (+|-)tz
          $day = $1;
          $month = $2;
          $year = $3;
          $hour = $4;
          $minute = $5;
          $second = $6;
          $tzsign = $7;
          $tzval = $8;
          ($sortdate, $displaydate) = 
                  mailmanagerTimeBuild($year, $month, $day, 
                                       $hour, $minute, $second,
                                       $tzsign, $tzval);
        }
        elsif ($g_email{$curmessageid}->{'__delivered_date__'} =~ /([A-Za-z]*)\s+(\d*)\s+(\d*):(\d*):(\d*)\s+(\d*)/) {
          # MMM dd hh:mm:ss yyyy
          $month = $1;
          $day = $2;
          $hour = $3;
          $minute = $4;
          $second = $5;
          $year = $6;
          ($sortdate, $displaydate) = 
                  mailmanagerTimeBuild($year, $month, $day, 
                                       $hour, $minute, $second, "", "");
        }
        else {
          # date is in an unknown format
          $sortdate = 0;
          $displaydate = "Dec 31 1969";
        }
        $g_email{$curmessageid}->{'__sort_date__'} = $sortdate;
        $g_email{$curmessageid}->{'__display_date__'} = $displaydate;
        # store the slot that the message occupies in the mailbox
        $g_email{$curmessageid}->{'__order__'} = $msgcount;
        # store the file position at the beginning of the message and at the
        # beginning of the body ...store file positions now in lieu of storing
        # the body of the message in memory (which can cause sandbox problems
        # when the body of the message is sufficiently large)
        $g_email{$curmessageid}->{'__filepos_message_begin__'} = $tmpfilepos;
        $g_email{$curmessageid}->{'__filepos_message_body__'} = $curfilepos;
      }
      # reset important variables
      @curheaders = ();
      $header = 0;
    }
    elsif ($header) {
      # message header for current message
      $curheader = $curline;
      $curheader =~ s/\s+$//;
      if ($curheader =~ /^message-id:\ +(.*)/i) {
        # found a 'Message-Id' header... this makes a nice hash key
        $curmessageid = $1;
        if (defined($existing_mids{$curmessageid})) {
          # only use Message-Id if it isn't already defined (this can occur
          # when the same message is saved to a folder more than once)
          $curmessageid = "";
        }
      }
      # if header leads with white space append it to the last header,
      # otherwise push it into the current list of message headers
      if ($curheader =~ /^\s/) {
        $curheader =~ s/^\s+//;
        $curheaders[$#curheaders] .= " $curheader";
      }
      else {
        push(@curheaders, $curheader);
      }
    }
    else {
      # must be part of the current message body or white space before the
      # first message in the mailbox.  the file position at the beginning of
      # the message body is stored (see above) instead of loading the entire
      # body of the message into memory.  later, the file position will be 
      # used to either display the body of the message or break the body of 
      # the messages into parts.  so... move along... nothing to see here.
    }
    $msize += length($curline); 
  }
  close(MFP);

  # store the size of the last message in the file
  # save the size of last message in the file (and file position at the end 
  # of the message) if applicable... i.e. the message is selected
  if ($curmessageid && $load_message) {
    $g_email{$curmessageid}->{'__size__'} = $msize;
    $g_email{$curmessageid}->{'__filepos_message_end__'} = $curfilepos;
    if (($g_form{'msort'} eq "in_order") && ($#selected_mids == 0)) {
      # set prevmessageid and nextmessageid
      $g_email{$curmessageid}->{'__prevmessageid__'} = $prevmessageid;
      $g_email{$curmessageid}->{'__nextmessageid__'} = "";
    }
  }

  # set up the threaded sort fields (if applicable)
  if (!$g_form{'messageid'} && ($g_form{'msort'} eq "by_thread")) {
    mailmanagerThreadMessages();
  }

  # remove the open session filename (see kludgealert above)
  mailmanagerReadMail_RemoveProcessID();

  # return the number of messages found
  return($nselmesg, $msgcount, $msgslot, 1);
}
 
##############################################################################

sub mailmanagerReadMail_CheckForDeadProcessIDs
{
  local($kfilename, $fsize, %pids, @dead, $numdead);

  # check open session filename contents for dead process IDs; if found 
  # remove.  return(numdead)... see <kludgealert> in mailmanagerReadMail()

  $kfilename = ".open-mbox-$g_auth{'login'}";
  $kfilename .= $g_form{'mbox'} || "_INBOX";
  $kfilename =~ s/\//_/g;
  $kfilename = $g_tmpdir . "/" . $kfilename; 

  @dead = ();
  if (-e "/bin/ps") {
    open(PFP, "/bin/ps -x 2>&1 |");
    while(<PFP>) {
      s/^\s+//g;
      s/\s+/\ /g;
      if (/^([0-9]*)\ ([^\ ]*)\ ([^\ ]*)/) {
        $pids{$1}->{'tty'} = $2; 
        $pids{$1}->{'status'} = $3; 
      }
    }
    close(PFP);
    if (-e "$kfilename") {
      open(TFP, ">$kfilename.$$");
      open(SFP, "$kfilename");
      while (<SFP>) {
        chomp;
        if (defined($pids{$_})) {
          print TFP "$_\n";
        }
        else {
          push(@dead, $_);
        }
      }
      close(SFP); 
      close(TFP); 
      rename("$kfilename.$$", $kfilename);
      ($fsize) = (stat($kfilename))[7];
      unlink($kfilename) if ($fsize == 0);
    }
  }

  # return number of dead process IDs found
  $numdead = $#dead + 1;
  return($numdead);
}

##############################################################################

sub mailmanagerReadMail_RemoveProcessID
{
  local($kfilename, $fsize);

  # remove the process ID from the open session filename; for more info 
  # see <kludgealert> in mailmanagerReadMail()

  $kfilename = ".open-mbox-$g_auth{'login'}";
  $kfilename .= $g_form{'mbox'} || "_INBOX";
  $kfilename =~ s/\//_/g;
  $kfilename = $g_tmpdir . "/" . $kfilename;

  if (-e "$kfilename") {
    open(TFP, ">$kfilename.$$");
    open(SFP, "$kfilename");
    while (<SFP>) {
      chomp;
      next if ($_ eq $$);
      print TFP "$_\n";
    }
    close(SFP); 
    close(TFP); 
    rename("$kfilename.$$", $kfilename);
    ($fsize) = (stat($kfilename))[7];
    unlink($kfilename) if ($fsize == 0);
  }
}

##############################################################################

sub mailmanagerReadMail_StoreProcessID
{
  local($kfilename);

  # store process id to open session filename contents; for more info 
  # see <kludgealert> in mailmanagerReadMail()

  $kfilename = ".open-mbox-$g_auth{'login'}";
  $kfilename .= $g_form{'mbox'} || "_INBOX";
  $kfilename =~ s/\//_/g;
  $kfilename = $g_tmpdir . "/" . $kfilename;

  if (-e "/bin/ps") {
    open(KFP, ">>$kfilename");
    print KFP "$$\n";
    close(KFP);
  }
}

##############################################################################

sub mailmanagerReadMail_TermSignalHandler
{
  mailmanagerReadMail_RemoveProcessID();
  $SIG{'TERM'} = 'DEFAULT';
}

##############################################################################

sub mailmanagerResourceError
{
  local($errmsg) = @_;
  local($os_error, $key);

  $os_error = $!;

  # do some housekeeping
  foreach $key (keys(%g_form)) {
    if ($key =~ /^fileupload/) {
      unlink($g_form{$key}->{'content-filename'});
    }
  }

  encodingIncludeStringLibrary("mailmanager");
    
  unless ($g_response_header_sent) {
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($MAILMANAGER_RESOURCE_ERROR_TITLE);
    htmlText($MAILMANAGER_RESOURCE_ERROR_TEXT);
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

sub mailmanagerSelectDestinationFileFromList
{
  local($destdir) = @_;
  local($virtualdestdir);
  local($filename, $filefullpath, $fsize, $mtime, $vpath);
  local($maxlen, $len, $maxnumlen, $numlen, $numcols, $string);
  local($fmtstring1, $fmtstring2, $timestring, $sizestring);
  local($fcount, $tcount);

  # function to display a listing of files (short or long versions 
  # available) that can be used to set the g_form{'destfile'}.  this
  # function is used by both the select mailbox and save message utils
  # note: destdir is presumed to be a directory

  # another note: if defined(g_form{'messagepart'}) then this function is 
  # being used to save a selected attachment to a file (versus saving a
  # selected message to a mailbox).  behavior will only differ slightly; 
  # for example, no need to show the number of messages for files in the
  # long format.

  # still another note: added some stuff if g_form{'localattach'} is
  # defined.  support for selecting pathnames of files on the local server
  # which are to be attached to an outgoing mail message.

  # yet another note: added some stuff if g_form{'fcc_folder'} is defined.
  # sets the value of the outgoing fcc in the new mail message form.

  # make sure destdir actually is a directory
  unless (-d "$destdir") {
    $destdir =~ s/\/$//;
    $destdir =~ s/[^\/]+$//g;
  }
  unless ($destdir eq "/") {
    $destdir =~ s/\/$//;  # take out trailing slashes
  }
  $virtualdestdir = $destdir;
  unless ($g_users{$g_auth{'login'}}->{'path'} eq "/") {
    $virtualdestdir =~ s/^$g_users{$g_auth{'login'}}->{'path'}//;
  }
  unless ($virtualdestdir eq "/") {
    $virtualdestdir =~ s/\/$//;  # take out trailing slashes
  }
  $maxlen = -1;
  opendir(CURDIR, "$destdir");
  foreach $filename (readdir(CURDIR)) {
    next if ($filename eq ".");
    next if ($filename eq ".htaccess");
    next if (($filename eq "..") && (!$virtualdestdir));
    next if (($filename eq "..") && ($virtualdestdir eq "/"));
    $len = length($filename) + 4;  # 4 extra characters for </a>
    $filefullpath = $destdir . "/" . $filename;
    $fg_files{$filename}->{'fullpath'} = $filefullpath;
    if (-l "$filefullpath") {
      $len++;  # for the '@'
      $fg_files{$filename}->{'type'} = "link";
      if ($g_form{'viewtype'} eq "long") {
        ($fsize, $mtime) = (lstat($filefullpath))[7,9];
        $fg_files{$filename}->{'size'} = "link";
        $fg_files{$filename}->{'fsize'} = $fsize;
        $fg_files{$filename}->{'mtime'} = $mtime;
        $fg_files{$filename}->{'target'} = readlink($filefullpath);
      }
    }
    elsif (-d "$filefullpath") {
      $len += 2;  # for the '[]'
      $fg_files{$filename}->{'type'} = "directory";
    }
    else {  # plain file
      $fg_files{$filename}->{'type'} = "file";
      if ($g_form{'viewtype'} eq "long") {
        ($fsize, $mtime) = (stat($filefullpath))[7,9];
        $fg_files{$filename}->{'fsize'} = $fsize;
        $fg_files{$filename}->{'mtime'} = $mtime;
        unless ($g_form{'messagepart'} || $g_form{'localattach'}) {
          $fg_files{$filename}->{'nmesg'} = mailmanagerCountMessages($filefullpath);
          $numlen = length($fg_files{$filename}->{'nmesg'});
          $maxnumlen = $numlen if ($numlen > $maxnumlen);
        }
      }
    }
    $maxlen = $len if ($len > $maxlen);
  }
  closedir(CURDIR);

  $string = $MAILMANAGER_FOLDER_SELECT_CURDIR;
  $string =~ s/__DIR__/$virtualdestdir/;
  htmlTextBold($string);
  htmlText("&#160; &#160; &#160; &#160;");
  $string = "mbox=";
  $string .= encodingStringToURL($g_form{'mbox'});
  $string .= "&destfile=";
  $string .= encodingStringToURL($virtualdestdir);
  if ($ENV{'SCRIPT_NAME'} !~ /mm_select.cgi/) {
    if ($g_form{'mpos'}) {
      $string .= "&mpos=$g_form{'mpos'}";
    }
    if ($g_form{'mrange'}) {
      $string .= "&mrange=$g_form{'mrange'}";
    }
  }
  if ($g_form{'msort'}) {
    $string .= "&msort=$g_form{'msort'}";
  }
  if ($g_form{'midfile'}) {
    $string .= "&midfile=";
    $string .= encodingStringToURL($g_form{'midfile'});
  }
  if ($g_form{'viewtype'} eq "short") {
    $string .= "&viewtype=long";
    if ((defined($g_form{'fcc_folder'})) || (defined($g_form{'localattach'}))) {
      if (defined($g_form{'fcc_folder'})) {
        $string .= "&fcc_folder=$g_form{'fcc_folder'}";
      }
      if (defined($g_form{'localattach'})) {
        $string .= "&localattach=$g_form{'localattach'}";
      }
      $title = $MAILMANAGER_FOLDER_SELECT_SHOW_DETAILS_FILE;
    }
    else {
      $title = $MAILMANAGER_FOLDER_SELECT_SHOW_DETAILS_MAIL;
    }
    $title =~ s/\s+/\ /g;
    htmlText("[&#160;");
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$string", "title", "$title");
    htmlAnchorText($MAILMANAGER_FOLDER_SELECT_SHOW_DETAILS);
    htmlAnchorClose();
    htmlText("&#160;]");
  }
  else {
    $string .= "&viewtype=short";
    if ((defined($g_form{'fcc_folder'})) || (defined($g_form{'localattach'}))) {
      if (defined($g_form{'fcc_folder'})) {
        $string .= "&fcc_folder=$g_form{'fcc_folder'}";
      }
      if (defined($g_form{'localattach'})) {
        $string .= "&localattach=$g_form{'localattach'}";
      }
      $title = $MAILMANAGER_FOLDER_SELECT_HIDE_DETAILS_FILE;
    }
    else {
      $title = $MAILMANAGER_FOLDER_SELECT_HIDE_DETAILS_MAIL;
    }
    $title =~ s/\s+/\ /g;
    htmlText("[&#160;");
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$string", "title", "$title");
    htmlAnchorText($MAILMANAGER_FOLDER_SELECT_HIDE_DETAILS);
    htmlAnchorClose();
    htmlText("&#160;]");
  }
  htmlPre();
  htmlFont("class", "fixed", "face", "courier new, courier", "size", "2",
           "style", "font-family:courier new, courier; font-size:12px");
  if ($g_form{'viewtype'} eq "long") {
    $fmtstring1 = "%-" . $maxlen . "s";
  }
  else {
    if ($maxlen <= 0) {
      $numcols = 3;
    }
    else {
      $numcols = sprintf "%d", 80 / $maxlen;
    }
    $fmtstring1 = "%-" . ($maxlen+4) . "s";
    # set the display row that the files should be displayed on; this is
    # my attempt to mimic the behavior of ls when listing files
    $fcount = 0;
    $tcount = keys(%fg_files);
    $g_form{'viewtype'} = "long";  # must temporarily set to long
    foreach $filename (sort mailmanagerByListingType(keys(%fg_files))) {
      $fg_files{$filename}->{'row'} = $fcount;
      $fcount++;
      $fcount = 0 if ($fcount > ($tcount / $numcols));
    }
    $g_form{'viewtype'} = "short";
    $fcount = 0;
  }
  foreach $filename (sort mailmanagerByListingType(keys(%fg_files))) {
    $string = "viewtype=$g_form{'viewtype'}";
    $string .= "&destfile=";
    $vpath = $virtualdestdir . "/" . $filename;
    $vpath =~ s/\/\//\//g;
    $string .= encodingStringToURL($vpath);
    $title = $MAILMANAGER_FOLDER_SELECT_TARGET;
    $title =~ s/__TARGET__/$vpath/;
    if ((defined($g_form{'fcc_folder'})) || (defined($g_form{'localattach'}))) {
      # selecting a target file from message composition form
      if (defined($g_form{'fcc_folder'})) {
        $string .= "&fcc_folder=$g_form{'fcc_folder'}";
      }
      else {
        $string .= "&localattach=$g_form{'localattach'}";
      }
      if (($fg_files{$filename}->{'type'} eq "link") || 
          ($fg_files{$filename}->{'type'} eq "directory")) {
        htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$string", "title", $title);
      }
      else {
        htmlAnchor("href", "donothing.cgi?$string", "title", $title,
                   "onClick", "document.selectForm.destfile.value = '$vpath'; updateParent(); return false;");
      }
    }
    else {
      # saving selected messages to a target; changing mail folder
      $string .= "&mbox=";
      $string .= encodingStringToURL($g_form{'mbox'});
      if ($ENV{'SCRIPT_NAME'} !~ /mm_select.cgi/) {
        if ($g_form{'mpos'}) {
          $string .= "&mpos=$g_form{'mpos'}";
        }
        if ($g_form{'mrange'}) {
          $string .= "&mrange=$g_form{'mrange'}";
        }
      }
      if ($g_form{'msort'}) {
        $string .= "&msort=$g_form{'msort'}";
      }
      if ($g_form{'midfile'}) {
        $string .= "&midfile=";
        $string .= encodingStringToURL($g_form{'midfile'});
      }
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$string", "title", $title,
                 "onClick", "document.selectForm.destfile.value = '$vpath'; document.selectForm.submit(); return false");
    }
    if ($g_form{'viewtype'} eq "long") {
      # long listing
      if ($fg_files{$filename}->{'type'} eq "link") {
        unless ($g_form{'messagepart'} || $g_form{'localattach'}) {
          $fmtstring2 = "%-" . $maxnumlen . "s";
          printf "$fmtstring1    $fmtstring2 %s   %s", 
                 "$filename</a>\@", " ", $MAILMANAGER_FOLDER_SELECT_SYMLINK,
                 "--> $fg_files{$filename}->{'target'}";
        }
        else {
          printf "$fmtstring1    %s   %s", 
                 "$filename</a>\@", $MAILMANAGER_FOLDER_SELECT_SYMLINK,
                 "--> $fg_files{$filename}->{'target'}";
        }
      }
      elsif ($fg_files{$filename}->{'type'} eq "directory") {
        printf "$fmtstring1", "$filename</a>\/"; 
      }
      else {  # plain file
        $timestring = dateBuildTimeString("alpha", 
                                          $fg_files{$filename}->{'mtime'});
        $timestring = dateLocalizeTimeString($timestring);
        if ($fg_files{$filename}->{'fsize'} < 1e3) {
          $sizestring = sprintf("%s $BYTES", $fg_files{$filename}->{'fsize'});
        }
        elsif ($fg_files{$filename}->{'fsize'} < 1048576) {
          $sizestring = sprintf("%1.1f $KILOBYTES",
                                ($fg_files{$filename}->{'fsize'} / 1024));
        }
        else {
          $sizestring = sprintf("%1.2f $MEGABYTES",
                              ($fg_files{$filename}->{'fsize'} / 1048576));
        }
        unless ($g_form{'messagepart'} || $g_form{'localattach'}) {
          $fmtstring2 = "%" . $maxnumlen . "d";
          printf "$fmtstring1    $fmtstring2 %s   %s   %s", 
                 "$filename</a>", $fg_files{$filename}->{'nmesg'}, 
                 $MAILMANAGER_FOLDER_SELECT_MESSAGES, $timestring, $sizestring;
        }
        else {
          printf "$fmtstring1    %s   %s", 
                 "$filename</a>", $timestring, $sizestring;
        }
      }
      print "\n";
    }
    else {
      # short columnar listing
      if ($fcount != $fg_files{$filename}->{'row'}) {
        $fcount = $fg_files{$filename}->{'row'};
        print "\n";
      }
      if ($fg_files{$filename}->{'type'} eq "link") {
        printf "$fmtstring1", "$filename</a>\@";
      }
      elsif ($fg_files{$filename}->{'type'} eq "directory") {
        printf "$fmtstring1", "$filename</a>\/";
      }
      else {
        printf "$fmtstring1", "$filename</a>";
      }
    }
  }
  htmlFontClose();
  htmlPreClose();
}

##############################################################################

sub mailmanagerShowMailSidebar
{
  local($args, $homedir, $count);
  local($path, $opath, $spath, $encpath, $fullpath);
  local(%mailboxes, $ar_enabled);

  # folder list
  htmlTable("align", "center", "cellspacing", "5", "width", "100%");
  htmlTableRow();
  htmlTableData();
  htmlTable("cellspacing", "1", "cellpadding", "1", "border", "0", 
            "bgcolor", "#000000", "width", "100%");
  htmlTableRow();
  htmlTableData("bgcolor", "#9999cc");
  htmlNoBR();
  htmlTextBold("&#160;$MAILMANAGER_FOLDER_LIST&#160;&#160;&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("bgcolor", "#cccccc");
  $args = "mbox=&msort=$g_form{'msort'}&epoch=$g_curtime";
  htmlNoBR();
  htmlText("&#160;");
  htmlAnchor("href", "mailmanager.cgi?$args",
             "title", 
             "$MAILMANAGER_SELECT_MAILBOX: {$MAILMANAGER_DEFAULT_FOLDER}",
             "onMouseOver",
             "window.status='$MAILMANAGER_SELECT_MAILBOX: {$MAILMANAGER_DEFAULT_FOLDER}'; return true",
             "onMouseOut", "window.status=''; return true");
  htmlAnchorText($MAILMANAGER_DEFAULT_FOLDER);
  htmlAnchorClose();
  htmlText("&#160;&#160;");
  htmlNoBRClose();
  htmlBR();
  $opath = $g_prefs{'mail__default_folder'} . "/outgoing";
  $encpath = encodingStringToURL($opath);
  $args = "mbox=$encpath&msort=$g_form{'msort'}&epoch=$g_curtime";
  htmlNoBR();
  htmlText("&#160;");
  htmlAnchor("href", "mailmanager.cgi?$args",
             "title", "$MAILMANAGER_SELECT_MAILBOX: $opath",
             "onMouseOver",
             "window.status='$MAILMANAGER_SELECT_MAILBOX: $opath'; return true",
             "onMouseOut", "window.status=''; return true");
  htmlAnchorText($MAILMANAGER_FOLDER_OUT);
  htmlAnchorClose();
  htmlText("&#160;&#160;");
  htmlNoBRClose();
  htmlBR();
  if (($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full") &&
      (-e "/usr/local/bin/spamassassin") && (-e "/usr/local/bin/procmail")) {
    mailmanagerSpamAssassinLoadSettings();
    if ($g_filters{'spamfolder'} ne "/dev/null") {
      $spath = $g_filters{'spamfolder'}
    }
    elsif ($g_filters{'spamfolder'}) {
      $spath = $g_filters{'last_spamfolder'}
    }
    else {
      $spath = "~/Mail/spam";
    }
    $spath =~ s/^\$HOME/\~/;
    $encpath = encodingStringToURL($spath);
    $args = "mbox=$encpath&msort=in_order&epoch=$g_curtime";
    htmlNoBR();
    htmlText("&#160;");
    htmlAnchor("href", "mailmanager.cgi?$args",
               "title", "$MAILMANAGER_SELECT_MAILBOX: $spath",
               "onMouseOver",
               "window.status='$MAILMANAGER_SELECT_MAILBOX: $spath'; return true",
               "onMouseOut", "window.status=''; return true");
    htmlAnchorText($MAILMANAGER_FOLDER_JUNK);
    htmlAnchorClose();
    htmlText("&#160;&#160;");
    htmlNoBRClose();
    htmlBR();
  }
  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  if (open(LFP, "$homedir/.imanager/last.mailbox")) {
    $count = 0;
    while (<LFP>) {
      $path = $_;
      chomp($path);
      $path =~ s/^$homedir/\~\//;
      $path =~ s#/+#/#g;
      next if ($path eq $opath);
      next if ($path eq $spath);
      $fullpath = mailmanagerBuildFullPath($path);
      next unless (-e "$fullpath");
      next if (defined($mailboxes{$path}));
      $count++;
      last if ($count > 5);
      if ($count == 1) {
        htmlImg("width", "1", "height", "7", "src", "$g_graphicslib/sp.gif");
        htmlBR();
        htmlTable("cellpadding", "0", "cellspacing", "0", "border", "0",
                  "align", "center", "width", "98%");
        htmlTableRow();
        htmlTableData("bgcolor", "#999999");
        htmlImg("width", "20", "height", "1", "src", "$g_graphicslib/sp.gif");
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableClose();
        htmlImg("width", "1", "height", "2", "src", "$g_graphicslib/sp.gif");
        htmlBR();
      }
      $encpath = encodingStringToURL($path);
      $args = "mbox=$encpath&msort=$g_form{'msort'}&epoch=$g_curtime";
      htmlNoBR();
      htmlText("&#160;");
      htmlAnchor("href", "mailmanager.cgi?$args",
                 "title", "$MAILMANAGER_SELECT_MAILBOX: $path",
                 "onMouseOver",
                 "window.status='$MAILMANAGER_SELECT_MAILBOX: $path'; return true",
                 "onMouseOut", "window.status=''; return true");
      htmlAnchorText($path);
      htmlAnchorClose();
      htmlText("&#160;&#160;");
      htmlNoBRClose();
      htmlBR();
      $mailboxes{$path} = "dau!";
    }
    close(LFP);
  }
  htmlImg("width", "1", "height", "7", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  htmlTable("cellpadding", "0", "cellspacing", "0", "border", "0",
            "align", "center", "width", "98%");
  htmlTableRow();
  htmlTableData("bgcolor", "#999999");
  htmlImg("width", "20", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlImg("width", "1", "height", "2", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  $path = $g_form{'mbox'};
  $encpath = encodingStringToURL($path);
  $args = "mbox=$encpath&msort=$g_form{'msort'}";
  htmlNoBR();
  htmlText("&#160;");
  htmlAnchor("href", "mm_select.cgi?$args",
             "title", $MAILMANAGER_SELECT_MAILBOX,
             "onMouseOver",
             "window.status='$MAILMANAGER_SELECT_MAILBOX'; return true",
             "onMouseOut", "window.status=''; return true");
  htmlAnchorText($MAILMANAGER_FOLDER_OTHER);
  htmlAnchorClose();
  htmlText("&#160;&#160;");
  htmlNoBRClose();
  htmlBR();
  htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlBR();

  if ($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full") {
    # address book
    htmlTable("align", "center", "cellspacing", "5", "width", "100%");
    htmlTableRow();
    htmlTableData();
    htmlTable("cellspacing", "1", "cellpadding", "1", "border", "0", 
              "bgcolor", "#000000", "width", "100%");
    htmlTableRow();
    htmlTableData("bgcolor", "#9999cc");
    htmlNoBR();
    htmlTextBold("&#160;$MAILMANAGER_ADDRESSBOOK_TITLE_SHORT&#160;&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData("bgcolor", "#cccccc");
    $encpath = encodingStringToURL($g_form{'mbox'});
    $args = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'}, 
                           "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'});
    htmlNoBR();
    htmlText("&#160;");
    htmlAnchor("href", "mm_addressbook.cgi?$args&epoch=$g_curtime",
        "title", $MAILMANAGER_ADDRESSBOOK_CONTACT_VIEW,
        "onMouseOver",
        "window.status='$MAILMANAGER_ADDRESSBOOK_TITLE_SHORT: $MAILMANAGER_ADDRESSBOOK_CONTACT_VIEW'; return true",
        "onMouseOut", "window.status=''; return true");
    htmlAnchorText($MAILMANAGER_ADDRESSBOOK_CONTACT_VIEW);
    htmlAnchorClose();
    htmlText("&#160;&#160;");
    htmlNoBRClose();
    htmlBR();
    htmlNoBR();
    htmlText("&#160;");
    htmlAnchor("href", "mm_addressbook.cgi?$args&action=add&epoch=$g_curtime",
        "title", $MAILMANAGER_ADDRESSBOOK_ADD,
        "onMouseOver",
        "window.status='$MAILMANAGER_ADDRESSBOOK_TITLE_SHORT: $MAILMANAGER_ADDRESSBOOK_ADD'; return true",
        "onMouseOut", "window.status=''; return true");
    htmlAnchorText($MAILMANAGER_ADDRESSBOOK_ADD);
    htmlAnchorClose();
    htmlText("&#160;&#160;");
    htmlNoBRClose();
    htmlBR();
    htmlNoBR();
    htmlText("&#160;");
    htmlAnchor("href", "mm_addressbook.cgi?$args&action=import&epoch=$g_curtime",
        "title", $MAILMANAGER_ADDRESSBOOK_IMPORT,
        "onMouseOver",
        "window.status='$MAILMANAGER_ADDRESSBOOK_TITLE_SHORT: $MAILMANAGER_ADDRESSBOOK_IMPORT'; return true",
        "onMouseOut", "window.status=''; return true");
    htmlAnchorText($MAILMANAGER_ADDRESSBOOK_IMPORT_SHORT);
    htmlAnchorClose();
    htmlText("&#160;&#160;");
    htmlNoBRClose();
    htmlBR();
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    # spam filters
    if ((-e "/usr/local/bin/spamassassin") && (-e "/usr/local/bin/procmail")) {
      htmlTable("align", "center", "cellspacing", "5", "width", "100%");
      htmlTableRow();
      htmlTableData();
      htmlTable("cellspacing", "1", "cellpadding", "1", "border", "0", 
                "bgcolor", "#000000", "width", "100%");
      htmlTableRow();
      htmlTableData("bgcolor", "#9999cc");
      htmlNoBR();
      htmlTextBold("&#160;$MAILMANAGER_FILTERS_TITLE&#160;&#160;&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("bgcolor", "#cccccc");
      htmlNoBR();
      if ($g_filters{'status'}) {
        htmlText("&#160;$MAILMANAGER_FILTERS_STATUS_ON&#160;&#160;");
      }
      else {
        htmlText("&#160;$MAILMANAGER_FILTERS_STATUS_OFF&#160;&#160;");
      }
      htmlNoBRClose();
      htmlBR();
      htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
      htmlBR();
      htmlTable("cellpadding", "0", "cellspacing", "0", "border", "0",
                "align", "center", "width", "98%");
      htmlTableRow();
      htmlTableData("bgcolor", "#999999");
      htmlImg("width", "20", "height", "1", "src", "$g_graphicslib/sp.gif");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlImg("width", "1", "height", "2", "src", "$g_graphicslib/sp.gif");
      htmlBR();
      htmlNoBR();
      htmlText("&#160;");
      htmlAnchor("href", "mm_filters.cgi?$args&epoch=$g_curtime",
          "title", $MAILMANAGER_FILTERS_EDIT,
          "onMouseOver", "window.status='$MAILMANAGER_FILTERS_EDIT'; return true",
          "onMouseOut", "window.status=''; return true");
      htmlAnchorText($MAILMANAGER_FILTERS_EDIT);
      htmlAnchorClose();
      htmlText("&#160;&#160;");
      htmlNoBRClose();
      htmlBR();
      htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
      htmlBR();
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
      htmlBR();
    }
    # autoresponder
    htmlTable("align", "center", "cellspacing", "5", "width", "100%");
    htmlTableRow();
    htmlTableData();
    htmlTable("cellspacing", "1", "cellpadding", "1", "border", "0", 
              "bgcolor", "#000000", "width", "100%");
    htmlTableRow();
    htmlTableData("bgcolor", "#9999cc");
    htmlNoBR();
    htmlTextBold("&#160;$MAILMANAGER_AUTOREPLY_TITLE_SHORT&#160;&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData("bgcolor", "#cccccc");
    htmlNoBR();
    $ar_enabled = mailmanagerNemetonAutoreplyGetStatus();
    if ($ar_enabled) {
      htmlText("&#160;$MAILMANAGER_AUTOREPLY_STATUS_ON&#160;&#160;");
    }
    else {
      htmlText("&#160;$MAILMANAGER_AUTOREPLY_STATUS_OFF&#160;&#160;");
    }
    htmlNoBRClose();
    htmlBR();
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlTable("cellpadding", "0", "cellspacing", "0", "border", "0",
              "align", "center", "width", "98%");
    htmlTableRow();
    htmlTableData("bgcolor", "#999999");
    htmlImg("width", "20", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlImg("width", "1", "height", "2", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlNoBR();
    htmlText("&#160;");
    htmlAnchor("href", "mm_autoresponder.cgi?$args&epoch=$g_curtime",
        "title", $MAILMANAGER_AUTOREPLY_EDIT_SETTINGS_SHORT,
        "onMouseOver",
        "window.status='$MAILMANAGER_AUTOREPLY_EDIT_SETTINGS_SHORT'; return true",
        "onMouseOut", "window.status=''; return true");
    htmlAnchorText($MAILMANAGER_AUTOREPLY_EDIT_SETTINGS_SHORT);
    htmlAnchorClose();
    htmlText("&#160;&#160;");
    htmlNoBRClose();
    htmlBR();
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlBR();
  }
}

##############################################################################

sub mailmanagerSpamAssassinDaemonEnabled
{
  local($enabled);

  # determine if the system is using the spamd to process mail
  $enabled = 0;
  if ($g_platform_type eq "virtual") {
    if (open(RC, "/etc/rc")) {
      while (<RC>) {
        next if (/^\#/);
        chomp;
        if (m#/usr/local/bin/spamd#) {
          $enabled = 1;
          last;
        }
      }
      close(RC);
    }
  }
  else {
    if (open(RC, "/etc/rc.conf")) {
      while (<RC>) {
        next if (/^\#/);
        chomp;
        if (m#^spamd_enable=?"yes?"$#i) {
          $enabled = 1;
          last;
        }
      }
      close(RC);
    }
  }
  return($enabled);
}

##############################################################################

sub mailmanagerSpamAssassinGetStatus
{
  local($status, $impbp, $homedir, $lda);
  
  # returns status = 0 if filters are not active
  # returns status > 0 if filters are active
  # returns status = 1 if filters are active; invoked via .forward
  # returns status = 2 if filters are active; invoked via local mailer
  $status = 0;
  
  # impbp = incoming mail processed by procmail
  # if impbp = 1; procmail invoked via .forward
  # if impbp = 2; procmail invoked via local mailer
  $impbp = 0;
  
  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  
  # check .forward file for procmail invoke
  if (-e "$homedir/.forward") { 
    open(MYFP, "$homedir/.forward");
    while (<MYFP>) {   
      if ((/^\"/) && (m#/usr/local/bin/procmail#) &&
          (-e "$homedir/.procmailrc")) {
        $impbp = 1;
        last;
      }
    }
    close(MYFP);
  }

  # check the local mailer definition
  $lda = mailmanagerGetLocalDeliveryAgent();
  if (($lda =~ m#usr/local/bin/procmail#) && (-e "$homedir/.procmailrc")) {
    $impbp = 2;
  }

  if ($impbp) {
    # incoming mail for user is being processed by procmail
    # check .procmailrc file for spamassassin pipe
    open(MYFP, "$homedir/.procmailrc");
    while (<MYFP>) {
      if (m#^\|/usr/local/bin/spamassassin#) {
        $status = $impbp;
        last;
      }
      elsif (m#^\|/usr/local/bin/spamc#) {
        $status = $impbp;
        last;
      }
    }
    close(MYFP);
  }

  return($status);
}

##############################################################################

sub mailmanagerSpamAssassinGetVersion
{
  local($version, $output);

  $version = 2.54;  # earliest supported version of SpamAssassin
  if (open(PIPE, "/usr/local/bin/spamassassin -V |")) {
    $output = <PIPE>;
    chomp($output);
    if ($output =~ /spamassassin version (.*)/i) {
      $version = $1;
    }
    close(PIPE);
  }
  return($version);
}

##############################################################################

sub mailmanagerSpamAssassinLoadSettings
{
  local($filters_enabled, $fdir, $idir, $homedir, $path);
  local($prcfile, @prclines, $index, $languagepref);
  
  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  
  $filters_enabled = mailmanagerSpamAssassinGetStatus();
  $g_filters{'status'} = $filters_enabled;
  $fdir = mailmanagerGetDirectoryPath("filters");
  $idir = $fdir;
  $idir =~ s/[^\/]+$//g;
  $idir =~ s/\/+$//g;
  $prcfile = ($filters_enabled) ? "$homedir/.procmailrc" :
                                  "$idir/last.procmailrc";
       
  # load up logabstract, logfile, and spamfolder settings
  if (open(MYFP, "$prcfile")) {
    while (<MYFP>) {
      chomp;
      push(@prclines, $_);
      chomp;
    }
    close(MYFP);
    for ($index=0; $index<=$#prclines; $index++) {
      # get last logabstract setting and last logfile setting before
      # encountering the spamassassin tagging recipe
      if ($prclines[$index] =~ /^LOGABSTRACT=(.*)/) {
        $g_filters{'logabstract'} = $1;
      }
      elsif ($prclines[$index] =~ /^LOGFILE=(.*)/) {
        $g_filters{'logfile'} = $1;
      }
      elsif ($prclines[$index] =~ /X-Spam-Status:\s+Yes/i) {
        $g_filters{'spamfolder'} = $prclines[$index+1];
        last;  # drop out
      }
    }
  }
  else {
    # defaults
    $g_filters{'logabstract'} = "yes";
    $g_filters{'logfile'} = "\$HOME/spam.log";
    $g_filters{'spamfolder'} = "\$HOME/Mail/spam";
  }

  # load up required_hits, whitelist, and blacklist
  $g_filters{'required_hits'} = 5;  # default value
  @{$g_filters{'whitelist'}} = ();  # default value
  @{$g_filters{'blacklist'}} = ();  # default value
  if (open(MYFP, "$homedir/.spamassassin/user_prefs")) {
    while (<MYFP>) {
      chomp;
      if (/^required_hits\s+([0-9\.\-]*)/) {
        $g_filters{'required_hits'} = $1;
      }
      elsif (/^whitelist_from\s+.*/) {
        push(@{$g_filters{'whitelist'}}, $_);
      }
      elsif (/^whitelist_to\s+.*/) {
        push(@{$g_filters{'whitelist'}}, $_);
      }
      elsif (/^blacklist_from\s+.*/) {
        push(@{$g_filters{'blacklist'}}, $_);
      }
      elsif (/^blacklist_to\s+.*/) {
        push(@{$g_filters{'blacklist'}}, $_);
      }
    }
    close(MYFP);
  }
  else {
    # create a new user_prefs file from skel
    $languagepref = encodingGetLanguagePreference();
    if (open(TFP, ">$homedir/.spamassassin/user_prefs") &&
        open(LFP, ">$fdir/last.user_prefs")) {
      open(SFP, "$g_skeldir/spamassassin.user_prefs");
      while (<SFP>) {
        next if (/__WHITELIST__/);
        next if (/__BLACKLIST__/);
        if ((/score HTML_COMMENT_8BITS/) ||
            (/score UPPERCASE_25_50/) ||
            (/score UPPERCASE_50_75/) ||
            (/score UPPERCASE_75_100/)) {
          if (($languagepref eq "ja") || ($languagepref eq "kr") ||
              ($languagepref =~ /^zh/)) {
            # these lines need to be uncommented
            s/^\#+//;
            s/^\s+//;
          }
          else {
            $_ = "# $_" unless (/^\#/);
          }
          print TFP $_;
          print LFP $_;
        }
        else {
          s/__REQUIRED_HITS__/5/;
          print TFP $_;
          print LFP $_;
        }
      }
      close(SFP);
      close(LFP);
      close(TFP);
      # link last.user_prefs with HOME/.spamassassin/user_prefs
      utime($g_curtime, $g_curtime, "$homedir/.spamassassin/user_prefs");
      utime($g_curtime, $g_curtime, "$fdir/last.user_prefs");
    }
  }

  # set the mode based on the value of required_hits
  $g_filters{'mode'} = "default";
  if ($g_filters{'required_hits'} < 0) {
    # whitelist hits get a -100, so if 'required_hits' is less than
    # zero, then this indicates that we are in 'strict' mode
    $g_filters{'mode'} = "strict";
  }
  elsif ($g_filters{'required_hits'} >= 100) {
    # blacklist hits get a +100, so if 'required_hits' is >= 100,
    # then this indicates that we are in 'permissive' mode
    $g_filters{'mode'} = "permissive";
  }
  elsif ($g_filters{'required_hits'} == 5) {
    $g_filters{'mode'} = "default";
  }
  else {
    $g_filters{'mode'} = "custom";
  }

  # load up the last spam folder specification if the current def is /dev/null
  if ($g_filters{'spamfolder'} eq "/dev/null") {
    $path = "$fdir/last.spamfolder";
    if (-e "$path") {
      open(MFP, "$path");
      $g_filters{'last_spamfolder'} = <MFP>;
      close(MFP);
      chomp($g_filters{'last_spamfolder'});
    }
    else {
      $g_filters{'last_spamfolder'} = "\$HOME/Mail/spam";
    }
  }
}

##############################################################################

sub mailmanagerTimeBuild
{
  local($year, $month, $day, $hour, $minute, $second, $tzsign, $tzval) = @_;
  local($sortdate, $displaydate, $curyear, $curmonth, $curday);
  local(%m_to_n, @numdays, $origmonth);
  local($languagepref);

  # Note: the curious reader may be wondering why I didn't just use 
  # something like Time::Local to evaluate these date strings back into a
  # psuedo integer form like the epoch time.  well, that is a good question.
  # please refer to the explanation in dateBuildTimeString (date.pl).

  ($curday, $curmonth, $curyear) = (localtime($g_curtime))[3,4,5];
  $curyear += 1900;

  %m_to_n = ('jan','0','feb','1','mar','2','apr','3','may','4','jun','5',
             'jul','6','aug','7','sep','8','oct','9','nov','10','dec','11');
  @numdays = (31,28,31,30,31,30,31,31,30,31,30,31);
  # adjust numday array for Feb entry ($numday[1]) if leap year
  if (((($year % 100) == 0) && (($year % 400) == 0)) ||
      ((($year % 100) != 0) && (($year % 4) == 0))) {
    $numdays[1] = 29;
  }

  # scrub up the month
  $origmonth = $month;
  $month =~ tr/A-Z/a-z/;
  $month = $m_to_n{$month};

  # build the displaydate (on unadjusted date)
  $languagepref = encodingGetLanguagePreference();
  if ((($curyear == $year) && (($curmonth - $month) < 3)) ||
      (($curyear == ($year+1)) && ((($curmonth+12) - $month) < 3))) {
    # message is less than 3 months old (plus or minus a few days <wink>)
    $day = "0$day" if (($day < 10) && ($day !~ /^0/));
    if ($languagepref eq 'ja') {
      $displaydate = sprintf("%s月%02d日 %02d:%02d",
                             $origmonth, $day, $hour, $minute);
    }
    else {
      $displaydate = "$origmonth $day $hour:$minute";
    }
  }
  else {
    $day = "0$day" if (($day < 10) && ($day !~ /^0/));
    if ($languagepref eq 'ja') {
      $displaydate = sprintf("%4d年%s月%02d日",
                             $year, $origmonth, $day);
    }
    else {
      $displaydate = "$origmonth $day $year";
    }
  }

  # scrub up the other parts
  $day =~ s/^0//g;
  $hour =~ s/^0//g;
  $minute =~ s/^0//g;
  $second =~ s/^0//g;

  # adjust date for timezone 
  if ($tzsign && $tzval && (length($tzval) == 4)) {
    $tzhour = substr($tzval, 0, 2);
    $tzminute = substr($tzval, 2, 2);
    $tzhour =~ s/^0//g;
    $tzminute =~ s/^0//g;
    if ($tzsign eq "+") {
      $tzhour *= -1;
      $tzminute *= -1;
    }
    $hour += $tzhour;
    $minute += $tzminute;
    if ($minute < 0) {
      $minute += 60;
      $hour -= 1;
    }
    if ($minute > 59) {
      $minute -= 60;
      $hour += 1;
    }
    if ($hour < 0) {
      $hour += 24;
      $day -= 1;
    }
    if ($hour > 24) {
      $hour -= 24;
      $day += 1;
    }
    if ($day <= 0) {
      $month -= 1;
      if ($month < 0) {
        $month = 11;
        $year -= 1;  
      }
      $day = $numdays[$month];
    }
    if ($day > $numdays[$month]) {
      $day = 1;
      $month += 1;
      if ($month > 11) {
        $month = 0;
        $year += 1;  
      }
    }
  }

  # prefix zero
  $second = "0$second" if ($second < 10);
  $minute = "0$minute" if ($minute < 10);
  $hour = "0$hour" if ($hour < 10);
  $day = "0$day" if ($day < 10);

  # build the sortdate
  $month = "0$month" if ($month < 10);
  $sortdate = "$year$month$day$hour$minute$second";

  return($sortdate, $displaydate);
}

##############################################################################

sub mailmanagerTrapFolderOutOfMemoryCrash
{
  local($string);

  $string = $MAILMANAGER_TITLE;
  $string =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
  $string .= " : $MAILMANAGER_FOLDER_OUT_OF_MEMORY_TITLE";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($string);
  htmlTextBold($MAILMANAGER_FOLDER_OUT_OF_MEMORY_TITLE);
  htmlP();
  $string = $MAILMANAGER_FOLDER_OUT_OF_MEMORY_TEXT;
  $string =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
  htmlText($string);
  htmlP();
  formOpen("method", "POST");
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "msort", "value", "in_order");
  formInput("type", "submit", "name", "action", "value", $CONTINUE_STRING);
  formClose();
  labelCustomFooter();
  exit(0); 
}

##############################################################################

sub mailmanagerUpdateMessageStatusFlag
{
  local($newflag) = @_;
  local($mbox, $tmpfile, $msgcount, $curmessageid, $tmpmessageid);
  local($curline, $curstatus, $curxstatus, $header, $curheader);
  local(%existing_mids, $cache);

  # A = answered
  # R = read
  # O = old(?)

  if ($newflag eq "A") {
    # check 'X-Status:' header for 'A'
    return if ($g_email{$g_form{'messageid'}}->{'x-status'} =~ /A/);
  }
  elsif ($newflag eq "RO") {
    # check 'Status:' header for 'R' and 'O'
    return if (defined($g_email{$g_form{'messageid'}}->{'status'}) &&
               ($g_email{$g_form{'messageid'}}->{'status'} =~ /R/) &&
               ($g_email{$g_form{'messageid'}}->{'status'} =~ /O/));
  }

  $mbox = $g_mailbox_fullpath;
  $mbox =~ s/\//\_/g;
  $tmpfile = "$g_tmpdir/.mailbox-" . $g_auth{'login'};
  $tmpfile .= "-" . $g_curtime . "-" . $$ . $mbox;

  # need a single line of memory cache to keep the read filehandle
  # sufficiently ahead of the write filehandle
  $cache = "";
    
  # open source mailbox read only; tmp mailbox write only
  open(SFP, "$g_mailbox_fullpath") ||
    mailmanagerResourceError("open(SFP, $g_mailbox_virtualpath)");
  open(TFP, "+<$g_mailbox_fullpath") ||
    mailmanagerResourceError("open(TFP, $g_mailbox_virtualpath)");

  # march through the mailbox
  $msgcount = 1;
  $curmessageid = $curstatus = $curxstatus = "";
  $header = 0;
  while (<SFP>) {
    $curline = $_;
    # look for message demarcation lines in the format of
    #     "From sender@domain wday mon day hour:min:sec year"
    if ($curline =~ /^From\ ([^\s]*)\s+(Mon|Tue|Wed|Thu|Fri|Sat|Sun)\s(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+([0-9]*)\s([0-9]*):([0-9]*):([0-9]*)\s([0-9]*)/) {
      # new message found...  store a temporary message id 
      $tmpmessageid = $msgcount;
      # reset important variables
      $curmessageid = $curstatus = $curxstatus = "";
      $header = 1;
      $msgcount++;
    }
    elsif ($header && ($curline eq "\n")) {
      # that's the end of the headers for the current message... what next?
      # if we don't have a curmessageid then use the tmpmessageid.  the
      # tmpmessageid is simply the order of the message in the file... this
      # may cause problems with coherency... but I can't think of any other
      # way keep track of a unique message id when no 'Message-Id' headers
      # are found in the message file.  my poor feeble brain.
      $curmessageid = $tmpmessageid unless ($curmessageid);
      $existing_mids{$curmessageid} = "dau!";
      # now check to see if the current messageid matches 
      if ($curmessageid eq $g_form{'messageid'}) {
        if (($newflag eq "A") && (!$curxstatus)) {
          # new 'X-Status:' line
          unless (print TFP $cache) {
            close(SFP);
            close(TFP);
            return;
          }
          $cache = "X-Status: A\n";
        }
        elsif (($newflag eq "RO") && ((!$curstatus) || ($curstatus eq "O"))) {
          # new 'Status:' line
          unless (print TFP $cache) {
            close(SFP);
            close(TFP);
            return;
          }
          $cache = "Status: RO\n";
        }
      }
      # reset important variables
      $header = 0;
    }
    elsif ($header) {
      # message header for current message
      $curheader = $curline;
      $curheader =~ s/\s+$//;
      if ($curheader =~ /^message-id:\ +(.*)/i) {
        # found a 'Message-Id' header... this makes a nice hash key
        $curmessageid = $1;
        if (defined($existing_mids{$curmessageid})) {
          # only use Message-Id if it isn't already defined (this can occur
          # when the same message is saved to a folder more than once)
          $curmessageid = "";
        }
      }
      elsif ($curheader =~ /^x-status: (.*)/i) {
        # found a 'X-Status' header
        $curxstatus = $1;
      }
      elsif ($curheader =~ /^status: (.*)/i) {
        # found a 'Status' header
        $curstatus = $1;
      }
    }
    if ($cache) {
      unless (print TFP $cache) {
        close(SFP);
        close(TFP);
        return;
      }
    }
    $cache = $curline;
  }

  # print the cached line
  print TFP $cache;

  # close the file handles 
  close(SFP);
  close(TFP);
}

##############################################################################

sub mailmanagerUserEmailAddress
{
  local($name, $address, $email);

  $email = $g_auth{'email'} || mailmanagerUserLastEmailAddress();
  unless ($email) {
    $name = $g_users{$g_auth{'login'}}->{'name'};
    $address = mailmanagerUserSystemEmailAddress();
    $email = ($name) ? "\"$name\" <$address>" : $address;
  }
  return($email);
}

##############################################################################

sub mailmanagerUserLastEmailAddress
{
  local($homedir, $email);

  $email = "";
  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  if (-e "$homedir/.imanager/last.emailaddress") {
    if (open(LEFP, "$homedir/.imanager/last.emailaddress")) {
      $email = <LEFP>;
      close(LEFP);
      chomp($email);
    }
  }
  return($email);
}

##############################################################################

sub mailmanagerUserSystemEmailAddress
{
  local($email, $host);

  $host = mailmanagerHostAddress();
  $email = "$g_auth{'login'}\@$host";
  return($email);
}

##############################################################################

sub mailmanagerThreadGetReference
{
  local($mid) = @_;
  local($refid, @references);

  $refid = "";
  if (defined($g_email{$mid}->{'in-reply-to'})) {
    ($refid) = (split(/;/, $g_email{$mid}->{'in-reply-to'}))[0];
  }
  elsif (defined($g_email{$mid}->{'references'})) {
    @references = split(/ /, $g_email{$mid}->{'references'});
    $refid = $references[$#references];
  }
  return($refid);
}

##############################################################################

# used for message threading
local($fg_thread_order); 

##############################################################################

sub mailmanagerThreadMailMessage
{
  local($mid, $curlevel, @mids) = @_;
  local($qmid, $refid);
  
  foreach $qmid (@mids) {
    next if ($qmid eq $mid);
    next if (defined($g_email{$qmid}->{'__thread_order__'}));
    $refid = mailmanagerThreadGetReference($qmid); 
    if ($refid eq $mid) {
      $g_email{$qmid}->{'__thread_order__'} = $fg_thread_order++;
      $g_email{$qmid}->{'__thread_level__'} = $curlevel;
      mailmanagerThreadMailMessage($qmid, $curlevel+1, @mids);
    }
  }
}

##############################################################################

sub mailmanagerThreadMessages
{
  local($mid, @mids, $curlevel, $messagelevel);
  local($i_index, $j_index, $curlevelinfo);

  # build an array of message ids sorted in reverse date order
  @mids = ();
  foreach $mid (sort mailmanagerByDate(keys(%g_email))) {
    push(@mids, $mid);
  }

  # build thread order
  $fg_thread_order = 1;
  $curlevel = 1;
  foreach $mid (@mids) {
    next if (defined($g_email{$mid}->{'__thread_order__'}));
    $g_email{$mid}->{'__thread_order__'} = $fg_thread_order++;
    $g_email{$mid}->{'__thread_level__'} = $curlevel;
    mailmanagerThreadMailMessage($mid, $curlevel+1, @mids);
  }

  # rebuild array of message ids sorted in threaded order
  @mids = ();
  foreach $mid (sort mailmanagerByThread(keys(%g_email))) {
    push(@mids, $mid);
  }

  # build thread indent graphic info (__thread_info__)
  # '|' = passthrough at level n
  # '+' = passthrough branch at level n
  # '-' = terminate branch at level n
  # ' ' = none at level n
  foreach ($i_index=0; $i_index<=$#mids; $i_index++) {
    $g_email{$mids[$i_index]}->{'__thread_info__'} = "";
    # for messages not on root level (>1), follow branch
    $message_level = $g_email{$mids[$i_index]}->{'__thread_level__'};
    for ($curlevel=2; $curlevel<=$message_level; $curlevel++) {
      $curlevelinfo = ($curlevel == $message_level) ? '-' : ' ';
      for ($j_index=$i_index+1; $j_index<=$#mids; $j_index++) {
        last if ($g_email{$mids[$j_index]}->{'__thread_level__'} < $curlevel);
        if ($g_email{$mids[$j_index]}->{'__thread_level__'} == $curlevel) {
          # there is a message further down in branch on same level
          $curlevelinfo = ($curlevel == $message_level) ? '+' : '|';
          last;
        }
      }
      $g_email{$mids[$i_index]}->{'__thread_info__'} .= $curlevelinfo;
    }
  }
}

##############################################################################

sub mailmanagerValidShell
{
  local($validshell, $myshell);
  local($filters_active, $ar_enabled, $homedir, $lda, $found);

  # used by autoresponder and mail filter utilities as a quick hack to see
  # if the mail delivery subsystem can deliver mail to a program for the 
  # user.  please refer to <http://www.sendmail.org/faq/section3.html#3.11>

  # only need to check for valid shell if exec'ing from .forward file
  $filters_active = mailmanagerSpamAssassinGetStatus();
  $ar_enabled = mailmanagerNemetonAutoreplyGetStatus();
  if ($filters_active || $ar_enabled) {
    # either mail filters or autoresponder is enabled... where is it
    # being exec'd from?  .forward?  check and see.
    $found = 0;
    $homedir = $g_users{$g_auth{'login'}}->{'home'};
    if (-e "$homedir/.forward") {
      open(MYFP, "$homedir/.forward");
      while (<MYFP>) {
        if (((/^\"/) && (/imanager.autoreply/)) ||
            ((/^\"/) && (m#/usr/local/bin/procmail#))) {
          # yep... exec'd from .forward
          $found = 1;
          close(MYFP);
        }
      }
      close(MYFP);
    }
    return(1) unless($found);
  }
  else {
    # neither mail filters nor autoresponder is enabled... if the user
    # will be enabling services, then will the .forward file be used?
    $lda = mailmanagerGetLocalDeliveryAgent();
    return(1) if ($lda =~ m#usr/local/bin/procmail#);
  }

  if (open(FP, "/etc/shells")) {
    $validshell = 0;
    while (<FP>) {
      next unless (/^\//);
      $myshell = $_;
      chomp($myshell);
      return(1) if ($myshell eq "/SENDMAIL/ANY/SHELL/");
      return(1) if ($myshell eq $g_users{$g_auth{'login'}}->{'shell'});
    }
    close(FP);
  }
  else {
    # can't open /etc/shells; presume that it is a valid shell?
    $validshell = 1;
  }
  return($validshell);
}

##############################################################################
# eof

1;

