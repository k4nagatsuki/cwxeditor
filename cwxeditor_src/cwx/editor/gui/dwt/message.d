
module cwx.editor.gui.dwt.message;

import cwx.utils;
import cwx.types;
import cwx.event;
import cwx.summary;
import cwx.skin;
import cwx.xml;
import cwx.flag;
import cwx.path;
import cwx.structs;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.eventdialog;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.properties;

import std.array;
import std.utf;
import std.string;
import std.datetime;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.List;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CTabItem;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.graphics.PaletteData;
import org.eclipse.swt.graphics.RGB;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.ShellAdapter;
import org.eclipse.swt.events.ShellEvent;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.events.ModifyEvent;
import org.eclipse.swt.events.ControlAdapter;
import org.eclipse.swt.events.ControlListener;
import org.eclipse.swt.events.ControlEvent;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.DragSourceAdapter;
import org.eclipse.swt.dnd.DragSourceEvent;
import org.eclipse.swt.dnd.DragSource;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.DropTarget;
import org.eclipse.swt.dnd.Clipboard;
import org.eclipse.swt.dnd.Transfer;

/// 台詞コンテントの設定ダイアログ。
class SpeakDialog : EventDialog {
private:
	class APData {
		string text;
		string[] rCoupons;
		int targDlg;
		int selDlg;
	}
	Object readAPD(Object old) {
		auto o = new APData;
		o.selDlg = _dlgsL.getSelectionIndex;
		auto apd = cast(APData) old;
		if (apd) {
			o.targDlg = apd.targDlg;
		} else {
			o.targDlg = o.selDlg;
		}
		o.text = _dlgs[o.targDlg].text;
		o.rCoupons = _dlgs[o.targDlg].rCoupons.dup;
		return o;
	}
	void writeAPD(Object o) {
		bool oldIgnoreMod = ignoreMod;
		ignoreMod = true;
		scope (exit) ignoreMod = oldIgnoreMod;
		auto apd = cast(APData) o;
		assert (apd);
		_dlgsL.select = apd.selDlg;
		_dlgs[apd.targDlg].text = apd.text;
		_dlgs[apd.targDlg].rCoupons = apd.rCoupons.dup;
		refreshDlgList(apd.targDlg);
		selectChanged();
	}
	class SUndo : Undo {
		private SDialog[] _dlgs;
		private int _selDlg;
		this () {
			save();
		}
		private void save() {
			_dlgs = [];
			foreach (d; this.outer._dlgs) {
				_dlgs ~= new SDialog(d);
			}
			_selDlg = _dlgsL.getSelectionIndex;
		}
		private void impl() {
			auto dlgs = _dlgs;
			int selDlg = _selDlg;
			save();

			this.outer._dlgs = [];
			foreach (dlg; dlgs) {
				this.outer._dlgs ~= new SDialog(dlg);
			}
			refreshDlgList();
			_dlgsL.select = selDlg;
			selectChanged();
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() {
			// Nothing
		}
	}
	void storeEdit() {
		_undo ~= new SUndo;
	}

	string _id;

	Combo _talkers;
	SDialog[] _dlgs;
	Table _dlgsL;
	Text _rCoupons;
	Combo _rCouponsList;
	FixedWidthText _text;
	UndoManager _undo;
	Listener _kdFilter;
	TextMenuModify _textTM, _rCouponsTM;
	MsgPreview _preview = null;

