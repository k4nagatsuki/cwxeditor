
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
import cwx.editor.gui.dwt.eventwindow;
import cwx.editor.gui.dwt.eventtreeview;
import cwx.editor.gui.dwt.dmenu;

import org.eclipse.swt.all;

public:

class TAreaWindow(V, A, C) : TopLevelPanel, SashPanel, TCPD {
private:
	int _readOnly = 0;
	Commons _comm;

	Composite _win;

	Summary _summ;
	A _area;
	Props _prop;

	UndoManager _undo;

	V _aview;

	void refresh() { mixin(S_TRACE);
		_aview.refresh();
	}
	@property
	bool canUp() { mixin(S_TRACE);
		return _aview.canUp;
	}
	@property
	bool canDown() { mixin(S_TRACE);
		return _aview.canDown;
	}
	void up() { mixin(S_TRACE);
		_aview.up();
	}
	void down() { mixin(S_TRACE);
		_aview.down();
	}
	void deleteArea(A area) { mixin(S_TRACE);
		if (_area is area) { mixin(S_TRACE);
			_comm.close(_win);
		}
	}
	void refArea(A area) { mixin(S_TRACE);
		if (_area is area) { mixin(S_TRACE);
			refreshTitle();
		}
	}
	void refreshTitle() { mixin(S_TRACE);
		_comm.setTitle(_win, title);
	}
	bool _refUndo = false;
	void refUndoMax() { mixin(S_TRACE);
		if (!_refUndo) return;
		_undo.max = _prop.var.etc.undoMaxEvent;
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			static if (is(A == Area)) {
				_comm.delArea.remove(&deleteArea);
				_comm.refArea.remove(&refArea);
			} else static if (is(A == Battle)) {
				_comm.delBattle.remove(&deleteArea);
				_comm.refBattle.remove(&refArea);
			} else static if (is(A == Package)) {
				_comm.delPackage.remove(&deleteArea);
				_comm.refPackage.remove(&refArea);
			} else { mixin(S_TRACE);
				static assert (0);
			}
			_comm.replText.remove(&refreshTitle);
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
		Composite contPane;
		_win = new Composite(parent, SWT.NONE);
		contPane = _win;
		_win.setData(new TLPData(this));
		static if (is(A == Area)) {
			_comm.delArea.add(&deleteArea);
			_comm.refArea.add(&refArea);
		} else static if (is(A == Battle)) {
			_comm.delBattle.add(&deleteArea);
			_comm.refBattle.add(&refArea);
		} else static if (is(A == Package)) {
			_comm.delPackage.add(&deleteArea);
			_comm.refPackage.add(&refArea);
		} else { mixin(S_TRACE);
			static assert (0);
		}
		_comm.replText.add(&refreshTitle);
		_comm.refUndoMax.add(&refUndoMax);
		_win.addDisposeListener(new Dispose);
		contPane.setLayout(windowGridLayout(1, true));
		_prop = prop;

		{ mixin(S_TRACE);
			auto pane = contPane;
			_aview = new V(comm, prop, summ, null, area.useCounter, area, pane, shell ? null : this,
				_prop.var.etc.showInheritBackground, _undo, _readOnly != SWT.NONE);
			_aview.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		refreshTitle();

		putMenuAction(MenuID.Undo, &this.undo, &_undo.canUndo);
		putMenuAction(MenuID.Redo, &this.redo, &_undo.canRedo);
		putMenuAction(MenuID.Up, &up, &canUp);
		putMenuAction(MenuID.Down, &down, &canDown);
		appendMenuTCPD(_comm, this, this, true, true, true, true, true);
		putMenuAction(MenuID.EditEvent, () => openEvent(false), null);
		putMenuAction(MenuID.EditSceneDup, () => openDup(), null);
		putMenuAction(MenuID.EditEventDup, () => openEvent(true), null);
		putMenuAction(MenuID.Refresh, &refresh, null);
		putMenuAction(MenuID.EditProp, &edit, &canEdit);
		putMenuAction(MenuID.SelectConnectedResource, &selectConnectedResource, &canSelectConnectedResource);
		putMenuAction(MenuID.Comment, &_aview.writeComment, &_aview.canWriteComment);

		void closeAdds(Summary summ) { mixin(S_TRACE);
			if (_summ is summ) _comm.close(_win);
		}
		_comm.closeAdds.add(&closeAdds);
		.listener(_win, SWT.Dispose, () => _comm.closeAdds.remove(&closeAdds));
	}

	@property
	override
	Image image() { mixin(S_TRACE);
		static if (is(A == Area)) {
			return _prop.images.areaSceneView;
		} else static if (is(A == Battle)) {
			return _prop.images.battleSceneView;
		} else { mixin(S_TRACE);
			static assert (0);
		}
	}
	@property
	override
	string title() { mixin(S_TRACE);
		return .tryFormat(_prop.msgs.viewNameSceneTab, .objName!A(_prop), _area.id, _area.name);
	}
	@property
	override
	void delegate(string) statusText() { return null; }

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
	void undo() { _undo.undo(); }
	void redo() { _undo.redo(); }

	void openEvent(bool canDuplicate = false) { mixin(S_TRACE);
		_aview.openEvent(canDuplicate);
	}
	void openDup() { mixin(S_TRACE);
		_aview.openDup();
	}

	private void edit() { _aview.edit(); }
	@property
	private bool canEdit() { return _aview.canEdit; }
	@property
	private bool canSelectConnectedResource() { mixin(S_TRACE);
		return _aview.canSelectConnectedResource();
	}
	private void selectConnectedResource() { mixin(S_TRACE);
		_aview.selectConnectedResource();
	}

	@property
	private TCPD tcpd() { mixin(S_TRACE);
		return _aview;
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
		} else if (((cate == "menucard" || cate == "enemycard")
				&& cpempty(cpbottom(path)))
				|| cate == "background") { mixin(S_TRACE);
			return _aview.openCWXPath(path, shellActivate);
		}
		return false;
	}
	@property
	override
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		r ~= _aview.openedCWXPath;
		return r;
	}
}

alias TAreaWindow!(AreaView, Area, MenuCard) AreaSceneWindow;
alias TAreaWindow!(BattleView, Battle, EnemyCard) BattleSceneWindow;
