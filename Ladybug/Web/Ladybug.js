window.ladybug = {
  timeout: 0
};

document.addEventListener('DOMContentLoaded', function() {
  postMessage({ message: 'ready' });
});

function send(id, method, url, params, files, headers, responseType) {
  var xhr = new XMLHttpRequest();

  if (params && (method == 'GET' || method == 'DELETE')) {
    url += '?' + param(params);
  }

  xhr.open(method, url, true);
  xhr.responseType = responseType || 'text';

  var formData;

  if (files) {
    formData = new FormData();
    for (var i in files) {
      var file = files[i];
      var blob = b64ToBlob(file.data, file.contentType);
      formData.append('blob', blob, file.name);
    }
    formData.append('json', JSON.stringify(params));
  }

  // TODO remove this or do better
  xhr.setRequestHeader('Accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8');

  xhr.onload = function() {
    if (responseType == 'blob') {
      var data = this.response;
      var reader = new FileReader();
      reader.onloadend = function() {
        var base64 = reader.result;
        var response = {
          status: xhr.status,
          statusText: xhr.statusText,
          base64: base64.substring(base64.indexOf(',') + 1)
        };
        postMessage({ message: 'response', id: id, response: response });
      }
      reader.readAsDataURL(data);
    }
    var response = {
      status: this.status,
      statusText: this.statusText,
      responseText: this.responseText
    };
    postMessage({ message: 'response', id: id, response: response });
  };

  if (formData) {
    xhr.send(formData);
  } else if (params && (method == 'POST' || method == 'PUT')) {
    xhr.send(JSON.stringify(params));
  } else {
    xhr.send();
  }
}

function param(obj) {
  var result = '';
  for (var prop in obj) {
    if (result.length > 0) {
      result += '&';
    }
    result += encodeURI(prop + '=' + obj[prop]);
  }
  return result;
}

function postMessage(msg) {
  webkit.messageHandlers.interOp.postMessage(msg);
}

// http://stackoverflow.com/questions/16245767/creating-a-blob-from-a-base64-string-in-javascript
function b64ToBlob(b64Data, contentType, sliceSize) {
  contentType = contentType || '';
  sliceSize = sliceSize || 512;

  var byteCharacters = atob(b64Data);
  var byteArrays = [];

  for (var offset = 0; offset < byteCharacters.length; offset += sliceSize) {
    var slice = byteCharacters.slice(offset, offset + sliceSize);

    var byteNumbers = new Array(slice.length);
    for (var i = 0; i < slice.length; i++) {
      byteNumbers[i] = slice.charCodeAt(i);
    }

    var byteArray = new Uint8Array(byteNumbers);
    byteArrays.push(byteArray);
  }

  var blob = new Blob(byteArrays, {type: contentType});
  return blob;
}