	void selectChanged() {
		bool oldIgnoreMod = ignoreMod;
		ignoreMod = true;
		scope (exit) ignoreMod = oldIgnoreMod;
		auto dlg = _dlgs[_dlgsL.getSelectionIndex];
		string rcs;
		foreach (rc; dlg.rCoupons) {
			rcs ~= rc;
			rcs ~= '\n';
		}
		_rCoupons.setText = rcs;
		_text.setText = dlg.text;
		refreshPreview();
	}
	void createDialog(SDialog dlg) {
		insertDialog(dlg, _dlgsL.getSelectionIndex);
	}
	void createDialog() {
		createDialog(new SDialog);
	}
	void insertDialog(SDialog dlg, int index, bool store = true) {
		if (store) storeEdit();
		if (index < 0) index = _dlgs.length;
		_dlgs = _dlgs[0 .. index] ~ dlg ~ _dlgs[index .. $];
		auto itm = new TableItem(_dlgsL, SWT.NONE, index);
		itm.setImage = prop.images.content(CType.TALK_DIALOG);
		_dlgsL.setSelection = [itm];
		_dlgsL.showSelection;
		selectChanged();
		applyEnabled();
	}
	void deleteDialog(int index, bool store = true) {
		if (index < 0 || _dlgs.length <= 1) return;
		if (store) storeEdit();
		bool sel = _dlgsL.getSelectionIndex == index;
		_dlgs = _dlgs[0 .. index] ~ _dlgs[index + 1 .. $];
		_dlgsL.remove(index);
		if (sel) {
			_dlgsL.select = index < _dlgs.length ? index : _dlgs.length - 1;
			selectChanged();
		}
		applyEnabled();
	}
	void deleteDialogSel() {
		deleteDialog(_dlgsL.getSelectionIndex);
	}
	void up() {
		int index = _dlgsL.getSelectionIndex;
		if (index > 0) {
			storeEdit();
			auto temp = _dlgs[index - 1];
			_dlgs[index - 1] = _dlgs[index];
			_dlgs[index] = temp;
			auto tempL = _dlgsL.getItem(index - 1).getText;
			_dlgsL.getItem(index - 1).setText(_dlgsL.getItem(index).getText);
			_dlgsL.getItem(index).setText(tempL);
			_dlgsL.select = index - 1;
			applyEnabled();
		}
	}
	void down() {
		int index = _dlgsL.getSelectionIndex;
		if (index + 1 < _dlgs.length) {
			storeEdit();
			auto temp = _dlgs[index + 1];
			_dlgs[index + 1] = _dlgs[index];
			_dlgs[index] = temp;
			auto tempL = _dlgsL.getItem(index + 1).getText;
			_dlgsL.getItem(index + 1).setText(_dlgsL.getItem(index).getText);
			_dlgsL.getItem(index).setText(tempL);
			_dlgsL.select = index + 1;
			applyEnabled();
		}
	}
	void copyToUpper() {
		storeEdit();
		int index = _dlgsL.getSelectionIndex;
		string textL = _dlgsL.getItem(index).getText;
		string text = lastRet(wrapReturnCode(_text.getText));
		for (int i = 0; i < index; i++) {
			_dlgsL.getItem(i).setText(textL);
			_dlgs[i].text = text;
		}
		applyEnabled();
	}
	void copyToLower() {
		storeEdit();
		int index = _dlgsL.getSelectionIndex;
		string textL = _dlgsL.getItem(index).getText;
		string text = lastRet(wrapReturnCode(_text.getText));
		for (int i = index + 1; i < _dlgs.length; i++) {
			_dlgsL.getItem(i).setText(textL);
			_dlgs[i].text = text;
		}
		applyEnabled();
	}
	void copyToDialogs() {
		storeEdit();
		int index = _dlgsL.getSelectionIndex;
		string textL = _dlgsL.getItem(index).getText;
		string text = lastRet(wrapReturnCode(_text.getText));
		foreach (i, dlg; _dlgs) {
			if (i != index) {
				_dlgsL.getItem(i).setText(textL);
				dlg.text = text;
			}
		}
		applyEnabled();
	}
	void put(dchar put) {
		putColor(_text, put);
	}
	void insert(string put) {
		_text.insert(put);
	}
	void putText(SDialog dlg) {
		dlg.text = lastRet(wrapReturnCode(_text.getText));
	}
	void putRCoupons(SDialog dlg) {
		string[] rcs;
		foreach (rc; splitLines(_rCoupons.getText)) {
			if (rc.length > 0) {
				rcs ~= rc;
			}
		}
		dlg.rCoupons = rcs;
	}
	class SelL : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			selectChanged();
		}
	}
	class SelectTalker : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			refreshPreview();
		}
	}
	private void refreshDlgList(int index) {
		string text = std.array.replace(wrapReturnCode(_dlgs[index].text), "\n", "");
		// FIXME: ""をsetTextするとArgument cannot be null
		if (text == "") text = " ";
		_dlgsL.getItem(index).setText(0, text);
	}
	class ModL : ModifyListener {
		override void modifyText(ModifyEvent e) {
			if (_textTM && _rCouponsTM && !_textTM.inProc && !_rCouponsTM.inProc) {
				putText(_dlgs[_dlgsL.getSelectionIndex]);
			}
			refreshDlgList(_dlgsL.getSelectionIndex);
			refreshPreview();
		}
	}
	class ModRC : ModifyListener {
		override void modifyText(ModifyEvent e) {
			if (_textTM && _rCouponsTM && !_textTM.inProc && !_rCouponsTM.inProc) {
				putRCoupons(_dlgs[_dlgsL.getSelectionIndex]);
			}
		}
	}
	SDialog selection() {
		int index = _dlgsL.getSelectionIndex;
		return index >= 0 ? _dlgs[index] : null;
	}
	class DialogsTCPD : TCPD {
		void cut(SelectionEvent se) {
			if (_dlgsL.getItemCount > 1 && selection) {
				copy(se);
				del(se);
			}
		}
		void copy(SelectionEvent se) {
			auto d = selection;
			if (d) {
				XMLtoCB(prop, comm.clipboard, d.toNode.text);
			}
		}
		void paste(SelectionEvent se) {
			auto xml = CBtoXML(comm.clipboard);
			if (xml) {
				try {
					auto node = XNode.parse(xml);
					if (node.name == SDialog.XML_NAME) {
						createDialog(SDialog.createFromNode(node, LATEST_VERSION));
					}
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		void del(SelectionEvent se) {deleteDialogSel;}
		bool canDoTCPD() {return _dlgsL.isFocusControl;}
	}
	class DDropListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){
			e.detail = DND.DROP_MOVE;
		}
		override void dragOver(DropTargetEvent e){
			e.detail = DND.DROP_MOVE;
		}
		override void drop(DropTargetEvent e){
			if (!isXMLBytes(e.data)) return;
			e.detail = DND.DROP_NONE;
			string xml = bytesToXML(e.data);
			try {
				auto node = XNode.parse(xml);
				if (node.name != SDialog.XML_NAME) return;
				storeEdit();
				scope p = (cast(DropTarget) e.getSource).getControl.toControl(e.x, e.y);
				auto t = _dlgsL.getItem(p);
				int index = t ? _dlgsL.indexOf(t) : _dlgsL.getItemCount;
				insertDialog(SDialog.createFromNode(node, LATEST_VERSION), index, false);
				if (_id == node.attr("paneId", false)) {
					e.detail = DND.DROP_MOVE;
				}
			} catch {}
		}
	}
	class DDragListener : DragSourceAdapter {
		private TableItem _itm;
		override void dragStart(DragSourceEvent e) {
			e.doit = (cast(DragSource) e.getSource).getControl.isFocusControl;
		}
		override void dragSetData(DragSourceEvent e){
			if (XMLBytesTransfer.getInstance.isSupportedType(e.dataType)) {
				auto c = cast(Table) (cast(DragSource) e.getSource).getControl;
				int index = c.getSelectionIndex;
				if (index >= 0) {
					auto d = _dlgs[index];
					auto node = d.toNode;
					node.newAttr("paneId", _id);
					e.data = bytesFromXML(node.text);
					_itm = c.getItem(index);
				}
			}
		}
		override void dragFinished(DragSourceEvent e) {
			if (e.detail == DND.DROP_MOVE) {
				deleteDialog(_dlgsL.indexOf(_itm), false);
			}
		}
	}
	void refreshCoupons() {
		auto c = _rCouponsList.getText;
		_rCouponsList.removeAll();
		addCastCoupons(_rCouponsList, prop, true, comm.skin.legacyName);
		_rCouponsList.select = 0;
		if (c.length && -1 == _rCouponsList.indexOf(c)) {
			_rCouponsList.add(c, 0);
		}
		_rCouponsList.setText = c;
	}
	protected override void refSkin() {
		_text.font = dwtData(prop.looks.messageFont(summ.legacy));
		refreshCoupons();
	}
	void refreshDlgList() {
		bool oldIgnoreMod = ignoreMod;
		ignoreMod = true;
		scope (exit) ignoreMod = oldIgnoreMod;
		int selIndex = _dlgsL.getSelectionIndex;
		int topIndex = _dlgsL.getTopIndex;

		_dlgsL.removeAll();
		foreach (dlg; _dlgs) {
			auto itm = new TableItem(_dlgsL, SWT.NONE);
			itm.setImage = prop.images.content(CType.TALK_DIALOG);
			string text = std.array.replace(dlg.text, "\n", "");
			// FIXME: ""をsetTextするとArgument cannot be null
			itm.setText = text.length > 0 ? text : " ";
		}

		if (selIndex < 0 || _dlgs.length <= selIndex) {
			_dlgsL.select = 0;
		} else {
			_dlgsL.select = selIndex;
			_dlgsL.setTopIndex = topIndex;
		}
		if (selIndex != _dlgsL.getSelectionIndex) {
			selectChanged();
		}
	}
	class SelPrev : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto btn = cast(Button) e.widget;
			if (btn.getSelection) {
				_preview.open();
			} else {
				_preview.close();
			}
		}
	}
	void refreshPreview() {
		if (_preview) {
			_preview.text(selectedTalker, "", wrapReturnCode(_text.getText));
		}
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto sash = cast(SplitPane) e.widget;
			auto ws = sash.getWeights;
			prop.var.etc.talkSashL = ws[0];
			prop.var.etc.talkSashR = ws[1];
			sash.getDisplay.removeFilter(SWT.KeyDown, _kdFilter);
			comm.refUndoMax.remove(&refUndoMax);
		}
	}
	private class KeyDownFilter : Listener {
		private int _undoAcc;
		private int _redoAcc;
		this () {
			_undoAcc = convertAccelerator(prop.msgs.menuUndo);
			_redoAcc = convertAccelerator(prop.msgs.menuRedo);
		}
		override void handleEvent(Event e) {
			auto c = cast(Control) e.widget;
			if (!c || c.getShell !is getShell) return;
			if (eqAcc(_undoAcc, e.keyCode, e.character, e.stateMask)) {
				_undo.undo();
				e.doit = false;
			} else if (eqAcc(_redoAcc, e.keyCode, e.character, e.stateMask)) {
				_undo.redo();
				e.doit = false;
			}
		}
	}
	void refUndoMax() {
		_undo.max = prop.var.etc.undoMaxEtc;
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime);
		super(comm, prop, shell, summ, CType.TALK_DIALOG, parent, evt, true, prop.var.speakDlg, false);
		_undo = new UndoManager(prop.var.etc.undoMaxEtc);
	}

	override
	bool openCWXPath(string path, bool shellActivate) {
		auto cate = cpcategory(path);
		if ("dialog" == cate) {
			auto index = cpindex(path);
			if (index >= _dlgsL.getItemCount) return false;
			_dlgsL.select = index;
			selectChanged();
			.forceFocus(_dlgsL, shellActivate);
			path = cpbottom(path);
			return cpempty(path);
		}
		return super.openCWXPath(path, shellActivate);
	}

	Talker selectedTalker() {
		switch (_talkers.getSelectionIndex) {
		case 0: return Talker.SELECTED;
		case 1: return Talker.UNSELECTED;
		case 2: return Talker.RANDOM;
		default: assert (0);
		}
	}
