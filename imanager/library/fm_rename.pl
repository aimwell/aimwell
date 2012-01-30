#
# fm_rename.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/fm_rename.pl,v 2.12.2.3 2006/04/25 19:48:23 rus Exp $
#
# file manager rename (move) functions
#

##############################################################################

sub filemanagerCheckRenameFileTarget
{
  local($fsp, $vsp, $ftp, $vtp);
  local(@subpaths, $index, $mi, $testpath, $filetype, $filename);
  local(%sourcepaths, $sourcepath, $curdir);

  encodingIncludeStringLibrary("filemanager");
  if ($g_form{'submit'} eq "$FILEMANAGER_ACTIONS_RENAME_CANCEL") {
    if ($g_form{'selected'}) {
      # need to set 'path' to 'selected' for the redirect
      $g_form{'path'} = (split(/\|\|\|/, $g_form{'selected'}))[0];
      $g_form{'path'} =~ s/\/+$//g;
      $g_form{'path'} =~ s/[^\/]+$//g;
      $g_form{'path'} =~ s/\/+$//g;
    }
    redirectLocation("filemanager.cgi",
                     $FILEMANAGER_ACTIONS_RENAME_CANCEL_TEXT);
  }

  unless ($g_form{'targetpath'}) {
    # uh... damnit beavis
    filemanagerRenameFileForm("EMPTY_FIELD");
  }

  # is one or more file selected?  
  if ((!$g_form{'path'}) && ($g_form{'selected'}) &&
      ($g_form{'selected'} !~ /\|\|\|/)) {
    $g_form{'path'} = $g_form{'selected'};
    $g_form{'selected'} = "";
  }

  if ($g_form{'path'}) {
    $sourcepaths{$g_form{'path'}} = "dau!";
  }
  else {
    @subpaths = split(/\|\|\|/, $g_form{'selected'});
    foreach $sourcepath (@subpaths) {
      $sourcepaths{$sourcepath} = "dau!";
    }
  }

  # loop through the selected sourcepaths and check for errors
  foreach $sourcepath (keys(%sourcepaths)) {
    # build full source path
    ($fsp, $vsp) = filemanagerGetFullPath($sourcepath);
    $fsp =~ /([^\/]+)$/;
    $curdir = $1;
    # check existence of source path
    unless ((-l "$fsp") || (-e "$fsp")) {
      if ($g_form{'selected'}) {
        # remove the sourcepath from the selected list
        delete($sourcepaths{$sourcepath});
        next;  # next in foreach loop
      }
      else {
        filemanagerResourceNotFound("filemanagerCheckRenameFileTarget verifying existence of \"$vsp\"");
      }
    }
    # can't rename the home directory
    if ((!$vsp) || ($vsp eq "/")) {
      if ($g_form{'selected'}) {
        # remove the sourcepath from the selected list
        delete($sourcepaths{$sourcepath});
        next;  # next in foreach loop
      }
      else {
        $FILEMANAGER_ACTIONS_RENAME =~ s/__TYPE__//g;
        $FILEMANAGER_PERMISSION_DENIED =~ s/__PATH__/\//g;
        filemanagerUserError($FILEMANAGER_ACTIONS_RENAME, 
                             $FILEMANAGER_PERMISSION_DENIED);
      }
    }
    # build full target path
    ($ftp, $vtp) = filemanagerGetFullPath($g_form{'targetpath'}, $fsp);
    # actions that aren't allowed
    if ($fsp eq $ftp) {
      # source and target are identical... oops!
      if ($g_form{'selected'}) {
        # remove the sourcepath from the selected list
        delete($sourcepaths{$sourcepath});
        next;  # next in foreach loop
      }
      else {
        $filetype = filemanagerGetFileType($fsp);
        $FILEMANAGER_ACTIONS_RENAME =~ s/__TYPE__/$filetype/g;
        $FILEMANAGER_SOURCE_TARGET_IDENTICAL_ERROR =~ s/__SOURCE__/$vsp/;
        $FILEMANAGER_SOURCE_TARGET_IDENTICAL_ERROR =~ s/__TARGET__/$vtp/;
        filemanagerUserError($FILEMANAGER_ACTIONS_RENAME, 
                             $FILEMANAGER_SOURCE_TARGET_IDENTICAL_ERROR);
      }
    }
    if ($g_form{'selected'}) {
      # multiple source files are selected
      if ((-e "$ftp") && (-f "$ftp")) {
        # target exists, target is a plain file... it doesn't make any 
        # sense to move multiple files onto a single source file that 
        # isn't a directory
        $FILEMANAGER_MULTIPLE_SOURCE_NO_CLOBBER_ERROR =~ s/__TARGET__/$vtp/;
        filemanagerUserError($FILEMANAGER_MOVE_TAGGED,
                             $FILEMANAGER_MULTIPLE_MOVE_NO_CLOBBER_ERROR);
      }
    }
    else {
      # single file selected
      if ((-e "$ftp") && ((-f "$ftp") || (-l "$ftp")) && (-d "$fsp")) {
        # target exists, target is a plain file (or a symlink), source 
        # is a directory...  not allowed to clobber an existing file 
        # with a directory
        $FILEMANAGER_ACTIONS_RENAME =~ s/__TYPE__/$FILEMANAGER_TYPE_DIRECTORY/g;
        $FILEMANAGER_NO_CLOBBER_ERROR =~ s/__SOURCE__/$vsp/;
        $FILEMANAGER_NO_CLOBBER_ERROR =~ s/__TARGET__/$vtp/;
        filemanagerUserError($FILEMANAGER_ACTIONS_RENAME, 
                             $FILEMANAGER_NO_CLOBBER_ERROR);
      }
    }
    # check the specified path to see if a subcomponent exists as a file
    @subpaths = split(/\//, $vtp);
    $testpath = $g_users{$g_auth{'login'}}->{'path'};
    for ($index=0; $index<$#subpaths; $index++) {
      next unless ($subpaths[$index]);
      $testpath .= "/$subpaths[$index]";
      $testpath =~ s/\/\//\//g;
      if ((-e "$testpath") && (-f "$testpath")) {
        $FILEMANAGER_FILE_IN_TARGET_PATH_ERROR =~ s/__TARGET__/$vtp/;
        $FILEMANAGER_FILE_IN_TARGET_PATH_ERROR =~ s/__SUBPATH__/$testpath/; 
        if ($g_form{'selected'}) {
          filemanagerUserError($FILEMANAGER_MOVE_TAGGED,
                               $FILEMANAGER_FILE_IN_TARGET_PATH_ERROR);
        }
        else {
          $FILEMANAGER_ACTIONS_RENAME =~ s/__TYPE__/$filetype/g;
          filemanagerUserError($FILEMANAGER_ACTIONS_RENAME,
                               $FILEMANAGER_FILE_IN_TARGET_PATH_ERROR);
        }
      }
    }
  }

  if ($g_form{'selected'}) {
    # if mulitple files selected, rebuild selected list since some of
    # entries may have been deleted
    $testpath = (split(/\|\|\|/, $g_form{'selected'}))[0];
    $testpath =~ s/\/+$//g;
    $testpath =~ s/[^\/]+$//g;
    $testpath =~ s/\/+$//g;
    $g_form{'selected'} = "";
    foreach $sourcepath (keys(%sourcepaths)) {
      $g_form{'selected'} .= "|||" if ($g_form{'selected'});
      $g_form{'selected'} .= $sourcepath;
    }
    unless ($g_form{'selected'}) {
      # oops... no valid source file(s) found
      $g_form{'path'} = $testpath;
      redirectLocation("filemanager.cgi", $FILEMANAGER_NO_SOURCE_VALID);
    }
  }

  # need a confirmation for a couple of things
  unless ($g_form{'confirm'} && ($g_form{'confirm'} eq "yes")) {
    foreach $sourcepath (keys(%sourcepaths)) {
      # build full source path
      ($fsp, $vsp) = filemanagerGetFullPath($sourcepath);
      # build full target path
      ($ftp, $vtp) = filemanagerGetFullPath($g_form{'targetpath'}, $fsp);
      # confirm if overwriting an existing file
      if ($g_prefs{'ftp__confirm_file_overwrite'} eq "yes") {
        if (((-f "$fsp") || (-l "$fsp")) && (-d "$ftp")) {
          # source is an existing file, target is a directory
          # append filename to target directory
          $fsp =~ /([^\/]+$)/;
          $filename = $1;
          $ftp .= "/$filename";
          # now the next conditional will work properly
        }
        if ((-e "$ftp") && ((-f "$ftp") || (-l "$ftp")) && (-f "$fsp")) {
          # target exists, target is a plain file, source is a plain file
          filemanagerRenameFileForm("CONFIRM_OVERWRITE");
        }
      }
      # confirm the creation of new directories
      if ($g_prefs{'ftp__confirm_dir_create'} eq "yes") {
        $testpath = $g_users{$g_auth{'login'}}->{'path'};
        @subpaths = split(/\//, $vtp);
        $mi = ($g_form{'selected'}) ? ($#subpaths+1) : $#subpaths;
        for ($index=0; $index<$mi; $index++) {
          next unless ($subpaths[$index]);
          $testpath .= "/$subpaths[$index]";
          $testpath =~ s/\/\//\//g;
          unless (-e "$testpath") {
            filemanagerRenameFileForm("CONFIRM_CREATEDIR");
          }
        }
      }
      # we actually only need to check the first sourcepath, since the
      # checks (and corresponding confirmations) are on the target path
      last;
    }
  }
}

##############################################################################

sub filemanagerRenameFileForm
{
  local($mesg) = @_;
  local($fullpath, $virtualpath, $displaypath);
  local($filetype, $lcfiletype, @subpaths, $filename, $title);
  local($helptext, $index, $size, $errortext);

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
    $title .= $FILEMANAGER_ACTIONS_RENAME_MULTIPLE;
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
      filemanagerResourceNotFound("filemanagerRenameFileForm
        verifying existence of \"$virtualpath\"");
    }
    if ((!$virtualpath) || ($virtualpath eq "/")) {
      $FILEMANAGER_ACTIONS_RENAME =~ s/__TYPE__//g;
      $FILEMANAGER_PERMISSION_DENIED =~ s/__PATH__/\//g;
      filemanagerUserError($FILEMANAGER_ACTIONS_RENAME, 
                           $FILEMANAGER_PERMISSION_DENIED);
    }
    @subpaths = split(/\//, $virtualpath);
    $filename = $subpaths[$#subpaths];
    $filetype = filemanagerGetFileType($fullpath);
    $FILEMANAGER_ACTIONS_RENAME =~ s/__TYPE__/$filetype/g;
    $FILEMANAGER_ACTIONS_RENAME_SOURCE =~ s/__TYPE__/$filetype/g;
    $FILEMANAGER_ACTIONS_RENAME_TARGET =~ s/__TYPE__/$filetype/g;
    $FILEMANAGER_ACTIONS_RENAME_SUBMIT =~ s/__TYPE__/$filetype/g;
    $title = $FILEMANAGER_TITLE;
    $title =~ s/__FILE__/$displaypath/g;
    $title .= " : $FILEMANAGER_ACTIONS_RENAME";
  }

  if (!$mesg || ($mesg eq "EMPTY_FIELD")) {
    if ($g_form{'selected'}) {
      $helptext = $FILEMANAGER_ACTIONS_RENAME_MULTIPLE_TEXT;
    }
    else {
      $helptext = $FILEMANAGER_ACTIONS_RENAME_TEXT;
      $lcfiletype = $filetype;
      $lcfiletype =~ tr/A-Z/a-z/;
      $helptext =~ s/__LCTYPE__/$lcfiletype/g;
      $helptext =~ s/__TYPE__/$filetype/g;
      $helptext =~ s/__FILE__/$filename/g;
    }
  }
  elsif ($mesg eq "CONFIRM_OVERWRITE") {
    $helptext = $FILEMANAGER_ACTIONS_RENAME_CONFIRM_OVERWRITE_TEXT;
    $helptext =~ s/__TYPE__/$filetype/g;
    $helptext =~ s/__FILE__/$g_form{'targetpath'}/g;
  }
  elsif ($mesg eq "CONFIRM_CREATEDIR") {
    $helptext = $FILEMANAGER_ACTIONS_RENAME_CONFIRM_CREATEDIR_TEXT;
    $helptext =~ s/__TYPE__/$filetype/g;
    $helptext =~ s/__FILE__/$g_form{'targetpath'}/g;
  }

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  if ($mesg && ($mesg eq "EMPTY_FIELD")) {
    $errortext = $FILEMANAGER_EMPTY_FIELD_ERROR;
    $errortext =~ s/__NAME__/$FILEMANAGER_ACTIONS_RENAME_TARGET/;
    htmlTextColorBold(">>> $errortext <<<", "#cc0000");
    htmlP();
  }       
  htmlText($helptext);
  htmlP();
  htmlUL();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "action", "value", "submit");
  if ($g_form{'selected'}) {
    formInput("type", "hidden", "name", "selected",
              "value", $g_form{'selected'});
  }
  else {
    formInput("type", "hidden", "name", "path", "value", $virtualpath);
  }
  if (!$mesg || ($mesg eq "EMPTY_FIELD")) {
    if ($g_form{'selected'}) {
      htmlTextBold("$FILEMANAGER_ACTIONS_RENAME_MULTIPLE_SOURCE:");
      htmlBR();
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
      htmlTextBold("$FILEMANAGER_ACTIONS_RENAME_TARGET_DIRECTORY:");
      htmlBR();
    }
    else {
      htmlTextBold("$FILEMANAGER_ACTIONS_RENAME_SOURCE: &#160;");
      htmlText($virtualpath);
      htmlP();
      htmlTextBold("$FILEMANAGER_ACTIONS_RENAME_TARGET:");
      htmlBR();
    }
    # build a default value for targetpath (if applicable)
    unless ($g_form{'targetpath'}) {
      if ($g_form{'selected'}) {
        # selected is populated from above
        ($fullpath, $virtualpath) = split(/\|\|\|/, $selected[0]);
        @subpaths = split(/\//, $virtualpath);
        $filename = $FILEMANAGER_ACTIONS_CREATEDIR_NEW_TEXT;
        for ($index=0; $index<$#subpaths; $index++) {
          next unless ($subpaths[$index]);
          $g_form{'targetpath'} .= "/$subpaths[$index]";
        }
        $g_form{'targetpath'} .= "/" . $filename;
      }
      else {
        # virtualpath is populated from above
        @subpaths = split(/\//, $virtualpath);
        $filename = $subpaths[$#subpaths];
        for ($index=0; $index<$#subpaths; $index++) {
          next unless ($subpaths[$index]);
          $g_form{'targetpath'} .= "/$subpaths[$index]";
        }
        $g_form{'targetpath'} .= "/" . $FILEMANAGER_ACTIONS_RENAME_NEW_TEXT;
        if ((!$filename) || ($filename eq "/")) {  
          # handle special case of copying home directory
          $g_form{'targetpath'} .= "_" . $FILEMANAGER_HOMEDIR;
        } 
        else {
          $g_form{'targetpath'} .= "_" . $filename;
        }
      }
    }
    $size = sprintf "%d", length($g_form{'targetpath'}) / 5;
    $size++;  $size *= 5;
    $size = 40 if ($size < 40);
    $size = 60 if ($size > 60);
    formInput("size", $size, "name", "targetpath", 
              "value", $g_form{'targetpath'});
    htmlP();
    if ($g_form{'selected'}) {
      formInput("type", "submit", "name", "submit",
                "value", $FILEMANAGER_ACTIONS_RENAME_MULTIPLE_SUBMIT);
    }
    else {
      $FILEMANAGER_ACTIONS_RENAME_SUBMIT =~ s/__TYPE__/$filetype/g;
      formInput("type", "submit", "name", "submit", 
                "value", $FILEMANAGER_ACTIONS_RENAME_SUBMIT);
    }
  }
  else {
    formInput("type", "hidden", "name", "confirm", "value", "yes");
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
  if (!$mesg || ($mesg eq "EMPTY_FIELD")) {
    formInput("type", "reset", "value", $RESET_STRING);
  }
  formInput("type", "submit", "name", "submit", 
            "value", $FILEMANAGER_ACTIONS_RENAME_CANCEL);
  formClose();
  htmlULClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub filemanagerRenameSourceFileToTargetFile
{
  local($fsp, $ftp) = @_;
  local($ftpd, $errortxt, $virtualpath, $homedir);

  $errortxt = "";

  # kill the target if it is a file (or symlink) and it exists already
  unlink($ftp) if ((-e "$ftp") && ((-f "$ftp") || (-l "$ftp")));

  # if the target is an existing directory, rewrite the target so that
  # the perl rename() command doesn't clobber the directory.  this more
  # closely mimics the behavior of the unix mv() command which is what 
  # I think people would expect (I could be wrong)
  #  ... or ...
  # if multiple files selected then append the source filename to the 
  # target directory name
  if (((-e "$ftp") && (-d "$ftp")) || $g_form{'selected'}) {
    # make sure we don't have any trailing slashes
    $fsp =~ s/\/$//;
    # get the source name (everything after last '/')
    $fsp =~ /([^\/]+$)/; 
    # and append
    $ftp .= "/$1";
    $ftp =~ s/\/\//\//g;
  }

  # create any directories necessary to fulfill the request
  $ftpd = $ftp;  # i know i know... these are stupid variable names
  $ftpd =~ s/\/$//;
  $ftpd =~ s/[^\/]+$//g;
  filemanagerCreateDirectory($ftpd);

  # rename (move) the file
  unless (rename($fsp, $ftp)) {
    $virtualpath = $fsp;
    $virtualpath =~ s/^$homedir// if ($homedir ne "/");
    $errortxt = "rename('$virtualpath', ";
    $virtualpath = $ftp;
    $virtualpath =~ s/^$homedir// if ($homedir ne "/");
    $errortxt .= "'$virtualpath'): $!\n";
  }

  return($errortxt);
}

##############################################################################

sub filemanagerRenameSourceToTarget
{
  local($fsp, $vsp, $ftp, $vtp, $etxt);
  local($filetype, %sourcepaths, $sourcepath);

  encodingIncludeStringLibrary("filemanager");

  # is one or more file selected?
  if ((!$g_form{'path'}) && ($g_form{'selected'}) &&
      ($g_form{'selected'} !~ /\|\|\|/)) {
    $g_form{'path'} = $g_form{'selected'};
    $g_form{'selected'} = "";
  }

  if ($g_form{'path'}) {
    $sourcepaths{$g_form{'path'}} = "dau!";
  }
  else {
    @subpaths = split(/\|\|\|/, $g_form{'selected'});
    foreach $sourcepath (@subpaths) {
      $sourcepaths{$sourcepath} = "dau!";
    }
  }

  foreach $sourcepath (keys(%sourcepaths)) {
    # build full source path
    ($fsp, $vsp) = filemanagerGetFullPath($sourcepath);
    # can't rename the home directory
    if ((!$vsp) || ($vsp eq "/")) {
      if ($g_form{'selected'}) {
        next;
      }
      else {
        $FILEMANAGER_ACTIONS_RENAME =~ s/__TYPE__//g;
        $FILEMANAGER_PERMISSION_DENIED =~ s/__PATH__/\//g;
        filemanagerUserError($FILEMANAGER_ACTIONS_RENAME, 
                             $FILEMANAGER_PERMISSION_DENIED);
      }
    }
    # build full target path
    ($ftp, $vtp) = filemanagerGetFullPath($g_form{'targetpath'}, $fsp);
    # rename (move) the source file to the specified target
    $etxt .= filemanagerRenameSourceFileToTargetFile($fsp, $ftp);
  }

  if ($etxt) {
    # errors encountered during action
    redirectLocation("filemanager.cgi", $etxt);
  }
  else {
    # set a new form path value and show happy results
    $g_form{'path'} = $vtp;
    if ($g_form{'selected'}) {
      # multiple file copy success message
      redirectLocation("filemanager.cgi",
                       $FILEMANAGER_ACTIONS_RENAME_MULITPLE_SUCCESS_TEXT);
    }
    else {
      $filetype = filemanagerGetFileType($fsp);
      $FILEMANAGER_ACTIONS_RENAME =~ s/__TYPE__/$filetype/g;
      $FILEMANAGER_ACTIONS_RENAME_SUCCESS_TEXT =~ s/__TYPE__/$filetype/g;
      $FILEMANAGER_ACTIONS_RENAME_SUCCESS_TEXT =~ s/\n/\ /g;
      redirectLocation("filemanager.cgi",
                       $FILEMANAGER_ACTIONS_RENAME_SUCCESS_TEXT);
    }
  }
}

##############################################################################
# eof

1;

