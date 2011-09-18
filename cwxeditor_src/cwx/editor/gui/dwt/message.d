
module cwx.editor.gui.dwt.message;

import cwx.utils;
import cwx.types;
import cwx.event;
import cwx.summary;
import cwx.skin;
import cwx.xml;

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
import org.eclipse.swt.dnd.Clipboard;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.DragSourceAdapter;
import org.eclipse.swt.dnd.DragSourceEvent;
import org.eclipse.swt.dnd.DragSource;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.DropTarget;
import org.eclipse.swt.dnd.Clipboard;
import org.eclipse.swt.dnd.Transfer;

class SpeakDialog : EventDialog {
private:
	string _id;

	Combo _talkers;
	SDialog[] _dlgs;
	Table _dlgsL;
	Text _rCoupons;
	Combo _rCouponsList;
	FixedWidthText _text;

	void selectChanged() {
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		auto dlg = _dlgs[_dlgsL.getSelectionIndex];
		string rcs;
		foreach (rc; dlg.rCoupons) {
			rcs ~= rc;
			rcs ~= '\n';
		}
		_rCoupons.setText = rcs;
		_text.setText = dlg.text;
	}
	void createDialog(SDialog dlg) {
		insertDialog(dlg, _dlgsL.getSelectionIndex);
	}
	void createDialog() {
		createDialog(new SDialog);
	}
	void insertDialog(SDialog dlg, int index) {
		if (index < 0) index = _dlgs.length;
		_dlgs = _dlgs[0 .. index] ~ dlg ~ _dlgs[index .. $];
		auto itm = new TableItem(_dlgsL, SWT.NONE, index);
		itm.setImage = prop.images.content(CType.TALK_DIALOG);
		_dlgsL.setSelection = [itm];
		_dlgsL.showSelection;
		selectChange;
		applyEnabled();
	}
	void deleteDialog(int index) {
		if (index < 0 || _dlgs.length <= 1) return;
		bool sel = _dlgsL.getSelectionIndex == index;
		_dlgs = _dlgs[0 .. index] ~ _dlgs[index + 1 .. $];
		_dlgsL.remove(index);
		if (sel) {
			_dlgsL.select = index < _dlgs.length ? index : _dlgs.length - 1;
			_oldSel = _dlgs[_dlgsL.getSelectionIndex];
			selectChanged;
		}
		applyEnabled();
	}
	void deleteDialogSel() {
		deleteDialog(_dlgsL.getSelectionIndex);
	}
	void up() {
		int index = _dlgsL.getSelectionIndex;
		if (index > 0) {
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
	SDialog _oldSel;
	void sets() {
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		_oldSel.text = lastRet(wrapReturnCode(_text.getText));
		string[] rcs;
		foreach (rc; splitLines(_rCoupons.getText)) {
			if (rc.length > 0) {
				rcs ~= rc;
			}
		}
		_oldSel.rCoupons = rcs;
		_oldSel = _dlgs[_dlgsL.getSelectionIndex];
	}
	void selectChange() {
		sets;
		selectChanged;
	}
	class SelL : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			selectChange;
		}
	}
	class ModL : ModifyListener {
		override void modifyText(ModifyEvent e) {
			string text = std.array.replace(wrapReturnCode(_text.getText), "\n", "");
			// FIXME: ""をsetTextするとArgument cannot be null
			_dlgsL.getItem(_dlgsL.getSelectionIndex).setText(0, text != "" ? text : " ");
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
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				XMLtoCB(prop, cb, d.toNode.text);
			}
		}
		void paste(SelectionEvent se) {
			auto cb = new Clipboard(Display.getCurrent);
			scope (exit) cb.dispose;
			auto xml = CBtoXML(cb);
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
				scope p = (cast(DropTarget) e.getSource).getControl.toControl(e.x, e.y);
				auto t = _dlgsL.getItem(p);
				int index = t ? _dlgsL.indexOf(t) : _dlgsL.getItemCount;
				insertDialog(SDialog.createFromNode(node, LATEST_VERSION), index);
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
				deleteDialog(_dlgsL.indexOf(_itm));
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
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime);
		super(comm, prop, shell, summ, CType.TALK_DIALOG, parent, evt, true, prop.var.speakDlg, false);
	}
