
module cwx.editor.gui.dwt.areaview;

import cwx.utils;
import cwx.area;
import cwx.card;
import cwx.flag;
import cwx.summary;
import cwx.background;
import cwx.props;
import cwx.imagesize;
import cwx.xml;
import cwx.skin;
import cwx.usecounter;
import cwx.path;
import cwx.structs;
import cwx.sjis;
import cwx.graphics;
import cwx.msgs;
import cwx.menu;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.spcarddialog;
import cwx.editor.gui.dwt.bgimagedialog;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.jpyimage;
import cwx.editor.gui.dwt.areawindow;
import cwx.editor.gui.dwt.messageutils;
import cwx.editor.gui.dwt.areaviewutils;
import cwx.editor.gui.dwt.dmenu;

import std.algorithm;
import std.math;
import std.path;
import std.file;
import std.traits;
import std.datetime;
import std.string;

import org.eclipse.swt.SWTException;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Spinner;
import org.eclipse.swt.widgets.ScrollBar;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.custom.SashForm;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CLabel;
import org.eclipse.swt.custom.CCombo;
import org.eclipse.swt.custom.ScrolledComposite;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.RGB;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Region;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.graphics.PaletteData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseTrackAdapter;
import org.eclipse.swt.events.MouseMoveListener;
import org.eclipse.swt.events.ModifyEvent;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.events.FocusEvent;
import org.eclipse.swt.events.FocusAdapter;
import org.eclipse.swt.events.FocusListener;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.KeyAdapter;
import org.eclipse.swt.events.KeyListener;
import org.eclipse.swt.events.TypedEvent;
import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.DropTarget;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.DropTargetAdapter;
import org.eclipse.swt.dnd.DragSource;
import org.eclipse.swt.dnd.DragSourceEvent;
import org.eclipse.swt.dnd.DragSourceAdapter;
import org.eclipse.swt.dnd.FileTransfer;
import org.eclipse.swt.dnd.ByteArrayTransfer;
import org.eclipse.swt.dnd.Transfer;
import org.eclipse.swt.dnd.Clipboard;
import java.lang.all;

public:

private P spnValue(string T, N, P)(N[] keys, P val) {
	auto a = keys[0];
	P value = mixin (T);
	for (int i = 1; i < keys.length; i++) {
		a = keys[i];
		if (mixin (T) != value) {
			value = val;
			break;
		}
	}
	return value;
}

private void createLabel(ToolBar bar, string label) {
	auto comp = new Composite(bar, SWT.NONE);
	comp.setLayout(new CenterLayout(SWT.VERTICAL, 0));
	auto lbl = new Label(comp, SWT.NONE);
	lbl.setText(label);
	createToolItemC(bar, comp);
}

private Spinner createSpinner(ToolBar bar, string label, int max, int min, int sel,
		void delegate(int value) edit, void delegate(int value) enter, int delegate(int oldVal) cancel) {
	createLabel(bar, label ~ ":");
	auto spn = new Spinner(bar, SWT.BORDER);
	spn.setEnabled(false);
	spn.setMaximum(max);
	spn.setMinimum(min);
	spn.setSelection(sel);
	createToolItemC(bar, spn);
	auto editL = new SpinnerEdit(spn, enter, edit, cancel);
	return spn;
}

private ToolItem createToolItemC(ToolBar bar, Control c) {
	auto ti = new ToolItem(bar, SWT.SEPARATOR);
	ti.setControl(c);
	ti.setWidth(c.computeSize(SWT.DEFAULT, SWT.DEFAULT).x);
	return ti;
}

private enum DropTarg {
	ImagePane,
	Card,
	Back
}

class AbstractAreaView(A, C, bool UseCards, bool UseBacks) : Composite, TCPD {
	/// 変更があった際に呼び出される。
	void delegate()[] modEvent;
	private void callModEvent() {
		foreach (dlg; modEvent) dlg();
	}
private:
	string _id;
	Commons _comm;
	Props _prop;
	A _area;
	TCPD _tcpd;
	UndoManager _undo;
	Preview _preview;

