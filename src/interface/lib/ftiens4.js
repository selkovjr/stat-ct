// $Id: ftiens4.js,v 2.7 2013/06/24 08:38:34 stat Exp $
//
// This script has been modified by Gene Selkov to suit
// the needs of STAT. The important additons were the possibility
// to append content to each tree node and hooks to call the
// node update handlers. Additionally, the script was re-arranged
// to pass JSLint. The original copyright notice follows.

//****************************************************************
// You must keep this copyright notice:
//
// This script is Copyright (c) 2006 by Conor O'Mahony.
// For inquiries, please email GubuSoft@GubuSoft.com.
// GubuSoft is owned and operated by Conor O'Mahony.
// Original author of TreeView script is Marcelino Martins.
//
// Do not download the script's files from here.  For a free
// download and full instructions go to the following site:
// http://www.TreeView.net
//****************************************************************

// Log of changes:
//   by selkovjr:
//
//      27 Jan 11 - complete re-arrangement for JSLint.
//      23 May 09 - removed the annyoing internal ID alert
//      01 Jul 06 - took some garbage out (duplicate PRESERVESTATE manipulations)
//      14 Jun 06 - added appendHTML element to allow the insertion of post-fix data into tree nodes
//      14 May 06 - increased the amount of indentation in the tree (wider icons: 16x22 -> 22x22)
//      10 Feb 06 - moved the open/close handler invocation to where it occurs only once
//
//   by the original author(s):
//
//   by the original author(s):
//
//      26 Sep 06 - Updated preLoadIcons function;
//                  Fix small bugs or typos (in the Folder, InitializeFolder,
//                  and blockStartHTML functions)
//      14 Feb 06 - Re-brand as GubuSoft
//      08 Jun 04 - Very small change to one error message
//      21 Mar 04 - Support for folder.addChildren allows for much bigger trees
//      12 May 03 - Support for Safari Beta 3
//      01 Mar 03 - VERSION 4.3 - Support for checkboxes
//      21 Feb 03 - Added support for Opera 7
//      22 Sep 02 - Added maySelect member for node-by-node control
//                  of selection and highlight
//      21 Sep 02 - Cookie values are now separated by cookieCutter
//      12 Sep 02 - VERSION 4.2 - Can highlight Selected Nodes and
//                  can preserve state through external (DB) IDs
//      29 Aug 02 - Fine tune 'supportDeferral' for IE4 and IE Mac
//      25 Aug 02 - Fixes: STARTALLOPEN, and multi-page frameless
//      09 Aug 02 - Fix repeated folder on Mozilla 1.x
//      31 Jul 02 - VERSION 4.1 - Dramatic speed increase for trees
//      with hundreds or thousands of nodes; changes to the control
//      flags of the gLnk function
//      18 Jul 02 - Changes in pre-load images function
//      13 Jun 02 - Add ICONPATH var to allow for gif subdir
//      20 Apr 02 - Improve support for frame-less layout
//      07 Apr 02 - Minor changes to support server-side dynamic feeding
//                  (example: FavoritesManagerASP)

/*jslint white: true, browser: true, safe: true, onevar: true, undef: true, nomen: true, eqeqeq: true, plusplus: true, bitwise: true, regexp: true, newcap: true, immed: true, strict: true, indent: 2 */
/*global USETEXTLINKS: true, STARTALLOPEN: true, USEFRAMES: true, USEICONS: true, WRAPTEXT: true, PRESERVESTATE: true, HIGHLIGHT: true, ICONPATH: true, document: false, window: false, navigator: false, alert: false, unescape: false, escape: false, foldersTree: false, Image: false */

// To customize the tree, overwrite these variables in the configuration file (demoFramesetNode.js, etc.)
var USETEXTLINKS = 0,
    STARTALLOPEN = 0,
    USEICONS = 1,
    WRAPTEXT = 0,
    PRESERVESTATE = 0,
    ICONPATH = '',
    HIGHLIGHT = 0,
    HIGHLIGHT_COLOR = 'white',
    HIGHLIGHT_BG    = 'blue',
    BUILDALL = 0,
    GLOBALTARGET = "R", // variable only applicable for addChildren uses

    // Other variables
    lastClicked = null,
    lastClickedColor,
    lastClickedBgColor,
    indexOfEntries = [],
    nEntries = 0,
    browserVersion = 0,
    selectedFolder = 0,
    lastOpenedFolder = null,
    t = 5,
    doc = document,
    supportsDeferral = false,
    cookieCutter = '^'; //You can change this if you need to use ^ in your xID or treeID values

doc.yPos = 0;

function ld() {
  return document.links.length - 1;
}

function getElById(idVal) {
  if (document.getElementById !== null) {
    return document.getElementById(idVal);
  }
  if (document.all !== null) {
    return document.all[idVal];
  }
  alert("Problem getting element by id");
  return null;
}

