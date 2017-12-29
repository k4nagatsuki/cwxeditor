
module cwx.editor.gui.dwt.flagtable;

import cwx.summary;
import cwx.flag;
import cwx.utils;
import cwx.usecounter;
import cwx.path;
import cwx.menu;
import cwx.types;
import cwx.system;
import cwx.card;
import cwx.event;
import cwx.xml;
import cwx.structs;
import cwx.msgutils;
import cwx.sjis;

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.messageutils;

static import std.algorithm;
import std.algorithm: map, max, min;
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

private string getSPCharPreviewValue(in Commons comm, char name) { mixin(S_TRACE);
	auto dc = std.ascii.toUpper(name);
	switch (dc) {
	case 'M': return comm.prop.var.etc.messageVarSelected;
	case 'U': return comm.prop.var.etc.messageVarUnselected;
	case 'R': return comm.prop.var.etc.messageVarRandom;
	case 'C': return comm.prop.var.etc.messageVarCard;
	case 'I': return comm.prop.var.etc.messageVarRef;
	case 'T': return comm.prop.var.etc.messageVarTeam;
	case 'Y': return comm.prop.var.etc.messageVarYado;
	default: return "";
	}
}

/// ステップ設定用のダイアログ。
public class StepEditDialog : AbsDialog {
private:
	Commons _comm;
	Summary _summ;

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
	Button _expandSPChars;

	UndoManager _undo;

	class UndoValue : Undo {
		private int _index;
		private string _oldName;
		private string _newName;
		this (int index, string oldName, string newName) { mixin(S_TRACE);
			_index = index;
			_oldName = oldName;
			_newName = newName;
		}
		private void impl() { mixin(S_TRACE);
			if (_tte.isEditing) _tte.cancel();
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
	class UndoValues : Undo {
		private string[] _values;
		this () { mixin(S_TRACE);
			_values = _valueCache[0 .. this.outer._values.getItemCount()].dup;
		}
		private void impl() { mixin(S_TRACE);
			if (_tte.isEditing) _tte.cancel();
			this.outer._values.setRedraw(false);
			scope (exit) this.outer._values.setRedraw(true);
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
	class UndoValueRange : Undo {
		private size_t[] _fromIndices;
		private string[][] _values;
		this (in URange[] ranges) { mixin(S_TRACE);
			foreach (range; ranges) { mixin(S_TRACE);
				_fromIndices ~= range.fromIndex;
				_values ~= _valueCache[range.fromIndex .. range.toIndex].dup;
			}
		}
		private void impl() { mixin(S_TRACE);
			if (_tte.isEditing) _tte.cancel();
			this.outer._values.setRedraw(false);
			scope (exit) this.outer._values.setRedraw(true);
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

	class UndoInsertDelete : Undo {
		private size_t[] _indices;
		private string[] _values;
		this (in size_t[] indices, bool insert) { mixin(S_TRACE);
			foreach (index; indices) { mixin(S_TRACE);
				_indices ~= index;
				if (!insert) _values ~= _valueCache[index];
			}
		}
		private void impl() { mixin(S_TRACE);
			if (_tte.isEditing) _tte.cancel();
			this.outer._values.setRedraw(false);
			scope (exit) this.outer._values.setRedraw(true);

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
		warning = ws;
	}

	void changeStepCount(bool store, int num) { mixin(S_TRACE);
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
						return name != lastValue;
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
		itm.setText(column, newText);
		_valueCache[index] = newText;
		if (_initInit) { mixin(S_TRACE);
			_init.setItem(index, newText);
		} else if (index == _initSelected) { mixin(S_TRACE);
			_init.setItem(0, newText);
		}
		applyEnabled();
	}

	void delStep(cwx.flag.Flag[] flag, Step[] step) { mixin(S_TRACE);
		foreach (s; step) { mixin(S_TRACE);
			if (s is _step) { mixin(S_TRACE);
				forceCancel();
				return;
			}
		}
		updateToolTip();
	}
	void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps) { updateToolTip(); }
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
			VarValue fValue(string path) { mixin(S_TRACE);
				auto flag = _summ.flagDirRoot.findFlag(path);
				return flag ? VarValue(true, flag.onOff ? flag.on : flag.off, flag.expandSPChars) : VarValue(false);
			}
			VarValue[string] sysSteps;
			.getPreviewSysSteps(_comm.prop, _summ, sysSteps);
			VarValue sValue(string path) { mixin(S_TRACE);
				auto step = _summ.flagDirRoot.findStep(path);
				if (step && _step is step) { mixin(S_TRACE);
					if (_initSelected == _editIndex && _valueEditor && !_valueEditor.isDisposed()) { mixin(S_TRACE);
						return VarValue(true, _valueEditor.getText(), _expandSPChars.getSelection());
					}
					return VarValue(true, _valueCache[_initSelected], _expandSPChars.getSelection());
				} else { mixin(S_TRACE);
					return step ? VarValue(true, step.value, step.expandSPChars) : sysSteps.get(path.toLower(), VarValue(false));
				}
			}
			string getName(char name) { mixin(S_TRACE);
				return .getSPCharPreviewValue(_comm, name);
			}
			bool hasMaterial(string path) { mixin(S_TRACE);
				if (_summ.legacy) { mixin(S_TRACE);
					auto c = .decodeFontPath(path);
					if (!isSJIS1ByteChar(c)) return false;
				}
				return _comm.skin.findImagePath(path, _summ.scenarioPath, _summ.dataVersion).length != 0 || .decodeFontPath(path) in _comm.skin.spChars;
			}
			string[size_t] rFonts;
			char[size_t] rColors;
			toolTip = .formatMsg(text, &fValue, &sValue, &getName, ver => _comm.prop.isTargetVersion(_summ, ver),
				_comm.prop.sys.prefixSystemVarName, &hasMaterial, rFonts, rColors);
		}
		return toolTip.replace("&", "&&");
	}
	void refScenario(Summary summ) { mixin(S_TRACE);
		if (_summ is summ) forceCancel();
	}
	void refDataVersion() { mixin(S_TRACE);
		_stepCount.setEnabled(!_summ.legacy || _stepCount.getSelection() != _comm.prop.looks.stepMaxCount);
		_expandSPChars.setEnabled(!_summ.legacy || _expandSPChars.getSelection());
		updateToolTip();
		refreshWarning();
	}
public:
	/// Params:
	/// dir = 設定するステップの親ディレクトリ。
	/// step = 設定するステップ。新規の場合はnull。
	this (Commons comm, Summary summ, Shell shell, FlagDir dir, Step step = null) { mixin(S_TRACE);
		super(comm.prop, shell, false, comm.prop.msgs.dlgTitStep, comm.prop.images.step, true, comm.prop.var.stepDlg, true);		auto o = this;
		_comm = comm;
		_summ = summ;
		_dir = dir;
		_step = step;
		_undo = new UndoManager(_comm.prop.var.etc.undoMaxEtc);
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
		area.setLayout(normalGridLayout(1, true));
		{ mixin(S_TRACE);
			auto top = new SplitPane(area, SWT.HORIZONTAL);
			top.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			.setupWeights(top, _comm.prop.var.etc.stepTopSashL, _comm.prop.var.etc.stepTopSashR);

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
			l1.setText(_comm.prop.msgs.dlgLblStepName);
			l1.setLayoutData(new GridData);
			setEVS(l1);
			_name = new Text(comp1, SWT.BORDER);
			mod(_name);
			createTextMenu!Text(_comm, _comm.prop, _name, &catchMod);
			setGridMinW(_name, _comm.prop.var.etc.flagNameWidth, GridData.FILL_HORIZONTAL);
			setEVS(_name);
			checker(_name);
			.listener(_name, SWT.Modify, &refreshWarning);

			auto l2 = new Label(comp2, SWT.NONE);
			l2.setText(_comm.prop.msgs.dlgLblStepInit);
			l2.setLayoutData(new GridData);
			setEVS(l2);
			_init = new Combo(comp2, SWT.READ_ONLY);
			mod(_init);
			_init.setVisibleItemCount(_comm.prop.var.etc.comboVisibleItemCount);
			setGridMinW(_init, _comm.prop.var.etc.flagInitWidth, GridData.FILL_HORIZONTAL);
			setEVS(_init);
		}
		{ mixin(S_TRACE);
			_values = new Table(area, SWT.MULTI | SWT.FULL_SELECTION | SWT.BORDER | SWT.VIRTUAL);
			_values.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto valueNumCol = new TableColumn(_values, SWT.NONE);
			auto prop = _comm.prop;
			saveColumnWidth!("prop.var.etc.valueNumberColumn")(_comm.prop, valueNumCol);
			auto nameCol = new FullTableColumn(_values, SWT.NONE);
			.listener(_values, SWT.MouseMove, &updateToolTip);

			auto menu = new Menu(_values.getShell(), SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.Undo, { _undo.undo(); }, &_undo.canUndo);
			createMenuItem(_comm, menu, MenuID.Redo, { _undo.redo(); }, &_undo.canRedo);
/+			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.Up, &upValues, &canUpValues);
			createMenuItem(_comm, menu, MenuID.Down, &downValues, &canDownValues);
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_comm, menu, this, true, true, true, true, true);
+/			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.CreateStepValues, &createStepValues, &canCreateStepValues);
			_values.setMenu(menu);

			Control createEditor(TableItem itm, int editC) { mixin(S_TRACE);
				_valueEditor = createTextEditor(_comm, _comm.prop, _values, itm.getText(editC));
				_editIndex = itm.getParent().indexOf(itm);
				auto menu = _valueEditor.getMenu();
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.CreateStepValues, &createStepValues, &canCreateStepValues);
				updateToolTip();
				.listener(_valueEditor, SWT.Modify, &updateToolTip);
				return _valueEditor;
			}
			_tte = new TableTextEdit(_comm, _comm.prop, _values, 1, &valueEditEnd, (itm, column) => true, &createEditor);
			_tte.quickStart = true;
		}
		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			comp.setLayout(zeroMarginGridLayout(3, false));

