title: 'SpringMVC 教程 - Controller'
date: 2018-04-10 00:39:10
tags:
  - Java
  - SpringMVC
  - Spring
---


##### 声明Controller
Controller也是一个标准的Spring bean，可以在Servlet的`WebApplicationContext`中定义。也可以使用`@Controller`注解，Spring会扫描注解自动注册为Spring的bean。
开启自动注册`@Controller`注解的bean可以使用如下Java Config的配置：
```Java
@Configuration
@ComponentScan("org.example.web")
public class WebConfig {

    // ...
}
```

如果使用xml配置，如下：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:p="http://www.springframework.org/schema/p"
    xmlns:context="http://www.springframework.org/schema/context"
    xsi:schemaLocation="
        http://www.springframework.org/schema/beans
        http://www.springframework.org/schema/beans/spring-beans.xsd
        http://www.springframework.org/schema/context
        http://www.springframework.org/schema/context/spring-context.xsd">

    <context:component-scan base-package="org.example.web"/>

    <!-- ... -->

</beans>
```

##### 请求映射
`@RequestMapping`可以将请求映射到具体的Controller方法上。通过找到匹配的url，http 方法，请求参数，header，媒体类型来映射请求。这个注解既可以用在类级别，也可以用在方法级别上。
为了方便`@RequestMapping`根据HTTP方法不同提供了如下快捷注解：
  - @GetMapping
  - @PostMapping
  - @DeleteMapping
  - @PutMapping
  - @PatchMapping

示例如下所示：
```Java
@RestController
@RequestMapping("/persons")
class PersonController {

    @GetMapping("/{id}")
    public Person getPerson(@PathVariable Long id) {
        // ...
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public void add(@RequestBody Person person) {
        // ...
    }
}
```

##### URI 模式
请求映射支持glob模式和通配符
  - `?` 匹配一个字符
  - `*` 匹配0个或多个字符
  - `**` 匹配0个或多个路径
可以通过`@PathVariable` 访问在URI中定义的变量：

```Java
@GetMapping("/owners/{ownerId}/pets/{petId}")
public Pet findPet(@PathVariable Long ownerId, @PathVariable Long petId) {
    // ...
}
``` 

URI的变量可以在类和方法中定义：
```Java
@Controller
@RequestMapping("/owners/{ownerId}")
public class OwnerController {

    @GetMapping("/pets/{petId}")
    public Pet findPet(@PathVariable Long ownerId, @PathVariable Long petId) {
        // ...
    }
}
```

URI变量会自动类型转换，如果失败会抛出`TypeMismatchException`的异常。默认支持`int`,`long`,`Date`等类型，也可以通过DataBinder和 Type Conversion来注册其他需要支持的类型。
URI变量名也可以明确的支持，例如`@PathVariable("customId")`，不过如果在编译的时候带着调试信息，或者对于Java8 使用`-parameters` 编译，则可以不需要明确的命名。
语法`{varName:regex}`表示变量根据正则表达是来匹配，例如"/spring-web-3.0.5 .jar"可以使用以下表达式匹配
```Java
@GetMapping("/{name:[a-z-]+}-{version:\\d\\.\\d\\.\\d}{ext:\\.[a-z]+}")
public void handle(@PathVariable String version, @PathVariable String ext) {
    // ...
}
```

URI同样可以有内嵌的`${}`的占位符，在应用启动的时候由`PropertyPlaceHolderConfigurer`从本地，系统，环境变量或者其他配置中解析。
Spring MVC使用的是Spring core 中的`AntPathMatcher`来匹配路径。
##### 模式对比
当有很多模式匹配URI的时候，必须通过对比来找到最合适的匹配。这个是通过`AntPathMatcher.getPatternComparator(String path)`来实现。
可以根据URI中的变量个数，通配符个数来给URL打分，如果一个URI的变量少，通配符多，那么他得到的分数就会低。当匹配的模式分数相同是，选择匹配模式长的那个，如果分数和长度都相同，选择变量比通配符少的那个。
`/**`是不参与评分的，而且总会是最后一个选择。同样`/plublic/**`也是当匹配不到其他没有两个通配符的模式的时候才会被选择。
了解更加详细的信息可以查看`AntPathMatcher`中的`AntPatternComparator`。同时也可个继承`PathMatcher`来定制URI匹配。
##### 后缀匹配
Spring MVC 默认启动`.*`后缀匹配模式，这样映射到`/person`的controller 同样可以映射到`/person.*`。扩展名可以用来代替header中的`Accept`表示请求返回的类型。例如`person.pdf`,`person.xml`等。
因为过去浏览器的`Accept`头很难解析，所以这么是有意要的，但是现在浏览器的`Accept`更加清晰明确了，所以更好的选择是用`Accept`。而且过去一段时间内，使用后缀名匹配的时候会有各种各样的问题，当使用URI变量，路径参数，URI编码时后缀模式会导致歧义。
可以使用以下方法关闭后缀模式：
  - `PathMatchConfigurer`的`useSuffixPatternMatching(false)`
  - `ContentNeogiationConfigurer` 的`favorPathExtension(false)`
##### 后缀匹配和RFD
反射型文件下载(RFD)攻击和XSS攻击很相似。XSS依赖于请求的输入，例如查询参数，URI变量等，而RFD是用户点击URL浏览器会下载恶意文件，用户点击后会攻击主机。
由于Spring MVC的 `@ResponseBody`和`ResponseEntity`会根据URI后缀来渲染不同类型的响应内容，所以可能受到RFD攻击。关闭后缀匹配可以降低攻击的风险，但是不能完全防止RFD攻击。
为了防止RFD攻击，可以在渲染响应内容的时候添加`Content-Disposition:inline;filename=f.txt`确保一个安全的下载文件。
默认情况下大多数扩展名都有白名单，可以通过继承`HttpMessageConverter`对内容协商注册扩展，可以避免在响应中添加`Content-Disposition`。
##### 可消费媒体类型
通过请求的`Content-Type`可以缩小请求的匹配范围，例如：
```Java
@PostMapping(path = "/pets", consumes = "application/json")
public void addPet(@RequestBody Pet pet) {
    // ...
}
```

consumes也支持表达式求反操作，例如`!text/plain`指的就除了`text/plain`都可以。
可以定义一个类级别的consumes，其方法共享这个consumes，和其他的`@ReqeustMapping`的属性不同，方法的consumes会覆盖类的定义。
##### 可产生的媒体类型
可以通过`Accept`头来缩小请求的匹配范围，例如：
```java
@GetMapping(path = "/pets/{petId}", produces = "application/json;charset=UTF-8")
@ResponseBody
public Pet getPet(@PathVariable String petId) {
    // ...
}
```

媒体类型可以指定一个字符集。对表达式取反也是支持的，例如：`!text/plain`指的就是除了`text/plain`都可以。
和consumes一样，也可以指定一个类级别的produces，其方法属性也会覆盖类的属性。
##### 参数和HTTP header
可以通过参数来缩小请求匹配的范围。可以设置是否有参数("myParam"),反过来是否没有("!myParam")或者指定一个值（"myParam=myValue")。
```Java
@GetMapping(path = "/pets/{petId}", params = "myParam=myValue")
public void findPet(@PathVariable String petId) {
    // ...
}
```

同样的情况也适合HTTP header
```Java
@GetMapping(path = "/pets", headers = "myHeader=myValue")
public void findPet(@PathVariable String petId) {
    // ...
}
```
