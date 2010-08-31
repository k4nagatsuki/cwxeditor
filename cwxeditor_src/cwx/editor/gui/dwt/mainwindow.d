
module cwx.editor.gui.dwt.mainwindow;

import std.file;
import std.path;
import std.zip;
import std.utf;
import std.process;
import std.thread;

import cwx.cwl;
import cwx.summary;
import cwx.event;
import cwx.flag;
import cwx.utils;
import cwx.archive;
import cwx.usecounter;
import cwx.props;
import cwx.skin;

import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.datawindow;
import cwx.editor.gui.dwt.cardwindow;
import cwx.editor.gui.dwt.directorywindow;
import cwx.editor.gui.dwt.settingsdialog;
import cwx.editor.gui.dwt.replacedialog;
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
import dwt.widgets.TabFolder;
import dwt.widgets.TabItem;
import dwt.widgets.Shell;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.widgets.FileDialog;
import dwt.widgets.DirectoryDialog;
import dwt.widgets.MessageBox;
import dwt.graphics.Image;
import dwt.program.Program;
import dwt.layout.FillLayout;
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

import dwtx.jface.dialogs.IDialogConstants;
import dwtx.jface.dialogs.Dialog;

public:
class MainWindow {
private:
	Shell _win = null;

	Props _prop;
	Commons _comm;

	DataWindow _dataWin;
	MainCardWindow _cardWin;
	DirectoryWindow _dirWin;

	void __refreshTitle() {
		_win.setText = _prop.msgs.mainWindowName
			(_dataWin.summary.scenarioName, getDirName(_dataWin.scenarioPath));
	}

