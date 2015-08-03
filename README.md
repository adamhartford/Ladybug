# Ladybug
Yet another Swift HTTP client. Inspired by jQuery's $.ajax.

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
  File(image: UIImage(named: "img1")!, name: "myfile1", fileName: "myfile1.png"),
  File(image: UIImage(named: "img2")!, name: "myfile2", fileName: "myfile2.png"),
  File(data: someData, name: "myfile3", fileName: "myfile3.data", contentType: "application/octet-stream")
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

#### SSL

Ladybug supports both certificate and public key pinning per host. You must provide the path to the certificate in your app bundle. For example:

```swift
let certPath = NSBundle.mainBundle().pathForResource("httpbin.org", ofType: "cer")

Ladybug.enableSSLPinning(.Certificate, filePath: certPath: host: "httpbin.org")
Ladybug.enableSSLPinning(.PublicKey, filePath: certPath!, host: "httpbin.org")
```

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

#### And, why not?

This works too:

```swift
🐞.get("/get") { response in
  println(response.json!)
}
```

### License
Ladybug is released under the MIT license. See LICENSE for details.