protected:
	override void setup(Composite area) {
		area.setLayout = windowGridLayout(1, true);
		{
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData = new GridData(GridData.FILL_BOTH);
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
			createMenuItem(menu, prop.msgs.menuUp, prop.images.menuUp, &up);
			createMenuItem(menu, prop.msgs.menuDown, prop.images.menuDown, &down);
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(prop, menu, new DialogsTCPD);
			_dlgsL.setMenu = menu;
			usingPopupMenuAccelerator(_dlgsL);

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
			auto comp = new Composite(area, SWT.NONE);
			comp.setLayoutData = new GridData(GridData.FILL_BOTH);
			comp.setLayout = new GridLayout(2, false);
			Control tp;
			if (evt) {
				tp = createTalkerPane2(comp, comm, prop, summ, evt.talkerNC, evt.dialogs[0].rCoupons, _talkers, _rCoupons, _rCouponsList);
			} else {
				tp = createTalkerPane2(comp, comm, prop, summ, Talker.SELECTED, [], _talkers, _rCoupons, _rCouponsList);
			}
			mod(_talkers);
			mod(_rCoupons);
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
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (evt) {
			foreach (dlg; evt.dialogs) {
				auto itm = new TableItem(_dlgsL, SWT.NONE);
				itm.setImage = prop.images.content(CType.TALK_DIALOG);
				string text = std.array.replace(dlg.text, "\n", "");
				// FIXME: ""をsetTextするとArgument cannot be null
				itm.setText = text.length > 0 ? text : " ";
				_dlgs ~= new SDialog(dlg.text, dlg.rCoupons);
			}
			_oldSel = _dlgs[0];
			_dlgsL.select = 0;
			selectChanged;
		} else {
			auto itm = new TableItem(_dlgsL, SWT.NONE);
			itm.setImage = prop.images.content(CType.TALK_DIALOG);
			_dlgs = [new SDialog];
			_oldSel = _dlgs[0];
			_dlgsL.select = 0;
		}
	}
	override bool apply() {
		sets;
		Talker talker;
		switch (_talkers.getSelectionIndex) {
		case 0:
			talker = Talker.SELECTED;
			break;
		case 1:
			talker = Talker.UNSELECTED;
			break;
		case 2:
			talker = Talker.RANDOM;
			break;
		default: assert (0);
		}
		if (!evt) evt = new Content(CType.TALK_DIALOG, "");
		evt.dialogs = _dlgs;
		evt.talkerNC = talker;
		return true;
	}
}

class MessageDialog : EventDialog {
private:
	CTabFolder _tabf;
	FixedWidthText _textA, _textB;
	ImageSelect!(MtType.CARD, Combo) _msel;

	class SL : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			switch (_tabf.getSelectionIndex) {
			case 0:
				_textA.setText = _textB.getText;
				break;
			case 1:
				_textB.setText = _textA.getText;
				break;
			default: assert (0);
			}
		}
	}
	void put(dchar put) {
		switch (_tabf.getSelectionIndex) {
		case 0:
			putColor(_textA, put);
			break;
		case 1:
			putColor(_textB, put);
			break;
		default: assert (0);
		}
	}
	void insert(string put) {
		switch (_tabf.getSelectionIndex) {
		case 0:
			_textA.insert(put);
			break;
		case 1:
			_textB.insert(put);
			break;
		default: assert (0);
		}
	}
	protected override void refSkin() {
		_textA.font = dwtData(prop.looks.messageFont(summ.legacy));
		_textB.font = dwtData(prop.looks.messageFont(summ.legacy));
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) {
		super(comm, prop, shell, summ, CType.TALK_MESSAGE, parent, evt, true, prop.var.msgDlg, false);
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
			auto msgComp = new Composite(comp, SWT.NONE);
			msgComp.setLayoutData = new GridData(GridData.FILL_VERTICAL);
			msgComp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
			_textA = createMessagePane(comm, prop, true, msgComp, summ);
			_textA.widget.setLayoutData = _textA.computeTextBaseSize(prop.looks.messageLine);
			mod(_textA.widget);
			auto tab = new CTabItem(_tabf, SWT.NONE);
			tab.setText = prop.msgs.imageMessage;
			tab.setControl = comp;
		}
		{
			auto comp = new Composite(_tabf, SWT.NONE);
			comp.setLayout = new CenterLayout;
			_textB = createMessagePane(comm, prop, false, comp, summ);
			mod(_textB.widget);
			_textB.widget.setLayoutData = _textB.computeTextBaseSize(prop.looks.messageLine);
			auto tab = new CTabItem(_tabf, SWT.NONE);
			tab.setText = prop.msgs.noImageMessage;
			tab.setControl = comp;
		}
		{
			auto bar = createSCharBar(area, &insert, &put, prop, skin);
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		{
			auto bar = createSkinSCharBar(area, &insert, prop, skin);
			bar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		_tabf.addSelectionListener(new SL);
		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (evt) {
			_textA.setText = evt.text;
			_textB.setText = evt.text;
			if (evt.talkerC == Talker.NARRATION) {
				_tabf.setSelection = 1;
			}
		} else {
			_tabf.setSelection = 1;
		}
	}
	override bool apply() {
		string text;
		string path = "";
		Talker talker;
		switch (_tabf.getSelectionIndex) {
		case 0:
			text = lastRet(wrapReturnCode(_textA.getText));
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
				path = _msel.image;
			}
			break;
		case 1:
			text = lastRet(wrapReturnCode(_textB.getText));
			talker = Talker.NARRATION;
			break;
		default: assert (0);
		}
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
		default:
			msel.dirsCombo.select = 0;
		}
	}
	return comp;
}

private FixedWidthText createMessagePane(Commons comm, Props prop, bool image, Composite parent, Summary summ) {
	int len = image ? prop.looks.messageImageLen : prop.looks.messageLen;
	auto r = new FixedWidthText(dwtData(prop.looks.messageFont(summ.legacy)), len, parent, SWT.BORDER);
	r.widget.setBackground = Display.getCurrent.getSystemColor(SWT.COLOR_DARK_BLUE);
	r.widget.setForeground = Display.getCurrent.getSystemColor(SWT.COLOR_WHITE);
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

private void putColor(FixedWidthText text, dchar put) {
	auto sel = text.widget.getSelection;
	auto old = toUTF32(text.getText);
	auto newt = cwx.utils.putColor(old, put, sel.x, sel.y);
	text.setText = toUTF8(newt);
	int nSel = sel.y + (newt.length - old.length);
	text.widget.setSelection(nSel);
}
