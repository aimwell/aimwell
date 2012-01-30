#
# html.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/html.pl,v 2.12.2.3 2006/04/25 19:48:23 rus Exp $
#
# html output fuctions
#

##############################################################################

sub htmlAnchor
{ 
  local(%values) = @_;
  local($name);

  # if the user is not using cookies to store authentication information,
  # then append the login/password info to the href string.  not everyone
  # likes cookies... so this next section of code coupled with the code in
  # authPrintHiddenFields() and redirectLocation() should cover all 
  # navigation sequences to keep the cookieless very happy crappy
  if ($g_auth{'type'} eq "form") {
    $values{'href'} .= "?" if ($values{'href'} !~ /\?/);
    $values{'href'} .= "&" if ($values{'href'} !~ /\?$/);
    $values{'href'} .= "AUTH=$g_auth{'KEY'}";
  }
 
  print "<a";
  foreach $name (keys(%values)) {
    if ($name eq "title") {
      $values{$name} =~ s/"/\&quot;/g;
    }
    print " $name=\"$values{$name}\"";
  } 
  print ">";
} 

##############################################################################

sub htmlAnchorArgs
{ 
  local(%anchorargs) = @_;
  local($name, $argstring);

  $argstring = "";
  foreach $name (keys(%anchorargs)) {
    $argstring .= "&" if ($argstring);
    $argstring .= "$name=";
    $argstring .= $anchorargs{$name} if ($anchorargs{$name});
  }
  return($argstring);
}

##############################################################################

sub htmlAnchorText
{
  local($text) = @_;

  $text =~ s/^\s//g;
  $text =~ s/\s$//g;
  $text = htmlSanitize($text);
  htmlFont("face", "arial, helvetica", "size", "2", 
           "style", "font-family:arial, helvetica; font-size:12px");
  print "$text";
  htmlFontClose();
}   

##############################################################################

sub htmlAnchorTextBold
{
  local($text) = @_;

  $text =~ s/^\s//g;
  $text =~ s/\s$//g;
  $text = htmlSanitize($text);
  htmlBold();
  htmlFont("face", "arial, helvetica", "size", "2",
           "style", "font-family:arial, helvetica; font-size:12px");
  print "$text";
  htmlFontClose();
  htmlBoldClose();
}   

##############################################################################

sub htmlAnchorTextLargeBold
{
  local($text) = @_;

  $text =~ s/^\s//g;
  $text =~ s/\s$//g;
  $text = htmlSanitize($text);
  htmlBold();
  htmlFont("face", "arial, helvetica", "size", "3",
           "style", "font-family:arial, helvetica; font-size:14px");
  print "$text";
  htmlFontClose();
  htmlBoldClose();
}   

##############################################################################

sub htmlAnchorTextCode
{
  local($text) = @_;

  $text =~ s/^\s//g;
  $text =~ s/\s$//g;
  $text = htmlSanitize($text);
  htmlFont("face", "courier new, courier", "size", "2", 
           "style", "font-family:courier new, courier; font-size:12px");
  print "$text";
  htmlFontClose();
}   

##############################################################################

sub htmlAnchorTextHeader
{
  local($text) = @_;

  $text =~ s/^\s//g;
  $text =~ s/\s$//g;
  $text = htmlSanitize($text);
  htmlBold();
  htmlFont("face", "arial, helvetica", "size", "4",
           "style", "font-family:arial, helvetica; font-size:18px");
  print "$text";
  htmlFontClose();
  htmlBoldClose();
}   

##############################################################################

sub htmlAnchorTextLarge
{
  local($text) = @_;

  $text =~ s/^\s//g;
  $text =~ s/\s$//g;
  $text = htmlSanitize($text);
  htmlFont("face", "arial, helvetica", "size", "3",
           "style", "font-family:arial, helvetica; font-size:14px");
  print "$text";
  htmlFontClose();
}   

##############################################################################

sub htmlAnchorTextSmall
{
  local($text) = @_;

  $text =~ s/^\s//g;
  $text =~ s/\s$//g;
  $text = htmlSanitize($text);
  htmlFont("face", "arial, helvetica", "size", "1",
           "style", "font-family:arial, helvetica; font-size:10px");
  print "$text";
  htmlFontClose();
}   

