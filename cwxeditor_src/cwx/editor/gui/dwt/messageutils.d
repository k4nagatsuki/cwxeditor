
module cwx.editor.gui.dwt.messageutils;

import cwx.utils;
import cwx.types;
import cwx.event;
import cwx.summary;
import cwx.skin;
import cwx.xml;
import cwx.flag;
import cwx.path;
import cwx.structs;
import cwx.msgutils;
import cwx.menu;
import cwx.types;
import cwx.imagesize;
import cwx.system;

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
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.couponview;
import cwx.editor.gui.dwt.chooser;

import std.array;
import std.utf;
import std.string;
import std.datetime;
import std.conv;
import std.exception;

import org.eclipse.swt.all;
import java.lang.all;

/// 台詞コンテント・メッセージコンテントのダイアログの親クラス。
class AbstractMessageDialog : EventDialog {
	private KeyDownFilter _kdFilter;
	private MsgPreviewWindow _previewWin = null;
	private MsgPreview _preview = null;
	private UndoManager _undo;

	private class SelPrev : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto btn = cast(Button) e.widget;
			if (btn.getSelection()) { mixin(S_TRACE);
				auto s = wrapReturnCode(text);
				if (_previewWin) { mixin(S_TRACE);
					if (_previewWin.isVisible()) return;
					_previewWin.text(selectedTalker, "", s);
					_previewWin.open();
				} else { mixin(S_TRACE);
					if (rightGroup.isVisible()) return;
					_preview.text(selectedTalker, imgPath, s);
					setPreviewLData(true);
				}
			} else { mixin(S_TRACE);
				if (_previewWin) { mixin(S_TRACE);
					if (!_previewWin.isVisible()) return;
					_previewWin.close();
				} else { mixin(S_TRACE);
					if (!rightGroup.isVisible()) return;
					setPreviewLData(false);
				}
			}
		}
	}
	private void setPreviewLData(bool visible, bool regWin = true) { mixin(S_TRACE);
		bool oVisible = rightGroup.isVisible();
		assert (_preview);
		rightGroup.setVisible(visible);
		int pvw;
		if (!visible) { mixin(S_TRACE);
			pvw = rightGroup.getSize().x;
		}
		int w = visible ? prop.looks.messageBounds.width : 0;
		int h = 0;
		rightGroupSize(w, h);

		if (getShell().isVisible()) getShell().setRedraw(false);
		scope (exit) {
			if (getShell().isVisible()) getShell().setRedraw(true);
		}
		if (regWin && oVisible != visible) { mixin(S_TRACE);
			auto ws = getShell().getSize();
			if (visible) { mixin(S_TRACE);
				pvw = rightGroup.getSize().x;
			}
			if (visible) { mixin(S_TRACE);
				ws.x += pvw;
			} else { mixin(S_TRACE);
				ws.x -= pvw;
			}
			getShell().setSize(ws);
		}
	}
	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			comm.refMenu.remove(&refMenu);
			comm.refUndoMax.remove(&refUndoMax);
			getShell().getDisplay().removeFilter(SWT.KeyDown, _kdFilter);
			if (_preview) { mixin(S_TRACE);
				if (type is CType.TALK_MESSAGE) { mixin(S_TRACE);
					prop.var.etc.showMessagePreview = _preview.isVisible();
				} else if (type is CType.TALK_DIALOG) { mixin(S_TRACE);
					prop.var.etc.showDialogPreview = _preview.isVisible();
				} else assert (0);
			}
		}
	}

	private class KeyDownFilter : Listener {
		this () { mixin(S_TRACE);
			refMenu(MenuID.Undo);
			refMenu(MenuID.Redo);
		}
		override void handleEvent(Event e) { mixin(S_TRACE);
			auto c = cast(Control) e.widget;
			if (!c || c.getShell() !is getShell()) return;
			if (!canHookKeyDown(c)) return;
			if (cast(Text) c) return;
			if (eqAcc(_undoAcc, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
				_undo.undo();
				e.doit = false;
			} else if (eqAcc(_redoAcc, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
				_undo.redo();
				e.doit = false;
			}
		}
	}
	protected bool canHookKeyDown(Control fc) { mixin(S_TRACE);
		return !_preview || !_preview.focusInValues;
	}
	private int _undoAcc;
	private int _redoAcc;
	private void refMenu(MenuID id) { mixin(S_TRACE);
		if (id == MenuID.Undo) _undoAcc = convertAccelerator(prop.buildMenu(MenuID.Undo));
		if (id == MenuID.Redo) _redoAcc = convertAccelerator(prop.buildMenu(MenuID.Redo));
	}
	private void refUndoMax() { mixin(S_TRACE);
		_undo.max = prop.var.etc.undoMaxEtc;
	}

	protected void initPreview(Composite area, WSize size) { mixin(S_TRACE);
		auto aComp = addition();
		aComp.setLayout(new GridLayout(1, true));
		auto prev = new Button(aComp, SWT.TOGGLE);
		prev.setText(prop.msgs.messagePreview);
		bool show;
		if (type is CType.TALK_MESSAGE) { mixin(S_TRACE);
			show = prop.var.etc.showMessagePreview;
		} else if (type is CType.TALK_DIALOG) { mixin(S_TRACE);
			show = prop.var.etc.showDialogPreview;
		} else assert (0);
		prev.setSelection(show);
		prev.addSelectionListener(new SelPrev);

		if (prop.var.etc.floatMessagePreview) { mixin(S_TRACE);
			_previewWin = new MsgPreviewWindow(getShell(), comm, prop, summ, prev, size);
		} else { mixin(S_TRACE);
			_preview = new MsgPreview(rightGroup, comm, prop, summ);
			rightGroup.setLayout(zeroGridLayout(1, false));
			_preview.setLayoutData(new GridData(GridData.FILL_BOTH));
			setPreviewLData(show, false);
		}
		refreshPreview();
	}

	this (Commons comm, Props prop, Shell shell, Summary summ, CType type, Content parent, Content evt, DSize size) { mixin(S_TRACE);
		super (comm, prop, shell, summ, type, parent, evt, true, size, false, !prop.var.etc.floatMessagePreview);
		_undo = new UndoManager(prop.var.etc.undoMaxEtc);
	}

	override
	protected void opened() { mixin(S_TRACE);
		if (!_previewWin) return;
		if (type is CType.TALK_MESSAGE) { mixin(S_TRACE);
			if (prop.var.etc.showMessagePreview) _previewWin.open();
			closeEvent ~= { mixin(S_TRACE);
				prop.var.etc.showMessagePreview = _previewWin.isVisible();
			};
		} else if (type is CType.TALK_DIALOG) { mixin(S_TRACE);
			if (prop.var.etc.showDialogPreview) _previewWin.open();
			closeEvent ~= { mixin(S_TRACE);
				prop.var.etc.showDialogPreview = _previewWin.isVisible();
			};
		} else assert (0);
	}

	protected override void setup(Composite area) { mixin(S_TRACE);
		area.addDisposeListener(new Dispose);
		_kdFilter = new KeyDownFilter;
		area.getDisplay().addFilter(SWT.KeyDown, _kdFilter);
		comm.refMenu.add(&refMenu);
		comm.refUndoMax.add(&refUndoMax);

	}

	void refreshPreview() { mixin(S_TRACE);
		if (!_previewWin && !_preview) return;
		auto s = wrapReturnCode(text);
		if (_previewWin) { mixin(S_TRACE);
			_previewWin.text(selectedTalker, imgPath, s);
			_previewWin.refresh();
		} else { mixin(S_TRACE);
			_preview.text(selectedTalker, imgPath, s);
			_preview.refresh();
		}
	}

	@property
	abstract string text();

	@property
	abstract Talker selectedTalker();

	@property
	abstract string imgPath();
}

/// 台詞コンテントの設定ダイアログ。
class SpeakDialog : AbstractMessageDialog {
private:
	class APData {
		int selDlg;
		SDialog[] dlgs;
	}
	Object readAPD(Object old) { mixin(S_TRACE);
		auto o = new APData;
		o.selDlg = _dlgsL.getSelectionIndex();
		foreach (d; _dlgs) { mixin(S_TRACE);
			o.dlgs ~= new SDialog(d);
		}
		return o;
	}
	void writeAPD(Object o) { mixin(S_TRACE);
		bool oldIgnoreMod = ignoreMod;
		ignoreMod = true;
		scope (exit) ignoreMod = oldIgnoreMod;
		auto apd = cast(APData)o;
		assert (apd);
		foreach (i, d; apd.dlgs) { mixin(S_TRACE);
			_dlgs[i] = new SDialog(d);
		}
		refreshDlgList();
		_dlgsL.select(apd.selDlg);
		selectChanged();
	}
	class SUndo : Undo {
		private SDialog[] _dlgs;
		private int _selDlg;
		this () { mixin(S_TRACE);
			save();
		}
		private void save() { mixin(S_TRACE);
			_dlgs = [];
			foreach (d; this.outer._dlgs) { mixin(S_TRACE);
				_dlgs ~= new SDialog(d);
			}
			_selDlg = _dlgsL.getSelectionIndex();
		}
		private void impl() { mixin(S_TRACE);
			auto dlgs = _dlgs;
			int selDlg = _selDlg;
			save();

			this.outer._dlgs = [];
			foreach (dlg; dlgs) { mixin(S_TRACE);
				this.outer._dlgs ~= new SDialog(dlg);
			}
			refreshDlgList();
			_dlgsL.select(selDlg);
			selectChanged();
		}
		override void undo() {impl();}
		override void redo() {impl();}
		override void dispose() { mixin(S_TRACE);
			// Nothing
		}
	}
	void storeEdit() { mixin(S_TRACE);
		_undo ~= new SUndo;
	}
	void updateValue() { mixin(S_TRACE);
		int max = _initValue.getSelection();
		int min = max;
		foreach (cp; _couponView.coupons) { mixin(S_TRACE);
			if (cp.value < 0) { mixin(S_TRACE);
				min -= cp.value;
			} else { mixin(S_TRACE);
				max += cp.value;
			}
		}
		if (0 >= min) { mixin(S_TRACE);
			_couponView.toolTip = .tryFormat(prop.msgs.valuedTalkerMaxMinLess0, max, min);
		} else { mixin(S_TRACE);
			_couponView.toolTip = .tryFormat(prop.msgs.valuedTalkerMaxMin, max, min);
		}
	}

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;

		if (prop.targetVersion("1.50")) { mixin(S_TRACE);
			if (Talker.VALUED is selectedTalker) { mixin(S_TRACE);
				ws ~= prop.msgs.warningValuedTalker;
			}
		}

		warning = ws;
	}

	string _id;

	Combo _talkers;
	SDialog[] _dlgs;
	Table _dlgsL;
	Text _rCoupons;
	Combo _rCouponsList;
	FixedWidthText _text;
	TextMenuModify _textTM, _rCouponsTM;
	CouponView!(CVType.Valued) _couponView;
	Spinner _initValue;

	protected override bool canHookKeyDown(Control fc) { mixin(S_TRACE);
		return super.canHookKeyDown(fc) && !isDescendant(_couponView, fc);
	}
	void selectChanged() { mixin(S_TRACE);
		bool oldIgnoreMod = ignoreMod;
		ignoreMod = true;
		scope (exit) ignoreMod = oldIgnoreMod;
		auto dlg = _dlgs[_dlgsL.getSelectionIndex()];
		string rcs;
		foreach (rc; dlg.rCoupons) { mixin(S_TRACE);
			rcs ~= rc;
			rcs ~= '\n';
		}
		_rCoupons.setText(rcs);
		_text.setText(dlg.text);
		auto len = dlg.text.length;
		_text.widget.setSelection(len, len);
		refreshPreview();
		comm.refreshToolBar();
	}
	void createDialog(SDialog dlg) { mixin(S_TRACE);
		insertDialog(dlg, _dlgsL.getSelectionIndex());
	}
	void createDialog() { mixin(S_TRACE);
		createDialog(new SDialog);
	}
	void insertDialog(SDialog dlg, int index, bool store = true) { mixin(S_TRACE);
		if (store) storeEdit();
		if (index < 0) index = _dlgs.length;
		_dlgs = _dlgs[0 .. index] ~ dlg ~ _dlgs[index .. $];
		auto itm = new TableItem(_dlgsL, SWT.NONE, index);
		itm.setImage(prop.images.content(CType.TALK_DIALOG));
		_dlgsL.setSelection([itm]);
		_dlgsL.showSelection();
		selectChanged();
		applyEnabled();
	}
	void deleteDialog(int index, bool store = true) { mixin(S_TRACE);
		if (index < 0 || _dlgs.length <= 1) return;
		if (store) storeEdit();
		bool sel = _dlgsL.getSelectionIndex() == index;
		_dlgs = _dlgs[0 .. index] ~ _dlgs[index + 1 .. $];
		_dlgsL.remove(index);
		if (sel) { mixin(S_TRACE);
			_dlgsL.select(index < _dlgs.length ? index : _dlgs.length - 1);
			selectChanged();
		} else { mixin(S_TRACE);
			comm.refreshToolBar();
		}
		applyEnabled();
	}
	void deleteDialogSel() { mixin(S_TRACE);
		deleteDialog(_dlgsL.getSelectionIndex());
	}
	void overDialog() { mixin(S_TRACE);
		int index = _dlgsL.getSelectionIndex();
		if (index > 0) { mixin(S_TRACE);
			_dlgsL.select(index - 1);
			selectChanged();
		}
	}
	void underDialog() { mixin(S_TRACE);
		int index = _dlgsL.getSelectionIndex();
		if (index + 1 < _dlgs.length) { mixin(S_TRACE);
			_dlgsL.select(index + 1);
			selectChanged();
		}
	}
	void up() { mixin(S_TRACE);
		int index = _dlgsL.getSelectionIndex();
		if (index > 0) { mixin(S_TRACE);
			storeEdit();
			auto temp = _dlgs[index - 1];
			_dlgs[index - 1] = _dlgs[index];
			_dlgs[index] = temp;
			auto tempL = _dlgsL.getItem(index - 1).getText();
			_dlgsL.getItem(index - 1).setText(_dlgsL.getItem(index).getText());
			_dlgsL.getItem(index).setText(tempL);
			_dlgsL.select(index - 1);
			applyEnabled();
			comm.refreshToolBar();
		}
	}
	void down() { mixin(S_TRACE);
		int index = _dlgsL.getSelectionIndex();
		if (index + 1 < _dlgs.length) { mixin(S_TRACE);
			storeEdit();
			auto temp = _dlgs[index + 1];
			_dlgs[index + 1] = _dlgs[index];
			_dlgs[index] = temp;
			auto tempL = _dlgsL.getItem(index + 1).getText();
			_dlgsL.getItem(index + 1).setText(_dlgsL.getItem(index).getText());
			_dlgsL.getItem(index).setText(tempL);
			_dlgsL.select(index + 1);
			applyEnabled();
			comm.refreshToolBar();
		}
	}
	void copyToUpper() { mixin(S_TRACE);
		storeEdit();
		int index = _dlgsL.getSelectionIndex();
		string textL = _dlgsL.getItem(index).getText();
		string text = lastRet(wrapReturnCode(_text.getText()));
		for (int i = 0; i < index; i++) { mixin(S_TRACE);
			_dlgsL.getItem(i).setText(textL);
			_dlgs[i].text = text;
		}
		applyEnabled();
		comm.refreshToolBar();
	}
	void copyToLower() { mixin(S_TRACE);
		storeEdit();
		int index = _dlgsL.getSelectionIndex();
		string textL = _dlgsL.getItem(index).getText();
		string text = lastRet(wrapReturnCode(_text.getText()));
		for (int i = index + 1; i < _dlgs.length; i++) { mixin(S_TRACE);
			_dlgsL.getItem(i).setText(textL);
			_dlgs[i].text = text;
		}
		applyEnabled();
		comm.refreshToolBar();
	}
	void copyToDialogs() { mixin(S_TRACE);
		storeEdit();
		int index = _dlgsL.getSelectionIndex();
		string textL = _dlgsL.getItem(index).getText();
		string text = lastRet(wrapReturnCode(_text.getText()));
		foreach (i, dlg; _dlgs) { mixin(S_TRACE);
			if (i != index) { mixin(S_TRACE);
				_dlgsL.getItem(i).setText(textL);
				dlg.text = text;
			}
		}
		applyEnabled();
		comm.refreshToolBar();
	}
	void put(dchar put) { mixin(S_TRACE);
		putColor(_text, put);
	}
	void insert(string put) { mixin(S_TRACE);
		_text.insert(put);
	}
	void putText(SDialog dlg) { mixin(S_TRACE);
		dlg.text = lastRet(wrapReturnCode(_text.getText()));
	}
	void putRCoupons(SDialog dlg) { mixin(S_TRACE);
		string[] rcs;
		foreach (rc; splitLines!string(_rCoupons.getText())) { mixin(S_TRACE);
			if (rc.length > 0) { mixin(S_TRACE);
				rcs ~= rc;
			}
		}
		dlg.rCoupons = rcs;
	}
	void updateTalker() { mixin(S_TRACE);
		_couponView.enabled = (Talker.VALUED is selectedTalker);
		_initValue.setEnabled(_couponView.enabled);
		comm.refreshToolBar();
	}
	class SelL : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			selectChanged();
		}
	}
	class SelectTalker : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			refreshPreview();
			refreshWarning();
			updateTalker();
		}
	}
	private void refreshDlgList(int index) { mixin(S_TRACE);
		string text = wrapReturnCode(_dlgs[index].text).singleLine;
		// FIXME: ""をsetTextするとArgument cannot be null
		if (text == "") text = " ";
		_dlgsL.getItem(index).setText(0, text);
	}
	class ModL : ModifyListener {
		override void modifyText(ModifyEvent e) { mixin(S_TRACE);
			if (_textTM && _rCouponsTM && !_textTM.inProc() && !_rCouponsTM.inProc()) { mixin(S_TRACE);
				putText(_dlgs[_dlgsL.getSelectionIndex()]);
			}
			refreshDlgList(_dlgsL.getSelectionIndex());
			refreshPreview();
		}
	}
	class ModRC : ModifyListener {
		override void modifyText(ModifyEvent e) { mixin(S_TRACE);
			if (_textTM && _rCouponsTM && !_textTM.inProc() && !_rCouponsTM.inProc()) { mixin(S_TRACE);
				putRCoupons(_dlgs[_dlgsL.getSelectionIndex()]);
			}
		}
	}
	@property
	SDialog selection() { mixin(S_TRACE);
		int index = _dlgsL.getSelectionIndex();
		return index >= 0 ? _dlgs[index] : null;
	}
	class DialogsTCPD : TCPD {
		void cut(SelectionEvent se) { mixin(S_TRACE);
			if (_dlgsL.getItemCount() > 1 && selection) { mixin(S_TRACE);
				copy(se);
				del(se);
			}
		}
		void copy(SelectionEvent se) { mixin(S_TRACE);
			auto d = selection;
			if (d) { mixin(S_TRACE);
				XMLtoCB(prop, comm.clipboard, d.toNode().text);
				comm.refreshToolBar();
			}
		}
		void paste(SelectionEvent se) { mixin(S_TRACE);
			auto xml = CBtoXML(comm.clipboard);
			if (xml) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					auto node = XNode.parse(xml);
					if (node.name == SDialog.XML_NAME) { mixin(S_TRACE);
						auto ver = new XMLInfo(prop.sys, LATEST_VERSION);
						createDialog(SDialog.createFromNode(node, ver));
					}
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		void del(SelectionEvent se) {deleteDialogSel();}
		void clone(SelectionEvent se) { mixin(S_TRACE);
			comm.clipboard.memoryMode = true;
			scope (exit) comm.clipboard.memoryMode = false;
			copy(se);
			paste(se);
		}
		@property bool canDoTCPD() {return _dlgsL.isFocusControl();}
		@property bool canDoT() {return _dlgsL.getSelectionIndex() > 0;}
		@property bool canDoC() {return canDoT;}
		@property bool canDoP() {return CBisXML(comm.clipboard);}
		@property bool canDoD() {return canDoT;}
		@property bool canDoClone() {return canDoC;}
	}
	class DDropListener : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = DND.DROP_MOVE;
		}
		override void dragOver(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = DND.DROP_MOVE;
		}
		override void drop(DropTargetEvent e){ mixin(S_TRACE);
			if (!isXMLBytes(e.data)) return;
			e.detail = DND.DROP_NONE;
			string xml = bytesToXML(e.data);
			try { mixin(S_TRACE);
				auto node = XNode.parse(xml);
				if (node.name != SDialog.XML_NAME) return;
				storeEdit();
				scope p = (cast(DropTarget) e.getSource()).getControl().toControl(e.x, e.y);
				auto t = _dlgsL.getItem(p);
				int index = t ? _dlgsL.indexOf(t) : _dlgsL.getItemCount();
				auto ver = new XMLInfo(prop.sys, LATEST_VERSION);
				insertDialog(SDialog.createFromNode(node, ver), index, false);
				if (_id == node.attr("paneId", false)) { mixin(S_TRACE);
					e.detail = DND.DROP_MOVE;
				}
			} catch {}
		}
	}
	class DDragListener : DragSourceAdapter {
		private TableItem _itm;
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl();
		}
		override void dragSetData(DragSourceEvent e){ mixin(S_TRACE);
			if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
				auto c = cast(Table) (cast(DragSource) e.getSource()).getControl();
				int index = c.getSelectionIndex();
				if (index >= 0) { mixin(S_TRACE);
					auto d = _dlgs[index];
					auto node = d.toNode();
					node.newAttr("paneId", _id);
					e.data = bytesFromXML(node.text);
					_itm = c.getItem(index);
				}
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			if (e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
				deleteDialog(_dlgsL.indexOf(_itm), false);
			}
		}
	}
	protected override void refSkin() { mixin(S_TRACE);
		_text.font = dwtData(prop.looks.messageFont(summ.legacy));
	}
	void refreshDlgList() { mixin(S_TRACE);
		bool oldIgnoreMod = ignoreMod;
		ignoreMod = true;
		scope (exit) ignoreMod = oldIgnoreMod;
		int selIndex = _dlgsL.getSelectionIndex();
		int topIndex = _dlgsL.getTopIndex();

		_dlgsL.removeAll();
		foreach (dlg; _dlgs) { mixin(S_TRACE);
			auto itm = new TableItem(_dlgsL, SWT.NONE);
			itm.setImage(prop.images.content(CType.TALK_DIALOG));
			string text = dlg.text.singleLine;
			// FIXME: ""をsetTextするとArgument cannot be null
			itm.setText(text.length > 0 ? text : " ");
		}

		if (selIndex < 0 || _dlgs.length <= selIndex) { mixin(S_TRACE);
			_dlgsL.select(0);
		} else { mixin(S_TRACE);
			_dlgsL.select(selIndex);
			_dlgsL.setTopIndex(topIndex);
		}
		if (selIndex != _dlgsL.getSelectionIndex()) { mixin(S_TRACE);
			selectChanged();
		} else { mixin(S_TRACE);
			comm.refreshToolBar();
		}
	}
	class DisposeLeftSash : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			auto sash = cast(SplitPane) e.widget;
			auto ws = sash.getWeights();
			prop.var.etc.talkLeftSashL = ws[0];
			prop.var.etc.talkLeftSashR = ws[1];
		}
	}
	class DisposeMainSash : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			auto sash = cast(SplitPane) e.widget;
			auto ws = sash.getWeights();
			prop.var.etc.talkMainSashL = ws[0];
			prop.var.etc.talkMainSashR = ws[1];
		}
	}

	private class KeyDownFilter : Listener {
		this () { mixin(S_TRACE);
			refMenu(MenuID.OverDialog);
			refMenu(MenuID.UnderDialog);
		}
		override void handleEvent(Event e) { mixin(S_TRACE);
			auto c = cast(Control) e.widget;
			if (!c || c.getShell() !is getShell()) return;
			if (_dlgsL is c) return;
			if (eqAcc(_overAcc, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
				overDialog();
				e.doit = false;
			} else if (eqAcc(_underAcc, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
				underDialog();
				e.doit = false;
			}
		}
	}
	private int _overAcc;
	private int _underAcc;
	private void refMenu(MenuID id) { mixin(S_TRACE);
		if (id == MenuID.OverDialog) _overAcc = convertAccelerator(prop.buildMenu(MenuID.OverDialog));
		if (id == MenuID.UnderDialog) _underAcc = convertAccelerator(prop.buildMenu(MenuID.UnderDialog));
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime());
		super(comm, prop, shell, summ, CType.TALK_DIALOG, parent, evt, prop.var.speakDlg);
	}

	override
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		auto cate = cpcategory(path);
		if ("dialog" == cate) { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= _dlgsL.getItemCount()) return false;
			_dlgsL.select(index);
			selectChanged();
			.forceFocus(_dlgsL, shellActivate);
			path = cpbottom(path);
			return cpempty(path);
		}
		return super.openCWXPath(path, shellActivate);
	}

	@property
	override
	string text() { mixin(S_TRACE);
		return wrapReturnCode(_text.getText());
	}

	@property
	override
	Talker selectedTalker() { mixin(S_TRACE);
		switch (_talkers.getSelectionIndex()) {
		case 0: return Talker.SELECTED;
		case 1: return Talker.UNSELECTED;
		case 2: return Talker.RANDOM;
		case 3: return Talker.VALUED;
		default: assert (0);
		}
	}

	@property
	override
	string imgPath() { mixin(S_TRACE);
		return "";
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		super.setup(area);

		area.setLayout(windowGridLayout(1, true));

		auto sash = new SplitPane(area, SWT.HORIZONTAL);
		sash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto left = new Composite(sash, SWT.NONE);
		left.setLayout(zeroMarginGridLayout(1, true));
		{ mixin(S_TRACE);
			auto grp = new Group(left, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setText(prop.msgs.talker);
			grp.setLayout(new GridLayout(1, true));
			_talkers = new Combo(grp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_talkers);
			_talkers.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_talkers.add(prop.msgs.talkerName(Talker.SELECTED));
			_talkers.add(prop.msgs.talkerName(Talker.UNSELECTED));
			_talkers.add(prop.msgs.talkerName(Talker.RANDOM));
			_talkers.add(prop.msgs.talkerName(Talker.VALUED));
			_talkers.addSelectionListener(new SelectTalker);
		}

		auto leftSash = new SplitPane(left, SWT.VERTICAL);
		leftSash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto skin = comm.skin;
		{ mixin(S_TRACE);
			auto grp = new Group(leftSash, SWT.NONE);
			grp.setText(prop.msgs.toneCoupons);
			grp.setLayout(new GridLayout(1, true));
			Control tp;
			if (evt) { mixin(S_TRACE);
				tp = createTalkerPane2(grp, comm, prop, summ, evt.dialogs[0].rCoupons, _rCoupons, _rCouponsList);
			} else { mixin(S_TRACE);
				tp = createTalkerPane2(grp, comm, prop, summ, [], _rCoupons, _rCouponsList);
			}
			mod(_rCoupons);
			_rCoupons.addModifyListener(new ModRC);
			tp.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		{ mixin(S_TRACE);
			auto grp = new Group(leftSash, SWT.NONE);
			grp.setText(prop.msgs.valued);
			grp.setLayout(new GridLayout(2, false));

			auto lbl = new Label(grp, SWT.NONE);
			lbl.setText(prop.msgs.initValue);
			_initValue = new Spinner(grp, SWT.BORDER);
			initSpinner(_initValue);
			mod(_initValue);
			_initValue.setMinimum(cast(int) prop.var.etc.couponValueMax * -1);
			_initValue.setMaximum(prop.var.etc.couponValueMax);
			_initValue.setSelection(1);
			_initValue.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			.listener(_initValue, SWT.Selection, &updateValue);
			_couponView = new CouponView!(CVType.Valued)(comm, summ, grp, SWT.NONE, &catchMod);
			mod(_couponView);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.horizontalSpan = 2;
			_couponView.setLayoutData(gd);
			_couponView.modEvent ~= &updateValue;
		}
		auto right = new Composite(sash, SWT.NONE);
		right.setLayout(zeroMarginGridLayout(2, false));
		{ mixin(S_TRACE);
			_dlgsL = new Table(right, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
			new FullTableColumn(_dlgsL, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = 0;
			gd.heightHint = 0;
			_dlgsL.setLayoutData(gd);
			_dlgsL.addSelectionListener(new SelL);

			auto drag = new DragSource(_dlgsL, DND.DROP_MOVE | DND.DROP_COPY);
			drag.setTransfer([XMLBytesTransfer.getInstance()]);
			drag.addDragListener(new DDragListener);
			auto drop = new DropTarget(_dlgsL, DND.DROP_DEFAULT | DND.DROP_MOVE | DND.DROP_COPY);
			drop.setTransfer([XMLBytesTransfer.getInstance()]);
			drop.addDropListener(new DDropListener);

			auto menu = new Menu(_dlgsL);
			createMenuItem(comm, menu, MenuID.Undo, {_undo.undo();}, &_undo.canUndo);
			createMenuItem(comm, menu, MenuID.Redo, {_undo.redo();}, &_undo.canRedo);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(comm, menu, MenuID.Up, &up, () => _dlgsL.getSelectionIndex() != -1 && 0 < _dlgsL.getSelectionIndex());
			createMenuItem(comm, menu, MenuID.Down, &down, () => _dlgsL.getSelectionIndex() != -1 && _dlgsL.getSelectionIndex() + 1 < _dlgsL.getItemCount());
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(comm, menu, MenuID.OverDialog, &overDialog, () => _dlgsL.getSelectionIndex() != -1 && 0 < _dlgsL.getSelectionIndex());
			createMenuItem(comm, menu, MenuID.UnderDialog, &underDialog, () => _dlgsL.getSelectionIndex() != -1 && _dlgsL.getSelectionIndex() + 1 < _dlgsL.getItemCount());
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(comm, menu, new DialogsTCPD, true, true, true, true, true);
			_dlgsL.setMenu(menu);

			auto bar = new ToolBar(right, SWT.FLAT | SWT.VERTICAL);
			comm.put(bar);
			bar.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			bar.addListener(SWT.Traverse, new class Listener {
				override void handleEvent(Event e) {e.doit = true;}
			});
			bar.addListener(SWT.KeyDown, new class Listener {
				override void handleEvent(Event e) {e.doit = true;}
			});
			createToolItem2(comm, bar, prop.msgs.createDialog, prop.images.createDialog, &createDialog, null);
			createToolItem2(comm, bar, prop.msgs.deleteDialog, prop.images.deleteDialog, &deleteDialogSel, () => _dlgsL.getItemCount() > 1 && _dlgsL.getSelectionIndex() != -1);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(comm, bar, MenuID.Up, &up, () => _dlgsL.getSelectionIndex() != -1 && 0 < _dlgsL.getSelectionIndex());
			createToolItem(comm, bar, MenuID.Down, &down, () => _dlgsL.getSelectionIndex() != -1 && _dlgsL.getSelectionIndex() + 1 < _dlgsL.getItemCount());
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem2(comm, bar, prop.msgs.copyToDialogs, prop.images.copyToDialogs, &copyToDialogs, () => _dlgsL.getSelectionIndex() != -1 && _dlgsL.getItemCount() > 1);
			createToolItem2(comm, bar, prop.msgs.copyToUpper, prop.images.copyToUpper, &copyToUpper, () => _dlgsL.getSelectionIndex() != -1 && 0 < _dlgsL.getSelectionIndex());
			createToolItem2(comm, bar, prop.msgs.copyToLower, prop.images.copyToLower, &copyToLower, () => _dlgsL.getSelectionIndex() != -1 && _dlgsL.getSelectionIndex() + 1 < _dlgsL.getItemCount());
		}
		{ mixin(S_TRACE);
			auto msgComp = new Composite(right, SWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.horizontalSpan = 2;
			msgComp.setLayoutData(gd);
			msgComp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
			_text = createMessagePane(comm, prop, true, msgComp, summ);
			mod(_text.widget);
			_text.widget.setLayoutData(_text.computeTextBaseSize(prop.looks.messageLine));
			_text.widget.addModifyListener(new ModL);
		}
		{ mixin(S_TRACE);
			auto bar = createSCharBar(comm, area, &insert, &put, prop, skin);
			bar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}
		{ mixin(S_TRACE);
			auto bar = createSkinSCharBar(comm, area, &insert, prop, skin);
			bar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}
		{ mixin(S_TRACE);
			auto bar = createFlagStepBar(area, &insert, comm, prop);
			bar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}

		leftSash.setWeights([prop.var.etc.talkLeftSashL, prop.var.etc.talkLeftSashR]);
		leftSash.addDisposeListener(new DisposeLeftSash);
		sash.setWeights([prop.var.etc.talkMainSashL, prop.var.etc.talkMainSashR]);
		sash.addDisposeListener(new DisposeMainSash);
		auto kdFilter = new KeyDownFilter;
		area.getDisplay().addFilter(SWT.KeyDown, kdFilter);
		comm.refMenu.add(&refMenu);
		.listener(area, SWT.Dispose, { mixin(S_TRACE);
			area.getDisplay().removeFilter(SWT.KeyDown, kdFilter);
			comm.refMenu.remove(&refMenu);
		});

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		if (evt) { mixin(S_TRACE);
			switch (evt.talkerNC) {
			case Talker.SELECTED:
				_talkers.select(0);
				break;
			case Talker.UNSELECTED:
				_talkers.select(1);
				break;
			case Talker.RANDOM:
				_talkers.select(2);
				break;
			case Talker.VALUED:
				_talkers.select(3);
				break;
			default:
				_talkers.select(0);
			}
			foreach (dlg; evt.dialogs) { mixin(S_TRACE);
				_dlgs ~= new SDialog(dlg.text, dlg.rCoupons);
			}
			_couponView.coupons = evt.coupons;
			_initValue.setSelection(evt.initValue);
		} else { mixin(S_TRACE);
			_talkers.select(0);
			_dlgs = [new SDialog];
		}
		refreshDlgList();

		_textTM = createTextMenu!Text(comm, prop, _rCoupons, &catchMod, _undo, TMAppendData(&readAPD, &writeAPD));
		_rCouponsTM = createTextMenu!Text(comm, prop, _text.widget, &catchMod, _undo, TMAppendData(&readAPD, &writeAPD));

		initPreview(area, prop.var.dlgPrev);
		updateValue();
		updateTalker();
		refreshWarning();
	}

	override bool apply() { mixin(S_TRACE);
		if (!evt) evt = new Content(CType.TALK_DIALOG, "");
		evt.dialogs = _dlgs;
		evt.talkerNC = selectedTalker;
		if (Talker.VALUED is evt.talkerNC) { mixin(S_TRACE);
			evt.coupons = _couponView.coupons;
			evt.initValue = _initValue.getSelection();
		} else { mixin(S_TRACE);
			evt.coupons = [];
			evt.initValue = 0;
		}
		comm.refCoupons.call();
		return true;
	}
}

/// メッセージコンテントの設定ダイアログ。
class MessageDialog : AbstractMessageDialog {
private:
	CTabFolder _tabf;
	Composite _msgCompA, _msgCompB;
	FixedWidthText _text;
	ImageSelect!(MtType.CARD, Combo) _msel;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;

		ws ~= _msel.warnings;

		warning = ws;
	}
	void tabChanged() { mixin(S_TRACE);
		switch (_tabf.getSelectionIndex()) {
		case 0:
			_text.num = prop.looks.messageImageLen;
			_text.widget.setParent(_msgCompA);
			break;
		case 1:
			_text.num = prop.looks.messageLen;
			_text.widget.setParent(_msgCompB);
			break;
		default: return;
		}
		_text.widget.setLayoutData(_text.computeTextBaseSize(prop.looks.messageLine));
		_text.widget.getParent().layout();
		if (0 == _tabf.getSelectionIndex()) { mixin(S_TRACE);
			_text.widget.getParent().getParent().layout();
		}
		refreshPreview();
	}
	class SL : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			tabChanged();
		}
	}
	class ModText : ModifyListener {
		override void modifyText(ModifyEvent e) { mixin(S_TRACE);
			refreshPreview();
		}
	}
	void put(dchar put) { mixin(S_TRACE);
		putColor(_text, put);
	}
	void insert(string put) { mixin(S_TRACE);
		_text.insert(put);
	}
	protected override void refSkin() { mixin(S_TRACE);
		_text.font = dwtData(prop.looks.messageFont(summ.legacy));
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super(comm, prop, shell, summ, CType.TALK_MESSAGE, parent, evt, prop.var.msgDlg);
	}

	void selectedTalkerParam(out Talker talker, out string imgPath) { mixin(S_TRACE);
		imgPath = "";
		switch (_tabf.getSelectionIndex()) {
		case 0:
			switch (_msel.dirsCombo.getSelectionIndex()) {
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

	@property
	override Talker selectedTalker() { mixin(S_TRACE);
		Talker talker;
		string imgPath;
		selectedTalkerParam(talker, imgPath);
		return talker;
	}
	@property
	override string imgPath() { mixin(S_TRACE);
		Talker talker;
		string imgPath;
		selectedTalkerParam(talker, imgPath);
		return imgPath;
	}
	@property
	override string text() { mixin(S_TRACE);
		return wrapReturnCode(_text.getText());
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		super.setup(area);

		area.setLayout(new GridLayout(1, true));
		_tabf = new CTabFolder(area, SWT.BORDER);
		mod(_tabf);
		_tabf.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto skin = comm.skin;
		{ mixin(S_TRACE);
			auto comp = new Composite(_tabf, SWT.NONE);
			comp.setLayout(new GridLayout(2, false));
			Control tp;
			if (evt) { mixin(S_TRACE);
				tp = createTalkerPane(comp, comm, prop, summ, evt.talkerC, evt.cardPath, _msel);
			} else { mixin(S_TRACE);
				tp = createTalkerPane(comp, comm, prop, summ, Talker.SELECTED, "", _msel);
			}
			mod(_msel);
			_msel.modEvent ~= &refreshWarning;
			_msel.cardMode = CardMode.Message;
			tp.setLayoutData(new GridData(GridData.FILL_BOTH));
			_msgCompA = new Composite(comp, SWT.NONE);
			_msgCompA.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			_msgCompA.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
			_text = createMessagePane(comm, prop, true, _msgCompA, summ);
			mod(_text.widget);
			_text.widget.addModifyListener(new ModText);
			createTextMenu!Text(comm, prop, _text.widget, &catchMod, _undo);
			auto tab = new CTabItem(_tabf, SWT.NONE);
			tab.setText(prop.msgs.imageMessage);
			tab.setControl(comp);
		}
		{ mixin(S_TRACE);
			_msgCompB = new Composite(_tabf, SWT.NONE);
			_msgCompB.setLayout(new CenterLayout);
			auto tab = new CTabItem(_tabf, SWT.NONE);
			tab.setText(prop.msgs.noImageMessage);
			tab.setControl(_msgCompB);
		}
		{ mixin(S_TRACE);
			auto bar = createSCharBar(comm, area, &insert, &put, prop, skin);
			bar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}
		{ mixin(S_TRACE);
			auto bar = createSkinSCharBar(comm, area, &insert, prop, skin);
			bar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}
		{ mixin(S_TRACE);
			auto bar = createFlagStepBar(area, &insert, comm, prop);
			bar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}

		_tabf.addSelectionListener(new SL);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		_tabf.setSelection(0);
		if (evt) { mixin(S_TRACE);
			_text.setText(evt.text);
			if (evt.talkerC == Talker.NARRATION) { mixin(S_TRACE);
				_tabf.setSelection(1);
			}
		} else { mixin(S_TRACE);
			_tabf.setSelection(1);
		}
		tabChanged();

		initPreview(area, prop.var.msgPrev);
		_msel.modEvent ~= &refreshPreview;
		_msel.updateImageEvent ~= &refreshPreview;
	}

	override bool apply() { mixin(S_TRACE);
		string text;
		string path = "";
		Talker talker;
		selectedTalkerParam(talker, path);
		text = lastRet(wrapReturnCode(_text.getText()));
		if (!evt) evt = new Content(CType.TALK_MESSAGE, "");
		evt.text = text;
		evt.talkerC = talker;
		evt.cardPath = path;
		return true;
	}
}

private Composite createTalkerPane2(Composite parent, Commons comm, Props prop, Summary summ,
		string[] coupons, out Text couponList, out Combo couponCombo) { mixin(S_TRACE);
	auto comp = new Composite(parent, SWT.NONE);
	comp.setLayout(zeroMarginGridLayout(2, false));
	couponCombo = createCouponCombo(comm, summ, comp, null, CouponComboType.Talker);
	auto push = new Button(comp, SWT.PUSH);
	auto skin = comm.skin;
	{ mixin(S_TRACE);
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		gd.widthHint = prop.var.etc.talkersWidth;
		couponCombo.setLayoutData(gd);
		push.setToolTipText(prop.msgs.setTalkerCoupon);
		push.setImage(prop.images.setTalkerCoupon);
	}
	{ mixin(S_TRACE);
		couponList = new Text(comp, SWT.BORDER | SWT.MULTI | SWT.V_SCROLL);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.horizontalSpan = 2;
		couponList.setLayoutData(gd);
		string buf;
		foreach (coupon; coupons) { mixin(S_TRACE);
			buf ~= coupon ~ "\n";
		}
		couponList.setText(buf);
		push.addSelectionListener(new class SelectionAdapter {
			private Combo _combo;
			private Text _list;
			this() { mixin(S_TRACE);
				_combo = couponCombo;
				_list = couponList;
			}
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				if (_combo.getText().length > 0) { mixin(S_TRACE);
					_list.setSelection(_list.getText().length, _list.getText().length);
					string[] lines = splitLines!string(_list.getText());
					if (lines.length > 0 && lines[$ - 1].length > 0) { mixin(S_TRACE);
						_list.insert("\n");
					}
					_list.insert(_combo.getText() ~ "\n");
				}
			}
		});
	}
	return comp;
}

private Composite createTalkerPane
		(Composite parent, Commons comm, Props prop, Summary summ, Talker talker, string path,
		out ImageSelect!(MtType.CARD, Combo) msel) { mixin(S_TRACE);
	auto comp = new Composite(parent, SWT.NONE);
	{ mixin(S_TRACE);
		comp.setLayout(zeroMarginGridLayout(1, true));
	}
	auto selected = prop.images.talker(Talker.SELECTED).getImageData();
	auto unselected = prop.images.talker(Talker.UNSELECTED).getImageData();
	auto random = prop.images.talker(Talker.RANDOM).getImageData();
	ImageData createDefImage(size_t index) { mixin(S_TRACE);
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
		prop.msgs.talkerName(Talker.SELECTED),
		prop.msgs.talkerName(Talker.UNSELECTED),
		prop.msgs.talkerName(Talker.RANDOM),
		prop.msgs.talkerName(Talker.CARD)
	];
	auto s = prop.looks.cardSize;
	msel = new ImageSelect!(MtType.CARD, Combo)(comp, SWT.NONE, comm, prop, summ, s.width, s.height,
		false, false, () => "", null, defs, &createDefImage);
	auto gd = new GridData(GridData.FILL_BOTH);
	msel.widget.setLayoutData(gd);
	msel.image = path;
	if (msel.image.length == 0) { mixin(S_TRACE);
		switch (talker) {
		case Talker.SELECTED:
			msel.dirsCombo.select(0);
			break;
		case Talker.UNSELECTED:
			msel.dirsCombo.select(1);
			break;
		case Talker.RANDOM:
			msel.dirsCombo.select(2);
			break;
		case Talker.CARD:
			msel.dirsCombo.select(3);
			break;
		default:
			msel.dirsCombo.select(0);
		}
	}
	return comp;
}

private class DisposeText : DisposeListener {
	private Color _back, _fore;
	this (Color back, Color fore) { mixin(S_TRACE);
		_back = back;
		_fore = fore;
	}
	override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
		_back.dispose();
		_fore.dispose();
	}
}
private FixedWidthText createMessagePane(Commons comm, Props prop, bool image, Composite parent, Summary summ) { mixin(S_TRACE);
	int len = image ? prop.looks.messageImageLen : prop.looks.messageLen;
	auto r = new FixedWidthText(dwtData(prop.looks.messageFont(summ.legacy)), len, parent, SWT.BORDER, true);
	auto d = r.widget.getDisplay();
	auto back = new Color(d, new RGB(prop.var.etc.msgBackR, prop.var.etc.msgBackG, prop.var.etc.msgBackB));
	auto fore = new Color(d, new RGB(prop.var.etc.msgForeR, prop.var.etc.msgForeG, prop.var.etc.msgForeB));
	r.widget.setBackground(back);
	r.widget.setForeground(fore);
	r.widget.addDisposeListener(new DisposeText(back, fore));
	return r;
}

private class PutC {
	private void delegate(string) _insert;
	private string _put;
	this(void delegate(string) insert, string put) { mixin(S_TRACE);
		_insert = insert;
		_put = put;
	}
	void put() { mixin(S_TRACE);
		_insert(_put);
	}
}
private class PutColor {
	private void delegate(dchar) _put;
	private dchar _color;
	this(void delegate(dchar) put, dchar color) { mixin(S_TRACE);
		_put = put;
		_color = color;
	}
	void put() { mixin(S_TRACE);
		_put(_color);
	}
}

private ToolBar createSCharBar(Commons comm, Composite parent,
		void delegate(string) insert, void delegate(dchar) putColor, Props prop, Skin skin) { mixin(S_TRACE);
	auto bar = new ToolBar(parent, SWT.FLAT);
	comm.put(bar);
	bar.addListener(SWT.Traverse, new class Listener {
		override void handleEvent(Event e) {e.doit = true;}
	});
	bar.addListener(SWT.KeyDown, new class Listener {
		override void handleEvent(Event e) {e.doit = true;}
	});
	foreach (c; [
		'W', 'R', 'B', 'G', 'Y'
	] ~ [
		'O', 'P', 'L', 'D' // CardWirth 1.50
	]) { mixin(S_TRACE);
		string t;
		final switch (c) {
		case 'W': t = prop.msgs.colorW; break;
		case 'R': t = prop.msgs.colorR; break;
		case 'B': t = prop.msgs.colorB; break;
		case 'G': t = prop.msgs.colorG; break;
		case 'Y': t = prop.msgs.colorY; break;
		case 'O': t = prop.msgs.colorO; break; // CardWirth 1.50
		case 'P': t = prop.msgs.colorP; break; // CardWirth 1.50
		case 'L': t = prop.msgs.colorL; break; // CardWirth 1.50
		case 'D': t = prop.msgs.colorD; break; // CardWirth 1.50
		}
		createToolItem2(comm, bar, t, prop.images.color(c), &(new PutColor(putColor, c)).put, null);
	}
	new ToolItem(bar, SWT.SEPARATOR);
	createToolItem2(comm, bar, prop.msgs.scRef, prop.images.scRef, &(new PutC(insert, "#I")).put, null);
	createToolItem2(comm, bar, prop.msgs.scTalkerName(Talker.SELECTED), prop.images.scTalker(Talker.SELECTED),
		&(new PutC(insert, "#M")).put, null);
	createToolItem2(comm, bar, prop.msgs.scTalkerName(Talker.UNSELECTED), prop.images.scTalker(Talker.UNSELECTED),
		&(new PutC(insert, "#U")).put, null);
	createToolItem2(comm, bar, prop.msgs.scTalkerName(Talker.RANDOM), prop.images.scTalker(Talker.RANDOM),
		&(new PutC(insert, "#R")).put, null);
	createToolItem2(comm, bar, prop.msgs.scTalkerName(Talker.CARD), prop.images.scTalker(Talker.CARD),
		&(new PutC(insert, "#C")).put, null);
	createToolItem2(comm, bar, prop.msgs.scTeam, prop.images.scTeam, &(new PutC(insert, "#T")).put, null);
	createToolItem2(comm, bar, prop.msgs.scYado, prop.images.scYado, &(new PutC(insert, "#Y")).put, null);
	return bar;
}

private ToolBar createSkinSCharBar(Commons comm, Composite parent, void delegate(string) insert, Props prop, Skin skin) { mixin(S_TRACE);
	auto bar = new ToolBar(parent, SWT.FLAT);
	comm.put(bar);
	bar.addListener(SWT.Traverse, new class Listener {
		override void handleEvent(Event e) {e.doit = true;}
	});
	bar.addListener(SWT.KeyDown, new class Listener {
		override void handleEvent(Event e) {e.doit = true;}
	});
	Image[] imgs;
	foreach (spc; skin.spChars.keys) { mixin(S_TRACE);
		auto img = new Image(Display.getCurrent(), spChar(skin, spc));
		string name = toUTF8("#"d ~ spc);
		auto scp = new PutC(insert, name);
		createToolItem2(comm, bar, name, img, &scp.put, null);
		imgs ~= img;
	}
	bar.addDisposeListener(new class DisposeListener {
		private Image[] _imgs;
		this() {_imgs = imgs;}
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			foreach (img; _imgs) { mixin(S_TRACE);
				img.dispose();
			}
		}
	});
	return bar;
}

private Composite createFlagStepBar(Composite parent, void delegate(string) insert, Commons comm, Props prop) { mixin(S_TRACE);
	auto bar = new Composite(parent, SWT.NONE);
	bar.setLayout(zeroMarginGridLayout(2, true));
	void create(out Combo list, out Button put, string puts, Image image, string lc) { mixin(S_TRACE);
		auto comp = new Composite(bar, SWT.NONE);
		comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		comp.setLayout(zeroMarginGridLayout(2, false));
		list = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
		list.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
		list.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		put = new Button(comp, SWT.PUSH);
		put.setToolTipText(puts);
		put.setImage(image);
		put.addSelectionListener(new class SelectionAdapter {
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				insert(lc ~ list.getText() ~ lc);
			}
		});
	}
	Combo flags, steps;
	Button putFlag, putStep;
	create(flags, putFlag, prop.msgs.addMsgRefFlag, prop.images.flag, "%");
	create(steps, putStep, prop.msgs.addMsgRefStep, prop.images.step, "$");

	void refList() { mixin(S_TRACE);
		auto root = comm.summary.flagDirRoot;
		auto fSel = flags.getText();
		auto sSel = steps.getText();
		flags.removeAll();
		foreach (i, flag; root.allFlags) { mixin(S_TRACE);
			auto p = flag.path;
			flags.add(p);
			if (0 == i || 0 == icmp(p, fSel)) flags.select(i);
		}
		steps.removeAll();
		foreach (i, step; root.allSteps) { mixin(S_TRACE);
			auto p = step.path;
			steps.add(p);
			if (0 == i || 0 == icmp(p, sSel)) steps.select(i);
		}
		flags.setEnabled(flags.getItemCount() > 0);
		putFlag.setEnabled(flags.getEnabled());
		steps.setEnabled(steps.getItemCount() > 0);
		putStep.setEnabled(steps.getEnabled());
	}
	refList();

	void refFlagAndStep(Flag[] flags, Step[] steps) { mixin(S_TRACE);
		refList();
	}
	comm.refFlagAndStep.add(&refFlagAndStep);
	comm.delFlagAndStep.add(&refFlagAndStep);
	bar.addDisposeListener(new class DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			comm.refFlagAndStep.remove(&refFlagAndStep);
			comm.delFlagAndStep.remove(&refFlagAndStep);
		}
	});
	return bar;
}

