#
# info.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/info.pl,v 2.12.2.2 2006/04/25 19:48:23 rus Exp $
#
# info and version subroutines
#

##############################################################################

sub infoDisplay
{
  # parse any form data
  require "$g_includelib/form.pl";
  formParseData();

  # include common libraries
  require "$g_includelib/auth.pl";  # for Encode64 and Decode64
  require "$g_includelib/html.pl";
  require "$g_includelib/label.pl";
  require "$g_includelib/encoding.pl";

  # set default content type for output
  encodingSetDefaultContentType();

  encodingIncludeStringLibrary("main");

  infoLoadVersion();

  if (($g_form{'fn'} eq "m") || ($g_form{'fn'} eq "mi")) {
    # 'm' is there for backwards compatibility with 2.02b
    infoDisplayMasterInfo();
  }
  elsif ($ENV{'SCRIPT_NAME'} =~ /about.cgi/) {
    infoDisplayCurrentFrame(1);
  }
  elsif ($g_form{'fn'} eq "mf") {
    infoDisplayMasterFrame();
  }
  elsif ($g_form{'fn'} eq "c") {
    infoDisplayCurrentFrame(1);
  }
  else {
    infoDisplayFrameSet();
  }
}

##############################################################################

sub infoDisplayCurrentFrame
{
  local($displayheader) = @_;
  local($datestring, $language, $aboutfilename);

  if ($displayheader) {
    htmlResponseHeader("Content-type: $g_default_content_type");
    htmlHtml();
    htmlHead();
    if ($ENV{'SCRIPT_NAME'} =~ /about.cgi/) {
      htmlTitle($MAINMENU_ABOUT_TITLE);
    }
    else {
      htmlTitle($MAINMENU_UPDATE_TITLE);
    }
    htmlHeadClose();
  }
  htmlBody("bgcolor", "#ffffff");
  if ($ENV{'SCRIPT_NAME'} =~ /about.cgi/) {
    htmlH3($MAINMENU_ABOUT_TITLE);
  }
  else {
    htmlH3($MAINMENU_UPDATE_TITLE);
    htmlP();
    htmlH3($UPDATE_CURRENT_INFO);
  }
  htmlBR();
  htmlTextBold("$ABOUT_VERSION:&#160;");
  htmlText("$g_info{'version'}");
  htmlBR();
  if ($g_info{'build_date'} ne "__UNKNOWN__") {
    htmlTextBold("$ABOUT_BUILD_DATE:&#160;");
    require "$g_includelib/date.pl";
    $datestring = dateBuildTimeString("alpha", $g_info{'build_date'});
    $datestring = dateLocalizeTimeString($datestring);
    $datestring =~ s/ /\&\#160\;/g;
    htmlTextSmall($datestring);
    htmlBR();
  }
  if ($displayheader && ($ENV{'SCRIPT_NAME'} =~ /about.cgi/)) {
    htmlP();
    $language = encodingGetLanguagePreference();
    $aboutfilename = "strings/" . $language . "/ABOUT";
    unless (-e "$aboutfilename") {
      $aboutfilename = "strings/en/ABOUT";
    }
    open(INFOFP, $aboutfilename);
    while (<INFOFP>) {
      htmlTextCode($_); 
      htmlBR();
    }
    close(INFOFP);
    print <<ENDTEXT;
<script language="JavaScript1.1">
<!--
  if (self.opener) {
    document.write("<form name=\\\"myform\\\">");
    document.write("<input type=\\\"submit\\\" name=\\"dzaijyan\\\" value=\\\"$CLOSE_STRING\\\" onClick=\\\"self.close();\\\">");
    document.write("</form>");
  }
//-->
</script>
ENDTEXT
  }
  htmlBodyClose();
  htmlHtmlClose() if ($displayheader);
}

##############################################################################

