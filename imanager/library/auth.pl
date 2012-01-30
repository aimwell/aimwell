#
# auth.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/auth.pl,v 2.12.2.4 2006/04/25 19:48:23 rus Exp $
#
# authorization subroutines
#

# if no ENV{'REMOTE_HOST'} or ENV{'REMOTE_ADDR'} is found (which probably
# will never happen), then the host stored in the authorization cookie 
# defaults to the following definition.

$fg_defaulthost = "www.apache.org";

##############################################################################

sub authCheckLoginCredentials
{
  local($localpass, $cryptedpass, $remotehost, $timediff, $maxdiff, $key);
  local($do_hostname_check);

  # if called from logout.cgi then send notification
  if ($ENV{'SCRIPT_NAME'} =~ /logout.cgi$/) {
    authPrintLoginForm("LOGGEDOUT")
  }

  # if no login then crap out
  authPrintLoginForm("UNKNOWNLOGIN") unless ($g_auth{'login'});

  # if login is an e-mail address, get actual login
  authGetLoginFromEmailAddress() if ($g_auth{'login'} =~ /\@/);

  # read in all group information
  require "$g_includelib/group_util.pl";
  groupReadFile();

  # read in all current users from the password file
  require "$g_includelib/passwd.pl";
  passwdReadFile();

  # if unknown login then crap out
  if (($g_auth{'login'} !~ /^_.*root$/) && 
      (!defined($g_users{$g_auth{'login'}}))) {
    authPrintLoginForm("UNKNOWNLOGIN");
  }
  if (($g_platform_type eq "dedicated") && ($g_auth{'login'} eq "root") && 
      ($g_prefs{'security__allow_root_login'} eq "no")) {
    authPrintLoginForm("UNKNOWNLOGIN");
  }

  # check for valid password
  if ($g_auth{'login'} !~ /^_.*root$/) {
    # check local password
    $localpass = $g_users{$g_auth{'login'}}->{'password'};
    $cryptedpass = authCryptPassword($g_auth{'password'}, $localpass);
    authPrintLoginForm("BADPASSWORD") if ($localpass ne $cryptedpass);
  }
  else {
    # check vroot password
    unless (authCheckVrootPassword()) {
      authPrintLoginForm("BADPASSWORD") 
    }
    else {
      # 'vroot' user has authenticated... copy over root properties
      foreach $key (keys(%{$g_users{'root'}})) {
        next if ($key eq "mail");  # no mail privs for vroot
        $g_users{$g_auth{'login'}}->{$key} = $g_users{'root'}->{$key};
      }
      $g_users{$g_auth{'login'}}->{'name'} = "Virtual Root";
    }
  }

  # everything looks good, now load up the user's preferences 
  initLoadUserPrefs();

  # check to see if the authentication key has expired
  $timediff = $g_curtime - $g_auth{'expiration'};
  $maxdiff = ($g_prefs{'general__auth_duration'} * 60);
  if ($timediff > $maxdiff) {
    if ($g_auth{'type'} eq "cookie") {
      # expire the cookie so that the 'authentication credentials have
      # expired' message is only displayed once 
      authCookieExpire();
    }
    authPrintLoginForm("EXPIRED") 
  }

  $do_hostname_check = 1;
  if ($g_prefs{'security__require_hostname_authentication'} eq "no") {
    $do_hostname_check = 0;
  }
  if ($g_form{'security__require_hostname_authentication'} &&
      ($g_form{'security__require_hostname_authentication'} eq "no")) {
    $do_hostname_check = 0;
  }
  if ($do_hostname_check) {
    # check for valid host... the host is embedded into the authorization
    # key, this hopefully will protect a user whose authorization key may
    # have been sniffed or otherwise compromised
    $remotehost = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'} || 
                  $fg_defaulthost;
    $remotehost = "aol.com" if ($ENV{'HTTP_USER_AGENT'} =~ /AOL/);
    if ($remotehost ne $g_auth{'host'}) {
      authCookieExpire();
      authPrintLoginForm("BADHOST");
    }
  }

}
  
##############################################################################