			auto l = new Label(comp, SWT.NONE);
			l.setText(_comm.prop.msgs.stepCount);
			_stepCount = new Spinner(comp, SWT.BORDER);
			initSpinner(_stepCount);
			mod(_stepCount);
			_stepCount.setMinimum(1);
			_stepCount.setMaximum(_comm.prop.var.etc.stepCountMax);
			.listener(_stepCount, SWT.Selection, () => changeStepCount(true, _stepCount.getSelection()));
			.listener(_stepCount, SWT.Modify, () => changeStepCount(true, _stepCount.getSelection()));

			_expandSPChars = new Button(comp, SWT.CHECK);
			mod(_expandSPChars);
			_expandSPChars.setText(_comm.prop.msgs.expandSPChars);
			_expandSPChars.setToolTipText(_comm.prop.msgs.expandSPCharsHint.replace("&", "&&"));
			.listener(_expandSPChars, SWT.Selection, &refDataVersion);
		}
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

		ignoreMod = true;
		scope (exit) ignoreMod = false;
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
		_expandSPChars.setSelection(_step ? _step.expandSPChars : false);
		refDataVersion();
	}

	@property
	private bool canCreateStepValues() { mixin(S_TRACE);
		auto index = _values.getSelectionIndex();
		return 0 <= index && index + 1 < _values.getItemCount();
	}
	private void createStepValues() { mixin(S_TRACE);
		if (!canCreateStepValues) return;
		auto t = cast(Text)_tte.editor;
		auto index = _values.getSelectionIndex();
		auto lastValue = t ? t.getText() : _values.getItem(index).getText(1);
		createStepValues(index, lastValue);
	}

	private void createStepValues(int index, string lastValue) { mixin(S_TRACE);
		auto stored = false;
		foreach (i; index + 1 .. _values.getItemCount()) { mixin(S_TRACE);
			lastValue = createNewName(lastValue, (string name) { mixin(S_TRACE);
				return name != lastValue;
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

	override bool apply() { mixin(S_TRACE);
		auto vals = _valueCache[0 .. _stepCount.getSelection()];
		if (_step.parent) { mixin(S_TRACE);
			_step.name = this.name;
			_step.setValues(vals, _initSelected);
			_step.expandSPChars = _expandSPChars.getSelection();
		} else { mixin(S_TRACE);
			_step = new Step(this.name, vals, _initSelected);
			_step.expandSPChars = _expandSPChars.getSelection();
			_dir.add(_step);
		}
		_comm.refFlagAndStep.call([], [_step]);
		return true;
	}
}

/// フラグ設定用のダイアログ。
public class FlagEditDialog : AbsDialog {
private:
	Commons _comm;
	Summary _summ;
	Props prop;
	cwx.flag.Flag _flag;
	FlagDir dir;

	Text flagName;
	Combo flagInit;
	Combo flagTrue;
	Combo flagFalse;
	Button _expandSPChars;

	void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (prop.sys.isSystemVar(flagName.getText())) { mixin(S_TRACE);
			ws ~= .tryFormat(prop.msgs.warningSystemVarName, prop.sys.prefixSystemVarName);
		}
		if (_expandSPChars.getSelection() && !_comm.prop.isTargetVersion(_summ, "2")) { mixin(S_TRACE);
			ws ~= _comm.prop.msgs.warningExpandSPChars;
		}
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
	void delFlag(cwx.flag.Flag[] flag, Step[] step) { mixin(S_TRACE);
		foreach (f; flag) { mixin(S_TRACE);
			if (f is _flag) { mixin(S_TRACE);
				forceCancel();
				return;
			}
		}
		updateToolTip();
	}
	void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps) { updateToolTip(); }
	void refPath(string o, string n, bool isDir) { updateToolTip(); }
	void refPaths(string parent) { updateToolTip(); }
	void updateToolTip() { mixin(S_TRACE);
		updateToolTipImpl(flagTrue);
		updateToolTipImpl(flagFalse);
	}
	void updateToolTipImpl(Combo combo) { mixin(S_TRACE);
		auto toolTip = "";
		if (_expandSPChars.getSelection()) { mixin(S_TRACE);
			VarValue fValue(string path) { mixin(S_TRACE);
				auto flag = _summ.flagDirRoot.findFlag(path);
				if (flag && _flag is flag) { mixin(S_TRACE);
					return VarValue(true, flagInit.getText(), _expandSPChars.getSelection());
				} else { mixin(S_TRACE);
					return flag ? VarValue(true, flag.onOff ? flag.on : flag.off, flag.expandSPChars) : VarValue(false);
				}
			}
			VarValue[string] sysSteps;
			.getPreviewSysSteps(_comm.prop, _summ, sysSteps);
			VarValue sValue(string path) { mixin(S_TRACE);
				auto step = _summ.flagDirRoot.findStep(path);
				return step ? VarValue(true, step.value, step.expandSPChars) : sysSteps.get(path.toLower(), VarValue(false));
			}
			string getName(char name) { mixin(S_TRACE);
				return .getSPCharPreviewValue(_comm, name);
			}
			bool hasMaterial(string path) { mixin(S_TRACE);
				if (_summ.legacy) { mixin(S_TRACE);
					auto c = .decodeFontPath(path);
					if (!isSJIS1ByteChar(c)) return false;
				}
				return _comm.skin.findImagePath(path, _summ.scenarioPath, _summ.dataVersion).length != 0 || .decodeFontPath(path) in _comm.skin.spChars;
			}
			string[size_t] rFonts;
			char[size_t] rColors;
			toolTip = .formatMsg(combo.getText(), &fValue, &sValue, &getName, ver => _comm.prop.isTargetVersion(_summ, ver),
				_comm.prop.sys.prefixSystemVarName, &hasMaterial, rFonts, rColors);
		}
		toolTip = toolTip.replace("&", "&&");
		if (toolTip != combo.getToolTipText()) { mixin(S_TRACE);
			combo.setToolTipText(toolTip);
		}
	}
	void refScenario(Summary summ) { mixin(S_TRACE);
		forceCancel();
	}
	void refDataVersion() { mixin(S_TRACE);
		_expandSPChars.setEnabled(!_summ.legacy || _expandSPChars.getSelection());
		updateToolTip();
		refreshWarning();
	}
public:
	/// Params:
	/// prop = 設定情報。
	/// shell = 親ウィンドウ。
	/// dir = 設定するフラグの親ディレクトリ。
	/// flag = 設定するフラグ。新規の場合はnull。
	this(Commons comm, Summary summ, Shell shell, FlagDir dir, cwx.flag.Flag flag = null) { mixin(S_TRACE);
		super(comm.prop, shell, false, comm.prop.msgs.dlgTitFlag, comm.prop.images.flag, true,
			comm.prop.var.flagDlg, true);
		_comm = comm;
		this.prop = comm.prop;
		_summ = summ;
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
		area.setLayout(zeroGridLayout(1));
		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
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
			flagName = new Text(comp1, SWT.BORDER);
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
			flagInit = new Combo(comp2, SWT.READ_ONLY);
			mod(flagInit);
			setGridMinW(flagInit, prop.var.etc.flagInitWidth, GridData.FILL_HORIZONTAL);
			setEVS(flagInit);
		}
		(new Label(area, SWT.SEPARATOR | SWT.HORIZONTAL))
			.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		{ mixin(S_TRACE);
			auto ocomp = new Composite(area, SWT.NONE);
			ocomp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
			cl.fillHorizontal = true;
			ocomp.setLayout(cl);
			auto comp = new Composite(ocomp, SWT.NONE);
			comp.setLayout(normalGridLayout(2, false));

			(new Label(comp, SWT.NULL)).setText(prop.msgs.dlgLblFlagTrue);
			flagTrue = new Combo(comp, SWT.NULL);
			mod(flagTrue);
			setComboItems(flagTrue, prop.var.etc.flagTrues.dup);
			flagTrue.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			createTextMenu!Combo(_comm, prop, flagTrue, &catchMod);
			auto tmod = new ModOnOff(0);
			flagTrue.addModifyListener(tmod);
			flagTrue.addSelectionListener(tmod);
			setGridMinW(flagTrue, prop.var.etc.flagValueWidth, GridData.FILL_HORIZONTAL);

			(new Label(comp, SWT.NULL)).setText(prop.msgs.dlgLblFlagFalse);
			flagFalse = new Combo(comp, SWT.NULL);
			mod(flagFalse);
			setComboItems(flagFalse, prop.var.etc.flagFalses.dup);
			flagFalse.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			createTextMenu!Combo(_comm, prop, flagFalse, &catchMod);
			auto fmod = new ModOnOff(1);
			flagFalse.addModifyListener(fmod);
			flagFalse.addSelectionListener(fmod);
			setGridMinW(flagFalse, prop.var.etc.flagValueWidth, GridData.FILL_HORIZONTAL);
		}
		(new Label(area, SWT.SEPARATOR | SWT.HORIZONTAL))
			.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		{ mixin(S_TRACE);
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL | GridData.HORIZONTAL_ALIGN_END));
			comp.setLayout(normalGridLayout(1, true));
			_expandSPChars = new Button(comp, SWT.CHECK);
			mod(_expandSPChars);
			_expandSPChars.setText(_comm.prop.msgs.expandSPChars);
			_expandSPChars.setToolTipText(_comm.prop.msgs.expandSPCharsHint.replace("&", "&&"));
			.listener(_expandSPChars, SWT.Selection, &refDataVersion);
			.listener(_expandSPChars, SWT.Selection, &updateToolTip);
		}
		_comm.delFlagAndStep.add(&delFlag);
		_comm.refScenario.add(&refScenario);
		_comm.refDataVersion.add(&refDataVersion);
		_comm.refPreviewValues.add(&updateToolTip);
		_comm.refFlagAndStep.add(&refFlagAndStep);
		_comm.refPath.add(&refPath);
		_comm.refPaths.add(&refPaths);
		_comm.replText.add(&updateToolTip);
		getShell().addDisposeListener(new Dispose);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (_flag !is null) { mixin(S_TRACE);
			flagName.setText(_flag.name);
			flagTrue.setText(_flag.on);
			if (-1 == flagTrue.indexOf(_flag.on)) flagTrue.add(_flag.on, 0);
			flagFalse.setText(_flag.off);
			if (-1 == flagFalse.indexOf(_flag.off)) flagFalse.add(_flag.off, 0);
			setComboItems(flagInit, [flagTrue.getText(), flagFalse.getText()]);
			flagInit.select(_flag.onOff ? 0 : 1);
			_expandSPChars.setSelection(_flag.expandSPChars);
		} else { mixin(S_TRACE);
			flagName.setText("");
			flagTrue.setText(prop.var.etc.flagTrues.length > 0 ? prop.var.etc.flagTrues[0] : "");
			flagFalse.setText(prop.var.etc.flagFalses.length > 0 ? prop.var.etc.flagFalses[0] : "");
			setComboItems(flagInit, [flagTrue.getText(), flagFalse.getText()]);
			flagInit.select(0);
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
			_flag.expandSPChars = _expandSPChars.getSelection();
		} else { mixin(S_TRACE);
			_flag = new cwx.flag.Flag(this.name, flagTrue.getText(), flagFalse.getText(),
				flagInit.getSelectionIndex() == 0);
			_flag.expandSPChars = _expandSPChars.getSelection();
			dir.add(_flag);
		}
		_comm.refFlagAndStep.call([_flag], []);
		return true;
	}
}