sub infoDisplayFrameSet
{
  local($vstring);

  if ($g_info{'master_site'} eq "__UNKNOWN__") {
    infoDisplayCurrentFrame(1);
  }
  else {
    # print out self referencing framed document
    htmlResponseHeader("Content-type: $g_default_content_type");
    htmlHtml();
    htmlHead();
    if ($ENV{'SCRIPT_NAME'} =~ /about.cgi/) {
      htmlTitle($MAINMENU_ABOUT_TITLE);
    }
    else {
      htmlTitle($MAINMENU_UPDATE_TITLE);
    }
    htmlHeadClose();
    htmlFrameSet("rows", "125,*");
    htmlFrame("name", "current", "src", "$ENV{'SCRIPT_NAME'}?fn=c");
    htmlFrame("name", "master", "src", "$ENV{'SCRIPT_NAME'}?fn=mf");
    htmlFrameSetClose();
    htmlNoFrames();
    infoDisplayCurrentFrame(0);
    htmlNoFramesClose();
    htmlHtmlClose();
  }
}

##############################################################################

sub infoDisplayMasterFrame
{
  local($vstring, $master_server, $url, $response, $status, $headers);
  local($language, $nva, $nvn, $nvbd);

  $language = encodingGetLanguagePreference();

  $vstring = $g_info{'version'} . ":" . $g_info{'build_date'};
  $vstring = authEncode64($vstring);
  $g_info{'master_site'} =~ /http:\/\/(.*?)\/(.*)/;
  $master_server = $1;
  $url = "/" . $2 . "/info.cgi";
  $url =~ s/\/\//\//g;
  $url .= "?fn=mi&v=$vstring&language=$language";

  $nva = 0;
  $nvn = $nvbd = "";

  require "$g_includelib/socket.pl";
  socketOpen(HTTP, $master_server, 80);
  print HTTP "GET $url HTTP/1.0\n";
  print HTTP "Host: $master_server\n";
  print HTTP "\n";
  $response = <HTTP>;
  ($status) = (split(/\s/, $response))[1];
  if ($status =~ /^2/) {
    # happy crappy
    $headers = 1;
    while (<HTTP>) {
      $response = $_;
      $response =~ s/\s+$//g;
      $response .= "\n";
      $headers = 0 if ($response eq "\n");
      print $response if ($headers && ($response =~ /^Content-Type/i));
      print $response if ($headers == 0);
      # new version information embedded in comments from master server
      # nva = new version available (0 or 1)
      # nvn = new version number (e.g. 'iManager 2.11')
      # nvbd = new version build date (in seconds since the Epoch)
      if (/__nva__ = \'(.*)\'/) {   
        $nva = $1;
      }
      elsif (/__nvn__ = \'(.*)\'/) {   
        $nvn = $1;
      }
      elsif (/__nvbd__ = \'(.*)\'/) {   
        $nvbd = $1;
        infoDisplayUpgradeSuggestion($nvn, $nvbd) if ($nva);
      }
    }
    close(HTTP);
  }
  else {
    # non-200 level response ... do something here
    htmlResponseHeader("Content-type: text/plain");
    print "$response\n"; 
  }
}

##############################################################################

