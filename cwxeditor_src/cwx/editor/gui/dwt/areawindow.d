
module cwx.editor.gui.dwt.areawindow;

import cwx.area;
import cwx.summary;
import cwx.skin;
import cwx.utils;
import cwx.path;
import cwx.types;
import cwx.menu;

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
import cwx.editor.gui.dwt.dmenu;

import org.eclipse.swt.all;

public:

class TAreaWindow(V, A, C, bool WithEventView) : TopLevelPanel, SashPanel, TCPD {
private:
	int _readOnly = 0;
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
		_aview.refresh();
	}
	@property
	bool canUp() {
		static if (WithEventView) {
			if (_tabA !is null && _tabf.getSelectionIndex() == 0) {
				return _aview.canUp;
			} else {
				return _eview.canUp;
			}
		} else {
			return _aview.canUp;
		}
	}
	@property
	bool canDown() {
		static if (WithEventView) {
			if (_tabA !is null && _tabf.getSelectionIndex() == 0) {
				return _aview.canDown;
			} else {
				return _eview.canDown;
			}
		} else {
			return _aview.canDown;
		}
	}
	void up() {
		static if (WithEventView) {
			if (_tabA !is null && _tabf.getSelectionIndex() == 0) {
				_aview.setFocus();
				_aview.up();
			} else {
				_eview.up();
			}
		} else {
			_aview.up();
		}
	}
	void down() {
		static if (WithEventView) {
			if (_tabA !is null && _tabf.getSelectionIndex() == 0) {
				_aview.setFocus();
				_aview.down();
			} else {
				_eview.down();
			}
		} else {
			_aview.down();
		}
	}
	void __deleteArea(A area) {
		if (_area is area) {
			_comm.close(_win);
		}
	}
	void __refArea(A area) {
		if (_area is area) {
			__refreshTitle();
		}
	}
	void __refreshTitle() {
		_comm.setTitle(_win, title);
	}
	static if (WithEventView) {
		void selectedTabImpl() {
			if (_tabf.getSelection() is _tabE) {
				_eview.initial();
				_comm.setStatusLine(_win, _eview.statusLine);
				_eview.openToolWindow();
			} else {
				_comm.setStatusLine(_win, _aview.statusLine);
				_eview.closeToolWindow();
			}
			_comm.refreshToolBar();
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
	this(Commons comm, Props prop, Summary summ, Composite parent, Shell areaWin, A area, UndoManager undo = null, bool readOnly = false) {
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_area = area;
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		_refUndo = undo is null;
		_undo = undo ? undo : new UndoManager(_prop.var.etc.undoMaxEvent);
		Shell shell = null;
		auto parShl = cast(Shell) parent;
		Composite contPane;
		if (parShl) {
			_sbshl = new SBShell(parShl, SWT.SHELL_TRIM);
			shell = _sbshl.shell;
			shell.setImage(prop.images.app);
			_win = shell;
			contPane = _sbshl.contentPane;
		} else {
			_win = new Composite(parent, SWT.NONE);
			contPane = _win;
		}
		_win.setData(new TLPData(this));
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
		contPane.setLayout(windowGridLayout(1, true));
		_prop = prop;
		static if (WithEventView) {
			_tabf = new CTabFolder(contPane, SWT.BORDER);
			_tabf.setLayoutData(new GridData(GridData.FILL_BOTH));
			if (cast(Area) area || cast(Battle) area) {
				_tabA = new CTabItem(_tabf, SWT.NONE);
				_tabA.setText(_prop.msgs.cardAndBackView);
			}
			_tabE = new CTabItem(_tabf, SWT.NONE);
			_tabE.setText(_prop.msgs.eventView);
			_tabf.addSelectionListener(new TabSel);

			if (cast(Area) area) {
				_tabA.setImage(_prop.images.areaSceneView);
				_tabE.setImage(_prop.images.areaEventTreeView);
			} else if (cast(Battle) area) {
				_tabA.setImage(_prop.images.battleSceneView);
				_tabE.setImage(_prop.images.battleEventTreeView);
			} else assert (0);
		}

		if (shell) {
			auto bar = new Menu(shell, SWT.BAR);

			auto mf = createMenu(_comm, bar, MenuID.File);
			static if (is(A : Area) && !WithEventView) {
				createMenuItem(_comm, mf, MenuID.EditEvent, &openEvent, null);
				new MenuItem(mf, SWT.SEPARATOR);
			} else static if (is(A : Battle) && !WithEventView) {
				auto itm = createMenuItem(_comm, mf, MenuID.EditEvent, &openEvent, null);
				itm.setImage(_prop.images.editEventBattle);
				new MenuItem(mf, SWT.SEPARATOR);
			}
			createMenuItem(_comm, mf, MenuID.CloseWin, &shell.close, null);

			auto me = createMenu(_comm, bar, MenuID.Edit);
			createMenuItem(_comm, me, MenuID.Undo, &this.undo, &_undo.canUndo);
			createMenuItem(_comm, me, MenuID.Redo, &this.redo, &_undo.canRedo);
			new MenuItem(me, SWT.SEPARATOR);
			createMenuItem(_comm, me, MenuID.Up, &up, &canUp);
			createMenuItem(_comm, me, MenuID.Down, &down, &canDown);
			new MenuItem(me, SWT.SEPARATOR);
			appendMenuTCPD(_comm, me, this, true, true, true, true, true);
			static if (WithEventView) {
				new MenuItem(me, SWT.SEPARATOR);
				createMenuItem(_comm, me, MenuID.Comment, &writeComment, &canWriteComment);
				new MenuItem(me, SWT.SEPARATOR);
				createMenuItem(_comm, me, MenuID.ToScript, &toScript, &canToScript);
				createMenuItem(_comm, me, MenuID.ToScriptAll, &toScriptAll, &canToScriptAll);
			}
			auto mv = createMenu(_comm, bar, MenuID.View);
			createMenuItem(_comm, mv, MenuID.Refresh, &refresh, null);

			shell.setMenuBar(bar);
		} else {
			putMenuAction(MenuID.Undo, &this.undo, &_undo.canUndo);
			putMenuAction(MenuID.Redo, &this.redo, &_undo.canRedo);
			putMenuAction(MenuID.Up, &up, &canUp);
			putMenuAction(MenuID.Down, &down, &canDown);
			appendMenuTCPD(_comm, this, this, true, true, true, true, true);
			static if (WithEventView) {
				putMenuAction(MenuID.Comment, &writeComment, &canWriteComment);
				putMenuAction(MenuID.ToScript, &toScript, &canToScript);
				putMenuAction(MenuID.ToScriptAll, &toScriptAll, &canToScriptAll);
			} else {
				putMenuAction(MenuID.EditEvent, &openEvent, null);
			}
			putMenuAction(MenuID.Refresh, &refresh, null);
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
				_aview.setLayoutData(new GridData(GridData.FILL_BOTH));
			}
			_tcpd ~= _aview;
			if (shell) _aview.setupMenu(shell.getMenuBar());
		}
		static if (WithEventView) {
			_eview = new EventView!(A, C, true)(comm, prop, summ, area, _tabf, _undo, _readOnly != SWT.NONE);
			_tabE.setControl(_eview);
			_tcpd ~= _eview;
		}
		__refreshTitle();

		if (shell) shell.pack();

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
			shell.setMaximized(winProps.maximized);
			scope wp = shell.computeSize(SWT.DEFAULT, SWT.DEFAULT);
			int width = winProps.width == SWT.DEFAULT ? wp.x : winProps.width;
			int height = winProps.height == SWT.DEFAULT ? wp.y : winProps.height;
			int x = winProps.x == SWT.DEFAULT ? shell.getBounds().x : winProps.x + areaWin.getBounds().x;
			int y = winProps.y == SWT.DEFAULT ? shell.getBounds().y : winProps.y + areaWin.getBounds().y;
			intoDisplay(x, y, width, height);
			shell.setBounds(x, y, width, height);
			_areaWin = areaWin;
		}
	}

	@property
	override
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
	@property
	override
	string title() {
		auto shl = cast(Shell) _win;
		static if (WithEventView) {
			if (shl) {
				return .tryFormat(_prop.msgs.viewName, .objName!A(_prop), _area.id, _area.name);
			}
			return .tryFormat(_prop.msgs.viewNameTab, .objName!A(_prop), _area.id, _area.name);
		} else {
			if (shl) {
				return .tryFormat(_prop.msgs.viewNameScene, .objName!A(_prop), _area.id, _area.name);
			}
			return .tryFormat(_prop.msgs.viewNameSceneTab, .objName!A(_prop), _area.id, _area.name);
		}
	}
	@property
	override
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
			if (!shell.getMaximized()) {
				winProps.width = shell.getSize().x;
				winProps.height = shell.getSize().y;
				if (_areaWin.isDisposed()) {
					winProps.x = shell.getBounds().x - _prop.var.areaWin.x;
					winProps.y = shell.getBounds().y - _prop.var.areaWin.y;
				} else {
					winProps.x = shell.getBounds().x - _areaWin.getBounds().x;
					winProps.y = shell.getBounds().y - _areaWin.getBounds().y;
				}
			}
			winProps.maximized = shell.getMaximized();
		}
	}
	@property
	override
	Composite shell() {
		return _win;
	}
	@property
	UndoManager undoManager() {
		return _undo;
	}
	@property
	V areaView() {
		return _aview;
	}

	/// Returns: 編集中のエリア。
	@property
	A eventTreeOwner() {
		return _area;
	}
	void undo() {_undo.undo();}
	void redo() {_undo.redo();}

	void openEvent() {
		_aview.openEvent();
	}

	static if (WithEventView) {
		@property
		EventView!(A, C, true) eventView() {
			_eview.initial();
			return _eview;
		}
		@property
		EventTreeView eventTreeView() {
			_eview.initial();
			return _eview.eventTreeView;
		}

		void selectSceneView() {
			_tabf.setSelection(_tabA);
			selectedTabImpl();
		}
		void selectEventView() {
			_tabf.setSelection(_tabE);
			selectedTabImpl();
		}

		private bool canToScript() {
			_eview.initial();
			return _eview.canToScript();
		}
		private bool canToScriptAll() {
			_eview.initial();
			return _eview.canToScriptAll();
		}
		private bool canWriteComment() {
			_eview.initial();
			return _eview.canWriteComment();
		}
		private void toScript() {
			_eview.initial();
			_eview.toScript();
		}
		private void toScriptAll() {
			_eview.initial();
			_eview.toScriptAll();
		}
		private void writeComment() {
			_eview.initial();
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
		void clone(SelectionEvent se) {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.clone(se);
				}
			}
		}
		@property
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
		@property
		bool canDoClone() {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) return c.canDoClone;
			}
			return false;
		}
	}
	override
	bool openCWXPath(string path, bool shellActivate) {
		auto cate = cpcategory(path);
		if (cpempty(path)) {
			return _aview.openCWXPath(path, shellActivate);
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
	@property
	override
	string[] openedCWXPath() {
		string[] r;
		static if (WithEventView) {
			_eview.initial();
			if (_tabf.getSelection() is _tabE) {
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
