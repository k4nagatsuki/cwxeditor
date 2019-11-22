
module cwx.editor.gui.dwt.flagtable;

import cwx.card;
import cwx.event;
import cwx.expression;
import cwx.flag;
import cwx.menu;
import cwx.msgutils;
import cwx.path;
import cwx.sjis;
import cwx.structs;
import cwx.summary;
import cwx.system;
import cwx.types;
import cwx.usecounter;
import cwx.utils;
import cwx.warning;
import cwx.xml;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.messageutils;
import cwx.editor.gui.dwt.replacedialog;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

static import std.algorithm;
import std.algorithm: each, map, max, min;
import std.array;
import std.ascii;
import std.conv;
import std.datetime;
import std.exception;
import std.range;
import std.string;
import std.typecons;

import org.eclipse.swt.all;

import java.lang.all;

/// ステップ設定用のダイアログ。
public class StepEditDialog : AbsDialog {
private:
	Commons _comm;
	Summary _summ;
	int _readOnly;
	bool _local;

	Step _step;
	FlagDir _dir;

	Text _name;
	Combo _init;
	bool _initInit = false;
	int _initSelected = -1;
	Table _values;
	string[] _valueCache;
	TableTextEdit _tte;
	Text _valueEditor = null;
	int _editIndex = -1;
	Spinner _stepCount;
	Combo _initTim;
	VariableInitialization[] _initTims;
	Button _expandSPChars;

	UndoManager _undo;

	abstract class SVUndo : Undo {
		private int[] _selected;
		private int[] _selected2;
		this () { mixin(S_TRACE);
			_selected = _values.getSelectionIndices();
		}
		protected void udb() { mixin(S_TRACE);
			if (_tte.isEditing) _tte.cancel();
			_values.setRedraw(false);
			_selected2 = _selected;
			_selected = _values.getSelectionIndices();
		}
		protected void uda() { mixin(S_TRACE);
			_values.deselectAll();
			_values.select(_selected2);
			_selected2 = [];
			_values.setRedraw(true);
		}
	}

	class UndoValue : SVUndo {
		private int _index;
		private string _oldName;
		private string _newName;
		this (int index, string oldName, string newName) { mixin(S_TRACE);
			_index = index;
			_oldName = oldName;
			_newName = newName;
		}
		private void impl() { mixin(S_TRACE);
			udb();
			scope (exit) uda();

			_valueCache[_index] = _oldName;
			_values.clear(_index);
			if (_initInit) { mixin(S_TRACE);
				_init.setItem(_index, _oldName);
			} else if (_index == _initSelected) { mixin(S_TRACE);
				_init.setItem(0, _oldName);
			}
			auto temp = _oldName;
			_oldName = _newName;
			_newName = temp;
		}
		void undo() { impl(); }
		void redo() { impl(); }
		void dispose() { }
	}
	void storeSingle(int index, string oldName, string newName) { mixin(S_TRACE);
		_undo ~= new UndoValue(index, oldName, newName);
	}
	class UndoValues : SVUndo {
		private string[] _values;
		this () { mixin(S_TRACE);
			_values = _valueCache[0 .. this.outer._values.getItemCount()].dup;
		}
		private void impl() { mixin(S_TRACE);
			udb();
			scope (exit) uda();

			auto values = _values;
			auto num = _stepCount.getSelection();
			_values = _valueCache[0 .. this.outer._values.getItemCount()].dup;
			_valueCache[0 .. values.length] = values[];

			changeStepCount(false, cast(int)values.length);
			foreach (i; 0 .. cast(int)values.length) { mixin(S_TRACE);
				this.outer._values.clear(i);
			}
			updateInitCombo();
			refDataVersion();
		}
		void undo() { impl(); }
		void redo() { impl(); }
		void dispose() { }
	}
	void storeAll() { mixin(S_TRACE);
		_undo ~= new UndoValues;
	}

	alias Tuple!(size_t, "fromIndex", size_t, "toIndex") URange;
	class UndoValueRange : SVUndo {
		private size_t[] _fromIndices;
		private string[][] _values;
		this (in URange[] ranges) { mixin(S_TRACE);
			foreach (range; ranges) { mixin(S_TRACE);
				_fromIndices ~= range.fromIndex;
				_values ~= _valueCache[range.fromIndex .. range.toIndex].dup;
			}
		}
		private void impl() { mixin(S_TRACE);
			udb();
			scope (exit) uda();

			foreach (fromIndex, values; .zip(_fromIndices, _values)) { mixin(S_TRACE);
				auto temp = _valueCache[fromIndex .. fromIndex + values.length].dup;
				_valueCache[fromIndex .. fromIndex + values.length] = values[];
				values[] = temp[];
				this.outer._values.clear(cast(int)fromIndex, cast(int)(fromIndex + values.length) - 1);
			}
			updateInitCombo();
			refDataVersion();
		}
		void undo() { impl(); }
		void redo() { impl(); }
		void dispose() { }
	}
	void storeRange(URange[] ranges) { mixin(S_TRACE);
		_undo ~= new UndoValueRange(ranges);
	}

	class UndoInsertDelete : SVUndo {
		private size_t[] _indices;
		private string[] _values;
		this (in size_t[] indices, bool insert) { mixin(S_TRACE);
			foreach (index; indices) { mixin(S_TRACE);
				_indices ~= index;
				if (!insert) _values ~= _valueCache[index];
			}
		}
		private void impl() { mixin(S_TRACE);
			udb();
			scope (exit) uda();

			if (_values.length) { mixin(S_TRACE);
				// 削除のアンドゥ(挿入を行う)
				foreach (index, value; .zip(_indices, _values)) { mixin(S_TRACE);
					_valueCache = _valueCache[0 .. index] ~ value ~ _valueCache[index .. $];
				}
				_values = [];
				this.outer._values.clear(cast(int)_indices[0], this.outer._values.getItemCount() - 1);
				this.outer._values.setItemCount(this.outer._values.getItemCount() + cast(int)_indices.length);
			} else { mixin(S_TRACE);
				// 挿入のアンドゥ(削除を行う)
				foreach_reverse (index; _indices) { mixin(S_TRACE);
					_values ~= _valueCache[index];
					std.algorithm.remove(_valueCache, index);
				}
				std.algorithm.reverse(_values);
				this.outer._values.setItemCount(this.outer._values.getItemCount() - cast(int)_indices.length);
				this.outer._values.clear(cast(int)_indices[0], this.outer._values.getItemCount() - 1);
			}
			_stepCount.setSelection(this.outer._values.getItemCount());
			updateInitCombo();
			refDataVersion();
		}
		void undo() { impl(); }
		void redo() { impl(); }
		void dispose() { }
	}
	void storeInsert(in size_t[] indices) { mixin(S_TRACE);
		_undo ~= new UndoInsertDelete(indices, true);
	}
	void storeDelete(in size_t[] indices) { mixin(S_TRACE);
		_undo ~= new UndoInsertDelete(indices, false);
	}

	void refUndoMax() { mixin(S_TRACE);
		_undo.max = _comm.prop.var.etc.undoMaxEtc;
	}

	void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (_comm.prop.sys.isSystemVar(_name.getText())) { mixin(S_TRACE);
			ws ~= .tryFormat(_comm.prop.msgs.warningSystemVarName, _comm.prop.sys.prefixSystemVarName);
		}
		if (_values.getItemCount() != _comm.prop.looks.stepMaxCount && _summ && _summ.legacy) { mixin(S_TRACE);
			ws ~= .tryFormat(_comm.prop.msgs.warningStepCount, _comm.prop.looks.stepMaxCount);
		}
		if (_expandSPChars.getSelection() && !_comm.prop.isTargetVersion(_summ, "2")) { mixin(S_TRACE);
			ws ~= _comm.prop.msgs.warningExpandSPChars;
		}
		ws ~= .sjisWarnings(_comm.prop.parent, _summ, _name.getText(), _comm.prop.msgs.dlgLblStepName);
		void editing(string[] vals) { mixin(S_TRACE);
			if (_editIndex != -1) vals[_editIndex] = _valueEditor.getText();
		}
		if (_expandSPChars.getSelection()) { mixin(S_TRACE);
			bool[string] ws2;
			auto vals = _valueCache[0 .. _stepCount.getSelection()];
			editing(vals);
			foreach (v; vals) { mixin(S_TRACE);
				bool[string] wFlags;
				bool[string] wSteps;
				bool[string] wVariants;
				bool[string] wFonts;
				bool[char] wColors;
				string[] flags;
				string[] steps;
				string[] variants;
				string[] fonts;
				char[] colors;
				textUseItems(wrapReturnCode(v), flags, steps, variants, fonts, colors);
				fonts = [];
				colors = [];
				auto isClassic = _summ && _summ.legacy;
				auto wsnVer = _summ ? _summ.dataVersion : LATEST_VERSION;
				auto ws3 = .textWarnings(_comm.prop.parent, _comm.skin, _summ, _dir.useCounter, isClassic, wsnVer, _comm.prop.var.etc.targetVersion,
					v, flags, steps, variants, fonts, colors, wFlags, wSteps, wVariants, wFonts, wColors).all;
				foreach (w; ws3) { mixin(S_TRACE);
					if (w in ws2) continue;
					ws2[w] = true;
					ws ~= w;
				}
			}
		}
		if (_initTim.getSelectionIndex() != -1 && !_local && _initTims[_initTim.getSelectionIndex()] !is VariableInitialization.Leave && !_comm.prop.isTargetVersion(_summ, "4")) { mixin(S_TRACE);
			ws ~= _comm.prop.msgs.warningVariableInitialization;
		}
		if (_valueCache.length && _summ.legacy) { mixin(S_TRACE);
			auto vals = _valueCache[0 .. _stepCount.getSelection()];
			editing(vals);
			foreach (val; vals) { mixin(S_TRACE);
				ws ~= .sjisWarnings(_comm.prop.parent, _summ, val, _comm.prop.msgs.stepValueForWarning);
			}
		}
		warning = ws;
	}

	void changeStepCount(bool store, int num) { mixin(S_TRACE);
		if (_readOnly) return;
		if (num == 0) return;
		auto ic = _values.getItemCount();
		if (ic == num) return;
		if (ic < num) { mixin(S_TRACE);
			_values.setRedraw(false);
			scope (exit) _values.setRedraw(true);
			_values.setItemCount(num);
			foreach (index; ic .. num) { mixin(S_TRACE);
				if (store && _valueCache.length <= index) { mixin(S_TRACE);
					auto lastValue = _valueCache[index - 1];
					lastValue = createNewName(lastValue, (string name) { mixin(S_TRACE);
						return name != lastValue || name == "";
					});
					_valueCache ~= lastValue;
				}
			}
			if (store) storeInsert(.iota(cast(size_t)ic, cast(size_t)_values.getItemCount()).array());
		} else if (num < ic) { mixin(S_TRACE);
			_values.setRedraw(false);
			scope (exit) _values.setRedraw(true);
			_values.setItemCount(num);
			if (store) storeDelete(.iota(cast(size_t)_values.getItemCount(), cast(size_t)ic).array());
		}
		if (_stepCount.getSelection() != num) _stepCount.setSelection(num);
		if (store) updateInitCombo();
		refDataVersion();
	}
	void updateInitCombo() { mixin(S_TRACE);
		_initSelected = .min(_initSelected, _values.getItemCount() - 1);
		_initInit = false;
		_init.removeAll();
		_init.add(_valueCache[_initSelected]);
		_init.select(0);
	}

	void valueEditEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
		_valueEditor = null;
		_editIndex = -1;
		if (itm.getText(1) == newText) return;
		auto index = _values.indexOf(itm);
		storeSingle(index, itm.getText(1), newText);
		_valueCache[index] = newText;
		_values.clear(index);
		if (_initInit) { mixin(S_TRACE);
			_init.setItem(index, newText);
		} else if (index == _initSelected) { mixin(S_TRACE);
			_init.setItem(0, newText);
		}
		applyEnabled();
		refreshWarning();
	}

	void delStep(cwx.flag.Flag[] flag, Step[] step, cwx.flag.Variant[] variants) { mixin(S_TRACE);
		if (_readOnly) return;
		foreach (s; step) { mixin(S_TRACE);
			if (s is _step) { mixin(S_TRACE);
				forceCancel();
				return;
			}
		}
		refreshWarning();
		updateToolTip();
	}
	void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps, cwx.flag.Variant[] variants) { updateToolTip(); }
	void refPath(string o, string n, bool isDir) { updateToolTip(); }
	void refPaths(string parent) { updateToolTip(); }
	void updateToolTip() { mixin(S_TRACE);
		if (_valueEditor && !_valueEditor.isDisposed()) { mixin(S_TRACE);
			auto toolTip = createToolTip(_valueEditor.getText());
			if (toolTip != _valueEditor.getToolTipText()) { mixin(S_TRACE);
				_valueEditor.setToolTipText(toolTip);
			}
		}
		auto p = _values.toControl(_values.getDisplay().getCursorLocation());
		auto itm = _values.getItem(p);
		if (itm) { mixin(S_TRACE);
			string value;
			if (_valueEditor && !_valueEditor.isDisposed() && _editIndex == _values.indexOf(itm)) { mixin(S_TRACE);
				value = _valueEditor.getText();
			} else { mixin(S_TRACE);
				value = itm.getText(1);
			}
			auto toolTip = createToolTip(value);
			if (toolTip != _values.getToolTipText()) { mixin(S_TRACE);
				_values.setToolTipText(toolTip);
			}
		}
	}
	string createToolTip(string text) { mixin(S_TRACE);
		auto toolTip = "";
		if (_expandSPChars.getSelection()) { mixin(S_TRACE);
			toolTip = .createSPCharPreview(_comm, _summ, _dir.useCounter, text, true, null, (path) { mixin(S_TRACE);
				auto step = .findVar!Step(_summ ? _summ.flagDirRoot : null, _dir.useCounter, path);
				if (step && _step is step) { mixin(S_TRACE);
					if (_initSelected == _editIndex && _valueEditor && !_valueEditor.isDisposed()) { mixin(S_TRACE);
						return VarValue(true, _valueEditor.getText(), _expandSPChars.getSelection());
					}
					return VarValue(true, _valueCache[_initSelected], _expandSPChars.getSelection());
				}
				return VarValue(false);
			});
			toolTip = toolTip.replace("&", "&&");
		}
		return toolTip;
	}
	void refScenario(Summary summ) { mixin(S_TRACE);
		if (_readOnly) return;
		if (_summ is summ) forceCancel();
	}
	void refDataVersion() { mixin(S_TRACE);
		_stepCount.setEnabled(!_summ.legacy || _stepCount.getSelection() != _comm.prop.looks.stepMaxCount);
		_expandSPChars.setEnabled(!_summ.legacy || _expandSPChars.getSelection());
		_initTim.setEnabled(_local || !_summ.legacy || _initTims[_initTim.getSelectionIndex()] !is VariableInitialization.Leave);
		updateToolTip();
		refreshWarning();
	}

