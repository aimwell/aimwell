#
# fm_util.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/fm_util.pl,v 2.12.2.5 2006/05/30 19:03:27 rus Exp $
#
# file manager utility functions
#

##############################################################################

sub filemanagerBuildFullPath
{
  local($userpath, $sourcepath) = @_;
  local($mypath, $fullpath, @subpaths, $index);

  if ($userpath =~ m#^~/#) {
    if (($g_platform_type eq "dedicated") &&
        (!$g_users{$g_auth{'login'}}->{'chroot'})) {
      # substitute full path for ~/PATH
      $userpath =~ s#^~/#$g_users{$g_auth{'login'}}->{'home'}/#;
    }
    else {
      $userpath =~ s#^~/#/#;
    }
  }
  elsif ($userpath =~ m#^~([^/]+)/#) {
    $userpath =~ s#^~[^/]+#$g_users{$1}->{'home'}/#;
  }

  if ($userpath !~ /^\//) {
    if ($sourcepath) {
      # if source path is supplied, use it to build full and virtual path
      # NOTE: source path presumed to be sanitized!
      # NOTE: source path presumed to be in home directory heirarchy!
      unless (-d "$sourcepath") {
        # oops... sourcepath isn't a directory, fix it up
        $sourcepath =~ s/\/+$//g;
        $sourcepath =~ s/[^\/]+$//g;
      }
      $fullpath = $sourcepath . "/" . $userpath;
    }
    else {
      # build a fullpath relative to current working directory... whatever
      # that happens to be... if no relative directory can be determined,
      # then presume path specification is relative to the users home dir
      if ($g_form{'cwd'}) {
        $mypath = $g_form{'cwd'};
        $g_form{'cwd'} = "";
        $fullpath = filemanagerBuildFullPath($mypath);
      }
      else {
        $fullpath = $g_users{$g_auth{'login'}}->{'home'};
      }
      $fullpath .= "/" . $userpath;
    }
  }
  else {
    $fullpath = $g_users{$g_auth{'login'}}->{'path'} . "/" . $userpath;
  }
  $fullpath =~ s/\/+/\//g;
  return("/") if ($fullpath eq "/");
  @subpaths = split(/\//, $fullpath);
  $mypath = "";
  for ($index=0; $index<=$#subpaths; $index++) {
    next if ((!$subpaths[$index]) || ($subpaths[$index] eq "."));
    if ($subpaths[$index] eq "..") {
      # remove the last subpath
      $mypath =~ s/[^\/]+$//g;
      $mypath =~ s/\/+$//g;
    }
    else {
      $mypath .= "/$subpaths[$index]";
    }
  }
  $mypath = "/" unless ($mypath);
  return($mypath);
}

##############################################################################

sub filemanagerChmod
{
  local($fmode, $fullpath) = @_;

  chmod($fmode, $fullpath) || return(0);
  return(1);
}

##############################################################################

sub filemanagerChown
{
  local($uid, $gid, $fullpath) = @_;

  chown($uid, $gid, $fullpath) || return(0);
  return(1);
}

##############################################################################

sub filemanagerCreateDirectory
{
  local($directory) = @_;
  local(@subpaths, $index, $curpath);
    
  return if (-e "$directory");

  $directory =~ s/\/+$//;
  @subpaths = split(/\//, $directory);
  for ($index=0; $index<=$#subpaths; $index++) {
    next unless ($subpaths[$index]);
    $curpath .= "/$subpaths[$index]";
    $curpath =~ s/\/\//\//g; 
    unless (-d "$curpath") {
      mkdir($curpath, 0700) ||
        filemanagerResourceError($FILEMANAGER_ACTIONS_CREATEDIR,
            "call to mkdir($curpath, 0700) in filemanagerCreateDirectory");
    }
  }
} 

##############################################################################

sub filemanagerGetDiskUtilization
{
  local($path, $uid) = @_;
  local($fuid, $fblck, $usage);

  $uid = $g_users{$g_auth{'login'}}->{'uid'} unless ($uid);
  $usage = 0;
  if (-l "$path") {
    ($fuid,$fblck) = (lstat($path))[4,12];
    if ($g_platform_type eq "virtual") {
      $usage = $fblck if ($fuid == $g_uid);
    }
    else {
      $usage = $fblck if ($fuid == $uid);
    }
  }
  elsif (-d "$path") {
    %g_linkinode = ();
    $usage = filemanagerGetDiskUtilizationFromRecursiveSearch($path, $uid);
  }
  else {
    ($fuid,$fblck) = (stat($path))[4,12];
    if ($g_platform_type eq "virtual") {
      $usage = $fblck if ($fuid == $g_uid);
    }
    else {
      $usage = $fblck if ($fuid == $uid);
    }
  }
  # convert blocks into bytes; stat() returns number of 512-byte blocks
  $usage *= 512;  
  return($usage);
}

##############################################################################

sub filemanagerGetDiskUtilizationFromRecursiveSearch
{
  local($path, $uid) = @_;
  local($size, $name, $fullpath, $inode, $nlink, $fuid, $fblck, *DIR);

  $uid = $g_users{$g_auth{'login'}}->{'uid'} unless ($uid);

  return unless ((-e "$path") && (-d "$path") && (!(-l "$path")));

  $size = 0;
  opendir(DIR, "$path");
  while ($name = readdir(DIR)) {
    next if (($name eq ".") || ($name eq ".."));
    $fullpath = $path . "/" . $name;
    if (-l "$fullpath") {
      # symlink
      ($fuid,$fblck) = (lstat($fullpath))[4,12];
      if ($g_platform_type eq "virtual") {
        $size += $fblck if ($fuid == $g_uid);
      }
      else {
        $size += $fblck if ($fuid == $uid);
      }
    }
    elsif (-d "$fullpath") {
      $fblck = filemanagerGetDiskUtilizationFromRecursiveSearch($fullpath);
      $size += $fblck;
    }
    else {
      # normal file, mind your hard links!
      ($inode,$nlink,$fuid,$fblck) = (stat($fullpath))[1,3,4,12];
      if ((($g_platform_type eq "virtual") && ($fuid == $g_uid)) ||
          (($g_platform_type eq "dedicated") && ($fuid == $uid))) {
        if (($nlink == 1) || (!defined($g_linkinode{$inode}))) {
          $size += $fblck;
        }
        $g_linkinode{$inode} = $inode if ($nlink > 1);
      }
    }
  }
  closedir(DIR);

  return($size);
}

##############################################################################

sub filemanagerGetFileType
{
  local($path) = @_;
  local($filetype);

  if (-l "$path") {
    $filetype = $FILEMANAGER_TYPE_FILE;
  } 
  elsif (-d "$path") {
    $filetype = $FILEMANAGER_TYPE_DIRECTORY;
  } 
  else {
    $filetype = $FILEMANAGER_TYPE_FILE;
  } 
  return($filetype);
}

##############################################################################

sub filemanagerGetFullPath
{
  local($userpath, $sourcepath) = @_;
  local($mypath, $fullpath, $virtualpath);

  $userpath = "/" unless ($userpath);
  # see filemanagerBuildFullPath for notes on sourcepath (if supplied)
  $mypath = filemanagerBuildFullPath($userpath, $sourcepath);
  if ($mypath !~ /^$g_users{$g_auth{'login'}}->{'path'}/) {
    # resulting testpath is not prefixed by home directory
    encodingIncludeStringLibrary("filemanager");
    $FILEMANAGER_PERMISSION_DENIED =~ s/__PATH__/$userpath/g;
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($FILEMANAGER_DENIED_TITLE);
    htmlText($FILEMANAGER_PERMISSION_DENIED);
    htmlP();
    htmlText("Error Code: 1003.1-1988");  # IEEE Std 1003.1-1988 (`POSIX')
    htmlP();
    labelCustomFooter();
    exit(0);
  }
  $virtualpath = $fullpath = $mypath;
  if ($g_users{$g_auth{'login'}}->{'path'} ne "/") {
    $virtualpath =~ s/^$g_users{$g_auth{'login'}}->{'path'}//g;
  }

  # convention is to remove trailing /'s
  $virtualpath =~ s/\/$//g;
  $fullpath =~ s/\/$//g;
  # ...well, with one exception anyway... if !defined(path), set to "/"
  $virtualpath = "/" unless ($virtualpath);
  $fullpath = "/" unless ($fullpath);

  return($fullpath, $virtualpath);
}

##############################################################################

sub filemanagerGetMimeType
{
  local($path) = @_;
  local($index, $pathext, $found, $mimetype, $extstring);
  local(%mimetypes, @extensions, $filename, $prefix);

  $prefix = initPlatformApachePrefix();
  $filename = "$prefix/conf/mime.types";

  $index = rindex($path, ".");
  if ($index >= 0) {
    $pathext = lc(substr($path, $index+1));
    $found = 0;
    open(MIMETYPES, "$filename");
    while (<MIMETYPES>) {
      s/^\s+//g;
      s/\s+$//g;
      s/\s+/ /g;
      next if ($_ =~ /^#/);
      $index = index($_, " ");
      next if ($index < 0);
      $mimetype = substr($_, 0, $index);
      $extstring = lc(substr($_, $index+1));
      @extensions = split(/\ /, $extstring);
      for ($index=0; $index<=$#extensions; $index++) {
        $mimetypes{$extensions[$index]} = $mimetype;
      }
    }
    close(MIMETYPES);
    return($mimetypes{$pathext}) if (defined($mimetypes{$pathext}));
  }
  return("text/plain") if ((-T "$path") && ($path !~ /\.pdf$/));
  return("application/octet-stream");
}

##############################################################################

sub filemanagerGetPermissionsText
{
  local($fmode) = @_;
  local($text_rwx, $text_octal);

  $text_rwx = "";

  # user
  if (($fmode >> 6) & 04) {
    $text_rwx .= "r";
    $text_octal += 400;
  }
  else {
    $text_rwx .= "-";
  }
  if (($fmode >> 6) & 02) {
    $text_rwx .= "w";
    $text_octal += 200;
  }
  else {
    $text_rwx .= "-";
  }
  if (($fmode >> 6) & 01) {
    $text_rwx .= "x";
    $text_octal += 100;
  }
  else {
    $text_rwx .= "-";
  }

  # group
  if (($fmode >> 3) & 04) {
    $text_rwx .= "r";
    $text_octal += 40;
  }
  else {
    $text_rwx .= "-";
  }
  if (($fmode >> 3) & 02) {
    $text_rwx .= "w";
    $text_octal += 20;
  }
  else {
    $text_rwx .= "-";
  }
  if (($fmode >> 3) & 01) {
    $text_rwx .= "x";
    $text_octal += 10;
  }
  else {
    $text_rwx .= "-";
  }

  # world
  if ($fmode & 04) {
    $text_rwx .= "r";
    $text_octal += 4;
  }
  else {
    $text_rwx .= "-";
  }
  if ($fmode & 02) {
    $text_rwx .= "w";
    $text_octal += 2;
  }
  else {
    $text_rwx .= "-";
  }
  if ($fmode & 01) {
    $text_rwx .= "x";
    $text_octal += 1;
  }
  else {
    $text_rwx .= "-";
  }

  # 'special'
  if ($fmode & 04000) {
    substr($text_rwx, 3, 1) = 's';
    $text_octal += 4000;
  }
  if ($fmode & 02000) {
    substr($text_rwx, 6, 1) = 's';
    $text_octal += 2000;
  }
  if ($fmode & 01000) {
    substr($text_rwx, 9, 1) = 't';
    $text_octal += 1000;
  }

  # fix up the text represenation of the octal format if necessary
  if ($text_octal < 1000) {
    $text_octal = "0$text_octal";
  }

  return($text_rwx, $text_octal);
}

##############################################################################

sub filemanagerGetQuotaUsage
{
  local($utype) = @_;
  local($homedir, $usage);

  unless ($utype) {
    if ($g_platform_type eq "virtual") {
      $utype = "dir";    # usage determined on contents of home directory
    }
    else {
      $utype = "quota";  # usage determined from quota
    }
  }

  $usage = 0;

  if ($utype eq "dir") {
    $homedir = $g_users{$g_auth{'login'}}->{'home'};
    $usage = filemanagerGetDiskUtilization($homedir);
    $usage += filemanagerGetDiskUtilization("/var/mail/$g_auth{'login'}");
  }
  elsif ($utype eq "quota") {
    # dedicated environment
    $usage = quotaGetUsed($g_users{$g_auth{'login'}}->{'uid'});
    $usage *= 1024;  # convert to bytes
  }

  # usage is returned in bytes
  return($usage);
}

##############################################################################

sub filemanagerInit
{
  local($homedir);

  # check for FTP privileges
  if ($g_users{$g_auth{'login'}}->{'ftp'} == 0) {
    encodingIncludeStringLibrary("filemanager");
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($FILEMANAGER_DENIED_TITLE);
    htmlText($FILEMANAGER_DENIED_TEXT);
    htmlP();
    labelCustomFooter();
    exit(0);
  }

  # check for a valid home directory
  $homedir = $g_users{$g_auth{'login'}}->{'home'};
  if ($homedir) {
    unless (-e "$homedir") {
      encodingIncludeStringLibrary("filemanager");
      htmlResponseHeader("Content-type: $g_default_content_type");
      labelCustomHeader($FILEMANAGER_HOMEDIR_INVALID_TITLE);
      htmlText($FILEMANAGER_HOMEDIR_INVALID_TEXT);
      htmlP();
      labelCustomFooter();
      exit(0);
    }
  }

  # do some housekeeping
  filemanagerTemporaryUploadFileRemove();

  # load up the date functions
  require "$g_includelib/date.pl";
}

##############################################################################

sub filemanagerIsBinary
{
  local($fpath) = @_;

  return(!(filemanagerIsText($fpath)));
}

##############################################################################

sub filemanagerIsReadable
{
  local($fpath) = @_;
  local($parent);

  return (1) if ((-r "$fpath") || (-R "$fpath"));

  # directories with 'x' bit set are readable
  if ((-d "$fpath") && (!(-l "$fpath"))) {
    return (1) if ((-x "$fpath") || (-X "$fpath"));
  }

  # file is readable if parent directory is readable
  $parent = $fpath;
  $parent =~ s/\/$//g;
  $parent =~ s/[^\/]+$//g;
  $parent =~ s/\/$//g;
  if ((!$parent) || ($parent eq "/")) {
    # root directory; well, top directory for virtual env anyway
    return(1) if ($g_platform_type eq "virtual");
  }
  else {
    return (1) if ((-x "$parent") || (-X "$parent"));
  }

  return(0);
}

##############################################################################

sub filemanagerIsText
{
  local($fpath) = @_;
  local($mimetype);

  $mimetype = filemanagerGetMimeType($fpath);

  return(1) if ($mimetype =~ /^text/);
  return(1) if ((-T "$fpath") && ($fpath !~ /pdf$/));
  return(0);
}

##############################################################################

sub filemanagerIsWritable
{
  local($fpath) = @_;
  local($parent);

  return (1) if ((-w "$fpath") || (-W "$fpath"));

  # file is writable if parent directory is writable
  $parent = $fpath;
  $parent =~ s/\/$//g;
  $parent =~ s/[^\/]+$//g;
  $parent =~ s/\/$//g;
  if ((!$parent) || ($parent eq "/")) {
    # root directory; well, top directory for virtual env anyway
    return(1) if ($g_platform_type eq "virtual");
  }
  else {
    return (1) if ((-w "$parent") || (-W "$parent"));
  }

  return(0);
}

##############################################################################

sub filemanagerResourceError
{
  local($resource, $errmsg) = @_;
  local($rootpath, $os_error, $key);

  $os_error = $!;

  # do some housekeeping
  foreach $key (keys(%g_form)) {
    if ($key =~ /^fileupload/) {
      unlink($g_form{$key}->{'content-filename'});
    }
  }

  encodingIncludeStringLibrary("filemanager");

  if ($errmsg) {
    # remove any references to home directory from message
    $rootpath = $g_users{$g_auth{'login'}}->{'path'};
    $errmsg =~ s/$rootpath/$FILEMANAGER_HOMEDIR/g if ($rootpath ne "/");
  }

  unless ($g_response_header_sent) {
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($FILEMANAGER_RESOURCE_ERROR_TITLE);
    $FILEMANAGER_RESOURCE_ERROR_TEXT =~ s/__RESOURCE__/$resource/;
    htmlText($FILEMANAGER_RESOURCE_ERROR_TEXT);
    htmlP();
    if ($errmsg) {
      htmlUL();
      htmlTextCode($errmsg);
      htmlULClose();
      htmlP();
    }
    if ($os_error) {
      htmlUL();
      htmlTextCode("$os_error");
      htmlULClose();
      htmlP();
    }
    labelCustomFooter();
    exit(0);
  }
  else {
    print STDERR "$errmsg\n" if ($errmsg);
    print STDERR "$os_error\n" if ($os_error);
  }
}

##############################################################################

sub filemanagerResourceNotFound
{
  local($debug_msg) = @_;

  encodingIncludeStringLibrary("filemanager");

  htmlResponseHeader("Content-type: $g_default_content_type");
  labelCustomHeader($FILEMANAGER_NOTFOUND_TITLE);
  htmlText($FILEMANAGER_NOTFOUND_TEXT);
  htmlP();
  if ($debug_msg) {
    htmlTextCode($debug_msg);
    htmlP();
  }
  labelCustomFooter();
  exit(0);
}

##############################################################################

sub filemanagerSanitizePath
{
  local($path) = @_;

  # remove any invalid ".." in path specification
  $path =~ s#/../#/#g; 
  $path =~ s#^../#/#; 
  $path =~ s#/..$#/#; 

  # same goes for "." too
  $path =~ s#/./#/#g; 
  $path =~ s#^./#/#; 
  $path =~ s#/.$#/#; 

  $path = "" if (($path eq ".") || ($path eq ".."));

  return($path);
}

##############################################################################

sub filemanagerSelectedOrder
{
  local($afp, $bfp);

  # sorts array entries in the 'selected' form field; this field is only
  # populated when copying, moving, or deleting multiple tagged filenames
  ($afp) = (split(/\|\|\|/, $a))[0];
  ($bfp) = (split(/\|\|\|/, $b))[0];

  if (((-d "$afp") && (!(-l "$afp"))) && ((-d "$bfp") && (!(-l "$bfp")))) {
    return($afp cmp $bfp);
  }
  elsif ((-d "$bfp") && (!(-l "$bfp"))) {
    return(1);
  }
  return(-1);

}

##############################################################################

sub filemanagerTemporaryUploadFileRead
{
  local($sessionid) = @_;
  local($index, $key, $filename);

  # read uploaded files from a temporary location which were stored there
  # in lieu of a pending confirmation... blech!
  for ($index=1; $index<=$g_prefs{'ftp__upload_file_elements'}; $index++) {
    $key = "fileupload$index";
    $filename = ".upload-" . $sessionid . "-" . $key . "_sourcepath";
    $fullpath = "$g_tmpdir/$filename";
    if (open(TFP, "$fullpath")) {
      while (read(TFP, $curchar, 1)) {
        $g_form{$key}->{'sourcepath'} .= $curchar;  
      }
      close(TFP);
    }
    $filename = ".upload-" . $sessionid . "-" . $key . "_content-filename";
    $fullpath = "$g_tmpdir/$filename";
    if (open(TFP, "$fullpath")) {
      while (read(TFP, $curchar, 1)) {
        $g_form{$key}->{'content-filename'} .= $curchar;  
      }
      close(TFP);
    }
    $filename = ".upload-" . $sessionid . "-" . $key . "_content-type";
    $fullpath = "$g_tmpdir/$filename";
    if (open(TFP, "$fullpath")) {
      while (read(TFP, $curchar, 1)) {
        $g_form{$key}->{'content-type'} .= $curchar;  
      }
      close(TFP);
    }
    $filename = ".upload-" . $sessionid . "-" . $key . "_targetpath";
    $fullpath = "$g_tmpdir/$filename";
    if (open(TFP, "$fullpath")) {
      while (read(TFP, $curchar, 1)) {
        $g_form{$key}->{'targetpath'} .= $curchar;  
      }
      close(TFP);
    }
  }
}

##############################################################################

sub filemanagerTemporaryUploadFileRemove
{
  local($sessionid) = @_;
  local($index, $key, $filename);

  if ($sessionid) {
    # look for temporary files with given session id and remove
    for ($index=1; $index<=$g_prefs{'ftp__upload_file_elements'}; $index++) {
      $key = "fileupload$index";
      # the sourcepath
      $filename = ".upload-" . $sessionid . "-" . $key . "_sourcepath";
      $fullpath = "$g_tmpdir/$filename";
      unlink($fullpath) if (-e "$fullpath");
      # the content-filename
      $filename = ".upload-" . $sessionid . "-" . $key . "_content-filename";
      $fullpath = "$g_tmpdir/$filename";
      if (-e "$fullpath") {
        if (open(TMPFILE, "$fullpath")) {
          $filename = <TMPFILE>;
          close(TMPFILE);
          chomp($filename);
          unlink($filename) if (-e "$filename");
        }
        unlink($fullpath)
      }
      # the content-type
      $filename = ".upload-" . $sessionid . "-" . $key . "_content-type";
      $fullpath = "$g_tmpdir/$filename";
      unlink($fullpath) if (-e "$fullpath");
      # the targetpath
      $filename = ".upload-" . $sessionid . "-" . $key . "_targetpath";
      $fullpath = "$g_tmpdir/$filename";
      unlink($fullpath) if (-e "$fullpath");
    }
  }

  # do some housekeeping
  $curtime = $g_curtime;
  if (opendir(TMPDIR, "$g_tmpdir")) {
    foreach $filename (readdir(TMPDIR)) {
      next unless ($filename =~ /^\.upload\-/);
      $fullpath = "$g_tmpdir/$filename";
      ($mtime) = (stat($fullpath))[9];
      unlink($fullpath) if (($curtime - $mtime) > (24 * 60 * 60));
    }
    closedir(TMPDIR);
  }
}

##############################################################################

sub filemanagerTemporaryUploadFileSave
{
  local($sessionid, $index, $key, $filename);

  # save uploaded files to a temporary location in lieu of a pending
  # confirmation

  encodingIncludeStringLibrary("filemanager");

  $sessionid = initUploadCookieGetSessionID();
  unless ($sessionid) {
    # uh oh... this could be trouble
    $sessionid = $g_curtime . "-" . $$;
  }
  for ($index=1; $index<=$g_prefs{'ftp__upload_file_elements'}; $index++) {
    $key = "fileupload$index";
    if ($g_form{$key}->{'sourcepath'}) {
      $filename = ".upload-" . $sessionid . "-" . $key . "_sourcepath";
      $fullpath = "$g_tmpdir/$filename";
      open(TFP, ">$fullpath") ||
        filemanagerResourceError($FILEMANAGER_ACTIONS_UPLOADFILE,
          "open(TFP, >$fullpath) call in filemanagerTemporaryUploadFileSave");
      print TFP "$g_form{$key}->{'sourcepath'}";
      close(TFP);
    }
    if ($g_form{$key}->{'content-filename'}) {
      $filename = ".upload-" . $sessionid . "-" . $key . "_content-filename";
      $fullpath = "$g_tmpdir/$filename";
      open(TFP, ">$fullpath") ||
        filemanagerResourceError($FILEMANAGER_ACTIONS_UPLOADFILE,
          "open(TFP, >$fullpath) call in filemanagerTemporaryUploadFileSave");
      print TFP "$g_form{$key}->{'content-filename'}";
      close(TFP);
    }
    if ($g_form{$key}->{'content-type'}) {
      $filename = ".upload-" . $sessionid . "-" . $key . "_content-type";
      $fullpath = "$g_tmpdir/$filename";
      open(TFP, ">$fullpath") ||
        filemanagerResourceError($FILEMANAGER_ACTIONS_UPLOADFILE,
          "open(TFP, >$fullpath) call in filemanagerTemporaryUploadFileSave");
      print TFP "$g_form{$key}->{'content-type'}";
      close(TFP);
    }
    if ($g_form{$key}->{'targetpath'}) {
      $filename = ".upload-" . $sessionid . "-" . $key . "_targetpath";
      $fullpath = "$g_tmpdir/$filename";
      open(TFP, ">$fullpath") ||
        filemanagerResourceError($FILEMANAGER_ACTIONS_UPLOADFILE,
          "open(TFP, >$fullpath) call in filemanagerTemporaryUploadFileSave");
      print TFP "$g_form{$key}->{'targetpath'}";
      close(TFP);
    }
  }
}

##############################################################################

sub filemanagerUserError
{
  local($resource, $errmsg) = @_;
  local($rootpath);

  # does the same thing as filemanagerResourceError without display of $!

  encodingIncludeStringLibrary("filemanager");

  # remove any references to home directory from message
  $rootpath = $g_users{$g_auth{'login'}}->{'path'};
  $errmsg =~ s/$rootpath/$FILEMANAGER_HOMEDIR/g if ($rootpath ne "/");

  unless ($g_response_header_sent) {
    htmlResponseHeader("Content-type: $g_default_content_type");
    labelCustomHeader($FILEMANAGER_RESOURCE_ERROR_TITLE);
    $FILEMANAGER_RESOURCE_ERROR_TEXT =~ s/__RESOURCE__/$resource/;
    htmlText($FILEMANAGER_RESOURCE_ERROR_TEXT);
    htmlP();
    htmlText($errmsg);
    htmlP();
    labelCustomFooter();
    exit(0);
  }
  else {
    print STDERR "$errmsg\n";
  }
}

##############################################################################
# eof

1;