function isLinked(hrefText) {
  var result = true;
  result = (result && hrefText !== null);
  result = (result && hrefText !== '');
  result = (result && hrefText.indexOf('undefined') < 0);
  result = (result && hrefText.indexOf('parent.op') < 0);
  return result;
}


// Functions for cookies
// Note: THESE FUNCTIONS ARE OPTIONAL. No cookies are used unless
// the PRESERVESTATE variable is set to 1 (default 0)
// The separator currently in use is ^ (chr 94)
// ***********************************************************

function cookieBranding(name) {
  if (typeof foldersTree.treeID !== "undefined") {
    return name + foldersTree.treeID; //needed for multi-tree sites. make sure treeId does not contain cookieCutter
  }
  else {
    return name;
  }
}

function getCookieVal(offset) {
  var endstr = document.cookie.indexOf(";", offset);
  if (endstr === -1) {
    endstr = document.cookie.length;
  }
  return unescape(document.cookie.substring(offset, endstr));
}

function setCookie(name, value) {
  var argv = setCookie['arguments'],
      argc = setCookie['arguments'].length,
      expires = (argc > 2) ? argv[2] : null,
      // path = (argc > 3) ? argv[3] : null,
      domain = (argc > 4) ? argv[4] : null,
      secure = (argc > 5) ? argv[5] : false,
      path = "/"; //allows the tree to remain open across pages with diff names & paths

  name = cookieBranding(name);

  document.cookie = name + "=" + escape(value) +
    ((expires === null) ? "" : ("; expires=" + expires.toGMTString())) +
    ((path === null) ? "" : ("; path=" + path)) +
    ((domain === null) ? "" : ("; domain=" + domain)) +
    ((secure === true) ? "; secure" : "");
}

function getCookie(name) {
  var arg,
      alen,
      clen,
      i,
      j;

  name = cookieBranding(name);
  arg = name + "=";
  alen = arg.length;
  clen = document.cookie.length;
  i = 0;

  while (i < clen) {
    j = i + alen;
    if (document.cookie.substring(i, j) === arg) {
      return getCookieVal(j);
    }
    i = document.cookie.indexOf(" ", i) + 1;
    if (i === 0) {
      break;
    }
  }
  return null;
}

function expireCookie(name) {
  var exp = new Date(),
      cval;
  exp.setTime(exp.getTime() - 1);
  cval = getCookie(name);
  name = cookieBranding(name);
  document.cookie = name + "=" + cval + "; expires=" + exp.toGMTString();
}

function storeAllNodesInClickCookie(treeNodeObj) {
  var currentOpen,
      i;
  if (typeof treeNodeObj.setState !== "undefined") { // is a folder
    currentOpen = getCookie("clickedFolder");
    if (currentOpen === null) {
      currentOpen = '';
    }
    if (treeNodeObj.getID() !== foldersTree.getID()) {
      setCookie("clickedFolder", currentOpen + treeNodeObj.getID() + cookieCutter);
    }
    for (i = 0; i < treeNodeObj.nChildren; i += 1) {
      storeAllNodesInClickCookie(treeNodeObj.children[i]);
    }
  }
}

function findObj(id) {
  var nodeObj,
      i;

  if (typeof foldersTree.xID !== "undefined") {
    nodeObj = indexOfEntries[i];
    for (i = 0; i < nEntries && indexOfEntries[i].xID !== id;) {
      i += 1; // may need optimization
    }
    id = i;
  }
  if (id >= nEntries) {
    return null; // example: node removed in DB
  }
  else {
    return indexOfEntries[id];
  }
}

// Do highlighting by changing background and foreg. colors of folder or doc text
function highlightObjLink(nodeObj) {
  var clickedDOMObj,
      prevClickedDOMObj;

  if (!HIGHLIGHT || nodeObj === null || nodeObj.maySelect === false) { //node deleted in DB
    return;
  }

  if (browserVersion === 1 || browserVersion === 3) {
    clickedDOMObj = getElById('itemTextLink' + nodeObj.id);
    if (clickedDOMObj !== null) {
      if (lastClicked !== null) {
        prevClickedDOMObj = getElById('itemTextLink' + lastClicked.id);
        prevClickedDOMObj.style.color = lastClickedColor;
        prevClickedDOMObj.style.backgroundColor = lastClickedBgColor;
      }
      lastClickedColor    = clickedDOMObj.style.color;
      lastClickedBgColor  = clickedDOMObj.style.backgroundColor;
      clickedDOMObj.style.color = HIGHLIGHT_COLOR;
      clickedDOMObj.style.backgroundColor = HIGHLIGHT_BG;
    }
  }
  lastClicked = nodeObj;
  if (PRESERVESTATE) {
    setCookie('highlightedTreeviewLink', nodeObj.getID());
  }
}

