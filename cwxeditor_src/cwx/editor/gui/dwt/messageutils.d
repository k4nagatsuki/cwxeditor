
module cwx.editor.gui.dwt.messageutils;

import cwx.card;
import cwx.event;
import cwx.expression;
import cwx.flag;
import cwx.imagesize;
import cwx.menu;
import cwx.msgutils;
import cwx.path;
import cwx.sjis;
import cwx.skin;
import cwx.structs;
import cwx.summary;
import cwx.system;
import cwx.types;
import cwx.types;
import cwx.usecounter;
import cwx.utils;
import cwx.warning;
import cwx.xml;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.couponview;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.customtext;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.eventdialog;
import cwx.editor.gui.dwt.imagelistwindow;
import cwx.editor.gui.dwt.imageselect;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.properties;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

static import std.algorithm;
import std.algorithm : max, min, sort, uniq;
import std.array;
import std.ascii;
import std.conv;
import std.datetime;
import std.exception;
import std.file;
import std.path;
import std.range;
import std.regex;
import std.string;
import std.typecons;
import std.uni;
import std.utf;

import org.eclipse.swt.all;
import java.lang.all;

/// 台詞コンテント・メッセージコンテントのダイアログの親クラス。
class AbstractMessageDialog : EventDialog {
	private UseCounter _uc;

	private Spinner _selectionColumns;
	private Button _centerX;
	private Button _centerY;
	private Button _boundaryCheck;
	private Button _selectTalker;

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

	protected override void refDataVersion() { mixin(S_TRACE);
		_selectionColumns.setEnabled(!summ || !summ.legacy || _selectionColumns.getSelection() != 1);
		_centerX.setEnabled(!summ || !summ.legacy || _centerX.getSelection());
		_centerY.setEnabled(!summ || !summ.legacy || _centerY.getSelection());
		_boundaryCheck.setEnabled(!summ || !summ.legacy || _boundaryCheck.getSelection());
		updateSelectTalkerEnabled();
		refreshWarning();
	}

	protected void updateSelectTalkerEnabled() { mixin(S_TRACE);
		_selectTalker.setEnabled((!summ || !summ.legacy || _selectTalker.getSelection()) && hasCharacterTalker);
	}

	@property
	protected bool hasCharacterTalker() { return true; }

	@property
	private string[] warnings() { mixin(S_TRACE);
		string[] ws;
		if (!prop.isTargetVersion(summ, "1")) { mixin(S_TRACE);
			if (_selectionColumns.getSelection() != 1) { mixin(S_TRACE);
				ws ~= prop.msgs.warningSelectionColumns;
			}
		}
		if (!prop.isTargetVersion(summ, "2")) { mixin(S_TRACE);
			if (_centerX.getSelection()) { mixin(S_TRACE);
				ws ~= prop.msgs.warningCenteringX;
			}
			if (_centerY.getSelection()) { mixin(S_TRACE);
				ws ~= prop.msgs.warningCenteringY;
			}
			if (_boundaryCheck.getSelection()) { mixin(S_TRACE);
				ws ~= prop.msgs.warningBoundaryCheck;
			}
		}
		if (!prop.isTargetVersion(summ, "3")) { mixin(S_TRACE);
			if (_selectTalker.getSelection() && hasCharacterTalker) { mixin(S_TRACE);
				ws ~= prop.msgs.warningSelectTalker;
			}
		}
		return ws;
	}

	private TextWarnings textWarnings(string text, in string[] flags, in string[] steps, in string[] variants, in string[] fonts, in char[] colors,
			ref bool[string] wFlags, ref bool[string] wSteps, ref bool[string] wVariants, ref bool[string] wFonts, ref bool[char] wColors) { mixin(S_TRACE);
		auto isClassic = summ && summ.legacy;
		auto wsnVer = summ ? summ.dataVersion : LATEST_VERSION;
		return .textWarnings(prop.parent, summSkin, summ, _uc, isClassic, wsnVer, prop.var.etc.targetVersion,
			text, flags, steps, variants, fonts, colors, wFlags, wSteps, wVariants, wFonts, wColors);
	}

