
module cwx.editor.gui.dwt.areaview;

import cwx.area;
import cwx.background;
import cwx.card;
import cwx.flag;
import cwx.graphics;
import cwx.imagesize;
import cwx.menu;
import cwx.msgutils;
import cwx.path;
import cwx.props;
import cwx.sjis;
import cwx.skin;
import cwx.structs;
import cwx.summary;
import cwx.system;
import cwx.types;
import cwx.usecounter;
import cwx.utils;
import cwx.xml;

import cwx.editor.gui.sound;

import cwx.editor.gui.dwt.absdialog;
import cwx.editor.gui.dwt.areaviewutils;
import cwx.editor.gui.dwt.areawindow;
import cwx.editor.gui.dwt.bgimagedialog;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.comment;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.incsearch;
import cwx.editor.gui.dwt.jpyimage;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.messageutils;
import cwx.editor.gui.dwt.spcarddialog;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.xmlbytestransfer;

import std.algorithm;
import std.conv;
import std.datetime;
import std.file;
import std.math;
import std.path;
import std.range;
import std.string;
import std.traits;
import std.typecons;

import org.eclipse.swt.all;

import java.lang.all;

public:

private P spnValue(string T, N, P)(N[] keys, P val) { mixin(S_TRACE);
	if (!keys.length) return val;
	auto a = keys[0];
	P value = mixin(T);
	for (int i = 1; i < keys.length; i++) { mixin(S_TRACE);
		a = keys[i];
		if (mixin(T) != value) { mixin(S_TRACE);
			value = val;
			break;
		}
	}
	return value;
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
		assert (!_readOnly);
		foreach (dlg; modEvent) dlg();
	}
