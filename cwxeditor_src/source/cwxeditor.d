
module cwxeditor;

private extern(C) __gshared string[] rt_options = [ "scanDataSeg=precise" ];

import cwx.props;
import cwx.sjis;
import cwx.structs;
import cwx.system;
import cwx.utils;

import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.mainwindow;
import cwx.editor.gui.dwt.textdialog;

import std.conv;
import std.exception;
import std.file;
import std.path;
import std.stdio;

import org.eclipse.swt.widgets.Display;

version (LDC) {
	version (Windows) {
		// LDCで /SUBSYSTEM:Windows /ENTRY:mainCRTStartup を指定した時の
		// エントリポイントはCのmainである必要がある
		import core.runtime;
		import core.stdc.string;
		import std.windows.charset;
		extern (C) c_int main(c_int argc, immutable char** argv) {
			.Runtime.initialize();
			scope (exit) .Runtime.terminate();

			string[] args;
			foreach (i; 0 .. argc) {
				args ~= .fromMBSz(argv[i]).to!string();
			}
			try {
				mainImpl(args);
				return 0;
			} catch (Throwable e) {
				return -1;
			}
		}
	} else {
		void main(string[] args) { mainImpl(args); }
	}
} else {
	void main(string[] args) { mainImpl(args); }
}

private void mainImpl(string[] args) {
	string appPath = exeName(args[0]);
	version (Console) {
		string log = "Executed: " ~ appPath;
		cwriteln(log);
		version (unittest) {
			cwriteln(.tryFormat("unittest success: %d msec", utperf));
		}
	} else {
		version (Windows) {
			std.stdio.stdout = std.stdio.File("NUL", "wb");
			std.stdio.stderr = std.stdio.File("NUL", "wb");
		} else version (Posix) {
			std.stdio.stdout = std.stdio.File("/dev/null", "wb");
			std.stdio.stderr = std.stdio.File("/dev/null", "wb");
		} else static assert (0);
	}

	LaunchOption opt;

	string debugName = cwx.utils.debugLog;
	cwx.utils.debugLog = buildPath(dirName(appPath), debugName);
	string dStr = .text(__LINE__); // 起動ログ
	auto display = new Display;
	dStr ~= " - " ~ .text(__LINE__);
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
				auto comm = new Commons(prop, null);
				dStr ~= " - " ~ .text(__LINE__);
				auto dlg = new TextDialog(comm, prop, null, prop.msgs.dlgTitUsage, null, prop.msgs.usage ~ "\n");
				dStr ~= " - " ~ .text(__LINE__);
				dlg.setImages(prop.images.icon);
				dStr ~= " - " ~ .text(__LINE__);
				dlg.open();
				dStr ~= " - " ~ .text(__LINE__);
				dlg.close();
				dStr ~= " - " ~ .text(__LINE__);
				prop.images.disposeImages();
				comm.dispose();
			} catch (Exception e) {
				printStackTrace();
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
		auto main = new MainWindow(appPath, sys, display, prop, opt);
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
	} finally {
		if (!display.isDisposed()) display.dispose();
	}
}
