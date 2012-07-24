
module cwx.editor.gui.dwt.dockingfolder;

import cwx.utils;
import cwx.xml;

import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.centerlayout;

import org.eclipse.swt.all;

import java.lang.all;

import std.algorithm;
import std.file;
import std.string;
import std.conv;
import std.ascii;

alias DockingFolder!(CTabFolder, SWT.BORDER | SWT.FLAT | SWT.CLOSE) DockingFolderCTC;

/// 方角。
enum Dir {
	N, /// 北。
	E, /// 東。
	S, /// 南。
	W /// 西。
}
private string dirToString(Dir dir) {
	final switch (dir) {
	case Dir.N: return "north";
	case Dir.E: return "east";
	case Dir.S: return "south";
	case Dir.W: return "west";
	}
}
private Dir stringToDir(string s) {
	switch (.toLower(s)) {
	case "north": return Dir.N;
	case "east": return Dir.E;
	case "south": return Dir.S;
	case "west": return Dir.W;
	default: return Dir.N;
	}
}

/// Controlを新規追加した際、新たに生成されるタブの位置。
enum NewCtrlLocation {
	Right, /// 現在選択中のタブの一つ右。
	Last /// タブリストの末尾。
}

/// 閉じたコントロールの位置情報の記録。
private struct CtrlMemory {
	string pane;
	string pairPane;
	Dir dir;
	int lWeight = 1;
	int rWeight = 1;
}

/// 閉じたペインの位置情報の記録。
private struct PaneMemory {
	string pairPane;
	Dir dir;
	int lWeight = 1;
	int rWeight = 1;
}

class DockingFolder(TabF, int Style) {
	static if (is(TabF == TabFolder)) {
		alias TabItem Tab;
	} else static if (is(TabF == CTabFolder)) {
		alias CTabItem Tab;
	} else static assert (0);
	private static const CLOSE = Style & SWT.CLOSE;
	private enum DPos {N, E, S, W, C, NONE}

	private Composite _comp, _area;

	private string[Control] _ctrls;
	private Control[string] _keys;
	private string[TabF] _tabfs;
	private TabF[string] _tKeys;
	private TabF[] _tabfList;
	private string[SplitPane] _sashs;
	private SplitPane[string] _sKeys;
	private CtrlMemory[string] _cMemories;
	private PaneMemory[string] _pMemories;

	private Canvas _canvas;