private void putColor(FixedWidthText text, dchar put) { mixin(S_TRACE);
	auto sel = text.widget.getSelection();
	auto old = toUTF32(text.getText());
	auto newt = cwx.msgutils.putColor(old, put, sel.x, sel.y);
	text.setText(toUTF8(newt));
	int nSel = sel.y + (newt.length - old.length);
	text.widget.setSelection(nSel);
}

class MsgPreviewWindow {
	private MsgPreview _preview;

	private Button _toggle;
	private WSize _size;
	private Shell _win;
	private ControlListener _winL;
	private int _parX, _parY;

	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_win.getParent().removeControlListener(_winL);
			saveWin();
		}
	}
	private class PShellL : ControlAdapter {
		override void controlMoved(ControlEvent e) { mixin(S_TRACE);
			auto pb = _win.getParent().getBounds();
			auto tb = _win.getBounds();
			_win.setBounds(tb.x + pb.x - _parX, tb.y + pb.y - _parY, tb.width, tb.height);
			_parX = pb.x;
			_parY = pb.y;
		}
	}
	private class ShellL : ShellAdapter {
		override void shellClosed(ShellEvent e) { mixin(S_TRACE);
			close();
			e.doit = false;
		}
	}

	this (Shell parent, Commons comm, Props prop, Summary summ, Button toggle, WSize size) { mixin(S_TRACE);
		_size = size;
		_toggle = toggle;

		_winL = new PShellL;
		parent.addControlListener(_winL);

		_win = new Shell(parent, SWT.TITLE | SWT.RESIZE | SWT.TOOL | SWT.CLOSE);
		_win.setText(prop.msgs.dlgTitMessagePreview);
		auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
		cl.fillHorizontal = true;
		cl.fillVertical = true;
		_win.setLayout(cl);
		_win.addShellListener(new ShellL);
		_win.addDisposeListener(new Dispose);

		_preview = new MsgPreview(_win, comm, prop, summ);
	}

	private void saveWin() { mixin(S_TRACE);
		auto winProps = _size;
		winProps.width = _win.getSize().x;
		winProps.height = _win.getSize().y;
		winProps.x = _win.getBounds().x - _win.getParent().getBounds().x;
		winProps.y = _win.getBounds().y - _win.getParent().getBounds().y;
	}
	bool isVisible() {return _win.isVisible();}

	void open() { mixin(S_TRACE);
		if (_win.isVisible()) return;
		auto pb = _win.getParent().getBounds();
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
		refresh();
		_win.setVisible(true);
		_toggle.setSelection(true);
	}
	void close() { mixin(S_TRACE);
		if (!_win.isVisible()) return;
		saveWin();
		_win.setVisible(false);
		_toggle.setSelection(false);
	}

	void text(Talker talker, string imgPath, string message) { mixin(S_TRACE);
		_preview.text(talker, imgPath, message);
	}

	private void refresh() { mixin(S_TRACE);
		_preview.refresh();
	}
}

