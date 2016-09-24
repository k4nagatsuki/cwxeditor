
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
import cwx.warning;
import cwx.sjis;
import cwx.card;

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
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.imagelistwindow;

import std.algorithm : max, sort, uniq;
import std.array;
import std.utf;
import std.string;
import std.datetime;
import std.conv;
import std.exception;
import std.ascii;
import std.path;
import std.typecons;
import std.range;

import org.eclipse.swt.all;
import java.lang.all;

/// 台詞コンテント・メッセージコンテントのダイアログの親クラス。
class AbstractMessageDialog : EventDialog {
	private Spinner _selectionColumns;

	private KeyDownFilter _kdFilter;
	private MsgPreviewWindow _previewWin = null;
	private MsgPreview _preview = null;
	private Button _prev = null;
	private UndoManager _undo;

	private Skin _summSkin;
	@property
	private Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : comm.skin;
	}

	private TextWarnings textWarnings(in string[] flags, in string[] steps, in string[] fonts, in char[] colors,
			ref bool[string] wFlags, ref bool[string] wSteps, ref bool[string] wFonts, ref bool[char] wColors) { mixin(S_TRACE);
		return .textWarnings(prop.parent, summSkin, summ, prop.var.etc.targetVersion,
			flags, steps, fonts, colors, wFlags, wSteps, wFonts, wColors);
	}

	private class SelPrev : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			updateShowPreview();
			if (type is CType.TALK_MESSAGE) { mixin(S_TRACE);
				prop.var.etc.showMessagePreview = _preview ? _preview.isVisible() : _previewWin.isVisible();
			} else if (type is CType.TALK_DIALOG) { mixin(S_TRACE);
				prop.var.etc.showDialogPreview = _preview ? _preview.isVisible() : _previewWin.isVisible();
			} else assert (0);
			if (!_previewWin) { mixin(S_TRACE);
				// プレビューがメインダイアログと一体化しているので
				// メインダイアログのサイズが変わる場合
				saveWin();
			}
		}
	}
	private void updateShowPreview() { mixin(S_TRACE);
		auto btn = _prev;
		if (btn.getSelection()) { mixin(S_TRACE);
			auto s = wrapReturnCode(text);
			if (_previewWin) { mixin(S_TRACE);
				if (_previewWin.isVisible()) return;
				_previewWin.text(imgPaths, s);
				_previewWin.open();
			} else { mixin(S_TRACE);
				if (rightGroup.isVisible()) return;
				_preview.text(imgPaths, s);
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
	private void setPreviewLData(bool visible, bool regWin = true) { mixin(S_TRACE);
		bool oVisible = rightGroup.isVisible();
		assert (_preview);
		rightGroup.setVisible(visible);
		int pvw;
		if (!visible) { mixin(S_TRACE);
			pvw = rightGroup.getSize().x;
		}
		int w = visible ? prop.s(prop.looks.messageBounds.width) : 0;
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

	private void refImageScale() { mixin(S_TRACE);
		if (!_preview) return;
		if (rightGroup.isVisible()) { mixin(S_TRACE);
			getShell().setRedraw(false);
			scope (exit) getShell().setRedraw(true);
			auto ws = getShell().getSize();
			auto pvw = rightGroup.getSize().x;
			ws.x -= pvw;
			ws.x += prop.s(prop.looks.messageBounds.width);
			getShell().setSize(ws);

			int w = prop.s(prop.looks.messageBounds.width);
			int h = 0;
			rightGroupSize(w, h);
		}
	}

	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			comm.refMenu.remove(&refMenu);
			comm.refUndoMax.remove(&refUndoMax);
			comm.refTargetVersion.remove(&refreshWarning);
			comm.refFlagAndStep.remove(&refFlagAndStep);
			comm.delFlagAndStep.remove(&refFlagAndStep);
			comm.refPaths.remove(&refPaths);
			comm.refPath.remove(&refPath);
			comm.delPaths.remove(&refreshWarning);
			comm.refImageScale.remove(&refImageScale);
			getShell().getDisplay().removeFilter(SWT.KeyDown, _kdFilter);
		}
	}

	private class KeyDownFilter : Listener {
		this () { mixin(S_TRACE);
			refMenu(MenuID.Undo);
			refMenu(MenuID.Redo);
		}
		override void handleEvent(Event e) { mixin(S_TRACE);
			if (!e.doit) return;
			auto c = cast(Control)e.widget;
			if (!c || c.isDisposed() || c.getShell() !is getShell()) return;
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
		aComp.setLayout(normalGridLayout(1, true));
		_prev = new Button(aComp, SWT.TOGGLE);
		auto pgd = new GridData;
		pgd.widthHint = prop.var.etc.buttonWidth;
		_prev.setLayoutData(pgd);
		_prev.setText(prop.msgs.messagePreview);
		bool show;
		if (type is CType.TALK_MESSAGE) { mixin(S_TRACE);
			show = prop.var.etc.showMessagePreview;
		} else if (type is CType.TALK_DIALOG) { mixin(S_TRACE);
			show = prop.var.etc.showDialogPreview;
		} else assert (0);
		_prev.setSelection(show);
		_prev.addSelectionListener(new SelPrev);
		initPreview2(area, size);

		void updatePreviewType() { mixin(S_TRACE);
			auto shell = area.getShell();
			shell.setRedraw(false);
			scope (exit) shell.setRedraw(true);
			initPreview2(area, size);
			updateShowPreview();
			if (type is CType.TALK_MESSAGE) { mixin(S_TRACE);
				show = prop.var.etc.showMessagePreview;
			} else if (type is CType.TALK_DIALOG) { mixin(S_TRACE);
				show = prop.var.etc.showDialogPreview;
			} else assert (0);
			if (show) { mixin(S_TRACE);
				auto size = shell.getSize();
				if (prop.var.etc.floatMessagePreview) { mixin(S_TRACE);
					size.x -= .max(1, prop.s(cast(int)prop.looks.messageBounds.width));
				} else { mixin(S_TRACE);
					size.x += prop.s(prop.looks.messageBounds.width);
				}
				shell.setSize(size);
				shell.layout(true);
			}
		}
		comm.refFloatMessagePreview.add(&updatePreviewType);
		.listener(area, SWT.Dispose, { mixin(S_TRACE);
			comm.refFloatMessagePreview.remove(&updatePreviewType);
		});
	}
	protected void initPreview2(Composite area, WSize size) { mixin(S_TRACE);
		if (prop.var.etc.floatMessagePreview) { mixin(S_TRACE);
			if (_preview) { mixin(S_TRACE);
				_preview.dispose();
				_preview = null;
				useRightGroup(false);
			}
		} else { mixin(S_TRACE);
			if (_previewWin) { mixin(S_TRACE);
				_previewWin.dispose();
				_previewWin = null;
				useRightGroup(true);
			}
		}
		if (prop.var.etc.floatMessagePreview) { mixin(S_TRACE);
			_previewWin = new MsgPreviewWindow(getShell(), comm, prop, summ, _prev, size);
		} else { mixin(S_TRACE);
			assert (rightGroup && !rightGroup.isDisposed());
			_preview = new MsgPreview(rightGroup, comm, prop, summ);
			rightGroup.setLayout(zeroGridLayout(1, false));
			_preview.setLayoutData(new GridData(GridData.FILL_BOTH));
			setPreviewLData(_prev.getSelection(), false);
		}
		refreshPreview();
	}

	this (Commons comm, Props prop, Shell shell, Summary summ, CType type, Content parent, Content evt, DSize size) { mixin(S_TRACE);
		super (comm, prop, shell, summ, type, parent, evt, true, size, false, !prop.var.etc.floatMessagePreview);
		_undo = new UndoManager(prop.var.etc.undoMaxEtc);
		_summSkin = findSkin(comm, prop, summ);
	}

	override
	protected void opened() { mixin(S_TRACE);
		if (!_previewWin) return;
		if (type is CType.TALK_MESSAGE) { mixin(S_TRACE);
			if (prop.var.etc.showMessagePreview) _previewWin.open();
		} else if (type is CType.TALK_DIALOG) { mixin(S_TRACE);
			if (prop.var.etc.showDialogPreview) _previewWin.open();
		} else assert (0);
	}

	protected override void setup(Composite area) { mixin(S_TRACE);
		area.addDisposeListener(new Dispose);
		_kdFilter = new KeyDownFilter;
		area.getDisplay().addFilter(SWT.KeyDown, _kdFilter);
		comm.refMenu.add(&refMenu);
		comm.refUndoMax.add(&refUndoMax);
		comm.refTargetVersion.add(&refreshWarning);
		comm.refFlagAndStep.add(&refFlagAndStep);
		comm.delFlagAndStep.add(&refFlagAndStep);
		comm.refPaths.add(&refPaths);
		comm.refPath.add(&refPath);
		comm.delPaths.add(&refreshWarning);
		comm.refImageScale.add(&refImageScale);
	}
	private void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps) { refreshWarning(); }
	private void refPath(string o, string n, bool isDir) { refreshWarning(); }
	private void refPaths(string parent) { refreshWarning(); }

	void refreshPreview() { mixin(S_TRACE);
		if (!_previewWin && !_preview) return;
		auto s = wrapReturnCode(text);
		if (_previewWin) { mixin(S_TRACE);
			_previewWin.text(imgPaths, s);
			_previewWin.refresh();
		} else { mixin(S_TRACE);
			_preview.text(imgPaths, s);
			_preview.refresh();
		}
	}

	@property
	abstract string text();

	@property
	protected abstract CardImage[] imgPaths();

	protected Composite createSelectionColumns(Composite parent) { mixin(S_TRACE);
		auto comp = new Composite(parent, SWT.NONE);
		auto gl = normalGridLayout(3, false);
		gl.marginHeight = 0;
		comp.setLayout(gl);
		auto l = new Label(comp, SWT.NONE);
		l.setText(prop.msgs.selectionColumns);
		_selectionColumns = new Spinner(comp, SWT.BORDER);
		mod(_selectionColumns);
		initSpinner(_selectionColumns);
		_selectionColumns.setMaximum(prop.var.etc.selectionColumnsMax);
		_selectionColumns.setMinimum(1);
		.listener(_selectionColumns, SWT.Selection, &refDataVersion);
		auto hint = new Label(comp, SWT.NONE);
		hint.setText(.tryFormat(prop.msgs.rangeHint, 1, prop.var.etc.selectionColumnsMax));
		return comp;
	}
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

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;

		if (!prop.targetVersion(summ, "1.50")) { mixin(S_TRACE);
			if (Talker.VALUED is selectedTalker) { mixin(S_TRACE);
				ws ~= prop.msgs.warningValuedTalker;
			}
		}

		bool[string] wFlags;
		bool[string] wSteps;
		bool[string] wFonts;
		bool[char] wColors;
		_dlgWarnings = [];
		foreach (i, dlg; _dlgs) { mixin(S_TRACE);
			auto dws = textWarnings(dlg.flagsInText, dlg.stepsInText, dlg.fontsInText, dlg.colorsInText,
				wFlags, wSteps, wFonts, wColors);
			if (dws.all.length) { mixin(S_TRACE);
				_dlgsL.getItem(cast(int)i).setImage(prop.images.warning);
				_dlgWarnings ~= dws.all;
			} else { mixin(S_TRACE);
				_dlgsL.getItem(cast(int)i).setImage(prop.images.content(CType.TALK_DIALOG));
			}
			ws ~= dws.noDup;

			foreach (coupon; dlg.rCoupons) { mixin(S_TRACE);
				ws ~= couponWarnings(prop.parent, summ, prop.var.etc.targetVersion, coupon, false);
			}
		}

		if (selectedTalker is Talker.VALUED) { mixin(S_TRACE);
			foreach (coupon; _couponView.coupons) { mixin(S_TRACE);
				ws ~= couponWarnings(prop.parent, summ, prop.var.etc.targetVersion, coupon.name, false);
			}
		}

		_warningTip.setVisible(false);
		_warningTip.setMessage("");

		if (!prop.isTargetVersion(summ, "1")) { mixin(S_TRACE);
			if (_selectionColumns.getSelection() != 1) { mixin(S_TRACE);
				ws ~= prop.msgs.warningSelectionColumns;
			}
		}

		warning = ws.sort().uniq().array();
	}

	protected override void refDataVersion() { mixin(S_TRACE);
		_selectionColumns.setEnabled(!summ || !summ.legacy || _selectionColumns.getSelection() != 1);
		refreshWarning();
	}

	class MouseMoveDlgsL : MouseTrackAdapter, MouseMoveListener {
		override void mouseMove(MouseEvent e) { mixin(S_TRACE);
			string toolTip = "";
			int ch = 0;
			foreach (i, itm; _dlgsL.getItems()) { mixin(S_TRACE);
				if (itm.getBounds().contains(e.x, e.y)) { mixin(S_TRACE);
					if (i < _dlgWarnings.length) { mixin(S_TRACE);
						toolTip = _dlgWarnings[i].join(.newline);
						ch = itm.getBounds().height;
						break;
					}
				}
			}
			toolTip = std.array.replace(toolTip, "&", "&&");
			if (_warningTip.getMessage() != toolTip) { mixin(S_TRACE);
				_warningTip.setVisible(false);
				_warningTip.setMessage(toolTip);
				if (toolTip != "") { mixin(S_TRACE);
					_warningTip.setLocation(_dlgsL.toDisplay(new Point(e.x, e.y + ch)));
					_warningTip.setVisible(true);
				}
			}
		}
		override void mouseEnter(MouseEvent e) { mixin(S_TRACE);
			mouseMove(e);
		}
		override void mouseExit(MouseEvent e) { mixin(S_TRACE);
			_warningTip.setVisible(false);
			_warningTip.setMessage("");
		}
	}

	string _id;

	Combo _talkers;
	SDialog[] _dlgs;
	Table _dlgsL;
	string[][] _dlgWarnings;
	ToolTip _warningTip;
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
		auto len = cast(int)dlg.text.length;
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
		if (index < 0) index = cast(int)_dlgs.length;
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
			_dlgsL.select(index < _dlgs.length ? index : cast(int)_dlgs.length - 1);
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
			_dlgsL.upItem(index);
			_dlgsL.showSelection();
			_dlgsL.redraw();
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
			_dlgsL.downItem(index);
			_dlgsL.showSelection();
			_dlgsL.redraw();
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
		refreshWarning();
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
		refreshWarning();
		comm.refreshToolBar();
	}
	void copyToDialogs() { mixin(S_TRACE);
		storeEdit();
		int index = _dlgsL.getSelectionIndex();
		string textL = _dlgsL.getItem(index).getText();
		string text = lastRet(wrapReturnCode(_text.getText()));
		foreach (i, dlg; _dlgs) { mixin(S_TRACE);
			if (i != index) { mixin(S_TRACE);
				_dlgsL.getItem(cast(int)i).setText(textL);
				dlg.text = text;
			}
		}
		applyEnabled();
		refreshWarning();
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
		refreshWarning();
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
					printStackTrace();
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
		@property bool canDoTCPD() {return true;}
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
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
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
		_text.font = prop.looks.messageFont(summSkin.legacy);
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

	private class KeyDownFilter : Listener {
		this () { mixin(S_TRACE);
			refMenu(MenuID.OverDialog);
			refMenu(MenuID.UnderDialog);
		}
		override void handleEvent(Event e) { mixin(S_TRACE);
			if (!e.doit) return;
			auto c = cast(Control)e.widget;
			if (!c || c.isDisposed() || c.getShell() !is getShell()) return;
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
		auto o = this;
		_id = format("%08X", &o) ~ "-" ~ to!(string)(Clock.currTime());
		super(comm, prop, shell, summ, CType.TALK_DIALOG, parent, evt, prop.var.speakDlg);
	}

	override
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		auto cate = cpcategory(path);
		if ("dialog" == cate) { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= _dlgsL.getItemCount()) return false;
			_dlgsL.select(cast(int)index);
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
	Talker selectedTalker() { mixin(S_TRACE);
		switch (_talkers.getSelectionIndex()) {
		case 0: return Talker.SELECTED;
		case 1: return Talker.UNSELECTED;
		case 2: return Talker.RANDOM;
		case 3: return Talker.VALUED;
		default: assert (0);
		}
	}

protected:
	@property
	override CardImage[] imgPaths() { return [new CardImage(selectedTalker)]; }

	override void setup(Composite area) { mixin(S_TRACE);
		super.setup(area);

		area.setLayout(windowGridLayout(2, false));

		auto sash = new SplitPane(area, SWT.HORIZONTAL);
		auto sgd = new GridData(GridData.FILL_BOTH);
		sgd.horizontalSpan = 2;
		sash.setLayoutData(sgd);
		auto left = new Composite(sash, SWT.NONE);
		left.setLayout(zeroMarginGridLayout(1, true));
		{ mixin(S_TRACE);
			auto grp = new Group(left, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setText(prop.msgs.talker);
			grp.setLayout(normalGridLayout(1, true));
			_talkers = new Combo(grp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			mod(_talkers);
			_talkers.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_talkers.add(prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.SELECTED)));
			_talkers.add(prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.UNSELECTED)));
			_talkers.add(prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.RANDOM)));
			_talkers.add(prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.VALUED)));
			_talkers.addSelectionListener(new SelectTalker);
		}

		auto leftSash = new SplitPane(left, SWT.VERTICAL);
		leftSash.resizeControl1 = true;
		leftSash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto skin = comm.skin;
		{ mixin(S_TRACE);
			auto grp = new Group(leftSash, SWT.NONE);
			grp.setText(prop.msgs.toneCoupons);
			grp.setLayout(normalGridLayout(1, true));
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
		void delegate() updateValue;
		{ mixin(S_TRACE);
			createValueEditor(comm, summ, leftSash, &catchMod, _couponView, _initValue, updateValue);
			mod(_initValue);
			mod(_couponView);
			_couponView.modEvent ~= &refreshWarning;
		}
		auto right = new Composite(sash, SWT.NONE);
		right.setLayout(zeroMarginGridLayout(2, false));
		{ mixin(S_TRACE);
			_dlgsL = .rangeSelectableTable(right, SWT.SINGLE | SWT.FULL_SELECTION | SWT.BORDER | SWT.V_SCROLL);
			new FullTableColumn(_dlgsL, SWT.NONE);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = 0;
			gd.heightHint = 0;
			_dlgsL.setLayoutData(gd);
			_dlgsL.addSelectionListener(new SelL);
			_warningTip = new ToolTip(_dlgsL.getShell(), SWT.NONE);
			_warningTip.setAutoHide(true);
			auto mmdl = new MouseMoveDlgsL;
			_dlgsL.addMouseMoveListener(mmdl);
			_dlgsL.addMouseTrackListener(mmdl);

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

		auto sChar = createSCharBar(comm, area, &insert, &put, prop, skin);
		sChar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

		auto rows = createSelectionColumns(area);

		auto skinSChar = createSkinSCharBar(comm, area, &insert, prop, skin);
		auto gdS = new GridData(GridData.FILL_HORIZONTAL);
		gdS.horizontalSpan = 2;
		skinSChar.setLayoutData(gdS);

		auto var = createFlagStepBar(area, &insert, comm, prop, skin, summ, true);
		auto gdV = new GridData(GridData.FILL_HORIZONTAL);
		gdV.horizontalSpan = 2;
		var.setLayoutData(gdV);

		area.setTabList([sash, sChar, skinSChar, var, rows]);

		.setupWeights(leftSash, prop.var.etc.talkLeftSashL, prop.var.etc.talkLeftSashR);
		.setupWeights(sash, prop.var.etc.talkMainSashL, prop.var.etc.talkMainSashR);
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
			_selectionColumns.setSelection(evt.selectionColumns);
		} else { mixin(S_TRACE);
			_talkers.select(0);
			_dlgs = [new SDialog];
			_selectionColumns.setSelection(1);
		}
		refreshDlgList();

		_textTM = createTextMenu!Text(comm, prop, _rCoupons, &catchMod, _undo, TMAppendData(&readAPD, &writeAPD));
		_rCouponsTM = createTextMenu!Text(comm, prop, _text.widget, &catchMod, _undo, TMAppendData(&readAPD, &writeAPD));

		initPreview(area, prop.var.dlgPrev);
		updateValue();
		updateTalker();
		refDataVersion();
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
		evt.selectionColumns = _selectionColumns.getSelection();
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

		bool[string] wFlags;
		bool[string] wSteps;
		bool[string] wFonts;
		bool[char] wColors;
		string[] flags;
		string[] steps;
		string[] fonts;
		char[] colors;
		textUseItems(lastRet(wrapReturnCode(_text.getText())), flags, steps, fonts, colors);
		ws ~= textWarnings(flags, steps, fonts, colors,
			wFlags, wSteps, wFonts, wColors).all;

		if (!prop.isTargetVersion(summ, "1")) { mixin(S_TRACE);
			if (_selectionColumns.getSelection() != 1) { mixin(S_TRACE);
				ws ~= prop.msgs.warningSelectionColumns;
			}
		}

		warning = ws;
	}

	protected override void refDataVersion() { mixin(S_TRACE);
		_selectionColumns.setEnabled(!summ || !summ.legacy || _selectionColumns.getSelection() != 1);
		refreshWarning();
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
			refreshWarning();
		}
	}
	void put(dchar put) { mixin(S_TRACE);
		putColor(_text, put);
	}
	void insert(string put) { mixin(S_TRACE);
		_text.insert(put);
	}
	protected override void refSkin() { mixin(S_TRACE);
		_text.font = prop.looks.messageFont(summSkin.legacy);
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, Content parent, Content evt) { mixin(S_TRACE);
		super(comm, prop, shell, summ, CType.TALK_MESSAGE, parent, evt, prop.var.msgDlg);
	}

	CardImage[] selectedTalkerParam() { mixin(S_TRACE);
		switch (_tabf.getSelectionIndex()) {
		case 0:
			return _msel.images;
		case 1:
			return [];
		default: assert (0);
		}
	}

	@property
	override CardImage[] imgPaths() { mixin(S_TRACE);
		return selectedTalkerParam();
	}
	@property
	override string text() { mixin(S_TRACE);
		return wrapReturnCode(_text.getText());
	}
