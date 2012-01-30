#
# fm_view.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/fm_view.pl,v 2.12.2.4 2006/04/25 19:48:23 rus Exp $
#
# file manager viewing functions
#

##############################################################################

sub filemanagerViewFile
{
  local($fullpath, $virtualpath, $filetype);
  local($mimetype, $fsize, $mtime, @subpaths, $filename, $curchar);
  local($action, $languagepref);

  ($fullpath, $virtualpath) = filemanagerGetFullPath($g_form{'path'});

  encodingIncludeStringLibrary("filemanager");

  $languagepref = encodingGetLanguagePreference();

  if (defined($g_form{'download'})) {
    $action = $FILEMANAGER_ACTIONS_DOWNLOAD;
  }
  else {
    $action = $FILEMANAGER_ACTIONS_VIEW;
  }

  if ((-d "$fullpath") || (-l "$fullpath")) {
    # uh... oops
    $filetype = filemanagerGetFileType($fullpath);
    $filetype =~ tr/A-Z/a-z/;
    $FILEMANAGER_FILETYPE_INVALID_ERROR =~ s/__SOURCE__/$virtualpath/g;
    $FILEMANAGER_FILETYPE_INVALID_ERROR =~ s/__LCTYPE__/$filetype/g;
    filemanagerUserError($action, $FILEMANAGER_FILETYPE_INVALID_ERROR);
  }

  unless (-e "$fullpath") {
    filemanagerResourceNotFound("filemanagerViewFile<br>
      verifying existence of \"$virtualpath\"");
  }

  if (defined($g_form{'download'})) {
    # set the Content-Type header to a nonstandard value such as 
    # application/x-download. It's very important that this header 
    # is something unrecognized by browsers because browsers often 
    # try to do something special when they recognize the content.
    # this doesn't work for non-compliant web browsers such as MS
    # Explorer 5.1 on a Mac 
    $mimetype = "application/x-download";
  }
  else {
    $mimetype = filemanagerGetMimeType($fullpath);
  }
  if ((filemanagerIsText($fullpath)) && ($languagepref eq "ja")) {
    # IE doesn't handle this right yet (Opera works great!)
    #$mimetype .= "; charset=EUC-JP";
  }

  ($fsize,$mtime) = (stat($fullpath))[7,9];
  @subpaths = split(/\//, $virtualpath);
  $filename = $subpaths[$#subpaths];

  if ((!(defined($g_form{'download'}))) &&
      (($mimetype eq "text/html") || ($mimetype eq "text/plain") ||
       ($mimetype eq "image/jpg") || ($mimetype eq "image/jpeg") || 
       ($minetype eq "image/jpe") || ($mimetype eq "image/pjpeg") ||
       ($mimetype eq "image/gif") || ($mimetype eq "image/png"))) {
    # viewing a file which most browsers will display in-line
    htmlResponseHeader("Content-type: $mimetype");
  }
  else { 
    # viewing a "non-common" file (see above) or "downloading" file
    htmlResponseHeader("Content-type: $mimetype; name=\"$filename\"",
              "Content-Disposition: attachment; filename=\"$filename\"",
              "Content-Length: $fsize");
  }
  open(FILE, "$fullpath") || 
    filemanagerResourceError($action, "open(FILE, \"$fullpath\")");
  if (filemanagerIsText($fullpath)) {
    while (<FILE>) {
      # massage the eol marker (if applicable)
      ## this ends up cropping files somehow
      ##if ($g_user_os eq "windows") {
      ##  s/\n$/\r\n/;
      ##}
      if ($languagepref eq "ja") {
        # IE doesn't handle this right yet (Opera works great!)
        #$_ = jcode'euc($_);
      }
      print STDOUT $_;
    }
  }
  else {
    while (read(FILE, $curchar, 1024)) {
      print STDOUT "$curchar";
    }
  }
  close(FILE);
}

##############################################################################
# eof

1;