	private class SelPrev : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			updateShowPreview();
			if (type is CType.TalkMessage) { mixin(S_TRACE);
				prop.var.etc.showMessagePreview = _preview ? _preview.isVisible() : _previewWin.isVisible();
			} else if (type is CType.TalkDialog) { mixin(S_TRACE);
				prop.var.etc.showDialogPreview = _preview ? _preview.isVisible() : _previewWin.isVisible();
			} else assert (0);
			if (!_previewWin) { mixin(S_TRACE);
				// プレビューがメインダイアログと一体化しているので
				// メインダイアログのサイズが変わる場合
				saveWin();
			}
		}
	}
	private void updatePreview() { mixin(S_TRACE);
		auto s = wrapReturnCode(text);
		if (_previewWin) { mixin(S_TRACE);
			_previewWin.text(imgPaths, s, _centerX.getSelection(), _centerY.getSelection(), _boundaryCheck.getSelection());
			_previewWin.text(imgPaths, s, _centerX.getSelection(), _centerY.getSelection(), _boundaryCheck.getSelection());
		} else { mixin(S_TRACE);
			_preview.text(imgPaths, s, _centerX.getSelection(), _centerY.getSelection(), _boundaryCheck.getSelection());
		}
	}
	private void updateShowPreview() { mixin(S_TRACE);
		auto btn = _prev;
		if (btn.getSelection()) { mixin(S_TRACE);
			if (_previewWin) { mixin(S_TRACE);
				if (_previewWin.isVisible()) return;
				updatePreview();
				_previewWin.open();
			} else { mixin(S_TRACE);
				if (rightGroup.isVisible()) return;
				updatePreview();
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
			if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
				comm.refFlagAndStep.remove(&refFlagAndStep);
				comm.delFlagAndStep.remove(&refFlagAndStep);
				comm.refPaths.remove(&refPaths);
				comm.refPath.remove(&refPath);
				comm.delPaths.remove(&refreshWarning);
			}
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
			if (cast(Text)c) return;
			if (cast(StyledText)c) return;
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
		if (type is CType.TalkMessage) { mixin(S_TRACE);
			show = prop.var.etc.showMessagePreview;
		} else if (type is CType.TalkDialog) { mixin(S_TRACE);
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
			if (type is CType.TalkMessage) { mixin(S_TRACE);
				show = prop.var.etc.showMessagePreview;
			} else if (type is CType.TalkDialog) { mixin(S_TRACE);
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
			_previewWin = new MsgPreviewWindow(getShell(), comm, prop, summ, _uc, _prev, size);
		} else { mixin(S_TRACE);
			assert (rightGroup && !rightGroup.isDisposed());
			_preview = new MsgPreview(rightGroup, comm, prop, summ, _uc);
			rightGroup.setLayout(zeroGridLayout(1, false));
			_preview.setLayoutData(new GridData(GridData.FILL_BOTH));
			setPreviewLData(_prev.getSelection(), false);
		}
		refreshPreview();
	}

	this (Commons comm, Props prop, Shell shell, Summary summ, UseCounter uc, CType type, Content parent, Content evt, DSize size) { mixin(S_TRACE);
		super (comm, prop, shell, summ, type, parent, evt, true, size, false, !prop.var.etc.floatMessagePreview);
		_undo = new UndoManager(prop.var.etc.undoMaxEtc);
		_summSkin = findSkin(comm, prop, summ);
		_uc = uc;
	}

	override
	protected void opened() { mixin(S_TRACE);
		if (!_previewWin) return;
		if (type is CType.TalkMessage) { mixin(S_TRACE);
			if (prop.var.etc.showMessagePreview) _previewWin.open();
		} else if (type is CType.TalkDialog) { mixin(S_TRACE);
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
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			comm.refFlagAndStep.add(&refFlagAndStep);
			comm.delFlagAndStep.add(&refFlagAndStep);
			comm.refPaths.add(&refPaths);
			comm.refPath.add(&refPath);
			comm.delPaths.add(&refreshWarning);
		}
		comm.refImageScale.add(&refImageScale);
	}
	private void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps, cwx.flag.Variant[] variants) { refreshWarning(); }
	private void refPath(string o, string n, bool isDir) { refreshWarning(); }
	private void refPaths(string parent) { refreshWarning(); }

	void refreshPreview() { mixin(S_TRACE);
		if (!_previewWin && !_preview) return;
		updatePreview();
		if (_previewWin) { mixin(S_TRACE);
			_previewWin.refresh();
		} else { mixin(S_TRACE);
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

	protected Composite createWsnSettingsBar(Composite parent) { mixin(S_TRACE);
		auto comp = new Composite(parent, SWT.NONE);
		comp.setLayout(zeroMarginGridLayout(5, false));
		createSelectionColumns(comp);

		_centerX = new Button(comp, SWT.CHECK);
		mod(_centerX);
		_centerX.setText(prop.msgs.centeringX);
		.listener(_centerX, SWT.Selection, &refDataVersion);
		.listener(_centerX, SWT.Selection, &refreshPreview);
		_centerY = new Button(comp, SWT.CHECK);
		mod(_centerY);
		_centerY.setText(prop.msgs.centeringY);
		.listener(_centerY, SWT.Selection, &refDataVersion);
		.listener(_centerY, SWT.Selection, &refreshPreview);

		_boundaryCheck = new Button(comp, SWT.CHECK);
		mod(_boundaryCheck);
		_boundaryCheck.setText(prop.msgs.boundaryCheck);
		_boundaryCheck.setToolTipText(prop.msgs.boundaryCheckDesc);
		.listener(_boundaryCheck, SWT.Selection, &refDataVersion);
		.listener(_boundaryCheck, SWT.Selection, &refreshPreview);

		_selectTalker = new Button(comp, SWT.CHECK);
		mod(_selectTalker);
		_selectTalker.setText(prop.msgs.selectTalker);
		.listener(_selectTalker, SWT.Selection, &refDataVersion);

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
		o.selDlg = _dlgsL.getSelectionIndex() == -1 ? 0 : _dlgsL.getSelectionIndex();
		foreach (d; _dlgs) { mixin(S_TRACE);
			o.dlgs ~= new SDialog(d);
		}
		return o;
	}
	void writeAPD(Object o) { mixin(S_TRACE);
		bool oldIgnoreMod = ignoreMod;
		setIgnoreMod(true, false);
		scope (exit) ignoreMod = oldIgnoreMod;
		auto apd = cast(APData)o;
		assert (apd);
		_dlgs.length = apd.dlgs.length;
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
			_selDlg = _dlgsL.getSelectionIndex() == -1 ? 0 : _dlgsL.getSelectionIndex();
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
		override void undo() { impl(); }
		override void redo() { impl(); }
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
			if (Talker.Valued is selectedTalker) { mixin(S_TRACE);
				ws ~= prop.msgs.warningValuedTalker;
			}
		}

		bool[string] wFlags;
		bool[string] wSteps;
		bool[string] wVariants;
		bool[string] wFonts;
		bool[char] wColors;
		_dlgWarnings = [];
		foreach (i, dlg; _dlgs) { mixin(S_TRACE);
			auto dws = textWarnings(dlg.text, dlg.flagsInText, dlg.stepsInText, dlg.variantsInText, dlg.fontsInText, dlg.colorsInText,
				wFlags, wSteps, wVariants, wFonts, wColors);
			if (dws.all.length) { mixin(S_TRACE);
				_dlgsL.getItem(cast(int)i).setImage(prop.images.warning);
				_dlgWarnings ~= dws.all;
			} else { mixin(S_TRACE);
				_dlgsL.getItem(cast(int)i).setImage(prop.images.content(CType.TalkDialog));
			}
			ws ~= dws.noDup;

			foreach (coupon; dlg.rCoupons) { mixin(S_TRACE);
				auto isClassic = summ && summ.legacy;
				auto wsnVer = summ ? summ.dataVersion : LATEST_VERSION;
				ws ~= couponWarnings(prop.parent, isClassic, wsnVer, prop.var.etc.targetVersion, coupon, false, prop.msgs.toneCoupons);
			}
		}

		if (selectedTalker is Talker.Valued) { mixin(S_TRACE);
			ws ~= _couponView.warnings;
		}

		_warningTip.setVisible(false);
		_warningTip.setMessage("");

		ws ~= warnings;

		warning = ws.sort().uniq().array();
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
	FixedWidthText!Text _text;
	TextMenuModify _textTM, _rCouponsTM;
	CouponView!(CVType.Valued) _couponView;
	Spinner _initValue;

	protected override bool canHookKeyDown(Control fc) { mixin(S_TRACE);
		return super.canHookKeyDown(fc) && !isDescendant(_couponView, fc);
	}
	void selectChanged() { mixin(S_TRACE);
		bool oldIgnoreMod = ignoreMod;
		setIgnoreMod(true, false);
		if (_dlgsL.getSelectionIndex() == -1) _dlgsL.select(0);
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
		itm.setImage(prop.images.content(CType.TalkDialog));
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
	@property
	bool canDeleteDialog() { return _dlgsL.getItemCount() > 1 && _dlgsL.getSelectionIndex() != -1; }
	void deleteDialogSel() { mixin(S_TRACE);
		if (_dlgsL.getSelectionIndex() == -1) return;
		deleteDialog(_dlgsL.getSelectionIndex());
	}
	@property
	bool canOverDialog() { return _dlgsL.getSelectionIndex() != -1 && 0 < _dlgsL.getSelectionIndex(); }
	void overDialog() { mixin(S_TRACE);
		int index = _dlgsL.getSelectionIndex();
		if (index > 0) { mixin(S_TRACE);
			_dlgsL.select(index - 1);
			selectChanged();
		}
	}
	@property
	bool canUnderDialog() { return _dlgsL.getSelectionIndex() != -1 && _dlgsL.getSelectionIndex() + 1 < _dlgsL.getItemCount(); }
	void underDialog() { mixin(S_TRACE);
		int index = _dlgsL.getSelectionIndex();
		if (index + 1 < _dlgs.length) { mixin(S_TRACE);
			_dlgsL.select(index + 1);
			selectChanged();
		}
	}

	@property
	bool canUp() { return _dlgsL.getSelectionIndex() != -1 && 0 < _dlgsL.getSelectionIndex(); }
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
	@property
	bool canDown() { return _dlgsL.getSelectionIndex() != -1 && _dlgsL.getSelectionIndex() + 1 < _dlgsL.getItemCount(); }
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
	@property
	bool canCopyToUpper() { return _dlgsL.getSelectionIndex() != -1 && 0 < _dlgsL.getSelectionIndex(); }
	void copyToUpper() { mixin(S_TRACE);
		int index = _dlgsL.getSelectionIndex();
		if (_dlgsL.getSelectionIndex() == -1) return;
		storeEdit();
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
	@property
	bool canCopyToLower() { return _dlgsL.getSelectionIndex() != -1 && _dlgsL.getSelectionIndex() + 1 < _dlgsL.getItemCount(); }
	void copyToLower() { mixin(S_TRACE);
		int index = _dlgsL.getSelectionIndex();
		if (_dlgsL.getSelectionIndex() == -1) return;
		storeEdit();
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
	@property
	bool canCopyToDialogs() { return _dlgsL.getSelectionIndex() != -1 && _dlgsL.getItemCount() > 1; }
	void copyToDialogs() { mixin(S_TRACE);
		int index = _dlgsL.getSelectionIndex();
		if (_dlgsL.getSelectionIndex() == -1) return;
		storeEdit();
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
		putColor(_text.widget, put);
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
		foreach (rc; splitLines(_rCoupons.getText())) { mixin(S_TRACE);
			if (rc.length > 0) { mixin(S_TRACE);
				rcs ~= rc;
			}
		}
		dlg.rCoupons = rcs;
	}
	void updateTalker() { mixin(S_TRACE);
		auto enabled = Talker.Valued is selectedTalker;
		_couponView.enabled = enabled;
		_initValue.setEnabled(enabled);
		comm.refreshToolBar();
	}
	class SelL : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			if (_dlgsL.getSelectionIndex() == -1) _dlgsL.select(0);
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
			if (_dlgsL.getSelectionIndex() == -1) return;
			if (_textTM && _rCouponsTM && !_textTM.inProc() && !_rCouponsTM.inProc()) { mixin(S_TRACE);
				putText(_dlgs[_dlgsL.getSelectionIndex()]);
			}
			refreshDlgList(_dlgsL.getSelectionIndex());
			refreshPreview();
		}
	}
	class ModRC : ModifyListener {
		override void modifyText(ModifyEvent e) { mixin(S_TRACE);
			if (_dlgsL.getSelectionIndex() == -1) return;
			if (_textTM && _rCouponsTM && !_textTM.inProc() && !_rCouponsTM.inProc()) { mixin(S_TRACE);
				putRCoupons(_dlgs[_dlgsL.getSelectionIndex()]);
			}
			refreshWarning();
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
		void del(SelectionEvent se) { deleteDialogSel(); }
		void clone(SelectionEvent se) { mixin(S_TRACE);
			comm.clipboard.memoryMode = true;
			scope (exit) comm.clipboard.memoryMode = false;
			copy(se);
			paste(se);
		}
		@property bool canDoTCPD() { return true; }
		@property bool canDoT() { return 1 < _dlgsL.getItemCount(); }
		@property bool canDoC() { return 0 < _dlgsL.getItemCount(); }
		@property bool canDoP() { return CBisXML(comm.clipboard); }
		@property bool canDoD() { return canDoT; }
		@property bool canDoClone() { return canDoC; }
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
		_text.font = prop.adjustFont(prop.looks.messageFont(summSkin.legacy));
	}
	void refreshDlgList() { mixin(S_TRACE);
		bool oldIgnoreMod = ignoreMod;
		setIgnoreMod(true, false);
		scope (exit) ignoreMod = oldIgnoreMod;
		int selIndex = _dlgsL.getSelectionIndex();
		int topIndex = _dlgsL.getTopIndex();

		_dlgsL.removeAll();
		foreach (dlg; _dlgs) { mixin(S_TRACE);
			auto itm = new TableItem(_dlgsL, SWT.NONE);
			itm.setImage(prop.images.content(CType.TalkDialog));
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
			refMenuImpl(MenuID.Up, &up, &canUp);
			refMenuImpl(MenuID.Down, &down, &canDown);
			refMenuImpl(MenuID.OverDialog, &overDialog, &canOverDialog);
			refMenuImpl(MenuID.UnderDialog, &underDialog, &canUnderDialog);
			refMenuImpl(MenuID.CreateDialog, &createDialog, null);
			refMenuImpl(MenuID.DeleteDialog, &deleteDialogSel, &canDeleteDialog);
			refMenuImpl(MenuID.CopyToAllDialogs, &copyToDialogs, &canCopyToDialogs);
			refMenuImpl(MenuID.CopyToUpperDialogs, &copyToUpper, &canCopyToUpper);
			refMenuImpl(MenuID.CopyToLowerDialogs, &copyToLower, &canCopyToLower);
		}
		override void handleEvent(Event e) { mixin(S_TRACE);
			if (!e.doit) return;
			auto c = cast(Control)e.widget;
			if (!c || c.isDisposed() || c.getShell() !is getShell()) return;
			if (_dlgsL is c) return;
			foreach (id; _accels.keys().sort()) { mixin(S_TRACE);
				auto accel = _accels[id];
				if (accel.enabled && !accel.enabled()) continue;
				if (eqAcc(accel.accel, e.keyCode, e.character, e.stateMask)) { mixin(S_TRACE);
					accel.func();
					e.doit = false;
					break;
				}
			}
		}
	}
	private Tuple!(int, "accel", void delegate(), "func", bool delegate(), "enabled")[MenuID] _accels;
	private void refMenu(MenuID id) { mixin(S_TRACE);
		auto p = id in _accels;
		if (!p) return;
		refMenuImpl(id, p.func, p.enabled);
	}
	private void refMenuImpl(MenuID id, void delegate() func, bool delegate() enabled) { mixin(S_TRACE);
		_accels[id] = typeof(_accels[id])(.convertAccelerator(prop.buildMenu(id)), func, enabled);
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, UseCounter uc, Content parent, Content evt) { mixin(S_TRACE);
		_id = .objectIDValue(this);
		super(comm, prop, shell, summ, uc, CType.TalkDialog, parent, evt, prop.var.speakDlg);
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

			cate = cpcategory(path);
			if ("text" == cate) { mixin(S_TRACE);
				path = cpbottom(path);
			}
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
		case 0: return Talker.Selected;
		case 1: return Talker.Unselected;
		case 2: return Talker.Random;
		case 3: return Talker.Valued;
		default: assert (0);
		}
	}

protected:
	@property
	override CardImage[] imgPaths() { return [new CardImage(selectedTalker)]; }

	override void setup(Composite area) { mixin(S_TRACE);
		super.setup(area);

		area.setLayout(windowGridLayout(1, false));

		auto sash = new SplitPane(area, SWT.HORIZONTAL);
		sash.setLayoutData(new GridData(GridData.FILL_BOTH));
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
			_talkers.add(prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.Selected)));
			_talkers.add(prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.Unselected)));
			_talkers.add(prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.Random)));
			_talkers.add(prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.Valued)));
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
				tp = createTalkerPane2(grp, comm, prop, summ, _uc, evt.dialogs[0].rCoupons, _rCoupons, _rCouponsList);
			} else { mixin(S_TRACE);
				tp = createTalkerPane2(grp, comm, prop, summ, _uc, [], _rCoupons, _rCouponsList);
			}
			mod(_rCoupons);
			_rCoupons.addModifyListener(new ModRC);
			tp.setLayoutData(new GridData(GridData.FILL_BOTH));
		}
		void delegate() updateValue;
		{ mixin(S_TRACE);
			createValueEditor(comm, summ, _uc, leftSash, &catchMod, _couponView, _initValue, updateValue);
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
			createMenuItem(comm, menu, MenuID.Undo, { _undo.undo(); }, &_undo.canUndo);
			createMenuItem(comm, menu, MenuID.Redo, { _undo.redo(); }, &_undo.canRedo);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(comm, menu, MenuID.CreateDialog, &createDialog, null);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(comm, menu, MenuID.Up, &up, &canUp);
			createMenuItem(comm, menu, MenuID.Down, &down, &canDown);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(comm, menu, MenuID.CopyToAllDialogs, &copyToDialogs, &canCopyToDialogs);
			createMenuItem(comm, menu, MenuID.CopyToUpperDialogs, &copyToUpper, &canCopyToUpper);
			createMenuItem(comm, menu, MenuID.CopyToLowerDialogs, &copyToLower, &canCopyToLower);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(comm, menu, MenuID.OverDialog, &overDialog, &canOverDialog);
			createMenuItem(comm, menu, MenuID.UnderDialog, &underDialog, &canUnderDialog);
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(comm, menu, new DialogsTCPD, true, true, true, true, true);
			_dlgsL.setMenu(menu);

			auto bar = new ToolBar(right, SWT.FLAT | SWT.VERTICAL);
			comm.put(bar);
			bar.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			bar.addListener(SWT.Traverse, new class Listener {
				override void handleEvent(Event e) { e.doit = true; }
			});
			bar.addListener(SWT.KeyDown, new class Listener {
				override void handleEvent(Event e) { e.doit = true; }
			});
			createToolItem(comm, bar, MenuID.CreateDialog, &createDialog, null);
			createToolItem(comm, bar, MenuID.DeleteDialog, &deleteDialogSel, &canDeleteDialog);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(comm, bar, MenuID.Up, &up, &canUp);
			createToolItem(comm, bar, MenuID.Down, &down, &canDown);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(comm, bar, MenuID.CopyToAllDialogs, &copyToDialogs, &canCopyToDialogs);
			createToolItem(comm, bar, MenuID.CopyToUpperDialogs, &copyToUpper, &canCopyToUpper);
			createToolItem(comm, bar, MenuID.CopyToLowerDialogs, &copyToLower, &canCopyToLower);
		}
		{ mixin(S_TRACE);
			auto msgComp = new Composite(right, SWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.horizontalSpan = 3;
			msgComp.setLayoutData(gd);
			msgComp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
			_text = createMessagePane(comm, prop, true, msgComp, summ);
			mod(_text.widget);
			_text.widget.setLayoutData(_text.computeTextBaseSize(prop.looks.messageLine));
			_text.widget.addModifyListener(new ModL);
		}

		auto sChar = createSCharBar(comm, summ, right, &insert, &put, prop, skin);
		auto scgd = new GridData(GridData.FILL_HORIZONTAL);
		scgd.horizontalSpan = 2;
		sChar.setLayoutData(scgd);

		auto skinSChar = createSkinSCharBar(comm, right, &insert, () => comm.skin);
		auto sscgd = new GridData(GridData.FILL_HORIZONTAL);
		sscgd.horizontalSpan = 2;
		skinSChar.setLayoutData(sscgd);

		auto var = createFlagStepBar(area, &insert, comm, prop, summ, _uc, skin, true);
		var.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

		auto wBar = createWsnSettingsBar(area);
		wBar.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));

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
		scope (exit) .asyncExec(getShell().getDisplay(), { ignoreMod = false; });
		if (evt) { mixin(S_TRACE);
			switch (evt.talkerNC) {
			case Talker.Selected:
				_talkers.select(0);
				break;
			case Talker.Unselected:
				_talkers.select(1);
				break;
			case Talker.Random:
				_talkers.select(2);
				break;
			case Talker.Valued:
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
			_centerX.setSelection(evt.centeringX);
			_centerY.setSelection(evt.centeringY);
			_boundaryCheck.setSelection(evt.boundaryCheck);
			_selectTalker.setSelection(evt.selectTalker);
		} else { mixin(S_TRACE);
			_talkers.select(0);
			_dlgs = [new SDialog];
			_selectionColumns.setSelection(1);
			_centerX.setSelection(false);
			_centerY.setSelection(false);
			_boundaryCheck.setSelection(false);
			_selectTalker.setSelection(false);
		}
		refreshDlgList();

		_rCouponsTM = createTextMenu!Text(comm, prop, _rCoupons, &catchMod, _undo, TMAppendData(&readAPD, &writeAPD));
		_textTM = createTextMenu!Text(comm, prop, _text.widget, &catchMod, _undo, TMAppendData(&readAPD, &writeAPD));

		auto menu = _text.widget.getMenu();
		new MenuItem(menu, SWT.SEPARATOR);
		.setupSPCharsMenu(comm, summ, _uc, _text.widget, menu, true, true, () => true);

		initPreview(area, prop.var.dlgPrev);
		updateValue();
		updateTalker();
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		if (!evt) evt = new Content(CType.TalkDialog, "");
		evt.dialogs = _dlgs;
		evt.talkerNC = selectedTalker;
		if (Talker.Valued is evt.talkerNC) { mixin(S_TRACE);
			evt.coupons = _couponView.coupons;
			evt.initValue = _initValue.getSelection();
		} else { mixin(S_TRACE);
			evt.coupons = [];
			evt.initValue = 1;
		}
		evt.selectionColumns = _selectionColumns.getSelection();
		evt.centeringX = _centerX.getSelection();
		evt.centeringY = _centerY.getSelection();
		evt.boundaryCheck = _boundaryCheck.getSelection();
		evt.selectTalker = _selectTalker.getSelection();
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			comm.refCoupons.call();
		}
		return true;
	}
}

/// メッセージコンテントの設定ダイアログ。
class MessageDialog : AbstractMessageDialog {
private:
	CTabFolder _tabf;
	Composite _msgCompA, _msgCompB;
	FixedWidthText!Text _text;
	ImageSelect!(MtType.CARD, Combo) _msel;

	override
	protected void refreshWarning() { mixin(S_TRACE);
		string[] ws;

		ws ~= _msel.warnings;

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
		textUseItems(lastRet(wrapReturnCode(_text.getText())), flags, steps, variants, fonts, colors);
		ws ~= textWarnings(_text.getText(), flags, steps, variants, fonts, colors,
			wFlags, wSteps, wVariants, wFonts, wColors).all;

		ws ~= warnings;

		warning = ws;
	}

	@property
	protected override bool hasCharacterTalker() { mixin(S_TRACE);
		foreach (imgPath; selectedTalkerParam) { mixin(S_TRACE);
			if (imgPath.type is CardImageType.Talker && imgPath.talker !is Talker.Card) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
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
		updateSelectTalkerEnabled();
		refreshWarning();
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
		putColor(_text.widget, put);
	}
	void insert(string put) { mixin(S_TRACE);
		_text.insert(put);
	}
	protected override void refSkin() { mixin(S_TRACE);
		_text.font = prop.adjustFont(prop.looks.messageFont(summSkin.legacy));
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, UseCounter uc, Content parent, Content evt) { mixin(S_TRACE);
		super (comm, prop, shell, summ, uc, CType.TalkMessage, parent, evt, prop.var.msgDlg);
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

	override
	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		auto cate = cpcategory(path);
		if ("text" == cate) { mixin(S_TRACE);
			path = cpbottom(path);
			return cpempty(path);
		}
		return super.openCWXPath(path, shellActivate);
	}

protected:
	override void setup(Composite area) { mixin(S_TRACE);
		super.setup(area);

		area.setLayout(windowGridLayout(3, false));
		_tabf = new CTabFolder(area, SWT.BORDER);
		mod(_tabf);
		auto gdT = new GridData(GridData.FILL_BOTH);
		gdT.horizontalSpan = 3;
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
			tp.setLayoutData(new GridData(GridData.FILL_BOTH));
			_msgCompA = new Composite(comp, SWT.NONE);
			_msgCompA.setLayoutData(new GridData(GridData.FILL_VERTICAL));
			_msgCompA.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
			_text = createMessagePane(comm, prop, true, _msgCompA, summ);
			mod(_text.widget);
			_text.widget.addModifyListener(new ModText);
			createTextMenu!Text(comm, prop, _text.widget, &catchMod, _undo);
			auto menu = _text.widget.getMenu();
			new MenuItem(menu, SWT.SEPARATOR);
			.setupSPCharsMenu(comm, summ, _uc, _text.widget, menu, true, true, () => true);
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

		auto sChar = createSCharBar(comm, summ, area, &insert, &put, prop, skin);
		sChar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

		auto skinSChar = createSkinSCharBar(comm, area, &insert, () => comm.skin);
		auto gdS = new GridData(GridData.FILL_HORIZONTAL);
		gdS.horizontalSpan = 3;
		skinSChar.setLayoutData(gdS);

		auto var = createFlagStepBar(area, &insert, comm, prop, summ, _uc, skin, true);
		auto gdV = new GridData(GridData.FILL_HORIZONTAL);
		gdV.horizontalSpan = 3;
		var.setLayoutData(gdV);

		auto wBar = createWsnSettingsBar(area);
		wBar.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));

