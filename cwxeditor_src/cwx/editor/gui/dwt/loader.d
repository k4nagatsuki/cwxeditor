
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
import cwx.filesync;

import cwx.editor.gui.sound;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.jpyimage;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

import core.thread;

import std.array;
import std.ascii;
import std.conv;
import std.datetime;
import std.file;
import std.path;
import std.process;
import std.range;
import std.stdio;
import std.string;
import std.typecons;
import std.utf;

import org.eclipse.swt.all;

import java.lang.all;
import java.io.ByteArrayInputStream;

/// シナリオデータと読込時にエラーの出たファイル。
alias Tuple!(Summary, "summary", const string[], "errorFiles") LoadResult;

private class LSFFThr(bool Array) {
	Display display;
	Display current;
	Props prop;
	LoadOption opt;
	Shell w;
	Cursor[Shell] cursors;
	FileSync sync;
	string fname;
	static if (Array) {
		string[] files;
		string[] temps;
		void clear() { mixin(S_TRACE);
			foreach (temp; temps) delAll(temp);
		}
		void delegate(LoadResult[]) loaded;
	} else {
		Summary old;
		string temp = "";
		void clear() { mixin(S_TRACE);
			if (temp.length) delAll(temp);
		}
		void delegate(Summary, in string[] errorFiles) loaded;
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
			LoadResult[] r;
			this (LoadResult[] r) { this.r = r; }
			bool success() { return r.length > 0; }
		} else {
			Summary r;
			const string[] errorFiles;
			this (Summary r, const string[] errorFiles) {
				this.r = r;
				this.errorFiles = errorFiles;
			}
			bool success() { return r !is null; }
		}
		void run() { mixin(S_TRACE);
			if (success()) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					static if (Array) {
						if (r.length == 1) { mixin(S_TRACE);
							status(.tryFormat(prop.msgs.loaded, r[0].summary.scenarioName));
						} else { mixin(S_TRACE);
							status(.tryFormat(prop.msgs.loadedCount, r.length));
						}
						loaded(r);
					} else { mixin(S_TRACE);
						status(.tryFormat(prop.msgs.loaded, r.scenarioName));
						loaded(r, errorFiles);
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
					MessageBox.showWarning(e.msg, prop.msgs.dlgTitWarning, w);
					static if (Array) {
						string[] names;
						foreach (s; r) { mixin(S_TRACE);
							names ~= s.summary.scenarioName;
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
		this (SummaryException e) { this.e = e; }
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
			if (failure) failure();
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
		sync.sync();
		working = new Working;
		static if (Array) {
			LoadResult[] r;
			foreach (i, path; files) { mixin(S_TRACE);
				fname = path;
				display.syncExec(new Start);
				string[] errorFiles;
				auto s = loadScenarioFromFileImpl(prop, opt, errorFiles, w, sync, status,
					null, path, null, null, false, display, &setMax, &setWork);
				if (s) { mixin(S_TRACE);
					r ~= LoadResult(s, errorFiles);
					if (s.useTemp) temps ~= s.scenarioPath;
				} else { mixin(S_TRACE);
					break;
				}
			}
			display.syncExec(new Load(r));
		} else { mixin(S_TRACE);
			display.syncExec(new Start);
			try { mixin(S_TRACE);
				Skin defSkin = .findSkin2(prop, prop.var.etc.defaultSkin, prop.var.etc.defaultSkinName);
				string[] errorFiles;
				Summary r = Summary.loadScenarioFromFile(prop.parent, opt,
					errorFiles, fname, prop.tempPath, defSkin, null, old, &setMax, &setWork,
					isDir(fname) ? baseName(fname) : baseName(dirName(fname)));
				temp = r.useTemp ? r.scenarioPath : "";
				display.syncExec(new Load(r, errorFiles));
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
		r ~= "*.wsn;Summary.xml;*.cab;*.zip;*.lzh;*.lha;Summary.wsm";
	} else { mixin(S_TRACE);
		r ~= "*.wsn;Summary.xml;*.zip;*.lzh;*.lha;Summary.wsm";
	}
	r ~= "*.xml;*.wid";
	return r;
}
string[] scenarioFilterDesc(Props prop) { mixin(S_TRACE);
	string[] r;
	if (canUncab) { mixin(S_TRACE);
		r ~= .tryFormat(prop.msgs.filterScenario, "*.wsn;Summary.xml;*.cab;*.zip;*.lzh;*.lha;Summary.wsm");
	} else { mixin(S_TRACE);
		r ~= .tryFormat(prop.msgs.filterScenario, "*.wsn;Summary.xml;*.zip;*.lzh;*.lha;Summary.wsm");
	}
	r ~= .tryFormat(prop.msgs.filterParts, "*.xml;*.wid");
	return r;
}

LoadResult[] loadScenarios(Props prop, in LoadOption opt, Shell w, FileSync sync, void delegate(string) status,
		string dlgTitle, void delegate(LoadResult[]) loaded = null, void delegate() failure = null, bool oThr = true) { mixin(S_TRACE);
	auto dlg = new FileDialog(w, SWT.PRIMARY_MODAL | SWT.APPLICATION_MODAL | SWT.MULTI | SWT.OPEN);
	dlg.setFilterExtensions(scenarioFilter);
	dlg.setFilterNames(scenarioFilterDesc(prop));
	dlg.setText(dlgTitle);
	dlg.setFilterPath(scenarioFilterPath(prop));
	string fname = dlg.open();
	if (fname) { mixin(S_TRACE);
		sync.sync();
		auto put = new class Object {
			Props prop;
			string filterPath;
			void delegate (LoadResult[]) loaded;
			void put(LoadResult[] r) { mixin(S_TRACE);
				if (r.length) { mixin(S_TRACE);
					filterPath = nabs(filterPath);
					if (r[0u].summary.readOnlyPath != "") { mixin(S_TRACE);
						prop.var.etc.scenarioPath = .nabs(r[0u].summary.readOnlyPath.dirName());
					} else { mixin(S_TRACE);
						prop.var.etc.scenarioPath = r[0u].summary.useTemp ? filterPath : dirName(filterPath);
					}
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
		auto r = loadScenariosFromFile(prop, opt, w, sync, status,
			files.toArray(), &put.put, failure, oThr);
		if (!oThr && r.length) put.put(r);
		return r;
	}
	return [];
}

LoadResult[] loadScenariosFromFile(Props prop, in LoadOption opt, Shell w, FileSync sync, void delegate(string) status,
		string[] files, void delegate(LoadResult[]) loaded = null, void delegate() failure = null, bool oThr = true) { mixin(S_TRACE);
	auto display = Display.getCurrent();
	if (oThr && loaded) { mixin(S_TRACE);
		auto thr = new LSFFThr!(true);
		thr.display = display;
		thr.prop = prop;
		thr.opt = opt;
		thr.sync = sync;
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
		sync.sync();
		LoadResult[] r;
		foreach (i, path; files) { mixin(S_TRACE);
			string[] errorFiles;
			auto s = loadScenarioFromFileImpl(prop, opt, errorFiles, w, sync, status, null, path, null, null, false, display);
			if (s) { mixin(S_TRACE);
				r ~= LoadResult(s, errorFiles);
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

Summary loadScenario(Props prop, in LoadOption opt, out string[] errorFiles, Shell w, FileSync sync, void delegate(string) status,
		Summary old, string dlgTitle, ref string[] openPaths,
		void delegate(Summary, in string[] errorFiles) loaded = null,
		void delegate() failure = null, bool oThr = true) { mixin(S_TRACE);
	string fname = selectScenario(prop, w, dlgTitle);
	if (fname) { mixin(S_TRACE);
		decScenarioPath(fname, openPaths, prop.var.etc.clickIsOpenEvent);
		auto put = new class Object {
			void delegate(Summary, in string[] errorFiles) loaded;
			void put(Summary r, in string[] errorFiles) { mixin(S_TRACE);
				if (loaded) loaded(r, errorFiles);
			}
		};
		put.loaded = loaded;
		auto r = loadScenarioFromFile(prop, opt, errorFiles, w, sync, status, old, fname, &put.put, failure, oThr);
		if (!oThr && r) put.put(r, errorFiles);
		return r;
	}
	return null;
}

Summary loadScenarioFromFile(Props prop, in LoadOption opt, out string[] errorFiles, Shell w, FileSync sync, void delegate(string) status,
		Summary old, string fname, void delegate(Summary, in string[] errorFiles) loaded = null, void delegate() failure = null, bool oThr = true) { mixin(S_TRACE);
	return loadScenarioFromFileImpl(prop, opt, errorFiles, w, sync, status, old, fname, loaded, failure, oThr, null);
}
private Summary loadScenarioFromFileImpl(Props prop, in LoadOption opt, out string[] errorFiles, Shell w, FileSync sync, void delegate(string) status,
		Summary old, string fname, void delegate(Summary, in string[] errorFiles) loaded = null, void delegate() failure = null, bool oThr = true, Display current = null,
		void delegate (uint) setMax = null, void delegate (uint) worked = null) { mixin(S_TRACE);
	if (oThr && loaded) { mixin(S_TRACE);
		auto thr = new LSFFThr!(false);
		thr.display = current ? current : Display.getCurrent();
		thr.current = current;
		thr.prop = prop;
		thr.opt = opt;
		thr.sync = sync;
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
		sync.sync();
		try { mixin(S_TRACE);
			Skin defSkin = .findSkin2(prop, prop.var.etc.defaultSkin, prop.var.etc.defaultSkinName);
			return Summary.loadScenarioFromFile(prop.parent, opt, errorFiles, fname,
				prop.tempPath, defSkin, null, old, setMax, worked,
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

/// シナリオロード時にエラーの出たファイルの一覧を示し、
/// シナリオを実際に読み込むかを指定させる。
class ScenarioErrorFilesDialog : AbsDialog {

	private Commons _comm = null;
	private const Summary _summ = null;
	private const string[] _errorFiles = [];

	private Table _files = null;

	this (Commons comm, Shell shell, const Summary summ, const string[] errorFiles)
	in {
		assert (summ !is null);
		assert (errorFiles.length);
	} body { mixin(S_TRACE);
		_comm = comm;
		_summ = summ;
		_errorFiles = errorFiles;
		super (_comm.prop, shell, true, _comm.prop.msgs.dlgTitScenarioLoadErrors,
			_comm.prop.images.warning, true, _comm.prop.var.scenarioLoadErrorsDlg);
		enterClose = true;
		firstFocusIsOK = true;
	}

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, true));

		auto fileName = (_summ.readOnlyPath != "" ? _summ.readOnlyPath : _summ.useTemp ? _summ.origZipName : _summ.scenarioPath).baseName();

		auto l = new Label(area, SWT.WRAP);
		l.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		if (fileName == "") { mixin(S_TRACE);
			l.setText(.tryFormat(_comm.prop.msgs.scenarioLoadErrorsNoFileName, _summ.scenarioName));
		} else { mixin(S_TRACE);
			l.setText(.tryFormat(_comm.prop.msgs.scenarioLoadErrors, _summ.scenarioName, fileName));
		}

		_files = .rangeSelectableTable(area, SWT.BORDER | SWT.MULTI | SWT.FULL_SELECTION);
		_files.setLayoutData(new GridData(GridData.FILL_BOTH));
		new FullTableColumn(_files, SWT.NONE);
		auto menu = new Menu(_files.getShell());
		createMenuItem(_comm, menu, MenuID.Copy, &copy, () => _files.getSelectionIndex() != -1);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.SelectAll, &selectAll, () => _files.getSelectionCount() < _files.getItemCount());
		_files.setMenu(menu);

		auto files = _errorFiles.dup;
		if (_comm.prop.var.etc.logicalSort) { mixin(S_TRACE);
			.sort!fnncmp(files);
		} else { mixin(S_TRACE);
			.sort!fncmp(files);
		}
		foreach (file; files) { mixin(S_TRACE);
			auto itm = new TableItem(_files, SWT.NONE);
			itm.setText(file);
		}
	}

	private void copy() { mixin(S_TRACE);
		string[] files;
		foreach (itm; _files.getSelection()) { mixin(S_TRACE);
			files ~= itm.getText();
		}
		auto text = new ArrayWrapperString(std.string.join(files, .newline));
		_comm.clipboard.setContents([text], [TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}

	private void selectAll() { mixin(S_TRACE);
		_files.selectAll();
	}
}
