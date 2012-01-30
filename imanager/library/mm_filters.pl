#
# mm_filters.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/mm_filters.pl,v 2.12.2.7 2006/04/25 19:48:24 rus Exp $
#
# functions to manipulate SpamAssassin filter settings
#

##############################################################################

sub mailmanagerFiltersConfirmNukeSpamFolderForm
{
  local($nukeoption);

  mailmanagerSpamAssassinLoadSettings();

  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_FILTERS_TITLE : ";
  $title .= $MAILMANAGER_FILTERS_SPAM_FOLDER_NUKE_TITLE;
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);

  #
  # confirm nuke folder table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_FILTERS_TITLE : $MAILMANAGER_FILTERS_SPAM_FOLDER_NUKE_TITLE");
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
  # begin encapsulation table
  htmlTable();
  htmlTableRow();
  htmlTableData();

  $nukeoption = $g_form{'nukeoption'} || "nuke_only";

  htmlText($MAILMANAGER_FILTERS_SPAM_FOLDER_NUKE_CONFIRM);
  htmlP();
  formOpen();
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "action", "value", "nuke_folder");
  htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
  htmlTableRow();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "radio", "name", "nukeoption", "value", "nuke_only",
            "_OTHER_", (($nukeoption eq "nuke_only") ? "CHECKED" : ""));
  htmlTableDataClose(); 
  htmlTableData("valign", "middle", "colspan", "2"); 
  htmlText("&#160;$MAILMANAGER_FILTERS_SPAM_FOLDER_NUKE_OPTION_EMPTY");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("colspan", "3"); 
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "radio", "name", "nukeoption", "value", "nuke_and_reset",
            "_OTHER_", (($nukeoption eq "nuke_and_reset") ? "CHECKED" : ""));
  htmlTableDataClose(); 
  htmlTableData("valign", "middle", "colspan", "2"); 
  htmlText("&#160;$MAILMANAGER_FILTERS_SPAM_FOLDER_NUKE_OPTION_RESET");
  htmlTableDataClose(); 
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "submit", "name", "proceed", "value", $CONFIRM_STRING);
  formInput("type", "submit", "name", "proceed", "value", $CANCEL_STRING);
  formClose();

  # end encapsulation table
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
  # end parent table
  #

  labelCustomFooter();
  exit(0);
}

##############################################################################

sub mailmanagerFiltersConfirmResetLogFileForm
{
  local($resetoption);

  mailmanagerSpamAssassinLoadSettings();

  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_FILTERS_TITLE : ";
  $title .= $MAILMANAGER_FILTERS_LOG_FILE_RESET;
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);

  #
  # confirm reset log table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_FILTERS_TITLE : $MAILMANAGER_FILTERS_LOG_FILE_RESET");
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
  # begin encapsulation table
  htmlTable();
  htmlTableRow();
  htmlTableData();

  $resetoption = $g_form{'resetoption'} || "reset_only";

  htmlText($MAILMANAGER_FILTERS_LOG_FILE_RESET_CONFIRM);
  htmlP();
  formOpen();
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "action", "value", "reset_log");
  htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
  htmlTableRow();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "radio", "name", "resetoption", "value", "reset_only",
            "_OTHER_", (($resetoption eq "reset_only") ? "CHECKED" : ""));
  htmlTableDataClose(); 
  htmlTableData("valign", "middle", "colspan", "2"); 
  htmlText("&#160;$MAILMANAGER_FILTERS_LOG_FILE_RESET_OPTION_EMPTY");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("colspan", "3"); 
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "radio", "name", "resetoption", "value", "reset_and_nuke",
            "_OTHER_", (($resetoption eq "reset_and_nuke") ? "CHECKED" : ""));
  htmlTableDataClose(); 
  htmlTableData("valign", "middle", "colspan", "2"); 
  htmlText("&#160;$MAILMANAGER_FILTERS_LOG_FILE_RESET_OPTION_RESET");
  htmlTableDataClose(); 
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "submit", "name", "proceed", "value", $CONFIRM_STRING);
  formInput("type", "submit", "name", "proceed", "value", $CANCEL_STRING);
  formClose();

  # end encapsulation table
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
  # end parent table
  #

  labelCustomFooter();
  exit(0);
}

##############################################################################

sub mailmanagerFiltersDisplaySummary
{
  local($mesg) = @_;
  local($title, $encpath, $encargs, @lines, $f_enabled, $string);
  local($homedir, $fullpath, $mbox, $size, $num, $count, $entry);
  local(@patterns, $pattern, $sa_version); 

  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_FILTERS_TITLE";
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);

  if (!$mesg && $g_form{'msgfileid'}) {
    # read message from temporary state message file
    $mesg = redirectMessageRead($g_form{'msgfileid'});
  }
  if ($mesg) {
    @lines = split(/\n/, $mesg);
    foreach $mesg (@lines) {
      htmlTextColorBold(">>> $mesg <<<", "#cc0000");
      htmlBR();
    }
    htmlBR();
  }

  #
  # display filters table (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_FILTERS_TITLE");
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
  # begin encapsulation table
  htmlTable();
  htmlTableRow();
  htmlTableData();

  $encpath = encodingStringToURL($g_form{'mbox'});
  $encargs = "mbox=$encpath&mpos=$g_form{'mpos'}&mrange=$g_form{'mrange'}&msort=$g_form{'msort'}";

  # help text
  htmlText($MAILMANAGER_FILTERS_HELP_TEXT);
  htmlP();
  unless (-e "/usr/local/bin/spamassassin") {
    htmlTextItalic($MAILMANAGER_FILTERS_SPAMASSASSIN_NOT_FOUND);
    htmlP();
  }
  else {
    unless (-e "/usr/local/bin/procmail") {
      htmlTextItalic($MAILMANAGER_FILTERS_PROCMAIL_NOT_FOUND);
      htmlP();
    }
  }

  mailmanagerSpamAssassinLoadSettings();

  # settings table
  htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
  if ((-e "/usr/local/bin/spamassassin") && (-e "/usr/local/bin/procmail")) {
    # version row
    $sa_version = mailmanagerSpamAssassinGetVersion();
    htmlTableRow();
    htmlTableData();
    htmlNoBR();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextBold("$MAILMANAGER_FILTERS_VERSION:");
    htmlText("&#160;&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlText($sa_version);
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlText("&#160;");
    htmlTableDataClose();
    htmlTableRowClose();
  }
  # status row
  htmlTableRow();
  htmlTableData();
  htmlNoBR();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  htmlTextBold("$MAILMANAGER_FILTERS_STATUS:");
  htmlText("&#160;&#160;&#160;");   
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("align", "left");
  htmlNoBR();
  $f_enabled = mailmanagerSpamAssassinGetStatus();
  if (($f_enabled) && (-e "/usr/local/bin/spamassassin") && 
      (-e "/usr/local/bin/procmail")) {
    htmlText($MAILMANAGER_FILTERS_STATUS_ON);
  }
  else {
    htmlText($MAILMANAGER_FILTERS_STATUS_OFF);
  }
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("align", "left", "width", "100%");
  htmlNoBR();
  htmlText("&#160; &#160; [ ");
  if ((-e "/usr/local/bin/spamassassin") && (-e "/usr/local/bin/procmail")) {
    if ($f_enabled) {
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=disable",
                 "title", $MAILMANAGER_FILTERS_DISABLE);
      htmlAnchorText($MAILMANAGER_FILTERS_DISABLE);
      htmlAnchorClose();
    }
    else {
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=enable",
                 "title", $MAILMANAGER_FILTERS_ENABLE);
      htmlAnchorText($MAILMANAGER_FILTERS_ENABLE);
      htmlAnchorClose();
    }
  }
  else {
    unless (-e "/usr/local/bin/spamassassin") {
      htmlTextItalic($MAILMANAGER_FILTERS_STATUS_SPAMASSASSIN_NOT_FOUND);
    }
    else {
      htmlTextItalic($MAILMANAGER_FILTERS_STATUS_PROCMAIL_NOT_FOUND);
    }
  }
  htmlText(" ]");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableRowClose();
  if ((-e "/usr/local/bin/spamassassin") && (-e "/usr/local/bin/procmail")) {
    # mode row
    htmlTableRow();
    htmlTableData();
    htmlNoBR();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextBold("$MAILMANAGER_FILTERS_MODE:");
    htmlText("&#160;&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "left");
    if ($g_filters{'mode'} eq "strict") {
      htmlText($MAILMANAGER_FILTERS_MODE_STRICT);
    }
    elsif ($g_filters{'mode'} eq "default") {
      htmlText($MAILMANAGER_FILTERS_MODE_DEFAULT);
    }
    elsif ($g_filters{'mode'} eq "permissive") {
      htmlText($MAILMANAGER_FILTERS_MODE_PERMISSIVE);
    }
    else {
      htmlText($MAILMANAGER_FILTERS_MODE_CUSTOM);
      htmlText(" ($g_filters{'required_hits'})");
    }
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlNoBR();
    htmlText("&#160; &#160; [ ");
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=edit_mode",
               "title", $MAILMANAGER_FILTERS_MODE_CHANGE_TITLE);
    htmlAnchorText($MAILMANAGER_FILTERS_MODE_CHANGE);
    htmlAnchorClose();
    htmlText(" ]");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    # save tagged messages?
    htmlTableRow();
    htmlTableData();
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlNoBR();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextBold("$MAILMANAGER_FILTERS_SPAM_FOLDER_SAVE\?");
    htmlText("&#160;&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    if ($g_filters{'spamfolder'} eq "/dev/null") {
      htmlText($NO_STRING); 
    }
    else {
      htmlText($YES_STRING); 
    }
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlNoBR();
    htmlText("&#160; &#160; [ ");
    if ($g_filters{'spamfolder'} eq "/dev/null") {
      $MAILMANAGER_FILTERS_SPAM_FOLDER_ENABLE_TITLE =~ s/\n//g;
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=edit_folder",
                 "title", $MAILMANAGER_FILTERS_SPAM_FOLDER_ENABLE_TITLE);
      htmlAnchorText($MAILMANAGER_FILTERS_SPAM_FOLDER_ENABLE);
      htmlAnchorClose();
    }
    else {
      $string = "$encargs&action=change_folder&spamfolder=";
      $string .= encodingStringToURL("/dev/null");
      $MAILMANAGER_FILTERS_SPAM_FOLDER_DISABLE_TITLE =~ 
                         s/__FOLDER__/$g_filters{'spamfolder'}/;
      $MAILMANAGER_FILTERS_SPAM_FOLDER_DISABLE_TITLE =~ s/\n//g;
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$string",
                 "title", $MAILMANAGER_FILTERS_SPAM_FOLDER_DISABLE_TITLE);
      htmlAnchorText($MAILMANAGER_FILTERS_SPAM_FOLDER_DISABLE);
      htmlAnchorClose();
    }
    htmlText(" ]");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    # tagged messages folder
    htmlTableRow();
    htmlTableData();
    htmlNoBR();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextBold("$MAILMANAGER_FILTERS_SPAM_FOLDER_SPEC:");
    htmlText("&#160;&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "left");
    $homedir = $g_users{$g_auth{'login'}}->{'home'};
    $fullpath = ($g_filters{'spamfolder'} eq "/dev/null") ? 
                 $g_filters{'last_spamfolder'} : $g_filters{'spamfolder'};
    $mbox = $fullpath;
    $fullpath =~ s/\$HOME/$homedir/;
    $mbox =~ s/\$HOME/~/;
    $encpath = encodingStringToURL($mbox);
    if ($g_filters{'spamfolder'} eq "/dev/null") {
      if (-e "$fullpath") {
        $title = $MAILMANAGER_FOLDER_OPEN;
        $title =~ s/__FOLDER__/$g_filters{'last_spamfolder'}/;
        htmlAnchor("href", "mailmanager.cgi?mbox=$encpath&msort=in_order",
                   "title", $title);
        htmlAnchorText($g_filters{'last_spamfolder'}); 
        htmlAnchorClose();
      }
      else {
        htmlText($g_filters{'last_spamfolder'}); 
      }
    }
    else {
      if (-e "$fullpath") {
        $title = $MAILMANAGER_FOLDER_OPEN;
        $title =~ s/__FOLDER__/$g_filters{'spamfolder'}/;
        htmlAnchor("href", "mailmanager.cgi?mbox=$encpath&msort=in_order",
                   "title", $title);
        htmlAnchorText($g_filters{'spamfolder'}); 
        htmlAnchorClose();
      }
      else {
        htmlText($g_filters{'spamfolder'}); 
      }
    }
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlNoBR();
    htmlText("&#160; &#160; [ ");
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=edit_folder",
               "title", $MAILMANAGER_FILTERS_SPAM_FOLDER_CHANGE);
    htmlAnchorText($MAILMANAGER_FILTERS_SPAM_FOLDER_CHANGE);
    htmlAnchorClose();
    htmlText(" ]");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    # tagged messages folder size
    htmlTableRow();
    htmlTableData();
    htmlNoBR();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextBold("$MAILMANAGER_FILTERS_SPAM_FOLDER_SIZE:");
    htmlText("&#160;&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlNoBR();
    if (-e "$fullpath") {
      $size = (stat("$fullpath"))[7];
    }
    else {
      $size = 0;
    }
    if ($size < 1024) {
      $string = sprintf("%s $BYTES", $size);
    }
    elsif ($size < 1048576) {
      $string = sprintf("%1.1f $KILOBYTES", ($size / 1024));
    }
    else {
      $string = sprintf("%1.2f $MEGABYTES", ($size / 1048576));
    }
    htmlText("$string; ");
    $num = 0;
    if (open(MFP, "$fullpath")) {
      while (<MFP>) {
        $num++ if (/^From\ /);
      }
      close(MFP);
    }
    if ($num == 1) {
      htmlText($MAILMANAGER_FILTERS_SPAM_FOLDER_ONE_MESG);
    }
    else {
      $MAILMANAGER_FILTERS_SPAM_FOLDER_NUM_MESG =~ s/__NUM__/$num/;
      htmlText($MAILMANAGER_FILTERS_SPAM_FOLDER_NUM_MESG);
    }
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "left");
    if ($size > 0) {
      htmlNoBR();
      htmlText("&#160; &#160; [ ");
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=confirm_nuke",
                 "title", $MAILMANAGER_FILTERS_SPAM_FOLDER_NUKE_TITLE);
      htmlAnchorText($MAILMANAGER_FILTERS_SPAM_FOLDER_NUKE);
      htmlAnchorClose();
      htmlText(" ]");
      htmlNoBRClose();
    }
    htmlTableDataClose();
    htmlTableRowClose();
    # white list count
    htmlTableRow();
    htmlTableData();
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlNoBR();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextBold("$MAILMANAGER_FILTERS_LISTS_WHITE_COUNT:");
    htmlText("&#160;&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    $num = 0;
    foreach $entry (sort(@{$g_filters{'whitelist'}})) {
      $entry =~ s/\s+/\ /g;
      @patterns = split(/ /, $entry);
      $num += $#patterns;
    }
    htmlText($num); 
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlNoBR();
    htmlText("&#160; &#160; [ ");
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=edit_lists",
               "title", $MAILMANAGER_FILTERS_LISTS_WHITE_EDIT);
    htmlAnchorText($MAILMANAGER_FILTERS_LISTS_WHITE_EDIT);
    htmlAnchorClose();
    htmlText(" ]");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    # white list patterns
    if ($num > 0) {
      htmlTableRow();
      htmlTableData("colspan", "3");
      htmlText("&#160;&#160;&#160;&#160;&#160;");
      htmlTextBold("$MAILMANAGER_FILTERS_LISTS_WHITE_PATTERNS:");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("colspan", "3");
      htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
      # whitelist_to
      $num = 0;
      foreach $entry (sort(@{$g_filters{'whitelist'}})) {
        next unless ($entry =~ /^whitelist_to/);
        $entry =~ s/\s+/\ /g;
        @patterns = split(/ /, $entry);
        $num += $#patterns;
      }
      $count = 0;
      foreach $entry (@{$g_filters{'whitelist'}}) {
        if ($entry =~ /^whitelist_to/) {
          $entry =~ s/\s+/\ /g;
          @patterns = split(/ /, $entry);
          foreach $pattern (@patterns) {
            next if ($pattern eq "whitelist_to");
            $count++;
            if ($count == 1) {
              htmlTableRow();
              htmlTableData();
              htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
              htmlTableDataClose();
              htmlTableData("valign", "top");
              htmlTextColor("whitelist_to:&#160;", "#666666");
              htmlTableDataClose();
              htmlTableData();
            }
            else {
              htmlTextColor(", ", "#666666");
            }
            htmlTextColor("$pattern", "#666666");
            # just show the first 10 (or 11 or 12) patterns
            last if (($count > 10) && ($num > 12));  # exit foreach pattern
          }
        }
        last if (($count > 10) && ($num > 12));   # exit foreach entry
      }
      if ($count > 0) {
        if ($num > 12) {
          $num -= 10;
          $string = $MAILMANAGER_FILTERS_LISTS_CROPPED;
          $string =~ s/__NUM__/$num/;
          htmlTextColor(", ...$string\...", "#666666");
        }
        htmlTableDataClose();
        htmlTableRowClose();
      }
      # whitelist_from
      $num = 0;
      foreach $entry (sort(@{$g_filters{'whitelist'}})) {
        next unless ($entry =~ /^whitelist_from/);
        $entry =~ s/\s+/\ /g;
        @patterns = split(/ /, $entry);
        $num += $#patterns;
      }
      $count = 0;
      foreach $entry (@{$g_filters{'whitelist'}}) {
        if ($entry =~ /^whitelist_from/) {
          $entry =~ s/\s+/\ /g;
          @patterns = split(/ /, $entry);
          foreach $pattern (@patterns) {
            next if ($pattern eq "whitelist_from");
            $count++;
            if ($count == 1) {
              htmlTableRow();
              htmlTableData();
              htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
              htmlTableDataClose();
              htmlTableData("valign", "top");
              htmlTextColor("whitelist_from:&#160;", "#666666");
              htmlTableDataClose();
              htmlTableData();
            }
            else {
              htmlTextColor(", ", "#666666");
            }
            htmlTextColor("$pattern", "#666666");
            # just show the first 10 (or 11 or 12) patterns
            last if (($count > 10) && ($num > 12));  # exit foreach pattern
          }
        }
        last if (($count > 10) && ($num > 12));   # exit foreach entry
      }
      if ($count > 0) {
        if ($num > 12) {
          $num -= 10;
          $string = $MAILMANAGER_FILTERS_LISTS_CROPPED;
          $string =~ s/__NUM__/$num/;
          htmlTextColor(", ...$string\...", "#666666");
        }
        htmlTableDataClose();
        htmlTableRowClose();
      }
      htmlTableClose();
      htmlTableDataClose();
      htmlTableRowClose();
    }
    # black list count
    htmlTableRow();
    htmlTableData();
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlNoBR();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextBold("$MAILMANAGER_FILTERS_LISTS_BLACK_COUNT:");
    htmlText("&#160;&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    $num = 0;
    foreach $entry (sort(@{$g_filters{'blacklist'}})) {
      $entry =~ s/\s+/\ /g;
      @patterns = split(/ /, $entry);
      $num += $#patterns;
    }
    htmlText($num); 
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlNoBR();
    htmlText("&#160; &#160; [ ");
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=edit_lists",
               "title", $MAILMANAGER_FILTERS_LISTS_BLACK_EDIT);
    htmlAnchorText($MAILMANAGER_FILTERS_LISTS_BLACK_EDIT);
    htmlAnchorClose();
    htmlText(" ]");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    # black list patterns
    if ($num > 0) {
      htmlTableRow();
      htmlTableData("colspan", "3");
      htmlText("&#160;&#160;&#160;&#160;&#160;");
      htmlTextBold("$MAILMANAGER_FILTERS_LISTS_BLACK_PATTERNS:");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("colspan", "3");
      htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
      # blacklist_to
      $num = 0;
      foreach $entry (sort(@{$g_filters{'blacklist'}})) {
        next unless ($entry =~ /^blacklist_to/);
        $entry =~ s/\s+/\ /g;
        @patterns = split(/ /, $entry);
        $num += $#patterns;
      }
      $count = 0;
      foreach $entry (@{$g_filters{'blacklist'}}) {
        if ($entry =~ /^blacklist_to/) {
          $entry =~ s/\s+/\ /g;
          @patterns = split(/ /, $entry);
          foreach $pattern (@patterns) {
            next if ($pattern eq "blacklist_to");
            $count++;
            if ($count == 1) {
              htmlTableRow();
              htmlTableData();
              htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
              htmlTableDataClose();
              htmlTableData("valign", "top");
              htmlTextColor("blacklist_to:&#160;", "#666666");
              htmlTableDataClose();
              htmlTableData();
            }
            else {
              htmlTextColor(", ", "#666666");
            }
            htmlTextColor("$pattern", "#666666");
            # just show the first 10 (or 11 or 12) patterns
            last if (($count > 10) && ($num > 12));  # exit foreach pattern
          }
        }
        last if (($count > 10) && ($num > 12));   # exit foreach entry
      }
      if ($count > 0) {
        if ($num > 12) {
          $num -= 10;
          $string = $MAILMANAGER_FILTERS_LISTS_CROPPED;
          $string =~ s/__NUM__/$num/;
          htmlTextColor(", ...$string\...", "#666666");
        }
        htmlTableDataClose();
        htmlTableRowClose();
      }
      # blacklist_from
      $num = 0;
      foreach $entry (sort(@{$g_filters{'blacklist'}})) {
        next unless ($entry =~ /^blacklist_from/);
        $entry =~ s/\s+/\ /g;
        @patterns = split(/ /, $entry);
        $num += $#patterns;
      }
      $count = 0;
      foreach $entry (@{$g_filters{'blacklist'}}) {
        if ($entry =~ /^blacklist_from/) {
          $entry =~ s/\s+/\ /g;
          @patterns = split(/ /, $entry);
          foreach $pattern (@patterns) {
            next if ($pattern eq "blacklist_from");
            $count++;
            if ($count == 1) {
              htmlTableRow();
              htmlTableData();
              htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
              htmlTableDataClose();
              htmlTableData("valign", "top");
              htmlTextColor("blacklist_from:&#160;", "#666666");
              htmlTableDataClose();
              htmlTableData();
            }
            else {
              htmlTextColor(", ", "#666666");
            }
            htmlTextColor("$pattern", "#666666");
            # just show the first 10 (or 11 or 12) patterns
            last if (($count > 10) && ($num > 12));  # exit foreach pattern
          }
        }
        last if (($count > 10) && ($num > 12));   # exit foreach entry
      }
      if ($count > 0) {
        if ($num > 12) {
          $num -= 10;
          $string = $MAILMANAGER_FILTERS_LISTS_CROPPED;
          $string =~ s/__NUM__/$num/;
          htmlTextColor(", ...$string\...", "#666666");
        }
        htmlTableDataClose();
        htmlTableRowClose();
      }
      htmlTableClose();
      htmlTableDataClose();
      htmlTableRowClose();
    }
    # log filtered messages?
    htmlTableRow();
    htmlTableData();
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlNoBR();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextBold("$MAILMANAGER_FILTERS_LOG_STATUS\?");
    htmlText("&#160;&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    if ($g_filters{'logabstract'} eq "no") {
      htmlText($NO_STRING); 
    }
    else {
      htmlText($YES_STRING); 
    }
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    htmlNoBR();
    htmlText("&#160; &#160; [ ");
    if ($g_filters{'logabstract'} eq "no") {
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=edit_log_opts",
                 "title", $MAILMANAGER_FILTERS_LOG_OPTIONS_EDIT);
      htmlAnchorText($MAILMANAGER_FILTERS_LOG_ENABLE);
      htmlAnchorClose();
    }
    else {
      $string = "$encargs&action=save_log_opts&logabstract=no";
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$string",
                 "title", $MAILMANAGER_FILTERS_LOG_STATUS_OFF);
      htmlAnchorText($MAILMANAGER_FILTERS_LOG_DISABLE);
      htmlAnchorClose();
    }
    htmlText(" ]");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    # tagged messages folder
    htmlTableRow();
    htmlTableData();
    htmlNoBR();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextBold("$MAILMANAGER_FILTERS_LOG_FILE_SPEC:");
    htmlText("&#160;&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "left");
    $homedir = $g_users{$g_auth{'login'}}->{'home'};
    $fullpath = $g_filters{'logfile'};
    $fullpath =~ s/\$HOME/$homedir/;
    $encpath = encodingStringToURL($mbox);
    if (-e "$fullpath") {
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=view_log",
                 "title", $MAILMANAGER_FILTERS_LOG_FILE_VIEW);
      htmlAnchorText($g_filters{'logfile'}); 
      htmlAnchorClose();
    }
    else {
      htmlText($g_filters{'logfile'}); 
    }
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlNoBR();
    htmlText("&#160; &#160; [ ");
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=edit_log_opts",
               "title", $MAILMANAGER_FILTERS_LOG_OPTIONS_EDIT);
    htmlAnchorText($MAILMANAGER_FILTERS_LOG_FILE_CHANGE);
    htmlAnchorClose();
    htmlText(" ]");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableRowClose();
    # tagged messages folder size
    htmlTableRow();
    htmlTableData();
    htmlNoBR();
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextBold("$MAILMANAGER_FILTERS_LOG_FILE_SIZE:");
    htmlText("&#160;&#160;&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlNoBR();
    if (-e "$fullpath") {
      $size = (stat("$fullpath"))[7];
    }
    else {
      $size = 0;
    }
    if ($size < 1024) {
      $string = sprintf("%s $BYTES", $size);
    }
    elsif ($size < 1048576) {
      $string = sprintf("%1.1f $KILOBYTES", ($size / 1024));
    }
    else {
      $string = sprintf("%1.2f $MEGABYTES", ($size / 1048576));
    }
    htmlText("$string");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "left");
    if ($size > 0) {
      htmlNoBR();
      htmlText("&#160; &#160; [ ");
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=view_log",
                 "title", $MAILMANAGER_FILTERS_LOG_FILE_VIEW);
      htmlAnchorText($MAILMANAGER_FILTERS_LOG_FILE_VIEW);
      htmlAnchorClose();
      htmlText(" | ");
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$encargs&action=confirm_reset",
                 "title", $MAILMANAGER_FILTERS_LOG_FILE_RESET);
      htmlAnchorText($MAILMANAGER_FILTERS_LOG_FILE_RESET);
      htmlAnchorClose();
      htmlText(" ]");
      htmlNoBRClose();
    }
    htmlTableDataClose();
    htmlTableRowClose();
  }
  htmlTableClose();

  formOpen(); 
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  formInput("type", "submit", "name", "action", "value", $MAILMANAGER_RETURN);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  formClose();

  # end encapsulation table
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
  # end parent table
  #

  labelCustomFooter();
  exit(0);
}

