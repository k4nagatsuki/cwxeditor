
module cwx.editor.gui.dwt.mainwindow;

import std.file;
import std.path;
import std.zip;
import std.utf;
import std.process;
import std.thread;
import std.metastrings;

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

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.flagspane;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.utils;

import dwt.events.SelectionAdapter;
import dwt.events.SelectionEvent;
import dwt.events.KeyListener;
import dwt.events.ControlAdapter;
import dwt.events.ControlEvent;
import dwt.events.MouseMoveListener;
import dwt.events.MouseEvent;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.events.ShellAdapter;
import dwt.events.ShellEvent;
import dwt.widgets.Control;
import dwt.widgets.Composite;
import dwt.widgets.Combo;
import dwt.widgets.Label;
import dwt.widgets.CoolBar;
import dwt.widgets.CoolItem;
import dwt.widgets.Display;
import dwt.widgets.ToolBar;
import dwt.widgets.ToolItem;
import dwt.widgets.Shell;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.widgets.FileDialog;
import dwt.widgets.DirectoryDialog;
import dwt.widgets.MessageBox;
import dwt.widgets.Text;
import dwt.graphics.Image;
import dwt.program.Program;
import dwt.layout.FillLayout;
import dwt.layout.RowLayout;
import dwt.layout.RowData;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.dnd.DND;
import dwt.dnd.Clipboard;
import dwt.dnd.DropTarget;
import dwt.dnd.DropTargetEvent;
import dwt.dnd.DropTargetAdapter;
import dwt.dnd.FileTransfer;
import dwt.dnd.TextTransfer;
import dwt.dnd.Transfer;
import dwt.dwthelper.utils;