##############################################################################

sub htmlAnchorClose
{
  print "</a>";
}

##############################################################################

sub htmlBold
{
  print "<b>";
}

##############################################################################

sub htmlBoldClose
{
  print "</b>";
}

##############################################################################

sub htmlBody
{
  local(%values) = @_;

  print "<body";
  foreach $name (keys(%values)) {
    print " $name=\"$values{$name}\"";
  }
  print ">\n";
}

##############################################################################

sub htmlBodyClose
{
  print "</body>\n";
}

##############################################################################

sub htmlBR
{
  local(%values) = @_;

  print "<br";
  foreach $name (keys(%values)) {
    print " $name=\"$values{$name}\"";
  }
  print ">\n";
}

##############################################################################

sub htmlComment
{
  print "\n\n<!--\n";
}

##############################################################################

sub htmlCommentClose
{
  print "\n-->\n\n";
}

##############################################################################

sub htmlFont
{
  local(%values) = @_;

  print "<font";
  foreach $name (keys(%values)) {
    print " $name=\"$values{$name}\"";
  }
  print ">";
}

##############################################################################

sub htmlFontClose
{
  print "</font>";
}

##############################################################################

sub htmlFrame
{
  local(%values) = @_;

  print "<frame";
  foreach $name (keys(%values)) {
    print " $name=\"$values{$name}\"";
  }
  print ">\n";
}

##############################################################################

sub htmlFrameSet
{
  local(%values) = @_;

  print "<frameset";
  foreach $name (keys(%values)) {
    print " $name=\"$values{$name}\"";
  }
  print ">\n";
}

##############################################################################

sub htmlFrameSetClose
{
  print "</frameset>\n";
}

##############################################################################

sub htmlH3
{
  local($text) = @_;

  $text = htmlSanitize($text);
  htmlBold();
  htmlFont("class", "h3", "face", "arial, helvetica", "size", "4",
           "style", "font-family:arial, helvetica; font-size:18px");
  print "$text";
  htmlFontClose();
  htmlBoldClose();
}

##############################################################################

sub htmlHead
{
  print "<head>\n";
}

##############################################################################

sub htmlHeadClose
{
  print "</head>\n";
}

##############################################################################

sub htmlHR
{
  local(%values) = @_;

  print "<hr";
  foreach $name (keys(%values)) {
    if ($values{$name}) {
      print " $name=\"$values{$name}\"";
    }
    else {
      print " $name";
    }
  }
  print ">";
}

##############################################################################

sub htmlHtml
{
  print "<html>\n";
}

##############################################################################

sub htmlHtmlClose
{
  print "</html>\n";
}

##############################################################################

sub htmlImg
{ 
  local(%values) = @_;
 
  print "<img";
  foreach $name (keys(%values)) {
    print " $name=\"$values{$name}\"";
    # if alt tag exists; replicate its def as a 'title' attribute value
  } 
  if ((defined($values{'alt'})) && (!(defined($values{'title'})))) {
    print " title=\"$values{'alt'}\"";
  }
  print ">";
} 

##############################################################################

sub htmlItalic
{
  print "<i>";
}

##############################################################################

sub htmlItalicClose
{
  print "</i>";
}

##############################################################################

sub htmlListItem
{
  print "<li>";
}

##############################################################################

sub htmlNoBR
{
  print "<nobr>";
}

##############################################################################

sub htmlNoBRClose
{
  print "</nobr>";
}

##############################################################################

sub htmlNoFrames
{
  print "<noframes>\n";
}

##############################################################################

sub htmlNoFramesClose
{
  print "</noframes>\n";
}

##############################################################################

sub htmlOL
{
  print "<ol>";
}

##############################################################################

sub htmlOLClose
{
  print "</ol>";
}

##############################################################################

sub htmlP
{
  local(%values) = @_;

  print "<p";
  foreach $name (keys(%values)) {
    print " $name=\"$values{$name}\"";
  }
  print ">\n";
}

##############################################################################

sub htmlPClose
{
  print "</p>";
}

##############################################################################

sub htmlPre
{
  print "<pre>";
}

##############################################################################

sub htmlPreClose
{
  print "</pre>\n";
}

