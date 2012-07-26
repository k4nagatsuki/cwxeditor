
module cwx.editor.gui.dwt.datawindow;

import cwx.summary;
import cwx.event;
import cwx.flag;
import cwx.utils;
import cwx.usecounter;
import cwx.skin;
import cwx.path;
import cwx.types;
import cwx.menu;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.areatable;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.flagspane;
import cwx.editor.gui.dwt.summarydialog;
import cwx.editor.gui.dwt.sbshell;
import cwx.editor.gui.dwt.dmenu;

import std.file;
import std.path;

import org.eclipse.swt.all;

class AbstractDataWindow(bool UseArea, bool UseFlag) : TopLevelPanel, SashPanel, TCPD {
private:
	Shell _parentShell;
	Commons _comm;
	SBShell _sbshl;
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

	static if (UseArea && UseFlag) {
		void selectedImpl() {
			if (tabf.getSelection() is tabA) {
				_comm.setStatusLine(tabf, _areas.statusLine);
			} else {
				assert (tabf.getSelection() is tabF);
				_comm.setStatusLine(tabf, _flags.statusLine);
			}
			_comm.refreshToolBar();
		}
		class SListener : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) {
				selectedImpl();
			}
		}
	}
public:
	this (Commons comm, Props prop, Shell parentShell, Composite parent) {
		_parentShell = parentShell;
		_prop = prop;
		_comm = comm;
		static if (UseArea) {
			_areas = new AreaTable(_comm, _prop);
		}
		static if (UseFlag) {
			_flags = new FlagsPane(_comm, _prop);
			_flags.setupTLP(this);
		}
		if (parent) construct(parent);
	}
	void reconstruct(Composite parent) {
		if (_win && !_win.isDisposed()) return;
		construct(parent);
		if (_summ) refresh();
	}
	private void construct(Composite parent) {
		Shell shell = null;
		auto parShl = cast(Shell) parent;
		Composite contPane;
		if (parShl) {
			_sbshl = new SBShell(parShl, SWT.SHELL_TRIM);
			shell = _sbshl.shell;
			shell.setImage(_prop.images.app);
			shell.addShellListener(new class ShellAdapter {
				public override void shellClosed(ShellEvent e) {
					(cast(Shell) e.widget).setVisible(false);
					e.doit = false;
					static if (UseArea && UseFlag) {
						_prop.var.dataWin.visible = false;
					}
				}
			});
			_win = shell;
			contPane = _sbshl.contentPane;
		} else {
			_win = new Composite(parent, SWT.NONE);
			contPane = _win;
		}
		_win.setData(new TLPData(this));
		contPane.setLayout(windowGridLayout(1, true));

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
				auto bar = new Menu(shell, SWT.BAR);

				auto mf = createMenu(_comm, bar, MenuID.File);
				createMenuItem(_comm, mf, MenuID.CloseWin, &shell.close, null);

				auto me = createMenu(_comm, bar, MenuID.Edit);
				static if (UseArea) {
					createMenuItem(_comm, me, MenuID.EditScene, &openAreaScene, &_areas.canOpenAreaScene);
					createMenuItem(_comm, me, MenuID.EditEvent, &openAreaEvent, &_areas.canOpenAreaEvent);
					new MenuItem(me, SWT.SEPARATOR);
				}
				createMenuItem(_comm, me, MenuID.Undo, &undo, &canUndo);
				createMenuItem(_comm, me, MenuID.Redo, &redo, &canRedo);
				new MenuItem(me, SWT.SEPARATOR);
				appendMenuTCPD(_comm, me, this, true, true, true, true);
				new MenuItem(me, SWT.SEPARATOR);
				createMenuItem(_comm, me, MenuID.Up, &up, &canUp);
				createMenuItem(_comm, me, MenuID.Down, &down, &canDown);

				static if (UseFlag) {
					auto mi = createMenu(_comm, bar, MenuID.View);
					createMenuItem(_comm, mi, MenuID.ChangeVH, &changeVHSide, null);
				}

				static if (UseArea) {
					auto mt = createMenu(_comm, bar, MenuID.Table);
					static if (UseFlag) {
						createMenuItem(_comm, mt, MenuID.EditSummary, &editSummary, &canEditSummary);
						new MenuItem(mt, SWT.SEPARATOR);
					}
					createMenuItem(_comm, mt, MenuID.NewArea, &createArea, &canCreateArea);
					createMenuItem(_comm, mt, MenuID.NewBattle, &createBattle, &canCreateBattle);
					createMenuItem(_comm, mt, MenuID.NewPackage, &createPackage, &canCreatePackage);
				}
				static if (UseFlag) {
					auto mv = createMenu(_comm, bar, MenuID.Variable);
					createMenuItem(_comm, mv, MenuID.NewFlagDir, &createFlagDir, &canCreateFlagDir);
					new MenuItem(mv, SWT.SEPARATOR);
					createMenuItem(_comm, mv, MenuID.NewFlag, &createFlag, &canCreateFlag);
					createMenuItem(_comm, mv, MenuID.NewStep, &createStep, &canCreateStep);
				}
				shell.setMenuBar(bar);
			}
			{
				auto bar = new ToolBar(contPane, SWT.FLAT);
				_comm.put(bar);
				bar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

				static if (UseArea && UseFlag) {
					createToolItem(_comm, bar, MenuID.EditSummary, &editSummary, &canEditSummary);
				}
				createToolItem(_comm, bar, MenuID.Up, &up, &canUp);
				createToolItem(_comm, bar, MenuID.Down, &down, &canDown);
				static if (UseArea) {
					new ToolItem(bar, SWT.SEPARATOR);
					createToolItem(_comm, bar, MenuID.NewArea, &createArea, &canCreateArea);
					createToolItem(_comm, bar, MenuID.NewBattle, &createBattle, &canCreateBattle);
					createToolItem(_comm, bar, MenuID.NewPackage, &createPackage, &canCreatePackage);
				}
				static if (UseFlag) {
					new ToolItem(bar, SWT.SEPARATOR);
					createToolItem(_comm, bar, MenuID.NewFlag, &createFlag, &canCreateFlag);
					createToolItem(_comm, bar, MenuID.NewStep, &createStep, &canCreateStep);
					createToolItem(_comm, bar, MenuID.NewFlagDir, &createFlagDir, &canCreateFlagDir);
					new ToolItem(bar, SWT.SEPARATOR);
					createToolItem(_comm, bar, MenuID.ChangeVH, &changeVHSide, null);
				}
			}
		} else {
			appendMenuTCPD(_comm, this, this, true, true, true, true);
			static if (UseArea && UseFlag) {
				putMenuAction(MenuID.EditSummary, &editSummary, &canEditSummary);
			}
			static if (UseArea) {
				putMenuAction(MenuID.EditScene, &openAreaScene, &_areas.canOpenAreaScene);
				putMenuAction(MenuID.EditEvent, &openAreaEvent, &_areas.canOpenAreaEvent);
				putMenuAction(MenuID.NewArea, &createArea, &canCreateArea);
				putMenuAction(MenuID.NewBattle, &createBattle, &canCreateBattle);
				putMenuAction(MenuID.NewPackage, &createPackage, &canCreatePackage);
			}
			static if (UseFlag) {
				putMenuAction(MenuID.NewFlagDir, &createFlagDir, &canCreateFlagDir);
				putMenuAction(MenuID.NewFlag, &createFlag, &canCreateFlag);
				putMenuAction(MenuID.NewStep, &createStep, &canCreateStep);
			}
			putMenuAction(MenuID.Undo, &undo, &canUndo);
			putMenuAction(MenuID.Redo, &redo, &canRedo);
			putMenuAction(MenuID.Up, &up, &canUp);
			putMenuAction(MenuID.Down, &down, &canDown);
		}
		{
			static if (UseArea && UseFlag) {
				tabf = new CTabFolder(contPane, SWT.BORDER);
				tabf.setLayoutData(new GridData(GridData.FILL_BOTH));
				tabf.addSelectionListener(new SListener);

				_flags.construct(tabf);
				_areas.construct(tabf, _flags.flags);

				tabA = new CTabItem(tabf, SWT.NONE);
				tabA.setText(_prop.msgs.scenarioView);
				tabA.setControl(_areas.table);
				tabF = new CTabItem(tabf, SWT.NONE);
				tabF.setText(_prop.msgs.variableView);
				tabF.setControl(_flags.widget);

				_tcpd ~= _areas;
				_tcpd ~= _flags.flags;
				_tcpd ~= _flags.dirs;
			} else static if (UseArea) {
				_areas.construct(contPane, null);
				_areas.table.setLayoutData(new GridData(GridData.FILL_BOTH));
				_tcpd ~= _areas;
			} else static if (UseFlag) {
				_flags.construct(contPane);
				_flags.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
				_tcpd ~= _flags.flags;
				_tcpd ~= _flags.dirs;
			} else static assert (0);
		}
		static if (UseArea && UseFlag) {
			if (shell) {
				shell.setMaximized(_prop.var.dataWin.maximized);
				shell.setMinimized(_prop.var.dataWin.minimized);
				scope wp = shell.computeSize(SWT.DEFAULT, SWT.DEFAULT);
				int width = _prop.var.dataWin.width == SWT.DEFAULT ? wp.x : _prop.var.dataWin.width;
				int height = _prop.var.dataWin.height == SWT.DEFAULT ? wp.y : _prop.var.dataWin.height;
				int x = _prop.var.dataWin.x == SWT.DEFAULT ? shell.getBounds().x : _prop.var.dataWin.x + shell.getParent().getBounds().x;
				int y = _prop.var.dataWin.y == SWT.DEFAULT ? shell.getBounds().y : _prop.var.dataWin.y + shell.getParent().getBounds().y;
				intoDisplay(x, y, width, height);
				shell.setBounds(x, y, width, height);
				shell.addControlListener(new class ControlAdapter {
					override void controlMoved(ControlEvent e) {
						saveDataWin();
					}
					override void controlResized(ControlEvent e) {
						saveDataWin();
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
				if (!win.getMaximized() && !win.getMinimized()) {
					_prop.var.dataWin.width = win.getSize().x;
					_prop.var.dataWin.height = win.getSize().y;
					_prop.var.dataWin.x = win.getBounds().x - win.getParent().getBounds().x;
					_prop.var.dataWin.y = win.getBounds().y - win.getParent().getBounds().y;
				}
				_prop.var.dataWin.maximized = win.getMaximized();
				_prop.var.dataWin.minimized = win.getMinimized();
			}
		}
	}
	@property
	Composite shell() {return _win;}

	static if (UseArea) {
		@property
		bool canEditSummary() {
			return _summ !is null;
		}
		@property
		bool canCreateArea() {
			return _summ !is null;
		}
		@property
		alias canCreateArea canCreateBattle;
		@property
		alias canCreateArea canCreatePackage;
		void editSummary() {
			if (!_summ) return;
			if (_win && !_win.isDisposed()) {
				_areas.editSummary(_win.getShell());
			} else {
				_areas.editSummary(_parentShell);
			}
		}

		private void openAreaScene() {
			_areas.openAreaScene(true);
		}
		private void openAreaEvent() {
			_areas.openAreaEvent(true);
		}

		/// エリアビューを開く。
		void openAreaScene(ulong id, bool shellActivate) {
			_areas.openAreaScene(id, shellActivate);
		}
		/// ditto
		void openAreaEvent(ulong id, bool shellActivate) {
			_areas.openAreaEvent(id, shellActivate);
		}
		/// ditto
		void openBattleScene(ulong id, bool shellActivate) {
			_areas.openBattleScene(id, shellActivate);
		}
		/// ditto
		void openBattleEvent(ulong id, bool shellActivate) {
			_areas.openBattleEvent(id, shellActivate);
		}
		/// ditto
		void openPackage(ulong id, bool shellActivate) {
			_areas.openPackage(id, shellActivate);
		}
		void createArea() {
			if (!_summ) return;
			_comm.openDataWin(false);
			.forceFocus(_areas.table, false);
			_areas.createArea();
		}
		void createBattle() {
			if (!_summ) return;
			_comm.openDataWin(false);
			.forceFocus(_areas.table, false);
			_areas.createBattle();
		}
		void createPackage() {
			createPackage(null);
		}
		ulong createPackage(Content baseStart) {
			if (!_summ) return 0;
			_comm.openDataWin(false);
			.forceFocus(_areas.table, false);
			return _areas.createPackage(baseStart);
		}
		void reNumberingAll() {
			_areas.reNumberingAll();
		}
	}
	static if (UseFlag) {
		@property
		bool canCreateFlagDir() {
			return _summ !is null;
		}
		@property
		alias canCreateFlagDir canCreateFlag;
		@property
		alias canCreateFlagDir canCreateStep;

		void createFlagDir() {
			if (!_summ) return;
			_flags.dirs.createDir();
		}
		void createFlag() {
			if (!_summ) return;
			_flags.flags.createFlag();
		}
		void createStep() {
			if (!_summ) return;
			_flags.flags.createStep();
		}
		private void changeVHSide() {
			.forceFocus(_flags.widget, false);
			_flags.changeVHSide();
		}
	}
	static if (UseArea && UseFlag) {
		void selectData() {
			tabf.setSelection(tabA);
			selectedImpl();
		}
		void selectFlags() {
			tabf.setSelection(tabF);
			selectedImpl();
		}
	}

	@property
	Image image() {
		static if (UseArea && UseFlag) {
			return _prop.images.menu(MenuID.TableView);
		} else static if (UseArea) {
			return _prop.images.menu(MenuID.TableView);
		} else static if (UseFlag) {
			return _prop.images.menu(MenuID.VarView);
		} else static assert (0);
	}
	@property
	string title() {
		auto shl = cast(Shell) _win;
		static if (UseArea && UseFlag) {
			if (shl && _summ) {
				return .tryFormat(_prop.msgs.dataWindowName, _summ.scenarioName, _summ.scenarioPath);
			}
			return _prop.msgs.dataTabName;
		} else static if (UseArea) {
			if (shl && _summ) {
				return .tryFormat(_prop.msgs.areasWindowName, _summ.scenarioName, _summ.scenarioPath);
			}
			return _prop.msgs.areasTabName;
		} else static if (UseFlag) {
			if (shl && _summ) {
				return .tryFormat(_prop.msgs.flagWindowName, _summ.scenarioName, _summ.scenarioPath);
			}
			return _prop.msgs.flagTabName;
		} else static assert (0);
	}
	@property
	void delegate(string) statusText() {return _sbshl ? &_sbshl.statusLine : null;}

	private void __refreshTitle() {
		if (!_win || _win.isDisposed()) return;
		_comm.setTitle(_win, title);
	}
	private void refresh() {
		__refreshTitle();
		static if (UseArea) {
			_areas.summary = _summ;
			static if (UseFlag) {
				if (_win && !_win.isDisposed()) {
					tabf.setSelection(tabA);
				}
			}
		}
		static if (UseFlag) {
			_flags.setFlagDirTree(_summ.flagDirRoot, _summ.useCounter);
		}
	}

	@property
	bool canUp() {
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) {
				return _areas.canUp();
			} else {
				assert (tabf.getSelection() is tabF);
				return _flags.canUp();
			}
		} else static if (UseArea) {
			return _areas.canUp();
		} else static if (UseFlag) {
			return _flags.canUp();
		} else static assert (0);
	}
	@property
	bool canDown() {
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) {
				return _areas.canDown();
			} else {
				assert (tabf.getSelection() is tabF);
				return _flags.canDown();
			}
		} else static if (UseArea) {
			return _areas.canDown();
		} else static if (UseFlag) {
			return _flags.canDown();
		} else static assert (0);
	}
	void up() {
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) {
				_areas.up();
			} else {
				assert (tabf.getSelection() is tabF);
				_flags.up();
			}
		} else static if (UseArea) {
			_areas.up();
		} else static if (UseFlag) {
			_flags.up();
		} else static assert (0);
	}
	void down() {
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) {
				_areas.down();
			} else {
				assert (tabf.getSelection() is tabF);
				_flags.down();
			}
		} else static if (UseArea) {
			_areas.down();
		} else static if (UseFlag) {
			_flags.down();
		} else static assert (0);
	}

	/// 指定されたディレクトリにあるSummary.xmlからシナリオをロードする。
	/// Throws:
	/// SummaryException = ファイルはSummary定義のXML文書ではない。
	/// FileException = ファイル読込み例外発生時。
	/// XmlException = XMLパースエラー発生時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	/// FileLoadException = Summary.xml以外での読込例外発生時。
	void load(Summary summ) {
		_summ = summ;
		refresh();
	}

	/// Returns: 貼り紙。
	@property
	Summary summary() {
		return _summ;
	}

	override {
		void cut(SelectionEvent se) {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.cut(se);
				}
			}
		}
		void copy(SelectionEvent se) {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.copy(se);
				}
			}
		}
		void paste(SelectionEvent se) {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.paste(se);
				}
			}
		}
		void del(SelectionEvent se) {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.del(se);
				}
			}
		}
		bool canDoTCPD() {
			return .hasFocus(_win);
		}
		@property
		bool canDoT() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) return c.canDoT;
			}
			return false;
		}
		@property
		bool canDoC() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) return c.canDoC;
			}
			return false;
		}
		@property
		bool canDoP() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) return c.canDoP;
			}
			return false;
		}
		@property
		bool canDoD() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) return c.canDoD;
			}
			return false;
		}
	}

	private bool openCWXPathAfCommon(A)(A a, ref string path, bool shellActivate) {
		path = cpbottom(path);
		if (cpattr(path).contains("shallow") && cpempty(path)) {
			.forceFocus(_areas.table, shellActivate);
			_areas.select(a);
			_comm.refreshToolBar();
			return true;
		}
		return false;
	}
	private bool openCWXPathAf(BindWindow, SceneWindow, EventWindow, A)(lazy BindWindow bw, lazy SceneWindow sw, lazy EventWindow ew, A a, string path, bool shellActivate) {
		if (openCWXPathAfCommon(a, path, shellActivate)) {
			return true;
		}
		string cate = cpcategory(path);
		bool isScene = cpempty(path)
			|| ((cate == "menucard" || cate == "enemycard") && cpempty(cpbottom(path)))
			|| cate == "background";
		if (isScene && cphasattr(path, "eventview")) {
			isScene = false;
		}
		string aPath = a.cwxPath(true);
		if (isScene) {
			auto sw2 = _comm.areaWindowFrom(aPath, shellActivate);
			if (sw2) {
				return sw2.openCWXPath(path, shellActivate);
			}
			if (!_comm.singleWindowMode(_prop) || _prop.var.etc.bindSceneWithEvent) {
				return bw.openCWXPath(path, shellActivate);
			} else {
				return sw.openCWXPath(path, shellActivate);
			}
		} else {
			auto ew2 = _comm.eventWindowFrom(aPath, shellActivate);
			if (ew2) {
				return ew2.openCWXPath(path, shellActivate);
			}
			if (!_comm.singleWindowMode(_prop) || _prop.var.etc.bindSceneWithEvent) {
				return bw.openCWXPath(path, shellActivate);
			} else {
				return ew.openCWXPath(path, shellActivate);
			}
		}
	}
	private bool openCWXPathAf(Window, A)(lazy Window w, A a, string path, bool shellActivate) {
		if (openCWXPathAfCommon(a, path, shellActivate)) {
			return true;
		}
		if (w) {
			static if (UseArea && UseFlag) {
				tabf.setSelection(tabA);
				_comm.refreshToolBar();
			}
			return w.openCWXPath(path, shellActivate);
		}
		return false;
	}
	bool openCWXPath(string path, bool shellActivate) {
		if (cpempty(path)) {
			static if (UseArea) {
				_comm.openDataWin(shellActivate);
				if (cphasattr(path, "opendialog")) {
					editSummary();
				}
			} else {
				_comm.openFlagWin(shellActivate);
			}
			return true;
		}
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		switch (cate) {
		case "area": {
			static if (UseArea) {
				if (index >= _summ.areas.length) return false;
				auto a = _summ.areas[index];
				return openCWXPathAf(_comm.openArea(_prop, _summ, a, shellActivate),
					_comm.openAreaScene(_prop, _summ, a, shellActivate),
					_comm.openAreaEvent(_prop, _summ, a, shellActivate),
					a, path, shellActivate);
			}
		} break;
		case "area:id": {
			static if (UseArea) {
				auto a = _summ.area(index);
				return openCWXPathAf(_comm.openArea(_prop, _summ, a, shellActivate),
					_comm.openAreaScene(_prop, _summ, a, shellActivate),
					_comm.openAreaEvent(_prop, _summ, a, shellActivate),
					a, path, shellActivate);
			}
		} break;
		case "battle": {
			static if (UseArea) {
				if (index >= _summ.battles.length) return false;
				auto a = _summ.battles[index];
				return openCWXPathAf(_comm.openArea(_prop, _summ, a, shellActivate),
					_comm.openAreaScene(_prop, _summ, a, shellActivate),
					_comm.openAreaEvent(_prop, _summ, a, shellActivate),
					a, path, shellActivate);
			}
		} break;
		case "battle:id": {
			static if (UseArea) {
				auto a = _summ.battle(index);
				return openCWXPathAf(_comm.openArea(_prop, _summ, a, shellActivate),
					_comm.openAreaScene(_prop, _summ, a, shellActivate),
					_comm.openAreaEvent(_prop, _summ, a, shellActivate),
					a, path, shellActivate);
			}
		} break;
		case "package": {
			static if (UseArea) {
				if (index >= _summ.packages.length) return false;
				auto a = _summ.packages[index];
				return openCWXPathAf(_comm.openArea(_prop, _summ, a, shellActivate),
					a, path, shellActivate);
			}
		} break;
		case "package:id": {
			static if (UseArea) {
				auto a = _summ.cwPackage(index);
				return openCWXPathAf(_comm.openArea(_prop, _summ, a, shellActivate),
					a, path, shellActivate);
			}
		} break;
		case "tableview": {
			static if (UseArea) {
				.forceFocus(_areas.table, shellActivate);
				return true;
			}
		} break;
		case "variable": {
			static if (UseFlag) {
				return _flags.openCWXPath(cpbottom(path), shellActivate);
			}
		} break;
		case "variableview": {
			static if (UseFlag) {
				.forceFocus(_flags.flags.widget, shellActivate);
				return true;
			}
		} break;
		default: break;
		}
		return false;
	}
	@property
	string[] openedCWXPath() {
		string[] r;
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) {
				auto a = _areas.openedCWXPath;
				auto b = _flags.openedCWXPath;
				if (!a.length) r ~= "tableview";
				if (!b.length) r ~= "variableview";
				r ~= a ~ b;
			} else {
				auto a = _flags.openedCWXPath;
				auto b = _areas.openedCWXPath;
				if (!a.length) r ~= "variableview";
				if (!b.length) r ~= "tableview";
				r ~= a ~ b;
			}
		} else static if (UseArea) {
			r ~= _areas.openedCWXPath;
			if (!r.length) r ~= "tableview";
		} else static if (UseFlag) {
			r ~= _flags.openedCWXPath;
			if (!r.length) r ~= "variableview";
		} else static assert (0);
		return r;
	}

	@property
	bool canUndo() {
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) {
				return _areas.canUndo();
			} else {
				assert (tabf.getSelection() is tabF);
				return _flags.canUndo();
			}
		} else static if (UseArea) {
			return _areas.canUndo();
		} else static if (UseFlag) {
			return _flags.canUndo();
		} else static assert (0);
	}
	@property
	bool canRedo() {
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) {
				return _areas.canRedo();
			} else {
				assert (tabf.getSelection() is tabF);
				return _flags.canRedo();
			}
		} else static if (UseArea) {
			return _areas.canRedo();
		} else static if (UseFlag) {
			return _flags.canRedo();
		} else static assert (0);
	}
	void undo() {
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) {
				_areas.undo();
			} else {
				assert (tabf.getSelection() is tabF);
				_flags.undo();
			}
		} else static if (UseArea) {
			_areas.undo();
		} else static if (UseFlag) {
			_flags.undo();
		} else static assert (0);
	}
	void redo() {
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) {
				_areas.redo();
			} else {
				assert (tabf.getSelection() is tabF);
				_flags.redo();
			}
		} else static if (UseArea) {
			_areas.redo();
		} else static if (UseFlag) {
			_flags.redo();
		} else static assert (0);
	}
}

alias AbstractDataWindow!(true, true) DataWindow;
alias AbstractDataWindow!(true, false) TableWindow;
alias AbstractDataWindow!(false, true) FlagWindow;