public:
class MainWindow : TopLevelPanel {
private:
	Shell _win = null;
	Label _status = null;
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
				summ = new Summary(dlg.name, dlg.skin, dlg.classicFolder, true);
			} else {
				auto p = Summary.createTempDir(_prop.tempPath, dlg.name);
				auto mFPath = std.path.join(p, findSkin2(_prop, dlg.skin).materialPath);
				if (!exists(mFPath) || !isdir(mFPath)) mkdir(mFPath);
				summ = new Summary(dlg.name, dlg.skin, p, false);
				if (summ.expandXMLs) {
					summ.saveXMLs(summ.scenarioPath);
				}
			}
			summ.author = _prop.var.etc.defaultAuthor;
			openScenario(summ);
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
	void openScenario(Summary summ) {
		assert (summ);
		auto old = summary;
		if (summ.type.length && !hasSkin(_prop, summ.type)) {
			MessageBox.showWarning(_prop.msgs.useDefaultSkin(summ.type, _prop.var.etc.defaultSkin),
				_prop.msgs.dlgTitWarning, _win);
			summ.type = _prop.var.etc.defaultSkin;
		}
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
		if (old) old.delTemp;
	}
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
			_prop.var.etc.expandXMLs, old, _prop.msgs.dlgTitOpenScenario, &openScenarioImpl);
	}
	void openScenario(string fname) {
		if (fnmatch(getExt(fname), "wid")) {
			ulong id;
			auto type = cwx.cwl.getType(fname, id);
			if (type) {
				string ts;
				if (type is typeid(Area)) {
					ts = "area";
				} else if (type is typeid(Battle)) {
					ts = "battle";
				} else if (type is typeid(Package)) {
					ts = "package";
				} else if (type is typeid(CastCard)) {
					ts = "castcard";
				} else if (type is typeid(SkillCard)) {
					ts = "skillcard";
				} else if (type is typeid(ItemCard)) {
					ts = "itemcard";
				} else if (type is typeid(BeastCard)) {
					ts = "beastcard";
				} else if (type is typeid(InfoCard)) {
					ts = "infocard";
				}
				ts ~= ":id:" ~ to!(string)(id);
				_openPaths ~= ts;
			}
			fname = getDirName(fname);
		}
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
			if (!summary.isSaved) {
				// いまだ保存されていない場合は名前をつけて保存
				return __saveScenarioA(shell);
			} else {
				shell.setCursor = Display.getCurrent.getSystemCursor(DWT.CURSOR_WAIT);
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
			auto dlg = new FileDialog(shell, DWT.PRIMARY_MODAL | DWT.APPLICATION_MODAL | DWT.SINGLE | DWT.SAVE);
			dlg.setFilterExtensions = ["*.wsn"];
			dlg.setFilterNames = [_prop.msgs.filterScenarioSave];
			dlg.setText = _prop.msgs.dlgTitSaveScenario;
			dlg.setFilterPath = scenarioFilterPath(_prop);
			dlg.setFileName = summary.scenarioName ~ ".wsn";
			dlg.setOverwrite = true;
			string fname = dlg.open;
			if (fname) {
				shell.setCursor = Display.getCurrent.getSystemCursor(DWT.CURSOR_WAIT);
				scope (exit) shell.setCursor = null;
				string tempPath = _prop.tempPath;
				bool expandXMLs = _prop.var.etc.expandXMLs;
				Skin defSkin = .findSkin2(_prop, _prop.var.etc.defaultSkin);
				try {
					summary.saveWithName(_prop.parent, _prop.var.etc.saveInnerImagePath,
						fname, tempPath, expandXMLs, defSkin, (string msg) {
							MessageBox.showWarning(msg, _prop.msgs.dlgTitWarning, shell);
						});
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
		string engine = summary ? findSkin(_prop, summary).engine : _prop.var.etc.enginePath;
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
		auto cb = new Clipboard(Display.getCurrent);
		scope (exit) cb.dispose;
		auto c = cb.getContents(XMLBytesTransfer.getInstance);
		if (c !is null && isXMLBytes(c)) {
			cb.setContents([new ArrayWrapperString(bytesToXML(c))], [TextTransfer.getInstance]);
		}
	}

	bool qSave(bool reload = false) {
		if (summary && (summary.isChanged || _dirWin.isChanged)) {
			MessageBox dlg;
			if (reload) {
				dlg = new MessageBox(_win, DWT.OK | DWT.CANCEL | DWT.ICON_QUESTION);
				dlg.setMessage = _prop.msgs.dlgMsgIsSaveBeforeReload(summary.scenarioName);
			} else {
				dlg = new MessageBox(_win, DWT.YES | DWT.NO | DWT.CANCEL | DWT.ICON_QUESTION);
				dlg.setMessage = _prop.msgs.dlgMsgIsSaveBeforeExit(summary.scenarioName);
			}
			scope (exit) dlg.dispose;
			dlg.setText = _prop.msgs.dlgTitQuestion;
			_win.setMinimized = false;
			switch (dlg.open) {
			case DWT.YES, DWT.OK:
				return reload ? true : save(_win);
			case DWT.NO:
				return true;
			case DWT.CANCEL:
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
					summary.delTemp;
				}
			} catch (Object e) {
				_win.setVisible = true;
				throw e;
			}
		}
	}
	class CDListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto cbar = cast(CoolBar) e.widget;
			_prop.var.etc.toolsWrapIndices = _cbar.getWrapIndices;
			_prop.var.etc.toolsOrder = _cbar.getItemOrder;
		}
	}
	void settings() {
		auto dlg = new SettingsDialog(_prop, _win);
		string[] oldHist = _prop.var.etc.openHistories;
		string[] oldKeyCodes = _prop.var.etc.standardKeyCodes;
		auto tools = _prop.var.etc.outerTools;
		if (dlg.open) {
			if (oldKeyCodes != _prop.var.etc.standardKeyCodes) {
				_comm.refStandardKeyCodes.call;
			}
			if (tools != _prop.var.etc.outerTools) {
				_comm.refOuterTools.call;
			}
		}
		if (oldHist != _prop.var.etc.openHistories) {
			createFileMenu;
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
			if (std.path.fnmatch(h, hist)) {
				_prop.var.etc.openHistories
					= _prop.var.etc.openHistories[0 .. i] ~ _prop.var.etc.openHistories[i + 1 .. $];
				break;
			}
		}
		_prop.var.etc.openHistories = [hist]
			~ (_prop.var.etc.openHistories.length < _prop.var.etc.historyMax
			? _prop.var.etc.openHistories : _prop.var.etc.openHistories[0 .. $ - 1]);
		createFileMenu;
	}
	class Hist {
		private string _hist;
		this(Menu menu, int num, string hist) {
			string text;
			Image img;
			if (std.path.fnmatch(getBaseName(hist), "Summary.xml")) {
				text = cuthist(hist[0u .. $ - "Summary.xml".length - std.path.sep.length],
					_prop.var.etc.historySnipLength);
				img = _prop.images.summaryFile;
			} else if (fnmatch(getExt(hist), "wsn")) {
				text = cuthist(hist, _prop.var.etc.historySnipLength);
				img = _prop.images.scenarioArchive;
			} else if (std.path.fnmatch(getBaseName(hist), "Summary.wsm")) {
				text = cuthist(hist[0u .. $ - "Summary.wsm".length - std.path.sep.length],
					_prop.var.etc.historySnipLength);
				img = _prop.images.classic;
			} else if (fnmatch(getExt(hist), "cab") || fnmatch(getExt(hist), "zip")) {
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
		createMenuItem(_menuFile, _prop.msgs.menuNew, _prop.images.menuNew, &createScenario);
		createMenuItem(_menuFile, _prop.msgs.menuOpen, _prop.images.menuOpen, &openScenarioM);
		createMenuItem(_menuFile, _prop.msgs.menuSave, _prop.images.menuSave, &saveScenario);
		createMenuItem(_menuFile, _prop.msgs.menuSaveA, _prop.images.menuSaveA, &saveScenarioA);
		new MenuItem(_menuFile, DWT.SEPARATOR);
		createMenuItem(_menuFile, _prop.msgs.menuReload, _prop.images.menuReload, &reload);
		new MenuItem(_menuFile, DWT.SEPARATOR);
		foreach (i, hist; _prop.var.etc.openHistories) {
			new Hist(_menuFile, i + 1, hist);
		}
		if (_prop.var.etc.openHistories.length > 0) new MenuItem(_menuFile, DWT.SEPARATOR);
		createMenuItem(_menuFile, _prop.msgs.menuClose, _prop.images.menuClose, &exitAll);
	}
public:
	this (string appPath, string propFilePath, cwx.system.System sys) {
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
					}
				}
			}
		}

		auto d = new Display;
		d.setAppName = _prop.msgs.application;
		if (_prop.var.etc.enginePath.length && !.exists(_prop.var.etc.enginePath)) {
			auto dlg = new SettingsDialog(_prop, null);
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
			_win = new Shell;
		} else {
			_win = new Shell(DWT.DIALOG_TRIM | DWT.MIN);
		}
		_win.setData = new TLPData(this);
		_win.setImage = _prop.images.app;

		_comm = new Commons;
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
			_win.setLayout = zeroGridLayout(1, true);
		} else {
			_win.setLayout = windowGridLayout(1, true);
		}

		auto toolComp = new Composite(_win, DWT.NONE);
		toolComp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		toolComp.setLayout = new FillLayout;
		if (_prop.var.etc.singleWindow) {
			auto dockComp = new Composite(_win, DWT.NONE);
			dockComp.setLayoutData = new GridData(GridData.FILL_BOTH);
			dockComp.setLayout = windowGridLayout(1, true);
			_dock = _prop.var.loadDock(dockComp, DWT.NONE, delegate Control(Composite parent, string key) {
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
				_dock = new DockingFolderCTC(dockComp, DWT.NONE, "work");
				initDock;
				auto data = _dock.addPane(_dock.first, Dir.N, 1, 3, "data");
				_tableWin = new TableWindow(_comm, _prop, data);
				_dock.add(_tableWin.shell, _tableWin.title, _tableWin.image, "data", true);
				_flagWin = new FlagWindow(_comm, _prop, data);
				_dock.add(_flagWin.shell, _flagWin.title, _flagWin.image, "flag", true);
				_cardWin = new MainCardWindow(_comm, _prop, data);
				_dock.add(_cardWin.shell, _cardWin.title, _cardWin.image, "card", false);
				_dirWin = new DirectoryWindow(_comm, _prop, data);
				_dock.add(_dirWin.shell, _dirWin.title, _dirWin.image, "file", false);
			}
			_status = new Label(dockComp, DWT.NONE);
		} else {
			_dataWin = new DataWindow(_comm, _prop, _win);
			_cardWin = new MainCardWindow(_comm, _prop, _win);
			_dirWin = new DirectoryWindow(_comm, _prop, _win);
			_status = new Label(_win, DWT.NONE);
		}
		_status.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		{
			_mainMenu = new HashSet!(MenuID);
			auto bar = new Menu(_win, DWT.BAR);

			_menuFile = createMenu(bar, _prop.msgs.menuFile);
			createFileMenu;

			auto me = createMenu(bar, _prop.msgs.menuEdit);
			if (_prop.var.etc.singleWindow) {
				mixin (MenuAction!("me", "OpenDirectory", DWT.PUSH, "openDirectory"));
				new MenuItem(me, DWT.SEPARATOR);
				mixin (MenuAction!("me", "Undo"));
				mixin (MenuAction!("me", "Redo"));
				new MenuItem(me, DWT.SEPARATOR);
				mixin (MenuAction!("me", "Cut"));
				mixin (MenuAction!("me", "Copy"));
				mixin (MenuAction!("me", "Paste"));
				mixin (MenuAction!("me", "Del"));
				new MenuItem(me, DWT.SEPARATOR);
				mixin (MenuAction!("me", "Up"));
				mixin (MenuAction!("me", "Down"));
				new MenuItem(me, DWT.SEPARATOR);
			}
			mixin (MenuAction!("me", "ReplaceText", DWT.PUSH, "replaceText"));
			mixin (MenuAction!("me", "ToXML", DWT.PUSH, "clipboardToXML"));
			new MenuItem(me, DWT.SEPARATOR);
			mixin (MenuAction!("me", "Reload", DWT.PUSH, "reload"));
			if (_prop.var.etc.singleWindow) {
				new MenuItem(me, DWT.SEPARATOR);
				mixin (MenuAction!("me", "NewFolder"));
			}

			auto mv = createMenu(bar, _prop.msgs.menuView);
			mixin (MenuAction!("mv", "DataWin", DWT.PUSH, "openDataWindow"));
			mixin (MenuAction!("mv", "CardWin", DWT.PUSH, "openCardWindow"));
			mixin (MenuAction!("mv", "DirWin", DWT.PUSH, "openDirWindow"));
			if (_prop.var.etc.singleWindow) {
				new MenuItem(mv, DWT.SEPARATOR);
				mixin (MenuAction!("mv", "Refresh"));
				new MenuItem(mv, DWT.SEPARATOR);
				mixin (MenuAction!("mv", "ChangeVH"));
			}

			if (_prop.var.etc.singleWindow) {
				auto ma = createMenu(bar, _prop.msgs.menuTable);
				mixin (MenuAction!("ma", "Summary", DWT.PUSH, "_tableWin.editSummary"));
				new MenuItem(ma, DWT.SEPARATOR);
				mixin (MenuAction!("ma", "NewArea", DWT.PUSH, "_tableWin.createArea"));
				mixin (MenuAction!("ma", "NewBattle", DWT.PUSH, "_tableWin.createBattle"));
				mixin (MenuAction!("ma", "NewPackage", DWT.PUSH, "_tableWin.createPackage"));

				auto mf = createMenu(bar, _prop.msgs.menuVariable);
				mixin (MenuAction!("mf", "NewFlagDir", DWT.PUSH, "_flagWin.createFlagDir"));
				mixin (MenuAction!("mf", "NewFlag", DWT.PUSH, "_flagWin.createFlag"));
				mixin (MenuAction!("mf", "NewStep", DWT.PUSH, "_flagWin.createStep"));

				auto mc = createMenu(bar, _prop.msgs.menuCards);
				auto g = new RadioGroup!(MenuItem);
				mixin (MenuAction!("mc", "ShowCardLife", DWT.RADIO, "showCardLife"));
				auto scf = _menu[MenuID.ShowCardLife];
				g.append(scf);
				mixin (MenuAction!("mc", "ShowCardList", DWT.RADIO, "showCardList"));
				auto scl = _menu[MenuID.ShowCardList];
				g.append(scl);
				mixin (MenuAction!("mc", "ShowCardTable", DWT.RADIO, "showCardTable"));
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
				new MenuItem(mc, DWT.SEPARATOR);
				mixin (MenuAction!("mc", "NewCast", DWT.PUSH, "newCast"));
				mixin (MenuAction!("mc", "NewSkill", DWT.PUSH, "newSkill"));
				mixin (MenuAction!("mc", "NewItem", DWT.PUSH, "newItem"));
				mixin (MenuAction!("mc", "NewBeast", DWT.PUSH, "newBeast"));
				mixin (MenuAction!("mc", "NewInfo", DWT.PUSH, "newInfo"));
				new MenuItem(mc, DWT.SEPARATOR);
				mixin (MenuAction!("mc", "AddScenario", DWT.PUSH, "_cardWin.addScenario"));
			}

			auto mt = createMenu(bar, _prop.msgs.menuTools);
			mixin (MenuAction!("mt", "ExecEngine", DWT.PUSH, "execEngine"));
			new MenuItem(mt, DWT.SEPARATOR);
			mixin (MenuAction!("mt", "Settings", DWT.PUSH, "settings"));

			_win.setMenuBar = bar;
		}

		_noSummMenu = new HashSet!(MenuID);
		_noSummMenu.add(MenuID.New);
		_noSummMenu.add(MenuID.Open);
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

		if (_prop.var.etc.singleWindow) {
			auto cbar = new CoolBar(toolComp, DWT.NONE);
			cbar.addControlListener(new CCListener);
			cbar.addDisposeListener(new CDListener);
			_cbar = cbar;
			void createCoolItem(CoolBar cbar, ToolBar tbar) {
				.createCoolItem(cbar, tbar);
				_toolBar ~= tbar;
			}
			{
				auto bar = new ToolBar(cbar, DWT.FLAT);
				mixin (ToolAction!("bar", "New", DWT.PUSH, "createScenario"));
				mixin (ToolAction!("bar", "Open", DWT.PUSH, "openScenarioM"));
				mixin (ToolAction!("bar", "Save", DWT.PUSH, "saveScenario"));
				mixin (ToolAction!("bar", "SaveA", DWT.PUSH, "saveScenarioA"));
				new ToolItem(bar, DWT.SEPARATOR);
				mixin (ToolAction!("bar", "Reload", DWT.PUSH, "reload"));
				createCoolItem(cbar, bar);
			}
			{
				auto bar = new ToolBar(cbar, DWT.FLAT);
				mixin (ToolAction!("bar", "Refresh"));
				createCoolItem(cbar, bar);
			}
			{
				auto bar = new ToolBar(cbar, DWT.FLAT);
				mixin (ToolAction!("bar", "Undo"));
				mixin (ToolAction!("bar", "Redo"));
				createCoolItem(cbar, bar);
			}
			{
				auto bar = new ToolBar(cbar, DWT.FLAT);
				mixin (ToolAction!("bar", "Cut"));
				mixin (ToolAction!("bar", "Copy"));
				mixin (ToolAction!("bar", "Paste"));
				mixin (ToolAction!("bar", "Del"));
				createCoolItem(cbar, bar);
			}
			{
				auto bar = new ToolBar(cbar, DWT.FLAT);
				mixin (ToolAction!("bar", "Up"));
				mixin (ToolAction!("bar", "Down"));
				createCoolItem(cbar, bar);
			}
			{
				auto bar = new ToolBar(cbar, DWT.FLAT);
				mixin (ToolAction!("bar", "ReplaceText", DWT.PUSH, "replaceText"));
				new ToolItem(bar, DWT.SEPARATOR);
				mixin (ToolAction!("bar", "ToXML", DWT.PUSH, "clipboardToXML"));
				createCoolItem(cbar, bar);
			}
			{
				auto bar = new ToolBar(cbar, DWT.FLAT);
				mixin (ToolAction!("bar", "DataWin", DWT.PUSH, "openDataWindow"));
				mixin (ToolAction!("bar", "FlagWin", DWT.PUSH, "openFlagWindow"));
				mixin (ToolAction!("bar", "CardWin", DWT.PUSH, "openCardWindow"));
				mixin (ToolAction!("bar", "DirWin", DWT.PUSH, "openDirWindow"));
				createCoolItem(cbar, bar);
			}
			{
				auto bar = new ToolBar(cbar, DWT.FLAT);
				mixin (ToolAction!("bar", "ChangeVH"));
				createCoolItem(cbar, bar);
			}
			{
				auto bar = new ToolBar(cbar, DWT.FLAT);
				mixin (ToolAction!("bar", "Summary", DWT.PUSH, "_tableWin.editSummary"));
				new ToolItem(bar, DWT.SEPARATOR);
				mixin (ToolAction!("bar", "NewArea", DWT.PUSH, "_tableWin.createArea"));
				mixin (ToolAction!("bar", "NewBattle", DWT.PUSH, "_tableWin.createBattle"));
				mixin (ToolAction!("bar", "NewPackage", DWT.PUSH, "_tableWin.createPackage"));
				new ToolItem(bar, DWT.SEPARATOR);
				mixin (ToolAction!("bar", "NewFlagDir", DWT.PUSH, "_flagWin.createFlagDir"));
				mixin (ToolAction!("bar", "NewFlag", DWT.PUSH, "_flagWin.createFlag"));
				mixin (ToolAction!("bar", "NewStep", DWT.PUSH, "_flagWin.createStep"));
				createCoolItem(cbar, bar);
			}
			{
				auto bar = new ToolBar(cbar, DWT.FLAT);
				auto g = new RadioGroup!(ToolItem);
				mixin (ToolAction!("bar", "ShowCardLife", DWT.RADIO, "showCardLife"));
				auto scf = _tool[MenuID.ShowCardLife];
				g.append(scf);
				mixin (ToolAction!("bar", "ShowCardList", DWT.RADIO, "showCardList"));
				auto scl = _tool[MenuID.ShowCardList];
				g.append(scl);
				mixin (ToolAction!("bar", "ShowCardTable", DWT.RADIO, "showCardTable"));
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
				new ToolItem(bar, DWT.SEPARATOR);
				mixin (ToolAction!("bar", "NewCast", DWT.PUSH, "newCast"));
				mixin (ToolAction!("bar", "NewSkill", DWT.PUSH, "newSkill"));
				mixin (ToolAction!("bar", "NewItem", DWT.PUSH, "newItem"));
				mixin (ToolAction!("bar", "NewBeast", DWT.PUSH, "newBeast"));
				mixin (ToolAction!("bar", "NewInfo", DWT.PUSH, "newInfo"));
				new ToolItem(bar, DWT.SEPARATOR);
				mixin (ToolAction!("bar", "AddScenario", DWT.PUSH, "_cardWin.addScenario"));
				createCoolItem(cbar, bar);
			}
			{
				auto bar = new ToolBar(cbar, DWT.FLAT);
				mixin (ToolAction!("bar", "OpenDirectory", DWT.PUSH, "openDirectory"));
				mixin (ToolAction!("bar", "NewFolder"));
				createCoolItem(cbar, bar);
			}
			{
				auto bar = new ToolBar(cbar, DWT.FLAT);
				mixin (ToolAction!("bar", "ExecEngine", DWT.PUSH, "execEngine"));
				new ToolItem(bar, DWT.SEPARATOR);
				mixin (ToolAction!("bar", "Settings", DWT.PUSH, "settings"));
				createCoolItem(cbar, bar);
			}
			int[] wi;
			foreach (i; _prop.var.etc.toolsWrapIndices) {
				if (i > 0 && i < cbar.getItemCount) wi ~= i;
			}
			cbar.setWrapIndices(wi);
			if (_prop.var.etc.toolsOrder.length == cbar.getItemCount) {
				cbar.setItemOrder(_prop.var.etc.toolsOrder);
			}

			auto drop = new DropTarget(cbar, DND.DROP_DEFAULT | DND.DROP_LINK);
			drop.setTransfer([FileTransfer.getInstance]);
			drop.addDropListener(new DTListener);

			_comm.baseShell(this, _tableWin, _flagWin, _cardWin, _dirWin);
		} else {
			auto bar = new ToolBar(toolComp, DWT.FLAT);
			mixin (ToolAction!("bar", "New", DWT.PUSH, "createScenario"));
			mixin (ToolAction!("bar", "Open", DWT.PUSH, "openScenarioM"));
			mixin (ToolAction!("bar", "Save", DWT.PUSH, "saveScenario"));
			mixin (ToolAction!("bar", "SaveA", DWT.PUSH, "saveScenarioA"));
			new ToolItem(bar, DWT.SEPARATOR);
			mixin (ToolAction!("bar", "ReplaceText", DWT.PUSH, "replaceText"));
			mixin (ToolAction!("bar", "ToXML", DWT.PUSH, "clipboardToXML"));
			new ToolItem(bar, DWT.SEPARATOR);
			mixin (ToolAction!("bar", "Reload", DWT.PUSH, "reload"));
			new ToolItem(bar, DWT.SEPARATOR);
			mixin (ToolAction!("bar", "DataWin", DWT.PUSH, "openDataWindow"));
			mixin (ToolAction!("bar", "CardWin", DWT.PUSH, "openCardWindow"));
			mixin (ToolAction!("bar", "DirWin", DWT.PUSH, "openDirWindow"));
			new ToolItem(bar, DWT.SEPARATOR);
			mixin (ToolAction!("bar", "ExecEngine", DWT.PUSH, "execEngine"));
			new ToolItem(bar, DWT.SEPARATOR);
			mixin (ToolAction!("bar", "Settings", DWT.PUSH, "settings"));
			new ToolItem(bar, DWT.SEPARATOR);
			mixin (ToolAction!("bar", "Close", DWT.PUSH, "exitAll"));
			_toolBar ~= bar;

			auto drop = new DropTarget(bar, DND.DROP_DEFAULT | DND.DROP_LINK);
			drop.setTransfer([FileTransfer.getInstance]);
			drop.addDropListener(new DTListener);

			_comm.baseShell(this, _dataWin, _cardWin, _dirWin);
		}

		int tx = _prop.var.mainWin.x == DWT.DEFAULT ? _win.getBounds.x : _prop.var.mainWin.x;
		int ty = _prop.var.mainWin.y == DWT.DEFAULT ? _win.getBounds.y : _prop.var.mainWin.y;
		if (_prop.var.etc.singleWindow) {
			intoDisplay(tx, ty, _prop.var.mainWin.width, _prop.var.mainWin.height);
			_win.setBounds(tx, ty, _prop.var.mainWin.width, _prop.var.mainWin.height);
			_win.setMaximized = _prop.var.mainWin.maximized;
			_win.layout(true);
		} else {
			_win.pack;
			intoDisplay(tx, ty, _win.getSize.x, _win.getSize.y);
			_win.setBounds(tx, ty, _win.getSize.x, _win.getSize.y);
		}
		if (_dock) dockSelect("data");
	}
	private class CCListener : ControlAdapter {
		override void controlResized(ControlEvent e) {
			_win.layout;
		}
	}
	private template NewCard(string Name) {
		static const NewCard = "auto cw = cast(ICardWindow) _tlp;"
			~ "if (cw) {"
			~ "    cw.create" ~ Name ~ ";"
			~ "} else {"
			~ "    _comm.openCardWin;"
			~ "    _cardWin.create" ~ Name ~ ";"
			~ "}";
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
	private void showCardLife() {
		auto cw = cast(ICardWindow) _tlp;
		if (cw) {
			menuAction!(MenuID.ShowCardLife);
		} else {
			_cardWin.showCardLife;
			menuActionAfter!(MenuID.ShowCardLife);
		}
	}
	private void showCardList() {
		auto cw = cast(ICardWindow) _tlp;
		if (cw) {
			menuAction!(MenuID.ShowCardList);
		} else {
			_cardWin.showCardList;
			menuActionAfter!(MenuID.ShowCardList);
		}
	}
	private void showCardTable() {
		auto cw = cast(ICardWindow) _tlp;
		if (cw) {
			menuAction!(MenuID.ShowCardTable);
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

	private HashSet!(MenuID) _noSummMenu;
	private MenuItem[MenuID] _menu;
	private ToolItem[MenuID] _tool;
	private RadioGroup!(MenuItem)[] _menuRG;
	private RadioGroup!(ToolItem)[] _toolRG;
	private HashSet!(MenuID) _mainMenu;
	private ToolBar[] _toolBar;
	private TopLevelPanel _tlp = null;
	private template MenuAction(string M, string S, int Style = DWT.PUSH, string Act = "") {
		static if (Act.length) {
			static const MenuAction = "_mainMenu.add(MenuID." ~ S ~ ");"
				~ "_menu[MenuID." ~ S ~ "] = createMenuItem(" ~ M ~ ", _prop.msgs.menu" ~ S ~ ", _prop.images.menu" ~ S ~ ", &"
				~ Act ~ ", " ~ ToString!(Style) ~ ");";
		} else {
			static const MenuAction = "_menu[MenuID." ~ S ~ "] = createMenuItem(" ~ M ~ ", _prop.msgs.menu" ~ S ~ ", _prop.images.menu" ~ S ~ ", "
				~ "&menuAction!(MenuID." ~ S ~ "), " ~ ToString!(Style) ~ ");";
		}
	}
	private template ToolAction(string T, string S, int Style = DWT.PUSH, string Act = "") {
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
	private void menuAction(MenuID ID)() {
		if (!_tlp) return;
		auto act = _tlp.menuAction(ID);
		assert (act);
		act();
		menuActionAfter!(ID);
	}
	private void menuActionAfter(MenuID ID)() {
		menuActionAfterImpl!(ID)(_menu, _menuRG);
		menuActionAfterImpl!(ID)(_tool, _toolRG);
	}

	private void setupMenu(M)(M[MenuID] menus) {
		foreach (id, itm; menus) {
			if (!summary && !_noSummMenu.contains(id)) {
				itm.setEnabled = false;
				continue;
			}
			if (_mainMenu.contains(id)) {
				itm.setEnabled = true;
				continue;
			}
			if (_tlp) {
				auto s = itm.getStyle;
				if (s & DWT.PUSH) {
					itm.setEnabled = _tlp.menuAction(id) !is null;
				} else if ((s & DWT.RADIO) || (s & DWT.CHECK)) {
					auto chk = _tlp.menuChecked(id);
					if (chk) {
						itm.setEnabled = true;
						itm.setSelection = chk();
					} else {
						itm.setEnabled = false;
					}
				}
			}
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
	Label statusText() {return _status;}
	DockingFolderCTC dock() {return _dock;}

	Summary summary() {return _dataWin ? _dataWin.summary : _tableWin.summary;}

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
			} else {
				_replDlg.widget.setMinimized = false;
				_replDlg.widget.setActive;
			}
			return _replDlg;
		}
		return null;
	}

	bool openCWXPath(string path) {
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

	void doCWX(string scenarioPath = null, string[] openPaths = []) {
		if (!_win) return;
		auto d = _win.getDisplay;
		_win.open;
		if (scenarioPath) {
			_openPaths = openPaths;
			openScenario(scenarioPath);
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
					debugln(e.msg ~ ", " ~ e.file ~ ", " ~ to!(string)(e.line));
					auto dlg = new MessageBox(_win, DWT.ICON_ERROR | DWT.OK);
					scope (exit) dlg.dispose;
					dlg.setText = _prop.msgs.dlgTitError;
					dlg.setMessage = _prop.msgs.unknownError ~ "\n" ~ e.msg;
					dlg.open;
				} catch (Object o) {
					debugln(o.toString);
					auto dlg = new MessageBox(_win, DWT.ICON_ERROR | DWT.OK);
					scope (exit) dlg.dispose;
					dlg.setText = _prop.msgs.dlgTitError;
					dlg.setMessage = _prop.msgs.unknownError ~ "\n" ~ o.toString;
					dlg.open;
				}
			}
		}
		_prop.images.disposeImages;
		d.dispose;
		_prop.var.save(dock);
	}
}

class CreateScenarioDialog : AbsDialog {
private:
	Props _prop;

	dwt.widgets.Text.Text _name;
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
		auto cl = new CenterLayout(DWT.HORIZONTAL | DWT.VERTICAL, 0);
		cl.fillHorizontal = true;
		area.setLayout = cl;
		auto comp = new Composite(area, DWT.NONE);
		comp.setLayout = new GridLayout(2, false);
		{
			auto l = new Label(comp, DWT.NONE);
			l.setText = _prop.msgs.scenarioName;
			_name = new dwt.widgets.Text.Text(comp, DWT.BORDER);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_name.setLayoutData = gd;
			checker(_name);
		}
		{
			auto l = new Label(comp, DWT.NONE);
			l.setText = _prop.msgs.type;
			_skinC = new Combo(comp, DWT.BORDER | DWT.DROP_DOWN | DWT.READ_ONLY);
			_skinC.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			foreach (type; .skinTable(_prop).keys.sort) {
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
							auto q = new MessageBox(getShell, DWT.OK | DWT.CANCEL | DWT.ICON_QUESTION);
							scope (exit) q.dispose;
							q.setText = _prop.msgs.dlgTitQuestion;
							q.setMessage = _prop.msgs.notEmptyDir(path);
							if (DWT.OK != q.open) continue;
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
