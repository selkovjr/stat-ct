// $Id: manage_handlers.js,v 2.1 2009-02-20 14:51:36 selkovjr Exp $

// ************************* I N I T I A L I Z A T I O N *************************
function initForm() {
  // open the first-level child nodes
  for ( var i = 0; i < foldersTree.nChildren; i++ ) {
    var child = foldersTree.children[i];
    if ( !child.isOpen ) {
      parent.clickOnNodeObj(child);
    }
  }

  // create button state hash and set initial states to 'true' (disabled)
  for ( var i = 0; i < document.manageform.elements.length; i++ ) {
    var input = document.manageform.elements[i];
    if ( input.type == 'submit' || input.type == 'button') {
      inputDisabled[input.name] = true;
    }
  }

  // enable some buttons
  if ( cloneExists ) {
    inputDisabled['commit'] = false;
    inputDisabled['cancel'] = false;
    inputDisabled['compare'] = false;
  }

  setFolderButtonsFromHash();

  // make sure there is no selection 
  unselect();
}

// ******************************* S E L E C T I O N *****************************
function selectNode(nodeID, tooBig) {
  document.manageform.node.value = nodeID;
  highlightObjLink(node[nodeID]);

  inputDisabled['expand'] = tooBig || !canExpand(node[nodeID]);
  inputDisabled['add'] = false;
  inputDisabled['edit'] = false;
  inputDisabled['copy'] = tooBig || false;
  inputDisabled['cut'] = false;
  inputDisabled['reparent'] = tooBig || !node[nodeID].children
    if ( copyBufferExists )
      inputDisabled['paste'] = false;
  inputDisabled['up'] = isFirstChild(node[nodeID]);
  inputDisabled['down'] = isLastChild(node[nodeID]);
  
  setFolderButtonsFromHash();
}

function unselect () {
  // this behavior is duplicated as part of highlightObjLink()
  if (lastClicked != null) {
    var prevClickedDOMObj = getElById('itemTextLink'+lastClicked.id);
    prevClickedDOMObj.style.color=lastClickedColor;
    prevClickedDOMObj.style.backgroundColor=lastClickedBgColor;
  }
  document.manageform.node.value = null;
}

// ************************** F O L D E R   O P E N I N G ***********************
function handleFolderOpening(folder) {
  // if the folder is selected, try to enable expansion 
  if ( document.manageform.node.value ) {
    inputDisabled['expand'] = !canExpand(node[document.manageform.node.value]);
    setFolderButtonsFromHash();
  }
}

function expandSelected () {
  if ( document.manageform.node.value != null ) {
    expandAll(node[document.manageform.node.value]);
    inputDisabled['expand'] = true;
    setFolderButtonsFromHash();
  }
}

function expandAll(folder) {
  // Open folder
  if (!folder.isOpen)
    parent.clickOnNodeObj(folder);

  // Call this function for all folder children
  for ( var i = 0; i < folder.nChildren; i++)  {
    var child = folder.children[i];
    if (typeof child.setState != "undefined") { // is a folder
      expandAll(child);
    }
  }
}

// ************************** F O L D E R   C L O S I N G ***********************
function handleFolderClosing(folder) {
  if ( folder.xID == document.manageform.node.value ) {
    // if I am closing myself, and I am selected, I should
    // become expandable again
    inputDisabled['expand'] = false;
  }
  else if ( isChildOf(folder.xID, document.manageform.node.value) ) {
    // if the current selection is within the folder being closed, 
    // remove selection and reset the buttons
    unselect();
    inputDisabled['expand'] = true;
    inputDisabled['add'] = true;
    inputDisabled['edit'] = true;
    inputDisabled['copy'] = true;
    inputDisabled['cut'] = true;
    inputDisabled['reparent'] = true;
    inputDisabled['paste'] = true;
    inputDisabled['up'] = true;
    inputDisabled['down'] = true;
  }
  else {
    // current folder is unrelated to selection; enable or disable
    // expansion according to selected folder's condition
    if ( node[document.manageform.node.value] ) {
      inputDisabled['expand'] = !canExpand(node[document.manageform.node.value]);
    }
    // no change if nothing is selected
  }
  setFolderButtonsFromHash();
}


// ************************ F O R M   S U B M I S S I O N ***********************
function preprocess() {
  // do not disable manageform.node here because Galeon and 
  // other Mozillas do not re-enable it after having come back to the form.
}

// ************************** M I S C E L L A N E O U S *************************
function setFolderButtonsFromHash () {
  for ( var i = 0; i < document.manageform.elements.length; i++ ) {
    var input = document.manageform.elements[i];
    if ( typeof(inputDisabled[input.name]) != 'undefined' ) {
      input.disabled = inputDisabled[input.name];
    }
  }
}

function isChildOf(folderID, nodeID) {
  if (typeof node[folderID].setState == "undefined") // folderID is a leaf node
    return false;

  for ( var i = 0; i < node[folderID].nChildren; i++ ) {
    var child = node[folderID].children[i];
    if ( child.xID == nodeID ) {
      return true;
    }
    else {
      if ( isChildOf(child.xID, nodeID) ) {
        return true;
      }
    }
  }
  return false;
}

function locatePrevious() {
  var folder = node[document.manageform.node.value];
  for ( var i = 1; i < folder.parentObj.nChildren; i++ ) {
    var child = folder.parentObj.children[i];
    if ( child == folder ) {
      document.manageform.other_node.value = folder.parentObj.children[i-1].xID;
    }
  }
}

function locateNext() {
  var folder = node[document.manageform.node.value];
  for ( var i = 0; i < folder.parentObj.nChildren - 1; i++ ) {
    var child = folder.parentObj.children[i];
    if ( child == folder ) {
      document.manageform.other_node.value = folder.parentObj.children[i+1].xID;
    }
  }
}

function isFirstChild (folder) {
  if ( folder == folder.parentObj.children[0] )
    return true;
  return false;
}

function isLastChild (folder) {
  var last = folder.parentObj.nChildren - 1;
  if ( folder == folder.parentObj.children[last] )
    return true;
  return false;
}

function canExpand (folder) {
  // the folder can expand if it has children and if it
  // is not completely expanded already
  if(!folder.children)
    return false;

  if(folder.children && !folder.isOpen)
    return true;

  for ( var i = 0; i < folder.nChildren; i++ ) {
    var child = folder.children[i];
    if ( typeof child.setState != "undefined" ) { // look only in folders
      if ( !child.isOpen ) {
        return true;
      }
      else {
       if ( canExpand(child) )
         return true;
      }
    }
    // skip non-folders
  }
  return false;
}

function op () {};
