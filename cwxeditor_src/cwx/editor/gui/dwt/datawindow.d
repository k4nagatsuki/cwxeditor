
module cwx.editor.gui.dwt.datawindow;

import cwx.summary;
import cwx.event;
import cwx.flag;
import cwx.utils;
import cwx.usecounter;
import cwx.skin;
import cwx.path;
import cwx.msgs;
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

import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.CoolBar;
import org.eclipse.swt.widgets.CoolItem;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CTabItem;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.events.KeyListener;
import org.eclipse.swt.events.ShellAdapter;
import org.eclipse.swt.events.ShellEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.ControlAdapter;
import org.eclipse.swt.events.ControlEvent;

class AbstractDataWindow(bool UseArea, bool UseFlag) : TopLevelPanel, TCPD {
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
		}
		class SListener : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) {
				selectedImpl();
			}
		}
	}
public:
	this(Commons comm, Props prop, Shell parentShell, Composite parent) {
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
				createMenuItem(_comm, mf, MenuID.CloseWin, &shell.close);

				auto me = createMenu(_comm, bar, MenuID.Edit);
				static if (UseArea) {
					createMenuItem(_comm, me, MenuID.EditScene, &openAreaScene);
					createMenuItem(_comm, me, MenuID.EditEvent, &openAreaEvent);
					new MenuItem(me, SWT.SEPARATOR);
				}
				createMenuItem(_comm, me, MenuID.Undo, &undo);
				createMenuItem(_comm, me, MenuID.Redo, &redo);
				new MenuItem(me, SWT.SEPARATOR);
				appendMenuTCPD(_comm, me, this, true, true, true, true);
				new MenuItem(me, SWT.SEPARATOR);
				createMenuItem(_comm, me, MenuID.Up, &up);
				createMenuItem(_comm, me, MenuID.Down, &down);

				static if (UseFlag) {
					auto mi = createMenu(_comm, bar, MenuID.View);
					createMenuItem(_comm, mi, MenuID.ChangeVH, &changeVHSide);
				}

				static if (UseArea) {
					auto mt = createMenu(_comm, bar, MenuID.Table);
					static if (UseFlag) {
						createMenuItem(_comm, mt, MenuID.EditSummary, &editSummary);
						new MenuItem(mt, SWT.SEPARATOR);
					}
					createMenuItem(_comm, mt, MenuID.NewArea, &createArea);
					createMenuItem(_comm, mt, MenuID.NewBattle, &createBattle);
					createMenuItem(_comm, mt, MenuID.NewPackage, &createPackage);
				}
				static if (UseFlag) {
					auto mv = createMenu(_comm, bar, MenuID.Variable);
					createMenuItem(_comm, mv, MenuID.NewFlagDir, &createFlagDir);
					new MenuItem(mv, SWT.SEPARATOR);
					createMenuItem(_comm, mv, MenuID.NewFlag, &createFlag);
					createMenuItem(_comm, mv, MenuID.NewStep, &createStep);
				}
				shell.setMenuBar(bar);
			}
			{
				auto bar = new ToolBar(contPane, SWT.FLAT);
				bar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

				static if (UseArea && UseFlag) {
					createToolItem(_comm, bar, MenuID.EditSummary, &editSummary);
				}
				createToolItem(_comm, bar, MenuID.Up, &up);
				createToolItem(_comm, bar, MenuID.Down, &down);
				static if (UseArea) {
					new ToolItem(bar, SWT.SEPARATOR);
					createToolItem(_comm, bar, MenuID.NewArea, &createArea);
					createToolItem(_comm, bar, MenuID.NewBattle, &createBattle);
					createToolItem(_comm, bar, MenuID.NewPackage, &createPackage);
				}
				static if (UseFlag) {
					new ToolItem(bar, SWT.SEPARATOR);
					createToolItem(_comm, bar, MenuID.NewFlag, &createFlag);
					createToolItem(_comm, bar, MenuID.NewStep, &createStep);
					createToolItem(_comm, bar, MenuID.NewFlagDir, &createFlagDir);
					new ToolItem(bar, SWT.SEPARATOR);
					createToolItem(_comm, bar, MenuID.ChangeVH, &changeVHSide);
				}
			}
		} else {
			appendMenuTCPD(_comm, this, this, true, true, true, true);
			static if (UseArea && UseFlag) {
				putMenuAction(MenuID.EditSummary, &editSummary);
			}
			static if (UseArea) {
				putMenuAction(MenuID.EditScene, &openAreaScene);
				putMenuAction(MenuID.EditEvent, &openAreaEvent);
				putMenuAction(MenuID.NewArea, &createArea);
				putMenuAction(MenuID.NewBattle, &createBattle);
				putMenuAction(MenuID.NewPackage, &createPackage);
			}
			static if (UseFlag) {
				putMenuAction(MenuID.NewFlagDir, &createFlagDir);
				putMenuAction(MenuID.NewFlag, &createFlag);
				putMenuAction(MenuID.NewStep, &createStep);
			}
			putMenuAction(MenuID.Undo, &undo);
			putMenuAction(MenuID.Redo, &redo);
			putMenuAction(MenuID.Up, &up);
			putMenuAction(MenuID.Down, &down);
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
		string aPath = a.cwxPath;
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
		case "variable": {
			static if (UseFlag) {
				return _flags.openCWXPath(cpbottom(path), shellActivate);
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
				r ~= _areas.openedCWXPath;
				r ~= _flags.openedCWXPath;
			} else {
				r ~= _flags.openedCWXPath;
				r ~= _areas.openedCWXPath;
			}
		} else static if (UseArea) {
			r ~= _areas.openedCWXPath;
		} else static if (UseFlag) {
			r ~= _flags.openedCWXPath;
		} else static assert (0);
		return r;
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
