
module cwx.editor.gui.dwt.flagtable;

import cwx.flag;
import cwx.utils;
import cwx.usecounter;

import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;

import dwt.DWT;
import dwt.DWTException;
import dwt.widgets.Shell;
import dwt.widgets.Control;
import dwt.widgets.Display;
import dwt.layout.FillLayout;
import dwt.layout.GridLayout;
import dwt.layout.GridData;
import dwt.custom.SashForm;
import dwt.widgets.Composite;
import dwt.widgets.Tree;
import dwt.widgets.TreeItem;
import dwt.widgets.Menu;
import dwt.widgets.MenuItem;
import dwt.dnd.Clipboard;
import dwt.custom.TreeEditor;
import dwt.widgets.Table;
import dwt.widgets.TableColumn;
import dwt.widgets.TableItem;
import dwt.widgets.Text;
import dwt.widgets.Label;
import dwt.widgets.Combo;
import dwt.widgets.Table;
import dwt.widgets.Widget;
import dwt.events.SelectionEvent;
import dwt.events.SelectionAdapter;
import dwt.events.FocusEvent;
import dwt.events.FocusListener;
import dwt.events.KeyListener;
import dwt.events.KeyAdapter;
import dwt.events.KeyEvent;
import dwt.events.MouseListener;
import dwt.events.MouseAdapter;
import dwt.events.MouseEvent;
import dwt.events.ModifyListener;
import dwt.events.ModifyEvent;
import dwt.events.FocusAdapter;
import dwt.events.FocusEvent;
import dwt.events.DisposeListener;
import dwt.events.DisposeEvent;
import dwt.graphics.Image;
import dwt.graphics.ImageData;
import dwt.dwthelper.utils;
import dwt.dnd.DND;
import dwt.dnd.Transfer;
import dwt.dnd.TransferData;
import dwt.dnd.DragSource;
import dwt.dnd.DragSourceListener;
import dwt.dnd.DragSourceEvent;
import dwt.dnd.ByteArrayTransfer;
import dwt.dnd.DropTargetAdapter;
import dwt.dnd.DropTargetEvent;
import dwt.dnd.DropTarget;

/// ステップ設定用のダイアログ。
/// 値は強制的に10件になる。
public class StepEditDialog : AbsDialog {
private:
	Props prop;
	Step _step;
	FlagDir dir;

	Text stepName;
	Combo stepInit;
	Text[] stepVals;

	class ModValue : ModifyListener {
	private:
		int index;
	public:
		this(int index) {
			this.index = index;
		}
		override void modifyText(ModifyEvent e) {
			if (index < stepInit.getItemCount) {
				stepInit.setItem(index, (cast(Text) e.getSource).getText);
			}
		}
	}
public:
	/// Params:
	/// prop = 設定情報。
	/// shell = 親ウィンドウ。
	/// dir = 設定するステップの親ディレクトリ。
	/// step = 設定するステップ。新規の場合はnull。
	this(Props prop, Shell shell, FlagDir dir, Step step = null) {
		assert (step is null || step.parent == dir);
		super(prop, shell, prop.msgs.dlgTitStep, prop.images.step, true, prop.var.stepDlg);
		this.prop = prop;
		this.dir = dir;
		this._step = step;
		enterClose = true;
	}