##############################################################################

sub mailmanagerFiltersEditListsForm
{
  local($value, $entry, $rows);

  mailmanagerSpamAssassinLoadSettings();

  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_FILTERS_TITLE : ";
  $title .= $MAILMANAGER_FILTERS_LISTS_EDIT_TITLE;
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);

  #
  # edit white/black lists (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_FILTERS_TITLE : $MAILMANAGER_FILTERS_LISTS_EDIT_TITLE");
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
  # begin encapsulation table
  htmlTable();
  htmlTableRow();
  htmlTableData();

  htmlText($MAILMANAGER_FILTERS_LISTS_EDIT_HELP_ABOUT);
  htmlP();
  htmlText($MAILMANAGER_FILTERS_LISTS_EDIT_HELP_TYPES_FROM);
  htmlP();
  htmlText($MAILMANAGER_FILTERS_LISTS_EDIT_HELP_TYPES_TO);
  htmlP();
  htmlText($MAILMANAGER_FILTERS_LISTS_EDIT_HELP_FORMAT);
  htmlP();
  htmlText($MAILMANAGER_FILTERS_LISTS_EDIT_HELP_EXAMPLES_1);
  htmlP();
  htmlPre();
  htmlFont("class", "fixed", "face", "courier new, courier", "size", "2",
           "style", "font-family: courier new, courier; font-size: 12px");
  print "$MAILMANAGER_FILTERS_LISTS_EDIT_HELP_EXAMPLES_2";
  htmlFontClose();
  htmlPreClose();
  htmlText($MAILMANAGER_FILTERS_LISTS_EDIT_HELP);
  htmlP();
  formOpen();
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "action", "value", "save_lists");
  htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  htmlTextBold("$MAILMANAGER_FILTERS_LISTS_WHITE_PATTERNS:");
  htmlBR();
  if ($g_form{'whitelist'}) {
    $value = $g_form{'whitelist'};
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    $value =~ s/\r\n/\n/g;
    $value =~ s/\r//g;
  }
  else {
    $value = "";
    foreach $entry (@{$g_filters{'whitelist'}}) {
      $value .= "$entry\n";
    }
  }
  $rows = ($value =~ tr/\n/\n/) || 6;
  $rows += 2;
  $rows = 6 if ($rows < 6);
  formTextArea($value, "name", "whitelist", "rows", $rows, "cols", 60, 
               "_FONT_", "fixed", "wrap", "physical");
  htmlBR();
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData();
  htmlTextBold("$MAILMANAGER_FILTERS_LISTS_BLACK_PATTERNS:");
  htmlBR();
  if ($g_form{'blacklist'}) {
    $value = $g_form{'blacklist'};
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    $value =~ s/\r\n/\n/g;
    $value =~ s/\r//g;
  }
  else {
    $value = "";
    foreach $entry (@{$g_filters{'blacklist'}}) {
      $value .= "$entry\n";
    }
  }
  $rows = ($value =~ tr/\n/\n/) || 6;
  $rows += 2;
  $rows = 6 if ($rows < 6);
  formTextArea($value, "name", "blacklist", "rows", $rows, "cols", 60, 
               "_FONT_", "fixed", "wrap", "physical");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "submit", "name", "proceed", "value", 
            $MAILMANAGER_FILTERS_LISTS_EDIT_STORE);
  formInput("type", "submit", "name", "proceed", "value", $CANCEL_STRING);
  formClose();

  # end encapsulation table
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
  # end parent table
  #

  labelCustomFooter();
  exit(0);
}

##############################################################################

