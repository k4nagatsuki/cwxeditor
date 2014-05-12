
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

	void refresh() { mixin(S_TRACE);
		_aview.refresh();
	}
	@property
	bool canUp() { mixin(S_TRACE);
		static if (WithEventView) {
			if (_tabA !is null && _tabf.getSelectionIndex() == 0) { mixin(S_TRACE);
				return _aview.canUp;
			} else { mixin(S_TRACE);
				return _eview.canUp;
			}
		} else { mixin(S_TRACE);
			return _aview.canUp;
		}
	}
	@property
	bool canDown() { mixin(S_TRACE);
		static if (WithEventView) {
			if (_tabA !is null && _tabf.getSelectionIndex() == 0) { mixin(S_TRACE);
				return _aview.canDown;
			} else { mixin(S_TRACE);
				return _eview.canDown;
			}
		} else { mixin(S_TRACE);
			return _aview.canDown;
		}
	}
	void up() { mixin(S_TRACE);
		static if (WithEventView) {
			if (_tabA !is null && _tabf.getSelectionIndex() == 0) { mixin(S_TRACE);
				_aview.setFocus();
				_aview.up();
			} else { mixin(S_TRACE);
				_eview.up();
			}
		} else { mixin(S_TRACE);
			_aview.up();
		}
	}
	void down() { mixin(S_TRACE);
		static if (WithEventView) {
			if (_tabA !is null && _tabf.getSelectionIndex() == 0) { mixin(S_TRACE);
				_aview.setFocus();
				_aview.down();
			} else { mixin(S_TRACE);
				_eview.down();
			}
		} else { mixin(S_TRACE);
			_aview.down();
		}
	}
	void __deleteArea(A area) { mixin(S_TRACE);
		if (_area is area) { mixin(S_TRACE);
			_comm.close(_win);
		}
	}
	void __refArea(A area) { mixin(S_TRACE);
		if (_area is area) { mixin(S_TRACE);
			__refreshTitle();
		}
	}
	void __refreshTitle() { mixin(S_TRACE);
		_comm.setTitle(_win, title);
	}
	static if (WithEventView) {
		void selectedTabImpl() { mixin(S_TRACE);
			if (_tabf.getSelection() is _tabE) { mixin(S_TRACE);
				_eview.initial();
				_comm.setStatusLine(_win, _eview.statusLine);
				_eview.openToolWindow();
			} else { mixin(S_TRACE);
				_comm.setStatusLine(_win, _aview.statusLine);
			}
			_comm.refreshToolBar();
		}
		class TabSel : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				selectedTabImpl();
			}
		}
	}
	bool _refUndo = false;
	void refUndoMax() { mixin(S_TRACE);
		if (!_refUndo) return;
		_undo.max = _prop.var.etc.undoMaxEvent;
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
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
			} else { mixin(S_TRACE);
				static assert (0);
			}
			_comm.replText.remove(&__refreshTitle);
			_comm.refUndoMax.remove(&refUndoMax);
		}
	}
