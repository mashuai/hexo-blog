title: 'SpringMVC 教程 - DispatcherServlet'
date: 2018-04-09 00:39:10
tags:
  - Java
  - SpringMVC
  - Spring
---

##### 简介
同许多其他的web框架一样，SpringMVC使用了前端控制器的设计模式，即一个以`DispatcherServlet`为核心的`Servlet`为处理请求提供了一个共享的算法，而实际的工作是由可配置的委托组件执行的。这个模式即灵活又支持多样的工作流。
同其他的`Servlet`,依照Servlet 规范`DispatcherServlet`需要在web.xml或者Java配置中声明并映射URL。接着`DispatcherServlet`使用Spring的配置来找找委托组件，用来映射URL，解析视图，异常处理等。
下面这个示例是使用Java配置来注册并初始化`DispatcherServlet`，这个类由Servlet容器自动发现。
```Java
public class MyWebApplicationInitializer implements WebApplicationInitializer {

    @Override
    public void onStartup(ServletContext servletCxt) {

        // Load Spring web application configuration
        AnnotationConfigWebApplicationContext ac = new AnnotationConfigWebApplicationContext();
        ac.register(AppConfig.class);
        ac.refresh();

        // Create and register the DispatcherServlet
        DispatcherServlet servlet = new DispatcherServlet(ac);
        ServletRegistration.Dynamic registration = servletCxt.addServlet("app", servlet);
        registration.setLoadOnStartup(1);
        registration.addMapping("/app/*");
    }
}
```

下面这个示例是使用`web.xml`来注册并初始化的
```xml
<web-app>

    <listener>
        <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
    </listener>

    <context-param>
        <param-name>contextConfigLocation</param-name>
        <param-value>/WEB-INF/app-context.xml</param-value>
    </context-param>

    <servlet>
        <servlet-name>app</servlet-name>
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
        <init-param>
            <param-name>contextConfigLocation</param-name>
            <param-value></param-value>
        </init-param>
        <load-on-startup>1</load-on-startup>
    </servlet>

    <servlet-mapping>
        <servlet-name>app</servlet-name>
        <url-pattern>/app/*</url-pattern>
    </servlet-mapping>

</web-app>
```

