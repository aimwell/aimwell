#
# vhost_util.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/vhost_util.pl,v 2.12.2.4 2006/04/25 19:48:25 rus Exp $
#
# general virtual host functions, used globally
#

##############################################################################

sub vhostHashInit
{
  local($order, $insidetags, $curhostnames);
  local(@curhostdirectives, $directive, $filename);
  local($servername, $name, $value, @iplist, $ipkey);
  local($prefix);

  $prefix = initPlatformApachePrefix();
  $filename = "$prefix/conf/httpd.conf";

  %g_vhosts = ();
  $order = 1;
  unless (open(HTTPDCONF, "$filename")) {
    print STDERR "failed to open httpd.conf: $!\n";
    return;
  }
  while (<HTTPDCONF>) {
    s/^\s+//;
    s/\s+$//;
    s/\s+/ /g;
    if ((/^<VirtualHost (.*)>/i) || (/^<Host (.*)>/i)) {
      $curhostnames = $1;
      $insidetags = 1;
      @curhostdirectives = ();
      next;
    }
    elsif ((/^<\/VirtualHost>/i) || (/^<\/Host>/i)) {
      $order++;
      $insidetags = 0;
      $curhostnames =~ s/^\s+//;
      $curhostnames =~ s/\s+$//;
      $curhostnames =~ s/\s/ /;
      $curhostnames =~ s/\s+/ /;
      # ignore virtual hosts that don't include a server name directive
      $servername = "";
      foreach $directive (@curhostdirectives) {
        $directive =~ /([A-Za-z]*) (.*)/;
        $name = $1;   $value = $2;
        $name =~ tr/A-Z/a-z/;
        if ($name eq "servername") {
          $servername = $value;
          last;
        }
      } 
      if ($g_platform_type eq "dedicated") {
        # is the virtual host ip based?
        if ($curhostnames =~ /([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*)/) {
          # if no server name then next
          next unless ($servername);
          # get ip list from definition
          $ipkey = $curhostnames;
          $ipkey =~ s/^\s+//;
          $ipkey =~ s/\s+$//;
          $ipkey =~ s/\s+/\ /g;
          @iplist = split(/\ /, $ipkey);
          $curhostnames = $servername;
          # set a flag to signify that this is an IP based virtual host
          $g_vhosts{$curhostnames}->{'ip_based'} = 1;
          foreach $ipkey (@iplist) {
            # store IP bindings
            push(@{$g_vhosts{$curhostnames}->{'ip_bindings'}}, $ipkey);
          }
        }
        if (($g_vhosts{$curhostnames}->{'ip_based'}) &&
            ($#{$g_vhosts{$curhostnames}->{'directives'}} > -1)) {
          # we are here because a virtual host with a server name has
          # been encountered which has already been discovered previously
          # in the configuration file.  since I hash on the server name,
          # I'm going to have to enforce that all multi-port definitions
          # for the same server name be composed of the same directives.
          # so... I am next'ing here so that the previously encountered
          # directives are not overwritten (or appended to)... there may
          # be exceptions that to this rule that will be encountered, but
          # I'm not sure if I want to go to the effort to support them.
          next;
        }
      }
      # loop through the directives
      foreach $directive (@curhostdirectives) {
        next if ($directive =~ /^SSLEnable/i);  # definitions are coupled
        next if ($directive =~ /^SSLDisable/i); # definitions are coupled
        push(@{$g_vhosts{$curhostnames}->{'directives'}}, $directive); 
        next if ($directive =~ /^\</);
        $directive =~ /([A-Za-z]*) (.*)/;
        $name = $1;   $value = $2;
        $name =~ tr/A-Z/a-z/;
        $g_vhosts{$curhostnames}->{$name} = $value;
      }
      $g_vhosts{$curhostnames}->{'hostnames'} = $curhostnames;
      $g_vhosts{$curhostnames}->{'order'} = $order;
    }
    elsif ($insidetags) {
      push(@curhostdirectives, $_);
    }
  }
  close(HTTPDCONF);
}

##############################################################################

sub vhostMapHostnames
{
  local(@users) = @_;
  local($user, $uinode, $vinode, $vkey, $match);
  local($homedir, $testpath, @hostnames, $hostname);

  # map home directory for given list of users to the document root of
  # any virtual subhost... CAUTION!!! this function can be extremely
  # slow if trying to map ALL users at the same time when there are 
  # loads of virtual hosts defined.

  if ($users[0] eq "ALL") {
    @users = ();
    foreach $user (keys(%g_users)) {
      next if ($user =~ /^_.*root$/);
      push(@users, $user); 
    }
  }

  foreach $user (@users) {
    $homedir = $g_users{$user}->{'home'};
    next unless (-e "$homedir");
    ($uinode) = (stat($homedir))[1] || 0;
    next unless ($uinode);
    foreach $vkey (keys(%g_vhosts)) {
      # see if the vhost directory contains a subpath that points to the same
      # inode as the users directory
      $match = 0;
      $testpath = $g_vhosts{$vkey}->{'documentroot'};
      $testpath =~ s/[^\/]+$//g;
      $testpath =~ s/\/+$//g;
      while ($testpath) {
        last unless (-e "$testpath");
        ($vinode) = (stat($testpath))[1];
        if ($vinode == $uinode) {
          $match = 1;
          last;
        }
        $testpath =~ s/[^\/]+$//g;
        $testpath =~ s/\/+$//g;
      }
      if ($match) {
        push(@{$g_users{$user}->{'vhostkeys'}}, $vkey);
        @hostnames = split(/\ /, $vkey);
        foreach $hostname (sort(@hostnames)) {
          push(@{$g_users{$user}->{'hostnames'}}, $hostname);
        }
      }
    }
  }
}

##############################################################################
    
sub vhostResourceError
{
  local($errmsg) = @_;
  local($os_error);

  $os_error = $!;
      
  encodingIncludeStringLibrary("vhosts");

  unless ($g_response_header_sent) {
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($VHOSTS_RESOURCE_ERROR_TITLE);
    htmlText($VHOSTS_RESOURCE_ERROR_TEXT);
    htmlP();
    if ($errmsg) {
      # display the message
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
# eof

1;

