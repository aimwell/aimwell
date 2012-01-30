#
# fm_chown.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/fm_chown.pl,v 2.12.2.4 2006/04/25 19:48:23 rus Exp $
#
# file manager change owner (group) functions
#

##############################################################################

sub filemanagerChangeTargetOwnership
{
  local($fullpath, $virtualpath);

  # build full source path
  ($fullpath, $virtualpath) = filemanagerGetFullPath($g_form{'path'});

  unless ((-l "$fullpath") || (-e "$fullpath")) {
    filemanagerResourceNotFound("filemanagerChangeTargetPermissions
      verifying existence of \"$virtualpath\"");
  }

  encodingIncludeStringLibrary("filemanager");

  # change the mode
  filemanagerChown($g_form{'uid'}, $g_form{'gid'}, $fullpath) ||
    filemanagerResourceError($FILEMANAGER_ACTIONS_CHOWN,
        "call to chmod($g_form{'uid'}, $g_form{'gid'}, $fullpath) \
         in filemanagerChown");

  # success! show happy results
  $FILEMANAGER_ACTIONS_CHOWN_SUCCESS_TEXT =~ s/\n/\ /g;
  redirectLocation("filemanager.cgi",
                   $FILEMANAGER_ACTIONS_CHOWN_SUCCESS_TEXT);
}

##############################################################################

sub filemanagerCheckChownTarget
{
  local($fullpath, $virtualpath);

  # build full source path
  ($fullpath, $virtualpath) = filemanagerGetFullPath($g_form{'path'});

  unless ((-l "$fullpath") || (-e "$fullpath")) {
    filemanagerResourceNotFound("filemanagerCheckChownTarget
      verifying existence of \"$virtualpath\"");
  }

  encodingIncludeStringLibrary("filemanager");

  if ($g_form{'submit'} eq "$FILEMANAGER_ACTIONS_CHOWN_CANCEL") {
    redirectLocation("filemanager.cgi",
                     $FILEMANAGER_ACTIONS_CHOWN_CANCEL_TEXT);
  }
}

##############################################################################

sub filemanagerChownForm
{
  local($fullpath, $virtualpath, $displaypath);
  local($filetype, $encpath, $fuid, $fgid, $user, $group);
  local(@mgroups, $authorized, $sel);

  encodingIncludeStringLibrary("filemanager");

  ($fullpath, $virtualpath) = filemanagerGetFullPath($g_form{'path'});
  if ($g_users{$g_auth{'login'}}->{'chroot'}) {
    $displaypath = "{$FILEMANAGER_HOMEDIR}" . $virtualpath;
  }
  else {
    $displaypath = $virtualpath;
  }

  unless ((-l "$fullpath") || (-e "$fullpath")) {
    filemanagerResourceNotFound("filemanagerChownForm
      verifying existence of \"$virtualpath\"");
  }

  ($fuid, $fgid) = (stat($fullpath))[4,5];

  $filetype = filemanagerGetFileType($fullpath);
  $FILEMANAGER_ACTIONS_CHOWN_NAME =~ s/__TYPE__/$filetype/;
  $FILEMANAGER_OWNERSHIP =~  s/__TYPE__/$filetype/g;

  $encpath = encodingStringToURL($virtualpath);

  htmlResponseHeader("Content-type: $g_default_content_type");
  $FILEMANAGER_TITLE =~ s/__FILE__/$displaypath/g;
  labelCustomHeader("$FILEMANAGER_TITLE : $FILEMANAGER_ACTIONS_CHOWN");
  htmlP();
  htmlUL();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "path", "value", $virtualpath);
  htmlTable();
  htmlTableRow();
  htmlTableData("valign", "middle", "align", "left");
  htmlNoBR();
  htmlTextBold("$FILEMANAGER_ACTIONS_CHOWN_NAME:&#160;&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left");
  htmlText($virtualpath);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle", "align", "left");
  htmlNoBR();
  htmlTextBold("$FILEMANAGER_OWNERSHIP:&#160;&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left");
  htmlNoBR();
  ($user) = (getpwuid($fuid))[0];
  ($group) = (getgrgid($fgid))[0];
  htmlText("$user / $group");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle", "align", "left");
  htmlTextBold("$FILEMANAGER_ACTIONS_CHOWN_NEW:&#160;&#160;");
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left");
  $authorized = 1;
  if (($g_users{$g_auth{'login'}}->{'uid'} == 0) ||
      (($g_prefs{'security__elevate_admin_ftp_privs'} eq "yes") && 
       (defined($g_groups{'wheel'}->{'m'}->{$g_auth{'login'}})))) {
    # give root folks plenty of rope
    htmlTable("border", "0", "cellspacing", "0", "cellpadding", "0");
    htmlTableRow();
    htmlTableData("valign", "middle");
    $sel = -1;
    formSelect("name", "uid", "size", 1);
    foreach $user (sort(keys(%g_users))) {
      $sel = ($g_users{$user}->{'uid'} == $fuid) ? (($sel < 0) ? 1 : 0) : 
                                                   (($sel < 0) ? -1 : 0);
      formSelectOption($g_users{$user}->{'uid'}, $user, (($sel == 1) ? 1 : 0));
    }
    formSelectClose();
    htmlTableData("valign", "middle");
    htmlText("&#160; / &#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle");
    $sel = -1;
    formSelect("name", "gid", "size", 1);
    foreach $group (sort(keys(%g_groups))) {
      $sel = ($g_groups{$group}->{'gid'} == $fgid) ? (($sel < 0) ? 1 : 0) : 
                                                     (($sel < 0) ? -1 : 0);
      formSelectOption($g_groups{$group}->{'gid'}, $group, $sel);
    }
    formSelectClose();
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableClose();
  }
  else {
    @mgroups = groupGetUsersGroupMembership($g_auth{'login'});
    if (($fuid == $g_users{$g_auth{'login'}}->{'uid'}) && ($#mgroups > 0)) {
      htmlTable("border", "0", "cellspacing", "0", "cellpadding", "0");
      htmlTableRow();
      htmlTableData("valign", "middle");
      htmlText("$user / &#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle");
      formInput("type", "hidden", "name", "uid", "value", $fuid);
      $sel = -1;
      formSelect("name", "gid", "size", 1);
      foreach $group (sort(@mgroups)) {
        $sel = ($g_groups{$group}->{'gid'} == $fgid) ? (($sel < 0) ? 1 : 0) : 
                                                       (($sel < 0) ? -1 : 0);
        formSelectOption($g_groups{$group}->{'gid'}, $group, $sel);
      }
      formSelectClose();
      htmlTableDataClose();
      htmlTableRowClose();
      htmlTableClose();
    }
    else {
      # do nothing
      htmlTextColorBold(">>> $FILEMANAGER_ACTIONS_CHOWN_DENIED <<<", "#cc0000");
      $authorized = 0;
    }
  }
  htmlTableDataClose();
  htmlTableRowClose();
  if ($authorized) {
    htmlTableRow();
    htmlTableData("colspan", "2", "align", "left");
    htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
    htmlBR();
    formInput("type", "submit", "name", "submit",
              "value", $FILEMANAGER_ACTIONS_CHOWN_SUBMIT);
    formInput("type", "reset", "value", $RESET_STRING);
    formInput("type", "submit", "name", "submit",
              "value", $FILEMANAGER_ACTIONS_CHOWN_CANCEL);
    htmlTableDataClose();
    htmlTableRowClose();
  }
  htmlTableClose();
  formClose();
  htmlULClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################
# eof

1;

