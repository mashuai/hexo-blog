title: 'Java8 Date Time API'
date: 2018-04-06 00:39:10
tags:
  - Java
  - Java8
  - Translate
---

[原文地址](http://www.studytrails.com/java/java8/java8_date_and_time/)  
#### 简介
Java8 带来了处理日期和时间需要的方式。几乎所有人都有使用Java Date 痛苦的经历。有很多人因此切换到了Joda Time，但是Java8现在有了更清晰，更可扩展的API。在我们学习API钱，先了解一下日期和时间的概念。Java日期遵循[公历](http://en.wikipedia.org/wiki/Gregorian_calendar)规则。表示时间和日期的类放在`java.time`包中。在这个包里比较重要的API有：  
  -  **java.time.Period**: 表示日期时期时间中的日期。表示日期部分的，年、月、日。例如：1年，两个月，5天。
  -  **java.time.Duration**: 表示日期时间中的时间。 表示时间的，秒，纳秒。例如：5秒。
  -  **java.time.Instant**: 表示时间线的一瞬间。保存的是UNIX时间戳的秒数，同时有另一个字段保存纳秒。
  -  **java.time.LocalDate**: 保存日期时间中的日期，用年-月-日表示。不包含时区，是不可变类。
  -  **java.time.LocalTime**: 保存日期时间中的时间，不包含时区。
  -  **java.time.LocalDateTime**: 保存LocalDate和LocalTime，不包含时区。
  -  **java.time.ZoneDateTime**: 保存LocalDateTIme，使用`ZoneOffset`保存时区信息。可以访问ZoneRule来转换本地时间。
  -  **java.time.ZoneOffset**: 保存时区相对于UTC的位移，时区信息保存在ZoneId中。
  -  **java.time.OffsetDateTime**: 通过位移来表示本地时间。这个类不包含时区规则。    

##### 创建本地日期

```
Instant now = Instant.now();
//2014-09-20T14:32:33.646Z
```
这个语句创建了一个新的时间实例。这个实例没有时区信息，如果打印这个实例将会打印UTC时间。  
##### 打印Unix时间戳
```
System.out.Println(now.getEpochSecond());
// prints 1411137153
```
Unix时间戳是从1970-01-01T00:00:00Z开始的。
#####  Instant 加时间
```
Instant tomorrow = now.plus(1, ChronoUnit.DAYS);
// prints 2014-09-20T14:32:33.646Z
```
这个函数允许添加时间间隔。时间间隔可以是：NANOS, MICROS, MILLIS, SECONDS, MINUTES, HOURS, HALF_DAYS, DAYS。
##### Instant 减时间
```
Instant yesterday = now.minus(1,ChronoUnit.HALF_DAYS);
// prints 2014-09-20T03:38:33.860Z
```
这个minus函数允许从Instant中减时间，时间间隔同plus。
##### 对比两个Instant
```
System.out.println(now.compareTo(tomorrow)); // prints -1
```
对比函数可以比较两个日期，如果参数在比较的Instant之后则返回-1，之前则返回1。
##### 检查Instant是否在另一个Instant之后
```
System.out.println(now.isAfter(yesterday));// prints true
```
##### 创建LocalDateTime
```
LocalDateTime localDateTime = LocalDateTime.now();
System.out.println(localDateTime); // prints 2014-09-28T13:01:40.556
```
注意，这个得到的是本地时区的时间
##### 将LocalDateTime转换成其他时区时间
```
System.out.println(localDateTime.atZone(ZoneId.of("America/New_York")));
// prints 2014-09-28T13:07:31.207-04:00[America/New_York]
```
这个将会创建一个新的ZonedDateTime
##### 从DateTime中获取星期
```
System.out.println(DayOfWeek.from(localDateTime));
// prints SUNDAY.
// (yes, i am working on a sunday :-( ) ))
```
##### 从DateTime中获取一年中第几天
```
System.out.println(localDateTime.get(ChronoField.DAY_OF_YEAR));
// prints 271
```
其他的可以是MINUTE_OF_HOUR, MINUTE_OF_DAY, HOUR_OF_AMPM, HOUR_OF_DAY, AMPM_OF_DAY, DAY_OF_WEEK, DAY_OF_MONTH, DAY_OF_YEAR, MONTH_OF_YEAR, YEAR, OFFSET_SECONDS（UTC时间的位移）
##### 从LocalDateTime中获取LocalDate
```
System.out.println(localDateTime.toLocalDate());
// prints 2014-09-29
```
##### 从LocalDateTIme中获取LocalTime
```
System.out.println(localDateTime.toLocalTime());
// prints 22:26:30.146
```
##### 通过年月日时分创建LocalDateTime
```
System.out.println(LocalDateTime.of(2014, 10, 1, 10, 0));
// prints 2014-10-01T10:00
```
##### 通过解析字符串创建LocalDateTime
```
LocalDateTime parsedLocalDateTime = LocalDateTime.parse("2014-01-01T11:00");
```
##### 创建另一个时区的LocalDateTime
```
System.out.println(LocalDateTime.now(ZoneId.of("UTC")));
// prints 2014-09-29T17:07:26.653 (the local timezone in UTC)
```
##### 通过Instant和时区创建LocalDateTime
```
Instant now = Instant.now();
System.out.println(LocalDateTime.ofInstant(now, ZoneId.of("UTC")));
//2014-09-29T17:09:19.644
```
##### 创建ZonedDateTime
```
ZonedDateTime zonedDateTime = ZonedDateTime.now();
//2014-09-29T22:41:24.908+05:30[Asia/Calcutta]
```
##### 获取两个不同时间在不同单位之差
```
System.out.println(zonedDateTime.until(ZonedDateTime.parse("2014-09-29T22:41:00-10:00"), ChronoUnit.HOURS));
// prints the difference between the current zonedDateTime and the zonedatetime parsed from the above string
```
##### 获取当前ZoneDateTime的位移
```
System.out.println(zonedDateTime.getOffset());
// prints the offset e.g. +10:00
```
##### 使用DateTimeFormatter解析或者格式化时间
```
System.out.println(zonedDateTime.format(DateTimeFormatter.ofPattern("'The' dd 'day of' MMM 'in year' YYYY 'and zone is' z")));
// prints The 29 day of Sep in year 2014 and zone is IST
```
##### 将ZoneDateTime更改时区
有两种方式可以完成这个任务，第一种不更改Instant更改时区，第二种更改时区不更改LocalTime
```
        System.out.println(zonedDateTime);
        System.out.println(zonedDateTime.toInstant());
        System.out.println(zonedDateTime.withZoneSameInstant(ZoneId.of("America/Chicago")));
        System.out.println(zonedDateTime.withZoneSameLocal(ZoneId.of("America/Chicago")));
        
        // prints 
        //System.out.println(zonedDateTime);
        //System.out.println(zonedDateTime.toInstant());
        //System.out.println(zonedDateTime.withZoneSameInstant(ZoneId.of("America/Chicago")));
        //System.out.println(zonedDateTime.withZoneSameLocal(ZoneId.of("America/Chicago")));
```
