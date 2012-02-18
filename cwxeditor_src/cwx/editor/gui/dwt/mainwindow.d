
module cwx.editor.gui.dwt.mainwindow;

import core.memory;
import core.thread;

import std.conv;
import std.file;
import std.path;
import std.zip;
import std.utf;
import std.process;
import std.metastrings;
import std.string;
import std.datetime;
import std.regex;
import std.array;
import std.algorithm;
debug import std.stdio;

import cwx.cwl;
import cwx.area;
import cwx.card;
import cwx.summary;
import cwx.event;
import cwx.flag;
import cwx.utils;
import cwx.archive;
import cwx.usecounter;
import cwx.props;
import cwx.skin;
import cwx.path;
import cwx.graphics;
import cwx.msgs;
import cwx.menu;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.datawindow;
import cwx.editor.gui.dwt.cardwindow;
import cwx.editor.gui.dwt.directorywindow;
import cwx.editor.gui.dwt.settingsdialog;
import cwx.editor.gui.dwt.replacedialog;
import cwx.editor.gui.dwt.dockingfolder;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.sbshell;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.flagspane;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.smalldialogs;
import cwx.editor.gui.dwt.loader;
import cwx.editor.gui.dwt.dmenu;

import org.eclipse.swt.SWTException;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.KeyListener;
import org.eclipse.swt.events.ControlAdapter;
import org.eclipse.swt.events.ControlEvent;
import org.eclipse.swt.events.MouseMoveListener;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.ShellAdapter;
import org.eclipse.swt.events.ShellEvent;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.events.MenuAdapter;
import org.eclipse.swt.events.MenuEvent;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.CoolBar;
import org.eclipse.swt.widgets.CoolItem;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.FileDialog;
import org.eclipse.swt.widgets.DirectoryDialog;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Link;
import org.eclipse.swt.widgets.TabFolder;
import org.eclipse.swt.widgets.Spinner;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CCombo;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Cursor;
import org.eclipse.swt.program.Program;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.layout.RowLayout;
import org.eclipse.swt.layout.RowData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.Clipboard;
import org.eclipse.swt.dnd.DropTarget;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.FileTransfer;
import org.eclipse.swt.dnd.TextTransfer;
import org.eclipse.swt.dnd.Transfer;
import java.lang.all;

version (Windows) {
	import std.c.windows.windows;
	private extern (Windows) {
		HANDLE CreateNamedPipeW(LPCWSTR, DWORD, DWORD,
			DWORD, DWORD, DWORD, DWORD, LPSECURITY_ATTRIBUTES);
		BOOL ConnectNamedPipe(HANDLE, OVERLAPPED*);
		BOOL DisconnectNamedPipe(HANDLE);
		const PIPE_ACCESS_DUPLEX = 0x3;
		const PIPE_TYPE_BYTE = 0x0;
		const PIPE_READMODE_BYTE = 0x0;
		const PIPE_WAIT = 0x0;
	}
} else {
	version (linux) {
		import std.c.linux.linux;
		import std.c.linux.socket;
		alias std.c.linux.linux.read cread;
		alias std.c.linux.linux.write cwrite;
		alias std.c.linux.socket.bind cbind;
	} else {
		import std.c.unix.unix;
		alias std.c.unix.unix.read cread;
		alias std.c.unix.unix.write cwrite;
		alias std.c.unix.unix.bind cbind;
	}
	import std.c.string;
	extern (C) {
		alias ushort sa_family_t;
		struct sockaddr_un {
			sa_family_t sun_family;
			char[sockaddr.sizeof - sa_family_t.sizeof] sun_path;
		}
	}
}

public:
class MainWindow : TopLevelPanel {
private:
	Display _display = null;
	bool _quit = false;
	Object _saveSync = null;

	SBShell _sbshl = null;
	Shell _win = null;
	DockingFolderCTC _dock = null;

	Props _prop;
	Commons _comm;

	DataWindow _dataWin = null;
	TableWindow _tableWin = null;
	FlagWindow _flagWin = null;
	MainCardWindow _cardWin = null;
	CastCardWindow _castWin = null;
	SkillCardWindow _skillWin = null;
	ItemCardWindow _itemWin = null;
	BeastCardWindow _beastWin = null;
	InfoCardWindow _infoWin = null;
	DirectoryWindow _dirWin = null;

	Menu _mExecEngine;
	Menu _tmExecEngine;
	void refreshExecEngine() {
		refreshExecEngineImpl(_mExecEngine, true);
		refreshExecEngineImpl(_tmExecEngine, false);
		setupMenu(_menu);
		setupMenu(_tool);
	}
	void refreshExecEngineImpl(Menu menu, bool autoSelect) {
		foreach (itm; menu.getItems()) {
			itm.dispose();
		}
		if (autoSelect) {
			_menu[MenuID.ExecEngine] = createMenuItem(_comm, menu, MenuID.ExecEngineAuto, &execEngine, &canExecEngine);
		}
		void putMenu(string path, string name, Image img) {
			createMenuItem2(_comm, menu, name, img, {
				if (path.length) {
					execEngineP(path);
				}
			}, () => path.length > 0);
		}
		if (_prop.var.etc.enginePath.length) {
			if (0 < menu.getItemCount()) {
				new MenuItem(menu, SWT.SEPARATOR);
			}
			putMenu(_prop.enginePath, "&0 " ~ _prop.enginePath.baseName.stripExtension, _prop.images.menu(MenuID.ExecEngine));
		}
		if (!_prop.var.etc.classicEngines.length) return;
		if (0 < menu.getItemCount()) {
			new MenuItem(menu, SWT.SEPARATOR);
		}
		foreach (i, ce; _prop.var.etc.classicEngines) {
			string name = .text(i + 1) ~ " " ~ ce.name;
			if (i + 1 <= 9) {
				name = "&" ~ name;
			}
			putMenu(ce.executePath(_prop.parent.appPath), name, _prop.images.classicEngine);
		}
	}

	void refreshTitle() {
		if (summary) {
			string path = summary.scenarioPath;
			_win.setText(_prop.msgs.mainWindowName(summary.scenarioName, path, summary.isChanged));
		} else {
			_win.setText(_prop.msgs.mainWindowName(null, null, false));
		}
	}

	private SysTime _lastBackup;
	void backupThr() {
		try {
			_lastBackup = Clock.currTime();
			while (!_quit) {
				if (_lastBackup + dur!"minutes"(_prop.var.etc.backupInterval) <= Clock.currTime()) {
					createBackup();
					_lastBackup = Clock.currTime();
				}
				core.thread.Thread.sleep(dur!"seconds"(1));
			}
			version (Console) {
				debug writeln("Exit Backup Thread");
			}
		} catch (Throwable e) {
			debugln(e);
		}
	}
	void createBackup() {
		try {
			if (_quit) return;
			if (!_prop.var.etc.backupEnabled) return;
			auto summ = summary;
			if (!summ) return;
			string parent = _prop.backupPath;
			auto bc = _prop.var.etc.backupCount;
			if (0 < bc) {
				string sPath = summ.scenarioPath;
				auto d = Clock.currTime();
				string file = .format("cwxeditor_backup_%04d%02d%02d%02d%02d%02d[%s].zip",
					d.year, d.month, d.day, d.hour, d.minute, d.second, sPath.baseName);
				string zFile = std.path.buildPath(parent, file);
				if (!parent.exists) mkdirRecurse(parent);
				synchronized (_saveSync) {
					summ.createZip(zFile, [], true);
				}
			}

			// 古いバックアップを削除する
			auto reg = .regex("^cwxeditor_backup_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]\\[.+\\]\\.zip$"d);
			auto files = clistdir(parent);
			string[] backup;
			foreach (f; files) {
				if (match(to!dstring(f), reg).empty) continue;
				backup ~= f;
			}
			if (backup.length <= bc) return;
			// 実際の更新日時よりファイル名に記述された日付を優先する
			backup = backup.sort;
			foreach (f; backup[0 .. backup.length - bc]) {
				f = std.path.buildPath(parent, f);
				try {
					std.file.remove(f);
				} catch (Exception e) {
					debugln(e);
				}
			}
		} catch (Exception e) {
			debugln(e);
		}
	}

