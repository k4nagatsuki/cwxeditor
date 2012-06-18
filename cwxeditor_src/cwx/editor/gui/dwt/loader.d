
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

import std.algorithm : lastIndexOf;
import std.array;
import std.conv;
import std.utf;
import std.ascii;
import std.zip;
import std.file;
import std.datetime;
import std.path;
import std.process;

import org.eclipse.swt.SWTException;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Spinner;
import org.eclipse.swt.widgets.Item;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.TreeItem;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.CoolBar;
import org.eclipse.swt.widgets.CoolItem;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Scale;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.TabFolder;
import org.eclipse.swt.widgets.Sash;
import org.eclipse.swt.widgets.FileDialog;
import org.eclipse.swt.custom.CLabel;
import org.eclipse.swt.custom.CCombo;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.TreeEditor;
import org.eclipse.swt.custom.TableEditor;
import org.eclipse.swt.events.KeyAdapter;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.MouseTrackAdapter;
import org.eclipse.swt.events.MouseWheelListener;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.FocusListener;
import org.eclipse.swt.events.FocusEvent;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.events.ModifyEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.ControlAdapter;
import org.eclipse.swt.events.ControlEvent;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.graphics.PaletteData;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.graphics.Cursor;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.program.Program;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.DropTarget;
import org.eclipse.swt.dnd.FileTransfer;
import java.lang.all;
import java.io.ByteArrayInputStream;

private class LSFFThr(S, bool Array) {
	Display display;
	Display current;
	Props prop;
	Shell w;
	Cursor[Shell] cursors;
	bool expandXMLs;
	string fname;
	static if (Array) {
		string[] files;
		string[] temps;
		void clear() {
			foreach (temp; temps) delAll(temp);
		}
		void delegate(S[]) loaded;
	} else {
		S old;
		string temp = "";
		void clear() {
			if (temp.length) delAll(temp);
		}
		void delegate(S) loaded;
	}
	void delegate() failure;
	void delegate(string) status;
	class Start : Runnable {
		void run() {
			status(.tryFormat(prop.msgs.loading, fname));
		}
	}
	class Exit : Runnable {
		void run() {
			try {
				resetCursors(cursors);
			} catch {
				clear();
			}
		}
	}
	class Failed : Runnable {
		void run() {
			static if (Array) {
				if (1 == files.length) {
					status(.tryFormat(prop.msgs.loadErrorStatus, files[0]));
				} else {
					status(.tryFormat(prop.msgs.loadErrorStatusCount, files.length));
				}
			} else {
				status(.tryFormat(prop.msgs.loadErrorStatus, fname));
			}
			if (failure) failure();
		}
	}
	uint worked = 0u;
	uint max;
	class Working : Runnable {
		void run() {
			try {
				status(.tryFormat(prop.msgs.loadProgress, baseName(fname), roundTo!int(cast(real) worked / max * 100.0)));
			} catch {
				clear();
			}
		}
	}
	class Load : Runnable {
		static if (Array) {
			S[] r;
			this (S[] r) {this.r = r;}
			bool success() {return r.length > 0;}
		} else {
			S r;
			this (S r) {this.r = r;}
			bool success() {return r !is null;}
		}
		void run() {
			if (success()) {
				try {
					static if (Array) {
						if (r.length == 1) {
							status(.tryFormat(prop.msgs.loaded, r[0].scenarioName));
						} else {
							status(.tryFormat(prop.msgs.loadedCount, r.length));
						}
					} else {
						status(.tryFormat(prop.msgs.loaded, r.scenarioName));
					}
					loaded(r);
				} catch (Exception e) {
					debugln(e);
					MessageBox.showWarning(e.msg, prop.msgs.dlgTitWarning, w);
					static if (Array) {
						string[] names;
						foreach (s; r) {
							names ~= s.scenarioName;
						}
						if (1 == names.length) {
							status(.tryFormat(prop.msgs.loadErrorStatus, names[0]));
						} else {
							status(.tryFormat(prop.msgs.loadErrorStatusCount, names.length));
						}
					} else {
						status(.tryFormat(prop.msgs.loadErrorStatus, r.scenarioName));
					}
				} catch {
					clear();
				}
			}
		}
	}
	class SError : Runnable {
		SummaryException e;
		this (SummaryException e) {this.e = e;}
		void run() {
			try {
				MessageBox.showWarning(e.msg, prop.msgs.dlgTitWarning, w);
			} catch {
				clear();
			}
			static if (Array) {
				if (1 == files.length) {
					status(.tryFormat(prop.msgs.loadErrorStatus, files[0]));
				} else {
					status(.tryFormat(prop.msgs.loadErrorStatus, files.length));
				}
			} else {
				status(.tryFormat(prop.msgs.loadErrorStatus, fname));
			}
		}
	}
	Runnable working;
	void setMax(uint maxv) {
		max = maxv;
		display.syncExec(working);
	}
	void setWork(uint workedv) {
		worked = workedv;
		display.asyncExec(working);
	}
	void run() {
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
			S[] r;
			foreach (i, path; files) {
				fname = path;
				display.syncExec(new Start);
				S s = loadScenarioFromFileImpl!(S)(prop, w, status, expandXMLs,
					null, path, null, null, false, display, &setMax, &setWork);
				if (s) {
					r ~= s;
					if (s.useTemp) temps ~= s.scenarioPath;
				} else {
					break;
				}
			}
			display.syncExec(new Load(r));
		} else {
			display.syncExec(new Start);
			try {
				S r = S.loadScenarioFromFile(prop.parent, prop.var.etc.doubleIO,
					fname, prop.var.etc.expandXMLs,
					prop.tempPath, null, old, &setMax, &setWork,
					isDir(fname) ? baseName(fname) : baseName(dirName(fname)));
				temp = r.useTemp ? r.scenarioPath : "";
				display.syncExec(new Load(r));
			} catch (SummaryException e) {
				display.syncExec(new SError(e));
			}
		}
		version (Console) {
			debug std.stdio.writeln("Exit Load Thread");
		}
	}
}

