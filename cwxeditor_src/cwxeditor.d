
module cwxeditor;

import cwx.utils;
import cwx.system;
import cwx.props;
import cwx.editor.gui.dwt.mainwindow;
import cwx.editor.gui.dwt.textdialog;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;

import std.file;
import std.path;
import std.stdio;

void main(string[] args) {
	cwx.utils.debugLog = buildPath(dirName(args[0u]), cwx.utils.debugLog);
	auto sys = new System;
	string conf = buildPath(dirName(args[0u]), "cwxeditor.config");
	if (args.length > 1) {
		string[] openPaths;
		size_t sc = 1u;
		for (int i = 1; i < args.length; i++) {
			bool help = false;
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
				case "-conf": // 設定ファイル指定
					if (i + 1 < args.length) conf = args[i + 1];
					sc = i + 2u;
					break;
				case "-help", "-h", "/?": // usage
					help = true;
					break;
				default:
					if (i > sc) {
						openPaths ~= args[i];
					}
					break;
				}
			} catch (Exception e) {
				debugln(e);
			}
			if (help) {
				version (Console) {
					try {
						string dir;
						version (Windows) {
							dir = "Folder";
						} else {
							dir = "Directory";
						}
						writeln("Usage: cwxeditor [-help | -conf <PATH>] <SCENARIO> [<CWXPath ...>]");
						writeln("");
						writeln("  Options:");
						writeln("    -help         print help");
						writeln("    -conf <PATH>  set config file path");
						writeln("    <SCENARIO>    read scenario (*.wsn/Summary.xml/Summary.wsm/[" ~ dir ~ "])");
						writeln("  OpenID:");
						writeln("    -a   <ID>     open area from <ID>");
						writeln("    -b   <ID>     open battle from <ID>");
						writeln("    -p   <ID>     open package from <ID>");
						writeln("  OpenPath:");
						writeln("    <CWXPath>     open resource from <CWXPath>");
					} catch (Exception e) {
						debugln(e);
					}
				}
				try {
					auto prop = new Props(conf, new CProps(args[0], sys));
					auto comm = new Commons(prop);
					auto dlg = new TextDialog(comm, prop, null, prop.msgs.dlgTitUsage, prop.images.app, prop.msgs.usage);
					dlg.open();
					prop.images.disposeImages();
				} catch (Exception e) {
					debugln(e);
				}
				return;
			}
		}
		if (sc < args.length) {
			auto main = new MainWindow(args[0], conf, sys, args[sc], openPaths);
			main.doCWX();
			return;
		}
	}
	auto main = new MainWindow(args[0], conf, sys);
	main.doCWX();
}