public:
	/// Params:
	/// dir = 設定するステップの親ディレクトリ。
	/// step = 設定するステップ。新規の場合はnull。
	this (Commons comm, Summary summ, Shell shell, bool readOnly, bool local, FlagDir dir, Step step = null) { mixin(S_TRACE);
		super (comm.prop, shell, readOnly, comm.prop.msgs.dlgTitStep, comm.prop.images.step, true, comm.prop.var.stepDlg, true);
		_comm = comm;
		_summ = summ;
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		_local = local;
		_dir = dir;
		_step = step;
		_undo = new UndoManager(_comm.prop.var.etc.undoMaxEtc);
		enterClose = readOnly;
	}

	/// Returns: 編集対象となったステップ。
	@property
	Step step() { mixin(S_TRACE);
		return _step;
	}
	/// 入力中の名前を妥当な形にして返す。
	@property
	string name() { mixin(S_TRACE);
		auto name = FlagDir.validName(_name.getText());
		return _dir.createNewStepName(name, _step ? _step.name : "");
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(normalGridLayout(2, false));
		{ mixin(S_TRACE);
			auto top = new SplitPane(area, SWT.HORIZONTAL);
			auto tgd = new GridData(GridData.FILL_HORIZONTAL);
			tgd.horizontalSpan = 2;
			top.setLayoutData(tgd);
			.setupWeights(top, _comm.prop.var.etc.stepTopSashL, _comm.prop.var.etc.stepTopSashR);

			auto comp1 = new Composite(top, SWT.NONE);
			comp1.setLayout(zeroMarginGridLayout(2, false));
			auto comp2 = new Composite(top, SWT.NONE);
			comp2.setLayout(zeroMarginGridLayout(4, false));

			auto l1 = new Label(comp1, SWT.NONE);
			l1.setText(_comm.prop.msgs.dlgLblStepName);
			_name = new Text(comp1, SWT.BORDER | _readOnly);
			mod(_name);
			createTextMenu!Text(_comm, _comm.prop, _name, &catchMod);
			setGridMinW(_name, _comm.prop.var.etc.flagNameWidth, GridData.FILL_HORIZONTAL);
			checker(_name);
			.listener(_name, SWT.Modify, &refreshWarning);

			auto l2 = new Label(comp2, SWT.NONE);
			l2.setText(_comm.prop.msgs.dlgLblStepInit);
			_init = new Combo(comp2, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_init);
			_init.setVisibleItemCount(_comm.prop.var.etc.comboVisibleItemCount);
			setGridMinW(_init, _comm.prop.var.etc.flagInitWidth, GridData.FILL_HORIZONTAL);
			_init.setEnabled(!_readOnly);

			auto l3 = new Label(comp2, SWT.NONE);
			l3.setText(_comm.prop.msgs.stepCount);
			_stepCount = new Spinner(comp2, SWT.BORDER);
			initSpinner(_stepCount);
			mod(_stepCount);
			_stepCount.setEnabled(!_readOnly);
			_stepCount.setMinimum(1);
			_stepCount.setMaximum(_comm.prop.var.etc.stepCountMax);
			.listener(_stepCount, SWT.Selection, () => changeStepCount(true, _stepCount.getSelection()));
			.listener(_stepCount, SWT.Modify, () => changeStepCount(true, _stepCount.getSelection()));
		}
		{ mixin(S_TRACE);
			_values = new Table(area, SWT.MULTI | SWT.FULL_SELECTION | SWT.BORDER | SWT.VIRTUAL);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.horizontalSpan = 2;
			_values.setLayoutData(gd);
			auto valueNumCol = new TableColumn(_values, SWT.NONE);
			auto prop = _comm.prop;
			saveColumnWidth!("prop.var.etc.valueNumberColumn")(_comm.prop, valueNumCol);
			auto nameCol = new FullTableColumn(_values, SWT.NONE);
			.listener(_values, SWT.MouseMove, &updateToolTip);

			auto menu = new Menu(_values.getShell(), SWT.POP_UP);
			if (_readOnly) { mixin(S_TRACE);
				createMenuItem(_comm, menu, MenuID.Copy, { mixin(S_TRACE);
					string[] t;
					foreach (itm; _values.getSelection()) { mixin(S_TRACE);
						t ~= itm.getText(1).replace("\n", .newline);
					}
					if (!t.length) return;
					auto text = new ArrayWrapperString(std.string.join(t, .newline));
					_comm.clipboard.setContents([text], [TextTransfer.getInstance()]);
					_comm.refreshToolBar();
				}, () => 0 < _values.getSelectionCount());
				new MenuItem(menu, SWT.SEPARATOR);
						createMenuItem(_comm, menu, MenuID.SelectAll, { .iota(0, _values.getItemCount()).each!(i => _values.select(i))(); }, () => _values.getItemCount() != _values.getSelectionCount());
			} else { mixin(S_TRACE);
				createMenuItem(_comm, menu, MenuID.Undo, { _undo.undo(); }, &_undo.canUndo);
				createMenuItem(_comm, menu, MenuID.Redo, { _undo.redo(); }, &_undo.canRedo);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.Up, &upValues, &canUpValues);
				createMenuItem(_comm, menu, MenuID.Down, &downValues, &canDownValues);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.CreateStepValues, &createStepValues, &canCreateStepValues);
			}
			_values.setMenu(menu);

			Control createEditor(TableItem itm, int editC) { mixin(S_TRACE);
				_valueEditor = createTextEditor(_comm, _comm.prop, _values, itm.getText(editC));
				_editIndex = itm.getParent().indexOf(itm);
				auto menu = _valueEditor.getMenu();
				new MenuItem(menu, SWT.SEPARATOR);
				.setupSPCharsMenu(_comm, _summ, _dir.useCounter, _valueEditor, menu, false, true, () => _expandSPChars.getSelection());
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.CreateStepValues, &createStepValues, &canCreateStepValues);
				updateToolTip();
				.listener(_valueEditor, SWT.Modify, &updateToolTip);
				.listener(_valueEditor, SWT.Modify, &refreshWarning);
				return _valueEditor;
			}
			if (!_readOnly) { mixin(S_TRACE);
				_tte = new TableTextEdit(_comm, _comm.prop, _values, 1, &valueEditEnd, (itm, column) => true, &createEditor);
				_tte.quickStart = EditStartType.Quick;
			}
		}
		{ mixin(S_TRACE);
			_expandSPChars = new Button(area, SWT.CHECK);
			mod(_expandSPChars);
			_expandSPChars.setEnabled(!_readOnly);
			_expandSPChars.setText(_comm.prop.msgs.expandSPChars);
			_expandSPChars.setToolTipText(_comm.prop.msgs.expandSPCharsHint.replace("&", "&&"));
			_expandSPChars.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_BEGINNING));
			.listener(_expandSPChars, SWT.Selection, &refDataVersion);
			.listener(_expandSPChars, SWT.Selection, &updateToolTip);

			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			comp.setLayout(zeroMarginGridLayout(2, false));
			auto l = new Label(comp, SWT.NONE);
			l.setText(_comm.prop.msgs.variableInitialization);
			_initTim = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_initTim);
			_initTim.setVisibleItemCount(_comm.prop.var.etc.comboVisibleItemCount);
			_initTim.setEnabled(!_readOnly);
			_initTims = FlagTable.selectableInitialization(_local);
			foreach (tim; _initTims) { mixin(S_TRACE);
				_initTim.add(_comm.prop.msgs.variableInitializationName(tim));
			}
			.listener(_initTim, SWT.Selection, &refDataVersion);
		}
		if (!_readOnly) { mixin(S_TRACE);
			_comm.delFlagAndStep.add(&delStep);
			_comm.refScenario.add(&refScenario);
			_comm.refDataVersion.add(&refDataVersion);
			_comm.refPreviewValues.add(&updateToolTip);
			_comm.refFlagAndStep.add(&refFlagAndStep);
			_comm.refPath.add(&refPath);
			_comm.refPaths.add(&refPaths);
			_comm.replText.add(&updateToolTip);
			.listener(area, SWT.Dispose, { mixin(S_TRACE);
				_comm.delFlagAndStep.remove(&delStep);
				_comm.refScenario.remove(&refScenario);
				_comm.refDataVersion.remove(&refDataVersion);
				_comm.refPreviewValues.remove(&updateToolTip);
				_comm.refFlagAndStep.remove(&refFlagAndStep);
				_comm.refPath.remove(&refPath);
				_comm.refPaths.remove(&refPaths);
				_comm.replText.remove(&updateToolTip);
			});
		}

		ignoreMod = true;
		scope (exit) .asyncExec(getShell().getDisplay(), { ignoreMod = false; });
		if (_step !is null) { mixin(S_TRACE);
			if (_step.parent) { mixin(S_TRACE);
				_name.setText(_step.name);
				_name.selectAll();
			} else { mixin(S_TRACE);
				// 新規作成時
				_name.setText("");
			}
			_valueCache = _step.values.dup;
		} else { mixin(S_TRACE);
			_name.setText("");
			_valueCache = .iota(_comm.prop.looks.stepMaxCount).map!(i => .parseDollarParams(_comm.prop.var.etc.stepValueName, ['N':.to!string(i)])).array();
		}

		.listener(_values, SWT.SetData, (e) { mixin(S_TRACE);
			auto item = cast(TableItem)e.item;
			auto i = e.index;
			item.setText(0, .text(i));
			item.setText(1, _valueCache[i]);
		});
		_values.setItemCount(cast(int)_valueCache.length);

		.listener(_init, SWT.FocusIn, { mixin(S_TRACE);
			if (!_initInit) { mixin(S_TRACE);
				auto index = _initSelected;
				setComboItems(_init, _valueCache[0 .. _values.getItemCount()]);
				_init.select(.min(_init.getItemCount() - 1, index));
				_initInit = true;
			}
		});
		.listener(_init, SWT.Selection, { mixin(S_TRACE);
			_initSelected = _init.getSelectionIndex();
		});
		_initSelected = _step.select;
		auto selValue = _valueCache[.min(_step is null ? 0 : _step.select, _step.count - 1)];
		_init.add(selValue);
		_init.select(0);
		_stepCount.setSelection(_values.getItemCount());
		_initTim.select(cast(int)_initTims.cCountUntil(_step ? _step.initialization : (_local ? VariableInitialization.None : VariableInitialization.Leave)));
		_expandSPChars.setSelection(_step ? _step.expandSPChars : false);
		refDataVersion();
	}

	@property
	private bool canCreateStepValues() { mixin(S_TRACE);
		if (_readOnly) return false;
		auto index = _values.getSelectionIndex();
		return 0 <= index && index + 1 < _values.getItemCount();
	}
	private void createStepValues() { mixin(S_TRACE);
		if (_readOnly) return;
		if (!canCreateStepValues) return;
		auto t = cast(Text)_tte.editor;
		auto index = _values.getSelectionIndex();
		auto lastValue = t ? t.getText() : _values.getItem(index).getText(1);
		createStepValues(index, lastValue);
	}

	private void createStepValues(int index, string lastValue) { mixin(S_TRACE);
		if (_readOnly) return;
		auto stored = false;
		foreach (i; index + 1 .. _values.getItemCount()) { mixin(S_TRACE);
			lastValue = createNewName(lastValue, (string name) { mixin(S_TRACE);
				return name != lastValue || name == "";
			});
			if (_valueCache[i] != lastValue) { mixin(S_TRACE);
				if (!stored) { mixin(S_TRACE);
					stored = true;
					storeRange([URange(index + 1, _values.getItemCount())]);
				}
				_valueCache[i] = lastValue;
				_values.clear(i);
			}
		}
		updateInitCombo();
	}

	@property
	private bool canUpValues() { mixin(S_TRACE);
		if (_readOnly) return false;
		return _values.getSelectionCount() && !_values.isSelected(0);
	}
	private void upValues() { mixin(S_TRACE);
		if (!canUpValues) return;
		_tte.enter();
		auto indices = _values.getSelectionIndices();
		std.algorithm.sort(indices);
		storeRange([URange(indices[0] - 1, indices[$ - 1] + 1)]);
		foreach (ref index; indices) { mixin(S_TRACE);
			std.algorithm.swap(_valueCache[index - 1], _valueCache[index]);
			_values.clear(index - 1);
			_values.clear(index);
			index--;
		}
		_values.deselectAll();
		_values.select(indices[0]);
		_values.showSelection();
		_values.select(indices);
		_tte.startEdit(_values.getItem(indices[0]));
	}

	@property
	private bool canDownValues() { mixin(S_TRACE);
		if (_readOnly) return false;
		return _values.getSelectionCount() && !_values.isSelected(_values.getItemCount() - 1);
	}
	private void downValues() { mixin(S_TRACE);
		if (!canDownValues) return;
		_tte.enter();
		auto itm = _values.getItem(_values.getSelectionIndex());
		auto indices = _values.getSelectionIndices();
		std.algorithm.sort(indices);
		storeRange([URange(indices[0], indices[$ - 1] + 2)]);
		foreach_reverse (ref index; indices) { mixin(S_TRACE);
			std.algorithm.swap(_valueCache[index + 1], _valueCache[index]);
			_values.clear(index);
			_values.clear(index + 1);
			index++;
		}
		_values.deselectAll();
		_values.select(indices[$ - 1]);
		_values.showSelection();
		_values.select(indices);
		_tte.startEdit(_values.getItem(indices[$ - 1]));
	}

	override bool apply() { mixin(S_TRACE);
		auto vals = _valueCache[0 .. _stepCount.getSelection()];
		if (_step.parent) { mixin(S_TRACE);
			_step.name = this.name;
			_step.setValues(vals, _initSelected);
		} else { mixin(S_TRACE);
			_step = new Step(this.name, vals, _initSelected);
			_dir.add(_step);
		}
		_step.initialization = _initTims[_initTim.getSelectionIndex()];
		_step.expandSPChars = _expandSPChars.getSelection();
		_comm.refFlagAndStep.call([], [_step], []);
		return true;
	}
}

/// フラグ設定用のダイアログ。
public class FlagEditDialog : AbsDialog {
private:
	Commons _comm;
	Summary _summ;
	Props prop;
	int _readOnly;
	bool _local;

	cwx.flag.Flag _flag;
	FlagDir dir;

	Text flagName;
	Combo flagInit;
	Combo flagTrue;
	Combo flagFalse;

	Combo _initTim;
	VariableInitialization[] _initTims;
	Button _expandSPChars;

	void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (prop.sys.isSystemVar(flagName.getText())) { mixin(S_TRACE);
			ws ~= .tryFormat(prop.msgs.warningSystemVarName, prop.sys.prefixSystemVarName);
		}
		if (_expandSPChars.getSelection() && !_comm.prop.isTargetVersion(_summ, "2")) { mixin(S_TRACE);
			ws ~= _comm.prop.msgs.warningExpandSPChars;
		}
		if (_expandSPChars.getSelection()) { mixin(S_TRACE);
			bool[string] ws2;
			foreach (text; [flagTrue, flagFalse]) { mixin(S_TRACE);
				bool[string] wFlags;
				bool[string] wSteps;
				bool[string] wVariants;
				bool[string] wFonts;
				bool[char] wColors;
				string[] flags;
				string[] steps;
				string[] variants;
				string[] fonts;
				char[] colors;
				textUseItems(wrapReturnCode(text.getText()), flags, steps, variants, fonts, colors);
				fonts = [];
				colors = [];
				auto isClassic = _summ && _summ.legacy;
				auto wsnVer = _summ ? _summ.dataVersion : LATEST_VERSION;
				auto ws3 = .textWarnings(_comm.prop.parent, _comm.skin, _summ, dir.useCounter, isClassic, wsnVer, _comm.prop.var.etc.targetVersion,
					text.getText(), flags, steps, variants, fonts, colors, wFlags, wSteps, wVariants, wFonts, wColors).all;
				foreach (w; ws3) { mixin(S_TRACE);
					if (w in ws2) continue;
					ws2[w] = true;
					ws ~= w;
				}
			}
		}
		if (_initTim.getSelectionIndex() != -1 && !_local && _initTims[_initTim.getSelectionIndex()] !is VariableInitialization.Leave && !_comm.prop.isTargetVersion(_summ, "4")) { mixin(S_TRACE);
			ws ~= _comm.prop.msgs.warningVariableInitialization;
		}
		ws ~= .sjisWarnings(_comm.prop.parent, _summ, flagName.getText(), _comm.prop.msgs.dlgLblFlagName);
		ws ~= .sjisWarnings(_comm.prop.parent, _summ, flagTrue.getText(), _comm.prop.msgs.flagOnValue);
		ws ~= .sjisWarnings(_comm.prop.parent, _summ, flagFalse.getText(), _comm.prop.msgs.flagOffValue);
		warning = ws;
	}

	class ModOnOff : SelectionAdapter, ModifyListener {
	private:
		int index;
		void change(E)(E e) { mixin(S_TRACE);
			if (index < flagInit.getItemCount()) { mixin(S_TRACE);
				flagInit.setItem(index, (cast(Combo) e.getSource()).getText());
			}
		}
	public:
		this(int index) { mixin(S_TRACE);
			this.index = index;
		}
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			change(e);
		}
		override void modifyText(ModifyEvent e) { mixin(S_TRACE);
			change(e);
			updateToolTipImpl(index == 0 ? flagTrue : flagFalse);
			refreshWarning();
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.delFlagAndStep.remove(&delFlag);
			_comm.refScenario.remove(&refScenario);
			_comm.refDataVersion.remove(&refDataVersion);
			_comm.refPreviewValues.remove(&updateToolTip);
			_comm.refFlagAndStep.remove(&refFlagAndStep);
			_comm.refPath.remove(&refPath);
			_comm.refPaths.remove(&refPaths);
			_comm.replText.remove(&updateToolTip);
		}
	}
	void delFlag(cwx.flag.Flag[] flag, Step[] step, cwx.flag.Variant[] variants) { mixin(S_TRACE);
		if (_readOnly) return;
		foreach (f; flag) { mixin(S_TRACE);
			if (f is _flag) { mixin(S_TRACE);
				forceCancel();
				return;
			}
		}
		refreshWarning();
		updateToolTip();
	}
	void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps, cwx.flag.Variant[] variants) { updateToolTip(); }
	void refPath(string o, string n, bool isDir) { updateToolTip(); }
	void refPaths(string parent) { updateToolTip(); }
	void updateToolTip() { mixin(S_TRACE);
		updateToolTipImpl(flagTrue);
		updateToolTipImpl(flagFalse);
	}
	void updateToolTipImpl(Combo combo) { mixin(S_TRACE);
		auto toolTip = "";
		if (_expandSPChars.getSelection()) { mixin(S_TRACE);
			toolTip = .createSPCharPreview(_comm, _summ, dir.useCounter, combo.getText(), true, (path) { mixin(S_TRACE);
				auto flag = .findVar!(cwx.flag.Flag)(_summ ? _summ.flagDirRoot : null, dir.useCounter, path);
				if (flag && _flag is flag) { mixin(S_TRACE);
					return VarValue(true, flagInit.getText(), _expandSPChars.getSelection());
				}
				return VarValue(false);
			}, null);
			toolTip = toolTip.replace("&", "&&");
		}
		if (toolTip != combo.getToolTipText()) { mixin(S_TRACE);
			combo.setToolTipText(toolTip);
		}
	}
	void refScenario(Summary summ) { mixin(S_TRACE);
		if (_readOnly) return;
		forceCancel();
	}
	void refDataVersion() { mixin(S_TRACE);
		_expandSPChars.setEnabled(!_summ.legacy || _expandSPChars.getSelection());
		_initTim.setEnabled(_local || !_summ.legacy || _initTims[_initTim.getSelectionIndex()] !is VariableInitialization.Leave);
		updateToolTip();
		refreshWarning();
	}
public:
	/// Params:
	/// prop = 設定情報。
	/// shell = 親ウィンドウ。
	/// dir = 設定するフラグの親ディレクトリ。
	/// flag = 設定するフラグ。新規の場合はnull。
	this(Commons comm, Summary summ, Shell shell, bool readOnly, bool local, FlagDir dir, cwx.flag.Flag flag = null) { mixin(S_TRACE);
		super(comm.prop, shell, readOnly, comm.prop.msgs.dlgTitFlag, comm.prop.images.flag, true,
			comm.prop.var.flagDlg, true);
		_comm = comm;
		this.prop = comm.prop;
		_summ = summ;
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		_local = local;
		this._flag = flag;
		this.dir = dir;
		enterClose = true;
	}

	/// Returns: 編集対象となったフラグ。
	@property
	cwx.flag.Flag flag() { mixin(S_TRACE);
		return _flag;
	}
	/// 入力中の名前を妥当な形にして返す。
	@property
	string name() { mixin(S_TRACE);
		auto name = FlagDir.validName(flagName.getText());
		return dir.createNewFlagName(name, _flag ? _flag.name : "");
	}
