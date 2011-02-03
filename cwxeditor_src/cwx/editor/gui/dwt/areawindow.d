
module cwx.editor.gui.dwt.areawindow;

import cwx.area;
import cwx.summary;
import cwx.skin;
import cwx.utils;
import cwx.path;

import cwx.editor.gui.dwt.areaview;
import cwx.editor.gui.dwt.eventview;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.undo;

import dwt.widgets.Shell;
import dwt.widgets.ToolBar;
import dwt.widgets.ToolItem;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.widgets.Composite;
import dwt.widgets.Label;
import dwt.custom.CTabFolder;
import dwt.custom.CTabItem;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.graphics.Image;
import dwt.events.DisposeEvent;
import dwt.events.DisposeListener;
import dwt.events.SelectionEvent;
import dwt.events.SelectionAdapter;

public:

class TAreaWindow(V, A, C) : TopLevelPanel, TCPD {
private:
	Commons _comm;

	CTabFolder _tabf;
	CTabItem _tabA;
	CTabItem _tabE;

	Composite _win;
	Label _status = null;
	Shell _areaWin = null;

	A _area;
	Props _prop;

	UndoManager _undo;

	V _aview;
	EventView!(A, C, true) _eview;

	TCPD[] _tcpd;

	void refresh() {
		_aview.refresh;
	}
	void up() {
		if (_tabA !is null && _tabf.getSelectionIndex == 0) {
			_aview.setFocus;
			_aview.up;
		} else {
			_eview.up;
		}
	}
	void down() {
		if (_tabA !is null && _tabf.getSelectionIndex == 0) {
			_aview.setFocus;
			_aview.down;
		} else {
			_eview.down;
		}
	}
	void saveScenario() {
		_comm.save.call(_win.getShell);
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
	class TabSel : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			if (_tabf.getSelection is _tabE) {
				_comm.statusLine(_win, _eview.statusLine);
				_eview.openToolWindow;
			} else {
				_comm.statusLine(_win, _aview.statusLine);
				_eview.closeToolWindow;
			}
		}
	}