sub infoDisplayMasterInfo
{
  local($datestring, $remote_version, $remote_build_date, $remote_platform);
  local($nva, $nvn, $nvbd);

  $nva = 0;

  if ($g_form{'v'}) {
    $g_form{'v'} = authDecode64($g_form{'v'});
    ($remote_version, $remote_build_date, $remote_platform) = 
                                               split(/:/, $g_form{'v'});
    if ($remote_platform) {
      # repopulate the g_info hash based on the remote platform
      %g_info = ();
      infoLoadVersion($remote_platform);
    }
  }

  htmlResponseHeader("Content-type: $g_default_content_type");
  htmlHtml();
  htmlHead();
  htmlTitle($MAINMENU_ABOUT_TITLE);
  htmlHeadClose();
  htmlBody("bgcolor", "#ffffff");
  htmlTable("border", "0", "cellpadding", "0", "cellspacing", "0");
  htmlTableRow();
  htmlTableData("valign", "top");
  htmlH3($ABOUT_MASTER_SITE);
  htmlBR();
  $ABOUT_VERSION =~ s/ /\&\#160\;/g;
  htmlTextBold("$ABOUT_VERSION:&#160;");
  htmlText("$g_info{'version'}");
  htmlBR();
  $ABOUT_BUILD_DATE =~ s/ /\&\#160\;/g;
  htmlTextBold("$ABOUT_BUILD_DATE:&#160;");
  require "$g_includelib/date.pl";
  $datestring = dateBuildTimeString("alpha", $g_info{'build_date'});
  $datestring = dateLocalizeTimeString($datestring);
  $datestring =~ s/ /\&\#160\;/g;
  htmlTextSmall($datestring);
  htmlBR();
  htmlTableDataClose();
  if ($remote_build_date < 1072915200) {  # pre-2004 builds
    htmlTableData("valign", "top");
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top");
  }
  else {
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData("valign", "top");
    htmlBR();
  }
  if ((!$g_form{'v'}) || ($g_info{'build_date'} eq "__UNKNOWN__")) {
    htmlText("&#160;");
  }
  else {
    htmlH3($ABOUT_UPGRADE_SUMMARY);
    htmlBR();
    if ((!$remote_version) || (!$remote_build_date)) {
      htmlText($ABOUT_UPGRADE_REMOTE_VERSION_UNKNOWN);
    }
    elsif (($g_info{'version'} ne $remote_version) ||
           ($g_info{'build_date'} > $remote_build_date)) {
      if ($g_info{'master_type'} eq "stable") {
        htmlText($ABOUT_UPGRADE_REMOTE_VERSION_OLD);
      }
      else {
        htmlText($ABOUT_UPGRADE_REMOTE_VERSION_OLD_DEV);
        $nva = 1;
      }
    }
    else {
      if ($g_info{'master_type'} eq "stable") {
        htmlText($ABOUT_UPGRADE_REMOTE_VERSION_CURRENT);
      }
      else {
        htmlText($ABOUT_UPGRADE_REMOTE_VERSION_CURRENT_DEV);
        $nva = 1;
      }
    }
  }
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  print "\n";
  print "<!-- __nva__ = '$nva' -->\n";
  print "<!-- __nvn__ = '$g_info{'version'}' -->\n";
  print "<!-- __nvbd__ = '$g_info{'build_date'}' -->\n";
  print "\n";
  htmlBodyClose();
  htmlHtmlClose();
}

##############################################################################

sub infoDisplayUpgradeSuggestion
{
  local($nvn, $nvbd) = @_;
  local($tarfile, $mtime, $curbd, $url);

  # there is a version newer available on the master site
  # display an upgrade suggestion if newer available version is located
  # on local server via a vinstall

  return unless ($nvn =~ /^iManager/);
  return unless (-e "/usr/local/sbin/vinstall");
  return unless (-e "/usr/bin/tar");

  # translate version name and number to filename
  # e.g. iManager 2.11 -> imanager-2.11.tar
  $tarfile = $nvn;
  $tarfile =~ tr/A-Z/a-z/;
  $tarfile =~ s/\ /\-/;
  $tarfile = "/usr/local/contrib/" . $tarfile . ".tar";
  return unless (-e "$tarfile");

  # the version exists, but is the tarfile build date current?
  return unless (-e "/tmp");
  system("/usr/bin/tar -C /tmp -xf $tarfile imanager/VERSION");
  ($mtime) = (stat("/tmp/imanager/VERSION"))[9];
  unlink("/tmp/imanager/VERSION");
  rmdir("/tmp/imanager");

  if (($mtime > $nvbd) || ($mtime > $g_info{'build_date'})) {
    # looks like an upgrade appears to be available; suggest upgrade
    $url = ($ENV{'HTTPS'} eq "on") ? "https://" : "http://";
    $url .= $ENV{'HTTP_HOST'};
    $url .= $ENV{'SCRIPT_NAME'};
    $url =~ s/info.cgi$/wizards\/update.cgi/;
    formOpen("name", "myform",
             "onSubmit", "if (self.parent.opener) { self.parent.opener.document.location='$url'; parent.close();} else { self.parent.location='$url';}; return true",
             "action", "wizards/donothing.cgi");
    authPrintHiddenFields();
    formInput("type", "submit", "name", "action",  
              "value", $UPDATE_INSTALL_LATEST);
    formClose();
  }
}