protected:
	private static void setMinW(Control c, int minW, int gridStyle = SWT.NULL) { mixin(S_TRACE);
		auto gd = new GridData(gridStyle);
		int w = c.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
		gd.widthHint = w > minW ? w : minW;
		c.setLayoutData(gd);
	}

	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(zeroGridLayout(2, false));
		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			auto cgd = new GridData(GridData.FILL_HORIZONTAL);
			cgd.horizontalSpan = 2;
			comp.setLayoutData(cgd);
			comp.setLayout(normalGridLayout(1, true));

			auto top = new SplitPane(comp, SWT.HORIZONTAL);
			top.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			.setupWeights(top, _comm.prop.var.etc.flagTopSashL, _comm.prop.var.etc.flagTopSashR);

			auto comp1 = new Composite(top, SWT.NONE);
			comp1.setLayout(zeroMarginGridLayout(2, false));
			auto comp2 = new Composite(top, SWT.NONE);
			comp2.setLayout(zeroMarginGridLayout(2, false));
			void setEVS(Control c) { mixin(S_TRACE);
				auto gd = cast(GridData)c.getLayoutData();
				assert (gd !is null);
				gd.grabExcessVerticalSpace = true;
				c.setLayoutData(gd);
			}

			auto l1 = new Label(comp1, SWT.NONE);
			l1.setText(prop.msgs.dlgLblFlagName);
			l1.setLayoutData(new GridData);
			setEVS(l1);
			flagName = new Text(comp1, SWT.BORDER | _readOnly);
			createTextMenu!Text(_comm, prop, flagName, &catchMod);
			mod(flagName);
			setGridMinW(flagName, prop.var.etc.flagNameWidth, GridData.FILL_HORIZONTAL);
			setEVS(flagName);
			checker(flagName);
			.listener(flagName, SWT.Modify, &refreshWarning);

			auto l2 = new Label(comp2, SWT.NONE);
			l2.setText(prop.msgs.dlgLblFlagInit);
			l2.setLayoutData(new GridData);
			setEVS(l2);
			flagInit = new Combo(comp2, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(flagInit);
			flagInit.setEnabled(!_readOnly);
			setGridMinW(flagInit, prop.var.etc.flagInitWidth, GridData.FILL_HORIZONTAL);
			setEVS(flagInit);
		}
		auto lgd1 = new GridData(GridData.FILL_HORIZONTAL);
		lgd1.horizontalSpan = 2;
		(new Label(area, SWT.SEPARATOR | SWT.HORIZONTAL)).setLayoutData(lgd1);
		{ mixin(S_TRACE);
			auto ocomp = new Composite(area, SWT.NONE);
			auto ogd = new GridData(GridData.FILL_BOTH);
			ogd.horizontalSpan = 2;
			ocomp.setLayoutData(ogd);
			auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
			cl.fillHorizontal = true;
			ocomp.setLayout(cl);
			auto comp = new Composite(ocomp, SWT.NONE);
			comp.setLayout(normalGridLayout(2, false));

			(new Label(comp, SWT.NULL)).setText(prop.msgs.dlgLblFlagTrue);
			flagTrue = new Combo(comp, SWT.DROP_DOWN | SWT.BORDER);
			mod(flagTrue);
			flagTrue.setEnabled(!_readOnly);
			setComboItems(flagTrue, prop.var.etc.flagTrues.dup);
			flagTrue.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			createTextMenu!Combo(_comm, prop, flagTrue, &catchMod);
			if (!_readOnly) { mixin(S_TRACE);
				auto tMenu = flagTrue.getMenu();
				new MenuItem(tMenu, SWT.SEPARATOR);
				.setupSPCharsMenu(_comm, _summ, dir.useCounter, flagTrue, tMenu, false, true, () => _expandSPChars.getSelection());
				auto tmod = new ModOnOff(0);
				flagTrue.addModifyListener(tmod);
				flagTrue.addSelectionListener(tmod);
			}
			setGridMinW(flagTrue, prop.var.etc.flagValueWidth, GridData.FILL_HORIZONTAL);

			(new Label(comp, SWT.NULL)).setText(prop.msgs.dlgLblFlagFalse);
			flagFalse = new Combo(comp, SWT.DROP_DOWN | SWT.BORDER);
			mod(flagFalse);
			flagFalse.setEnabled(!_readOnly);
			setComboItems(flagFalse, prop.var.etc.flagFalses.dup);
			flagFalse.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			createTextMenu!Combo(_comm, prop, flagFalse, &catchMod);
			if (!_readOnly) { mixin(S_TRACE);
				auto fMenu = flagFalse.getMenu();
				new MenuItem(fMenu, SWT.SEPARATOR);
				.setupSPCharsMenu(_comm, _summ, dir.useCounter, flagFalse, fMenu, false, true, () => _expandSPChars.getSelection());
				auto fmod = new ModOnOff(1);
				flagFalse.addModifyListener(fmod);
				flagFalse.addSelectionListener(fmod);
			}
			setGridMinW(flagFalse, prop.var.etc.flagValueWidth, GridData.FILL_HORIZONTAL);
		}
		auto lgd2 = new GridData(GridData.FILL_HORIZONTAL);
		lgd2.horizontalSpan = 2;
		(new Label(area, SWT.SEPARATOR | SWT.HORIZONTAL)).setLayoutData(lgd2);
		{ mixin(S_TRACE);
			auto eComp = new Composite(area, SWT.NONE);
			eComp.setLayout(normalGridLayout(1, true));
			_expandSPChars = new Button(eComp, SWT.CHECK);
			mod(_expandSPChars);
			_expandSPChars.setEnabled(!_readOnly);
			_expandSPChars.setText(_comm.prop.msgs.expandSPChars);
			_expandSPChars.setToolTipText(_comm.prop.msgs.expandSPCharsHint.replace("&", "&&"));
			.listener(_expandSPChars, SWT.Selection, &refDataVersion);
			.listener(_expandSPChars, SWT.Selection, &updateToolTip);

			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			comp.setLayout(normalGridLayout(2, false));
			auto l = new Label(comp, SWT.NONE);
			l.setText(_comm.prop.msgs.variableInitialization);
			_initTim = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_initTim);
			_initTim.setVisibleItemCount(_comm.prop.var.etc.comboVisibleItemCount);
			_initTim.setEnabled(!_readOnly);
			_initTims = FlagTable.selectableInitialization(_local);
			foreach (tim; _initTims) { mixin(S_TRACE);
				_initTim.add(_comm.prop.msgs.variableInitializationName(tim));
			}
			.listener(_initTim, SWT.Selection, &refDataVersion);
		}
		if (!_readOnly) { mixin(S_TRACE);
			_comm.delFlagAndStep.add(&delFlag);
			_comm.refScenario.add(&refScenario);
			_comm.refDataVersion.add(&refDataVersion);
			_comm.refPreviewValues.add(&updateToolTip);
			_comm.refFlagAndStep.add(&refFlagAndStep);
			_comm.refPath.add(&refPath);
			_comm.refPaths.add(&refPaths);
			_comm.replText.add(&updateToolTip);
			getShell().addDisposeListener(new Dispose);
		}

		ignoreMod = true;
		scope (exit) .asyncExec(getShell().getDisplay(), { ignoreMod = false; });
		if (_flag !is null) { mixin(S_TRACE);
			flagName.setText(_flag.name);
			flagTrue.setText(_flag.on);
			if (-1 == flagTrue.indexOf(_flag.on)) flagTrue.add(_flag.on, 0);
			flagFalse.setText(_flag.off);
			if (-1 == flagFalse.indexOf(_flag.off)) flagFalse.add(_flag.off, 0);
			setComboItems(flagInit, [flagTrue.getText(), flagFalse.getText()]);
			flagInit.select(_flag.onOff ? 0 : 1);
			_initTim.select(cast(int)_initTims.cCountUntil(_flag.initialization));
			_expandSPChars.setSelection(_flag.expandSPChars);
		} else { mixin(S_TRACE);
			flagName.setText("");
			flagTrue.setText(prop.var.etc.flagTrues.length > 0 ? prop.var.etc.flagTrues[0] : "");
			flagFalse.setText(prop.var.etc.flagFalses.length > 0 ? prop.var.etc.flagFalses[0] : "");
			setComboItems(flagInit, [flagTrue.getText(), flagFalse.getText()]);
			flagInit.select(0);
			_initTim.select(cast(int)_initTims.cCountUntil(_local ? VariableInitialization.None : VariableInitialization.Leave));
			_expandSPChars.setSelection(false);
		}
		if (!_flag.parent) { mixin(S_TRACE);
			// 新規作成時
			flagName.setText("");
		}
		flagName.selectAll();
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		if (_flag.parent) { mixin(S_TRACE);
			_flag.name = this.name;
			_flag.onOff = flagInit.getSelectionIndex() == 0;
			_flag.on = flagTrue.getText();
			_flag.off = flagFalse.getText();
		} else { mixin(S_TRACE);
			_flag = new cwx.flag.Flag(this.name, flagTrue.getText(), flagFalse.getText(),
				flagInit.getSelectionIndex() == 0);
			dir.add(_flag);
		}
		_flag.initialization = _initTims[_initTim.getSelectionIndex()];
		_flag.expandSPChars = _expandSPChars.getSelection();
		_comm.refFlagAndStep.call([_flag], [], []);
		return true;
	}
}

/// コモン設定用のダイアログ。
public class VariantEditDialog : AbsDialog {
private:
	Commons _comm;
	Summary _summ;
	cwx.flag.Variant _variant;
	FlagDir _dir;
	int _readOnly;
	bool _local;

	Text _name;

	Button _typeNum;
	Button _typeStr;
	Button _typeBool;

	Text _numVal;
	Text _strVal;
	Combo _boolVal;

	Combo _initTim;
	VariableInitialization[] _initTims;

	void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (!_comm.prop.isTargetVersion(_summ, "4")) { mixin(S_TRACE);
			ws ~= _comm.prop.msgs.warningVariant;
		}
		if (_typeNum.getSelection()) { mixin(S_TRACE);
			auto s = _numVal.getText();
			auto len = s.strip().replace(".", "").replace("-", "").stripLeft("0").length;
			if (_comm.prop.var.etc.limitForNumberOfVariant < len) { mixin(S_TRACE);
				ws ~= _comm.prop.msgs.warningLimitForNumberOfVariant;
			}
		}
		ws ~= .sjisWarnings(_comm.prop.parent, _summ, _name.getText(), _comm.prop.msgs.variantName);
		ws ~= .sjisWarnings(_comm.prop.parent, _summ, _strVal.getText(), _comm.prop.msgs.stringValue);
		warning = ws;
	}

	void updateEnabled() { mixin(S_TRACE);
		_numVal.setEnabled(!_readOnly && _typeNum.getSelection());
		_strVal.setEnabled(!_readOnly && _typeStr.getSelection());
		_boolVal.setEnabled(!_readOnly && _typeBool.getSelection());
		check();
	}

	void delVariant(cwx.flag.Flag[] flag, Step[] step, cwx.flag.Variant[] variants) { mixin(S_TRACE);
		if (_readOnly) return;
		if (.contains!"a is b"(variants, _variant)) { mixin(S_TRACE);
			forceCancel();
		}
	}
	void refScenario(Summary summ) { mixin(S_TRACE);
		if (_readOnly) return;
		forceCancel();
	}
	void refDataVersion() { mixin(S_TRACE);
		refreshWarning();
	}
public:
	this(Commons comm, Summary summ, Shell shell, bool readOnly, bool local, FlagDir dir, cwx.flag.Variant variant = null) { mixin(S_TRACE);
		super(comm.prop, shell, false, comm.prop.msgs.dlgTitVariant, comm.prop.images.variant, true,
			comm.prop.var.variantDlg, true);
		_comm = comm;
		_summ = summ;
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		_local = local;
		_variant = variant;
		_dir = dir;
		enterClose = true;
	}

	@property
	cwx.flag.Variant variant() { mixin(S_TRACE);
		return _variant;
	}

	/// 入力中の名前を妥当な形にして返す。
	@property
	string name() { mixin(S_TRACE);
		auto name = FlagDir.validName(_name.getText());
		return _dir.createNewVariantName(name, _variant ? _variant.name : "");
	}

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		area.setLayout(zeroGridLayout(1));
		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comp.setLayout(normalGridLayout(2, false));

			auto l1 = new Label(comp, SWT.NONE);
			l1.setText(_comm.prop.msgs.variantName);
			_name = new Text(comp, SWT.BORDER | _readOnly);
			.createTextMenu!Text(_comm, _comm.prop, _name, &catchMod);
			mod(_name);
			checker(_name);
			.listener(_name, SWT.Modify, &refreshWarning);
			_name.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}
		(new Label(area, SWT.SEPARATOR | SWT.HORIZONTAL)).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_BOTH));
			comp.setLayout(normalGridLayout(2, false));

			GridData grabVGD(int style) { mixin(S_TRACE);
				auto gd = new GridData(style);
				gd.grabExcessVerticalSpace = true;
				return gd;
			}

			_typeNum = new Button(comp, SWT.RADIO);
			mod(_typeNum);
			_typeNum.setEnabled(!_readOnly);
			_typeNum.setText(_comm.prop.msgs.numberValue);
			.listener(_typeNum, SWT.Selection, &updateEnabled);
			.listener(_typeNum, SWT.Selection, &refreshWarning);
			_numVal = .createNumberEditor(_comm, comp, SWT.BORDER | _readOnly, &catchMod);
			mod(_numVal);
			auto ngd = grabVGD(GridData.HORIZONTAL_ALIGN_BEGINNING);
			auto gc = new GC(_numVal);
			scope (exit) gc.dispose();
			ngd.widthHint = _numVal.computeSize(cast(int)(gc.wTextExtent(double.min_normal.text).x * 1.5), SWT.DEFAULT).x;
			_numVal.setLayoutData(ngd);
			.listener(_numVal, SWT.Modify, &refreshWarning);
			checker(_numVal, (numVal) { mixin(S_TRACE);
				if (!numVal.getEnabled()) return true;
				try {
					.to!double(numVal.getText());
					return true;
				} catch (ConvException e) {
					return false;
				}
			});

			_typeStr = new Button(comp, SWT.RADIO);
			mod(_typeStr);
			_typeStr.setEnabled(!_readOnly);
			.listener(_typeStr, SWT.Selection, &updateEnabled);
			.listener(_typeStr, SWT.Selection, &refreshWarning);
			_typeStr.setText(_comm.prop.msgs.stringValue);
			_strVal = new Text(comp, SWT.BORDER | _readOnly);
			mod(_strVal);
			.createTextMenu!Text(_comm, _comm.prop, _strVal, &catchMod);
			_strVal.setLayoutData(grabVGD(GridData.FILL_HORIZONTAL));
			.listener(_strVal, SWT.Modify, &refreshWarning);

			_typeBool = new Button(comp, SWT.RADIO);
			mod(_typeBool);
			_typeBool.setEnabled(!_readOnly);
			.listener(_typeBool, SWT.Selection, &updateEnabled);
			.listener(_typeBool, SWT.Selection, &refreshWarning);
			_typeBool.setText(_comm.prop.msgs.booleanValue);
			_boolVal = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_boolVal);
			_boolVal.setVisibleItemCount(_comm.prop.var.etc.comboVisibleItemCount);
			auto v = VariantVal(VariantType.Boolean);
			v.boolVal = true;
			_boolVal.add(.variantValueToText(v));
			v.boolVal = false;
			_boolVal.add(.variantValueToText(v));
			_boolVal.setLayoutData(grabVGD(GridData.HORIZONTAL_ALIGN_BEGINNING));
		}
		(new Label(area, SWT.SEPARATOR | SWT.HORIZONTAL)).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			comp.setLayout(normalGridLayout(2, false));
			auto l = new Label(comp, SWT.NONE);
			l.setText(_comm.prop.msgs.variableInitialization);
			_initTim = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_initTim);
			_initTim.setVisibleItemCount(_comm.prop.var.etc.comboVisibleItemCount);
			_initTim.setEnabled(!_readOnly);
			_initTims = FlagTable.selectableInitialization(_local);
			foreach (tim; _initTims) { mixin(S_TRACE);
				_initTim.add(_comm.prop.msgs.variableInitializationName(tim));
			}
		}

		if (!_readOnly) { mixin(S_TRACE);
			_comm.delFlagAndStep.add(&delVariant);
			_comm.refScenario.add(&refScenario);
			_comm.refDataVersion.add(&refDataVersion);
			.listener(area, SWT.Dispose, { mixin(S_TRACE);
				_comm.delFlagAndStep.remove(&delVariant);
				_comm.refScenario.remove(&refScenario);
				_comm.refDataVersion.remove(&refDataVersion);
			});
		}

		ignoreMod = true;
		scope (exit) .asyncExec(getShell().getDisplay(), { ignoreMod = false; });
		if (_variant) { mixin(S_TRACE);
			_name.setText(_variant.name);
			_numVal.setText(.variantValueToText(VariantVal(VariantType.Number)));
			_boolVal.select(0);
			final switch (_variant.type) {
			case VariantType.Number:
				_typeNum.setSelection(true);
				_numVal.setText(.variantValueToText(_variant));
				break;
			case VariantType.String:
				_typeStr.setSelection(true);
				_strVal.setText(_variant.strVal);
				break;
			case VariantType.Boolean:
				_typeBool.setSelection(true);
				_boolVal.select(_variant.boolVal ? 0 : 1);
				break;
			}
			_initTim.select(cast(int)_initTims.cCountUntil(_variant.initialization));
		} else { mixin(S_TRACE);
			_name.setText("");
			_typeNum.setSelection(true);
			_numVal.setText(.variantValueToText(VariantVal(VariantType.Number)));
			_strVal.setText("");
			_boolVal.select(0);
			_initTim.select(cast(int)_initTims.cCountUntil(_local ? VariableInitialization.None : VariableInitialization.Leave));
		}
		if (!_variant.parent) { mixin(S_TRACE);
			// 新規作成時
			_name.setText("");
		}
		_name.selectAll();
		updateEnabled();
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		double numVal = 0;
		if (_typeNum.getSelection()) { mixin(S_TRACE);
			try {
				numVal = .to!double(_numVal.getText());
			} catch (ConvException e) {
				return false;
			}
		}
		if (_variant.parent) { mixin(S_TRACE);
			_variant.name = this.name;
			if (_typeNum.getSelection()) { mixin(S_TRACE);
				_variant.value = numVal;
			} else if (_typeStr.getSelection()) { mixin(S_TRACE);
				_variant.value = _strVal.getText();
			} else if (_typeBool.getSelection()) { mixin(S_TRACE);
				_variant.value = _boolVal.getSelectionIndex() == 0;
			} else assert (0);
		} else { mixin(S_TRACE);
			if (_typeNum.getSelection()) { mixin(S_TRACE);
				_variant = new cwx.flag.Variant(this.name, numVal);
			} else if (_typeStr.getSelection()) { mixin(S_TRACE);
				_variant = new cwx.flag.Variant(this.name, _strVal.getText());
			} else if (_typeBool.getSelection()) { mixin(S_TRACE);
				_variant = new cwx.flag.Variant(this.name, _boolVal.getSelectionIndex() == 0);
			} else assert (0);
			_dir.add(_variant);
		}
		_variant.initialization = _initTims[_initTim.getSelectionIndex()];
		_comm.refFlagAndStep.call([], [], [_variant]);
		return true;
	}
}

