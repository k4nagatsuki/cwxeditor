
module cwx.editor.gui.dwt.areaview;

import cwx.utils;
import cwx.area;
import cwx.card;
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

import cwx.editor.gui.dwt.utils;
import cwx.editor.gui.dwt.props;
import cwx.editor.gui.dwt.images;
import cwx.editor.gui.dwt.skin;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.spcarddialog;
import cwx.editor.gui.dwt.bgimagedialog;
import cwx.editor.gui.dwt.materialselect;
import cwx.editor.gui.dwt.xmlbytestransfer;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.jpyimage;

import std.math;
import std.path;
import std.file;

import org.eclipse.swt.SWTException;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.List;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Spinner;
import org.eclipse.swt.custom.SashForm;
import org.eclipse.swt.custom.CLabel;
import org.eclipse.swt.custom.CCombo;
import org.eclipse.swt.custom.ScrolledComposite;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.RGB;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.FillLayout;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.MouseAdapter;
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

private void createToolItemC(ToolBar bar, Control c) {
	auto ti = new ToolItem(bar, SWT.SEPARATOR);
	ti.setControl(c);
	ti.setWidth(c.computeSize(SWT.DEFAULT, SWT.DEFAULT).x);
}

class AbstractAreaView(A, C, bool UseCards, bool UseBacks) : Composite, TCPD {
private:
	Commons _comm;
	Props _prop;
	A _area;
	TCPD _tcpd;
	UndoManager _undo;