protected:
	override void setup(Composite area) { mixin(S_TRACE);
		super.setup(area);

		area.setLayout(windowGridLayout(2, false));
		_tabf = new CTabFolder(area, SWT.BORDER);
		mod(_tabf);
		auto gdT = new GridData(GridData.FILL_BOTH);
		gdT.horizontalSpan = 2;
		_tabf.setLayoutData(gdT);
		auto skin = comm.skin;
		{ mixin(S_TRACE);
			auto comp = new Composite(_tabf, SWT.NONE);
			comp.setLayout(normalGridLayout(2, false));
			Control tp;
			if (evt) { mixin(S_TRACE);
				tp = createTalkerPane(comp, comm, prop, summ, evt.cardPaths, _msel);
			} else { mixin(S_TRACE);
				tp = createTalkerPane(comp, comm, prop, summ, [], _msel);
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

		auto sChar = createSCharBar(comm, area, &insert, &put, prop, skin);
		sChar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

		auto rows = createSelectionColumns(area);

		auto skinSChar = createSkinSCharBar(comm, area, &insert, prop, skin);
		auto gdS = new GridData(GridData.FILL_HORIZONTAL);
		gdS.horizontalSpan = 2;
		skinSChar.setLayoutData(gdS);

		auto var = createFlagStepBar(area, &insert, comm, prop, skin, summ, true);
		auto gdV = new GridData(GridData.FILL_HORIZONTAL);
		gdV.horizontalSpan = 2;
		var.setLayoutData(gdV);

		_tabf.addSelectionListener(new SL);

		area.setTabList([_tabf, sChar, skinSChar, var, rows]);

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		_tabf.setSelection(0);
		if (evt) { mixin(S_TRACE);
			_text.setText(evt.text);
			if (evt.cardPaths == []) { mixin(S_TRACE);
				_tabf.setSelection(1);
			}
			_selectionColumns.setSelection(evt.selectionColumns);
		} else { mixin(S_TRACE);
			_tabf.setSelection(1);
			_selectionColumns.setSelection(1);
		}
		tabChanged();

		initPreview(area, prop.var.msgPrev);
		_msel.modEvent ~= &refreshPreview;
		_msel.updateImageEvent ~= &refreshPreview;
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		string text;
		auto paths = selectedTalkerParam();
		text = lastRet(wrapReturnCode(_text.getText()));
		if (!evt) evt = new Content(CType.TALK_MESSAGE, "");
		evt.text = text;
		evt.cardPaths = paths;
		evt.selectionColumns = _selectionColumns.getSelection();
		return true;
	}
}

private Composite createTalkerPane2(Composite parent, Commons comm, Props prop, Summary summ,
		string[] coupons, out Text couponList, out Combo couponCombo) { mixin(S_TRACE);
	auto comp = new Composite(parent, SWT.NONE);
	comp.setLayout(zeroMarginGridLayout(2, false));
	couponCombo = createCouponCombo(comm, summ, comp, null, CouponComboType.Talker, "");
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
					_list.setSelection(cast(int)_list.getText().length, cast(int)_list.getText().length);
					auto s = .wrapReturnCode(_list.getText());
					if (s.length && !std.string.endsWith(s, "\n")) { mixin(S_TRACE);
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
		(Composite parent, Commons comm, Props prop, Summary summ, CardImage[] paths,
		out ImageSelect!(MtType.CARD, Combo) msel) { mixin(S_TRACE);
	auto comp = new Composite(parent, SWT.NONE);
	{ mixin(S_TRACE);
		comp.setLayout(zeroMarginGridLayout(1, true));
	}
	string[] defs = [
		prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.SELECTED)),
		prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.UNSELECTED)),
		prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.RANDOM)),
		prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.CARD))
	];
	auto s = prop.looks.cardSize;
	msel = new ImageSelect!(MtType.CARD, Combo)(comp, SWT.NONE, comm, prop, summ, prop.s(s.width), prop.s(s.height),
		false, () => "", null, included => defs);
	msel.valueFromDef = (defIndex, included, binPath) { mixin(S_TRACE);
		switch (defIndex) {
		case 0: return new CardImage(Talker.SELECTED);
		case 1: return new CardImage(Talker.UNSELECTED);
		case 2: return new CardImage(Talker.RANDOM);
		case 3: return new CardImage(Talker.CARD);
		default: return new CardImage("", CardImagePosition.Default);
		}
	};
	msel.valueToDef = (imgPath, included) { mixin(S_TRACE);
		final switch (imgPath.type) {
		case CardImageType.File:
			return imgPath.path == "" ? 0 : -1;
		case CardImageType.PCNumber:
			return -1; // 非対応
		case CardImageType.Talker:
			final switch (imgPath.talker) {
			case Talker.SELECTED: return 0;
			case Talker.UNSELECTED: return 1;
			case Talker.RANDOM: return 2;
			case Talker.CARD: return 3;
			case Talker.VALUED: return -1; // 非対応
			}
		}
	};
	auto gd = new GridData(GridData.FILL_BOTH);
	msel.widget.setLayoutData(gd);
	msel.images = paths.length ? paths : [new CardImage(Talker.SELECTED)];

	void refImageScale() { mixin(S_TRACE);
		msel.setPreviewSize(prop.s(s.width), prop.s(s.height));
	}
	comm.refImageScale.add(&refImageScale);
	.listener(msel.widget, SWT.Dispose, { mixin(S_TRACE);
		comm.refImageScale.remove(&refImageScale);
	});

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
	auto r = new FixedWidthText(prop.looks.messageFont(comm.skin.legacy), len, parent, SWT.BORDER, true);
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

