#
# fm_browse.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/fm_browse.pl,v 2.12.2.6 2006/05/30 17:32:01 rus Exp $
#
# file manager browse functions
#

##############################################################################

sub filemanagerBrowseDirectoryMenu
{
  local($mesg, $fullpath, $virtualpath) = @_;
  local($displaypath, @subpaths, $index, $subpath, $encpath);
  local($curname, $curpath, $curfile, $curdir);
  local($fmode, $fuid, $fgid, $fsize, $ftype, $args);
  local($mtime, $mdate, $target, $targetfullpath, $title);
  local($copytext, $renametext, $deletetext, $pluraltext);
  local(%files, %directories, $emptydirectory, $homedir);
  local($totalentries, $hiddenentries, $numtagged, $numvisible);
  local($totalfiles, $totaldirectories, $totallinks, $javascript, $css);
  local(@lines, $have_writable_objects, $javascript, $size50);

  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  if ($g_users{$g_atuh{'login'}}->{'chroot'}) {
    $displaypath = "/\{$FILEMANAGER_HOMEDIR\}" . "/" . $virtualpath;
  }
  else {
    $displaypath = "/" . $virtualpath;
  }
  $displaypath =~ s/\/+/\//g;
  $displaypath =~ s/^\///;
  $displaypath =~ s/\/$//;

  if ($ENV{'SCRIPT_NAME'} !~ /wizards\/filemanager.cgi/) {
    $ENV{'SCRIPT_NAME'} =~ /wizards\/([a-z_]*).cgi$/;
    $ENV{'SCRIPT_NAME'} =~ s/$1/filemanager/;
  }

  $javascript = javascriptTagUntagAll();
  $javascript .= javascriptHighlightUnhighlightRow();

  $css = "<style type=\"text/css\">
.highlighted { background:#dddddd }
.unhighlighted { background:#ffffff }
</style>";

  htmlResponseHeader("Content-type: $g_default_content_type");
  $FILEMANAGER_TITLE =~ s/__FILE__/$displaypath/g;
  labelCustomHeader($FILEMANAGER_TITLE, "", $javascript, $css);

  if ($mesg) {
    @lines = split(/\n/, $mesg);
    foreach $mesg (@lines) {
      htmlNoBR();
      htmlTextColorBold(">>>&#160;$mesg&#160;<<<", "#cc0000");
      htmlNoBRClose();
      htmlBR();
    }
    htmlP();
  }

  # override hide hidden entry preference if applicable
  if ($g_form{'hde'}) {
    if ($g_form{'hde'} eq "yes") {
      # hde = hide dot entries
      $g_prefs{'ftp__hide_entries_that_begin_with_a_dot'} = "yes";
    }
    elsif ($g_form{'hde'} eq "no") {
      # hde = hide dot entries
      $g_prefs{'ftp__hide_entries_that_begin_with_a_dot'} = "no";
    }
  }

  # set permission display option
  unless ($g_form{'co'}) {
    $g_form{'co'} = $g_prefs{'ftp__chmod_options'};
  }

  # open directory... run through entries
  $emptydirectory = 1;
  $totalentries = $hiddenentries = 0;
  $totalfiles = $totaldirectories = $totallinks = 0;
  %files = %directories = ();
  if (opendir(DIRHANDLE, $fullpath)) {
    while ($curname = readdir(DIRHANDLE)) {
      next if ($curname eq ".");
      next if (($curname eq "..") && 
               (($fullpath eq $g_users{$g_auth{'login'}}->{'path'}) ||
                ($fullpath eq "$g_users{$g_auth{'login'}}->{'path'}/")));
      $totalentries++;
      if (($curname =~ /^\./) && ($curname ne "..")) {
        $hiddenentries++;
        if ($g_prefs{'ftp__hide_entries_that_begin_with_a_dot'} eq "yes") {
          next;
        }
      }
      $curpath = "$fullpath/$curname";
      if (-l "$curpath") {
        ($fmode,$fuid,$fgid,$fsize,$mtime) = (lstat($curpath))[2,4,5,7,9];
        $target = readlink($curpath);
        $files{$curname}->{'type'} = "link";
        $files{$curname}->{'mode'} = $fmode;
        $files{$curname}->{'uid'} = $fuid;
        $files{$curname}->{'gid'} = $fgid;
        $files{$curname}->{'size'} = $fsize;
        $files{$curname}->{'mtime'} = $mtime;
        $files{$curname}->{'target'} = $target;
        $files{$curname}->{'fullpath'} = $curpath;
        $totallinks++;
      }
      elsif (-d "$curpath") {
        ($fmode,$fuid,$fgid,$fsize,$mtime) = (stat($curpath))[2,4,5,7,9];
        $directories{$curname}->{'mode'} = $fmode;
        $directories{$curname}->{'uid'} = $fuid;
        $directories{$curname}->{'gid'} = $fgid;
        $directories{$curname}->{'size'} = $fsize;
        $directories{$curname}->{'mtime'} = $mtime;
        $directories{$curname}->{'fullpath'} = $curpath;
        $totaldirectories++;
      }
      else { 
        ($fmode,$fuid,$fgid,$fsize,$mtime) = (stat($curpath))[2,4,5,7,9];
        $files{$curname}->{'type'} = "file";
        $files{$curname}->{'mode'} = $fmode;
        $files{$curname}->{'uid'} = $fuid;
        $files{$curname}->{'gid'} = $fgid;
        $files{$curname}->{'size'} = $fsize;
        $files{$curname}->{'mtime'} = $mtime;
        $files{$curname}->{'fullpath'} = $curpath;
        $totalfiles++;
      }
      $emptydirectory = 0 if ($curname ne "..");
    }
    closedir(DIRHANDLE);
    $numtagged = $totalentries;
    if ($g_prefs{'ftp__hide_entries_that_begin_with_a_dot'} eq "yes") {
      $numtagged -= $hiddenentries;
    }
    $numvisible = $numtagged;
    $numtagged-- if (defined($directories{".."}));
  }
  else {
    $totalentries = $numtagged = -1;
  }

  # information on the current directory
  ($fmode,$fuid,$fgid,$fsize,$mtime) = (stat($fullpath))[2,4,5,7,9];
  $mdate = dateBuildTimeString("alpha", $mtime);
  $mdate = dateLocalizeTimeString($mdate);

  htmlTable("border", "0");
  # current folder 
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$FILEMANAGER_CURDIR:&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  @subpaths = split(/\//, $displaypath);
  $subpath = $title = "";
  for ($index=0; $index<$#subpaths; $index++) {
    if ($g_users{$g_auth{'login'}}->{'chroot'}) {
      $subpath .= "/$subpaths[$index]" if ($index > 0);
    }
    else {
      $subpath .= "/$subpaths[$index]";
    }
    $title .= "/$subpaths[$index]";
    $encpath = encodingStringToURL($subpath);
    htmlText("&#160;/&#160;");
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?path=$encpath", 
               "title", "$FILEMANAGER_JUMP_TEXT $title");
    htmlAnchorText($subpaths[$index]);
    htmlAnchorClose();
  }
  htmlText("&#160;/&#160;$subpaths[$#subpaths]");
  htmlTableDataClose();
  htmlTableRowClose();
  # number of entries
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$FILEMANAGER_TOTAL_ENTRIES:&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  if ($totalentries < 0) {
    htmlText("???");
  }
  else {
    htmlText("$totalentries");
  }
  if ($totalentries > 0) {
    htmlTextSmall("&#160;&#160;&#160;(");
    $pluraltext = ($totaldirectories == 1) ? 
          $FILEMANAGER_ENTRY_DIRECTORY : $FILEMANAGER_ENTRY_DIRECTORY_PLURAL;
    htmlTextSmall("$totaldirectories $pluraltext; ");
    $pluraltext = ($totaldirectories == 1) ? 
          $FILEMANAGER_ENTRY_FILE : $FILEMANAGER_ENTRY_FILE_PLURAL;
    htmlTextSmall("$totalfiles $pluraltext; ");
    $pluraltext = ($totaldirectories == 1) ? 
          $FILEMANAGER_ENTRY_SYMLINK : $FILEMANAGER_ENTRY_SYMLINK_PLURAL;
    htmlTextSmall("$totallinks $pluraltext");
    if ($hiddenentries > 0) {
      htmlTextSmall("; ");
      $encpath = encodingStringToURL($virtualpath);
      if ($g_prefs{'ftp__hide_entries_that_begin_with_a_dot'} eq "no") {
        $args = htmlAnchorArgs("path", $encpath, "co", $g_form{'co'}, "hde", "yes");
        htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$args",
                   "title", $FILEMANAGER_HIDE_FILES);
        $FILEMANAGER_ENTRY_CAN_BE_HIDDEN =~ s/__FILES__/$hiddenentries/;
        htmlAnchorTextSmall($FILEMANAGER_ENTRY_CAN_BE_HIDDEN);
      }
      else {
        $args = htmlAnchorArgs("path", $encpath, "co", $g_form{'co'}, "hde", "no");
        htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$args",
                   "title", $FILEMANAGER_SHOW_HIDDEN_FILES);
        $FILEMANAGER_ENTRY_HIDDEN =~ s/__FILES__/$hiddenentries/;
        htmlAnchorTextSmall($FILEMANAGER_ENTRY_HIDDEN);
      }
      htmlAnchorClose();
    }
    htmlTextSmall(")");
  }
  htmlTableDataClose();
  htmlTableRowClose();
  # various properties
  if (($g_platform_type eq "dedicated") || 
      (($g_platform_type eq "virtual") && 
       (($g_auth{'login'} eq "root") || ($g_auth{'login'} =~ /^_.*root$/) ||
        ($g_auth{'login'} eq $g_users{'__rootid'})))) {
    htmlTableRow();
    htmlTableData("valign", "middle");
    $FILEMANAGER_OWNERSHIP =~ s/__TYPE__/$FILEMANAGER_TYPE_DIRECTORY/g;
    htmlTextBold("$FILEMANAGER_OWNERSHIP:&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    ($user) = (getpwuid($fuid))[0];
    ($group) = (getgrgid($fgid))[0];
    htmlText("$user / $group");
    htmlTableDataClose();
    htmlTableRow();
  }
  htmlTableRow();
  htmlTableData("valign", "middle");
  $FILEMANAGER_PERMS =~ s/__TYPE__/$FILEMANAGER_TYPE_DIRECTORY/g;
  htmlTextBold("$FILEMANAGER_PERMS:&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  if ($g_form{'co'} eq "advanced") {
    ($ptxt_rwx, $ptxt_oct) = filemanagerGetPermissionsText($fmode);
    htmlTextCode("d$ptxt_rwx ($ptxt_oct)");
  } 
  else {
    if (($fmode >> 6) & 04) {
      $permissions .= $FILEMANAGER_PERMS_READABLE;
    }
    if (($fmode >> 6) & 02) {
      $permissions .= ", " if ($permissions);
      $permissions .= $FILEMANAGER_PERMS_WRITABLE;
    }
    if (($fmode >> 6) & 01) {
      $permissions .= ", " if ($permissions);
      $permissions .= $FILEMANAGER_PERMS_EXECUTABLE;
    }
    $permissions = $NONE_STRING unless ($permissions);
    htmlText($permissions);
  }
  $encpath = encodingStringToURL($virtualpath);
  htmlText("&#160; &#160;");
  htmlTextSmall("(");
  if ($g_form{'co'} eq "basic") {
    $args = htmlAnchorArgs("path", $encpath, "co", "advanced", 
                           "hde", $g_form{'hde'});
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$args", 
               "title", $FILEMANAGER_MODE_SHOW_OCTAL);
    htmlAnchorTextSmall($FILEMANAGER_MODE_SHOW_OCTAL);
  }
  else {
    $args = htmlAnchorArgs("path", $encpath, "co", "basic", 
                           "hde", $g_form{'hde'});
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?$args", 
               "title", $FILEMANAGER_MODE_SHOW_BASIC);
    htmlAnchorTextSmall($FILEMANAGER_MODE_SHOW_BASIC);
  }
  htmlAnchorClose();
  htmlTextSmall(")");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$FILEMANAGER_MTIME:&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  htmlText($mdate);
  htmlTableDataClose();
  htmlTableRowClose();
  # actions
  htmlTableRow();
  htmlTableData("valign", "top");
  htmlTextBold("$FILEMANAGER_ACTIONS:&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "top"); 
  if ((-w "$fullpath") || (-W "$fullpath")) {
    htmlAnchor("href", "fm_createdir.cgi?path=$encpath",
               "title", $FILEMANAGER_ACTIONS_CREATEDIR);
    htmlAnchorText($FILEMANAGER_ACTIONS_CREATEDIR);
    htmlAnchorClose();
    htmlBR();
    htmlAnchor("href", "fm_createfile.cgi?path=$encpath",
               "title", $FILEMANAGER_ACTIONS_NEWFILE);
    htmlAnchorText($FILEMANAGER_ACTIONS_NEWFILE);
    htmlAnchorClose();
    htmlBR();
    htmlAnchor("href", "fm_upload.cgi?path=$encpath", 
               "title", $FILEMANAGER_ACTIONS_UPLOADFILE);
    htmlAnchorText($FILEMANAGER_ACTIONS_UPLOADFILE);
    htmlAnchorClose();
    htmlBR();
  }
  if (filemanagerIsReadable($fullpath)) {
    $copytext = $FILEMANAGER_ACTIONS_COPY;
    $copytext =~ s/__TYPE__/$FILEMANAGER_TYPE_DIRECTORY/g;
    htmlAnchor("href", "fm_copy.cgi?path=$encpath", "title", $copytext);
    htmlAnchorText($copytext);
    htmlAnchorClose();
    htmlBR();
  }
  if ($virtualpath && ($virtualpath ne "/") && 
      (filemanagerIsWritable($fullpath))) {
    $renametext = $FILEMANAGER_ACTIONS_RENAME;
    $renametext =~ s/__TYPE__/$FILEMANAGER_TYPE_DIRECTORY/g;
    htmlAnchor("href", "fm_rename.cgi?path=$encpath", "title", $renametext);
    htmlAnchorText($renametext);
    htmlAnchorClose();
    htmlBR();
    # can only purge directory contents if owned by user
    if ((($g_platform_type eq "virtual") && ($fuid == $g_uid)) ||
        (($g_platform_type eq "dedicated") &&
         ($fuid == $g_users{$g_auth{'login'}}->{'uid'}))) {
      if ($emptydirectory) {
        $deletetext = $FILEMANAGER_ACTIONS_REMOVE;
        $deletetext =~ s/__TYPE__/$FILEMANAGER_TYPE_DIRECTORY/g;
        htmlAnchor("href", "fm_remove.cgi?path=$encpath", "title", $deletetext);
        htmlAnchorText($deletetext);
        htmlAnchorClose();
      }
      else {
        # kepd - keep empty parent directory; in this case, yes
        htmlAnchor("href", "fm_remove.cgi?path=$encpath&kepd=yes",
                   "title", $FILEMANAGER_ACTIONS_REMOVE_DIRCONTENTS);
        htmlAnchorText($FILEMANAGER_ACTIONS_REMOVE_DIRCONTENTS);
        htmlAnchorClose();
      }
      htmlBR();
    }
  }
  if ((($g_platform_type eq "virtual") && ($fuid == $g_uid)) ||
      (($g_platform_type eq "dedicated") &&
       (($fuid == $g_users{$g_auth{'login'}}->{'uid'}) ||
        ($g_users{$g_auth{'login'}}->{'uid'} == 0) ||
        (($g_prefs{'security__elevate_admin_ftp_privs'} eq "yes") && 
         (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}})))))) {
    # file is owned by user or user is root
    htmlAnchor("href", "fm_chmod.cgi?path=$encpath",
               "title", $FILEMANAGER_ACTIONS_CHMOD);
    htmlAnchorText($FILEMANAGER_ACTIONS_CHMOD);
    htmlAnchorClose();
    htmlBR();
  }
  if (($g_platform_type eq "dedicated") &&
      ((($fuid == $g_users{$g_auth{'login'}}->{'uid'}) &&
        (groupGetUsersGroupMembership($g_auth{'login'}) > 1)) ||
       ($g_users{$g_auth{'login'}}->{'uid'} == 0) || 
       (($g_prefs{'security__elevate_admin_ftp_privs'} eq "yes") && 
        (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}}))))) {
    # show chown link
    htmlAnchor("href", "fm_chown.cgi?path=$encpath",
               "title", $FILEMANAGER_ACTIONS_CHOWN);
    htmlAnchorText($FILEMANAGER_ACTIONS_CHOWN);
    htmlAnchorClose();
    htmlBR();
  }
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();

  if ($numvisible >= 1) {
    if ($numtagged >= 2) {
      formOpen("method", "POST");
    }
    # separator
    htmlTable("cellpadding", "0", "cellspacing", "0",
              "border", "0", "width", "100\%");
    htmlTableRow();
    htmlTableData("align", "left");
    htmlTextBold("&#160;$FILEMANAGER_DIRECTORY_CONTENTS");
    htmlTableDataClose();
    htmlTableData("align", "right");
    $timestring = dateBuildTimeString("alpha");
    $timestring = dateLocalizeTimeString($timestring);
    $FILEMANAGER_DIRECTORY_CONTENTS_STATUS =~ s/__TIME__/$timestring/;
    htmlNoBR(); 
    htmlText("&#160;&#160;&#160;&#160;&#160;");
    htmlTextSmall("$FILEMANAGER_DIRECTORY_CONTENTS_STATUS&#160;");
    htmlNoBRClose(); 
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData("bgcolor", "#999999", "colspan", "2");
    htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
  
    $displaypath = $virtualpath;
    $displaypath = "" if ($displaypath eq "/");
  
    $copytext = $FILEMANAGER_ACTIONS_COPY;
    $renametext = $FILEMANAGER_ACTIONS_RENAME;
    $deletetext = $FILEMANAGER_ACTIONS_REMOVE;
    $copytext =~ s/__TYPE__//g;
    $renametext =~ s/__TYPE__//g;
    $deletetext =~ s/__TYPE__//g;
    $copytext =~ s/\s$//g;
    $renametext =~ s/\s$//g;
    $deletetext =~ s/\s$//g;
  
    htmlTable("border", "0", "cellspacing", "0", "cellpadding", "0");
    htmlTableRow();
    if ($numtagged >= 2) {
      htmlTableData("align", "center", "valign", "bottom");
      htmlNoBR();
      htmlTextBold("&#160;$FILEMANAGER_TAG&#160;");
      htmlNoBRClose();
      htmlTableDataClose();
    }
    htmlTableData("align", "center");
    print "&#160;";
    htmlTableDataClose();
    htmlTableData("align", "left", "valign", "bottom");
    htmlNoBR();
    htmlText("&#160;&#160;");
    htmlTextBold($FILEMANAGER_NAME);
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "left", "valign", "bottom");
    htmlNoBR();
    htmlTextBold("&#160;&#160;&#160;&#160;$FILEMANAGER_MTIME");
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "right", "valign", "bottom");
    htmlNoBR();
    htmlTextBold($FILEMANAGER_FILESIZE);
    htmlNoBRClose();
    htmlTableDataClose();
    htmlTableData("align", "left", "valign", "bottom");
    if ($numtagged >= 1) {
      htmlNoBR();
      htmlTextBold("&#160;&#160;&#160;$FILEMANAGER_ACTIONS");
      htmlNoBRClose();
    }
    else {
      print "&#160;";
    }
    htmlTableDataClose();
    htmlTableRowClose();

    $have_writable_objects = 0;
    foreach $curdir (sort(keys(%directories))) {
      $fmode = $directories{$curdir}->{'mode'};
      $fsize = $directories{$curdir}->{'size'};
      $mtime = $directories{$curdir}->{'mtime'};
      $curpath = $directories{$curdir}->{'fullpath'};
      htmlTableRow();
      if ($curdir eq "..") {
        $subpath = $displaypath;
        $subpath =~ s/[^\/]+$//g;
        $subpath =~ s/\/+$//g;
        $subpath = "/" unless ($subpath);
        $encpath = encodingStringToURL($subpath);
      } 
      else {
        $subpath = "$displaypath/$curdir";
        $encpath = encodingStringToURL($subpath);
      }
      if ($numtagged >= 2) {
        if ($curdir ne "..") {
          if ($g_form{'selected'} && ($g_form{'selected'} =~ /\Q$subpath\E/)) {
            htmlTableRow("class", "highlighted");
          }
          else {
            htmlTableRow("class", "unhighlighted");
          }
        }
        else {
          htmlTableRow("class", "unhighlighted");
        }
        htmlTableData("valign", "middle", "align", "center");
        if ($curdir ne "..") {
          formInput("type", "checkbox", "name", "selected",
                    "value", $subpath, "onClick", "toggle_row(this)", "_OTHER_", 
                    ($g_form{'selected'} && ($g_form{'selected'} =~ /\Q$subpath\E/)) ? "CHECKED" : "");
        }
        htmlTableDataClose();
      }
      htmlTableData("width", "24", "valign", "middle", "align", "right");
      $title = $FILEMANAGER_ACTIONS_OPEN;
      $title =~ s/__TYPE__/$FILEMANAGER_TYPE_DIRECTORY/;
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?path=$encpath",
                 "title", "$title: $curdir");
      htmlImg("border", "0", "width", "24", "height", "24",
              "src", "$g_graphicslib/folder.png", "alt", "$title: $curdir");
      htmlAnchorClose();
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlNoBR();
      htmlText("&#160;&#160;");
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?path=$encpath",
                 "title", "$title: $curdir");
      htmlAnchorText($curdir);
      htmlAnchorClose();
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      $mdate = dateBuildTimeString("alpha", $mtime);
      $mdate = dateLocalizeTimeString($mdate);
      $mdate =~ s/\ /\&\#160\;/g;
      htmlText("&#160;&#160;&#160;&#160;$mdate");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "right");
      htmlText("&#160;&#160;&#160;&#160;$fsize&#160;$BYTES");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlNoBR();
      htmlText("&#160;&#160;&#160;");
      if ($curdir ne "..") {
        htmlText("[&#160;");
        $title = $FILEMANAGER_ACTIONS_COPY;
        $title =~ s/__TYPE__/$FILEMANAGER_TYPE_DIRECTORY/;
        if (filemanagerIsReadable($curpath)) {
          htmlAnchor("href", "fm_copy.cgi?path=$encpath",
                     "title", "$title: $curdir");
          htmlAnchorText($copytext);
          htmlAnchorClose();
        }
        else {
          htmlTextColor($copytext, "#999999");
        }
        htmlText("&#160;|&#160;");
        $title = $FILEMANAGER_ACTIONS_RENAME;
        $title =~ s/__TYPE__/$FILEMANAGER_TYPE_DIRECTORY/;
        if (filemanagerIsWritable($curpath)) {
          htmlAnchor("href", "fm_rename.cgi?path=$encpath", 
                     "title", "$title: $curdir");
          htmlAnchorText($renametext);
          htmlAnchorClose();
          $have_writable_objects = 1;
        }
        else {
          htmlTextColor($renametext, "#999999");
        }
        htmlText("&#160;|&#160;");
        $title = $FILEMANAGER_ACTIONS_REMOVE;
        $title =~ s/__TYPE__/$FILEMANAGER_TYPE_DIRECTORY/;
        # kepd - keep empty parent directory; in this case, no
        if (filemanagerIsWritable($curpath)) {
          htmlAnchor("href", "fm_remove.cgi?path=$encpath&kepd=no",
                     "title", "$title: $curdir");
          htmlAnchorText($deletetext);
          htmlAnchorClose();
          $have_writable_objects = 1;
        }
        else {
          htmlTextColor($deletetext, "#999999");
        }
        htmlText("&#160;]");
      }
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableRowClose();
    }
    foreach $curfile (sort(keys(%files))) {
      $ftype = $files{$curfile}->{'type'};
      $fmode = $files{$curfile}->{'mode'};
      $fsize = $files{$curfile}->{'size'};
      $mtime = $files{$curfile}->{'mtime'};
      $target = $files{$curfile}->{'target'};
      $curpath = $files{$curfile}->{'fullpath'};
      $subpath = "$displaypath/$curfile";
      $encpath = encodingStringToURL($subpath);
      htmlTableRow();
      if ($g_form{'selected'} && ($g_form{'selected'} =~ /\Q$subpath\E/)) {
        htmlTableRow("class", "highlighted");
      }
      else {
        htmlTableRow("class", "unhighlighted");
      }
      if ($numtagged >= 2) {
        htmlTableData("valign", "middle", "align", "center");
        formInput("type", "checkbox", "name", "selected",
                  "value", $subpath, "onClick", "toggle_row(this)", "_OTHER_", 
                  ($g_form{'selected'} && ($g_form{'selected'} =~ /\Q$subpath\E/)) ? "CHECKED" : "");
        htmlTableDataClose();
      }
      htmlTableData("width", "24", "valign", "middle", "align", "right");
      $title = $FILEMANAGER_ACTIONS_OPEN;
      if ($ftype eq "link") {
        $title =~ s/__TYPE__/$FILEMANAGER_TYPE_SYMLINK/;
      }
      else {
        $title =~ s/__TYPE__/$FILEMANAGER_TYPE_FILE/;
      }
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?path=$encpath",
                 "title", "$title: $curfile");
      htmlImg("border", "0", "width", "24", "height", "24",
              "src", "$g_graphicslib/$ftype.png", "alt", "$title: $curfile");
      htmlAnchorClose();
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlNoBR();
      htmlText("&#160;&#160;");
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?path=$encpath",
                 "title", "$title: $curfile");
      htmlAnchorText($curfile);
      htmlAnchorClose();
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      $mdate = dateBuildTimeString("alpha", $mtime);
      $mdate = dateLocalizeTimeString($mdate);
      $mdate =~ s/\ /\&\#160\;/g;
      htmlNoBR();
      htmlText("&#160; &#160; $mdate");
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "right");
      htmlText("&#160;&#160;&#160;&#160;$fsize&#160;$BYTES");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlNoBR();
      htmlText("&#160; &#160;");
      if ($ftype eq "link") {
        htmlText("$FILEMANAGER_TYPE_SYMLINK --> ");
        $targetfullpath = filemanagerBuildFullPath($target, $fullpath);
        if ($targetfullpath !~ /^$g_users{$g_auth{'login'}}->{'path'}/) {
          htmlText($target);
        }
        else {
          $encpath = $targetfullpath;
          if ($g_users{$g_auth{'login'}}->{'path'} ne "/") {
            $encpath =~ s/^$g_users{$g_auth{'login'}}->{'path'}//;
          }
          $encpath = encodingStringToURL($encpath);
          htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?path=$encpath");
          htmlAnchorText($target);
          htmlAnchorClose();
        }
      }
      else {
        htmlText("[&#160;");
        $title = $FILEMANAGER_ACTIONS_COPY;
        $title =~ s/__TYPE__/$FILEMANAGER_TYPE_FILE/;
        if (filemanagerIsReadable($curpath)) {
          htmlAnchor("href", "fm_copy.cgi?path=$encpath",
                     "title", "$title: $curfile");
          htmlAnchorText($copytext);
          htmlAnchorClose();
        }
        else {
          htmlTextColor($copytext, "#999999");
        }
        htmlText("&#160;|&#160;");
        $title = $FILEMANAGER_ACTIONS_RENAME;
        $title =~ s/__TYPE__/$FILEMANAGER_TYPE_FILE/;
        if (filemanagerIsWritable($curpath)) {
          htmlAnchor("href", "fm_rename.cgi?path=$encpath", 
                     "title", "$title: $curfile");
          htmlAnchorText($renametext);
          htmlAnchorClose();
          $have_writable_objects = 1;
        }
        else {
          htmlTextColor($renametext, "#999999");
        }
        htmlText("&#160;|&#160;");
        $title = $FILEMANAGER_ACTIONS_REMOVE;
        $title =~ s/__TYPE__/$FILEMANAGER_TYPE_FILE/;
        if (filemanagerIsWritable($curpath)) {
          htmlAnchor("href", "fm_remove.cgi?path=$encpath",
                     "title", "$title: $curfile");
          htmlAnchorText($deletetext);
          htmlAnchorClose();
          $have_writable_objects = 1;
        }
        else {
          htmlTextColor($deletetext, "#999999");
        }
        htmlText("&#160;]");
      }
      htmlNoBRClose();
      htmlTableDataClose();
      htmlTableRowClose();
    }
    htmlTableClose();
    htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    if ($numtagged >= 2) {
      # separator
      htmlTable("cellpadding", "0", "cellspacing", "0",
                "border", "0", "bgcolor", "#999999", "width", "100\%");
      htmlTableRow();
      htmlTableData();
      htmlImg("width", "1", "height", "1", "src", "$g_graphicslib/sp.gif");
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
      htmlImg("width", "1", "height", "5", "src", "$g_graphicslib/sp.gif");
      htmlBR();
      # tagged action buttons
      formInput("type", "submit", "name", "submit",
                "value", $FILEMANAGER_COPY_TAGGED);
      if ($have_writable_objects) {
        formInput("type", "submit", "name", "submit",
                  "value", $FILEMANAGER_MOVE_TAGGED);
        formInput("type", "submit", "name", "submit",
                  "value", $FILEMANAGER_DELETE_TAGGED);
      }
      print <<ENDTEXT;
&#160;
<script language="JavaScript1.1">
  document.write("<input type=\\\"button\\\" ");
  document.write("style=\\\"font-family:arial, helvetica; font-size:13px\\\" ");
  document.write("value=\\\"$TAG_ALL\\\" onClick=\\\"");
  document.write("this.value=tag_untag_all(this.form.selected)\\\">");
</script>
ENDTEXT
      formClose();
    }
  }
  
  if ((keys(%directories) == 0) &&
      (($fullpath eq $g_users{$g_auth{'login'}}->{'path'}) ||
       ($fullpath eq "$g_users{$g_auth{'login'}}->{'path'}/"))) {
    # don't print the jump form
  }
  else {
    # jump to another folder/file form
    formOpen("name", "jumpForm", "method", "POST");
    authPrintHiddenFields();
    formInput("type", "hidden", "name", "cwd", "value", $virtualpath);
    htmlTable();
    htmlTableRow();
    htmlTableData("valign", "middle");
    htmlText("$FILEMANAGER_JUMP_TEXT:");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    $size50 = formInputSize(50);
    formInput("name", "path", "size", $size50, 
        "onFocus", 
        "if(this.value=='$FILEMANAGER_JUMP_HELP_TEXT')this.value='';",
        "onBlur", 
        "if(this.value=='')this.value='$FILEMANAGER_JUMP_HELP_TEXT';",
        "value", "$FILEMANAGER_JUMP_HELP_TEXT");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
    formClose();
    htmlP();
  }
  
  labelCustomFooter();

  exit(0);
}

