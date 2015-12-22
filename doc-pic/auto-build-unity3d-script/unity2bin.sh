#!/bin/sh
set -e
set -x

PATH=/bin:/usr/bin:/sbin/:/usr/sbin:/Applications/Unity/Unity.app/Contents/MacOS:/Users/guohai/ProjectWorkSpace/android_unity/UnityMac/android-sdk-macosx/build-tools/23.0.2

for a in $*
do
	r=`echo $a | sed "s/--//g"`
	eval $r
done
PROJECT_PATH=/tmp/$projectname
ANDROIDPROJECT_HOME=$PROJECT_PATH/AndroidProject/$projectname
ANDROID_HOME=/Users/guohai/ProjectWorkSpace/android_unity/UnityMac/android-sdk-macosx
KEYSTORE=/Users/guohai/keystore
SIGNED_PASS=coolnet
cd /tmp
svn co $svnurl $PROJECT_PATH

function buildforwindows()
{
  echo "Target windows project build start..."
	Unity -projectPath $PROJECT_PATH -executeMethod ProjectBuild.BuildForWindows -quit
	#file pageage to tgz
	tar czvf /tmp/$projectname-$version.tgz $PROJECT_PATH/build/
}

function buildforandroid()
{
  echo "Target android project build start..."
	Unity -projectPath $PROJECT_PATH -executeMethod ProjectBuild.BuildForAndroid -quit

	mkdir -p $ANDROIDPROJECT_HOME/gen
	mkdir -p $ANDROIDPROJECT_HOME/bin
	mkdir -p $ANDROIDPROJECT_HOME/result

	aapt p -f -m -J $ANDROIDPROJECT_HOME/gen -S $ANDROIDPROJECT_HOME/res -I $ANDROID_HOME/platforms/android-23/android.jar  -M $ANDROIDPROJECT_HOME/AndroidManifest.xml

	find $ANDROIDPROJECT_HOME/src -name *.java > $ANDROIDPROJECT_HOME/result/sources.list

	javac -encoding UTF-8 -bootclasspath $ANDROID_HOME/platforms/android-23/android.jar -d $ANDROIDPROJECT_HOME/bin -classpath $ANDROIDPROJECT_HOME/libs/unity-classes.jar @$ANDROIDPROJECT_HOME/result/sources.list
	#use android sdk dx
	dx --dex --output=$ANDROIDPROJECT_HOME/bin/classes.dex $ANDROIDPROJECT_HOME/bin $ANDROIDPROJECT_HOME/libs/unity-classes.jar

	aapt p -f -S $ANDROIDPROJECT_HOME/res -I $ANDROID_HOME/platforms/android-23/android.jar -M $ANDROIDPROJECT_HOME/AndroidManifest.xml -A $ANDROIDPROJECT_HOME/assets -F $ANDROIDPROJECT_HOME/result/unit.ap_ --auto-add-overlay

	java -classpath $ANDROID_HOME/tools/lib/sdklib.jar com.android.sdklib.build.ApkBuilderMain  $ANDROIDPROJECT_HOME/result/unity-unsigend.apk -u -z $ANDROIDPROJECT_HOME/result/unit.ap_ -f $ANDROIDPROJECT_HOME/bin/classes.dex -rf $ANDROIDPROJECT_HOME/src -rj $ANDROIDPROJECT_HOME/libs -nf $ANDROIDPROJECT_HOME/libs

	jarsigner -verbose -keystore $KEYSTORE/aeo_android.keystore -signedjar $ANDROIDPROJECT_HOME/result/$projectname.apk $ANDROIDPROJECT_HOME/result/unity-unsigend.apk aeo_android.keystore -keypass $SIGNED_PASS -storepass $SIGNED_PASS
}

function buildforios()
{
  echo "Target ios project build start..."
	Unity -projectPath $PROJECT_PATH -executeMethod ProjectBuild.BuildForiOS -quit
	cd $PROJECT_PATH/iOSProject
	xcodebuild -project Unity-iPhone.xcodeproj -target Unity-iPhone ENABLE_BITCODE=NO
}

case $target in
  windows)
    buildforwindows
    ;;
  ios | iOS)
    buildforios
    ;;
  android)
    buildforandroid
    ;;
  *)
    buildforwindows
    buildforios
    buildforandroid
    ;;
esac