enum SPChar {
	M = 0, /// 選択中
	U = 1, /// 選択外
	R = 2, /// ランダム
	C = 3, /// カード
	I = 4, /// 話者
	T = 5, /// チーム
	Y = 6 /// 宿
}

immutable SPCHAR_ALL = [
	SPChar.M,
	SPChar.U,
	SPChar.R,
	SPChar.C,
	SPChar.I,
	SPChar.T,
	SPChar.Y,
];

immutable SPCHAR_TEXT = [
	SPChar.M,
	SPChar.U,
	SPChar.R,
	SPChar.T,
	SPChar.Y,
];

private immutable C_TBL = [
	'M',
	'U',
	'R',
	'C',
	'I',
	'T',
	'Y',
];

class PreviewValues : Composite {
	void delegate()[] modEvent;

	private static class FlagData {
		Flag flag;
		bool onOff;
	}
	private static class StepData {
		Step step;
		int select;
	}

	private Commons _comm;
	private Props _prop;
	private Summary _summ;

	private bool _isMessage;
	private const(SPChar)[] _targetChars;
	private Table _values;
	private int[SPChar] _indexTable;
	private UndoManager _undo;
	private bool _changedText = false;

	private class UndoPV : Undo {
		private string[char] _names;
		private bool[string] _flags;
		private int[string] _steps;
		this () { mixin(S_TRACE);
			getValues2(_names, _flags, _steps);
		}
		private void impl() { mixin(S_TRACE);
			string[char] names;
			bool[string] flags;
			int[string] steps;
			getValues2(names, flags, steps);
			setValues2(_names, _flags, _steps);
			_names = names;
			_flags = flags;
			_steps = steps;
			raiseModEvent();
		}
		override void undo() { impl(); }
		override void redo() { impl(); }
		override void dispose() { mixin(S_TRACE);
			// Nothing
		}
	}
	private void store() { mixin(S_TRACE);
		_undo ~= new UndoPV;
	}
	private void refUndoMax() { mixin(S_TRACE);
		_undo.max = _prop.var.etc.undoMaxEtc;
	}

	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.refUndoMax.remove(&refUndoMax);
			_comm.refFlagAndStep.remove(&refFlagAndStep);
			_comm.delFlagAndStep.remove(&refFlagAndStep);
			if (SPChar.M in _indexTable) _prop.var.etc.messageVarSelected = _values.getItem(_indexTable[SPChar.M]).getText(1);
			if (SPChar.U in _indexTable) _prop.var.etc.messageVarUnselected = _values.getItem(_indexTable[SPChar.U]).getText(1);
			if (SPChar.R in _indexTable) _prop.var.etc.messageVarRandom = _values.getItem(_indexTable[SPChar.R]).getText(1);
			if (SPChar.C in _indexTable) _prop.var.etc.messageVarCard = _values.getItem(_indexTable[SPChar.C]).getText(1);
			if (SPChar.I in _indexTable) _prop.var.etc.messageVarRef = _values.getItem(_indexTable[SPChar.I]).getText(1);
			if (SPChar.T in _indexTable) _prop.var.etc.messageVarTeam = _values.getItem(_indexTable[SPChar.T]).getText(1);
			if (SPChar.Y in _indexTable) _prop.var.etc.messageVarYado = _values.getItem(_indexTable[SPChar.Y]).getText(1);
			if (_isMessage) { mixin(S_TRACE);
				_prop.var.etc.messageVarKindColumn = _values.getColumn(0).getWidth();
				_prop.var.etc.messageVarValueColumn = _values.getColumn(1).getWidth();
			} else { mixin(S_TRACE);
				_prop.var.etc.textVarKindColumn = _values.getColumn(0).getWidth();
				_prop.var.etc.textVarValueColumn = _values.getColumn(1).getWidth();
			}
			_comm.refPreviewValues.call();
		}
	}

	private class Mod : ModifyListener {
		private TableItem _itm;
		this (TableItem itm) { mixin(S_TRACE);
			_itm = itm;
		}
		override void modifyText(ModifyEvent e) { mixin(S_TRACE);
			if (!_changedText) { mixin(S_TRACE);
				store();
				_changedText = true;
			}
			string text = ctrlText(cast(Control) e.widget);
			_itm.setText(1, text);
			raiseModEvent();
		}
	}

	private void refreshFlags() { mixin(S_TRACE);
		_values.setRedraw(false);
		scope (exit) _values.setRedraw(true);
		int topIndex = _values.getTopIndex();
		scope (exit) {
			if (_values.getItemCount() <= topIndex) {
				topIndex = _values.getItemCount() - 1;
			}
			_values.setTopIndex(topIndex);
		}
		int[string] pvs;
		string selPath = null;

		if (_targetChars.length < _values.getItemCount()) { mixin(S_TRACE);
			foreach (i; _targetChars.length .. _values.getItemCount()) { mixin(S_TRACE);
				auto itm = _values.getItem(i);
				string key = .toLower(itm.getText(0));
				auto o = itm.getData();
				auto f = cast(FlagData) o;
				if (f) pvs[key] = f.onOff ? 1 : 0;
				auto s = cast(StepData) o;
				if (s) pvs[key] = s.select;
				if (i == _values.getSelectionIndex()) { mixin(S_TRACE);
					selPath = key;
				}
			}
			_values.remove(_targetChars.length, _values.getItemCount() - 1);
		}
		foreach (f; _summ.flagDirRoot.allFlags) { mixin(S_TRACE);
			auto itm = new TableItem(_values, SWT.NONE);
			auto path = f.path;
			itm.setImage(0, _prop.images.flag);
			itm.setText(0, path);
			itm.setText(1, f.onOff ? f.on : f.off);
			auto d = new FlagData;
			itm.setData(d);
			d.flag = f;
			d.onOff = f.onOff;
			string lpath = .toLower(path);
			auto p = lpath in pvs;
			if (p) { mixin(S_TRACE);
				if (*p == 1) { mixin(S_TRACE);
					itm.setText(1, f.on);
					d.onOff = true;
				} else if (*p == 0) { mixin(S_TRACE);
					itm.setText(1, f.off);
					d.onOff = false;
				}
			}
			if (selPath && selPath == lpath) { mixin(S_TRACE);
				_values.select(_values.getItemCount() - 1);
			}
		}
		foreach (f; _summ.flagDirRoot.allSteps) { mixin(S_TRACE);
			auto itm = new TableItem(_values, SWT.NONE);
			auto path = f.path;
			itm.setImage(0, _prop.images.step);
			itm.setText(0, path);
			itm.setText(1, f.values[f.select]);
			auto d = new StepData;
			itm.setData(d);
			d.step = f;
			d.select = f.select;
			string lpath = .toLower(path);
			auto p = lpath in pvs;
			if (p) { mixin(S_TRACE);
				if (0 <= *p && *p < f.values.length) { mixin(S_TRACE);
					itm.setText(1, f.values[*p]);
					d.select = *p;
				}
			}
			if (selPath && selPath == lpath) { mixin(S_TRACE);
				_values.select(_values.getItemCount() - 1);
			}
		}
	}
	private void refFlagAndStep(Flag[] flags, Step[] steps) { mixin(S_TRACE);
		_undo.reset();
		refreshFlags();
		raiseModEvent();
	}
	private Control createEditor(TableItem itm, int editC) { mixin(S_TRACE);
		_changedText = false;
		auto fd = cast(FlagData) itm.getData();
		if (fd) { mixin(S_TRACE);
			auto text = createComboEditor!Combo(_comm, _prop, itm.getParent(), [fd.flag.on, fd.flag.off], itm.getText(1));
			text.addModifyListener(new Mod(itm));
			return text;
		}
		auto sd = cast(StepData) itm.getData();
		if (sd) { mixin(S_TRACE);
			auto text = createComboEditor!Combo(_comm, _prop, itm.getParent(), sd.step.values, itm.getText(1));
			text.addModifyListener(new Mod(itm));
			return text;
		}
		auto combo = createTextEditor(_comm, _prop, itm.getParent(), itm.getText(1));
		combo.addModifyListener(new Mod(itm));
		return combo;
	}
	private static string ctrlText(Control ctrl) { mixin(S_TRACE);
		auto text = cast(Text) ctrl;
		if (text) return text.getText();
		auto combo = cast(Combo) ctrl;
		if (combo) return combo.getText();
		assert (0);
	}
	private void editEnd(TableItem itm, int column, Control ctrl) { mixin(S_TRACE);
		auto old = itm.getText(column);
		auto text = cast(Text) ctrl;
		if (text) itm.setText(column, text.getText());
		auto combo = cast(Combo) ctrl;
		if (combo) { mixin(S_TRACE);
			itm.setText(column, combo.getText());
			auto fd = cast(FlagData) itm.getData();
			if (fd) fd.onOff = combo.getSelectionIndex() == 0;
			auto sd = cast(StepData) itm.getData();
			if (sd) sd.select = combo.getSelectionIndex();
		}
		if (old != itm.getText()) raiseModEvent();
	}

	private void raiseModEvent() { mixin(S_TRACE);
		foreach (dlg; modEvent) dlg();
		_comm.refreshToolBar();
	}

	void resetValues() { mixin(S_TRACE);
		return resetValues(_values.getSelectionIndices());
	}
	void resetValuesAll() { mixin(S_TRACE);
		return resetValues(std.range.iota(0, _values.getItemCount()).array());
	}
	void resetValues(in int[] indices) { mixin(S_TRACE);
		bool[int] set;
		foreach (i; indices) set[i] = true;
		store();
		size_t i = 0;
		foreach (c; _targetChars) { mixin(S_TRACE);
			if (i in set) { mixin(S_TRACE);
				auto itm = _values.getItem(_indexTable[cast(SPChar)c]);
				final switch (cast(SPChar)c) {
				case SPChar.M:
					itm.setText(1, _prop.var.etc.messageVarSelected.INIT);
					break;
				case SPChar.U:
					itm.setText(1, _prop.var.etc.messageVarUnselected.INIT);
					break;
				case SPChar.R:
					itm.setText(1, _prop.var.etc.messageVarRandom.INIT);
					break;
				case SPChar.C:
					itm.setText(1, _prop.var.etc.messageVarCard.INIT);
					break;
				case SPChar.I:
					itm.setText(1, _prop.var.etc.messageVarRef.INIT);
					break;
				case SPChar.T:
					itm.setText(1, _prop.var.etc.messageVarTeam.INIT);
					break;
				case SPChar.Y:
					itm.setText(1, _prop.var.etc.messageVarYado.INIT);
					break;
				}
			}
			i++;
		}
		foreach (f; _summ.flagDirRoot.allFlags) { mixin(S_TRACE);
			if (i in set) { mixin(S_TRACE);
				auto itm = _values.getItem(i);
				itm.setText(1, f.onOff ? f.on : f.off);
				auto data = cast(FlagData) itm.getData();
				data.onOff = f.onOff;
			}
			i++;
		}
		foreach (f; _summ.flagDirRoot.allSteps) { mixin(S_TRACE);
			if (i in set) { mixin(S_TRACE);
				auto itm = _values.getItem(i);
				itm.setText(1, f.values[f.select]);
				auto data = cast(StepData) itm.getData();
				data.select = f.select;
			}
			i++;
		}
		raiseModEvent();
	}
	bool isInitialValues() { mixin(S_TRACE);
		return isInitialValues(_values.getSelectionIndices());
	}
	bool isInitialValuesAll() { mixin(S_TRACE);
		return isInitialValues(std.range.iota(0, _values.getItemCount()).array());
	}
	bool isInitialValues(in int[] indices) { mixin(S_TRACE);
		bool[int] set;
		foreach (i; indices) set[i] = true;
		size_t i = 0;
		foreach (c; _targetChars) { mixin(S_TRACE);
			if (i in set) { mixin(S_TRACE);
				auto itm = _values.getItem(_indexTable[cast(SPChar)c]);
				final switch (cast(SPChar)c) {
				case SPChar.M:
					if (itm.getText(1) != _prop.var.etc.messageVarSelected.INIT) return false;
					break;
				case SPChar.U:
					if (itm.getText(1) != _prop.var.etc.messageVarUnselected.INIT) return false;
					break;
				case SPChar.R:
					if (itm.getText(1) != _prop.var.etc.messageVarRandom.INIT) return false;
					break;
				case SPChar.C:
					if (itm.getText(1) != _prop.var.etc.messageVarCard.INIT) return false;
					break;
				case SPChar.I:
					if (itm.getText(1) != _prop.var.etc.messageVarRef.INIT) return false;
					break;
				case SPChar.T:
					if (itm.getText(1) != _prop.var.etc.messageVarTeam.INIT) return false;
					break;
				case SPChar.Y:
					if (itm.getText(1) != _prop.var.etc.messageVarYado.INIT) return false;
					break;
				}
			}
			i++;
		}
		foreach (f; _summ.flagDirRoot.allFlags) { mixin(S_TRACE);
			if (i in set) { mixin(S_TRACE);
				auto itm = _values.getItem(i);
				auto data = cast(FlagData) itm.getData();
				if (data.onOff != f.onOff) return false;
			}
			i++;
		}
		foreach (f; _summ.flagDirRoot.allSteps) { mixin(S_TRACE);
			if (i in set) { mixin(S_TRACE);
				auto itm = _values.getItem(i);
				auto data = cast(StepData) itm.getData();
				if (data.select != f.select) return false;
			}
			i++;
		}
		return true;
	}

	class ValuesTCPD : TCPD {
		void cut(SelectionEvent e) { assert (0); };
		void copy(SelectionEvent e) { mixin(S_TRACE);
			auto indices = _values.getSelectionIndices().sort;
			if (!indices.length) return;
			string text;
			foreach (sel; indices[0] .. indices[$ - 1] + 1) { mixin(S_TRACE);
				auto itm = _values.getItem(sel);
				auto fd = cast(FlagData) itm.getData();
				auto sd = cast(StepData) itm.getData();
				if (fd) { mixin(S_TRACE);
					text ~= to!string(fd.onOff);
				} else if (sd) { mixin(S_TRACE);
					text ~= to!string(sd.select);
				} else { mixin(S_TRACE);
					text ~= itm.getText(1);
				}
				text ~= std.ascii.newline;
			}
			_comm.clipboard.setContents([new ArrayWrapperString(text)], [TextTransfer.getInstance()]);
			_comm.refreshToolBar();
		}
		void paste(SelectionEvent e) { mixin(S_TRACE);
			auto a = cast(ArrayWrapperString) _comm.clipboard.getContents(TextTransfer.getInstance());
			if (!a) return;
			auto indices = _values.getSelectionIndices().sort;
			if (!indices.length) return;
			int i = indices[0];
			auto linesu = a.array.splitLines();
			if (!linesu.length) return;
			store();
			auto lines = assumeUnique(linesu);
			int[] sels;
			foreach (line; lines) { mixin(S_TRACE);
				if (_values.getItemCount() <= i) break;
				auto itm = _values.getItem(i);
				auto fd = cast(FlagData) itm.getData();
				auto sd = cast(StepData) itm.getData();
				try { mixin(S_TRACE);
					if (fd) { mixin(S_TRACE);
						fd.onOff = to!bool(line);
						itm.setText(1, fd.onOff ? fd.flag.on : fd.flag.off);
					} else if (sd) { mixin(S_TRACE);
						auto value = to!int(line);
						if (0 <= value && value < sd.step.values.length) { mixin(S_TRACE);
							sd.select = value;
							itm.setText(1, sd.step.values[sd.select]);
						}
					} else { mixin(S_TRACE);
						itm.setText(1, line);
					}
				} catch (ConvException e) {
					debugln(e);
				}
				sels ~= i;
				i++;
			}
			_values.deselectAll();
			_values.select(sels);
			_values.showSelection();
			raiseModEvent();
		}
		void del(SelectionEvent e) { assert (0); };
		void clone(SelectionEvent e) { assert (0); };
		bool canDoTCPD() { mixin(S_TRACE);
			return _values.isFocusControl();
		}
		bool canDoT() { return false; }
		bool canDoC() { return -1 != _values.getSelectionIndex(); }
		bool canDoP() { return -1 != _values.getSelectionIndex() && CBisText(_comm.clipboard); }
		bool canDoD() { return false; }
		bool canDoClone() { return false; }
	}

	this (Composite parent, Commons comm, Props prop, Summary summ, bool message) { mixin(S_TRACE);
		super (parent, SWT.NONE);

		_undo = new UndoManager(prop.var.etc.undoMaxEtc);
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_isMessage = message;
		_targetChars = message ? SPCHAR_ALL : SPCHAR_TEXT;

		this.setLayout(zeroGridLayout(1, true));

		_values = new Table(this, SWT.BORDER | SWT.FULL_SELECTION | SWT.MULTI);
		auto vgd = new GridData(GridData.FILL_BOTH);
		vgd.heightHint = _prop.var.etc.messageVarTableHeight;
		_values.setLayoutData(vgd);
		_values.addDisposeListener(new Dispose);
		_values.setHeaderVisible(true);

		auto menu = new Menu(_values);
		createMenuItem(comm, menu, MenuID.Undo, {_undo.undo();}, &_undo.canUndo);
		createMenuItem(comm, menu, MenuID.Redo, {_undo.redo();}, &_undo.canRedo);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(comm, menu, MenuID.ResetPreviewValues, &resetValues, () => !isInitialValues());
		createMenuItem(comm, menu, MenuID.ResetPreviewValuesAll, &resetValuesAll, () => !isInitialValuesAll());
		new MenuItem(menu, SWT.SEPARATOR);
		appendMenuTCPD(comm, menu, new ValuesTCPD, false, true, true, false, false);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(comm, menu, MenuID.SelectAll, &_values.selectAll, () => _values.getSelectionCount() < _values.getItemCount());
		_values.setMenu(menu);

		auto kindCol = new TableColumn(_values, SWT.NONE);
		kindCol.setText(_prop.msgs.messageVarKindColumn);
		auto valueCol = new TableColumn(_values, SWT.NONE);
		valueCol.setText(_prop.msgs.messageVarValueColumn);
		if (_isMessage) { mixin(S_TRACE);
			kindCol.setWidth(_prop.var.etc.messageVarKindColumn);
			valueCol.setWidth(_prop.var.etc.messageVarValueColumn);
		} else { mixin(S_TRACE);
			kindCol.setWidth(_prop.var.etc.textVarKindColumn);
			valueCol.setWidth(_prop.var.etc.textVarValueColumn);
		}

		foreach (i; _targetChars) { mixin(S_TRACE);
			_indexTable[cast(SPChar)i] = _values.getItemCount();
			auto itm = new TableItem(_values, SWT.NONE);
			final switch (cast(SPChar)i) {
			case SPChar.M:
				itm.setImage(0, _prop.images.scTalker(Talker.SELECTED));
				itm.setText(0, _prop.msgs.scTalkerName(Talker.SELECTED));
				itm.setText(1, _prop.var.etc.messageVarSelected);
				break;
			case SPChar.U:
				itm.setImage(0, _prop.images.scTalker(Talker.UNSELECTED));
				itm.setText(0, _prop.msgs.scTalkerName(Talker.UNSELECTED));
				itm.setText(1, _prop.var.etc.messageVarUnselected);
				break;
			case SPChar.R:
				itm.setImage(0, _prop.images.scTalker(Talker.RANDOM));
				itm.setText(0, _prop.msgs.scTalkerName(Talker.RANDOM));
				itm.setText(1, _prop.var.etc.messageVarRandom);
				break;
			case SPChar.C:
				itm.setImage(0, _prop.images.scTalker(Talker.CARD));
				itm.setText(0, _prop.msgs.scTalkerName(Talker.CARD));
				itm.setText(1, _prop.var.etc.messageVarCard);
				break;
			case SPChar.I:
				itm.setImage(0, _prop.images.scRef);
				itm.setText(0, _prop.msgs.scRef);
				itm.setText(1, _prop.var.etc.messageVarRef);
				break;
			case SPChar.T:
				itm.setImage(0, _prop.images.scTeam);
				itm.setText(0, _prop.msgs.scTeam);
				itm.setText(1, _prop.var.etc.messageVarTeam);
				break;
			case SPChar.Y:
				itm.setImage(0, _prop.images.scYado);
				itm.setText(0, _prop.msgs.scYado);
				itm.setText(1, _prop.var.etc.messageVarYado);
				break;
			}
		}
		refreshFlags();
		_comm.refUndoMax.add(&refUndoMax);
		_comm.refFlagAndStep.add(&refFlagAndStep);
		_comm.delFlagAndStep.add(&refFlagAndStep);

		new TableTCEdit(_comm, _values, 1, &createEditor, &editEnd, null);
	}

	void getValues(out string[char] names, out string[string] flags, out string[string] steps) { mixin(S_TRACE);
		foreach (i; _targetChars) { mixin(S_TRACE);
			names[C_TBL[cast(SPChar)i]] = _values.getItem(_indexTable[cast(SPChar)i]).getText(1);
		}
		foreach (i; _targetChars.length .. _values.getItemCount()) { mixin(S_TRACE);
			auto itm = _values.getItem(i);
			if (cast(FlagData) itm.getData()) { mixin(S_TRACE);
				flags[itm.getText(0)] = itm.getText(1);
			} else { mixin(S_TRACE);
				assert (cast(StepData) itm.getData());
				steps[itm.getText(0)] = itm.getText(1);
			}
		}
	}
	private void getValues2(out string[char] names, out bool[string] flags, out int[string] steps) { mixin(S_TRACE);
		foreach (i; _targetChars) { mixin(S_TRACE);
			names[C_TBL[cast(SPChar)i]] = _values.getItem(_indexTable[cast(SPChar)i]).getText(1);
		}
		foreach (i; _targetChars.length .. _values.getItemCount()) { mixin(S_TRACE);
			auto itm = _values.getItem(i);
			auto fd = cast(FlagData) itm.getData();
			if (fd) { mixin(S_TRACE);
				flags[itm.getText(0)] = fd.onOff;
			} else { mixin(S_TRACE);
				auto sd = cast(StepData) itm.getData();
				assert (sd !is null);
				steps[itm.getText(0)] = sd.select;
			}
		}
	}
	private void setValues2(in string[char] names, in bool[string] flags, in int[string] steps) { mixin(S_TRACE);
		foreach (i; _targetChars) { mixin(S_TRACE);
			_values.getItem(_indexTable[cast(SPChar)i]).setText(1, names[C_TBL[cast(SPChar)i]]);
		}
		foreach (i; _targetChars.length .. _values.getItemCount()) { mixin(S_TRACE);
			auto itm = _values.getItem(i);
			auto fd = cast(FlagData) itm.getData();
			if (fd) { mixin(S_TRACE);
				auto p = itm.getText(0) in flags;
				if (p) { mixin(S_TRACE);
					fd.onOff = *p;
					itm.setText(1, fd.onOff ? fd.flag.on : fd.flag.off);
				}
			} else { mixin(S_TRACE);
				auto sd = cast(StepData) itm.getData();
				assert (sd !is null);
				auto p = itm.getText(0) in steps;
				if (p && 0 <= *p && *p < sd.step.values.length) { mixin(S_TRACE);
					sd.select = *p;
					itm.setText(1, sd.step.values[sd.select]);
				}
			}
		}
	}

	@property
	bool focusInValues() { mixin(S_TRACE);
		return _values.isFocusControl();
	}
	bool undo() { return _undo.undo(); }
	bool redo() { return _undo.redo(); }
}