protected:
	override void setup(Composite area) {
		area.setLayout = windowGridLayout(1, true);
		auto sash = new SplitPane(area, SWT.VERTICAL);
		sash.setLayoutData = new GridData(GridData.FILL_BOTH);
		{
			auto comp = new Composite(sash, SWT.NONE);
			comp.setLayout = new GridLayout(2, false);
			_dlgsL = new Table(comp, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
			new FullTableColumn(_dlgsL, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = 0;
			gd.heightHint = 0;
			_dlgsL.setLayoutData = gd;
			_dlgsL.addSelectionListener(new SelL);

			auto drag = new DragSource(_dlgsL, DND.DROP_MOVE | DND.DROP_COPY);
			drag.setTransfer([XMLBytesTransfer.getInstance]);
			drag.addDragListener(new DDragListener);
			auto drop = new DropTarget(_dlgsL, DND.DROP_DEFAULT | DND.DROP_MOVE | DND.DROP_COPY);
			drop.setTransfer([XMLBytesTransfer.getInstance]);
			drop.addDropListener(new DDropListener);

			auto menu = new Menu(_dlgsL);
			createMenuItem(menu, prop.msgs.menuUndo, prop.images.menuUndo, {_undo.undo();});
			createMenuItem(menu, prop.msgs.menuRedo, prop.images.menuRedo, {_undo.redo();});
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(menu, prop.msgs.menuUp, prop.images.menuUp, &up);
			createMenuItem(menu, prop.msgs.menuDown, prop.images.menuDown, &down);
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(prop, menu, new DialogsTCPD, true, true, true, true);
			_dlgsL.setMenu = menu;

			auto bar = new ToolBar(comp, SWT.FLAT | SWT.VERTICAL);
			bar.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			bar.addListener(SWT.Traverse, new class Listener {
				override void handleEvent(Event e) {e.doit = true;}
			});
			bar.addListener(SWT.KeyDown, new class Listener {
				override void handleEvent(Event e) {e.doit = true;}
			});
			createToolItem(bar, prop.msgs.createDialog, prop.images.createDialog, &createDialog);
			createToolItem(bar, prop.msgs.deleteDialog, prop.images.deleteDialog, &deleteDialogSel);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(bar, prop.msgs.ttUp, prop.images.menuUp, &up);
			createToolItem(bar, prop.msgs.ttDown, prop.images.menuDown, &down);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(bar, prop.msgs.copyToDialogs, prop.images.copyToDialogs, &copyToDialogs);
			createToolItem(bar, prop.msgs.copyToUpper, prop.images.copyToUpper, &copyToUpper);
			createToolItem(bar, prop.msgs.copyToLower, prop.images.copyToLower, &copyToLower);
		}
		auto skin = comm.skin;
		{
			auto comp = new Composite(sash, SWT.NONE);
			comp.setLayout = new GridLayout(2, false);
			Control tp;
			if (evt) {
				tp = createTalkerPane2(comp, comm, prop, summ, evt.talkerNC, evt.dialogs[0].rCoupons, _talkers, _rCoupons, _rCouponsList);
			} else {
				tp = createTalkerPane2(comp, comm, prop, summ, Talker.SELECTED, [], _talkers, _rCoupons, _rCouponsList);
			}
			mod(_talkers);
			mod(_rCoupons);
			_talkers.addSelectionListener(new SelectTalker);
			_rCoupons.addModifyListener(new ModRC);
			refreshCoupons();
			tp.setLayoutData = new GridData(GridData.FILL_BOTH);
			auto msgComp = new Composite(comp, SWT.NONE);
			msgComp.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			msgComp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
			_text = createMessagePane(comm, prop, true, msgComp, summ);
			mod(_text.widget);
			_text.widget.setLayoutData = _text.computeTextBaseSize(prop.looks.messageLine);
			_text.widget.addModifyListener(new ModL);
		}
		{
			auto bar = createSCharBar(area, &insert, &put, prop, skin);
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		{
			auto bar = createSkinSCharBar(area, &insert, prop, skin);
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		{
			auto bar = createFlagStepBar(area, &insert, comm, prop);
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		auto aComp = addition();
		aComp.setLayout = new GridLayout(1, true);
		auto prev = new Button(aComp, SWT.TOGGLE);
		prev.setText = prop.msgs.messagePreview;
		prev.addSelectionListener(new SelPrev);

		sash.addDisposeListener(new Dispose);
		sash.setWeights = [prop.var.etc.talkSashL, prop.var.etc.talkSashR];
		_kdFilter = new KeyDownFilter;
		sash.getDisplay.addFilter(SWT.KeyDown, _kdFilter);
		comm.refUndoMax.add(&refUndoMax);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (evt) {
			foreach (dlg; evt.dialogs) {
				_dlgs ~= new SDialog(dlg.text, dlg.rCoupons);
			}
		} else {
			_dlgs = [new SDialog];
		}
		refreshDlgList();

		_textTM = createTextMenu!Text(comm, prop, _rCoupons, &catchMod, _undo, TMAppendData(&readAPD, &writeAPD));
		_rCouponsTM = createTextMenu!Text(comm, prop, _text.widget, &catchMod, _undo, TMAppendData(&readAPD, &writeAPD));

		_preview = new MsgPreview(getShell, comm, prop, summ, prev, prop.var.dlgPrev);
		refreshPreview();
	}
	override
	protected void opened() {
		if (prop.var.etc.showDialogPreview) _preview.open();
		closeEvent ~= {
			prop.var.etc.showDialogPreview = _preview.isVisible;
		};
	}

	override bool apply() {
		if (!evt) evt = new Content(CType.TALK_DIALOG, "");
		evt.dialogs = _dlgs;
		evt.talkerNC = selectedTalker;
		return true;
	}
}

/// メッセージコンテントの設定ダイアログ。
class MessageDialog : EventDialog {
private:
	CTabFolder _tabf;
	Composite _msgCompA, _msgCompB;
	FixedWidthText _text;
	ImageSelect!(MtType.CARD, Combo) _msel;
	UndoManager _undo;
	KeyDownFilter _kdFilter;
	MsgPreview _preview = null;

	void tabChanged() {
		switch (_tabf.getSelectionIndex) {
		case 0:
			_text.num = prop.looks.messageImageLen;
			_text.widget.setParent = _msgCompA;
			break;
		case 1:
			_text.num = prop.looks.messageLen;
			_text.widget.setParent = _msgCompB;
			break;
		default: return;
		}
		_text.widget.setLayoutData = _text.computeTextBaseSize(prop.looks.messageLine);
		_text.widget.getParent.layout();
		if (0 == _tabf.getSelectionIndex) {
			_text.widget.getParent.getParent.layout();
		}
	}
	class SelPrev : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto btn = cast(Button) e.widget;
			if (btn.getSelection) {
				_preview.open();
			} else {
				_preview.close();
			}
		}
	}
	class SL : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			tabChanged();
		}
	}
	class ModText : ModifyListener {
		override void modifyText(ModifyEvent e) {
			refreshPreview();
		}
	}
	void put(dchar put) {
		putColor(_text, put);
	}
	void insert(string put) {
		_text.insert(put);
	}
	void refreshPreview() {
		if (_preview) {
			Talker talker;
			string imgPath;
			selectedTalker(talker, imgPath);
			_preview.text(talker, imgPath, wrapReturnCode(_text.getText));
		}
	}
	protected override void refSkin() {
		_text.font = dwtData(prop.looks.messageFont(summ.legacy));
	}
	class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto c = cast(Control) e.widget;
			assert (c);
			c.getDisplay.removeFilter(SWT.KeyDown, _kdFilter);
			comm.refUndoMax.remove(&refUndoMax);
		}
	}
	private class KeyDownFilter : Listener {
		private int _undoAcc;
		private int _redoAcc;
		this () {
			_undoAcc = convertAccelerator(prop.msgs.menuUndo);
			_redoAcc = convertAccelerator(prop.msgs.menuRedo);
		}
		override void handleEvent(Event e) {
			auto c = cast(Control) e.widget;
			if (!c || c.getShell !is getShell) return;
			if (eqAcc(_undoAcc, e.keyCode, e.character, e.stateMask)) {
				_undo.undo();
				e.doit = false;
			} else if (eqAcc(_redoAcc, e.keyCode, e.character, e.stateMask)) {
				_undo.redo();
				e.doit = false;
			}
		}
	}
	void refUndoMax() {
		_undo.max = prop.var.etc.undoMaxEtc;
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super(comm, prop, shell, summ, CType.TALK_MESSAGE, parent, evt, true, prop.var.msgDlg, false);
		_undo = new UndoManager(prop.var.etc.undoMaxEtc);
	}

	void selectedTalker(out Talker talker, out string imgPath) {
		imgPath = "";
		switch (_tabf.getSelectionIndex) {
		case 0:
			switch (_msel.dirsCombo.getSelectionIndex) {
			case 0:
				talker = Talker.SELECTED;
				break;
			case 1:
				talker = Talker.UNSELECTED;
				break;
			case 2:
				talker = Talker.RANDOM;
				break;
			case 3:
				talker = Talker.CARD;
				break;
			default:
				talker = Talker.IMAGE;
				imgPath = _msel.image;
			}
			break;
		case 1:
			talker = Talker.NARRATION;
			break;
		default: assert (0);
		}
	}
