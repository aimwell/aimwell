#
# fm_remove.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/fm_remove.pl,v 2.12.2.3 2006/04/25 19:48:23 rus Exp $
#
# file manager remove functions
#

##############################################################################

sub filemanagerCheckRemoveFileTarget
{
  local($fullpath, $virtualpath);

  encodingIncludeStringLibrary("filemanager");
  if ($g_form{'submit'} eq "$FILEMANAGER_ACTIONS_REMOVE_CANCEL") {
    unless ($g_form{'selected'}) {
      # need to set 'path' to 'selected' for the redirect
      $g_form{'path'} = (split(/\|\|\|/, $g_form{'selected'}))[0];
      $g_form{'path'} =~ s/\/+$//g;
      $g_form{'path'} =~ s/[^\/]+$//g;
      $g_form{'path'} =~ s/\/+$//g;
    }
    redirectLocation("filemanager.cgi", 
                     $FILEMANAGER_ACTIONS_REMOVE_CANCEL_TEXT);
  }

  # is one or more file selected?  
  if ((!$g_form{'path'}) && ($g_form{'selected'}) &&
      ($g_form{'selected'} !~ /\|\|\|/)) {
    $g_form{'path'} = $g_form{'selected'};
    $g_form{'selected'} = "";
  }

  if ($g_form{'selected'}) {
    # multiple files... files that don't exist in the specification will
    # be ignored when removal takes place, and an error message will be
    # displayed after the complete set of actions has been processed 
  }
  else {
    # single file... build full source path and check existence
    ($fullpath, $virtualpath) = filemanagerGetFullPath($g_form{'path'});
    unless ((-l "$fullpath") || (-e "$fullpath")) {
      filemanagerResourceNotFound("filemanagerCheckRemoveFileTarget
        verifying existence of \"$virtualpath\"");
    }
  }
}

##############################################################################

