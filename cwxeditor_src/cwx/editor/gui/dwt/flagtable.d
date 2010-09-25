
module cwx.editor.gui.dwt.flagtable;

import cwx.flag;
import cwx.utils;
import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.usecounter;

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

import dwtx.jface.dialogs.Dialog;
import dwtx.jface.dialogs.IDialogConstants;
import dwtx.jface.viewers.Viewer;
import dwtx.jface.viewers.TableViewer;
import dwtx.jface.viewers.TreeViewer;
import dwtx.jface.viewers.ITreeContentProvider;
import dwtx.jface.viewers.IStructuredContentProvider;
import dwtx.jface.viewers.ITableLabelProvider;
import dwtx.jface.viewers.LabelProvider;
import dwtx.jface.viewers.ILabelProviderListener;
import dwtx.jface.viewers.TreeSelection;
import dwtx.jface.viewers.TreePath;
import dwtx.jface.viewers.ICellModifier;
import dwtx.jface.viewers.TextCellEditor;

/// ステップ設定用のダイアログ。
/// 値は強制的に10件になる。
public class StepEditDialog : Dialog {
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
		super(shell);
		this.prop = prop;
		this.dir = dir;
		this._step = step;
	}

protected:
	override void configureShell(Shell shell) {
		super.configureShell(shell);
		shell.setText(prop.msgs.dlgTitStep);
	}

	override Control createDialogArea(Composite parent) {
		auto area = cast(Composite) super.createDialogArea(parent);
		area.setLayout = zeroGridLayout(1);
		{
			auto comp = new Composite(area, DWT.NULL);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comp.setLayout = new GridLayout(5, false);

			(new Label(comp, DWT.NULL)).setText = prop.msgs.dlgLblStepName;
			stepName = new Text(comp, DWT.BORDER);
			setGridMinW(stepName, prop.var.etc.flagNameWidth);

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
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

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

		(new Label(area, DWT.SEPARATOR | DWT.HORIZONTAL))
			.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

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

		return area;
	}

	override void createButtonsForButtonBar(Composite parent) {
		createButton(parent, IDialogConstants.OK_ID, IDialogConstants.OK_LABEL, true);
		createButton(parent, IDialogConstants.CANCEL_ID, IDialogConstants.CANCEL_LABEL, false);
	}

	override void buttonPressed(int buttonId) {
		if (buttonId == IDialogConstants.OK_ID) {
			string[] vals;
			foreach (stepVal; stepVals) {
				vals ~= stepVal.getText;
			}
			if (_step !is null) {
				_step.name = stepName.getText;
				_step.setValues(vals, stepInit.getSelectionIndex);
			} else {
				auto name = FlagDir.validName(stepName.getText);
				if (name.length > 0) {
					name = dir.createNewStepName(name);
					_step = new Step(name, vals, stepInit.getSelectionIndex);
					dir.add(_step);
				} else {
					buttonId = IDialogConstants.CANCEL_ID;
				}
			}
		}
		setReturnCode(buttonId);
		close();
		super.buttonPressed(buttonId);
	}

	/// Returns: 編集対象となったステップ。
	Step step() {
		return _step;
	}
}

/// フラグ設定用のダイアログ。
public class FlagEditDialog : Dialog {
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
		super(shell);
		this.prop = prop;
		this._flag = flag;
		this.dir = dir;
	}

protected:
	override void configureShell(Shell shell) {
		super.configureShell(shell);
		shell.setText(prop.msgs.dlgTitFlag);
	}

	private static void setMinW(Control c, int minW, int gridStyle = DWT.NULL) {
		auto gd = new GridData(gridStyle);
		int w = c.computeSize(DWT.DEFAULT, DWT.DEFAULT).x;
		gd.widthHint = w > minW ? w : minW;
		c.setLayoutData(gd);
	}

	override Control createDialogArea(Composite parent) {
		auto area = cast(Composite) super.createDialogArea(parent);
		area.setLayout = zeroGridLayout(1);
		{
			auto comp = new Composite(area, DWT.NULL);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			comp.setLayout = new GridLayout(5, false);

			(new Label(comp, DWT.NULL)).setText = prop.msgs.dlgLblFlagName;
			flagName = new Text(comp, DWT.BORDER);
			setGridMinW(flagName, prop.var.etc.flagNameWidth);

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
			auto comp = new Composite(area, DWT.NULL);
			comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
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

		(new Label(area, DWT.SEPARATOR | DWT.HORIZONTAL))
			.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

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

		return area;
	}

	override void createButtonsForButtonBar(Composite parent) {
		createButton(parent, IDialogConstants.OK_ID, IDialogConstants.OK_LABEL, true);
		createButton(parent, IDialogConstants.CANCEL_ID, IDialogConstants.CANCEL_LABEL, false);
	}

	override void buttonPressed(int buttonId) {
		// 重複があるとき/名前が空欄のときのチェックはFlag.name()に任せる。
		if (buttonId == IDialogConstants.OK_ID) {
			if (_flag !is null) {
				_flag.name = flagName.getText;
				_flag.onOff = flagInit.getSelectionIndex == 0;
				_flag.on = flagTrue.getText;
				_flag.off = flagFalse.getText;
			} else {
				auto name = FlagDir.validName(flagName.getText);
				if (name.length > 0) {
					name = dir.createNewFlagName(name);
					_flag = new Flag(name, flagTrue.getText, flagFalse.getText,
						flagInit.getSelectionIndex == 0);
					dir.add(_flag);
				} else {
					buttonId = IDialogConstants.CANCEL_ID;
				}
			}
		}
		setReturnCode(buttonId);
		close();
		super.buttonPressed(buttonId);
	}
	/// Returns: 編集対象となったフラグ。
	Flag flag() {
		return _flag;
	}
}

