
module cwx.editor.gui.dwt.autokeycode;

import cwx.menu;
import cwx.structs;
import cwx.system;
import cwx.types;
import cwx.utils;
import cwx.xml;

import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.editablelistview;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

import std.algorithm;
import std.array;
import std.range;
import std.traits;

import org.eclipse.swt.all;

import java.lang.all;

public:

class KeyCodeByFeatureView : AbstractEditableListView!(KeyCodeByFeature) {

	private Commons _comm;
	private string delegate() _skinType;

	private TableTextEdit _tfe = null;
	private TableTextEdit _tke = null;

	private bool delegate() _catchMod;

	private Control createKeyCodeEditor(TableItem itm, int editC) { mixin(S_TRACE);
		return .createKeyCodeCombo!Combo(_comm, null, itm.getParent(), _catchMod, itm.getText(1), false, _skinType);
	}
	private void featureEditEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
		auto index = itm.getParent().indexOf(itm);
		mainValueEditEnd(itm, KeyCodeByFeature(newText, value(index).keyCode));
	}
	private void keyCodeEditEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
		auto index = itm.getParent().indexOf(itm);
		subValueEditEnd(itm, KeyCodeByFeature(value(index).feature, newText));
	}

	override
	protected KeyCodeByFeature[] createFromNode(ref XNode node) { mixin(S_TRACE);
		KeyCodeByFeature[] list;
		node.onTag[KeyCodeByFeature.XML_NAME] = (ref XNode node) { mixin(S_TRACE);
			list.length += 1;
			list[$ - 1].fromNode(node);
		};
		node.parse();
		return list;
	}
	override
	protected XNode toNode(in int[] indices) { mixin(S_TRACE);
		auto node = XNode.create(xmlName);
		foreach (i; indices) value(i).toNode(node);
		return node;
	}
	@property
	const
	override
	protected string xmlName() { return "keyCodesByFeatures"; }

	override
	protected void initColumns(Table table) { mixin(S_TRACE);
		table.setHeaderVisible(true);
		auto featureCol = new TableColumn(table, SWT.NONE);
		featureCol.setText(_comm.prop.msgs.cardFeature);
		auto keyCodeCol = new TableColumn(table, SWT.NONE);
		keyCodeCol.setText(_comm.prop.msgs.keyCode);
		saveColumnWidth!("prop.var.etc.keyCodesByFeaturesFeatureColumn")(_comm.prop, featureCol);
		saveColumnWidth!("prop.var.etc.keyCodesByFeaturesKeyCodeColumn")(_comm.prop, keyCodeCol);
	}
	override
	protected void initEditors(Table table) { mixin(S_TRACE);
		_tfe = new TableTextEdit(_comm, _comm.prop, table, 0, &featureEditEnd, (itm, column) => true, (itm, editC) => .createTextEditor(_comm, _comm.prop, itm.getParent(), itm.getText()));
		_tke = new TableTextEdit(_comm, _comm.prop, table, 1, &keyCodeEditEnd, (itm, column) => true, &createKeyCodeEditor);
	}
	@property
	override
	protected AbstractTableEdit[] editors() { return [cast(AbstractTableEdit)_tfe, _tke]; }
	@property
	override
	protected AbstractTableEdit mainEditor() { return _tfe; }

	override
	protected void updateItem(in KeyCodeByFeature value, TableItem itm) { mixin(S_TRACE);
		itm.setImage(0, _comm.prop.images.cards);
		itm.setText(0, value.feature);
		itm.setImage(1, _comm.prop.images.keyCode);
		itm.setText(1, value.keyCode);
	}

	override
	const
	protected bool isValidValue(in KeyCodeByFeature value) { mixin(S_TRACE);
		return value.feature != "";
	}

	this (Commons comm, Composite parent, int style, string delegate() skinType, bool delegate() catchMod) { mixin(S_TRACE);
		_comm = comm;
		_skinType = skinType;
		_catchMod = catchMod;

		super (comm, parent, style, true);
	}
}

class KeyCodeByMotionView : AbstractEditableListView!(KeyCodeByMotion) {

	private Commons _comm;
	private string delegate() _skinType;

	private TableComboEdit!Combo _tme = null;
	private TableComboEdit!Combo _tee = null;
	private TableTextEdit _tke = null;

	private bool delegate() _catchMod;