	void previewTrigger(Table list, int x, int y) {
		auto itm = list.getItem(new Point(x, y));
		if (!itm) {
			_preview.close();
			return;
		}
		int i = list.indexOf(itm);
		PileImage image = null;
		static if (UseCards) {
			if (_cards is list) {
				image = _imgp.images[cardsIndex + i];
			}
		}
		static if (UseBacks) {
			if (_backs is list) {
				image = _imgp.images[i];
			}
		}
		if (!image) {
			_preview.close();
			return;
		}
		auto b = itm.getBounds();
		auto p = list.toDisplay(b.x, b.y + b.height);
		_preview.image(image, p.x, p.y, b.height);
		_preview.show();
	}
	class ClosePreview : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			_preview.close();
		}
	}
	class PreviewTrigger : MouseTrackAdapter, MouseMoveListener {
		override void mouseExit(MouseEvent e) {
			_preview.close();
		}
		override void mouseMove(MouseEvent e) {
			auto list = cast(Table) e.widget;
			previewTrigger(list, e.x, e.y);
		}
	}

	/// 他のエリアのカード配置を参照する。
	static const RefCards = !UseCards && UseBacks;
	static if (RefCards) {
		Combo _refAreas;
		AbstractArea[] _refAreasArr;
		AbstractArea _refTarget = null;
		void refreshRefAreas() {
			if (!_summ) return;
			_refAreasArr.length = 0;
			_refAreas.removeAll();
			if (!_area) return;
			_refAreas.add(_prop.msgs.noRefArea);
			_refAreas.select(0);
			foreach (a; _summ.areas) {
				_refAreasArr ~= a;
				_refAreas.add(to!string(a.id) ~ "." ~ a.name);
				if(_refTarget is a) _refAreas.select(_refAreas.getItemCount() - 1);
			}
			foreach (a; _summ.battles) {
				_refAreasArr ~= a;
				_refAreas.add(to!string(a.id) ~ "." ~ a.name);
				if(_refTarget is a) _refAreas.select(_refAreas.getItemCount() - 1);
			}
			if (0 == _refAreas.getSelectionIndex()) {
				_refTarget = null;
				foreach (a; _imgp.appends) {
					a.dispose();
				}
				_imgp.appends = [];
			}
		}
		void refreshRefAreasA(Area a) {refreshRefAreas();}
		void refreshRefAreasB(Battle a) {refreshRefAreas();}
		@property
		int refCardIndex() {
			int partyIndex = 0;
			static if (UseCards) partyIndex += _area.cards.length;
			static if (UseBacks) partyIndex += _area.backs.length;
			return partyIndex;
		}
		void refRefMenuCard(string a) {
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath, cpparent(a))) return;
			createRefCard();
			_imgp.redraw();
		}
		void addRefMenuCard(string a) {
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath, cpparent(a))) return;
			createRefCard();
			_imgp.redraw();
		}
		void delRefMenuCard(string a) {
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath, cpparent(a))) return;
			createRefCard();
			_imgp.redraw();
		}
		void upRefMenuCards(string a, int[] indices, int count) {
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath, a)) return;
			if (!indices.length) return;
			createRefCard();
			_imgp.redraw();
		}
		void downRefMenuCards(string a, int[] indices, int count) {
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath, a)) return;
			if (!indices.length) return;
			createRefCard();
			_imgp.redraw();
		}
		void openRefAreaView() {
			if (!_refTarget) return;
			try {
				_comm.openCWXPath(cpaddattr(_refTarget.cwxPath, "shallow"), false);
			} catch (Exception e) {
				debugln(e);
			}
		}
	}

	static class AUndo : Undo {
		protected AbstractAreaView _v = null;
		protected Commons comm;
		protected A area;
		protected Summary summ;
		this (AbstractAreaView v, Commons comm, A area, Summary summ) {
			static if (!is(A : Area) && !is(A : Battle)) {
				_v = v;
			}
			this.comm = comm;
			this.area = area;
			this.summ = summ;
		}
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
		protected void udb(AbstractAreaView v) {
			if (!v) return;
			auto ct = Display.getCurrent().getFocusControl();
			while (ct.getParent()) {
				if (ct is v) {
					return;
				}
				ct = ct.getParent();
			}
			.forceFocus(v._imgp, false);
		}
		protected void uda(AbstractAreaView v) {
			scope (exit) comm.refreshToolBar();
			if (!v) return;
			static if (UseCards) if (!v._viewCards) v._cards.deselectAll();
			static if (UseBacks) if (!v._viewBacks) v._backs.deselectAll();
			v.refreshStatusLine();
		}
		protected AbstractAreaView view() {
			static if (is(A : Area) || is(A : Battle)) {
				return comm.areaViewFrom!(A, C, UseCards, UseBacks)(area.cwxPath, false);
			} else {
				return _v;
			}
		}
	}
	static if (UseCards) {
		static class UndoSPAuto : AUndo {
			private bool _spAuto;
			this (AbstractAreaView v, Commons comm, A area, Summary summ) {
				super (v, comm, area, summ);
				_spAuto = area.spAuto;
			}
			private void impl() {
				auto v = view();
				udb(v);
				scope (exit) uda(v);
				auto spAuto = area.spAuto;
				area.spAuto = _spAuto;
				_spAuto = spAuto;
				if (v) {
					if (v._autoMenu) v._autoMenu.setSelection(area.spAuto);
					if (v._autoTMenu) v._autoTMenu.setSelection(area.spAuto);
					if (v._customMenu) v._customMenu.setSelection(!area.spAuto);
					if (v._customTMenu) v._customTMenu.setSelection(!area.spAuto);
					v.callModEvent();
				}
			}
			override void undo() {impl();}
			override void redo() {impl();}
			override void dispose() {}
		}
	}
	static if (is(A == Battle)) {
		static class MCWXPath : CWXPath {
			@property
			override string cwxPath() {return "";}
			override CWXPath findCWXPath(string path) {return null;}
			@property
			override CWXPath[] cwxChilds() {return [];}
			@property
			CWXPath cwxParent() {return null;}
		}
		static class UndoMusic : AUndo {
			private PathUser _path;
			this (AbstractAreaView v, Commons comm, A area, Summary summ) {
				super (v, comm, area, summ);
				_path = new PathUser(new MCWXPath);
				if (summ) _path.setUseCounter(summ.useCounter.sub);
				_path.path = area.music;
			}
			private void impl() {
				auto v = view();
				udb(v);
				scope (exit) uda(v);
				auto path = _path.path;
				_path.path = area.music;
				area.music = path;
				if (v) {
					v._bgm.path = path;
					v.callModEvent();
				}
			}
			override void undo() {impl();}
			override void redo() {impl();}
			override void dispose() {
				_path.removeUseCounter();
			}
		}
	}
	template Reselect() {
		private int[] _cIdcs;
		private int[] _bIdcs;
		this (AbstractAreaView v, Commons comm, A area, Summary summ, int[] cIdcs, int[] bIdcs) {
			super (v, comm, area, summ);
			_cIdcs = cIdcs;
			_bIdcs = bIdcs;
		}
		private void reselect(AbstractAreaView v) {
			if (!v) return;
			static if (UseCards) v._cards.select(_cIdcs);
			static if (UseBacks) v._backs.select(_bIdcs);
		}
		private void add(int i) {
			_cIdcs[] += i;
			_bIdcs[] += i;
		}
	}
	static class UndoUD(int I) : AUndo {
		mixin Reselect;
		private int _count = 1;
		this (AbstractAreaView v, Commons comm, A area, Summary summ, int[] cIdcs, int[] bIdcs, int count) {
			super (v, comm, area, summ);
			_cIdcs = cIdcs;
			_bIdcs = bIdcs;
			_count = count;
		}
		override void undo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			add(I * _count);
			reselect(v);
			static if (I < 0) {
				downImpl(v, comm, area, _cIdcs, _bIdcs, _count, false);
			} else {
				upImpl(v, comm, area, _cIdcs, _bIdcs, _count, false);
			}
			add(-I * _count);
		}
		override void redo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			reselect(v);
			static if (I < 0) {
				upImpl(v, comm, area, _cIdcs, _bIdcs, _count, false);
			} else {
				downImpl(v, comm, area, _cIdcs, _bIdcs, _count, false);
			}
		}
		override void dispose() {}
	}
	alias UndoUD!(-1) UndoUp;
	alias UndoUD!(1) UndoDown;
	static class UndoInsert : AUndo {
		mixin Reselect;
		private UndoDelete _delUndo = null;
		override void undo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			reselect(v);
			_delUndo = new UndoDelete(v, comm, area, summ, _cIdcs, _bIdcs);
			delImpl2(v, comm, area, _cIdcs, _bIdcs, false);
		}
		override void redo() {
			_delUndo.undo();
			_delUndo = null;
		}
		override void dispose() {
			if (_delUndo) _delUndo.dispose();
		}
	}
	static class UndoDelete : AUndo {
		static if (UseCards) {
			C[int] _cs;
			bool[int] _cChks;
		}
		static if (UseBacks) {
			BgImage[int] _bs;
			bool[int] _bChks;
		}
		this (AbstractAreaView v, Commons comm, A area, Summary summ, int[] cIdcs, int[] bIdcs) {
			super (v, comm, area, summ);
			static if (UseCards) {
				foreach (i; cIdcs) {
					auto node = area.cards[i].toNode();
					auto c = C.createFromNode(node, LATEST_VERSION);
					if (summ) c.setUseCounter(summ.useCounter.sub);
					_cs[i] = c;
					_cChks[i] = v ? v._cards.getItem(i).getChecked() : true;
				}
			}
			static if (UseBacks) {
				foreach (i; bIdcs) {
					auto b = area.backs[i].dup;
					if (summ) b.setUseCounter(summ.useCounter.sub);
					_bs[i] = b;
					_bChks[i] = v ? v._backs.getItem(i).getChecked() : true;
				}
			}
		}
		override void undo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			static if (UseCards) {
				foreach (i; _cs.keys.sort) {
					appendCardImpl(v, comm, area, i, _cs[i], true, false, _cChks[i]);
				}
			}
			static if (UseBacks) {
				foreach (i; _bs.keys.sort) {
					appendBgImageImpl(v, comm, area, i, _bs[i], true, false, _bChks[i]);
				}
			}
			if (v) v.refreshSelected();
		}
		override void redo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			int[] cs;
			int[] bs;
			static if (UseCards) cs = _cs.keys;
			static if (UseBacks) bs = _bs.keys;
			delImpl2(v, comm, area, cs, bs, false);
		}
		override void dispose() {
			static if (UseCards) {
				foreach (i, c; _cs) c.removeUseCounter();
			}
			static if (UseBacks) {
				foreach (i, b; _bs) b.removeUseCounter();
			}
		}
	}
	static class UndoEdit : AUndo {
		static if (UseCards) C[int] _cs;
		static if (UseBacks) BgImage[int] _bs;
		this (AbstractAreaView v, Commons comm, A area, Summary summ, int[] ckeys, int[] bkeys) {
			super (v, comm, area, summ);
			static if (UseCards) _cs = saveC(ckeys);
			static if (UseBacks) _bs = saveB(bkeys);
		}
		static if (UseCards) {
			private C[int] saveC(int[] indices) {
				C[int] cs;
				foreach (i; indices) {
					auto c = area.cards[i];
					static if (is(C == MenuCard)) {
						c = new C(c.name, c.path, c.desc, c.flag, c.x, c.y, c.scale);
					} else static if (is(C == EnemyCard)) {
						c = new C(c.id, c.escape, c.flag, c.x, c.y, c.scale);
					} else static assert (0);
					if (summ) c.setUseCounter(summ.useCounter.sub);
					cs[i] = c;
				}
				return cs;
			}
		}
		static if (UseBacks) {
			private BgImage[int] saveB(int[] indices) {
				BgImage[int] bs;
				foreach (i; indices) {
					auto b = area.backs[i];
					b = b.dup;
					if (summ) b.setUseCounter(summ.useCounter.sub);
					bs[i] = b;
				}
				return bs;
			}
		}
		private void impl() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			static if (UseCards) {
				auto cs = saveC(_cs.keys);
				foreach (i, c; _cs) {
					c.removeUseCounter();
					auto ac = area.cards[i];
					static if (is(C == MenuCard)) {
						ac.name = c.name;
						ac.path = c.path;
						ac.desc = c.desc;
						ac.flag = c.flag;
						ac.x = c.x;
						ac.y = c.y;
						ac.scale = c.scale;
					} else static if (is(C == EnemyCard)) {
						ac.id = c.id;
						ac.escape = c.escape;
						ac.flag = c.flag;
						ac.x = c.x;
						ac.y = c.y;
						ac.scale = c.scale;
					} else static assert (0);
					comm.refMenuCard.call(ac.cwxPath);
				}
				_cs = cs;
			}
			static if (UseBacks) {
				auto bs = saveB(_bs.keys);
				foreach (i, b; _bs) {
					b.removeUseCounter();
					auto ab = area.backs[i];
					ab.path = b.path;
					ab.flag = b.flag;
					ab.x = b.x;
					ab.y = b.y;
					ab.width = b.width;
					ab.height = b.height;
					ab.mask = b.mask;
					comm.refBgImage.call(ab.cwxPath);
				}
				_bs = bs;
			}
			if (v) {
				v.refreshPanel();
				v.refreshControls();
				v.callModEvent();
			}
			comm.refUseCount.call();
		}
		override void undo() {
			impl();
		}
		override void redo() {
			impl();
		}
		override void dispose() {
			static if (UseCards) {
				foreach (i, c; _cs) c.removeUseCounter();
			}
			static if (UseBacks) {
				foreach (i, b; _bs) b.removeUseCounter();
			}
		}
	}
	UndoEdit createUndoEdit() {
		int[] cs;
		int[] bs;
		static if (UseCards) cs = _cards.getSelectionIndices();
		static if (UseBacks) bs = _backs.getSelectionIndices();
		return new UndoEdit(this, _comm, _area, _summ, cs, bs);
	}

	@property
	protected Props prop() {return _prop;}
	@property
	protected Summary summ() {return _summ;}

	ImagePane _imgp;

	bool _viewMsg = false;
	bool _viewParty = true;
	bool _fixed = false;

	Summary _summ;
	MenuItem _vmMenu;
	MenuItem _vpMenu;
	MenuItem _vfMenu;
	ToolItem _vmTMenu;
	ToolItem _vpTMenu;
	ToolItem _vfTMenu;
	static if (RefCards) {
		MenuItem _vrMenu;
		ToolItem _vrTMenu;
	}
	static if (is (C == EnemyCard) || RefCards) {
		MenuItem _dbgMenu;
		ToolItem _dbgTMenu;
		@property
		protected bool debugMode() {return _dbgMode;}
		bool _dbgMode = false;
		void reverseDebugMode() {
			_dbgMode = !_dbgMode;
			if (_dbgMenu) _dbgMenu.setSelection(_dbgMode);
			if (_dbgTMenu) _dbgTMenu.setSelection(_dbgMode);
			refreshPanel();
		}
	}
	static if (is (C == EnemyCard)) {
		ToolItem _escTMenu;
		MaterialSelect!(MtType.BGM, CCombo, CCombo) _bgm;
		void setEscape() {
			_undo ~= createUndoEdit();
			foreach (c; _editC.keys) {
				c.escape = _escTMenu.getSelection();
			}
			callModEvent();
		}
		void selectBGM() {
			_undo ~= new UndoMusic(this, _comm, _area, _summ);
			_area.music = _bgm.path;
			_comm.refUseCount.call();
			callModEvent();
			_comm.refreshToolBar();
		}
	}

	static if (UseCards && UseBacks) {
		SplitPane _sash;
	}

	@property
	ImagePane imagePane() {return _imgp;}
	Spinner _xSpn, _ySpn;
	Combo _flag = null;
	static if (UseCards) {
		bool _viewCards = true;
		C[PileImage] _cardTbl;
		int[C] _editC;
		Table _cards;
		MenuItem _vcMenu;
		ToolItem _vcTMenu;
		MenuItem _autoMenu;
		ToolItem _autoTMenu;
		MenuItem _customMenu;
		ToolItem _customTMenu;
		Spinner _scaleSpn;

		@property
		Table cardList() {return _cards;}
		void editSpnCard(string T)(int value) {
			__editSpn!(T, C)(value, _editC, cardsIndex);
			_imgp.redraw();
		}
		void enterSpnCard(string T, string N)(int value) {
			_undo ~= createUndoEdit();
			__enterSpn!(T, N, C)(value, _editC, cardsIndex);
			_imgp.redraw();
		}
		int cancelSpnCard(string T)(int oldVal) {
			assert(_editC.length > 0);
			if (_editC.length > 1) {
				return 0;
			} else {
				assert(_editC.length == 1);
				return __cancelSpn!(T, C)(_editC);
			}
		}
		class SCListener : SelectionAdapter {
			public override void widgetSelected(SelectionEvent e) {
				listSelectC();
			}
		}
		void listSelectC() {
			selectListItem!(C)(_cards, cardsIndex, _editC, _area.cards);
		}
		void resizeImageC(FlexImage img, int x, int y, real scale) {
			auto card = _cardTbl[img];
			card.x = x;
			card.y = y;
			card.scale = scale;
			refreshControls();
			_comm.refMenuCard.call(card.cwxPath);
			callModEvent();
		}
		void selectImageC(FlexImage img) {
			__selectImage!(C)(img, _area.cards, _cardTbl, _editC, _cards);
		}
		void setAuto() {
			_undo ~= new UndoSPAuto(this, _comm, _area, _summ);
			__setAuto(true);
		}
		void setCustom() {
			_undo ~= new UndoSPAuto(this, _comm, _area, _summ);
			__setAuto(false);
		}
	}

	static if (UseBacks) {
		bool _viewBacks = true;
		BgImage[PileImage] _backTbl;
		int[BgImage] _editB;
		Table _backs;
		MenuItem _vbMenu;
		ToolItem _vbTMenu;
		ToolItem _maskTMenu;
		Spinner _wSpn, _hSpn;

		@property
		Table backList() {return _backs;}
		void editSpnBack(string T)(int value) {
			__editSpn!(T, BgImage)(value, _editB, 0);
			_imgp.redraw();
		}
		void enterSpnBack(string T, string N)(int value) {
			_undo ~= createUndoEdit();
			__enterSpn!(T, N, BgImage)(value, _editB, 0);
			_imgp.redraw();
		}
		int cancelSpnBack(string T)(int oldVal) {
			assert(_editB.length > 0);
			if (_editB.length > 1) {
				return 0;
			} else {
				assert(_editB.length == 1);
				return __cancelSpn!(T, BgImage)(_editB);
			}
		}
		class SBListener : SelectionAdapter {
			public override void widgetSelected(SelectionEvent e) {
				listSelectB();
			}
		}
		void listSelectB() {
			selectListItem!(BgImage)(_backs, 0, _editB, _area.backs);
		}
		void resizeImageB(FlexImage img, int x, int y, int w, int h) {
			auto back = _backTbl[img];
			back.x = x;
			back.y = y;
			back.width = w;
			back.height = h;
			refreshControls();
			_comm.refBgImage.call(back.cwxPath);
			callModEvent();
		}
		void selectImageB(FlexImage img) {
			__selectImage!(BgImage)(img, _area.backs, _backTbl, _editB, _backs);
		}
		void setMask() {
			_undo ~= createUndoEdit();
			foreach (back, i; _editB) {
				back.mask = _maskTMenu.getSelection();
				_imgp.images[i].transparent = back.mask;
				_imgp.images[i].createImage();
				_comm.refBgImage.call(back.cwxPath);
			}
			_imgp.redraw();
			callModEvent();
		}
	}

	void selectListItem(T)(Table list, int startIndex, ref int[T] edits, T[] cols) {
		int count = list.getItemCount();
		auto imgs = _imgp.images;
		typeof(edits) editsInit;
		edits = editsInit;
		for (int i = 0; i < count; i++) {
			auto img = cast(FlexImage) imgs[startIndex + i];
			bool o = img.selected;
			bool n = list.isSelected(i);
			if (n) {
				_imgp.select(img);
				edits[cols[i]] = i;
			} else {
				_imgp.deselect(img);
			}
		}
		static if (is(T == C)) {
			__refreshSelected(_viewCards, _cards, _editC, _area.cards, cardsIndex);
		} else {
			__refreshSelected(_viewBacks, _backs, _editB, _area.backs, 0);
		}
		refreshControls();
		_imgp.redraw();
		_comm.refreshToolBar();
	}

	void __editSpn(string T, B)(int value, int[B] edits, int startIndex) {
		foreach (i; edits.values) {
			auto a = cast(FlexImage) _imgp.images[startIndex + i];
			mixin (T);
		}
	}
	void __enterSpn(string T, string N, B)(int value, int[B] edits, int startIndex) {
		foreach (c, i; edits) {
			{
				auto a = c;
				mixin (T);
			}
			{
				auto a = cast(FlexImage) _imgp.images[startIndex + i];
				mixin (N);
				a.resize(false);
				static if (is(B : AbstractSpCard)) {
					_comm.refMenuCard.call(c.cwxPath);
				} else static if (is(B : BgImage)) {
					_comm.refBgImage.call(c.cwxPath);
				} else static assert (0);
			}
		}
		callModEvent();
	}
	int __cancelSpn(string T, B)(int[B] edits) {
		auto a = edits.keys[0];
		return mixin (T);
	}

	void editSpn(string T)(int value) {
		static if (UseCards) __editSpn!(T, C)(value, _editC, cardsIndex);
		static if (UseBacks) __editSpn!(T, BgImage)(value, _editB, 0);
		_imgp.redraw();
	}
	void enterSpn(string T, string N)(int value) {
		_undo ~= createUndoEdit();
		static if (UseCards) __enterSpn!(T, N, C)(value, _editC, cardsIndex);
		static if (UseBacks) __enterSpn!(T, N, BgImage)(value, _editB, 0);
		_imgp.redraw();
	}
	int cancelSpn(string T)(int oldVal) {
		static if (UseCards && UseBacks) {
			assert(_editC.length + _editB.length > 0);
			if (_editC.length + _editB.length > 1) {
				return oldVal;
			} else if (_editC.length == 1) {
				return __cancelSpn!(T, C)(_editC);
			} else {
				assert(_editB.length == 1);
				return __cancelSpn!(T, BgImage)(_editB);
			}
		} else static if (UseCards) {
			return cancelSpnCard!(T)(oldVal);
		} else static if (UseBacks) {
			return cancelSpnBack!(T)(oldVal);
		} else {
			static assert (0);
		}
	}

	void __selectImage(T)(FlexImage img, T[] cols, T[PileImage] tbl, ref int[T] edits, Table list) {
		auto c = tbl[img];
		foreach (int i, b; cols) {
			if (b is c) {
				if (img.selected) {
					list.setSelection(list.getSelectionIndices() ~ i);
					edits[b] = i;
				} else {
					list.deselect(i);
					edits.remove(b);
				}
				refreshControls();
				list.showSelection();
				return;
			}
		}
		assert(0);
	}

	int[] __refreshSelected(T)(bool view, Table list, ref int[T] edits, T[] cols, int startIndex) {
		int[] sels;
		foreach (key; edits.keys) {
			edits.remove(key);
		}
		for (int i = startIndex; i < startIndex + list.getItemCount(); i++) {
			auto fi = cast(FlexImage) _imgp.images[i];
			if (fi && view && fi.selected) {
				sels ~= i - startIndex;
				edits[cols[i - startIndex]] = i - startIndex;
			}
		}
		return sels;
	}
	static if (UseCards) {
		private void refreshCards() {
			_cards.setRedraw(false);
			scope (exit) _cards.setRedraw(true);
			auto idx = _cards.getSelectionIndices();
			auto cs = _area.cards;
			_cards.removeAll();
			foreach (i, c; cs) {
				auto itm = new TableItem(_cards, SWT.NONE);
				itm.setImage(_prop.images.cards);
				itm.setData(c);
				itm.setChecked(true);
				itm.setText(cardName(c));
			}
			_cards.setSelection(idx);
		}
	}
	static if (UseBacks) {
		private void refreshBacks() {
			_backs.setRedraw(false);
			scope (exit) _backs.setRedraw(true);
			auto idx = _backs.getSelectionIndices();
			auto cs = _area.backs;
			_backs.removeAll();
			foreach (i, c; cs) {
				auto itm = new TableItem(_backs, SWT.NONE);
				itm.setImage(_prop.images.backs);
				itm.setData(c);
				itm.setChecked(true);
				itm.setText(baseName(c.path));
			}
			_backs.setSelection(idx);
		}
	}
	static void upImpl2(T)(AbstractAreaView v, Table list, void delegate(int, int) swap, int startIndex, int[] indices, int count) {
		indices = indices.sort;
		if (!indices.length) return;
		if (indices[0] != 0) {
			foreach (j; 0 .. count) {
				foreach (i; indices) {
					i -= j;
					if (v) v._imgp.swap(i + startIndex - 1, i + startIndex);
					swap(i - 1, i);
					if (list) {
						auto itm1 = list.getItem(i - 1);
						auto itm2 = list.getItem(i);
						string temp = itm1.getText();
						itm1.setText(itm2.getText());
						itm2.setText(temp);
						auto dtemp = itm1.getData();
						itm1.setData(itm2.getData());
						itm2.setData(dtemp);
					}
				}
			}
		}
		if (v) v.callModEvent();
	}
	static void downImpl2(T)(AbstractAreaView v, Table list, void delegate(int, int) swap, int startIndex, int[] indices, int cardsCount, int count) {
		indices = indices.sort;
		if (!indices.length) return;
		if (indices[$ - 1] + 1 < cardsCount) {
			foreach (j; 0 .. count) {
				foreach_reverse (i; indices) {
					i += j;
					if (v) v._imgp.swap(i + startIndex + 1, i + startIndex);
					swap(i + 1, i);
					if (list) {
						auto itm1 = list.getItem(i + 1);
						auto itm2 = list.getItem(i);
						string temp = itm1.getText();
						itm1.setText(itm2.getText());
						itm2.setText(temp);
						auto dtemp = itm1.getData();
						itm1.setData(itm2.getData());
						itm2.setData(dtemp);
					}
				}
			}
		}
		if (v) v.callModEvent();
	}

	void __pos(int First, string Cmp, string Get, string Set, string CSet, T)(int startIndex, T[] cs) {
		int b = First;
		for (int i = startIndex; i < startIndex + cs.length; i++) {
			auto a = cast(FlexImage) _imgp.images[i];
			if (a.selected && mixin (Cmp)) {
				b = mixin (Get);
			}
		}
		for (int i = startIndex; i < startIndex + cs.length; i++) {
			auto a = cast(FlexImage) _imgp.images[i];
			if (a.selected) {
				mixin (Set ~ ";");
				a.resize();
				auto c = cs[i - startIndex];
				mixin (CSet ~ ";");
				static if (is(T : AbstractSpCard)) {
					_comm.refMenuCard.call(c.cwxPath);
				} else static if (is(T : BgImage)) {
					_comm.refBgImage.call(c.cwxPath);
				} else static assert (0);
			}
		}
		callModEvent();
	}
	void __posEven(string X, string Wid, string SetX, string XC, T)(int startIndex, T[] cs) {
		FlexImage[] targs;
		int right_w = int.min;
		scope int[FlexImage] indices;
		for (int i = 0; i < cs.length; i++) {
			auto a = cast(FlexImage) _imgp.images[i + startIndex];
			if (a.selected) {
				indices[a] = i;
				targs ~= a;
				int rw = mixin(X) + mixin (Wid);
				if (right_w < rw) right_w = rw;
			}
		}
		if (targs.length > 1) {
			bool ficmp(in FlexImage fi1, in FlexImage fi2) {
				int x1, x2;
				{
					auto a = fi1;
					x1 = mixin (X);
				}
				{
					auto a = fi2;
					x2 = mixin (X);
				}
				return x1 < x2;
			}
			targs = .sortDlg!(FlexImage)(targs, &ficmp);
			auto a = targs[0];
			int left = mixin (X);
			a = targs[$ - 1];
			int right = right_w - mixin (Wid);
			for (int i = 0; i < targs.length; i++) {
				a = targs[i];
				auto b = left + cast(int) rndtol(((right - left) / (targs.length - 1.0)) * i);
				mixin (SetX ~ ";");
				a.resize();
				auto c = cs[indices[a]];
				mixin (XC ~ ";");
				static if (is(T : AbstractSpCard)) {
					_comm.refMenuCard.call(c.cwxPath);
				} else static if (is(T : BgImage)) {
					_comm.refBgImage.call(c.cwxPath);
				} else static assert (0);
			}
		}
		callModEvent();
	}
	static if (UseCards) {
		private void __scaleC(real s) {
			int scale = cast(int) rndtol(s * 100);
			foreach (i, c; _area.cards) {
				auto fi = cast(FlexImage) _imgp.images[cardsIndex + i];
				if (fi.selected) {
					c.scale = scale;
					fi.scale = s;
					fi.resize();
				}
				_comm.refMenuCard.call(c.cwxPath);
			}
			refreshControls();
			_imgp.redraw();
			callModEvent();
		}
		private void __scaleCMax() {
			__scaleC(_prop.looks.cardSizeMax);
		}
		private void __scaleCMiddle() {
			__scaleC(1.0);
		}
		private void __scaleCMin() {
			__scaleC(_prop.looks.cardSizeMin);
		}
	}
	void __scaleEven(int First, string Cmp, string CSet, T)(int startIndex, T[] cs) {
		int w = First;
		int h = First;
		for (int i = 0; i < cs.length; i++) {
			auto fi = cast(FlexImage) _imgp.images[startIndex + i];
			if (fi.selected) {
				int a, b;
				a = fi.width;
				b = w;
				if (mixin (Cmp)) w = a;
				a = fi.height;
				b = h;
				if (mixin (Cmp)) h = a;
			}
		}
		for (int i = 0; i < cs.length; i++) {
			auto fi = cast(FlexImage) _imgp.images[startIndex + i];
			if (fi.selected) {
				fi.newWidth = w;
				fi.newHeight = h;
				fi.resize();
				auto a = cs[i];
				mixin (CSet);
				_comm.refMenuCard.call(a.cwxPath);
			}
		}
		callModEvent();
	}
	void __posTop(T)(int startIndex, T[] cs) {
		__pos!(int.max, "a.y < b", "a.y", "a.newY = b", "c.y = a.y", T)(startIndex, cs);
	}
	void __posBottom(T)(int startIndex, T[] cs) {
		__pos!(int.min, "a.y + a.height > b", "a.y + a.height", "a.newY = b - a.height", "c.y = a.y", T)(startIndex, cs);
	}
	void __posLeft(T)(int startIndex, T[] cs) {
		__pos!(int.max, "a.x < b", "a.x", "a.newX = b", "c.x = a.x", T)(startIndex, cs);
	}
	void __posRight(T)(int startIndex, T[] cs) {
		__pos!(int.min, "a.x + a.width > b", "a.x + a.width", "a.newX = b - a.width", "c.x = a.x", T)(startIndex, cs);
	}
	void __posEven(T)(int startIndex, T[] cs) {
		__posEven!("a.x", "a.width", "a.newX = b", "c.x = b", T)(startIndex, cs);
	}
	void posTop() {
		_undo ~= createUndoEdit();
		static if (UseCards) __posTop!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posTop!(BgImage)(0, _area.backs);
		refreshControls();
		_imgp.redraw();
	}
	void posBottom() {
		_undo ~= createUndoEdit();
		static if (UseCards) __posBottom!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posBottom!(BgImage)(0, _area.backs);
		refreshControls();
		_imgp.redraw();
	}
	void posLeft() {
		_undo ~= createUndoEdit();
		static if (UseCards) __posLeft!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posLeft!(BgImage)(0, _area.backs);
		refreshControls();
		_imgp.redraw();
	}
	void posRight() {
		_undo ~= createUndoEdit();
		static if (UseCards) __posRight!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posRight!(BgImage)(0, _area.backs);
		refreshControls();
		_imgp.redraw();
	}
	void posEven() {
		_undo ~= createUndoEdit();
		static if (UseCards) __posEven!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posEven!(BgImage)(0, _area.backs);
		refreshControls();
		_imgp.redraw();
	}
	static if (UseCards) {
		void __scaleEvenC(int First, string Cmp)() {
			__scaleEven!(First, Cmp, "a.scale = cast(int) rndtol(cast(real) fi.baseWidth / w);", C)(cardsIndex, _area.cards);
		}
	}
	static if (UseBacks) {
		void __scaleEvenB(int First, string Cmp)() {
			__scaleEven!(First, Cmp, "a.width = w, a.height = h;", BgImage)(0, _area.backs);
		}
	}
	void scaleEvenBig() {
		_undo ~= createUndoEdit();
		static if (UseCards) __scaleEvenC!(int.min, "a > b")();
		static if (UseBacks) __scaleEvenB!(int.min, "a > b")();
		refreshControls();
		_imgp.redraw();
	}
	void scaleEvenSmall() {
		_undo ~= createUndoEdit();
		static if (UseCards) __scaleEvenC!(int.max, "a < b")();
		static if (UseBacks) __scaleEvenB!(int.max, "a < b")();
		refreshControls();
		_imgp.redraw();
	}
	class IPEditListener : MouseAdapter {
		override void mouseDoubleClick(MouseEvent e) {
			if (e.button == 1) {
				int i = _imgp.findSelectedIndex(e.x, e.y);
				if (i >= 0) {
					editImagePane([i]);
				}
			}
		}
	}
	void edit() {
		editImagePane(_imgp.selectedIndices);
	}
	void editImagePane(int[] indices) {
		int[] cs;
		int[] bs;
		foreach (i; indices) {
			static if (UseCards && UseBacks) {
				if (i >= cardsIndex) {
					cs ~= i - cardsIndex;
				} else {
					bs ~= i;
				}
			} else static if (UseCards) {
				cs ~= i - cardsIndex;
			} else static if (UseBacks) {
				bs ~= i;
			} else {
				static assert (0);
			}
		}
		static if (UseCards) {
			editCard(cs);
		}
		static if (UseBacks) {
			editBack(bs);
		}
	}
	void refreshWallpaper() {
		_imgp.setBackgroundImage(_comm.wallpaper);
		if (_prop.var.etc.wallpaperStyle < WallpaperStyle.min || WallpaperStyle.max < _prop.var.etc.wallpaperStyle) {
			_prop.var.etc.wallpaperStyle = WallpaperStyle.Tile;
		}
		_imgp.wallpaperStyle = cast(WallpaperStyle) _prop.var.etc.wallpaperStyle;
	}
	Control createImagePane(Composite parent) {
		auto sc = new ScrolledComposite(parent, SWT.H_SCROLL | SWT.V_SCROLL);
		sc.setExpandHorizontal(false);
		sc.setExpandVertical(false);
		auto vs = _prop.looks.viewSize;
		sc.getHorizontalBar().setIncrement(vs.width / 20);
		sc.getVerticalBar().setIncrement(vs.height / 20);
		sc.getHorizontalBar().setPageIncrement(vs.width / 5);
		sc.getVerticalBar().setPageIncrement(vs.height / 5);
		sc.setLayoutData(new GridData(GridData.FILL_BOTH));
		_imgp = new ImagePane(sc, SWT.BORDER | SWT.NO_BACKGROUND);
		static if (RefCards) {
			listener(_imgp, SWT.Dispose, {
				foreach (a; _imgp.appends) {
					a.dispose();
				}
			});
		}
		auto rgb = new RGB(_prop.var.etc.wallColorR,
			_prop.var.etc.wallColorG,
			_prop.var.etc.wallColorB);
		auto color = new Color(Display.getCurrent(), rgb);
		_imgp.setBackgroundColor(color);
		_comm.refWallpaper.add(&refreshWallpaper);
		_imgp.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_imgp.setBackgroundImage(cast(Image) null);
				_comm.refWallpaper.remove(&refreshWallpaper);
			}
		});
		refreshWallpaper();
		sc.setContent(_imgp);
		auto rect = _imgp.computeSize(vs.width, vs.height);
		sc.setMinSize(rect.x, rect.y);
		_imgp.setSize(rect.x, rect.y);
		auto ipe = new IPEditListener;
		_imgp.addMouseListener(ipe);
		_imgp.changingImages(&changingImages);
		{
			auto menu = new Menu(parent.getShell(), SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.EditProp, &edit, () => _imgp.selectedIndex != -1);
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_comm, menu, _tcpd, true, true, true, true);
			static if (is(A : Area)) {
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.EditEvent, &openEvent, null);
			} else static if (is(A : Battle)) {
				new MenuItem(menu, SWT.SEPARATOR);
				auto itm = createMenuItem(_comm, menu, MenuID.EditEvent, &openEvent, null);
				itm.setImage(_prop.images.editEventBattle);
			}
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.PosTop, &posTop, () => _imgp.selectedIndex >= 2);
			createMenuItem(_comm, menu, MenuID.PosBottom, &posBottom, () => _imgp.selectedIndex >= 2);
			createMenuItem(_comm, menu, MenuID.PosLeft, &posLeft, () => _imgp.selectedIndex >= 2);
			createMenuItem(_comm, menu, MenuID.PosRight, &posRight, () => _imgp.selectedIndex >= 2);
			createMenuItem(_comm, menu, MenuID.PosEven, &posEven, () => _imgp.selectedIndex >= 2);
			static if (UseCards) {
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.ScaleMin, &__scaleCMin, () => _imgp.selectedIndex >= 2);
	 			createMenuItem(_comm, menu, MenuID.ScaleMiddle, &__scaleCMiddle, () => _imgp.selectedIndex >= 2);
				createMenuItem(_comm, menu, MenuID.ScaleMax, &__scaleCMax, () => _imgp.selectedIndex >= 2);
			}
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.ScaleBig, &scaleEvenBig, () => _imgp.selectedIndex >= 2);
			createMenuItem(_comm, menu, MenuID.ScaleSmall, &scaleEvenSmall, () => _imgp.selectedIndex >= 2);
			_imgp.setMenu(menu);
		}
		_imgp.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				auto pane = cast(ImagePane) e.widget;
				auto img = pane.getBackgroundImage();
				if (img) img.dispose();
				auto color = pane.getBackgroundColor();
				if (color) color.dispose();
			}
		});
		return sc;
	}
	void changingImages() {
		_undo ~= createUndoEdit();
		_comm.refreshToolBar();
	}

	void refreshControls() {
		string f = null;
		if (_flag) _flag.setText(_flag.getItem(0));
		void flag(string f2) {
			if (!_flag) return;
			if (!f) {
				f = f2;
				if ("" != f2) {
					_flag.setText(f2);
				}
			} else if (f != f2) {
				_flag.setText("");
			}
		}
		static if (UseCards) {
			foreach (c; _editC.keys) {
				flag(c.flag);
			}
		}
		static if (UseBacks) {
			foreach (b; _editB.keys) {
				flag(b.flag);
			}
		}
		static if (UseCards && UseBacks) {
			if (_flag) _flag.setEnabled(_editC.length || _editB.length);
			_xSpn.setEnabled(_editC.length || _editB.length);
			_ySpn.setEnabled(_xSpn.getEnabled());
			_wSpn.setEnabled(_editB.length > 0);
			_hSpn.setEnabled(_wSpn.getEnabled());
			_maskTMenu.setEnabled(_wSpn.getEnabled());
			_scaleSpn.setEnabled(_editC.length > 0);
			if (_editC.length == 1) {
				auto card = _editC.keys[0];
				_scaleSpn.setSelection(cast(int) rndtol(card.scale * 100.0));
				if (_editB.length == 0) {
					_xSpn.setSelection(card.x);
					_ySpn.setSelection(card.y);
				}
			} else if (_editC.length > 1) {
				_scaleSpn.setSelection(spnValue!("cast(int) rndtol(a.scale * 100.0)", C, int)(_editC.keys, 100));
			}
			if (_editB.length == 1) {
				auto back = _editB.keys[0];
				_wSpn.setSelection(back.width);
				_hSpn.setSelection(back.height);
				_maskTMenu.setSelection(back.mask);
				if (_editC.length == 0) {
					_xSpn.setSelection(back.x);
					_ySpn.setSelection(back.y);
				}
			} else if (_editB.length > 1) {
				_wSpn.setSelection(spnValue!("a.width", BgImage, int)(_editB.keys, 0));
				_hSpn.setSelection(spnValue!("a.height", BgImage, int)(_editB.keys, 0));
				_maskTMenu.setSelection(spnValue!("a.mask", BgImage, bool)(_editB.keys, 0));
			}
			if (_editC.length + _editB.length > 1) {
				if (_editC.length == 0) {
					_xSpn.setSelection(spnValue!("a.x", BgImage, int)(_editB.keys, 0));
					_ySpn.setSelection(spnValue!("a.y", BgImage, int)(_editB.keys, 0));
				} else if (_editB.length == 0) {
					_xSpn.setSelection(spnValue!("a.x", C, int)(_editC.keys, 0));
					_ySpn.setSelection(spnValue!("a.y", C, int)(_editC.keys, 0));
				} else {
					int x = spnValue!("a.x", C, int)(_editC.keys, 0);
					_xSpn.setSelection(x == spnValue!("a.x", BgImage, int)(_editB.keys, 0) ? x : 0);
					int y = spnValue!("a.y", C, int)(_editC.keys, 0);
					_ySpn.setSelection(y == spnValue!("a.y", BgImage, int)(_editB.keys, 0) ? y : 0);
				}
			}
		} else static if (UseCards) {
			if (_flag) _flag.setEnabled(_editC.length > 0);
			bool enbl = _editC.length > 0;
			_xSpn.setEnabled(enbl);
			_ySpn.setEnabled(enbl);
			_scaleSpn.setEnabled(enbl);
			static if (is (C == EnemyCard)) {
				_escTMenu.setEnabled(enbl);
			}
			if (_editC.length == 1) {
				auto card = _editC.keys[0];
				_xSpn.setSelection(card.x);
				_ySpn.setSelection(card.y);
				_scaleSpn.setSelection(cast(int) rndtol(card.scale * 100.0));
				static if (is (C == EnemyCard)) {
					_escTMenu.setSelection(card.escape);
				}
			} else if (_editC.length > 1) {
				_xSpn.setSelection(spnValue!("a.x", C, int)(_editC.keys, 0));
				_ySpn.setSelection(spnValue!("a.y", C, int)(_editC.keys, 0));
				_scaleSpn.setSelection(spnValue!("cast(int) rndtol(a.scale * 100.0)", C, int)(_editC.keys, 100));
				static if (is (C == EnemyCard)) {
					_escTMenu.setSelection(spnValue!("a.escape", C, bool)(_editC.keys, false));
				}
			}
		} else static if (UseBacks) {
			if (_flag) _flag.setEnabled(_editB.length > 0);
			bool enbl = _editB.length > 0;
			_xSpn.setEnabled (enbl);
			_ySpn.setEnabled (enbl);
			_wSpn.setEnabled (enbl);
			_hSpn.setEnabled (enbl);
			_maskTMenu.setEnabled(enbl);
			if (_editB.length == 1) {
				auto back = _editB.keys[0];
				_xSpn.setSelection(back.x);
				_ySpn.setSelection(back.y);
				_wSpn.setSelection(back.width);
				_hSpn.setSelection(back.height);
				_maskTMenu.setSelection(back.mask);
			} else if (_editB.length > 1) {
				_xSpn.setSelection(spnValue!("a.x", BgImage, int)(_editB.keys, 0));
				_ySpn.setSelection(spnValue!("a.y", BgImage, int)(_editB.keys, 0));
				_wSpn.setSelection(spnValue!("a.width", BgImage, int)(_editB.keys, 0));
				_hSpn.setSelection(spnValue!("a.height", BgImage, int)(_editB.keys, 0));
				_maskTMenu.setSelection(spnValue!("a.mask", BgImage, bool)(_editB.keys, false));
			}
		} else {
			static assert (0);
		}
		refreshStatusLine();
		_comm.refreshToolBar();
	}
	void refreshStatusLine() {
		string line = "";
		string flag(string path) {
			if (!path.length) return _prop.msgs.areaViewStatusNoFlag;
			if (_summ) {
				auto f = _summ.flagDirRoot.findFlag(path);
				if (f) return .tryFormat(_prop.msgs.areaViewStatusWithFlag, path);
			}
			return .tryFormat(_prop.msgs.areaViewStatusInvalidFlag, path);
		}
		static if (is(C : MenuCard)) {
			string cardName = _prop.msgs.menuCard;
			string path(in C card) {
				string path = card.path;
				if (!path.length) return _prop.msgs.noSelectImage;
				if (isBinImg(path)) return _prop.msgs.areaViewStatusImageIncluding;
				if (!_comm.skin.findImagePath(path, _summ ? _summ.scenarioPath : "").length) {
					return .tryFormat(_prop.msgs.noImage, encodePath(path));
				}
				return encodePath(path);
			}
		} else static if (is(C : EnemyCard)) {
			string cardName = _prop.msgs.enemyCard;
			string path(in C card) {
				if (_summ) {
					if (0 == card.id) return _prop.msgs.noSelectCast;
					auto c = _summ.cwCast(card.id);
					if (!c) return .tryFormat(_prop.msgs.noCast, card.id);
					return .tryFormat(_prop.msgs.areaViewStatusEnemyCard, c.id, c.name);
				}
				assert (0);
			}
		}
		static if (UseCards) {
			void putOneCard(in C card) {
				if (_summ) {
					line = .tryFormat(_prop.msgs.areaViewStatus, cardName, path(card), flag(card.flag));
				} else {
					line = .tryFormat(_prop.msgs.areaViewStatusNoSummary, cardName, path(card));
				}
			}
		}
		static if (UseBacks) {
			void putOneBack(in BgImage back) {
				string path = encodePath(back.path);
				if (!path.length) {
					path = _prop.msgs.noSelectImage;
				} else if (!_comm.skin.findImagePath(path, _summ ? _summ.scenarioPath : "").length) {
					path = .tryFormat(_prop.msgs.noImage, encodePath(path));
				}
				if (_summ) {
					line = .tryFormat(_prop.msgs.areaViewStatus, _prop.msgs.back, path, flag(back.flag));
				} else {
					line = .tryFormat(_prop.msgs.areaViewStatusNoSummary, _prop.msgs.back, path);
				}
			}
		}
		static if (UseCards && UseBacks) {
			if (_editC.length == 1 && !_editB.length) {
				putOneCard(_editC.keys[0]);
			} else if (!_editC.length && _editB.length == 1) {
				putOneBack(_editB.keys[0]);
			} else if (_editC.length + _editB.length) {
				if (_editC.length) {
					line = .tryFormat(_prop.msgs.areaViewStatusSelCard, _editC.length);
				}
				if (_editB.length) {
					if (line.length) line ~= " ";
					line ~= .tryFormat(_prop.msgs.areaViewStatusSelBack, _editB.length);
				}
			}
		} else static if (UseCards) {
			if (1 == _editC.length) {
				putOneCard(_editC.keys[0]);
			} else if (1 < _editC.length) {
				line = .tryFormat(_prop.msgs.areaViewStatusSelCard, _editC.length);
			}
		} else static if (UseBacks) {
			if (1 == _editB.length) {
				putOneBack(_editB.keys[0]);
			} else if (1 < _editB.length) {
				line = .tryFormat(_prop.msgs.areaViewStatusSelBack, _editB.length);
			}
		}
		statusLine = line;
	}
	static if (UseCards) {
		static int staticCardsIndex(A area) {
			static if (UseBacks) {
				return area.backs.length;
			} else {
				return 0;
			}
		}
		@property
		int cardsIndex() {
			return staticCardsIndex(_area);
		}
	}

	void refreshSelected() {
		static if (UseCards) {
			int[] selsC = __refreshSelected(_viewCards, _cards, _editC, _area.cards, cardsIndex);
			_cards.setSelection(selsC);
		}
		static if (UseBacks) {
			int[] selsB = __refreshSelected(_viewBacks, _backs, _editB, _area.backs, 0);
			_backs.setSelection(selsB);
		}
		refreshControls();
	}

	class MKListener(C) : MouseAdapter {
		private void delegate(int[]) _edit;
		private C[] delegate() _items;
		this(void delegate(int[]) edit, C[] delegate() items) {
			_edit = edit;
			_items = items;
		}
		private void edit(TypedEvent e) {
			auto l = cast(Table) e.widget;
			_edit(l.getSelectionIndices());
		}
		override void mouseDoubleClick(MouseEvent e) {
			if (e.button == 1) {
				edit(e);
			}
		}
	}
	Table createList(C)(Composite parent, string name, Image image, TCPD tcpd,
			void delegate(int[]) edit, C[] delegate() items) {
		auto comp = new Composite(parent, SWT.NONE);
		comp.setLayout(zeroGridLayout(1));
		auto label = new CLabel(comp, SWT.NONE);
		label.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		label.setText(name);
		label.setImage(image);
		auto list = new Table(comp, SWT.MULTI | SWT.CHECK | SWT.BORDER | SWT.H_SCROLL | SWT.V_SCROLL);
		new FullTableColumn(list, SWT.NONE);
		auto mkl = new MKListener!(C)(edit, items);
		auto closePreview = new ClosePreview;
		list.getVerticalBar().addSelectionListener(closePreview);
		list.getHorizontalBar().addSelectionListener(closePreview);
		list.addSelectionListener(new VCheckListener);
		list.addMouseListener(mkl);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = 0;
		gd.heightHint = 0;
		list.setLayoutData(gd);
		{
			auto menu = new Menu(parent.getShell(), SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.EditProp, {
				edit(list.getSelectionIndices());
			}, () => list.getSelectionIndex() != -1);
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_comm, menu, tcpd, true, true, true, true);
			static if ((is(A : Area) || is(A : Battle)) && is(C : AbstractSpCard)) {
				new MenuItem(menu, SWT.SEPARATOR);
				static if (is(A : Area)) {
					createMenuItem(_comm, menu, MenuID.EditEvent, &openEvent, null);
				} else static if (is(A : Battle)) {
					auto itm = createMenuItem(_comm, menu, MenuID.EditEvent, &openEvent, null);
					itm.setImage(_prop.images.editEventBattle);
				} else static assert (0);
			}
			list.setMenu(menu);
		}
		return list;
	}
	static if (UseCards) {
		void __setAuto(bool value) {
			_area.spAuto = value;
			if (_autoMenu) _autoMenu.setSelection(value);
			if (_autoTMenu) _autoTMenu.setSelection(value);
			if (_customMenu) _customMenu.setSelection(!value);
			if (_customTMenu) _customTMenu.setSelection(!value);
			callModEvent();
		}
	}
	class VCheckListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			static if (UseCards) {
				foreach (i, itm; _cards.getItems()) {
					_imgp.images[cardsIndex + i].visible = _viewCards && itm.getChecked();
				}
			}
			static if (UseBacks) {
				foreach (i, itm; _backs.getItems()) {
					_imgp.images[i].visible = _viewBacks && itm.getChecked();
				}
			}
		}
	}
	void openFlagView() {
		if (-1 == _flag.getSelectionIndex()) return;
		auto flag = _summ.flagDirRoot.findFlag(_flag.getText());
		if (!flag) return;
		try {
			_comm.openCWXPath(flag.cwxPath, false);
		} catch (Exception e) {
			debugln(e);
		}
	}

	private TopLevelPanel _tlp;
