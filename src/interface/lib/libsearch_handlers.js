function selectNode(nodeID) {
  document.searchform.category.value = node[nodeID].category;
  highlightObjLink(node[nodeID]);
}

function preprocess () {
  var anchors = document.body.getElementsByTagName("A");
  for ( var i = 0; i < anchors.length; i++ ) {
    if(anchors[i].id.match(/itemTextLink/)
       && (anchors[i].style.color === HIGHLIGHT_COLOR
       || anchors[i].style.color === '#ffffff') ) {
      var href = anchors[i].href;
      href = href.replace(/\D+/g, "");
      //      alert('Selected: ' + anchors[i].id + ', ' + href);
      document.searchform.category.value = node[href].category;
      return true;
    }
  }

  // no selection
  document.searchform.category.value = 'all';
  return true;
}

function initForm() {}
function handleFolderOpening (node) {}
function handleFolderClosing (node) {}
function op() {}
