
module cwx.editor.gui.dwt.keycodeview;

import cwx.card;
import cwx.menu;
import cwx.motion;
import cwx.summary;
import cwx.system;
import cwx.types;
import cwx.utils;
import cwx.warning;
import cwx.xml;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.comment;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.editablelistview;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

import std.algorithm;
import std.array;
import std.conv;
import std.datetime;
import std.string;
import std.traits;

import org.eclipse.swt.all;

import java.lang.all;

/// カードが持つキーコードのビュー。
class KeyCodeView : AbstractEditableListView!string {

	private bool _withIgnitionType = false;

	private Commons _comm;
	private Summary _summ;

	private TableTextEdit _tte = null;
	private TableComboEdit!Combo _tce = null;

	private bool delegate() _catchMod;

	private const(Motion)[] delegate() _getMotions = null;

	override
	protected void updateItem(in string value, TableItem itm) { mixin(S_TRACE);
		auto name = value;
		itm.setText(name);
		auto image = _comm.prop.images.keyCode;
		if (_withIgnitionType) { mixin(S_TRACE);
			auto fkc = _comm.prop.sys.toFKeyCode(name);
			itm.setText(1, _comm.prop.msgs.keyCodeTiming(fkc.kind));
			image = _comm.prop.images.keyCodeTiming(fkc.kind);
		}
		itm.setImage(image);
		itm.redraw();
	}
	private void refDataVersion() { mixin(S_TRACE);
		clearAll();
	}

