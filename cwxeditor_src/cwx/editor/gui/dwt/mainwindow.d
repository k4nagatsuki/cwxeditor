
module cwx.editor.gui.dwt.mainwindow;

import std.file;
import std.path;
import std.zip;
import std.utf;
import std.process;
import std.thread;
import std.metastrings;
import std.string;
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

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.flagspane;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.utils;

import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.KeyListener;
import org.eclipse.swt.events.ControlAdapter;
import org.eclipse.swt.events.ControlEvent;
import org.eclipse.swt.events.MouseMoveListener;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.ShellAdapter;
import org.eclipse.swt.events.ShellEvent;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.PaintEvent;
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
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.graphics.Image;
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
	SBShell _sbshl = null;
	Shell _win = null;
	DockingFolderCTC _dock = null;

	Props _prop;
	Commons _comm;

	DataWindow _dataWin = null;
	TableWindow _tableWin = null;
	FlagWindow _flagWin = null;
	MainCardWindow _cardWin;
	DirectoryWindow _dirWin;

	void __refreshTitle() {
		if (summary) {
			string path = summary.scenarioPath;
			_win.setText = _prop.msgs.mainWindowName(summary.scenarioName, path);
		} else {
			_win.setText = _prop.msgs.mainWindowName(null, null);
		}
	}

	void createScenario() {
		if (qSave) {
			auto dlg = new CreateScenarioDialog(_prop, _win);
			if (!dlg.open) return;
			Summary summ;
			if (dlg.legacy) {
				summ = new Summary(dlg.name, dlg.skin, dlg.classicFolder, false, true);
			} else {
				auto p = Summary.createTempDir(_prop.tempPath, dlg.name);
				auto mFPath = std.path.join(p, findSkin2(_prop, dlg.skin).materialPath);
				if (!exists(mFPath) || !isdir(mFPath)) std.file.mkdir(mFPath);
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
				if (qSave) {
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
				auto wsm = std.path.join(old.scenarioPath, "Summary.wsm");
				if (old.useTemp) {
					try {
						openScenario(old.reloadXMLs);
					} catch (Exception e) {
						debugln(e);
						MessageBox.showWarning(_prop.msgs.reloadError
							(summary.scenarioPath) ~ "\n" ~ e.msg,
							_prop.msgs.dlgTitWarning, _win);
					}
				} else {
					if (!.exists(wsm)) wsm = old.scenarioPath;
					loadScenarioFromFile!(Summary)(_prop, _win, &setStatusLine, expand, old, wsm, &openScenario);
				}
			} else if (expand) {
				try {
					openScenario(old.reloadXMLs);
				} catch (Exception e) {
					debugln(e);
					MessageBox.showWarning(_prop.msgs.reloadError
						(summary.scenarioPath) ~ "\n" ~ e.msg,
						_prop.msgs.dlgTitWarning, _win);
				}
			} else {
				assert (old.zipName.length);
				loadScenarioFromFile!(Summary)(_prop, _win, &setStatusLine, expand, old, old.zipName, &openScenario);
			}
		}
	}
	void openScenarioM() {
		if (qSave) {
			openScenario;
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
		_dirWin.stopTrace;
		scope (exit) _dirWin.resumeTrace;
		if (_prop.var.etc.logicalSort) {
			summ.flagDirRoot.sorter = &ncmp;
		} else {
			summ.flagDirRoot.sorter = &cmp;
		}
		summ.flagDirRoot.sortFlags(true);
		summ.flagDirRoot.sortSteps(true);
		auto old = summary;
		if (summ.type.length && !hasSkin(_prop, summ.type) && summ.type != _prop.var.etc.defaultSkin) {
			MessageBox.showWarning(_prop.msgs.useDefaultSkin(summ.type, _prop.var.etc.defaultSkin),
				_prop.msgs.dlgTitWarning, _win);
			summ.type = _prop.var.etc.defaultSkin;
		}
		_comm.skin = findSkin(_prop, summ);
		_comm.closeAll;
		if (_dataWin) {
			_dataWin.load(summ);
		} else {
			_tableWin.load(summ);
			_flagWin.load(summ);
		}
		_cardWin.refresh(summ);
		_dirWin.refresh(summ);
		if (_replDlg && !_replDlg.widget.isDisposed) _replDlg.summary = summ;
		_comm.refScenarioName.call;
		_comm.refScenarioPath.call;
		if (!dock) {
			if (_prop.var.dataWin.visible) _comm.openDataWin;
			if (_prop.var.cardWin.visible) _comm.openCardWin;
			if (_prop.var.dirWin.visible) _comm.openDirWin;
		}
		setupMenu(_menu);
		setupMenu(_tool);
		addHistory;
		try {
			if (old) old.delTemp;
		} catch (Exception e) {
			debugln(e);
		}
		summ.resetChanged;
		statusLine = _prop.msgs.loaded(summ.scenarioName);
	}
	string _firstScenarioPath = null;
	string[] _openPaths;
	void openScenarioImpl(Summary summ) {
		if (summ) {
			openScenario(summ);
			foreach (path; _openPaths) {
				try {
					if (openCWXPath(path)) {
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
		loadScenario!(Summary)(_prop, _win, &setStatusLine,
			_prop.var.etc.expandXMLs, old, _prop.msgs.dlgTitOpenScenario,
			_openPaths, &openScenarioImpl);
	}
	void openScenario(string fname) {
		if (cfnmatch(getExt(fname), "wsm") && !.exists(fname)) {
			fname = getDirName(fname);
		}
		decScenarioPath(fname, _openPaths);
		auto old = summary;
		loadScenarioFromFile!(Summary)(_prop, _win, &setStatusLine, _prop.var.etc.expandXMLs, old, fname, &openScenarioImpl);
	}
	void saveScenario() {
		save(_win);
	}
	void savec(Shell shell) {
		save(shell);
	}
	bool save(Shell shell) {
		if (summary) {
			_dirWin.pauseTrace;
			scope (exit) _dirWin.resumeTrace;
			if (!summary.isSaved) {
				// いまだ保存されていない場合は名前をつけて保存
				return __saveScenarioA(shell);
			} else {
				shell.setCursor = Display.getCurrent.getSystemCursor(SWT.CURSOR_WAIT);
				scope (exit) shell.setCursor = null;
				try {
					summary.saveOverwrite(_prop.parent, _prop.var.etc.saveInnerImagePath);
					_comm.saved.call;
					addHistory;
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
			dlg.setFilterExtensions = ["*.wsn"];
			dlg.setFilterNames = [_prop.msgs.filterScenarioSave];
			dlg.setText = _prop.msgs.dlgTitSaveScenario;
			dlg.setFilterPath = scenarioFilterPath(_prop);
			dlg.setFileName = addExt(summary.scenarioName, "wsn");
			dlg.setOverwrite = true;
			string fname = dlg.open;
			if (fname) {
				shell.setCursor = Display.getCurrent.getSystemCursor(SWT.CURSOR_WAIT);
				scope (exit) shell.setCursor = null;
				_dirWin.pauseTrace;
				scope (exit) _dirWin.resumeTrace;
				string tempPath = _prop.tempPath;
				bool expandXMLs = _prop.var.etc.expandXMLs;
				Skin defSkin = .findSkin2(_prop, _prop.var.etc.defaultSkin);
				try {
					summary.saveWithName(_prop.parent, _prop.var.etc.saveInnerImagePath,
						fname, tempPath, expandXMLs, defSkin, (string msg) {
							MessageBox.showWarning(msg, _prop.msgs.dlgTitWarning, shell);
						});
					_comm.skin = findSkin(_prop, summary);
					_comm.saved.call;
					_comm.refScenarioPath.call;
					_comm.refSkin.call;
					_comm.refPaths.call("");
					addHistory;
				} catch (SummaryException e) {
					debugln(e);
					MessageBox.showWarning(e.msg, _prop.msgs.dlgTitWarning, shell);
				}
			}
		}
		return false;
	}
	void execEngine() {
		string engine = summary ? _comm.skin.engine : _prop.var.etc.enginePath;
		if (engine.length) {
			if (!exec(engine, getDirName(nabs(engine)))) {
				MessageBox.showWarning(_prop.msgs.errorExecEngine(engine),
					_prop.msgs.dlgTitWarning, _win);
			}
		}
	}
	void openDataWindow() {
		if (summary || dock) {
			_prop.var.dataWin.visible = true;
			_comm.openDataWin;
		}
	}
	void openFlagWindow() {
		if (dock) {
			_comm.openFlagWin;
		}
	}
	void openCardWindow() {
		if (summary || dock) {
			_prop.var.cardWin.visible = true;
			_comm.openCardWin;
		}
	}
	void openDirWindow() {
		if (summary || dock) {
			_prop.var.dirWin.visible = true;
			_comm.openDirWin;
		}
	}
	void exitAll() {
		if (qSave) {
			_win.close;
		}
	}
	private ReplaceDialog _replDlg = null;
	void replaceText() {
		openReplWin;
	}
	void clipboardToXML() {
		auto c = _comm.clipboard.getContents(XMLBytesTransfer.getInstance);
		if (c !is null && isXMLBytes(c)) {
			_comm.clipboard.setContents([new ArrayWrapperString(bytesToXML(c))], [TextTransfer.getInstance]);
		}
	}

	bool qSave(bool reload = false) {
		if (summary && (summary.isChanged || _dirWin.isChanged)) {
			MessageBox dlg;
			if (reload) {
				dlg = new MessageBox(_win, SWT.OK | SWT.CANCEL | SWT.ICON_QUESTION);
				dlg.setMessage = _prop.msgs.dlgMsgIsSaveBeforeReload(summary.scenarioName);
			} else {
				dlg = new MessageBox(_win, SWT.YES | SWT.NO | SWT.CANCEL | SWT.ICON_QUESTION);
				dlg.setMessage = _prop.msgs.dlgMsgIsSaveBeforeExit(summary.scenarioName);
			}
			scope (exit) dlg.dispose;
			dlg.setText = _prop.msgs.dlgTitQuestion;
			_win.setMinimized = false;
			switch (dlg.open) {
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
			e.doit = qSave;
		}
	}
	class DListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refScenarioName.remove(&__refreshTitle);
			_comm.refScenarioPath.remove(&__refreshTitle);
			_comm.replText.remove(&__refreshTitle);

			auto b = _win.getBounds;
			_prop.var.mainWin.x = b.x;
			_prop.var.mainWin.y = b.y;
			if (dock) {
				_prop.var.mainWin.maximized = _win.getMaximized;
				if (!_prop.var.mainWin.maximized) {
					_prop.var.mainWin.width = b.width;
					_prop.var.mainWin.height = b.height;
				}
			}
			_win.setVisible = false;
			try {
				_comm.closeAll;
				if (summary && summary.useTemp) {
					_dirWin.stopTrace;
					try {
						summary.delTemp;
					} catch (Exception e) {
						debugln(e);
					}
				}
			} catch (Object e) {
				_win.setVisible = true;
				throw e;
			}
		}
	}
	void settings() {
		string[] oldHist = _prop.var.etc.openHistories;
		scope (exit) {
			if (oldHist != _prop.var.etc.openHistories) {
				createFileMenu;
			}
		}
		auto dlg = new SettingsDialog(_comm, _prop, _win, summary);
		if (dlg.open) {
			_prop.var.save(dock);
		}
	}

	void addHistory() {
		string hist;
		if (summary.legacy) {
			if (summary.useTemp) {
				hist = summary.zipName;
			} else {
				hist = std.path.join(summary.scenarioPath, "Summary.wsm");
			}
		} else if (summary.useTemp) {
			hist = summary.zipName;
			if (!hist.length) return;
		} else {
			hist = std.path.join(summary.scenarioPath, "Summary.xml");
		}
		hist = nabs(hist);
		_prop.var.etc.scenarioPath = summary.useTemp ? getDirName(hist) : getDirName(getDirName(hist));
		foreach (i, h; _prop.var.etc.openHistories) {
			if (cfnmatch(h, hist)) {
				_prop.var.etc.openHistories
					= _prop.var.etc.openHistories[0 .. i] ~ _prop.var.etc.openHistories[i + 1 .. $];
				break;
			}
		}
		_prop.var.etc.openHistories = [hist]
			~ (_prop.var.etc.openHistories.length < _prop.var.etc.historyMax
			? _prop.var.etc.openHistories : _prop.var.etc.openHistories[0 .. $ - 1]);
		_prop.var.save(dock);
		createFileMenu;
	}
	class Hist {
		private string _hist;
		this(Menu menu, int num, string hist) {
			string text;
			Image img;
			if (cfnmatch(getBaseName(hist), "Summary.xml")) {
				text = cuthist(hist[0u .. $ - "Summary.xml".length - std.path.sep.length],
					_prop.var.etc.historySnipLength);
				img = _prop.images.summaryFile;
			} else if (cfnmatch(getExt(hist), "wsn")) {
				text = cuthist(hist, _prop.var.etc.historySnipLength);
				img = _prop.images.scenarioArchive;
			} else if (cfnmatch(getBaseName(hist), "Summary.wsm")) {
				text = cuthist(hist[0u .. $ - "Summary.wsm".length - std.path.sep.length],
					_prop.var.etc.historySnipLength);
				img = _prop.images.classic;
			} else if (cfnmatch(getExt(hist), "cab") || cfnmatch(getExt(hist), "zip")) {
				text = cuthist(hist, _prop.var.etc.historySnipLength);
				img = _prop.images.scenarioArchive;
			} else {
				text = cuthist(hist, _prop.var.etc.historySnipLength);
				img = _prop.images.unknown;
			}
			string nstr;
			if (num < 10) {
				nstr = "&" ~ to!(string)(num);
			} else {
				nstr = to!(string)(num);
			}
			createMenuItem(menu, nstr ~ " " ~ text, img, &run);
			_hist = hist;
		}
		private void run() {
			if (qSave) {
				openScenario(_hist);
			}
		}
		private static string cuthist(string hist, int cut) {
			hist = nabs(hist);
			scope dhist = toUTF32(hist);
			if (dhist.length > cut + "..."d.length) {
				auto drive = getDrive(hist);
				int rlen = drive ? toUTF32(drive).length + 1 : 1;
				int flen = toUTF32(getBaseName(hist)).length + 1;
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
		foreach (itm; _menuFile.getItems) {
			itm.dispose;
		}
		mixin (MenuAction!("_menuFile", "New", SWT.PUSH, "createScenario"));
		mixin (MenuAction!("_menuFile", "Open", SWT.PUSH, "openScenarioM"));
		mixin (MenuAction!("_menuFile", "Save", SWT.PUSH, "saveScenario"));
		mixin (MenuAction!("_menuFile", "SaveA", SWT.PUSH, "saveScenarioA"));
		new MenuItem(_menuFile, SWT.SEPARATOR);
		mixin (MenuAction!("_menuFile", "Reload", SWT.PUSH, "reload"));
		new MenuItem(_menuFile, SWT.SEPARATOR);
		foreach (i, hist; _prop.var.etc.openHistories) {
			new Hist(_menuFile, i + 1, hist);
		}
		if (_prop.var.etc.openHistories.length > 0) new MenuItem(_menuFile, SWT.SEPARATOR);
		createMenuItem(_menuFile, _prop.msgs.menuClose, _prop.images.menuClose, &exitAll);
		setupMenu(_menu);
	}
	Display _display = null;
	static const PIPE_APP_MAX = 256;
	string _pipeName = "";
	class OpenCWXPath : Runnable {
		string path;
		override void run() {
			auto paths = split(path, ";");
			if (!paths.length) paths = [""];
			foreach (p; paths) {
				try {
					openCWXPath(p);
				} catch {}
			}
		}
	}
	int pipeThr() {
		if (!_pipeName.length) return -1;
		version (Windows) {
			auto pipe = CreateNamedPipeW(toUTF16z(_pipeName), PIPE_ACCESS_DUPLEX,
				PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_WAIT,
				1, MAX_PATH, MAX_PATH, 1000, null);
			if (pipe == INVALID_HANDLE_VALUE) return -1;
			scope (exit) CloseHandle(pipe);
			char[MAX_PATH] buf;
			DWORD len;
			auto openPath = new OpenCWXPath;
			while (ConnectNamedPipe(pipe, null)) {
				scope (exit) DisconnectNamedPipe(pipe);
				if (!ReadFile(pipe, buf.ptr, buf.length, &len, null)) continue;
				string rstr = buf[0 .. len];
				if (rstr == "quit") break;
				auto summ = summary;
				if (rstr == "get opened scenario" && summ) {
					string send;
					if (summ.useTemp) {
						send = summ.zipName;
					} else {
						send = summ.scenarioPath;
					}
					if (!WriteFile(pipe, send.ptr, send.length, &len, null)) continue;
					if (!ReadFile(pipe, buf.ptr, buf.length, &len, null)) continue;
					rstr = buf[0 .. len];
				}
				if (cwx.utils.startsWith(rstr, "open cwxpath ")) {
					openPath.path = rstr["open cwxpath ".length .. $];
					_display.asyncExec(openPath);
				}
			}
		} else {
			auto pipe = socket(PF_UNIX, SOCK_STREAM, 0);
			if (pipe == -1) return -1;
			scope (exit) close(pipe);
			sockaddr_un laddr;
			laddr.sun_family = AF_UNIX;
			strcpy(&(laddr.sun_path[1]), _pipeName.ptr);
			if (0 != cbind(pipe, cast(sockaddr*) &laddr, laddr.sizeof)) return -1;
			if (0 != listen(pipe, 1)) return -1;
			char[4096] buf;
			int len;
			auto openPath = new OpenCWXPath;
			typeof(pipe) rsock;
			sockaddr_un raddr;
			socklen_t rsocklen;
			while (-1 != (rsock = accept(pipe, cast(sockaddr*) &raddr, &rsocklen))) {
				scope (exit) close(rsock);
				if (-1 == (len = cread(pipe, buf.ptr, buf.length))) continue;
				string rstr = buf[0 .. len];
				if (rstr == "quit") break;
				auto summ = summary;
				if (rstr == "get opened scenario" && summ) {
					string send;
					if (summ.useTemp) {
						send = summ.zipName;
					} else {
						send = summ.scenarioPath;
					}
					if (-1 == cwrite(pipe, send.ptr, send.length)) continue;
					if (-1 == (len = cread(pipe, buf.ptr, buf.length))) continue;
					rstr = buf[0 .. len];
				}
				if (cwx.utils.startsWith(rstr, "open cwxpath ")) {
					openPath.path = rstr["open cwxpath ".length .. $];
					_display.asyncExec(openPath);
				}
			}
			close(pipe);
		}
		debug writefln("Exit Pipe Thread");
		return 0;
	}
public:
	this (string appPath, string propFilePath, cwx.system.System sys,
			string firstScenarioPath = null, string[] openPaths = []) {
		decScenarioPath(firstScenarioPath, openPaths);
		/// すでにfirstScenarioPathを開いている
		/// 既存のcwxeditorプロセスがある場合、
		/// そちらを開くようにする。
		string path1 = "";
		if (firstScenarioPath && .exists(firstScenarioPath)) {
			path1 = nabs(firstScenarioPath);
			auto ext = getExt(path1);
			if (!.isdir(path1)
					&& (cfnmatch(ext, "xml") || cfnmatch(ext, "wsm") || cfnmatch(ext, "wid"))) {
				path1 = nabs(getDirName(path1));
			}
		}
		version (Windows) {
			char[MAX_PATH] buf;
			DWORD len;
			for (size_t i = 0; i < PIPE_APP_MAX; i++) {
				string pipeName = r"\\.\pipe\cwxeditor_" ~ to!(string)(i);
				auto p = CreateFileW(toUTF16z(pipeName),
					GENERIC_READ | GENERIC_WRITE, 0, null, OPEN_EXISTING, 0, null);
				if (p == INVALID_HANDLE_VALUE) {
					if (!_pipeName.length) _pipeName = pipeName;
					if (!path1.length) break;
					continue;
				}
				scope (exit) CloseHandle(p);
				if (!path1.length) continue;
				string send = "get opened scenario";
				if (!WriteFile(p, send.ptr, send.length, &len, null)) continue;
				if (!ReadFile(p, buf.ptr, buf.length, &len, null)) continue;
				auto path2 = nabs(buf[0 .. len]);
				if (!cfnmatch(path1, path2)) continue;
				send = "open cwxpath ";
				foreach (j, s; openPaths) {
					if (j > 0) send ~= ";";
					send ~= s;
				}
				if (!WriteFile(p, send.ptr, send.length, &len, null)) continue;
				return;
			}
		} else {
			char[4096] buf;
			for (size_t i = 0; i < PIPE_APP_MAX; i++) {
				string pipeName = r"/pipe/cwxeditor_" ~ to!(string)(i);
				auto p = socket(PF_UNIX, SOCK_STREAM, 0);
				if (-1 == p) continue;
				scope (exit) close(p);
				sockaddr_un raddr;
				raddr.sun_family = AF_INET;
				strcpy(&(raddr.sun_path[1]), pipeName.ptr);
				if (-1 == connect(p, cast(sockaddr*) &raddr, raddr.sizeof)) {
					if (!_pipeName.length) _pipeName = pipeName;
					if (!path1.length) break;
					continue;
				}
				if (!path1.length) continue;
				string send = "get opened scenario";
				if (-1 == cwrite(p, send.ptr, send.length)) continue;
				int len = cread(p, buf.ptr, buf.length);
				if (-1 == len) continue;
				auto path2 = nabs(buf[0 .. len]);
				if (!cfnmatch(path1, path2)) continue;
				send = "open cwxpath ";
				foreach (j, s; openPaths) {
					if (j > 0) send ~= ";";
					send ~= s;
				}
				if (-1 == cwrite(p, send.ptr, send.length)) continue;
				return;
			}
		}
		_firstScenarioPath = firstScenarioPath;
		_openPaths = openPaths;
		_prop = new Props(propFilePath, new CProps(appPath, sys));
		if (_prop.var.etc.tempPath.length == 0) {
			string t = getenv("TEMP");
			if (t) _prop.var.etc.tempPath = std.path.join(t, "cwxeditor");
		}
		if (_prop.var.etc.tempPath.length == 0) {
			string t = getenv("TMP");
			if (t) _prop.var.etc.tempPath = std.path.join(t, "cwxeditor");
		}
		if (_prop.var.etc.tempPath.length == 0) {
			string t = getenv("TMPDIR");
			if (t) _prop.var.etc.tempPath = std.path.join(t, "cwxeditor");
		}
		if (_prop.var.etc.tempPath.length == 0) {
			_prop.var.etc.tempPath = "temp";
		}
		if (exists(_prop.tempPath)) {
			foreach (temp; clistdir(_prop.tempPath)) {
				temp = std.path.join(_prop.tempPath, temp);
				if (exists(temp) && isdir(temp)) {
					auto lock = std.path.join(temp, "cwxeditor.lock");
					if (exists(lock)) {
						try {
							std.file.remove(lock);
							delAll(temp);
						} catch (Exception e) {}
					} else if (fnstartsWith(getBaseName(temp), "cwxeditor_temp_")) {
						try {
							delAll(temp);
						} catch (Exception e) {}
					}
				}
			}
		}

		_comm = new Commons;
		_comm.skin = findSkin2(_prop, _prop.var.etc.defaultSkin);

		auto d = new Display;
		_display = d;
		d.setAppName = _prop.msgs.application;
		if (_prop.var.etc.enginePath.length && !.exists(_prop.var.etc.enginePath)) {
			auto dlg = new SettingsDialog(_comm, _prop, null, null);
			if (!dlg.open) return;
		}

		string engineDir = "";
		if (_prop.var.etc.enginePath.length) {
			engineDir = getDirName(nabs(_prop.var.etc.enginePath));
			auto skinTable = .skinTable(_prop);
			if (!(_prop.var.etc.defaultSkin in skinTable)) {
				MessageBox.showWarning(_prop.msgs.loadSkinError(_prop.var.etc.defaultSkin),
					_prop.msgs.dlgTitWarning, null);
			}
		}

		if (_prop.var.etc.singleWindow) {
			_sbshl = new SBShell(null, SWT.SHELL_TRIM);
		} else {
			_sbshl = new SBShell(null, SWT.DIALOG_TRIM | SWT.MIN);
		}
		_win = _sbshl.shell;
		_win.setData = new TLPData(this);
		_win.setImage = _prop.images.app;

		_comm.save.add(&savec);
		_comm.refScenarioName.add(&__refreshTitle);
		_comm.refScenarioPath.add(&__refreshTitle);
		_comm.replText.add(&__refreshTitle);
		_win.addDisposeListener(new DListener);
		_win.addShellListener(new SListener);
		foreach (f; _prop.looks.fontFiles) {
			d.loadFont(std.path.join(engineDir, f));
		}
		_win.setText(_prop.msgs.mainWindowName(null, null));
		if (_prop.var.etc.singleWindow) {
			_sbshl.contentPane.setLayout = zeroGridLayout(1, true);
		} else {
			_sbshl.contentPane.setLayout = windowGridLayout(1, true);
		}
		auto toolComp = new Composite(_sbshl.contentPane, SWT.NONE);
		toolComp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		toolComp.setLayout = new FillLayout;
		if (_prop.var.etc.singleWindow) {
			auto dockComp = new Composite(_sbshl.contentPane, SWT.NONE);
			dockComp.setLayoutData = new GridData(GridData.FILL_BOTH);
			dockComp.setLayout = windowGridLayout(1, true);
			_dock = _prop.var.loadDock(dockComp, SWT.NONE, delegate Control(Composite parent, string key) {
				switch (key) {
				case "data": {
					_tableWin = new TableWindow(_comm, _prop, parent);
					return _tableWin.shell;
				}
				case "flag": {
					_flagWin = new FlagWindow(_comm, _prop, parent);
					return _flagWin.shell;
				}
				case "card": {
					_cardWin = new MainCardWindow(_comm, _prop, parent);
					return _cardWin.shell;
				}
				case "file": {
					_dirWin = new DirectoryWindow(_comm, _prop, parent);
					return _dirWin.shell;
				}
				default:
					debugln("Unknown pane key: " ~ key);
					return null;
				}
			});
			void initDock() {
				if (!_dock.findPane("work").length) {
					_dock.addPane(_dock.first, Dir.N, 3, 1, "work");
				}
				_dock.canMove = &dockCanMove;
				_dock.newPaneName = &dockNewPaneName;
				_dock.canVanish = &dockCanVanish;
				_dock.selectEvent ~= &dockSelect;
				_dock.closeCtrlEvent ~= &dockCloseCtrl;
				_dock.addCreatePaneEvent(&createPaneEvent);
				_dock.area.setLayoutData = new GridData(GridData.FILL_BOTH);
			}
			if (_dock) {
				initDock;
				if (_tableWin) {
					_dock.tabImage("data", _tableWin.image);
					_dock.tabText("data", _tableWin.title);
				} else {
					_tableWin = new TableWindow(_comm, _prop, null);
				}
				if (_flagWin) {
					_dock.tabImage("flag", _flagWin.image);
					_dock.tabText("flag", _flagWin.title);
				} else {
					_flagWin = new FlagWindow(_comm, _prop, null);
				}
				if (_cardWin) {
					_dock.tabImage("card", _cardWin.image);
					_dock.tabText("card", _cardWin.title);
				} else {
					_cardWin = new MainCardWindow(_comm, _prop, null);
				}
				if (_dirWin) {
					_dock.tabImage("file", _dirWin.image);
					_dock.tabText("file", _dirWin.title);
				} else {
					_dirWin = new DirectoryWindow(_comm, _prop, null);
				}
			} else {
				_dock = new DockingFolderCTC(dockComp, SWT.NONE, "work");
				initDock;
				auto data = _dock.addPane(_dock.first, Dir.N, 1, 3, "data");
				_tableWin = new TableWindow(_comm, _prop, data);
				_dock.add(_tableWin.shell, _tableWin.title, _tableWin.image, "data", true);
				_flagWin = new FlagWindow(_comm, _prop, data);
				_dock.add(_flagWin.shell, _flagWin.title, _flagWin.image, "flag", false);
				_cardWin = new MainCardWindow(_comm, _prop, data);
				_dock.add(_cardWin.shell, _cardWin.title, _cardWin.image, "card", false);
				_dirWin = new DirectoryWindow(_comm, _prop, data);
				_dock.add(_dirWin.shell, _dirWin.title, _dirWin.image, "file", false);
			}
		} else {
			_dataWin = new DataWindow(_comm, _prop, _win);
			_cardWin = new MainCardWindow(_comm, _prop, _win);
			_dirWin = new DirectoryWindow(_comm, _prop, _win);
		}

		_noSummMenu = new HashSet!(MenuID);
		_noSummMenu.add(MenuID.New);
		_noSummMenu.add(MenuID.Open);
		_noSummMenu.add(MenuID.Close);
		_noSummMenu.add(MenuID.ToXML);
		_noSummMenu.add(MenuID.DataWin);
		_noSummMenu.add(MenuID.FlagWin);
		_noSummMenu.add(MenuID.CardWin);
		_noSummMenu.add(MenuID.DirWin);
		_noSummMenu.add(MenuID.ChangeVH);
		_noSummMenu.add(MenuID.ShowCardLife);
		_noSummMenu.add(MenuID.ShowCardList);
		_noSummMenu.add(MenuID.ShowCardTable);
		_noSummMenu.add(MenuID.ExecEngine);
		_noSummMenu.add(MenuID.Settings);
		_noSummMenu.add(MenuID.Version);

		{
			_mainMenu = new HashSet!(MenuID);
			auto bar = new Menu(_win, SWT.BAR);

			_menuFile = createMenu(bar, _prop.msgs.menuFile);
			createFileMenu;

			auto me = createMenu(bar, _prop.msgs.menuEdit);
			if (_prop.var.etc.singleWindow) {
				mixin (MenuAction!("me", "OpenDirectory", SWT.PUSH, "openDirectory"));
				new MenuItem(me, SWT.SEPARATOR);
				mixin (MenuAction!("me", "Undo"));
				mixin (MenuAction!("me", "Redo"));
				new MenuItem(me, SWT.SEPARATOR);
				mixin (MenuAction!("me", "Cut"));
				mixin (MenuAction!("me", "Copy"));
				mixin (MenuAction!("me", "Paste"));
				mixin (MenuAction!("me", "Del"));
				new MenuItem(me, SWT.SEPARATOR);
				mixin (MenuAction!("me", "Up"));
				mixin (MenuAction!("me", "Down"));
				new MenuItem(me, SWT.SEPARATOR);
			}
			mixin (MenuAction!("me", "ReplaceText", SWT.PUSH, "replaceText"));
			mixin (MenuAction!("me", "ReNumberingAll", SWT.PUSH, "reNumberingAll"));
			mixin (MenuAction!("me", "ToXML", SWT.PUSH, "clipboardToXML"));
			new MenuItem(me, SWT.SEPARATOR);
			mixin (MenuAction!("me", "Reload", SWT.PUSH, "reload"));
			if (_prop.var.etc.singleWindow) {
				new MenuItem(me, SWT.SEPARATOR);
				mixin (MenuAction!("me", "NewFolder"));
			}

			auto mv = createMenu(bar, _prop.msgs.menuView);
			mixin (MenuAction!("mv", "DataWin", SWT.PUSH, "openDataWindow"));
			if (_prop.var.etc.singleWindow) {
				mixin (MenuAction!("mv", "FlagWin", SWT.PUSH, "openFlagWindow"));
			}
			mixin (MenuAction!("mv", "CardWin", SWT.PUSH, "openCardWindow"));
			mixin (MenuAction!("mv", "DirWin", SWT.PUSH, "openDirWindow"));
			if (_prop.var.etc.singleWindow) {
				new MenuItem(mv, SWT.SEPARATOR);
				mixin (MenuAction!("mv", "Refresh", SWT.PUSH, "refreshAll"));
				new MenuItem(mv, SWT.SEPARATOR);
				mixin (MenuAction!("mv", "ChangeVH"));
			}

			if (_prop.var.etc.singleWindow) {
				auto ma = createMenu(bar, _prop.msgs.menuTable);
				mixin (MenuAction!("ma", "Summary", SWT.PUSH, "_tableWin.editSummary"));
				new MenuItem(ma, SWT.SEPARATOR);
				mixin (MenuAction!("ma", "NewArea", SWT.PUSH, "_tableWin.createArea"));
				mixin (MenuAction!("ma", "NewBattle", SWT.PUSH, "_tableWin.createBattle"));
				mixin (MenuAction!("ma", "NewPackage", SWT.PUSH, "_tableWin.createPackage"));

				auto mf = createMenu(bar, _prop.msgs.menuVariable);
				mixin (MenuAction!("mf", "NewFlagDir", SWT.PUSH, "_flagWin.createFlagDir"));
				mixin (MenuAction!("mf", "NewFlag", SWT.PUSH, "_flagWin.createFlag"));
				mixin (MenuAction!("mf", "NewStep", SWT.PUSH, "_flagWin.createStep"));

				auto mc = createMenu(bar, _prop.msgs.menuNewCards);
				auto g = new RadioGroup!(MenuItem);
				mixin (MenuAction!("mc", "ShowCardLife", SWT.RADIO, "showCardLife"));
				auto scf = _menu[MenuID.ShowCardLife];
				g.append(scf);
				mixin (MenuAction!("mc", "ShowCardList", SWT.RADIO, "showCardList"));
				auto scl = _menu[MenuID.ShowCardList];
				g.append(scl);
				mixin (MenuAction!("mc", "ShowCardTable", SWT.RADIO, "showCardTable"));
				auto sct = _menu[MenuID.ShowCardTable];
				g.append(sct);
				if (_prop.var.etc.cardLife) {
					scf.setSelection = true;
 				} else if (_prop.var.etc.cardDetails) {
					sct.setSelection = true;
				} else {
					scl.setSelection = true;
				}
				_menuRG ~= g;
				new MenuItem(mc, SWT.SEPARATOR);
				mixin (MenuAction!("mc", "NewCast", SWT.PUSH, "newCast"));
				mixin (MenuAction!("mc", "NewSkill", SWT.PUSH, "newSkill"));
				mixin (MenuAction!("mc", "NewItem", SWT.PUSH, "newItem"));
				mixin (MenuAction!("mc", "NewBeast", SWT.PUSH, "newBeast"));
				mixin (MenuAction!("mc", "NewInfo", SWT.PUSH, "newInfo"));
				new MenuItem(mc, SWT.SEPARATOR);
				mixin (MenuAction!("mc", "AddScenario", SWT.PUSH, "_cardWin.addScenario"));
			}

			auto mt = createMenu(bar, _prop.msgs.menuTools);
			mixin (MenuAction!("mt", "ExecEngine", SWT.PUSH, "execEngine"));
			new MenuItem(mt, SWT.SEPARATOR);
			mixin (MenuAction!("mt", "Settings", SWT.PUSH, "settings"));

			auto mh = createMenu(bar, _prop.msgs.menuHelp);
			mixin (MenuAction!("mh", "Version", SWT.PUSH, "versionInfo"));

			_win.setMenuBar = bar;
		}

		if (_prop.var.etc.singleWindow) {
			_cbar = createCoolBar!("tools")(_prop, toolComp, (CoolBar cbar) {
				void createCoolItem(CoolBar cbar, ToolBar tbar) {
					.createCoolItem(cbar, tbar);
					_toolBar ~= tbar;
				}
				{
					auto bar = new ToolBar(cbar, SWT.FLAT);
					mixin (ToolAction!("bar", "New", SWT.PUSH, "createScenario"));
					mixin (ToolAction!("bar", "Open", SWT.PUSH, "openScenarioM"));
					mixin (ToolAction!("bar", "Save", SWT.PUSH, "saveScenario"));
					mixin (ToolAction!("bar", "SaveA", SWT.PUSH, "saveScenarioA"));
					new ToolItem(bar, SWT.SEPARATOR);
					mixin (ToolAction!("bar", "Reload", SWT.PUSH, "reload"));
					createCoolItem(cbar, bar);
				}
				{
					auto bar = new ToolBar(cbar, SWT.FLAT);
					mixin (ToolAction!("bar", "Refresh", SWT.PUSH, "refreshAll"));
					createCoolItem(cbar, bar);
				}
				{
					auto bar = new ToolBar(cbar, SWT.FLAT);
					mixin (ToolAction!("bar", "Undo"));
					mixin (ToolAction!("bar", "Redo"));
					createCoolItem(cbar, bar);
				}
				{
					auto bar = new ToolBar(cbar, SWT.FLAT);
					mixin (ToolAction!("bar", "Cut"));
					mixin (ToolAction!("bar", "Copy"));
					mixin (ToolAction!("bar", "Paste"));
					mixin (ToolAction!("bar", "Del"));
					createCoolItem(cbar, bar);
				}
				{
					auto bar = new ToolBar(cbar, SWT.FLAT);
					mixin (ToolAction!("bar", "Up"));
					mixin (ToolAction!("bar", "Down"));
					createCoolItem(cbar, bar);
				}
				{
					auto bar = new ToolBar(cbar, SWT.FLAT);
					mixin (ToolAction!("bar", "ReplaceText", SWT.PUSH, "replaceText"));
					new ToolItem(bar, SWT.SEPARATOR);
					mixin (ToolAction!("bar", "ReNumberingAll", SWT.PUSH, "reNumberingAll"));
					new ToolItem(bar, SWT.SEPARATOR);
					mixin (ToolAction!("bar", "ToXML", SWT.PUSH, "clipboardToXML"));
					createCoolItem(cbar, bar);
				}
				{
					auto bar = new ToolBar(cbar, SWT.FLAT);
					mixin (ToolAction!("bar", "DataWin", SWT.PUSH, "openDataWindow"));
					mixin (ToolAction!("bar", "FlagWin", SWT.PUSH, "openFlagWindow"));
					mixin (ToolAction!("bar", "CardWin", SWT.PUSH, "openCardWindow"));
					mixin (ToolAction!("bar", "DirWin", SWT.PUSH, "openDirWindow"));
					createCoolItem(cbar, bar);
				}
				{
					auto bar = new ToolBar(cbar, SWT.FLAT);
					mixin (ToolAction!("bar", "ChangeVH"));
					createCoolItem(cbar, bar);
				}
				{
					auto bar = new ToolBar(cbar, SWT.FLAT);
					mixin (ToolAction!("bar", "Summary", SWT.PUSH, "_tableWin.editSummary"));
					new ToolItem(bar, SWT.SEPARATOR);
					mixin (ToolAction!("bar", "NewArea", SWT.PUSH, "_tableWin.createArea"));
					mixin (ToolAction!("bar", "NewBattle", SWT.PUSH, "_tableWin.createBattle"));
					mixin (ToolAction!("bar", "NewPackage", SWT.PUSH, "_tableWin.createPackage"));
					new ToolItem(bar, SWT.SEPARATOR);
					mixin (ToolAction!("bar", "NewFlagDir", SWT.PUSH, "_flagWin.createFlagDir"));
					mixin (ToolAction!("bar", "NewFlag", SWT.PUSH, "_flagWin.createFlag"));
					mixin (ToolAction!("bar", "NewStep", SWT.PUSH, "_flagWin.createStep"));
					createCoolItem(cbar, bar);
				}
				{
					auto bar = new ToolBar(cbar, SWT.FLAT);
					auto g = new RadioGroup!(ToolItem);
					mixin (ToolAction!("bar", "ShowCardLife", SWT.RADIO, "showCardLife"));
					auto scf = _tool[MenuID.ShowCardLife];
					g.append(scf);
					mixin (ToolAction!("bar", "ShowCardList", SWT.RADIO, "showCardList"));
					auto scl = _tool[MenuID.ShowCardList];
					g.append(scl);
					mixin (ToolAction!("bar", "ShowCardTable", SWT.RADIO, "showCardTable"));
					auto sct = _tool[MenuID.ShowCardTable];
					g.append(sct);
					if (_prop.var.etc.cardLife) {
						scf.setSelection = true;
					} else if (_prop.var.etc.cardDetails) {
						sct.setSelection = true;
					} else {
						scl.setSelection = true;
					}
					_toolRG ~= g;
					new ToolItem(bar, SWT.SEPARATOR);
					mixin (ToolAction!("bar", "NewCast", SWT.PUSH, "newCast"));
					mixin (ToolAction!("bar", "NewSkill", SWT.PUSH, "newSkill"));
					mixin (ToolAction!("bar", "NewItem", SWT.PUSH, "newItem"));
					mixin (ToolAction!("bar", "NewBeast", SWT.PUSH, "newBeast"));
					mixin (ToolAction!("bar", "NewInfo", SWT.PUSH, "newInfo"));
					new ToolItem(bar, SWT.SEPARATOR);
					mixin (ToolAction!("bar", "AddScenario", SWT.PUSH, "_cardWin.addScenario"));
					createCoolItem(cbar, bar);
				}
				{
					auto bar = new ToolBar(cbar, SWT.FLAT);
					mixin (ToolAction!("bar", "OpenDirectory", SWT.PUSH, "openDirectory"));
					mixin (ToolAction!("bar", "NewFolder"));
					createCoolItem(cbar, bar);
				}
				{
					auto bar = new ToolBar(cbar, SWT.FLAT);
					mixin (ToolAction!("bar", "ExecEngine", SWT.PUSH, "execEngine"));
					new ToolItem(bar, SWT.SEPARATOR);
					mixin (ToolAction!("bar", "Settings", SWT.PUSH, "settings"));
					createCoolItem(cbar, bar);
				}
			});

			auto drop = new DropTarget(_cbar, DND.DROP_DEFAULT | DND.DROP_LINK);
			drop.setTransfer([FileTransfer.getInstance]);
			drop.addDropListener(new DTListener);

			_comm.baseShell(this, _tableWin, _flagWin, _cardWin, _dirWin);
		} else {
			auto bar = new ToolBar(toolComp, SWT.FLAT);
			mixin (ToolAction!("bar", "New", SWT.PUSH, "createScenario"));
			mixin (ToolAction!("bar", "Open", SWT.PUSH, "openScenarioM"));
			mixin (ToolAction!("bar", "Save", SWT.PUSH, "saveScenario"));
			mixin (ToolAction!("bar", "SaveA", SWT.PUSH, "saveScenarioA"));
			new ToolItem(bar, SWT.SEPARATOR);
			mixin (ToolAction!("bar", "ReplaceText", SWT.PUSH, "replaceText"));
			mixin (ToolAction!("bar", "ReNumberingAll", SWT.PUSH, "reNumberingAll"));
			mixin (ToolAction!("bar", "ToXML", SWT.PUSH, "clipboardToXML"));
			new ToolItem(bar, SWT.SEPARATOR);
			mixin (ToolAction!("bar", "Reload", SWT.PUSH, "reload"));
			new ToolItem(bar, SWT.SEPARATOR);
			mixin (ToolAction!("bar", "DataWin", SWT.PUSH, "openDataWindow"));
			mixin (ToolAction!("bar", "CardWin", SWT.PUSH, "openCardWindow"));
			mixin (ToolAction!("bar", "DirWin", SWT.PUSH, "openDirWindow"));
			new ToolItem(bar, SWT.SEPARATOR);
			mixin (ToolAction!("bar", "ExecEngine", SWT.PUSH, "execEngine"));
			new ToolItem(bar, SWT.SEPARATOR);
			mixin (ToolAction!("bar", "Settings", SWT.PUSH, "settings"));
			new ToolItem(bar, SWT.SEPARATOR);
			mixin (ToolAction!("bar", "Close", SWT.PUSH, "exitAll"));
			_toolBar ~= bar;

			auto drop = new DropTarget(bar, DND.DROP_DEFAULT | DND.DROP_LINK);
			drop.setTransfer([FileTransfer.getInstance]);
			drop.addDropListener(new DTListener);

			_comm.baseShell(this, _dataWin, _cardWin, _dirWin);
			setupMenu(_menu);
			setupMenu(_tool);
		}

		int tx = _prop.var.mainWin.x == SWT.DEFAULT ? _win.getBounds.x : _prop.var.mainWin.x;
		int ty = _prop.var.mainWin.y == SWT.DEFAULT ? _win.getBounds.y : _prop.var.mainWin.y;
		if (_prop.var.etc.singleWindow) {
			_win.setMaximized = _prop.var.mainWin.maximized;
			intoDisplay(tx, ty, _prop.var.mainWin.width, _prop.var.mainWin.height);
			_win.setBounds(tx, ty, _prop.var.mainWin.width, _prop.var.mainWin.height);
			_win.layout(true);
		} else {
			_win.pack;
			intoDisplay(tx, ty, _win.getSize.x, _win.getSize.y);
			_win.setBounds(tx, ty, _win.getSize.x, _win.getSize.y);
		}
		if (_dock) {
			dockSelect("data");
			setupMenu(_menu);
			setupMenu(_tool);
		}
	}
	private template NewCard(string Name) {
		static const NewCard = "auto cw = cast(ICardWindow) _tlp;"
			~ "if (cw && cw.canCreate" ~ Name ~ ") {"
			~ "    cw.create" ~ Name ~ ";"
			~ "} else {"
			~ "    _comm.openCardWin;"
			~ "    _cardWin.create" ~ Name ~ ";"
			~ "}";
	}
	private void refreshAll(SelectionEvent se) {
		if (!_dock) return;
		foreach (ctrl; _dock.showingControls) {
			auto tlpData = cast(TLPData) ctrl.getData;
			if (!tlpData) continue;
			auto act = tlpData.tlp.menuAction(MenuID.Refresh);
			if (act) act(se);
		}
	}
	private class TabfPaint : PaintListener {
		override void paintControl(PaintEvent e) {
			auto path = _prop.var.etc.backgroundImage;
			if (!path.length || !.exists(path)) return;
			auto tabf = cast(CTabFolder) e.widget;
			if (!tabf || tabf.getItemCount > 0) return;
			auto rect = tabf.getClientArea;
			auto data = loadImage(path, false);
			auto d = Display.getCurrent;
			auto img = new Image(d, data);
			scope (exit) img.dispose;
			drawTileImage(e.gc, img, rect);
		}
	}
	private class TabMenu {
		private string _paneKey;
		this (string paneKey) {
			_paneKey = paneKey;
			auto comp = _dock.pane(paneKey);
			comp.addPaintListener(new TabfPaint);
			auto menu = new Menu(comp.getShell, SWT.POP_UP);
			createMenuItem(menu, _prop.msgs.menuClosePane, _prop.images.menuClosePane, &close);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(menu, _prop.msgs.menuClosePaneEtc, _prop.images.menuClosePaneEtc, &closeEtc);
			createMenuItem(menu, _prop.msgs.menuClosePaneLeft, _prop.images.menuClosePaneLeft, &closeLeft);
			createMenuItem(menu, _prop.msgs.menuClosePaneRight, _prop.images.menuClosePaneRight, &closeRight);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(menu, _prop.msgs.menuClosePaneAll, _prop.images.menuClosePaneAll, &closeAll);
			_dock.setMenu(paneKey, menu);
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
	private void openDirectory() {
		if (!summary) return;
		auto dirWin = cast(DirectoryWindow) _tlp;
		if (dirWin) {
			dirWin.openDirectory;
		} else {
			openFolder(summary.scenarioPath);
		}
	}
	private void showCardLife(SelectionEvent se) {
		auto cw = cast(ICardWindow) _tlp;
		if (cw) {
			menuAction!(MenuID.ShowCardLife)(se);
		} else {
			_cardWin.showCardLife;
			menuActionAfter!(MenuID.ShowCardLife);
		}
	}
	private void showCardList(SelectionEvent se) {
		auto cw = cast(ICardWindow) _tlp;
		if (cw) {
			menuAction!(MenuID.ShowCardList)(se);
		} else {
			_cardWin.showCardList;
			menuActionAfter!(MenuID.ShowCardList);
		}
	}
	private void showCardTable(SelectionEvent se) {
		auto cw = cast(ICardWindow) _tlp;
		if (cw) {
			menuAction!(MenuID.ShowCardTable)(se);
		} else {
			_cardWin.showCardTable;
			menuActionAfter!(MenuID.ShowCardTable);
		}
	}
	private void newCast() {mixin (NewCard!("Cast"));}
	private void newSkill() {mixin (NewCard!("Skill"));}
	private void newItem() {mixin (NewCard!("Item"));}
	private void newInfo() {mixin (NewCard!("Info"));}
	private void newBeast() {mixin (NewCard!("Beast"));}
	private void versionInfo() {
		(new VersionDialog(_prop, _win)).open;
	}

	private HashSet!(MenuID) _noSummMenu;
	private MenuItem[MenuID] _menu;
	private ToolItem[MenuID] _tool;
	private RadioGroup!(MenuItem)[] _menuRG;
	private RadioGroup!(ToolItem)[] _toolRG;
	private HashSet!(MenuID) _mainMenu;
	private ToolBar[] _toolBar;
	private TopLevelPanel _tlp = null;
	private template MenuAction(string M, string S, int Style = SWT.PUSH, string Act = "") {
		static if (Act.length) {
			static const MenuAction = "_mainMenu.add(MenuID." ~ S ~ ");"
				~ "_menu[MenuID." ~ S ~ "] = createMenuItem(" ~ M ~ ", _prop.msgs.menu" ~ S ~ ", _prop.images.menu" ~ S ~ ", &"
				~ Act ~ ", " ~ ToString!(Style) ~ ");";
		} else {
			static const MenuAction = "_menu[MenuID." ~ S ~ "] = createMenuItem(" ~ M ~ ", _prop.msgs.menu" ~ S ~ ", _prop.images.menu" ~ S ~ ", "
				~ "&menuAction!(MenuID." ~ S ~ "), " ~ ToString!(Style) ~ ");";
		}
	}
	private template ToolAction(string T, string S, int Style = SWT.PUSH, string Act = "") {
		static if (Act.length) {
			static const ToolAction = "_mainMenu.add(MenuID." ~ S ~ ");"
				~ "_tool[MenuID." ~ S ~ "] = createToolItem(" ~ T ~ ", _prop.msgs.tt" ~ S ~ ", _prop.images.menu" ~ S ~ ", &"
				~ Act ~ ", " ~ ToString!(Style) ~ ");";
		} else {
			static const ToolAction = "_tool[MenuID." ~ S ~ "] = createToolItem(" ~ T ~ ", _prop.msgs.tt" ~ S ~ ", _prop.images.menu" ~ S ~ ", "
				~ "&menuAction!(MenuID." ~ S ~ "), " ~ ToString!(Style) ~ ");";
		}
	}
	private void menuActionAfterImpl(MenuID ID, T)(T[MenuID] tools, RadioGroup!(T)[] rg) {
		if (!_tlp) return;
		if (_tlp.menuChecked(ID)) {
			auto p = ID in tools;
			if (p) {
				auto b = *p;
				foreach (g; rg) {
					if (g.contains(b)) {
						foreach (gb; g.set) {
							gb.setSelection = gb is b;
						}
						return;
					}
				}
				b.setSelection = _tlp.menuChecked(ID)();
			}
		}
	}
	private void menuAction(MenuID ID)(SelectionEvent se) {
		if (!_tlp) return;
		auto act = _tlp.menuAction(ID);
		assert (act);
		act(se);
		menuActionAfter!(ID);
	}
	private void menuActionAfter(MenuID ID)() {
		menuActionAfterImpl!(ID)(_menu, _menuRG);
		menuActionAfterImpl!(ID)(_tool, _toolRG);
	}

	private void setupMenu(M)(M[MenuID] menus) {
		foreach (id, itm; menus) {
			if (_tlp) {
				auto s = itm.getStyle;
				if ((s & SWT.RADIO) || (s & SWT.CHECK)) {
					auto chk = _tlp.menuChecked(id);
					if (chk) itm.setSelection = chk();
				}
			}
			if (!summary && !_noSummMenu.contains(id)) {
				itm.setEnabled = false;
				continue;
			}
			if (_mainMenu.contains(id)) {
				itm.setEnabled = true;
				continue;
			}
			itm.setEnabled = _tlp && _tlp.menuAction(id);
		}
	}
	private void dockSelect(string key) {
		if (!_dock) return;
		if (!_dock.control(key)) return;
		auto tlp = (cast(TLPData) _dock.control(key).getData).tlp;
		assert (tlp, key);
		_tlp = tlp;
		statusLine = tlp.statusLine;
		setupMenu(_menu);
		setupMenu(_tool);
	}
	private bool dockCanMove(string ctrlKey, string dropPaneKey) {
		if (!dropPaneKey.length) return true;
		bool iswa = cwx.utils.startsWith(dropPaneKey, "work");
		if (cwx.utils.startsWith(ctrlKey, "work")) {
			return iswa;
		} else {
			return !iswa;
		}
	}
	private bool dockCanVanish(string key) {
		if (cwx.utils.startsWith(key, "work")) {
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
		if (cwx.utils.startsWith(ctrlKey, "work")) {
			return _dock.newPaneKey("work");
		} else if (cwx.utils.startsWith(basePane, "work")) {
			if (dir == Dir.E || dir == Dir.W) {
				return _dock.newPaneKey("side");
			} else if (dir == Dir.N || dir == Dir.S) {
				return _dock.newPaneKey("data");
			}
		}
		return "";
	}
	private void setStatusLine(string status) {
		_comm.statusLine(_win, status);
	}

	string title() {return _win.getText;}
	Image image() {return _win.getImage;}
	Composite shell() {return _win;}
	void delegate(string) statusText() {return &_sbshl.statusLine;}
	DockingFolderCTC dock() {return _dock;}

	Summary summary() {return _dataWin ? _dataWin.summary : _tableWin.summary;}

	void reNumbering(A)(A[] arr, bool hand = false) {
		ulong newId = 1;
		foreach (a; arr) {
			if (a.id != newId) {
				if (!hand) summary.useCounter.change(A.toID(a.id), A.toID(newId));
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
		scope (exit) dlg.dispose;
		dlg.setText = _prop.msgs.dlgTitQuestion;
		dlg.setMessage = _prop.msgs.reNumberingAll;
		if (SWT.OK == dlg.open) {
			reNumbering(summary.areas);
			reNumbering(summary.battles);
			reNumbering(summary.packages);
			reNumbering(summary.casts);
			foreach (c; summary.casts) {
				reNumbering(c.skills, true);
				reNumbering(c.items, true);
				reNumbering(c.beasts, true);
			}
			reNumbering(summary.skills);
			reNumbering(summary.items);
			reNumbering(summary.beasts);
			reNumbering(summary.infos);
		}
	}

	ReplaceDialog openReplWin() {
		if (summary) {
			if (!_replDlg || _replDlg.widget.isDisposed) {
				_replDlg = new ReplaceDialog(_comm, _prop, _win, summary);
				auto b = _win.getBounds;
				auto p = _replDlg.widget.getSize;
				int x = b.x + (b.width - p.x) / 2;
				int y = b.y + (b.height - p.y) / 2;
				intoDisplay(x, y, p.x, p.y);
				_replDlg.widget.setLocation = new Point(x, y);
				_replDlg.replaceText("");
			} else {
				_replDlg.widget.setMinimized = false;
				_replDlg.widget.setActive;
			}
			return _replDlg;
		}
		return null;
	}

	bool openCWXPath(string path) {
		if (!summary) return false;
		bool open() {
			path = toLower(path);
			if (path == "") {
				return true;
			}
			auto cate = cpcategory(path);
			switch (cate) {
			case "area", "battle", "package", "area:id", "battle:id", "package:id", "variable": {
				if (_dataWin) {
					return _dataWin.openCWXPath(path);
				} else if (cate == "variable") {
					return _flagWin.openCWXPath(path);
				} else {
					return _tableWin.openCWXPath(path);
				}
			} case "castcard", "skillcard", "itemcard", "beastcard", "infocard",
					"castcard:id", "skillcard:id", "itemcard:id", "beastcard:id", "infocard:id": {
				return _cardWin.openCWXPath(path);
			} default: return false;
			}
		}
		if (open) {
			_win.setMinimized = false;
			_win.forceActive;
			return true;
		}
		return false;
	}

	void doCWX() {
		if (!_win) return;
		auto d = _win.getDisplay;
		_win.open;
		if (_firstScenarioPath) {
			openScenario(_firstScenarioPath);
		}

		auto pipe = new std.thread.Thread(&pipeThr);
		pipe.start;
		version (Windows) {
			scope (exit) {
				auto p = CreateFileW(toUTF16z(_pipeName),
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
		while (!_win.isDisposed) {
			version (nocatch) {
				if (!d.readAndDispatch) {
					d.sleep;
				}
			} else {
				// なるべくユーザデータを消さないよう、例外が発生しても処理を続行する。
				try {
					if (!d.readAndDispatch) {
						d.sleep;
					}
				} catch (Exception e) {
					_win.setVisible = true;
					fdebugln(e.msg ~ ", " ~ e.file ~ ", " ~ to!(string)(e.line));
					auto dlg = new MessageBox(_win, SWT.ICON_ERROR | SWT.OK);
					scope (exit) dlg.dispose;
					dlg.setText = _prop.msgs.dlgTitError;
					dlg.setMessage = _prop.msgs.unknownError ~ "\n---\n" ~ e.msg;
					dlg.open;
				} catch (Object o) {
					_win.setVisible = true;
					fdebugln(o.toString);
					auto dlg = new MessageBox(_win, SWT.ICON_ERROR | SWT.OK);
					scope (exit) dlg.dispose;
					dlg.setText = _prop.msgs.dlgTitError;
					dlg.setMessage = _prop.msgs.unknownError ~ "\n---\n" ~ o.toString;
					dlg.open;
				}
			}
		}
		_dirWin.quitTrace;
		_prop.images.disposeImages;
		d.dispose;
		_prop.var.save(dock);
		debug writefln("Exit Main Thread");
	}
}

class CreateScenarioDialog : AbsDialog {
private:
	Props _prop;

	Text _name;
	Combo _skinC;
	string _nameVal, _skinVal, _classicFolder;

public:
	this (Props prop, Shell shell) {
		_prop = prop;
		super(_prop, shell, _prop.msgs.dlgTitNewScenario, _prop.images.menuNew, true, _prop.var.newScDlg);
		enterClose = true;
	}

	string name() {
		return _nameVal;
	}
	string skin() {
		return _skinVal;
	}
	bool legacy() {return _skinVal.length == 0;}
	string classicFolder() {
		return _classicFolder;
	}
protected:
	override void setup(Composite area) {
		auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
		cl.fillHorizontal = true;
		area.setLayout = cl;
		auto comp = new Composite(area, SWT.NONE);
		comp.setLayout = new GridLayout(2, false);
		{
			auto l = new Label(comp, SWT.NONE);
			l.setText = _prop.msgs.scenarioName;
			_name = new Text(comp, SWT.BORDER);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_name.setLayoutData = gd;
			checker(_name);
		}
		{
			auto l = new Label(comp, SWT.NONE);
			l.setText = _prop.msgs.type;
			_skinC = new Combo(comp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			_skinC.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			auto skins = skinTable(_prop).keys;
			if (_prop.var.etc.logicalSort) {
				skins = sort!(ncmp)(skins);
			} else {
				skins = sort!(cmp)(skins);
			}
			foreach (type; skins) {
				_skinC.add(type);
			}
			if (!_skinC.getItemCount) {
				// スキンが無い
				_skinC.add(_prop.var.etc.defaultSkin);
			}
			if (_prop.var.etc.canCreateClassic) {
				_skinC.add(_prop.msgs.classic);
			}
			_skinC.setText = _prop.var.etc.defaultSkin;
			if (_skinC.getSelectionIndex == -1) _skinC.select = 0;
			checker(_skinC);
		}
	}

	override bool close(bool ok, out bool cancel) {
		if (ok) {
			_nameVal = _name.getText;
			if (_prop.var.etc.canCreateClassic && _skinC.getSelectionIndex == _skinC.getItemCount - 1) {
				_skinVal = "";
				auto dlg = new DirectoryDialog(getShell);
				scope (exit) dlg.dispose;
				dlg.setText = _prop.msgs.newClassicDir;
				dlg.setMessage = _prop.msgs.newClassicDirDesc;
				dlg.setFilterPath = _prop.var.etc.scenarioPath;
				while (true) {
					auto path = dlg.open;
					if (path) {
						if (clistdir(path).length) {
							auto q = new MessageBox(getShell, SWT.OK | SWT.CANCEL | SWT.ICON_QUESTION);
							scope (exit) q.dispose;
							q.setText = _prop.msgs.dlgTitQuestion;
							q.setMessage = _prop.msgs.notEmptyDir(path);
							if (SWT.OK != q.open) continue;
						}
						_prop.var.etc.scenarioPath = dlg.getFilterPath;
						_classicFolder = path;
					} else {
						ok = false;
						cancel = true;
					}
					break;
				}
			} else {
				_skinVal = _skinC.getText;
			}
		}
		return ok;
	}
}

class VersionDialog : AbsDialog {
private:
	Props _prop;

	class OpenLink : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto prog = Program.findProgram("html");
			if (prog) prog.execute(e.text);
		}
	}
public:
	this(Props prop, Shell shell) {
		super(prop, shell, prop.msgs.dlgTitVersion, prop.images.menuVersion, false, null, false, false);
		_prop = prop;
		enterClose = true;
		firstFocusIsOK = true;
	}
protected:
	override void setup(Composite area) {
		auto gl = new GridLayout(2, false);
		gl.marginWidth = 10;
		gl.horizontalSpacing = 15;
		area.setLayout = gl;
		auto d = Display.getCurrent;
		auto img = new Label(area, SWT.CENTER);
		img.setImage = _prop.images.icon;
		auto gd = new GridData;
		auto rect = _prop.images.icon.getBounds;
		gd.widthHint = rect.width;
		gd.heightHint = rect.height;
		gd.verticalSpan = 2;
		img.setLayoutData = gd;
		auto ln = new Link(area, SWT.NONE);
		ln.setText = _prop.msgs.application ~ " / " ~ _prop.msgs.appVersion ~ "\n"
			~ "<a>" ~ _prop.msgs.appWebSiteURI ~ "</a>\n"
			~ _prop.msgs.appDesc;
		ln.addSelectionListener(new OpenLink);
		auto lb = new Label(area, SWT.NONE);
		lb.setText = _prop.msgs.appBuild;
	}
}
