
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
import cwx.editor.gui.dwt.message;

import std.algorithm;
import std.math;
import std.path;
import std.file;
import std.traits;

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
	comp.setLayout = new CenterLayout(SWT.VERTICAL, 0);
	auto lbl = new Label(comp, SWT.NONE);
	lbl.setText = label;
	createToolItemC(bar, comp);
}

private Spinner createSpinner(ToolBar bar, string label, int max, int min, int sel,
		void delegate(int value) edit, void delegate(int value) enter, int delegate(int oldVal) cancel) {
	createLabel(bar, label ~ ":");
	auto spn = new Spinner(bar, SWT.BORDER);
	spn.setEnabled = false;
	spn.setMaximum = max;
	spn.setMinimum = min;
	spn.setSelection = sel;
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

class AbstractAreaView(A, C, bool UseCards, bool UseBacks) : Composite, TCPD {
	/// 変更があった際に呼び出される。
	void delegate()[] modEvent;
	private void callModEvent() {
		foreach (dlg; modEvent) dlg();
	}
private:
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
		auto b = itm.getBounds;
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
			_refAreas.select = 0;
			foreach (a; _summ.areas) {
				_refAreasArr ~= a;
				_refAreas.add(to!string(a.id) ~ "." ~ a.name);
				if(_refTarget is a) _refAreas.select = _refAreas.getItemCount - 1;
			}
			foreach (a; _summ.battles) {
				_refAreasArr ~= a;
				_refAreas.add(to!string(a.id) ~ "." ~ a.name);
				if(_refTarget is a) _refAreas.select = _refAreas.getItemCount - 1;
			}
			if (0 == _refAreas.getSelectionIndex) {
				_refTarget = null;
			}
		}
		void refreshRefAreasA(Area a) {refreshRefAreas();}
		void refreshRefAreasB(Battle a) {refreshRefAreas();}
		int refCardIndex() {
			int partyIndex = 0;
			static if (UseCards) partyIndex += _area.cards.length;
			static if (UseBacks) partyIndex += _area.backs.length;
			return partyIndex;
		}
		PileImage createRefCardFromIndex(int i) {
			auto area = cast(Area) _refTarget;
			if (area) {
				return createRefCard(area.cards[i]);
			}
			auto battle = cast(Battle) _refTarget;
			if (battle) {
				return createRefCard(battle.cards[i]);
			}
			assert (0);
		}
		void refRefMenuCard(string a) {
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath, cpparent(a))) return;
			int i = cpindex(cpbottom(a));
			_imgp.set(refCardIndex + i, createRefCardFromIndex(i));
			_imgp.redraw();
		}
		void addRefMenuCard(string a) {
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath, cpparent(a))) return;
			int i = cpindex(cpbottom(a));
			_imgp.insert(refCardIndex + i, createRefCardFromIndex(i));
			_imgp.redraw();
		}
		void delRefMenuCard(string a) {
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath, cpparent(a))) return;
			int i = cpindex(cpbottom(a));
			_imgp.remove(refCardIndex + i);
			_imgp.redraw();
		}
		void upRefMenuCards(string a, int[] indices) {
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath, a)) return;
			auto i2 = indices.dup;
			i2[] -= 1;
			indices ~= i2;
			indices = indices.sort;
			foreach (i; indices.uniq) {
				_imgp.set(refCardIndex + i, createRefCardFromIndex(i));
			}
			_imgp.redraw();
		}
		void downRefMenuCards(string a, int[] indices) {
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath, a)) return;
			auto i2 = indices.dup;
			i2[] += 1;
			indices ~= i2;
			indices = indices.sort;
			foreach (i; indices.uniq) {
				_imgp.set(refCardIndex + i, createRefCardFromIndex(i));
			}
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
			auto ct = Display.getCurrent.getFocusControl;
			while (ct.getParent) {
				if (ct is v) {
					return;
				}
				ct = ct.getParent;
			}
			.forceFocus(v._imgp, false);
		}
		protected void uda(AbstractAreaView v) {
			if (!v) return;
			static if (UseCards) if (!v._viewCards) v._cards.deselectAll;
			static if (UseBacks) if (!v._viewBacks) v._backs.deselectAll;
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
					if (v._autoMenu) v._autoMenu.setSelection = area.spAuto;
					if (v._autoTMenu) v._autoTMenu.setSelection = area.spAuto;
					if (v._customMenu) v._customMenu.setSelection = !area.spAuto;
					if (v._customTMenu) v._customTMenu.setSelection = !area.spAuto;
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
			override string cwxPath() {return "";}
			override CWXPath findCWXPath(string path) {return null;}
			override CWXPath[] cwxChilds() {return [];}
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
				_path.removeUseCounter;
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
		override void undo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			add(I);
			reselect(v);
			static if (I < 0) {
				downImpl(v, comm, area, _cIdcs, _bIdcs);
			} else {
				upImpl(v, comm, area, _cIdcs, _bIdcs);
			}
			add(-I);
		}
		override void redo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			reselect(v);
			static if (I < 0) {
				upImpl(v, comm, area, _cIdcs, _bIdcs);
			} else {
				downImpl(v, comm, area, _cIdcs, _bIdcs);
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
			delImpl2(v, comm, area, _cIdcs, _bIdcs);
		}
		override void redo() {
			_delUndo.undo;
			_delUndo = null;
		}
		override void dispose() {
			if (_delUndo) _delUndo.dispose;
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
					auto node = area.cards[i].toNode;
					auto c = C.createFromNode(node, LATEST_VERSION);
					if (summ) c.setUseCounter(summ.useCounter.sub);
					_cs[i] = c;
					_cChks[i] = v ? v._cards.getItem(i).getChecked : true;
				}
			}
			static if (UseBacks) {
				foreach (i; bIdcs) {
					auto b = area.backs[i].dup;
					if (summ) b.setUseCounter(summ.useCounter.sub);
					_bs[i] = b;
					_bChks[i] = v ? v._backs.getItem(i).getChecked : true;
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
			if (v) v.refreshSelected;
		}
		override void redo() {
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			int[] cs;
			int[] bs;
			static if (UseCards) cs = _cs.keys;
			static if (UseBacks) bs = _bs.keys;
			delImpl2(v, comm, area, cs, bs);
		}
		override void dispose() {
			static if (UseCards) {
				foreach (i, c; _cs) c.removeUseCounter;
			}
			static if (UseBacks) {
				foreach (i, b; _bs) b.removeUseCounter;
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
					c.removeUseCounter;
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
					b.removeUseCounter;
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
				v.refreshPanel;
				v.refreshControls;
				v.callModEvent();
			}
			comm.refUseCount.call;
		}
		override void undo() {
			impl();
		}
		override void redo() {
			impl();
		}
		override void dispose() {
			static if (UseCards) {
				foreach (i, c; _cs) c.removeUseCounter;
			}
			static if (UseBacks) {
				foreach (i, b; _bs) b.removeUseCounter;
			}
		}
	}
	UndoEdit createUndoEdit() {
		int[] cs;
		int[] bs;
		static if (UseCards) cs = _cards.getSelectionIndices;
		static if (UseBacks) bs = _backs.getSelectionIndices;
		return new UndoEdit(this, _comm, _area, _summ, cs, bs);
	}

	protected Props prop() {return _prop;}
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
	static if (is (C == EnemyCard) || RefCards) {
		MenuItem _dbgMenu;
		ToolItem _dbgTMenu;
		protected bool debugMode() {return _dbgMode;}
		bool _dbgMode = false;
		void reverseDebugMode() {
			_dbgMode = !_dbgMode;
			if (_dbgMenu) _dbgMenu.setSelection = _dbgMode;
			if (_dbgTMenu) _dbgTMenu.setSelection = _dbgMode;
			refreshPanel;
		}
	}
	static if (is (C == EnemyCard)) {
		ToolItem _escTMenu;
		MaterialSelect!(MtType.BGM, CCombo, CCombo) _bgm;
		void setEscape() {
			_undo ~= createUndoEdit();
			foreach (c; _editC.keys) {
				c.escape = _escTMenu.getSelection;
			}
			callModEvent();
		}
		void selectBGM() {
			_undo ~= new UndoMusic(this, _comm, _area, _summ);
			_area.music = _bgm.path;
			_comm.refUseCount.call;
			callModEvent();
		}
	}

	static if (UseCards && UseBacks) {
		SplitPane _sash;
	}

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

		Table cardList() {return _cards;}
		void editSpnCard(string T)(int value) {
			__editSpn!(T, C)(value, _editC, cardsIndex);
			_imgp.redraw;
		}
		void enterSpnCard(string T, string N)(int value) {
			_undo ~= createUndoEdit();
			__enterSpn!(T, N, C)(value, _editC, cardsIndex);
			_imgp.redraw;
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
				// FIXME: ここから直接selectListItemをインスタンス化して呼ぶとアクセス違反に。
				listSelectC;
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
			refreshControls;
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

		Table backList() {return _backs;}
		void editSpnBack(string T)(int value) {
			__editSpn!(T, BgImage)(value, _editB, 0);
			_imgp.redraw;
		}
		void enterSpnBack(string T, string N)(int value) {
			_undo ~= createUndoEdit();
			__enterSpn!(T, N, BgImage)(value, _editB, 0);
			_imgp.redraw;
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
				// FIXME: ここから直接selectListItemをインスタンス化して呼ぶとアクセス違反に。
				listSelectB;
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
			refreshControls;
			_comm.refBgImage.call(back.cwxPath);
			callModEvent();
		}
		void selectImageB(FlexImage img) {
			__selectImage!(BgImage)(img, _area.backs, _backTbl, _editB, _backs);
		}
		void setMask() {
			_undo ~= createUndoEdit();
			foreach (back, i; _editB) {
				back.mask = _maskTMenu.getSelection;
				_imgp.images[i].transparent = back.mask;
				_imgp.images[i].createImage;
				_comm.refBgImage.call(back.cwxPath);
			}
			_imgp.redraw;
			callModEvent();
		}
	}

	void selectListItem(T)(Table list, int startIndex, ref int[T] edits, T[] cols) {
		int count = list.getItemCount;
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
		refreshControls;
		_imgp.redraw;
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
		_imgp.redraw;
	}
	void enterSpn(string T, string N)(int value) {
		_undo ~= createUndoEdit();
		static if (UseCards) __enterSpn!(T, N, C)(value, _editC, cardsIndex);
		static if (UseBacks) __enterSpn!(T, N, BgImage)(value, _editB, 0);
		_imgp.redraw;
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
					list.setSelection(list.getSelectionIndices ~ i);
					edits[b] = i;
				} else {
					list.deselect(i);
					edits.remove(b);
				}
				refreshControls;
				list.showSelection;
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
		for (int i = startIndex; i < startIndex + list.getItemCount; i++) {
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
			_cards.setRedraw = false;
			scope (exit) _cards.setRedraw = true;
			auto idx = _cards.getSelectionIndices;
			auto cs = _area.cards;
			_cards.removeAll();
			foreach (i, c; cs) {
				auto itm = new TableItem(_cards, SWT.NONE);
				itm.setImage = _prop.images.cards;
				itm.setData = c;
				itm.setChecked = true;
				itm.setText = cardName(c);
			}
			_cards.setSelection = idx;
		}
	}
	static if (UseBacks) {
		private void refreshBacks() {
			_backs.setRedraw = false;
			scope (exit) _backs.setRedraw = true;
			auto idx = _backs.getSelectionIndices;
			auto cs = _area.backs;
			_backs.removeAll();
			foreach (i, c; cs) {
				auto itm = new TableItem(_backs, SWT.NONE);
				itm.setImage = _prop.images.backs;
				itm.setData = c;
				itm.setChecked = true;
				itm.setText = baseName(c.path);
			}
			_backs.setSelection = idx;
		}
	}
	static void upImpl2(T)(AbstractAreaView v, Table list, void delegate(int, int) swap, int startIndex, int[] indices) {
		indices = indices.sort;
		if (!indices.length) return;
		if (indices[0] != 0) {
			foreach (i; indices) {
				if (v) v._imgp.swap(i + startIndex - 1, i + startIndex);
				swap(i - 1, i);
				if (list) {
					auto itm1 = list.getItem(i - 1);
					auto itm2 = list.getItem(i);
					string temp = itm1.getText;
					itm1.setText = itm2.getText;
					itm2.setText = temp;
					auto dtemp = itm1.getData;
					itm1.setData = itm2.getData;
					itm2.setData = dtemp;
				}
			}
		}
		if (v) v.callModEvent();
	}
	static void downImpl2(T)(AbstractAreaView v, Table list, void delegate(int, int) swap, int startIndex, int[] indices, int count) {
		indices = indices.sort;
		if (!indices.length) return;
		if (indices[$ - 1] + 1 < count) {
			foreach_reverse (i; indices) {
				if (v) v._imgp.swap(i + startIndex + 1, i + startIndex);
				swap(i + 1, i);
				if (list) {
					auto itm1 = list.getItem(i + 1);
					auto itm2 = list.getItem(i);
					string temp = itm1.getText;
					itm1.setText = itm2.getText;
					itm2.setText = temp;
					auto dtemp = itm1.getData;
					itm1.setData = itm2.getData;
					itm2.setData = dtemp;
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
				a.resize;
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
				a.resize;
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
					fi.resize;
				}
				_comm.refMenuCard.call(c.cwxPath);
			}
			refreshControls;
			_imgp.redraw;
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
				fi.resize;
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
		refreshControls;
		_imgp.redraw;
	}
	void posBottom() {
		_undo ~= createUndoEdit();
		static if (UseCards) __posBottom!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posBottom!(BgImage)(0, _area.backs);
		refreshControls;
		_imgp.redraw;
	}
	void posLeft() {
		_undo ~= createUndoEdit();
		static if (UseCards) __posLeft!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posLeft!(BgImage)(0, _area.backs);
		refreshControls;
		_imgp.redraw;
	}
	void posRight() {
		_undo ~= createUndoEdit();
		static if (UseCards) __posRight!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posRight!(BgImage)(0, _area.backs);
		refreshControls;
		_imgp.redraw;
	}
	void posEven() {
		_undo ~= createUndoEdit();
		static if (UseCards) __posEven!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posEven!(BgImage)(0, _area.backs);
		refreshControls;
		_imgp.redraw;
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
		static if (UseCards) __scaleEvenC!(int.min, "a > b");
		static if (UseBacks) __scaleEvenB!(int.min, "a > b");
		refreshControls;
		_imgp.redraw;
	}
	void scaleEvenSmall() {
		_undo ~= createUndoEdit();
		static if (UseCards) __scaleEvenC!(int.max, "a < b");
		static if (UseBacks) __scaleEvenB!(int.max, "a < b");
		refreshControls;
		_imgp.redraw;
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
		_imgp.setBackgroundImage = _comm.wallpaper;
	}
	Control createImagePane(Composite parent) {
		auto sc = new ScrolledComposite(parent, SWT.H_SCROLL | SWT.V_SCROLL);
		sc.setExpandHorizontal = false;
		sc.setExpandVertical = false;
		auto vs = _prop.looks.viewSize;
		sc.getHorizontalBar.setIncrement = vs.width / 20;
		sc.getVerticalBar.setIncrement = vs.height / 20;
		sc.getHorizontalBar.setPageIncrement = vs.width / 5;
		sc.getVerticalBar.setPageIncrement = vs.height / 5;
		sc.setLayoutData = new GridData(GridData.FILL_BOTH);
		_imgp = new ImagePane(sc, SWT.BORDER | SWT.NO_BACKGROUND);
		auto rgb = new RGB(_prop.var.etc.wallColorR,
			_prop.var.etc.wallColorG,
			_prop.var.etc.wallColorB);
		auto color = new Color(Display.getCurrent, rgb);
		_imgp.setBackgroundColor = color;
		_comm.refWallpaper.add(&refreshWallpaper);
		_imgp.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_imgp.setBackgroundImage = cast(Image) null;
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
			auto menu = new Menu(parent.getShell, SWT.POP_UP);
			createMenuItem(menu, _prop.msgs.menuCEdit, _prop.images.menuCEdit, &edit);
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_prop, menu, _tcpd, true, true, true, true);
			static if (is(A : Area) || is(A : Battle)) {
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(menu, _prop.msgs.menuEditEvent, _prop.images.menuEditEvent, &openEvent);
			}
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(menu, _prop.msgs.menuPosTop, _prop.images.menuPosTop, &posTop);
			createMenuItem(menu, _prop.msgs.menuPosBottom, _prop.images.menuPosBottom, &posBottom);
			createMenuItem(menu, _prop.msgs.menuPosLeft, _prop.images.menuPosLeft, &posLeft);
			createMenuItem(menu, _prop.msgs.menuPosRight, _prop.images.menuPosRight, &posRight);
			createMenuItem(menu, _prop.msgs.menuPosEven, _prop.images.menuPosEven, &posEven);
			static if (UseCards) {
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(menu, _prop.msgs.menuScaleMin, _prop.images.menuScaleMin, &__scaleCMin);
	 			createMenuItem(menu, _prop.msgs.menuScaleMiddle, _prop.images.menuScaleMiddle, &__scaleCMiddle);
				createMenuItem(menu, _prop.msgs.menuScaleMax, _prop.images.menuScaleMax, &__scaleCMax);
			}
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(menu, _prop.msgs.menuScaleEvenBig, _prop.images.menuScaleEvenBig, &scaleEvenBig);
			createMenuItem(menu, _prop.msgs.menuScaleEvenSmall, _prop.images.menuScaleEvenSmall, &scaleEvenSmall);
			_imgp.setMenu(menu);
		}
		_imgp.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				auto pane = cast(ImagePane) e.widget;
				auto img = pane.getBackgroundImage;
				if (img) img.dispose;
				auto color = pane.getBackgroundColor;
				if (color) color.dispose;
			}
		});
		return sc;
	}
	void changingImages() {
		_undo ~= createUndoEdit();
	}

	void refreshControls() {
		string f = null;
		if (_flag) _flag.setText = _flag.getItem(0);
		void flag(string f2) {
			if (!_flag) return;
			if (!f) {
				f = f2;
				if ("" != f2) {
					_flag.setText = f2;
				}
			} else if (f != f2) {
				_flag.setText = "";
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
			if (_flag) _flag.setEnabled = _editC.length || _editB.length;
			_xSpn.setEnabled = _editC.length || _editB.length;
			_ySpn.setEnabled = _xSpn.getEnabled;
			_wSpn.setEnabled = _editB.length > 0;
			_hSpn.setEnabled = _wSpn.getEnabled;
			_maskTMenu.setEnabled = _wSpn.getEnabled;
			_scaleSpn.setEnabled = _editC.length > 0;
			if (_editC.length == 1) {
				auto card = _editC.keys[0];
				_scaleSpn.setSelection = cast(int) rndtol(card.scale * 100.0);
				if (_editB.length == 0) {
					_xSpn.setSelection = card.x;
					_ySpn.setSelection = card.y;
				}
			} else if (_editC.length > 1) {
				_scaleSpn.setSelection
					= spnValue!("cast(int) rndtol(a.scale * 100.0)", C, int)(_editC.keys, 100);
			}
			if (_editB.length == 1) {
				auto back = _editB.keys[0];
				_wSpn.setSelection = back.width;
				_hSpn.setSelection = back.height;
				_maskTMenu.setSelection = back.mask;
				if (_editC.length == 0) {
					_xSpn.setSelection = back.x;
					_ySpn.setSelection = back.y;
				}
			} else if (_editB.length > 1) {
				_wSpn.setSelection = spnValue!("a.width", BgImage, int)(_editB.keys, 0);
				_hSpn.setSelection = spnValue!("a.height", BgImage, int)(_editB.keys, 0);
				_maskTMenu.setSelection = spnValue!("a.mask", BgImage, bool)(_editB.keys, 0);
			}
			if (_editC.length + _editB.length > 1) {
				if (_editC.length == 0) {
					_xSpn.setSelection = spnValue!("a.x", BgImage, int)(_editB.keys, 0);
					_ySpn.setSelection = spnValue!("a.y", BgImage, int)(_editB.keys, 0);
				} else if (_editB.length == 0) {
					_xSpn.setSelection = spnValue!("a.x", C, int)(_editC.keys, 0);
					_ySpn.setSelection = spnValue!("a.y", C, int)(_editC.keys, 0);
				} else {
					int x = spnValue!("a.x", C, int)(_editC.keys, 0);
					_xSpn.setSelection = x == spnValue!("a.x", BgImage, int)(_editB.keys, 0) ? x : 0;
					int y = spnValue!("a.y", C, int)(_editC.keys, 0);
					_ySpn.setSelection = y == spnValue!("a.y", BgImage, int)(_editB.keys, 0) ? y : 0;
				}
			}
		} else static if (UseCards) {
			if (_flag) _flag.setEnabled = _editC.length > 0;
			bool enbl = _editC.length > 0;
			_xSpn.setEnabled = enbl;
			_ySpn.setEnabled = enbl;
			_scaleSpn.setEnabled = enbl;
			static if (is (C == EnemyCard)) {
				_escTMenu.setEnabled = enbl;
			}
			if (_editC.length == 1) {
				auto card = _editC.keys[0];
				_xSpn.setSelection = card.x;
				_ySpn.setSelection = card.y;
				_scaleSpn.setSelection = cast(int) rndtol(card.scale * 100.0);
				static if (is (C == EnemyCard)) {
					_escTMenu.setSelection = card.escape;
				}
			} else if (_editC.length > 1) {
				_xSpn.setSelection = spnValue!("a.x", C, int)(_editC.keys, 0);
				_ySpn.setSelection = spnValue!("a.y", C, int)(_editC.keys, 0);
				_scaleSpn.setSelection
					= spnValue!("cast(int) rndtol(a.scale * 100.0)", C, int)(_editC.keys, 100);
				static if (is (C == EnemyCard)) {
					_escTMenu.setSelection = spnValue!("a.escape", C, bool)(_editC.keys, false);
				}
			}
		} else static if (UseBacks) {
			if (_flag) _flag.setEnabled = _editB.length > 0;
			bool enbl = _editB.length > 0;
			_xSpn.setEnabled = enbl;
			_ySpn.setEnabled = enbl;
			_wSpn.setEnabled = enbl;
			_hSpn.setEnabled = enbl;
			_maskTMenu.setEnabled = enbl;
			if (_editB.length == 1) {
				auto back = _editB.keys[0];
				_xSpn.setSelection = back.x;
				_ySpn.setSelection = back.y;
				_wSpn.setSelection = back.width;
				_hSpn.setSelection = back.height;
				_maskTMenu.setSelection = back.mask;
			} else if (_editB.length > 1) {
				_xSpn.setSelection = spnValue!("a.x", BgImage, int)(_editB.keys, 0);
				_ySpn.setSelection = spnValue!("a.y", BgImage, int)(_editB.keys, 0);
				_wSpn.setSelection = spnValue!("a.width", BgImage, int)(_editB.keys, 0);
				_hSpn.setSelection = spnValue!("a.height", BgImage, int)(_editB.keys, 0);
				_maskTMenu.setSelection = spnValue!("a.mask", BgImage, bool)(_editB.keys, false);
			}
		} else {
			static assert (0);
		}
		refreshStatusLine();
	}
	void refreshStatusLine() {
		static if (UseCards && UseBacks) {
			statusLine = _prop.msgs.areaViewStatus(_summ, cast(AbstractSpCard[]) _editC.keys, _editB.keys, _summ !is null);
		} else static if (UseCards) {
			statusLine = _prop.msgs.areaViewStatus(_summ, cast(AbstractSpCard[]) _editC.keys, cast(BgImage[]) [], _summ !is null);
		} else static if (UseBacks) {
			statusLine = _prop.msgs.areaViewStatus(_summ, cast(AbstractSpCard[]) [], _editB.keys, _summ !is null);
		}
	}
	static if (UseCards) {
		static int staticCardsIndex(A area) {
			static if (UseBacks) {
				return area.backs.length;
			} else {
				return 0;
			}
		}
		int cardsIndex() {
			return staticCardsIndex(_area);
		}
	}

	void refreshSelected() {
		static if (UseCards) {
			int[] selsC = __refreshSelected(_viewCards, _cards, _editC, _area.cards, cardsIndex);
			_cards.setSelection = selsC;
		}
		static if (UseBacks) {
			int[] selsB = __refreshSelected(_viewBacks, _backs, _editB, _area.backs, 0);
			_backs.setSelection = selsB;
		}
		refreshControls;
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
			_edit(l.getSelectionIndices);
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
		comp.setLayout = zeroGridLayout(1);
		auto label = new CLabel(comp, SWT.NONE);
		label.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		label.setText = name;
		label.setImage = image;
		auto list = new Table(comp, SWT.MULTI | SWT.CHECK | SWT.BORDER | SWT.H_SCROLL | SWT.V_SCROLL);
		new FullTableColumn(list, SWT.NONE);
		auto mkl = new MKListener!(C)(edit, items);
		auto closePreview = new ClosePreview;
		list.getVerticalBar.addSelectionListener(closePreview);
		list.getHorizontalBar.addSelectionListener(closePreview);
		list.addSelectionListener = new VCheckListener;
		list.addMouseListener(mkl);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = 0;
		gd.heightHint = 0;
		list.setLayoutData = gd;
		{
			auto menu = new Menu(parent.getShell, SWT.POP_UP);
			createMenuItem(menu, _prop.msgs.menuCEdit, _prop.images.menuCEdit, {
				edit(list.getSelectionIndices);
			});
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_prop, menu, tcpd, true, true, true, true);
			static if ((is(A : Area) || is(A : Battle)) && is(C : AbstractSpCard)) {
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(menu, _prop.msgs.menuEditEvent, _prop.images.menuEditEvent, &openEvent);
			}
			list.setMenu(menu);
		}
		return list;
	}
	static if (UseCards) {
		void __setAuto(bool value) {
			_area.spAuto = value;
			if (_autoMenu) _autoMenu.setSelection = value;
			if (_autoTMenu) _autoTMenu.setSelection = value;
			if (_customMenu) _customMenu.setSelection = !value;
			if (_customTMenu) _customTMenu.setSelection = !value;
			callModEvent();
		}
	}
	class VCheckListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			static if (UseCards) {
				foreach (i, itm; _cards.getItems) {
					_imgp.images[cardsIndex + i].visible = _viewCards && itm.getChecked;
				}
			}
			static if (UseBacks) {
				foreach (i, itm; _backs.getItems) {
					_imgp.images[i].visible = _viewBacks && itm.getChecked;
				}
			}
		}
	}
	void openFlagView() {
		if (-1 == _flag.getSelectionIndex) return;
		auto flag = _summ.flagDirRoot.findFlag(_flag.getText);
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
		auto gl = windowGridLayout(1);
		gl.marginWidth = 0;
		gl.marginHeight = 0;
		setLayout = gl;
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
		_preview = new Preview(_prop, parent.getShell);
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
		{
			auto toolbar = new ToolBar(this, SWT.FLAT);
			toolbar.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			setupToolBar(toolbar);
		}
		auto lrSash = new SplitPane(this, SWT.HORIZONTAL);
		lrSash.setLayoutData = new GridData(GridData.FILL_BOTH);
		auto left = new Composite(lrSash, SWT.NONE);
		{
			auto lgl = zeroMarginGridLayout(2, false);
			lgl.verticalSpacing = WGL_SPACING;
			left.setLayout = lgl;
		}
		{
			Composite listsP;
			static if (UseCards && UseBacks) {
				_sash = new SplitPane(left, SWT.VERTICAL);
				listsP = _sash;
			} else {
				listsP = new Composite(left, SWT.NONE);
				listsP.setLayout = new FillLayout;
			}
			auto lpgd = new GridData(GridData.FILL_BOTH);
			lpgd.horizontalSpan = 2;
			listsP.setLayoutData = lpgd;
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
					auto target = new DropTarget(_cards, DND.DROP_DEFAULT | DND.DROP_COPY);
					target.setTransfer([cast(Transfer) FileTransfer.getInstance, XMLBytesTransfer.getInstance]);
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
				new BLDropTarget(_backs);
				_backs.addMouseTrackListener(prevTrig);
				_backs.addMouseMoveListener(prevTrig);
			}
			static if (UseCards && UseBacks) {
				_cards.addMouseListener(new class MouseAdapter {
					override void mouseDown(MouseEvent e) {
						if (e.button == 1 && (e.stateMask & SWT.CTRL) == 0 && (e.stateMask & SWT.SHIFT) == 0) {
							_imgp.deselectRange(0, _area.backs.length);
							_backs.deselectAll;
							typeof(_editB) editB;
							_editB = editB;
							refreshControls;
						}
					}
				});
				_backs.addMouseListener(new class MouseAdapter {
					override void mouseDown(MouseEvent e) {
						if (e.button == 1 && (e.stateMask & SWT.CTRL) == 0 && (e.stateMask & SWT.SHIFT) == 0) {
							_imgp.deselectRange(cardsIndex, cardsIndex + _area.cards.length);
							_cards.deselectAll;
							typeof(_editC) editC;
							_editC = editC;
							refreshControls;
						}
					}
				});
				_sash.setWeights([_prop.var.etc.areaSashT, _prop.var.etc.areaSashB]);
			}
			static if (UseCards && UseBacks) {
				_sash.addDisposeListener(new class DisposeListener {
					override void widgetDisposed(DisposeEvent e) {
						_prop.var.etc.areaSashT = _sash.getWeights[0];
						_prop.var.etc.areaSashB = _sash.getWeights[1];
					}
				});
			}
		}
		if (_summ) {
			auto lFlag = new Label(left, SWT.NONE);
			lFlag.setText = _prop.msgs.areaViewFlagDesc;
			_flag = new Combo(left, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			_flag.setVisibleItemCount = 20;
			_flag.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			_flag.add(_prop.msgs.noFlag);
			refreshFlag();
			_flag.addSelectionListener(new SelFlag);
			_comm.refFlag.add(&refFlag);
			_comm.delFlag.add(&refFlag);
			_flag.addDisposeListener(new FlagsDispose);
			{
				auto menu = new Menu(_flag.getShell, SWT.POP_UP);
				createMenuItem(menu, _prop.msgs.menuOpenFlagView, _prop.images.menuOpenFlagView, &openFlagView);
				_flag.setMenu = menu;
			}
			static if (RefCards) {
				auto lRef = new Label(left, SWT.NONE);
				lRef.setText = _prop.msgs.areaViewRefAreaDesc;
				_refAreas = new Combo(left, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
				_refAreas.setVisibleItemCount = 20;
				_refAreas.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				_refAreas.add(_prop.msgs.noRefArea);
				refreshRefAreas();
				_refAreas.addSelectionListener(new class SelectionAdapter {
					override void widgetSelected(SelectionEvent e) {
						int sel = _refAreas.getSelectionIndex;
						_refTarget = sel <= 0 ? null : _refAreasArr[sel - 1];
						refreshPanel();
					}
				});
				{
					auto menu = new Menu(_refAreas.getShell, SWT.POP_UP);
					createMenuItem(menu, _prop.msgs.menuOpenTableView, _prop.images.menuOpenTableView, &openRefAreaView);
					_refAreas.setMenu = menu;
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
				_refAreas.addDisposeListener(new class DisposeListener {
					override void widgetDisposed(DisposeEvent e) {
						_comm.refArea.remove(&refreshRefAreasA);
						_comm.delArea.remove(&refreshRefAreasA);
						_comm.refBattle.remove(&refreshRefAreasB);
						_comm.delBattle.remove(&refreshRefAreasB);
						_comm.refMenuCard.remove(&refRefMenuCard);
						_comm.addMenuCard.remove(&addRefMenuCard);
						_comm.delMenuCard.remove(&delRefMenuCard);
						_comm.upMenuCard.remove(&upRefMenuCards);
						_comm.downMenuCard.remove(&downRefMenuCards);
					}
				});
			}
		}
		{
			createImagePane(lrSash);
			static if (is (C == MenuCard) || UseBacks) {
				auto target = new DropTarget(_imgp, DND.DROP_DEFAULT | DND.DROP_COPY);
				static if (is (C == MenuCard)) {
					target.setTransfer([cast(Transfer) FileTransfer.getInstance, XMLBytesTransfer.getInstance]);
				} else {
					target.setTransfer([FileTransfer.getInstance]);
				}
				target.addDropListener(new IPDropTarget);
			}
			static if (UseBacks) appendBgImages(0, area.backs, false, false);
			static if (UseCards) appendCards(0, area.cards, false, false);
			appendPartyCards();
		}
		static if (is(A : Battle) && is(C : EnemyCard)) {
			{
				auto target = new DropTarget(imagePane, DND.DROP_DEFAULT | DND.DROP_LINK);
				target.setTransfer([XMLBytesTransfer.getInstance]);
				target.addDropListener(new DTListener(true));
			}
			{
				auto target = new DropTarget(cardList, DND.DROP_DEFAULT | DND.DROP_LINK);
				target.setTransfer([XMLBytesTransfer.getInstance]);
				target.addDropListener(new DTListener(false));
			}
		}
		lrSash.setWeights = [_prop.var.etc.areaViewL, _prop.var.etc.areaViewR];
		lrSash.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				auto ws = (cast(SplitPane) e.widget).getWeights;
				_prop.var.etc.areaViewL = ws[0];
				_prop.var.etc.areaViewR = ws[1];
			}
		});
		static if (UseCards) refreshCards;
		static if (UseBacks) refreshBacks;
	}
	private string _statusLine;
	private void statusLine(string statusLine) {
		_statusLine = statusLine;
		_comm.statusLine(_imgp, statusLine);
	}
	string statusLine() {return _statusLine;}

	A area() {
		return _area;
	}
	Summary summary() {
		return _summ;
	}
	static if (is(A : Area) || is(A : Battle)) {
		void openEvent() {
			if (!_summ) return;
			string path;
			auto sels = _cards.getSelection;
			if (sels.length) {
				auto card = cast(C) sels[0].getData;
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
		refresh;
	}
	private void replText() {
		static if (UseCards) {
			foreach (i, c; _area.cards) {
				auto img = _imgp.images[cardsIndex + i];
				string name = cardName(c);
				img.title = name;
				img.createImage;
				cardList.getItem(i).setText = name;
			}
			_imgp.redraw;
		}
	}
	static if (UseCards) {
		private void refreshCardState() {
			for (int i = 0; i < _area.cards.length; i++) {
				auto fi = cast(FlexImage) _imgp.images[cardsIndex + i];
				fi.smoothing = _prop.var.etc.smoothingCard;
				fi.createImage;
			}
			_imgp.redraw;
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
				_cards.getItem(i).setText = cardName(c);
				_cards.getItem(i).setData = c;
				partyIndex++;
			}
		}
		static if (UseBacks) {
			foreach (i, b; _area.backs) {
				auto v = _imgp.images[i].visible;
				auto fi = create(b);
				fi.visible = v;
				_imgp.set(i, fi);
				_backs.getItem(i).setText = baseName(b.path);
				_backs.getItem(i).setData = b;
				partyIndex++;
			}
		}
		_imgp.removeRange(partyIndex, _imgp.images.length);
		appendPartyCards();
		_imgp.select = sels;
		_imgp.redraw;
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
			foreach (c; cs) {
				_imgp.append(createRefCard(c));
			}
		}
		PileImage createRefCard(C2)(in C2 c) {
			auto img = createCardImage!PileImage(c, _prop.var.etc.smoothingCard);
			img.alpha = _prop.var.etc.partyCardAlpha;
			return img;
		}
	}
	void refresh() {
		static if (UseCards && is (C == EnemyCard)) {
			_bgm.refresh;
		}
		refreshPanel;
	}
	private void removeImpl(T)(int index, ref T[PileImage] tbl, int startIndex) {
		tbl.remove(_imgp.images[startIndex + index]);
		_imgp.remove(startIndex + index);
		callModEvent();
	}
	private void removeRangeImpl(T)(int fromIndex, int toIndex, ref T[PileImage] tbl, int startIndex) {
		for (int i = fromIndex + startIndex; i < toIndex + startIndex; i++) {
			tbl.remove(_imgp.images[i]);
		}
		_imgp.removeRange(startIndex + fromIndex, startIndex + toIndex);
		callModEvent();
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

	void up() {
		int[] cIdcs;
		int[] bIdcs;
		static if (UseCards) {
			if (_viewCards) cIdcs = _cards.getSelectionIndices;
		}
		static if (UseBacks) {
			if (_viewBacks) bIdcs = _backs.getSelectionIndices;
		}
		_undo ~= new UndoUp(this, _comm, _area, _summ, cIdcs, bIdcs);
		upImpl(this, _comm, _area, cIdcs, bIdcs);
	}
	private static void upImpl(AbstractAreaView v, Commons comm, A area, int[] cIdcs, int[] bIdcs) {
		static if (UseCards) {
			upImpl2!(C)(v, v ? v._cards : null, &area.swapCards, staticCardsIndex(area), cIdcs);
			comm.upMenuCard.call(area.cwxPath, cIdcs);
		}
		static if (UseBacks) {
			upImpl2!(BgImage)(v, v ? v._backs : null, &area.swapBacks, 0, bIdcs);
			comm.upBgImage.call(area.cwxPath, bIdcs);
		}
		if (v) {
			v.refreshSelected;
			if (cIdcs.length > 0 || bIdcs.length > 0) v._imgp.redraw;
		}
	}
	void down() {
		int[] cIdcs;
		int[] bIdcs;
		static if (UseCards) {
			if (_viewCards) cIdcs = _cards.getSelectionIndices;
		}
		static if (UseBacks) {
			if (_viewBacks) bIdcs = _backs.getSelectionIndices;
		}
		_undo ~= new UndoDown(this, _comm, _area, _summ, cIdcs, bIdcs);
		downImpl(this, _comm, _area, cIdcs, bIdcs);
	}
	private static void downImpl(AbstractAreaView v, Commons comm, A area, int[] cIdcs, int[] bIdcs) {
		static if (UseCards) {
			downImpl2!(C)(v, v ? v._cards : null, &area.swapCards, staticCardsIndex(area), cIdcs, area.cards.length);
			comm.downMenuCard.call(area.cwxPath, cIdcs);
		}
		static if (UseBacks) {
			downImpl2!(BgImage)(v, v ? v._backs : null, &area.swapBacks, 0, bIdcs, area.backs.length);
			comm.downBgImage.call(area.cwxPath, bIdcs);
		}
		if (v) {
			v.refreshSelected;
			if (cIdcs.length > 0 || bIdcs.length > 0) v._imgp.redraw;
		}
	}
	static if (UseCards && UseBacks) {
		private void reverseView(T)(ref bool view, Table list, int[T] edits, T[] delegate() col, int startIndex,
				MenuItem menu, ToolItem titm) {
			if (_imgp.isVisible) .forceFocus(this, false);
			view = !view;
			list.setEnabled = view;
			for (int i = 0; i < col().length; i++) {
				auto fi = cast(FlexImage) _imgp.images[startIndex + i];
				fi.visible = view && list.getItem(i).getChecked;
				if (!view && fi.selected) {
					_imgp.deselect(fi);
					edits.remove(col()[i]);
				}
			}
			if (!view) {
				list.deselectAll;
			}
			if (menu) menu.setSelection = view;
			if (titm) titm.setSelection = view;
			refreshControls;
			_imgp.redraw;
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
					_cards.getItem(i).setText = fi.title;
					_cards.getItem(i).setData = c;
					refreshControls;
					_comm.refMenuCard.call(c.cwxPath);
					_comm.refUseCount.call;
					_imgp.redraw;
					callModEvent();
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
			auto dlg = new SpCardDialog!(C)(_comm, _prop, getShell, _summ, c);
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
					refreshSelected;
					break;
				}
			}
			UndoEdit undo = null;
			auto dlg = new SpCardDialog!(C)(_comm, _prop, getShell, _summ, card);
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
				auto c = cast(C) itm.getData;
				if (c.name == newText) return;
				_undo ~= new UndoEdit(this, _comm, _area, _summ, [itm.getParent.indexOf(itm)], []);
				c.name = newText;
				itm.setText(column, c.name);
				refreshPanel();
				_comm.refMenuCard.call(c.cwxPath);
				callModEvent();
			}
		} else static if (is(C : EnemyCard)) {
			void enemyEditEnd(TableItem itm, int column, CCombo combo) {
				assert (_summ);
				int i = combo.getSelectionIndex;
				if (-1 == i) return;
				auto c = cast(C) itm.getData;
				if (c.id == _summ.casts[i].id) return;
				_undo ~= new UndoEdit(this, _comm, _area, _summ, [itm.getParent.indexOf(itm)], []);
				c.id = _summ.casts[i].id;
				itm.setText(column, cardName(c));
				refreshPanel();
				_comm.refMenuCard.call(c.cwxPath);
				callModEvent();
			}
			void createEnemyCombo(TableItem itm, int column, out string[] strs, out string str) {
				assert (_summ);
				auto c = cast(C) itm.getData;
				foreach (cc; _summ.casts) {
					string s = to!string(cc.id) ~ "." ~ cc.name;
					strs ~= s;
					if (cc.id == c.id) {
						str = s;
					}
				}
			}
		} else static assert (0);
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
			auto castCard = summary.casts(card.id);
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
			auto castCard = summary.casts(card.id);
			return castCard ? castCard.name : "";
		} else static assert (0, C2);
	}
	string cardImagePath(C2)(in C2 card) {
		static if (is(typeof(card.path))) {
			return _comm.skin.findImagePath(card.path, summary.scenarioPath);
		} else static if (is(typeof(summary.casts(card.id)))) {
			auto castCard = summary.casts(card.id);
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
					_backs.getItem(i).setText = baseName(back.path);
					_backs.getItem(i).setData = b;
					refreshControls;
					_comm.refBgImage.call(b.cwxPath);
					_comm.refUseCount.call;
					_imgp.redraw;
					callModEvent();
					return;
				}
			}
			assert (0);
		}
		void createBackground() {
			auto b = new BgImage("", "", 0, 0, 0, 0, false);
			auto dlg = new BgImageDialog(_comm, _prop, getShell, _summ, b);
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
					refreshSelected;
					break;
				}
			}
			UndoEdit undo = null;
			auto dlg = new BgImageDialog(_comm, _prop, getShell, _summ, back);
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
			int i = combo.getSelectionIndex;
			if (-1 == i) return;
			auto b = cast(BgImage) itm.getData;
			if (0 == i) {
				if (b.path == "") return;
				_undo ~= new UndoEdit(this, _comm, _area, _summ, [], [itm.getParent.indexOf(itm)]);
				b.path = "";
				itm.setText(column, "");
			} else {
				string mt = combo.getText;
				if (std.string.startsWith(mt, "/")) {
					mt = mt["/".length .. $];
				}
				if (b.path == mt) return;
				_undo ~= new UndoEdit(this, _comm, _area, _summ, [], [itm.getParent.indexOf(itm)]);
				b.path = mt;
				itm.setText(column, baseName(decodePath(mt)));
			}
			refreshPanel();
			_comm.refBgImage.call(b.cwxPath);
			callModEvent();
		}
		void createBgImageCombo(TableItem itm, int column, out string[] strs, out string str) {
			auto b = cast(BgImage) itm.getData;
			strs ~= _prop.msgs.imageNone;
			str = _prop.msgs.imageNone;
			bool def;
			string p = _comm.skin.findImagePathF(b.path, _summ ? _summ.scenarioPath : null, def);
			p = nabs(p);
			foreach (t; _comm.skin.tables) {
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
						recurse(full, sFile ~ std.path.sep);
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
			recurse(_summ.scenarioPath, std.path.sep);
		}
		bool isViewBacks() {
			return _viewBacks;
		}
	}

	bool isViewMsg() {return _viewMsg;}
	bool isViewParty() {return _viewParty;}
	bool isFixed() {return _fixed;}
	static if (UseCards) {
		bool spCustom() {return !_area.spAuto;}
	}
	private void setupTLP(TopLevelPanel tlp) {
		_tlp.putMenuChecked(MenuID.ViewParty, &reverseViewParty, &isViewParty);
		_tlp.putMenuChecked(MenuID.Fixed, &reverseFixed, &isFixed);
		static if (UseCards && UseBacks) {
			_tlp.putMenuChecked(MenuID.ViewCards, &reverseViewCards, &isViewCards);
			_tlp.putMenuChecked(MenuID.ViewBacks, &reverseViewBacks, &isViewBacks);
		}
		static if (UseCards) {
			_tlp.putMenuChecked(MenuID.Auto, &setAuto, &_area.spAuto);
			_tlp.putMenuChecked(MenuID.Custom, &setCustom, &spCustom);
		}
		_tlp.putMenuAction(MenuID.Refresh, &refresh);
		_tlp.putMenuAction(MenuID.Undo, &undo);
		_tlp.putMenuAction(MenuID.Redo, &redo);
		_tlp.putMenuAction(MenuID.Up, &up);
		_tlp.putMenuAction(MenuID.Down, &down);
	}

	/// メニューにAreaViewで使用するアイテムを設定する。
	/// Params:
	/// bar = メニュー。
	void setupMenu(Menu bar) {
		auto mv = createMenu(bar, _prop.msgs.menuCardsAndBacks);
		_vpMenu = createMenuItem(mv, _prop.msgs.menuViewParty, _prop.images.menuViewParty,
			&reverseViewParty, SWT.CHECK);
		_vpMenu.setSelection = _viewParty;
		_vmMenu = createMenuItem(mv, _prop.msgs.menuViewMsg, _prop.images.menuViewMsg,
			&reverseViewMsg, SWT.CHECK);
		_vmMenu.setSelection = _viewMsg;
		new MenuItem(mv, SWT.SEPARATOR);
		_vfMenu = createMenuItem(mv, _prop.msgs.menuFixed, _prop.images.menuFixed,
			&reverseFixed, SWT.CHECK);
		_vfMenu.setSelection = _fixed;
		static if (is(C : EnemyCard) || RefCards) {
			if (_summ) {
				new MenuItem(mv, SWT.SEPARATOR);
				_dbgMenu = createMenuItem(mv,
					_prop.msgs.menuEnemyCardDebugView,
					_prop.images.menuEnemyCardDebugView,
					&reverseDebugMode, SWT.CHECK);
				_dbgMenu.setSelection = _dbgMode;
			}
		}
		static if (UseCards && UseBacks) {
			new MenuItem(mv, SWT.SEPARATOR);
			_vcMenu = createMenuItem(mv, _prop.msgs.menuViewCards, _prop.images.menuViewCards,
				&reverseViewCards, SWT.CHECK);
			_vcMenu.setSelection = _viewCards;
			_vbMenu = createMenuItem(mv, _prop.msgs.menuViewBacks, _prop.images.menuViewBacks,
				&reverseViewBacks, SWT.CHECK);
			_vbMenu.setSelection = _viewBacks;
		}
		static if (UseCards) {
			new MenuItem(mv, SWT.SEPARATOR);
			_autoMenu = createMenuItem(mv, _prop.msgs.menuAuto, _prop.images.menuAuto, &setAuto, SWT.RADIO);
			_customMenu = createMenuItem(mv, _prop.msgs.menuCustom, _prop.images.menuCustom, &setCustom, SWT.RADIO);
			_autoMenu.setSelection = _area.spAuto;
			_customMenu.setSelection = !_area.spAuto;
		}
		new MenuItem(mv, SWT.SEPARATOR);
		static if (is (C == MenuCard)) {
			createMenuItem(mv, _prop.msgs.menuNewMenuCard, _prop.images.menuNewMenuCard, &createCard);
		} else static if (is (C == EnemyCard)) {
			createMenuItem(mv, _prop.msgs.menuNewEnemyCard, _prop.images.menuNewEnemyCard, &createCard);
		}
		static if (UseBacks) {
			createMenuItem(mv, _prop.msgs.menuNewBack, _prop.images.menuNewBack, &createBackground);
		}
	}

	/// ツールバーにAreaViewで使用するアイテムを設定する。
	/// Params:
	/// bar = ツールバー。
	private void setupToolBar(ToolBar bar) {
		static if (is(A : Area)) {
			if (cast(AreaSceneWindow) tlpData(this).tlp) {
				createToolItem(bar, _prop.msgs.ttEditEvent, _prop.images.areaEventTreeView, &openEvent);
				new ToolItem(bar, SWT.SEPARATOR);
			}
		} else static if (is(A : Battle)) {
			if (cast(BattleSceneWindow) tlpData(this).tlp) {
				createToolItem(bar, _prop.msgs.ttEditEvent, _prop.images.battleEventTreeView, &openEvent);
				new ToolItem(bar, SWT.SEPARATOR);
			}
		}
		if (!_tlp) {
			createToolItem(bar, _prop.msgs.ttRefresh, _prop.images.menuRefresh, &refresh);
			new ToolItem(bar, SWT.SEPARATOR);
		}
		_vpTMenu = createToolItem(bar,
			_prop.msgs.ttViewParty, _prop.images.menuViewParty,
			&reverseViewParty, SWT.CHECK);
		_vpTMenu.setSelection = _viewParty;
		_vmTMenu = createToolItem(bar,
			_prop.msgs.ttViewMsg, _prop.images.menuViewMsg,
			&reverseViewMsg, SWT.CHECK);
		_vmTMenu.setSelection = _viewMsg;
		new ToolItem(bar, SWT.SEPARATOR);
		_vfTMenu = createToolItem(bar,
			_prop.msgs.ttFixed, _prop.images.menuFixed,
			&reverseFixed, SWT.CHECK);
		_vfTMenu.setSelection = _fixed;
		static if (is(C : EnemyCard) || RefCards) {
			if (_summ) {
				new ToolItem(bar, SWT.SEPARATOR);
				_dbgTMenu = createToolItem(bar,
					_prop.msgs.ttEnemyCardDebugView,
					_prop.images.menuEnemyCardDebugView,
					&reverseDebugMode, SWT.CHECK);
				_dbgTMenu.setSelection = _dbgMode;
			}
		}
		static if (UseCards && UseBacks) {
			new ToolItem(bar, SWT.SEPARATOR);
			_vcTMenu = createToolItem(bar,
				_prop.msgs.ttViewCards, _prop.images.menuViewCards,
				&reverseViewCards, SWT.CHECK);
			_vcTMenu.setSelection = _viewCards;
			_vbTMenu = createToolItem(bar,
				_prop.msgs.ttViewBacks, _prop.images.menuViewBacks,
				&reverseViewBacks, SWT.CHECK);
			_vbTMenu.setSelection = _viewBacks;
		}
		new ToolItem(bar, SWT.SEPARATOR);
		if (!_tlp) {
			createToolItem(bar, _prop.msgs.ttUndo, _prop.images.menuUndo, &undo);
			createToolItem(bar, _prop.msgs.ttRedo, _prop.images.menuRedo, &redo);
			new ToolItem(bar, SWT.SEPARATOR);
			createToolItem(bar, _prop.msgs.ttUp, _prop.images.menuUp, &up);
			createToolItem(bar, _prop.msgs.ttDown, _prop.images.menuDown, &down);
			new ToolItem(bar, SWT.SEPARATOR);
		}
		static if (UseCards) {
			_autoTMenu = createToolItem(bar, _prop.msgs.ttAuto, _prop.images.menuAuto, &setAuto, SWT.RADIO);
			_customTMenu = createToolItem(bar, _prop.msgs.ttCustom, _prop.images.menuCustom, &setCustom, SWT.RADIO);
			_autoTMenu.setSelection = _area.spAuto;
			_customTMenu.setSelection = !_area.spAuto;
			new ToolItem(bar, SWT.SEPARATOR);
			static if (is (C == MenuCard)) {
				createToolItem(bar, _prop.msgs.ttNewMenuCard, _prop.images.menuNewMenuCard, &createCard);
			} else static if (is (C == EnemyCard)) {
				createToolItem(bar, _prop.msgs.ttNewEnemyCard, _prop.images.menuNewEnemyCard, &createCard);
			} else {
				static assert (0);
			}
		}
		static if (UseBacks) {
			createToolItem(bar, _prop.msgs.ttNewBack, _prop.images.menuNewBack, &createBackground);
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
			_maskTMenu = createToolItem(bar, _prop.msgs.ttMask, _prop.images.menuMask, &setMask, SWT.CHECK);
			_maskTMenu.setEnabled = false;
		}
		static if (is (C == EnemyCard)) {
			new ToolItem(bar, SWT.SEPARATOR);
			_escTMenu = createToolItem(bar, _prop.msgs.ttDoEscape, _prop.images.menuDoEscape,
					&setEscape, SWT.CHECK);
			_escTMenu.setEnabled = false;
			new ToolItem(bar, SWT.SEPARATOR);
			auto skin = _comm.skin;
			_bgm = new MaterialSelect!(MtType.BGM, CCombo, CCombo)
				(_comm, _prop, _summ, &selectBGM, [_prop.msgs.bgmNone]);
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
			_comm.refFlag.remove(&refFlag);
			_comm.delFlag.remove(&refFlag);
		}
	}
	private class SelFlag : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			int index = _flag.getSelectionIndex;
			string flag = index <= 0 ? "" : _flag.getText;
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
	private void refFlag(Flag flag) {
		refreshFlag();
	}
	private void refreshFlag() {
		if (!_flag) return;
		string f = _flag.getText;
		_flag.removeAll();
		_flag.add(_prop.msgs.noFlag);
		_flag.select = 0;
		foreach (i, fl; _summ.flagDirRoot.allFlags) {
			auto path = fl.path;
			_flag.add(path);
			if (path == f) _flag.setText = path;
		}
	}

	void reverseViewParty() {
		_viewParty = !_viewParty;
		int imgLen = _imgp.images.length;
		int partyLen = _prop.looks.partyCardXY.length;
		for (int i = imgLen - 2; i >= imgLen - partyLen - 1; i--) {
			_imgp.images[i].visible = _viewParty;
		}
		if (_vpMenu) _vpMenu.setSelection = _viewParty;
		if (_vpTMenu) _vpTMenu.setSelection = _viewParty;
		_imgp.redraw;
	}
	void reverseViewMsg() {
		_viewMsg = !_viewMsg;
		_imgp.images[$ - 1].visible = _viewMsg;
		if (_vmMenu) _vmMenu.setSelection = _viewMsg;
		if (_vmTMenu) _vmTMenu.setSelection = _viewMsg;
		_imgp.redraw;
	}
	void reverseFixed() {
		_fixed = !_fixed;
		static if (UseCards) {
			_imgp.fixedRange(_fixed, cardsIndex, cardsIndex + _area.cards.length);
		}
		static if (UseBacks) {
			_imgp.fixedRange(_fixed, 0, _area.backs.length);
		}
		if (_vfMenu) _vfMenu.setSelection = _fixed;
		if (_vfTMenu) _vfTMenu.setSelection = _fixed;
		_imgp.redraw;
	}
	private int insertIndex(Table list) {
		int[] indices = list.getSelectionIndices.sort;
		return indices.length ? indices[$ - 1] + 1 : list.getItemCount;
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
				v._imgp.deselectAll;
				v._imgp.insert(v.cardsIndex + index, img);
				v._imgp.images[v.cardsIndex + index].visible = check;
				auto itm = new TableItem(v._cards, SWT.NONE, index);
				itm.setImage = v._prop.images.cards;
				itm.setData = card;
				itm.setChecked = check;
				itm.setText = v.cardName(card);
				if (select && v._viewCards) {
					v._imgp.select(img);
					if (refresh) {
						v.refreshSelected;
					}
				}
				v._imgp.redraw;
			}
			comm.addMenuCard.call(card.cwxPath);
			comm.refUseCount.call;
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
			_imgp.insert(cardsIndex + index, imgs);
			foreach (i, c; cards) {
				auto itm = new TableItem(_cards, SWT.NONE, index + i);
				itm.setImage = _prop.images.cards;
				itm.setData = c;
				itm.setChecked = true;
				itm.setText = cardName(c);
			}
			if (select && _viewCards) _imgp.select(imgs);
			callModEvent();
		}
		static if (is (C == MenuCard)) {
			private int cardFromFile(string fname, int x, int y, bool fromImgPane) {
				if (!_summ) return -1;
				if (!hasPath(_summ.scenarioPath, fname)) {
					auto dlg = new MessageBox(getShell, SWT.ICON_QUESTION | SWT.YES | SWT.NO | SWT.CANCEL);
					dlg.setMessage = _prop.msgs.dlgMsgDropCard(fname);
					dlg.setText = _prop.msgs.dlgTitDropCard;
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
					e.detail = _summ ? DND.DROP_COPY : DND.DROP_NONE;
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
							} catch (SWTException e) {}
						}
						if (addC.length) {
							auto undo = new UndoInsert(this.outer, _comm, _area, _summ, addC, []);
							_comm.refPaths.call(_comm.skin.materialPath);
						}
						return;
					} else if (isXMLBytes(e.data)) {
						int[] i = appendCardFromXML(bytesToXML(e.data), 0, 0, false);
						if (i.length > 0) {
							_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, i, []);
						}
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
				v._imgp.deselectAll;
				auto img = v.create(back);
				v._imgp.insert(index, img);
				v._imgp.images[index].visible = check;
				auto itm = new TableItem(v._backs, SWT.NONE, index);
				itm.setImage = v._prop.images.backs;
				itm.setData = back;
				itm.setChecked = check;
				itm.setText = baseName(back.path);
				if (select && v._viewBacks) {
					v._imgp.select(img);
					if (refresh) {
						v.refreshSelected;
					}
				}
				v._imgp.redraw;
			}
			comm.addBgImage.call(back.cwxPath);
			comm.refUseCount.call;
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
			_imgp.insert(index, imgs);
			foreach (i, b; backs) {
				auto itm = new TableItem(_backs, SWT.NONE, index + i);
				itm.setImage = _prop.images.backs;
				itm.setData = b;
				itm.setChecked = true;
				itm.setText = baseName(b.path);
				if (raiseEvent) _comm.addBgImage.call(b.cwxPath);
			}
			if (select && _viewBacks) _imgp.select(imgs);
			callModEvent();
		}
		private int backFromFile(string fname, int x, int y, int w, int h, bool fromImgPane) {
			if (!_summ) return -1;
			if (!hasPath(_summ.scenarioPath, fname)) {
				auto dlg = new MessageBox(getShell, SWT.ICON_QUESTION | SWT.YES | SWT.NO | SWT.CANCEL);
				dlg.setMessage = _prop.msgs.dlgMsgDropBack(fname);
				dlg.setText = _prop.msgs.dlgTitDropBack;
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
		private class BLDropTarget : FileDropTarget {
		public:
			this(Control c) {
				super(c);
			}
			private int[] addB;
		protected:
			override bool canDrop() {return _summ !is null;}
			bool doFile(string path, int x, int y) {
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
			void doExit(string[] copy) {
				assert (_summ);
				scope (exit) addB = [];
				if (copy.length > 0) {
					_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, [], addB);
					_comm.refPaths.call(_comm.skin.materialPath);
				}
			}
		}
	}

	static if (UseCards && is (C == MenuCard)) {
		int[] appendCardFromXML(string xml, int x, int y, bool fromImgPane) {
			try {
				auto root = XNode.parse(xml);
				auto cards = MenuCard.createFromCardNode(root, _prop.var.etc.copyDesc, LATEST_VERSION);
				int[] r;
				// x, y座標を中心にして配置
				auto s = _prop.looks.cardSize;
				auto ins = _prop.looks.menuCardInsets;
				int cx = x - cast(int) (s.width + ins.e + ins.w) / 2;
				int cy = y - cast(int) (s.height + ins.n + ins.s) / 2;
				foreach (card; cards) {
					assert (card.scale == 1.0);
					card.x = cx;
					card.y = cy;
					r ~= appendCard(card, true, true, fromImgPane);
				}
				return r;
			} catch (Exception e) {
				debugln(e);
			}
			return [];
		}
	}
	private class IPDropTarget : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){
			e.detail = _summ ? DND.DROP_COPY : DND.DROP_NONE;
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
				}
				return;
			}
			static if (UseCards && is (C == MenuCard)) {
				if (isXMLBytes(e.data)) {
					scope p = _imgp.toControl(e.x, e.y);
					int[] i = appendCardFromXML(bytesToXML(e.data), p.x, p.y, true);
					if (i.length > 0) {
						_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, i, []);
					}
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
					img.createImage;
					if (cardList.getItem(i).getText != castCard.name) {
						cardList.getItem(i).setText = castCard.name;
						_comm.refMenuCard.call(_area.cards[i].cwxPath);
					}
				}
			}
			imagePane.redraw;
		}
		private void __deleteCast(CastCard castCard) {
			auto skin = _comm.skin;
			foreach (i, c; area.cards) {
				if (castCard.id == c.id) {
					auto img = imagePane.images[cardsIndex + i];
					img.setImageData(.castCard(skin));
					img.createImage;
					cardList.getItem(i).setText = "";
				}
			}
			imagePane.redraw;
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
		int[] appendEnemyFromXML(string xml, int x, int y, bool fromImgPane) {
			int[] r;
			try {
				auto node = XNode.parse(xml);
				if (node.name != CastCard.XML_NAME_M) return [];
				if (summary.id != node.attr("summId", false)) return [];
				bool refr = false;
				auto cards = EnemyCard.createCardsFromNode(node, LATEST_VERSION);
				if (cards.length) {
					foreach (i, c; cards) {
						c.x = x;
						c.y = y;
						r ~= appendCard(c, true, true, fromImgPane);
					}
					_comm.refUseCount.call;
				}
			} catch (Exception e) {
				debugln(e);
			}
			return r;
		}
		class DTListener : DropTargetAdapter {
			private bool _isImgPane;
			this (bool isImgPane) {_isImgPane = isImgPane;}
			override void dragEnter(DropTargetEvent e){
				e.detail = DND.DROP_LINK;
			}
			override void drop(DropTargetEvent e) {
				if (isXMLBytes(e.data)) {
					auto arr = bytesToXML(e.data);
					auto imgp = cast(ImagePane) (cast(DropTarget) e.getSource).getControl;
					int[] indices;
					if (imgp) {
						auto p = imgp.toControl(e.x, e.y);
						indices = appendEnemyFromXML(arr, p.x, p.y, _isImgPane);
					} else {
						indices = appendEnemyFromXML(arr, 0, 0, _isImgPane);
					}
					if (indices.length) {
						_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, indices, []);
					}
				}
			}
		}
	}
	void cut(SelectionEvent se) {
		int[] cs;
		int[] bs;
		static if (UseCards) cs = _cards.getSelectionIndices;
		static if (UseBacks) bs = _backs.getSelectionIndices;
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
		static if (UseCards) cs = _cards.getSelectionIndices;
		static if (UseBacks) bs = _backs.getSelectionIndices;
		_undo ~= new UndoDelete(this, _comm, _area, _summ, cs, bs);
		delImpl;
	}
	private void delImpl() {
		_tcpd.del(null);
	}
	private static void delImpl2(AbstractAreaView v, Commons comm, A area, int[] cIdcs, int[] bIdcs) {
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
			v._imgp.redraw;
			v.refreshSelected;
		}
		comm.refUseCount.call;
	}
	bool canDoTCPD() {
		return _imgp.isVisible;
	}
	static if (UseCards && UseBacks) {
		private class AllTCPD : TCPD {
			void cut(SelectionEvent se) {
				copy(se);
				del(se);
			}
			void copy(SelectionEvent se) {
				scope MenuCard[] cards;
				foreach (i; _cards.getSelectionIndices) {
					cards ~= _area.cards[i];
				}
				scope BgImage[] backs;
				foreach (i; _backs.getSelectionIndices) {
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
							_imgp.deselectAll;
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
							if (_viewCards || _viewBacks) _imgp.redraw;
							refreshSelected;
							_comm.refUseCount.call;
							_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, addC, addB);
						}
					} catch (Exception e) {
						debugln(e);
					}
				}
			}
			void del(SelectionEvent se) {
				delImpl2(this.outer, _comm, _area, _cards.getSelectionIndices, _backs.getSelectionIndices);
			}
			bool canDoTCPD() {
				return _imgp.isVisible;
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
				foreach (i; _cards.getSelectionIndices) {
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
								_imgp.deselectAll;
								foreach (i, c; cs) {
									int index = insertIndex(_cards) + i;
									addC ~= index;
									_area.insert(index, c);
								}
								appendCards(insertIndex(_cards), cs, true, true);
								if (_viewCards) _imgp.redraw;
								refreshSelected;
								_comm.refUseCount.call;
								_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, addC, []);
							}
						} catch (Exception e) {
							debugln(e);
						}
					}
				}
			}
			void del(SelectionEvent se) {
				delImpl2(this.outer, _comm, _area, _cards.getSelectionIndices, []);
			}
			bool canDoTCPD() {
				return _cards.isVisible && _cards.isEnabled;
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
				foreach (i; _backs.getSelectionIndices) {
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
								_imgp.deselectAll;
								foreach (i, b; bs) {
									int index = insertIndex(_backs) + i;
									addB ~= index;
									_area.insert(index, b);
								}
								appendBgImages(insertIndex(_backs), bs, true, true);
								if (_viewBacks) _imgp.redraw;
								refreshSelected;
								_comm.refUseCount.call;
								_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, [], addB);
							}
						} catch (Exception e) {
							debugln(e);
						}
					}
				}
			}
			void del(SelectionEvent se) {
				delImpl2(this.outer, _comm, _area, [], _backs.getSelectionIndices);
			}
			bool canDoTCPD() {
				return _backs.isVisible && _backs.isEnabled;
			}
		}
	}
	void undo() {_undo.undo;}
	void redo() {_undo.redo;}

	bool openCWXPath(string path, bool shellActivate) {
		if (cpempty(path)) {
			.forceFocus(_imgp, shellActivate);
			return true;
		}
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		bool sel(Table list) {
			if (index >= list.getItemCount) return false;
			.forceFocus(_imgp, shellActivate);
			list.select = index;
			list.showSelection;
			return true;
		}
		static if (UseCards && is(C : MenuCard)) {
			if (cate == "menucard") {
				if (cphasattr(path, "opendialog")) {
					if (index >= _cards.getItemCount) return false;
					editCard([index]);
					return true;
				} else {
					if (sel(_cards)) {
						listSelectC;
						return true;
					}
				}
			}
		}
		static if (UseCards && is(C : EnemyCard)) {
			if (cate == "enemycard") {
				if (cphasattr(path, "opendialog")) {
					if (index >= _cards.getItemCount) return false;
					editCard([index]);
					return true;
				} else {
					if (sel(_cards)) {
						listSelectC;
						return true;
					}
				}
			}
		}
		static if (UseBacks) {
			if (cate == "background") {
				if (cphasattr(path, "opendialog")) {
					if (index >= _backs.getItemCount) return false;
					editBack([index]);
					return true;
				} else {
					if (sel(_backs)) {
						listSelectB;
						return true;
					}
				}
			}
		}
		return false;
	}
	string[] openedCWXPath() {
		string[] r;
		static if (UseCards) {
			foreach (i; _cards.getSelectionIndices) {
				r ~= _area.cards[i].cwxPath;
			}
		}
		static if (UseBacks) {
			foreach (i; _backs.getSelectionIndices) {
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

/// 背景画像を生成する。
/// Returns: 背景画像。
FlexImage createBackgroundImage
		(Skin skin, string path, int x, int y, int w, int h, bool transparent) {
	FlexImage r;
	auto ext = cwx.utils.getExt(path);
	if (cfnmatch(ext, "jpy1") || cfnmatch(ext, "jptx") || cfnmatch(ext, "jpdc")) {
		auto data = loadJPYImage(skin, path, []);
		r = new FlexImage(data, x, y, data.width, data.height);
	} else {
		uint baseW = w, baseH = h;
		try {
			dwtImageSize(skin, path, baseW, baseH);
		} catch {
			baseW = w;
			baseH = h;
		}
		r = new FlexImage(path, x, y, baseW, baseH);
	}
	r.transparent = transparent;
	r.newWidth = w;
	r.newHeight = h;
	r.resize;
	return r;
}

/// キャストカード画像(背景のみ)を生成する。
/// Returns: カード背景画像。
PileImage createCastCardBackImage(Props prop, Skin skin, int x, int y) {
	auto cardSize = prop.looks.cardSize;
	auto matPad = prop.looks.castCardInsets;
	int w = cardSize.width + matPad.e + matPad.w;
	int h = cardSize.height + matPad.n + matPad.s;
	auto r = new PileImage(castCard(skin), x, y, w, h);
	r.createImage;
	return r;
}

PImg createCardImageCommon(PImg)(Props prop, ImageData card,
		CInsets matPad, int x, int y, real scale, bool smoothing) {
	auto cardSize = prop.looks.cardSize;
	int w = cardSize.width + matPad.e + matPad.w;
	int h = cardSize.height + matPad.n + matPad.s;
	auto r = new PImg(card, x, y, w, h);
	r.transparent = false;
	r.smoothing = smoothing;
	static if (is(PImg : FlexImage)) {
		r.minimumWidth = cast(int) rndtol(w * prop.looks.cardSizeMin);
		r.minimumHeight = cast(int) rndtol(h * prop.looks.cardSizeMin);
		r.maximumWidth = cast(int) rndtol(w * prop.looks.cardSizeMax);
		r.maximumHeight = cast(int) rndtol(h * prop.looks.cardSizeMax);
		r.ratioFix = true;
		r.newWidth = cast(int) rndtol(w * scale);
		r.newHeight = cast(int) rndtol(h * scale);
	} else {
		r.width = cast(int) rndtol(w * scale);
		r.height = cast(int) rndtol(h * scale);
	}
	return r;
}

/// キャストカード画像を生成する。
/// Returns: カード画像。
PImg createCastCardImage(PImg)(Props prop, Skin skin, CastCard card,
		string sPath, int x, int y, real scale, bool smoothing, bool dbgMode) {
	auto matPad = prop.looks.castCardInsets;
	PImg r;
	if (card) {
		r = createCardImageCommon!PImg(prop, castCardImage(prop, skin, card, sPath, dbgMode),
			matPad, x, y, scale, smoothing);
	} else {
		r = createCardImageCommon!PImg(prop, castCard(skin),
			matPad, x, y, scale, smoothing);
	}
	static if (is(PImg : FlexImage)) {
		r.resize;
	} else {
		r.createImage;
	}
	return r;
}

/// メニューカード画像を生成する。
/// Returns: カード画像。
PImg createMenuCardImage(PImg)(Props prop, Skin skin,
		string title, string path, int x, int y, real scale, bool smoothing) {
	auto matPad = prop.looks.menuCardInsets;
	auto r = createCardImageCommon!PImg(prop, menuCard(skin), matPad, x, y, scale, smoothing);
	r.append(path, matPad, true);
	r.setTitle(title, dwtData(prop.looks.menuCardNameFont(skin.legacy)), dwtData(prop.looks.menuCardNamePoint));
	static if (is(PImg : FlexImage)) {
		r.resize;
	} else {
		r.createImage;
	}
	return r;
}

BgImagesView createBgImagesViewAndMenu(Commons comm, Props prop, Summary summ, BgImageContainer cont, Composite parent, AbstractArea refTarget) {
	auto undo = new UndoManager(prop.var.etc.undoMaxEvent);
	void refUndoMax() {
		undo.max = prop.var.etc.undoMaxEvent;
	}
	auto view = new BgImagesView(comm, prop, summ, cont, parent, refTarget, undo);
	comm.refUndoMax.add(&refUndoMax);
	view.addDisposeListener(new class DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			comm.refUndoMax.remove(&refUndoMax);
		}
	});
	auto bar = new Menu(parent.getShell, SWT.BAR);
	parent.getShell.setMenuBar = bar;
	auto me = createMenu(bar, prop.msgs.menuEdit);
	createMenuItem(me, prop.msgs.menuUndo, prop.images.menuUndo, &view.undo);
	createMenuItem(me, prop.msgs.menuRedo, prop.images.menuRedo, &view.redo);
	new MenuItem(me, SWT.SEPARATOR);
	createMenuItem(me, prop.msgs.menuUp, prop.images.menuUp, &view.up);
	createMenuItem(me, prop.msgs.menuDown, prop.images.menuDown, &view.down);
	new MenuItem(me, SWT.SEPARATOR);
	appendMenuTCPD(prop, me, view, true, true, true, true);
	auto mv = createMenu(bar, prop.msgs.menuView);
	createMenuItem(mv, prop.msgs.menuRefresh, prop.images.menuRefresh, &view.refresh);
	view.setupMenu(bar);
	return view;
}

PileImage createMessageImage(Commons comm, Props prop) {
	auto rect = prop.looks.messageBounds;
	string[char] names;
	string[string] flags;
	// 特殊文字が無いためシナリオパス不要
	auto imgData = previewMessage(comm, prop, "", null, "", [""], names, flags);
	auto img = new PileImage(imgData, rect.x, rect.y, imgData.width, imgData.height);
	img.alpha = prop.var.etc.messageAlpha;
	img.createImage;
	return img;
}

class Preview {
	private Props _prop;
	private Shell _shell;
	private PileImage _image = null;
	private PileImage _showingImage = null;
	private int _x = 0, _y = 0;
	private int _showingX = int.min, _showingY = int.min;
	private int _w = 0, _h = 0;
	private int _itmH = 0;
	private Image _paintImage = null;

	this (Props prop, Shell parentShell) {
		_prop = prop;

		_shell = new Shell(parentShell, SWT.NO_TRIM | SWT.NO_BACKGROUND);
		_shell.setAlpha = _prop.var.etc.previewAlpha;
		_shell.addPaintListener(new Paint);
	}

	class Paint : PaintListener {
		override void paintControl(PaintEvent e) {
			onPaint(e);
		}
	}
	private void onPaint(PaintEvent e) {
		if (_image && _paintImage) {
			auto d = _shell.getDisplay;
			e.gc.drawImage(_paintImage, 0, 0);
		}
	}

	void image(PileImage image, int x, int y, int itmH) {
		if (!_shell || _shell.isDisposed) return;
		_image = image;
		if (_image) {
			_x = x;
			_y = y;
			_itmH = itmH;
		} else {
			_shell.setVisible = false;
			if (_paintImage) {
				_paintImage.dispose();
				_paintImage = null;
			}
			auto region = _shell.getRegion;
			if (region) region.dispose();
		}
	}
	void dispose() {
		if (!_shell || _shell.isDisposed) return;
		close();
		_shell.dispose();
	}
	void show() {
		if (!_shell || _shell.isDisposed) return;
		if (_prop.var.etc.showImagePreview && _image) {
			if (_image is _showingImage && _x == _showingX && _y == _showingY && _shell.getVisible) {
				return;
			}
			_showingImage = _image;
			_showingX = _x;
			_showingY = _y;
			_shell.setVisible = false;
			// 大きすぎる画像はリサイズ
			_w = _image.baseWidth;
			_h = _image.baseHeight;
			if (_prop.var.etc.previewMaxWidth < _w || _prop.var.etc.previewMaxHeight < _h) {
				real ws = cast(real) _prop.var.etc.previewMaxWidth / _w;
				real hs = cast(real) _prop.var.etc.previewMaxHeight / _h;
				real s = std.algorithm.min(ws, hs);
				_w *= s;
				_h *= s;
			}

			// 画面に収まるよう位置合わせ
			auto d = _shell.getDisplay;
			auto dc = d.getClientArea;
			if (_y + _h > dc.height) {
				_y -= _itmH + _h;
			}
			if (_x < 0) {
				_x = 0;
			}
			if (_x + _w > dc.width) {
				_x -= _x + _w - dc.width;
			}
			_shell.setBounds(_x, _y, _w, _h);
			auto data = _image.baseSizeData;
			if (!data) return;
			data = data.scaledTo(_w, _h);
			if (_paintImage) {
				_paintImage.dispose();
			}
			_paintImage = new Image(d, data);

			// 透明色を使う場合は透明部分を除いたRegionを作る
			auto oldReg = _shell.getRegion;
			if (oldReg) oldReg.dispose();
			if (_image.transparent) {
				auto region = new Region;
				auto rect = new Rectangle(0, 0, 0, 1);
				auto pixels = new int[_w];
				foreach (y; 0 .. _h) {
					rect.y = y;
					data.getPixels(0, y, _w, pixels, 0);
					int tStart = 0;
					bool t = true;
					foreach (x; 0 .. _w) {
						bool pt = data.transparentPixel == pixels[x];
						if (pt) tStart = x;
						if (t == pt) {
							continue;
						}
						pt = t;
						if (pt) {
							rect.x = tStart + 1;
							rect.width = x - tStart;
							region.add(rect);
						}
					}
					if (!t) {
						rect.x = tStart + 1;
						rect.width = _w - tStart;
						region.add(rect);
					}
				}
				_shell.setRegion = region;
			} else {
				_shell.setRegion = null;
			}

			_shell.setVisible = true;
		}
	}
	void close() {
		image(null, 0, 0, 0);
	}
}
