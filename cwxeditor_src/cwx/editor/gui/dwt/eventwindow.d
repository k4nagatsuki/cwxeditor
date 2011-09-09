
module cwx.editor.gui.dwt.eventwindow;

import cwx.area;
import cwx.card;
import cwx.event;
import cwx.summary;
import cwx.skin;
import cwx.utils;
import cwx.path;

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.eventview;
import cwx.editor.gui.dwt.eventtreeview;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.sbshell;

import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.events.ShellEvent;
import org.eclipse.swt.events.ShellAdapter;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.SelectionEvent;

interface IEventWindow {
	EventTreeView eventTreeView();
}

class EventWindow(A : EventTreeOwner) : TopLevelPanel, IEventWindow, TCPD {
private:
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

public:
	this(Commons comm, Props prop, Summary summ, Composite parent, Shell parent2, A eto, UndoManager undo) {
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
		contPane.setLayout = windowGridLayout(1, true);
		_prop = prop;
		_eto = eto;
		_comm = comm;
		_undo = undo ? undo : new UndoManager(1024);

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
		_win.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				saveWin;
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
			}
		});
		{
			_eview = new typeof(_eview)(comm, prop, summ, eto, contPane, _undo);
			_eview.setLayoutData = new GridData(GridData.FILL_BOTH);
		}
		if (shell) {
			auto bar = new Menu(shell, SWT.BAR);

			auto mf = createMenu(bar, _prop.msgs.menuFile);
			createMenuItem(mf, _prop.msgs.menuCloseWin, _prop.images.menuCloseWin, &shell.close);

			auto me = createMenu(bar, _prop.msgs.menuEdit);
			createMenuItem(me, _prop.msgs.menuUndo, _prop.images.menuUndo, &_eview.undo);
			createMenuItem(me, _prop.msgs.menuRedo, _prop.images.menuRedo, &_eview.redo);
			new MenuItem(me, SWT.SEPARATOR);
			createMenuItem(me, _prop.msgs.menuUp, _prop.images.menuUp, &_eview.up);
			createMenuItem(me, _prop.msgs.menuDown, _prop.images.menuDown, &_eview.down);
			new MenuItem(me, SWT.SEPARATOR);
			appendMenuTCPD(_prop, me, this, true, true, true, true);
			new MenuItem(me, SWT.SEPARATOR);
			createMenuItem(me, _prop.msgs.menuWriteComment, _prop.images.menuWriteComment, &_eview.writeComment);
			new MenuItem(me, SWT.SEPARATOR);
			createMenuItem(me, _prop.msgs.menuToScript, _prop.images.menuToScript, &_eview.toScript);
			createMenuItem(me, _prop.msgs.menuToScriptAll, _prop.images.menuToScriptAll, &_eview.toScriptAll);

			shell.setMenuBar = bar;
		} else {
			appendMenuTCPD(_prop, this, this, true, true, true, true);
			putMenuAction(MenuID.Undo, &_eview.undo);
			putMenuAction(MenuID.Redo, &_eview.redo);
			putMenuAction(MenuID.Up, &_eview.up);
			putMenuAction(MenuID.Down, &_eview.down);
			putMenuAction(MenuID.WriteComment, &_eview.writeComment);
			putMenuAction(MenuID.ToScript, &_eview.toScript);
			putMenuAction(MenuID.ToScriptAll, &_eview.toScriptAll);
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
			shell.setMaximized = winProps.maximized;
			int width = winProps.width;
			int height = winProps.height;
			int x = winProps.x == SWT.DEFAULT ? shell.getBounds.x : winProps.x + parent2.getBounds.x;
			int y = winProps.y == SWT.DEFAULT ? shell.getBounds.y : winProps.y + parent2.getBounds.y;
			intoDisplay(x, y, width, height);
			shell.setBounds(x, y, width, height);
			_parent2 = parent2;
		}

		_eview.refresh;
		__refreshTitle;
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
			if (!shell.getMaximized) {
				winProps.width = shell.getSize.x;
				winProps.height = shell.getSize.y;
				if (_parent2.isDisposed) {
					winProps.x = shell.getBounds.x - parentProps.x;
					winProps.y = shell.getBounds.y - parentProps.y;
				} else {
					winProps.x = shell.getBounds.x - _parent2.getBounds.x;
					winProps.y = shell.getBounds.y - _parent2.getBounds.y;
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
	private void __deleteOwner(A a) {
		if (_eto is a) {
			_comm.close(_win);
		}
	}
	private void __refOwner(A a) {
		if (_eto is a) {
			__refreshTitle;
		}
	}
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
	string title() {
		auto shl = cast(Shell) _win;
		static if (is (A == Area)) {
			if (shl) {
				return _prop.msgs.areaEventViewName(_eto.id, _eto.name);
			}
			return _prop.msgs.areaEventViewNameTab(_eto.id, _eto.name);
		} else static if (is (A == Battle)) {
			if (shl) {
				return _prop.msgs.battleEventViewName(_eto.id, _eto.name);
			}
			return _prop.msgs.packageViewNameTab(_eto.id, _eto.name);
		} else static if (is (A == Package)) {
			if (shl) {
				return _prop.msgs.packageViewName(_eto.id, _eto.name);
			}
			return _prop.msgs.packageViewNameTab(_eto.id, _eto.name);
		} else static if (is (A == SkillCard)) {
			if (shl) {
				return _prop.msgs.skillViewName(_eto.id, _eto.name);
			}
			return _prop.msgs.skillViewNameTab(_eto.id, _eto.name);
		} else static if (is (A == ItemCard)) {
			if (shl) {
				return _prop.msgs.itemViewName(_eto.id, _eto.name);
			}
			return _prop.msgs.itemViewNameTab(_eto.id, _eto.name);
		} else static if (is (A == BeastCard)) {
			if (shl) {
				return _prop.msgs.beastViewName(_eto.id, _eto.name);
			}
			return _prop.msgs.beastViewNameTab(_eto.id, _eto.name);
		} else {
			static assert (0);
		}
	}
	void delegate(string) statusText() {return _sbshl ? &_sbshl.statusLine : null;}
	private void __refreshTitle() {
		_comm.setTitle(_win, title);
		_eview.refreshTitle;
	}
	/// Returns: 編集中のイベントツリー所持者。
	A eventTreeOwner() {
		return _eto;
	}
	typeof(_eview) eventView() {
		return _eview;
	}
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
		bool canDoTCPD() {
			return _eview.canDoTCPD;
		}
	}
	bool openCWXPath(string path) {
		return _eview.openCWXPath(path);
	}
}

alias EventWindow!(Area) AreaEventWindow;
alias EventWindow!(Battle) BattleEventWindow;
alias EventWindow!(Package) PackageWindow;
alias EventWindow!(SkillCard) SkillEventWindow;
alias EventWindow!(ItemCard) ItemEventWindow;
alias EventWindow!(BeastCard) BeastEventWindow;