public:
	this(Commons comm, Props prop, Summary summ, Composite parent, Shell areaWin, A area) {
		_comm = comm;
		_area = area;
		_undo = new UndoManager(1024);
		Shell shell = null;
		auto parShl = cast(Shell) parent;
		if (parShl) {
			shell = new Shell(parShl, DWT.SHELL_TRIM);
			shell.setImage = prop.images.app;
			_win = shell;
		} else {
			_win = new Composite(parent, DWT.NONE);
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
		_win.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				saveWin;
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
			}
		});
		_win.setLayout = windowGridLayout(1, true);
		_prop = prop;
		_tabf = new CTabFolder(_win, DWT.BORDER);
		_tabf.setLayoutData = new GridData(GridData.FILL_BOTH);
		if (cast(Area) area || cast(Battle) area) {
			_tabA = new CTabItem(_tabf, DWT.NONE);
			_tabA.setText = _prop.msgs.cardAndBackView;
		}
		_tabE = new CTabItem(_tabf, DWT.NONE);
		_tabE.setText = _prop.msgs.eventView;
		_tabf.addSelectionListener(new TabSel);

		if (shell) {
			auto bar = new Menu(shell, DWT.BAR);

			auto mf = createMenu(bar, _prop.msgs.menuFile);
			createMenuItem(mf, _prop.msgs.menuSave, _prop.images.menuSave, &saveScenario);
			new MenuItem(mf, DWT.SEPARATOR);
			createMenuItem(mf, _prop.msgs.menuCloseWin, _prop.images.menuCloseWin, &shell.close);

			auto me = createMenu(bar, _prop.msgs.menuEdit);
			createMenuItem(me, _prop.msgs.menuUndo, _prop.images.menuUndo, &undo);
			createMenuItem(me, _prop.msgs.menuRedo, _prop.images.menuRedo, &redo);
			new MenuItem(me, DWT.SEPARATOR);
			createMenuItem(me, _prop.msgs.menuUp, _prop.images.menuUp, &up);
			createMenuItem(me, _prop.msgs.menuDown, _prop.images.menuDown, &down);
			new MenuItem(me, DWT.SEPARATOR);
			appendMenuTCPD(_prop, me, this, true, true, true, true);

			auto mv = createMenu(bar, _prop.msgs.menuView);
			createMenuItem(mv, _prop.msgs.menuRefresh, _prop.images.menuRefresh, &refresh);

			shell.setMenuBar = bar;
		} else {
			putMenuAction(MenuID.Undo, &undo);
			putMenuAction(MenuID.Redo, &redo);
			putMenuAction(MenuID.Up, &up);
			putMenuAction(MenuID.Down, &down);
			appendMenuTCPD(_prop, this, this, true, true, true, true);
			putMenuAction(MenuID.Refresh, &refresh);
		}
		{
			_aview = new V(comm, prop, summ, area, _tabf, shell ? null : this, _undo);
			_tabA.setControl(_aview);
			_tcpd ~= _aview;
			if (shell) _aview.setupMenu(shell.getMenuBar);
		}
		{
			_eview = new EventView!(A, C, true)(comm, prop, summ, area, _tabf, _undo);
			_tabE.setControl(_eview);
			_tcpd ~= _eview;
			_aview.setCardFuncs(&_eview.removeCard, &_eview.appendCard, &_eview.renameCard,
				&_eview.upCard, &_eview.downCard);
		}
		if (shell) {
			_status = new Label(_win, DWT.NONE);
			_status.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		__refreshTitle;

		if (shell) shell.pack;

		static if (is(V == AreaView)) {
			auto winProps = _prop.var.areaWin;
		} else static if (is(V == BattleView)) {
			auto winProps = _prop.var.battleWin;
		} else {
			static assert (0);
		}
		if (shell) {
			scope wp = shell.computeSize(DWT.DEFAULT, DWT.DEFAULT);
			int width = winProps.width == DWT.DEFAULT ? wp.x : winProps.width;
			int height = winProps.height == DWT.DEFAULT ? wp.y : winProps.height;
			int x = winProps.x == DWT.DEFAULT ? shell.getBounds.x : winProps.x + areaWin.getBounds.x;
			int y = winProps.y == DWT.DEFAULT ? shell.getBounds.y : winProps.y + areaWin.getBounds.y;
			intoDisplay(x, y, width, height);
			shell.setBounds(x, y, width, height);
			shell.setMaximized = winProps.maximized;
			_areaWin = areaWin;
		}

		_eview.refresh(_tabf.getSelection is _tabE);
	}

	Image image() {
		static if (is (A == Area)) {
			return _prop.images.area;
		} else static if (is (A == Battle)) {
			return _prop.images.battle;
		} else {
			static assert (0);
		}
	}
	string title() {
		auto shl = cast(Shell) _win;
		static if (is (A == Area)) {
			if (shl) {
				return _prop.msgs.areaViewName(_area.id, _area.name);
			}
			return _prop.msgs.areaViewNameTab(_area.id, _area.name);
		} else static if (is (A == Battle)) {
			if (shl) {
				return _prop.msgs.battleViewName(_area.id, _area.name);
			}
			return _prop.msgs.battleViewNameTab(_area.id, _area.name);
		} else {
			static assert (0);
		}
	}
	Label statusText() {return _status;}

	private void saveWin() {
		static if (is(V == AreaView)) {
			auto winProps = _prop.var.areaWin;
		} else static if (is(V == BattleView)) {
			auto winProps = _prop.var.battleWin;
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

	/// Returns: 編集中のエリア。
	A eventTreeOwner() {
		return _area;
	}
	void undo() {_undo.undo;}
	void redo() {_undo.redo;}
	override {
		void cut(int stateMask) {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.cut(stateMask);
				}
			}
		}
		void copy(int stateMask) {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.copy(stateMask);
				}
			}
		}
		void paste(int stateMask) {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.paste(stateMask);
				}
			}
		}
		void del(int stateMask) {
			foreach (c; _tcpd) {
				if (c.canDoTCPD) {
					c.del(stateMask);
				}
			}
		}
		bool canDoTCPD() {
			return .hasFocus(_win);
		}
	}
	bool openCWXPath(string path) {
		auto cate = cpcategory(path);
		if (path == "") {
			_tabf.setSelection = _tabA;
			return true;
		} else if (((cate == "menucard" || cate == "enemycard")
				&& cpbottom(path) == "")
				|| cate == "background") {
			return _aview.openCWXPath(path);
		} else {
			return _eview.openCWXPath(path);
		}
	}
}

alias TAreaWindow!(AreaView, Area, MenuCard) AreaWindow;
alias TAreaWindow!(BattleView, Battle, EnemyCard) BattleWindow;
