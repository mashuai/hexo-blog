title: '深入理解Spring MVC'
date: 2018-04-07 00:39:10
tags:
  - Java
  - Spring
  - SpringMVC
  - Web
---

[原文地址](https://stackify.com/spring-mvc/)  
##### 初始工程
这篇文章中将使用最新的Spring Framework 5框架。主要关注的是Spring的经典Web技术栈，这套技术从最开始的Spring版本就开始支持，并且知道现在仍然是构建Spring Web应用的主要方式。  
使用Spring Boot和其他starter来设置初始工程。xml配置如下：
```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>2.0.1</version>
    <relativePath/>
</parent>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-thymeleaf</artifactId>
    </dependency>
</dependencies>
```
##### 测试项目
为了理解Spring Web MVC是如何工作的，可以先实现一个简单的Login功能的。创建一个由`@Controller`来修饰的类`InternalController`，这个类包含一个Get的映射。  
`hello()`函数没有参数。返回一个由Spring解释的视图名字的字符串。（在本例中是`login.html`）  
```Java
import org.springframework.web.bind.annotation.GetMapping;

@GetMapping("/")
public String hello() {
    return "login";
}
``` 
为了处理用户登陆逻辑，创建另一个接受POST请求的带有Login数据的方法。然后根据处理结果返回成功或者失败页面。
注意，`login()`函数接受一个领域对象作为参数，返回的是`ModelAndView`对象。
```Java
@PostMapping("/login")
public ModelAndView login(LoginData loginData) {
    if (LOGIN.equals(loginData.getLogin()) 
      && PASSWORD.equals(loginData.getPassword())) {
        return new ModelAndView("success", 
          Collections.singletonMap("login", loginData.getLogin()));
    } else {
        return new ModelAndView("failure", 
          Collections.singletonMap("login", loginData.getLogin()));
    }
}
```
`ModelAndView`保存了两个不同的对象：
  - Model： 用来渲染页面用的键值对的map
  - View： 填充Model数据的模版页面。
将它们合并起来是为了方便，这样controller的方法就可以同时返回这两个了。
使用`Thymeleaf`作为模版引擎来渲染页面。  
##### Java Web应用的基础-Servlet
当你在浏览器里键入`http://localhost:8080/ `，然后按回车键，请求到达服务器的时候到底发生了什么？是如何在浏览器中看到这个web请求的数据的？
因为这个项目是一个简单的Spring Boot应用，所以可以通过`Spring5Application`来运行。
Spring Boot默认使用[Apache Tomcat](http://stackify.com/tomcat-performance-monitoring/)运行程序，运行成功后可能会看到如下的日志：
```
2017-10-16 20:36:11.626  INFO 57414 --- [main] 
  o.s.b.w.embedded.tomcat.TomcatWebServer  : 
  Tomcat initialized with port(s): 8080 (http)

2017-10-16 20:36:11.634  INFO 57414 --- [main] 
  o.apache.catalina.core.StandardService   : 
  Starting service [Tomcat]

2017-10-16 20:36:11.635  INFO 57414 --- [main] 
  org.apache.catalina.core.StandardEngine  : 
  Starting Servlet Engine: Apache Tomcat/8.5.23
```
因为Tomcat是一个Servlet容器，所以几乎所有的HTTP请求都是由Java Servlet处理的。自然的Spring Web的入口就是一个Servlet。
Servlet是所有Java Web应用的核心组件；它非常的低成，并且没有暴露任何具体的编程模式，例如MVC。
一个HTTP的Servelt只能接受HTTP请求，处理请求后返回响应。
现在使用Servlet 3.0的API，可以不再使用XML配置，直接可以使用Java配置。
##### Spring MVC的核心-DispatcherServlet
作为Web开发者，我们希望抽象出以下枯燥和样板的任务，而关注于有用的业务逻辑  
  - 将HTTP请求映射到响应处理函数
  - 将HTTP请求数据和header解析成数据传输对象（DTOs）或者领域对象
  - model-view-controller 互相交互
  - 从DTO，领域对象等生成响应
Spring的`DispatcherServlet`提供了以上的功能，是Spring WEB MVC框架的核心，是应用接受所有请求的核心组件。
稍后就会了解到`DispatcherServlet`可扩展性非常强。例如：它允许你加入现有或者新的适配器来适应不同的任务：
  - 将请求映射到处理它的类或者函数(由`HandlerMapping`实现）
  - 使用特定模式来处理请求，例如一个普通的Servlet，一个复杂的MVC 工作流，或者只是一个方法。(由`HandlerAdapter`实现）
  - 通过名字解析试图对象，允许你使用不同的模版引擎，例如：XML，XSLT或者其他视图技术(由`ViewResolver`实现）
  - 默认使用Apache Comons 的文件上传组件解析文件上传，或者也可以自己实现。
  - 由`LocalResolver`实现本地化，包括cookie，session，HTTP的Accept Header，或者其他由用户定义的本地化。
##### 处理HTTP请求
首先让我们重新审视一下在刚刚建立的应用中是如何处理HTTP请求的。
`DispatcherServlet`有一个很长的继承层级。自顶向下理解每个单独的概念是非常有必要的。处理请求的函数将会更加有趣。
![SpringMVC](https://raw.githubusercontent.com/mashuai/hexo-blog/master/images/springmvc.png)
理解HTTP请求在本地开发模式处理和远程处理是理解MVC架构非常重要的一步。
###### GenericServlet
`GenericServlet`时Servlet规范中的一部分，不直接处理HTTP。它定义了`service()`方法，来接受请求和返回响应。
注意，`ServletRequest`和`ServletResponse`并不是绑定到HTTP协议的。
```Java
public abstract void service(ServletRequest req, ServletResponse res) 
  throws ServletException, IOException;
```
服务器所有的请求，包括简单的GET请求都会调用这个方法。
##### HttpServlet
正如其名，`HttpServelt`是Servlet 规范中关于HTTP请求的实现。
更确切的说，`HttpServlet`是一个实现了`service()`的抽象类。通过将不同的HTTP请求类型分开，由不同的函数处理，实现大约如下所示：
```Java
protected void service(HttpServletRequest req, HttpServletResponse resp)
    throws ServletException, IOException {

    String method = req.getMethod();
    if (method.equals(METHOD_GET)) {
        // ...
        doGet(req, resp);
    } else if (method.equals(METHOD_HEAD)) {
        // ...
        doHead(req, resp);
    } else if (method.equals(METHOD_POST)) {
        doPost(req, resp);
        // ...
    }
```
##### HttpServletBean
在这个继承关系中`HttpServletBean`是第一个Spring的类。从web.xml或者WebApplicationInitialzer获取的初始参数来注入bean。
在应用中的请求分别调用doGet,doPost等方法来处理不同的HTTP请求。
##### FrameworkServlet
`FrameworkServlet`实现了`ApplicationContextAware`,集成Web的Application Context。不过它也可以创建自己的Application Context。
正如上述所言，父类`HttpServletBean`通过将初始参数作为bean的属性注入。因此如果contex的类名在`contextClass`这个初始参数中，那么就有这个参数创建application context的实例，否则默认使用`XmlWebApplicationContext`。
由于XML配置现在已经过时了。Spring Boot默认使用`AnnotationConfigWebApplicationContext`来配置`DispatcherServlet`。不过这个是很容易修改的。
例如，想要在Spring MVC中使用Groovy的application context，可以将下列配置在web.xml中
```
  dispatcherServlet
        org.springframework.web.servlet.DispatcherServlet
        contextClass
        org.springframework.web.context.support.GroovyWebApplicationContext
```
相同的配置也可以在`WebApplicationInitializer`中配置。
##### DispatcherServlet: 统一处理请求
`HttpServlet.service() `通过HTTP的动词类型来处理路由不同的请求到不同的方法，这个在底层的servlet实现的很好。但是，在SpringMVC的抽象层次中，不能仅靠方法类型来路由请求。
同样的，`FrameworkServlet`的另一个主要功能就是将不同的处理使用`processRequest()`组合在一起。
```Java
@Override
protected final void doGet(HttpServletRequest request, 
  HttpServletResponse response) throws ServletException, IOException {
    processRequest(request, response);
}

@Override
protected final void doPost(HttpServletRequest request, 
  HttpServletResponse response) throws ServletException, IOException {
    processRequest(request, response);
}
```
##### DispatcherServlet: 丰富请求
最后,`DispatcherServlet`实现`doService() `方法。它向请求中加入了一些有用的对象，继续在web 的管道中传递下去，例如：web application context, locale resolver, theme resolver, theme source等
```Java
request.setAttribute(WEB_APPLICATION_CONTEXT_ATTRIBUTE, 
  getWebApplicationContext());
request.setAttribute(LOCALE_RESOLVER_ATTRIBUTE, this.localeResolver);
request.setAttribute(THEME_RESOLVER_ATTRIBUTE, this.themeResolver);
request.setAttribute(THEME_SOURCE_ATTRIBUTE, getThemeSource());
```
同时，`doService()`加入了输入输出的Flash Map，Flash Map是将参数从一个请求传递到另一个请求的基本模式。在重定向中很有用。(例如在重定向之后向用户展示一段简单的信息）
```Java
FlashMap inputFlashMap = this.flashMapManager
  .retrieveAndUpdate(request, response);
if (inputFlashMap != null) {
    request.setAttribute(INPUT_FLASH_MAP_ATTRIBUTE, 
      Collections.unmodifiableMap(inputFlashMap));
}
request.setAttribute(OUTPUT_FLASH_MAP_ATTRIBUTE, new FlashMap());
```
接着`doService() `将会调用`doDispatch()`方法来分发请求。

##### DispatcherServlet: 分发请求
`dispatch() `的主要目的就是知道一个合适的处理请求的处理器并且传递request/response参数。处理器可以是任何对象，并不局限于一个特定的接口。同样也意味着Spring需要找到如何使用这个处理器的适配器。
为了给请求找到合适的处理器，Spring会遍历实现`HandlerMapping`接口的注册的实现。有很多不同的实现可以满足我们各种需求。
`SimpleUrlHandlerMapping`使用URL将请求映射到处理bean中。例如：它可以通过`Java.util.Properties `注入它的映射信息：
```
/welcome.html=ticketController
/show.html=ticketController
```
`RequestMappingHandlerMapping`可能是最广泛使用的映射处理器。它将请求映射到`@Controller`类下的`@RequestMapping`修饰的方法上。这个就是上面那个例子中的`hello()`和`login()`。
注意，上面两个方法分别是`@GetMapping`和`@PostMapping`修饰的。这两个注解来源于`@RequestMapping`。
`dispatch() `同时也可以处理一些其他的HTTP的任务：
  - 如果资源不存在，对GET请求进行短路处理。
  - 对相应的请求使用multipart 解析。
  - 如果处理器选择异步处理请求，对请求进行短路处理。
#####  处理请求
现在Spring确定了处理请求的处理器和处理器的适配器，是时候处理请求了。下面是`HandlerAdapter.handle() `的签名。比较重要的一点是处理器可以选择如何处理请求：
  - 直接将相应写入到response body 和 返回null
  - 返回一个`ModelAndView`对象由`DispatcherServlet`渲染。
```Java
@Nullable
ModelAndView handle(HttpServletRequest request, 
                    HttpServletResponse response, 
                    Object handler) throws Exception;
```
Spring提供了很多类型的处理器，下面是`SimpleControllerHandlerAdapter`如何处理Spring MVC的controller实例的(不要和@Controller搞混)。
注意，controller处理器返回ModelAndView对象并不是由起渲染的。
```Java
public ModelAndView handle(HttpServletRequest request, 
  HttpServletResponse response, Object handler) throws Exception {
    return ((Controller) handler).handleRequest(request, response);
}
```
第二个是`SimpleServletHandlerAdapter`它对一个普通的servlet适配。
servlet并不知道`ModelAndView`，完全自己处理请求，将返回写入到相应的body中。因此它的适配器就直接返回null。
```Java
public ModelAndView handle(HttpServletRequest request, 
  HttpServletResponse response, Object handler) throws Exception {
    ((Servlet) handler).service(request, response);
    return null;
}
```
在本例中，controller是由`@RequestMapping`修饰的POJO，因此处理器会使用`HandlerMethod`来封装它的方法。Spring使用`RequestMappingHandlerAdapter`来适配这种处理器类型。
##### 处理参数，返回处理器函数的值
注意，一般来说controller并不会接收`HttpServletRequest`和`HttpServletResponse`作为参数，但是它可以接收和返回很多中其他类型，例如：领域对象，路径参数等。
同样，也不强求一个controller返回一个`ModelAndView`实例。可以选择返回一个视图名称，`ResponseEntity`，或者是一个可以被转换成JSON的POJO。
`RequestMappingHandlerAdapter`可以保证从`HttpServletRequest`中解析方法需要的参数，同时创建`ModelAndView`对象返回。
下面这段代码就是`RequestMappingHandlerAdapter`中保证这件事情的：
```Java
ServletInvocableHandlerMethod invocableMethod 
  = createInvocableHandlerMethod(handlerMethod);
if (this.argumentResolvers != null) {
    invocableMethod.setHandlerMethodArgumentResolvers(
      this.argumentResolvers);
}
if (this.returnValueHandlers != null) {
    invocableMethod.setHandlerMethodReturnValueHandlers(
      this.returnValueHandlers);
}
```
`argumentResolvers`在`HandlerMethodArgumentResolver`实例中有不同实现。一共有30多种不同的参数解析器的实现。他们可以从请求参数将函数需要的参数解析出来。包括：url路径变量，请求体参数，请求头，cookies，session等。
`returnValueHandlers`在`HandlerMethodArgumentResolver`实例中有不同实现。同样也有很多不同的返回值处理器来处理方法返回的结果，创建`ModelAndView`对象。
例如：当函数`hello()`返回一个string的时候，`ViewNameMethodReturnValueHandler`处理这个值。`login()`返回一个`ModelAndView`对象的时候，Sring使用`ModelAndViewMethodReturnValueHandler`处理这个值。
##### 渲染视图
现在Spring已经处理了HTTP请求，获取了`ModelAndView`实例，现在它需要在用户浏览器渲染HTML页面了。它依赖于由Model和选择的模版组成的`ModelAndView`对象。
同样的，Spring也可以渲染JSON ,XML或者其他HTTP协议接受的类型。这些将在接下来的REST相关了解更多。
现在回去看一下`DispatcherServlet`。` render() `首先使用`LocaleResolver`实例设置返回的Local。首先假设浏览器已经正确设置Accetp头。默认使用`AcceptHeaderLocaleResolver`来处理。
在渲染过程中，`ModelAndView`可以包含一个视图的名字或者是已经选择的视图，或者如果controller依赖于默认视图也可以没有。
既然`hello()`和`login()`方法制定了字符串名字作为视图名称，所以需要使用viewResolvers来查找视图。
```Java
for (ViewResolver viewResolver : this.viewResolvers) {
    View view = viewResolver.resolveViewName(viewName, locale);
    if (view != null) {
        return view;
    }
}
```
ViewResolver的实现由很多，这里使用了由`thymeleaf-spring5`提供的`ThymeleafViewResolver`实现。解析器知道去哪里查找视图，并且提供相应的视图实例。
调用完`render()`之后，Spring就完成了将HTML页面渲染到用户浏览器的任务。
##### REST 支持
除了MVC的场景，我们可以使用狂减创建rest web service。
一个简单的场景，可以使用由`@RequestBody`修饰的POJO作为参数。由`@ResponseBody`修饰方法，指定方法的返回结果直接写入到响应体中。
```Java
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

@ResponseBody
@PostMapping("/message")
public MyOutputResource sendMessage(
  @RequestBody MyInputResource inputResource) {
    
    return new MyOutputResource("Received: "
      + inputResource.getRequestMessage());
}
```
感谢SpringMVC的扩展性，这样做也是可以的。
框架使用`HttpMessageConverter`将内部DTO转换成REST的表示。例如：`MappingJackson2HttpMessageConverter`的可以使用Jackson库将转换model和JSON。
为了简化创建REST API，Srping 引入了`@RestController`注解。默认使用`@ResonseBody`这样就不需要在每个方法中使用了。
```Java
import org.springframework.web.bind.annotation.RestController;

@RestController
public class RestfulWebServiceController {

    @GetMapping("/message")
    public MyOutputResource getMessage() {
        return new MyOutputResource("Hello!");
    }
}
```
##### 结论
在这篇文章中，详细描述了Spring MVC处理HTTP请求的各个步骤。了解到Spring 框架是如何将各个组件组合在一起提供处理HTTP协议的。