	private FocusL _fl;
	private this (Composite parent, int style, bool createTabf, string firstPaneKey = "") {
		_comp = new Composite(parent, SWT.NONE);
		_comp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));

		_canvas = new Canvas(_comp, SWT.TRANSPARENT | SWT.NO_BACKGROUND);
		_canvas.setLayoutData(new CenterLayoutData(true, true));
		_canvas.setVisible(false);
		auto drop = new DropTarget(_canvas, DND.DROP_MOVE);
		drop.setTransfer([TextTransfer.getInstance()]);
		drop.addDropListener(new DTL);
		_canvas.addPaintListener(new PL);

		_area = new Composite(_comp, style);
		_area.addListener(SWT.Dispose, new DListener);
		_area.setLayoutData(new CenterLayoutData(true, true));
		_area.setLayout(new FillLayout);
		if (createTabf) newTabf(_area, firstPaneKey);
		_fl = new FocusL;
		Display.getCurrent().addFilter(SWT.FocusIn, _fl);
	}
	private bool _canSave = true;
	private class DListener : Listener {
		override void handleEvent(Event e) {
			Display.getCurrent().removeFilter(SWT.FocusIn, _fl);
			if (_canSave) {
				try {
					saveTree();
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
	}
	/// 唯一のコンストラクタ。
	/// firstPaneKeyに""を指定した場合は自動的にkeyが生成される。
	this (Composite parent, int style, string firstPaneKey = "") {
		this (parent, style, true, firstPaneKey);
	}

	/// keyから末尾の数値部分を取り除く。
	private static string prefix(string key) {
		while (key.length && (.isDigit(key[$ - 1]) || '_' == key[$ - 1])) {
			auto u = '_' == key[$ - 1];
			key = key[0 .. $ - 1];
			if (u) break;
		}
		return key;
	} unittest {
		assert (prefix("abc_123") == "abc");
		assert (prefix("ab_c_123") == "ab_c");
		assert (prefix("abc") == "abc");
	}

	/// 新しくペインのkeyを生成して返す。
	string newPaneKey(string prefix) {
		int i = 0;
		string key = prefix;
		while (key in _tKeys && key in _sKeys) {
			i++;
			key = .format("%s_%s", prefix, i);
		}
		return key;
	}
	/// 新しくControlのkeyを生成して返す。
	string newCtrlKey(string prefix) {
		int i = 0;
		string key = prefix;
		while (key in _keys) {
			i++;
			key = .format("%s_%s", prefix, i);
		}
		return key;
	}
	/// Controlを移動する際、移動の可否を決定するためのdelegate。
	/// nullの場合は常に移動可能となる。
	/// ctrlKeyには移動するControlのkeyが、dropPaneKeyには移動先の
	/// keyが渡されるが、移動先が新規ペインならdropPaneKeyは""になる。
	bool delegate (string ctrlKey, string dropPaneKey) canMove = null;
	/// 移動によって生成される新規ペインの名前を指定したい場合に
	/// その名前を返すdelegate。
	/// ""を返すと自動的に生成される。
	string delegate (string ctrlKey, string basePane, Dir dir) newPaneName = null;

	private string newTabfKey(string prefix = "t") {
		string key;
		int i = _tabfs.length;
		do {
			key = .format("%s_%d", prefix, i);
			i++;
		} while (key in _tKeys);
		return key;
	}
	/// 全てのペインを返す。
	@property
	Composite[] panes() {return cast(Composite[]) _tabfList;}
	/// ditto
	@property
	string[] paneKeys() {return _tKeys.keys;}
	/// keyに該当するペインを返す。
	/// 存在しない場合はnullを返す。
	Composite pane(string key) {
		auto p = key in _tKeys;
		return p ? *p : null;
	}
	/// ペインのkeyを返す。
	/// 非対象のペインであれば""を返す。
	string key(Composite pane) {
		auto tabf = cast(TabF) pane;
		if (!tabf) throw new Exception("Invalid composite");
		auto p = tabf in _tabfs;
		return p ? *p : "";
	}
	/// paneKeyに該当するペインの選択中のControlのkeyを返す。
	/// 選択中でない場合は""を返す。
	string selectedCtrl(string paneKey) {
		auto tabf = cast(TabF) pane(paneKey);
		if (!tabf) return "";
		auto sel = selected(tabf);
		if (!sel) return "";
		return _ctrls[sel.getControl()];
	}
	/// paneKeyのペインに座標(スクリーン全体座標)に該当する
	/// Controlのタブがあればkeyを返す。
	/// 該当が無い場合は""を返す。
	string control(string paneKey, int x, int y) {
		auto tabf = cast(TabF) pane(paneKey);
		if (!tabf) return "";
		auto itm = tabf.getItem(tabf.toControl(x, y));
		if (!itm) return "";
		return _ctrls[itm.getControl()];
	}

	/// keyに該当するControlを返す。
	/// 存在しない場合はnullを返す。
	Control control(string key) {
		auto p = key in _keys;
		return p ? *p : null;
	}
	/// Controlのkeyを返す。
	/// 非対象のControlであれば""を返す。
	string keyFromCtrl(Control ctrl) {
		auto p = ctrl in _ctrls;
		return p ? *p : "";
	}
	/// 全てのControlを返す。
	@property
	Control[] allControls() {return _ctrls.keys;}
	/// ditto
	@property
	string[] controlKeys() {return _keys.keys;}
	/// 指定されたペインに含まれるControlの一覧。
	Control[] controls(string key) {
		auto tabf = cast(TabF) pane(key);
		if (!tabf) return [];
		Control[] r;
		foreach (tab; tabf.getItems()) {
			r ~= tab.getControl();
		}
		return r;
	}
	/// ditto
	string[] controlKeys(string key) {
		auto tabf = cast(TabF) pane(key);
		if (!tabf) return [];
		string[] r;
		foreach (tab; tabf.getItems()) {
			r ~= _ctrls[tab.getControl()];
		}
		return r;
	}
	/// 現在表示中のコントロールの一覧を返す。
	@property
	Control[] showingControls() {
		Control[] r;
		foreach (tabf; _tabfList) {
			auto tab = selected(tabf);
			if (tab) r ~= tab.getControl();
		}
		return r;
	}
	private Tab tab(string key) {
		auto p = key in _keys;
		if (!p) return null;
		foreach (tab; (cast(TabF) p.getParent()).getItems()) {
			if (tab.getControl() is *p) {
				return tab;
			}
		}
		assert (0, "dockingfolder#tab");
	}
	/// keyに該当するControlタブのテキストを設定する。
	/// 該当するControlが存在しなければfalseを返す。
	bool tabText(string key, string text) {
		auto t = tab(key);
		if (t) {
			t.setText(text);
			return true;
		}
		return false;
	}
	/// keyに該当するControlタブのテキストを返す。
	/// 該当するControlが存在しなければnullを返す。
	string tabText(string key) {
		auto t = tab(key);
		return t ? t.getText() : null;
	}
	/// keyに該当するControlタブのイメージを設定する。
	/// 該当するControlが存在しなければfalseを返す。
	bool tabImage(string key, Image image) {
		auto t = tab(key);
		if (t) {
			t.setImage(image);
			return true;
		}
		return false;
	}
	/// keyに該当するControlタブのイメージを返す。
	/// イメージが設定されていないか、
	/// 該当するControlが存在しなければnullを返す。
	Image tabText(string key) {
		auto t = tab(key);
		return t ? t.getImage() : null;
	}
	/// 最も古いペイン。
	@property
	Composite first() {return panes[0];}
	/// ditto
	@property
	string firstKey() {return _tabfs[cast(TabF) first];}
	/// 全てのペインの親となるComposite。
	@property
	Composite area() {return _comp;}
	private bool vanish(string key) {
		return canVanish ? canVanish(key) : true;
	}
	/// keyのペインが空になった際に呼び出される。
	/// falseを返す事で、ペインの消去を回避する事ができる。
	bool delegate(string key) canVanish = null;

	/// 位置を保存するべきコントロールまたはペインであればtrueを返す。
	bool delegate(string key) memoryControl = null;
	/// ditto
	bool delegate(string key) memoryPane = null;

	/// ペインbaseに対して、dir方向にペインを追加する。
	/// Param:
	///  lWeight, rWeight = 分割した際のサイズの割合。
	///  key = 新たなペインのkey。""を指定した場合は自動的に生成される。
	///        自動生成されたキーは必ず"t"+連番("t%d")の形式になる。
	/// Returns: 生成されたペイン。
	Composite addPane(string base, Dir dir, int lWeight = 1, int rWeight = 1, string key = "") {
		return addPane(pane(base), dir, lWeight, rWeight, key);
	}
	/// ditto
	Composite addPane(Composite base, Dir dir, int lWeight = 1, int rWeight = 1, string key = "") {
		_comp.setRedraw(false);
		scope (exit) _comp.setRedraw(true);
		if (key in _tKeys || key in _sKeys) throw new Exception("invalid key");
		int style = dir == Dir.N || dir == Dir.S ? SWT.VERTICAL : SWT.HORIZONTAL;
		bool before = dir == Dir.N || dir == Dir.W;
		if (!key.length) key = newTabfKey("t");
		auto r = newSash(base, style, before, lWeight, rWeight, key);
		_area.layout(true);
		return r;
	}
	/// keyを接頭辞に持つペインが存在すればそれを返す。
	/// keyを接頭辞に持つペインが以前閉じられたものであれば元々あった場所に追加する。
	/// そうでない場合はbase1またはbase2の指定された方向に追加して返す。
	Composite addPaneFromMemory(string base1, string base2, Dir dir, int lWeight, int rWeight, string key) {
		auto s = findPane2(key);
		if (s) return s;

		auto preKey = prefix(key);
		auto memory = preKey in _pMemories;
		scope (exit) {
			if (memory) _pMemories.remove(preKey);
		}
		auto base = base1;
		if (memory) {
			dir = memory.dir;
			base = memory.pairPane;
			lWeight = memory.lWeight;
			rWeight = memory.rWeight;
		}
		auto pair = findPane2(base);
		if (!pair) {
			auto panes = findPane(base1);
			if (!panes.length) {
				panes = findPane(base2);
			}
			pair = this.pane(panes[0]);
		}

		return addPane(pair, dir, lWeight, rWeight, newPaneKey(key));
	}
	/// Controlを追加する。
	/// ctrlの親は必ずこのインスタンスに含まれるペインでなくてはならない。
	void add(Control ctrl, string tabText, string key, bool select = false, NewCtrlLocation loc = NewCtrlLocation.Last) {
		add(ctrl, tabText, null, key, select);
	}
	/// ditto
	void add(Control ctrl, string tabText, Image tabImage, string key, bool select = false, NewCtrlLocation loc = NewCtrlLocation.Last) {
		if (!key.length || (key in _keys)) throw new Exception("invalid key: " ~ key);
		auto tabf = cast(TabF) ctrl.getParent();
		if (!tabf) throw new Exception("no tabfolder");
		Tab tab;
		final switch (loc) {
		case NewCtrlLocation.Right:
			auto sel = selected(tabf);
			if (!sel) goto case NewCtrlLocation.Last;
			tab = new Tab(tabf, SWT.NONE, tabf.indexOf(sel) + 1);
			break;
		case NewCtrlLocation.Last:
			tab = new Tab(tabf, SWT.NONE);
			break;
		}
		tab.setText(tabText);
		tab.setImage(tabImage);
		tab.setControl(ctrl);
		_ctrls[ctrl] = key;
		_keys[key] = ctrl;
		if (select) {
			tabf.setSelection(tab);
			if (tabf.getShell() is tabf.getDisplay().getActiveShell()) {
				tabf.setFocus();
			}
		}
	}
	/// 指定されたControlが以前配置された事があればその場所に追加する。
	/// 追加された事がなければまずpaneを探して追加しようと試み、
	/// paneが無ければpairPaneの指定された方向に新規ペインを作成して追加する。
	void addFromMemory(Control delegate(Composite) createControl, string tabText, Image tabImage, string key, string pane, string pairPane, Dir dir, bool select = false, NewCtrlLocation loc = NewCtrlLocation.Last) {
		if (!key.length || (key in _keys)) throw new Exception("invalid key: " ~ key);
		Composite p;
		auto memory = key in _cMemories;
		scope (exit) {
			if (memory) _cMemories.remove(key);
		}
		string tPane = pairPane;
		pane = newPaneKey(pane);
		if (memory) {
			pane = memory.pane;
			dir = memory.dir;
			pairPane = memory.pairPane;
		}
		p = findPane2(pane);
		if (!p) {
			int l, r;
			if (memory) {
				l = memory.lWeight;
				r = memory.rWeight;
			} else {
				if (dir == Dir.N || dir == Dir.W) {
					l = 1;
					r = dir == Dir.N ? 3 : 4;
				} else {
					l = dir == Dir.S ? 3 : 4;
					r = 1;
				}
			}
			p = addPaneFromMemory(pairPane, tPane, dir, l, r, pane);
		}
		auto c = createControl(p);
		if (!c) throw new Exception("No control: " ~ key);
		this.add(c, tabText, tabImage, key, select, loc);
	}

	/// keyに該当するペインにmenuを登録する。
	void setMenu(string key, Menu menu) {
		auto p = pane(key);
		if (p) p.setMenu(menu);
	}
	/// prefixから始まるペインのkeyを全て返す。
	string[] findPane(string prefix) {
		string[] r;
		foreach (key, pane; _tKeys) {
			if (std.string.startsWith(key, prefix)) {
				r ~= key;
			}
		}
		return r;
	}
	/// prefixから始まるペイン、または一致するsashを返す。
	private Composite findPane2(string prefix) {
		auto p = prefix in _sKeys;
		if (p) return *p;
		auto p2 = prefix in _tKeys;
		if (p2) return *p2;
		auto panes = findPane(prefix);
		return panes.length ? pane(panes[0]) : null;
	}
	/// prefixから始まるControlのkeyを全て返す。
	string[] findCtrl(string prefix) {
		string[] r;
		foreach (key, ctrl; _keys) {
			if (std.string.startsWith(key, prefix)) {
				r ~= key;
			}
		}
		return r;
	}
	/// Controlを閉じる。閉じる事が可能な該当するControlが無かった場合はfalseを返す。
	bool close(string key) {
		_comp.setRedraw(false);
		scope (exit) _comp.setRedraw(true);
		auto t = tab(key);
		if (t) {
			close(t);
			t.dispose();
			return true;
		}
		return false;
	}
	/// keyに該当しないControlがあるか。
	bool hasEtc(string key) {
		auto tab = this.tab(key);
		if (!tab) return false;
		return tab.getParent().getItems().length > 1;
	}
	/// keyに該当しないControlを閉じる。
	void closeEtc(string key) {
		_comp.setRedraw(false);
		scope (exit) _comp.setRedraw(true);
		auto tab = this.tab(key);
		if (!tab) return;
		foreach (i, t; tab.getParent().getItems()) {
			if (t !is tab) {
				close(t);
				t.dispose();
			}
		}
	}
	/// keyの左側のControlがあるか。
	bool hasLeft(string key) {
		auto tab = this.tab(key);
		if (!tab) return false;
		auto i = tab.getParent().indexOf(tab);
		if (-1 == i) return false;
		return 0 < i;
	}
	/// keyの左側のControlを閉じる。
	void closeLeft(string key) {
		_comp.setRedraw(false);
		scope (exit) _comp.setRedraw(true);
		auto tab = this.tab(key);
		if (!tab) return;
		auto i = tab.getParent().indexOf(tab);
		if (i <= 0) return;
		foreach (t; tab.getParent().getItems()[0 .. i]) {
			close(t);
			t.dispose();
		}
	}
	/// keyの右側のControlがあるか。
	bool hasRight(string key) {
		auto tab = this.tab(key);
		if (!tab) return false;
		auto i = tab.getParent().indexOf(tab);
		if (-1 == i) return false;
		return i + 1 < tab.getParent().getItemCount();
	}
	/// keyの右側のControlを閉じる。
	void closeRight(string key) {
		_comp.setRedraw(false);
		scope (exit) _comp.setRedraw(true);
		auto tab = this.tab(key);
		if (!tab) return;
		auto i = tab.getParent().indexOf(tab);
		if (i >= tab.getParent().getItemCount() - 1) return;
		foreach (t; tab.getParent().getItems()[i + 1 .. $]) {
			close(t);
			t.dispose();
		}
	}
	/// keyを含むペインの全てのControlを閉じる。
	void closeAll(string key) {
		_comp.setRedraw(false);
		scope (exit) _comp.setRedraw(true);
		auto tab = this.tab(key);
		if (!tab) return;
		foreach (t; tab.getParent().getItems()) {
			close(t);
			t.dispose();
		}
	}

	/// ペインが生成された際、ペインのkeyを引数に呼出される。
	void delegate(string)[] createPaneEvent;
	/// createPaneEventの追加と共に、
	/// これまでに生成されたペインに対しての呼出しが行われる。
	void addCreatePaneEvent(void delegate(string) createPaneEvent) {
		this.createPaneEvent ~= createPaneEvent;
		foreach (key; _tabfs) {
			createPaneEvent(key);
		}
	}

	/// Controlタブが選択された際、Controlをkeyを引数に呼出される。
	void delegate(string)[] selectEvent;
	/// Controlタブが閉じられる際、Controlをkeyを引数に呼出される。
	/// falseを返すとキャンセルされる。
	bool delegate(string)[] closeCtrlEvent;

	private TabF newTabf(Composite parent, string key) {
		if (!key.length) key = newTabfKey("t");
		auto tabf = new TabF(parent, Style | SWT.NO_MERGE_PAINTS);
		_tKeys[key] = tabf;
		_tabfs[tabf] = key;
		_tabfList ~= tabf;

		static if (CLOSE) {
			static if (is(TabF : CTabFolder)) {
				tabf.addCTabFolderListener(new CTFL);
			}
		}

		tabf.addSelectionListener(new SelTab);
		tabf.addMouseListener(new ClickTab);
		auto drag = new DragSource(tabf, DND.DROP_MOVE);
		drag.setTransfer([TextTransfer.getInstance()]);
		drag.addDragListener(new DSL(tabf));

		foreach (dlg; createPaneEvent) {
			dlg(key);
		}

		return tabf;
	}
	private Tab _dragItm = null;
	private DPos _dropPos = DPos.NONE;
	private DPos _drawPos = DPos.NONE;
	private TabF _drawTabf = null;
	private void removeTabf(TabF tabf, bool memory) {
		if (memory && memoryPane && memoryPane(_tabfs[tabf])) {
			PaneMemory m;
			m.pairPane = pairKey(tabf, m.dir, m.lWeight, m.rWeight);
			if ("" != m.pairPane) {
				_pMemories[prefix(_tabfs[tabf])] = m;
			}
		}

		tabf.dispose();
		_tabfList = cwx.utils.remove!("a is b")(_tabfList, tabf);
		auto key = _tabfs[tabf];
		_tKeys.remove(key);
		_tabfs.remove(tabf);
		reconstruct();
	}
	private class CTFL :  CTabFolderListener {
		void itemClosed(CTabFolderEvent e) {
			_comp.setRedraw(false);
			scope (exit) _comp.setRedraw(true);
			close(cast(Tab) e.item);
		}
	}
	/// tabfが分割領域の一部であれば分割相手のキーとtabfの方向を返す。
	/// そうでなければ""を返す。
	private string pairKey(TabF tabf, out Dir dir, out int lWeight, out int rWeight) {
		auto comp = cast(SplitPane) tabf.getParent();
		if (comp) {
			auto ws = comp.getWeights();
			lWeight = ws[0];
			rWeight = ws[1];
			auto cs = comp.getChildren();
			if (comp.getStyle() & SWT.VERTICAL) {
				dir = cs[0] is tabf ? Dir.N : Dir.S;
			} else {
				dir = cs[0] is tabf ? Dir.W : Dir.E;
			}
			Control pair;
			if (cs[0] is tabf) {
				pair = cs[1];
			} else {
				pair = cs[0];
			}
			return cast(TabF) pair ? _tabfs[cast(TabF) pair] : _sashs[cast(SplitPane) pair];
		}
		return "";
	}
	private void close(Tab tab) {
		auto ctrl = tab.getControl();
		auto ctrlKey = keyFromCtrl(ctrl);
		foreach (evt; closeCtrlEvent) {
			if (!evt(ctrlKey)) return;
		}
		auto tabf = tab.getParent();
		auto key = _tabfs[tabf];
		auto van = vanish(key);

		// 記録
		if (van && memoryControl && memoryControl(ctrlKey)) {
			CtrlMemory memory;
			memory.pairPane = pairKey(tabf, memory.dir, memory.lWeight, memory.rWeight);
			if ("" != memory.pairPane) {
				memory.pane = _tabfs[tabf];
				_cMemories[ctrlKey] = memory;
			}
		}

		// 削除
		_ctrls.remove(tab.getControl());
		_keys.remove(ctrlKey);
		tab.getControl().dispose();
		if (tabf.getItemCount() == 1 && _area.getChildren()[0] !is tabf) {
			if (van) {
				removeTabf(tabf, true);
				_area.layout(true);
			}
		}
	}
	@property
	private string newSashKey() {
		int i = 0;
		while (true) {
			string sKey = .format("sash_%d", i);
			if (sKey !in _sKeys && sKey !in _tKeys) return sKey;
			i++;
		}
	}
	private void putSashTable(SplitPane sash, string sKey) {
		_sKeys[sKey] = sash;
		_sashs[sash] = sKey;
		sash.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) {
				_sKeys.remove(sKey);
				_sashs.remove(sash);
			}
		});
	}
	/// Controlツリーの再構築。
	private void reconstruct() {
		void tree(Control ctrl) {
			auto comp = cast(SplitPane) ctrl;
			if (!comp) return;
			Control[] children;
			foreach (ch; comp.getChildren()) {
				if (!ch.isDisposed() && !(cast(Sash) ch)) {
					children ~= ch;
				}
			}
			if (children.length == 1) {
				auto aft = afters(comp);
				children[0].setParent(comp.getParent());
				addAfters(aft);
				comp.dispose();
				tree(children[0]);
			} else if (children.length == 2) {
				// _area.layout(true)が効かない事があるので
				// SplitPaneを作り直さなければならない
				auto aft = afters(comp);
				auto weights = comp.getWeights();
				auto sash = new SplitPane(comp.getParent(), comp.getStyle());
				auto key = _sashs[comp];
				addAfters(aft);
				foreach (c; children) {
					c.setParent(sash);
				}
				comp.dispose();
				putSashTable(sash, key);
				foreach (child; children) tree(child);
				sash.setWeights(weights);
			} else {
				assert (!children.length, "dockingfolder#reconstruct");
				comp.dispose();
			}
		}
		tree(_area.getChildren()[0]);
	}
	private void drawDropMark(GC gc, int x, int y, int w, int h) {
		auto d = Display.getCurrent();
		gc.setBackground(d.getSystemColor(SWT.COLOR_BLACK));
		gc.setAlpha(0xff / 2);
		gc.setLineWidth(5);
		final switch (_drawPos) {
		case DPos.C: gc.fillRectangle(x, y, w, h); break;
		case DPos.N: gc.fillRectangle(x, y, w, h / 2); break;
		case DPos.E: gc.fillRectangle(x + w / 2, y, w / 2, h); break;
		case DPos.S: gc.fillRectangle(x, y + h / 2, w, h / 2); break;
		case DPos.W: gc.fillRectangle(x, y, w / 2, h); break;
		case DPos.NONE: break;
		}
	}
	private bool canDrop(TabF tabf) {
		if (!_dragItm) return false;
		if (_dropPos == DPos.NONE) return false;
		if (canMove) {
			auto p = _dragItm.getControl() in _ctrls;
			if (!p) return false;
			auto ctrlKey = *p;
			auto dropPaneKey = _dropPos == DPos.C ? _tabfs[tabf] : "";
			return canMove(ctrlKey, dropPaneKey);
		}
		return true;
	}
	private class PL : PaintListener {
		override void paintControl(PaintEvent e) {
			if (!_drawTabf) return;
			if (!canDrop(_drawTabf)) return;
			auto pos = boundsOnCanvas(_drawTabf);
			auto ca = _drawTabf.getClientArea();
			drawDropMark(e.gc, pos.x + ca.x, pos.y + ca.y, ca.width, ca.height);
		}
	}
	private class DSL : DragSourceListener {
		private TabF _tabf;
		this (TabF tabf) {_tabf = tabf;}
		override void dragStart(DragSourceEvent e) {
			e.doit = false;
			auto itm = _tabf.getItem(new Point(e.x, e.y));
			if (itm) {
				_dragItm = itm;
				e.doit = true;
				_canvas.setVisible(true);
			}
		}
		override void dragSetData(DragSourceEvent e) {
			if (_dragItm) {
				e.data = new ArrayWrapperString(_dragItm.getText());
			}
		}
		override void dragFinished(DragSourceEvent e) {
			_drawTabf = null;
			_canvas.setVisible(false);
			_comp.layout(true);
			if (e.detail == DND.DROP_MOVE) {
				auto tabf = _dragItm.getParent();
				_dragItm.dispose();
				_dragItm = null;
				if (tabf.getItemCount() == 0 && vanish(_tabfs[tabf])) {
					removeTabf(tabf, false);
				}
				_area.layout(true);
			}
		}
	}
	private static Control[] afters(Control targ) {
		auto pcs = targ.getParent().getChildren();
		int pi = .cCountUntil!("a is b")(pcs, targ);
		assert (pi != -1, "dockingfolder#afters");
		return pcs[pi + 1 .. $];
	}
	private static void addAfters(Control[] afters) {
		foreach (ac; afters) {
			auto par = ac.getParent();
			ac.setParent(ac.getParent().getParent());
			ac.setParent(par);
		}
	}
	private static void setInsertMark(TabF tabf, Tab tab, bool after) {
		static if (is(typeof(tabf.setInsertMark(tab, after)))) {
			tabf.setInsertMark(tab, after);
		}
	}
	private static Tab selected(TabF tabf) {
		static if (is(typeof(tabf.getSelection()) == Tab)) {
			return tabf.getSelection();
		} else {
			auto tabs = tabf.getSelection();
			return tabs.length ? tabs[0] : null;
		}
	}
	private Rectangle boundsOnDisplay(Control ctrl) {
		auto p = ctrl.toDisplay(0, 0);
		auto s = ctrl.getSize();
		return new Rectangle(p.x, p.y, s.x, s.y);
	}
	private Rectangle boundsOnCanvas(Control ctrl) {
		auto cvp = _canvas.toDisplay(0, 0);
		auto cp = ctrl.toDisplay(0, 0);
		auto s = ctrl.getSize();
		return new Rectangle(cp.x - cvp.x, cp.y - cvp.y, s.x, s.y);
	}
	private class DTL : DropTargetAdapter {
		override void dragEnter(DropTargetEvent e) {
			dragOver(e);
		}
		override void dragLeave(DropTargetEvent e) {
			e.detail = DND.DROP_NONE;
			_drawPos = DPos.NONE;
			_drawTabf = null;
			_canvas.redraw();
		}
		private TabF getTabf(int x, int y) {
			foreach (t; _tabfList) {
				if (boundsOnDisplay(t).contains(x, y)) {
					return t;
				}
			}
			return null;
		}
		override void dragOver(DropTargetEvent e) {
			auto drawTabf = _drawTabf;
			auto dropPos = _dropPos;
			_dropPos = DPos.NONE;
			e.detail = DND.DROP_NONE;
			auto tabf = getTabf(e.x, e.y);
			_drawTabf = tabf;
			if (tabf) {
				auto p = tabf.toControl(e.x, e.y);
				auto itm = tabf.getItem(p);
				if (itm) {
					setInsertMark(tabf, itm, false);
					_dropPos = DPos.C;
				} else {
					setInsertMark(tabf, null, false);
					auto ca = tabf.getClientArea();
					auto size = tabf.getSize();
					int x = p.x, y = p.y;
					int w = size.x, h = size.y;
					int xn = w - x, yn = h - y;
					if (y < ca.y || (tabf is _dragItm.getParent() && tabf.getItemCount() == 1)) {
						_dropPos = DPos.C;
						if (tabf.getItemCount() > 0) {
							int index = tabf.getItemCount() - 1;
							setInsertMark(tabf, tabf.getItem(index), true);
						}
					} else if (y <= x && y <= xn && y < h / 3) {
						_dropPos = DPos.N;
					} else if (xn <= y && xn <= yn && x > w - w / 3) {
						_dropPos = DPos.E;
					} else if (yn <= x && yn <= xn && y > h - h / 3) {
						_dropPos = DPos.S;
					} else if (x <= y && x <= yn && x < w / 3) {
						_dropPos = DPos.W;
					} else if (0 <= x && 0 <= y && x < w && y < h) {
						_dropPos = DPos.C;
					}
				}
				if (!canDrop(tabf)) _dropPos = DPos.NONE;
				if (_dropPos != DPos.NONE) e.detail = DND.DROP_MOVE;
			}
			if (_dropPos != dropPos || _drawTabf !is drawTabf) {
				_drawPos = _dropPos;
				_canvas.redraw();
			}
		}
		override void drop(DropTargetEvent e) {
			e.detail = DND.DROP_NONE;
			scope (exit) {
				_drawTabf = null;
				_drawPos = DPos.NONE;
				_dropPos = DPos.NONE;
			}
			if (_dropPos == DPos.NONE || !e.data || !_dragItm) return;
			auto dropTarg = getTabf(e.x, e.y);
			if (!dropTarg) return;
			if (!canDrop(dropTarg)) return;
			auto sash = dropTarg.getParent();
			void newTab(TabF tabf, int index) {
				auto tab = index != -1
					? new Tab(tabf, _dragItm.getStyle(), index)
					: new Tab(tabf, _dragItm.getStyle());
				auto c = _dragItm.getControl();
				c.setParent(tabf);
				{
					_onNewTab = true;
					scope (exit) _onNewTab = false;
					_dragItm.setControl(null);
				}
				tab.setControl(c);
				tab.setText(_dragItm.getText());
				tab.setImage(_dragItm.getImage());
				tabf.setSelection(tab);
				if (tabf.getShell() is tabf.getDisplay().getActiveShell()) {
					tabf.setFocus();
				}
			}
			int putCenter() {
				auto dropItm = dropTarg.getItem(dropTarg.toControl(e.x, e.y));
				if (dropItm is _dragItm) return DND.DROP_NONE;
				int i1 = dropItm ? .cCountUntil!("a is b")(dropTarg.getItems(), dropItm) : dropTarg.getItemCount();
				if (dropTarg is _dragItm.getParent()) {
					int i2 = .cCountUntil!("a is b")(dropTarg.getItems(), _dragItm);
					if (i2 + 1 == i1) return DND.DROP_NONE;
				}
				newTab(dropTarg, dropItm ? i1 : -1);
				return DND.DROP_MOVE;
			}
			int nSash(int style, bool before) {
				if (dropTarg is _dragItm.getParent() && dropTarg.getItemCount() == 1) {
					return DND.DROP_NONE;
				}
				if (newPaneName) {
					auto ctrlKey = _ctrls[_dragItm.getControl()];
					Dir dir;
					switch (_dropPos) {
					case DPos.N: dir = Dir.N; break;
					case DPos.E: dir = Dir.E; break;
					case DPos.S: dir = Dir.S; break;
					case DPos.W: dir = Dir.W; break;
					default: assert (0);
					}
				}
				string newKey = newTabfKey(prefix(key(_dragItm.getParent())));
				auto tabf = newSash(dropTarg, style, before, 1, 1, newKey);
				newTab(tabf, -1);
				if (tabf.getShell() is tabf.getDisplay().getActiveShell()) {
					tabf.setFocus();
				}
				return DND.DROP_MOVE;
			}
			switch (_dropPos) {
			case DPos.N: {
				e.detail = nSash(SWT.VERTICAL, true);
			} break;
			case DPos.E: {
				e.detail = nSash(SWT.HORIZONTAL, false);
			} break;
			case DPos.S: {
				e.detail = nSash(SWT.VERTICAL, false);
			} break;
			case DPos.W: {
				e.detail = nSash(SWT.HORIZONTAL, true);
			} break;
			case DPos.C: {
				e.detail = putCenter();
			} break;
			default: break;
			}
		}
	}
	private bool _onNewTab = false;
	private class SelTab : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			auto tabf = cast(TabF) e.widget;
			if (tabf.isFocusControl()) selectTab(tabf);
		}
	}
	private class ClickTab : MouseAdapter {
		override void mouseDown(MouseEvent e) {
			auto tabf = cast(TabF) e.widget;
			if (tabf.getShell() is tabf.getDisplay().getActiveShell()) {
				tabf.setFocus();
			}
		}
	}
	private class FocusL : Listener {
		override void handleEvent(Event e) {
			void control(Control ctrl) {
				if (ctrl.getShell() !is area.getShell()) return;
				auto pane = cast(Composite) ctrl;
				if (!pane) pane = ctrl.getParent();
				while (pane) {
					auto tabf = cast(TabF) pane;
					if (tabf && tabf in _tabfs) {
						selectTab(tabf);
						break;
					}
					pane = pane.getParent();
				}
			}
			auto ctrl = Display.getCurrent().getFocusControl();
			if (ctrl) {
				control(ctrl);
			} else {
				_oldSel = "";
			}
		}
	}
	private string _oldSel = "";
	private void selectTab(TabF tabf) {
		if (_onNewTab) return;
		auto tab = selected(tabf);
		if (!tab) return;
		if (tab.isDisposed()) return;
		auto ctrl = tab.getControl();
		auto key = keyFromCtrl(ctrl);
		if (!key.length) return;
		if (_oldSel != key) {
			_oldSel = key;
			foreach (ls; selectEvent) {
				ls(_ctrls[ctrl]);
			}
		}
	}
	private TabF newSash(Composite targ, int style, bool before, int lWeight, int rWeight, string key) {
		auto parent = targ.getParent();
		int[] weights;
		auto sashf = cast(SplitPane) parent;
		if (sashf) weights = sashf.getWeights();
		scope (exit) if(sashf) sashf.setWeights(weights);
		auto aft = afters(targ);
		auto nSash = new SplitPane(parent, style);
		putSashTable(nSash, newSashKey);
		addAfters(aft);
		TabF r;
		if (before) {
			r = newTabf(nSash, key);
			targ.setParent(nSash);
		} else {
			targ.setParent(nSash);
			r = newTabf(nSash, key);
		}
		nSash.setWeights([lWeight, rWeight]);
		return r;
	}

	private static struct Tabf {
		string key;
		int select;
		Tabi[] tabs;
	}
	private static struct Tabi {
		string key;
		string name;
	}
	private static struct Sashf {
		string key;
		bool vertical;
		int lWeight;
		int rWeight;
		Sashf* lSash;
		Tabf* lTabf;
		Sashf* rSash;
		Tabf* rTabf;
	}
	private static struct Area {
		Sashf* sash;
		Tabf* tabf;
	}
	private Area* _tree = null;
	private void saveTree() {
		auto area = new Area;
		saveTree(_area.getChildren()[0], area.sash, area.tabf);
		assert ((area.sash || area.tabf) && !(area.sash && area.tabf), "dockingfolder#saveTree 1");
		_tree = area;
	}
	private void saveTree(Control c, out Sashf* sa, out Tabf* ta) {
		auto sash = cast(SplitPane) c;
		if (sash) {
			sa = new Sashf;
			ta = null;
			sa.key = _sashs[sash];
			sa.vertical = (sash.getStyle() & SWT.VERTICAL) != 0;
			auto weights = sash.getWeights();
			sa.lWeight = weights[0];
			sa.rWeight = weights[1];
			bool left = true;
			assert (sash.getChildren().length == 3, "dockingfolder#saveTree 2");
			foreach (child; sash.getChildren()) {
				if (!(cast(Sash) child)) {
					if (left) {
						saveTree(child, sa.lSash, sa.lTabf);
						left = false;
					} else {
						saveTree(child, sa.rSash, sa.rTabf);
						break;
					}
				}
			}
			assert ((sa.lSash || sa.lTabf) && !(sa.lSash && sa.lTabf), "dockingfolder#saveTree 3");
			assert ((sa.rSash || sa.rTabf) && !(sa.rSash && sa.rTabf), "dockingfolder#saveTree 4");
		} else {
			ta = new Tabf;
			sa = null;
			auto tabf = cast(TabF) c;
			assert (tabf, "dockingfolder#saveTree 5");
			ta.key = _tabfs[tabf];
			ta.select = tabf.getSelectionIndex();
			ta.tabs.length = tabf.getItemCount();
			foreach (i, tab; tabf.getItems()) {
				ta.tabs[i].key = _ctrls[tab.getControl()];
				ta.tabs[i].name = tab.getText();
			}
		}
	}

	/// XMLノードにして返す。dispose後も呼出し可能。
	/// excludeに含まれる文字列で開始されるタブは無視される。
	XNode toNode(string[] exclude = []) {
		auto r = XNode.create("dockingFolder");
		toNodeImpl(r, exclude);
		return r;
	}
	/// ditto
	XNode toNode(ref XNode parent, string[] exclude = []) {
		auto r = parent.newElement("dockingFolder");
		toNodeImpl(r, exclude);
		return r;
	}
	private XNode toNodeImpl(ref XNode r, string[] exclude) {
		if (!_area.isDisposed()) {
			saveTree();
		}

		if (_cMemories.length) {
			auto ctrlM = r.newElement("controlMemories");
			foreach (key, memory; _cMemories) {
				auto e = ctrlM.newElement("controlMemory", key);
				e.newAttr("pane", memory.pane);
				e.newAttr("pairPane", memory.pairPane);
				e.newAttr("dir", dirToString(memory.dir));
				e.newAttr("lWeight", memory.lWeight);
				e.newAttr("rWeight", memory.rWeight);
			}
		}
		if (_pMemories.length) {
			auto paneM = r.newElement("paneMemories");
			foreach (key, memory; _pMemories) {
				auto e = paneM.newElement("paneMemory", key);
				e.newAttr("pairPane", memory.pairPane);
				e.newAttr("dir", dirToString(memory.dir));
				e.newAttr("lWeight", memory.lWeight);
				e.newAttr("rWeight", memory.rWeight);
			}
		}

		assert (_tree, "dockingfolder#toNodeImpl");
		if (_tree.sash) {
			return toNodeImpl(r, _tree.sash, exclude);
		} else {
			return toNodeImpl(r, _tree.tabf, exclude);
		}
	}
	private XNode toNodeImpl(ref XNode parent, Sashf* sa, string[] exclude) {
		auto r = parent.newElement("sash");
		r.newAttr("key", sa.key);
		r.newAttr("type", sa.vertical ? VERTICAL : HORIZONTAL);
		r.newAttr("lWeight", sa.lWeight);
		r.newAttr("rWeight", sa.rWeight);
		void n(Sashf* sa, Tabf* ta) {
			if (sa) {
				toNodeImpl(r, sa, exclude);
			} else {
				toNodeImpl(r, ta, exclude);
			}
		}
		n(sa.lSash, sa.lTabf);
		n(sa.rSash, sa.rTabf);
		return r;
	}
	private XNode toNodeImpl(ref XNode parent, Tabf* ta, string[] exclude) {
		auto r = parent.newElement("tabs");
		if (ta.select >= 0) r.newAttr("select", ta.select);
		r.newAttr("key", ta.key);
		bool sc(string name) {
			foreach (ex; exclude) {
				if (std.string.startsWith(name, ex)) return true;
			}
			return false;
		}
		foreach (tab; ta.tabs) {
			if (sc(tab.key)) continue;
			auto t = r.newElement("tab");
			t.newAttr("key", tab.key);
			t.newAttr("name", tab.name);
		}
		return r;
	}
	private static const HORIZONTAL = "horizontal";
	private static const VERTICAL = "vertical";
	private static struct Proc {
		DockingFolder r;
		Composite par;
		Control delegate(Composite, string) create;
		void delegate(string, TabF) addRemoveList;
		void sash(ref XNode node) {
			string dStr = .text(__LINE__);
			try {
				dStr ~= " - " ~ .text(__LINE__);
				string type = node.attr("type", true);
				/// FIXME: たまに type == VERTICAL の所でアクセス違反が起きる？
				dStr ~= " - " ~ .text(__LINE__);
				auto sash = new SplitPane(par, type == VERTICAL ? SWT.VERTICAL : SWT.HORIZONTAL);
				r.putSashTable(sash, node.attr("key", false, r.newSashKey));
				dStr ~= " - " ~ .text(__LINE__);
				Proc proc;
				proc.r = r;
				proc.par = sash;
				proc.create = create;
				proc.addRemoveList = addRemoveList;
				node.onTag["sash"] = &proc.sash;
				node.onTag["tabs"] = &proc.tabs;
				dStr ~= " - " ~ .text(__LINE__);
				node.parse();
				dStr ~= " - " ~ .text(__LINE__);
				sash.setWeights([node.attr!(int)("lWeight", true), node.attr!(int)("rWeight", true)]);
				dStr ~= " - " ~ .text(__LINE__);
			} catch (Throwable e) {
				fdebugln(dStr);
				fdebugln(e);
				throw new Exception(dStr, __FILE__, __LINE__);
			}
		}
		void tabs(ref XNode node) {
			string dStr = .text(__LINE__);
			try {
				dStr ~= " - " ~ .text(__LINE__);
				auto key = node.attr("key", true);
				dStr ~= " - " ~ key ~ " - " ~ .text(__LINE__);
				auto tabf = r.newTabf(par, key);
				dStr ~= " - " ~ .text(__LINE__);
				node.onTag["tab"] = (ref XNode node) {
					dStr ~= " - " ~ .text(__LINE__);
					auto key = node.attr("key", true);
					dStr ~= " - " ~ .text(__LINE__);
					auto v = create(tabf, key);
					dStr ~= " - " ~ .text(__LINE__);
					if (v) r.add(v, node.attr("name", true), key);
					dStr ~= " - " ~ .text(__LINE__);
				};
				dStr ~= " - " ~ .text(__LINE__);
				node.parse();
				dStr ~= " - " ~ .text(__LINE__);
				auto i = node.attr!(int)("select", false, -1);
				if (0 < tabf.getItemCount()) {
					dStr ~= " - " ~ .text(__LINE__);
					i = std.algorithm.max(i, 0);
					i = std.algorithm.min(i, tabf.getItemCount() - 1);
					tabf.setSelection(i);
				} else {
					addRemoveList(key, tabf);
				}
				dStr ~= " - " ~ .text(__LINE__);
			} catch (Throwable e) {
				fdebugln(dStr);
				fdebugln(e);
				throw new Exception(dStr, __FILE__, __LINE__);
			}
		}
	}
	/// XMLノードから生成して返す。
	/// Param:
	///  create = XMLノード内にControlのkeyが見つかった時に
	///           呼出され、Controlを生成して返すdelegate。
	static DockingFolder fromNode(ref XNode node, Composite parent, int style,
			bool delegate(typeof(this), string) canVanish,
			Control delegate(Composite, string) create,
			void delegate(string) createPaneEvent = null) {
		string dStr = .text(__LINE__);
		try {
			dStr ~= " - " ~ .text(__LINE__);
			assert (node.name == "dockingFolder", "dockingfolder#fromNode");
			DockingFolder r = null;
			try {
				r = new DockingFolder(parent, style, false);

				node.onTag["controlMemories"] = (ref XNode node) {
					node.onTag["controlMemory"] = (ref XNode e) {
						string key = e.value;
						CtrlMemory memory;
						memory.pane = e.attr("pane", false);
						memory.pairPane = e.attr("pairPane", false);
						memory.dir = stringToDir(e.attr("dir", false));
						string lw = e.attr("lWeight", false);
						string rw = e.attr("rWeight", false);
						if (lw.length && isNumeric(lw)) memory.lWeight = .parse!int(lw);
						if (rw.length && isNumeric(rw)) memory.rWeight = .parse!int(rw);
						r._cMemories[key] = memory;
					};
					node.parse();
				};
				node.onTag["paneMemories"] = (ref XNode node) {
					node.onTag["paneMemory"] = (ref XNode e) {
						string key = e.value;
						PaneMemory memory;
						memory.pairPane = e.attr("pairPane", false);
						memory.dir = stringToDir(e.attr("dir", false));
						string lw = e.attr("lWeight", false);
						string rw = e.attr("rWeight", false);
						if (lw.length && isNumeric(lw)) memory.lWeight = .parse!int(lw);
						if (rw.length && isNumeric(rw)) memory.rWeight = .parse!int(rw);
						r._pMemories[key] = memory;
					};
					node.parse();
				};

				dStr ~= " - " ~ .text(__LINE__);
				if (createPaneEvent) r.createPaneEvent ~= createPaneEvent;
				TabF[] removeList;
				Proc proc;
				proc.r = r;
				proc.par = r._area;
				proc.create = create;
				proc.addRemoveList = (string key, TabF tabf) {
					if (!canVanish || canVanish(r, key)) {
						removeList ~= tabf;
					}
				};
				node.onTag["sash"] = &proc.sash;
				node.onTag["tabs"] = &proc.tabs;
				dStr ~= " - " ~ .text(__LINE__);
				node.parse();
				dStr ~= " - " ~ .text(__LINE__);
				foreach (tabf; removeList) {
					r.removeTabf(tabf, true);
				}
				dStr ~= " - " ~ .text(__LINE__);
				return r;
			} catch (Exception e) {
				dStr ~= " - " ~ .text(__LINE__);
				if (r && r.area) {
					dStr ~= " - " ~ .text(__LINE__);
					r._canSave = false;
					r.area.dispose();
				}
				dStr ~= " - " ~ .text(__LINE__);
				throw e;
			}
			dStr ~= " - " ~ .text(__LINE__);
		} catch (Throwable e) {
			fdebugln(dStr);
			fdebugln(e);
			throw new Exception(dStr, __FILE__, __LINE__);
		}
	}
}
