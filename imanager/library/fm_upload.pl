#
# fm_upload.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/fm_upload.pl,v 2.12.2.8 2006/04/25 19:48:23 rus Exp $
#
# file manager upload file functions
#

##############################################################################

sub filemanagerCheckUploadFileFormData
{
  local($fsp, $vsp, $ftp, $vtp, @ftps, @vtps);
  local(@subpaths, $index, $sindex, $testpath, $fsize, $homedir);
  local($filepath, $filetext, $filename, @pids);
  local(@cow_indices, @ccd_indices);
  local($sessionid, $tmpfilename, @pids, $index, $key);

  # build full source path
  ($fsp, $vsp) = filemanagerGetFullPath($g_form{'path'});

  unless (-e "$fsp") {
    filemanagerResourceNotFound("filemanagerCheckUploadFileFormData
      verifying existence of \"$vsp\"");
  }

  encodingIncludeStringLibrary("filemanager");

  if ($g_form{'submit'} eq "$FILEMANAGER_ACTIONS_UPLOADFILE_CANCEL") {
    # first do some clean up
    $sessionid = initUploadCookieGetSessionID();
    if ($sessionid) {
      if ($g_platform_type eq "virtual") {
        $tmpfilename = $g_tmpdir . "/.upload-" . $sessionid . "-pid";
        if (open(PIDFP, "$tmpfilename")) {
          while (<PIDFP>) {
            chomp;
            push(@pids, $_);
          }
          close(PIDFP);
          kill('TERM', @pids);
        }
        unlink($tmpfilename);
        # remove temporary files
        for ($index=1; $index<=$g_prefs{'ftp__upload_file_elements'}; $index++) {
          $key = "fileupload$index";
          $tmpfilename = $g_tmpdir . "/.upload-" . $sessionid . "-" . $key;
        }
        unlink($tmpfilename);
      }
      else {
        HOUSEKEEPING: {
          local $> = 0;
          $tmpfilename = $g_maintmpdir . "/.upload-" . $sessionid . "-pid";
          if (open(PIDFP, "$tmpfilename")) {
            while (<PIDFP>) {
              chomp;
              push(@pids, $_);
            }
            close(PIDFP);
            kill('TERM', @pids);
          }
          unlink($tmpfilename);
          # remove temporary files
          for ($index=1; $index<=$g_prefs{'ftp__upload_file_elements'}; $index++) {
            $key = "fileupload$index";
            $tmpfilename = $g_maintmpdir . "/.upload-" . $sessionid . "-" . $key;
            unlink($tmpfilename);
          }
        }
      }
      filemanagerTemporaryUploadFileRemove($sessionid);
    }
    # cleaning done... redirect
    redirectLocation("filemanager.cgi",
                     $FILEMANAGER_ACTIONS_UPLOADFILE_CANCEL_UPLOAD_TEXT);
  }

  if (($g_form{'submit'} eq "$FILEMANAGER_CONFIRM_OVERWRITE") ||
      ($g_form{'submit'} eq "$FILEMANAGER_CONFIRM_CREATEDIR")) {
    # read in the uploaded files from temporary location
    $sessionid = initUploadCookieGetSessionID();
    filemanagerTemporaryUploadFileRead($sessionid);
  }

  # build full target paths
  $fsize = 0;
  for ($index=1; $index<=$g_prefs{'ftp__upload_file_elements'}; $index++) {
    $key = "fileupload$index";
    $filepath = $g_form{$key}->{'targetpath'} || 
                $g_form{$key}->{'sourcepath'};
    next unless ($filepath);
    $fsize += (stat($g_form{$key}->{'content-filename'}))[7];
    ($ftp, $vtp) = filemanagerGetFullPath($filepath, $fsp);
    $ftps[$index] = $ftp;
    $vtps[$index] = $vtp;
    # actions that aren't allowed
    # check the specified path to see if a subcomponent exists as a file
    @subpaths = split(/\//, $vtp);
    $testpath = $g_users{$g_auth{'login'}}->{'path'};
    for ($sindex=0; $sindex<$#subpaths; $sindex++) {
      next unless ($subpaths[$sindex]);
      $testpath .= "/$subpaths[$sindex]";
      $testpath =~ s/\/\//\//g;
      if ((-e "$testpath") && (-f "$testpath")) {
        $filetext = "$vtp ($FILEMANAGER_TYPE_FILE&#160;$index\)";
        $FILEMANAGER_FILE_IN_TARGET_PATH_ERROR =~ s/__TARGET__/$filetext/;
        $FILEMANAGER_FILE_IN_TARGET_PATH_ERROR =~ s/__SUBPATH__/$testpath/;
        filemanagerUserError($FILEMANAGER_ACTIONS_UPLOADFILE,
                             $FILEMANAGER_FILE_IN_TARGET_PATH_ERROR);
      }
    }
  }

  if ($#ftps == -1) {
    # uh... damnit beavis
    filemanagerUploadFileForm("EMPTY_FIELD");
  }

  # figure out if there is enough room to copy the file
  if ($g_users{$g_auth{'login'}}->{'ftpquota'}) {
    $homedir = $g_users{$g_auth{'login'}}->{'home'};
    $used = filemanagerGetQuotaUsage();
    if (($fsize + $used) > 
        ($g_users{$g_auth{'login'}}->{'ftpquota'} * 1048576)) {
      # user doesn't have enough room
      for ($index=1; $index<=$g_prefs{'ftp__upload_file_elements'}; $index++) {
        $key = "fileupload$index";
        $filepath = $g_form{$key}->{'targetpath'} || 
                    $g_form{$key}->{'sourcepath'};
        next unless ($filepath);
        unlink($g_form{$key}->{'content-filename'});
      }
      $FILEMANAGER_ACTIONS_UPLOADFILE_QUOTA_ERROR =~ s/__NUMBER__/$fsize/g;
      filemanagerUserError($FILEMANAGER_ACTIONS_UPLOADFILE,
                           $FILEMANAGER_ACTIONS_UPLOADFILE_QUOTA_ERROR);
    }
  }

  # need a confirmation for overwriting files
  $g_form{'confirm_file_overwrite'} = "no" unless ($g_form{'confirm_file_overwrite'});
  if ($g_form{'confirm_file_overwrite'} ne "yes") {
    if ($g_prefs{'ftp__confirm_file_overwrite'} eq "yes") {
      for ($index=1; 
           $index<=$g_prefs{'ftp__upload_file_elements'}; $index++) {
        next unless (defined($ftps[$index]));
        $key = "fileupload$index";
        $ftp = $ftps[$index];
        if (-d "$ftp") {
          # target is a directory, append filename to target directory
          $ftp .= "/$g_form{$key}->{'sourcepath'}";
          $vtp .= "/$g_form{$key}->{'sourcepath'}";
          $ftp =~ s/\/\//\//g;
          $vtp =~ s/\/\//\//g;
          $ftps[$index] = $ftp;
          $vtps[$index] = $vtp;
          # now the next conditional will work properly
        }
        if ((-e "$ftp") && ((-f "$ftp") || (-l "$ftp"))) {
          # target exists, target is a plain file
          push(@cow_indices, "$index:$vtps[$index]");
        }
      }
      if ($#cow_indices > -1) {
        filemanagerUploadFileConfirmForm("CONFIRM_OVERWRITE", @cow_indices);
      }
    }
  }

  # confirm the creation of new directories
  $g_form{'confirm_dir_create'} = "no" unless ($g_form{'confirm_dir_create'});
  if ($g_form{'confirm_dir_create'} ne "yes") {
    if ($g_prefs{'ftp__confirm_dir_create'} eq "yes") {
      for ($index=1; 
           $index<=$g_prefs{'ftp__upload_file_elements'}; $index++) {
        next unless (defined($vtps[$index]));
        @subpaths = split(/\//, $vtps[$index]);
        $testpath = $g_users{$g_auth{'login'}}->{'path'};
        for ($sindex=0; $sindex<$#subpaths; $sindex++) {
          next unless ($subpaths[$sindex]);
          $testpath .= "/$subpaths[$sindex]";
          $testpath =~ s/\/\//\//g;
          unless (-e "$testpath") {
            push(@ccd_indices, "$index:$vtps[$index]");
            last;
          }
        }
      }
      if ($#ccd_indices > -1) {
        filemanagerUploadFileConfirmForm("CONFIRM_CREATEDIR", @ccd_indices);
      }
    }
  }
}

##############################################################################

sub filemanagerUploadFileConfirmForm
{
  local($mesg, @indices) = @_;
  local($fullpath, $virtualpath, $displaypath);
  local(@subpaths, $filename, $iindex, $index, $key);

  encodingIncludeStringLibrary("filemanager");

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

  # save the uploaded files in a temporary location
  filemanagerTemporaryUploadFileSave();

  htmlResponseHeader("Content-type: $g_default_content_type");
  $FILEMANAGER_TITLE =~ s/__FILE__/$displaypath/g;
  labelCustomHeader("$FILEMANAGER_TITLE : $FILEMANAGER_ACTIONS_UPLOADFILE");
  if ($mesg eq "CONFIRM_OVERWRITE") {
    htmlText($FILEMANAGER_ACTIONS_UPLOADFILE_CONFIRM_OVERWRITE_TEXT);
  }
  elsif ($mesg eq "CONFIRM_CREATEDIR") {
    htmlText($FILEMANAGER_ACTIONS_UPLOADFILE_CONFIRM_CREATEDIR_TEXT);
  }
  htmlUL();
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "path", "value", $virtualpath);
  if (($mesg eq "CONFIRM_OVERWRITE") || 
      (defined($g_form{'confirm_file_overwrite'}))) {
    formInput("type", "hidden", "name", "confirm_file_overwrite", 
              "value", "yes");
  }
  if (($mesg eq "CONFIRM_CREATEDIR") || 
      (defined($g_form{'confirm_dir_create'}))) {
    formInput("type", "hidden", "name", "confirm_dir_create", 
              "value", "yes");
  }
  htmlTable();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;");
  htmlTableDataClose();
  htmlTableData();
  htmlTextBold($FILEMANAGER_ACTIONS_UPLOADFILE_SOURCE);
  htmlTableDataClose();
  htmlTableData();
  htmlText("&#160; &#160;");
  htmlTableDataClose();
  htmlTableData();
  if ($mesg eq "CONFIRM_OVERWRITE") {
    htmlTextBold($FILEMANAGER_ACTIONS_UPLOADFILE_TARGET);
  }
  elsif ($mesg eq "CONFIRM_CREATEDIR") {
    htmlTextBold($FILEMANAGER_ACTIONS_CREATEDIR_TARGET);
  }
  htmlTableDataClose();
  htmlTableRowClose();
  for ($iindex=0; $iindex<=$#indices; $iindex++) {
    ($index,$displaypath) = split(/:/, $indices[$iindex]);
    $key = "fileupload$index";
    htmlTableRow();
    htmlTableData();
    htmlText("$FILEMANAGER_TYPE_FILE&#160;$index\:");
    htmlTableDataClose();
    htmlTableData();
    htmlText($g_form{$key}->{'sourcepath'});
    htmlTableDataClose();
    htmlTableData();
    htmlText("&#160; &#160;");
    htmlTableDataClose();
    htmlTableData();
    if ($mesg eq "CONFIRM_CREATEDIR") {
      $displaypath =~ s/([^\/]+$)//;
    }
    htmlText($displaypath);
    htmlTableDataClose();
    htmlTableRowClose();
  }
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;");
  htmlTableDataClose();
  htmlTableData("colspan", "3");
  if ($mesg eq "CONFIRM_OVERWRITE") {
    formInput("type", "submit", "name", "submit",
              "value", $FILEMANAGER_CONFIRM_OVERWRITE);
  }
  elsif ($mesg eq "CONFIRM_CREATEDIR") {
    formInput("type", "submit", "name", "submit",
              "value", $FILEMANAGER_CONFIRM_CREATEDIR);
  }
  formInput("type", "submit", "name", "submit",
            "value", $FILEMANAGER_ACTIONS_COPY_CANCEL);
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  formClose();
  htmlULClose();
  htmlP();
  htmlText($FILEMANAGER_ACTIONS_UPLOADFILE_CONFIRM_NOTE);
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub filemanagerUploadFileForm
{
  local($mesg) = @_;
  local($fullpath, $virtualpath, $displaypath);
  local($errortext, $index, $sizel, $sizer);

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

  initUploadCookieSetSessionID();
  htmlResponseHeader("Content-type: $g_default_content_type");
  $FILEMANAGER_TITLE =~ s/__FILE__/$displaypath/g;
  labelCustomHeader("$FILEMANAGER_TITLE : $FILEMANAGER_ACTIONS_UPLOADFILE");
  htmlUL();
  if ($mesg && ($mesg eq "EMPTY_FIELD")) {
    $errortext = $FILEMANAGER_EMPTY_FIELD_ERROR;
    $errortext =~ s/__NAME__/$FILEMANAGER_ACTIONS_UPLOADFILE_SOURCE/;
    htmlTextColorBold(">>> $errortext <<<", "#cc0000");
    htmlP();
  }
  formOpen("method", "POST", "enctype", "multipart/form-data");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "path", "value", $virtualpath);
  htmlTextBold("$FILEMANAGER_CWD: &#160;");
  htmlText($virtualpath);
  htmlP();
  htmlTable();
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;");
  htmlTableDataClose();
  htmlTableData();
  htmlTextBold($FILEMANAGER_ACTIONS_UPLOADFILE_SOURCE);
  htmlBR();
  htmlText($FILEMANAGER_ACTIONS_UPLOADFILE_SOURCE_HELP);
  htmlTableDataClose();
  htmlTableData();
  htmlTextBold($FILEMANAGER_ACTIONS_UPLOADFILE_TARGET);
  htmlBR();
  htmlText($FILEMANAGER_ACTIONS_UPLOADFILE_TARGET_HELP);
  htmlTableDataClose();
  htmlTableRowClose();
  # print out the upload file rows, 1 to g_prefs{'ftp__upload_file_elements'}
  $sizel = formInputSize(35);
  $sizer = formInputSize(30);
  for ($index=1; $index<=$g_prefs{'ftp__upload_file_elements'}; $index++) {
    htmlTableRow();
    htmlTableData();
    htmlText("$FILEMANAGER_TYPE_FILE&#160;$index\:");
    htmlTableDataClose();
    htmlTableData();
    formInput("type", "file", "name", "fileupload$index", "size", $sizel);
    htmlTableDataClose();
    htmlTableData();
    formInput("name", "fileupload$index", "size", $sizer);
    htmlTableDataClose();
    htmlTableRowClose();
  }
  htmlTableRow();
  htmlTableData();
  htmlText("&#160;");
  htmlTableDataClose();
  htmlTableData("colspan", "2");
  htmlTable("border", "0", "cellpadding", "0", "cellspacing", "0");
  htmlTableRow();
  htmlTableData("valign", "top"); 
  formInput("type", "submit", "name", "submit",
            "value", $FILEMANAGER_ACTIONS_UPLOADFILE);
  formInput("type", "reset", "value", $RESET_STRING);
  formClose();
  htmlTableDataClose();
  htmlTableData("valign", "top"); 
  formOpen("method", "POST");
  authPrintHiddenFields();
  formInput("type", "hidden", "name", "path", "value", $virtualpath);
  htmlText("&#160;");
  formInput("type", "submit", "name", "submit", "value", $CANCEL_STRING);
  formClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlTableDataClose();
  htmlTableRowClose();
  htmlTableClose();
  htmlULClose();
  htmlP();
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub filemanagerUploadFileStore
{
  local($fsp, $vsp, $ftp, $vtp, @ftps, @vtps, @fsizes);
  local($index, $key, $filepath, $ftpd, $encpath, $firstline, $curline);
  local($firstdirectory, $currentdirectory, $title, $fmode);
  local($sessionid);

  # build full source path
  ($fsp, $vsp) = filemanagerGetFullPath($g_form{'path'});

  unless (-e "$fsp") {
    filemanagerResourceNotFound("filemanagerCheckUploadFileFormData
      verifying existence of \"$vsp\"");
  }

  encodingIncludeStringLibrary("filemanager");

  # save uploaded files
  for ($index=1; $index<=$g_prefs{'ftp__upload_file_elements'}; $index++) {
    $key = "fileupload$index";
    $filepath = $g_form{$key}->{'targetpath'} || 
                $g_form{$key}->{'sourcepath'};
    next unless ($filepath);
    ($ftp, $vtp) = filemanagerGetFullPath($filepath, $fsp);
    # if the target is a directory, append filename
    if (-d "$ftp") {
      $ftp .= "/$g_form{$key}->{'sourcepath'}";
      $vtp .= "/$g_form{$key}->{'sourcepath'}";
      $ftp =~ s/\/\//\//g;
      $vtp =~ s/\/\//\//g;
    }
    push(@ftps, $ftp);
    push(@vtps, $vtp);
    push(@fsizes, (stat($g_form{$key}->{'content-filename'}))[7]);
    # create any necessary directories
    $ftpd = $ftp;  # i know i know... these are stupid variable names
    $ftpd =~ s/\/$//;
    $ftpd =~ s/[^\/]+$//g;
    filemanagerCreateDirectory($ftpd);
    # create a zero length file first; for ownership inheritance
    # save uploaded file... well, actually, rename the file
    rename($g_form{$key}->{'content-filename'}, $ftp) ||
      filemanagerResourceError($FILEMANAGER_ACTIONS_UPLOADFILE,
          "rename($g_form{$key}->{'content-filename'}, $ftp) call failed in filemanagerUploadFileStore");
    # modify the file perms if applicable
    if (($g_platform_type eq "dedicated") && ($ftpd)) {
      ($fmode) = (stat($ftpd))[2];
      $fmode &= 0677 if ($fmode & 0100);
      $fmode &= 0767 if ($fmode & 0010);
      $fmode &= 0776 if ($fmode & 0001);
      chmod($fmode, $ftp);
    }
    # now let's do some nice things if the stored file is plain text file
    if (filemanagerIsText($ftp)) {
      # first, open the file and convert \r\n to \n.  why didn't we do
      # this earlier?  well, because we didn't want to clobber \r\n 
      # sequences in binary files
      $firstline = $curline = "";
      if (open(UFP, "$ftp")) {
        open(TFP, "+<$ftp");
        while (<UFP>) {
          $curline = $_;
          $firstline = $curline unless ($firstline);
          # convert CRLF to LF
          $curline =~ s/\r\n/\n/g;
          $curline =~ s/\r//g;
          print TFP $curline;
        }
        close(UFP);
        $curpos = tell(TFP);
        truncate(TFP, $curpos);
        close(TFP);
        # if the text file starts with the sequence '#!/', then we'll
        # assume that it should be executable
        if ($firstline =~ /^\#\!\//) {
          if (($g_platform_type eq "dedicated") && 
              ($g_users{$g_auth{'login'}}->{'uid'} == 0)) {
            filemanagerChmod(0700, $ftp); 
          }
          else {
            filemanagerChmod(0755, $ftp); 
          }
        }
      }
    }
  }

  # do some housekeeping if necessary
  $sessionid = initUploadCookieGetSessionID();
  if ($sessionid) {
    filemanagerTemporaryUploadFileRemove($sessionid);
    if ($g_platform_type eq "virtual") {
      $tmpfilename = $g_tmpdir . "/.upload-" . $sessionid . "-pid";
      unlink($tmpfilename);
    }
    else {
      HOUSEKEEPING: {
        local $> = 0;
        $tmpfilename = $g_maintmpdir . "/.upload-" . $sessionid . "-pid";
        unlink($tmpfilename);
      }
    }
  }

  if ($#vtps == 0) {
    # just one file was uploaded
    $g_form{'path'} = $vtps[0];
    $FILEMANAGER_ACTIONS_UPLOADFILE_SUCCESS_SINGLE_TEXT =~ s/\n/\ /g;
    redirectLocation("filemanager.cgi",
                     $FILEMANAGER_ACTIONS_UPLOADFILE_SUCCESS_SINGLE_TEXT);
  }
  else {
    # more than one file was uploaded, were they all uploaded to the same
    # directory?  if so, then redirect to the directory
    $firstdirectory = $ftps[0];
    $firstdirectory =~ s/[^\/]+$//; 
    for ($index=1; $index<=$#ftps; $index++) {
      $currentdirectory = $ftps[$index];
      $currentdirectory =~ s/[^\/]+$//; 
      if ($currentdirectory ne $firstdirectory) {
        last;
      }
    }
    if ($currentdirectory eq $firstdirectory) {
      # mulitple files uploaded to just one directory
      $g_form{'path'} = $vtps[0];
      $g_form{'path'} =~ s/[^\/]+$//;
      $FILEMANAGER_ACTIONS_UPLOADFILE_SUCCESS_MULTIPLE_TEXT =~ s/\n/\ /g;
      redirectLocation("filemanager.cgi",
                       $FILEMANAGER_ACTIONS_UPLOADFILE_SUCCESS_MULTIPLE_TEXT);
    }
    else {
      # rewrite the script name environment variable
      $ENV{'SCRIPT_NAME'} =~ /wizards\/([a-z_]*).cgi$/;
      $ENV{'SCRIPT_NAME'} =~ s/$1/filemanager/;  
      # print out a multiple file select form
      htmlResponseHeader("Content-type: $g_default_content_type");
      $FILEMANAGER_TITLE =~ s/__FILE__/$displaypath/g;
      $title = "$FILEMANAGER_TITLE : $FILEMANAGER_ACTIONS_UPLOADFILE";
      labelCustomHeader($title);
      htmlText($FILEMANAGER_ACTIONS_UPLOADFILE_SUCCESS_MULTIPLE_TEXT);
      htmlUL();
      htmlTable();
      htmlTableRow();
      htmlTableData("width", "24", "valign", "middle", "align", "right");
      htmlText("&#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold($FILEMANAGER_TYPE_FILE);
      htmlTableDataClose();
      htmlTableData();
      htmlText("&#160; &#160;");
      htmlTableDataClose();
      htmlTableData("valign", "middle", "align", "left");
      htmlTextBold($FILEMANAGER_FILESIZE);
      htmlTableDataClose();
      htmlTableRowClose();
      for ($index=0; $index<=$#ftps; $index++) {
        htmlTableRow();
        $encpath = encodingStringToURL($vtps[$index]);
        htmlTableData("width", "24", "valign", "middle", "align", "right");
        htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?path=$encpath",
                   "title", "$FILEMANAGER_JUMP_TEXT: $vtps[$index]");
        htmlImg("border", "0", "width", "24", "height", "24",
                "src", "$g_graphicslib/file.jpg");
        htmlAnchorClose();
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        htmlAnchor("href", "$ENV{'SCRIPT_NAME'}?path=$encpath",
                   "title", "$FILEMANAGER_JUMP_TEXT: $vtps[$index]");
        htmlAnchorText($vtps[$index]);
        htmlAnchorClose();
        htmlTableDataClose();
        htmlTableData();
        htmlText("&#160; &#160;");
        htmlTableDataClose();
        htmlTableData("valign", "middle", "align", "left");
        htmlText("$fsizes[$index] $BYTES");
        htmlTableDataClose();
        htmlTableRowClose();
      }
      htmlTableClose();
      htmlULClose();
      htmlP();
      labelCustomFooter();
      exit(0);
    }
  }
}

##############################################################################
# eof

1;

