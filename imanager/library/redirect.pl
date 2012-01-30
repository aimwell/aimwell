#
# redirect.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/redirect.pl,v 2.12.2.3 2006/04/25 19:48:25 rus Exp $
#
# redirection utility functions
#

##############################################################################

sub redirectLocation
{
  local($wizard, $msg) = @_;
  local($url, $scriptname, $args, $msgfileid);

  # if a message is passed in to redirectLocation, then store it in a
  # temporary file, and include the filename in the query string.  make
  # sure that the script we are redirecting to can handle the input.
  # 
  # why did I do this?  well, so that if you reload after an action in 
  # filemanager or iroot, it doesn't repost and give an error.  it was
  # necessary, trust me.
  #
  if ($msg) {
    $msgfileid = redirectMessageSave($msg);
  }

  $url = ($ENV{'HTTPS'} && ($ENV{'HTTPS'} eq "on")) ? 
           "https://" : "http://";
  $url .= "$ENV{'HTTP_HOST'}";

  $scriptname = $ENV{'SCRIPT_NAME'};
  $scriptname =~ s/[^\/]+$//g;
  if ($wizard =~ /^\.\.\//) {
    $scriptname =~ s/\/+$//g;
    $scriptname =~ s/[^\/]+$//g;
    $wizard =~ s/^[^\/]+//g;
  }
  $scriptname .= $wizard;
  $scriptname =~ s/\/\//\//g;
  $url .= $scriptname;

  #
  # build a list of arguments which will be passed to the new location
  #
  # the authentication key (if necessary)
  $args = ($g_auth{'type'} eq "form") ? "AUTH=$g_auth{'KEY'}" : "";
  # filemanager path
  if ($g_form{'path'}) {
    # append path to args if defined for filemanager wizards
    $g_form{'path'} = encodingStringToURL($g_form{'path'});
    $args .= "&path=$g_form{'path'}"; 
  }
  # mailmanager mailbox
  if ($g_form{'mbox'}) {
    # append mbox to args if defined for mailmanager wizards
    $g_form{'mbox'} = encodingStringToURL($g_form{'mbox'});
    $args .= "&mbox=$g_form{'mbox'}"; 
  }
  # mailmanager mailbox position
  if ($g_form{'mpos'}) {
    # append mpos to args if defined for mailmanager wizards
    $args .= "&mpos=$g_form{'mpos'}"; 
  }
  # mailmanager mailbox range option
  if ($g_form{'mrange'}) {
    # append mrange to args if defined for mailmanager wizards
    $args .= "&mrange=$g_form{'mrange'}"; 
  }
  # mailmanager mailbox sort option
  if ($g_form{'msort'}) {
    # append msort to args if defined for mailmanager wizards
    $args .= "&msort=$g_form{'msort'}"; 
  }
  # mailmanager mailbox message id
  if ($g_form{'messageid'}) {
    # append messageid to args if defined for mailmanager wizards
    $g_form{'messageid'} = encodingStringToURL($g_form{'messageid'});
    $args .= "&messageid=$g_form{'messageid'}"; 
  }
  # mailmanager address book contact list
  if ($g_form{'abclistid'}) {
    $g_form{'abclistid'} = encodingStringToURL($g_form{'abclistid'});
    $args .= "&abclistid=$g_form{'abclistid'}"; 
  }
  # iroot add virtual host user list
  if ($g_form{'vhostuserlist'}) {
    $g_form{'vhostuserlist'} = encodingStringToURL($g_form{'vhostuserlist'});
    $args .= "&vhostuserlist=$g_form{'vhostuserlist'}"; 
  }
  # and finally the message file id if a message is to be relayed
  if ($msg) {
    # append message file specification if specified
    $args .= "&msgfileid=$msgfileid"; 
  }
  $args =~ s/^\&+//g;
  $url .= "?$args" if ($args);

  print "Content-type: $g_default_content_type\n";
  print "Location: $url\n";
  print "\n";
  exit(0);
}

##############################################################################

sub redirectMessageRead
{
  local($msgfileid) = @_;
  local($msg, $filename);

  # open up the temporary state message file and read in the message
  $filename = "$g_tmpdir/.redirect-msg-" . $msgfileid;
  if (open(MESGFP, "$filename")) {
    $msg .= $_ while (<MESGFP>);
    close(MESGFP);
  }
  initTemporaryFileRemove($filename);
  return($msg);
}

##############################################################################

sub redirectMessageSave
{
  local($msg) = @_;
  local($msgfileid, $filename);

  $msg =~ s/^\s+//;
  $msg =~ s/\s+$//;
  $msgfileid = $g_curtime . "-" . $$;
  $filename = "$g_tmpdir/.redirect-msg-" . $msgfileid;
  if (open(MESGFP, ">$filename")) {
    print MESGFP "$msg";
    close(MESGFP);
    chown($g_users{$g_auth{'login'}}->{'uid'}, 
          $g_users{$g_auth{'login'}}->{'gid'}, $filename);
  }
  return($msgfileid);
}

##############################################################################
# eof

1;

