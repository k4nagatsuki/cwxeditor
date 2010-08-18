
module cwx.editor.gui.dwt.eventwindow;

import cwx.area;
import cwx.card;
import cwx.event;
import cwx.summary;
import cwx.skin;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.eventview;
import cwx.editor.gui.dwt.undo;

import dwt.widgets.Shell;
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

class EventWindow(A : EventTreeOwner) : TCPD {
private:
	A _eto;
	Commons _comm;
	Props _prop;

	Shell _win;
	Shell _parent2;

	EventView!(A, void, false) _eview;

	void saveScenario() {
		_comm.save.call(_win);
	}
public:
	this(Commons comm, Props prop, Summary summ, Shell parent, Shell parent2, A eto) {
		_win = new Shell(parent, DWT.SHELL_TRIM);
		_win.setImage = prop.images.app;
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
		auto bar = new Menu(_win, DWT.BAR);
		{
			auto mf = createMenu(bar, _prop.msgs.menuFile);
			createMenuItem(mf, _prop.msgs.menuSave, _prop.images.menuSave, &saveScenario);
			new MenuItem(mf, DWT.SEPARATOR);
			createMenuItem(mf, _prop.msgs.menuCloseWin, _prop.images.menuCloseWin, &_win.close);

			auto me = createMenu(bar, _prop.msgs.menuEdit);
			createMenuItem(me, _prop.msgs.menuUndo, _prop.images.menuUndo, &_eview.undo);
			createMenuItem(me, _prop.msgs.menuRedo, _prop.images.menuRedo, &_eview.redo);
			new MenuItem(me, DWT.SEPARATOR);
			createMenuItem(me, _prop.msgs.menuUp, _prop.images.menuUp, &_eview.up);
			createMenuItem(me, _prop.msgs.menuDown, _prop.images.menuDown, &_eview.down);
			new MenuItem(me, DWT.SEPARATOR);
			appendMenuTCPD(_prop, me, this, true, true, true, true);

			_win.setMenuBar = bar;
		}

		static if (is(A == Package)) {
			auto winProps = _prop.var.packageWin;
		} else static if (is(A : EffectCard)) {
			auto winProps = _prop.var.cardEventWin;
		} else {
			static assert (0);
		}
		int width = winProps.width;
		int height = winProps.height;
		int x = winProps.x == DWT.DEFAULT ? _win.getBounds.x : winProps.x + parent2.getBounds.x;
		int y = winProps.y == DWT.DEFAULT ? _win.getBounds.y : winProps.y + parent2.getBounds.y;
		intoDisplay(x, y, width, height);
		_win.setBounds(x, y, width, height);
		_win.setMaximized = winProps.maximized;
		_parent2 = parent2;

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
		if (!_win.getMaximized) {
			winProps.width = _win.getSize.x;
			winProps.height = _win.getSize.y;
			if (_parent2.isDisposed) {
				winProps.x = _win.getBounds.x - parentProps.x;
				winProps.y = _win.getBounds.y - parentProps.y;
			} else {
				winProps.x = _win.getBounds.x - _parent2.getBounds.x;
				winProps.y = _win.getBounds.y - _parent2.getBounds.y;
			}
		}
		winProps.maximized = _win.getMaximized;
	}
	Shell shell() {
		return _win;
	}
	private void __deleteOwner(A a) {
		if (_eto is a) {
			_win.close;
		}
	}
	private void __refOwner(A a) {
		if (_eto is a) {
			__refreshTitle;
		}
	}
	private void __refreshTitle() {
		static if (is (A == Package)) {
			_win.setText = _prop.msgs.packageViewName(_eto.id, _eto.name);
		} else static if (is (A == SkillCard)) {
			_win.setText = _prop.msgs.skillViewName(_eto.id, _eto.name);
		} else static if (is (A == ItemCard)) {
			_win.setText = _prop.msgs.itemViewName(_eto.id, _eto.name);
		} else static if (is (A == BeastCard)) {
			_win.setText = _prop.msgs.beastViewName(_eto.id, _eto.name);
		} else {
			static assert (0);
		}
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
}

alias EventWindow!(Package) PackageWindow;
alias EventWindow!(SkillCard) SkillEventWindow;
alias EventWindow!(ItemCard) ItemEventWindow;
alias EventWindow!(BeastCard) BeastEventWindow;
