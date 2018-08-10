
module cwx.editor.gui.dwt.roundview;

import cwx.xml;
import cwx.menu;
import cwx.types;
import cwx.utils;
import cwx.card;
import cwx.system;
import cwx.event;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.centerlayout;

static import std.algorithm;
import std.algorithm : equal, map, uniq;
import std.array;
import std.conv;
import std.datetime;
import std.range;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;

alias Integer RoundObj;

/// ラウンド発火条件のビュー。
class RoundView : Composite {
	void delegate()[] modEvent;
	private void raiseModifyEvent() { mixin(S_TRACE);
		foreach (dlg; modEvent) { mixin(S_TRACE);
			dlg();
		}
	}
	private string _id;

	private int _readOnly = 0;

	private Commons _comm;
	private Props _prop;
	private KeyDownFilter _kdFilter;

	private UndoManager _undo;

	private Table _rounds;
	private ToolBar _toolbar = null;
	private TableTCEdit _ttce = null;

	private bool delegate() _catchMod;

	private void setRound(int index, uint round) { mixin(S_TRACE);
		auto itm = _rounds.getItem(index);
		assert (itm !is null);
		setRound(itm, round);
	}
	private void setRound(TableItem itm, uint round) { mixin(S_TRACE);
		itm.setText(.text(round));
		itm.setImage(_prop.images.round);
		itm.setData(new RoundObj(round));
	}
	private uint getRound(TableItem itm) { mixin(S_TRACE);
		return (cast(RoundObj)itm.getData()).intValue();
	}

	class UndoName : Undo {
		private int _index;
		private uint _oldValue;
		private uint _newValue;
		this (int index, uint oldValue, uint newValue) { mixin(S_TRACE);
			_index = index;
			_oldValue = oldValue;
			_newValue = newValue;
		}
		private void impl() { mixin(S_TRACE);
			if (_ttce && _ttce.isEditing) _ttce.cancel();
			setRound(_index, _oldValue);
			auto temp = _oldValue;
			_oldValue = _newValue;
			_newValue = temp;
			raiseModifyEvent();
			_comm.refreshToolBar();
		}
		void undo() { impl(); }
		void redo() { impl(); }
		void dispose() { }
	}
	void storeSingle(int index, uint oldValue, uint newValue) { mixin(S_TRACE);
		_undo ~= new UndoName(index, oldValue, newValue);
	}
	private class UndoRounds : Undo {
		private uint[] _rounds;
		private bool _canAddRound;
		this () { mixin(S_TRACE);
			save();
		}
		private void save() { mixin(S_TRACE);
			_rounds = this.outer.rounds;
			_canAddRound = this.outer._canAddRound;
		}
		private void impl() { mixin(S_TRACE);
			if (_ttce && _ttce.isEditing) _ttce.cancel();
			auto rounds = _rounds;
			auto canAddRound = _canAddRound;
			save();
			this.outer._rounds.setRedraw(false);
			scope (exit) this.outer._rounds.setRedraw(true);

			auto n = this.outer._rounds.getItemCount();
			this.outer._rounds.setItemCount(cast(int)rounds.length);
			foreach (i, round; rounds) { mixin(S_TRACE);
				setRound(cast(int)i, round);
			}
			this.outer._canAddRound = canAddRound;
			raiseModifyEvent();
			_comm.refreshToolBar();
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { mixin(S_TRACE);
			// Nothing
		}
	}
	private void storeRounds() { mixin(S_TRACE);
		_undo ~= new UndoRounds;
	}
	private void undo() { mixin(S_TRACE);
		_undo.undo();
	}
	private void redo() { mixin(S_TRACE);
		_undo.redo();
	}