ToolBar createSimpleSCharBar(Composite parent,
		void delegate(string) insert, Commons comm, Props prop, Skin skin) { mixin(S_TRACE);
	auto bar = new ToolBar(parent, SWT.FLAT);
	comm.put(bar);
	bar.addListener(SWT.Traverse, new class Listener {
		override void handleEvent(Event e) {e.doit = true;}
	});
	bar.addListener(SWT.KeyDown, new class Listener {
		override void handleEvent(Event e) {e.doit = true;}
	});
	createToolItem2(comm, bar, prop.msgs.scTalkerName(Talker.SELECTED), prop.images.scTalker(Talker.SELECTED),
		&(new PutC(insert, "#M")).put, null);
	createToolItem2(comm, bar, prop.msgs.scTalkerName(Talker.UNSELECTED), prop.images.scTalker(Talker.UNSELECTED),
		&(new PutC(insert, "#U")).put, null);
	createToolItem2(comm, bar, prop.msgs.scTalkerName(Talker.RANDOM), prop.images.scTalker(Talker.RANDOM),
		&(new PutC(insert, "#R")).put, null);
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

Composite createFlagStepBar(Composite parent, void delegate(string) insert, Commons comm, Props prop, Skin skin, Summary summ, bool imageFont) { mixin(S_TRACE);
	auto bar = new Composite(parent, SWT.NONE);
	bar.setLayout(zeroMarginGridLayout((imageFont && summ) ? 2 : 1, false));
	Composite create(Composite parent, out Combo list, out Button put, string puts, Image image, string delegate(string) lc, int colNum) { mixin(S_TRACE);
		auto comp = new Composite(parent, SWT.NONE);
		auto gl = windowGridLayout(colNum, false);
		gl.marginWidth = 0;
		gl.marginHeight = 0;
		comp.setLayout(gl);
		list = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
		list.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
		list.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		put = new Button(comp, SWT.PUSH);
		put.setToolTipText(puts);
		put.setImage(image);
		put.addSelectionListener(new class SelectionAdapter {
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				insert(lc(list.getText()));
			}
		});
		return comp;
	}
	Combo flags, steps, fonts = null;
	Button putFlag, putStep, putFont = null;
	IncSearch flagIncSearch, stepIncSearch, fontIncSearch = null;
	Button imgListBtn = null;
	auto varComp = new Composite(bar, SWT.NONE);
	varComp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
	varComp.setLayout(zeroMarginGridLayout(2, true));
	create(varComp, flags, putFlag, prop.msgs.addMsgRefFlag, prop.images.flag, (s) => "%" ~ s ~ "%", 2).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
	create(varComp, steps, putStep, prop.msgs.addMsgRefStep, prop.images.step, (s) => "$" ~ s ~ "$", 2).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
	if (imageFont && summ) { mixin(S_TRACE);
		auto comp = create(bar, fonts, putFont, prop.msgs.addMsgRefImageFont, prop.images.imageFont, (s) => .tryFormat("#%s", .decodeFontPath(s)), 3);
		auto fgd = new GridData(GridData.FILL_HORIZONTAL);
		auto gc = new GC(comp);
		scope (exit) gc.dispose();
		fgd.widthHint = gc.wTextExtent("font_##.bmp").x;
		fonts.setLayoutData(fgd);
		imgListBtn = new Button(comp, SWT.TOGGLE);
		imgListBtn.setImage(prop.images.menu(MenuID.LookImages));
		imgListBtn.setToolTipText(prop.msgs.menuText(MenuID.LookImages));
	}

	IncSearch createIncs(Combo combo, void delegate() refList, MenuID openMenu, void delegate() openDlg) { mixin(S_TRACE);
		auto incSearch = new IncSearch(comm, combo);
		incSearch.modEvent ~= refList;
		auto menu = new Menu(combo.getShell(), SWT.POP_UP);
		createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
			.forceFocus(combo, true);
			incSearch.startIncSearch();
		}, () => 1 < combo.getItemCount());
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(comm, menu, MenuID.OpenAtVarView, openDlg, () => combo.getSelectionIndex() >= 0);
		combo.setMenu(menu);
		return incSearch;
	}

	void refListF() { mixin(S_TRACE);
		auto root = comm.summary.flagDirRoot;
		auto fSel = flags.getText();
		flags.removeAll();
		auto list = root.allFlags;
		size_t i = 0;
		foreach (flag; list) { mixin(S_TRACE);
			auto p = flag.path;
			if (!flagIncSearch.match(p)) continue;
			flags.add(p);
			if (0 == i || p == fSel) flags.select(cast(int)i);
			i++;
		}
		flags.setEnabled(list.length > 0);
		putFlag.setEnabled(flags.getItemCount() > 0);
	}
	void refListS() { mixin(S_TRACE);
		auto root = comm.summary.flagDirRoot;
		auto sSel = steps.getText();
		steps.removeAll();
		auto list = root.allSteps;
		size_t i = 0;
		foreach (step; list) { mixin(S_TRACE);
			auto p = step.path;
			if (!stepIncSearch.match(p)) continue;
			steps.add(p);
			if (0 == i || p == sSel) steps.select(cast(int)i);
			i++;
		}
		steps.setEnabled(list.length > 0);
		putStep.setEnabled(steps.getItemCount() > 0);
	}

	flagIncSearch = createIncs(flags, &refListF, MenuID.OpenAtVarView, { mixin(S_TRACE);
		auto flag = summ.flagDirRoot.findFlag(flags.getText());
		if (!flag) return;
		try { mixin(S_TRACE);
			comm.openCWXPath(flag.cwxPath(true), false);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	});
	stepIncSearch = createIncs(steps, &refListS, MenuID.OpenAtVarView, { mixin(S_TRACE);
		auto step = summ.flagDirRoot.findStep(steps.getText());
		if (!step) return;
		try { mixin(S_TRACE);
			comm.openCWXPath(step.cwxPath(true), false);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	});

	refListF();
	refListS();

	void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps) { mixin(S_TRACE);
		refListF();
		refListS();
	}
	comm.refFlagAndStep.add(&refFlagAndStep);
	comm.delFlagAndStep.add(&refFlagAndStep);
	bar.addDisposeListener(new class DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			comm.refFlagAndStep.remove(&refFlagAndStep);
			comm.delFlagAndStep.remove(&refFlagAndStep);
		}
	});

	if (fonts) { mixin(S_TRACE);
		ImageListWindow!(MtType.CARD) imgListWin = null;
		void refListSPF() { mixin(S_TRACE);
			auto sel = fonts.getText();
			fonts.removeAll();
			auto sPath = summ.scenarioPath;
			size_t i = 0;
			bool has = false;
			foreach (file; .clistdir(sPath)) { mixin(S_TRACE);
				if (containsPath(prop.var.etc.ignorePaths, file)) continue;
				if (summ.isSystemFile(sPath.buildPath(file))) continue;
				auto u = to!dstring(file);
				if (istartsWith(file, "font_") && u.length == 10 && file.extension().toLower() == ".bmp") { mixin(S_TRACE);
					if (summ.legacy) { mixin(S_TRACE);
						auto n = u[5];
						if (!isSJIS1ByteChar(n)) { mixin(S_TRACE);
							// クラシックなシナリオではShift JISの1バイト文字以外は不可
							continue;
						}
					}
					auto path = sPath.buildPath(file);
					if (skin.isBgImage(path)) { mixin(S_TRACE);
						has = true;
						if (!fontIncSearch.match(to!string(decodeFontPath(file)))) continue;
						fonts.add(file);
						if (0 == i || 0 == fncmp(file, sel)) fonts.select(cast(int)i);
						i++;
					}
				}
			}
			fonts.setEnabled(has);
			putFont.setEnabled(fonts.getItemCount() > 0);
			imgListBtn.setEnabled(fonts.getItemCount() > 0);

			if (imgListWin && !imgListWin.shell.isDisposed()) { mixin(S_TRACE);
				imgListWin.images("/", fonts.getItems());
				imgListWin.select(encodePath(fonts.getText()));
			}
			if (!has) { mixin(S_TRACE);
				// ヒント表示
				fonts.add("font_?.bmp");
				fonts.select(0);
			}
		}
		fontIncSearch = createIncs(fonts, &refListSPF, MenuID.OpenAtFileView, { mixin(S_TRACE);
			auto font = fonts.getText();
			try { mixin(S_TRACE);
				comm.openFilePath(font, false, true);
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		});
		refListSPF();

		void refPath(string o, string n, bool isDir) { refListSPF(); }
		void refPaths(string parent) { refListSPF(); }
		comm.refPath.add(&refPath);
		comm.refPaths.add(&refPaths);
		comm.delPaths.add(&refListSPF);
		comm.refIgnorePaths.add(&refListSPF);
		comm.refSkin.add(&refListSPF);
		bar.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				comm.refPath.remove(&refPath);
				comm.refPaths.remove(&refPaths);
				comm.delPaths.remove(&refListSPF);
				comm.refIgnorePaths.remove(&refListSPF);
				comm.refSkin.remove(&refListSPF);
			}
		});

		.listener(fonts, SWT.Selection, { mixin(S_TRACE);
			if (imgListWin && !imgListWin.shell.isDisposed()) { mixin(S_TRACE);
				imgListWin.select(encodePath(fonts.getText()));
			}
		});
		class SelImageList : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				auto b = cast(Button)e.widget;
				if (b.getSelection()) { mixin(S_TRACE);
					if (imgListWin && !imgListWin.shell.isDisposed()) { mixin(S_TRACE);
						imgListWin.shell.setActive();
						return;
					}
					auto parent = (cast(Control)e.widget).getShell();
					imgListWin = new ImageListWindow!(MtType.CARD)(prop, comm, summ, parent, (string path) { mixin(S_TRACE);
						auto s = .tryFormat("#%s", .decodeFontPath(path));
						insert(s);
					}, b);
					.listener(imgListWin.shell, SWT.Dispose, { mixin(S_TRACE);
						b.setSelection(false);
					});
					auto menu = new Menu(imgListWin.shell, SWT.POP_UP);
					createMenuItem(comm, menu, MenuID.IncSearch, () => fontIncSearch.startIncSearch(), null);
					imgListWin.widget.setMenu(menu);

					auto cloc = Display.getCurrent().getCursorLocation();
					cloc.x++;
					cloc.y++;
					auto p = new Point(prop.var.etc.imageListWidth, prop.var.etc.imageListHeight);
					intoDisplay(cloc.x, cloc.y, p.x, p.y);
					imgListWin.shell.setBounds(cloc.x, cloc.y, p.x, p.y);
					imgListWin.images("/", fonts.getItems());
					imgListWin.mask = true;
					imgListWin.select(encodePath(fonts.getText()));
					imgListWin.shell.open();
				} else { mixin(S_TRACE);
					if (!imgListWin || imgListWin.shell.isDisposed()) { mixin(S_TRACE);
						return;
					}
					imgListWin.shell.close();
					imgListWin.shell.dispose();
				}
			}
		}
		imgListBtn.addSelectionListener(new SelImageList);
	}

	return bar;
}