sub filemanagerRemoveFileConfirmForm
{
  local($fullpath, $virtualpath, $displaypath);
  local($filetype, $lcfiletype, @subpaths, $filename);
  local($ctext, $emptydir, $title, @selected);

  encodingIncludeStringLibrary("filemanager");

  # is one or more file selected?  
  if ((!$g_form{'path'}) && ($g_form{'selected'}) &&
      ($g_form{'selected'} !~ /\|\|\|/)) {
    $g_form{'path'} = $g_form{'selected'};
    $g_form{'selected'} = "";
  }

  if ($g_form{'selected'}) {
    $title = $FILEMANAGER_TITLE;
    $title =~ s/__FILE__//g;
    $title .= $FILEMANAGER_ACTIONS_REMOVE_MULTIPLE;
  }
  else {
    ($fullpath, $virtualpath) = filemanagerGetFullPath($g_form{'path'});
    if ($g_users{$g_auth{'login'}}->{'chroot'}) {
      $displaypath = "{$FILEMANAGER_HOMEDIR}" . $virtualpath;
    }
    else {
      $displaypath = $virtualpath;
    }
    unless ((-l "$fullpath") || (-e "$fullpath")) {
      filemanagerResourceNotFound("filemanagerRemoveFileConfirmForm
        verifying existence of \"$virtualpath\"");
    }
    @subpaths = split(/\//, $virtualpath);
    $filename = $subpaths[$#subpaths];
    $filetype = filemanagerGetFileType($fullpath);
    $FILEMANAGER_ACTIONS_REMOVE =~ s/__TYPE__/$filetype/g;
    $FILEMANAGER_ACTIONS_REMOVE_NAME =~ s/__TYPE__/$filetype/g;
    $title = $FILEMANAGER_TITLE;
    $title =~ s/__FILE__/$displaypath/g;
    $title .= " : $FILEMANAGER_ACTIONS_REMOVE";
  }
  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  htmlP();
  htmlUL();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "confirm", "value", "yes");
  if ($g_form{'selected'}) {
    # muliple files selected
    formInput("type", "hidden", "name", "selected", 
              "value", $g_form{'selected'});
    formInput("type", "hidden", "name", "ketd", "value", "no");
    htmlText($FILEMANAGER_ACTIONS_REMOVE_MULTIPLE_CONFIRM);
    htmlP();
    @subpaths = split(/\|\|\|/, $g_form{'selected'});
    foreach $filename (@subpaths) {
      ($fullpath, $virtualpath) = filemanagerGetFullPath($filename);
      push(@selected, "$fullpath|||$virtualpath");
    }
    htmlTable("border", "0", "cellpadding", "0", "cellspacing", "1");
    foreach $filename (sort filemanagerSelectedOrder(@selected)) {
      htmlTableRow();
      htmlTableData();
      htmlText("&#160;&#160;");
      htmlTableDataClose();
      ($fullpath, $virtualpath) = split(/\|\|\|/, $filename);
      if ($g_users{$g_auth{'login'}}->{'chroot'}) {
        $displaypath = "{$FILEMANAGER_HOMEDIR}" . $virtualpath;
      }
      else {
        $displaypath = $virtualpath;
      }
      htmlTableData("valign", "middle", "width", "24", "align", "right");
      if ((-d "$fullpath") && (!(-l "$fullpath"))) {
        htmlImg("border", "0", "width", "24", "height", "24",
                "src", "$g_graphicslib/folder.jpg");
      }
      elsif (-l "$fullpath") {
        htmlImg("border", "0", "width", "24", "height", "24",
                "src", "$g_graphicslib/link.jpg");
      }
      else {
        htmlImg("border", "0", "width", "24", "height", "24",
                "src", "$g_graphicslib/file.jpg");
      }
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlText("&#160;$displaypath");
      htmlTableDataClose();
      htmlTableRowClose();
    }
    htmlTableClose();
    htmlP();
    formInput("type", "submit", "name", "submit",
              "value", $FILEMANAGER_ACTIONS_REMOVE_CONFIRM_MULTIPLE);
  }
  else {
    htmlTextBold("$FILEMANAGER_ACTIONS_REMOVE_NAME: &#160;");
    htmlText($virtualpath);
    htmlP();
    formInput("type", "hidden", "name", "path", "value", $virtualpath);
    if ((-d "$fullpath") && (!(-l "$fullpath"))) {
      # target is a directory
      $emptydir = 1;
      if (opendir(CURDIR, "$fullpath")) {
        foreach $filename (readdir(CURDIR)) {
          next if (($filename eq ".") || ($filename eq ".."));
          $emptydir = 0;
          last;
        }
        closedir(CURDIR);
      }
      if ($emptydir) {
        # print ketd as a hidden field... set to "no"
        # fyi... ketd = keep empty target directory
        formInput("type", "hidden", "name", "ketd", "value", "no");
        $ctext = $FILEMANAGER_ACTIONS_REMOVE_CONFIRM_SINGLE_TEXT;
        $lcfiletype = $filetype;
        $lcfiletype =~ tr/A-Z/a-z/;
        $ctext =~ s/__LCTYPE__/$lcfiletype/g;
        $ctext =~ s/__FILE__/$filename/g;
        htmlText($ctext);
        htmlP();
        $FILEMANAGER_ACTIONS_REMOVE_CONFIRM_SINGLE =~ s/__TYPE__/$filetype/g;
        formInput("type", "submit", "name", "submit", 
                  "value", $FILEMANAGER_ACTIONS_REMOVE_CONFIRM_SINGLE);
      }
      else {
        htmlText($FILEMANAGER_ACTIONS_REMOVE_CONFIRM_MULTIPLE_TEXT); 
        htmlP(); 
        # print ketd as a toggle using whatever value was passed in
        $g_form{'ketd'} = "no" unless ($g_form{'ketd'});
        formInput("type", "checkbox", "name", "ketd", "value", "yes",
                  "_OTHER_", ($g_form{'ketd'} eq "yes") ? "CHECKED" : "");
        htmlText($FILEMANAGER_ACTIONS_REMOVE_KEPD);
        htmlP();
        formInput("type", "submit", "name", "submit",
                  "value", $FILEMANAGER_ACTIONS_REMOVE_CONFIRM_MULTIPLE);
      }
    }
    else {
      $ctext = $FILEMANAGER_ACTIONS_REMOVE_CONFIRM_SINGLE_TEXT;
      $lcfiletype = $filetype;
      $lcfiletype =~ tr/A-Z/a-z/;
      $ctext =~ s/__LCTYPE__/$lcfiletype/g;
      $ctext =~ s/__FILE__/$filename/g;
      htmlText($ctext);
      htmlP();
      $FILEMANAGER_ACTIONS_REMOVE_CONFIRM_SINGLE =~ s/__TYPE__/$filetype/g;
      formInput("type", "submit", "name", "submit", 
                "value", $FILEMANAGER_ACTIONS_REMOVE_CONFIRM_SINGLE);
    }
  }
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "submit", 
            "value", $FILEMANAGER_ACTIONS_REMOVE_CANCEL);
  formClose();
  htmlULClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub filemanagerRemoveTargetDirectory
{
  local($fullpath, $ketd) = @_;
  local($filename, $ftp, $homedir, $errortxt, $virtualpath);
  local(*CURDIR);

  $errortxt = "";

  # remove the files in the directory first
  if (opendir(CURDIR, "$fullpath")) {
    foreach $filename (readdir(CURDIR)) {
      next if (($filename eq ".") || ($filename eq ".."));
      $ftp = "$fullpath/$filename";
      if (-l "$ftp") {
        $errortxt .= filemanagerRemoveTargetFile($ftp);
      }
      elsif (-d "$ftp") {
        $errortxt .= filemanagerRemoveTargetDirectory($ftp, 0);
      }
      else {
        $errortxt .= filemanagerRemoveTargetFile($ftp);
      }
    }
    closedir(CURDIR);
  }

  # now remove the directory if it is ok
  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  if ($ketd || ($fullpath eq $homedir) || ($fullpath eq "$homedir/")) {
    # do nothing
    # fyi... ketd = keep empty target directory
  }
  else {
    unless (rmdir($fullpath)) {
      $virtualpath = $fullpath;
      $virtualpath =~ s/^$homedir// if ($homedir ne "/");
      $errortxt .= "rmdir('$virtualpath'): $!\n";
    }
  }
  return($errortxt);
}

##############################################################################

sub filemanagerRemoveTargetFile
{
  local($fullpath) = @_;
  local($errortxt, $virtualpath, $homedir);

  $errortxt = "";

  # pretty simple task -- nuke the file
  unless (unlink($fullpath)) {
    $homedir = $g_users{$g_auth{'login'}}->{'home'};
    $virtualpath = $fullpath;
    $virtualpath =~ s/^$homedir// if ($homedir ne "/");
    $errortxt = "unlink('$virtualpath'): $!\n";
  }
  return($errortxt);
}

##############################################################################

sub filemanagerRemoveTarget
{
  local($fullpath, $virtualpath, $filetype);
  local(@subpaths, @selected, $filename);
  local($ketd, $stxt, $etxt);

  # is one or more file selected?  
  if ((!$g_form{'path'}) && ($g_form{'selected'}) &&
      ($g_form{'selected'} !~ /\|\|\|/)) {
    $g_form{'path'} = $g_form{'selected'};
    $g_form{'selected'} = "";
  }

  # fyi... ketd = keep empty target directory
  $ketd = ($g_form{'ketd'} && ($g_form{'ketd'} eq "yes")) ? 1 : 0;

  encodingIncludeStringLibrary("filemanager");

  $etxt = "";
  if ($g_form{'selected'}) {
    @subpaths = split(/\|\|\|/, $g_form{'selected'});
    foreach $filename (@subpaths) {
      ($fullpath, $virtualpath) = filemanagerGetFullPath($filename);
      push(@selected, "$fullpath|||$virtualpath");
    }
    # remove the files in sort order so that error messages (if they
    # are encountered) are displayed in the the right order
    foreach $filename (sort filemanagerSelectedOrder(@selected)) {
      ($fullpath, $virtualpath) = split(/\|\|\|/, $filename);
      if ((-d "$fullpath") && (!(-l "$fullpath"))) {
        $etxt .= filemanagerRemoveTargetDirectory($fullpath, $ketd);
      }
      else {
        # remove target file
        $etxt .= filemanagerRemoveTargetFile($fullpath);
      }
    }
    $stxt = $FILEMANAGER_ACTIONS_REMOVE_MULITPLE_SUCCESS_TEXT;
    $g_form{'path'} = $subpaths[0];
    $g_form{'path'} =~ s/\/$//g;
    $g_form{'path'} =~ s/[^\/]+$//g;
    $g_form{'path'} =~ s/\/$//g;
  }
  else {
    # build full source path
    ($fullpath, $virtualpath) = filemanagerGetFullPath($g_form{'path'});
    unless ((-l "$fullpath") || (-e "$fullpath")) {
      filemanagerResourceNotFound("filemanagerRemoveTarget
        verifying existence of \"$virtualpath\"");
    }
    # remove the specified target
    if ((-d "$fullpath") && (!(-l "$fullpath"))) {
      $etxt = filemanagerRemoveTargetDirectory($fullpath, $ketd);
    }
    else {
      # remove target file
      $etxt = filemanagerRemoveTargetFile($fullpath);
      $ketd = 0;  # this is probably already zero anyway
    }
    # set a new form path value and show happy results
    if ($ketd == 0) {
      unless ($etxt) {
        # we nuked the old target, build a new one
        $virtualpath =~ s/\/$//g;
        $virtualpath =~ s/[^\/]+$//g;
        $virtualpath =~ s/\/$//g;
      }
      $stxt = $FILEMANAGER_ACTIONS_REMOVE_SUCCESS_TEXT;
      $filetype = filemanagerGetFileType($fullpath);
      $stxt =~ s/__TYPE__/$filetype/g;
    }
    else {
      # we kept the empty target directory; so displaying the purge 
      # directory success message is appropiate
      $stxt = $FILEMANAGER_ACTIONS_PURGE_SUCCESS_TEXT
    }
    $g_form{'path'} = $virtualpath;
  }

  # redirect with error message text (if defined) or success message text
  unless ($etxt) {
    $stxt =~ s/\n/\ /g;
    redirectLocation("filemanager.cgi", $stxt);
  }
  else {
    redirectLocation("filemanager.cgi", $etxt);
  }
}

##############################################################################
# eof

1;