public:
	this(Commons comm, Props prop, Summary summ, A area, Composite parent, TopLevelPanel tlp, UndoManager undo) {
		super(parent, SWT.NONE);
		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime());
		auto gl = windowGridLayout(1);
		gl.marginWidth = 0;
		gl.marginHeight = 0;
		setLayout(gl);
		_prop = prop;
		_summ = summ;
		_area = area;
		_comm = comm;
		_undo = undo;
		_tlp = tlp;
		_comm.refSkin.add(&refresh);
		_comm.delPaths.add(&refresh);
		_comm.replPath.add(&refreshR);
		_comm.replText.add(&replText);
		_comm.replID.add(&replText);
		static if (UseCards) {
			_comm.refCardState.add(&refreshCardState);
		}
		_preview = new Preview(_prop, parent.getShell());
		addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_preview.dispose();
				_comm.refSkin.remove(&refresh);
				_comm.delPaths.remove(&refresh);
				_comm.replPath.remove(&refreshR);
				_comm.replText.remove(&replText);
				_comm.replID.remove(&replText);
				static if (UseCards) {
					_comm.refCardState.remove(&refreshCardState);
					foreach (dlg; _editDlgsC.values) {
						dlg.forceCancel();
					}
				}
				static if (UseBacks) {
					foreach (dlg; _editDlgsB.values) {
						dlg.forceCancel();
					}
				}
			}
		});
		static if (is (C == EnemyCard) || RefCards) {
			_comm.refCast.add(&__refreshCast);
			_comm.delCast.add(&__deleteCast);
			addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) {
					_comm.refCast.remove(&__refreshCast);
					_comm.delCast.remove(&__deleteCast);
				}
			});
		}
		static if (is (A == Area)) {
			_viewMsg = _prop.var.etc.viewMessageArea;
			_viewParty = _prop.var.etc.viewPartyCardsArea;
			_fixed = _prop.var.etc.fixedImagesArea;
		} else static if (is (A == Battle)) {
			_viewMsg = _prop.var.etc.viewMessageBattle;
			_viewParty = _prop.var.etc.viewPartyCardsBattle;
			_fixed = _prop.var.etc.fixedImagesBattle;
		} else static if (is (A == BgImageContainer)) {
			_viewMsg = _prop.var.etc.viewMessageEvent;
			_viewParty = _prop.var.etc.viewPartyCardsEvent;
			_fixed = _prop.var.etc.fixedImagesEvent;
		} else {
			static assert (0);
		}
		static if (is(C : EnemyCard) || RefCards) {
			_dbgMode = _prop.var.etc.viewEnemyCardDebug;
		}
		addDisposeListener(new class DisposeListener {
			public override void widgetDisposed(DisposeEvent e) {
				static if (is (A == Area)) {
					_prop.var.etc.viewMessageArea = _viewMsg;
					_prop.var.etc.viewPartyCardsArea = _viewParty;
					_prop.var.etc.fixedImagesArea = _fixed;
				} else static if (is (A == Battle)) {
					_prop.var.etc.viewMessageBattle = _viewMsg;
					_prop.var.etc.viewPartyCardsBattle = _viewParty;
					_prop.var.etc.fixedImagesBattle = _fixed;
				} else static if (is (A == BgImageContainer)) {
					_prop.var.etc.viewMessageEvent = _viewMsg;
					_prop.var.etc.viewPartyCardsEvent = _viewParty;
					_prop.var.etc.fixedImagesEvent = _fixed;
				} else {
					static assert (0);
				}
				static if (RefCards) {
					_prop.var.etc.viewReferenceCards = _imgp.showAppends;
				}
				static if (is(C : EnemyCard) || RefCards) {
					_prop.var.etc.viewEnemyCardDebug = _dbgMode;
				}
			}
		});
		static if (UseCards && UseBacks) {
			_viewCards = _prop.var.etc.viewCards;
			_viewBacks = _prop.var.etc.viewBgImages;
			addDisposeListener(new class DisposeListener {
				public override void widgetDisposed(DisposeEvent e) {
					_prop.var.etc.viewCards = _viewCards;
					_prop.var.etc.viewBgImages = _viewBacks;
				}
			});
		}
		static if (UseCards) {
			auto ctcpd = new CardTCPD;
		}
		static if (UseBacks) auto btcpd = new BgImageTCPD;
		static if (UseCards && UseBacks) {
			_tcpd = new AllTCPD;
		} else static if (UseCards) {
			_tcpd = ctcpd;
		} else static if (UseBacks) {
			_tcpd = btcpd;
		} else {
			static assert (0);
		}

		if (_tlp) setupTLP(_tlp);
		auto toolbar = new ToolBar(this, SWT.FLAT);
		_comm.put(toolbar);
		toolbar.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

		auto lrSash = new SplitPane(this, SWT.HORIZONTAL);
		lrSash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto left = new Composite(lrSash, SWT.NONE);
		{
			auto lgl = zeroMarginGridLayout(2, false);
			lgl.verticalSpacing = WGL_SPACING;
			left.setLayout(lgl);
		}
		{
			Composite listsP;
			static if (UseCards && UseBacks) {
				_sash = new SplitPane(left, SWT.VERTICAL);
				listsP = _sash;
			} else {
				listsP = new Composite(left, SWT.NONE);
				listsP.setLayout(new FillLayout);
			}
			auto lpgd = new GridData(GridData.FILL_BOTH);
			lpgd.horizontalSpan = 2;
			listsP.setLayoutData(lpgd);
			auto prevTrig = new PreviewTrigger;
			static if (UseCards) {
				static if (is (C == MenuCard)) {
					_cards = createList(listsP, prop.msgs.menuCards,
						prop.images.cards, ctcpd, &editCard, &_area.cards);
					new TableTextEdit(_comm, _prop, _cards, 0, &nameEditEnd);
				} else static if (is (C == EnemyCard)) {
					_cards = createList(listsP, prop.msgs.enemyCards,
						prop.images.cards, ctcpd, &editCard, &_area.cards);
					new TableComboEdit!CCombo(_comm, _prop, _cards, 0, &createEnemyCombo, &enemyEditEnd);
				}
				_cards.addSelectionListener(new SCListener);
				static if (is (C == MenuCard)) {
					auto target = new DropTarget(_cards, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_LINK);
					target.setTransfer([cast(Transfer) FileTransfer.getInstance(), XMLBytesTransfer.getInstance()]);
					target.addDropListener(new CLDropTarget);
				}
				_cards.addMouseTrackListener(prevTrig);
				_cards.addMouseMoveListener(prevTrig);
			}
			static if (UseBacks) {
				_backs = createList(listsP, prop.msgs.backs,
					prop.images.backs, btcpd, &editBack, &_area.backs);
				_backs.addSelectionListener(new SBListener);
				new TableComboEdit!CCombo(_comm, _prop, _backs, 0, &createBgImageCombo, &bgImageEditEnd);
				auto backDrop = new DropTarget(_backs, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_LINK);
				backDrop.setTransfer([cast(Transfer) FileTransfer.getInstance(), XMLBytesTransfer.getInstance()]);
				backDrop.addDropListener(new BLDropTarget);
				_backs.addMouseTrackListener(prevTrig);
				_backs.addMouseMoveListener(prevTrig);
			}
			static if (UseCards && UseBacks) {
				_cards.addMouseListener(new class MouseAdapter {
					override void mouseDown(MouseEvent e) {
						if (e.button == 1 && (e.stateMask & SWT.CTRL) == 0 && (e.stateMask & SWT.SHIFT) == 0) {
							_imgp.deselectRange(0, _area.backs.length);
							_backs.deselectAll();
							typeof(_editB) editB;
							_editB = editB;
							refreshControls();
						}
					}
				});
				_backs.addMouseListener(new class MouseAdapter {
					override void mouseDown(MouseEvent e) {
						if (e.button == 1 && (e.stateMask & SWT.CTRL) == 0 && (e.stateMask & SWT.SHIFT) == 0) {
							_imgp.deselectRange(cardsIndex, cardsIndex + _area.cards.length);
							_cards.deselectAll();
							typeof(_editC) editC;
							_editC = editC;
							refreshControls();
						}
					}
				});
				_sash.setWeights([_prop.var.etc.areaSashT, _prop.var.etc.areaSashB]);
			}
			static if (UseCards && UseBacks) {
				_sash.addDisposeListener(new class DisposeListener {
					override void widgetDisposed(DisposeEvent e) {
						_prop.var.etc.areaSashT = _sash.getWeights()[0];
						_prop.var.etc.areaSashB = _sash.getWeights()[1];
					}
				});
			}
		}
		if (_summ) {
			auto lFlag = new Label(left, SWT.NONE);
			lFlag.setText(_prop.msgs.areaViewFlagDesc);
			_flag = new Combo(left, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			_flag.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			_flag.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_flag.add(_prop.msgs.noFlagRef);
			refreshFlag();
			_flag.addSelectionListener(new SelFlag);
			_comm.refFlagAndStep.add(&refFlag);
			_comm.delFlagAndStep.add(&refFlag);
			_flag.addDisposeListener(new FlagsDispose);
			{
				auto menu = new Menu(_flag.getShell(), SWT.POP_UP);
				createMenuItem(_comm, menu, MenuID.OpenAtVarView, &openFlagView, () => _flag.getSelectionIndex() > 0);
				_flag.setMenu(menu);
			}
			static if (RefCards) {
				auto lRef = new Label(left, SWT.NONE);
				lRef.setText(_prop.msgs.areaViewRefAreaDesc);
				_refAreas = new Combo(left, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
				_refAreas.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				_refAreas.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_refAreas.add(_prop.msgs.noRefArea);
				listener(_refAreas,  SWT.Selection, {
					int sel = _refAreas.getSelectionIndex();
					_refTarget = sel <= 0 ? null : _refAreasArr[sel - 1];
					if (!_refTarget) {
						foreach (a; _imgp.appends) {
							a.dispose();
						}
						_imgp.appends = [];
					}
					refreshPanel();
				});
				{
					auto menu = new Menu(_refAreas.getShell(), SWT.POP_UP);
					createMenuItem(_comm, menu, MenuID.OpenAtTableView, &openRefAreaView, () => _refAreas.getSelectionIndex() > 0);
					_refAreas.setMenu(menu);
				}
				_comm.refArea.add(&refreshRefAreasA);
				_comm.delArea.add(&refreshRefAreasA);
				_comm.refBattle.add(&refreshRefAreasB);
				_comm.delBattle.add(&refreshRefAreasB);
				_comm.refMenuCard.add(&refRefMenuCard);
				_comm.addMenuCard.add(&addRefMenuCard);
				_comm.delMenuCard.add(&delRefMenuCard);
				_comm.upMenuCard.add(&upRefMenuCards);
				_comm.downMenuCard.add(&downRefMenuCards);
				listener(_refAreas, SWT.Dispose, {
					_comm.refArea.remove(&refreshRefAreasA);
					_comm.delArea.remove(&refreshRefAreasA);
					_comm.refBattle.remove(&refreshRefAreasB);
					_comm.delBattle.remove(&refreshRefAreasB);
					_comm.refMenuCard.remove(&refRefMenuCard);
					_comm.addMenuCard.remove(&addRefMenuCard);
					_comm.delMenuCard.remove(&delRefMenuCard);
					_comm.upMenuCard.remove(&upRefMenuCards);
					_comm.downMenuCard.remove(&downRefMenuCards);
				});
			}
		}
		{
			createImagePane(lrSash);
			static if (is (C == MenuCard) || UseBacks) {
				auto target = new DropTarget(_imgp, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_LINK);
				static if (is (C == MenuCard)) {
					target.setTransfer([cast(Transfer) FileTransfer.getInstance(), XMLBytesTransfer.getInstance()]);
				} else {
					target.setTransfer([FileTransfer.getInstance()]);
				}
				target.addDropListener(new IPDropTarget);
			}
			static if (UseBacks) appendBgImages(0, area.backs, false, false);
			static if (UseCards) appendCards(0, area.cards, false, false);
			appendPartyCards();
			static if (RefCards) {
				_imgp.showAppends = _prop.var.etc.viewReferenceCards;
			}
		}
		setupToolBar(toolbar);
		static if (is(A : Battle) && is(C : EnemyCard)) {
			{
				auto target = new DropTarget(imagePane, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_LINK);
				target.setTransfer([XMLBytesTransfer.getInstance()]);
				target.addDropListener(new DTListener);
			}
			{
				auto target = new DropTarget(cardList, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_LINK);
				target.setTransfer([XMLBytesTransfer.getInstance()]);
				target.addDropListener(new DTListener);
			}
		}
		static if (UseCards) {
			auto cardDrag = new DragSource(_cards, DND.DROP_LINK | DND.DROP_COPY);
			cardDrag.setTransfer([XMLBytesTransfer.getInstance()]);
			cardDrag.addDragListener(new CardDrag);
		}
		static if (UseBacks) {
			auto backDrag = new DragSource(_backs, DND.DROP_LINK | DND.DROP_COPY);
			backDrag.setTransfer([XMLBytesTransfer.getInstance()]);
			backDrag.addDragListener(new BackDrag);
		}

		lrSash.setWeights([_prop.var.etc.areaViewL, _prop.var.etc.areaViewR]);
		lrSash.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				auto ws = (cast(SplitPane) e.widget).getWeights();
				_prop.var.etc.areaViewL = ws[0];
				_prop.var.etc.areaViewR = ws[1];
			}
		});
		static if (UseCards) refreshCards();
		static if (UseBacks) refreshBacks();
		static if (RefCards) {
			refreshRefAreas();
		}
	}
	private string _statusLine;
	@property
	private void statusLine(string statusLine) {
		_statusLine = statusLine;
		_comm.setStatusLine(_imgp, statusLine);
	}
	@property
	string statusLine() {return _statusLine;}

	@property
	A area() {
		return _area;
	}
	@property
	Summary summary() {
		return _summ;
	}
	static if (is(A : Area) || is(A : Battle)) {
		void openEvent() {
			if (!_summ) return;
			string path;
			auto i = _cards.getSelectionIndex();
			if (-1 != i) {
				auto card = cast(C) _cards.getItem(i).getData();
				if (card.trees.length) {
					path = card.trees[0].cwxPath;
				} else {
					path = card.cwxPath;
				}
			} else {
				path = area.cwxPath;
			}
			path = cpaddattr(path, "eventview");
			_comm.openCWXPath(path, true);
		}
	}
	void refreshR(string from, string to) {
		refresh();
	}
	private void replText() {
		static if (UseCards) {
			auto skin = _comm.skin;
			foreach (i, c; _area.cards) {
				string name = cardName(c);
				auto itm = cardList.getItem(i);
				if (itm.getText() != name) {
					auto img = _imgp.images[cardsIndex + i];
					static if (is(C:EnemyCard)) {
						auto castCard = _summ.cwCast(c.id);
						if (!castCard) continue; // カード名が表示されないため不要
						img.setImageData(castCardImage(_prop, skin, castCard, _summ ? _summ.scenarioPath : "", _dbgMode));
					} else {
						img.title = name;
					}
					img.createImage();
					itm.setText(name);
					_comm.refMenuCard.call(c.cwxPath);
				}
			}
			_imgp.redraw();
		}
	}
	static if (UseCards) {
		private void refreshCardState() {
			for (int i = 0; i < _area.cards.length; i++) {
				auto fi = cast(FlexImage) _imgp.images[cardsIndex + i];
				fi.smoothing = _prop.var.etc.smoothingCard;
				fi.createImage();
			}
			_imgp.redraw();
		}
	}
	private void refreshPanel() {
		auto sels = _imgp.selectedIndices;
		size_t partyIndex = 0;
		static if (UseCards) {
			foreach (i, c; _area.cards) {
				auto v = _imgp.images[cardsIndex + i].visible;
				auto fi = create(c);
				fi.visible = v;
				_imgp.set(cardsIndex + i, fi);
				_cards.getItem(i).setText(cardName(c));
				_cards.getItem(i).setData(c);
				partyIndex++;
			}
		}
		static if (UseBacks) {
			foreach (i, b; _area.backs) {
				auto v = _imgp.images[i].visible;
				auto fi = create(b);
				fi.visible = v;
				_imgp.set(i, fi);
				_backs.getItem(i).setText(baseName(b.path));
				_backs.getItem(i).setData(b);
				partyIndex++;
			}
		}
		_imgp.removeRange(partyIndex, _imgp.images.length);
		appendPartyCards();
		_imgp.select(sels);
		_imgp.redraw();
		_comm.refreshToolBar();
	}
	private void appendPartyCards() {
		static if (RefCards) {
			if (_refTarget) {
				auto a = cast(Area) _refTarget;
				if (a) addRefCards(a.cards);
				auto b = cast(Battle) _refTarget;
				if (b) addRefCards(b.cards);
			}
		}
		foreach (p; _prop.looks.partyCardXY) {
			auto img = createCastCardBackImage(_prop, _comm.skin, p.x, p.y);
			img.alpha = _prop.var.etc.partyCardAlpha;
			img.visible = _viewParty;
			_imgp.append(img);
		}
		auto img = createMessageImage(_comm, _prop);
		img.visible = _viewMsg;
		_imgp.append(img);
	}
	static if (RefCards) {
		void addRefCards(C2)(in C2[] cs) {
			foreach (a; _imgp.appends) {
				a.dispose();
			}
			auto a = createRefCardImpl!C2(cs);
			if (a) {
				_imgp.appends = [a];
			} else {
				_imgp.appends = [];
			}
		}
		void createRefCard() {
			foreach (a; _imgp.appends) {
				a.dispose();
			}
			_imgp.appends = [];
			auto area = cast(Area) _refTarget;
			if (area) {
				auto a = createRefCardImpl(area.cards);
				if (a) _imgp.appends = [a];
			}
			auto battle = cast(Battle) _refTarget;
			if (battle) {
				auto a = createRefCardImpl(battle.cards);
				if (a) _imgp.appends = [a];
			}
		}
		Image createRefCardImpl(C2)(in C2[] cs) {
			auto d = getDisplay();
			auto vs = _prop.looks.viewSize;
			auto img = new Image(d, vs.width, vs.height);
			auto data = img.getImageData();
			img.dispose();
			auto alphas = new byte[vs.width * vs.height];
			alphas[] = 0;
			data.setAlphas(0, 0, vs.width * vs.height, alphas, 0);
			foreach (c; cs) {
				auto pimg = createCardImage!PileImage(c, _prop.var.etc.smoothingCard);
				auto pdata = pimg.createImageData();
				foreach (x; 0 .. pimg.width) {
					foreach (y; 0 .. pimg.height) {
						int x2 = x + pimg.x;
						int y2 = y + pimg.y;
						if (0 <= x2 && x2 < vs.width && 0 <= y2 && y2 < vs.height) {
							data.setPixel(x2, y2, pdata.getPixel(x, y));
							data.setAlpha(x2, y2, _prop.var.etc.partyCardAlpha);
						}
					}
				}
				pimg.dispose();
			}
			return new Image(d, data);
		}
	}
	void refresh() {
		static if (UseCards && is (C == EnemyCard)) {
			_bgm.refresh();
		}
		refreshPanel();
	}
	private void removeImpl(T)(int index, ref T[PileImage] tbl, int startIndex) {
		tbl.remove(_imgp.images[startIndex + index]);
		_imgp.remove(startIndex + index);
		callModEvent();
		_comm.refreshToolBar();
	}
	private void removeRangeImpl(T)(int fromIndex, int toIndex, ref T[PileImage] tbl, int startIndex) {
		for (int i = fromIndex + startIndex; i < toIndex + startIndex; i++) {
			tbl.remove(_imgp.images[i]);
		}
		_imgp.removeRange(startIndex + fromIndex, startIndex + toIndex);
		callModEvent();
		_comm.refreshToolBar();
	}
	static if (UseCards) {
		private static void removeCard(AbstractAreaView v, Commons comm, A area, ref C[PileImage] tbl, int index) {
			if (v) v.removeImpl(index, tbl, staticCardsIndex(area));
			comm.delMenuCard.call(area.cards[index].cwxPath);
		}
		private void removeCardRange(int fromIndex, int toIndex) {
			removeRangeImpl(fromIndex, toIndex, _cardTbl, cardsIndex);
			for (int i = toIndex; i >= fromIndex; i--) {
				_comm.delMenuCard.call(_area.cards[i].cwxPath);
			}
		}
	}
	static if (UseBacks) {
		private static void removeBack(AbstractAreaView v, Commons comm, A area, ref BgImage[PileImage] tbl, int index) {
			if (v) v.removeImpl(index, tbl, 0);
			comm.delBgImage.call(area.backs[index].cwxPath);
		}
		private void removeBackRange(int fromIndex, int toIndex) {
			removeRangeImpl(fromIndex, toIndex, _backTbl, 0);
			for (int i = toIndex; i >= fromIndex; i--) {
				_comm.delBgImage.call(_area.backs[i].cwxPath);
			}
		}
	}

	@property
	bool isFocusOnListOrPane() {
		static if (UseCards) {
			if (_cards.isFocusControl()) return true;
		}
		static if (UseBacks) {
			if (_backs.isFocusControl()) return true;
		}
		if (_imgp.isFocusControl()) return true;
		return false;
	}

	@property
	bool canUp() {
		if (!isFocusOnListOrPane()) return false;
		int[] cIdcs, bIdcs;
		static if (UseCards) {
			if (_viewCards) {
				cIdcs = _cards.getSelectionIndices().sort;
				if (cIdcs.length && cIdcs[0] <= 0) return false;
			}
		}
		static if (UseBacks) {
			if (_viewBacks) {
				bIdcs = _backs.getSelectionIndices().sort;
				if (bIdcs.length && bIdcs[0] <= 0) return false;
			}
		}
		return cIdcs.length || bIdcs.length;
	}
	@property
	bool canDown() {
		if (!isFocusOnListOrPane()) return false;
		int[] cIdcs, bIdcs;
		static if (UseCards) {
			if (_viewCards) {
				cIdcs = _cards.getSelectionIndices().sort;
				if (cIdcs.length && _cards.getItemCount() - 1 <= cIdcs[$ - 1]) return false;
			}
		}
		static if (UseBacks) {
			if (_viewBacks) {
				bIdcs = _backs.getSelectionIndices().sort;
				if (bIdcs.length && _backs.getItemCount() - 1 <= bIdcs[$ - 1]) return false;
			}
		}
		return cIdcs.length || bIdcs.length;
	}
	void up() {
		up(1, true, true);
	}
	void up(int count, bool cards, bool backs) {
		if (!isFocusOnListOrPane()) return;
		int[] cIdcs;
		int[] bIdcs;
		static if (UseCards) {
			if (cards) {
				if (_viewCards) cIdcs = _cards.getSelectionIndices();
				cIdcs = cIdcs.sort;
				if (cIdcs.length && cIdcs[0] < count) {
					count = cIdcs[0];
				}
			}
		}
		static if (UseBacks) {
			if (backs) {
				if (_viewBacks) bIdcs = _backs.getSelectionIndices();
				bIdcs = bIdcs.sort;
				if (bIdcs.length && bIdcs[0] < count) {
					count = bIdcs[0];
				}
			}
		}
		if ((!cIdcs.length && !bIdcs.length) || 0 >= count) return;
		_undo ~= new UndoUp(this, _comm, _area, _summ, cIdcs, bIdcs, count);
		upImpl(this, _comm, _area, cIdcs, bIdcs, count, true);
		_comm.refreshToolBar();
	}
	private static void upImpl(AbstractAreaView v, Commons comm, A area, int[] cIdcs, int[] bIdcs, int count, bool sel) {
		static if (UseCards) {
			upImpl2!(C)(v, v ? v._cards : null, &area.swapCards, staticCardsIndex(area), cIdcs, count);
			comm.upMenuCard.call(area.cwxPath, cIdcs, count);
		}
		static if (UseBacks) {
			upImpl2!(BgImage)(v, v ? v._backs : null, &area.swapBacks, 0, bIdcs, count);
			comm.upBgImage.call(area.cwxPath, bIdcs, count);
		}
		if (v) {
			if (sel) {
				int[] sels;
				static if (UseCards) {
					foreach (ci; cIdcs) {
						sels ~= staticCardsIndex(area) + ci - count;
					}
				}
				static if (UseBacks) {
					foreach (bi; bIdcs) {
						sels ~= bi - count;
					}
				}
				v._imgp.select(sels);
			}
			v.refreshSelected();
			if (cIdcs.length > 0 || bIdcs.length > 0) v._imgp.redraw();
		}
	}
	void down() {
		down(1, true, true);
	}
	void down(int count, bool cards, bool backs) {
		if (!isFocusOnListOrPane()) return;
		int[] cIdcs;
		int[] bIdcs;
		static if (UseCards) {
			if (cards) {
				if (_viewCards) cIdcs = _cards.getSelectionIndices();
				cIdcs = cIdcs.sort;
				if (cIdcs.length && _cards.getItemCount() - count <= cIdcs[$ - 1]) {
					count = _cards.getItemCount() - 1 - cIdcs[$ - 1];
				}
			}
		}
		static if (UseBacks) {
			if (backs) {
				if (_viewBacks) bIdcs = _backs.getSelectionIndices();
				bIdcs = bIdcs.sort;
				if (bIdcs.length && _backs.getItemCount() - count <= bIdcs[$ - 1]) {
					count = _backs.getItemCount() - 1 - bIdcs[$ - 1];
				}
			}
		}
		if ((!cIdcs.length && !bIdcs.length) || 0 >= count) return;
		_undo ~= new UndoDown(this, _comm, _area, _summ, cIdcs, bIdcs, count);
		downImpl(this, _comm, _area, cIdcs, bIdcs, count, true);
		_comm.refreshToolBar();
	}
	private static void downImpl(AbstractAreaView v, Commons comm, A area, int[] cIdcs, int[] bIdcs, int count, bool sel) {
		static if (UseCards) {
			downImpl2!(C)(v, v ? v._cards : null, &area.swapCards, staticCardsIndex(area), cIdcs, area.cards.length, count);
			comm.downMenuCard.call(area.cwxPath, cIdcs, count);
		}
		static if (UseBacks) {
			downImpl2!(BgImage)(v, v ? v._backs : null, &area.swapBacks, 0, bIdcs, area.backs.length, count);
			comm.downBgImage.call(area.cwxPath, bIdcs, count);
		}
		if (v) {
			if (sel) {
				int[] sels;
				static if (UseCards) {
					foreach (ci; cIdcs) {
						sels ~= staticCardsIndex(area) + ci + count;
					}
				}
				static if (UseBacks) {
					foreach (bi; bIdcs) {
						sels ~= bi + count;
					}
				}
				v._imgp.select(sels);
			}
			v.refreshSelected();
			if (cIdcs.length > 0 || bIdcs.length > 0) v._imgp.redraw();
		}
	}
	static if (UseCards && UseBacks) {
		private void reverseView(T)(ref bool view, Table list, int[T] edits, T[] delegate() col, int startIndex,
				MenuItem menu, ToolItem titm) {
			if (_imgp.isVisible()) .forceFocus(this, false);
			view = !view;
			list.setEnabled(view);
			for (int i = 0; i < col().length; i++) {
				auto fi = cast(FlexImage) _imgp.images[startIndex + i];
				fi.visible = view && list.getItem(i).getChecked();
				if (!view && fi.selected) {
					_imgp.deselect(fi);
					edits.remove(col()[i]);
				}
			}
			if (!view) {
				list.deselectAll();
			}
			if (menu) menu.setSelection(view);
			if (titm) titm.setSelection(view);
			refreshControls();
			_imgp.redraw();
		}
		void reverseViewCards() {
			reverseView!(C)(_viewCards, _cards, _editC, &_area.cards, cardsIndex, _vcMenu, _vcTMenu);
		}
		void reverseViewBacks() {
			reverseView!(BgImage)(_viewBacks, _backs, _editB, &_area.backs, 0, _vbMenu, _vbTMenu);
		}
	}
	static if (UseCards) {
		SpCardDialog!(C)[C] _editDlgsC;
		void editCardApply(UndoEdit undo, C card) {
			assert (undo);
			_undo ~= undo;
			int index;
			foreach (i, c; _area.cards) {
				if (c is card) {
					auto fi = create(card);
					_imgp.set(cardsIndex + i, fi);
					if (_cards.isSelected(i) && _viewCards) _imgp.select(fi);
					_cards.getItem(i).setText(fi.title);
					_cards.getItem(i).setData(c);
					refreshControls();
					_comm.refMenuCard.call(c.cwxPath);
					_comm.refUseCount.call();
					_imgp.redraw();
					callModEvent();
					_comm.refreshToolBar();
					return;
				}
			}
			assert (0);
		}
		void createCard() {
			static if (is(C : MenuCard)) {
				auto c = new MenuCard("", "", "", "", 0, 0, 1.0);
			} else static if (is(C : EnemyCard)) {
				if (!_summ) return;
				if (_summ.casts.length == 0) return;
				auto c = new EnemyCard(0, false, "", 0, 0, 1.0);
			} else static assert (0);
			auto dlg = new SpCardDialog!(C)(_comm, _prop, getShell(), _summ, c);
			dlg.appliedEvent ~= {
				auto c = dlg.card;
				int index = insertIndex(_cards);
				_undo ~= new UndoInsert(this, _comm, _area, _summ, [index], []);
				appendCard(index, c, true, true);
				UndoEdit undo = null;
				dlg.applyEvent ~= {
					undo = new UndoEdit(this, _comm, _area, _summ, [cCountUntil!("a is b")(_area.cards, c)], []);
				};
				dlg.appliedEvent.length = 0;
				dlg.appliedEvent ~= {
					editCardApply(undo, c);
				};
			};
			_editDlgsC[c] = dlg;
			dlg.closeEvent ~= {
				_editDlgsC.remove(c);
			};
			dlg.open();
		}
		void editCard(int[] indices) {
			foreach (i; indices) {
				editCard(_area.cards[i]);
			}
		}
		void editCard(C card) {
			auto p = card in _editDlgsC;
			if (p) {
				p.active();
				return;
			}
			foreach (i, c; _area.cards) {
				if (c is card) {
					_imgp.select([i + cardsIndex]);
					refreshSelected();
					break;
				}
			}
			UndoEdit undo = null;
			auto dlg = new SpCardDialog!(C)(_comm, _prop, getShell(), _summ, card);
			dlg.applyEvent ~= {
				undo = new UndoEdit(this, _comm, _area, _summ, [cCountUntil!("a is b")(_area.cards, card)], []);
			};
			dlg.appliedEvent ~= {
				editCardApply(undo, card);
			};
			_editDlgsC[card] = dlg;
			dlg.closeEvent ~= {
				_editDlgsC.remove(card);
			};
			dlg.open();
		}
		static if (is(C : MenuCard)) {
			void nameEditEnd(TableItem itm, int column, string newText) {
				auto c = cast(C) itm.getData();
				if (c.name == newText) return;
				_undo ~= new UndoEdit(this, _comm, _area, _summ, [itm.getParent().indexOf(itm)], []);
				c.name = newText;
				itm.setText(column, c.name);
				refreshPanel();
				_comm.refMenuCard.call(c.cwxPath);
				callModEvent();
				_comm.refreshToolBar();
			}
		} else static if (is(C : EnemyCard)) {
			void enemyEditEnd(TableItem itm, int column, CCombo combo) {
				assert (_summ);
				int i = combo.getSelectionIndex();
				if (-1 == i) return;
				auto c = cast(C) itm.getData();
				if (c.id == _summ.casts[i].id) return;
				_undo ~= new UndoEdit(this, _comm, _area, _summ, [itm.getParent().indexOf(itm)], []);
				c.id = _summ.casts[i].id;
				itm.setText(column, cardName(c));
				refreshPanel();
				_comm.refMenuCard.call(c.cwxPath);
				callModEvent();
				_comm.refreshToolBar();
			}
			void createEnemyCombo(TableItem itm, int column, out string[] strs, out string str) {
				assert (_summ);
				auto c = cast(C) itm.getData();
				foreach (cc; _summ.casts) {
					string s = to!string(cc.id) ~ "." ~ cc.name;
					strs ~= s;
					if (cc.id == c.id) {
						str = s;
					}
				}
			}
		} else static assert (0);
		@property
		bool isViewCards() {
			return _viewCards;
		}
	}
	PImg createCardImage(PImg, C2)(in C2 card, bool smoothing) {
		static if (is(C2 : MenuCard) || is(C2 : const MenuCard)) {
			return createMenuCardImage!PImg
				(prop, _comm.skin, card.name,
				cardImagePath(card), card.x, card.y, card.scale, smoothing);
		} else static if (is(C2 : EnemyCard) || is(C2 : const EnemyCard)) {
			auto skin = _comm.skin;
			auto castCard = summary.cwCast(card.id);
			if (castCard) {
				return createCastCardImage!PImg(prop, skin, castCard, _summ.scenarioPath,
					card.x, card.y, card.scale, smoothing, debugMode);
			} else {
				return createCastCardImage!PImg(prop, skin, null, _summ.scenarioPath,
					card.x, card.y, card.scale, smoothing, debugMode);
			}
		} else static assert (0, C2);
	}
	string cardName(C2)(in C2 card) {
		static if (is(C2 : MenuCard)) {
			return card.name;
		} else static if (is(C2 : EnemyCard)) {
			auto castCard = summary.cwCast(card.id);
			return castCard ? castCard.name : "";
		} else static assert (0, C2);
	}
	string cardImagePath(C2)(in C2 card) {
		static if (is(typeof(card.path))) {
			return _comm.skin.findImagePath(card.path, summary.scenarioPath);
		} else static if (is(typeof(summary.cwCast(card.id)))) {
			auto castCard = summary.cwCast(card.id);
			if (castCard) {
				return _comm.skin.findImagePath(castCard.path, summary.scenarioPath);
			} else {
				return "";
			}
		} else static assert (0, C2);
	}
	static if (UseBacks) {
		BgImageDialog[BgImage] _editDlgsB;
		void editBackApply(UndoEdit undo, BgImage back) {
			assert (undo);
			_undo ~= undo;
			foreach (i, b; _area.backs) {
				if (b is back) {
					auto fi = create(back);
					_imgp.set(i, fi);
					if (_backs.isSelected(i) && _viewBacks) _imgp.select(fi);
					_backs.getItem(i).setText(baseName(back.path));
					_backs.getItem(i).setData(b);
					refreshControls();
					_comm.refBgImage.call(b.cwxPath);
					_comm.refUseCount.call();
					_imgp.redraw();
					callModEvent();
					_comm.refreshToolBar();
					return;
				}
			}
			assert (0);
		}
		void createBackground() {
			auto b = new BgImage("", "", 0, 0, 0, 0, false);
			auto dlg = new BgImageDialog(_comm, _prop, getShell(), _summ, b);
			dlg.appliedEvent ~= {
				auto b = dlg.back;
				int index = insertIndex(_backs);
				_undo ~= new UndoInsert(this, _comm, _area, _summ, [], [index]);
				appendBgImage(index, b, true, true);
				UndoEdit undo = null;
				dlg.applyEvent ~= {
					undo = new UndoEdit(this, _comm, _area, _summ, [], [cCountUntil!("a is b")(_area.backs, b)]);
				};
				dlg.appliedEvent.length = 0;
				dlg.appliedEvent ~= {
					editBackApply(undo, b);
				};
			};
			_editDlgsB[b] = dlg;
			dlg.closeEvent ~= {
				_editDlgsB.remove(b);
			};
			dlg.open();
		}
		void editBack(int[] indices) {
			foreach (i; indices) {
				editBack(_area.backs[i]);
			}
		}
		void editBack(BgImage back) {
			auto p = back in _editDlgsB;
			if (p) {
				p.active();
				return;
			}
			foreach (i, b; _area.backs) {
				if (b is back) {
					_imgp.select([i]);
					refreshSelected();
					break;
				}
			}
			UndoEdit undo = null;
			auto dlg = new BgImageDialog(_comm, _prop, getShell(), _summ, back);
			dlg.applyEvent ~= {
				undo = new UndoEdit(this, _comm, _area, _summ, [], [cCountUntil!("a is b")(_area.backs, back)]);
			};
			dlg.appliedEvent ~= {
				editBackApply(undo, back);
			};
			_editDlgsB[back] = dlg;
			dlg.closeEvent ~= {
				_editDlgsB.remove(back);
			};
			dlg.open();
		}
		void bgImageEditEnd(TableItem itm, int column, CCombo combo) {
			int i = combo.getSelectionIndex();
			if (-1 == i) return;
			auto b = cast(BgImage) itm.getData();
			if (0 == i) {
				if (b.path == "") return;
				_undo ~= new UndoEdit(this, _comm, _area, _summ, [], [itm.getParent().indexOf(itm)]);
				b.path = "";
				itm.setText(column, "");
			} else {
				string mt = combo.getText();
				if (std.string.startsWith(mt, "/")) {
					mt = mt["/".length .. $];
				}
				if (b.path == mt) return;
				_undo ~= new UndoEdit(this, _comm, _area, _summ, [], [itm.getParent().indexOf(itm)]);
				b.path = mt;
				itm.setText(column, baseName(decodePath(mt)));
			}
			refreshPanel();
			_comm.refBgImage.call(b.cwxPath);
			callModEvent();
			_comm.refreshToolBar();
		}
		void createBgImageCombo(TableItem itm, int column, out string[] strs, out string str) {
			auto b = cast(BgImage) itm.getData();
			strs ~= _prop.msgs.imageNone;
			str = _prop.msgs.imageNone;
			bool def;
			string p = _comm.skin.findImagePathF(b.path, _summ ? _summ.scenarioPath : null, def);
			p = nabs(p);
			foreach (t; _comm.skin.tables()) {
				strs ~= t;
				if (cfnmatch(p, nabs(std.path.buildPath(_comm.skin.tableDir, t)))) {
					str = t;
				}
			}
			if (!_summ) return;
			void recurse(string dir, string sDir) {
				foreach (file; clistdir(dir)) {
					string full = std.path.buildPath(dir, file);
					string sFile = sDir ~ file;
					if (isDir(full)) {
						recurse(full, sFile ~ std.path.dirSeparator);
					} else {
						if (!_comm.skin.isBgImage(file)) continue;
						if (containsPath(_prop.var.etc.ignorePaths, file)) continue;
						sFile = encodePath(sFile);
						strs ~= sFile;
						if (cfnmatch(p, nabs(full))) {
							str = sFile;
						}
					}
				}
			}
			recurse(_summ.scenarioPath, std.path.dirSeparator);
		}
		bool isViewBacks() {
			return _viewBacks;
		}
	}

	@property
	bool isViewMsg() {return _viewMsg;}
	@property
	bool isViewParty() {return _viewParty;}
	static if (RefCards) {
		@property
		bool isViewRefCards() {return _imgp.showAppends;}
	}
	@property
	bool isFixed() {return _fixed;}
	static if (UseCards) {
		@property
		bool spCustom() {return !_area.spAuto;}
	}
	private void setupTLP(TopLevelPanel tlp) {
		_tlp.putMenuChecked(MenuID.ShowParty, &reverseViewParty, &isViewParty, null);
		_tlp.putMenuChecked(MenuID.FixedImage, &reverseFixed, &isFixed, null);
		static if (UseCards && UseBacks) {
			_tlp.putMenuChecked(MenuID.ShowCard, &reverseViewCards, &isViewCards, null);
			_tlp.putMenuChecked(MenuID.ShowBack, &reverseViewBacks, &isViewBacks, null);
		}
		static if (UseCards) {
			_tlp.putMenuChecked(MenuID.AutoArrange, &setAuto, &_area.spAuto, null);
			_tlp.putMenuChecked(MenuID.ManualArrange, &setCustom, &spCustom, null);
		}
		_tlp.putMenuAction(MenuID.Refresh, &refresh, null);
		_tlp.putMenuAction(MenuID.Undo, &undo, &_undo.canUndo);
		_tlp.putMenuAction(MenuID.Redo, &redo, &_undo.canRedo);
		_tlp.putMenuAction(MenuID.Up, &up, &canUp);
		_tlp.putMenuAction(MenuID.Down, &down, &canDown);
	}

	/// メニューにAreaViewで使用するアイテムを設定する。
	/// Params:
	/// bar = メニュー。
	void setupMenu(Menu bar) {
		auto mv = createMenu(_comm, bar, MenuID.CardsAndBacks);
		_vpMenu = createMenuItem(_comm, mv, MenuID.ShowParty, &reverseViewParty, null, SWT.CHECK);
		_vpMenu.setSelection(_viewParty);
		_vmMenu = createMenuItem(_comm, mv, MenuID.ShowMsg, &reverseViewMsg, null, SWT.CHECK);
		_vmMenu.setSelection(_viewMsg);
		static if (RefCards) {
			_vrMenu = createMenuItem(_comm, mv, MenuID.ShowRefCards, &reverseViewRefCards, null, SWT.CHECK);
			_vrMenu.setSelection(_imgp.showAppends);
		}
		new MenuItem(mv, SWT.SEPARATOR);
		_vfMenu = createMenuItem(_comm, mv, MenuID.FixedImage, &reverseFixed, null, SWT.CHECK);
		_vfMenu.setSelection(_fixed);
		static if (is(C : EnemyCard) || RefCards) {
			if (_summ) {
				new MenuItem(mv, SWT.SEPARATOR);
				_dbgMenu = createMenuItem(_comm, mv, MenuID.ShowEnemyCardProp, &reverseDebugMode, null, SWT.CHECK);
				_dbgMenu.setSelection(_dbgMode);
			}
		}
		static if (UseCards && UseBacks) {
			new MenuItem(mv, SWT.SEPARATOR);
			_vcMenu = createMenuItem(_comm, mv, MenuID.ShowCard, &reverseViewCards, null, SWT.CHECK);
			_vcMenu.setSelection(_viewCards);
			_vbMenu = createMenuItem(_comm, mv, MenuID.ShowBack, &reverseViewBacks, null, SWT.CHECK);
			_vbMenu.setSelection(_viewBacks);
		}
		static if (UseCards) {
			new MenuItem(mv, SWT.SEPARATOR);
			_autoMenu = createMenuItem(_comm, mv, MenuID.AutoArrange, &setAuto, null, SWT.RADIO);
			_customMenu = createMenuItem(_comm, mv, MenuID.ManualArrange, &setCustom, null, SWT.RADIO);
			_autoMenu.setSelection(_area.spAuto);
			_customMenu.setSelection(!_area.spAuto);
		}
		new MenuItem(mv, SWT.SEPARATOR);
		static if (is (C == MenuCard)) {
			createMenuItem(_comm, mv, MenuID.NewMenuCard, &createCard, null);
		} else static if (is (C == EnemyCard)) {
			createMenuItem(_comm, mv, MenuID.NewEnemyCard, &createCard, null);
		}
		static if (UseBacks) {
			createMenuItem(_comm, mv, MenuID.NewBack, &createBackground, null);
		}
	}

	/// ツールバーにAreaViewで使用するアイテムを設定する。
	/// Params:
	/// bar = ツールバー。
	private void setupToolBar(ToolBar bar) {
		static if (is(A : Area)) {
			if (cast(AreaSceneWindow) tlpData(this).tlp) {
				createToolItem(_comm, bar, MenuID.EditEvent, &openEvent, null);
				new ToolItem(bar, SWT.SEPARATOR);
			}
		} else static if (is(A : Battle)) {
			if (cast(BattleSceneWindow) tlpData(this).tlp) {
				auto itm = createToolItem(_comm, bar, MenuID.EditEvent, &openEvent, null);
				itm.setImage(_prop.images.editEventBattle);
				new ToolItem(bar, SWT.SEPARATOR);
			}
		}
		if (!_tlp) {
			createToolItem(_comm, bar, MenuID.Refresh, &refresh, null);
			new ToolItem(bar, SWT.SEPARATOR);
		}
		_vpTMenu = createToolItem(_comm, bar, MenuID.ShowParty, &reverseViewParty, null, SWT.CHECK);
		_vpTMenu.setSelection(_viewParty);
		_vmTMenu = createToolItem(_comm, bar, MenuID.ShowMsg, &reverseViewMsg, null, SWT.CHECK);
		_vmTMenu.setSelection(_viewMsg);
		static if (RefCards) {
			_vrTMenu = createToolItem(_comm, bar, MenuID.ShowRefCards, &reverseViewRefCards, null, SWT.CHECK);
			_vrTMenu.setSelection(_imgp.showAppends);
		}
		new ToolItem(bar, SWT.SEPARATOR);
		_vfTMenu = createToolItem(_comm, bar, MenuID.FixedImage, &reverseFixed, null, SWT.CHECK);
		_vfTMenu.setSelection(_fixed);
		static if (is(C : EnemyCard) || RefCards) {
			if (_summ) {
				new ToolItem(bar, SWT.SEPARATOR);
				_dbgTMenu = createToolItem(_comm, bar, MenuID.ShowEnemyCardProp, &reverseDebugMode, null, SWT.CHECK);
				_dbgTMenu.setSelection(_dbgMode);
			}
		}
		static if (UseCards && UseBacks) {
			new ToolItem(bar, SWT.SEPARATOR);
			_vcTMenu = createToolItem(_comm, bar, MenuID.ShowCard, &reverseViewCards, null, SWT.CHECK);
			_vcTMenu.setSelection(_viewCards);
			_vbTMenu = createToolItem(_comm, bar, MenuID.ShowBack, &reverseViewBacks, null, SWT.CHECK);
			_vbTMenu.setSelection(_viewBacks);
		}
		new ToolItem(bar, SWT.SEPARATOR);
		if (!_tlp) {
			createToolItem(_comm, bar, MenuID.Undo, &undo, &_undo.canUndo);
			createToolItem(_comm, bar, MenuID.Redo, &redo, &_undo.canRedo);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(_comm, bar, MenuID.Up, &up, &canUp);
			createToolItem(_comm, bar, MenuID.Down, &down, &canDown);
			new ToolItem(bar, SWT.SEPARATOR);
		}
		static if (UseCards) {
			_autoTMenu = createToolItem(_comm, bar, MenuID.AutoArrange, &setAuto, null, SWT.RADIO);
			_customTMenu = createToolItem(_comm, bar, MenuID.ManualArrange, &setCustom, null, SWT.RADIO);
			_autoTMenu.setSelection(_area.spAuto);
			_customTMenu.setSelection(!_area.spAuto);
			new ToolItem(bar, SWT.SEPARATOR);
			static if (is (C == MenuCard)) {
				createToolItem(_comm, bar, MenuID.NewMenuCard, &createCard, null);
			} else static if (is (C == EnemyCard)) {
				createToolItem(_comm, bar, MenuID.NewEnemyCard, &createCard, null);
			} else {
				static assert (0);
			}
		}
		static if (UseBacks) {
			createToolItem(_comm, bar, MenuID.NewBack, &createBackground, null);
		}
		new ToolItem(bar, SWT.SEPARATOR);
		_xSpn = createSpinner(bar, _prop.msgs.left, _prop.looks.posLeftMax, _prop.looks.posLeftMin, 0,
			&editSpn!("a.newX = value;"), &enterSpn!("a.x = value;", "a.newX = value;"),
			&cancelSpn!("a.x"));
		new ToolItem(bar, SWT.SEPARATOR);
		_ySpn = createSpinner(bar, _prop.msgs.top, _prop.looks.posTopMax, _prop.looks.posTopMin, 0,
			&editSpn!("a.newY = value;"), &enterSpn!("a.y = value;", "a.newY = value;"),
			&cancelSpn!("a.y"));
		static if (UseBacks) {
			new ToolItem(bar, SWT.SEPARATOR);
			_wSpn = createSpinner(bar, _prop.msgs.width, _prop.looks.backWidthMax, _prop.looks.backWidthMin, 0,
				&editSpnBack!("a.newWidth = value;"), &enterSpnBack!("a.width = value;", "a.newWidth = value;"),
				&cancelSpnBack!("a.width"));
			new ToolItem(bar, SWT.SEPARATOR);
			_hSpn = createSpinner(bar, _prop.msgs.height, _prop.looks.backHeightMax, _prop.looks.backHeightMin, 0,
				&editSpnBack!("a.newHeight = value;"), &enterSpnBack!("a.height = value;", "a.newHeight = value;"),
				&cancelSpnBack!("a.height"));
		}
		static if (UseCards) {
			new ToolItem(bar, SWT.SEPARATOR);
			_scaleSpn = createSpinner(bar, _prop.msgs.scale,
				cast(int) rndtol(_prop.looks.cardSizeMax * 100), cast(int) rndtol(_prop.looks.cardSizeMin * 100), 100,
				&editSpnCard!("a.scale = value / 100.0;"),
				&enterSpnCard!("a.scale = value / 100.0;", "a.scale = value / 100.0;"),
				&cancelSpnCard!("cast(int) rndtol(a.scale * 100.0)"));
			createLabel(bar, "%");
		}
		static if (UseBacks) {
			new ToolItem(bar, SWT.SEPARATOR);
			_maskTMenu = createToolItem(_comm, bar, MenuID.Mask, &setMask, () => _backs.getSelectionIndex() != -1, SWT.CHECK);
			_maskTMenu.setEnabled(false);
		}
		static if (is (C == EnemyCard)) {
			new ToolItem(bar, SWT.SEPARATOR);
			_escTMenu = createToolItem(_comm, bar, MenuID.Escape, &setEscape, () => _cards.getSelectionIndex() != -1, SWT.CHECK);
			_escTMenu.setEnabled(false);
			new ToolItem(bar, SWT.SEPARATOR);
			auto skin = _comm.skin;
			_bgm = new MaterialSelect!(MtType.BGM, CCombo, CCombo)(_comm, _prop, _summ, &selectBGM, [_prop.msgs.bgmNone]);
			auto dirs = _bgm.createDirsCombo(bar);
			createToolItemC(bar, dirs);
			auto files = _bgm.createFileList(bar);
			createToolItemC(bar, files);
			_bgm.createPlayToolItem(bar);
			_bgm.path = _area.music;
		}
	}
	private class FlagsDispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refFlagAndStep.remove(&refFlag);
			_comm.delFlagAndStep.remove(&refFlag);
		}
	}
	private class SelFlag : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int index = _flag.getSelectionIndex();
			string flag = index <= 0 ? "" : _flag.getText();
			auto undo = createUndoEdit();
			bool chg = false;
			static if (UseCards) {
				foreach (c; _editC.keys) {
					if (c.flag != flag) {
						c.flag = flag;
						chg = true;
					}
				}
			}
			static if (UseBacks) {
				foreach (b; _editB.keys) {
					if (b.flag != flag) {
						b.flag = flag;
						chg = true;
					}
				}
			}
			_undo ~= undo;
			refreshStatusLine();
			_comm.refUseCount.call();
		}
	}
	private void refFlag(Flag[] flag, Step[] step) {
		if (!flag.length) return;
		refreshFlag();
	}
	private void refreshFlag() {
		if (!_flag) return;
		string f = _flag.getText();
		_flag.removeAll();
		_flag.add(_prop.msgs.noFlagRef);
		_flag.select(0);
		foreach (i, fl; _summ.flagDirRoot.allFlags) {
			auto path = fl.path;
			_flag.add(path);
			if (path == f) _flag.setText(path);
		}
	}

	void reverseViewParty() {
		_viewParty = !_viewParty;
		int imgLen = _imgp.images.length;
		int partyLen = _prop.looks.partyCardXY.length;
		for (int i = imgLen - 2; i >= imgLen - partyLen - 1; i--) {
			_imgp.images[i].visible = _viewParty;
		}
		if (_vpMenu) _vpMenu.setSelection(_viewParty);
		if (_vpTMenu) _vpTMenu.setSelection(_viewParty);
		_imgp.redraw();
	}
	void reverseViewMsg() {
		_viewMsg = !_viewMsg;
		_imgp.images[$ - 1].visible = _viewMsg;
		if (_vmMenu) _vmMenu.setSelection(_viewMsg);
		if (_vmTMenu) _vmTMenu.setSelection(_viewMsg);
		_imgp.redraw();
	}
	static if (RefCards) {
		void reverseViewRefCards() {
			_imgp.showAppends = !_imgp.showAppends;
			if (_vmMenu) _vmMenu.setSelection(_imgp.showAppends);
			if (_vmTMenu) _vmTMenu.setSelection(_imgp.showAppends);
			_imgp.redraw();
		}
	}
	void reverseFixed() {
		_fixed = !_fixed;
		static if (UseCards) {
			_imgp.fixedRange(_fixed, cardsIndex, cardsIndex + _area.cards.length);
		}
		static if (UseBacks) {
			_imgp.fixedRange(_fixed, 0, _area.backs.length);
		}
		if (_vfMenu) _vfMenu.setSelection(_fixed);
		if (_vfTMenu) _vfTMenu.setSelection(_fixed);
		_imgp.redraw();
	}
	private int insertIndex(Table list) {
		int[] indices = list.getSelectionIndices().sort;
		return indices.length ? indices[$ - 1] + 1 : list.getItemCount();
	}
	static if (UseCards) {
		/// カードを追加する。
		/// Params:
		/// card = カード。
		/// select = 選択状態にするか。
		/// refresh = 表示を更新するか。
		private int appendCard(C card, bool select, bool refresh, bool fromImgPane) {
			int index = fromImgPane ? _area.cards.length : insertIndex(_cards);
			appendCard(index, card, select, refresh);
			return index;
		}
		/// ditto
		private void appendCard(int index, C card, bool select, bool refresh, bool check = true) {
			appendCardImpl(this, _comm, _area, index, card, select, refresh, check);
		}
		/// ditto
		private static void appendCardImpl(AbstractAreaView v, Commons comm, A area, int index, C card, bool select, bool refresh, bool check = true) {
			area.insert(index, card);
			if (v) {
				auto img = v.create(card);
				v._imgp.deselectAll();
				v._imgp.insert(v.cardsIndex + index, img);
				v._imgp.images[v.cardsIndex + index].visible = check;
				auto itm = new TableItem(v._cards, SWT.NONE, index);
				itm.setImage(v._prop.images.cards);
				itm.setData(card);
				itm.setChecked(check);
				itm.setText(v.cardName(card));
				if (select && v._viewCards) {
					v._imgp.select(img);
					if (refresh) {
						v.refreshSelected();
					}
				}
				v._imgp.redraw();
			}
			comm.addMenuCard.call(card.cwxPath);
			comm.refUseCount.call();
			if (v) v.callModEvent();
		}
		private FlexImage create(C card) {
			auto img = createCardImage!FlexImage(card, _prop.var.etc.smoothingCard);
			_cardTbl[img] = card;
			img.visible = isViewCards;
			img.fixed = isFixed;
			img.addSelectionListener(&selectImageC);
			img.addResizeListener(&resizeImageC);
			return img;
		}
		private void appendCards(int index, C[] cards, bool select, bool raiseEvent) {
			FlexImage[] imgs;
			foreach (i, card; cards) {
				auto img = create(card);
				imgs ~= img;
				if (raiseEvent) _comm.addMenuCard.call(card.cwxPath);
			}
			_imgp.insert(cardsIndex + index, cast(PileImage[]) imgs);
			foreach (i, c; cards) {
				auto itm = new TableItem(_cards, SWT.NONE, index + i);
				itm.setImage(_prop.images.cards);
				itm.setData(c);
				itm.setChecked(true);
				itm.setText(cardName(c));
			}
			if (select && _viewCards) _imgp.select(imgs);
			callModEvent();
		}
		static if (is (C == MenuCard)) {
			private int cardFromFile(string fname, int x, int y, bool fromImgPane) {
				if (!_summ) return -1;
				if (!hasPath(_summ.scenarioPath, fname)) {
					auto dlg = new MessageBox(getShell(), SWT.ICON_QUESTION | SWT.YES | SWT.NO | SWT.CANCEL);
					dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDropCard, fname));
					dlg.setText(_prop.msgs.dlgTitDropCard);
					auto ret = dlg.open();
					if (SWT.YES == ret) {
						fname = copyTo(_summ.scenarioPath, fname, _comm.skin.materialPath);
					} else if (SWT.CANCEL == ret) {
						return -1;
					}
				}
				auto card = new MenuCard(baseName(.stripExtension(fname)), fname, "", "", x, y, 1.0);
				return appendCard(card, true, true, fromImgPane);
			}
			private class CLDropTarget : DropTargetAdapter {
				override void dragEnter(DropTargetEvent e){
					e.detail = _summ ? DND.DROP_LINK : DND.DROP_NONE;
				}
				private int[] addC;
				override void drop(DropTargetEvent e) {
					assert (_summ);
					scope (exit) addC = [];
					auto arr = cast(FileNames) e.data;
					if (arr) {
						foreach (fname; arr.array) {
							try {
								if (!doFile(fname)) {
									break;
								}
							} catch (SWTException e) {
								debugln(e);
							}
						}
						if (addC.length) {
							auto undo = new UndoInsert(this.outer, _comm, _area, _summ, addC, []);
							_comm.refPaths.call(_comm.skin.materialPath);
						}
						_comm.refreshToolBar();
						return;
					} else if (isXMLBytes(e.data)) {
						int[] ci, bi;
						auto ctrl = (cast(DropTarget) e.getSource()).getControl();
						auto p = ctrl.toControl(e.x, e.y);
						appendFromXML(bytesToXML(e.data), p.x, p.y, DropTarg.Card, ci, bi);
						if (ci.length || bi.length) {
							_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, ci, bi);
						}
						_comm.refreshToolBar();
					}
				}
				private bool doFile(string path) {
					assert (_summ);
					if (_comm.skin.isCardImage(path)) {
						int i = cardFromFile(path, 0, 0, false);
						if (i == -1) {
							return false;
						} else {
							addC ~= i;
						}
					}
					return true;
				}
			}
		}
		class CardDrag : DragSourceAdapter {
			override void dragStart(DragSourceEvent e) {
				e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl();
			}
			override void dragSetData(DragSourceEvent e){
				if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) {
					auto tbl = cast(Table) (cast(DragSource) e.getSource()).getControl();
					auto sel = tbl.getSelectionIndex();
					auto curItm = sel != -1 ? tbl.getItem(sel) : null;
					C[] cs;
					foreach (itm; tbl.getSelection()) {
						cs ~= cast(C) itm.getData();
					}
					auto node = A.CtoNode(cs);
					node.newAttr("paneId", _id);
					if (curItm) node.newAttr("cursorIndex", tbl.indexOf(curItm));
					e.data = bytesFromXML(node.text);
				}
			}
			override void dragFinished(DragSourceEvent e) {
				// Nothing
			}
		}
	}
	static if (UseBacks) {
		/// 背景画像を追加する。
		/// Params:
		/// back = 背景画像。
		/// select = 選択状態にするか。
		/// refresh = 表示を更新するか。
		private int appendBgImage(BgImage back, bool select, bool refresh, bool fromImgPane) {
			int index = fromImgPane ? _area.backs.length : insertIndex(_backs);
			appendBgImage(index, back, select, refresh);
			return index;
		}
		/// ditto
		private void appendBgImage(int index, BgImage back, bool select, bool refresh, bool check = true) {
			appendBgImageImpl(this, _comm, _area, index, back, select, refresh, check);
		}
		/// ditto
		private static void appendBgImageImpl(AbstractAreaView v, Commons comm, A area, int index, BgImage back, bool select, bool refresh, bool check = true) {
			area.insert(index, back);
			if (v) {
				v._imgp.deselectAll();
				auto img = v.create(back);
				v._imgp.insert(index, img);
				v._imgp.images[index].visible = check;
				auto itm = new TableItem(v._backs, SWT.NONE, index);
				itm.setImage(v._prop.images.backs);
				itm.setData(back);
				itm.setChecked(check);
				itm.setText(baseName(back.path));
				if (select && v._viewBacks) {
					v._imgp.select(img);
					if (refresh) {
						v.refreshSelected();
					}
				}
				v._imgp.redraw();
			}
			comm.addBgImage.call(back.cwxPath);
			comm.refUseCount.call();
			if (v) v.callModEvent();
		}
		private FlexImage create(BgImage back) {
			auto skin = _comm.skin;
			auto path = skin.findImagePath(back.path, _summ ? _summ.scenarioPath : "");
			auto img = createBackgroundImage
				(skin, path, back.x, back.y, back.width, back.height, back.mask);
			_backTbl[img] = back;
			img.visible = _viewBacks;
			img.fixed = isFixed;
			img.addSelectionListener(&selectImageB);
			img.addResizeListener(&resizeImageB);
			return img;
		}
		private void appendBgImages(int index, BgImage[] backs, bool select, bool raiseEvent) {
			FlexImage[] imgs;
			foreach (back; backs) {
				imgs ~= create(back);
			}
			_imgp.insert(index, cast(PileImage[]) imgs);
			foreach (i, b; backs) {
				auto itm = new TableItem(_backs, SWT.NONE, index + i);
				itm.setImage(_prop.images.backs);
				itm.setData(b);
				itm.setChecked(true);
				itm.setText(baseName(b.path));
				if (raiseEvent) _comm.addBgImage.call(b.cwxPath);
			}
			if (select && _viewBacks) _imgp.select(imgs);
			callModEvent();
		}
		private int backFromFile(string fname, int x, int y, int w, int h, bool fromImgPane) {
			if (!_summ) return -1;
			if (!hasPath(_summ.scenarioPath, fname)) {
				auto dlg = new MessageBox(getShell(), SWT.ICON_QUESTION | SWT.YES | SWT.NO | SWT.CANCEL);
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDropBack, fname));
				dlg.setText(_prop.msgs.dlgTitDropBack);
				auto ret = dlg.open();
				if (SWT.YES == ret) {
					fname = copyTo(_summ.scenarioPath, fname, _comm.skin.materialPath);
				} else if (SWT.CANCEL == ret) {
					return -1;
				}
			}
			auto back = new BgImage(fname, "", x, y, w, h, false);
			return appendBgImage(back, true, true, fromImgPane);
		}
		private class BLDropTarget : DropTargetAdapter {
			private int[] addB;
			override void dragEnter(DropTargetEvent e){
				e.detail = DND.DROP_LINK;
			}
			override void drop(DropTargetEvent e) {
				assert (_summ);
				scope (exit) addB = [];
				auto arr = cast(FileNames) e.data;
				if (arr) {
					foreach (fname; arr.array) {
						try {
							if (!doFile(fname)) {
								break;
							}
						} catch (SWTException e) {}
					}
					if (addB.length) {
						auto undo = new UndoInsert(this.outer, _comm, _area, _summ, [], addB);
						_comm.refPaths.call(_comm.skin.materialPath);
					}
					_comm.refreshToolBar();
					return;
				} else if (isXMLBytes(e.data)) {
					int[] ci, bi;
					auto ctrl = (cast(DropTarget) e.getSource()).getControl();
					auto p = ctrl.toControl(e.x, e.y);
					appendFromXML(bytesToXML(e.data), p.x, p.y, DropTarg.Back, ci, bi);
					if (ci.length || bi.length) {
						_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, ci, bi);
					}
					_comm.refreshToolBar();
				}
			}
			private bool doFile(string path) {
				assert (_summ);
				auto img = loadBgImage(_comm.skin, path);
				if (img) {
					int i = backFromFile(path, 0, 0, img.width, img.height, false);
					if (i >= 0) {
						addB ~= i;
						return true;
					}
				}
				return false;
			}
		}
		class BackDrag : DragSourceAdapter {
			override void dragStart(DragSourceEvent e) {
				e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl();
			}
			override void dragSetData(DragSourceEvent e){
				if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) {
					auto tbl = cast(Table) (cast(DragSource) e.getSource()).getControl();
					auto sel = tbl.getSelectionIndex();
					auto curItm = sel != -1 ? tbl.getItem(sel) : null;
					BgImage[] bs;
					foreach (itm; tbl.getSelection()) {
						bs ~= cast(BgImage) itm.getData();
					}
					auto node = Area.BtoNode(bs);
					node.newAttr("paneId", _id);
					if (curItm) node.newAttr("cursorIndex", tbl.indexOf(curItm));
					e.data = bytesFromXML(node.text);
				}
			}
			override void dragFinished(DragSourceEvent e) {
				// Nothing
			}
		}
	}

	private void moveItems(Table list, int fromIndex, int toIndex) {
		if (fromIndex < 0 || list.getItemCount() <= fromIndex) return;
		if (fromIndex == toIndex) return;
		bool cards = false;
		bool backs = false;
		static if (UseCards) cards = list is _cards;
		static if (UseBacks) backs = list is _backs;
		if (fromIndex < toIndex) {
			down(toIndex - fromIndex, cards, backs);
		} else if (fromIndex > toIndex) {
			up(fromIndex - toIndex, cards, backs);
		}
	}
	private void appendFromXML(string xml, int x, int y, DropTarg dTarg, out int[] ci, out int[] bi) {
		try {
			bool toImgp = dTarg is DropTarg.ImagePane;
			auto node = XNode.parse(xml);
			int ptoi(Table list) {
				auto itm = list.getItem(new Point(x, y));
				if (itm) {
					return list.indexOf(itm);
				} else {
					return list.getItemCount();
				}
			}

			MenuCard[] mcs;
			BgImage[] bs;
			if (Area.CBfromXML(node, mcs, bs)) {
				if (!mcs.length && !bs.length) return;
				if (toImgp) {
					if (_id == node.attr("paneId", false)) return;
					static if (is(C : MenuCard)) {
						foreach (card; mcs) {
							ci ~= appendCard(card, true, true, toImgp);
						}
					}
					static if (UseBacks) {
						foreach (back; bs) {
							bi ~= appendBgImage(back, true, true, toImgp);
						}
					}
					_comm.refUseCount.call();
					_comm.refreshToolBar();
					return;
				}
				static if (is(C : MenuCard)) {
					if (DropTarg.Card is dTarg && mcs.length) {
						if (_id == node.attr("paneId", false)) {
							moveItems(_cards, node.attr("cursorIndex", false, -1), ptoi(_cards));
							return;
						}
						int si = ptoi(_cards);
						foreach (i, card; mcs) {
							appendCard(si + i, card, true, true);
							ci ~= si + i;
						}
						_comm.refUseCount.call();
						_comm.refreshToolBar();
						return;
					}
				}
				static if (UseBacks) {
					if (DropTarg.Back is dTarg && bs.length) {
						if (_id == node.attr("paneId", false)) {
							moveItems(_backs, node.attr("cursorIndex", false, -1), ptoi(_backs));
							return;
						}
						int si = ptoi(_backs);
						foreach (i, back; bs) {
							appendBgImage(si + i, back, true, true);
							bi ~= si + i;
						}
						_comm.refUseCount.call();
						_comm.refreshToolBar();
						return;
					}
				}
				return;
			}
			static if (is(C : EnemyCard)) {
				EnemyCard[] ecs;
				if (Battle.CfromXML(node, ecs)) {
					if (!ecs.length) return;
					if (toImgp) {
						if (_id == node.attr("paneId", false)) return;
						foreach (card; ecs) {
							ci ~= appendCard(card, true, true, toImgp);
						}
						_comm.refUseCount.call();
						return;
					}
					if (DropTarg.Card is dTarg && ecs.length) {
						if (_id == node.attr("paneId", false)) {
							moveItems(_cards, node.attr("cursorIndex", false, -1), ptoi(_cards));
							return;
						}
						int si = ptoi(_cards);
						foreach (i, card; ecs) {
							appendCard(si + i, card, true, true);
							ci ~= si + i;
						}
						_comm.refUseCount.call();
						_comm.refreshToolBar();
						return;
					}
					return;
				}
			}

			static if (is(A : Battle) && is(C : EnemyCard)) {
				if (node.name == CastCard.XML_NAME_M) {
					// キャストカードからのエネミーカード生成
					if (summary.id != node.attr("summId", false)) return;
					auto cards = EnemyCard.createCardsFromNode(node, LATEST_VERSION);
					if (cards.length) {
						int cx = 0;
						int cy = 0;
						if (toImgp) {
							auto s = _prop.looks.cardSize;
							auto ins = _prop.looks.castCardInsets;
							cx = x - cast(int) (s.width + ins.e + ins.w) / 2;
							cy = y - cast(int) (s.height + ins.n + ins.s) / 2;
						}
						foreach (i, card; cards) {
							assert (card.scale == 1.0);
							card.x = cx;
							card.y = cy;
							ci ~= appendCard(card, true, true, toImgp);
						}
						_comm.refUseCount.call();
						_comm.refreshToolBar();
					}
					return;
				}
			}

			static if (is(C : MenuCard)) {
				// その他カードからのメニューカード生成
				auto cards = MenuCard.createFromCardNode(node, _prop.var.etc.copyDesc, LATEST_VERSION);
				// x, y座標を中心にして配置
				int cx = 0;
				int cy = 0;
				if (toImgp) {
					auto s = _prop.looks.cardSize;
					auto ins = _prop.looks.menuCardInsets;
					cx = x - cast(int) (s.width + ins.e + ins.w) / 2;
					cy = y - cast(int) (s.height + ins.n + ins.s) / 2;
				}
				foreach (card; cards) {
					assert (card.scale == 1.0);
					card.x = cx;
					card.y = cy;
					ci ~= appendCard(card, true, true, toImgp);
				}
				_comm.refreshToolBar();
			}
		} catch (Exception e) {
			debugln(e);
		}
	}
	private class IPDropTarget : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){
			e.detail = _summ ? DND.DROP_LINK : DND.DROP_NONE;
		}
		private int[] addC;
		private int[] addB;
		override void drop(DropTargetEvent e) {
			assert (_summ);
			scope (exit) addC = [];
			scope (exit) addB = [];
			auto arr = cast(FileNames) e.data;
			if (arr) {
				int append = 0;
				foreach (fname; arr.array) {
					try {
						scope p = _imgp.toControl(e.x, e.y);
						if (!doFile(fname, p.x, p.y)) {
							break;
						}
						append++;
					} catch (SWTException e) {}
				}
				if (append > 0) {
					_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, addC, addB);
					_comm.refPaths.call(_comm.skin.materialPath);
					_comm.refreshToolBar();
				}
				return;
			}
			if (isXMLBytes(e.data)) {
				scope p = _imgp.toControl(e.x, e.y);
				int[] ci, bi;
				appendFromXML(bytesToXML(e.data), p.x, p.y, DropTarg.ImagePane, ci, bi);
				if (ci.length || bi.length) {
					_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, ci, bi);
					_comm.refreshToolBar();
				}
			}
		}
		private bool doFile(string path, int x, int y) {
			assert (_summ);
			auto skin = _comm.skin;
			static if ((UseCards && is (C == MenuCard)) && UseBacks) {
				if (skin.isCardImage(path)) {
					int i = cardFromFile(path, x, y, true);
					if (i == -1) {
						return false;
					} else {
						addC ~= i;
					}
				} else {
					auto img = loadBgImage(skin, path);
					if (img) {
						int i = backFromFile(path, x, y, img.width, img.height, true);
						if (i == -1) {
							return false;
						} else {
							addB ~= i;
						}
					}
				}
			} else static if (UseCards && is (C == MenuCard)) {
				if (skin.isCardImage(path)) {
					int i = cardFromFile(path, x, y, true);
					if (i == -1) {
						return false;
					} else {
						addC ~= i;
					}
				}
			} else static if (UseBacks) {
				auto img = loadBgImage(skin, path);
				if (img) {
					int i = backFromFile(path, x, y, img.width, img.height, true);
					if (i == -1) {
						return false;
					} else {
						addB ~= i;
					}
				}
			}
			_comm.refreshToolBar();
			return true;
		}
	}

	static if (is (C == EnemyCard)) {
		private void __refreshCast(CastCard castCard) {
			auto skin = _comm.skin;
			foreach (i, c; area.cards) {
				if (castCard.id == _area.cards[i].id) {
					auto img = imagePane.images[cardsIndex + i];
					img.setImageData(castCardImage(_prop, skin, castCard, _summ ? _summ.scenarioPath : "", _dbgMode));
					img.createImage();
					if (cardList.getItem(i).getText() != castCard.name) {
						cardList.getItem(i).setText(castCard.name);
						_comm.refMenuCard.call(_area.cards[i].cwxPath);
					}
				}
			}
			imagePane.redraw();
		}
		private void __deleteCast(CastCard castCard) {
			auto skin = _comm.skin;
			foreach (i, c; area.cards) {
				if (castCard.id == c.id) {
					auto img = imagePane.images[cardsIndex + i];
					img.setImageData(.castCard(skin));
					img.createImage();
					cardList.getItem(i).setText("");
				}
			}
			imagePane.redraw();
		}
	} else static if (RefCards) {
		private void __refreshCast(CastCard castCard) {
			refreshPanel();
		}
		private void __deleteCast(CastCard castCard) {
			refreshPanel();
		}
	}
	static if (is(A : Battle) && is(C : EnemyCard)) {
		class DTListener : DropTargetAdapter {
			override void dragEnter(DropTargetEvent e){
				e.detail = DND.DROP_LINK;
			}
			override void drop(DropTargetEvent e) {
				if (isXMLBytes(e.data)) {
					auto arr = bytesToXML(e.data);
					auto ctrl = (cast(DropTarget) e.getSource()).getControl();
					auto p = ctrl.toControl(e.x, e.y);
					auto imgp = cast(ImagePane) ctrl;
					int[] ci, bi;
					appendFromXML(arr, p.x, p.y, imgp ? DropTarg.ImagePane : DropTarg.Card, ci, bi);
					if (ci.length || bi.length) {
						_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, ci, bi);
						_comm.refreshToolBar();
					}
				}
			}
		}
	}
	void cut(SelectionEvent se) {
		int[] cs;
		int[] bs;
		static if (UseCards) cs = _cards.getSelectionIndices();
		static if (UseBacks) bs = _backs.getSelectionIndices();
		_undo ~= new UndoDelete(this, _comm, _area, _summ, cs, bs);
		_tcpd.cut(se);
	}
	void copy(SelectionEvent se) {
		_tcpd.copy(se);
	}
	void paste(SelectionEvent se) {
		_tcpd.paste(se);
	}
	void del(SelectionEvent se) {
		int[] cs;
		int[] bs;
		static if (UseCards) cs = _cards.getSelectionIndices();
		static if (UseBacks) bs = _backs.getSelectionIndices();
		_undo ~= new UndoDelete(this, _comm, _area, _summ, cs, bs);
		delImpl();
	}
	private void delImpl() {
		_tcpd.del(null);
	}
	private static void delImpl2(AbstractAreaView v, Commons comm, A area, int[] cIdcs, int[] bIdcs, bool store) {
		if (store && v) v._undo ~= new UndoDelete(v, comm, area, comm.summary, cIdcs, bIdcs);
		static if (UseCards) {
			foreach_reverse (i; cIdcs.sort) {
				if (v) {
					removeCard(v, comm, area, v._cardTbl, i);
				} else {
					C[PileImage] empty;
					removeCard(v, comm, area, empty, i);
				}
				area.removeCard(i);
				if (v) v._cards.remove(i);
			}
		}
		static if (UseBacks) {
			foreach_reverse (i; bIdcs.sort) {
				if (v) {
					removeBack(v, comm, area, v._backTbl, i);
				} else {
					BgImage[PileImage] empty;
					removeBack(v, comm, area, empty, i);
				}
				area.removeBgImage(i);
				if (v) v._backs.remove(i);
			}
		}
		if (v) {
			v._imgp.redraw();
			v.refreshSelected();
		}
		comm.refUseCount.call();
	}
	@property
	bool canDoTCPD() {
		return _imgp.isVisible();
	}
	@property
	bool canDoT() {
		return _imgp.selectedIndex != -1;
	}
	@property
	bool canDoC() {
		return _imgp.selectedIndex != -1;
	}
	@property
	bool canDoP() {
		return true;
	}
	@property
	bool canDoD() {
		return _imgp.selectedIndex != -1;
	}
	static if (UseCards && UseBacks) {
		private class AllTCPD : TCPD {
			void cut(SelectionEvent se) {
				copy(se);
				del(se);
			}
			void copy(SelectionEvent se) {
				scope MenuCard[] cards;
				foreach (i; _cards.getSelectionIndices()) {
					cards ~= _area.cards[i];
				}
				scope BgImage[] backs;
				foreach (i; _backs.getSelectionIndices()) {
					backs ~= _area.backs[i];
				}
				if (cards.length > 0 || backs.length > 0) {
					XMLtoCB(_prop, _comm.clipboard, Area.CBtoXML(cards, backs));
				}
			}
			void paste(SelectionEvent se) {
				auto xml = CBtoXML(_comm.clipboard);
				if (xml) {
					try {
						C[] cs;
						BgImage[] bs;
						A.CBfromXML(xml, cs, bs);
						if (cs.length || bs.length) {
							_imgp.deselectAll();
							int[] addC, addB;
							auto iib = insertIndex(_backs);
							foreach (i, b; bs) {
								int index = iib + i;
								addB ~= index;
								_area.insert(index, b);
							}
							appendBgImages(iib, bs, true, true);
							auto iic = insertIndex(_cards);
							foreach (i, c; cs) {
								int index = iic + i;
								addC ~= index;
								_area.insert(index, c);
							}
							appendCards(iic, cs, true, true);
							if (_viewCards || _viewBacks) _imgp.redraw();
							refreshSelected();
							_comm.refUseCount.call();
							_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, addC, addB);
							_comm.refreshToolBar();
						}
					} catch (Exception e) {
						debugln(e);
					}
				}
			}
			void del(SelectionEvent se) {
				delImpl2(this.outer, _comm, _area, _cards.getSelectionIndices(), _backs.getSelectionIndices(), true);
				_comm.refreshToolBar();
			}
			@property
			bool canDoTCPD() {
				return _imgp.isVisible();
			}
			@property
			bool canDoT() {
				return _imgp.selectedIndex != -1;
			}
			@property
			bool canDoC() {
				return _imgp.selectedIndex != -1;
			}
			@property
			bool canDoP() {
				return true;
			}
			@property
			bool canDoD() {
				return _imgp.selectedIndex != -1;
			}
		}
	}

	static if (UseCards) {
		private class CardTCPD : TCPD {
			void cut(SelectionEvent se) {
				copy(se);
				del(se);
			}
			void copy(SelectionEvent se) {
				scope C[] cards;
				foreach (i; _cards.getSelectionIndices()) {
					cards ~= _area.cards[i];
				}
				if (cards.length > 0) {
					XMLtoCB(_prop, _comm.clipboard, A.CtoXML(cards));
				}
			}
			void paste(SelectionEvent se) {
				static if (UseBacks) {
					this.outer.paste(se);
				} else {
					auto xml = CBtoXML(_comm.clipboard);
					if (xml) {
						try {
							C[] cs;
							A.CfromXML(xml, cs);
							if (cs.length) {
								int[] addC;
								_imgp.deselectAll();
								foreach (i, c; cs) {
									int index = insertIndex(_cards) + i;
									addC ~= index;
									_area.insert(index, c);
								}
								appendCards(insertIndex(_cards), cs, true, true);
								if (_viewCards) _imgp.redraw();
								refreshSelected();
								_comm.refUseCount.call();
								_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, addC, []);
								_comm.refreshToolBar();
							}
						} catch (Exception e) {
							debugln(e);
						}
					}
				}
			}
			void del(SelectionEvent se) {
				delImpl2(this.outer, _comm, _area, _cards.getSelectionIndices(), [], true);
				_comm.refreshToolBar();
			}
			@property
			bool canDoTCPD() {
				return _cards.isVisible() && _cards.isEnabled();
			}
			@property
			bool canDoT() {
				return _cards.getSelectionIndex() != -1;
			}
			@property
			bool canDoC() {
				return _cards.getSelectionIndex() != -1;
			}
			@property
			bool canDoP() {
				return true;
			}
			@property
			bool canDoD() {
				return _cards.getSelectionIndex() != -1;
			}
		}
	}
	static if (UseBacks) {
		private class BgImageTCPD : TCPD {
			void cut(SelectionEvent se) {
				copy(se);
				del(se);
			}
			void copy(SelectionEvent se) {
				scope BgImage[] backs;
				foreach (i; _backs.getSelectionIndices()) {
					backs ~= _area.backs[i];
				}
				if (backs.length > 0) {
					XMLtoCB(_prop, _comm.clipboard, A.BtoXML(backs));
				}
			}
			void paste(SelectionEvent se) {
				static if (UseCards) {
					this.outer.paste(se);
				} else {
					auto xml = CBtoXML(_comm.clipboard);
					if (xml) {
						try {
							BgImage[] bs;
							A.BfromXML(xml, bs);
							if (bs.length) {
								int[] addB;
								_imgp.deselectAll();
								foreach (i, b; bs) {
									int index = insertIndex(_backs) + i;
									addB ~= index;
									_area.insert(index, b);
								}
								appendBgImages(insertIndex(_backs), bs, true, true);
								if (_viewBacks) _imgp.redraw();
								refreshSelected();
								_comm.refUseCount.call();
								_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, [], addB);
								_comm.refreshToolBar();
							}
						} catch (Exception e) {
							debugln(e);
						}
					}
				}
			}
			void del(SelectionEvent se) {
				delImpl2(this.outer, _comm, _area, [], _backs.getSelectionIndices(), true);
				_comm.refreshToolBar();
			}
			@property
			bool canDoTCPD() {
				return _backs.isVisible() && _backs.isEnabled();
			}
			@property
			bool canDoT() {
				return _backs.getSelectionIndex() != -1;
			}
			@property
			bool canDoC() {
				return _backs.getSelectionIndex() != -1;
			}
			@property
			bool canDoP() {
				return true;
			}
			@property
			bool canDoD() {
				return _backs.getSelectionIndex() != -1;
			}
		}
	}
	void undo() {_undo.undo();}
	void redo() {_undo.redo();}

	bool openCWXPath(string path, bool shellActivate) {
		if (cpempty(path)) {
			.forceFocus(_imgp, shellActivate);
			_comm.refreshToolBar();
			return true;
		}
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		bool sel(Table list) {
			if (index >= list.getItemCount()) return false;
			.forceFocus(_imgp, shellActivate);
			list.select(index);
			list.showSelection();
			_comm.refreshToolBar();
			return true;
		}
		static if (UseCards && is(C : MenuCard)) {
			if (cate == "menucard") {
				if (cphasattr(path, "opendialog")) {
					if (index >= _cards.getItemCount()) return false;
					editCard([index]);
					return true;
				} else {
					if (sel(_cards)) {
						listSelectC();
						return true;
					}
				}
			}
		}
		static if (UseCards && is(C : EnemyCard)) {
			if (cate == "enemycard") {
				if (cphasattr(path, "opendialog")) {
					if (index >= _cards.getItemCount()) return false;
					editCard([index]);
					return true;
				} else {
					if (sel(_cards)) {
						listSelectC();
						return true;
					}
				}
			}
		}
		static if (UseBacks) {
			if (cate == "background") {
				if (cphasattr(path, "opendialog")) {
					if (index >= _backs.getItemCount()) return false;
					editBack([index]);
					return true;
				} else {
					if (sel(_backs)) {
						listSelectB();
						return true;
					}
				}
			}
		}
		return false;
	}
	@property
	string[] openedCWXPath() {
		string[] r;
		static if (UseCards) {
			foreach (i; _cards.getSelectionIndices()) {
				r ~= _area.cards[i].cwxPath;
			}
		}
		static if (UseBacks) {
			foreach (i; _backs.getSelectionIndices()) {
				r ~= _area.backs[i].cwxPath;
			}
		}
		return r.length ? r : [_area.cwxPath];
	}
}

alias AbstractAreaView!(Area, MenuCard, true, true) AreaView;
alias AbstractAreaView!(Battle, EnemyCard, true, false) BattleView;

class BgImagesView : AbstractAreaView!(BgImageContainer, void, false, true) {
	this(Commons comm, Props prop, Summary summ, BgImageContainer bic, Composite parent, AbstractArea refTarget, UndoManager undo) {
		if (prop.var.etc.refCardsAtEditBgImage) {
			_refTarget = refTarget;
		}
		super(comm, prop, summ, bic, parent, null, undo);
	}
}
