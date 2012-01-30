#
# init.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/init.pl,v 2.12.2.8 2006/04/25 19:48:23 rus Exp $
# initializes a proper environment
#

##############################################################################
#
# default language, this is what users will get if they set their own 
# language preference to "default" -- you can't just make up languages here
# and hope the strings for them exist.  only a certain subset of the
# languages spoken on this earth of ours are supported at the current time.
# please check the "strings" directory for a list of valid languages.  if
# your preferred language is not found in the "strings" directory, then take
# some initiative, translate the strings, and send them back to me to be
# included in the distribution.  many kind thanks and warm regards,  --rus.
#

$g_defaultlanguage = "en";

#
# if you are using vi to view this file (good for you!), you can get a list
# of supported languages by typing ':! ls ../strings' in the vi editor
#
##############################################################################
##############################################################################
##############################################################################
#
#
#
#
#
#
#
#
#          you proceed past this line of comments at your own risk
#
#
#
#
#
#
#
#
##############################################################################
#
# global variable initializations
#

@g_months = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec);
@g_weekdays = (Sun, Mon, Tue, Wed, Thu, Fri, Sat, Sun);

# the default content type (this will get rewritten later)
$g_default_content_type = "text/html";

##############################################################################
#
# global hashes, seems appropriate to initialize them here
#

# form data hash values (user supplied data)
%g_form = ();

# authentication info
%g_auth = ();

# hash of user entries in /etc/passwd
%g_users = ();

# hash of group entries in /etc/group
%g_groups = ();

# user preferences
%g_prefs = ();

##############################################################################
#
# figure out where all of the library files are with respect to the current
# executable call.  require statements in libraries then use these global
# variables instead of having if (-e), else statements everywhere.  wizards
# include the "library/file" and "../library/file" require statements.
#

$g_rootdir = ".";
if (($ENV{'SCRIPT_FILENAME'}) &&
    ($ENV{'SCRIPT_FILENAME'} =~ /wizards\/[a-z_]*\.cgi$/)) {
  $g_rootdir = "..";
}

$g_bindir =        $g_rootdir . "/bin";
$g_includelib =    $g_rootdir . "/library";
$g_graphicslib =   $g_rootdir . "/graphics";
$g_labellib =      $g_rootdir . "/label";
$g_prefslib =      $g_rootdir . "/preferences";
$g_userprefsdir =  $g_rootdir . "/preferences";
$g_skeldir =       $g_rootdir . "/skel";
$g_stringlib =     $g_rootdir . "/strings";
$g_tmpdir =        $g_rootdir . "/tmp";

##############################################################################
#
# set platform os and type
#
$g_platform_os = $^O;
$g_platform_os =~ tr/A-Z/a-z/;
$g_platform_type = (-e "/etc/id") ? "virtual" : "dedicated";

##############################################################################
#
# get global user id and group id (virtual environment)
#
if ($g_platform_type eq "virtual") {
  # set global user and group ids... these are used when reading from the 
  # virtual passwd file (for warnings) and writing to the virtual passwd 
  # file (in their respective gecos fields)
  $g_uid = $>;
  $g_gid = $);
  $g_gid = (split(/\s/, $g_gid))[0];
}
else {
  # dedicated env; start out with superuser (root) privileges
  $> = $< = 0;
  $) = $( = 0;
}

##############################################################################
#
# set up a no man's land tmp directory for users with no home directory.
# in a dedicated environment this directory will be used to store the users
# tmp files, prefs file, address book entries, etc.  However, in a virtual 
# environment, this directory will rarely, if ever, be used (in a virtual
# environment the main imanager tmp and prefs directories are used instead). 
#
unless (-e "/tmp/.imanager") {
  if ($g_platform_type eq "dedicated") {
    mkdir("/tmp/.imanager", 01777);
    chmod(01777, "/tmp/.imanager");
  }
  else {
    mkdir("/tmp/.imanager", 0770);
    chmod(0770, "/tmp/.imanager");
  }
}

