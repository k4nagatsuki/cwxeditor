
module cwx.editor.gui.dwt.flagtable;

import cwx.summary;
import cwx.flag;
import cwx.utils;
import cwx.usecounter;
import cwx.path;
import cwx.menu;
import cwx.types;

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;

import std.conv;
import std.string;
import std.exception;

import org.eclipse.swt.all;

import java.lang.all;

/// ステップ設定用のダイアログ。
/// 値は強制的に10件になる。
public class StepEditDialog : AbsDialog {
private:
	Commons _comm;
	Props prop;
	Step _step;
	FlagDir dir;

	Text stepName;
	Combo stepInit;
	Text[] stepVals;

	void refreshWarning() {
		string[] ws;
		if (prop.sys.isSystemVar(stepName.getText())) {
			ws ~= .tryFormat(prop.msgs.warningSystemVarName, prop.sys.prefixSystemVarName);
		}
		warning = ws;
	}

	class ModValue : ModifyListener {
	private:
		int index;
	public:
		this(int index) {
			this.index = index;
		}
		override void modifyText(ModifyEvent e) {
			if (index < stepInit.getItemCount()) {
				stepInit.setItem(index, (cast(Text) e.getSource()).getText());
			}
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.delFlagAndStep.remove(&delStep);
			_comm.refScenario.remove(&refScenario);
		}
	}
	void delStep(Flag[] flag, Step[] step) {
		foreach (s; step) {
			if (s is _step) {
				forceCancel();
				return;
			}
		}
	}
	void refScenario(Summary summ) {
		forceCancel();
	}
public:
	/// Params:
	/// prop = 設定情報。
	/// shell = 親ウィンドウ。
	/// dir = 設定するステップの親ディレクトリ。
	/// step = 設定するステップ。新規の場合はnull。
	this (Commons comm, Props prop, Shell shell, FlagDir dir, Step step = null) {
		super(prop, shell, false, prop.msgs.dlgTitStep, prop.images.step, true, prop.var.stepDlg, true);
		_comm = comm;
		this.prop = prop;
		this.dir = dir;
		this._step = step;
		enterClose = true;
	}

	/// Returns: 編集対象となったステップ。
	@property
	Step step() {
		return _step;
	}
	/// 入力中の名前を妥当な形にして返す。
	@property
	string name() {
		auto name = FlagDir.validName(stepName.getText());
		if (_step.parent) {
			return name;
		} else {
			return dir.createNewStepName(name, _step ? _step.name : "");
		}
	}
protected:
	override void setup(Composite area) {
		area.setLayout(zeroGridLayout(1));
		{
			auto comp = new Composite(area, SWT.NULL);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comp.setLayout(new GridLayout(5, false));

			(new Label(comp, SWT.NULL)).setText(prop.msgs.dlgLblStepName);
			stepName = new Text(comp, SWT.BORDER);
			mod(stepName);
			createTextMenu!Text(_comm, prop, stepName, &catchMod);
			setGridMinW(stepName, prop.var.etc.flagNameWidth, GridData.FILL_HORIZONTAL);
			checker(stepName);
			.listener(stepName, SWT.Modify, &refreshWarning);

			auto gd = new GridData(GridData.FILL_VERTICAL);
			gd.heightHint = 0;
			(new Label(comp, SWT.SEPARATOR | SWT.VERTICAL)).setLayoutData(gd);

			(new Label(comp, SWT.NULL)).setText(prop.msgs.dlgLblStepInit);
			stepInit = new Combo(comp, SWT.READ_ONLY);
			mod(stepInit);
			stepInit.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
			setGridMinW(stepInit, prop.var.etc.flagInitWidth);
		}
		(new Label(area, SWT.SEPARATOR | SWT.HORIZONTAL))
			.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		{
			auto comp = new Composite(area, SWT.NULL);
			comp.setLayoutData(new GridData(GridData.FILL_BOTH));

			// 何列かに分けて値のフィールドを配置する
			Composite valsComp;
			int gdc = 0;
			for (int i = 0; i < prop.looks.stepMaxCount; i++) {
				if (i % 5 == 0) {
					// 1列の件数が5を超えた場合、列を追加
					if (0 < i) {
						auto gd = new GridData(GridData.FILL_VERTICAL);
						gd.heightHint = 0;
						(new Label(comp, SWT.SEPARATOR | SWT.VERTICAL)).setLayoutData(gd);
						gdc++;
					}
					valsComp = new Composite(comp, SWT.NULL);
					valsComp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					valsComp.setLayout(new GridLayout(2, false));
					gdc++;
				}
				(new Label(valsComp, SWT.NULL)).setText(.tryFormat(prop.msgs.dlgLblStep, i));
				auto t = new Text(valsComp, SWT.BORDER);
				createTextMenu!Text(_comm, prop, t, &catchMod);
				stepVals ~= t;
				mod(t);
				stepVals[i].addModifyListener(new ModValue(i));
				stepVals[i].addFocusListener(new class FocusAdapter {
					override void focusGained(FocusEvent e) {
						auto text = cast(Text) e.widget;
						text.selectAll();
					}
				});
				setGridMinW(stepVals[i], prop.var.etc.flagValueWidth, GridData.FILL_HORIZONTAL);
			}
			comp.setLayout(new GridLayout(gdc, false));
		}
		_comm.delFlagAndStep.add(&delStep);
		_comm.refScenario.add(&refScenario);
		getShell().addDisposeListener(new Dispose);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		string[] vals;
		if (_step !is null) {
			stepName.setText(_step.name);
			foreach (i, stepVal; stepVals) {
				if (i < _step.count) {
					stepVal.setText(_step.getValue(i));
				} else {
					stepVal.setText(.tryFormat(prop.msgs.dlgTxtStep, i));
				}
				vals ~= stepVal.getText();
			}
		} else {
			stepName.setText("");
			foreach (i, stepVal; stepVals) {
				stepVal.setText(.tryFormat(prop.msgs.dlgTxtStep, i));
				vals ~= stepVal.getText();
			}
		}
		if (!_step.parent) {
			// 新規作成時
			stepName.setText("");
		}
		stepName.selectAll();
		setComboItems(stepInit, vals);
		stepInit.select(_step is null ? 0 : _step.select);
	}

