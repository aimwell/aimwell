#
# form.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/form.pl,v 2.12.2.8 2006/04/25 19:48:23 rus Exp $
#
# form functions
#

$g_min_textarea_rows = 12;       # min number of rows in a text area element
$g_max_textarea_rows = 40;       # max number of rows in a text area element

##############################################################################

sub formClose
{
  print "</form>\n";
}

##############################################################################

sub formInput
{
  local(%values) = @_;
  local($fontsize, $pxsize);

  $pxsize = "13px";

  # take dangerous characters out of value if specified
  if ($values{'value'}) {
    $values{'value'} =~ s/\&/\&amp\;/g;  # escape out ampersands first
    $values{'value'} = htmlSanitize($values{'value'});
  }

  print "<input";
  foreach $name (keys(%values)) {
    next if ($name eq "_OTHER_");
    print " $name=\"";
    print $values{$name} if (defined($values{$name}));
    print "\"";
  }
  if (!$values{'type'} || ($values{'type'} ne "hidden")) {
    print " style=\"font-family: arial, helvetica; font-size: $pxsize\"";
  }
  print " $values{'_OTHER_'}" if ($values{'_OTHER_'});
  print ">";
  if (!$values{'type'} || ($values{'type'} ne "checkbox")) {
    print "\n";
  }
}

##############################################################################

sub formInputSize
{
  local($inputsize) = @_;
  local($formsize);

  # if cornered, I'll deny ever putting in this kludge to make Netscape 4
  # browsers match how MSIE correctly renders input form lengths. as much
  # as I dislike MSIE, I must conceed that MSIE does render form elements
  # and table data in a manner more like one would expect.  IMO, Netscape
  # is easier to use, but it is not without its own irritating quirks...
  # alas... I digress... I deny the following function outright.
  #
  # author's note: 
  # Netscape 6 (preview release) appears to have fixed this 4.x bug

  # input size is the actual character length that is desired, adjust 
  # desired size by the Netscape 4 bug ratio as determined experimentally
  if (($ENV{'HTTP_USER_AGENT'} =~ /Mozilla\/4/) &&
      ($ENV{'HTTP_USER_AGENT'} !~ /compatible; MSIE/) &&
      ($ENV{'HTTP_USER_AGENT'} =~ /Win/)) {
    # okay... Netscape 4.x win95/98/NT browsers, unix variants seem fine
    $formsize = sprintf "%d", ($inputsize * 0.52);
  }
  else {
    $formsize = $inputsize; 
  }
  $formsize = 1 if ($formsize < 1);
  return($formsize);
}

##############################################################################

sub formOpen
{
  local(%values) = @_;

  $values{'method'} = "POST" unless ($values{'method'});
  print "<form";
  foreach $name (keys(%values)) {
    print " $name=\"$values{$name}\"";
  }
  unless (defined($values{'action'})) {
    print " action=\"$ENV{'SCRIPT_NAME'}\"";
  }
  print ">\n";
}

##############################################################################

sub formParseData
{
  if ($ENV{'CONTENT_LENGTH'} && ($ENV{'CONTENT_LENGTH'} > 0) &&
      ($ENV{'CONTENT_TYPE'} =~ /multipart\/form-data/)) {
    # should only drop in here if file upload element is present in form
    formParseDataMultipart();
  }
  else {
    formParseDataUrlEncoded();
  }
}


##############################################################################

