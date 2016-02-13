---
layout: post
title:  "自动构建Unity3D项目到二进制程序"
date:   2015-12-22 22:22:2
categories: build ci unity script shell
---
## Unity3D项目持续集成方案 ##

**Unity3D** 是一个用于创建诸如三维视频游戏、建筑可视化、实时三维动画等类型互动内容的综合型创作工具。其编辑器运行在Windows和Mac OS X下，可发布游戏至Windows、Wii、OSX或iOS平台。他的持续集成方法主要是通过调用 *BuildPipline.BuildPlayer()* 方法来实现直接生成Windows/MacOS下可运行的程序，或生成Android/iOS项目，再通过脚本进行编译打包生成apk/ipa。利用图形化界面Jenkis来方便用户使用。

### 通过脚本生成Windows下可运行EXE程序 ###

- 在Unity项目的Assets/Editor下新建 [ProjectBuild.cs](http://guohai163.github.io/doc-pic/auto-build-unity3d-script/ProjectBuild.cs) 类。
类内按所要生成的目标产生静态方法，如要生成Windows版本可执行程序：

		static void BuildForWindows()
		{
			BuildPipeline.BuildPlayer(levels,locationPath,BuildTarget.StandaloneWindows,BuildOptions.None);
		}

- 产生给jenkins调用的shell脚本

		#!/bin/sh
		#配置基础项地址
		PROJECT_NAME=HelloWorld
		PATH=/Application/Unity/Unity.app/Contents/MacOS
		PROJECT_PATH=/User/xxx/DEMO/$PROJECT_NAME

		#调用Unity脚本生成目标平台程序,其中-projectPath为指定项目 所在路径，-executeMethod参数为指定要指定生成的类以及方法。-quit为指定执行所有操作后退出unity
		Unity -projectPath $PROJECT_PATH -executeMethod ProjectBuild.BuildForWindows -quit

- 给该脚本赋予执行权限 `chmod 700 unity2bin.sh`执行该脚本 `./unity2bin.sh`.至此WINDOWS版本所有脚本生成完毕。 
- 为了便于远程下载，建议再对生成目录进行一次打包操作 `tar zcvf $projectname.tgz $project_path/build/` 
- 选看章节，让项目支持SVN获取代码。因这次需求方还在使用SVN进行项目管理。为了避免版本冲突之类造成麻烦，建议每次都在临时目录进行项目的或者与生成，在生成完毕后只保留项目的二进制结果，删除临时代码。

### 通过脚本生成Android下可运行的APK程序 ###

- 使用UNITY生成的CS类与上面的WINDOWS版本基本一致，只是生成的是一个AND项目而不能直接是一个AND包。也就是打成APK还要有后续步骤。
- 在脚本生成时需要使用 `/gen /bin /result` 三个目录，请提前用mkdir 进行生成。
- 使用aapt生成R.java文件 `aapt p -f -m -J gen -S res -I android.jar -M AndroidManifest.xml`
- 使用javac生成class文件 `javac -encoding UTF-8 -bootclasspath android.jar -d bin *.java -classpath libs/unity-classes.jar`
- 使用AndroidSDK带的DX工具将上一步 的CLASS文件打包为DEX二进制包`dx --dex --output=bin/classes.dex bin libs/unity-classes.jar`
- 再次使用aapt工具生成不带dex的APK文件 `aapt p -f S res -I android.jar -M AndroidManifest.xml -A assets -F result/$projectname.ap_ --auto-add-overlay`
- 使用java命令将dex文件打入APK包内`java -classpath $androidhome/tools/lib/sdklib.jar com.android.sdklib.build.ApkBuilderMain $reuslt/$projectname-unsigent.apk -u -z result/$projectname.ap_ -f bin/classes.dex -rf src -rj libs -nf libs`
- 对项目进行签名操作，否则在真机上无法安装。首先要使用 `keytool` 生成签名证书文件
`keytool -genkey -alias gyyx-android.keystore -keyalg RSA -validity 20000 -keystore android.keystore`
- 使用上一步生成的证书对APK进行签名 `jarsigner -verbose -keystore android.keystore -signedjar $reuslt/$projectname-sigent.apk $reuslt/$projectname-unsigent.apk android.keystore`
- ###备注：在OSX系统上请使用JDK1.7进行上方操作1.8可能会报错###

### 通过脚本生成iOS下可运行的IPA程序 ###

- 生成iOS版本也比较简单，一样是通过ProjectBuild类来进行生成。 `Unity -projectPath $PROJECT_PATH -executeMethod ProjectBuild.BuildForiOS -quit`
- 进入生成的项目xcode项目目录进行项目生成操作。 `xcodebuild -project Unity-iPhone.xcodeproj -target Unity-iPhone ENABLE_BITCODE=NO`

### 结束语 ###

以上内容本人进一周的尝试和整理所得，希望对你有所帮助。完成的[unity2bin.sh](http://guohai163.github.io/doc-pic/auto-build-unity3d-script/unity2bin.sh)请点击下载。
使用方法

`./unity2bin.sh -svnurl=http://xxx/svn/project/ --target=(android|ios|windows) --projectname=xxxx --version=xx.xx.xx`