##############################################################################

sub htmlResponseHeader
{
  local(@headers) = @_;
  local($header, $html);

  $g_response_header_sent = 1;

  print "";
  foreach $header (@headers) {
    print "$header\n";
  }
  print "\n";
}

##############################################################################

sub htmlSanitize
{
  local($string) = @_;

  if ($string) {
    # don't escape out ampersands... this is only a necessity when sanitizing
    # text used in form elements like <input>, <option>, and <textarea>
    $string =~ s/\</\&lt\;/g;
    $string =~ s/\>/\&gt\;/g;
    $string =~ s/\"/\&quot\;/g;
  }
  return($string);
}

##############################################################################

sub htmlTable
{
  local(%values) = @_;

  print "<table";
  foreach $name (keys(%values)) {
    print " $name=\"$values{$name}\"";
  }
  print ">\n";
}

##############################################################################

sub htmlTableClose
{
  print "</table>\n";
}

##############################################################################
  
sub htmlTableData
{ 
  local(%values) = @_;
 
  print "<td";
  foreach $name (keys(%values)) {
    print " $name=\"$values{$name}\"";
  } 
  print ">";
} 

##############################################################################
  
sub htmlTableDataClose
{
  print "</td>\n";
}

##############################################################################
  
sub htmlTableRow 
{
  local(%values) = @_;
    
  print "<tr";
  foreach $name (keys(%values)) {
    print " $name=\"$values{$name}\"";
  }
  print ">\n";
}

##############################################################################
  
sub htmlTableRowClose
{
  print "</tr>\n";
}

##############################################################################

sub htmlText 
{
  local($text) = @_;  

  $text = htmlSanitize($text);
  htmlFont("class", "text", "face", "arial, helvetica", "size", "2",
           "style", "font-family:arial, helvetica; font-size:12px");
  print "$text";
  htmlFontClose();
}

##############################################################################

sub htmlTextBold
{
  local($text) = @_;

  $text = htmlSanitize($text);
  htmlBold();
  htmlFont("class", "boldtext", "face", "arial, helvetica", "size", "2",
           "style", "font-family:arial, helvetica; font-size:12px");
  print "$text";
  htmlFontClose();
  htmlBoldClose();
}

##############################################################################

sub htmlTextCode
{
  local($text) = @_;

  $text = htmlSanitize($text);
  htmlFont("class", "fixed", "face", "courier new, courier", "size", "2",
           "style", "font-family:courier new, courier; font-size:12px");
  print "$text";
  htmlFontClose();
}

##############################################################################

sub htmlTextCodeBold
{
  local($text) = @_;

  $text = htmlSanitize($text);
  htmlBold();
  htmlFont("class", "boldfixed", "face", "courier new, courier", "size", "2",
           "style", "font-family:courier new, courier; font-size:12px");
  print "$text";
  htmlFontClose();
  htmlBoldClose();
}

##############################################################################

sub htmlTextCodeColor
{
  local($text, $color) = @_;
  local($class, $html);

  $text = htmlSanitize($text);
  htmlFont("class", "boldfixed", "face", "courier new, courier", 
           "size", "2", "color", $color,
           "style", "font-family:courier new, courier; font-size:12px");
  print "$text";
  htmlFontClose();
}

##############################################################################

sub htmlTextCodeSmall
{
  local($text) = @_;

  $text = htmlSanitize($text);
  htmlFont("class", "smallfixed", "face", "courier new, courier", "size", "2",
           "style", "font-family:courier new, courier; font-size:11px");
  print "$text";
  htmlFontClose();
}

##############################################################################

sub htmlTextCodeSmallBold
{
  local($text) = @_;

  $text = htmlSanitize($text);
  htmlBold();
  htmlFont("class", "smallboldfixed", "face", "courier new, courier", 
           "size", "2",
           "style", "font-family:courier new, courier; font-size:11px");
  print "$text";
  htmlFontClose();
  htmlBoldClose();
}

##############################################################################

