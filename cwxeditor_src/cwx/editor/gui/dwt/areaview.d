
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
import cwx.types;
import cwx.menu;
import cwx.msgutils;
import cwx.system;

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
import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.incsearch;

import std.algorithm;
import std.math;
import std.path;
import std.file;
import std.traits;
import std.datetime;
import std.string;
import std.conv;

import org.eclipse.swt.all;

import java.lang.all;

public:

private P spnValue(string T, N, P)(N[] keys, P val) { mixin(S_TRACE);
	auto a = keys[0];
	P value = mixin (T);
	for (int i = 1; i < keys.length; i++) { mixin(S_TRACE);
		a = keys[i];
		if (mixin (T) != value) { mixin(S_TRACE);
			value = val;
			break;
		}
	}
	return value;
}

private void createLabel(ToolBar bar, string label) { mixin(S_TRACE);
	auto comp = new Composite(bar, SWT.NONE);
	comp.setLayout(new CenterLayout(SWT.VERTICAL, 0));
	auto lbl = new Label(comp, SWT.NONE);
	lbl.setText(label);
	createToolItemC(bar, comp);
}

private Spinner createSpinner(ToolBar bar, string label, int max, int min, int sel,
		void delegate(int value) edit, void delegate(int value) enter, int delegate(int oldVal) cancel) { mixin(S_TRACE);
	createLabel(bar, label ~ ":");
	auto spn = new Spinner(bar, SWT.BORDER);
	initSpinner(spn);
	spn.setEnabled(false);
	spn.setMaximum(max);
	spn.setMinimum(min);
	spn.setSelection(sel);
	createToolItemC(bar, spn);
	auto editL = new SpinnerEdit(spn, enter, edit, cancel);
	return spn;
}