protected:
	override void setup(Composite area) {
		area.setLayout = windowGridLayout(1, true);
		_tabf = new CTabFolder(area, SWT.BORDER);
		mod(_tabf);
		_tabf.setLayoutData = new GridData(GridData.FILL_BOTH);
		auto skin = comm.skin;
		{
			auto comp = new Composite(_tabf, SWT.NONE);
			comp.setLayout = new GridLayout(2, false);
			Control tp;
			if (evt) {
				tp = createTalkerPane(comp, comm, prop, summ, evt.talkerC, evt.cardPath, _msel);
			} else {
				tp = createTalkerPane(comp, comm, prop, summ, Talker.SELECTED, "", _msel);
			}
			mod(_msel);
			tp.setLayoutData = new GridData(GridData.FILL_BOTH);
			_msgCompA = new Composite(comp, SWT.NONE);
			_msgCompA.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			_msgCompA.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
			_text = createMessagePane(comm, prop, true, _msgCompA, summ);
			mod(_text.widget);
			_text.widget.addModifyListener(new ModText);
			createTextMenu!Text(comm, prop, _text.widget, &catchMod, _undo);
			auto tab = new CTabItem(_tabf, SWT.NONE);
			tab.setText = prop.msgs.imageMessage;
			tab.setControl = comp;
		}
		{
			_msgCompB = new Composite(_tabf, SWT.NONE);
			_msgCompB.setLayout = new CenterLayout;
			auto tab = new CTabItem(_tabf, SWT.NONE);
			tab.setText = prop.msgs.noImageMessage;
			tab.setControl = _msgCompB;
		}
		{
			auto bar = createSCharBar(area, &insert, &put, prop, skin);
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		{
			auto bar = createSkinSCharBar(area, &insert, prop, skin);
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		{
			auto bar = createFlagStepBar(area, &insert, comm, prop);
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		auto aComp = addition();
		aComp.setLayout = new GridLayout(1, true);
		auto prev = new Button(aComp, SWT.TOGGLE);
		prev.setText = prop.msgs.messagePreview;
		prev.addSelectionListener(new SelPrev);

		_tabf.addSelectionListener(new SL);
		_tabf.addDisposeListener(new Dispose);
		_kdFilter = new KeyDownFilter;
		_tabf.getDisplay.addFilter(SWT.KeyDown, _kdFilter);
		comm.refUndoMax.add(&refUndoMax);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		_tabf.setSelection = 0;
		if (evt) {
			_text.setText = evt.text;
			if (evt.talkerC == Talker.NARRATION) {
				_tabf.setSelection = 1;
			}
		} else {
			_tabf.setSelection = 1;
		}
		tabChanged();

		_preview = new MsgPreview(getShell, comm, prop, summ, prev, prop.var.msgPrev);
		refreshPreview();
		_msel.modEvent ~= &refreshPreview;
	}
	override
	protected void opened() {
		if (prop.var.etc.showMessagePreview) _preview.open();
		closeEvent ~= {
			prop.var.etc.showMessagePreview = _preview.isVisible;
		};
	}

	override bool apply() {
		string text;
		string path = "";
		Talker talker;
		selectedTalker(talker, path);
		text = lastRet(wrapReturnCode(_text.getText));
		if (!evt) evt = new Content(CType.TALK_MESSAGE, "");
		evt.text = text;
		evt.talkerC = talker;
		evt.cardPath = path;
		return true;
	}
}

private Composite createTalkerPane2(Composite parent, Commons comm, Props prop, Summary summ, Talker talker,
		string[] coupons, out Combo talkerCombo, out Text couponList, out Combo couponCombo) {
	auto comp = new Composite(parent, SWT.NONE);
	comp.setLayout = new GridLayout(2, false);
	{
		talkerCombo = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		gd.horizontalSpan = 2;
		talkerCombo.setLayoutData = gd;
		talkerCombo.add(prop.msgs.talker(Talker.SELECTED));
		talkerCombo.add(prop.msgs.talker(Talker.UNSELECTED));
		talkerCombo.add(prop.msgs.talker(Talker.RANDOM));
		switch (talker) {
		case Talker.SELECTED:
			talkerCombo.select = 0;
			break;
		case Talker.UNSELECTED:
			talkerCombo.select = 1;
			break;
		case Talker.RANDOM:
			talkerCombo.select = 2;
			break;
		default:
			talkerCombo.select = 0;
		}
	}
	couponCombo = new Combo(comp, SWT.DROP_DOWN | SWT.BORDER);
	couponCombo.setVisibleItemCount = 20;
	createTextMenu!Combo(comm, prop, couponCombo, null);
	auto push = new Button(comp, SWT.PUSH);
	auto skin = comm.skin;
	{
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		gd.widthHint = prop.var.etc.talkersWidth;
		couponCombo.setLayoutData = gd;
		push.setToolTipText = prop.msgs.setTalkerCoupon;
		push.setImage = prop.images.setTalkerCoupon;
	}
	{
		couponList = new Text(comp, SWT.BORDER | SWT.MULTI | SWT.V_SCROLL);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.horizontalSpan = 2;
		couponList.setLayoutData = gd;
		string buf;
		foreach (coupon; coupons) {
			buf ~= coupon ~ "\n";
		}
		couponList.setText = buf;
		push.addSelectionListener(new class SelectionAdapter {
			private Combo _combo;
			private Text _list;
			this() {
				_combo = couponCombo;
				_list = couponList;
			}
			override void widgetSelected(SelectionEvent e) {
				if (_combo.getText.length > 0) {
					_list.setSelection(_list.getText.length, _list.getText.length);
					string[] lines = splitLines(_list.getText);
					if (lines.length > 0 && lines[$ - 1].length > 0) {
						_list.insert("\n");
					}
					_list.insert(_combo.getText ~ "\n");
				}
			}
		});
	}
	return comp;
}

private Composite createTalkerPane
		(Composite parent, Commons comm, Props prop, Summary summ, Talker talker, string path,
		out ImageSelect!(MtType.CARD, Combo) msel) {
	auto comp = new Composite(parent, SWT.NONE);
	{
		comp.setLayout = zeroMarginGridLayout(1, true);
	}
	auto selected = prop.images.talker(Talker.SELECTED).getImageData;
	auto unselected = prop.images.talker(Talker.UNSELECTED).getImageData;
	auto random = prop.images.talker(Talker.RANDOM).getImageData;
	ImageData createDefImage(size_t index) {
		switch (index) {
		case 0:
			// 選択中
			return selected;
		case 1:
			// 選択中以外
			return unselected;
		case 2:
			// ランダム
			return random;
		case 3:
			// カード
			return menuCard(comm.skin);
		default: assert (0);
		}
	}
	string[] defs = [
		prop.msgs.talker(Talker.SELECTED),
		prop.msgs.talker(Talker.UNSELECTED),
		prop.msgs.talker(Talker.RANDOM),
		prop.msgs.talker(Talker.CARD)
	];
	auto s = prop.looks.cardSize;
	msel = new ImageSelect!(MtType.CARD, Combo)(comp, SWT.NONE, comm, prop, summ, s.width, s.height,
		false, "", null, defs, &createDefImage);
	auto gd = new GridData(GridData.FILL_BOTH);
	msel.widget.setLayoutData = gd;
	msel.image = path;
	if (msel.image.length == 0) {
		switch (talker) {
		case Talker.SELECTED:
			msel.dirsCombo.select = 0;
			break;
		case Talker.UNSELECTED:
			msel.dirsCombo.select = 1;
			break;
		case Talker.RANDOM:
			msel.dirsCombo.select = 2;
			break;
		case Talker.CARD:
			msel.dirsCombo.select = 3;
			break;
		default:
			msel.dirsCombo.select = 0;
		}
	}
	return comp;
}

class DisposeText : DisposeListener {
	private Color _back, _fore;
	this (Color back, Color fore) {
		_back = back;
		_fore = fore;
	}
	override void widgetDisposed(DisposeEvent e) {
		_back.dispose();
		_fore.dispose();
	}
}
private FixedWidthText createMessagePane(Commons comm, Props prop, bool image, Composite parent, Summary summ) {
	int len = image ? prop.looks.messageImageLen : prop.looks.messageLen;
	auto r = new FixedWidthText(dwtData(prop.looks.messageFont(summ.legacy)), len, parent, SWT.BORDER);
	auto d = r.widget.getDisplay;
	auto back = new Color(d, new RGB(prop.var.etc.msgBackR, prop.var.etc.msgBackG, prop.var.etc.msgBackB));
	auto fore = new Color(d, new RGB(prop.var.etc.msgForeR, prop.var.etc.msgForeG, prop.var.etc.msgForeB));
	r.widget.setBackground = back;
	r.widget.setForeground = fore;
	r.widget.addDisposeListener(new DisposeText(back, fore));
	return r;
}

private class PutC {
	private void delegate(string) _insert;
	private string _put;
	this(void delegate(string) insert, string put) {
		_insert = insert;
		_put = put;
	}
	void put() {
		_insert(_put);
	}
}
private class PutColor {
	private void delegate(dchar) _put;
	private dchar _color;
	this(void delegate(dchar) put, dchar color) {
		_put = put;
		_color = color;
	}
	void put() {
		_put(_color);
	}
}
private ToolBar createSCharBar(Composite parent,
		void delegate(string) insert, void delegate(dchar) putColor, Props prop, Skin skin) {
	auto bar = new ToolBar(parent, SWT.FLAT);
	bar.addListener(SWT.Traverse, new class Listener {
		override void handleEvent(Event e) {e.doit = true;}
	});
	bar.addListener(SWT.KeyDown, new class Listener {
		override void handleEvent(Event e) {e.doit = true;}
	});
	createToolItem(bar, prop.msgs.defaultColor, prop.images.defaultColor, &(new PutColor(putColor, 'W')).put);
	createToolItem(bar, prop.msgs.red, prop.images.red, &(new PutColor(putColor, 'R')).put);
	createToolItem(bar, prop.msgs.blue, prop.images.blue, &(new PutColor(putColor, 'B')).put);
	createToolItem(bar, prop.msgs.green, prop.images.green, &(new PutColor(putColor, 'G')).put);
	createToolItem(bar, prop.msgs.yellow, prop.images.yellow, &(new PutColor(putColor, 'Y')).put);
	new ToolItem(bar, SWT.SEPARATOR);
	createToolItem(bar, prop.msgs.scRef, prop.images.scRef, &(new PutC(insert, "#I")).put);
	createToolItem(bar, prop.msgs.scTalker(Talker.SELECTED), prop.images.scTalker(Talker.SELECTED),
		&(new PutC(insert, "#M")).put);
	createToolItem(bar, prop.msgs.scTalker(Talker.UNSELECTED), prop.images.scTalker(Talker.UNSELECTED),
		&(new PutC(insert, "#U")).put);
	createToolItem(bar, prop.msgs.scTalker(Talker.RANDOM), prop.images.scTalker(Talker.RANDOM),
		&(new PutC(insert, "#R")).put);
	createToolItem(bar, prop.msgs.scTalker(Talker.CARD), prop.images.scTalker(Talker.CARD),
		&(new PutC(insert, "#C")).put);
	createToolItem(bar, prop.msgs.scTeam, prop.images.scTeam, &(new PutC(insert, "#T")).put);
	createToolItem(bar, prop.msgs.scYado, prop.images.scYado, &(new PutC(insert, "#Y")).put);
	return bar;
}

private ToolBar createSkinSCharBar(Composite parent, void delegate(string) insert, Props prop, Skin skin) {
	auto bar = new ToolBar(parent, SWT.FLAT);
	bar.addListener(SWT.Traverse, new class Listener {
		override void handleEvent(Event e) {e.doit = true;}
	});
	bar.addListener(SWT.KeyDown, new class Listener {
		override void handleEvent(Event e) {e.doit = true;}
	});
	Image[] imgs;
	foreach (spc; skin.spChars.keys) {
		auto img = new Image(Display.getCurrent, spChar(skin, spc));
		string name = toUTF8("#"d ~ spc);
		auto scp = new PutC(insert, name);
		createToolItem(bar, name, img, &scp.put);
		imgs ~= img;
	}
	bar.addDisposeListener(new class DisposeListener {
		private Image[] _imgs;
		this() {_imgs = imgs;}
		override void widgetDisposed(DisposeEvent e) {
			foreach (img; _imgs) {
				img.dispose;
			}
		}
	});
	return bar;
}

private Composite createFlagStepBar(Composite parent, void delegate(string) insert, Commons comm, Props prop) {
	auto bar = new Composite(parent, SWT.NONE);
	bar.setLayout = zeroMarginGridLayout(2, true);
	void create(out Combo list, out Button put, string puts, Image image, string lc) {
		auto comp = new Composite(bar, SWT.NONE);
		comp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		comp.setLayout = zeroMarginGridLayout(2, false);
		list = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
		list.setVisibleItemCount = 20;
		list.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		put = new Button(comp, SWT.PUSH);
		put.setToolTipText = puts;
		put.setImage = image;
		put.addSelectionListener(new class SelectionAdapter {
			override void widgetSelected(SelectionEvent e) {
				insert(lc ~ list.getText ~ lc);
			}
		});
	}
	Combo flags, steps;
	Button putFlag, putStep;
	create(flags, putFlag, prop.msgs.addMsgRefFlag, prop.images.flag, "%");
	create(steps, putStep, prop.msgs.addMsgRefStep, prop.images.step, "$");

	void refList() {
		auto root = comm.summary.flagDirRoot;
		auto fSel = flags.getText;
		auto sSel = steps.getText;
		flags.removeAll();
		foreach (i, flag; root.allFlags) {
			auto p = flag.path;
			flags.add(p);
			if (0 == i || 0 == icmp(p, fSel)) flags.select = i;
		}
		steps.removeAll();
		foreach (i, step; root.allSteps) {
			auto p = step.path;
			steps.add(p);
			if (0 == i || 0 == icmp(p, sSel)) steps.select = i;
		}
		flags.setEnabled = flags.getItemCount > 0;
		putFlag.setEnabled = flags.getEnabled;
		steps.setEnabled = steps.getItemCount > 0;
		putStep.setEnabled = steps.getEnabled;
	}
	refList();

	void refFlagAndStep(Flag[] flags, Step[] steps) {
		refList();
	}
	comm.refFlagAndStep.add(&refFlagAndStep);
	comm.delFlagAndStep.add(&refFlagAndStep);
	bar.addDisposeListener(new class DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			comm.refFlagAndStep.remove(&refFlagAndStep);
			comm.delFlagAndStep.remove(&refFlagAndStep);
		}
	});
	return bar;
}