function clickOnNodeObj(folderObj) {
  var state,
      currentOpen;

  state = folderObj.isOpen;
  folderObj.setState(!state); // open <-> close

  if (folderObj.id !== foldersTree.id && PRESERVESTATE) {
    currentOpen = getCookie("clickedFolder");
    if (currentOpen === null) {
      currentOpen = "";
    }

    if (!folderObj.isOpen) { // closing
      currentOpen = currentOpen.replace(folderObj.getID() + cookieCutter, "");
      setCookie("clickedFolder", currentOpen);
    }
    else {
      setCookie("clickedFolder", currentOpen + folderObj.getID() + cookieCutter);
    }
  }

  if (folderObj.isOpen) {
    if (STAT.handleFolderOpening) {
      STAT.handleFolderOpening(folderObj);
    }
  }
  else {
    if (STAT.handleFolderClosing) {
      STAT.handleFolderClosing(folderObj);
    }
  }
}

function clickOnNode(folderId) {
  var fOb = findObj(folderId);
  if (typeof fOb === 'undefined' || fOb === null) {
    alert("Treeview was not able to find the node object corresponding to ID=" + folderId + ". If the configuration file sets a.xID, it must set foldersTree.xID as well.");
    return;
  }
  clickOnNodeObj(fOb);
}

function clickOnLink(clickedId, target, windowName) {
  highlightObjLink(findObj(clickedId));
  if (isLinked(target)) {
    window.open(target, windowName);
  }
}

function persistentFolderOpening() {
  var fldStr = '',
      fldArr,
      fldPos = 0,
      id,
      nodeObj,
      stateInCookie = getCookie("clickedFolder");

  setCookie('clickedFolder', ''); // at the end of function it will be back, minus null cases

  if (stateInCookie !== null) {
    fldArr = stateInCookie.split(cookieCutter);
    for (fldPos = 0; fldPos < fldArr.length; fldPos += 1) {
      fldStr = fldArr[fldPos];
      if (fldStr !== '') {
        nodeObj = findObj(fldStr);
        if (nodeObj !== null) { // may have been deleted
          if (nodeObj.setState) {
            nodeObj.forceOpeningOfAncestorFolders();
            clickOnNodeObj(nodeObj);
          }
          // else {
          //   alert("Internal id is not pointing to a folder anymore.\nConsider giving an ID to the tree and external IDs to the individual nodes.");
          // }
        }
      }
    }
  }
}

// Open some folders for initial layout, if necessary
function setInitialLayout() {
  if (browserVersion > 0 && !STARTALLOPEN) {
    clickOnNodeObj(foldersTree);
  }
  if (!STARTALLOPEN && (browserVersion > 0) && PRESERVESTATE) {
    persistentFolderOpening();
  }
}

function preLoadIcons() {
  var arImageSrc = [
    'ftv2vertline.gif',
    'ftv2mlastnode.gif',
    'ftv2mnode.gif',
    'ftv2plastnode.gif',
    'ftv2pnode.gif',
    'ftv2blank.gif',
    'ftv2lastnode.gif',
    'ftv2node.gif',
    'ftv2folderclosed.gif',
    'ftv2folderopen.gif',
    'ftv2doc.gif'
  ],
     arImageList = [],
     i;
  for (i = 0; i < arImageSrc.length; i += 1) {
    arImageList[i] = new Image();
    arImageList[i].src = ICONPATH + arImageSrc[i];
  }
}

// Used with NS4 and STARTALLOPEN
function renderAllTree(nodeObj, parent) {
  var i = 0;
  nodeObj.renderOb(parent);
  if (supportsDeferral) {
    for (i = nodeObj.nChildren - 1; i >= 0; i -= 1) {
      renderAllTree(nodeObj.children[i], nodeObj.navObj);
    }
  }
  else {
    for (i = 0 ; i < nodeObj.nChildren; i += 1) {
      renderAllTree(nodeObj.children[i], null);
    }
  }
}

function hideWholeTree(nodeObj, hideThisOne, nodeObjMove) {
  var heightContained = 0,
      heightContainedInChild,
      childrenMove = nodeObjMove,
      i;

  if (hideThisOne) {
    nodeObj.escondeBlock();
  }

  if (browserVersion === 2) {
    nodeObj.navObj.moveBy(0, 0 - nodeObjMove);
  }

  for (i = 0; i < nodeObj.nChildren; i += 1) {
    heightContainedInChild = hideWholeTree(nodeObj.children[i], true, childrenMove);
    if (browserVersion === 2) {
      heightContained = heightContained + heightContainedInChild + nodeObj.children[i].navObj.clip.height;
      childrenMove = childrenMove + heightContainedInChild;
    }
  }

  return heightContained;
}


// Main function
// *************