##############################################################################
#
# set an appropriately restrictive umask (this will be reset later for
# non-privileged users)
#
umask(077);

##############################################################################
#
# set the path of important external programs which are required to function
#
if (-e "/usr/bin/uname") {
  $g_uname_path = "/usr/bin/uname";
}
else {
  $g_uname_path = "/bin/uname";
}

##############################################################################
#
# copy dependent binaries from program local bin to system local bin
#
initPlatformDependentBinaries();

##############################################################################
#
# seed the random number generator
#
$g_curtime = time();
srand($g_curtime ^ ($$ + ($$ <<15)));

##############################################################################
#
# global var which indicates whether response header has been sent to client
#
$g_response_header_sent = 0;

##############################################################################

sub initEnvironment
{
  # load required libraries
  require "$g_includelib/form.pl";
  require "$g_includelib/prefs.pl";

  # parse any form data
  formParseData();

  # load up global security preferences (from root preferences file)
  prefsLoadGlobalSecurityOptions();

  # only allow secure access?  check security option
  if ($g_prefs{'security__force_ssl_connection'} eq "yes") {
    initSecureAccessCheck(); 
  }

  # load common libraries
  require "$g_includelib/html.pl";
  require "$g_includelib/label.pl";
  require "$g_includelib/encoding.pl";
  require "$g_includelib/navigation.pl";
  require "$g_includelib/javascript.pl";
  require "$g_includelib/redirect.pl";

  # load required strings
  encodingIncludeStringLibrary("main");
  encodingIncludeStringLibrary("passwd");

  # set global default content type for output (this will be overwritten
  # later after user preferences have been loaded, but we need to set it to 
  # something here in case errors are encountered during authentication)
  encodingSetDefaultContentType();

  # load up the authentication information either from state (via the AUTH
  # cookie) or from the login form
  require "$g_includelib/auth.pl";
  authStateGet();
  unless ($g_auth{'login'} && $g_auth{'password'}) {
    authPrintLoginForm();
  }

  # authenticate the login and password information provided by the user.
  # once authentication is validated, the user preferences are loaded.
  authCheckLoginCredentials();

  # reload global, main, and auth strings now that the user preferences have
  # been loaded.  this is necessary in case the user has selected a language
  # other than g_defaultlanguage
  encodingIncludeStringLibrary("main");
  encodingIncludeStringLibrary("passwd");
  encodingIncludeStringLibrary("auth");

  # figure out the user operating system... which is convenient to know
  initRemoteUserOperatingSystem();

  # set authorization key
  authStateSet();

  # do some housekeeping on main tmp directory
  initTemporaryFileRemove();

  # change the temporary directory to be in the user directory structure
  initSetTmpDir();

  # set up environment for platform
  if ($g_platform_type eq "dedicated") {
    # set the effective user and group ids based on the login id
    initSetUID();
    # set the timezone of the user if a preference can be found
    initSetTimeZone();
    # do some housekeeping on the user tmp directory
    initTemporaryFileRemove();
  }
}

##############################################################################
  
sub initLoadUserPrefs 
{
  # this is called from authCheckLoginCredentials() after validation 

  if ($g_platform_type eq "dedicated") {
    # change the prefs directory to be in the user directory structure
    initSetPrefsDir();
  }
    
  # load up the user preferences
  prefsLoad();
      
  # also need to re-set default content-type based on user language pref
  encodingSetDefaultContentType();
}

##############################################################################

sub initPlatformApachePrefix
{
  local($prefix);

  if ($g_platform_type eq "virtual") {
    $prefix = "/usr/local/etc/httpd";
  }
  else {
    # dedicated env supports both apache/1.x and apache/2.x
    if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/1#) {
      $prefix = "/usr/local/apache";
    }
    elsif ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#) {
      $prefix = "/usr/local/apache2";
    }
    else {
      # punt
      $prefix = "/www";
    }
  }
  return($prefix);
}

##############################################################################