public class FlagTable : TCPD {
private:
	class FlagTableContentProvider : IStructuredContentProvider {
	public:
		override Object[] getElements(Object inputElement) {
			Object[] r;
			if (_dir !is null && (cast(FlagDir) inputElement)) {
				auto _dir = cast(FlagDir) inputElement;
				r ~= _dir.steps;
				r ~= _dir.flags;
			}
			return r;
		}
		override void inputChanged(Viewer viewer, Object oldInput, Object newInput) {}
		override void dispose() {}
	}

	class FlagTableLabelProvider : ITableLabelProvider {
		override string getColumnText(Object element, int columnIndex) {
			if (cast(Flag) element) {
				auto flag = cast(Flag) element;
				switch (columnIndex) {
				case 0:
					return flag.name;
				case 1:
					return flag.onOff ? flag.on : flag.off;
				case 2:
					return to!(string)(uc.flag.get(toFlagId(flag.path)));
				default:
					assert (false);
				}
			} else {
				assert (cast(Step) element);
				auto step = cast(Step) element;
				switch (columnIndex) {
				case 0:
					return step.name;
				case 1:
					return step.value;
				case 2:
					return to!(string)(uc.step.get(toStepId(step.path)));
				default:
					assert (false);
				}
			}
			assert (false);
		}
		override Image getColumnImage(Object element, int columnIndex) {
			if (columnIndex == 0) {
				if (cast(Flag) element) {
					return prop.images.flag;
				} else {
					assert (cast(Step) element);
					return prop.images.step;
				}
			}
			return null;
		}
		override void addListener(ILabelProviderListener listener) {}
		override void removeListener(ILabelProviderListener listener) {}
		override bool isLabelProperty(Object element, string property) {
			return false;
		}
		override void dispose() {}
	}

	Props prop;
	Commons _comm;
	UseCounter uc;

	Table flags;
	TableViewer flagsV;

	FlagDir _dir = null;

	void editFlag(FlagDir parent, Flag flag) {
		string old = flag ? flag.path : null;
		auto dlg = new FlagEditDialog(prop, flags.getShell, parent, flag);
		if (IDialogConstants.OK_ID == dlg.open) {
			if (old && old != flag.path) uc.change(toFlagId(old), toFlagId(flag.path));
			refresh;
			for (int i = _dir.steps.length; i < flags.getItemCount; i++) {
				if (flags.getItem(i).getText(0) == dlg.flag.name) {
					flags.select = i;
					break;
				}
			}
			_comm.refFlagAndStep.call([dlg.flag], []);
		}
	}
	void editStep(FlagDir parent, Step step) {
		string old = step ? step.path : null;
		auto dlg = new StepEditDialog(prop, flags.getShell, parent, step);
		if (IDialogConstants.OK_ID == dlg.open) {
			if (old && old != step.path) uc.change(toStepId(old), toStepId(step.path));
			refresh;
			for (int i = 0; i < _dir.steps.length; i++) {
				if (flags.getItem(i).getText(0) == dlg.step.name) {
					flags.select = i;
					break;
				}
			}
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
		flags = new Table(parent, DWT.MULTI | DWT.BORDER | DWT.FULL_SELECTION);
		flagsV = new TableViewer(flags);
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

		flagsV.setColumnProperties(["", "", ""]);
		flagsV.setContentProvider(new FlagTableContentProvider);
		flagsV.setLabelProvider(new FlagTableLabelProvider);

		flags.addKeyListener(new KListener);
		flags.addMouseListener(new MListener);
		auto menu = new Menu(flags.getShell, DWT.POP_UP);
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

		return flags;
	}
	Control widget() {return flags;}

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
		if (_dir !is null && flagsV !is null) {
			flags.deselectAll;
			_dir.sortSteps;
			_dir.sortFlags;
			flagsV.setInput(_dir);
			if (selName !is null) {
				for (int i = 0; i < flags.getItemCount; i++) {
					if (flags.getItem(i).getText(0) == selName) {
						flags.select(i);
						break;
					}
				}
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
			copy();
			del();
		}
		void copy() {
			Flag[] fs;
			Step[] ss;
			if (getSelectionFlagAndStep(fs, ss)) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(prop, cb, getXML(_dir, fs, ss));
			}
		}
		void paste() {
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