@property
string[] scenarioFilter() {
	string[] r;
	if (canUncab) {
		r ~= "*.wsn;Summary.xml;*.cab;*.zip;Summary.wsm";
	} else {
		r ~= "*.wsn;Summary.xml;*.zip;Summary.wsm";
	}
	r ~= "*.xml;*.wid";
	return r;
}
string[] scenarioFilterDesc(Props prop) {
	string[] r;
	if (canUncab) {
		r ~= .tryFormat(prop.msgs.filterScenario, "*.wsn;Summary.xml;*.cab;*.zip;Summary.wsm");
	} else {
		r ~= .tryFormat(prop.msgs.filterScenario, "*.wsn;Summary.xml;*.zip;Summary.wsm");
	}
	r ~= .tryFormat(prop.msgs.filterParts, "*.xml;*.wid");
	return r;
}

S[] loadScenarios(S)(Props prop, Shell w, void delegate(string) status,
		bool expandXMLs, string dlgTitle, void delegate(S[]) loaded = null, void delegate() failure = null, bool oThr = true) {
	auto dlg = new FileDialog(w, SWT.PRIMARY_MODAL | SWT.APPLICATION_MODAL | SWT.MULTI | SWT.OPEN);
	dlg.setFilterExtensions(scenarioFilter);
	dlg.setFilterNames(scenarioFilterDesc(prop));
	dlg.setText(dlgTitle);
	dlg.setFilterPath(scenarioFilterPath(prop));
	string fname = dlg.open();
	if (fname) {
		auto put = new class Object {
			Props prop;
			string filterPath;
			void delegate (S[]) loaded;
			void put(S[] r) {
				if (r.length) {
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
		foreach (file; dlg.getFileNames()) {
			auto ext = cwx.utils.getExt(file);
			if (cfnmatch(ext, "wid") || cfnmatch(ext, "widx")) {
				file = dirName(file);
			}
			files.add(nabs(std.path.buildPath(dlg.getFilterPath(), file)));
		}
		S[] r = loadScenariosFromFile!(S)(prop, w, status, expandXMLs,
			files.toArray(), &put.put, failure, oThr);
		if (!oThr && r.length) put.put(r);
		return r;
	}
	return [];
}

S[] loadScenariosFromFile(S)(Props prop, Shell w, void delegate(string) status,
		bool expandXMLs, string[] files, void delegate(S[]) loaded = null, void delegate() failure = null, bool oThr = true) {
	auto display = Display.getCurrent();
	if (oThr && loaded) {
		auto thr = new LSFFThr!(S, true);
		thr.display = display;
		thr.prop = prop;
		thr.w = w;
		thr.expandXMLs = expandXMLs;
		thr.files = files;
		thr.loaded = loaded;
		thr.failure = failure;
		thr.status = status;
		thr.cursors = setWaitCursors(w);
		auto t = new core.thread.Thread(&thr.run);
		t.start();
		return [];
	} else {
		auto cursors = setWaitCursors(w);
		scope (exit) resetCursors(cursors);
		S[] r;
		foreach (i, path; files) {
			S s = loadScenarioFromFileImpl!(S)(prop, w, status, expandXMLs, null, path, null, null, false, display);
			if (s) {
				r ~= s;
			} else {
				break;
			}
		}
		return r;
	}
}

string scenarioFilterPath(Props prop) {
	if (prop.var.etc.scenarioPath.length == 0) {
		if (prop.enginePath.length == 0) return "";
		return nabs(std.path.buildPath(dirName(prop.enginePath), "Scenario"));
	} else {
		return nabs(prop.var.etc.scenarioPath);
	}
}

string selectScenario(Props prop, Shell w, string dlgTitle) {
	auto dlg = new FileDialog(w, SWT.PRIMARY_MODAL | SWT.APPLICATION_MODAL | SWT.SINGLE | SWT.OPEN);
	dlg.setFilterExtensions(scenarioFilter);
	dlg.setFilterNames(scenarioFilterDesc(prop));
	dlg.setText(dlgTitle);
	dlg.setFilterPath(scenarioFilterPath(prop));
	return dlg.open();
}

S loadScenario(S)(Props prop, Shell w, void delegate(string) status,
		bool expandXMLs, S old, string dlgTitle, ref string[] openPaths, void delegate(S) loaded = null, void delegate() failure = null, bool oThr = true) {
	string fname = selectScenario(prop, w, dlgTitle);
	if (fname) {
		decScenarioPath(fname, openPaths);
		auto put = new class Object {
			void delegate(S) loaded;
			void put(S r) {
				if (loaded) loaded(r);
			}
		};
		put.loaded = loaded;
		S r = loadScenarioFromFile!(S)(prop, w, status, expandXMLs, old, fname, &put.put, failure, oThr);
		if (!oThr && r) put.put(r);
		return r;
	}
	return null;
}

S loadScenarioFromFile(S)(Props prop, Shell w, void delegate(string) status,
		bool expandXMLs, S old, string fname, void delegate(S) loaded = null, void delegate() failure = null, bool oThr = true) {
	return loadScenarioFromFileImpl!(S)(prop, w, status, expandXMLs, old, fname, loaded, failure, oThr, null);
}
private S loadScenarioFromFileImpl(S)(Props prop, Shell w, void delegate(string) status,
		bool expandXMLs, S old, string fname, void delegate(S) loaded = null, void delegate() failure = null, bool oThr = true, Display current = null,
		void delegate (uint) setMax = null, void delegate (uint) worked = null) {
	if (oThr && loaded) {
		auto thr = new LSFFThr!(S, false);
		thr.display = current ? current : Display.getCurrent();
		thr.current = current;
		thr.prop = prop;
		thr.w = w;
		thr.expandXMLs = expandXMLs;
		thr.old = old;
		thr.fname = fname;
		thr.loaded = loaded;
		thr.failure = failure;
		thr.status = status;
		if (!current) {
			thr.cursors = setWaitCursors(w);
		}
		auto t = new core.thread.Thread(&thr.run);
		t.start();
		return null;
	} else {
		Cursor[Shell] cursors;
		if (!current) {
			cursors = setWaitCursors(w);
		}
		scope (exit) {
			if (!current) resetCursors(cursors);
		}
		try {
			return S.loadScenarioFromFile(prop.parent, prop.var.etc.doubleIO,
				fname, prop.var.etc.expandXMLs,
				prop.tempPath, null, old, setMax, worked,
				isDir(fname) ? baseName(fname) : baseName(dirName(fname)));
		} catch (SummaryException e) {
			status(.tryFormat(prop.msgs.loadErrorStatus, fname));
			if (failure) failure();
		}
	}
	return null;
}