private ToolItem createToolItemC(ToolBar bar, Control c) { mixin(S_TRACE);
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
	private void callModEvent() { mixin(S_TRACE);
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
	IncSearch _flagIncSearch;

	void previewTrigger(Table list, int x, int y) { mixin(S_TRACE);
		auto itm = list.getItem(new Point(x, y));
		if (!itm) { mixin(S_TRACE);
			_preview.close();
			return;
		}
		int i = list.indexOf(itm);
		PileImage image = null;
		static if (UseCards) {
			if (_cards is list) { mixin(S_TRACE);
				image = _imgp.images[cardsIndex + i];
			}
		}
		static if (UseBacks) {
			if (_backs is list) { mixin(S_TRACE);
				image = _imgp.images[i];
			}
		}
		if (!image) { mixin(S_TRACE);
			_preview.close();
			return;
		}
		auto b = itm.getBounds();
		auto p = list.toDisplay(b.x, b.y + b.height);
		_preview.image(image, p.x, p.y, b.height);
		_preview.show();
	}
	class ClosePreview : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			_preview.close();
		}
	}
	class PreviewTrigger : MouseTrackAdapter, MouseMoveListener {
		override void mouseExit(MouseEvent e) { mixin(S_TRACE);
			_preview.close();
		}
		override void mouseMove(MouseEvent e) { mixin(S_TRACE);
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
		IncSearch _refAreaIncSearch;
		void refreshRefAreas() { mixin(S_TRACE);
			if (!_summ) return;
			_refAreasArr.length = 0;
			_refAreas.removeAll();
			if (!_area) return;
			_refAreas.add(_prop.msgs.noRefArea);
			_refAreas.select(0);
			bool has = _refTarget is null;
			foreach (a; _summ.areas) { mixin(S_TRACE);
				if(_refTarget is a) has = true;
				if (!_refAreaIncSearch.match(a.name)) continue;
				_refAreasArr ~= a;
				_refAreas.add(to!string(a.id) ~ "." ~ a.name);
				if(_refTarget is a) _refAreas.select(_refAreas.getItemCount() - 1);
			}
			foreach (a; _summ.battles) { mixin(S_TRACE);
				if(_refTarget is a) has = true;
				if (!_refAreaIncSearch.match(a.name)) continue;
				_refAreasArr ~= a;
				_refAreas.add(to!string(a.id) ~ "." ~ a.name);
				if(_refTarget is a) _refAreas.select(_refAreas.getItemCount() - 1);
			}
			if (0 == _refAreas.getSelectionIndex()) { mixin(S_TRACE);
				if (has) { mixin(S_TRACE);
					_refAreas.select(-1);
				} else {
					_refTarget = null;
					foreach (a; _imgp.appends) { mixin(S_TRACE);
						a.data[] = 0;
						delete a.data;
						a.alphaData[] = 0;
						delete a.alphaData;
					}
					_imgp.appends = [];
				}
			}
		}
		void refreshRefAreasA(Area a) {refreshRefAreas();}
		void refreshRefAreasB(Battle a) {refreshRefAreas();}
		@property
		int refCardIndex() { mixin(S_TRACE);
			int partyIndex = 0;
			static if (UseCards) partyIndex += _area.cards.length;
			static if (UseBacks) partyIndex += _area.backs.length;
			return partyIndex;
		}
		void refRefMenuCard(string a) { mixin(S_TRACE);
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath(true), cpparent(a))) return;
			createRefCard();
			_imgp.redraw();
		}
		void addRefMenuCard(string a) { mixin(S_TRACE);
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath(true), cpparent(a))) return;
			createRefCard();
			_imgp.redraw();
		}
		void delRefMenuCard(string a) { mixin(S_TRACE);
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath(true), cpparent(a))) return;
			createRefCard(cpindex(cpbottom(a)));
			_imgp.redraw();
		}
		void upRefMenuCards(string a, int[] indices, int count) { mixin(S_TRACE);
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath(true), a)) return;
			if (!indices.length) return;
			createRefCard();
			_imgp.redraw();
		}
		void downRefMenuCards(string a, int[] indices, int count) { mixin(S_TRACE);
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath(true), a)) return;
			if (!indices.length) return;
			createRefCard();
			_imgp.redraw();
		}
		void openRefAreaView() { mixin(S_TRACE);
			if (!_refTarget) return;
			try { mixin(S_TRACE);
				_comm.openCWXPath(cpaddattr(_refTarget.cwxPath(true), "shallow"), false);
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
		this (AbstractAreaView v, Commons comm, A area, Summary summ) { mixin(S_TRACE);
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
		protected void udb(AbstractAreaView v) { mixin(S_TRACE);
			if (!v) return;
			auto ct = Display.getCurrent().getFocusControl();
			while (ct.getParent()) { mixin(S_TRACE);
				if (ct is v) { mixin(S_TRACE);
					return;
				}
				ct = ct.getParent();
			}
			.forceFocus(v._imgp, false);
		}
		protected void uda(AbstractAreaView v) { mixin(S_TRACE);
			scope (exit) comm.refreshToolBar();
			if (!v) return;
			static if (UseCards) if (!v._viewCards) v._cards.deselectAll();
			static if (UseBacks) if (!v._viewBacks) v._backs.deselectAll();
			v.refreshStatusLine();
		}
		protected AbstractAreaView view() { mixin(S_TRACE);
			static if (is(A : Area) || is(A : Battle)) {
				return comm.areaViewFrom!(A, C, UseCards, UseBacks)(area.cwxPath(true), false);
			} else { mixin(S_TRACE);
				return _v;
			}
		}
	}
	static if (UseCards) {
		static class UndoSPAuto : AUndo {
			private bool _spAuto;
			this (AbstractAreaView v, Commons comm, A area, Summary summ) { mixin(S_TRACE);
				super (v, comm, area, summ);
				_spAuto = area.spAuto;
			}
			private void impl() { mixin(S_TRACE);
				auto v = view();
				udb(v);
				scope (exit) uda(v);
				auto spAuto = area.spAuto;
				area.spAuto = _spAuto;
				_spAuto = spAuto;
				if (v) { mixin(S_TRACE);
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
			override string cwxPath(bool id) {return "";}
			override CWXPath findCWXPath(string path) {return null;}
			@property
			const
			override const(CWXPath)[] cwxChilds() {return [];}
			@property
			CWXPath cwxParent() {return null;}
		}
		static class UndoMusic : AUndo {
			private PathUser _path;
			this (AbstractAreaView v, Commons comm, A area, Summary summ) { mixin(S_TRACE);
				super (v, comm, area, summ);
				_path = new PathUser(new MCWXPath);
				if (summ) _path.setUseCounter(summ.useCounter.sub);
				_path.path = area.music;
			}
			private void impl() { mixin(S_TRACE);
				auto v = view();
				udb(v);
				scope (exit) uda(v);
				auto path = _path.path;
				_path.path = area.music;
				area.music = path;
				if (v) { mixin(S_TRACE);
					v._bgm.path = path;
					v.callModEvent();
				}
			}
			override void undo() {impl();}
			override void redo() {impl();}
			override void dispose() { mixin(S_TRACE);
				_path.removeUseCounter();
			}
		}
	}
	template Reselect() {
		private int[] _cIdcs;
		private int[] _bIdcs;
		this (AbstractAreaView v, Commons comm, A area, Summary summ, int[] cIdcs, int[] bIdcs) { mixin(S_TRACE);
			super (v, comm, area, summ);
			_cIdcs = cIdcs;
			_bIdcs = bIdcs;
		}
		private void reselect(AbstractAreaView v) { mixin(S_TRACE);
			if (!v) return;
			static if (UseCards) v._cards.select(_cIdcs);
			static if (UseBacks) v._backs.select(_bIdcs);
		}
		private void add(int i) { mixin(S_TRACE);
			_cIdcs[] += i;
			_bIdcs[] += i;
		}
	}
	static class UndoUD(int I) : AUndo {
		mixin Reselect;
		private int _count = 1;
		this (AbstractAreaView v, Commons comm, A area, Summary summ, int[] cIdcs, int[] bIdcs, int count) { mixin(S_TRACE);
			super (v, comm, area, summ);
			_cIdcs = cIdcs;
			_bIdcs = bIdcs;
			_count = count;
		}
		override void undo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			add(I * _count);
			reselect(v);
			static if (I < 0) {
				downImpl(v, comm, area, _cIdcs, _bIdcs, _count, false);
			} else { mixin(S_TRACE);
				upImpl(v, comm, area, _cIdcs, _bIdcs, _count, false);
			}
			add(-I * _count);
		}
		override void redo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			reselect(v);
			static if (I < 0) {
				upImpl(v, comm, area, _cIdcs, _bIdcs, _count, false);
			} else { mixin(S_TRACE);
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
		override void undo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			reselect(v);
			_delUndo = new UndoDelete(v, comm, area, summ, _cIdcs, _bIdcs);
			delImpl2(v, comm, area, _cIdcs, _bIdcs, false);
		}
		override void redo() { mixin(S_TRACE);
			_delUndo.undo();
			_delUndo = null;
		}
		override void dispose() { mixin(S_TRACE);
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
		this (AbstractAreaView v, Commons comm, A area, Summary summ, int[] cIdcs, int[] bIdcs) { mixin(S_TRACE);
			super (v, comm, area, summ);
			static if (UseCards) {
				foreach (i; cIdcs) { mixin(S_TRACE);
					auto node = area.cards[i].toNode(new XMLOption(comm.prop.sys));
					auto ver = new XMLInfo(comm.prop.sys, LATEST_VERSION);
					auto c = C.createFromNode(node, ver);
					if (summ) c.setUseCounter(summ.useCounter.sub);
					_cs[i] = c;
					_cChks[i] = v ? v._cards.getItem(i).getChecked() : true;
				}
			}
			static if (UseBacks) {
				foreach (i; bIdcs) { mixin(S_TRACE);
					auto b = area.backs[i].dup;
					if (summ) b.setUseCounter(summ.useCounter.sub);
					_bs[i] = b;
					_bChks[i] = v ? v._backs.getItem(i).getChecked() : true;
				}
			}
		}
		override void undo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			static if (UseCards) {
				foreach (i; _cs.keys.sort) { mixin(S_TRACE);
					appendCardImpl(v, comm, area, i, _cs[i], true, false, _cChks[i]);
				}
			}
			static if (UseBacks) {
				foreach (i; _bs.keys.sort) { mixin(S_TRACE);
					appendBgImageImpl(v, comm, area, i, _bs[i], true, false, _bChks[i]);
				}
			}
			if (v) v.refreshSelected();
		}
		override void redo() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			int[] cs;
			int[] bs;
			static if (UseCards) cs = _cs.keys;
			static if (UseBacks) bs = _bs.keys;
			delImpl2(v, comm, area, cs, bs, false);
		}
		override void dispose() { mixin(S_TRACE);
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
		this (AbstractAreaView v, Commons comm, A area, Summary summ, int[] ckeys, int[] bkeys) { mixin(S_TRACE);
			super (v, comm, area, summ);
			static if (UseCards) _cs = saveC(ckeys);
			static if (UseBacks) _bs = saveB(bkeys);
		}
		static if (UseCards) {
			private C[int] saveC(int[] indices) { mixin(S_TRACE);
				C[int] cs;
				foreach (i; indices) { mixin(S_TRACE);
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
			private BgImage[int] saveB(int[] indices) { mixin(S_TRACE);
				BgImage[int] bs;
				foreach (i; indices) { mixin(S_TRACE);
					auto b = area.backs[i];
					b = b.dup;
					if (summ) b.setUseCounter(summ.useCounter.sub);
					bs[i] = b;
				}
				return bs;
			}
		}
		private void impl() { mixin(S_TRACE);
			auto v = view();
			udb(v);
			scope (exit) uda(v);
			static if (UseCards) {
				auto cs = saveC(_cs.keys);
				foreach (i, c; _cs) { mixin(S_TRACE);
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
					comm.refMenuCard.call(ac.cwxPath(true));
				}
				_cs = cs;
			}
			static if (UseBacks) {
				auto bs = saveB(_bs.keys);
				foreach (i, b; _bs) { mixin(S_TRACE);
					b.removeUseCounter();
					area.set(i, b.dup);
					comm.refBgImage.call(area.backs[i].cwxPath(true));
				}
				_bs = bs;
			}
			if (v) { mixin(S_TRACE);
				v.refreshPanel();
				v.refreshControls();
				v.callModEvent();
				v.refreshFlags();
			}
			comm.refUseCount.call();
		}
		override void undo() { mixin(S_TRACE);
			impl();
		}
		override void redo() { mixin(S_TRACE);
			impl();
		}
		override void dispose() { mixin(S_TRACE);
			static if (UseCards) {
				foreach (i, c; _cs) c.removeUseCounter();
			}
			static if (UseBacks) {
				foreach (i, b; _bs) b.removeUseCounter();
			}
		}
	}
	UndoEdit createUndoEdit() { mixin(S_TRACE);
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

	ToolBar _toolbar;
	ImagePane _imgp;
	Table _flagList;
	Button _flagAllCheck;
	IncSearch _refFlagIncSearch;
	void flagIncSearch() { mixin(S_TRACE);
		.forceFocus(_flagList, true);
		_refFlagIncSearch.startIncSearch();
	}

	bool _viewMsg = false;
	bool _viewParty = true;
	bool _showGrid = false;
	int _gridX = 0;
	int _gridY = 0;

	Summary _summ;
	MenuItem _vmMenu;
	MenuItem _vpMenu;
	MenuItem _sgMenu;
	MenuItem _sgPMenu;
	ToolItem _vmTMenu;
	ToolItem _vpTMenu;
	ToolItem _sgTMenu;
	static if (RefCards) {
		MenuItem _vrMenu;
		ToolItem _vrTMenu;
	}
	static if (is (C == EnemyCard) || RefCards) {
		MenuItem _dbgMenu;
		ToolItem _dbgTMenu;
		@property
		public bool debugMode() {return _dbgMode;}
		bool _dbgMode = false;
		void reverseDebugMode() { mixin(S_TRACE);
			_dbgMode = !_dbgMode;
			if (_dbgMenu) _dbgMenu.setSelection(_dbgMode);
			if (_dbgTMenu) _dbgTMenu.setSelection(_dbgMode);
			refreshPanel();
		}
	}
	static if (is (C == EnemyCard)) {
		ToolItem _escTMenu;
		MaterialSelect!(MtType.BGM, CCombo, CCombo) _bgm;
		void setEscape() { mixin(S_TRACE);
			_undo ~= createUndoEdit();
			foreach (c; _editC.keys) { mixin(S_TRACE);
				c.escape = _escTMenu.getSelection();
			}
			callModEvent();
		}
		void selectBGM() { mixin(S_TRACE);
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
		bool _fixedC = false;
		bool _viewCards = true;
		C[PileImage] _cardTbl;
		int[C] _editC;
		Table _cards;
		MenuItem _vfcMenu;
		ToolItem _vfcTMenu;
		MenuItem _vcMenu;
		ToolItem _vcTMenu;
		MenuItem _autoMenu;
		ToolItem _autoTMenu;
		MenuItem _customMenu;
		ToolItem _customTMenu;
		Spinner _scaleSpn;

		@property
		Table cardList() {return _cards;}
		void editSpnCard(string T)(int value) { mixin(S_TRACE);
			__editSpn!(T, C)(value, _editC, cardsIndex);
			_imgp.redraw();
		}
		void enterSpnCard(string T, string N)(int value) { mixin(S_TRACE);
			_undo ~= createUndoEdit();
			__enterSpn!(T, N, C)(value, _editC, cardsIndex);
			_imgp.redraw();
		}
		int cancelSpnCard(string T)(int oldVal) { mixin(S_TRACE);
			assert(_editC.length > 0);
			if (_editC.length > 1) { mixin(S_TRACE);
				return 0;
			} else { mixin(S_TRACE);
				assert(_editC.length == 1);
				return __cancelSpn!(T, C)(_editC);
			}
		}
		class SCListener : SelectionAdapter {
			public override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				listSelectC();
			}
		}
		void selectAllC() { mixin(S_TRACE);
			foreach (i; 0 .. _cards.getItemCount()) { mixin(S_TRACE);
				_cards.select(i);
			}
			listSelectC();
		}
		void listSelectC() { mixin(S_TRACE);
			selectListItem!(C)(_cards, cardsIndex, _editC, _area.cards);
		}
		void resizeImageC(FlexImage img, int x, int y, real scale) { mixin(S_TRACE);
			auto card = _cardTbl[img];
			card.x = x;
			card.y = y;
			card.scale = scale;
			refreshControls();
			_comm.refMenuCard.call(card.cwxPath(true));
			callModEvent();
		}
		void selectImageC(FlexImage img) { mixin(S_TRACE);
			__selectImage!(C)(img, _area.cards, _cardTbl, _editC, _cards);
		}
		void setAuto() { mixin(S_TRACE);
			_undo ~= new UndoSPAuto(this, _comm, _area, _summ);
			__setAuto(true);
		}
		void setCustom() { mixin(S_TRACE);
			_undo ~= new UndoSPAuto(this, _comm, _area, _summ);
			__setAuto(false);
		}
		FlexImage cardImage(int index) { mixin(S_TRACE);
			return cast(FlexImage) _imgp.images[cardsIndex + index];
		}
	}

	static if (UseBacks) {
		bool _fixedB = false;
		bool _viewBacks = true;
		BgImage[PileImage] _backTbl;
		int[BgImage] _editB;
		Table _backs;
		MenuItem _vfbMenu;
		ToolItem _vfbTMenu;
		MenuItem _vbMenu;
		ToolItem _vbTMenu;
		ToolItem _maskTMenu;
		Spinner _wSpn, _hSpn;

		@property
		Table backList() {return _backs;}
		void editSpnBack(string T)(int value) { mixin(S_TRACE);
			__editSpn!(T, BgImage)(value, _editB, 0);
			_imgp.redraw();
		}
		void enterSpnBack(string T, string N)(int value) { mixin(S_TRACE);
			_undo ~= createUndoEdit();
			__enterSpn!(T, N, BgImage)(value, _editB, 0);
			_imgp.redraw();
		}
		int cancelSpnBack(string T)(int oldVal) { mixin(S_TRACE);
			assert(_editB.length > 0);
			if (_editB.length > 1) { mixin(S_TRACE);
				return 0;
			} else { mixin(S_TRACE);
				assert(_editB.length == 1);
				return __cancelSpn!(T, BgImage)(_editB);
			}
		}
		class SBListener : SelectionAdapter {
			public override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				listSelectB();
			}
		}
		void selectAllB() { mixin(S_TRACE);
			foreach (i; 0 .. _backs.getItemCount()) { mixin(S_TRACE);
				_backs.select(i);
			}
			listSelectB();
		}
		void listSelectB() { mixin(S_TRACE);
			selectListItem!(BgImage)(_backs, 0, _editB, _area.backs);
		}
		void resizeImageB(FlexImage img, int x, int y, int w, int h) { mixin(S_TRACE);
			auto back = _backTbl[img];
			back.x = x;
			back.y = y;
			back.width = w;
			back.height = h;
			refreshControls();
			_comm.refBgImage.call(back.cwxPath(true));
			callModEvent();
		}
		void selectImageB(FlexImage img) { mixin(S_TRACE);
			__selectImage!(BgImage)(img, _area.backs, _backTbl, _editB, _backs);
		}
		void setMask() { mixin(S_TRACE);
			_undo ~= createUndoEdit();
			foreach (back, i; _editB) { mixin(S_TRACE);
				if (cast(ImageCell) back) { mixin(S_TRACE);
					back.mask = _maskTMenu.getSelection();
					_imgp.images[i].transparent = back.mask;
					_imgp.images[i].createImage();
					_comm.refBgImage.call(back.cwxPath(true));
				}
			}
			_imgp.redraw();
			callModEvent();
		}
		FlexImage backImage(int index) { mixin(S_TRACE);
			return cast(FlexImage) _imgp.images[index];
		}
	}

	void selectListItem(T)(Table list, int startIndex, ref int[T] edits, T[] cols) { mixin(S_TRACE);
		int count = list.getItemCount();
		auto imgs = _imgp.images;
		typeof(edits) editsInit;
		edits = editsInit;
		for (int i = 0; i < count; i++) { mixin(S_TRACE);
			auto img = cast(FlexImage) imgs[startIndex + i];
			bool o = img.selected;
			bool n = list.isSelected(i);
			if (n) { mixin(S_TRACE);
				_imgp.select(img);
				edits[cols[i]] = i;
			} else { mixin(S_TRACE);
				_imgp.deselect(img);
			}
		}
		static if (is(T == C)) {
			__refreshSelected(_viewCards, _cards, _editC, _area.cards, cardsIndex);
		} else { mixin(S_TRACE);
			__refreshSelected(_viewBacks, _backs, _editB, _area.backs, 0);
		}
		refreshControls();
		_imgp.redraw();
		_comm.refreshToolBar();
	}

	void __editSpn(string T, B)(int value, int[B] edits, int startIndex) { mixin(S_TRACE);
		foreach (i; edits.values) { mixin(S_TRACE);
			auto a = cast(FlexImage) _imgp.images[startIndex + i];
			mixin (T);
		}
	}
	void __enterSpn(string T, string N, B)(int value, int[B] edits, int startIndex) { mixin(S_TRACE);
		foreach (c, i; edits) { mixin(S_TRACE);
			{ mixin(S_TRACE);
				auto a = c;
				mixin (T);
			}
			{ mixin(S_TRACE);
				auto a = cast(FlexImage) _imgp.images[startIndex + i];
				mixin (N);
				a.resize(false);
				static if (is(B : AbstractSpCard)) {
					_comm.refMenuCard.call(c.cwxPath(true));
				} else static if (is(B : BgImage)) {
					_comm.refBgImage.call(c.cwxPath(true));
				} else static assert (0);
			}
		}
		callModEvent();
	}
	int __cancelSpn(string T, B)(int[B] edits) { mixin(S_TRACE);
		auto a = edits.keys[0];
		return mixin (T);
	}

	void editSpn(string T)(int value) { mixin(S_TRACE);
		static if (UseCards) __editSpn!(T, C)(value, _editC, cardsIndex);
		static if (UseBacks) __editSpn!(T, BgImage)(value, _editB, 0);
		_imgp.redraw();
	}
	void enterSpn(string T, string N)(int value) { mixin(S_TRACE);
		_undo ~= createUndoEdit();
		static if (UseCards) __enterSpn!(T, N, C)(value, _editC, cardsIndex);
		static if (UseBacks) __enterSpn!(T, N, BgImage)(value, _editB, 0);
		_imgp.redraw();
	}
	int cancelSpn(string T)(int oldVal) { mixin(S_TRACE);
		static if (UseCards && UseBacks) {
			assert(_editC.length + _editB.length > 0);
			if (_editC.length + _editB.length > 1) { mixin(S_TRACE);
				return oldVal;
			} else if (_editC.length == 1) { mixin(S_TRACE);
				return __cancelSpn!(T, C)(_editC);
			} else { mixin(S_TRACE);
				assert(_editB.length == 1);
				return __cancelSpn!(T, BgImage)(_editB);
			}
		} else static if (UseCards) {
			return cancelSpnCard!(T)(oldVal);
		} else static if (UseBacks) {
			return cancelSpnBack!(T)(oldVal);
		} else { mixin(S_TRACE);
			static assert (0);
		}
	}

	void __selectImage(T)(FlexImage img, T[] cols, T[PileImage] tbl, ref int[T] edits, Table list) { mixin(S_TRACE);
		auto c = tbl[img];
		foreach (int i, b; cols) { mixin(S_TRACE);
			if (b is c) { mixin(S_TRACE);
				if (img.selected) { mixin(S_TRACE);
					list.setSelection(list.getSelectionIndices() ~ i);
					edits[b] = i;
				} else { mixin(S_TRACE);
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

	int[] __refreshSelected(T)(bool view, Table list, ref int[T] edits, T[] cols, int startIndex) { mixin(S_TRACE);
		int[] sels;
		foreach (key; edits.keys) { mixin(S_TRACE);
			edits.remove(key);
		}
		for (int i = startIndex; i < startIndex + list.getItemCount(); i++) { mixin(S_TRACE);
			auto fi = cast(FlexImage) _imgp.images[i];
			if (fi && view && fi.selected) { mixin(S_TRACE);
				sels ~= i - startIndex;
				edits[cols[i - startIndex]] = i - startIndex;
			}
		}
		return sels;
	}
	static if (UseCards) {
		private Image cardImg(C c) { mixin(S_TRACE);
			return c.flag == "" ? _prop.images.cards : _prop.images.cardsWithFlag;
		}
		private void refreshCards() { mixin(S_TRACE);
			_cards.setRedraw(false);
			scope (exit) _cards.setRedraw(true);
			auto idx = _cards.getSelectionIndices();
			auto cs = _area.cards;
			_cards.removeAll();
			foreach (i, c; cs) { mixin(S_TRACE);
				auto itm = new TableItem(_cards, SWT.NONE);
				itm.setImage(cardImg(c));
				itm.setData(c);
				itm.setChecked(true);
				itm.setText(cardName(c));
			}
			_cards.setSelection(idx);
		}
	}
	static if (UseBacks) {
		private Image backImg(BgImage bg) { mixin(S_TRACE);
			if (cast(ImageCell) bg) { mixin(S_TRACE);
				return bg.flag == "" ? _prop.images.backs : _prop.images.backsWithFlag;
			} else if (cast(TextCell) bg) { mixin(S_TRACE);
				return bg.flag == "" ? _prop.images.textCell : _prop.images.textCellWithFlag;
			} else if (cast(ColorCell) bg) { mixin(S_TRACE);
				return bg.flag == "" ? _prop.images.colorCell : _prop.images.colorCellWithFlag;
			} else assert (0);
		}
		private void refreshBacks() { mixin(S_TRACE);
			_backs.setRedraw(false);
			scope (exit) _backs.setRedraw(true);
			auto idx = _backs.getSelectionIndices();
			auto cs = _area.backs;
			_backs.removeAll();
			foreach (i, c; cs) { mixin(S_TRACE);
				auto itm = new TableItem(_backs, SWT.NONE);
				itm.setImage(backImg(c));
				itm.setData(c);
				itm.setChecked(true);
				itm.setText(c.name);
			}
			_backs.setSelection(idx);
		}
	}
	static void upImpl2(T)(AbstractAreaView v, Table list, void delegate(int, int) swap, int startIndex, int[] indices, int count) { mixin(S_TRACE);
		indices = indices.sort;
		if (!indices.length) return;
		if (indices[0] != 0) { mixin(S_TRACE);
			foreach (j; 0 .. count) { mixin(S_TRACE);
				foreach (i; indices) { mixin(S_TRACE);
					i -= j;
					if (v) v._imgp.swap(i + startIndex - 1, i + startIndex);
					swap(i - 1, i);
					if (list) { mixin(S_TRACE);
						auto itm1 = list.getItem(i - 1);
						auto itm2 = list.getItem(i);
						string temp = itm1.getText();
						itm1.setText(itm2.getText());
						itm2.setText(temp);
						auto dtemp = itm1.getData();
						itm1.setData(itm2.getData());
						itm2.setData(dtemp);
						auto itemp = itm1.getImage();
						itm1.setImage(itm2.getImage());
						itm2.setImage(itemp);
						auto ctemp = itm1.getChecked();
						itm1.setChecked(itm2.getChecked());
						itm2.setChecked(ctemp);
					}
				}
			}
		}
		if (v) v.callModEvent();
	}
	static void downImpl2(T)(AbstractAreaView v, Table list, void delegate(int, int) swap, int startIndex, int[] indices, int cardsCount, int count) { mixin(S_TRACE);
		indices = indices.sort;
		if (!indices.length) return;
		if (indices[$ - 1] + 1 < cardsCount) { mixin(S_TRACE);
			foreach (j; 0 .. count) { mixin(S_TRACE);
				foreach_reverse (i; indices) { mixin(S_TRACE);
					i += j;
					if (v) v._imgp.swap(i + startIndex + 1, i + startIndex);
					swap(i + 1, i);
					if (list) { mixin(S_TRACE);
						auto itm1 = list.getItem(i + 1);
						auto itm2 = list.getItem(i);
						string temp = itm1.getText();
						itm1.setText(itm2.getText());
						itm2.setText(temp);
						auto dtemp = itm1.getData();
						itm1.setData(itm2.getData());
						itm2.setData(dtemp);
						auto itemp = itm1.getImage();
						itm1.setImage(itm2.getImage());
						itm2.setImage(itemp);
						auto ctemp = itm1.getChecked();
						itm1.setChecked(itm2.getChecked());
						itm2.setChecked(ctemp);
					}
				}
			}
		}
		if (v) v.callModEvent();
	}

	void __pos(int First, string Cmp, string Get, string Set, string CSet, T)(int startIndex, T[] cs) { mixin(S_TRACE);
		int b = First;
		for (int i = startIndex; i < startIndex + cs.length; i++) { mixin(S_TRACE);
			auto a = cast(FlexImage) _imgp.images[i];
			if (a.selected && mixin (Cmp)) { mixin(S_TRACE);
				b = mixin (Get);
			}
		}
		for (int i = startIndex; i < startIndex + cs.length; i++) { mixin(S_TRACE);
			auto a = cast(FlexImage) _imgp.images[i];
			if (a.selected) { mixin(S_TRACE);
				mixin (Set ~ ";");
				a.resize();
				auto c = cs[i - startIndex];
				mixin (CSet ~ ";");
				static if (is(T : AbstractSpCard)) {
					_comm.refMenuCard.call(c.cwxPath(true));
				} else static if (is(T : BgImage)) {
					_comm.refBgImage.call(c.cwxPath(true));
				} else static assert (0);
			}
		}
		callModEvent();
	}
	void __posEven(string X, string Wid, string SetX, string XC, T)(int startIndex, T[] cs) { mixin(S_TRACE);
		FlexImage[] targs;
		int right_w = int.min;
		scope int[FlexImage] indices;
		for (int i = 0; i < cs.length; i++) { mixin(S_TRACE);
			auto a = cast(FlexImage) _imgp.images[i + startIndex];
			if (a.selected) { mixin(S_TRACE);
				indices[a] = i;
				targs ~= a;
				int rw = mixin(X) + mixin (Wid);
				if (right_w < rw) right_w = rw;
			}
		}
		int[const FlexImage] baseIndices;
		foreach (i, fimg; targs) { mixin(S_TRACE);
			baseIndices[fimg] = i;
		}
		if (targs.length > 1) { mixin(S_TRACE);
			bool ficmp(in FlexImage fi1, in FlexImage fi2) { mixin(S_TRACE);
				int x1, x2;
				{ mixin(S_TRACE);
					auto a = fi1;
					x1 = mixin (X);
				}
				{ mixin(S_TRACE);
					auto a = fi2;
					x2 = mixin (X);
				}
				if (x1 == x2) { mixin(S_TRACE);
					return baseIndices[fi1] < baseIndices[fi2];
				} else { mixin(S_TRACE);
					return x1 < x2;
				}
			}
			targs = .sortDlg!(FlexImage)(targs, &ficmp);
			auto a = targs[0];
			int left = mixin (X);
			a = targs[$ - 1];
			int right = right_w - mixin (Wid);
			for (int i = 0; i < targs.length; i++) { mixin(S_TRACE);
				a = targs[i];
				auto b = left + cast(int) rndtol(((right - left) / (targs.length - 1.0)) * i);
				mixin (SetX ~ ";");
				a.resize();
				auto c = cs[indices[a]];
				mixin (XC ~ ";");
				static if (is(T : AbstractSpCard)) {
					_comm.refMenuCard.call(c.cwxPath(true));
				} else static if (is(T : BgImage)) {
					_comm.refBgImage.call(c.cwxPath(true));
				} else static assert (0);
			}
		}
		callModEvent();
	}
	static if (UseCards) {
		private void __scaleC(real s) { mixin(S_TRACE);
			int scale = cast(int) rndtol(s * 100);
			foreach (i, c; _area.cards) { mixin(S_TRACE);
				auto fi = cast(FlexImage) _imgp.images[cardsIndex + i];
				if (fi.selected) { mixin(S_TRACE);
					c.scale = scale;
					fi.scale = s;
					fi.resize();
				}
				_comm.refMenuCard.call(c.cwxPath(true));
			}
			refreshControls();
			_imgp.redraw();
			callModEvent();
		}
		private void __scaleCMax() { mixin(S_TRACE);
			__scaleC(_prop.var.etc.cardScaleMax / 100.0);
		}
		private void __scaleCMiddle() { mixin(S_TRACE);
			__scaleC(1.0);
		}
		private void __scaleCMin() { mixin(S_TRACE);
			__scaleC(_prop.var.etc.cardScaleMin / 100.0);
		}
	}
	void __scaleEven(int First, string Cmp, string CSet, T)(int startIndex, T[] cs) { mixin(S_TRACE);
		int w = First;
		int h = First;
		for (int i = 0; i < cs.length; i++) { mixin(S_TRACE);
			auto fi = cast(FlexImage) _imgp.images[startIndex + i];
			if (fi.selected) { mixin(S_TRACE);
				int a, b;
				a = fi.width;
				b = w;
				if (mixin (Cmp)) w = a;
				a = fi.height;
				b = h;
				if (mixin (Cmp)) h = a;
			}
		}
		for (int i = 0; i < cs.length; i++) { mixin(S_TRACE);
			auto fi = cast(FlexImage) _imgp.images[startIndex + i];
			if (fi.selected) { mixin(S_TRACE);
				fi.newWidth = w;
				fi.newHeight = h;
				fi.resize();
				auto a = cs[i];
				mixin (CSet);
				_comm.refMenuCard.call(a.cwxPath(true));
			}
		}
		callModEvent();
	}
	void __posTop(T)(int startIndex, T[] cs) { mixin(S_TRACE);
		__pos!(int.max, "a.y < b", "a.y", "a.newY = b", "c.y = a.y", T)(startIndex, cs);
	}
	void __posBottom(T)(int startIndex, T[] cs) { mixin(S_TRACE);
		__pos!(int.min, "a.y + a.height > b", "a.y + a.height", "a.newY = b - a.height", "c.y = a.y", T)(startIndex, cs);
	}
	void __posLeft(T)(int startIndex, T[] cs) { mixin(S_TRACE);
		__pos!(int.max, "a.x < b", "a.x", "a.newX = b", "c.x = a.x", T)(startIndex, cs);
	}
	void __posRight(T)(int startIndex, T[] cs) { mixin(S_TRACE);
		__pos!(int.min, "a.x + a.width > b", "a.x + a.width", "a.newX = b - a.width", "c.x = a.x", T)(startIndex, cs);
	}
	void __posEven(T)(int startIndex, T[] cs) { mixin(S_TRACE);
		__posEven!("a.x", "a.width", "a.newX = b", "c.x = b", T)(startIndex, cs);
	}
	bool canChangePos() { mixin(S_TRACE);
		bool r = false;
		static if (UseCards) r |= 0 < _cards.getSelectionCount();
		static if (UseBacks) r |= 0 < _backs.getSelectionCount();
		return r;
	}
	void posTop() { mixin(S_TRACE);
		_undo ~= createUndoEdit();
		static if (UseCards) __posTop!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posTop!(BgImage)(0, _area.backs);
		refreshControls();
		_imgp.redraw();
	}
	void posBottom() { mixin(S_TRACE);
		_undo ~= createUndoEdit();
		static if (UseCards) __posBottom!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posBottom!(BgImage)(0, _area.backs);
		refreshControls();
		_imgp.redraw();
	}
	void posLeft() { mixin(S_TRACE);
		_undo ~= createUndoEdit();
		static if (UseCards) __posLeft!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posLeft!(BgImage)(0, _area.backs);
		refreshControls();
		_imgp.redraw();
	}
	void posRight() { mixin(S_TRACE);
		_undo ~= createUndoEdit();
		static if (UseCards) __posRight!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posRight!(BgImage)(0, _area.backs);
		refreshControls();
		_imgp.redraw();
	}
	void posEven() { mixin(S_TRACE);
		_undo ~= createUndoEdit();
		static if (UseCards) __posEven!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posEven!(BgImage)(0, _area.backs);
		refreshControls();
		_imgp.redraw();
	}
	void nearTop() { mixin(S_TRACE);
		_undo ~= createUndoEdit();
		static if (UseCards) nearTopImpl(cardsIndex, _area.cards, true);
		static if (UseBacks) nearTopImpl(0, _area.backs, false);
		callModEvent();
		refreshControls();
		_imgp.redraw();
	}
	void nearBottom() { mixin(S_TRACE);
		_undo ~= createUndoEdit();
		static if (UseCards) nearBottomImpl(cardsIndex, _area.cards, true);
		static if (UseBacks) nearBottomImpl(0, _area.backs, false);
		callModEvent();
		refreshControls();
		_imgp.redraw();
	}
	void nearLeft() { mixin(S_TRACE);
		_undo ~= createUndoEdit();
		static if (UseCards) nearLeftImpl(cardsIndex, _area.cards, true);
		static if (UseBacks) nearLeftImpl(0, _area.backs, false);
		callModEvent();
		refreshControls();
		_imgp.redraw();
	}
	void nearRight() { mixin(S_TRACE);
		_undo ~= createUndoEdit();
		static if (UseCards) nearRightImpl(cardsIndex, _area.cards, true);
		static if (UseBacks) nearRightImpl(0, _area.backs, false);
		callModEvent();
		refreshControls();
		_imgp.redraw();
	}
	void nearCenterH() { nearCenterImpl1(true, false); }
	void nearCenterV() { nearCenterImpl1(false, true); }
	void nearCenter() { nearCenterImpl1(true, true); }
	void nearCenterImpl1(bool h, bool v) { mixin(S_TRACE);
		_undo ~= createUndoEdit();
		static if (UseCards) nearCenterImpl2(cardsIndex, _area.cards, true, h, v);
		static if (UseBacks) nearCenterImpl2(0, _area.backs, false, h, v);
		callModEvent();
		refreshControls();
		_imgp.redraw();
	}
	void nearTopImpl(T)(int startIndex, T[] cs, bool refParty) { mixin(S_TRACE);
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		getItemPositions(startIndex, cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH);
		nearImpl(startIndex, cs, 0, -itemsT);
	}
	void nearBottomImpl(T)(int startIndex, T[] cs, bool refParty) { mixin(S_TRACE);
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		getItemPositions(startIndex, cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH);
		nearImpl(startIndex, cs, 0, canvasH - itemsH - itemsT);
	}
	void nearLeftImpl(T)(int startIndex, T[] cs, bool refParty) { mixin(S_TRACE);
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		getItemPositions(startIndex, cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH);
		nearImpl(startIndex, cs, -itemsL, 0);
	}
	void nearRightImpl(T)(int startIndex, T[] cs, bool refParty) { mixin(S_TRACE);
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		getItemPositions(startIndex, cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH);
		nearImpl(startIndex, cs, canvasW - itemsW - itemsL, 0);
	}
	void nearCenterImpl2(T)(int startIndex, T[] cs, bool refParty, bool h, bool v) { mixin(S_TRACE);
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		getItemPositions(startIndex, cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH);

		int x = h ? (canvasW - itemsW) / 2 : itemsL;
		int y = v ? (canvasH - itemsH) / 2 : itemsT;
		int moveX = x - itemsL;
		int moveY = y - itemsT;
		nearImpl(startIndex, cs, moveX, moveY);
	}
	void getItemPositions(int startIndex, int count, bool refParty,
			out int canvasW, out int canvasH,
			out int itemsL, out int itemsT,
			out int itemsW, out int itemsH) { mixin(S_TRACE);
		auto vs = _prop.looks.viewSize;
		canvasW = vs.width;
		canvasH = refParty && _viewParty ? _prop.looks.partyTop : vs.height;

		itemsL = int.max;
		itemsT = int.max;
		int itemsR = int.min, itemsB = int.min;
		foreach (i; startIndex .. startIndex + count) { mixin(S_TRACE);
			auto img = cast(FlexImage)_imgp.images[i];
			assert (img !is null);
			if (img.selected) { mixin(S_TRACE);
				itemsL = .min(itemsL, img.x);
				itemsT = .min(itemsT, img.y);
				itemsR = .max(itemsR, img.x + img.width);
				itemsB = .max(itemsB, img.y + img.height);
			}
		}
		itemsW = itemsR - itemsL;
		itemsH = itemsB - itemsT;
	}
	void nearImpl(T)(int startIndex, T[] cs, int moveX, int moveY) { mixin(S_TRACE);
		foreach (i, c; cs) { mixin(S_TRACE);
			auto img = cast(FlexImage)_imgp.images[startIndex + i];
			assert (img !is null);
			if (img.selected) { mixin(S_TRACE);
				c.x = c.x + moveX;
				c.y = c.y + moveY;
				img.newX = c.x;
				img.newY = c.y;
				img.resize();
				static if (is(T:AbstractSpCard)) {
					_comm.refMenuCard.call(c.cwxPath(true));
				} else static if (is(T:BgImage)) {
					_comm.refBgImage.call(c.cwxPath(true));
				} else static assert (0);
			}
		}
	}
	static if (UseBacks) {
		void expandBacks() { mixin(S_TRACE);
			_undo ~= createUndoEdit();
			auto vs = _prop.looks.viewSize;
			foreach (i, back; _area.backs) { mixin(S_TRACE);
				auto img = cast(FlexImage)_imgp.images[0 + i];
				assert (img !is null);
				if (img.selected) { mixin(S_TRACE);
					back.x = 0;
					back.y = 0;
					back.width = vs.width;
					back.height = vs.height;
					img.newX = back.x;
					img.newY = back.y;
					img.newWidth = back.width;
					img.newHeight = back.height;
					img.resize();
					_comm.refBgImage.call(back.cwxPath(true));
				}
			}
			callModEvent();
			refreshControls();
			_imgp.redraw();
		}
	}
	static if (UseCards) {
		void __scaleEvenC(int First, string Cmp)() { mixin(S_TRACE);
			__scaleEven!(First, Cmp, "a.scale = cast(int) rndtol(cast(real) fi.baseWidth / w);", C)(cardsIndex, _area.cards);
		}
	}
	static if (UseBacks) {
		void __scaleEvenB(int First, string Cmp)() { mixin(S_TRACE);
			__scaleEven!(First, Cmp, "a.width = w, a.height = h;", BgImage)(0, _area.backs);
		}
	}
	void scaleEvenBig() { mixin(S_TRACE);
		_undo ~= createUndoEdit();
		static if (UseCards) __scaleEvenC!(int.min, "a > b")();
		static if (UseBacks) __scaleEvenB!(int.min, "a > b")();
		refreshControls();
		_imgp.redraw();
	}
	void scaleEvenSmall() { mixin(S_TRACE);
		_undo ~= createUndoEdit();
		static if (UseCards) __scaleEvenC!(int.max, "a < b")();
		static if (UseBacks) __scaleEvenB!(int.max, "a < b")();
		refreshControls();
		_imgp.redraw();
	}
	class IPEditListener : MouseAdapter {
		override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (e.button == 1) { mixin(S_TRACE);
				int i = _imgp.findSelectedIndex(e.x, e.y);
				if (i >= 0) { mixin(S_TRACE);
					editImagePane([i]);
				}
			}
		}
	}
	public void edit() { mixin(S_TRACE);
		editImagePane(_imgp.selectedIndices);
	}
	@property
	public bool canEdit() { mixin(S_TRACE);
		return _imgp.selectedIndex != -1 && !_imgp.isMoving;
	}
	void editImagePane(int[] indices) { mixin(S_TRACE);
		if (_imgp.isMoving) return;
		int[] cs;
		int[] bs;
		foreach (i; indices) { mixin(S_TRACE);
			static if (UseCards && UseBacks) {
				if (i >= cardsIndex) { mixin(S_TRACE);
					cs ~= i - cardsIndex;
				} else { mixin(S_TRACE);
					bs ~= i;
				}
			} else static if (UseCards) {
				cs ~= i - cardsIndex;
			} else static if (UseBacks) {
				bs ~= i;
			} else { mixin(S_TRACE);
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
	void refreshWallpaper() { mixin(S_TRACE);
		_imgp.setBackgroundImage(_comm.wallpaper);
		if (_prop.var.etc.wallpaperStyle < WallpaperStyle.min || WallpaperStyle.max < _prop.var.etc.wallpaperStyle) { mixin(S_TRACE);
			_prop.var.etc.wallpaperStyle = WallpaperStyle.Tile;
		}
		_imgp.wallpaperStyle = cast(WallpaperStyle) _prop.var.etc.wallpaperStyle;
	}
	Control createImagePane(Composite parent) { mixin(S_TRACE);
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
			listener(_imgp, SWT.Dispose, { mixin(S_TRACE);
				foreach (a; _imgp.appends) { mixin(S_TRACE);
					a.data[] = 0;
					delete a.data;
					a.alphaData[] = 0;
					delete a.alphaData;
				}
			});
		}
		auto d = Display.getCurrent();
		auto rgb = new RGB(_prop.var.etc.wallColorR,
			_prop.var.etc.wallColorG,
			_prop.var.etc.wallColorB);
		auto color = new Color(d, rgb);
		_imgp.setBackgroundColor2(color);
		int alpha;
		_imgp.gridRange = _prop.var.etc.gridRange;
		_imgp.gridColor(new Color(d, dwtData(_prop.var.etc.gridColor, alpha)));
		_imgp.gridHighlightColor(new Color(d, dwtData(_prop.var.etc.gridHighlightColor, alpha)));
		_comm.refWallpaper.add(&refreshWallpaper);
		_imgp.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
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
		{ mixin(S_TRACE);
			auto menu = new Menu(parent.getShell(), SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.EditProp, &edit, &canEdit);
			static if (is(A : Area)) {
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.NewMenuCard, &createCard, null);
			} else static if (is(A : Battle)) {
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.NewEnemyCard, &createCard, null);
			}
			static if (UseBacks) {
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.NewBack, &createBackground, null);
				createMenuItem(_comm, menu, MenuID.NewTextCell, &createTextCell, null);
				createMenuItem(_comm, menu, MenuID.NewColorCell, &createColorCell, null);
			}
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_comm, menu, _tcpd, true, true, true, true, true);
			static if (is(A : Area)) {
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.EditEvent, &openEvent, null);
			} else static if (is(A : Battle)) {
				new MenuItem(menu, SWT.SEPARATOR);
				auto itm = createMenuItem(_comm, menu, MenuID.EditEvent, &openEvent, null);
				itm.setImage(_prop.images.editEventBattle);
			}
			new MenuItem(menu, SWT.SEPARATOR);
			_sgPMenu = createMenuItem(_comm, menu, MenuID.ShowGrid, &reverseShowGrid, null, SWT.CHECK);
			_sgPMenu.setSelection(_showGrid);
			new MenuItem(menu, SWT.SEPARATOR);

			void delegate(SelectionEvent) dummy = null;
			auto chgPosMI = createMenuItem(_comm, menu, MenuID.ChangePos, dummy, &canChangePos, SWT.CASCADE);
			auto chgPos = new Menu(chgPosMI);
			chgPosMI.setMenu(chgPos);
			createMenuItem(_comm, chgPos, MenuID.NearTop, &nearTop, &canChangePos);
			createMenuItem(_comm, chgPos, MenuID.NearBottom, &nearBottom, &canChangePos);
			createMenuItem(_comm, chgPos, MenuID.NearLeft, &nearLeft, &canChangePos);
			createMenuItem(_comm, chgPos, MenuID.NearRight, &nearRight, &canChangePos);
			createMenuItem(_comm, chgPos, MenuID.NearCenterH, &nearCenterH, &canChangePos);
			createMenuItem(_comm, chgPos, MenuID.NearCenterV, &nearCenterV, &canChangePos);
			createMenuItem(_comm, chgPos, MenuID.NearCenter, &nearCenter, &canChangePos);
			new MenuItem(chgPos, SWT.SEPARATOR);
			createMenuItem(_comm, chgPos, MenuID.PosTop, &posTop, &canChangePos);
			createMenuItem(_comm, chgPos, MenuID.PosBottom, &posBottom, &canChangePos);
			createMenuItem(_comm, chgPos, MenuID.PosLeft, &posLeft, &canChangePos);
			createMenuItem(_comm, chgPos, MenuID.PosRight, &posRight, &canChangePos);
			createMenuItem(_comm, chgPos, MenuID.PosEven, &posEven, &canChangePos);
			static if (UseCards) {
				new MenuItem(chgPos, SWT.SEPARATOR);
				createMenuItem(_comm, chgPos, MenuID.ScaleMin, &__scaleCMin, &canChangePos);
	 			createMenuItem(_comm, chgPos, MenuID.ScaleMiddle, &__scaleCMiddle, &canChangePos);
				createMenuItem(_comm, chgPos, MenuID.ScaleMax, &__scaleCMax, &canChangePos);
			}
			new MenuItem(chgPos, SWT.SEPARATOR);
			createMenuItem(_comm, chgPos, MenuID.ScaleBig, &scaleEvenBig, &canChangePos);
			createMenuItem(_comm, chgPos, MenuID.ScaleSmall, &scaleEvenSmall, &canChangePos);
			static if (UseBacks) {
				new MenuItem(chgPos, SWT.SEPARATOR);
				createMenuItem(_comm, chgPos, MenuID.ExpandBack, &expandBacks, () => 0 < _backs.getSelectionCount());
			}

			_imgp.setMenu(menu);
		}
		_imgp.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				auto pane = cast(ImagePane) e.widget;
				auto img = pane.getBackgroundImage();
				if (img) img.dispose();
				auto color = pane.getBackgroundColor2();
				if (color) color.dispose();
				color = pane.gridColor();
				if (color) color.dispose();
				color = pane.gridHighlightColor();
				if (color) color.dispose();
			}
		});
		return sc;
	}
	void createFlagList(Composite parent) { mixin(S_TRACE);
		auto comp = new Composite(parent, SWT.NONE);
		auto gl = windowGridLayout(1, false);
		gl.marginWidth = 0;
		gl.marginHeight = 0;
		comp.setLayout(gl);
		auto label = new CLabel(comp, SWT.NONE);
		label.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		label.setText(_prop.msgs.refFlags);
		label.setImage(_prop.images.flag);

		_flagList = new Table(comp, SWT.SINGLE | SWT.CHECK | SWT.BORDER | SWT.H_SCROLL | SWT.V_SCROLL);
		new FullTableColumn(_flagList, SWT.NONE);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = 0;
		gd.heightHint = 0;
		_flagList.setLayoutData(gd);

		_refFlagIncSearch = new IncSearch(_comm, _flagList);
		_refFlagIncSearch.modEvent ~= &refreshFlags;

		auto menu = new Menu(_flagList.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &flagIncSearch, { mixin(S_TRACE);
			foreach (itm; _flagList.getItems()) { mixin(S_TRACE);
				if (cast(Flag)itm.getData()) return true;
			}
			return false;
		});
		new MenuItem(menu, SWT.SEPARATOR);
		createMenuItem(_comm, menu, MenuID.OpenAtVarView, &openFlagView,
			() => _flagList.getSelectionIndex() != -1
			&& cast(Flag)_flagList.getItem(_flagList.getSelectionIndex()).getData());
		_flagList.setMenu(menu);

		_flagAllCheck = new Button(comp, SWT.CHECK);
		_flagAllCheck.setText(_prop.msgs.allCheckFlag);
		_flagAllCheck.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		.listener(_flagAllCheck, SWT.Selection, (Event e) { mixin(S_TRACE);
			foreach (itm; _flagList.getItems()) { mixin(S_TRACE);
				itm.setChecked(_flagAllCheck.getSelection());
			}
			checkFlag(e);
		});
		.listener(_flagList, SWT.Selection, &checkFlag);

		_comm.refFlagAndStep.add(&refFlags);
		_comm.delFlagAndStep.add(&delFlags);
		.listener(_flag, SWT.Dispose, { mixin(S_TRACE);
			_comm.refFlagAndStep.remove(&refFlags);
			_comm.delFlagAndStep.remove(&delFlags);
		});
	}
	void refFlags(Flag[] f, Step[] s) { mixin(S_TRACE);
		if (!_summ) return;
		if (!f.length) return;
		refreshFlags();
	}
	void delFlags(Flag[] f, Step[] s) { mixin(S_TRACE);
		if (!_summ) return;
		if (!f.length) return;
		refreshFlags();
	}
	void refreshFlags() { mixin(S_TRACE);
		if (!_flagList) return;
		bool[string] useFlags;
		static if (UseCards) {
			foreach (c; _area.cards) { mixin(S_TRACE);
				useFlags[c.flag] = true;
			}
		}
		static if (UseBacks) {
			foreach (c; _area.backs) { mixin(S_TRACE);
				useFlags[c.flag] = true;
			}
		}
		string sel = "";
		if (_flagList.getSelectionIndex() != -1) { mixin(S_TRACE);
			auto itm = _flagList.getItem(_flagList.getSelectionIndex());
			if (itm.getImage() is _prop.images.emptyIcon) { mixin(S_TRACE);
				sel = itm.getText();
			}
		}
		_flagList.removeAll();
		bool has = false;
		auto flags = useFlags.keys;
		if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
			flags = cwx.utils.sort!(incmp)(flags);
		} else { mixin(S_TRACE);
			flags = cwx.utils.sort!(icmp)(flags);
		}
		foreach (path; flags) { mixin(S_TRACE);
			if (!path.length) { mixin(S_TRACE);
				auto nof = new TableItem(_flagList, SWT.NONE);
				nof.setText(_prop.msgs.noFlagRef);
				nof.setImage(_prop.images.emptyIcon);
			} else { mixin(S_TRACE);
				auto flag = _summ.flagDirRoot.findFlag(path);
				if (!has && path == sel) { mixin(S_TRACE);
					has = true;
				}
				if (!_refFlagIncSearch.match(path)) continue;
				auto itm = new TableItem(_flagList, SWT.NONE);
				itm.setData(flag);
				if (flag) { mixin(S_TRACE);
					itm.setImage(_prop.images.flag);
				} else { mixin(S_TRACE);
					itm.setImage(_prop.images.warning);
				}
				itm.setText(path);
			}
			if (path == sel) _flagList.select(_flagList.getItemCount() - 1);
		}
		if (!has && _flagList.getItemCount()) { mixin(S_TRACE);
			_flagList.select(0);
		}
		_flagList.showSelection();
		_flagList.setEnabled(0 < _flagList.getItemCount());
		_flagAllCheck.setEnabled(0 < _flagList.getItemCount());
		updateFlagChecks();
	}
	void openFlagView() { mixin(S_TRACE);
		if (!_flagList) return;
		auto i = _flagList.getSelectionIndex();
		if (-1 == i) return;
		auto a = cast(Flag) _flagList.getItem(i).getData();
		if (!a) return;
		try { mixin(S_TRACE);
			_comm.openCWXPath(cpaddattr(a.cwxPath(true), "shallow"), false);
		} catch (Exception e) {
			debugln(e);
		}
	}
	void checkFlag(Event e) { mixin(S_TRACE);
		if (!_flagList) return;
		updateChecked(e);
		bool[string] useFlags;
		if (e && cast(TableItem)e.item) { mixin(S_TRACE);
			auto itm = cast(TableItem)e.item;
			itm.setGrayed(false);
		}
		bool allChecked = true;
		foreach (itm; _flagList.getItems()) { mixin(S_TRACE);
			if (itm.getGrayed()) { mixin(S_TRACE);
				allChecked = false;
				continue;
			}
			bool checked = itm.getChecked();
			allChecked &= checked;
			if (itm.getImage() is _prop.images.emptyIcon) { mixin(S_TRACE);
				useFlags[""] = checked;
			} else { mixin(S_TRACE);
				useFlags[itm.getText().toLower()] = checked;
			}
		}
		_flagAllCheck.setSelection(allChecked && _flagList.getItemCount());
		static if (UseCards) {
			foreach (itm; _cards.getItems()) { mixin(S_TRACE);
				auto c = cast(C)itm.getData();
				auto p = c.flag.toLower() in useFlags;
				if (p) itm.setChecked(*p);
			}
		}
		static if (UseBacks) {
			foreach (itm; _backs.getItems()) { mixin(S_TRACE);
				auto c = cast(BgImage)itm.getData();
				auto p = c.flag.toLower() in useFlags;
				if (p) itm.setChecked(*p);
			}
		}
		checked();
		_imgp.redraw();
	}
	void updateFlagChecks() { mixin(S_TRACE);
		if (!_flagList) return;
		int[string] useFlags;
		void put(string flag, bool check) { mixin(S_TRACE);
			auto p = flag in useFlags;
			if (p) { mixin(S_TRACE);
				if ((*p == 0 && check) || (*p == 1 && !check)) { mixin(S_TRACE);
					useFlags[flag] = 2;
				}
			} else { mixin(S_TRACE);
				useFlags[flag] = check ? 1 : 0;
			}
		}
		static if (UseCards) {
			foreach (itm; _cards.getItems()) { mixin(S_TRACE);
				auto c = cast(C)itm.getData();
				auto flag = c.flag.toLower();
				put(flag, itm.getChecked());
			}
		}
		static if (UseBacks) {
			foreach (itm; _backs.getItems()) { mixin(S_TRACE);
				auto c = cast(BgImage)itm.getData();
				auto flag = c.flag.toLower();
				put(flag, itm.getChecked());
			}
		}
		bool allChecked = true;
		foreach (itm; _flagList.getItems()) { mixin(S_TRACE);
			string flag;
			if (itm.getImage() is _prop.images.emptyIcon) { mixin(S_TRACE);
				flag = "";
			} else { mixin(S_TRACE);
				flag = itm.getText().toLower();
			}
			int val = useFlags.get(flag, 0);
			if (val == 0) { mixin(S_TRACE);
				itm.setChecked(false);
				itm.setGrayed(false);
				allChecked = false;
			} else if (val == 1) { mixin(S_TRACE);
				itm.setChecked(true);
				itm.setGrayed(false);
			} else { mixin(S_TRACE);
				itm.setChecked(true);
				itm.setGrayed(true);
				allChecked = false;
			}
		}
		_flagAllCheck.setSelection(allChecked && _flagList.getItemCount());
	}

	void changingImages() { mixin(S_TRACE);
		_undo ~= createUndoEdit();
		_comm.refreshToolBar();
	}

	void refreshControls() { mixin(S_TRACE);
		if (!_xSpn) return;
		string f = null;
		if (_flag) _flag.setText(_flag.getItem(0));
		void flag(string f2) { mixin(S_TRACE);
			if (!_flag) return;
			if (!f) { mixin(S_TRACE);
				f = f2;
				if ("" != f2) { mixin(S_TRACE);
					_flag.setText(f2);
				}
			} else if (f != f2) { mixin(S_TRACE);
				_flag.setText("");
			}
		}
		static if (UseCards) {
			foreach (c; _editC.keys) { mixin(S_TRACE);
				flag(c.flag);
			}
		}
		static if (UseBacks) {
			foreach (b; _editB.keys) { mixin(S_TRACE);
				flag(b.flag);
			}
		}
		static if (UseCards && UseBacks) {
			if (_flag) _flag.setEnabled(_editC.length || _editB.length);
			_xSpn.setEnabled(_editC.length || _editB.length);
			_ySpn.setEnabled(_xSpn.getEnabled());
			_wSpn.setEnabled(_editB.length > 0);
			_hSpn.setEnabled(_wSpn.getEnabled());
			bool maskEnabled = false;
			foreach (back; _editB.keys) { mixin(S_TRACE);
				if (cast(ImageCell) back) { mixin(S_TRACE);
					maskEnabled = true;
					break;
				}
			}
			_maskTMenu.setEnabled(maskEnabled);
			_scaleSpn.setEnabled(_editC.length > 0);
			if (_editC.length == 1) { mixin(S_TRACE);
				auto card = _editC.keys[0];
				_scaleSpn.setSelection(cast(int) rndtol(card.scale * 100.0));
				if (_editB.length == 0) { mixin(S_TRACE);
					_xSpn.setSelection(card.x);
					_ySpn.setSelection(card.y);
				}
			} else if (_editC.length > 1) { mixin(S_TRACE);
				_scaleSpn.setSelection(spnValue!("cast(int) rndtol(a.scale * 100.0)", C, int)(_editC.keys, 100));
			}
			if (_editB.length == 1) { mixin(S_TRACE);
				auto back = _editB.keys[0];
				_wSpn.setSelection(back.width);
				_hSpn.setSelection(back.height);
				_maskTMenu.setSelection(back.mask);
				if (_editC.length == 0) { mixin(S_TRACE);
					_xSpn.setSelection(back.x);
					_ySpn.setSelection(back.y);
				}
			} else if (_editB.length > 1) { mixin(S_TRACE);
				_wSpn.setSelection(spnValue!("a.width", BgImage, int)(_editB.keys, 0));
				_hSpn.setSelection(spnValue!("a.height", BgImage, int)(_editB.keys, 0));
				_maskTMenu.setSelection(spnValue!("a.mask", BgImage, bool)(_editB.keys, 0));
			}
			if (_editC.length + _editB.length > 1) { mixin(S_TRACE);
				if (_editC.length == 0) { mixin(S_TRACE);
					_xSpn.setSelection(spnValue!("a.x", BgImage, int)(_editB.keys, 0));
					_ySpn.setSelection(spnValue!("a.y", BgImage, int)(_editB.keys, 0));
				} else if (_editB.length == 0) { mixin(S_TRACE);
					_xSpn.setSelection(spnValue!("a.x", C, int)(_editC.keys, 0));
					_ySpn.setSelection(spnValue!("a.y", C, int)(_editC.keys, 0));
				} else { mixin(S_TRACE);
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
			if (_editC.length == 1) { mixin(S_TRACE);
				auto card = _editC.keys[0];
				_xSpn.setSelection(card.x);
				_ySpn.setSelection(card.y);
				_scaleSpn.setSelection(cast(int) rndtol(card.scale * 100.0));
				static if (is (C == EnemyCard)) {
					_escTMenu.setSelection(card.escape);
				}
			} else if (_editC.length > 1) { mixin(S_TRACE);
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
			bool maskEnabled = false;
			foreach (back; _editB.keys) { mixin(S_TRACE);
				if (cast(ImageCell) back) { mixin(S_TRACE);
					maskEnabled = true;
					break;
				}
			}
			_maskTMenu.setEnabled(maskEnabled);
			if (_editB.length == 1) { mixin(S_TRACE);
				auto back = _editB.keys[0];
				_xSpn.setSelection(back.x);
				_ySpn.setSelection(back.y);
				_wSpn.setSelection(back.width);
				_hSpn.setSelection(back.height);
				_maskTMenu.setSelection(back.mask);
			} else if (_editB.length > 1) { mixin(S_TRACE);
				_xSpn.setSelection(spnValue!("a.x", BgImage, int)(_editB.keys, 0));
				_ySpn.setSelection(spnValue!("a.y", BgImage, int)(_editB.keys, 0));
				_wSpn.setSelection(spnValue!("a.width", BgImage, int)(_editB.keys, 0));
				_hSpn.setSelection(spnValue!("a.height", BgImage, int)(_editB.keys, 0));
				_maskTMenu.setSelection(spnValue!("a.mask", BgImage, bool)(_editB.keys, false));
			}
		} else { mixin(S_TRACE);
			static assert (0);
		}
		refreshStatusLine();
		_comm.refreshToolBar();
	}
	void refreshStatusLine() { mixin(S_TRACE);
		string line = "";
		string flag(string path) { mixin(S_TRACE);
			if (!path.length) return _prop.msgs.areaViewStatusNoFlag;
			if (_summ) { mixin(S_TRACE);
				auto f = _summ.flagDirRoot.findFlag(path);
				if (f) return .tryFormat(_prop.msgs.areaViewStatusWithFlag, path);
			}
			return .tryFormat(_prop.msgs.areaViewStatusInvalidFlag, path);
		}
		static if (is(C : MenuCard)) {
			string cardName = _prop.msgs.menuCard;
			string path(in C card) { mixin(S_TRACE);
				string path = card.path;
				if (!path.length) return _prop.msgs.noSelectImage;
				if (isBinImg(path)) return _prop.msgs.areaViewStatusImageIncluding;
				if (!_comm.skin.findImagePath(path, _summ ? _summ.scenarioPath : "").length) { mixin(S_TRACE);
					return .tryFormat(_prop.msgs.noImage, encodePath(path));
				}
				return encodePath(path);
			}
		} else static if (is(C : EnemyCard)) {
			string cardName = _prop.msgs.enemyCard;
			string path(in C card) { mixin(S_TRACE);
				if (_summ) { mixin(S_TRACE);
					if (0 == card.id) return _prop.msgs.noSelectCast;
					auto c = _summ.cwCast(card.id);
					if (!c) return .tryFormat(_prop.msgs.noCast, card.id);
					return .tryFormat(_prop.msgs.areaViewStatusEnemyCard, c.id, c.name);
				}
				assert (0);
			}
		}
		static if (UseCards) {
			void putOneCard(in C card) { mixin(S_TRACE);
				if (_summ) { mixin(S_TRACE);
					line = .tryFormat(_prop.msgs.areaViewStatus, cardName, path(card), flag(card.flag));
				} else { mixin(S_TRACE);
					line = .tryFormat(_prop.msgs.areaViewStatusNoSummary, cardName, path(card));
				}
			}
		}
		static if (UseBacks) {
			void putOneBack(in BgImage back) { mixin(S_TRACE);
				string path, name;
				auto ic = cast(ImageCell) back;
				if (ic) { mixin(S_TRACE);
					name = _prop.msgs.back;
					path = encodePath(ic.path);
					if (!path.length) { mixin(S_TRACE);
						path = _prop.msgs.noSelectImage;
					} else if (!_comm.skin.findImagePath(path, _summ ? _summ.scenarioPath : "").length) { mixin(S_TRACE);
						path = .tryFormat(_prop.msgs.noImage, encodePath(path));
					}
				}
				auto tc = cast(TextCell) back;
				if (tc) { mixin(S_TRACE);
					name = _prop.msgs.textCell;
					path = back.name;
				}
				auto cc = cast(ColorCell) back;
				if (cc) { mixin(S_TRACE);
					name = _prop.msgs.colorCell;
					path = back.name;
				}
				if (_summ) { mixin(S_TRACE);
					line = .tryFormat(_prop.msgs.areaViewStatus, name, path, flag(back.flag));
				} else { mixin(S_TRACE);
					line = .tryFormat(_prop.msgs.areaViewStatusNoSummary, name, path);
				}
			}
		}
		static if (UseCards && UseBacks) {
			if (_editC.length == 1 && !_editB.length) { mixin(S_TRACE);
				putOneCard(_editC.keys[0]);
			} else if (!_editC.length && _editB.length == 1) { mixin(S_TRACE);
				putOneBack(_editB.keys[0]);
			} else if (_editC.length + _editB.length) { mixin(S_TRACE);
				if (_editC.length) { mixin(S_TRACE);
					line = .tryFormat(_prop.msgs.areaViewStatusSelCard, _editC.length);
				}
				if (_editB.length) { mixin(S_TRACE);
					if (line.length) line ~= " ";
					line ~= .tryFormat(_prop.msgs.areaViewStatusSelBack, _editB.length);
				}
			}
		} else static if (UseCards) {
			if (1 == _editC.length) { mixin(S_TRACE);
				putOneCard(_editC.keys[0]);
			} else if (1 < _editC.length) { mixin(S_TRACE);
				line = .tryFormat(_prop.msgs.areaViewStatusSelCard, _editC.length);
			}
		} else static if (UseBacks) {
			if (1 == _editB.length) { mixin(S_TRACE);
				putOneBack(_editB.keys[0]);
			} else if (1 < _editB.length) { mixin(S_TRACE);
				line = .tryFormat(_prop.msgs.areaViewStatusSelBack, _editB.length);
			}
		}
		statusLine = line;
	}
	static if (UseCards) {
		static int staticCardsIndex(A area) { mixin(S_TRACE);
			static if (UseBacks) {
				return area.backs.length;
			} else { mixin(S_TRACE);
				return 0;
			}
		}
		@property
		int cardsIndex() { mixin(S_TRACE);
			return staticCardsIndex(_area);
		}
	}

	void refreshSelected() { mixin(S_TRACE);
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
		this(void delegate(int[]) edit, C[] delegate() items) { mixin(S_TRACE);
			_edit = edit;
			_items = items;
		}
		private void edit(TypedEvent e) { mixin(S_TRACE);
			auto l = cast(Table) e.widget;
			_edit(l.getSelectionIndices());
		}
		override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (e.button == 1) { mixin(S_TRACE);
				edit(e);
			}
		}
	}
	Table createList(C)(Composite parent, string name, Image image, TCPD tcpd,
			void delegate(int[]) edit, C[] delegate() items, void delegate() selectAll) { mixin(S_TRACE);
		auto comp = new Composite(parent, SWT.NONE);
		auto gl = windowGridLayout(2, false);
		gl.marginWidth = 0;
		gl.marginHeight = 0;
		comp.setLayout(gl);
		auto label = new CLabel(comp, SWT.NONE);
		label.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		label.setText(name);
		label.setImage(image);
		auto bar = new ToolBar(comp, SWT.FLAT);
		_comm.put(bar);
		static if (is(C:AbstractSpCard)) {
			static if (UseBacks) {
				_vcTMenu = createToolItem(_comm, bar, MenuID.ShowCard, &reverseViewCards, null, SWT.CHECK);
				_vcTMenu.setSelection(_viewCards);
			}
			_vfcTMenu = createToolItem(_comm, bar, MenuID.FixedCards, &reverseFixedCards, null, SWT.CHECK);
			_vfcTMenu.setSelection(_fixedC);
		} else { mixin(S_TRACE);
			static assert (is(C:BgImage));
			static if (UseCards) {
				_vbTMenu = createToolItem(_comm, bar, MenuID.ShowBack, &reverseViewBacks, null, SWT.CHECK);
				_vbTMenu.setSelection(_viewBacks);
			}
			_vfbTMenu = createToolItem(_comm, bar, MenuID.FixedCells, &reverseFixedCells, null, SWT.CHECK);
			_vfbTMenu.setSelection(_fixedB);
		}

		auto list = new Table(comp, SWT.MULTI | SWT.CHECK | SWT.BORDER | SWT.H_SCROLL | SWT.V_SCROLL);
		new FullTableColumn(list, SWT.NONE);
		auto mkl = new MKListener!(C)(edit, items);
		auto closePreview = new ClosePreview;
		list.getVerticalBar().addSelectionListener(closePreview);
		list.getHorizontalBar().addSelectionListener(closePreview);
		list.addSelectionListener(new VCheckListener);
		list.addMouseListener(mkl);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.horizontalSpan = 2;
		gd.widthHint = 0;
		gd.heightHint = 0;
		list.setLayoutData(gd);
		{ mixin(S_TRACE);
			auto menu = new Menu(parent.getShell(), SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.EditProp, { mixin(S_TRACE);
				edit(list.getSelectionIndices());
			}, () => list.getSelectionIndex() != -1);
			new MenuItem(menu, SWT.SEPARATOR);
			static if (is(C:MenuCard)) {
				createMenuItem(_comm, menu, MenuID.NewMenuCard, &createCard, null);
			} else static if (is(C:EnemyCard)) {
				createMenuItem(_comm, menu, MenuID.NewEnemyCard, &createCard, null);
			} else {
				createMenuItem(_comm, menu, MenuID.NewBack, &createBackground, null);
				createMenuItem(_comm, menu, MenuID.NewTextCell, &createTextCell, null);
				createMenuItem(_comm, menu, MenuID.NewColorCell, &createColorCell, null);
			}
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_comm, menu, tcpd, true, true, true, true, true);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.SelectAll, selectAll, () => list.getItemCount() && list.getSelectionCount() != list.getItemCount());
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
		void __setAuto(bool value) { mixin(S_TRACE);
			_area.spAuto = value;
			if (_autoMenu) _autoMenu.setSelection(value);
			if (_autoTMenu) _autoTMenu.setSelection(value);
			if (_customMenu) _customMenu.setSelection(!value);
			if (_customTMenu) _customTMenu.setSelection(!value);
			callModEvent();
		}
	}
	class VCheckListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			updateChecked(e);
			checked();
			updateFlagChecks();
		}
	}
	void checked() { mixin(S_TRACE);
		static if (UseCards) {
			foreach (i, itm; _cards.getItems()) { mixin(S_TRACE);
				_imgp.images[cardsIndex + i].visible = _viewCards && itm.getChecked();
			}
		}
		static if (UseBacks) {
			foreach (i, itm; _backs.getItems()) { mixin(S_TRACE);
				_imgp.images[i].visible = _viewBacks && itm.getChecked();
			}
		}
	}
	void openFlagView() { mixin(S_TRACE);
		if (-1 == _flag.getSelectionIndex()) return;
		auto flag = _summ.flagDirRoot.findFlag(_flag.getText());
		if (!flag) return;
		try { mixin(S_TRACE);
			_comm.openCWXPath(flag.cwxPath(true), false);
		} catch (Exception e) {
			debugln(e);
		}
	}
	void refShowToolBar() { mixin(S_TRACE);
		if (!_comm.singleWindowMode(_prop)) return;
		auto gl = windowGridLayout(1, true);
		gl.marginWidth = 0;
		gl.marginHeight = 0;
		auto gd = new GridData(GridData.FILL_HORIZONTAL);
		if (!_prop.var.etc.showSceneToolBar) { mixin(S_TRACE);
			gl.verticalSpacing = 0;
			gd.heightHint = 0;
		}
		setLayout(gl);
		_toolbar.setVisible(_prop.var.etc.showSceneToolBar);
		_toolbar.setLayoutData(gd);
		layout();
	}

	private TopLevelPanel _tlp;