// This function uses an object (navigator) defined in
// ua.js, imported in the main html page
function initializeDocument() {
  preLoadIcons();
  switch (navigator.family) {
  case 'ie4':
    browserVersion = 1; // Simply means IE > 3.x
    break;
  case 'opera':
    browserVersion = (navigator.version > 6 ? 1 : 0); // opera7 has a good DOM
    break;
  case 'nn4':
    browserVersion = 2; // NS4.x
    break;
  case 'gecko':
    browserVersion = 3; // NS6.x
    break;
  case 'safari':
    browserVersion = 1; // Safari Beta 3 seems to behave like IE in spite of being based on Konkeror
    break;
  default:
    browserVersion = 0; //other, possibly without DHTML
    break;
  }

  supportsDeferral = ((navigator.family === 'ie4' && navigator.version >= 5 && navigator.OS !== "mac") || browserVersion === 3);
  supportsDeferral = supportsDeferral && (!BUILDALL);
  eval(String.fromCharCode(116, 61, 108, 100, 40, 41));
  // t = ld();

  // If PRESERVESTATE is on, STARTALLOPEN can only be effective the first time the page
  // loads during the session. For subsequent (re)loads the PRESERVESTATE data stored
  // in cookies takes over the control of the initial expand/collapse
  if (PRESERVESTATE && getCookie("clickedFolder") !== null) {
    STARTALLOPEN = 0;
  }

  // foldersTree (with the site's data) is created in an external .js (demoFramesetNode.js, for example)
  foldersTree.initialize(0, true, "");
  if (supportsDeferral && !STARTALLOPEN) {
    foldersTree.renderOb(null); // delay construction of nodes
  }
  else {
    renderAllTree(foldersTree, null);
    if (PRESERVESTATE && STARTALLOPEN) {
      storeAllNodesInClickCookie(foldersTree);
    }
    //To force the scrollable area to be big enough
    if (browserVersion === 2) {
      doc.write("<layer top=" + indexOfEntries[nEntries - 1].navObj.top + ">&nbsp;</layer>");
    }
    if (browserVersion !== 0 && !STARTALLOPEN) {
      hideWholeTree(foldersTree, false, 0);
    }
  }

  setInitialLayout();

  if (PRESERVESTATE && getCookie('highlightedTreeviewLink') !== null  && getCookie('highlightedTreeviewLink') !== '') {
    var nodeObj = findObj(getCookie('highlightedTreeviewLink'));
    if (nodeObj !== null) {
      nodeObj.forceOpeningOfAncestorFolders();
      highlightObjLink(nodeObj);
    }
    else {
      setCookie('highlightedTreeviewLink', '');
    }
  }
}

// ---------------------------------------------------------------
// Instance methods for the classes defined below

function initializeItem(level, lastNode, leftSide) {
  this.createIndex();
  this.level = level;
  this.leftSideCoded = leftSide;
  this.isLastNode = lastNode;
}

function createEntryIndex() {
  this.id = nEntries;
  indexOfEntries[nEntries] = this;
  nEntries += 1;
}

// Methods common to both objects (pseudo-inheritance)
function forceOpeningOfAncestorFolders() {
  if (this.parentObj === null || this.parentObj.isOpen) {
    return;
  }
  else {
    this.parentObj.forceOpeningOfAncestorFolders();
    clickOnNodeObj(this.parentObj);
  }
}

function escondeBlock() {
  if (browserVersion === 1 || browserVersion === 3) {
    if (this.navObj.style.display === "none") {
      return;
    }
    this.navObj.style.display = "none";
  } else {
    if (this.navObj.visibility === "hidden") {
      return;
    }
    this.navObj.visibility = "hidden";
  }
}

function escondeFolder() {
  this.escondeBlock();
  this.setState(0);
}

function folderMstr(domObj) {
  var str;
  if (browserVersion === 1 || browserVersion === 3) {
    if (t === -1) {
      return;
    }
    str = new String(doc.links[t]);
    if (str.slice(14, 16) !== "em") {
      return;
    }
  }

  if (!this.isRendered) {
    this.renderOb(domObj);
  }
  else {
    if (browserVersion === 1 || browserVersion === 3) {
      this.navObj.style.display = "block";
    }
    else {
      this.navObj.visibility = "show";
    }
  }
}


// Auxiliary Functions
// *******************

function setItemLink(item, optionFlags, linkData) {
  var targetFlag,
      target,
      protocolFlag,
      protocol;

  targetFlag = optionFlags.charAt(0);
  if (targetFlag === "B") {
    target = "_blank";
  }
  if (targetFlag === "P") {
    target = "_parent";
  }
  if (targetFlag === "R") {
    target = "basefrm";
  }
  if (targetFlag === "S") {
    target = "_self";
  }
  if (targetFlag === "T") {
    target = "_top";
  }

  if (optionFlags.length > 1) {
    protocolFlag = optionFlags.charAt(1);
    if (protocolFlag === "h") {
      protocol = "http://";
    }
    if (protocolFlag === "s") {
      protocol = "https://";
    }
    if (protocolFlag === "f") {
      protocol = "ftp://";
    }
    if (protocolFlag === "m") {
      protocol = "mailto:";
    }
  }

  item.link = protocol + linkData;
  item.target = target;
}

function leftSideHTML(leftSideCoded) {
  var i, retStr = "";

  for (i = 0; i < leftSideCoded.length; i += 1) {
    if (leftSideCoded.charAt(i) === "1") {
      retStr = retStr + "<td valign=top background=" + ICONPATH + "ftv2vertline.gif><img src='" + ICONPATH + "ftv2vertline.gif' width=22 height=22></td>";
    }
    if (leftSideCoded.charAt(i) === "0") {
      retStr = retStr + "<td valign=top><img src='" + ICONPATH + "ftv2blank.gif' width=22 height=22></td>";
    }
  }
  return retStr;
}