private void putColor(FixedWidthText text, dchar put) {
	auto sel = text.widget.getSelection;
	auto old = toUTF32(text.getText);
	auto newt = cwx.utils.putColor(old, put, sel.x, sel.y);
	text.setText = toUTF8(newt);
	int nSel = sel.y + (newt.length - old.length);
	text.widget.setSelection(nSel);
}

class MsgPreview {
	private static class FlagData {
		Flag flag;
		bool onOff;
	}
	private static class StepData {
		Step step;
		int select;
	}
	private enum C {
		M = 0, // 選択中
		U = 1, // 選択外
		R = 2, // ランダム
		C = 3, // カード
		I = 4, // 話者
		T = 5, // チーム
		Y = 6 // 宿
	}
	private static immutable C_TBL = [
		'M',
		'U',
		'R',
		'C',
		'I',
		'T',
		'Y'
	];

	private Commons _comm;
	private Props _prop;
	private Summary _summ;
	private WSize _size;
	private Button _toggle;

	private Shell _win;
	private ControlListener _winL;
	private int _parX, _parY;
	private Canvas _canvas;
	private Table _values;
	private Image _img = null;

	private Talker _talker = Talker.NARRATION;
	private string _imgPath = "";
	private string _message = "";

	private class Paint : PaintListener {
		override void paintControl(PaintEvent e) {
			auto b = _canvas.getBounds;
			auto rect = _prop.looks.messageBounds;
			e.gc.drawImage(_img, (b.width - rect.width) / 2, (b.height - rect.height) / 2);
		}
	}
	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_win.getParent.removeControlListener(_winL);
			if (_img) _img.dispose();
			_comm.refFlagAndStep.remove(&refFlagAndStep);
			_prop.var.etc.messageVarSelected = _values.getItem(C.M).getText(1);
			_prop.var.etc.messageVarUnselected = _values.getItem(C.U).getText(1);
			_prop.var.etc.messageVarRandom = _values.getItem(C.R).getText(1);
			_prop.var.etc.messageVarCard = _values.getItem(C.C).getText(1);
			_prop.var.etc.messageVarRef = _values.getItem(C.I).getText(1);
			_prop.var.etc.messageVarTeam = _values.getItem(C.T).getText(1);
			_prop.var.etc.messageVarYado = _values.getItem(C.Y).getText(1);
			_prop.var.etc.messageVarKindColumn = _values.getColumn(0).getWidth;
			_prop.var.etc.messageVarValueColumn = _values.getColumn(1).getWidth;
			saveWin();
		}
	}
	private class PShellL : ControlAdapter {
		override void controlMoved(ControlEvent e) {
			auto pb = _win.getParent.getBounds;
			auto tb = _win.getBounds;
			_win.setBounds(tb.x + pb.x - _parX, tb.y + pb.y - _parY, tb.width, tb.height);
			_parX = pb.x;
			_parY = pb.y;
		}
	}
	private class ShellL : ShellAdapter {
		override void shellClosed(ShellEvent e) {
			close();
			e.doit = false;
		}
	}
	private void refreshFlags() {
		int[string] pvs;

		if (C.max + 1 < _values.getItemCount) {
			foreach (i; C.max .. _values.getItemCount) {
				auto itm = _values.getItem(i);
				string key = cwx.utils.toLower(itm.getText(0));
				auto o = itm.getData;
				auto f = cast(FlagData) o;
				if (f) pvs[key] = f.onOff ? 1 : 0;
				auto s = cast(StepData) o;
				if (s) pvs[key] = s.select;
			}
			_values.remove(C.max + 1, _values.getItemCount);
		}
		foreach (f; _summ.flagDirRoot.allFlags) {
			auto itm = new TableItem(_values, SWT.NONE);
			auto path = f.path;
			itm.setImage(0, _prop.images.flag);
			itm.setText(0, path);
			itm.setText(1, f.onOff ? f.on : f.off);
			auto d = new FlagData;
			itm.setData = d;
			d.flag = f;
			d.onOff = f.onOff;
			auto p = cwx.utils.toLower(path) in pvs;
			if (p) {
				if (*p == 1) {
					itm.setText(1, f.on);
					d.onOff = true;
				} else if (*p == 0) {
					itm.setText(1, f.off);
					d.onOff = false;
				}
			}
		}
		foreach (f; _summ.flagDirRoot.allSteps) {
			auto itm = new TableItem(_values, SWT.NONE);
			auto path = f.path;
			itm.setImage(0, _prop.images.step);
			itm.setText(0, path);
			itm.setText(1, f.values[f.select]);
			auto d = new StepData;
			itm.setData = d;
			d.step = f;
			d.select = f.select;
			auto p = cwx.utils.toLower(path) in pvs;
			if (p) {
				if (0 <= *p && *p < f.values.length) {
					itm.setText(1, f.values[*p]);
					d.select = *p;
				}
			}
		}
	}
	private void refFlagAndStep(Flag[] flags, Step[] steps) {
		refreshFlags();
	}
	private Control createEditor(TableItem itm, int editC) {
		auto fd = cast(FlagData) itm.getData;
		if (fd) {
			return createComboEditor!Combo(_comm, _prop, itm.getParent, [fd.flag.on, fd.flag.off], itm.getText(1));
		}
		auto sd = cast(StepData) itm.getData;
		if (sd) {
			return createComboEditor!Combo(_comm, _prop, itm.getParent, sd.step.values, itm.getText(1));
		}
		return createTextEditor(_comm, _prop, itm.getParent, itm.getText(1));
	}
	private void editEnd(TableItem itm, int column, Control ctrl) {
		auto old = itm.getText(column);
		auto text = cast(Text) ctrl;
		if (text) itm.setText(column, text.getText);
		auto combo = cast(Combo) ctrl;
		if (combo) {
			itm.setText(column, combo.getText);
			auto fd = cast(FlagData) itm.getData;
			if (fd) fd.onOff = combo.getSelectionIndex == 1;
			auto sd = cast(StepData) itm.getData;
			if (sd) sd.select = combo.getSelectionIndex;
		}
		if (old != itm.getText) refresh();
	}

	this (Shell parent, Commons comm, Props prop, Summary summ, Button toggle, WSize size) {
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_size = size;
		_toggle = toggle;

		_winL = new PShellL;
		parent.addControlListener(_winL);

		_win = new Shell(parent, SWT.TITLE | SWT.RESIZE | SWT.TOOL | SWT.CLOSE);
		_win.setText = _prop.msgs.dlgTitMessagePreview;
		_win.setLayout = zeroGridLayout(1, true);
		_win.addShellListener(new ShellL);

		_canvas = new Canvas(_win, SWT.DOUBLE_BUFFERED);
		auto cgd = new GridData(GridData.FILL_HORIZONTAL);
		auto rect = _prop.looks.messageBounds;
		cgd.widthHint = rect.width;
		cgd.heightHint = rect.height;
		_canvas.setLayoutData = cgd;
		_canvas.addPaintListener(new Paint);
		_canvas.addDisposeListener(new Dispose);

		_values = new Table(_win, SWT.BORDER | SWT.FULL_SELECTION);
		auto vgd = new GridData(GridData.FILL_BOTH);
		vgd.heightHint = _prop.var.etc.messageVarTableHeight;
		_values.setLayoutData = vgd;
		_values.setHeaderVisible = true;
		auto kindCol = new TableColumn(_values, SWT.NONE);
		kindCol.setText = _prop.msgs.messageVarKindColumn;
		kindCol.setWidth = _prop.var.etc.messageVarKindColumn;
		auto valueCol = new TableColumn(_values, SWT.NONE);
		valueCol.setText = _prop.msgs.messageVarValueColumn;
		valueCol.setWidth = _prop.var.etc.messageVarValueColumn;

		foreach (i; C.min .. C.max + 1) {
			auto itm = new TableItem(_values, SWT.NONE);
			final switch (cast(C) i) {
			case C.M:
				itm.setImage(0, _prop.images.scTalker(Talker.SELECTED));
				itm.setText(0, _prop.msgs.scTalker(Talker.SELECTED));
				itm.setText(1, _prop.var.etc.messageVarSelected);
				break;
			case C.U:
				itm.setImage(0, _prop.images.scTalker(Talker.UNSELECTED));
				itm.setText(0, _prop.msgs.scTalker(Talker.UNSELECTED));
				itm.setText(1, _prop.var.etc.messageVarUnselected);
				break;
			case C.R:
				itm.setImage(0, _prop.images.scTalker(Talker.RANDOM));
				itm.setText(0, _prop.msgs.scTalker(Talker.RANDOM));
				itm.setText(1, _prop.var.etc.messageVarRandom);
				break;
			case C.C:
				itm.setImage(0, _prop.images.scTalker(Talker.CARD));
				itm.setText(0, _prop.msgs.scTalker(Talker.CARD));
				itm.setText(1, _prop.var.etc.messageVarCard);
				break;
			case C.I:
				itm.setImage(0, _prop.images.scRef);
				itm.setText(0, _prop.msgs.scRef);
				itm.setText(1, _prop.var.etc.messageVarRef);
				break;
			case C.T:
				itm.setImage(0, _prop.images.scTeam);
				itm.setText(0, _prop.msgs.scTeam);
				itm.setText(1, _prop.var.etc.messageVarTeam);
				break;
			case C.Y:
				itm.setImage(0, _prop.images.scYado);
				itm.setText(0, _prop.msgs.scYado);
				itm.setText(1, _prop.var.etc.messageVarYado);
				break;
			}
		}
		refreshFlags();
		_comm.refFlagAndStep.add(&refFlagAndStep);

		new TableTCEdit(_values, 1, &createEditor, &editEnd, null);
	}
	private void saveWin() {
		auto winProps = _size;
		winProps.width = _win.getSize.x;
		winProps.height = _win.getSize.y;
		winProps.x = _win.getBounds.x - _win.getParent.getBounds.x;
		winProps.y = _win.getBounds.y - _win.getParent.getBounds.y;
	}

	bool isVisible() {return _win.isVisible;}

	void open() {
		if (_win.isVisible) return;
		auto pb = _win.getParent.getBounds;
		_parX = pb.x;
		_parY = pb.y;
		auto winProps = _size;
		scope wp = _win.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		int width = winProps.width == SWT.DEFAULT ? wp.x : winProps.width;
		int height = winProps.height == SWT.DEFAULT ? wp.y : winProps.height;
		int x = winProps.x == SWT.DEFAULT ? pb.x + pb.width : winProps.x + pb.x;
		int y = winProps.y == SWT.DEFAULT ? pb.y : winProps.y + pb.y;
		intoDisplay(x, y, width, height);
		_win.setBounds(x, y, width, height);
		_win.setVisible = true;
		_toggle.setSelection = true;
	}
	void close() {
		if (!_win.isVisible) return;
		saveWin();
		_win.setVisible = false;
		_toggle.setSelection = false;
	}

	void text(Talker talker, string imgPath, string message) {
		if (_img && talker is _talker && imgPath == _imgPath && message == _message) {
			return;
		}
		_talker = talker;
		_imgPath = imgPath;
		_message = message;
		refresh();
	}

	private void refresh() {
		auto d = _canvas.getDisplay;
		if (_img) {
			_img.dispose();
		}
		ImageData tImg = null;
		final switch (_talker) {
		case Talker.NARRATION:
			tImg = null;
			break;
		case Talker.SELECTED:
		case Talker.UNSELECTED:
		case Talker.RANDOM:
			tImg = _prop.images.talker(_talker).getImageData;
			break;
		case Talker.IMAGE:
			tImg = loadImage(_comm.skin.findImagePath(_imgPath, _summ.scenarioPath), true);
			break;
		case Talker.CARD:
			auto cRect = _prop.looks.cardSize;
			tImg = menuCard(_comm.skin).scaledTo(cRect.width, cRect.height);
			break;
		}

		string[char] names;
		string[string] flags;
		foreach (i; C.min .. C.max + 1) {
			names[C_TBL[cast(C) i]] = _values.getItem(i).getText(1);
		}
		foreach (i; C.max .. _values.getItemCount) {
			auto itm = _values.getItem(i);
			flags[itm.getText(0)] = itm.getText(1);
		}
		_img = new Image(d, previewMessage(_comm, _prop, _summ.scenarioPath, tImg, _message, [], names, flags));
		_canvas.redraw();
	}
}