	private Control createEditor(TableItem itm, int editC) { mixin(S_TRACE);
		return .createKeyCodeCombo!Combo(_comm, _summ, itm.getParent(), _catchMod, itm.getText(), _withIgnitionType, () => _comm.skin.type);
	}
	private void editEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
		mainValueEditEnd(itm, newText);
	}

	void ignitionTypeCombo(TableItem itm, int column, out string[] strs, out string str) { mixin(S_TRACE);
		foreach (i, kind; EnumMembers!FKCKind) { mixin(S_TRACE);
			auto v = _comm.prop.msgs.keyCodeTiming(kind);
			strs ~= v;
			if (kind is _comm.prop.sys.fireKeyCodeKind(itm.getText())) { mixin(S_TRACE);
				str = v;
			}
		}
	}
	void ignitionTypeEditEnd(TableItem selItm, int column, Combo combo) { mixin(S_TRACE);
		int i = combo.getSelectionIndex();
		if (-1 == i) return;
		auto oldText = selItm.getText();
		auto kind = [EnumMembers!FKCKind][i];
		auto newText = _comm.prop.sys.convFireKeyCode(oldText, kind);
		subValueEditEnd(selItm, newText);
	}

	override
	const
	protected bool isValidValue(in string value) { mixin(S_TRACE);
		if (_withIgnitionType) { mixin(S_TRACE);
			return _comm.prop.sys.toFKeyCode(value).keyCode != "";
		} else { mixin(S_TRACE);
			return canDuplicate || value != "";
		}
	}
	override
	const
	protected size_t maxCount() { mixin(S_TRACE);
		if (_summ && _summ.legacy && canDuplicate) { mixin(S_TRACE);
			return _comm.prop.looks.keyCodesMaxLegacy;
		} else {
			return size_t.max;
		}
	}

	override
	protected string[] createFromNode(ref XNode node) { mixin(S_TRACE);
		auto ver = new XMLInfo(_comm.prop.sys, LATEST_VERSION);
		auto keyCodes = .keyCodesFromNode(node, ver);
		return keyCodes;
	}
	override
	const
	protected string xmlName() { return KEY_CODES_XML_NAME; }
	override
	protected XNode toNode(in int[] indices) { mixin(S_TRACE);
		auto keyCodes = indices.map!(i => value(i))().array();
		return .keyCodesToNode(keyCodes);
	}

	protected
	override
	Image addIcon() { return _comm.prop.images.addKeyCode; }
	protected
	override
	const
	string addText() { return _comm.prop.msgs.addKeyCode; }
	protected
	override
	Image delIcon() { return _comm.prop.images.delKeyCode; }
	protected
	override
	const
	string delText() { return _comm.prop.msgs.delKeyCode; }

	override
	protected void initColumns(Table table) { mixin(S_TRACE);
		new FullTableColumn(table, SWT.NONE);
		if (_withIgnitionType) { mixin(S_TRACE);
			auto col = new TableColumn(table, SWT.NONE);
			auto gc = new GC(table);
			scope (exit) gc.dispose();
			auto w = 0;
			auto t = "";
			foreach (kind; EnumMembers!FKCKind) { mixin(S_TRACE);
				auto t2 = _comm.prop.msgs.keyCodeTiming(kind);
				auto w2 = gc.wTextExtent(t2).x;
				if (w < w2) { mixin(S_TRACE);
					w = w2;
					t = t2;
				}
			}
			auto l = new class Listener {
				override void handleEvent(Event e) { mixin(S_TRACE);
					auto itm = cast(TableItem)e.item;
					itm.setText(1, t);
				}
			};
			table.addListener(SWT.SetData, l);
			table.setItemCount(1);
			col.pack();
			table.removeListener(SWT.SetData, l);
			table.setItemCount(0);
		}
	}
	override
	protected void initEditors(Table table) { mixin(S_TRACE);
		_tte = new TableTextEdit(_comm, _comm.prop, table, 0, &editEnd, (itm, column) => true, &createEditor);
		if (_withIgnitionType) { mixin(S_TRACE);
			_tce = new TableComboEdit!Combo(_comm, _comm.prop, table, 1, &ignitionTypeCombo, &ignitionTypeEditEnd, null);
		}
	}
	override
	protected void initToolBar(ToolBar bar) { mixin(S_TRACE);
		if (!readOnly && _getMotions) { mixin(S_TRACE);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(_comm, bar, MenuID.AddKeyCodesByFeatures, &addKeyCodesByFeatures, &canAddKeyCodesByFeatures);
		}
	}
	override
	protected void initPopupMenu(Menu menu) { mixin(S_TRACE);
		new MenuItem(menu, SWT.SEPARATOR);
		if (!readOnly && !canDuplicate) { mixin(S_TRACE);
			void delegate() dlg = null;
			auto cascade = createMenuItem(_comm, menu, MenuID.KeyCodeTiming, dlg, () => canConvKeyCode!(FKCKind.Use) || canConvKeyCode!(FKCKind.Success) || canConvKeyCode!(FKCKind.Failure) || canConvKeyCode!(FKCKind.HasNot), SWT.CASCADE);
			auto sub = new Menu(parent.getShell(), SWT.DROP_DOWN);
			cascade.setMenu(sub);
			createMenuItem(_comm, sub, MenuID.KeyCodeTimingUse, &convKeyCode!(FKCKind.Use), &canConvKeyCode!(FKCKind.Use));
			if (_withIgnitionType) { mixin(S_TRACE);
				createMenuItem(_comm, sub, MenuID.KeyCodeTimingSuccess, &convKeyCode!(FKCKind.Success), &canConvKeyCode!(FKCKind.Success));
				createMenuItem(_comm, sub, MenuID.KeyCodeTimingFailure, &convKeyCode!(FKCKind.Failure), &canConvKeyCode!(FKCKind.Failure));
			}
			createMenuItem(_comm, sub, MenuID.KeyCodeTimingHasNot, &convKeyCode!(FKCKind.HasNot), &canConvKeyCode!(FKCKind.HasNot));
		}
		void delegate() dlg = null;
		auto cascade = createMenuItem(_comm, menu, MenuID.CopyTimingConvertedKeyCode, dlg, &canCopyWith, SWT.CASCADE);
		auto sub = new Menu(parent.getShell(), SWT.DROP_DOWN);
		cascade.setMenu(sub);
		createMenuItem(_comm, sub, MenuID.CopyTimingConvertedKeyCodeUse, &copyKeyCodeWith!(FKCKind.Use), &canCopyWith);
		createMenuItem(_comm, sub, MenuID.CopyTimingConvertedKeyCodeSuccess, &copyKeyCodeWith!(FKCKind.Success), &canCopyWith);
		createMenuItem(_comm, sub, MenuID.CopyTimingConvertedKeyCodeFailure, &copyKeyCodeWith!(FKCKind.Failure), &canCopyWith);
		createMenuItem(_comm, sub, MenuID.CopyTimingConvertedKeyCodeHasNot, &copyKeyCodeWith!(FKCKind.HasNot), &canCopyWith);
		if (!readOnly && _getMotions) { mixin(S_TRACE);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.AddKeyCodesByFeatures, &addKeyCodesByFeatures, &canAddKeyCodesByFeatures);
		}
	}

	@property
	override
	protected AbstractTableEdit[] editors() { return _tce ? [cast(AbstractTableEdit)_tte, _tce] : [cast(AbstractTableEdit)_tte]; }
	@property
	override
	protected AbstractTableEdit mainEditor() { return _tte; }

	this (Commons comm, Summary summ, Composite parent, int style, bool canDuplicate, bool withIgnitionType, bool delegate() catchMod, const(Motion)[] delegate() getMotions = null) { mixin(S_TRACE);
		_comm = comm;
		_summ = summ;
		_withIgnitionType = withIgnitionType;
		_catchMod = catchMod;
		_getMotions = getMotions;

		super (comm, parent, style, canDuplicate);

		_comm.refDataVersion.add(&refDataVersion);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			_comm.refDataVersion.remove(&refDataVersion);
		});
	}

	alias values keyCodes;

	@property
	string[] warnings() { mixin(S_TRACE);
		auto keyCodes = this.keyCodes;
		string[] ws;
		foreach (keyCode; keyCodes) { mixin(S_TRACE);
			ws ~= .sjisWarnings(_comm.prop.parent, _summ, keyCode, _comm.prop.msgs.keyCode);
			if (_withIgnitionType && !_comm.prop.targetVersion(_summ, "1.50")) { mixin(S_TRACE);
				if (_comm.prop.sys.fireKeyCodeKind(keyCode) is FKCKind.HasNot) { mixin(S_TRACE);
					ws ~= _comm.prop.msgs.warningHasNotKeyCode;
					break;
				}
			}
		}
		if (!canDuplicate && keyCodes.length && keyCodes[0] == "MatchingType=All") { mixin(S_TRACE);
			ws ~= _comm.prop.msgs.searchErrorKeyCodeMatchingAll;
		}
		if (canDuplicate && _comm.prop.sys.isRunAway(keyCodes)) { mixin(S_TRACE);
			ws ~= .tryFormat(_comm.prop.msgs.warningRunAwayCard, _comm.prop.sys.runAway);
		}
		if (canDuplicate && _summ && _summ.legacy && _comm.prop.looks.keyCodesMaxLegacy < keyCodes.length) { mixin(S_TRACE);
			ws ~= .tryFormat(_comm.prop.msgs.warningKeyCodeCount, _comm.prop.looks.keyCodesMaxLegacy);
		}
		string[] ws2;
		bool[string] wSet;
		foreach (w; ws) { mixin(S_TRACE);
			if (w !in wSet) { mixin(S_TRACE);
				wSet[w] = true;
				ws2 ~= w;
			}
		}
		return ws2;
	}

	protected override string[] getWarnings(TableItem itm) { mixin(S_TRACE);
		auto keyCode = itm.getText();
		string[] ws;
		ws ~= .sjisWarnings(_comm.prop.parent, _summ, keyCode, _comm.prop.msgs.keyCode);
		if (_withIgnitionType && !_comm.prop.targetVersion(_summ, "1.50")) { mixin(S_TRACE);
			if (_comm.prop.sys.fireKeyCodeKind(keyCode) is FKCKind.HasNot) { mixin(S_TRACE);
				ws ~= _comm.prop.msgs.warningHasNotKeyCode;
			}
		}
		auto table = itm.getParent();
		if (!canDuplicate && table.getItemCount() && itm is table.getItem(0) && keyCode == "MatchingType=All") { mixin(S_TRACE);
			ws ~= _comm.prop.msgs.searchErrorKeyCodeMatchingAll;
		}
		if (canDuplicate && _comm.prop.sys.isRunAway([keyCode])) { mixin(S_TRACE);
			ws ~= .tryFormat(_comm.prop.msgs.warningRunAwayCard, _comm.prop.sys.runAway);
		}
		return ws;
	}

	@property
	private bool canConvKeyCode(FKCKind Kind)() { mixin(S_TRACE);
		if (readOnly) return false;
		if (canDuplicate) { mixin(S_TRACE);
			foreach (name; keyCodes) { mixin(S_TRACE);
				if (name == "") continue;
				if (name != _comm.prop.sys.convFireKeyCode(name, Kind)) return true;
			}
			return false;
		} else { mixin(S_TRACE);
			if (!_withIgnitionType && Kind !is FKCKind.HasNot && Kind !is FKCKind.Use) return false;
			bool[string] kTable;
			foreach (name; keyCodes) { mixin(S_TRACE);
				if (name == "") continue;
				kTable[name] = true;
			}
			foreach (i; selectionIndices) { mixin(S_TRACE);
				auto name = value(i);
				if (name == "") continue;
				auto name2 = _comm.prop.sys.convFireKeyCode(name, Kind);
				if (name2 !in kTable) return true;
				kTable.remove(name);
				kTable[name2] = true;
			}
			return false;
		}
	}
	private void convKeyCode(FKCKind Kind)() { mixin(S_TRACE);
		if (!canConvKeyCode!Kind) return;
		table.setRedraw(false);
		scope (exit) table.setRedraw(true);
		foreach (e; editors) { mixin(S_TRACE);
			if (e && e.isEditing) e.enter();
		}
		storeAll();

		if (canDuplicate) { mixin(S_TRACE);
			foreach (i; selectionIndices) { mixin(S_TRACE);
				auto name = value(i);
				if (name == "") continue;
				name = _comm.prop.sys.convFireKeyCode(name, Kind);
				setValue(i, name);
			}
		} else { mixin(S_TRACE);
			bool[string] kTable;
			foreach (name; keyCodes) { mixin(S_TRACE);
				if (name == "") continue;
				kTable[name] = true;
			}
			foreach (i; selectionIndices) { mixin(S_TRACE);
				auto name = value(i);
				if (name == "") continue;
				kTable.remove(name);
				name = _comm.prop.sys.convFireKeyCode(name, Kind);
				if (name in kTable) continue;
				kTable[name] = true;
				setValue(i, name);
			}
		}
		raiseModifyEvent();
		_comm.refreshToolBar();
	}
	@property
	private bool canCopyWith() { mixin(S_TRACE);
		foreach (i; selectionIndices) { mixin(S_TRACE);
			if (value(i) != "") return true;
		}
		return false;
	}
	private void copyKeyCodeWith(FKCKind Kind)() { mixin(S_TRACE);
		if (!canCopyWith) return;
		foreach (e; editors) { mixin(S_TRACE);
			if (e && e.isEditing) e.enter();
		}
		auto keyCodes = selectionIndices.filter!(i => value(i) != "")().map!(i => _comm.prop.sys.convFireKeyCode(value(i), Kind))().array();
		if (keyCodes.length) { mixin(S_TRACE);
			XMLtoCB(_comm.prop, _comm.clipboard, .keyCodesToXML(keyCodes));
			_comm.refreshToolBar();
		}
	}

	private SelectCardFeaturesDialog _selectFeaturesDlg = null;
	@property
	private bool canAddKeyCodesByFeatures() { mixin(S_TRACE);
		return !readOnly && _getMotions && (_comm.prop.keyCodesByFeatures(_comm.skin.type).length || _getMotions().length);
	}
	private void addKeyCodesByFeatures() { mixin(S_TRACE);
		if (!canAddKeyCodesByFeatures) return;

		if (_selectFeaturesDlg) { mixin(S_TRACE);
			_selectFeaturesDlg.active();
			return;
		}
		if (_comm.prop.keyCodesByFeatures(_comm.skin.type).length) { mixin(S_TRACE);
			_selectFeaturesDlg = new SelectCardFeaturesDialog(_comm, getShell());
			_selectFeaturesDlg.closeEvent ~= { _selectFeaturesDlg = null; };
			_selectFeaturesDlg.appliedEvent ~= { addKeyCodesByFeatures2(_selectFeaturesDlg.keyCodes); };
			_selectFeaturesDlg.open();
		} else { mixin(S_TRACE);
			addKeyCodesByFeatures2([]);
		}
	}
	private void addKeyCodesByFeatures2(in string[] byFeatures) { mixin(S_TRACE);
		foreach (e; editors) { mixin(S_TRACE);
			if (e && e.isEditing) e.enter();
		}
		bool[string] keyCodes;
		foreach (keyCode; this.keyCodes) keyCodes[keyCode] = true;

		string[] add;
		foreach (keyCode; byFeatures) { mixin(S_TRACE);
			if (keyCode in keyCodes) continue;
			add ~= keyCode;
			keyCodes[keyCode] = true;
		}

		foreach (m; _getMotions()) { mixin(S_TRACE);
			foreach (ref kcm; _comm.prop.keyCodesByMotions(_comm.skin.type)) { mixin(S_TRACE);
				if (kcm.match(m.type, m.element)) { mixin(S_TRACE);
					if (kcm.keyCode in keyCodes) continue;
					add ~= kcm.keyCode;
					keyCodes[kcm.keyCode] = true;
				}
			}
		}

		if (!add.length) return;
		string[] noAdd;
		if (maxCount <= valueCount) { mixin(S_TRACE);
			noAdd = add;
			add = [];
		} else if (maxCount < valueCount + add.length) { mixin(S_TRACE);
			noAdd = add[maxCount - valueCount .. $];
			add = add[0 .. maxCount - valueCount];
		}
		if (add.length) { mixin(S_TRACE);
			storeAll();
			appendValues(add);
		}
		if (noAdd.length) { mixin(S_TRACE);
			.asyncExec(getDisplay(), { mixin(S_TRACE);
				auto dlg = new AddKeyCodeErrorDialog(_comm, getShell(), noAdd);
				dlg.open();
			});
		}
	}
}

