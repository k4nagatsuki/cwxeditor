
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
	Composite _win, _contPane;
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
		void selectedImpl() { mixin(S_TRACE);
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				_comm.setStatusLine(tabf, _areas.statusLine);
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				_comm.setStatusLine(tabf, _flags.statusLine);
			}
			_comm.refreshToolBar();
		}
		class SListener : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				selectedImpl();
			}
		}
	}
public:
	this (Commons comm, Props prop, Shell parentShell, Composite parent) { mixin(S_TRACE);
		_parentShell = parentShell;
		_prop = prop;
		_comm = comm;
		static if (UseArea) {
			_areas = new AreaTable(_comm, _prop, false, null);
		}
		static if (UseFlag) {
			_flags = new FlagsPane(_comm, _prop);
			_flags.setupTLP(this);
		}
		if (parent) construct(parent);
	}
	void reconstruct(Composite parent) { mixin(S_TRACE);
		if (_win && !_win.isDisposed()) return;
		construct(parent);
		if (_summ) refresh();
	}
	private void construct(Composite parent) { mixin(S_TRACE);
		Shell shell = null;
		auto parShl = cast(Shell) parent;
		Composite contPane;
		if (parShl) { mixin(S_TRACE);
			_sbshl = new SBShell(parShl, SWT.SHELL_TRIM);
			shell = _sbshl.shell;
			shell.setImages(_prop.images.icon);
			shell.addShellListener(new class ShellAdapter {
				public override void shellClosed(ShellEvent e) { mixin(S_TRACE);
					(cast(Shell) e.widget).setVisible(false);
					e.doit = false;
					static if (UseArea && UseFlag) {
						_prop.var.dataWin.visible = false;
					}
				}
			});
			_win = shell;
			contPane = _sbshl.contentPane;
		} else { mixin(S_TRACE);
			_win = new Composite(parent, SWT.NONE);
			contPane = _win;
		}
		_contPane = contPane;
		_win.setData(new TLPData(this));
		contPane.setLayout(windowGridLayout(1, true));

		static if (UseArea) {
			_comm.refTableViewStyle.add(&refTableViewStyle);
		}
		_comm.refScenarioName.add(&__refreshTitle);
		_comm.refScenarioPath.add(&__refreshTitle);
		_comm.replText.add(&__refreshTitle);
		_win.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				static if (UseArea) {
					_comm.refTableViewStyle.remove(&refTableViewStyle);
				}
				_comm.refScenarioName.remove(&__refreshTitle);
				_comm.refScenarioPath.remove(&__refreshTitle);
				_comm.replText.remove(&__refreshTitle);
			}
		});
		{ mixin(S_TRACE);
			static if (UseArea && UseFlag) {
				tabf = new CTabFolder(contPane, SWT.BORDER);
				tabf.setLayoutData(new GridData(GridData.FILL_BOTH));
				tabf.addSelectionListener(new SListener);

				_flags.construct(tabf);
				_areas.construct(tabf, _flags.flags);

				tabA = new CTabItem(tabf, SWT.NONE);
				tabA.setText(_prop.msgs.scenarioView);
				tabA.setControl(_areas.panel);
				tabF = new CTabItem(tabf, SWT.NONE);
				tabF.setText(_prop.msgs.variableView);
				tabF.setControl(_flags.widget);

				_tcpd ~= _areas;
				_tcpd ~= _flags.flags;
				_tcpd ~= _flags.dirs;
			} else static if (UseArea) {
				_areas.construct(contPane, null);
				_areas.panel.setLayoutData(new GridData(GridData.FILL_BOTH));
				_tcpd ~= _areas;
			} else static if (UseFlag) {
				_flags.construct(contPane);
				_flags.widget.setLayoutData(new GridData(GridData.FILL_BOTH));
				_tcpd ~= _flags.flags;
				_tcpd ~= _flags.dirs;
			} else static assert (0);
		}
		if (shell) { mixin(S_TRACE);
			{ mixin(S_TRACE);
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
				appendMenuTCPD(_comm, me, this, true, true, true, true, true);
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
					createMenuItem(_comm, mt, MenuID.NewAreaDir, &createAreaDir, &canCreateAreaDir);
					new MenuItem(mt, SWT.SEPARATOR);
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
			{ mixin(S_TRACE);
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
					createToolItem(_comm, bar, MenuID.NewAreaDir, &createAreaDir, &canCreateAreaDir);
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
		} else { mixin(S_TRACE);
			appendMenuTCPD(_comm, this, this, true, true, true, true, true);
			static if (UseArea && UseFlag) {
				putMenuAction(MenuID.EditSummary, &editSummary, &canEditSummary);
			}
			static if (UseArea) {
				putMenuAction(MenuID.EditScene, &openAreaScene, &_areas.canOpenAreaScene);
				putMenuAction(MenuID.EditEvent, &openAreaEvent, &_areas.canOpenAreaEvent);
				putMenuAction(MenuID.NewAreaDir, &createAreaDir, &canCreateAreaDir);
				putMenuAction(MenuID.NewArea, &createArea, &canCreateArea);
				putMenuAction(MenuID.NewBattle, &createBattle, &canCreateBattle);
				putMenuAction(MenuID.NewPackage, &createPackage, &canCreatePackage);
				putMenuAction(MenuID.ReNumbering, &_areas.reNumbering, &_areas.canReNumbering);
				putMenuAction(MenuID.SetStartArea, &_areas.setStartArea, &_areas.canSetStartArea);
			}
			static if (UseFlag) {
				putMenuAction(MenuID.NewFlagDir, &createFlagDir, &canCreateFlagDir);
				putMenuAction(MenuID.NewFlag, &createFlag, &canCreateFlag);
				putMenuAction(MenuID.NewStep, &createStep, &canCreateStep);
				putMenuAction(MenuID.EditProp, &_flags.edit, &_flags.canEdit);
			}
			putMenuAction(MenuID.ChangeVH, &changeVHSide, &canChangeVH);
			putMenuAction(MenuID.Undo, &undo, &canUndo);
			putMenuAction(MenuID.Redo, &redo, &canRedo);
			putMenuAction(MenuID.Up, &up, &canUp);
			putMenuAction(MenuID.Down, &down, &canDown);
			putMenuAction(MenuID.FindID, &replaceID, &canReplaceID);
		}
		static if (UseArea && UseFlag) {
			if (shell) { mixin(S_TRACE);
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
					override void controlMoved(ControlEvent e) { mixin(S_TRACE);
						saveDataWin();
					}
					override void controlResized(ControlEvent e) { mixin(S_TRACE);
						saveDataWin();
					}
				});
			}
		}
		_comm.refScenarioName.add(&__refreshTitle);
		_win.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				_comm.refScenarioName.remove(&__refreshTitle);
			}
		});
	}
	static if (UseArea) {
		@property
		AreaTable areas() { return _areas; }

		void refTableViewStyle() { mixin(S_TRACE);
			static if (UseFlag) {
				tabA.getControl().dispose();
				_areas.construct(tabf, _flags.flags);
				tabA.setControl(_areas.panel);
			} else {
				_areas.panel.dispose();
				_areas.construct(_contPane, null);
				_areas.panel.setLayoutData(new GridData(GridData.FILL_BOTH));
				_contPane.layout();
			}
			if (_summ) _areas.summary = _summ;
		}
	}
	static if (UseArea && UseFlag) {
		private void saveDataWin() { mixin(S_TRACE);
			auto win = cast(Shell) _win;
			if (win) { mixin(S_TRACE);
				if (!win.getMaximized() && !win.getMinimized()) { mixin(S_TRACE);
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
	override
	Composite shell() {return _win;}

	static if (UseArea) {
		@property
		bool canEditSummary() { mixin(S_TRACE);
			return _summ !is null;
		}
		@property
		bool canCreateAreaDir() { mixin(S_TRACE);
			return _summ !is null && _areas.canCreateDir;
		}
		@property
		bool canCreateArea() { mixin(S_TRACE);
			return _summ !is null;
		}
		@property
		alias canCreateArea canCreateBattle;
		@property
		alias canCreateArea canCreatePackage;
		void editSummary() { mixin(S_TRACE);
			if (!_summ) return;
			if (_win && !_win.isDisposed()) { mixin(S_TRACE);
				_areas.editSummary(_win.getShell());
			} else { mixin(S_TRACE);
				_areas.editSummary(_parentShell);
			}
		}

		private void openAreaScene() { mixin(S_TRACE);
			_areas.openAreaScene(true);
		}
		private void openAreaEvent() { mixin(S_TRACE);
			_areas.openAreaEvent(true);
		}

		/// エリアビューを開く。
		void openAreaScene(ulong id, bool shellActivate) { mixin(S_TRACE);
			_areas.openAreaScene(id, shellActivate);
		}
		/// ditto
		void openAreaEvent(ulong id, bool shellActivate) { mixin(S_TRACE);
			_areas.openAreaEvent(id, shellActivate);
		}
		/// ditto
		void openBattleScene(ulong id, bool shellActivate) { mixin(S_TRACE);
			_areas.openBattleScene(id, shellActivate);
		}
		/// ditto
		void openBattleEvent(ulong id, bool shellActivate) { mixin(S_TRACE);
			_areas.openBattleEvent(id, shellActivate);
		}
		/// ditto
		void openPackage(ulong id, bool shellActivate) { mixin(S_TRACE);
			_areas.openPackage(id, shellActivate);
		}
		void createAreaDir() { mixin(S_TRACE);
			if (!_summ) return;
			_comm.openDataWin(false);
			_areas.createDir();
		}
		void createArea() { mixin(S_TRACE);
			if (!_summ) return;
			_comm.openDataWin(false);
			.forceFocus(_areas.table, false);
			_areas.createArea();
		}
		void createBattle() { mixin(S_TRACE);
			if (!_summ) return;
			_comm.openDataWin(false);
			.forceFocus(_areas.table, false);
			_areas.createBattle();
		}
		void createPackage() { mixin(S_TRACE);
			createPackage(null);
		}
		ulong createPackage(Content baseStart) { mixin(S_TRACE);
			if (!_summ) return 0;
			_comm.openDataWin(false);
			.forceFocus(_areas.table, false);
			return _areas.createPackage(baseStart);
		}
		void reNumberingAll() { mixin(S_TRACE);
			_areas.reNumberingAll();
		}
	}
	static if (UseFlag) {
		@property
		FlagsPane flags() { return _flags; }

		@property
		bool canCreateFlagDir() { mixin(S_TRACE);
			return _summ !is null;
		}
		@property
		alias canCreateFlagDir canCreateFlag;
		@property
		alias canCreateFlagDir canCreateStep;

		void createFlagDir() { mixin(S_TRACE);
			if (!_summ) return;
			_flags.dirs.createDir();
		}
		void createFlag() { mixin(S_TRACE);
			if (!_summ) return;
			_flags.flags.createFlag();
		}
		void createStep() { mixin(S_TRACE);
			if (!_summ) return;
			_flags.flags.createStep();
		}
	}
	static if (UseArea && UseFlag) {
		void selectData() { mixin(S_TRACE);
			tabf.setSelection(tabA);
			selectedImpl();
		}
		void selectFlags() { mixin(S_TRACE);
			tabf.setSelection(tabF);
			selectedImpl();
		}
		private void changeVHSide() { mixin(S_TRACE);
			if (tabf.getSelection() is tabA) {
				_areas.changeVHSide();
			} else {
				_flags.changeVHSide();
			}
		}
		private bool canChangeVH() { mixin(S_TRACE);
			if (tabf.getSelection() is tabA) {
				return _areas.canChangeVH();
			} else {
				return true;
			}
		}
	} else static if (UseArea) {
		private void changeVHSide() { mixin(S_TRACE);
			_areas.changeVHSide();
		}
		private bool canChangeVH() { mixin(S_TRACE);
			return _areas.canChangeVH();
		}
	} else static if (UseFlag) {
		private void changeVHSide() { mixin(S_TRACE);
			_flags.changeVHSide();
		}
		private bool canChangeVH() { mixin(S_TRACE);
			return true;
		}
	}

	@property
	override
	Image image() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			return _prop.images.menu(MenuID.TableView);
		} else static if (UseArea) {
			return _prop.images.menu(MenuID.TableView);
		} else static if (UseFlag) {
			return _prop.images.menu(MenuID.VarView);
		} else static assert (0);
	}
	@property
	override
	string title() { mixin(S_TRACE);
		auto shl = cast(Shell) _win;
		static if (UseArea && UseFlag) {
			if (shl && _summ) { mixin(S_TRACE);
				return .tryFormat(_prop.msgs.dataWindowName, _summ.scenarioName, _summ.scenarioPath);
			}
			return _prop.msgs.dataTabName;
		} else static if (UseArea) {
			if (shl && _summ) { mixin(S_TRACE);
				return .tryFormat(_prop.msgs.areasWindowName, _summ.scenarioName, _summ.scenarioPath);
			}
			return _prop.msgs.areasTabName;
		} else static if (UseFlag) {
			if (shl && _summ) { mixin(S_TRACE);
				return .tryFormat(_prop.msgs.flagWindowName, _summ.scenarioName, _summ.scenarioPath);
			}
			return _prop.msgs.flagTabName;
		} else static assert (0);
	}
	@property
	override
	void delegate(string) statusText() {return _sbshl ? &_sbshl.statusLine : null;}

	private void __refreshTitle() { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) return;
		_comm.setTitle(_win, title);
	}
	private void refresh() { mixin(S_TRACE);
		__refreshTitle();
		static if (UseArea) {
			_areas.summary = _summ;
			static if (UseFlag) {
				if (_win && !_win.isDisposed()) { mixin(S_TRACE);
					tabf.setSelection(tabA);
				}
			}
		}
		static if (UseFlag) {
			_flags.setFlagDirTree(_summ.flagDirRoot, _summ.useCounter);
		}
	}

	@property
	bool canUp() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				return _areas.canUp();
			} else { mixin(S_TRACE);
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
	bool canDown() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				return _areas.canDown();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				return _flags.canDown();
			}
		} else static if (UseArea) {
			return _areas.canDown();
		} else static if (UseFlag) {
			return _flags.canDown();
		} else static assert (0);
	}
	void up() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				_areas.up();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				_flags.up();
			}
		} else static if (UseArea) {
			_areas.up();
		} else static if (UseFlag) {
			_flags.up();
		} else static assert (0);
	}
	void down() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				_areas.down();
			} else { mixin(S_TRACE);
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
	void load(Summary summ) { mixin(S_TRACE);
		_summ = summ;
		refresh();
	}

	/// Returns: 貼り紙。
	@property
	Summary summary() { mixin(S_TRACE);
		return _summ;
	}
	static if (UseArea) {
		void selectSummary() { mixin(S_TRACE);
			_areas.selectSummary();
		}
	}

	override {
		void cut(SelectionEvent se) { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) { mixin(S_TRACE);
					c.cut(se);
				}
			}
		}
		void copy(SelectionEvent se) { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) { mixin(S_TRACE);
					c.copy(se);
				}
			}
		}
		void paste(SelectionEvent se) { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) { mixin(S_TRACE);
					c.paste(se);
				}
			}
		}
		void del(SelectionEvent se) { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) { mixin(S_TRACE);
					c.del(se);
				}
			}
		}
		void clone(SelectionEvent se) { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) { mixin(S_TRACE);
					c.clone(se);
				}
			}
		}
		bool canDoTCPD() { mixin(S_TRACE);
			return .hasFocus(_win);
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoT;
			}
			return false;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoC;
			}
			return false;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoP;
			}
			return false;
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoD;
			}
			return false;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			foreach (c; _tcpd) { mixin(S_TRACE);
				if (c.canDoTCPD) return c.canDoClone;
			}
			return false;
		}
	}

	private bool openCWXPathAfCommon(A)(A a, ref string path, bool shellActivate) { mixin(S_TRACE);
		path = cpbottom(path);
		if (cpattr(path).contains("shallow") && cpempty(path)) { mixin(S_TRACE);
			if (!cphasattr(path, "nofocus")) .forceFocus(_areas.table, shellActivate);
			_areas.select(a);
			_comm.refreshToolBar();
			return true;
		}
		return false;
	}
	private bool openCWXPathAf(BindWindow, SceneWindow, EventWindow, A)(lazy BindWindow bw, lazy SceneWindow sw, lazy EventWindow ew, A a, string path, bool shellActivate) { mixin(S_TRACE);
		if (openCWXPathAfCommon(a, path, shellActivate)) { mixin(S_TRACE);
			return true;
		}
		string cate = cpcategory(path);
		bool isScene = cpempty(path)
			|| ((cate == "menucard" || cate == "enemycard") && cpempty(cpbottom(path)))
			|| cate == "background";
		if (isScene && cphasattr(path, "eventview")) { mixin(S_TRACE);
			isScene = false;
		}
		string aPath = a.cwxPath(true);
		if (isScene) { mixin(S_TRACE);
			auto sw2 = _comm.areaWindowFrom(aPath, shellActivate);
			if (sw2) { mixin(S_TRACE);
				return sw2.openCWXPath(path, shellActivate);
			}
			if (!_comm.singleWindowMode(_prop) || _prop.var.etc.bindSceneWithEvent) { mixin(S_TRACE);
				return bw.openCWXPath(path, shellActivate);
			} else { mixin(S_TRACE);
				return sw.openCWXPath(path, shellActivate);
			}
		} else { mixin(S_TRACE);
			auto ew2 = _comm.eventWindowFrom(aPath, shellActivate);
			if (ew2) { mixin(S_TRACE);
				return ew2.openCWXPath(path, shellActivate);
			}
			if (!_comm.singleWindowMode(_prop) || _prop.var.etc.bindSceneWithEvent) { mixin(S_TRACE);
				return bw.openCWXPath(path, shellActivate);
			} else { mixin(S_TRACE);
				return ew.openCWXPath(path, shellActivate);
			}
		}
	}
	private bool openCWXPathAf(Window, A)(lazy Window w, A a, string path, bool shellActivate) { mixin(S_TRACE);
		if (openCWXPathAfCommon(a, path, shellActivate)) { mixin(S_TRACE);
			return true;
		}
		if (w) { mixin(S_TRACE);
			static if (UseArea && UseFlag) {
				tabf.setSelection(tabA);
				_comm.refreshToolBar();
			}
			return w.openCWXPath(path, shellActivate);
		}
		return false;
	}
	override
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		if (cpempty(path)) { mixin(S_TRACE);
			static if (UseArea) {
				_comm.selectSummary(shellActivate);
				if (!cphasattr(path, "nofocus")) .forceFocus(_areas.table, shellActivate);
				if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
					editSummary();
				}
			} else { mixin(S_TRACE);
				_comm.openFlagWin(shellActivate);
			}
			return true;
		}
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		switch (cate) {
		case "area": { mixin(S_TRACE);
			static if (UseArea) {
				if (index >= _summ.areas.length) return false;
				auto a = _summ.areas[index];
				return openCWXPathAf(_comm.openArea(_prop, _summ, a, shellActivate),
					_comm.openAreaScene(_prop, _summ, a, shellActivate),
					_comm.openAreaEvent(_prop, _summ, a, shellActivate),
					a, path, shellActivate);
			}
		} break;
		case "area:id": { mixin(S_TRACE);
			static if (UseArea) {
				auto a = _summ.area(index);
				return openCWXPathAf(_comm.openArea(_prop, _summ, a, shellActivate),
					_comm.openAreaScene(_prop, _summ, a, shellActivate),
					_comm.openAreaEvent(_prop, _summ, a, shellActivate),
					a, path, shellActivate);
			}
		} break;
		case "battle": { mixin(S_TRACE);
			static if (UseArea) {
				if (index >= _summ.battles.length) return false;
				auto a = _summ.battles[index];
				return openCWXPathAf(_comm.openArea(_prop, _summ, a, shellActivate),
					_comm.openAreaScene(_prop, _summ, a, shellActivate),
					_comm.openAreaEvent(_prop, _summ, a, shellActivate),
					a, path, shellActivate);
			}
		} break;
		case "battle:id": { mixin(S_TRACE);
			static if (UseArea) {
				auto a = _summ.battle(index);
				return openCWXPathAf(_comm.openArea(_prop, _summ, a, shellActivate),
					_comm.openAreaScene(_prop, _summ, a, shellActivate),
					_comm.openAreaEvent(_prop, _summ, a, shellActivate),
					a, path, shellActivate);
			}
		} break;
		case "package": { mixin(S_TRACE);
			static if (UseArea) {
				if (index >= _summ.packages.length) return false;
				auto a = _summ.packages[index];
				return openCWXPathAf(_comm.openArea(_prop, _summ, a, shellActivate),
					a, path, shellActivate);
			}
		} break;
		case "package:id": { mixin(S_TRACE);
			static if (UseArea) {
				auto a = _summ.cwPackage(index);
				return openCWXPathAf(_comm.openArea(_prop, _summ, a, shellActivate),
					a, path, shellActivate);
			}
		} break;
		case "tableview": { mixin(S_TRACE);
			static if (UseArea) {
				.forceFocus(_areas.table, shellActivate);
				return true;
			}
		} break;
		case "variable": { mixin(S_TRACE);
			static if (UseFlag) {
				return _flags.openCWXPath(cpbottom(path), shellActivate);
			}
		} break;
		case "variableview": { mixin(S_TRACE);
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
	override
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				auto a = _areas.openedCWXPath;
				auto b = _flags.openedCWXPath;
				if (!a.length) r ~= "tableview";
				if (!b.length) r ~= "variableview";
				r ~= a ~ b;
			} else { mixin(S_TRACE);
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
	bool canUndo() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				return _areas.canUndo();
			} else { mixin(S_TRACE);
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
	bool canRedo() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				return _areas.canRedo();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				return _flags.canRedo();
			}
		} else static if (UseArea) {
			return _areas.canRedo();
		} else static if (UseFlag) {
			return _flags.canRedo();
		} else static assert (0);
	}
	void undo() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				_areas.undo();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				_flags.undo();
			}
		} else static if (UseArea) {
			_areas.undo();
		} else static if (UseFlag) {
			_flags.undo();
		} else static assert (0);
	}
	void redo() { mixin(S_TRACE);
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				_areas.redo();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				_flags.redo();
			}
		} else static if (UseArea) {
			_areas.redo();
		} else static if (UseFlag) {
			_flags.redo();
		} else static assert (0);
	}
	void replaceID() {
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				_areas.replaceID();
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				_flags.replaceID();
			}
		} else static if (UseArea) {
			_areas.replaceID();
		} else static if (UseFlag) {
			_flags.replaceID();
		} else static assert (0);
	}
	@property
	bool canReplaceID() {
		static if (UseArea && UseFlag) {
			if (tabf.getSelection() is tabA) { mixin(S_TRACE);
				return _areas.canReplaceID;
			} else { mixin(S_TRACE);
				assert (tabf.getSelection() is tabF);
				return _flags.canReplaceID;
			}
		} else static if (UseArea) {
			return _areas.canReplaceID;
		} else static if (UseFlag) {
			return _flags.canReplaceID;
		} else static assert (0);
	}
}

alias AbstractDataWindow!(true, true) DataWindow;
alias AbstractDataWindow!(true, false) TableWindow;
alias AbstractDataWindow!(false, true) FlagWindow;
