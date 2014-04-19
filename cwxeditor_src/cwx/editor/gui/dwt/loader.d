
module cwx.editor.gui.dwt.loader;

import cwx.cwl;
import cwx.card;
import cwx.types;
import cwx.utils;
import cwx.features;
import cwx.archive;
import cwx.summary;
import cwx.usecounter;
import cwx.props;
import cwx.imagesize;
import cwx.skin;
import cwx.cab;
import cwx.structs;
import cwx.event;
import cwx.variables;

import cwx.editor.gui.sound;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.jpyimage;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dmenu;

import core.thread;

import std.array;
import std.conv;
import std.utf;
import std.ascii;
import std.zip;
import std.file;
import std.datetime;
import std.path;
import std.process;

import org.eclipse.swt.all;

import java.lang.all;
import java.io.ByteArrayInputStream;

private class LSFFThr(bool Array) {
	Display display;
	Display current;
	Props prop;
	LoadOption opt;
	Shell w;
	Cursor[Shell] cursors;
	string fname;
	static if (Array) {
		string[] files;
		string[] temps;
		void clear() { mixin(S_TRACE);
			foreach (temp; temps) delAll(temp);
		}
		void delegate(Summary[]) loaded;
	} else {
		Summary old;
		string temp = "";
		void clear() { mixin(S_TRACE);
			if (temp.length) delAll(temp);
		}
		void delegate(Summary) loaded;
	}
	void delegate() failure;
	void delegate(string) status;
	class Start : Runnable {
		void run() { mixin(S_TRACE);
			status(.tryFormat(prop.msgs.loading, fname));
		}
	}
	class Exit : Runnable {
		void run() { mixin(S_TRACE);
			try { mixin(S_TRACE);
				resetCursors(cursors);
			} catch (Exception e) { mixin(S_TRACE);
				printStackTrace();
				debugln(e);
				clear();
			}
		}
	}
	class Failed : Runnable {
		void run() { mixin(S_TRACE);
			static if (Array) {
				if (1 == files.length) { mixin(S_TRACE);
					status(.tryFormat(prop.msgs.loadErrorStatus, files[0]));
				} else { mixin(S_TRACE);
					status(.tryFormat(prop.msgs.loadErrorStatusCount, files.length));
				}
			} else { mixin(S_TRACE);
				status(.tryFormat(prop.msgs.loadErrorStatus, fname));
			}
			if (failure) failure();
		}
	}
	uint worked = 0u;
	uint max;
	class Working : Runnable {
		void run() { mixin(S_TRACE);
			try { mixin(S_TRACE);
				status(.tryFormat(prop.msgs.loadProgress, baseName(fname), roundTo!int(cast(real) worked / max * 100.0)));
			} catch (Exception e) { mixin(S_TRACE);
				printStackTrace();
				debugln(e);
				clear();
			}
		}
	}
	class Load : Runnable {
		static if (Array) {
			Summary[] r;
			this (Summary[] r) {this.r = r;}
			bool success() {return r.length > 0;}
		} else {
			Summary r;
			this (Summary r) {this.r = r;}
			bool success() {return r !is null;}
		}
		void run() { mixin(S_TRACE);
			if (success()) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					static if (Array) {
						if (r.length == 1) { mixin(S_TRACE);
							status(.tryFormat(prop.msgs.loaded, r[0].scenarioName));
						} else { mixin(S_TRACE);
							status(.tryFormat(prop.msgs.loadedCount, r.length));
						}
					} else { mixin(S_TRACE);
						status(.tryFormat(prop.msgs.loaded, r.scenarioName));
					}
					loaded(r);
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
					MessageBox.showWarning(e.msg, prop.msgs.dlgTitWarning, w);
					static if (Array) {
						string[] names;
						foreach (s; r) { mixin(S_TRACE);
							names ~= s.scenarioName;
						}
						if (1 == names.length) { mixin(S_TRACE);
							status(.tryFormat(prop.msgs.loadErrorStatus, names[0]));
						} else { mixin(S_TRACE);
							status(.tryFormat(prop.msgs.loadErrorStatusCount, names.length));
						}
					} else { mixin(S_TRACE);
						status(.tryFormat(prop.msgs.loadErrorStatus, r.scenarioName));
					}
				} catch (Throwable e) { mixin(S_TRACE);
					printStackTrace();
					debugln(e);
					clear();
				}
			}
		}
	}
	class SError : Runnable {
		SummaryException e;
		this (SummaryException e) {this.e = e;}
		void run() { mixin(S_TRACE);
			try { mixin(S_TRACE);
				MessageBox.showWarning(e.msg, prop.msgs.dlgTitWarning, w);
			} catch (Exception e) { mixin(S_TRACE);
				printStackTrace();
				debugln(e);
				clear();
			}
			static if (Array) {
				if (1 == files.length) { mixin(S_TRACE);
					status(.tryFormat(prop.msgs.loadErrorStatus, files[0]));
				} else { mixin(S_TRACE);
					status(.tryFormat(prop.msgs.loadErrorStatus, files.length));
				}
			} else { mixin(S_TRACE);
				status(.tryFormat(prop.msgs.loadErrorStatus, fname));
			}
		}
	}
	Runnable working;
	void setMax(uint maxv) { mixin(S_TRACE);
		max = maxv;
		display.syncExec(working);
	}
	void setWork(uint workedv) { mixin(S_TRACE);
		worked = workedv;
		display.asyncExec(working);
	}
	void run() { mixin(S_TRACE);
		version (Console) {
			debug std.stdio.writeln("Start Load Thread");
		}
		scope (exit) {
			display.syncExec(new Exit);
		}
		scope (failure) {
			display.syncExec(new Failed);
		}
		working = new Working;
		static if (Array) {
			Summary[] r;
			foreach (i, path; files) { mixin(S_TRACE);
				fname = path;
				display.syncExec(new Start);
				Summary s = loadScenarioFromFileImpl(prop, opt, w, status,
					null, path, null, null, false, display, &setMax, &setWork);
				if (s) { mixin(S_TRACE);
					r ~= s;
					if (s.useTemp) temps ~= s.scenarioPath;
				} else { mixin(S_TRACE);
					break;
				}
			}
			display.syncExec(new Load(r));
		} else { mixin(S_TRACE);
			display.syncExec(new Start);
			try { mixin(S_TRACE);
				Summary r = Summary.loadScenarioFromFile(prop.parent, opt,
					fname, prop.tempPath, null, old, &setMax, &setWork,
					isDir(fname) ? baseName(fname) : baseName(dirName(fname)));
				temp = r.useTemp ? r.scenarioPath : "";
				display.syncExec(new Load(r));
			} catch (SummaryException e) {
				printStackTrace();
				debugln(e);
				display.syncExec(new SError(e));
			}
		}
		version (Console) {
			debug std.stdio.writeln("Exit Load Thread");
		}
	}
}

