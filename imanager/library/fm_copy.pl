#
# fm_copy.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/fm_copy.pl,v 2.12.2.4 2006/04/25 19:48:23 rus Exp $
#
# file manager copy functions
#

##############################################################################

sub filemanagerCheckCopyFileTarget
{
  local($fsp, $vsp, $ftp, $vtp);
  local(@subpaths, $index, $testpath, $filetype, $filename);
  local(%sourcepaths, $sourcepath, $curdir);

  encodingIncludeStringLibrary("filemanager");
  if ($g_form{'submit'} eq "$FILEMANAGER_ACTIONS_COPY_CANCEL") {
    if ($g_form{'selected'}) {
      # need to set 'path' to 'selected' for the redirect
      $g_form{'path'} = (split(/\|\|\|/, $g_form{'selected'}))[0];
      $g_form{'path'} =~ s/\/+$//g;
      $g_form{'path'} =~ s/[^\/]+$//g;
      $g_form{'path'} =~ s/\/+$//g;
    }
    redirectLocation("filemanager.cgi", 
                     $FILEMANAGER_ACTIONS_COPY_CANCEL_TEXT);
  }

  unless ($g_form{'targetpath'}) {
    # uh... damnit beavis
    filemanagerCopyFileForm("EMPTY_FIELD");
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
        # single file is selected... 
        filemanagerResourceNotFound("filemanagerCheckCopyFileTarget verifying existence of \"$vsp\"");
      }
    }
    # build full target path
    ($ftp, $vtp) = filemanagerGetFullPath($g_form{'targetpath'}, $fsp);
    if (((!$g_form{'selected'}) && (-e "$ftp") && (-d "$ftp") && 
         (-d "$fsp") && ($ftp !~ /$curdir$/)) ||
        ($g_form{'selected'} && ($ftp !~ /$curdir$/))) {
      # the target is an existing directory... the source is a directory.
      # the target, however, does not end in the "current directory" of
      # the source (i.e. the last subpath of the source directory).  so,
      # we will presume that the user wants to copy the entire directory
      # including the directory name to the new target... therefore, 
      # append the "current directory" to the target path specification
      $ftp .= "/$curdir";
      $vtp .= "/$curdir";
    }
    # actions that aren't allowed 
    if ($fsp eq $ftp) {
      # source == target.  bu sying!
      if ($g_form{'selected'}) {
        # remove the sourcepath from the selected list
        delete($sourcepaths{$sourcepath});
        next;  # next in foreach loop
      }
      else {
        # source and target are identical... oops!
        $filetype = filemanagerGetFileType($fsp);
        $FILEMANAGER_ACTIONS_COPY =~ s/__TYPE__/$filetype/g;
        $FILEMANAGER_SOURCE_TARGET_IDENTICAL_ERROR =~ s/__SOURCE__/$vsp/;
        $FILEMANAGER_SOURCE_TARGET_IDENTICAL_ERROR =~ s/__TARGET__/$vtp/;
        filemanagerUserError($FILEMANAGER_ACTIONS_COPY, 
                             $FILEMANAGER_SOURCE_TARGET_IDENTICAL_ERROR);
      }
    }
    if ($g_form{'selected'}) {
      # multiple source files are selected
      if ((-e "$ftp") && (-f "$ftp")) {
        # target exists, target is a plain file; it doesn't make any
        # sense to copy multiple files onto a single target file that
        # isn't a directory
        $FILEMANAGER_MULTIPLE_SOURCE_NO_CLOBBER_ERROR =~ s/__TARGET__/$vtp/;
        filemanagerUserError($FILEMANAGER_COPY_TAGGED, 
                             $FILEMANAGER_MULTIPLE_COPY_NO_CLOBBER_ERROR);
      }
    }
    else {
      # only one file is selected
      if ((-e "$ftp") && (-f "$ftp") && (-d "$fsp")) {
        # target exists, target is a plain file, source is a directory;
        # not allowed to clobber an existing file with a directory
        $FILEMANAGER_ACTIONS_COPY =~ s/__TYPE__/$FILEMANAGER_TYPE_DIRECTORY/g;
        $FILEMANAGER_NO_CLOBBER_ERROR =~ s/__SOURCE__/$vsp/;
        $FILEMANAGER_NO_CLOBBER_ERROR =~ s/__TARGET__/$vtp/;
        filemanagerUserError($FILEMANAGER_ACTIONS_COPY, 
                             $FILEMANAGER_NO_CLOBBER_ERROR);
      }
    }
    # check the specified target to see if a subcomponent exists as a file
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
          filemanagerUserError($FILEMANAGER_COPY_TAGGED, 
                               $FILEMANAGER_FILE_IN_TARGET_PATH_ERROR);
        }
        else {
          $filetype = filemanagerGetFileType($fsp);
          $FILEMANAGER_ACTIONS_COPY =~ s/__TYPE__/$filetype/g;
          filemanagerUserError($FILEMANAGER_ACTIONS_COPY, 
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
          filemanagerCopyFileForm("CONFIRM_OVERWRITE");
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
            filemanagerCopyFileForm("CONFIRM_CREATEDIR");
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

sub filemanagerCopyFileForm
{
  local($mesg) = @_;
  local($fullpath, $virtualpath, $displaypath);
  local($filetype, @subpaths, $filename, $title);
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
    $title .= $FILEMANAGER_ACTIONS_COPY_MULTIPLE;
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
      filemanagerResourceNotFound("filemanagerCopyFileForm
        verifying existence of \"$virtualpath\"");
    }
    @subpaths = split(/\//, $virtualpath);
    $filename = $subpaths[$#subpaths];
    $filetype = filemanagerGetFileType($fullpath);
    $FILEMANAGER_ACTIONS_COPY =~ s/__TYPE__/$filetype/g;
    $FILEMANAGER_ACTIONS_COPY_SOURCE =~ s/__TYPE__/$filetype/g;
    $FILEMANAGER_ACTIONS_COPY_SUBMIT =~ s/__TYPE__/$filetype/g;
    $title = $FILEMANAGER_TITLE;
    $title =~ s/__FILE__/$displaypath/g;
    $title .= " : $FILEMANAGER_ACTIONS_COPY";

  }

  if (!$mesg || ($mesg eq "EMPTY_FIELD")) {
    if ($g_form{'selected'}) {
      $helptext = $FILEMANAGER_ACTIONS_COPY_MULTIPLE_TEXT;
    }
    else {
      if ($filetype eq $FILEMANAGER_TYPE_DIRECTORY) {
        $helptext = $FILEMANAGER_ACTIONS_COPY_TEXT_DIRECTORY;
      }
      else {
        $helptext = $FILEMANAGER_ACTIONS_COPY_TEXT_FILE;
      }
      $helptext =~ s/__FILE__/$filename/g;
    }
  }
  elsif ($mesg eq "CONFIRM_OVERWRITE") {
    $helptext = $FILEMANAGER_ACTIONS_COPY_CONFIRM_OVERWRITE_TEXT;
    $helptext =~ s/__FILE__/$g_form{'targetpath'}/g;
  }
  elsif ($mesg eq "CONFIRM_CREATEDIR") {
    $helptext = $FILEMANAGER_ACTIONS_COPY_CONFIRM_CREATEDIR_TEXT;
    $helptext =~ s/__FILE__/$g_form{'targetpath'}/g;
  }

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($title);
  if ($mesg && ($mesg eq "EMPTY_FIELD")) {
    $errortext = $FILEMANAGER_EMPTY_FIELD_ERROR;
    $errortext =~ s/__NAME__/$FILEMANAGER_ACTIONS_COPY_TARGET/;
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
      htmlTextBold("$FILEMANAGER_ACTIONS_COPY_MULTIPLE_SOURCE:");
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
      htmlTextBold("$FILEMANAGER_ACTIONS_COPY_TARGET_DIRECTORY:");
      htmlBR();
    }
    else {
      htmlTextBold("$FILEMANAGER_ACTIONS_COPY_SOURCE: &#160;");
      htmlText($virtualpath);
      htmlP();
      htmlTextBold("$FILEMANAGER_ACTIONS_COPY_TARGET:");
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
        $g_form{'targetpath'} .= "/" . $FILEMANAGER_ACTIONS_COPY_OF_TEXT;
        if ((!$filename) || ($filename eq "/")) {
          # handle special case of copying home directory
          $g_form{'targetpath'} .= "_" . $FILEMANAGER_HOMEDIR;
        }
        else {
          $g_form{'targetpath'} .= "_" . $filename;
        }
      }
    }
    # make a guess as what the size should be for the targetpath input field
    $size = sprintf "%d", length($g_form{'targetpath'}) / 5;
    $size++;  $size *= 5;
    $size = 40 if ($size < 40);
    $size = 60 if ($size > 60);
    # target input field
    formInput("size", $size, "name", "targetpath", 
              "value", $g_form{'targetpath'});
    htmlP();
    if ($g_form{'selected'}) {
      formInput("type", "submit", "name", "submit", 
                "value", $FILEMANAGER_ACTIONS_COPY_MULTIPLE_SUBMIT);
    }
    else {
      $FILEMANAGER_ACTIONS_COPY_SUBMIT =~ s/__TYPE__/$filetype/g;
      formInput("type", "submit", "name", "submit", 
                "value", $FILEMANAGER_ACTIONS_COPY_SUBMIT);
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
            "value", $FILEMANAGER_ACTIONS_COPY_CANCEL);
  formClose();
  htmlULClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub filemanagerCopySourceDirtoTargetDir
{
  local($fsp, $ftp, $oftp) = @_;
  local($filename, $nfsp, $nftp);
  local($errortxt, $virtualpath, $homedir);
  local(*CURDIR);

  $errortxt = "";

  # return if source is not a directory 
  return ("") unless (-d "$fsp");
  # aha!  don't let symlinks to directories slip under our nose
  return ("") if (-l "$fsp");

  # create the directory
  filemanagerCreateDirectory($ftp);
  # now copy any files in the source directory
  if (opendir(CURDIR, "$fsp")) {
    foreach $filename (readdir(CURDIR)) {
      next if (($filename eq ".") || ($filename eq ".."));
      $nfsp = "$fsp/$filename";
      $nftp = "$ftp/$filename";
      # don't get caught in a recursive loop
      next if ($nfsp eq $oftp);
      # recurse or copy?
      if (-l "$nfsp") {
        $errortxt .= filemanagerCopySourceLinkToTargetLink($nfsp, $nftp);
      }
      elsif (-d "$nfsp") {
        $errortxt .= filemanagerCopySourceDirtoTargetDir($nfsp, $nftp, $oftp);
      }
      else {
        $errortxt .= filemanagerCopySourceFileToTargetFile($nfsp, $nftp);
      }
    }
    closedir(CURDIR);
  }
  else {
    $homedir = $g_users{$g_auth{'login'}}->{'home'};
    $virtualpath = $fsp;
    $virtualpath =~ s/^$homedir// if ($homedir ne "/");
    $errortxt = "opendir('$virtualpath'): $!\n";
  }

  return($errortxt);
}

##############################################################################

sub filemanagerCopySourceFileToTargetFile
{
  local($fsp, $ftp) = @_;
  local($fsize, $used, $ftpd);
  local($errortext, $homedir, $virtualpath);

  $errortxt = "";

  # return if source is a directory
  return("") if (-d "$fsp");

  # if target is directory, append filename
  if (-d "$ftp") {
    # make sure we don't have any trailing slashes
    $fsp =~ s/\/$//;
    # get the source name (everything after last '/')
    $fsp =~ /([^\/]+$)/;
    # and append
    $ftp .= "/$1";
    $ftp =~ s/\/\//\//g;
  }

  # kill the target if it exists already; do this here before a 
  # quota calcuation is made to properly consider disk space use
  unlink($ftp) if (-e "$ftp");

  # figure out if there is enough room to copy the file
  if ($g_users{$g_auth{'login'}}->{'ftpquota'}) {
    # get the size of the source file
    ($fsize) = (stat($fsp))[7];
    # get current disk usage
    $used = filemanagerGetQuotaUsage();
    if (($fsize + $used) > 
        ($g_users{$g_auth{'login'}}->{'ftpquota'} * 1048576)) {
      # user doesn't have enough room
      if ($g_form{'selected'}) {
        $homedir = $g_users{$g_auth{'login'}}->{'home'};
        $virtualpath = $fsp;
        $virtualpath =~ s/^$homedir// if ($homedir ne "/");
        $errortext = "copy('$virtualpath', ";
        $virtualpath = $ftp;
        $virtualpath =~ s/^$homedir// if ($homedir ne "/");
        $errortxt .= "'$virtualpath'): quota exceeded\n";
        return($errortxt);
      }
      else {
        $FILEMANAGER_ACTIONS_COPY_QUOTA_ERROR =~ s/__SOURCE__/$fsp/g;
        $FILEMANAGER_ACTIONS_COPY_QUOTA_ERROR =~ s/__TARGET__/$ftp/g;
        filemanagerUserError($FILEMANAGER_ACTIONS_COPY, 
                             $FILEMANAGER_ACTIONS_COPY_QUOTA_ERROR);
      }
    }
  }

  # create any directories necessary to fulfill the request
  $ftpd = $ftp;  # i know i know... these are stupid variable names
  $ftpd =~ s/\/$//;
  $ftpd =~ s/[^\/]+$//g;
  filemanagerCreateDirectory($ftpd);

  if (open(TFP, ">$ftp")) {
    if ($fsp eq "/dev/null") {
      # special case: source is /dev/null... do nothing
    }
    else {
      # copy the file
      if (open(SFP, "$fsp")) {
        while (read(SFP, $curchar, 1024)) {
          print TFP "$curchar";
        }
        close(SFP);
      }
      else {
        $homedir = $g_users{$g_auth{'login'}}->{'home'};
        $virtualpath = $fsp;
        $virtualpath =~ s/^$homedir// if ($homedir ne "/");
        $errortxt = "read('$virtualpath'): $!\n";
      }
    }
    close(TFP);
  }
  else {
    $homedir = $g_users{$g_auth{'login'}}->{'home'};
    $virtualpath = $ftp;
    $virtualpath =~ s/^$homedir// if ($homedir ne "/");
    $errortxt = "write('$virtualpath'): $!\n";
  }

  return($errortxt);
}

##############################################################################

sub filemanagerCopySourceLinkToTargetLink
{
  local($fsp, $ftp) = @_;
  local($target, $errortext, $virtualpath, $homedir);

  $errortxt = "";

  # get target from source
  $target = readlink($fsp);

  unless (symlink($target, $ftp)) {
    $virtualpath = $target;
    $virtualpath =~ s/^$homedir// if ($homedir ne "/");
    $errortxt = "symlink('$virtualpath', ";
    $virtualpath = $ftp;
    $virtualpath =~ s/^$homedir// if ($homedir ne "/");
    $errortxt .= "'$virtualpath'): $!\n";
  }

  return($errortxt);
}

##############################################################################

sub filemanagerCopySourceToTarget
{
  local($fsp, $vsp, $ftp, $vtp, $etxt, $ovtp);
  local($filetype, %sourcepaths, $sourcepath, $curdir);

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
    $fsp =~ /([^\/]+)$/;
    $curdir = $1;
    # build full target path
    ($ftp, $vtp) = filemanagerGetFullPath($g_form{'targetpath'}, $fsp);
    $ovtp = $vtp;
    if (((!$g_form{'selected'}) && (-e "$ftp") && (-d "$ftp") && 
         (-d "$fsp") && ($ftp !~ /$curdir$/)) ||
        (($g_form{'selected'}) && ($ftp !~ /$curdir$/))) {
      # the target is an existing directory... the source is a directory.
      # the target, however, does not end in the "current directory" of
      # the source (i.e. the last subpath of the source directory).  so,
      # we will presume that the user wants to copy the entire directory
      # including the directory name to the new target... therefore, 
      # append the "current directory" to the target path specification
      $ftp .= "/$curdir";
      $vtp .= "/$curdir";
    }
    # copy the source file to the specified target
    if (-l "$fsp") {
      # copy a source symlink to target
      $etxt .= filemanagerCopySourceLinkToTargetLink($fsp, $ftp);
    }
    elsif (-d "$fsp") {
      # recursively copy a source directory to target
      $etxt .= filemanagerCopySourceDirtoTargetDir($fsp, $ftp, $ftp);
    }
    else {
      # copy a source file to target
      $etxt .= filemanagerCopySourceFileToTargetFile($fsp, $ftp);
    }
  }

  if ($etxt) {
    # errors encountered during action
    redirectLocation("filemanager.cgi", $etxt);
  }
  else {
    # set a new form path value and show happy results
    $g_form{'path'} = $ovtp;
    if ($g_form{'selected'}) {
      # multiple file copy success message
      redirectLocation("filemanager.cgi", 
                       $FILEMANAGER_ACTIONS_COPY_MULITPLE_SUCCESS_TEXT);
    }
    else {
      $filetype = filemanagerGetFileType($fsp);
      $FILEMANAGER_ACTIONS_COPY =~ s/__TYPE__/$filetype/g;
      $FILEMANAGER_ACTIONS_COPY_SUCCESS_TEXT =~ s/__TYPE__/$filetype/g;
      $filetype =~ tr/A-Z/a-z/;
      $FILEMANAGER_ACTIONS_COPY_SUCCESS_TEXT =~ s/__LCTYPE__/$filetype/g;
      $FILEMANAGER_ACTIONS_COPY_SUCCESS_TEXT =~ s/\n/\ /g;
      redirectLocation("filemanager.cgi", 
                       $FILEMANAGER_ACTIONS_COPY_SUCCESS_TEXT);
    }
  }
}

##############################################################################
# eof

1;

