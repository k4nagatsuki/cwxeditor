
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
import cwx.editor.gui.dwt.sbshell;

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

	void saveScenario() {
		_comm.save.call(_win.getShell);
	}
	static if (UseArea && UseFlag) {
		class SListener : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) {
				if (tabf.getSelection is tabA) {
					_comm.statusLine(tabf, _areas.statusLine);
				} else {
					assert (tabf.getSelection is tabF);
					_comm.statusLine(tabf, _flags.statusLine);
				}
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
		Composite contPane;
		if (parShl) {
			_sbshl = new SBShell(parShl, SWT.SHELL_TRIM);
			shell = _sbshl.shell;
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
			contPane = _sbshl.contentPane;
		} else {
			_win = new Composite(parent, SWT.NONE);
			contPane = _win;
		}
		_win.setData = new TLPData(this);
		contPane.setLayout = windowGridLayout(1, true);

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

				auto mf = createMenu(bar, _prop.msgs.menuFile);
				createMenuItem(mf, _prop.msgs.menuSave, _prop.images.menuSave, &saveScenario);
				new MenuItem(mf, SWT.SEPARATOR);
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
						new MenuItem(mt, SWT.SEPARATOR);
					}
					createMenuItem(mt, _prop.msgs.menuNewArea, _prop.images.menuNewArea, &createArea);
					createMenuItem(mt, _prop.msgs.menuNewBattle, _prop.images.menuNewBattle, &createBattle);
					createMenuItem(mt, _prop.msgs.menuNewPackage, _prop.images.menuNewPackage, &createPackage);
				}
				static if (UseFlag) {
					auto mv = createMenu(bar, _prop.msgs.menuVariable);
					createMenuItem(mv, _prop.msgs.menuNewFlagDir, _prop.images.menuNewFlagDir, &createFlagDir);
					new MenuItem(mv, SWT.SEPARATOR);
					createMenuItem(mv, _prop.msgs.menuNewFlag, _prop.images.menuNewFlag, &createFlag);
					createMenuItem(mv, _prop.msgs.menuNewStep, _prop.images.menuNewStep, &createStep);
				}
				shell.setMenuBar = bar;
			}
			{
				auto bar = new ToolBar(contPane, SWT.FLAT);
				bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);

				static if (UseArea && UseFlag) {
					createToolItem(bar, _prop.msgs.ttSummary, _prop.images.menuSummary, &editSummary);
				}
				static if (UseArea) {
					new ToolItem(bar, SWT.SEPARATOR);
					createToolItem(bar, _prop.msgs.ttNewArea, _prop.images.menuNewArea, &createArea);
					createToolItem(bar, _prop.msgs.ttNewBattle, _prop.images.menuNewBattle, &createBattle);
					createToolItem(bar, _prop.msgs.ttNewPackage, _prop.images.menuNewPackage, &createPackage);
				}
				static if (UseFlag) {
					new ToolItem(bar, SWT.SEPARATOR);
					createToolItem(bar, _prop.msgs.ttNewFlag, _prop.images.menuNewFlag, &createFlag);
					createToolItem(bar, _prop.msgs.ttNewStep, _prop.images.menuNewStep, &createStep);
					createToolItem(bar, _prop.msgs.ttNewFlagDir, _prop.images.menuNewFlagDir, &createFlagDir);
					new ToolItem(bar, SWT.SEPARATOR);
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
				tabf = new CTabFolder(contPane, SWT.BORDER);
				tabf.setLayoutData = new GridData(GridData.FILL_BOTH);
				tabf.addSelectionListener(new SListener);

				_flags = new FlagsPane(_comm, _prop, tabf);
				_flags.setupTLP(this);
				_areas.construct(tabf, _flags.flags);

				tabA = new CTabItem(tabf, SWT.NONE);
				tabA.setText = _prop.msgs.scenarioView;
				tabA.setControl(_areas.table);
				tabF = new CTabItem(tabf, SWT.NONE);
				tabF.setText = _prop.msgs.variableView;
				tabF.setControl(_flags.widget);

				_tcpd ~= _areas;
				_tcpd ~= _flags.flags;
				_tcpd ~= _flags.dirs;
			} else static if (UseArea) {
				_areas.construct(contPane, null);
				_areas.table.setLayoutData = new GridData(GridData.FILL_BOTH);
				_tcpd ~= _areas;
			} else static if (UseFlag) {
				_flags = new FlagsPane(_comm, _prop, contPane);
				_flags.setupTLP(this);
				_flags.widget.setLayoutData = new GridData(GridData.FILL_BOTH);
				_tcpd ~= _flags.flags;
				_tcpd ~= _flags.dirs;
			} else static assert (0);
		}
		static if (UseArea && UseFlag) {
			if (shell) {
				shell.setMaximized = _prop.var.dataWin.maximized;
				shell.setMinimized = _prop.var.dataWin.minimized;
				scope wp = shell.computeSize(SWT.DEFAULT, SWT.DEFAULT);
				int width = _prop.var.dataWin.width == SWT.DEFAULT ? wp.x : _prop.var.dataWin.width;
				int height = _prop.var.dataWin.height == SWT.DEFAULT ? wp.y : _prop.var.dataWin.height;
				int x = _prop.var.dataWin.x == SWT.DEFAULT ? shell.getBounds.x : _prop.var.dataWin.x + shell.getParent.getBounds.x;
				int y = _prop.var.dataWin.y == SWT.DEFAULT ? shell.getBounds.y : _prop.var.dataWin.y + shell.getParent.getBounds.y;
				intoDisplay(x, y, width, height);
				shell.setBounds(x, y, width, height);
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
			if (_win && !_win.isDisposed) {
				_areas.editSummary(_win.getShell);
			} else {
				_areas.editSummary(_parentShell);
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
	void delegate(string) statusText() {return _sbshl ? &_sbshl.statusLine : null;}

	private void __refreshTitle() {
		if (!_win || _win.isDisposed) return;
		_comm.setTitle(_win, title);
	}
	private void refresh() {
		__refreshTitle;
		static if (UseArea) {
			_areas.summary = _summ;
			static if (UseFlag) {
				if (_win && !_win.isDisposed) {
					tabf.setSelection = tabA;
				}
			}
		}
		static if (UseFlag) {
			if (_win && !_win.isDisposed) {
				_flags.setFlagDirTree(_summ.flagDirRoot, _summ.useCounter);
			}
		}
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
