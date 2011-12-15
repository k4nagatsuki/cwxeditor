
module cwx.editor.gui.dwt.areawindow;

import cwx.area;
import cwx.summary;
import cwx.skin;
import cwx.utils;
import cwx.path;

import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.eventview;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.sbshell;
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.eventtreeview;

import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CTabItem;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionAdapter;

public:

class TAreaWindow(V, A, C, bool WithEventView) : TopLevelPanel, TCPD {
private:
	Commons _comm;

	SBShell _sbshl;
	Composite _win;
	Shell _areaWin = null;

	Summary _summ;
	A _area;
	Props _prop;

	UndoManager _undo;

	V _aview;

	static if (WithEventView) {
		CTabFolder _tabf;
		CTabItem _tabA;
		CTabItem _tabE;
		EventView!(A, C, true) _eview;
	}

	TCPD[] _tcpd;

	void refresh() {
		_aview.refresh;
	}
	void up() {
		static if (WithEventView) {
			if (_tabA !is null && _tabf.getSelectionIndex == 0) {
				_aview.setFocus;
				_aview.up;
			} else {
				_eview.up;
			}
		} else {
			_aview.up;
		}
	}
	void down() {
		static if (WithEventView) {
			if (_tabA !is null && _tabf.getSelectionIndex == 0) {
				_aview.setFocus;
				_aview.down;
			} else {
				_eview.down;
			}
		} else {
			_aview.down;
		}
	}
	void __deleteArea(A area) {
		if (_area is area) {
			_comm.close(_win);
		}
	}
	void __refArea(A area) {
		if (_area is area) {
			__refreshTitle;
		}
	}
	void __refreshTitle() {
		_comm.setTitle(_win, title);
	}
	static if (WithEventView) {
		void selectedTabImpl() {
			if (_tabf.getSelection is _tabE) {
				_eview.initial;
				_comm.statusLine(_win, _eview.statusLine);
				_eview.openToolWindow;
			} else {
				_comm.statusLine(_win, _aview.statusLine);
				_eview.closeToolWindow;
			}
		}
		class TabSel : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) {
				selectedTabImpl();
			}
		}
	}
	bool _refUndo = false;
	void refUndoMax() {
		if (!_refUndo) return;
		_undo.max = _prop.var.etc.undoMaxEvent;
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			saveWin();
			static if (is (A == Area)) {
				_comm.delArea.remove(&__deleteArea);
				_comm.refArea.remove(&__refArea);
			} else static if (is (A == Battle)) {
				_comm.delBattle.remove(&__deleteArea);
				_comm.refBattle.remove(&__refArea);
			} else static if (is (A == Package)) {
				_comm.delPackage.remove(&__deleteArea);
				_comm.refPackage.remove(&__refArea);
			} else {
				static assert (0);
			}
			_comm.replText.remove(&__refreshTitle);
			_comm.refUndoMax.remove(&refUndoMax);
		}
	}
