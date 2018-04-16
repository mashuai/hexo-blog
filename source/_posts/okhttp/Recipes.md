title: OKHttp Recipes
date: 2017-03-18 19:44:10
tags:
    - Java
    - Translate
    - OKHttp
    - HTTP
---

[原文地址](https://github.com/square/okhttp/wiki/Recipes)
我们写了一些建议，来演示如何使用OKHttp来解决一些常见问题。

#### 同步GET
可以用来下载文件，打印header，打印body。`string()`方法对于小文档的响应来说是个既方便有高效的方法。但是如果一个文档太大（大于1M），就不要使用`string()`方法了，以为他会把整个文档加载到内存中,在这种情况下可以把body当作流来处理。  

```Java
private final OkHttpClient client = new OkHttpClient();
public void run() throws Exception {
Request request = new Request.Builder()
    .url("http://publicobject.com/helloworld.txt")
    .build();

Response response = client.newCall(request).execute();
if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);

Headers responseHeaders = response.headers();
for (int i = 0; i < responseHeaders.size(); i++) {
System.out.println(responseHeaders.name(i) + ": " + responseHeaders.value(i));
}
System.out.println(response.body().string());
    
```

#### 异步GET
在工作线程下载文件，响应可读后回调。在响应的header准备好的时候回调。响应体可能仍然阻塞。现在OKHttp没有提供获取响应体的异步API。

```Java
private final OkHttpClient client = new OkHttpClient();

public void run() throws Exception {
Request request = new Request.Builder()
    .url("http://publicobject.com/helloworld.txt")
    .build();

client.newCall(request).enqueue(new Callback() {
    @Override public void onFailure(Call call, IOException e) {
    e.printStackTrace();
    }

    @Override public void onResponse(Call call, Response response) throws IOException {
    if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);

    Headers responseHeaders = response.headers();
    for (int i = 0, size = responseHeaders.size(); i < size; i++) {
        System.out.println(responseHeaders.name(i) + ": " + responseHeaders.value(i));
    }

    System.out.println(response.body().string());
    }
});
}
```  

#### 访问Header
总体上说Header有点像`Map<String,String>`，每一个字段都有或没有值。但是一些Header允许有多个值，就像Guava的`[Multimap](http://docs.guava-libraries.googlecode.com/git/javadoc/com/google/common/collect/Multimap.html)`。
例如HTTP提供多个`Vary`的值是很常见并且合法的。OKHttp的API在这两种情况下都能轻松使用。
当写入请求header的时候使用`header(name,value)`设置仅有一个的`name`和`value`。如果有存在的值，会先移除值再添加。 使用`addHeader(name,value)`添加header不会移除已经存在的header。
当读响应header的时候，`header(name)`只返回最后一个值，通常也仅有一个。如果没有值，将会返回null。以一个list的方式获取所有的值可以使用`headers(name)`。
如果要访问所有的header，可以使用Headers类，支持坐标访问。

```Java
private final OkHttpClient client = new OkHttpClient();

public void run() throws Exception {
Request request = new Request.Builder()
    .url("https://api.github.com/repos/square/okhttp/issues")
    .header("User-Agent", "OkHttp Headers.java")
    .addHeader("Accept", "application/json; q=0.5")
    .addHeader("Accept", "application/vnd.github.v3+json")
    .build();

Response response = client.newCall(request).execute();
if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);

System.out.println("Server: " + response.header("Server"));
System.out.println("Date: " + response.header("Date"));
System.out.println("Vary: " + response.headers("Vary"));
}
```

#### 使用POST发送String请求。
使用HTTP的POST给服务发送请求。这个例子发送了一个markdown文档到服务器用来将markdown渲染成HTML。因为整个请求是放在内存中的，所以使用此API的时候避免大文档（小于1M）。

```Java
public static final MediaType MEDIA_TYPE_MARKDOWN
    = MediaType.parse("text/x-markdown; charset=utf-8");

private final OkHttpClient client = new OkHttpClient();

public void run() throws Exception {
String postBody = ""
    + "Releases\n"
    + "--------\n"
    + "\n"
    + " * _1.0_ May 6, 2013\n"
    + " * _1.1_ June 15, 2013\n"
    + " * _1.2_ August 11, 2013\n";

Request request = new Request.Builder()
    .url("https://api.github.com/markdown/raw")
    .post(RequestBody.create(MEDIA_TYPE_MARKDOWN, postBody))
    .build();

Response response = client.newCall(request).execute();
if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);

System.out.println(response.body().string());
}
```

#### 使用POST发送流
使用POST将请求体以流的方式发送。请求体在被写入的时候生成。这个例子直接使用了`[Okio](https://github.com/square/okio)`的缓冲库。可能你更熟悉`OutputStream`可以通过`BufferedSink.outputStream`获取。


```Java
public static final MediaType MEDIA_TYPE_MARKDOWN
    = MediaType.parse("text/x-markdown; charset=utf-8");

private final OkHttpClient client = new OkHttpClient();

public void run() throws Exception {
RequestBody requestBody = new RequestBody() {
    @Override public MediaType contentType() {
    return MEDIA_TYPE_MARKDOWN;
    }

    @Override public void writeTo(BufferedSink sink) throws IOException {
    sink.writeUtf8("Numbers\n");
    sink.writeUtf8("-------\n");
    for (int i = 2; i <= 997; i++) {
        sink.writeUtf8(String.format(" * %s = %s\n", i, factor(i)));
    }
    }

    private String factor(int n) {
    for (int i = 2; i < n; i++) {
        int x = n / i;
        if (x * i == n) return factor(x) + " × " + i;
    }
    return Integer.toString(n);
    }
};

Request request = new Request.Builder()
    .url("https://api.github.com/markdown/raw")
    .post(requestBody)
    .build();

Response response = client.newCall(request).execute();
if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);

System.out.println(response.body().string());
}
```

#### 使用POST发送一个文件
文件很容易当作一个请求体。

```Java
public static final MediaType MEDIA_TYPE_MARKDOWN
    = MediaType.parse("text/x-markdown; charset=utf-8");

private final OkHttpClient client = new OkHttpClient();

public void run() throws Exception {
File file = new File("README.md");

Request request = new Request.Builder()
    .url("https://api.github.com/markdown/raw")
    .post(RequestBody.create(MEDIA_TYPE_MARKDOWN, file))
    .build();

Response response = client.newCall(request).execute();
if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);

System.out.println(response.body().string());
}
```

#### 发送form 参数
使用`FormBody.Builder`来创建一个同HTML 的`form`标签方式相同的请求踢。名字和值会被编码成HTML兼容的URL编码。

```Java
private final OkHttpClient client = new OkHttpClient();

public void run() throws Exception {
RequestBody formBody = new FormBody.Builder()
    .add("search", "Jurassic Park")
    .build();
Request request = new Request.Builder()
    .url("https://en.wikipedia.org/w/index.php")
    .post(formBody)
    .build();

Response response = client.newCall(request).execute();
if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);

System.out.println(response.body().string());
}
```

#### 发送multipart请求
`MultipartBody.Builder`可以创建和HTML上传文件兼容的请求。每一个multipart请求体自身也是请求体，可以有自己的header。如果提供了，这些header仅描述自身的一部分，例如`Content-Dispositon`。`Content-Type`,`Content-Length`如果可用会自动添加。
 
```Java
private static final String IMGUR_CLIENT_ID = "...";
private static final MediaType MEDIA_TYPE_PNG = MediaType.parse("image/png");

private final OkHttpClient client = new OkHttpClient();

public void run() throws Exception {
// Use the imgur image upload API as documented at https://api.imgur.com/endpoints/image
RequestBody requestBody = new MultipartBody.Builder()
    .setType(MultipartBody.FORM)
    .addFormDataPart("title", "Square Logo")
    .addFormDataPart("image", "logo-square.png",
        RequestBody.create(MEDIA_TYPE_PNG, new File("website/static/logo-square.png")))
    .build();

Request request = new Request.Builder()
    .header("Authorization", "Client-ID " + IMGUR_CLIENT_ID)
    .url("https://api.imgur.com/3/image")
    .post(requestBody)
    .build();

Response response = client.newCall(request).execute();
if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);

System.out.println(response.body().string());
}
```
#### 使用Gson解析响应JSON
[Gson](http://code.google.com/p/google-gson/)是一个很顺手的转换Java对象和JSON的API。这里我们用它来解析GitHub响应的JSON。
注意，`ResponseBody.charStream()`使用`content-type`的响应header来选择解码响应流的字符集，如果没有提供默认使用UTF-8。

```Java
private final OkHttpClient client = new OkHttpClient();
private final Gson gson = new Gson();

public void run() throws Exception {
Request request = new Request.Builder()
    .url("https://api.github.com/gists/c2a7c39532239ff261be")
    .build();
Response response = client.newCall(request).execute();
if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);

Gist gist = gson.fromJson(response.body().charStream(), Gist.class);
for (Map.Entry<String, GistFile> entry : gist.files.entrySet()) {
    System.out.println(entry.getKey());
    System.out.println(entry.getValue().content);
}
}

static class Gist {
Map<String, GistFile> files;
}

static class GistFile {
String content;
}
```

#### 响应缓存
为了换成响应需要又一个可读写的缓存目录并且限制缓存的大小。缓存目录应该是私有的，并且非信任的应用无权访问。  
同时访问一个缓冲目录回出现错误。大多数应用应该调用一次`new OkHttpClient()`，配置它的缓存，在其他地方使用统一个实例。否则两个缓存实例会互相损害，损坏换成，可能是你的应用崩溃。
响应缓存使用HTTP的header来配置。如果请求头添加了`Cache-Control: max-stale=3600`,OKHttp将会使用这些配置。是服务器来配置响应可以被缓存多长时间，通过响应头来配置，例如`Cache-Control: max-age=9600`。有一些header可以强制换成响应，强制一个网络返回或者强制一个有条件的GET确定缓存是否有效。
 
```Java
private final OkHttpClient client;

public CacheResponse(File cacheDirectory) throws Exception {
int cacheSize = 10 * 1024 * 1024; // 10 MiB
Cache cache = new Cache(cacheDirectory, cacheSize);

client = new OkHttpClient.Builder()
    .cache(cache)
    .build();
}

public void run() throws Exception {
Request request = new Request.Builder()
    .url("http://publicobject.com/helloworld.txt")
    .build();

Response response1 = client.newCall(request).execute();
if (!response1.isSuccessful()) throw new IOException("Unexpected code " + response1);

String response1Body = response1.body().string();
System.out.println("Response 1 response:          " + response1);
System.out.println("Response 1 cache response:    " + response1.cacheResponse());
System.out.println("Response 1 network response:  " + response1.networkResponse());

Response response2 = client.newCall(request).execute();
if (!response2.isSuccessful()) throw new IOException("Unexpected code " + response2);

String response2Body = response2.body().string();
System.out.println("Response 2 response:          " + response2);
System.out.println("Response 2 cache response:    " + response2.cacheResponse());
System.out.println("Response 2 network response:  " + response2.networkResponse());

System.out.println("Response 2 equals Response 1? " + response1Body.equals(response2Body));
}
```

为了阻止缓冲可以使用`[CacheControl.FORCE_NETWORK](CacheControl.FORCE_NETWORK)`.为了阻止网络连接可以使用`[CacheControl.FORCE_CACHE](http://square.github.io/okhttp/3.x/okhttp/okhttp3/CacheControl.html#FORCE_CACHE)`。警告：如果使用了`FORCE_CACHE`并且响应需要网络，将会返回`504 Unsatisfiable Request`。
#### 取消请求
使用`Call.cancel()`立即取消正在进行的请求。如果一个线程正在写一个请求或者读一个响应将会抛出IOException。当一个请求不在需要的时候使用这个函数来保护网络。例如当用户导航离开应用的时候。同步和异步的请求都可以取消。
 
```Java
private final ScheduledExecutorService executor = Executors.newScheduledThreadPool(1);
private final OkHttpClient client = new OkHttpClient();

public void run() throws Exception {
Request request = new Request.Builder()
    .url("http://httpbin.org/delay/2") // This URL is served with a 2 second delay.
    .build();

final long startNanos = System.nanoTime();
final Call call = client.newCall(request);

// Schedule a job to cancel the call in 1 second.
executor.schedule(new Runnable() {
    @Override public void run() {
    System.out.printf("%.2f Canceling call.%n", (System.nanoTime() - startNanos) / 1e9f);
    call.cancel();
    System.out.printf("%.2f Canceled call.%n", (System.nanoTime() - startNanos) / 1e9f);
    }
}, 1, TimeUnit.SECONDS);

try {
    System.out.printf("%.2f Executing call.%n", (System.nanoTime() - startNanos) / 1e9f);
    Response response = call.execute();
    System.out.printf("%.2f Call was expected to fail, but completed: %s%n",
        (System.nanoTime() - startNanos) / 1e9f, response);
} catch (IOException e) {
    System.out.printf("%.2f Call failed as expected: %s%n",
        (System.nanoTime() - startNanos) / 1e9f, e);
}
}
```

#### 超时处理
当端点不可达的时候使用超时使请求失败。网络分区可能是客户端连接问题，服务器可用性问题或者其他问题。OKHttp支持连接，读，写超时。
 
```Java
private final OkHttpClient client;

public ConfigureTimeouts() throws Exception {
client = new OkHttpClient.Builder()
    .connectTimeout(10, TimeUnit.SECONDS)
    .writeTimeout(10, TimeUnit.SECONDS)
    .readTimeout(30, TimeUnit.SECONDS)
    .build();
}

public void run() throws Exception {
Request request = new Request.Builder()
    .url("http://httpbin.org/delay/2") // This URL is served with a 2 second delay.
    .build();

Response response = client.newCall(request).execute();
System.out.println("Response completed: " + response);
}
 ```

#### 调用前配置
所有的HTTP调用配置都会在`OkHttpClient`中，包括，代理设置，超时和缓存。当需要修改某个调用的配置的时候，使用`OKHttpClient.newBuilder()`。这个函数会返回共享的连接池，调度器，并且跟原始client相同的配置。在下面这个例子中，一个请求的超时时间是500ms另一个是3000ms。

 ```Java
private final OkHttpClient client = new OkHttpClient();

public void run() throws Exception {
Request request = new Request.Builder()
    .url("http://httpbin.org/delay/1") // This URL is served with a 1 second delay.
    .build();

try {
    // Copy to customize OkHttp for this request.
    OkHttpClient copy = client.newBuilder()
        .readTimeout(500, TimeUnit.MILLISECONDS)
        .build();

    Response response = copy.newCall(request).execute();
    System.out.println("Response 1 succeeded: " + response);
} catch (IOException e) {
    System.out.println("Response 1 failed: " + e);
}

try {
    // Copy to customize OkHttp for this request.
    OkHttpClient copy = client.newBuilder()
        .readTimeout(3000, TimeUnit.MILLISECONDS)
        .build();

    Response response = copy.newCall(request).execute();
    System.out.println("Response 2 succeeded: " + response);
} catch (IOException e) {
    System.out.println("Response 2 failed: " + e);
}
}
 ```

#### 处理认证
OKHttp会自动重试认证请求。当响应是`401 Not Authorized`,`Authenticator`需要用来提供凭证。将会重新实现一个带有凭证的请求，如果没有凭证可用跳过重试，返回null。
使用` Response.challenges()`来获取任何认证口令的方案和域。当使用`Basic`认证的时候使用`Credentials.basic(username,password)`来编码一个header。
 
```Java
private final OkHttpClient client;

public Authenticate() {
client = new OkHttpClient.Builder()
    .authenticator(new Authenticator() {
        @Override public Request authenticate(Route route, Response response) throws IOException {
        System.out.println("Authenticating for response: " + response);
        System.out.println("Challenges: " + response.challenges());
        String credential = Credentials.basic("jesse", "password1");
        return response.request().newBuilder()
            .header("Authorization", credential)
            .build();
        }
    })
    .build();
}

public void run() throws Exception {
Request request = new Request.Builder()
    .url("http://publicobject.com/secrets/hellosecret.txt")
    .build();

Response response = client.newCall(request).execute();
if (!response.isSuccessful()) throw new IOException("Unexpected code " + response);

System.out.println(response.body().string());
}
```