@property
string[] scenarioFilter() { mixin(S_TRACE);
	string[] r;
	if (canUncab) { mixin(S_TRACE);
		r ~= "*.wsn;Summary.xml;*.cab;*.zip;Summary.wsm";
	} else { mixin(S_TRACE);
		r ~= "*.wsn;Summary.xml;*.zip;Summary.wsm";
	}
	r ~= "*.xml;*.wid";
	return r;
}
string[] scenarioFilterDesc(Props prop) { mixin(S_TRACE);
	string[] r;
	if (canUncab) { mixin(S_TRACE);
		r ~= .tryFormat(prop.msgs.filterScenario, "*.wsn;Summary.xml;*.cab;*.zip;Summary.wsm");
	} else { mixin(S_TRACE);
		r ~= .tryFormat(prop.msgs.filterScenario, "*.wsn;Summary.xml;*.zip;Summary.wsm");
	}
	r ~= .tryFormat(prop.msgs.filterParts, "*.xml;*.wid");
	return r;
}

Summary[] loadScenarios(Props prop, in LoadOption opt, Shell w, void delegate(string) status,
		string dlgTitle, void delegate(Summary[]) loaded = null, void delegate() failure = null, bool oThr = true) { mixin(S_TRACE);
	auto dlg = new FileDialog(w, SWT.PRIMARY_MODAL | SWT.APPLICATION_MODAL | SWT.MULTI | SWT.OPEN);
	dlg.setFilterExtensions(scenarioFilter);
	dlg.setFilterNames(scenarioFilterDesc(prop));
	dlg.setText(dlgTitle);
	dlg.setFilterPath(scenarioFilterPath(prop));
	string fname = dlg.open();
	if (fname) { mixin(S_TRACE);
		auto put = new class Object {
			Props prop;
			string filterPath;
			void delegate (Summary[]) loaded;
			void put(Summary[] r) { mixin(S_TRACE);
				if (r.length) { mixin(S_TRACE);
					filterPath = nabs(filterPath);
					prop.var.etc.scenarioPath = r[0u].useTemp ? filterPath : dirName(filterPath);
				}
				if (loaded) loaded(r);
			}
		};
		put.prop = prop;
		put.filterPath = dlg.getFilterPath();
		put.loaded = loaded;
		auto files = new HashSet!(string);
		foreach (file; dlg.getFileNames()) { mixin(S_TRACE);
			auto ext = .extension(file);
			if (cfnmatch(ext, ".wid") || cfnmatch(ext, ".wex")) { mixin(S_TRACE);
				file = dirName(file);
			}
			files.add(nabs(std.path.buildPath(dlg.getFilterPath(), file)));
		}
		Summary[] r = loadScenariosFromFile(prop, opt, w, status,
			files.toArray(), &put.put, failure, oThr);
		if (!oThr && r.length) put.put(r);
		return r;
	}
	return [];
}