sub initPlatformDependentBinaries
{
  local($replace, $d_sz, $d_mt, $l_sz, $l_mt, $curchar);

  initPlatformLocalBin();

  # copy the autoply binary down to the system local bin (if necessary)
  if (-e "$g_localbin/autoreply") {
    ($d_sz, $d_mt) = (stat("$g_localbin/autoreply"))[7,9];
    if (-e "/usr/local/bin/imanager.autoreply") {
      ($l_sz, $l_mt) = (stat("/usr/local/bin/imanager.autoreply"))[7,9];
      $replace = (($d_sz != $l_sz) || ($d_mt != $l_mt)) ? 1 : 0;
    }
    else {
      $replace = 1;
    }
    if ($replace) {
      if (-e "/usr/local/bin/imanager.autoreply") {
        chmod(0755, "/usr/local/bin/imanager.autoreply");
      }
      open(SFP, "$g_localbin/autoreply");
      open(TFP, ">/usr/local/bin/imanager.autoreply");
      while (read(SFP, $curchar, 1024)) {
        print TFP "$curchar";
      }
      close(TFP);
      close(SFP);
      chmod(0555, "/usr/local/bin/imanager.autoreply");
      utime($d_mt, $d_mt, "/usr/local/bin/imanager.autoreply");
    }
  }
}

##############################################################################

sub initPlatformNetworkParameters
{
  # determine what platform we are running on and set bin path accordingly
  unless ($g_platform_os) {
    open(UNAME, "$g_uname_path -r -s |") || initPlatformUnknown("uname");
    $g_platform_os = <UNAME>;
    close(UNAME);
    $g_platform_os =~ s/[^A-Za-z0-9\.\ ]//g;
    $g_platform_os =~ tr/A-Z/a-z/;
  }
  if (($g_platform_os =~ /bsdos/) || ($g_platform_os =~ /freebsd/)) {
    $AF_INET = 2;
    $SOCK_STREAM = 1;
  } 
  elsif (($g_platform_os =~ /sunos/) || ($g_platform_os =~ /solaris/)) {
    $AF_INET = 2;
    $SOCK_STREAM = 2;
  } 
  else {
    initPlatformUnknown("unknown");
  } 
}

##############################################################################

sub initPlatformLocalBin
{
  # determine what platform we are running on and set bin path accordingly
  unless ($g_platform_os) {
    open(UNAME, "$g_uname_path -r -s |") || initPlatformUnknown("uname");
    $g_platform_os = <UNAME>;
    close(UNAME);
    $g_platform_os =~ s/[^A-Za-z0-9\.\ ]//g;
    $g_platform_os =~ tr/A-Z/a-z/;
  }
  if ($g_platform_os =~ /bsdos/) {
    $g_localbin = $g_bindir . "/BSD-OS";
  } 
  elsif ($g_platform_os =~ /freebsd/) {
    $g_localbin = $g_bindir . "/FreeBSD/4.x";
  } 
  elsif (($g_platform_os =~ /sunos/) || ($g_platform_os =~ /solaris/)) {
    $g_localbin = $g_bindir . "/SunOS";
  } 
  else {
    initPlatformUnknown("unknown");
  } 
}

##############################################################################

sub initPlatformUnknown
{
  local($error_type) = @_;

  encodingIncludeStringLibrary("main");
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($UNKNOWN_PLATFORM_TITLE);
  htmlText($UNKNOWN_PLATFORM_TEXT);
  htmlP();
  if ($error_type eq "uname") {
    htmlText("$g_uname_path -r -s");
    htmlBR();
    if ($g_platform_os) {
      htmlText($g_platform_os);
    }
    else {
      htmlTextCode($!);
    }
  }
  else {
    # unknown os
    if ($g_platform_os) {
      htmlText($g_platform_os);
    }
  }
  htmlP();
  labelCustomFooter();
  exit(0);
}
 
##############################################################################

sub initRemoteUserOperatingSystem
{
  if ($ENV{'HTTP_USER_AGENT'} =~ /windows/i) {
    $g_user_os = "windows";
  }
  elsif ($ENV{'HTTP_USER_AGENT'} =~ /mac/i) {
    $g_user_os = "mac";
  }
  else {
    $g_user_os = "other";  # Linux, *BSD, Solaris, etc
  }
}