sub formParseDataMultipart
{
  # parses form data submitted in multi-part mode; stores small data to 
  # memory and writes big stuff to disk in tmp files.  did this to avoid
  # filling up sandbox and getting killed by the watcher daemons.
  
  local($boundary, $buffer, $bufferlen, $firstchar, $nextchar, $fsize);
  local($curline, $formname, $filename, $name, $value, $tmpfilename, $value);
  local($errmsg, $string, $key, $sessionid);

  if ($ENV{'CONTENT_TYPE'} =~ /multipart\/form-data; boundary=(.*)/) {
    # get the session id
    $sessionid = initUploadCookieGetSessionID();
    unless ($sessionid) {
      $sessionid = $g_curtime . "-" . $$;
    }
    # store the current pid in a session id file; this will be used
    # if the user decides to "Cancel" the upload request later
    $tmpfilename = $g_tmpdir . "/.upload-" . $sessionid . "-pid";
    if (open(TMPFILE, ">>$tmpfilename")) {
      print TMPFILE "$$\n";
      close(TMPFILE);
    }
    # parse the multi-part form data 
    $boundary = $1;
    $bufferlen = length($boundary) + 2;
    read(STDIN, $buffer, $bufferlen);
    while ($buffer ne "$boundary--") {
      if ($buffer eq "--$boundary") {
        # new variable definition block; read the block headers
        $curline = <STDIN>;  # rest of boundary line
        last if ($curline eq "--\r\n");  # closing boundary; end of stream
        $curline = <STDIN>;  # first actual header
        if ($curline =~ /form-data; name=\"(.*?)\"; filename=\"(.*?)\"/) {
          # if we are here, then typical match is something like:
          # 'Content-Disposition: form-data; name="NAME"; filename="FILE"'
          # the body of block is the contents of the filename, FILE
          $formname = $1;
          $filename = $2;
          if ($filename) {
            $g_form{$formname}->{'fullsourcepath'} = $filename;
            if ($filename =~ /\\/) {
              $filename =~ s/\\/\//g;
            }
            $filename =~ /([^\/]+$)/;
            $filename = $1;
            $g_form{$formname}->{'sourcepath'} = $filename;
          }
          # read the remaining supplemental headers (if exist)
          while ($curline ne "\r\n") {
            $curline = <STDIN>;
            if ($curline =~ /(.*?): (.*)/) {
              # supplemental information headers; formname should be active
              $name = $1;
              $value = $2;
              $name =~ tr/A-Z/a-z/;
              $value =~ s/^\s+//;
              $value =~ s/\s+$//;
              $g_form{$formname}->{$name} = $value;
            }
          }
          # now read the block body; read stream until next boundary is 
          # encountered and store in a temporary file... store the name
          # of the temporary file as the value of the 'content-filename'
          $tmpfilename = $g_tmpdir . "/.upload-" . $sessionid . "-" . $formname;
          $g_form{$formname}->{'content-filename'} = $tmpfilename;
          unless (open(TMPFILE, ">$tmpfilename")) {
            $errmsg = "open(TMPFILE, '>$tmpfilename') failed -- ";
            $errmsg .= "check available disk space";
            formParseDataMultipartError($errmsg);
          }
          read(STDIN, $buffer, ($bufferlen+2));  # add 2 for the \r\n
          while ($buffer ne "\r\n--$boundary") {
            $firstchar = substr($buffer, 0, 1);
            unless (print TMPFILE $firstchar) {
              $errmsg = "write to TMPFILE failed -- ";
              $errmsg .= "check available disk space\n";
              $errmsg .= "tmpfilename=$tmpfilename\n";
              formParseDataMultipartError($errmsg);
            }
            read(STDIN, $nextchar, 1) || last;
            $buffer = substr($buffer, 1) . $nextchar;
          }
          close(TMPFILE);
          # remove filename if it is zero length
          ($fsize) = (stat($tmpfilename))[7];
          if ($fsize == 0) {
            foreach $key (keys(%{$g_form{$formname}})) {
              delete($g_form{$formname}->{$key});
            }
            unlink($tmpfilename);
          }
          # reset buffer (subtract 2)
          $buffer = substr($buffer, 2);
        }
        elsif ($curline =~ /form-data; name=\"(.*?)\"/) {
          # form name equal value block, where value is defined in the body
          # of the block; no special treatment is required
          $formname = $1;
          # read the remaining supplemental headers (if exist) and ignore
          while ($curline ne "\r\n") {
            $curline = <STDIN>;
          }
          # now read in the block body
          $value = "";
          read(STDIN, $buffer, ($bufferlen+2));  # add 2 for the \r\n
          while ($buffer ne "\r\n--$boundary") {
            $firstchar = substr($buffer, 0, 1);
            $value .= $firstchar;
            read(STDIN, $nextchar, 1) || last;
            $buffer = substr($buffer, 1) . $nextchar;
          }
          # now read the body of the block and store as variable value
          if ($formname =~ /^fileupload/) {
            # this is actually where the targetpath for the upload file form 
            # elements is stored.  the sourcepath is contained in the 
            # content-dispostion info header (filename="FILE") of the form
            # block which includes the actual uploaded file data.  confused?
            # don't sweat it.  it works... and that is all that matters.  ;)
            $g_form{$formname}->{'targetpath'} = $value;
          }
          else {
            $g_form{$formname} = $value;
          }
          # reset buffer (subtract 2)
          $buffer = substr($buffer, 2);
        }
        else {
          # ignore
          read(STDIN, $nextchar, 1) || last;
          $buffer = substr($buffer, 1) . $nextchar;
        }
      }
      else {
        read(STDIN, $nextchar, 1) || last;
        $buffer = substr($buffer, 1) . $nextchar;
      }
    }
  }
}

##############################################################################

sub formParseDataMultipartError
{
  local($errmsg) = @_;
  local($os_error);

  $os_error = $!;

  # do some housekeeping
  if (-e "$g_tmpdir") {
    if (opendir(TMPDIR, "$g_tmpdir")) {
      foreach $filename (readdir(TMPDIR)) {
        next if (($filename eq ".") || ($filename eq ".."));
        next unless ($filename =~ /$g_curtime\-$$/);
        next unless (-f "$g_tmpdir/$filename");
        unlink("$g_tmpdir/$filename");
      }  
      closedir(TMPDIR);
    }
  }

  unless ($g_response_header_sent) {
    print "Content-type: text/plain\n\n";
    print "formParseDataMultipartError:\n";
    print "$errmsg\n" if ($errmsg);
    print "$os_error\n" if ($os_error);
    exit(0);
  }
  else {
    print STDERR "$errmsg\n" if ($errmsg);
    print STDERR "$os_error\n" if ($os_error);
  }
}

##############################################################################

