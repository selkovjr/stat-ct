// $Id: eval_handlers.js,v 2.16 2013/07/08 12:57:33 stat Exp $

// Create a YUI sandbox on your page.
YUI({
  // http://carisenda.com/blog/2011/yui3-local.html
  combine: true,
  filter: 'raw',
  base: '/combo/lib/?/yui3/build/',
  comboBase: '/combo/lib/?/',
  root: 'yui3/build/'
}).use('node', 'event', function (Y) {

  function resetNode(nodeID) {
    var idBase = 'rating_' + nodeID + '_';
    var baseExpr = new RegExp(idBase);
    var spans = document.body.getElementsByTagName("SPAN");
    for(var i = 0; i < spans.length; i++) {
      if(spans[i].id.match(baseExpr)) {
        if ( spans[i].id.match(/-1$/) ) {
          // if this span is [NP], remove the select control
          if(spans[i].className == 'depressed') {
            spans[i].parentNode.removeChild(document.getElementById(idBase + 'np'));
          }
        }
        spans[i].className = 'raised l' + node[nodeID].level;
      }
    }
    node[nodeID].rating = null;
  }

  function setNodeValue(nodeID, value) {
    // find the span object for this nodeID and value
    var idBase = 'rating_' + nodeID + '_';
    var buttonSpan = document.getElementById(idBase + value);

    // create a select control if this is an 'NP' span in the raised state
    if ( buttonSpan.id.match(/-1$/) && buttonSpan.className.match(/raised/) ) {
      var listbox = document.createElement('select');
      listbox.id = listbox.name = idBase + 'np';
      buttonSpan.parentNode.insertBefore(listbox, buttonSpan.nextSibling);
      buttonSpan.style.marginRight = '0';
      listbox.style.verticalAlign = 'middle';
      listbox.style.marginRight = '6px';
      for ( var i = 0; i < reasons.length; i++ ) {
        // reasons and reasonText are defined by the mason component using the tree
        listbox.options[i] = new Option ( reasonText[reasons[i]], reasons[i]);
      }
    }
    else {
      // restore margin previously reset by the above case
      var npButtonSpan =  document.getElementById(idBase + rating_np);
      if ( npButtonSpan )
        npButtonSpan.style.marginRight = '6px';
    }

    buttonSpan.className = 'depressed';

    node[nodeID].rating = value;
    // validate(); -- this was useful in displaying the live average
  }

  function cascadeSetting(folder, value) {
    if ( folder.isOpen ) {
      for ( var i = 0; i < folder.nChildren; i++)  {
        var child = folder.children[i];
        // don't cascade into the closed folders or optional items
        if ( child.children && child.isOpen && !child.opt) {
          cascadeSetting(child, value);
        }
        else {
          // don't cascade into optional // Non-Participatory
          if ( value != null && !child.opt ) {
            resetNode(child.xID);
            setNodeValue(child.xID, value);
          }
        }
      }
    }

    // change state in this node
    resetNode(folder.xID);
    if ( value != null)
      setNodeValue(folder.xID, value);
  }

  STAT.buttonPush = function(buttonSpan, nodeID) {
    var folder = node[nodeID];
    var id = buttonSpan.id.split('_');
    upwardReset(folder);
    if ( folder.label == 'Organ Resection Phase' || folder.label == 'Peritonectomy Phase') {
      // this must have something to do with HIPEC
      setNodeValue(folder.xID, id[2]);
    }
    else {
      cascadeSetting(folder, id[2]);
    }
  };

  function upwardReset(node) {
    resetNode(node.xID);
    var parent = node.parentObj;
    if ( parent.rating )
      upwardReset(parent);
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

  STAT.toggleText = function(folder) {
    if (folder.isOpen) {
      parent.clickOnNodeObj(folder);
    }
    else {
      expandAll(folder);
    }
  }


  STAT.toggleButton = function(buttonSpan) {
    var
      idFrag = buttonSpan.id.split('_'),
      value = idFrag.pop(),
      inputID = idFrag.join('_'),
      listbox,
      node;

    console.log([inputID, value, Y.one(buttonSpan).ancestor()]);

    // create a select control if this is an 'NP' span in the raised state
    if (value === '-1' && buttonSpan.className.match(/raised/)) {
      listbox = document.createElement('select');
      listbox.id = listbox.name = inputID + '_np';
      buttonSpan.parentNode.insertBefore(listbox, buttonSpan.nextSibling);
      buttonSpan.style.marginRight = '0';
      listbox.style.marginLeft = '6px';
      for ( var i = 0; i < reasons.length; i++ ) {
        // reasons and reasonText are defined by the mason component using the tree
        listbox.options[i] = new Option ( reasonText[reasons[i]], reasons[i]);
      }
    }
    else {
      // restore margin previously reset by the above case
      var npButtonSpan =  document.getElementById(inputID + '_np');
      if ( npButtonSpan ) {
        npButtonSpan.style.marginRight = '6px';
      }
    }

    node = Y.one(buttonSpan).ancestor().one('.depressed');
    if (node) {
      node.removeClass('depressed');
      node.addClass('raised');

      if (node.get('id').match(/-1$/)) {
        Y.Node.getDOMNode(node).parentNode.removeChild(document.getElementById(inputID + '_np'));
      }
    }

    Y.one(buttonSpan).removeClass('raised');
    Y.one(buttonSpan).addClass('depressed');

    Y.one('#' + inputID).set('value', value);
  };

  STAT.initForm = function() {
    // Open the first-level child nodes.
    for ( var i = 0; i < foldersTree.nChildren; i++ ) {
      var child = foldersTree.children[i];
      if ( navigator.appName.match(/microsoft|msie/i) ) {
        // This is based on the assumption that the tree starts with
        // all folders open, so it opens to the first level in two clicks
        // on each child of foldersTree.

        // Starting with the tree completely open is necessary to
        // apply MSIE behaviors in csshover.htc, which fixes its
        // inability to apply hover styles to button spans

        // Make sure that STARTALLOPEN is set in activity_tree.js.mason
        if ( child.isOpen ) {
          parent.clickOnNodeObj(child);
          if (STAT.application === 'ct') {
            // Dr. Ferguson initially wanted all parent nodes except Overall compressed.
            // Now that he has changded his mind, only the case-specific notes are
            // left compressed, but I will wait before I change this code.
            if (child.label && child.label.match(/Component|Overall|General|remarks/)) {
              parent.clickOnNodeObj(child);
            }
          }
          else {
            parent.clickOnNodeObj(child);
          }
        }
      }
      else {
        // all other browsers simply need to open the children
        if ( !child.isOpen ) {
          if (STAT.application === 'ct') {
            // Dr. Ferguson initially wanted all parent nodes except Overall compressed.
            // Now that he has changded his mind, only the case-specific notes are
            // left compressed, but I will wait before I change this code.
            if (child.label && child.label.match(/Component|Overall|General|remarks/)) {
              parent.clickOnNodeObj(child);
            }
          }
          else {
            // For everybody else, expand all of them to the first level
            parent.clickOnNodeObj(child);
          }
        }
      }
    }
  }


  STAT.handleFolderOpening = function(folder) {
    var pearl = document.getElementById("pearl_" + folder.xID);
    if ( pearl ) {
      // can't have pearl buttons in children whithout having one in parent
      if ( folder.hasPearls ) pearl.className = "blackpearl";
      else pearl.className = "pearl";

      // now I need to check the pearl status of children
      for ( var i = 0; i < folder.nChildren; i++)  {
        var child = folder.children[i];
        pearl = document.getElementById("pearl_" + child.xID);
        if ( child.hasPearls ) {
          pearl.className = "blackpearl";
        }
        else {
          if ( !child.isOpen ) {
            if ( child.containsPearls ) pearl.className = "blackpearl";
            else pearl.className = "pearl";
          }
        }
      }
    }

    if ( folder.rating && folder.label != 'Organ Resection Phase' && folder.label != 'Peritonectomy Phase' ) {
      // all we have to do here is pass the current folder
      // value to immediate descendants (no cascading)
      for ( var i = 0; i < folder.nChildren; i++)  {
        var child = folder.children[i];
        if ( !child.opt ) {
          resetNode(child.xID);
          setNodeValue(child.xID, folder.rating);
        }
      }
    }
  };


  STAT.handleFolderClosing = function(folder) {
    var pearl = document.getElementById("pearl_" + folder.xID);
    if ( pearl ) {
      // can't have pearl buttons in children whithout having one in parent
      if ( folder.containsPearls ) pearl.className = "blackpearl";
      else pearl.className = "pearl";
    }
  };

  function entirelyNP (folder) {
    if ( folder.rating == -1 )
      return true;

    if ( folder.children ) {
      for ( var i = 0; i < folder.nChildren; i++ ) {
        var child = folder.children[i];

        if ( !entirelyNP(child) )
          return false;
      }
      return true;
    }
    else {
      return false;
    }
  }

  function folderValue (folder) {
    // compute the average of all values in this folder

    if ( folder.rating == -1 )
      return null; // the entire folder is non-participatory

    if ( folder.rating )
      return parseInt(folder.rating); // if the folder is set, children don't matter

    // the folder has no value; examine children
    var avg = null;
    var n = 0;
    for ( var i = 0; i < folder.nChildren; i++ ) {
      var child = folder.children[i];
      var value;

      if ( child.rating == -1 )
        continue;

      if ( child.rating ) {
        value = parseInt(child.rating);
      }
      else {
        value = folderValue(child);
        if ( !value ) continue;
      }

      n += 1;
      avg = ((n - 1)*avg + value)/n;
    }
    return avg;
  }

  function validate (complain) {
    // The complain argument, if set to true, will make the browser open
    // a popup and quit. If absent or set to false, will traverse the
    // tree in the same manner, but will calculate the grade average
    // while doing that (useful in finding out whether a subtree has a
    // non-null value)

    // First, verify that each of the immediate children of the top
    // categories (2nd level) has a non-null value
    var avg = 0;
    var n = 0;
    for ( var t = 0; t < foldersTree.nChildren; t++ ) {
      var top = foldersTree.children[t];
      if ( !top.xID.match(/^[0-9]+$/) ) {
        if ( top.xID.match(/overall/i) && complain ) {
          var value = folderValue(top);
          if ( typeof(value) == 'undefined' || value == null ) {
            alert('Please enter ' + top.label);
            return false;
          }
        }
        else {
          continue; // other non-numeric ids are of no interest as they
                    // have no values
        }
      }
      else {
        // General and Specific have a non-numeric xID

        if (STAT.application !== 'ct') {
          // Dr. Ferguson does not want regular STAT assessments
          for ( var f = 0; f < top.nChildren; f++ ) {
            var folder = top.children[f];
            var value = folderValue(folder);
            if ( typeof(value) == 'undefined' || value == null ) {
              if ( complain
             && !entirelyNP(folder)
             && folder.label != 'Organ Resection Phase' // HIPEC exceptions
             && folder.label != 'Peritonectomy Phase'
             ) {
                alert('Please assess "' + folder.label + '" or its details');
                folder.forceOpeningOfAncestorFolders();
                return false;
              }
              else {
                continue;
              }
            }
            n += 1;
            avg = ((n - 1)*avg + value)/n;
          }
        }
      }
    }
    // this element no longer exists -- that's where the live average was displayed
    // document.getElementById('overall_display').childNodes[0].nodeValue = '(' + avg.toFixed(2) + ')   ';

    // Then, if it's a validation call, determine whether all mandatory assessments
    // have been made
    if ( complain ) {
      for ( var nodeID in required ) {
        if ( folderValue(node[nodeID]) == null && !entirelyNP(node[nodeID]) ) {
          alert('Assessment is required for:\n' + required[nodeID]);
          node[nodeID].forceOpeningOfAncestorFolders();
          return false;
        }
      }
    }

    return true;
  }


  STAT.preprocess = function() {
    // scan the emulated toggle buttons to record the values
    // of those which are depressed
    var arraySpans = document.body.getElementsByTagName("SPAN");
    for ( var i = 0; i < arraySpans.length; i++ ) {
      var id = arraySpans[i].id.split('_');
      var ratingID = id[0] + '_' + id[1];
      if ( arraySpans[i].className == 'depressed' ) {
        var grade = document.getElementById(ratingID);
        grade.value = id[2];
      }
    }

    if (validate(true)) {
      Y.each(Y.all('.suggestion-collector'), function (input) {
        if (input.get('value') === input.get('defaultValue')) {
          input.set('value', '');
        }
      });
      return true;
    };
    return false;
  };

  function op () {};

  Y.one(".ferguson_components").delegate('focus', function (e) {
    if (e.target.get('value') === e.target.get('defaultValue')) {
        e.target.set('value', '');
    }
  }, 'input.suggestion-collector');

  Y.one(".ferguson_components").delegate('blur', function (e) {
    if (e.target.get('value') === '') {
      e.target.set('value', e.target.get('defaultValue'));
    }
  }, 'input.suggestion-collector');
});