	void createScenario() {
		if (qSave) {
			auto dlg = new CreateScenarioDialog(_prop, _win);
			if (dlg.open != IDialogConstants.OK_ID) return;
			auto old = _dataWin.summary;
			string name = dlg.name;
			string skinName = dlg.skinName;
			_comm.closeAll;
			auto p = Summary.createTempDir(_prop.tempPath, name);
			_dataWin.create(p, name, skinName);
			if (_dataWin.summary.expandXMLs) {
				_dataWin.summary.saveXMLs(_dataWin.summary.scenarioPath);
			}
			_cardWin.refresh(_dataWin.summary);
			_dirWin.refresh(_dataWin.summary);
			__refreshTitle;
			if (old) old.delTemp;
			if (_prop.var.dataWin.visible) _dataWin.open;
			if (_prop.var.cardWin.visible) _cardWin.open;
			if (_prop.var.dirWin.visible) _dirWin.open;
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
		auto old = _dataWin.summary;
		if (old.useTemp && !old.zipName.length) {
			MessageBox.showWarning(_prop.msgs.reloadBeforeSaveError(old.scenarioName),
				_prop.msgs.dlgTitWarning, _win);
			return;
		}
		if (old && qSave(true)) {
			bool expand = old.expandXMLs;
			if (old.legacy) {
				auto wsm = std.path.join(old.scenarioPath, "Summary.wsm");
				bool legacy = true;
				loadScenarioFromFile!(Summary)(_prop, _win, expand, old, wsm, &openScenario);
			} else if (expand) {
				try {
					openScenario(old.reloadXMLs);
				} catch (Exception e) {
					debugln(e);
					MessageBox.showWarning(_prop.msgs.reloadError
						(_dataWin.summary.scenarioPath) ~ "\n" ~ e.msg,
						_prop.msgs.dlgTitWarning, _win);
				}
			} else {
				assert (old.zipName.length);
				loadScenarioFromFile!(Summary)(_prop, _win, expand, old, old.zipName, &openScenario);
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
		if (!findSkin(_prop, summ, false)) {
			MessageBox.showWarning(_prop.msgs.useDefaultSkin(summ.type, _prop.var.etc.defaultSkin),
				_prop.msgs.dlgTitWarning, _win);
			summ.type = _prop.var.etc.defaultSkin;
		}
		_comm.closeAll;
		_dataWin.load(summ);
		_cardWin.refresh(summ);
		_dirWin.refresh(summ);
		_comm.refScenarioName.call;
		_comm.refScenarioPath.call;
		if (_prop.var.dataWin.visible) _dataWin.open;
		if (_prop.var.cardWin.visible) _cardWin.open;
		if (_prop.var.dirWin.visible) _dirWin.open;
		addHistory;
	}
	ulong[] _openAreas, _openBattles, _openPackages;
	void openScenarioImpl(Summary summ) {
		if (summ) {
			openScenario(summ);
			foreach (id; _openAreas) {
				_dataWin.openArea(id);
			}
			_openAreas.length = 0u;
			foreach (id; _openBattles) {
				_dataWin.openBattle(id);
			}
			_openBattles.length = 0u;
			foreach (id; _openPackages) {
				_dataWin.openPackage(id);
			}
			_openPackages.length = 0u;
		}
	}
	void openScenario() {
		auto old = _dataWin.summary;
		loadScenario!(Summary)(_prop, _win, _prop.var.etc.expandXMLs, old, _prop.msgs.dlgTitOpenScenario, &openScenarioImpl);
	}
	void openScenario(string fname) {
		auto old = _dataWin.summary;
		loadScenarioFromFile!(Summary)(_prop, _win, _prop.var.etc.expandXMLs, old, fname, &openScenarioImpl);
	}
	void saveScenario() {
		save(_win);
	}
	void savec(Shell shell) {
		save(shell);
	}
	bool save(Shell shell) {
		if (_dataWin.summary) {
			if (!_dataWin.summary.isSaved) {
				// いまだ保存されていない場合は名前をつけて保存
				return __saveScenarioA(shell);
			} else {
				shell.setCursor = Display.getCurrent.getSystemCursor(DWT.CURSOR_WAIT);
				scope (exit) shell.setCursor = null;
				try {
					_dataWin.summary.saveOverwrite(_prop.parent);
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
		if (_dataWin.summary) {
			auto dlg = new FileDialog(shell, DWT.PRIMARY_MODAL | DWT.APPLICATION_MODAL | DWT.SINGLE | DWT.SAVE);
			dlg.setFilterExtensions = ["*.wsn"];
			dlg.setFilterNames = [_prop.msgs.filterScenarioSave];
			dlg.setText = _prop.msgs.dlgTitSaveScenario;
			dlg.setFilterPath = scenarioFilterPath(_prop);
			dlg.setFileName = _dataWin.summary.scenarioName ~ ".wsn";
			dlg.setOverwrite = true;
			string fname = dlg.open;
			if (fname) {
				shell.setCursor = Display.getCurrent.getSystemCursor(DWT.CURSOR_WAIT);
				scope (exit) shell.setCursor = null;
				string tempPath = _prop.tempPath;
				bool expandXMLs = _prop.var.etc.expandXMLs;
				Skin defSkin = .findSkin2(_prop, _prop.var.etc.defaultSkin);
				try {
					_dataWin.summary.saveWithName(_prop.parent, fname, tempPath, expandXMLs, defSkin, (string msg) {
						MessageBox.showWarning(msg, _prop.msgs.dlgTitWarning, shell);
					});
					_prop.var.etc.scenarioPath = nabs(dlg.getFilterPath);
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
		string engine = _dataWin.summary ? findSkin(_prop, _dataWin.summary).engine : _prop.var.etc.enginePath;
		if (!exec(engine, getDirName(nabs(engine)))) {
			MessageBox.showWarning(_prop.msgs.errorExecEngine(engine),
				_prop.msgs.dlgTitWarning, _win);
		}
	}
	void openDataWindow() {
		if (_dataWin.summary) {
			_prop.var.dataWin.visible = true;
			_dataWin.open;
		}
	}
	void openCardWindow() {
		if (_dataWin.summary) {
			_prop.var.cardWin.visible = true;
			_cardWin.open;
		}
	}
	void openDirWindow() {
		if (_dataWin.summary) {
			_prop.var.dirWin.visible = true;
			_dirWin.open;
		}
	}
	void exitAll() {
		if (qSave) {
			_win.close;
		}
	}
	void replaceText() {
		if (_dataWin.summary) {
			auto dlg = new ReplaceDialog(_comm, _prop, _win, _dataWin.summary);
			dlg.open;
		}
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
		if (_dataWin.summary && (_dataWin.summary.isChanged || _dirWin.isChanged)) {
			MessageBox dlg;
			if (reload) {
				dlg = new MessageBox(_win, DWT.OK | DWT.CANCEL | DWT.ICON_QUESTION);
				dlg.setMessage = _prop.msgs.dlgMsgIsSaveBeforeReload(_dataWin.summary.scenarioName);
			} else {
				dlg = new MessageBox(_win, DWT.YES | DWT.NO | DWT.CANCEL | DWT.ICON_QUESTION);
				dlg.setMessage = _prop.msgs.dlgMsgIsSaveBeforeExit(_dataWin.summary.scenarioName);
			}
			scope (exit) dlg.dispose;
			dlg.setText = _prop.msgs.dlgTitQuestion;
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

	class SListener : ShellAdapter {
		override void shellClosed(ShellEvent e) {
			e.doit = qSave;
		}
	}

	void settings() {
		auto dlg = new SettingsDialog(_prop, _win);
		string[] oldHist = _prop.var.etc.openHistories;
		string[] oldKeyCodes = _prop.var.etc.standardKeyCodes;
		auto tools = _prop.var.etc.outerTools;
		string enginePath = _prop.var.etc.enginePath;
		if (IDialogConstants.OK_ID == dlg.open) {
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
		if (_dataWin.summary.legacy) {
			hist = std.path.join(_dataWin.summary.scenarioPath, "Summary.wsm");
		} else if (_dataWin.summary.useTemp) {
			hist = _dataWin.summary.zipName;
			if (!hist.length) return;
		} else {
			hist = std.path.join(_dataWin.summary.scenarioPath, "Summary.xml");
		}
		hist = nabs(hist);
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
	this(string appPath, string propFilePath, cwx.system.System sys) {
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
						} catch (IOException e) {}
					}
				}
			}
		}

		auto d = new Display;
		d.setAppName = _prop.msgs.application;
		if (!.exists(_prop.var.etc.enginePath)) {
			auto dlg = new SettingsDialog(_prop, null);
			if (IDialogConstants.OK_ID != dlg.open) return;
		}

		string engineDir = getDirName(nabs(_prop.var.etc.enginePath));
		auto skinTable = .skinTable(_prop);
		if (!(_prop.var.etc.defaultSkin in skinTable)) {
			MessageBox.showWarning(_prop.msgs.loadSkinError(_prop.var.etc.defaultSkin),
				_prop.msgs.dlgTitWarning, null);
			return;
		}

		_win = new Shell(d, DWT.DIALOG_TRIM | DWT.MIN);
		_win.setImage = _prop.images.app;

		_comm = new Commons;
		_comm.save.add(&savec);
		_comm.refScenarioName.add(&__refreshTitle);
		_comm.refScenarioPath.add(&__refreshTitle);
		_comm.replText.add(&__refreshTitle);
		_win.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.refScenarioName.remove(&__refreshTitle);
				_comm.refScenarioPath.remove(&__refreshTitle);
				_comm.replText.remove(&__refreshTitle);
			}
		});

		_win.addShellListener(new SListener);
		foreach (f; _prop.looks.fontFiles) {
			d.loadFont(engineDir ~ f);
		}
		_win.setText(_prop.msgs.mainWindowName(null, null));
		_win.setLayout = windowGridLayout(1);
		int tx = _prop.var.mainWin.x == DWT.DEFAULT ? _win.getBounds.x : _prop.var.mainWin.x;
		int ty = _prop.var.mainWin.y == DWT.DEFAULT ? _win.getBounds.y : _prop.var.mainWin.y;
		intoDisplay(tx, ty, _win.getSize.x, _win.getSize.y);
		_win.setBounds(tx, ty, _win.getSize.x, _win.getSize.y);
		_win.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_prop.var.mainWin.x = _win.getBounds.x;
				_prop.var.mainWin.y = _win.getBounds.y;
			}
		});
		{
			auto bar = new Menu(_win, DWT.BAR);

			_menuFile = createMenu(bar, _prop.msgs.menuFile);
			createFileMenu;

			auto me = createMenu(bar, _prop.msgs.menuEdit);
			createMenuItem(me, _prop.msgs.menuReplaceText, _prop.images.menuReplaceText, &replaceText);
			createMenuItem(me, _prop.msgs.menuToXML, _prop.images.menuToXML, &clipboardToXML);
			new MenuItem(me, DWT.SEPARATOR);
			createMenuItem(me, _prop.msgs.menuReload, _prop.images.menuReload, &reload);

			auto mv = createMenu(bar, _prop.msgs.menuView);
			createMenuItem(mv, _prop.msgs.menuDataWin, _prop.images.menuDataWin, &openDataWindow);
			createMenuItem(mv, _prop.msgs.menuCardWin, _prop.images.menuCardWin, &openCardWindow);
			createMenuItem(mv, _prop.msgs.menuDirWin, _prop.images.menuDirWin, &openDirWindow);

			auto mt = createMenu(bar, _prop.msgs.menuTools);
			createMenuItem(mt, _prop.msgs.menuExecEngine, _prop.images.menuExecEngine, &execEngine);
			new MenuItem(mt, DWT.SEPARATOR);
			createMenuItem(mt, _prop.msgs.menuSettings, _prop.images.menuSettings, &settings);

			_win.setMenuBar = bar;
		}

		{
			auto bar = new ToolBar(_win, DWT.FLAT);
			createToolItem(bar, _prop.msgs.ttNew, _prop.images.menuNew, &createScenario);
			createToolItem(bar, _prop.msgs.ttOpen, _prop.images.menuOpen, &openScenarioM);
			createToolItem(bar, _prop.msgs.ttSave, _prop.images.menuSave, &saveScenario);
			createToolItem(bar, _prop.msgs.ttSaveA, _prop.images.menuSaveA, &saveScenarioA);
			new ToolItem(bar, DWT.SEPARATOR);
			createToolItem(bar, _prop.msgs.ttReplaceText, _prop.images.menuReplaceText, &replaceText);
			createToolItem(bar, _prop.msgs.ttToXML, _prop.images.menuToXML, &clipboardToXML);
			new ToolItem(bar, DWT.SEPARATOR);
			createToolItem(bar, _prop.msgs.ttReload, _prop.images.menuReload, &reload);
			new ToolItem(bar, DWT.SEPARATOR);
			createToolItem(bar, _prop.msgs.ttDataWin, _prop.images.menuDataWin, &openDataWindow);
			createToolItem(bar, _prop.msgs.ttCardWin, _prop.images.menuCardWin, &openCardWindow);
			createToolItem(bar, _prop.msgs.ttDirWin, _prop.images.menuDirWin, &openDirWindow);
			new ToolItem(bar, DWT.SEPARATOR);
			createToolItem(bar, _prop.msgs.ttExecEngine, _prop.images.menuExecEngine, &execEngine);
			new ToolItem(bar, DWT.SEPARATOR);
			createToolItem(bar, _prop.msgs.ttSettings, _prop.images.menuSettings, &settings);
			new ToolItem(bar, DWT.SEPARATOR);
			createToolItem(bar, _prop.msgs.ttClose, _prop.images.menuClose, &exitAll);

			auto drop = new DropTarget(bar, DND.DROP_DEFAULT | DND.DROP_LINK);
			drop.setTransfer([FileTransfer.getInstance]);
			drop.addDropListener(new DTListener);
		}
		_dataWin = new DataWindow(_comm, _prop, _win);
		_cardWin = new MainCardWindow(_comm, _prop, _win);
		_dirWin = new DirectoryWindow(_comm, _prop, _win);
		_comm.baseShell(_win, _dataWin.shell, _cardWin.shell);
	}

	void doCWX(string scenarioPath = null, ulong[] openAreas = [], ulong[] openBattles = [], ulong[] openPackages = []) {
		if (!_win) return;
		auto d = _win.getDisplay;
		_win.pack;
		_win.open;
		if (scenarioPath) {
			_openAreas = openAreas;
			_openBattles = openBattles;
			_openPackages = openPackages;
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
		d.dispose;
		if (_dataWin.summary && _dataWin.summary.useTemp) {
			_dataWin.summary.delTemp;
		}
		_prop.var.save;
	}
}

class CreateScenarioDialog : Dialog {
private:
	Props _prop;

	dwt.widgets.Text.Text _name;
	Combo _skinC;
	string _nameVal, _skinVal;

public:
	this(Props prop, Shell shell) {
		super(shell);
		_prop = prop;
	}

	string name() {
		return _nameVal;
	}
	string skinName() {
		return _skinVal;
	}
protected:
	override void configureShell(Shell shell) {
		super.configureShell(shell);
		shell.setText = _prop.msgs.dlgTitNewScenario;
	}

	override Control createDialogArea(Composite parent) {
		auto area = cast(Composite) super.createDialogArea(parent);
		area.setLayout = new GridLayout(2, false);
		{
			auto l = new Label(area, DWT.NONE);
			l.setText = _prop.msgs.scenarioName;
			_name = new dwt.widgets.Text.Text(area, DWT.BORDER);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_name.setLayoutData = gd;
		}
		{
			auto l = new Label(area, DWT.NONE);
			l.setText = _prop.msgs.type;
			_skinC = new Combo(area, DWT.BORDER | DWT.DROP_DOWN | DWT.READ_ONLY);
			_skinC.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			foreach (type; .skinTable(_prop).keys.sort) {
				_skinC.add(type);
			}
			_skinC.setText = _prop.var.etc.defaultSkin;
		}

		return area;
	}

	override void createButtonsForButtonBar(Composite parent) {
		createButton(parent, IDialogConstants.OK_ID, IDialogConstants.OK_LABEL, true);
		createButton(parent, IDialogConstants.CANCEL_ID, IDialogConstants.CANCEL_LABEL, false);
	}

	override void buttonPressed(int buttonId) {
		if (buttonId == IDialogConstants.OK_ID) {
			if (_name.getText.length == 0) {
				buttonId = IDialogConstants.CANCEL_ID;
			} else {
				_nameVal = _name.getText;
				_skinVal = _skinC.getText;
			}
		}
		setReturnCode(buttonId);
		close;
		super.buttonPressed(buttonId);
	}
}
