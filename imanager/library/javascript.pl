#
# javascript.pl
# Copyright (c) 1996-2006 Verio Inc., an NTT Communications Company
# written by Rus Berrett
#
# $SMEId: local/imanager/library/javascript.pl,v 2.12.2.1 2006/04/25 19:48:23 rus Exp $
#
# javascript functions
#

##############################################################################

sub javascriptCheckMessageFields
{
  local($jscript);

  # javascript adapted from code found in O'Reilly Javascript book, p.261
  $jscript = "<script language=\"Javascript1.1\">
<!--
function isblank(s)
{
   for (var i=0; i<s.length; i++) {
     var c=s.charAt(i);
     if ((c != ' ') && (c != '\\n') && (c != '\\t')) return false;
   }
   return true;
}

function verify()
{
  var msg = \"\";

  if (isblank(document.formfields.send_to.value)) {
    msg += \"$MAILMANAGER_SEND_ERROR_TO_EMPTY\\n\";
  }
  if (isblank(document.formfields.send_from.value)) {
    msg += \"$MAILMANAGER_SEND_ERROR_FROM_EMPTY\\n\";
  }
  if (msg != \"\") {
    alert(msg);
    return false;
  }
  return true;
}
//-->
</script>
";

  return($jscript);
}

##############################################################################

sub javascriptHighlightUnhighlightRow
{
  local($jscript);

  $jscript = "<script language=\"Javascript1.1\">
<!--
function highlight_row(e)
{
  var r = null;

  if (e.parentNode && e.parentNode.parentNode) {
    r = e.parentNode.parentNode;
  }
  else if (e.parentElement && e.parentElement.parentElement) {
    r = e.parentElement.parentElement;
  }

  if (r) {
    if (r.className == \"unhighlighted\") {
      r.className = \"highlighted\";
    }
    else if (r.className == \"unreadunhighlighted\") {
      r.className = \"unreadhighlighted\";
    }
  }
}

function unhighlight_row(e)
{
  var r = null;

  if (e.parentNode && e.parentNode.parentNode) {
    r = e.parentNode.parentNode;
  }
  else if (e.parentElement && e.parentElement.parentElement) {
    r = e.parentElement.parentElement;
  }

  if (r) {
    if (r.className == \"highlighted\") {
      r.className = \"unhighlighted\";
    }
    else if (r.className == \"unreadhighlighted\") {
      r.className = \"unreadunhighlighted\";
    }
  }
}

function toggle_row(e)
{
  if (e.checked) {
    highlight_row(e);
  }
  else {
    unhighlight_row(e);
  }
}

//-->
</script>
";

  return($jscript);
}

##############################################################################

sub javascriptOpenWindow
{
  local($jscript);

  $jscript = "<script language=\"JavaScript1.1\">
<!--
  function openWindow(url, w, h) {
    var options = \"width=\" + w + \",height=\" + h + \",\";
    options += \"resizable=yes,scrollbars=yes,status=yes,\";
    options += \"menubar=no,toolbar=no,location=no,directories=no\";
    var newWin = window.open(url, 'newWin', options);
    newWin.opener = self;
    newWin.focus();
  }
//-->
</script>
";

  return($jscript);
}

##############################################################################

sub javascriptSearchAndReplace
{
  local($jscript);

  $jscript = "<script language=\"JavaScript1.1\">
<!--
  function search_and_replace(searchfor, replacewith, sourcestr)
  {
    var deststr = \"\";
    var index = sourcestr.indexOf(searchfor);
    if (index > -1) {
      var len = searchfor.length;
      var newsourcestr = sourcestr.substring(index+len);
      deststr = sourcestr.substring(0, index) + replacewith +
                search_and_replace(searchfor, replacewith, newsourcestr);
    }
    else {
      deststr = sourcestr;
    }
    return(deststr);
  }
//-->
</script>
";

  return($jscript);
}

##############################################################################

sub javascriptTagUntagAll
{
  local($jscript);

  $jscript = "<script language=\"JavaScript1.1\">
<!--
  var tagged = 0;
  function tag_untag_all(field)
  {
    var index;
    if (tagged == 0) {
      for (index = 0; index < field.length; index++) {
        field[index].checked = true;
        highlight_row(field[index]);
      }
      tagged = 1;
      return(\"$UNTAG_ALL\"); 
    }
    else {
      for (index = 0; index < field.length; index++) {
        field[index].checked = false; 
        unhighlight_row(field[index]);
      }
      tagged = 0;
      return(\"$TAG_ALL\"); 
    }

  }
//-->
</script>
";

  return($jscript);
}

##############################################################################
# eof

1;

