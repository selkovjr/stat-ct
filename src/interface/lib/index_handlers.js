// $Id: index_handlers.js,v 2.7 2013/11/16 22:19:17 stat Exp $

function initForm(date, teammate, nodeID, case_to_ignore) {
  document.registerform.case_to_ignore.value = case_to_ignore;
  document.registerform.teammate.value = teammate;
  document.registerform.date.options[document.registerform.date.options.length] = new Option(date);
  document.registerform.date.options.selectedIndex = document.registerform.date.options.length - 1;

  // contract all folders, then expand one level
  parent.clickOnNodeObj(parent.foldersTree);
  parent.clickOnNodeObj(parent.foldersTree);

  // expand the folder containing this procedure
  parent.clickOnNodeObj(node[nodeID].parentObj);

  // highlight the procedure
  highlightObjLink(node[nodeID]);
  location.href = "#new_case_form";
}

function setProc(procID) {
  document.registerform.procedure.value = procID;
}

function preprocess () {
  // don't commit on enter if WICK is selecting
  if (siw && siw.selectingSomething)
    return false;

  var teammate = document.getElementById("teammate").value;

  if ( teammate.length == 0 || teammate == null ) {
    var role = document.getElementById("role").value;
    if ( role == 'trainee' ) {
      role = 'attending physician';
    }
    else {
      role = 'trainee';
    }
    alert('Please spcecify ' + role + "'s name or CNetID");
    return false;
  }

  var anchors = document.body.getElementsByTagName("A");
  for ( var i = 0; i < anchors.length; i++ ) {
    if(anchors[i].id.match(/itemTextLink/)
       && (anchors[i].style.color === HIGHLIGHT_COLOR
           || anchors[i].style.color === '#ffffff') ) {
      // alert('Selected: ' + anchors[i].id + ', ' + anchors[i].firstChild.nodeValue + ' (' + document.registerform.procedure.value + ')');
      var procId = anchors[i].href.replace(/[^0-9]+/g, '');
      document.registerform.procedure.value = procId + ':' + anchors[i].firstChild.nodeValue;
      return true;
    }
  }
  alert('Please select a procedure');
  return false;
}

STAT.handleFolderOpening = function(folder) {
  var pearl = document.getElementById("pearl_" + folder.xID);
  if ( pearl ) {  // this assumes that a pearl was added by the template
    // can't have pearl buttons in children whithout having one in parent
    if ( folder.hasPearls ) pearl.className = "blackpearl";
    else pearl.className = "pearl";

    // now I need to check the pearl status of children
    for ( var i = 0; i < folder.nChildren; i++)  {
      var child = folder.children[i];
      pearl = document.getElementById("pearl_" + child.xID);
      if ( child.containsPearls ) {
	pearl.className = "blackpearl";
      }
    }
  }
}

STAT.handleFolderClosing = function(folder) {
  var pearl = document.getElementById("pearl_" + folder.xID);
  if ( pearl ) {
    // can't have pearl buttons in children whithout having one in parent
    if ( folder.containsPearls ) pearl.className = "blackpearl";
    else pearl.className = "pearl";
  }
}

function op() {}