	override bool apply() {
		string[] vals;
		foreach (stepVal; stepVals) {
			vals ~= stepVal.getText();
		}
		if (_step.parent) {
			_step.name = this.name;
			_step.setValues(vals, stepInit.getSelectionIndex());
		} else {
			_step = new Step(this.name, vals, stepInit.getSelectionIndex());
			dir.add(_step);
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
	Flag _flag;
	FlagDir dir;

	Text flagName;
	Combo flagInit;
	Combo flagTrue;
	Combo flagFalse;

	void refreshWarning() {
		string[] ws;
		if (prop.sys.isSystemVar(flagName.getText())) {
			ws ~= .tryFormat(prop.msgs.warningSystemVarName, prop.sys.prefixSystemVarName);
		}
		warning = ws;
	}

	class ModOnOff : SelectionAdapter, ModifyListener {
	private:
		int index;
		void change(E)(E e) {
			if (index < flagInit.getItemCount()) {
				flagInit.setItem(index, (cast(Combo) e.getSource()).getText());
			}
		}
	public:
		this(int index) {
			this.index = index;
		}
		override void widgetSelected(SelectionEvent e) {
			change(e);
		}
		override void modifyText(ModifyEvent e) {
			change(e);
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.delFlagAndStep.remove(&delFlag);
			_comm.refScenario.remove(&refScenario);
		}
	}
	void delFlag(Flag[] flag, Step[] step) {
		foreach (f; flag) {
			if (f is _flag) {
				forceCancel();
				return;
			}
		}
	}
	void refScenario(Summary summ) {
		forceCancel();
	}
public:
	/// Params:
	/// prop = 設定情報。
	/// shell = 親ウィンドウ。
	/// dir = 設定するフラグの親ディレクトリ。
	/// flag = 設定するフラグ。新規の場合はnull。
	this(Commons comm, Props prop, Shell shell, FlagDir dir, Flag flag = null) {
		super(prop, shell, false, prop.msgs.dlgTitFlag, prop.images.flag, true, prop.var.flagDlg, true);
		_comm = comm;
		this.prop = prop;
		this._flag = flag;
		this.dir = dir;
		enterClose = true;
	}

	/// Returns: 編集対象となったフラグ。
	@property
	Flag flag() {
		return _flag;
	}
	/// 入力中の名前を妥当な形にして返す。
	@property
	string name() {
		auto name = FlagDir.validName(flagName.getText());
		if (_flag.parent) {
			return name;
		} else {
			return dir.createNewFlagName(name, _flag ? _flag.name : "");
		}
	}
protected:
	private static void setMinW(Control c, int minW, int gridStyle = SWT.NULL) {
		auto gd = new GridData(gridStyle);
		int w = c.computeSize(SWT.DEFAULT, SWT.DEFAULT).x;
		gd.widthHint = w > minW ? w : minW;
		c.setLayoutData(gd);
	}

	override void setup(Composite area) {
		area.setLayout(zeroGridLayout(1));
		{
			auto comp = new Composite(area, SWT.NULL);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comp.setLayout(new GridLayout(5, false));

			(new Label(comp, SWT.NULL)).setText(prop.msgs.dlgLblFlagName);
			flagName = new Text(comp, SWT.BORDER);
			createTextMenu!Text(_comm, prop, flagName, &catchMod);
			mod(flagName);
			setGridMinW(flagName, prop.var.etc.flagNameWidth, GridData.FILL_HORIZONTAL);
			checker(flagName);
			.listener(flagName, SWT.Modify, &refreshWarning);

			auto gd = new GridData(GridData.FILL_VERTICAL);
			gd.heightHint = 0;
			(new Label(comp, SWT.SEPARATOR | SWT.VERTICAL)).setLayoutData(gd);

			(new Label(comp, SWT.NULL)).setText(prop.msgs.dlgLblFlagInit);
			flagInit = new Combo(comp, SWT.READ_ONLY);
			mod(flagInit);
			setGridMinW(flagInit, prop.var.etc.flagInitWidth);
		}
		(new Label(area, SWT.SEPARATOR | SWT.HORIZONTAL))
			.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		{
			auto ocomp = new Composite(area, SWT.NONE);
			ocomp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
			cl.fillHorizontal = true;
			ocomp.setLayout(cl);
			auto comp = new Composite(ocomp, SWT.NONE);
			comp.setLayout(new GridLayout(2, false));

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
		if (_flag !is null) {
			flagName.setText(_flag.name);
			flagTrue.setText(_flag.on);
			if (-1 == flagTrue.indexOf(_flag.on)) flagTrue.add(_flag.on, 0);
			flagFalse.setText(_flag.off);
			if (-1 == flagFalse.indexOf(_flag.off)) flagFalse.add(_flag.off, 0);
			setComboItems(flagInit, [flagTrue.getText(), flagFalse.getText()]);
			flagInit.select(_flag.onOff ? 0 : 1);
		} else {
			flagName.setText("");
			flagTrue.setText(prop.var.etc.flagTrues.length > 0 ? prop.var.etc.flagTrues[0] : "");
			flagFalse.setText(prop.var.etc.flagFalses.length > 0 ? prop.var.etc.flagFalses[0] : "");
			setComboItems(flagInit, [flagTrue.getText(), flagFalse.getText()]);
			flagInit.select(0);
		}
		if (!_flag.parent) {
			// 新規作成時
			flagName.setText("");
		}
		flagName.selectAll();
	}

	override bool apply() {
		if (_flag.parent) {
			_flag.name = this.name;
			_flag.onOff = flagInit.getSelectionIndex() == 0;
			_flag.on = flagTrue.getText();
			_flag.off = flagFalse.getText();
		} else {
			_flag = new Flag(this.name, flagTrue.getText(), flagFalse.getText(),
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
	private int[] _selected;
	private int[] _selectedB;
	protected FlagDir selDir = null;
	this (FlagTable v, Commons comm, FlagDir dir) {
		_v = v;
		_dir = dir.path;
		this.comm = comm;
		saveSelected(v);
	}
	@property
	protected FlagDir dir() {
		return cast(FlagDir) comm.summary.flagDirRoot.findPath(_dir, false);
	}
	private void saveSelected(FlagTable v) {
		auto dir = this.dir();
		if (!dir) return;
		_selectedDir = dir.cwxPath(true);
		if (v && v.flags && !v.flags.isDisposed()) {
			_selected = v.flags.getSelectionIndices();
		} else {
			_selected.length = 0;
		}
	}
	void udb(FlagTable v) {
		_selectedB = _selected.dup;
		saveSelected(v);
		if (v && v.flags && !v.flags.isDisposed()) {
			.forceFocus(v.flags, false);
		}
	}
	void uda(FlagTable v) {
		if (v && v.flags && !v.flags.isDisposed()) {
			if (selDir) {
				if (comm.openCWXPath(selDir.cwxPath(true), true)) {
					v.flags.deselectAll();
				}
			} else {
				if (comm.openCWXPath(_selectedDir, true)) {
					v.flags.deselectAll();
					v.flags.select(_selectedB);
				}
			}
			v.refreshStatusLine();
		}
		selDir = null;
		comm.refreshToolBar();
	}
	FlagTable view() {
		return _v;
	}
	abstract override void undo();
	abstract override void redo();
	abstract override void dispose();
}
package class UndoEdit : FTVUndo {
	private CWXPath _f;
	private string _name;
	this (FlagTable v, Commons comm, FlagDir dir, int index, string newName) {
		super (v, comm, dir);
		_name = newName;
		auto p = FlagTable.fromIndex(dir, index);
		auto f = cast(Flag) p;
		if (f) _f = new Flag(f);
		auto s = cast(Step) p;
		if (s) _f = new Step(s);
	}
	private void impl() {
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		auto fB = _f;
		auto dir = this.dir();
		assert (dir);
		if (cast(Flag)fB) {
			auto f = dir.getFlag(_name);
			_f = new Flag(f);
			auto o = cast(Flag) fB;
			assert (o);
			_name = o.name;
			bool refVal = o.on != f.on || o.off != f.off;
			auto oPath = f.path;
			f.copyFrom(o);
			auto nPath = f.path;
			refVal |= oPath != nPath;
			if (oPath != nPath) {
				comm.summary.useCounter.change(toFlagId(oPath), toFlagId(nPath));
			}
			if (refVal) {
				comm.refFlagAndStep.call([f], []);
			}
		} else {
			assert (cast(Step)fB);
			auto s = dir.getStep(_name);
			_f = new Step(s);
			auto o = cast(Step) fB;
			assert (o);
			_name = o.name;
			bool refVal = o.values != s.values;
			auto oPath = s.path;
			s.copyFrom(o);
			auto nPath = s.path;
			refVal |= oPath != nPath;
			if (oPath != nPath) {
				comm.summary.useCounter.change(toStepId(oPath), toStepId(nPath));
			}
			if (refVal) {
				comm.refFlagAndStep.call([], [s]);
			}
		}
		if (v && v.flags && !v.flags.isDisposed()) {
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
	private Flag[] _fs;
	private Step[] _ss;

	/// 追加を元に戻す。
	this (FlagTable v, Commons comm, FlagDir dir, int[] selected, int[] dirIndices, string[] flagName, string[] stepName) {
		super (v, comm, dir);
		_selected = selected.dup;
		_dirIndices = dirIndices.dup;
		_flagName = flagName.dup;
		_stepName = stepName.dup;
		_insert = true;
	}
	/// 削除を元に戻す。
	this (FlagTable v, Commons comm, FlagDir dir, int[] selected, FlagDir[int] ds, Flag[] fs, Step[] ss) {
		super (v, comm, dir);
		_selected = selected.dup;
		save(ds, fs, ss);
		_insert = false;
	}
	private void save(FlagDir[int] ds, Flag[] fs, Step[] ss) {
		_ds = ds;
		foreach (index, d; _ds) {
			_ds[index] = new FlagDir(d);
		}
		_fs.length = 0;
		foreach (f; fs) {
			_fs ~= new Flag(f);
		}
		_ss.length = 0;
		foreach (s; ss) {
			_ss ~= new Step(s);
		}
	}
	private void undoInsert(FlagTable v) {
		_insert = false;
		FlagDir[int] ds;
		Flag[] fs;
		Step[] ss;
		auto dir = this.dir();
		foreach (i; _dirIndices) {
			auto d = dir.subDirs[i];
			if (d) ds[i] = d;
		}
		foreach (n; _flagName) {
			auto f = dir.getFlag(n);
			if (f) fs ~= f;
		}
		foreach (n; _stepName) {
			auto s = dir.getStep(n);
			if (s) ss ~= s;
		}
		save(ds, fs, ss);
		foreach (f; fs) {
			dir.remove(f);
		}
		foreach (s; ss) {
			dir.remove(s);
		}
		foreach (d; ds) {
			dir.remove(d);
			fs ~= d.allFlags;
			ss ~= d.allSteps;
		}
		if (v && v.flags && !v.flags.isDisposed()) {
			v.refresh();
		}
		if (ds.length) comm.delFlagDir.call(ds.values);
		if (fs.length || ss.length) comm.delFlagAndStep.call(fs, ss);
	}
	private void undoDelete(FlagTable v) {
		_insert = true;
		auto dir = this.dir();
		_dirIndices.length = 0;
		_flagName.length = 0;
		_stepName.length = 0;
		selDir = (_ds.length == 1 && !_fs.length && !_ss.length) ? _ds.values[0] : null;
		foreach (f; _fs) {
			_flagName ~= f.name;
			dir.add(f);
		}
		foreach (s; _ss) {
			_stepName ~= s.name;
			dir.add(s);
		}
		foreach (index; _ds.keys.sort) {
			auto d = _ds[index];
			_dirIndices ~= index;
			dir.insert(index, d);
			_fs ~= d.allFlags;
			_ss ~= d.allSteps;
		}
		if (v && v.flags && !v.flags.isDisposed()) {
			v.refresh();
		}
		if (_ds.length) comm.refFlagDir.call(_ds.values);
		if (_fs.length || _ss.length) comm.refFlagAndStep.call(_fs, _ss);
	}
	override void undo() {
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		undoImpl(v);
	}
	private void undoImpl(FlagTable v) {
		if (_insert) {
			undoInsert(v);
		} else {
			undoDelete(v);
		}
	}
	override void redo() {
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		redoImpl(v);
	}
	private void redoImpl(FlagTable v) {
		undoImpl(v);
	}
	override void dispose() {}
}
package class UndoMove : FTVUndo {
	private UndoInsertDelete _dir1;
	private UndoInsertDelete _dir2;
	private string[string] _cFlags;
	private string[string] _cSteps;

	this (FlagTable v, Commons comm, int[] selected, FlagDir to, int[] dirIndices, string[] flagName, string[] stepName, FlagDir from, FlagDir[int] ds, Flag[] fs, Step[] ss, Flag[string] cFlags, Step[string] cSteps) {
		super (v, comm, from);
		_selected = selected.dup;
		assert (dirIndices.length == ds.length);
		assert (flagName.length == fs.length);
		assert (stepName.length == ss.length);
		_dir1 = new UndoInsertDelete(v, comm, to, selected, dirIndices, flagName, stepName);
		_dir2 = new UndoInsertDelete(v, comm, from, selected, ds, fs, ss);
		foreach (oPath, flag; cFlags) {
			_cFlags[oPath] = flag.path;
		}
		foreach (oPath, step; cSteps) {
			_cSteps[oPath] = step.path;
		}
	}
	private void change(FlagTable v) {
		string[string] cFlags;
		string[string] cSteps;
		foreach (nPath, oPath; _cFlags) {
			cFlags[oPath] = nPath;
			comm.summary.useCounter.change(toFlagId(oPath), toFlagId(nPath));
		}
		foreach (nPath, oPath; _cSteps) {
			cSteps[oPath] = nPath;
			comm.summary.useCounter.change(toStepId(oPath), toStepId(nPath));
		}
		_cFlags = cFlags;
		_cSteps = cSteps;
		if (v && v.flags && !v.flags.isDisposed()) {
			v.__refreshUseCount();
		}
	}
	override void undo() {
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		_dir1.undoImpl(v);
		_dir2.undoImpl(v);
		change(v);
	}
	override void redo() {
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		_dir2.redoImpl(v);
		_dir1.redoImpl(v);
		change(v);
	}
	override void dispose() {
		_dir1.dispose();
		_dir2.dispose();
	}
}
package class UndoEditDir : FTVUndo {
	private string _oldName;
	this (FlagTable v, Commons comm, FlagDir dir, string oldName) {
		super (v, comm, dir);
		_oldName = oldName;
	}
	private void impl() {
		auto v = view();
		udb(v);
		scope (exit) uda(v);
		auto dir = this.dir();

		string oldName = dir.name;
		dir.rename(_oldName, comm.summary.useCounter);
		_oldName = oldName;

		comm.refFlagDir.call([dir]);
	}
	override void undo() {impl();}
	override void redo() {impl();}
	override void dispose() {}
}
package class UndoSwap : FTVUndo {
	private FlagDir _parent;
	private int _index1, _index2;
	this (FlagTable v, Commons comm, FlagDir dir, FlagDir parent, int index1, int index2) {
		super (v, comm, dir);
		_parent = parent;
		_index1 = index1;
		_index2 = index2;
	}
	private void impl() {
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
	void storeEdit(int index, string newName) {
		_undo ~= new UndoEdit(this, _comm, _dir, index, newName);
	}
	void storeInsert(int[] selected, string[] flagName, string[] stepName) {
		_undo ~= new UndoInsertDelete(this, _comm, _dir, selected, [], flagName, stepName);
	}
	void storeDelete(int[] selected, Flag[] fs, Step[] ss) {
		FlagDir[int] ds;
		_undo ~= new UndoInsertDelete(this, _comm, _dir, selected, ds, fs, ss);
	}

	static int indexOf(FlagDir dir, CWXPath p) {
		int i = 0;
		foreach (s; dir.steps) {
			if (s is p) {
				return i;
			}
			i++;
		}
		foreach (f; dir.flags) {
			if (f is p) {
				return i;
			}
			i++;
		}
		return -1;
	}
	static CWXPath fromIndex(FlagDir dir, int index) {
		if (dir.steps.length <= index) {
			return dir.flags[index - dir.steps.length];
		}
		return dir.steps[index];
	}
	static int toFlagIndex(FlagDir dir, int index) {
		return index - dir.steps.length;
	}
	static int toStepIndex(FlagDir dir, int index) {
		return index;
	}

	static const NAME = 0;
	static const VALUE = 1;
	static const UC = 2;
	void refreshFlags() {
		if (_dir) {
			int i = 0;
			foreach (f; _dir.steps) {
				TableItem itm;
				if (i < flags.getItemCount()) {
					itm = flags.getItem(i);
				} else {
					itm = new TableItem(flags, SWT.NONE);
				}
				itm.setImage(0, prop.images.step);
				itm.setText(NAME, f.name);
				itm.setText(VALUE, f.value);
				itm.setText(UC, to!(string)(uc.get(toStepId(f.path))));
				itm.setData(f);
				i++;
			}
			foreach (f; _dir.flags) {
				TableItem itm;
				if (i < flags.getItemCount()) {
					itm = flags.getItem(i);
				} else {
					itm = new TableItem(flags, SWT.NONE);
				}
				itm.setImage(0, prop.images.flag);
				itm.setText(NAME, f.name);
				itm.setText(VALUE, f.onOff ? f.on : f.off);
				itm.setText(UC, to!(string)(uc.get(toFlagId(f.path))));
				itm.setData(f);
				i++;
			}
			if (i < flags.getItemCount()) {
				flags.remove(i, flags.getItemCount() - 1);
			}
		} else {
			flags.removeAll();
		}
	}

	Props prop;
	Commons _comm;
	UseCounter uc;

	Table flags;

	FlagDir _dir = null;
	string _statusLine = "";

	FlagEditDialog[Flag] _editDlgsF;
	StepEditDialog[Step] _editDlgsS;

	UndoManager _undo;

	void editFlag(FlagDir parent, Flag flag) {
		bool createMode = flag is null;
		string old = createMode ? null : flag.path;
		if (!flag) {
			string on = prop.var.etc.flagTrues.length > 0 ? prop.var.etc.flagTrues[0] : "";
			string off = prop.var.etc.flagFalses.length > 0 ? prop.var.etc.flagFalses[0] : "";
			flag = new Flag("", on, off, true);
		}
		auto p = flag in _editDlgsF;
		if (p) {
			p.active();
			return;
		}
		auto dlg = new FlagEditDialog(_comm, prop, dlgParShl, parent, flag);
		dlg.applyEvent ~= {
			int i = indexOf(parent, flag);
			if (-1 != i) {
				assert (!createMode);
				storeEdit(i, dlg.name);
			}
		};
		dlg.appliedEvent ~= {
			auto flag = dlg.flag;
			if (old && old != flag.path) uc.change(toFlagId(old), toFlagId(flag.path), true);
			if (createMode) {
				int[] indices;
				if (flags && !flags.isDisposed()) {
					indices = flags.getSelectionIndices();
				}
				storeInsert(indices, [flag.name], []);
				createMode = false;
			}
			_comm.openCWXPath(flag.cwxPath(true), false);
			refresh(flag.name);
			_comm.refFlagAndStep.call([flag], []);
			_comm.refreshToolBar();
		};
		_editDlgsF[flag] = dlg;
		dlg.closeEvent ~= {
			_editDlgsF.remove(flag);
		};
		dlg.open();
	}
	void editStep(FlagDir parent, Step step) {
		bool createMode = step is null;
		string old = createMode ? null : step.path;
		if (!step) {
			string[] vals;
			foreach (i; 0 .. prop.looks.stepMaxCount) {
				vals ~= .tryFormat(prop.msgs.dlgTxtStep, i);
			}
			step = new Step("", vals, 0);
		}
		auto p = step in _editDlgsS;
		if (p) {
			p.active();
			return;
		}
		auto dlg = new StepEditDialog(_comm, prop, dlgParShl, parent, step);
		dlg.applyEvent ~= {
			int i = indexOf(parent, step);
			if (-1 != i) {
				assert (!createMode);
				storeEdit(i, dlg.name);
			}
		};
		dlg.appliedEvent ~= {
			auto step = dlg.step;
			if (old && old != step.path) uc.change(toStepId(old), toStepId(step.path), true);
			if (createMode) {
				int[] indices;
				if (flags && !flags.isDisposed()) {
					indices = flags.getSelectionIndices();
				}
				storeInsert(indices, [step.name], []);
				createMode = false;
			}
			_comm.openCWXPath(step.cwxPath(true), false);
			refresh(step.name);
			_comm.refFlagAndStep.call([], [step]);
			_comm.refreshToolBar();
		};
		_editDlgsS[step] = dlg;
		dlg.closeEvent ~= {
			_editDlgsS.remove(step);
		};
		dlg.open();
	}

	class MListener : MouseAdapter {
	public:
		override void mouseDoubleClick(MouseEvent e) {
			if (e.button == 1) {
				edit();
			}
		}
	}
	class KListener : KeyAdapter {
	public:
		override void keyPressed(KeyEvent e) {
			if (e.character == SWT.CR) {
				edit();
			}
		}
	}

	/// 選択中のフラグとステップを取得する。
	/// Params:
	/// fs = 選択中のフラグの配列が格納される。
	/// ss = 選択中のステップの配列が格納される。
	/// Returns: 選択中ならtrue。
	bool getSelectionFlagAndStep(out Flag[] fs, out Step[] ss) {
		auto indices = flags.getSelectionIndices();
		if (indices.length > 0) {
			foreach (i; indices) {
				if (i < _dir.steps.length) {
					ss ~= _dir.steps[i];
				} else {
					fs ~= _dir.flags[i - _dir.steps.length];
				}
			}
			return true;
		} else {
			return false;
		}
	}

	Flag[] _dragFlags;
	Step[] _dragSteps;
	class FlagDragListener : DragSourceListener {
	private:
		int[] dragIndices;
	public:
		override void dragStart(DragSourceEvent e) {
			e.doit = flags.getSelectionCount() > 0;
		}
		override void dragSetData(DragSourceEvent e) {
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) {
				// XML化して転送する。
				getSelectionFlagAndStep(_dragFlags, _dragSteps);
				e.data = bytesFromXML(getXML(_dir, _dragFlags, _dragSteps));
			}
		}
		override void dragFinished(DragSourceEvent e) {
			if (e.detail == DND.DROP_MOVE) {
				foreach (flag; _dragFlags) {
					flag.parent.remove(flag);
				}
				foreach (step; _dragSteps) {
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
	void flagsSelected() {
		refreshStatusLine();
		_comm.refreshToolBar();
	}
	class SListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			flagsSelected();
		}
	}
	class DListener : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refUseCount.remove(&__refreshUseCount);
			_comm.replText.remove(&refresh);
		}
	}
	void nameEditEnd(TableItem itm, int column, string text) {
		text = FlagDir.validName(text);
		auto f = cast(Flag) itm.getData();
		if (f) {
			if (0 == icmp(f.name, text)) return;
			auto newName = f.parent.createNewFlagName(text, f.name);
			storeEdit(itm.getParent().indexOf(itm), newName);
			auto oldId = toFlagId(f.path);
			f.name = newName;
			uc.change(oldId, toFlagId(f.path), true);
			refresh();
			_comm.refFlagAndStep.call([f], []);
			_comm.refreshToolBar();
			return;
		}
		auto s = cast(Step) itm.getData();
		if (s) {
			if (0 == icmp(s.name, text)) return;
			auto newName = s.parent.createNewStepName(text, s.name);
			storeEdit(itm.getParent().indexOf(itm), newName);
			auto oldId = toStepId(s.path);
			s.name = newName;
			uc.change(oldId, toStepId(s.path), true);
			refresh();
			_comm.refFlagAndStep.call([], [s]);
			_comm.refreshToolBar();
			return;
		}
	}
	void initCombo(TableItem itm, int column, out string[] strs, out string str) {
		auto f = cast(Flag) itm.getData();
		if (f) {
			strs = [f.on, f.off];
			str = f.onOff ? f.on : f.off;
			return;
		}
		auto s = cast(Step) itm.getData();
		if (s) {
			foreach (i, v; s.values) {
				strs ~= v;
				if (i == s.select) {
					str = v;
				}
			}
			return;
		}
	}
	void initEditEnd(TableItem itm, int column, CCombo combo) {
		int i = combo.getSelectionIndex();
		if (-1 == i) return;
		auto f = cast(Flag) itm.getData();
		if (f) {
			if (f.onOff == (0 == i)) return;
			storeEdit(flags.indexOf(itm), f.name);
			f.onOff = 0 == i;
			itm.setText(column, f.onOff ? f.on : f.off);
			_comm.refFlagAndStep.call([f], []);
			_comm.refreshToolBar();
			return;
		}
		auto s = cast(Step) itm.getData();
		if (s) {
			if (s.select == i) return; 
			storeEdit(flags.indexOf(itm), s.name);
			s.select(i);
			itm.setText(column, s.value);
			_comm.refFlagAndStep.call([], [s]);
			_comm.refreshToolBar();
			return;
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			foreach (dlg; _editDlgsF.values) {
				dlg.forceCancel();
			}
			foreach (dlg; _editDlgsS.values) {
				dlg.forceCancel();
			}
		}
	}
	@property
	Shell dlgParShl() {
		if (flags && !flags.isDisposed()) return flags.getShell();
		return _comm.mainWin.shell.getShell();
	}
	void selectAll() {
		foreach (i; 0 .. flags.getItemCount()) {
			flags.select(i);
		}
		flagsSelected();
	}
public:
	this (Commons comm, Props prop, UndoManager undo) {
		_undo = undo;
		_comm = comm;
		this.prop = prop;
	}

	/// コントロールを生成する。
	/// Params:
	/// parent = 親コントロール。
	Control createControl(Composite parent) {
		_comp = new Composite(parent, SWT.NONE);
		_comp.setLayout(new FillLayout);
		flags = new Table(_comp, SWT.MULTI | SWT.BORDER | SWT.FULL_SELECTION);
		flags.setHeaderVisible(true);
		auto nameCol = new TableColumn(flags, SWT.NULL);
		nameCol.setText(prop.msgs.flagName);
		saveColumnWidth!("prop.var.etc.flagNameColumn")(prop, nameCol);
		auto initCol = new TableColumn(flags, SWT.NULL);
		initCol.setText(prop.msgs.flagInit);
		saveColumnWidth!("prop.var.etc.flagInitColumn")(prop, initCol);
		auto countCol = new TableColumn(flags, SWT.NULL);
		countCol.setText(prop.msgs.flagCount);
		saveColumnWidth!("prop.var.etc.flagCountColumn")(prop, countCol);

		flags.addKeyListener(new KListener);
		flags.addMouseListener(new MListener);
		auto menu = new Menu(flags.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.EditProp, &edit, () => flags.getSelectionIndex() != -1);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.Undo, &this.undo, &_undo.canUndo);
		createMenuItem(_comm, menu, MenuID.Redo, &this.redo, &_undo.canRedo);
		new MenuItem(menu, SWT.SEPARATOR);
		appendMenuTCPD(_comm, menu, this, true, true, true, true, true);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.SelectAll, &selectAll, () => flags.getItemCount() && flags.getSelectionCount() != flags.getItemCount());
		flags.setMenu(menu);

		auto ds = new DragSource(flags, DND.DROP_MOVE | DND.DROP_COPY);
		ds.setTransfer([XMLBytesTransfer.getInstance()]);
		ds.addDragListener(new FlagDragListener);

		_comm.refUseCount.add(&__refreshUseCount);
		_comm.replText.add(&refresh);
		flags.addSelectionListener(new SListener);
		flags.addDisposeListener(new DListener);

		new TableTextEdit(_comm, prop, flags, 0, &nameEditEnd, null);
		new TableComboEdit!CCombo(_comm, prop, flags, 1, &initCombo, &initEditEnd, null);

		_comp.addDisposeListener(new Dispose);

		return _comp;
	}
	private Composite _comp = null;
	@property
	Control widget() {return _comp;}

	@property
	package Flag[] dragFlags() {return _dragFlags;}
	@property
	package Step[] dragSteps() {return _dragSteps;}

	private void refreshStatusLine() {
		string s = "";
		void put(lazy string name, size_t count) {
			if (!count) return;
			if (s.length) s ~= " ";
			s ~= .tryFormat(prop.msgs.flagStatus, name, count);
		}
		if (_dir) {
			put(prop.msgs.flag, _dir.flags.length);
			put(prop.msgs.step, _dir.steps.length);
		}
		Flag[] selFlags;
		Step[] selSteps;
		getSelectionFlagAndStep(selFlags, selSteps);
		if (selFlags.length || selSteps.length) {
			s = .tryFormat(prop.msgs.flagStatusSel, s, selFlags.length + selSteps.length);
		}
		_statusLine = s;
		_comm.setStatusLine(flags, _statusLine);
	}
	@property
	string statusLine() {return _statusLine;}

	private void __refreshUseCount() {
		foreach (itm; flags.getItems()) {
			if (cast(Flag) itm.getData()) {
				itm.setText(2, to!(string)(uc.flag.get(toFlagId((cast(Flag) itm.getData()).path))));
			} else {
				assert (cast(Step) itm.getData());
				itm.setText(2, to!(string)(uc.step.get(toStepId((cast(Step) itm.getData()).path))));
			}
		}
	}
	void refresh() {
		refresh(null);
	}
	void refresh(string selName) {
		if (!flags || flags.isDisposed()) return;
		if (_dir) {
			string[] sels;
			if (selName) {
				sels ~= selName;
			} else {
				foreach (itm; flags.getSelection()) {
					sels ~= itm.getText(NAME);
				}
			}
			flags.deselectAll();
			_dir.sortSteps();
			_dir.sortFlags();
			refreshFlags();
			foreach (i, itm; flags.getItems()) {
				if (contains(sels, itm.getText(NAME))) {
					flags.select(i);
				}
			}
			if (selName) {
				flags.showSelection();
			}
		}
		refreshStatusLine();
	}
	/// 表示上で選択されているindex。
	@property
	int[] selected() {
		if (flags && !flags.isDisposed()) {
			return flags.getSelectionIndices();
		}
		return [];
	}
	/// 表示上で選択されているフラグまたはステップ。
	int[] selectedItems(out Flag[] fs, out Step[] ss) {
		if (flags && !flags.isDisposed()) {
			auto indices = flags.getSelectionIndices();
			foreach (i; indices) {
				auto o = flags.getItem(i).getData();
				auto f = cast(Flag) o;
				if (f) fs ~= f;
				auto s = cast(Step) o;
				if (s) ss ~= s;
			}
			return indices;
		}
		return [];
	}

	/// フラグ生成のダイアログボックスを開く。
	/// 適切に設定された場合、新規フラグを生成する。
	void createFlag() {
		editFlag(_dir, null);
	}

	/// ステップ生成のダイアログボックスを開く。
	/// 適切に設定された場合、新規ステップを生成する。
	void createStep() {
		editStep(_dir, null);
	}

	/// 選択中のフラグ・ステップの編集を開始する。
	void edit() {
		if (_dir !is null) {
			foreach (index; flags.getSelectionIndices()) {
				if (index < _dir.steps.length) {
					auto step = _dir.steps[index];
					editStep(step.parent, step);
				} else {
					auto flag = _dir.flags[index - _dir.steps.length];
					editFlag(flag.parent, flag);
				}
			}
		}
	}
	/// 指定されたフラグの編集を開始する。
	void edit(Flag flag) {
		enforce(flag.parent is dir);
		editFlag(flag.parent, flag);
	}
	/// 指定されたステップの編集を開始する。
	void edit(Step step) {
		enforce(step.parent is dir);
		editStep(step.parent, step);
	}

	/// 編集対象のディレクトリを設定する。
	/// Params:
	/// dir = ディレクトリ。
	void setDir(FlagDir dir, bool forceRefresh = false) {
		if (!forceRefresh && _dir is dir) return;
		foreach (dlg; _editDlgsF.values) {
			dlg.forceCancel();
		}
		foreach (dlg; _editDlgsS.values) {
			dlg.forceCancel();
		}
		_dir = dir;
		refresh();
	}

	/// Returns: 編集対象のディレクトリ。
	@property
	FlagDir dir() {
		return _dir;
	}

	private void selectImpl(Object flag, bool deselect) {
		if (deselect) flags.deselectAll();
		foreach (i, itm; flags.getItems()) {
			if (itm.getData() is flag) {
				flags.select(i);
				break;
			}
		}
		flags.showSelection();
		_comm.refreshToolBar();
	}
	/// フラグを選択する。
	void select(Flag flag, bool deselect) {
		selectImpl(flag, deselect);
	}
	/// ステップを選択する。
	void select(Step step, bool deselect) {
		selectImpl(step, deselect);
	}

	/// コントロールを解放する。
	void dispose() {
		if (flags !is null) {
			flags.dispose();
		}
	}

	/// 使用回数カウンタを設定する。
	/// Params:
	/// uc = 使用回数カウンタ。
	@property
	void useCounter(UseCounter uc) {
		this.uc = uc;
	}

	override {
		void cut(SelectionEvent se) {
			if (!_dir) return;
			copy(se);
			del(se);
		}
		void copy(SelectionEvent se) {
			if (!_dir) return;
			Flag[] fs;
			Step[] ss;
			if (getSelectionFlagAndStep(fs, ss)) {
				XMLtoCB(prop, _comm.clipboard, getXML(_dir, fs, ss));
				_comm.refreshToolBar();
			}
		}
		void paste(SelectionEvent se) {
			if (!_dir) return;
			auto c = CBtoXML(_comm.clipboard);
			if (c) {
				try {
					string newPath;
					string rootId;
					Flag[string] cFlags;
					Step[string] cSteps;
					auto sels = flags.getSelectionIndices();
					if (_dir.appendFromXML(c, LATEST_VERSION,
							true, false, cFlags, cSteps, newPath, rootId)) {
						string[] flagName;
						string[] stepName;
						foreach (f; cFlags) {
							flagName ~= f.name;
						}
						foreach (s; cSteps) {
							stepName ~= s.name;
						}
						storeInsert(sels, flagName, stepName);
						refresh();
						_comm.refFlagAndStep.call(cFlags.values, cSteps.values);
						_comm.refreshToolBar();
					}
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		void del(SelectionEvent se) {
			if (!_dir) return;
			auto sels = flags.getSelectionIndices();
			Flag[] fs;
			Step[] ss;
			foreach (itm; flags.getSelection()) {
				auto data = itm.getData();
				auto flag = cast(Flag) data;
				if (flag) {
					fs ~= flag;
					_dir.remove(flag);
				}
				auto step = cast(Step) data;
				if (step) {
					ss ~= step;
					_dir.remove(step);
				}
			}
			storeDelete(sels, fs, ss);
			_comm.delFlagAndStep.call(fs, ss);
			refresh();
			_comm.refreshToolBar();
		}
		void clone(SelectionEvent se) {
			_comm.clipboard.memoryMode = true;
			scope (exit) _comm.clipboard.memoryMode = false;
			copy(se);
			paste(se);
		}
		@property
		bool canDoTCPD() {
			return _comm.summary && flags.isFocusControl();
		}
		@property
		bool canDoT() {
			return flags.getSelectionIndex() != -1;
		}
		@property
		bool canDoC() {
			return canDoT;
		}
		@property
		bool canDoP() {
			return _comm.summary !is null && CBisXML(_comm.clipboard);
		}
		@property
		bool canDoD() {
			return canDoT;
		}
		@property
		bool canDoClone() {
			return canDoC;
		}
	}
	void undo() {
		_undo.undo();
		_comm.refreshToolBar();
	}
	void redo() {
		_undo.redo();
		_comm.refreshToolBar();
	}

	@property
	string[] openedCWXPath() {
		string[] r;
		Flag[] fs;
		Step[] ss;
		getSelectionFlagAndStep(fs, ss);
		foreach (f; fs) {
			r ~= f.cwxPath(true);
		}
		foreach (s; ss) {
			r ~= s.cwxPath(true);
		}
		return r;
	}
}