##############################################################################

sub initSecureAccessCheck
{
  local($url, $string);

  return if ($ENV{'HTTPS'} eq "on");

  $url = "https://$ENV{'HTTP_HOST'}";
  $url .= $ENV{'SCRIPT_NAME'}; 
  $string = "";
  foreach $key (keys(%g_form)) {
    $g_form{$key} =~ s/([^a-zA-Z0-9_\-.\/])/uc sprintf("%%%02x",ord($1))/eg;
    $string .= "$key=$g_form{$key}&";
  }
  $url .= "?" . $string if (chop($string) eq "&");

  print "Content-type: $g_default_content_type\n";
  print "Location: $url\n";
  print "\n";
  exit(0);
}

##############################################################################

sub initSetPrefsDir
{
  local($homedir);

  # this function is only called when in a "dedicated" environment; changes 
  # the prefsdir definition to be one that exists in the users home directory
  # structure.

  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  if ((-e "$homedir") && ($homedir ne "/")) {
    $g_userprefsdir = "$homedir/.imanager";
    mkdir("$g_userprefsdir", 0700) unless (-e "$g_userprefsdir");
    chown($g_users{$g_auth{'login'}}->{'uid'},
          $g_users{$g_auth{'login'}}->{'gid'}, $g_tmpdir);
    chmod(0700, $g_userprefsdir);
  }
  else {
    # home directory doesn't exist or is "/" ... use a specification in 
    # no man's land (see above), i.e. /tmp/.imanager/login
    $g_tmpdir = "/tmp/.imanager/$g_auth{'login'}";
    mkdir("$g_userprefsdir", 0700) unless (-e "$g_userprefsdir");
    chown($g_users{$g_auth{'login'}}->{'uid'},
          $g_users{$g_auth{'login'}}->{'gid'}, $g_tmpdir);
    chmod(0700, $g_userprefsdir);
  }
}

##############################################################################

sub initSetTimeZone
{
  local($homedir, @scf, $configfile, $timezone);

  $homedir = $g_users{$g_auth{'login'}}->{'home'};

  # looking for a TZ environment def in any of the shell config files
  push(@scf, "$homedir/.bashrc");
  push(@scf, "$homedir/.cshrc");
  push(@scf, "$homedir/.kshrc");
  push(@scf, "$homedir/.shrc");
  push(@scf, "$homedir/.tcshrc");
  push(@scf, "$homedir/.zshrc");

  foreach $configfile (@scf) {
    open(SCF, "$configfile");
    while (<SCF>) {
      if (/^setenv\s+TZ\s+(\S+)/i) {
        $timezone = $1;
      }
    }
    close(SCF);
  }

  if ($timezone) {
    require "$g_includelib/timezone.pl";
    timezoneSet($timezone);
  }
}

##############################################################################

