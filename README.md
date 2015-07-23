# Ladybug
Swift HTTP client built on WKWebView and XHR. Just for kicks. Don't use this :)

### Usage

Supports `GET`, `POST`, `PUT`, and `DELETE`. Request body is sent as JSON.

```swift
Ladybug.baseURL = "http://httpbin.org"
  
Ladybug.get("/get") { response in
  println(response.json!)
}
  
let params = ["foo": "bar"]
Ladybug.post("/post", parameters: params) { response in
  println(response.json!)
}
```

#### Multipart Form Data

```swift
let params = ["foo": "bar"]

let files = [
  File(name: "myfile1", image: UIImage(named: "img1")!),
  File(name: "myfile2", image: UIImage(named: "img2")!)
]
        
Ladybug.post("/post", parameters: params, files: files) { response in
  println(response.text!)
}
```

#### Blob Responses

```swift
Ladybug.get("/image") { response in
  let image = response.image!
  // or...
  let data = response.data!
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
  println(response.json!)
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
  println(response.json!)
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
