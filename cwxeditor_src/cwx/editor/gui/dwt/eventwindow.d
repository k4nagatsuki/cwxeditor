
module cwx.editor.gui.dwt.eventwindow;

import cwx.area;
import cwx.card;
import cwx.event;
import cwx.summary;
import cwx.skin;
import cwx.utils;
import cwx.path;

import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.eventview;
import cwx.editor.gui.dwt.undo;

import dwt.widgets.Composite;
import dwt.widgets.Shell;
import dwt.widgets.Label;
import dwt.widgets.ToolBar;
import dwt.widgets.ToolItem;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.graphics.Image;
import dwt.events.ShellEvent;
import dwt.events.ShellAdapter;
import dwt.events.DisposeEvent;
import dwt.events.DisposeListener;

class EventWindow(A : EventTreeOwner) : TopLevelPanel, TCPD {
private:
	A _eto;
	Commons _comm;
	Props _prop;

	Composite _win;
	Label _status = null;
	Shell _parent2 = null;

	EventView!(A, void, false) _eview;

	void saveScenario() {
		_comm.save.call(_win.getShell);
	}
public:
	this(Commons comm, Props prop, Summary summ, Composite parent, Shell parent2, A eto) {
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
		_win.setLayout = windowGridLayout(1, true);
		_prop = prop;
		_eto = eto;
		_comm = comm;

		static if (is (A == Package)) {
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
				static if (is (A == Package)) {
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
			_eview = new EventView!(A, void, false)(comm, prop, summ, eto, _win, new UndoManager(1024));
			_eview.setLayoutData = new GridData(GridData.FILL_BOTH);
		}
		if (shell) {
			auto bar = new Menu(shell, DWT.BAR);

			auto mf = createMenu(bar, _prop.msgs.menuFile);
			createMenuItem(mf, _prop.msgs.menuSave, _prop.images.menuSave, &saveScenario);
			new MenuItem(mf, DWT.SEPARATOR);
			createMenuItem(mf, _prop.msgs.menuCloseWin, _prop.images.menuCloseWin, &shell.close);

			auto me = createMenu(bar, _prop.msgs.menuEdit);
			createMenuItem(me, _prop.msgs.menuUndo, _prop.images.menuUndo, &_eview.undo);
			createMenuItem(me, _prop.msgs.menuRedo, _prop.images.menuRedo, &_eview.redo);
			new MenuItem(me, DWT.SEPARATOR);
			createMenuItem(me, _prop.msgs.menuUp, _prop.images.menuUp, &_eview.up);
			createMenuItem(me, _prop.msgs.menuDown, _prop.images.menuDown, &_eview.down);
			new MenuItem(me, DWT.SEPARATOR);
			appendMenuTCPD(_prop, me, this, true, true, true, true);

			shell.setMenuBar = bar;
		} else {
			appendMenuTCPD(_prop, this, this, true, true, true, true);
			putMenuAction(MenuID.Undo, &_eview.undo);
			putMenuAction(MenuID.Redo, &_eview.redo);
			putMenuAction(MenuID.Up, &_eview.up);
			putMenuAction(MenuID.Down, &_eview.down);
		}
		if (shell) {
			_status = new Label(_win, DWT.NONE);
			_status.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}

		if (shell) {
			static if (is(A == Package)) {
				auto winProps = _prop.var.packageWin;
			} else static if (is(A : EffectCard)) {
				auto winProps = _prop.var.cardEventWin;
			} else {
				static assert (0);
			}
			int width = winProps.width;
			int height = winProps.height;
			int x = winProps.x == DWT.DEFAULT ? shell.getBounds.x : winProps.x + parent2.getBounds.x;
			int y = winProps.y == DWT.DEFAULT ? shell.getBounds.y : winProps.y + parent2.getBounds.y;
			intoDisplay(x, y, width, height);
			shell.setBounds(x, y, width, height);
			shell.setMaximized = winProps.maximized;
			_parent2 = parent2;
		}

		_eview.refresh;
		__refreshTitle;
	}
	private void saveWin() {
		static if (is(A == Package)) {
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
		static if (is (A == Package)) {
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
		static if (is (A == Package)) {
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
	Label statusText() {return _status;}
	private void __refreshTitle() {
		_comm.setTitle(_win, title);
		_eview.refreshTitle;
	}
	/// Returns: 編集中のイベントツリー所持者。
	A eventTreeOwner() {
		return _eto;
	}
	override {
		void cut() {
			_eview.cut;
		}
		void copy() {
			_eview.copy;
		}
		void paste() {
			_eview.paste;
		}
		void del() {
			_eview.del;
		}
		bool canDoTCPD() {
			return _eview.canDoTCPD;
		}
	}
	bool openCWXPath(string path) {
		return _eview.openCWXPath(path);
	}
}

alias EventWindow!(Package) PackageWindow;
alias EventWindow!(SkillCard) SkillEventWindow;
alias EventWindow!(ItemCard) ItemEventWindow;
alias EventWindow!(BeastCard) BeastEventWindow;