private abstract class FTVUndo : Undo {
	protected FlagTable _v;
	protected Commons comm;
	protected UseCounter useCounter;
	protected string _dir;
	private string _selectedDir;
	private ptrdiff_t[] _selectedF;
	private ptrdiff_t[] _selectedS;
	private ptrdiff_t[] _selectedV;
	private ptrdiff_t[] _selectedFB;
	private ptrdiff_t[] _selectedSB;
	private ptrdiff_t[] _selectedVB;
	protected FlagDir selDir = null;
	this (FlagTable v, Commons comm, UseCounter uc, FlagDir dir) { mixin(S_TRACE);
		_v = v;
		_dir = dir.cwxPath(true);
		this.comm = comm;
		this.useCounter = uc;
		saveSelected(v);
	}
	this (FlagTable v, Commons comm, UseCounter uc, FlagDir dir, ptrdiff_t[] selectedF, ptrdiff_t[] selectedS, ptrdiff_t[] selectedV) { mixin(S_TRACE);
		_v = v;
		_dir = dir.cwxPath(true);
		this.comm = comm;
		this.useCounter = uc;
		_selectedF = selectedF;
		_selectedS = selectedS;
		_selectedV = selectedV;
	}
	@property
	protected FlagDir dir() { mixin(S_TRACE);
		return cast(FlagDir)comm.summary.findCWXPath(_dir);
	}
	private void saveSelected(FlagTable v) { mixin(S_TRACE);
		auto dir = this.dir();
		if (!dir) return;
		_selectedDir = dir.cwxPath(true);
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			_selectedF = v.selectionFlagIndices;
			_selectedS = v.selectionStepIndices;
			_selectedV = v.selectionVariantIndices;
		} else { mixin(S_TRACE);
			_selectedF.length = 0;
			_selectedS.length = 0;
			_selectedV.length = 0;
		}
	}
	void udb(FlagTable v) { mixin(S_TRACE);
		_selectedFB = _selectedF.dup;
		_selectedSB = _selectedS.dup;
		_selectedVB = _selectedV.dup;
		saveSelected(v);
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			.forceFocus(v.flags, false);
		}
	}
	void uda(FlagTable v) { mixin(S_TRACE);
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			if (selDir) { mixin(S_TRACE);
				if (comm.openCWXPath(selDir.cwxPath(true), true)) { mixin(S_TRACE);
					v.flags.deselectAll();
				}
			} else { mixin(S_TRACE);
				if (comm.openCWXPath(_selectedDir, true)) { mixin(S_TRACE);
					v.flags.deselectAll();
					v.selectFlagIndices(_selectedFB);
					v.selectStepIndices(_selectedSB);
					v.selectVariantIndices(_selectedVB);
				}
			}
			v.refreshStatusLine();
		}
		selDir = null;
		comm.refreshToolBar();
	}
	FlagTable view() { mixin(S_TRACE);
		return _v;
	}
	abstract override void undo();
	abstract override void redo();
	abstract override void dispose();
}
package class UndoAllVariables : FTVUndo {
	private FlagDir _root;
	private FlagDir _copyRoot;
	this (FlagTable v, Commons comm, UseCounter uc, FlagDir dir, FlagDir root) { mixin(S_TRACE);
		super (v, comm, uc, dir);
		_root = root;
		_copyRoot = new FlagDir(root.localOwner, root);
	}
	private void impl() { mixin(S_TRACE);
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		auto copy = _copyRoot;
		_copyRoot = new FlagDir(_root.localOwner, _root);

		_root.removeAll();
		foreach (f; copy.flags) _root.add(f);
		foreach (f; copy.steps) _root.add(f);
		foreach (f; copy.variants) _root.add(f);
		foreach (f; copy.subDirs) _root.add(f);
		comm.refFlagAndStep.call(_root.allFlags, _root.allSteps, _root.allVariants);
		comm.openFlagWin(false).dirs.refresh();
	}
	override void undo() { impl(); }
	override void redo() { impl(); }
	override void dispose() {}
}
package class UndoEditN {
	private CWXPath _f;
	private ptrdiff_t _index;
	this (FlagDir dir, int index, string oldName, int value, string[] names, VariantVal val) { mixin(S_TRACE);
		auto p = FlagTable.fromIndex(dir, index);
		auto f = cast(cwx.flag.Flag)p;
		if (f) { mixin(S_TRACE);
			auto flag = new cwx.flag.Flag(f);
			flag.useCounter = dir.useCounter.sub;
			_index = f.parent.indexOf(f);
			flag.name = oldName;
			if (-1 != value) flag.onOff = value == 0;
			if (names.length) { mixin(S_TRACE);
				flag.on = names[0];
				flag.off = names[1];
			}
			_f = flag;
		}
		auto s = cast(Step)p;
		if (s) { mixin(S_TRACE);
			auto step = new Step(s);
			step.useCounter = dir.useCounter.sub;
			_index = s.parent.indexOf(s);
			step.name = oldName;
			if (-1 != value) step.select = value;
			if (names.length) { mixin(S_TRACE);
				step.setValues(names, step.select);
			}
			_f = step;
		}
		if (auto v = cast(cwx.flag.Variant)p) { mixin(S_TRACE);
			auto variant = new cwx.flag.Variant(v);
			variant.useCounter = dir.useCounter.sub;
			_index = v.parent.indexOf(v);
			variant.name = oldName;
			if (val.valid) { mixin(S_TRACE);
				final switch (val.type) {
				case VariantType.Number:
					variant.value = val.numVal;
					break;
				case VariantType.String:
					variant.value = val.strVal;
					break;
				case VariantType.Boolean:
					variant.value = val.boolVal;
					break;
				}
			}
			_f = variant;
		}
	}
	CWXPath impl(Commons comm, FlagDir dir, out string newName) { mixin(S_TRACE);
		assert (dir);
		auto fB = _f;
		if (cast(cwx.flag.Flag)fB) { mixin(S_TRACE);
			auto f = dir.flags[_index];
			_f = new cwx.flag.Flag(f);
			(cast(cwx.flag.Flag)_f).useCounter = f.useCounter.sub;
			auto o = cast(cwx.flag.Flag)fB;
			assert (o);
			bool refVal = o.on != f.on || o.off != f.off;
			newName = o.name;
			o.name = f.name;
			f.copyFrom(o);
			refVal |= newName != f.name;
			if (refVal) { mixin(S_TRACE);
				return f;
			}
		} else if (cast(Step)fB) { mixin(S_TRACE);
			auto s = dir.steps[_index];
			_f = new Step(s);
			(cast(Step)_f).useCounter = s.useCounter.sub;
			auto o = cast(Step)fB;
			assert (o);
			bool refVal = o.values != s.values;
			newName = o.name;
			o.name = s.name;
			s.copyFrom(o);
			refVal |= newName != s.name;
			if (refVal) { mixin(S_TRACE);
				return s;
			}
		} else { mixin(S_TRACE);
			assert (cast(cwx.flag.Variant)fB);
			auto v = dir.variants[_index];
			_f = new cwx.flag.Variant(v);
			(cast(cwx.flag.Variant)_f).useCounter = v.useCounter.sub;
			auto o = cast(cwx.flag.Variant)fB;
			assert (o);
			bool refVal = o.type != v.type;
			if (!refVal) { mixin(S_TRACE);
				final switch (o.type) {
				case VariantType.Number:
					refVal |= o.numVal != v.numVal;
					break;
				case VariantType.String:
					refVal |= o.strVal != v.strVal;
					break;
				case VariantType.Boolean:
					refVal |= o.boolVal != v.boolVal;
					break;
				}
			}
			newName = o.name;
			o.name = v.name;
			v.copyFrom(o);
			refVal |= newName != v.name;
			if (refVal) { mixin(S_TRACE);
				return v;
			}
		}
		return null;
	}
}

package class UndoEdit : FTVUndo {
	private UndoEditN[] _impl;
	this (FlagTable v, Commons comm, UseCounter uc, FlagDir dir, int[] index, string[] oldName, int[] oldValues, string[][] oldNames, VariantVal[] oldVals) in { mixin(S_TRACE);
		assert (index.length == oldName.length);
		assert (!oldValues.length || oldValues.length == index.length);
		assert (!oldVals.length || oldVals.length == index.length);
	} body { mixin(S_TRACE);
		super (v, comm, uc, dir);
		foreach (i, idx; index) { mixin(S_TRACE);
			_impl ~= new UndoEditN(dir, idx, oldName[i], oldValues.length ? oldValues[i] : -1, oldNames.length ? oldNames[i] : [],
				oldVals.length ? oldVals[i] : VariantVal(false));
		}
	}
	private void impl() { mixin(S_TRACE);
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		auto dir = this.dir();
		cwx.flag.Flag[] refF;
		Step[] refS;
		cwx.flag.Variant[] refV;
		string[] newNameF;
		string[] newNameS;
		string[] newNameV;
		foreach (impl; _impl) { mixin(S_TRACE);
			string newName;
			auto refVal = impl.impl(comm, dir, newName);
			if (cast(cwx.flag.Flag)refVal) { mixin(S_TRACE);
				refF ~= cast(cwx.flag.Flag)refVal;
				newNameF ~= newName;
			} else if (cast(Step)refVal) { mixin(S_TRACE);
				refS ~= cast(Step)refVal;
				newNameS ~= newName;
			} else if (auto variant = cast(cwx.flag.Variant)refVal) { mixin(S_TRACE);
				refV ~= variant;
				newNameV ~= newName;
			}
		}
		FlagTable.setNames(refF, newNameF, useCounter);
		FlagTable.setNames(refS, newNameS, useCounter);
		FlagTable.setNames(refV, newNameV, useCounter);
		comm.refFlagAndStep.call(refF, refS, refV);
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			v.refresh();
		}
	}
	override void undo() { impl(); }
	override void redo() { impl(); }
	override void dispose() {}
}
/// 名前以外のパラメータのアンドゥ。
package class UndoEditParams : FTVUndo {
	private cwx.flag.Flag[] _oldFlags;
	private Step[] _oldSteps;
	private cwx.flag.Variant[] _oldVariants;
	this (FlagTable v, Commons comm, UseCounter uc, FlagDir dir, cwx.flag.Flag[] oldFlags, Step[] oldSteps, cwx.flag.Variant[] oldVariants) { mixin(S_TRACE);
		super (v, comm, uc, dir);
		_oldFlags = oldFlags;
		_oldSteps = oldSteps;
		_oldVariants = oldVariants;
	}
	private void impl() { mixin(S_TRACE);
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		auto dir = this.dir();
		cwx.flag.Flag[] refF;
		Step[] refS;
		cwx.flag.Variant[] refV;

		foreach (i, ref f; _oldFlags) { mixin(S_TRACE);
			auto t = dir.getFlag(f.name);
			auto o = new cwx.flag.Flag(t);
			o.useCounter = dir.useCounter.sub;
			t.copyFrom(f);
			f = o;
			refF ~= t;
		}
		foreach (i, ref f; _oldSteps) { mixin(S_TRACE);
			auto t = dir.getStep(f.name);
			auto o = new Step(t);
			o.useCounter = dir.useCounter.sub;
			t.copyFrom(f);
			f = o;
			refS ~= t;
		}
		foreach (i, ref f; _oldVariants) { mixin(S_TRACE);
			auto t = dir.getVariant(f.name);
			auto o = new cwx.flag.Variant(t);
			o.useCounter = dir.useCounter.sub;
			t.copyFrom(f);
			f = o;
			refV ~= t;
		}

		comm.refFlagAndStep.call(refF, refS, refV);
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			v.refresh();
		}
	}
	override void undo() { impl(); }
	override void redo() { impl(); }
	override void dispose() { }
}

