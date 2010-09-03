
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
class DataWindow : TCPD {
private:
	Commons _comm;
	Shell _win;
	AreaTable _areas;
	FlagsPane _flags;
	Props _prop;
	TabFolder tabf;
	TabItem tabA;
	TabItem tabF;

	Summary _summ = null;

	TCPD[] _tcpd;

	void createFlagDir() {
		tabf.setSelection(tabF);
		_flags.dirs.setFocus;
		_flags.dirs.createDir;
	}
	void createFlag() {
		tabf.setSelection(tabF);
		_flags.flags.setFocus;
		_flags.flags.createFlag;
	}
	void createStep() {
		tabf.setSelection(tabF);
		_flags.flags.setFocus;
		_flags.flags.createStep;
	}
	void close() {
		_win.setVisible = false;
	}

	void editSummary() {
		string oldName = _summ.scenarioName;
		string oldType = _summ.type;
		auto dlg = new SummaryDialog(_comm, _prop, _win, _summ);
		if (IDialogConstants.OK_ID == dlg.open) {
			_areas.refresh;
			_comm.refUseCount.call;
			if (oldName != _summ.scenarioName) _comm.refScenarioName.call;
			if (oldType != _summ.type) {_comm.refSkin.call;}
		}
	}
	void createArea() {
		tabf.setSelection(tabA);
		_areas.setFocus;
		_areas.createArea;
	}
	void createBattle() {
		tabf.setSelection(tabA);
		_areas.setFocus;
		_areas.createBattle;
	}
	void createPackage() {
		tabf.setSelection(tabA);
		_areas.setFocus;
		_areas.createPackage;
	}

	void saveScenario() {
		_comm.save.call(_win);
	}
public:
	this(Commons comm, Props prop, Shell parent) {
		_win = new Shell(parent, DWT.SHELL_TRIM);
		_win.setImage = prop.images.app;
		_win.addShellListener(new class ShellAdapter {
			public override void shellClosed(ShellEvent e) {
				_win.setVisible = false;
				e.doit = false;
				_prop.var.dataWin.visible = false;
			}
		});
		_win.setLayout = windowGridLayout(1, true);
		_prop = prop;
		_comm = comm;

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
		{
			auto bar = new Menu(_win, DWT.BAR);

			auto mf = createMenu(bar, _prop.msgs.menuFile);
			createMenuItem(mf, _prop.msgs.menuSave, _prop.images.menuSave, &saveScenario);
			new MenuItem(mf, DWT.SEPARATOR);
			createMenuItem(mf, _prop.msgs.menuCloseWin, _prop.images.menuCloseWin, &close);

			auto me = createMenu(bar, _prop.msgs.menuEdit);
			appendMenuTCPD(_prop, me, this);

			auto mt = createMenu(bar, _prop.msgs.menuTable);
			createMenuItem(mt, _prop.msgs.menuNewArea, _prop.images.menuNewArea, &createArea);
			createMenuItem(mt, _prop.msgs.menuNewBattle, _prop.images.menuNewBattle, &createBattle);
			createMenuItem(mt, _prop.msgs.menuNewPackage, _prop.images.menuNewPackage, &createPackage);

			auto mv = createMenu(bar, _prop.msgs.menuVariable);
			createMenuItem(mv, _prop.msgs.menuNewDir, _prop.images.menuNewFlagDir, &createFlagDir);
			new MenuItem(mv, DWT.SEPARATOR);
			createMenuItem(mv, _prop.msgs.menuNewFlag, _prop.images.menuNewFlag, &createFlag);
			createMenuItem(mv, _prop.msgs.menuNewStep, _prop.images.menuNewStep, &createStep);

			_win.setMenuBar = bar;
		}
		{
			auto bar = new ToolBar(_win, DWT.FLAT);
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);

			createToolItem(bar, _prop.msgs.ttSummary, _prop.images.menuSummary, &editSummary);
			new ToolItem(bar, DWT.SEPARATOR);
			createToolItem(bar, _prop.msgs.ttNewArea, _prop.images.menuNewArea, &createArea);
			createToolItem(bar, _prop.msgs.ttNewBattle, _prop.images.menuNewBattle, &createBattle);
			createToolItem(bar, _prop.msgs.ttNewPackage, _prop.images.menuNewPackage, &createPackage);
			new ToolItem(bar, DWT.SEPARATOR);
			createToolItem(bar, _prop.msgs.ttNewFlag, _prop.images.menuNewFlag, &createFlag);
			createToolItem(bar, _prop.msgs.ttNewStep, _prop.images.menuNewStep, &createStep);
			createToolItem(bar, _prop.msgs.ttNewDir, _prop.images.menuNewFlagDir, &createFlagDir);
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
		scope wp = _win.computeSize(DWT.DEFAULT, DWT.DEFAULT);
		int width = _prop.var.dataWin.width == DWT.DEFAULT ? wp.x : _prop.var.dataWin.width;
		int height = _prop.var.dataWin.height == DWT.DEFAULT ? wp.y : _prop.var.dataWin.height;
		int x = _prop.var.dataWin.x == DWT.DEFAULT ? _win.getBounds.x : _prop.var.dataWin.x + _win.getParent.getBounds.x;
		int y = _prop.var.dataWin.y == DWT.DEFAULT ? _win.getBounds.y : _prop.var.dataWin.y + _win.getParent.getBounds.y;
		intoDisplay(x, y, width, height);
		_win.setBounds(x, y, width, height);
		_win.setMaximized = _prop.var.dataWin.maximized;
		_win.setMinimized = _prop.var.dataWin.minimized;
		_win.addControlListener(new class ControlAdapter {
			override void controlMoved(ControlEvent e) {
				saveDataWin;
			}
			override void controlResized(ControlEvent e) {
				saveDataWin;
			}
		});
		_comm.refScenarioName.add(&__refreshTitle);
		_win.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.refScenarioName.remove(&__refreshTitle);
			}
		});
	}
	private void saveDataWin() {
		auto win = _win;
		if (!win.getMaximized && !win.getMinimized) {
			_prop.var.dataWin.width = win.getSize.x;
			_prop.var.dataWin.height = win.getSize.y;
			_prop.var.dataWin.x = win.getBounds.x - win.getParent.getBounds.x;
			_prop.var.dataWin.y = win.getBounds.y - win.getParent.getBounds.y;
		}
		_prop.var.dataWin.maximized = win.getMaximized;
		_prop.var.dataWin.minimized = win.getMinimized;
	}
	Shell shell() {return _win;}
	/// ウィンドウを開く。
	void open() {
		if (_summ) {
			_win.setMinimized = false;
			_win.open;
		}
	}
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

	private void __refreshTitle() {
		_win.setText = _prop.msgs.dataWindowName(_summ.scenarioName, _summ.scenarioPath);
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
		refresh;
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
			return _win.isFocusControl;
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
			_win.setMinimized = false;
			_win.setActive;
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