void getPreviewValues(in Props prop, in Summary summ, in SPChar[] targetChars,
		out string[char] names, out string[string] flags, out string[string] steps) { mixin(S_TRACE);
	foreach (c; targetChars) { mixin(S_TRACE);
		final switch (c) {
		case SPChar.M:
			names[C_TBL[c]] = prop.var.etc.messageVarSelected;
			break;
		case SPChar.U:
			names[C_TBL[c]] = prop.var.etc.messageVarUnselected;
			break;
		case SPChar.R:
			names[C_TBL[c]] = prop.var.etc.messageVarRandom;
			break;
		case SPChar.C:
			names[C_TBL[c]] = prop.var.etc.messageVarCard;
			break;
		case SPChar.I:
			names[C_TBL[c]] = prop.var.etc.messageVarRef;
			break;
		case SPChar.T:
			names[C_TBL[c]] = prop.var.etc.messageVarTeam;
			break;
		case SPChar.Y:
			names[C_TBL[c]] = prop.var.etc.messageVarYado;
			break;
		}
	}
	if (summ) { mixin(S_TRACE);
		foreach (f; summ.flagDirRoot.allFlags) { mixin(S_TRACE);
			flags[f.path] = f.onOff ? f.on : f.off;
		}
		foreach (f; summ.flagDirRoot.allSteps) { mixin(S_TRACE);
			steps[f.path] = f.value;
		}
	}
}

