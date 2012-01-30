#
# fm_createfile.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/fm_createfile.pl,v 2.12.2.3 2006/04/25 19:48:23 rus Exp $
#
# file manager create new file functions
#

##############################################################################

sub filemanagerCheckNewFileTarget
{
  local($fsp, $vsp, $ftp, $vtp, $ltarget);

  # build full source path
  ($fsp, $vsp) = filemanagerGetFullPath($g_form{'path'});

  encodingIncludeStringLibrary("filemanager");

  if ($g_form{'submit'} eq "$FILEMANAGER_ACTIONS_NEWFILE_CANCEL") {
    redirectLocation("filemanager.cgi",
                     $FILEMANAGER_ACTIONS_NEWFILE_CANCEL_TEXT);
  }

  unless ($g_form{'targetpath'}) {
    # uh... damnit beavis
    filemanagerNewFileForm("EMPTY_FIELD");
  }

  # build full target path
  ($ftp, $vtp) = filemanagerGetFullPath($g_form{'targetpath'});

  # actions that aren't allowed
  if ((-e "$ftp") && (-d "$ftp") && (!(-l "$ftp"))) {
    # target exists, target is a directory...  not allowed
    # to clobber an existing file with a directory
    $FILEMANAGER_ACTIONS_NEWFILE_NO_CLOBBER_ERROR =~ s/__TARGET__/$vtp/;
    filemanagerUserError($FILEMANAGER_ACTIONS_NEWFILE, 
                         $FILEMANAGER_ACTIONS_NEWFILE_NO_CLOBBER_ERROR);
  }
  # check the specified path to see if a subcomponent exists as a file
  @subpaths = split(/\//, $vtp);
  $testpath = $g_users{$g_auth{'login'}}->{'path'};
  for ($index=0; $index<$#subpaths; $index++) {
    next unless ($subpaths[$index]);
    $testpath .= "/$subpaths[$index]";
    $testpath =~ s/\/\//\//g;
    $ltarget = readlink($testpath) if (-l "$testpath");
    if ((-e "$testpath") && 
        ((-f "$testpath") || 
         ((-l "$testpath") && (-f "$ltarget")))) {
      $FILEMANAGER_FILE_IN_TARGET_PATH_ERROR =~ s/__TARGET__/$vtp/;
      $FILEMANAGER_FILE_IN_TARGET_PATH_ERROR =~ s/__SUBPATH__/$testpath/; 
      filemanagerUserError($FILEMANAGER_ACTIONS_NEWFILE,
                           $FILEMANAGER_FILE_IN_TARGET_PATH_ERROR);
    }
  }

  $g_form{'confirm'} = "no" unless ($g_form{'confirm'});
  if ($g_form{'confirm'} ne "yes") {
    # need a confirmation for overwriting files
    if ($g_prefs{'ftp__confirm_file_overwrite'} eq "yes") {
      if ((-e "$ftp") && ((-f "$ftp") || (-l "$ftp"))) {
        # target exists, target is a plain file
        filemanagerNewFileForm("CONFIRM_OVERWRITE");
      }
    }
    # confirm the creation of new directories
    if ($g_prefs{'ftp__confirm_dir_create'} eq "yes") {
      $testpath = $g_users{$g_auth{'login'}}->{'path'};
      for ($index=0; $index<$#subpaths; $index++) {
        next unless ($subpaths[$index]);
        $testpath .= "/$subpaths[$index]";
        $testpath =~ s/\/\//\//g;
        unless (-e "$testpath") {
          filemanagerNewFileForm("CONFIRM_CREATEDIR");
        }
      }
    }
  }
}

##############################################################################

sub filemanagerNewFileForm
{
  local($mesg) = @_;
  local($fullpath, $virtualpath, $displaypath);
  local(@subpaths, $helptext, $index, $size);

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
  labelCustomHeader("$FILEMANAGER_TITLE : $FILEMANAGER_ACTIONS_NEWFILE");
  if ($mesg && ($mesg eq "CONFIRM_OVERWRITE")) {
    $helptext = $FILEMANAGER_ACTIONS_NEWFILE_CONFIRM_OVERWRITE_TEXT;
    $helptext =~ s/__FILE__/$g_form{'targetpath'}/g;
    htmlText($helptext);
  }
  elsif ($mesg && ($mesg eq "CONFIRM_CREATEDIR")) {
    $helptext = $FILEMANAGER_ACTIONS_NEWFILE_CONFIRM_CREATEDIR_TEXT;
    $helptext =~ s/__FILE__/$g_form{'targetpath'}/g;
    htmlText($helptext);
  }
  htmlUL();
  if ($mesg && ($mesg eq "EMPTY_FIELD")) { 
    $errortext = $FILEMANAGER_EMPTY_FIELD_ERROR;
    $errortext =~ s/__NAME__/$FILEMANAGER_ACTIONS_NEWFILE_TARGET/;
    htmlTextColorBold(">>> $errortext <<<", "#cc0000");
    htmlP();
  }
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "action", "value", "submit");
  formInput("type", "hidden", "name", "path", "value", $virtualpath);
  if (!$mesg || ($mesg eq "EMPTY_FIELD")) {
    unless ($g_form{'targetpath'}) {
      for ($index=0; $index<=$#subpaths; $index++) {
        next unless ($subpaths[$index]);
        $g_form{'targetpath'} .= "/$subpaths[$index]";
      }
      $g_form{'targetpath'} .= "/" . $FILEMANAGER_ACTIONS_NEWFILE_NEW_TEXT;
      if ($fullpath =~ /cgi-bin/) {
        $g_form{'targetpath'} .= ".pl";
      }
      elsif (($fullpath =~ /htdocs/) || ($fullpath =~ /vhosts/)) {
        $g_form{'targetpath'} .= ".html";
      }
      else {
        $g_form{'targetpath'} .= ".txt";
      }
    }
    $size = sprintf "%d", length($g_form{'targetpath'}) / 5;
    $size++;  $size *= 5;
    $size = 40 if ($size < 40);
    $size = 60 if ($size > 55);
    htmlTextBold("$FILEMANAGER_CWD: &#160;");
    htmlText($virtualpath);
    htmlP();
    htmlTextBold("$FILEMANAGER_ACTIONS_NEWFILE_TARGET:");
    htmlBR();
    formInput("size", $size, "name", "targetpath", 
              "value", $g_form{'targetpath'});
    htmlP();
    $g_form{'enf'} = "yes" unless ($g_form{'enf'});  # enf = edit new file
    formInput("type", "checkbox", "name", "enf", "value", "yes",
              "_OTHER_", ($g_form{'enf'} eq "yes") ? "CHECKED" : "");
    htmlText($FILEMANAGER_ACTIONS_NEWFILE_ENF);
    htmlP();
    formInput("type", "submit", "name", "submit", 
              "value", $FILEMANAGER_ACTIONS_NEWFILE);
  }
  else {
    $g_form{'enf'} = "no" unless ($g_form{'enf'});  # enf = edit new file
    formInput("type", "hidden", "name", "confirm", "value", "yes");
    formInput("type", "hidden", "name", "enf", "value", $g_form{'enf'});
    formInput("type", "hidden", "name", "targetpath",
              "value", $g_form{'targetpath'});
    if ($mesg eq "CONFIRM_OVERWRITE") {
      formInput("type", "submit", "name", "submit",
                "value", $FILEMANAGER_CONFIRM_OVERWRITE);
    }
    elsif ($mesg eq "CONFIRM_CREATEDIR") {
      formInput("type", "submit", "name", "submit",
                "value", $FILEMANAGER_CONFIRM_CREATEDIR);
    }
  }
  formInput("type", "submit", "name", "submit", 
            "value", $FILEMANAGER_ACTIONS_NEWFILE_CANCEL);
  if (!$mesg || ($mesg eq "EMPTY_FIELD")) {
    formInput("type", "reset", "value", $RESET_STRING);
  }
  formClose();
  htmlULClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub filemanagerCreateNewFile
{
  local($ftp, $vtp, $ftpd, $fmode);

  # build full target path
  ($ftp, $vtp) = filemanagerGetFullPath($g_form{'targetpath'});

  encodingIncludeStringLibrary("filemanager");

  # create any directories necessary to fulfill the request
  $ftpd = $ftp;  # i know i know... these are stupid variable names
  $ftpd =~ s/\/$//;
  $ftpd =~ s/[^\/]+$//g;
  filemanagerCreateDirectory($ftpd);

  # create the target file
  open(TFP, ">$ftp") || 
    filemanagerResourceError($FILEMANAGER_ACTIONS_NEWFILE,
        "open(>$ftp) call for target in filemanagerCreateNewFile");
  close(TFP);

  # modify the file perms if applicable
  if (($g_platform_type eq "dedicated") && ($ftpd)) {
    ($fmode) = (stat($ftpd))[2]; 
    $fmode &= 0677 if ($fmode & 0100);
    $fmode &= 0767 if ($fmode & 0010);
    $fmode &= 0776 if ($fmode & 0001);
    chmod($fmode, $ftp);
  }
  
  # set a new form path value and show happy results
  $g_form{'path'} = $vtp;
  if ($g_form{'enf'} eq "yes") {
    $FILEMANAGER_ACTIONS_NEWFILE_SUCCESS_EDIT_TEXT =~ s/\n/\ /g;
    redirectLocation("fm_edit.cgi",
                     $FILEMANAGER_ACTIONS_NEWFILE_SUCCESS_EDIT_TEXT);
  }
  else {
    $FILEMANAGER_ACTIONS_NEWFILE_SUCCESS_TEXT =~ s/\n/\ /g;
    redirectLocation("filemanager.cgi",
                     $FILEMANAGER_ACTIONS_NEWFILE_SUCCESS_TEXT);
  }
}

##############################################################################
# eof

1;

