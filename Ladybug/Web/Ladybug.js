window.ladybug = {
  timeout: 0
};

document.addEventListener('DOMContentLoaded', function() {
  postMessage({ message: 'ready' });
});

function send(id, method, url, params, headers) {
  var xhr = new XMLHttpRequest();

  if (params && (method == 'GET' || method == 'DELETE')) {
    url += '?' + param(params);
  }

  xhr.open(method, url, true);
  xhr.onload = function() {
    var data = null;
    var type = this.getResponseHeader('content-type');
    if (type == 'application/json') data = JSON.parse(this.responseText);
    var response = {
      status: this.status,
      statusText: this.statusText,
      responseText: this.responseText,
      data: data
    };
    postMessage({ message: 'response', id: id, response: response });
  };

  if (params && (method == 'POST' || method == 'PUT')) {
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