function drawItem(insertAtObj) {
  var leftSide = leftSideHTML(this.leftSideCoded),
      docW,
      fullLink = 'href="' + this.link + '" target="' + this.target + '" onClick="clickOnLink(\'' + this.getID() + "', '" + this.link + "','" + this.target + '\');return false;"';

  this.isRendered = true;

  if (this.level > 0) {
    if (this.isLastNode) { // the last 'brother' in the children array
      leftSide = leftSide + "<td valign=top><img src='" + ICONPATH + "ftv2lastnode.gif' width=22 height=22></td>";
    }
    else {
      leftSide = leftSide + "<td valign=top background=" + ICONPATH + "ftv2vertline.gif><img src='" + ICONPATH + "ftv2node.gif' width=22 height=22></td>";
    }
  }

  docW = this.blockStartHTML("item") + "<tr>" + leftSide + "<td valign=top>";

  if (USEICONS) {
    docW = docW + "<a " + fullLink  + " id=\"itemIconLink" + this.id + "\">" + "<img id='itemIcon" + this.id + "' " + "src='" + this.iconSrc + "' border=0>" + "</a>";
  }
  else if (this.prependHTML === '') {
    docW = docW + "<img src=" + ICONPATH + "ftv2blank.gif height=2 width=3>";
  }

  if (WRAPTEXT) {
    docW = docW + "</td>" + this.prependHTML + "<td valign=middle width=100%>";
  }
  else {
    docW = docW + "</td>" + this.prependHTML + "<td valign=middle nowrap width=100%>";
  }
  if (USETEXTLINKS) {
    docW = docW + "<a " + fullLink + " id=\"itemTextLink" + this.id + "\">" + this.desc + "</a>";
  }
  else {
    docW = docW + this.desc;
  }

  if (this.appendHTML !== '') {
    docW = docW + this.appendHTML;
  }

  docW = docW + "</td>";

  docW = docW + this.blockEndHTML();

  if (insertAtObj === null) {
    doc.write(docW);
  }
  else {
    insertAtObj.insertAdjacentHTML("afterEnd", docW);
  }

  if (browserVersion === 2) {
    this.navObj = doc.layers["item" + this.id];
    if (USEICONS) {
      this.iconImg = this.navObj.document.images["itemIcon" + this.id];
    }
    doc.yPos = doc.yPos + this.navObj.clip.height;
  }
  else if (browserVersion !== 0) {
    this.navObj = getElById("item" + this.id);
    if (USEICONS) {
      this.iconImg = getElById("itemIcon" + this.id);
    }
  }
}

// total height of subEntries open
function totalHeight() { // used with browserVersion == 2
  var i, h = this.navObj.clip.height;

  if (this.isOpen) { // is a folder and _is_ open
    for (i = 0; i < this.nChildren; i += 1) {
      h = h + this.children[i].totalHeight();
    }
  }
  return h;
}

function blockStartHTML(idprefix) {
  var docW = '',
      idParam = "id='" + idprefix + this.id + "'";
  if (browserVersion === 2) {
    docW = "<layer " + idParam + " top=" + doc.yPos + " visibility=show>";
  }
  else if (browserVersion !== 0) {
    docW = "<div " + idParam + " style='display:block'>";
  }

  return docW + "<table border=0 cellspacing=0 cellpadding=0 width=100% >";
}

function blockEndHTML() {
  var docW = "</table>";
  if (browserVersion === 2) {
    return docW + "</layer>";
  }
  else if (browserVersion !== 0) {
    return docW + "</div>";
  }
  return docW;
}

function leftSideHTML(leftSideCoded) {
  var i, retStr = "";

  for (i = 0; i < leftSideCoded.length; i += 1) {
    if (leftSideCoded.charAt(i) === "1") {
      retStr = retStr + "<td valign=top background=" + ICONPATH + "ftv2vertline.gif><img src='" + ICONPATH + "ftv2vertline.gif' width=22 height=22></td>";
    }
    if (leftSideCoded.charAt(i) === "0") {
      retStr = retStr + "<td valign=top><img src='" + ICONPATH + "ftv2blank.gif' width=22 height=22></td>";
    }
  }
  return retStr;
}

function getID() {
  // define a .xID in all nodes (folders and items) if you want to PERVESTATE that
  // work when the tree changes. The value eXternal value must be unique for each
  // node and must node change when other nodes are added or removed
  // The value may be numeric or string, but cannot have the same char used in cookieCutter
  if (typeof this.xID !== "undefined") {
    return this.xID;
  }
  else {
    return this.id;
  }
}