sub htmlTextColor
{
  local($text, $color) = @_;
  local($class, $html);

  $text = htmlSanitize($text);
  $class = ($color =~ /^\#/) ? "text" : $color . "text";
  htmlFont("class", $class, "face", "arial, helvetica", 
           "size", "2", "color", $color,
           "style", "font-family:arial, helvetica; font-size:12px");
  print "$text";
  htmlFontClose();
}

##############################################################################

sub htmlTextColorBold
{
  local($text, $color) = @_;
  local($class, $html);

  $text = htmlSanitize($text);
  $class = ($color =~ /^\#/) ? "boldtext" : $color . "boldtext";
  htmlBold();
  htmlFont("class", $class, "face", "arial, helvetica", 
           "size", "2", "color", $color,
           "style", "font-family:arial, helvetica; font-size:12px");
  print "$text";
  htmlFontClose();
  htmlBoldClose();
}

##############################################################################

sub htmlTextColorSmall
{
  local($text, $color) = @_;
  local($class, $html);

  $text = htmlSanitize($text);
  $class = ($color =~ /^\#/) ? "boldtext" : $color . "smalltext";
  htmlFont("class", $class, "face", "arial, helvetica", 
           "size", "1", "color", $color,
           "style", "font-family:arial, helvetica; font-size:10px");
  print "$text";
  htmlFontClose();
}

##############################################################################

sub htmlTextColorSmallBold
{
  local($text, $color) = @_;
  local($class, $html);

  $text = htmlSanitize($text);
  $class = ($color =~ /^\#/) ? "boldtext" : $color . "smallboldtext";
  htmlBold();
  htmlFont("class", $class, "face", "arial, helvetica", 
           "size", "1", "color", $color,
           "style", "font-family:arial, helvetica; font-size:10px");
  print "$text";
  htmlFontClose();
  htmlBoldClose();
}

##############################################################################

sub htmlTextItalic
{
  local($text) = @_;

  $text = htmlSanitize($text);
  htmlItalic();
  htmlFont("class", "italictext", "face", "arial, helvetica", "size", "2",
           "style", "font-family:arial, helvetica; font-size:12px");
  print "$text";
  htmlFontClose();
  htmlItalicClose();
}

##############################################################################

sub htmlTextLarge
{
  local($text) = @_;  

  $text = htmlSanitize($text);
  htmlFont("class", "largetext", "face", "arial, helvetica", "size", "3",
           "style", "font-family:arial, helvetica; font-size:14px");
  print "$text";
  htmlFontClose();
}

##############################################################################

sub htmlTextLargeBold
{
  local($text) = @_;  

  $text = htmlSanitize($text);
  htmlBold();
  htmlFont("class", "largeboldtext", "face", "arial, helvetica", "size", "3",
           "style", "font-family:arial, helvetica; font-size:14px");
  print "$text";
  htmlFontClose();
  htmlBoldClose();
}

##############################################################################

sub htmlTextSmall 
{
  local($text) = @_;  

  $text = htmlSanitize($text);
  htmlFont("class", "smalltext", "face", "arial, helvetica", "size", "1",
           "style", "font-family:arial, helvetica; font-size:10px");
  print "$text";
  htmlFontClose();
}

##############################################################################

sub htmlTextSmallBold
{
  local($text) = @_;  

  $text = htmlSanitize($text);
  htmlBold();
  htmlFont("class", "smalltext", "face", "arial, helvetica", "size", "1",
           "style", "font-family:arial, helvetica; font-size:10px");
  print "$text";
  htmlFontClose();
  htmlBoldClose();
}

##############################################################################

sub htmlTextUnderline
{
  local($text) = @_;

  $text = htmlSanitize($text);
  htmlUnderline();
  htmlFont("class", "underlinedtext", "face", "arial, helvetica", 
           "size", "2",
           "style", "font-family:arial, helvetica; font-size:12px");
  print "$text";
  htmlFontClose();
  htmlUnderlineClose();
}

##############################################################################

sub htmlTitle
{
  local($text) = @_;

  $text = htmlSanitize($text);
  print "<title>$text</title>\n";
}

##############################################################################

sub htmlUL
{
  print "<ul>";
}

##############################################################################

sub htmlULClose
{
  print "</ul>";
}

##############################################################################

sub htmlUnderline
{
  print "<u>";
}

##############################################################################

sub htmlUnderlineClose
{
  print "</u>";
}

##############################################################################
# eof

1;