public:
	this(Commons comm, Props prop, Summary summ, A area, Composite parent, TopLevelPanel tlp, UndoManager undo) { mixin(S_TRACE);
		super(parent, SWT.NONE);
		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime());
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
		_comm.refShowToolBar.add(&refShowToolBar);
		static if (UseCards) {
			_comm.refCardState.add(&refreshCardState);
		}
		static if (UseBacks) {
			_comm.refPreviewValues.add(&refreshTextCell);
			_comm.refFlagAndStep.add(&refreshTextCellF);
		}
		_preview = new Preview(_prop, parent.getShell());
		addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				_preview.dispose();
				_comm.refSkin.remove(&refresh);
				_comm.delPaths.remove(&refresh);
				_comm.replPath.remove(&refreshR);
				_comm.replText.remove(&replText);
				_comm.replID.remove(&replText);
				_comm.refShowToolBar.remove(&refShowToolBar);
				static if (UseCards) {
					_comm.refCardState.remove(&refreshCardState);
					foreach (dlg; _editDlgsC.values) { mixin(S_TRACE);
						dlg.forceCancel();
					}
				}
				static if (UseBacks) {
					_comm.refPreviewValues.remove(&refreshTextCell);
					_comm.refFlagAndStep.remove(&refreshTextCellF);
					foreach (dlg; _editDlgsB.values) { mixin(S_TRACE);
						dlg.forceCancel();
					}
				}
			}
		});
		static if (is (C == EnemyCard) || RefCards) {
			_comm.refCast.add(&__refreshCast);
			_comm.delCast.add(&__deleteCast);
			addDisposeListener(new class DisposeListener {
				override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
					_comm.refCast.remove(&__refreshCast);
					_comm.delCast.remove(&__deleteCast);
				}
			});
		}
		static if (is (A == Area)) {
			_viewMsg = _prop.var.etc.viewMessageArea;
			_viewParty = _prop.var.etc.viewPartyCardsArea;
			_fixedC = _prop.var.etc.fixedImagesMenuCards;
			_fixedB = _prop.var.etc.fixedImagesCells;
		} else static if (is (A == Battle)) {
			_viewMsg = _prop.var.etc.viewMessageBattle;
			_viewParty = _prop.var.etc.viewPartyCardsBattle;
			_fixedC = _prop.var.etc.fixedImagesBattle;
		} else static if (is (A == BgImageContainer)) {
			_viewMsg = _prop.var.etc.viewMessageEvent;
			_viewParty = _prop.var.etc.viewPartyCardsEvent;
			_fixedB = _prop.var.etc.fixedImagesEvent;
		} else { mixin(S_TRACE);
			static assert (0);
		}
		_showGrid = _prop.var.etc.showGrid;
		_gridX = _prop.var.etc.gridX;
		_gridY = _prop.var.etc.gridY;
		static if (is(C : EnemyCard) || RefCards) {
			_dbgMode = _prop.var.etc.viewEnemyCardDebug;
		}
		addDisposeListener(new class DisposeListener {
			public override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				static if (is (A == Area)) {
					_prop.var.etc.viewMessageArea = _viewMsg;
					_prop.var.etc.viewPartyCardsArea = _viewParty;
					_prop.var.etc.fixedImagesMenuCards = _fixedC;
					_prop.var.etc.fixedImagesCells = _fixedB;
				} else static if (is (A == Battle)) {
					_prop.var.etc.viewMessageBattle = _viewMsg;
					_prop.var.etc.viewPartyCardsBattle = _viewParty;
					_prop.var.etc.fixedImagesBattle = _fixedC;
				} else static if (is (A == BgImageContainer)) {
					_prop.var.etc.viewMessageEvent = _viewMsg;
					_prop.var.etc.viewPartyCardsEvent = _viewParty;
					_prop.var.etc.fixedImagesEvent = _fixedB;
				} else { mixin(S_TRACE);
					static assert (0);
				}
				_prop.var.etc.showGrid = _showGrid;
				_prop.var.etc.gridX = _gridX;
				_prop.var.etc.gridY = _gridY;
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
				public override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
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
		} else { mixin(S_TRACE);
			static assert (0);
		}

		if (_tlp) setupTLP(_tlp);
		_toolbar = new ToolBar(this, SWT.FLAT);
		_comm.put(_toolbar);

		auto lrSash = new SplitPane(this, SWT.HORIZONTAL);
		lrSash.setLayoutData(new GridData(GridData.FILL_BOTH));
		auto left = new Composite(lrSash, SWT.NONE);
		{ mixin(S_TRACE);
			auto lgl = zeroMarginGridLayout(2, false);
			lgl.verticalSpacing = WGL_SPACING;
			left.setLayout(lgl);
		}
		{ mixin(S_TRACE);
			Composite listsP;
			static if (UseCards && UseBacks) {
				_sash = new SplitPane(left, SWT.VERTICAL);
				listsP = _sash;
			} else { mixin(S_TRACE);
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
						prop.images.cards, ctcpd, &editCard, &_area.cards, &selectAllC);
					new TableTextEdit(_comm, _prop, _cards, 0, &nameEditEnd);
				} else static if (is (C == EnemyCard)) {
					_cards = createList(listsP, prop.msgs.enemyCards,
						prop.images.cards, ctcpd, &editCard, &_area.cards, &selectAllC);
					new TableComboEdit!Combo(_comm, _prop, _cards, 0, &createEnemyCombo, &enemyEditEnd, (itm, column) => 0 < _summ.casts.length, &enemyIncSearch);
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
					prop.images.backs, btcpd, &editBack, &_area.backs, &selectAllB);
				_backs.addSelectionListener(new SBListener);
				new TableComboEdit!Combo(_comm, _prop, _backs, 0, &createBgImageCombo, &bgImageEditEnd, &bgImageCanEdit, &bgImageIncSearch);
				auto backDrop = new DropTarget(_backs, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_LINK);
				backDrop.setTransfer([cast(Transfer) FileTransfer.getInstance(), XMLBytesTransfer.getInstance()]);
				backDrop.addDropListener(new BLDropTarget);
				_backs.addMouseTrackListener(prevTrig);
				_backs.addMouseMoveListener(prevTrig);
			}
			static if (UseCards && UseBacks) {
				_cards.addMouseListener(new class MouseAdapter {
					override void mouseDown(MouseEvent e) { mixin(S_TRACE);
						if (e.button == 1 && (e.stateMask & SWT.CTRL) == 0 && (e.stateMask & SWT.SHIFT) == 0) { mixin(S_TRACE);
							_imgp.deselectRange(0, _area.backs.length);
							_backs.deselectAll();
							typeof(_editB) editB;
							_editB = editB;
							refreshControls();
						}
					}
				});
				_backs.addMouseListener(new class MouseAdapter {
					override void mouseDown(MouseEvent e) { mixin(S_TRACE);
						if (e.button == 1 && (e.stateMask & SWT.CTRL) == 0 && (e.stateMask & SWT.SHIFT) == 0) { mixin(S_TRACE);
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
					override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
						_prop.var.etc.areaSashT = _sash.getWeights()[0];
						_prop.var.etc.areaSashB = _sash.getWeights()[1];
					}
				});
			}
		}
		if (_summ) { mixin(S_TRACE);
			auto lFlag = new Label(left, SWT.NONE);
			lFlag.setText(_prop.msgs.areaViewFlagDesc);
			_flag = new Combo(left, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			_flag.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			_flag.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_flag.add(_prop.msgs.noFlagRef);
			_flag.addSelectionListener(new SelFlag);
			_comm.refFlagAndStep.add(&refFlag);
			_comm.delFlagAndStep.add(&refFlag);
			_flag.addDisposeListener(new FlagsDispose);
			{ mixin(S_TRACE);
				_flagIncSearch = new IncSearch(_comm, _flag);
				_flagIncSearch.modEvent ~= &refreshFlag;

				auto menu = new Menu(_flag.getShell(), SWT.POP_UP);
				createMenuItem(_comm, menu, MenuID.IncSearch, {
					.forceFocus(_flag, true);
					_flagIncSearch.startIncSearch();
				}, () => 1 < _flag.getItemCount());
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.OpenAtVarView, &openFlagView, () => _flag.getSelectionIndex() > 0);
				_flag.setMenu(menu);
			}
			refreshFlag();
			static if (RefCards) {
				auto lRef = new Label(left, SWT.NONE);
				lRef.setText(_prop.msgs.areaViewRefAreaDesc);
				_refAreas = new Combo(left, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
				_refAreas.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				_refAreas.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_refAreas.add(_prop.msgs.noRefArea);
				listener(_refAreas,  SWT.Selection, { mixin(S_TRACE);
					int sel = _refAreas.getSelectionIndex();
					_refTarget = sel <= 0 ? null : _refAreasArr[sel - 1];
					if (!_refTarget) { mixin(S_TRACE);
						foreach (a; _imgp.appends) { mixin(S_TRACE);
							a.data[] = 0;
							delete a.data;
							a.alphaData[] = 0;
							delete a.alphaData;
						}
						_imgp.appends = [];
					}
					refreshPanel();
				});
				{ mixin(S_TRACE);
					auto menu = new Menu(_refAreas.getShell(), SWT.POP_UP);

					_refAreaIncSearch = new IncSearch(_comm, _refAreas);
					_refAreaIncSearch.modEvent ~= &refreshRefAreas;
					createMenuItem(_comm, menu, MenuID.IncSearch, {
						.forceFocus(_refAreas, true);
						_refAreaIncSearch.startIncSearch();
					}, () => 1 < _flag.getItemCount());
					new MenuItem(menu, SWT.SEPARATOR);

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
				listener(_refAreas, SWT.Dispose, { mixin(S_TRACE);
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
		{ mixin(S_TRACE);
			if (_summ) { mixin(S_TRACE);
				auto lrSash2 = new SplitPane(lrSash, SWT.HORIZONTAL);
				createImagePane(lrSash2);
				createFlagList(lrSash2);
				static if (is(A:Area)) {
					lrSash2.setWeights([_prop.var.etc.areaViewImageFlagL, _prop.var.etc.areaViewImageFlagR]);
				} else static if (is(A:Battle)) {
					lrSash2.setWeights([_prop.var.etc.battleViewImageFlagL, _prop.var.etc.battleViewImageFlagR]);
				} else static if (is(A:BgImageContainer)) {
					lrSash2.setWeights([_prop.var.etc.bgImageViewImageFlagL, _prop.var.etc.bgImageViewImageFlagR]);
				} else static assert (0);
				.listener(lrSash2, SWT.Dispose, { mixin(S_TRACE);
					auto ws = lrSash2.getWeights();
					static if (is(A:Area)) {
						_prop.var.etc.areaViewImageFlagL = ws[0];
						_prop.var.etc.areaViewImageFlagR = ws[1];
					} else static if (is(A:Battle)) {
						_prop.var.etc.battleViewImageFlagL = ws[0];
						_prop.var.etc.battleViewImageFlagR = ws[1];
					} else static if (is(A:BgImageContainer)) {
						_prop.var.etc.bgImageViewImageFlagL = ws[0];
						_prop.var.etc.bgImageViewImageFlagR = ws[1];
					} else static assert (0);
				});
			} else { mixin(S_TRACE);
				createImagePane(lrSash);
			}
			static if (is (C == MenuCard) || UseBacks) {
				auto target = new DropTarget(_imgp, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_LINK);
				static if (is (C == MenuCard)) {
					target.setTransfer([cast(Transfer) FileTransfer.getInstance(), XMLBytesTransfer.getInstance()]);
				} else { mixin(S_TRACE);
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
		// 遅延実行
		_imgp.addPaintListener(new class PaintListener {
			override void paintControl(PaintEvent e) {
				_imgp.removePaintListener(this);
				_toolbar.setRedraw(false);
				scope (exit) _toolbar.setRedraw(true);
				setupToolBar(_toolbar);
				refreshControls();
			}
		});
		static if (is(A : Battle) && is(C : EnemyCard)) {
			{ mixin(S_TRACE);
				auto target = new DropTarget(imagePane, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_LINK);
				target.setTransfer([XMLBytesTransfer.getInstance()]);
				target.addDropListener(new DTListener);
			}
			{ mixin(S_TRACE);
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

		static if (is(A:Area)) {
			lrSash.setWeights([_prop.var.etc.areaViewL, _prop.var.etc.areaViewR]);
		} else static if (is(A:Battle)) {
			lrSash.setWeights([_prop.var.etc.battleViewL, _prop.var.etc.battleViewR]);
		} else static if (is(A:BgImageContainer)) {
			lrSash.setWeights([_prop.var.etc.bgImageViewL, _prop.var.etc.bgImageViewR]);
		} else static assert (0);
		lrSash.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				auto ws = (cast(SplitPane) e.widget).getWeights();
				static if (is(A:Area)) {
					_prop.var.etc.areaViewL = ws[0];
					_prop.var.etc.areaViewR = ws[1];
				} else static if (is(A:Battle)) {
					_prop.var.etc.battleViewL = ws[0];
					_prop.var.etc.battleViewR = ws[1];
				} else static if (is(A:BgImageContainer)) {
					_prop.var.etc.bgImageViewL = ws[0];
					_prop.var.etc.bgImageViewR = ws[1];
				} else static assert (0);
			}
		});
		refShowToolBar();
		static if (UseCards) refreshCards();
		static if (UseBacks) refreshBacks();
		static if (RefCards) {
			refreshRefAreas();
		}
		refreshGrid();
		refreshFlags();
	}
	private string _statusLine;
	@property
	private void statusLine(string statusLine) { mixin(S_TRACE);
		_statusLine = statusLine;
		_comm.setStatusLine(_imgp, statusLine);
	}
	@property
	string statusLine() {return _statusLine;}

	@property
	A area() { mixin(S_TRACE);
		return _area;
	}
	@property
	Summary summary() { mixin(S_TRACE);
		return _summ;
	}
	static if (is(A : Area) || is(A : Battle)) {
		void openEvent() { mixin(S_TRACE);
			if (!_summ) return;
			string path;
			auto i = _cards.getSelectionIndex();
			if (-1 != i) { mixin(S_TRACE);
				auto card = cast(C) _cards.getItem(i).getData();
				if (card.trees.length) { mixin(S_TRACE);
					path = card.trees[0].cwxPath(true);
				} else { mixin(S_TRACE);
					path = card.cwxPath(true);
				}
			} else { mixin(S_TRACE);
				path = area.cwxPath(true);
			}
			path = cpaddattr(path, "eventview");
			_comm.openCWXPath(path, true);
		}
	}
	void refreshR(string from, string to) { mixin(S_TRACE);
		refresh();
	}
	private void replText() { mixin(S_TRACE);
		static if (UseCards) {
			auto skin = _comm.skin;
			foreach (i, c; _area.cards) { mixin(S_TRACE);
				string name = cardName(c);
				auto itm = cardList.getItem(i);
				if (itm.getText() != name) { mixin(S_TRACE);
					auto img = _imgp.images[cardsIndex + i];
					static if (is(C:EnemyCard)) {
						auto castCard = _summ.cwCast(c.id);
						if (!castCard) continue; // カード名が表示されないため不要
						img.setImageData(castCardImage(_prop, skin, castCard, _summ ? _summ.scenarioPath : "", _dbgMode));
					} else { mixin(S_TRACE);
						img.title = name;
					}
					img.createImage();
					itm.setText(name);
					_comm.refMenuCard.call(c.cwxPath(true));
				}
				// 置換でフラグ名が消失する可能性があるため
				itm.setImage(cardImg(c));
			}
			_imgp.redraw();
		}
		static if (UseBacks) {
			foreach (i, b; _area.backs) { mixin(S_TRACE);
				backList.getItem(i).setImage(backImg(b));
			}
		}
	}
	static if (UseCards) {
		private void refreshCardState() { mixin(S_TRACE);
			for (int i = 0; i < _area.cards.length; i++) { mixin(S_TRACE);
				auto fi = cast(FlexImage) _imgp.images[cardsIndex + i];
				fi.smoothing = _prop.var.etc.smoothingCard;
				fi.createImage();
			}
			_imgp.redraw();
		}
	}
	private void refreshPanel() { mixin(S_TRACE);
		auto sels = _imgp.selectedIndices;
		size_t partyIndex = 0;
		static if (UseCards) {
			foreach (i, c; _area.cards) { mixin(S_TRACE);
				auto v = _imgp.images[cardsIndex + i].visible;
				auto fi = create(c);
				fi.visible = v;
				_imgp.set(cardsIndex + i, fi);
				_cards.getItem(i).setText(cardName(c));
				_cards.getItem(i).setImage(cardImg(c));
				_cards.getItem(i).setData(c);
				partyIndex++;
			}
		}
		static if (UseBacks) {
			foreach (i, b; _area.backs) { mixin(S_TRACE);
				auto v = _imgp.images[i].visible;
				auto fi = create(b);
				fi.visible = v;
				_imgp.set(i, fi);
				_backs.getItem(i).setText(b.name);
				_backs.getItem(i).setImage(backImg(b));
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
	private void appendPartyCards() { mixin(S_TRACE);
		static if (RefCards) {
			if (_refTarget) { mixin(S_TRACE);
				auto a = cast(Area) _refTarget;
				if (a) addRefCards(a.cards);
				auto b = cast(Battle) _refTarget;
				if (b) addRefCards(b.cards);
			}
		}
		foreach (p; _prop.looks.partyCardXY) { mixin(S_TRACE);
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
		void addRefCards(C2)(in C2[] cs) { mixin(S_TRACE);
			foreach (a; _imgp.appends) { mixin(S_TRACE);
				a.data[] = 0;
				delete a.data;
				a.alphaData[] = 0;
				delete a.alphaData;
			}
			auto a = createRefCardImpl!C2(cs, -1);
			if (a) { mixin(S_TRACE);
				_imgp.appends = [a];
			} else { mixin(S_TRACE);
				_imgp.appends = [];
			}
		}
		void createRefCard(int del = -1) { mixin(S_TRACE);
			foreach (a; _imgp.appends) { mixin(S_TRACE);
				a.data[] = 0;
				delete a.data;
				a.alphaData[] = 0;
				delete a.alphaData;
			}
			_imgp.appends = [];
			auto area = cast(Area) _refTarget;
			if (area) { mixin(S_TRACE);
				auto a = createRefCardImpl(area.cards, del);
				if (a) _imgp.appends = [a];
			}
			auto battle = cast(Battle) _refTarget;
			if (battle) { mixin(S_TRACE);
				auto a = createRefCardImpl(battle.cards, del);
				if (a) _imgp.appends = [a];
			}
		}
		ImageData createRefCardImpl(C2)(in C2[] cs, int del) { mixin(S_TRACE);
			auto d = getDisplay();
			auto vs = _prop.looks.viewSize;
			auto img = new Image(d, vs.width, vs.height);
			auto data = img.getImageData();
			img.dispose();
			auto alphas = new byte[vs.width * vs.height];
			scope (exit) {
				alphas[] = 0;
				delete alphas;
			}
			alphas[] = 0;
			data.setAlphas(0, 0, vs.width * vs.height, alphas, 0);
			foreach (i, c; cs) { mixin(S_TRACE);
				if (i == del) continue;
				auto pimg = createCardImage!PileImage(c, _prop.var.etc.smoothingCard);
				auto pdata = pimg.createImageData();
				scope (exit) {
					pdata.data[] = 0;
					delete pdata.data;
				}
				assert (pdata !is null);
				foreach (x; 0 .. pimg.width) { mixin(S_TRACE);
					foreach (y; 0 .. pimg.height) { mixin(S_TRACE);
						int x2 = x + pimg.x;
						int y2 = y + pimg.y;
						if (0 <= x2 && x2 < vs.width && 0 <= y2 && y2 < vs.height) { mixin(S_TRACE);
							data.setPixel(x2, y2, pdata.getPixel(x, y));
							data.setAlpha(x2, y2, _prop.var.etc.partyCardAlpha);
						}
					}
				}
				pimg.dispose();
			}
			return data;
		}
	}
	void refresh() { mixin(S_TRACE);
		static if (UseCards && is (C == EnemyCard)) {
			_bgm.refresh();
		}
		refreshPanel();
	}
	private void removeImpl(T)(int index, ref T[PileImage] tbl, int startIndex) { mixin(S_TRACE);
		tbl.remove(_imgp.images[startIndex + index]);
		_imgp.remove(startIndex + index);
		callModEvent();
		_comm.refreshToolBar();
	}
	private void removeRangeImpl(T)(int fromIndex, int toIndex, ref T[PileImage] tbl, int startIndex) { mixin(S_TRACE);
		for (int i = fromIndex + startIndex; i < toIndex + startIndex; i++) { mixin(S_TRACE);
			tbl.remove(_imgp.images[i]);
		}
		_imgp.removeRange(startIndex + fromIndex, startIndex + toIndex);
		callModEvent();
		_comm.refreshToolBar();
	}
	static if (UseCards) {
		private static void removeCard(AbstractAreaView v, Commons comm, A area, ref C[PileImage] tbl, int index) { mixin(S_TRACE);
			if (v) v.removeImpl(index, tbl, staticCardsIndex(area));
			comm.delMenuCard.call(area.cards[index].cwxPath(true));
		}
		private void removeCardRange(int fromIndex, int toIndex) { mixin(S_TRACE);
			removeRangeImpl(fromIndex, toIndex, _cardTbl, cardsIndex);
			for (int i = toIndex; i >= fromIndex; i--) { mixin(S_TRACE);
				_comm.delMenuCard.call(_area.cards[i].cwxPath(true));
			}
		}
	}
	static if (UseBacks) {
		private static void removeBack(AbstractAreaView v, Commons comm, A area, ref BgImage[PileImage] tbl, int index) { mixin(S_TRACE);
			if (v) v.removeImpl(index, tbl, 0);
			comm.delBgImage.call(area.backs[index].cwxPath(true));
		}
		private void removeBackRange(int fromIndex, int toIndex) { mixin(S_TRACE);
			removeRangeImpl(fromIndex, toIndex, _backTbl, 0);
			for (int i = toIndex; i >= fromIndex; i--) { mixin(S_TRACE);
				_comm.delBgImage.call(_area.backs[i].cwxPath(true));
			}
		}
	}

	@property
	bool isFocusOnListOrPane() { mixin(S_TRACE);
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
	bool canUp() { mixin(S_TRACE);
		if (!isFocusOnListOrPane()) return false;
		int[] cIdcs, bIdcs;
		static if (UseCards) {
			if (_viewCards) { mixin(S_TRACE);
				cIdcs = _cards.getSelectionIndices().sort;
				if (cIdcs.length && cIdcs[0] <= 0) return false;
			}
		}
		static if (UseBacks) {
			if (_viewBacks) { mixin(S_TRACE);
				bIdcs = _backs.getSelectionIndices().sort;
				if (bIdcs.length && bIdcs[0] <= 0) return false;
			}
		}
		return cIdcs.length || bIdcs.length;
	}
	@property
	bool canDown() { mixin(S_TRACE);
		if (!isFocusOnListOrPane()) return false;
		int[] cIdcs, bIdcs;
		static if (UseCards) {
			if (_viewCards) { mixin(S_TRACE);
				cIdcs = _cards.getSelectionIndices().sort;
				if (cIdcs.length && _cards.getItemCount() - 1 <= cIdcs[$ - 1]) return false;
			}
		}
		static if (UseBacks) {
			if (_viewBacks) { mixin(S_TRACE);
				bIdcs = _backs.getSelectionIndices().sort;
				if (bIdcs.length && _backs.getItemCount() - 1 <= bIdcs[$ - 1]) return false;
			}
		}
		return cIdcs.length || bIdcs.length;
	}
	void up() { mixin(S_TRACE);
		up(1, true, true);
	}
	void up(int count, bool cards, bool backs) { mixin(S_TRACE);
		if (!isFocusOnListOrPane()) return;
		int[] cIdcs;
		int[] bIdcs;
		static if (UseCards) {
			if (cards) { mixin(S_TRACE);
				if (_viewCards) cIdcs = _cards.getSelectionIndices();
				cIdcs = cIdcs.sort;
				if (cIdcs.length && cIdcs[0] < count) { mixin(S_TRACE);
					count = cIdcs[0];
				}
			}
		}
		static if (UseBacks) {
			if (backs) { mixin(S_TRACE);
				if (_viewBacks) bIdcs = _backs.getSelectionIndices();
				bIdcs = bIdcs.sort;
				if (bIdcs.length && bIdcs[0] < count) { mixin(S_TRACE);
					count = bIdcs[0];
				}
			}
		}
		if ((!cIdcs.length && !bIdcs.length) || 0 >= count) return;
		_undo ~= new UndoUp(this, _comm, _area, _summ, cIdcs, bIdcs, count);
		upImpl(this, _comm, _area, cIdcs, bIdcs, count, true);
		_comm.refreshToolBar();
	}
	private static void upImpl(AbstractAreaView v, Commons comm, A area, int[] cIdcs, int[] bIdcs, int count, bool sel) { mixin(S_TRACE);
		static if (UseCards) {
			upImpl2!(C)(v, v ? v._cards : null, &area.swapCards, staticCardsIndex(area), cIdcs, count);
			comm.upMenuCard.call(area.cwxPath(true), cIdcs, count);
		}
		static if (UseBacks) {
			upImpl2!(BgImage)(v, v ? v._backs : null, &area.swapBacks, 0, bIdcs, count);
			comm.upBgImage.call(area.cwxPath(true), bIdcs, count);
		}
		if (v) { mixin(S_TRACE);
			if (sel) { mixin(S_TRACE);
				int[] sels;
				static if (UseCards) {
					foreach (ci; cIdcs) { mixin(S_TRACE);
						sels ~= staticCardsIndex(area) + ci - count;
					}
				}
				static if (UseBacks) {
					foreach (bi; bIdcs) { mixin(S_TRACE);
						sels ~= bi - count;
					}
				}
				v._imgp.select(sels);
			}
			v.refreshSelected();
			if (cIdcs.length > 0 || bIdcs.length > 0) v._imgp.redraw();
		}
	}
	void down() { mixin(S_TRACE);
		down(1, true, true);
	}
	void down(int count, bool cards, bool backs) { mixin(S_TRACE);
		if (!isFocusOnListOrPane()) return;
		int[] cIdcs;
		int[] bIdcs;
		static if (UseCards) {
			if (cards) { mixin(S_TRACE);
				if (_viewCards) cIdcs = _cards.getSelectionIndices();
				cIdcs = cIdcs.sort;
				if (cIdcs.length && _cards.getItemCount() - count <= cIdcs[$ - 1]) { mixin(S_TRACE);
					count = _cards.getItemCount() - 1 - cIdcs[$ - 1];
				}
			}
		}
		static if (UseBacks) {
			if (backs) { mixin(S_TRACE);
				if (_viewBacks) bIdcs = _backs.getSelectionIndices();
				bIdcs = bIdcs.sort;
				if (bIdcs.length && _backs.getItemCount() - count <= bIdcs[$ - 1]) { mixin(S_TRACE);
					count = _backs.getItemCount() - 1 - bIdcs[$ - 1];
				}
			}
		}
		if ((!cIdcs.length && !bIdcs.length) || 0 >= count) return;
		_undo ~= new UndoDown(this, _comm, _area, _summ, cIdcs, bIdcs, count);
		downImpl(this, _comm, _area, cIdcs, bIdcs, count, true);
		_comm.refreshToolBar();
	}
	private static void downImpl(AbstractAreaView v, Commons comm, A area, int[] cIdcs, int[] bIdcs, int count, bool sel) { mixin(S_TRACE);
		static if (UseCards) {
			downImpl2!(C)(v, v ? v._cards : null, &area.swapCards, staticCardsIndex(area), cIdcs, area.cards.length, count);
			comm.downMenuCard.call(area.cwxPath(true), cIdcs, count);
		}
		static if (UseBacks) {
			downImpl2!(BgImage)(v, v ? v._backs : null, &area.swapBacks, 0, bIdcs, area.backs.length, count);
			comm.downBgImage.call(area.cwxPath(true), bIdcs, count);
		}
		if (v) { mixin(S_TRACE);
			if (sel) { mixin(S_TRACE);
				int[] sels;
				static if (UseCards) {
					foreach (ci; cIdcs) { mixin(S_TRACE);
						sels ~= staticCardsIndex(area) + ci + count;
					}
				}
				static if (UseBacks) {
					foreach (bi; bIdcs) { mixin(S_TRACE);
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
				MenuItem menu, ToolItem titm) { mixin(S_TRACE);
			if (_imgp.isVisible()) .forceFocus(this, false);
			view = !view;
			list.setEnabled(view);
			for (int i = 0; i < col().length; i++) { mixin(S_TRACE);
				auto fi = cast(FlexImage) _imgp.images[startIndex + i];
				fi.visible = view && list.getItem(i).getChecked();
				if (!view && fi.selected) { mixin(S_TRACE);
					_imgp.deselect(fi);
					edits.remove(col()[i]);
				}
			}
			if (!view) { mixin(S_TRACE);
				list.deselectAll();
			}
			if (menu) menu.setSelection(view);
			if (titm) titm.setSelection(view);
			refreshControls();
			_imgp.redraw();
		}
		void reverseViewCards() { mixin(S_TRACE);
			reverseView!(C)(_viewCards, _cards, _editC, &_area.cards, cardsIndex, _vcMenu, _vcTMenu);
		}
		void reverseViewBacks() { mixin(S_TRACE);
			reverseView!(BgImage)(_viewBacks, _backs, _editB, &_area.backs, 0, _vbMenu, _vbTMenu);
		}
	}
	static if (UseCards) {
		SpCardDialog!(C)[C] _editDlgsC;
		void editCardApply(UndoEdit undo, C card) { mixin(S_TRACE);
			assert (undo);
			_undo ~= undo;
			int index;
			foreach (i, c; _area.cards) { mixin(S_TRACE);
				if (c is card) { mixin(S_TRACE);
					auto fi = create(card);
					_imgp.set(cardsIndex + i, fi);
					if (_cards.isSelected(i) && _viewCards) _imgp.select(fi);
					_cards.getItem(i).setText(cardName(c));
					_cards.getItem(i).setImage(cardImg(c));
					_cards.getItem(i).setData(c);
					refreshControls();
					_comm.refMenuCard.call(c.cwxPath(true));
					_comm.refUseCount.call();
					refreshFlags();
					_imgp.redraw();
					callModEvent();
					_comm.refreshToolBar();
					return;
				}
			}
			assert (0);
		}
		void createCard() { mixin(S_TRACE);
			static if (is(C : MenuCard)) {
				auto c = new MenuCard("", "", "", "", 0, 0, 1.0);
			} else static if (is(C : EnemyCard)) {
				if (!_summ) return;
				if (_summ.casts.length == 0) return;
				auto c = new EnemyCard(0, false, "", 0, 0, 1.0);
			} else static assert (0);
			auto dlg = new SpCardDialog!(C)(_comm, _prop, getShell(), _summ, c, true);
			dlg.appliedEvent ~= { mixin(S_TRACE);
				auto c = dlg.card;
				int index = insertIndex(_cards);
				_undo ~= new UndoInsert(this, _comm, _area, _summ, [index], []);
				appendCard(index, c, true, true);
				UndoEdit undo = null;
				dlg.applyEvent ~= { mixin(S_TRACE);
					undo = new UndoEdit(this, _comm, _area, _summ, [cCountUntil!("a is b")(_area.cards, c)], []);
				};
				dlg.appliedEvent.length = 0;
				dlg.appliedEvent ~= { mixin(S_TRACE);
					editCardApply(undo, c);
				};
			};
			_editDlgsC[c] = dlg;
			dlg.closeEvent ~= { mixin(S_TRACE);
				_editDlgsC.remove(c);
			};
			dlg.open();
		}
		void editCard(int[] indices) { mixin(S_TRACE);
			foreach (i; indices) { mixin(S_TRACE);
				editCard(_area.cards[i]);
			}
		}
		void editCard(C card) { mixin(S_TRACE);
			auto p = card in _editDlgsC;
			if (p) { mixin(S_TRACE);
				p.active();
				return;
			}
			foreach (i, c; _area.cards) { mixin(S_TRACE);
				if (c is card) { mixin(S_TRACE);
					_imgp.select([i + cardsIndex]);
					refreshSelected();
					break;
				}
			}
			UndoEdit undo = null;
			auto dlg = new SpCardDialog!(C)(_comm, _prop, getShell(), _summ, card, false);
			dlg.applyEvent ~= { mixin(S_TRACE);
				undo = new UndoEdit(this, _comm, _area, _summ, [cCountUntil!("a is b")(_area.cards, card)], []);
			};
			dlg.appliedEvent ~= { mixin(S_TRACE);
				editCardApply(undo, card);
			};
			_editDlgsC[card] = dlg;
			dlg.closeEvent ~= { mixin(S_TRACE);
				_editDlgsC.remove(card);
			};
			dlg.open();
		}
		static if (is(C : MenuCard)) {
			void nameEditEnd(TableItem selItm, int column, string newText) { mixin(S_TRACE);
				int[] indices;
				foreach (itm; selItm.getParent().getSelection()) { mixin(S_TRACE);
					auto c = cast(C)itm.getData();
					if (c.name == newText) continue;
					indices ~= itm.getParent().indexOf(itm);
				}
				if (indices.length) { mixin(S_TRACE);
					_undo ~= new UndoEdit(this, _comm, _area, _summ, indices, []);
					foreach (index; indices) { mixin(S_TRACE);
						auto itm = selItm.getParent().getItem(index);
						auto c = cast(C)itm.getData();
						c.name = newText;
						itm.setText(column, c.name);
						_comm.refMenuCard.call(c.cwxPath(true));
					}
					refreshPanel();
					callModEvent();
				}
				_comm.refreshToolBar();
			}
		} else static if (is(C : EnemyCard)) {
			void enemyEditEnd(TableItem selItm, int column, Combo combo) { mixin(S_TRACE);
				assert (_summ);
				int i = combo.getSelectionIndex();
				if (-1 == i) return;
				int[] indices;
				foreach (itm; selItm.getParent().getSelection()) { mixin(S_TRACE);
					auto c = cast(C)itm.getData();
					if (c.id == _summ.casts[i].id) continue;
					indices ~= itm.getParent().indexOf(itm);
				}
				if (indices.length) { mixin(S_TRACE);
					_undo ~= new UndoEdit(this, _comm, _area, _summ, indices, []);
					foreach (index; indices) { mixin(S_TRACE);
						auto itm = selItm.getParent().getItem(index);
						auto c = cast(C)itm.getData();
						c.id = _summ.casts[i].id;
						itm.setText(column, cardName(c));
						_comm.refMenuCard.call(c.cwxPath(true));
					}
					refreshPanel();
					callModEvent();
				}
				_comm.refreshToolBar();
			}
			void createEnemyCombo(TableItem itm, int column, out string[] strs, out string str) { mixin(S_TRACE);
				assert (_summ);
				auto c = cast(C) itm.getData();
				foreach (cc; _summ.casts) { mixin(S_TRACE);
					string s = to!string(cc.id) ~ "." ~ cc.name;
					strs ~= s;
					if (cc.id == c.id) { mixin(S_TRACE);
						str = s;
					}
				}
			}
			string[] enemyIncSearch(IncSearch incSearch) { mixin(S_TRACE);
				assert (_summ);
				string[] strs;
				foreach (cc; _summ.casts) { mixin(S_TRACE);
					if (!incSearch.match(cc.name)) continue;
					string s = to!string(cc.id) ~ "." ~ cc.name;
					strs ~= s;
				}
				return strs;
			}
		} else static assert (0);
		@property
		bool isViewCards() { mixin(S_TRACE);
			return _viewCards;
		}
	}
	PImg createCardImage(PImg, C2)(in C2 card, bool smoothing) { mixin(S_TRACE);
		static if (is(C2 : MenuCard) || is(C2 : const MenuCard)) {
			return createMenuCardImage!PImg
				(prop, _comm.skin, card.name,
				cardImagePath(card), card.x, card.y, card.scale, smoothing, card.pcNumber);
		} else static if (is(C2 : EnemyCard) || is(C2 : const EnemyCard)) {
			auto skin = _comm.skin;
			auto castCard = summary.cwCast(card.id);
			if (castCard) { mixin(S_TRACE);
				return createCastCardImage!PImg(prop, skin, castCard, _summ.scenarioPath,
					card.x, card.y, card.scale, smoothing, debugMode);
			} else { mixin(S_TRACE);
				return createCastCardImage!PImg(prop, skin, null, _summ.scenarioPath,
					card.x, card.y, card.scale, smoothing, debugMode);
			}
		} else static assert (0, C2);
	}
	string cardName(C2)(in C2 card) { mixin(S_TRACE);
		static if (is(C2 : MenuCard)) {
			return card.name;
		} else static if (is(C2 : EnemyCard)) {
			auto castCard = summary.cwCast(card.id);
			return castCard ? castCard.name : "";
		} else static assert (0, C2);
	}
	string cardImagePath(C2)(in C2 card) { mixin(S_TRACE);
		static if (is(typeof(card.path))) {
			return _comm.skin.findImagePath(card.path, summary.scenarioPath);
		} else static if (is(typeof(summary.cwCast(card.id)))) {
			auto castCard = summary.cwCast(card.id);
			if (castCard) { mixin(S_TRACE);
				return _comm.skin.findImagePath(castCard.path, summary.scenarioPath);
			} else { mixin(S_TRACE);
				return "";
			}
		} else static assert (0, C2);
	}
	static if (UseBacks) {
		BgImageDialog[BgImage] _editDlgsB;
		void editBackApply(UndoEdit undo, BgImage back) { mixin(S_TRACE);
			assert (undo);
			_undo ~= undo;
			foreach (i, b; _area.backs) { mixin(S_TRACE);
				if (b is back) { mixin(S_TRACE);
					auto fi = create(back);
					_imgp.set(i, fi);
					if (_backs.isSelected(i) && _viewBacks) _imgp.select(fi);
					_backs.getItem(i).setText(back.name);
					_backs.getItem(i).setImage(backImg(back));
					_backs.getItem(i).setData(b);
					refreshControls();
					_comm.refBgImage.call(b.cwxPath(true));
					_comm.refUseCount.call();
					refreshFlags();
					_imgp.redraw();
					callModEvent();
					_comm.refreshToolBar();
					return;
				}
			}
			assert (0);
		}
		void createBackground() { mixin(S_TRACE);
			createBackgroundImpl(ImageType.Image);
		}
		void createTextCell() { mixin(S_TRACE);
			createBackgroundImpl(ImageType.Text);
		}
		void createColorCell() { mixin(S_TRACE);
			createBackgroundImpl(ImageType.ColorFilter);
		}
		void createBackgroundImpl(ImageType type) { mixin(S_TRACE);
			BgImage b = null;
			BgImageDialog dlg = null;
			final switch (type) {
			case ImageType.Image:
				auto ic = new ImageCell;
				dlg = new ImageCellDialog(_comm, _prop, getShell(), _summ, ic, true);
				b = ic;
				break;
			case ImageType.Text:
				auto tc = new TextCell;
				tc.width = _prop.var.etc.textCellDefaultWidth;
				tc.height = _prop.var.etc.textCellDefaultHeight;
				dlg = new TextCellDialog(_comm, _prop, getShell(), _summ, tc, true);
				b = tc;
				break;
			case ImageType.ColorFilter:
				auto cc = new ColorCell;
				cc.width = _prop.var.etc.colorCellDefaultWidth;
				cc.height = _prop.var.etc.colorCellDefaultHeight;
				dlg = new ColorCellDialog(_comm, _prop, getShell(), _summ, cc, true);
				b = cc;
				break;
			}
			dlg.appliedEvent ~= { mixin(S_TRACE);
				auto b = dlg.back;
				int index = insertIndex(_backs);
				_undo ~= new UndoInsert(this, _comm, _area, _summ, [], [index]);
				appendBgImage(index, b, true, true);
				UndoEdit undo = null;
				dlg.applyEvent ~= { mixin(S_TRACE);
					undo = new UndoEdit(this, _comm, _area, _summ, [], [cCountUntil!("a is b")(_area.backs, b)]);
				};
				dlg.appliedEvent.length = 0;
				dlg.appliedEvent ~= { mixin(S_TRACE);
					editBackApply(undo, b);
				};
			};
			_editDlgsB[b] = dlg;
			dlg.closeEvent ~= { mixin(S_TRACE);
				_editDlgsB.remove(b);
			};
			dlg.open();
		}
		void editBack(int[] indices) { mixin(S_TRACE);
			foreach (i; indices) { mixin(S_TRACE);
				editBack(_area.backs[i]);
			}
		}
		void editBack(BgImage back) { mixin(S_TRACE);
			auto p = back in _editDlgsB;
			if (p) { mixin(S_TRACE);
				p.active();
				return;
			}
			foreach (i, b; _area.backs) { mixin(S_TRACE);
				if (b is back) { mixin(S_TRACE);
					_imgp.select([i]);
					refreshSelected();
					break;
				}
			}
			UndoEdit undo = null;
			BgImageDialog dlg = null;
			auto ic = cast(ImageCell) back;
			if (ic) { mixin(S_TRACE);
				dlg = new ImageCellDialog(_comm, _prop, getShell(), _summ, ic, false);
			}
			auto tc = cast(TextCell) back;
			if (tc) { mixin(S_TRACE);
				dlg = new TextCellDialog(_comm, _prop, getShell(), _summ, tc, false);
			}
			auto cc = cast(ColorCell) back;
			if (cc) { mixin(S_TRACE);
				dlg = new ColorCellDialog(_comm, _prop, getShell(), _summ, cc, false);
			}
			dlg.applyEvent ~= { mixin(S_TRACE);
				undo = new UndoEdit(this, _comm, _area, _summ, [], [cCountUntil!("a is b")(_area.backs, back)]);
			};
			dlg.appliedEvent ~= { mixin(S_TRACE);
				editBackApply(undo, back);
			};
			_editDlgsB[back] = dlg;
			dlg.closeEvent ~= { mixin(S_TRACE);
				_editDlgsB.remove(back);
			};
			dlg.open();
		}
		string[] _selectableBgImages;
		void bgImageEditEnd(TableItem itm, int column, Combo combo) { mixin(S_TRACE);
			int i = combo.getSelectionIndex();
			_selectableBgImages = [];
			if (-1 == i) return;
			auto b = cast(ImageCell) itm.getData();
			assert (b !is null);
			if (0 == i) { mixin(S_TRACE);
				if (b.path == "") return;
				_undo ~= new UndoEdit(this, _comm, _area, _summ, [], [itm.getParent().indexOf(itm)]);
				b.path = "";
				itm.setText(column, "");
			} else { mixin(S_TRACE);
				string mt = combo.getText();
				if (std.string.startsWith(mt, "/")) { mixin(S_TRACE);
					mt = mt["/".length .. $];
				}
				if (b.path == mt) return;
				_undo ~= new UndoEdit(this, _comm, _area, _summ, [], [itm.getParent().indexOf(itm)]);
				b.path = mt;
				itm.setText(column, baseName(decodePath(mt)));
			}
			refreshPanel();
			_comm.refBgImage.call(b.cwxPath(true));
			callModEvent();
			_comm.refreshToolBar();
		}
		bool bgImageCanEdit(TableItem itm, int column) { mixin(S_TRACE);
			return (cast(ImageCell) itm.getData()) !is null;
		}
		void createBgImageCombo(TableItem itm, int column, out string[] strs, out string str) { mixin(S_TRACE);
			_selectableBgImages = [];
			auto b = cast(ImageCell) itm.getData();
			if (!b) return;
			strs ~= _prop.msgs.imageNone;
			str = _prop.msgs.imageNone;
			bool def;
			string p = _comm.skin.findImagePathF(b.path, _summ ? _summ.scenarioPath : null, def);
			p = nabs(p);
			foreach (t; _comm.skin.tables(_prop.var.etc.logicalSort)) { mixin(S_TRACE);
				strs ~= t;
				if (cfnmatch(p, nabs(std.path.buildPath(_comm.skin.tableDir, t)))) { mixin(S_TRACE);
					str = t;
				}
			}
			_selectableBgImages = strs;
			if (!_summ) return;
			void recurse(string dir, string sDir) { mixin(S_TRACE);
				foreach (file; clistdir(dir)) { mixin(S_TRACE);
					if (containsPath(_prop.var.etc.ignorePaths, file)) continue;
					string full = std.path.buildPath(dir, file);
					string sFile = sDir ~ file;
					if (isDir(full)) { mixin(S_TRACE);
						recurse(full, sFile ~ std.path.dirSeparator);
					} else { mixin(S_TRACE);
						if (!_comm.skin.isBgImage(file)) continue;
						sFile = encodePath(sFile);
						strs ~= sFile;
						if (cfnmatch(p, nabs(full))) { mixin(S_TRACE);
							str = sFile;
						}
					}
				}
			}
			recurse(_summ.scenarioPath, std.path.dirSeparator);
			_selectableBgImages = strs;
		}
		string[] bgImageIncSearch(IncSearch incSearch) { mixin(S_TRACE);
			string[] r;
			r ~= _prop.msgs.imageNone;
			foreach (s; _selectableBgImages) { mixin(S_TRACE);
				if (incSearch.match(s)) { mixin(S_TRACE);
					r ~= s;
				}
			}
			return r;
		}
		bool isViewBacks() { mixin(S_TRACE);
			return _viewBacks;
		}
		void refreshTextCellF(Flag[] flags, Step[] steps) { mixin(S_TRACE);
			refreshTextCell();
		}
		void refreshTextCell() { mixin(S_TRACE);
			foreach (img; _imgp.images) { mixin(S_TRACE);
				if (img.type == ImageType.Text) { mixin(S_TRACE);
					img.createImage();
				}
			}
			_imgp.redraw();
		}
		string previewText(string base) { mixin(S_TRACE);
			string[char] names;
			string[string] flags;
			string[string] steps;
			getPreviewValues(_prop, _summ, SPCHAR_TEXT, names, flags, steps);
			return simpleFormatMsg(base, flags, steps, names);
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
	static if (UseCards) {
		@property
		bool isFixedCards() {return _fixedC;}
		@property
		bool spCustom() {return !_area.spAuto;}
	}
	static if (UseBacks) {
		@property
		bool isFixedCells() {return _fixedB;}
	}
	@property
	bool isShowGrid() {return _showGrid;}
	private void setupTLP(TopLevelPanel tlp) { mixin(S_TRACE);
		_tlp.putMenuChecked(MenuID.ShowParty, &reverseViewParty, &isViewParty, null);
		static if (UseCards && UseBacks) {
			_tlp.putMenuChecked(MenuID.ShowCard, &reverseViewCards, &isViewCards, null);
			_tlp.putMenuChecked(MenuID.ShowBack, &reverseViewBacks, &isViewBacks, null);
		}
		static if (UseCards) {
			_tlp.putMenuChecked(MenuID.AutoArrange, &setAuto, &_area.spAuto, null);
			_tlp.putMenuChecked(MenuID.ManualArrange, &setCustom, &spCustom, null);
			_tlp.putMenuChecked(MenuID.FixedCards, &reverseFixedCards, &isFixedCards, null);
		}
		static if (UseBacks) {
			_tlp.putMenuChecked(MenuID.FixedCells, &reverseFixedCells, &isFixedCells, null);
		}
		_tlp.putMenuChecked(MenuID.ShowGrid, &reverseShowGrid, &isShowGrid, null);
		_tlp.putMenuAction(MenuID.Refresh, &refresh, null);
		_tlp.putMenuAction(MenuID.Undo, &undo, &_undo.canUndo);
		_tlp.putMenuAction(MenuID.Redo, &redo, &_undo.canRedo);
		_tlp.putMenuAction(MenuID.Up, &up, &canUp);
		_tlp.putMenuAction(MenuID.Down, &down, &canDown);
	}

	/// メニューにAreaViewで使用するアイテムを設定する。
	/// Params:
	/// bar = メニュー。
	void setupMenu(Menu bar) { mixin(S_TRACE);
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
		static if (UseCards) {
			_vfcMenu = createMenuItem(_comm, mv, MenuID.FixedCards, &reverseFixedCards, null, SWT.CHECK);
			_vfcMenu.setSelection(_fixedC);
		}
		static if (UseBacks) {
			_vfbMenu = createMenuItem(_comm, mv, MenuID.FixedCells, &reverseFixedCells, null, SWT.CHECK);
			_vfbMenu.setSelection(_fixedB);
		}
		static if (is(C : EnemyCard) || RefCards) {
			if (_summ) { mixin(S_TRACE);
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
		_sgMenu = createMenuItem(_comm, mv, MenuID.ShowGrid, &reverseShowGrid, null, SWT.CHECK);
		_sgMenu.setSelection(_showGrid);
		new MenuItem(mv, SWT.SEPARATOR);
		static if (is (C == MenuCard)) {
			createMenuItem(_comm, mv, MenuID.NewMenuCard, &createCard, null);
		} else static if (is (C == EnemyCard)) {
			createMenuItem(_comm, mv, MenuID.NewEnemyCard, &createCard, null);
		}
		static if (UseBacks) {
			createMenuItem(_comm, mv, MenuID.NewBack, &createBackground, null);
			createMenuItem(_comm, mv, MenuID.NewTextCell, &createTextCell, null);
			createMenuItem(_comm, mv, MenuID.NewColorCell, &createColorCell, null);
		}
	}

	/// ツールバーにAreaViewで使用するアイテムを設定する。
	/// Params:
	/// bar = ツールバー。
	private void setupToolBar(ToolBar bar) { mixin(S_TRACE);
		static if (is(A : Area)) {
			if (cast(AreaSceneWindow) tlpData(this).tlp) { mixin(S_TRACE);
				createToolItem(_comm, bar, MenuID.EditEvent, &openEvent, null);
				new ToolItem(bar, SWT.SEPARATOR);
			}
		} else static if (is(A : Battle)) {
			if (cast(BattleSceneWindow) tlpData(this).tlp) { mixin(S_TRACE);
				auto itm = createToolItem(_comm, bar, MenuID.EditEvent, &openEvent, null);
				itm.setImage(_prop.images.editEventBattle);
				new ToolItem(bar, SWT.SEPARATOR);
			}
		}
		if (!_tlp) { mixin(S_TRACE);
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
		static if (is(C : EnemyCard) || RefCards) {
			if (_summ) { mixin(S_TRACE);
				new ToolItem(bar, SWT.SEPARATOR);
				_dbgTMenu = createToolItem(_comm, bar, MenuID.ShowEnemyCardProp, &reverseDebugMode, null, SWT.CHECK);
				_dbgTMenu.setSelection(_dbgMode);
			}
		}
		new ToolItem(bar, SWT.SEPARATOR);
		if (!_tlp) { mixin(S_TRACE);
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
			} else { mixin(S_TRACE);
				static assert (0);
			}
		}
		static if (UseBacks) {
			createToolItem(_comm, bar, MenuID.NewBack, &createBackground, null);
			createToolItem(_comm, bar, MenuID.NewTextCell, &createTextCell, null);
			createToolItem(_comm, bar, MenuID.NewColorCell, &createColorCell, null);
		}
		new ToolItem(bar, SWT.SEPARATOR);
		_xSpn = createSpinner(bar, _prop.msgs.left, _prop.var.etc.posLeftMax, -(cast(int) _prop.var.etc.posLeftMax), 0,
			&editSpn!("a.newX = value;"), &enterSpn!("a.x = value;", "a.newX = value;"),
			&cancelSpn!("a.x"));
		new ToolItem(bar, SWT.SEPARATOR);
		_ySpn = createSpinner(bar, _prop.msgs.top, _prop.var.etc.posTopMax, -(cast(int) _prop.var.etc.posTopMax), 0,
			&editSpn!("a.newY = value;"), &enterSpn!("a.y = value;", "a.newY = value;"),
			&cancelSpn!("a.y"));
		static if (UseBacks) {
			new ToolItem(bar, SWT.SEPARATOR);
			_wSpn = createSpinner(bar, _prop.msgs.width, _prop.var.etc.backWidthMax, 0, 0,
				&editSpnBack!("a.newWidth = value;"), &enterSpnBack!("a.width = value;", "a.newWidth = value;"),
				&cancelSpnBack!("a.width"));
			new ToolItem(bar, SWT.SEPARATOR);
			_hSpn = createSpinner(bar, _prop.msgs.height, _prop.var.etc.backHeightMax, 0, 0,
				&editSpnBack!("a.newHeight = value;"), &enterSpnBack!("a.height = value;", "a.newHeight = value;"),
				&cancelSpnBack!("a.height"));
		}
		static if (UseCards) {
			new ToolItem(bar, SWT.SEPARATOR);
			_scaleSpn = createSpinner(bar, _prop.msgs.scale, _prop.var.etc.cardScaleMax, _prop.var.etc.cardScaleMin, 100,
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
			_bgm = new MaterialSelect!(MtType.BGM, CCombo, CCombo)(_comm, _prop, _summ, false, &selectBGM, [_prop.msgs.bgmNone]);
			auto comp = new Composite(bar, SWT.NONE);
			comp.setLayout(zeroGridLayout(3, false));
			auto dirs = _bgm.createDirsCombo(comp);
			auto files = _bgm.createFileList(comp);
			auto playBar = new ToolBar(comp, SWT.FLAT);
			_bgm.createPlayToolItem(playBar);
			createToolItemC(bar, comp);
			_bgm.path = _area.music;
		}
		new ToolItem(bar, SWT.SEPARATOR);
		_sgTMenu = createToolItem(_comm, bar, MenuID.ShowGrid, &reverseShowGrid, null, SWT.CHECK);
		_sgTMenu.setSelection(_showGrid);
		new ToolItem(bar, SWT.SEPARATOR);
		createLabel(bar, _prop.msgs.left ~ ":");
		auto gridX = new Spinner(bar, SWT.BORDER);
		initSpinner(gridX);
		gridX.setMaximum(_prop.looks.viewSize.width);
		gridX.setMinimum(1);
		gridX.setSelection(_gridX);
		.listener(gridX, SWT.Selection, { mixin(S_TRACE);
			_gridX = gridX.getSelection();
			refreshGrid();
		});
		createToolItemC(bar, gridX);
		new ToolItem(bar, SWT.SEPARATOR);
		createLabel(bar, _prop.msgs.top ~ ":");
		auto gridY = new Spinner(bar, SWT.BORDER);
		initSpinner(gridY);
		gridY.setMaximum(_prop.looks.viewSize.height);
		gridY.setMinimum(1);
		gridY.setSelection(_gridY);
		.listener(gridY, SWT.Selection, { mixin(S_TRACE);
			_gridY = gridY.getSelection();
			refreshGrid();
		});
		createToolItemC(bar, gridY);
	}
	private class FlagsDispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.refFlagAndStep.remove(&refFlag);
			_comm.delFlagAndStep.remove(&refFlag);
		}
	}
	private class SelFlag : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			int index = _flag.getSelectionIndex();
			string flag = index <= 0 ? "" : _flag.getText();
			auto undo = createUndoEdit();
			bool chg = false;
			static if (UseCards) {
				foreach (c, i; _editC) { mixin(S_TRACE);
					if (c.flag != flag) { mixin(S_TRACE);
						c.flag = flag;
						_cards.getItem(i).setImage(cardImg(c));
						chg = true;
					}
				}
			}
			static if (UseBacks) {
				foreach (b, i; _editB) { mixin(S_TRACE);
					if (b.flag != flag) { mixin(S_TRACE);
						b.flag = flag;
						_backs.getItem(i).setImage(backImg(b));
						chg = true;
					}
				}
			}
			_undo ~= undo;
			refreshStatusLine();
			_comm.refUseCount.call();
			refreshFlags();
		}
	}
	private void refFlag(Flag[] flag, Step[] step) { mixin(S_TRACE);
		if (!flag.length) return;
		refreshFlag();
	}
	private void refreshFlag() { mixin(S_TRACE);
		if (!_flag) return;
		string f = _flag.getText();
		_flag.removeAll();
		_flag.add(_prop.msgs.noFlagRef);
		_flag.select(0);
		foreach (i, fl; _summ.flagDirRoot.allFlags) { mixin(S_TRACE);
			auto path = fl.path;
			if (!_flagIncSearch.match(path)) continue;
			_flag.add(path);
			if (path == f) _flag.setText(path);
		}
	}

	void reverseViewParty() { mixin(S_TRACE);
		_viewParty = !_viewParty;
		int imgLen = _imgp.images.length;
		int partyLen = _prop.looks.partyCardXY.length;
		for (int i = imgLen - 2; i >= imgLen - partyLen - 1; i--) { mixin(S_TRACE);
			_imgp.images[i].visible = _viewParty;
		}
		if (_vpMenu) _vpMenu.setSelection(_viewParty);
		if (_vpTMenu) _vpTMenu.setSelection(_viewParty);
		_imgp.redraw();
	}
	void reverseViewMsg() { mixin(S_TRACE);
		_viewMsg = !_viewMsg;
		_imgp.images[$ - 1].visible = _viewMsg;
		if (_vmMenu) _vmMenu.setSelection(_viewMsg);
		if (_vmTMenu) _vmTMenu.setSelection(_viewMsg);
		_imgp.redraw();
	}
	static if (RefCards) {
		void reverseViewRefCards() { mixin(S_TRACE);
			_imgp.showAppends = !_imgp.showAppends;
			if (_vrMenu) _vrMenu.setSelection(_imgp.showAppends);
			if (_vrTMenu) _vrTMenu.setSelection(_imgp.showAppends);
			_imgp.redraw();
		}
	}
	static if (UseCards) {
		void reverseFixedCards() { mixin(S_TRACE);
			_fixedC = !_fixedC;
			_imgp.fixedRange(_fixedC, cardsIndex, cardsIndex + _area.cards.length);
			if (_vfcMenu) _vfcMenu.setSelection(_fixedC);
			if (_vfcTMenu) _vfcTMenu.setSelection(_fixedC);
			_imgp.redraw();
		}
	}
	static if (UseBacks) {
		void reverseFixedCells() { mixin(S_TRACE);
			_fixedB = !_fixedB;
			_imgp.fixedRange(_fixedB, 0, _area.backs.length);
			if (_vfbMenu) _vfbMenu.setSelection(_fixedB);
			if (_vfbTMenu) _vfbTMenu.setSelection(_fixedB);
			_imgp.redraw();
		}
	}
	void reverseShowGrid() { mixin(S_TRACE);
		_showGrid = !_showGrid;
		refreshGrid();
		if (_sgMenu) _sgMenu.setSelection(_showGrid);
		if (_sgTMenu) _sgTMenu.setSelection(_showGrid);
		if (_sgPMenu) _sgPMenu.setSelection(_showGrid);
		_imgp.redraw();
	}
	void refreshGrid() { mixin(S_TRACE);
		_imgp.gridX = _showGrid ? _gridX : 0;
		_imgp.gridY = _showGrid ? _gridY : 0;
	}
	private int insertIndex(Table list) { mixin(S_TRACE);
		int[] indices = list.getSelectionIndices().sort;
		return indices.length ? indices[$ - 1] + 1 : list.getItemCount();
	}
	static if (UseCards) {
		/// カードを追加する。
		/// Params:
		/// card = カード。
		/// select = 選択状態にするか。
		/// refresh = 表示を更新するか。
		private int appendCard(C card, bool select, bool refresh, bool fromImgPane) { mixin(S_TRACE);
			int index = fromImgPane ? _area.cards.length : insertIndex(_cards);
			appendCard(index, card, select, refresh);
			return index;
		}
		/// ditto
		private void appendCard(int index, C card, bool select, bool refresh, bool check = true) { mixin(S_TRACE);
			appendCardImpl(this, _comm, _area, index, card, select, refresh, check);
		}
		/// ditto
		private static void appendCardImpl(AbstractAreaView v, Commons comm, A area, int index, C card, bool select, bool refresh, bool check = true) { mixin(S_TRACE);
			area.insert(index, card);
			if (v) { mixin(S_TRACE);
				auto img = v.create(card);
				v._imgp.deselectAll();
				v._imgp.insert(v.cardsIndex + index, img);
				v._imgp.images[v.cardsIndex + index].visible = check;
				auto itm = new TableItem(v._cards, SWT.NONE, index);
				itm.setImage(v.cardImg(card));
				itm.setData(card);
				itm.setChecked(check);
				itm.setText(v.cardName(card));
				if (select && v._viewCards) { mixin(S_TRACE);
					v._imgp.select(img);
					if (refresh) { mixin(S_TRACE);
						v.refreshSelected();
					}
				}
				v._imgp.redraw();
			}
			comm.addMenuCard.call(card.cwxPath(true));
			comm.refUseCount.call();
			if (v) { mixin(S_TRACE);
				v.refreshFlags();
				v.callModEvent();
			}
		}
		private FlexImage create(C card) { mixin(S_TRACE);
			auto img = createCardImage!FlexImage(card, _prop.var.etc.smoothingCard);
			_cardTbl[img] = card;
			img.visible = isViewCards;
			img.fixed = isFixedCards;
			img.addSelectionListener(&selectImageC);
			img.addResizeListener(&resizeImageC);
			return img;
		}
		private void appendCards(int index, C[] cards, bool select, bool raiseEvent) { mixin(S_TRACE);
			FlexImage[] imgs;
			foreach (i, card; cards) { mixin(S_TRACE);
				auto img = create(card);
				imgs ~= img;
				if (raiseEvent) _comm.addMenuCard.call(card.cwxPath(true));
			}
			_imgp.insert(cardsIndex + index, cast(PileImage[]) imgs);
			foreach (i, c; cards) { mixin(S_TRACE);
				auto itm = new TableItem(_cards, SWT.NONE, index + i);
				itm.setImage(cardImg(c));
				itm.setData(c);
				itm.setChecked(true);
				itm.setText(cardName(c));
			}
			if (select && _viewCards) _imgp.select(imgs);
			callModEvent();
		}
		static if (is (C == MenuCard)) {
			private int cardFromFile(string fname, int x, int y, bool fromImgPane) { mixin(S_TRACE);
				if (!_summ) return -1;
				if (!hasPath(_summ.scenarioPath, fname)) { mixin(S_TRACE);
					auto dlg = new MessageBox(getShell(), SWT.ICON_QUESTION | SWT.YES | SWT.NO | SWT.CANCEL);
					dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDropCard, fname));
					dlg.setText(_prop.msgs.dlgTitDropCard);
					auto ret = dlg.open();
					if (SWT.YES == ret) { mixin(S_TRACE);
						fname = copyTo(_summ.scenarioPath, fname, _comm.skin.materialPath, false);
					} else if (SWT.CANCEL == ret) { mixin(S_TRACE);
						return -1;
					}
				}
				auto card = new MenuCard(baseName(.stripExtension(fname)), fname, "", "", x, y, 1.0);
				return appendCard(card, true, true, fromImgPane);
			}
			private class CLDropTarget : DropTargetAdapter {
				override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
					e.detail = _summ ? DND.DROP_LINK : DND.DROP_NONE;
				}
				private int[] addC;
				override void drop(DropTargetEvent e) { mixin(S_TRACE);
					assert (_summ);
					scope (exit) addC = [];
					auto arr = cast(FileNames) e.data;
					if (arr) { mixin(S_TRACE);
						foreach (fname; arr.array) { mixin(S_TRACE);
							try { mixin(S_TRACE);
								if (!doFile(fname)) { mixin(S_TRACE);
									break;
								}
							} catch (SWTException e) {
								debugln(e);
							}
						}
						if (addC.length) { mixin(S_TRACE);
							auto undo = new UndoInsert(this.outer, _comm, _area, _summ, addC, []);
							_comm.refPaths.call(_comm.skin.materialPath);
						}
						_comm.refreshToolBar();
						return;
					} else if (isXMLBytes(e.data)) { mixin(S_TRACE);
						int[] ci, bi;
						auto ctrl = (cast(DropTarget) e.getSource()).getControl();
						auto p = ctrl.toControl(e.x, e.y);
						appendFromXML(bytesToXML(e.data), p.x, p.y, DropTarg.Card, ci, bi);
						if (ci.length || bi.length) { mixin(S_TRACE);
							_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, ci, bi);
						}
						_comm.refreshToolBar();
					}
				}
				private bool doFile(string path) { mixin(S_TRACE);
					assert (_summ);
					if (_comm.skin.isCardImage(path, true)) { mixin(S_TRACE);
						int i = cardFromFile(path, 0, 0, false);
						if (i == -1) { mixin(S_TRACE);
							return false;
						} else { mixin(S_TRACE);
							addC ~= i;
						}
					}
					return true;
				}
			}
		}
		class CardDrag : DragSourceAdapter {
			override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
				e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl();
			}
			override void dragSetData(DragSourceEvent e){ mixin(S_TRACE);
				if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
					auto tbl = cast(Table) (cast(DragSource) e.getSource()).getControl();
					auto sel = tbl.getSelectionIndex();
					auto curItm = sel != -1 ? tbl.getItem(sel) : null;
					C[] cs;
					foreach (itm; tbl.getSelection()) { mixin(S_TRACE);
						cs ~= cast(C) itm.getData();
					}
					auto node = A.CtoNode(cs, new XMLOption(_prop.sys));
					node.newAttr("paneId", _id);
					if (curItm) node.newAttr("cursorIndex", tbl.indexOf(curItm));
					e.data = bytesFromXML(node.text);
				}
			}
			override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
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
		private int appendBgImage(BgImage back, bool select, bool refresh, bool fromImgPane) { mixin(S_TRACE);
			int index = fromImgPane ? _area.backs.length : insertIndex(_backs);
			appendBgImage(index, back, select, refresh);
			return index;
		}
		/// ditto
		private void appendBgImage(int index, BgImage back, bool select, bool refresh, bool check = true) { mixin(S_TRACE);
			appendBgImageImpl(this, _comm, _area, index, back, select, refresh, check);
		}
		/// ditto
		private static void appendBgImageImpl(AbstractAreaView v, Commons comm, A area, int index, BgImage back, bool select, bool refresh, bool check = true) { mixin(S_TRACE);
			area.insert(index, back);
			if (v) { mixin(S_TRACE);
				v._imgp.deselectAll();
				auto img = v.create(back);
				v._imgp.insert(index, img);
				v._imgp.images[index].visible = check;
				auto itm = new TableItem(v._backs, SWT.NONE, index);
				itm.setImage(v.backImg(back));
				itm.setData(back);
				itm.setChecked(check);
				itm.setText(back.name);
				if (select && v._viewBacks) { mixin(S_TRACE);
					v._imgp.select(img);
					if (refresh) { mixin(S_TRACE);
						v.refreshSelected();
					}
				}
				v._imgp.redraw();
			}
			comm.addBgImage.call(back.cwxPath(true));
			comm.refUseCount.call();
			if (v) { mixin(S_TRACE);
				v.refreshFlags();
				v.callModEvent();
			}
		}
		private FlexImage create(BgImage back) { mixin(S_TRACE);
			FlexImage img = null;
			auto ic = cast(ImageCell) back;
			if (ic) img = create(ic);
			auto tc = cast(TextCell) back;
			if (tc) img = create(tc);
			auto cc = cast(ColorCell) back;
			if (cc) img = create(cc);
			assert (img !is null);
			_backTbl[img] = back;
			img.visible = _viewBacks;
			img.fixed = isFixedCells;
			img.addSelectionListener(&selectImageB);
			img.addResizeListener(&resizeImageB);
			return img;
		}
		private FlexImage create(ImageCell back) { mixin(S_TRACE);
			auto skin = _comm.skin;
			auto path = skin.findImagePath(back.path, _summ ? _summ.scenarioPath : "");
			return createBackgroundImage
				(_prop, skin, _summ, path, back.x, back.y, back.width, back.height, back.mask);
		}
		private FlexImage create(TextCell back) { mixin(S_TRACE);
			auto r = new FlexImage(back.text, back.fontName, back.size, back.color,
				back.bold, back.italic, back.underline, back.strike, back.vertical,
				back.borderingType, back.borderingColor, back.borderingWidth,
				back.x, back.y, back.width, back.height);
			r.transparent = back.mask;
			r.previewText = &previewText;
			r.createImage();
			return r;
		}
		private FlexImage create(ColorCell back) { mixin(S_TRACE);
			auto r = new FlexImage(back.blendMode, back.gradientDir, back.color1, back.color2,
				back.x, back.y, back.width, back.height);
			r.transparent = back.mask;
			return r;
		}
		private void appendBgImages(int index, BgImage[] backs, bool select, bool raiseEvent) { mixin(S_TRACE);
			FlexImage[] imgs;
			foreach (back; backs) { mixin(S_TRACE);
				imgs ~= create(back);
			}
			_imgp.insert(index, cast(PileImage[]) imgs);
			foreach (i, b; backs) { mixin(S_TRACE);
				auto itm = new TableItem(_backs, SWT.NONE, index + i);
				itm.setImage(backImg(b));
				itm.setData(b);
				itm.setChecked(true);
				itm.setText(b.name);
				if (raiseEvent) _comm.addBgImage.call(b.cwxPath(true));
			}
			if (select && _viewBacks) _imgp.select(imgs);
			callModEvent();
		}
		private int backFromFile(string fname, int x, int y, int w, int h, bool fromImgPane) { mixin(S_TRACE);
			if (!_summ) return -1;
			if (!hasPath(_summ.scenarioPath, fname)) { mixin(S_TRACE);
				auto dlg = new MessageBox(getShell(), SWT.ICON_QUESTION | SWT.YES | SWT.NO | SWT.CANCEL);
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDropBack, fname));
				dlg.setText(_prop.msgs.dlgTitDropBack);
				auto ret = dlg.open();
				if (SWT.YES == ret) { mixin(S_TRACE);
					fname = copyTo(_summ.scenarioPath, fname, _comm.skin.materialPath, false);
				} else if (SWT.CANCEL == ret) { mixin(S_TRACE);
					return -1;
				}
			}
			auto back = new ImageCell(fname, "", x, y, w, h, false);
			return appendBgImage(back, true, true, fromImgPane);
		}
		private class BLDropTarget : DropTargetAdapter {
			private int[] addB;
			override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
				e.detail = DND.DROP_LINK;
			}
			override void drop(DropTargetEvent e) { mixin(S_TRACE);
				assert (_summ);
				scope (exit) addB = [];
				auto arr = cast(FileNames) e.data;
				if (arr) { mixin(S_TRACE);
					foreach (fname; arr.array) { mixin(S_TRACE);
						try { mixin(S_TRACE);
							if (!doFile(fname)) { mixin(S_TRACE);
								break;
							}
						} catch (SWTException e) {
							debugln(e);
						}
					}
					if (addB.length) { mixin(S_TRACE);
						auto undo = new UndoInsert(this.outer, _comm, _area, _summ, [], addB);
						_comm.refPaths.call(_comm.skin.materialPath);
					}
					_comm.refreshToolBar();
					return;
				} else if (isXMLBytes(e.data)) { mixin(S_TRACE);
					int[] ci, bi;
					auto ctrl = (cast(DropTarget) e.getSource()).getControl();
					auto p = ctrl.toControl(e.x, e.y);
					appendFromXML(bytesToXML(e.data), p.x, p.y, DropTarg.Back, ci, bi);
					if (ci.length || bi.length) { mixin(S_TRACE);
						_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, ci, bi);
					}
					_comm.refreshToolBar();
				}
			}
			private bool doFile(string path) { mixin(S_TRACE);
				assert (_summ);
				auto img = loadBgImage(_prop, _comm.skin, _summ, path);
				if (img) { mixin(S_TRACE);
					int i = backFromFile(path, 0, 0, img.width, img.height, false);
					if (i >= 0) { mixin(S_TRACE);
						addB ~= i;
						return true;
					}
				}
				return false;
			}
		}
		class BackDrag : DragSourceAdapter {
			override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
				e.doit = (cast(DragSource) e.getSource()).getControl().isFocusControl();
			}
			override void dragSetData(DragSourceEvent e){ mixin(S_TRACE);
				if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
					auto tbl = cast(Table) (cast(DragSource) e.getSource()).getControl();
					auto sel = tbl.getSelectionIndex();
					auto curItm = sel != -1 ? tbl.getItem(sel) : null;
					BgImage[] bs;
					foreach (itm; tbl.getSelection()) { mixin(S_TRACE);
						bs ~= cast(BgImage) itm.getData();
					}
					auto node = Area.BtoNode(bs, new XMLOption(_prop.sys));
					node.newAttr("paneId", _id);
					if (curItm) node.newAttr("cursorIndex", tbl.indexOf(curItm));
					e.data = bytesFromXML(node.text);
				}
			}
			override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
				// Nothing
			}
		}
	}

	private void moveItems(Table list, int fromIndex, int toIndex) { mixin(S_TRACE);
		if (fromIndex < 0 || list.getItemCount() <= fromIndex) return;
		if (fromIndex == toIndex) return;
		bool cards = false;
		bool backs = false;
		static if (UseCards) cards = list is _cards;
		static if (UseBacks) backs = list is _backs;
		if (fromIndex < toIndex) { mixin(S_TRACE);
			down(toIndex - fromIndex, cards, backs);
		} else if (fromIndex > toIndex) { mixin(S_TRACE);
			up(fromIndex - toIndex, cards, backs);
		}
	}
	private void appendFromXML(string xml, int x, int y, DropTarg dTarg, out int[] ci, out int[] bi) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			bool toImgp = dTarg is DropTarg.ImagePane;
			auto node = XNode.parse(xml);
			int ptoi(Table list) { mixin(S_TRACE);
				auto itm = list.getItem(new Point(x, y));
				if (itm) { mixin(S_TRACE);
					return list.indexOf(itm);
				} else { mixin(S_TRACE);
					return list.getItemCount();
				}
			}

			MenuCard[] mcs;
			BgImage[] bs;
			auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
			if (Area.CBfromXML(node, mcs, bs, ver)) { mixin(S_TRACE);
				if (!mcs.length && !bs.length) return;
				if (toImgp) { mixin(S_TRACE);
					if (_id == node.attr("paneId", false)) return;
					static if (is(C : MenuCard)) {
						foreach (card; mcs) { mixin(S_TRACE);
							ci ~= appendCard(card, true, true, toImgp);
						}
					}
					static if (UseBacks) {
						foreach (back; bs) { mixin(S_TRACE);
							bi ~= appendBgImage(back, true, true, toImgp);
						}
					}
					_comm.refUseCount.call();
					refreshFlags();
					_comm.refreshToolBar();
					return;
				}
				static if (is(C : MenuCard)) {
					if (DropTarg.Card is dTarg && mcs.length) { mixin(S_TRACE);
						if (_id == node.attr("paneId", false)) { mixin(S_TRACE);
							moveItems(_cards, node.attr("cursorIndex", false, -1), ptoi(_cards));
							return;
						}
						int si = ptoi(_cards);
						foreach (i, card; mcs) { mixin(S_TRACE);
							appendCard(si + i, card, true, true);
							ci ~= si + i;
						}
						_comm.refUseCount.call();
						refreshFlags();
						_comm.refreshToolBar();
						return;
					}
				}
				static if (UseBacks) {
					if (DropTarg.Back is dTarg && bs.length) { mixin(S_TRACE);
						if (_id == node.attr("paneId", false)) { mixin(S_TRACE);
							moveItems(_backs, node.attr("cursorIndex", false, -1), ptoi(_backs));
							return;
						}
						int si = ptoi(_backs);
						foreach (i, back; bs) { mixin(S_TRACE);
							appendBgImage(si + i, back, true, true);
							bi ~= si + i;
						}
						_comm.refUseCount.call();
						refreshFlags();
						_comm.refreshToolBar();
						return;
					}
				}
				return;
			}
			static if (is(C : EnemyCard)) {
				EnemyCard[] ecs;
				if (Battle.CfromXML(node, ecs, ver)) { mixin(S_TRACE);
					if (!ecs.length) return;
					if (toImgp) { mixin(S_TRACE);
						if (_id == node.attr("paneId", false)) return;
						foreach (card; ecs) { mixin(S_TRACE);
							ci ~= appendCard(card, true, true, toImgp);
						}
						_comm.refUseCount.call();
						refreshFlags();
						_comm.refreshToolBar();
						return;
					}
					if (DropTarg.Card is dTarg && ecs.length) { mixin(S_TRACE);
						if (_id == node.attr("paneId", false)) { mixin(S_TRACE);
							moveItems(_cards, node.attr("cursorIndex", false, -1), ptoi(_cards));
							return;
						}
						int si = ptoi(_cards);
						foreach (i, card; ecs) { mixin(S_TRACE);
							appendCard(si + i, card, true, true);
							ci ~= si + i;
						}
						_comm.refUseCount.call();
						refreshFlags();
						_comm.refreshToolBar();
						return;
					}
					return;
				}
			}

			static if (is(A : Battle) && is(C : EnemyCard)) {
				if (node.name == CastCard.XML_NAME_M) { mixin(S_TRACE);
					// キャストカードからのエネミーカード生成
					if (summary.id != node.attr("summId", false)) return;
					auto cards = EnemyCard.createCardsFromNode(node, ver);
					if (cards.length) { mixin(S_TRACE);
						int cx = 0;
						int cy = 0;
						if (toImgp) { mixin(S_TRACE);
							auto s = _prop.looks.cardSize;
							auto ins = _prop.looks.castCardInsets;
							cx = x - cast(int) (s.width + ins.e + ins.w) / 2;
							cy = y - cast(int) (s.height + ins.n + ins.s) / 2;
						}
						foreach (i, card; cards) { mixin(S_TRACE);
							assert (card.scale == 1.0);
							card.x = cx;
							card.y = cy;
							ci ~= appendCard(card, true, true, toImgp);
						}
						_comm.refUseCount.call();
						refreshFlags();
						_comm.refreshToolBar();
					}
					return;
				}
			}

			static if (is(C : MenuCard)) {
				// その他カードからのメニューカード生成
				auto cards = MenuCard.createFromCardNode(node, _prop.var.etc.copyDesc, ver);
				// x, y座標を中心にして配置
				int cx = 0;
				int cy = 0;
				if (toImgp) { mixin(S_TRACE);
					auto s = _prop.looks.cardSize;
					auto ins = _prop.looks.menuCardInsets;
					cx = x - cast(int) (s.width + ins.e + ins.w) / 2;
					cy = y - cast(int) (s.height + ins.n + ins.s) / 2;
				}
				foreach (card; cards) { mixin(S_TRACE);
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
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = _summ ? DND.DROP_LINK : DND.DROP_NONE;
		}
		private int[] addC;
		private int[] addB;
		override void drop(DropTargetEvent e) { mixin(S_TRACE);
			assert (_summ);
			scope (exit) addC = [];
			scope (exit) addB = [];
			auto arr = cast(FileNames) e.data;
			if (arr) { mixin(S_TRACE);
				int append = 0;
				foreach (fname; arr.array) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						scope p = _imgp.toControl(e.x, e.y);
						if (!doFile(fname, p.x, p.y)) { mixin(S_TRACE);
							break;
						}
						append++;
					} catch (SWTException e) {
						debugln(e);
					}
				}
				if (append > 0) { mixin(S_TRACE);
					_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, addC, addB);
					_comm.refPaths.call(_comm.skin.materialPath);
					_comm.refreshToolBar();
				}
				return;
			}
			if (isXMLBytes(e.data)) { mixin(S_TRACE);
				scope p = _imgp.toControl(e.x, e.y);
				int[] ci, bi;
				appendFromXML(bytesToXML(e.data), p.x, p.y, DropTarg.ImagePane, ci, bi);
				if (ci.length || bi.length) { mixin(S_TRACE);
					_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, ci, bi);
					_comm.refreshToolBar();
				}
			}
		}
		private bool doFile(string path, int x, int y) { mixin(S_TRACE);
			assert (_summ);
			auto skin = _comm.skin;
			static if ((UseCards && is (C == MenuCard)) && UseBacks) {
				if (skin.isCardImage(path, false)) { mixin(S_TRACE);
					int i = cardFromFile(path, x, y, true);
					if (i == -1) { mixin(S_TRACE);
						return false;
					} else { mixin(S_TRACE);
						addC ~= i;
					}
				} else { mixin(S_TRACE);
					auto img = loadBgImage(_prop, skin, _summ, path);
					if (img) { mixin(S_TRACE);
						int i = backFromFile(path, x, y, img.width, img.height, true);
						if (i == -1) { mixin(S_TRACE);
							return false;
						} else { mixin(S_TRACE);
							addB ~= i;
						}
					}
				}
			} else static if (UseCards && is (C == MenuCard)) {
				if (skin.isCardImage(path, true)) { mixin(S_TRACE);
					int i = cardFromFile(path, x, y, true);
					if (i == -1) { mixin(S_TRACE);
						return false;
					} else { mixin(S_TRACE);
						addC ~= i;
					}
				}
			} else static if (UseBacks) {
				auto img = loadBgImage(_prop, skin, _summ, path);
				if (img) { mixin(S_TRACE);
					int i = backFromFile(path, x, y, img.width, img.height, true);
					if (i == -1) { mixin(S_TRACE);
						return false;
					} else { mixin(S_TRACE);
						addB ~= i;
					}
				}
			}
			_comm.refreshToolBar();
			return true;
		}
	}

	static if (is (C == EnemyCard)) {
		private void __refreshCast(CastCard castCard) { mixin(S_TRACE);
			auto skin = _comm.skin;
			foreach (i, c; area.cards) { mixin(S_TRACE);
				if (castCard.id == _area.cards[i].id) { mixin(S_TRACE);
					auto img = imagePane.images[cardsIndex + i];
					img.setImageData(castCardImage(_prop, skin, castCard, _summ ? _summ.scenarioPath : "", _dbgMode));
					img.createImage();
					if (cardList.getItem(i).getText() != castCard.name) { mixin(S_TRACE);
						cardList.getItem(i).setText(castCard.name);
						_comm.refMenuCard.call(_area.cards[i].cwxPath(true));
					}
				}
			}
			imagePane.redraw();
		}
		private void __deleteCast(CastCard castCard) { mixin(S_TRACE);
			auto skin = _comm.skin;
			foreach (i, c; area.cards) { mixin(S_TRACE);
				if (castCard.id == c.id) { mixin(S_TRACE);
					auto img = imagePane.images[cardsIndex + i];
					img.setImageData(.castCard(skin));
					img.createImage();
					cardList.getItem(i).setText("");
				}
			}
			imagePane.redraw();
		}
	} else static if (RefCards) {
		private void __refreshCast(CastCard castCard) { mixin(S_TRACE);
			refreshPanel();
		}
		private void __deleteCast(CastCard castCard) { mixin(S_TRACE);
			refreshPanel();
		}
	}
	static if (is(A : Battle) && is(C : EnemyCard)) {
		class DTListener : DropTargetAdapter {
			override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
				e.detail = DND.DROP_LINK;
			}
			override void drop(DropTargetEvent e) { mixin(S_TRACE);
				if (isXMLBytes(e.data)) { mixin(S_TRACE);
					auto arr = bytesToXML(e.data);
					auto ctrl = (cast(DropTarget) e.getSource()).getControl();
					auto p = ctrl.toControl(e.x, e.y);
					auto imgp = cast(ImagePane) ctrl;
					int[] ci, bi;
					appendFromXML(arr, p.x, p.y, imgp ? DropTarg.ImagePane : DropTarg.Card, ci, bi);
					if (ci.length || bi.length) { mixin(S_TRACE);
						_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, ci, bi);
						_comm.refreshToolBar();
					}
				}
			}
		}
	}
	void cut(SelectionEvent se) { mixin(S_TRACE);
		int[] cs;
		int[] bs;
		static if (UseCards) cs = _cards.getSelectionIndices();
		static if (UseBacks) bs = _backs.getSelectionIndices();
		_undo ~= new UndoDelete(this, _comm, _area, _summ, cs, bs);
		_tcpd.cut(se);
	}
	void copy(SelectionEvent se) { mixin(S_TRACE);
		_tcpd.copy(se);
	}
	void paste(SelectionEvent se) { mixin(S_TRACE);
		_tcpd.paste(se);
	}
	void del(SelectionEvent se) { mixin(S_TRACE);
		int[] cs;
		int[] bs;
		static if (UseCards) cs = _cards.getSelectionIndices();
		static if (UseBacks) bs = _backs.getSelectionIndices();
		_undo ~= new UndoDelete(this, _comm, _area, _summ, cs, bs);
		delImpl();
	}
	private void delImpl() { mixin(S_TRACE);
		_tcpd.del(null);
	}
	void clone(SelectionEvent se) { mixin(S_TRACE);
		_tcpd.clone(se);
	}
	private static void delImpl2(AbstractAreaView v, Commons comm, A area, int[] cIdcs, int[] bIdcs, bool store) { mixin(S_TRACE);
		if (store && v) v._undo ~= new UndoDelete(v, comm, area, comm.summary, cIdcs, bIdcs);
		static if (UseCards) {
			foreach_reverse (i; cIdcs.sort) { mixin(S_TRACE);
				if (v) { mixin(S_TRACE);
					removeCard(v, comm, area, v._cardTbl, i);
				} else { mixin(S_TRACE);
					C[PileImage] empty;
					removeCard(v, comm, area, empty, i);
				}
				area.removeCard(i);
				if (v) v._cards.remove(i);
			}
		}
		static if (UseBacks) {
			foreach_reverse (i; bIdcs.sort) { mixin(S_TRACE);
				if (v) { mixin(S_TRACE);
					removeBack(v, comm, area, v._backTbl, i);
				} else { mixin(S_TRACE);
					BgImage[PileImage] empty;
					removeBack(v, comm, area, empty, i);
				}
				area.removeBgImage(i);
				if (v) v._backs.remove(i);
			}
		}
		if (v) { mixin(S_TRACE);
			v._imgp.redraw();
			v.refreshSelected();
			v.refreshFlags();
		}
		comm.refUseCount.call();
	}
	@property
	bool canDoTCPD() { mixin(S_TRACE);
		return _imgp.isVisible();
	}
	@property
	bool canDoT() { mixin(S_TRACE);
		return _imgp.selectedIndex != -1;
	}
	@property
	bool canDoC() { mixin(S_TRACE);
		return _imgp.selectedIndex != -1;
	}
	@property
	bool canDoP() { mixin(S_TRACE);
		return CBisXML(_comm.clipboard);
	}
	@property
	bool canDoD() { mixin(S_TRACE);
		return _imgp.selectedIndex != -1;
	}
	@property
	bool canDoClone() { mixin(S_TRACE);
		return canDoC;
	}
	static if (UseCards && UseBacks) {
		private class AllTCPD : TCPD {
			void cut(SelectionEvent se) { mixin(S_TRACE);
				copy(se);
				del(se);
			}
			void copy(SelectionEvent se) { mixin(S_TRACE);
				scope MenuCard[] cards;
				foreach (i; _cards.getSelectionIndices()) { mixin(S_TRACE);
					cards ~= _area.cards[i];
				}
				scope BgImage[] backs;
				foreach (i; _backs.getSelectionIndices()) { mixin(S_TRACE);
					backs ~= _area.backs[i];
				}
				if (cards.length > 0 || backs.length > 0) { mixin(S_TRACE);
					XMLtoCB(_prop, _comm.clipboard, Area.CBtoXML(cards, backs, new XMLOption(_prop.sys)));
					_comm.refreshToolBar();
				}
			}
			void paste(SelectionEvent se) { mixin(S_TRACE);
				auto xml = CBtoXML(_comm.clipboard);
				if (xml) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						C[] cs;
						BgImage[] bs;
						auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
						A.CBfromXML(xml, cs, bs, ver);
						if (cs.length || bs.length) { mixin(S_TRACE);
							_imgp.deselectAll();
							int[] addC, addB;
							auto iib = insertIndex(_backs);
							foreach (i, b; bs) { mixin(S_TRACE);
								int index = iib + i;
								addB ~= index;
								_area.insert(index, b);
							}
							appendBgImages(iib, bs, true, true);
							auto iic = insertIndex(_cards);
							foreach (i, c; cs) { mixin(S_TRACE);
								int index = iic + i;
								addC ~= index;
								_area.insert(index, c);
							}
							appendCards(iic, cs, true, true);
							if (_viewCards || _viewBacks) _imgp.redraw();
							refreshSelected();
							_comm.refUseCount.call();
							refreshFlags();
							_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, addC, addB);
							_comm.refreshToolBar();
						}
					} catch (Exception e) {
						debugln(e);
					}
				}
			}
			void del(SelectionEvent se) { mixin(S_TRACE);
				delImpl2(this.outer, _comm, _area, _cards.getSelectionIndices(), _backs.getSelectionIndices(), true);
				_comm.refreshToolBar();
			}
			void clone(SelectionEvent se) { mixin(S_TRACE);
				_comm.clipboard.memoryMode = true;
				scope (exit) _comm.clipboard.memoryMode = false;
				copy(se);
				paste(se);
			}
			@property
			bool canDoTCPD() { mixin(S_TRACE);
				return _imgp.isVisible();
			}
			@property
			bool canDoT() { mixin(S_TRACE);
				return _imgp.selectedIndex != -1;
			}
			@property
			bool canDoC() { mixin(S_TRACE);
				return _imgp.selectedIndex != -1;
			}
			@property
			bool canDoP() { mixin(S_TRACE);
				return CBisXML(_comm.clipboard);
			}
			@property
			bool canDoD() { mixin(S_TRACE);
				return _imgp.selectedIndex != -1;
			}
			@property
			bool canDoClone() { mixin(S_TRACE);
				return canDoC;
			}
		}
	}

	static if (UseCards) {
		private class CardTCPD : TCPD {
			void cut(SelectionEvent se) { mixin(S_TRACE);
				copy(se);
				del(se);
			}
			void copy(SelectionEvent se) { mixin(S_TRACE);
				scope C[] cards;
				foreach (i; _cards.getSelectionIndices()) { mixin(S_TRACE);
					cards ~= _area.cards[i];
				}
				if (cards.length > 0) { mixin(S_TRACE);
					XMLtoCB(_prop, _comm.clipboard, A.CtoXML(cards, new XMLOption(_prop.sys)));
					_comm.refreshToolBar();
				}
			}
			void paste(SelectionEvent se) { mixin(S_TRACE);
				static if (UseBacks) {
					this.outer.paste(se);
				} else { mixin(S_TRACE);
					auto xml = CBtoXML(_comm.clipboard);
					if (xml) { mixin(S_TRACE);
						try { mixin(S_TRACE);
							C[] cs;
							auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
							A.CfromXML(xml, cs, ver);
							if (cs.length) { mixin(S_TRACE);
								int[] addC;
								_imgp.deselectAll();
								foreach (i, c; cs) { mixin(S_TRACE);
									int index = insertIndex(_cards) + i;
									addC ~= index;
									_area.insert(index, c);
								}
								appendCards(insertIndex(_cards), cs, true, true);
								if (_viewCards) _imgp.redraw();
								refreshSelected();
								_comm.refUseCount.call();
								refreshFlags();
								_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, addC, []);
								_comm.refreshToolBar();
							}
						} catch (Exception e) {
							debugln(e);
						}
					}
				}
			}
			void del(SelectionEvent se) { mixin(S_TRACE);
				delImpl2(this.outer, _comm, _area, _cards.getSelectionIndices(), [], true);
				_comm.refreshToolBar();
			}
			void clone(SelectionEvent se) { mixin(S_TRACE);
				_comm.clipboard.memoryMode = true;
				scope (exit) _comm.clipboard.memoryMode = false;
				copy(se);
				paste(se);
			}
			@property
			bool canDoTCPD() { mixin(S_TRACE);
				return _cards.isVisible() && _cards.isEnabled();
			}
			@property
			bool canDoT() { mixin(S_TRACE);
				return _cards.getSelectionIndex() != -1;
			}
			@property
			bool canDoC() { mixin(S_TRACE);
				return _cards.getSelectionIndex() != -1;
			}
			@property
			bool canDoP() { mixin(S_TRACE);
				return CBisXML(_comm.clipboard);
			}
			@property
			bool canDoD() { mixin(S_TRACE);
				return _cards.getSelectionIndex() != -1;
			}
			@property
			bool canDoClone() { mixin(S_TRACE);
				return canDoC;
			}
		}
	}
	static if (UseBacks) {
		private class BgImageTCPD : TCPD {
			void cut(SelectionEvent se) { mixin(S_TRACE);
				copy(se);
				del(se);
			}
			void copy(SelectionEvent se) { mixin(S_TRACE);
				scope BgImage[] backs;
				foreach (i; _backs.getSelectionIndices()) { mixin(S_TRACE);
					backs ~= _area.backs[i];
				}
				if (backs.length > 0) { mixin(S_TRACE);
					XMLtoCB(_prop, _comm.clipboard, A.BtoXML(backs, new XMLOption(_prop.sys)));
					_comm.refreshToolBar();
				}
			}
			void paste(SelectionEvent se) { mixin(S_TRACE);
				static if (UseCards) {
					this.outer.paste(se);
				} else { mixin(S_TRACE);
					auto xml = CBtoXML(_comm.clipboard);
					if (xml) { mixin(S_TRACE);
						try { mixin(S_TRACE);
							BgImage[] bs;
							auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
							A.BfromXML(xml, bs, ver);
							if (bs.length) { mixin(S_TRACE);
								int[] addB;
								_imgp.deselectAll();
								foreach (i, b; bs) { mixin(S_TRACE);
									int index = insertIndex(_backs) + i;
									addB ~= index;
									_area.insert(index, b);
								}
								appendBgImages(insertIndex(_backs), bs, true, true);
								if (_viewBacks) _imgp.redraw();
								refreshSelected();
								_comm.refUseCount.call();
								refreshFlags();
								_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, [], addB);
								_comm.refreshToolBar();
							}
						} catch (Exception e) {
							debugln(e);
						}
					}
				}
			}
			void del(SelectionEvent se) { mixin(S_TRACE);
				delImpl2(this.outer, _comm, _area, [], _backs.getSelectionIndices(), true);
				_comm.refreshToolBar();
			}
			void clone(SelectionEvent se) { mixin(S_TRACE);
				_comm.clipboard.memoryMode = true;
				scope (exit) _comm.clipboard.memoryMode = false;
				copy(se);
				paste(se);
			}
			@property
			bool canDoTCPD() { mixin(S_TRACE);
				return _backs.isVisible() && _backs.isEnabled();
			}
			@property
			bool canDoT() { mixin(S_TRACE);
				return _backs.getSelectionIndex() != -1;
			}
			@property
			bool canDoC() { mixin(S_TRACE);
				return _backs.getSelectionIndex() != -1;
			}
			@property
			bool canDoP() { mixin(S_TRACE);
				return CBisXML(_comm.clipboard);
			}
			@property
			bool canDoD() { mixin(S_TRACE);
				return _backs.getSelectionIndex() != -1;
			}
			@property
			bool canDoClone() { mixin(S_TRACE);
				return canDoC;
			}
		}
	}
	void undo() {_undo.undo();}
	void redo() {_undo.redo();}

	bool openCWXPath(string path, bool shellActivate) { mixin(S_TRACE);
		if (cpempty(path)) { mixin(S_TRACE);
			if (!cphasattr(path, "nofocus")) .forceFocus(_imgp, shellActivate);
			_comm.refreshToolBar();
			return true;
		}
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		bool sel(Table list) { mixin(S_TRACE);
			if (index >= list.getItemCount()) return false;
			if (!cphasattr(path, "nofocus")) .forceFocus(_imgp, shellActivate);
			list.select(index);
			list.showSelection();
			_comm.refreshToolBar();
			return true;
		}
		static if (UseCards && is(C : MenuCard)) {
			if (cate == "menucard") { mixin(S_TRACE);
				if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
					if (index >= _cards.getItemCount()) return false;
					editCard([index]);
					return true;
				} else { mixin(S_TRACE);
					if (sel(_cards)) { mixin(S_TRACE);
						listSelectC();
						return true;
					}
				}
			}
		}
		static if (UseCards && is(C : EnemyCard)) {
			if (cate == "enemycard") { mixin(S_TRACE);
				if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
					if (index >= _cards.getItemCount()) return false;
					editCard([index]);
					return true;
				} else { mixin(S_TRACE);
					if (sel(_cards)) { mixin(S_TRACE);
						listSelectC();
						return true;
					}
				}
			}
		}
		static if (UseBacks) {
			if (cate == "background") { mixin(S_TRACE);
				if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
					if (index >= _backs.getItemCount()) return false;
					editBack([index]);
					return true;
				} else { mixin(S_TRACE);
					if (sel(_backs)) { mixin(S_TRACE);
						listSelectB();
						return true;
					}
				}
			}
		}
		return false;
	}
	@property
	string[] openedCWXPath() { mixin(S_TRACE);
		string[] r;
		static if (UseCards) {
			foreach (i; _cards.getSelectionIndices()) { mixin(S_TRACE);
				r ~= _area.cards[i].cwxPath(true);
			}
		}
		static if (UseBacks) {
			foreach (i; _backs.getSelectionIndices()) { mixin(S_TRACE);
				r ~= _area.backs[i].cwxPath(true);
			}
		}
		return r.length ? r : [_area.cwxPath(true)];
	}
}

alias AbstractAreaView!(Area, MenuCard, true, true) AreaView;
alias AbstractAreaView!(Battle, EnemyCard, true, false) BattleView;

class BgImagesView : AbstractAreaView!(BgImageContainer, void, false, true) {
	this(Commons comm, Props prop, Summary summ, BgImageContainer bic, Composite parent, AbstractArea refTarget, UndoManager undo) { mixin(S_TRACE);
		if (prop.var.etc.refCardsAtEditBgImage) { mixin(S_TRACE);
			_refTarget = refTarget;
		}
		super(comm, prop, summ, bic, parent, null, undo);
	}
}