Summary[] loadScenariosFromFile(Props prop, in LoadOption opt, Shell w, void delegate(string) status,
		string[] files, void delegate(Summary[]) loaded = null, void delegate() failure = null, bool oThr = true) { mixin(S_TRACE);
	auto display = Display.getCurrent();
	if (oThr && loaded) { mixin(S_TRACE);
		auto thr = new LSFFThr!(true);
		thr.display = display;
		thr.prop = prop;
		thr.opt = opt;
		thr.w = w;
		thr.files = files;
		thr.loaded = loaded;
		thr.failure = failure;
		thr.status = status;
		thr.cursors = setWaitCursors(w);
		auto t = new core.thread.Thread(&thr.run);
		t.start();
		return [];
	} else { mixin(S_TRACE);
		auto cursors = setWaitCursors(w);
		scope (exit) resetCursors(cursors);
		Summary[] r;
		foreach (i, path; files) { mixin(S_TRACE);
			Summary s = loadScenarioFromFileImpl(prop, opt, w, status, null, path, null, null, false, display);
			if (s) { mixin(S_TRACE);
				r ~= s;
			} else { mixin(S_TRACE);
				break;
			}
		}
		return r;
	}
}

string scenarioFilterPath(Props prop) { mixin(S_TRACE);
	if (prop.var.etc.scenarioPath.length == 0) { mixin(S_TRACE);
		if (prop.enginePath.length == 0) return "";
		return nabs(std.path.buildPath(dirName(prop.enginePath), "Scenario"));
	} else { mixin(S_TRACE);
		return nabs(prop.var.etc.scenarioPath);
	}
}

string selectScenario(Props prop, Shell w, string dlgTitle) { mixin(S_TRACE);
	auto dlg = new FileDialog(w, SWT.PRIMARY_MODAL | SWT.APPLICATION_MODAL | SWT.SINGLE | SWT.OPEN);
	dlg.setFilterExtensions(scenarioFilter);
	dlg.setFilterNames(scenarioFilterDesc(prop));
	dlg.setText(dlgTitle);
	dlg.setFilterPath(scenarioFilterPath(prop));
	return dlg.open();
}

Summary loadScenario(Props prop, in LoadOption opt, Shell w, void delegate(string) status,
		Summary old, string dlgTitle, ref string[] openPaths, void delegate(Summary) loaded = null, void delegate() failure = null, bool oThr = true) { mixin(S_TRACE);
	string fname = selectScenario(prop, w, dlgTitle);
	if (fname) { mixin(S_TRACE);
		decScenarioPath(fname, openPaths, prop.var.etc.clickIsOpenEvent);
		auto put = new class Object {
			void delegate(Summary) loaded;
			void put(Summary r) { mixin(S_TRACE);
				if (loaded) loaded(r);
			}
		};
		put.loaded = loaded;
		Summary r = loadScenarioFromFile(prop, opt, w, status, old, fname, &put.put, failure, oThr);
		if (!oThr && r) put.put(r);
		return r;
	}
	return null;
}

Summary loadScenarioFromFile(Props prop, in LoadOption opt, Shell w, void delegate(string) status,
		Summary old, string fname, void delegate(Summary) loaded = null, void delegate() failure = null, bool oThr = true) { mixin(S_TRACE);
	return loadScenarioFromFileImpl(prop, opt, w, status, old, fname, loaded, failure, oThr, null);
}
private Summary loadScenarioFromFileImpl(Props prop, in LoadOption opt, Shell w, void delegate(string) status,
		Summary old, string fname, void delegate(Summary) loaded = null, void delegate() failure = null, bool oThr = true, Display current = null,
		void delegate (uint) setMax = null, void delegate (uint) worked = null) { mixin(S_TRACE);
	if (oThr && loaded) { mixin(S_TRACE);
		auto thr = new LSFFThr!(false);
		thr.display = current ? current : Display.getCurrent();
		thr.current = current;
		thr.prop = prop;
		thr.opt = opt;
		thr.w = w;
		thr.old = old;
		thr.fname = fname;
		thr.loaded = loaded;
		thr.failure = failure;
		thr.status = status;
		if (!current) { mixin(S_TRACE);
			thr.cursors = setWaitCursors(w);
		}
		auto t = new core.thread.Thread(&thr.run);
		t.start();
		return null;
	} else { mixin(S_TRACE);
		Cursor[Shell] cursors;
		if (!current) { mixin(S_TRACE);
			cursors = setWaitCursors(w);
		}
		scope (exit) {
			if (!current) resetCursors(cursors);
		}
		try { mixin(S_TRACE);
			return Summary.loadScenarioFromFile(prop.parent, opt, fname,
				prop.tempPath, null, old, setMax, worked,
				isDir(fname) ? baseName(fname) : baseName(dirName(fname)));
		} catch (SummaryException e) {
			printStackTrace();
			debugln(e);
			status(.tryFormat(prop.msgs.loadErrorStatus, fname));
			if (failure) failure();
		}
	}
	return null;
}