##############################################################################

sub filemanagerBrowseFileMenu
{
  local($mesg, $fullpath, $virtualpath) = @_;
  local($displaypath, @subpaths, $index, $subpath, $encpath);
  local($filetype, $mimetype, $fmode, $fsize, $mtime, $mdate);
  local($target, $targetfullpath, $permissions, $ptxt_rwx, $ptxt_oct);
  local($fuid, $fgid, $user, $group, @lines);

  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  if ($g_users{$g_auth{'login'}}->{'chroot'}) {
    $displaypath = "/\{$FILEMANAGER_HOMEDIR\}" . "/" . $virtualpath;
  }
  else {
    $displaypath = "/" . $virtualpath;
  }
  $displaypath =~ s/\/+/\//g;
  $displaypath =~ s/^\///;
  $displaypath =~ s/\/$//;

  if ($ENV{'SCRIPT_NAME'} !~ /wizards\/filemanager.cgi/) {
    $ENV{'SCRIPT_NAME'} =~ /wizards\/([a-z_]*).cgi$/;
    $ENV{'SCRIPT_NAME'} =~ s/$1/filemanager/;
  }

  # set permission display option
  unless ($g_form{'co'}) {
    $g_form{'co'} = $g_prefs{'ftp__chmod_options'};
  }

  htmlResponseHeader("Content-type: $g_default_content_type");
  $FILEMANAGER_TITLE =~ s/__FILE__/$displaypath/g;
  labelCustomHeader($FILEMANAGER_TITLE);

  if ($mesg) {
    @lines = split(/\n/, $mesg);
    foreach $mesg (@lines) {
      htmlNoBR();
      htmlTextColorBold(">>>&#160;$mesg&#160;<<<", "#cc0000");
      htmlNoBRClose();
      htmlBR();
    }
    htmlP();
  }

  htmlTable("border", "0");

  # current file 
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$FILEMANAGER_CURFILE:");
  htmlTableDataClose();  
  htmlTableData("valign", "middle");
  @subpaths = split(/\//, $displaypath);
  $subpath = $title = "";
  for ($index=0; $index<$#subpaths; $index++) {
    if ($g_users{$g_auth{'login'}}->{'chroot'}) {
      $subpath .= "/$subpaths[$index]" if ($index > 0);
    }
    else {
      $subpath .= "/$subpaths[$index]";
    }
    $title .= "/$subpaths[$index]";
    $encpath = encodingStringToURL($subpath);
    htmlText("&#160;/&#160;");
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?path=$encpath",
               "title", "$FILEMANAGER_JUMP_TEXT $title");
    htmlAnchorText($subpaths[$index]);
    htmlAnchorClose();
  }
  htmlText("&#160;/&#160;$subpaths[$#subpaths]");
  htmlTableDataClose();  
  htmlTableRowClose();

  $displaypath = $virtualpath;

  # file type
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$FILEMANAGER_TYPE:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  $filetype = (-l "$fullpath") ? $FILEMANAGER_TYPE_SYMLINK :
              (filemanagerIsText($fullpath)) ? $FILEMANAGER_TYPE_ASCII : 
                                               $FILEMANAGER_TYPE_BINARY;
  htmlText($filetype);
  htmlTableDataClose();
  htmlTableRowClose();
  unless (-l "$fullpath") {
    # MIME type
    htmlTableRow();
    htmlTableData("valign", "middle");
    htmlTextBold("$FILEMANAGER_MIMETYPE:");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    $mimetype = filemanagerGetMimeType($fullpath);
    htmlText($mimetype);
    htmlTableDataClose();
    htmlTableRowClose();
  }
  # file size and modification time
  if (-l "$fullpath") {
    ($fmode,$fuid,$fgid,$fsize,$mtime) = (lstat($fullpath))[2,4,5,7,9];
  }
  else {
    ($fmode,$fuid,$fgid,$fsize,$mtime) = (stat($fullpath))[2,4,5,7,9];
  }
  $mdate = dateBuildTimeString("alpha", $mtime);
  $mdate = dateLocalizeTimeString($mdate);
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$FILEMANAGER_FILESIZE:");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  htmlText("$fsize&#160;$BYTES");
  htmlTableDataClose();
  htmlTableRowClose();

  if (($g_platform_type eq "dedicated") || 
      (($g_platform_type eq "virtual") && 
       (($g_auth{'login'} eq "root") || ($g_auth{'login'} =~ /^_.*root$/) ||
        ($g_auth{'login'} eq $g_users{'__rootid'})))) {
    htmlTableRow();
    htmlTableData("valign", "middle");
    if (-l "$fullpath") {
      $FILEMANAGER_OWNERSHIP =~ s/__TYPE__/$FILEMANAGER_TYPE_SYMLINK/g;
    }
    else {
      $FILEMANAGER_OWNERSHIP =~ s/__TYPE__/$FILEMANAGER_TYPE_FILE/g;
    }
    htmlTextBold("$FILEMANAGER_OWNERSHIP:&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    ($user) = (getpwuid($fuid))[0];
    ($group) = (getgrgid($fgid))[0];
    htmlText("$user / $group");
    htmlTableDataClose();
    htmlTableRow();
  }
  htmlTableRow();
  htmlTableData("valign", "middle");
  if (-l "$fullpath") {
    $FILEMANAGER_PERMS =~ s/__TYPE__/$FILEMANAGER_TYPE_SYMLINK/g;
  }
  else {
    $FILEMANAGER_PERMS =~ s/__TYPE__/$FILEMANAGER_TYPE_FILE/g;
  }
  htmlTextBold("$FILEMANAGER_PERMS:&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  if ($g_form{'co'} eq "advanced") {
    ($ptxt_rwx, $ptxt_oct) = filemanagerGetPermissionsText($fmode);
    if (-l "$fullpath") {
      htmlTextCode("l$ptxt_rwx ($ptxt_oct)");
    }
    elsif (-b "$fullpath") {
      htmlTextCode("b$ptxt_rwx ($ptxt_oct)");
    }
    elsif (-c "$fullpath") {
      htmlTextCode("c$ptxt_rwx ($ptxt_oct)");
    }
    else {
      htmlTextCode("-$ptxt_rwx ($ptxt_oct)");
    }
  } 
  else {
    if (($fmode >> 6) & 04) {
      $permissions .= $FILEMANAGER_PERMS_READABLE;
    }
    if (($fmode >> 6) & 02) {
      $permissions .= ", " if ($permissions);
      $permissions .= $FILEMANAGER_PERMS_WRITABLE;
    }
    if (($fmode >> 6) & 01) {
      $permissions .= ", " if ($permissions);
      $permissions .= $FILEMANAGER_PERMS_EXECUTABLE;
    }
    $permissions = $NONE_STRING unless ($permissions);
    htmlText($permissions);
  }
  $encpath = encodingStringToURL($displaypath);
  htmlText("&#160; &#160;");
  htmlTextSmall("(");
  if ($g_form{'co'} eq "basic") {
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?path=$encpath&co=advanced",
               "title", $FILEMANAGER_MODE_SHOW_OCTAL);
    htmlAnchorTextSmall($FILEMANAGER_MODE_SHOW_OCTAL);
  }
  else {
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?path=$encpath&co=basic",
               "title", $FILEMANAGER_MODE_SHOW_BASIC);
    htmlAnchorTextSmall($FILEMANAGER_MODE_SHOW_BASIC);
  }
  htmlAnchorClose();
  htmlTextSmall(")");
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle");
  htmlTextBold("$FILEMANAGER_MTIME:&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle");
  htmlText($mdate);
  htmlTableDataClose();
  htmlTableRowClose();
  
  if (-l "$fullpath") {
    # symlink target
    htmlTableRow();
    htmlTableData("valign", "middle");
    htmlTextBold("$FILEMANAGER_TYPE_SYMLINK $FILEMANAGER_TARGET:");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    $target = readlink($fullpath);
    $subpath = $fullpath;
    $subpath =~ s/[^\/]+$//g;
    $subpath =~ s/\/+$//g;
    $subpath = "/" unless ($subpath);
    $targetfullpath = filemanagerBuildFullPath($target, $subpath);
    if ($targetfullpath !~ /^$g_users{$g_auth{'login'}}->{'path'}/) {
      htmlText($target);
    }
    else {
      $encpath = $targetfullpath;
      if ($g_users{$g_auth{'login'}}->{'path'} ne "/") {
        $encpath =~ s/^$g_users{$g_auth{'login'}}->{'path'}//;
      }
      $encpath = encodingStringToURL($encpath);
      htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?path=$encpath",
                 "title", "$FILEMANAGER_JUMP_TEXT $target");
      htmlAnchorText($target);
      htmlAnchorClose();
    }
    htmlTableDataClose();
    htmlTableRowClose();
  }

  # actions
  $encpath = encodingStringToURL($displaypath);
  htmlTableRow();
  htmlTableData("valign", "top");
  htmlTextBold("$FILEMANAGER_ACTIONS:");
  htmlTableDataClose();
  htmlTableData("valign", "top");
  unless (-l "$fullpath") {
    if (($fsize > 0) && (filemanagerIsReadable($fullpath))) {
      # size > 0, readable by user
      # view file link
      htmlAnchor("href", "fm_view.cgi?path=$encpath",
                 "title", $FILEMANAGER_ACTIONS_VIEW);
      htmlAnchorText($FILEMANAGER_ACTIONS_VIEW);
      htmlAnchorClose();
      htmlBR();
      # download file link
      htmlAnchor("href", "fm_view.cgi?path=$encpath&download=1",
                 "title", $FILEMANAGER_ACTIONS_DOWNLOAD);
      htmlAnchorText($FILEMANAGER_ACTIONS_DOWNLOAD);
      htmlAnchorClose();
      htmlBR();
      if ($g_users{$g_auth{'login'}}->{'mail'}) {
        # e-mail file as an attachment link
        htmlAnchor("href", "mm_compose.cgi?filelocal1=$encpath",
                   "title", $FILEMANAGER_ACTIONS_EMAIL);
        htmlAnchorText($FILEMANAGER_ACTIONS_EMAIL);
        htmlAnchorClose();
        htmlBR();
      }
    }
    if ((filemanagerIsText($fullpath)) &&
        (filemanagerIsWritable($fullpath))) {
      # text file, writable
      htmlAnchor("href", "fm_edit.cgi?path=$encpath",
                 "title", $FILEMANAGER_ACTIONS_EDIT);
      htmlAnchorText($FILEMANAGER_ACTIONS_EDIT);
      htmlAnchorClose();
      htmlBR();
    }
  }
  if (filemanagerIsReadable($fullpath)) {
    if (-l "$fullpath") {
      $FILEMANAGER_ACTIONS_COPY =~ s/__TYPE__/$FILEMANAGER_TYPE_SYMLINK/g;
    }
    else {
      $FILEMANAGER_ACTIONS_COPY =~ s/__TYPE__/$FILEMANAGER_TYPE_FILE/g;
    }
    htmlAnchor("href", "fm_copy.cgi?path=$encpath",
               "title", $FILEMANAGER_ACTIONS_COPY);
    htmlAnchorText($FILEMANAGER_ACTIONS_COPY);
    htmlAnchorClose();
    htmlBR();
  }
  if (filemanagerIsWritable($fullpath)) {
    if (-l "$fullpath") {
      $FILEMANAGER_ACTIONS_RENAME =~ s/__TYPE__/$FILEMANAGER_TYPE_SYMLINK/g;
    }
    else {
      $FILEMANAGER_ACTIONS_RENAME =~ s/__TYPE__/$FILEMANAGER_TYPE_FILE/g;
    }
    htmlAnchor("href", "fm_rename.cgi?path=$encpath",
               "title", $FILEMANAGER_ACTIONS_RENAME);
    htmlAnchorText($FILEMANAGER_ACTIONS_RENAME);
    htmlAnchorClose();
    htmlBR();
    if (-l "$fullpath") {
      $FILEMANAGER_ACTIONS_REMOVE =~ s/__TYPE__/$FILEMANAGER_TYPE_SYMLINK/g;
    }
    else {
      $FILEMANAGER_ACTIONS_REMOVE =~ s/__TYPE__/$FILEMANAGER_TYPE_FILE/g;
    }
    htmlAnchor("href", "fm_remove.cgi?path=$encpath",
               "title", $FILEMANAGER_ACTIONS_REMOVE);
    htmlAnchorText($FILEMANAGER_ACTIONS_REMOVE);
    htmlAnchorClose();
    htmlBR();
  }
  if ((($g_platform_type eq "virtual") && ($fuid == $g_uid)) ||
      (($g_platform_type eq "dedicated") && 
       (($fuid == $g_users{$g_auth{'login'}}->{'uid'}) ||
        ($g_users{$g_auth{'login'}}->{'uid'} == 0) ||
        (($g_prefs{'security__elevate_admin_ftp_privs'} eq "yes") && 
         (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}})))))) {
    # file is owned by user or user is root
    htmlAnchor("href", "fm_chmod.cgi?path=$encpath",
               "title", $FILEMANAGER_ACTIONS_CHMOD);
    htmlAnchorText($FILEMANAGER_ACTIONS_CHMOD);
    htmlAnchorClose();
    htmlBR();
  }
  if (($g_platform_type eq "dedicated") &&
      ((($fuid == $g_users{$g_auth{'login'}}->{'uid'}) &&
        (groupGetUsersGroupMembership($g_auth{'login'}) > 1)) ||
       ($g_users{$g_auth{'login'}}->{'uid'} == 0) ||
       (($g_prefs{'security__elevate_admin_ftp_privs'} eq "yes") && 
        (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}}))))) {
    # show chown link
    htmlAnchor("href", "fm_chown.cgi?path=$encpath",
               "title", $FILEMANAGER_ACTIONS_CHOWN);
    htmlAnchorText($FILEMANAGER_ACTIONS_CHOWN);
    htmlAnchorClose();
    htmlBR();
  }
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub filemanagerBrowseSpecifiedPath
{
  local($mesg) = @_;
  local($fullpath, $virtualpath);

  encodingIncludeStringLibrary("filemanager");

  # easter egg
  if ($g_form{'path'} && 
      (($g_form{'path'} eq authDecode64("cnVuIG1pbmVzd2VlcGVy")) ||
       ($g_form{'path'} eq authDecode64("cGxheSBtaW5lc3dlZXBlcg")))) {
    require "$g_includelib/lang/ee/ms.pl";
    eastereggMineSweepRun();
    exit(0);
  }

  if ($g_form{'path'}) {
    # remove the '/insert/pathname/here' if the user failed to remove it
    $g_form{'path'} =~ s/$FILEMANAGER_JUMP_HELP_TEXT//g;
  }

  # set path to "" if user specified {HOME}
  if ($g_form{'path'} && ($g_form{'path'} eq "{$FILEMANAGER_HOMEDIR}")) {
    $g_form{'path'} = "";
  }

  # set the path for root users on a dedicated box to saved 'home' path
  if (!$g_form{'path'}) {
    if ($g_users{$g_auth{'login'}}->{'chroot'}) {
      $g_form{'path'} = "/";
    }
    else {
      $g_form{'path'} = $g_users{$g_auth{'login'}}->{'home'};
    }
  }

  ($fullpath, $virtualpath) = filemanagerGetFullPath($g_form{'path'});

  if (!$mesg && $g_form{'msgfileid'}) {
    # read message from temporary state message file
    $mesg = redirectMessageRead($g_form{'msgfileid'});
  }

  # does the file exist?
  unless ((-l "$fullpath") || (-e "$fullpath")) {
    filemanagerResourceNotFound("verifying existence of 
        \"$virtualpath\" in filemanagerBrowseFileMenu");
  }

  if (-l "$fullpath") {
    filemanagerBrowseFileMenu($mesg, $fullpath, $virtualpath);
  }
  elsif (-d "$fullpath") {
    filemanagerBrowseDirectoryMenu($mesg, $fullpath, $virtualpath);
  }
  else {
    filemanagerBrowseFileMenu($mesg, $fullpath, $virtualpath);
  }
}

