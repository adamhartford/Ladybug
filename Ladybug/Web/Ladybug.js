window.ladybug = {
  postJSON: false,
  timeout: 0,
  cache: false
};

$(function() {
  postMessage({ message: 'ready' });
});

function sendRequest(id, type, url, params, headers) {
  $.ajax({
    type: type,
    url: url,
    cache: false,
    timeout: ladybug.timeout,
    data: (type == 'post' || type == 'put') && ladybug.postJSON ? JSON.stringify(params) : params,
    headers: headers
  }).done(function(data, textStatus, jqXHR) {
    postMessage({ message: 'response', id: id, data: data, textStatus: textStatus, jqXHR: jqXHR });
  }).fail(function(jqXHR, textStatus) {
    postMessage({ message: 'response', id: id, jqXHR: jqXHR, textStatus: textStatus });
  });
}

function postMessage(msg) {
  // TODO stringify really necessary? DOM error 25 when sending some messages.
  webkit.messageHandlers.interOp.postMessage(JSON.stringify(msg));
}