class MsgPreview : Composite {

	private Commons _comm;
	private Props _prop;
	private Summary _summ;

	private Canvas _canvas;
	private Image _img = null;
	private PreviewValues _values;

	private Talker _talker = Talker.NARRATION;
	private string _imgPath = "";
	private string _message = "";

	private class Paint : PaintListener {
		override void paintControl(PaintEvent e) { mixin(S_TRACE);
			auto b = _canvas.getBounds();
			auto rect = _prop.looks.messageBounds;
			e.gc.drawImage(_img, (b.width - rect.width) / 2, (b.height - rect.height) / 2);
		}
	}
	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			if (_img) _img.dispose();
			_comm.refSkin.remove(&refresh);
		}
	}

	this (Composite parent, Commons comm, Props prop, Summary summ) { mixin(S_TRACE);
		super (parent, SWT.NONE);

		_comm = comm;
		_prop = prop;
		_summ = summ;

		this.setLayout(zeroGridLayout(1, true));

		_canvas = new Canvas(this, SWT.DOUBLE_BUFFERED);
		auto cgd = new GridData(GridData.FILL_HORIZONTAL);
		auto rect = _prop.looks.messageBounds;
		cgd.widthHint = rect.width;
		cgd.heightHint = rect.height;
		_canvas.setLayoutData(cgd);
		_canvas.addPaintListener(new Paint);
		_canvas.addDisposeListener(new Dispose);

		_values = new PreviewValues(this, comm, prop, summ, true);
		auto vgd = new GridData(GridData.FILL_BOTH);
		vgd.heightHint = _prop.var.etc.messageVarTableHeight;
		_values.setLayoutData(vgd);
		_values.modEvent ~= &refresh;
		_comm.refSkin.add(&refresh);
	}

	void text(Talker talker, string imgPath, string message) { mixin(S_TRACE);
		if (_img && talker is _talker && imgPath == _imgPath && message == _message) { mixin(S_TRACE);
			return;
		}
		_talker = talker;
		_imgPath = imgPath;
		_message = message;
		if (isVisible()) refresh();
	}

	private void refresh() { mixin(S_TRACE);
		auto d = _canvas.getDisplay();
		if (_img) { mixin(S_TRACE);
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
		case Talker.VALUED:
			tImg = _prop.images.talker(_talker).getImageData();
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
		string[string] flags, steps;
		_values.getValues(names, flags, steps);
		_img = new Image(d, previewMessage(_comm, _prop, _summ.scenarioPath, tImg, _message, [], names, flags, steps));
		_canvas.redraw();
	}

	@property
	bool focusInValues() { mixin(S_TRACE);
		return _values.focusInValues;
	}
	bool undo() { return _values.undo(); }
	bool redo() { return _values.redo(); }
}