sub formParseDataUrlEncoded
{
  local($kvstring, @kvpairs, $kv, $key, $value);

  if ($ENV{'REQUEST_METHOD'} eq "GET") {
    #$kvstring = $ENV{'QUERY_STRING'};
    $value = index($ENV{'REQUEST_URI'}, '?');
    $kvstring = substr($ENV{'REQUEST_URI'}, $value+1);
  } 
  elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
    read(STDIN, $kvstring, $ENV{'CONTENT_LENGTH'});
  } 
  else {   # neither POST nor GET
    return;
  }

  @kvpairs = split(/&/, $kvstring);
  foreach $kv (@kvpairs) {
    ($key, $value) = split (/=/, $kv);
    # scrub up the key
    $key =~ tr/+/ /;
    $key =~ s/\%00//g;
    $key =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex($1))/eg;
    $key =~ s/^\s+//;
    $key =~ s/\s+$//;
    # scrub up the value
    $value =~ tr/+/ /;
    $value =~ s/\%00//g;
    $value =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex($1))/eg;
    if (($key eq "editedfile") || ($key eq "sigtext") ||
        ($key eq "send_body") || ($key eq "auto_body")) {
      #
      # don't scrub too hard on certain form submission data such as
      # those that are submitted from text area widgets (see below) 
      #
      # name eq "editedfile"     filemanager: edit file
      # name eq "sigtext"        signature: body of signature
      # name eq "send_body"      mailmanager: body of message
      # name eq "auto_body"      autoresponder: body of autoresponder 
    }
    else {
      # remove evil spirits
      $value =~ s/^\s+//;
      $value =~ s/\s+$//;
    }
    if (defined($g_form{$key})) {
      $g_form{$key} .= "|||$value";
    }
    else {
      $g_form{$key} = $value;
    }
  }
} 
 
##############################################################################
 
sub formSelect
{
  local(%values) = @_;

  if ($values{'_FONT_'} && ($values{'_FONT_'} eq "fixed")) {
    htmlFont("class", "fixed", "face", "courier new, courier", "size", "3");
  }
  else {
    htmlFont("class", "text", "face", "arial, helvetica", "size", "3");
  }
  print "<select"; 
  foreach $name (keys(%values)) {
    next if ($name eq "_FONT_");
    next if ($name eq "_OTHER_");
    print " $name=\"$values{$name}\"";
  }
  print " $values{'_OTHER_'}" if ($values{'_OTHER_'});
  print ">\n";
}

##############################################################################

sub formSelectClose
{ 
  print "</select>";
  htmlFontClose();
  print "\n";
} 
    
##############################################################################
    
sub formSelectOption
{   
  local($value, $name, $selected) = @_;

  $value =~ s/\&/\&amp\;/g;  # escape out ampersands first
  $value = htmlSanitize($value);
  print "<option value=\"$value\"";
  print " SELECTED" if ($selected);
  print "> $name\n"; 
}   
    
##############################################################################
    
sub formSelectRows
{
  local($numelements) = @_;

  return($numelements) if ($numelements <= 15);
  return(15) if ($numelements <= 100);
  return(25);
}

##############################################################################

sub formTextArea
{
  local($default, %values) = @_;
  local($languagepref);

  if ($values{'_FILENAME_'}) {
    $languagepref = encodingGetLanguagePreference();
  }

  if ($values{'_FONT_'} eq "fixed") {
    htmlFont("class", "fixed", "face", "courier new, courier", "size", "3");
  }
  else {
    htmlFont("class", "text", "face", "arial, helvetica", "size", "2");
  }
  print "<textarea";
  foreach $name (keys(%values)) {
    next if ($name eq "_FONT_");
    next if ($name eq "_OTHER_");
    next if ($name eq "_FILENAME_");
    print " $name=\"$values{$name}\"";
  }
  print " $values{'_OTHER_'}" if ($values{'_OTHER_'});
  print ">";
  if ($values{'_FILENAME_'}) {
    # read contents of file and print directly to STDOUT
    if (open(DEFAULT, "$values{'_FILENAME_'}")) {
      while (<DEFAULT>) {
        $default = $_;
        if ($languagepref eq "ja") {
          $default = jcode'euc($default);
        }
        $default =~ s/\&/\&amp\;/g;  # escape out ampersands first
        $default = htmlSanitize($default);
        print "$default";
      }
      close(DEFAULT);
    }
  }
  else {
    if ($default) {
      $default =~ s/\&/\&amp\;/g;  # escape out ampersands first
      $default = htmlSanitize($default);
      print "$default";
    }
  }
  print "</textarea>";
  htmlFontClose();
  print "\n";
}

##############################################################################

sub formTextAreaRows
{
  local($text, $minrows, $maxrows) = @_;
  local($rows);

  $minrows = $g_min_textarea_rows unless ($minrows);
  $maxrows = $g_max_textarea_rows unless ($maxrows);

  return($maxrows) unless($text);

  $rows = $text =~ tr/\n/\n/;
  if ($rows > $maxrows) {
    $rows = $maxrows;
  }
  elsif ($rows < $minrows) {
    $rows = $minrows;
  }
  return($rows);
}

##############################################################################
# eof

1;