package class UndoInsertDelete : FTVUndo {
	private bool _insert;

	/// insert
	private ptrdiff_t[] _dirIndices;
	private ptrdiff_t[] _flagIndices;
	private ptrdiff_t[] _stepIndices;
	private ptrdiff_t[] _variantIndices;
	/// delete
	private FlagDir[ptrdiff_t] _ds;
	private cwx.flag.Flag[ptrdiff_t] _fs;
	private Step[ptrdiff_t] _ss;
	private cwx.flag.Variant[ptrdiff_t] _vs;

	/// 追加を元に戻す。
	this (FlagTable v, Commons comm, UseCounter uc, FlagDir dir, ptrdiff_t[] selectedF, ptrdiff_t[] selectedS, ptrdiff_t[] selectedV, ptrdiff_t[] dirIndices, ptrdiff_t[] flagIndices, ptrdiff_t[] stepIndices, ptrdiff_t[] variantIndices) { mixin(S_TRACE);
		super (v, comm, uc, dir, selectedF.dup, selectedS.dup, selectedV.dup);
		_dirIndices = dirIndices.dup;
		_flagIndices = flagIndices.dup;
		_stepIndices = stepIndices.dup;
		_variantIndices = variantIndices.dup;
		_insert = true;
	}
	/// 削除を元に戻す。
	this (FlagTable v, Commons comm, UseCounter uc, FlagDir dir, ptrdiff_t[] selectedF, ptrdiff_t[] selectedS, ptrdiff_t[] selectedV, FlagDir[ptrdiff_t] ds, cwx.flag.Flag[ptrdiff_t] fs, Step[ptrdiff_t] ss, cwx.flag.Variant[ptrdiff_t] vs) { mixin(S_TRACE);
		super (v, comm, uc, dir, selectedF.dup, selectedS.dup, selectedV.dup);
		save(ds, fs, ss, vs);
		_insert = false;
	}

	private void save(FlagDir[ptrdiff_t] ds, cwx.flag.Flag[ptrdiff_t] fs, Step[ptrdiff_t] ss, cwx.flag.Variant[ptrdiff_t] vs) { mixin(S_TRACE);
		_ds = null;
		foreach (index, d; ds) { mixin(S_TRACE);
			_ds[index] = new FlagDir(d.localOwner, d);
		}
		_fs = null;
		foreach (index, f; fs) { mixin(S_TRACE);
			_fs[index] = new cwx.flag.Flag(f);
			_fs[index].useCounter = this.dir.useCounter.sub;
		}
		_ss = null;
		foreach (index, s; ss) { mixin(S_TRACE);
			_ss[index] = new Step(s);
			_ss[index].useCounter = this.dir.useCounter.sub;
		}
		_vs = null;
		foreach (index, v; vs) { mixin(S_TRACE);
			_vs[index] = new cwx.flag.Variant(v);
			_vs[index].useCounter = this.dir.useCounter.sub;
		}
	}
	private void undoInsert(FlagTable v) { mixin(S_TRACE);
		cwx.flag.Flag[] rfs;
		Step[] rss;
		cwx.flag.Variant[] rvs;
		FlagDir[] rds;
		undoInsertImpl(rfs, rss, rvs, rds);
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			v.refresh();
		}
		if (rds.length) comm.delFlagDir.call(rds);
		if (rfs.length || rss.length || rvs.length) { mixin(S_TRACE);
			comm.delFlagAndStep.call(rfs, rss, rvs);
		}
		comm.refUseCount.call();
	}
	private void undoInsertImpl(ref cwx.flag.Flag[] rfs, ref Step[] rss, ref cwx.flag.Variant[] rvs, ref FlagDir[] rds) { mixin(S_TRACE);
		_insert = false;
		FlagDir[ptrdiff_t] ds;
		cwx.flag.Flag[ptrdiff_t] fs;
		Step[ptrdiff_t] ss;
		cwx.flag.Variant[ptrdiff_t] vs;
		auto dir = this.dir();
		foreach (i; _dirIndices) { mixin(S_TRACE);
			auto d = dir.subDirs[i];
			if (d) ds[i] = d;
		}
		foreach (i; _flagIndices) { mixin(S_TRACE);
			auto f = dir.flags[i];
			if (f) fs[i] = f;
		}
		foreach (i; _stepIndices) { mixin(S_TRACE);
			auto s = dir.steps[i];
			if (s) ss[i] = s;
		}
		foreach (i; _variantIndices) { mixin(S_TRACE);
			auto v = dir.variants[i];
			if (v) vs[i] = v;
		}
		save(ds, fs, ss, vs);
		foreach (f; fs) { mixin(S_TRACE);
			useCounter.deleteID(toFlagId(f.path));
			dir.remove(f);
		}
		foreach (s; ss) { mixin(S_TRACE);
			useCounter.deleteID(toStepId(s.path));
			dir.remove(s);
		}
		foreach (v; vs) { mixin(S_TRACE);
			useCounter.deleteID(toVariantId(v.path));
			dir.remove(v);
		}
		foreach (d; ds) { mixin(S_TRACE);
			foreach (f; d.allFlags) { mixin(S_TRACE);
				useCounter.deleteID(toFlagId(f.path));
				rfs ~= f;
			}
			foreach (f; d.allSteps) { mixin(S_TRACE);
				useCounter.deleteID(toStepId(f.path));
				rss ~= f;
			}
			foreach (f; d.allVariants) { mixin(S_TRACE);
				useCounter.deleteID(toVariantId(f.path));
				rvs ~= f;
			}
			rds ~= d.allSubDirs;
			dir.remove(d);
		}
		auto v = view();
		if (v) v.callDeleteEvent();
		rds ~= ds.values;
		rfs ~= fs.values;
		rss ~= ss.values;
		rvs ~= vs.values;
	}
	private void undoDelete(FlagTable v) { mixin(S_TRACE);
		cwx.flag.Flag[] rfs;
		Step[] rss;
		cwx.flag.Variant[] rvs;
		FlagDir[] rds;
		undoDeleteImpl(rfs, rss, rvs, rds);
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			v.refresh();
		}
		if (rds.length) comm.delFlagDir.call(rds);
		if (rfs.length || rss.length || rvs.length) { mixin(S_TRACE);
			comm.delFlagAndStep.call(rfs, rss, rvs);
		}
		comm.refUseCount.call();
	}
	private void undoDeleteImpl(ref cwx.flag.Flag[] rfs, ref Step[] rss, ref cwx.flag.Variant[] rvs, ref FlagDir[] rds) { mixin(S_TRACE);
		_insert = true;
		auto dir = this.dir();
		_dirIndices.length = 0;
		_flagIndices.length = 0;
		_stepIndices.length = 0;
		_variantIndices.length = 0;
		selDir = (_ds.length == 1 && !_fs.length && !_ss.length && !_vs.length) ? _ds.values[0] : null;
		foreach (index; std.algorithm.sort(_fs.keys)) { mixin(S_TRACE);
			auto f = _fs[index];
			_flagIndices ~= index;
			dir.insert(index, f, true);
			useCounter.createID(toFlagId(f.path));
		}
		foreach (index; std.algorithm.sort(_ss.keys)) { mixin(S_TRACE);
			auto s = _ss[index];
			_stepIndices ~= index;
			dir.insert(index, s, true);
			useCounter.createID(toStepId(s.path));
		}
		foreach (index; std.algorithm.sort(_vs.keys)) { mixin(S_TRACE);
			auto v = _vs[index];
			_variantIndices ~= index;
			dir.insert(index, v, true);
			useCounter.createID(toVariantId(v.path));
		}
		foreach (index; std.algorithm.sort(_ds.keys)) { mixin(S_TRACE);
			auto d = _ds[index];
			_dirIndices ~= index;
			dir.insert(index, d, true);
			foreach (f; d.allFlags) { mixin(S_TRACE);
				useCounter.createID(toFlagId(f.path));
				rfs ~= f;
			}
			foreach (f; d.allSteps) { mixin(S_TRACE);
				useCounter.createID(toStepId(f.path));
				rss ~= f;
			}
			foreach (f; d.allVariants) { mixin(S_TRACE);
				useCounter.createID(toVariantId(f.path));
				rvs ~= f;
			}
			rds ~= d.allSubDirs;
		}
		auto v = view();
		if (v) v.callDeleteEvent();
		rds ~= _ds.values;
		rfs ~= _fs.values;
		rss ~= _ss.values;
		rvs ~= _vs.values;
	}
	override void undo() { mixin(S_TRACE);
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		undoImpl(v);
	}
	private void undoImpl(FlagTable v) { mixin(S_TRACE);
		if (_insert) { mixin(S_TRACE);
			undoInsert(v);
		} else { mixin(S_TRACE);
			undoDelete(v);
		}
	}
	override void redo() { mixin(S_TRACE);
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		redoImpl(v);
	}
	private void redoImpl(FlagTable v) { mixin(S_TRACE);
		undoImpl(v);
	}
	override void dispose() {}
}
package class UndoMove : FTVUndo {
	private UndoInsertDelete _dir1;
	private UndoInsertDelete _dir2;

	this (FlagTable v, Commons comm, UseCounter uc, ptrdiff_t[] selectedF, ptrdiff_t[] selectedS, ptrdiff_t[] selectedV, FlagDir to, ptrdiff_t[] dirIndices, ptrdiff_t[] flagIndices, ptrdiff_t[] stepIndices, ptrdiff_t[] variantIndices, FlagDir from, FlagDir[ptrdiff_t] ds, cwx.flag.Flag[ptrdiff_t] fs, Step[ptrdiff_t] ss, cwx.flag.Variant[ptrdiff_t] vs) { mixin(S_TRACE);
		super (v, comm, uc, from, selectedF.dup, selectedS.dup, selectedV.dup);
		assert (dirIndices.length == ds.length);
		assert (flagIndices.length == fs.length);
		assert (stepIndices.length == ss.length);
		assert (variantIndices.length == vs.length);
		_dir1 = new UndoInsertDelete(v, comm, uc, to, selectedF, selectedS, selectedV, dirIndices, flagIndices, stepIndices, variantIndices);
		_dir2 = new UndoInsertDelete(v, comm, uc, from, selectedF, selectedS, selectedV, ds, fs, ss, vs);
	}
	private void paths(UndoInsertDelete ins, FlagDir dir, out FlagId[] flagIDs, out StepId[] stepIDs, out VariantId[] variantIDs, out cwx.flag.Flag[] flags, out Step[] steps, out cwx.flag.Variant[] variants) { mixin(S_TRACE);
		assert (dir !is null);
		foreach (i; std.algorithm.sort(ins._dirIndices.dup)) { mixin(S_TRACE);
			foreach (f; dir.subDirs[i].allFlags) flags ~= f;
			foreach (f; dir.subDirs[i].allSteps) steps ~= f;
			foreach (f; dir.subDirs[i].allVariants) variants ~= f;
		}
		foreach (i; std.algorithm.sort(ins._flagIndices.dup)) { mixin(S_TRACE);
			flags ~= dir.flags[i];
		}
		foreach (i; std.algorithm.sort(ins._stepIndices.dup)) { mixin(S_TRACE);
			steps ~= dir.steps[i];
		}
		foreach (i; std.algorithm.sort(ins._variantIndices.dup)) { mixin(S_TRACE);
			variants ~= dir.variants[i];
		}
		foreach (f; flags) flagIDs ~= toFlagId(f.path);
		foreach (f; steps) stepIDs ~= toStepId(f.path);
		foreach (f; variants) variantIDs ~= toVariantId(f.path);
	}
	private void change(FlagTable v, FlagId[] oldF, FlagId[] newF, StepId[] oldS, StepId[] newS, VariantId[] oldV, VariantId[] newV) { mixin(S_TRACE);
		foreach (nPath, oPath; .zip(newF, oldF)) { mixin(S_TRACE);
			useCounter.change(oPath, nPath);
		}
		foreach (nPath, oPath; .zip(newS, oldS)) { mixin(S_TRACE);
			useCounter.change(oPath, nPath);
		}
		foreach (nPath, oPath; .zip(newV, oldV)) { mixin(S_TRACE);
			useCounter.change(oPath, nPath);
		}
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			v.refresh();
		}
		comm.refUseCount.call();
	}
	private void impl(UndoInsertDelete del, UndoInsertDelete ins) { mixin(S_TRACE);
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		FlagId[] oldF, newF;
		StepId[] oldS, newS;
		VariantId[] oldV, newV;
		cwx.flag.Flag[] flags;
		Step[] steps;
		cwx.flag.Variant[] variants;
		auto delDir = del.dir();
		auto insDir = ins.dir();
		paths(del, del.dir(), oldF, oldS, oldV, flags, steps, variants);
		cwx.flag.Flag[] rfs;
		Step[] rss;
		cwx.flag.Variant[] rvs;
		FlagDir[] rds;
		del.undoInsertImpl(rfs, rss, rvs, rds);
		ins.undoDeleteImpl(rfs, rss, rvs, rds);
		paths(ins, ins.dir(), newF, newS, newV, flags, steps, variants);
		change(v, oldF, newF, oldS, newS, oldV, newV);

		bool[cwx.flag.Flag] fSet;
		bool[Step] sSet;
		bool[cwx.flag.Variant] vSet;
		bool[FlagDir] dSet;
		foreach (f; rfs) fSet[f] = true;
		foreach (f; rss) sSet[f] = true;
		foreach (f; rvs) vSet[f] = true;
		foreach (f; rds) dSet[f] = true;
		if (rds.length) comm.delFlagDir.call(dSet.keys);
		if (rfs.length || rss.length || rvs.length) { mixin(S_TRACE);
			comm.delFlagAndStep.call(fSet.keys, sSet.keys, vSet.keys);
		}
		comm.refUseCount.call();
	}
	override void undo() { mixin(S_TRACE);
		impl(_dir1, _dir2);
	}
	override void redo() { mixin(S_TRACE);
		impl(_dir2, _dir1);
	}
	override void dispose() { mixin(S_TRACE);
		_dir1.dispose();
		_dir2.dispose();
	}
}
package class UndoEditDir : FTVUndo {
	private string _oldName;
	this (FlagTable v, Commons comm, UseCounter uc, FlagDir dir, string oldName) { mixin(S_TRACE);
		super (v, comm, uc, dir);
		_oldName = oldName;
	}
	private void impl() { mixin(S_TRACE);
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		auto dir = this.dir();
		assert (dir !is null);

		string oldName = dir.name;
		dir.rename(_oldName, useCounter);
		_oldName = oldName;

		comm.refFlagDir.call([dir]);
	}
	override void undo() { impl(); }
	override void redo() { impl(); }
	override void dispose() {}
}

public class FlagTable : TCPD {
public:
	void delegate()[] createEvent;
	void delegate()[] deleteEvent;
private:
	void storeEdit(int[] index, string[] oldName, int[] oldValues = [], string[][] oldNames = [], VariantVal[] oldVals = []) { mixin(S_TRACE);
		_undo ~= new UndoEdit(this, _comm, uc, _dir, index, oldName, oldValues, oldNames, oldVals);
	}
	void storeEdit(int index, string oldName, int oldValue, string[] oldNames = [], VariantVal oldVal = VariantVal(false)) { mixin(S_TRACE);
		_undo ~= new UndoEdit(this, _comm, uc, _dir, [index], [oldName], oldValue != -1 ? [oldValue] : [], oldNames.length ? [oldNames] : [], oldVal.valid ? [oldVal] : []);
	}
	void storeEditParams(cwx.flag.Flag[] oldFlags, Step[] oldSteps, cwx.flag.Variant[] oldVariants) { mixin(S_TRACE);
		_undo ~= new UndoEditParams(this, _comm, uc, _dir, oldFlags, oldSteps, oldVariants);
	}
	void storeInsert(ptrdiff_t[] selectedF, ptrdiff_t[] selectedS, ptrdiff_t[] selectedV, ptrdiff_t[] flagIndices, ptrdiff_t[] stepIndices, ptrdiff_t[] variantIndices) { mixin(S_TRACE);
		_undo ~= new UndoInsertDelete(this, _comm, uc, _dir, selectedF, selectedS, selectedV, [], flagIndices, stepIndices, variantIndices);
	}
	void storeDelete(ptrdiff_t[] selectedF, ptrdiff_t[] selectedS, ptrdiff_t[] selectedV, cwx.flag.Flag[ptrdiff_t] fs, Step[ptrdiff_t] ss, cwx.flag.Variant[ptrdiff_t] vs) { mixin(S_TRACE);
		_undo ~= new UndoInsertDelete(this, _comm, uc, _dir, selectedF, selectedS, selectedV, null, fs, ss, vs);
	}

	void callCreateEvent() { mixin(S_TRACE);
		foreach (dlg; createEvent) dlg();
	}
	void callDeleteEvent() { mixin(S_TRACE);
		foreach (dlg; deleteEvent) dlg();
	}

	static int indexOf(FlagDir dir, CWXPath p) { mixin(S_TRACE);
		int i = 0;
		foreach (v; dir.variants) { mixin(S_TRACE);
			if (v is p) { mixin(S_TRACE);
				return i;
			}
			i++;
		}
		foreach (s; dir.steps) { mixin(S_TRACE);
			if (s is p) { mixin(S_TRACE);
				return i;
			}
			i++;
		}
		foreach (f; dir.flags) { mixin(S_TRACE);
			if (f is p) { mixin(S_TRACE);
				return i;
			}
			i++;
		}
		return -1;
	}
	static CWXPath fromIndex(FlagDir dir, int index) { mixin(S_TRACE);
		if (index < dir.variants.length) { mixin(S_TRACE);
			return dir.variants[index];
		}
		index -= dir.variants.length;
		if (index < dir.steps.length) { mixin(S_TRACE);
			return dir.steps[index];
		}
		index -= dir.steps.length;
		return dir.flags[index];
	}
	static int toFlagIndex(FlagDir dir, int index) { mixin(S_TRACE);
		return index - cast(int)dir.variants.length - cast(int)dir.steps.length;
	}
	static int toStepIndex(FlagDir dir, int index) { mixin(S_TRACE);
		return index - cast(int)dir.variants.length;
	}
	static int toVariantIndex(FlagDir dir, int index) { mixin(S_TRACE);
		return index;
	}

	static const NAME = 0;
	static const VALUE = 1;
	static const INIT = 2;
	static const UC = 3;
	void refreshFlags() { mixin(S_TRACE);
		if (_dir) { mixin(S_TRACE);
			int i = 0;
			.sortedWithName(_dir.variants, prop.var.etc.logicalSort, (cwx.flag.Variant f) { mixin(S_TRACE);
				if (!_incSearch.match(f.name, f)) return;
				TableItem itm;
				if (i < flags.getItemCount()) { mixin(S_TRACE);
					itm = flags.getItem(i);
				} else { mixin(S_TRACE);
					itm = new TableItem(flags, SWT.NONE);
				}
				itm.setImage(0, prop.images.variant);
				itm.setText(NAME, f.name);
				itm.setText(VALUE, .variantValueToText(f));
				itm.setText(INIT, prop.msgs.variableInitializationShortName(f.initialization));
				itm.setText(UC, to!(string)(uc.get(toVariantId(f.path))));
				itm.setData(f);
				i++;
			});
			.sortedWithName(_dir.steps, prop.var.etc.logicalSort, (Step f) { mixin(S_TRACE);
				if (!_incSearch.match(f.name, f)) return;
				TableItem itm;
				if (i < flags.getItemCount()) { mixin(S_TRACE);
					itm = flags.getItem(i);
				} else { mixin(S_TRACE);
					itm = new TableItem(flags, SWT.NONE);
				}
				itm.setImage(0, prop.images.step);
				itm.setText(NAME, f.name);
				itm.setText(VALUE, .getStepValue(prop, f, f.select));
				itm.setText(INIT, prop.msgs.variableInitializationShortName(f.initialization));
				itm.setText(UC, to!(string)(uc.get(toStepId(f.path))));
				itm.setData(f);
				i++;
			});
			.sortedWithName(_dir.flags, prop.var.etc.logicalSort, (cwx.flag.Flag f) { mixin(S_TRACE);
				if (!_incSearch.match(f.name, f)) return;
				TableItem itm;
				if (i < flags.getItemCount()) { mixin(S_TRACE);
					itm = flags.getItem(i);
				} else { mixin(S_TRACE);
					itm = new TableItem(flags, SWT.NONE);
				}
				itm.setImage(0, prop.images.flag);
				itm.setText(NAME, f.name);
				itm.setText(VALUE, f.onOff ? f.on : f.off);
				itm.setText(INIT, prop.msgs.variableInitializationShortName(f.initialization));
				itm.setText(UC, to!(string)(uc.get(toFlagId(f.path))));
				itm.setData(f);
				i++;
			});
			if (i < flags.getItemCount()) { mixin(S_TRACE);
				flags.remove(i, flags.getItemCount() - 1);
			}
		} else { mixin(S_TRACE);
			flags.removeAll();
		}
	}

	string _id;

	Props prop;
	Commons _comm;
	UseCounter uc;
	int _readOnly;
	bool _local;

	Table flags;

	FlagDir _dir = null;
	string _statusLine = "";

	FlagEditDialog[cwx.flag.Flag] _editDlgsF;
	StepEditDialog[Step] _editDlgsS;
	VariantEditDialog[cwx.flag.Variant] _editDlgsV;

	IncSearch _incSearch = null;
	private void incSearch() { mixin(S_TRACE);
		.forceFocus(flags, true);
		_incSearch.startIncSearch();
	}

	UndoManager _undo;
	TableTextEdit _tte;
	TableTCEdit _tce;
	TableComboEdit!Combo _tie;

