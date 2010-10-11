
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
import dwt.widgets.Shell;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.custom.CTabFolder;
import dwt.custom.CTabItem;
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

class AbstractDataWindow(bool UseArea, bool UseFlag) : TopLevelPanel, TCPD {
private:
	Commons _comm;
	Composite _win;
	static if (UseArea) {
		AreaTable _areas;
	}
	static if (UseFlag) {
		FlagsPane _flags;
	}
	Props _prop;
	static if (UseArea && UseFlag) {
		CTabFolder tabf;
		CTabItem tabA;
		CTabItem tabF;
	}

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
					static if (UseArea && UseFlag) {
						_prop.var.dataWin.visible = false;
					}
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

				static if (UseFlag) {
					auto mi = createMenu(bar, _prop.msgs.menuView);
					createMenuItem(mi, _prop.msgs.menuChangeVH, _prop.images.menuChangeVH, &changeVHSide);
				}

				static if (UseArea) {
					auto mt = createMenu(bar, _prop.msgs.menuTable);
					static if (UseFlag) {
						createMenuItem(mt, _prop.msgs.menuSummary, _prop.images.menuSummary, &editSummary);
						new MenuItem(mt, DWT.SEPARATOR);
					}
					createMenuItem(mt, _prop.msgs.menuNewArea, _prop.images.menuNewArea, &createArea);
					createMenuItem(mt, _prop.msgs.menuNewBattle, _prop.images.menuNewBattle, &createBattle);
					createMenuItem(mt, _prop.msgs.menuNewPackage, _prop.images.menuNewPackage, &createPackage);
				}
				static if (UseFlag) {
					auto mv = createMenu(bar, _prop.msgs.menuVariable);
					createMenuItem(mv, _prop.msgs.menuNewFlagDir, _prop.images.menuNewFlagDir, &createFlagDir);
					new MenuItem(mv, DWT.SEPARATOR);
					createMenuItem(mv, _prop.msgs.menuNewFlag, _prop.images.menuNewFlag, &createFlag);
					createMenuItem(mv, _prop.msgs.menuNewStep, _prop.images.menuNewStep, &createStep);
				}
				shell.setMenuBar = bar;
			}
			{
				auto bar = new ToolBar(shell, DWT.FLAT);
				bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);

				static if (UseArea && UseFlag) {
					createToolItem(bar, _prop.msgs.ttSummary, _prop.images.menuSummary, &editSummary);
				}
				static if (UseArea) {
					new ToolItem(bar, DWT.SEPARATOR);
					createToolItem(bar, _prop.msgs.ttNewArea, _prop.images.menuNewArea, &createArea);
					createToolItem(bar, _prop.msgs.ttNewBattle, _prop.images.menuNewBattle, &createBattle);
					createToolItem(bar, _prop.msgs.ttNewPackage, _prop.images.menuNewPackage, &createPackage);
				}
				static if (UseFlag) {
					new ToolItem(bar, DWT.SEPARATOR);
					createToolItem(bar, _prop.msgs.ttNewFlag, _prop.images.menuNewFlag, &createFlag);
					createToolItem(bar, _prop.msgs.ttNewStep, _prop.images.menuNewStep, &createStep);
					createToolItem(bar, _prop.msgs.ttNewFlagDir, _prop.images.menuNewFlagDir, &createFlagDir);
					new ToolItem(bar, DWT.SEPARATOR);
					createToolItem(bar, _prop.msgs.ttChangeVH, _prop.images.menuChangeVH, &changeVHSide);
				}
			}
		} else {
			appendMenuTCPD(_prop, this, this);
			static if (UseArea && UseFlag) {
				putMenuAction(MenuID.Summary, &editSummary);
			}
			static if (UseArea) {
				putMenuAction(MenuID.NewArea, &createArea);
				putMenuAction(MenuID.NewBattle, &createBattle);
				putMenuAction(MenuID.NewPackage, &createPackage);
			}
			static if (UseFlag) {
				putMenuAction(MenuID.NewFlagDir, &createFlagDir);
				putMenuAction(MenuID.NewFlag, &createFlag);
				putMenuAction(MenuID.NewStep, &createStep);
			}
		}
		{
			static if (UseArea && UseFlag) {
				tabf = new CTabFolder(_win, DWT.BORDER);
				tabf.setLayoutData = new GridData(GridData.FILL_BOTH);

				_flags = new FlagsPane(_comm, _prop, tabf);
				_flags.setupTLP(this);
				_areas = new AreaTable(_comm, _prop, tabf, _flags.flags);

				tabA = new CTabItem(tabf, DWT.NONE);
				tabA.setText = _prop.msgs.scenarioView;
				tabA.setControl(_areas.table);
				tabF = new CTabItem(tabf, DWT.NONE);
				tabF.setText = _prop.msgs.variableView;
				tabF.setControl(_flags.widget);

				_tcpd ~= _areas;
				_tcpd ~= _flags.flags;
				_tcpd ~= _flags.dirs;
			} else static if (UseArea) {
				_areas = new AreaTable(_comm, _prop, _win, null);
				_areas.table.setLayoutData = new GridData(GridData.FILL_BOTH);
				_tcpd ~= _areas;
			} else static if (UseFlag) {
				_flags = new FlagsPane(_comm, _prop, _win);
				_flags.setupTLP(this);
				_flags.widget.setLayoutData = new GridData(GridData.FILL_BOTH);
				_tcpd ~= _flags.flags;
				_tcpd ~= _flags.dirs;
			} else static assert (0);
		}
		static if (UseArea && UseFlag) {
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
		}
		_comm.refScenarioName.add(&__refreshTitle);
		_win.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.refScenarioName.remove(&__refreshTitle);
			}
		});
	}
	static if (UseArea && UseFlag) {
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
	}
	Composite shell() {return _win;}

	static if (UseArea) {
		void editSummary() {
			if (!_summ) return;
			_areas.editSummary;
		}
		void create(string path, string name, string type) {
			scope mFPath = std.path.join(path, findSkin2(_prop, type).materialPath);
			if (!exists(mFPath) || !isdir(mFPath)) mkdir(mFPath);
			_summ = new Summary(name, type, path, false);
			_summ.author = _prop.var.etc.defaultAuthor;
			refresh;
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
		void createArea() {
			if (!_summ) return;
			_comm.openDataWin;
			.forceFocus(_areas.table);
			_areas.createArea;
		}
		void createBattle() {
			if (!_summ) return;
			_comm.openDataWin;
			.forceFocus(_areas.table);
			_areas.createBattle;
		}
		void createPackage() {
			createPackage(null);
		}
		ulong createPackage(Content baseStart) {
			if (!_summ) return 0;
			_comm.openDataWin;
			.forceFocus(_areas.table);
			return _areas.createPackage(baseStart);
		}
	}
	static if (UseFlag) {
		void createFlagDir() {
			if (!_summ) return;
			static if (UseArea) {
				_comm.openDataWin;
			} else {
				_comm.openFlagWin;
			}
			.forceFocus(_flags.dirs.widget);
			_flags.dirs.createDir;
		}
		void createFlag() {
			if (!_summ) return;
			static if (UseArea) {
				_comm.openDataWin;
			} else {
				_comm.openFlagWin;
			}
			.forceFocus(_flags.flags.widget);
			_flags.flags.createFlag;
		}
		void createStep() {
			if (!_summ) return;
			static if (UseArea) {
				_comm.openDataWin;
			} else {
				_comm.openFlagWin;
			}
			.forceFocus(_flags.flags.widget);
			_flags.flags.createStep;
		}
		private void changeVHSide() {
			.forceFocus(_flags.widget);
			_flags.changeVHSide;
		}
	}

	Image image() {
		static if (UseArea && UseFlag) {
			return _prop.images.menuDataWin;
		} else static if (UseArea) {
			return _prop.images.menuDataWin;
		} else static if (UseFlag) {
			return _prop.images.menuFlagWin;
		} else static assert (0);
	}
	string title() {
		auto shl = cast(Shell) _win;
		static if (UseArea && UseFlag) {
			if (shl) {
				return _prop.msgs.dataWindowName(_summ);
			}
			return _prop.msgs.dataTabName(_summ);
		} else static if (UseArea) {
			if (shl) {
				return _prop.msgs.areasWindowName(_summ);
			}
			return _prop.msgs.areasTabName(_summ);
		} else static if (UseFlag) {
			if (shl) {
				return _prop.msgs.flagWindowName(_summ);
			}
			return _prop.msgs.flagTabName(_summ);
		} else static assert (0);
	}
	private void __refreshTitle() {
		_comm.setTitle(_win, title);
	}
	private void refresh() {
		__refreshTitle;
		static if (UseFlag) {
			_flags.setFlagDirTree(_summ.flagDirRoot, _summ.useCounter);
		}
		static if (UseArea) {
			_areas.summary = _summ;
			static if (UseFlag) {
				tabf.setSelection = tabA;
			}
		}
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
			static if (UseArea && UseFlag) {
				tabf.setSelection = tabA;
			}
			return w.openCWXPath(cpbottom(path));
		}
		return false;
	}
	bool openCWXPath(string path) {
		if (path == "") {
			static if (UseArea) {
				_comm.openDataWin;
			} else {
				_comm.openFlagWin;
			}
			return true;
		}
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		switch (cate) {
		case "area": {
			static if (UseArea) {
				if (index >= _summ.areas.length) return false;
				return openCWXPathAf(_comm.openArea(_prop, _summ, _summ.areas[index]), path);
			}
		} break;
		case "area:id": {
			static if (UseArea) {
				return openCWXPathAf(_comm.openArea(_prop, _summ, _summ.area(index)), path);
			}
		} break;
		case "battle": {
			static if (UseArea) {
				if (index >= _summ.battles.length) return false;
				return openCWXPathAf(_comm.openArea(_prop, _summ, _summ.battles[index]), path);
			}
		} break;
		case "battle:id": {
			static if (UseArea) {
				return openCWXPathAf(_comm.openArea(_prop, _summ, _summ.battle(index)), path);
			}
		} break;
		case "package": {
			static if (UseArea) {
				if (index >= _summ.packages.length) return false;
				return openCWXPathAf(_comm.openArea(_prop, _summ, _summ.packages[index]), path);
			}
		} break;
		case "package:id": {
			static if (UseArea) {
				return openCWXPathAf(_comm.openArea(_prop, _summ, _summ.packages(index)), path);
			}
		} break;
		case "variable": {
			static if (UseFlag) {
				return _flags.openCWXPath(cpbottom(path));
			}
		} break;
		default: break;
		}
		return false;
	}
}

alias AbstractDataWindow!(true, true) DataWindow;
alias AbstractDataWindow!(true, false) TableWindow;
alias AbstractDataWindow!(false, true) FlagWindow;