##############################################################################

sub filemanagerHandleActionOnSelectedRequest
{
  encodingIncludeStringLibrary("filemanager");

  unless ($g_form{'selected'}) {
    # uh... damnit beavis
    filemanagerBrowseSpecifiedPath($FILEMANAGER_NONE_SELECTED);
  }

  if ($g_form{'submit'} eq $FILEMANAGER_COPY_TAGGED) {
    $ENV{'SCRIPT_NAME'} =~ s/filemanager.cgi/fm_copy.cgi/;
    require "$g_includelib/fm_copy.pl";
    filemanagerCopyFileForm();
  }
  elsif ($g_form{'submit'} eq $FILEMANAGER_MOVE_TAGGED) {
    $ENV{'SCRIPT_NAME'} =~ s/filemanager.cgi/fm_rename.cgi/;
    require "$g_includelib/fm_rename.pl";
    filemanagerRenameFileForm();
  }
  elsif ($g_form{'submit'} eq $FILEMANAGER_DELETE_TAGGED) {
    $ENV{'SCRIPT_NAME'} =~ s/filemanager.cgi/fm_remove.cgi/;
    require "$g_includelib/fm_remove.pl";
    if ((!$g_form{'confirm'}) &&
        ($g_prefs{'ftp__confirm_file_remove'} eq "yes")) {
      filemanagerRemoveFileConfirmForm();
    }
    filemanagerCheckRemoveFileTarget();
    filemanagerRemoveTarget();
  }
  else {
    # uh... what?
    filemanagerBrowseSpecifiedPath();
  }
}

##############################################################################
# eof

1;