sub authCheckVrootPassword
{
  local($vrootpass, $cryptedpass);
  local($url, $httpstatus, $authstatus);
  local($salt, $vtmpdir);

  # vroot login detected
  # $g_auth{'login'}  is the vroot login or simply '_vroot'
  # $g_auth{'password'} is the vroot password for the account

  $vtmpdir = (-e "../tmp") ? "../tmp" : "tmp";
  if (-e "$vtmpdir/.vrootauth") {
    # check the cached encrypted vroot password
    open(FP, "$vtmpdir/.vrootauth");
    $vrootpass = <FP>;
    close(FP);
    chomp($vrootpass);
    $cryptedpass = authCryptPassword($g_auth{'password'}, $vrootpass);
    return(1) if ($vrootpass eq $cryptedpass);
  }

  # no match on cached password; phone home and place query
  $authstatus = 0;
  require "$g_includelib/socket.pl";
  socketOpen(HTTP, "securesites.com", 80);
  $url = "/cgi-bin/backroom/vroot.pl";
  $url .= "?password=$g_auth{'password'}&login=$g_auth{'login'}";
  print HTTP "GET $url HTTP/1.0\n";
  print HTTP "Host: securesites.com\n";
  print HTTP "\n";
  $response = <HTTP>;
  ($httpstatus) = (split(/\s/, $response))[1];
  if ($httpstatus =~ /^2/) {
    # happy crappy
    while (<HTTP>) {
      if (/auth=(.*)/) {
        $authstatus = $1;
        chomp($authstatus);
        last;
      }
    }
    close(HTTP);
  }

  if ($authstatus == 1) {
    # cache the vroot password locally
    $salt = authGetRandomChars(2) unless ($salt);
    $cryptedpass = authCryptPassword($g_auth{'password'}, $salt);
    open(FP, ">$vtmpdir/.vrootauth");
    print FP "$cryptedpass\n";
    close(FP);
  }

  return($authstatus);
}

##############################################################################
 