	private Control createEditor(TableItem itm, int editC) { mixin(S_TRACE);
		auto spn = new Spinner(itm.getParent(), SWT.BORDER);
		initSpinner(spn);
		spn.setMaximum(_prop.var.etc.roundMax);
		spn.setMinimum(1);
		spn.setSelection(getRound(itm));
		return spn;
	}
	private void editEnd(TableItem itm, int column, Control ctrl) { mixin(S_TRACE);
		auto spn = cast(Spinner)ctrl;
		assert (spn !is null);
		auto oldValue = getRound(itm);
		auto newValue = spn.getSelection();
		if (oldValue == newValue && !_startAdd) return;
		scope (exit) _startAdd = null;
		if (existsRound(itm, newValue)) { mixin(S_TRACE);
			_startAdd = null;
			return;
		}
		if (_startAdd) { mixin(S_TRACE);
			storeRounds();
			_startAdd = null;
		} else { mixin(S_TRACE);
			storeSingle(_rounds.indexOf(itm), oldValue, newValue);
		}
		_startAdd = null;
		setRound(itm, newValue);
		sortRounds([newValue]);
		updateCanAddRound();
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	private void exitEdit(bool cancel) { mixin(S_TRACE);
		if (cancel && _startAdd) _startAdd.dispose();
		_startAdd = null;
	}
	private bool existsRound(TableItem itm, uint round) { mixin(S_TRACE);
		foreach (itm2; _rounds.getItems()) { mixin(S_TRACE);
			if (itm2 !is itm && getRound(itm2) == round) { mixin(S_TRACE);
				_rounds.deselectAll();
				_rounds.setSelection([itm2]);
				if (_startAdd) _startAdd.dispose();
				_rounds.showSelection();
				return true;
			}
		}
		return false;
	}

	private void sortRounds(uint[] selRounds) { mixin(S_TRACE);
		bool[uint] selRounds2;
		foreach (round; selRounds) selRounds2[round] = true;
		auto rounds = this.rounds;
		std.algorithm.sort(rounds);
		foreach (i, itm; _rounds.getItems()) { mixin(S_TRACE);
			auto round = rounds[i];
			setRound(itm, round);
			if (round in selRounds2) { mixin(S_TRACE);
				_rounds.select(cast(int)i);
			} else { mixin(S_TRACE);
				_rounds.deselect(cast(int)i);
			}
		}
		_rounds.showSelection();
	}

	private TableItem append(uint round, int index = -1) { mixin(S_TRACE);
		if (_ttce && _ttce.isEditing) _ttce.enter();
		TableItem itm;
		if (index != -1) { mixin(S_TRACE);
			itm = new TableItem(_rounds, SWT.NONE, index);
		} else { mixin(S_TRACE);
			itm = new TableItem(_rounds, SWT.NONE);
		}
		setRound(itm, round);
		return itm;
	}
	private TableItem _startAdd = null;
	private void add() { mixin(S_TRACE);
		bool[uint] eRounds;
		foreach (itm; _rounds.getItems()) eRounds[getRound(itm)] = true;
		uint round = 1;
		while (round in eRounds) round++;
		if (_prop.var.etc.roundMax < round) return;
		if (_ttce && _ttce.isEditing) _ttce.enter();
		auto itm = append(round, round - 1);
		_rounds.deselectAll();
		_rounds.setSelection([itm]);
		_rounds.showSelection();
		_comm.refreshToolBar();
		.forceFocus(_rounds, false);
		_startAdd = itm;
		_ttce.startEdit();
	}
	private void del() { mixin(S_TRACE);
		auto indices = _rounds.getSelectionIndices();
		if (!indices.length) return;
		if (_ttce && _ttce.isEditing) _ttce.enter();
		storeRounds();
		_rounds.remove(indices);
		_canAddRound = true;
		raiseModifyEvent();
		_comm.refreshToolBar();
	}

	private bool _canAddRound = true;
	@property
	const
	private bool canAddRound() { mixin(S_TRACE);
		return _canAddRound;
	}
	private void updateCanAddRound() { mixin(S_TRACE);
		_canAddRound = !_readOnly && !.equal(.iota(1u, _prop.var.etc.roundMax + 1), .map!(itm => getRound(itm))(_rounds.getItems()));
	}

	private class CDropListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = _readOnly ? DND.DROP_NONE : DND.DROP_MOVE;
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = _readOnly ? DND.DROP_NONE : DND.DROP_MOVE;
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			if (!isXMLBytes(e.data)) return;
			e.detail = DND.DROP_NONE;
			string xml = bytesToXML(e.data);
			try { mixin(S_TRACE);
				auto node = XNode.parse(xml);
				auto samePane = _id == node.attr("paneId", false);
				if (samePane) return;
				if (!appendFromNode(node)) return;
				e.detail = DND.DROP_COPY;
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
	}
	bool appendFromNode(ref XNode node) { mixin(S_TRACE);
		if (node.name != ROUNDS_XML_NAME) return false;
		auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
		auto rounds = roundsFromNode(node, ver);
		return appendRounds(rounds);
	}
	bool appendRounds(in uint[] rounds) {
		if (!rounds.length) return false;
		bool[uint] eRounds;
		foreach (itm; _rounds.getItems()) eRounds[getRound(itm)] = true;

		uint[] rounds2;
		foreach (round; rounds) { mixin(S_TRACE);
			if (round in eRounds) continue;
			eRounds[round] = true;
			rounds2 ~= round;
		}
		if (!rounds2.length) return false;

		_rounds.setRedraw(false);
		scope (exit) _rounds.setRedraw(true);
		if (_ttce && _ttce.isEditing) _ttce.enter();

		storeRounds();
		foreach (round; rounds2) { mixin(S_TRACE);
			append(round);
		}
		_rounds.deselectAll();
		sortRounds(rounds2);
		updateCanAddRound();
		raiseModifyEvent();
		_comm.refreshToolBar();
		return true;
	}
	private int _dragIndex = -1;
	private class CDragListener : DragSourceAdapter {
		private TableItem[] _itms;
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			auto c = cast(Table)(cast(DragSource)e.getSource()).getControl();
			e.doit = c.isFocusControl() && c.getSelectionIndex() != -1;
		}
		override void dragSetData(DragSourceEvent e){ mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				if (_ttce && _ttce.isEditing) _ttce.enter();
				auto c = cast(Table)(cast(DragSource)e.getSource()).getControl();
				_itms = c.getSelection();
				if (!_itms.length) return;
				_dragIndex = c.getSelectionIndex();
				if (_dragIndex == -1) return;
				auto rounds = _itms.map!(itm => getRound(itm))().array();
				auto node = roundsToNode(rounds);
				node.newAttr("paneId", _id);
				e.data = bytesFromXML(node.text);
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			if (!_readOnly && e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
				if (_ttce && _ttce.isEditing) _ttce.enter();
				_rounds.setRedraw(false);
				scope (exit) _rounds.setRedraw(true);
				foreach_reverse (itm; _itms) itm.dispose();
				raiseModifyEvent();
				_comm.refreshToolBar();
			}
			_dragIndex = -1;
			_itms = [];
		}
	}
	private class RoundTCPD : TCPD {
		override void cut(SelectionEvent se) { mixin(S_TRACE);
			if (canDoT) { mixin(S_TRACE);
				copy(se);
				del(se);
			}
		}
		override void copy(SelectionEvent se) { mixin(S_TRACE);
			if (canDoC) { mixin(S_TRACE);
				if (_ttce && _ttce.isEditing) _ttce.enter();
				auto rounds = _rounds.getSelection().map!(itm => getRound(itm))().array();
				XMLtoCB(_prop, _comm.clipboard, roundsToXML(rounds));
				_comm.refreshToolBar();
			}
		}
		override void paste(SelectionEvent se) { mixin(S_TRACE);
			auto xml = CBtoXML(_comm.clipboard);
			if (xml) { mixin(S_TRACE);
				if (_ttce && _ttce.isEditing) _ttce.enter();
				try { mixin(S_TRACE);
					auto node = XNode.parse(xml);
					appendFromNode(node);
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
		override void del(SelectionEvent se) { mixin(S_TRACE);
			this.outer.del();
		}
		override void clone(SelectionEvent se) { mixin(S_TRACE);
			assert (0);
		}
		@property
		override bool canDoTCPD() { mixin(S_TRACE);
			return true;
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			return !_readOnly && _rounds.getSelectionIndex() != -1;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			return _rounds.getSelectionIndex() != -1;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			return !_readOnly && CBisXML(_comm.clipboard);
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			return !_readOnly && _rounds.getSelectionIndex() != -1;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			return !_readOnly && canDoC;
		}
	}

	private class HTBTraverse : Listener {
		override void handleEvent(Event e) { e.doit = true; }
	}
	private class HTBKeyDown : Listener {
		override void handleEvent(Event e) { e.doit = true; }
	}

	this (Commons comm, Composite parent, int style, bool delegate() catchMod) { mixin(S_TRACE);
		super (parent, style);

		auto o = this;
		_id = format("%08X", &o) ~ "-" ~ to!(string)(Clock.currTime());

		_readOnly = style & SWT.READ_ONLY;
		_comm = comm;
		_prop = comm.prop;
		_catchMod = catchMod;
		_undo = new UndoManager(_prop.var.etc.undoMaxEtc);
		this.setLayout(zeroMarginGridLayout(1, true));
		if (!_readOnly) { mixin(S_TRACE);
			_toolbar = new ToolBar(this, SWT.FLAT);
			_comm.put(_toolbar);
			_toolbar.addListener(SWT.Traverse, new HTBTraverse);
			_toolbar.addListener(SWT.KeyDown, new HTBKeyDown);
			createToolItem2(_comm, _toolbar, _prop.msgs.addRound, _prop.images.addRound, &add, &canAddRound);
			createToolItem2(_comm, _toolbar, _prop.msgs.delRound, _prop.images.delRound, &del, () => !_readOnly && _rounds.getSelectionIndex() != -1);
		}
		{ mixin(S_TRACE);
			_rounds = .rangeSelectableTable(this, SWT.BORDER | SWT.MULTI | SWT.FULL_SELECTION);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.roundWidth;
			_rounds.setLayoutData(gd);

			new FullTableColumn(_rounds, SWT.NONE);

			auto menu = new Menu(_rounds);
			if (!_readOnly) { mixin(S_TRACE);
				createMenuItem(_comm, menu, MenuID.Undo, &undo, () => !_readOnly && _undo.canUndo);
				createMenuItem(_comm, menu, MenuID.Redo, &redo, () => !_readOnly && _undo.canRedo);
				new MenuItem(menu, SWT.SEPARATOR);
				appendMenuTCPD(_comm, menu, new RoundTCPD, true, true, true, true, false);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.AddRangeOfRound, &addManyRounds, &canAddRound);
			} else { mixin(S_TRACE);
				appendMenuTCPD(_comm, menu, new RoundTCPD, false, true, false, false, false);
			}
			_rounds.setMenu(menu);
			.listener(_rounds, SWT.Selection, { _comm.refreshToolBar(); });
			if (!_readOnly) { mixin(S_TRACE);
				.listener(_rounds, SWT.MouseDoubleClick, { mixin(S_TRACE);
					if (_rounds.getSelectionIndex() != -1) return;
					if (!canAddRound) return;
					add();
				});
			}
		}

		auto drag = new DragSource(_rounds, DND.DROP_MOVE | DND.DROP_COPY);
		drag.setTransfer([XMLBytesTransfer.getInstance()]);
		drag.addDragListener(new CDragListener);
		if (!_readOnly) { mixin(S_TRACE);
			auto drop = new DropTarget(_rounds, DND.DROP_DEFAULT | DND.DROP_MOVE | DND.DROP_COPY);
			drop.setTransfer([XMLBytesTransfer.getInstance()]);
			drop.addDropListener(new CDropListener);
		}

		if (!_readOnly) { mixin(S_TRACE);
			_ttce = new TableTCEdit(_comm, _rounds, 0, &createEditor, &editEnd, (itm, column) => true);
			_ttce.exitEvent ~= &exitEdit;
		}

		auto d = this.getDisplay();
		_comm.refMenu.add(&refMenu);
		_comm.refUndoMax.add(&refUndoMax);
		_kdFilter = new KeyDownFilter();
		d.addFilter(SWT.KeyDown, _kdFilter);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			_comm.refMenu.remove(&refMenu);
			_comm.refUndoMax.remove(&refUndoMax);
			d.removeFilter(SWT.KeyDown, _kdFilter);
		});
	}
	private class KeyDownFilter : Listener {
		this () { mixin(S_TRACE);
			refMenu(MenuID.Undo);
			refMenu(MenuID.Redo);
		}
		override void handleEvent(Event e) { mixin(S_TRACE);
			if (!e.doit) return;
			auto c = cast(Control)e.widget;
			if (!c || c.isDisposed() || c.getShell() !is getShell()) return;
			if (isDescendant(this.outer, c)) { mixin(S_TRACE);
				if (c.getMenu() && findMenu(c.getMenu(), e.keyCode, e.character, e.stateMask)) return;
				if (eqAcc(_undoAcc, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
					_undo.undo();
					e.doit = false;
				} else if (eqAcc(_redoAcc, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
					_undo.redo();
					e.doit = false;
				}
			}
		}
	}
	private int _undoAcc;
	private int _redoAcc;
	private void refMenu(MenuID id) { mixin(S_TRACE);
		if (id == MenuID.Undo) _undoAcc = convertAccelerator(_prop.buildMenu(MenuID.Undo));
		if (id == MenuID.Redo) _redoAcc = convertAccelerator(_prop.buildMenu(MenuID.Redo));
	}

	private void refUndoMax() { mixin(S_TRACE);
		_undo.max = _prop.var.etc.undoMaxEtc;
	}

	private void addManyRounds() { mixin(S_TRACE);
		if (_readOnly) return;
		if (!canAddRound) return;
		if (_ttce && _ttce.isEditing) _ttce.enter();
		auto dlg = new ManyRoundsDialog(_prop, getShell());
		if (dlg.open()) { mixin(S_TRACE);
			appendRounds(dlg.rounds);
		}
	}

	@property
	bool isNewItemEditing() { return _startAdd !is null; }

	@property
	uint[] rounds() { mixin(S_TRACE);
		uint[] r;
		foreach (i, itm; _rounds.getItems()) { mixin(S_TRACE);
			if (itm is _startAdd) continue;
			r ~= getRound(itm);
		}
		return r;
	}
	@property
	void rounds(in uint[] rounds) { mixin(S_TRACE);
		_undo.reset();
		_rounds.removeAll();
		auto rounds2 = rounds.dup;
		std.algorithm.sort(rounds2);
		foreach (round; rounds2.uniq()) { mixin(S_TRACE);
			append(round, -1);
		}
	}

	@property
	void enabled(bool e) { mixin(S_TRACE);
		_rounds.setEnabled(e);
		if (_toolbar) _toolbar.setEnabled(!_readOnly && e);
	}
	@property
	bool enabled() { mixin(S_TRACE);
		return _rounds.isEnabled();
	}

	@property
	string[] warnings() { mixin(S_TRACE);
		return [];
	}
}

class ManyRoundsDialog : AbsDialog {
private:
	Props _prop;

