
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

static import std.algorithm;
import std.algorithm : max, min, map;
import std.range;
import std.array;
import std.ascii;
import std.conv;
import std.datetime;
import std.string;
import std.exception;

import org.eclipse.swt.all;

import java.lang.all;

/// ステップ設定用のダイアログ。
public class StepEditDialog : AbsDialog {
private:
	Commons _comm;
	Summary _summ;

	Step _step;
	FlagDir _dir;

	Text _name;
	Combo _init;
	Table _values;
	string[] _valueCache;
	TableTextEdit _tte;
	Spinner _stepCount;

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
			_values.getItem(_index).setText(1, _oldName);
			if (_index == _init.getSelectionIndex()) { mixin(S_TRACE);
				_init.setItem(_index, _oldName);
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
				this.outer._values.getItem(i).setText(1, values[i]);
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
		warning = ws;
	}

	void changeStepCount(bool store, int num) { mixin(S_TRACE);
		if (num == 0) return;
		auto ic = _values.getItemCount();
		if (ic == num) return;
		if (store) storeAll();
		if (ic < num) { mixin(S_TRACE);
			_values.setRedraw(false);
			scope (exit) _values.setRedraw(true);
			auto lastValue = _values.getItem(ic - 1).getText(1);
			foreach (index; ic .. num) { mixin(S_TRACE);
				auto item = new TableItem(_values, SWT.NONE);
				item.setText(0, .text(index));

				if (store) { mixin(S_TRACE);
					if (index < _valueCache.length) { mixin(S_TRACE);
						lastValue = _valueCache[index];
					} else { mixin(S_TRACE);
						lastValue = createNewName(lastValue, (string name) { mixin(S_TRACE);
							return name != lastValue;
						});
						_valueCache ~= lastValue;
					}
					item.setText(1, lastValue);
				}
			}
		} else if (num < ic) { mixin(S_TRACE);
			_values.setRedraw(false);
			scope (exit) _values.setRedraw(true);
			_values.setItemCount(num);
		}
		if (_stepCount.getSelection() != num) _stepCount.setSelection(num);
		if (store) updateInitCombo();
		refDataVersion();
	}
	void updateInitCombo() { mixin(S_TRACE);
		auto index = _init.getSelectionIndex();
		setComboItems(_init, _valueCache[0 .. _values.getItemCount()]);
		_init.select(.min(_init.getItemCount() - 1, index));
	}

	void valueEditEnd(TableItem itm, int column, string newText) { mixin(S_TRACE);
		if (itm.getText(1) == newText) return;
		auto index = _values.indexOf(itm);
		storeSingle(index, itm.getText(1), newText);
		itm.setText(column, newText);
		_valueCache[index] = newText;
		_init.setItem(index, newText);
		applyEnabled();
	}

	void delStep(cwx.flag.Flag[] flag, Step[] step) { mixin(S_TRACE);
		foreach (s; step) { mixin(S_TRACE);
			if (s is _step) { mixin(S_TRACE);
				forceCancel();
				return;
			}
		}
	}
	void refScenario(Summary summ) { mixin(S_TRACE);
		if (_summ is summ) forceCancel();
	}
	void refDataVersion() { mixin(S_TRACE);
		_stepCount.setEnabled(!_summ.legacy || _stepCount.getSelection() != _comm.prop.looks.stepMaxCount);
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
		if (_step.parent) { mixin(S_TRACE);
			return name;
		} else { mixin(S_TRACE);
			return _dir.createNewStepName(name, _step ? _step.name : "");
		}
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
			_values = .rangeSelectableTable(area, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.VIRTUAL);
			_values.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto valueNumCol = new TableColumn(_values, SWT.NONE);
			auto prop = _comm.prop;
			saveColumnWidth!("prop.var.etc.valueNumberColumn")(_comm.prop, valueNumCol);
			auto nameCol = new FullTableColumn(_values, SWT.NONE);

			auto menu = new Menu(_values.getShell(), SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.Undo, { _undo.undo(); }, &_undo.canUndo);
			createMenuItem(_comm, menu, MenuID.Redo, { _undo.redo(); }, &_undo.canRedo);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.CreateStepValues, &createStepValues, &canCreateStepValues);
			_values.setMenu(menu);