##### 层次结构
`DispatcherServlet`需要一个扩展了的`ApplicationContext`的`WebApplicationContext`来配置自己的信息。`WebApplicationContext`包含了`Servlet`的`ServletContext`的引用，可以使用`RequestContextUtils`中的静态方法从`WebApplicationContext`中查找`ServletContext`。
对于大多数应用来说一个`WebApplicationContext`就足够了。当然`WebApplicatioContext`也可以是有层次结构的，例如由多个Servlet共享的一个根`WebApplicationContext`，每个Servlet又有自己的子`WebApplicationContext`。
根`WebApplicationContext`一般包括需要在多个Servlet中共享的基础bean，例如数据仓库，业务逻辑等。在Servlet规范中，这些bean可以被有效的继承和改写，子`WebApplicationContext`仅包含在其属于的Servlet中。
![spring mvc context](https://raw.githubusercontent.com/mashuai/hexo-blog/master/images/mvc-context-hierarchy.png)
下面这个例子就是`WebApplicationContext`的层级配置
```Java
public class MyWebAppInitializer extends AbstractAnnotationConfigDispatcherServletInitializer {

    @Override
    protected Class<?>[] getRootConfigClasses() {
        return new Class<?>[] { RootConfig.class };
    }

    @Override
    protected Class<?>[] getServletConfigClasses() {
        return new Class<?>[] { App1Config.class };
    }

    @Override
    protected String[] getServletMappings() {
        return new String[] { "/app1/*" };
    }
} 
```

同样的，在web.xml中的配置
```xml
<web-app>

    <listener>
        <listener-class>org.springframework.web.context.ContextLoaderListener</listener-class>
    </listener>

    <context-param>
        <param-name>contextConfigLocation</param-name>
        <param-value>/WEB-INF/root-context.xml</param-value>
    </context-param>

    <servlet>
        <servlet-name>app1</servlet-name>
        <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
        <init-param>
            <param-name>contextConfigLocation</param-name>
            <param-value>/WEB-INF/app1-context.xml</param-value>
        </init-param>
        <load-on-startup>1</load-on-startup>
    </servlet>

    <servlet-mapping>
        <servlet-name>app1</servlet-name>
        <url-pattern>/app1/*</url-pattern>
    </servlet-mapping>

</web-app>
```

##### 特殊的bean类型
`DispatcherServlet`委托专用的bean来处理请求，渲染响应。专用的bean指的是Spring管理的，实现WebFlux框架约定的实例。这些bean一般都是内建的约定，但是可以定制他们的属性，扩展或者代替这些bean。

bean 类型 | 解释
---------- | ---------:
HandlerMapping | 将请求映射到指定处理器，这个处理器同时包含了一系列的拦截器用来处理处理前和处理后的请求。映射根据不同的条件来查找不同的处理器，具体细节由其实现决定。两个主要的`HandlerMapping`是支持注解`@RequestMapping`的`RequestMappingHandlerMapping`, 和直接将url和控制器映射的`SimpleUrlHandlerMapping`
HandlerAdapter | 帮助`DispatcherServlet` 执行特定的处理器而无需知道这些处理器需要如何被执行。例如执行一个注解controller需要解析他的注解。`HandlerAdapter`的重要作用就是处理这些细节问题。
HandlerExceptionResolver | 将异常重定向到其他处理器或者是显示HTML的错误界面。
ViewResolver | 通过处理器返回的视图字符串查找具体的视图并渲染。 
LocaleResolver, LocaleContextResolver | 支持国际化页面，使用例如时区等来解析本地化问题。 
ThemeResolver | 解析应用可用的主题，例如提供个性化框架 
MultipartResolver | 处理上传文件 
FlashMapManager | 保存和检索输入输出的FlashMap，它可以将属性从一个请求传递到另一个请求的输入输出，一般应用在重定向中。 

##### Web MVC 配置
应用可以声明在特殊的bean类型中列出的bean来处理请求。`DispatcherServlet`会检查每一个bean的`WebApplicationContext`。如果没有指定的bean，那么就会使用DispatcherServlet.properties中定义的bean。
MVC配置将会在以后详细的列出。
##### Servlet 配置
在Servlet 3.0+中，可以使用编程的方式来代替web.xml配置。下面这个例子就是通过编程注册`DispatcherServlet`
```Java
import org.springframework.web.WebApplicationInitializer;

public class MyWebApplicationInitializer implements WebApplicationInitializer {

    @Override
    public void onStartup(ServletContext container) {
        XmlWebApplicationContext appContext = new XmlWebApplicationContext();
        appContext.setConfigLocation("/WEB-INF/spring/dispatcher-config.xml");

        ServletRegistration.Dynamic registration = container.addServlet("dispatcher", new DispatcherServlet(appContext));
        registration.setLoadOnStartup(1);
        registration.addMapping("/");
    }
}
```

`WebApplicationInitializer`是由SpringMVC提供的接口，用来保证上述实现可以由支持Servlet 3.0的容器自动检测并初始化。抽象类`AbstractDispatcherServletInitializerl`实现了`WebApplicationInitializer` 可以更加容易的注册`DispathcerServlet`。
下面是使用Java配置的Spring
```Java
public class MyWebAppInitializer extends AbstractAnnotationConfigDispatcherServletInitializer {

    @Override
    protected Class<?>[] getRootConfigClasses() {
        return null;
    }

    @Override
    protected Class<?>[] getServletConfigClasses() {
        return new Class<?>[] { MyWebConfig.class };
    }

    @Override
    protected String[] getServletMappings() {
        return new String[] { "/" };
    }
}
```

如果使用的是xml配置，需要直接继承`AbstractDispatcherServletInitializer`
```Java
public class MyWebAppInitializer extends AbstractDispatcherServletInitializer {

    @Override
    protected WebApplicationContext createRootApplicationContext() {
        return null;
    }

    @Override
    protected WebApplicationContext createServletApplicationContext() {
        XmlWebApplicationContext cxt = new XmlWebApplicationContext();
        cxt.setConfigLocation("/WEB-INF/spring/dispatcher-config.xml");
        return cxt;
    }

    @Override
    protected String[] getServletMappings() {
        return new String[] { "/" };
    }
}
```

`AbstractDispatcherServletInitializer`同样提供了一个方便的函数来添加过滤器。
```Java
public class MyWebAppInitializer extends AbstractDispatcherServletInitializer {

    // ...

    @Override
    protected Filter[] getServletFilters() {
        return new Filter[] {
            new HiddenHttpMethodFilter(), new CharacterEncodingFilter() };
    }
}
```

每个过滤器根据他具体的类型添加一个默认的名字，并且自动映射到DispatcherServlet。
`isAsyncSupported`方法是`AbstractDispatcherServletInitializer`的protect的方法，可以启动`DispatcherServlet`支持异步处理
如果要定义自己的DispatcherServlet，那么可以重写`createDispatcherServlet`方法。
##### 处理请求
`DispatcherServlet`处理请求的流程如下：  
  - 查找`WebApplicationContext`并将其作为request的一个属性保存起来，以便其他控制器或者处理链中的组件可以使用。默认保存键为`DispatcherServlet.WEB_APPLICATION_CONTEXT_ATTRIBUTE` 
  - 本地化解析器保存在request中，以便处理链中的其他组件使用他来处理请求做本地化处理。如果不需要本地化，那么就不需要使用他。
  - 主题解析器保存在request中，以便其他组件，例如视图查找器使用，如果不需要要主题定制，直接忽略。
  - 如果指定了文件上传解析器，那么就会检查请求是否有文件上传，如果有请求有`MultipartHttpServletRequest`封装，以便其他组件处理。
  - 查找合适的处理器处理请求。如果找到了处理器，那么就依次执行处理链上的组件，返回一个model或者视图。如果是注解的controller也可以直接渲染而不需要返回视图。
  - 如果返回一个model，会渲染一个视图，如果没有返回model，那么就无需渲染视图了，因为视图可能已经被渲染了。

在请求处理过程中如果出现了一场那么就可以使用`WebApplicatioContext`中的`HandlerExceptionResolver`来定制异常处理。
SpringMVC 同样支持返回`last-modification-date`，对指定请求处理如何判断是否有`last-modification-date`非常直接：`DispatcherServlet`查找适合的处理器，并且检查其是否实现了`LastModified`接口，如果实现了，调用`long getLastModified(request)`返回给客户端。
通过web.xml中Servlet的初始化参数可以定制DispatcherServlet.

参数 | 解释 |
---------- | ---------:
contextClass | 实现`WebApplicationContext`的类，默认使用`XmlWebApplicationContext` 
contextConfigLocation | 传递给Context 实例的字符串，包括了bean的定义 
namespace | `WebApplicationContext` 的命名空间，默认`[servlet-name]-servlet` 

##### 拦截器
`HandlerMapping`支持拦截器，在对某些请求添加处理的时候非常有用，比如，权限检查。拦截器必须实现`org.springframework.web.servlet`包中的`HandlerInterceptor`，这个接口有三个处理函数分别对应请求处理前，请求处理后，完成请求处理。
  - preHandle(..) 在请求处理前执行
  - postHandle(..) 请求处理后执行
  - afterCompletion(..) 整个请求处理结束后执行
`preHandle(..)` 返回一个boolean值。可以使用这个值来中断处理请求链。当返回true的时候，处理将会继续执行，如果返回false，`DispatcherServelt`假定拦截器已经对请求正确处理了，例如渲染了一个页面等。将会中断请求处理链。
注意，`postHandle`方法很少使用`@ResponseBody`和`ResponseEntity`。因为响应已经在`postHandle`执行之前有`HandlerAdapter`返回了。意味着在`postHandle`的时候再修改响应已经晚了。对应这种场景可以继承`ResponseBodyAdvice`或者实现ControllerAdvice或者直接配置`RequestMappingHandlerAdapter`来实现。

##### 异常处理
如果在请求映射或者处理请求的时候抛出异常，`DispatcherServelt`会委托`HandlerExceptionResolver`来解析异常并提供可选择的处理，即返一个错误响应。
下表是`HandlerExceptionResolver`的实现

 HandlerExceptionResolver | 描述 
---------- | ---------:
SimpleMappingExceptionResolver | 异常类名和错误页面名的映射。浏览器渲染错误页面的时候非常实用 
DefaultHandlerExceptionResolver | 解析SpringMVC抛出的异常，同时将其映射到HTTP的错误码上  
ResponseStatusExceptionResolver | 解析@ResponseStatus注解，同时根据其注解值将其映射到HTTP的错误码上  
ExceptionHandlerExceptionResolver | 调用@Controller 或者@ControllerAdvice 类中使用@ExceptionHandler注解的方法 

###### 解析链
可以通过在Spring的配置中声明多个`HandlerExceptionResolver`bean，来构成一个异常处理解析链，如果需要的话，同时可以设置他们解析的顺序。序号越大，处理越靠后。
`HandlerExceptionResolver`可以返回：
  - 指向错误页面的 `ModelAndView`
  - 如果异常在解析链中被处理返回空`ModelAndView`
  - 如果异常为被处理返回`null`，后续的解析起继续处理异常，如果异常一直未被处理，那么将会冒泡到Servlet容器处理
Spring MVC的异常是有MVC配置自动声明的，@ResponseStatus注解异常，支持@ExceptionHandler方法的异常。这些处理器都是可以定制和替换的
###### Servlet容器异常
如果`HandlerExceptionResolver`无法处理异常，那么异常将会继续传播，或者是返回了错误的HTTP状态码，例如4xx，5xx。Servlet容器可能会渲染一个错误的页面。这个页面也是可以定制的：
```xml
<error-page>
    <location>/error</location>
</error-page>
```

根据上述代码，当出现了无法处理的异常，或者返回错误码，容器会根据配置返回一个错误的URL。这个请求将会继续被DispatcherServlet处理，比如映射到一个@Controller的错误处理控制器上：
```Java
@RestController
public class ErrorController {

    @RequestMapping(path = "/error")
    public Map<String, Object> handle(HttpServletRequest request) {
        Map<String, Object> map = new HashMap<String, Object>();
        map.put("status", request.getAttribute("javax.servlet.error.status_code"));
        map.put("reason", request.getAttribute("javax.servlet.error.message"));
        return map;
    }
}
```

##### 视图解析
Spring MVC通过定义了`ViewResolver`和`View`两个接口可以让我们直接通过返回model来渲染视图，而不需要指定某一个特定的视图技术。`ViewResolver`提供了视图名和视图之间的映射关系。在提交给特定视图技术之前由`View`来准备数据。
下列表格展示了ViewResolver的层级：

 ViewResolver | 描述 
---------- | ---------:
AbstractCachingViewResolver | `AbstractCachingViewResolver`的子类缓存他解析的视图。缓存可以提高某些视图技术的性能。可以通过设置cache属性为false来关闭缓存。当然如果需要在运行时刷新缓存（例如 FreeMaker的template改变了）那么可以调用`removeFromCache(String viewName, Locale loc)`来刷新。
XmlViewResolver | 实现`ViewResolver`，可以接收一个同Spring XML bean同DTD的xml配置文件。默认在/WEB-INF/views.xml
ResourceBundleViewResolver | 解析定义在`ResourceBundle`中的视图，使用viewname.class作为视图类，viewname.url作为视图名
UrlBasedViewResolver | 无需明确指定映射，直接通过解析url来查找视图名。
InternalResourceViewResolver | 实现`UrlBasedViewResolver`,`JstlView`,`TilesView`，支持`InternalResourceView`例如：jsp，servlet class等。
FreeMarkerViewResolver | `UrlBasedViewResolver`的子类，用来支持FreeMarker
ContentNegotiatingViewResolver | 根据请求的文件名或者Accept来确定视图

###### 视图处理
如果需要的话，可以声明多个视图处理器，通过设置`order`属性来确定他们的顺序。order越大，处理越靠后。
默认情况下`ViewResolver`可以返回null代表找不到视图。当然在JSP中，使用InternalResourceViewResolver来检查JSP是否存在的唯一方式就是通过`RequestDispatcher`执行一次调度。因此`InternalResourceViewResolver`必须是最后一个视图解析器。
###### 视图redirect
视图前缀`redirect:` 表示视图需要执行一次redirect。`UrlBasedViewResolver`和其子类会识别出这是要给重定向，剩下的部分就是视图名。
这个效果和Controller返回一个`RedirectView`一样，但是使用这个指令，controller就可以简单的返回一个视图名就可以了。视图名`redirect:/myapp/some/resource`将会返回相对于当前Servlet Context的视图，`redirect:http://myhost.com/some/arbitrary/path` 这种则会返回绝对URL。
注意，如果一个controller被`@ResponseStatus`修饰，那么注解值优先级高于`RedirectView`
###### 视图Forwarding
视图前缀`forward: `表示视图执行forwarding。同样由`UrlBasedViewResolver`和其子类解析。通过创建`InternalResourceView`执行`RequestDispatcher.forward()`实现。因此这个指令对于`InternalResourceViewResolver`和`InternalResourceViewResolver`没啥用，但是对于使用了其他的视图技术但是仍然想用强制使用JSP或者Servlet的时候就很有用了。
###### 视图内容协商
`ContentNegotiatingViewResolver`并不会解析视图，而是将其委托给其他视图解析器，并且选择客户端请求描述选择视图。描述可以是Accept头或者参数，例如`/path?format=pdf`
`ContentNegotiatingViewResolver`通过对比请求的媒体类型和`ViewResolvers`支持的媒体类型来选择合适的View。被选中的列表中的第一个View将会被返回给客户端。
##### 本地化
同Spring MVC，大多数Spring架构支持国际化。`DispatcherServlet`通过`LocaleResolver`根据客户端的区域自动解析消息。
当请求到来时`DispatcherServlet`查找本地化解析器，如果找到则会设置本地化。通过`RequestContext.getLocale()`方法可以获取由本地化解析器解析的本地化语言。
为了自动化解析，可以通过拦截器对具体的场景进行本地化解析，例如根据请求参数来解析。
本地化解析器和拦截器定义在`org.springframework.web.servlet.i18n`包中，可以在应用中配置。下面是一些Spring使用的配置

###### TimeZone
通过获取客户端的时区来做本地化。`LocaleContextResolver`接口扩展了`LocalResolver`，提供了一个可能包含时区信息的`LocaleContext`。
如果可以，用户的时区可以通过`RequestContext.getTimeZone()`方法获取。时区信息可以自动的被注册到Spring中的ConversionService 日期时间的Converter和Formatter使用。
###### Header resolver
这个解析器检查`accept-language`头，一般来说包含的是客户端操作系统的区域。注意这个不支持时区。
###### Cookie resolver
这个解析器检查cookie中可能包含的`TimeZone`和`Locale`。通过如下定义来使用：
```xml
<bean id="localeResolver" class="org.springframework.web.servlet.i18n.CookieLocaleResolver">

    <property name="cookieName" value="clientlanguage"/>

    <!-- in seconds. If set to -1, the cookie is not persisted (deleted when browser shuts down) -->
    <property name="cookieMaxAge" value="100000"/>

</bean>
```

CookieLocaleResolver的属性：

 名字 | 默认值 | 描述 
---------- | --------- | ----------:
cookieName | classname + LOCALE | cookie名
cookieMaxAge | Servlet容器默认值 | cookie生效时间
cookiePath | / | cookie 保存位置

###### Session resolver
`SessionLocaleResolver`通过从session中检查可能包含的`TimeZone`和`Locale`。相对于`CookieLocaleResolver`，他将信息保存在`HttpSession`中。
###### Locale interceptor
可以通过拦截器启动针对某些映射的本地化策略，例如如下：
```xml
<bean id="localeChangeInterceptor"
        class="org.springframework.web.servlet.i18n.LocaleChangeInterceptor">
    <property name="paramName" value="siteLanguage"/>
</bean>

<bean id="localeResolver"
        class="org.springframework.web.servlet.i18n.CookieLocaleResolver"/>

<bean id="urlMapping"
        class="org.springframework.web.servlet.handler.SimpleUrlHandlerMapping">
    <property name="interceptors">
        <list>
            <ref bean="localeChangeInterceptor"/>
        </list>
    </property>
    <property name="mappings">
        <value>/**/*.view=someController</value>
    </property>
</bean>
```

##### 主题
可以通过设置Spring MVC的主题来整体设置应用的外观，从而提高用户体验。主题是一些静态资源的集合，主要是可以影响外观的样式表和图片。
为了应用主题，首先要设置一个`org.springframework.ui.context.ThemeSource`的接口。`WebApplicationContext`继承了`ThemeSource`，但是将其实现委托给了子类。默认使用的是`org.springframework.ui.context.support.ResourceBundleThemeSource`来从classpath的根目录下加载配置文件。配置文件格式如下：
```
styleSheet=/themes/cool/style.css
background=/themes/cool/img/coolBg.jpg
```
配置文件的名字是视图代码中的变量名。对于JSP而言可以如下显示：
```JSP
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags"%>
<html>
    <head>
        <link rel="stylesheet" href="<spring:theme code='styleSheet'/>" type="text/css"/>
    </head>
    <body style="background=<spring:theme code='background'/>">
        ...
    </body>
</html>
```

默认情况下`ResourceBundleThemeSource`使用空的前缀名，这样配置文件直接从classpath根目录下加载。这样就可以将`cool.properties`定义放到classpath根目录下，`ResourceBundleThemeSource`默认使用标准的Java资源加载工具，同时也完全支持国际化，所以通过命名来支持`cool_nl.properties`。
###### 解析主题
`DispatcherServlet`通过bean的名字`themeResolver`来查找`ThemeResolver`的实现。
ThemeResolver 的实现如下：

Class | 描述 
---------- | ---------:
FixedThemeResolver | 选中一个固定的主题，设置`defaultThemeName`属性
SessionThemeResolver | 主题由用户session维护。每个session只需要设置一次
CookieThemeResolver | 通过cookie选择主题
##### Multipart resolver
`org.springframework.web.multipart`中的`MultipartResolver`是用来处理multipart请求的。共有给予Common Fileupload和Servlet 3.0 两种实现。
为了使用multipart，需要在`DispatcherServlet`的Spring配置中声明一个名字为`multipartResolver`的bean。当POST请求的`content-type`是`multipart/form-data`的时候，解析器解析这个请求并且将`HttpServletRequest`封装成`MultipartHttpServletRequest`来处理请求。
###### Apache FileUpload
使用Apache Commons FileUpload 只需要简单的配置一个类型为`CommonsMultipartResolver`，名字为`multipartResolver`的bean即可。当然也需要将`commons-fileupload`加入到依赖中。
###### Servlet 3.0
使用Servlet 3.0则需要Servlet 容器的配置
  - 使用Java配置，在Servlet注册中设置`MultipartConfigElement`。
  - 使用web.xml 添加要给`<multipart-config>`的配置
如下是使用Java的配置：

```Java
public class AppInitializer extends AbstractAnnotationConfigDispatcherServletInitializer {

    // ...

    @Override
    protected void customizeRegistration(ServletRegistration.Dynamic registration) {

        // Optionally also set maxFileSize, maxRequestSize, fileSizeThreshold
        registration.setMultipartConfig(new MultipartConfigElement("/tmp"));
    }

}
```

Servlet 3.0配置好之后，只需要添加类型为`StandardServletMultipartResolver`，名字为`multipartResolver`的配置即可。