public:
	this(Commons comm, Props prop, Summary summ, Composite parent, Shell areaWin, A area, UndoManager undo = null) {
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_area = area;
		_refUndo = undo is null;
		_undo = undo ? undo : new UndoManager(_prop.var.etc.undoMaxEvent);
		Shell shell = null;
		auto parShl = cast(Shell) parent;
		Composite contPane;
		if (parShl) {
			_sbshl = new SBShell(parShl, SWT.SHELL_TRIM);
			shell = _sbshl.shell;
			shell.setImage = prop.images.app;
			_win = shell;
			contPane = _sbshl.contentPane;
		} else {
			_win = new Composite(parent, SWT.NONE);
			contPane = _win;
		}
		_win.setData = new TLPData(this);
		static if (is (A == Area)) {
			_comm.delArea.add(&__deleteArea);
			_comm.refArea.add(&__refArea);
		} else static if (is (A == Battle)) {
			_comm.delBattle.add(&__deleteArea);
			_comm.refBattle.add(&__refArea);
		} else static if (is (A == Package)) {
			_comm.delPackage.add(&__deleteArea);
			_comm.refPackage.add(&__refArea);
		} else {
			static assert (0);
		}
		_comm.replText.add(&__refreshTitle);
		_comm.refUndoMax.add(&refUndoMax);
		_win.addDisposeListener(new Dispose);
		contPane.setLayout = windowGridLayout(1, true);
		_prop = prop;
		static if (WithEventView) {
			_tabf = new CTabFolder(contPane, SWT.BORDER);
			_tabf.setLayoutData = new GridData(GridData.FILL_BOTH);
			if (cast(Area) area || cast(Battle) area) {
				_tabA = new CTabItem(_tabf, SWT.NONE);
				_tabA.setText = _prop.msgs.cardAndBackView;
			}
			_tabE = new CTabItem(_tabf, SWT.NONE);
			_tabE.setText = _prop.msgs.eventView;
			_tabf.addSelectionListener(new TabSel);

			if (cast(Area) area) {
				_tabA.setImage = _prop.images.areaSceneView;
				_tabE.setImage = _prop.images.areaEventTreeView;
			} else if (cast(Battle) area) {
				_tabA.setImage = _prop.images.battleSceneView;
				_tabE.setImage = _prop.images.battleEventTreeView;
			} else assert (0);
		}

		if (shell) {
			auto bar = new Menu(shell, SWT.BAR);

			auto mf = createMenu(bar, _prop.msgs.menuFile);
			static if (is(A : Area) && !WithEventView) {
				createMenuItem(mf, _prop.msgs.menuEditEvent, _prop.images.areaEventTreeView, &openEvent);
				new MenuItem(mf, SWT.SEPARATOR);
			} else static if (is(A : Battle) && !WithEventView) {
				createMenuItem(mf, _prop.msgs.menuEditEvent, _prop.images.battleEventTreeView, &openEvent);
				new MenuItem(mf, SWT.SEPARATOR);
			}
			createMenuItem(mf, _prop.msgs.menuCloseWin, _prop.images.menuCloseWin, &shell.close);

			auto me = createMenu(bar, _prop.msgs.menuEdit);
			createMenuItem(me, _prop.msgs.menuUndo, _prop.images.menuUndo, &this.undo);
			createMenuItem(me, _prop.msgs.menuRedo, _prop.images.menuRedo, &this.redo);
			new MenuItem(me, SWT.SEPARATOR);
			createMenuItem(me, _prop.msgs.menuUp, _prop.images.menuUp, &up);
			createMenuItem(me, _prop.msgs.menuDown, _prop.images.menuDown, &down);
			new MenuItem(me, SWT.SEPARATOR);
			appendMenuTCPD(_prop, me, this, true, true, true, true);
			static if (WithEventView) {
				new MenuItem(me, SWT.SEPARATOR);
				createMenuItem(me, _prop.msgs.menuWriteComment, _prop.images.menuWriteComment, &writeComment);
				new MenuItem(me, SWT.SEPARATOR);
				createMenuItem(me, _prop.msgs.menuToScript, _prop.images.menuToScript, &toScript);
				createMenuItem(me, _prop.msgs.menuToScriptAll, _prop.images.menuToScriptAll, &toScriptAll);
			}
			auto mv = createMenu(bar, _prop.msgs.menuView);
			createMenuItem(mv, _prop.msgs.menuRefresh, _prop.images.menuRefresh, &refresh);

			shell.setMenuBar = bar;
		} else {
			putMenuAction(MenuID.Undo, &this.undo);
			putMenuAction(MenuID.Redo, &this.redo);
			putMenuAction(MenuID.Up, &up);
			putMenuAction(MenuID.Down, &down);
			appendMenuTCPD(_prop, this, this, true, true, true, true);
			static if (WithEventView) {
				putMenuAction(MenuID.WriteComment, &writeComment);
				putMenuAction(MenuID.ToScript, &toScript);
				putMenuAction(MenuID.ToScriptAll, &toScriptAll);
			} else {
				putMenuAction(MenuID.EditEvent, &openEvent);
			}
			putMenuAction(MenuID.Refresh, &refresh);
		}
		{
			static if (WithEventView) {
				auto pane = _tabf;
			} else {
				auto pane = contPane;
			}
			_aview = new V(comm, prop, summ, area, pane, shell ? null : this, _undo);
			static if (WithEventView) {
				_tabA.setControl(_aview);
			} else {
				_aview.setLayoutData = new GridData(GridData.FILL_BOTH);
			}
			_tcpd ~= _aview;
			if (shell) _aview.setupMenu(shell.getMenuBar);
		}
		static if (WithEventView) {
			_eview = new EventView!(A, C, true)(comm, prop, summ, area, _tabf, _undo);
			_tabE.setControl(_eview);
			_tcpd ~= _eview;
		}
		__refreshTitle;

		if (shell) shell.pack;

		static if (is(V == AreaView)) {
			static if (WithEventView) {
				auto winProps = _prop.var.areaWin;
			} else {
				auto winProps = _prop.var.areaSceneWin;
			}
		} else static if (is(V == BattleView)) {
			static if (WithEventView) {
				auto winProps = _prop.var.battleWin;
			} else {
				auto winProps = _prop.var.battleSceneWin;
			}
		} else {
			static assert (0);
		}
		if (shell) {
			shell.setMaximized = winProps.maximized;
			scope wp = shell.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			int width = winProps.width == SWT.DEFAULT ? wp.x : winProps.width;
			int height = winProps.height == SWT.DEFAULT ? wp.y : winProps.height;
			int x = winProps.x == SWT.DEFAULT ? shell.getBounds.x : winProps.x + areaWin.getBounds.x;
			int y = winProps.y == SWT.DEFAULT ? shell.getBounds.y : winProps.y + areaWin.getBounds.y;
			intoDisplay(x, y, width, height);
			shell.setBounds(x, y, width, height);
			_areaWin = areaWin;
		}
	}

	Image image() {
		static if (is (A == Area)) {
			static if (WithEventView) {
				return _prop.images.area;
			} else {
				return _prop.images.areaSceneView;
			}
		} else static if (is (A == Battle)) {
			static if (WithEventView) {
				return _prop.images.battle;
			} else {
				return _prop.images.battleSceneView;
			}
		} else {
			static assert (0);
		}
	}
	string title() {
		auto shl = cast(Shell) _win;
		static if (is (A == Area)) {
			static if (WithEventView) {
				if (shl) {
					return _prop.msgs.areaViewName(_area.id, _area.name);
				}
				return _prop.msgs.areaViewNameTab(_area.id, _area.name);
			} else {
				if (shl) {
					return _prop.msgs.areaSceneViewName(_area.id, _area.name);
				}
				return _prop.msgs.areaSceneViewNameTab(_area.id, _area.name);
			}
		} else static if (is (A == Battle)) {
			static if (WithEventView) {
				if (shl) {
					return _prop.msgs.battleViewName(_area.id, _area.name);
				}
				return _prop.msgs.battleViewNameTab(_area.id, _area.name);
			} else {
				if (shl) {
					return _prop.msgs.battleSceneViewName(_area.id, _area.name);
				}
				return _prop.msgs.battleSceneViewNameTab(_area.id, _area.name);
			}
		} else {
			static assert (0);
		}
	}
	void delegate(string) statusText() {return _sbshl ? &_sbshl.statusLine : null;}

	private void saveWin() {
		static if (is(V == AreaView)) {
			static if (WithEventView) {
				auto winProps = _prop.var.areaWin;
			} else {
				auto winProps = _prop.var.areaSceneWin;
			}
		} else static if (is(V == BattleView)) {
			static if (WithEventView) {
				auto winProps = _prop.var.battleWin;
			} else {
				auto winProps = _prop.var.battleSceneWin;
			}
		} else {
			static assert (0);
		}
		auto shell = cast(Shell) _win;
		if (shell) {
			if (!shell.getMaximized) {
				winProps.width = shell.getSize.x;
				winProps.height = shell.getSize.y;
				if (_areaWin.isDisposed) {
					winProps.x = shell.getBounds.x - _prop.var.areaWin.x;
					winProps.y = shell.getBounds.y - _prop.var.areaWin.y;
				} else {
					winProps.x = shell.getBounds.x - _areaWin.getBounds.x;
					winProps.y = shell.getBounds.y - _areaWin.getBounds.y;
				}
			}
			winProps.maximized = shell.getMaximized;
		}
	}
	Composite shell() {
		return _win;
	}
	UndoManager undoManager() {
		return _undo;
	}
	V areaView() {
		return _aview;
	}

	/// Returns: 編集中のエリア。
	A eventTreeOwner() {
		return _area;
	}
	void undo() {_undo.undo;}
	void redo() {_undo.redo;}

	void openEvent() {
		_aview.openEvent();
	}

	static if (WithEventView) {
		EventView!(A, C, true) eventView() {
			_eview.initial;
			return _eview;
		}
		EventTreeView eventTreeView() {
			_eview.initial;
			return _eview.eventTreeView;
		}

		void selectSceneView() {
			_tabf.setSelection = _tabA;
			selectedTabImpl();
		}
		void selectEventView() {
			_tabf.setSelection = _tabE;
			selectedTabImpl();
		}

		private void toScript() {
			_eview.initial;
			_eview.toScript();
		}
		private void toScriptAll() {
			_eview.initial;
			_eview.toScriptAll();
		}
		private void writeComment() {
			_eview.initial;
			_eview.writeComment();
		}
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
	bool openCWXPath(string path, bool shellActivate) {
		auto cate = cpcategory(path);
		if (cpempty(path)) {
			static if (WithEventView) {
				_tabf.setSelection = _tabA;
			}
			return true;
		} else if (cphasattr(path, "eventview")) {
			static if (WithEventView) {
				_eview.initial();
				return _eview.openCWXPath(path, shellActivate);
			}
		} else if (((cate == "menucard" || cate == "enemycard")
				&& cpempty(cpbottom(path)))
				|| cate == "background") {
			return _aview.openCWXPath(path, shellActivate);
		} else {
			static if (WithEventView) {
				_eview.initial();
				return _eview.openCWXPath(path, shellActivate);
			}
		}
		return false;
	}
	string[] openedCWXPath() {
		string[] r;
		static if (WithEventView) {
			_eview.initial();
			if (_tabf.getSelection is _tabE) {
				r ~= _aview.openedCWXPath;
				r ~= _eview.openedCWXPath;
			} else {
				r ~= _eview.openedCWXPath;
				r ~= _aview.openedCWXPath;
			}
		} else {
			r ~= _aview.openedCWXPath;
		}
		return r;
	}
}

alias TAreaWindow!(AreaView, Area, MenuCard, true) AreaWindow;
alias TAreaWindow!(AreaView, Area, MenuCard, false) AreaSceneWindow;
alias TAreaWindow!(BattleView, Battle, EnemyCard, true) BattleWindow;
alias TAreaWindow!(BattleView, Battle, EnemyCard, false) BattleSceneWindow;