			Control createEditor(TableItem itm, int editC) { mixin(S_TRACE);
				auto editor = createTextEditor(_comm, _comm.prop, _values, itm.getText(editC));
				auto menu = editor.getMenu();
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.CreateStepValues, &createStepValues, &canCreateStepValues);
				return editor;
			}
			_tte = new TableTextEdit(_comm, _comm.prop, _values, 1, &valueEditEnd, (itm, column) => true, &createEditor);
			_tte.quickStart = true;
		}
		{
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			comp.setLayout(zeroMarginGridLayout(2, false));

			auto l = new Label(comp, SWT.NONE);
			l.setText(_comm.prop.msgs.stepCount);
			_stepCount = new Spinner(comp, SWT.BORDER);
			initSpinner(_stepCount);
			mod(_stepCount);
			_stepCount.setMinimum(1);
			_stepCount.setMaximum(_comm.prop.var.etc.stepCountMax);
			.listener(_stepCount, SWT.Selection, () => changeStepCount(true, _stepCount.getSelection()));
			.listener(_stepCount, SWT.Modify, () => changeStepCount(true, _stepCount.getSelection()));
		}
		_comm.delFlagAndStep.add(&delStep);
		_comm.refScenario.add(&refScenario);
		_comm.refDataVersion.add(&refDataVersion);
		.listener(area, SWT.Dispose, { mixin(S_TRACE);
			_comm.delFlagAndStep.remove(&delStep);
			_comm.refScenario.remove(&refScenario);
			_comm.refDataVersion.remove(&refDataVersion);
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
			_valueCache = .iota(_comm.prop.looks.stepMaxCount).map!(i => .tryFormat(_comm.prop.msgs.dlgTxtStep, i)).array();
		}
		foreach (i, value; _valueCache) { mixin(S_TRACE);
			auto item = new TableItem(_values, SWT.NONE);
			item.setText(0, .text(i));
			item.setText(1, value);
		}
		setComboItems(_init, _valueCache);
		_init.select(.min(_step is null ? 0 : _step.select, _step.count - 1));
		_stepCount.setSelection(_values.getItemCount());
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
		bool stored = false;
		foreach (i; index + 1 .. _values.getItemCount()) { mixin(S_TRACE);
			lastValue = createNewName(lastValue, (string name) { mixin(S_TRACE);
				return name != lastValue;
			});
			if (_valueCache[i] != lastValue) { mixin(S_TRACE);
				if (!stored) { mixin(S_TRACE);
					stored = true;
					storeAll();
				}
				_values.getItem(i).setText(1, lastValue);
				_valueCache[i] = lastValue;
			}
		}
		updateInitCombo();
	}

	override bool apply() { mixin(S_TRACE);
		auto vals = _valueCache[0 .. _stepCount.getSelection()];
		if (_step.parent) { mixin(S_TRACE);
			_step.name = this.name;
			_step.setValues(vals, _init.getSelectionIndex());
		} else { mixin(S_TRACE);
			_step = new Step(this.name, vals, _init.getSelectionIndex());
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
	Props prop;
	cwx.flag.Flag _flag;
	FlagDir dir;

	Text flagName;
	Combo flagInit;
	Combo flagTrue;
	Combo flagFalse;

	void refreshWarning() { mixin(S_TRACE);
		string[] ws;
		if (prop.sys.isSystemVar(flagName.getText())) { mixin(S_TRACE);
			ws ~= .tryFormat(prop.msgs.warningSystemVarName, prop.sys.prefixSystemVarName);
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
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.delFlagAndStep.remove(&delFlag);
			_comm.refScenario.remove(&refScenario);
		}
	}
	void delFlag(cwx.flag.Flag[] flag, Step[] step) { mixin(S_TRACE);
		foreach (f; flag) { mixin(S_TRACE);
			if (f is _flag) { mixin(S_TRACE);
				forceCancel();
				return;
			}
		}
	}
	void refScenario(Summary summ) { mixin(S_TRACE);
		forceCancel();
	}
public:
	/// Params:
	/// prop = 設定情報。
	/// shell = 親ウィンドウ。
	/// dir = 設定するフラグの親ディレクトリ。
	/// flag = 設定するフラグ。新規の場合はnull。
	this(Commons comm, Props prop, Shell shell, FlagDir dir, cwx.flag.Flag flag = null) { mixin(S_TRACE);
		super(prop, shell, false, prop.msgs.dlgTitFlag, prop.images.flag, true, prop.var.flagDlg, true);
		_comm = comm;
		this.prop = prop;
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
		if (_flag.parent) { mixin(S_TRACE);
			return name;
		} else { mixin(S_TRACE);
			return dir.createNewFlagName(name, _flag ? _flag.name : "");
		}
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
		_comm.delFlagAndStep.add(&delFlag);
		_comm.refScenario.add(&refScenario);
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
		} else { mixin(S_TRACE);
			flagName.setText("");
			flagTrue.setText(prop.var.etc.flagTrues.length > 0 ? prop.var.etc.flagTrues[0] : "");
			flagFalse.setText(prop.var.etc.flagFalses.length > 0 ? prop.var.etc.flagFalses[0] : "");
			setComboItems(flagInit, [flagTrue.getText(), flagFalse.getText()]);
			flagInit.select(0);
		}
		if (!_flag.parent) { mixin(S_TRACE);
			// 新規作成時
			flagName.setText("");
		}
		flagName.selectAll();
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
		_comm.refFlagAndStep.call([_flag], []);
		return true;
	}
}