private abstract class FTVUndo : Undo {
	protected FlagTable _v;
	protected Commons comm;
	protected string _dir;
	private string _selectedDir;
	private ptrdiff_t[] _selectedF;
	private ptrdiff_t[] _selectedS;
	private ptrdiff_t[] _selectedFB;
	private ptrdiff_t[] _selectedSB;
	protected FlagDir selDir = null;
	this (FlagTable v, Commons comm, FlagDir dir) { mixin(S_TRACE);
		_v = v;
		_dir = dir.cwxPath(true);
		this.comm = comm;
		saveSelected(v);
	}
	this (FlagTable v, Commons comm, FlagDir dir, ptrdiff_t[] selectedF, ptrdiff_t[] selectedS) { mixin(S_TRACE);
		_v = v;
		_dir = dir.cwxPath(true);
		this.comm = comm;
		_selectedF = selectedF;
		_selectedS = selectedS;
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
		} else { mixin(S_TRACE);
			_selectedF.length = 0;
			_selectedS.length = 0;
		}
	}
	void udb(FlagTable v) { mixin(S_TRACE);
		_selectedFB = _selectedF.dup;
		_selectedSB = _selectedS.dup;
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
	this (FlagTable v, Commons comm, FlagDir dir, FlagDir root) { mixin(S_TRACE);
		super (v, comm, dir);
		_root = root;
		_copyRoot = new FlagDir(root);
	}
	private void impl() { mixin(S_TRACE);
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		auto copy = _copyRoot;
		_copyRoot = new FlagDir(_root);

		_root.removeAll();
		foreach (f; copy.flags) _root.add(f);
		foreach (f; copy.steps) _root.add(f);
		foreach (f; copy.subDirs) _root.add(f);
		comm.refFlagAndStep.call(_root.allFlags, _root.allSteps);
		comm.openFlagWin(false).dirs.refresh();
	}
	override void undo() {impl();}
	override void redo() {impl();}
	override void dispose() {}
}
package class UndoEditN {
	private CWXPath _f;
	private ptrdiff_t _index;
	this (FlagDir dir, int index, string oldName, int value, string[] names) { mixin(S_TRACE);
		auto p = FlagTable.fromIndex(dir, index);
		auto f = cast(cwx.flag.Flag)p;
		if (f) { mixin(S_TRACE);
			auto flag = new cwx.flag.Flag(f);
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
			_index = s.parent.indexOf(s);
			step.name = oldName;
			if (-1 != value) step.select = value;
			if (names.length) { mixin(S_TRACE);
				step.setValues(names, step.select);
			}
			_f = step;
		}
	}
	CWXPath impl(Commons comm, FlagDir dir, out string newName) { mixin(S_TRACE);
		assert (dir);
		auto fB = _f;
		if (cast(cwx.flag.Flag)fB) { mixin(S_TRACE);
			auto f = dir.flags[_index];
			_f = new cwx.flag.Flag(f);
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
		} else { mixin(S_TRACE);
			assert (cast(Step)fB);
			auto s = dir.steps[_index];
			_f = new Step(s);
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
		}
		return null;
	}
}
package class UndoEdit : FTVUndo {
	private UndoEditN[] _impl;
	this (FlagTable v, Commons comm, FlagDir dir, int[] index, string[] oldName, int[] oldValues, string[][] oldNames) in { mixin(S_TRACE);
		assert (index.length == oldName.length);
		assert (!oldValues.length || oldValues.length == index.length);
	} body { mixin(S_TRACE);
		super (v, comm, dir);
		foreach (i, idx; index) { mixin(S_TRACE);
			_impl ~= new UndoEditN(dir, idx, oldName[i], oldValues.length ? oldValues[i] : -1, oldNames.length ? oldNames[i] : []);
		}
	}
	private void impl() { mixin(S_TRACE);
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		auto dir = this.dir();
		cwx.flag.Flag[] refF;
		Step[] refS;
		string[] newNameF;
		string[] newNameS;
		foreach (impl; _impl) { mixin(S_TRACE);
			string newName;
			auto refVal = impl.impl(comm, dir, newName);
			if (cast(cwx.flag.Flag)refVal) { mixin(S_TRACE);
				refF ~= cast(cwx.flag.Flag)refVal;
				newNameF ~= newName;
			} else if (cast(Step)refVal) { mixin(S_TRACE);
				refS ~= cast(Step)refVal;
				newNameS ~= newName;
			}
		}
		FlagTable.setNames(refF, newNameF, comm.summary.useCounter);
		FlagTable.setNames(refS, newNameS, comm.summary.useCounter);
		comm.refFlagAndStep.call(refF, refS);
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			v.refresh();
		}
	}
	override void undo() {impl();}
	override void redo() {impl();}
	override void dispose() {}
}
package class UndoInsertDelete : FTVUndo {
	private bool _insert;

	/// insert
	private ptrdiff_t[] _dirIndices;
	private ptrdiff_t[] _flagIndices;
	private ptrdiff_t[] _stepIndices;
	/// delete
	private FlagDir[ptrdiff_t] _ds;
	private cwx.flag.Flag[ptrdiff_t] _fs;
	private Step[ptrdiff_t] _ss;

	/// 追加を元に戻す。
	this (FlagTable v, Commons comm, FlagDir dir, ptrdiff_t[] selectedF, ptrdiff_t[] selectedS, ptrdiff_t[] dirIndices, ptrdiff_t[] flagIndices, ptrdiff_t[] stepIndices) { mixin(S_TRACE);
		super (v, comm, dir, selectedF.dup, selectedS.dup);
		_dirIndices = dirIndices.dup;
		_flagIndices = flagIndices.dup;
		_stepIndices = stepIndices.dup;
		_insert = true;
	}
	/// 削除を元に戻す。
	this (FlagTable v, Commons comm, FlagDir dir, ptrdiff_t[] selectedF, ptrdiff_t[] selectedS, FlagDir[ptrdiff_t] ds, cwx.flag.Flag[ptrdiff_t] fs, Step[ptrdiff_t] ss) { mixin(S_TRACE);
		super (v, comm, dir, selectedF.dup, selectedS.dup);
		save(ds, fs, ss);
		_insert = false;
	}
	private void save(FlagDir[ptrdiff_t] ds, cwx.flag.Flag[ptrdiff_t] fs, Step[ptrdiff_t] ss) { mixin(S_TRACE);
		_ds = null;
		foreach (index, d; ds) { mixin(S_TRACE);
			_ds[index] = new FlagDir(d);
		}
		_fs = null;
		foreach (index, f; fs) { mixin(S_TRACE);
			_fs[index] = new cwx.flag.Flag(f);
		}
		_ss = null;
		foreach (index, s; ss) { mixin(S_TRACE);
			_ss[index] = new Step(s);
		}
	}
	private void undoInsert(FlagTable v) { mixin(S_TRACE);
		cwx.flag.Flag[] rfs;
		Step[] rss;
		FlagDir[] rds;
		undoInsertImpl(rfs, rss, rds);
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			v.refresh();
		}
		if (rds.length) comm.delFlagDir.call(rds);
		if (rfs.length || rss.length) { mixin(S_TRACE);
			comm.delFlagAndStep.call(rfs, rss);
		}
	}
	private void undoInsertImpl(ref cwx.flag.Flag[] rfs, ref Step[] rss, ref FlagDir[] rds) { mixin(S_TRACE);
		_insert = false;
		FlagDir[ptrdiff_t] ds;
		cwx.flag.Flag[ptrdiff_t] fs;
		Step[ptrdiff_t] ss;
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
		save(ds, fs, ss);
		foreach (f; fs) { mixin(S_TRACE);
			dir.remove(f);
		}
		foreach (s; ss) { mixin(S_TRACE);
			dir.remove(s);
		}
		foreach (d; ds) { mixin(S_TRACE);
			dir.remove(d);
			rfs ~= d.allFlags;
			rss ~= d.allSteps;
			rds ~= d.allSubDirs;
		}
		rds ~= ds.values;
		rfs ~= fs.values;
		rss ~= ss.values;
	}
	private void undoDelete(FlagTable v) { mixin(S_TRACE);
		cwx.flag.Flag[] rfs;
		Step[] rss;
		FlagDir[] rds;
		undoDeleteImpl(rfs, rss, rds);
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			v.refresh();
		}
		if (rds.length) comm.delFlagDir.call(rds);
		if (rfs.length || rss.length) { mixin(S_TRACE);
			comm.delFlagAndStep.call(rfs, rss);
		}
	}
	private void undoDeleteImpl(ref cwx.flag.Flag[] rfs, ref Step[] rss, ref FlagDir[] rds) { mixin(S_TRACE);
		_insert = true;
		auto dir = this.dir();
		_dirIndices.length = 0;
		_flagIndices.length = 0;
		_stepIndices.length = 0;
		selDir = (_ds.length == 1 && !_fs.length && !_ss.length) ? _ds.values[0] : null;
		foreach (index; std.algorithm.sort(_fs.keys)) { mixin(S_TRACE);
			auto f = _fs[index];
			_flagIndices ~= index;
			dir.insert(index, f, true);
		}
		foreach (index; std.algorithm.sort(_ss.keys)) { mixin(S_TRACE);
			auto s = _ss[index];
			_stepIndices ~= index;
			dir.insert(index, s, true);
		}
		foreach (index; std.algorithm.sort(_ds.keys)) { mixin(S_TRACE);
			auto d = _ds[index];
			_dirIndices ~= index;
			dir.insert(index, d, true);
			rfs ~= d.allFlags;
			rss ~= d.allSteps;
			rds ~= d.allSubDirs;
		}
		rds ~= _ds.values;
		rfs ~= _fs.values;
		rss ~= _ss.values;
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

	this (FlagTable v, Commons comm, ptrdiff_t[] selectedF, ptrdiff_t[] selectedS, FlagDir to, ptrdiff_t[] dirIndices, ptrdiff_t[] flagIndices, ptrdiff_t[] stepIndices, FlagDir from, FlagDir[ptrdiff_t] ds, cwx.flag.Flag[ptrdiff_t] fs, Step[ptrdiff_t] ss) { mixin(S_TRACE);
		super (v, comm, from, selectedF.dup, selectedS.dup);
		assert (dirIndices.length == ds.length);
		assert (flagIndices.length == fs.length);
		assert (stepIndices.length == ss.length);
		_dir1 = new UndoInsertDelete(v, comm, to, selectedF, selectedS, dirIndices, flagIndices, stepIndices);
		_dir2 = new UndoInsertDelete(v, comm, from, selectedF, selectedS, ds, fs, ss);
	}
	private void paths(UndoInsertDelete ins, FlagDir dir, out FlagId[] flagIDs, out StepId[] stepIDs, out cwx.flag.Flag[] flags, out Step[] steps) { mixin(S_TRACE);
		assert (dir !is null);
		foreach (i; std.algorithm.sort(ins._dirIndices.dup)) { mixin(S_TRACE);
			foreach (f; dir.subDirs[i].allFlags) flags ~= f;
			foreach (f; dir.subDirs[i].allSteps) steps ~= f;
		}
		foreach (i; std.algorithm.sort(ins._flagIndices.dup)) { mixin(S_TRACE);
			flags ~= dir.flags[i];
		}
		foreach (i; std.algorithm.sort(ins._stepIndices.dup)) { mixin(S_TRACE);
			steps ~= dir.steps[i];
		}
		foreach (f; flags) flagIDs ~= toFlagId(f.path);
		foreach (f; steps) stepIDs ~= toStepId(f.path);
	}
	private void change(FlagTable v, FlagId[] oldF, FlagId[] newF, StepId[] oldS, StepId[] newS) { mixin(S_TRACE);
		foreach (nPath, oPath; .zip(newF, oldF)) { mixin(S_TRACE);
			comm.summary.useCounter.change(oPath, nPath);
		}
		foreach (nPath, oPath; .zip(newS, oldS)) { mixin(S_TRACE);
			comm.summary.useCounter.change(oPath, nPath);
		}
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			v.refresh();
			v.refreshUseCount();
		}
	}
	private void impl(UndoInsertDelete del, UndoInsertDelete ins) { mixin(S_TRACE);
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		FlagId[] oldF, newF;
		StepId[] oldS, newS;
		cwx.flag.Flag[] flags;
		Step[] steps;
		auto delDir = del.dir();
		auto insDir = ins.dir();
		paths(del, del.dir(), oldF, oldS, flags, steps);
		cwx.flag.Flag[] rfs;
		Step[] rss;
		FlagDir[] rds;
		del.undoInsertImpl(rfs, rss, rds);
		ins.undoDeleteImpl(rfs, rss, rds);
		paths(ins, ins.dir(), newF, newS, flags, steps);
		change(v, oldF, newF, oldS, newS);

		bool[cwx.flag.Flag] fSet;
		bool[Step] sSet;
		bool[FlagDir] dSet;
		foreach (f; rfs) fSet[f] = true;
		foreach (f; rss) sSet[f] = true;
		foreach (f; rds) dSet[f] = true;
		if (rds.length) comm.delFlagDir.call(dSet.keys);
		if (rfs.length || rss.length) { mixin(S_TRACE);
			comm.delFlagAndStep.call(fSet.keys, sSet.keys);
		}
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
	this (FlagTable v, Commons comm, FlagDir dir, string oldName) { mixin(S_TRACE);
		super (v, comm, dir);
		_oldName = oldName;
	}
	private void impl() { mixin(S_TRACE);
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		auto dir = this.dir();
		assert (dir !is null);

		string oldName = dir.name;
		dir.rename(_oldName, comm.summary.useCounter);
		_oldName = oldName;

		comm.refFlagDir.call([dir]);
	}
	override void undo() { impl(); }
	override void redo() { impl(); }
	override void dispose() {}
}

