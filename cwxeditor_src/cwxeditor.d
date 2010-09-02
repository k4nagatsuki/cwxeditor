
module cwxeditor;

import cwx.utils;
import cwx.system;
import cwx.editor.gui.dwt.mainwindow;

import std.file;
import std.path;
import std.stdio;

void main(string[] args) {
	cwx.utils.debugLog = join(getDirName(args[0u]), cwx.utils.debugLog);
	auto sys = new System;
	string ini = join(getDirName(args[0u]), "cwxeditor.xml");
	if (args.length > 1) {
		string[] openPaths;
		size_t sc = 1u;
		for (int i = 1; i < args.length; i++) {
			try {
				switch (args[i]) {
				case "-a": // エリア表示
					if (i + 1 < args.length) openPaths ~= "area:id:" ~ args[i + 1];
					sc = i + 2u;
					break;
				case "-b": // バトル表示
					if (i + 1 < args.length) openPaths ~= "battle:id:" ~ args[i + 1];
					sc = i + 2u;
					break;
				case "-p": // パッケージ表示
					if (i + 1 < args.length) openPaths ~= "package:id:" ~ args[i + 1];
					sc = i + 2u;
					break;
				case "-ini": // 設定ファイル指定
					if (i + 1 < args.length) ini = args[i + 1];
					sc = i + 2u;
					break;
				case "-help", "-h", "/?": // usage
					string dir;
					version (Windows) {
						dir = "Folder";
					} else {
						dir = "Directory";
					}
					writefln("Usage: cwxeditor [-help | -ini <PATH>] <SCENARIO> [<CWXPath ...>]");
					writefln("");
					writefln("  Options:");
					writefln("    -help        print help");
					writefln("    -ini <PATH>  set initialize file path");
					writefln("    <SCENARIO>   read scenario (*.wsn/Summary.xml/Summary.wsm/[" ~ dir ~ "])");
					writefln("  OpenID:");
					writefln("    -a   <ID>    open area from <ID>");
					writefln("    -b   <ID>    open battle from <ID>");
					writefln("    -p   <ID>    open package from <ID>");
					writefln("  OpenPath:");
					writefln("    <CWXPath>    open resource from <CWXPath>");
					return;
				default:
					if (i > sc) {
						openPaths ~= args[i];
					}
					break;
				}
			} catch {}
		}
		if (sc < args.length) {
			auto main = new MainWindow(args[0], ini, sys);
			main.doCWX(args[sc], openPaths);
			return;
		}
	}
	auto main = new MainWindow(args[0], ini, sys);
	main.doCWX;
}
