
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
import dwt.widgets.TabFolder;
import dwt.widgets.TabItem;
import dwt.widgets.ToolBar;
import dwt.widgets.ToolItem;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.widgets.Composite;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.graphics.Image;
import dwt.events.DisposeEvent;
import dwt.events.DisposeListener;
import dwt.events.SelectionEvent;
import dwt.events.SelectionAdapter;

public:

class TAreaWindow(V, A, C) : TCPD {
private:
	Commons _comm;

	TabFolder _tabf;
	TabItem _tabA;
	TabItem _tabE;

	Shell _win;
	Shell _areaWin;

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
	void areaViewSetFocus() {
		_tabf.setSelection(_tabA);
		_eview.closeToolWindow;
		_aview.setFocus;
	}
	void saveScenario() {
		_comm.save.call(_win);
	}
	void __deleteArea(A area) {
		if (_area is area) {
			_win.close;
		}
	}
	void __refArea(A area) {
		if (_area is area) {
			__refreshTitle;
		}
	}
	void __refreshTitle() {
		static if (is (A == Area)) {
			_win.setText = _prop.msgs.areaViewName(_area.id, _area.name);
		} else static if (is (A == Battle)) {
			_win.setText = _prop.msgs.battleViewName(_area.id, _area.name);
		} else {
			static assert (0);
		}
	}
public:
	this(Commons comm, Props prop, Summary summ, Shell parent, Shell areaWin, A area) {
		_comm = comm;
		_area = area;
		_undo = new UndoManager(1024);
		_win = new Shell(parent, DWT.SHELL_TRIM);
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
		_win.setImage = prop.images.app;
		_win.setLayout = windowGridLayout(1, true);
		_prop = prop;
		_tabf = new TabFolder(_win, DWT.NONE);
		_tabf.setLayoutData = new GridData(GridData.FILL_BOTH);
		if (cast(Area) area || cast(Battle) area) {
			_tabA = new TabItem(_tabf, DWT.NONE);
			_tabA.setText = _prop.msgs.cardAndBackView;
		}
		_tabE = new TabItem(_tabf, DWT.NONE);
		_tabE.setText = _prop.msgs.eventView;
		_tabf.addSelectionListener(new class SelectionAdapter {
			override void widgetSelected(SelectionEvent e) {
				if (_tabf.getSelection[0] is _tabE) {
					_eview.openToolWindow;
				} else {
					_eview.closeToolWindow;
				}
			}
		});

		auto bar = new Menu(_win, DWT.BAR);
		{
			auto mf = createMenu(bar, _prop.msgs.menuFile);
			createMenuItem(mf, _prop.msgs.menuSave, _prop.images.menuSave, &saveScenario);
			new MenuItem(mf, DWT.SEPARATOR);
			createMenuItem(mf, _prop.msgs.menuCloseWin, _prop.images.menuCloseWin, &_win.close);

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

			_win.setMenuBar = bar;
		}
		{
			_aview = new V(comm, prop, summ, area, _tabf, _undo);
			_tabA.setControl(_aview);
			_tcpd ~= _aview;
			_aview.setupMenu(bar, &areaViewSetFocus);
		}
		{
			_eview = new EventView!(A, C, true)(comm, prop, summ, area, _tabf, _undo);
			_tabE.setControl(_eview);
			_tcpd ~= _eview;
			_aview.setCardFuncs(&_eview.removeCard, &_eview.appendCard, &_eview.renameCard,
				&_eview.upCard, &_eview.downCard);
		}
		__refreshTitle;

		_win.pack;

		static if (is(V == AreaView)) {
			auto winProps = _prop.var.areaWin;
		} else static if (is(V == BattleView)) {
			auto winProps = _prop.var.battleWin;
		} else {
			static assert (0);
		}
		scope wp = _win.computeSize(DWT.DEFAULT, DWT.DEFAULT);
		int width = winProps.width == DWT.DEFAULT ? wp.x : winProps.width;
		int height = winProps.height == DWT.DEFAULT ? wp.y : winProps.height;
		int x = winProps.x == DWT.DEFAULT ? _win.getBounds.x : winProps.x + areaWin.getBounds.x;
		int y = winProps.y == DWT.DEFAULT ? _win.getBounds.y : winProps.y + areaWin.getBounds.y;
		intoDisplay(x, y, width, height);
		_win.setBounds(x, y, width, height);
		_win.setMaximized = winProps.maximized;
		_areaWin = areaWin;

		_eview.refresh(_tabf.getSelection[0] is _tabE);
	}
	private void saveWin() {
		static if (is(V == AreaView)) {
			auto winProps = _prop.var.areaWin;
		} else static if (is(V == BattleView)) {
			auto winProps = _prop.var.battleWin;
		} else {
			static assert (0);
		}
		if (!_win.getMaximized) {
			winProps.width = _win.getSize.x;
			winProps.height = _win.getSize.y;
			if (_areaWin.isDisposed) {
				winProps.x = _win.getBounds.x - _prop.var.areaWin.x;
				winProps.y = _win.getBounds.y - _prop.var.areaWin.y;
			} else {
				winProps.x = _win.getBounds.x - _areaWin.getBounds.x;
				winProps.y = _win.getBounds.y - _areaWin.getBounds.y;
			}
		}
		winProps.maximized = _win.getMaximized;
	}
	Shell shell() {
		return _win;
	}

	/// Returns: 編集中のエリア。
	A eventTreeOwner() {
		return _area;
	}
	void undo() {_undo.undo;}
	void redo() {_undo.redo;}
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
	bool openCWXPath(string path) {
		if (path == "" || (is(A : Area) && cpcategory(path) == "background")) {
			_tabf.setSelection = _tabA;
			return true;
		} else {
			return _eview.openCWXPath(path);
		}
	}
}

alias TAreaWindow!(AreaView, Area, MenuCard) AreaWindow;
alias TAreaWindow!(BattleView, Battle, EnemyCard) BattleWindow;