##############################################################################

sub infoInstallLatestVersion
{
  local($lastbd, $installdir, $mesg, $command, @output, $datestring);

  infoLoadVersion();
  $lastbd = $g_info{'build_date'};

  # set the installation directory
  $installdir = $ENV{'SCRIPT_FILENAME'};
  $installdir =~ s/\/wizards\/.*$//g;
  $installdir =~ s/[^\/]+$//g;
  $installdir =~ s/\/+$//g;

  # run vinstall; scan output for errors 
  @output = ();
  $command = "/usr/local/sbin/vinstall imanager2 -q -d $installdir";
  open(PIPE, "$command |");
  while (<PIPE>) {
    chomp;
    push(@output, $_);
  }
  close(PIPE);

  # figure out what was just installed and send a summary back to user
  %g_info = ();
  infoLoadVersion();
  if ($g_info{'build_date'} == $lastbd) {
    # nothing was accomplished
    $mesg = $UPDATE_INSTALL_LATEST_FAILURE;
  }
  else {
    # new version was installed
    $mesg = $UPDATE_INSTALL_LATEST_SUCCESS . "\n";
    $mesg .= "$ABOUT_VERSION: $g_info{'version'}\n";
    require "$g_includelib/date.pl";
    $datestring = dateBuildTimeString("alpha", $g_info{'build_date'});
    $datestring = dateLocalizeTimeString($datestring);
    $mesg .= "$ABOUT_BUILD_DATE: $datestring\n";
  }
  
  redirectLocation("iroot.cgi", $mesg);
}

##############################################################################

sub infoLoadVersion
{
  local($platform) = @_;
  local($filename, $pathname, $name, $value);

  # check for a specific platform VERSION file
  $pathname = "";
  if ($platform) {
    $filename = "VERSION.$platform";
    if (-e "$filename") {
      $pathname = "$filename";
    }
    elsif (-e "../$filename") {
      $pathname = "../$filename";
    }
  }
  # if a specific platform VERSION file is not found, default to VERSION
  unless (-e "$pathname") {
    $filename = "VERSION";
    if (-e "$filename") {
      $pathname = "$filename";
    }
    elsif (-e "../$filename") {
      $pathname = "../$filename";
    }
    else {
      $g_info{'version'} = "iManager 2.0";
      $g_info{'build_date'} = "__UNKNOWN__";
      $g_info{'master_site'} = "__UNKNOWN__";
      $g_info{'master_type'} = "__UNKNOWN__";
      return;
    }
  }
  open(IFP, "$pathname");
  while (<IFP>) {
    next if (/^#/);
    ($name, $value) = split(/=/);
    $name =~ tr/A-Z/a-z/;
    $name =~ s/^\s+//;
    $name =~ s/\s+$//;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    $g_info{$name} = $value;
  }
  close(IFP);
  $g_info{'build_date'} = (stat($pathname))[9];
}

##############################################################################

sub infoUpdateCheckPrivileges
{
  # check for update privileges
  if (($g_auth{'login'} ne "root") &&
      ($g_auth{'login'} !~ /^_.*root$/) &&
      ($g_auth{'login'} ne $g_users{'__rootid'}) &&
      (!(defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}})))) {
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($UPDATE_DENIED_TITLE);
    htmlText($UPDATE_DENIED_TEXT);
    htmlP();
    labelCustomFooter();
    exit(0);
  }
}

##############################################################################
# eof

1;

