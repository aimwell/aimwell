#
# fm_chmod.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/fm_chmod.pl,v 2.12.2.3 2006/04/25 19:48:23 rus Exp $
#
# file manager change mode functions
#

##############################################################################

sub filemanagerChangeTargetPermissions
{
  local($fullpath, $virtualpath, $fmode, $fmodestr);

  # build full source path
  ($fullpath, $virtualpath) = filemanagerGetFullPath($g_form{'path'});

  unless ((-l "$fullpath") || (-e "$fullpath")) {
    filemanagerResourceNotFound("filemanagerChangeTargetPermissions
      verifying existence of \"$virtualpath\"");
  }

  encodingIncludeStringLibrary("filemanager");

  # build the octal permission mode
  if ($g_form{'readable'} && ($g_form{'readable'} eq "yes")) {
    $g_form{'ur'} = "yes";
    $g_form{'gr'} = "yes";
    $g_form{'or'} = "yes";
  }
  if ($g_form{'writable'} && ($g_form{'writable'} eq "yes")) {
    $g_form{'uw'} = "yes";
  }
  if ($g_form{'executable'} && ($g_form{'executable'} eq "yes")) {
    $g_form{'ux'} = "yes";
    $g_form{'gx'} = "yes";
    $g_form{'ox'} = "yes";
  }
  $fmode = 0;
  $fmode += ($g_form{'ur'}) ? 0400 : 0;
  $fmode += ($g_form{'uw'}) ? 0200 : 0;
  $fmode += ($g_form{'ux'}) ? 0100 : 0;  
  $fmode += ($g_form{'gr'}) ?  040 : 0;
  $fmode += ($g_form{'gw'}) ?  020 : 0;
  $fmode += ($g_form{'gx'}) ?  010 : 0;
  $fmode += ($g_form{'or'}) ?   04 : 0;
  $fmode += ($g_form{'ow'}) ?   02 : 0;
  $fmode += ($g_form{'ox'}) ?   01 : 0;

  $fmodestr = sprintf "%o", $fmode;

  # change the mode
  filemanagerChmod($fmode, $fullpath) ||
    filemanagerResourceError($FILEMANAGER_ACTIONS_CHMOD,
        "call to chmod($fmodestr, $fullpath) in filemanagerChmod");

  # success! show happy results
  $FILEMANAGER_ACTIONS_CHMOD_SUCCESS_TEXT =~ s/\n/\ /g;
  redirectLocation("filemanager.cgi",
                   $FILEMANAGER_ACTIONS_CHMOD_SUCCESS_TEXT);
}

##############################################################################

sub filemanagerCheckChmodTarget
{
  local($fullpath, $virtualpath);

  # build full source path
  ($fullpath, $virtualpath) = filemanagerGetFullPath($g_form{'path'});

  unless ((-l "$fullpath") || (-e "$fullpath")) {
    filemanagerResourceNotFound("filemanagerCheckChmodTarget
      verifying existence of \"$virtualpath\"");
  }

  encodingIncludeStringLibrary("filemanager");

  if ($g_form{'submit'} eq "$FILEMANAGER_ACTIONS_CHMOD_CANCEL") {
    redirectLocation("filemanager.cgi",
                     $FILEMANAGER_ACTIONS_CHMOD_CANCEL_TEXT);
  }
}

##############################################################################