	private void createMotionEditor(TableItem itm, int column, out string[] strs, out string str, out bool canIncSearch) { mixin(S_TRACE);
		auto index = itm.getParent().indexOf(itm);
		foreach (i, type; EnumMembers!MType) { mixin(S_TRACE);
			strs ~= _comm.prop.msgs.motionName(type);
			if (value(index).type is type) str = strs[$ - 1];
		}
		canIncSearch = false;
	}
	private void createElementEditor(TableItem itm, int column, out string[] strs, out string str, out bool canIncSearch) { mixin(S_TRACE);
		auto index = itm.getParent().indexOf(itm);
		strs ~= _comm.prop.msgs.defaultSelection(_comm.prop.msgs.noElement);
		str = strs[$ - 1];
		foreach (i, element; EnumMembers!Element) { mixin(S_TRACE);
			strs ~= _comm.prop.msgs.elementName(element);
			auto val = value(index);
			if (val.hasElement && val.element is element) str = strs[$ - 1];
		}
		canIncSearch = false;
	}
	private Control createKeyCodeEditor(TableItem itm, int editC) { mixin(S_TRACE);
		return .createKeyCodeCombo!Combo(_comm, null, itm.getParent(), _catchMod, itm.getText(2), false, _skinType);
	}
	private void motionEditEnd(TableItem selItm, int column, Combo combo) { mixin(S_TRACE);
		auto sel = combo.getSelectionIndex();
		if (sel == -1) return;
		auto index = selItm.getParent().indexOf(selItm);
		auto value = this.value(index);
		value.type = [EnumMembers!MType][sel];
		mainValueEditEnd(selItm, value);
	}
	private void elementEditEnd(TableItem selItm, int column, Combo combo) { mixin(S_TRACE);
		auto sel = combo.getSelectionIndex();
		if (sel == -1) return;
		auto index = selItm.getParent().indexOf(selItm);
		auto value = this.value(index);
		if (sel == 0) { mixin(S_TRACE);
			value.element = Element.All;
			value.hasElement = false;
		} else { mixin(S_TRACE);
			value.element = [EnumMembers!Element][sel - 1];
			value.hasElement = true;
		}
		subValueEditEnd(selItm, value);
	}
	private void keyCodeEditEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
		auto index = itm.getParent().indexOf(itm);
		auto value = this.value(index);
		value.keyCode = newText;
		subValueEditEnd(itm, value);
	}

	override
	protected KeyCodeByMotion[] createFromNode(ref XNode node) { mixin(S_TRACE);
		KeyCodeByMotion[] list;
		node.onTag[KeyCodeByMotion.XML_NAME] = (ref XNode node) { mixin(S_TRACE);
			list.length += 1;
			list[$ - 1].fromNode(node);
		};
		node.parse();
		return list;
	}
	override
	protected XNode toNode(in int[] indices) { mixin(S_TRACE);
		auto node = XNode.create(xmlName);
		foreach (i; indices) value(i).toNode(node);
		return node;
	}
	@property
	const
	override
	protected string xmlName() { return "keyCodesByMotions"; }

	override
	protected void initColumns(Table table) { mixin(S_TRACE);
		table.setHeaderVisible(true);
		auto motionCol = new TableColumn(table, SWT.NONE);
		motionCol.setText(_comm.prop.msgs.motion);
		auto elementCol = new TableColumn(table, SWT.NONE);
		elementCol.setText(_comm.prop.msgs.motionElement);
		auto keyCodeCol = new TableColumn(table, SWT.NONE);
		keyCodeCol.setText(_comm.prop.msgs.keyCode);
		saveColumnWidth!("prop.var.etc.keyCodesByMotionsMotionColumn")(_comm.prop, motionCol);
		saveColumnWidth!("prop.var.etc.keyCodesByMotionsElementColumn")(_comm.prop, elementCol);
		saveColumnWidth!("prop.var.etc.keyCodesByMotionsKeyCodeColumn")(_comm.prop, keyCodeCol);
	}
	override
	protected void initEditors(Table table) { mixin(S_TRACE);
		_tme = new TableComboEdit!Combo(_comm, _comm.prop, table, 0, &createMotionEditor, &motionEditEnd, null);
		_tee = new TableComboEdit!Combo(_comm, _comm.prop, table, 1, &createElementEditor, &elementEditEnd, null);
		_tke = new TableTextEdit(_comm, _comm.prop, table, 2, &keyCodeEditEnd, (itm, column) => true, &createKeyCodeEditor);
	}
	@property
	override
	protected AbstractTableEdit[] editors() { return [cast(AbstractTableEdit)_tme, _tee, _tke]; }
	@property
	override
	protected AbstractTableEdit mainEditor() { return _tme; }

	override
	protected void updateItem(in KeyCodeByMotion value, TableItem itm) { mixin(S_TRACE);
		itm.setImage(0, _comm.prop.images.motion(value.type));
		itm.setText(0, _comm.prop.msgs.motionName(value.type));
		if (value.hasElement) { mixin(S_TRACE);
			itm.setImage(1, _comm.prop.images.element(value.element));
			itm.setText(1, _comm.prop.msgs.elementName(value.element));
		} else { mixin(S_TRACE);
			itm.setImage(1, _comm.prop.images.emptyIcon);
			itm.setText(1, _comm.prop.msgs.defaultSelection(_comm.prop.msgs.noElement));
		}
		itm.setImage(2, _comm.prop.images.keyCode);
		itm.setText(2, value.keyCode);
	}

	this (Commons comm, Composite parent, int style, string delegate() skinType, bool delegate() catchMod) { mixin(S_TRACE);
		_comm = comm;
		_skinType = skinType;
		_catchMod = catchMod;

		super (comm, parent, style, true);
	}
}
