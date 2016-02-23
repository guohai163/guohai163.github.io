---
layout: post
title:  "开发中常见错误列表"
date:   2016-02-23 16:59:06
categories: java c# sonar
---
1. <font color="#DC143C">错误的使用&&进行空参数判断</font>

  ```java
  //错误
  if (dt == null && dt.Rows.Count <= 0)
  ```
    如果dt为空，逻辑表达式会继续向后检查。并抛出异常。应改为
  ```java
  //正确
  if (dt == null || dt.Rows.Count <=0)
  ```
    另外一种常见的错误
  ```java
  //错误
  if (dt != null || dt.Rows.Count > 0)
  ```
2. <font color="#DC143C">程序内值传递不显示指定</font>

  ```java
  //错误
  public void setName(string name)
  {
    name = name;
  }

  //正确
  public void setName(string name)
  {
      this.name = name;
  }
  ```
3. <font color="#DC143C">在使用string.Format()方法时预期的参数个数和实际的不符。</font>

  ```java
  //错误
  var s1 = string.Format("{0} {1} {2}", 1, 2);
  var s2 = string.Format("{0}", 10, 11);

  //正确
  var s1 = string.Format("{0} {1} {2}", 1, 2, 3);
  ```
4. <font color="#DC143C">静态变量错误的初始化顺序</font>

  ```java
  //错误
  public static SmsConnection smsConnection = SmsConnection.Connect(smsOperator);
  public static SmsOperator smsOperator;

  //正确
  public static SmsOperator smsOperator;
  public static SmsConnection smsConnection = SmsConnection.Connect(smsOperator);
  ```
5. <font color="#DC143C">错误的位置使用了using</font>,以下使用方法主调方法可能可以使用返回的table但可能导致运行时错误。请尽量避免

  ```java
  //错误
  public static DataTable GetDT()
  {
    using(DataTable table=new DataTable())
    {
      //操作table对象
      return table;
    }
  }

  //正确
  public static DataTable GetDT()
  {
    DataTable table=new DataTable();

    //操作table对象
    return table;
  }
  ```