	/// Returns: 編集対象となったステップ。
	Step step() {
		return _step;
	}
protected:
	override void setup(Composite area) {
		area.setLayout = zeroGridLayout(1);
		{
			auto comp = new Composite(area, DWT.NULL);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comp.setLayout = new GridLayout(5, false);

			(new Label(comp, DWT.NULL)).setText = prop.msgs.dlgLblStepName;
			stepName = new Text(comp, DWT.BORDER);
			setGridMinW(stepName, prop.var.etc.flagNameWidth, GridData.FILL_HORIZONTAL);
			checker(stepName);

			auto gd = new GridData(GridData.FILL_VERTICAL);
			gd.heightHint = 0;
			(new Label(comp, DWT.SEPARATOR | DWT.VERTICAL)).setLayoutData(gd);

			(new Label(comp, DWT.NULL)).setText = prop.msgs.dlgLblStepInit;
			stepInit = new Combo(comp, DWT.READ_ONLY);
			stepInit.setVisibleItemCount = 20;
			setGridMinW(stepInit, prop.var.etc.flagInitWidth);
		}
		(new Label(area, DWT.SEPARATOR | DWT.HORIZONTAL))
			.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		{
			auto comp = new Composite(area, DWT.NULL);
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
						(new Label(comp, DWT.SEPARATOR | DWT.VERTICAL)).setLayoutData(gd);
						gdc++;
					}
					valsComp = new Composite(comp, DWT.NULL);
					valsComp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
					valsComp.setLayout = new GridLayout(2, false);
					gdc++;
				}
				(new Label(valsComp, DWT.NULL)).setText = prop.msgs.dlgLblStep(i);
				stepVals ~= new Text(valsComp, DWT.BORDER);
				stepVals[i].addModifyListener(new ModValue(i));
				stepVals[i].addFocusListener(new class FocusAdapter {
					override void focusGained(FocusEvent e) {
						auto text = cast(Text) e.widget;
						text.selectAll;
					}
				});
				setGridMinW(stepVals[i], prop.var.etc.flagValueWidth, GridData.FILL_HORIZONTAL);
			}
			comp.setLayout = new GridLayout(gdc, false);
		}

		string[] vals;
		if (_step !is null) {
			stepName.setText = _step.name;
			foreach (i, stepVal; stepVals) {
				if (i < _step.count) {
					stepVal.setText(_step.getValue(i));
				} else {
					stepVal.setText(prop.msgs.dlgTxtStep(i));
				}
				vals ~= stepVal.getText;
			}
		} else {
			stepName.setText = "";
			foreach (i, stepVal; stepVals) {
				stepVal.setText(prop.msgs.dlgTxtStep(i));
				vals ~= stepVal.getText;
			}
		}
		stepName.selectAll;
		stepInit.setItems(vals);
		stepInit.select(_step is null ? 0 : _step.select);
	}

	override bool close(bool ok) {
		if (ok) {
			string[] vals;
			foreach (stepVal; stepVals) {
				vals ~= stepVal.getText;
			}
			if (_step !is null) {
				_step.name = stepName.getText;
				_step.setValues(vals, stepInit.getSelectionIndex);
			} else {
				auto name = FlagDir.validName(stepName.getText);
				name = dir.createNewStepName(name);
				_step = new Step(name, vals, stepInit.getSelectionIndex);
				dir.add(_step);
			}
		}
		return ok;
	}
}

/// フラグ設定用のダイアログ。
public class FlagEditDialog : AbsDialog {
private:
	Props prop;
	Flag _flag;
	FlagDir dir;

	Text flagName;
	Combo flagInit;
	Combo flagTrue;
	Combo flagFalse;