private:
	string _id;
	Commons _comm;
	Props _prop;
	A _area;
	UseCounter _uc;
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
		private Object _lastData = null;
		override void mouseEnter(MouseEvent e) { mixin(S_TRACE);
			if (_prop.var.etc.showCardStatusUnderPointer) refreshStatusLine();
		}
		override void mouseExit(MouseEvent e) { mixin(S_TRACE);
			_preview.close();
			if (_prop.var.etc.showCardStatusUnderPointer) refreshStatusLine();
		}
		override void mouseMove(MouseEvent e) { mixin(S_TRACE);
			auto list = cast(Table)e.widget;
			previewTrigger(list, e.x, e.y);

			auto itm = list.getItem(new Point(e.x, e.y));
			auto d = itm ? itm.getData() : null;
			if (d !is _lastData) { mixin(S_TRACE);
				_lastData = d;
				if (_prop.var.etc.showCardStatusUnderPointer) { mixin(S_TRACE);
					if (auto card = cast(MenuCard)d) { mixin(S_TRACE);
						statusLine = .createAreaViewStatusLine(_comm, _summ, summSkin, card);
					} else if (auto card = cast(EnemyCard)d) { mixin(S_TRACE);
						statusLine = .createAreaViewStatusLine(_comm, _summ, summSkin, card);
					} else if (auto back = cast(BgImage)d) { mixin(S_TRACE);
						statusLine = .createAreaViewStatusLine(_comm, _summ, summSkin, back);
					} else { mixin(S_TRACE);
						refreshStatusLine();
					}
				}
			}
		}
	}

	@property
	const
	size_t messageIndex() { mixin(S_TRACE);
		size_t index = 0;
		static if (UseCards) index += _area.cards.length;
		static if (UseBacks) index += _area.backs.length;
		return index;
	}
	@property
	size_t partyIndex() { mixin(S_TRACE);
		return messageIndex + 1;
	}

	/// 他のエリアのカード配置を参照する。
	static const RefCards = !UseCards && UseBacks;
	static if (RefCards) {
		Combo _refAreas;
		AbstractArea[] _refAreasArr;
		AbstractArea _refTarget = null;
		bool _showRefCards = false;
		IncSearch _refAreaIncSearch;
		bool _hasRefArea = false;
		void refreshRefAreas() { mixin(S_TRACE);
			if (!_refAreas || _refAreas.isDisposed()) return;
			if (!_summ || _summ.scenarioPath == "") return;
			_refAreasArr.length = 0;
			_refAreas.removeAll();
			_hasRefArea = false;
			if (!_area) return;
			_refAreas.add(_prop.msgs.defaultSelection(_prop.msgs.noRefArea));
			_refAreas.select(0);
			bool has = _refTarget is null;
			foreach (a; _summ.areas) { mixin(S_TRACE);
				if(_refTarget is a) has = true;
				_hasRefArea = true;
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
				}
			}
		}
		void refreshRefAreasA(Area a) { refreshRefAreas(); }
		void refreshRefAreasB(Battle a) { refreshRefAreas(); }
		@property
		size_t refCardIndex() { mixin(S_TRACE);
			// カード数+背景数+メッセージ(×1)+パーティ人数
			return partyIndex + _prop.looks.partyCardXY.length;
		}
		void refRefMenuCard(string a) { mixin(S_TRACE);
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath(true), cpparent(a))) return;
			createRefCard();
		}
		void addRefMenuCard(string a) { mixin(S_TRACE);
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath(true), cpparent(a))) return;
			createRefCard();
		}
		void delRefMenuCard(string a) { mixin(S_TRACE);
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath(true), cpparent(a))) return;
			createRefCard(cast(int)cpindex(cpbottom(a)));
		}
		void upRefMenuCards(string a, int[] indices, int count) { mixin(S_TRACE);
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath(true), a)) return;
			if (!indices.length) return;
			createRefCard();
		}
		void downRefMenuCards(string a, int[] indices, int count) { mixin(S_TRACE);
			if (!_refTarget) return;
			if (!cpeq(_refTarget.cwxPath(true), a)) return;
			if (!indices.length) return;
			createRefCard();
		}
		void openRefAreaView() { mixin(S_TRACE);
			if (!_refTarget) return;
			try { mixin(S_TRACE);
				if (auto a = cast(Area)_refTarget)_comm.openAreaScene(_prop, _summ, a, false, false);
				if (auto a = cast(Battle)_refTarget)_comm.openAreaScene(_prop, _summ, a, false, false);
			} catch (Exception e) {
				printStackTrace();
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
			static if (!is(A:Area) && !is(A:Battle)) {
				_v = v;
			}
			this.comm = comm;
			this.area = area;
			this.summ = summ;
		}
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
		protected void udb(AbstractAreaView[] vs) { mixin(S_TRACE);
			if (!vs.length) return;
			auto ct = Display.getCurrent().getFocusControl();
			if (!ct) return;
			foreach (v; vs) { mixin(S_TRACE);
				while (ct.getParent()) { mixin(S_TRACE);
					if (ct is v) { mixin(S_TRACE);
						return;
					}
					ct = ct.getParent();
				}
			}
			.forceFocus(vs[0]._imgp, false);
		}
		protected void uda(AbstractAreaView[] vs) { mixin(S_TRACE);
			scope (exit) comm.refreshToolBar();
			foreach (v; vs) { mixin(S_TRACE);
				static if (UseCards) if (!v._viewCards) v._cards.deselectAll();
				static if (UseBacks) if (!v._viewBacks) v._backs.deselectAll();
				v.refreshStatusLine();
			}
		}
		protected AbstractAreaView[] views() { mixin(S_TRACE);
			static if (is(A : Area) || is(A : Battle)) {
				return comm.areaViewsFrom!(A, C, UseCards, UseBacks)(area.cwxPath(true), false);
			} else { mixin(S_TRACE);
				return [_v];
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
				auto vs = views();
				udb(vs);
				scope (exit) uda(vs);
				auto spAuto = area.spAuto;
				area.spAuto = _spAuto;
				_spAuto = spAuto;
				foreach (v; vs) { mixin(S_TRACE);
					if (v._autoMenu) v._autoMenu.setSelection(area.spAuto);
					if (v._autoTMenu) v._autoTMenu.setSelection(area.spAuto);
					if (v._customMenu) v._customMenu.setSelection(!area.spAuto);
					if (v._customTMenu) v._customTMenu.setSelection(!area.spAuto);
					v.callModEvent();
				}
			}
			override void undo() { impl(); }
			override void redo() { impl(); }
			override void dispose() { }
		}
	}
	static if (is(A == Battle)) {
		static class MCWXPath : CWXPath {
			@property
			override string cwxPath(bool id) { return ""; }
			override CWXPath findCWXPath(string path) { return null; }
			@property
			inout
			override inout(CWXPath)[] cwxChilds() { return []; }
			@property
			CWXPath cwxParent() { return null; }
			protected
			override
			void changed() { }
		}
		static class UndoMusic : AUndo {
			private PathUser _path;
			private uint _volume;
			private uint _loopCount;
			private uint _fadeIn;
			private bool _continueBGM;
			this (AbstractAreaView v, Commons comm, A area, Summary summ) { mixin(S_TRACE);
				super (v, comm, area, summ);
				_path = new PathUser(new MCWXPath);
				if (area.useCounter) _path.setUseCounter(area.useCounter.sub);
				_path.path = area.music;
				_volume = area.volume;
				_loopCount = area.loopCount;
				_fadeIn = area.fadeIn;
				_continueBGM = area.continueBGM;
			}
			private void impl() { mixin(S_TRACE);
				auto vs = views();
				udb(vs);
				scope (exit) uda(vs);
				auto path = _path.path;
				auto volume = _volume;
				auto loopCount = _loopCount;
				auto fadeIn = _fadeIn;
				auto continueBGM = _continueBGM;
				_path.path = area.music;
				_volume = area.volume;
				_loopCount = area.loopCount;
				_fadeIn = area.fadeIn;
				_continueBGM = area.continueBGM;
				area.music = path;
				area.volume = volume;
				area.loopCount = loopCount;
				area.fadeIn = fadeIn;
				area.continueBGM = continueBGM;
				foreach (v; vs) { mixin(S_TRACE);
					v._bgm.path = path;
					v._bgm.volume = volume;
					v._bgm.loopCount = loopCount;
					v._bgm.fadeIn = fadeIn;
					v._bgm.continueBGM = continueBGM;
					v.callModEvent();
				}
			}
			override void undo() { impl(); }
			override void redo() { impl(); }
			override void dispose() { mixin(S_TRACE);
				_path.removeUseCounter();
			}
		}
		static class UndoPossibleToRunAway : AUndo {
			private bool _possibleToRunAway;
			this (AbstractAreaView v, Commons comm, A area, Summary summ) { mixin(S_TRACE);
				super (v, comm, area, summ);
				_possibleToRunAway = area.possibleToRunAway;
			}
			private void impl() { mixin(S_TRACE);
				auto vs = views();
				udb(vs);
				scope (exit) uda(vs);
				auto possibleToRunAway = area.possibleToRunAway;
				area.possibleToRunAway = _possibleToRunAway;
				_possibleToRunAway = possibleToRunAway;
				foreach (v; vs) { mixin(S_TRACE);
					if (v._possibleToRunAwayMenu) v._possibleToRunAwayMenu.setSelection(area.possibleToRunAway);
					if (v._possibleToRunAwayCheck) v._possibleToRunAwayCheck.setSelection(area.possibleToRunAway);
					v.callModEvent();
				}
			}
			override void undo() { impl(); }
			override void redo() { impl(); }
			override void dispose() { }
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
		private void reselect(AbstractAreaView[] vs) { mixin(S_TRACE);
			foreach (v; vs) { mixin(S_TRACE);
				static if (UseCards) {
					v._cards.select(_cIdcs);
					v.listSelectC();
				}
				static if (UseBacks) {
					v._backs.select(_bIdcs);
					v.listSelectB();
				}
			}
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
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			add(I * _count);
			reselect(vs);
			static if (I < 0) {
				downImpl(vs, comm, area, _cIdcs, _bIdcs, _count, false);
			} else { mixin(S_TRACE);
				upImpl(vs, comm, area, _cIdcs, _bIdcs, _count, false);
			}
			add(-I * _count);
		}
		override void redo() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			reselect(vs);
			static if (I < 0) {
				upImpl(vs, comm, area, _cIdcs, _bIdcs, _count, false);
			} else { mixin(S_TRACE);
				downImpl(vs, comm, area, _cIdcs, _bIdcs, _count, false);
			}
		}
		override void dispose() { }
	}
	alias UndoUD!(-1) UndoUp;
	alias UndoUD!(1) UndoDown;
	static if (UseCards) {
		static class UndoCardIndices : AUndo {
			mixin Reselect;
			private Tuple!(size_t, size_t)[] _indices;
			this (AbstractAreaView v, Commons comm, A area, Summary summ, int[] cIdcs, int[] bIdcs, Tuple!(size_t, size_t)[] indices) { mixin(S_TRACE);
				super (v, comm, area, summ);
				_cIdcs = cIdcs;
				_bIdcs = bIdcs;
				_indices = indices;
			}
			private void impl() { mixin(S_TRACE);
				auto vs = views();
				udb(vs);
				scope (exit) uda(vs);

				_indices = .map!(t => .tuple(t[1], t[0]))(_indices).array();
				area.setCardIndices(_indices);
				comm.refMenuCardIndices.call(area, _indices);
				reselect(vs);
			}
			override void undo() { impl(); }
			override void redo() { impl(); }
			override void dispose() { }
		}
		UndoCardIndices createUndoCardIndices(Tuple!(size_t, size_t)[] indices) { mixin(S_TRACE);
			int[] cs;
			int[] bs;
			static if (UseCards) cs = _cards.getSelectionIndices();
			static if (UseBacks) bs = _backs.getSelectionIndices();
			return new UndoCardIndices(this, _comm, _area, _summ, cs, bs, indices);
		}
	}
	static class UndoInsert : AUndo {
		mixin Reselect;
		private UndoDelete _delUndo = null;
		override void undo() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			reselect(vs);
			_delUndo = new UndoDelete(vs[0], comm, area, summ, _cIdcs, _bIdcs);
			delImpl2(vs, comm, summ, area, _cIdcs, _bIdcs, false);
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
			bool[int] _cGrys;
		}
		static if (UseBacks) {
			BgImage[int] _bs;
			bool[int] _bChks;
			bool[int] _bGrys;
		}
		this (AbstractAreaView v, Commons comm, A area, Summary summ, int[] cIdcs, int[] bIdcs) { mixin(S_TRACE);
			super (v, comm, area, summ);
			static if (UseCards) {
				foreach (i; cIdcs) { mixin(S_TRACE);
					auto c = area.cards[i].dup;
					if (area.useCounter) c.setUseCounter(area.useCounter.sub, area);
					_cs[i] = c;
					_cChks[i] = v ? v._cards.getItem(i).getChecked() : true;
					_cGrys[i] = v ? v._cards.getItem(i).getGrayed() : false;
				}
			}
			static if (UseBacks) {
				foreach (i; bIdcs) { mixin(S_TRACE);
					auto b = area.backs[i].dup;
					if (area.useCounter) b.setUseCounter(area.useCounter.sub, area);
					_bs[i] = b;
					_bChks[i] = v ? v._backs.getItem(i).getChecked() : true;
					_bGrys[i] = v ? v._backs.getItem(i).getGrayed() : false;
				}
			}
		}
		override void undo() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			static if (UseCards) {
				foreach (i; std.algorithm.sort(_cs.keys)) { mixin(S_TRACE);
					appendCardImpl(vs, comm, summ, area, i, _cs[i].dup, true, false, _cChks[i], _cGrys[i]);
				}
			}
			static if (UseBacks) {
				foreach (i; std.algorithm.sort(_bs.keys)) { mixin(S_TRACE);
					appendBgImageImpl(vs, comm, summ, area, i, _bs[i].dup, true, false, _bChks[i], _bGrys[i]);
				}
			}
			if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
				comm.refUseCount.call();
			}
			foreach (v; vs) { mixin(S_TRACE);
				v.refreshSelected();
				v.refreshFlags();
				v.checked();
				v.callModEvent();
			}
		}
		override void redo() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			int[] cs;
			int[] bs;
			static if (UseCards) cs = _cs.keys;
			static if (UseBacks) bs = _bs.keys;
			delImpl2(vs, comm, summ, area, cs, bs, false);
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
		UseCounter _uc;
		this (AbstractAreaView v, Commons comm, A area, Summary summ, int[] ckeys, int[] bkeys) { mixin(S_TRACE);
			super (v, comm, area, summ);
			_uc = v._uc;
			static if (UseCards) _cs = saveC(ckeys);
			static if (UseBacks) _bs = saveB(bkeys);
		}
		static if (UseCards) {
			private C[int] saveC(int[] indices) { mixin(S_TRACE);
				C[int] cs;
				foreach (i; indices) { mixin(S_TRACE);
					auto c = area.cards[i];
					c = c.shallowCopy;
					if (area.useCounter) c.setUseCounter(area.useCounter.sub, area);
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
					if (area.useCounter) b.setUseCounter(area.useCounter.sub, area);
					bs[i] = b;
				}
				return bs;
			}
		}
		private void impl() { mixin(S_TRACE);
			auto vs = views();
			udb(vs);
			scope (exit) uda(vs);
			static if (UseCards) {
				auto cs = saveC(_cs.keys);
				foreach (i, c; _cs) { mixin(S_TRACE);
					c.removeUseCounter();
					auto ac = area.cards[i];
					ac.shallowCopyFrom(c);
					if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
						comm.refMenuCard.call(ac.cwxPath(true));
					}
				}
				_cs = cs;
			}
			static if (UseBacks) {
				auto bs = saveB(_bs.keys);
				foreach (i, b; _bs) { mixin(S_TRACE);
					area.backs[i].deepCopy(b);
					if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
						comm.refBgImage.call(area.backs[i].cwxPath(true));
					}
				}
				_bs = bs;
			}
			foreach (v; vs) { mixin(S_TRACE);
				v.refreshPanel();
				v.refreshControls();
				v.callModEvent();
				v.refreshFlags();
			}
			if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
				comm.refUseCount.call();
			}
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

	private AbstractAreaView[] views() { mixin(S_TRACE);
		static if (is(A:Area) || is(A:Battle)) {
			auto vs = _comm.areaViewsFrom!(A, C, UseCards, UseBacks)(_area.cwxPath(true), false);
			foreach (v; vs) { mixin(S_TRACE);
				if (v.setupToolBar(v._toolbar)) _comm.refreshToolBar();
			}
			return vs;
		} else { mixin(S_TRACE);
			return [this];
		}
	}

	@property
	protected Props prop() { return _prop; }
	@property
	protected Summary summ() { return _summ; }

	int _readOnly = SWT.NONE;

	Skin _summSkin;
	Skin _forceSkin = null;
	@property
	Skin summSkin() { mixin(S_TRACE);
		return _summSkin ? _summSkin : _comm.skin;
	}

	ToolBar _toolbar;
	ImagePane _imgp;
	Table _flagList;
	Button _flagAllCheck;
	IncSearch _refFlagIncSearch;
	void flagIncSearch() { mixin(S_TRACE);
		.forceFocus(_flagList, true);
		_refFlagIncSearch.startIncSearch();
	}
	Control _lastFocus = null;
	bool _hasFlags = false;

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
	static if (is(C == EnemyCard) || RefCards) {
		MenuItem _dbgMenu;
		ToolItem _dbgTMenu;
		@property
		public bool debugMode() { return _dbgMode; }
		bool _dbgMode = false;
		void reverseDebugMode() { mixin(S_TRACE);
			_dbgMode = !_dbgMode;
			if (_dbgMenu) _dbgMenu.setSelection(_dbgMode);
			if (_dbgTMenu) _dbgTMenu.setSelection(_dbgMode);
			refreshPanel();
			_prop.var.etc.viewEnemyCardDebug = _dbgMode;
		}
	}
	static if (is(C == EnemyCard)) {
		ToolItem _escTMenu;
		MaterialSelect!(MtType.BGM, Combo, Combo) _bgm;
		void setEscape() { mixin(S_TRACE);
			if (_readOnly) return;
			_undo ~= createUndoEdit();
			foreach (c, i; _editC) { mixin(S_TRACE);
				c.action(ActionCardType.RunAway, _escTMenu.getSelection());
				_cards.getItem(i).setImage(cardImg(c));
				_comm.refMenuCard.call(c.cwxPath(true));
			}
			callModEvent();
			foreach (v; views()) { mixin(S_TRACE);
				// 同期
				if (v !is this) { mixin(S_TRACE);
					v.refreshControls();
					v.callModEvent();
				}
			}
		}
		void selectBGM() { mixin(S_TRACE);
			if (_readOnly) return;
			if (_area.music == _bgm.path
					&& _area.volume == _bgm.volume
					&& _area.loopCount == _bgm.loopCount
					&& _area.fadeIn == _bgm.fadeIn
					&& _area.continueBGM == _bgm.continueBGM) {
				return;
			}
			_undo ~= new UndoMusic(this, _comm, _area, _summ);
			_area.music = _bgm.path;
			_area.volume = _bgm.volume;
			_area.loopCount = _bgm.loopCount;
			_area.fadeIn = _bgm.fadeIn;
			_area.continueBGM = _bgm.continueBGM;
			if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
				_comm.refUseCount.call();
			}
			callModEvent();
			_comm.refreshToolBar();
			foreach (v; views()) { mixin(S_TRACE);
				// 同期
				if (v !is this) { mixin(S_TRACE);
					v._bgm.path = _area.music;
					v._bgm.volume = _area.volume;
					v._bgm.loopCount = _area.loopCount;
					v._bgm.fadeIn = _area.fadeIn;
					v._bgm.continueBGM = _area.continueBGM;
					v.callModEvent();
				}
			}
		}
	}

	static if (UseCards && UseBacks) {
		SplitPane _sash;
	}

	@property
	ImagePane imagePane() { return _imgp; }
	Spinner _xSpn, _ySpn;
	Spinner _layerSpn;
	Combo _flag = null;
	bool _hasFlag = false;
	static if (UseCards) {
		bool _fixedC = true;
		bool _viewCards = true;
		C[PileImage] _cardTbl;
		int[C] _editC;
		Table _cards;
		static if (is(C:MenuCard)) {
			TableTextEdit _cardEdit = null;
		} else static if (is(C:EnemyCard)) {
			TableComboEdit!Combo _cardEdit = null;
		} else static assert (0);
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
		Table cardList() { return _cards; }
		void editSpnCard(string T)(int value) { mixin(S_TRACE);
			if (_readOnly) return;
			editSpnImpl!(T, C)(value, _editC, cardsIndex);
		}
		void enterSpnCard(string T, string N)(int value) { mixin(S_TRACE);
			if (_readOnly) return;
			_undo ~= createUndoEdit();
			enterSpnImpl!(T, N, C)(value, _editC, (v) => v.cardsIndex);
		}
		int cancelSpnCard(string T, string SetFlexImage)(int oldVal) { mixin(S_TRACE);
			if (_readOnly) return oldVal;
			assert(_editC.length > 0);
			return cancelSpnImpl!(T, SetFlexImage, C)(_editC, (v) => v.cardsIndex, true);
		}
		class SCListener : MouseAdapter, SelectionListener {
			public override void widgetDefaultSelected(SelectionEvent e) { }
			public override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				listSelectC();
			}
			public override void mouseUp(MouseEvent e) { mixin(S_TRACE);
				// BUG: 稀にアイテムがないところをクリックして
				//      全ての選択を解除してもSelectionEventが発生しないケースがある
				if (!_cards.getItem(new Point(e.x, e.y))) listSelectC();
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
		void resizeImageC(FlexImage img, int x, int y, uint scale) { mixin(S_TRACE);
			if (_readOnly) return;
			auto card = _cardTbl[img];
			card.x = x;
			card.y = y;
			card.scale = scale;
			auto index = _area.cards.cCountUntil!("a is b")(card);
			foreach (v; views()) { mixin(S_TRACE);
				if (v !is this) { mixin(S_TRACE);
					auto fi = cast(FlexImage)v._imgp.images[cardsIndex + index];
					assert (fi !is null);
					v._imgp.redrawImage(fi);
					fi.newBounds = img.bounds;
					fi.resize(false);
					v._imgp.redrawImage(fi);
				}
				v.refreshControls();
				v.callModEvent();
				v.checked();
			}
			if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
				_comm.refMenuCard.call(card.cwxPath(true));
			}
		}
		private FlexImage[] _selectImageC = [];
		void selectImageC(FlexImage img) { mixin(S_TRACE);
			_selectImageC ~= img;
			selectImage!(C)(img, _area.cards, _cardTbl, _editC, _cards);
			refreshControls();
		}
		private void selectImageCImpl() { mixin(S_TRACE);
			if (!_selectImageC.length) return;
			_cards.setRedraw(false);
			scope (exit) _cards.setRedraw(true);
			_toolbar.setRedraw(false);
			scope (exit) _toolbar.setRedraw(true);
			_selectImageC.length = 0;
			refreshControls();
			_cards.showSelection();
		}
		void setAuto() { mixin(S_TRACE);
			if (_readOnly) return;
			_undo ~= new UndoSPAuto(this, _comm, _area, _summ);
			setAutoImpl(true);
		}
		void setCustom() { mixin(S_TRACE);
			if (_readOnly) return;
			_undo ~= new UndoSPAuto(this, _comm, _area, _summ);
			setAutoImpl(false);
		}
		FlexImage cardImage(int index) { mixin(S_TRACE);
			return cast(FlexImage)_imgp.images[cardsIndex + index];
		}
	}

	static if (UseBacks) {
		bool _fixedB = true;
		bool _fixedFirstB = true;
		bool _viewBacks = true;
		BgImage[PileImage] _backTbl;
		TableComboEdit!Combo _backEdit = null;
		int[BgImage] _editB;
		Table _backs;
		CLabel _inheritBgImgs = null;
		bool _showInheritBacks = true;
		MenuItem _vfbMenu;
		ToolItem _vfbTMenu;
		MenuItem _vffbMenu;
		ToolItem _vffbTMenu;
		MenuItem _vbMenu;
		ToolItem _vbTMenu;
		ToolItem _maskTMenu;
		Spinner _wSpn, _hSpn;

		@property
		Table backList() { return _backs; }
		void editSpnBack(string T)(int value) { mixin(S_TRACE);
			if (_readOnly) return;
			editSpnImpl!(T, BgImage)(value, _editB, 0);
		}
		void enterSpnBack(string T, string N)(int value) { mixin(S_TRACE);
			if (_readOnly) return;
			_undo ~= createUndoEdit();
			enterSpnImpl!(T, N, BgImage)(value, _editB, (v) => 0);
		}
		int cancelSpnBack(string T, string SetFlexImage)(int oldVal) { mixin(S_TRACE);
			if (_readOnly) return oldVal;
			assert(_editB.length > 0);
			return cancelSpnImpl!(T, SetFlexImage, BgImage)(_editB, (v) => 0, true);
		}
		class SBListener : MouseAdapter, SelectionListener {
			public override void widgetDefaultSelected(SelectionEvent e) { }
			public override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				listSelectB();
			}
			public override void mouseUp(MouseEvent e) { mixin(S_TRACE);
				// BUG: 稀にアイテムがないところをクリックして
				//      全ての選択を解除してもSelectionEventが発生しないケースがある
				if (!_backs.getItem(new Point(e.x, e.y))) listSelectB();
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
			if (_readOnly) return;
			auto back = _backTbl[img];
			back.x = x;
			back.y = y;
			back.width = w;
			back.height = h;
			auto index = _area.backs.cCountUntil!("a is b")(back);
			foreach (v; views()) { mixin(S_TRACE);
				if (v !is this) { mixin(S_TRACE);
					auto fi = cast(FlexImage)v._imgp.images[0 + index];
					assert (fi !is null);
					v._imgp.redrawImage(fi);
					fi.newBounds = img.bounds;
					fi.resize(false);
					v._imgp.redrawImage(fi);
				}
				v.refreshControls();
				v.callModEvent();
				v.checked();
			}
			if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
				_comm.refBgImage.call(back.cwxPath(true));
			}
		}
		private FlexImage[] _selectImageB = [];
		void selectImageB(FlexImage img) { mixin(S_TRACE);
			_selectImageB ~= img;
			selectImage!(BgImage)(img, _area.backs, _backTbl, _editB, _backs);
			refreshControls();
		}
		private void selectImageBImpl() { mixin(S_TRACE);
			if (!_selectImageB.length) return;
			_backs.setRedraw(false);
			scope (exit) _backs.setRedraw(true);
			_toolbar.setRedraw(false);
			scope (exit) _toolbar.setRedraw(true);
			_selectImageB.length = 0;
			refreshControls();
			_backs.showSelection();
		}
		void setMask() { mixin(S_TRACE);
			if (_readOnly) return;
			_undo ~= createUndoEdit();
			auto vs = views();
			foreach (back, i; _editB) { mixin(S_TRACE);
				if (cast(ImageCell)back) { mixin(S_TRACE);
					back.mask = _maskTMenu.getSelection();
					foreach (v; vs) { mixin(S_TRACE);
						auto img = v._imgp.images[0 + i];
						img.transparent = back.mask;
						img.createImage();
						v._imgp.redrawImage(img);
					}
					if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
						_comm.refBgImage.call(back.cwxPath(true));
					}
				}
			}
			foreach (v; vs) { mixin(S_TRACE);
				v.callModEvent();
				if (v !is this) { mixin(S_TRACE);
					v.refreshControls();
				}
			}
			_comm.refreshToolBar();
		}
		FlexImage backImage(int index) { mixin(S_TRACE);
			return cast(FlexImage)_imgp.images[index];
		}

		void updateInheritBacks() { mixin(S_TRACE);
			if (!_inheritBgImgs) return;
			if (.isInheritBackground(_area.backs)) { mixin(S_TRACE);
				_inheritBgImgs.setText(_prop.msgs.inheritBackground);
				_inheritBgImgs.setToolTipText(_prop.msgs.inheritBackgroundHint);
				_inheritBgImgs.setImage(_prop.images.inheritBackground);
			} else { mixin(S_TRACE);
				_inheritBgImgs.setText(_prop.msgs.notInheritBackground);
				_inheritBgImgs.setToolTipText(_prop.msgs.notInheritBackgroundHint);
				_inheritBgImgs.setImage(_prop.images.notInheritBackground);
			}
		}
	}

	void selectListItem(T)(Table list, int startIndex, ref int[T] edits, T[] cols) { mixin(S_TRACE);
		int count = list.getItemCount();
		auto imgs = _imgp.images;
		typeof(edits) editsInit;
		edits = editsInit;
		auto oldSels = _imgp.selectedIndices;
		for (int i = 0; i < count; i++) { mixin(S_TRACE);
			auto img = cast(FlexImage)imgs[startIndex + i];
			bool o = img.selected;
			bool n = list.isSelected(i);
			if (n) { mixin(S_TRACE);
				_imgp.select(img);
				edits[cols[i]] = i;
			} else { mixin(S_TRACE);
				_imgp.deselect(img);
			}
		}
		if (oldSels == _imgp.selectedIndices) return;
		static if (is(T == C)) {
			refreshSelectedImpl(_viewCards, _cards, _editC, _area.cards, cardsIndex);
		} else { mixin(S_TRACE);
			refreshSelectedImpl(_viewBacks, _backs, _editB, _area.backs, 0);
		}
		refreshControls();
		_comm.refreshToolBar();
	}

	void editSpnImpl(string T, B)(int value, int[B] edits, int startIndex) { mixin(S_TRACE);
		if (_readOnly) return;
		if (_refreshControls) return;
		foreach (i; edits.byValue) { mixin(S_TRACE);
			auto a = cast(FlexImage)_imgp.images[startIndex + i];
			_imgp.redrawImage(a);
			mixin(T);
			_imgp.redrawImage(a);
		}
	}
	void enterSpnImpl(string T, string N, B)(int value, int[B] edits, int delegate(AbstractAreaView) startIndex) { mixin(S_TRACE);
		if (_readOnly) return;
		auto vs = views();
		foreach (c, i; edits) { mixin(S_TRACE);
			{ mixin(S_TRACE);
				auto a = c;
				mixin(T);
			}
			foreach (v; vs) { mixin(S_TRACE);
				auto a = cast(FlexImage)v._imgp.images[startIndex(v) + i];
				mixin(N);
				v._imgp.redrawImage(a);
				a.resize(false);
				v._imgp.redrawImage(a);
			}
			if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
				static if (is(B : AbstractSpCard)) {
					_comm.refMenuCard.call(c.cwxPath(true));
				} else static if (is(B : BgImage)) {
					_comm.refBgImage.call(c.cwxPath(true));
				} else static assert (0);
			}
		}
		foreach (v; vs) { mixin(S_TRACE);
			v.callModEvent();
			if (v !is this) v.refreshControls();
		}
		_comm.refreshToolBar();
	}
	int cancelSpnImpl(string T, string SetFlexImage, B)(int[B] edits, int delegate(AbstractAreaView) startIndex, bool redraw) { mixin(S_TRACE);
		if (_readOnly) return 0;
		if (!edits.length) return 0;
		auto a = edits.keys[0];
		auto r = mixin(T);
		auto vs = views();
		foreach (a2, i; edits) { mixin(S_TRACE);
			a = a2;
			auto fi = cast(FlexImage)_imgp.images[startIndex(this) + i];
			mixin(SetFlexImage);
			_imgp.redrawImage(fi);
			if (r != mixin(T)) r = 0;
			_imgp.redrawImage(fi);
		}
		if (redraw) { mixin(S_TRACE);
			refreshControls();
		}
		return r;
	}

	void editSpn(string T)(int value) { mixin(S_TRACE);
		if (_readOnly) return;
		static if (UseCards) editSpnImpl!(T, C)(value, _editC, cardsIndex);
		static if (UseBacks) editSpnImpl!(T, BgImage)(value, _editB, 0);
	}
	void enterSpn(string T, string N)(int value) { mixin(S_TRACE);
		if (_readOnly) return;
		_undo ~= createUndoEdit();
		static if (UseCards) enterSpnImpl!(T, N, C)(value, _editC, (v) => v.cardsIndex);
		static if (UseBacks) enterSpnImpl!(T, N, BgImage)(value, _editB, (v) => 0);
	}
	int cancelSpn(string T, string SetFlexImage)(int oldVal) { mixin(S_TRACE);
		if (_readOnly) return oldVal;
		static if (UseCards && UseBacks) {
			if (_editC.length + _editB.length == 0) return oldVal;
			if (_editC.length && _editB.length) { mixin(S_TRACE);
				auto r1 = cancelSpnImpl!(T, SetFlexImage, C)(_editC, (v) => v.cardsIndex, false);
				auto r2 = cancelSpnImpl!(T, SetFlexImage, BgImage)(_editB, (v) => 0, false);
				refreshControls();
				return r1 == r2 ? r1 : oldVal;
			} else if (_editC.length) { mixin(S_TRACE);
				return cancelSpnImpl!(T, SetFlexImage, C)(_editC, (v) => v.cardsIndex, true);
			} else { mixin(S_TRACE);
				assert(_editB.length);
				return cancelSpnImpl!(T, SetFlexImage, BgImage)(_editB, (v) => 0, true);
			}
		} else static if (UseCards) {
			if (_editC.length == 0) return oldVal;
			return cancelSpnCard!(T, SetFlexImage)(oldVal);
		} else static if (UseBacks) {
			if (_editB.length == 0) return oldVal;
			return cancelSpnBack!(T, SetFlexImage)(oldVal);
		} else { mixin(S_TRACE);
			static assert (0);
		}
	}

	void selectImage(T)(FlexImage img, T[] cols, T[PileImage] tbl, ref int[T] edits, Table list) { mixin(S_TRACE);
		auto c = tbl[img];
		foreach (i2, b; cols) { mixin(S_TRACE);
			auto i = cast(int)i2;
			if (b is c) { mixin(S_TRACE);
				if (img.selected) { mixin(S_TRACE);
					list.select(i);
					edits[b] = i;
				} else { mixin(S_TRACE);
					list.deselect(i);
					edits.remove(b);
				}
				return;
			}
		}
		assert(0);
	}

	int[] refreshSelectedImpl(T)(bool view, Table list, ref int[T] edits, T[] cols, int startIndex) { mixin(S_TRACE);
		int[] sels;
		foreach (key; edits.keys) { mixin(S_TRACE);
			edits.remove(key);
		}
		for (int i = startIndex; i < startIndex + list.getItemCount(); i++) { mixin(S_TRACE);
			auto fi = cast(FlexImage)_imgp.images[i];
			if (fi && view && fi.selected) { mixin(S_TRACE);
				sels ~= i - startIndex;
				edits[cols[i - startIndex]] = i - startIndex;
			}
		}
		return sels;
	}
	static if (UseCards) {
		private Image cardImg(C c) { mixin(S_TRACE);
			return .cardIcon(_prop, c);
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
				itm.setText(cardNameWithGroup(c));
			}
			_cards.setSelection(idx);
		}
	}
	static if (UseBacks) {
		private Image backImg(BgImage bg) { mixin(S_TRACE);
			Image normal, withFlag;
			if (cast(ImageCell)bg) { mixin(S_TRACE);
				normal = _prop.images.backs;
				withFlag = _prop.images.backsWithFlag;
			} else if (cast(TextCell)bg) { mixin(S_TRACE);
				normal = _prop.images.textCell;
				withFlag = _prop.images.textCellWithFlag;
			} else if (cast(ColorCell)bg) { mixin(S_TRACE);
				normal = _prop.images.colorCell;
				withFlag = _prop.images.colorCellWithFlag;
			} else if (cast(PCCell)bg) { mixin(S_TRACE);
				normal = _prop.images.pcCell;
				withFlag = _prop.images.pcCellWithFlag;
			} else assert (0);
			if (bg.flag && bg.flag != "") { mixin(S_TRACE);
				return withFlag;
			} else { mixin(S_TRACE);
				return normal;
			}
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
				itm.setText(c.name(_prop.parent));
			}
			_backs.setSelection(idx);
		}
	}
	static void upImpl2(T)(AbstractAreaView[] vs, Table[] lists, void delegate(size_t, size_t) swap, int startIndex, int[] indices, int count) { mixin(S_TRACE);
		std.algorithm.sort(indices);
		if (!indices.length) return;
		if (indices[0] != 0) { mixin(S_TRACE);
			foreach (j; 0 .. count) { mixin(S_TRACE);
				foreach (i; indices) { mixin(S_TRACE);
					i -= j;
					foreach (v; vs) v._imgp.swap(i + startIndex - 1, i + startIndex);
					swap(i - 1, i);
					foreach (list; lists) { mixin(S_TRACE);
						list.upItem(i);
						list.showSelection();
						list.redraw();
					}
				}
			}
		}
		foreach (v; vs) v.callModEvent();
	}
	static void downImpl2(T)(AbstractAreaView[] vs, Table[] lists, void delegate(size_t, size_t) swap, int startIndex, int[] indices, int cardsCount, int count) { mixin(S_TRACE);
		std.algorithm.sort(indices);
		if (!indices.length) return;
		if (indices[$ - 1] + 1 < cardsCount) { mixin(S_TRACE);
			foreach (j; 0 .. count) { mixin(S_TRACE);
				foreach_reverse (i; indices) { mixin(S_TRACE);
					i += j;
					foreach (v; vs) v._imgp.swap(i + startIndex + 1, i + startIndex);
					swap(i + 1, i);
					foreach (list; lists) { mixin(S_TRACE);
						list.downItem(i);
						list.showSelection();
						list.redraw();
					}
				}
			}
		}
		foreach (v; vs) v.callModEvent();
	}

	void posImpl(int First, string Cmp, string Get, string Set, string CSet, T)(int startIndex, T[] cs) { mixin(S_TRACE);
		if (_readOnly) return;
		int b = First;
		for (int i = startIndex; i < startIndex + cs.length; i++) { mixin(S_TRACE);
			auto a = cast(FlexImage)_imgp.images[i];
			if (a.selected && mixin(Cmp)) { mixin(S_TRACE);
				b = mixin(Get);
			}
		}
		auto vs = views();
		for (int i = startIndex; i < startIndex + cs.length; i++) { mixin(S_TRACE);
			auto img = cast(FlexImage)_imgp.images[i];
			if (img.selected) { mixin(S_TRACE);
				FlexImage a = null;
				foreach (v; vs) { mixin(S_TRACE);
					a = cast(FlexImage)v._imgp.images[i];
					assert (a !is null);
					v._imgp.redrawImage(a);
					mixin(Set ~ ";");
					a.resize();
					v._imgp.redrawImage(a);
				}
				auto c = cs[i - startIndex];
				mixin(CSet ~ ";");
				if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
					static if (is(T : AbstractSpCard)) {
						_comm.refMenuCard.call(c.cwxPath(true));
					} else static if (is(T : BgImage)) {
						_comm.refBgImage.call(c.cwxPath(true));
					} else static assert (0);
				}
			}
		}
		foreach (v; vs) {
			v.callModEvent();
			v.refreshControls();
		}
	}
	void posEvenImpl(T)(int startIndex, T[] cs) { mixin(S_TRACE);
		if (_readOnly) return;
		int right_w;
		int[FlexImage] indices;
		bool delegate(in FlexImage fi1, in FlexImage fi2) ficmpX;
		auto targs = posEvenTargs(startIndex, cs, indices, right_w, ficmpX);

		if (targs.length > 1) { mixin(S_TRACE);
			targs = .sortDlg(targs, ficmpX);
			int left = targs[0].x;
			int right = right_w - targs[$ - 1].width;
			for (int i = 0; i < targs.length; i++) { mixin(S_TRACE);
				auto a = targs[i];
				auto b = left + cast(int)rndtol(((right - left) / (targs.length - 1.0)) * i);
				_imgp.redrawImage(a);
				a.newX = b;
				a.resize();
				_imgp.redrawImage(a);
				auto c = cs[indices[a]];
				c.x = b;
				if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
					static if (is(T : AbstractSpCard)) {
						_comm.refMenuCard.call(c.cwxPath(true));
					} else static if (is(T : BgImage)) {
						_comm.refBgImage.call(c.cwxPath(true));
					} else static assert (0);
				}
			}
		}
		callModEvent();
	}
	bool canPosEvenImpl(T)(int startIndex, T[] cs) { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!canChangePos) return false;
		int right_w;
		int[FlexImage] indices;
		bool delegate(in FlexImage fi1, in FlexImage fi2) ficmpX;
		auto targs = posEvenTargs(startIndex, cs, indices, right_w, ficmpX);
		if (targs.length > 1) { mixin(S_TRACE);
			targs = .sortDlg(targs, ficmpX);
			int left = targs[0].x;
			int right = right_w - targs[$ - 1].width;
			for (int i = 0; i < targs.length; i++) { mixin(S_TRACE);
				auto b = left + cast(int)rndtol(((right - left) / (targs.length - 1.0)) * i);
				if (targs[i].x != b) return true;
			}
		}
		return false;
	}
	FlexImage[] posEvenTargs(T)(int startIndex, in T[] cs, out int[FlexImage] indices, out int right_w, out bool delegate(in FlexImage fi1, in FlexImage fi2) ficmpX) { mixin(S_TRACE);
		FlexImage[] targs;
		right_w = int.min;
		for (int i = 0; i < cs.length; i++) { mixin(S_TRACE);
			auto a = cast(FlexImage)_imgp.images[i + startIndex];
			if (a.selected) { mixin(S_TRACE);
				indices[a] = i;
				targs ~= a;
				int rw = a.x + a.width;
				if (right_w < rw) right_w = rw;
			}
		}
		int[const FlexImage] baseIndices;
		foreach (i, fimg; targs) { mixin(S_TRACE);
			baseIndices[fimg] = cast(int)i;
		}
		ficmpX = (fi1, fi2) { mixin(S_TRACE);
			auto x1 = fi1.x;
			auto x2 = fi2.x;
			if (x1 == x2) { mixin(S_TRACE);
				return baseIndices[fi1] < baseIndices[fi2];
			} else { mixin(S_TRACE);
				return x1 < x2;
			}
		};
		return targs;
	}
	static if (UseCards) {
		private void scaleC(uint scale) { mixin(S_TRACE);
			if (_readOnly) return;
			_undo ~= createUndoEdit();
			foreach (i, c; _area.cards) { mixin(S_TRACE);
				auto fi = cast(FlexImage)_imgp.images[cardsIndex + i];
				if (fi.selected) { mixin(S_TRACE);
					c.scale = scale;
					fi.newScale = scale;
					_imgp.redrawImage(fi);
					fi.resize();
					_imgp.redrawImage(fi);
				}
				if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
					_comm.refMenuCard.call(c.cwxPath(true));
				}
			}
			refreshControls();
			callModEvent();
		}
		private void scaleCMax() { mixin(S_TRACE);
			if (_readOnly) return;
			scaleC(_prop.var.etc.cardScaleMax);
		}
		private void scaleCMiddle() { mixin(S_TRACE);
			if (_readOnly) return;
			scaleC(100);
		}
		private void scaleCMin() { mixin(S_TRACE);
			if (_readOnly) return;
			scaleC(_prop.var.etc.cardScaleMin);
		}
		@property
		bool canScaleCAny(int scale) { mixin(S_TRACE);
			if (!canChangePos) return false;
			auto cScales = _cards.getSelectionIndices().map!(i => _imgp.images[cardsIndex + i].scale)();
			return cScales.any!(a => a != scale)();
		}
	}
	void scaleEvenImpl(int First, string Cmp, string CSet, T)(int delegate(AbstractAreaView) startIndex, T[] cs) { mixin(S_TRACE);
		if (_readOnly) return;
		int w = First;
		int h = First;
		int scale = First;
		for (int i = 0; i < cs.length; i++) { mixin(S_TRACE);
			auto fi = cast(FlexImage)_imgp.images[startIndex(this) + i];
			if (fi.selected) { mixin(S_TRACE);
				_imgp.redrawImage(fi);
				int a, b;
				a = fi.width;
				b = w;
				if (mixin(Cmp)) w = a;
				a = fi.height;
				b = h;
				if (mixin(Cmp)) h = a;
				a = fi.scale;
				b = scale;
				if (mixin(Cmp)) scale = a;
				_imgp.redrawImage(fi);
			}
		}
		auto vs = views();
		for (int i = 0; i < cs.length; i++) { mixin(S_TRACE);
			auto fi = cast(FlexImage)_imgp.images[startIndex(this) + i];
			if (fi.selected) { mixin(S_TRACE);
				foreach (v; vs) { mixin(S_TRACE);
					auto fi2 = cast(FlexImage)v._imgp.images[startIndex(v) + i];
					v._imgp.redrawImage(fi2);
					if (fi2.scaleMode) { mixin(S_TRACE);
						fi2.newScale = scale;
					} else { mixin(S_TRACE);
						fi2.newWidth = w;
						fi2.newHeight = h;
					}
					fi2.resize();
					v._imgp.redrawImage(fi2);
				}
				auto a = cs[i];
				mixin(CSet);
				if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
					_comm.refMenuCard.call(a.cwxPath(true));
				}
			}
		}
		foreach (v; vs) { mixin(S_TRACE);
			v.callModEvent();
			v.refreshControls();
		}
	}
	@property
	bool canPosAny(int delegate(in PileImage) func) { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!canChangePos) return false;
		static if (UseCards) {
			auto cVals = _cards.getSelectionIndices().map!(i => func(_imgp.images[cardsIndex + i]))();
			if (!cVals.isUniform) return true;
		}
		static if (UseBacks) {
			auto bVals = _backs.getSelectionIndices().map!(i => func(_imgp.images[i]))();
			if (!bVals.isUniform) return true;
		}
		return false;
	}
	@property
	bool canPosTop() { return canPosAny(fi => fi.y); }
	@property
	bool canPosBottom() { return canPosAny(fi => fi.y + fi.height); }
	@property
	bool canPosLeft() { return canPosAny(fi => fi.x); }
	@property
	bool canPosRight() { return canPosAny(fi => fi.x + fi.width); }

	void posTopImpl(T)(int startIndex, T[] cs) { mixin(S_TRACE);
		if (_readOnly) return;
		posImpl!(int.max, "a.y < b", "a.y", "a.newY = b", "c.y = a.y", T)(startIndex, cs);
	}
	void posBottomImpl(T)(int startIndex, T[] cs) { mixin(S_TRACE);
		if (_readOnly) return;
		posImpl!(int.min, "a.y + a.height > b", "a.y + a.height", "a.newY = b - a.height", "c.y = a.y", T)(startIndex, cs);
	}
	void posLeftImpl(T)(int startIndex, T[] cs) { mixin(S_TRACE);
		if (_readOnly) return;
		posImpl!(int.max, "a.x < b", "a.x", "a.newX = b", "c.x = a.x", T)(startIndex, cs);
	}
	void posRightImpl(T)(int startIndex, T[] cs) { mixin(S_TRACE);
		if (_readOnly) return;
		posImpl!(int.min, "a.x + a.width > b", "a.x + a.width", "a.newX = b - a.width", "c.x = a.x", T)(startIndex, cs);
	}
	bool canChangePos() { mixin(S_TRACE);
		bool r = false;
		static if (UseCards) r |= 0 < _cards.getSelectionCount();
		static if (UseBacks) r |= 0 < _backs.getSelectionCount();
		return r && !_readOnly;
	}
	void posTop() { mixin(S_TRACE);
		if (_readOnly) return;
		_undo ~= createUndoEdit();
		static if (UseCards) posTopImpl!(C)(cardsIndex, _area.cards);
		static if (UseBacks) posTopImpl!(BgImage)(0, _area.backs);
	}
	void posBottom() { mixin(S_TRACE);
		if (_readOnly) return;
		_undo ~= createUndoEdit();
		static if (UseCards) posBottomImpl!(C)(cardsIndex, _area.cards);
		static if (UseBacks) posBottomImpl!(BgImage)(0, _area.backs);
	}
	void posLeft() { mixin(S_TRACE);
		if (_readOnly) return;
		_undo ~= createUndoEdit();
		static if (UseCards) posLeftImpl!(C)(cardsIndex, _area.cards);
		static if (UseBacks) posLeftImpl!(BgImage)(0, _area.backs);
	}
	void posRight() { mixin(S_TRACE);
		if (_readOnly) return;
		_undo ~= createUndoEdit();
		static if (UseCards) posRightImpl!(C)(cardsIndex, _area.cards);
		static if (UseBacks) posRightImpl!(BgImage)(0, _area.backs);
	}
	void posEven() { mixin(S_TRACE);
		if (_readOnly) return;
		_undo ~= createUndoEdit();
		static if (UseCards) posEvenImpl!(C)(cardsIndex, _area.cards);
		static if (UseBacks) posEvenImpl!(BgImage)(0, _area.backs);
	}
	@property
	bool canPosEven() {
		if (_readOnly) return false;
		if (!canChangePos) return false;
		static if (UseCards) {
			if (canPosEvenImpl!C(cardsIndex, _area.cards)) return true;
		}
		static if (UseBacks) {
			if (canPosEvenImpl!BgImage(0, _area.backs)) return true;
		}
		return false;
	}
	void nearTop() { mixin(S_TRACE);
		if (_readOnly) return;
		_undo ~= createUndoEdit();
		static if (UseCards) nearTopImpl((v) => v.cardsIndex, _area.cards, true);
		static if (UseBacks) nearTopImpl((v) => 0, _area.backs, false);
	}
	bool canNearTop() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!canChangePos) return false;
		static if (UseCards) {
			if (canNearTopImpl((v) => v.cardsIndex, _area.cards, true)) return true;
		}
		static if (UseBacks) {
			if (canNearTopImpl((v) => 0, _area.backs, false)) return true;
		}
		return false;
	}
	void nearBottom() { mixin(S_TRACE);
		if (_readOnly) return;
		_undo ~= createUndoEdit();
		static if (UseCards) nearBottomImpl((v) => v.cardsIndex, _area.cards, true);
		static if (UseBacks) nearBottomImpl((v) => 0, _area.backs, false);
	}
	bool canNearBottom() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!canChangePos) return false;
		static if (UseCards) {
			if (canNearBottomImpl((v) => v.cardsIndex, _area.cards, true)) return true;
		}
		static if (UseBacks) {
			if (canNearBottomImpl((v) => 0, _area.backs, false)) return true;
		}
		return false;
	}
	void nearLeft() { mixin(S_TRACE);
		if (_readOnly) return;
		_undo ~= createUndoEdit();
		static if (UseCards) nearLeftImpl((v) => v.cardsIndex, _area.cards, true);
		static if (UseBacks) nearLeftImpl((v) => 0, _area.backs, false);
	}
	bool canNearLeft() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!canChangePos) return false;
		static if (UseCards) {
			if (canNearLeftImpl((v) => v.cardsIndex, _area.cards, true)) return true;
		}
		static if (UseBacks) {
			if (canNearLeftImpl((v) => 0, _area.backs, false)) return true;
		}
		return false;
	}
	void nearRight() { mixin(S_TRACE);
		if (_readOnly) return;
		_undo ~= createUndoEdit();
		static if (UseCards) nearRightImpl((v) => v.cardsIndex, _area.cards, true);
		static if (UseBacks) nearRightImpl((v) => 0, _area.backs, false);
	}
	bool canNearRight() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!canChangePos) return false;
		static if (UseCards) {
			if (canNearRightImpl((v) => v.cardsIndex, _area.cards, true)) return true;
		}
		static if (UseBacks) {
			if (canNearRightImpl((v) => 0, _area.backs, false)) return true;
		}
		return false;
	}
	void nearCenterH() { nearCenterImpl1(true, false); }
	void nearCenterV() { nearCenterImpl1(false, true); }
	void nearCenter() { nearCenterImpl1(true, true); }
	void nearCenterImpl1(bool h, bool v) { mixin(S_TRACE);
		if (_readOnly) return;
		_undo ~= createUndoEdit();
		static if (UseCards) nearCenterImpl2((v) => v.cardsIndex, _area.cards, true, h, v);
		static if (UseBacks) nearCenterImpl2((v) => 0, _area.backs, false, h, v);
	}
	bool canNearCenter(bool h, bool v) { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!canChangePos) return false;
		static if (UseCards) {
			if (canNearCenterImpl((v) => v.cardsIndex, _area.cards, true, h, v)) return true;
		}
		static if (UseBacks) {
			if (canNearCenterImpl((v) => 0, _area.backs, false, h, v)) return true;
		}
		return false;
	}
	void nearTopImpl(T)(int delegate(AbstractAreaView) startIndex, T[] cs, bool refParty) { mixin(S_TRACE);
		if (_readOnly) return;
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		if (!getItemPositions(startIndex(this), cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH)) return;
		nearImpl(startIndex, cs, 0, -itemsT);
	}
	bool canNearTopImpl(T)(int delegate(AbstractAreaView) startIndex, T[] cs, bool refParty) { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!canChangePos) return false;
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		if (!getItemPositions(startIndex(this), cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH)) return false;
		return itemsT != 0;
	}
	void nearBottomImpl(T)(int delegate(AbstractAreaView) startIndex, T[] cs, bool refParty) { mixin(S_TRACE);
		if (_readOnly) return;
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		if (!getItemPositions(startIndex(this), cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH)) return;
		nearImpl(startIndex, cs, 0, canvasH - itemsH - itemsT);
	}
	bool canNearBottomImpl(T)(int delegate(AbstractAreaView) startIndex, T[] cs, bool refParty) { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!canChangePos) return false;
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		if (!getItemPositions(startIndex(this), cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH)) return false;
		return canvasH - itemsH - itemsT != 0;
	}
	void nearLeftImpl(T)(int delegate(AbstractAreaView) startIndex, T[] cs, bool refParty) { mixin(S_TRACE);
		if (_readOnly) return;
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		if (!getItemPositions(startIndex(this), cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH)) return;
		nearImpl(startIndex, cs, -itemsL, 0);
	}
	bool canNearLeftImpl(T)(int delegate(AbstractAreaView) startIndex, T[] cs, bool refParty) { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!canChangePos) return false;
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		if (!getItemPositions(startIndex(this), cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH)) return false;
		return itemsL != 0;
	}
	void nearRightImpl(T)(int delegate(AbstractAreaView) startIndex, T[] cs, bool refParty) { mixin(S_TRACE);
		if (_readOnly) return;
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		if (!getItemPositions(startIndex(this), cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH)) return;
		nearImpl(startIndex, cs, canvasW - itemsW - itemsL, 0);
	}
	bool canNearRightImpl(T)(int delegate(AbstractAreaView) startIndex, T[] cs, bool refParty) { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!canChangePos) return false;
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		if (!getItemPositions(startIndex(this), cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH)) return false;
		return canvasW - itemsW - itemsL != 0;
	}
	void nearCenterImpl2(T)(int delegate(AbstractAreaView) startIndex, T[] cs, bool refParty, bool h, bool v) { mixin(S_TRACE);
		if (_readOnly) return;
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		if (!getItemPositions(startIndex(this), cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH)) return;

		int x = h ? (canvasW - itemsW) / 2 : itemsL;
		int y = v ? (canvasH - itemsH) / 2 : itemsT;
		int moveX = x - itemsL;
		int moveY = y - itemsT;
		nearImpl(startIndex, cs, moveX, moveY);
	}
	bool canNearCenterImpl(T)(int delegate(AbstractAreaView) startIndex, T[] cs, bool refParty, bool h, bool v) { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!canChangePos) return false;
		int canvasW, canvasH, itemsL, itemsT, itemsW, itemsH;
		if (!getItemPositions(startIndex(this), cs.length, refParty, canvasW, canvasH, itemsL, itemsT, itemsW, itemsH)) return false;

		int x = h ? (canvasW - itemsW) / 2 : itemsL;
		int y = v ? (canvasH - itemsH) / 2 : itemsT;
		int moveX = x - itemsL;
		int moveY = y - itemsT;
		return moveX || moveY;
	}
	bool getItemPositions(int startIndex, size_t count, bool refParty,
			out int canvasW, out int canvasH,
			out int itemsL, out int itemsT,
			out int itemsW, out int itemsH) { mixin(S_TRACE);
		auto vs = _prop.looks.viewSize;
		canvasW = vs.width;
		canvasH = refParty && _viewParty ? _prop.looks.partyTop : vs.height;

		itemsL = int.max;
		itemsT = int.max;
		int itemsR = int.min, itemsB = int.min;
		auto selected = false;
		foreach (i; startIndex .. startIndex + count) { mixin(S_TRACE);
			auto img = cast(FlexImage)_imgp.images[i];
			assert (img !is null);
			if (img.selected) { mixin(S_TRACE);
				selected = true;
				itemsL = .min(itemsL, img.x);
				itemsT = .min(itemsT, img.y);
				itemsR = .max(itemsR, img.x + img.width);
				itemsB = .max(itemsB, img.y + img.height);
			}
		}
		itemsW = itemsR - itemsL;
		itemsH = itemsB - itemsT;
		return selected;
	}
	void nearImpl(T)(int delegate(AbstractAreaView) startIndex, T[] cs, int moveX, int moveY) { mixin(S_TRACE);
		if (_readOnly) return;
		auto vs = views();
		foreach (i, c; cs) { mixin(S_TRACE);
			auto img = cast(FlexImage)_imgp.images[startIndex(this) + i];
			assert (img !is null);
			if (img.selected) { mixin(S_TRACE);
				c.x = c.x + moveX;
				c.y = c.y + moveY;
				foreach (v; vs) { mixin(S_TRACE);
					auto fi = cast(FlexImage)_imgp.images[startIndex(v) + i];
					v._imgp.redrawImage(fi);
					fi.newX = c.x;
					fi.newY = c.y;
					fi.resize();
					v._imgp.redrawImage(fi);
				}
				if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
					static if (is(T:AbstractSpCard)) {
						_comm.refMenuCard.call(c.cwxPath(true));
					} else static if (is(T:BgImage)) {
						_comm.refBgImage.call(c.cwxPath(true));
					} else static assert (0);
				}
			}
		}
		foreach (v; vs) { mixin(S_TRACE);
			v.callModEvent();
			v.refreshControls();
		}
	}
	static if (UseBacks) {
		void expandBacks() { mixin(S_TRACE);
			if (_readOnly) return;
			_undo ~= createUndoEdit();
			auto vSize = _prop.looks.viewSize;
			auto vs = views();
			foreach (i, back; _area.backs) { mixin(S_TRACE);
				auto img = cast(FlexImage)_imgp.images[0 + i];
				assert (img !is null);
				if (img.selected) { mixin(S_TRACE);
					back.x = 0;
					back.y = 0;
					back.width = vSize.width;
					back.height = vSize.height;
					foreach (v; vs) { mixin(S_TRACE);
						auto img2 = cast(FlexImage)v._imgp.images[0 + i];
						v._imgp.redrawImage(img2);
						img2.newX = back.x;
						img2.newY = back.y;
						img2.newWidth = back.width;
						img2.newHeight = back.height;
						img2.resize();
						v._imgp.redrawImage(img2);
					}
					if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
						_comm.refBgImage.call(back.cwxPath(true));
					}
				}
			}
			foreach (v; vs) { mixin(S_TRACE);
				v.callModEvent();
				v.refreshControls();
			}
		}
		@property
		bool canExpandBacks() { mixin(S_TRACE);
			if (_readOnly || 0 == _backs.getSelectionCount()) return false;
			auto vSize = _prop.looks.viewSize;
			foreach (i, back; _area.backs) { mixin(S_TRACE);
				auto img = cast(FlexImage)_imgp.images[0 + i];
				assert (img !is null);
				if (img.selected) { mixin(S_TRACE);
					if (back.x != 0 || back.y != 0 || back.width != vSize.width || back.height != vSize.height) return true;
				}
			}
			return false;
		}
	}
	static if (UseCards) {
		void scaleEvenC(int First, string Cmp)() { mixin(S_TRACE);
			if (_readOnly) return;
			scaleEvenImpl!(First, Cmp, "a.scale = scale;", C)((v) => v.cardsIndex, _area.cards);
		}
	}
	static if (UseBacks) {
		void scaleEvenB(int First, string Cmp)() { mixin(S_TRACE);
			if (_readOnly) return;
			scaleEvenImpl!(First, Cmp, "a.width = w, a.height = h;", BgImage)((v) => 0, _area.backs);
		}
	}
	void scaleEvenBig() { mixin(S_TRACE);
		if (_readOnly) return;
		_undo ~= createUndoEdit();
		static if (UseCards) scaleEvenC!(int.min, "a > b")();
		static if (UseBacks) scaleEvenB!(int.min, "a > b")();
	}
	void scaleEvenSmall() { mixin(S_TRACE);
		if (_readOnly) return;
		_undo ~= createUndoEdit();
		static if (UseCards) scaleEvenC!(int.max, "a < b")();
		static if (UseBacks) scaleEvenB!(int.max, "a < b")();
	}
	@property
	bool canScaleEvenAny() { mixin(S_TRACE);
		if (!canChangePos) return false;
		static if (UseCards) {
			auto cScales = _cards.getSelectionIndices().map!(i => _imgp.images[cardsIndex + i].scale)();
			if (!cScales.isUniform) return true;
		}
		static if (UseBacks) {
			auto bScales = _backs.getSelectionIndices().map!(i => _imgp.images[i].scale)();
			if (!bScales.isUniform) return true;
		}
		return false;
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
		return !_readOnly && _imgp.selectedIndex != -1 && !_imgp.isMoving;
	}
	void editImagePane(int[] indices) { mixin(S_TRACE);
		if (_readOnly) return;
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
		_imgp.wallpaperStyle = cast(WallpaperStyle)_prop.var.etc.wallpaperStyle;
	}
	Control createImagePane(Composite parent) { mixin(S_TRACE);
		auto sc = new ScrolledComposite(parent, SWT.H_SCROLL | SWT.V_SCROLL);
		sc.setExpandHorizontal(false);
		sc.setExpandVertical(false);
		sc.setLayoutData(new GridData(GridData.FILL_BOTH));

		auto vs = _prop.looks.viewSize;
		_imgp = new ImagePane(sc, SWT.BORDER | SWT.NO_BACKGROUND | _readOnly, vs.width, vs.height, _prop.var.etc.imageScale, _prop.drawingScale);
		_imgp.drawXORSelectionLine = _prop.var.etc.drawXORSelectionLine;
		_imgp.resizingImageWithRatio = _prop.var.etc.resizingImageWithRatio;

		void refImageScale() { mixin(S_TRACE);
			auto vs = _prop.looks.viewSize;
			vs.width = _prop.s(vs.width);
			vs.height = _prop.s(vs.height);
			sc.getHorizontalBar().setIncrement(vs.width / 20);
			sc.getVerticalBar().setIncrement(vs.height / 20);
			sc.getHorizontalBar().setPageIncrement(vs.width / 5);
			sc.getVerticalBar().setPageIncrement(vs.height / 5);
			auto rect = _imgp.computeSize(vs.width, vs.height);
			sc.setMinSize(rect.x, rect.y);
			_imgp.setSize(rect.x, rect.y);
			_imgp.imageScale = _prop.var.etc.imageScale;
			_imgp.drawingScale = _prop.drawingScale;
			if (_imgp.images.length) refreshPanel();
		}
		void refSwitchFixedWithCheckBox() { mixin(S_TRACE);
			if (!_prop.var.etc.switchFixedWithCheckBox) { mixin(S_TRACE);
				auto changed = false;
				static if (UseCards) {
					foreach (itm; _cards.getItems()) { mixin(S_TRACE);
						if (itm.getGrayed()) { mixin(S_TRACE);
							itm.setGrayed(false);
							changed = true;
						}
					}
				}
				static if (UseBacks) {
					foreach (itm; _backs.getItems()) { mixin(S_TRACE);
						if (itm.getGrayed()) { mixin(S_TRACE);
							itm.setGrayed(false);
							changed = true;
						}
					}
				}
				if (changed) checked();
			}
		}
		static if (UseCards) {
			void refImagePaneSelectionFilter() { mixin(S_TRACE);
				_imgp.resizingImageWithRatio = _prop.var.etc.resizingImageWithRatio;
				_imgp.drawXORSelectionLine = _prop.var.etc.drawXORSelectionLine;
				foreach (i, itm; _cards.getItems()) { mixin(S_TRACE);
					auto fi = cast(FlexImage)_imgp.images[cardsIndex + i];
					assert (fi !is null);
					if (fi.hasSelectionFilter != _prop.var.etc.showSceneViewSelectionFilter) { mixin(S_TRACE);
						fi.hasSelectionFilter = _prop.var.etc.showSceneViewSelectionFilter;
						if (fi.selected && fi.visible) _imgp.redrawImage(fi);
					}
				}
			}
		}

		static if (UseCards && UseBacks) {
			_imgp.cancelFullRedraw();
		}
		_imgp.highPoint = _prop.var.etc.highValueOfImageControl;
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
		_comm.refImageScale.add(&refImageScale);
		_comm.refSwitchFixedWithCheckBox.add(&refSwitchFixedWithCheckBox);
		static if (UseCards) {
			_comm.refImagePaneSelectionFilter.add(&refImagePaneSelectionFilter);
		}
		_imgp.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				_imgp.setBackgroundImage(cast(Image)null);
				_comm.refWallpaper.remove(&refreshWallpaper);
				_comm.refImageScale.remove(&refImageScale);
				_comm.refSwitchFixedWithCheckBox.remove(&refSwitchFixedWithCheckBox);
				static if (UseCards) {
					_comm.refImagePaneSelectionFilter.remove(&refImagePaneSelectionFilter);
				}
			}
		});
		refreshWallpaper();
		sc.setContent(_imgp);
		refImageScale();
		auto ipe = new IPEditListener;
		_imgp.addMouseListener(ipe);
		_imgp.changingImages(&changingImages);
		_imgp.rangeSelectable = (in FlexImage img) { mixin(S_TRACE);
			if (_prop.var.etc.ignoreBackgroundInRange) { mixin(S_TRACE);
				auto vs = _prop.looks.viewSize;
				return img.x != 0 || img.y != 0 || img.width != vs.width || img.height != vs.height;
			}
			return true;
		};
		{ mixin(S_TRACE);
			auto menu = new Menu(parent.getShell(), SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.EditProp, &edit, &canEdit);
			if (!_readOnly) { mixin(S_TRACE);
				static if (is(A : Area)) {
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(_comm, menu, MenuID.NewMenuCard, &createCard, () => !_readOnly);
				} else static if (is(A : Battle)) {
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(_comm, menu, MenuID.NewEnemyCard, &createCard, () => !_readOnly && _summ && _summ.casts.length);
				}
				static if (UseBacks) {
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(_comm, menu, MenuID.NewBack, &createBackground, () => !_readOnly);
					createMenuItem(_comm, menu, MenuID.NewTextCell, &createTextCell, () => !_readOnly);
					createMenuItem(_comm, menu, MenuID.NewColorCell, &createColorCell, () => !_readOnly);
					createMenuItem(_comm, menu, MenuID.NewPCCell, &createPCCell, () => !_readOnly && !(_summ && _summ.legacy));
				}
			}
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_comm, menu, _tcpd, !_readOnly, true, !_readOnly, !_readOnly, !_readOnly);
			static if (is(A : Area)) {
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.EditEvent, () => openEvent(false), null);
			} else static if (is(A : Battle)) {
				new MenuItem(menu, SWT.SEPARATOR);
				auto itm = createMenuItem(_comm, menu, MenuID.EditEvent, () => openEvent(false), null);
				itm.setImage(_prop.images.editEventBattle);
			}
			if (_summ) { mixin(S_TRACE);
				new MenuItem(menu, SWT.SEPARATOR);
				createMenuItem(_comm, menu, MenuID.SelectConnectedResource, &selectConnectedResource, &canSelectConnectedResource);
			}
			new MenuItem(menu, SWT.SEPARATOR);
			_sgPMenu = createMenuItem(_comm, menu, MenuID.ShowGrid, &reverseShowGrid, null, SWT.CHECK);
			.setupToggle(_sgPMenu, _prop.var.etc.showGrid);

			if (!_readOnly) { mixin(S_TRACE);
				new MenuItem(menu, SWT.SEPARATOR);
				void delegate(SelectionEvent) dummy = null;
				auto chgPosMI = createMenuItem(_comm, menu, MenuID.ChangePos, dummy, &canChangePos, SWT.CASCADE);
				auto chgPos = new Menu(chgPosMI);
				chgPosMI.setMenu(chgPos);
				createMenuItem(_comm, chgPos, MenuID.NearTop, &nearTop, &canNearTop);
				createMenuItem(_comm, chgPos, MenuID.NearBottom, &nearBottom, &canNearBottom);
				createMenuItem(_comm, chgPos, MenuID.NearLeft, &nearLeft, &canNearLeft);
				createMenuItem(_comm, chgPos, MenuID.NearRight, &nearRight, &canNearRight);
				createMenuItem(_comm, chgPos, MenuID.NearCenterH, &nearCenterH, () => canNearCenter(true, false));
				createMenuItem(_comm, chgPos, MenuID.NearCenterV, &nearCenterV, () => canNearCenter(false, true));
				createMenuItem(_comm, chgPos, MenuID.NearCenter, &nearCenter, () => canNearCenter(true, true));
				new MenuItem(chgPos, SWT.SEPARATOR);
				createMenuItem(_comm, chgPos, MenuID.PosTop, &posTop, &canPosTop);
				createMenuItem(_comm, chgPos, MenuID.PosBottom, &posBottom, &canPosBottom);
				createMenuItem(_comm, chgPos, MenuID.PosLeft, &posLeft, &canPosLeft);
				createMenuItem(_comm, chgPos, MenuID.PosRight, &posRight, &canPosRight);
				createMenuItem(_comm, chgPos, MenuID.PosEven, &posEven, &canPosEven);
				static if (UseCards) {
					new MenuItem(chgPos, SWT.SEPARATOR);
					createMenuItem(_comm, chgPos, MenuID.ScaleMin, &scaleCMin, () => canScaleCAny(_prop.var.etc.cardScaleMin));
					createMenuItem(_comm, chgPos, MenuID.ScaleMiddle, &scaleCMiddle, () => canScaleCAny(100));
					createMenuItem(_comm, chgPos, MenuID.ScaleMax, &scaleCMax, () => canScaleCAny(_prop.var.etc.cardScaleMax));
				}
				new MenuItem(chgPos, SWT.SEPARATOR);
				createMenuItem(_comm, chgPos, MenuID.ScaleBig, &scaleEvenBig, &canScaleEvenAny);
				createMenuItem(_comm, chgPos, MenuID.ScaleSmall, &scaleEvenSmall, &canScaleEvenAny);
				static if (UseBacks) {
					new MenuItem(chgPos, SWT.SEPARATOR);
					createMenuItem(_comm, chgPos, MenuID.ExpandBack, &expandBacks, &canExpandBacks);
				}
			}

			_imgp.setMenu(menu);
		}
		_imgp.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				auto pane = cast(ImagePane)e.widget;
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

		_flagList = .rangeSelectableTable(comp, SWT.SINGLE | SWT.CHECK | SWT.BORDER | SWT.H_SCROLL | SWT.V_SCROLL);
		new FullTableColumn(_flagList, SWT.NONE);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = 0;
		gd.heightHint = 0;
		_flagList.setLayoutData(gd);

		_refFlagIncSearch = new IncSearch(_comm, _flagList, () => _hasFlags);
		_refFlagIncSearch.modEvent ~= &refreshFlags;

		auto menu = new Menu(_flagList.getShell(), SWT.POP_UP);
		createMenuItem(_comm, menu, MenuID.IncSearch, &flagIncSearch, () => _hasFlags);
		if (!_readOnly) { mixin(S_TRACE);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.OpenAtVarView, &openFlagViewL,
				() => !_readOnly && _flagList.getSelectionIndex() != -1
				&& cast(cwx.flag.Flag)_flagList.getItem(_flagList.getSelectionIndex()).getData());
		}
		_flagList.setMenu(menu);

		_flagAllCheck = new Button(comp, SWT.CHECK);
		_flagAllCheck.setText(_prop.msgs.allCheckFlag);
		_flagAllCheck.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		.listener(_flagAllCheck, SWT.Selection, { mixin(S_TRACE);
			foreach (itm; _flagList.getItems()) { mixin(S_TRACE);
				itm.setChecked(_flagAllCheck.getSelection());
				itm.setGrayed(false);
			}
			checkFlagImpl();
		});
		.listener(_flagList, SWT.Selection, &checkFlag);

		if (summ && summ.scenarioPath != "" && !_readOnly) { mixin(S_TRACE);
			_comm.refFlagAndStep.add(&refFlags);
			_comm.delFlagAndStep.add(&delFlags);
			.listener(_flag, SWT.Dispose, { mixin(S_TRACE);
				_comm.refFlagAndStep.remove(&refFlags);
				_comm.delFlagAndStep.remove(&delFlags);
			});
		}
	}
	void refFlags(cwx.flag.Flag[] f, Step[] s, cwx.flag.Variant[] v) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!_summ) return;
		if (!f.length) return;
		refreshFlags();
	}
	void delFlags(cwx.flag.Flag[] f, Step[] s, cwx.flag.Variant[] v) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!_summ) return;
		if (!f.length) return;
		refreshFlags();
	}
	void refreshFlags() { mixin(S_TRACE);
		if (!_flagList) return;
		if (_comm.inReplaceText) return;
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
		_hasFlags = false;
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
				nof.setText(_prop.msgs.defaultSelection(_prop.msgs.noFlagRef));
				nof.setImage(_prop.images.emptyIcon);
			} else { mixin(S_TRACE);
				static if (is(A:BgImageContainer)) {
					auto flag = .findVar!(cwx.flag.Flag)(_summ ? _summ.flagDirRoot : null, null, path);
				} else {
					auto flag = .findVar!(cwx.flag.Flag)(_summ.flagDirRoot, _area.useCounter, path);
				}
				if (!has && path == sel) { mixin(S_TRACE);
					has = true;
				}
				_hasFlags = true;
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
	void openFlagViewL() { mixin(S_TRACE);
		if (_readOnly) return;
		if (!_flagList) return;
		auto i = _flagList.getSelectionIndex();
		if (-1 == i) return;
		auto a = cast(cwx.flag.Flag)_flagList.getItem(i).getData();
		if (!a) return;
		try { mixin(S_TRACE);
			_comm.openCWXPath(cpaddattr(a.cwxPath(true), "shallow"), false);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
	void checkFlag(Event e) { mixin(S_TRACE);
		if (!_flagList) return;
		if (e.detail != SWT.CHECK) return;
		updateChecked(e);
		if (e && cast(TableItem)e.item) { mixin(S_TRACE);
			auto itm = cast(TableItem)e.item;
			itm.setGrayed(false);
		}
		auto allChecked = checkFlagImpl();
		_flagAllCheck.setSelection(allChecked && _flagList.getItemCount());
	}
	bool checkFlagImpl() { mixin(S_TRACE);
		bool[string] useFlags;
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
		return allChecked;
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
		if (_readOnly) return;
		_undo ~= createUndoEdit();
		_comm.refreshToolBar();
	}

	private bool _refreshControls = false;
	void refreshControls() { mixin(S_TRACE);
		_refreshControls = true;
		_toolbar.redraw();
	}

	private void updateFlagCombo() { mixin(S_TRACE);
		if (!_flag) return;
		auto f = "";
		bool breaked = false;
		void flag(string f2) { mixin(S_TRACE);
			if (f == "") { mixin(S_TRACE);
				f = f2;
			} else if (f != f2) { mixin(S_TRACE);
				f = "";
				breaked = true;
			}
		}
		static if (UseCards) {
			foreach (c; _editC.keys) { mixin(S_TRACE);
				if (breaked) break;
				flag(c.flag);
			}
		}
		static if (UseBacks) {
			foreach (b; _editB.keys) { mixin(S_TRACE);
				if (breaked) break;
				flag(b.flag);
			}
		}
		auto s = f == "" ? _flag.getItem(0) : f;
		if (s != _flag.getText()) _flag.setText(s);
		static if (UseCards && UseBacks) {
			_flag.setEnabled(!_readOnly && (_editC.length || _editB.length));
		} else static if (UseCards) {
			_flag.setEnabled(!_readOnly && _editC.length > 0);
		} else static if (UseBacks) {
			_flag.setEnabled(!_readOnly && _editB.length > 0);
		}
	}
	private static bool valid(Args...)(Args ctrls) { mixin(S_TRACE);
		foreach (ctrl; ctrls) { mixin(S_TRACE);
			if (!ctrl || ctrl.isDisposed()) return false;
		}
		return true;
	}
	void refreshControlsImpl() { mixin(S_TRACE);
		if (!_xSpn) return;
		if (!_refreshControls) return;
		scope (exit) _refreshControls = false;
		static if (UseCards && UseBacks) {
			if (!valid(_imgp, _xSpn, _ySpn, _wSpn, _hSpn, _layerSpn, _maskTMenu, _scaleSpn)) return;
			_imgp.cancelFullRedraw();
			_xSpn.setEnabled(!_readOnly && (_editC.length || _editB.length));
			_ySpn.setEnabled(!_readOnly && _xSpn.getEnabled());
			_wSpn.setEnabled(!_readOnly && _editB.length > 0);
			_hSpn.setEnabled(!_readOnly && _wSpn.getEnabled());
			_layerSpn.setEnabled(!_readOnly && (!_summ || !_summ.legacy) && _xSpn.getEnabled());
			bool maskEnabled = false;
			foreach (back; _editB.keys) { mixin(S_TRACE);
				if (cast(ImageCell)back) { mixin(S_TRACE);
					maskEnabled = true;
					break;
				}
			}
			_maskTMenu.setEnabled(!_readOnly && maskEnabled);
			_scaleSpn.setEnabled(!_readOnly && _editC.length > 0);
			if (_editC.length == 1) { mixin(S_TRACE);
				auto card = _editC.keys[0];
				_scaleSpn.setSelection(card.scale);
				if (_editB.length == 0) { mixin(S_TRACE);
					_xSpn.setSelection(card.x);
					_ySpn.setSelection(card.y);
					_layerSpn.setSelection(card.layer);
				}
			} else if (_editC.length > 1) { mixin(S_TRACE);
				_scaleSpn.setSelection(spnValue!("a.scale", C, int)(_editC.keys, 100));
			}
			if (_editB.length == 1) { mixin(S_TRACE);
				auto back = _editB.keys[0];
				_wSpn.setSelection(back.width);
				_hSpn.setSelection(back.height);
				_maskTMenu.setSelection(cast(ImageCell)back && back.mask);
				if (_editC.length == 0) { mixin(S_TRACE);
					_xSpn.setSelection(back.x);
					_ySpn.setSelection(back.y);
					_layerSpn.setSelection(back.layer);
				}
			} else if (_editB.length > 1) { mixin(S_TRACE);
				_wSpn.setSelection(spnValue!("a.width", BgImage, int)(_editB.keys, 0));
				_hSpn.setSelection(spnValue!("a.height", BgImage, int)(_editB.keys, 0));
				BgImage[] ics = [];
				foreach (b; _editB.keys) { mixin(S_TRACE);
					if (auto ic = cast(ImageCell)b)ics ~= ics;
				}
				_maskTMenu.setSelection(spnValue!("a.mask", BgImage, bool)(ics, 0));
			}
			if (_editC.length + _editB.length > 1) { mixin(S_TRACE);
				if (_editC.length == 0) { mixin(S_TRACE);
					_xSpn.setSelection(spnValue!("a.x", BgImage, int)(_editB.keys, 0));
					_ySpn.setSelection(spnValue!("a.y", BgImage, int)(_editB.keys, 0));
					_layerSpn.setSelection(spnValue!("a.layer", BgImage, int)(_editB.keys, 0));
				} else if (_editB.length == 0) { mixin(S_TRACE);
					_xSpn.setSelection(spnValue!("a.x", C, int)(_editC.keys, 0));
					_ySpn.setSelection(spnValue!("a.y", C, int)(_editC.keys, 0));
					_layerSpn.setSelection(spnValue!("a.layer", C, int)(_editC.keys, 0));
				} else { mixin(S_TRACE);
					int x = spnValue!("a.x", C, int)(_editC.keys, 0);
					_xSpn.setSelection(x == spnValue!("a.x", BgImage, int)(_editB.keys, 0) ? x : 0);
					int y = spnValue!("a.y", C, int)(_editC.keys, 0);
					_ySpn.setSelection(y == spnValue!("a.y", BgImage, int)(_editB.keys, 0) ? y : 0);
					int layer = spnValue!("a.layer", C, int)(_editC.keys, 0);
					_layerSpn.setSelection(layer == spnValue!("a.layer", BgImage, int)(_editB.keys, 0) ? layer : 0);
				}
			}
			updateInheritBacks();
		} else static if (UseCards) {
			if (!valid(_imgp, _xSpn, _ySpn, _layerSpn, _scaleSpn)) return;
			static if (is(C == EnemyCard)) {
				if (!valid(_escTMenu)) return;
			}
			bool enbl = !_readOnly && _editC.length > 0;
			_xSpn.setEnabled(enbl);
			_ySpn.setEnabled(enbl);
			_scaleSpn.setEnabled(enbl);
			_layerSpn.setEnabled(enbl && (!_summ || !_summ.legacy));
			static if (is(C == EnemyCard)) {
				_escTMenu.setEnabled(enbl);
			}
			if (_editC.length == 1) { mixin(S_TRACE);
				auto card = _editC.keys[0];
				_xSpn.setSelection(card.x);
				_ySpn.setSelection(card.y);
				_scaleSpn.setSelection(card.scale);
				_layerSpn.setSelection(card.layer);
				static if (is(C == EnemyCard)) {
					_escTMenu.setSelection(card.action(ActionCardType.RunAway));
				}
			} else if (_editC.length > 1) { mixin(S_TRACE);
				_xSpn.setSelection(spnValue!("a.x", C, int)(_editC.keys, 0));
				_ySpn.setSelection(spnValue!("a.y", C, int)(_editC.keys, 0));
				_scaleSpn.setSelection(spnValue!("a.scale", C, int)(_editC.keys, 100));
				_layerSpn.setSelection(spnValue!("a.layer", C, int)(_editC.keys, 0));
				static if (is(C == EnemyCard)) {
					_escTMenu.setSelection(spnValue!("a.action(ActionCardType.RunAway)", C, bool)(_editC.keys, false));
				}
			}
		} else static if (UseBacks) {
			if (!valid(_imgp, _xSpn, _ySpn, _wSpn, _hSpn, _layerSpn, _maskTMenu)) return;
			bool enbl = !_readOnly && _editB.length > 0;
			_xSpn.setEnabled(enbl);
			_ySpn.setEnabled(enbl);
			_wSpn.setEnabled(enbl);
			_hSpn.setEnabled(enbl);
			_layerSpn.setEnabled(enbl && (!_summ || !_summ.legacy));
			bool maskEnabled = false;
			if (!_readOnly) { mixin(S_TRACE);
				foreach (back; _editB.keys) { mixin(S_TRACE);
					if (cast(ImageCell)back) { mixin(S_TRACE);
						maskEnabled = true;
						break;
					}
				}
			}
			_maskTMenu.setEnabled(maskEnabled);
			if (_editB.length == 1) { mixin(S_TRACE);
				auto back = _editB.keys[0];
				_xSpn.setSelection(back.x);
				_ySpn.setSelection(back.y);
				_wSpn.setSelection(back.width);
				_hSpn.setSelection(back.height);
				_maskTMenu.setSelection(cast(ImageCell)back && back.mask);
				_layerSpn.setSelection(back.layer);
			} else if (_editB.length > 1) { mixin(S_TRACE);
				_xSpn.setSelection(spnValue!("a.x", BgImage, int)(_editB.keys, 0));
				_ySpn.setSelection(spnValue!("a.y", BgImage, int)(_editB.keys, 0));
				_wSpn.setSelection(spnValue!("a.width", BgImage, int)(_editB.keys, 0));
				_hSpn.setSelection(spnValue!("a.height", BgImage, int)(_editB.keys, 0));
				BgImage[] ics = [];
				foreach (b; _editB.keys) { mixin(S_TRACE);
					if (auto ic = cast(ImageCell)b)ics ~= ics;
				}
				_maskTMenu.setSelection(spnValue!("a.mask", BgImage, bool)(ics, false));
				_layerSpn.setSelection(spnValue!("a.layer", BgImage, int)(_editB.keys, 0));
			}
			updateInheritBacks();
		} else { mixin(S_TRACE);
			static assert (0);
		}
		updateFlagCombo();
		refreshStatusLine();
		_comm.refreshToolBar();
	}
	void refDataVersion() { mixin(S_TRACE);
		static if (is(A:Battle)) { mixin(S_TRACE);
			_bgm.canContinue = !_summ || !_summ.legacy;
		}
	}

	void refreshStatusLine() { mixin(S_TRACE);
		string line = "";
		static if (UseCards && UseBacks) {
			if (_editC.length == 1 && !_editB.length) { mixin(S_TRACE);
				line = createAreaViewStatusLine(_comm, _summ, summSkin, _editC.keys[0]);
			} else if (!_editC.length && _editB.length == 1) { mixin(S_TRACE);
				line = createAreaViewStatusLine(_comm, _summ, summSkin, _editB.keys[0]);
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
				line = createAreaViewStatusLine(_comm, _summ, summSkin, _editC.keys[0]);
			} else if (1 < _editC.length) { mixin(S_TRACE);
				line = .tryFormat(_prop.msgs.areaViewStatusSelCard, _editC.length);
			}
		} else static if (UseBacks) {
			if (1 == _editB.length) { mixin(S_TRACE);
				line = createAreaViewStatusLine(_comm, _summ, summSkin, _editB.keys[0]);
			} else if (1 < _editB.length) { mixin(S_TRACE);
				line = .tryFormat(_prop.msgs.areaViewStatusSelBack, _editB.length);
			}
		}
		statusLine = line;
	}
	static if (UseCards) {
		static int staticCardsIndex(A area) { mixin(S_TRACE);
			static if (UseBacks) {
				return cast(int)area.backs.length;
			} else { mixin(S_TRACE);
				return 0;
			}
		}
		@property
		int cardsIndex() { mixin(S_TRACE);
			return cast(int)staticCardsIndex(_area);
		}
	}

	void refreshSelected() { mixin(S_TRACE);
		static if (UseCards) {
			int[] selsC = refreshSelectedImpl(_viewCards, _cards, _editC, _area.cards, cardsIndex);
			_cards.setSelection(selsC);
		}
		static if (UseBacks) {
			int[] selsB = refreshSelectedImpl(_viewBacks, _backs, _editB, _area.backs, 0);
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
			auto l = cast(Table)e.widget;
			_edit(l.getSelectionIndices());
		}
		override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (e.button == 1) { mixin(S_TRACE);
				auto list = cast(Table)e.widget;
				assert (list);
				auto itm = list.getItem(new Point(e.x, e.y));
				if (!itm) return;
				// チェックボックスの領域をダブルクリックした時は編集開始を避ける
				if (e.x < itm.getImageBounds(0).x) return;
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
				.setupToggle(_vcTMenu, _prop.var.etc.viewCards);
			}
			if (!_readOnly) { mixin(S_TRACE);
				_vfcTMenu = createToolItem(_comm, bar, MenuID.FixedCards, &reverseFixedCards, null, SWT.CHECK);
				static if (is(C:MenuCard)) {
					.setupToggle(_vfcTMenu, _prop.var.etc.fixedImagesMenuCards);
					new ToolItem(bar, SWT.SEPARATOR);
					createToolItem(_comm, bar, MenuID.NewMenuCard, &createCard, () => !_readOnly);
				} else static if (is(C:EnemyCard)) {
					.setupToggle(_vfcTMenu, _prop.var.etc.fixedImagesBattle);
					new ToolItem(bar, SWT.SEPARATOR);
					createToolItem(_comm, bar, MenuID.NewEnemyCard, &createCard, () => !_readOnly && _summ && _summ.casts.length);
				} else static assert (0);
			}
		} else { mixin(S_TRACE);
			static assert (is(C:BgImage));
			static if (UseCards) {
				_vbTMenu = createToolItem(_comm, bar, MenuID.ShowBack, &reverseViewBacks, null, SWT.CHECK);
				.setupToggle(_vbTMenu, _prop.var.etc.viewBgImages);
			}
			if (!_readOnly) { mixin(S_TRACE);
				_vfbTMenu = createToolItem(_comm, bar, MenuID.FixedCells, &reverseFixedCells, null, SWT.CHECK);
				.setupToggle(_vfbTMenu, _prop.var.etc.fixedImagesCells);
				_vffbTMenu = createToolItem(_comm, bar, MenuID.FixedBackground, &reverseFixedBackground, null, SWT.CHECK);
				static if (is(A:Area)) {
					.setupToggle(_vffbTMenu, _prop.var.etc.fixedImagesBackground);
				} else static if (is(A:BgImageContainer)) {
					auto fixed = false;
					if (_summ) { mixin(S_TRACE);
						.setupToggle(_vffbTMenu, _prop.var.etc.fixedImagesEventBackground);
					} else { mixin(S_TRACE);
						.setupToggle(_vffbTMenu, _prop.var.etc.fixedImagesDefaultBackground);
					}
				} else static assert (0);
				new ToolItem(bar, SWT.SEPARATOR);
				createToolItem(_comm, bar, MenuID.NewBack, &createBackground, () => !_readOnly);
				createToolItem(_comm, bar, MenuID.NewTextCell, &createTextCell, () => !_readOnly);
				createToolItem(_comm, bar, MenuID.NewColorCell, &createColorCell, () => !_readOnly);
				createToolItem(_comm, bar, MenuID.NewPCCell, &createPCCell, () => !_readOnly && !(_summ && _summ.legacy));
			}
		}

		auto list = .rangeSelectableTable(comp, SWT.MULTI | SWT.CHECK | SWT.BORDER | SWT.H_SCROLL | SWT.V_SCROLL);
		.listener(list, SWT.Selection, (e) { mixin(S_TRACE);
			if (e.detail != SWT.CHECK) return;
			auto itm = cast(TableItem)e.item;
			if (itm.getGrayed()) { mixin(S_TRACE);
				itm.setGrayed(false);
				itm.setChecked(true);
			} else if (itm.getChecked()) { mixin(S_TRACE);
				itm.setGrayed(_prop.var.etc.switchFixedWithCheckBox);
				itm.setChecked(true);
			} else { mixin(S_TRACE);
				itm.setGrayed(false);
				itm.setChecked(false);
			}
			if (list.isSelected(list.indexOf(itm))) { mixin(S_TRACE);
				foreach (itm2; list.getSelection()) { mixin(S_TRACE);
					if (itm is itm2) continue;
					itm2.setGrayed(itm.getGrayed());
					itm2.setChecked(itm.getChecked());
				}
			}
		});
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
			}, () => !_readOnly && list.getSelectionIndex() != -1);
			if (!_readOnly) { mixin(S_TRACE);
				new MenuItem(menu, SWT.SEPARATOR);
				static if (is(C:MenuCard)) {
					createMenuItem(_comm, menu, MenuID.NewMenuCard, &createCard, () => !_readOnly);
				} else static if (is(C:EnemyCard)) {
					createMenuItem(_comm, menu, MenuID.NewEnemyCard, &createCard, () => !_readOnly && _summ && _summ.casts.length);
				} else {
					createMenuItem(_comm, menu, MenuID.NewBack, &createBackground, () => !_readOnly);
					createMenuItem(_comm, menu, MenuID.NewTextCell, &createTextCell, () => !_readOnly);
					createMenuItem(_comm, menu, MenuID.NewColorCell, &createColorCell, () => !_readOnly);
					createMenuItem(_comm, menu, MenuID.NewPCCell, &createPCCell, () => !_readOnly && !(_summ && _summ.legacy));
				}
				new MenuItem(menu, SWT.SEPARATOR);
				static if (is(C:MenuCard) || is(C:EnemyCard)) {
					createMenuItem(_comm, menu, MenuID.Comment, &writeCommentC, &canWriteCommentC);
				} else {
					createMenuItem(_comm, menu, MenuID.Comment, &writeCommentB, &canWriteCommentB);
				}
			}
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_comm, menu, tcpd, !_readOnly, true, !_readOnly, !_readOnly, !_readOnly);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.SelectAll, selectAll, () => list.getItemCount() && list.getSelectionCount() != list.getItemCount());
			static if ((is(A : Area) || is(A : Battle)) && is(C : AbstractSpCard)) {
				new MenuItem(menu, SWT.SEPARATOR);
				static if (is(A : Area)) {
					createMenuItem(_comm, menu, MenuID.EditEvent, () => openEvent(false), null);
				} else static if (is(A : Battle)) {
					auto itm = createMenuItem(_comm, menu, MenuID.EditEvent, () => openEvent(false), null);
					itm.setImage(_prop.images.editEventBattle);
				} else static assert (0);
			}
			if (_summ) { mixin(S_TRACE);
				static if (is(C:AbstractSpCard)) {
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(_comm, menu, MenuID.SelectConnectedResource, &selectConnectedResourceC, &canSelectConnectedResourceC);
				} else static if (is(C:BgImage)) {
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(_comm, menu, MenuID.SelectConnectedResource, &selectConnectedResourceB, &canSelectConnectedResourceB);
				} else static assert (0);
			}
			if (!_readOnly) { mixin(S_TRACE);
				new MenuItem(menu, SWT.SEPARATOR);
				static if (is(C:BgImage)) {
					createMenuItem(_comm, menu, MenuID.FindID, &findCellName, &canFindCellName);
				} else {
					createMenuItem(_comm, menu, MenuID.FindID, &findCardGroup, &canFindCardGroup);
					new MenuItem(menu, SWT.SEPARATOR);
					.createMenuItem(_comm, menu, MenuID.SortWithPosition, &sortWithPosition, &canSortWithPosition);
				}
			}
			list.setMenu(menu);
		}
		static if (is(C:BgImage)) {
			if (_showInheritBacks) { mixin(S_TRACE);
				_inheritBgImgs = new CLabel(comp, SWT.NONE);

				auto width = 0;
				_inheritBgImgs.setText(_prop.msgs.inheritBackground);
				_inheritBgImgs.setImage(_prop.images.inheritBackground);
				width = .max(width, _inheritBgImgs.computeSize(SWT.DEFAULT, SWT.DEFAULT).x);
				_inheritBgImgs.setText(_prop.msgs.notInheritBackground);
				_inheritBgImgs.setImage(_prop.images.notInheritBackground);
				width = .max(width, _inheritBgImgs.computeSize(SWT.DEFAULT, SWT.DEFAULT).x);

				auto ibd = new GridData(GridData.HORIZONTAL_ALIGN_END);
				ibd.horizontalSpan = 2;
				ibd.widthHint = width;
				_inheritBgImgs.setLayoutData(ibd);
			}
		}
		auto ib = _comm.prop.images.menu(MenuID.Comment).getBounds();
		.listener(list, SWT.Paint, (e) { mixin(S_TRACE);
			if (_prop.var.etc.showItemNumberOfSceneAndEventView) { mixin(S_TRACE);
				auto count = list.getItemCount();
				auto h = list.getSize().y;
				auto cw = list.getColumn(0).getWidth();
				e.gc.setForeground(list.getDisplay().getSystemColor(SWT.COLOR_GRAY));
				for (auto i = list.getTopIndex(); i < count; i++) { mixin(S_TRACE);
					auto itm = list.getItem(i);
					if (itm.isDisposed()) continue;
					auto b = itm.getBounds();
					if (h <= b.y) { mixin(S_TRACE);
						break;
					}
					auto s = .text(i + 1);
					auto te = e.gc.wTextExtent(s);
					auto x = cw - 5.ppis - te.x;
					if (.commentText(cast(CWXPath)itm.getData(), false) != "") x -= ib.width + 5.ppis;
					auto y = b.y + (b.height - te.y) / 2;
					e.gc.wDrawText(s, x, y, true);
				}
			}
		});
		.setupComment(_comm, list, false);
		return list;
	}
	static if (is(C:EnemyCard)) {
		Composite createBgmPane(Composite parent) { mixin(S_TRACE);
			auto skin = summSkin;
			_bgm = new MaterialSelect!(MtType.BGM, Combo, Combo)(_comm, _prop, _summ, _forceSkin, _readOnly != 0, &selectBGM, included => [_prop.msgs.defaultSelection(_prop.msgs.bgmNone)]);
			_bgm.canContinue = !_summ || !_summ.legacy;

			auto comp = new Composite(parent, SWT.NONE);
			auto gl = windowGridLayout(2, false);
			gl.marginWidth = 0;
			gl.marginHeight = 0;
			comp.setLayout(gl);
			auto label = new CLabel(comp, SWT.NONE);
			label.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			label.setText(_prop.msgs.bgm);
			label.setImage(_prop.images.bgm);
			auto bar = new ToolBar(comp, SWT.FLAT);
			_comm.put(bar);
			_bgm.createPlayToolItem(bar);
			new ToolItem(bar, SWT.SEPARATOR);
			_bgm.createRefreshToolItem(bar);
			_bgm.createDirectoryToolItem(bar);

			auto h2GD(int style) { mixin(S_TRACE);
				auto gd = new GridData(style);
				gd.horizontalSpan = 2;
				return gd;
			}

			_bgm.createDirsCombo(comp).setLayoutData(h2GD(GridData.FILL_HORIZONTAL));
			_bgm.createFileList(comp).setLayoutData(h2GD(GridData.FILL_HORIZONTAL));

			_bgm.createPlayingBar(comp).setLayoutData(h2GD(GridData.FILL_HORIZONTAL));
			_bgm.createPlayingOptions(comp, false, true).setLayoutData(h2GD(GridData.FILL_HORIZONTAL));
			_bgm.createFadeIn(comp).setLayoutData(h2GD(GridData.FILL_HORIZONTAL | GridData.HORIZONTAL_ALIGN_END));

			_bgm.path = _area.music;
			_bgm.volume = _area.volume;
			_bgm.loopCount = _area.loopCount;
			_bgm.fadeIn = _area.fadeIn;
			_bgm.continueBGM = _area.continueBGM;
			return comp;
		}
	}

	static if (UseCards) {
		void findCardGroup() { mixin(S_TRACE);
			foreach (itm; _cards.getSelection()) { mixin(S_TRACE);
				auto cardGroup = (cast(AbstractSpCard)itm.getData()).cardGroup;
				if (cardGroup != "") { mixin(S_TRACE);
					_comm.replaceID(toCardGroupId(cardGroup), true);
					return;
				}
			}
		}
		@property
		bool canFindCardGroup() { mixin(S_TRACE);
			foreach (itm; _cards.getSelection()) { mixin(S_TRACE);
				if ((cast(AbstractSpCard)itm.getData()).cardGroup != "") return true;
			}
			return false;
		}
		void sortWithPosition() { mixin(S_TRACE);
			auto indices = indicesFromPosition();
			if (!indices.length) return;
			_undo ~= createUndoCardIndices(indices);
			_area.setCardIndices(indices);
			_comm.refMenuCardIndices.call(_area, indices);
		}
		@property
		bool canSortWithPosition() { mixin(S_TRACE);
			return 0 < indicesFromPosition().length;
		}
		Tuple!(size_t, size_t)[] indicesFromPosition() { mixin(S_TRACE);
			auto cs = _area.cards;
			auto indices = .iota(0, cs.length).array();
			if (_cards.getSelectionCount()) { mixin(S_TRACE);
				indices = .filter!(i => _cards.isSelected(cast(int)i))(indices).array();
			}
			auto newIndices = std.algorithm.sort!((a, b) => cs[a].y < cs[b].y || (cs[a].y == cs[b].y && cs[a].x < cs[b].x) || (cs[a].y == cs[b].y && cs[a].x == cs[b].x && a < b))(indices.dup).array();
			auto newIndices2 = .map!(i => indices[.countUntil(newIndices, i)])(indices);
			auto r = .filter!(t => t[0] != t[1])(.zip(indices, newIndices2)).array();
			return r;
		}
	}
	static if (UseBacks) {
		void findCellName() { mixin(S_TRACE);
			foreach (itm; _backs.getSelection()) { mixin(S_TRACE);
				auto cellName = (cast(BgImage)itm.getData()).cellName;
				if (cellName != "") { mixin(S_TRACE);
					_comm.replaceID(toCellNameId(cellName), true);
					return;
				}
			}
		}
		@property
		bool canFindCellName() { mixin(S_TRACE);
			foreach (itm; _backs.getSelection()) { mixin(S_TRACE);
				if ((cast(BgImage)itm.getData()).cellName != "") return true;
			}
			return false;
		}
	}

	static if (UseBacks) {
		@property
		bool canSelectConnectedResourceB() { mixin(S_TRACE);
			auto index = _backs.getSelectionIndex();
			if (index == -1) return false;
			auto cell = cast(BgImage)_backs.getItem(index).getData();
			if (!cell) return false;
			if (canSelectConnectedResourceImpl(cell)) return true;
			foreach (item; _backs.getSelection()) { mixin(S_TRACE);
				auto c = cast(BgImage)item.getData();
				if (!c) continue;
				if (canSelectConnectedResourceImpl(c)) return true;
			}
			return false;
		}
		void selectConnectedResourceB() { mixin(S_TRACE);
			auto index = _backs.getSelectionIndex();
			if (index == -1) return;
			auto cell = cast(BgImage)_backs.getItem(index).getData();
			if (!cell) return;
			if (selectConnectedResourceImpl(cell)) return;
			foreach (item; _backs.getSelection()) { mixin(S_TRACE);
				if (_comm.stopOpen) break;
				auto c = cast(BgImage)item.getData();
				if (!c) continue;
				if (selectConnectedResourceImpl(c)) return;
			}
		}
	}
	static if (UseCards) {
		void setAutoImpl(bool value) { mixin(S_TRACE);
			if (_readOnly) return;
			_area.spAuto = value;
			auto vs = views();
			foreach (v; vs) { mixin(S_TRACE);
				if (v._autoMenu) v._autoMenu.setSelection(value);
				if (v._autoTMenu) v._autoTMenu.setSelection(value);
				if (v._customMenu) v._customMenu.setSelection(!value);
				if (v._customTMenu) v._customTMenu.setSelection(!value);
				v.callModEvent();
			}
			_comm.refreshToolBar();
		}
		@property
		bool canSelectConnectedResourceC() { mixin(S_TRACE);
			auto index = _cards.getSelectionIndex();
			if (index == -1) return false;
			auto card = cast(AbstractSpCard)_cards.getItem(index).getData();
			if (!card) return false;
			if (canSelectConnectedResourceImpl(card)) return true;
			foreach (item; _cards.getSelection()) { mixin(S_TRACE);
				auto c = cast(AbstractSpCard)item.getData();
				if (!c) continue;
				if (canSelectConnectedResourceImpl(c)) return true;
			}
			return false;
		}
		void selectConnectedResourceC() { mixin(S_TRACE);
			auto index = _cards.getSelectionIndex();
			if (index == -1) return;
			auto card = cast(AbstractSpCard)_cards.getItem(index).getData();
			if (!card) return;
			if (selectConnectedResourceImpl(card)) return;
			foreach (item; _cards.getSelection()) { mixin(S_TRACE);
				if (_comm.stopOpen) break;
				auto c = cast(AbstractSpCard)item.getData();
				if (!c) continue;
				if (selectConnectedResourceImpl(c)) return;
			}
		}
	}
	void refPath(string oldPath, string newPath, bool isDir) { mixin(S_TRACE);
		if (isDir) return;
		static if (UseCards) {
			foreach (i, itm; _cards.getItems()) { mixin(S_TRACE);
				auto img = _imgp.images[cardsIndex + i];
				if (img.updatePath(_summ.scenarioPath.buildPath(oldPath), _summ.scenarioPath.buildPath(newPath))) { mixin(S_TRACE);
					_imgp.redrawImage(img);
				}
			}
		}
		static if (UseBacks) {
			foreach (i, itm; _backs.getItems()) { mixin(S_TRACE);
				auto img = _imgp.images[i];
				if (img.updatePath(_summ.scenarioPath.buildPath(oldPath), _summ.scenarioPath.buildPath(newPath))) { mixin(S_TRACE);
					_imgp.redrawImage(img);
				}
				auto cell = cast(ImageCell)itm.getData();
				if (!cell) continue;
				if (cell.path == newPath) {
					itm.setText(cell.path);
				}
			}
		}
	}
	private bool canSelectConnectedResourceImpl(CWXPath c) { mixin(S_TRACE);
		if (!_summ) return false;
		if (auto card = cast(AbstractSpCard)c) { mixin(S_TRACE);
			if (auto path = card.connectedResource(_summ)) { mixin(S_TRACE);
				return true;
			}
			auto file = card.connectedFile;
			if (_summ.hasMaterial(file, _prop.var.etc.ignorePaths)) { mixin(S_TRACE);
				return true;
			}
		}
		if (auto cell = cast(BgImage)c) { mixin(S_TRACE);
			auto file = cell.connectedFile;
			if (_summ.hasMaterial(file, _prop.var.etc.ignorePaths)) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
	}
	private bool selectConnectedResourceImpl(CWXPath c) { mixin(S_TRACE);
		if (!_summ) return false;
		if (auto card = cast(AbstractSpCard)c) { mixin(S_TRACE);
			if (auto path = card.connectedResource(_summ)) { mixin(S_TRACE);
				_comm.openCWXPath(cpaddattr(cpaddattr(path.cwxPath(true), "shallow"), "only"), false);
				return true;
			}
			auto file = card.connectedFile;
			if (_summ.hasMaterial(file, _prop.var.etc.ignorePaths)) { mixin(S_TRACE);
				_comm.openFilePath(file, false, true);
				return true;
			}
		}
		if (auto cell = cast(BgImage)c) { mixin(S_TRACE);
			auto file = cell.connectedFile;
			if (_summ.hasMaterial(file, _prop.var.etc.ignorePaths)) { mixin(S_TRACE);
				_comm.openFilePath(file, false, true);
				return true;
			}
		}
		return false;
	}
	@property
	public bool canSelectConnectedResource() { mixin(S_TRACE);
		static if (UseCards && UseBacks) {
			if (_cards.isFocusControl() && canSelectConnectedResourceC) { mixin(S_TRACE);
				return true;
			} else if (_backs.isFocusControl() && canSelectConnectedResourceB) { mixin(S_TRACE);
				return true;
			}
		}
		static if (UseCards) {
			if (canSelectConnectedResourceC) { mixin(S_TRACE);
				return true;
			}
		}
		static if (UseBacks) {
			if (canSelectConnectedResourceB) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
	}
	public void selectConnectedResource() { mixin(S_TRACE);
		static if (UseCards && UseBacks) {
			if (_cards.isFocusControl() && canSelectConnectedResourceC) { mixin(S_TRACE);
				selectConnectedResourceC();
				return;
			} else if (_backs.isFocusControl() && canSelectConnectedResourceB) { mixin(S_TRACE);
				selectConnectedResourceB();
				return;
			}
		}
		static if (UseCards) {
			if (canSelectConnectedResourceC) { mixin(S_TRACE);
				selectConnectedResourceC();
				return;
			}
		}
		static if (UseBacks) {
			if (canSelectConnectedResourceB) { mixin(S_TRACE);
				selectConnectedResourceB();
				return;
			}
		}
	}
	class VCheckListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			if (e.detail != SWT.CHECK) return;
			updateChecked(e);
			checked();
			updateFlagChecks();
		}
	}
	void checked() { mixin(S_TRACE);
		static if (UseCards) {
			foreach (i, itm; _cards.getItems()) { mixin(S_TRACE);
				auto img = cast(FlexImage)_imgp.images[cardsIndex + i];
				auto visible = _viewCards && itm.getChecked();
				auto fixed = isFixedCards || (visible && itm.getGrayed());
				if (img.visible != visible || img.fixed != fixed) { mixin(S_TRACE);
					img.visible = visible;
					img.fixed = fixed;
					_imgp.redrawImage(img);
				}
			}
		}
		static if (UseBacks) {
			auto firstB = false;
			foreach (i, itm; _backs.getItems()) { mixin(S_TRACE);
				auto img = cast(FlexImage)_imgp.images[i];
				auto visible = _viewBacks && itm.getChecked();
				auto fixed = _fixedB || (visible && itm.getGrayed());
				if (_fixedFirstB && !firstB) { mixin(S_TRACE);
					const vs = _prop.looks.viewSize;
					if (img.x == 0 && img.y == 0 && img.width == vs.width && img.height == vs.height) { mixin(S_TRACE);
						firstB = true;
						fixed = true;
					}
				}
				if (img.visible != visible || img.fixed != fixed) { mixin(S_TRACE);
					img.visible = visible;
					img.fixed = fixed;
					_imgp.redrawImage(img);
				}
			}
		}
	}
	void openFlagViewC() { mixin(S_TRACE);
		if (_readOnly) return;
		if (-1 == _flag.getSelectionIndex()) return;
		auto path = _flag.getText();
		static if (is(A:BgImageContainer)) {
			auto flag = .findVar!(cwx.flag.Flag)(_summ ? _summ.flagDirRoot : null, null, path);
		} else {
			auto flag = .findVar!(cwx.flag.Flag)(_summ.flagDirRoot, _area.useCounter, path);
		}
		if (!flag) return;
		try { mixin(S_TRACE);
			_comm.openCWXPath(flag.cwxPath(true), false);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
	void refShowToolBar() { mixin(S_TRACE);
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
	this(Commons comm, Props prop, Summary summ, Skin forceSkin, UseCounter uc, A area, Composite parent, TopLevelPanel tlp, bool showInheritBacks, UndoManager undo, bool readOnly) { mixin(S_TRACE);
		super(parent, SWT.NONE);
		_readOnly = readOnly ? SWT.READ_ONLY : SWT.NONE;
		_id = .objectIDValue(this);
		_prop = prop;
		_summ = summ;
		_uc = uc;
		_area = area;
		_comm = comm;
		_undo = undo;
		_tlp = tlp;
		static if (UseBacks) _showInheritBacks = showInheritBacks;
		if (forceSkin) { mixin(S_TRACE);
			_summSkin = forceSkin;
			_forceSkin = forceSkin;
		} else if (_readOnly || !_summ || _summ.scenarioPath == "") { mixin(S_TRACE);
			_summSkin = findSkin(_comm, _prop, _summ);
		}
		if (_summ && _summ.scenarioPath != "" && !_readOnly) { mixin(S_TRACE);
			_comm.refSkin.add(&refresh);
			_comm.refDataVersion.add(&refreshControls);
			_comm.delPaths.add(&refresh);
			_comm.replPath.add(&refreshR);
			_comm.replText.add(&replText);
			_comm.replID.add(&replText);
			static if (UseCards) {
				_comm.refPreviewValues.add(&refreshCardNamePreview);
				_comm.refFlagAndStep.add(&refreshCardNamePreviewF);
				_comm.refDataVersion.add(&refreshCardNamePreview);
				_comm.refCardState.add(&refreshCardState);
			}
			static if (UseBacks) {
				_comm.refPreviewValues.add(&refreshTextCell);
				_comm.refFlagAndStep.add(&refreshTextCellF);
				_comm.refDataVersion.add(&refreshTextCell);
			}
			_comm.refFlagAndStep.add(&refFlag);
			_comm.delFlagAndStep.add(&refFlag);
			_comm.refDataVersion.add(&refDataVersion);
		}
		_preview = new Preview(_prop, this);
		addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				_preview.dispose();
				if (summ && summ.scenarioPath != "" && !_readOnly) { mixin(S_TRACE);
					_comm.refSkin.remove(&refresh);
					_comm.refDataVersion.remove(&refreshControls);
					_comm.delPaths.remove(&refresh);
					_comm.replPath.remove(&refreshR);
					_comm.replText.remove(&replText);
					_comm.replID.remove(&replText);
					static if (UseCards) {
						_comm.refPreviewValues.remove(&refreshCardNamePreview);
						_comm.refFlagAndStep.remove(&refreshCardNamePreviewF);
						_comm.refDataVersion.remove(&refreshCardNamePreview);
						_comm.refCardState.remove(&refreshCardState);
						foreach (dlg; _editDlgsC.values) { mixin(S_TRACE);
							dlg.forceCancel();
						}
						foreach (dlg; _commentDlgsC.values) { mixin(S_TRACE);
							dlg.forceCancel();
						}
					}
					static if (UseBacks) {
						_comm.refPreviewValues.remove(&refreshTextCell);
						_comm.refFlagAndStep.remove(&refreshTextCellF);
						_comm.refDataVersion.remove(&refreshTextCell);
						foreach (dlg; _editDlgsB.values) { mixin(S_TRACE);
							dlg.forceCancel();
						}
						foreach (dlg; _commentDlgsB.values) { mixin(S_TRACE);
							dlg.forceCancel();
						}
					}
					_comm.refFlagAndStep.remove(&refFlag);
					_comm.delFlagAndStep.remove(&refFlag);
					_comm.refDataVersion.remove(&refDataVersion);
				}
			}
		});
		static if (is(C == EnemyCard) || RefCards) {
			if (summ && summ.scenarioPath != "" && !_readOnly) { mixin(S_TRACE);
				_comm.refCast.add(&refreshCast);
				_comm.delCast.add(&deleteCast);
				addDisposeListener(new class DisposeListener {
					override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
						_comm.refCast.remove(&refreshCast);
						_comm.delCast.remove(&deleteCast);
					}
				});
			}
		}
		static if (is(A:Area)) {
			_viewMsg = _prop.var.etc.viewMessageArea;
			_viewParty = _prop.var.etc.viewPartyCardsArea;
			if (!_readOnly) { mixin(S_TRACE);
				_fixedC = _prop.var.etc.fixedImagesMenuCards;
				_fixedB = _prop.var.etc.fixedImagesCells;
				_fixedFirstB = _prop.var.etc.fixedImagesBackground;
			}
		} else static if (is(A:Battle)) {
			_viewMsg = _prop.var.etc.viewMessageBattle;
			_viewParty = _prop.var.etc.viewPartyCardsBattle;
			if (!_readOnly) { mixin(S_TRACE);
				_fixedC = _prop.var.etc.fixedImagesBattle;
			}
		} else static if (is(A:BgImageContainer)) {
			_viewMsg = _prop.var.etc.viewMessageEvent;
			_viewParty = _prop.var.etc.viewPartyCardsEvent;
			if (!_readOnly) { mixin(S_TRACE);
				_fixedB = _prop.var.etc.fixedImagesEvent;
				if (_summ) { mixin(S_TRACE);
					_fixedFirstB = _prop.var.etc.fixedImagesEventBackground;
				} else { mixin(S_TRACE);
					_fixedFirstB = _prop.var.etc.fixedImagesDefaultBackground;
				}
			}
		} else { mixin(S_TRACE);
			static assert (0);
		}
		_showGrid = _prop.var.etc.showGrid;
		_gridX = _prop.var.etc.gridX;
		_gridY = _prop.var.etc.gridY;
		static if (is(C : EnemyCard) || RefCards) {
			_dbgMode = _prop.var.etc.viewEnemyCardDebug;
		}
		static if (UseCards && UseBacks) {
			_viewCards = _prop.var.etc.viewCards;
			_viewBacks = _prop.var.etc.viewBgImages;
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
		.listener(_toolbar, SWT.Paint, &refreshControlsImpl);

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
				static if (is(C == MenuCard)) {
					_cards = createList(listsP, prop.msgs.menuCards,
						prop.images.cards, ctcpd, &editCard, () => _area.cards, &selectAllC);
					if (!_readOnly) { mixin(S_TRACE);
							_cardEdit = new TableTextEdit(_comm, _prop, _cards, 0, &nameEditEnd, null, (itm, editC) { mixin(S_TRACE);
								auto card = cast(MenuCard)itm.getData();
								auto t = createTextEditor(_comm, _prop, _cards, card.name);
								if (card.expandSPChars) { mixin(S_TRACE);
									auto nameMenu = t.getMenu();
									new MenuItem(nameMenu, SWT.SEPARATOR);
									.setupSPCharsMenu(_comm, _summ, &summSkin, _uc, t, nameMenu, false, false, () => card.expandSPChars);
									void updateToolTip() { mixin(S_TRACE);
										auto toolTip = .createSPCharPreview(_comm, _summ, &summSkin, _uc, t.getText(), false, null, null);
										toolTip = toolTip.replace("&", "&&");
										if (toolTip != t.getToolTipText()) { mixin(S_TRACE);
											t.setToolTipText(toolTip);
										}
									}
									.listener(t, SWT.Modify, &updateToolTip);
									updateToolTip();
								}
								return t;
							});
					}
				} else static if (is(C == EnemyCard)) {
					_cards = createList(listsP, prop.msgs.enemyCards,
						prop.images.cards, ctcpd, &editCard, () => _area.cards, &selectAllC);
					if (!_readOnly) { mixin(S_TRACE);
						_cardEdit = new TableComboEdit!Combo(_comm, _prop, _cards, 0, &createEnemyCombo, &enemyEditEnd, (itm, column) => 0 < _summ.casts.length, &enemyIncSearch);
					}
				}
				auto scl = new SCListener;
				_cards.addSelectionListener(scl);
				_cards.addMouseListener(scl);
				static if (is(C == MenuCard)) {
					if (!_readOnly) { mixin(S_TRACE);
						auto target = new DropTarget(_cards, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_LINK);
						target.setTransfer([cast(Transfer)FileTransfer.getInstance(), XMLBytesTransfer.getInstance()]);
						target.addDropListener(new CLDropTarget);
					}
				}
				_cards.addMouseTrackListener(prevTrig);
				_cards.addMouseMoveListener(prevTrig);
				.listener(_cards, SWT.Paint, &selectImageCImpl);
				.listener(_cards, SWT.Paint, &openCWXPathImpl);
			}
			static if (UseBacks) {
				_backs = createList(listsP, prop.msgs.backs,
					prop.images.backs, btcpd, &editBack, () => _area.backs, &selectAllB);
				auto sbl = new SBListener;
				_backs.addSelectionListener(sbl);
				_backs.addMouseListener(sbl);
				if (!_readOnly) { mixin(S_TRACE);
					_backEdit = new TableComboEdit!Combo(_comm, _prop, _backs, 0, &createBgImageCombo, &bgImageEditEnd, &bgImageCanEdit, &bgImageIncSearch);
					auto backDrop = new DropTarget(_backs, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_LINK);
					backDrop.setTransfer([cast(Transfer)FileTransfer.getInstance(), XMLBytesTransfer.getInstance()]);
					backDrop.addDropListener(new BLDropTarget);
				}
				_backs.addMouseTrackListener(prevTrig);
				_backs.addMouseMoveListener(prevTrig);
				.listener(_backs, SWT.Paint, &selectImageBImpl);
				.listener(_backs, SWT.Paint, &openCWXPathImpl);
			}
			if (summ && summ.scenarioPath != "" && !_readOnly) { mixin(S_TRACE);
				_comm.refPath.add(&refPath);
				.listener(listsP, SWT.Dispose, { mixin(S_TRACE);
					_comm.refPath.remove(&refPath);
				});
			}
			static if (UseCards && UseBacks) {
				_cards.addMouseListener(new class MouseAdapter {
					override void mouseDown(MouseEvent e) { mixin(S_TRACE);
						if (e.button == 1 && (e.stateMask & SWT.CTRL) == 0 && (e.stateMask & SWT.SHIFT) == 0) { mixin(S_TRACE);
							_imgp.deselectRange(0, cast(int)_area.backs.length);
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
							_imgp.deselectRange(cardsIndex, cardsIndex + cast(int)_area.cards.length);
							_cards.deselectAll();
							typeof(_editC) editC;
							_editC = editC;
							refreshControls();
						}
					}
				});
				.setupWeights(_sash, _prop.var.etc.areaSashT, _prop.var.etc.areaSashB);
			}
		}
		if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
			auto lFlag = new Label(left, SWT.NONE);
			lFlag.setText(_prop.msgs.areaViewFlagDesc);
			_flag = new Combo(left, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
			_flag.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			_flag.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			_flag.add(_prop.msgs.defaultSelection(_prop.msgs.noFlagRef));
			_flag.addSelectionListener(new SelFlag);
			if (_readOnly) { mixin(S_TRACE);
				_comm.refFlagAndStep.add(&refFlag);
				_comm.delFlagAndStep.add(&refFlag);
				_flag.addDisposeListener(new FlagsDispose);
			}
			{ mixin(S_TRACE);
				_flagIncSearch = new IncSearch(_comm, _flag, () => _hasFlag);
				_flagIncSearch.modEvent ~= &refreshFlag;

				auto menu = new Menu(_flag.getShell(), SWT.POP_UP);
				createMenuItem(_comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
					.forceFocus(_flag, true);
					_flagIncSearch.startIncSearch();
				}, () => _hasFlag);
				if (!_readOnly) { mixin(S_TRACE);
					new MenuItem(menu, SWT.SEPARATOR);
					createMenuItem(_comm, menu, MenuID.OpenAtVarView, &openFlagViewC, () => !_readOnly && _flag.getSelectionIndex() > 0);
				}
				_flag.setMenu(menu);
			}
			refreshFlag();
			static if (RefCards) {
				_showRefCards = _prop.var.etc.viewReferenceCards;
				auto lRef = new Label(left, SWT.NONE);
				lRef.setText(_prop.msgs.areaViewRefAreaDesc);
				_refAreas = new Combo(left, SWT.READ_ONLY | SWT.DROP_DOWN | SWT.BORDER);
				_refAreas.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				_refAreas.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				_refAreas.add(_prop.msgs.defaultSelection(_prop.msgs.noRefArea));
				listener(_refAreas,  SWT.Selection, { mixin(S_TRACE);
					int sel = _refAreas.getSelectionIndex();
					_refTarget = sel <= 0 ? null : _refAreasArr[sel - 1];
					refreshPanel();
				});
				{ mixin(S_TRACE);
					auto menu = new Menu(_refAreas.getShell(), SWT.POP_UP);

					_refAreaIncSearch = new IncSearch(_comm, _refAreas, () => _hasRefArea);
					_refAreaIncSearch.modEvent ~= &refreshRefAreas;
					createMenuItem(_comm, menu, MenuID.IncSearch, { mixin(S_TRACE);
						.forceFocus(_refAreas, true);
						_refAreaIncSearch.startIncSearch();
					}, () => _hasRefArea);
					new MenuItem(menu, SWT.SEPARATOR);

					createMenuItem(_comm, menu, MenuID.OpenAtTableView, &openRefAreaView, () => !_readOnly && _refAreas.getSelectionIndex() > 0);
					_refAreas.setMenu(menu);
				}
				if (summ && summ.scenarioPath != "" && !_readOnly) { mixin(S_TRACE);
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
		}
		static if (is(C:EnemyCard)) {
			auto runComp = new Composite(left, SWT.NONE);
			auto rcgd = new GridData(GridData.FILL_HORIZONTAL);
			rcgd.horizontalSpan = 2;
			runComp.setLayoutData(rcgd);
			runComp.setLayout(windowGridLayout(1, true));

			auto line1 = new Label(runComp, SWT.SEPARATOR | SWT.HORIZONTAL);
			line1.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

			_possibleToRunAwayCheck = new Button(runComp, SWT.CHECK);
			_possibleToRunAwayCheck.setText(_prop.msgs.menuText(MenuID.PossibleToRunAway));
			_comm.put(_possibleToRunAwayCheck, &canReversePossibleToRunAway);
			.listener(_possibleToRunAwayCheck, SWT.Selection, &reversePossibleToRunAway);
			_possibleToRunAwayCheck.setSelection(_area.possibleToRunAway);
			_possibleToRunAwayCheck.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_CENTER));

			auto line2 = new Label(runComp, SWT.SEPARATOR | SWT.HORIZONTAL);
			line2.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

			auto bgmPane = createBgmPane(left);
			auto bggd = new GridData(GridData.FILL_HORIZONTAL);
			bggd.horizontalSpan = 2;
			bgmPane.setLayoutData(bggd);
		}
		{ mixin(S_TRACE);
			if (_summ) { mixin(S_TRACE);
				auto lrSash2 = new SplitPane(lrSash, SWT.HORIZONTAL);
				lrSash2.canMinimized2 = true;
				lrSash2.resizeControl1 = true;
				auto imagePaneComp = new Composite(lrSash2, SWT.NONE);
				auto ipcl = windowGridLayout(1, true);
				ipcl.marginWidth = 0;
				ipcl.marginHeight = 0;
				imagePaneComp.setLayout(ipcl);
				createImagePane(imagePaneComp).setLayoutData(new GridData(GridData.FILL_BOTH));
				if (!_readOnly) { mixin(S_TRACE);
					auto l = new Label(imagePaneComp, SWT.NONE);
					l.setText(_prop.msgs.areaViewKeyboardHint);
				}
				createFlagList(lrSash2);
				static if (is(A:Area)) {
					.setupWeights(lrSash2, _prop.var.etc.areaViewImageFlagL, _prop.var.etc.areaViewImageFlagR);
				} else static if (is(A:Battle)) {
					.setupWeights(lrSash2, _prop.var.etc.battleViewImageFlagL, _prop.var.etc.battleViewImageFlagR);
				} else static if (is(A:BgImageContainer)) {
					.setupWeights(lrSash2, _prop.var.etc.bgImageViewImageFlagL, _prop.var.etc.bgImageViewImageFlagR);
				} else static assert (0);
			} else { mixin(S_TRACE);
				auto imagePaneComp = new Composite(lrSash, SWT.NONE);
				auto ipcl = windowGridLayout(1, true);
				ipcl.marginWidth = 0;
				ipcl.marginHeight = 0;
				imagePaneComp.setLayout(ipcl);
				createImagePane(imagePaneComp).setLayoutData(new GridData(GridData.FILL_BOTH));
				if (!_readOnly) { mixin(S_TRACE);
					auto l = new Label(imagePaneComp, SWT.NONE);
					l.setText(_prop.msgs.areaViewKeyboardHint);
				}
			}
			static if (is(C == MenuCard) || UseBacks) {
				if (!_readOnly) { mixin(S_TRACE);
					auto target = new DropTarget(_imgp, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_LINK);
					static if (is(C == MenuCard)) {
						target.setTransfer([cast(Transfer)FileTransfer.getInstance(), XMLBytesTransfer.getInstance()]);
					} else { mixin(S_TRACE);
						target.setTransfer([FileTransfer.getInstance()]);
					}
					target.addDropListener(new IPDropTarget);
				}
			}
			static if (UseBacks) appendBgImages(0, area.backs, false, false, true);
			static if (UseCards) appendCards(0, area.cards, false, false, true);
			auto mImg = createMessageImage(_comm, _prop, _summ);
			mImg.visible = _viewMsg;
			_imgp.append(mImg);
			void updateMessageImage() { mixin(S_TRACE);
				auto i = _imgp.images.cCountUntil!"a is b"(mImg);
				mImg = createMessageImage(_comm, _prop, _summ);
				mImg.visible = _viewMsg;
				_imgp.set(cast(int)i, mImg);
			}
			_comm.refImageScale.add(&updateMessageImage);
			.listener(_imgp, SWT.Dispose, { mixin(S_TRACE);
				_comm.refImageScale.remove(&updateMessageImage);
			});
			foreach (p; _prop.looks.partyCardXY) { mixin(S_TRACE);
				auto img = createCastCardBackImage(_prop, summSkin, _summ, p.x, p.y, cast(byte)_prop.var.etc.partyCardAlpha);
				img.visible = _viewParty;
				_imgp.append(img);
				class Update {
					PileImage img;
					void update() { mixin(S_TRACE);
						updateCastCardBackImage(img, summSkin, cast(byte)_prop.var.etc.partyCardAlpha, _prop.drawingScale);
					}
					void dispose() { mixin(S_TRACE);
						_comm.refSkin.remove(&update);
						_comm.refImageScale.remove(&update);
					}
				}
				auto update = new Update;
				update.img = img;
				if (summ && summ.scenarioPath != "" && !_readOnly) { mixin(S_TRACE);
					_comm.refSkin.add(&update.update);
					_comm.refImageScale.add(&update.update);
					.listener(_imgp, SWT.Dispose, &update.dispose);
				}
			}
			static if (RefCards) {
				createRefCard();
			}
		}

		static if (UseCards) {
			_comm.refMenuCardAndBgImageList.add(&_cards.redraw);
			_comm.refMenuCardIndices.add(&refMenuCardIndices);
		}
		static if (UseBacks) _comm.refMenuCardAndBgImageList.add(&_backs.redraw);
		.listener(this, SWT.Dispose, { mixin(S_TRACE);
			static if (UseCards) {
				_comm.refMenuCardAndBgImageList.remove(&_cards.redraw);
				_comm.refMenuCardIndices.remove(&refMenuCardIndices);
			}
			static if (UseBacks) _comm.refMenuCardAndBgImageList.remove(&_backs.redraw);
		});

		auto fi = new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				auto c = cast(Control)e.widget;
				if (!c) return;
				if (.isDescendant(lrSash.getParent(), c)) { mixin(S_TRACE);
					_lastFocus = c;
					_comm.refreshToolBar();
				}
			}
		};
		getDisplay().addFilter(SWT.FocusIn, fi);
		.listener(this, SWT.Dispose, { getDisplay().removeFilter(SWT.FocusIn, fi); });

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
		setupToolBar0(_toolbar); // レイアウトのため最初のアイテムだけ生成しておく
		static if (is(A : Battle) && is(C : EnemyCard)) {
			if (!_readOnly) { mixin(S_TRACE);
				auto target = new DropTarget(imagePane, DND.DROP_DEFAULT | DND.DROP_COPY | DND.DROP_LINK);
				target.setTransfer([XMLBytesTransfer.getInstance()]);
				target.addDropListener(new DTListener);
			}
			if (!_readOnly) { mixin(S_TRACE);
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
			.setupWeights(lrSash, _prop.var.etc.areaViewL, _prop.var.etc.areaViewR);
		} else static if (is(A:Battle)) {
			.setupWeights(lrSash, _prop.var.etc.battleViewL, _prop.var.etc.battleViewR);
		} else static if (is(A:BgImageContainer)) {
			.setupWeights(lrSash, _prop.var.etc.bgImageViewL, _prop.var.etc.bgImageViewR);
		} else static assert (0);
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
	string statusLine() { return _statusLine; }

	@property
	A area() { mixin(S_TRACE);
		return _area;
	}
	@property
	Summary summary() { mixin(S_TRACE);
		return _summ;
	}
	static if (is(A : Area) || is(A : Battle)) {
		void openEvent(bool canDuplicate = false) { mixin(S_TRACE);
			if (!_summ) return;
			auto tlp = _comm.openAreaEvent(_prop, _summ, _area, false, canDuplicate);
			auto i = _cards.getSelectionIndex();
			if (-1 != i) { mixin(S_TRACE);
				string path;
				auto card = cast(C)_cards.getItem(i).getData();
				path = cplast(card.cwxPath(true));
				if (card.trees.length) { mixin(S_TRACE);
					path = cpjoin(path, cplast(card.trees[0].cwxPath(true)));
				}
				tlp.openCWXPath(path, false);
			}
		}
		void openDup() { mixin(S_TRACE);
			_comm.openAreaScene(_prop, _summ, _area, false, true);
		}
	}
	void refreshR(string from, string to) { mixin(S_TRACE);
		refresh();
	}
	private void replText() { mixin(S_TRACE);
		if (!_summ || _summ.scenarioPath == "" || _readOnly) return;
		setRedraw(false);
		scope (exit) setRedraw(true);
		static if (UseCards) {
			auto skin = summSkin;
			foreach (i, c; _area.cards) { mixin(S_TRACE);
				string name = cardName(c);
				auto itm = cardList.getItem(cast(int)i);
				if (itm.getText() != name) { mixin(S_TRACE);
					auto img = _imgp.images[cardsIndex + i];
					static if (is(C:EnemyCard)) {
						auto castCard = _summ.cwCast(c.id);
						if (!castCard) continue; // カード名が表示されないため不要
						img.setImageData(castCardImage(_prop, skin, _summ, castCard, _dbgMode));
					} else { mixin(S_TRACE);
						img.title = name;
					}
					img.createImage();
					itm.setText(cardNameWithGroup(c));
					_imgp.redrawImage(img);
					_comm.refMenuCard.call(c.cwxPath(true));
				}
				// 置換でフラグ名が消失する可能性があるため
				itm.setImage(cardImg(c));
			}
		}
		static if (UseBacks) {
			foreach (i, b; _area.backs) { mixin(S_TRACE);
				backList.getItem(cast(int)i).setImage(backImg(b));
				backList.getItem(cast(int)i).setText(b.name(_prop.parent));
			}
			refreshTextCell();
		}
		refreshFlags();
	}
	static if (UseCards) {
		private void refreshCard(size_t i) { mixin(S_TRACE);
			auto fi = cast(FlexImage)_imgp.images[cardsIndex + i];
			assert (fi !is null);
			auto v = fi.visible;
			auto f = fi.fixed;
			auto selected = fi.selected;
			fi = create(_area.cards[i]);
			fi.visible = v;
			fi.fixed = f;
			_imgp.set(cardsIndex + cast(int)i, fi);
			if (selected) _imgp.select(fi);
			_imgp.redrawImage(fi);
		}
		private void refreshCardState() { mixin(S_TRACE);
			foreach (i, c; _area.cards) { mixin(S_TRACE);
				refreshCard(i);
			}
		}
		private void refreshCardNamePreview() { mixin(S_TRACE);
			foreach (i, c; _area.cards) { mixin(S_TRACE);
				static if (is(C:MenuCard)) {
					if (!c.expandSPChars) continue;
				} else static if (is(C:EnemyCard)) {
					if (!c.isOverrideName) continue;
				} else static assert (0);
				auto fi = cast(FlexImage)_imgp.images[cardsIndex + i];
				auto v = fi.visible;
				auto f = fi.fixed;
				auto selected = fi.selected;
				fi = create(c);
				fi.visible = v;
				fi.fixed = f;
				_imgp.set(cardsIndex + cast(int)i, fi);
				if (selected) _imgp.select(fi);
				_imgp.redrawImage(fi);
			}
		}
		private void refreshCardNamePreviewF(cwx.flag.Flag[] flags, Step[] steps, cwx.flag.Variant[] variants) { mixin(S_TRACE);
			refreshCardNamePreview();
		}
		private void refMenuCardIndices(const(AbstractArea) area, const(Tuple!(size_t, size_t))[] indices) { mixin(S_TRACE);
			if (area !is _area) return;
			foreach (t; indices) { mixin(S_TRACE);
				auto i = t[0];
				refreshCard(i);
				auto c = _area.cards[i];
				auto itm = _cards.getItem(cast(int)i);
				itm.setText(cardNameWithGroup(c));
				itm.setImage(cardImg(c));
				itm.setData(c);
			}
		}
	}
	private void refreshPanel() { mixin(S_TRACE);
		auto sels = _imgp.selectedIndices;
		static if (UseCards) {
			foreach (i, c; _area.cards) { mixin(S_TRACE);
				auto itm = _cards.getItem(cast(int)i);
				auto v = _imgp.images[cardsIndex + i].visible;
				auto f = (cast(FlexImage)_imgp.images[cardsIndex + i]).fixed;
				auto fi = create(c);
				fi.visible = v;
				fi.fixed = f;
				_imgp.set(cardsIndex + cast(int)i, fi);
				itm.setText(cardNameWithGroup(c));
				itm.setImage(cardImg(c));
				itm.setData(c);
			}
		}
		static if (UseBacks) {
			foreach (i, b; _area.backs) { mixin(S_TRACE);
				auto itm = _backs.getItem(cast(int)i);
				auto v = _imgp.images[i].visible;
				auto f = (cast(FlexImage)_imgp.images[i]).fixed;
				auto fi = create(b);
				fi.visible = v;
				fi.fixed = f;
				_imgp.set(cast(int)i, fi);
				itm.setText(b.name(_prop.parent));
				itm.setImage(backImg(b));
				itm.setData(b);
			}
			checked();
		}

		static if (RefCards) {
			createRefCard();
		}

		_imgp.select(sels);
		_comm.refreshToolBar();
	}
	static if (RefCards) {
		void createRefCard(int del = -1) { mixin(S_TRACE);
			_imgp.removeRange(refCardIndex, _imgp.images.length);
			if (_refTarget) { mixin(S_TRACE);
				if (auto area = cast(Area)_refTarget) { mixin(S_TRACE);
					_imgp.append(createRefCardImpl(area.cards, del));
				}
				if (auto area = cast(Battle)_refTarget) { mixin(S_TRACE);
					_imgp.append(createRefCardImpl(area.cards, del));
				}
			}
		}
		PileImage[] createRefCardImpl(C2)(in C2[] cs, int del = -1) { mixin(S_TRACE);
			PileImage[] r;
			foreach (i, c; cs) { mixin(S_TRACE);
				if (i == del) continue;
				auto pImg = createCardImage!PileImage(c, _prop.var.etc.smoothingCard);
				pImg.visible = _showRefCards;
				pImg.alpha = _prop.var.etc.partyCardAlpha;
				r ~= pImg;
			}
			return r;
		}
	}
	void refresh() { mixin(S_TRACE);
		static if (UseCards && is(C == EnemyCard)) {
			if (_bgm) _bgm.refresh();
		}
		refreshPanel();
	}
	private void removeImpl(T)(int index, ref T[PileImage] tbl, int startIndex, bool refresh) { mixin(S_TRACE);
		if (_readOnly) return;
		tbl.remove(_imgp.images[startIndex + index]);
		_imgp.remove(startIndex + index);
		if (refresh) { mixin(S_TRACE);
			refreshSelected();
			refreshFlags();
			checked();
			callModEvent();
			_comm.refreshToolBar();
		}
	}
	static if (UseCards) {
		private static void removeCard(AbstractAreaView v, Commons comm, Summary summ, A area, ref C[PileImage] tbl, int index, bool refresh) { mixin(S_TRACE);
			v.removeImpl(index, tbl, staticCardsIndex(area), refresh);
			if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
				comm.delMenuCard.call(area.cards[index].cwxPath(true));
			} else { mixin(S_TRACE);
				auto p = area.cards[index] in v._editDlgsC;
				if (p) p.forceCancel();
				auto p2 = area.cards[index] in v._commentDlgsC;
				if (p2) p2.forceCancel();
			}
		}
	}
	static if (UseBacks) {
		private static void removeBack(AbstractAreaView v, Commons comm, Summary summ, A area, ref BgImage[PileImage] tbl, int index, bool refresh) { mixin(S_TRACE);
			v.removeImpl(index, tbl, 0, refresh);
			if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
				comm.delBgImage.call(area.backs[index].cwxPath(true));
			} else { mixin(S_TRACE);
				auto p = area.backs[index] in v._editDlgsB;
				if (p) p.forceCancel();
				auto p2 = area.backs[index] in v._commentDlgsB;
				if (p2) p2.forceCancel();
			}
		}
	}

	@property
	bool isFocusOnListOrPane() { mixin(S_TRACE);
		static if (UseCards) {
			if (_lastFocus is _cards) return true;
		}
		static if (UseBacks) {
			if (_lastFocus is _backs) return true;
		}
		if (_lastFocus is _imgp) return true;
		return false;
	}

	@property
	bool canUp() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!isFocusOnListOrPane()) return false;
		int[] cIdcs, bIdcs;
		static if (UseCards) {
			if (_viewCards) { mixin(S_TRACE);
				cIdcs = _cards.getSelectionIndices();
				std.algorithm.sort(cIdcs);
				if (cIdcs.length && cIdcs[0] <= 0) return false;
			}
		}
		static if (UseBacks) {
			if (_viewBacks) { mixin(S_TRACE);
				bIdcs = _backs.getSelectionIndices();
				std.algorithm.sort(bIdcs);
				if (bIdcs.length && bIdcs[0] <= 0) return false;
			}
		}
		return cIdcs.length || bIdcs.length;
	}
	@property
	bool canDown() { mixin(S_TRACE);
		if (_readOnly) return false;
		if (!isFocusOnListOrPane()) return false;
		int[] cIdcs, bIdcs;
		static if (UseCards) {
			if (_viewCards) { mixin(S_TRACE);
				cIdcs = _cards.getSelectionIndices();
				std.algorithm.sort(cIdcs);
				if (cIdcs.length && _cards.getItemCount() - 1 <= cIdcs[$ - 1]) return false;
			}
		}
		static if (UseBacks) {
			if (_viewBacks) { mixin(S_TRACE);
				bIdcs = _backs.getSelectionIndices();
				std.algorithm.sort(bIdcs);
				if (bIdcs.length && _backs.getItemCount() - 1 <= bIdcs[$ - 1]) return false;
			}
		}
		return cIdcs.length || bIdcs.length;
	}
	void up() { mixin(S_TRACE);
		if (_readOnly) return;
		up(1, true, true);
	}
	void up(int count, bool cards, bool backs) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!isFocusOnListOrPane()) return;
		int[] cIdcs;
		int[] bIdcs;
		static if (UseCards) {
			if (cards) { mixin(S_TRACE);
				if (_viewCards) cIdcs = _cards.getSelectionIndices();
				std.algorithm.sort(cIdcs);
				if (cIdcs.length && cIdcs[0] < count) { mixin(S_TRACE);
					count = cIdcs[0];
				}
			}
		}
		static if (UseBacks) {
			if (backs) { mixin(S_TRACE);
				if (_viewBacks) bIdcs = _backs.getSelectionIndices();
				std.algorithm.sort(bIdcs);
				if (bIdcs.length && bIdcs[0] < count) { mixin(S_TRACE);
					count = bIdcs[0];
				}
			}
		}
		if ((!cIdcs.length && !bIdcs.length) || 0 >= count) return;
		_undo ~= new UndoUp(this, _comm, _area, _summ, cIdcs, bIdcs, count);
		upImpl(views(), _comm, _area, cIdcs, bIdcs, count, true);
		_comm.refreshToolBar();
	}
	private static void upImpl(AbstractAreaView[] vs, Commons comm, A area, int[] cIdcs, int[] bIdcs, int count, bool sel) { mixin(S_TRACE);
		static if (UseCards) {
			Table[] cards;
			foreach (v; vs) cards ~= v._cards;
			upImpl2!(C)(vs, cards, &area.swapCards, staticCardsIndex(area), cIdcs, count);
			comm.upMenuCard.call(area.cwxPath(true), cIdcs, count);
		}
		static if (UseBacks) {
			Table[] backs;
			foreach (v; vs) backs ~= v._backs;
			upImpl2!(BgImage)(vs, backs, &area.swapBacks, 0, bIdcs, count);
			comm.upBgImage.call(area.cwxPath(true), bIdcs, count);
		}
		foreach (v; vs) { mixin(S_TRACE);
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
		}
	}
	void down() { mixin(S_TRACE);
		if (_readOnly) return;
		down(1, true, true);
	}
	void down(int count, bool cards, bool backs) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!isFocusOnListOrPane()) return;
		int[] cIdcs;
		int[] bIdcs;
		static if (UseCards) {
			if (cards) { mixin(S_TRACE);
				if (_viewCards) cIdcs = _cards.getSelectionIndices();
				std.algorithm.sort(cIdcs);
				if (cIdcs.length && _cards.getItemCount() - count <= cIdcs[$ - 1]) { mixin(S_TRACE);
					count = _cards.getItemCount() - 1 - cIdcs[$ - 1];
				}
			}
		}
		static if (UseBacks) {
			if (backs) { mixin(S_TRACE);
				if (_viewBacks) bIdcs = _backs.getSelectionIndices();
				std.algorithm.sort(bIdcs);
				if (bIdcs.length && _backs.getItemCount() - count <= bIdcs[$ - 1]) { mixin(S_TRACE);
					count = _backs.getItemCount() - 1 - bIdcs[$ - 1];
				}
			}
		}
		if ((!cIdcs.length && !bIdcs.length) || 0 >= count) return;
		_undo ~= new UndoDown(this, _comm, _area, _summ, cIdcs, bIdcs, count);
		downImpl(views(), _comm, _area, cIdcs, bIdcs, count, true);
		_comm.refreshToolBar();
	}
	private static void downImpl(AbstractAreaView[] vs, Commons comm, A area, int[] cIdcs, int[] bIdcs, int count, bool sel) { mixin(S_TRACE);
		static if (UseCards) {
			Table[] cards;
			foreach (v; vs) cards ~= v._cards;
			downImpl2!(C)(vs, cards, &area.swapCards, staticCardsIndex(area), cIdcs, cast(int)area.cards.length, count);
			comm.downMenuCard.call(area.cwxPath(true), cIdcs, count);
		}
		static if (UseBacks) {
			Table[] backs;
			foreach (v; vs) backs ~= v._backs;
			downImpl2!(BgImage)(vs, backs, &area.swapBacks, 0, bIdcs, cast(int)area.backs.length, count);
			comm.downBgImage.call(area.cwxPath(true), bIdcs, count);
		}
		foreach (v; vs) { mixin(S_TRACE);
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
		}
	}
	static if (UseCards && UseBacks) {
		private void reverseView(T)(ref bool view, Table list, int[T] edits, T[] delegate() col, int startIndex,
				MenuItem menu, ToolItem titm) { mixin(S_TRACE);
			if (_imgp.isVisible()) .forceFocus(this, false);
			view = !view;
			list.setEnabled(view);
			for (int i = 0; i < col().length; i++) { mixin(S_TRACE);
				auto fi = cast(FlexImage)_imgp.images[startIndex + i];
				fi.visible = view && list.getItem(i).getChecked();
				if (!view && fi.selected) { mixin(S_TRACE);
					_imgp.deselect(fi);
					edits.remove(col()[i]);
				}
				_imgp.redrawImage(fi);
			}
			if (!view) { mixin(S_TRACE);
				list.deselectAll();
			}
			if (menu) menu.setSelection(view);
			if (titm) titm.setSelection(view);
			refreshControls();
		}
		void reverseViewCards() { mixin(S_TRACE);
			reverseView!(C)(_viewCards, _cards, _editC, () => _area.cards, cardsIndex, _vcMenu, _vcTMenu);
		}
		void reverseViewBacks() { mixin(S_TRACE);
			reverseView!(BgImage)(_viewBacks, _backs, _editB, () => _area.backs, 0, _vbMenu, _vbTMenu);
		}
	}
	static if (UseCards) {
		SpCardDialog!(C)[C] _editDlgsC;
		void editCardApply(UndoEdit undo, C card) { mixin(S_TRACE);
			if (_readOnly) return;
			assert (undo);
			_undo ~= undo;
			int index;
			auto vs = views();
			foreach (i, c; _area.cards) { mixin(S_TRACE);
				if (c is card) { mixin(S_TRACE);
					foreach (v; vs) { mixin(S_TRACE);
						auto itm = v._cards.getItem(cast(int)i);
						auto fi = v.create(card);
						fi.visible = itm.getChecked();
						fi.fixed = fi.visible && itm.getGrayed();
						v._imgp.set(v.cardsIndex + cast(int)i, fi);
						if (v._cards.isSelected(cast(int)i) && v._viewCards) v._imgp.select(fi);
						itm.setText(v.cardNameWithGroup(c));
						itm.setImage(v.cardImg(c));
						itm.setData(c);
						v.refreshControls();
						v.refreshFlags();
						v.callModEvent();
					}
					if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
						_comm.refMenuCard.call(c.cwxPath(true));
						_comm.refUseCount.call();
					}
					_comm.refreshToolBar();
					return;
				}
			}
			assert (0);
		}
		void createCard() { mixin(S_TRACE);
			if (_readOnly) return;
			static if (is(C:EnemyCard)) {
				if (!_summ.casts.length) return;
			}
			static if (is(C : MenuCard)) {
				auto c = new MenuCard("", false, [], "", "", 0, 0, 100, LAYER_MENU_CARD, "", -1);
			} else static if (is(C : EnemyCard)) {
				if (!_summ) return;
				if (_summ.casts.length == 0) return;
				auto c = new EnemyCard(0, (bool[ActionCardType]).init, "", 0, 0, 100, LAYER_MENU_CARD, "", -1, false, "", false, []);
			} else static assert (0);
			auto dlg = new SpCardDialog!(C)(_comm, _prop, getShell(), _summ, _forceSkin, _uc, c, true);
			dlg.appliedEvent ~= { mixin(S_TRACE);
				auto c = dlg.card;
				int index = insertIndex(_cards);
				_undo ~= new UndoInsert(this, _comm, _area, _summ, [index], []);
				appendCard(index, c, true, true);
				if (_summ && _summ.scenarioPath != "") _comm.refCardGroups.call();
				UndoEdit undo = null;
				dlg.applyEvent ~= { mixin(S_TRACE);
					undo = new UndoEdit(this, _comm, _area, _summ, [cast(int)cCountUntil!("a is b")(_area.cards, c)], []);
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
			if (_readOnly) return;
			static if (is(C:EnemyCard)) {
				if (!_summ.casts.length) return;
			}
			foreach (i; indices) { mixin(S_TRACE);
				if (_comm.stopOpen) break;
				editCard(_area.cards[i]);
			}
		}
		void editCard(C card) { mixin(S_TRACE);
			if (_readOnly) return;
			static if (is(C:EnemyCard)) {
				if (!_summ.casts.length) return;
			}
			auto p = card in _editDlgsC;
			if (p) { mixin(S_TRACE);
				p.active();
				return;
			}
			foreach (i, c; _area.cards) { mixin(S_TRACE);
				if (c is card) { mixin(S_TRACE);
					_imgp.select([cast(int)i + cardsIndex]);
					refreshSelected();
					break;
				}
			}
			UndoEdit undo = null;
			auto dlg = new SpCardDialog!(C)(_comm, _prop, getShell(), _summ, _forceSkin, _uc, card, false);
			dlg.applyEvent ~= { mixin(S_TRACE);
				undo = new UndoEdit(this, _comm, _area, _summ, [cast(int)cCountUntil!("a is b")(_area.cards, card)], []);
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
				if (_readOnly) return;
				int[] indices;
				foreach (itm; selItm.getParent().getSelection()) { mixin(S_TRACE);
					auto c = cast(C)itm.getData();
					if (c.name == newText) continue;
					indices ~= itm.getParent().indexOf(itm);
				}
				if (indices.length) { mixin(S_TRACE);
					_undo ~= new UndoEdit(this, _comm, _area, _summ, indices, []);
					foreach (index; indices) { mixin(S_TRACE);
						auto itm = _cards.getItem(index);
						auto c = cast(C)itm.getData();
						c.name = newText;
						if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
							_comm.refMenuCard.call(c.cwxPath(true));
						}
					}
					auto vs = views();
					foreach (v; vs) { mixin(S_TRACE);
						foreach (index; indices) { mixin(S_TRACE);
							auto itm = v._cards.getItem(index);
							auto c = cast(C)itm.getData();
							itm.setText(column, c.name);
						}
						v.refreshPanel();
						v.callModEvent();
					}
				}
				_comm.refreshToolBar();
			}
		} else static if (is(C : EnemyCard)) {
			void enemyEditEnd(TableItem selItm, int column, Combo combo) { mixin(S_TRACE);
				if (_readOnly) return;
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
						auto itm = _cards.getItem(index);
						auto c = cast(C)itm.getData();
						c.id = _summ.casts[i].id;
						if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
							_comm.refMenuCard.call(c.cwxPath(true));
						}
					}
					auto vs = views();
					foreach (v; vs) { mixin(S_TRACE);
						foreach (index; indices) { mixin(S_TRACE);
							auto itm = v._cards.getItem(index);
							auto c = cast(C)itm.getData();
							itm.setText(column, v.cardNameWithGroup(c));
						}
						v.refreshPanel();
						v.callModEvent();
					}
				}
				_comm.refreshToolBar();
			}
			void createEnemyCombo(TableItem itm, int column, out string[] strs, out string str) { mixin(S_TRACE);
				if (_readOnly) return;
				assert (_summ);
				auto c = cast(C)itm.getData();
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

		CommentDialog[C] _commentDlgsC;
		@property
		bool canWriteCommentC() { mixin(S_TRACE);
			if (_readOnly) return false;
			return _cards.getSelectionIndex() != -1;
		}
		void writeCommentC() { mixin(S_TRACE);
			if (_readOnly) return;
			auto sels = _cards.getSelectionIndices();
			if (!sels.length) return;
			if (_cardEdit) _cardEdit.enter();
			foreach (index; sels) { mixin(S_TRACE);
				if (_comm.stopOpen) break;
				writeCommentBImpl(index);
			}
		}
		void writeCommentBImpl(int index) { mixin(S_TRACE);
			auto card = cast(C)_cards.getItem(index).getData();
			assert (card !is null);
			auto p = card in _commentDlgsC;
			if (p) { mixin(S_TRACE);
				p.active();
				return;
			}
			auto dlg = new CommentDialog(_comm, _cards.getShell(), card.comment);
			dlg.title = .tryFormat(prop.msgs.dlgTitCommentWith, cardNameWithGroup(card));
			dlg.appliedEvent ~= { mixin(S_TRACE);
				_undo ~= new UndoEdit(this, _comm, _area, _summ, [index], []);
				card.comment = dlg.comment;
				foreach (v; views()) v._cards.redraw();
			};
			void refMenuCard(string cwxPath) { mixin(S_TRACE);
				if (!.cpeq(_area.cwxPath(true), .cpparent(cwxPath))) return;
				auto i = .cpindex(.cpbottom(cwxPath));
				if (_area.cards[i] !is card) return;
				dlg.title = .tryFormat(prop.msgs.dlgTitCommentWith, cardNameWithGroup(card));
			}
			void delMenuCard(string cwxPath) { mixin(S_TRACE);
				if (!.cpeq(_area.cwxPath(true), .cpparent(cwxPath))) return;
				auto i = .cpindex(.cpbottom(cwxPath));
				if (_area.cards[i] !is card) return;
				dlg.forceCancel();
			}
			void replText() { mixin(S_TRACE);
				dlg.title = .tryFormat(prop.msgs.dlgTitCommentWith, cardNameWithGroup(card));
			}
			_commentDlgsC[card] = dlg;
			_comm.refMenuCard.add(&refMenuCard);
			_comm.delMenuCard.add(&delMenuCard);
			_comm.replText.add(&replText);
			dlg.closeEvent ~= { mixin(S_TRACE);
				_commentDlgsC.remove(card);
				_comm.refMenuCard.remove(&refMenuCard);
				_comm.delMenuCard.remove(&delMenuCard);
				_comm.replText.remove(&replText);
			};
			dlg.open();
		}
	}
	PImg createCardImage(PImg, C2)(in C2 card, bool smoothing) { mixin(S_TRACE);
		static if (is(C2 : MenuCard) || is(C2 : const MenuCard)) {
			auto name = card.name;
			if (card.expandSPChars) { mixin(S_TRACE);
				name = .createSPCharPreview(_comm, _summ, &summSkin, _uc, name, false, null, null);
			}
			return createMenuCardImage!PImg(prop, summSkin, summary, name,
				cardImagePath(card), card.x, card.y, card.scale, smoothing, card.layer);
		} else static if (is(C2 : EnemyCard) || is(C2 : const EnemyCard)) {
			auto skin = summSkin;
			auto castCard = summary.cwCast(card.id);
			if (castCard) { mixin(S_TRACE);
				return createCastCardImage!PImg(_comm, skin, summary, card, castCard,
					card.x, card.y, card.scale, smoothing, debugMode, card.layer);
			} else { mixin(S_TRACE);
				return createCastCardImage!PImg(_comm, skin, summary, card, null,
					card.x, card.y, card.scale, smoothing, debugMode, card.layer);
			}
		} else static assert (0, C2);
	}
	string cardName(C2)(in C2 card) { mixin(S_TRACE);
		static if (is(C2 : MenuCard)) {
			return card.name;
		} else static if (is(C2 : EnemyCard)) {
			if (card.isOverrideName) return card.overrideName;
			auto castCard = summary.cwCast(card.id);
			return castCard ? castCard.name : "";
		} else static assert (0, C2);
	}
	string cardNameWithGroup(C2)(in C2 card) { mixin(S_TRACE);
		auto name = cardName(card);
		if (card.cardGroup == "") { mixin(S_TRACE);
			return name;
		} else { mixin(S_TRACE);
			return .tryFormat(_prop.msgs.nameWithCardGroup, card.cardGroup, name);
		}
	}
	CardImage[] cardImagePath(C2)(in C2 card) { mixin(S_TRACE);
		static if (is(typeof(card.paths))) {
			return card.paths;
		} else static if (is(typeof(summary.cwCast(card.id)))) {
			auto castCard = summary.cwCast(card.id);
			if (castCard) { mixin(S_TRACE);
				return castCard.paths;
			} else { mixin(S_TRACE);
				return [];
			}
		} else static assert (0, C2);
	}
	static if (UseBacks) {
		BgImageDialog[BgImage] _editDlgsB;
		void editBackApply(UndoEdit undo, BgImage back) { mixin(S_TRACE);
			if (_readOnly) return;
			assert (undo);
			_undo ~= undo;
			auto vs = views();
			foreach (i, b; _area.backs) { mixin(S_TRACE);
				if (b is back) { mixin(S_TRACE);
					foreach (v; vs) { mixin(S_TRACE);
						auto itm = v._backs.getItem(cast(int)i);
						auto fi = v.create(back);
						fi.visible = itm.getChecked();
						fi.fixed = fi.visible && itm.getGrayed();
						v._imgp.set(cast(int)i, fi);
						if (v._backs.isSelected(cast(int)i) && v._viewBacks) v._imgp.select(fi);
						itm.setText(back.name(_prop.parent));
						itm.setImage(v.backImg(back));
						itm.setData(b);
						v.refreshControls();
						v.refreshFlags();
						v.checked();
						v.callModEvent();
					}
					if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
						_comm.refBgImage.call(b.cwxPath(true));
						_comm.refUseCount.call();
					}
					_comm.refreshToolBar();
					return;
				}
			}
			assert (0);
		}
		void createBackground() { mixin(S_TRACE);
			if (_readOnly) return;
			createBackgroundImpl(0);
		}
		void createTextCell() { mixin(S_TRACE);
			if (_readOnly) return;
			createBackgroundImpl(1);
		}
		void createColorCell() { mixin(S_TRACE);
			if (_readOnly) return;
			createBackgroundImpl(2);
		}
		void createPCCell() { mixin(S_TRACE);
			if (_readOnly) return;
			createBackgroundImpl(3);
		}
		void createBackgroundImpl(int type) { mixin(S_TRACE);
			if (_readOnly) return;
			BgImage b = null;
			BgImageDialog dlg = null;
			final switch (type) {
			case 0:
				auto ic = new ImageCell;
				dlg = new ImageCellDialog(_comm, _prop, getShell(), _summ, _forceSkin, _uc, ic, true);
				b = ic;
				break;
			case 1:
				auto tc = new TextCell;
				tc.width = _prop.var.etc.textCellDefaultWidth;
				tc.height = _prop.var.etc.textCellDefaultHeight;
				dlg = new TextCellDialog(_comm, _prop, getShell(), _summ, _forceSkin, _uc, tc, true);
				b = tc;
				break;
			case 2:
				auto cc = new ColorCell;
				cc.width = _prop.var.etc.colorCellDefaultWidth;
				cc.height = _prop.var.etc.colorCellDefaultHeight;
				dlg = new ColorCellDialog(_comm, _prop, getShell(), _summ, _uc, cc, true);
				b = cc;
				break;
			case 3:
				auto pc = new PCCell;
				pc.width = _prop.looks.cardSize.width;
				pc.height = _prop.looks.cardSize.height;
				dlg = new PCCellDialog(_comm, _prop, getShell(), _summ, _forceSkin, _uc, pc, true);
				b = pc;
				break;
			}
			dlg.appliedEvent ~= { mixin(S_TRACE);
				auto b = dlg.back;
				int index = insertIndex(_backs);
				_undo ~= new UndoInsert(this, _comm, _area, _summ, [], [index]);
				appendBgImage(index, b, true, true);
				UndoEdit undo = null;
				if (_summ && _summ.scenarioPath != "") _comm.refCellNames.call();
				dlg.applyEvent ~= { mixin(S_TRACE);
					undo = new UndoEdit(this, _comm, _area, _summ, [], [cast(int)cCountUntil!("a is b")(_area.backs, b)]);
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
			if (_readOnly) return;
			foreach (i; indices) { mixin(S_TRACE);
				if (_comm.stopOpen) break;
				editBack(_area.backs[i]);
			}
		}
		void editBack(BgImage back) { mixin(S_TRACE);
			if (_readOnly) return;
			auto p = back in _editDlgsB;
			if (p) { mixin(S_TRACE);
				p.active();
				return;
			}
			foreach (i, b; _area.backs) { mixin(S_TRACE);
				if (b is back) { mixin(S_TRACE);
					_imgp.select([cast(int)i]);
					refreshSelected();
					break;
				}
			}
			UndoEdit undo = null;
			BgImageDialog dlg = null;
			auto ic = cast(ImageCell)back;
			if (ic) { mixin(S_TRACE);
				dlg = new ImageCellDialog(_comm, _prop, getShell(), _summ, _forceSkin, _uc, ic, false);
			}
			auto tc = cast(TextCell)back;
			if (tc) { mixin(S_TRACE);
				dlg = new TextCellDialog(_comm, _prop, getShell(), _summ, _forceSkin, _uc, tc, false);
			}
			auto cc = cast(ColorCell)back;
			if (cc) { mixin(S_TRACE);
				dlg = new ColorCellDialog(_comm, _prop, getShell(), _summ, _uc, cc, false);
			}
			auto pc = cast(PCCell)back;
			if (pc) { mixin(S_TRACE);
				dlg = new PCCellDialog(_comm, _prop, getShell(), _summ, _forceSkin, _uc, pc, false);
			}
			dlg.applyEvent ~= { mixin(S_TRACE);
				undo = new UndoEdit(this, _comm, _area, _summ, [], [cast(int)cCountUntil!("a is b")(_area.backs, back)]);
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
			if (_readOnly) return;
			int i = combo.getSelectionIndex();
			_selectableBgImages = [];
			if (-1 == i) return;
			auto vs = views();
			auto index = itm.getParent().indexOf(itm);
			auto bg = cast(BgImage)itm.getData();
			if (auto pc = cast(PCCell)bg) { mixin(S_TRACE);
				auto pcNumber = combo.getSelectionIndex() + 1;
				if (pc.pcNumber == pcNumber) return;
				_undo ~= new UndoEdit(this, _comm, _area, _summ, [], [index]);
				pc.pcNumber = pcNumber;
				auto name = pc.name(_prop.parent);
				foreach (v; vs) { mixin(S_TRACE);
					v._backs.getItem(index).setText(column, name);
				}
			}
			if (auto b = cast(ImageCell)bg) { mixin(S_TRACE);
				if (0 == i) { mixin(S_TRACE);
					if (b.path == "") return;
					_undo ~= new UndoEdit(this, _comm, _area, _summ, [], [index]);
					b.path = "";
					foreach (v; vs) { mixin(S_TRACE);
						v._backs.getItem(index).setText(column, "");
					}
				} else { mixin(S_TRACE);
					string mt = combo.getText();
					if (std.string.startsWith(mt, "/")) { mixin(S_TRACE);
						mt = mt["/".length .. $];
					}
					if (b.path == mt) return;
					_undo ~= new UndoEdit(this, _comm, _area, _summ, [], [index]);
					b.path = mt;
					auto name = b.name(_prop.parent);
					foreach (v; vs) { mixin(S_TRACE);
						v._backs.getItem(index).setText(column, name);
					}
				}
			}
			foreach (v; vs) { mixin(S_TRACE);
				v.refreshPanel();
				v.callModEvent();
			}
			if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
				_comm.refBgImage.call(bg.cwxPath(true));
			}
			_comm.refreshToolBar();
		}
		bool bgImageCanEdit(TableItem itm, int column) { mixin(S_TRACE);
			return !_readOnly && (cast(ImageCell)itm.getData()) !is null || (cast(PCCell)itm.getData()) !is null;
		}
		void createBgImageCombo(TableItem itm, int column, out string[] strs, out string str, out bool canIncSearch) { mixin(S_TRACE);
			if (_readOnly) return;
			_selectableBgImages = [];
			if (auto pc = cast(PCCell)itm.getData()) { mixin(S_TRACE);
				foreach (i; 0 .. _prop.looks.partyCardXY.length) { mixin(S_TRACE);
					auto s = .tryFormat(_prop.msgs.pc, i + 1);
					strs ~= s;
					if (i + 1 == pc.pcNumber) {
						str = s;
					}
				}
				canIncSearch = false;
				return;
			}
			auto b = cast(ImageCell)itm.getData();
			if (!b) return;
			strs ~= _prop.msgs.defaultSelection(_prop.msgs.imageNone);
			str = _prop.msgs.defaultSelection(_prop.msgs.imageNone);
			string p = summSkin.findImagePath(b.path, _summ ? _summ.scenarioPath : null, _summ ? _summ.dataVersion : LATEST_VERSION);
			p = nabs(p);
			foreach (t; summSkin.tables(_prop.var.etc.logicalSort)) { mixin(S_TRACE);
				// スケーリングされたイメージファイルを除外
				if (t.noScaledPath != "") continue;
				strs ~= t;
				foreach (tableDir; summSkin.tableDirs) {mixin(S_TRACE);
					if (cfnmatch(p, nabs(std.path.buildPath(tableDir, t)))) { mixin(S_TRACE);
						str = t;
						break;
					}
				}
			}
			_selectableBgImages = strs;
			if (!_summ) return;
			void recurse(string dir, string sDir) { mixin(S_TRACE);
				foreach (file; clistdir(dir)) { mixin(S_TRACE);
					if (containsPath(_prop.var.etc.ignorePaths, file)) continue;
					string full = std.path.buildPath(dir, file);
					string sFile = sDir ~ file;
					if (!_summ || _summ.scenarioPath == "" || (!_summ.legacy && _summ.loadScaledImage)) { mixin(S_TRACE);
						// スケーリングされたイメージファイルを除外
						if (sFile.noScaledPath != "") continue;
					}
					if (isDir(full)) { mixin(S_TRACE);
						recurse(full, sFile ~ std.path.dirSeparator);
					} else { mixin(S_TRACE);
						if (!summSkin.isBgImage(file)) continue;
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
			canIncSearch = true;
		}
		string[] bgImageIncSearch(IncSearch incSearch) { mixin(S_TRACE);
			string[] r;
			r ~= _prop.msgs.defaultSelection(_prop.msgs.imageNone);
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

		CommentDialog[BgImage] _commentDlgsB;
		@property
		bool canWriteCommentB() { mixin(S_TRACE);
			if (_readOnly) return false;
			return _backs.getSelectionIndex() != -1;
		}
		void writeCommentB() { mixin(S_TRACE);
			if (_readOnly) return;
			auto sels = _backs.getSelectionIndices();
			if (!sels.length) return;
			if (_backEdit) _backEdit.enter();
			foreach (index; sels) { mixin(S_TRACE);
				if (_comm.stopOpen) break;
				writeCommentCImpl(index);
			}
		}
		void writeCommentCImpl(int index) { mixin(S_TRACE);
			auto back = cast(BgImage)_backs.getItem(index).getData();
			assert (back !is null);
			auto p = back in _commentDlgsB;
			if (p) { mixin(S_TRACE);
				p.active();
				return;
			}
			auto dlg = new CommentDialog(_comm, _backs.getShell(), back.comment);
			dlg.title = .tryFormat(prop.msgs.dlgTitCommentWith, back.name(_comm.prop.parent));
			dlg.appliedEvent ~= { mixin(S_TRACE);
				_undo ~= new UndoEdit(this, _comm, _area, _summ, [], [index]);
				back.comment = dlg.comment;
				foreach (v; views()) v._backs.redraw();
			};
			void refBgImage(string cwxPath) { mixin(S_TRACE);
				if (!.cpeq(_area.cwxPath(true), .cpparent(cwxPath))) return;
				auto i = .cpindex(.cpbottom(cwxPath));
				if (_area.backs[i] !is back) return;
				dlg.title = .tryFormat(prop.msgs.dlgTitCommentWith, back.name(_comm.prop.parent));
			}
			void delBgImage(string cwxPath) { mixin(S_TRACE);
				if (!.cpeq(_area.cwxPath(true), .cpparent(cwxPath))) return;
				auto i = .cpindex(.cpbottom(cwxPath));
				if (_area.backs[i] !is back) return;
				dlg.forceCancel();
			}
			void replText() { mixin(S_TRACE);
				dlg.title = .tryFormat(prop.msgs.dlgTitCommentWith, back.name(_comm.prop.parent));
			}
			_commentDlgsB[back] = dlg;
			_comm.refBgImage.add(&refBgImage);
			_comm.delBgImage.add(&delBgImage);
			_comm.replText.add(&replText);
			dlg.closeEvent ~= { mixin(S_TRACE);
				_commentDlgsB.remove(back);
				_comm.refBgImage.remove(&refBgImage);
				_comm.delBgImage.remove(&delBgImage);
				_comm.replText.remove(&replText);
			};
			dlg.open();
		}

		void refreshTextCellF(cwx.flag.Flag[] flags, Step[] steps, cwx.flag.Variant[] variants) { mixin(S_TRACE);
			refreshTextCell();
		}
		void refreshTextCell() { mixin(S_TRACE);
			foreach (i, img; _imgp.images.dup) { mixin(S_TRACE);
				if (img.type == ImageType.Text) { mixin(S_TRACE);
					auto itm = _backs.getItem(cast(int)i);
					auto tc = cast(TextCell)itm.getData();
					assert (tc !is null);
					img.title = tc.text;
					img.createImage();
					_imgp.redrawImage(img);
					itm.setText(tc.name(_prop.parent));
				}
			}
		}
		string previewText(string base) { mixin(S_TRACE);
			string[char] names;
			VarValue[string] flags;
			VarValue[string] steps;
			VarValue[string] variants;
			VarValue[string] sysSteps;
			getPreviewValues(_prop, _summ, null, SPCHAR_TEXT, names, flags, steps, variants, sysSteps);
			return simpleFormatMsg(base, flags, steps, variants, sysSteps, names, ver => _prop.isTargetVersion(_summ, ver),
				_prop.sys.prefixSystemVarName);
		}
	}

	@property
	bool isViewMsg() { return _viewMsg; }
	@property
	bool isViewParty() { return _viewParty; }
	static if (RefCards) {
		@property
		bool isViewRefCards() { return _showRefCards; }
	}
	static if (UseCards) {
		@property
		bool isFixedCards() { return _fixedC || _readOnly; }
		@property
		bool spCustom() { return !_area.spAuto; }
	}
	static if (UseBacks) {
		@property
		bool isFixedCells() { return _fixedB || _readOnly; }
		@property
		bool isFixedBackground() { return _fixedFirstB || _readOnly; }
	}
	static if (is(A:Battle)) {
		MenuItem _possibleToRunAwayMenu;
		Button _possibleToRunAwayCheck;
		@property
		const
		bool canReversePossibleToRunAway() { mixin(S_TRACE);
			return !_readOnly && (!(_summ && _summ.legacy) || !_area.possibleToRunAway);
		}
		@property
		bool isPossibleToRunAway() { return _area.possibleToRunAway; }
		@property
		void reversePossibleToRunAway() { mixin(S_TRACE);
			_undo ~= new UndoPossibleToRunAway(this, _comm, _area, _summ);
			_area.possibleToRunAway = !_area.possibleToRunAway;
			callModEvent();
			foreach (v; views()) { mixin(S_TRACE);
				// 同期
				if (v !is this) { mixin(S_TRACE);
					v._possibleToRunAwayMenu.setSelection(_area.possibleToRunAway);
					v._possibleToRunAwayCheck.setSelection(_area.possibleToRunAway);
					v.callModEvent();
				}
			}
			_comm.refreshToolBar();
		}
	}
	@property
	bool isShowGrid() { return _showGrid; }
	private void setupTLP(TopLevelPanel tlp) { mixin(S_TRACE);
		_tlp.putMenuChecked(MenuID.ShowParty, &reverseViewParty, &isViewParty, null);
		static if (UseCards && UseBacks) {
			_tlp.putMenuChecked(MenuID.ShowCard, &reverseViewCards, &isViewCards, null);
			_tlp.putMenuChecked(MenuID.ShowBack, &reverseViewBacks, &isViewBacks, null);
		}
		static if (UseCards) {
			_tlp.putMenuChecked(MenuID.AutoArrange, &setAuto, &_area.spAuto, () => !_readOnly);
			_tlp.putMenuChecked(MenuID.ManualArrange, &setCustom, &spCustom, () => !_readOnly);
			_tlp.putMenuChecked(MenuID.FixedCards, &reverseFixedCards, &isFixedCards, null);
		}
		static if (UseBacks) {
			_tlp.putMenuChecked(MenuID.FixedCells, &reverseFixedCells, &isFixedCells, null);
			_tlp.putMenuChecked(MenuID.FixedBackground, &reverseFixedBackground, &isFixedBackground, null);
		}
		_tlp.putMenuChecked(MenuID.ShowGrid, &reverseShowGrid, &isShowGrid, null);
		_tlp.putMenuAction(MenuID.Refresh, &refresh, null);
		_tlp.putMenuAction(MenuID.Undo, &undo, () => !_readOnly && _undo.canUndo);
		_tlp.putMenuAction(MenuID.Redo, &redo, () => !_readOnly && _undo.canRedo);
		_tlp.putMenuAction(MenuID.Up, &up, &canUp);
		_tlp.putMenuAction(MenuID.Down, &down, &canDown);
		static if (is(A:Battle)) {
			_tlp.putMenuChecked(MenuID.PossibleToRunAway, &reversePossibleToRunAway, &isPossibleToRunAway, &canReversePossibleToRunAway);
		}
	}

	/// メニューにAreaViewで使用するアイテムを設定する。
	/// Params:
	/// bar = メニュー。
	void setupMenu(Menu bar) { mixin(S_TRACE);
		auto mv = createMenu(_comm, bar, MenuID.CardsAndBacks);
		_vpMenu = createMenuItem(_comm, mv, MenuID.ShowParty, &reverseViewParty, null, SWT.CHECK);
		static if (is(C:MenuCard)) {
			.setupToggle(_vpMenu, _prop.var.etc.viewPartyCardsArea);
		} else static if (is(C:EnemyCard)) {
			.setupToggle(_vpMenu, _prop.var.etc.viewPartyCardsBattle);
		} else static if (!UseCards) {
			.setupToggle(_vpMenu, _prop.var.etc.viewPartyCardsEvent);
		} else static assert (0);
		_vmMenu = createMenuItem(_comm, mv, MenuID.ShowMsg, &reverseViewMsg, null, SWT.CHECK);
		static if (is(C:MenuCard)) {
			.setupToggle(_vpMenu, _prop.var.etc.viewMessageArea);
		} else static if (is(C:EnemyCard)) {
			.setupToggle(_vpMenu, _prop.var.etc.viewMessageBattle);
		} else static if (!UseCards) {
			.setupToggle(_vpMenu, _prop.var.etc.viewMessageEvent);
		} else static assert (0);
		static if (RefCards) {
			_vrMenu = createMenuItem(_comm, mv, MenuID.ShowRefCards, &reverseViewRefCards, null, SWT.CHECK);
			.setupToggle(_vrMenu, _prop.var.etc.viewReferenceCards);
		}
		if (!_readOnly) { mixin(S_TRACE);
			new MenuItem(mv, SWT.SEPARATOR);
			static if (UseCards) {
				_vfcMenu = createMenuItem(_comm, mv, MenuID.FixedCards, &reverseFixedCards, null, SWT.CHECK);
				static if (is(C:MenuCard)) {
					.setupToggle(_vfcMenu, _prop.var.etc.fixedImagesMenuCards);
				} else static if (is(C:EnemyCard)) {
					.setupToggle(_vfcMenu, _prop.var.etc.fixedImagesBattle);
				} else static assert (0);
			}
			static if (UseBacks) {
				_vfbMenu = createMenuItem(_comm, mv, MenuID.FixedCells, &reverseFixedCells, null, SWT.CHECK);
				_vffbMenu = createMenuItem(_comm, mv, MenuID.FixedBackground, &reverseFixedBackground, null, SWT.CHECK);
				static if (is(A:Area)) {
					.setupToggle(_vfbMenu, _prop.var.etc.fixedImagesBackground);
					.setupToggle(_vffbMenu, _prop.var.etc.fixedImagesBackground);
				} else static if (is(A:BgImageContainer)) {
					auto fixed = false;
					if (_summ) { mixin(S_TRACE);
						.setupToggle(_vfbMenu, _prop.var.etc.fixedImagesEventBackground);
						.setupToggle(_vffbMenu, _prop.var.etc.fixedImagesEventBackground);
					} else { mixin(S_TRACE);
						.setupToggle(_vfbMenu, _prop.var.etc.fixedImagesDefaultBackground);
						.setupToggle(_vffbMenu, _prop.var.etc.fixedImagesDefaultBackground);
					}
				} else static assert (0);
			}
		}
		static if (is(C : EnemyCard) || RefCards) {
			if (_summ) { mixin(S_TRACE);
				new MenuItem(mv, SWT.SEPARATOR);
				_dbgMenu = createMenuItem(_comm, mv, MenuID.ShowEnemyCardProp, &reverseDebugMode, null, SWT.CHECK);
				.setupToggle(_dbgMenu, _prop.var.etc.viewEnemyCardDebug);
			}
		}
		static if (UseCards && UseBacks) {
			new MenuItem(mv, SWT.SEPARATOR);
			_vcMenu = createMenuItem(_comm, mv, MenuID.ShowCard, &reverseViewCards, null, SWT.CHECK);
			.setupToggle(_vcMenu, _prop.var.etc.viewCards);
			_vbMenu = createMenuItem(_comm, mv, MenuID.ShowBack, &reverseViewBacks, null, SWT.CHECK);
			.setupToggle(_vbMenu, _prop.var.etc.viewBgImages);
		}
		static if (UseCards) {
			new MenuItem(mv, SWT.SEPARATOR);
			_autoMenu = createMenuItem(_comm, mv, MenuID.AutoArrange, &setAuto, () => !_readOnly, SWT.RADIO);
			_customMenu = createMenuItem(_comm, mv, MenuID.ManualArrange, &setCustom, () => !_readOnly, SWT.RADIO);
			_autoMenu.setSelection(_area.spAuto);
			_customMenu.setSelection(!_area.spAuto);
		}
		static if (is(A:Battle)) {
			new MenuItem(mv, SWT.SEPARATOR);
			_possibleToRunAwayMenu = createMenuItem(_comm, bar, MenuID.PossibleToRunAway, &reversePossibleToRunAway, &canReversePossibleToRunAway, SWT.CHECK);
			_possibleToRunAwayMenu.setSelection(_area.possibleToRunAway);
		}
		new MenuItem(mv, SWT.SEPARATOR);
		_sgMenu = createMenuItem(_comm, mv, MenuID.ShowGrid, &reverseShowGrid, null, SWT.CHECK);
		.setupToggle(_sgMenu, _prop.var.etc.showGrid);
		if (!_readOnly) { mixin(S_TRACE);
			new MenuItem(mv, SWT.SEPARATOR);
			static if (is(C == MenuCard)) {
				createMenuItem(_comm, mv, MenuID.NewMenuCard, &createCard, () => !_readOnly);
			} else static if (is(C == EnemyCard)) {
				createMenuItem(_comm, mv, MenuID.NewEnemyCard, &createCard, () => !_readOnly && _summ && _summ.casts.length);
			}
			static if (UseBacks) {
				createMenuItem(_comm, mv, MenuID.NewBack, &createBackground, () => !_readOnly);
				createMenuItem(_comm, mv, MenuID.NewTextCell, &createTextCell, () => !_readOnly);
				createMenuItem(_comm, mv, MenuID.NewColorCell, &createColorCell, () => !_readOnly);
				createMenuItem(_comm, mv, MenuID.NewPCCell, &createPCCell, () => !_readOnly && !(_summ && _summ.legacy));
			}
		}
	}

	private bool _setupToolBar = false;
	private void setupToolBar0(ToolBar bar) { mixin(S_TRACE);
		static if (is(A:Area)) {
			if (cast(AreaSceneWindow)tlpData(this).tlp) { mixin(S_TRACE);
				createToolItem(_comm, bar, MenuID.EditEvent, () => openEvent(false), null);
				new ToolItem(bar, SWT.SEPARATOR);
				if (_prop.var.etc.showDuplicateViewInToolBar) { mixin(S_TRACE);
					createToolItem(_comm, bar, MenuID.EditSceneDup, () => openDup(), null);
					new ToolItem(bar, SWT.SEPARATOR);
				}
			}
		} else static if (is(A:Battle)) {
			if (cast(BattleSceneWindow)tlpData(this).tlp) { mixin(S_TRACE);
				auto itm = createToolItem(_comm, bar, MenuID.EditEvent, () => openEvent(false), null);
				itm.setImage(_prop.images.editEventBattle);
				new ToolItem(bar, SWT.SEPARATOR);
				if (_prop.var.etc.showDuplicateViewInToolBar) { mixin(S_TRACE);
					itm = createToolItem(_comm, bar, MenuID.EditSceneDup, () => openDup(), null);
					itm.setImage(_prop.images.battleSceneViewDup);
					new ToolItem(bar, SWT.SEPARATOR);
				}
			}
		}
		if (!_tlp) { mixin(S_TRACE);
			createToolItem(_comm, bar, MenuID.Refresh, &refresh, null);
			new ToolItem(bar, SWT.SEPARATOR);
		}
		if (!_readOnly) { mixin(S_TRACE);
			if (!_tlp) { mixin(S_TRACE);
				createToolItem(_comm, bar, MenuID.Undo, &undo, () => !_readOnly && _undo.canUndo);
				createToolItem(_comm, bar, MenuID.Redo, &redo, () => !_readOnly && _undo.canRedo);
				new ToolItem(bar, SWT.SEPARATOR);
			}
			createToolItem(_comm, bar, MenuID.Up, &up, &canUp);
			createToolItem(_comm, bar, MenuID.Down, &down, &canDown);
			new ToolItem(bar, SWT.SEPARATOR);
		}
		_vpTMenu = createToolItem(_comm, bar, MenuID.ShowParty, &reverseViewParty, null, SWT.CHECK);
	}
	/// ツールバーにAreaViewで使用するアイテムを設定する。
	/// Params:
	/// bar = ツールバー。
	private bool setupToolBar(ToolBar bar) { mixin(S_TRACE);
		if (_setupToolBar) return false;
		_setupToolBar = true;
		static if (is(C:MenuCard)) {
			.setupToggle(_vpTMenu, _prop.var.etc.viewPartyCardsArea);
		} else static if (is(C:EnemyCard)) {
			.setupToggle(_vpTMenu, _prop.var.etc.viewPartyCardsBattle);
		} else static if (!UseCards) {
			.setupToggle(_vpTMenu, _prop.var.etc.viewPartyCardsEvent);
		} else static assert (0);
		_vmTMenu = createToolItem(_comm, bar, MenuID.ShowMsg, &reverseViewMsg, null, SWT.CHECK);
		static if (is(C:MenuCard)) {
			.setupToggle(_vmTMenu, _prop.var.etc.viewMessageArea);
		} else static if (is(C:EnemyCard)) {
			.setupToggle(_vmTMenu, _prop.var.etc.viewMessageBattle);
		} else static if (!UseCards) {
			.setupToggle(_vmTMenu, _prop.var.etc.viewMessageEvent);
		} else static assert (0);
		static if (RefCards) {
			_vrTMenu = createToolItem(_comm, bar, MenuID.ShowRefCards, &reverseViewRefCards, null, SWT.CHECK);
			.setupToggle(_vrTMenu, _prop.var.etc.viewReferenceCards);
		}
		static if (is(C : EnemyCard) || RefCards) {
			if (_summ) { mixin(S_TRACE);
				new ToolItem(bar, SWT.SEPARATOR);
				_dbgTMenu = createToolItem(_comm, bar, MenuID.ShowEnemyCardProp, &reverseDebugMode, null, SWT.CHECK);
				.setupToggle(_dbgTMenu, _prop.var.etc.viewEnemyCardDebug);
			}
		}
		static if (UseCards) {
			new ToolItem(bar, SWT.SEPARATOR);
			_autoTMenu = createToolItem(_comm, bar, MenuID.AutoArrange, &setAuto, () => !_readOnly, SWT.RADIO);
			_customTMenu = createToolItem(_comm, bar, MenuID.ManualArrange, &setCustom, () => !_readOnly, SWT.RADIO);
			_autoTMenu.setSelection(_area.spAuto);
			_customTMenu.setSelection(!_area.spAuto);
		}
		new ToolItem(bar, SWT.SEPARATOR);
		_xSpn = createSpinner(bar, _prop.msgs.left, _prop.var.etc.posLeftMax, -(cast(int)_prop.var.etc.posLeftMax), 0,
			&editSpn!("a.newX = value;"), &enterSpn!("a.x = value;", "a.newX = value;"),
			&cancelSpn!("a.x", "fi.newX = a.x;"), _readOnly);
		new ToolItem(bar, SWT.SEPARATOR);
		_ySpn = createSpinner(bar, _prop.msgs.top, _prop.var.etc.posTopMax, -(cast(int)_prop.var.etc.posTopMax), 0,
			&editSpn!("a.newY = value;"), &enterSpn!("a.y = value;", "a.newY = value;"),
			&cancelSpn!("a.y", "fi.newY = a.y;"), _readOnly);
		static if (UseBacks) {
			new ToolItem(bar, SWT.SEPARATOR);
			_wSpn = createSpinner(bar, _prop.msgs.width, _prop.var.etc.backWidthMax, 0, 0,
				&editSpnBack!("a.newWidth = value;"), &enterSpnBack!("a.width = value;", "a.newWidth = value;"),
				&cancelSpnBack!("a.width", "fi.newWidth = a.width;"), _readOnly);
			new ToolItem(bar, SWT.SEPARATOR);
			_hSpn = createSpinner(bar, _prop.msgs.height, _prop.var.etc.backHeightMax, 0, 0,
				&editSpnBack!("a.newHeight = value;"), &enterSpnBack!("a.height = value;", "a.newHeight = value;"),
				&cancelSpnBack!("a.height", "fi.newHeight = a.height;"), _readOnly);
		}
		static if (UseCards) {
			new ToolItem(bar, SWT.SEPARATOR);
			_scaleSpn = createSpinner(bar, _prop.msgs.scale, _prop.var.etc.cardScaleMax, _prop.var.etc.cardScaleMin, 100,
				&editSpnCard!("a.newScale = value;"),
				&enterSpnCard!("a.scale = value;", "a.newScale = value;"),
				&cancelSpnCard!("a.scale", "fi.newScale = a.scale;"), _readOnly);
			createLabel(bar, "%");
		}
		static if (UseBacks) {
			new ToolItem(bar, SWT.SEPARATOR);
			_maskTMenu = createToolItem(_comm, bar, MenuID.Mask, &setMask, { mixin(S_TRACE);
				if (_readOnly) return false;
				foreach (itm; _backs.getSelection()) { mixin(S_TRACE);
					if (cast(ImageCell)itm.getData()) { mixin(S_TRACE);
						return true;
					}
				}
				return false;
			}, SWT.CHECK);
			_maskTMenu.setEnabled(false);
		}
		static if (is(C == EnemyCard)) {
			new ToolItem(bar, SWT.SEPARATOR);
			_escTMenu = createToolItem(_comm, bar, MenuID.Escape, &setEscape, () => !_readOnly && _cards.getSelectionIndex() != -1, SWT.CHECK);
			_escTMenu.setEnabled(false);
		}
		new ToolItem(bar, SWT.SEPARATOR);
		_layerSpn = createSpinner(bar, _prop.msgs.layer, _prop.var.etc.layerMax, LAYER_BACK_CELL, LAYER_BACK_CELL,
			&editSpn!("a.layer = value * 10;"), &enterSpn!("a.layer = value;", "a.layer = value * 10;"),
			&cancelSpn!("a.layer", "fi.layer = a.layer * 10;"), _readOnly);
		_layerSpn.setToolTipText(.tryFormat(_prop.msgs.layerValues, LAYER_BACK_CELL, LAYER_MENU_CARD, LAYER_PLAYER_CARD, LAYER_MESSAGE));
		new ToolItem(bar, SWT.SEPARATOR);
		_sgTMenu = createToolItem(_comm, bar, MenuID.ShowGrid, &reverseShowGrid, null, SWT.CHECK);
		.setupToggle(_sgTMenu, _prop.var.etc.showGrid);
		new ToolItem(bar, SWT.SEPARATOR);
		createLabel(bar, _prop.msgs.left ~ ":");
		auto gridX = new Spinner(bar, SWT.BORDER);
		initSpinner(gridX);
		gridX.setMaximum(_prop.looks.viewSize.width);
		gridX.setMinimum(1);
		gridX.setSelection(_gridX);
		.setupSpinner(gridX, _prop.var.etc.gridX);
		void updateGridX() { mixin(S_TRACE);
			_gridX = gridX.getSelection();
			refreshGrid();
		}
		.listener(gridX, SWT.Selection, &updateGridX);
		.listener(gridX, SWT.Modify, &updateGridX);
		createToolItemC(bar, gridX);
		new ToolItem(bar, SWT.SEPARATOR);
		createLabel(bar, _prop.msgs.top ~ ":");
		auto gridY = new Spinner(bar, SWT.BORDER);
		initSpinner(gridY);
		gridY.setMaximum(_prop.looks.viewSize.height);
		gridY.setMinimum(1);
		gridY.setSelection(_gridY);
		.setupSpinner(gridY, _prop.var.etc.gridY);
		void updateGridY() { mixin(S_TRACE);
			_gridY = gridY.getSelection();
			refreshGrid();
		}
		.listener(gridY, SWT.Selection, &updateGridY);
		.listener(gridY, SWT.Modify, &updateGridY);
		createToolItemC(bar, gridY);
		bar.getParent().layout();
		return true;
	}
	private class FlagsDispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_comm.refFlagAndStep.remove(&refFlag);
			_comm.delFlagAndStep.remove(&refFlag);
		}
	}
	private class SelFlag : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			if (_readOnly) return;
			int index = _flag.getSelectionIndex();
			string flag = index <= 0 ? "" : _flag.getText();
			auto vs = views();
			auto undo = createUndoEdit();
			bool chg = false;
			static if (UseCards) {
				foreach (c, i; _editC) { mixin(S_TRACE);
					if (c.flag != flag) { mixin(S_TRACE);
						c.flag = flag;
						foreach (v; vs) v._cards.getItem(i).setImage(v.cardImg(c));
						chg = true;
						_comm.refMenuCard.call(c.cwxPath(true));
					}
				}
			}
			static if (UseBacks) {
				foreach (b, i; _editB) { mixin(S_TRACE);
					if (b.flag != flag) { mixin(S_TRACE);
						b.flag = flag;
						foreach (v; vs) v._backs.getItem(i).setImage(v.backImg(b));
						chg = true;
						_comm.refBgImage.call(b.cwxPath(true));
					}
				}
			}
			_undo ~= undo;
			foreach (v; vs) { mixin(S_TRACE);
				v.refreshStatusLine();
				v.refreshFlags();
			}
			callModEvent();
			if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
				_comm.refUseCount.call();
			}
		}
	}
	private void refFlag(cwx.flag.Flag[] flag, Step[] step, cwx.flag.Variant[] variants) { mixin(S_TRACE);
		if (_readOnly) return;
		if (!flag.length) return;
		refreshFlag();
	}
	private void refreshFlag() { mixin(S_TRACE);
		if (!_flag) return;
		string f = _flag.getText();
		_flag.removeAll();
		_hasFlag = false;
		_flag.add(_prop.msgs.defaultSelection(_prop.msgs.noFlagRef));
		_flag.select(0);
		.sortedWithPath(.allVars!(cwx.flag.Flag)(_summ.flagDirRoot, null), _prop.var.etc.logicalSort, (cwx.flag.Flag fl) { mixin(S_TRACE);
			auto path = fl.path;
			_hasFlag = true;
			if (!_flagIncSearch.match(path)) return;
			_flag.add(path);
			if (path == f) _flag.setText(path);
		});
	}

	void reverseViewParty() { mixin(S_TRACE);
		_viewParty = !_viewParty;
		foreach (i; partyIndex .. partyIndex + _prop.looks.partyCardXY.length) { mixin(S_TRACE);
			auto img = _imgp.images[i];
			img.visible = _viewParty;
			_imgp.redrawImage(img);
		}
		if (_vpMenu) _vpMenu.setSelection(_viewParty);
		if (_vpTMenu) _vpTMenu.setSelection(_viewParty);
		static if (is(C:MenuCard)) {
			_prop.var.etc.viewPartyCardsArea = _viewParty;
		} else static if (is(C:EnemyCard)) {
			_prop.var.etc.viewPartyCardsBattle = _viewParty;
		} else static if (!UseCards) {
			_prop.var.etc.viewPartyCardsEvent = _viewParty;
		} else static assert (0);
	}
	void reverseViewMsg() { mixin(S_TRACE);
		_viewMsg = !_viewMsg;
		auto img = _imgp.images[messageIndex];
		img.visible = _viewMsg;
		_imgp.redrawImage(img);
		if (_vmMenu) _vmMenu.setSelection(_viewMsg);
		if (_vmTMenu) _vmTMenu.setSelection(_viewMsg);
		static if (is(C:MenuCard)) {
			_prop.var.etc.viewMessageArea = _viewMsg;
		} else static if (is(C:EnemyCard)) {
			_prop.var.etc.viewMessageBattle = _viewMsg;
		} else static if (!UseCards) {
			_prop.var.etc.viewMessageEvent = _viewMsg;
		} else static assert (0);
	}
	static if (RefCards) {
		void reverseViewRefCards() { mixin(S_TRACE);
			_showRefCards = !_showRefCards;
			if (_vrMenu) _vrMenu.setSelection(_showRefCards);
			if (_vrTMenu) _vrTMenu.setSelection(_showRefCards);
			foreach (i; refCardIndex .. _imgp.images.length) { mixin(S_TRACE);
				auto pImg = _imgp.images[i];
				pImg.visible = _showRefCards;
				_imgp.redrawImage(pImg);
			}
			_prop.var.etc.viewReferenceCards = _showRefCards;
		}
	}
	static if (UseCards) {
		void reverseFixedCards() { mixin(S_TRACE);
			if (_readOnly) return;
			_fixedC = !_fixedC;
			checked();
			if (_vfcMenu) _vfcMenu.setSelection(_fixedC);
			if (_vfcTMenu) _vfcTMenu.setSelection(_fixedC);
			static if (is(C:MenuCard)) {
				_prop.var.etc.fixedImagesMenuCards = _fixedC;
			} else static if (is(C:EnemyCard)){
				_prop.var.etc.fixedImagesBattle = _fixedC;
			} else static assert (0);
		}
	}
	static if (UseBacks) {
		void reverseFixedCells() { mixin(S_TRACE);
			if (_readOnly) return;
			_fixedB = !_fixedB;
			checked();
			if (_vfbMenu) _vfbMenu.setSelection(_fixedB);
			if (_vfbTMenu) _vfbTMenu.setSelection(_fixedB);
			_prop.var.etc.fixedImagesCells = _fixedB;
		}
		void reverseFixedBackground() { mixin(S_TRACE);
			if (_readOnly) return;
			_fixedFirstB = !_fixedFirstB;
			checked();
			if (_vffbMenu) _vffbMenu.setSelection(_fixedFirstB);
			if (_vffbTMenu) _vffbTMenu.setSelection(_fixedFirstB);
			static if (is(A:Area)) {
				_prop.var.etc.fixedImagesBackground = _fixedFirstB;
			} else static if (is(A:BgImageContainer)) {
				auto fixed = false;
				if (_summ) { mixin(S_TRACE);
					_prop.var.etc.fixedImagesEventBackground = _fixedFirstB;
				} else { mixin(S_TRACE);
					_prop.var.etc.fixedImagesDefaultBackground = _fixedFirstB;
				}
			} else static assert (0);
		}
	}
	void reverseShowGrid() { mixin(S_TRACE);
		_showGrid = !_showGrid;
		refreshGrid();
		if (_sgMenu) _sgMenu.setSelection(_showGrid);
		if (_sgTMenu) _sgTMenu.setSelection(_showGrid);
		if (_sgPMenu) _sgPMenu.setSelection(_showGrid);
		_prop.var.etc.showGrid = _showGrid;
	}
	void refreshGrid() { mixin(S_TRACE);
		_imgp.gridX = _showGrid ? _gridX : 0;
		_imgp.gridY = _showGrid ? _gridY : 0;
	}
	private int insertIndex(Table list) { mixin(S_TRACE);
		int[] indices = list.getSelectionIndices();
		std.algorithm.sort(indices);
		return indices.length ? indices[$ - 1] + 1 : list.getItemCount();
	}
	static if (UseCards) {
		/// カードを追加する。
		/// Params:
		/// card = カード。
		/// select = 選択状態にするか。
		/// refresh = 表示を更新するか。
		private int appendCard(C card, bool select, bool refresh, bool fromImgPane) { mixin(S_TRACE);
			int index = fromImgPane ? cast(int)_area.cards.length : insertIndex(_cards);
			appendCard(index, card, select, refresh);
			return index;
		}
		/// ditto
		private void appendCard(int index, C card, bool select, bool refresh, bool check = true) { mixin(S_TRACE);
			appendCardImpl(views(), _comm, _summ, _area, index, card, select, refresh, check);
		}
		/// ditto
		private static void appendCardImpl(AbstractAreaView[] vs, Commons comm, Summary summ, A area, int index, C card, bool select, bool refresh, bool check = true, bool grayed = false) { mixin(S_TRACE);
			area.insert(index, card);
			foreach (v; vs) { mixin(S_TRACE);
				auto img = v.create(card);
				img.visible = v.isViewCards && check;
				img.fixed = v.isFixedCards || (img.visible && grayed);
				v._imgp.deselectAll();
				v._imgp.insert(v.cardsIndex + index, img);
				auto itm = new TableItem(v._cards, SWT.NONE, index);
				itm.setImage(v.cardImg(card));
				itm.setData(card);
				itm.setGrayed(grayed);
				itm.setChecked(check);
				itm.setText(v.cardNameWithGroup(card));
				if (select && v.isViewCards) { mixin(S_TRACE);
					v._imgp.select(img);
					if (refresh) { mixin(S_TRACE);
						v.refreshSelected();
					}
				}
			}
			if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
				comm.addMenuCard.call(card.cwxPath(true));
				if (refresh) comm.refUseCount.call();
			}
			if (refresh) { mixin(S_TRACE);
				foreach (v; vs) { mixin(S_TRACE);
					v.refreshFlags();
					v.checked();
					v.callModEvent();
				}
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
		private void appendCards(int index, C[] cards, bool select, bool raiseEvent, bool initialize) { mixin(S_TRACE);
			auto vs = initialize ? [this] : views();
			foreach (vi, v; vs) { mixin(S_TRACE);
				v._cards.setRedraw(false);
				scope (exit) v._cards.setRedraw(true);
				v._imgp.setRedraw(false);
				scope (exit) v._imgp.setRedraw(true);
				FlexImage[] imgs;
				foreach (i, card; cards) { mixin(S_TRACE);
					auto img = v.create(card);
					imgs ~= img;
					if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
						if (vi == 0 && raiseEvent) _comm.addMenuCard.call(card.cwxPath(true));
					}
				}
				v._imgp.insert(v.cardsIndex + index, cast(PileImage[])imgs);
				foreach (i, c; cards) { mixin(S_TRACE);
					auto itm = new TableItem(v._cards, SWT.NONE, index + cast(int)i);
					itm.setImage(v.cardImg(c));
					itm.setData(c);
					itm.setChecked(true);
					itm.setText(v.cardNameWithGroup(c));
				}
				if (select && v._viewCards) v._imgp.select(imgs);
				if (!initialize) v.callModEvent();
			}
		}
		static if (is(C == MenuCard)) {
			private int cardFromFile(string fname, int x, int y, bool fromImgPane) { mixin(S_TRACE);
				if (_readOnly) return -1;
				if (!_summ) return -1;
				if (hasPath(_summ.scenarioPath, fname)) { mixin(S_TRACE);
					fname = abs2rel(fname, _summ.scenarioPath);
				} else { mixin(S_TRACE);
					auto dlg = new MessageBox(getShell(), SWT.ICON_QUESTION | SWT.YES | SWT.NO | SWT.CANCEL);
					dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDropCard, fname));
					dlg.setText(_prop.msgs.dlgTitDropCard);
					auto ret = dlg.open();
					if (SWT.YES == ret) { mixin(S_TRACE);
						fname = copyTo(_summ.scenarioPath, fname, summSkin.materialPath, false);
					} else if (SWT.CANCEL == ret) { mixin(S_TRACE);
						return -1;
					}
				}
				auto card = new MenuCard(baseName(.stripExtension(fname)), false, fname.length ? [new CardImage(fname, CardImagePosition.Default)] : [], "", "", x, y, 100, LAYER_MENU_CARD, "", -1);
				return appendCard(card, true, true, fromImgPane);
			}
			private class CLDropTarget : DropTargetAdapter {
				override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
					e.detail = !_readOnly && _summ && _summ.scenarioPath != "" ? DND.DROP_LINK : DND.DROP_NONE;
				}
				private int[] addC;
				override void drop(DropTargetEvent e) { mixin(S_TRACE);
					if (!summ || summ.scenarioPath == "" || _readOnly) return;
					assert (_summ);
					scope (exit) addC = [];
					auto arr = cast(FileNames)e.data;
					if (arr) { mixin(S_TRACE);
						int[] selIndices;
						foreach (fname; arr.array) { mixin(S_TRACE);
							try { mixin(S_TRACE);
								if (!doFile(fname)) { mixin(S_TRACE);
									break;
								}
								selIndices ~= cardsIndex + _cards.getItemCount() - 1;
							} catch (SWTException e) {
								printStackTrace();
								debugln(e);
							}
						}
						if (addC.length) { mixin(S_TRACE);
							auto undo = new UndoInsert(this.outer, _comm, _area, _summ, addC, []);
							_comm.refPaths.call(summSkin.materialPath);
						}
						_imgp.select(selIndices);
						refreshSelected();
						_comm.refreshToolBar();
						return;
					} else if (isXMLBytes(e.data)) { mixin(S_TRACE);
						int[] ci, bi;
						auto ctrl = (cast(DropTarget)e.getSource()).getControl();
						auto p = ctrl.toControl(e.x, e.y);
						appendFromXML(bytesToXML(e.data), p.x, p.y, DropTarg.Card, ci, bi);
						if (ci.length || bi.length) { mixin(S_TRACE);
							_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, ci, bi);
						}
						_comm.refreshToolBar();
					}
				}
				private bool doFile(string path) { mixin(S_TRACE);
					if (_readOnly) return false;
					assert (_summ);
					if (summSkin.isCardImage(path, true, false)) { mixin(S_TRACE);
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
				e.doit = (cast(DragSource)e.getSource()).getControl().isFocusControl();
			}
			override void dragSetData(DragSourceEvent e){ mixin(S_TRACE);
				if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
					auto tbl = cast(Table)(cast(DragSource)e.getSource()).getControl();
					auto sel = tbl.getSelectionIndex();
					auto curItm = sel != -1 ? tbl.getItem(sel) : null;
					C[] cs;
					foreach (itm; tbl.getSelection()) { mixin(S_TRACE);
						cs ~= cast(C)itm.getData();
					}
					auto node = A.CtoNode(cs, new XMLOption(_prop.sys, LATEST_VERSION));
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
			int index = fromImgPane ? cast(int)_area.backs.length : insertIndex(_backs);
			appendBgImage(index, back, select, refresh);
			return index;
		}
		/// ditto
		private void appendBgImage(int index, BgImage back, bool select, bool refresh, bool check = true) { mixin(S_TRACE);
			appendBgImageImpl(views(), _comm, _summ, _area, index, back, select, refresh, check);
		}
		/// ditto
		private static void appendBgImageImpl(AbstractAreaView[] vs, Commons comm, Summary summ, A area, int index, BgImage back, bool select, bool refresh, bool check = true, bool grayed = false) { mixin(S_TRACE);
			area.insert(index, back);
			foreach (v; vs) { mixin(S_TRACE);
				v._imgp.deselectAll();
				auto img = v.create(back);
				img.visible = v.isViewBacks && check;
				img.fixed = v.isFixedCells || (img.visible && grayed);
				v._imgp.insert(index, img);
				auto itm = new TableItem(v._backs, SWT.NONE, index);
				itm.setImage(v.backImg(back));
				itm.setData(back);
				itm.setGrayed(grayed);
				itm.setChecked(check);
				itm.setText(back.name(comm.prop.parent));
				if (select && v.isViewBacks) { mixin(S_TRACE);
					v._imgp.select(img);
					if (refresh) { mixin(S_TRACE);
						v.refreshSelected();
					}
				}
			}
			if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
				comm.addBgImage.call(back.cwxPath(true));
				if (refresh) comm.refUseCount.call();
			}
			if (refresh) { mixin(S_TRACE);
				foreach (v; vs) { mixin(S_TRACE);
					v.refreshFlags();
					v.checked();
					v.callModEvent();
				}
			}
		}
		private FlexImage create(BgImage back) { mixin(S_TRACE);
			FlexImage img = null;
			auto ic = cast(ImageCell)back;
			if (ic) img = create(ic);
			auto tc = cast(TextCell)back;
			if (tc) img = create(tc);
			auto cc = cast(ColorCell)back;
			if (cc) img = create(cc);
			auto pc = cast(PCCell)back;
			if (pc) img = create(pc);
			assert (img !is null);
			_backTbl[img] = back;
			img.visible = _viewBacks;
			img.fixed = isFixedCells;
			img.layer = back.layer * 10;
			img.addSelectionListener(&selectImageB);
			img.addResizeListener(&resizeImageB);
			return img;
		}
		private FlexImage create(ImageCell back) { mixin(S_TRACE);
			auto skin = summSkin;
			auto path = skin.findImagePath(back.path, _summ ? _summ.scenarioPath : "", _summ ? _summ.dataVersion : LATEST_VERSION);
			return createBackgroundImage(_prop, skin, _summ, path, back.x, back.y, back.width, back.height, back.mask, back.layer, back.smoothing is Smoothing.True);
		}
		private FlexImage create(TextCell back) { mixin(S_TRACE);
			auto r = new FlexImage(back.text, _prop.drawingScale, _prop.adjustFont(back.fontName), back.size, back.color,
				back.bold, back.italic, back.underline, back.strike, back.vertical, back.antialias,
				back.borderingType, back.borderingColor, back.borderingWidth,
				back.x, back.y, back.width, back.height);
			r.transparent = back.mask;
			r.previewText = &previewText;
			r.layer = back.layer * 10;
			r.createImage();
			return r;
		}
		private FlexImage create(ColorCell back) { mixin(S_TRACE);
			auto r = new FlexImage(_prop.drawingScale, back.blendMode, back.gradientDir, back.color1, back.color2,
				back.x, back.y, back.width, back.height);
			r.transparent = back.mask;
			r.layer = back.layer * 10;
			return r;
		}
		private FlexImage create(PCCell back) { mixin(S_TRACE);
			auto skin = summSkin;
			auto size = _prop.ds(_prop.looks.cardSize);
			auto r = new FlexImage((img, gc) { mixin(S_TRACE);
				version (Windows) {
					import org.eclipse.swt.internal.win32.OS;
					if (OS.VERSION(6, 0) <= OS.WIN32_VERSION) { mixin(S_TRACE);
						gc.setAntialias(SWT.ON);
					}
				}
				auto d = _imgp.getDisplay();
				int alpha;
				auto back2 = new Color(d, .dwtData(_prop.looks.pcCellBackColor, alpha));
				scope (exit) back2.dispose();
				gc.setBackground(back2);
				version (Windows) {
					if (OS.VERSION(6, 0) <= OS.WIN32_VERSION) { mixin(S_TRACE);
						gc.setAlpha(alpha);
					}
				}
				auto width = size.width;
				auto height = size.height;
				if (back.expand) { mixin(S_TRACE);
					width = _prop.ds(img.width);
					height = _prop.ds(img.height);
				}
				gc.fillOval(_prop.ds(0), _prop.ds(0), width, height);
				auto fore2 = new Color(d, .dwtData(_prop.looks.pcCellForeColor, alpha));
				scope (exit) fore2.dispose();
				gc.setForeground(fore2);
				version (Windows) {
					if (OS.VERSION(6, 0) <= OS.WIN32_VERSION) { mixin(S_TRACE);
						gc.setAlpha(alpha);
					}
				}
				gc.drawOval(_prop.ds(0), _prop.ds(0), width - 1, height - 1);
				auto font = _prop.adjustFont(_prop.looks.pcNumberFont(skin.legacy));
				font.point /= .dpiMuls;
				drawCenterText(.dwtData(_prop.ds(font)), gc, new Rectangle(_prop.ds(0), _prop.ds(0), width - 1, height - 1), .text(back.pcNumber));
			}, _prop.drawingScale, back.x, back.y, size.width, size.height, false);
			r.transparent = false;
			r.layer = back.layer * 10;
			r.newWidth = back.width;
			r.newHeight = back.height;
			r.resize();
			return r;
		}
		private void appendBgImages(int index, BgImage[] backs, bool select, bool raiseEvent, bool initialize) { mixin(S_TRACE);
			auto vs = initialize ? [this] : views();
			foreach (vi, v; vs) { mixin(S_TRACE);
				v._backs.setRedraw(false);
				scope (exit) v._backs.setRedraw(true);
				v._imgp.setRedraw(false);
				scope (exit) v._imgp.setRedraw(true);
				FlexImage[] imgs;
				foreach (back; backs) { mixin(S_TRACE);
					imgs ~= v.create(back);
				}
				v._imgp.insert(index, cast(PileImage[])imgs);
				foreach (i, b; backs) { mixin(S_TRACE);
					auto itm = new TableItem(v._backs, SWT.NONE, index + cast(int)i);
					itm.setImage(v.backImg(b));
					itm.setData(b);
					itm.setChecked(true);
					itm.setText(b.name(_prop.parent));
					if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
						if (vi == 0 && raiseEvent) _comm.addBgImage.call(b.cwxPath(true));
					}
				}
				if (select && v._viewBacks) v._imgp.select(imgs);
				v.checked();
				if (!initialize) v.callModEvent();
			}
		}
		private int backFromFile(string fname, int x, int y, int w, int h, bool fromImgPane) { mixin(S_TRACE);
			if (_readOnly) return -1;
			if (!_summ) return -1;
			if (hasPath(_summ.scenarioPath, fname)) { mixin(S_TRACE);
				fname = abs2rel(fname, _summ.scenarioPath);
			} else { mixin(S_TRACE);
				auto dlg = new MessageBox(getShell(), SWT.ICON_QUESTION | SWT.YES | SWT.NO | SWT.CANCEL);
				dlg.setMessage(.tryFormat(_prop.msgs.dlgMsgDropBack, fname));
				dlg.setText(_prop.msgs.dlgTitDropBack);
				auto ret = dlg.open();
				if (SWT.YES == ret) { mixin(S_TRACE);
					fname = copyTo(_summ.scenarioPath, fname, summSkin.materialPath, false);
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
				e.detail = !_readOnly && _summ && _summ.scenarioPath != "" ? DND.DROP_LINK : DND.DROP_NONE;
			}
			override void drop(DropTargetEvent e) { mixin(S_TRACE);
				if (!_summ || _summ.scenarioPath == "" || _readOnly) return;
				assert (_summ);
				scope (exit) addB = [];
				auto arr = cast(FileNames)e.data;
				if (arr) { mixin(S_TRACE);
					int[] selIndices;
					foreach (fname; arr.array) { mixin(S_TRACE);
						try { mixin(S_TRACE);
							if (!doFile(fname)) { mixin(S_TRACE);
								break;
							}
							selIndices ~= 0 + _backs.getItemCount() - 1;
						} catch (SWTException e) {
							printStackTrace();
							debugln(e);
						}
					}
					if (addB.length) { mixin(S_TRACE);
						auto undo = new UndoInsert(this.outer, _comm, _area, _summ, [], addB);
						_comm.refPaths.call(summSkin.materialPath);
					}
					_imgp.select(selIndices);
					refreshSelected();
					_comm.refreshToolBar();
					return;
				} else if (isXMLBytes(e.data)) { mixin(S_TRACE);
					int[] ci, bi;
					auto ctrl = (cast(DropTarget)e.getSource()).getControl();
					auto p = ctrl.toControl(e.x, e.y);
					appendFromXML(bytesToXML(e.data), p.x, p.y, DropTarg.Back, ci, bi);
					if (ci.length || bi.length) { mixin(S_TRACE);
						_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, ci, bi);
					}
					_comm.refreshToolBar();
				}
			}
			private bool doFile(string path) { mixin(S_TRACE);
				if (_readOnly) return false;
				assert (_summ);
				auto img = loadBgImage(_prop, summSkin, _summ, path, _prop.drawingScaleForImage(_summ));
				if (img) { mixin(S_TRACE);
					int i = backFromFile(path, 0, 0, img.getWidth(NORMAL_SCALE), img.getHeight(NORMAL_SCALE), false);
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
				e.doit = (cast(DragSource)e.getSource()).getControl().isFocusControl();
			}
			override void dragSetData(DragSourceEvent e){ mixin(S_TRACE);
				if (XMLBytesTransfer.getInstance().isSupportedType(e.dataType)) { mixin(S_TRACE);
					auto tbl = cast(Table)(cast(DragSource)e.getSource()).getControl();
					auto sel = tbl.getSelectionIndex();
					auto curItm = sel != -1 ? tbl.getItem(sel) : null;
					BgImage[] bs;
					foreach (itm; tbl.getSelection()) { mixin(S_TRACE);
						bs ~= cast(BgImage)itm.getData();
					}
					auto node = Area.BtoNode(bs, new XMLOption(_prop.sys, LATEST_VERSION));
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
		if (_readOnly) return;
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
		if (_readOnly) return;
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
					if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
						_comm.refUseCount.call();
						refreshFlags();
					}
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
							appendCard(si + cast(int)i, card, true, true);
							ci ~= si + cast(int)i;
						}
						if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
							_comm.refUseCount.call();
							refreshFlags();
						}
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
							appendBgImage(si + cast(int)i, back, true, true);
							bi ~= si + cast(int)i;
						}
						if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
							_comm.refUseCount.call();
							refreshFlags();
						}
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
						if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
							_comm.refUseCount.call();
							refreshFlags();
						}
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
							appendCard(si + cast(int)i, card, true, true);
							ci ~= si + cast(int)i;
						}
						if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
							_comm.refUseCount.call();
							refreshFlags();
						}
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
						int[] selIndices;
						foreach (i, card; cards) { mixin(S_TRACE);
							assert (card.scale == 100);
							card.x = cx;
							card.y = cy;
							selIndices ~= cardsIndex + _cards.getItemCount();
							ci ~= appendCard(card, true, true, toImgp);
						}
						_imgp.select(selIndices);
						refreshSelected();
						if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
							_comm.refUseCount.call();
							refreshFlags();
						}
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
				int[] selIndices;
				foreach (card; cards) { mixin(S_TRACE);
					assert (card.scale == 100);
					card.x = cx;
					card.y = cy;
					selIndices ~= cardsIndex + _cards.getItemCount();
					ci ~= appendCard(card, true, true, toImgp);
				}
				_imgp.select(selIndices);
				refreshSelected();
				_comm.refreshToolBar();
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
	private class IPDropTarget : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
			e.detail = !_readOnly && _summ && _summ.scenarioPath != "" ? DND.DROP_LINK : DND.DROP_NONE;
		}
		private int[] addC;
		private int[] addB;
		override void drop(DropTargetEvent e) { mixin(S_TRACE);
			if (!summ || summ.scenarioPath == "" || _readOnly) return;
			assert (_summ);
			scope (exit) addC = [];
			scope (exit) addB = [];
			auto arr = cast(FileNames)e.data;
			if (arr) { mixin(S_TRACE);
				int append = 0;
				foreach (fname; arr.array) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						scope p = _imgp.toControl(e.x, e.y);
						if (!doFile(fname, p.x / _prop.var.etc.imageScale, p.y / _prop.var.etc.imageScale)) { mixin(S_TRACE);
							break;
						}
						append++;
					} catch (SWTException e) {
						printStackTrace();
						debugln(e);
					}
				}
				if (append > 0) { mixin(S_TRACE);
					_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, addC, addB);
					_comm.refPaths.call(summSkin.materialPath);

					int[] selIndices;
					static if (UseCards) {
						foreach (i; addC) { mixin(S_TRACE);
							selIndices ~= cardsIndex + i;
						}
					}
					static if (UseBacks) {
						foreach (i; addB) { mixin(S_TRACE);
							selIndices ~= 0 + i;
						}
					}
					_imgp.select(selIndices);
					refreshSelected();
					_comm.refreshToolBar();
				}
				return;
			}
			if (isXMLBytes(e.data)) { mixin(S_TRACE);
				scope p = _imgp.toControl(e.x, e.y);
				int[] ci, bi;
				appendFromXML(bytesToXML(e.data), p.x / _prop.var.etc.imageScale, p.y / _prop.var.etc.imageScale, DropTarg.ImagePane, ci, bi);
				if (ci.length || bi.length) { mixin(S_TRACE);
					_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, ci, bi);
					_comm.refreshToolBar();
				}
			}
		}
		private bool doFile(string path, int x, int y) { mixin(S_TRACE);
			if (_readOnly) return false;
			assert (_summ);
			auto skin = summSkin;
			static if ((UseCards && is(C == MenuCard)) && UseBacks) {
				if (skin.isCardImage(path, false, false)) { mixin(S_TRACE);
					int i = cardFromFile(path, x, y, true);
					if (i == -1) { mixin(S_TRACE);
						return false;
					} else { mixin(S_TRACE);
						addC ~= i;
					}
				} else { mixin(S_TRACE);
					auto img = loadBgImage(_prop, skin, _summ, path, _prop.drawingScaleForImage(_summ));
					if (img) { mixin(S_TRACE);
						int i = backFromFile(path, x, y, img.getWidth(NORMAL_SCALE), img.getHeight(NORMAL_SCALE), true);
						if (i == -1) { mixin(S_TRACE);
							return false;
						} else { mixin(S_TRACE);
							addB ~= i;
						}
					}
				}
			} else static if (UseCards && is(C == MenuCard)) {
				if (skin.isCardImage(path, true, false)) { mixin(S_TRACE);
					int i = cardFromFile(path, x, y, true);
					if (i == -1) { mixin(S_TRACE);
						return false;
					} else { mixin(S_TRACE);
						addC ~= i;
					}
				}
			} else static if (UseBacks) {
				auto img = loadBgImage(_prop, skin, _summ, path, _prop.drawingScaleForImage(_summ));
				if (img) { mixin(S_TRACE);
					int i = backFromFile(path, x, y, img.getWidth(NORMAL_SCALE), img.getHeight(NORMAL_SCALE), true);
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

	static if (is(C == EnemyCard)) {
		private void refreshCast(CastCard castCard) { mixin(S_TRACE);
			if (!_summ || _summ.scenarioPath == "" || _readOnly) return;
			auto skin = summSkin;
			foreach (i, c; area.cards) { mixin(S_TRACE);
				if (castCard.id == _area.cards[i].id) { mixin(S_TRACE);
					auto img = imagePane.images[cardsIndex + i];
					auto name = img.title;
					img.setImageData(.castCardImage(_prop, skin, _summ, castCard, _dbgMode));
					img.createImage();
					imagePane.redrawImage(img);
					if (name != castCard.name) { mixin(S_TRACE);
						cardList.getItem(cast(int)i).setText(c.cardGroup == "" ? castCard.name : .tryFormat(_prop.msgs.nameWithCardGroup, c.cardGroup, castCard.name));
						_comm.refMenuCard.call(_area.cards[i].cwxPath(true));
					}
				}
			}
		}
		private void deleteCast(CastCard castCard) { mixin(S_TRACE);
			if (_readOnly) return;
			auto skin = summSkin;
			foreach (i, c; area.cards) { mixin(S_TRACE);
				if (castCard.id == c.id) { mixin(S_TRACE);
					auto img = imagePane.images[cardsIndex + i];
					img.setImageData(.castCard(skin, prop.drawingScale));
					img.createImage();
					imagePane.redrawImage(img);
					cardList.getItem(cast(int)i).setText("");
				}
			}
		}
	} else static if (RefCards) {
		private void refreshCast(CastCard castCard) { mixin(S_TRACE);
			refreshPanel();
		}
		private void deleteCast(CastCard castCard) { mixin(S_TRACE);
			refreshPanel();
		}
	}
	static if (is(A : Battle) && is(C : EnemyCard)) {
		class DTListener : DropTargetAdapter {
			override void dragEnter(DropTargetEvent e){ mixin(S_TRACE);
				e.detail = !_readOnly ? DND.DROP_LINK : DND.DROP_NONE;
			}
			override void drop(DropTargetEvent e) { mixin(S_TRACE);
				if (_readOnly) return;
				if (isXMLBytes(e.data)) { mixin(S_TRACE);
					auto arr = bytesToXML(e.data);
					auto ctrl = (cast(DropTarget)e.getSource()).getControl();
					auto p = ctrl.toControl(e.x, e.y);
					auto imgp = cast(ImagePane)ctrl;
					int[] ci, bi;
					appendFromXML(arr, p.x / _prop.var.etc.imageScale, p.y / _prop.var.etc.imageScale, imgp ? DropTarg.ImagePane : DropTarg.Card, ci, bi);
					if (ci.length || bi.length) { mixin(S_TRACE);
						_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, ci, bi);
						_comm.refreshToolBar();
					}
				}
			}
		}
	}
	void cut(SelectionEvent se) { mixin(S_TRACE);
		if (_readOnly) return;
		_tcpd.cut(se);
	}
	void copy(SelectionEvent se) { mixin(S_TRACE);
		_tcpd.copy(se);
	}
	void paste(SelectionEvent se) { mixin(S_TRACE);
		if (_readOnly) return;
		_tcpd.paste(se);
	}
	void del(SelectionEvent se) { mixin(S_TRACE);
		if (_readOnly) return;
		delImpl();
	}
	private void delImpl() { mixin(S_TRACE);
		if (_readOnly) return;
		_tcpd.del(null);
	}
	void clone(SelectionEvent se) { mixin(S_TRACE);
		if (_readOnly) return;
		_tcpd.clone(se);
	}
	private static void delImpl2(AbstractAreaView[] vs, Commons comm, Summary summ, A area, int[] cIdcs, int[] bIdcs, bool store) { mixin(S_TRACE);
		if (store && vs.length) { mixin(S_TRACE);
			vs[0]._undo ~= new UndoDelete(vs[0], comm, area, summ, cIdcs, bIdcs);
		}
		foreach (v; vs) { mixin(S_TRACE);
			static if (UseCards) v._cards.setRedraw(false);
			static if (UseBacks) v._backs.setRedraw(false);
			v._imgp.setRedraw(false);
		}
		scope (exit) {
			foreach (v; vs) {
				static if (UseCards) v._cards.setRedraw(true);
				static if (UseBacks) v._backs.setRedraw(true);
				v._imgp.setRedraw(true);
			}
		}
		static if (UseCards) {
			foreach_reverse (i; std.algorithm.sort(cIdcs)) { mixin(S_TRACE);
				foreach (v; vs) { mixin(S_TRACE);
					removeCard(v, comm, summ, area, v._cardTbl, i, false);
				}
				area.removeCard(i);
				foreach (v; vs) v._cards.remove(i);
			}
		}
		static if (UseBacks) {
			foreach_reverse (i; std.algorithm.sort(bIdcs)) { mixin(S_TRACE);
				foreach (v; vs) { mixin(S_TRACE);
					removeBack(v, comm, summ, area, v._backTbl, i, false);
				}
				area.removeBgImage(i);
				foreach (v; vs) v._backs.remove(i);
			}
		}
		foreach (v; vs) { mixin(S_TRACE);
			v.refreshSelected();
			v.refreshFlags();
			v.checked();
			v.callModEvent();
		}
		if (summ && summ.scenarioPath != "") { mixin(S_TRACE);
			if (cIdcs.length) comm.refCardGroups.call();
			if (bIdcs.length) comm.refCellNames.call();
			comm.refUseCount.call();
		}
		comm.refreshToolBar();
	}
	@property
	bool canDoTCPD() { mixin(S_TRACE);
		return _imgp.isVisible();
	}
	@property
	bool canDoT() { mixin(S_TRACE);
		return !_readOnly && _imgp.selectedIndex != -1;
	}
	@property
	bool canDoC() { mixin(S_TRACE);
		return _imgp.selectedIndex != -1;
	}
	@property
	bool canDoP() { mixin(S_TRACE);
		return !_readOnly && CBisXML(_comm.clipboard);
	}
	@property
	bool canDoD() { mixin(S_TRACE);
		return !_readOnly && _imgp.selectedIndex != -1;
	}
	@property
	bool canDoClone() { mixin(S_TRACE);
		return !_readOnly && canDoC;
	}
	static if (UseCards && UseBacks) {
		private class AllTCPD : TCPD {
			void cut(SelectionEvent se) { mixin(S_TRACE);
				if (_readOnly) return;
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
					XMLtoCB(_prop, _comm.clipboard, Area.CBtoXML(cards, backs, new XMLOption(_prop.sys, LATEST_VERSION)));
					_comm.refreshToolBar();
				}
			}
			void paste(SelectionEvent se) { mixin(S_TRACE);
				if (_readOnly) return;
				auto xml = CBtoXML(_comm.clipboard);
				if (xml) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						C[] cs;
						BgImage[] bs;
						auto ver = new XMLInfo(_prop.sys, LATEST_VERSION);
						A.CBfromXML(xml, cs, bs, ver);
						if (cs.length || bs.length) { mixin(S_TRACE);
							auto vs = views();
							foreach (vi, v; vs) { mixin(S_TRACE);
								v._imgp.setRedraw(false);
							}
							scope (exit) {
								foreach (vi, v; vs) {
									v._imgp.setRedraw(true);
								}
							}
							_imgp.deselectAll();
							int[] addC, addB;
							auto iib = insertIndex(_backs);
							foreach (i, b; bs) { mixin(S_TRACE);
								int index = iib + cast(int)i;
								addB ~= index;
								_area.insert(index, b);
							}
							appendBgImages(iib, bs, true, true, false);
							auto iic = insertIndex(_cards);
							foreach (i, c; cs) { mixin(S_TRACE);
								int index = iic + cast(int)i;
								addC ~= index;
								_area.insert(index, c);
							}
							appendCards(iic, cs, true, true, false);
							refreshSelected();
							if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
								_comm.refUseCount.call();
								refreshFlags();
							}
							_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, addC, addB);
							if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
								if (cs.length) _comm.refCardGroups.call();
								if (bs.length) _comm.refCellNames.call();
							}
							_comm.refreshToolBar();
						}
					} catch (Exception e) {
						printStackTrace();
						debugln(e);
					}
				}
			}
			void del(SelectionEvent se) { mixin(S_TRACE);
				if (_readOnly) return;
				delImpl2(views(), _comm, _summ, _area, _cards.getSelectionIndices(), _backs.getSelectionIndices(), true);
				_comm.refreshToolBar();
			}
			void clone(SelectionEvent se) { mixin(S_TRACE);
				if (_readOnly) return;
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
				return !_readOnly && _imgp.selectedIndex != -1;
			}
			@property
			bool canDoC() { mixin(S_TRACE);
				return _imgp.selectedIndex != -1;
			}
			@property
			bool canDoP() { mixin(S_TRACE);
				return !_readOnly && CBisXML(_comm.clipboard);
			}
			@property
			bool canDoD() { mixin(S_TRACE);
				return !_readOnly && _imgp.selectedIndex != -1;
			}
			@property
			bool canDoClone() { mixin(S_TRACE);
				return !_readOnly && canDoC;
			}
		}
	}

	static if (UseCards) {
		private class CardTCPD : TCPD {
			void cut(SelectionEvent se) { mixin(S_TRACE);
				if (_readOnly) return;
				copy(se);
				del(se);
			}
			void copy(SelectionEvent se) { mixin(S_TRACE);
				scope C[] cards;
				foreach (i; _cards.getSelectionIndices()) { mixin(S_TRACE);
					cards ~= _area.cards[i];
				}
				if (cards.length > 0) { mixin(S_TRACE);
					XMLtoCB(_prop, _comm.clipboard, A.CtoXML(cards, new XMLOption(_prop.sys, LATEST_VERSION)));
					_comm.refreshToolBar();
				}
			}
			void paste(SelectionEvent se) { mixin(S_TRACE);
				if (_readOnly) return;
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
									int index = insertIndex(_cards) + cast(int)i;
									addC ~= index;
									_area.insert(index, c);
								}
								appendCards(insertIndex(_cards), cs, true, true, false);
								refreshSelected();
								if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
									_comm.refUseCount.call();
									refreshFlags();
								}
								_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, addC, []);
								if (_summ && _summ.scenarioPath != "")_comm.refCardGroups.call();
								_comm.refreshToolBar();
							}
						} catch (Exception e) {
							printStackTrace();
							debugln(e);
						}
					}
				}
			}
			void del(SelectionEvent se) { mixin(S_TRACE);
				if (_readOnly) return;
				delImpl2(views(), _comm, _summ, _area, _cards.getSelectionIndices(), [], true);
				_comm.refreshToolBar();
			}
			void clone(SelectionEvent se) { mixin(S_TRACE);
				if (_readOnly) return;
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
				return !_readOnly && _cards.getSelectionIndex() != -1;
			}
			@property
			bool canDoC() { mixin(S_TRACE);
				return _cards.getSelectionIndex() != -1;
			}
			@property
			bool canDoP() { mixin(S_TRACE);
				return !_readOnly && CBisXML(_comm.clipboard);
			}
			@property
			bool canDoD() { mixin(S_TRACE);
				return !_readOnly && _cards.getSelectionIndex() != -1;
			}
			@property
			bool canDoClone() { mixin(S_TRACE);
				return !_readOnly && canDoC;
			}
		}
	}
	static if (UseBacks) {
		private class BgImageTCPD : TCPD {
			void cut(SelectionEvent se) { mixin(S_TRACE);
				if (_readOnly) return;
				copy(se);
				del(se);
			}
			void copy(SelectionEvent se) { mixin(S_TRACE);
				scope BgImage[] backs;
				foreach (i; _backs.getSelectionIndices()) { mixin(S_TRACE);
					backs ~= _area.backs[i];
				}
				if (backs.length > 0) { mixin(S_TRACE);
					XMLtoCB(_prop, _comm.clipboard, A.BtoXML(backs, new XMLOption(_prop.sys, LATEST_VERSION)));
					_comm.refreshToolBar();
				}
			}
			void paste(SelectionEvent se) { mixin(S_TRACE);
				if (_readOnly) return;
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
									int index = insertIndex(_backs) + cast(int)i;
									addB ~= index;
									_area.insert(index, b);
								}
								appendBgImages(insertIndex(_backs), bs, true, true, false);
								refreshSelected();
								if (_summ && _summ.scenarioPath != "") { mixin(S_TRACE);
									_comm.refUseCount.call();
									refreshFlags();
								}
								_undo ~= new UndoInsert(this.outer, _comm, _area, _summ, [], addB);
								if (_summ && _summ.scenarioPath != "")_comm.refCellNames.call();
								_comm.refreshToolBar();
							}
						} catch (Exception e) {
							printStackTrace();
							debugln(e);
						}
					}
				}
			}
			void del(SelectionEvent se) { mixin(S_TRACE);
				if (_readOnly) return;
				delImpl2(views(), _comm, _summ, _area, [], _backs.getSelectionIndices(), true);
				_comm.refreshToolBar();
			}
			void clone(SelectionEvent se) { mixin(S_TRACE);
				if (_readOnly) return;
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
				return !_readOnly && _backs.getSelectionIndex() != -1;
			}
			@property
			bool canDoC() { mixin(S_TRACE);
				return _backs.getSelectionIndex() != -1;
			}
			@property
			bool canDoP() { mixin(S_TRACE);
				return !_readOnly && CBisXML(_comm.clipboard);
			}
			@property
			bool canDoD() { mixin(S_TRACE);
				return !_readOnly && _backs.getSelectionIndex() != -1;
			}
			@property
			bool canDoClone() { mixin(S_TRACE);
				return !_readOnly && canDoC;
			}
		}
	}
	void undo() { mixin(S_TRACE);
		if (_readOnly) return;
		_undo.undo();
	}
	void redo() { mixin(S_TRACE);
		if (_readOnly) return;
		_undo.redo();
	}

	@property
	bool canWriteComment() { mixin(S_TRACE);
		static if (UseCards) {
			if (_cards.isFocusControl()) return canWriteCommentC;
		}
		static if (UseBacks) {
			if (_backs.isFocusControl()) return canWriteCommentB;
		}
		return true;
	}
	void writeComment() { mixin(S_TRACE);
		if (!canWriteComment) return;
		static if (UseCards) {
			if (_cards.isFocusControl()) writeCommentC();
		}
		static if (UseBacks) {
			if (_backs.isFocusControl()) writeCommentB();
		}
	}

	private bool _openCWXPathFocus = false;
	private bool _openCWXPathShellActivate = false;
	private int[][Table] _openCWXPathIndices;
	static if (UseCards) bool _listSelectC = false;
	static if (UseBacks) bool _listSelectB = false;
	private void openCWXPathImpl() { mixin(S_TRACE);
		if (!_openCWXPathIndices.length) return;

		if (_openCWXPathFocus) .forceFocus(_imgp, _openCWXPathShellActivate);
		foreach (list, indices; _openCWXPathIndices) { mixin(S_TRACE);
			list.select(indices);
			list.showSelection();
		}
		_comm.refreshToolBar();
		static if (UseCards) if (_listSelectC) listSelectC();
		static if (UseBacks) if (_listSelectB) listSelectB();

		_openCWXPathFocus = false;
		_openCWXPathShellActivate = false;
		_openCWXPathIndices = null;
		static if (UseCards) _listSelectC = false;
		static if (UseBacks) _listSelectB = false;
	}

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
			if (!cphasattr(path, "nofocus")) { mixin(S_TRACE);
				_openCWXPathFocus = true;
				_openCWXPathShellActivate |= shellActivate;
			}
			if (list in _openCWXPathIndices) { mixin(S_TRACE);
				_openCWXPathIndices[list] ~= cast(int)index;
			} else {
				_openCWXPathIndices[list] = [cast(int)index];
			}
			.forceFocus(list, shellActivate);
			return true;
		}
		static if (UseCards && is(C : MenuCard)) {
			if (cate == "menucard") { mixin(S_TRACE);
				if (cphasattr(path, "only")) _cards.deselectAll();
				if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
					if (index >= _cards.getItemCount()) return false;
					editCard([cast(int)index]);
					return true;
				} else { mixin(S_TRACE);
					if (sel(_cards)) { mixin(S_TRACE);
						_listSelectC = true;
						return true;
					}
				}
			}
		}
		static if (UseCards && is(C : EnemyCard)) {
			if (cate == "enemycard") { mixin(S_TRACE);
				if (cphasattr(path, "only")) _cards.deselectAll();
				if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
					if (index >= _cards.getItemCount()) return false;
					editCard([cast(int)index]);
					return true;
				} else { mixin(S_TRACE);
					if (sel(_cards)) { mixin(S_TRACE);
						_listSelectC = true;
						return true;
					}
				}
			}
		}
		static if (UseBacks) {
			if (cate == "background") { mixin(S_TRACE);
				if (cphasattr(path, "only")) _backs.deselectAll();
				if (cphasattr(path, "opendialog")) { mixin(S_TRACE);
					if (index >= _backs.getItemCount()) return false;
					editBack([cast(int)index]);
					return true;
				} else { mixin(S_TRACE);
					if (sel(_backs)) { mixin(S_TRACE);
						_listSelectB = true;
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
	this(Commons comm, Props prop, Summary summ, Skin skin, UseCounter uc, BgImageContainer bic, Composite parent, AbstractArea refTarget, bool showInheritBacks, UndoManager undo, bool readOnly) { mixin(S_TRACE);
		if (prop.var.etc.refCardsAtEditBgImage) { mixin(S_TRACE);
			_refTarget = refTarget;
		}
		super (comm, prop, summ, skin, uc, bic, parent, null, showInheritBacks, undo, readOnly);
	}
}