class SelectCardFeaturesDialog : AbsDialog {
	private Commons _comm;

	private Table _features;

	private string[] _keyCodes;

	private void refKeyCodesByFeatures() { mixin(S_TRACE);
		if (_comm.prop.keyCodesByFeatures(_comm.skin.type).length == 0) { mixin(S_TRACE);
			forceCancel();
		} else { mixin(S_TRACE);
			_features.setItemCount(cast(int)_comm.prop.keyCodesByFeatures(_comm.skin.type).length);
			_features.clearAll();
		}
	}

	this (Commons comm, Shell shell) { mixin(S_TRACE);
		super (comm.prop, shell, false, comm.prop.msgs.selectFeatures, comm.prop.images.menu(MenuID.AddKeyCodesByFeatures), true, comm.prop.var.selectFeaturesDlg, false, true);
		_comm = comm;
		enterClose = true;
	}

	@property
	const
	const(string)[] keyCodes() { return _keyCodes; }

	override void setup(Composite area) { mixin(S_TRACE);
		auto d = area.getDisplay();
		area.setLayout(.normalGridLayout(1, false));

		auto l = new Label(area, SWT.WRAP);
		l.setText(_comm.prop.msgs.selectFeaturesHint);
		l.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

		_features = .rangeSelectableTable(area, SWT.MULTI | SWT.CHECK | SWT.BORDER | SWT.H_SCROLL | SWT.V_SCROLL | SWT.FULL_SELECTION | SWT.VIRTUAL);
		new FullTableColumn(_features, SWT.NONE);
		_features.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto menu = new Menu(_features.getShell());
		createMenuItem(_comm, menu, MenuID.SelectAll, &selectAll, () => _features.getSelectionCount() < _features.getItemCount());
		_features.setMenu(menu);

		.listener(_features, SWT.SetData, (e) { mixin(S_TRACE);
			auto itm = cast(TableItem)e.item;
			itm.setText(_comm.prop.keyCodesByFeatures(_comm.skin.type)[e.index].feature);
		});
		.listener(_features, SWT.Selection, (e) { .updateChecked(e); });
		_comm.refSkin.add(&refKeyCodesByFeatures);
		_comm.refKeyCodesByFeatures.add(&refKeyCodesByFeatures);
		.listener(_features, SWT.Dispose, { mixin(S_TRACE);
			_comm.refSkin.remove(&refKeyCodesByFeatures);
			_comm.refKeyCodesByFeatures.remove(&refKeyCodesByFeatures);
		});
		refKeyCodesByFeatures();
	}