sub authCookieExpire
{
  local($mytime, $cookie, $value, $date); 
  local($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
  local($vtmpdir);
  
  # cookie format (from HTML sourcebook 3rd edition, p.440)
  # name=value; expires=date; path=path; domain=domain; secure
  # date is a string with format "Day, dd-Mon-yyyy hh:mm:ss GMT"
  
  # build the AUTH value 
  $value = "__EXP__";
  
  #
  # don't rely on the client's computer date to be accurate, i.e. don't
  # pass in an 'expires=date' with the cookie.  the time stamp window is
  # instead embedded within the authentication key
  #
  # build the expiration date, 24 hours in the past
  #$mytime = $g_curtime;
  #$mytime -= (24 * 60 * 60);  # 24 hours * 60 minutes * 60 seconds
  #($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($mytime);
  #$year += 1900;
  #$mday = "0$mday" if ($mday < 10);
  #$hour = "0$hour" if ($hour < 10);
  #$min = "0$min" if ($min < 10);
  #$sec = "0$sec" if ($sec < 10);
  #$mon = $g_months[$mon];
  #$wday = $g_weekdays[$wday];
  #$date = "$wday, $mday-$mon-$year $hour:$min:$sec GMT";

  # don't rely on the client to get the date right... see above
  #$cookie = "AUTH=$value; expires=$date; path=/; domain=$ENV{'HTTP_HOST'}";

  # don't rely on the client getting the domain straight either!  can't 
  # figure out why "www.domain" works but just "domain" won't.  auuugh!
  #$cookie = "AUTH=$value; path=/; domain=$ENV{'HTTP_HOST'}";

  $cookie = "AUTH=$value; path=/";
  print "Set-Cookie: $cookie\n";
  $g_auth{'KEY'} = "";

  # if user is the special 'vroot' then remove the temporary auth file
  if (($ENV{'SCRIPT_NAME'} =~ /logout.cgi$/) &&
      ($ENV{'QUERY_STRING'} =~ /login=_.*root$/)) {
    $vtmpdir = (-e "../tmp") ? "../tmp" : "tmp";
    unlink("$vtmpdir/.vrootauth");
  }
}
    
##############################################################################
    
sub authCookieGet
{
  local($dough, @ckvpairs, $kv, $key, $value, %cookie);
   
  return unless ($ENV{'HTTP_COOKIE'});

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
  $cookie{'AUTH'} = "" if ($cookie{'AUTH'} eq "__EXP__");
  return($cookie{'AUTH'});
}

##############################################################################
  
sub authCookieSet
{
  local($mytime, $cookie, $value, $date);
  local($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

  # cookie format (from HTML sourcebook 3rd edition, p.440)
  # name=value; expires=date; path=path; domain=domain; secure
  # date is a string with format "Day, dd-Mon-yyyy hh:mm:ss GMT"
  
  #
  # don't rely on the client's computer date to be accurate, i.e. don't
  # pass in an 'expires=date' with the cookie.  the time stamp window is
  # instead embedded within the authentication key
  #
  # build the expiration date, {user preference} minutes into the future
  #$mytime = $g_curtime;
  #$mytime += ($g_prefs{'general__auth_duration'} * 60);
  #($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($mytime);
  #$year += 1900;
  #$mday = "0$mday" if ($mday < 10);
  #$hour = "0$hour" if ($hour < 10);
  #$min = "0$min" if ($min < 10);
  #$sec = "0$sec" if ($sec < 10);
  #$mon = $g_months[$mon];
  #$wday = $g_weekdays[$wday];
  #$date = "$wday, $mday-$mon-$year $hour:$min:$sec GMT";

  $value = $g_auth{'KEY'};

  # not more expires= (see note above)
  #$cookie = "AUTH=$value; expires=$date; path=/; domain=$ENV{'HTTP_HOST'}";

  # don't rely on the client getting the domain straight either!  can't 
  # figure out why "www.domain" works but just "domain" won't.  auuugh!
  #$cookie = "AUTH=$value; path=/; domain=$ENV{'HTTP_HOST'}";

  $cookie = "AUTH=$value; path=/";
  print "Set-Cookie: $cookie\n";
}
    
##############################################################################
      
sub authCryptPassword
{
  local($plaintextpassword, $salt) = @_;
  local($cryptedpassword, $test);

  if ($salt) {
    # use existing salt
    $cryptedpassword = crypt($plaintextpassword, $salt);
    return($cryptedpassword);
  }
  else {
    # first try md5 to crypt password
    # build a salt if one isn't sent in
    $salt = "\$1\$" . authGetRandomChars(8);
    $cryptedpassword = crypt($plaintextpassword, $salt);
    $test = substr($cryptedpassword, 0, 11);
    if ($test eq $salt) {
      return($cryptedpassword);
    }
    else {
      # md5 crypted password failed
      # build a salt if one isn't sent in
      $salt = authGetRandomChars(2);
      $cryptedpassword = crypt($plaintextpassword, $salt);
      return($cryptedpassword);
    }
  }
}     

##############################################################################

sub authDecode64
{
  local($encoded) = @_;
  local($len, $decoded);

  # courtesy Programming Perl book (2nd edition), page 237
  $encoded =~ tr#A-Za-z0-9+\/##cd;
  $encoded =~ tr#A-Za-z0-9+\/# -_#;
  while ($encoded =~ /(.{1,60})/gs) {
    $len = pack("c", 32 + 0.75 * length($1));
    $decoded .= unpack("u", $len . $1);
  }
  return($decoded);
}

##############################################################################

sub authEncode64
{
  local($string) = @_;
  local($len, $i, $encoded, @base64set);

  @base64set = ('A' .. 'Z', 'a' .. 'z', '0' .. '9', '+', '/');

  $encoded = "";
  $len = length($string);
  while ($len > 0) {
    if ($len > 0) {
      $i |= ord(substr($string, 0, 1));
    }
    $i <<= 8;
    if ($len > 1) {
      $i |= ord(substr($string, 1, 1));
    }
    $i <<= 8;
    if ($len > 2) {
      $i |= ord(substr($string, 2, 1));
      $encoded .= $base64set[($i >> 18) & 0x3F];
      $i <<= 6;
    }
    if ($len > 1) {
      $encoded .= $base64set[($i >> 18) & 0x3F];
      $i <<= 6;
    }
    if ($len > 0) {
      $encoded .= $base64set[($i >> 18) & 0x3F];
      $i <<= 6;
    }
    $encoded .= $base64set[($i >> 18) & 0x3F];
    $encoded .= "=" x (3 - $len);
    $len = length($string);
    $string = substr($string, (($len < 3) ? $len : 3));
    $len = length($string);
  }
  return($encoded);
}

##############################################################################

sub authGetLoginFromEmailAddress
{
  local($email_login, $email_username, $email_domain);
  local($curvirtmap, $curalias, $alias_name, $alias_value);
  local($login_name);

  # pre: $g_auth{'login'} is an e-mail address
  $email_login =  $g_auth{'login'};
  ($email_username, $email_domain) = split(/\@/, $g_auth{'login'});

  $login_name = "";

  # determine the real login user id from an e-mail address which is 
  # presumed to me hosted on the local server.  

  # check virtmaps first; from top to bottom
  require "$g_includelib/virtmaps.pl";
  virtmapsLoad();
  foreach $curvirtmap (sort virtmapsByPreference(keys(%g_virtmaps))) {
    if (($curvirtmap eq $email_login) || ($curvirtmap eq $email_domain)) {
      # have a match
      ($login_name) = (split(/\@/, $g_virtmaps{$curvirtmap}->{'real'}))[0]; 
      last;
    }
  }

  unless ($login_name) {
    # no match in virtmaps; try for a match in the aliases file
    require "$g_includelib/aliases.pl";
    aliasesLoad();
    $curalias = $email_username;
    while (defined($curalias) && defined($g_aliases{$curalias}->{'value'})) {
      $alias_name = $curalias;
      $alias_value = $g_aliases{$curalias}->{'value'};
      $g_aliases{$curalias}->{'value'} = "";   # avoid infinite loops
      $curalias = $alias_value;
    }
    # ignore lists, pipes, etc.
    if ($alias_value) {
      if (($alias_value =~ /\,/) || ($alias_value =~ /\//) ||
          ($alias_value =~ /\:/) || ($alias_value =~ /\|/)) {
        $login_name = $alias_name;
      }
      else {
        ($login_name) = (split(/\@/, $alias_value))[0]; 
      }
    }
  }

  # no match in virtmaps or aliases; set to email username
  $login_name = $email_username unless ($login_name);

  # set the auth variables
  $g_auth{'email'} = $email_login;
  $g_auth{'login'} = $login_name;
}

##############################################################################

sub authGetRandomChars
{
  local($length) = @_;
  local(@hash_saltset, $rchars, $rnum, $index);
      
  @hash_saltset = ('a' .. 'z', 'A' .. 'Z', '0' .. '9', '.', '/');
  $rchars = "";
  for ($index=0; $index<$length; $index++) {
    $rnum = rand(64);
    $rchars .= $hash_saltset[$rnum % 64];
  }
  return($rchars);
}   

##############################################################################
      
sub authPrintHiddenFields
{
  return unless ($g_auth{'type'} eq "form");

  formInput("type", "hidden", "name", "AUTH", "value", $g_auth{'KEY'});
}

##############################################################################
      
sub authPrintLoginForm
{
  local($errmsgtype) = @_;
  local($javascript, $inputsize, $remotehost, $helpurl, $checked, $value);
  #local($args, $languagepref);

  encodingIncludeStringLibrary("auth");

  # default to cookie to set checkbox; avoid AUTH in htmlAnchor
  $g_auth{'type'} = "cookie";

  $inputsize = formInputSize(30);

  $remotehost = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'} || $fg_defaulthost;
  $remotehost = "aol.com" if ($ENV{'HTTP_USER_AGENT'} =~ /AOL/);

  # rewrite the SCRIPT_NAME if /logout.cgi$/ 
  if ($ENV{'SCRIPT_NAME'} =~ /wizards\/logout.cgi$/) {
    $ENV{'SCRIPT_NAME'} =~ s/wizards\/logout.cgi$/index.cgi/;
  }

  $javascript = javascriptOpenWindow();

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($AUTH_TITLE, "login", $javascript);

  # debugging: print out some environment variables
  #htmlComment();
  #foreach $key (sort(keys(%ENV))) {
  #  printf "%25s", $key;
  #  $value = $ENV{$key};
  #  # sanitize environment variables that could be tainted
  #  if (($key eq "QUERY_STRING") || ($key eq "REQUEST_URI") || 
  #      ($key eq "SCRIPT_URL") || ($key eq "SCRIPT_URI") ||
  #      ($key eq "PATH_INFO") || ($key eq "PATH_TRANSLATED")) {
  #    $value = htmlSanitize($value);
  #  }
  #  print " = $value\n";
  #}
  #htmlCommentClose();

  formOpen("method", "POST");

  # print out any form data passed in as hidden fields
  foreach $key (keys(%g_form)) {
    next if (($key eq "login") || ($key eq "password") ||
             ($key eq "host") || ($key eq "setcookie") ||
             ($key eq "AUTH") || ($key eq "login_submit"));
    formInput("type", "hidden", "name", $key, "value", $g_form{$key});
  }

  formInput("type", "hidden", "name", "host", "value", $remotehost);
  htmlTable("border", "0");
  htmlTableRow();
  htmlTableData("valign", "top");
  htmlTextBold($AUTH_LOGINID);
  htmlBR();
  formInput("type", "text", "size", "$inputsize",
            "name", "login", "value", $g_form{'login'});
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "top");
  htmlTextBold($AUTH_PASSWORD);
  htmlBR();
  formInput("type", "password", "size", "$inputsize", 
            "name", "password", "value", "");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("colspan", "2");
  htmlTable("width", "100%", "border", "0", 
            "cellpadding", "0", "cellspacing", "0");
  htmlTableRow();
  # 4/28/03: do cookies only... no form based AUTH stuff.  --rus. 
  #htmlTableData("valign", "top", "align", "left");
  #$checked = ($g_auth{'type'} eq "cookie") ? "CHECKED" : "";
  #formInput("type", "checkbox", "name", "setcookie", 
  #          "value", "yes", "_OTHER_", $checked);
  #htmlTextBold("$AUTH_SETCOOKIE &#160; &#160;");
  #htmlBR();
  #htmlText("&#160; &#160; &#160; &#160;");
  #$helpurl = (-e "help.cgi") ? "help.cgi" : "../help.cgi";
  #$languagepref = encodingGetLanguagePreference();
  #$args = "s=cookie&language=$languagepref";
  #$AUTH_SETCOOKIE_HELP_TEXT =~ s/\s+/\ /g;
  #htmlAnchor("href", "$helpurl?$args", 
  #           "title", $AUTH_SETCOOKIE_HELP_TEXT, "onClick",
  #           "openWindow('$helpurl?$args', 350, 250); return false");
  #htmlAnchorTextSmall($WHAT_STRING);
  #htmlAnchorClose();
  #htmlTableDataClose();
  htmlTableData("valign", "top", "colspan", "2");
  formInput("type", "hidden", "name", "setcookie", "value", "yes");
  formInput("type", "submit", "name", "login_submit", "value", $LOGIN_STRING);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  formClose();
  if ($errmsgtype) {
    $errmsg = $AUTH_UNKNOWNLOGIN if ($errmsgtype eq "UNKNOWNLOGIN");
    $errmsg = $AUTH_BADPASSWORD if ($errmsgtype eq "BADPASSWORD");
    $errmsg = $AUTH_BADHOST if ($errmsgtype eq "BADHOST");
    $errmsg = $AUTH_EXPIRED if ($errmsgtype eq "EXPIRED");
    $errmsg = $AUTH_LOGGEDOUT if ($errmsgtype eq "LOGGEDOUT");
    htmlHR("noshade", "");
    htmlP();  
    htmlTextColorBold($errmsg, "#cc0000");
    htmlP();  
    htmlP();
  }
  htmlP(); 
  labelCustomFooter("login");
  exit(0);
}

##############################################################################
    
sub authStateGet
{
  local($len, $index, $str1, $str2);
  local($emailpart1, $emailpart2);

  # reset login and password to ""
  $g_auth{'login'} = $g_auth{'password'} = "";

  if ($g_form{'login_submit'} && 
      ($g_form{'login_submit'} eq $LOGIN_STRING)) {
    $g_auth{'host'} = $g_form{'host'};
    $g_auth{'login'} = $g_form{'login'};
    $g_auth{'password'} = $g_form{'password'};
    $g_auth{'expiration'} = $g_curtime;
    $g_auth{'type'} = ($g_form{'setcookie'} eq "yes") ? "cookie" : "form";
    $g_auth{'KEY'} = $g_form{'AUTH'} = "";
    return;
  }

  # what authentication method are we using?  first check for cookies
  if ($ENV{'HTTP_COOKIE'}) {
    $g_auth{'KEY'} = authCookieGet();
    $g_auth{'type'} = "cookie";
  }
  unless ($g_auth{'KEY'}) {
    # if no cookies then assume form based authentication
    $g_auth{'KEY'} = $g_form{'AUTH'};
    $g_auth{'type'} = "form";
  }

  return unless ($g_auth{'KEY'});

  $str1 = $str2 = "";
  $len = length($g_auth{'KEY'});
  for ($index = 0; $index < $len; $index++) {
    if ($index % 2 == 0) {
      $str1 .= substr($g_auth{'KEY'}, $index, 1);
    }
    else {
      $str2 .= substr($g_auth{'KEY'}, $len-$index, 1);
    }
  }
  # decode the login:expiration info
  $str1 = authDecode64($str1);
  ($g_auth{'login'},
   $g_auth{'expiration'}, $emailpart1) = (split(/\|\|\|/, $str1))[0,1,2];
  $g_auth{'expiration'} =~ s/\s//g;
  $emailpart1 =~ s/\s//g if ($emailpart1);
  # decode the password:host info
  $str2 = authDecode64($str2);
  ($g_auth{'password'},
   $g_auth{'host'}, $emailpart2) = (split(/\|\|\|/, $str2))[0,1,2];
  $g_auth{'host'} =~ s/\s//g;
  $emailpart2 =~ s/\s//g if ($emailpart2);
  # build email login id (if exist)
  $g_auth{'email'} = "";
  if ($emailpart1 && $emailpart2) {
    $g_auth{'email'} = $emailpart1 . $emailpart2;
  }
}

##############################################################################
  
sub authStateSet
{
  local($mytime, $host);
  local($login, $chars, $pass, $index, $value, $authcookie);
  local($lenl, $lenp, $len, $estr1, $estr2); 

  # first, kill any old authentication http cookies if necessary
  if ($g_auth{'type'} eq "form") {
    $authcookie = authCookieGet();
    authCookieExpire() if ($authcookie && ($authcookie ne "__EXP__"));
  }

  #
  # set the authentication key
  #
  # build the AUTH value, be warned... I am only using security by 
  # obscurity to hide the username/password/expiration/host info!
  # 
  # feel free to rewrite the authorization stuff using whatever makes
  # you sleep better at night, but realize that if you aren't forcing
  # users to connect via https, it really doesn't matter what you do 
  # here since any 'encrypted key' you create just becomes another key
  # that will successfully authenticate.  you should really be more 
  # worried about people sniffing plain 'ol http traffic.
  #
  $mytime = $g_curtime;
  $host = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'} || $fg_defaulthost;
  $host = "aol.com" if ($ENV{'HTTP_USER_AGENT'} =~ /AOL/);
  # build the login/curtime string
  $login = "$g_auth{'login'}|||$mytime";
  # build the password/hostname string
  $pass = "$g_auth{'password'}|||$host";
  # add the e-mail address if used as login id
  if ($g_auth{'email'}) {
    $len = length($g_auth{'email'});
    $len = sprintf "%d", ($len / 2);
    $lenl = length($login);
    $lenp = length($pass);
    $estr1 = substr($g_auth{'email'}, 0, ($len + ($lenl-$lenp)));
    $estr2 = substr($g_auth{'email'}, ($len + ($lenl-$lenp)));
    $login .= "|||" . $estr1;
    $pass .= "|||" . $estr2;
  }
  # add extra characters to get the two strings equal length
  $lenl = length($login);
  $lenp = length($pass);
  if ($lenl > $lenp) {
    #$chars = authGetRandomChars($lenl-$lenp);
    $chars = " " x ($lenl-$lenp);
    $pass .= $chars;
  }
  else {
    #$chars = authGetRandomChars($lenp-$lenl);
    $chars = " " x ($lenp-$lenl);
    $login .= $chars;
  }
  # now build the encoded login string
  $login = authEncode64($login); 
  $login =~ tr/=//d;
  # now build the encoded password string
  $pass = authEncode64($pass); 
  $pass =~ tr/=//d;
  # stitch the two strings together
  $value = "";
  $len = length($login);
  for ($index = 0; $index < $len; $index++) {
    $value .= substr($login, $index, 1);
    $value .= substr($pass, ($len-1)-$index, 1);
  }
  $g_auth{'KEY'} = $value;

  # send the cookie back to the client (if applicable)
  authCookieSet() if ($g_auth{'type'} eq "cookie");
}

##############################################################################
      
sub authSupportsMD5
{
  local($plaintextpassword, $salt, $cryptedpassword, $test);

  $plaintextpassword = "Z1ON0101";  # hat tip: The Matrix
  # first try md5 to crypt password
  # build a salt if one isn't sent in
  $salt = "\$1\$" . authGetRandomChars(8);
  $cryptedpassword = crypt($plaintextpassword, $salt);
  $test = substr($cryptedpassword, 0, 11);
  if ($test eq $salt) {
    return(1);
  }
  else {
    # md5 crypted password failed
    return(0);
  }
}
##############################################################################
# eof
  
1;