private abstract class FTVUndo : Undo {
	protected FlagTable _v;
	protected Commons comm;
	protected string _dir;
	private string _selectedDir;
	private string[] _selectedF;
	private string[] _selectedS;
	private string[] _selectedFB;
	private string[] _selectedSB;
	protected FlagDir selDir = null;
	this (FlagTable v, Commons comm, FlagDir dir) { mixin(S_TRACE);
		_v = v;
		_dir = dir.path;
		this.comm = comm;
		saveSelected(v);
	}
	@property
	protected FlagDir dir() { mixin(S_TRACE);
		return cast(FlagDir) comm.summary.flagDirRoot.findPath(_dir, false);
	}
	private void saveSelected(FlagTable v) { mixin(S_TRACE);
		auto dir = this.dir();
		if (!dir) return;
		_selectedDir = dir.cwxPath(true);
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			_selectedF = v.selectionFlagNames;
			_selectedS = v.selectionStepNames;
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
					v.selectFlagNames(_selectedFB);
					v.selectStepNames(_selectedSB);
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
	private string _name;
	this (FlagDir dir, int index, string oldName, int value, string[] names) { mixin(S_TRACE);
		auto p = FlagTable.fromIndex(dir, index);
		auto f = cast(cwx.flag.Flag)p;
		if (f) { mixin(S_TRACE);
			auto flag = new cwx.flag.Flag(f);
			_name = flag.name;
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
			_name = step.name;
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
			auto f = dir.getFlag(_name);
			_f = new cwx.flag.Flag(f);
			auto o = cast(cwx.flag.Flag)fB;
			assert (o);
			_name = o.name;
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
			auto s = dir.getStep(_name);
			_f = new Step(s);
			auto o = cast(Step)fB;
			assert (o);
			_name = o.name;
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
	private int[] _dirIndices;
	private string[] _flagName;
	private string[] _stepName;
	/// delete
	private FlagDir[int] _ds;
	private cwx.flag.Flag[] _fs;
	private Step[] _ss;

	/// 追加を元に戻す。
	this (FlagTable v, Commons comm, FlagDir dir, string[] selectedF, string[] selectedS, int[] dirIndices, string[] flagName, string[] stepName) { mixin(S_TRACE);
		super (v, comm, dir);
		_selectedF = selectedF.dup;
		_selectedS = selectedS.dup;
		_dirIndices = dirIndices.dup;
		_flagName = flagName.dup;
		_stepName = stepName.dup;
		_insert = true;
	}
	/// 削除を元に戻す。
	this (FlagTable v, Commons comm, FlagDir dir, string[] selectedF, string[] selectedS, FlagDir[int] ds, cwx.flag.Flag[] fs, Step[] ss) { mixin(S_TRACE);
		super (v, comm, dir);
		_selectedF = selectedF.dup;
		_selectedS = selectedS.dup;
		save(ds, fs, ss);
		_insert = false;
	}
	private void save(FlagDir[int] ds, cwx.flag.Flag[] fs, Step[] ss) { mixin(S_TRACE);
		_ds = ds;
		foreach (index, d; _ds) { mixin(S_TRACE);
			_ds[index] = new FlagDir(d);
		}
		_fs.length = 0;
		foreach (f; fs) { mixin(S_TRACE);
			_fs ~= new cwx.flag.Flag(f);
		}
		_ss.length = 0;
		foreach (s; ss) { mixin(S_TRACE);
			_ss ~= new Step(s);
		}
	}
	private void undoInsert(FlagTable v) { mixin(S_TRACE);
		_insert = false;
		FlagDir[int] ds;
		cwx.flag.Flag[] fs;
		Step[] ss;
		auto dir = this.dir();
		foreach (i; _dirIndices) { mixin(S_TRACE);
			auto d = dir.subDirs[i];
			if (d) ds[i] = d;
		}
		foreach (n; _flagName) { mixin(S_TRACE);
			auto f = dir.getFlag(n);
			if (f) fs ~= f;
		}
		foreach (n; _stepName) { mixin(S_TRACE);
			auto s = dir.getStep(n);
			if (s) ss ~= s;
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
			fs ~= d.allFlags;
			ss ~= d.allSteps;
		}
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			v.refresh();
		}
		if (ds.length) comm.delFlagDir.call(ds.values);
		if (fs.length || ss.length) comm.delFlagAndStep.call(fs, ss);
	}
	private void undoDelete(FlagTable v) { mixin(S_TRACE);
		_insert = true;
		auto dir = this.dir();
		_dirIndices.length = 0;
		_flagName.length = 0;
		_stepName.length = 0;
		selDir = (_ds.length == 1 && !_fs.length && !_ss.length) ? _ds.values[0] : null;
		foreach (f; _fs) { mixin(S_TRACE);
			_flagName ~= f.name;
			dir.add(f);
		}
		foreach (s; _ss) { mixin(S_TRACE);
			_stepName ~= s.name;
			dir.add(s);
		}
		foreach (index; std.algorithm.sort(_ds.keys)) { mixin(S_TRACE);
			auto d = _ds[index];
			_dirIndices ~= index;
			dir.insert(index, d);
			_fs ~= d.allFlags;
			_ss ~= d.allSteps;
		}
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			v.refresh();
		}
		if (_ds.length) comm.refFlagDir.call(_ds.values);
		if (_fs.length || _ss.length) comm.refFlagAndStep.call(_fs, _ss);
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
	private string[string] _cFlags;
	private string[string] _cSteps;

	this (FlagTable v, Commons comm, string[] selectedF, string[] selectedS, FlagDir to, int[] dirIndices, string[] flagName, string[] stepName, FlagDir from, FlagDir[int] ds, cwx.flag.Flag[] fs, Step[] ss, cwx.flag.Flag[string] cFlags, Step[string] cSteps) { mixin(S_TRACE);
		super (v, comm, from);
		_selectedF = selectedF.dup;
		_selectedS = selectedS.dup;
		assert (dirIndices.length == ds.length);
		assert (flagName.length == fs.length);
		assert (stepName.length == ss.length);
		_dir1 = new UndoInsertDelete(v, comm, to, selectedF, selectedS, dirIndices, flagName, stepName);
		_dir2 = new UndoInsertDelete(v, comm, from, selectedF, selectedS, ds, fs, ss);
		foreach (oPath, flag; cFlags) { mixin(S_TRACE);
			_cFlags[oPath] = flag.path;
		}
		foreach (oPath, step; cSteps) { mixin(S_TRACE);
			_cSteps[oPath] = step.path;
		}
	}
	private void change(FlagTable v) { mixin(S_TRACE);
		string[string] cFlags;
		string[string] cSteps;
		foreach (nPath, oPath; _cFlags) { mixin(S_TRACE);
			cFlags[oPath] = nPath;
			comm.summary.useCounter.change(toFlagId(oPath), toFlagId(nPath));
		}
		foreach (nPath, oPath; _cSteps) { mixin(S_TRACE);
			cSteps[oPath] = nPath;
			comm.summary.useCounter.change(toStepId(oPath), toStepId(nPath));
		}
		_cFlags = cFlags;
		_cSteps = cSteps;
		if (v && v.flags && !v.flags.isDisposed()) { mixin(S_TRACE);
			v.refreshUseCount();
		}
	}
	override void undo() { mixin(S_TRACE);
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		_dir1.undoImpl(v);
		_dir2.undoImpl(v);
		change(v);
	}
	override void redo() { mixin(S_TRACE);
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		_dir2.redoImpl(v);
		_dir1.redoImpl(v);
		change(v);
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

		string oldName = dir.name;
		dir.rename(_oldName, comm.summary.useCounter);
		if (dir.parent) dir.parent.sortSubDirs(false);
		_oldName = oldName;

		comm.refFlagDir.call([dir]);
		_dir = dir.path;
	}
	override void undo() {impl();}
	override void redo() {impl();}
	override void dispose() {}
}
package class UndoSwap : FTVUndo {
	private FlagDir _parent;
	private int _index1, _index2;
	this (FlagTable v, Commons comm, FlagDir dir, FlagDir parent, int index1, int index2) { mixin(S_TRACE);
		super (v, comm, dir);
		_parent = parent;
		_index1 = index1;
		_index2 = index2;
	}
	private void impl() { mixin(S_TRACE);
		auto v = view();
		udb(v);
		scope (exit) uda(v);

		_parent.swapDir(_index1, _index2);

		comm.refFlagDir.call([_parent, _parent.subDirs[_index1], _parent.subDirs[_index2]]);
	}
	override void undo() {impl();}
	override void redo() {impl();}
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
	void storeInsert(string[] selectedF, string[] selectedS, string[] flagName, string[] stepName) { mixin(S_TRACE);
		_undo ~= new UndoInsertDelete(this, _comm, _dir, selectedF, selectedS, [], flagName, stepName);
	}
	void storeDelete(string[] selectedF, string[] selectedS, cwx.flag.Flag[] fs, Step[] ss) { mixin(S_TRACE);
		FlagDir[int] ds;
		_undo ~= new UndoInsertDelete(this, _comm, _dir, selectedF, selectedS, ds, fs, ss);
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
			foreach (f; _dir.steps) { mixin(S_TRACE);
				if (!_incSearch.match(f.name, f)) continue;
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
			}
			foreach (f; _dir.flags) { mixin(S_TRACE);
				if (!_incSearch.match(f.name, f)) continue;
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
			}
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

	void editFlag(FlagDir parent, cwx.flag.Flag flag) { mixin(S_TRACE);
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
		auto dlg = new FlagEditDialog(_comm, prop, dlgParShl, parent, flag);
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
				string[] selsF;
				string[] selsS;
				if (flags && !flags.isDisposed()) { mixin(S_TRACE);
					selsF = selectionFlagNames;
					selsS = selectionStepNames;
				}
				storeInsert(selsF, selsS, [flag.name], []);
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
		bool createMode = step is null;
		string old = createMode ? null : step.name;
		if (!step) { mixin(S_TRACE);
			string[] vals;
			foreach (i; 0 .. prop.looks.stepMaxCount) { mixin(S_TRACE);
				vals ~= .tryFormat(prop.msgs.dlgTxtStep, i);
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
				string[] selsF;
				string[] selsS;
				if (flags && !flags.isDisposed()) { mixin(S_TRACE);
					selsF = selectionFlagNames;
					selsS = selectionStepNames;
				}
				storeInsert(selsF, selsS, [], [step.name]);
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
			if (e.character == SWT.CR) { mixin(S_TRACE);
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
	void selectNamesImpl(F)(string[] names) { mixin(S_TRACE);
		auto set = new HashSet!string;
		foreach (name; names) set.add(name);
		foreach (i, itm; flags.getItems()) { mixin(S_TRACE);
			if (auto f = cast(F)itm.getData()) { mixin(S_TRACE);
				if (set.contains(f.name)) { mixin(S_TRACE);
					flags.select(cast(int)i);
				}
			}
		}
	}
	void selectFlagNames(string[] names) { mixin(S_TRACE);
		selectNamesImpl!(cwx.flag.Flag)(names);
	}
	void selectStepNames(string[] names) { mixin(S_TRACE);
		selectNamesImpl!Step(names);
	}

	cwx.flag.Flag[] _dragFlags;
	Step[] _dragSteps;
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
				getSelectionFlagAndStep(_dragFlags, _dragSteps);
				XNode node;
				getNode(_dir, _dragFlags, _dragSteps, node);
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
				_comm.delFlagAndStep.call(_dragFlags, _dragSteps);
				_comm.refreshToolBar();
			}
			_dragFlags.length = 0;
			_dragSteps.length = 0;
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
	void copyVariablePath() { mixin(S_TRACE);
		if (0 == flags.getSelectionCount()) return;

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
			createMenuItem2(_comm, mEvt, MenuProps.buildMenu(.tryFormat(prop.msgs.setStepValue, .tryFormat(prop.msgs.dlgTxtStep, i)), mnemonic, "", false), prop.images.content(CType.SET_STEP), () => copyStepTree(i), () => 0 < selectionSteps.length);
		}
		foreach (i; 0..prop.looks.stepMaxCount) { mixin(S_TRACE);
			ssValue(i);
		}

		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.FindID, &replaceID, &canReplaceID);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.CopyVariablePath, &copyVariablePath, () => 0 < flags.getSelectionCount());
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

		new TableTextEdit(_comm, prop, flags, 0, &nameEditEnd, null);
		new TableComboEdit!Combo(_comm, prop, flags, 1, &initCombo, &initEditEnd, null);

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
	Control widget() {return _comp;}

	@property
	package cwx.flag.Flag[] dragFlags() {return _dragFlags;}
	@property
	package Step[] dragSteps() {return _dragSteps;}

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
			if (cast(cwx.flag.Flag) itm.getData()) { mixin(S_TRACE);
				itm.setText(2, to!(string)(uc.flag.get(toFlagId((cast(cwx.flag.Flag) itm.getData()).path))));
			} else { mixin(S_TRACE);
				assert (cast(Step) itm.getData());
				itm.setText(2, to!(string)(uc.step.get(toStepId((cast(Step) itm.getData()).path))));
			}
		}
	}
	void refresh() { mixin(S_TRACE);
		refresh([]);
	}
	void refresh(in Object[] selObjs) { mixin(S_TRACE);
		if (!flags || flags.isDisposed()) return;
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
			_dir.sortSteps();
			_dir.sortFlags();
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
	string[] selectionFlagNames() { mixin(S_TRACE);
		string[] r;
		foreach (f; selectionFlags) { mixin(S_TRACE);
			r ~= f.name;
		}
		return r;
	}
	/// ditto
	@property
	string[] selectionStepNames() { mixin(S_TRACE);
		string[] r;
		foreach (f; selectionSteps) { mixin(S_TRACE);
			r ~= f.name;
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
				auto node = XNode.parse(c);
				pasteImpl(node);
			}
		}
		void del(SelectionEvent se) { mixin(S_TRACE);
			if (!_dir) return;
			auto selsF = selectionFlagNames;
			auto selsS = selectionStepNames;
			cwx.flag.Flag[] fs;
			Step[] ss;
			foreach (itm; flags.getSelection()) { mixin(S_TRACE);
				auto data = itm.getData();
				auto flag = cast(cwx.flag.Flag) data;
				if (flag) { mixin(S_TRACE);
					fs ~= flag;
					_dir.remove(flag);
				}
				auto step = cast(Step) data;
				if (step) { mixin(S_TRACE);
					ss ~= step;
					_dir.remove(step);
				}
			}
			storeDelete(selsF, selsS, fs, ss);
			_comm.delFlagAndStep.call(fs, ss);
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
			string newPath;
			string rootId;
			cwx.flag.Flag[string] cFlags;
			Step[string] cSteps;
			auto selsF = selectionFlagNames;
			auto selsS = selectionStepNames;
			auto ver = new XMLInfo(prop.sys, LATEST_VERSION);
			if (_dir.appendFromNode(node, ver, true, false, cFlags, cSteps, newPath, rootId)) { mixin(S_TRACE);
				string[] flagName;
				string[] stepName;
				if (!cFlags.length && !cSteps.length) return false;
				foreach (f; cFlags) { mixin(S_TRACE);
					flagName ~= f.name;
				}
				foreach (s; cSteps) { mixin(S_TRACE);
					stepName ~= s.name;
				}
				storeInsert(selsF, selsS, flagName, stepName);
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
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() { mixin(S_TRACE);
		_undo.redo();
		_comm.refreshToolBar();
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