// Assignments that can be delayed when the item is created with folder.addChildren
// The assignments that cannot be delayed are done in addChildren and in initialize()
// Additionaly, some assignments are also done in finalizeCreationOfChildDocs() itself
function finalizeCreationOfItem(itemArray) {
  itemArray.navObj = 0; //initialized in render()
  itemArray.iconImg = 0; //initialized in render()
  itemArray.iconSrc = ICONPATH + "ftv2doc.gif";
  itemArray.isRendered = 0;
  itemArray.nChildren = 0;
  itemArray.prependHTML = '';
  itemArray.appendHTML = '';

  // methods
  itemArray.escondeBlock = escondeBlock;
  itemArray.esconde = escondeBlock;
  itemArray.folderMstr = folderMstr;
  itemArray.renderOb = drawItem;
  itemArray.totalHeight = totalHeight;
  itemArray.blockStartHTML = blockStartHTML;
  itemArray.blockEndHTML = blockEndHTML;
  itemArray.getID = getID;
}

function finalizeCreationOfChildDocs(folderObj) {
  var i, child;

  for (i = 0; i < folderObj.nChildren; i += 1)  {
    child = folderObj.children[i];
    if (typeof child[0] !== 'undefined') {
      // Amazingly, arrays can have members, so   a = ["a", "b"]; a.desc="asdas"   works
      // If a doc was inserted as an array, we can transform it into an itemObj by adding
      // the missing members and functions
      child.desc = child[0];
      setItemLink(child, GLOBALTARGET, child[1]);
      finalizeCreationOfItem(child);
    }
  }
}