	class AUndo : Undo {
		this () {}
		abstract override void undo();
		abstract override void redo();
		abstract override void dispose();
		protected void udb() {
			auto ct = Display.getCurrent.getFocusControl;
			while (ct.getParent) {
				if (ct is this) {
					return;
				}
				ct = ct.getParent;
			}
			.forceFocus(_imgp);
		}
		protected void uda() {
			static if (UseCards) if (!_viewCards) _cards.deselectAll;
			static if (UseBacks) if (!_viewBacks) _backs.deselectAll;
		}
	}
	static if (UseCards) {
		class UndoSPAuto : AUndo {
			private bool _spAuto;
			this () {
				_spAuto = _area.spAuto;
			}
			private void impl() {
				udb;
				scope (exit) uda;
				auto spAuto = _area.spAuto;
				_area.spAuto = _spAuto;
				_spAuto = spAuto;
				if (_autoMenu) _autoMenu.setSelection = _area.spAuto;
				if (_autoTMenu) _autoTMenu.setSelection = _area.spAuto;
				if (_customMenu) _customMenu.setSelection = !_area.spAuto;
				if (_customTMenu) _customTMenu.setSelection = !_area.spAuto;
			}
			override void undo() {impl;}
			override void redo() {impl;}
			override void dispose() {}
		}
	}
	static if (is(A == Battle)) {
		class UndoMusic : AUndo {
			private PathUser _path;
			this () {
				_path = new PathUser(new class CWXPath {
					override string cwxPath() {return "";}
					override CWXPath findCWXPath(string path) {return null;}
					override CWXPath[] cwxChilds() {return [];}
				});
				if (_summ) _path.setUseCounter(_summ.useCounter.sub);
				_path.path = _area.music;
			}
			private void impl() {
				udb;
				scope (exit) uda;
				auto path = _path.path;
				_path.path = _area.music;
				_area.music = path;
				_bgm.path = path;
			}
			override void undo() {impl;}
			override void redo() {impl;}
			override void dispose() {
				_path.removeUseCounter;
			}
		}
	}
	template Reselect() {
		static if (UseCards && UseBacks) {
			private int[] _cIdcs;
			private int[] _bIdcs;
			this () {
				this (_cards.getSelectionIndices, _backs.getSelectionIndices);
			}
			this (int[] cIdcs, int[] bIdcs) {
				_cIdcs = cIdcs;
				_bIdcs = bIdcs;
			}
		} else {
			private int[] _idcs;
			this () {
				static if (UseCards) {
					this (_cards.getSelectionIndices);
				} else static if (UseBacks) {
					this (_backs.getSelectionIndices);
				} else static assert (0);
			}
			this (int[] indices) {
				_idcs = indices;
			}
		}
		private void reselect() {
			static if (UseCards && UseBacks) {
				_cards.select(_cIdcs);
				_backs.select(_bIdcs);
			} else static if (UseCards) {
				_cards.select(_idcs);
			} else static if (UseBacks) {
				_backs.select(_idcs);
			} else static assert (0);
		}
		private void add(int i) {
			static if (UseCards && UseBacks) {
				_cIdcs[] += i;
				_bIdcs[] += i;
			} else {
				_idcs[] += i;
			}
		}
	}
	class UndoUD(int I) : AUndo {
		mixin Reselect;
		override void undo() {
			udb;
			scope (exit) uda;
			add(I);
			reselect;
			add(-I);
			static if (I < 0) {
				downImpl;
			} else {
				upImpl;
			}
		}
		override void redo() {
			udb;
			scope (exit) uda;
			reselect;
			static if (I < 0) {
				upImpl;
			} else {
				downImpl;
			}
		}
		override void dispose() {}
	}
	alias UndoUD!(-1) UndoUp;
	alias UndoUD!(1) UndoDown;
	class UndoInsert : AUndo {
		mixin Reselect;
		private UndoDelete _delUndo = null;
		override void undo() {
			udb;
			scope (exit) uda;
			reselect;
			_delUndo = new UndoDelete;
			delImpl;
		}
		override void redo() {
			_delUndo.undo;
			_delUndo = null;
		}
		override void dispose() {
			if (_delUndo) _delUndo.dispose;
		}
	}
	class UndoDelete : AUndo {
		static if (UseCards) C[int] _cs;
		static if (UseBacks) BgImage[int] _bs;
		this () {
			static if (UseCards) {
				foreach (i; _cards.getSelectionIndices) {
					auto c = C.createFromNode(_area.cards[i].toNode, LATEST_VERSION);
					if (_summ) c.setUseCounter(_summ.useCounter.sub);
					_cs[i] = c;
				}
			}
			static if (UseBacks) {
				foreach (i; _backs.getSelectionIndices) {
					auto b = _area.backs[i].dup;
					if (_summ) b.setUseCounter(_summ.useCounter.sub);
					_bs[i] = b;
				}
			}
		}
		override void undo() {
			udb;
			scope (exit) uda;
			static if (UseCards) {
				foreach (i; _cs.keys.sort) {
					appendCard(i, _cs[i], true, false);
				}
			}
			static if (UseBacks) {
				foreach (i; _bs.keys.sort) {
					appendBgImage(i, _bs[i], true, false);
				}
			}
			refreshSelected;
		}
		override void redo() {
			udb;
			scope (exit) uda;
			static if (UseCards) _cards.select(_cs.keys);
			static if (UseBacks) _backs.select(_bs.keys);
			delImpl;
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
	class UndoEdit : AUndo {
		static if (UseCards) C[int] _cs;
		static if (UseBacks) BgImage[int] _bs;
		this () {
			static if (UseCards) _cs = saveC(_cards.getSelectionIndices);
			static if (UseBacks) _bs = saveB(_backs.getSelectionIndices);
		}
		static if (UseCards) {
			private C[int] saveC(int[] indices) {
				C[int] cs;
				foreach (i; indices) {
					auto c = _area.cards[i];
					static if (is(C == MenuCard)) {
						c = new C(c.name, c.path, c.desc, c.flag, c.x, c.y, c.scale);
					} else static if (is(C == EnemyCard)) {
						c = new C(c.id, c.escape, c.flag, c.x, c.y, c.scale);
					} else static assert (0);
					if (_summ) c.setUseCounter(_summ.useCounter.sub);
					cs[i] = c;
				}
				return cs;
			}
		}
		static if (UseBacks) {
			private BgImage[int] saveB(int[] indices) {
				BgImage[int] bs;
				foreach (i; indices) {
					auto b = _area.backs[i];
					b = b.dup;
					if (_summ) b.setUseCounter(_summ.useCounter.sub);
					bs[i] = b;
				}
				return bs;
			}
		}
		private void impl() {
			udb;
			scope (exit) uda;
			static if (UseCards) {
				auto cs = saveC(_cs.keys);
				foreach (i, c; _cs) {
					c.removeUseCounter;
					auto ac = _area.cards[i];
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
				}
				_cs = cs;
			}
			static if (UseBacks) {
				auto bs = saveB(_bs.keys);
				foreach (i, b; _bs) {
					b.removeUseCounter;
					auto ab = _area.backs[i];
					ab.path = b.path;
					ab.flag = b.flag;
					ab.x = b.x;
					ab.y = b.y;
					ab.width = b.width;
					ab.height = b.height;
					ab.mask = b.mask;
				}
				_bs = bs;
			}
			refreshPanel;
			_comm.refUseCount.call;
		}
		override void undo() {
			impl;
		}
		override void redo() {
			impl;
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
	static if (is (C == EnemyCard)) {
		protected bool debugMode() {return _dbgMode;}
		bool _dbgMode = false;
		MenuItem _dbgMenu;
		ToolItem _dbgTMenu;
		ToolItem _escTMenu;
		ToolItem _bgmTMenu;
		MaterialSelect!(MtType.BGM, CCombo, CCombo) _bgm;
		void reverseDebugMode() {
			_dbgMode = !_dbgMode;
			if (_dbgMenu) _dbgMenu.setSelection = _dbgMode;
			if (_dbgTMenu) _dbgTMenu.setSelection = _dbgMode;
			refreshPanel;
		}
		void setEscape() {
			_undo ~= new UndoEdit;
			foreach (c; _editC.keys) {
				c.escape = _escTMenu.getSelection;
			}
		}
		void selectBGM() {
			_undo ~= new UndoMusic;
			_area.music = _bgm.path;
			_comm.refUseCount.call;
		}
		void __playBGM() {
			if (_bgmTMenu.getSelection) {
				string path = _bgm.filePath;
				if (path.length > 0) {
					_bgmTMenu.setToolTipText = _prop.msgs.stopBGM(path);
					_bgmTMenu.setImage = _prop.images.stopBGM;
					playBGMCW(_prop, path, _summ.legacy);
				} else {
					_bgmTMenu.setSelection = false;
				}
			} else {
				_bgmTMenu.setToolTipText = _prop.msgs.playBGM;
				_bgmTMenu.setImage = _prop.images.playBGM;
				stopBGM;
			}
		}
	}

	static if (UseCards && UseBacks) {
		SplitPane _sash;
	}

	ImagePane imagePane() {return _imgp;}
	Spinner _xSpn, _ySpn;
	static if (UseCards) {
		bool _viewCards = true;
		C[PileImage] _cardTbl;
		int[C] _editC;
		List _cards;
		MenuItem _vcMenu;
		ToolItem _vcTMenu;
		MenuItem _autoMenu;
		ToolItem _autoTMenu;
		MenuItem _customMenu;
		ToolItem _customTMenu;
		Spinner _scaleSpn;

		void delegate(int) _removeCard;
		void delegate(int) _renameCard;
		void delegate(int, C) _appendCard;
		void delegate(int[]) _upCard;
		void delegate(int[]) _downCard;

		List cardList() {return _cards;}
		void editSpnCard(string T)(int value) {
			__editSpn!(T, C)(value, _editC, cardsIndex);
			_imgp.redraw;
		}
		void enterSpnCard(string T, string N)(int value) {
			_undo ~= new UndoEdit;
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
		}
		void selectImageC(FlexImage img) {
			__selectImage!(C)(img, _area.cards, _cardTbl, _editC, _cards);
		}
		void setAuto() {
			_undo ~= new UndoSPAuto;
			__setAuto(true);
		}
		void setCustom() {
			_undo ~= new UndoSPAuto;
			__setAuto(false);
		}
	}

	static if (UseBacks) {
		bool _viewBacks = true;
		BgImage[PileImage] _backTbl;
		int[BgImage] _editB;
		List _backs;
		MenuItem _vbMenu;
		ToolItem _vbTMenu;
		ToolItem _maskTMenu;
		Spinner _wSpn, _hSpn;

		List backList() {return _backs;}
		void editSpnBack(string T)(int value) {
			__editSpn!(T, BgImage)(value, _editB, 0);
			_imgp.redraw;
		}
		void enterSpnBack(string T, string N)(int value) {
			_undo ~= new UndoEdit;
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
		}
		void selectImageB(FlexImage img) {
			__selectImage!(BgImage)(img, _area.backs, _backTbl, _editB, _backs);
		}
		void setMask() {
			_undo ~= new UndoEdit;
			foreach (back, i; _editB) {
				back.mask = _maskTMenu.getSelection;
				_imgp.images[i].transparent = back.mask;
				_imgp.images[i].createImage;
			}
			_imgp.redraw;
		}
	}

	void selectListItem(T)(List list, int startIndex, ref int[T] edits, T[] cols) {
		int count = list.getItemCount;
		auto imgs = _imgp.images;
		edits = typeof(edits).init;
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
			}
		}
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
		_undo ~= new UndoEdit;
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

	void __selectImage(T)(FlexImage img, T[] cols, T[PileImage] tbl, ref int[T] edits, List list) {
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

	int[] __refreshSelected(T)(bool view, List list, ref int[T] edits, T[] cols, int startIndex) {
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
			auto cs = _area.cards;
			string[] itms;
			itms.length = cs.length;
			foreach (i, c; cs) itms[i] = cardName(c);
			_cards.setItems(itms);
		}
	}
	static if (UseBacks) {
		private void refreshBacks() {
			auto cs = _area.backs;
			string[] itms;
			itms.length = cs.length;
			foreach (i, c; cs) itms[i] = getBaseName(c.path);
			_backs.setItems(itms);
		}
	}
	int[] __up(T)(bool view, List list, void delegate(int, int) swap, int startIndex) {
		int[] indices;
		if (view && list.getItemCount > 0 && !list.isSelected(0)) {
			for (int i = 1; i < list.getItemCount; i++) {
				if (list.isSelected(i)) {
					_imgp.swap(i + startIndex - 1, i + startIndex);
					swap(i - 1, i);
					string temp = list.getItem(i - 1);
					list.setItem(i - 1, list.getItem(i));
					list.setItem(i, temp);
					indices ~= i;
				}
			}
		}
		return indices;
	}
	int[] __down(T)(bool view, List list, void delegate(int, int) swap, int startIndex) {
		int[] indices;
		if (view && list.getItemCount > 0 && !list.isSelected(list.getItemCount - 1)) {
			for (int i = list.getItemCount - 2; i >= 0; i--) {
				if (list.isSelected(i)) {
					_imgp.swap(i + startIndex + 1, i + startIndex);
					swap(i + 1, i);
					string temp = list.getItem(i + 1);
					list.setItem(i + 1, list.getItem(i));
					list.setItem(i, temp);
					indices ~= i;
				}
			}
		}
		return indices;
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
			}
		}
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
			bool ficmp(FlexImage fi1, FlexImage fi2) {
				int x1, x2;
				auto a = fi1;
				x1 = mixin (X);
				a = fi2;
				x2 = mixin (X);
				return x1 < x2;
			}
			targs = .sort(targs, &ficmp);
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
			}
		}
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
			}
			refreshControls;
			_imgp.redraw;
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
			}
		}
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
		_undo ~= new UndoEdit;
		static if (UseCards) __posTop!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posTop!(BgImage)(0, _area.backs);
		refreshControls;
		_imgp.redraw;
	}
	void posBottom() {
		_undo ~= new UndoEdit;
		static if (UseCards) __posBottom!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posBottom!(BgImage)(0, _area.backs);
		refreshControls;
		_imgp.redraw;
	}
	void posLeft() {
		_undo ~= new UndoEdit;
		static if (UseCards) __posLeft!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posLeft!(BgImage)(0, _area.backs);
		refreshControls;
		_imgp.redraw;
	}
	void posRight() {
		_undo ~= new UndoEdit;
		static if (UseCards) __posRight!(C)(cardsIndex, _area.cards);
		static if (UseBacks) __posRight!(BgImage)(0, _area.backs);
		refreshControls;
		_imgp.redraw;
	}
	void posEven() {
		_undo ~= new UndoEdit;
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
		_undo ~= new UndoEdit;
		static if (UseCards) __scaleEvenC!(int.min, "a > b");
		static if (UseBacks) __scaleEvenB!(int.min, "a > b");
		refreshControls;
		_imgp.redraw;
	}
	void scaleEvenSmall() {
		_undo ~= new UndoEdit;
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
					editImagePane(i);
				}
			}
		}
	}
	void edit() {
		int i = _imgp.selectedIndex;
		if (i >= 0) {
			editImagePane(i);
		}
	}
	void editImagePane(int i) {
		static if (UseCards && UseBacks) {
			if (i >= cardsIndex) {
				editCard(_area.cards[i - cardsIndex]);
			} else {
				editBack(_area.backs[i]);
			}
		} else static if (UseCards) {
			editCard(_area.cards[i - cardsIndex]);
		} else static if (UseBacks) {
			editBack(_area.backs[i]);
		} else {
			static assert (0);
		}
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
		auto rgb = new RGB(_prop.var.etc.backgroundColorR, _prop.var.etc.backgroundColorG, _prop.var.etc.backgroundColorB);
		auto color = new Color(Display.getCurrent, rgb);
		_imgp.setBackgroundColor = color;
		auto biPath = _prop.var.etc.backgroundImage;
		if (biPath.length && .exists(biPath)) {
			auto backImg = loadImage(biPath, false);
			_imgp.setBackgroundImage = new Image(Display.getCurrent, backImg);
		}
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
			usingPopupMenuAccelerator(_imgp);
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
		_undo ~= new UndoEdit;
	}

	void refreshControls() {
		static if (UseCards && UseBacks) {
			_xSpn.setEnabled = _editC.length > 0 || _editB.length > 0;
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
			statusLine = _prop.msgs.areaViewStatus(_summ, cast(AbstractSpCard[]) _editC.keys, _editB.keys, _summ !is null);
		} else static if (UseCards) {
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
			statusLine = _prop.msgs.areaViewStatus(_summ, cast(AbstractSpCard[]) _editC.keys, cast(BgImage[]) [], _summ !is null);
		} else static if (UseBacks) {
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
			statusLine = _prop.msgs.areaViewStatus(_summ, cast(AbstractSpCard[]) [], _editB.keys, _summ !is null);
		} else {
			static assert (0);
		}
	}
	static if (UseCards) {
		int cardsIndex() {
			static if (UseBacks) {
				return _area.backs.length;
			} else {
				return 0;
			}
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
		private void delegate(C) _edit;
		private C[] delegate() _items;
		this(void delegate(C) edit, C[] delegate() items) {
			_edit = edit;
			_items = items;
		}
		private void edit(TypedEvent e) {
			auto l = cast(List) e.widget;
			int i = l.getFocusIndex;
			if (i >= 0) {
				_edit(_items()[i]);
			}
		}
		override void mouseDoubleClick(MouseEvent e) {
			if (e.button == 1) {
				edit(e);
			}
		}
	}
	List createList(C)(Composite parent, string name, Image image, TCPD tcpd,
			void delegate(C) edit, C[] delegate() items) {
		auto comp = new Composite(parent, SWT.NONE);
		comp.setLayout = zeroGridLayout(1);
		auto label = new CLabel(comp, SWT.NONE);
		label.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		label.setText = name;
		label.setImage = image;
		auto list = new List(comp, SWT.MULTI | SWT.BORDER | SWT.H_SCROLL | SWT.V_SCROLL);
		auto mkl = new MKListener!(C)(edit, items);
		list.addMouseListener(mkl);
		auto gd = new GridData(GridData.FILL_BOTH);
		gd.widthHint = 0;
		gd.heightHint = 0;
		list.setLayoutData = gd;
		{
			auto menu = new Menu(parent.getShell, SWT.POP_UP);
			createMenuItem(menu, _prop.msgs.menuCEdit, _prop.images.menuCEdit, &this.edit);
			new MenuItem(menu, SWT.SEPARATOR);
			appendMenuTCPD(_prop, menu, tcpd, true, true, true, true);
			list.setMenu(menu);
			usingPopupMenuAccelerator(list);
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
		addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_comm.refSkin.remove(&refresh);
				_comm.delPaths.remove(&refresh);
				_comm.replPath.remove(&refreshR);
				_comm.replText.remove(&replText);
				_comm.replID.remove(&replText);
				static if (UseCards) {
					_comm.refCardState.remove(&refreshCardState);
				}
			}
		});
		static if (is (C == EnemyCard)) {
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
			_dbgMode = _prop.var.etc.viewEnemyCardDebug;
		} else static if (is (A == BgImageContainer)) {
			_viewMsg = _prop.var.etc.viewMessageEvent;
			_viewParty = _prop.var.etc.viewPartyCardsEvent;
			_fixed = _prop.var.etc.fixedImagesEvent;
		} else {
			static assert (0);
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
					_prop.var.etc.viewEnemyCardDebug = _dbgMode;
				} else static if (is (A == BgImageContainer)) {
					_prop.var.etc.viewMessageEvent = _viewMsg;
					_prop.var.etc.viewPartyCardsEvent = _viewParty;
					_prop.var.etc.fixedImagesEvent = _fixed;
				} else {
					static assert (0);
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
		{
			Composite listsP;
			static if (UseCards && UseBacks) {
				_sash = new SplitPane(lrSash, SWT.VERTICAL);
				listsP = _sash;
			} else {
				listsP = new Composite(lrSash, SWT.NONE);
				listsP.setLayout = new FillLayout;
			}
			static if (UseCards) {
				static if (is (C == MenuCard)) {
					_cards = createList(listsP, prop.msgs.menuCards,
						prop.images.cards, ctcpd, &editCard, &_area.cards);
				} else static if (is (C == EnemyCard)) {
					_cards = createList(listsP, prop.msgs.enemyCards,
						prop.images.cards, ctcpd, &editCard, &_area.cards);
				}
				_cards.addSelectionListener(new SCListener);
				static if (is (C == MenuCard)) {
					auto target = new DropTarget(_cards, DND.DROP_DEFAULT | DND.DROP_COPY);
					target.setTransfer([cast(Transfer) FileTransfer.getInstance, XMLBytesTransfer.getInstance]);
					target.addDropListener(new CLDropTarget);
				}
			}
			static if (UseBacks) {
				_backs = createList(listsP, prop.msgs.backs,
					prop.images.backs, btcpd, &editBack, &_area.backs);
				_backs.addSelectionListener(new SBListener);
				new BLDropTarget(_backs);
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
			static if (UseBacks) appendBgImages(0, area.backs, false);
			static if (UseCards) appendCards(0, area.cards, false);
			foreach (p; _prop.looks.partyCardXY) {
				auto img = createCastCardBackImage(_prop, _comm.skin, p.x, p.y);
				img.alpha = _prop.var.etc.partyCardAlpha;
				img.visible = _viewParty;
				_imgp.append(img);
			}
			{
				auto img = createMessageImage(_prop);
				img.visible = _viewMsg;
				_imgp.append(img);
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
				cardList.setItem(i, name);
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
				_imgp.set(cardsIndex + i, create(c));
				_cards.setItem(i, cardName(c));
				partyIndex++;
			}
		}
		static if (UseBacks) {
			foreach (i, b; _area.backs) {
				_imgp.set(i, create(b));
				_backs.setItem(i, getBaseName(b.path));
				partyIndex++;
			}
		}
		foreach (p; _prop.looks.partyCardXY) {
			auto img = createCastCardBackImage(_prop, _comm.skin, p.x, p.y);
			img.alpha = _prop.var.etc.partyCardAlpha;
			img.visible = _viewParty;
			_imgp.set(partyIndex, img);
			partyIndex++;
		}
		_imgp.select = sels;
		_imgp.redraw;
	}
	void refresh() {
		static if (UseCards && is (C == EnemyCard)) {
			_bgm.refresh;
		}
		refreshPanel;
	}
	static if (UseCards) {
		void setCardFuncs(void delegate(int) removeCard,
				void delegate(int, C) appendCard,
				void delegate(int) renameCard,
				void delegate(int[]) up, void delegate(int[]) down) {
			_removeCard = removeCard;
			_appendCard = appendCard;
			_renameCard = renameCard;
			_upCard = up;
			_downCard = down;
		}
	}
	private void __remove(T)(int index, ref T[PileImage] tbl, int startIndex) {
		tbl.remove(_imgp.images[startIndex + index]);
		_imgp.remove(startIndex + index);
		_comm.refUseCount.call;
	}
	private void __removeRange(T)(int fromIndex, int toIndex, ref T[PileImage] tbl, int startIndex) {
		for (int i = fromIndex + startIndex; i < toIndex + startIndex; i++) {
			tbl.remove(_imgp.images[i]);
		}
		_imgp.removeRange(startIndex + fromIndex, startIndex + toIndex);
		_comm.refUseCount.call;
	}
	static if (UseCards) {
		private void removeCard(int index) {
			__remove(index, _cardTbl, cardsIndex);
			if (_removeCard !is null) _removeCard(index);
		}
		private void removeCardRange(int fromIndex, int toIndex) {
			__removeRange(fromIndex, toIndex, _cardTbl, cardsIndex);
			if (_removeCard !is null) {
				for (int i = toIndex; i >= fromIndex; i--) {
					_removeCard(i);
				}
			}
		}
	}
	static if (UseBacks) {
		private void removeBack(int index) {
			__remove(index, _backTbl, 0);
		}
		private void removeBackRange(int fromIndex, int toIndex) {
			__removeRange(fromIndex, toIndex, _backTbl, 0);
		}
	}

	void up() {
		_undo ~= new UndoUp;
		upImpl;
	}
	private void upImpl() {
		int[] refC;
		int[] refB;
		static if (UseCards) {
			refC = __up!(C)(_viewCards, _cards, &_area.swapCards, cardsIndex);
			if (_upCard) _upCard(refC);
		}
		static if (UseBacks) {
			refB = __up!(BgImage)(_viewBacks, _backs, &_area.swapBacks, 0);
		}
		refreshSelected;
		if (refC.length > 0 || refB.length > 0) _imgp.redraw;
	}
	void down() {
		_undo ~= new UndoDown;
		downImpl;
	}
	private void downImpl() {
		int[] refC;
		int[] refB;
		static if (UseCards) {
			refC = __down!(C)(_viewCards, _cards, &_area.swapCards, cardsIndex);
			if (_downCard) _downCard(refC);
		}
		static if (UseBacks) {
			refB = __down!(BgImage)(_viewBacks, _backs, &_area.swapBacks, 0);
		}
		refreshSelected;
		if (refC.length > 0 || refB.length > 0) _imgp.redraw;
	}
	static if (UseCards && UseBacks) {
		private void reverseView(T)(ref bool view, List list, int[T] edits, T[] delegate() col, int startIndex,
				MenuItem menu, ToolItem titm) {
			if (_imgp.isVisible) .forceFocus(this);
			view = !view;
			list.setEnabled = view;
			for (int i = 0; i < col().length; i++) {
				auto fi = cast(FlexImage) _imgp.images[startIndex + i];
				fi.visible = view;
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
		void createCard() {
			static if (is (C == EnemyCard)) {
				if (!_summ) return;
				if (_summ.casts.length == 0) return;
			}
			auto dlg = new SpCardDialog!(C)(_comm, _prop, getShell, _summ, null);
			if (dlg.open) {
				int index = insertIndex(_cards);
				static if (UseBacks) {
					_undo ~= new UndoInsert([index], []);
				} else {
					_undo ~= new UndoInsert([index]);
				}
				appendCard(index, dlg.card, true, true);
			}
		}
		void editCard(C card) {
			foreach (i, c; _area.cards) {
				if (c is card) {
					_imgp.select([i + cardsIndex]);
					refreshSelected;
					break;
				}
			}
			auto undo = new UndoEdit;
			auto dlg = new SpCardDialog!(C)(_comm, _prop, getShell, _summ, card);
			if (dlg.open) {
				_undo ~= undo;
				int index;
				foreach (i, c; _area.cards) {
					if (c is card) {
						auto fi = create(card);
						_imgp.set(cardsIndex + i, fi);
						if (_cards.isSelected(i) && _viewCards) _imgp.select(fi);
						_cards.setItem(i, fi.title);
						if (_renameCard) _renameCard(i);
						refreshControls;
						_comm.refUseCount.call;
						_imgp.redraw;
						return;
					}
				}
				assert (0);
			}
		}
		bool isViewCards() {
			return _viewCards;
		}
		protected abstract {
			string cardName(C element);
			FlexImage createCardImage(C card, bool smoothing);
			string cardImagePath(C card);
		}
	}
	static if (UseBacks) {
		void createBackground() {
			auto dlg = new BgImageDialog(_comm, _prop, getShell, _summ, null);
			if (dlg.open) {
				int index = insertIndex(_backs);
				static if (UseCards) {
					_undo ~= new UndoInsert([], [index]);
				} else {
					_undo ~= new UndoInsert([index]);
				}
				appendBgImage(index, dlg.back, true, true);
			}
		}
		void editBack(BgImage back) {
			foreach (i, b; _area.backs) {
				if (b is back) {
					_imgp.select([i]);
					refreshSelected;
					break;
				}
			}
			auto undo = new UndoEdit;
			auto dlg = new BgImageDialog(_comm, _prop, getShell, _summ, back);
			if (dlg.open) {
				_undo ~= undo;
				foreach (i, b; _area.backs) {
					if (b is back) {
						auto fi = create(back);
						_imgp.set(i, fi);
						if (_backs.isSelected(i) && _viewBacks) _imgp.select(fi);
						_backs.setItem(i, getBaseName(back.path));
						refreshControls;
						_comm.refUseCount.call;
						_imgp.redraw;
						return;
					}
				}
				assert (0);
			}
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
		static if (UseCards && is(C == EnemyCard)) {
			new MenuItem(mv, SWT.SEPARATOR);
			_dbgMenu = createMenuItem(mv,
				_prop.msgs.menuEnemyCardDebugView,
				_prop.images.menuEnemyCardDebugView,
				&reverseDebugMode, SWT.CHECK);
			_dbgMenu.setSelection = _dbgMode;
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
		static if (UseCards && is(C == EnemyCard)) {
			new ToolItem(bar, SWT.SEPARATOR);
			_dbgTMenu = createToolItem(bar,
				_prop.msgs.ttEnemyCardDebugView,
				_prop.images.menuEnemyCardDebugView,
				&reverseDebugMode, SWT.CHECK);
			_dbgTMenu.setSelection = _dbgMode;
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
			_bgmTMenu = createToolItem(bar, _prop.msgs.playBGM, _prop.images.playBGM, &__playBGM, SWT.CHECK);
			_bgmTMenu.addDisposeListener(new StopBGM);
			_bgm.path = _area.music;
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
	private int insertIndex(List list) {
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
		private void appendCard(int index, C card, bool select, bool refresh) {
			auto img = create(card);
			_imgp.deselectAll;
			_imgp.insert(cardsIndex + index, img);
			_area.insert(index, card);
			_cards.add(cardName(card), index);
			if (select && _viewCards) {
				_imgp.select(img);
				if (refresh) {
					refreshSelected;
				}
			}
			if (_appendCard) _appendCard(index, card);
			_imgp.redraw;
			_comm.refUseCount.call;
		}
		private FlexImage create(C card) {
			auto img = createCardImage(card, _prop.var.etc.smoothingCard);
			_cardTbl[img] = card;
			img.visible = isViewCards;
			img.fixed = isFixed;
			img.addSelectionListener(&selectImageC);
			img.addResizeListener(&resizeImageC);
			return img;
		}
		private void appendCards(int index, C[] cards, bool select = false) {
			FlexImage[] imgs;
			foreach (i, card; cards) {
				auto img = create(card);
				imgs ~= img;
				if (_appendCard) _appendCard(index + i, card);
			}
			_imgp.insert(cardsIndex + index, imgs);
			foreach (i, c; cards) _cards.add(cardName(c), index + i);
			if (select && _viewCards) _imgp.select(imgs);
		}
		static if (is (C == MenuCard)) {
			private int cardFromFile(string fname, int x, int y, bool fromImgPane) {
				if (!_summ) return -1;
				if (!hasPath(_summ.scenarioPath, fname)) {
					auto dlg = new MessageBox(getShell, SWT.ICON_QUESTION | SWT.YES | SWT.NO | SWT.CANCEL);
					scope (exit) dlg.dispose;
					dlg.setMessage = _prop.msgs.dlgMsgDropCard(fname);
					dlg.setText = _prop.msgs.dlgTitDropCard;
					auto ret = dlg.open();
					if (SWT.YES == ret) {
						fname = copyTo(_summ.scenarioPath, fname, _comm.skin.materialPath);
					} else if (SWT.CANCEL == ret) {
						return -1;
					}
				}
				auto card = new MenuCard(getBaseName(.getName(fname)), fname, "", "", x, y, 1.0);
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
							static if (UseBacks) {
								auto undo = new UndoInsert(addC, []);
							} else {
								auto undo = new UndoInsert(addC);
							}
							_comm.refPaths.call(_comm.skin.materialPath);
						}
						return;
					} else if (isXMLBytes(e.data)) {
						int i = appendCardFromXML(bytesToXML(e.data), 0, 0, false);
						if (i >= 0) {
							static if (UseBacks) {
								_undo ~= new UndoInsert([i], []);
							} else {
								_undo ~= new UndoInsert([i]);
							}
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
		private void appendBgImage(int index, BgImage back, bool select, bool refresh) {
			_imgp.deselectAll;
			auto img = create(back);
			_imgp.insert(index, img);
			_area.insert(index, back);
			_backs.add(getBaseName(back.path), index);
			if (select && _viewBacks) {
				_imgp.select(img);
				if (refresh) {
					refreshSelected;
				}
			}
			_imgp.redraw;
			_comm.refUseCount.call;
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
		private void appendBgImages(int index, BgImage[] backs, bool select = false) {
			FlexImage[] imgs;
			foreach (back; backs) {
				imgs ~= create(back);
			}
			_imgp.insert(index, imgs);
			foreach (i, b; backs) _backs.add(getBaseName(b.path), index + i);
			if (select && _viewBacks) _imgp.select(imgs);
		}
		private int backFromFile(string fname, int x, int y, int w, int h, bool fromImgPane) {
			if (!_summ) return -1;
			if (!hasPath(_summ.scenarioPath, fname)) {
				auto dlg = new MessageBox(getShell, SWT.ICON_QUESTION | SWT.YES | SWT.NO | SWT.CANCEL);
				scope (exit) dlg.dispose;
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
					static if (UseCards) {
						_undo ~= new UndoInsert([], addB);
					} else {
						_undo ~= new UndoInsert(addB);
					}
					_comm.refPaths.call(_comm.skin.materialPath);
				}
			}
		}
	}

	static if (UseCards && is (C == MenuCard)) {
		int appendCardFromXML(string xml, int x, int y, bool fromImgPane) {
			try {
				auto root = XNode.parse(xml);
				auto card = MenuCard.createFromCardNode(root, LATEST_VERSION);
				if (!card) return -1;
				card.x = x;
				card.y = y;
				return appendCard(card, true, true, fromImgPane);
			} catch {}
			return -1;
		}
	}
	private class IPDropTarget : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e){
			e.detail = _summ ? DND.DROP_COPY : DND.DROP_NONE;
		}
		static if (UseCards) private int[] addC;
		static if (UseBacks) private int[] addB;
		override void drop(DropTargetEvent e) {
			assert (_summ);
			static if (UseCards) scope (exit) addC = [];
			static if (UseBacks) scope (exit) addB = [];
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
					static if (UseCards && UseBacks) {
						_undo ~= new UndoInsert(addC, addB);
					} else static if (UseCards) {
						_undo ~= new UndoInsert(addC);
					} else static if (UseBacks) {
						_undo ~= new UndoInsert(addB);
					} else static assert (0);
					_comm.refPaths.call(_comm.skin.materialPath);
				}
				return;
			}
			static if (UseCards && is (C == MenuCard)) {
				if (isXMLBytes(e.data)) {
					scope p = _imgp.toControl(e.x, e.y);
					int i = appendCardFromXML(bytesToXML(e.data), p.x, p.y, true);
					if (i >= 0) {
						static if (UseBacks) {
							_undo ~= new UndoInsert([i], []);
						} else {
							_undo ~= new UndoInsert([i]);
						}
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
					cardList.setItem(i, castCard.name);
					if (_renameCard) _renameCard(i);
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
					cardList.setItem(i, "");
				}
			}
			imagePane.redraw;
		}
	}
	void cut(SelectionEvent se) {
		_undo ~= new UndoDelete;
		_tcpd.cut(se);
	}
	void copy(SelectionEvent se) {
		_tcpd.copy(se);
	}
	void paste(SelectionEvent se) {
		_tcpd.paste(se);
	}
	void del(SelectionEvent se) {
		_undo ~= new UndoDelete;
		delImpl;
	}
	private void delImpl() {
		_tcpd.del(null);
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
					auto cb = new Clipboard(Display.getCurrent);
					scope (exit) cb.dispose;
					XMLtoCB(_prop, cb, Area.CBtoXML(cards, backs));
				}
			}
			void paste(SelectionEvent se) {
				auto cb = new Clipboard(Display.getCurrent);
				scope (exit) cb.dispose;
				auto xml = CBtoXML(cb);
				if (xml) {
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
						appendBgImages(iib, bs, true);
						auto iic = insertIndex(_cards);
						foreach (i, c; cs) {
							int index = iic + i;
							addC ~= index;
							_area.insert(index, c);
						}
						appendCards(iic, cs, true);
						if (_viewCards || _viewBacks) _imgp.redraw;
						refreshSelected;
						_comm.refUseCount.call;
						_undo ~= new UndoInsert(addC, addB);
					}
				}
			}
			void del(SelectionEvent se) {
				int i;
				while (0 <= (i = _cards.getSelectionIndex)) {
					_area.removeCard(i);
					removeCard(i);
					_cards.remove(i);
				}
				while (0 <= (i = _backs.getSelectionIndex)) {
					_area.removeBgImage(i);
					removeBack(i);
					_backs.remove(i);
				}
				_imgp.redraw;
				refreshSelected;
				_comm.refUseCount.call;
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
					auto cb = new Clipboard(Display.getCurrent);
					scope (exit) cb.dispose;
					XMLtoCB(_prop, cb, A.CtoXML(cards));
				}
			}
			void paste(SelectionEvent se) {
				static if (UseBacks) {
					this.outer.paste(se);
				} else {
					auto cb = new Clipboard(Display.getCurrent);
					scope (exit) cb.dispose;
					auto xml = CBtoXML(cb);;
					if (xml) {
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
							appendCards(insertIndex(_cards), cs, true);
							if (_viewCards) _imgp.redraw;
							refreshSelected;
							_comm.refUseCount.call;
							static if (UseBacks) {
								_undo ~= new UndoInsert(addC, []);
							} else {
								_undo ~= new UndoInsert(addC);
							}
						}
					}
				}
			}
			void del(SelectionEvent se) {
				int i;
				while (0 <= (i = _cards.getSelectionIndex)) {
					_area.removeCard(i);
					removeCard(i);
					_cards.remove(i);
				}
				_imgp.redraw;
				refreshSelected;
				_comm.refUseCount.call;
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
					auto cb = new Clipboard(Display.getCurrent);
					scope (exit) cb.dispose;
					XMLtoCB(_prop, cb, A.BtoXML(backs));
				}
			}
			void paste(SelectionEvent se) {
				static if (UseCards) {
					this.outer.paste(se);
				} else {
					auto cb = new Clipboard(Display.getCurrent);
					scope (exit) cb.dispose;
					auto xml = CBtoXML(cb);
					if (xml) {
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
							appendBgImages(insertIndex(_backs), bs, true);
							if (_viewBacks) _imgp.redraw;
							refreshSelected;
							_comm.refUseCount.call;
							static if (UseCards) {
								_undo ~= new UndoInsert([], addB);
							} else {
								_undo ~= new UndoInsert(addB);
							}
						}
					}
				}
			}
			void del(SelectionEvent se) {
				int i;
				while (0 <= (i = _backs.getSelectionIndex)) {
					_area.removeBgImage(i);
					removeBack(i);
					_backs.remove(i);
				}
				_imgp.redraw;
				refreshSelected;
				_comm.refUseCount.call;
			}
			bool canDoTCPD() {
				return _backs.isVisible && _backs.isEnabled;
			}
		}
	}
	void undo() {_undo.undo;}
	void redo() {_undo.redo;}

	bool openCWXPath(string path) {
		auto cate = cpcategory(path);
		auto index = cpindex(path);
		bool sel(List list) {
			if (index >= list.getItemCount) return false;
			.forceFocus(_imgp);
			list.deselectAll;
			list.select = index;
			list.showSelection;
			return true;
		}
		static if (UseCards && is(C : MenuCard)) {
			if (cate == "menucard") {
				if (sel(_cards)) {
					listSelectC;
					return true;
				}
			}
		}
		static if (UseCards && is(C : EnemyCard)) {
			if (cate == "enemycard") {
				if (sel(_cards)) {
					listSelectC;
					return true;
				}
			}
		}
		static if (UseBacks) {
			if (cate == "background") {
				if (sel(_backs)) {
					listSelectB;
					return true;
				}
			}
		}
		return false;
	}
}

