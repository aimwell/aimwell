#
# apache.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/apache.pl,v 2.12.2.5 2006/04/25 19:48:23 rus Exp $
#
# apache web server functions
#

##############################################################################

sub apacheRestart
{
  local($mesg, $rc, %ec, $syntax_ok, $prefix, $timestamp);

  encodingIncludeStringLibrary("apache");

  # check for cancel
  if ($g_form{'submit'} eq "$CANCEL_STRING") {
    $mesg = $APACHE_RESTART_CANCEL_TEXT;
    redirectLocation("iroot.cgi", $mesg);
  }

  # check for return to wizards menu request
  if ($g_form{'submit'} eq "$APACHE_RESTART_RETURN") {
    redirectLocation("iroot.cgi");
  }

  $prefix = initPlatformApachePrefix();
  if ($g_platform_type eq "virtual") {
    # apache isn't really restarted here... just 'touch' the httpd.conf and
    # let the watcher daemon restart it - this will also kill all child 
    # processes including in all probability the instance of this script
    utime($g_curtime, $g_curtime, "$prefix/conf/httpd.conf");
  }
  else {
    # preform a configtext through an apachectl system call
    $syntax_ok = 0;
    open(PIPE, "$prefix/bin/apachectl configtest 2>&1 |");
    while (<PIPE>) {
      if (/^syntax ok/i) {
        $syntax_ok = 1;
      }
      else {
        $mesg .= $_;
      }
    }
    close(PIPE);
    # redirect to self if bad syntax found
    unless ($syntax_ok) {
      $mesg = $APACHE_RESTART_FAILED_TEXT . "\n" . $mesg;
      redirectLocation("restart_apache.cgi", $mesg) 
    }
    # set the file modification time so that later restart requests can
    # use the modification time to display when the last restart request
    # was made through the restart wizard
    utime($g_curtime, $g_curtime, "$prefix/conf/httpd.conf");
    # perform a restart through an apachectl system call
    unless (fork) {
      # child process
      close(STDOUT);
      close(STDIN);
      close(STDERR);
      open(RESTARTLOG, ">>$prefix/logs/restart_log");
      print RESTARTLOG "=" x 78 . "\n";
      $timestamp = localtime($g_curtime);
      print RESTARTLOG "$timestamp - $prefix/bin/apachectl restart";
      sleep(5);
      $rc = 0xffff & system("$prefix/bin/apachectl restart");
      printf RESTARTLOG "system('apachectl restart') returned %#04x: ", $rc;
      if ($rc == 0) {
        print RESTARTLOG "ran with normal exit\n";
      }
      elsif ($rc == 0xff00) {
        print RESTARTLOG "command failed: $!\n";
      }
      elsif ($rc > 0x80) {
        $rc >>= 8;
        print RESTARTLOG "ran with non-zero exit status $rc\n";
        %ec = ("0", "operation completed successfully",
               "1", "n/a",
               "2", "usage error",
               "3", "httpsd could not be started",
               "4", "httpsd could not be stopped",
               "5", "httpsd could not be started during a restart",
               "6", "httpsd could not be restarted during a restart",
               "7", "httpsd could not be restarted during a graceful restart",
               "8", "configuration syntax error");
        print RESTARTLOG "apachectl exit code $rc == $ec{$rc}\n";
      }
      else {
        print "ran with ";
        if ($rc & 0x80) {
          $rc &= ~0x80;
          print RESTARTLOG "coredump from ";
        }
        print RESTARTLOG "signal $rc\n";
      }
      close(RESTARTLOG);
      exit(0);
    }
  }

  # if we are still here, watcher is a little slow (sometimes the SIGHUP  
  # will happen instantaneously)... redirect to tools & wizards main menu
  $mesg = $APACHE_RESTART_SUCCESS_TEXT;
  redirectLocation("iroot.cgi", $mesg);
}

##############################################################################

sub apacheRestartConfirm
{
  local($modtime, $modstr);
  local($mesg, @lines, $prefix);

  if ($g_form{'msgfileid'}) {
    # read message from temporary state message file
    $mesg = redirectMessageRead($g_form{'msgfileid'});
  }

  encodingIncludeStringLibrary("apache");

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($APACHE_RESTART_TITLE);

  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();

  if ($mesg) {
    @lines = split(/\n/, $mesg);
    foreach $mesg (@lines) {
      htmlTextColorBold(">>>&#160;$mesg&#160;<<<", "#cc0000");
      htmlBR();
    }
    htmlP();
  }

  htmlText($APACHE_RESTART_HELP_TEXT_1);
  htmlP();
  $prefix = initPlatformApachePrefix();
  $modtime = (stat("$prefix/conf/httpd.conf"))[9];
  $modstr = localtime($modtime);
  require "$g_includelib/date.pl";
  $modstr = dateLocalizeTimeString($modstr);
  htmlTextCode("&#160; &#160; $modstr");
  htmlP();
  htmlTextItalic($APACHE_RESTART_HELP_TEXT_2);
  htmlP();
  formOpen("method", "POST");
  formInput("type", "hidden", "name", "confirm", "value", "yes");
  formInput("type", "submit", "name", "submit", "value", 
            $APACHE_RESTART_SUBMIT_TEXT);
  formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  htmlBR();
  htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  formInput("type", "submit", "name", "submit", "value", 
            $APACHE_RESTART_RETURN);
  formClose();
  htmlP();

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