	Spinner _from;
	Spinner _to;

	uint[] _rounds;
public:
	this (Props prop, Shell shell) { mixin(S_TRACE);
		_prop = prop;
		super (prop, shell, prop.msgs.dlgTitAddManyRounds, prop.images.menu(MenuID.AddRangeOfRound), false);
		enterClose = true;
	}

	@property
	const
	override
	bool noScenario() { return true; }

	@property
	uint[] rounds() { mixin(S_TRACE);
		return _rounds;
	}
protected:
	private class SelMin : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			int f = _from.getSelection();
			if (f >= _to.getSelection()) { mixin(S_TRACE);
				_to.setSelection(f);
			}
		}
	}
	private class SelMax : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			int t = _to.getSelection();
			if (t <= _from.getSelection()) { mixin(S_TRACE);
				_from.setSelection(t);
			}
		}
	}
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, false));
		{ mixin(S_TRACE);
			auto grp = new Group(area, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setText(_prop.msgs.manyRounds);
			grp.setLayout(new CenterLayout(SWT.VERTICAL | SWT.HORIZONTAL, 0));
			auto comp = new Composite(grp, SWT.NONE);
			comp.setLayout(normalGridLayout(4, false));
			_from = new Spinner(comp, SWT.BORDER);
			initSpinner(_from);
			_from.setMinimum(1);
			_from.setMaximum(_prop.var.etc.roundMax);
			_from.addSelectionListener(new SelMin);
			auto l1 = new Label(comp, SWT.NONE);
			l1.setText(_prop.msgs.roundSep);
			_to = new Spinner(comp, SWT.BORDER);
			initSpinner(_to);
			_to.setMinimum(1);
			_to.setMaximum(_prop.var.etc.roundMax);
			_to.addSelectionListener(new SelMax);
			auto l2 = new Label(comp, SWT.NONE);
			l2.setText(.tryFormat(_prop.msgs.rangeHint, 1, _prop.var.etc.roundMax));
		}
	}
	override bool close(bool ok) { mixin(S_TRACE);
		if (ok) { mixin(S_TRACE);
			for (uint i = _from.getSelection(); i <= _to.getSelection(); i++) { mixin(S_TRACE);
				_rounds ~= i;
			}
		}
		return ok;
	}
}