class AreaView : AbstractAreaView!(Area, MenuCard, true, true) {
	private Commons _comm;
	this(Commons comm, Props prop, Summary summ, Area area, Composite parent, TopLevelPanel tlp, UndoManager undo) {
		_comm = comm;
		super(comm, prop, summ, area, parent, tlp, undo);
	}
protected override:
	string cardName(MenuCard element) {
		return element.name;
	}
	FlexImage createCardImage(MenuCard card, bool smoothing) {
		return createMenuCardImage
			(prop, _comm.skin, card.name,
			cardImagePath(card), card.x, card.y, card.scale, smoothing);
	}
	string cardImagePath(MenuCard card) {
		return _comm.skin.findImagePath(card.path, summary.scenarioPath);
	}
}

class BattleView : AbstractAreaView!(Battle, EnemyCard, true, false) {
	private Commons _comm;
	this(Commons comm, Props prop, Summary summ, Battle btl, Composite parent, TopLevelPanel tlp, UndoManager undo) {
		_comm = comm;
		super(comm, prop, summ, btl, parent, tlp, undo);
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
private:
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
					_undo ~= new UndoInsert(indices);
				}
			}
		}
	}
protected override:
	string cardName(EnemyCard card) {
		auto castCard = summary.casts(card.id);
		return castCard ? castCard.name : "";
	}
	FlexImage createCardImage(EnemyCard card, bool smoothing) {
		auto skin = _comm.skin;
		auto castCard = summary.casts(card.id);
		if (castCard) {
			return createCastCardImage(prop, skin, castCard, _summ.scenarioPath,
				card.x, card.y, card.scale, smoothing, debugMode);
		} else {
			return createCastCardImage(prop, skin, null, _summ.scenarioPath,
				card.x, card.y, card.scale, smoothing, debugMode);
		}
	}
	string cardImagePath(EnemyCard card) {
		auto castCard = summary.casts(card.id);
		if (castCard) {
			return _comm.skin.findImagePath(castCard.path, summary.scenarioPath);
		} else {
			return "";
		}
	}
}