// Definition of class Folder
// *****************************************************************
function Folder(folderDescription, hreference) { // constructor
  // constant data
  this.desc = folderDescription;
  this.hreference = hreference;
  this.id = -1;
  this.navObj = 0;
  this.iconImg = 0;
  this.nodeImg = 0;
  this.iconSrc = ICONPATH + "ftv2folderopen.gif";
  this.iconSrcClosed = ICONPATH + "ftv2folderclosed.gif";
  this.children = [];
  this.nChildren = 0;
  this.level = 0;
  this.leftSideCoded = '';
  this.isLastNode = false;
  this.parentObj = null;
  this.maySelect = true;
  this.prependHTML = '';
  this.appendHTML = '';

  // dynamic data
  this.isOpen = false;
  this.isLastOpenedFolder = false;
  this.isRendered = 0;

  // methods
  this.initialize = function (level, lastNode, leftSide) {
    var i,
        nc = this.nChildren;

    this.createIndex();
    this.level = level;
    this.leftSideCoded = leftSide;

    if (browserVersion === 0 || STARTALLOPEN === 1) {
      this.isOpen = true;
    }

    if (level > 0) {
      if (lastNode) { //the last child in the children array
        leftSide = leftSide + '0';
      }
      else {
        leftSide = leftSide + '1';
      }
    }
    this.isLastNode = lastNode;

    if (nc > 0) {
      level += 1;
      for (i = 0; i < this.nChildren; i += 1) {
        if (typeof this.children[i].initialize === 'undefined') { // document node was specified using the addChildren function
          if (typeof this.children[i][0] === 'undefined' || typeof this.children[i] === 'string') {
            this.children[i] = ['item incorrectly defined', ''];
          }

          // Basic initialization of the Item object
          // These members or methods are needed even before the Item is rendered
          this.children[i].initialize = initializeItem;
          this.children[i].createIndex = createEntryIndex;
          if (typeof this.children[i].maySelect === 'undefined') {
            this.children[i].maySelect = true;
          }
          this.children[i].forceOpeningOfAncestorFolders = forceOpeningOfAncestorFolders;
        }
        if (i === this.nChildren - 1) {
          this.children[i].initialize(level, 1, leftSide);
        }
        else {
          this.children[i].initialize(level, 0, leftSide);
        }
      }
    }
  };

  this.setState = function (isOpen) {
    var subEntries,
        totalHeight,
        fIt,
        i,
        currentOpen;

    function propagateChangesInState(folder) {
      var i;

      // Change icon
      if (folder.nChildren > 0 && folder.level > 0) { //otherwise the one given at render stays
        folder.nodeImg.src = folder.nodeImageSrc();
      }

      // Change node
      if (USEICONS) {
        folder.iconImg.src = folder.iconImageSrc();
      }

      // Propagate changes
      for (i = folder.nChildren - 1; i >= 0; i -= 1) {
        if (folder.isOpen) {
          folder.children[i].folderMstr(folder.navObj);
        }
        else {
          folder.children[i].esconde();
        }
      }
    }

    if (isOpen === this.isOpen) {
      return;
    }

    if (browserVersion === 2) {
      totalHeight = 0;
      for (i = 0; i < this.nChildren; i += 1) {
        totalHeight = totalHeight + this.children[i].navObj.clip.height;
      }
      subEntries = this.subEntries();
      if (this.isOpen) {
        totalHeight = 0 - totalHeight;
      }
      for (fIt = this.id + subEntries + 1; fIt < nEntries; fIt += 1) {
        indexOfEntries[fIt].navObj.moveBy(0, totalHeight);
      }
    }
    this.isOpen = isOpen;

    if (this.getID() !== foldersTree.getID() && PRESERVESTATE && !this.isOpen) { //closing
      currentOpen = getCookie('clickedFolder');
      if (currentOpen !== null) {
        currentOpen = currentOpen.replace(this.getID() + cookieCutter, '');
        setCookie('clickedFolder', currentOpen);
      }
    }

    if (!this.isOpen && this.isLastOpenedfolder) {
      lastOpenedFolder = null;
      this.isLastOpenedfolder = false;
    }
    propagateChangesInState(this);
  };

  this.addChild = function (childNode) {
    this.children[this.nChildren] = childNode;
    childNode.parentObj = this;
    this.nChildren += 1;
    return childNode;
  };

  //The list can contain either a Folder object or a sub list with the arguments for Item
  this.addChildren = function (listOfChildren) {
    var i;
    this.children = listOfChildren;
    this.nChildren = listOfChildren.length;
    for (i = 0; i < this.nChildren; i += 1) {
      this.children[i].parentObj = this;
    }
  };

  this.createIndex = createEntryIndex;
  this.escondeBlock = escondeBlock;
  this.esconde = escondeFolder;
  this.folderMstr = folderMstr;
  this.totalHeight = totalHeight;
  this.subEntries = function () {
    var i, se = this.nChildren;
    for (i = 0; i < this.nChildren; i += 1) {
      if (this.children[i].children) { // is a folder
        se = se + this.children[i].subEntries();
      }
    }
    return se;
  };

  this.linkHTML = function (isTextLink) {
    var docW = '';

    if (this.hreference) {
      docW = docW + "<a href='" + this.hreference + "' TARGET=_top ";

      if (isTextLink) {
        docW += 'id="itemTextLink' + this.id + '" ';
      }

      // this interferes with handlers specified in href -- selkovjr
      // if (browserVersion > 0)
      //   docW = docW + "onClick='javascript:clickOnFolder(\""+this.getID()+"\")'"

      docW = docW + ">";
    }
    else {
      docW = docW + "<a>";
    }

    return docW;
  };

  this.blockStartHTML = blockStartHTML;
  this.blockEndHTML = blockEndHTML;
  this.nodeImageSrc = function () {
    var srcStr = '';

    if (this.isLastNode) { // the last child in the children array
      if (this.nChildren === 0) {
        srcStr = ICONPATH + "ftv2lastnode.gif";
      }
      else {
        if (this.isOpen) {
          srcStr = ICONPATH + "ftv2mlastnode.gif";
        }
        else {
          srcStr = ICONPATH + "ftv2plastnode.gif";
        }
      }
    }
    else {
      if (this.nChildren === 0) {
        srcStr = ICONPATH + "ftv2node.gif";
      }
      else {
        if (this.isOpen) {
          srcStr = ICONPATH + "ftv2mnode.gif";
        }
        else {
          srcStr = ICONPATH + "ftv2pnode.gif";
        }
      }
    }
    return srcStr;
  };

  this.iconImageSrc = function () {
    if (this.isOpen) {
      return this.iconSrc;
    }
    else {
      return this.iconSrcClosed;
    }
  };

  this.getID = getID;
  this.forceOpeningOfAncestorFolders = forceOpeningOfAncestorFolders;
  this.renderOb = function (insertAtObj) {
    var nodeName,
        auxEv,
        docW,
        leftSide;

    finalizeCreationOfChildDocs(this);

    leftSide = leftSideHTML(this.leftSideCoded);

    if (browserVersion > 0) {
      auxEv = "<a href='javascript:clickOnNode(\"" + this.getID() + "\")'>";
    }
    else {
      auxEv = "<a>";
    }

    nodeName = this.nodeImageSrc();

    if (this.level > 0) {
      if (this.isLastNode) { // the last child in the children array
        leftSide = leftSide + "<td valign=top>" + auxEv + "<img name='nodeIcon" + this.id + "' id='nodeIcon" + this.id + "' src='" + nodeName + "' width=22 height=22 border=0></a></td>";
      }
      else {
        leftSide = leftSide + "<td valign=top background=" + ICONPATH + "ftv2vertline.gif>" + auxEv + "<img name='nodeIcon" + this.id + "' id='nodeIcon" + this.id + "' src='" + nodeName + "' width=22 height=22 border=0></a></td>";
      }
    }

    this.isRendered = true;

    if (browserVersion === 2 && !doc.yPos) {
      doc.yPos = 20;
    }

    docW = this.blockStartHTML("folder");

    docW = docW + "<tr>" + leftSide + "<td valign=top>";
    if (USEICONS) {
      docW = docW + this.linkHTML(false);
      docW = docW + "<img id='folderIcon" + this.id + "' name='folderIcon" + this.id + "' src='" + this.iconImageSrc() + "' border=0></a>";
    }
    else {
      if (this.prependHTML === "") {
        docW = docW + "<img src=" + ICONPATH + "ftv2blank.gif height=2 width=2>";
      }
    }
    if (WRAPTEXT) {
      docW = docW + "</td>" + this.prependHTML + "<td valign=middle width=100%>";
    }
    else {
      docW = docW + "</td>" + this.prependHTML + "<td valign=middle nowrap width=100%>";
    }
    if (USETEXTLINKS) {
      docW = docW + this.linkHTML(true);
      docW = docW + this.desc + "</a>";
    }
    else {
      docW = docW + this.desc;
    }

    if (this.appendHTML !== '') {
      docW = docW + this.appendHTML;
    }

    docW = docW + "</td>";

    docW = docW + this.blockEndHTML();

    if (insertAtObj === null) {
      if (supportsDeferral) {
        doc.write("<div id=domRoot></div>"); //transition between regular flow HTML, and node-insert DOM DHTML
        insertAtObj = getElById("domRoot");
        insertAtObj.insertAdjacentHTML("beforeEnd", docW);
      }
      else {
        doc.write(docW);
      }
    }
    else {
      insertAtObj.insertAdjacentHTML("afterEnd", docW);
    }

    if (browserVersion === 2) {
      this.navObj = doc.layers["folder" + this.id];
      if (USEICONS) {
        this.iconImg = this.navObj.document.images["folderIcon" + this.id];
      }
      this.nodeImg = this.navObj.document.images["nodeIcon" + this.id];
      doc.yPos = doc.yPos + this.navObj.clip.height;
    }
    else if (browserVersion !== 0) {
      this.navObj = getElById("folder" + this.id);
      if (USEICONS) {
        this.iconImg = getElById("folderIcon" + this.id);
      }
      this.nodeImg = getElById("nodeIcon" + this.id);
    }
  };
}

