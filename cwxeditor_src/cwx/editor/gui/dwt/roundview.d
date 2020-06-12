
module cwx.editor.gui.dwt.roundview;

import cwx.card;
import cwx.event;
import cwx.menu;
import cwx.system;
import cwx.types;
import cwx.utils;
import cwx.xml;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.editablelistview;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

static import std.algorithm;
import std.algorithm : equal, map, uniq;
import std.array;
import std.conv;
import std.datetime;
import std.range;
import std.string;

import org.eclipse.swt.all;

import java.lang.all;

/// ラウンド発火条件のビュー。
class RoundView : AbstractEditableListView!(uint, true) {

	private Commons _comm;

	private TableTCEdit _ttce = null;

	private bool delegate() _catchMod;

	private Control createEditor(TableItem itm, int editC) { mixin(S_TRACE);
		auto table = itm.getParent();
		auto spn = new Spinner(table, SWT.BORDER);
		initSpinner(spn);
		spn.setMaximum(_comm.prop.var.etc.roundMax);
		spn.setMinimum(1);
		spn.setSelection(value(table.indexOf(itm)));
		return spn;
	}
	private void editEnd(TableItem itm, int column, Control ctrl) { mixin(S_TRACE);
		auto spn = cast(Spinner)ctrl;
		assert (spn !is null);
		auto newValue = spn.getSelection();
		mainValueEditEnd(itm, newValue);
	}

	override
	protected uint createNewValue(out int index, out bool cancel) { mixin(S_TRACE);
		index = -1;
		cancel = false;
		bool[uint] eRounds;
		foreach (i; rounds) eRounds[i] = true;
		uint round = 1;
		while (round in eRounds) round++;
		if (_comm.prop.var.etc.roundMax < round) { mixin(S_TRACE);
			cancel = true;
			return 0;
		}
		index = round - 1;
		return round;
	}
	override
	const
	protected bool isValidValue(in uint value) { return 0 < value; }

	private bool _canAddRound = true;
	@property
	const
	private bool canAddRound() { mixin(S_TRACE);
		return _canAddRound;
	}
	private void updateCanAddRound() { mixin(S_TRACE);
		_canAddRound = !readOnly && !.equal(.iota(1u, _comm.prop.var.etc.roundMax + 1), .map!(i => value(i))(.iota(0, valueCount)));
	}

	@property
	override
	const
	protected string xmlName() { return ROUNDS_XML_NAME; }
	override
	protected uint[] createFromNode(ref XNode node) { mixin(S_TRACE);
		auto ver = new XMLInfo(_comm.prop.sys, LATEST_VERSION);
		return .roundsFromNode(node, ver);
	}
	override
	protected XNode toNode(in int[] indices) { mixin(S_TRACE);
		auto rounds = indices.map!(i => value(i))().array();
		return .roundsToNode(rounds);
	}

	override
	protected void initColumns(Table table) { mixin(S_TRACE);
		new FullTableColumn(table, SWT.NONE);
	}
	override
	protected void initEditors(Table table) { mixin(S_TRACE);
		_ttce = new TableTCEdit(_comm, table, 0, &createEditor, &editEnd, (itm, column) => true);
	}
	override
	protected void initPopupMenu(Menu menu) { mixin(S_TRACE);
		if (!readOnly) { mixin(S_TRACE);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.AddRangeOfRound, &addManyRounds, &canAddRound);
			modEvent ~= &updateCanAddRound;
		}
	}

	@property
	override
	protected AbstractTableEdit[] editors() { return [cast(AbstractTableEdit)_ttce]; }
	@property
	override
	protected AbstractTableEdit mainEditor() { return _ttce; }

	protected
	override
	Image addIcon() { return _comm.prop.images.addRound; }
	protected
	override
	const
	string addText() { return _comm.prop.msgs.addRound; }
	protected
	override
	Image delIcon() { return _comm.prop.images.delRound; }
	protected
	override
	const
	string delText() { return _comm.prop.msgs.delRound; }

	override
	protected void updateItem(in uint round, TableItem itm) { mixin(S_TRACE);
		itm.setText(.text(round));
		itm.setImage(_comm.prop.images.round);
	}

	this (Commons comm, Composite parent, int style, bool delegate() catchMod) { mixin(S_TRACE);
		_comm = comm;
		_catchMod = catchMod;

		super (comm, parent, style, false);
	}

	private void addManyRounds() { mixin(S_TRACE);
		if (readOnly) return;
		if (!canAddRound) return;
		foreach (e; editors) { mixin(S_TRACE);
			if (e && e.isEditing) e.enter();
		}
		auto dlg = new ManyRoundsDialog(_comm.prop, getShell());
		if (dlg.open()) { mixin(S_TRACE);
			appendValues(dlg.rounds);
		}
	}

	alias values rounds;

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
