// $Id: image_load_handlers.js,v 2.2 2009-02-23 02:13:27 selkovjr Exp $

var image_data = new Object;

function load_one_image(name, src) {
    // create the data structure for this image and hide it from display
    image_data[name] = new Object;
    image_data[name].image = document.getElementById("graph_" + name);
    // image_data[name].image.style.display = "none";
    image_data[name].message = document.getElementById("message_" + name);
    image_data[name].message.innerHTML = "Loading ...";
    image_data[name].src = src;

    // our XMLHttpRequest to grab the image
    image_data[name].req = getreq();
    image_data[name].req.onreadystatechange = function () { image_loaded(name) };
    image_data[name].req.open("get", image_data[name].src, true);
    image_data[name].req.send(null);     
}

function image_loaded(name) {
    // if the XMLHttpRequest is finished loading
    if(image_data[name].req.readyState == 4) {
        // and the file actually exists
        if(image_data[name].req.status == 200) {
            // success
            var result = image_data[name].req.responseText
	    if ( result.match(/^IMAGE:/) ) {
		image_data[name].message.innerHTML = '';
		image_data[name].image.src = 'data:image/png;base64,' + result.substr(6); // minus "IMAGE:"
	    }
	    else {
		image_data[name].image.style.display = "none";
		image_data[name].message.innerHTML = result;
	    }
        }
        else {
            // say it doesn't exist and hide the image
            image_data[name].message.innerHTML = "Got server error " + image_data[name].req.status + " instead of image for " + name + " graph";
            image_data[name].image.style.display = "none";
        }
    }
}

function getreq() {
  var req;
  if ( window.XMLHttpRequest )
    return new XMLHttpRequest();
  else if ( window.ActiveXObject ) {
    req = new ActiveXObject("Msxml2.XMLHTTP");
    if ( !req )
        return new ActiveXObject("Microsoft.XMLHTTP");
    return req;
  }
}