/// メッセージのプレビューを生成する。
ImageData previewMessage(Commons comm, Props prop, string sPath, ImageData talker, string message, in string[] sel, in string[char] names, /+ FIXME: リンクエラー！ +//+in +/string[string] flags) {
	auto d = Display.getCurrent;
	version (Windows) {
		bool legacy = comm.skin.legacy;
	} else {
		bool legacy = false;
	}
	auto rect = prop.looks.messageBounds;
	auto bh = prop.looks.messageButtonHeight;
	auto canvas = new Image(d, rect.width, rect.height + bh * sel.length);
	scope (exit) canvas.dispose;
	auto gc = new GC(canvas);
	scope (exit) gc.dispose;
	int alpha;

	// 背景の描画
	auto back = new Color(d, dwtData(prop.looks.messageBackColor, alpha));
	scope (exit) back.dispose();
	gc.setBackground = back;
	gc.fillRectangle(3, 3, rect.width - 6, rect.height - 6);
	foreach (i; 0 .. sel.length) {
		gc.fillRectangle(3, rect.height + 3 + bh * i, rect.width - 6, bh - 6);
	}

	// 文章と特殊文字の描画

	// 改行置換
	if (.contains(message, '\r')) {
		message = message.splitlines.join("\n");
	}
	// 特殊文字・フラグ・ステップ・色
	string[size_t] rFonts;
	char[size_t] rColors;
	string fValue(string path) {
		foreach (f, v; flags) {
			if (0 == icmp(f, path)) {
				return v;
			}
		}
		return "";
	}
	message = formatMsg(message, &fValue, &fValue, delegate string (char name) {
		auto dc = std.ascii.toUpper(name);
		foreach (c, v; names) {
			if (std.ascii.toUpper(c) == dc) {
				return v;
			}
		}
		return "";
	}, rFonts, rColors);
	auto dmsg = to!dstring(message);

	CPoint[] spFontP;
	string[] spFont;
	RGB[] spColor;
	auto cr = d.getSystemColor(SWT.COLOR_RED);
	auto cb = d.getSystemColor(SWT.COLOR_BLUE);
	auto cg = d.getSystemColor(SWT.COLOR_GREEN);
	auto cy = d.getSystemColor(SWT.COLOR_YELLOW);

	auto font = new Font(d, dwtData(prop.looks.messageFont(legacy)));
	scope (exit) font.dispose();
	auto fc = new Color(d, dwtData(prop.looks.messageForeColor, alpha));
	scope (exit) fc.dispose();
	auto hc = new Color(d, dwtData(prop.looks.messageHemColor, alpha));
	scope (exit) hc.dispose();
	auto selFont = new Font(d, dwtData(prop.looks.messageSelectFont(legacy)));
	scope (exit) selFont.dispose();

	auto start = prop.looks.messageStartPos(legacy, talker !is null);
	int x = start.x, y = start.y;
	int lineH;
	string old = "";
	void ret() {
		x = start.x;
		y += lineH;
		old = "";
	}
	if (legacy) {
		auto textCanvas = new Image(d, rect.width, rect.height + bh * sel.length);
		scope (exit) textCanvas.dispose();
		auto tgc = new GC(textCanvas);
		scope (exit) tgc.dispose();
		// FIXME: IPAフォントの使用とアンチエイリアス設定を
		//        同時に行うと一部環境で問題が出る。
//		tgc.setTextAntialias = SWT.OFF;
		tgc.setFont = font;
		tgc.setForeground = fc;
		tgc.setBackground = hc;
		tgc.fillRectangle(0, 0, rect.width, rect.height + bh * sel.length);
		lineH = tgc.getFontMetrics.getHeight + 2;
		for (size_t i = 0; i < dmsg.length; i++) {
			if (rect.height - 6 < y + lineH) {
				// 行数オーバー
				break;
			}
			auto cf = i in rFonts;
			if (cf) {
				// 特殊文字の描画位置を記憶
				string s1 = to!string(dmsg[i]);
				i++;
				string s2 = to!string(dmsg[i]);
				spFontP ~= CPoint(x - 2, y - 2);
				spFont ~= *cf;
				spColor ~= tgc.getForeground.getRGB;
				x += tgc.textExtent(s1).x - 1;
				x += tgc.textExtent(s2).x - 1;
				continue;
			}
			auto cp = i in rColors;
			if (cp) {
				// フォント色変更
				switch (*cp) {
				case 'W': tgc.setForeground = fc; break;
				case 'R': tgc.setForeground = cr; break;
				case 'B': tgc.setForeground = cb; break;
				case 'G': tgc.setForeground = cg; break;
				case 'Y': tgc.setForeground = cy; break;
				default: assert (0);
				}
				i++;
				continue;
			}
			auto c = dmsg[i];
			switch (c) {
			case '\n':
				x = start.x;
				y += lineH;
				break;
			default:
				auto s = to!string(c);
				int w = tgc.textExtent(s).x - 1;
				if (rect.width - 6 < x + w) {
					// 列数オーバー
					ret();
					if (rect.height - 6 < y + lineH) {
						// 行数オーバー
						break;
					}
				}
				tgc.drawText(s, x, y, true);
				x += w;
				break;
			}
		}

		// 選択肢
		tgc.setForeground = fc;
		tgc.setFont = selFont;
		auto slh = tgc.getFontMetrics.getHeight;
		int sx;
		int sy = rect.height + ((bh - slh) / 2);
		foreach (i, t; sel) {
			sx = (rect.width - tgc.textExtent(t).x) / 2;
			tgc.drawText(t, sx, sy, true);
			sy += bh;
		}

		// 貼り付け
		auto tImgData = textCanvas.getImageData;
		tImgData.transparentPixel = tImgData.getPixel(0, 0);
		auto hemImgData = new ImageData(tImgData.width, tImgData.height, 2, new PaletteData([new RGB(255, 255, 255), new RGB(0, 0, 0)]));
		hemImgData.transparentPixel = 0;
		foreach (ix; 0 .. tImgData.width) {
			foreach (iy; 0 .. tImgData.height) {
				if (tImgData.getPixel(ix, iy) != tImgData.transparentPixel) {
					hemImgData.setPixel(ix, iy, 1);
				}
			}
		}
		auto hemImg = new Image(d, hemImgData);
		scope (exit) hemImg.dispose();
		auto tImg = new Image(d, tImgData);
		scope (exit) tImg.dispose();
		gc.drawImage(hemImg, -1, -1);
		gc.drawImage(hemImg, 0, -1);
		gc.drawImage(hemImg, 1, -1);
		gc.drawImage(hemImg, 1, 0);
		gc.drawImage(hemImg, 1, 1);
		gc.drawImage(hemImg, 0, 1);
		gc.drawImage(hemImg, -1, 1);
		gc.drawImage(hemImg, -1, 0);
		gc.drawImage(tImg, 0, 0);
	} else {
		// FIXME: IPAフォントの使用とアンチエイリアス設定を
		//        同時に行うと一部環境で問題が出る。
//		gc.setTextAntialias = SWT.ON;
		gc.setFont = font;
		lineH = gc.getFontMetrics.getHeight;

		void drawText(string s, int x, int y) {
			if ("―" == s && "―" == old) {
				// "―"の場合のみ表示を接続する処理が入る
				gc.setForeground = hc;
				gc.drawText(s, x, y - 1, true);
				gc.drawText(s, x, y + 1, true);
				gc.drawText(s, x - lineH / 2 + 2, y - 1, true);
				gc.drawText(s, x - lineH / 2 + 2, y + 1, true);
				gc.setForeground = fc;
				gc.drawText(s, x - lineH / 2, y, true);
				gc.drawText(s, x, y, true);
			} else {
				gc.setForeground = hc;
				gc.drawText(s, x - 1, y, true);
				gc.drawText(s, x + 1, y, true);
				gc.drawText(s, x, y - 1, true);
				gc.drawText(s, x, y + 1, true);
				gc.setForeground = fc;
				gc.drawText(s, x, y, true);
			}
			old = s;
		}
		for (size_t i = 0; i < dmsg.length; i++) {
			if (rect.height - 6 < y + lineH) {
				// 行数オーバー
				break;
			}
			auto cf = i in rFonts;
			if (cf) {
				// 特殊文字の描画位置を記憶
				string s1 = to!string(dmsg[i]);
				i++;
				string s2 = to!string(dmsg[i]);
				spFontP ~= CPoint(x, y - 2);
				spFont ~= *cf;
				spColor ~= gc.getForeground.getRGB;
				x += gc.textExtent(s1).x - 1;
				x += gc.textExtent(s2).x - 1;
				continue;
			}
			auto cp = i in rColors;
			if (cp) {
				// フォント色変更
				switch (*cp) {
				case 'W': gc.setForeground = fc; break;
				case 'R': gc.setForeground = cr; break;
				case 'B': gc.setForeground = cb; break;
				case 'G': gc.setForeground = cg; break;
				case 'Y': gc.setForeground = cy; break;
				default: assert (0);
				}
				i++;
				continue;
			}
			auto c = dmsg[i];
			switch (c) {
			case '\n':
				ret();
				break;
			default:
				auto s = to!string(c);
				int w = gc.textExtent(s).x;
				if (rect.width - 6 < x + w) {
					// 列数オーバー
					ret();
					if (rect.height - 6 < y + lineH) {
						// 行数オーバー
						break;
					}
				}
				drawText(s, x, y);
				x += w;
				break;
			}
		}

		// 選択肢
		gc.setForeground = fc;
		gc.setFont = selFont;
		auto slh = gc.getFontMetrics.getHeight;
		int sx;
		int sy = rect.height + ((bh - slh) / 2);
		foreach (i, t; sel) {
			sx = (rect.width - gc.textExtent(t).x) / 2;
			drawText(t, sx, sy);
			sy += bh;
		}
	}

	// フォントイメージ
	auto wrgb = fc.getRGB;
	for (size_t i = 0; i < spFontP.length; i++) {
		auto pt = spFontP[i];
		auto path = spFont[i];
		string fpath = comm.skin.findImagePath(path, sPath);
		ImageData data = null;
		if (fpath && fpath.length) {
			// シナリオ内特殊文字
			data = loadImage(fpath, true);
		}
		if (!data) {
			// 標準特殊文字
			auto c = spColor[i];
			data = spChar(comm.skin, decodeFontPath(path));
			if (data && !wrgb.opEquals(c)) {
				auto spc = data;
				data = new ImageData(spc.width, spc.height, 24, new PaletteData(0xFF << 16, 0xFF << 8, 0xFF << 0));
				// &R等による色の置換
				foreach (dx; 0 .. data.width) {
					foreach (dy; 0 .. data.height) {
						auto p = spc.palette.getRGB(spc.getPixel(dx, dy));
						if (wrgb.opEquals(p)) {
							data.setPixel(dx, dy, (c.red << 16) | (c.green << 8) | (c.blue << 0));
						} else {
							data.setPixel(dx, dy, (p.red << 16) | (p.green << 8) | (p.blue << 0));
						}
					}
				}
				data.transparentPixel = data.getPixel(0, 0);
			}
		}
		if (data) {
			auto img = new Image(d, data);
			scope (exit) img.dispose();
			gc.drawImage(img, pt.x, pt.y);
		}
	}

	// 話者
	if (talker) {
		auto tImg = new Image(d, talker);
		scope (exit) tImg.dispose();
		auto tp = prop.looks.messageTalkerPos;
		gc.drawImage(tImg, tp.x, tp.y);
	}

	// 枠
	auto c1 = new Color(d, dwtData(prop.looks.messageLineColor1, alpha));
	scope (exit) c1.dispose();
	auto c2 = new Color(d, dwtData(prop.looks.messageLineColor2, alpha));
	scope (exit) c2.dispose();
	gc.setForeground = c1;
	gc.drawRectangle(0, 0, rect.width - 1, rect.height - 1);
	gc.drawRectangle(2, 2, rect.width - 5, rect.height - 5);
	foreach (i; 0 .. sel.length) {
		gc.drawRectangle(0, rect.height + bh * i, rect.width - 1, bh - 1);
		gc.drawRectangle(2, rect.height + 2 + bh * i, rect.width - 5, bh - 5);
	}
	gc.setForeground = c2;
	gc.drawRectangle(1, 1, rect.width - 3, rect.height - 3);
	foreach (i; 0 .. sel.length) {
		gc.drawRectangle(1, rect.height + 1 + bh * i, rect.width - 3, bh - 3);
	}

	return canvas.getImageData;
}
