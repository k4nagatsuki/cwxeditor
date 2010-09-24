
module cwx.editor.gui.dwt.datawindow;

import cwx.summary;
import cwx.event;
import cwx.flag;
import cwx.utils;
import cwx.usecounter;
import cwx.skin;
import cwx.path;

import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.areatable;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.flagspane;
import cwx.editor.gui.dwt.summarydialog;

import std.file;
import std.path;

import dwt.widgets.Control;
import dwt.widgets.Composite;
import dwt.widgets.CoolBar;
import dwt.widgets.CoolItem;
import dwt.widgets.ToolBar;
import dwt.widgets.ToolItem;
import dwt.widgets.TabFolder;
import dwt.widgets.TabItem;
import dwt.widgets.Shell;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.graphics.Image;
import dwt.layout.FillLayout;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.events.KeyListener;
import dwt.events.ShellAdapter;
import dwt.events.ShellEvent;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.events.ControlAdapter;
import dwt.events.ControlEvent;

import dwtx.jface.dialogs.IDialogConstants;

public:
class DataWindow : TopLevelPanel, TCPD {
private:
	Commons _comm;
	Composite _win;
	AreaTable _areas;
	FlagsPane _flags;
	Props _prop;
	TabFolder tabf;
	TabItem tabA;
	TabItem tabF;

	Summary _summ = null;

	TCPD[] _tcpd;

