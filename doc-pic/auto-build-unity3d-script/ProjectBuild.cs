using System.Collections;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System;

class ProjectBuild : Editor{

	static string[] GetBuildScenes()
	{
		List<string> names = new List<string>();
		foreach(EditorBuildSettingsScene e in EditorBuildSettings.scenes)
		{
			if(e==null)
				continue;
			if(e.enabled)
				names.Add(e.path);
		}
		return names.ToArray();
	}

	static void BuildForAndroid()
	{
		string path = Application.dataPath.Substring (0, Application.dataPath.LastIndexOf ('/')) + "/" + "AndroidProject";
		if (string.IsNullOrEmpty (BuildPipeline.BuildPlayer (GetBuildScenes (), path, BuildTarget.Android, BuildOptions.AcceptExternalModificationsToPlayer)))
		{
			//encryptDll(path +"/"+ UnityEditor.PlayerSettings.productName + @"/assets/bin/Data/Managed/Assembly-CSharp.dll");
			//encryptDll(path +"/"+ UnityEditor.PlayerSettings.productName + @"/assets/bin/Data/Managed/Assembly-CSharp-firstpass.dll");
		}
	}

	static void BuildForiOS()
	{
		string path = Application.dataPath.Substring (0, Application.dataPath.LastIndexOf ('/')) + "/" + "iOSProject";
		BuildPipeline.BuildPlayer (GetBuildScenes (), path, BuildTarget.iPhone, BuildOptions.None);
	}

	static void BuildForOSx()
	{
		string path = Application.dataPath.Substring (0, Application.dataPath.LastIndexOf ('/')) + "/build/" + "OSxProject";
		BuildPipeline.BuildPlayer (GetBuildScenes (), path, BuildTarget.StandaloneOSXIntel, BuildOptions.None);

	}

	static void BuildForWindows()
	{
		string path = Application.dataPath.Substring (0, Application.dataPath.LastIndexOf ('/')) + "/build/" + "WindowsProject.exe";
		BuildPipeline.BuildPlayer (GetBuildScenes (), path, BuildTarget.StandaloneWindows, BuildOptions.None);
	}

	static void encryptDll(string path)
	{
		if(File.Exists(path))
		{
			byte[] bytes = File.ReadAllBytes (path);
            bytes[0] += 73;
            File.WriteAllBytes(path, bytes);
		}
	}
}
