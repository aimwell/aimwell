#
# vhosts.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/vhosts.pl,v 2.12.2.5 2006/04/25 19:48:25 rus Exp $
#
# virtual host admin functions (add/edit/remove/view)
#

##############################################################################

sub vhostsByPreference
{
  if (($a =~ /^__NEWVHOST/) || ($b =~ /^__NEWVHOST/)) {
    return($a cmp $b);
  }

  if ($g_form{'sort_submit'} &&
      ($g_form{'sort_submit'} eq $VHOSTS_SORT_BY_HOST)) {
    return($a cmp $b);
  }
  elsif ($g_form{'sort_submit'} &&
         ($g_form{'sort_submit'} eq $VHOSTS_SORT_BY_NAME)) {
    return($g_vhosts{$a}->{'servername'} cmp $g_vhosts{$b}->{'servername'});
  }
  elsif ($g_form{'sort_submit'} &&
         ($g_form{'sort_submit'} eq $VHOSTS_SORT_BY_ROOT)) {
    return($g_vhosts{$a}->{'documentroot'} cmp 
           $g_vhosts{$b}->{'documentroot'});
  }
  else {
    return($g_vhosts{$a}->{'order'} <=> $g_vhosts{$b}->{'order'});
  }
}

##############################################################################

sub vhostsCheckFormValidity
{
  local($type) = @_;
  local($mesg, $vhost, @selectedvhosts, $vcount, @hostnames, @myhn);
  local($hnkey, $snkey, $sadkey, $drkey, $trkey, $erkey, $sakey, $ookey);
  local($vhostname, $directive, $orig_otheroptions, $definedhost);
  local($index, $index2, $errmsg, $errflag, %errors); 
  
  encodingIncludeStringLibrary("vhosts");
  
  if ($g_form{'submit'} eq "$CANCEL_STRING") {
    if ($type eq "add") {  
      $mesg = $VHOSTS_CANCEL_ADD_TEXT;
    }
    elsif ($type eq "edit") {
      $mesg = $VHOSTS_CANCEL_EDIT_TEXT;
    }
    elsif ($type eq "remove") {
      $mesg = $VHOSTS_CANCEL_REMOVE_TEXT;
    } 
    redirectLocation("iroot.cgi", $mesg);
  } 

  # perform error checking on form data
  if (($type eq "add") || ($type eq "edit")) {
    $vcount = 0;
    %errors = ();
    @selectedvhosts = split(/\|\|\|/, $g_form{'vhosts'});
    foreach $vhost (@selectedvhosts) {
      $vhostname = $vhost;
      $vhostname =~ s/[^a-zA-Z0-9]/\_/g;
      $hnkey = $vhostname . "_hostnames"; 
      $snkey = $vhostname . "_servername"; 
      $sadkey = $vhostname . "_serveradmin"; 
      $drkey = $vhostname . "_documentroot"; 
      $trkey = $vhostname . "_transferlog"; 
      $erkey = $vhostname . "_errorlog"; 
      $sakey = $vhostname . "_scriptalias"; 
      $ookey = $vhostname . "_otheroptions"; 
      # clean up the text area element form data
      if ($g_form{$ookey}) {
        $g_form{$ookey} =~ s/\r\n/\n/g;
        $g_form{$ookey} =~ s/\r//g;
        $g_form{$ookey} =~ s/\s+$//g;
        $g_form{$ookey} .= "\n";
      }
      # clean up the hostnames
      $g_form{$hnkey} =~ s/\s/ /g; 
      $g_form{$hnkey} =~ s/\s+/ /g;
      # fill in certain fields if left blank and (type == add)
      if ($type eq "add") {
        if ((($vhost =~ /^__NEWVHOST/) && ($g_platform_type eq "dedicated")) ||
            ($g_vhosts{$vhost}->{'ip_based'})) {
          if (($g_form{$hnkey}) && (!$g_form{$snkey}) &&
              (!$g_form{$sadkey}) && (!$g_form{$drkey}) &&
              (!$g_form{$trkey}) && (!$g_form{$erkey}) &&
              (!$g_form{$sakey}) && (!$g_form{$ookey})) {
            # blank out hostname if nothing else is filled in; the hostname
            # was a hidden form element set to the server ip
            $g_form{$hnkey} = "";
          }
        }
        if ((!$g_form{$snkey}) && $g_form{$hnkey}) {
          @hostnames = split(/\ /, $g_form{$hnkey});
          $g_form{$snkey} = $hostnames[0]; 
        }
        if ((!$g_form{$hnkey}) && $g_form{$snkey}) {
          $g_form{$hnkey} = $g_form{$snkey};
        }
      }
      # next if new and left blank
      next if (($vhost =~ /^__NEWVHOST/) && 
               (!$g_form{$hnkey}) && (!$g_form{$snkey}) &&
               (!$g_form{$sadkey}) && (!$g_form{$drkey}) &&
               (!$g_form{$trkey}) && (!$g_form{$erkey}) &&
               (!$g_form{$sakey}) && (!$g_form{$ookey}));
      # next if no change was made (only applicable for type == edit)
      if ($type eq "edit") {
        # set the orig_otheroptions value
        $orig_otheroptions = "";
        foreach $directive (@{$g_vhosts{$vhost}->{'directives'}}) {
          next if (($directive =~ /^servername\s/i) ||
                   ($directive =~ /^serveradmin\s/i) ||
                   ($directive =~ /^documentroot\s/i) ||
                   ($directive =~ /^transferlog\s/i) ||
                   ($directive =~ /^errorlog\s/i) ||
                   ($directive =~ /^scriptalias\s/i));
          $orig_otheroptions .= "$directive\n";
        }
        if (($g_form{$hnkey} eq $vhost) &&
            ($g_form{$snkey} eq $g_vhosts{$vhost}->{'servername'}) &&
            ($g_form{$sadkey} eq $g_vhosts{$vhost}->{'serveradmin'}) &&
            ($g_form{$drkey} eq $g_vhosts{$vhost}->{'documentroot'}) &&
            ($g_form{$trkey} eq $g_vhosts{$vhost}->{'transferlog'}) &&
            ($g_form{$erkey} eq $g_vhosts{$vhost}->{'errorlog'}) &&
            ($g_form{$sakey} eq $g_vhosts{$vhost}->{'scriptalias'}) &&
            ($g_form{$ookey} eq $orig_otheroptions)) {
          $g_form{'vhosts'} =~ s/^\Q$vhost\E$//;
          $g_form{'vhosts'} =~ s/^\Q$vhost\E\|\|\|//;
          $g_form{'vhosts'} =~ s/\|\|\|\Q$vhost\E\|\|\|/\|\|\|/;
          $g_form{'vhosts'} =~ s/\|\|\|\Q$vhost\E$//;
          next;
        }
      }
      $vcount++;
      # when adding new virtual host, need either hostnames or servername
      if ($type eq "add") {
        if ((!$g_form{$hnkey}) && (!$g_form{$snkey})) {
          $errors{$vhost}->{$hnkey} = $VHOSTS_ERROR_HOSTNAMES_IS_BLANK;
        }
      }
      # check to see if both hostnames and documentroot are specified (if
      # one is specified, then require both ... if neither are specified, 
      # then assume removal is wanted
      if ((!$g_form{$hnkey}) && $g_form{$drkey}) {
        $errors{$vhost}->{$hnkey} = $VHOSTS_ERROR_HOSTNAMES_IS_BLANK;
      }
      if ($g_form{$hnkey} && (!$g_form{$drkey})) {
        $errors{$vhost}->{$drkey} = $VHOSTS_ERROR_DOCUMENTROOT_IS_BLANK;
      }
      # remove trailing slashes from document root specification
      $g_form{$drkey} =~ s/\/+$//g if ($g_form{$drkey});
      # virtual host definition check; no duplicate additions allowed
      if ($type eq "add") {
        $errflag = 0;
        @hostnames = split(/\ /, $g_form{$hnkey});
        foreach $definedhost (keys(%g_vhosts)) {
          $definedhost =~ s/\s/ /; 
          $definedhost =~ s/\s+/ /;
          @myhn = split(/\ /, $definedhost);
          for ($index=0; (($index<=$#hostnames) && (!($errflag))); $index++) {
            for ($index2=0; (($index2<=$#myhn) && (!($errflag))); $index2++) {
              if ($hostnames[$index] eq $myhn[$index2]) {
                $errmsg = $VHOSTS_ERROR_DUPLICATE_ADDITION;
                $errmsg =~ s/__VHOST__/$hostnames[$index]/;
                $errors{$vhost}->{$hnkey} = $errmsg;
                $errflag = 1;
              }
            }
          }
          last if ($errflag);
        }
      }
      # idiot checks: for example, removing "DocumentRoot" included in the 
      # DocumentRoot definition (believe it or not, it was reported as a 
      # 'serious' problem by a customer)
      $g_form{$snkey} =~ s/^servername//i;
      $g_form{$sadkey} =~ s/^serveradmin//i;
      $g_form{$drkey} =~ s/^documentroot//i;
      $g_form{$sakey} =~ s/^scriptalias//i;
      $g_form{$trkey} =~ s/^transferlog//i;
      $g_form{$erkey} =~ s/^errorlog//i;
      # remove leading and trailing spaces
      $g_form{$hnkey} =~ s/^\s+//;
      $g_form{$hnkey} =~ s/\s+$//;
      $g_form{$snkey} =~ s/^\s+//;
      $g_form{$snkey} =~ s/\s+$//;
      $g_form{$sadkey} =~ s/^\s+//;
      $g_form{$sadkey} =~ s/\s+$//;
      $g_form{$drkey} =~ s/^\s+//;
      $g_form{$drkey} =~ s/\s+$//;
      $g_form{$sakey} =~ s/^\s+//;
      $g_form{$sakey} =~ s/\s+$//;
      $g_form{$trkey} =~ s/^\s+//;
      $g_form{$trkey} =~ s/\s+$//;
      $g_form{$erkey} =~ s/^\s+//;
      $g_form{$erkey} =~ s/\s+$//;
    }
    if (keys(%errors)) {
      vhostsDisplayForm($type, %errors);
    }
    if ($vcount == 0) {
      # nothing to do!
      vhostsNoChangesExist($type);
    }
    # print out a confirm form if necessary
    $g_form{'confirm'} = "no" unless ($g_form{'confirm'});
    if ($g_form{'confirm'} ne "yes") {
      vhostsConfirmChanges($type);
    }
  }
}

##############################################################################

sub vhostsCommitChanges
{
  local($type) = @_;
  local($vhost, @selectedvhosts, @vhostlist, $pkey, $ukey);
  local($hnkey, $snkey, $sadkey, $drkey, $trkey, $erkey, $sakey, $ookey);
  local($vhostname, $directive, $orig_otheroptions);
  local($success_mesg);

  @selectedvhosts = split(/\|\|\|/, $g_form{'vhosts'});
  foreach $vhost (@selectedvhosts) {
    if (($type eq "add") || ($type eq "edit")) {
      $vhostname = $vhost;
      $vhostname =~ s/[^a-zA-Z0-9]/\_/g;
      $hnkey = $vhostname . "_hostnames"; 
      $snkey = $vhostname . "_servername"; 
      $sadkey = $vhostname . "_serveradmin"; 
      $drkey = $vhostname . "_documentroot"; 
      $trkey = $vhostname . "_transferlog"; 
      $erkey = $vhostname . "_errorlog"; 
      $sakey = $vhostname . "_scriptalias"; 
      $ookey = $vhostname . "_otheroptions"; 
      if ($vhost =~ /^__NEWVHOST/) {
        $pkey = $vhostname . "_placement";
        $ukey = $vhostname . "_user";
      }
      # clean up the text area element form data
      if ($g_form{$ookey}) {
        $g_form{$ookey} =~ s/\r\n/\n/g;
        $g_form{$ookey} =~ s/\r//g;
        $g_form{$ookey} =~ s/\s+$//g;
        $g_form{$ookey} .= "\n";
      }
      if ($g_platform_type eq "virtual") {
        # set the _servername form field if type == add, this must match the
        # first domain name listed in the hostnames field.  this is done so 
        # that frontpage won't barf on the virtual host
        if ($type eq "add") {
          @hostnames = split(/\ /, $g_form{$hnkey});
          $g_form{$snkey} = $hostnames[0]; 
        }
      }
      # set the orig_otheroptions value if type == edit
      if ($type eq "edit") {
        $orig_otheroptions = "";
        foreach $directive (@{$g_vhosts{$vhost}->{'directives'}}) {
          next if (($directive =~ /^servername\s/i) ||
                   ($directive =~ /^serveradmin\s/i) ||
                   ($directive =~ /^documentroot\s/i) ||
                   ($directive =~ /^transferlog\s/i) ||
                   ($directive =~ /^errorlog\s/i) ||
                   ($directive =~ /^scriptalias\s/i));
          $orig_otheroptions .= "$directive\n";
        }
      }
      # next if new and left blank
      next if (($vhost =~ /^__NEWVHOST/) && 
               (!$g_form{$hnkey}) && (!$g_form{$snkey}) &&
               (!$g_form{$sadkey}) && (!$g_form{$drkey}) &&
               (!$g_form{$trkey}) && (!$g_form{$erkey}) &&
               (!$g_form{$sakey}) && (!$g_form{$ookey}));
      # next if no change was made (only applicable for type == edit)
      next if (($type eq "edit") &&
               ($g_form{$hnkey} eq $vhost) &&
               ($g_form{$snkey} eq $g_vhosts{$vhost}->{'servername'}) &&
               ($g_form{$sadkey} eq $g_vhosts{$vhost}->{'serveradmin'}) &&
               ($g_form{$drkey} eq $g_vhosts{$vhost}->{'documentroot'}) &&
               ($g_form{$trkey} eq $g_vhosts{$vhost}->{'transferlog'}) &&
               ($g_form{$erkey} eq $g_vhosts{$vhost}->{'errorlog'}) &&
               ($g_form{$sakey} eq $g_vhosts{$vhost}->{'scriptalias'}) &&
               ($g_form{$ookey} eq $orig_otheroptions));
      if ((!$g_form{$hnkey}) && (!$g_form{$drkey})) {
        # poor man's way of removing a vhost, i.e. editing it and setting
        # its hostnames and document root value to "" ...tag it for removal
        $g_vhosts{$vhost}->{'new_hostnames'} = "__REMOVE";
      }
      else {
        $g_vhosts{$vhost}->{'new_hostnames'} = $g_form{$hnkey};
        $g_vhosts{$vhost}->{'new_servername'} = $g_form{$snkey};
        $g_vhosts{$vhost}->{'new_serveradmin'} = $g_form{$sadkey};
        $g_vhosts{$vhost}->{'new_documentroot'} = $g_form{$drkey};
        $g_vhosts{$vhost}->{'new_transferlog'} = $g_form{$trkey};
        $g_vhosts{$vhost}->{'new_errorlog'} = $g_form{$erkey};
        $g_vhosts{$vhost}->{'new_scriptalias'} = $g_form{$sakey};
        $g_vhosts{$vhost}->{'new_otheroptions'} = $g_form{$ookey};
        $g_vhosts{$vhost}->{'placement'} = $g_form{$pkey};
        $g_vhosts{$vhost}->{'user'} = $g_form{$ukey};
      }
      push(@vhostlist, $vhost);
    }
    elsif ($type eq "remove") {
      $g_vhosts{$vhost}->{'new_hostnames'} = "__REMOVE";
      push(@vhostlist, $vhost);
    }
  }
  vhostsSaveChanges(@vhostlist);

  # now redirect to the restart apache wizard and show success message
  if ($type eq "add") {
    $success_mesg = $VHOSTS_SUCCESS_ADD_TEXT;
  }
  elsif ($type eq "edit") {
    $success_mesg = $VHOSTS_SUCCESS_EDIT_TEXT;
  }
  elsif ($type eq "remove") {
    $success_mesg = $VHOSTS_SUCCESS_REMOVE_TEXT;
  }
  $success_mesg .= "\n$VHOSTS_SUCCESS_RESTART";
  redirectLocation("restart_apache.cgi", $success_mesg);
}

##############################################################################

sub vhostsConfirmChanges
{
  local($type) = @_;
  local($subtitle, $title);
  local($vhost, @selectedvhosts, $pkey, $ukey, @hostnames);
  local($hnkey, $snkey, $sadkey, $drkey, $trkey, $erkey, $sakey, $ookey);
  local($vhostname, $directive, $orig_otheroptions, @oolines, $indent);
  local($idx, $maxidx);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("vhosts");

  if ($type eq "add") {
    $subtitle = "$IROOT_ADD_TEXT: $CONFIRM_STRING";
  }
  elsif ($type eq "edit") {
    $subtitle = "$IROOT_EDIT_TEXT: $CONFIRM_STRING";
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_VHOSTS_TITLE: $subtitle";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlText($VHOSTS_CONFIRM_TEXT);
  htmlP();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "type", "value", $type);
  formInput("type", "hidden", "name", "confirm", "value", "yes");
  formInput("type", "hidden", "name", "vhosts",
            "value", $g_form{'vhosts'});
  htmlUL();
  @selectedvhosts = split(/\|\|\|/, $g_form{'vhosts'});
  foreach $vhost (@selectedvhosts) {
    $vhostname = $vhost;
    $vhostname =~ s/[^a-zA-Z0-9]/\_/g;
    $hnkey = $vhostname . "_hostnames"; 
    $snkey = $vhostname . "_servername"; 
    $sadkey = $vhostname . "_serveradmin"; 
    $drkey = $vhostname . "_documentroot"; 
    $trkey = $vhostname . "_transferlog"; 
    $erkey = $vhostname . "_errorlog"; 
    $sakey = $vhostname . "_scriptalias"; 
    $ookey = $vhostname . "_otheroptions"; 
    $pkey = $vhostname . "_placement";
    $ukey = $vhostname . "_user";
    # clean up the text area element form data
    if ($g_form{$ookey}) {
      $g_form{$ookey} =~ s/\r\n/\n/g;
      $g_form{$ookey} =~ s/\r//g;
      $g_form{$ookey} =~ s/\s+$//g;
      $g_form{$ookey} .= "\n";
    }
    if ($g_platform_type eq "virtual") {
      # set the _servername form field if type == add, this must match the
      # first domain name listed in the hostnames field.  this is done so 
      # that frontpage won't barf on the virtual host
      if ($type eq "add") {
        @hostnames = split(/\ /, $g_form{$hnkey});
        $g_form{$snkey} = $hostnames[0]; 
      }
    }
    # set the orig_otheroptions value if type == edit
    if ($type eq "edit") {
      $orig_otheroptions = "";
      foreach $directive (@{$g_vhosts{$vhost}->{'directives'}}) {
        next if (($directive =~ /^servername\s/i) ||
                 ($directive =~ /^serveradmin\s/i) ||
                 ($directive =~ /^documentroot\s/i) ||
                 ($directive =~ /^transferlog\s/i) ||
                 ($directive =~ /^errorlog\s/i) ||
                 ($directive =~ /^scriptalias\s/i));
        $orig_otheroptions .= "$directive\n";
      }
    }
    # next if new and left blank
    next if (($vhost =~ /^__NEWVHOST/) && 
             (!$g_form{$hnkey}) && (!$g_form{$snkey}) &&
             (!$g_form{$sadkey}) && (!$g_form{$drkey}) &&
             (!$g_form{$trkey}) && (!$g_form{$erkey}) &&
             (!$g_form{$sakey}) && (!$g_form{$ookey}));
    # next if no change was made (only applicable for type == edit)
    next if (($type eq "edit") &&
             ($g_form{$hnkey} eq $vhost) &&
             ($g_form{$snkey} eq $g_vhosts{$vhost}->{'servername'}) &&
             ($g_form{$sadkey} eq $g_vhosts{$vhost}->{'serveradmin'}) &&
             ($g_form{$drkey} eq $g_vhosts{$vhost}->{'documentroot'}) &&
             ($g_form{$trkey} eq $g_vhosts{$vhost}->{'transferlog'}) &&
             ($g_form{$erkey} eq $g_vhosts{$vhost}->{'errorlog'}) &&
             ($g_form{$sakey} eq $g_vhosts{$vhost}->{'scriptalias'}) &&
             ($g_form{$ookey} eq $orig_otheroptions));
    # print out the hidden fields
    formInput("type", "hidden", "name", $hnkey, "value", $g_form{$hnkey});
    formInput("type", "hidden", "name", $snkey, "value", $g_form{$snkey});
    formInput("type", "hidden", "name", $sadkey, "value", $g_form{$sadkey});
    formInput("type", "hidden", "name", $drkey, "value", $g_form{$drkey});
    formInput("type", "hidden", "name", $trkey, "value", $g_form{$trkey});
    formInput("type", "hidden", "name", $erkey, "value", $g_form{$erkey});
    formInput("type", "hidden", "name", $sakey, "value", $g_form{$sakey});
    formInput("type", "hidden", "name", $ookey, "value", $g_form{$ookey});
    if (defined($g_form{$pkey})) {
      formInput("type", "hidden", "name", $pkey, "value", $g_form{$pkey});
    }
    if (defined($g_form{$ukey})) {
      formInput("type", "hidden", "name", $ukey, "value", $g_form{$ukey});
    }
    htmlListItem();
    if ((!$g_form{$hnkey}) && (!$g_form{$drkey})) {
      # poor man's way of removing a vhost, i.e. editing it and setting
      # its hostname and document root values to "" ...confirm removal
      htmlTextBold($VHOSTS_CONFIRM_REMOVE);
      htmlBR();
      $maxidx = ($g_vhosts{$vhost}->{'ip_based'}) ? 
                 ($#{$g_vhosts{$vhost}->{'ip_bindings'}}+1) : 1;
      for ($idx=1; $idx<=$maxidx; $idx++) {
        if ($g_vhosts{$vhost}->{'ip_based'}) {
          print "&#160; ";
          htmlTextCode("<VirtualHost ");
          htmlTextCode("$g_vhosts{$vhost}->{'ip_bindings'}[$idx-1]");
          htmlBR();
          if ($g_vhosts{$vhost}->{'ip_bindings'}[$idx-1] =~ /443$/) {
            print "&#160; &#160; ";
            if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#) {
              htmlTextCode("SSLEngine on");
            }
            else {
              htmlTextCode("SSLEnable");
            }
          }
          else {
            print "&#160; &#160; ";
            if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#) {
              htmlTextCode("SSLEngine off");
            }
            else {
              htmlTextCode("SSLDisable");
            }
          }
        }
        else {
          print "&#160; ";
          htmlTextCode("<VirtualHost $vhost>");
        }
        htmlBR();
        $indent = 0;
        foreach $directive (@{$g_vhosts{$vhost}->{'directives'}}) {
          if ($directive =~ /^\<\//) {
            $indent--;
          }
          if ($indent > 0) {  # indent for Phil
            print "&#160; " x ($indent*2);
          }
          if (($directive =~ /^\</) && ($directive !~ /^\<\//)) {
            $indent++;
          }
          print "&#160; &#160; ";  # indent for Phil
          htmlTextCode("$directive");
          htmlBR();
        }
        print "&#160; ";
        htmlTextCode("</VirtualHost>");
        htmlBR();
      }
    }
    else {
      if ($vhost =~ /^__NEWVHOST/) {
        # confirm addition
        htmlTextBold($VHOSTS_CONFIRM_ADD);
        htmlBR();
        $maxidx = ($g_platform_type ne "dedicated") ? 1 : 2;
        for ($idx=1; $idx<=$maxidx; $idx++) {
          if ($g_platform_type ne "dedicated") {
            print "&#160; ";
            htmlTextCode("<VirtualHost $g_form{$hnkey}>");
          }
          else {
            if ($idx == 1) {
              print "&#160; ";
              htmlTextCode("<VirtualHost $ENV{'SERVER_ADDR'}:80>");
              htmlBR();
              print "&#160; &#160; ";
              if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#) {
                htmlTextCode("SSLEngine off");
              }
              else {
                htmlTextCode("SSLDisable");
              }
            }
            else {
              print "&#160; ";
              htmlTextCode("<VirtualHost $ENV{'SERVER_ADDR'}:443>");
              htmlBR();
              print "&#160; &#160; ";
              if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#) {
                htmlTextCode("SSLEngine on");
              }
              else {
                htmlTextCode("SSLEnable");
              }
            }
          }
          htmlBR();
          if ($g_form{$snkey}) {
            print "&#160; &#160; ";
            htmlTextCode("ServerName $g_form{$snkey}");
            htmlBR();
          }
          if ($g_form{$sadkey}) {
            print "&#160; &#160; ";
            htmlTextCode("ServerAdmin $g_form{$sadkey}");
            htmlBR();
          }
          if ($g_form{$drkey}) {
            print "&#160; &#160; ";
            htmlTextCode("DocumentRoot $g_form{$drkey}");
            htmlBR();
          }
          if ($g_form{$trkey}) {
            print "&#160; &#160; ";
            htmlTextCode("TransferLog $g_form{$trkey}");
            htmlBR();
          }
          if ($g_form{$erkey}) {
            print "&#160; &#160; ";
            htmlTextCode("ErrorLog $g_form{$erkey}");
            htmlBR();
          }
          if ($g_form{$sakey}) {
            print "&#160; &#160; ";
            htmlTextCode("ScriptAlias $g_form{$sakey}");
            htmlBR();
          }
          if ($g_form{$ookey}) {
            $indent = 0;
            @oolines = split(/\n/, $g_form{$ookey});
            foreach $directive (@oolines) {
              if ($directive =~ /^\<\//) {
                $indent--;
              }
              if ($indent > 0) {  # indent for Phil
                print "&#160; " x ($indent*2);
              }
              if (($directive =~ /^\</) && ($directive !~ /^\<\//)) {
                $indent++;
              }
              print "&#160; &#160; ";
              htmlTextCode("$directive");
              htmlBR();
            }
          }
          print "&#160; ";
          htmlTextCode("</VirtualHost>");
          htmlBR();
        }
      }
      else {
        # confirm edition
        htmlTextBold($VHOSTS_CONFIRM_CHANGE_FROM);
        htmlBR();
        $maxidx = ($g_vhosts{$vhost}->{'ip_based'}) ? 
                   ($#{$g_vhosts{$vhost}->{'ip_bindings'}}+1) : 1;
        for ($idx=1; $idx<=$maxidx; $idx++) {
          if ($g_vhosts{$vhost}->{'ip_based'}) {
            print "&#160; ";
            htmlTextCode("<VirtualHost ");
            htmlTextCode("$g_vhosts{$vhost}->{'ip_bindings'}[$idx-1]");
            htmlBR();
            if ($g_vhosts{$vhost}->{'ip_bindings'}[$idx-1] =~ /443$/) {
              print "&#160; &#160; ";
              if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#) {
                htmlTextCode("SSLEngine on");
              }
              else {
                htmlTextCode("SSLEnable");
              }
            }
            else {
              print "&#160; &#160; ";
              if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#) {
                htmlTextCode("SSLEngine off");
              }
              else {
                htmlTextCode("SSLDisable");
              }
            }
          }
          else {
            print "&#160; ";
            htmlTextCode("<VirtualHost $vhost>");
          }
          htmlBR();
          if ($g_vhosts{$vhost}->{'servername'}) {
            print "&#160; &#160; ";
            htmlTextCode("ServerName $g_vhosts{$vhost}->{'servername'}");
            htmlBR();
          }
          if ($g_vhosts{$vhost}->{'serveradmin'}) {
            print "&#160; &#160; ";
            htmlTextCode("ServerAdmin $g_vhosts{$vhost}->{'serveradmin'}");
            htmlBR();
          }
          if ($g_vhosts{$vhost}->{'documentroot'}) {
            print "&#160; &#160; ";
            htmlTextCode("DocumentRoot $g_vhosts{$vhost}->{'documentroot'}");
            htmlBR();
          }
          if ($g_vhosts{$vhost}->{'transferlog'}) {
            print "&#160; &#160; ";
            htmlTextCode("TransferLog $g_vhosts{$vhost}->{'transferlog'}");
            htmlBR();
          }
          if ($g_vhosts{$vhost}->{'errorlog'}) {
            print "&#160; &#160; ";
            htmlTextCode("ErrorLog $g_vhosts{$vhost}->{'errorlog'}");
            htmlBR();
          }
          if ($g_vhosts{$vhost}->{'scriptalias'}) {
            print "&#160; &#160; ";
            htmlTextCode("ScriptAlias $g_vhosts{$vhost}->{'scriptalias'}");
            htmlBR();
          }
          $indent = 0;
          foreach $directive (@{$g_vhosts{$vhost}->{'directives'}}) {
            next if (($directive =~ /^servername\s/i) ||
                     ($directive =~ /^serveradmin\s/i) ||
                     ($directive =~ /^documentroot\s/i) ||
                     ($directive =~ /^transferlog\s/i) ||
                     ($directive =~ /^errorlog\s/i) ||
                     ($directive =~ /^scriptalias\s/i));
            if ($directive =~ /^\<\//) {
              $indent--;
            }
            if ($indent > 0) {  # indent for Phil
              print "&#160; " x ($indent*2);
            }
            if (($directive =~ /^\</) && ($directive !~ /^\<\//)) {
              $indent++;
            }
            print "&#160; &#160; ";
            htmlTextCode("$directive");
            htmlBR();
          }
          print "&#160; ";
          htmlTextCode("</VirtualHost>");
          htmlBR();
        }
        htmlTextCodeBold($VHOSTS_CONFIRM_CHANGE_TO);
        htmlBR();
        for ($idx=1; $idx<=$maxidx; $idx++) {
          if ($g_vhosts{$vhost}->{'ip_based'}) {
            print "&#160; ";
            htmlTextCode("<VirtualHost ");
            htmlTextCode("$g_vhosts{$vhost}->{'ip_bindings'}[$idx-1]");
            if ($g_vhosts{$vhost}->{'ip_bindings'}[$idx-1] =~ /443$/) {
              print "&#160; &#160; ";
              if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#) {
                htmlTextCode("SSLEngine on");
              }
              else {
                htmlTextCode("SSLEnable");
              }
            }
            else {
              print "&#160; &#160; ";
              if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#) {
                htmlTextCode("SSLEngine off");
              }
              else {
                htmlTextCode("SSLDisable");
              }
            }
          }
          else {
            print "&#160; ";
            htmlTextCode("<VirtualHost $g_form{$hnkey}>");
          }
          htmlBR();
          if ($g_form{$snkey}) {
            print "&#160; &#160; ";
            htmlTextCode("ServerName $g_form{$snkey}");
            htmlBR();
          }
          if ($g_form{$sadkey}) {
            print "&#160; &#160; ";
            htmlTextCode("ServerAdmin $g_form{$sadkey}");
            htmlBR();
          }
          if ($g_form{$drkey}) {
            print "&#160; &#160; ";
            htmlTextCode("DocumentRoot $g_form{$drkey}");
            htmlBR();
          }
          if ($g_form{$trkey}) {
            print "&#160; &#160; ";
            htmlTextCode("TransferLog $g_form{$trkey}");
            htmlBR();
          }
          if ($g_form{$erkey}) {
            print "&#160; &#160; ";
            htmlTextCode("ErrorLog $g_form{$erkey}");
            htmlBR();
          }
          if ($g_form{$sakey}) {
            print "&#160; &#160; ";
            htmlTextCode("ScriptAlias $g_form{$sakey}");
            htmlBR();
          }
          if ($g_form{$ookey}) {
            $indent = 0;
            @oolines = split(/\n/, $g_form{$ookey});
            foreach $directive (@oolines) {
              if ($directive =~ /^\<\//) {
                $indent--;
              }
              if ($indent > 0) {  # indent for Phil
                print "&#160; " x ($indent*2);
              }
              if (($directive =~ /^\</) && ($directive !~ /^\<\//)) {
                $indent++;
              }
              print "&#160; &#160; ";
              htmlTextCode("$directive");
              htmlBR();
            }
          }
          print "&#160; ";
          htmlTextCode("</VirtualHost>");
          htmlBR();
        }
      }
    }
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
  }
  htmlULClose();
  htmlP();
  formInput("type", "submit", "name", "submit", "value", $CONFIRM_STRING);
  formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  formClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub vhostsCreateDirectories
{
  local($virtualhost, $user) = @_;
  local($key, %targetpaths, $targetpath, @subpaths, $index, $curpath);

  if (($g_platform_type eq "dedicated") && (!$user)) {
    $user = "www";
  }

  # build a list of directory pathnames from the directive definitions in
  # the virtualhost hash
  if ($virtualhost =~ /DocumentRoot (\S*)/s) {
    $targetpath = $1;
    if ($targetpath =~ /^\//) {
      $targetpath =~ s/\/+$//g;
      $targetpaths{$targetpath}->{'directive'} = "DocumentRoot";
      if ($g_platform_type eq "dedicated") {
        # user/group ownership of path; docroot owned by user:www
        $targetpaths{$targetpath}->{'uid'} = $g_users{$user}->{'uid'};
        $targetpaths{$targetpath}->{'gid'} = $g_users{'www'}->{'gid'};
      }
    }
  }
  if ($virtualhost =~ /ScriptAlias \/cgi-bin\/ (\S*)/s) {
    $targetpath = $1;
    if ($targetpath =~ /^\//) {
      $targetpath =~ s/\/+$//g;
      $targetpaths{$targetpath}->{'directive'} = "ScriptAlias";
      if ($g_platform_type eq "dedicated") {
        # user/group ownership of path; cgi-bin owned by user:www
        $targetpaths{$targetpath}->{'uid'} = $g_users{$user}->{'uid'};
        $targetpaths{$targetpath}->{'gid'} = $g_users{'www'}->{'gid'};
      }
    }
  }
  if ($virtualhost =~ /ScriptAlias \/cgi-local\/ (\S*)/s) {
    $targetpath = $1;
    if ($targetpath =~ /^\//) {
      $targetpath =~ s/\/+$//g;
      $targetpaths{$targetpath}->{'directive'} = "ScriptAlias (Local)";
      if ($g_platform_type eq "dedicated") {
        # user/group ownership of path; cgi-local owned by user:www
        $targetpaths{$targetpath}->{'uid'} = $g_users{$user}->{'uid'};
        $targetpaths{$targetpath}->{'gid'} = $g_users{'www'}->{'gid'};
      }
    }
  }
  if ($virtualhost =~ /TransferLog (\S*)/s) {
    $targetpath = $1;
    if ($targetpath =~ /^\//) {
      $targetpath =~ s/\/+$//g;
      $targetpath =~ s/[^\/]+$//g;
      $targetpaths{$targetpath}->{'directive'} = "TransferLog";
      if ($g_platform_type eq "dedicated") {
        # user/group ownership of path; logs are owned by root:user
        $targetpaths{$targetpath}->{'uid'} = $g_users{'root'}->{'uid'};
        $targetpaths{$targetpath}->{'gid'} = $g_users{$user}->{'gid'};
      }
    }
  }
  if ($virtualhost =~ /CustomLog (\S*)/s) {
    # should we first for more than one CustomLog or just the first one
    # encountered?  just handle the first one encountered for now.
    $targetpath = $1;
    if ($targetpath =~ /^\//) {
      $targetpath =~ s/\/+$//g;
      $targetpath =~ s/[^\/]+$//g;
      $targetpaths{$targetpath}->{'directive'} = "CustomLog";
      if ($g_platform_type eq "dedicated") {
        # user/group ownership of path; logs are owned by root:user
        $targetpaths{$targetpath}->{'uid'} = $g_users{'root'}->{'uid'};
        $targetpaths{$targetpath}->{'gid'} = $g_users{$user}->{'gid'};
      }
    }
  }
  if ($virtualhost =~ /ErrorLog (\S*)/s) {
    $targetpath = $1;
    if ($targetpath =~ /^\//) {
      $targetpath =~ s/\/+$//g;
      $targetpath =~ s/[^\/]+$//g;
      $targetpaths{$targetpath}->{'directive'} = "ErrorLog";
      if ($g_platform_type eq "dedicated") {
        # user/group ownership of path; logs are owned by root:user
        $targetpaths{$targetpath}->{'uid'} = $g_users{'root'}->{'uid'};
        $targetpaths{$targetpath}->{'gid'} = $g_users{$user}->{'gid'};
      }
    }
  }

  foreach $targetpath (keys(%targetpaths)) {
    if (-e "$targetpath") {
      if (-d "$targetpath") {
        # ignore if directory already exists
        next;
      }
      else {
        # target exists, but is a file... remove first
        unlink($targetpath);
      }
    }
    $targetpath =~ s/\/+$//;
    @subpaths = split(/\//, $targetpath);
    $curpath = "";
    for ($index=0; $index<=$#subpaths; $index++) {
      next unless ($subpaths[$index]);
      $curpath .= "/$subpaths[$index]";
      $curpath =~ s/\/\//\//g;
      if (!(-d "$curpath")) {
        mkdir($curpath, 0755) ||
          irootResourceError($IROOT_VHOSTS_TITLE,
              "call to mkdir($curpath, 0755) in vhostsCreateDirectories");
        if ($g_platform_type eq "dedicated") {
          # change ownership of new directory
          chown($targetpaths{$targetpath}->{'uid'}, 
                $targetpaths{$targetpath}->{'gid'}, $curpath);
        }
        # change mode of new directory
        chmod(0755, "$curpath");
      }
    }
    if ($targetpaths{$targetpath}->{'directive'} =~ /ScriptAlias/) {
      chmod(0750, "$targetpath");
    }
  }
}

##############################################################################

sub vhostsDisplayForm
{
  local($type, %errors) = @_;
  local($title, $subtitle, $helptext, $buttontext, $vhostlist);
  local(@selectedvhosts, $vhost, $index, $singlevhost, $colspan);
  local($size50, $key, $value, $vhosttxt, $servername);
  local($directive, $vhostoption, $otheroptions, $rows, $javascript);
  local($numnewhosts, @vusers, $path, $group, $tkey, $ttype);
  local($mesg, @lines, $indent, $idx, $maxidx);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("vhosts");

  # check for cancelled actions from the select user form 
  # (applicable to the dedicated environment only)
  if ($g_form{'select_submit'} &&
      ($g_form{'select_submit'} eq $CANCEL_STRING)) {
    redirectLocation("iroot.cgi", $VHOSTS_CANCEL_ADD_TEXT);
  }

  if ($g_form{'msgfileid'}) {
    # read message from temporary state message file
    $mesg = redirectMessageRead($g_form{'msgfileid'});
  }

  if ($type eq "add") {
    $subtitle = $IROOT_ADD_TEXT;
    # populate the selectedvhosts array
    if ($g_form{'vhosts'}) {
      @selectedvhosts = split(/\|\|\|/, $g_form{'vhosts'});
    }
    else {
      # if dedicated, must either have a vhostuserlist or a selecteduser
      # print out a select user form if neither of these are defined
      if (($g_platform_type eq "dedicated") &&
          (!$g_form{'selecteduser'}) && (!$g_form{'vhostuserlist'})) {
        vhostsSelectUserForm();
      }
      if ($g_form{'vhostuserlist'}) {
        @vusers = split(/\|\|\|/, $g_form{'vhostuserlist'});
        $numnewhosts = $#vusers+1;
      }
      elsif ($g_form{'selecteduser'}) {
        $numnewhosts = $g_prefs{'iroot__num_newvhosts'};
        for ($index=0; $index<$numnewhosts; $index++) {
          $vusers[$index] = $g_form{'selecteduser'};
        }
      } 
      else {
        $numnewhosts = $g_prefs{'iroot__num_newvhosts'};
      }
      for ($index=1; $index<=$numnewhosts; $index++) {
        $key = "__NEWVHOST$index";
        push(@selectedvhosts, $key);
        $vhostlist .= "$key\|\|\|";
        if ($#vusers > -1) {
          # users present; this will always be true for platform == dedicated
          # load up an appropriate vhost template for the user
          if ($g_platform_type eq "virtual") {
            $ttype = "user";
          }
          else {  # dedicated
            $ttype = ($vusers[$index-1] eq "vhost") ? "admin" : 
                     ($vusers[$index-1] eq "www") ? "www" : "user";
          }
          if ($ttype ne "www") {
            vhostsTemplateLoad($ttype);
            # pre-populate the values of the directives based on the template
            $group = groupGetNameFromID($g_users{$vusers[$index-1]}->{'gid'});
            $path = $g_users{$vusers[$index-1]}->{'home'};
            $path =~ s/^\///;
            foreach $tkey (keys(%g_vhost_template)) {
              $g_vhosts{$key}->{$tkey} = $g_vhost_template{$tkey};
              $g_vhosts{$key}->{$tkey} =~ s/HOME/$path/g;
              $g_vhosts{$key}->{$tkey} =~ s/LOGIN/$vusers[$index-1]/g;
              $g_vhosts{$key}->{$tkey} =~ s/GROUP/$group/g;
            }
          }
          # save the user in the _user field
          $key .= "_user";
          $g_form{$key} = $vusers[$index-1];
        }
        else {
          # no users present; platform must == virtual for this to be so.
          # since on dedicated you must tie to a user; even if it is 'www'
        }
      }
      $vhostlist =~ s/\|+$//g;
      $g_form{'vhosts'} = $vhostlist;
    }
    $helptext = $VHOSTS_ADD_HELP_TEXT;
    $buttontext = $VHOSTS_ADD_SUBMIT_TEXT;
  }
  elsif ($type eq "edit") {
    $subtitle = $IROOT_EDIT_TEXT;
    @selectedvhosts = split(/\|\|\|/, $g_form{'vhosts'}) if ($g_form{'vhosts'});
    $helptext = $VHOSTS_EDIT_HELP_TEXT;
    $buttontext = $VHOSTS_EDIT_SUBMIT_TEXT;
  } 
  elsif ($type eq "remove") {
    $subtitle = $IROOT_REMOVE_TEXT;
    @selectedvhosts = split(/\|\|\|/, $g_form{'vhosts'}) if ($g_form{'vhosts'});
    $helptext = $VHOSTS_REMOVE_HELP_TEXT;
    $buttontext = $VHOSTS_REMOVE_SUBMIT_TEXT;
  }
  elsif ($type eq "view") {
    $subtitle = $IROOT_VIEW_TEXT;
    foreach $vhost (keys(%g_vhosts)) {
      push(@selectedvhosts, $vhost);
    }
  }

  # are there any virtual hosts selected?
  if ($#selectedvhosts == -1) {
    # oops... no vhosts in selected vhost list.
    if (($type eq "edit") || ($type eq "remove")) {
      $singlevhost = vhostsSelectForm($type);
      @selectedvhosts = ("$singlevhost");
    } 
    else {
      vhostsEmptyFile();
    } 
  }
  else {
    # have selected vhosts, are we re-sorting the selection display?
    if (($type eq "edit") || ($type eq "remove")) {
      vhostsSelectForm($type) if ($g_form{'sort_select'});
    }
  }

  if (($type eq "add") || ($type eq "edit")) {
    $size50 = formInputSize(50);
    $colspan = 4;
    # javascript required for the templates which populate the entry fields
    $javascript = javascriptSearchAndReplace();
  }
  else {
    $colspan = 3;
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_VHOSTS_TITLE: $subtitle";
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title, "", $javascript);

  if ($mesg) {
    @lines = split(/\n/, $mesg);
    foreach $mesg (@lines) {
      htmlTextColorBold(">>>&#160;$mesg&#160;<<<", "#cc0000");
      htmlBR();
    }
    htmlP();
  }
  elsif (keys(%errors)) {
    htmlTextColorBold(">>> $IROOT_ERRORS_FOUND <<<", "#cc0000");
    htmlP();
  }

  # show some help
  if ($type ne "view") {
    htmlText($helptext);
    htmlP();
    if (($type eq "add") || ($type eq "edit")) {
      htmlText($VHOSTS_OVERVIEW_HELP_TEXT);
      htmlP();
      htmlPre();
      htmlFont("class", "fixed", "face", "courier new, courier", "size", "2",
               "style", "font-family:courier new, courier; font-size:12px");
      if ($g_platform_type eq "virtual") {
        print "$VHOSTS_OVERVIEW_EXAMPLE_TEXT_VIRTUAL";
      }
      else {
        print "$VHOSTS_OVERVIEW_EXAMPLE_TEXT_DEDICATED";
      }
      htmlFontClose();
      htmlPreClose();
      if ($g_platform_type eq "virtual") {
        htmlText($VHOSTS_HOSTNAMES_HELP_TEXT);
        htmlP();
      }
      htmlText($VHOSTS_SERVERNAME_HELP_TEXT);
      htmlP();
      htmlText($VHOSTS_SERVERADMIN_HELP_TEXT);
      htmlP();
      htmlText($VHOSTS_DOCUMENTROOT_HELP_TEXT);
      htmlP();
      htmlText($VHOSTS_SCRIPTALIAS_HELP_TEXT);
      htmlP();
      if ($g_platform_type eq "virtual") {
        htmlText($VHOSTS_TRANSFERLOG_HELP_TEXT);
        htmlP();
      }
      htmlText($VHOSTS_ERRORLOG_HELP_TEXT);
      htmlP();
      if (($type eq "add") && (defined($g_vhost_template{'hostnames'}))) {
        htmlText($VHOSTS_TEMPLATE_HELP_TEXT);
        htmlP();
      }
    }
  }
  formOpen("method", "POST", "name", "vhostsform");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "view", "value", $type);
  formInput("type", "hidden", "name", "vhosts", 
            "value", $g_form{'vhosts'});
  htmlTable();
  foreach $vhost (sort vhostsByPreference(@selectedvhosts)) {
    $vhostname = $vhost;
    $vhostname =~ s/[^a-zA-Z0-9]/\_/g;
    # <VirtualHost> row
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "bottom", "colspan", $colspan);
    if (($type eq "view") || ($type eq "remove")) {
      $vhostenc = encodingStringToURL($vhost);
      if ($g_vhosts{$vhost}->{'ip_based'}) {
        $maxidx = $#{$g_vhosts{$vhost}->{'ip_bindings'}};
        $vhosttxt = $g_vhosts{$vhost}->{'ip_bindings'}[0];
        for ($idx=1; $idx<=$maxidx; $idx++) {
          if ($g_vhosts{$vhost}->{'ip_bindings'}[$idx] =~ /\:([0-9]+)$/) {
            $vhosttxt .= ",$1";
          }
        }
      }
      else {
        $vhosttxt = $vhost;
        $vhosttxt =~ s/\ /\&\#160\;/g;
      }
      if ($type eq "view") {
        htmlNoBR();
        htmlTextBold("<VirtualHost&#160;$vhosttxt> ");
        htmlTextSmall("&#160;&#160;&#160;(&#160;");
        htmlAnchor("href", "vhosts_edit.cgi?vhosts=$vhostenc", "title", 
                   "$IROOT_VHOSTS_TITLE: $IROOT_EDIT_TEXT: $vhost");
        htmlAnchorTextSmall($IROOT_EDIT_TEXT);
        htmlAnchorClose();
        htmlTextSmall("&#160;|&#160;");
        htmlAnchor("href", "vhosts_remove.cgi?vhosts=$vhostenc", "title", 
                   "$IROOT_VHOSTS_TITLE: $IROOT_REMOVE_TEXT: $vhost");
        htmlAnchorTextSmall($IROOT_REMOVE_TEXT);
        htmlAnchorClose();
        htmlTextSmall("&#160;)");
        htmlNoBRClose();
      }
      else {
        htmlText("<VirtualHost&#160;$vhosttxt>");
      }
    }
    else {
      htmlTextBold("<VirtualHost>");
    }
    htmlTableDataClose();
    htmlTableRowClose();
    if (($type eq "view") || ($type eq "remove")) {
      # display the defined virtual host directives
      htmlTableRow();
      htmlTableData();
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData();
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData();
      $indent = 0;
      foreach $directive (@{$g_vhosts{$vhost}->{'directives'}}) {
        if ($directive =~ /^(servername)(.*)/i) {
          htmlText("$1 "); 
          $servername = $2;
          $servername =~ s/\ //g;
          $title = $URL_OPEN_STRING;
          $title =~ s/__URL__/http\:\/\/$servername\//;
          htmlAnchor("target", "_blank", "href", "http://$servername/",
                     "title", $title);
          htmlText($servername); 
          htmlAnchorClose();
        }
        else {
          if ($directive =~ /^\<\//) {
            $indent--;
          }
          if ($indent > 0) {  # indent for Phil
            print "&#160; " x ($indent*2);
          }
          if (($directive =~ /^\</) && ($directive !~ /^\<\//)) {
            $indent++;
          }
          htmlText($directive);
        }
        htmlBR();
      }
      htmlTableDataClose();
      htmlTableRowClose();
    }
    else {
      # display the form fields for the virtual host directives
      # directive row 1: host names(s)
      if ((($vhost =~ /^__NEWVHOST/) && ($g_platform_type eq "dedicated")) ||
          ($g_vhosts{$vhost}->{'ip_based'})) {
        $key = $vhostname . "_hostnames";
        formInput("name", $key, "type", "hidden", "value", $ENV{'SERVER_ADDR'});
      }
      else {
        htmlTableRow();
        htmlTableData();
        htmlText("&#160;&#160;");
        htmlTableDataClose();
        htmlTableData();
        htmlText("&#160;&#160;&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextBold("$VHOSTS_HOSTNAMES:");
        htmlTableDataClose();
        htmlTableData("valign", "middle");
        $key = $vhostname . "_hostnames";
        $value = (defined($g_form{'sort_submit'}) ||
                  defined($g_form{'submit'})) ? $g_form{$key} : 
                                      $g_vhosts{$vhost}->{'hostnames'};
        formInput("name", $key, "size", $size50, "value", $value);
        htmlTableDataClose();
        htmlTableData("valign", "middle");
        if (defined($errors{$vhost}->{$key})) {
          htmlTextColorBold(">>> $errors{$vhost}->{$key} <<<", "#cc0000");
        }
        htmlTableDataClose();
        htmlTableRowClose();
      }
      # directive row 2: ServerName
      htmlTableRow();
      htmlTableData();
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData();
      htmlText("&#160;&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$VHOSTS_SERVERNAME:");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      $key = $vhostname . "_servername";
      $value = (defined($g_form{'sort_submit'}) ||
                defined($g_form{'submit'})) ? $g_form{$key} :
                                    $g_vhosts{$vhost}->{'servername'};
      formInput("name", $key, "size", $size50, "value", $value);
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      if (defined($errors{$vhost}->{$key})) {
        htmlTextColorBold(">>> $errors{$vhost}->{$key} <<<", "#cc0000");
      }
      htmlTableDataClose();
      htmlTableRowClose();
      # directive row 3: ServerAdmin
      htmlTableRow();
      htmlTableData();
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData();
      htmlText("&#160;&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$VHOSTS_SERVERADMIN:");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      $key = $vhostname . "_serveradmin";
      $value = (defined($g_form{'sort_submit'}) ||
                defined($g_form{'submit'})) ? $g_form{$key} :
                                    $g_vhosts{$vhost}->{'serveradmin'};
      formInput("name", $key, "size", $size50, "value", $value);
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      if (defined($errors{$vhost}->{$key})) {
        htmlTextColorBold(">>> $errors{$vhost}->{$key} <<<", "#cc0000");
      }
      htmlTableDataClose();
      htmlTableRowClose();
      # directive row 4: DocumentRoot
      htmlTableRow();
      htmlTableData();
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData();
      htmlText("&#160;&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$VHOSTS_DOCUMENTROOT:");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      $key = $vhostname . "_documentroot";
      $value = (defined($g_form{'sort_submit'}) ||
                defined($g_form{'submit'})) ? $g_form{$key} :
                                    $g_vhosts{$vhost}->{'documentroot'};
      formInput("name", $key, "size", $size50, "value", $value);
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      if (defined($errors{$vhost}->{$key})) {
        htmlTextColorBold(">>> $errors{$vhost}->{$key} <<<", "#cc0000");
      }
      htmlTableDataClose();
      htmlTableRowClose();
      # directive row 5: ScriptAlias
      htmlTableRow();
      htmlTableData();
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData();
      htmlText("&#160;&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$VHOSTS_SCRIPTALIAS:");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      $key = $vhostname . "_scriptalias";
      $value = (defined($g_form{'sort_submit'}) ||
                defined($g_form{'submit'})) ? $g_form{$key} :
                                    $g_vhosts{$vhost}->{'scriptalias'};
      formInput("name", $key, "size", $size50, "value", $value);
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      if (defined($errors{$vhost}->{$key})) {
        htmlTextColorBold(">>> $errors{$vhost}->{$key} <<<", "#cc0000");
      }
      htmlTableDataClose();
      htmlTableRowClose();
      # directive row 6: TransferLog
      if ((($vhost =~ /^__NEWVHOST/) && ($g_platform_type eq "dedicated")) ||
          ($g_vhosts{$vhost}->{'ip_based'})) {
        $key = $vhostname . "_transferlog";
        formInput("name", $key, "type", "hidden", "value", "");
      }
      else {
        htmlTableRow();
        htmlTableData();
        htmlText("&#160;&#160;");
        htmlTableDataClose();
        htmlTableData();
        htmlText("&#160;&#160;&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextBold("$VHOSTS_TRANSFERLOG:");
        htmlTableDataClose();
        htmlTableData("valign", "middle");
        $key = $vhostname . "_transferlog";
        $value = (defined($g_form{'sort_submit'}) ||
                defined($g_form{'submit'})) ? $g_form{$key} :
                                    $g_vhosts{$vhost}->{'transferlog'};
        formInput("name", $key, "size", $size50, "value", $value);
        htmlTableDataClose();
        htmlTableData("valign", "middle");
        if (defined($errors{$vhost}->{$key})) {
          htmlTextColorBold(">>> $errors{$vhost}->{$key} <<<", "#cc0000");
        }
        htmlTableDataClose();
        htmlTableRowClose();
      }
      # directive row 7: ErrorLog
      htmlTableRow();
      htmlTableData();
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData();
      htmlText("&#160;&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold("$VHOSTS_ERRORLOG:");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      $key = $vhostname . "_errorlog";
      $value = (defined($g_form{'sort_submit'}) ||
                defined($g_form{'submit'})) ? $g_form{$key} :
                                    $g_vhosts{$vhost}->{'errorlog'};
      formInput("name", $key, "size", $size50, "value", $value);
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      if (defined($errors{$vhost}->{$key})) {
        htmlTextColorBold(">>> $errors{$vhost}->{$key} <<<", "#cc0000");
      }
      htmlTableDataClose();
      htmlTableRowClose();
      # directive row 8: other options
      htmlTableRow();
      htmlTableData();
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData();
      htmlText("&#160;&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("colspan", "2");
      htmlTextBold("$VHOSTS_OTHEROPTIONS:");
      htmlBR();
      $key = $vhostname . "_otheroptions";
      $otheroptions = $g_form{$key};
      if ((!$g_form{'sort_submit'}) && (!$g_form{'submit'}) && (!$otheroptions)) {
        # build up a default from the current def
        foreach $directive (@{$g_vhosts{$vhost}->{'directives'}}) {
          next if (($directive =~ /^servername\s/i) ||
                   ($directive =~ /^serveradmin\s/i) ||
                   ($directive =~ /^documentroot\s/i) ||
                   ($directive =~ /^transferlog\s/i) ||
                   ($directive =~ /^errorlog\s/i) ||
                   ($directive =~ /^scriptalias\s/i));
          $otheroptions .= "$directive\n";
        }
      }
      $rows = formTextAreaRows($otheroptions, 5, 12);
      formTextArea($otheroptions, "name", $key, "rows", $rows+1, 
                   "cols", 65, "_FONT_", "fixed", "wrap", "off");
      htmlTableDataClose();
      htmlTableRowClose();
      # directive row 9: placement (only applicable for add)
      if ($type eq "add") {
        htmlTableRow();
        htmlTableData();
        htmlText("&#160;&#160;");
        htmlTableDataClose();
        htmlTableData();
        htmlText("&#160;&#160;&#160;");
        htmlTableDataClose();
        htmlTableData("colspan", "3");
        htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
        htmlTableRow();
        htmlTableData("valign", "middle", "align", "left");
        htmlTextBold("$VHOSTS_VHOST_PLACEMENT:&#160;&#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle");
        $key = $vhostname . "_placement";
        formSelect("name", $key);
        formSelectOption("__APPEND", $VHOSTS_VHOST_PLACEMENT_APPEND, 
                         ((!$g_form{$key}) || ($g_form{$key} eq "__APPEND")));
        foreach $vhostoption (sort vhostsByPreference(keys(%g_vhosts))) {
          next if ($vhostoption =~ /^__NEWVHOST/);
          $value = $VHOSTS_VHOST_PLACEMENT_INSERT;
          $value =~ s/__VHOST__/$vhostoption/;
          formSelectOption($vhostoption, $value, 
                           (defined($g_form{$key}) && 
                            ($g_form{$key} eq $vhostoption)));
        }
        formSelectClose();
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableClose();
        htmlTableDataClose();
        htmlTableRowClose();
      }
    }
    # </VirtualHost> row
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top", "colspan", "2");
    if ($type ne "remove") {
      htmlTextBold("</VirtualHost>");
    }
    else {
      htmlText("</VirtualHost>");
    }
    htmlTableDataClose();
    if ($type eq "add") {
      # print out the user stuff
      $key = $vhostname . "_user";
      if ($g_platform_type eq "virtual") {
        $ttype = ($g_form{$key}) ? "user" : "admin";
      }
      else {  # dedicated
        $ttype = ($g_form{$key} eq "vhost") ? "admin" : 
                 ($g_form{$key} eq "www") ? "www" : "user";
      }
      vhostsTemplateLoad($ttype);
      formInput("type", "hidden", "name", $key, "value", $g_form{$key});
      htmlTableData("valign", "middle", "colspan", "2");
      if (defined($g_vhost_template{'hostnames'})) {
        $otheroptions = "";
        foreach $directive (@{$g_vhost_template{'directives'}}) {
          next if (($directive =~ /^servername\s/i) ||
                   ($directive =~ /^serveradmin\s/i) ||
                   ($directive =~ /^documentroot\s/i) ||
                   ($directive =~ /^transferlog\s/i) ||
                   ($directive =~ /^errorlog\s/i) ||
                   ($directive =~ /^scriptalias\s/i));
          $otheroptions .= "$directive\\n";
        }
        if (($g_platform_type eq "virtual") ||
            (($g_platform_type eq "dedicated") &&
             (($vhost =~ /^__NEWVHOST/) || 
              ($g_vhosts{$vhost}->{'ip_based'})))) {
          # only show "populate from template" button if appropriate:
          #   1) platform is virtual, or
          #   2) platform is dedicated and host is IP based
          print <<ENDTEXT;
&#160;
<script language="JavaScript1.1">
  document.write("<input type=\\\"button\\\" ");
  document.write("style=\\\"font-family:arial, helvetica; font-size:13px\\\" ");
  document.write("value=\\\"$VHOSTS_POPULATE_FROM_TEMPLATE\\\" ");
  document.write("onClick=\\\"populate_$vhostname()\\\">");
  function populate_$vhostname()
  {
    var domain = "DOMAIN";
ENDTEXT
          if ($g_platform_type eq "virtual") {
            print <<ENDTEXT;
    var name = document.vhostsform.$vhostname\_hostnames.value ||
               document.vhostsform.$vhostname\_servername.value;
ENDTEXT
          }
          else {
            print <<ENDTEXT;
    var name = document.vhostsform.$vhostname\_servername.value;
ENDTEXT
          }
          print <<ENDTEXT;
    name = (name.split(' '))[0];
    if (name == "")
      name = "$VHOSTS_SERVERNAME";
ENDTEXT
          if ($g_platform_type eq "virtual") {
            print <<ENDTEXT;
    document.vhostsform.$vhostname\_hostnames.value =
        search_and_replace(domain, name, "$g_vhost_template{'hostnames'}");
ENDTEXT
          }
          print <<ENDTEXT;
    document.vhostsform.$vhostname\_servername.value = 
        search_and_replace(domain, name, "$g_vhost_template{'servername'}");
    document.vhostsform.$vhostname\_serveradmin.value = 
        search_and_replace(domain, name, "$g_vhost_template{'serveradmin'}");
    document.vhostsform.$vhostname\_documentroot.value = 
        search_and_replace(domain, name, "$g_vhost_template{'documentroot'}");
    document.vhostsform.$vhostname\_scriptalias.value = 
        search_and_replace(domain, name, "$g_vhost_template{'scriptalias'}");
ENDTEXT
          if ($g_platform_type eq "virtual") {
            print <<ENDTEXT;
    document.vhostsform.$vhostname\_transferlog.value = 
        search_and_replace(domain, name, "$g_vhost_template{'transferlog'}");
ENDTEXT
          }
          print <<ENDTEXT;
    document.vhostsform.$vhostname\_errorlog.value = 
        search_and_replace(domain, name, "$g_vhost_template{'errorlog'}");
    document.vhostsform.$vhostname\_otheroptions.value = 
        search_and_replace(domain, name, "$otheroptions");
ENDTEXT
          if ($g_form{$key} ne "__ADMIN__") {
            # need to search and replace for LOGIN, GROUP, and HOME
            $group = groupGetNameFromID($g_users{$g_form{$key}}->{'gid'});
            $path = $g_users{$g_form{$key}}->{'home'};
            $path =~ s/^\///;
            print <<ENDTEXT;
    var login = "LOGIN";
    var username = "$g_form{$key}";
ENDTEXT
            if ($g_platform_type eq "virtual") {
              print <<ENDTEXT;
    document.vhostsform.$vhostname\_hostnames.value =
        search_and_replace(login, username, 
                           document.vhostsform.$vhostname\_hostnames.value);
ENDTEXT
            }
            print <<ENDTEXT;
    document.vhostsform.$vhostname\_servername.value = 
        search_and_replace(login, username, 
                           document.vhostsform.$vhostname\_servername.value);
    document.vhostsform.$vhostname\_serveradmin.value = 
        search_and_replace(login, username, 
                           document.vhostsform.$vhostname\_serveradmin.value);
    document.vhostsform.$vhostname\_documentroot.value = 
        search_and_replace(login, username, 
                           document.vhostsform.$vhostname\_documentroot.value);
    document.vhostsform.$vhostname\_scriptalias.value = 
        search_and_replace(login, username, 
                           document.vhostsform.$vhostname\_scriptalias.value);
ENDTEXT
            if ($g_platform_type eq "virtual") {
              print <<ENDTEXT;
    document.vhostsform.$vhostname\_transferlog.value = 
        search_and_replace(login, username, 
                           document.vhostsform.$vhostname\_transferlog.value);
ENDTEXT
            }
            print <<ENDTEXT;
    document.vhostsform.$vhostname\_errorlog.value = 
        search_and_replace(login, username, 
                           document.vhostsform.$vhostname\_errorlog.value);
    document.vhostsform.$vhostname\_otheroptions.value = 
        search_and_replace(login, username, 
                           document.vhostsform.$vhostname\_otheroptions.value);
    var group = "GROUP";
    var groupname = "$group";
ENDTEXT
            if ($g_platform_type eq "virtual") {
              print <<ENDTEXT;
    document.vhostsform.$vhostname\_hostnames.value =
        search_and_replace(group, groupname, 
                           document.vhostsform.$vhostname\_hostnames.value);
ENDTEXT
            }
            print <<ENDTEXT;
    document.vhostsform.$vhostname\_servername.value = 
        search_and_replace(group, groupname, 
                           document.vhostsform.$vhostname\_servername.value);
    document.vhostsform.$vhostname\_serveradmin.value = 
        search_and_replace(group, groupname, 
                           document.vhostsform.$vhostname\_serveradmin.value);
    document.vhostsform.$vhostname\_documentroot.value = 
        search_and_replace(group, groupname, 
                           document.vhostsform.$vhostname\_documentroot.value);
    document.vhostsform.$vhostname\_scriptalias.value = 
        search_and_replace(group, groupname, 
                           document.vhostsform.$vhostname\_scriptalias.value);
ENDTEXT
            if ($g_platform_type eq "virtual") {
              print <<ENDTEXT;
    document.vhostsform.$vhostname\_transferlog.value = 
        search_and_replace(group, groupname, 
                           document.vhostsform.$vhostname\_transferlog.value);
ENDTEXT
            }
            print <<ENDTEXT;
    document.vhostsform.$vhostname\_errorlog.value = 
        search_and_replace(group, groupname, 
                           document.vhostsform.$vhostname\_errorlog.value);
    document.vhostsform.$vhostname\_otheroptions.value = 
        search_and_replace(group, groupname, 
                           document.vhostsform.$vhostname\_otheroptions.value);
    var home = "HOME";
    var path = "$path";
ENDTEXT
            if ($g_platform_type eq "virtual") {
              print <<ENDTEXT;
    document.vhostsform.$vhostname\_hostnames.value =
        search_and_replace(home, path,  
                           document.vhostsform.$vhostname\_hostnames.value);
ENDTEXT
            }
            print <<ENDTEXT;
    document.vhostsform.$vhostname\_servername.value = 
        search_and_replace(home, path, 
                           document.vhostsform.$vhostname\_servername.value);
    document.vhostsform.$vhostname\_serveradmin.value = 
        search_and_replace(home, path, 
                           document.vhostsform.$vhostname\_serveradmin.value);
    document.vhostsform.$vhostname\_documentroot.value = 
        search_and_replace(home, path, 
                           document.vhostsform.$vhostname\_documentroot.value);
    document.vhostsform.$vhostname\_scriptalias.value = 
        search_and_replace(home, path, 
                           document.vhostsform.$vhostname\_scriptalias.value);
ENDTEXT
            if ($g_platform_type eq "virtual") {
              print <<ENDTEXT;
    document.vhostsform.$vhostname\_transferlog.value = 
        search_and_replace(home, path, 
                           document.vhostsform.$vhostname\_transferlog.value);
ENDTEXT
            }
            print <<ENDTEXT;
    document.vhostsform.$vhostname\_errorlog.value = 
        search_and_replace(home, path, 
                           document.vhostsform.$vhostname\_errorlog.value);
    document.vhostsform.$vhostname\_otheroptions.value = 
        search_and_replace(home, path, 
                           document.vhostsform.$vhostname\_otheroptions.value);
ENDTEXT
          }
          print <<ENDTEXT;
  }
</script>
ENDTEXT
        }
      }
      htmlTableDataClose();
    }
    htmlTableRowClose();
    # virtual host separator (a fine gray line)
    if ($#selectedvhosts > 0) {
      htmlTableRow();
      htmlTableData("colspan", "4");
      htmlTable("cellpadding", "0", "cellspacing", "0",
                "border", "0", "bgcolor", "#999999", "width", "100\%");
      htmlTableRow();
      htmlTableData();
      htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlTableDataClose();
      htmlTableRowClose();
    }
  }
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("colspan", ($colspan+1));
  if ($type ne "view") {
    htmlBR() if ($#selectedvhosts == 0);
    formInput("type", "submit", "name", "submit", "value", $buttontext);
    formInput("type", "reset", "value", $RESET_STRING) if ($type ne "remove");
    formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  }
  if (($type ne "add") && ($#selectedvhosts > 0)) {
    htmlP();
    if ((!$g_form{'sort_submit'}) || 
        ($g_form{'sort_submit'} ne $VHOSTS_SORT_BY_HOST)) {
      formInput("type", "submit", "name", "sort_submit", "value",
                $VHOSTS_SORT_BY_HOST);
    }
    if ((!$g_form{'sort_submit'}) || 
        ($g_form{'sort_submit'} ne $VHOSTS_SORT_BY_NAME)) {
      formInput("type", "submit", "name", "sort_submit", "value",
                $VHOSTS_SORT_BY_NAME);
    }
    if ((!$g_form{'sort_submit'}) || 
        ($g_form{'sort_submit'} ne $VHOSTS_SORT_BY_ROOT)) {
      formInput("type", "submit", "name", "sort_submit", "value",
                $VHOSTS_SORT_BY_ROOT);
    }
    if (($g_form{'sort_submit'}) && 
        ($g_form{'sort_submit'} ne $VHOSTS_SORT_BY_ORDER)) {
      formInput("type", "submit", "name", "sort_submit", "value",
                $VHOSTS_SORT_BY_ORDER);
    }
  }
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  formClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub vhostsEmptyFile
{
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlText($VHOSTS_NO_HOSTS_EXIST);
  htmlP();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub vhostsLoad
{
  require "$g_includelib/vhost_util.pl";
  vhostHashInit();
}

##############################################################################

sub vhostsNoChangesExist
{
  local($type) = @_;
  local($subtitle, $title);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("vhosts");

  if ($type eq "add") {
    $subtitle = "$IROOT_ADD_TEXT";
  }
  elsif ($type eq "edit") {
    $subtitle = "$IROOT_EDIT_TEXT";
  }

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_VHOSTS_TITLE: $subtitle";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTable("width", "550");
  htmlTableRow();
  htmlTableData();
  htmlText($VHOSTS_NO_CHANGES_FOUND);
  htmlP();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub vhostsSaveChanges
{
  local(@vhost_ids) = @_;
  local($vhost, $newentry, %entries, $match, $modtime);
  local($curentry, $curhostnames, $newentry, $servername);
  local($locked, $lastchar, $filename, $name, $value, $curhostport);
  local($idx, $maxidx, @lines, $curline, $indent, $prefix);

  foreach $vhost (@vhost_ids) {
    # sift through the vhost ids one by one
    if ($g_vhosts{$vhost}->{'new_hostnames'} eq "__REMOVE") {
      # this is a subtle expectation in the code that may be missed.  set
      # the new virtual value for a vhost to "__REMOVE" if you want to 
      # remove the vhost from the vhosts file.
      $entries{$vhost} = "__REMOVE";
      next;
    }
    $newentry = "";
    $maxidx = 1;
    if ($g_platform_type eq "dedicated") {
      if ($vhost =~ /^__NEWVHOST/) { 
        # new virtual host on a dedicated box
        $maxidx = 2;
      }
      else {
        $maxidx = $#{$g_vhosts{$vhost}->{'ip_bindings'}}+1;
      }
    }
    for ($idx=1; $idx<=$maxidx; $idx++) {
      if ($g_platform_type eq "dedicated") {
        if ($vhost =~ /^__NEWVHOST/) {
          if ($idx == 1) {
            $newentry .= "<VirtualHost $ENV{'SERVER_ADDR'}:80>\n";
            if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#) {
              $newentry .= "  SSLEngine off\n";
            }
            else {
              $newentry .= "  SSLDisable\n";
            }
          }
          else {
            $newentry .= "<VirtualHost $ENV{'SERVER_ADDR'}:443>\n";
            if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#) {
              $newentry .= "  SSLEngine on\n";
            }
            else {
              $newentry .= "  SSLEnable\n";
            }
          }
        }
        else {
          $newentry .= "<VirtualHost ";
          $newentry .= "$g_vhosts{$vhost}->{'ip_bindings'}[$idx-1]>\n";
          if ($g_vhosts{$vhost}->{'ip_bindings'}[$idx-1] =~ /443$/) {
            if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#) {
              $newentry .= "  SSLEngine on\n";
            }
            else {
              $newentry .= "  SSLEnable\n";
            }
          }
          else {
            if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#) {
              $newentry .= "  SSLEngine off\n";
            }
            else {
              $newentry .= "  SSLDisable\n";
            }
          }
        }
      }
      else {
        # not dedicated
        $newentry = "<VirtualHost $g_vhosts{$vhost}->{'new_hostnames'}>\n";
      }
      if ($g_vhosts{$vhost}->{'new_servername'}) {
        $newentry .= "  ServerName $g_vhosts{$vhost}->{'new_servername'}\n";
      }
      if ($g_vhosts{$vhost}->{'new_serveradmin'}) {
        $newentry .= "  ServerAdmin $g_vhosts{$vhost}->{'new_serveradmin'}\n";
      }
      if ($g_vhosts{$vhost}->{'new_documentroot'}) {
        $newentry .= "  DocumentRoot $g_vhosts{$vhost}->{'new_documentroot'}\n";
      }
      if ($g_vhosts{$vhost}->{'new_transferlog'}) {
        $newentry .= "  TransferLog $g_vhosts{$vhost}->{'new_transferlog'}\n";
      }
      if ($g_vhosts{$vhost}->{'new_errorlog'}) {
        $newentry .= "  ErrorLog $g_vhosts{$vhost}->{'new_errorlog'}\n";
      }
      if ($g_vhosts{$vhost}->{'new_scriptalias'}) {
        $newentry .= "  ScriptAlias $g_vhosts{$vhost}->{'new_scriptalias'}\n";
      }
      if ($g_vhosts{$vhost}->{'new_otheroptions'}) {
        #$newentry .= "$g_vhosts{$vhost}->{'new_otheroptions'}";
        @lines = split(/\n/, $g_vhosts{$vhost}->{'new_otheroptions'});      
        $index = 0;
        foreach $curline (@lines) {
          $curline =~ s/^\s+//g;
          $curline =~ s/\s+$//g;
          if ($curline =~ /^\<\//) {
            $indent--;
          }
          if ($indent > 0) {  # indent for Phil
            $newentry .= "  " x ($indent*2);
          }
          if (($directive =~ /^\</) && ($directive !~ /^\<\//)) {
            $indent++;
          }
          $newentry .= "  $curline\n"; 
        }
      }
      $newentry .= "</VirtualHost>";
      $newentry .= "\n" if ($idx < $maxidx);
    }
    $entries{$vhost} = $newentry;
  }

  $prefix = initPlatformApachePrefix();
  $filename = "$prefix/conf/httpd.conf";

  # add a newline character to the file if necessary
  open(OLDHTTPDFP, "$filename") ||
    irootResourceError($IROOT_VHOSTS_TITLE,
        "open(OLDHTTPDFP, '$filename') in vhostsSaveChanges");
  seek(OLDHTTPDFP, -1, 2);
  read(OLDHTTPDFP, $lastchar, 1);
  close(OLDHTTPDFP);
  if ($lastchar ne "\n") {
    open(OLDHTTPDFP, ">>$filename") ||
      irootResourceError($IROOT_VHOSTS_TITLE,
          "open(OLDHTTPDFP, '>>$filename') in vhostsSaveChanges");
    print OLDHTTPDFP "\n";
    close(OLDHTTPDFP);
  }

  # backup old file
  require "$g_includelib/backup.pl";
  backupSystemFile("$filename");

  # write out new vhosts file
  # first check for a lock file
  if (-f "/etc/htmptmp$$.$g_curtime") {
    irootResourceError($IROOT_VHOSTS_TITLE,
        "-f '/etc/htmptmp$$.$g_curtime' returned 1 in vhostsSaveChanges");
  }
  # no obvious lock... use link() for atomicity to avoid race conditions
  open(VTMP, ">/etc/htmptmp$$.$g_curtime") ||
    irootResourceError($IROOT_VHOSTS_TITLE,
        "open(VTMP, '>/etc/htmptmp$$.$g_curtime') in vhostsSaveChanges");
  close(VTMP);
  $locked = link("/etc/htmptmp$$.$g_curtime", "/etc/htmp");
  unlink("/etc/htmptmp$$.$g_curtime");
  $locked || irootResourceError($IROOT_VHOSTS_TITLE,
     "link('/etc/htmptmp$$.$g_curtime', '/etc/htmp') \
      failed in vhostsSaveChanges");
  open(NEWHTTPDFP, ">/etc/htmp")  ||
    irootResourceError($IROOT_VHOSTS_TITLE,
        "open(NEWHTTPDFP, '>/etc/htmp') in vhostsSaveChanges");
  flock(NEWHTTPDFP, 2);  # exclusive lock
  open(OLDHTTPDFP, "$filename");
  while (<OLDHTTPDFP>) {
    $myline = $curline = $_;
    $myline =~ s/^\s+//;
    $myline =~ s/\s+$//;
    $myline =~ s/\s+/ /g;
    if (($myline =~ /^<VirtualHost (.*)>/i) || ($myline =~ /^<Host (.*)>/i)) {
      # VirtualHost definition encountered in file; slurp it up
      $servername = "";
      $curhostnames = $1;
      $curentry = $curline;
      while (<OLDHTTPDFP>) {
        $myline = $curline = $_;
        $myline =~ s/^\s+//;
        $myline =~ s/\s+$//;
        $myline =~ s/\s+/ /g;
        $myline =~ /([A-Za-z]*) (.*)/;
        $name = $1;   $value = $2;
        $name =~ tr/A-Z/a-z/ if ($name);
        $servername = $value if ($name && ($name eq "servername"));
        $curentry .= $curline;
        if (($myline =~ /^<\/VirtualHost>/i) || ($myline =~ /^<\/Host>/i)) {
          $curhostnames =~ s/^\s+//;
          $curhostnames =~ s/\s+$//;
          $curhostnames =~ s/\s/ /;
          $curhostnames =~ s/\s+/ /;
          last;
        }
      }
      # is the virtual host ip based?
      $curhostport = ""; 
      if ($curhostnames =~ /[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\:([0-9]*)/) {
        $curhostport = $1;
        $curhostnames = $servername;
      }
      elsif ($curhostnames =~ /[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*/) {
        $curhostnames = $servername;
      }
      # check current vhost entry for match; then replace or ignore (remove)
      $match = 0;
      foreach $vhost (@vhost_ids) {
        if ($curhostnames eq $vhost) {
          $match = 1;
          # we have a match, replace or ignore?
          if ($entries{$vhost} eq "__REMOVE") {
            # ignore
            delete($entries{$vhost}) unless ($curhostport == 80);
            # need the unless in there so both the 80 and 443 entries are
            # removed ... by checking for curhostport == 80, we make sure
            # that hash value in entries is removed after the 443 instance
            # in the config file has been nuked
          }
          else {
            # replace
            print NEWHTTPDFP "$entries{$vhost}\n" ||
              irootResourceError($IROOT_VHOSTS_TITLE,
                "print to NEWHTTPDFP failed -- server quota exceeded?");
            vhostsCreateDirectories($entries{$vhost},
                                    $g_vhosts{$vhost}->{'user'});
            delete($entries{$vhost});
            # reset the hash value in entries if applicable (i.e. to  
            # account for the coupling of 80/443 virtual host pairs)
            if ($curhostport == 80) {
              $entries{$vhost} = "__REMOVE"; 
              # that should set the flag so that when the original 443 entry
              # that is immediately followed by the 80 entry will be nuked
            }
          }
        }
      }
      if ($match == 0) {
        print NEWHTTPDFP "$curentry" ||
          irootResourceError($IROOT_VHOSTS_TITLE,
            "print to NEWHTTPDFP failed -- server quota exceeded?");
      }
      # append any new vhosts after current entry if applicable
      foreach $vhost (@vhost_ids) {
        next unless ($vhost =~ /^__NEWVHOST/);
        if ($curhostnames eq $g_vhosts{$vhost}->{'placement'}) {
          print NEWHTTPDFP "\n$entries{$vhost}\n" ||
            irootResourceError($IROOT_VHOSTS_TITLE,
              "print to NEWHTTPDFP failed -- server quota exceeded?");
          vhostsCreateDirectories($entries{$vhost},
                                  $g_vhosts{$vhost}->{'user'});
          delete($entries{$vhost});
        }
      }
    }
    else {
      print NEWHTTPDFP "$curline" ||
        irootResourceError($IROOT_VHOSTS_TITLE,
          "print to NEWHTTPDFP failed -- server quota exceeded?");
    }
  } 
  close(OLDHTTPDFP);
  # append new entries
  foreach $entry (keys(%entries)) {
    next if ($entries{$entry} eq "__REMOVE");
    print NEWHTTPDFP "$entries{$entry}\n" ||
      irootResourceError($IROOT_VHOSTS_TITLE,
        "print to NEWHTTPDFP failed -- server quota exceeded?");
    vhostsCreateDirectories($entries{$entry}, $g_vhosts{$entry}->{'user'});
  } 
  flock(NEWHTTPDFP, 8);  # unlock
  close(NEWHTTPDFP);
  $modtime = (stat("$filename"))[9];
  utime($modtime, $modtime, "/etc/htmp");
  rename("/etc/htmp", "$filename") ||
     irootResourceError($IROOT_VHOSTS_TITLE, 
       "rename('/etc/htmp', '$filename') in vhostsSaveChanges");
  chmod(0664, "$filename");
  if ($g_platform_type eq "dedicated") {
    # change ownership to web admin
    chown($g_users{'webadmin'}->{'uid'}, 
          $g_users{'webadmin'}->{'gid'}, $filename);
  }
  
  # done... don't restart apache here, have the user do it manually
}

##############################################################################

sub vhostsSelectForm
{
  local($type) = @_;
  local($title, $subtitle, $vhost, $vcount, $optiontxt);
  local(@selectedvhosts, $svhost, $selected);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("vhosts");

  $subtitle = "$IROOT_VHOSTS_TITLE: ";
  if ($type eq "edit") {
    $subtitle .= "$IROOT_EDIT_TEXT: $VHOSTS_SELECT_TITLE";
  }
  elsif ($type eq "remove") {
    $subtitle .= "$IROOT_REMOVE_TEXT: $VHOSTS_SELECT_TITLE";
  }

  $title = "$IROOT_MAINMENU_TITLE: $subtitle";

  # first check and see if there are more than one vhost to select
  $vcount = 0;
  foreach $vhost (keys(%g_vhosts)) {
    $vcount++;
  }
  if ($vcount == 0) {
    # oops.  no vhost definitions in vhosts file.
    vhostsEmptyFile();
  }
  elsif ($vcount == 1) {
    $g_form{'vhosts'} = (keys(%g_vhosts))[0];
    return($g_form{'vhosts'});
  }

  @selectedvhosts = split(/\|\|\|/, $g_form{'vhosts'}) if ($g_form{'vhosts'});

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlTextLargeBold($subtitle);
  htmlBR();
  if ($g_form{'select_submit'} &&
      ($g_form{'select_submit'} eq $VHOSTS_SELECT_TITLE)) {
    htmlBR();
    htmlTextColorBold(">>> $VHOSTS_SELECT_HELP <<<", "#cc0000");
  }
  else {
    htmlText($VHOSTS_SELECT_HELP);
  }
  htmlP();
  formOpen("method", "POST");
  authPrintHiddenFields();
  htmlTable();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  formInput("type", "hidden", "name", "view", "value", $type);
  formSelect("name", "vhosts", "size", formSelectRows($vcount),
             "_OTHER_", "MULTIPLE", "_FONT_", "fixed");
  $g_form{'sort_submit'} = $g_form{'sort_select'};  # for sort subroutine
  foreach $vhost (sort vhostsByPreference(keys(%g_vhosts))) {
    $selected = 0;
    foreach $svhost (@selectedvhosts) {
      if ($svhost eq $vhost) {
        $selected = 1;
        last;
      }
    }
    $optiontxt = "$vhost"; 
    $optiontxt =~ s/\ /,\ /g;
    if (length($optiontxt) > 70) {
      $optiontxt = substr($optiontxt, 0, 70) . "&#133;";
    }
    formSelectOption($vhost, $optiontxt, $selected);
  }
  formSelectClose();
  htmlTableDataClose();
  htmlTableData("valign", "top");
  if ($g_form{'sort_select'} &&
      ($g_form{'sort_select'} eq $VHOSTS_SORT_BY_NAME)) {
    formInput("type", "submit", "name", "sort_select", "value",
              $VHOSTS_SORT_BY_ORDER);
  }
  else {
    formInput("type", "submit", "name", "sort_select", "value",
              $VHOSTS_SORT_BY_NAME);
  }
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("colspan", "2");
  formInput("type", "submit", "name", "select_submit",
            "value", $VHOSTS_SELECT_TITLE);
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  formClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub vhostsSelectUserForm
{
  local($ucount, $user, $title, $subtitle, $args);

  # first check and see if there any users to select
  $ucount = 0;
  foreach $user (keys(%g_users)) {
    next if ($user =~ /^_.*root$/);
    next if (($g_users{$user}->{'uid'} < 1000) ||
             ($g_users{$user}->{'uid'} > 65533));
    $ucount++;
  }

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("vhosts");

  $subtitle = "$IROOT_VHOSTS_TITLE: ";
  $subtitle .= "$IROOT_ADD_TEXT: $VHOSTS_USER_SELECT_TITLE";
  $title = "$IROOT_MAINMENU_TITLE: $subtitle";

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);

  htmlText($VHOSTS_USER_SELECT_HELP_1);
  if ($ucount) {
    htmlText("&#160;");
    htmlText($VHOSTS_USER_SELECT_HELP_2);
  }
  htmlP();
  htmlText($VHOSTS_USER_SELECT_HELP_3);
  unless (defined($g_users{'vhost'})) {
    $args = "users=__NEWUSER1&";
    $args .= "__NEWUSER1_login=vhost&";
    $args .= "__NEWUSER1_name=Vhost Admin&";
    $args .= "__NEWUSER1_path_option=standard&";
    $args .= "__NEWUSER1_shell=/bin/tcsh&";
    $args .= "__NEWUSER1_ftp=1&";
    $args .= "__NEWUSER1_configvhost=1&";
    $args .= "sort_submit=1";
    htmlText(" [&#160;");
    htmlAnchor("href", "users_add.cgi?$args", 
               "title", "$VHOSTS_USER_CREATE_VHOST_USER");
    htmlAnchorText($VHOSTS_USER_CREATE_VHOST_USER);
    htmlAnchorClose();
    htmlText("&#160;]");
  }
  htmlP();
  htmlText($VHOSTS_USER_SELECT_HELP_4);
  htmlP();

  htmlUL();
  if ($ucount) {
    if ($g_form{'select_submit'} eq $SUBMIT_STRING) {
      htmlTextColorBold(">>> $VHOSTS_USER_SELECT_ERROR <<<", "#cc0000");
      htmlBR();
    }
    formOpen("method", "POST");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "type", "value", $type);
    formSelect("name", "selecteduser", "size", formSelectRows($ucount));
    foreach $user (sort {$a cmp $b} (keys(%g_users))) {
      next if (($user eq "root") || ($user eq "__rootid") ||
               ($user eq $g_users{'__rootid'}));
      if ($g_platform_type eq "dedicated") {
        next if (($g_users{$user}->{'uid'} < 1000) ||
                 ($g_users{$user}->{'uid'} > 65533));
      }
      formSelectOption($user, "$user ($g_users{$user}->{'name'})");
    }
    formSelectClose();
    htmlBR();
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    formInput("type", "submit", "name", "select_submit",
              "value", $SUBMIT_STRING); 
    formInput("type", "reset", "value", $RESET_STRING);
    formInput("type", "submit", "name", "select_submit",
              "value", $CANCEL_STRING); 
    formClose();
  }
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "type", "value", $type);
  formInput("type", "hidden", "name", "selecteduser", "value", "www");
  formInput("type", "submit", "name", "select_submit",
            "value", $VHOSTS_USER_SELECT_NONE); 
  unless ($ucount) {
    formInput("type", "submit", "name", "select_submit",
              "value", $CANCEL_STRING); 
  }
  formClose();
  htmlULClose();
  htmlP();

  labelCustomFooter();
  exit(0);
}

##############################################################################

sub vhostsTemplateEditForm
{
  local($title, $size50, $key, $value, $otheroptions, $rows, $directive);

  encodingIncludeStringLibrary("iroot");
  encodingIncludeStringLibrary("vhosts");

  vhostsTemplateLoad($g_form{'template'});

  $size50 = formInputSize(50);

  $title = "$IROOT_MAINMENU_TITLE: $IROOT_VHOSTS_TITLE: ";
  if ($g_form{'template'} eq "user") {
    $title .= "$IROOT_VHOSTS_TEMPLATES_EDIT_USER";
  }
  else {
    $title .= "$IROOT_VHOSTS_TEMPLATES_EDIT_ADMIN";
  }

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlText($VHOSTS_TEMPLATE_EDIT_HELP_TEXT);
  htmlP();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "template", "value", $g_form{'template'});
  if ($g_form{'template'} eq "user") {
    htmlText($VHOSTS_TEMPLATE_EDIT_USER_TEMPLATE_HELP);
    htmlP();
    htmlTextBold($VHOSTS_TEMPLATE_EDIT_USER_TEMPLATE_TITLE);
  }
  else {
    htmlText($VHOSTS_TEMPLATE_EDIT_ADMIN_TEMPLATE_HELP);
    htmlP();
    htmlTextBold($VHOSTS_TEMPLATE_EDIT_ADMIN_TEMPLATE_TITLE);
  }
  htmlTable();
  # <VirtualHost> row
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "bottom", "colspan", "3");
  htmlTextBold("<VirtualHost>");
  htmlTableDataClose();
  htmlTableRowClose();
  # directive row 1: host names(s)
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  htmlText("&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left");
  htmlTextBold("$VHOSTS_HOSTNAMES:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $key = "template_hostnames";
  $value = $g_form{$key} || $g_vhost_template{'hostnames'};
  formInput("name", $key, "size", $size50, "value", $value);
  htmlTableDataClose();
  htmlTableRowClose();
  # directive row 2: ServerName
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  htmlText("&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left");
  htmlTextBold("$VHOSTS_SERVERNAME:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $key = "template_servername";
  $value = $g_form{$key} || $g_vhost_template{'servername'};
  formInput("name", $key, "size", $size50, "value", $value);
  htmlTableDataClose();
  htmlTableRowClose();
  # directive row 3: ServerAdmin
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  htmlText("&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left");
  htmlTextBold("$VHOSTS_SERVERADMIN:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $key = "template_serveradmin";
  $value = $g_form{$key} || $g_vhost_template{'serveradmin'};
  formInput("name", $key, "size", $size50, "value", $value);
  htmlTableDataClose();
  htmlTableRowClose();
  # directive row 4: DocumentRoot
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  htmlText("&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left");
  htmlTextBold("$VHOSTS_DOCUMENTROOT:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $key = "template_documentroot";
  $value = $g_form{$key} || $g_vhost_template{'documentroot'};
  formInput("name", $key, "size", $size50, "value", $value);
  htmlTableDataClose();
  htmlTableRowClose();
  # directive row 5: ScriptAlias
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  htmlText("&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left");
  htmlTextBold("$VHOSTS_SCRIPTALIAS:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $key = "template_scriptalias";
  $value = $g_form{$key} || $g_vhost_template{'scriptalias'};
  formInput("name", $key, "size", $size50, "value", $value);
  htmlTableDataClose();
  htmlTableRowClose();
  # directive row 6: TransferLog
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  htmlText("&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left");
  htmlTextBold("$VHOSTS_TRANSFERLOG:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $key = "template_transferlog";
  $value = $g_form{$key} || $g_vhost_template{'transferlog'};
  formInput("name", $key, "size", $size50, "value", $value);
  htmlTableDataClose();
  htmlTableRowClose();
  # directive row 7: ErrorLog
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  htmlText("&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left");
  htmlTextBold("$VHOSTS_ERRORLOG:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $key = "template_errorlog";
  $value = $g_form{$key} || $g_vhost_template{'errorlog'};
  formInput("name", $key, "size", $size50, "value", $value);
  htmlTableDataClose();
  htmlTableRowClose();
  # directive row 8: other options
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  htmlText("&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("colspan", "2");
  htmlTextBold("$VHOSTS_OTHEROPTIONS:");
  htmlBR();
  $key = "template_otheroptions";
  $otheroptions = $g_form{$key};
  if ($otheroptions) {
    foreach $directive (@{$g_vhost_template{'directives'}}) {
      next if (($directive =~ /^servername\s/i) ||
               ($directive =~ /^serveradmin\s/i) ||
               ($directive =~ /^documentroot\s/i) ||
               ($directive =~ /^transferlog\s/i) ||
               ($directive =~ /^errorlog\s/i) ||
               ($directive =~ /^scriptalias\s/i));
      $otheroptions .= "$directive\n";
    }
  }
  $rows = formTextAreaRows($otheroptions, 5, 12);
  formTextArea($otheroptions, "name", $key, "rows", $rows+1,
               "cols", 65, "_FONT_", "fixed", "wrap", "off");
  htmlTableDataClose();
  htmlTableRowClose();
  # </VirtualHost> row
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "bottom", "colspan", "3");
  htmlTextBold("</VirtualHost>");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  # submit, cancel, reset buttons
  formInput("type", "submit", "name", "submit", "value", 
            $VHOSTS_TEMPLATE_SUBMIT_TEXT);
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  formClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub vhostsTemplateLoad
{
  local($type) = @_;
  local($filename, $insidetags, $curhostnames);
  local(@curhostdirectives, $directive, $name, $value);

  # only one template can be in memory at a time (at least for now)
  %g_vhost_template = ();

  # try and load previously saved vhost templates
  $filename = "$g_prefslib/_vhost_template." . $g_platform_type . "_" . $type;
  $filename .= "_apache2" if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#);
  unless (-e "$filename") {
    # default vhost templates
    $filename = "$g_prefslib/_default_vhost_template.";
    $filename .=  $g_platform_type . "_" . $type;
    $filename .= "_apache2" if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#);
  }
  return unless (-e "$filename");

  open(TFP, "$filename");
  while (<TFP>) {
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
      $insidetags = 0;
      $curhostnames =~ s/^\s+//;
      $curhostnames =~ s/\s+$//;
      $curhostnames =~ s/\s/ /;
      $curhostnames =~ s/\s+/ /;
      # loop through the directives
      foreach $directive (@curhostdirectives) {
        push(@{$g_vhost_template{'directives'}}, $directive);
        next if ($directive =~ /^\</);
        $directive =~ /([A-Za-z]*) (.*)/;
        $name = $1;   $value = $2;
        $name =~ tr/A-Z/a-z/;
        $g_vhost_template{$name} = $value;
      }
      $g_vhost_template{'hostnames'} = $curhostnames;
      last;
    }
    elsif ($insidetags) {
      push(@curhostdirectives, $_);
    }
  }
  close(TFP);
}

##############################################################################

sub vhostsTemplateSave
{
  local($filename, $directive, @oolines);

  encodingIncludeStringLibrary("vhosts");

  if ($g_form{'submit'} eq "$CANCEL_STRING") {
    redirectLocation("iroot.cgi", $VHOSTS_TEMPLATE_EDIT_CANCEL_TEXT);
  } 

  # get template filename based on platform and template type
  $filename = "$g_prefslib/_vhost_template.";
  $filename .= $g_platform_type . "_" . $g_form{'template'};
  $filename .= "_apache2" if ($ENV{'SERVER_SOFTWARE'} =~ m#^Apache/2#);

  # save template
  open(TFP, ">$filename");
  $g_form{'template_hostnames'} =~ s/\s/ /g; 
  $g_form{'template_hostnames'} =~ s/\s+/ /g;
  print TFP "<VirtualHost $g_form{'template_hostnames'}>\n";
  print TFP "ServerName $g_form{'template_servername'}\n";
  if ($g_form{'template_serveradmin'}) {
    print TFP "ServerAdmin $g_form{'template_serveradmin'}\n";
  }
  if ($g_form{'template_documentroot'}) {
    $g_form{'template_documentroot'} =~ s/\/+$//g;
    print TFP "DocumentRoot $g_form{'template_documentroot'}\n";
  }
  if ($g_form{'template_scriptalias'}) {
    print TFP "ScriptAlias $g_form{'template_scriptalias'}\n";
  }
  if ($g_form{'template_transferlog'}) {
    print TFP "TransferLog $g_form{'template_transferlog'}\n";
  }
  if ($g_form{'template_errorlog'}) {
    print TFP "ErrorLog $g_form{'template_errorlog'}\n";
  }
  if ($g_form{'template_otheroptions'}) {
    $g_form{'template_otheroptions'} =~ s/\r\n/\n/g;
    $g_form{'template_otheroptions'} =~ s/\r//g;
    $g_form{'template_otheroptions'} =~ s/\s+$//g;
    $g_form{'template_otheroptions'} .= "\n";
    @oolines = split(/\n/, $g_form{'template_otheroptions'});
    foreach $directive (@oolines) {
      print TFP "$directive\n";
    }
  }
  print TFP "</VirtualHost>\n";
  close(TFP);

  # redirect back to the iroot main menu
  redirectLocation("iroot.cgi", $VHOSTS_TEMPLATE_STORE_SUCCESS_TEXT);
}

##############################################################################
# eof
  
1;

