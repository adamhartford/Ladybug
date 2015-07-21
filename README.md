# Ladybug
Swift HTTP client built on WKWebView and XHR. Just for kicks. Don't use this :)

### Usage

Supports `GET`, `POST`, `PUT`, and `DELETE`. Request body is sent as JSON.

```swift
Ladybug.baseURL = "http://httpbin.org"
  
Ladybug.get("/get") { response in
  println(response.data!)
}
  
let params = ["foo": "bar"]
Ladybug.post("/post", parameters: parameters) { response in
  println(response.data!)
}
```

#### Basic Authentication

```swift
Ladybug.setBasicAuth("SomeUser", password: "SomePassword")
```

#### Headers

Set custom headers per request:

```swift
let headers = ["X-MyHeader1": "Value1", "X-MyHeader2": "Value2"]
Ladybug.get("/get", headers: headers) { response in
  println(response.data!)
}
```

Or globally for all requests:

```swift
Ladybug.additionalHeaders = ["X-MyHeader": "Value"]
````

#### Events

Before a single request is sent:

```swift
Ladybug.get("/get", beforeSend: request in {
  println(request)
}) { response in {
  println(response.data!)
}
```

Or before any request is sent:

```swift
Ladybug.beforeSend = { request in
  request.headers["X-Foo"] = "Bar"
}
```

### License
Ladybug is released under the MIT license. See LICENSE for details.