	void saveScenario() {
		_comm.save.call(_win.getShell);
	}
public:
	this(Commons comm, Props prop, Composite parent) {
		_prop = prop;
		_comm = comm;
		if (parent) construct(parent);
	}
	void reconstruct(Composite parent) {
		if (_win && !_win.isDisposed) return;
		construct(parent);
		if (_summ) refresh;
	}
	private void construct(Composite parent) {
		Shell shell = null;
		auto parShl = cast(Shell) parent;
		if (parShl) {
			shell = new Shell(parShl, DWT.SHELL_TRIM);
			shell.setImage = _prop.images.app;
			shell.addShellListener(new class ShellAdapter {
				public override void shellClosed(ShellEvent e) {
					(cast(Shell) e.widget).setVisible = false;
					e.doit = false;
					_prop.var.dataWin.visible = false;
				}
			});
			_win = shell;
		} else {
			_win = new Composite(parent, DWT.NONE);
		}
		_win.setData = new TLPData(this);
		_win.setLayout = windowGridLayout(1, true);

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
		if (shell) {
			{
				auto bar = new Menu(shell, DWT.BAR);

				auto mf = createMenu(bar, _prop.msgs.menuFile);
				createMenuItem(mf, _prop.msgs.menuSave, _prop.images.menuSave, &saveScenario);
				new MenuItem(mf, DWT.SEPARATOR);
				createMenuItem(mf, _prop.msgs.menuCloseWin, _prop.images.menuCloseWin, &shell.close);

				auto me = createMenu(bar, _prop.msgs.menuEdit);
				appendMenuTCPD(_prop, me, this);

				auto mt = createMenu(bar, _prop.msgs.menuTable);
				createMenuItem(mt, _prop.msgs.menuNewArea, _prop.images.menuNewArea, &createArea);
				createMenuItem(mt, _prop.msgs.menuNewBattle, _prop.images.menuNewBattle, &createBattle);
				createMenuItem(mt, _prop.msgs.menuNewPackage, _prop.images.menuNewPackage, &createPackage);

				auto mv = createMenu(bar, _prop.msgs.menuVariable);
				createMenuItem(mv, _prop.msgs.menuNewFlagDir, _prop.images.menuNewFlagDir, &createFlagDir);
				new MenuItem(mv, DWT.SEPARATOR);
				createMenuItem(mv, _prop.msgs.menuNewFlag, _prop.images.menuNewFlag, &createFlag);
				createMenuItem(mv, _prop.msgs.menuNewStep, _prop.images.menuNewStep, &createStep);

				shell.setMenuBar = bar;
			}
			{
				auto bar = new ToolBar(shell, DWT.FLAT);
				bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);

				createToolItem(bar, _prop.msgs.ttSummary, _prop.images.menuSummary, &editSummary);
				new ToolItem(bar, DWT.SEPARATOR);
				createToolItem(bar, _prop.msgs.ttNewArea, _prop.images.menuNewArea, &createArea);
				createToolItem(bar, _prop.msgs.ttNewBattle, _prop.images.menuNewBattle, &createBattle);
				createToolItem(bar, _prop.msgs.ttNewPackage, _prop.images.menuNewPackage, &createPackage);
				new ToolItem(bar, DWT.SEPARATOR);
				createToolItem(bar, _prop.msgs.ttNewFlag, _prop.images.menuNewFlag, &createFlag);
				createToolItem(bar, _prop.msgs.ttNewStep, _prop.images.menuNewStep, &createStep);
				createToolItem(bar, _prop.msgs.ttNewFlagDir, _prop.images.menuNewFlagDir, &createFlagDir);
			}
		} else {
			appendMenuTCPD(_prop, this, this);
			putMenuAction(_prop.msgs.menuNewArea, _prop.msgs.ttNewArea, &createArea);
			putMenuAction(_prop.msgs.menuNewBattle, _prop.msgs.ttNewBattle, &createBattle);
			putMenuAction(_prop.msgs.menuNewPackage, _prop.msgs.ttNewPackage, &createPackage);
			putMenuAction(_prop.msgs.menuNewFlagDir, _prop.msgs.ttNewFlagDir, &createFlagDir);
			putMenuAction(_prop.msgs.menuNewFlag, _prop.msgs.ttNewFlag, &createFlag);
			putMenuAction(_prop.msgs.menuNewStep, _prop.msgs.ttNewStep, &createStep);
			putMenuAction(_prop.msgs.menuSummary, _prop.msgs.ttSummary, &editSummary);
		}
		{
			tabf = new TabFolder(_win, DWT.NONE);
			tabf.setLayoutData = new GridData(GridData.FILL_BOTH);

			_flags = new FlagsPane(_comm, _prop, tabf);
			_areas = new AreaTable(_comm, _prop, tabf, _flags.flags);

			tabA = new TabItem(tabf, DWT.NONE);
			tabA.setText = _prop.msgs.scenarioView;
			tabA.setControl(_areas.table);
			tabF = new TabItem(tabf, DWT.NONE);
			tabF.setText = _prop.msgs.variableView;
			tabF.setControl(_flags.widget);

			_tcpd ~= _areas;
			_tcpd ~= _flags.flags;
			_tcpd ~= _flags.dirs;
		}
		if (shell) {
			scope wp = shell.computeSize(DWT.DEFAULT, DWT.DEFAULT);
			int width = _prop.var.dataWin.width == DWT.DEFAULT ? wp.x : _prop.var.dataWin.width;
			int height = _prop.var.dataWin.height == DWT.DEFAULT ? wp.y : _prop.var.dataWin.height;
			int x = _prop.var.dataWin.x == DWT.DEFAULT ? shell.getBounds.x : _prop.var.dataWin.x + shell.getParent.getBounds.x;
			int y = _prop.var.dataWin.y == DWT.DEFAULT ? shell.getBounds.y : _prop.var.dataWin.y + shell.getParent.getBounds.y;
			intoDisplay(x, y, width, height);
			shell.setBounds(x, y, width, height);
			shell.setMaximized = _prop.var.dataWin.maximized;
			shell.setMinimized = _prop.var.dataWin.minimized;
			shell.addControlListener(new class ControlAdapter {
				override void controlMoved(ControlEvent e) {
					saveDataWin;
				}
				override void controlResized(ControlEvent e) {
					saveDataWin;
				}
			});
		}
		_comm.refScenarioName.add(&__refreshTitle);
		_win.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.refScenarioName.remove(&__refreshTitle);
			}
		});
	}
	private void saveDataWin() {
		auto win = cast(Shell) _win;
		if (win) {
			if (!win.getMaximized && !win.getMinimized) {
				_prop.var.dataWin.width = win.getSize.x;
				_prop.var.dataWin.height = win.getSize.y;
				_prop.var.dataWin.x = win.getBounds.x - win.getParent.getBounds.x;
				_prop.var.dataWin.y = win.getBounds.y - win.getParent.getBounds.y;
			}
			_prop.var.dataWin.maximized = win.getMaximized;
			_prop.var.dataWin.minimized = win.getMinimized;
		}
	}
	Composite shell() {return _win;}
	/// エリアビューを開く。
	void openArea(ulong id) {
		_areas.openArea(id);
	}
	/// ditto
	void openBattle(ulong id) {
		_areas.openBattle(id);
	}
	/// ditto
	void openPackage(ulong id) {
		_areas.openPackage(id);
	}

	void createArea() {
		if (!_summ) return;
		_comm.openDataWin;
		tabf.setSelection(tabA);
		_areas.setFocus;
		_areas.createArea;
	}
	void createBattle() {
		if (!_summ) return;
		_comm.openDataWin;
		tabf.setSelection(tabA);
		_areas.setFocus;
		_areas.createBattle;
	}
	void createPackage() {
		if (!_summ) return;
		_comm.openDataWin;
		tabf.setSelection(tabA);
		_areas.setFocus;
		_areas.createPackage;
	}
	void createFlagDir() {
		if (!_summ) return;
		_comm.openDataWin;
		tabf.setSelection(tabF);
		_flags.dirs.setFocus;
		_flags.dirs.createDir;
	}
	void createFlag() {
		if (!_summ) return;
		_comm.openDataWin;
		tabf.setSelection(tabF);
		_flags.flags.setFocus;
		_flags.flags.createFlag;
	}
	void createStep() {
		if (!_summ) return;
		_comm.openDataWin;
		tabf.setSelection(tabF);
		_flags.flags.setFocus;
		_flags.flags.createStep;
	}
	void editSummary() {
		if (!_summ) return;
		string oldName = _summ.scenarioName;
		string oldType = _summ.type;
		auto dlg = new SummaryDialog(_comm, _prop, _win.getShell, _summ);
		if (IDialogConstants.OK_ID == dlg.open) {
			_areas.refresh;
			_comm.refUseCount.call;
			if (oldName != _summ.scenarioName) _comm.refScenarioName.call;
			if (oldType != _summ.type) {_comm.refSkin.call;}
		}
	}

	string title() {
		auto shl = cast(Shell) _win;
		if (shl) {
			return _prop.msgs.dataWindowName(_summ);
		}
		return _prop.msgs.dataTabName(_summ);
	}
	private void __refreshTitle() {
		_comm.setTitle(_win, title);
	}
	private void refresh() {
		__refreshTitle;
		_flags.setFlagDirTree(_summ.flagDirRoot, _summ.useCounter);
		_areas.summary = _summ;
		tabf.setSelection = tabA;
	}
	void create(string path, string name, string type) {
		scope mFPath = std.path.join(path, findSkin2(_prop, type).materialPath);
		if (!exists(mFPath) || !isdir(mFPath)) mkdir(mFPath);
		_summ = new Summary(name, type, path, false);
		_summ.author = _prop.var.etc.defaultAuthor;
		refresh;
	}

	/// 指定されたディレクトリにあるSummary.xmlからシナリオをロードする。
	/// Throws:
	/// SummaryException = ファイルはSummary定義のXML文書ではない。
	/// IOException = ファイル読込み例外発生時。
	/// XmlException = XMLパースエラー発生時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	/// FileLoadException = Summary.xml以外での読込例外発生時。
	void load(Summary summ) {
		_summ = summ;
		if (_win && !_win.isDisposed) refresh;
	}

	/// Returns: 貼り紙。
	Summary summary() {
		return _summ;
	}
	/// Returns: 編集中のシナリオのディレクトリ。
	string scenarioPath() {
		return _summ.scenarioPath;
	}

	override {
		void cut() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.cut;
				}
			}
		}
		void copy() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.copy;
				}
			}
		}
		void paste() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.paste;
				}
			}
		}
		void del() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.del;
				}
			}
		}
		bool canDoTCPD() {
			return .hasFocus(_win);
		}
	}

	private bool openCWXPathAf(Window)(Window w, string path) {
		if (w) {
			tabf.setSelection = tabA;
			return w.openCWXPath(cpbottom(path));
		}
		return false;
	}
	bool openCWXPath(string path) {
		if (path == "") {
			_comm.openDataWin;
			return true;
		}
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		switch (cate) {
		case "area": {
			if (index >= _summ.areas.length) return false;
			return openCWXPathAf(_comm.openArea(_prop, _summ, _summ.areas[index]), path);
		} break;
		case "area:id": {
			return openCWXPathAf(_comm.openArea(_prop, _summ, _summ.area(index)), path);
		} break;
		case "battle": {
			if (index >= _summ.battles.length) return false;
			return openCWXPathAf(_comm.openArea(_prop, _summ, _summ.battles[index]), path);
		} break;
		case "battle:id": {
			return openCWXPathAf(_comm.openArea(_prop, _summ, _summ.battle(index)), path);
		} break;
		case "package": {
			if (index >= _summ.packages.length) return false;
			return openCWXPathAf(_comm.openArea(_prop, _summ, _summ.packages[index]), path);
		} break;
		case "package:id": {
			return openCWXPathAf(_comm.openArea(_prop, _summ, _summ.packages(index)), path);
		} break;
		case "variable": {
			return _flags.openCWXPath(cpbottom(path));
		} break;
		default: break;
		}
		return false;
	}
}