public class FlagTable : TCPD {
private:
	void storeEdit(int[] index, string[] oldName, int[] oldValues = [], string[][] oldNames = []) { mixin(S_TRACE);
		_undo ~= new UndoEdit(this, _comm, _dir, index, oldName, oldValues, oldNames);
	}
	void storeEdit(int index, string oldName, int oldValue, string[] oldNames = []) { mixin(S_TRACE);
		_undo ~= new UndoEdit(this, _comm, _dir, [index], [oldName], [oldValue], [oldNames]);
	}
	void storeInsert(ptrdiff_t[] selectedF, ptrdiff_t[] selectedS, ptrdiff_t[] flagIndices, ptrdiff_t[] stepIndices) { mixin(S_TRACE);
		_undo ~= new UndoInsertDelete(this, _comm, _dir, selectedF, selectedS, [], flagIndices, stepIndices);
	}
	void storeDelete(ptrdiff_t[] selectedF, ptrdiff_t[] selectedS, cwx.flag.Flag[ptrdiff_t] fs, Step[ptrdiff_t] ss) { mixin(S_TRACE);
		_undo ~= new UndoInsertDelete(this, _comm, _dir, selectedF, selectedS, null, fs, ss);
	}

	static int indexOf(FlagDir dir, CWXPath p) { mixin(S_TRACE);
		int i = 0;
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
		if (dir.steps.length <= index) { mixin(S_TRACE);
			return dir.flags[index - dir.steps.length];
		}
		return dir.steps[index];
	}
	static int toFlagIndex(FlagDir dir, int index) { mixin(S_TRACE);
		return index - cast(int)dir.steps.length;
	}
	static int toStepIndex(FlagDir dir, int index) { mixin(S_TRACE);
		return index;
	}

