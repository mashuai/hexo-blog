title: 'SpringMVC 教程 - DispatcherServlet'
date: 2018-04-07 00:39:10
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
| bean 类型 | 解释 |
| --- | --- |
| HandlerMapping | 将请求映射到指定处理器，这个处理器同时包含了一系列的拦截器用来处理处理前和处理后的请求。映射根据不同的条件来查找不同的处理器，具体细节由其实现决定。两个主要的`HandlerMapping`是支持注解`@RequestMapping`的`RequestMappingHandlerMapping`, 和直接将url和控制器映射的`SimpleUrlHandlerMapping`|
| HandlerAdapter | 帮助`DispatcherServlet` 执行特定的处理器而无需知道这些处理器需要如何被执行。例如执行一个注解controller需要解析他的注解。`HandlerAdapter`的重要作用就是处理这些细节问题。|
| HandlerExceptionResolver | 将异常重定向到其他处理器或者是显示HTML的错误界面。|
| ViewResolver | 通过处理器返回的视图字符串查找具体的视图并渲染。 |
| LocaleResolver, LocaleContextResolver | 支持国际化页面，使用例如时区等来解析本地化问题。 |
| ThemeResolver | 解析应用可用的主题，例如提供个性化框架 |
| MultipartResolver | 处理上传文件 |
| FlashMapManager | 保存和检索输入输出的FlashMap，它可以将属性从一个请求传递到另一个请求的输入输出，一般应用在重定向中。 |

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
| 参数 | 解释 |
| --- | --- |
| contextClass | 实现`WebApplicationContext`的类，默认使用`XmlWebApplicationContext` |
| contextConfigLocation | 传递给Context 实例的字符串，包括了bean的定义 |
| namespace | `WebApplicationContext` 的命名空间，默认`[servlet-name]-servlet` |

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
| HandlerExceptionResolver | 描述 |
| --- | --- |
| SimpleMappingExceptionResolver | 异常类名和错误页面名的映射。浏览器渲染错误页面的时候非常实用 |
| DefaultHandlerExceptionResolver | 解析SpringMVC抛出的异常，同时将其映射到HTTP的错误码上  |
| ResponseStatusExceptionResolver | 解析@ResponseStatus注解，同时根据其注解值将其映射到HTTP的错误码上  |
| ExceptionHandlerExceptionResolver | 调用@Controller 或者@ControllerAdvice 类中使用@ExceptionHandler注解的方法 |