		_tabf.addSelectionListener(new SL);
		_tabf.setSelection(0);

		ignoreMod = true;
		scope (exit) .asyncExec(getShell().getDisplay(), { ignoreMod = false; });
		if (evt) { mixin(S_TRACE);
			_text.setText(evt.text);
			if (evt.cardPaths == []) { mixin(S_TRACE);
				_tabf.setSelection(1);
			}
			_selectionColumns.setSelection(evt.selectionColumns);
			_centerX.setSelection(evt.centeringX);
			_centerY.setSelection(evt.centeringY);
			_boundaryCheck.setSelection(evt.boundaryCheck);
			_selectTalker.setSelection(evt.selectTalker);
		} else { mixin(S_TRACE);
			_tabf.setSelection(1);
			_selectionColumns.setSelection(1);
			_centerX.setSelection(false);
			_centerY.setSelection(false);
			_boundaryCheck.setSelection(false);
			_selectTalker.setSelection(false);
		}
		tabChanged();

		initPreview(area, prop.var.msgPrev);
		_msel.modEvent ~= &refreshPreview;
		_msel.modEvent ~= &updateSelectTalkerEnabled;
		_msel.updateImageEvent ~= &refreshPreview;
		refDataVersion();
	}

	override bool apply() { mixin(S_TRACE);
		string text;
		auto paths = selectedTalkerParam();
		text = lastRet(wrapReturnCode(_text.getText()));
		if (!evt) evt = new Content(CType.TalkMessage, "");
		evt.text = text;
		evt.cardPaths = paths;
		evt.selectionColumns = _selectionColumns.getSelection();
		evt.centeringX = _centerX.getSelection();
		evt.centeringY = _centerY.getSelection();
		evt.boundaryCheck = _boundaryCheck.getSelection();
		evt.selectTalker = _selectTalker.getSelection();
		return true;
	}
}

private Composite createTalkerPane2(Composite parent, Commons comm, Props prop, Summary summ, UseCounter uc,
		string[] coupons, out Text couponList, out Combo couponCombo) { mixin(S_TRACE);
	auto comp = new Composite(parent, SWT.NONE);
	comp.setLayout(zeroMarginGridLayout(2, false));
	couponCombo = createCouponCombo(comm, summ, uc, comp, null, CouponComboType.Talker, "");
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
		couponList.setTabs(prop.var.etc.tabs);
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

private Composite createTalkerPane(Composite parent, Commons comm, Props prop, Summary summ,
		CardImage[] paths, out ImageSelect!(MtType.CARD, Combo) msel) { mixin(S_TRACE);
	auto comp = new Composite(parent, SWT.NONE);
	{ mixin(S_TRACE);
		comp.setLayout(zeroMarginGridLayout(1, true));
	}
	string[] defs = [
		prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.Selected)),
		prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.Unselected)),
		prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.Random)),
		prop.msgs.defaultSelection(prop.msgs.talkerName(Talker.Card))
	];
	auto s = prop.looks.cardSize;
	msel = new ImageSelect!(MtType.CARD, Combo)(comp, SWT.NONE, comm, prop, summ, prop.s(s.width), prop.s(s.height),
		prop.s(CInsets(0, 0, 0, 0)), CardImagePosition.TopLeft, false, () => "", null, included => defs);
	msel.createDefaultItem = () => new CardImage(Talker.Selected);
	msel.valueFromDef = (defIndex, included, binPath) { mixin(S_TRACE);
		switch (defIndex) {
		case 0: return new CardImage(Talker.Selected);
		case 1: return new CardImage(Talker.Unselected);
		case 2: return new CardImage(Talker.Random);
		case 3: return new CardImage(Talker.Card);
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
			case Talker.Selected: return 0;
			case Talker.Unselected: return 1;
			case Talker.Random: return 2;
			case Talker.Card: return 3;
			case Talker.Valued: return -1; // 非対応
			}
		}
	};
	auto gd = new GridData(GridData.FILL_BOTH);
	msel.widget.setLayoutData(gd);
	msel.images = paths.length ? paths : [new CardImage(Talker.Selected)];

	void refImageScale() { mixin(S_TRACE);
		msel.setPreviewSize(prop.s(s.width), prop.s(s.height), prop.s(CInsets(0, 0, 0, 0)));
	}
	comm.refImageScale.add(&refImageScale);
	.listener(msel.widget, SWT.Dispose, { mixin(S_TRACE);
		comm.refImageScale.remove(&refImageScale);
	});

	return comp;
}

private FixedWidthText!Text createMessagePane(Commons comm, Props prop, bool image, Composite parent, Summary summ) { mixin(S_TRACE);
	int len = image ? prop.looks.messageImageLen : prop.looks.messageLen;
	auto r = new FixedWidthText!Text(prop.adjustFont(prop.looks.messageFont(comm.skin.legacy)), len, parent, SWT.BORDER, true);
	auto d = r.widget.getDisplay();
	auto normBack = r.widget.getBackground();
	auto normFore = r.widget.getForeground();
	auto back = new Color(d, new RGB(prop.var.etc.msgBackR, prop.var.etc.msgBackG, prop.var.etc.msgBackB));
	auto fore = new Color(d, new RGB(prop.var.etc.msgForeR, prop.var.etc.msgForeG, prop.var.etc.msgForeB));

	void updateMsgColor() { mixin(S_TRACE);
		if (prop.var.etc.useMessageWindowColorInTextContentDialog) { mixin(S_TRACE);
			r.widget.setBackground(back);
			r.widget.setForeground(fore);
		} else { mixin(S_TRACE);
			r.widget.setBackground(normBack);
			r.widget.setForeground(normFore);
		}
	}
	updateMsgColor();

	comm.refUseMessageWindowColorInTextContentDialog.add(&updateMsgColor);
	.listener(r.widget, SWT.Dispose, { mixin(S_TRACE);
		comm.refUseMessageWindowColorInTextContentDialog.remove(&updateMsgColor);
		back.dispose();
		fore.dispose();
	});
	return r;
}