sub initSetTmpDir
{
  local($homedir, $key, $filename, $parentdir, $gid);

  # changes the tmpdir definition to be one that exists in the 
  # users home directory structure

  $g_maintmpdir = $g_tmpdir;

  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  if ((-e "$homedir") && ($homedir ne "/")) {
    $g_tmpdir = "$homedir/.imanager";
    mkdir("$g_tmpdir", 0700) unless (-e "$g_tmpdir");
    chown($g_users{$g_auth{'login'}}->{'uid'},
          $g_users{$g_auth{'login'}}->{'gid'}, $g_tmpdir);
    chmod(0700, $g_tmpdir);
    $g_tmpdir .= "/tmp";
    mkdir("$g_tmpdir", 0700) unless (-e "$g_tmpdir");
    chown($g_users{$g_auth{'login'}}->{'uid'},
          $g_users{$g_auth{'login'}}->{'gid'}, $g_tmpdir);
    chmod(0700, $g_tmpdir);
  }
  else {
    # home directory doesn't exist or is "/" ... use a specification in 
    # no man's land (see above), i.e. /tmp/.imanager/login
    $g_tmpdir = "/tmp/.imanager/$g_auth{'login'}";
    mkdir("$g_tmpdir", 0700) unless (-e "$g_tmpdir");
    chown($g_users{$g_auth{'login'}}->{'uid'},
          $g_users{$g_auth{'login'}}->{'gid'}, $g_tmpdir);
    chmod(0700, $g_tmpdir);
    $g_tmpdir .= "/tmp";
    mkdir("$g_tmpdir", 0700) unless (-e "$g_tmpdir");
    chown($g_users{$g_auth{'login'}}->{'uid'},
          $g_users{$g_auth{'login'}}->{'gid'}, $g_tmpdir);
    chmod(0700, $g_tmpdir);
  }

  # any uploaded files need to be moved from the central tmp directory
  # to the users local tmp directory
  foreach $key (keys(%g_form)) {
    if (defined($g_form{$key}->{'content-filename'})) {
      $g_form{$key}->{'content-filename'} =~ /([^\/]+$)/;
      $filename = "$g_tmpdir/$1";
      rename($g_form{$key}->{'content-filename'}, $filename);
      $g_form{$key}->{'content-filename'} = $filename;
      # take care of initial ownership and perms for the uploaded file;
      # these may be overwritten later
      require "$g_includelib/fm_util.pl";
      $parentdir = filemanagerGetFullPath($filename);
      ($gid) = (stat($parentdir))[5];
      chown($g_users{$g_auth{'login'}}->{'uid'}, $gid, $filename);
      if ($g_users{$g_auth{'login'}}->{'uid'} != 0) {
        chmod(0644, $filename);
      }
    }
  }
}

##############################################################################

sub initSetUID
{
  # this function is only called when in a "dedicated" environment; since the
  # cgi's in a dedicated environment all run setuid, it is prudent to lower
  # the privileges to that of the user accessing the scripts.  However, there
  # are some exceptions.  the exeptions are enumerated in the NOTE(s) below.

  local(@mg, $mygid, $idx, $gstring);

  # start out with superuser (root) privileges
  $> = $< = 0;
  $) = $( = 0;

  # virtual root user has superuser privs
  return if ($g_auth{'login'} =~ /^_.*root$/);

  ######################################################################
  #
  # NOTE: some apps require tasks to be completed with elevated privs
  #       before stepping down to a non-privileged uid
  #
  if ($ENV{'SCRIPT_NAME'} =~ /profile.cgi$/) {
    require "$g_includelib/vhost_util.pl";
    vhostHashInit();
  }

  ######################################################################
  #
  # NOTE: some users have admin rights and need elevated prvis for 
  #       certain tasks
  #
  if (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}})) {
    return if (($ENV{'SCRIPT_NAME'} =~ /aliases_[a-z]*.cgi$/) ||
               ($ENV{'SCRIPT_NAME'} =~ /mailaccess_[a-z]*.cgi$/) ||
               ($ENV{'SCRIPT_NAME'} =~ /groups_[a-z]*.cgi$/) ||
               ($ENV{'SCRIPT_NAME'} =~ /restart_apache.cgi$/) ||
               ($ENV{'SCRIPT_NAME'} =~ /spammers_[a-z]*.cgi$/) ||
               ($ENV{'SCRIPT_NAME'} =~ /users_[a-z]*.cgi$/) ||
               ($ENV{'SCRIPT_NAME'} =~ /vhosts_[a-z]*.cgi$/) ||
               ($ENV{'SCRIPT_NAME'} =~ /virtmaps_[a-z]*.cgi$/));
    if ($g_prefs{'security__elevate_admin_ftp_privs'} eq "yes") {
      return if (($ENV{'SCRIPT_NAME'} =~ /filemanager.cgi$/) ||
                 ($ENV{'SCRIPT_NAME'} =~ /fm_[a-z]*.cgi$/));
    }
  }

  ######################################################################
  #
  # NOTE: some apps that are run by non-privileged users require privs 
  #
  return if (($ENV{'SCRIPT_NAME'} =~ /changepassword.cgi$/) &&
             ($g_form{'submit'}));

  ######################################################################

  # set the effective uid and gid to that of the non-privileged user
  if ($g_users{$g_auth{'login'}}->{'uid'} != 0) {
    # set the new group id
    $gstring = "";
    @mg = groupGetUsersGroupMembership($g_auth{'login'});
    for ($idx=0; $idx<=$#mg; $idx++) {
      $gstring .= "$g_groups{$mg[$idx]}->{'gid'} ";
    }
    chop($gstring);
    $) = $gstring;
    $( = $g_users{$g_auth{'login'}}->{'gid'};
    # set the new user id
    $> = $< = $g_users{$g_auth{'login'}}->{'uid'};
    # set a less restrictive umask for the non-privileged user
    umask(022);
  }
}