/// メッセージのプレビューを生成する。
ImageData previewMessage(Commons comm, Props prop, string sPath, ImageData talker, string message, in string[] sel, in string[char] names, in string[string] flags, in string[string] steps) { mixin(S_TRACE);
	auto d = Display.getCurrent();
	version (Windows) {
		bool legacy = comm.skin.legacy;
	} else { mixin(S_TRACE);
		bool legacy = false;
	}
	auto rect = prop.looks.messageBounds;
	auto bh = prop.looks.messageButtonHeight;
	auto canvas = new Image(d, rect.width, rect.height + bh * sel.length);
	scope (exit) canvas.dispose();
	auto gc = new GC(canvas);
	scope (exit) gc.dispose();
	int alpha;

	// 背景の描画
	auto back = new Color(d, dwtData(prop.var.etc.messageBackColor, alpha));
	scope (exit) back.dispose();
	gc.setBackground(back);
	gc.fillRectangle(3, 3, rect.width - 6, rect.height - 6);
	foreach (i; 0 .. sel.length) { mixin(S_TRACE);
		gc.fillRectangle(3, rect.height + 3 + bh * i, rect.width - 6, bh - 6);
	}

	// 話者の描画
	if (talker) { mixin(S_TRACE);
		auto tImg = new Image(d, talker);
		scope (exit) tImg.dispose();
		auto tp = prop.looks.messageTalkerPos;
		auto cs = prop.looks.cardSize;
		int tpy = tp.y + (cast(int) cs.height - cast(int) talker.height) / 2;
		gc.drawImage(tImg, tp.x, tpy);
	}

	// 文章と特殊文字の描画

	// 改行置換
	if (.contains(message, '\r')) { mixin(S_TRACE);
		message = message.splitLines().join("\n");
	}
	// 特殊文字・フラグ・ステップ・色
	string[size_t] rFonts;
	char[size_t] rColors;
	string fValue(string path) { mixin(S_TRACE);
		foreach (f, v; flags) { mixin(S_TRACE);
			if (0 == icmp(f, path)) { mixin(S_TRACE);
				return v;
			}
		}
		return "%" ~ path ~ "%";
	}
	string sValue(string path) { mixin(S_TRACE);
		foreach (f, v; steps) { mixin(S_TRACE);
			if (0 == icmp(f, path)) { mixin(S_TRACE);
				return v;
			}
		}
		return "$" ~ path ~ "$";
	}
	version (Windows) {
		message = wrapReturnCode(message);
		message = message.replace("\n", "\r\n");
	}
	message = formatMsg(message, &fValue, &sValue, delegate string (char name) { mixin(S_TRACE);
		auto dc = std.ascii.toUpper(name);
		foreach (c, v; names) { mixin(S_TRACE);
			if (std.ascii.toUpper(c) == dc) { mixin(S_TRACE);
				return v;
			}
		}
		return "";
	}, (string path) { mixin(S_TRACE);
		return comm.skin.findImagePath(path, comm.summary.scenarioPath).length != 0 || decodeFontPath(path) in comm.skin.spChars;
	}, rFonts, rColors);
	auto dmsg = to!dstring(message);

	auto cr = d.getSystemColor(SWT.COLOR_RED);
	auto cb = d.getSystemColor(SWT.COLOR_CYAN);
	auto cg = d.getSystemColor(SWT.COLOR_GREEN);
	auto cy = d.getSystemColor(SWT.COLOR_YELLOW);
	auto co = new Color(d, new RGB(255, 165, 0)); scope (exit) co.dispose(); // CardWirth 1.50
	auto cp = new Color(d, new RGB(204, 136, 255)); scope (exit) cp.dispose(); // CardWirth 1.50
	auto cl = new Color(d, new RGB(169, 169, 169)); scope (exit) cl.dispose(); // CardWirth 1.50
	auto cd = new Color(d, new RGB(105, 105, 105)); scope (exit) cd.dispose(); // CardWirth 1.50

	auto font = new Font(d, dwtData(prop.looks.messageFont(legacy)));
	scope (exit) font.dispose();
	auto fc = new Color(d, dwtData(prop.var.etc.messageForeColor, alpha));
	scope (exit) fc.dispose();
	auto hc = new Color(d, dwtData(prop.var.etc.messageHemColor, alpha));
	scope (exit) hc.dispose();
	auto selFont = new Font(d, dwtData(prop.looks.messageSelectFont(legacy)));
	scope (exit) selFont.dispose();

	auto start = prop.looks.messageStartPos(legacy, talker !is null);
	int x = start.x, y = start.y;
	int lineH;
	string old = "";
	int msgLen =  talker ? prop.looks.messageImageLen : prop.looks.messageLen;
	int writeLen = 0;
	void ret() { mixin(S_TRACE);
		writeLen = 0;
		x = start.x;
		y += lineH;
		old = "";
	}

	// フォントイメージ
	auto wrgb = fc.getRGB();
	void drawSPFont(GC gc, CPoint pt, string path, RGB c) { mixin(S_TRACE);
		string fpath = comm.skin.findImagePath(path, sPath);
		ImageData data = null;
		if (fpath && fpath.length) { mixin(S_TRACE);
			// シナリオ内特殊文字
			data = loadImage(fpath, true);
		}
		if (!data) { mixin(S_TRACE);
			// 標準特殊文字
			data = spChar(comm.skin, decodeFontPath(path));
			if (data) { mixin(S_TRACE);
				auto spc = data;
				data = new ImageData(spc.width, spc.height, 24, new PaletteData(0xFF << 16, 0xFF << 8, 0xFF << 0));
				// &R等による色の置換
				foreach (dx; 0 .. data.width) { mixin(S_TRACE);
					foreach (dy; 0 .. data.height) { mixin(S_TRACE);
						auto p = spc.palette.getRGB(spc.getPixel(dx, dy));
						if (wrgb.opEquals(p)) { mixin(S_TRACE);
							data.setPixel(dx, dy, (c.red << 16) | (c.green << 8) | (c.blue << 0));
						} else { mixin(S_TRACE);
							data.setPixel(dx, dy, (p.red << 16) | (p.green << 8) | (p.blue << 0));
						}
					}
				}
				data.transparentPixel = data.getPixel(0, 0);
			}
		}
		if (data) { mixin(S_TRACE);
			auto img = new Image(d, data);
			scope (exit) img.dispose();
			gc.drawImage(img, pt.x, pt.y);
		}
	}

	if (legacy) { mixin(S_TRACE);
		auto textCanvas = new Image(d, rect.width, rect.height + bh * sel.length);
		scope (exit) textCanvas.dispose();
		auto tgc = new GC(textCanvas);
		scope (exit) tgc.dispose();
		// FIXME: IPAフォントの使用とアンチエイリアス設定を
		//        同時に行うと一部環境で問題が出る。
//		tgc.setTextAntialias(SWT.OFF);
		tgc.setFont(font);
		tgc.setForeground(fc);
		tgc.setBackground(hc);
		tgc.fillRectangle(0, 0, rect.width, rect.height + bh * sel.length);
		lineH = tgc.getFontMetrics().getHeight() + 2;
		for (size_t i = 0; i < dmsg.length; i++) { mixin(S_TRACE);
			if (rect.height - 6 < y + lineH) { mixin(S_TRACE);
				// 行数オーバー
				break;
			}
			auto cf = i in rFonts;
			if (cf) { mixin(S_TRACE);
				// 特殊文字の描画位置を記憶
				string s1 = to!string(dmsg[i]);
				i++;
				string s2 = to!string(dmsg[i]);
				auto w = (tgc.textExtent(s1).x - 1) + (tgc.textExtent(s2).x - 1);
				if (msgLen < writeLen + 2) { mixin(S_TRACE);
					// 列数オーバー
					if (!(i + 1 < dmsg.length && dmsg[i + 1] == '\n')) { mixin(S_TRACE);
						ret();
					}
					if (rect.height - 6 < y + lineH) { mixin(S_TRACE);
						// 行数オーバー
						break;
					}
				}
				writeLen += 2;
				drawSPFont(gc, CPoint(x - 2, y - 2), *cf, tgc.getForeground().getRGB());
				x += w;
				continue;
			}
			auto colorP = i in rColors;
			if (colorP) { mixin(S_TRACE);
				// フォント色変更
				switch (*colorP) {
				case 'W': tgc.setForeground(fc); break;
				case 'R': tgc.setForeground(cr); break;
				case 'B': tgc.setForeground(cb); break;
				case 'G': tgc.setForeground(cg); break;
				case 'Y': tgc.setForeground(cy); break;
				case 'O': tgc.setForeground(co); break;
				case 'P': tgc.setForeground(cp); break;
				case 'L': tgc.setForeground(cl); break;
				case 'D': tgc.setForeground(cd); break;
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
				auto te = tgc.textExtent(s);
				int w = te.x - 1;
				int len = (te.x + 1) / tgc.textExtent("#").x;
				// 行末が半角スペースの時だけ特別扱いする(CardWirthの挙動に合わせた処理)
				if (msgLen < writeLen + (s == " " ? len - 1 : len)) { mixin(S_TRACE);
					// 列数オーバー
					if (!(i + 1 < dmsg.length && dmsg[i + 1] == '\n')) { mixin(S_TRACE);
						ret();
					}
					if (rect.height - 6 < y + lineH) { mixin(S_TRACE);
						// 行数オーバー
						break;
					}
				}
				writeLen += len;
				tgc.drawText(s, x, y, true);
				x += w;
				break;
			}
		}

		// 選択肢
		tgc.setForeground(fc);
		tgc.setFont(selFont);
		auto slh = tgc.getFontMetrics().getHeight();
		int sx;
		int sy = rect.height + ((bh - slh) / 2);
		foreach (i, t; sel) { mixin(S_TRACE);
			sx = (rect.width - tgc.textExtent(t).x) / 2;
			tgc.drawText(t, sx, sy, true);
			sy += bh;
		}

		// 貼り付け
		auto tImgData = textCanvas.getImageData();
		tImgData.transparentPixel = tImgData.getPixel(0, 0);
		auto hemImgData = new ImageData(tImgData.width, tImgData.height, 2, new PaletteData([new RGB(255, 255, 255), new RGB(0, 0, 0)]));
		hemImgData.transparentPixel = 0;
		foreach (ix; 0 .. tImgData.width) { mixin(S_TRACE);
			foreach (iy; 0 .. tImgData.height) { mixin(S_TRACE);
				if (tImgData.getPixel(ix, iy) != tImgData.transparentPixel) { mixin(S_TRACE);
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
	} else { mixin(S_TRACE);
		// FIXME: IPAフォントの使用とアンチエイリアス設定を
		//        同時に行うと一部環境で問題が出る。
//		gc.setTextAntialias(SWT.ON);
		gc.setFont(font);
		lineH = gc.getFontMetrics().getHeight();
		gc.setForeground(fc);

		void drawText(string s, int x, int y) { mixin(S_TRACE);
			if ("―" == s && "―" == old) { mixin(S_TRACE);
				// "―"の場合のみ表示を接続する処理が入る
				gc.setForeground(hc);
				gc.drawText(s, x, y - 1, true);
				gc.drawText(s, x, y + 1, true);
				gc.drawText(s, x - lineH / 2 + 2, y - 1, true);
				gc.drawText(s, x - lineH / 2 + 2, y + 1, true);
				gc.setForeground(fc);
				gc.drawText(s, x - lineH / 2, y, true);
				gc.drawText(s, x, y, true);
			} else { mixin(S_TRACE);
				gc.setForeground(hc);
				gc.drawText(s, x - 1, y, true);
				gc.drawText(s, x + 1, y, true);
				gc.drawText(s, x, y - 1, true);
				gc.drawText(s, x, y + 1, true);
				gc.setForeground(fc);
				gc.drawText(s, x, y, true);
			}
			old = s;
		}
		for (size_t i = 0; i < dmsg.length; i++) { mixin(S_TRACE);
			if (rect.height - 6 < y + lineH) { mixin(S_TRACE);
				// 行数オーバー
				break;
			}
			auto cf = i in rFonts;
			if (cf) { mixin(S_TRACE);
				// 特殊文字の描画位置を記憶
				string s1 = to!string(dmsg[i]);
				i++;
				string s2 = to!string(dmsg[i]);
				auto w = (gc.textExtent(s1).x - 1) + (gc.textExtent(s2).x - 1);
				if (msgLen < writeLen + 2) { mixin(S_TRACE);
					// 列数オーバー
					if (!(i + 1 < dmsg.length && dmsg[i + 1] == '\n')) { mixin(S_TRACE);
						ret();
					}
					if (rect.height - 6 < y + lineH) { mixin(S_TRACE);
						// 行数オーバー
						break;
					}
				}
				writeLen += 2;
				drawSPFont(gc, CPoint(x, y - 2), *cf, gc.getForeground().getRGB());
				x += w;
				continue;
			}
			auto colorP = i in rColors;
			if (colorP) { mixin(S_TRACE);
				// フォント色変更
				switch (*colorP) {
				case 'W': gc.setForeground(fc); break;
				case 'R': gc.setForeground(cr); break;
				case 'B': gc.setForeground(cb); break;
				case 'G': gc.setForeground(cg); break;
				case 'Y': gc.setForeground(cy); break;
				case 'O': gc.setForeground(co); break; // CardWirth 1.50
				case 'P': gc.setForeground(cp); break; // CardWirth 1.50
				case 'L': gc.setForeground(cl); break; // CardWirth 1.50
				case 'D': gc.setForeground(cd); break; // CardWirth 1.50
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
				auto te = gc.textExtent(s);
				int w = te.x - 1;
				int len = (te.x + 1) / gc.textExtent("#").x;
				// 行末が半角スペースの時だけ特別扱いする(CardWirthの挙動に合わせた処理)
				if (msgLen < writeLen + (s == " " ? len - 1 : len)) { mixin(S_TRACE);
					// 列数オーバー
					if (!(i + 1 < dmsg.length && dmsg[i + 1] == '\n')) { mixin(S_TRACE);
						ret();
					}
					if (rect.height - 6 < y + lineH) { mixin(S_TRACE);
						// 行数オーバー
						break;
					}
				}
				writeLen += len;
				drawText(s, x, y);
				x += w;
				break;
			}
		}

		// 選択肢
		gc.setForeground(fc);
		gc.setFont(selFont);
		auto slh = gc.getFontMetrics().getHeight();
		int sx;
		int sy = rect.height + ((bh - slh) / 2);
		foreach (i, t; sel) { mixin(S_TRACE);
			sx = (rect.width - gc.textExtent(t).x) / 2;
			drawText(t, sx, sy);
			sy += bh;
		}
	}

	// 枠
	auto c1 = new Color(d, dwtData(prop.var.etc.messageLineColor1, alpha));
	scope (exit) c1.dispose();
	auto c2 = new Color(d, dwtData(prop.var.etc.messageLineColor2, alpha));
	scope (exit) c2.dispose();
	gc.setForeground(c1);
	gc.drawRectangle(0, 0, rect.width - 1, rect.height - 1);
	gc.drawRectangle(2, 2, rect.width - 5, rect.height - 5);
	foreach (i; 0 .. sel.length) { mixin(S_TRACE);
		gc.drawRectangle(0, rect.height + bh * i, rect.width - 1, bh - 1);
		gc.drawRectangle(2, rect.height + 2 + bh * i, rect.width - 5, bh - 5);
	}
	gc.setForeground(c2);
	gc.drawRectangle(1, 1, rect.width - 3, rect.height - 3);
	foreach (i; 0 .. sel.length) { mixin(S_TRACE);
		gc.drawRectangle(1, rect.height + 1 + bh * i, rect.width - 3, bh - 3);
	}

	return canvas.getImageData();
}
