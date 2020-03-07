---
layout: post
title:  "在maven项目中使用junit做单元测试"
date:   2014-08-14 21:59:06
categories: [develop]
tags: [java, maven, junit]
---
###JUnit###
JUnit是一个Java语言的单元测试框架。它由肯特·贝克和Erich Gamma建立，逐渐成为源于Kent Beck的sUnit的xUnit家族中为最成功的一个。 JUnit有它自己的JUnit扩展生态圈。

###在Maven项目中引入JUnit###

修改 `pom.xml` 文件,在 `<dependencys>` 节点内增加  

	<dependency>
		<groupId>junit</groupId>
		<artifactId>junit</artifactId>
		<version>4.11</version>
		<scope>test</scope>
	</dependency>

###测试方法###

在Maven项目中请将源代码放置于`src/main/java`下，测试代码放于`src/test/java`下

* 等待测试方法

		public class Hello {
			public String sayHello(){
				return "Hello world";
			}
		}
* junit测试方法  

		@Test
		public void TestSayHello(){
			Hello hello=new Hello();
			String result = t.sayHello();
			assertEquals("Hello world",result);
		}

###如果使用单元测试###

在项目上 `Run As->JUnit Test` 即可看到测试结果，全绿即为全部测试通过

![JUnitResult](http://guohai163.github.io/doc-pic/junit-tutorial/junit-test.png)

[完整代码](https://github.com/guohai163/org.guohai.maven.junit)