	static const NAME = 0;
	static const VALUE = 1;
	static const UC = 2;
	void refreshFlags() { mixin(S_TRACE);
		if (_dir) { mixin(S_TRACE);
			int i = 0;
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

	Table flags;

	FlagDir _dir = null;
	string _statusLine = "";

	FlagEditDialog[cwx.flag.Flag] _editDlgsF;
	StepEditDialog[Step] _editDlgsS;

	IncSearch _incSearch = null;
	private void incSearch() { mixin(S_TRACE);
		.forceFocus(flags, true);
		_incSearch.startIncSearch();
	}

	UndoManager _undo;
	TableTextEdit _tte;
	TableComboEdit!Combo _tce;

	void editFlag(FlagDir parent, cwx.flag.Flag flag) { mixin(S_TRACE);
		enterEdit();
		bool createMode = flag is null;
		string old = createMode ? null : flag.name;
		if (!flag) { mixin(S_TRACE);
			string on = prop.var.etc.flagTrues.length > 0 ? prop.var.etc.flagTrues[0] : "";
			string off = prop.var.etc.flagFalses.length > 0 ? prop.var.etc.flagFalses[0] : "";
			flag = new cwx.flag.Flag("", on, off, prop.var.etc.flagInitValue);
		}
		auto p = flag in _editDlgsF;
		if (p) { mixin(S_TRACE);
			p.active();
			return;
		}
		auto dlg = new FlagEditDialog(_comm, _comm.summary, dlgParShl, parent, flag);
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
				if (flags && !flags.isDisposed()) { mixin(S_TRACE);
					selsF = selectionFlagIndices;
					selsS = selectionStepIndices;
				}
				storeInsert(selsF, selsS, [flag.parent.indexOf(flag)], []);
				createMode = false;
			} else { mixin(S_TRACE);
				storeEdit(indexOf(parent, flag), oldName, oldValue, oldNames);
			}
			_comm.openCWXPath(flag.cwxPath(true), false);
			refresh([flag]);
			_comm.refFlagAndStep.call([flag], []);
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
		}
		auto p = step in _editDlgsS;
		if (p) { mixin(S_TRACE);
			p.active();
			return;
		}
		auto dlg = new StepEditDialog(_comm, _comm.summary, dlgParShl, parent, step);
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
				if (flags && !flags.isDisposed()) { mixin(S_TRACE);
					selsF = selectionFlagIndices;
					selsS = selectionStepIndices;
				}
				storeInsert(selsF, selsS, [], [step.parent.indexOf(step)]);
				createMode = false;
			} else { mixin(S_TRACE);
				storeEdit(indexOf(parent, step), oldName, oldValue, oldNames);
			}
			_comm.openCWXPath(step.cwxPath(true), false);
			refresh([step]);
			_comm.refFlagAndStep.call([], [step]);
			_comm.refreshToolBar();
		};
		_editDlgsS[step] = dlg;
		dlg.closeEvent ~= { mixin(S_TRACE);
			_editDlgsS.remove(step);
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
	bool getSelectionFlagAndStep(out cwx.flag.Flag[] fs, out Step[] ss) { mixin(S_TRACE);
		auto indices = flags.getSelectionIndices();
		if (indices.length > 0) { mixin(S_TRACE);
			foreach (i; indices) { mixin(S_TRACE);
				auto itm = flags.getItem(i);
				if (auto s = cast(Step)itm.getData()) { mixin(S_TRACE);
					ss ~= s;
				} else if (auto f = cast(cwx.flag.Flag)itm.getData()) { mixin(S_TRACE);
					fs ~= f;
				} else assert (0);
			}
			return true;
		} else { mixin(S_TRACE);
			return false;
		}
	}
	void getSelectionFlagAndStepWithIndex(out cwx.flag.Flag[ptrdiff_t] fs, out Step[ptrdiff_t] ss) { mixin(S_TRACE);
		cwx.flag.Flag[] fsi;
		Step[] ssi;
		getSelectionFlagAndStep(fsi, ssi);
		foreach (f; fsi) fs[f.parent.indexOf(f)] = f;
		foreach (f; ssi) ss[f.parent.indexOf(f)] = f;
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

	cwx.flag.Flag[ptrdiff_t] _dragFlags;
	Step[ptrdiff_t] _dragSteps;
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
				getSelectionFlagAndStepWithIndex(_dragFlags, _dragSteps);
				XNode node;
				getNode(_dir, _dragFlags.values, _dragSteps.values, node);
				node.newAttr("paneId", _id);
				e.data = bytesFromXML(node.text);
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			if (e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
				foreach (flag; _dragFlags) { mixin(S_TRACE);
					flag.parent.remove(flag);
				}
				foreach (step; _dragSteps) { mixin(S_TRACE);
					step.parent.remove(step);
				}
				refresh();
				_comm.delFlagAndStep.call(_dragFlags.values, _dragSteps.values);
				_comm.refreshToolBar();
			}
			_dragFlags = null;
			_dragSteps = null;
		}
	}
	class FlagDrop : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = DND.DROP_COPY;
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = DND.DROP_COPY;
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
			} catch (Exception e) { mixin (S_TRACE);
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
		int[] indices;
		string[] oldNames;
		string[] oldNamesF;
		string[] oldNamesS;
		FlagId[] oldFID;
		StepId[] oldSID;
		foreach (itm; itms) { mixin(S_TRACE);
			auto f = cast(cwx.flag.Flag)itm.getData();
			if (f) { mixin(S_TRACE);
				indices ~= indexOf(f.parent, f);
				oldNamesF ~= f.name;
				oldNames ~= f.name;
				refF ~= f;
				oldFID ~= toFlagId(f.path);
			}
			auto s = cast(Step)itm.getData();
			if (s) { mixin(S_TRACE);
				indices ~= indexOf(s.parent, s);
				oldNamesS ~= s.name;
				oldNames ~= s.name;
				refS ~= s;
				oldSID ~= toStepId(s.path);
			}
		}
		if (indices.length) { mixin(S_TRACE);
			auto newNamesF = _dir.createNewFlagNames(text, refF.length, oldNamesF);
			auto newNamesS = _dir.createNewStepNames(text, refS.length, oldNamesS);
			bool changed = oldNamesF != newNamesF || oldNamesS != newNamesS;
			if (oldNamesF != newNamesF) setNames(refF, newNamesF, uc);
			if (oldNamesS != newNamesS) setNames(refS, newNamesS, uc);
			if (changed) { mixin(S_TRACE);
				storeEdit(indices, oldNames);
				refresh();
				_comm.refFlagAndStep.call(refF, refS);
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
	void initCombo(TableItem itm, int column, out string[] strs, out string str) { mixin(S_TRACE);
		auto f = cast(cwx.flag.Flag) itm.getData();
		if (f) { mixin(S_TRACE);
			strs = [f.on, f.off];
			str = f.onOff ? f.on : f.off;
			return;
		}
		auto s = cast(Step) itm.getData();
		if (s) { mixin(S_TRACE);
			foreach (i, v; s.values) { mixin(S_TRACE);
				strs ~= v;
				if (i == s.select) { mixin(S_TRACE);
					str = v;
				}
			}
			return;
		}
	}
	void initEditEnd(TableItem selItm, int column, Combo combo) { mixin(S_TRACE);
		int i = combo.getSelectionIndex();
		if (-1 == i) return;
		auto selFlag = cast(cwx.flag.Flag)selItm.getData();
		auto selStep = cast(Step)selItm.getData();
		auto itms = flags.getSelection();
		itms = itms.remove(selItm);
		itms.insertInPlace(0, selItm);
		cwx.flag.Flag[] refF;
		Step[] refS;
		int[] indices;
		string[] oldNames;
		int[] oldValues;
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
		}
		if (indices.length) { mixin(S_TRACE);
			storeEdit(indices, oldNames, oldValues);
			_comm.refFlagAndStep.call(refF, refS);
		}
		_comm.refreshToolBar();
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			foreach (dlg; _editDlgsF.values) { mixin(S_TRACE);
				dlg.forceCancel();
			}
			foreach (dlg; _editDlgsS.values) { mixin(S_TRACE);
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
		getSelectionFlagAndStep(fs, ss);
		auto c = createInitVariablesTree(fs, ss);
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
	this (Commons comm, Props prop, UndoManager undo) { mixin(S_TRACE);
		auto o = this;
		_id = format("%08X", &o) ~ "-" ~ to!(string)(Clock.currTime());

		_undo = undo;
		_comm = comm;
		this.prop = prop;
	}

	/// コントロールを生成する。
	/// Params:
	/// parent = 親コントロール。
	Control createControl(Composite parent, Composite incSearchParent, void delegate() gotFocus) { mixin(S_TRACE);
		_comp = new Composite(parent, SWT.NONE);
		_comp.setLayout(new FillLayout);
		flags = .rangeSelectableTable(_comp, SWT.MULTI | SWT.BORDER | SWT.FULL_SELECTION);
		flags.setHeaderVisible(true);
		.listener(flags, SWT.FocusIn, gotFocus);
		auto nameCol = new TableColumn(flags, SWT.NULL);
		nameCol.setText(prop.msgs.flagName);
		saveColumnWidth!("prop.var.etc.flagNameColumn")(prop, nameCol);
		auto initCol = new TableColumn(flags, SWT.NULL);
		initCol.setText(prop.msgs.flagInit);
		saveColumnWidth!("prop.var.etc.flagInitColumn")(prop, initCol);
		auto countCol = new TableColumn(flags, SWT.NULL);
		countCol.setText(prop.msgs.flagCount);
		saveColumnWidth!("prop.var.etc.flagCountColumn")(prop, countCol);

		updateIncSearchParent(incSearchParent);

		flags.addKeyListener(new KListener);
		flags.addMouseListener(new MListener);
		auto menu = new Menu(flags.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &incSearch, null);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.EditProp, &edit, &canEdit);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.NewFlag, &createFlag, () => _dir !is null);
		createMenuItem(_comm, menu, MenuID.NewStep, &createStep, () => _dir !is null);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.Undo, &this.undo, &_undo.canUndo);
		createMenuItem(_comm, menu, MenuID.Redo, &this.redo, &_undo.canRedo);
		new MenuItem(menu, SWT.SEPARATOR);
		appendMenuTCPD(_comm, menu, this, true, true, true, true, true);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.SelectAll, &selectAll, () => flags.getItemCount() && flags.getSelectionCount() != flags.getItemCount());
		new MenuItem(menu, SWT.SEPARATOR);

		void delegate() dlg = null;
		auto evt = createMenuItem(_comm, menu, MenuID.CreateVariableEventTree, dlg, () => 0 < flags.getSelectionCount(), SWT.CASCADE);
		auto mEvt = new Menu(parent.getShell(), SWT.DROP_DOWN);
		evt.setMenu(mEvt);
		createMenuItem(_comm, mEvt, MenuID.InitVariablesTree, &copyInitTree, () => 0 < flags.getSelectionCount());
		new MenuItem(mEvt, SWT.SEPARATOR);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.contentName(CType.REVERSE_FLAG), "R", "", false), prop.images.content(CType.REVERSE_FLAG), &copyFlagReverseTree, () => 0 < selectionFlags.length);
		new MenuItem(mEvt, SWT.SEPARATOR);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.setFlagTrue, "T", "", false), prop.images.content(CType.SET_FLAG), () => copyFlagTree(true), () => 0 < selectionFlags.length);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.setFlagFalse, "F", "", false), prop.images.content(CType.SET_FLAG), () => copyFlagTree(false), () => 0 < selectionFlags.length);
		new MenuItem(mEvt, SWT.SEPARATOR);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.contentName(CType.SET_STEP_UP), "U", "", false), prop.images.content(CType.SET_STEP_UP), &copyStepUpTree, () => 0 < selectionSteps.length);
		createMenuItem2(_comm, mEvt, MenuProps.buildMenu(prop.msgs.contentName(CType.SET_STEP_DOWN), "D", "", false), prop.images.content(CType.SET_STEP_DOWN), &copyStepDownTree, () => 0 < selectionSteps.length);
		new MenuItem(mEvt, SWT.SEPARATOR);
		void ssValue(uint i) { mixin(S_TRACE);
			string mnemonic = i < 10 ? .text(i) : "";
			createMenuItem2(_comm, mEvt, MenuProps.buildMenu(.tryFormat(prop.msgs.setStepValue, .parseDollarParams(prop.var.etc.stepValueName, ['N':.to!string(i)])), mnemonic, "", false), prop.images.content(CType.SET_STEP), () => copyStepTree(i), () => 0 < selectionSteps.length);
		}
		foreach (i; 0..prop.looks.stepMaxCount) { mixin(S_TRACE);
			ssValue(i);
		}

		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.FindID, &replaceID, &canReplaceID);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.CopyVariablePath, &copyVariablePath, &canCopyVariablePath);
		flags.setMenu(menu);

		auto ds = new DragSource(flags, DND.DROP_MOVE | DND.DROP_COPY);
		ds.setTransfer([XMLBytesTransfer.getInstance()]);
		ds.addDragListener(new FlagDragListener);
		auto dt = new DropTarget(flags, DND.DROP_COPY);
		dt.setTransfer([XMLBytesTransfer.getInstance()]);
		dt.addDropListener(new FlagDrop);

		_comm.refUseCount.add(&refreshUseCount);
		_comm.replText.add(&refresh);
		flags.addSelectionListener(new SListener);
		flags.addDisposeListener(new DListener);

		_tte = new TableTextEdit(_comm, prop, flags, 0, &nameEditEnd, null);
		_tce = new TableComboEdit!Combo(_comm, prop, flags, 1, &initCombo, &initEditEnd, null);

		_comp.addDisposeListener(new Dispose);

		return _comp;
	}
	void updateIncSearchParent(Composite incSearchParent) {
		auto matchers = [
			AdditionMatcher(MenuProps.buildMenu(.objName!Step(prop), "S", "", false), (o) => cast(Step)o !is null),
			AdditionMatcher(MenuProps.buildMenu(.objName!(cwx.flag.Flag)(prop), "F", "", false), (o) => cast(cwx.flag.Flag)o !is null),
		];
		_incSearch = new IncSearch(_comm, incSearchParent, matchers);
		_incSearch.modEvent ~= &refresh;
	}
	private Composite _comp = null;
	@property
	Control widget() { return _comp; }

	@property
	package cwx.flag.Flag[ptrdiff_t] dragFlags() { return _dragFlags; }
	@property
	package Step[ptrdiff_t] dragSteps() { return _dragSteps; }

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
		}
		cwx.flag.Flag[] selFlags;
		Step[] selSteps;
		getSelectionFlagAndStep(selFlags, selSteps);
		if (selFlags.length || selSteps.length) { mixin(S_TRACE);
			s = .tryFormat(prop.msgs.flagStatusSel, s, selFlags.length + selSteps.length);
		}
		_statusLine = s;
		_comm.setStatusLine(flags, _statusLine);
	}
	@property
	string statusLine() {return _statusLine;}

	private void refreshUseCount() { mixin(S_TRACE);
		foreach (itm; flags.getItems()) { mixin(S_TRACE);
			if (cast(cwx.flag.Flag)itm.getData()) { mixin(S_TRACE);
				itm.setText(2, to!(string)(uc.flag.get(toFlagId((cast(cwx.flag.Flag)itm.getData()).path))));
			} else { mixin(S_TRACE);
				assert (cast(Step)itm.getData() !is null);
				itm.setText(2, to!(string)(uc.step.get(toStepId((cast(Step)itm.getData()).path))));
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
	int[] selectedItems(out cwx.flag.Flag[] fs, out Step[] ss) { mixin(S_TRACE);
		if (flags && !flags.isDisposed()) { mixin(S_TRACE);
			auto indices = flags.getSelectionIndices();
			foreach (i; indices) { mixin(S_TRACE);
				auto o = flags.getItem(i).getData();
				auto f = cast(cwx.flag.Flag) o;
				if (f) fs ~= f;
				auto s = cast(Step) o;
				if (s) ss ~= s;
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
		getSelectionFlagAndStep(fs, ss);
		return fs;
	}
	/// ditto
	@property
	Step[] selectionSteps() { mixin(S_TRACE);
		cwx.flag.Flag[] fs;
		Step[] ss;
		getSelectionFlagAndStep(fs, ss);
		return ss;
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

	/// フラグ生成のダイアログボックスを開く。
	/// 適切に設定された場合、新規フラグを生成する。
	void createFlag() { mixin(S_TRACE);
		editFlag(_dir, null);
	}

	/// ステップ生成のダイアログボックスを開く。
	/// 適切に設定された場合、新規ステップを生成する。
	void createStep() { mixin(S_TRACE);
		editStep(_dir, null);
	}

	/// 選択中のフラグ・ステップの編集を開始する。
	void edit() { mixin(S_TRACE);
		if (_dir !is null) { mixin(S_TRACE);
			foreach (index; flags.getSelectionIndices()) { mixin(S_TRACE);
				if (auto step = cast(Step)flags.getItem(index).getData()) { mixin(S_TRACE);
					editStep(step.parent, step);
				} else if (auto flag = cast(cwx.flag.Flag)flags.getItem(index).getData()) { mixin(S_TRACE);
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
			assert (f || s);
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
			if (!_dir) return;
			copy(se);
			del(se);
		}
		void copy(SelectionEvent se) { mixin(S_TRACE);
			if (!_dir) return;
			cwx.flag.Flag[] fs;
			Step[] ss;
			if (getSelectionFlagAndStep(fs, ss)) { mixin(S_TRACE);
				XNode node;
				getNode(_dir, fs, ss, node);
				node.newAttr("paneId", _id);
				XMLtoCB(prop, _comm.clipboard, node.text);
				_comm.refreshToolBar();
			}
		}
		void paste(SelectionEvent se) { mixin(S_TRACE);
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
			if (!_dir) return;
			enterEdit();
			auto selsF = selectionFlagIndices;
			auto selsS = selectionStepIndices;
			cwx.flag.Flag[ptrdiff_t] fs;
			Step[ptrdiff_t] ss;
			auto sels = flags.getSelection();
			foreach (itm; sels) { mixin(S_TRACE);
				auto data = itm.getData();
				if (auto flag = cast(cwx.flag.Flag)data) { mixin(S_TRACE);
					fs[flag.parent.indexOf(flag)] = flag;
				}
				if (auto step = cast(Step)data) { mixin(S_TRACE);
					ss[step.parent.indexOf(step)] = step;
				}
			}
			foreach (itm; sels) { mixin(S_TRACE);
				auto data = itm.getData();
				if (auto flag = cast(cwx.flag.Flag)data) { mixin(S_TRACE);
					_dir.remove(flag);
				}
				if (auto step = cast(Step)data) { mixin(S_TRACE);
					_dir.remove(step);
				}
			}
			storeDelete(selsF, selsS, fs, ss);
			_comm.delFlagAndStep.call(fs.values, ss.values);
			refresh();
			_comm.refreshToolBar();
		}
		void clone(SelectionEvent se) { mixin(S_TRACE);
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
			return flags.getSelectionIndex() != -1;
		}
		@property
		bool canDoC() { mixin(S_TRACE);
			return canDoT;
		}
		@property
		bool canDoP() { mixin(S_TRACE);
			return _comm.summary !is null && CBisXML(_comm.clipboard);
		}
		@property
		bool canDoD() { mixin(S_TRACE);
			return canDoT;
		}
		@property
		bool canDoClone() { mixin(S_TRACE);
			return canDoC;
		}
	}
	private bool pasteImpl(ref XNode node) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			enterEdit();
			string newPath;
			string rootId;
			cwx.flag.Flag[string] cFlags;
			Step[string] cSteps;
			auto selsF = selectionFlagIndices;
			auto selsS = selectionStepIndices;
			auto ver = new XMLInfo(prop.sys, LATEST_VERSION);
			if (_dir.appendFromNode(node, ver, true, false, cFlags, cSteps, newPath, rootId)) { mixin(S_TRACE);
				ptrdiff_t[] flagIndices;
				ptrdiff_t[] stepIndices;
				if (!cFlags.length && !cSteps.length) return false;
				foreach (f; cFlags) { mixin(S_TRACE);
					flagIndices ~= f.parent.indexOf(f);
				}
				foreach (s; cSteps) { mixin(S_TRACE);
					stepIndices ~= s.parent.indexOf(s);
				}
				storeInsert(selsF, selsS, flagIndices, stepIndices);
				Object[] objs;
				objs ~= cFlags.values;
				objs ~= cSteps.values;
				refresh(objs);
				_comm.refFlagAndStep.call(cFlags.values, cSteps.values);
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
		cancelEdit();
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() { mixin(S_TRACE);
		cancelEdit();
		_undo.redo();
		_comm.refreshToolBar();
	}

	void cancelEdit() { mixin(S_TRACE);
		if (_tte) _tte.cancel();
		if (_tce) _tce.cancel();
	}
	void enterEdit() { mixin(S_TRACE);
		if (_tte) _tte.enter();
		if (_tce) _tce.enter();
	}

	void replaceID() {
		auto index = flags.getSelectionIndex();
		if (index <= -1) return;
		auto data = flags.getItem(index).getData();
		if (auto f = cast(cwx.flag.Flag)data) _comm.replaceID(toFlagId(f.path), true);
		if (auto f = cast(Step)data) _comm.replaceID(toStepId(f.path), true);
	}
	@property
	bool canReplaceID() {
		auto index = flags.getSelectionIndex();
		if (index <= -1) return false;
		auto data = flags.getItem(index).getData();
		return cast(cwx.flag.Flag)data || cast(Step)data;
	}

	@property
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		cwx.flag.Flag[] fs;
		Step[] ss;
		getSelectionFlagAndStep(fs, ss);
		foreach (f; fs) { mixin(S_TRACE);
			r ~= f.cwxPath(true);
		}
		foreach (s; ss) { mixin(S_TRACE);
			r ~= s.cwxPath(true);
		}
		return r;
	}
}
