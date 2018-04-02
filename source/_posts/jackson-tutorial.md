title: 'Jackson 简明教程'
date: 2015-11-08 00:39:10
tags:
  - JSON
  - Java
  - Jackson
  - Translate
---

[原文地址](https://github.com/FasterXML/jackson-databind/)  
#### 一分钟教程：POJOs和JSON的互相转换
&emsp;&emsp;最常用的功能就是将一段JSON片段组装成POJOs。所以我们首先从这个入手。下面是一个简单的，有两个属性的POJO：  
```
// Note: can use getters/setters as well; here we just use public fields directly:
public class MyValue {
  public String name;
  public int age;
  // NOTE: if using getters/setters, can keep fields `protected` or `private`
}
```
我们需要一个`com.fasterxml.jackson.databind.ObjectMapper`的实例来做所有的数据绑定，`ObjectMapper`仅需要创建一次即可。  
```
ObjectMapper mapper = new ObjectMapper(); // create once, reuse
```
采用默认构造函数目前基本够用，当需要处理特殊情况的时候再学习如何根据情况配置ObjectMapper。以下是使用`ObjectMapper`的示例：  
```
MyValue value = mapper.readValue(new File("data.json"), MyValue.class);
// or:
value = mapper.readValue(new URL("http://some.com/api/entry.json"), MyValue.class);
// or:
value = mapper.readValue("{\"name\":\"Bob\", \"age\":13}", MyValue.class);
```
如果想要生成JSON，只需要反过来就行：
```
mapper.writeValue(new File("result.json"), myResultObject);
// or:
byte[] jsonBytes = mapper.writeValueAsBytes(myResultObject);
// or:
String jsonString = mapper.writeValueAsString(myResultObject);
```
#### 三分钟教程：泛型集合和树模型
除了处理Bean风格的POJO，Jackson同时可以处理JDK的`List`和`Map`:  
```
Map<String, Integer> scoreByName = mapper.readValue(jsonSource, Map.class);
List<String> names = mapper.readValue(jsonSource, List.class);

// and can obviously write out as well
mapper.writeValue(new File("names.json"), names);
```
匹配这种，只要JSON的结构匹配，并且类型简单就可以。如果有POJO值，则需要声明他的实际类型(PS:POJO的属性如果是`List`等类型，则不需要指定类型)  
```
Map<String, ResultValue> results = mapper.readValue(jsonSource,
   new TypeReference<Map<String, ResultValue>>() { } );
// why extra work? Java Type Erasure will prevent type detection otherwise })
```
然而，处理`Map`,`List`和其他'简单'类型(String,Number,Boolean)可以更见简单，对象遍历非常麻烦，所以Jackson的`Tree Model`迟早有用。  
```
// can be read as generic JsonNode, if it can be Object or Array; or,
// if known to be Object, as ObjectNode, if array, ArrayNode etc:
ObjectNode root = mapper.readTree("stuff.json");
String name = root.get("name").asText();
int age = root.get("age").asInt();

// can modify as well: this adds child Object as property 'other', set property 'type'
root.with("other").put("type", "student");
String json = mapper.writeValueAsString(root);

// with above, we end up with something like as 'json' String:
// {
//   "name" : "Bob", "age" : 13,
//   "other" : {
//      "type" : "student"
//   }
// }
```
树模型比data-bind更加的方便，尤其是高度动态的数据结构，或者JSON无法完美映射Java类的时候。
#### 五分钟教程：Streaming parser, generator
有一种更见标准的处理模型，叫做incremental model，也叫Stream model ，这种处理方法和data-bind方式同样方便，和Tree Model同样灵活。data-bind和Tree Model 底层都是基于它。但是同样也暴露给那些想要极致性能和完全掌控解析JSON的用户。
```
JsonFactory f = mapper.getFactory(); // may alternatively construct directly too

// First: write simple JSON output
File jsonFile = new File("test.json");
JsonGenerator g = f.createGenerator(jsonFile);
// write JSON: { "message" : "Hello world!" }
g.writeStartObject();
g.writeStringField("message", "Hello world!");
g.writeEndObject();
g.close();

// Second: read file back
JsonParser p = f.createParser(jsonFile);

JsonToken t = p.nextToken(); // Should be JsonToken.START_OBJECT
t = p.nextToken(); // JsonToken.FIELD_NAME
if ((t != JsonToken.FIELD_NAME) || !"message".equals(p.getCurrentName())) {
   // handle error
}
t = p.nextToken();
if (t != JsonToken.VALUE_STRING) {
   // similarly
}
String msg = p.getText();
System.out.printf("My message to you is: %s!\n", msg);
p.close(); }
```
#### 10分钟教程：配置
有两种入门的配置方法：feature 和 Annotation
##### feature 配置
下面是一些最常用的配置
首先从高层的data-bind配置开始：
```
// SerializationFeature for changing how JSON is written

// to enable standard indentation ("pretty-printing"):
mapper.enable(SerializationFeature.INDENT_OUTPUT);
// to allow serialization of "empty" POJOs (no properties to serialize)
// (without this setting, an exception is thrown in those cases)
mapper.disable(SerializationFeature.FAIL_ON_EMPTY_BEANS);
// to write java.util.Date, Calendar as number (timestamp):
mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

// DeserializationFeature for changing how JSON is read as POJOs:

// to prevent exception when encountering unknown property:
mapper.disable(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES);
// to allow coercion of JSON empty String ("") to null Object value:
mapper.enable(DeserializationFeature.ACCEPT_EMPTY_STRING_AS_NULL_OBJECT);
```
下面是一些可以控制JSON底层解析，生成的配置：
```
// JsonParser.Feature for configuring parsing settings:

// to allow C/C++ style comments in JSON (non-standard, disabled by default)
// (note: with Jackson 2.5, there is also `mapper.enable(feature)` / `mapper.disable(feature)`)
mapper.configure(JsonParser.Feature.ALLOW_COMMENTS, true);
// to allow (non-standard) unquoted field names in JSON:
mapper.configure(JsonParser.Feature.ALLOW_UNQUOTED_FIELD_NAMES, true);
// to allow use of apostrophes (single quotes), non standard
mapper.configure(JsonParser.Feature.ALLOW_SINGLE_QUOTES, true);

// JsonGenerator.Feature for configuring low-level JSON generation:

// to force escaping of non-ASCII characters:
mapper.configure(JsonGenerator.Feature.ESCAPE_NON_ASCII, true);
```
##### 注解配置：修改属性名
最简单的使用注解配置的方式是使用`@JsonProperty`:  
```
public class MyBean {
   private String _name;

   // without annotation, we'd get "theName", but we want "name":
   @JsonProperty("name")
   public String getTheName() { return _name; }

   // note: it is enough to add annotation on just getter OR setter;
   // so we can omit it here
   public void setTheName(String n) { _name = n; }
} 
```
##### 注解配置：忽略属性
有两个可以设置忽略属性的注解，一个是`@JsonIgnore` 修饰的是单个属性，一个是`@JsonIgnoreProperties` 修饰的类。
```
// means that if we see "foo" or "bar" in JSON, they will be quietly skipped
// regardless of whether POJO has such properties
@JsonIgnoreProperties({ "foo", "bar" })
public class MyBean
{
   // will not be written as JSON; nor assigned from JSON:
   @JsonIgnore
   public String internal;

   // no annotation, public field is read/written normally
   public String external;

   @JsonIgnore
   public void setCode(int c) { _code = c; }

   // note: will also be ignored because setter has annotation!
   public int getCode() { return _code; }
} 
```
由于重命名，所以注解是在匹配的的字段，get，set中共享的：如果其中一个设置了`@JsonIgnore`，其他的也受影响。当然也可以使用分离的注解来解决问题：
```
public class ReadButDontWriteProps {
   private String _name;
   @JsonProperty public void setName(String n) { _name = n; }
   @JsonIgnore public String getName() { return _name; }
} 
```
在这个例子中，`name`不会被写入到JSON中，但是如果JSON中有，则会映射到Java对象中。

##### 注解配置：定制注解构造器
和其他的data-bind包不同，jackson 不需要定义默认的构造函数（即不包含参数的构造函数）。如果需要，可以定义一个简单的包含参数的构造函数:  
```
public class CtorBean
{
  public final String name;
  public final int age;

  @JsonCreator // constructor can be public, private, whatever
  private CtorBean(@JsonProperty("name") String name,
    @JsonProperty("age") int age)
  {
      this.name = name;
      this.age = age;
  }
}
```
构造函数在不可变对象中非常实用。  
也可以直接定义一个工厂方法：
```
public class FactoryBean
{
    // fields etc omitted for brewity

    @JsonCreator
    public static FactoryBean create(@JsonProperty("name") String name) {
      // construct and return an instance
    }
}
```
#### 其他特性：
一个有用，但是不被广泛知晓的功能就是Jackson可以任意转换两个POJO。可以将其想象成两步，第一步，将POJO写成JSON，第二步讲JSON写成另一个POJO。实现的时候用了更加高效的一种方法，并没有生成中间的JSON。
转换在兼容的类型中运行的很好：
```
ResultType result = mapper.convertValue(sourceObject, ResultType.class);
```
只要这两个POJO的类型兼容，即to json 和 from json的成功，那么就可以成功：
```
// Convert from List<Integer> to int[]
List<Integer> sourceList = ...;
int[] ints = mapper.convertValue(sourceList, int[].class);
// Convert a POJO into Map!
Map<String,Object> propertyMap = mapper.convertValue(pojoValue, Map.class);
// ... and back
PojoType pojo = mapper.convertValue(propertyMap, PojoType.class);
// decode Base64! (default byte[] representation is base64-encoded String)
String base64 = "TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlz";
byte[] binary = mapper.convertValue(base64, byte[].class);
```
基本上Jackson可以替换很多Apache Commons的组件，例如Base64的编码解码，处理动态POJO等。