private class PutC {
	private void delegate(string) _insert;
	private string delegate() _put;
	this(void delegate(string) insert, string put) { mixin(S_TRACE);
		_insert = insert;
		_put = () => put;
	}
	this(void delegate(string) insert, string delegate() put) { mixin(S_TRACE);
		_insert = insert;
		_put = put;
	}
	void put() { mixin(S_TRACE);
		_insert(_put());
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

private ToolBar createSCharBar(Commons comm, Summary summ, Composite parent,
		void delegate(string) insert, void delegate(dchar) putColor, Props prop, Skin skin) { mixin(S_TRACE);
	auto bar = new ToolBar(parent, SWT.FLAT);
	comm.put(bar);
	bar.addListener(SWT.Traverse, new class Listener {
		override void handleEvent(Event e) { e.doit = true; }
	});
	bar.addListener(SWT.KeyDown, new class Listener {
		override void handleEvent(Event e) { e.doit = true; }
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
	createToolItem2(comm, bar, prop.msgs.scTalkerName(Talker.Selected), prop.images.scTalker(Talker.Selected),
		&(new PutC(insert, "#M")).put, null);
	createToolItem2(comm, bar, prop.msgs.scTalkerName(Talker.Unselected), prop.images.scTalker(Talker.Unselected),
		&(new PutC(insert, "#U")).put, null);
	createToolItem2(comm, bar, prop.msgs.scTalkerName(Talker.Random), prop.images.scTalker(Talker.Random),
		&(new PutC(insert, "#R")).put, null);
	createToolItem2(comm, bar, prop.msgs.scTalkerName(Talker.Card), prop.images.scTalker(Talker.Card),
		&(new PutC(insert, "#C")).put, null);
	createToolItem2(comm, bar, prop.msgs.scTeam, prop.images.scTeam, &(new PutC(insert, "#T")).put, null);
	createToolItem2(comm, bar, prop.msgs.scYado, prop.images.scYado, &(new PutC(insert, "#Y")).put, null);
	new ToolItem(bar, SWT.SEPARATOR);
	createPCSPCharBar(comm, summ, bar, insert);
	return bar;
}

ToolBar createSimpleSCharBar(Composite parent,
		void delegate(string) insert, Commons comm, Props prop, Summary summ, Skin skin) { mixin(S_TRACE);
	auto bar = new ToolBar(parent, SWT.FLAT);
	comm.put(bar);
	bar.addListener(SWT.Traverse, new class Listener {
		override void handleEvent(Event e) { e.doit = true; }
	});
	bar.addListener(SWT.KeyDown, new class Listener {
		override void handleEvent(Event e) { e.doit = true; }
	});
	createToolItem2(comm, bar, prop.msgs.scTalkerName(Talker.Selected), prop.images.scTalker(Talker.Selected),
		&(new PutC(insert, "#M")).put, null);
	createToolItem2(comm, bar, prop.msgs.scTalkerName(Talker.Unselected), prop.images.scTalker(Talker.Unselected),
		&(new PutC(insert, "#U")).put, null);
	createToolItem2(comm, bar, prop.msgs.scTalkerName(Talker.Random), prop.images.scTalker(Talker.Random),
		&(new PutC(insert, "#R")).put, null);
	createToolItem2(comm, bar, prop.msgs.scTeam, prop.images.scTeam, &(new PutC(insert, "#T")).put, null);
	createToolItem2(comm, bar, prop.msgs.scYado, prop.images.scYado, &(new PutC(insert, "#Y")).put, null);
	new ToolItem(bar, SWT.SEPARATOR);
	createPCSPCharBar(comm, summ, bar, insert);
	return bar;
}

private void createPCSPCharBar(Commons comm, Summary summ, ToolBar bar, void delegate(string) insert) { mixin(S_TRACE);
	createToolItem2(comm, bar, comm.prop.msgs.selectedPlayerCardNumber, comm.prop.images.selectedPlayerCardNumber,
		&(new PutC(insert, "$" ~ comm.prop.sys.selectedPlayerCardNumber ~ "$")).put, () => comm.prop.isTargetVersion(summ, "2"));
	Spinner spn = null;
	auto t = createToolItem2(comm, bar, .tryFormat(comm.prop.msgs.playerCardName, comm.prop.var.etc.selectedPlayerCardName), comm.prop.images.playerCardName,
		&(new PutC(insert, () => "$" ~ comm.prop.sys.playerCardName(spn.getSelection()) ~ "$")).put,
		() => comm.prop.isTargetVersion(summ, "2"));
	spn = new Spinner(bar, SWT.BORDER);
	initSpinner(spn);
	spn.setMaximum(cast(int)comm.prop.looks.partyMax);
	spn.setMinimum(1);
	spn.setSelection(1);
	.setupSpinner(spn, comm.prop.var.etc.selectedPlayerCardName);
	.createToolItemC(bar, spn);
	void updatePCN() { mixin(S_TRACE);
		t.setToolTipText(.tryFormat(comm.prop.msgs.playerCardName, spn.getSelection));
	}
	.listener(spn, SWT.Selection, &updatePCN);
	.listener(spn, SWT.Modify, &updatePCN);
	comm.put(spn, () => comm.prop.isTargetVersion(summ, "2"));
}

private ToolBar createSkinSCharBar(Commons comm, Composite parent, void delegate(string) insert, Skin delegate() skin) { mixin(S_TRACE);
	auto bar = new ToolBar(parent, SWT.FLAT);
	comm.put(bar);
	bar.addListener(SWT.Traverse, new class Listener {
		override void handleEvent(Event e) { e.doit = true; }
	});
	bar.addListener(SWT.KeyDown, new class Listener {
		override void handleEvent(Event e) { e.doit = true; }
	});
	void updateBar() { mixin(S_TRACE);
		updateSkinSCharBar(comm, bar, insert, skin());
		parent.layout();
	}
	comm.refSkin.add(&updateBar);
	.listener(bar, SWT.Dispose, { mixin(S_TRACE);
		foreach (itm; bar.getItems()) { mixin(S_TRACE);
			itm.getImage().dispose();
		}
		comm.refSkin.remove(&updateBar);
	});
	updateBar();
	return bar;
}
private void updateSkinSCharBar(Commons comm, ToolBar bar, void delegate(string) insert, Skin skin) { mixin(S_TRACE);
	foreach (itm; bar.getItems()) { mixin(S_TRACE);
		itm.getImage().dispose();
		itm.dispose();
	}
	foreach (spc; std.algorithm.sort(skin.spChars.keys)) { mixin(S_TRACE);
		auto data = .spChar(skin, comm.prop.drawingScale, spc);
		if (!data.valid) continue;
		auto img = new Image(Display.getCurrent(), data.scaled(comm.prop.var.etc.imageScale));
		string name = toUTF8("#"d ~ spc);
		auto scp = new PutC(insert, name);
		createToolItem2(comm, bar, name, img, &scp.put, null);
	}
}

Composite createFlagStepBar(Composite parent, void delegate(string) insert, Commons comm, Props prop,
		Summary summ, UseCounter uc, Skin skin, bool imageFont, Button delegate(Composite, Combo, VariableType) createButton = null) { mixin(S_TRACE);
	auto bar = new Composite(parent, SWT.NONE);
	bar.setLayout(zeroMarginGridLayout((imageFont && summ) ? 2 : 1, false));
	Composite create(Composite parent, out Combo list, out Button put, string puts, Image image, string delegate(string) lc, int colNum, VariableType varType) { mixin(S_TRACE);
		auto comp = new Composite(parent, SWT.NONE);
		auto gl = windowGridLayout(colNum, false);
		gl.marginWidth = 0;
		gl.marginHeight = 0;
		comp.setLayout(gl);
		list = new Combo(comp, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
		list.setVisibleItemCount(prop.var.etc.comboVisibleItemCount);
		list.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		if (createButton) { mixin(S_TRACE);
			put = createButton(comp, list, varType);
		} else { mixin(S_TRACE);
			put = new Button(comp, SWT.PUSH);
			put.setToolTipText(puts);
			put.setImage(image);
			put.addSelectionListener(new class SelectionAdapter {
				override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
					insert(lc(list.getText()));
				}
			});
		}
		return comp;
	}

	Combo flags, steps, variants, fonts = null;
	Button putFlag, putStep, putVariant, putFont = null;
	IncSearch flagIncSearch, stepIncSearch, variantIncSearch, fontIncSearch = null;
	Button imgListBtn = null;
	auto varComp = new Composite(bar, SWT.NONE);
	varComp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
	varComp.setLayout(zeroMarginGridLayout(3, true));
	create(varComp, flags, putFlag, prop.msgs.addMsgRefFlag, prop.images.flag, (s) => "%" ~ s ~ "%", 2, VariableType.Flag).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
	create(varComp, steps, putStep, prop.msgs.addMsgRefStep, prop.images.step, (s) => "$" ~ s ~ "$", 2, VariableType.Step).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
	create(varComp, variants, putVariant, prop.msgs.addMsgRefVariant, prop.images.variant, (s) => "@" ~ s ~ "@", 2, VariableType.Variant).setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
	if (imageFont && summ) { mixin(S_TRACE);
		auto comp = create(bar, fonts, putFont, prop.msgs.addMsgRefImageFont, prop.images.imageFont, (s) => .tryFormat("#%s", .decodeFontPath(s)), 3, VariableType.init);
		auto fgd = new GridData(GridData.FILL_HORIZONTAL);
		auto gc = new GC(comp);
		scope (exit) gc.dispose();
		fgd.widthHint = gc.wTextExtent("font_##.bmp").x;
		fonts.setLayoutData(fgd);
		imgListBtn = new Button(comp, SWT.TOGGLE);
		imgListBtn.setImage(prop.images.menu(MenuID.LookImages));
		imgListBtn.setToolTipText(prop.msgs.menuText(MenuID.LookImages));
	}

	IncSearch createIncs(Combo combo, void delegate() refList, MenuID openMenu, void delegate() openDlg, bool delegate() enabled) { mixin(S_TRACE);
		auto incSearch = new IncSearch(comm, combo, enabled);
		incSearch.modEvent ~= refList;
		auto menu = new Menu(combo.getShell(), SWT.POP_UP);
		createMenuItem(comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
			.forceFocus(combo, true);
			incSearch.startIncSearch();
		}, enabled);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(comm, menu, MenuID.OpenAtVarView, openDlg, () => combo.getSelectionIndex() >= 0);
		combo.setMenu(menu);
		return incSearch;
	}

	void refListF() { mixin(S_TRACE);
		if (summ) { mixin(S_TRACE);
			auto root = summ.flagDirRoot;
			auto fSel = flags.getText();
			flags.removeAll();
			auto list = .allVars!(cwx.flag.Flag)(root, uc);
			size_t i = 0;
			.sortedWithPath(list, prop.var.etc.logicalSort, (cwx.flag.Flag flag) { mixin(S_TRACE);
				auto p = flag.path;
				if (!flagIncSearch.match(p)) return;
				flags.add(p);
				if (0 == i || p == fSel) flags.select(cast(int)i);
				i++;
			});
			flags.setEnabled(list.length > 0);
			putFlag.setEnabled(flags.getItemCount() > 0);
		} else { mixin(S_TRACE);
			flags.setEnabled(false);
			putFlag.setEnabled(false);
		}
	}
	void refListS() { mixin(S_TRACE);
		if (summ) { mixin(S_TRACE);
			auto root = summ.flagDirRoot;
			auto sSel = steps.getText();
			steps.removeAll();
			auto list = .allVars!Step(root, uc);
			size_t i = 0;
			.sortedWithPath(list, prop.var.etc.logicalSort, (Step step) { mixin(S_TRACE);
				auto p = step.path;
				if (!stepIncSearch.match(p)) return;
				steps.add(p);
				if (0 == i || p == sSel) steps.select(cast(int)i);
				i++;
			});
			steps.setEnabled(list.length > 0);
			putStep.setEnabled(steps.getItemCount() > 0);
		} else { mixin(S_TRACE);
			steps.setEnabled(false);
			putStep.setEnabled(false);
		}
	}
	void refListV() { mixin(S_TRACE);
		if (summ) { mixin(S_TRACE);
			auto root = summ.flagDirRoot;
			auto vSel = variants.getText();
			variants.removeAll();
			auto list = .allVars!(cwx.flag.Variant)(root, uc);
			size_t i = 0;
			.sortedWithPath(list, prop.var.etc.logicalSort, (cwx.flag.Variant variant) { mixin(S_TRACE);
				auto p = variant.path;
				if (!variantIncSearch.match(p)) return;
				variants.add(p);
				if (0 == i || p == vSel) variants.select(cast(int)i);
				i++;
			});
			variants.setEnabled(list.length > 0);
			putVariant.setEnabled(variants.getItemCount() > 0);
		} else { mixin(S_TRACE);
			variants.setEnabled(false);
			putVariant.setEnabled(false);
		}
	}

	flagIncSearch = createIncs(flags, &refListF, MenuID.OpenAtVarView, { mixin(S_TRACE);
		if (!summ) return;
		auto flag = .findVar!(cwx.flag.Flag)(summ ? summ.flagDirRoot : null, uc, flags.getText());
		if (!flag) return;
		try { mixin(S_TRACE);
			comm.openCWXPath(flag.cwxPath(true), false);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}, &flags.isEnabled);
	stepIncSearch = createIncs(steps, &refListS, MenuID.OpenAtVarView, { mixin(S_TRACE);
		if (!summ) return;
		auto step = .findVar!Step(summ ? summ.flagDirRoot : null, uc, steps.getText());
		if (!step) return;
		try { mixin(S_TRACE);
			comm.openCWXPath(step.cwxPath(true), false);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}, &steps.isEnabled);
	variantIncSearch = createIncs(variants, &refListV, MenuID.OpenAtVarView, { mixin(S_TRACE);
		if (!summ) return;
		auto variant = .findVar!(cwx.flag.Variant)(summ ? summ.flagDirRoot : null, uc, variants.getText());
		if (!variant) return;
		try { mixin(S_TRACE);
			comm.openCWXPath(variant.cwxPath(true), false);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}, &variants.isEnabled);

	refListF();
	refListS();
	refListV();

	void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps, cwx.flag.Variant[] variants) { mixin(S_TRACE);
		if (flags.length) refListF();
		if (steps.length) refListS();
		if (variants.length) refListV();
	}
	if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
		comm.refFlagAndStep.add(&refFlagAndStep);
		comm.delFlagAndStep.add(&refFlagAndStep);
		bar.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				comm.refFlagAndStep.remove(&refFlagAndStep);
				comm.delFlagAndStep.remove(&refFlagAndStep);
			}
		});
	}

	if (fonts) { mixin(S_TRACE);
		ImageListWindow!(MtType.CARD) imgListWin = null;
		void refListSPF() { mixin(S_TRACE);
			if (!summ) return;
			auto sel = fonts.getText();
			fonts.removeAll();
			auto sPath = summ.scenarioPath;
			size_t i = 0;
			bool has = false;
			foreach (file; .clistdir(sPath)) { mixin(S_TRACE);
				if (containsPath(prop.var.etc.ignorePaths, file)) continue;
				if (summ.isSystemFile(sPath.buildPath(file))) continue;
				auto u = to!dstring(file);
				if (file.isSPFontFile) { mixin(S_TRACE);
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
		}, &fonts.isEnabled);
		refListSPF();

		void refPath(string o, string n, bool isDir) { refListSPF(); }
		void refPaths(string parent) { refListSPF(); }
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			comm.refPath.add(&refPath);
			comm.refPaths.add(&refPaths);
			comm.delPaths.add(&refListSPF);
			comm.refSkin.add(&refListSPF);
		}
		comm.refIgnorePaths.add(&refListSPF);
		bar.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
					comm.refPath.remove(&refPath);
					comm.refPaths.remove(&refPaths);
					comm.delPaths.remove(&refListSPF);
					comm.refSkin.remove(&refListSPF);
				}
				comm.refIgnorePaths.remove(&refListSPF);
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
					createMenuItem(comm, menu, MenuID.IncSearch, () => fontIncSearch.startIncSearch(), &fonts.isEnabled);
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(comm, menu, MenuID.CloseWin, &imgListWin.close, null);
					imgListWin.widget.setMenu(menu);

					auto cloc = Display.getCurrent().getCursorLocation();
					cloc.x++;
					cloc.y++;
					auto p = imgListWin.shell.getSize();
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

private void putColor(Control ctrl, dchar put) { mixin(S_TRACE);
	assert (cast(Text)ctrl !is null);
	auto text = cast(Text)ctrl;
	auto sel = text.getSelection();
	auto a = text.getText().toUTF16()[0 .. sel.x].toUTF32();
	auto b = text.getText().toUTF16()[sel.x .. sel.y].toUTF32();
	auto c = text.getText().toUTF16()[sel.y .. $].toUTF32();
	auto old = toUTF32(text.getText());
	sel.x = cast(int)a.length;
	sel.y = cast(int)(a.length + b.length);
	auto newt = cwx.msgutils.putColor(old, put, sel.x, sel.y);
	text.setText(toUTF8(newt));
	int nSel = sel.y + (cast(int)newt.length - cast(int)old.length);
	nSel = cast(int)newt[0 .. nSel].toUTF16().length;
	text.setSelection(nSel);
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

	this (Shell parent, Commons comm, Props prop, Summary summ, UseCounter uc, Button toggle, WSize size) { mixin(S_TRACE);
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

		_preview = new MsgPreview(_win, comm, prop, summ, uc);
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
	bool isVisible() { return _win.isVisible(); }

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

	void text(CardImage[] imgPaths, string message, bool centerX, bool centerY, bool boundaryCheck) { mixin(S_TRACE);
		_preview.text(imgPaths, message, centerX, centerY, boundaryCheck);
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

immutable SPCHAR_TEXT_CLASSIC = [
	SPChar.M,
	SPChar.U,
	SPChar.R,
	SPChar.T,
	SPChar.Y,
];

immutable SPCHAR_TEXT = [
	SPChar.M,
	SPChar.U,
	SPChar.R,
	SPChar.C,
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
	private static class VariantData {
		cwx.flag.Variant variant;
		VariantVal val;
	}

	private static class PlayerCardName {
		uint number;
		this (uint number) { this.number = number; }
	}
	private static Object SELECTED_PLAYER_NUMBER;
	static this () {
		SELECTED_PLAYER_NUMBER = new Object;
	}

	private Commons _comm;
	private Props _prop;
	private Summary _summ;
	private UseCounter _uc;

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
		private VariantVal[string] _variants;
		private uint _selectedPlayerCardNumber;
		private string[] _playerCardName;
		this () { mixin(S_TRACE);
			getValues2(_names, _flags, _steps, _variants, _selectedPlayerCardNumber, _playerCardName);
		}
		private void impl() { mixin(S_TRACE);
			string[char] names;
			bool[string] flags;
			int[string] steps;
			VariantVal[string] variants;
			uint selectedPlayerCardNumber;
			string[] playerCardName;
			getValues2(names, flags, steps, variants, selectedPlayerCardNumber, playerCardName);
			setValues2(_names, _flags, _steps, _variants, _selectedPlayerCardNumber, _playerCardName);
			_names = names;
			_flags = flags;
			_steps = steps;
			_variants = variants;
			_selectedPlayerCardNumber = selectedPlayerCardNumber;
			_playerCardName = playerCardName;
			raiseModEvent();
			savePreviewValues();
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
			if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
				_comm.refFlagAndStep.remove(&refFlagAndStep);
				_comm.delFlagAndStep.remove(&refFlagAndStep);
			}
			_comm.refDataVersion.remove(&refDataVersion);
			savePreviewValues();
		}
	}

	private void savePreviewValues() { mixin(S_TRACE);
		if (SPChar.M in _indexTable) _prop.var.etc.messageVarSelected = _values.getItem(_indexTable[SPChar.M]).getText(1);
		if (SPChar.U in _indexTable) _prop.var.etc.messageVarUnselected = _values.getItem(_indexTable[SPChar.U]).getText(1);
		if (SPChar.R in _indexTable) _prop.var.etc.messageVarRandom = _values.getItem(_indexTable[SPChar.R]).getText(1);
		if (SPChar.C in _indexTable) _prop.var.etc.messageVarCard = _values.getItem(_indexTable[SPChar.C]).getText(1);
		if (SPChar.I in _indexTable) _prop.var.etc.messageVarRef = _values.getItem(_indexTable[SPChar.I]).getText(1);
		if (SPChar.T in _indexTable) _prop.var.etc.messageVarTeam = _values.getItem(_indexTable[SPChar.T]).getText(1);
		if (SPChar.Y in _indexTable) _prop.var.etc.messageVarYado = _values.getItem(_indexTable[SPChar.Y]).getText(1);

		string[] playerCardName = [];
		foreach (itm; _values.getItems()) { mixin(S_TRACE);
			auto o = itm.getData();
			if (o is SELECTED_PLAYER_NUMBER) { mixin(S_TRACE);
				_prop.var.etc.messageVarSelectedPlayerCardNumber = .to!uint(itm.getText(1));
			} else if (auto pcn = cast(PlayerCardName)o) { mixin(S_TRACE);
				playerCardName ~= itm.getText(1);
			}
		}
		if (playerCardName.length) { mixin(S_TRACE);
			_prop.var.etc.messageVarPlayerCardName = playerCardName;
		}

		if (_isMessage) { mixin(S_TRACE);
			_prop.var.etc.messageVarKindColumn = _values.getColumn(0).getWidth();
			_prop.var.etc.messageVarValueColumn = _values.getColumn(1).getWidth();
		} else { mixin(S_TRACE);
			_prop.var.etc.textVarKindColumn = _values.getColumn(0).getWidth();
			_prop.var.etc.textVarValueColumn = _values.getColumn(1).getWidth();
		}
		_comm.refPreviewValues.call();
	}

	private class Mod : ModifyListener {
		private TableItem _itm;
		this (TableItem itm) { mixin(S_TRACE);
			_itm = itm;
		}
		private void mod(Control ctrl) { mixin(S_TRACE);
			if (!_changedText) { mixin(S_TRACE);
				store();
				_changedText = true;
			}
			string text = ctrlText(ctrl);
			auto old = _itm.getText(1);

			auto o = _itm.getData();
			if (auto vd = cast(VariantData)o) { mixin(S_TRACE);
				auto val = .variantValueFromText(text);
				if (val.valid) { mixin(S_TRACE);
					_itm.setText(1, .variantValueToText(val));
				} else { mixin(S_TRACE);
					_itm.setText(1, .variantValueToText(vd.val));
				}
			} else { mixin(S_TRACE);
				_itm.setText(1, text);
			}
			if (old != _itm.getText(1)) { mixin(S_TRACE);
				raiseModEvent();
				savePreviewValues();
			}
		}
		override void modifyText(ModifyEvent e) { mixin(S_TRACE);
			mod(cast(Control)e.widget);
		}
	}

	private void refreshFlags() { mixin(S_TRACE);
		int[string] pvs;
		VariantVal[string] pvvs;
		bool[string] selPaths;

		if (_targetChars.length < _values.getItemCount()) { mixin(S_TRACE);
			foreach (i; _targetChars.length .. _values.getItemCount()) { mixin(S_TRACE);
				auto itm = _values.getItem(cast(int)i);
				string key;
				auto o = itm.getData();
				if (auto f = cast(FlagData)o) { mixin(S_TRACE);
					pvs[key] = f.onOff ? 1 : 0;
					key = .toLower(itm.getText(0));
				} else if (auto s = cast(StepData)o) { mixin(S_TRACE);
					pvs[key] = s.select;
					key = .toLower(itm.getText(0));
				} else if (auto v = cast(VariantData)o) { mixin(S_TRACE);
					pvvs[key] = v.val;
					key = .toLower(itm.getText(0));
				} else if (o is SELECTED_PLAYER_NUMBER) { mixin(S_TRACE);
					key = _prop.sys.selectedPlayerCardNumber;
				} else if (auto pcn = cast(PlayerCardName)o) { mixin(S_TRACE);
					key = _prop.sys.playerCardName(pcn.number);
				} else assert (0);

				if (_values.isSelected(cast(int)i)) { mixin(S_TRACE);
					selPaths[key] = true;
				}
			}
			_values.remove(cast(int)_targetChars.length, _values.getItemCount() - 1);
		}
		if (_prop.isTargetVersion(_summ, "2")) { mixin(S_TRACE);
			// 選択メンバ番号(Wsn.2)
			{ mixin(S_TRACE);
				auto itm = new TableItem(_values, SWT.NONE);
				itm.setImage(0, _prop.images.selectedPlayerCardNumber);
				itm.setText(0, _prop.msgs.selectedPlayerCardNumber);
				itm.setText(1, .text(_prop.var.etc.messageVarSelectedPlayerCardNumber));
				itm.setData(SELECTED_PLAYER_NUMBER);
			}
			// パーティメンバ名(Wsn.2)
			foreach (pcn; 1 .. _prop.looks.partyMax + 1) { mixin(S_TRACE);
				auto itm = new TableItem(_values, SWT.NONE);
				itm.setImage(0, _prop.images.playerCardName);
				itm.setText(0, .tryFormat(_prop.msgs.playerCardName, pcn));
				string val;
				if (pcn - 1 < _prop.var.etc.messageVarPlayerCardName.length) { mixin(S_TRACE);
					val = _prop.var.etc.messageVarPlayerCardName[pcn - 1];
				} else { mixin(S_TRACE);
					val = .parseDollarParams(_prop.var.etc.messageVarPlayerCardNameDefault, ['N':.text(pcn)]);
				}
				itm.setText(1, val);
				itm.setData(new PlayerCardName(cast(uint)pcn));
			}
		}
		if (_summ) { mixin(S_TRACE);
			.sortedWithPath(.allVars!(cwx.flag.Variant)(_summ.flagDirRoot, _uc), _prop.var.etc.logicalSort, (cwx.flag.Variant f) { mixin(S_TRACE);
				auto itm = new TableItem(_values, SWT.NONE);
				auto path = f.path;
				itm.setImage(0, _prop.images.variant);
				itm.setText(0, path);
				itm.setText(1, .variantValueToText(f));
				auto d = new VariantData;
				itm.setData(d);
				d.variant = f;
				d.val = VariantVal(f);
				string lpath = .toLower(path);
				auto p = lpath in pvvs;
				if (p) { mixin(S_TRACE);
					itm.setText(1, variantValueToText(*p));
					d.val = *p;
				}
				if (lpath in selPaths) { mixin(S_TRACE);
					_values.select(_values.getItemCount() - 1);
				}
			});
			.sortedWithPath(.allVars!Step(_summ.flagDirRoot, _uc), _prop.var.etc.logicalSort, (Step f) { mixin(S_TRACE);
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
				if (lpath in selPaths) { mixin(S_TRACE);
					_values.select(_values.getItemCount() - 1);
				}
			});
			.sortedWithPath(.allVars!(cwx.flag.Flag)(_summ.flagDirRoot, _uc), _prop.var.etc.logicalSort, (cwx.flag.Flag f) { mixin(S_TRACE);
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
				if (lpath in selPaths) { mixin(S_TRACE);
					_values.select(_values.getItemCount() - 1);
				}
			});
		}
	}
	private void refFlagAndStep(cwx.flag.Flag[] flags, Step[] steps, cwx.flag.Variant[] variants) { mixin(S_TRACE);
		_undo.reset();
		_values.setRedraw(false);
		scope (exit) _values.setRedraw(true);
		int topIndex = _values.getTopIndex();
		scope (exit) {
			if (_values.getItemCount() <= topIndex) {
				topIndex = _values.getItemCount() - 1;
			}
			_values.setTopIndex(topIndex);
		}
		refreshFlags();
		raiseModEvent();
	}
	private void refDataVersion() { mixin(S_TRACE);
		_undo.reset();
		_values.setRedraw(false);
		scope (exit) _values.setRedraw(true);
		int topIndex = _values.getTopIndex();
		scope (exit) {
			if (_values.getItemCount() <= topIndex) {
				topIndex = _values.getItemCount() - 1;
			}
			_values.setTopIndex(topIndex);
		}
		_targetChars = _isMessage ? SPCHAR_ALL : (!_summ || !_summ.legacy ? SPCHAR_TEXT : SPCHAR_TEXT_CLASSIC);
		_values.removeAll();
		foreach (i; _targetChars) { mixin(S_TRACE);
			_indexTable[cast(SPChar)i] = _values.getItemCount();
			auto itm = new TableItem(_values, SWT.NONE);
			final switch (cast(SPChar)i) {
			case SPChar.M:
				itm.setImage(0, _prop.images.scTalker(Talker.Selected));
				itm.setText(0, _prop.msgs.scTalkerName(Talker.Selected));
				itm.setText(1, _prop.var.etc.messageVarSelected);
				break;
			case SPChar.U:
				itm.setImage(0, _prop.images.scTalker(Talker.Unselected));
				itm.setText(0, _prop.msgs.scTalkerName(Talker.Unselected));
				itm.setText(1, _prop.var.etc.messageVarUnselected);
				break;
			case SPChar.R:
				itm.setImage(0, _prop.images.scTalker(Talker.Random));
				itm.setText(0, _prop.msgs.scTalkerName(Talker.Random));
				itm.setText(1, _prop.var.etc.messageVarRandom);
				break;
			case SPChar.C:
				itm.setImage(0, _prop.images.scTalker(Talker.Card));
				itm.setText(0, _prop.msgs.scTalkerName(Talker.Card));
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
		raiseModEvent();
	}
	private Control createEditor(TableItem itm, int editC) { mixin(S_TRACE);
		_changedText = false;
		auto o = itm.getData();
		if (auto fd = cast(FlagData)o) { mixin(S_TRACE);
			auto text = createComboEditor!Combo(_comm, _prop, itm.getParent(), [fd.flag.on, fd.flag.off], itm.getText(1));
			text.addModifyListener(new Mod(itm));
			return text;
		}
		if (auto sd = cast(StepData)o) { mixin(S_TRACE);
			auto text = createComboEditor!Combo(_comm, _prop, itm.getParent(), sd.step.values, itm.getText(1));
			text.addModifyListener(new Mod(itm));
			return text;
		}
		if (auto vd = cast(VariantData)o) { mixin(S_TRACE);
			auto text = .variantValueEditor(_comm, itm.getParent(), itm.getText(1));
			text.addModifyListener(new Mod(itm));
			return text;
		}
		if (o is SELECTED_PLAYER_NUMBER) { mixin(S_TRACE);
			auto spn = new Spinner(itm.getParent(), SWT.BORDER);
			initSpinner(spn);
			spn.setMaximum(cast(int)_prop.looks.partyMax);
			spn.setMinimum(0);
			spn.setSelection(.to!uint(itm.getText(1)));
			spn.addModifyListener(new Mod(itm));
			return spn;
		}
		auto combo = createTextEditor(_comm, _prop, itm.getParent(), itm.getText(1));
		combo.addModifyListener(new Mod(itm));
		return combo;
	}
	private static string ctrlText(Control ctrl) { mixin(S_TRACE);
		auto text = cast(Text)ctrl;
		if (text) return text.getText();
		auto stext = cast(StyledText)ctrl;
		if (stext) return stext.getText();
		auto combo = cast(Combo)ctrl;
		if (combo) return combo.getText();
		auto spn = cast(Spinner)ctrl;
		if (spn) return .text(spn.getSelection());
		assert (0);
	}
	private void editEnd(TableItem itm, int column, Control ctrl) { mixin(S_TRACE);
		auto old = itm.getText(column);
		void putText(string text) { mixin(S_TRACE);
			auto o = itm.getData();
			if (auto vd = cast(VariantData)o) { mixin(S_TRACE);
				auto val = .variantValueFromText(text);
				if (val.valid) { mixin(S_TRACE);
					vd.val = val;
					itm.setText(column, .variantValueToText(val));
				} else { mixin(S_TRACE);
					itm.setText(column, .variantValueToText(vd.val));
				}
			} else { mixin(S_TRACE);
				itm.setText(column, text);
			}
		}
		if (auto text = cast(Text)ctrl) { mixin(S_TRACE);
			putText(text.getText());
		} else if (auto text = cast(StyledText)ctrl) { mixin(S_TRACE);
			putText(text.getText());
		} else if (auto combo = cast(Combo)ctrl) { mixin(S_TRACE);
			itm.setText(column, combo.getText());
			auto o = itm.getData();
			if (auto fd = cast(FlagData)o) fd.onOff = combo.getSelectionIndex() == 0;
			if (auto sd = cast(StepData)o) sd.select = combo.getSelectionIndex();
		} else if (auto spn = cast(Spinner)ctrl) { mixin(S_TRACE);
			itm.setText(column, .text(spn.getSelection()));
		} else assert (0);
		if (old != itm.getText()) { mixin(S_TRACE);
			raiseModEvent();
			savePreviewValues();
		}
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
		int i = 0;
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
		if (i < _values.getItemCount() && _values.getItem(i).getData() is SELECTED_PLAYER_NUMBER) { mixin(S_TRACE);
			if (i in set) { mixin(S_TRACE);
				_values.getItem(i).setText(1, .text(_prop.var.etc.messageVarSelectedPlayerCardNumber.INIT));
			}
			i++;
		}
		while (i < _values.getItemCount()) { mixin(S_TRACE);
			auto itm = _values.getItem(i);
			if (auto pcnObj = cast(PlayerCardName)itm.getData()) { mixin(S_TRACE);
				if (i in set) { mixin(S_TRACE);
					auto pcn = pcnObj.number;
					if (pcn - 1 < _prop.var.etc.messageVarPlayerCardName.INIT.length) { mixin(S_TRACE);
						itm.setText(1, _prop.var.etc.messageVarPlayerCardName.INIT[pcn - 1]);
					} else { mixin(S_TRACE);
						itm.setText(1, .parseDollarParams(_prop.var.etc.messageVarPlayerCardNameDefault, ['N':.text(pcn)]));
					}
				}
				i++;
			} else { mixin(S_TRACE);
				break;
			}
		}
		if (_summ) { mixin(S_TRACE);
			.sortedWithPath(.allVars!(cwx.flag.Variant)(_summ.flagDirRoot, _uc), _prop.var.etc.logicalSort, (cwx.flag.Variant f) { mixin(S_TRACE);
				if (i in set) { mixin(S_TRACE);
					auto itm = _values.getItem(i);
					itm.setText(1, .variantValueToText(f));
					auto data = cast(VariantData)itm.getData();
					data.val = VariantVal(f);
				}
				i++;
			});
			.sortedWithPath(.allVars!Step(_summ.flagDirRoot, _uc), _prop.var.etc.logicalSort, (Step f) { mixin(S_TRACE);
				if (i in set) { mixin(S_TRACE);
					auto itm = _values.getItem(i);
					itm.setText(1, f.values[f.select]);
					auto data = cast(StepData)itm.getData();
					data.select = f.select;
				}
				i++;
			});
			.sortedWithPath(.allVars!(cwx.flag.Flag)(_summ.flagDirRoot, _uc), _prop.var.etc.logicalSort, (cwx.flag.Flag f) { mixin(S_TRACE);
				if (i in set) { mixin(S_TRACE);
					auto itm = _values.getItem(i);
					itm.setText(1, f.onOff ? f.on : f.off);
					auto data = cast(FlagData)itm.getData();
					data.onOff = f.onOff;
				}
				i++;
			});
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
		int i = 0;
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
		if (i < _values.getItemCount() && _values.getItem(i).getData() is SELECTED_PLAYER_NUMBER) { mixin(S_TRACE);
			if (i in set) { mixin(S_TRACE);
				if (_values.getItem(i).getText(1) != .text(_prop.var.etc.messageVarSelectedPlayerCardNumber.INIT)) return false;
			}
			i++;
		}
		while (i < _values.getItemCount()) { mixin(S_TRACE);
			auto itm = _values.getItem(i);
			if (auto pcnObj = cast(PlayerCardName)itm.getData()) { mixin(S_TRACE);
				if (i in set) { mixin(S_TRACE);
					auto pcn = pcnObj.number;
					string s;
					if (pcn - 1 < _prop.var.etc.messageVarPlayerCardName.INIT.length) { mixin(S_TRACE);
						s = _prop.var.etc.messageVarPlayerCardName.INIT[pcn - 1];
					} else { mixin(S_TRACE);
						s = .parseDollarParams(_prop.var.etc.messageVarPlayerCardNameDefault, ['N':.text(pcn)]);
					}
					if (itm.getText(1) != s) return false;
				}
				i++;
			} else { mixin(S_TRACE);
				break;
			}
		}
		if (_summ) { mixin(S_TRACE);
			cwx.flag.Variant[] vs;
			.sortedWithPath(.allVars!(cwx.flag.Variant)(_summ.flagDirRoot, _uc), _prop.var.etc.logicalSort, (cwx.flag.Variant v) { vs ~= v; });
			foreach (f; vs) { mixin(S_TRACE);
				if (i in set) { mixin(S_TRACE);
					auto itm = _values.getItem(i);
					auto data = cast(VariantData)itm.getData();
					if (data.val != VariantVal(f)) return false;
				}
				i++;
			}
			Step[] ss;
			.sortedWithPath(.allVars!Step(_summ.flagDirRoot, _uc), _prop.var.etc.logicalSort, (Step s) { ss ~= s; });
			foreach (f; ss) { mixin(S_TRACE);
				if (i in set) { mixin(S_TRACE);
					auto itm = _values.getItem(i);
					auto data = cast(StepData)itm.getData();
					if (data.select != f.select) return false;
				}
				i++;
			}
			cwx.flag.Flag[] fs;
			.sortedWithPath(.allVars!(cwx.flag.Flag)(_summ.flagDirRoot, _uc), _prop.var.etc.logicalSort, (cwx.flag.Flag f) { fs ~= f; });
			foreach (f; fs) { mixin(S_TRACE);
				if (i in set) { mixin(S_TRACE);
					auto itm = _values.getItem(i);
					auto data = cast(FlagData)itm.getData();
					if (data.onOff != f.onOff) return false;
				}
				i++;
			}
		}
		return true;
	}

	class ValuesTCPD : TCPD {
		void cut(SelectionEvent e) { assert (0); };
		void copy(SelectionEvent e) { mixin(S_TRACE);
			auto indices = _values.getSelectionIndices();
			std.algorithm.sort(indices);
			if (!indices.length) return;
			string text;
			foreach (sel; indices[0] .. indices[$ - 1] + 1) { mixin(S_TRACE);
				auto itm = _values.getItem(sel);
				auto fd = cast(FlagData)itm.getData();
				auto sd = cast(StepData)itm.getData();
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
			auto indices = _values.getSelectionIndices();
			std.algorithm.sort(indices);
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
				auto fd = cast(FlagData)itm.getData();
				auto sd = cast(StepData)itm.getData();
				auto vd = cast(VariantData)itm.getData();
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
					} else if (vd) { mixin(S_TRACE);
						auto val = .variantValueFromText(line);
						if (val.valid) { mixin(S_TRACE);
							vd.val = val;
							itm.setText(1, .variantValueToText(val));
						}
					} else if (itm.getData() is SELECTED_PLAYER_NUMBER) { mixin(S_TRACE);
						uint value;
						try { mixin(S_TRACE);
							value = .to!(uint)(line);
							if (_prop.looks.partyMax < value) value = cast(uint)_prop.looks.partyMax;
						} catch (Exception) { mixin(S_TRACE);
							value = 0;
						}
						itm.setText(1, .text(value));
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

	this (Composite parent, Commons comm, Props prop, Summary summ, UseCounter uc, bool message) { mixin(S_TRACE);
		super (parent, SWT.NONE);

		_undo = new UndoManager(prop.var.etc.undoMaxEtc);
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_uc = uc;
		_isMessage = message;
		_targetChars = message ? SPCHAR_ALL : (!summ || !summ.legacy ? SPCHAR_TEXT : SPCHAR_TEXT_CLASSIC);

		this.setLayout(zeroGridLayout(1, true));

		_values = .rangeSelectableTable(this, SWT.BORDER | SWT.FULL_SELECTION | SWT.MULTI);
		auto vgd = new GridData(GridData.FILL_BOTH);
		vgd.heightHint = _prop.var.etc.messageVarTableHeight;
		_values.setLayoutData(vgd);
		_values.addDisposeListener(new Dispose);
		_values.setHeaderVisible(true);

		auto menu = new Menu(_values);
		createMenuItem(comm, menu, MenuID.Undo, { _undo.undo(); }, &_undo.canUndo);
		createMenuItem(comm, menu, MenuID.Redo, { _undo.redo(); }, &_undo.canRedo);
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(comm, menu, MenuID.ResetValues, &resetValues, () => !isInitialValues());
		createMenuItem(comm, menu, MenuID.ResetValuesAll, &resetValuesAll, () => !isInitialValuesAll());
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

		refDataVersion();
		_comm.refUndoMax.add(&refUndoMax);
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			_comm.refFlagAndStep.add(&refFlagAndStep);
			_comm.delFlagAndStep.add(&refFlagAndStep);
		}
		_comm.refDataVersion.add(&refDataVersion);

		new TableTCEdit(_comm, _values, 1, &createEditor, &editEnd, null);
	}

	void getValues(out string[char] names, out VarValue[string] flags, out VarValue[string] steps,
			out VarValue[string] variants, out VarValue[string] sysSteps) { mixin(S_TRACE);
		foreach (i; _targetChars) { mixin(S_TRACE);
			names[C_TBL[cast(SPChar)i]] = _values.getItem(_indexTable[cast(SPChar)i]).getText(1);
		}
		foreach (i; _targetChars.length .. _values.getItemCount()) { mixin(S_TRACE);
			auto itm = _values.getItem(cast(int)i);
			auto o = itm.getData();
			if (auto fd = cast(FlagData)o) { mixin(S_TRACE);
				flags[itm.getText(0)] = VarValue(true, itm.getText(1), fd.flag.expandSPChars);
			} else if (auto sd = cast(StepData)o) { mixin(S_TRACE);
				steps[itm.getText(0)] = VarValue(true, itm.getText(1), sd.step.expandSPChars);
			} else if (auto vd = cast(VariantData)o) { mixin(S_TRACE);
				auto val = .variantValueFromText(itm.getText(1));
				if (val.valid) { mixin(S_TRACE);
					variants[itm.getText(0)] = VarValue(true, .variantValueToPreviewText(val), false);
				} else { mixin(S_TRACE);
					variants[itm.getText(0)] = VarValue(true, .variantValueToPreviewText(vd.val), false);
				}
			} else if (o is SELECTED_PLAYER_NUMBER) { mixin(S_TRACE);
				sysSteps[_prop.sys.selectedPlayerCardNumber.toLower()] = VarValue(true, itm.getText(1), false);
			} else if (auto pcnObj = cast(PlayerCardName)o) { mixin(S_TRACE);
				sysSteps[_prop.sys.playerCardName(pcnObj.number).toLower()] = VarValue(true, itm.getText(1), false);
			} else assert (0);
		}
	}
	private void getValues2(out string[char] names, out bool[string] flags, out int[string] steps, out VariantVal[string] variants,
			out uint selectedPlayerCardNumber, out string[] playerCardName) { mixin(S_TRACE);
		foreach (i; _targetChars) { mixin(S_TRACE);
			names[C_TBL[cast(SPChar)i]] = _values.getItem(_indexTable[cast(SPChar)i]).getText(1);
		}
		foreach (i; _targetChars.length .. _values.getItemCount()) { mixin(S_TRACE);
			auto itm = _values.getItem(cast(int)i);
			auto o = itm.getData();
			if (auto fd = cast(FlagData)o) { mixin(S_TRACE);
				flags[itm.getText(0)] = fd.onOff;
			} else if (auto sd = cast(StepData)o) { mixin(S_TRACE);
				steps[itm.getText(0)] = sd.select;
			} else if (auto vd = cast(VariantData)o) { mixin(S_TRACE);
				variants[itm.getText(0)] = vd.val;
			} else if (o is SELECTED_PLAYER_NUMBER) { mixin(S_TRACE);
				selectedPlayerCardNumber = .to!uint(itm.getText(1));
			} else if (auto pcnObj = cast(PlayerCardName)o) { mixin(S_TRACE);
				playerCardName ~= itm.getText(1);
			} else assert (0);
		}
	}
	private void setValues2(in string[char] names, in bool[string] flags, in int[string] steps, in VariantVal[string] variants,
			uint selectedPlayerCardNumber, in string[] playerCardName) { mixin(S_TRACE);
		foreach (i; _targetChars) { mixin(S_TRACE);
			_values.getItem(_indexTable[cast(SPChar)i]).setText(1, names[C_TBL[cast(SPChar)i]]);
		}
		size_t pcni = 0;
		foreach (i; _targetChars.length .. _values.getItemCount()) { mixin(S_TRACE);
			auto itm = _values.getItem(cast(int)i);
			auto o = itm.getData();
			if (auto fd = cast(FlagData)o) { mixin(S_TRACE);
				auto p = itm.getText(0) in flags;
				if (p) { mixin(S_TRACE);
					fd.onOff = *p;
					itm.setText(1, fd.onOff ? fd.flag.on : fd.flag.off);
				}
			} else if (auto sd = cast(StepData)o) { mixin(S_TRACE);
				assert (sd !is null);
				auto p = itm.getText(0) in steps;
				if (p && 0 <= *p && *p < sd.step.values.length) { mixin(S_TRACE);
					sd.select = *p;
					itm.setText(1, sd.step.values[sd.select]);
				}
			} else if (auto vd = cast(VariantData)o) { mixin(S_TRACE);
				assert (vd !is null);
				auto p = itm.getText(0) in variants;
				if (p) { mixin(S_TRACE);
					vd.val = *p;
					itm.setText(1, .variantValueToText(*p));
				}
			} else if (o is SELECTED_PLAYER_NUMBER) { mixin(S_TRACE);
				itm.setText(1, .text(selectedPlayerCardNumber));
			} else if (auto pcnObj = cast(PlayerCardName)o) { mixin(S_TRACE);
				itm.setText(1, playerCardName[pcni]);
				pcni++;
			} else assert (0);
		}
	}

	@property
	bool focusInValues() { mixin(S_TRACE);
		return _values.isFocusControl();
	}
	bool undo() { return _undo.undo(); }
	bool redo() { return _undo.redo(); }
}

Text variantValueEditor(Commons comm, Composite parent, string value) { mixin(S_TRACE);
	auto t = .createTextEditor(comm, comm.prop, parent, value);
	t.setToolTipText(comm.prop.msgs.variantValueHint);
	.listener(t, SWT.Modify, { mixin(S_TRACE);
		auto hint = "";
		if (.variantValueFromText(t.getText()).valid) { mixin(S_TRACE);
			hint = comm.prop.msgs.variantValueHint;
		} else { mixin(S_TRACE);
			hint = .tryFormat(comm.prop.msgs.warningInvalidVariantValue, comm.prop.msgs.variantValueHint);
		}
		if (t.getToolTipText() != hint) t.setToolTipText(hint);
	});
	return t;
}

void getPreviewValues(in Props prop, Summary summ, UseCounter uc, in SPChar[] targetChars,
		out string[char] names, out VarValue[string] flags, out VarValue[string] steps,
		out VarValue[string] variants, out VarValue[string] sysSteps) { mixin(S_TRACE);
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
		.sortedWithPath(.allVars!(cwx.flag.Flag)(summ.flagDirRoot, uc), prop.var.etc.logicalSort, (cwx.flag.Flag f) { mixin(S_TRACE);
			flags[f.path] = VarValue(true, f.onOff ? f.on : f.off, f.expandSPChars);
		});
		.sortedWithPath(.allVars!Step(summ.flagDirRoot, uc), prop.var.etc.logicalSort, (Step f) { mixin(S_TRACE);
			steps[f.path] = VarValue(true, f.value, f.expandSPChars);
		});
		.sortedWithPath(.allVars!(cwx.flag.Variant)(summ.flagDirRoot, uc), prop.var.etc.logicalSort, (cwx.flag.Variant f) { mixin(S_TRACE);
			variants[f.path] = VarValue(true, .variantValueToPreviewText(f), false);
		});
	}
	.getPreviewSysSteps(prop, summ, true, sysSteps);
}

void getPreviewSysSteps(in Props prop, in Summary summ, bool expandSharps, out VarValue[string] sysSteps) { mixin(S_TRACE);
	if (prop.isTargetVersion(summ, "2")) { mixin(S_TRACE);
		if (expandSharps) { mixin(S_TRACE);
			// 選択メンバ番号(Wsn.2)
			sysSteps[prop.sys.selectedPlayerCardNumber.toLower()] = VarValue(true, .text(prop.var.etc.messageVarSelectedPlayerCardNumber), false);
		}
		// パーティメンバ名(Wsn.2)
		foreach (pcn; 1 .. prop.looks.partyMax + 1) { mixin(S_TRACE);
			auto name = prop.sys.playerCardName(cast(uint)pcn).toLower();
			if (pcn - 1 < prop.var.etc.messageVarPlayerCardName.length) { mixin(S_TRACE);
				sysSteps[name] = VarValue(true, prop.var.etc.messageVarPlayerCardName[pcn - 1], false);
			} else { mixin(S_TRACE);
				sysSteps[name] = VarValue(true, .parseDollarParams(prop.var.etc.messageVarPlayerCardNameDefault, ['N':.text(pcn)]), false);
			}
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
	private bool _centerX = false;
	private bool _centerY = false;
	private bool _boundaryCheck = false;

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
			if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
				_comm.refSkin.remove(&refresh);
			}
			_comm.refImageScale.remove(&refImageScale);
		}
	}

	this (Composite parent, Commons comm, Props prop, Summary summ, UseCounter uc) { mixin(S_TRACE);
		super (parent, SWT.NONE);

		_comm = comm;
		_prop = prop;
		_summ = summ;

		this.setLayout(zeroGridLayout(1, true));

		_canvas = new Canvas(this, SWT.DOUBLE_BUFFERED);
		refImageScaleImpl();
		_canvas.addPaintListener(new Paint);
		_canvas.addDisposeListener(new Dispose);

		_values = new PreviewValues(this, comm, prop, summ, uc, true);
		auto vgd = new GridData(GridData.FILL_BOTH);
		vgd.heightHint = _prop.var.etc.messageVarTableHeight;
		_values.setLayoutData(vgd);
		_values.modEvent ~= &refresh;
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			_comm.refSkin.add(&refresh);
		}
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

	void text(CardImage[] imgPaths, string message, bool centerX, bool centerY, bool boundaryCheck) { mixin(S_TRACE);
		if (imgPaths == _imgPaths && message == _message && centerX is _centerX && centerY is _centerY && boundaryCheck is _boundaryCheck) { mixin(S_TRACE);
			return;
		}
		_imgPaths = imgPaths;
		_message = message;
		_centerX = centerX;
		_centerY = centerY;
		_boundaryCheck = boundaryCheck;
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
		ImageDataWithScale[] tImg = [];
		CardImagePosition[] pos = [];
		foreach (imgPath; _imgPaths) { mixin(S_TRACE);
			final switch (imgPath.type) {
			case CardImageType.File:
				auto isSkinMaterial = false;
				auto isEngineMaterial = false;
				auto path = _comm.skin.findImagePathF(imgPath.path, _summ ? _summ.scenarioPath : "", _summ ? _summ.dataVersion : LATEST_VERSION,
					isSkinMaterial, isEngineMaterial);
				auto drawingScale = (isSkinMaterial || isEngineMaterial) ? _prop.drawingScale : _prop.drawingScaleForImage(_summ);
				tImg ~= .loadImageWithScale(path, drawingScale, true, false);
				pos ~= imgPath.positionType;
				break;
			case CardImageType.PCNumber:
				// Invalid data.
				break;
			case CardImageType.Talker:
				final switch (imgPath.talker) {
				case Talker.Selected:
				case Talker.Unselected:
				case Talker.Random:
				case Talker.Valued:
					tImg ~= new ImageDataWithScale(_prop.images.talker(imgPath.talker).getImageData(), .dpiMuls);
					pos ~= CardImagePosition.Default;
					break;
				case Talker.Card:
					auto cRect = _prop.looks.cardSize;
					auto imgData = .menuCard(_comm.skin, _comm.prop.drawingScale);
					auto data = imgData.scaled(_comm.prop.drawingScale).scaledTo(_comm.prop.ds(cRect.width), _comm.prop.ds(cRect.height));
					tImg ~= new ImageDataWithScale(data, _comm.prop.drawingScale);
					pos ~= CardImagePosition.Default;
					break;
				}
				break;
			}
		}

		string[char] names;
		VarValue[string] flags, steps, variants, sysSteps;
		_values.getValues(names, flags, steps, variants, sysSteps);
		_img = new Image(d, previewMessage(_comm, _prop, _summ, tImg, pos, _message,
			[], names, flags, steps, variants, sysSteps, _centerX, _centerY, _boundaryCheck).scaled(_comm.prop.var.etc.imageScale));
	}

	@property
	bool focusInValues() { mixin(S_TRACE);
		return _values.focusInValues;
	}
	bool undo() { return _values.undo(); }
	bool redo() { return _values.redo(); }
}

/// メッセージのプレビューを生成する。
ImageDataWithScale previewMessage(Commons comm, Props prop, in Summary summ, ImageDataWithScale[] talkers,
		CardImagePosition[] poses, string message, in string[] sel, in string[char] names,
		in VarValue[string] flags, in VarValue[string] steps, in VarValue[string] variants,
		in VarValue[string] sysSteps, bool centerX, bool centerY, bool boundaryCheck) { mixin(S_TRACE);
	auto d = Display.getCurrent();
	version (Windows) {
		bool legacy = comm.skin.legacy;
	} else { mixin(S_TRACE);
		bool legacy = false;
	}
	auto sPath = summ ? summ.scenarioPath : "";
	auto rect = prop.ds(prop.looks.messageBounds);
	auto bh = prop.ds(prop.looks.messageButtonHeight);
	auto canvas = new Image(d, rect.width, rect.height + bh * cast(int)sel.length);
	scope (exit) canvas.dispose();
	auto gc = new GC(canvas);
	scope (exit) gc.dispose();
	int alpha;

	// 背景の描画
	auto back = new Color(d, dwtData(prop.var.etc.messageBackColor, alpha));
	scope (exit) back.dispose();
	gc.setBackground(back);
	gc.fillRectangle(prop.ds(3), prop.ds(3), rect.width - prop.ds(6), rect.height - prop.ds(6));
	foreach (i; 0 .. sel.length) { mixin(S_TRACE);
		gc.fillRectangle(prop.ds(3), rect.height + prop.ds(3) + bh * cast(int)i, rect.width - prop.ds(6), bh - prop.ds(6));
	}

	// 話者の描画
	foreach (i, talker; talkers) { mixin(S_TRACE);
		auto tImg = new Image(d, talker.scaled(prop.drawingScale));
		scope (exit) tImg.dispose();
		auto tp = prop.ds(prop.looks.messageTalkerPos);
		auto cs = prop.ds(prop.looks.cardSize);
		final switch (poses[i]) {
		case CardImagePosition.Default:
		case CardImagePosition.TopLeft:
			int tpy = tp.y + (cast(int)cs.height - cast(int)talker.getHeight(prop.drawingScale)) / 2;
			gc.drawImage(tImg, tp.x, tpy);
			break;
		case CardImagePosition.Center:
			auto b = tImg.getBounds();
			int tpx = (rect.width - b.width) / 2;
			int tpy = (rect.height - b.height) / 2;
			gc.drawImage(tImg, tpx, tpy);
			break;
		}
	}

	// 文章と特殊文字の描画

	// 改行置換
	if (.contains(message, '\r')) { mixin(S_TRACE);
		message = message.splitLines().join("\n");
	}
	// 特殊文字・フラグ・ステップ・色
	string[size_t] rFonts;
	char[size_t] rColors;
	VarValue fValue(string path) { mixin(S_TRACE);
		return flags.get(path, VarValue(false));
	}
	VarValue sValue(string path) { mixin(S_TRACE);
		auto p = path in steps;
		if (p) return *p;
		return sysSteps.get(path.toLower(), VarValue(false));
	}
	VarValue vValue(string path) { mixin(S_TRACE);
		return variants.get(path, VarValue(false));
	}
	version (Windows) {
		message = wrapReturnCode(message);
		message = message.replace("\r\n", "\n");
	}
	message = .formatMsg(message, &fValue, &sValue, &vValue, delegate string (char name) { mixin(S_TRACE);
		auto dc = std.ascii.toUpper(name);
		foreach (c, v; names) { mixin(S_TRACE);
			if (std.ascii.toUpper(c) == dc) { mixin(S_TRACE);
				return v;
			}
		}
		return "";
	}, ver => prop.isTargetVersion(summ, ver), prop.sys.prefixSystemVarName, (string path) { mixin(S_TRACE);
		if (summ && summ.legacy) { mixin(S_TRACE);
			auto c = decodeFontPath(path);
			if (!isSJIS1ByteChar(c)) return false;
		}
		return comm.skin.findImagePath(path, summ ? summ.scenarioPath : "", summ ? summ.dataVersion : LATEST_VERSION).length != 0 || decodeFontPath(path) in comm.skin.spChars;
	}, rFonts, rColors);

	auto antialias = 2 <= prop.drawingScale;
	auto font = .createFontFromPixels(prop.ds(prop.adjustFont(prop.looks.messageFont(legacy))), antialias);
	scope (exit) font.dispose();
	auto fc = new Color(d, dwtData(prop.var.etc.messageForeColor, alpha));
	scope (exit) fc.dispose();
	auto hc = new Color(d, dwtData(prop.var.etc.messageHemColor, alpha));
	scope (exit) hc.dispose();
	auto selFont = .createFontFromPixels(prop.ds(prop.adjustFont(prop.looks.messageSelectFont(legacy))), antialias);
	scope (exit) selFont.dispose();

	gc.setFont(font);

	int msgLen = talkers.length ? prop.looks.messageImageLen : prop.looks.messageLen;
	if (boundaryCheck) { mixin(S_TRACE);
		auto openChars = prop.looks.openChars;
		auto closeChars = prop.looks.closeChars;
		auto wordRegex = prop.looks.wordRegex;
		auto sw = gc.wTextExtent("#").x;
		message = .wrapMsg(message, msgLen - 1, (s) => (gc.wTextExtent(s).x + 1) / sw, true, openChars, closeChars, wordRegex, rFonts, rColors);
		msgLen = int.max;
	}

	auto dmsg = to!dstring(message);

	auto cr = d.getSystemColor(SWT.COLOR_RED);
	auto cb = d.getSystemColor(SWT.COLOR_CYAN);
	auto cg = d.getSystemColor(SWT.COLOR_GREEN);
	auto cy = d.getSystemColor(SWT.COLOR_YELLOW);
	auto co = new Color(d, new RGB(255, 165, 0)); scope (exit) co.dispose(); // CardWirth 1.50
	auto cp = new Color(d, new RGB(204, 136, 255)); scope (exit) cp.dispose(); // CardWirth 1.50
	auto cl = new Color(d, new RGB(169, 169, 169)); scope (exit) cl.dispose(); // CardWirth 1.50
	auto cd = new Color(d, new RGB(105, 105, 105)); scope (exit) cd.dispose(); // CardWirth 1.50

	auto start = prop.ds(prop.looks.messageStartPos(legacy, 0 < talkers.length, centerX));
	// 縁取り分の位置ずれ
	start.x -= 1;
	start.y -= 1;
	int x = start.x, y = start.y;
	int lineH;
	string old = "";
	int writeLen = 0;

	Rectangle drawRect = null;
	Rectangle lDrawRect = null;

	void ret() { mixin(S_TRACE);
		writeLen = 0;
		x = start.x;
		y += lineH;
		old = "";
		lDrawRect = null;
	}

	void merge(int x, int y, int w, int h) { mixin(S_TRACE);
		auto rect = new Rectangle(x, y, w, h);
		if (drawRect) { mixin(S_TRACE);
			drawRect.add(rect);
		} else { mixin(S_TRACE);
			drawRect = rect;
		}
		if (lDrawRect) { mixin(S_TRACE);
			lDrawRect.add(rect);
		} else { mixin(S_TRACE);
			lDrawRect = new Rectangle(x, y, w, h);
		}
	}
	void delegate(int slideX, int slideY)[] drawer;
	void delegate(GC tgc, int slideX, int slideY)[] textDrawer;

	// フォントイメージ
	auto wrgb = fc.getRGB();
	void drawSPFont(CPoint pt, string path, RGB c, lazy Rectangle lDrawRect) { mixin(S_TRACE);
		string fpath = comm.skin.findImagePath(path, sPath, summ ? summ.dataVersion : LATEST_VERSION);
		ImageDataWithScale data = null;
		if (fpath && fpath.length) { mixin(S_TRACE);
			// シナリオ内特殊文字
			data = .loadImageWithScale(fpath, prop.drawingScaleForImage(summ), true, false);
		}
		if (!data) { mixin(S_TRACE);
			// 標準特殊文字
			data = .spChar(comm.skin, prop.drawingScale, decodeFontPath(path));
			if (data) { mixin(S_TRACE);
				auto spc = data.scaled(prop.drawingScale);
				auto data2 = new ImageData(spc.width, spc.height, 24, new PaletteData(0xFF << 16, 0xFF << 8, 0xFF << 0));
				// &R等による色の置換
				foreach (dx; 0 .. data2.width) { mixin(S_TRACE);
					foreach (dy; 0 .. data2.height) { mixin(S_TRACE);
						auto p = spc.palette.getRGB(spc.getPixel(dx, dy));
						if (wrgb.opEquals(p)) { mixin(S_TRACE);
							data2.setPixel(dx, dy, (c.red << 16) | (c.green << 8) | (c.blue << 0));
						} else { mixin(S_TRACE);
							data2.setPixel(dx, dy, (p.red << 16) | (p.green << 8) | (p.blue << 0));
						}
					}
				}
				data2.transparentPixel = data2.getPixel(0, 0);
				data = new ImageDataWithScale(data2, prop.drawingScale);
			}
			merge(pt.x, pt.y, data.getWidth(prop.drawingScale), data.getHeight(prop.drawingScale));
			auto lineRect = lDrawRect;
			textDrawer ~= (tgc, slideX, slideY) { mixin(S_TRACE);
				auto img = new Image(d, data.scaled(prop.drawingScale));
				scope (exit) img.dispose();
				if (centerX) { mixin(S_TRACE);
					slideX += (rect.width - lineRect.width) / 2;
				}
				tgc.drawImage(img, pt.x + slideX, pt.y + slideY);
			};
		} else { mixin(S_TRACE);
			merge(pt.x, pt.y, data.getWidth(prop.drawingScale), data.getHeight(prop.drawingScale));
			auto lineRect = lDrawRect;
			drawer ~= (slideX, slideY) { mixin(S_TRACE);
				auto img = new Image(d, data.scaled(prop.drawingScale));
				scope (exit) img.dispose();
				if (centerX) { mixin(S_TRACE);
					slideX += (rect.width - lineRect.width) / 2;
				}
				gc.drawImage(img, slideX + pt.x + 1, slideY + pt.y + 1);
			};
		}
	}

	auto foreground = fc;
	lineH = prop.ds(prop.looks.messageLineHeight);
	for (size_t i = 0; i < dmsg.length; i++) { mixin(S_TRACE);
		if (!centerY && rect.height - prop.ds(6) < y + lineH) { mixin(S_TRACE);
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
				if (!centerY && rect.height - prop.ds(6) < y + lineH) { mixin(S_TRACE);
					// 行数オーバー
					break;
				}
			}
			writeLen += 2;
			drawSPFont(CPoint(x, y), *cf, foreground.getRGB(), lDrawRect);
			x += w;
			continue;
		}
		auto colorP = i in rColors;
		if (colorP) { mixin(S_TRACE);
			// フォント色変更
			switch (*colorP) {
			case 'W': foreground = fc; break;
			case 'R': foreground = cr; break;
			case 'B': foreground = cb; break;
			case 'G': foreground = cg; break;
			case 'Y': foreground = cy; break;
			case 'O': foreground = co; break;
			case 'P': foreground = cp; break;
			case 'L': foreground = cl; break;
			case 'D': foreground = cd; break;
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
			auto te = gc.wTextExtent(s);
			int len = (te.x + 1) / gc.wTextExtent("#").x;
			int w = prop.ds(prop.looks.messageCharWidth);
			if (len < 2) w = prop.ds(prop.looks.messageCharWidth) / 2;
			// 行末が半角スペースの時だけ特別扱いする(CardWirthの挙動に合わせた処理)
			if (msgLen < writeLen + (s == " " ? len - 1 : len)) { mixin(S_TRACE);
				// 列数オーバー
				if (dmsg[i] != '\n') { mixin(S_TRACE);
					ret();
				}
				if (rect.height - prop.ds(6) < y + lineH) { mixin(S_TRACE);
					// 行数オーバー
					break;
				}
			}
			writeLen += len;
			class TGCDrawer {
				private Color foreground;
				private string s;
				private int x;
				private int y;
				private Rectangle lineRect;
				this (Color foreground, string s, int x, int y, Rectangle lineRect) { mixin(S_TRACE);
					this.foreground = foreground;
					this.s = s;
					this.x = x;
					this.y = y;
					this.lineRect = lineRect;
				}
				void draw(GC tgc, int slideX, int slideY) { mixin(S_TRACE);
					static immutable JOINS = "―─＿￣";
					tgc.setForeground(foreground);
					if (centerX) { mixin(S_TRACE);
						slideX += (rect.width - lineRect.width) / 2;
					}
					auto x = this.x + slideX;
					auto y = this.y + slideY;
					if (std.string.indexOf(JOINS, s) != -1) { mixin(S_TRACE);
						// 強制的に左右を接続する文字
						tgc.wDrawText(s, x - 1, y, true);
						tgc.wDrawText(s, x, y, true);
						tgc.wDrawText(s, x + 1, y, true);
					} else { mixin(S_TRACE);
						tgc.wDrawText(s, x, y, true);
					}
				}
			}
			merge(x, y, w, lineH);
			textDrawer ~= &(new TGCDrawer(foreground, s, x, y, lDrawRect)).draw;
			x += w;
			break;
		}
	}

	int slideX = prop.ds(0), slideY = prop.ds(0);
	if (centerY && drawRect) { mixin(S_TRACE);
		slideY = (rect.height - drawRect.height) / 2 - drawRect.y;
	}

	auto canvasHeight = rect.height;
	if (drawRect) { mixin(S_TRACE);
		canvasHeight = .max(canvasHeight, drawRect.height);
	}
	auto textCanvas = new Image(d, rect.width, canvasHeight + bh * cast(int)sel.length);
	scope (exit) textCanvas.dispose();
	auto tgc = new GC(textCanvas);
	scope (exit) tgc.dispose();

	// FIXME: IPAフォントの使用とアンチエイリアス設定を
	//        同時に行うと一部環境で問題が出る。
	//tgc.setTextAntialias(SWT.OFF);
	tgc.setFont(font);
	tgc.setForeground(fc);
	tgc.setBackground(hc);
	tgc.fillRectangle(textCanvas.getBounds());

	foreach (dlg; textDrawer) { mixin(S_TRACE);
		dlg(tgc, slideX, slideY);
	}

	// 枠
	auto c1 = new Color(d, dwtData(prop.var.etc.messageLineColor1, alpha));
	scope (exit) c1.dispose();
	auto c2 = new Color(d, dwtData(prop.var.etc.messageLineColor2, alpha));
	scope (exit) c2.dispose();
	foreach (l; prop.ds(0) .. prop.ds(1)) { mixin(S_TRACE);
		gc.setForeground(c1);
		auto l2 = l * 2;
		gc.drawRectangle(prop.ds(0) + l, prop.ds(0) + l, rect.width - 1 - l2, rect.height - 1 - l2);
		gc.drawRectangle(prop.ds(2) + l, prop.ds(2) + l, rect.width - prop.ds(4) - 1 - l2, rect.height - prop.ds(4) - 1 - l2);
		foreach (i; 0 .. sel.length) { mixin(S_TRACE);
			gc.drawRectangle(prop.ds(0) + l, rect.height + bh * cast(int)i + l, rect.width - 1 - l2, bh - 1 - l2);
			gc.drawRectangle(prop.ds(2) + l, rect.height + prop.ds(2) + bh * cast(int)i + l, rect.width - prop.ds(4) - 1 - l2, bh - prop.ds(4) - 1 - l2);
		}
		gc.setForeground(c2);
		gc.drawRectangle(prop.ds(1) + l, prop.ds(1) + l, rect.width - prop.ds(2) - 1 - l2, rect.height - prop.ds(2) - 1 - l2);
		foreach (i; 0 .. sel.length) { mixin(S_TRACE);
			gc.drawRectangle(prop.ds(1) + l, rect.height + prop.ds(1) + bh * cast(int)i + l, rect.width - prop.ds(2) - 1 - l2, bh - prop.ds(2) - 1 - l2);
		}
	}

	// 貼り付け
	foreach (dlg; drawer) { mixin(S_TRACE);
		dlg(slideX, slideY);
	}

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

	// 選択肢
	gc.setForeground(fc);
	gc.setFont(selFont);
	auto slh = gc.getFontMetrics().getHeight();
	int sx;
	int sy = rect.height + ((bh - slh) / 2);
	foreach (i, t; sel) { mixin(S_TRACE);
		sx = (rect.width - gc.wTextExtent(t).x) / 2;
		gc.wDrawText(t, sx, sy, true);
		sy += bh;
	}

	auto data = canvas.getImageData();
	return new ImageDataWithScale(data, prop.drawingScale);
}

void setupSPCharsMenu(Commons comm, Summary summ, UseCounter uc, Control ctrl, Menu parentMenu, bool full, bool expandSharps, bool delegate() isExpandSPChars) { mixin(S_TRACE);
	void delegate() dummy = { };
	auto mainMI = .createMenuItem(comm, parentMenu, MenuID.PutSPChar, dummy, isExpandSPChars, SWT.CASCADE);
	auto menu = new Menu(mainMI);
	mainMI.setMenu(menu);

	.listener(menu, SWT.Show, { mixin(S_TRACE);
		foreach (mi; menu.getItems()) mi.dispose();

		void insert(string s) { mixin(S_TRACE);
			if (auto t = cast(Text)ctrl) { mixin(S_TRACE);
				t.insert(s);
			} else if (auto t = cast(Combo)ctrl) { mixin(S_TRACE);
				auto ws = s.to!wstring;
				auto p = t.getSelection();
				auto a = t.getText().toUTF16()[0 .. p.x];
				auto b = t.getText().toUTF16()[p.x .. p.y];
				auto c = t.getText().toUTF16()[p.y .. $];
				t.setText((a ~ ws ~ c).to!string);
				p.x += ws.length;
				p.y = p.x;
				t.setSelection(p);
			} else assert (0);
		}

		// カード名等
		foreach (spc; expandSharps ? (full ? SPCHAR_ALL : (!summ || !summ.legacy ? SPCHAR_TEXT : SPCHAR_TEXT_CLASSIC)) : []) { mixin(S_TRACE);
			void createMI(SPChar spc) { mixin(S_TRACE);
				void put() { mixin(S_TRACE);
					insert("#" ~ .C_TBL[spc]);
				}
				final switch (spc) {
				case SPChar.M:
					.createMenuItem2(comm, menu, comm.prop.msgs.scTalkerName(Talker.Selected),
						comm.prop.images.scTalker(Talker.Selected), &put, null);
					break;
				case SPChar.U:
					.createMenuItem2(comm, menu, comm.prop.msgs.scTalkerName(Talker.Unselected),
						comm.prop.images.scTalker(Talker.Unselected), &put, null);
					break;
				case SPChar.R:
					.createMenuItem2(comm, menu, comm.prop.msgs.scTalkerName(Talker.Random),
						comm.prop.images.scTalker(Talker.Random), &put, null);
					break;
				case SPChar.C:
					.createMenuItem2(comm, menu, comm.prop.msgs.scTalkerName(Talker.Card),
						comm.prop.images.scTalker(Talker.Card), &put, null);
					break;
				case SPChar.I:
					.createMenuItem2(comm, menu, comm.prop.msgs.scRef, comm.prop.images.scRef, &put, null);
					break;
				case SPChar.T:
					.createMenuItem2(comm, menu, comm.prop.msgs.scTeam, comm.prop.images.scTeam, &put, null);
					break;
				case SPChar.Y:
					.createMenuItem2(comm, menu, comm.prop.msgs.scYado, comm.prop.images.scYado, &put, null);
					break;
				}
			}
			createMI(spc);
		}

		if (!summ.legacy) { mixin(S_TRACE);
			if (menu.getItemCount()) new MenuItem(menu, SWT.SEPARATOR);

			if (expandSharps) { mixin(S_TRACE);
				// 選択メンバ番号(Wsn.2)
				.createMenuItem2(comm, menu, comm.prop.msgs.selectedPlayerCardNumber,
					comm.prop.images.selectedPlayerCardNumber, () => insert("$" ~ comm.prop.sys.selectedPlayerCardNumber ~ "$"), null);

				new MenuItem(menu, SWT.SEPARATOR);
			}

			// パーティメンバ名(Wsn.2)
			foreach (uint pcn; 1u .. cast(uint)comm.prop.looks.partyMax + 1u) { mixin(S_TRACE);
				void createMI2(uint pcn) { mixin(S_TRACE);
					.createMenuItem2(comm, menu, .tryFormat(comm.prop.msgs.playerCardName, pcn),
						comm.prop.images.playerCardName, () => insert("$" ~ comm.prop.sys.playerCardName(pcn) ~ "$"), null);
				}
				createMI2(pcn);
			}
		}

		new MenuItem(menu, SWT.SEPARATOR);

		// フラグ
		auto fMI = .createMenuItem(comm, menu, MenuID.PutFlagValue, dummy, &summ.flagDirRoot.hasFlag, SWT.CASCADE);
		auto fMenu = new Menu(fMI);
		fMI.setMenu(fMenu);
		.listener(fMenu, SWT.Show, { mixin(S_TRACE);
			foreach (mi; fMenu.getItems()) mi.dispose();
			.sortedWithPath(.allVars!(cwx.flag.Flag)(summ.flagDirRoot, uc), comm.prop.var.etc.logicalSort, (cwx.flag.Flag f) { mixin(S_TRACE);
				.createMenuItem2(comm, fMenu, f.path, comm.prop.images.flag, () => insert("%" ~ f.path ~ "%"), null);
			});
		});

		// ステップ
		auto sMI = .createMenuItem(comm, menu, MenuID.PutStepValue, dummy, &summ.flagDirRoot.hasStep, SWT.CASCADE);
		auto sMenu = new Menu(sMI);
		sMI.setMenu(sMenu);
		.listener(sMenu, SWT.Show, { mixin(S_TRACE);
			foreach (mi; sMenu.getItems()) mi.dispose();
			.sortedWithPath(.allVars!Step(summ.flagDirRoot, uc), comm.prop.var.etc.logicalSort, (Step f) { mixin(S_TRACE);
				.createMenuItem2(comm, sMenu, f.path, comm.prop.images.step, () => insert("$" ~ f.path ~ "$"), null);
			});
		});

		// コモン
		auto vMI = .createMenuItem(comm, menu, MenuID.PutVariantValue, dummy, &summ.flagDirRoot.hasVariant, SWT.CASCADE);
		auto vMenu = new Menu(vMI);
		vMI.setMenu(vMenu);
		.listener(vMenu, SWT.Show, { mixin(S_TRACE);
			foreach (mi; vMenu.getItems()) mi.dispose();
			.sortedWithPath(.allVars!(cwx.flag.Variant)(summ.flagDirRoot, uc), comm.prop.var.etc.logicalSort, (cwx.flag.Variant f) { mixin(S_TRACE);
				.createMenuItem2(comm, vMenu, f.path, comm.prop.images.variant, () => insert("@" ~ f.path ~ "@"), null);
			});
		});

		if (full) { mixin(S_TRACE);
			new MenuItem(menu, SWT.SEPARATOR);

			// 色の変更
			auto cMI = .createMenuItem(comm, menu, MenuID.PutColor, dummy, null, SWT.CASCADE);
			auto cMenu = new Menu(cMI);
			cMI.setMenu(cMenu);
			foreach (c; [
				'W', 'R', 'B', 'G', 'Y'
			] ~ [
				'O', 'P', 'L', 'D' // CardWirth 1.50
			]) { mixin(S_TRACE);
				void putC(char c) { mixin(S_TRACE);
					string t;
					final switch (c) {
					case 'W': t = comm.prop.msgs.colorW; break;
					case 'R': t = comm.prop.msgs.colorR; break;
					case 'B': t = comm.prop.msgs.colorB; break;
					case 'G': t = comm.prop.msgs.colorG; break;
					case 'Y': t = comm.prop.msgs.colorY; break;
					case 'O': t = comm.prop.msgs.colorO; break; // CardWirth 1.50
					case 'P': t = comm.prop.msgs.colorP; break; // CardWirth 1.50
					case 'L': t = comm.prop.msgs.colorL; break; // CardWirth 1.50
					case 'D': t = comm.prop.msgs.colorD; break; // CardWirth 1.50
					}
					createMenuItem2(comm, cMenu, t, comm.prop.images.color(c), () => putColor(ctrl, c), null);
				}
				putC(c);
			}

			new MenuItem(menu, SWT.SEPARATOR);

			// スキン付属の特殊文字
			auto skMI = .createMenuItem(comm, menu, MenuID.PutSkinSPChar, dummy, () => 0 < comm.skin.spChars.length, SWT.CASCADE);
			auto skMenu = new Menu(skMI);
			skMI.setMenu(skMenu);
			.listener(skMenu, SWT.Show, { mixin(S_TRACE);
				foreach (mi; skMenu.getItems()) mi.dispose();
				auto skin = comm.skin;
				foreach (spc; std.algorithm.sort(skin.spChars.keys)) { mixin(S_TRACE);
					void putSkinC(dchar spc) { mixin(S_TRACE);
						auto data = .spChar(skin, comm.prop.drawingScale, spc);
						if (!data.valid) return;
						auto img = new Image(Display.getCurrent(), data.scaled(.dpiMuls));
						auto name = toUTF8("#"d ~ spc);
						auto mi = createMenuItem2(comm, skMenu, name, img, () => insert(name), null);
						.listener(mi, SWT.Dispose, &img.dispose);
					}
					putSkinC(spc);
				}
			});

			new MenuItem(menu, SWT.SEPARATOR);

			// イメージ
			auto fontMI = .createMenuItem(comm, menu, MenuID.PutImageFont, dummy, { mixin(S_TRACE);
				foreach (file; .dirEntries(summ.scenarioPath, "font_?.bmp", SpanMode.shallow)) {
					if (file.isSPFontFile) return true;
				}
				return false;
			}, SWT.CASCADE);
			auto fontMenu = new Menu(fontMI);
			fontMI.setMenu(fontMenu);
			.listener(fontMenu, SWT.Show, { mixin(S_TRACE);
				foreach (mi; fontMenu.getItems()) mi.dispose();
				auto skin = comm.skin;
				string[] files;
				foreach (file; .dirEntries(summ.scenarioPath, "font_?.bmp", SpanMode.shallow)) { mixin(S_TRACE);
					if (!file.isSPFontFile) continue;
					files ~= file;
				}
				foreach (file; std.algorithm.sort!((a, b) => fncmp(a, b) < 0)(files)) { mixin(S_TRACE);
					void createMI3(string file) { mixin(S_TRACE);
						auto image = skin.isCardImage(file, false, false) ? comm.prop.images.cards : comm.prop.images.backs;
						.createMenuItem2(comm, fontMenu, file.baseName(), image, () => insert("#%s".format(decodeFontPath(file.baseName()))), null);
					}
					createMI3(file);
				}
			});
		}
	});
}

string createSPCharPreview(in Commons comm, in Summary summ, in UseCounter uc, string text, bool expandSharps, VarValue delegate(string path) overrideFlagValue, VarValue delegate(string path) overrideStepValue) { mixin(S_TRACE);
	VarValue fValue(string path) { mixin(S_TRACE);
		if (overrideFlagValue) { mixin(S_TRACE);
			auto v = overrideFlagValue(path);
			if (v.exists) return v;
		}
		auto flag = .findVar!(cwx.flag.Flag)(summ ? summ.flagDirRoot : null, uc, path);
		return flag ? VarValue(true, flag.onOff ? flag.on : flag.off, flag.expandSPChars) : VarValue(false);
	}
	VarValue[string] sysSteps;
	.getPreviewSysSteps(comm.prop, summ, expandSharps, sysSteps);
	VarValue sValue(string path) { mixin(S_TRACE);
		if (overrideStepValue) { mixin(S_TRACE);
			auto v = overrideStepValue(path);
			if (v.exists) return v;
		}
		auto step = .findVar!Step(summ ? summ.flagDirRoot : null, uc, path);
		return step ? VarValue(true, step.value, step.expandSPChars) : sysSteps.get(path.toLower(), VarValue(false));
	}
	VarValue vValue(string path) { mixin(S_TRACE);
		auto variant = .findVar!(cwx.flag.Variant)(summ ? summ.flagDirRoot : null, uc, path);
		return variant ? VarValue(true, .variantValueToPreviewText(variant), false) : VarValue(false);
	}
	string getName(char name) { mixin(S_TRACE);
		return .getSPCharPreviewValue(comm, name);
	}
	bool hasMaterial(string path) { mixin(S_TRACE);
		if (!expandSharps) return true; // #から始まる文字が全て展開されないようにする
		if (summ.legacy) { mixin(S_TRACE);
			auto c = .decodeFontPath(path);
			if (!.isSJIS1ByteChar(c)) return false;
		}
		return comm.skin.findImagePath(path, summ.scenarioPath, summ.dataVersion).length != 0 || .decodeFontPath(path) in comm.skin.spChars;
	}
	string[size_t] rFonts;
	char[size_t] rColors;
	return .formatMsg(text, &fValue, &sValue, &vValue, &getName, ver => comm.prop.isTargetVersion(summ, ver),
		comm.prop.sys.prefixSystemVarName, &hasMaterial, rFonts, rColors);
}

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
