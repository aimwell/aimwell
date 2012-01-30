#
# mm_browse.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/mm_browse.pl,v 2.12.2.15 2006/05/18 23:41:38 rus Exp $
#
# mail manager browse functions
#

##############################################################################

sub mailmanagerHandleActionOnSelectedRequest
{
  encodingIncludeStringLibrary("mailmanager");

  unless ($g_form{'selected'}) {
    # uh... damnit beavis
    mailmanagerShowMailbox($MAILMANAGER_NONE_SELECTED);
  }

  if (($g_form{'submit'} eq $MAILMANAGER_DELETE_TAGGED) ||
      ($g_form{'submit'} eq $MAILMANAGER_DELETE_SINGLE)) {
    require "$g_includelib/mm_delete.pl";
    mailmanagerHandleDeleteMessageRequest();
  }
  elsif (($g_form{'submit'} eq $MAILMANAGER_SAVE_TAGGED) ||
         ($g_form{'submit'} eq $MAILMANAGER_SAVE_SINGLE)) {
    require "$g_includelib/mm_save.pl";
    mailmanagerHandleSaveMessageRequest();
  }
  else {
    # uh... what?
    mailmanagerShowMailbox();
  }
}

##############################################################################

sub mailmanagerIsTmpMessage
{
  return($g_form{'mbox'} =~ m#/tmp/.message_[^/]*#);
}

##############################################################################

sub mailmanagerIsUnread
{
  local($mid) = @_;
  local($status, $xstatus, $unread);

  return(0) unless ($mid);
  $status = $xstatus = "";
  $status = $g_email{$mid}->{'status'} if ($g_email{$mid}->{'status'});
  $xstatus = $g_email{$mid}->{'x-status'} if ($g_email{$mid}->{'xstatus'});
  $unread = (($status eq "") || (($status eq "O") && ($xstatus eq ""))) ? 1 : 0;
  return($unread);
}

##############################################################################

sub mailmanagerLineWrap
{
  # untested code, uncomment at your own risk

  #local($curline, $eol) = @_;
  #local($newlines, $space);
  #
  # wrap lines longer than 80 characters?  let the browser wrap text
  #
  #$newlines = "";
  #while (length($curline) > 80) {
  #  $space = rindex($curline, " ", 79);
  #  last if ($space < 0);  # no space found left of 80th character!
  #  $newlines .= substr($curline, 0, $space);
  #  $newlines .= "$eol\n";
  #  $curline = "+" . substr($curline, $space);
  #}
  #$newlines .= $curline;
  #return($newlines);
}

##############################################################################

sub mailmanagerMessageHeaderMarkup
{
  local($headername, $headerdef) = @_;
  local($adef, $numaddresses, $cstr, $abstr, $abdir, $file, $stxt);
  local(@parts, $part, $prevpart, $email, $rawabc, $rawabg, $abcount);
  local($title, $grouplist, $encargs);

  # headername is one of "to", "reply-to", "from", or "cc"

  $MAILMANAGER_ADDRESSBOOK_ADD_GROUP =~ s/\ /\&\#160\;/g;

  # count up the addreses
  $adef = $headerdef;
  $adef =~ s/\".*?\"//g;
  $numaddresses = $adef =~ tr/\@/\@/;

  # curline may contain `&gt;', `&lt;', or '&quot;' patterns.  buffer these
  # with some innocuous characters like `|||', this fixes a bug where the
  # regex would match an addy enclosed by '<', '>', or '"' and be too greedy
  $headerdef =~ s/\&(g|l|quo)t;/\|\|\|\&$1t;\|\|\|/g;

  if (($headername ne "to") || ($numaddresses > 1)) {
    # remove any duplicitous address occurrences
    $headerdef =~ s/\s+?\([\w.\-]+?@[\w.-]+?\)//g; 
    # markup e-mail addresses with compose links
    $encargs = htmlAnchorArgs("mbox", encodingStringToURL($g_form{'mbox'}), "mpos", $g_form{'mpos'}, 
                              "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'});
    $encargs .= "&send_to=";
    $cstr = "mm_compose.cgi?$encargs";
    $headerdef =~ s{\b([\w.\-\&]+?@[\w.-]+?)(?=[.-]*(?:[^\w.-]|$))}
                   {<i><a target="linkWin" href="$cstr$1" title="$MAILMANAGER_COMPOSE: $1">$1</a></i>}igx;
    # look for addresses in the header that are not in the user's address 
    # book; insert a small add address book contact graphic (and link) 
    # immediately following the address
    $encargs = htmlAnchorArgs("mbox", encodingStringToURL($g_form{'mbox'}), "mpos", $g_form{'mpos'}, 
                              "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'},
                              "messageid", encodingStringToURL($g_form{'messageid'}));
    $encargs .= "&action=add&raw_abc=";
    $abstr = "mm_addressbook.cgi?$encargs";
    $abdir = mailmanagerGetDirectoryPath("addressbook");
    @parts = split(/\,/, $headerdef);
    $abcount = 0;
    $headerdef = $prevpart = $rawabg = "";
    foreach $part (@parts) {
      $part =~ s/\s+$//;
      next unless ($part);
      if ($part =~ m{">(.*?)</a></i>([^,]+?)?$}) {
        $email = $1;
        $grouplist .= "$email, ";
        $file = $abdir . "/A_" . $email;
        $part = $prevpart . $part if ($prevpart);
        $rawabc = $part; 
        $rawabc =~ s{<i><a target="linkWin" href=".*?">}{}ig;
        $rawabc =~ s{</a></i>}{}ig;
        $rawabc =~ s{</a></i>}{}ig;
        unless (-e "$file") {
          $title = $MAILMANAGER_ADDRESSBOOK_ADD_SINGLE;
          $title =~ s/__EMAIL__/$email/;
          $stxt = $rawabc;
          $stxt =~ s/([^\|])\&/$1\%26/g;  # escape ampersands
          $part .= "&#160;<a href=\"$abstr$stxt\" ";
          $part .= "title=\"$title\"><img border=\"0\" ";
          $part .= "width=\"14\" height=\"14\" ";
          $part .= "src=\"$g_graphicslib/mm_abas.jpg\"></a>";
        }
        $rawabg .= "$rawabc,,,";
        $abcount++;
        $headerdef .= "$part,";
        $prevpart = "";
      }
      else {
        $prevpart .= "$part,";
      }
    }
    $headerdef .= $prevpart if ($prevpart);
    chop($headerdef);
    # append the add group address book contact link and graphic
    if ($abcount > 1) {
      $rawabg =~ s/\,+$//;
      $stxt = $rawabg;
      $stxt =~ s/([^\|])\&/$1\%26/g;  # escape ampersands
      $grouplist =~ s/\s+$//;
      $grouplist =~ s/\,$//;
      $title = $MAILMANAGER_ADDRESSBOOK_ADD_GROUP_HELP;
      $title =~ s/__EMAIL__/$grouplist/;
      $headerdef .= " ($MAILMANAGER_ADDRESSBOOK_ADD_GROUP&#160;";
      $headerdef .= "<a href=\"$abstr$stxt\" ";
      $headerdef .= "title=\"$title\"><img border=\"0\" ";
      $headerdef .= "width=\"17\" height=\"14\" ";
      $headerdef .= "src=\"$g_graphicslib/mm_abal.jpg\"></a>";
      $headerdef .= ")";
    }
  }

  # reverse the buffer of &gt;, &lt;, &quot; character patterns (see above)
  $headerdef =~ s/\|\|\|\&(g|l|quo)t;\|\|\|/\&$1t;/g;

  return($headerdef);
}

##############################################################################

sub mailmanagerMessageLineMarkup
{
  local($curline) = @_;
  local($string, $encargs);

  # curline may contain `&gt;', `&lt;', or '&quot;' patterns.  buffer these
  # with some innocuous characters like `|||', this fixes a bug where the
  # regex would match a url enclosed by '<', '>', or '"' and be too greedy
  $curline =~ s/\&(g|l|quo)t;/\|\|\|\&$1t;\|\|\|/g;
  # the infamous url regex... provided courtesy Dan Brian
  unless ($curline =~ s{\b(([a-z]*tp)(s)?:[\w/#~:.?+=&%$@!\-]+?)
                        (?=[.:?\-]*(?:[^\w/#~:.?+=&%$@!\-]|$))}
                       {<a target="linkWin" href="$1" title=\"$MAILMANAGER_OPEN_URL: $1\">$1</a>}igx) {
    if ($curline !~ /^Message-Id:/i) {
      # and the derived email regex... 
      $encargs = htmlAnchorArgs("mbox", encodingStringToURL($g_form{'mbox'}), "mpos", $g_form{'mpos'},
                                "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'});
      $encargs .= "&send_to=";
      $string = "mm_compose.cgi?$encargs";
      $curline =~ s{\b([\w.\-\&]+?@[\w.?+=\-]+?)(?=[.?+=\-]*(?:[^\w.?+=\-]|$))}
                   {<i><a target="linkWin" href="$string$1" title="$MAILMANAGER_COMPOSE: $1">$1</a></i>}igx;    

    }
  }
  # reverse the buffer of &gt;, &lt;, &quot; character patterns (see above)
  $curline =~ s/\|\|\|\&(g|l|quo)t;\|\|\|/\&$1t;/g;

  return($curline);
}

##############################################################################

sub mailmanagerShowMailbox
{
  local($mesg) = @_;
  local($msgcount, $mbox_exists);
  local($mid, $prevmessageid, $string, $encpath, $timestring);
  local($fsize, $sizetext, $boxsize, $count, $title, $homedir);
  local($fuser, $fhost, $from_self, $hostname, $subject, $num);
  local($naddr, $namp, $url, $mpos, $mpos2, $languagepref);
  local(@addresses, $useraddress, $mflag, @msglines);
  local($ar_enabled, $args, $javascript, $css);
  local($curmpos, $lastmpos, $lastmid);

  if ($ENV{'SCRIPT_NAME'} !~ /wizards\/mailmanager.cgi/) {
    $ENV{'SCRIPT_NAME'} =~ /wizards\/([a-z_]*).cgi$/;
    $ENV{'SCRIPT_NAME'} =~ s/$1/mailmanager/;
  }

  encodingIncludeStringLibrary("mailmanager");

  if ($g_form{'mbox'} &&
      (($g_form{'mbox'} eq authDecode64("cnVuIG1pbmVzd2VlcGVy")) ||
       ($g_form{'mbox'} eq authDecode64("cGxheSBtaW5lc3dlZXBlcg")))) {
    require "$g_includelib/lang/ee/ms.pl";
    eastereggMineSweepRun();
    exit(0);
  }

  if ($g_form{'sort_submit'}) {
    if (($g_form{'sort_submit'} eq "by_date") ||
        ($g_form{'sort_submit'} eq $MAILMANAGER_SORT_BY_DATE)) {
      $g_form{'msort'} = "by_date";
    } 
    elsif (($g_form{'sort_submit'} eq "by_sender") ||
           ($g_form{'sort_submit'} eq $MAILMANAGER_SORT_BY_SENDER)) {
      $g_form{'msort'} = "by_sender";
    }
    elsif (($g_form{'sort_submit'} eq "by_subject") ||
           ($g_form{'sort_submit'} eq $MAILMANAGER_SORT_BY_SUBJECT)) {
      $g_form{'msort'} = "by_subject"; 
    }
    elsif (($g_form{'sort_submit'} eq "by_size") ||
           ($g_form{'sort_submit'} eq $MAILMANAGER_SORT_BY_SIZE)) {
      $g_form{'msort'} = "by_size"; 
    }
    elsif (($g_form{'sort_submit'} eq "by_thread") ||
           ($g_form{'sort_submit'} eq $MAILMANAGER_SORT_BY_THREAD)) {
      $g_form{'msort'} = "by_thread"; 
    }
    elsif (($g_form{'sort_submit'} eq "in_order") ||
           ($g_form{'sort_submit'} eq $MAILMANAGER_SORT_IN_ORDER)) {
      $g_form{'msort'} = "in_order"; 
    }
    # reset mpos to "" if changing sort preference
    $g_form{'mpos'} = "";
  }

  ($msgcount, $mbox_exists) = (mailmanagerReadMail())[1,3];

  # determine last valid mail position
  $lastmpos = sprintf "%d", (($msgcount-1) / $g_form{'mrange'});
  $lastmpos *= $g_form{'mrange'};
  $lastmpos += 1;

  # set current mail position
  unless ($g_form{'mpos'}) {
    $curmpos = (($g_form{'msort'} eq "by_thread") ||
                ($g_form{'msort'} eq "in_order")) ? $lastmpos : 1;
  }
  elsif ($g_form{'mpos'} > $msgcount) {
    $curmpos = $lastmpos;
    $g_form{'mpos'} = (($g_form{'msort'} eq "by_thread") ||
                       ($g_form{'msort'} eq "in_order")) ? "" : $curmpos;
  }
  else {
    $curmpos = $g_form{'mpos'};
  }

  # set up some boolean status flags
  $ar_enabled = mailmanagerNemetonAutoreplyGetStatus();

  $MAILMANAGER_TITLE =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;

  $javascript = javascriptOpenWindow();
  $javascript .= javascriptTagUntagAll();
  $javascript .= javascriptHighlightUnhighlightRow();

  $languagepref = encodingGetLanguagePreference();

  htmlResponseHeader("Content-type: $g_default_content_type");
  
  # encoded path
  $encpath = encodingStringToURL($g_form{'mbox'});

  # refresh rate
  if (defined($g_form{'refresh_rate'})) {
    $g_prefs{'mail__inbox_refresh_rate'} = $g_form{'refresh_rate'};
  }
  if ((!defined($g_prefs{'mail__inbox_refresh_rate'})) || 
      (($g_prefs{'mail__inbox_refresh_rate'} != 0) &&
       ($g_prefs{'mail__inbox_refresh_rate'} < 15))) {
    $g_prefs{'mail__inbox_refresh_rate'} = 15;
  }
  if (defined($g_form{'refresh_rate'})) {
    # save the new preference
    require "$g_includelib/prefs.pl";
    prefsSave();
  }
  if ((!$g_form{'mbox'}) && ($g_prefs{'mail__inbox_refresh_rate'} > 0)) {
    #$args = "mbox=$encpath&mpos=$g_form{'mpos'}";
    #$args .= "&mrange=$g_form{'mrange'}&msort=$g_form{'msort'}&epoch=$g_curtime";
    #$url = "mailmanager.cgi?$args";
    #print "<meta http-equiv=Refresh ";
    #print "content=\"$g_prefs{'mail__inbox_refresh_rate'}; url=$url\">\n";
    $javascript .= "<script language=\"javascript\">
var reloadtime = $g_prefs{'mail__inbox_refresh_rate'};
var reloadticks = reloadtime * 1000;

function refresh_page() {
  if (reloadtime > 0 ) {
    setTimeout(\"location.reload()\", reloadticks);
  }
}
</script>\n"
  }

  $css = "<style type=\"text/css\">
.highlighted { background:#bbbbbb }
.unhighlighted { background:#ffffff }
.unreadhighlighted { background:#bbbbdd }
.unreadunhighlighted { background:#ddddee }
</style>";

  if ((!$g_form{'mbox'}) && ($g_prefs{'mail__inbox_refresh_rate'} > 0)) {
    labelCustomHeader($MAILMANAGER_TITLE, "", $javascript, $css,
                      "onload=\"refresh_page()\"");
  }
  else {
    labelCustomHeader($MAILMANAGER_TITLE, "", $javascript, $css);
  }

  if (!$mesg && $g_form{'msgfileid'}) {
    # read message from temporary state message file
    $mesg = redirectMessageRead($g_form{'msgfileid'});
  }
  if ($mesg) {
    @msglines = split(/\n/, $mesg);
    foreach $mesg (@msglines) {
      htmlTextColorBold(">>> $mesg <<<", "#cc0000");
      htmlBR();
    }
    htmlBR();
  }

  if (-e "$g_mailbox_fullpath") {
    ($fsize) = (stat($g_mailbox_fullpath))[7];
    if ($fsize < 1024) {
      $boxsize = sprintf("%s $BYTES", $fsize);
    }
    elsif ($fsize < 1048576) {
      $boxsize = sprintf("%1.1f $KILOBYTES", ($fsize / 1024));
    }
    else {
      $boxsize = sprintf("%1.2f $MEGABYTES", ($fsize / 1048576));
    }
  }
  else {
    $boxsize = "0 $BYTES";
  }

  if ($msgcount > 0) {
    # get a list of localhostnames for use later (see below)
    mailmanagerGetLocalHostnames();
  }

  #
  # mailbox table (2 cells: sidebar, contents)
  #
  htmlTable("border", "0", "cellspacing", "0",
            "cellpadding", "0", "bgcolor", "#000000");
  htmlTableRow();
  htmlTableData();
  htmlTable("border", "0", "cellspacing", "1", "cellpadding", "0");
  htmlTableRow();
  htmlTableData("bgcolor", "#999999", "valign", "top");
  #
  # begin sidebar table cell
  #
  mailmanagerShowMailSidebar(); 
  #
  # end sidebar table cell
  #
  htmlTableDataClose();
  htmlTableData("bgcolor", "#ffffff", "valign", "top");
  #
  # begin contents table cell
  #
  htmlTable("cellpadding", "2", "cellspacing", "0",
            "border", "0", "width", "100\%", "bgcolor", "#9999cc");
  htmlTableRow();
  htmlTableData("align", "left", "valign", "middle");
  htmlTextBold("&#160;$MAILMANAGER_FOLDER_CONTENTS - $g_mailbox_virtualpath");
  htmlTableDataClose();
  htmlTableData("align", "right", "valign", "middle");
  htmlNoBR();
  $timestring = dateBuildTimeString("alpha");
  $timestring = dateLocalizeTimeString($timestring);
  $MAILMANAGER_FOLDER_CONTENTS_STATUS =~ s/__TIME__/$timestring/;
  htmlTextSmallBold("$MAILMANAGER_FOLDER_CONTENTS_STATUS&#160;");
  unless ($g_form{'mbox'}) {
    formOpen("method", "POST", "style", "display:inline; font-size:1px");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
    formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
    #htmlTextSmall("&#160;&#160;(");
    #htmlTextSmall("$MAILMANAGER_REFRESH_TEXT:&#160;");
    #formInput("size", "3", "name", "refresh_rate", 
    #          "value", "$g_prefs{'mail__inbox_refresh_rate'}",
    #          "style", "display:inline; line-height:14px; width:30px; font-size: 10px; font-family: Verdana, Arial, Helvetica; padding:0px;");
    #htmlTextSmall("&#160;$MAILMANAGER_REFRESH_UNITS)&#160;");
    print <<ENDTEXT;
<script language="JavaScript1.1">
  document.write("<font style=\\\"font-family:arial, helvetica; font-size:10px\\\" face=\\\"arial, helvetica\\\" class=\\\"boldtext\\\" size=\\\"1\\\" color=\\\"#000000\\\">");
  document.write("&#160;&#160;($MAILMANAGER_REFRESH_TEXT:&#160;");
  document.write("<input size=\\\"3\\\" name=\\\"refresh_rate\\\" ");
  document.write("style=\\\"display:inline; line-height:14px; width:30px; font-size: 10px; font-family: Verdana, Arial, Helvetica; padding:0px\\\" ");
  document.write("value=\\\"$g_prefs{'mail__inbox_refresh_rate'}\\\">");
  document.write("&#160;$MAILMANAGER_REFRESH_UNITS)&#160;");
  document.write("</font>");
</script>
ENDTEXT
    formClose();
  }
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
            "cellpadding", "0", "bgcolor", "#666666");
  htmlTableRow();
  htmlTableData("bgcolor", "#666666");
  htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  # button bar
  htmlImg("width", "3", "height", "50", "src", "$g_graphicslib/sp.gif");
  unless ($g_form{'mbox'}) {
    $args = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                           "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'},
                           "epoch", $g_curtime);
    htmlAnchor("href", "mailmanager.cgi?$args",
               "title", $MAILMANAGER_CHECK_MAIL,
               "onClick", "document.location.reload(); return false",
               "onMouseOver", "status='$MAILMANAGER_CHECK_MAIL'; return true",
               "onMouseOut", "status=''; return true");
    htmlImg("border", "0", "width", "50", "height", "50", 
            "alt", "$MAILMANAGER_CHECK_MAIL",
            "src", "$g_graphicslib/mm_chk.jpg");
    htmlAnchorClose();
    htmlImg("width", "15", "height", "1", "src", "$g_graphicslib/sp.gif");
  }
  $args = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'}, 
                         "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'});
  htmlAnchor("href", "mm_compose.cgi?$args",
             "title", $MAILMANAGER_COMPOSE,
             "onMouseOver", "status='$MAILMANAGER_COMPOSE'; return true",
             "onMouseOut", "status=''; return true");
  htmlImg("border", "0", "width", "50", "height", "50", "alt",
          "$MAILMANAGER_COMPOSE", "src", "$g_graphicslib/mm_new.jpg");
  htmlAnchorClose();
  htmlImg("width", "15", "height", "1", "src", "$g_graphicslib/sp.gif");
  if ($msgcount > 1) {
    if ((($g_users{$g_auth{'login'}}->{'ftp'}) ||
         ($g_users{$g_auth{'login'}}->{'imap'})) &&
        ($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full")) {
      $args = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'}, 
                             "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'},
                             "selected", "__ALL__", "rfs", "yes");
      htmlAnchor("href", "mm_save.cgi?$args",
                 "title", $MAILMANAGER_SAVE_ALL,
                 "onMouseOver", 
                 "status='$MAILMANAGER_SAVE_ALL'; return true",
                 "onMouseOut", "status=''; return true");
      htmlImg("border", "0", "width", "50", "height", "50", "alt",
              "$MAILMANAGER_SAVE_ALL", "src", "$g_graphicslib/mm_sa.jpg");
      htmlAnchorClose();
    }
    $args = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'}, 
                           "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'},
                           "selected", "__ALL__");
    htmlAnchor("href", "mm_delete.cgi?$args",
               "title", $MAILMANAGER_DELETE_ALL,
               "onMouseOver", 
               "status='$MAILMANAGER_DELETE_ALL'; return true",
               "onMouseOut", "status=''; return true");
    htmlImg("border", "0", "width", "50", "height", "50", "alt",
            "$MAILMANAGER_DELETE_ALL", "src", "$g_graphicslib/mm_da.jpg");
    htmlAnchorClose();
    htmlImg("width", "15", "height", "1", "src", "$g_graphicslib/sp.gif");
  }
  if ((($g_users{$g_auth{'login'}}->{'ftp'}) ||
       ($g_users{$g_auth{'login'}}->{'imap'})) &&
      ($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full")) {
    $args = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'}, 
                           "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'});
    htmlAnchor("href", "mm_select.cgi?$args",
               "title", $MAILMANAGER_SELECT_MAILBOX,
               "onMouseOver", 
               "status='$MAILMANAGER_SELECT_MAILBOX'; return true",
               "onMouseOut", "status=''; return true");
    htmlImg("border", "0", "width", "50", "height", "50", "alt",
            "$MAILMANAGER_SELECT_MAILBOX", "src", "$g_graphicslib/mm_c.jpg");
    htmlAnchorClose();
    htmlImg("width", "15", "height", "1", "src", "$g_graphicslib/sp.gif");
  }
  if ($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full") {
    $args = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'}, 
                           "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'});
    htmlAnchor("href", "mm_addressbook.cgi?$args",
               "title", $MAILMANAGER_ADDRESSBOOK_VIEW,
               "onMouseOver", 
               "status='$MAILMANAGER_ADDRESSBOOK_VIEW'; return true",
               "onMouseOut", "status=''; return true");
    htmlImg("border", "0", "width", "50", "height", "50", "alt",
            "$MAILMANAGER_ADDRESSBOOK_VIEW", 
            "src", "$g_graphicslib/mm_ab.jpg");
    htmlAnchorClose();
    htmlAnchor("href", "mm_filters.cgi?$args",
               "title", $MAILMANAGER_FILTERS_EDIT,
               "onMouseOver", 
               "status='$MAILMANAGER_FILTERS_EDIT'; return true",
               "onMouseOut", "status=''; return true");
    htmlImg("border", "0", "width", "50", "height", "50", "alt",
            "$MAILMANAGER_FILTERS_EDIT", "src", "$g_graphicslib/mm_sf.jpg");
    htmlAnchorClose();
    if ($ar_enabled) {
      htmlAnchor("href", "mm_autoresponder.cgi?$args",
                 "title", "$MAILMANAGER_AUTOREPLY_STATUS_ON: $MAILMANAGER_AUTOREPLY_EDIT_SETTINGS\...",
                 "onMouseOver", 
                 "status='$MAILMANAGER_AUTOREPLY_STATUS_ON: $MAILMANAGER_AUTOREPLY_EDIT_SETTINGS...'; return true",
                 "onMouseOut", "status=''; return true");
      htmlImg("border", "0", "width", "50", "height", "50", 
              "alt", "$MAILMANAGER_AUTOREPLY_STATUS_ON: $MAILMANAGER_AUTORE
PLY_EDIT_SETTINGS\...", 
              "src", "$g_graphicslib/mm_are.jpg");
      htmlAnchorClose();
    }
    else {
      htmlAnchor("href", "mm_autoresponder.cgi?$args",
                 "title", "$MAILMANAGER_AUTOREPLY_STATUS_OFF: $MAILMANAGER_AUTOREPLY_EDIT_SETTINGS_SHORT\...",
                 "onMouseOver", 
                 "status='$MAILMANAGER_AUTOREPLY_STATUS_OFF: $MAILMANAGER_AUTOREPLY_EDIT_SETTINGS...'; return true",
                 "onMouseOut", "status=''; return true");
      htmlImg("border", "0", "width", "50", "height", "50", 
              "alt", "$MAILMANAGER_AUTOREPLY_STATUS_OFF: $MAILMANAGER_AUTOREPLY_EDIT_SETTINGS\...", 
              "src", "$g_graphicslib/mm_ard.jpg");
      htmlAnchorClose();
    }
    htmlAnchor("href", "mm_signature.cgi?$args",
               "title", $MAILMANAGER_SIGNATURE_EDIT,
               "onMouseOver", 
               "status='$MAILMANAGER_SIGNATURE_EDIT'; return true",
               "onMouseOut", "status=''; return true");
    htmlImg("border", "0", "width", "50", "height", "50", "alt",
            "$MAILMANAGER_SIGNATURE_EDIT", 
            "src", "$g_graphicslib/mm_sig.jpg");
    htmlAnchorClose();
  }
  htmlImg("width", "3", "height", "50", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  # summary table
  htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
            "cellpadding", "0", "bgcolor", "#666666");
  htmlTableRow();
  htmlTableData("bgcolor", "#666666");
  htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
            "cellpadding", "1", "bgcolor", "#BBBBBB");
  htmlTableRow();
  htmlTableData("align", "left", "valign", "middle", "width", "50%");
  htmlNoBR();
  htmlTextSmall("&#160;$MAILMANAGER_FOLDER_NAME\:&#160;");
  formOpen("method", "POST", "style", "display:inline; font-size:1px");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("size", "20", "name", "mbox", "value", $g_mailbox_virtualpath,
            "style", "display:inline; line-height:14px; width:200px; font-size: 10px; font-family: Verdana, Arial, Helvetica; padding:0px;");
  htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
  formClose();
  htmlNoBRClose();
  htmlTableDataClose();
  if ($msgcount == 0) {
    htmlTableData("align", "right", "valign", "middle");
    htmlNoBR();
    $string = "$MAILMANAGER_FOLDER_SIZE\:&#160;$boxsize&#160;";
    htmlTextSmall($string);
    htmlNoBRClose();
    htmlTableDataClose();
  }
  else {
    htmlTableData("align", "right", "valign", "middle", "width", "50%");
    htmlNoBR();
    htmlTextSmall("$MAILMANAGER_FOLDER_RANGE_SELECT:&#160;");
    $string = " " . $curmpos . "-";
    if ($msgcount >= ($curmpos + $g_form{'mrange'})) {
      $mpos2 = $curmpos + $g_form{'mrange'} - 1;
    }
    else {
      $mpos2 = $msgcount;
    }
    $string .= $mpos2;
    formOpen("method", "POST", "style", "display:inline; font-size:1px");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
    formInput("size", "6", "name", "mpos", "value", $string,
              "style", "display:inline; line-height:14px; width:60px; font-size: 10px; font-family: Verdana, Arial, Helvetica; padding:0px;");
    htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
    formClose();
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
  }
  htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
            "cellpadding", "0", "bgcolor", "#666666");
  htmlTableRow();
  htmlTableData("bgcolor", "#666666");
  htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  if ($msgcount > 0) {
    # current messages and mailbox size table
    htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
              "cellpadding", "1", "bgcolor", "#BBBBBB");
    htmlTableRow();
    htmlTableData("align", "left", "valign", "middle", "width", "50%");
    htmlNoBR();
    # current message #'s
    $string = $MAILMANAGER_FOLDER_RANGE_SUMMARY;
    $string =~ s/__LOW__/$curmpos/;
    if ($msgcount >= ($curmpos + $g_form{'mrange'})) {
      $mpos2 = $curmpos + $g_form{'mrange'} - 1;
    }
    else {
      $mpos2 = $msgcount;
    }
    $string =~ s/__HIGH__/$mpos2/;
    $string =~ s/__TOTAL__/$msgcount/;
    htmlTextSmall("&#160;$string");
    if ($msgcount > $g_form{'mrange'}) {
      # prev | current | next message links
      htmlTextSmall("&#160;&#160;(&#160;");
      # prev message #'s
      if (($curmpos > (3 * $g_form{'mrange'})) ||
          (($curmpos - (3 * $g_form{'mrange'})) >
           (($g_form{'mrange'}-1) * -1))) {
        $string = "mbox=";
        $string .= encodingStringToURL($g_form{'mbox'});
        $mpos = $curmpos;
        $mpos -= $g_form{'mrange'};
        $mpos2 = $mpos + $g_form{'mrange'} - 1;
        if (($mpos > 1) ||
            (($mpos <= 1) &&
             (($g_form{'msort'} eq "by_thread") ||
              ($g_form{'msort'} eq "in_order")))) {
          $string .= "&mpos=" . $mpos . "-" . $mpos2;
        }
        $string .= "&mrange=$g_form{'mrange'}&msort=$g_form{'msort'}&messageid=";
        $string .= encodingStringToURL($mid);
        $title = $MAILMANAGER_MESSAGE_PREV_TITLE;
        $num = ($mpos > 0) ? $mpos : 0;
        $num = $mpos2 - $num;
        $title =~ s/__NUM__/$num/;
        htmlAnchor("style", "color:#3333cc", "title", $title,
                   "href", "$ENV{'SCRIPT_NAME'}?$string");
        htmlTextSmall($MAILMANAGER_MESSAGE_PREV);
        htmlAnchorClose();
        htmlTextSmall(" | ");
      }
      if (($curmpos > (2 * $g_form{'mrange'})) ||
          (($curmpos - (2 * $g_form{'mrange'})) >
           (($g_form{'mrange'}-1) * -1))) {
        $string = "mbox=";
        $string .= encodingStringToURL($g_form{'mbox'});
        $mpos = $curmpos;
        $mpos -= (2 * $g_form{'mrange'});
        $mpos2 = $mpos + $g_form{'mrange'} - 1;
        if (($mpos > 1) ||
            (($mpos <= 1) &&
             (($g_form{'msort'} eq "by_thread") ||
              ($g_form{'msort'} eq "in_order")))) {
          $string .= "&mpos=" . $mpos . "-" . $mpos2;
        }
        $string .= "&mrange=$g_form{'mrange'}&msort=$g_form{'msort'}&messageid=";
        $string .= encodingStringToURL($mid);
        $title = "$MAILMANAGER_FOLDER_RANGE_SELECT: ";
        $title .= ($mpos > 0) ? $mpos : 1;
        $title .= "-" . $mpos2;
        htmlAnchor("style", "color:#3333cc", "title", $title,
                   "href", "$ENV{'SCRIPT_NAME'}?$string");
        $mpos = 1 if ($mpos <= 0);
        htmlTextSmall("$mpos-$mpos2");
        htmlAnchorClose();
        htmlTextSmall(" | ");
      }
      if (($curmpos > $g_form{'mrange'}) ||
          (($curmpos - $g_form{'mrange'}) >
           (($g_form{'mrange'}-1) * -1))) {
        $string = "mbox=";
        $string .= encodingStringToURL($g_form{'mbox'});
        $mpos = $curmpos;
        $mpos -= $g_form{'mrange'};
        $mpos2 = $mpos + $g_form{'mrange'} - 1;
        if (($mpos > 1) ||
            (($mpos <= 1) &&
             (($g_form{'msort'} eq "by_thread") ||
              ($g_form{'msort'} eq "in_order")))) {
          $string .= "&mpos=" . $mpos . "-" . $mpos2;
        }
        $string .= "&mrange=$g_form{'mrange'}&msort=$g_form{'msort'}&messageid=";
        $string .= encodingStringToURL($mid);
        $title = "$MAILMANAGER_FOLDER_RANGE_SELECT: ";
        $title .= ($mpos > 0) ? $mpos : 1;
        $title .= "-" . $mpos2;
        htmlAnchor("style", "color:#3333cc", "title", $title,
                   "href", "$ENV{'SCRIPT_NAME'}?$string");
        $mpos = 1 if ($mpos <= 0);
        htmlTextSmall("$mpos-$mpos2");
        htmlAnchorClose();
        htmlTextSmall(" | ");
      }
      # current message #'s
      $string = $curmpos . "-";
      if ($msgcount >= ($curmpos + $g_form{'mrange'})) {
        $mpos2 = $curmpos + $g_form{'mrange'} - 1;
      }
      else {
        $mpos2 = $msgcount;
      }
      $string .= $mpos2;
      htmlTextSmall($string);
      # next message #'s
      if ($msgcount >= ($curmpos + $g_form{'mrange'})) {
        htmlTextSmall(" | ");
        $string = "mbox=";
        $string .= encodingStringToURL($g_form{'mbox'});
        $mpos = $curmpos;
        $mpos += $g_form{'mrange'};
        $mpos2 = $mpos + $g_form{'mrange'} - 1;
        if (($mpos < $lastmpos) ||
            (($mpos == $lastmpos) && 
             ($g_form{'msort'} ne "by_thread") &&
             ($g_form{'msort'} ne "in_order"))) {
          $string .= "&mpos=" . $mpos . "-" . $mpos2;
        }
        $string .= "&mrange=$g_form{'mrange'}&msort=$g_form{'msort'}&messageid=";
        $string .= encodingStringToURL($mid);
        $title = "$MAILMANAGER_FOLDER_RANGE_SELECT: ";
        $title .= $mpos . "-";
        $title .= ($mpos2 > $msgcount) ? $msgcount : $mpos2;
        htmlAnchor("style", "color:#3333cc", "title", $title,
                   "href", "$ENV{'SCRIPT_NAME'}?$string");
        $mpos2 = $msgcount if ($mpos2 > $msgcount);
        htmlTextSmall("$mpos-$mpos2");
        htmlAnchorClose();
      }
      if ($msgcount >= ($curmpos + (2 * $g_form{'mrange'}))) {
        htmlTextSmall(" | ");
        $string = "mbox=";
        $string .= encodingStringToURL($g_form{'mbox'});
        $mpos = $curmpos;
        $mpos += (2 * $g_form{'mrange'});
        $mpos2 = $mpos + $g_form{'mrange'} - 1;
        if (($mpos < $lastmpos) ||
            (($mpos == $lastmpos) && 
             ($g_form{'msort'} ne "by_thread") &&
             ($g_form{'msort'} ne "in_order"))) {
          $string .= "&mpos=" . $mpos . "-" . $mpos2;
        }
        $string .= "&mrange=$g_form{'mrange'}&msort=$g_form{'msort'}&messageid=";
        $string .= encodingStringToURL($mid);
        $title = "$MAILMANAGER_FOLDER_RANGE_SELECT: ";
        $title .= $mpos . "-";
        $title .= ($mpos2 > $msgcount) ? $msgcount : $mpos2;
        htmlAnchor("style", "color:#3333cc", "title", $title,
                   "href", "$ENV{'SCRIPT_NAME'}?$string");
        $mpos2 = $msgcount if ($mpos2 > $msgcount);
        htmlTextSmall("$mpos-$mpos2");
        htmlAnchorClose();
      }
      if ($msgcount >= ($curmpos + (3 * $g_form{'mrange'}))) {
        htmlTextSmall(" | ");
        $string = "mbox=";
        $string .= encodingStringToURL($g_form{'mbox'});
        $mpos = $curmpos;
        $mpos += (3 * $g_form{'mrange'});
        $mpos2 = $mpos + $g_form{'mrange'} - 1;
        if (($mpos < $lastmpos) ||
            (($mpos == $lastmpos) && 
             ($g_form{'msort'} ne "by_thread") &&
             ($g_form{'msort'} ne "in_order"))) {
          $string .= "&mpos=" . $mpos . "-" . $mpos2;
        }
        $string .= "&mrange=$g_form{'mrange'}&msort=$g_form{'msort'}&messageid=";
        $string .= encodingStringToURL($mid);
        $title = "$MAILMANAGER_FOLDER_RANGE_SELECT: ";
        $title .= $mpos . "-";
        $title .= ($mpos2 > $msgcount) ? $msgcount : $mpos2;
        htmlAnchor("style", "color:#3333cc", "title", $title,
                   "href", "$ENV{'SCRIPT_NAME'}?$string");
        $mpos2 = $msgcount if ($mpos2 > $msgcount);
        htmlTextSmall("$mpos-$mpos2");
        htmlAnchorClose();
      }
      if ($msgcount >= ($curmpos + (4 * $g_form{'mrange'}))) {
        htmlTextSmall(" | ");
        $string = "mbox=";
        $string .= encodingStringToURL($g_form{'mbox'});
        $mpos = $curmpos;
        $mpos += $g_form{'mrange'};
        $mpos2 = $mpos + $g_form{'mrange'} - 1;
        if (($mpos < $lastmpos) ||
            (($mpos == $lastmpos) && 
             ($g_form{'msort'} ne "by_thread") &&
             ($g_form{'msort'} ne "in_order"))) {
          $string .= "&mpos=" . $mpos . "-" . $mpos2;
        }
        $string .= "&mrange=$g_form{'mrange'}&msort=$g_form{'msort'}&messageid=";
        $string .= encodingStringToURL($mid);
        $title = "$MAILMANAGER_FOLDER_RANGE_SELECT: ";
        $title .= $mpos . "-";
        $title .= ($mpos2 > $msgcount) ? $msgcount : $mpos2;
        htmlAnchor("style", "color:#3333cc", "title", $title,
                   "href", "$ENV{'SCRIPT_NAME'}?$string");
        $mpos2 = $msgcount if ($mpos2 > $msgcount);
        htmlTextSmall($MAILMANAGER_MESSAGE_NEXT);
        htmlAnchorClose();
      }
      htmlTextSmall("&#160;)&#160;");
    }
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "right", "valign", "middle");
    htmlNoBR();
    $string = "$MAILMANAGER_FOLDER_SIZE\:&#160;$boxsize&#160;";
    htmlTextSmall($string);
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
              "cellpadding", "0", "bgcolor", "#666666");
    htmlTableRow();
    htmlTableData("bgcolor", "#666666");
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    formOpen("method", "POST", "style", "display:inline;");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
    formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
    formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    # the mail messages
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "width", "100\%");
    htmlTableRow();
    if ($msgcount > 1) {
      htmlTableData("align", "right");
      htmlTextBold("&#160;&#160;#&#160;&#160;");
      htmlTableDataClose();
    }
    if (($msgcount - $curmpos + 1) > 1) {
      htmlTableData("align", "center");
      htmlNoBR();
      htmlTextBold("&#160;$MAILMANAGER_MESSAGE_TAG&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
    }
    htmlTableData("align", "center");
    htmlNoBR();
    htmlTextBold("&#160;$MAILMANAGER_MESSAGE_FLAGS&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData();
    htmlNoBR();
    if ($g_form{'msort'} ne "by_date") {
      $args = "mbox=$encpath&mrange=$g_form{'mrange'}&sort_submit=by_date";
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$args");
    }
    htmlTextBold($MAILMANAGER_MESSAGE_DATE);
    if ($g_form{'msort'} ne "by_date") {
      htmlAnchorClose();
    }
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData();
    if ($g_form{'msort'} ne "by_sender") {
      $args = "mbox=$encpath&mrange=$g_form{'mrange'}&sort_submit=by_sender";
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$args");
    }
    htmlTextBold($MAILMANAGER_MESSAGE_SENDER);
    if ($g_form{'msort'} ne "by_sender") {
      htmlAnchorClose();
    }
    htmlTableDataClose();
    htmlTableData();
    if ($g_form{'msort'} ne "by_subject") {
      $args = "mbox=$encpath&mrange=$g_form{'mrange'}&sort_submit=by_subject";
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$args");
    }
    htmlTextBold($MAILMANAGER_MESSAGE_SUBJECT);
    if ($g_form{'msort'} ne "by_subject") {
      htmlAnchorClose();
    }
    htmlTableDataClose();
    htmlTableData("align", "right");
    htmlNoBR();
    if ($g_form{'msort'} ne "by_size") {
      $args = "mbox=$encpath&mrange=$g_form{'mrange'}&sort_submit=by_size";
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$args");
    }
    htmlTextBold("$MAILMANAGER_MESSAGE_SIZE_ABBREVIATED");
    if ($g_form{'msort'} ne "by_size") {
      htmlAnchorClose();
    }
    htmlTextBold("&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    # set some variables 
    $count = 0;
    $useraddress = mailmanagerUserSystemEmailAddress();
    push(@addresses, $useraddress);
    $useraddress = mailmanagerUserLastEmailAddress();
    if (($useraddress) &&
        ($useraddress =~ m{\b([\w.\-\&]+?@[\w.-]+?)(?=[.-]*(?:[^\w.-]|$))})) {
      push(@addresses, $1);
    }
    push(@addresses, $g_auth{'email'}) if ($g_auth{'email'});
    $url = (-e "help.cgi") ? "help.cgi" : "../help.cgi";
    # update prev and next stuff if not showing mailbox messages "in order"
    if (($g_form{'msort'} ne "in_order") &&
        (mailmanagerMailboxCacheStatusStale())) {
      mailmanagerMailboxCacheClear();
      $prevmessageid = $string = "";
      foreach $mid (sort mailmanagerByPreference(keys(%g_email))) {
        next unless ($mid);
        $string .= "$mid\n";
        $g_email{$mid}->{'__prevmessageid__'} = $prevmessageid;
        $g_email{$mid}->{'__nextmessageid__'} = "";
        if ($prevmessageid) {
          $g_email{$prevmessageid}->{'__nextmessageid__'} = $mid;
          mailmanagerMailboxCacheSaveMessageInfo($prevmessageid);
        }
        $prevmessageid = $mid;
      }
      if ($prevmessageid) {
        mailmanagerMailboxCacheSaveMessageInfo($prevmessageid);
      }
      mailmanagerMailboxCacheStatusUpdate($string);
    }
    # show the messages 
    foreach $mid (sort mailmanagerByPreference(keys(%g_email))) {
      $count++;
      if ($g_form{'msort'} ne "in_order") {
        # increment message count, skip if not in window
        next if ($count < $curmpos);
        next if ($count >= ($curmpos + $g_form{'mrange'}));
      }
      # print out the message summary row 
      if (mailmanagerIsUnread($mid)) {
        if ($g_form{'selected'} && ($g_form{'selected'} =~ /\Q$mid\E/)) {
          htmlTableRow("class", "unreadhighlighted");
        }
        else {
          htmlTableRow("class", "unreadunhighlighted");
        }
      }
      else {
        if ($g_form{'selected'} && ($g_form{'selected'} =~ /\Q$mid\E/)) {
          htmlTableRow("class", "highlighted");
        }
        else {
          htmlTableRow("class", "unhighlighted");
        }
      }
      # determine if the current message is from self (or not)
      $from_self = 0;
      ($fuser, $fhost) = (split(/\@/, $g_email{$mid}->{'__from_email__'}))[0,1];
      if ($fuser eq $g_auth{'login'}) {
        if ($fhost) {
          foreach $hostname (keys(%g_localhostnames)) {
            if ($hostname eq $fhost) {
              $from_self = 1;
              last;
            }
          }
        }
        else {
          $from_self = 1;
        }
      }
      # message number
      if ($msgcount > 1) {
        htmlTableData("valign", "middle", "align", "right");
        if ($g_form{'msort'} eq "in_order") {
          $string = $count + $curmpos - 1;
        }
        else {
          $string = $count;
        }
        htmlText("&#160;&#160;$string\.&#160;");
        htmlTableDataClose();
      }
      # tag
      if (($msgcount - $curmpos + 1) > 1) {
        htmlTableData("valign", "middle", "align", "center");
        formInput("type", "checkbox", "name", "selected",
                  "style", "display:inline; margin-top:-2px; margin-bottom:-2px; margin-left:0px; margin-right:0px; padding:0px",
                  "value", $mid, "onClick", "toggle_row(this)", "_OTHER_", 
                  ($g_form{'selected'} && ($g_form{'selected'} =~ /\Q$mid\E/)) ? "CHECKED" : "");
        htmlTableDataClose();
      }
      # flags - leading white space buffer
      htmlTableData("valign", "middle", "align", "center");
      # flags - (r) replied to; (N) new message
      if (mailmanagerIsUnread($mid)) {
        $args = "s=flags_N&language=$languagepref";
        htmlAnchor("href", "$url?$args", 
                   "title", $MAILMANAGER_FLAGS_HELP_N, "onClick",
                   "openWindow('$url?$args', 400, 250); return false");
        htmlAnchorTextCode("N");
        htmlAnchorClose();
      }
      elsif (($g_email{$mid}->{'status'} && ($g_email{$mid}->{'status'} =~ /r/)) ||
             ($g_email{$mid}->{'x-status'} && ($g_email{$mid}->{'x-status'} =~ /A/))) {
        $args = "s=flags_r&language=$languagepref";
        htmlAnchor("href", "$url?$args", 
                   "title", $MAILMANAGER_FLAGS_HELP_r, "onClick",
                   "openWindow('$url?$args', 375, 225); return false");
        htmlAnchorTextCode("r");
        htmlAnchorClose();
      }
      else {
        htmlTextCode("&#160;");
      }
      # flags - (+) message to user and user only
      #         (T) message to user, cc'ed to others
      #         (C) message is cc'ed to user
      #         (F) message is from user
      $mflag = 0;
      if ($from_self) {
        $args = "s=flags_F&language=$languagepref";
        htmlAnchor("href", "$url?$args", 
                   "title", $MAILMANAGER_FLAGS_HELP_F, "onClick",
                   "openWindow('$url?$args', 375, 225); return false");
        htmlAnchorTextCode("F");
        htmlAnchorClose();
        $mflag = 1;
      }
      else {
        foreach $useraddress (@addresses) {
          if ($g_email{$mid}->{'to'} =~ /$useraddress/) {
            $naddr = $g_email{$mid}->{'to'} =~ s/$useraddress/$useraddress/g;
            $namp = $g_email{$mid}->{'to'} =~ tr/\@/\@/;
            if ((!$g_email{$mid}->{'cc'}) && ($namp == $naddr)) {
              $args = "s=flags_plus&language=$languagepref";
              htmlAnchor("href", "$url?$args", 
                         "title", $MAILMANAGER_FLAGS_HELP_PLUS, "onClick",
                         "openWindow('$url?$args', 375, 225); return false");
              htmlAnchorTextCode("+");
              htmlAnchorClose();
            }
            else {
              $args = "s=flags_T&language=$languagepref";
              htmlAnchor("href", "$url?$args", 
                         "title", $MAILMANAGER_FLAGS_HELP_T, "onClick",
                         "openWindow('$url?$args', 375, 225); return false");
              htmlAnchorTextCode("T");
              htmlAnchorClose();
            }
            $mflag = 1;
            last;
          }
          elsif ($g_email{$mid}->{'cc'} && ($g_email{$mid}->{'cc'} =~ /$useraddress/)) {
            $args = "s=flags_C&language=$languagepref";
            htmlAnchor("href", "$url?$args", 
                       "title", $MAILMANAGER_FLAGS_HELP_C, "onClick",
                       "openWindow('$url?$args', 375, 225); return false");
            htmlAnchorTextCode("C");
            htmlAnchorClose();
            $mflag = 1;
            last;
          }
        }
      }
      htmlTextCode("&#160;") unless ($mflag);
      htmlTableDataClose();
      # date
      htmlTableData("valign", "middle");
      $string = $g_email{$mid}->{'__display_date__'};
      $string = dateLocalizeTimeString($string);
      $string =~ s/\ /\&\#160\;/g;
      htmlNoBR();
      htmlText("$string&#160;&#160;&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      # from
      htmlTableData("valign", "middle");
      htmlNoBR();
      if ($from_self) {
        $string = $g_email{$mid}->{'to'};
      }
      else {
        $string = $g_email{$mid}->{'__from_name__'};
      }
      if ($languagepref eq "ja") {
        $string = mailmanagerMimeDecodeHeaderJP_QP($string);
        $string = jcode'euc(mimedecode($string));
      }
      $string = mailmanagerMimeDecodeHeader($string);
      $string = "$MAILMANAGER_MESSAGE_TO\: $string" if ($from_self);
      if (length($string) > 30) {
        $string = substr($string, 0, 30) . "&#133;";
      }
      $string =~ s/\ /\&\#160\;/g;
      htmlText("$string&#160;&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      # subject
      htmlTableData("valign", "middle", "height", "16");
      if ($g_form{'msort'} eq "by_thread") {
        # print out thread graphics
        htmlTable("cellpadding", "0", "cellspacing", "0", "border", "0");
        htmlTableRow();
        $tl = length($g_email{$mid}->{'__thread_info__'});
        for ($tdx=0; $tdx<$tl; $tdx++) {
          $ttype = substr($g_email{$mid}->{'__thread_info__'}, $tdx, 1);
          if ($ttype eq " ") {
            htmlTableData("width", "16", "height", "16");
            htmlImg("width", "16", "height", "16", "src", "$g_graphicslib/sp.gif");
            htmlTableDataClose();
          }
          elsif ($ttype eq "+") {
            htmlTableData("width", "16", "height", "16");
            htmlImg("width", "16", "height", "16", "src", "$g_graphicslib/thread_branch.png");
            htmlTableDataClose();
          }
          elsif ($ttype eq "|") {
            htmlTableData("width", "16", "height", "16");
            htmlImg("width", "16", "height", "16", "src", "$g_graphicslib/thread_line.png");
            htmlTableDataClose();
          }
          elsif ($ttype eq "-") {
            htmlTableData("width", "16", "height", "16");
            htmlImg("width", "16", "height", "16", "src", "$g_graphicslib/thread_elbow.png");
            htmlTableDataClose();
          }
        }
        htmlTableData("valign", "middle", "height", "16");
      }
      htmlNoBR();
      if ($g_email{$mid}->{'subject'}) {
        $subject = $g_email{$mid}->{'subject'};
        if ($languagepref eq "ja") {
          $subject = mailmanagerMimeDecodeHeaderJP_QP($subject);
          $subject = jcode'euc(mimedecode($subject));
        }
        $subject = mailmanagerMimeDecodeHeader($subject);
      }
      else {
        $subject = $MAILMANAGER_NO_SUBJECT;
      }
      if ($g_form{'msort'} eq "by_thread") {
        if (((length($g_email{$mid}->{'__thread_info__'}) * 2) + length($subject)) > 60) {
          $subject = substr($subject, 0, (60 - (length($g_email{$mid}->{'__thread_info__'}) * 2))) . "&#133;";
        }
      }
      else {
        if (length($subject) > 60) {
          $subject = substr($subject, 0, 60) . "&#133;";
        }
      }
      $title = $MAILMANAGER_MESSAGE_VIEW;
      $title =~ s/__SUBJECT__/$subject/;
      $args = htmlAnchorArgs("mbox", encodingStringToURL($g_form{'mbox'}), 
                             "mpos", $g_form{'mpos'}, "mrange", $g_form{'mrange'},
                             "msort", $g_form{'msort'}, "messageid", 
                              encodingStringToURL($mid));
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$args", "title", $title);
      htmlAnchorText($subject);
      htmlAnchorClose();
      htmlText("&#160;&#160");
      htmlNoBRClose();
      if ($g_form{'msort'} eq "by_thread") {
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableClose();
      }
      htmlTableDataClose();
      # size
      htmlTableData("valign", "middle", "align", "right");
      $fsize = $g_email{$mid}->{'__size__'};
      if ($fsize < 1048576) {
        $sizetext = sprintf("%1.1f $KILOBYTES", ($fsize / 1024));
      }
      else {
        $sizetext = sprintf("%1.2f $MEGABYTES", ($fsize / 1048576));
      }
      htmlNoBR();
      htmlText("&#160;&#160;$sizetext&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableRowClose();
      $lastmid = $mid;
    }
    htmlTableClose();
    # separator
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "width", "100\%");
    htmlTableRow();
    htmlTableData("bgcolor", "#ffffff", "colspan", "2");
    htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    # separator
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "bgcolor", "#BBBBBB", "width", "100\%");
    htmlTableRow();
    htmlTableData();
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    # submission buttons
    if (($msgcount - $curmpos + 1) > 1) {
      htmlNoBR();
      htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
      if ((($g_users{$g_auth{'login'}}->{'ftp'}) ||
           ($g_users{$g_auth{'login'}}->{'imap'})) &&
          ($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full")) {
        formInput("type", "submit", "name", "submit",
                  "value", $MAILMANAGER_SAVE_TAGGED);
      }
      formInput("type", "submit", "name", "submit",
                "value", $MAILMANAGER_DELETE_TAGGED);
      print <<ENDTEXT;
&#160;
<script language="JavaScript1.1">
  document.write("<input type=\\\"button\\\" ");
  document.write("style=\\\"font-family:arial, helvetica; font-size:13px\\\" ");
  document.write("value=\\\"$TAG_ALL\\\" onClick=\\\"");
  document.write("this.value=tag_untag_all(this.form.selected)\\\">");
</script>
ENDTEXT
      htmlNoBRClose();
      htmlBR();
      htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
      htmlBR();
      htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
      if ($g_form{'msort'} ne "by_date") {
        formInput("type", "submit", "name", "sort_submit",
                  "value", $MAILMANAGER_SORT_BY_DATE);
      }
      if ($g_form{'msort'} ne "by_sender") {
        formInput("type", "submit", "name", "sort_submit",
                  "value", $MAILMANAGER_SORT_BY_SENDER);
      }
      if ($g_form{'msort'} ne "by_subject") {
        formInput("type", "submit", "name", "sort_submit",
                  "value", $MAILMANAGER_SORT_BY_SUBJECT);
      }
      if ($g_form{'msort'} ne "by_size") {
        formInput("type", "submit", "name", "sort_submit",
                  "value", $MAILMANAGER_SORT_BY_SIZE);
      }
      if ($g_form{'msort'} ne "by_thread") {
        formInput("type", "submit", "name", "sort_submit",
                  "value", $MAILMANAGER_SORT_BY_THREAD);
      }
      if ($g_form{'msort'} ne "in_order") {
        formInput("type", "submit", "name", "sort_submit",
                  "value", $MAILMANAGER_SORT_IN_ORDER);
      }
    }
    else {
      # just one message in mailbox
      htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
      formInput("type", "hidden", "name", "selected", "value", $lastmid);
      formInput("type", "submit", "name", "submit",
                "value", $MAILMANAGER_DELETE_SINGLE);
      if ((($g_users{$g_auth{'login'}}->{'ftp'}) ||
           ($g_users{$g_auth{'login'}}->{'imap'})) &&
          ($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full")) {
        formInput("type", "submit", "name", "submit",
                  "value", $MAILMANAGER_SAVE_SINGLE);
      }
    }
    if ((($g_users{$g_auth{'login'}}->{'ftp'}) ||
         ($g_users{$g_auth{'login'}}->{'imap'})) &&
        ($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full")) {
      # set rfs (removefromsource) equal to yes (if javascript enabled)
      # this makes the default action to be 'save and remove' (move)
      print <<ENDTEXT;
<script language="JavaScript1.1">
  document.write("<input type=\\\"hidden\\\" name=\\\"rfs\\\" ");
  document.write("value=\\\"yes\\\"> ");
</script>
ENDTEXT
    }
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "width", "100\%");
    htmlTableRow();
    htmlTableData("bgcolor", "#ffffff");
    htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData("bgcolor", "#000000");
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    formClose();
  }
  else {
    # specified mailbox is empty
    htmlBR();
    $MAILMANAGER_FOLDER_EMPTY_TEXT =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
    htmlText("&#160; $MAILMANAGER_FOLDER_EMPTY_TEXT");
    htmlP();
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "width", "100\%");
    htmlTableRow();
    htmlTableData("bgcolor", "#ffffff");
    htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData("bgcolor", "#000000");
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
  }
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  # mailbox summary
  htmlTable("border", "0");
  htmlTableRow();
  htmlTableData();
  htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableData("valign", "top");
  htmlNoBR();
  htmlTextBold("$MAILMANAGER_FOLDER_NAME\:&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("valign", "top");
  htmlNoBR();
  htmlText($g_mailbox_virtualpath);
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("valign", "top", "rowspan", "3");
  $len = length($g_mailbox_virtualpath);
  $string = "&#160; " x (($len > 25) ? 4 : 10);
  htmlNoBR();
  htmlText($string);
  htmlTextBold("$MAILMANAGER_ACTIONS\:&#160;&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("valign", "top", "rowspan", "3");
  unless ($g_form{'mbox'}) {
    $args = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                           "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'},
                           "epoch", $g_curtime);
    htmlNoBR();
    htmlAnchor("href", "mailmanager.cgi?$args",
               "title", $MAILMANAGER_CHECK_MAIL,
               "onClick", "document.location.reload(); return false");
    htmlAnchorText($MAILMANAGER_CHECK_MAIL);
    htmlAnchorClose();
    htmlNoBRClose();
    htmlBR();
  }
  htmlNoBR();
  $args = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                         "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'});
  htmlAnchor("href", "mm_compose.cgi?$args", "title", $MAILMANAGER_COMPOSE);
  htmlAnchorText($MAILMANAGER_COMPOSE);
  htmlAnchorClose();
  htmlNoBRClose();
  htmlBR();
  if ($msgcount > 1) {
    if ((($g_users{$g_auth{'login'}}->{'ftp'}) ||
         ($g_users{$g_auth{'login'}}->{'imap'})) &&
        ($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full")) {
      $args = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                             "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'},
                             "selected", "__ALL__", "rfs", "yes");
      htmlNoBR();
      htmlAnchor("href", "mm_save.cgi?$args",
                 "title", "$MAILMANAGER_SAVE_ALL&#160;(1&#133;$msgcount)");
      htmlAnchorText("$MAILMANAGER_SAVE_ALL&#160;(1&#133;$msgcount)");
      htmlAnchorClose();
      htmlNoBRClose();
      htmlBR();
    }
    $args = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                           "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'},
                           "selected", "__ALL__");
    htmlNoBR();
    htmlAnchor("href", "mm_delete.cgi?$args",
               "title", "$MAILMANAGER_DELETE_ALL&#160;(1&#133;$msgcount)");
    htmlAnchorText("$MAILMANAGER_DELETE_ALL&#160;(1&#133;$msgcount)");
    htmlAnchorClose();
    htmlNoBRClose();
    htmlBR();
  }
  if ((($g_users{$g_auth{'login'}}->{'ftp'}) ||
       ($g_users{$g_auth{'login'}}->{'imap'})) &&
      ($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full")) {
    $args = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                           "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'});
    htmlAnchor("href", "mm_select.cgi?$args",
               "title", $MAILMANAGER_SELECT_MAILBOX);
    htmlAnchorText($MAILMANAGER_SELECT_MAILBOX);
    htmlAnchorClose();
    htmlBR();
  }
  htmlTableDataClose();
  htmlTableData("valign", "top", "rowspan", "3");
  htmlText("&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "top", "rowspan", "3");
  if ($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full") {
    $args = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                           "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'});
    htmlAnchor("href", "mm_addressbook.cgi?$args",
               "title", $MAILMANAGER_ADDRESSBOOK_VIEW);
    htmlAnchorText($MAILMANAGER_ADDRESSBOOK_VIEW);
    htmlAnchorClose();
    htmlBR();
    htmlAnchor("href", "mm_filters.cgi?$args",
               "title", $MAILMANAGER_FILTERS_EDIT);
    htmlAnchorText($MAILMANAGER_FILTERS_EDIT);
    htmlAnchorClose();
    htmlBR();
    htmlNoBR();
    htmlAnchor("href", "mm_autoresponder.cgi?$args",
               "title", $MAILMANAGER_AUTOREPLY_EDIT_SETTINGS);
    htmlAnchorText($MAILMANAGER_AUTOREPLY_EDIT_SETTINGS);
    htmlAnchorClose();
    htmlNoBRClose();
    htmlBR();
    htmlAnchor("href", "mm_signature.cgi?$args",
               "title", $MAILMANAGER_SIGNATURE_EDIT);
    htmlAnchorText($MAILMANAGER_SIGNATURE_EDIT);
    htmlAnchorClose();
    htmlBR();
  }
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableData("valign", "top");
  htmlTextBold("$MAILMANAGER_FOLDER_NUM_MESSAGES\:&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "top");
  htmlText($msgcount);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableData("valign", "top");
  htmlTextBold("$MAILMANAGER_FOLDER_SIZE\:&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "top");
  htmlNoBR();
  htmlText($boxsize);
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  #
  # end contents table cell
  #
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  #
  # end mailbox table
  #
  htmlP();

  labelCustomFooter();

  # store mailbox folder to last.folder 
  if ($mbox_exists && $g_form{'mbox'}) {
    $homedir = $g_users{$g_auth{'login'}}->{'home'};
    if (open(NLFP, ">$homedir/.imanager/last.mailbox.$$")) {
      $g_mailbox_virtualpath =~ s/^\Q$homedir\E/\~\//;
      $g_mailbox_virtualpath =~ s#//#/#g;
      print NLFP "$g_mailbox_virtualpath\n";
      $num = 0;
      open(OLFP, "$homedir/.imanager/last.mailbox");
      while (<OLFP>) {
        $num++;
        last if ($num > 39);
        print NLFP $_;
      }
      close(OLFP);
      close(NLFP);
      rename("$homedir/.imanager/last.mailbox.$$",
             "$homedir/.imanager/last.mailbox");
    }
  }

  exit(0);
}

##############################################################################

sub mailmanagerShowMessage
{
  local($mesg) = @_;
  local($nselmsg, $msgcount, $msgslot);
  local($mid, $title, $string, $subject, $encargs, @msglines);
  local($index, $pci, $spci, $tpci, $header, $name, $ctype, $ctenc);
  local($subctype, $subctenc, $len, $languagepref, $messagepartid);
  local($curline, $buffer, $curfilepos, $endfilepos);
  local($a_num, $a_type, $a_enc, $a_size, $a_disp);
  local($mfrom, $mdate, $msubject, $msize, $sizetext);
  local($prevmid, $nextmid);

  if ($ENV{'SCRIPT_NAME'} !~ /wizards\/mailmanager.cgi/) {
    $ENV{'SCRIPT_NAME'} =~ /wizards\/([a-z_]*).cgi$/;
    $ENV{'SCRIPT_NAME'} =~ s/$1/mailmanager/;
  }

  ($nselmsg, $msgcount, $msgslot) = (mailmanagerReadMail())[0,1,2];

  encodingIncludeStringLibrary("mailmanager");
  $MAILMANAGER_TITLE =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;

  if ($nselmsg == 0) {
    # mail message $g_form{'messageid'} does not exist in specified mailbox
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($MAILMANAGER_TITLE);
    $string = $MAILMANAGER_MESSAGE_NOT_FOUND_TEXT;
    $string =~ s/__MAILBOX__/$g_mailbox_virtualpath/g;
    $string =~ s/__MESSAGEID__/$g_form{'messageid'}/g;
    htmlText($string);
    htmlP();
    labelCustomFooter();
    exit(0);
  }

  # rewrite msgslot if not sorting in order... get this from cache
  if ($g_form{'msort'} ne "in_order") {
    $msgslot = mailmanagerMailboxCacheGetMessageSlot($g_form{'messageid'});
  }


  # parse the message body into parts if applicable
  mailmanagerParseBodyIntoParts();

  if ($g_form{'messagepart'}) {
    # show message part if specified 
    mailmanagerShowMessagePart();
  }

  $encpath = encodingStringToURL($g_form{'mbox'});

  $mid = $g_form{'messageid'};
  if ($g_email{$mid}->{'__size__'} < 1024) {
    $sizetext = sprintf("%s $BYTES", $g_email{$mid}->{'__size__'});
  }
  elsif ($g_email{$mid}->{'__size__'} < 1048576) {
    $sizetext = sprintf("%1.1f $KILOBYTES", 
                        ($g_email{$mid}->{'__size__'} / 1024));
  }
  else {
    $sizetext = sprintf("%1.2f $MEGABYTES", 
                        ($g_email{$mid}->{'__size__'} / 1048576));
  }

  # get the previous and next message ids; this is based on the 
  # current message id and the current sorting preference
  ($prevmid, $nextmid) = (mailmanagerMailboxCacheGetMessageInfo())[0,1];

  $languagepref = encodingGetLanguagePreference();

  htmlResponseHeader("Content-type: $g_default_content_type");

  # build the title string
  if ($g_email{$mid}->{'subject'}) {
    $subject = $g_email{$mid}->{'subject'};
    if ($languagepref eq "ja") {
      $subject = mailmanagerMimeDecodeHeaderJP_QP($subject);
      $subject = jcode'euc(mimedecode($subject));
    }
    $subject = mailmanagerMimeDecodeHeader($subject);
  }
  else {
    $subject = $MAILMANAGER_NO_SUBJECT;
  }
  $string = $g_email{$mid}->{'from'};
  if ($languagepref eq "ja") {
    $string = mailmanagerMimeDecodeHeaderJP_QP($string);
    $string = jcode'euc(mimedecode($string));
  }
  $string = mailmanagerMimeDecodeHeader($string);
  $title = "$MAILMANAGER_TITLE : $subject -- $string";

  if (($g_form{'print_submit'}) || mailmanagerIsTmpMessage()) {
    # printer friendly format
    htmlHtml();
    htmlHead();
    htmlTitle($title);
    htmlHeadClose();
    htmlBody("bgcolor", "#ffffff");
  }
  else {
    $javascript = javascriptOpenWindow();
    labelCustomHeader($title, "", $javascript);
    if (!$mesg && $g_form{'msgfileid'}) {
      # read message from temporary state message file
      $mesg = redirectMessageRead($g_form{'msgfileid'});
    }
    if ($mesg) {
      @msglines = split(/\n/, $mesg);
      foreach $mesg (@msglines) {
        htmlTextColorBold(">>> $mesg <<<", "#cc0000");
        htmlBR();
      }
      htmlBR();
    }
    #
    # mail message table (2 cells: sidebar, contents)
    #
    htmlTable("border", "0", "cellspacing", "0",
              "cellpadding", "0", "bgcolor", "#000000");
    htmlTableRow();
    htmlTableData();
    htmlTable("border", "0", "cellspacing", "1", "cellpadding", "0");
    htmlTableRow();
    htmlTableData("bgcolor", "#999999", "valign", "top");
    #
    # begin sidebar table cell
    #
    mailmanagerShowMailSidebar(); 
    #
    # end sidebar table cell
    #
    htmlTableDataClose();
    htmlTableData("bgcolor", "#ffffff", "valign", "top");
    #
    # begin message table cell
    #
    htmlTable("cellpadding", "2", "cellspacing", "0",
              "border", "0", "width", "100\%", "bgcolor", "#9999cc");
    htmlTableRow();
    htmlTableData("align", "left", "valign", "middle");
    htmlTextBold("&#160;$g_mailbox_virtualpath : $subject -- $string");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
              "cellpadding", "0", "bgcolor", "#666666");
    htmlTableRow();
    htmlTableData("bgcolor", "#666666");
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    # button bar
    htmlImg("width", "3", "height", "50", "src", "$g_graphicslib/sp.gif");
    $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'}, 
                              "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'}, 
                              "messageid", encodingStringToURL($mid));
    htmlAnchor("href", "mm_bounce.cgi?$encargs",
               "title", $MAILMANAGER_BOUNCE,
               "onMouseOver", "status='$MAILMANAGER_BOUNCE'; return true",
               "onMouseOut", "status=''; return true");
    htmlImg("border", "0", "width", "50", "height", "50",
            "alt", "$MAILMANAGER_BOUNCE", "src", "$g_graphicslib/mm_b.jpg");
    htmlAnchorClose();
    htmlAnchor("href", "mm_compose.cgi?type=forward&$encargs",
               "title", $MAILMANAGER_FORWARD,
               "onMouseOver", "status='$MAILMANAGER_FORWARD'; return true",
               "onMouseOut", "status=''; return true");
    htmlImg("border", "0", "width", "50", "height", "50",
            "alt", "$MAILMANAGER_FORWARD", "src", "$g_graphicslib/mm_f.jpg");
    htmlAnchorClose();
    htmlAnchor("href", "mm_compose.cgi?type=reply&$encargs",
               "title", $MAILMANAGER_REPLY,
               "onMouseOver", "status='$MAILMANAGER_REPLY'; return true",
               "onMouseOut", "status=''; return true");
    htmlImg("border", "0", "width", "50", "height", "50",
            "alt", "$MAILMANAGER_REPLY", "src", "$g_graphicslib/mm_r.jpg");
    htmlAnchorClose();
    htmlAnchor("href", "mm_compose.cgi?type=groupreply&$encargs",
               "title", $MAILMANAGER_REPLY_GROUP,
               "onMouseOver", "status='$MAILMANAGER_REPLY_GROUP'; return true",
               "onMouseOut", "status=''; return true");
    htmlImg("border", "0", "width", "50", "height", "50",
            "alt", "$MAILMANAGER_REPLY_GROUP", 
            "src", "$g_graphicslib/mm_g.jpg");
    htmlAnchorClose();
    htmlImg("width", "15", "height", "1", "src", "$g_graphicslib/sp.gif");
    if ((($g_users{$g_auth{'login'}}->{'ftp'}) ||
         ($g_users{$g_auth{'login'}}->{'imap'})) &&
        ($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full")) {
      $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'}, 
                                "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'}, 
                                "rfs", "yes", "messageid", encodingStringToURL($mid));
      htmlAnchor("href", "mm_save.cgi?$encargs",
                 "title", $MAILMANAGER_SAVE_SINGLE, "onMouseOver",
                 "status='$MAILMANAGER_SAVE_SINGLE'; return true",
                 "onMouseOut", "status=''; return true");
      htmlImg("border", "0", "width", "50", "height", "50", "alt",
              "$MAILMANAGER_SAVE_SINGLE", "src", "$g_graphicslib/mm_s.jpg");
      htmlAnchorClose(); 
    }
    $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'}, 
                              "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'}, 
                              "selected", encodingStringToURL($mid));
    htmlAnchor("href", "mm_delete.cgi?$encargs",
               "title", $MAILMANAGER_DELETE_SINGLE, "onMouseOver",  
               "status='$MAILMANAGER_DELETE_SINGLE'; return true",
               "onMouseOut", "status=''; return true");
    htmlImg("border", "0", "width", "50", "height", "50", "alt",
            "$MAILMANAGER_DELETE_SINGLE", "src", "$g_graphicslib/mm_d.jpg");
    htmlAnchorClose();
    htmlImg("width", "15", "height", "1", "src", "$g_graphicslib/sp.gif");
    $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'}, 
                              "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'});
    htmlAnchor("href", "mm_compose.cgi?$encargs",
               "title", $MAILMANAGER_COMPOSE,
               "onMouseOver", "status='$MAILMANAGER_COMPOSE'; return true",
               "onMouseOut", "status=''; return true");
    htmlImg("border", "0", "width", "50", "height", "50", 
            "alt", "$MAILMANAGER_COMPOSE", "src", "$g_graphicslib/mm_new.jpg");
    htmlAnchorClose();
    htmlImg("width", "15", "height", "1", "src", "$g_graphicslib/sp.gif");
    if ((($g_users{$g_auth{'login'}}->{'ftp'}) ||
         ($g_users{$g_auth{'login'}}->{'imap'})) &&
        ($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full")) {
      $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'}, 
                                "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'});
      htmlAnchor("href", "mm_select.cgi?$encargs",
                 "title", $MAILMANAGER_SELECT_MAILBOX, "onMouseOver", 
                 "status='$MAILMANAGER_SELECT_MAILBOX'; return true",
                 "onMouseOut", "status=''; return true");
      htmlImg("border", "0", "width", "50", "height", "50", "alt",
              "$MAILMANAGER_SELECT_MAILBOX", "src", "$g_graphicslib/mm_c.jpg");
      htmlAnchorClose();
      htmlImg("width", "15", "height", "1", "src", "$g_graphicslib/sp.gif");
    }
    $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                              "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                              "messageid", encodingStringToURL($mid));
    unless ($g_form{'rawheaders'}) {
      $encargs .= "&rawheaders=yes";
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs", 
                 "title", $MAILMANAGER_SHOW_FULL_HEADERS, "onMouseOver",  
                 "status='$MAILMANAGER_SHOW_FULL_HEADERS'; return true",
                 "onMouseOut", "status=''; return true");
      htmlImg("border", "0", "width", "50", "height", "50",
              "alt", "$MAILMANAGER_SHOW_FULL_HEADERS",
              "src", "$g_graphicslib/mm_hm.jpg");
      htmlAnchorClose();
    }
    else {
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs", 
                 "title", $MAILMANAGER_SHOW_PARTIAL_HEADERS, "onMouseOver",  
                 "status='$MAILMANAGER_SHOW_PARTIAL_HEADERS'; return true",
                 "onMouseOut", "status=''; return true");
      htmlImg("border", "0", "width", "50", "height", "50",
              "alt", "$MAILMANAGER_SHOW_PARTIAL_HEADERS",
              "src", "$g_graphicslib/mm_hl.jpg");
      htmlAnchorClose();
    }
    htmlImg("width", "3", "height", "50", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    # summary table
    htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
              "cellpadding", "0", "bgcolor", "#666666");
    htmlTableRow();
    htmlTableData("bgcolor", "#666666", "colspan", "3");
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
              "cellpadding", "2", "bgcolor", "#BBBBBB");
    htmlTableRow();
    htmlTableData("align", "left");
    htmlNoBR();
    $string = "&#160;$MAILMANAGER_FOLDER_NAME\:&#160;";
    htmlTextSmall("&#160;$MAILMANAGER_FOLDER_NAME\:&#160;");
    $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                              "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}");
    $title = $MAILMANAGER_FOLDER_RETURN;
    $title =~ s/__FOLDER__/$g_mailbox_virtualpath/;
    htmlAnchor("style", "color:#3333cc", "title", $title,
               "href", "mailmanager.cgi?$encargs");
    htmlTextSmall($g_mailbox_virtualpath);
    htmlAnchorClose();
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "center");
    htmlNoBR();
    if ($g_form{'msort'} eq "in_order") {
      $string = "$MAILMANAGER_MESSAGE_NUMBER\:&#160;$msgslot";
    }
    else {
      $string = "$MAILMANAGER_MESSAGE_NUMBER\:&#160;$msgslot/$msgcount";
    }
    htmlTextSmall($string);
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "right");
    htmlNoBR();
    $string = "$MAILMANAGER_MESSAGE_SIZE\:&#160;$sizetext&#160;";
    htmlTextSmall($string);
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
              "cellpadding", "0", "bgcolor", "#666666");
    htmlTableRow();
    htmlTableData("bgcolor", "#666666", "colspan", "3");
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    if ($prevmid || $nextmid) {
      htmlTable("cellpadding", "2", "cellspacing", "0",
                "border", "0", "width", "100\%", "bgcolor", "#cccccc");
      htmlTableRow();
      htmlTableData("align", "left", "valign", "middle");
      if ($prevmid) {
        htmlTextSmallBold("<<&#160;");
        $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                  "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                  "messageid", encodingStringToURL($prevmid));
        $title = $MAILMANAGER_VIEW_PREV_TITLE;
        if ($g_form{'msort'} ne "in_order") {
          $title .= "...\n";
          ($mdate, $mfrom, $msubject, $msize) = 
                   (mailmanagerMailboxCacheGetMessageInfo($prevmid))[2,3,4,5];
          $string = dateLocalizeTimeString($mdate);
          $title .= "$MAILMANAGER_MESSAGE_DATE\: $string\n";
          if ($languagepref eq "ja") {
            $mfrom = mailmanagerMimeDecodeHeaderJP_QP($mfrom);
            $mfrom = jcode'euc(mimedecode($mfrom));
          }
          $mfrom = mailmanagerMimeDecodeHeader($mfrom);
          $title .= "$MAILMANAGER_MESSAGE_SENDER\: $mfrom\n";
          if ($msubject) {
            if ($languagepref eq "ja") {
              $msubject = mailmanagerMimeDecodeHeaderJP_QP($msubject);
              $msubject = jcode'euc(mimedecode($msubject));
            }
            $msubject = mailmanagerMimeDecodeHeader($msubject);
          }
          else {
            $msubject = $MAILMANAGER_NO_SUBJECT;
          }
          $title .= "$MAILMANAGER_MESSAGE_SUBJECT\: $msubject\n";
          if ($msize < 1024) {
            $sizetext = sprintf("%s $BYTES", $msize);
          }
          elsif ($msize < 1048576) {
            $sizetext = sprintf("%1.1f $KILOBYTES", ($msize / 1024));
          }
          else {
            $sizetext = sprintf("%1.2f $MEGABYTES", ($msize / 1048576));
          }
          $title .= "$MAILMANAGER_MESSAGE_SIZE_ABBREVIATED\: $sizetext";
        }
        htmlAnchor("style", "color:#3333cc", "title", $title,
                   "href", "$ENV{'SCRIPT_NAME'}?$encargs");
        htmlTextSmall($MAILMANAGER_VIEW_PREV);
        htmlAnchorClose();
      }
      else {
        htmlTextSmallBold("&#160;");
      }
      htmlTableDataClose();
      htmlTableData("align", "right", "valign", "middle");
      if ($nextmid) {
        $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                  "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                  "messageid", encodingStringToURL($nextmid));
        $title = $MAILMANAGER_VIEW_NEXT_TITLE;
        if ($g_form{'msort'} ne "in_order") {
          $title .= "...\n";
          ($mdate, $mfrom, $msubject, $msize) = 
                   (mailmanagerMailboxCacheGetMessageInfo($nextmid))[2,3,4,5];
          $string = dateLocalizeTimeString($mdate);
          $title .= "$MAILMANAGER_MESSAGE_DATE\: $string\n";
          if ($languagepref eq "ja") {
            $mfrom = mailmanagerMimeDecodeHeaderJP_QP($mfrom);
            $mfrom = jcode'euc(mimedecode($mfrom));
          }
          $mfrom = mailmanagerMimeDecodeHeader($mfrom);
          $title .= "$MAILMANAGER_MESSAGE_SENDER\: $mfrom\n";
          if ($msubject) {
            if ($languagepref eq "ja") {
              $msubject = mailmanagerMimeDecodeHeaderJP_QP($msubject);
              $msubject = jcode'euc(mimedecode($msubject));
            }
            $msubject = mailmanagerMimeDecodeHeader($msubject);
          }
          else {
            $msubject = $MAILMANAGER_NO_SUBJECT;
          }
          $title .= "$MAILMANAGER_MESSAGE_SUBJECT\: $msubject\n";
          if ($msize < 1024) {
            $sizetext = sprintf("%s $BYTES", $msize);
          }
          elsif ($msize < 1048576) {
            $sizetext = sprintf("%1.1f $KILOBYTES", ($msize / 1024));
          }
          else {
            $sizetext = sprintf("%1.2f $MEGABYTES", ($msize / 1048576));
          }
          $title .= "$MAILMANAGER_MESSAGE_SIZE_ABBREVIATED\: $sizetext";
        }
        htmlAnchor("style", "color:#3333cc", "title", $title,
                   "href", "$ENV{'SCRIPT_NAME'}?$encargs");
        htmlTextSmall($MAILMANAGER_VIEW_NEXT);
        htmlAnchorClose();
        htmlTextSmallBold("&#160;>>");
      }
      else {
        htmlTextSmallBold("&#160;");
      }
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
                "cellpadding", "0", "bgcolor", "#666666");
      htmlTableRow();
      htmlTableData("bgcolor", "#666666");
      htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
    }
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    # begin message encapsulation table
    htmlTable();
    htmlTableRow();
    htmlTableData();
  }

  # print message headers
  unless ($g_form{'rawheaders'}) {
    # just show a handful of meaningful headers
    htmlTable("border", "0", "cellpadding", "0", "cellspacing", "0");
    # to
    htmlTableRow();
    htmlTableData("valign", "top");
    htmlTextBold("$MAILMANAGER_MESSAGE_TO\:&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top");
    $header = $g_email{$mid}->{'to'};
    if ($languagepref eq "ja") {
      $header = mailmanagerMimeDecodeHeaderJP_QP($header);
      $header = jcode'euc(mimedecode($header));
    }
    $header = mailmanagerMimeDecodeHeader($header);
    unless ($g_form{'print_submit'}) {
      $header = htmlSanitize($header);
      $header = mailmanagerMessageHeaderMarkup("to", $header);
      htmlFont("class", "text", "face", "arial, helvetica", "size", "2",
               "style", "font-family:arial, helvetica; font-size:12px");
      print "$header";
      htmlFontClose();
    }
    else {
      htmlText($header);
    }
    htmlTableDataClose();
    htmlTableRowClose();
    # date
    htmlTableRow();
    htmlTableData("valign", "top");
    htmlTextBold("$MAILMANAGER_MESSAGE_DATE\:&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top");
    $string = $g_email{$mid}->{'date'};
    $string = dateLocalizeTimeString($string);
    htmlText($string);
    htmlTableDataClose();
    htmlTableRowClose();
    # from
    htmlTableRow();
    htmlTableData("valign", "top");
    htmlNoBR();
    htmlTextBold("$MAILMANAGER_MESSAGE_SENDER\:&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("valign", "top");
    $header = $g_email{$mid}->{'from'} ||
              $g_email{$mid}->{'__delivered_from__'};
    if ($languagepref eq "ja") {
      $header = mailmanagerMimeDecodeHeaderJP_QP($header);
      $header = jcode'euc(mimedecode($header));
    }
    $header = mailmanagerMimeDecodeHeader($header);
    unless ($g_form{'print_submit'}) {
      $header = htmlSanitize($header);
      $header = mailmanagerMessageHeaderMarkup("from", $header);
      htmlFont("class", "text", "face", "arial, helvetica", "size", "2",
               "style", "font-family:arial, helvetica; font-size:12px");
      print "$header";
      htmlFontClose();
    }
    else {
      htmlText($header);
    }
    htmlTableDataClose();
    htmlTableRowClose();
    if ($g_email{$mid}->{'reply-to'}) {
      # reply-to
      htmlTableRow();
      htmlTableData("valign", "top");
      htmlNoBR();
      htmlTextBold("$MAILMANAGER_MESSAGE_REPLY_TO\:&#160;&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableData("valign", "top");
      $header = $g_email{$mid}->{'reply-to'};
      if ($languagepref eq "ja") {
        $header = mailmanagerMimeDecodeHeaderJP_QP($header);
        $header = jcode'euc(mimedecode($header));
      }
      $header = mailmanagerMimeDecodeHeader($header);
      unless ($g_form{'print_submit'}) {
        $header = htmlSanitize($header);
        $header = mailmanagerMessageHeaderMarkup("reply-to", $header);
        htmlFont("class", "text", "face", "arial, helvetica", "size", "2",
                 "style", "font-family:arial, helvetica; font-size:12px");
        print "$header";
        htmlFontClose();
      }
      else {
        htmlText($header);
      }
      htmlTableDataClose();
      htmlTableRowClose();
    }
    # subject
    htmlTableRow();
    htmlTableData("valign", "top");
    htmlTextBold("$MAILMANAGER_MESSAGE_SUBJECT\:&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top");
    htmlText($subject);
    htmlTableDataClose();
    htmlTableRowClose();
    if ($g_email{$mid}->{'cc'}) {
      # cc
      htmlTableRow();
      htmlTableData("valign", "top");
      htmlTextBold("$MAILMANAGER_MESSAGE_CC\:&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "top");
      $header = $g_email{$mid}->{'cc'};
      if ($languagepref eq "ja") {
        $header = mailmanagerMimeDecodeHeaderJP_QP($header);
        $header = jcode'euc(mimedecode($header));
      }
      $header = mailmanagerMimeDecodeHeader($header);
      unless ($g_form{'print_submit'}) {
        $header = htmlSanitize($header);
        $header = mailmanagerMessageHeaderMarkup("cc", $header);
        htmlFont("class", "text", "face", "arial, helvetica", "size", "2",
                 "style", "font-family:arial, helvetica; font-size:12px");
        print "$header";
        htmlFontClose();
      }
      else {
        htmlText($header);
      }
      htmlTableDataClose();
      htmlTableRowClose();
    }
    htmlTableClose();
  }
  else {
    # show all headers (raw mode)
    htmlTable("border", "0", "cellpadding", "0", "cellspacing", "0");
    htmlTableRow();
    htmlTableData("valign", "top");
    htmlTextCodeBold("From &#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top");
    $string = $g_email{$mid}->{'__delivered_from__'};
    if ($languagepref eq "ja") {
      $string = mailmanagerMimeDecodeHeaderJP_QP($string);
      $string = jcode'euc(mimedecode($string));
    }
    $string = mailmanagerMimeDecodeHeader($string);
    $string .= " $g_email{$mid}->{'__delivered_date__'}";
    htmlTextCode($string);
    htmlTableDataClose();
    htmlTableRowClose();
    # print out the delivery header
    for ($index=0; $index<=$#{$g_email{$mid}->{'headers'}}; $index++) {
      $header = $g_email{$mid}->{'headers'}[$index];
      next if ($header =~ /^\_\_/);
      if ($languagepref eq "ja") {
        $header = mailmanagerMimeDecodeHeaderJP_QP($header);
        $header = jcode'euc(mimedecode($header));
      }
      $header = mailmanagerMimeDecodeHeader($header);
      if ($header =~ /^(.*?)\:\ (.*)/) {
        $name = $1;
        $string = $2;
        htmlTableRow();
        htmlTableData("valign", "top");
        htmlNoBR();
        htmlTextCodeBold("$name\:&#160;");
        htmlNoBRClose();
        htmlTableDataClose();
        htmlTableData("valign", "top");
        htmlTextCode($string);
        htmlTableDataClose();
        htmlTableRowClose();
      }
    }
    htmlTableClose();
  }
  htmlBR();

  # show message body
  $messagepartid = -1; 
  $ctype = $g_email{$mid}->{'content-type'};
  $ctenc = $g_email{$mid}->{'content-transfer-encoding'};
  htmlFont("class", "smallfixed", "face", "courier new, courier", "size", "2",
           "style", "font-family:courier new, courier; font-size:12px");
  if ($#{$g_email{$mid}->{'parts'}} > -1) {
    # multipart message; print out the message part by part
    for ($pci=0; $pci<=$#{$g_email{$mid}->{'parts'}}; $pci++) {
      $messagepartid = $pci+1;
      $a_num = $MAILMANAGER_ATTACHMENT_NUMBER;
      $a_num =~ s/__NUM__/$messagepartid/;
      $a_type = (split(/\;/, $g_email{$mid}->{'parts'}[$pci]->{'content-type'}))[0] || "???";
      $a_enc = $g_email{$mid}->{'parts'}[$pci]->{'content-transfer-encoding'};
      $a_disp = $g_email{$mid}->{'parts'}[$pci]->{'content-disposition'};
      $a_size = $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_end__'} - 
                $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_body__'};
      if ($a_size < 1024) {
        $a_size = sprintf("%s $BYTES", $a_size);
      }
      elsif ($a_size < 1048576) {
        $a_size = sprintf("%1.1f $KILOBYTES", ($a_size / 1024));
      }
      else {
        $a_size = sprintf("%1.2f $MEGABYTES", ($a_size / 1048576));
      }
      if ($pci > 0) {
        htmlImg("width", "1", "height", "2", "src", "$g_graphicslib/sp.gif");
        htmlBR();
      }
      htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
                "cellpadding", "0", "background", "$g_graphicslib/dotted.png");
      htmlTableRow();
      htmlTableData();
      htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
      htmlBR();
      htmlFont("color", "#666666");
      print "[ $a_num";
      if ($a_disp) {
        $a_disp =~ s/attachment; //;
        $a_disp =~ s/inline; //;
        if ($languagepref eq "ja") {
          $a_disp = mailmanagerMimeDecodeHeaderJP_QP($a_disp);
          $a_disp = jcode'euc(mimedecode($a_disp));
        }
        $a_disp =~ s/filename=/$MAILMANAGER_CONTENT_DISPOSITION_FILENAME=/;
        print "; $a_disp";
      }
      print " ]";
      htmlBR();
      print "[ $MAILMANAGER_ATTACHMENT_TYPE: $a_type; ";
      if ($a_enc) {
        print "$MAILMANAGER_ATTACHMENT_ENCODING: $a_enc; ";
      }
      print "$MAILMANAGER_ATTACHMENT_SIZE: $a_size ]";
      htmlBR();
      htmlFontClose();
      htmlBR();
      $ctype = $g_email{$mid}->{'parts'}[$pci]->{'content-type'};
      $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'content-transfer-encoding'};
      if ($#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}} > -1) {
        # here we have a message part that has secondary level parts
        htmlUL();
        for ($spci=0; $spci<=$#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}}; $spci++) {
          $messagepartid = sprintf "%d.%d", ($pci+1), ($spci+1);
          $a_num = $MAILMANAGER_ATTACHMENT_NUMBER;
          $a_num =~ s/__NUM__/$messagepartid/;
          $a_type = (split(/\;/, $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-type'}))[0] || "???";
          $a_enc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-transfer-encoding'};
          $a_disp = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-disposition'};
          $a_size = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_end__'} - 
                    $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_body__'};
          if ($a_size < 1024) {
            $a_size = sprintf("%s $BYTES", $a_size);
          }
          elsif ($a_size < 1048576) {
            $a_size = sprintf("%1.1f $KILOBYTES", ($a_size / 1024));
          }
          else {
            $a_size = sprintf("%1.2f $MEGABYTES", ($a_size / 1048576));
          }
          if ($spci > 0) {
            htmlImg("width", "1", "height", "2", "src", "$g_graphicslib/sp.gif");
            htmlBR();
          }
          htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
                    "cellpadding", "0", "background", "$g_graphicslib/dotted.png");
          htmlTableRow();
          htmlTableData();
          htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
          htmlTableDataClose();
          htmlTableRowClose();
          htmlTableClose();
          htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
          htmlBR();
          htmlFont("color", "#666666");
          print "[ $a_num";
          if ($a_disp) {
            $a_disp =~ s/attachment; //;
            $a_disp =~ s/inline; //;
            if ($languagepref eq "ja") {
              $a_disp = mailmanagerMimeDecodeHeaderJP_QP($a_disp);
              $a_disp = jcode'euc(mimedecode($a_disp));
            }
            $a_disp =~ s/filename=/$MAILMANAGER_CONTENT_DISPOSITION_FILENAME=/;
            print "; $a_disp";
          }
          print " ]";
          htmlBR();
          print "[ $MAILMANAGER_ATTACHMENT_TYPE: $a_type; ";
          if ($a_enc) {
            print "$MAILMANAGER_ATTACHMENT_ENCODING: $a_enc; ";
          }
          print "$MAILMANAGER_ATTACHMENT_SIZE: $a_size ]";
          htmlBR();
          htmlFontClose();
          htmlBR();
          $subctype = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-type'};
          $subctenc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-transfer-encoding'};
          if ($#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}} > -1) {
            # here we have a message part that has tertiary level parts
            htmlUL();
            for ($tpci=0; $tpci<=$#{$g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}}; $tpci++) {
              $messagepartid = sprintf "%d.%d.%d", ($pci+1), ($spci+1), ($tpci+1);
              $a_num = $MAILMANAGER_ATTACHMENT_NUMBER;
              $a_num =~ s/__NUM__/$messagepartid/;
              $a_type = (split(/\;/, $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-type'}))[0] || "???";
              $a_enc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-transfer-encoding'};
              $a_disp = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-disposition'};
              $a_size = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_end__'} - 
                        $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_body__'};
              if ($a_size < 1024) {
                $a_size = sprintf("%s $BYTES", $a_size);
              }
              elsif ($a_size < 1048576) {
                $a_size = sprintf("%1.1f $KILOBYTES", ($a_size / 1024));
              }
              else {
                $a_size = sprintf("%1.2f $MEGABYTES", ($a_size / 1048576));
              }
              if ($tpci > 0) {
                htmlImg("width", "1", "height", "2", "src", "$g_graphicslib/sp.gif");
                htmlBR();
              }
              htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
                        "cellpadding", "0", "background", "$g_graphicslib/dotted.png");
              htmlTableRow();
              htmlTableData();
              htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
              htmlTableDataClose();
              htmlTableRowClose();
              htmlTableClose();
              htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
              htmlBR();
              htmlFont("color", "#666666");
              print "[ $a_num";
              if ($a_disp) {
                $a_disp =~ s/attachment; //;
                $a_disp =~ s/inline; //;
                if ($languagepref eq "ja") {
                  $a_disp = mailmanagerMimeDecodeHeaderJP_QP($a_disp);
                  $a_disp = jcode'euc(mimedecode($a_disp));
                }
                $a_disp =~ s/filename=/$MAILMANAGER_CONTENT_DISPOSITION_FILENAME=/;
                print "; $a_disp";
              }
              print " ]";
              htmlBR();
              print "[ $MAILMANAGER_ATTACHMENT_TYPE: $a_type; ";
              if ($a_enc) {
                print "$MAILMANAGER_ATTACHMENT_ENCODING: $a_enc; ";
              }
              print "$MAILMANAGER_ATTACHMENT_SIZE: $a_size ]";
              htmlBR();
              htmlFontClose();
              htmlBR();
              $subctype = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-type'};
              $subctenc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-transfer-encoding'};
              if (($subctype =~ /text\/plain/i) || ($subctype =~ /application\/text/i)) {
                # tertiary level part is plain text; so just print out the body line by line
                unless (open(MFP, "$g_mailbox_fullpath")) {
                  mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
                }
                seek(MFP, $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_body__'}, 0);
                $endfilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_end__'};
                $buffer = "";
                while (<MFP>) {
                  $curline = $_;
                  # decode the current line
                  if ($subctenc =~ /quoted-printable/i) {
                    $string = mailmanagerDecodeQuotedPrintable($curline);
                    $buffer .= $string;
                    next if ($curline =~ /=\r?\n$/);  # keep reading the file
                  }
                  elsif ($subctenc =~ /base64/i) {
                    $buffer = mailmanagerDecode64($curline);
                  }
                  else {
                    $buffer = $curline;
                  }
                  # append the current buffer to message body
                  if ($languagepref eq "ja") {
                    $buffer = jcode'euc($buffer);
                  }
                  $buffer =~ s#\<#\&lt\;#g;
                  $buffer =~ s#\>#\&gt\;#g;
                  unless ($g_form{'print_submit'}) {
                    $buffer = mailmanagerMessageLineMarkup($buffer);
                  }
                  $buffer =~ s#^\ #\&\#160\;#;
                  $buffer =~ s#\ \ #\ \&\#160\;#g;
                  $buffer =~ s#\ +\n$#\&\#160\;\n#;
                  $buffer =~ s#\n$#<br>\n#;
                  print $buffer;
                  $buffer = "";
                  $curfilepos = tell(MFP);
                  last if ($curfilepos >= $endfilepos);
                }
                close(MFP); 
              }
              else {
                # tertiary level part must be viewed separately or in-line
                if ((($subctype =~ /image\/jpg/) || ($subctype =~ /image\/jpeg/) ||
                     ($subctype =~ /image\/jpe/) || ($subctype =~ /image\/pjpeg/) ||
                     ($subctype =~ /image\/gif/) || ($subctype =~ /image\/png/)) && 
                    (defined($g_form{'inline'})) &&
                    (($g_form{'inline'} =~ /^$messagepartid$/) ||
                     ($g_form{'inline'} =~ /^$messagepartid\|/) ||
                     ($g_form{'inline'} =~ /\|$messagepartid\|/) ||
                     ($g_form{'inline'} =~ /\|$messagepartid$/))) {
                  # show image in-line as requested
                  $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                            "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                            "messageid", encodingStringToURL($mid));
                  $encargs .= "&messagepart=$messagepartid";
                  $string = ($ENV{'HTTPS'} && ($ENV{'HTTPS'} eq "on")) ? "https://" : "http://";
                  $string .= "$ENV{'HTTP_HOST'}$ENV{'SCRIPT_NAME'}?$encargs";
                  htmlNoBR();
                  htmlImg("width", "10", "height", "1", "src", "$g_graphicslib/sp.gif");
                  $a_disp =~ s/\"/\&quot;/g;
                  htmlImg("src", "$string", "title", $a_disp);
                  htmlNoBRClose();
                  htmlBR();
                  htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
                  htmlBR();
                  unless ($g_form{'print_submit'}) {
                    print "&#160;&#160;";
                    $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                              "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                              "messageid", encodingStringToURL($mid));
                    $string = $g_form{'inline'};
                    $string =~ s/^$messagepartid$//;
                    $string =~ s/^$messagepartid\|//;
                    $string =~ s/\|$messagepartid\|//;
                    $string =~ s/\|$messagepartid$//;
                    $encargs .= "&inline=$string";
                    $string = ">>&#160;$MAILMANAGER_ATTACHMENT_HIDE_TYPE_INLINE&#160;<<";
                    ($subctype) = (split(/\;/, $subctype))[0];
                    $string =~ s/__TYPE__/$subctype/;
                    $title = $MAILMANAGER_ATTACHMENT_HIDE_INLINE_HELP;
                    $title =~ s/\s+/\ /g;
                    $title =~ s/__TYPE__/$subctype/;
                    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs", "title", $title);
                    htmlAnchorText($string);
                    htmlAnchorClose();
                    htmlBR();
                  }
                }
                elsif ($g_form{'print_submit'}) {
                  $string = "&#160;&#160;\[\[&#160;";
                  $string .= "$MAILMANAGER_ATTACHMENT_NOT_SHOWN&#160;\]\]";
                  ($subctype) = (split(/\;/, $subctype))[0];
                  $string =~ s/__TYPE__/$subctype/;
                  htmlFont("color", "#666666");
                  print "$string";
                  htmlFontClose();
                  htmlP();
                }
                unless ($g_form{'print_submit'}) {
                  if ($subctype &&
                      (($subctype =~ /image\/jpg/) || ($subctype =~ /image\/jpeg/) ||
                       ($subctype =~ /image\/jpe/) || ($subctype =~ /image\/pjpeg/) ||
                       ($subctype =~ /image\/gif/) || ($subctype =~ /image\/png/)) && 
                      (!defined($g_form{'inline'}) ||
                       (($g_form{'inline'} !~ /^$messagepartid$/) &&
                        ($g_form{'inline'} !~ /^$messagepartid\|/) &&
                        ($g_form{'inline'} !~ /\|$messagepartid\|/) &&
                        ($g_form{'inline'} !~ /\|$messagepartid$/)))) {
                    print "&#160;&#160;";
                    $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                              "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                              "messageid", encodingStringToURL($mid));
                    $encargs .= "&inline=";
                    if ($g_form{'inline'}) { 
                      $encargs .= $g_form{'inline'};
                      $encargs .= "|";
                    }
                    $encargs .= $messagepartid;
                    $string = ">>&#160;$MAILMANAGER_ATTACHMENT_VIEW_TYPE_INLINE&#160;<<";
                    ($subctype) = (split(/\;/, $subctype))[0];
                    $string =~ s/__TYPE__/$subctype/;
                    $title = $MAILMANAGER_ATTACHMENT_VIEW_INLINE_HELP;
                    $title =~ s/\s+/\ /g;
                    $title =~ s/__TYPE__/$subctype/;
                    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs", "title", $title);
                    htmlAnchorText($string);
                    htmlAnchorClose();
                    htmlBR();
                  }
                  if ($subctype =~ /message\/(.*)/i) {
                    $mtype = $1;
                    print "&#160;&#160;";
                    $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                              "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                              "selected", encodingStringToURL($mid));
                    $encargs .= "&message=$mtype";
                    $encargs .= "&messagepart=$messagepartid";
                    $string = ">>&#160;$MAILMANAGER_ATTACHMENT_VIEW_TYPE&#160;<<";
                    ($subctype) = (split(/\;/, $subctype))[0];
                    $string =~ s/__TYPE__/$subctype/;
                    $title = $MAILMANAGER_ATTACHMENT_VIEW_SEPARATELY_HELP;
                    $title =~ s/\s+/\ /g;
                    $title =~ s/__TYPE__/$subctype/;
                    htmlAnchor("href", "mm_save.cgi?$encargs", "title", $title, "onClick",
                               "openWindow('mm_save.cgi?$encargs', 700, 500); return false");
                    htmlAnchorText($string);
                    htmlAnchorClose();
                  }
                  else {
                    print "&#160;&#160;";
                    $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                              "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                              "messageid", encodingStringToURL($mid));
                    $encargs .= "&messagepart=$messagepartid";
                    $string = ">>&#160;$MAILMANAGER_ATTACHMENT_VIEW_TYPE&#160;<<";
                    ($subctype) = (split(/\;/, $subctype))[0];
                    $string =~ s/__TYPE__/$subctype/;
                    $title = $MAILMANAGER_ATTACHMENT_VIEW_SEPARATELY_HELP;
                    $title =~ s/\s+/\ /g;
                    $title =~ s/__TYPE__/$subctype/;
                    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs", "title", $title);
                    htmlAnchorText($string);
                    htmlAnchorClose();
                    if ($g_users{$g_auth{'login'}}->{'ftp'}) {
                      # save attachment option available only for 'ftp' users
                      htmlBR();
                      print "&#160;&#160;";
                      $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                                "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                                "selected", encodingStringToURL($mid));
                      $encargs .= "&messagepart=$messagepartid";
                      $string = ">>&#160;$MAILMANAGER_ATTACHMENT_SAVE_TYPE&#160;<<";
                      ($subctype) = (split(/\;/, $subctype))[0];
                      $string =~ s/__TYPE__/$subctype/;
                      $title = $MAILMANAGER_ATTACHMENT_SAVE_HELP;
                      $title =~ s/\s+/\ /g;
                      $title =~ s/__TYPE__/$subctype/;
                      htmlAnchor("href", "mm_save.cgi?$encargs", "title", $title);
                      htmlAnchorText($string);
                      htmlAnchorClose();
                    }
                  }
                  htmlP();
                }
              }
            }
            htmlImg("width", "1", "height", "2", "src", "$g_graphicslib/sp.gif");
            htmlBR();
            htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
                      "cellpadding", "0", "background", "$g_graphicslib/dotted.png");
            htmlTableRow();
            htmlTableData();
            htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
            htmlTableDataClose();
            htmlTableRowClose();
            htmlTableClose();
            htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
            htmlBR();
            htmlULClose();
          }
          elsif (($subctype =~ /text\/plain/i) || ($subctype =~ /application\/text/i)) {
            # secondary level part is plain text; so just print out the body line by line
            unless (open(MFP, "$g_mailbox_fullpath")) {
              mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
            }
            seek(MFP, $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_body__'}, 0);
            $endfilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_end__'};
            $buffer = "";
            while (<MFP>) {
              $curline = $_;
              # decode the current line
              if ($subctenc =~ /quoted-printable/i) {
                $string = mailmanagerDecodeQuotedPrintable($curline);
                $buffer .= $string;
                next if ($curline =~ /=\r?\n$/);  # keep reading the file
              }
              elsif ($subctenc =~ /base64/i) {
                $buffer = mailmanagerDecode64($curline);
              }
              else {
                $buffer = $curline;
              }
              # append the current buffer to message body
              if ($languagepref eq "ja") {
                $buffer = jcode'euc($buffer);
              }
              $buffer =~ s#\<#\&lt\;#g;
              $buffer =~ s#\>#\&gt\;#g;
              unless ($g_form{'print_submit'}) {
                $buffer = mailmanagerMessageLineMarkup($buffer);
              }
              $buffer =~ s#^\ #\&\#160\;#;
              $buffer =~ s#\ \ #\ \&\#160\;#g;
              $buffer =~ s#\ +\n$#\&\#160\;\n#;
              $buffer =~ s#\n$#<br>\n#;
              print $buffer;
              $buffer = "";
              $curfilepos = tell(MFP);
              last if ($curfilepos >= $endfilepos);
            }
            close(MFP); 
          }
          else {
            # secondary level part must be viewed separately or in-line
            if ((($subctype =~ /image\/jpg/) || ($subctype =~ /image\/jpeg/) ||
                 ($subctype =~ /image\/jpe/) || ($subctype =~ /image\/pjpeg/) ||
                 ($subctype =~ /image\/gif/) || ($subctype =~ /image\/png/)) && 
                (defined($g_form{'inline'})) &&
                (($g_form{'inline'} =~ /^$messagepartid$/) ||
                 ($g_form{'inline'} =~ /^$messagepartid\|/) ||
                 ($g_form{'inline'} =~ /\|$messagepartid\|/) ||
                 ($g_form{'inline'} =~ /\|$messagepartid$/))) {
              # show image in-line as requested
              $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                        "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                        "messageid", encodingStringToURL($mid));
              $encargs .= "&messagepart=$messagepartid";
              $string = ($ENV{'HTTPS'} && ($ENV{'HTTPS'} eq "on")) ? "https://" : "http://";
              $string .= "$ENV{'HTTP_HOST'}$ENV{'SCRIPT_NAME'}?$encargs";
              htmlNoBR();
              htmlImg("width", "10", "height", "1", "src", "$g_graphicslib/sp.gif");
              $a_disp =~ s/\"/\&quot;/g;
              htmlImg("src", "$string", "title", $a_disp);
              htmlNoBRClose();
              htmlBR();
              htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
              htmlBR();
              unless ($g_form{'print_submit'}) {
                print "&#160;&#160;";
                $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                          "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                          "messageid", encodingStringToURL($mid));
                $string = $g_form{'inline'};
                $string =~ s/^$messagepartid$//;
                $string =~ s/^$messagepartid\|//;
                $string =~ s/\|$messagepartid\|//;
                $string =~ s/\|$messagepartid$//;
                $encargs .= "&inline=$string";
                $string = ">>&#160;$MAILMANAGER_ATTACHMENT_HIDE_TYPE_INLINE&#160;<<";
                ($subctype) = (split(/\;/, $subctype))[0];
                $string =~ s/__TYPE__/$subctype/;
                $title = $MAILMANAGER_ATTACHMENT_HIDE_INLINE_HELP;
                $title =~ s/\s+/\ /g;
                $title =~ s/__TYPE__/$subctype/;
                htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs", "title", $title);
                htmlAnchorText($string);
                htmlAnchorClose();
                htmlBR();
              }
            }
            elsif ($g_form{'print_submit'}) {
              $string = "&#160;&#160;\[\[&#160;";
              $string .= "$MAILMANAGER_ATTACHMENT_NOT_SHOWN&#160;\]\]";
              ($subctype) = (split(/\;/, $subctype))[0];
              $string =~ s/__TYPE__/$subctype/;
              htmlFont("color", "#666666");
              print "$string";
              htmlFontClose();
              htmlP();
            }
            unless ($g_form{'print_submit'}) {
              if ($subctype &&
                  (($subctype =~ /image\/jpg/) || ($subctype =~ /image\/jpeg/) ||
                   ($subctype =~ /image\/jpe/) || ($subctype =~ /image\/pjpeg/) ||
                   ($subctype =~ /image\/gif/) || ($subctype =~ /image\/png/)) && 
                  (!defined($g_form{'inline'}) ||
                   (($g_form{'inline'} !~ /^$messagepartid$/) &&
                    ($g_form{'inline'} !~ /^$messagepartid\|/) &&
                    ($g_form{'inline'} !~ /\|$messagepartid\|/) &&
                    ($g_form{'inline'} !~ /\|$messagepartid$/)))) {
                print "&#160;&#160;";
                $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                          "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                          "messageid", encodingStringToURL($mid));
                $encargs .= "&inline=";
                if ($g_form{'inline'}) {
                  $encargs .= $g_form{'inline'};
                  $encargs .= "|";
                }
                $encargs .= $messagepartid;
                $string = ">>&#160;$MAILMANAGER_ATTACHMENT_VIEW_TYPE_INLINE&#160;<<";
                ($subctype) = (split(/\;/, $subctype))[0];
                $string =~ s/__TYPE__/$subctype/;
                $title = $MAILMANAGER_ATTACHMENT_VIEW_INLINE_HELP;
                $title =~ s/\s+/\ /g;
                $title =~ s/__TYPE__/$subctype/;
                htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs", "title", $title);
                htmlAnchorText($string);
                htmlAnchorClose();
                htmlBR();
              }
              if ($subctype =~ /message\/(.*)/i) {
                $mtype = $1;
                print "&#160;&#160;";
                $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                          "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                          "selected", encodingStringToURL($mid));
                $encargs .= "&message=$mtype";
                $encargs .= "&messagepart=$messagepartid";
                $string = ">>&#160;$MAILMANAGER_ATTACHMENT_VIEW_TYPE&#160;<<";
                ($subctype) = (split(/\;/, $subctype))[0];
                $string =~ s/__TYPE__/$subctype/;
                $title = $MAILMANAGER_ATTACHMENT_VIEW_SEPARATELY_HELP;
                $title =~ s/\s+/\ /g;
                $title =~ s/__TYPE__/$subctype/;
                htmlAnchor("href", "mm_save.cgi?$encargs", "title", $title, "onClick",
                           "openWindow('mm_save.cgi?$encargs', 700, 500); return false");
                htmlAnchorText($string);
                htmlAnchorClose();
              }
              else {
                print "&#160;&#160;";
                $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                          "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                          "messageid", encodingStringToURL($mid));
                $encargs .= "&messagepart=$messagepartid";
                $string = ">>&#160;$MAILMANAGER_ATTACHMENT_VIEW_TYPE&#160;<<";
                ($subctype) = (split(/\;/, $subctype))[0];
                $string =~ s/__TYPE__/$subctype/;
                $title = $MAILMANAGER_ATTACHMENT_VIEW_SEPARATELY_HELP;
                $title =~ s/\s+/\ /g;
                $title =~ s/__TYPE__/$subctype/;
                htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs", "title", $title);
                htmlAnchorText($string);
                htmlAnchorClose();
                if ($g_users{$g_auth{'login'}}->{'ftp'}) {
                  # save attachment option available only for 'ftp' users
                  htmlBR();
                  print "&#160;&#160;";
                  $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                            "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                            "selected", encodingStringToURL($mid));
                  $encargs .= "&messagepart=$messagepartid";
                  $string = ">>&#160;$MAILMANAGER_ATTACHMENT_SAVE_TYPE&#160;<<";
                  ($subctype) = (split(/\;/, $subctype))[0];
                  $string =~ s/__TYPE__/$subctype/;
                  $title = $MAILMANAGER_ATTACHMENT_SAVE_HELP;
                  $title =~ s/\s+/\ /g;
                  $title =~ s/__TYPE__/$subctype/;
                  htmlAnchor("href", "mm_save.cgi?$encargs", "title", $title);
                  htmlAnchorText($string);
                  htmlAnchorClose();
                }
              }
              htmlP();
            }
          }
        }
        htmlImg("width", "1", "height", "2", "src", "$g_graphicslib/sp.gif");
        htmlBR();
        htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
                  "cellpadding", "0", "background", "$g_graphicslib/dotted.png");
        htmlTableRow();
        htmlTableData();
        htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
        htmlTableDataClose();
        htmlTableRowClose();
        htmlTableClose();
        htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
        htmlBR();
        htmlULClose();
      }
      elsif ($ctype && 
             ($ctype !~ /text\/plain/i) && ($ctype !~ /aplication\/text/i)) {
        # no secondary message parts, but not just plain text...
        # must view separately or inline (upon request)
        if ((($ctype =~ /image\/jpg/) || ($ctype =~ /image\/jpeg/) ||
             ($ctype =~ /image\/jpe/) || ($ctype =~ /image\/pjpeg/) ||
             ($ctype =~ /image\/gif/) || ($ctype =~ /image\/png/)) && 
            (defined($g_form{'inline'})) &&
            (($g_form{'inline'} =~ /^$messagepartid$/) ||
             ($g_form{'inline'} =~ /^$messagepartid\|/) ||
             ($g_form{'inline'} =~ /\|$messagepartid\|/) ||
             ($g_form{'inline'} =~ /\|$messagepartid$/))) {
          # show image in-line as requested
          $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                    "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                    "messageid", encodingStringToURL($mid));
          $encargs .= "&messagepart=$messagepartid";
          $string = ($ENV{'HTTPS'} && ($ENV{'HTTPS'} eq "on")) ? "https://" : "http://";
          $string .= "$ENV{'HTTP_HOST'}$ENV{'SCRIPT_NAME'}?$encargs";
          htmlNoBR();
          htmlImg("width", "10", "height", "1", "src", "$g_graphicslib/sp.gif");
          $a_disp =~ s/\"/\&quot;/g;
          htmlImg("src", "$string", "title", $a_disp);
          htmlNoBRClose();
          htmlBR();
          htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
          htmlBR();
          unless ($g_form{'print_submit'}) {
            print "&#160;&#160;";
            $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                      "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                      "messageid", encodingStringToURL($mid));
            $string = $g_form{'inline'};
            $string =~ s/^$messagepartid$//;
            $string =~ s/^$messagepartid\|//;
            $string =~ s/\|$messagepartid\|//;
            $string =~ s/\|$messagepartid$//;
            $encargs .= "&inline=$string";
            $string = ">>&#160;$MAILMANAGER_ATTACHMENT_HIDE_TYPE_INLINE&#160;<<";
            ($ctype) = (split(/\;/, $ctype))[0];
            $string =~ s/__TYPE__/$ctype/;
            $title = $MAILMANAGER_ATTACHMENT_HIDE_INLINE_HELP;
            $title =~ s/\s+/\ /g;
            $title =~ s/__TYPE__/$ctype/;
            htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs", "title", $title);
            htmlAnchorText($string);
            htmlAnchorClose();
            htmlBR();
          }
        }
        elsif ($g_form{'print_submit'}) {
          $string = "&#160;&#160;\[\[&#160;";
          $string .= "$MAILMANAGER_ATTACHMENT_NOT_SHOWN&#160;\]\]";
          ($ctype) = (split(/\;/, $ctype))[0];
          $string =~ s/__TYPE__/$ctype/;
          htmlFont("color", "#666666");
          print "$string";
          htmlFontClose();
          htmlP();
        }
        unless ($g_form{'print_submit'}) {
          if ($ctype &&
              (($ctype =~ /image\/jpg/) || ($ctype =~ /image\/jpeg/) ||
               ($ctype =~ /image\/jpe/) || ($ctype =~ /image\/pjpeg/) ||
               ($ctype =~ /image\/gif/) || ($ctype =~ /image\/png/)) && 
              (!defined($g_form{'inline'}) ||
               (($g_form{'inline'} !~ /^$messagepartid$/) &&
                ($g_form{'inline'} !~ /^$messagepartid\|/) &&
                ($g_form{'inline'} !~ /\|$messagepartid\|/) &&
                ($g_form{'inline'} !~ /\|$messagepartid$/)))) {
            print "&#160;&#160;";
            $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                      "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                      "messageid", encodingStringToURL($mid));
            $encargs .= "&inline=";
            if ($g_form{'inline'}) { 
              $encargs .= $g_form{'inline'};
              $encargs .= "|";
            }
            $encargs .= $messagepartid;
            $string = ">>&#160;$MAILMANAGER_ATTACHMENT_VIEW_TYPE_INLINE&#160;<<";
            ($ctype) = (split(/\;/, $ctype))[0];
            $string =~ s/__TYPE__/$ctype/;
            $title = $MAILMANAGER_ATTACHMENT_VIEW_INLINE_HELP;
            $title =~ s/\s+/\ /g;
            $title =~ s/__TYPE__/$ctype/;
            htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs", "title", $title);
            htmlAnchorText($string);
            htmlAnchorClose();
            htmlBR();
          }
          if ($ctype =~ /message\/(.*)/i) {
            $mtype = $1;
            print "&#160;&#160;";
            $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                      "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                      "selected", encodingStringToURL($mid));
            $encargs .= "&message=$mtype";
            $encargs .= "&messagepart=$messagepartid";
            $string = ">>&#160;$MAILMANAGER_ATTACHMENT_VIEW_TYPE&#160;<<";
            ($ctype) = (split(/\;/, $ctype))[0];
            $string =~ s/__TYPE__/$ctype/;
            $title = $MAILMANAGER_ATTACHMENT_VIEW_SEPARATELY_HELP;
            $title =~ s/\s+/\ /g;
            $title =~ s/__TYPE__/$ctype/;
            htmlAnchor("href", "mm_save.cgi?$encargs", "title", $title, "onClick",
                       "openWindow('mm_save.cgi?$encargs', 700, 500); return false");
            htmlAnchorText($string);
            htmlAnchorClose();
          }
          else {
            print "&#160;&#160;";
            $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                      "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                      "messageid", encodingStringToURL($mid));
            $encargs .= "&messagepart=$messagepartid";
            $string = ">>&#160;$MAILMANAGER_ATTACHMENT_VIEW_TYPE&#160;<<";
            ($ctype) = (split(/\;/, $ctype))[0];
            $string =~ s/__TYPE__/$ctype/;
            $title = $MAILMANAGER_ATTACHMENT_VIEW_SEPARATELY_HELP;
            $title =~ s/\s+/\ /g;
            $title =~ s/__TYPE__/$ctype/;
            htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs", "title", $title);
            htmlAnchorText($string);
            htmlAnchorClose();
            if ($g_users{$g_auth{'login'}}->{'ftp'}) {
              # save attachment option available only for 'ftp' users
              htmlBR();
              print "&#160;&#160;";
              $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                        "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                        "selected", encodingStringToURL($mid));
              $encargs .= "&messagepart=$messagepartid";
              $string = ">>&#160;$MAILMANAGER_ATTACHMENT_SAVE_TYPE&#160;<<";
              ($ctype) = (split(/\;/, $ctype))[0];
              $string =~ s/__TYPE__/$ctype/;
              $title = $MAILMANAGER_ATTACHMENT_SAVE_HELP;
              $title =~ s/\s+/\ /g;
              $title =~ s/__TYPE__/$ctype/;
              htmlAnchor("href", "mm_save.cgi?$encargs", "title", $title);
              htmlAnchorText($string);
              htmlAnchorClose();
            }
          }
          htmlP();
        }
      }
      else {
        # no message parts, and just a plain text message
        # just print out the body of the message part line by line
        unless (open(MFP, "$g_mailbox_fullpath")) {
          mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
        }
        seek(MFP, $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_body__'}, 0);
        $endfilepos = $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_end__'};
        $buffer = "";
        while (<MFP>) {
          $curline = $_;
          # decode the current line
          if ($ctenc =~ /quoted-printable/i) {
            $string = mailmanagerDecodeQuotedPrintable($curline);
            $buffer .= $string;
            next if ($curline =~ /=\r?\n$/);  # keep reading the file
          }
          elsif ($ctenc =~ /base64/i) {
            $buffer = mailmanagerDecode64($curline);
          }
          else {
            $buffer = $curline;
          }
          # append the current buffer to message body
          if ($languagepref eq "ja") {
            $buffer = jcode'euc($buffer);
          }
          $buffer =~ s#\<#\&lt\;#g;
          $buffer =~ s#\>#\&gt\;#g;
          unless ($g_form{'print_submit'}) {
            $buffer = mailmanagerMessageLineMarkup($buffer);
          }
          $buffer =~ s#^\ #\&\#160\;#;
          $buffer =~ s#\ \ #\ \&\#160\;#g;
          $buffer =~ s#\ +\n$#\&\#160\;\n#;
          $buffer =~ s#\n$#<br>\n#;
          print $buffer;
          $buffer = "";
          $curfilepos = tell(MFP);
          last if ($curfilepos >= $endfilepos);
        }
        close(MFP); 
      }
    }
    htmlImg("width", "1", "height", "2", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
              "cellpadding", "0", "background", "$g_graphicslib/dotted.png");
    htmlTableRow();
    htmlTableData();
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlBR();
  }
  elsif ($ctype && 
         ($ctype !~ /text\/plain/i) && ($ctype !~ /application\/text/i)) {
    # no parts, but not just plain text; can view in-line or separately
    if ((($ctype =~ /image\/jpg/) || ($ctype =~ /image\/jpeg/) ||
         ($ctype =~ /image\/jpe/) || ($ctype =~ /image\/pjpeg/) ||
         ($ctype =~ /image\/gif/) || ($ctype =~ /image\/png/)) && 
        (defined($g_form{'inline'})) &&
        (($g_form{'inline'} =~ /^$messagepartid$/) ||
         ($g_form{'inline'} =~ /^$messagepartid\|/) ||
         ($g_form{'inline'} =~ /\|$messagepartid\|/) ||
         ($g_form{'inline'} =~ /\|$messagepartid$/))) {
      # show image in-line as requested
      $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                "messageid", encodingStringToURL($mid));
      $encargs .= "&messagepart=$messagepartid";
      $string = ($ENV{'HTTPS'} && ($ENV{'HTTPS'} eq "on")) ? "https://" : "http://";
      $string .= "$ENV{'HTTP_HOST'}$ENV{'SCRIPT_NAME'}?$encargs";
      htmlNoBR();
      htmlImg("width", "10", "height", "1", "src", "$g_graphicslib/sp.gif");
      htmlImg("src", "$string");
      htmlNoBRClose();
      htmlBR();
      htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
      htmlBR();
      unless ($g_form{'print_submit'}) {
        print "&#160;&#160;";
        $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                  "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                  "messageid", encodingStringToURL($mid));
        $string = $g_form{'inline'};
        $string =~ s/^$messagepartid$//;
        $string =~ s/^$messagepartid\|//;
        $string =~ s/\|$messagepartid\|//;
        $string =~ s/\|$messagepartid$//;
        $encargs .= "&inline=$string";
        $string = ">>&#160;$MAILMANAGER_MESSAGE_HIDE_TYPE_INLINE&#160;<<";
        ($subctype) = (split(/\;/, $subctype))[0];
        $string =~ s/__TYPE__/$subctype/;
        $title = $MAILMANAGER_MESSAGE_HIDE_INLINE_HELP;
        $title =~ s/\s+/\ /g;
        $title =~ s/__TYPE__/$subctype/;
        htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs", "title", $title);
        htmlAnchorText($string);
        htmlAnchorClose();
        htmlBR();
      }
    }
    elsif ($g_form{'print_submit'}) {
      $string = "&#160;&#160;\[\[&#160;";
      $string .= "$MAILMANAGER_MESSAGE_NOT_SHOWN&#160;\]\]";
      ($ctype) = (split(/\;/, $ctype))[0];
      $string =~ s/__TYPE__/$ctype/;
      htmlFont("color", "#666666");
      print "$string";
      htmlFontClose();
      htmlP();
    }
    unless ($g_form{'print_submit'}) {
      if ($ctype &&
          (($ctype =~ /image\/jpg/) || ($ctype =~ /image\/jpeg/) ||
           ($ctype =~ /image\/jpe/) || ($ctype =~ /image\/pjpeg/) ||
           ($ctype =~ /image\/gif/) || ($ctype =~ /image\/png/)) && 
          (!defined($g_form{'inline'}) ||
           (($g_form{'inline'} !~ /^$messagepartid$/) &&
            ($g_form{'inline'} !~ /^$messagepartid\|/) &&
            ($g_form{'inline'} !~ /\|$messagepartid\|/) &&
            ($g_form{'inline'} !~ /\|$messagepartid$/)))) {
        print "&#160;&#160;";
        $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                  "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                  "messageid", encodingStringToURL($mid));
        $encargs .= "&inline=";
        if ($g_form{'inline'}) { 
          $encargs .= $g_form{'inline'};
          $encargs .= "|";
        }
        $encargs .= $messagepartid;
        $string = ">>&#160;$MAILMANAGER_ATTACHMENT_VIEW_TYPE_INLINE&#160;<<";
        ($ctype) = (split(/\;/, $ctype))[0];
        $string =~ s/__TYPE__/$ctype/;
        $title = $MAILMANAGER_ATTACHMENT_VIEW_INLINE_HELP;
        $title =~ s/\s+/\ /g;
        $title =~ s/__TYPE__/$ctype/;
        htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs", "title", $title);
        htmlAnchorText($string);
        htmlAnchorClose();
        htmlBR();
      }
      print "&#160;&#160;";
      $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                "messageid", encodingStringToURL($mid));
      $encargs .= "&messagepart=$messagepartid";
      $string = ">>&#160;$MAILMANAGER_MESSAGE_VIEW_TYPE&#160;<<";
      ($ctype) = (split(/\;/, $ctype))[0];
      $string =~ s/__TYPE__/$ctype/;
      $title = $MAILMANAGER_MESSAGE_VIEW_SEPARATELY_HELP;
      $title =~ s/\s+/\ /g;
      $title =~ s/__TYPE__/$ctype/;
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs", "title", $title);
      htmlAnchorText($string);
      htmlAnchorClose();
      if ($g_users{$g_auth{'login'}}->{'ftp'}) {
        htmlBR();
        # save message body option available only for 'ftp' users
        print "&#160;&#160;";
        $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                  "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                  "selected", encodingStringToURL($mid));
        $encargs .= "&messagepart=$messagepartid";
        $string = ">>&#160;$MAILMANAGER_MESSAGE_SAVE_TYPE&#160;<<";
        ($ctype) = (split(/\;/, $ctype))[0];
        $string =~ s/__TYPE__/$ctype/;
        $title = $MAILMANAGER_MESSAGE_SAVE_HELP;
        $title =~ s/\s+/\ /g;
        $title =~ s/__TYPE__/$ctype/;
        htmlAnchor("href", "mm_save.cgi?$encargs", "title", $title);
        htmlAnchorText($string);
        htmlAnchorClose();
      }
      htmlP();
    }
  }
  else {
    # no parts, and just a plain text message; so just print out the body 
    # of the message line by line
    unless (open(MFP, "$g_mailbox_fullpath")) {
      mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
    }
    seek(MFP, $g_email{$mid}->{'__filepos_message_body__'}, 0);
    $endfilepos = $g_email{$mid}->{'__filepos_message_end__'};
    $buffer = "";
    while (<MFP>) {
      $curline = $_;
      # decode the current line
      if ($ctenc =~ /quoted-printable/i) {
        $string = mailmanagerDecodeQuotedPrintable($curline);
        $buffer .= $string;
        next if ($curline =~ /=\r?\n$/);  # keep reading the file
      }
      elsif ($ctenc =~ /base64/i) {
        $buffer = mailmanagerDecode64($curline);
      }
      else {
        $buffer = $curline;
      }
      # append the current buffer to message body
      if ($languagepref eq "ja") {
        $buffer = jcode'euc($buffer);
      }
      $buffer =~ s#\<#\&lt\;#g;
      $buffer =~ s#\>#\&gt\;#g;
      unless ($g_form{'print_submit'}) {
        $buffer = mailmanagerMessageLineMarkup($buffer);
      }
      $buffer =~ s#^\ #\&\#160\;#;
      $buffer =~ s#\ \ #\ \&\#160\;#g;
      $buffer =~ s#\ +\n$#\&\#160\;\n#;
      $buffer =~ s#\n$#<br>\n#;
      print $buffer;
      $buffer = "";
      $curfilepos = tell(MFP);
      last if ($curfilepos >= $endfilepos);
    }
    close(MFP); 
  }
  htmlFontClose();
  htmlP();

  unless ($g_form{'print_submit'}) {
    # printer friendly format button
    formOpen("method", "POST");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
    formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
    formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
    formInput("type", "hidden", "name", "inline", "value", $g_form{'inline'});
    formInput("type", "hidden", "name", "messageid", "value", $mid);
    if ($g_form{'rawheaders'} && ($g_form{'rawheaders'} eq "yes")) {
      formInput("type", "hidden", "name", "rawheaders", "value", "yes");
    }
    htmlText("&#160;&#160;");
    formInput("type", "submit", "name", "print_submit", "value",
              $MAILMANAGER_PRINTER_FRIENDLY_FORMAT);
    formClose();
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
  }

  if (($g_form{'print_submit'}) || mailmanagerIsTmpMessage()) {
    htmlBodyClose();
    htmlHtmlClose();
  }
  else {
    # end message encapsulation table
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    # separator
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "bgcolor", "#000000", "width", "100\%");
    htmlTableRow();
    htmlTableData();
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    # mail folder and actions
    htmlTable();
    htmlTableRow();
    htmlTableData();
    htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableData("valign", "top");
    htmlTextBold("$MAILMANAGER_FOLDER_NAME\:&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top");
    $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                              "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}");
    $title = $MAILMANAGER_FOLDER_OPEN;
    $title =~ s/__FOLDER__/$g_mailbox_virtualpath/;
    htmlAnchor("href", "mailmanager.cgi?$encargs", "title", $title);
    htmlAnchorText($g_mailbox_virtualpath);
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableData("valign", "top", "rowspan", "3");
    $len = length($g_mailbox_virtualpath); 
    $string = "&#160; " x (($len > 25) ? 4 : 10);
    htmlText($string);
    htmlTextBold("$MAILMANAGER_ACTIONS\:&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top", "rowspan", "3");
    $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                              "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                              "messageid", encodingStringToURL($mid));
    htmlAnchor("href", "mm_bounce.cgi?$encargs",
               "title", $MAILMANAGER_BOUNCE);
    htmlAnchorText($MAILMANAGER_BOUNCE);
    htmlAnchorClose();
    htmlBR();
    htmlAnchor("href", "mm_compose.cgi?type=forward&$encargs",
               "title", $MAILMANAGER_FORWARD);
    htmlAnchorText($MAILMANAGER_FORWARD);
    htmlAnchorClose();
    htmlBR();
    htmlAnchor("href", "mm_compose.cgi?type=reply&$encargs",
               "title", $MAILMANAGER_REPLY);
    htmlAnchorText($MAILMANAGER_REPLY);
    htmlAnchorClose();
    htmlBR();
    htmlAnchor("href", "mm_compose.cgi?type=groupreply&$encargs",
               "title", $MAILMANAGER_REPLY_GROUP);
    htmlAnchorText($MAILMANAGER_REPLY_GROUP);
    htmlAnchorClose();
    htmlBR();
    $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                              "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                              "selected", encodingStringToURL($mid));
    if ((($g_users{$g_auth{'login'}}->{'ftp'}) ||
         ($g_users{$g_auth{'login'}}->{'imap'})) &&
        ($g_users{$g_auth{'login'}}->{'mail_access_level'} eq "full")) {
      htmlAnchor("href", "mm_save.cgi?$encargs&rfs=yes",
                 "title", $MAILMANAGER_SAVE_SINGLE);
      htmlAnchorText($MAILMANAGER_SAVE_SINGLE);
      htmlAnchorClose(); 
      htmlBR();
    }
    htmlAnchor("href", "mm_delete.cgi?$encargs",
               "title", $MAILMANAGER_DELETE_SINGLE);
    htmlAnchorText($MAILMANAGER_DELETE_SINGLE);
    htmlAnchorClose();
    htmlBR();
    htmlImg("width", "1", "height", "3", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlTableDataClose();
    htmlTableRowClose();
    # message number
    htmlTableRow();
    htmlTableData();
    htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableData("valign", "top");
    htmlTextBold("$MAILMANAGER_MESSAGE_NUMBER\:&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top");
    if ($g_form{'msort'} eq "in_order") {
      htmlText("$msgslot");
    }
    else {
      htmlText("$msgslot/$msgcount");
    }
    htmlTableDataClose();
    htmlTableRowClose();
    # message size
    htmlTableRow();
    htmlTableData();
    htmlImg("width", "5", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableData("valign", "top");
    htmlTextBold("$MAILMANAGER_MESSAGE_SIZE\:&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top");
    htmlText($sizetext);
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    if ($prevmid || $nextmid) {
      htmlTable("width", "100\%", "border", "0", "cellspacing", "0",
                "cellpadding", "0", "bgcolor", "#000000");
      htmlTableRow();
      htmlTableData("bgcolor", "#000000");
      htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlTable("cellpadding", "2", "cellspacing", "0",
                "border", "0", "width", "100\%", "bgcolor", "#cccccc");
      htmlTableRow();
      htmlTableData("align", "left", "valign", "middle");
      if ($prevmid) {
        htmlTextSmallBold("<<&#160;");
        $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                  "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                  "messageid", encodingStringToURL($previd));
        $title = $MAILMANAGER_VIEW_PREV_TITLE;
        if ($g_form{'msort'} ne "in_order") {
          $title .= "...\n";
          ($mdate, $mfrom, $msubject, $msize) = 
                   (mailmanagerMailboxCacheGetMessageInfo($prevmid))[2,3,4,5];
          $string = dateLocalizeTimeString($mdate);
          $title .= "$MAILMANAGER_MESSAGE_DATE\: $string\n";
          if ($languagepref eq "ja") {
            $mfrom = mailmanagerMimeDecodeHeaderJP_QP($mfrom);
            $mfrom = jcode'euc(mimedecode($mfrom));
          }
          $mfrom = mailmanagerMimeDecodeHeader($mfrom);
          $title .= "$MAILMANAGER_MESSAGE_SENDER\: $mfrom\n";
          if ($msubject) {
            if ($languagepref eq "ja") {
              $msubject = mailmanagerMimeDecodeHeaderJP_QP($msubject);
              $msubject = jcode'euc(mimedecode($msubject));
            }
            $msubject = mailmanagerMimeDecodeHeader($msubject);
          }
          else {
            $msubject = $MAILMANAGER_NO_SUBJECT;
          }
          $title .= "$MAILMANAGER_MESSAGE_SUBJECT\: $msubject\n";
          if ($msize < 1024) {
            $sizetext = sprintf("%s $BYTES", $msize);
          }
          elsif ($msize < 1048576) {
            $sizetext = sprintf("%1.1f $KILOBYTES", ($msize / 1024));
          }
          else {
            $sizetext = sprintf("%1.2f $MEGABYTES", ($msize / 1048576));
          }
          $title .= "$MAILMANAGER_MESSAGE_SIZE_ABBREVIATED\: $sizetext";
        }
        htmlAnchor("style", "color:#3333cc", "title", $title,
                   "href", "$ENV{'SCRIPT_NAME'}?$encargs");
        htmlTextSmall($MAILMANAGER_VIEW_PREV);
        htmlAnchorClose();
      }
      else {
        htmlTextSmallBold("&#160;");
      }
      htmlTableDataClose();
      htmlTableData("align", "right", "valign", "middle");
      if ($nextmid) {
        $encargs = htmlAnchorArgs("mbox", $encpath, "mpos", $g_form{'mpos'},
                                  "mrange", $g_form{'mrange'}, "msort", "$g_form{'msort'}",
                                  "messageid", encodingStringToURL($nextid));
        $title = $MAILMANAGER_VIEW_NEXT_TITLE;
        if ($g_form{'msort'} ne "in_order") {
          $title .= "...\n";
          ($mdate, $mfrom, $msubject, $msize) = 
                   (mailmanagerMailboxCacheGetMessageInfo($nextmid))[2,3,4,5];
          $string = dateLocalizeTimeString($mdate);
          $title .= "$MAILMANAGER_MESSAGE_DATE\: $string\n";
          if ($languagepref eq "ja") {
            $mfrom = mailmanagerMimeDecodeHeaderJP_QP($mfrom);
            $mfrom = jcode'euc(mimedecode($mfrom));
          }
          $mfrom = mailmanagerMimeDecodeHeader($mfrom);
          $title .= "$MAILMANAGER_MESSAGE_SENDER\: $mfrom\n";
          if ($msubject) {
            if ($languagepref eq "ja") {
              $msubject = mailmanagerMimeDecodeHeaderJP_QP($msubject);
              $msubject = jcode'euc(mimedecode($msubject));
            }
            $msubject = mailmanagerMimeDecodeHeader($msubject);
          }
          else {
            $msubject = $MAILMANAGER_NO_SUBJECT;
          }
          $title .= "$MAILMANAGER_MESSAGE_SUBJECT\: $msubject\n";
          if ($msize < 1024) {
            $sizetext = sprintf("%s $BYTES", $msize);
          }
          elsif ($msize < 1048576) {
            $sizetext = sprintf("%1.1f $KILOBYTES", ($msize / 1024));
          }
          else {
            $sizetext = sprintf("%1.2f $MEGABYTES", ($msize / 1048576));
          }
          $title .= "$MAILMANAGER_MESSAGE_SIZE_ABBREVIATED\: $sizetext";
        }
        htmlAnchor("style", "color:#3333cc", "title", $title,
                   "href", "$ENV{'SCRIPT_NAME'}?$encargs");
        htmlTextSmall($MAILMANAGER_VIEW_NEXT);
        htmlAnchorClose();
      }
      else {
        htmlTextSmallBold("&#160;");
      }
      htmlTextSmallBold("&#160;>>");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
    }
    #
    # end contents table cell
    #
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    #
    # end mail message table
    #
    htmlP();
    labelCustomFooter();
  }

  # update the message status flag
  mailmanagerUpdateMessageStatusFlag("RO");

  exit(0);
}

##############################################################################

sub mailmanagerShowMessagePart
{
  local($mid, $pci, $spci, $tpci, $ctype, $cdisp, $ctenc);
  local($fname, $fsize, $languagepref, $code);
  local($bfilepos, $efilepos, $curfilepos, $chref);
  local($string, $curline, $buffer);

  $mid = $g_form{'messageid'};
  ($pci,$spci,$tpci) = split(/\./, $g_form{'messagepart'});

  $languagepref = encodingGetLanguagePreference();

  # content-id href
  $encargs = htmlAnchorArgs("mbox", encodingStringToURL($g_form{'mbox'}), "mpos", $g_form{'mpos'},
                            "mrange", $g_form{'mrange'}, "msort", $g_form{'msort'},
                            "messageid", encodingStringToURL($g_form{'messageid'}));
  $encargs .= "&messagepart=";
  $chref = ($ENV{'HTTPS'} && ($ENV{'HTTPS'} eq "on")) ? "https://" : "http://";
  $chref .= "$ENV{'HTTP_HOST'}$ENV{'SCRIPT_NAME'}?$encargs";

  if ($pci == -1) {
    $ctype = $g_email{$mid}->{'content-type'};
    $cdisp = $g_email{$mid}->{'content-disposition'};
    $ctenc = $g_email{$mid}->{'content-transfer-encoding'};
    $bfilepos = $g_email{$mid}->{'__filepos_message_body__'};
    $efilepos = $g_email{$mid}->{'__filepos_message_end__'};
  } 
  elsif (!$spci) {
    $pci--;
    $ctype = $g_email{$mid}->{'parts'}[$pci]->{'content-type'};
    $cdisp = $g_email{$mid}->{'parts'}[$pci]->{'content-disposition'};
    $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'content-transfer-encoding'};
    $bfilepos = $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_body__'};
    $efilepos = $g_email{$mid}->{'parts'}[$pci]->{'__filepos_part_end__'};
  }
  elsif (!$tpci) {
    $pci--;
    $spci--;
    $ctype = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-type'};
    $cdisp = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-disposition'};
    $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'content-transfer-encoding'};
    $bfilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_body__'};
    $efilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'__filepos_part_end__'};
  }
  else {
    $pci--;
    $spci--;
    $tpci--;
    $ctype = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-type'};
    $cdisp = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-disposition'};
    $ctenc = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'content-transfer-encoding'};
    $bfilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_body__'};
    $efilepos = $g_email{$mid}->{'parts'}[$pci]->{'sparts'}[$spci]->{'tparts'}[$tpci]->{'__filepos_part_end__'};
  }

  # figure out what filename should be sent
  if ($cdisp && ($cdisp =~ /filename=\"(.*)\"/)) {
    $fname = $1;
  }
  elsif ($cdisp && ($cdisp =~ /filename=(.*)/)) {
    $fname = $1;
  }
  elsif ($ctype && ($ctype =~ /name=\"(.*)\"/)) {
    $fname = $1;
  }
  elsif ($ctype && ($ctype =~ /name=(.*)/)) {
    $fname = $1;
  }
  elsif ($ctype =~ /(\w*?)\/(\w*)/) {
    $fname = $1 . "." . $2;
    $fname =~ s/plain$/txt/;
  }
  else {
    $fname = "attachment." . $pci; 
    $fname .= "-" . $spci if ($spci);
  }
  if ($languagepref eq "ja") {
    $fname = mailmanagerMimeDecodeHeaderJP_QP($fname);
    $code = jcode'getcode($fname);
    if ($code eq "jis") {
      $fname = jcode::convert(\$fname, 'sjis', 'jis');
    }
    else {
      $fname = jcode'sjis(mimedecode($fname));
    }
  }

  # tweak the content type a wee bit if applicable
  $ctype .= "; name=\"$fname\"" if ($ctype !~ /name=/);

  # print out the response header
  htmlResponseHeader("Content-type: $ctype; name=\"$fname\"",
                     "Content-Disposition: attachment; filename=\"$fname\"");

  # print out the data
  unless (open(MFP, "$g_mailbox_fullpath")) {
    mailmanagerResourceError("open(MFP, $g_mailbox_virtualpath)");
  }
  seek(MFP, $bfilepos, 0);
  $buffer = "";
  while (<MFP>) {
    $curline = $_;
    # decode the current line
    if ($ctenc =~ /quoted-printable/i) {
      $string = mailmanagerDecodeQuotedPrintable($curline);
      $buffer .= $string;
      next if ($curline =~ /=\r?\n$/);  # keep reading the file
    }
    elsif ($ctenc =~ /base64/i) { 
      $buffer = mailmanagerDecode64($curline);
    }
    else {
      $buffer = $curline;
    }
    # print out the current buffer
    if (($ctype =~ /text\//i) || ($ctype =~ /application\/text/i)) {
      # plain text ... markup as required
      $buffer =~ s/src=\"cid:(.*?)\"/src=\"$chref$g_email{$mid}->{'content-id'}->{$1}\"/ig;
      $buffer =~ s/src=cid:(.*?)[\ \>]/src=\"$chref$g_email{$mid}->{'content-id'}->{$1}\"/ig;    
      $buffer =~ s/background=\"cid:(.*?)\"/background=\"$chref$g_email{$mid}->{'content-id'}->{$1}\"/ig;
    }
    print $buffer;
    $buffer = "";
    $curfilepos = tell(MFP); 
    last if ($curfilepos >= $efilepos);
  }
  close(MFP); 

  exit(0);
}

##############################################################################
# eof

1;