##############################################################################

sub initTemporaryFileRemove
{
  local($filename) = @_;
  local($curtime, $mtime);

  if ($filename) {
    # look for temporary file with given filename and remove
    unlink($filename) if (-e "$filename");
  }

  # do some housekeeping
  $curtime = $g_curtime;
  if (-e "$g_tmpdir") {
    if (opendir(TMPDIR, "$g_tmpdir")) {
      foreach $filename (readdir(TMPDIR)) {
        next if (($filename eq ".") || ($filename eq ".."));
        next unless (-f "$g_tmpdir/$filename");
        ($mtime) = (stat("$g_tmpdir/$filename"))[9];
        if (($curtime - $mtime) > (24 * 60 * 60)) {
          # file is more than 24 hours old, probably not serving any 
          # useful purpose.... so to keep things tidy, get rid of it
          unlink("$g_tmpdir/$filename");
        }
      }
      closedir(TMPDIR);
    }
    else {
      # tmpdir exists but can't open it?  what gives?  is it a file?
      unlink($g_tmpdir);
      mkdir($g_tmpdir, 0700);
      chmod(0700, $g_tmpdir);
    }
  }
  else {
    # tmpdir doesn't exist?!  did an external process nuke it?  recreate
    # it for now in case it is needed later
    mkdir($g_tmpdir, 0700);
    chmod(0700, $g_tmpdir);
  }
}

##############################################################################

sub initUploadCookieExpireSessionID
{
  local($date, $cookie);

  $date = "Thu, 01-Jan-1970 00:00:00 GMT";
  $cookie = "SID=__EXP__; expires=$date; path=/; domain=$ENV{'HTTP_HOST'}";
  print "Set-Cookie: $cookie\n";
}

##############################################################################

sub initUploadCookieGetSessionID
{
  local($dough, @ckvpairs, $kv, $key, $value, %cookie);
  local($sessionid);

  $sessionid = "";   
  if ($ENV{'HTTP_COOKIE'}) {
    $dough = $ENV{'HTTP_COOKIE'} . ";";
    @ckvpairs = split(/\;/, $dough);
    foreach $kv (@ckvpairs) {
      ($key, $value) = split(/=/, $kv);
      $key =~ s/^\s+//;
      $key =~ s/\s+$//;
      $value =~ s/^\s+//;
      $value =~ s/\s+$//;
      $cookie{$key} = $value;
    }
    $sessionid = $cookie{'SID'};
  }

  # the sessionid has the format of epochtime-processid and should only
  # contain numeric characters and dashes... since the sessionid is used
  # to construct some full pathnames, care must be taken to be sure the 
  # user submitted data is properly scrubbed
  $sessionid =~ s/[^0-9\-]//g;

  return($sessionid);
}

##############################################################################

sub initUploadCookieSetSessionID
{
  local($sessionid, $cookie);

  $sessionid = $g_curtime . "-" . $$;
  $cookie = "SID=$sessionid; path=/; domain=$ENV{'HTTP_HOST'}";
  print "Set-Cookie: $cookie\n";
}

##############################################################################

unless ($ENV{'SERVER_NAME'}) {
  print STDERR "hello world\n";
  exit(0);
}

##############################################################################
# eof

1;