	private void selectAll() { mixin(S_TRACE);
		_features.selectAll();
	}

	override
	bool close(bool ok, out bool cancel) { mixin(S_TRACE);
		bool[string] keyCodes;
		foreach (i, itm; _features.getItems()) { mixin(S_TRACE);
			if (!itm.getChecked()) continue;
			auto feature = _comm.prop.keyCodesByFeatures(_comm.skin.type)[i];
			if (feature.keyCode in keyCodes) continue;
			_keyCodes ~= feature.keyCode;
			keyCodes[feature.keyCode] = true;
		}
		return true;
	}
}

class AddKeyCodeErrorDialog : AbsDialog {

	private Commons _comm = null;
	private const(string)[] _keyCodes = [];
	private Table _table = null;

	this (Commons comm, Shell shell, const(string)[] keyCodes) in (keyCodes.length) { mixin(S_TRACE);
		_comm = comm;
		_keyCodes = keyCodes;
		super (_comm.prop, shell, true, _comm.prop.msgs.addKeyCodesError, _comm.prop.images.warning, true, _comm.prop.var.addKeyCodesErrorDlg, false, false);
		enterClose = true;
		firstFocusIsOK = true;
	}

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(1, true));

		auto l = new Label(area, SWT.WRAP);
		l.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		l.setText(.tryFormat(_comm.prop.msgs.addKeyCodesErrorDesc, _comm.prop.looks.keyCodesMaxLegacy));

		_table = .rangeSelectableTable(area, SWT.BORDER | SWT.MULTI | SWT.H_SCROLL | SWT.V_SCROLL | SWT.FULL_SELECTION);
		_table.setLayoutData(new GridData(GridData.FILL_BOTH));
		new FullTableColumn(_table, SWT.NONE);
		auto menu = new Menu(_table.getShell());
		createMenuItem(_comm, menu, MenuID.Copy, &copy, () => _table.getSelectionIndex() != -1);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.SelectAll, &selectAll, () => _table.getSelectionCount() < _table.getItemCount());
		_table.setMenu(menu);

		foreach (keyCode; _keyCodes) { mixin(S_TRACE);
			auto itm = new TableItem(_table, SWT.NONE);
			itm.setImage(_comm.prop.images.keyCode);
			itm.setText(keyCode);
		}
	}

	private void copy() { mixin(S_TRACE);
		string[] keyCodes;
		foreach (itm; _table.getSelection()) { mixin(S_TRACE);
			keyCodes ~= itm.getText();
		}
		if (!keyCodes.length) return;
		XMLtoCB(_comm.prop, _comm.clipboard, .keyCodesToXML(keyCodes));
		_comm.refreshToolBar();
	}

	private void selectAll() { mixin(S_TRACE);
		_table.selectAll();
	}
}
