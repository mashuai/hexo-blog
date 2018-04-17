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
