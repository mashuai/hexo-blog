title: 'SpringMVC 教程 - Filter'
date: 2018-04-09 00:39:10
tags:
  - Java
  - SpringMVC
  - Spring
---

##### 简介
`spring-web`模块提供了许多非常实用的Filter
##### HTTP PUT FORM
浏览器只能通过GET或者POST提交FORM数据，但是非浏览器的客户端可以使用PUT或者PATCH。Servlet API仅为POST方法提供了`ServletRequest.getParameter*()`方法获取FORM信息。
`spring-web`模块提供了`HttpPutFormContentFilter`检查PUT或者PATCH方法的`content-type`是否是`application/x-www-form-urlencoded`,如果是，则从请求体重读取属性并封装到`ServletRequest`中，以便日后通过`ServletRequest.getParameter*()`获取FORM数据。
##### 重定向头
由于请求会经过像负载均衡器这样的代理，那么host，port，scheme在创建一些资源文件的链接的时候返回给客户端可能是有所不同的。
RFC 7239 为代理定义了`Forwarded` 的HTTP头来提供原始请求的信息。同样也有一些其他非标准的HTTP头，例如：`X-Forwarded-Host`,`X-Forwarded-Port`,`X-Forwarded-Proto`。
`ForwardedHeaderFilter`会从`Forwarded`,`X-Forwarded-Host`,`X-Forwarded-Port`或者`X-Forwarded-Proto`中获取跳转信息。他分装了请求以覆盖host，port，scheme，同样为日后的处理隐藏跳转信息。
注意，根据RFC 7239第八节的解释，使用重定向头的时候会有安全问题。在应用层是无法判断一个挑战是否是可信的。所以要正确配置网络上游代理，以便过滤掉不合法的跳转。
如果应用没有使用代理，那么就无需使用`ForwardedHeaderFilter`过滤器。
##### Shallow ETag
`ShallowEtagHeaderFilter`为ETG提供了过滤器，关于ETAG将在视图技术中详细解释。
##### CORS
通过controller的注解Spring MVC对CORS提供了详细的支持。在和Spring Sercurity一同使用的时候`CorsFilter`必须排在Spring Sercurity的过滤器之前。
##### 关于CORS
由于安全原因，浏览器禁止AJAX跳出当前域去访问资源。例如你的银行帐号在一个tab页打卡了，另一个evil.com在其他tab打开。evil.com的脚本不能使用你的银行账号信息去访问银行的API。
Cross-Origin Resource Sharing (CORS) 是由众多浏览器实现的W3C的规范。他规定了允许哪些请求可以跨域，而不是通过弱安全的和功能受限的IFRAME和JSONP。
`HandlerMapping`对CORS提供了内置支持。成功将请求映射到处理器后，`HandlerMapping`对当前请求检查CORS配置，预检请求直接处理，简单和实际请求则检查CORS请求，验证，设置返回header。
为了开启跨域请求（例如`Origin`头和请求的host不一致），需要对CORS进行明确的配置。如果没有找到CORS的配置，那么直接拒绝预检请求，简单请求和实际请求不会添加响应头，因此浏览器不会获取到信息。
每一个`HandlerMapping`都可以根据URL不同配置单独的 `CorsConfiguration`。一般来说应用会通过Java Config或者Xml 命名空间来配置单一，全局的CORS。
`HandlerMapping`级别的全局CORS配置可以和handler级别的CORS合并。例如有注解的controller可以使用类或者方法级别的注解`@CrossOrigin`配置跨域。
`@CrossOrigin`注解可以在controller层启动对请求的跨域检查，例如：
```Java
@RestController
@RequestMapping("/account")
public class AccountController {

    @CrossOrigin
    @GetMapping("/{id}")
    public Account retrieve(@PathVariable Long id) {
        // ...
    }

    @DeleteMapping("/{id}")
    public void remove(@PathVariable Long id) {
        // ...
    }
}
```
默认情况下`@CrossOrigin`的作用如下：
  - 允许所有的域
  - 允许所有header
  - 允许controller映射的方法
  - `allowedCredentials` 默认关闭
  - `max-age`默认30分钟
`@CrossOrigin`同样支持类级别：
```Java
@CrossOrigin(origins = "http://domain2.com", maxAge = 3600)
@RestController
@RequestMapping("/account")
public class AccountController {

    @GetMapping("/{id}")
    public Account retrieve(@PathVariable Long id) {
        // ...
    }

    @DeleteMapping("/{id}")
    public void remove(@PathVariable Long id) {
        // ...
    }
}
```
`@CrossOrigin`同时可以在类和方法中使用：
```Java
@CrossOrigin(maxAge = 3600)
@RestController
@RequestMapping("/account")
public class AccountController {

    @CrossOrigin("http://domain2.com")
    @GetMapping("/{id}")
    public Account retrieve(@PathVariable Long id) {
        // ...
    }

    @DeleteMapping("/{id}")
    public void remove(@PathVariable Long id) {
        // ...
    }
}
```
通过定义全局的CORS配置，来配合使用。全局的CORS配置可以通过Java Config或者XML的XNM命名空间来配置。
默认情况下全局的CORS配置：
  - 允许所有的域
  - 允许所有的header
  - 允许GET,HEAD，POST方法
  - `allowedCredentials` 默认关闭
  - `max-age`默认30分钟
使用Java配置CORS
```Java
@Configuration
@EnableWebMvc
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {

        registry.addMapping("/api/**")
            .allowedOrigins("http://domain2.com")
            .allowedMethods("PUT", "DELETE")
            .allowedHeaders("header1", "header2", "header3")
            .exposedHeaders("header1", "header2")
            .allowCredentials(true).maxAge(3600);

        // Add more mappings...
    }
}
```
使用XML配置CORS
```Xml
<mvc:cors>

    <mvc:mapping path="/api/**"
        allowed-origins="http://domain1.com, http://domain2.com"
        allowed-methods="GET, PUT"
        allowed-headers="header1, header2, header3"
        exposed-headers="header1, header2" allow-credentials="true"
        max-age="123" />

    <mvc:mapping path="/resources/**"
        allowed-origins="http://domain1.com" />

</mvc:cors>
```
另外，也可以通过`CorsFilter`配置CORS。
```Java
CorsConfiguration config = new CorsConfiguration();

// Possibly...
// config.applyPermitDefaultValues()

config.setAllowCredentials(true);
config.addAllowedOrigin("http://domain1.com");
config.addAllowedHeader("");
config.addAllowedMethod("");

UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
source.registerCorsConfiguration("/**", config);

CorsFilter filter = new CorsFilter(source);
```

