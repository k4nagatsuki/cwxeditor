
module cwx.editor.gui.dwt.eventwindow;

import cwx.area;
import cwx.card;
import cwx.event;
import cwx.summary;
import cwx.skin;
import cwx.utils;
import cwx.path;
import cwx.types;
import cwx.menu;

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.eventview;
import cwx.editor.gui.dwt.eventtreeview;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.sbshell;
import cwx.editor.gui.dwt.dmenu;

import std.conv;

import org.eclipse.swt.all;

interface IEventWindow {
	@property
	EventTreeView eventTreeView();
}

class EventWindow(A : EventTreeOwner) : TopLevelPanel, IEventWindow, SashPanel, TCPD {
private:
	Summary _summ;
	A _eto;
	Commons _comm;
	Props _prop;
	UndoManager _undo;

	SBShell _sbshl;
	Composite _win;
	Shell _parent2 = null;

	static if (is(A : Area)) {
		EventView!(A, MenuCard, true) _eview;
	} else static if (is(A : Battle)) {
		EventView!(A, EnemyCard, true) _eview;
	} else {
		EventView!(A, void, false) _eview;
	}

	bool _refUndo = false;
	void refUndoMax() {
		if (!_refUndo) return;
		_undo.max = _prop.var.etc.undoMaxEvent;
	}
public:
	this (Commons comm, Props prop, Summary summ, Composite parent, Shell parent2, A eto, UndoManager undo) {
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
		contPane.setLayout(windowGridLayout(1, true));
		_prop = prop;
		_summ = summ;
		_eto = eto;
		_comm = comm;
		_refUndo = undo is null;
		_undo = undo ? undo : new UndoManager(_prop.var.etc.undoMaxEvent);

		static if (is (A == Area)) {
			_comm.delArea.add(&__deleteOwner);
			_comm.refArea.add(&__refOwner);
		} else static if (is (A == Battle)) {
			_comm.delBattle.add(&__deleteOwner);
			_comm.refBattle.add(&__refOwner);
		} else static if (is (A == Package)) {
			_comm.delPackage.add(&__deleteOwner);
			_comm.refPackage.add(&__refOwner);
		} else static if (is (A == SkillCard)) {
			_comm.delSkill.add(&__deleteOwner);
			_comm.refSkill.add(&__refOwner);
		} else static if (is (A == ItemCard)) {
			_comm.delItem.add(&__deleteOwner);
			_comm.refItem.add(&__refOwner);
		} else static if (is (A == BeastCard)) {
			_comm.delBeast.add(&__deleteOwner);
			_comm.refBeast.add(&__refOwner);
		} else {
			static assert (0);
		}
		_comm.replText.add(&__refreshTitle);
		_comm.refUndoMax.add(&refUndoMax);
		_win.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				saveWin();
						static if (is (A == Area)) {
					_comm.delArea.remove(&__deleteOwner);
					_comm.refArea.remove(&__refOwner);
				} else static if (is (A == Battle)) {
					_comm.delBattle.remove(&__deleteOwner);
					_comm.refBattle.remove(&__refOwner);
				} else static if (is (A == Package)) {
					_comm.delPackage.remove(&__deleteOwner);
					_comm.refPackage.remove(&__refOwner);
				} else static if (is (A == SkillCard)) {
					_comm.delSkill.remove(&__deleteOwner);
					_comm.refSkill.remove(&__refOwner);
				} else static if (is (A == ItemCard)) {
					_comm.delItem.remove(&__deleteOwner);
					_comm.refItem.remove(&__refOwner);
				} else static if (is (A == BeastCard)) {
					_comm.delBeast.remove(&__deleteOwner);
					_comm.refBeast.remove(&__refOwner);
				} else {
					static assert (0);
				}
				_comm.replText.remove(&__refreshTitle);
				_comm.refUndoMax.remove(&refUndoMax);
			}
		});
		{
			_eview = new typeof(_eview)(comm, prop, summ, eto, contPane, _undo);
			_eview.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		if (shell) {
			auto bar = new Menu(shell, SWT.BAR);

			auto mf = createMenu(_comm, bar, MenuID.File);
			static if (is(A : Area)) {
				createMenuItem(_comm, mf, MenuID.EditScene, &openScene, null);
				new MenuItem(mf, SWT.SEPARATOR);
			} else static if (is(A : Battle)) {
				createMenuItem(_comm, mf, MenuID.EditScene, &openScene, null);
				new MenuItem(mf, SWT.SEPARATOR);
			}
			createMenuItem(_comm, mf, MenuID.CloseWin, &shell.close, null);

			auto me = createMenu(_comm, bar, MenuID.Edit);
			createMenuItem(_comm, me, MenuID.Undo, &_eview.undo, &_undo.canUndo);
			createMenuItem(_comm, me, MenuID.Redo, &_eview.redo, &_undo.canRedo);
			new MenuItem(me, SWT.SEPARATOR);
			createMenuItem(_comm, me, MenuID.Up, &_eview.up, &_eview.canUp);
			createMenuItem(_comm, me, MenuID.Down, &_eview.down, &_eview.canDown);
			new MenuItem(me, SWT.SEPARATOR);
			appendMenuTCPD(_comm, me, this, true, true, true, true, true);
			new MenuItem(me, SWT.SEPARATOR);
			createMenuItem(_comm, me, MenuID.Comment, &_eview.writeComment, &_eview.canWriteComment);
			new MenuItem(me, SWT.SEPARATOR);
			createMenuItem(_comm, me, MenuID.ToScript, &_eview.toScript, &_eview.canToScript);
			createMenuItem(_comm, me, MenuID.ToScriptAll, &_eview.toScriptAll, &_eview.canToScriptAll);

			shell.setMenuBar(bar);
		} else {
			appendMenuTCPD(_comm, this, this, true, true, true, true, true);
			static if (is(A : Area) || is(A : Battle)) {
				putMenuAction(MenuID.EditScene, &openScene, null);
			}
			putMenuAction(MenuID.Undo, &_eview.undo, &_undo.canUndo);
			putMenuAction(MenuID.Redo, &_eview.redo, &_undo.canRedo);
			putMenuAction(MenuID.Up, &_eview.up, &_eview.canUp);
			putMenuAction(MenuID.Down, &_eview.down, &_eview.canDown);
			putMenuAction(MenuID.Comment, &_eview.writeComment, &_eview.canWriteComment);
			putMenuAction(MenuID.ToScript, &_eview.toScript, &_eview.canToScript);
			putMenuAction(MenuID.ToScriptAll, &_eview.toScriptAll, &_eview.canToScriptAll);
		}

		if (shell) {
			static if (is(A == Area)) {
				auto winProps = _prop.var.areaEventWin;
			} else static if (is(A == Battle)) {
				auto winProps = _prop.var.battleEventWin;
			} else static if (is(A == Package)) {
				auto winProps = _prop.var.packageWin;
			} else static if (is(A : EffectCard)) {
				auto winProps = _prop.var.cardEventWin;
			} else {
				static assert (0);
			}
			shell.setMaximized(winProps.maximized);
			int width = winProps.width;
			int height = winProps.height;
			int x = winProps.x == SWT.DEFAULT ? shell.getBounds().x : winProps.x + parent2.getBounds().x;
			int y = winProps.y == SWT.DEFAULT ? shell.getBounds().y : winProps.y + parent2.getBounds().y;
			intoDisplay(x, y, width, height);
			shell.setBounds(x, y, width, height);
			_parent2 = parent2;
		}

		auto d = contPane.getDisplay();
		auto tl = new class Listener {
			override void handleEvent(Event e) {
				auto tabf = cast(CTabFolder) contPane.getParent();
				if (!tabf) return;
				if (eventTreeView.eventTree && contPane is tabf.getSelection().getControl()) {
					_eview.openToolWindow();
				} else {
					_eview.closeToolWindow();
				}
			}
		};
		d.addFilter(SWT.FocusIn, tl);
		.listener(contPane, SWT.Dispose, {
			d.removeFilter(SWT.FocusIn, tl);
		});

		_eview.refresh();
		__refreshTitle();
	}
	private void saveWin() {
		static if (is(A == Area)) {
			auto winProps = _prop.var.areaEventWin;
			auto parentProps = _prop.var.dataWin;
		} else static if (is(A == Battle)) {
			auto winProps = _prop.var.battleEventWin;
			auto parentProps = _prop.var.dataWin;
		} else static if (is(A == Package)) {
			auto winProps = _prop.var.packageWin;
			auto parentProps = _prop.var.dataWin;
		} else static if (is(A : EffectCard)) {
			auto winProps = _prop.var.cardEventWin;
			auto parentProps = _prop.var.cardWin;
		} else {
			static assert (0);
		}
		auto shell = cast(Shell) _win;
		if (shell) {
			if (!shell.getMaximized()) {
				winProps.width = shell.getSize().x;
				winProps.height = shell.getSize().y;
				if (_parent2.isDisposed()) {
					winProps.x = shell.getBounds().x - parentProps.x;
					winProps.y = shell.getBounds().y - parentProps.y;
				} else {
					winProps.x = shell.getBounds().x - _parent2.getBounds().x;
					winProps.y = shell.getBounds().y - _parent2.getBounds().y;
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
	static if (is(A : Area) || is(A : Battle)) {
		private void openScene() {
			_comm.openAreaScene(_prop, _summ, _eto, true);
		}
	}
	private void __deleteOwner(A a) {
		if (_eto is a) {
			_comm.close(_win);
		}
	}
	private void __refOwner(A a) {
		if (_eto is a) {
			__refreshTitle();
		}
	}
	@property
	override
	Image image() {
		static if (is (A == Area)) {
			return _prop.images.areaEventTreeView;
		} else static if (is (A == Battle)) {
			return _prop.images.battleEventTreeView;
		} else static if (is (A == Package)) {
			return _prop.images.packages;
		} else static if (is (A == SkillCard)) {
			return _prop.images.skill;
		} else static if (is (A == ItemCard)) {
			return _prop.images.item;
		} else static if (is (A == BeastCard)) {
			return _prop.images.beast;
		} else {
			static assert (0);
		}
	}
	@property
	override
	string title() {
		auto shl = cast(Shell) _win;
		static if (is (A == Area) || is (A == Battle)) {
			if (shl) {
				return .tryFormat(_prop.msgs.viewNameEvent, .objName!A(_prop), _eto.id, _eto.name);
			}
			return .tryFormat(_prop.msgs.viewNameEventTab, .objName!A(_prop), _eto.id, _eto.name);
		} else {
			if (shl) {
				return .tryFormat(_prop.msgs.viewName, .objName!A(_prop), _eto.id, _eto.name);
			}
			return .tryFormat(_prop.msgs.viewNameEventTab, .objName!A(_prop), _eto.id, _eto.name);
		}
	}
	@property
	override
	void delegate(string) statusText() {return _sbshl ? &_sbshl.statusLine : null;}
	private void __refreshTitle() {
		_comm.setTitle(_win, title);
		_eview.refreshTitle();
	}
	/// Returns: 編集中のイベントツリー所持者。
	@property
	A eventTreeOwner() {
		return _eto;
	}
	@property
	typeof(_eview) eventView() {
		return _eview;
	}
	@property
	override EventTreeView eventTreeView() {
		return _eview.eventTreeView;
	}

	override {
		void cut(SelectionEvent se) {
			_eview.cut(se);
		}
		void copy(SelectionEvent se) {
			_eview.copy(se);
		}
		void paste(SelectionEvent se) {
			_eview.paste(se);
		}
		void del(SelectionEvent se) {
			_eview.del(se);
		}
		void clone(SelectionEvent se) {
			_eview.clone(se);
		}
		@property
		bool canDoTCPD() {
			return _eview.canDoTCPD;
		}
		@property
		bool canDoT() {
			return _eview.canDoT;
		}
		@property
		bool canDoC() {
			return _eview.canDoC;
		}
		@property
		bool canDoP() {
			return _eview.canDoP;
		}
		@property
		bool canDoD() {
			return _eview.canDoD;
		}
		@property
		bool canDoClone() {
			return _eview.canDoClone;
		}
	}
	override
	bool openCWXPath(string path, bool shellActivate) {
		return _eview.openCWXPath(path, shellActivate);
	}
	@property
	override
	string[] openedCWXPath() {
		return _eview.openedCWXPath;
	}
}

alias EventWindow!(Area) AreaEventWindow;
alias EventWindow!(Battle) BattleEventWindow;
alias EventWindow!(Package) PackageWindow;
alias EventWindow!(SkillCard) SkillEventWindow;
alias EventWindow!(ItemCard) ItemEventWindow;
alias EventWindow!(BeastCard) BeastEventWindow;
