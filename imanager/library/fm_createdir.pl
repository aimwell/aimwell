#
# fm_createdir.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/fm_createdir.pl,v 2.12.2.3 2006/04/25 19:48:23 rus Exp $
#
# file manager create directory functions
#

##############################################################################

sub filemanagerCheckCreateDirectoryTarget
{
  local($fsp, $vsp, $ftp, $vtp);

  # build full source path
  ($fsp, $vsp) = filemanagerGetFullPath($g_form{'path'});

  encodingIncludeStringLibrary("filemanager");

  if ($g_form{'submit'} eq "$FILEMANAGER_ACTIONS_CREATEDIR_CANCEL") {
    redirectLocation("filemanager.cgi", 
                     $FILEMANAGER_ACTIONS_CREATEDIR_CANCEL_TEXT);
  }

  unless ($g_form{'targetpath'}) {
    # uh... damnit beavis
    filemanagerCreateDirectoryForm("EMPTY_FIELD");
  }

  # build full target path
  ($ftp, $vtp) = filemanagerGetFullPath($g_form{'targetpath'}, $fsp);

  # actions that aren't allowed
  if (-d "$ftp") {
    # the directory specified already exists... oops!
    $FILEMANAGER_ACTIONS_CREATEDIR_ALREADY_EXIST_ERROR =~ s/__TARGET__/$vtp/;
    filemanagerUserError($FILEMANAGER_ACTIONS_CREATEDIR, 
                         $FILEMANAGER_ACTIONS_CREATEDIR_ALREADY_EXIST_ERROR);
  }
  if ((-e "$ftp") && ((-f "$ftp") || (-l "$ftp"))) {
    # target exists, target is a plain file (or a symlink)...  not allowed
    # to clobber an existing file with a directory
    $FILEMANAGER_ACTIONS_CREATEDIR_NO_CLOBBER_ERROR =~ s/__TARGET__/$vtp/;
    filemanagerUserError($FILEMANAGER_ACTIONS_CREATEDIR, 
                         $FILEMANAGER_ACTIONS_CREATEDIR_NO_CLOBBER_ERROR);
  }
}

##############################################################################

sub filemanagerCreateDirectoryForm
{
  local($mesg) = @_;
  local($fullpath, $virtualpath, $displaypath);
  local(@subpaths, $index, $size, $errortext);

  encodingIncludeStringLibrary("filemanager");

  ($fullpath, $virtualpath) = filemanagerGetFullPath($g_form{'path'});
  if ($g_users{$g_auth{'login'}}->{'chroot'}) {
    $displaypath = "{$FILEMANAGER_HOMEDIR}" . $virtualpath;
  }
  else {
    $displaypath = $virtualpath;
  }

  unless (-e "$fullpath") {
    filemanagerResourceNotFound("filemanagerCreateDirectoryFileForm
      verifying existence of \"$virtualpath\"");
  }

  @subpaths = split(/\//, $virtualpath);

  htmlResponseHeader("Content-type: $g_default_content_type");
  $FILEMANAGER_TITLE =~ s/__FILE__/$displaypath/g;
  labelCustomHeader("$FILEMANAGER_TITLE : $FILEMANAGER_ACTIONS_CREATEDIR");
  htmlUL();
  if ($mesg && ($mesg eq "EMPTY_FIELD")) {
    $errortext = $FILEMANAGER_EMPTY_FIELD_ERROR;
    $errortext =~ s/__NAME__/$FILEMANAGER_ACTIONS_CREATEDIR_TARGET/;
    htmlTextColorBold(">>> $errortext <<<", "#cc0000");
    htmlP();
  } 
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "action", "value", "submit");
  formInput("type", "hidden", "name", "path", "value", $virtualpath);
  unless ($g_form{'targetpath'}) {
    for ($index=0; $index<=$#subpaths; $index++) {
      next unless ($subpaths[$index]);
      $g_form{'targetpath'} .= "/$subpaths[$index]";
    }
    $g_form{'targetpath'} .= "/" . $FILEMANAGER_ACTIONS_CREATEDIR_NEW_TEXT;
  }
  $size = sprintf "%d", length($g_form{'targetpath'}) / 5;
  $size +=2;  # extra space
  $size *= 5;
  $size = 40 if ($size < 40);
  $size = 60 if ($size > 55);
  htmlTextBold("$FILEMANAGER_CWD: &#160;");
  htmlText($virtualpath);
  htmlP();
  htmlTextBold("$FILEMANAGER_ACTIONS_CREATEDIR_TARGET:");
  htmlBR();
  formInput("size", $size, "name", "targetpath", 
            "value", $g_form{'targetpath'});
  htmlP();
  formInput("type", "submit", "name", "submit", 
            "value", $FILEMANAGER_ACTIONS_CREATEDIR);
  formInput("type", "reset", "value", $RESET_STRING);
  formInput("type", "submit", "name", "submit", 
            "value", $FILEMANAGER_ACTIONS_CREATEDIR_CANCEL);
  formClose();
  htmlULClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub filemanagerCreateDirectoryTarget
{
  local($ftp, $vtp, $parent, $fmode);

  # build full target path
  ($ftp, $vtp) = filemanagerGetFullPath($g_form{'targetpath'});

  encodingIncludeStringLibrary("filemanager");

  # create the target directory
  filemanagerCreateDirectory($ftp);
  
  # modify the directory perms if applicable
  $parent = $ftp;
  $parent =~ s/\/$//;
  $parent =~ s/[^\/]+$//g;
  if (($g_platform_type eq "dedicated") && ($parent)) {
    ($fmode) = (stat($parent))[2];
    chmod($fmode, $ftp);
  }

  # set a new form path value and show happy results
  $g_form{'path'} = $vtp;
  $FILEMANAGER_ACTIONS_CREATEDIR_SUCCESS_TEXT =~ s/\n/\ /g;
  redirectLocation("filemanager.cgi", 
                   $FILEMANAGER_ACTIONS_CREATEDIR_SUCCESS_TEXT);
}

##############################################################################
# eof

1;