	void editFlag(FlagDir parent, cwx.flag.Flag flag) { mixin(S_TRACE);
		enterEdit();
		bool createMode = flag is null;
		string old = createMode ? null : flag.name;
		if (!flag) { mixin(S_TRACE);
			string on = prop.var.etc.flagTrues.length > 0 ? prop.var.etc.flagTrues[0] : "";
			string off = prop.var.etc.flagFalses.length > 0 ? prop.var.etc.flagFalses[0] : "";
			flag = new cwx.flag.Flag("", on, off, prop.var.etc.flagInitValue);
			flag.initialization = _local ? VariableInitialization.None : VariableInitialization.Leave;
		}
		auto p = flag in _editDlgsF;
		if (p) { mixin(S_TRACE);
			p.active();
			return;
		}
		auto dlg = new FlagEditDialog(_comm, _comm.summary, dlgParShl, _readOnly != SWT.NONE, _local, parent, flag);
		string oldName = "";
		int oldValue = 0;
		string[] oldNames = [flag.on, flag.off];
		dlg.applyEvent ~= { mixin(S_TRACE);
			int i = indexOf(parent, flag);
			if (-1 != i) { mixin(S_TRACE);
				assert (!createMode);
				oldName = flag.name;
				oldValue = flag.onOff ? 0 : 1;
				oldNames = [flag.on, flag.off];
			}
		};
		dlg.appliedEvent ~= { mixin(S_TRACE);
			auto flag = dlg.flag;
			if (old && old != flag.name) { mixin(S_TRACE);
				uc.change(toFlagId(FlagDir.join(parent.path, old)), toFlagId(flag.path), true);
				old = flag.name;
			}
			if (createMode) { mixin(S_TRACE);
				ptrdiff_t[] selsF;
				ptrdiff_t[] selsS;
				ptrdiff_t[] selsV;
				if (flags && !flags.isDisposed()) { mixin(S_TRACE);
					selsF = selectionFlagIndices;
					selsS = selectionStepIndices;
					selsV = selectionVariantIndices;
				}
				storeInsert(selsF, selsS, selsV, [flag.parent.indexOf(flag)], [], []);
				uc.createID(toFlagId(flag.path));
				callCreateEvent();
				_comm.refUseCount.call();
				createMode = false;
			} else { mixin(S_TRACE);
				storeEdit(indexOf(parent, flag), oldName, oldValue, oldNames);
			}
			_comm.openCWXPath(flag.cwxPath(true), false);
			refresh([flag]);
			_comm.refFlagAndStep.call([flag], [], []);
			_comm.refreshToolBar();
		};
		_editDlgsF[flag] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgsF.remove(flag);
		};
		dlg.open();
	}
	void editStep(FlagDir parent, Step step) { mixin(S_TRACE);
		enterEdit();
		bool createMode = step is null;
		string old = createMode ? null : step.name;
		if (!step) { mixin(S_TRACE);
			string[] vals;
			foreach (i; 0 .. prop.looks.stepMaxCount) { mixin(S_TRACE);
				vals ~= .parseDollarParams(prop.var.etc.stepValueName, ['N':.to!string(i)]);
			}
			step = new Step("", vals, .min(prop.looks.stepMaxCount - 1, .max(0, prop.var.etc.stepInitValue.value)));
			step.initialization = _local ? VariableInitialization.None : VariableInitialization.Leave;
		}
		auto p = step in _editDlgsS;
		if (p) { mixin(S_TRACE);
			p.active();
			return;
		}
		auto dlg = new StepEditDialog(_comm, _comm.summary, dlgParShl, _readOnly != SWT.NONE, _local, parent, step);
		string oldName = "";
		int oldValue = 0;
		string[] oldNames = step.values.dup;
		dlg.applyEvent ~= { mixin(S_TRACE);
			int i = indexOf(parent, step);
			if (-1 != i) { mixin(S_TRACE);
				assert (!createMode);
				oldName = step.name;
				oldValue = step.select;
				oldNames = step.values.dup;
			}
		};
		dlg.appliedEvent ~= { mixin(S_TRACE);
			auto step = dlg.step;
			if (old && old != step.name) { mixin(S_TRACE);
				uc.change(toStepId(FlagDir.join(parent.path, old)), toStepId(step.path), true);
				old = step.name;
			}
			if (createMode) { mixin(S_TRACE);
				ptrdiff_t[] selsF;
				ptrdiff_t[] selsS;
				ptrdiff_t[] selsV;
				if (flags && !flags.isDisposed()) { mixin(S_TRACE);
					selsF = selectionFlagIndices;
					selsS = selectionStepIndices;
					selsV = selectionVariantIndices;
				}
				storeInsert(selsF, selsS, selsV, [], [step.parent.indexOf(step)], []);
				uc.createID(toStepId(step.path));
				callCreateEvent();
				_comm.refUseCount.call();
				createMode = false;
			} else { mixin(S_TRACE);
				storeEdit(indexOf(parent, step), oldName, oldValue, oldNames);
			}
			_comm.openCWXPath(step.cwxPath(true), false);
			refresh([step]);
			_comm.refFlagAndStep.call([], [step], []);
			_comm.refreshToolBar();
		};
		_editDlgsS[step] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgsS.remove(step);
		};
		dlg.open();
	}
	void editVariant(FlagDir parent, cwx.flag.Variant variant) { mixin(S_TRACE);
		enterEdit();
		auto createMode = variant is null;
		auto old = createMode ? null : variant.name;
		if (!variant) { mixin(S_TRACE);
			variant = new cwx.flag.Variant("", 0.0);
			variant.initialization = _local ? VariableInitialization.None : VariableInitialization.Leave;
		}
		auto p = variant in _editDlgsV;
		if (p) { mixin(S_TRACE);
			p.active();
			return;
		}
		auto dlg = new VariantEditDialog(_comm, _comm.summary, dlgParShl, _readOnly != SWT.NONE, _local, parent, variant);
		auto oldName = "";
		auto oldValue = VariantVal(false);
		dlg.applyEvent ~= { mixin(S_TRACE);
			int i = indexOf(parent, variant);
			if (-1 != i) { mixin(S_TRACE);
				assert (!createMode);
				oldName = variant.name;
				oldValue = VariantVal(variant);
			}
		};
		dlg.appliedEvent ~= { mixin(S_TRACE);
			auto variant = dlg.variant;
			if (old && old != variant.name) { mixin(S_TRACE);
				uc.change(toVariantId(FlagDir.join(parent.path, old)), toVariantId(variant.path), true);
				old = variant.name;
			}
			if (createMode) { mixin(S_TRACE);
				ptrdiff_t[] selsF;
				ptrdiff_t[] selsS;
				ptrdiff_t[] selsV;
				if (flags && !flags.isDisposed()) { mixin(S_TRACE);
					selsF = selectionFlagIndices;
					selsS = selectionStepIndices;
					selsV = selectionVariantIndices;
				}
				storeInsert(selsF, selsS, selsV, [], [], [variant.parent.indexOf(variant)]);
				uc.createID(toVariantId(variant.path));
				callCreateEvent();
				_comm.refUseCount.call();
				createMode = false;
			} else { mixin(S_TRACE);
				storeEdit(indexOf(parent, variant), oldName, -1, [], oldValue);
			}
			_comm.openCWXPath(variant.cwxPath(true), false);
			refresh([variant]);
			_comm.refFlagAndStep.call([], [], [variant]);
			_comm.refreshToolBar();
		};
		_editDlgsV[variant] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgsV.remove(variant);
		};
		dlg.open();
	}

	class MListener : MouseAdapter {
	public:
		override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (e.button == 1) { mixin(S_TRACE);
				edit();
			}
		}
	}
	class KListener : KeyAdapter {
	public:
		override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			if (.isEnterKey(e.keyCode)) { mixin(S_TRACE);
				edit();
			}
		}
	}

	/// 選択中のフラグとステップを取得する。
	/// Params:
	/// fs = 選択中のフラグの配列が格納される。
	/// ss = 選択中のステップの配列が格納される。
	/// Returns: 選択中ならtrue。
	bool getSelectionFlagAndStep(out cwx.flag.Flag[] fs, out Step[] ss, out cwx.flag.Variant[] vs) { mixin(S_TRACE);
		auto indices = flags.getSelectionIndices();
		if (indices.length > 0) { mixin(S_TRACE);
			foreach (i; indices) { mixin(S_TRACE);
				auto itm = flags.getItem(i);
				if (auto s = cast(Step)itm.getData()) { mixin(S_TRACE);
					ss ~= s;
				} else if (auto f = cast(cwx.flag.Flag)itm.getData()) { mixin(S_TRACE);
					fs ~= f;
				} else if (auto f = cast(cwx.flag.Variant)itm.getData()) { mixin(S_TRACE);
					vs ~= f;
				} else assert (0);
			}
			return true;
		} else { mixin(S_TRACE);
			return false;
		}
	}
	void getSelectionFlagAndStepWithIndex(out cwx.flag.Flag[ptrdiff_t] fs, out Step[ptrdiff_t] ss, out cwx.flag.Variant[ptrdiff_t] vs) { mixin(S_TRACE);
		cwx.flag.Flag[] fsi;
		Step[] ssi;
		cwx.flag.Variant[] vsi;
		getSelectionFlagAndStep(fsi, ssi, vsi);
		foreach (f; fsi) fs[f.parent.indexOf(f)] = f;
		foreach (f; ssi) ss[f.parent.indexOf(f)] = f;
		foreach (f; vsi) vs[f.parent.indexOf(f)] = f;
	}
	void selectIndicesImpl(F)(in ptrdiff_t[] indices, in F[] arr) { mixin(S_TRACE);
		auto set = new HashSet!string;
		foreach (i; indices) set.add(arr[i].name);
		foreach (i, itm; flags.getItems()) { mixin(S_TRACE);
			if (auto f = cast(F)itm.getData()) { mixin(S_TRACE);
				if (set.contains(f.name)) { mixin(S_TRACE);
					flags.select(cast(int)i);
				}
			}
		}
	}
	void selectFlagIndices(in ptrdiff_t[] indices) { mixin(S_TRACE);
		selectIndicesImpl!(cwx.flag.Flag)(indices, _dir.flags);
	}
	void selectStepIndices(in ptrdiff_t[] indices) { mixin(S_TRACE);
		selectIndicesImpl!Step(indices, _dir.steps);
	}
	void selectVariantIndices(in ptrdiff_t[] indices) { mixin(S_TRACE);
		selectIndicesImpl!(cwx.flag.Variant)(indices, _dir.variants);
	}

	cwx.flag.Flag[ptrdiff_t] _dragFlags;
	Step[ptrdiff_t] _dragSteps;
	cwx.flag.Variant[ptrdiff_t] _dragVariants;
	class FlagDragListener : DragSourceListener {
	private:
		int[] dragIndices;
	public:
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			e.doit = flags.getSelectionCount() > 0;
		}
		override void dragSetData(DragSourceEvent e) { mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				// XML化して転送する。
				getSelectionFlagAndStepWithIndex(_dragFlags, _dragSteps, _dragVariants);
				XNode node;
				getNode(_dir, _dragFlags.values, _dragSteps.values, _dragVariants.values, node);
				node.newAttr("paneId", _id);
				e.data = bytesFromXML(node.text);
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			if (!_readOnly && e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
				foreach (flag; _dragFlags) { mixin(S_TRACE);
					uc.deleteID(toFlagId(flag.path));
					flag.parent.remove(flag);
				}
				foreach (step; _dragSteps) { mixin(S_TRACE);
					uc.deleteID(toStepId(step.path));
					step.parent.remove(step);
				}
				foreach (variant; _dragVariants) { mixin(S_TRACE);
					uc.deleteID(toVariantId(variant.path));
					variant.parent.remove(variant);
				}
				refresh();
				callDeleteEvent();
				_comm.delFlagAndStep.call(_dragFlags.values, _dragSteps.values, _dragVariants.values);
				_comm.refreshToolBar();
				_comm.refUseCount.call();
			}
			_dragFlags = null;
			_dragSteps = null;
			_dragVariants = null;
		}
	}
	class FlagDrop : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			e.detail =  (!_local || !_comm.summary || !_comm.summary.legacy) ? DND.DROP_COPY : DND.DROP_NONE;
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			e.detail =  (!_local || !_comm.summary || !_comm.summary.legacy) ? DND.DROP_COPY : DND.DROP_NONE;
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			if (!isXMLBytes(e.data)) return;
			e.detail = DND.DROP_NONE;
			auto xml = bytesToXML(e.data);
			try { mixin(S_TRACE);
				auto node = XNode.parse(xml);
				if (_id == node.attr!string("paneId", false)) return;
				if (pasteImpl(node)) { mixin(S_TRACE);
					e.detail = DND.DROP_COPY;
				}
			} catch (Exception e) { mixin(S_TRACE);
				printStackTrace();
				debugln(e);
			}
		}
	}

	void flagsSelected() { mixin(S_TRACE);
		refreshStatusLine();
		_comm.refreshToolBar();
	}
	class SListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			flagsSelected();
		}
	}
	class DListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.refUseCount.remove(&refreshUseCount);
			_comm.replText.remove(&refresh);
		}
	}
	void nameEditEnd(TableItem selItm, int column, string text) { mixin(S_TRACE);
		text = FlagDir.validName(text);
		auto itms = flags.getSelection();
		itms = itms.remove(selItm);
		itms.insertInPlace(0, selItm);
		cwx.flag.Flag[] refF;
		Step[] refS;
		cwx.flag.Variant[] refV;
		int[] indices;
		string[] oldNames;
		string[] oldNamesF;
		string[] oldNamesS;
		string[] oldNamesV;
		FlagId[] oldFID;
		StepId[] oldSID;
		VariantId[] oldVID;
		foreach (itm; itms) { mixin(S_TRACE);
			auto d = itm.getData();
			if (auto f = cast(cwx.flag.Flag)d) { mixin(S_TRACE);
				indices ~= indexOf(f.parent, f);
				oldNamesF ~= f.name;
				oldNames ~= f.name;
				refF ~= f;
				oldFID ~= toFlagId(f.path);
			}
			if (auto s = cast(Step)d) { mixin(S_TRACE);
				indices ~= indexOf(s.parent, s);
				oldNamesS ~= s.name;
				oldNames ~= s.name;
				refS ~= s;
				oldSID ~= toStepId(s.path);
			}
			if (auto v = cast(cwx.flag.Variant)d) { mixin(S_TRACE);
				indices ~= indexOf(v.parent, v);
				oldNamesV ~= v.name;
				oldNames ~= v.name;
				refV ~= v;
				oldVID ~= toVariantId(v.path);
			}
		}
		if (indices.length) { mixin(S_TRACE);
			auto newNamesF = _dir.createNewFlagNames(text, refF.length, oldNamesF);
			auto newNamesS = _dir.createNewStepNames(text, refS.length, oldNamesS);
			auto newNamesV = _dir.createNewVariantNames(text, refV.length, oldNamesV);
			bool changed = oldNamesF != newNamesF || oldNamesS != newNamesS || oldNamesV != newNamesV;
			if (oldNamesF != newNamesF) setNames(refF, newNamesF, uc);
			if (oldNamesS != newNamesS) setNames(refS, newNamesS, uc);
			if (oldNamesV != newNamesV) setNames(refV, newNamesV, uc);
			if (changed) { mixin(S_TRACE);
				storeEdit(indices, oldNames);
				refresh();
				_comm.refFlagAndStep.call(refF, refS, refV);
			}
		}
		_comm.refreshToolBar();
	}
	static bool setNames(F)(F[] refVals, in string[] newNames, UseCounter uc) { mixin(S_TRACE);
		// 一旦ダミーの名前に変える事で既存名称との重複を回避する
		if (!refVals.length) return false;
		auto dir = refVals[0].parent;
		auto newSet = new HashSet!string;
		foreach (name; newNames) newSet.add(name);
		auto tempSet = new HashSet!string;
		foreach (i; 0..refVals.length) { mixin(S_TRACE);
			auto name = createNewName("temp", (string name) { mixin(S_TRACE);
				if (!dir.canAppend!F(name)) return false;
				return !newSet.contains(name) && !tempSet.contains(name);
			});
			tempSet.add(name);
		}
		string[] oldNames;
		foreach (i, tempName; tempSet.toArray()) { mixin(S_TRACE);
			auto f = refVals[i];
			oldNames ~= f.name;
			auto oldID = F.toID(f.path);
			f.name = tempName;
			uc.change(oldID, F.toID(f.path), false);
		}
		bool changed = false;
		foreach (i, name; newNames) { mixin(S_TRACE);
			auto f = refVals[i];
			auto oldID = F.toID(f.path);
			f.name = name;
			uc.change(oldID, F.toID(f.path), false);
			if (oldNames[i] != name) changed = true;
		}
		return changed;
	}
	Control initCreateEditor(TableItem itm, int editC) { mixin(S_TRACE);
		assert (editC == VALUE);
		auto d = itm.getData();
		if (cast(cwx.flag.Flag)d || cast(Step)d) { mixin(S_TRACE);
			string[] strs;
			string str;
			initCombo(itm, editC, strs, str);
			return .createComboEditor!Combo(_comm, prop, itm.getParent(), strs, str);
		} else if (cast(cwx.flag.Variant)d) { mixin(S_TRACE);
			return .variantValueEditor(_comm, itm.getParent(), itm.getText(VALUE));
		} else assert (0);
	}
	void initCombo(TableItem itm, int column, out string[] strs, out string str) { mixin(S_TRACE);
		auto d = itm.getData();
		if (auto f = cast(cwx.flag.Flag)d) { mixin(S_TRACE);
			strs = [f.on, f.off];
			str = f.onOff ? f.on : f.off;
			return;
		} else if (auto s = cast(Step)d) { mixin(S_TRACE);
			foreach (i, v; s.values) { mixin(S_TRACE);
				strs ~= v;
				if (i == s.select) { mixin(S_TRACE);
					str = v;
				}
			}
			return;
		} else assert (0);
	}
	void initEditEnd(TableItem selItm, int column, Control ctrl) { mixin(S_TRACE);
		auto i = -1;
		auto val = VariantVal(false);
		if (auto combo = cast(Combo)ctrl) { mixin(S_TRACE);
			i = combo.getSelectionIndex();
			if (-1 == i) return;
		} else if (auto t = cast(Text)ctrl) { mixin(S_TRACE);
			auto text = t.getText();
			if ("" == text) return;
			val = .variantValueFromText(text);
			if (!val.valid) return;
		}
		auto selFlag = cast(cwx.flag.Flag)selItm.getData();
		auto selStep = cast(Step)selItm.getData();
		auto selVariant = cast(cwx.flag.Variant)selItm.getData();
		auto itms = flags.getSelection();
		itms = itms.remove(selItm);
		itms.insertInPlace(0, selItm);
		cwx.flag.Flag[] refF;
		Step[] refS;
		cwx.flag.Variant[] refV;
		int[] indices;
		string[] oldNames;
		int[] oldValues;
		VariantVal[] oldVals;
		foreach (itm; itms) { mixin(S_TRACE);
			auto f = cast(cwx.flag.Flag)itm.getData();
			if (selFlag && f) { mixin(S_TRACE);
				if (f.onOff == (0 == i)) continue;
				indices ~= indexOf(f.parent, f);
				oldNames ~= f.name;
				oldValues ~= f.onOff ? 0 : 1;
				f.onOff = 0 == i;
				itm.setText(column, f.onOff ? f.on : f.off);
				refF ~= f;
			}
			auto s = cast(Step)itm.getData();
			if (selStep && s) { mixin(S_TRACE);
				if (s.select == i) continue;
				indices ~= indexOf(s.parent, s);
				oldNames ~= s.name;
				oldValues ~= s.select;
				s.select(i);
				itm.setText(column, getStepValue(prop, s, s.select));
				refS ~= s;
			}
			auto v = cast(cwx.flag.Variant)itm.getData();
			if (selVariant && v) { mixin(S_TRACE);
				indices ~= indexOf(v.parent, v);
				oldNames ~= v.name;
				oldVals ~= VariantVal(v);
				final switch (val.type) {
				case VariantType.Number:
					v.value = val.numVal;
					break;
				case VariantType.String:
					v.value = val.strVal;
					break;
				case VariantType.Boolean:
					v.value = val.boolVal;
					break;
				}
				itm.setText(column, .variantValueToText(v));
				refV ~= v;
			}
		}
		if (indices.length) { mixin(S_TRACE);
			storeEdit(indices, oldNames, oldValues, [], oldVals);
			_comm.refFlagAndStep.call(refF, refS, refV);
		}
		_comm.refreshToolBar();
	}
	void initTimCreateEditor(TableItem itm, int column, out string[] strs, out string str) { mixin(S_TRACE);
		assert (!_readOnly);
		assert (column is INIT);
		VariableInitialization initialization;
		auto d = itm.getData();
		if (auto f = cast(cwx.flag.Flag)d) { mixin(S_TRACE);
			initialization = f.initialization;
		} else if (auto f = cast(Step)d) { mixin(S_TRACE);
			initialization = f.initialization;
		} else if (auto f = cast(cwx.flag.Variant)d) { mixin(S_TRACE);
			initialization = f.initialization;
		} else assert (0);

		str = prop.msgs.variableInitializationShortName(initialization);
		foreach (tim; selectableInitialization(_local)) { mixin(S_TRACE);
			strs ~= prop.msgs.variableInitializationShortName(tim);
		}
	}
	void initTimEditEnd(TableItem selItm, int column, Combo combo) { mixin(S_TRACE);
		assert (!_readOnly);
		assert (column is INIT);
		auto tims = selectableInitialization(_local);
		auto tim = tims[combo.getSelectionIndex()];

		auto itms = flags.getSelection();
		itms = itms.remove(selItm);
		itms.insertInPlace(0, selItm);

		cwx.flag.Flag[] refF;
		Step[] refS;
		cwx.flag.Variant[] refV;
		cwx.flag.Flag[] oldF;
		Step[] oldS;
		cwx.flag.Variant[] oldV;

		foreach (itm; itms) { mixin(S_TRACE);
			auto d = itm.getData();
			if (auto f = cast(cwx.flag.Flag)d) { mixin(S_TRACE);
				if (f.initialization is tim) continue;
				oldF ~= new cwx.flag.Flag(f);
				oldF[$ - 1].useCounter = f.useCounter.sub;
				refF ~= f;
				f.initialization = tim;
			}
			if (auto f = cast(Step)d) { mixin(S_TRACE);
				if (f.initialization is tim) continue;
				oldS ~= new Step(f);
				oldS[$ - 1].useCounter = f.useCounter.sub;
				refS ~= f;
				f.initialization = tim;
			}
			if (auto f = cast(cwx.flag.Variant)d) { mixin(S_TRACE);
				if (f.initialization is tim) continue;
				oldV ~= new cwx.flag.Variant(f);
				oldV[$ - 1].useCounter = f.useCounter.sub;
				refV ~= f;
				f.initialization = tim;
			}
			itm.setText(INIT, prop.msgs.variableInitializationShortName(tim));
		}
		if (oldF.length || oldS.length || oldV.length) { mixin(S_TRACE);
			storeEditParams(oldF, oldS, oldV);
			_comm.refFlagAndStep.call(refF, refS, refV);
			_comm.refreshToolBar();
		}
	}
	static VariableInitialization[] selectableInitialization(bool local) { mixin(S_TRACE);
		if (local) { mixin(S_TRACE);
			return [VariableInitialization.Leave, VariableInitialization.EventExit, VariableInitialization.None];
		} else { mixin(S_TRACE);
			return [VariableInitialization.Leave, VariableInitialization.Complete, VariableInitialization.None];
		}
	}

	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			foreach (dlg; _editDlgsF.values) { mixin(S_TRACE);
				dlg.forceCancel();
			}
			foreach (dlg; _editDlgsS.values) { mixin(S_TRACE);
				dlg.forceCancel();
			}
			foreach (dlg; _editDlgsV.values) { mixin(S_TRACE);
				dlg.forceCancel();
			}
		}
	}
	@property
	Shell dlgParShl() { mixin(S_TRACE);
		if (flags && !flags.isDisposed()) return flags.getShell();
		return _comm.mainWin.shell.getShell();
	}
	void selectAll() { mixin(S_TRACE);
		foreach (i; 0 .. flags.getItemCount()) { mixin(S_TRACE);
			flags.select(i);
		}
		flagsSelected();
	}
	void copyFlagTree(bool onOff) { mixin(S_TRACE);
		auto c = createSetFlagTree(selectionFlags, onOff);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys, LATEST_VERSION)));
		_comm.refreshToolBar();
	}
	void copyStepTree(int value) { mixin(S_TRACE);
		auto c = createSetStepTree(selectionSteps, value);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys, LATEST_VERSION)));
		_comm.refreshToolBar();
	}
	void copyInitTree() { mixin(S_TRACE);
		cwx.flag.Flag[] fs;
		Step[] ss;
		cwx.flag.Variant[] vs;
		getSelectionFlagAndStep(fs, ss, vs);
		auto c = createInitVariablesTree(fs, ss, vs);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys, LATEST_VERSION)));
		_comm.refreshToolBar();
	}
	void copyFlagReverseTree() { mixin(S_TRACE);
		auto c = createReverseFlagTree(selectionFlags);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys, LATEST_VERSION)));
		_comm.refreshToolBar();
	}
	void copyStepUpTree() { mixin(S_TRACE);
		auto c = createSetStepUpTree(selectionSteps);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys, LATEST_VERSION)));
		_comm.refreshToolBar();
	}
	void copyStepDownTree() { mixin(S_TRACE);
		auto c = createSetStepDownTree(selectionSteps);
		if (!c) return;
		XMLtoCB(prop, _comm.clipboard, c.toXML(new XMLOption(prop.sys, LATEST_VERSION)));
		_comm.refreshToolBar();
	}