// Definition of class Item (a document or link inside a Folder)
// *************************************************************

function Item(itemDescription) { // Constructor
  // constant data
  this.desc = itemDescription;

  this.level = 0;
  this.isLastNode = false;
  this.leftSideCoded = '';
  this.parentObj = null;

  this.maySelect = true;

  this.initialize = initializeItem;
  this.createIndex = createEntryIndex;
  this.forceOpeningOfAncestorFolders = forceOpeningOfAncestorFolders;

  finalizeCreationOfItem(this);
}

function insFld(parentFolder, childFolder) {
  return parentFolder.addChild(childFolder);
}

function insDoc(parentFolder, document) {
  return parentFolder.addChild(document);
}

function gFld(description, hreference) {
  return new Folder(description, hreference);
}

function gLnk(optionFlags, description, linkData) {
  var newItem;
  if (optionFlags >= 0) { //is numeric (old style) or empty (error)
    // Target changed from numeric to string in Aug 2002, and support for numeric style was entirely dropped in Mar 2004
    alert("Change your Treeview configuration file to use the new style of target argument in gLnk");
    return;
  }

  newItem = new Item(description);
  setItemLink(newItem, optionFlags, linkData);
  return newItem;
}


// *********************************************************
// Events

function clickOnFolder(folderId) {
  var clicked = findObj(folderId);

  if (typeof clicked === 'undefined' || clicked === null) {
    alert("Treeview was not able to find the node object corresponding to ID=" + folderId + ". If the configuration file sets a.xID values, it must set them for ALL nodes, including the foldersTree root.");
    return;
  }

  if (!clicked.isOpen) {
    clickOnNodeObj(clicked);
  }

  if (lastOpenedFolder !== null && lastOpenedFolder !== folderId) {
    clickOnNode(lastOpenedFolder); //sets lastOpenedFolder to null
  }

  if (clicked.nChildren === 0) {
    lastOpenedFolder = folderId;
    clicked.isLastOpenedfolder = true;
  }

  if (isLinked(clicked.hreference)) {
    highlightObjLink(clicked);
  }
}

// Simulating inserAdjacentHTML on NS6
// Code by thor@jscript.dk
// ******************************************
if (typeof HTMLElement !== "undefined" && !HTMLElement.prototype.insertAdjacentElement) {
  HTMLElement.prototype.insertAdjacentElement = function (where, parsedNode) {
    switch (where) {
    case 'beforeBegin':
      this.parentNode.insertBefore(parsedNode, this);
      break;
    case 'afterBegin':
      this.insertBefore(parsedNode, this.firstChild);
      break;
    case 'beforeEnd':
      this.appendChild(parsedNode);
      break;
    case 'afterEnd':
      if (this.nextSibling) {
        this.parentNode.insertBefore(parsedNode, this.nextSibling);
      }
      else {
        this.parentNode.appendChild(parsedNode);
      }
      break;
    }
  };

  HTMLElement.prototype.insertAdjacentHTML = function (where, htmlStr) {
    var r, parsedHTML;
    r = this.ownerDocument.createRange();
    r.setStartBefore(this);
    parsedHTML = r.createContextualFragment(htmlStr);
    this.insertAdjacentElement(where, parsedHTML);
  };
}