sub mailmanagerFiltersEditLoggingOptions
{
  local($mesg) = @_;
  local(@lines, $title, $logabstract, $logfile);

  mailmanagerSpamAssassinLoadSettings();

  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_FILTERS_TITLE : ";
  $title .= $MAILMANAGER_FILTERS_LOG_STATUS;
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);

  if (!$mesg && $g_form{'msgfileid'}) {
    # read message from temporary state message file
    $mesg = redirectMessageRead($g_form{'msgfileid'});
  }
  if ($mesg) {
    @lines = split(/\n/, $mesg);
    foreach $mesg (@lines) {
      htmlTextColorBold(">>> $mesg <<<", "#cc0000");
      htmlBR();
    }
    htmlBR();
  }

  #
  # edit spam log options (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_FILTERS_TITLE : $MAILMANAGER_FILTERS_LOG_STATUS");
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
  # begin encapsulation table
  htmlTable();
  htmlTableRow();
  htmlTableData();

  $logabstract = $g_form{'logabstract'} || $g_filters{'logabstract'};
  $logfile = $g_form{'logfile'} || $g_filters{'logfile'};

  htmlText($MAILMANAGER_FILTERS_LOG_OPTIONS_HELP);
  htmlP();
  formOpen();
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "action", "value", "save_log_opts");
  htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
  htmlTableRow();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "radio", "name", "logabstract", "value", "yes",
            "_OTHER_", (($logabstract eq "yes") ? "CHECKED" : ""));
  htmlTableDataClose(); 
  htmlTableData("valign", "middle", "colspan", "2"); 
  htmlText("&#160;$MAILMANAGER_FILTERS_LOG_STATUS_ON");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  htmlTableDataClose(); 
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  htmlText("$MAILMANAGER_FILTERS_SPAM_FOLDER_SPEC:&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle"); 
  $size40 = formInputSize(40);
  formInput("size", $size40, "name", "logfile", "value", $logfile);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("colspan", "3"); 
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "radio", "name", "logabstract", "value", "no",
            "_OTHER_", (($logabstract eq "no") ? "CHECKED" : ""));
  htmlTableDataClose(); 
  htmlTableData("valign", "middle", "colspan", "2"); 
  htmlText("&#160;$MAILMANAGER_FILTERS_LOG_STATUS_OFF");
  htmlTableDataClose(); 
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "submit", "name", "proceed", "value", 
            $MAILMANAGER_FILTERS_LOG_OPTIONS_STORE);
  formInput("type", "submit", "name", "proceed", "value", $CANCEL_STRING);
  formClose();

  # end encapsulation table
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
  # end parent table
  #

  labelCustomFooter();
  exit(0);
}

##############################################################################

sub mailmanagerFiltersEditSpamFolderOptions
{
  local($mesg) = @_;
  local(@lines, $title, $savespam, $spamfolder);

  mailmanagerSpamAssassinLoadSettings();

  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_FILTERS_TITLE : ";
  $title .= $MAILMANAGER_FILTERS_SPAM_FOLDER_SAVE;
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);

  if (!$mesg && $g_form{'msgfileid'}) {
    # read message from temporary state message file
    $mesg = redirectMessageRead($g_form{'msgfileid'});
  }
  if ($mesg) {
    @lines = split(/\n/, $mesg);
    foreach $mesg (@lines) {
      htmlTextColorBold(">>> $mesg <<<", "#cc0000");
      htmlBR();
    }
    htmlBR();
  }

  #
  # edit spam folder options (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_FILTERS_TITLE : $MAILMANAGER_FILTERS_SPAM_FOLDER_SAVE");
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
  # begin encapsulation table
  htmlTable();
  htmlTableRow();
  htmlTableData();

  $savespam = $g_form{'savespam'};
  unless ($savespam) {
    $savespam = ($g_filters{'spamfolder'} eq "/dev/null") ? "no" : "yes";
  }
  $spamfolder = $g_form{'spamfolder'};
  unless ($spamfolder || $g_form{'proceed'}) {
    $spamfolder = ($g_filters{'spamfolder'} eq "/dev/null") ?
                   $g_filters{'last_spamfolder'} : $g_filters{'spamfolder'};
  }

  htmlText($MAILMANAGER_FILTERS_SPAM_FOLDER_HELP);
  htmlP();
  htmlText($MAILMANAGER_FILTERS_SPAM_FOLDER_HELP_SPEC);
  htmlP();
  formOpen();
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "action", "value", "change_folder");
  htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
  htmlTableRow();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "radio", "name", "savespam", "value", "yes",
            "_OTHER_", (($savespam eq "yes") ? "CHECKED" : ""));
  htmlTableDataClose(); 
  htmlTableData("valign", "middle", "colspan", "2"); 
  htmlText("&#160;$MAILMANAGER_FILTERS_SPAM_FOLDER_SAVE");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  htmlTableDataClose(); 
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  htmlText("$MAILMANAGER_FILTERS_SPAM_FOLDER_SPEC:&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle"); 
  $size40 = formInputSize(40);
  formInput("size", $size40, "name", "spamfolder", "value", $spamfolder);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("colspan", "3"); 
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "radio", "name", "savespam", "value", "no",
            "_OTHER_", (($savespam eq "no") ? "CHECKED" : ""));
  htmlTableDataClose(); 
  htmlTableData("valign", "middle", "colspan", "2"); 
  htmlText("&#160;$MAILMANAGER_FILTERS_SPAM_FOLDER_DISCARD");
  htmlTableDataClose(); 
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "submit", "name", "proceed", "value", 
            $MAILMANAGER_FILTERS_SPAM_FOLDER_SET);
  formInput("type", "submit", "name", "proceed", "value", $CANCEL_STRING);
  formClose();

  # end encapsulation table
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
  # end parent table
  #

  labelCustomFooter();
  exit(0);
}

##############################################################################

sub mailmanagerFiltersEditModeForm
{
  local($mesg) = @_;
  local(@lines, $title, $size5, $mode);

  mailmanagerSpamAssassinLoadSettings();

  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_FILTERS_TITLE : ";
  $title .= $MAILMANAGER_FILTERS_MODE_CHANGE;
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);

  if (!$mesg && $g_form{'msgfileid'}) {
    # read message from temporary state message file
    $mesg = redirectMessageRead($g_form{'msgfileid'});
  }
  if ($mesg) {
    @lines = split(/\n/, $mesg);
    foreach $mesg (@lines) {
      htmlTextColorBold(">>> $mesg <<<", "#cc0000");
      htmlBR();
    }
    htmlBR();
  }

  #
  # edit mode options (2 cells: sidebar, contents)
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
  htmlTextBold("&#160;$MAILMANAGER_FILTERS_TITLE : $MAILMANAGER_FILTERS_SPAM_FOLDER_SAVE");
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
  # begin encapsulation table
  htmlTable();
  htmlTableRow();
  htmlTableData();

  $mode = $g_form{'mode'} || $g_filters{'mode'};

  htmlText($MAILMANAGER_FILTERS_MODE_HELP);
  htmlP();
  htmlText($MAILMANAGER_FILTERS_MODE_HELP_DEFAULT);
  htmlP();
  htmlText($MAILMANAGER_FILTERS_MODE_HELP_CUSTOM);
  htmlP();
  formOpen();
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
  formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
  formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
  formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
  formInput("type", "hidden", "name", "action", "value", "set_mode");
  htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
  htmlTableRow();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "radio", "name", "mode", "value", "strict",
            "_OTHER_", (($mode eq "strict") ? "CHECKED" : ""));
  htmlTableDataClose(); 
  htmlTableData("valign", "middle"); 
  htmlText("&#160;$MAILMANAGER_FILTERS_MODE_STRICT");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("colspan", "3"); 
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "radio", "name", "mode", "value", "permissive",
            "_OTHER_", (($mode eq "permissive") ? "CHECKED" : ""));
  htmlTableDataClose(); 
  htmlTableData("valign", "middle"); 
  htmlText("&#160;$MAILMANAGER_FILTERS_MODE_PERMISSIVE");
  htmlTableDataClose(); 
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("colspan", "3"); 
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "radio", "name", "mode", "value", "default",
            "_OTHER_", (($mode eq "default") ? "CHECKED" : ""));
  htmlTableDataClose(); 
  htmlTableData("valign", "middle"); 
  htmlText("&#160;$MAILMANAGER_FILTERS_MODE_DEFAULT");
  htmlTableDataClose(); 
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("colspan", "3"); 
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "radio", "name", "mode", "value", "custom", 
            "_OTHER_", (($mode eq "custom") ? "CHECKED" : ""));
  htmlTableDataClose(); 
  htmlTableData("valign", "middle"); 
  htmlText("&#160;$MAILMANAGER_FILTERS_MODE_CUSTOM_THRESHOLD:");
  htmlTableDataClose();
  htmlTableData("valign", "middle"); 
  htmlText("&#160;&#160;");
  unless ($g_form{'required_hits'} || $g_form{'proceed'}) {
    $g_form{'required_hits'} = $g_filters{'required_hits'};
  } 
  $size5 = formInputSize(5);
  formInput("size", $size5, "name", "required_hits", 
            "value", $g_form{'required_hits'});
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  formInput("type", "submit", "name", "proceed", "value", 
            $MAILMANAGER_FILTERS_MODE_SET);
  formInput("type", "submit", "name", "proceed", "value", $CANCEL_STRING);
  formClose();
  htmlP();

  # end encapsulation table
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
  # end parent table
  #

  labelCustomFooter();
  exit(0);
}

##############################################################################

sub mailmanagerFiltersHandleRequest 
{
  local($mesg);
  
  encodingIncludeStringLibrary("mailmanager");
  
  # check first for cancel requests 
  if ($g_form{'proceed'} eq $CANCEL_STRING) {
    if ($g_form{'action'} eq "set_mode") {
      $mesg = $MAILMANAGER_FILTERS_MODE_SET_CANCEL;
    }
    elsif ($g_form{'action'} eq "change_folder") {
      $mesg = $MAILMANAGER_FILTERS_SPAM_FOLDER_CHANGE_CANCEL;
    }
    elsif ($g_form{'action'} eq "nuke_folder") {
      $mesg = $MAILMANAGER_FILTERS_SPAM_FOLDER_NUKE_CANCEL;
    }
    elsif ($g_form{'action'} eq "save_lists") {
      $mesg = $MAILMANAGER_FILTERS_LISTS_EDIT_CANCEL;
    }
    elsif ($g_form{'action'} eq "save_log_opts") {
      $mesg = $MAILMANAGER_FILTERS_LOG_OPTIONS_CHANGE_CANCEL;
    }
    elsif ($g_form{'action'} eq "reset_log") {
      $mesg = $MAILMANAGER_FILTERS_LOG_FILE_RESET_CANCEL;
    }
    redirectLocation("mm_filters.cgi", $mesg);
  }

  # process action
  if ((!$g_form{'action'}) ||
      ($g_form{'action'} eq $MAILMANAGER_FILTERS_RETURN)) {
    mailmanagerFiltersDisplaySummary();
  }
  elsif ($g_form{'action'} eq "enable") {
    mailmanagerFiltersSanityCheck("enable");
    mailmanagerFiltersSetStatus("enable");
  }
  elsif ($g_form{'action'} eq "disable") {
    mailmanagerFiltersSanityCheck("disable");
    mailmanagerFiltersSetStatus("disable");
  }
  elsif ($g_form{'action'} eq "edit_mode") {
    mailmanagerFiltersEditModeForm();
  }
  elsif ($g_form{'action'} eq "set_mode") {
    # first perform some error checks on the submitted data
    if ($g_form{'mode'} eq "custom") {
      if (!$g_form{'required_hits'}) {
        $mesg = $MAILMANAGER_FILTERS_MODE_ERROR_CUSTOM_UNDEFINED;
        mailmanagerFiltersEditModeForm($mesg);
      }
      elsif ($g_form{'required_hits'} =~ /[^0-9\.\-]/) {
        $mesg = $MAILMANAGER_FILTERS_MODE_ERROR_CUSTOM_INVALID;
        mailmanagerFiltersEditModeForm($mesg);
      }
    }
    # perform a sanity check
    mailmanagerFiltersSanityCheck("set_mode");
    # set the new mode
    mailmanagerFiltersSetMode();
  }
  elsif ($g_form{'action'} eq "edit_folder") {
    mailmanagerFiltersEditSpamFolderOptions();
  }
  elsif ($g_form{'action'} eq "change_folder") {
   # first perform some error checks
    if (($g_form{'savespam'} eq "yes") && (!$g_form{'spamfolder'})) {
      $mesg = $MAILMANAGER_FILTERS_SPAM_FOLDER_CHANGE_ERROR;
      mailmanagerFiltersEditSpamFolderOptions($mesg);
    }
    # perform a sanity check
    mailmanagerFiltersSanityCheck("change_folder");
    # store folder option preferences
    mailmanagerFiltersSaveSpamFolderOptions();
  }
  elsif ($g_form{'action'} eq "confirm_nuke") {
    mailmanagerFiltersConfirmNukeSpamFolderForm();
  }
  elsif ($g_form{'action'} eq "nuke_folder") {
    mailmanagerFiltersNukeSpamFolder();
  }
  elsif ($g_form{'action'} eq "edit_lists") {
    mailmanagerFiltersEditListsForm();
  }
  elsif ($g_form{'action'} eq "save_lists") {
    mailmanagerFiltersSanityCheck("save_lists");
    mailmanagerFiltersSaveLists();
  }
  elsif ($g_form{'action'} eq "edit_log_opts") {
    mailmanagerFiltersEditLoggingOptions();
  }
  elsif ($g_form{'action'} eq "save_log_opts") {
    mailmanagerFiltersSanityCheck("save_log_opts");
    mailmanagerFiltersSaveLoggingOptions();
  }
  elsif ($g_form{'action'} eq "view_log") {
    mailmanagerFiltersViewLogFile();
  }
  elsif ($g_form{'action'} eq "confirm_reset") {
    mailmanagerFiltersConfirmResetLogFileForm();
  }
  elsif ($g_form{'action'} eq "reset_log") {
    mailmanagerFiltersResetLog();
  }
  elsif ($g_form{'action'} eq $MAILMANAGER_RETURN) {
    redirectLocation("mailmanager.cgi");
  }
}

##############################################################################

sub mailmanagerFiltersNukeSpamFolder
{
  local($homedir, $fullpath, $folderpath, $output);

  mailmanagerSpamAssassinLoadSettings();

  $homedir = $g_users{$g_auth{'login'}}->{'home'};

  # nuke the log file
  $folderpath = ($g_filters{'spamfolder'} eq "/dev/null") ? 
                 $g_filters{'last_spamfolder'} : $g_filters{'spamfolder'};
  $fullpath = $folderpath;
  $fullpath =~ s/\$HOME/$homedir/;
  if (unlink($fullpath)) {
    $output = $MAILMANAGER_FILTERS_SPAM_FOLDER_NUKE_SUCCESS;
    open(MYFP, ">$fullpath");
    close(MYFP);
  }
  else {
    $folderpath = ($g_filters{'spamfolder'} eq "/dev/null") ? 
                   $g_filters{'last_spamfolder'} : $g_filters{'spamfolder'};
    $output = "unlink($folderpath): $!";
  }
  # empty the spam folder (if applicable)
  if ($g_form{'nukeoption'} ne "nuke_only") {
    $output .= "\n";
    $fullpath = $g_filters{'logfile'};
    $fullpath =~ s/\$HOME/$homedir/;
    if (unlink($fullpath)) {
      $output .= $MAILMANAGER_FILTERS_LOG_FILE_RESET_SUCCESS;
      open(MYFP, ">$fullpath");
      close(MYFP);
    }
    else {
      $output .= "unlink($g_filters{'logfile'}): $!";
    }
  }
  # redirect back to mail filtering index
  redirectLocation("mm_filters.cgi", $output);
}

##############################################################################