public:
	this (Commons comm, Props prop, UndoManager undo, bool local = false, bool readOnly = false) { mixin(S_TRACE);
		_id = .objectIDValue(this);

		_undo = undo;
		_comm = comm;
		this.prop = prop;
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		_local = local;
	}

	/// コントロールを生成する。
	/// Params:
	/// parent = 親コントロール。
	Control createControl(Composite parent, Composite incSearchParent, void delegate() gotFocus) { mixin(S_TRACE);
		_comp = new Composite(parent, SWT.NONE);
		_comp.setLayout(new FillLayout);
		flags = .rangeSelectableTable(_comp, SWT.MULTI | SWT.BORDER | SWT.FULL_SELECTION);
		flags.setHeaderVisible(true);
		if (gotFocus) .listener(flags, SWT.FocusIn, gotFocus);
		auto nameCol = new TableColumn(flags, SWT.NULL);
		nameCol.setText(prop.msgs.flagName);
		if (_local) { mixin(S_TRACE);
			saveColumnWidth!("prop.var.etc.localFlagNameColumn")(prop, nameCol);
		} else { mixin(S_TRACE);
			saveColumnWidth!("prop.var.etc.flagNameColumn")(prop, nameCol);
		}
		auto initCol = new TableColumn(flags, SWT.NULL);
		initCol.setText(prop.msgs.flagInit);
		if (_local) { mixin(S_TRACE);
			saveColumnWidth!("prop.var.etc.localFlagInitColumn")(prop, initCol);
		} else { mixin(S_TRACE);
			saveColumnWidth!("prop.var.etc.flagInitColumn")(prop, initCol);
		}
		auto initTimCol = new TableColumn(flags, SWT.NULL);
		initTimCol.setText(prop.msgs.variableInitializationShort);
		if (_local) { mixin(S_TRACE);
			saveColumnWidth!("prop.var.etc.localVariableInitializationColumn")(prop, initTimCol);
		} else { mixin(S_TRACE);
			saveColumnWidth!("prop.var.etc.variableInitializationColumn")(prop, initTimCol);
		}
		auto countCol = new TableColumn(flags, SWT.NULL);
		countCol.setText(prop.msgs.flagCount);
		if (_local) { mixin(S_TRACE);
			saveColumnWidth!("prop.var.etc.localFlagCountColumn")(prop, countCol);
		} else { mixin(S_TRACE);
			saveColumnWidth!("prop.var.etc.flagCountColumn")(prop, countCol);
		}

		updateIncSearchParent(incSearchParent);

		flags.addKeyListener(new KListener);
		flags.addMouseListener(new MListener);
		auto menu = new Menu(flags.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &incSearch, () => _dir && (_dir.flags.length || _dir.steps.length || _dir.variants.length));
		new MenuItem(menu, SWT.SEPARATOR);
		if (_readOnly) { mixin(S_TRACE);
			createMenuItem(_comm, menu, MenuID.ShowProp, &edit, &canEdit);
		} else { mixin(S_TRACE);
			createMenuItem(_comm, menu, MenuID.EditProp, &edit, &canEdit);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.NewFlag, &createFlag, () => _dir !is null && (!_local || !_comm.summary || !_comm.summary.legacy));
			createMenuItem(_comm, menu, MenuID.NewStep, &createStep, () => _dir !is null && (!_local || !_comm.summary || !_comm.summary.legacy));
			createMenuItem(_comm, menu, MenuID.NewVariant, &createVariant, () => _dir && (!_comm.summary || !_comm.summary.legacy));
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.Undo, &this.undo, &_undo.canUndo);
			createMenuItem(_comm, menu, MenuID.Redo, &this.redo, &_undo.canRedo);
		}
		new MenuItem(menu, SWT.SEPARATOR);
		appendMenuTCPD(_comm, menu, this, !_readOnly, true, !_readOnly, !_readOnly, !_readOnly);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.SelectAll, &selectAll, () => flags.getItemCount() && flags.getSelectionCount() != flags.getItemCount());
		new MenuItem(menu, SWT.SEPARATOR);

		void delegate() dlg = null;
		auto evt = createMenuItem(_comm, menu, MenuID.CreateVariableEventTree, dlg, () => 0 < flags.getSelectionCount(), SWT.CASCADE);
		auto mEvt = new Menu(parent.getShell(), SWT.DROP_DOWN);
		evt.setMenu(mEvt);
		createMenuItem(_comm, mEvt, MenuID.InitVariablesTree, &copyInitTree, () => 0 < flags.getSelectionCount());
		new MenuItem(mEvt, SWT.SEPARATOR);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.contentName(CType.ReverseFlag), "R", "", false), prop.images.content(CType.ReverseFlag), &copyFlagReverseTree, () => 0 < selectionFlags.length);
		new MenuItem(mEvt, SWT.SEPARATOR);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.setFlagTrue, "T", "", false), prop.images.content(CType.SetFlag), () => copyFlagTree(true), () => 0 < selectionFlags.length);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.setFlagFalse, "F", "", false), prop.images.content(CType.SetFlag), () => copyFlagTree(false), () => 0 < selectionFlags.length);
		new MenuItem(mEvt, SWT.SEPARATOR);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.contentName(CType.SetStepUp), "U", "", false), prop.images.content(CType.SetStepUp), &copyStepUpTree, () => 0 < selectionSteps.length);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.contentName(CType.SetStepDown), "D", "", false), prop.images.content(CType.SetStepDown), &copyStepDownTree, () => 0 < selectionSteps.length);
		new MenuItem(mEvt, SWT.SEPARATOR);
		void ssValue(uint i) { mixin(S_TRACE);
			string mnemonic = i < 10 ? .text(i) : "";
			createMenuItem2(_comm, mEvt, MenuProps.buildMenu(.tryFormat(prop.msgs.setStepValue, .parseDollarParams(prop.var.etc.stepValueName, ['N':.to!string(i)])), mnemonic, "", false), prop.images.content(CType.SetStep), () => copyStepTree(i), () => 0 < selectionSteps.length);
		}
		foreach (i; 0..prop.looks.stepMaxCount) { mixin(S_TRACE);
			ssValue(i);
		}

		if (!_readOnly) { mixin(S_TRACE);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.FindID, &replaceID, &canReplaceID);
		}
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.CopyVariablePath, &copyVariablePath, &canCopyVariablePath);
		flags.setMenu(menu);

		auto ds = new DragSource(flags, DND.DROP_MOVE | DND.DROP_COPY);
		ds.setTransfer([XMLBytesTransfer.getInstance()]);
		ds.addDragListener(new FlagDragListener);
		if (!_readOnly) { mixin(S_TRACE);
			auto dt = new DropTarget(flags, DND.DROP_COPY);
			dt.setTransfer([XMLBytesTransfer.getInstance()]);
			dt.addDropListener(new FlagDrop);
		}

		_comm.refUseCount.add(&refreshUseCount);
		_comm.replText.add(&refresh);
		flags.addSelectionListener(new SListener);
		flags.addDisposeListener(new DListener);

		if (!_readOnly) { mixin(S_TRACE);
			_tte = new TableTextEdit(_comm, prop, flags, NAME, &nameEditEnd, null);
			_tce = new TableTCEdit(_comm, flags, VALUE, &initCreateEditor, &initEditEnd, null);
			_tie = new TableComboEdit!Combo(_comm, prop, flags, INIT, &initTimCreateEditor, &initTimEditEnd, (itm, column) { mixin(S_TRACE);
				if (_local) return true;
				auto d = itm.getData();
				if (auto f = cast(cwx.flag.Flag)d) { mixin(S_TRACE);
					return !_comm.summary.legacy || f.initialization !is VariableInitialization.Leave;
				} else if (auto f = cast(Step)d) { mixin(S_TRACE);
					return !_comm.summary.legacy || f.initialization !is VariableInitialization.Leave;
				} else if (auto f = cast(cwx.flag.Variant)d) { mixin(S_TRACE);
					return true;
				} else assert (0);
			}, null);
		}

		_comp.addDisposeListener(new Dispose);

		return _comp;
	}
	void updateIncSearchParent(Composite incSearchParent) {
		auto matchers = [
			AdditionMatcher(MenuProps.buildMenu(.objName!(cwx.flag.Variant)(prop), "V", "", false), (o) => cast(cwx.flag.Variant)o !is null),
			AdditionMatcher(MenuProps.buildMenu(.objName!Step(prop), "S", "", false), (o) => cast(Step)o !is null),
			AdditionMatcher(MenuProps.buildMenu(.objName!(cwx.flag.Flag)(prop), "F", "", false), (o) => cast(cwx.flag.Flag)o !is null),
		];
		_incSearch = new IncSearch(_comm, incSearchParent, () => _dir && (_dir.flags.length || _dir.steps.length || _dir.variants.length), matchers);
		_incSearch.modEvent ~= &refresh;
	}
	private Composite _comp = null;
	@property
	Control widget() { return _comp; }

	@property
	package cwx.flag.Flag[ptrdiff_t] dragFlags() { return _dragFlags; }
	@property
	package Step[ptrdiff_t] dragSteps() { return _dragSteps; }
	@property
	package cwx.flag.Variant[ptrdiff_t] dragVariants() { return _dragVariants; }

	private void refreshStatusLine() { mixin(S_TRACE);
		string s = "";
		void put(lazy string name, size_t count) { mixin(S_TRACE);
			if (!count) return;
			if (s.length) s ~= " ";
			s ~= .tryFormat(prop.msgs.flagStatus, name, count);
		}
		if (_dir) { mixin(S_TRACE);
			put(prop.msgs.flag, _dir.flags.length);
			put(prop.msgs.step, _dir.steps.length);
			put(prop.msgs.variant, _dir.variants.length);
		}
		cwx.flag.Flag[] selFlags;
		Step[] selSteps;
		cwx.flag.Variant[] selVariants;
		getSelectionFlagAndStep(selFlags, selSteps, selVariants);
		if (selFlags.length || selSteps.length || selVariants.length) { mixin(S_TRACE);
			s = .tryFormat(prop.msgs.flagStatusSel, s, selFlags.length + selSteps.length + selVariants.length);
		}
		_statusLine = s;
		_comm.setStatusLine(flags, _statusLine);
	}
	@property
	string statusLine() { return _statusLine; }

	private void refreshUseCount() { mixin(S_TRACE);
		foreach (itm; flags.getItems()) { mixin(S_TRACE);
			if (cast(cwx.flag.Flag)itm.getData()) { mixin(S_TRACE);
				itm.setText(UC, to!(string)(uc.get(toFlagId((cast(cwx.flag.Flag)itm.getData()).path))));
			} else if (cast(Step)itm.getData()) { mixin(S_TRACE);
				itm.setText(UC, to!(string)(uc.get(toStepId((cast(Step)itm.getData()).path))));
			} else { mixin(S_TRACE);
				assert (cast(cwx.flag.Variant)itm.getData() !is null);
				itm.setText(UC, to!(string)(uc.get(toVariantId((cast(cwx.flag.Variant)itm.getData()).path))));
			}
		}
	}
	void refresh() { mixin(S_TRACE);
		refresh([]);
	}
	void refresh(in Object[] selObjs) { mixin(S_TRACE);
		if (!flags || flags.isDisposed()) return;
		enterEdit();
		if (_dir) { mixin(S_TRACE);
			const(Object)[] sels;
			if (selObjs.length) { mixin(S_TRACE);
				sels ~= selObjs;
			} else { mixin(S_TRACE);
				foreach (itm; flags.getSelection()) { mixin(S_TRACE);
					sels ~= itm.getData();
				}
			}
			flags.deselectAll();
			refreshFlags();
			foreach (i, itm; flags.getItems()) { mixin(S_TRACE);
				if (.contains(sels, itm.getData())) { mixin(S_TRACE);
					flags.select(cast(int)i);
				}
			}
			if (selObjs.length) { mixin(S_TRACE);
				flags.showSelection();
			}
		}
		refreshStatusLine();
	}
	/// 表示上で選択されているindex。
	@property
	int[] selected() { mixin(S_TRACE);
		if (flags && !flags.isDisposed()) { mixin(S_TRACE);
			return flags.getSelectionIndices();
		}
		return [];
	}
	/// 表示上で選択されているフラグまたはステップ。
	int[] selectedItems(out cwx.flag.Flag[] fs, out Step[] ss, out cwx.flag.Variant[] vs) { mixin(S_TRACE);
		if (flags && !flags.isDisposed()) { mixin(S_TRACE);
			auto indices = flags.getSelectionIndices();
			foreach (i; indices) { mixin(S_TRACE);
				auto o = flags.getItem(i).getData();
				auto f = cast(cwx.flag.Flag)o;
				if (f) fs ~= f;
				auto s = cast(Step)o;
				if (s) ss ~= s;
				auto v = cast(cwx.flag.Variant)o;
				if (v) vs ~= v;
			}
			return indices;
		}
		return [];
	}
	/// ditto
	@property
	cwx.flag.Flag[] selectionFlags() { mixin(S_TRACE);
		cwx.flag.Flag[] fs;
		Step[] ss;
		cwx.flag.Variant[] vs;
		getSelectionFlagAndStep(fs, ss, vs);
		return fs;
	}
	/// ditto
	@property
	Step[] selectionSteps() { mixin(S_TRACE);
		cwx.flag.Flag[] fs;
		Step[] ss;
		cwx.flag.Variant[] vs;
		getSelectionFlagAndStep(fs, ss, vs);
		return ss;
	}
	/// ditto
	@property
	cwx.flag.Variant[] selectionVariants() { mixin(S_TRACE);
		cwx.flag.Flag[] fs;
		Step[] ss;
		cwx.flag.Variant[] vs;
		getSelectionFlagAndStep(fs, ss, vs);
		return vs;
	}
	/// ditto
	@property
	ptrdiff_t[] selectionFlagIndices() { mixin(S_TRACE);
		ptrdiff_t[] r;
		foreach (f; selectionFlags) { mixin(S_TRACE);
			assert (f !is null);
			assert (f.parent !is null);
			r ~= f.parent.indexOf(f);
		}
		return r;
	}
	/// ditto
	@property
	ptrdiff_t[] selectionStepIndices() { mixin(S_TRACE);
		ptrdiff_t[] r;
		foreach (f; selectionSteps) { mixin(S_TRACE);
			assert (f !is null);
			assert (f.parent !is null);
			r ~= f.parent.indexOf(f);
		}
		return r;
	}
	/// ditto
	@property
	ptrdiff_t[] selectionVariantIndices() { mixin(S_TRACE);
		ptrdiff_t[] r;
		foreach (f; selectionVariants) { mixin(S_TRACE);
			assert (f !is null);
			assert (f.parent !is null);
			r ~= f.parent.indexOf(f);
		}
		return r;
	}

	/// フラグ生成のダイアログボックスを開く。
	/// 適切に設定された場合、新規フラグを生成する。
	void createFlag() { mixin(S_TRACE);
		if (_readOnly) return;
		editFlag(_dir, null);
	}

	/// ステップ生成のダイアログボックスを開く。
	/// 適切に設定された場合、新規ステップを生成する。
	void createStep() { mixin(S_TRACE);
		if (_readOnly) return;
		editStep(_dir, null);
	}

	/// コモン生成のダイアログボックスを開く。
	/// 適切に設定された場合、新規ステップを生成する。
	void createVariant() { mixin(S_TRACE);
		if (_readOnly) return;
		editVariant(_dir, null);
	}

	/// 選択中のフラグ・ステップの編集を開始する。
	void edit() { mixin(S_TRACE);
		if (_dir !is null) { mixin(S_TRACE);
			foreach (index; flags.getSelectionIndices()) { mixin(S_TRACE);
				auto d = flags.getItem(index).getData();
				if (auto variant = cast(cwx.flag.Variant)d) { mixin(S_TRACE);
					editVariant(variant.parent, variant);
				} else if (auto step = cast(Step)d) { mixin(S_TRACE);
					editStep(step.parent, step);
				} else if (auto flag = cast(cwx.flag.Flag)d) { mixin(S_TRACE);
					editFlag(flag.parent, flag);
				} else assert (0);
			}
		}
	}
	@property
	bool canEdit() { mixin(S_TRACE);
		return flags.getSelectionIndex() != -1;
	}
	/// 指定されたフラグの編集を開始する。
	void edit(cwx.flag.Flag flag) { mixin(S_TRACE);
		enforce(flag.parent is dir);
		editFlag(flag.parent, flag);
	}
	/// 指定されたステップの編集を開始する。
	void edit(Step step) { mixin(S_TRACE);
		enforce(step.parent is dir);
		editStep(step.parent, step);
	}
	/// 指定されたコモンの編集を開始する。
	void edit(cwx.flag.Variant variant) { mixin(S_TRACE);
		enforce(variant.parent is dir);
		editVariant(variant.parent, variant);
	}

	/// 編集対象のディレクトリを設定する。
	/// Params:
	/// dir = ディレクトリ。
	void setDir(FlagDir dir, bool forceRefresh = false) { mixin(S_TRACE);
		if (!forceRefresh && _dir is dir) return;
		cancelEdit();
		foreach (dlg; _editDlgsF.values) { mixin(S_TRACE);
			dlg.forceCancel();
		}
		foreach (dlg; _editDlgsS.values) { mixin(S_TRACE);
			dlg.forceCancel();
		}
		foreach (dlg; _editDlgsV.values) { mixin(S_TRACE);
			dlg.forceCancel();
		}
		_dir = dir;
		refresh();
	}

	/// Returns: 編集対象のディレクトリ。
	@property
	FlagDir dir() { mixin(S_TRACE);
		return _dir;
	}

	private void selectImpl(Object flag, bool deselect) { mixin(S_TRACE);
		if (deselect) flags.deselectAll();
		foreach (i, itm; flags.getItems()) { mixin(S_TRACE);
			if (itm.getData() is flag) { mixin(S_TRACE);
				flags.select(cast(int)i);
				break;
			}
		}
		flags.showSelection();
		_comm.refreshToolBar();
	}
	/// フラグを選択する。
	void select(cwx.flag.Flag flag, bool deselect) { mixin(S_TRACE);
		selectImpl(flag, deselect);
	}
	/// ステップを選択する。
	void select(Step step, bool deselect) { mixin(S_TRACE);
		selectImpl(step, deselect);
	}
	/// コモンを選択する。
	void select(cwx.flag.Variant variant, bool deselect) { mixin(S_TRACE);
		selectImpl(variant, deselect);
	}
	void deselectAll() { mixin(S_TRACE);
		flags.deselectAll();
	}

	/// 状態変数のパスをコピーする。
	@property
	bool canCopyVariablePath() { mixin(S_TRACE);
		return 0 < flags.getSelectionCount();
	}
	/// ditto
	void copyVariablePath() { mixin(S_TRACE);
		if (!canCopyVariablePath) return;

		char[] buf;
		foreach (itm; flags.getSelection()) { mixin(S_TRACE);
			if (buf.length) buf ~= .newline;
			auto f = cast(cwx.flag.Flag)itm.getData();
			if (f) buf ~= f.path;
			auto s = cast(Step)itm.getData();
			if (s) buf ~= s.path;
			auto v = cast(cwx.flag.Variant)itm.getData();
			if (v) buf ~= v.path;
			assert (f || s || v);
		}
		_comm.clipboard.setContents([new ArrayWrapperString(buf)],
			[TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}

	/// コントロールを解放する。
	void dispose() { mixin(S_TRACE);
		if (flags !is null) { mixin(S_TRACE);
			flags.dispose();
		}
	}

	/// 使用回数カウンタを設定する。
	/// Params:
	/// uc = 使用回数カウンタ。
	@property
	void useCounter(UseCounter uc) { mixin(S_TRACE);
		this.uc = uc;
	}

	override {
		void cut(SelectionEvent se) { mixin(S_TRACE);
			if (_readOnly) return;
			if (!_dir) return;
			copy(se);
			del(se);
		}
		void copy(SelectionEvent se) { mixin(S_TRACE);
			if (!_dir) return;
			cwx.flag.Flag[] fs;
			Step[] ss;
			cwx.flag.Variant[] vs;
			if (getSelectionFlagAndStep(fs, ss, vs)) { mixin(S_TRACE);
				XNode node;
				getNode(_dir, fs, ss, vs, node);
				node.newAttr("paneId", _id);
				XMLtoCB(prop, _comm.clipboard, node.text);
				_comm.refreshToolBar();
			}
		}
		void paste(SelectionEvent se) { mixin(S_TRACE);
			if (_readOnly) return;
			if (!_dir) return;
			auto c = CBtoXML(_comm.clipboard);
			if (c) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto node = XNode.parse(c);
					pasteImpl(node);
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
		void del(SelectionEvent se) { mixin(S_TRACE);
			if (_readOnly) return;
			if (!_dir) return;
			enterEdit();
			auto selsF = selectionFlagIndices;
			auto selsS = selectionStepIndices;
			auto selsV = selectionVariantIndices;
			cwx.flag.Flag[ptrdiff_t] fs;
			Step[ptrdiff_t] ss;
			cwx.flag.Variant[ptrdiff_t] vs;
			auto sels = flags.getSelection();
			foreach (itm; sels) { mixin(S_TRACE);
				auto data = itm.getData();
				if (auto flag = cast(cwx.flag.Flag)data) { mixin(S_TRACE);
					fs[flag.parent.indexOf(flag)] = flag;
				}
				if (auto step = cast(Step)data) { mixin(S_TRACE);
					ss[step.parent.indexOf(step)] = step;
				}
				if (auto variant = cast(cwx.flag.Variant)data) { mixin(S_TRACE);
					vs[variant.parent.indexOf(variant)] = variant;
				}
			}
			foreach (itm; sels) { mixin(S_TRACE);
				auto data = itm.getData();
				if (auto flag = cast(cwx.flag.Flag)data) { mixin(S_TRACE);
					uc.deleteID(toFlagId(flag.path));
					_dir.remove(flag);
				}
				if (auto step = cast(Step)data) { mixin(S_TRACE);
					uc.deleteID(toStepId(step.path));
					_dir.remove(step);
				}
				if (auto variant = cast(cwx.flag.Variant)data) { mixin(S_TRACE);
					uc.deleteID(toVariantId(variant.path));
					_dir.remove(variant);
				}
			}
			callDeleteEvent();
			storeDelete(selsF, selsS, selsV, fs, ss, vs);
			_comm.delFlagAndStep.call(fs.values, ss.values, vs.values);
			refresh();
			_comm.refreshToolBar();
			_comm.refUseCount.call();
		}
		void clone(SelectionEvent se) { mixin(S_TRACE);
			if (_readOnly) return;
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copy(se);
			paste(se);
		}
		@property
		bool canDoTCPD() { mixin(S_TRACE);
			return _comm.summary !is null;
		}
		@property
		bool canDoT() { mixin(S_TRACE);
			if (_readOnly) return false;
			return flags.getSelectionIndex() != -1;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			return canDoT;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			if (_readOnly) return false;
			return _comm.summary !is null && CBisXML(_comm.clipboard) && (!_local || !_comm.summary || !_comm.summary.legacy);
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			if (_readOnly) return false;
			return canDoT;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			if (_readOnly) return false;
			return canDoC && (!_local || !_comm.summary || !_comm.summary.legacy);
		}
	}
	private bool pasteImpl(ref XNode node) { mixin(S_TRACE);
		if (_readOnly) return false;
		try { mixin(S_TRACE);
			enterEdit();
			string newPath;
			string rootId;
			cwx.flag.Flag[string] cFlags;
			Step[string] cSteps;
			cwx.flag.Variant[string] cVariants;
			auto selsF = selectionFlagIndices;
			auto selsS = selectionStepIndices;
			auto selsV = selectionVariantIndices;
			auto ver = new XMLInfo(prop.sys, LATEST_VERSION);
			if (_dir.appendFromNode(node, ver, true, false, _local, cFlags, cSteps, cVariants, newPath, rootId)) { mixin(S_TRACE);
				ptrdiff_t[] flagIndices;
				ptrdiff_t[] stepIndices;
				ptrdiff_t[] variantIndices;
				if (!cFlags.length && !cSteps.length && !cVariants.length) return false;
				foreach (f; cFlags) { mixin(S_TRACE);
					flagIndices ~= f.parent.indexOf(f);
					uc.createID(toFlagId(f.path));
				}
				foreach (s; cSteps) { mixin(S_TRACE);
					stepIndices ~= s.parent.indexOf(s);
					uc.createID(toStepId(s.path));
				}
				foreach (v; cVariants) { mixin(S_TRACE);
					variantIndices ~= v.parent.indexOf(v);
					uc.createID(toVariantId(v.path));
				}
				callCreateEvent();
				storeInsert(selsF, selsS, selsV, flagIndices, stepIndices, variantIndices);
				Object[] objs;
				objs ~= cFlags.values;
				objs ~= cSteps.values;
				objs ~= cVariants.values;
				refresh(objs);
				_comm.refFlagAndStep.call(cFlags.values, cSteps.values, cVariants.values);
				_comm.refUseCount.call();
				_comm.refreshToolBar();
				return true;
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
		return false;
	}
	void undo() { mixin(S_TRACE);
		if (_readOnly) return;
		cancelEdit();
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() { mixin(S_TRACE);
		if (_readOnly) return;
		cancelEdit();
		_undo.redo();
		_comm.refreshToolBar();
	}

	void cancelEdit() { mixin(S_TRACE);
		if (_tte) _tte.cancel();
		if (_tce) _tce.cancel();
		if (_tie) _tie.cancel();
	}
	void enterEdit() { mixin(S_TRACE);
		if (_tte) _tte.enter();
		if (_tce) _tce.enter();
		if (_tie) _tie.enter();
	}

	void replaceID() { mixin(S_TRACE);
		if (_readOnly) return;
		auto index = flags.getSelectionIndex();
		if (index <= -1) return;
		auto data = flags.getItem(index).getData();
		if (_local) { mixin(S_TRACE);
			auto ec = cast(LocalVariableOwner)uc.owner;
			assert (ec !is null);
			auto replWin = _comm.mainWin.openReplWin();
			CWXPath[] arr;
			if (auto f = cast(cwx.flag.Flag)data) { mixin(S_TRACE);
				SortableCWXPath!FlagUser.sortedPaths(uc.valueSet(toFlagId(f.path)), (p) { mixin(S_TRACE);
					arr ~= p.obj.owner;
				});
			} else if (auto f = cast(Step)data) { mixin(S_TRACE);
				SortableCWXPath!StepUser.sortedPaths(uc.valueSet(toStepId(f.path)), (p) { mixin(S_TRACE);
					arr ~= p.obj.owner;
				});
			} else if (auto f = cast(cwx.flag.Variant)data) { mixin(S_TRACE);
				SortableCWXPath!VariantUser.sortedPaths(uc.valueSet(toVariantId(f.path)), (p) { mixin(S_TRACE);
					arr ~= p.obj.owner;
				});
			} else assert (0);
			replWin.setFindResult(.cwxPlace(ec), arr, _comm.prop.msgs.replLocalVariables);
		} else { mixin(S_TRACE);
			if (auto f = cast(cwx.flag.Flag)data) _comm.replaceID(toFlagId(f.path), true);
			if (auto f = cast(Step)data) _comm.replaceID(toStepId(f.path), true);
			if (auto f = cast(cwx.flag.Variant)data) _comm.replaceID(toVariantId(f.path), true);
		}
	}
	@property
	bool canReplaceID() { mixin(S_TRACE);
		if (_readOnly) return false;
		auto index = flags.getSelectionIndex();
		if (index <= -1) return false;
		auto data = flags.getItem(index).getData();
		return cast(cwx.flag.Flag)data || cast(Step)data || cast(cwx.flag.Variant)data;
	}

	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		if (!_dir) return false;
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		switch (cate) {
		case "flag": { mixin(S_TRACE);
			if (index >= _dir.flags.length) return false;
			if (!cphasattr(path, "nofocus")) forceFocus(flags, shellActivate);
			if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
				edit(_dir.flags[index]);
			} else { mixin(S_TRACE);
				select(_dir.flags[index], cphasattr(path, "only"));
			}
			_comm.refreshToolBar();
			return true;
		}
		case "step": { mixin(S_TRACE);
			if (index >= dir.steps.length) return false;
			if (!cphasattr(path, "nofocus")) forceFocus(flags, shellActivate);
			if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
				edit(_dir.steps[index]);
			} else { mixin(S_TRACE);
				select(_dir.steps[index], cphasattr(path, "only"));
			}
			_comm.refreshToolBar();
			return true;
		}
		case "variant": { mixin(S_TRACE);
			if (index >= dir.variants.length) return false;
			if (!cphasattr(path, "nofocus")) forceFocus(flags, shellActivate);
			if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
				edit(dir.variants[index]);
			} else { mixin(S_TRACE);
				select(dir.variants[index], cphasattr(path, "only"));
			}
			_comm.refreshToolBar();
			return true;
		}
		case "": { mixin(S_TRACE);
			return true;
		}
		default: break;
		}
		return false;
	}

	@property
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		cwx.flag.Flag[] fs;
		Step[] ss;
		cwx.flag.Variant[] vs;
		getSelectionFlagAndStep(fs, ss, vs);
		foreach (f; fs) { mixin(S_TRACE);
			r ~= f.cwxPath(true);
		}
		foreach (s; ss) { mixin(S_TRACE);
			r ~= s.cwxPath(true);
		}
		foreach (v; vs) { mixin(S_TRACE);
			r ~= v.cwxPath(true);
		}
		return r;
	}
}