sub filemanagerChmodForm
{
  local($fullpath, $virtualpath, $displaypath);
  local($filetype, $fmode, $perms, $encpath, @colspan);
  local($ptxt_rwx, $ptxt_oct);

  encodingIncludeStringLibrary("filemanager");

  ($fullpath, $virtualpath) = filemanagerGetFullPath($g_form{'path'});
  if ($g_users{$g_auth{'login'}}->{'chroot'}) {
    $displaypath = "{$FILEMANAGER_HOMEDIR}" . $virtualpath;
  }
  else {
    $displaypath = $virtualpath;
  }

  unless ((-l "$fullpath") || (-e "$fullpath")) {
    filemanagerResourceNotFound("filemanagerChmodForm
      verifying existence of \"$virtualpath\"");
  }

  $fmode = (stat($fullpath))[2];

  $filetype = filemanagerGetFileType($fullpath);
  $FILEMANAGER_ACTIONS_CHMOD_NAME =~ s/__TYPE__/$filetype/;
  $FILEMANAGER_PERMS =~ s/__TYPE__/$filetype/;

  # co = chmod options
  unless ($g_form{'co'}) {
    $g_form{'co'} = $g_prefs{'ftp__chmod_options'};
  }

  $encpath = encodingStringToURL($virtualpath);

  @colspan = ($g_form{'co'} eq "basic") ? () : ("colspan", "12");

  htmlResponseHeader("Content-type: $g_default_content_type");
  $FILEMANAGER_TITLE =~ s/__FILE__/$displaypath/g;
  labelCustomHeader("$FILEMANAGER_TITLE : $FILEMANAGER_ACTIONS_CHMOD");
  htmlP();
  htmlUL();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "path", "value", $virtualpath);
  formInput("type", "hidden", "name", "co", "value", $g_form{'co'});
  htmlTable();
  htmlTableRow();
  htmlTableData("valign", "middle", "align", "left");
  htmlNoBR();
  htmlTextBold("$FILEMANAGER_ACTIONS_CHMOD_NAME:&#160;&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left", @colspan);
  htmlText($virtualpath);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle", "align", "left");
  htmlNoBR();
  htmlTextBold("$FILEMANAGER_PERMS:&#160;&#160;");
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableData("valign", "middle", "align", "left", @colspan);
  htmlNoBR();
  if ($g_form{'co'} eq "advanced") {
    ($ptxt_rwx, $ptxt_oct) = filemanagerGetPermissionsText($fmode);
    htmlTextCode("$ptxt_rwx ($ptxt_oct)");
  }
  else {
    if (($fmode >> 6) & 04) {
      $perms .= $FILEMANAGER_PERMS_READABLE;
    }
    if (($fmode >> 6) & 02) {
      $perms .= ", " if ($perms);
      $perms .= $FILEMANAGER_PERMS_WRITABLE;
    }
    if (($fmode >> 6) & 01) {
      $perms .= ", " if ($perms);
      $perms .= $FILEMANAGER_PERMS_EXECUTABLE;
    }
    $perms = $NONE_STRING unless ($perms);
    htmlText($perms);
  }
  htmlNoBRClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableRow();
  htmlTableData("valign", "middle", "align", "left");
  htmlTextBold("$FILEMANAGER_ACTIONS_CHMOD_NEW:&#160;&#160;");
  htmlTableDataClose();
  if ($g_form{'co'} eq "advanced") {
    htmlTableData("valign", "middle", "align", "center");
    htmlNoBR();
    formInput("type", "checkbox", "name", "ur", "value", "yes",
              "_OTHER_", (($fmode >> 6) & 04) ? "CHECKED" : "");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    formInput("type", "checkbox", "name", "uw", "value", "yes",
              "_OTHER_", (($fmode >> 6) & 02) ? "CHECKED" : "");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    formInput("type", "checkbox", "name", "ux", "value", "yes",
              "_OTHER_", (($fmode >> 6) & 01) ? "CHECKED" : "");
    htmlTableDataClose();
    htmlTableData();
    htmlText("&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    formInput("type", "checkbox", "name", "gr", "value", "yes",
              "_OTHER_", (($fmode >> 3) & 04) ? "CHECKED" : "");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    formInput("type", "checkbox", "name", "gw", "value", "yes",
              "_OTHER_", (($fmode >> 3) & 02) ? "CHECKED" : "");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    formInput("type", "checkbox", "name", "gx", "value", "yes",
              "_OTHER_", (($fmode >> 3) & 01) ? "CHECKED" : "");
    htmlTableDataClose();
    htmlTableData();
    htmlText("&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    formInput("type", "checkbox", "name", "or", "value", "yes",
              "_OTHER_", ($fmode & 04) ? "CHECKED" : "");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    formInput("type", "checkbox", "name", "ow", "value", "yes",
              "_OTHER_", ($fmode & 02) ? "CHECKED" : "");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    formInput("type", "checkbox", "name", "ox", "value", "yes",
              "_OTHER_", ($fmode & 01) ? "CHECKED" : "");
    htmlTableDataClose();
    htmlTableData();
    htmlTextSmall("&#160; (");
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?path=$encpath&co=basic",
               "title", $FILEMANAGER_ACTIONS_CHMOD_BASIC_OPTS);
    htmlAnchorTextSmall($FILEMANAGER_ACTIONS_CHMOD_BASIC_OPTS);
    htmlAnchorClose();
    htmlTextSmall(")");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    htmlTextCode("r");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    htmlTextCode("w");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    htmlTextCode("x");
    htmlTableDataClose();
    htmlTableData();
    htmlText("&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    htmlTextCode("r");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    htmlTextCode("w");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    htmlTextCode("x");
    htmlTableDataClose();
    htmlTableData();
    htmlText("&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    htmlTextCode("r");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    htmlTextCode("w");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center");
    htmlTextCode("x");
    htmlTableDataClose();
    htmlTableData();
    htmlText("&#160;");
    htmlTableDataClose();
    htmlTableRowClose();
    htmlTableRow();
    htmlTableData();
    htmlText("&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center", "colspan", "3");
    htmlTextCode($FILEMANAGER_PERMS_OWNER);
    htmlTableDataClose();
    htmlTableData();
    htmlText("&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center", "colspan", "3");
    htmlTextCode($FILEMANAGER_PERMS_GROUP);
    htmlTableDataClose();
    htmlTableData();
    htmlText("&#160;");
    htmlTableDataClose();
    htmlTableData("valign", "middle", "align", "center", "colspan", "3");
    htmlTextCode($FILEMANAGER_PERMS_OTHERS);
    htmlTableDataClose();
    htmlTableData();
    htmlText("&#160;");
    htmlTableDataClose();
  }
  else {
    htmlTableData("valign", "middle", "align", "left");
    htmlNoBR();
    formInput("type", "checkbox", "name", "readable", "value", "yes",
              "_OTHER_", (($fmode >> 6) & 04) ? "CHECKED" : "");
    htmlText("$FILEMANAGER_PERMS_READABLE &#160;");
    formInput("type", "checkbox", "name", "writable", "value", "yes",
              "_OTHER_", (($fmode >> 6) & 02) ? "CHECKED" : "");
    htmlText("$FILEMANAGER_PERMS_WRITABLE &#160;");
    formInput("type", "checkbox", "name", "executable", "value", "yes",
              "_OTHER_", (($fmode >> 6) & 01) ? "CHECKED" : "");
    htmlText("$FILEMANAGER_PERMS_EXECUTABLE &#160;");
    htmlText("&#160; &#160;");
    htmlTextSmall("(");
    htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?path=$encpath&co=advanced",
               "title", $FILEMANAGER_ACTIONS_CHMOD_ADVANCED_OPTS);
    htmlAnchorTextSmall($FILEMANAGER_ACTIONS_CHMOD_ADVANCED_OPTS);
    htmlAnchorClose();
    htmlTextSmall(")");
    htmlTableDataClose();
  }
  htmlTableRowClose();
  htmlTableRow();
  if ($g_form{'co'} eq "advanced") {
    htmlTableData("colspan", "13", "align", "left");
  }
  else {
    htmlTableData("colspan", "2", "align", "left");
  }
  htmlImg("width", "1", "height", "8", "src", "$g_graphicslib/sp.gif");
  htmlBR();
  formInput("type", "submit", "name", "submit",
            "value", $FILEMANAGER_ACTIONS_CHMOD_SUBMIT);
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "submit",
            "value", $FILEMANAGER_ACTIONS_CHMOD_CANCEL);
  htmlTableDataClose();
  htmlTableRowClose();
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