sub mailmanagerFiltersSanityCheck
{
  local($action) = @_;
  local(%statinfo, $path, $size, $date, $lda, $atxt);
  local($lda, $ar_enabled, $homedir, $idir, $fdir);
  local($title, $subtitle);
  local($sa_version);

  # function looks at ~/.forward, ~/.procmailrc, ~/.spamassassin/user_prefs
  # and compares the size and modification date to those stored in
  # ~/.imanager/last.forward, ~/.imanager/last.procmailrc, and 
  # ~/.imanager/filters/last.user_prefs respectively... if there are 
  # differences, then external modifications have been made (or, if this is
  # the first time the check has been made, the .forward, .procmailrc, and
  # .spamassassin/user_prefs files were pre-existing).  if the check succeeds
  # (i.e.  differences exist) then the files may need to be rebuilt from the
  # original files (which are found in the ~imanager/skel directory).

  return if ($g_form{'sanitycheck'} eq "yes");

  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  $fdir = mailmanagerGetDirectoryPath("filters");
  $idir = $fdir;
  $idir =~ s/[^\/]+$//g;
  $idir =~ s/\/+$//g;

  $lda = mailmanagerGetLocalDeliveryAgent();

  $ar_enabled = mailmanagerNemetonAutoreplyGetStatus();

  # does the .forward need a sanity check?
  if ((($lda !~ m#/usr/local/bin/procmail#) || ($ar_enabled)) &&
      (($action eq "enable") || ($action eq "disable"))) {
    $statinfo{'forward_current'}->{'size'} = 0;
    $statinfo{'forward_current'}->{'date'} = 0;
    $statinfo{'forward_archive'}->{'size'} = 0;
    $statinfo{'forward_archive'}->{'date'} = 0;
    # forward_current
    $path = "$homedir/.forward";
    if (-e "$path") {
      ($size, $date) = (stat("$path"))[7,9];
      $statinfo{'forward_current'}->{'size'} = $size;
      $statinfo{'forward_current'}->{'date'} = $date;
    }
    # forward_archive
    $path = "$idir/last.forward";
    if (-e "$path") {
      ($size, $date) = (stat("$path"))[7,9];
    }
    else {
      ($size, $date) = (stat("$g_skeldir/dot.forward_autoreply"))[7,9];
    }
    $statinfo{'forward_archive'}->{'size'} = $size;
    $statinfo{'forward_archive'}->{'date'} = $date;
  }

  # do changes to .procmailrc need a sanity check?
  if ((($lda =~ m#/usr/local/bin/procmail#) &&
       (($action eq "enable") || ($action eq "disable"))) ||
      (($action eq "change_folder") || ($action eq "save_log_opts"))) {
    $statinfo{'procmailrc_current'}->{'size'} = 0;
    $statinfo{'procmailrc_current'}->{'date'} = 0;
    $statinfo{'procmailrc_archive'}->{'size'} = 0;
    $statinfo{'procmailrc_archive'}->{'date'} = 0;
    # procmailrc_current
    $path = "$homedir/.procmailrc";
    if (-e "$path") {
      ($size, $date) = (stat("$path"))[7,9];
      $statinfo{'procmailrc_current'}->{'size'} = $size;
      $statinfo{'procmailrc_current'}->{'date'} = $date;
    }
    # procmailrc_archive
    $path = "$idir/last.procmailrc";
    if (-e "$path") {
      ($size, $date) = (stat("$path"))[7,9];
    }
    else {
      $sa_version = mailmanagerSpamAssassinGetVersion();
      if (mailmanagerSpamAssassinDaemonEnabled()) {
        ($size, $date) = (stat("$g_skeldir/dot.procmailrc_spamc"))[7,9];
      }
      else {
        ($size, $date) = (stat("$g_skeldir/dot.procmailrc"))[7,9];
      }
    }
    $statinfo{'procmailrc_archive'}->{'size'} = $size;
    $statinfo{'procmailrc_archive'}->{'date'} = $date;
  }

  # do changes need to user_prefs need a sanity check?
  if (($action eq "set_mode") || ($action eq "save_lists")) {
    $statinfo{'userprefs_current'}->{'size'} = 0;
    $statinfo{'userprefs_current'}->{'date'} = 0;
    $statinfo{'userprefs_archive'}->{'size'} = 0;
    $statinfo{'userprefs_archive'}->{'date'} = 0;
    # userprefs_current
    $path = "$homedir/.spamassassin/user_prefs";
    if (-e "$path") {
      ($size, $date) = (stat("$path"))[7,9];
      $statinfo{'userprefs_current'}->{'size'} = $size;
      $statinfo{'userprefs_current'}->{'date'} = $date;
    }
    # userprefs_archive
    $path = "$fdir/last.user_prefs";
    if (-e "$path") {
      ($size, $date) = (stat("$path"))[7,9];
    }
    else {
      ($size, $date) = (stat("$g_skeldir/spamassassin.user_prefs"))[7,9];
    }
    $statinfo{'userprefs_archive'}->{'size'} = $size;
    $statinfo{'userprefs_archive'}->{'date'} = $date;
  }

  # if no files to check; then return
  return unless(keys(%statinfo));

  if ((($statinfo{'forward_current'}->{'size'} > 0) &&
       (($statinfo{'forward_current'}->{'size'} !=
         $statinfo{'forward_archive'}->{'size'}) ||
        ($statinfo{'forward_current'}->{'date'} >
         $statinfo{'forward_archive'}->{'date'}))) ||
     (($statinfo{'procmailrc_current'}->{'size'} > 0) &&
      (($statinfo{'procmailrc_current'}->{'size'} !=
        $statinfo{'procmailrc_archive'}->{'size'}) ||
       ($statinfo{'procmailrc_current'}->{'date'} >
        $statinfo{'procmailrc_archive'}->{'date'}))) ||
     (($statinfo{'userprefs_current'}->{'size'} > 0) &&
      (($statinfo{'userprefs_current'}->{'size'} !=
        $statinfo{'userprefs_archive'}->{'size'}) ||
       ($statinfo{'userprefs_current'}->{'date'} >
        $statinfo{'userprefs_archive'}->{'date'})))) {
    # something has changed externally -- print out a warning
    $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_FILTERS_TITLE : ";
    if ($action eq "enable") {
      $subtitle = $MAILMANAGER_FILTERS_ENABLE;
    }
    elsif ($action eq "disable") {
      $subtitle = $MAILMANAGER_FILTERS_DISABLE;
    }
    elsif ($action eq "set_mode") {
      $subtitle = $MAILMANAGER_FILTERS_MODE_SET;
    }
    elsif ($action eq "change_folder") {
      $subtitle = $MAILMANAGER_FILTERS_SPAM_FOLDER_CHANGE;
    }
    elsif ($action eq "save_lists") {
      $subtitle = $MAILMANAGER_FILTERS_LISTS_EDIT_STORE;
    }
    elsif ($action eq "save_log_opts") {
      $subtitle = $MAILMANAGER_FILTERS_LOG_OPTIONS_STORE;
    }
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader("$title $subtitle");
    #
    # sanity check table (2 cells: sidebar, contents)
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
    htmlTextBold("&#160;$MAILMANAGER_FILTERS_TITLE : $subtitle");
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
    # begin encapsulation table
    htmlTable();
    htmlTableRow();
    htmlTableData();
    # begin form
    formOpen();
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
    formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
    formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
    formInput("type", "hidden", "name", "sanitycheck", "value", "yes");
    formInput("type", "hidden", "name", "action", "value", $action);
    if ($g_form{'mode'}) {
      formInput("type", "hidden", "name", "mode", "value", $g_form{'mode'});
    }
    if ($g_form{'required_hits'}) {
      formInput("type", "hidden", "name", "required_hits", 
                "value", $g_form{'required_hits'});
    }
    if ($g_form{'savespam'}) {
      formInput("type", "hidden", "name", "savespam", 
                "value", $g_form{'savespam'});
    }
    if ($g_form{'spamfolder'}) {
      formInput("type", "hidden", "name", "spamfolder", 
                "value", $g_form{'spamfolder'});
    }
    if ($g_form{'whitelist'}) {
      formInput("type", "hidden", "name", "whitelist", 
                "value", $g_form{'whitelist'});
    }
    if ($g_form{'blacklist'}) {
      formInput("type", "hidden", "name", "blacklist", 
                "value", $g_form{'blacklist'});
    }
    if ($g_form{'logfile'}) {
      formInput("type", "hidden", "name", "logfile", 
                "value", $g_form{'logfile'});
    }
    if ($g_form{'logabstract'}) {
      formInput("type", "hidden", "name", "logabstract", 
                "value", $g_form{'logabstract'});
    }
    htmlText($MAILMANAGER_FILTERS_CONFIRM_WARNING_TEXT_1);
    htmlP();
    if (($statinfo{'forward_current'}->{'size'} > 0) &&
        (($statinfo{'forward_current'}->{'size'} !=
          $statinfo{'forward_archive'}->{'size'}) ||
         ($statinfo{'forward_current'}->{'date'} >
          $statinfo{'forward_archive'}->{'date'}))) {
      # .forward externally modified
      htmlUL();
      htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_FILENAME:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      htmlText(".forward");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_CURSIZE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $size = $statinfo{'forward_current'}->{'size'};
      if ($size < 1024) {
        $size = sprintf("%s $BYTES", $size);
      }
      elsif ($size < 1048576) {
        $size = sprintf("%1.1f $KILOBYTES", ($size / 1024));
      }
      else {
        $size = sprintf("%1.2f $MEGABYTES", ($size / 1048576));
      }
      htmlText($size);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_LASTSIZE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $size = $statinfo{'forward_archive'}->{'size'};
      if ($size < 1024) {
        $size = sprintf("%s $BYTES", $size);
      }
      elsif ($size < 1048576) {
        $size = sprintf("%1.1f $KILOBYTES", ($size / 1024));
      }
      else {
        $size = sprintf("%1.2f $MEGABYTES", ($size / 1048576));
      }
      htmlText($size);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_CURDATE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $date = $statinfo{'forward_current'}->{'date'};
      $date = dateBuildTimeString("alpha", $date);
      $date = dateLocalizeTimeString($date);
      htmlText($date);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_LASTDATE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $date = $statinfo{'forward_archive'}->{'date'};
      $date = dateBuildTimeString("alpha", $date);
      $date = dateLocalizeTimeString($date);
      htmlText($date);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlULClose();
      htmlP();
    }
    if (($statinfo{'procmailrc_current'}->{'size'} > 0) &&
        (($statinfo{'procmailrc_current'}->{'size'} !=
          $statinfo{'procmailrc_archive'}->{'size'}) ||
         ($statinfo{'procmailrc_current'}->{'date'} >
          $statinfo{'procmailrc_archive'}->{'date'}))) {
      # .procmailrc externally modified
      htmlUL();
      htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_FILENAME:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      htmlText(".procmailrc");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_CURSIZE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $size = $statinfo{'procmailrc_current'}->{'size'};
      if ($size < 1024) {
        $size = sprintf("%s $BYTES", $size);
      }
      elsif ($size < 1048576) {
        $size = sprintf("%1.1f $KILOBYTES", ($size / 1024));
      }
      else {
        $size = sprintf("%1.2f $MEGABYTES", ($size / 1048576));
      }
      htmlText($size);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_LASTSIZE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $size = $statinfo{'procmailrc_archive'}->{'size'};
      if ($size < 1024) {
        $size = sprintf("%s $BYTES", $size);
      }
      elsif ($size < 1048576) {
        $size = sprintf("%1.1f $KILOBYTES", ($size / 1024));
      }
      else {
        $size = sprintf("%1.2f $MEGABYTES", ($size / 1048576));
      }
      htmlText($size);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_CURDATE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $date = $statinfo{'procmailrc_current'}->{'date'};
      $date = dateBuildTimeString("alpha", $date);
      $date = dateLocalizeTimeString($date);
      htmlText($date);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_LASTDATE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $date = $statinfo{'procmailrc_archive'}->{'date'};
      $date = dateBuildTimeString("alpha", $date);
      $date = dateLocalizeTimeString($date);
      htmlText($date);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlULClose();
      htmlP();
    }
    if (($statinfo{'userprefs_current'}->{'size'} > 0) &&
        (($statinfo{'userprefs_current'}->{'size'} !=
          $statinfo{'userprefs_archive'}->{'size'}) ||
         ($statinfo{'userprefs_current'}->{'date'} >
          $statinfo{'userprefs_archive'}->{'date'}))) {
      # user_prefs externally modified
      htmlUL();
      htmlTable("cellspacing", "0", "cellpadding", "0", "border", "0");
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_FILENAME:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      htmlText("user_prefs");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_CURSIZE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $size = $statinfo{'userprefs_current'}->{'size'};
      if ($size < 1024) {
        $size = sprintf("%s $BYTES", $size);
      }
      elsif ($size < 1048576) {
        $size = sprintf("%1.1f $KILOBYTES", ($size / 1024));
      }
      else {
        $size = sprintf("%1.2f $MEGABYTES", ($size / 1048576));
      }
      htmlText($size);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_LASTSIZE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $size = $statinfo{'userprefs_archive'}->{'size'};
      if ($size < 1024) {
        $size = sprintf("%s $BYTES", $size);
      }
      elsif ($size < 1048576) {
        $size = sprintf("%1.1f $KILOBYTES", ($size / 1024));
      }
      else {
        $size = sprintf("%1.2f $MEGABYTES", ($size / 1048576));
      }
      htmlText($size);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_CURDATE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $date = $statinfo{'userprefs_current'}->{'date'};
      $date = dateBuildTimeString("alpha", $date);
      $date = dateLocalizeTimeString($date);
      htmlText($date);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableRow();
      htmlTableData("align", "left");
      htmlTextBold("$MAILMANAGER_EXTERNAL_CHANGES_WARNING_LASTDATE:");
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      htmlTableData("align", "left");
      $date = $statinfo{'userprefs_archive'}->{'date'};
      $date = dateBuildTimeString("alpha", $date);
      $date = dateLocalizeTimeString($date);
      htmlText($date);
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlULClose();
      htmlP();
    }
    if ($action eq "enable") {
      $atxt = $MAILMANAGER_FILTERS_ENABLE;
    }
    elsif ($action eq "disable") {
      $atxt = $MAILMANAGER_FILTERS_DISABLE;
    }
    elsif ($action eq "set_mode") {
      $atxt = $MAILMANAGER_FILTERS_MODE_SET;
    }
    elsif ($action eq "change_folder") {
      $atxt = $MAILMANAGER_FILTERS_SPAM_FOLDER_CHANGE;
    }
    elsif ($action eq "save_lists") {
      $atxt = $MAILMANAGER_FILTERS_LISTS_EDIT_STORE;
    }
    elsif ($action eq "save_log_opts") {
      $atxt = $MAILMANAGER_FILTERS_LOG_OPTIONS_STORE;
    }
    $MAILMANAGER_FILTERS_CONFIRM_WARNING_TEXT_2 =~ s/__ACTION__/$atxt/;
    htmlText($MAILMANAGER_FILTERS_CONFIRM_WARNING_TEXT_2);
    htmlP();
    formInput("type", "submit", "name", "proceed", "value",
              $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_IGNORE);
    formInput("type", "submit", "name", "proceed", "value",
              $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_RESTORE);
    formInput("type", "submit", "name", "proceed", "value", $CANCEL_STRING);
    formClose();
    # end encapsulation table
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
    # end parent table
    #
    labelCustomFooter();
    exit(0);
  }
}

##############################################################################

sub mailmanagerFiltersResetLog
{
  local($homedir, $fullpath, $folderpath, $output);

  mailmanagerSpamAssassinLoadSettings();

  $homedir = $g_users{$g_auth{'login'}}->{'home'};

  # nuke the log file
  $fullpath = $g_filters{'logfile'};
  $fullpath =~ s/\$HOME/$homedir/;
  if (unlink($fullpath)) {
    $output = $MAILMANAGER_FILTERS_LOG_FILE_RESET_SUCCESS;
    open(MYFP, ">$fullpath");
    close(MYFP);
  }
  else {
    $output = "unlink($g_filters{'logfile'}): $!";
  }
  # empty the spam folder (if applicable)
  if ($g_form{'resetoption'} ne "reset_only") {
    $folderpath = ($g_filters{'spamfolder'} eq "/dev/null") ? 
                   $g_filters{'last_spamfolder'} : $g_filters{'spamfolder'};
    $fullpath = $folderpath;
    $fullpath =~ s/\$HOME/$homedir/;
    $output .= "\n";
    if (unlink($fullpath)) {
      $output .= $MAILMANAGER_FILTERS_SPAM_FOLDER_NUKE_SUCCESS;
      open(MYFP, ">$fullpath");
      close(MYFP);
    }
    else {
      $output .= "unlink($g_filters{'logfile'}): $!";
    }
  }
  # redirect back to mail filtering index
  redirectLocation("mm_filters.cgi", $output);
}

##############################################################################

sub mailmanagerFiltersSaveLists
{
  local(@entries, $entry);

  # load old settings
  mailmanagerSpamAssassinLoadSettings();

  # overwrite whitelist with new settings
  @{$g_filters{'whitelist'}} = ();
  $g_form{'whitelist'} =~ s/\r\n/\n/g;
  $g_form{'whitelist'} =~ s/\r//g;
  @entries = split(/\n/, $g_form{'whitelist'});
  foreach $entry (@entries) {
    $entry =~ s/^\s+//;
    $entry =~ s/\s+$//;
    if (($entry !~ /^whitelist_to/i) && ($entry !~ /^whitelist_from/i)) {
      # presume user implied a '_from' entry if no spec
      $entry = "whitelist_from $entry";
    } 
    push(@{$g_filters{'whitelist'}}, $entry);
  }

  # overwrite blacklist with new settings
  @{$g_filters{'blacklist'}} = ();
  $g_form{'blacklist'} =~ s/\r\n/\n/g;
  $g_form{'blacklist'} =~ s/\r//g;
  @entries = split(/\n/, $g_form{'blacklist'});
  foreach $entry (@entries) {
    $entry =~ s/^\s+//;
    $entry =~ s/\s+$//;
    if (($entry !~ /^blacklist_to/) && ($entry !~ /^blacklist_from/)) {
      # presume user implied a '_from' entry if no spec
      $entry = "blacklist_from $entry";
    } 
    push(@{$g_filters{'blacklist'}}, $entry);
  }

  # write out new file(s)
  mailmanagerFiltersWriteSettings();

  # show success message
  redirectLocation("mm_filters.cgi", $MAILMANAGER_FILTERS_LISTS_EDIT_SUCCESS);
}

##############################################################################

sub mailmanagerFiltersSaveLoggingOptions
{
  # load old settings
  mailmanagerSpamAssassinLoadSettings();

  # overwrite with new settings
  $g_filters{'logabstract'} = $g_form{'logabstract'};
  $g_filters{'logfile'} = $g_form{'logfile'} if ($g_form{'logfile'});

  # write out new file(s)
  mailmanagerFiltersWriteSettings();

  # show success message
  redirectLocation("mm_filters.cgi", 
                   $MAILMANAGER_FILTERS_LOG_OPTIONS_CHANGE_SUCCESS);
}

##############################################################################

sub mailmanagerFiltersSaveSpamFolderOptions
{
  local($fdir, $path);

  # load old settings
  mailmanagerSpamAssassinLoadSettings();

  # overwrite with new settings
  if ($g_form{'savespam'} eq "no") {
    if ($g_filters{'spamfolder'} ne "/dev/null") {
      # save last specification to last.spamfolder
      $fdir = mailmanagerGetDirectoryPath("filters");
      $path = "$fdir/last.spamfolder";
      open(MFP, ">$path");
      print MFP "$g_filters{'spamfolder'}\n";
      close(MFP);
    }
    $g_filters{'spamfolder'} = "/dev/null";
  }
  else {
    $g_filters{'spamfolder'} = $g_form{'spamfolder'};
  }

  # write out new file(s)
  mailmanagerFiltersWriteSettings();

  # show success message
  redirectLocation("mm_filters.cgi", 
                   $MAILMANAGER_FILTERS_SPAM_FOLDER_CHANGE_SUCCESS);
}

##############################################################################

sub mailmanagerFiltersSetMode
{
  # load old settings
  mailmanagerSpamAssassinLoadSettings();

  # overwrite with new settings
  if ($g_form{'mode'} eq "strict") {
    $g_filters{'required_hits'} = "-10";
  }
  elsif ($g_form{'mode'} eq "permissive") {
    $g_filters{'required_hits'} = "100";
  }
  elsif ($g_form{'mode'} eq "default") {
    $g_filters{'required_hits'} = "5";
  }
  elsif ($g_form{'mode'} eq "custom") {
    $g_filters{'required_hits'} = $g_form{'required_hits'};
  }

  # write out new file(s)
  mailmanagerFiltersWriteSettings();

  # show success message
  redirectLocation("mm_filters.cgi", $MAILMANAGER_FILTERS_MODE_SET_SUCCESS);
}

##############################################################################

sub mailmanagerFiltersSetStatus
{
  local($homedir, $fdir, $idir, $lda);
  local($ar_enabled, $ar_mode, $ar_path, $ar_command, $ar_recipe);
  local(@prclines, $line, $vflag, $index, $mesg);
  local($folder, $fullpath, $languagepref, $sa_version);

  # load old settings
  mailmanagerSpamAssassinLoadSettings();

  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  $fdir = mailmanagerGetDirectoryPath("filters");
  $idir = $fdir;
  $idir =~ s/[^\/]+$//g;
  $idir =~ s/\/+$//g;

  $lda = mailmanagerGetLocalDeliveryAgent();

  $ar_enabled = mailmanagerNemetonAutoreplyGetStatus();
  if ($ar_enabled) {
    require "$g_includelib/mm_autoresponder.pl";
    $ar_mode = mailmanagerAutoresponderGetMode();
    $ar_mode = "autoreply" if ($ar_mode eq "n/a");
    $ar_path = ($ar_mode eq "vacation") ? "$g_skeldir/dot.forward_vacation" :
                                          "$g_skeldir/dot.forward_autoreply";
  }

  require "$g_includelib/backup.pl"; 
  backupUserFile("$homedir/.procmailrc");
  if ($lda !~ m#usr/local/bin/procmail#) {
    backupUserFile("$homedir/.forward");
  }

  if ($g_form{'action'} eq "enable") {
    # enable filtering; add spamassassin call to .procmailrc
    if ($g_form{'proceed'} eq $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_IGNORE) {
      # add a spamassassin section to procmailrc or just uncomment a 
      # previously disabled pipe to spamassassin recipe block
      $vflag = 1;  # append vinstall block flag
      open(TFP, "$homedir/.procmailrc.$$");
      open(SFP, "$homedir/.procmailrc");
      while (<SFP>) {
        if (/^\#\ IM_DISABLED\ /) {
          s/^\#\ IM_DISABLED\ //;
          $vflag = 0;  # don't append vinstall block
        }
        print TFP $_;
      }
      close(SFP);
      if ($vflag) {
        $sa_version = mailmanagerSpamAssassinGetVersion();
        if (mailmanagerSpamAssassinDaemonEnabled()) {
          open(SFP, "$g_skeldir/dot.procmailrc_spamc");
        }
        else {
          open(SFP, "$g_skeldir/dot.procmailrc");
        }
        while (<SFP>) {
          $curline = $_;
          $curline =~ s/__USER__/$g_auth{'login'}/;
          $curline =~ s/__LOGFILE__/$g_filters{'logfile'}/;
          $curline =~ s/__LOGABSTRACT__/$g_filters{'logabstract'}/;
          $curline =~ s/__SPAMFOLDER__/$g_filters{'spamfolder'}/;
          $curline =~ s/__AUTORESPONDER__//;
          print TFP $curline;
        }
        close(SFP);
      }
      if ($ar_enabled) {
        open(DFP, "$ar_path");
        $ar_command = <DFP>;
        close(DFP);
        chomp($ar_command);
        $ar_command =~ s/__HOME__/$homedir/g;
        $ar_command =~ s/\/+/\//g;
        $ar_command =~ s/\"//g;
        $ar_recipe = ":0 c\n\* \!^X-autoreply:\n$ar_command";
        print TFP "$ar_recipe\n";
      }
      close(TFP);
      rename("$homedir/.procmailrc.$$", "$homedir/.procmailrc");
      # copy .procmailrc to last.procmailrc (only require the proceed
      # and ignore conflicts warning one time... after that, it will be
      # presumed that the user has an ample supply of rope)
      open(SFP, "$homedir/.procmailrc");
      open(LFP, ">$idir/last.procmailrc");
      print LFP $_ while (<SFP>);
      close(LFP);
      close(SFP);
    }
    else {
      # build .procmailrc from skel
      open(TFP, ">$homedir/.procmailrc");
      open(LFP, ">$idir/last.procmailrc");
      $sa_version = mailmanagerSpamAssassinGetVersion();
      if (mailmanagerSpamAssassinDaemonEnabled()) {
        open(SFP, "$g_skeldir/dot.procmailrc_spamc");
      }
      else {
        open(SFP, "$g_skeldir/dot.procmailrc");
      }
      while (<SFP>) {
        $curline = $_;
        $curline =~ s/__USER__/$g_auth{'login'}/;
        $curline =~ s/__LOGFILE__/$g_filters{'logfile'}/;
        $curline =~ s/__LOGABSTRACT__/$g_filters{'logabstract'}/;
        $curline =~ s/__SPAMFOLDER__/$g_filters{'spamfolder'}/;
        if (/__AUTORESPONDER__/) {
          if ($ar_enabled) {
            open(DFP, "$ar_path");
            $ar_command = <DFP>;
            close(DFP);
            chomp($ar_command);
            $ar_command =~ s/__HOME__/$homedir/g;
            $ar_command =~ s/\/+/\//g;
            $ar_command =~ s/\"//g;
            $ar_recipe = ":0 c\n\* \!^X-autoreply:\n$ar_command";
            $curline =~ s/__AUTORESPONDER__/$ar_recipe/;
          }
          else {
            $curline =~ s/__AUTORESPONDER__//;
          }
        }
        print TFP $curline;
        print LFP $curline;
      }
      close(SFP);
      close(LFP);
      close(TFP);
    }
    # link last.procmailrc with HOME/.procmailrc
    utime($g_curtime, $g_curtime, "$homedir/.procmailrc");
    utime($g_curtime, $g_curtime, "$idir/last.procmailrc");
    # now that spamassassin rules have been included in the .procmailrc,
    # we need to rebuild .forward file (if applicable)
    if ($ar_enabled) {
      if ($g_form{'proceed'} eq $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_IGNORE) {
        # scan for autoreply and \__USER__ lines and remove
        open(TFP, ">$homedir/.forward.$$");
        open(SFP, "$homedir/.forward");
        while (<SFP>) {
          next if (/imanager.autoreply/);
          next if (/^\\__$g_auth{'login'}__/);
          print TFP $_;
        }
        close(SFP);
        close(TFP);
        rename("$homedir/.forward.$$", "$homedir/.forward");
        # copy .forward to last.forward (only require the proceed and
        # ignore conflicts warning one time... after that, it will be
        # presumed that the user has an ample supply of rope)
        open(SFP, "$homedir/.forward");
        open(LFP, ">$idir/last.forward");
        print LFP $_ while (<SFP>);
        close(LFP);
        close(SFP);
        # link last.forward with HOME/.forward
        utime($g_curtime, $g_curtime, "$homedir/.forward");
        utime($g_curtime, $g_curtime, "$idir/last.forward");
      }
      else {
        # nuke .forward and last.forward; these will be rebuilt below
        # if the local delievery agent is not procmail
        unlink("$homedir/.forward");
        unlink("$idir/last.forward");
      }
    }
    if ($lda !~ m#usr/local/bin/procmail#) {
      # local delivery agent != procmail
      if ($g_form{'proceed'} eq $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_IGNORE) {
        # print the appropriate pipe to procmail as first line in 
        # .forward file and scan the rest of the file and remove any
        # other occurrences to procmail (and autoresponders as well
        # since the pipe to the autoresponder will be in .procmailrc)
        open(TFP, ">$homedir/.forward.$$");
        open(SFP, "$g_skeldir/dot.forward_procmail");
        while (<SFP>) {
          s/__USER__/$g_auth{'login'}/g;
          print TFP $_;
        }
        close(SFP);
        open(SFP, "$homedir/.forward");
        while (<SFP>) {
          next if (m#/usr/local/bin/procmail#);
          next if (/imanager.autoreply/);
          print TFP $_;
        }
        close(SFP);
        close(TFP);
        rename("$homedir/.forward.$$", "$homedir/.forward");
        # copy .forward to last.forward (only require the proceed and
        # ignore conflicts warning one time... after that, it will be
        # presumed that the user has an ample supply of rope)
        open(SFP, "$homedir/.forward");
        open(LFP, ">$idir/last.forward");
        print LFP $_ while (<SFP>);
        close(LFP);
        close(SFP);
      }
      else {
        # build .forward file from skel
        open(TFP, ">$homedir/.forward");
        open(LFP, ">$idir/last.forward");
        open(SFP, "$g_skeldir/dot.forward_procmail");
        while (<SFP>) {
          s/__USER__/$g_auth{'login'}/g;
          print TFP $_;
          print LFP $_;
        }
        close(SFP);
        close(LFP);
        close(TFP);
      }
      # link last.forward with HOME/.forward
      utime($g_curtime, $g_curtime, "$homedir/.forward");
      utime($g_curtime, $g_curtime, "$idir/last.forward");
    }
    # make sure the directory for the spamfolder exists
    if ($g_filters{'spamfolder'} ne "/dev/null") {
      $folder = $g_filters{'spamfolder'};
      $folder =~ s/\$HOME/\~/;
      $folder =~ s/[^\/]+$//g;
      $folder =~ s/\/+$//g;
      $fullpath = mailmanagerBuildFullPath($folder); 
      mailmanagerCreateDirectory($fullpath);
    }
  }
  else {
    # disable filtering 
    if ($lda =~ m#usr/local/bin/procmail#) {
      # local delivery agent == procmail
      # remove spamassassin call from .procmailrc
      if ($g_form{'proceed'} eq $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_IGNORE) {
        # remove the spamassassin section from procmailrc (and remove the
        # autoreply call if applicable)
        open(SFP, "$homedir/.procmailrc");
        while (<SFP>) {
          next if (/imanager.autoreply/);  # skip an imanager autoreply
          if (/^\#\# begin spamassassin vinstall/) {
            $vflag = 1;
            next;
          }
          elsif (/^\#\# end spamassassin vinstall/) {
            $vflag = 0;
            next;
          }
          next if ($vflag);
          chomp;
          # check for spamassassin recipe block outside of vinstall block
          if ((m#^\|/usr/local/bin/spamc#) ||
              (m#^\|/usr/local/bin/spamassassin#)) {
            $_ = "# IM_DISABLED " . $_;
            for ($index=$#prclines; $index>=0; $index--) {
              $prclines[$index] = "# IM_DISABLED " . $prclines[$index];
              if ($prclines[$index] =~ /^\:/) {
                last;
              }
            }
          }
          push(@prclines, $_);
        }
        close(SFP);
        open(TFP, "$homedir/.procmailrc.$$");
        foreach $line (@prclines) {
          print TFP "$line\n";
        }
        close(TFP);
        rename("$homedir/.procmailrc.$$", "$homedir/.procmailrc");
        # copy .procmailrc to last.procmailrc (only require the proceed
        # and ignore conflicts warning one time... after that, it will be
        # presumed that the user has an ample supply of rope)
        open(SFP, "$homedir/.procmailrc");
        open(LFP, ">$idir/last.procmailrc");
        print LFP $_ while (<SFP>);
        close(LFP);
        close(SFP);
        # link last.procmailrc with HOME/.procmailrc
        utime($g_curtime, $g_curtime, "$homedir/.procmailrc");
        utime($g_curtime, $g_curtime, "$idir/last.procmailrc");
      }
      else {
        # nuke HOME/.procmailrc  
        unlink("$homedir/.procmailrc");
      }
    }
    else {
      # local delivery agent != procmail
      # remove procmail call from .forward file
      if ($g_form{'proceed'} eq $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_IGNORE) {
        # remove the procmail call from the .forward file
        open(TFP, ">$homedir/.forward.$$");
        open(SFP, "$homedir/.forward");
        while (<SFP>) {
          next if ((/^\"/) && (m#/usr/local/bin/procmail#));
          print TFP $_;
        }
        close(SFP);
        close(TFP);
        rename("$homedir/.forward.$$", "$homedir/.forward");
        # copy .forward to last.forward (only require the proceed and
        # ignore conflicts warning one time... after that, it will be
        # presumed that the user has an ample supply of rope)
        open(SFP, "$homedir/.forward");
        open(LFP, ">$idir/last.forward");
        print LFP $_ while (<SFP>);
        close(LFP);
        close(SFP);
        # link last.forward with HOME/.forward
        utime($g_curtime, $g_curtime, "$homedir/.forward");
        utime($g_curtime, $g_curtime, "$idir/last.forward");
      }
      else {
        # nuke HOME/.forward  
        unlink("$homedir/.forward");
        unlink("$idir/last.forward");
      }
    }
    # now that filters have been disabled, rebuild the .forward file 
    # with autoresponder call (if applicable)
    if ($ar_enabled) {
      if ($g_form{'proceed'} eq $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_IGNORE) {
        # change HOME/.forward (according to current mode)... scan
        # current .forward file and remove/replace/insert appropriate line
        open(TFP, ">$homedir/.forward.$$");
        open(SFP, "$homedir/.forward");
        open(DFP, "$ar_path");
        $ar_command = <DFP>;
        close(DFP);
        chomp($ar_command);
        $ar_command =~ s/__HOME__/$homedir/g;
        $ar_command =~ s/\/+/\//g;
        print TFP "$ar_command\n";
        while (<SFP>) {
          next if (/imanager.autoreply/);
          print TFP $_;
        }
        close(SFP);
        close(TFP);
        rename("$homedir/.forward.$$", "$homedir/.forward");
        # copy .forward to last.forward (only require the proceed and
        # ignore conflicts warning one time... after that, it will be
        # presumed that the user has an ample supply of rope)
        open(SFP, "$homedir/.forward");
        open(LFP, ">$idir/last.forward");
        print LFP $_ while (<SFP>);
        close(LFP);
        close(SFP);
      }
      else {
        # rebuild .forward file with template files found in skel
        open(TFP, ">$homedir/.forward");
        open(LFP, ">$idir/last.forward");
        open(SFP, "$ar_path");
        while (<SFP>) {
          s/__HOME__/$homedir/g;
          s/__USER__/$g_auth{'login'}/g;
          s/\/+/\//g;
          print TFP $_;
          print LFP $_;
        }
        close(SFP);
        close(LFP);
        close(TFP);
      }
      # link last.forward with HOME/.forward
      utime($g_curtime, $g_curtime, "$homedir/.forward");
      utime($g_curtime, $g_curtime, "$idir/last.forward");
    }
  }

  # show success message
  $mesg = $MAILMANAGER_FILTERS_STATUS_SET_SUCCESS;
  if ($g_form{'action'} eq "enable") {
    $mesg =~ s/__ACTION__/$MAILMANAGER_FILTERS_ENABLE/;
  }
  else {
    $mesg =~ s/__ACTION__/$MAILMANAGER_FILTERS_DISABLE/;
  }
  redirectLocation("mm_filters.cgi", $mesg);
}

##############################################################################

sub mailmanagerFiltersUpdateChineseJapaneseKoreanCharsetRules
{
  local($lang, $f_enabled, $homedir, $fdir);
  local(%statinfo, $linkflag, $size, $date, $curline);

  # this function should be called when a user changes their default
  # language encoding; it uncomments out or comments out scoring rules
  # located in the spamassassin user_prefs file.  the new language 
  # preference is available at g_form{'general__language'} 

  # only need to do this if filters are currently active; other
  # code takes care of the charset rules upon activation
  $f_enabled = mailmanagerSpamAssassinGetStatus();
  return unless($f_enabled);

  $lang = $g_form{'general__language'};

  mailmanagerSpamAssassinLoadSettings();

  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  $fdir = mailmanagerGetDirectoryPath("filters");

  $linkflag = 1;
  $statinfo{'userprefs_current'}->{'size'} = 0;
  $statinfo{'userprefs_current'}->{'date'} = 0;
  $statinfo{'userprefs_archive'}->{'size'} = 0;
  $statinfo{'userprefs_archive'}->{'date'} = 0;
  # userprefs_current
  $path = "$homedir/.spamassassin/user_prefs";
  if (-e "$path") {
    ($size, $date) = (stat("$path"))[7,9];
    $statinfo{'userprefs_current'}->{'size'} = $size;
    $statinfo{'userprefs_current'}->{'date'} = $date;
  }
  # userprefs_archive
  $path = "$fdir/last.user_prefs";
  if (-e "$path") {
    ($size, $date) = (stat("$path"))[7,9];
  }
  else {
    ($size, $date) = (stat("$g_skeldir/spamassassin.user_prefs"))[7,9];
  }
  $statinfo{'userprefs_archive'}->{'size'} = $size;
  $statinfo{'userprefs_archive'}->{'date'} = $date;
  if (($statinfo{'userprefs_current'}->{'size'} > 0) &&
      (($statinfo{'userprefs_current'}->{'size'} !=
        $statinfo{'userprefs_archive'}->{'size'}) ||
       ($statinfo{'userprefs_current'}->{'date'} >
        $statinfo{'userprefs_archive'}->{'date'}))) {
    # external modifications to user_prefs exist
    $linkflag = 0;
  }

  open(TFP, ">$homedir/.spamassassin/user_prefs.$$");
  open(LFP, ">$fdir/last.user_prefs") if ($linkflag);
  if ((-e "$homedir/.spamassassin/user_prefs") &&
      ((stat("$homedir/.spamassassin/user_prefs"))[7] > 0)) {
    require "$g_includelib/backup.pl"; 
    backupUserFile("$homedir/.spamassassin/user_prefs");
    open(SFP, "$homedir/.spamassassin/user_prefs");
  }
  else {
    open(SFP, "$g_skeldir/spamassassin.user_prefs");
  }
  while (<SFP>) {
    $curline = $_;
    if (($curline =~ /score HTML_COMMENT_8BITS/) ||
        ($curline =~ /score UPPERCASE_25_50/) ||
        ($curline =~ /score UPPERCASE_50_75/) ||
        ($curline =~ /score UPPERCASE_75_100/)) {
      if (($lang eq "ja") || ($lang eq "kr") || ($lang =~ /^zh/)) {
        # these lines need to be uncommented
        $curline =~ s/^\#+//;
        $curline =~ s/^\s+//;
      }
      else {
        # these lines need to be commented out
        $curline = "# $curline" unless ($curline =~ /^\#/);
      }
    }
    $curline =~ s/__WHITELIST__//;
    $curline =~ s/__BLACKLIST__//;
    $curline =~ s/__REQUIRED_HITS__/$g_filters{'required_hits'}/;
    print TFP $curline;
    print LFP $curline if ($linkflag)
  }
  close(SFP);
  close(TFP);
  rename("$homedir/.spamassassin/user_prefs.$$",
         "$homedir/.spamassassin/user_prefs");
  if ($linkflag) {
    close(LFP);
    utime($g_curtime, $g_curtime, "$homedir/.spamassassin/user_prefs");
    utime($g_curtime, $g_curtime, "$fdir/last.user_prefs");
  }
}

##############################################################################

sub mailmanagerFiltersViewLogFile
{
  local($fdir, %vprefs);
  local($title, $string, $datestring, $year, $mon, $day, $num);
  local($homedir, $fullpath, $lcount, %m_to_n, $date_end, $date_begin);
  local($mytime, $sender, $date, $subject, $size, $rlb, $rle);
  local($ymin, $ymax, $mmin, $mmax, $dmin, $dmax, $sday);
  local($languagepref, $pattern, $cnt, $len, $fmtstring);
  local(@lmon, $montxt);

  # load filter settings
  mailmanagerSpamAssassinLoadSettings();

  # load up submitted viewing options (or the defaults)
  $fdir = mailmanagerGetDirectoryPath("filters");
  if (open(FP, "$fdir/viewlog_prefs")) {
    while (<FP>) {
      chomp;
      /(.*)\:(.*)/;
      $vprefs{$1} = $2;
    }
    close(FP);
  }
  else {
    # defaults
    $vprefs{'date_option'} = "today";
    $vprefs{'date_custom_begin'} = -1;
    $vprefs{'date_custom_end'} = -1;
    $vprefs{'subject_filter'} = "disabled";
    $vprefs{'subject_pattern'} = "";
    $vprefs{'sender_filter'} = "disabled";
    $vprefs{'sender_pattern'} = "";
  }

  # need users language pref
  $languagepref = encodingGetLanguagePreference();

  # experimental
  if ($languagepref eq "ja") {
    $vprefs{'format_option'} = "table";
  }
  else {
    $vprefs{'format_option'} = "fixed";
  }

  # save current options
  if ($g_form{'change_submit'}) {
    $vprefs{'date_option'} = $g_form{'date_option'};
    if ($vprefs{'date_option'} eq "custom") {
      $vprefs{'date_custom_begin'} = $g_form{'custom_year_begin'};
      $vprefs{'date_custom_begin'} .= $g_form{'custom_mon_begin'};
      $vprefs{'date_custom_begin'} .= $g_form{'custom_day_begin'};
      $vprefs{'date_custom_begin'} =~ s/[^\w\-\.\*\@]//g;
      $vprefs{'date_custom_end'} = $g_form{'custom_year_end'};
      $vprefs{'date_custom_end'} .= $g_form{'custom_mon_end'};
      $vprefs{'date_custom_end'} .= $g_form{'custom_day_end'};
      $vprefs{'date_custom_end'} =~ s/[^\w\-\.\*]//g;
    }
    $vprefs{'subject_filter'} = $g_form{'subject_filter'} || "disabled";
    $vprefs{'subject_pattern'} = $g_form{'subject_pattern'};
    $vprefs{'sender_filter'} = $g_form{'sender_filter'} || "disabled";
    $vprefs{'sender_pattern'} = $g_form{'sender_pattern'};
    open(FP, ">$fdir/viewlog_prefs");
    foreach $key (sort(keys(%vprefs))) {
      print FP "$key:$vprefs{$key}\n";
    }
    close(FP);
  }

  htmlResponseHeader("Content-type: $g_default_content_type");

  # part 1 of the the document: the header
  $title = "$MAILMANAGER_TITLE_PLAIN - $MAILMANAGER_FILTERS_TITLE : ";
  $title .= $MAILMANAGER_FILTERS_LOG_TITLE;
  unless ($g_form{'print_submit'}) {
    # print out a summary header of the viewing options
    labelCustomHeader($title);
    #
    # spam log table (2 cells: sidebar, contents)
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
    htmlTextBold("&#160;$MAILMANAGER_FILTERS_TITLE : $MAILMANAGER_FILTERS_LOG_TITLE");
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
    # begin encapsulation table
    htmlTable();
    htmlTableRow();
    htmlTableData();
  }
  else {
    # printer friendly format
    htmlHtml();
    htmlHead();
    htmlTitle($title);
    htmlHeadClose();
    htmlBody("bgcolor", "#ffffff");
  }

  %m_to_n = ('jan', '01', 'feb', '02', 'mar','03', 'apr','04',
             'may', '05', 'jun', '06', 'jul','07', 'aug','08',
             'sep', '09', 'oct', '10', 'nov','11', 'dec','12');

  encodingIncludeStringLibrary("date");
  @lmon = ($MONTHS_JAN, $MONTHS_FEB, $MONTHS_MAR, $MONTHS_APR,
           $MONTHS_MAY, $MONTHS_JUN, $MONTHS_JUL, $MONTHS_AUG,
           $MONTHS_SEP, $MONTHS_OCT, $MONTHS_NOV, $MONTHS_DEC);

  # part 2 of the document: summary of display option and log file matches
  htmlTable();
  htmlTableRow();
  htmlTableData();
  htmlTextBold("$MAILMANAGER_FILTERS_LOG_FILE_SPEC:");
  htmlText("&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("align", "left", "colspan", "2");
  htmlNoBR();
  htmlText($g_filters{'logfile'});
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData();
  htmlTextBold("$MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_RANGE:");
  htmlText("&#160;&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("align", "left");
  $date_end = $date_begin = -1;
  if ($vprefs{'date_option'} eq "all") {
    $datestring = $MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_ALL;
  }
  elsif ($vprefs{'date_option'} eq "today") {
    $datestring = $MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_TODAY;
    ($day, $mon, $year) = (localtime($g_curtime))[3,4,5];
    $year += 1900;  $mon++;
    $date_end = $date_begin = sprintf "%04d%02d%02d", $year, $mon, $day;
  }
  elsif ($vprefs{'date_option'} eq "yesterday") {
    $datestring = $MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_YESTERDAY;
    $mytime = $g_curtime - (24 * 60 * 60);
    ($day, $mon, $year) = (localtime($mytime))[3,4,5];
    $year += 1900;  $mon++;
    $date_end = $date_begin = sprintf "%04d%02d%02d", $year, $mon, $day;
  }
  elsif ($vprefs{'date_option'} eq "last7days") {
    $datestring = $MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_LAST7DAYS;
    ($day, $mon, $year) = (localtime($g_curtime))[3,4,5];
    $year += 1900;  $mon++;
    $date_end = sprintf "%04d%02d%02d", $year, $mon, $day;
    $mytime = $g_curtime - (6 * 24 * 60 * 60);
    ($day, $mon, $year) = (localtime($mytime))[3,4,5];
    $year += 1900;  $mon++;
    $date_begin = sprintf "%04d%02d%02d", $year, $mon, $day;
  }
  elsif ($vprefs{'date_option'} eq "custom") {
    $year = substr($vprefs{'date_custom_begin'}, 0, 4);
    $mon = substr($vprefs{'date_custom_begin'}, 4, 2);
    $mon =~ s/^0//;
    $day = substr($vprefs{'date_custom_begin'}, 6, 2);
    $day =~ s/^0//;
    $string = $g_months[$mon-1] . " " . $day . " " . $year;
    $date_begin = sprintf "%04d%02d%02d", $year, $mon, $day;
    $datestring = dateLocalizeTimeString($string);
    $year = substr($vprefs{'date_custom_end'}, 0, 4);
    $mon = substr($vprefs{'date_custom_end'}, 4, 2);
    $mon =~ s/^0//;
    $day = substr($vprefs{'date_custom_end'}, 6, 2);
    $day =~ s/^0//;
    $string = $g_months[$mon-1] . " " . $day . " " . $year;
    $datestring .= " -> " . dateLocalizeTimeString($string);
    $date_end = sprintf "%04d%02d%02d", $year, $mon, $day;
  }
  htmlText($datestring);
  htmlTableDataClose();
  htmlTableData("align", "left");
  htmlText("&#160;&#160;&#160;&#160;&#160;");
  unless ($g_form{'print_submit'}) {
    htmlText("[ ");
    if ((($vprefs{'sender_filter'} eq "enabled") &&
         ($vprefs{'sender_pattern'})) ||
        (($vprefs{'subject_filter'} eq "enabled") &&
         ($vprefs{'subject_pattern'}))) {
      htmlAnchor("href", "#cdo", 
                 "title", $MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_CHANGE);
      htmlAnchorText($MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_CHANGE);
    }
    else {
      htmlAnchor("href", "#cdo",
                 "title", $MAILMANAGER_FILTERS_LOG_DISPLAY_CHANGE);
      htmlAnchorText($MAILMANAGER_FILTERS_LOG_DISPLAY_CHANGE);
    }
    htmlAnchorClose();
    htmlText(" ]");
  }
  htmlTableDataClose();
  htmlTableRowClose();
  if (($vprefs{'sender_filter'} eq "enabled") &&
      ($vprefs{'sender_pattern'})) {
    htmlTableRow();
    htmlTableData();
    htmlTextBold("$MAILMANAGER_FILTERS_LOG_DISPLAY_SENDER_MATCH:");
    htmlText("&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlText("/$vprefs{'sender_pattern'}/");
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    unless ($g_form{'print_submit'}) {
      htmlText("[ ");
      htmlAnchor("href", "#cdo",
                 "title", $MAILMANAGER_FILTERS_LOG_DISPLAY_SENDER_CHANGE);
      htmlAnchorText($MAILMANAGER_FILTERS_LOG_DISPLAY_SENDER_CHANGE);
      htmlAnchorClose();
      htmlText(" ]");
    }
    htmlTableDataClose();
    htmlTableRowClose();
  }
  if (($vprefs{'subject_filter'} eq "enabled") &&
      ($vprefs{'subject_pattern'})) {
    htmlTableRow();
    htmlTableData();
    htmlTextBold("$MAILMANAGER_FILTERS_LOG_DISPLAY_SUBJECT_MATCH:");
    htmlText("&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlText("/$vprefs{'subject_pattern'}/");
    htmlTableDataClose();
    htmlTableData("align", "left");
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    unless ($g_form{'print_submit'}) {
      htmlText("[ ");
      htmlAnchor("href", "#cdo",
                 "title", $MAILMANAGER_FILTERS_LOG_DISPLAY_SUBJECT_CHANGE);
      htmlAnchorText($MAILMANAGER_FILTERS_LOG_DISPLAY_SUBJECT_CHANGE);
      htmlAnchorClose();
      htmlText(" ]");
    }
    htmlTableDataClose();
    htmlTableRowClose();
  }
  htmlTableClose();
  htmlP();
  # step through the log and show the messages that match the viewing options
  $lcount = 0;
  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  $fullpath = $g_filters{'logfile'};
  $fullpath =~ s/\$HOME/$homedir/;
  $rlb = $rle = -1;  # date range of log file
  if (open(FP, "$fullpath")) {
    while (<FP>) {
      chomp;
      if (/^From\s+(.*)\s+(Sun|Mon|Tue|Wed|Thu|Fri|Sat)(.*)/) {
        # sender/date entry encountered
        $sender = $1;
        $datestring = $2 . $3;
        $datestring =~ /\S+\s+(\S+)\s+(\S+)\s+\S+\s+(\S+)/;
        $mon = $1;
        $mon =~ tr/A-Z/a-z/;
        $mon = $m_to_n{$mon};
        $day = $2;
        $year = $3;
        $date = sprintf "%04d%02d%02d", $year, $mon, $day;
        $rlb = $date if (($rlb < 0) || ($date < $rlb));
        $rle = $date if (($rle < 0) || ($date > $rle));
        $pattern = $vprefs{'sender_pattern'};
        $pattern =~ s/\./\\\./;
        $pattern =~ s/\-/\\\-/;
        $pattern =~ s/\@/\\\@/;
        $pattern =~ s/\*/\.\*/;
        next if (($vprefs{'sender_filter'} eq "enabled") &&
                 ($pattern) && ($sender !~ /$pattern/i));
        next if (($date_begin > 0) && ($date_end > 0) &&
                 (($date < $date_begin) || ($date > $date_end)));
        # get subject 
        $subject = <FP>;
        chomp($subject);
        if ($subject =~ /^\s+Subject:/) {
          $subject =~ s/^\s+Subject:\s+//;
          $subject =~ s/\s+$//;
          if ($subject) {
            if ($languagepref eq "ja") {
              $subject = mailmanagerMimeDecodeHeaderJP_QP($subject);
              $subject = jcode'euc(mimedecode($subject));
            }
            $subject = mailmanagerMimeDecodeHeader($subject);
          }
          $pattern = $vprefs{'subject_pattern'};
          $pattern =~ s/\./\\\./;
          $pattern =~ s/\-/\\\-/;
          $pattern =~ s/\*/\.\*/;
          next if (($vprefs{'subject_filter'} eq "enabled") && ($pattern) && 
                   ((!$subject) || ($subject !~ /$pattern/i)));
          # get folder/size
          $size = <FP>;
          chomp($size);
        }
        else {
          # missing Subject line... presume the line is folder/size
          $size = $subject;
          $subject = "";
        }
        $size =~ /\s+\S+\s+\S+\s+(\S+)/;
        $size = $1;
        if ($lcount == 0) {
          if ($vprefs{'format_option'} eq "fixed") {
            htmlPre();
            htmlFont("class", "fixed", "face", "courier new, courier", "size", "2", 
                     "style", "font-family: courier new, courier; font-size: 12px");
            htmlBold();
            printf " %-12s ", $MAILMANAGER_MESSAGE_DATE;
            printf "%-30s ", $MAILMANAGER_MESSAGE_SENDER;
            printf "%-60s ", $MAILMANAGER_MESSAGE_SUBJECT;
            printf "%8s ", $MAILMANAGER_MESSAGE_SIZE_ABBREVIATED;
            htmlBoldClose();
            print "\n";
          }
          else {
            htmlTable("border", "0", "cellpadding", "0", "cellspacing", "1");
            htmlTableRow();
            htmlTableData("align", "left");
            htmlFont("class", "fixed", "face", "courier new, courier", "size", "2", 
                     "style", "font-family: courier new, courier; font-size: 12px");
            htmlBold();
            print "$MAILMANAGER_MESSAGE_DATE";
            htmlBoldClose();
            htmlFontClose();
            htmlTableDataClose();
            htmlTableData("align", "left");
            htmlFont("class", "fixed", "face", "courier new, courier", "size", "2", 
                     "style", "font-family: courier new, courier; font-size: 12px");
            htmlBold();
            print "$MAILMANAGER_MESSAGE_SENDER";
            htmlBoldClose();
            htmlFontClose();
            htmlTableDataClose();
            htmlTableData("align", "left");
            htmlFont("class", "fixed", "face", "courier new, courier", "size", "2", 
                     "style", "font-family: courier new, courier; font-size: 12px");
            htmlBold();
            print "$MAILMANAGER_MESSAGE_SUBJECT";
            htmlBoldClose();
            htmlFontClose();
            htmlTableDataClose();
            htmlTableData("align", "right");
            htmlFont("class", "fixed", "face", "courier new, courier", "size", "2", 
                     "style", "font-family: courier new, courier; font-size: 12px");
            htmlBold();
            print "$MAILMANAGER_MESSAGE_SIZE_ABBREVIATED";
            htmlBoldClose();
            htmlFontClose();
            htmlTableDataClose();
            htmlTableRowClose();
          }
        }
        $lcount++;
        $datestring =~ /\S+\s+(\S+)\s+(\S+)\s+\S+\s+(\S+)/;
        $datestring = sprintf "$1 %02d $3", $2;
        $datestring = dateLocalizeTimeString($datestring);
        if ($languagepref eq "ja") {
          $sender = mailmanagerMimeDecodeHeaderJP_QP($sender);
          $sender = jcode'euc(mimedecode($sender));
        }
        if (length($sender) > 30) {
          $sender = substr($sender, 0, 29) . "&#133;";
        }
        if ($subject) {
          if ($languagepref eq "ja") {
            $subject = mailmanagerMimeDecodeHeaderJP_QP($subject);
            $subject = jcode'euc(mimedecode($subject));
          }
          $subject = mailmanagerMimeDecodeHeader($subject);
          if (($languagepref ne "ja") && (length($subject) > 60)) {
            $subject = substr($subject, 0, 59) . "&#133;";
          }
        }
        else {
          $subject = $MAILMANAGER_NO_SUBJECT;
        }
        if (length($subject) > 60) {
          $subject = substr($subject, 0, 59) . "&#133;"; 
        }
        # print out entry
        if ($vprefs{'format_option'} eq "fixed") {
          printf " %-12s ", $datestring;
          # dress up the sender for a fixed display
          $string = $sender;
          $len = 30;
          $cnt = $string =~ s/\&/\&/g;
          if ($string =~ /\&\#133;$/) {
            $cnt--;
            $string = substr($string, 0, 29);
            $string =~ s/\&/\&\#38;/g;
            $len += ($cnt * 4);
            $string .= "&#133;";
            $len += 5;
          }
          else {
            $string =~ s/\&/\&\#38;/g;
            $len += ($cnt * 4);
          }
          $cnt = $string =~ s/\</\</g;
          $string =~ s/\</\&lt;/g;
          $len += ($cnt * 3);
          $fmtstring = "%-" . $len . "s ";
          printf $fmtstring, $string;
          # dress up the subject for a fixed display
          $string = $subject; 
          $len = 60;
          $cnt = $string =~ s/\&/\&/g;
          if ($string =~ /\&\#133;$/) {
            $cnt--;
            $string = substr($string, 0, 59);
            $string =~ s/\&/\&\#38;/g;
            $len += ($cnt * 4);
            $string .= "&#133;";
            $len += 5;
          }
          else {
            $string =~ s/\&/\&\#38;/g;
            $len += ($cnt * 4);
          }
          $cnt = $string =~ s/\</\</g;
          $string =~ s/\</\&lt;/g;
          $len += ($cnt * 3);
          $fmtstring = "%-" . $len . "s ";
          printf $fmtstring, $string;
          printf "%8s", $size;
          print "\n";
        }
        else {
          htmlTableRow();
          htmlTableData("align", "left");
          htmlFont("class", "fixed", "face", "courier new, courier", "size", "2", 
                   "style", "font-family: courier new, courier; font-size: 12px");
          htmlNoBR();
          print "$datestring&#160;&#160;";
          htmlNoBRClose();
          htmlFontClose();
          htmlTableDataClose();
          htmlTableData("align", "left");
          htmlFont("class", "fixed", "face", "courier new, courier", "size", "2", 
                   "style", "font-family: courier new, courier; font-size: 12px");
          htmlNoBR();
          print "$sender&#160;&#160;";
          htmlNoBRClose();
          htmlFontClose();
          htmlTableDataClose();
          htmlTableData("align", "left");
          htmlFont("class", "fixed", "face", "courier new, courier", "size", "2", 
                   "style", "font-family: courier new, courier; font-size: 12px");
          htmlNoBR();
          print "$subject&#160;&#160;";
          htmlNoBRClose();
          htmlFontClose();
          htmlTableDataClose();
          htmlTableData("align", "right");
          htmlFont("class", "fixed", "face", "courier new, courier", "size", "2", 
                   "style", "font-family: courier new, courier; font-size: 12px");
          print "$size";
          htmlFontClose();
          htmlTableDataClose();
          htmlTableRowClose();
        }
      }
    }
    close(FP);
    if ($lcount == 0) {
      htmlTextItalic($MAILMANAGER_FILTERS_LOG_DISPLAY_NO_MATCHES);
    }
    else {
      if ($vprefs{'format_option'} eq "fixed") {
        htmlFontClose();
        htmlPreClose();
        print "\n";
      }
      else {
        htmlTableClose();
      }
    }
  }
  else {
    htmlTextItalic($MAILMANAGER_FILTERS_LOG_DISPLAY_NO_ENTRIES);
  }
  htmlP();
  
  # part 3 of the the document: the header
  unless ($g_form{'print_submit'}) {
    # print out the change viewing options form
    formOpen("method", "POST");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
    formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
    formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
    formInput("type", "hidden", "name", "action", "value", "view_log");
    formInput("type", "submit", "name", "print_submit", "value",
              $MAILMANAGER_PRINTER_FRIENDLY_FORMAT);
    formClose();
    htmlP();
    htmlTable("cellpadding", "0", "cellspacing", "0", "border", "0", 
              "background", "$g_graphicslib/dotted.png", "width", "100\%");
    htmlTableRow();
    htmlTableData();
    htmlAnchor("name", "cdo");
    htmlImg("border", "0", "width", "1", "height", "1", 
            "src", "$g_graphicslib/sp.gif");
    htmlAnchorClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlP();
    formOpen("method", "POST");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
    formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
    formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
    formInput("type", "hidden", "name", "action", "value", "view_log");
    htmlTable("border", "0", "width", "750");
    htmlTableRow();
    htmlTableData("valign", "top");
    htmlNoBR();
    htmlTextBold("$MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_RANGE:");
    htmlNoBRClose();
    htmlBR();
    htmlTable("border", "0");
    htmlTableRow();
    htmlTableData("valign", "middle");
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    formInput("type", "radio", "name", "date_option", "value", "all",
              "_OTHER_", ($vprefs{'date_option'} eq "all") ? "CHECKED" : "");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    htmlText($MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_ALL);
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData("valign", "middle");
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    formInput("type", "radio", "name", "date_option", "value", "today",
              "_OTHER_", 
              ($vprefs{'date_option'} eq "today") ? "CHECKED" : "");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    htmlText($MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_TODAY);
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData("valign", "middle");
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    formInput("type", "radio", "name", "date_option", "value", "yesterday",
              "_OTHER_", 
              ($vprefs{'date_option'} eq "yesterday") ? "CHECKED" : "");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    htmlText($MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_YESTERDAY);
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData("valign", "middle");
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    formInput("type", "radio", "name", "date_option", "value", "last7days",
              "_OTHER_", 
              ($vprefs{'date_option'} eq "last7days") ? "CHECKED" : "");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    htmlText($MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_LAST7DAYS);
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData("valign", "middle");
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    formInput("type", "radio", "name", "date_option", "value", "custom",
              "_OTHER_", 
              ($vprefs{'date_option'} eq "custom") ? "CHECKED" : "");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    htmlText($MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_CUSTOM);
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData("valign", "middle");
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    htmlTable("border", "0", "cellspacing", "0", "cellpadding", "0");
    htmlTableRow();
    htmlTableData("valign", "middle");
    htmlNoBR();
    htmlTextSmall($MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_CUSTOM_FROM);
    htmlText("&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    formSelect("name", "custom_year_begin", "style", "display:inline; font-size: 10px; font-family: Verdana, Arial, Helvetica");
    ($year) = (localtime($g_curtime))[5];
    $year += 1900;
    $ymin = ($rlb > 0) ? (substr($rlb, 0, 4)) : ($year-1);
    $ymax = ($rle > 0) ? (substr($rle, 0, 4)) : ($year+1);
    for ($num=$ymin; $num<=$ymax; $num++) {
      $otxt = $num;
      if ($languagepref eq "ja") {
        $otxt .= " 年";
      }
      formSelectOption($num, $otxt, 
                       (($vprefs{'date_custom_begin'} > -1) ? 
                        ($num == substr($vprefs{'date_custom_begin'}, 0, 4)) :
                        ($num == $year)));
    }
    formSelectClose();
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    formSelect("name", "custom_mon_begin", "style", "display:inline; line-height:12px; font-size: 10px; font-family: Verdana, Arial, Helvetica");
    if ($ymin == $ymax) {
      $mmin = ($rlb > 0) ? (substr($rlb, 4, 2)) : 1;
      $mmax = ($rle > 0) ? (substr($rle, 4, 2)) : 12;
      $mmin =~ s/^0//;  $mmax =~ s/^0//;
    }
    else {
      $mmin = 1;
      $mmax = 12;
    }
    for ($num=$mmin; $num<=$mmax; $num++) {
      $mon = ($num >= 10) ? $num : "0$num";
      $otxt = $lmon[$num-1];
      if ($languagepref eq "ja") {
        $otxt .= " 月";
      }
      formSelectOption($mon, $otxt,
                       (($vprefs{'date_custom_begin'} > -1) ? 
                        ($mon == substr($vprefs{'date_custom_begin'}, 4, 2)) :
                        ($num == $mmin)));
    }
    formSelectClose();
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    formSelect("name", "custom_day_begin", "style", "display:inline; line-height:12px; font-size: 10px; font-family: Verdana, Arial, Helvetica");
    if (($ymin == $ymax) && ($mmin == $mmax)) {
      $dmin = ($rlb > 0) ? (substr($rlb, 6, 2)) : 1;
      $dmax = ($rle > 0) ? (substr($rle, 6, 2)) : 31;
      $dmin =~ s/^0//;  $mmax =~ s/^0//;
    }
    else {
      $dmin = 1;
      $dmax = 31;
    }
    $sday = ($rlb > 0) ? (substr($rlb, 6, 2)) : 1;
    $sday =~ s/^0//;
    for ($num=$dmin; $num<=$dmax; $num++) {
      $day = ($num >= 10) ? $num : "0$num";
      $otxt = $num;
      if ($languagepref eq "ja") {
        $otxt .= " 日";
      }
      formSelectOption($day, $otxt,
                       (($vprefs{'date_custom_begin'} > -1) ? 
                        ($day == substr($vprefs{'date_custom_begin'}, 6, 2)) :
                        ($num == $sday)));
    }
    formSelectClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData("valign", "middle", "align", "right");
    htmlNoBR();
    htmlTextSmall($MAILMANAGER_FILTERS_LOG_DISPLAY_DATE_CUSTOM_TO);
    htmlText("&#160;");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    formSelect("name", "custom_year_end", "style", "display:inline; font-size: 10px; font-family: Verdana, Arial, Helvetica");
    ($year) = (localtime($g_curtime))[5];
    $year += 1900;
    $ymin = ($rlb > 0) ? (substr($rlb, 0, 4)) : ($year-1);
    $ymax = ($rle > 0) ? (substr($rle, 0, 4)) : ($year+1);
    for ($num=$ymin; $num<=$ymax; $num++) {
      $otxt = $num;
      if ($languagepref eq "ja") {
        $otxt .= " 年";
      }
      formSelectOption($num, $otxt, 
                       (($vprefs{'date_custom_end'} > -1) ? 
                        ($num == substr($vprefs{'date_custom_end'}, 0, 4)) :
                        ($num == $year)));
    }
    formSelectClose();
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    formSelect("name", "custom_mon_end", "style", "display:inline; line-height:12px; font-size: 10px; font-family: Verdana, Arial, Helvetica");
    if ($ymin == $ymax) {
      $mmin = ($rlb > 0) ? (substr($rlb, 4, 2)) : 1;
      $mmax = ($rle > 0) ? (substr($rle, 4, 2)) : 12;
      $mmin =~ s/^0//;  $mmax =~ s/^0//;
    }
    else {
      $mmin = 1;
      $mmax = 12;
    }
    for ($num=$mmin; $num<=$mmax; $num++) {
      $mon = ($num >= 10) ? $num : "0$num";
      $otxt = $lmon[$num-1];
      if ($languagepref eq "ja") {
        $otxt .= " 月";
      }
      formSelectOption($mon, $otxt,
                       (($vprefs{'date_custom_end'} > -1) ? 
                        ($mon == substr($vprefs{'date_custom_end'}, 4, 2)) :
                        ($num == $mmax)));
    }
    formSelectClose();
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    formSelect("name", "custom_day_end", "style", "display:inline; line-height:12px; font-size: 10px; font-family: Verdana, Arial, Helvetica");
    if (($ymin == $ymax) && ($mmin == $mmax)) {
      $dmin = ($rlb > 0) ? (substr($rlb, 6, 2)) : 1;
      $dmax = ($rle > 0) ? (substr($rle, 6, 2)) : 12;
      $dmin =~ s/^0//;  $mmax =~ s/^0//;
    }
    else {
      $dmin = 1;
      $dmax = 31;
    }
    $sday = ($rle > 0) ? (substr($rle, 6, 2)) : 1;
    $sday =~ s/^0//;
    for ($num=$dmin; $num<=$dmax; $num++) {
      $day = ($num >= 10) ? $num : "0$num";
      $otxt = $num;
      if ($languagepref eq "ja") {
        $otxt .= " 日";
      }
      formSelectOption($day, $otxt,
                       (($vprefs{'date_custom_end'} > -1) ? 
                        ($day == substr($vprefs{'date_custom_end'}, 6, 2)) :
                        ($num == $sday)));
    }
    formSelectClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTableDataClose();
    htmlTableData("valign", "top");
    htmlText("&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top");
    htmlTextBold("$MAILMANAGER_FILTERS_LOG_DISPLAY_SENDER_PATTERN:");
    htmlBR();
    htmlTable();
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top", "align", "right");
    htmlNoBR();
    htmlText("&#160;");
    formInput("type", "checkbox", "name", "sender_filter", "value", "enabled",
              "_OTHER_", 
              ($vprefs{'sender_filter'} eq "enabled") ? "CHECKED" : "");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("valign", "top", "align", "left");
    htmlText($MAILMANAGER_FILTERS_LOG_DISPLAY_SENDER_HELP);
    htmlBR();
    $size = formInputSize(40);
    formInput("size", $size, "name", "sender_pattern", 
              "value", $vprefs{'sender_pattern'});
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTextBold("$MAILMANAGER_FILTERS_LOG_DISPLAY_SUBJECT_PATTERN:");
    htmlBR();
    htmlTable();
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "top", "align", "right");
    htmlNoBR();
    htmlText("&#160;");
    formInput("type", "checkbox", "name", "subject_filter", "value", "enabled",
              "_OTHER_", 
              ($vprefs{'subject_filter'} eq "enabled") ? "CHECKED" : "");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("valign", "top", "align", "left");
    htmlText($MAILMANAGER_FILTERS_LOG_DISPLAY_SUBJECT_HELP);
    htmlBR();
    formInput("size", $size, "name", "subject_pattern", 
              "value", $vprefs{'subject_pattern'});
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    htmlTable();
    htmlTableRow();
    htmlTableData();
    formInput("type", "submit", "name", "change_submit", "value",
              $MAILMANAGER_FILTERS_LOG_DISPLAY_CHANGE);
    formClose();
    htmlTableDataClose();
    htmlTableData();
    formOpen("method", "POST");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
    formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
    formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
    formInput("type", "hidden", "name", "action", "value", "confirm_reset");
    formInput("type", "submit", "name", "submit", "value", 
              $MAILMANAGER_FILTERS_LOG_FILE_RESET);
    formClose();
    htmlTableDataClose();
    htmlTableData();
    formOpen("method", "POST");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "mbox", "value", $g_form{'mbox'});
    formInput("type", "hidden", "name", "mpos", "value", $g_form{'mpos'});
    formInput("type", "hidden", "name", "mrange", "value", $g_form{'mrange'});
    formInput("type", "hidden", "name", "msort", "value", $g_form{'msort'});
    formInput("type", "submit", "name", "action", "value", 
              $MAILMANAGER_FILTERS_RETURN);
    formClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    # end encapsulation table
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
    # end parent table
    #
    labelCustomFooter();
  }
  else {
    # printer friendly format
    htmlBodyClose();
    htmlHtmlClose();
  }
}

##############################################################################

sub mailmanagerFiltersWriteSettings
{
  local($homedir, $fdir, $idir, $entry, $curline, $lda, $f_enabled);
  local($ar_mode, $ar_enabled, $ar_command, $ar_recipe, $path);
  local(@prclines, $index, $flag, $lff, $laf, $languagepref);
  local($sa_version);

  $homedir = $g_users{$g_auth{'login'}}->{'home'};

  $fdir = mailmanagerGetDirectoryPath("filters");
  $idir = $fdir;
  $idir =~ s/[^\/]+$//g;
  $idir =~ s/\/+$//g;

  if (($g_form{'action'} eq "set_mode") || 
      ($g_form{'action'} eq "save_lists")) {
    # writing to user_prefs; make sure everything looks good
    unless (-e "$homedir/.spamassassin") {
      mkdir("$homedir/.spamassassin", 0755);
    }
    # backup current user_prefs first
    require "$g_includelib/backup.pl"; 
    backupUserFile("$homedir/.spamassassin/user_prefs");
    # get language preference
    $languagepref = encodingGetLanguagePreference();
    # save changes to spamassassin user_prefs
    if ($g_form{'proceed'} eq $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_IGNORE) {
      # scan current user_prefs file and replace appropriate entries
      open(TFP, ">$homedir/.spamassassin/user_prefs.$$");
      open(SFP, "$homedir/.spamassassin/user_prefs");
      while (<SFP>) {
        if (/^required_hits/i) {
          print TFP "required_hits $g_filters{'required_hits'}\n";
        }
        elsif (/^whitelist/i) {
          # ignore all current whitelist entries; but write the new list
          # when encountering the first whitelist entry
          foreach $entry (@{$g_filters{'whitelist'}}) {
            print TFP "$entry\n";
          }
          @{$g_filters{'whitelist'}} = ();
        }
        elsif (/^blacklist/i) {
          # ignore all current blacklist entries; but write the new list
          # when encountering the first blacklist entry
          foreach $entry (@{$g_filters{'blacklist'}}) {
            print TFP "$entry\n";
          }
          @{$g_filters{'blacklist'}} = ();
        }
        elsif ((/score HTML_COMMENT_8BITS/) || 
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
        }
        else {
          print TFP $_;
        }
      }
      close(SFP);
      close(TFP);
      rename("$homedir/.spamassassin/user_prefs.$$",
             "$homedir/.spamassassin/user_prefs");
      # copy user_prefs to last.user_prefs (only require the proceed 
      # and ignore conflicts warning one time... after that, it will 
      # be presumed that the user has an ample supply of rope)
      open(SFP, "$homedir/.spamassassin/user_prefs");
      open(LFP, ">$fdir/last.user_prefs");
      print LFP $_ while (<SFP>);
      close(LFP);
      close(SFP);
    }
    else {
      # rebuild user_prefs from skel
      open(TFP, ">$homedir/.spamassassin/user_prefs");
      open(LFP, ">$fdir/last.user_prefs");
      open(SFP, "$g_skeldir/spamassassin.user_prefs");
      while (<SFP>) {
        if (/__WHITELIST__/) {
          foreach $entry (@{$g_filters{'whitelist'}}) {
            print TFP "$entry\n";
            print LFP "$entry\n";
          }
        }
        elsif (/__BLACKLIST__/) {
          foreach $entry (@{$g_filters{'blacklist'}}) {
            print TFP "$entry\n";
            print LFP "$entry\n";
          }
        }
        elsif ((/score HTML_COMMENT_8BITS/) || 
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
          s/__REQUIRED_HITS__/$g_filters{'required_hits'}/;
          print TFP $_;
          print LFP $_;
        }
      }
      close(SFP);
      close(LFP);
      close(TFP);
    }
    # link last.user_prefs with HOME/.spamassassin/user_prefs
    utime($g_curtime, $g_curtime, "$homedir/.spamassassin/user_prefs");
    utime($g_curtime, $g_curtime, "$fdir/last.user_prefs");
  }
  else {
    # action eq "change_folder" || "save_log_opts" ... change .procmailrc
    # so... backup current user_prefs first
    require "$g_includelib/backup.pl"; 
    backupUserFile("$homedir/.procmailrc");
    # save changes to .procmailrc
    if ($g_form{'proceed'} eq $MAILMANAGER_EXTERNAL_CHANGES_PROCEED_IGNORE) {
      # rewrite entries in .procmailrc (if found)
      open(SFP, "$homedir/.procmailrc");
      while (<SFP>) {
        chomp;
        push(@prclines, $_);
      }
      close(SFP);
      $flag = 0;
      for ($index=0; $index<=$#prclines; $index++) {
        $flag = 1 if ($prclines[$index] =~ m#^\|/usr/local/bin/spamassassin#);
        if ($flag && ($prclines[$index] =~ /^X-Spam-Status:\s+Yes/i)) {
          $prclines[$index+1] = $g_filters{'spamfolder'};
          last;
        }
      }
      $lff = $laf = $flag = 0;
      for ($index=$#prclines; $index>=0; $index--) {
        $flag = 1 if ($prclines[$index] =~ m#^\|/usr/local/bin/spamassassin#);
        if ($flag && ($lff == 0) && ($prclines[$index] =~ /^LOGFILE=/)) {
          $prclines[$index] = "LOGFILE=$g_filters{'logfile'}";
          $lff = 1;
        }
        if ($flag && ($laf == 0) && ($prclines[$index] =~ /^LOGABSTRACT=/)) {
          $prclines[$index] = "LOGABSTRACT=$g_filters{'logabstract'}";
          $laf = 1;
        }
        last if ($lff && $laf);
      }
      open(TFP, ">$homedir/.procmailrc.$$");
      for ($index=0; $index<=$#prclines; $index++) {
        print TFP "$prclines[$index]\n";
      }
      close(TFP);
      rename("$homedir/.procmailrc.$$", "$homedir/.procmailrc");
      # copy .procmailrc to last.procmailrc (only require the proceed
      # and ignore conflicts warning one time... after that, it will be
      # presumed that the user has an ample supply of rope)
      open(SFP, "$homedir/.procmailrc");
      open(LFP, ">$idir/last.procmailrc");
      print LFP $_ while (<SFP>);
      close(LFP);
      close(SFP);
    }
    else {
      $f_enabled = mailmanagerSpamAssassinGetStatus();
      $ar_enabled = mailmanagerNemetonAutoreplyGetStatus();
      if ($ar_enabled) {
        require "$g_includelib/mm_autoresponder.pl"; 
        $ar_mode = mailmanagerAutoresponderGetMode();
        $ar_mode = "autoreply" if ($ar_mode eq "n/a");
        $path = ($ar_mode eq "vacation") ? "$g_skeldir/dot.forward_vacation" :
                                           "$g_skeldir/dot.forward_autoreply";
      }
      open(TFP, ">$homedir/.procmailrc");
      open(LFP, ">$idir/last.procmailrc");
      $sa_version = mailmanagerSpamAssassinGetVersion();
      if (mailmanagerSpamAssassinDaemonEnabled()) {
        open(SFP, "$g_skeldir/dot.procmailrc_spamc");
      }
      else {
        open(SFP, "$g_skeldir/dot.procmailrc");
      }
      while (<SFP>) {
        $curline = $_; 
        $curline =~ s/__USER__/$g_auth{'login'}/;
        $curline =~ s/__LOGFILE__/$g_filters{'logfile'}/;
        $curline =~ s/__LOGABSTRACT__/$g_filters{'logabstract'}/;
        $curline =~ s/__SPAMFOLDER__/$g_filters{'spamfolder'}/;
        if (/__AUTORESPONDER__/) {
          if ($ar_enabled) {
            open(DFP, "$path");
            $ar_command = <DFP>;
            close(DFP);
            chomp($ar_command); 
            $ar_command =~ s/__HOME__/$homedir/g;
            $ar_command =~ s/\/+/\//g;
            $ar_command =~ s/\"//g;
            $ar_recipe = ":0 c\n\* \!^X-autoreply:\n$ar_command";
            $curline =~ s/__AUTORESPONDER__/$ar_recipe/;
          }
          else {
            $curline =~ s/__AUTORESPONDER__//;
          }
        }
        print TFP $curline if ($f_enabled);
        print LFP $curline;
      }
      close(SFP);
      close(LFP);
      close(TFP);
    }
    # link last.procmailrc with HOME/.procmailrc
    utime($g_curtime, $g_curtime, "$homedir/.procmailrc");
    utime($g_curtime, $g_curtime, "$idir/last.procmailrc");
  }
}

##############################################################################
# eof

1;