public:
	this(Commons comm, Props prop, Summary summ, Composite parent, Shell areaWin, A area, UndoManager undo = null, bool readOnly = false) { mixin(S_TRACE);
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
		if (parShl) { mixin(S_TRACE);
			_sbshl = new SBShell(parShl, SWT.SHELL_TRIM);
			shell = _sbshl.shell;
			shell.setImages(_prop.images.icon);
			_win = shell;
			contPane = _sbshl.contentPane;
		} else { mixin(S_TRACE);
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
		} else { mixin(S_TRACE);
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
			if (cast(Area) area || cast(Battle) area) { mixin(S_TRACE);
				_tabA = new CTabItem(_tabf, SWT.NONE);
				_tabA.setText(_prop.msgs.cardAndBackView);
			}
			_tabE = new CTabItem(_tabf, SWT.NONE);
			_tabE.setText(_prop.msgs.eventView);
			_tabf.addSelectionListener(new TabSel);

			if (cast(Area) area) { mixin(S_TRACE);
				_tabA.setImage(_prop.images.areaSceneView);
				_tabE.setImage(_prop.images.areaEventTreeView);
			} else if (cast(Battle) area) { mixin(S_TRACE);
				_tabA.setImage(_prop.images.battleSceneView);
				_tabE.setImage(_prop.images.battleEventTreeView);
			} else assert (0);
		}

		{ mixin(S_TRACE);
			static if (WithEventView) {
				auto pane = _tabf;
			} else { mixin(S_TRACE);
				auto pane = contPane;
			}
			_aview = new V(comm, prop, summ, area, pane, shell ? null : this, _undo, _readOnly != SWT.NONE);
			static if (WithEventView) {
				_tabA.setControl(_aview);
			} else { mixin(S_TRACE);
				_aview.setLayoutData(new GridData(GridData.FILL_BOTH));
			}
			if (shell) _aview.setupMenu(shell.getMenuBar());
		}
		static if (WithEventView) {
			_eview = new EventView!(A, C, true)(comm, prop, summ, area, _tabf, _undo, _readOnly != SWT.NONE);
			_tabE.setControl(_eview);
		}
		__refreshTitle();

		if (shell) { mixin(S_TRACE);
			auto bar = new Menu(shell, SWT.BAR);

			auto mf = createMenu(_comm, bar, MenuID.File);
			static if (is(A : Area) && !WithEventView) {
				createMenuItem(_comm, mf, MenuID.EditEvent, () => openEvent(false), null);
				new MenuItem(mf, SWT.SEPARATOR);
			} else static if (is(A : Battle) && !WithEventView) {
				auto itm = createMenuItem(_comm, mf, MenuID.EditEvent, () => openEvent(false), null);
				itm.setImage(_prop.images.editEventBattle);
				new MenuItem(mf, SWT.SEPARATOR);
			}
			createMenuItem(_comm, mf, MenuID.CloseWin, &shell.close, null);

			auto me = createMenu(_comm, bar, MenuID.Edit);
			if (!_readOnly) { mixin(S_TRACE);
				createMenuItem(_comm, me, MenuID.Undo, &this.undo, &_undo.canUndo);
				createMenuItem(_comm, me, MenuID.Redo, &this.redo, &_undo.canRedo);
				new MenuItem(me, SWT.SEPARATOR);
				createMenuItem(_comm, me, MenuID.Up, &up, &canUp);
				createMenuItem(_comm, me, MenuID.Down, &down, &canDown);
				new MenuItem(me, SWT.SEPARATOR);
				appendMenuTCPD(_comm, me, this, true, true, true, true, true);
			} else { mixin(S_TRACE);
				appendMenuTCPD(_comm, me, this, false, true, false, false, false);
			}
			static if (WithEventView) {
				if (!_readOnly) { mixin(S_TRACE);
					new MenuItem(me, SWT.SEPARATOR);
					createMenuItem(_comm, me, MenuID.Comment, &writeComment, &canWriteComment);
				}
				new MenuItem(me, SWT.SEPARATOR);
				createMenuItem(_comm, me, MenuID.ToScript, &toScript, &canToScript);
				createMenuItem(_comm, me, MenuID.ToScriptAll, &toScriptAll, &canToScriptAll);
			}
			auto mv = createMenu(_comm, bar, MenuID.View);
			createMenuItem(_comm, mv, MenuID.Refresh, &refresh, null);

			shell.setMenuBar(bar);
		} else { mixin(S_TRACE);
			putMenuAction(MenuID.Undo, &this.undo, &_undo.canUndo);
			putMenuAction(MenuID.Redo, &this.redo, &_undo.canRedo);
			putMenuAction(MenuID.Up, &up, &canUp);
			putMenuAction(MenuID.Down, &down, &canDown);
			appendMenuTCPD(_comm, this, this, true, true, true, true, true);
			static if (WithEventView) {
				putMenuAction(MenuID.Comment, &writeComment, &canWriteComment);
				putMenuAction(MenuID.ToScript, &toScript, &canToScript);
				putMenuAction(MenuID.ToScript1Content, &toScript1Content, &canToScript);
				putMenuAction(MenuID.ToScriptAll, &toScriptAll, &canToScriptAll);
				putMenuAction(MenuID.StartToPackage, &startToPackage, &canStartToPackage);
				putMenuAction(MenuID.WrapTree, &wrapTree, &canWrapTree);
				putMenuAction(MenuID.FindID, &findStartUsers, &canFindStartUsers);
			} else { mixin(S_TRACE);
				putMenuAction(MenuID.EditEvent, () => openEvent(false), null);
			}
			putMenuAction(MenuID.EditSceneDup, () => openDup(), null);
			putMenuAction(MenuID.EditEventDup, () => openEvent(true), null);
			putMenuAction(MenuID.Refresh, &refresh, null);
			putMenuAction(MenuID.EditProp, &edit, &canEdit);
			static if (WithEventView) {
				putMenuAction(MenuID.Cut1Content, &_eview.cut1Content, () => _tabf.getSelection() is _tabE && _eview.canCut1Content);
				putMenuAction(MenuID.Copy1Content, &_eview.copy1Content, () => _tabf.getSelection() is _tabE && _eview.canCopy1Content);
				putMenuAction(MenuID.Delete1Content, &_eview.del1Content, () => _tabf.getSelection() is _tabE && _eview.canDel1Content);
				putMenuAction(MenuID.PasteInsert, &_eview.pasteInsert, () => _tabf.getSelection() is _tabE && _eview.canPasteInsert);
				putMenuAction(MenuID.SwapToParent, &_eview.swapToParent, () => _tabf.getSelection() is _tabE && &_eview.canSwapToParent);
				putMenuAction(MenuID.SwapToChild, &_eview.swapToChild, () => _tabf.getSelection() is _tabE && &_eview.canSwapToChild);
			}
		}

		void closeAdds(Summary summ) { mixin(S_TRACE);
			if (_summ is summ) _comm.close(_win);
		}
		_comm.closeAdds.add(&closeAdds);
		.listener(_win, SWT.Dispose, () => _comm.closeAdds.remove(&closeAdds));

		if (shell) shell.pack();

		static if (is(V == AreaView)) {
			static if (WithEventView) {
				auto winProps = _prop.var.areaWin;
			} else { mixin(S_TRACE);
				auto winProps = _prop.var.areaSceneWin;
			}
		} else static if (is(V == BattleView)) {
			static if (WithEventView) {
				auto winProps = _prop.var.battleWin;
			} else { mixin(S_TRACE);
				auto winProps = _prop.var.battleSceneWin;
			}
		} else { mixin(S_TRACE);
			static assert (0);
		}
		if (shell) { mixin(S_TRACE);
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
	Image image() { mixin(S_TRACE);
		static if (is (A == Area)) {
			static if (WithEventView) {
				return _prop.images.area;
			} else { mixin(S_TRACE);
				return _prop.images.areaSceneView;
			}
		} else static if (is (A == Battle)) {
			static if (WithEventView) {
				return _prop.images.battle;
			} else { mixin(S_TRACE);
				return _prop.images.battleSceneView;
			}
		} else { mixin(S_TRACE);
			static assert (0);
		}
	}
	@property
	override
	string title() { mixin(S_TRACE);
		auto shl = cast(Shell) _win;
		static if (WithEventView) {
			if (shl) { mixin(S_TRACE);
				return .tryFormat(_prop.msgs.viewName, .objName!A(_prop), _area.id, _area.name);
			}
			return .tryFormat(_prop.msgs.viewNameTab, .objName!A(_prop), _area.id, _area.name);
		} else { mixin(S_TRACE);
			if (shl) { mixin(S_TRACE);
				return .tryFormat(_prop.msgs.viewNameScene, .objName!A(_prop), _area.id, _area.name);
			}
			return .tryFormat(_prop.msgs.viewNameSceneTab, .objName!A(_prop), _area.id, _area.name);
		}
	}
	@property
	override
	void delegate(string) statusText() {return _sbshl ? &_sbshl.statusLine : null;}

	private void saveWin() { mixin(S_TRACE);
		static if (is(V == AreaView)) {
			static if (WithEventView) {
				auto winProps = _prop.var.areaWin;
			} else { mixin(S_TRACE);
				auto winProps = _prop.var.areaSceneWin;
			}
		} else static if (is(V == BattleView)) {
			static if (WithEventView) {
				auto winProps = _prop.var.battleWin;
			} else { mixin(S_TRACE);
				auto winProps = _prop.var.battleSceneWin;
			}
		} else { mixin(S_TRACE);
			static assert (0);
		}
		auto shell = cast(Shell) _win;
		if (shell) { mixin(S_TRACE);
			if (!shell.getMaximized()) { mixin(S_TRACE);
				winProps.width = shell.getSize().x;
				winProps.height = shell.getSize().y;
				if (_areaWin.isDisposed()) { mixin(S_TRACE);
					winProps.x = shell.getBounds().x - _prop.var.areaWin.x;
					winProps.y = shell.getBounds().y - _prop.var.areaWin.y;
				} else { mixin(S_TRACE);
					winProps.x = shell.getBounds().x - _areaWin.getBounds().x;
					winProps.y = shell.getBounds().y - _areaWin.getBounds().y;
				}
			}
			winProps.maximized = shell.getMaximized();
		}
	}
	@property
	override
	Composite shell() { mixin(S_TRACE);
		return _win;
	}
	@property
	UndoManager undoManager() { mixin(S_TRACE);
		return _undo;
	}
	@property
	V areaView() { mixin(S_TRACE);
		return _aview;
	}

	/// Returns: 編集中のエリア。
	@property
	A eventTreeOwner() { mixin(S_TRACE);
		return _area;
	}
	void undo() {_undo.undo();}
	void redo() {_undo.redo();}

	void openEvent(bool canDuplicate) { mixin(S_TRACE);
		_aview.openEvent(canDuplicate);
	}
	void openDup() { mixin(S_TRACE);
		_aview.openDup();
	}

	static if (WithEventView) {
		@property
		EventView!(A, C, true) eventView() { mixin(S_TRACE);
			_eview.initial();
			return _eview;
		}
		@property
		EventTreeView eventTreeView() { mixin(S_TRACE);
			_eview.initial();
			return _eview.eventTreeView;
		}

		void selectSceneView() { mixin(S_TRACE);
			_tabf.setSelection(_tabA);
			selectedTabImpl();
		}
		void selectEventView() { mixin(S_TRACE);
			_tabf.setSelection(_tabE);
			selectedTabImpl();
		}

		private bool canToScript() { mixin(S_TRACE);
			_eview.initial();
			return _eview.canToScript();
		}
		private bool canToScriptAll() { mixin(S_TRACE);
			_eview.initial();
			return _eview.canToScriptAll();
		}
		private bool canWriteComment() { mixin(S_TRACE);
			_eview.initial();
			return _eview.canWriteComment();
		}
		private bool canStartToPackage() { mixin(S_TRACE);
			_eview.initial();
			return _eview.canStartToPackage();
		}
		private bool canWrapTree() { mixin(S_TRACE);
			_eview.initial();
			return _eview.canWrapTree();
		}
		private bool canFindStartUsers() { mixin(S_TRACE);
			_eview.initial();
			return _eview.canFindStartUsers();
		}
		private void toScript() { mixin(S_TRACE);
			_eview.initial();
			_eview.toScript();
		}
		private void toScript1Content() { mixin(S_TRACE);
			_eview.initial();
			_eview.toScript1Content();
		}
		private void toScriptAll() { mixin(S_TRACE);
			_eview.initial();
			_eview.toScriptAll();
		}
		private void writeComment() { mixin(S_TRACE);
			_eview.initial();
			_eview.writeComment();
		}
		private void startToPackage() { mixin(S_TRACE);
			_eview.initial();
			_eview.startToPackage();
		}
		private void wrapTree() { mixin(S_TRACE);
			_eview.initial();
			_eview.wrapTree();
		}
		private void findStartUsers() { mixin(S_TRACE);
			_eview.initial();
			_eview.findStartUsers();
		}
		private void edit() { mixin(S_TRACE);
			if (_tabf.getSelection() is _tabA) {
				_aview.edit();
			} else {
				_aview.edit();
			}
		}
		@property
		private bool canEdit() { mixin(S_TRACE);
			if (_tabf.getSelection() is _tabA) {
				return _aview.canEdit;
			} else {
				return _eview.canEdit;
			}
		}
	} else {
		private void edit() { _aview.edit(); }
		@property
		private bool canEdit() { return _aview.canEdit; }
	}

	@property
	private TCPD tcpd() { mixin(S_TRACE);
		static if (WithEventView) {
			if (_tabf.getSelection() is _tabA) { mixin(S_TRACE);
				return _aview;
			} else { mixin(S_TRACE);
				assert (_tabf.getSelection() is _tabE);
				return _eview;
			}
		} else {
			return _aview;
		}
	}
	override {
		void cut(SelectionEvent se) { mixin(S_TRACE);
			if (tcpd.canDoTCPD) { mixin(S_TRACE);
				tcpd.cut(se);
			}
		}
		void copy(SelectionEvent se) { mixin(S_TRACE);
			if (tcpd.canDoTCPD) { mixin(S_TRACE);
				tcpd.copy(se);
			}
		}
		void paste(SelectionEvent se) { mixin(S_TRACE);
			if (tcpd.canDoTCPD) { mixin(S_TRACE);
				tcpd.paste(se);
			}
		}
		void del(SelectionEvent se) { mixin(S_TRACE);
			if (tcpd.canDoTCPD) { mixin(S_TRACE);
				tcpd.del(se);
			}
		}
		void clone(SelectionEvent se) { mixin(S_TRACE);
			if (tcpd.canDoTCPD) { mixin(S_TRACE);
				tcpd.clone(se);
			}
		}
		@property
		bool canDoTCPD() { mixin(S_TRACE);
			return .hasFocus(_win);
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			return tcpd.canDoTCPD && tcpd.canDoT;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			return tcpd.canDoTCPD && tcpd.canDoC;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			return tcpd.canDoTCPD && tcpd.canDoP;
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			return tcpd.canDoTCPD && tcpd.canDoD;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			return tcpd.canDoTCPD && tcpd.canDoClone;
		}
	}
	override
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		auto cate = cpcategory(path);
		if (cpempty(path)) { mixin(S_TRACE);
			return _aview.openCWXPath(path, shellActivate);
		} else if (cphasattr(path, "eventview")) { mixin(S_TRACE);
			static if (WithEventView) {
				_eview.initial();
				return _eview.openCWXPath(path, shellActivate);
			}
		} else if (((cate == "menucard" || cate == "enemycard")
				&& cpempty(cpbottom(path)))
				|| cate == "background") { mixin(S_TRACE);
			return _aview.openCWXPath(path, shellActivate);
		} else { mixin(S_TRACE);
			static if (WithEventView) {
				_eview.initial();
				return _eview.openCWXPath(path, shellActivate);
			}
		}
		return false;
	}
	@property
	override
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		static if (WithEventView) {
			_eview.initial();
			if (_tabf.getSelection() is _tabE) { mixin(S_TRACE);
				r ~= _aview.openedCWXPath;
				r ~= _eview.openedCWXPath;
			} else { mixin(S_TRACE);
				r ~= _eview.openedCWXPath;
				r ~= _aview.openedCWXPath;
			}
		} else { mixin(S_TRACE);
			r ~= _aview.openedCWXPath;
		}
		return r;
	}
}

alias TAreaWindow!(AreaView, Area, MenuCard, true) AreaWindow;
alias TAreaWindow!(AreaView, Area, MenuCard, false) AreaSceneWindow;
alias TAreaWindow!(BattleView, Battle, EnemyCard, true) BattleWindow;
alias TAreaWindow!(BattleView, Battle, EnemyCard, false) BattleSceneWindow;