class BgImagesView : AbstractAreaView!(BgImageContainer, void, false, true) {
	this(Commons comm, Props prop, Summary summ, BgImageContainer bic, Composite parent, UndoManager undo) {
		super(comm, prop, summ, bic, parent, null, undo);
	}
}

/// 背景画像を生成する。
/// Returns: 背景画像。
FlexImage createBackgroundImage
		(Skin skin, string path, int x, int y, int w, int h, bool transparent) {
	FlexImage r;
	auto ext = getExt(path);
	if (fnmatch(ext, "jpy1") || fnmatch(ext, "jptx") || fnmatch(ext, "jpdc")) {
		auto data = loadJPYImage(skin, path);
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

FlexImage createCardImageCommon(Props prop, ImageData card,
		CInsets matPad, int x, int y, real scale, bool smoothing) {
	auto cardSize = prop.looks.cardSize;
	int w = cardSize.width + matPad.e + matPad.w;
	int h = cardSize.height + matPad.n + matPad.s;
	auto r = new FlexImage(card, x, y, w, h);
	r.minimumWidth = cast(int) rndtol(w * prop.looks.cardSizeMin);
	r.minimumHeight = cast(int) rndtol(h * prop.looks.cardSizeMin);
	r.maximumWidth = cast(int) rndtol(w * prop.looks.cardSizeMax);
	r.maximumHeight = cast(int) rndtol(h * prop.looks.cardSizeMax);
	r.ratioFix = true;
	r.transparent = false;
	r.newWidth = cast(int) rndtol(w * scale);
	r.newHeight = cast(int) rndtol(h * scale);
	r.smoothing = smoothing;
	return r;
}

/// キャストカード画像を生成する。
/// Returns: カード画像。
FlexImage createCastCardImage(Props prop, Skin skin, CastCard card,
		string sPath, int x, int y, real scale, bool smoothing, bool dbgMode) {
	auto matPad = prop.looks.castCardInsets;
	FlexImage r;
	if (card) {
		r = createCardImageCommon(prop, castCardImage(prop, skin, card, sPath, dbgMode),
			matPad, x, y, scale, smoothing);
	} else {
		r = createCardImageCommon(prop, castCard(skin),
			matPad, x, y, scale, smoothing);
	}
	r.resize;
	return r;
}

/// メニューカード画像を生成する。
/// Returns: カード画像。
FlexImage createMenuCardImage(Props prop, Skin skin,
		string title, string path, int x, int y, real scale, bool smoothing) {
	auto matPad = prop.looks.menuCardInsets;
	auto r = createCardImageCommon(prop, menuCard(skin), matPad, x, y, scale, smoothing);
	r.append(path, matPad, true);
	r.setTitle(title, dwtData(prop.looks.menuCardNameFont(skin.legacy)), dwtData(prop.looks.menuCardNamePoint));
	r.resize;
	return r;
}

BgImagesView createBgImagesViewAndMenu(Commons comm, Props prop, Summary summ, BgImageContainer cont, Composite parent) {
	auto view = new BgImagesView(comm, prop, summ, cont, parent, new UndoManager(1024));
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

PileImage createMessageImage(Props prop) {
	auto d = Display.getCurrent;
	auto rect = prop.looks.messageBounds;
	auto bh = prop.looks.messageButtonHeight;
	auto canvas = new Image(d, rect.width, rect.height + bh);
	scope (exit) canvas.dispose;
	auto gc = new GC(canvas);
	scope (exit) gc.dispose;
	int alpha;
	auto c1 = new Color(d, dwtData(prop.looks.messageLineColor1, alpha));
	scope (exit) c1.dispose;
	auto c2 = new Color(d, dwtData(prop.looks.messageLineColor2, alpha));
	scope (exit) c2.dispose;
	auto c3 = new Color(d, dwtData(prop.looks.messageBackColor, alpha));
	scope (exit) c3.dispose;
	gc.setForeground = c1;
	gc.drawRectangle(0, 0, rect.width - 1, rect.height - 1);
	gc.drawRectangle(2, 2, rect.width - 5, rect.height - 5);
	gc.drawRectangle(0, rect.height, rect.width - 1, bh - 1);
	gc.drawRectangle(2, rect.height + 2, rect.width - 5, bh - 5);
	gc.setForeground = c2;
	gc.drawRectangle(1, 1, rect.width - 3, rect.height - 3);
	gc.drawRectangle(1, rect.height + 1, rect.width - 3, bh - 3);
	gc.setBackground = c3;
	gc.fillRectangle(3, 3, rect.width - 6, rect.height - 6);
	gc.fillRectangle(3, rect.height + 3, rect.width - 6, bh - 6);
	auto img = new PileImage(canvas.getImageData, rect.x, rect.y, rect.width, rect.height + bh);
	img.alpha = prop.var.etc.messageAlpha;
	img.createImage;
	return img;
}