	class ModOnOff : SelectionAdapter, ModifyListener {
	private:
		int index;
		void change(EventObject e) {
			if (index < flagInit.getItemCount) {
				flagInit.setItem(index, (cast(Combo) e.getSource).getText);
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
public:
	/// Params:
	/// prop = 設定情報。
	/// shell = 親ウィンドウ。
	/// dir = 設定するフラグの親ディレクトリ。
	/// flag = 設定するフラグ。新規の場合はnull。
	this(Props prop, Shell shell, FlagDir dir, Flag flag = null) {
		assert (flag is null || flag.parent == dir);
		super(prop, shell, prop.msgs.dlgTitFlag, prop.images.flag, true, prop.var.flagDlg);
		this.prop = prop;
		this._flag = flag;
		this.dir = dir;
		enterClose = true;
	}

	/// Returns: 編集対象となったフラグ。
	Flag flag() {
		return _flag;
	}
protected:
	private static void setMinW(Control c, int minW, int gridStyle = DWT.NULL) {
		auto gd = new GridData(gridStyle);
		int w = c.computeSize(DWT.DEFAULT, DWT.DEFAULT).x;
		gd.widthHint = w > minW ? w : minW;
		c.setLayoutData(gd);
	}

	override void setup(Composite area) {
		area.setLayout = zeroGridLayout(1);
		{
			auto comp = new Composite(area, DWT.NULL);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comp.setLayout = new GridLayout(5, false);

			(new Label(comp, DWT.NULL)).setText = prop.msgs.dlgLblFlagName;
			flagName = new Text(comp, DWT.BORDER);
			setGridMinW(flagName, prop.var.etc.flagNameWidth, GridData.FILL_HORIZONTAL);
			checker(flagName);

			auto gd = new GridData(GridData.FILL_VERTICAL);
			gd.heightHint = 0;
			(new Label(comp, DWT.SEPARATOR | DWT.VERTICAL)).setLayoutData(gd);

			(new Label(comp, DWT.NULL)).setText = prop.msgs.dlgLblFlagInit;
			flagInit = new Combo(comp, DWT.READ_ONLY);
			setGridMinW(flagInit, prop.var.etc.flagInitWidth);
		}
		(new Label(area, DWT.SEPARATOR | DWT.HORIZONTAL))
			.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		{
			auto ocomp = new Composite(area, DWT.NONE);
			ocomp.setLayoutData(new GridData(GridData.FILL_BOTH));
			auto cl = new CenterLayout(DWT.HORIZONTAL | DWT.VERTICAL, 0);
			cl.fillHorizontal = true;
			ocomp.setLayout = cl;
			auto comp = new Composite(ocomp, DWT.NONE);
			comp.setLayout(new GridLayout(2, false));

			(new Label(comp, DWT.NULL)).setText = prop.msgs.dlgLblFlagTrue;
			flagTrue = new Combo(comp, DWT.NULL);
			flagTrue.setItems(prop.var.etc.flagTrues);
			flagTrue.setVisibleItemCount = 20;
			auto tmod = new ModOnOff(0);
			flagTrue.addModifyListener = tmod;
			flagTrue.addSelectionListener = tmod;
			setGridMinW(flagTrue, prop.var.etc.flagValueWidth, GridData.FILL_HORIZONTAL);

			(new Label(comp, DWT.NULL)).setText = prop.msgs.dlgLblFlagFalse;
			flagFalse = new Combo(comp, DWT.NULL);
			flagFalse.setItems(prop.var.etc.flagFalses);
			flagFalse.setVisibleItemCount = 20;
			auto fmod = new ModOnOff(1);
			flagFalse.addModifyListener = fmod;
			flagFalse.addSelectionListener = fmod;
			setGridMinW(flagFalse, prop.var.etc.flagValueWidth, GridData.FILL_HORIZONTAL);
		}

		if (_flag !is null) {
			flagName.setText = _flag.name;
			flagTrue.setText = _flag.on;
			flagFalse.setText = _flag.off;
			flagInit.setItems([flagTrue.getText, flagFalse.getText]);
			flagInit.select = _flag.onOff ? 0 : 1;
		} else {
			flagName.setText = "";
			flagTrue.setText = prop.var.etc.flagTrues.length > 0 ? prop.var.etc.flagTrues[0] : "";
			flagFalse.setText = prop.var.etc.flagFalses.length > 0 ? prop.var.etc.flagFalses[0] : "";
			flagInit.setItems([flagTrue.getText, flagFalse.getText]);
			flagInit.select = 0;
		}
		flagName.selectAll;
	}

	override bool close(bool ok) {
		if (ok) {
			if (_flag !is null) {
				_flag.name = flagName.getText;
				_flag.onOff = flagInit.getSelectionIndex == 0;
				_flag.on = flagTrue.getText;
				_flag.off = flagFalse.getText;
			} else {
				auto name = FlagDir.validName(flagName.getText);
				name = dir.createNewFlagName(name);
				_flag = new Flag(name, flagTrue.getText, flagFalse.getText,
					flagInit.getSelectionIndex == 0);
				dir.add(_flag);
			}
		}
		return ok;
	}
}

public class FlagTable : TCPD {
private:
	static const NAME = 0;
	static const VALUE = 1;
	static const UC = 2;
	void refreshFlags() {
		if (_dir) {
			int i = 0;
			foreach (f; _dir.steps) {
				TableItem itm;
				if (i < flags.getItemCount) {
					itm = flags.getItem(i);
				} else {
					itm = new TableItem(flags, DWT.NONE);
				}
				itm.setImage(0, prop.images.step);
				itm.setText(NAME, f.name);
				itm.setText(VALUE, f.value);
				itm.setText(UC, to!(string)(uc.get(toStepId(f.path))));
				itm.setData = f;
				i++;
			}
			foreach (f; _dir.flags) {
				TableItem itm;
				if (i < flags.getItemCount) {
					itm = flags.getItem(i);
				} else {
					itm = new TableItem(flags, DWT.NONE);
				}
				itm.setImage(0, prop.images.flag);
				itm.setText(NAME, f.name);
				itm.setText(VALUE, f.onOff ? f.on : f.off);
				itm.setText(UC, to!(string)(uc.get(toFlagId(f.path))));
				itm.setData = f;
				i++;
			}
			if (i < flags.getItemCount) {
				flags.remove(i, flags.getItemCount - 1);
			}
		} else {
			flags.removeAll;
		}
	}

	Props prop;
	Commons _comm;
	UseCounter uc;

	Table flags;

	FlagDir _dir = null;

	void editFlag(FlagDir parent, Flag flag) {
		string old = flag ? flag.path : null;
		auto dlg = new FlagEditDialog(prop, flags.getShell, parent, flag);
		if (dlg.open) {
			if (old && old != flag.path) uc.change(toFlagId(old), toFlagId(flag.path));
			refresh(dlg.flag.name);
			_comm.refFlagAndStep.call([dlg.flag], []);
		}
	}
	void editStep(FlagDir parent, Step step) {
		string old = step ? step.path : null;
		auto dlg = new StepEditDialog(prop, flags.getShell, parent, step);
		if (dlg.open) {
			if (old && old != step.path) uc.change(toStepId(old), toStepId(step.path));
			refresh(dlg.step.name);
			_comm.refFlagAndStep.call([], [dlg.step]);
		}
	}

	void startEdit() {
		if (_dir !is null) {
			int index = flags.getSelectionIndex;
			if (0 <= index) {
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

	class MListener : MouseAdapter {
	public:
		override void mouseDoubleClick(MouseEvent e) {
			startEdit;
		}
	}
	class KListener : KeyAdapter {
	public:
		override void keyPressed(KeyEvent e) {
			if (e.character == DWT.CR) {
				startEdit;
			}
		}
	}

	/// 選択中のフラグとステップを取得する。
	/// Params:
	/// fs = 選択中のフラグの配列が格納される。
	/// ss = 選択中のステップの配列が格納される。
	/// Returns: 選択中ならtrue。
	bool getSelectionFlagAndStep(out Flag[] fs, out Step[] ss) {
		auto indices = flags.getSelectionIndices;
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

	class FlagDragListener : DragSourceListener {
	private:
		int[] dragIndices;
		Flag[] fs;
		Step[] ss;
	public:
		override void dragStart(DragSourceEvent e) {
			e.doit = flags.getSelectionCount > 0;
		}
		override void dragSetData(DragSourceEvent e) {
			if (XMLBytesTransfer.getInstance.isSupportedType(e.dataType)) {

				// XML化して転送する。
				getSelectionFlagAndStep(fs, ss);
				e.data = bytesFromXML(getXML(_dir, fs, ss));
			}
		}
		override void dragFinished(DragSourceEvent e) {
			if (e.detail == DND.DROP_MOVE) {
				foreach (flag; fs) {
					flag.parent.remove(flag);
				}
				fs.length = 0;
				foreach (step; ss) {
					step.parent.remove(step);
				}
				ss.length = 0;
				refresh;
				_comm.delFlagAndStep.call(fs, ss);
			}
		}
	}

public:
	this(Commons comm, Props prop) {
		_comm = comm;
		this.prop = prop;
	}

	/// コントロールを生成する。
	/// Params:
	/// parent = 親コントロール。
	Control createControl(Composite parent) {
		_comp = new Composite(parent, DWT.NONE);
		_comp.setLayout = new FillLayout;
		flags = new Table(_comp, DWT.MULTI | DWT.BORDER | DWT.FULL_SELECTION);
		flags.setHeaderVisible = true;
		auto nameCol = new TableColumn(flags, DWT.NULL);
		nameCol.setText = prop.msgs.flagName;
		saveColumnWidth!("prop.var.etc.flagNameColumn")(prop, nameCol);
		auto initCol = new TableColumn(flags, DWT.NULL);
		initCol.setText = prop.msgs.flagInit;
		saveColumnWidth!("prop.var.etc.flagInitColumn")(prop, initCol);
		auto countCol = new TableColumn(flags, DWT.NULL);
		countCol.setText = prop.msgs.flagCount;
		saveColumnWidth!("prop.var.etc.flagCountColumn")(prop, countCol);

		flags.addKeyListener(new KListener);
		flags.addMouseListener(new MListener);
		auto menu = new Menu(flags.getShell, DWT.POP_UP);
		createMenuItem(menu, prop.msgs.menuCEdit, prop.images.menuCEdit, &startEdit);
		new MenuItem(menu, DWT.SEPARATOR);
		appendMenuTCPD(prop, menu, this);
		flags.setMenu(menu);

		auto ds = new DragSource(flags, DND.DROP_MOVE | DND.DROP_COPY);
		ds.setTransfer = [XMLBytesTransfer.getInstance];
		ds.addDragListener(new FlagDragListener);

		_comm.refUseCount.add(&__refreshUseCount);
		_comm.replText.add(&refresh);
		flags.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.refUseCount.remove(&__refreshUseCount);
				_comm.replText.remove(&refresh);
			}
		});

		return _comp;
	}
	private Composite _comp = null;
	Control widget() {return _comp;}

	private void __refreshUseCount() {
		foreach (itm; flags.getItems) {
			if (cast(Flag) itm.getData) {
				itm.setText(2, to!(string)(uc.flag.get(toFlagId((cast(Flag) itm.getData).path))));
			} else {
				assert (cast(Step) itm.getData);
				itm.setText(2, to!(string)(uc.step.get(toStepId((cast(Step) itm.getData).path))));
			}
		}
	}
	void refresh() {
		refresh(null);
	}
	void refresh(string selName) {
		if (_dir) {
			string[] sels;
			if (selName) {
				sels ~= selName;
			} else {
				foreach (itm; flags.getSelection) {
					sels ~= itm.getText(NAME);
				}
			}
			flags.deselectAll;
			_dir.sortSteps;
			_dir.sortFlags;
			refreshFlags;
			foreach (i, itm; flags.getItems) {
				if (contains(sels, itm.getText(NAME))) {
					flags.select(i);
				}
			}
			if (selName) {
				flags.showSelection;
			}
		}
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

	/// 編集対象のディレクトリを設定する。
	/// Params:
	/// dir = ディレクトリ。
	void dir(FlagDir dir) {
		_dir = dir;
		refresh;
	}

	/// Returns: 編集対象のディレクトリ。
	FlagDir dir() {
		return _dir;
	}

	/// フラグを追加する。
	/// Params:
	/// flag = フラグ。
	void add(Flag flag) {
		_dir.add(flag);
		refresh;
	}

	/// ステップを追加する。
	/// Params:
	/// step = ステップ。
	void add(Step step) {
		_dir.add(step);
		refresh;
	}

	private void selectImpl(Object flag) {
		flags.deselectAll;
		foreach (i, itm; flags.getItems) {
			if (itm.getData is flag) {
				flags.select = i;
				break;
			}
		}
	}
	/// フラグを選択する。
	void select(Flag flag) {
		selectImpl(flag);
	}
	/// ステップを選択する。
	void select(Step step) {
		selectImpl(step);
	}

	/// コントロールを解放する。
	void dispose() {
		if (flags !is null) {
			flags.dispose;
		}
	}

	/// 使用回数カウンタを設定する。
	/// Params:
	/// uc = 使用回数カウンタ。
	void useCounter(UseCounter uc) {
		this.uc = uc;
	}

	override {
		void cut() {
			if (!_dir) return;
			copy();
			del();
		}
		void copy() {
			if (!_dir) return;
			Flag[] fs;
			Step[] ss;
			if (getSelectionFlagAndStep(fs, ss)) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(prop, cb, getXML(_dir, fs, ss));
			}
		}
		void paste() {
			if (!_dir) return;
			auto cb = new Clipboard(Display.getCurrent);
			scope (exit) cb.dispose;
			auto c = CBtoXML(cb);
			if (c) {
				string newPath;
				Flag[string] cFlags;
				Step[string] cSteps;
				if (_dir.appendFromXML(c, LATEST_VERSION,
						true, false, cFlags, cSteps, newPath)) {
					refresh;
					_comm.refFlagAndStep.call(cFlags.values, cSteps.values);
				}
			}
		}
		void del() {
			if (!_dir) return;
			Flag[] fs;
			Step[] ss;
			foreach (itm; flags.getSelection) {
				auto data = itm.getData;
				if (cast(Flag) data) {
					fs ~= cast(Flag) data;
					_dir.remove(cast(Flag) data);
				} else {
					ss ~= cast(Step) data;
					_dir.remove(cast(Step) data);
				}
			}
			_comm.delFlagAndStep.call(fs, ss);
			refresh;
		}
		bool canDoTCPD() {
			return flags.isFocusControl;
		}
	}
}
