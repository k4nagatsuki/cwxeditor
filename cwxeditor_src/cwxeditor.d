
module cwxeditor;

import cwx.utils;
import cwx.system;
import cwx.props;
import cwx.structs;

import cwx.editor.gui.dwt.mainwindow;
import cwx.editor.gui.dwt.textdialog;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;

import std.file;
import std.path;
import std.stdio;
import std.exception;
import std.conv;
import std.cstream;

void main(string[] args) {
	string appPath = exeName(args[0]);
	version (Console) {
		string log = "Executed: " ~ appPath;
		cwriteln(log);
		debug {
			cwriteln(.tryFormat("unittest success: %d msec", utperf));
		}
	}
	LaunchOption opt;

	string debugName = cwx.utils.debugLog;
	cwx.utils.debugLog = buildPath(dirName(appPath), debugName);
	string dStr = .text(__LINE__); // 起動ログ
	try {
		auto sys = new System;
		opt.conf = buildPath(dirName(appPath), "cwxeditor.config");
		dStr ~= " - " ~ .text(__LINE__);
		opt.parseStrings(args[1 .. $]);
		dStr ~= " - " ~ .text(__LINE__);
		auto cprops = new CProps(appPath, sys);
		dStr ~= " - " ~ .text(__LINE__);
		auto prop = new Props(opt.conf, cprops);
		dStr ~= " - " ~ .text(__LINE__);
		if (prop.var.cwxDir) cwx.utils.debugLog = buildPath(prop.var.cwxDir, debugName);
		dStr ~= " - " ~ .text(__LINE__);
		if (opt.help) {
			/// usage
			dStr ~= " - " ~ .text(__LINE__);
			version (Console) {
				try {
					cwriteln(prop.msgs.usage);
				} catch (Exception e) {
					debugln(e);
				}
			}
			try {
				dStr ~= " - " ~ .text(__LINE__);
				auto comm = new Commons(prop);
				dStr ~= " - " ~ .text(__LINE__);
				auto dlg = new TextDialog(comm, prop, null, prop.msgs.dlgTitUsage, prop.images.app, prop.msgs.usage ~ "\n");
				dlg.open();
				dStr ~= " - " ~ .text(__LINE__);
				prop.images.disposeImages();
				comm.dispose();
			} catch (Exception e) {
				debugln(e);
			}
			dStr ~= " - " ~ .text(__LINE__);
			return;
		}
		if (opt.putlangfile.length) {
			// 言語ファイルを保存する
			try {
				auto file = nabs(opt.putlangfile);
				auto dir = file.dirName();
				if (!dir.exists()) dir.mkdirRecurse();
				std.file.write(file, prop.msgs.toXML(true));
			} catch (Exception e) {
				debugln(e);
			}
			return;
		}
		dStr ~= " - " ~ .text(__LINE__);
		auto main = new MainWindow(appPath, sys, prop, opt);
		dStr ~= " - " ~ .text(__LINE__);
		main.doCWX();
		dStr ~= " - " ~ .text(__LINE__);
		version (Console) {
			debug writeln("Exit main()");
		}
	} catch (Throwable e) {
		fdebugln(dStr);
		fdebugln(e);
		throw e;
	}
}