	void createScenario() {
		if (qSave()) {
			auto dlg = new CreateScenarioDialog(_comm, _prop, _win);
			if (!dlg.open()) return;
			Summary summ;
			if (dlg.legacy) {
				summ = new Summary(dlg.name, dlg.skin, dlg.classicFolder, false, true);
			} else {
				auto p = Summary.createTempDir(_prop.tempPath, dlg.name);
				auto mFPath = std.path.buildPath(p, findSkin2(_prop, dlg.skin).materialPath);
				if (!exists(mFPath) || !isDir(mFPath)) std.file.mkdir(mFPath);
				summ = new Summary(dlg.name, dlg.skin, p, true, false);
				if (summ.expandXMLs) {
					summ.saveXMLs(summ.scenarioPath);
				}
			}
			summ.author = _prop.var.etc.defaultAuthor;
			openScenario(summ);
			statusLine = "";
		}
	}
	class DTListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){
			e.detail = DND.DROP_LINK;
		}
		override void drop(DropTargetEvent e) {
			auto arr = cast(FileNames) e.data;
			if (arr && arr.array.length > 0) {
				if (qSave()) {
					openScenario(arr.array[0]);
				}
			}
		}
	}
	void reload() {
		if (!summary) return;
		auto old = summary;
		if (old.useTemp && !old.zipName.length) {
			MessageBox.showWarning(_prop.msgs.reloadBeforeSaveError(old.scenarioName),
				_prop.msgs.dlgTitWarning, _win);
			return;
		}
		if (old && qSave(true)) {
			bool expand = old.expandXMLs;
			if (old.legacy) {
				auto wsm = std.path.buildPath(old.scenarioPath, "Summary.wsm");
				if (old.useTemp) {
					try {
						openScenario(old.reloadXMLs(_prop.var.etc.doubleIO));
					} catch (Exception e) {
						debugln(e);
						MessageBox.showWarning(_prop.msgs.reloadError
							(summary.scenarioPath) ~ "\n" ~ e.msg,
							_prop.msgs.dlgTitWarning, _win);
					}
				} else {
					if (!.exists(wsm)) wsm = old.scenarioPath;
					loadScenarioFromFile!(Summary)(_prop, _comm.mainShell, &setStatusLine, expand, old, wsm, &openScenario, null);
				}
			} else if (expand) {
				try {
					openScenario(old.reloadXMLs(_prop.var.etc.doubleIO));
				} catch (Exception e) {
					debugln(e);
					MessageBox.showWarning(_prop.msgs.reloadError
						(summary.scenarioPath) ~ "\n" ~ e.msg,
						_prop.msgs.dlgTitWarning, _win);
				}
			} else {
				assert (old.zipName.length);
				loadScenarioFromFile!(Summary)(_prop, _comm.mainShell, &setStatusLine, expand, old, old.zipName, &openScenario, null);
			}
		}
	}
	void openScenarioM() {
		if (qSave()) {
			openScenario();
		}
	}
	int cmp(string a, string b) {
		return std.string.cmp(a, b);
	}
	int ncmp(string a, string b) {
		return cwx.utils.ncmp(a, b);
	}
	void openScenario(Summary summ) {
		assert (summ);
		_lastBackup = Clock.currTime();
		_dirWin.stopTrace();
		scope (exit) _dirWin.resumeTrace();
		if (_prop.var.etc.logicalSort) {
			summ.flagDirRoot.sorter = &ncmp;
		} else {
			summ.flagDirRoot.sorter = &cmp;
		}
		summ.flagDirRoot.sortFlags(true);
		summ.flagDirRoot.sortSteps(true);
		auto old = summary;
		if (old) {
			addHistory();
		}
		if (summ.type.length && !hasSkin(_prop, summ.type)
				&& summ.type != _prop.var.etc.defaultSkin) {
			MessageBox.showWarning(_prop.msgs.useDefaultSkin(summ.type, _prop.var.etc.defaultSkin),
				_prop.msgs.dlgTitWarning, _win);
			summ.type = _prop.var.etc.defaultSkin;
		}
		summ.resetChanged();
		_comm.skin = findSkin(_comm, _prop, summ);
		_comm.closeAll();
		if (_dataWin) {
			_dataWin.load(summ);
		} else {
			_tableWin.load(summ);
			_flagWin.load(summ);
		}
		if (_cardWin) _cardWin.refresh(summ);
		if (_castWin) _castWin.refresh(summ);
		if (_skillWin) _skillWin.refresh(summ);
		if (_itemWin) _itemWin.refresh(summ);
		if (_beastWin) _beastWin.refresh(summ);
		if (_infoWin) _infoWin.refresh(summ);
		_dirWin.refresh(summ);
		_comm.refScenario.call(summ);
		_comm.refScenarioName.call();
		_comm.refScenarioPath.call();
		if (!dock) {
			if (_prop.var.dataWin.visible) _comm.openDataWin(false);
			if (_prop.var.cardWin.visible) _comm.openBindCardWin(false);
			if (_prop.var.dirWin.visible) _comm.openDirWin(false);
		}
		setupMenu(_menu);
		setupMenu(_tool);
		string fullHist = "";
		if (_prop.var.etc.reconstruction) {
			fullHist = findFullHist(createHistString(summary));
		}
		bool opened = false;
		string openedS = "";
		if (_prop.var.etc.reconstruction) {
			auto paths = fullHistToCWXPaths(fullHist);
			if (paths.length) {
				statusLine = _prop.msgs.reconstructionStatus(0, paths.length);
				foreach (i, cwxPath; paths) {
					if (openCWXPath(cwxPath, false)) {
						opened = true;
						openedS = statusLine;
						statusLine = _prop.msgs.reconstructionStatus(i + 1, paths.length);
					} else {
						statusLine = _prop.msgs.reconstructionStatus(i + 1, paths.length);
					}
				}
			}
		}
		addHistory();
		try {
			if (old) {
				synchronized (_saveSync) {
					old.delTemp();
				}
			}
		} catch (Exception e) {
			debugln(e);
		}
		if (!opened || !openedS.length) {
			statusLine = _prop.msgs.loaded(summ.scenarioName);
		} else {
			statusLine = openedS;
		}
		summ.changedEventForce ~= &_comm.changed.call;
		summ.changedEvent ~= &refreshTitle;
		refreshTitle();
		GC.collect();
		_win.redraw();
	}
	string _firstScenarioPath = null;
	string[] _openPaths;

	void openScenarioImpl(Summary summ) {
		if (summ) {
			openScenario(summ);
			foreach (path; _openPaths) {
				try {
					if (openCWXPath(path, true)) {
						continue;
					}
				} catch (Exception e) {
					debugln(e);
				}
				MessageBox.showWarning(_prop.msgs.cwxPathOpenError(path), _prop.msgs.dlgTitWarning, _win);
			}
			_openPaths.length = 0u;
		}
	}
	void openScenario() {
		auto old = summary;
		loadScenario!(Summary)(_prop, _comm.mainShell, &setStatusLine,
			_prop.var.etc.expandXMLs, old, _prop.msgs.dlgTitOpenScenario,
			_openPaths, &openScenarioImpl, null);
	}
	void openScenario(string fname, void delegate() failure = null) {
		if (cfnmatch(cwx.utils.getExt(fname), "wsm") && !.exists(fname)) {
			fname = dirName(fname);
		}
		decScenarioPath(fname, _openPaths);
		auto old = summary;
		loadScenarioFromFile!(Summary)(_prop, _comm.mainShell, &setStatusLine,
			_prop.var.etc.expandXMLs, old, fname, &openScenarioImpl, failure);
	}
	void playSavedSound() {
		string file = _prop.var.etc.savedSound;
		if (file.length && .exists(file)) {
			playSE(file, false);
		}
	}
	void saveScenario() {
		auto fc = _win.getDisplay().getFocusControl();
		save(fc.getShell());
	}
	void savec(Shell shell) {
		save(shell);
	}
	bool save(Shell shell) {
		if (summary) {
			_dirWin.pauseTrace();
			scope (exit) {
				_dirWin.resumeTrace();
			}
			if (!summary.isSaved) {
				// いまだ保存されていない場合は名前をつけて保存
				return __saveScenarioA(shell);
			} else {
				auto cursors = setWaitCursors(shell);
				scope (exit) {
					resetCursors(cursors);
				}
				try {
					synchronized (_saveSync) {
						summary.saveOverwrite(_prop.parent, _prop.var.etc.doubleIO, _prop.var.etc.saveInnerImagePath);
					}
					_comm.saved.call();
					refreshTitle();
					addHistory();
					GC.collect();
					playSavedSound();
					return true;
				} catch (SummaryException e) {
					debugln(e);
					MessageBox.showWarning(e.msg, _prop.msgs.dlgTitWarning, shell);
					return false;
				}
			}
		}
		return true;
	}
	void saveScenarioA() {
		__saveScenarioA(_win);
	}
	bool __saveScenarioA(Shell shell) {
		if (summary) {
			auto dlg = new FileDialog(shell, SWT.PRIMARY_MODAL | SWT.APPLICATION_MODAL | SWT.SINGLE | SWT.SAVE);
			dlg.setFilterExtensions(["*.wsn"]);
			dlg.setFilterNames([_prop.msgs.filterScenarioSave]);
			dlg.setText(_prop.msgs.dlgTitSaveScenario);
			dlg.setFilterPath(scenarioFilterPath(_prop));
			dlg.setFileName(setExtension(summary.scenarioName, "wsn"));
			dlg.setOverwrite(true);
			string fname = dlg.open();
			if (fname) {
				auto cursors = setWaitCursors(shell);
				scope (exit) resetCursors(cursors);
				_dirWin.pauseTrace();
				scope (exit) _dirWin.resumeTrace();
				string tempPath = _prop.tempPath;
				bool expandXMLs = _prop.var.etc.expandXMLs;
				Skin defSkin = .findSkin2(_prop, _prop.var.etc.defaultSkin);
				try {
					synchronized (_saveSync) {
						summary.saveWithName(_prop.parent, _prop.var.etc.doubleIO,
							_prop.var.etc.saveInnerImagePath,
							fname, tempPath, expandXMLs, defSkin, (string msg) {
								MessageBox.showWarning(msg, _prop.msgs.dlgTitWarning, shell);
							});
					}
					_comm.skin = findSkin(_comm, _prop, summary);
					_comm.saved.call();
					refreshTitle();
					_comm.refScenarioPath.call();
					_comm.refSkin.call();
					_comm.refPaths.call("");
					addHistory();
					GC.collect();
					playSavedSound();
				} catch (SummaryException e) {
					debugln(e);
					MessageBox.showWarning(e.msg, _prop.msgs.dlgTitWarning, shell);
				}
			}
		}
		return false;
	}
	void execEngineP(string path) {
		if (!exec(path, dirName(nabs(path)))) {
			MessageBox.showWarning(_prop.msgs.errorExecEngine(path),
				_prop.msgs.dlgTitWarning, _win);
		}
	}
	@property
	bool canExecEngine() {
		string engine = summary ? _comm.skin.executeEngine : _prop.enginePath;
		return engine.length > 0;
	}
	void execEngine() {
		string engine = summary ? _comm.skin.executeEngine : _prop.enginePath;
		if (engine.length) {
			execEngineP(engine);
		}
	}
	private void openDataWindow() {
		if (summary || dock) {
			_prop.var.dataWin.visible = true;
			_comm.openDataWin(true);
		}
	}
	private void openFlagWindow() {
		if (dock) {
			_comm.openFlagWin(true);
		}
	}
	private void openCardWindow() {
		assert (_cardWin);
		if (summary || dock) {
			_prop.var.cardWin.visible = true;
			_comm.openBindCardWin(true);
		}
	}
	private void openDirWindow() {
		if (summary || dock) {
			_prop.var.dirWin.visible = true;
			_comm.openDirWin(true);
		}
	}
	void exitAll() {
		if (qSave()) {
			_win.close();
		}
	}
	private ReplaceDialog _replDlg = null;
	void replaceText() {
		openReplWin();
	}
	void clipboardToXML() {
		auto c = _comm.clipboard.getContents(XMLBytesTransfer.getInstance());
		if (c !is null && isXMLBytes(c)) {
			_comm.clipboard.setContents([new ArrayWrapperString(bytesToXML(c))], [TextTransfer.getInstance()]);
		}
	}

	bool qSave(bool reload = false) {
		if (_comm.isChanged) {
			MessageBox dlg;
			if (reload) {
				dlg = new MessageBox(_win, SWT.OK | SWT.CANCEL | SWT.ICON_QUESTION);
				dlg.setMessage(_prop.msgs.dlgMsgIsSaveBeforeReload(summary.scenarioName));
			} else {
				dlg = new MessageBox(_win, SWT.YES | SWT.NO | SWT.CANCEL | SWT.ICON_QUESTION);
				dlg.setMessage(_prop.msgs.dlgMsgIsSaveBeforeExit(summary.scenarioName));
			}
			dlg.setText(_prop.msgs.dlgTitQuestion);
			_win.setMinimized(false);
			switch (dlg.open()) {
			case SWT.YES, SWT.OK:
				return reload ? true : save(_win);
			case SWT.NO:
				return true;
			case SWT.CANCEL:
				return false;
			default: assert (0);
			}
		}
		return true;
	}

	private CoolBar _cbar = null;
	class SListener : ShellAdapter {
		override void shellClosed(ShellEvent e) {
			e.doit = qSave();
			if (e.doit) {
				if (summary && !_comm.isChanged) {
					writeDock();
				}
				_comm.closeAll();
			}
		}
	}
	class DListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_quit = true;
			_prop.var.etc.lastScenario = summary ? createHistString(summary) : "";
			_comm.save.remove(&savec);
			_comm.refScenarioName.remove(&refreshTitle);
			_comm.refScenarioPath.remove(&refreshTitle);
			_comm.refWallpaper.remove(&redrawAll);
			_comm.replText.remove(&refreshTitle);
			_comm.refClassicSkin.remove(&refreshExecEngine);
			_comm.refHistories.remove(&createFileMenu);
			auto b = _win.getBounds();
			_prop.var.mainWin.x = b.x;
			_prop.var.mainWin.y = b.y;
			if (dock) {
				_prop.var.mainWin.maximized = _win.getMaximized();
				if (!_prop.var.mainWin.maximized) {
					_prop.var.mainWin.width = b.width;
					_prop.var.mainWin.height = b.height;
				}
			}
			stopSE();
			stopBGM();
			_win.setVisible(false);
			scope (failure) _win.setVisible(true);
			_comm.refScenario.call(null);
			_comm.closeAll();
			if (summary && summary.useTemp) {
				_dirWin.stopTrace();
				try {
					synchronized (_saveSync) {
						summary.delTemp();
					}
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
	}
	void sendReloadProps() {
		sendToPipe((string recv) {
			if (!recv) {
				return "reload settings";
			}
			return "";
		}, {
			return true;
		});
	}
	void reloadProps() {
		auto oldStgs = OldSettings(_prop);
		scope (exit) {
			oldStgs.raiseEvent(_comm);
		}
		_prop.var.reload();
	}
	private SettingsDialog _stgDlg = null;
	void settings() {
		if (_stgDlg) {
			_stgDlg.active();
		} else {
			_stgDlg = new SettingsDialog(_comm, _prop, _win, _dock, summary, &sendReloadProps);
			_stgDlg.closeEvent ~= {
				_stgDlg = null;
			};
			_stgDlg.open();
		}
	}

	string findFullHist(string hist) {
		if ("" == hist) return hist;
		auto hists = _prop.var.etc.openHistories.dup;
		foreach (i, h; hists) {
			if (cfnmatch(fullHistToHist(h), hist)) {
				hist = h;
				break;
			}
		}
		return hist;
	}
	static string createHistString(Summary summary) {
		if (!summary) return "";
		string hist;
		if (summary.legacy) {
			if (summary.useTemp) {
				hist = summary.zipName;
			} else {
				hist = std.path.buildPath(summary.scenarioPath, "Summary.wsm");
			}
		} else if (summary.useTemp) {
			hist = summary.zipName;
			if (!hist.length) return "";
		} else {
			hist = std.path.buildPath(summary.scenarioPath, "Summary.xml");
		}
		return nabs(hist);
	}
	string createFullHistString() {
		string hist = createHistString(summary);
		if ("" == hist) return "";
		if (_prop.var.etc.reconstruction) {
			hist = "\"" ~ hist ~ "\" " ~ std.string.join(openedCWXPath, CWXPATH_SEP.idup);
		}
		return hist;
	}
	void writeDock() {
		string hist = createHistString(summary);
		if ("" == hist) return;
		auto hists = _prop.var.etc.openHistories.dup;
		foreach (i, h; hists) {
			if (cfnmatch(fullHistToHist(h), hist)) {
				if (_prop.var.etc.reconstruction) {
					hists[i] = createFullHistString();
				} else {
					hists[i] = hist;
				}
				_prop.var.etc.openHistories = hists;
				break;
			}
		}
	}
	/// `"/foo/bar" /cwx:0/path:0...` -> `/foo/bar`
	static string fullHistToHist(string hist) {
		if (std.string.startsWith(hist, "\"")) {
			int i = std.string.indexOf(hist["\"".length .. $], "\"");
			if (-1 != i) {
				return hist["\"".length .. i + "\"".length];
			}
		}
		return hist;
	} unittest {
		assert (fullHistToHist(r"C:\test\test1") == r"C:\test\test1");
		assert (fullHistToHist(`"C:\test\test1" aaa`) == r"C:\test\test1");
	}
	/// `"/foo/bar" /cwx:0/path:0&/cwx:1/path1:0` -> [`/cwx:0/path:0`, `/cwx:1/path:1`]
	static string[] fullHistToCWXPaths(string hist) {
		if (std.string.startsWith(hist, "\"")) {
			int i = std.string.indexOf(hist["\"".length .. $], "\"");
			if (-1 != i) {
				return std.string.split(strip(hist[i + "\"".length + 1 .. $]), CWXPATH_SEP.idup);
			}
		}
		return [];
	} unittest {
		assert (fullHistToCWXPaths(r"C:\test\test1") == []);
		assert (fullHistToCWXPaths(`"C:\test\test1" aaa&bbb`) == ["aaa", "bbb"]);
	}
	void delHist(string fullHist) {
		auto hists = _prop.var.etc.openHistories.dup;
		string hist = fullHistToHist(fullHist);
		string[] hists2;
		foreach (i, h; hists) {
			if (!cfnmatch(fullHistToHist(h), hist)) {
				hists2 ~= h;
			}
		}
		_prop.var.etc.openHistories = hists2;
		writeDock();
		_prop.var.save(dock);
		sendReloadProps();
		_comm.refHistories.call();
	}
	void addHistory() {
		string hist = createFullHistString();
		if ("" == hist) return;
		string p = fullHistToHist(hist);
		_prop.var.etc.scenarioPath = summary.useTemp ? dirName(p) : dirName(dirName(p));
		auto hists = _prop.var.etc.openHistories.dup;
		foreach (i, h; hists) {
			if (cfnmatch(fullHistToHist(h), p)) {
				// すでに履歴中に存在するため、最新位置に移動
				hist = h;
				_prop.var.etc.openHistories = hists[0 .. i] ~ hists[i + 1 .. $];
				hists = _prop.var.etc.openHistories.dup;
				break;
			}
		}
		_prop.var.etc.openHistories
			= [hist] ~ (hists.length < _prop.var.etc.historyMax ? hists : hists[0 .. $ - 1]);
		_prop.var.etc.lastScenario = p;
		writeDock();
		_prop.var.save(dock);
		sendReloadProps();
		_comm.refHistories.call();
	}
	class Hist {
		private string _hist;
		this(Menu menu, int num, string hist) {
			hist = fullHistToHist(hist);
			string text;
			Image img;
			auto snipLen = _prop.var.etc.historySnipLength;
			if (cfnmatch(baseName(hist), "Summary.xml")) {
				text = cuthist(hist[0u .. $ - "Summary.xml".length - std.path.sep.length], snipLen);
				img = _prop.images.summaryFile;
			} else if (cfnmatch(cwx.utils.getExt(hist), "wsn")) {
				text = cuthist(hist, snipLen);
				img = _prop.images.scenarioArchive;
			} else if (cfnmatch(baseName(hist), "Summary.wsm")) {
				text = cuthist(hist[0u .. $ - "Summary.wsm".length - std.path.sep.length], snipLen);
				img = _prop.images.classic;
			} else if (cfnmatch(cwx.utils.getExt(hist), "cab") || cfnmatch(cwx.utils.getExt(hist), "zip")) {
				text = cuthist(hist, snipLen);
				img = _prop.images.scenarioArchive;
			} else {
				text = cuthist(hist, snipLen);
				img = _prop.images.unknown;
			}
			string nstr;
			if (num < 10) {
				nstr = "&" ~ to!(string)(num);
			} else {
				nstr = to!(string)(num);
			}
			createMenuItem2(_comm, menu, nstr ~ " " ~ text, img, &run, null);
			_hist = hist;
		}
		private void run() {
			if (qSave()) {
				openScenario(_hist, &delHist);
			}
		}
		private void delHist() {
			auto dlg = new MessageBox(_win, SWT.ICON_QUESTION | SWT.YES | SWT.NO);
			string h = _hist;
			string ext = cwx.utils.getExt(h);
			if (cfnmatch(ext, "xml") || cfnmatch(ext, "wsm") || cfnmatch(ext, "wid")) {
				h = dirName(h);
			}
			dlg.setMessage(_prop.msgs.scenarioNotFound(h));
			dlg.setText(_prop.msgs.dlgTitQuestion);
			if (SWT.YES == dlg.open()) {
				this.outer.delHist(_hist);
			}
		}
		private static string cuthist(string hist, int cut) {
			hist = nabs(hist);
			scope dhist = toUTF32(hist);
			if (dhist.length > cut + "..."d.length) {
				auto drive = driveName(hist);
				int rlen = drive ? toUTF32(drive).length + 1 : 1;
				int flen = toUTF32(baseName(hist)).length + 1;
				int plen = cut - flen;
				if (plen < rlen) plen = rlen;
				return toUTF8(dhist[0 .. plen] ~ "..." ~ dhist[$ - flen .. $]);
			} else {
				return hist;
			}
		} unittest {
			version (Windows) {
				string result;
				result = cuthist(r"C:\Documents and Settings\aaaaaaaaaaaa\bbbbbbbbbb\test.file", 30);
				assert (result == r"C:\Documents and Set...\test.file", result);
				result = cuthist(r"C:\Documents and Settings\aaaaaaaaaaaa\bbbbbbbbbb\test.file", 10);
				assert (result == r"C:\...\test.file", result);
				result = cuthist(r"C:\Documents and Settings\aaaaaaaaaaaa\bbbbbbbbbb\test.file", 11);
				assert (result == r"C:\...\test.file", result);
				result = cuthist(r"C:\Documents and Settings\aaaaaaaaaaaa\bbbbbbbbbb\test.file", 12);
				assert (result == r"C:\...\test.file", result);
				result = cuthist(r"C:\Documents and Settings\aaaaaaaaaaaa\bbbbbbbbbb\test.file", 13);
				assert (result == r"C:\...\test.file", result);
				result = cuthist(r"C:\Documents and Settings\aaaaaaaaaaaa\bbbbbbbbbb\test.file", 14);
				assert (result == r"C:\D...\test.file", result);
				result = cuthist(r"C:\simple\test.file", 35);
				assert (result == r"C:\simple\test.file", result);
				result = cuthist(r"C:\simple\test.file", 19);
				assert (result == r"C:\simple\test.file", result);
				result = cuthist(r"C:\simple\test.file", 18);
				assert (result == r"C:\simple\test.file", result);
				result = cuthist(r"C:\simple\test.file", 17);
				assert (result == r"C:\simple\test.file", result);
				result = cuthist(r"C:\simple\test.file", 16);
				assert (result == r"C:\simple\test.file", result);
				result = cuthist(r"C:\simple\test.file", 15);
				assert (result == r"C:\si...\test.file", result);
				result = cuthist(r"C:\日本語\テスト.file", 12);
				assert (result == r"C:\日本語\テスト.file", result);
				result = cuthist(r"C:\日本語\テスト.file", 11);
				assert (result == r"C:\...\テスト.file", result);
				result = cuthist(r"C:\日本語日本語\テスト.file", 13);
				assert (result == r"C:\日...\テスト.file", result);
			}
		}
	}
	private Menu _menuFile;
	void createFileMenu() {
		foreach (itm; _menuFile.getItems()) {
			itm.dispose();
		}
		mixin (MenuAction!("_menuFile", MenuID.New, SWT.PUSH, "createScenario", "null"));
		mixin (MenuAction!("_menuFile", MenuID.Open, SWT.PUSH, "openScenarioM", "null"));
		mixin (MenuAction!("_menuFile", MenuID.Save, SWT.PUSH, "saveScenario", "() => summary !is null"));
		mixin (MenuAction!("_menuFile", MenuID.SaveAs, SWT.PUSH, "saveScenarioA", "() => summary !is null"));
		new MenuItem(_menuFile, SWT.SEPARATOR);
		mixin (MenuAction!("_menuFile", MenuID.CreateArchive, SWT.PUSH, "_dirWin.createArchive", "&_dirWin.canCreateArchive"));
		new MenuItem(_menuFile, SWT.SEPARATOR);
		mixin (MenuAction!("_menuFile", MenuID.Reload, SWT.PUSH, "reload", "() => summary !is null"));
		new MenuItem(_menuFile, SWT.SEPARATOR);
		auto hists = _prop.var.etc.openHistories;
		foreach (i, hist; hists) {
			new Hist(_menuFile, i + 1, hist);
		}
		if (hists.length > 0) new MenuItem(_menuFile, SWT.SEPARATOR);
		createMenuItem(_comm, _menuFile, MenuID.Close, &exitAll, null);
		setupMenu(_menu);
	}
	static const PIPE_APP_MAX = 256;
	string _pipeName = "";
	class OpenCWXPath : Runnable {
		string path;
		override void run() {
			auto paths = std.string.split(path, CWXPATH_SEP.idup);
			if (!paths.length) paths = [""];
			foreach (p; paths) {
				try {
					openCWXPath(p, true);
				} catch (Throwable e) {
					debugln (e);
				}
			}
		}
	}
	class ReloadSettings : Runnable {
		override void run() {
			try {
				reloadProps();
			} catch (Throwable e) {
				debugln (e);
			}
		}
	}
	void pipeThr() {
		try {
			auto openPath = new OpenCWXPath;
			auto reloadSettings = new ReloadSettings;
			createPipeName();
			if (!_pipeName.length) return;
			Summary summ = null;
			string recvSend(in char[] recv, out bool quit) {
				quit = false;
				if (recv == "quit") {
					quit = true;
					return null;
				} else if (recv == "get opened scenario") {
					summ = summary;
					if (!summ) return null;
					string send = "opened scenario ";
					if (summ.useTemp) {
						send ~= summ.zipName;
					} else {
						send ~= summ.scenarioPath;
					}
					return send;
				} else if (std.string.startsWith(recv.idup, "open cwxpath ")) {
					openPath.path = recv["open cwxpath ".length .. $].idup;
					_display.asyncExec(openPath);
					return null;
				} else if (recv == "reload settings") {
					_display.asyncExec(reloadSettings);
				}
				return null;
			}
			version (Windows) {
				auto pipe = CreateNamedPipeW(toUTFz!(wchar*)(_pipeName), PIPE_ACCESS_DUPLEX,
					PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,
					1, MAX_PATH, MAX_PATH, 1000, null);
				if (pipe == INVALID_HANDLE_VALUE) return;
				scope (exit) CloseHandle(pipe);
				char[MAX_PATH] buf;
				DWORD len;
				bool quit = false;
				while (!quit && ConnectNamedPipe(pipe, null)) {
					scope (exit) DisconnectNamedPipe(pipe);
					while (true) {
						if (!ReadFile(pipe, buf.ptr, buf.length, &len, null)) break;
						auto recv = buf[0 .. len];
						string send = recvSend(recv, quit);
						if (quit) break;
						if (!send) break;
						if (!WriteFile(pipe, send.ptr, send.length, &len, null)) break;
					}
				}
			} else {
				auto pipe = socket(PF_UNIX, SOCK_STREAM, 0);
				if (pipe == -1) return -1;
				scope (exit) close(pipe);
				sockaddr_un laddr;
				laddr.sun_family = AF_UNIX;
				strcpy(&(laddr.sun_path[1]), _pipeName.ptr);
				if (0 != cbind(pipe, cast(sockaddr*) &laddr, laddr.sizeof)) return;
				if (0 != listen(pipe, 1)) return -1;
				char[4096] buf;
				int len;
				typeof(pipe) rsock;
				sockaddr_un raddr;
				socklen_t rsocklen;
				bool quit = false;
				while (!quit && -1 != (rsock = accept(pipe, cast(sockaddr*) &raddr, &rsocklen))) {
					scope (exit) close(rsock);
					while (true) {
						if (-1 == (len = cread(pipe, buf.ptr, buf.length))) break;
						string recv = buf[0 .. len];
						string send = recvSend(recv, quit);
						if (quit) break;
						if (!send) break;
						if (-1 == cwrite(pipe, send.ptr, send.length)) break;
					}
				}
				close(pipe);
			}
			version (Console) {
				debug writeln("Exit Pipe Thread");
			}
		} catch (Exception e) {
			debugln(e);
		}
	}
	/// このプロセスが待ち受けする際のパイプ名を生成。
	void createPipeName() {
		version (Windows) {
			for (size_t i = 0; i < PIPE_APP_MAX; i++) {
				string pipeName = r"\\.\pipe\cwxeditor_" ~ to!(string)(i);
				auto p = CreateFileW(toUTFz!(wchar*)(pipeName),
					GENERIC_READ | GENERIC_WRITE, 0, null, OPEN_EXISTING, 0, null);
				if (p == INVALID_HANDLE_VALUE) {
					_pipeName = pipeName;
					break;
				}
				CloseHandle(p);
			}
		} else {
			for (size_t i = 0; i < PIPE_APP_MAX; i++) {
				string pipeName = r"/pipe/cwxeditor_" ~ to!(string)(i);
				auto p = socket(PF_UNIX, SOCK_STREAM, 0);
				if (-1 == p) continue;
				scope (exit) close(p);
				sockaddr_un raddr;
				raddr.sun_family = AF_INET;
				strcpy(&(raddr.sun_path[1]), pipeName.ptr);
				if (-1 == connect(p, cast(sockaddr*) &raddr, raddr.sizeof)) {
					_pipeName = pipeName;
					break;
				}
			}
		}
	}
	/// CWXEditorのプロセスに対してパイプを通じてメッセージを送る。
	void sendToPipe(string delegate(string) sendRecv, bool delegate() next) {
		version (Windows) {
			char[MAX_PATH] buf;
			DWORD len;
			for (size_t i = 0; i < PIPE_APP_MAX; i++) {
				if (!next()) break;
				string pipeName = r"\\.\pipe\cwxeditor_" ~ to!(string)(i);
				if (_pipeName == pipeName) continue;
				auto p = CreateFileW(toUTFz!(wchar*)(pipeName),
					GENERIC_READ | GENERIC_WRITE, 0, null, OPEN_EXISTING, 0, null);
				if (p == INVALID_HANDLE_VALUE) {
					continue;
				}
				scope (exit) CloseHandle(p);
				string recv = null;
				while (true) {
					string send = sendRecv(recv);
					if (!send || !send.length) break;
					if (!WriteFile(p, send.ptr, send.length, &len, null)) break;
					if (!ReadFile(p, buf.ptr, buf.length, &len, null)) break;
					recv = buf[0 .. len].idup;
				}
			}
		} else {
			char[4096] buf;
			for (size_t i = 0; i < PIPE_APP_MAX; i++) {
				if (!next()) break;
				string pipeName = r"/pipe/cwxeditor_" ~ to!(string)(i);
				if (_pipeName == pipeName) continue;
				auto p = socket(PF_UNIX, SOCK_STREAM, 0);
				if (-1 == p) continue;
				scope (exit) close(p);
				sockaddr_un raddr;
				raddr.sun_family = AF_INET;
				strcpy(&(raddr.sun_path[1]), pipeName.ptr);
				if (-1 == connect(p, cast(sockaddr*) &raddr, raddr.sizeof)) {
					continue;
				}
				string recv = null;
				while (true) {
					string send = sendRecv(recv);
					if (!send || !send.length) break;
					if (-1 == cwrite(p, send.ptr, send.length)) break;
					int len = cread(p, buf.ptr, buf.length);
					if (-1 == len) break;
					recv = buf[0 .. len].idup;
				}
			}
		}
	}
public:
	this (string appPath, string confFilePath, cwx.system.System sys,
			string firstScenarioPath = null, string[] openPaths = []) {
		string dStr = .text(__LINE__); // 起動ログ
		try {
			dStr ~= " - " ~ .text(__LINE__);
			decScenarioPath(firstScenarioPath, openPaths);
			/// すでにfirstScenarioPathを開いている
			/// 既存のcwxeditorプロセスがある場合、
			/// そちらを開くようにする。
			string path1 = "";
			dStr ~= " - " ~ .text(__LINE__);
			if (firstScenarioPath && .exists(firstScenarioPath)) {
				path1 = nabs(firstScenarioPath);
				auto ext = cwx.utils.getExt(path1);
				if (!.isDir(path1)
						&& (cfnmatch(ext, "xml") || cfnmatch(ext, "wsm") || cfnmatch(ext, "wid"))) {
					path1 = nabs(dirName(path1));
				}
			}
			bool execute = true;
			dStr ~= " - " ~ .text(__LINE__);
			sendToPipe((string recv) {
				if (!recv) {
					return "get opened scenario";
				} else if (std.string.startsWith(recv, "opened scenario ")) {
					if (cfnmatch(path1, nabs(recv["opened scenario ".length .. $]))) {
						string send = "open cwxpath ";
						foreach (j, s; openPaths) {
							if (j > 0) send ~= CWXPATH_SEP;
							send ~= s;
						}
						path1 = "";
						execute = false;
						return send;
					} else {
						return "";
					}
				} else {
					return "";
				}
			}, {
				return path1.length > 0;
			});
			dStr ~= " - " ~ .text(__LINE__);
			if (!execute) return;
			_firstScenarioPath = firstScenarioPath;
			_openPaths = openPaths;
			_saveSync = new Object;
			dStr ~= " - " ~ .text(__LINE__);
			_prop = new Props(confFilePath, new CProps(appPath, sys));
			if (exists(_prop.tempPath)) {
				dStr ~= " - " ~ .text(__LINE__);
				foreach (temp; clistdir(_prop.tempPath)) {
					temp = std.path.buildPath(_prop.tempPath, temp);
					if (exists(temp) && isDir(temp)) {
						auto lock = std.path.buildPath(temp, "cwxeditor.lock");
						if (exists(lock)) {
							try {
								std.file.remove(lock);
								delAll(temp);
							} catch (Exception e) {}
						} else if (fnstartsWith(baseName(temp), "cwxeditor_temp_")) {
							try {
								delAll(temp);
							} catch (Exception e) {}
						}
					}
				}
			}

			dStr ~= " - " ~ .text(__LINE__);
			_comm = new Commons(_prop);
			_comm.skin = findSkin2(_prop, _prop.var.etc.defaultSkin);
			dStr ~= " - " ~ .text(__LINE__);

			auto d = new Display;
			_display = d;
			d.setAppName(_prop.msgs.application);
			dStr ~= " - " ~ .text(__LINE__);

			string engineDir = "";
			if (_prop.enginePath.length && .exists(_prop.enginePath)) {
				dStr ~= " - " ~ .text(__LINE__);
				engineDir = dirName(nabs(_prop.enginePath));
				auto skinTable = .skinTable(_prop);
				if (!(_prop.var.etc.defaultSkin in skinTable)) {
					MessageBox.showWarning(_prop.msgs.loadSkinError(_prop.var.etc.defaultSkin),
						_prop.msgs.dlgTitWarning, null);
				}
			}

			if (_prop.var.etc.singleWindow) {
				dStr ~= " - " ~ .text(__LINE__);
				_sbshl = new SBShell(null, SWT.SHELL_TRIM);
			} else {
				dStr ~= " - " ~ .text(__LINE__);
				_sbshl = new SBShell(null, SWT.DIALOG_TRIM | SWT.MIN);
			}
			dStr ~= " - " ~ .text(__LINE__);
			_win = _sbshl.shell();
			_win.setData(new TLPData(this));
			_win.setImage(_prop.images.app);

			dStr ~= " - " ~ .text(__LINE__);
			_comm.save.add(&savec);
			_comm.refScenarioName.add(&refreshTitle);
			_comm.refScenarioPath.add(&refreshTitle);
			_comm.refWallpaper.add(&redrawAll);
			_comm.replText.add(&refreshTitle);
			_comm.refClassicSkin.add(&refreshExecEngine);
			_comm.refHistories.add(&createFileMenu);
			_win.addDisposeListener(new DListener);
			_win.addShellListener(new SListener);
			_comm.refreshWallpaper(_prop);
			dStr ~= " - " ~ .text(__LINE__);
			foreach (f; _prop.looks.fontFiles) {
				d.loadFont(std.path.buildPath(engineDir, f));
			}
			dStr ~= " - " ~ .text(__LINE__);
			_win.setText(_prop.msgs.mainWindowName(null, null, false));
			if (_prop.var.etc.singleWindow) {
				_sbshl.contentPane.setLayout(zeroGridLayout(1, true));
			} else {
				_sbshl.contentPane.setLayout(windowGridLayout(1, true));
			}
			dStr ~= " - " ~ .text(__LINE__);
			auto toolComp = new Composite(_sbshl.contentPane, SWT.NONE);
			toolComp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			toolComp.setLayout(new FillLayout);
			if (_prop.var.etc.singleWindow) {
				dStr ~= " - " ~ .text(__LINE__);
				auto dockComp = new Composite(_sbshl.contentPane, SWT.NONE);
				dockComp.setLayoutData(new GridData(GridData.FILL_BOTH));
				dockComp.setLayout(windowGridLayout(1, true));
				dStr ~= " - " ~ .text(__LINE__);
				_dock = _prop.var.loadDock(dockComp, SWT.NONE, delegate Control(Composite parent, string key) {
					scope (exit) {
						dStr ~= " - " ~ .text(__LINE__);
					}
					switch (key) {
					case "data": {
						dStr ~= " - " ~ .text(__LINE__);
						_tableWin = new TableWindow(_comm, _prop, _win, parent);
						return _tableWin.shell;
					}
					case "flag": {
						dStr ~= " - " ~ .text(__LINE__);
						_flagWin = new FlagWindow(_comm, _prop, _win, parent);
						return _flagWin.shell;
					}
					case "card": {
						dStr ~= " - " ~ .text(__LINE__);
						if (_prop.var.etc.bindCardViews) {
							_cardWin = new MainCardWindow(_comm, _prop, parent);
							return _cardWin.shell;
						}
						return null;
					}
					case "castCard": {
						dStr ~= " - " ~ .text(__LINE__);
						if (!_prop.var.etc.bindCardViews) {
							_castWin = new CastCardWindow(_comm, _prop, parent);
							return _castWin.shell;
						}
						return null;
					}
					case "skillCard": {
						dStr ~= " - " ~ .text(__LINE__);
						if (!_prop.var.etc.bindCardViews) {
							_skillWin = new SkillCardWindow(_comm, _prop, parent);
							return _skillWin.shell;
						}
						return null;
					}
					case "itemCard": {
						dStr ~= " - " ~ .text(__LINE__);
						if (!_prop.var.etc.bindCardViews) {
							_itemWin = new ItemCardWindow(_comm, _prop, parent);
							return _itemWin.shell;
						}
						return null;
					}
					case "beastCard": {
						dStr ~= " - " ~ .text(__LINE__);
						if (!_prop.var.etc.bindCardViews) {
							_beastWin = new BeastCardWindow(_comm, _prop, parent);
							return _beastWin.shell;
						}
						return null;
					}
					case "infoCard": {
						dStr ~= " - " ~ .text(__LINE__);
						if (!_prop.var.etc.bindCardViews) {
							_infoWin = new InfoCardWindow(_comm, _prop, parent);
							return _infoWin.shell;
						}
						return null;
					}
					case "file": {
						dStr ~= " - " ~ .text(__LINE__);
						_dirWin = new DirectoryWindow(_comm, _prop, parent);
						return _dirWin.shell;
					}
					default:
						dStr ~= " - " ~ .text(__LINE__);
						debugln("Unknown pane key: " ~ key);
						return null;
					}
				});
				dStr ~= " - " ~ .text(__LINE__);
				void initDock() {
					dStr ~= " - " ~ .text(__LINE__);
					if (!_dock.findPane("work").length) {
						_dock.addPane(_dock.first, Dir.N, 3, 1, "work");
					}
					dStr ~= " - " ~ .text(__LINE__);
					_dock.canMove = &dockCanMove;
					_dock.newPaneName = &dockNewPaneName;
					_dock.canVanish = &dockCanVanish;
					_dock.selectEvent ~= &dockSelect;
					_dock.closeCtrlEvent ~= &dockCloseCtrl;
					_dock.addCreatePaneEvent(&createPaneEvent);
					_dock.area.setLayoutData(new GridData(GridData.FILL_BOTH));
					dStr ~= " - " ~ .text(__LINE__);
				}
				if (_dock) {
					dStr ~= " - " ~ .text(__LINE__);
					initDock();
					dStr ~= " - " ~ .text(__LINE__);
					if (_tableWin) {
						dStr ~= " - " ~ .text(__LINE__);
						_dock.tabImage("data", _tableWin.image);
						_dock.tabText("data", _tableWin.title);
					} else {
						dStr ~= " - " ~ .text(__LINE__);
						_tableWin = new TableWindow(_comm, _prop, _win, null);
					}
					dStr ~= " - " ~ .text(__LINE__);
					if (_flagWin) {
						dStr ~= " - " ~ .text(__LINE__);
						_dock.tabImage("flag", _flagWin.image);
						_dock.tabText("flag", _flagWin.title);
					} else {
						dStr ~= " - " ~ .text(__LINE__);
						_flagWin = new FlagWindow(_comm, _prop, _win, null);
					}
					dStr ~= " - " ~ .text(__LINE__);
					if (_prop.var.etc.bindCardViews) {
						dStr ~= " - " ~ .text(__LINE__);
						if (_cardWin) {
							_dock.tabImage("card", _cardWin.image);
							_dock.tabText("card", _cardWin.title);
						} else {
							_cardWin = new MainCardWindow(_comm, _prop, null);
						}
					} else {
						dStr ~= " - " ~ .text(__LINE__);
						if (_castWin) {
							_dock.tabImage("castCard", _castWin.image);
							_dock.tabText("castCard", _castWin.title);
						} else {
							_castWin = new CastCardWindow(_comm, _prop, null);
						}
						if (_skillWin) {
							_dock.tabImage("skillCard", _skillWin.image);
							_dock.tabText("skillCard", _skillWin.title);
						} else {
							_skillWin = new SkillCardWindow(_comm, _prop, null);
						}
						if (_itemWin) {
							_dock.tabImage("itemCard", _itemWin.image);
							_dock.tabText("itemCard", _itemWin.title);
						} else {
							_itemWin = new ItemCardWindow(_comm, _prop, null);
						}
						if (_beastWin) {
							_dock.tabImage("beastCard", _beastWin.image);
							_dock.tabText("beastCard", _beastWin.title);
						} else {
							_beastWin = new BeastCardWindow(_comm, _prop, null);
						}
						if (_infoWin) {
							_dock.tabImage("infoCard", _infoWin.image);
							_dock.tabText("infoCard", _infoWin.title);
						} else {
							_infoWin = new InfoCardWindow(_comm, _prop, null);
						}
					}
					dStr ~= " - " ~ .text(__LINE__);
					if (_dirWin) {
						dStr ~= " - " ~ .text(__LINE__);
						_dock.tabImage("file", _dirWin.image);
						_dock.tabText("file", _dirWin.title);
					} else {
						dStr ~= " - " ~ .text(__LINE__);
						_dirWin = new DirectoryWindow(_comm, _prop, null);
					}
					dStr ~= " - " ~ .text(__LINE__);
				} else {
					dStr ~= " - " ~ .text(__LINE__);
					_dock = new DockingFolderCTC(dockComp, SWT.NONE, "work");
					initDock();
					dStr ~= " - " ~ .text(__LINE__);
					auto data = _dock.addPane(_dock.first, Dir.N, 1, 3, "data");
					_tableWin = new TableWindow(_comm, _prop, _win, data);
					_dock.add(_tableWin.shell, _tableWin.title, _tableWin.image, "data", true);
					_flagWin = new FlagWindow(_comm, _prop, _win, data);
					_dock.add(_flagWin.shell, _flagWin.title, _flagWin.image, "flag", false);
					dStr ~= " - " ~ .text(__LINE__);
					if (_prop.var.etc.bindCardViews) {
						_cardWin = new MainCardWindow(_comm, _prop, data);
						_dock.add(_cardWin.shell, _cardWin.title, _cardWin.image, "card", false);
					} else {
						dStr ~= " - " ~ .text(__LINE__);
						_castWin = new CastCardWindow(_comm, _prop, data);
						_dock.add(_castWin.shell, _castWin.title, _castWin.image, "castCard", false);
						_skillWin = new SkillCardWindow(_comm, _prop, data);
						_dock.add(_skillWin.shell, _skillWin.title, _skillWin.image, "skillCard", false);
						_itemWin = new ItemCardWindow(_comm, _prop, data);
						_dock.add(_itemWin.shell, _itemWin.title, _itemWin.image, "itemCard", false);
						_beastWin = new BeastCardWindow(_comm, _prop, data);
						_dock.add(_beastWin.shell, _beastWin.title, _beastWin.image, "beastCard", false);
						_infoWin = new InfoCardWindow(_comm, _prop, data);
						_dock.add(_infoWin.shell, _infoWin.title, _infoWin.image, "infoCard", false);
						dStr ~= " - " ~ .text(__LINE__);
					}
					_dirWin = new DirectoryWindow(_comm, _prop, data);
					_dock.add(_dirWin.shell, _dirWin.title, _dirWin.image, "file", false);
					dStr ~= " - " ~ .text(__LINE__);
				}
			} else {
				dStr ~= " - " ~ .text(__LINE__);
				_dataWin = new DataWindow(_comm, _prop, _win, _win);
				_cardWin = new MainCardWindow(_comm, _prop, _win);
				_dirWin = new DirectoryWindow(_comm, _prop, _win);
				dStr ~= " - " ~ .text(__LINE__);
			}
			dStr ~= " - " ~ .text(__LINE__);

			_noSummMenu = new HashSet!(MenuID);
			_noSummMenu.add(MenuID.New);
			_noSummMenu.add(MenuID.Open);
			_noSummMenu.add(MenuID.Close);
			_noSummMenu.add(MenuID.ToXMLText);
			if (_prop.var.etc.singleWindow) {
				_noSummMenu.add(MenuID.TableView);
				_noSummMenu.add(MenuID.VarView);
				_noSummMenu.add(MenuID.CardView);
				_noSummMenu.add(MenuID.CastView);
				_noSummMenu.add(MenuID.SkillView);
				_noSummMenu.add(MenuID.ItemView);
				_noSummMenu.add(MenuID.BeastView);
				_noSummMenu.add(MenuID.InfoView);
				_noSummMenu.add(MenuID.FileView);
			}
			_noSummMenu.add(MenuID.ChangeVH);
			_noSummMenu.add(MenuID.ShowCardProp);
			_noSummMenu.add(MenuID.ShowCardImage);
			_noSummMenu.add(MenuID.ShowCardDetail);
			_noSummMenu.add(MenuID.ExecEngine);
			_noSummMenu.add(MenuID.Settings);
			_noSummMenu.add(MenuID.VersionInfo);

			dStr ~= " - " ~ .text(__LINE__);
			{
				_mainMenu = new HashSet!(MenuID);
				auto bar = new Menu(_win, SWT.BAR);
				dStr ~= " - " ~ .text(__LINE__);

				_menuFile = createMenu(_comm, bar, MenuID.File);
				setupMenuListener(_menuFile);
				dStr ~= " - " ~ .text(__LINE__);
				createFileMenu();
				dStr ~= " - " ~ .text(__LINE__);

				auto me = createMenu(_comm, bar, MenuID.Edit);
				setupMenuListener(me);
				if (_prop.var.etc.singleWindow) {
					mixin (MenuAction!("me", MenuID.OpenDir, SWT.PUSH, "openDirectory", "&canOpenDirectory"));
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.Undo));
					mixin (MenuAction!("me", MenuID.Redo));
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.Cut));
					mixin (MenuAction!("me", MenuID.Copy));
					mixin (MenuAction!("me", MenuID.Paste));
					mixin (MenuAction!("me", MenuID.Delete));
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.Comment));
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.ToScript));
					mixin (MenuAction!("me", MenuID.ToScriptAll));
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.Up));
					mixin (MenuAction!("me", MenuID.Down));
					new MenuItem(me, SWT.SEPARATOR);
				}
				mixin (MenuAction!("me", MenuID.Find, SWT.PUSH, "replaceText", "() => summary !is null"));
				mixin (MenuAction!("me", MenuID.ReNumberingAll, SWT.PUSH, "reNumberingAll", "() => summary !is null"));
				mixin (MenuAction!("me", MenuID.ToXMLText, SWT.PUSH, "clipboardToXML", "null"));
				dStr ~= " - " ~ .text(__LINE__);
				if (_prop.var.etc.singleWindow) {
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.NewDir, SWT.PUSH, "_dirWin.createNewFolder", "&_dirWin.canCreateNewFolder"));
					new MenuItem(me, SWT.SEPARATOR);
					mixin (MenuAction!("me", MenuID.DelNotUsedFile, SWT.PUSH, "_dirWin.deleteUnuse", "&_dirWin.canDeleteUnuse"));
				}

				auto mv = createMenu(_comm, bar, MenuID.View);
				setupMenuListener(mv);
				mixin (MenuAction!("mv", MenuID.TableView, SWT.PUSH, "openDataWindow", "null"));
				if (_prop.var.etc.singleWindow) {
					mixin (MenuAction!("mv", MenuID.VarView, SWT.PUSH, "openFlagWindow", "null"));
				}
				if (!_prop.var.etc.singleWindow || _prop.var.etc.bindCardViews) {
					mixin (MenuAction!("mv", MenuID.CardView, SWT.PUSH, "openCardWindow", "null"));
				} else {
					new MenuItem(mv, SWT.SEPARATOR);
					mixin (MenuAction!("mv", MenuID.CastView, SWT.PUSH, "openCast", "null"));
					mixin (MenuAction!("mv", MenuID.SkillView, SWT.PUSH, "openSkill", "null"));
					mixin (MenuAction!("mv", MenuID.ItemView, SWT.PUSH, "openItem", "null"));
					mixin (MenuAction!("mv", MenuID.BeastView, SWT.PUSH, "openBeast", "null"));
					mixin (MenuAction!("mv", MenuID.InfoView, SWT.PUSH, "openInfo", "null"));
					new MenuItem(mv, SWT.SEPARATOR);
				}
				mixin (MenuAction!("mv", MenuID.FileView, SWT.PUSH, "openDirWindow", "null"));
				if (_prop.var.etc.singleWindow) {
					dStr ~= " - " ~ .text(__LINE__);
					new MenuItem(mv, SWT.SEPARATOR);
					mixin (MenuAction!("mv", MenuID.Refresh, SWT.PUSH, "refreshAll", "() => summary !is null"));
					new MenuItem(mv, SWT.SEPARATOR);
					mixin (MenuAction!("mv", MenuID.ChangeVH));
				}
				dStr ~= " - " ~ .text(__LINE__);

				if (_prop.var.etc.singleWindow) {
					auto ma = createMenu(_comm, bar, MenuID.Table);
					setupMenuListener(ma);
					mixin (MenuAction!("ma", MenuID.EditSummary, SWT.PUSH, "_tableWin.editSummary", "&_tableWin.canEditSummary"));
					new MenuItem(ma, SWT.SEPARATOR);
					if (!_prop.var.etc.bindSceneWithEvent) {
						mixin (MenuAction!("ma", MenuID.EditScene));
						mixin (MenuAction!("ma", MenuID.EditEvent));
						new MenuItem(ma, SWT.SEPARATOR);
					}
					mixin (MenuAction!("ma", MenuID.NewArea, SWT.PUSH, "_tableWin.createArea", "&_tableWin.canCreateArea"));
					mixin (MenuAction!("ma", MenuID.NewBattle, SWT.PUSH, "_tableWin.createBattle", "&_tableWin.canCreateBattle"));
					mixin (MenuAction!("ma", MenuID.NewPackage, SWT.PUSH, "_tableWin.createPackage", "&_tableWin.canCreatePackage"));

					auto mf = createMenu(_comm, bar, MenuID.Variable);
					setupMenuListener(mf);
					mixin (MenuAction!("mf", MenuID.NewFlagDir, SWT.PUSH, "_flagWin.createFlagDir", "&_flagWin.canCreateFlagDir"));
					mixin (MenuAction!("mf", MenuID.NewFlag, SWT.PUSH, "_flagWin.createFlag", "&_flagWin.canCreateFlag"));
					mixin (MenuAction!("mf", MenuID.NewStep, SWT.PUSH, "_flagWin.createStep", "&_flagWin.canCreateStep"));

					auto mc = createMenu(_comm, bar, MenuID.Card);
					setupMenuListener(mc);
					auto g = new RadioGroup!(MenuItem);
					mixin (MenuAction!("mc", MenuID.ShowCardProp, SWT.RADIO, "showCardLife", "null"));
					auto scf = _menu[MenuID.ShowCardProp];
					g.append(scf);
					mixin (MenuAction!("mc", MenuID.ShowCardImage, SWT.RADIO, "showCardList", "null"));
					auto scl = _menu[MenuID.ShowCardImage];
					g.append(scl);
					mixin (MenuAction!("mc", MenuID.ShowCardDetail, SWT.RADIO, "showCardTable", "null"));
					auto sct = _menu[MenuID.ShowCardDetail];
					g.append(sct);
					if (_prop.var.etc.cardLife) {
						scf.setSelection(true);
	 				} else if (_prop.var.etc.cardDetails) {
						sct.setSelection(true);
					} else {
						scl.setSelection(true);
					}
					_menuRG ~= g;
					new MenuItem(mc, SWT.SEPARATOR);
					mixin (MenuAction!("mc", MenuID.NewCast, SWT.PUSH, "newCast", "&canNewCast"));
					mixin (MenuAction!("mc", MenuID.NewSkill, SWT.PUSH, "newSkill", "&canNewSkill"));
					mixin (MenuAction!("mc", MenuID.NewItem, SWT.PUSH, "newItem", "&canNewItem"));
					mixin (MenuAction!("mc", MenuID.NewBeast, SWT.PUSH, "newBeast", "&canNewBeast"));
					mixin (MenuAction!("mc", MenuID.NewInfo, SWT.PUSH, "newInfo", "&canNewInfo"));
					new MenuItem(mc, SWT.SEPARATOR);
					mixin (MenuAction!("mc", MenuID.OpenImportSource, SWT.PUSH, "addScenario", "&canAddScenario"));
				}
				dStr ~= " - " ~ .text(__LINE__);

				auto mt = createMenu(_comm, bar, MenuID.Tool);
				setupMenuListener(mt);
				void delegate(SelectionEvent) dummy = null;
				auto eemi = createMenuItem(_comm, mt, MenuID.ExecEngine, dummy, () => canExecEngine || _prop.var.etc.classicEngines.length, SWT.CASCADE);
				_mExecEngine = new Menu(eemi);
				eemi.setMenu(_mExecEngine);
				new MenuItem(mt, SWT.SEPARATOR);
				mixin (MenuAction!("mt", MenuID.Settings, SWT.PUSH, "settings", "null"));

				auto mh = createMenu(_comm, bar, MenuID.Help);
				setupMenuListener(mh);
				mixin (MenuAction!("mh", MenuID.VersionInfo, SWT.PUSH, "versionInfo", "null"));

				_win.setMenuBar(bar);
				dStr ~= " - " ~ .text(__LINE__);
			}
			dStr ~= " - " ~ .text(__LINE__);

			Menu tmOpenCardWin;
			void createCardWinTI(ToolBar bar) {
				_mainMenu.add(MenuID.CardView);
				auto ti = createDropDownItem(_comm, bar, MenuID.CardView, &openCardWindow, tmOpenCardWin, null);
				_tool[MenuID.CardView] = ti;
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.casts, _prop.images.casts, &openCast, null);
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.skill, _prop.images.skill, &openSkill, null);
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.item, _prop.images.item, &openItem, null);
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.beast, _prop.images.beast, &openBeast, null);
				createMenuItem2(_comm, tmOpenCardWin, _prop.msgs.info, _prop.images.info, &openInfo, null);
			}
			void createExecEngineTI(ToolBar bar) {
				_mainMenu.add(MenuID.ExecEngine);
				auto ti = createDropDownItem(_comm, bar, MenuID.ExecEngine, &execEngine, _tmExecEngine, () => canExecEngine || _prop.var.etc.classicEngines.length);
				_tool[MenuID.ExecEngine] = ti;
			}

			if (_prop.var.etc.singleWindow) {
				dStr ~= " - " ~ .text(__LINE__);
				_cbar = createCoolBar!("tools")(_comm, toolComp, (CoolBar cbar) {
					void createCoolItem(CoolBar cbar, ToolBar tbar) {
						.createCoolItem(cbar, tbar);
						_toolBar ~= tbar;
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.New, SWT.PUSH, "createScenario", "null"));
						mixin (ToolAction!("bar", MenuID.Open, SWT.PUSH, "openScenarioM", "null"));
						mixin (ToolAction!("bar", MenuID.Save, SWT.PUSH, "saveScenario", "() => summary !is null"));
						mixin (ToolAction!("bar", MenuID.SaveAs, SWT.PUSH, "saveScenarioA", "() => summary !is null"));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.CreateArchive, SWT.PUSH, "_dirWin.createArchive", "&_dirWin.canCreateArchive"));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.Reload, SWT.PUSH, "reload", "() => summary !is null"));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.Refresh, SWT.PUSH, "refreshAll", "() => summary !is null"));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.Undo));
						mixin (ToolAction!("bar", MenuID.Redo));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.Cut));
						mixin (ToolAction!("bar", MenuID.Copy));
						mixin (ToolAction!("bar", MenuID.Paste));
						mixin (ToolAction!("bar", MenuID.Delete));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.Up));
						mixin (ToolAction!("bar", MenuID.Down));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.Find, SWT.PUSH, "replaceText", "() => summary !is null"));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.ReNumberingAll, SWT.PUSH, "reNumberingAll", "() => summary !is null"));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.ToXMLText, SWT.PUSH, "clipboardToXML", "null"));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.TableView, SWT.PUSH, "openDataWindow", "null"));
						mixin (ToolAction!("bar", MenuID.VarView, SWT.PUSH, "openFlagWindow", "null"));
						if (_prop.var.etc.bindCardViews) {
							createCardWinTI(bar);
						} else {
							new ToolItem(bar, SWT.SEPARATOR);
							mixin (ToolAction!("bar", MenuID.CastView, SWT.PUSH, "openCast", "null"));
							mixin (ToolAction!("bar", MenuID.SkillView, SWT.PUSH, "openSkill", "null"));
							mixin (ToolAction!("bar", MenuID.ItemView, SWT.PUSH, "openItem", "null"));
							mixin (ToolAction!("bar", MenuID.BeastView, SWT.PUSH, "openBeast", "null"));
							mixin (ToolAction!("bar", MenuID.InfoView, SWT.PUSH, "openInfo", "null"));
							new ToolItem(bar, SWT.SEPARATOR);
						}
						mixin (ToolAction!("bar", MenuID.FileView, SWT.PUSH, "openDirWindow", "null"));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.ChangeVH));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.EditSummary, SWT.PUSH, "_tableWin.editSummary", "() => summary !is null"));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.NewArea, SWT.PUSH, "_tableWin.createArea", "&_tableWin.canCreateArea"));
						mixin (ToolAction!("bar", MenuID.NewBattle, SWT.PUSH, "_tableWin.createBattle", "&_tableWin.canCreateBattle"));
						mixin (ToolAction!("bar", MenuID.NewPackage, SWT.PUSH, "_tableWin.createPackage", "&_tableWin.canCreatePackage"));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.NewFlagDir, SWT.PUSH, "_flagWin.createFlagDir", "&_flagWin.canCreateFlagDir"));
						mixin (ToolAction!("bar", MenuID.NewFlag, SWT.PUSH, "_flagWin.createFlag", "&_flagWin.canCreateFlag"));
						mixin (ToolAction!("bar", MenuID.NewStep, SWT.PUSH, "_flagWin.createStep", "&_flagWin.canCreateStep"));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						auto g = new RadioGroup!(ToolItem);
						mixin (ToolAction!("bar", MenuID.ShowCardProp, SWT.RADIO, "showCardLife", "null"));
						auto scf = _tool[MenuID.ShowCardProp];
						g.append(scf);
						mixin (ToolAction!("bar", MenuID.ShowCardImage, SWT.RADIO, "showCardList", "null"));
						auto scl = _tool[MenuID.ShowCardImage];
						g.append(scl);
						mixin (ToolAction!("bar", MenuID.ShowCardDetail, SWT.RADIO, "showCardTable", "null"));
						auto sct = _tool[MenuID.ShowCardDetail];
						g.append(sct);
						if (_prop.var.etc.cardLife) {
							scf.setSelection(true);
						} else if (_prop.var.etc.cardDetails) {
							sct.setSelection(true);
						} else {
							scl.setSelection(true);
						}
						_toolRG ~= g;
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.NewCast, SWT.PUSH, "newCast", "&canNewCast"));
						mixin (ToolAction!("bar", MenuID.NewSkill, SWT.PUSH, "newSkill", "&canNewSkill"));
						mixin (ToolAction!("bar", MenuID.NewItem, SWT.PUSH, "newItem", "&canNewItem"));
						mixin (ToolAction!("bar", MenuID.NewBeast, SWT.PUSH, "newBeast", "&canNewBeast"));
						mixin (ToolAction!("bar", MenuID.NewInfo, SWT.PUSH, "newInfo", "&canNewInfo"));
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.OpenImportSource, SWT.PUSH, "addScenario", "&canAddScenario"));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						mixin (ToolAction!("bar", MenuID.OpenDir, SWT.PUSH, "openDirectory", "&canOpenDirectory"));
						mixin (ToolAction!("bar", MenuID.NewDir, SWT.PUSH, "_dirWin.createNewFolder", "&_dirWin.canCreateNewFolder"));
						createCoolItem(cbar, bar);
					}
					{
						auto bar = new ToolBar(cbar, SWT.FLAT);
						createExecEngineTI(bar);
						new ToolItem(bar, SWT.SEPARATOR);
						mixin (ToolAction!("bar", MenuID.Settings, SWT.PUSH, "settings", "null"));
						createCoolItem(cbar, bar);
					}
				});

				auto drop = new DropTarget(_cbar, DND.DROP_DEFAULT | DND.DROP_LINK);
				drop.setTransfer([FileTransfer.getInstance()]);
				drop.addDropListener(new DTListener);

				_comm.baseShell(this, _tableWin, _flagWin, _castWin, _skillWin, _itemWin, _beastWin, _infoWin, _dirWin);
				dStr ~= " - " ~ .text(__LINE__);
			} else {
				dStr ~= " - " ~ .text(__LINE__);
				auto bar = new ToolBar(toolComp, SWT.FLAT);
				mixin (ToolAction!("bar", MenuID.New, SWT.PUSH, "createScenario", "null"));
				mixin (ToolAction!("bar", MenuID.Open, SWT.PUSH, "openScenarioM", "null"));
				mixin (ToolAction!("bar", MenuID.Save, SWT.PUSH, "saveScenario", "() => summary !is null"));
				mixin (ToolAction!("bar", MenuID.SaveAs, SWT.PUSH, "saveScenarioA", "() => summary !is null"));
				new ToolItem(bar, SWT.SEPARATOR);
				mixin (ToolAction!("bar", MenuID.Find, SWT.PUSH, "replaceText", "() => summary !is null"));
				mixin (ToolAction!("bar", MenuID.ReNumberingAll, SWT.PUSH, "reNumberingAll", "() => summary !is null"));
				mixin (ToolAction!("bar", MenuID.ToXMLText, SWT.PUSH, "clipboardToXML", "null"));
				new ToolItem(bar, SWT.SEPARATOR);
				mixin (ToolAction!("bar", MenuID.Reload, SWT.PUSH, "reload", "() => summary !is null"));
				new ToolItem(bar, SWT.SEPARATOR);
				mixin (ToolAction!("bar", MenuID.TableView, SWT.PUSH, "openDataWindow", "() => summary !is null"));
				createCardWinTI(bar);
				mixin (ToolAction!("bar", MenuID.FileView, SWT.PUSH, "openDirWindow", "() => summary !is null"));
				new ToolItem(bar, SWT.SEPARATOR);
				createExecEngineTI(bar);
				new ToolItem(bar, SWT.SEPARATOR);
				mixin (ToolAction!("bar", MenuID.Settings, SWT.PUSH, "settings", "null"));
				new ToolItem(bar, SWT.SEPARATOR);
				mixin (ToolAction!("bar", MenuID.Close, SWT.PUSH, "exitAll", "null"));
				_toolBar ~= bar;

				auto drop = new DropTarget(bar, DND.DROP_DEFAULT | DND.DROP_LINK);
				drop.setTransfer([FileTransfer.getInstance()]);
				drop.addDropListener(new DTListener);

				_comm.baseShell(this, _dataWin, _cardWin, _dirWin);
				setupMenu(_menu);
				setupMenu(_tool);
				dStr ~= " - " ~ .text(__LINE__);
			}
			d.addFilter(SWT.Selection, new class Listener {
				override void handleEvent(Event e) {
					if (cast(CTabFolder) e.widget || cast(TabFolder) e.widget) {
						_comm.refreshToolBar();
					}
				}
			});
			d.addFilter(SWT.FocusIn, new class Listener {
				override void handleEvent(Event e) {
					_comm.refreshToolBar();
				}
			});
			d.addFilter(SWT.KeyDown, new KeyDownFilter);
			d.addFilter(SWT.MouseWheel, new SwitchTab);
			refreshExecEngine();

			dStr ~= " - " ~ .text(__LINE__);
			int tx = _prop.var.mainWin.x == SWT.DEFAULT ? _win.getBounds().x : _prop.var.mainWin.x;
			int ty = _prop.var.mainWin.y == SWT.DEFAULT ? _win.getBounds().y : _prop.var.mainWin.y;
			if (_prop.var.etc.singleWindow) {
				_win.setMaximized(_prop.var.mainWin.maximized);
				intoDisplay(tx, ty, _prop.var.mainWin.width, _prop.var.mainWin.height);
				_win.setBounds(tx, ty, _prop.var.mainWin.width, _prop.var.mainWin.height);
				_win.layout(true);
			} else {
				_win.pack();
				intoDisplay(tx, ty, _win.getSize().x, _win.getSize().y);
				_win.setBounds(tx, ty, _win.getSize().x, _win.getSize().y);
			}
			dStr ~= " - " ~ .text(__LINE__);
			if (_dock) {
				if (_dock.pane("data")) {
					dockSelect("data");
				} else if (_dock.pane("card")) {
					dockSelect("card");
				} else if (_dock.pane("flag")) {
					dockSelect("flag");
				} else if (_dock.pane("castCard")) {
					dockSelect("castCard");
				} else if (_dock.pane("skillCard")) {
					dockSelect("skillCard");
				} else if (_dock.pane("itemCard")) {
					dockSelect("itemCard");
				} else if (_dock.pane("beastCard")) {
					dockSelect("beastCard");
				} else if (_dock.pane("infoCard")) {
					dockSelect("infoCard");
				} else if (_dock.pane("file")) {
					dockSelect("file");
				}
				dStr ~= " - " ~ .text(__LINE__);
				setupMenu(_menu);
				setupMenu(_tool);
			}
		} catch (Throwable e) {
			// 起動失敗
			fdebugln(dStr);
			fdebugln(e);
			throw e;
		}
	}
	private class KeyDownFilter : Listener {
		override void handleEvent(Event e) {
			static const F = [
				SWT.F1, SWT.F2, SWT.F3, SWT.F4, SWT.F5,
				SWT.F6, SWT.F7, SWT.F8, SWT.F9, SWT.F10,
				SWT.F11, SWT.F12, SWT.F13, SWT.F14, SWT.F15,
			];
			e.doit = true;
			auto d = Display.getCurrent();
			auto fc = d.getFocusControl();
			if (!fc) return;
			bool ro = !(fc.getStyle() & SWT.READ_ONLY);
			if (ro && (cast(Spinner) fc || cast(Text) fc || cast(Combo) fc || cast(CCombo) fc)) {
				if (!(e.stateMask & SWT.CTRL) && !.contains!("a == b", int, int)(F, e.keyCode)) {
					return;
				}
			}
			if (cast(IgnoreHotkey) fc.getData()) {
				return;
			}
			void raiseEvent(MenuItem menu) {
				scope se = new Event;
				se.type = SWT.Selection;
				se.widget = menu;
				se.time = e.time;
				se.stateMask = e.stateMask;
				se.doit = e.doit;
				menu.notifyListeners(SWT.Selection, se);
				e.doit = false;
			}
			if (fc.getMenu()) {
				auto menu = findMenu(fc.getMenu(), e.keyCode, e.character, e.stateMask);
				if (menu && menu.getEnabled()) {
					raiseEvent(menu);
					return;
				}
			}
			if (!.isDescendant(_win, fc.getShell())) return;
			// フォーカスのあるコントロールのShellのメニューを探し、
			// 該当するメニューが無かった場合は
			// 順に上位のShellを探索する
			auto shl = fc.getShell();
			MenuItem menu = null;
			while (!menu && shl) {
				menu = findMenu(shl, e.keyCode, e.character, e.stateMask);
				if (menu) break;
				if (shl is _win) break;
				int s = shl.getStyle();
				if ((s & SWT.PRIMARY_MODAL) || (s & SWT.APPLICATION_MODAL) || (s & SWT.SYSTEM_MODAL)) {
					break;
				}
				shl = cast(Shell) shl.getParent();
				if (!shl) break;
			}
			if (menu && menu.getEnabled()) {
				raiseEvent(menu);
				return;
			}
		}
	}
	private class SwitchTab : Listener {
		private Control _oldFocus = null;

		private bool switchTab(TabF, Tab)(TabF tabf, Tab tab, Event e) {
			if (!tab || 0 == e.count) return false;
			auto w = cast(Control) e.widget;
			if (!w) return false;
			if (tabf.getItemCount() <= 1) return false;
			auto p = w.toDisplay(e.x, e.y);
			auto ca = tabf.getClientArea();
			if (ca.y <= tabf.toControl(p).y) return false;
			int index = tabf.indexOf(tab);
			assert (-1 != index);
			if (e.count < 0) {
				index++;
				if (tabf.getItemCount() <= index) index = 0;
			} else if (0 < e.count) {
				index--;
				if (index < 0) index = tabf.getItemCount() - 1;
			}
			tabf.setSelection(index);

			scope se = new Event;
			se.type = SWT.Selection;
			se.widget = tabf;
			se.time = e.time;
			se.stateMask = e.stateMask;
			se.doit = e.doit;
			tabf.notifyListeners(SWT.Selection, se);
			e.doit = se.doit;
			return true;
		}

		override void handleEvent(Event e) {
			if (!_prop.var.etc.switchTabWheel) return;
			if (e.type != SWT.MouseWheel) return;
			auto d = Display.getCurrent();
			auto c = d.getCursorControl();
			if (!c) return;
			if (!.isDescendant(_win, c.getShell())) return;

			auto ctabf = cast(CTabFolder) c;
			if (ctabf) {
				if (switchTab(ctabf, ctabf.getSelection(), e)) {
					e.doit = false;
				}
			}
			auto tabf = cast(TabFolder) c;
			if (tabf && 0 < tabf.getSelection().length) {
				if (switchTab(tabf, tabf.getSelection()[0], e)) {
					e.doit = false;
				}
			}
		}
	}

	private void redrawAll() {
		_win.redraw(true);
	}
	private bool canAddScenario() {
		return summary !is null;
	}
	private void addScenario() {
		_comm.addScenario(_prop);
	}
	private template NewCard(string Name) {
		static const NewCard = "auto cw = cast(ICardWindow) _tlp;"
			~ "if (cw && cw.canCreate" ~ Name ~ ") {"
			~ "    cw.create" ~ Name ~ "();"
			~ "} else if (_cardWin) {"
			~ "    _cardWin.create" ~ Name ~ "();"
			~ "} else {"
			~ "    _" ~ std.string.toLower(Name) ~ "Win.create" ~ Name ~ "();"
			~ "}";
	}
	private void openCast() {
		if (!summary && !_comm.singleWindowMode(_prop)) return;
		_comm.openCastWin(true);
	}
	private void openSkill() {
		if (!summary && !_comm.singleWindowMode(_prop)) return;
		_comm.openSkillWin(true);
	}
	private void openItem() {
		if (!summary && !_comm.singleWindowMode(_prop)) return;
		_comm.openItemWin(true);
	}
	private void openBeast() {
		if (!summary && !_comm.singleWindowMode(_prop)) return;
		_comm.openBeastWin(true);
	}
	private void openInfo() {
		if (!summary && !_comm.singleWindowMode(_prop)) return;
		_comm.openInfoWin(true);
	}
	private void refreshAll(SelectionEvent se) {
		if (!_dock) return;
		foreach (ctrl; _dock.showingControls) {
			auto tlpData = cast(TLPData) ctrl.getData();
			if (!tlpData) continue;
			auto act = tlpData.tlp.menuAction(MenuID.Refresh);
			if (act) act(se);
		}
	}
	private class TabfPaint : PaintListener {
		override void paintControl(PaintEvent e) {
			if (!_comm.wallpaper) return;
			auto tabf = cast(CTabFolder) e.widget;
			if (!tabf || tabf.getItemCount() > 0) return;
			auto rect = tabf.getClientArea();
			drawWallpaper(e.gc, _comm.wallpaper, rect, _prop.var.etc.wallpaperStyle);
		}
	}
	private class TabMenu {
		private string _paneKey;
		this (string paneKey) {
			_paneKey = paneKey;
			auto comp = _dock.pane(paneKey);
			comp.addPaintListener(new TabfPaint);
			auto menu = new Menu(comp.getShell(), SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.ClosePane, &close, &canClose);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.ClosePaneExcept, &closeEtc, &canCloseEtc);
			createMenuItem(_comm, menu, MenuID.ClosePaneLeft, &closeLeft, &canCloseLeft);
			createMenuItem(_comm, menu, MenuID.ClosePaneRight, &closeRight, &canCloseRight);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.ClosePaneAll, &closeAll, &canClose);
			_dock.setMenu(paneKey, menu);
		}
		@property
		bool canClose() {
			return _dock.selectedCtrl(_paneKey).length > 0;
		}
		@property
		bool canCloseEtc() {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			return ctrl.length && _dock.hasEtc(ctrl);
		}
		@property
		bool canCloseLeft() {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			return ctrl.length && _dock.hasLeft(ctrl);
		}
		@property
		bool canCloseRight() {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			return ctrl.length && _dock.hasRight(ctrl);
		}
		void close(SelectionEvent se) {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.close(ctrl);
		}
		void closeEtc(SelectionEvent se) {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.closeEtc(ctrl);
		}
		void closeLeft(SelectionEvent se) {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.closeLeft(ctrl);
		}
		void closeRight(SelectionEvent se) {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.closeRight(ctrl);
		}
		void closeAll(SelectionEvent se) {
			auto ctrl = _dock.selectedCtrl(_paneKey);
			if (ctrl.length) _dock.closeAll(ctrl);
		}
	}
	private void createPaneEvent(string paneKey) {
		new TabMenu(paneKey);
	}
	private bool canOpenDirectory() {return summary !is null;}
	private void openDirectory() {
		if (!summary) return;
		auto dirWin = cast(DirectoryWindow) _tlp;
		if (dirWin) {
			dirWin.openDirectory();
		} else {
			openFolder(summary.scenarioPath);
		}
	}
	private bool isMainCardWin(ICardWindow cw) {
		return cast(MainCardWindow) cw || cast(CastCardWindow) cw || cast(SkillCardWindow) cw || cast(ItemCardWindow) cw || cast(BeastCardWindow) cw || cast(InfoCardWindow) cw;
	}
	private void showCardLife(SelectionEvent se) {
		auto cw = cast(ICardWindow) _tlp;
		if (cw && !isMainCardWin(cw)) {
			menuAction!(MenuID.ShowCardProp)(se);
		} else {
			if (_cardWin) _cardWin.showCardLife();
			if (_castWin) _castWin.showCardLife();
			if (_skillWin) _skillWin.showCardLife();
			if (_itemWin) _itemWin.showCardLife();
			if (_beastWin) _beastWin.showCardLife();
			if (_infoWin) _infoWin.showCardLife();
			menuActionAfter!(MenuID.ShowCardProp)();
		}
	}
	private void showCardList(SelectionEvent se) {
		auto cw = cast(ICardWindow) _tlp;
		if (cw && !isMainCardWin(cw)) {
			menuAction!(MenuID.ShowCardImage)(se);
		} else {
			if (_cardWin) _cardWin.showCardList();
			if (_castWin) _castWin.showCardList();
			if (_skillWin) _skillWin.showCardList();
			if (_itemWin) _itemWin.showCardList();
			if (_beastWin) _beastWin.showCardList();
			if (_infoWin) _infoWin.showCardList();
			menuActionAfter!(MenuID.ShowCardImage)();
		}
	}
	private void showCardTable(SelectionEvent se) {
		auto cw = cast(ICardWindow) _tlp;
		if (cw && !isMainCardWin(cw)) {
			menuAction!(MenuID.ShowCardDetail)(se);
		} else {
			if (_cardWin) _cardWin.showCardTable();
			if (_castWin) _castWin.showCardTable();
			if (_skillWin) _skillWin.showCardTable();
			if (_itemWin) _itemWin.showCardTable();
			if (_beastWin) _beastWin.showCardTable();
			if (_infoWin) _infoWin.showCardTable();
			menuActionAfter!(MenuID.ShowCardDetail)();
		}
	}
	private bool canNewCard() {return summary !is null;}
	private alias canNewCard canNewCast;
	private alias canNewCard canNewSkill;
	private alias canNewCard canNewItem;
	private alias canNewCard canNewInfo;
	private alias canNewCard canNewBeast;
	private void newCast() {mixin (NewCard!("Cast"));}
	private void newSkill() {mixin (NewCard!("Skill"));}
	private void newItem() {mixin (NewCard!("Item"));}
	private void newBeast() {mixin (NewCard!("Beast"));}
	private void newInfo() {mixin (NewCard!("Info"));}
	private void versionInfo() {
		(new VersionDialog(_comm, _prop, _win)).open();
	}

	private HashSet!(MenuID) _noSummMenu;
	private MenuItem[MenuID] _menu;
	private ToolItem[MenuID] _tool;
	private RadioGroup!(MenuItem)[] _menuRG;
	private RadioGroup!(ToolItem)[] _toolRG;
	private HashSet!(MenuID) _mainMenu;
	private ToolBar[] _toolBar;
	private TopLevelPanel _tlp = null;
	private template MenuAction(string M, MenuID Id, int Style = SWT.PUSH, string Act = "", string Can = "null") {
		static if (Act.length) {
			static const MenuAction = "_mainMenu.add(" ~ Id.stringof ~ ");"
				~ "_menu[" ~ Id.stringof ~ "] = createMenuItem(_comm, " ~ M ~ ", " ~ Id.stringof ~ ", &"
				~ Act ~ ", " ~ Can ~ ", " ~ ToString!(Style) ~ ");";
		} else {
			static const MenuAction = "_menu[" ~ Id.stringof ~ "] = createMenuItem(_comm, " ~ M ~ ", " ~ Id.stringof ~ ", "
				~ "&menuAction!(" ~ Id.stringof ~ "), " ~ Can ~ ", " ~ ToString!(Style) ~ ");";
		}
	}
	private template ToolAction(string T, MenuID Id, int Style = SWT.PUSH, string Act = "", string Can = "null") {
		static if (Act.length) {
			static const ToolAction = "_mainMenu.add(" ~ Id.stringof ~ ");"
				~ "_tool[" ~ Id.stringof ~ "] = createToolItem(_comm, " ~ T ~ ", " ~ Id.stringof ~ ", &"
				~ Act ~ ", " ~ Can ~ ", " ~ ToString!(Style) ~ ");";
		} else {
			static const ToolAction = "_tool[" ~ Id.stringof ~ "] = createToolItem(_comm, " ~ T ~ ", " ~ Id.stringof ~ ", "
				~ "&menuAction!(" ~ Id.stringof ~ "), " ~ Can ~ ", " ~ ToString!(Style) ~ ");";
		}
	}
	void refreshToolBar() {
		foreach (bar; _toolBar) {
			foreach (itm; bar.getItems()) {
				if (itm.getStyle() & SWT.SEPARATOR) continue;
				auto d = cast(MenuData) itm.getData();
				if (!d) continue;
				try {
					if (d.enabled !is null) {
						itm.setEnabled(d.enabled());
					} else {
						auto enabled = _tlp.menuEnabled(d.id);
						if (enabled) itm.setEnabled(enabled());
					}
				} catch (Throwable e) {
					debugln(.text(d.id));
					debugln(e);
				}
			}
		}
	}
	private class MenuShown : MenuAdapter {
		override void menuShown(MenuEvent e) {
			auto menu = cast(Menu) e.widget;
			foreach (itm; menu.getItems()) {
				if (itm.getStyle() & SWT.SEPARATOR) continue;
				auto d = cast(MenuData) itm.getData();
				assert (d !is null);
				if (d.enabled) continue; // createMenuItem()内の処理に任せる
				auto enabled = _tlp.menuEnabled(d.id);
				if (!enabled) continue;
				itm.setEnabled(enabled());
			}
		}
	}
	private void setupMenuListener(Menu menu) {
		menu.addMenuListener(new MenuShown);
	}
	private void menuActionAfterImpl(MenuID ID, T)(T[MenuID] tools, RadioGroup!(T)[] rg) {
		if (!_tlp) return;
		if (_tlp.menuChecked(ID)) {
			auto p = ID in tools;
			if (p) {
				auto b = *p;
				foreach (g; rg) {
					if (g.contains(b)) {
						foreach (gb; g.set()) {
							gb.setSelection(gb is b);
						}
						return;
					}
				}
				b.setSelection(_tlp.menuChecked(ID)());
			}
		}
	}
	private void menuAction(MenuID ID)(SelectionEvent se) {
		if (!_tlp) return;
		auto act = _tlp.menuAction(ID);
		assert (act, .text(ID) ~ " " ~ .text(_tlp));
		act(se);
		menuActionAfter!(ID)();
	}
	private void menuActionAfter(MenuID ID)() {
		menuActionAfterImpl!(ID)(_menu, _menuRG);
		menuActionAfterImpl!(ID)(_tool, _toolRG);
	}

	private void setupMenu(M)(M[MenuID] menus) {
		foreach (id, itm; menus) {
			if (id is MenuID.ExecEngine) {
				itm.setEnabled(_prop.var.etc.enginePath.length || _prop.var.etc.classicEngines.length);
				continue;
			}
			if (_tlp) {
				auto s = itm.getStyle();
				if ((s & SWT.RADIO) || (s & SWT.CHECK)) {
					auto chk = _tlp.menuChecked(id);
					if (chk) itm.setSelection(chk());
				}
			}
			if (!summary && !_noSummMenu.contains(id)) {
				itm.setEnabled(false);
				continue;
			}
			if (_mainMenu.contains(id)) {
				itm.setEnabled(true);
				continue;
			}
			itm.setEnabled(_tlp && _tlp.menuAction(id));
		}
	}
	private void dockSelect(string key) {
		if (!_dock) return;
		if (!_dock.control(key)) return;
		auto tlp = (cast(TLPData) _dock.control(key).getData()).tlp;
		assert (tlp, key);
		_tlp = tlp;
		statusLine = tlp.statusLine;
		setupMenu(_menu);
		setupMenu(_tool);
	}
	private bool dockCanMove(string ctrlKey, string dropPaneKey) {
		if (!dropPaneKey.length) return true;
		bool iswa = std.string.startsWith(dropPaneKey, "work");
		if (std.string.startsWith(ctrlKey, "work")) {
			return iswa;
		} else {
			return !iswa;
		}
	}
	private bool dockCanVanish(string key) {
		if (std.string.startsWith(key, "work")) {
			return _dock.findPane("work").length > 1;
		}
		if (_dock.panes.length == 2) {
			statusLine = "";
		}
		return true;
	}
	private bool dockCloseCtrl(string key) {
		statusLine = "";
		return true;
	}
	private string dockNewPaneName(string ctrlKey, string basePane, Dir dir) {
		if (std.string.startsWith(ctrlKey, "work")) {
			return _dock.newPaneKey("work");
		} else if (std.string.startsWith(basePane, "work")) {
			if (dir == Dir.E || dir == Dir.W) {
				return _dock.newPaneKey("side");
			} else if (dir == Dir.N || dir == Dir.S) {
				return _dock.newPaneKey("data");
			}
		}
		return "";
	}
	void setStatusLine(string status) {
		_comm.setStatusLine(_win, status);
	}

	@property
	string title() {return _win.getText();}
	@property
	Image image() {return _win.getImage();}
	@property
	Composite shell() {return _win;}
	@property
	void delegate(string) statusText() {return &_sbshl.statusLine;}
	@property
	DockingFolderCTC dock() {return _dock;}

	@property
	Summary summary() {return _dataWin ? _dataWin.summary : _tableWin.summary;}

	void reNumberingHands(A)(A[] arr) {
		ulong newId = 1;
		foreach (a; arr) {
			if (a.id != newId) {
				a.id = newId;
				static if (is (A : Area)) {
					_comm.refArea.call(a);
				} else static if (is (A : Battle)) {
					_comm.refBattle.call(a);
				} else static if (is (A : Package)) {
					_comm.refPackage.call(a);
				} else static if (is (A : CastCard)) {
					_comm.refCast.call(a);
				} else static if (is (A : SkillCard)) {
					_comm.refSkill.call(a);
				} else static if (is (A : ItemCard)) {
					_comm.refItem.call(a);
				} else static if (is (A : BeastCard)) {
					_comm.refBeast.call(a);
				} else static if (is (A : InfoCard)) {
					_comm.refInfo.call(a);
				}
			}
			newId++;
		}
	}
	void reNumberingAll() {
		if (!summary) return;
		auto dlg = new MessageBox(_win, SWT.ICON_QUESTION | SWT.OK | SWT.CANCEL);
		dlg.setText(_prop.msgs.dlgTitQuestion);
		dlg.setMessage(_prop.msgs.reNumberingAll);
		if (SWT.OK == dlg.open()) {
			if (_dataWin) {
				_dataWin.reNumberingAll();
			} else if (_tableWin) {
				_tableWin.reNumberingAll();
			} else assert (0);
			if (_cardWin) {
				_cardWin.reNumberingAll();
			} else {
				_castWin.reNumberingAll();
				_skillWin.reNumberingAll();
				_itemWin.reNumberingAll();
				_beastWin.reNumberingAll();
				_infoWin.reNumberingAll();
			}
			foreach (c; summary.casts) {
				auto w = _comm.handCardWindowFrom(_prop, summary, c, false, false);
				if (w) {
					w.reNumberingAll();
				} else {
					reNumberingHands(c.skills);
					reNumberingHands(c.items);
					reNumberingHands(c.beasts);
				}
			}
		}
	}

	ReplaceDialog openReplWin() {
		if (summary) {
			if (!_replDlg || _replDlg.widget.isDisposed()) {
				_replDlg = new ReplaceDialog(_comm, _prop, _win, summary);
				_replDlg.open();
			} else {
				_replDlg.widget.setMinimized(false);
				_replDlg.widget.setActive();
			}
			return _replDlg;
		}
		return null;
	}

	bool openCWXPath(string path, bool shellActivate) {
		if (!summary) return false;
		_win.setRedraw(false);
		scope (exit) _win.setRedraw(true);
		bool open() {
			path = cwx.utils.toLower(path);
			if (cpempty(path)) {
				if (cphasattr(path, "opendialog")) {
					if (_dataWin) {
						_dataWin.editSummary();
					} else {
						_tableWin.editSummary();
					}
				}
				return true;
			}
			auto cate = cpcategory(path);
			switch (cate) {
			case "area", "battle", "package", "area:id", "battle:id", "package:id", "variable": {
				if (_dataWin) {
					return _dataWin.openCWXPath(path, shellActivate);
				} else if (cate == "variable") {
					return _flagWin.openCWXPath(path, shellActivate);
				} else {
					return _tableWin.openCWXPath(path, shellActivate);
				}
			} case "castcard", "skillcard", "itemcard", "beastcard", "infocard",
					"castcard:id", "skillcard:id", "itemcard:id", "beastcard:id", "infocard:id": {
				if (_cardWin) {
					return _cardWin.openCWXPath(path, shellActivate);
				} else {
					assert (_castWin);
					assert (_skillWin);
					assert (_itemWin);
					assert (_beastWin);
					assert (_infoWin);
					switch (cate) {
					case "castcard", "castcard:id":
						return _castWin.openCWXPath(path, shellActivate);
					case "skillcard", "skillcard:id":
						return _skillWin.openCWXPath(path, shellActivate);
					case "itemcard", "itemcard:id":
						return _itemWin.openCWXPath(path, shellActivate);
					case "beastcard", "beastcard:id":
						return _beastWin.openCWXPath(path, shellActivate);
					case "infocard", "infocard:id":
						return _infoWin.openCWXPath(path, shellActivate);
					default:
						return false;
					}
				}
			} default: return false;
			}
		}
		bool r = true;
		foreach (p; std.string.split(path, CWXPATH_SEP.idup)) {
			if (open()) {
				_win.setMinimized(false);
				if (shellActivate) _win.forceActive();
			} else {
				r = false;
			}
		}
		return r;
	}
	@property
	string[] openedCWXPath() {
		string[] r;
		if (!_dock) return r;
		foreach (paneKey; _dock.paneKeys) {
			foreach (ctrl; _dock.controls(paneKey)) {
				auto tlpData = cast(TLPData) ctrl.getData();
				if (tlpData.tlp is this) continue;
				assert (tlpData);
				r ~= tlpData.tlp.openedCWXPath;
			}
			// ペイン内で選択中のタブを末尾に追加
			string ctrlKey = _dock.selectedCtrl(paneKey);
			if ("" != ctrlKey) {
				auto ctrl = _dock.control(ctrlKey);
				assert (ctrl);
				auto tlpData = cast(TLPData) ctrl.getData();
				assert (tlpData);
				if (tlpData.tlp !is this) {
					r ~= tlpData.tlp.openedCWXPath;
				}
			}
		}
		// 現在フォーカスのあるコントロールを末尾に追加
		auto d = _win.getDisplay();
		auto fc = d.getFocusControl();
		while (fc) {
			auto tlpData = cast(TLPData) fc.getData();
			if (tlpData && tlpData.tlp !is this) {
				r ~= tlpData.tlp.openedCWXPath;
				break;
			}
			fc = fc.getParent();
		}
		return array(uniq(r));
	}

	void doCWX() {
		if (!_win) return;
		string dStr = .text(__LINE__);;
		try {
			auto d = _win.getDisplay();
			_win.open();
			dStr ~= " - " ~ .text(__LINE__);
			if (_firstScenarioPath) {
				dStr ~= " - " ~ .text(__LINE__);
				openScenario(_firstScenarioPath);
			} else if (_prop.var.etc.openLastScenario && _prop.var.etc.lastScenario.length) {
				dStr ~= " - " ~ .text(__LINE__);
				openScenario(_prop.var.etc.lastScenario);
			}
			dStr ~= " - " ~ .text(__LINE__);

			auto pipe = new core.thread.Thread(&pipeThr);
			pipe.start();
			auto backup = new core.thread.Thread(&backupThr);
			backup.start();
			version (Windows) {
				scope (exit) {
					auto p = CreateFileW(toUTFz!(wchar*)(_pipeName),
						GENERIC_READ | GENERIC_WRITE, 0, null, OPEN_EXISTING, 0, null);
					if (p != INVALID_HANDLE_VALUE) {
						scope (exit) CloseHandle(p);
						string pmsg = "quit";
						DWORD len;
						WriteFile(p, pmsg.ptr, pmsg.length, &len, null);
					}
				}
			} else {
				scope (exit) {
					auto fd = open(std.string.toStringz(_pipeName), O_WRONLY, 0);
					if (fd != -1) {
						scope (exit) close(fd);
						string pmsg = "quit";
						cwrite(fd, pmsg.ptr, pmsg.length);
					}
				}
			}
			dStr ~= " - " ~ .text(__LINE__);
			bool openErrDlg = false;
			while (!_win.isDisposed()) {
				version (nocatch) {
					if (!d.readAndDispatch()) {
						d.sleep();
					}
				} else {
					// なるべくユーザデータを消さないよう、例外が発生しても処理を続行する。
					try {
						if (!d.readAndDispatch()) {
							d.sleep();
						}
					} catch (Throwable e) {
						if (!openErrDlg) {
							// 際限の無い連続発生を抑制
							openErrDlg = true;
							_win.setVisible(true);
							fdebugln(e);
							string s = createDebugln(e);
							auto dlg = new ErrorDialog(_comm, _prop, _win, s);
							dlg.closeEvent ~= {
								openErrDlg = false;
							};
							dlg.open();
						} else {
							core.thread.Thread.sleep(.dur!("msecs")(1));
						}
					}
				}
			}
			// FIXME: quitTrace()をbackup.join()より先に行うと時々アクセス違反
			_quit = true;
			dStr ~= " - " ~ .text(__LINE__);
			backup.join();
			dStr ~= " - " ~ .text(__LINE__);
			_dirWin.quitTrace();
			dStr ~= " - " ~ .text(__LINE__);
			_comm.dispose();
			dStr ~= " - " ~ .text(__LINE__);
			_prop.images.disposeImages();
			dStr ~= " - " ~ .text(__LINE__);
			d.dispose();
			dStr ~= " - " ~ .text(__LINE__);
			_prop.var.save(dock);
			dStr ~= " - " ~ .text(__LINE__);
			sendReloadProps();
			version (Console) {
				debug writeln("Exit Main Thread");
			}
		} catch (Throwable e) {
			// 起動・終了失敗
			fdebugln(dStr);
			fdebugln(e);
			throw e;
		}
	}
}