private void putColor(FixedWidthText text, dchar put) { mixin(S_TRACE);
	auto sel = text.widget.getSelection();
	auto old = toUTF32(text.getText());
	auto newt = cwx.msgutils.putColor(old, put, sel.x, sel.y);
	text.setText(toUTF8(newt));
	int nSel = sel.y + (cast(int)newt.length - cast(int)old.length);
	text.widget.setSelection(nSel);
}

class MsgPreviewWindow {
	private Commons _comm;

	private MsgPreview _preview;

	private Button _toggle;
	private WSize _size;
	private Shell _win;
	private ControlListener _winL;
	private int _parX, _parY;
	private int _oldImageScale;

	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_win.getParent().removeControlListener(_winL);
		}
	}
	private class PShellL : ControlAdapter {
		override void controlMoved(ControlEvent e) { mixin(S_TRACE);
			auto pb = _win.getParent().getBounds();
			auto tb = _win.getBounds();
			_win.setBounds(tb.x + pb.x - _parX, tb.y + pb.y - _parY, tb.width, tb.height);
			_parX = pb.x;
			_parY = pb.y;
			saveWin();
		}
	}
	private class ShellL : ShellAdapter {
		override void shellClosed(ShellEvent e) { mixin(S_TRACE);
			close();
			e.doit = false;
		}
	}

	this (Shell parent, Commons comm, Props prop, Summary summ, Button toggle, WSize size) { mixin(S_TRACE);
		_comm = comm;
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
		.listener(_win, SWT.Move, &saveWin);
		.listener(_win, SWT.Resize, &saveWin);
		comm.refImageScale.add(&refImageScale);
		.listener(_win, SWT.Dispose, { mixin(S_TRACE);
			comm.refImageScale.remove(&refImageScale);
		});
		_oldImageScale = comm.prop.var.etc.imageScale;

		_preview = new MsgPreview(_win, comm, prop, summ);
	}

	private void refImageScale() { mixin(S_TRACE);
		auto ws = _win.getSize();
		auto b = _comm.prop.looks.messageBounds;
		auto oldW = cast(int)b.width * _oldImageScale;
		auto newW = cast(int)b.width * _comm.prop.var.etc.imageScale;
		ws.x += newW - oldW;
		auto oldH = cast(int)b.height * _oldImageScale;
		auto newH = cast(int)b.height * _comm.prop.var.etc.imageScale;
		ws.y += newH - oldH;
		_win.setSize(ws);

		_oldImageScale = _comm.prop.var.etc.imageScale;
	}

	private void saveWin() { mixin(S_TRACE);
		if (!_win.isVisible()) return;
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
		.setupWindow(_win, _size);
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
	void dispose() { mixin(S_TRACE);
		_win.dispose();
	}

	void text(CardImage[] imgPaths, string message) { mixin(S_TRACE);
		_preview.text(imgPaths, message);
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
		cwx.flag.Flag flag;
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
				auto itm = _values.getItem(cast(int)i);
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
			_values.remove(cast(int)_targetChars.length, _values.getItemCount() - 1);
		}
		if (_summ) { mixin(S_TRACE);
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
	}
	private void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps) { mixin(S_TRACE);
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
			if (cast(int)i in set) { mixin(S_TRACE);
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
		if (_summ) { mixin(S_TRACE);
			foreach (f; _summ.flagDirRoot.allFlags) { mixin(S_TRACE);
				if (cast(int)i in set) { mixin(S_TRACE);
					auto itm = _values.getItem(cast(int)i);
					itm.setText(1, f.onOff ? f.on : f.off);
					auto data = cast(FlagData) itm.getData();
					data.onOff = f.onOff;
				}
				i++;
			}
			foreach (f; _summ.flagDirRoot.allSteps) { mixin(S_TRACE);
				if (cast(int)i in set) { mixin(S_TRACE);
					auto itm = _values.getItem(cast(int)i);
					itm.setText(1, f.values[f.select]);
					auto data = cast(StepData) itm.getData();
					data.select = f.select;
				}
				i++;
			}
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
			if (cast(int)i in set) { mixin(S_TRACE);
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
		if (_summ) { mixin(S_TRACE);
			foreach (f; _summ.flagDirRoot.allFlags) { mixin(S_TRACE);
				if (cast(int)i in set) { mixin(S_TRACE);
					auto itm = _values.getItem(cast(int)i);
					auto data = cast(FlagData) itm.getData();
					if (data.onOff != f.onOff) return false;
				}
				i++;
			}
			foreach (f; _summ.flagDirRoot.allSteps) { mixin(S_TRACE);
				if (cast(int)i in set) { mixin(S_TRACE);
					auto itm = _values.getItem(cast(int)i);
					auto data = cast(StepData) itm.getData();
					if (data.select != f.select) return false;
				}
				i++;
			}
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
					printStackTrace();
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

		_values = .rangeSelectableTable(this, SWT.BORDER | SWT.FULL_SELECTION | SWT.MULTI);
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
			auto itm = _values.getItem(cast(int)i);
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
			auto itm = _values.getItem(cast(int)i);
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
			auto itm = _values.getItem(cast(int)i);
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

	private CardImage[] _imgPaths = [];
	private string _message = "";

	private class Paint : PaintListener {
		override void paintControl(PaintEvent e) { mixin(S_TRACE);
			refreshImpl();
			auto b = _canvas.getBounds();
			auto rect = _prop.looks.messageBounds;
			e.gc.drawImage(_img, (b.width - _prop.s(rect.width)) / 2, (b.height - _prop.s(rect.height)) / 2);
		}
	}
	private class Dispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			if (_img) _img.dispose();
			_comm.refSkin.remove(&refresh);
			_comm.refImageScale.remove(&refImageScale);
		}
	}

	this (Composite parent, Commons comm, Props prop, Summary summ) { mixin(S_TRACE);
		super (parent, SWT.NONE);

		_comm = comm;
		_prop = prop;
		_summ = summ;

		this.setLayout(zeroGridLayout(1, true));

		_canvas = new Canvas(this, SWT.DOUBLE_BUFFERED);
		refImageScaleImpl();
		_canvas.addPaintListener(new Paint);
		_canvas.addDisposeListener(new Dispose);

		_values = new PreviewValues(this, comm, prop, summ, true);
		auto vgd = new GridData(GridData.FILL_BOTH);
		vgd.heightHint = _prop.var.etc.messageVarTableHeight;
		_values.setLayoutData(vgd);
		_values.modEvent ~= &refresh;
		_comm.refSkin.add(&refresh);
		_comm.refImageScale.add(&refImageScale);
	}

	private void refImageScale() { mixin(S_TRACE);
		refImageScaleImpl();
		layout(true);
		refresh();
	}
	private void refImageScaleImpl() { mixin(S_TRACE);
		auto cgd = new GridData(GridData.FILL_HORIZONTAL);
		auto rect = _prop.looks.messageBounds;
		cgd.widthHint = _prop.s(rect.width);
		cgd.heightHint = _prop.s(rect.height);
		_canvas.setLayoutData(cgd);
	}

	void text(CardImage[] imgPaths, string message) { mixin(S_TRACE);
		if (imgPaths == _imgPaths && message == _message) { mixin(S_TRACE);
			return;
		}
		_imgPaths = imgPaths;
		_message = message;
		if (isVisible()) refresh();
	}

	private void refresh() { mixin(S_TRACE);
		if (_img) { mixin(S_TRACE);
			_img.dispose();
			_img = null;
		}
		_canvas.redraw();
	}
	private void refreshImpl() { mixin(S_TRACE);
		if (_img) return;
		auto d = _canvas.getDisplay();
		ImageData[] tImg = [];
		foreach (imgPath; _imgPaths) { mixin(S_TRACE);
			final switch (imgPath.type) {
			case CardImageType.File:
				tImg ~= loadImage(_comm.skin.findImagePath(imgPath.path, _summ.scenarioPath), true);
				break;
			case CardImageType.PCNumber:
				// Invalid data.
				break;
			case CardImageType.Talker:
				final switch (imgPath.talker) {
				case Talker.SELECTED:
				case Talker.UNSELECTED:
				case Talker.RANDOM:
				case Talker.VALUED:
					tImg ~= _prop.images.talker(imgPath.talker).getImageData();
					break;
				case Talker.CARD:
					auto cRect = _prop.looks.cardSize;
					tImg ~= menuCard(_comm.skin).scaledTo(cRect.width, cRect.height);
					break;
				}
				break;
			}
		}

		string[char] names;
		string[string] flags, steps;
		_values.getValues(names, flags, steps);
		_img = new Image(d, previewMessage(_comm, _prop, _summ.scenarioPath, tImg, _message, [], names, flags, steps));
	}

	@property
	bool focusInValues() { mixin(S_TRACE);
		return _values.focusInValues;
	}
	bool undo() { return _values.undo(); }
	bool redo() { return _values.redo(); }
}

/// メッセージのプレビューを生成する。
ImageData previewMessage(Commons comm, Props prop, string sPath, ImageData[] talkers, string message, in string[] sel, in string[char] names, in string[string] flags, in string[string] steps) { mixin(S_TRACE);
	auto d = Display.getCurrent();
	version (Windows) {
		bool legacy = comm.skin.legacy;
	} else { mixin(S_TRACE);
		bool legacy = false;
	}
	auto rect = prop.looks.messageBounds;
	auto bh = prop.looks.messageButtonHeight;
	auto canvas = new Image(d, rect.width, rect.height + bh * cast(int)sel.length);
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
		gc.fillRectangle(3, rect.height + 3 + bh * cast(int)i, rect.width - 6, bh - 6);
	}

	// 話者の描画
	foreach (talker; talkers) { mixin(S_TRACE);
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
			if (f == path) { mixin(S_TRACE);
				return v;
			}
		}
		return null;
	}
	string sValue(string path) { mixin(S_TRACE);
		foreach (f, v; steps) { mixin(S_TRACE);
			if (f == path) { mixin(S_TRACE);
				return v;
			}
		}
		return null;
	}
	version (Windows) {
		message = wrapReturnCode(message);
		message = message.replace("\r\n", "\n");
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
		if (comm.summary.legacy) { mixin(S_TRACE);
			auto c = decodeFontPath(path);
			if (!isSJIS1ByteChar(c)) return false;
		}
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

	auto font = .createFontFromPixels(prop.looks.messageFont(legacy));
	scope (exit) font.dispose();
	auto fc = new Color(d, dwtData(prop.var.etc.messageForeColor, alpha));
	scope (exit) fc.dispose();
	auto hc = new Color(d, dwtData(prop.var.etc.messageHemColor, alpha));
	scope (exit) hc.dispose();
	auto selFont = .createFontFromPixels(prop.looks.messageSelectFont(legacy));
	scope (exit) selFont.dispose();

	auto start = prop.looks.messageStartPos(legacy, 0 < talkers.length);
	int x = start.x, y = start.y;
	int lineH;
	string old = "";
	int msgLen =  talkers.length ? prop.looks.messageImageLen : prop.looks.messageLen;
	int writeLen = 0;
	void ret() { mixin(S_TRACE);
		writeLen = 0;
		x = start.x;
		y += lineH;
		old = "";
	}

	auto textCanvas = new Image(d, rect.width, rect.height + bh * cast(int)sel.length);
	scope (exit) textCanvas.dispose();
	auto tgc = new GC(textCanvas);
	scope (exit) tgc.dispose();

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
			auto img = new Image(d, data);
			scope (exit) img.dispose();
			tgc.drawImage(img, pt.x, pt.y);
		} else {
			if (data) { mixin(S_TRACE);
				auto img = new Image(d, data);
				scope (exit) img.dispose();
				gc.drawImage(img, pt.x, pt.y);
			}
		}
	}

	// FIXME: IPAフォントの使用とアンチエイリアス設定を
	//        同時に行うと一部環境で問題が出る。
	//tgc.setTextAntialias(SWT.OFF);
	tgc.setFont(font);
	tgc.setForeground(fc);
	tgc.setBackground(hc);
	tgc.fillRectangle(0, 0, rect.width, rect.height + bh * cast(int)sel.length);
	lineH = prop.looks.messageLineHeight;
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
			auto w = prop.looks.messageCharWidth;
			if (msgLen < writeLen + 2) { mixin(S_TRACE);
				// 列数オーバー
				if (dmsg[i] != '\n') { mixin(S_TRACE);
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
			default: break;
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
			auto te = tgc.wTextExtent(s);
			int len = (te.x + 1) / tgc.wTextExtent("#").x;
			int w = prop.looks.messageCharWidth;
			if (len < 2) w = prop.looks.messageCharWidth / 2;
			// 行末が半角スペースの時だけ特別扱いする(CardWirthの挙動に合わせた処理)
			if (msgLen < writeLen + (s == " " ? len - 1 : len)) { mixin(S_TRACE);
				// 列数オーバー
				if (dmsg[i] != '\n') { mixin(S_TRACE);
					ret();
				}
				if (rect.height - 6 < y + lineH) { mixin(S_TRACE);
					// 行数オーバー
					break;
				}
			}
			writeLen += len;
			static immutable JOINS = "―─＿￣";
			if (std.string.indexOf(JOINS, s) != -1) { mixin(S_TRACE);
				// 強制的に左右を接続する文字
				tgc.wDrawText(s, x - 1, y, true);
				tgc.wDrawText(s, x, y, true);
				tgc.wDrawText(s, x + 1, y, true);
			} else { mixin(S_TRACE);
				tgc.wDrawText(s, x, y, true);
			}
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
		sx = (rect.width - tgc.wTextExtent(t).x) / 2;
		tgc.wDrawText(t, sx, sy, true);
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

	// 枠
	auto c1 = new Color(d, dwtData(prop.var.etc.messageLineColor1, alpha));
	scope (exit) c1.dispose();
	auto c2 = new Color(d, dwtData(prop.var.etc.messageLineColor2, alpha));
	scope (exit) c2.dispose();
	gc.setForeground(c1);
	gc.drawRectangle(0, 0, rect.width - 1, rect.height - 1);
	gc.drawRectangle(2, 2, rect.width - 5, rect.height - 5);
	foreach (i; 0 .. sel.length) { mixin(S_TRACE);
		gc.drawRectangle(0, rect.height + bh * cast(int)i, rect.width - 1, bh - 1);
		gc.drawRectangle(2, rect.height + 2 + bh * cast(int)i, rect.width - 5, bh - 5);
	}
	gc.setForeground(c2);
	gc.drawRectangle(1, 1, rect.width - 3, rect.height - 3);
	foreach (i; 0 .. sel.length) { mixin(S_TRACE);
		gc.drawRectangle(1, rect.height + 1 + bh * cast(int)i, rect.width - 3, bh - 3);
	}

	auto data = canvas.getImageData();
	if (1024 < prop.s(1024)) { mixin(S_TRACE);
		data = data.scaledTo(prop.s(data.width), prop.s(data.height));
	}
	return data;
}
