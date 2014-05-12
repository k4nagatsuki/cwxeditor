
module cwx.editor.gui.dwt.dockingfolder;

import cwx.utils;
import cwx.xml;

import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.dutils : intoDisplay;

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
private string dirToString(Dir dir) { mixin(S_TRACE);
	final switch (dir) {
	case Dir.N: return "north";
	case Dir.E: return "east";
	case Dir.S: return "south";
	case Dir.W: return "west";
	}
}
private Dir stringToDir(string s) { mixin(S_TRACE);
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
	bool isSubWindow = false;
	string subPaneKey = "";
	int x = SWT.DEFAULT;
	int y = SWT.DEFAULT;
	int width = SWT.DEFAULT;
	int height = SWT.DEFAULT;
}

class DockingFolder(TabF, int Style) {
	static if (is(TabF == TabFolder)) {
		alias TabItem Tab;
	} else static if (is(TabF == CTabFolder)) {
		alias CTabItem Tab;
	} else static assert (0);
	private static const CLOSE = Style & SWT.CLOSE;
	private enum DPos {N, E, S, W, C, NONE}

	private int _style;
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

	private Shell[] _subShells;
	private Composite[Shell] _subAreas;
	private Canvas[Shell] _subCanvas;
	private bool[Shell] _inDisposeEvent;

	private FocusL _fl;

	private this (Composite parent, int style, bool createTabf, string firstPaneKey = "") { mixin(S_TRACE);
		_comp = new Composite(parent, SWT.NONE);
		_comp.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
		_style = style;

		_canvas = createCanvas(_comp);

		_area = createArea(_comp);
		_area.getShell().addListener(SWT.Dispose, new DListener);
		if (createTabf) newTabf(_area, firstPaneKey);
		_fl = new FocusL;
		Display.getCurrent().addFilter(SWT.MouseDown, _fl);
		Display.getCurrent().addFilter(SWT.FocusIn, _fl);
		Display.getCurrent().addFilter(SWT.Deactivate, _fl);
	}
	private Canvas createCanvas(Composite parent) { mixin(S_TRACE);
		auto canvas = new Canvas(parent, SWT.TRANSPARENT | SWT.NO_BACKGROUND);
		canvas.setLayoutData(new CenterLayoutData(true, true));
		canvas.setVisible(false);
		auto drop = new DropTarget(canvas, DND.DROP_MOVE);
		drop.setTransfer([TextTransfer.getInstance()]);
		drop.addDropListener(new DTL(canvas));
		canvas.addPaintListener(new PL);
		return canvas;
	}
	private Composite createArea(Composite parent) { mixin(S_TRACE);
		auto area = new Composite(parent, _style);
		area.setLayoutData(new CenterLayoutData(true, true));
		area.setLayout(new FillLayout);
		return area;
	}
	private bool _canSave = true;
	private class DListener : Listener {
		override void handleEvent(Event e) { mixin(S_TRACE);
			Display.getCurrent().removeFilter(SWT.MouseDown, _fl);
			Display.getCurrent().removeFilter(SWT.FocusIn, _fl);
			Display.getCurrent().removeFilter(SWT.Deactivate, _fl);
			if (_canSave) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					saveTree();
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
	}
	/// 唯一のコンストラクタ。
	/// firstPaneKeyに""を指定した場合は自動的にkeyが生成される。
	this (Composite parent, int style, string firstPaneKey = "") { mixin(S_TRACE);
		this (parent, style, true, firstPaneKey);
	}

	/// keyから末尾の数値部分を取り除く。
	private static string prefix(string key) { mixin(S_TRACE);
		while (key.length && (.isDigit(key[$ - 1]) || '_' == key[$ - 1])) { mixin(S_TRACE);
			auto u = '_' == key[$ - 1];
			key = key[0 .. $ - 1];
			if (u) break;
		}
		return key;
	} unittest { mixin(S_TRACE);
		assert (prefix("abc_123") == "abc");
		assert (prefix("ab_c_123") == "ab_c");
		assert (prefix("abc") == "abc");
	}

	/// 新しくペインのkeyを生成して返す。
	string newPaneKey(string prefix) { mixin(S_TRACE);
		int i = 0;
		string key = prefix;
		while (key in _tKeys && key in _sKeys) { mixin(S_TRACE);
			i++;
			key = .format("%s_%s", prefix, i);
		}
		return key;
	}
	/// 新しくControlのkeyを生成して返す。
	string newCtrlKey(string prefix) { mixin(S_TRACE);
		int i = 0;
		string key = prefix;
		while (key in _keys) { mixin(S_TRACE);
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

	private string newTabfKey(string prefix = "t") { mixin(S_TRACE);
		string key;
		int i = _tabfs.length;
		do { mixin(S_TRACE);
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
	Composite pane(string key) { mixin(S_TRACE);
		auto p = key in _tKeys;
		return p ? *p : null;
	}
	/// ペインのkeyを返す。
	/// 非対象のペインであれば""を返す。
	string key(Composite pane) { mixin(S_TRACE);
		auto tabf = cast(TabF) pane;
		if (!tabf) throw new Exception("Invalid composite");
		auto p = tabf in _tabfs;
		return p ? *p : "";
	}
	/// paneKeyに該当するペインの選択中のControlのkeyを返す。
	/// 選択中でない場合は""を返す。
	string selectedCtrl(string paneKey) { mixin(S_TRACE);
		auto tabf = cast(TabF) pane(paneKey);
		if (!tabf) return "";
		auto sel = selected(tabf);
		if (!sel) return "";
		return _ctrls[sel.getControl()];
	}
	/// paneKeyのペインに座標(スクリーン全体座標)に該当する
	/// Controlのタブがあればkeyを返す。
	/// 該当が無い場合は""を返す。
	string control(string paneKey, int x, int y) { mixin(S_TRACE);
		auto tabf = cast(TabF) pane(paneKey);
		if (!tabf) return "";
		auto itm = tabf.getItem(tabf.toControl(x, y));
		if (!itm) return "";
		return _ctrls[itm.getControl()];
	}

	/// keyに該当するControlを返す。
	/// 存在しない場合はnullを返す。
	Control control(string key) { mixin(S_TRACE);
		auto p = key in _keys;
		return p ? *p : null;
	}
	/// Controlのkeyを返す。
	/// 非対象のControlであれば""を返す。
	string keyFromCtrl(Control ctrl) { mixin(S_TRACE);
		auto p = ctrl in _ctrls;
		return p ? *p : "";
	}
	/// 全てのControlを返す。
	@property
	Control[] allControls() {return _ctrls.keys;}
	/// ditto
	string[] controlKeys() {return _keys.keys;}
	/// 指定されたペインに含まれるControlの一覧。
	Control[] controls(string key) { mixin(S_TRACE);
		auto tabf = cast(TabF) pane(key);
		if (!tabf) return [];
		Control[] r;
		foreach (tab; tabf.getItems()) { mixin(S_TRACE);
			r ~= tab.getControl();
		}
		return r;
	}
	/// ditto
	string[] controlKeys(string key) { mixin(S_TRACE);
		auto tabf = cast(TabF) pane(key);
		if (!tabf) return [];
		string[] r;
		foreach (tab; tabf.getItems()) { mixin(S_TRACE);
			r ~= _ctrls[tab.getControl()];
		}
		return r;
	}
	/// 指定されたペインに含まれるControlの数。
	/// ペインが存在しない場合は0を返す。
	int controlCount(string key) { mixin(S_TRACE);
		auto tabf = cast(TabF) pane(key);
		if (!tabf) return 0;
		return tabf.getItemCount();
	}
	/// 現在表示中のコントロールの一覧を返す。
	@property
	Control[] showingControls() { mixin(S_TRACE);
		Control[] r;
		foreach (tabf; _tabfList) { mixin(S_TRACE);
			auto tab = selected(tabf);
			if (tab) r ~= tab.getControl();
		}
		return r;
	}
	private Tab tab(string key) { mixin(S_TRACE);
		auto p = key in _keys;
		if (!p) return null;
		foreach (tab; (cast(TabF) p.getParent()).getItems()) { mixin(S_TRACE);
			if (tab.getControl() is *p) { mixin(S_TRACE);
				return tab;
			}
		}
		assert (0, "dockingfolder#tab");
	}
	/// keyに該当するControlタブのテキストを設定する。
	/// 該当するControlが存在しなければfalseを返す。
	bool tabText(string key, string text) { mixin(S_TRACE);
		auto t = tab(key);
		if (t) { mixin(S_TRACE);
			t.setText(text);
			auto shell = t.getControl().getShell();
			if (shell !is _area.getShell()) { mixin(S_TRACE);
				updateSubShellTitle(shell);
			}
			return true;
		}
		return false;
	}
	/// keyに該当するControlタブのテキストを返す。
	/// 該当するControlが存在しなければnullを返す。
	string tabText(string key) { mixin(S_TRACE);
		auto t = tab(key);
		return t ? t.getText() : null;
	}
	/// keyに該当するControlタブのイメージを設定する。
	/// 該当するControlが存在しなければfalseを返す。
	bool tabImage(string key, Image image) { mixin(S_TRACE);
		auto t = tab(key);
		if (t) { mixin(S_TRACE);
			t.setImage(image);
			auto shell = t.getControl().getShell();
			if (shell !is _area.getShell()) { mixin(S_TRACE);
				updateSubShellTitle(shell);
			}
			return true;
		}
		return false;
	}
	/// keyに該当するControlタブのイメージを返す。
	/// イメージが設定されていないか、
	/// 該当するControlが存在しなければnullを返す。
	Image tabText(string key) { mixin(S_TRACE);
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
	/// paneを指定した場合、サブウィンドウのどれかになる可能性もある。
	@property
	Composite area() {return _comp;}
	private Composite getArea(Control c) { mixin(S_TRACE);
		auto shell = c.getShell();
		return shell is _area.getShell() ? _area : _subAreas[shell];
	}

	private bool vanish(string key) { mixin(S_TRACE);
		auto pane = this.pane(key);
		assert (pane !is null);
		if (pane.getShell() is _comp.getShell() && cast(TabF)_area.getChildren()[0]) { mixin(S_TRACE);
			assert (_area.getChildren()[0] is pane);
			assert (_area.getChildren().length == 1);
			return false;
		}
		return canVanish ? canVanish(key) : true;
	}
	/// 中ボタンクリックでタブを閉じようとした際に呼び出される。
	/// falseを返すとキャンセルする。
	bool delegate(string key) closeTabWithMiddleClick = null;

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
	Composite addPane(string base, Dir dir, int lWeight = 1, int rWeight = 1, string key = "") { mixin(S_TRACE);
		return addPane(pane(base), dir, lWeight, rWeight, key);
	}
	/// ditto
	Composite addPane(Composite base, Dir dir, int lWeight = 1, int rWeight = 1, string key = "") { mixin(S_TRACE);
		_comp.setRedraw(false);
		foreach (subShell; _subShells) subShell.setRedraw(false);
		scope (exit) {
			_comp.setRedraw(true);
			foreach (subShell; _subShells) subShell.setRedraw(true);
		}
		if (key in _tKeys || key in _sKeys) throw new Exception("invalid key");
		int style = dir == Dir.N || dir == Dir.S ? SWT.VERTICAL : SWT.HORIZONTAL;
		bool before = dir == Dir.N || dir == Dir.W;
		if (!key.length) key = newTabfKey("t");
		auto r = newSash(base, style, before, lWeight, rWeight, key);
		getArea(base).layout(true);
		return r;
	}
	/// keyを接頭辞に持つペインが存在すればそれを返す。
	/// keyを接頭辞に持つペインが以前閉じられたものであれば元々あった場所に追加する。
	/// そうでない場合はbase1またはbase2の指定された方向に追加して返す。
	Composite addPaneFromMemory(string base1, string base2, Dir dir, int lWeight, int rWeight, string key) { mixin(S_TRACE);
		auto s = findPane2(key);
		if (s) return s;

		auto preKey = prefix(key);
		auto memory = preKey in _pMemories;
		scope (exit) {
			if (memory) _pMemories.remove(preKey);
		}
		auto base = base1;
		if (memory) { mixin(S_TRACE);
			if (memory.isSubWindow) { mixin(S_TRACE);
				Shell shell;
				TabF tabf;
				createSubWindow(memory.subPaneKey, shell, tabf);
				auto parPos = _comp.getShell().getLocation();
				auto b = new Rectangle(memory.x + parPos.x, memory.y + parPos.y, memory.width, memory.height);
				intoDisplay(b.x, b.y, b.width, b.height);
				shell.setBounds(b);
				shell.open();
				return tabf;
			}
			dir = memory.dir;
			base = memory.pairPane;
			lWeight = memory.lWeight;
			rWeight = memory.rWeight;
		}
		auto pair = findPane2(base);
		if (!pair) { mixin(S_TRACE);
			auto panes = findPane(base1, true);
			if (!panes.length) { mixin(S_TRACE);
				panes = findPane(base2, true);
			}
			if (!panes.length) { mixin(S_TRACE);
				panes = findPane(prefix(base1), true);
			}
			if (!panes.length) { mixin(S_TRACE);
				panes = findPane(prefix(base2), true);
			}
			if (panes.length) {
				pair = this.pane(panes[0]);
			} else {
				pair = first;
			}
		}

		return addPane(pair, dir, lWeight, rWeight, newPaneKey(key));
	}
	/// keyを接頭辞に持つControlが存在すれば所属ペインを返す。
	/// keyを接頭辞に持つControlが以前閉じられたものであれば元々の所属ペインを返す。
	/// Controlが以前にも存在しないか、所属ペインが今存在しなければペインを追加する。
	Composite addPaneFromCtrlMemory(string base, Dir dir, int lWeight, int rWeight, string paneKey, string ctrlKey) { mixin(S_TRACE);
		auto s = findPane2(paneKey);
		if (s) return s;
		auto cs = findCtrl(ctrlKey, true);
		if (cs.length) { mixin(S_TRACE);
			return tab(cs[0]).getParent();
		}

		auto preKey = prefix(ctrlKey);
		auto memory = preKey in _cMemories;
		scope (exit) {
			if (memory) _cMemories.remove(preKey);
		}
		if (memory) { mixin(S_TRACE);
			paneKey = memory.pane;
			dir = memory.dir;
			base = memory.pairPane;
			lWeight = memory.lWeight;
			rWeight = memory.rWeight;
		}
		auto pane = findPane2(paneKey);
		if (pane) return pane;

		return addPaneFromMemory(base, base, dir, lWeight, rWeight, paneKey);
	}
	/// Controlを追加する。
	/// ctrlの親は必ずこのインスタンスに含まれるペインでなくてはならない。
	void add(Control ctrl, string tabText, string key, bool select = false, NewCtrlLocation loc = NewCtrlLocation.Last) { mixin(S_TRACE);
		add(ctrl, tabText, null, key, select);
	}
	/// ditto
	void add(Control ctrl, string tabText, Image tabImage, string key, bool select = false, NewCtrlLocation loc = NewCtrlLocation.Last) { mixin(S_TRACE);
		addImpl(ctrl, tabText, tabImage, key, select, loc, false);
	}
	void addImpl(Control ctrl, string tabText, Image tabImage, string key, bool select = false, NewCtrlLocation loc = NewCtrlLocation.Last, bool loading = false) { mixin(S_TRACE);
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
		if (select) { mixin(S_TRACE);
			this.select(key);
		}
		auto shell = tabf.getShell();
		if (shell !is _area.getShell() && !shell.isVisible()) { mixin(S_TRACE);
			if (!loading) tabf.getShell().setVisible(true);
		}
	}
	/// 指定されたControlが以前配置された事があればその場所に追加する。
	/// 追加された事がなければまずpaneを探して追加しようと試み、
	/// paneが無ければpairPaneの指定された方向に新規ペインを作成して追加する。
	void addFromMemory(Control delegate(Composite) createControl, string tabText, Image tabImage, string key, string pane, string pairPane, Dir dir, bool select = false, NewCtrlLocation loc = NewCtrlLocation.Last) { mixin(S_TRACE);
		if (!key.length || (key in _keys)) throw new Exception("invalid key: " ~ key);
		Composite p;
		auto memory = key in _cMemories;
		scope (exit) {
			if (memory) _cMemories.remove(key);
		}
		string tPane = pairPane;
		pane = newPaneKey(pane);
		if (memory) { mixin(S_TRACE);
			pane = memory.pane;
			dir = memory.dir;
			pairPane = memory.pairPane;
		}
		p = findPane2(pane);
		if (!p) { mixin(S_TRACE);
			int l, r;
			if (memory) { mixin(S_TRACE);
				l = memory.lWeight;
				r = memory.rWeight;
			} else { mixin(S_TRACE);
				if (dir == Dir.N || dir == Dir.W) { mixin(S_TRACE);
					l = 1;
					r = dir == Dir.N ? 3 : 4;
				} else { mixin(S_TRACE);
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
	void setMenu(string key, Menu menu) { mixin(S_TRACE);
		auto p = pane(key);
		if (p) p.setMenu(menu);
	}
	/// prefixから始まるペインのkeyを全て返す。
	string[] findPane(string prefix, bool includeSubShells) { mixin(S_TRACE);
		string[] r;
		foreach (key, pane; _tKeys) { mixin(S_TRACE);
			if (!includeSubShells && pane.getShell() !is _area.getShell()) continue;
			if (std.string.startsWith(key, prefix)) { mixin(S_TRACE);
				r ~= key;
			}
		}
		return r;
	}
	/// prefixから始まるペイン、または一致するsashを返す。
	private Composite findPane2(string prefix) { mixin(S_TRACE);
		auto p = prefix in _sKeys;
		if (p) return *p;
		auto p2 = prefix in _tKeys;
		if (p2) return *p2;
		auto panes = findPane(prefix, true);
		return panes.length ? pane(panes[0]) : null;
	}
	/// prefixから始まるControlのkeyを全て返す。
	string[] findCtrl(string prefix, bool includeSubShells) { mixin(S_TRACE);
		string[] r;
		foreach (key, ctrl; _keys) { mixin(S_TRACE);
			if (!includeSubShells && ctrl.getShell() !is _area.getShell()) continue;
			if (std.string.startsWith(key, prefix)) { mixin(S_TRACE);
				r ~= key;
			}
		}
		return r;
	}

	/// area配下のタブを全て返す。
	private Tab[] getTabs(Composite area) {
		Tab[] tabs;
		void recurse(Composite comp) { mixin(S_TRACE);
			if (auto tabf = cast(TabF)comp) { mixin(S_TRACE);
				foreach (tab; tabf.getItems()) { mixin(S_TRACE);
					tabs ~= tab;
				}
			} else { mixin(S_TRACE);
				foreach (child; comp.getChildren()) { mixin(S_TRACE);
					if (auto comp2 = cast(Composite)child) recurse(comp2);
				}
			}
		}
		recurse(area);
		return tabs;
	}
	/// 新規にサブウィンドウを作成する。
	private void createSubWindow(out Shell shell, out Composite area) {
		auto parShl = _comp.getShell();
		shell = new Shell(parShl, SWT.TITLE | SWT.RESIZE | SWT.CLOSE | SWT.TOOL);
		_subShells ~= shell;
		shell.setLayout(new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0));
		_subCanvas[shell] = createCanvas(shell);
		_inDisposeEvent[shell] = false;
		area = createArea(shell);
		_subAreas[shell] = area;
		void tabsClose(Composite area) {
			foreach (tab; getTabs(area)) { mixin(S_TRACE);
				close(tab);
			}
		}
		shell.addShellListener(new class ShellAdapter {
			override void shellClosed(ShellEvent e) { mixin(S_TRACE);
				auto shell = cast(Shell)e.widget;
				auto area = _subAreas[shell];
				_inDisposeEvent[shell] = true;
				shell.setVisible(false);
				// すべてのControlを閉じる
				tabsClose(area);
				if (area.getChildren().length) { mixin(S_TRACE);
					// 閉じられないペインを含む場合は非表示にする
					e.doit = false;
					_inDisposeEvent[shell] = false;
				} else {
					e.doit = true;
				}
			}
		});
		shell.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				auto shell = cast(Shell)e.widget;
				_inDisposeEvent.remove(shell);
				_subCanvas.remove(shell);
				_subAreas.remove(shell);
				cwx.utils.remove!("a is b")(_subShells, shell);
			}
		});
	}
	/// 新規にpaneKeyのペインを含むサブウィンドウを作成する。
	private void createSubWindow(string tabfKey, out Shell shell, out TabF tabf) {
		Composite area;
		createSubWindow(shell, area);
		tabf = newTabf(area, tabfKey);
	}

	/// keyのControlをペインから分離してサブウィンドウにする。
	void createSubWindow(string key) { mixin(S_TRACE);
		if (isSingleWindow(key)) return;
		foreach (moveShell; movingShellEvent) { mixin(S_TRACE);
			moveShell(key);
		}
		auto ctrl = control(key);
		auto oldTabf = cast(TabF)ctrl.getParent();
		auto oldShell = oldTabf.getShell();
		auto size = oldTabf.getSize();
		auto tabfKey = newTabfKey(prefix(this.key(oldTabf)));
		auto tab = this.tab(key);

		Shell shell;
		TabF tabf;
		createSubWindow(tabfKey, shell, tabf);
		shell.setText(tab.getText());
		shell.setImage(tab.getImage());
		newTab(tabf, tab, -1);
		tab.dispose();
		if (oldTabf.getItemCount() == 0 && vanish(_tabfs[oldTabf])) { mixin(S_TRACE);
			removeTabf(oldTabf, false);
		}

		auto d = shell.getDisplay();
		auto ca = shell.computeTrim(SWT.DEFAULT, SWT.DEFAULT, SWT.DEFAULT, SWT.DEFAULT);
		auto cl = d.getCursorLocation();
		cl.x -= size.x / 2;
		cl.y += ca.y / 2;
		size.x += ca.width;
		size.y += ca.height;
		intoDisplay(cl.x, cl.y, size.x, size.y);
		shell.setLocation(cl);
		shell.setSize(size);
		shell.open();
		foreach (moveShell; moveShellEvent) { mixin(S_TRACE);
			moveShell(oldShell, key);
		}
	}
	/// keyのControlのウィンドウ間の移動を通知する。
	void delegate(Shell before, string key)[] moveShellEvent;
	/// keyのControlのウィンドウ間の移動を移動前に通知する。
	void delegate(string key)[] movingShellEvent;

	/// 指定されたpaneKeyがサブウィンドウ内のものか。
	bool isSubWindowPane(string paneKey) { mixin(S_TRACE);
		auto pane = this.pane(paneKey);
		if (!pane) return false;
		return pane.getShell() !is _comp.getShell();
	}
	/// 指定されたkeyのControlがサブウィンドウ内のものか。
	bool isSubWindowCtrl(string key) { mixin(S_TRACE);
		auto ctrl = this.control(key);
		if (!ctrl) return false;
		return ctrl.getShell() !is _comp.getShell();
	}
	/// 指定されたkeyのControlがサブウィンドウ内で唯一のものか。
	bool isSingleWindow(string key) { mixin(S_TRACE);
		if (!isSubWindowCtrl(key)) return false;
		auto ctrl = this.control(key);
		if (!ctrl) return false;
		auto area = getArea(ctrl);
		auto children = area.getChildren();
		return children.length == 1 && cast(TabF)children[0] && (cast(TabF)children[0]).getItemCount() == 1;
	}
	/// 指定されたpaneKeyが持つControlがサブウィンドウ内で唯一のものか。
	bool isSinglePane(string paneKey) { mixin(S_TRACE);
		if (!isSubWindowPane(paneKey)) return false;
		auto pane = this.pane(paneKey);
		auto children = _subAreas[pane.getShell()].getChildren();
		return children.length == 1 && cast(TabF)children[0] && (cast(TabF)children[0]).getItemCount() == 1;
	}

	/// keyのControlを表示する。
	bool select(string key) { mixin(S_TRACE);
		auto tab = this.tab(key);
		if (!tab) return false;
		tab.getParent().setSelection(tab);
		auto shell = tab.getParent().getShell();
		if (shell !is _area.getShell()) updateSubShellTitle(shell);
		return true;
	}
	/// keyの左のControlを表示する。
	bool walkLeft(string key) { mixin(S_TRACE);
		auto tab = this.tab(key);
		if (!tab) return false;
		auto tabf = tab.getParent();
		int count = tabf.getItemCount();
		if (count <= 1) return false;
		int index = tabf.indexOf(tab);
		index = index == 0 ? count - 1 : index - 1;
		return select(keyFromCtrl(tabf.getItem(index).getControl()));
	}
	/// keyの右のControlを表示する。
	bool walkRight(string key) { mixin(S_TRACE);
		auto tab = this.tab(key);
		if (!tab) return false;
		auto tabf = tab.getParent();
		int count = tabf.getItemCount();
		if (count <= 1) return false;
		int index = tabf.indexOf(tab);
		index = index + 1 == count ? 0 : index + 1;
		return select(keyFromCtrl(tabf.getItem(index).getControl()));
	}
	/// Controlを閉じる。閉じる事が可能な該当するControlが無かった場合はfalseを返す。
	bool close(string key) { mixin(S_TRACE);
		_comp.setRedraw(false);
		foreach (subShell; _subShells) subShell.setRedraw(false);
		scope (exit) {
			_comp.setRedraw(true);
			foreach (subShell; _subShells) subShell.setRedraw(true);
		}
		auto t = tab(key);
		if (t) { mixin(S_TRACE);
			close(t);
			return true;
		}
		return false;
	}
	/// keyに該当しないControlがあるか。
	bool hasEtc(string key) { mixin(S_TRACE);
		auto tab = this.tab(key);
		if (!tab) return false;
		return tab.getParent().getItems().length > 1;
	}
	/// keyに該当しないControlを閉じる。
	void closeEtc(string key) { mixin(S_TRACE);
		_comp.setRedraw(false);
		foreach (subShell; _subShells) subShell.setRedraw(false);
		scope (exit) {
			_comp.setRedraw(true);
			foreach (subShell; _subShells) subShell.setRedraw(true);
		}
		auto tab = this.tab(key);
		if (!tab) return;
		foreach (i, t; tab.getParent().getItems()) { mixin(S_TRACE);
			if (t !is tab) { mixin(S_TRACE);
				close(t);
			}
		}
	}
	/// keyの左側のControlがあるか。
	bool hasLeft(string key) { mixin(S_TRACE);
		auto tab = this.tab(key);
		if (!tab) return false;
		auto i = tab.getParent().indexOf(tab);
		if (-1 == i) return false;
		return 0 < i;
	}
	/// keyの左側のControlを閉じる。
	void closeLeft(string key) { mixin(S_TRACE);
		_comp.setRedraw(false);
		foreach (subShell; _subShells) subShell.setRedraw(false);
		scope (exit) {
			_comp.setRedraw(true);
			foreach (subShell; _subShells) subShell.setRedraw(true);
		}
		auto tab = this.tab(key);
		if (!tab) return;
		auto i = tab.getParent().indexOf(tab);
		if (i <= 0) return;
		foreach (t; tab.getParent().getItems()[0 .. i]) { mixin(S_TRACE);
			close(t);
		}
	}
	/// keyの右側のControlがあるか。
	bool hasRight(string key) { mixin(S_TRACE);
		auto tab = this.tab(key);
		if (!tab) return false;
		auto i = tab.getParent().indexOf(tab);
		if (-1 == i) return false;
		return i + 1 < tab.getParent().getItemCount();
	}
	/// keyの右側のControlを閉じる。
	void closeRight(string key) { mixin(S_TRACE);
		_comp.setRedraw(false);
		foreach (subShell; _subShells) subShell.setRedraw(false);
		scope (exit) {
			_comp.setRedraw(true);
			foreach (subShell; _subShells) subShell.setRedraw(true);
		}
		auto tab = this.tab(key);
		if (!tab) return;
		auto i = tab.getParent().indexOf(tab);
		if (i >= tab.getParent().getItemCount() - 1) return;
		foreach (t; tab.getParent().getItems()[i + 1 .. $]) { mixin(S_TRACE);
			close(t);
		}
	}
	/// keyを含むペインの全てのControlを閉じる。
	void closeAll(string key) { mixin(S_TRACE);
		_comp.setRedraw(false);
		foreach (subShell; _subShells) subShell.setRedraw(false);
		scope (exit) {
			_comp.setRedraw(true);
			foreach (subShell; _subShells) subShell.setRedraw(true);
		}
		auto tab = this.tab(key);
		if (!tab) return;
		foreach (t; tab.getParent().getItems()) { mixin(S_TRACE);
			close(t);
		}
	}

	/// ペインが生成された際、ペインのkeyを引数に呼出される。
	void delegate(Composite pane, string)[] createPaneEvent;
	/// createPaneEventの追加と共に、
	/// これまでに生成されたペインに対しての呼出しが行われる。
	void addCreatePaneEvent(void delegate(Composite, string) createPaneEvent) { mixin(S_TRACE);
		this.createPaneEvent ~= createPaneEvent;
		foreach (key, pane; _tabfs) { mixin(S_TRACE);
			createPaneEvent(key, pane);
		}
	}

	/// Controlタブが選択された際、Controlをkeyを引数に呼出される。
	void delegate(string)[] selectEvent;
	/// Controlタブが閉じられる際、Controlをkeyを引数に呼出される。
	/// falseを返すとキャンセルされる。
	bool delegate(string)[] closeCtrlEvent;

	private TabF newTabf(Composite parent, string key) { mixin(S_TRACE);
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

		foreach (dlg; createPaneEvent) { mixin(S_TRACE);
			dlg(tabf, key);
		}

		return tabf;
	}
	private Tab _dragItm = null;
	private DPos _dropPos = DPos.NONE;
	private DPos _drawPos = DPos.NONE;
	private TabF _drawTabf = null;
	private void removeTabf(TabF tabf, bool memory) { mixin(S_TRACE);
		auto shell = tabf.getShell();
		auto area = getArea(tabf);
		auto isSubShell = shell !is _comp.getShell();
		auto key = _tabfs[tabf];

		if (memory && memoryPane && memoryPane(_tabfs[tabf])) { mixin(S_TRACE);
			PaneMemory m;
			m.isSubWindow = false;
			m.pairPane = pairKey(tabf, m.dir, m.lWeight, m.rWeight);
			if ("" == m.pairPane) { mixin(S_TRACE);
				auto comp = area.getChildren()[0];
				if (isSubShell && tabf is comp && !tabf.getItemCount()) {
					// サブウィンドウの最後のタブ
					m.isSubWindow = true;
					m.subPaneKey = key;
					auto parPos = _comp.getShell().getLocation();
					auto bounds = shell.getBounds();
					m.x = bounds.x - parPos.x;
					m.y = bounds.y - parPos.y;
					m.width = bounds.width;
					m.height = bounds.height;
					_pMemories[prefix(_tabfs[tabf])] = m;
				}
			} else {
				_pMemories[prefix(_tabfs[tabf])] = m;
			}
		}

		tabf.dispose();
		_tabfList = cwx.utils.remove!("a is b")(_tabfList, tabf);
		_tKeys.remove(key);
		_tabfs.remove(tabf);

		if (isSubShell && area.getChildren().length == 0) { mixin(S_TRACE);
			if (!_inDisposeEvent[shell]) {
				shell.close();
			}
		} else if (area.getChildren().length) { mixin(S_TRACE);
			reconstruct(area.getChildren()[0]);
		}
		if (isSubShell && !shell.isDisposed() && !getTabs(area).length) { mixin(S_TRACE);
			shell.setVisible(false);
		}
	}
	private class CTFL :  CTabFolderListener {
		void itemClosed(CTabFolderEvent e) { mixin(S_TRACE);
			_comp.setRedraw(false);
			foreach (subShell; _subShells) subShell.setRedraw(false);
			scope (exit) {
				_comp.setRedraw(true);
				foreach (subShell; _subShells) subShell.setRedraw(true);
			}
			e.doit = false;
			close(cast(Tab)e.item);
		}
	}
	/// tabfが分割領域の一部であれば分割相手のキーとtabfの方向を返す。
	/// そうでなければ""を返す。
	private string pairKey(TabF tabf, out Dir dir, out int lWeight, out int rWeight) { mixin(S_TRACE);
		auto comp = cast(SplitPane) tabf.getParent();
		if (comp) { mixin(S_TRACE);
			auto ws = comp.getWeights();
			lWeight = ws[0];
			rWeight = ws[1];
			auto cs = comp.getChildren();
			if (comp.getStyle() & SWT.VERTICAL) { mixin(S_TRACE);
				dir = cs[0] is tabf ? Dir.N : Dir.S;
			} else { mixin(S_TRACE);
				dir = cs[0] is tabf ? Dir.W : Dir.E;
			}
			Control pair;
			if (cs[0] is tabf) { mixin(S_TRACE);
				pair = cs[1];
			} else { mixin(S_TRACE);
				pair = cs[0];
			}
			return cast(TabF) pair ? _tabfs[cast(TabF) pair] : _sashs[cast(SplitPane) pair];
		}
		return "";
	}
	private void close(Tab tab) { mixin(S_TRACE);
		auto ctrl = tab.getControl();
		auto ctrlKey = keyFromCtrl(ctrl);
		foreach (evt; closeCtrlEvent) { mixin(S_TRACE);
			if (!evt(ctrlKey)) return;
		}
		auto tabf = tab.getParent();
		auto key = _tabfs[tabf];
		auto van = vanish(key);
		auto area = getArea(tabf);
		auto shell = tabf.getShell();
		auto isSubShell = shell !is _comp.getShell();

		// 記録
		if (van && memoryControl && memoryControl(ctrlKey)) { mixin(S_TRACE);
			CtrlMemory memory;
			memory.pairPane = pairKey(tabf, memory.dir, memory.lWeight, memory.rWeight);
			if ("" != memory.pairPane) { mixin(S_TRACE);
				memory.pane = _tabfs[tabf];
				_cMemories[ctrlKey] = memory;
			}
		}

		// 削除
		_ctrls.remove(tab.getControl());
		_keys.remove(ctrlKey);
		tab.getControl().dispose();
		tab.dispose();
		if (!tabf.getItemCount() && _area.getChildren()[0] !is tabf) { mixin(S_TRACE);
			if (van) { mixin(S_TRACE);
				removeTabf(tabf, true);
			} else { mixin(S_TRACE);
				area.layout(true);
			}
		}
		if (isSubShell && !shell.isDisposed()) { mixin(S_TRACE);
			// サブウィンドウのタイトルの更新
			if (!tabf.isDisposed() && tabf.getItemCount() && selected(tabf)) { mixin(S_TRACE);
				auto tab2 = selected(tabf);
				shell.setText(tab2.getText());
				shell.setImage(tab2.getImage());
			} else { mixin(S_TRACE);
				if (!updateSubShellTitle(shell)) shell.setVisible(false);
			}
		}
	}
	private bool updateSubShellTitle(Shell shell) { mixin(S_TRACE);
		bool recurse(Composite comp) { mixin(S_TRACE);
			if (auto tabf = cast(TabF)comp) { mixin(S_TRACE);
				auto tab = selected(tabf);
				if (tab) { mixin(S_TRACE);
					shell.setText(tab.getText());
					shell.setImage(tab.getImage());
					return true;
				}
			} else { mixin(S_TRACE);
				foreach (child; comp.getChildren()) { mixin(S_TRACE);
					if (auto comp2 = cast(Composite)child) { mixin(S_TRACE);
						if (recurse(comp2)) return true;
					}
				}
			}
			return false;
		}
		return recurse(_subAreas[shell]);
	}
	@property
	private string newSashKey() { mixin(S_TRACE);
		int i = 0;
		while (true) { mixin(S_TRACE);
			string sKey = .format("sash_%d", i);
			if (sKey !in _sKeys && sKey !in _tKeys) return sKey;
			i++;
		}
	}
	private void putSashTable(SplitPane sash, string sKey) { mixin(S_TRACE);
		_sKeys[sKey] = sash;
		_sashs[sash] = sKey;
		sash.addDisposeListener(new class DisposeListener {
			override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
				_sKeys.remove(sKey);
				_sashs.remove(sash);
			}
		});
	}
	/// Controlツリーの再構築。
	private void reconstruct(Control area) { mixin(S_TRACE);
		void tree(Control ctrl) { mixin(S_TRACE);
			auto comp = cast(SplitPane) ctrl;
			if (!comp) return;
			Control[] children;
			foreach (ch; comp.getChildren()) { mixin(S_TRACE);
				if (!ch.isDisposed() && !(cast(Sash) ch)) { mixin(S_TRACE);
					children ~= ch;
				}
			}
			if (children.length == 1) { mixin(S_TRACE);
				auto aft = afters(comp);
				children[0].setParent(comp.getParent());
				addAfters(aft);
				comp.dispose();
				tree(children[0]);
			} else if (children.length == 2) { mixin(S_TRACE);
				// _area.layout(true)が効かない事があるので
				// SplitPaneを作り直さなければならない
				auto aft = afters(comp);
				auto weights = comp.getWeights();
				auto sash = new SplitPane(comp.getParent(), comp.getStyle());
				auto key = _sashs[comp];
				addAfters(aft);
				foreach (c; children) { mixin(S_TRACE);
					c.setParent(sash);
				}
				comp.dispose();
				putSashTable(sash, key);
				foreach (child; children) tree(child);
				sash.setWeights(weights);
			} else { mixin(S_TRACE);
				assert (!children.length, "dockingfolder#reconstruct");
				comp.dispose();
			}
		}
		auto parent = area.getParent();
		tree(area);
		parent.layout(true);
	}
	private void drawDropMark(GC gc, int x, int y, int w, int h) { mixin(S_TRACE);
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
	private bool canDrop(TabF tabf) { mixin(S_TRACE);
		if (!_dragItm) return false;
		if (_dropPos == DPos.NONE) return false;
		if (canMove) { mixin(S_TRACE);
			auto p = _dragItm.getControl() in _ctrls;
			if (!p) return false;
			auto ctrlKey = *p;
			auto dropPaneKey = _dropPos == DPos.C ? _tabfs[tabf] : "";
			return canMove(ctrlKey, dropPaneKey);
		}
		return true;
	}
	private class PL : PaintListener {
		override void paintControl(PaintEvent e) { mixin(S_TRACE);
			if (!_drawTabf) return;
			if (!canDrop(_drawTabf)) return;
			auto canvas = cast(Canvas)e.widget;
			if (_drawTabf.getShell() !is canvas.getShell()) return;
			auto pos = boundsOnCanvas(canvas, _drawTabf);
			auto ca = _drawTabf.getClientArea();
			drawDropMark(e.gc, pos.x + ca.x, pos.y + ca.y, ca.width, ca.height);
		}
	}
	private class DSL : DragSourceListener {
		private TabF _tabf;
		this (TabF tabf) {_tabf = tabf;}
		override void dragStart(DragSourceEvent e) { mixin(S_TRACE);
			e.doit = false;
			auto itm = _tabf.getItem(new Point(e.x, e.y));
			if (itm) { mixin(S_TRACE);
				_dragItm = itm;
				e.doit = true;
				_canvas.setVisible(true);
				foreach (canvas; _subCanvas.byValue()) { mixin(S_TRACE);
					canvas.setVisible(true);
				}
			}
		}
		override void dragSetData(DragSourceEvent e) { mixin(S_TRACE);
			if (_dragItm) { mixin(S_TRACE);
				e.data = new ArrayWrapperString(_dragItm.getText());
			}
		}
		override void dragFinished(DragSourceEvent e) { mixin(S_TRACE);
			_drawTabf = null;
			_canvas.setVisible(false);
			foreach (canvas; _subCanvas.byValue()) { mixin(S_TRACE);
				canvas.setVisible(false);
			}
			/+_comp.layout(true);+/
			if (e.detail == DND.DROP_MOVE) { mixin(S_TRACE);
				auto area = getArea(_dragItm.getParent());
				auto tabf = _dragItm.getParent();
				_dragItm.dispose();
				_dragItm = null;
				if (tabf.getItemCount() == 0 && vanish(_tabfs[tabf])) { mixin(S_TRACE);
					removeTabf(tabf, false);
				} else { mixin(S_TRACE);
					area.layout(true);
				}
			}
		}
	}
	private static Control[] afters(Control targ) { mixin(S_TRACE);
		auto pcs = targ.getParent().getChildren();
		int pi = .cCountUntil!("a is b")(pcs, targ);
		assert (pi != -1, "dockingfolder#afters");
		return pcs[pi + 1 .. $];
	}
	private static void addAfters(Control[] afters) { mixin(S_TRACE);
		foreach (ac; afters) { mixin(S_TRACE);
			auto par = ac.getParent();
			ac.setParent(ac.getParent().getParent());
			ac.setParent(par);
		}
	}
	private static void setInsertMark(TabF tabf, Tab tab, bool after) { mixin(S_TRACE);
		static if (is(typeof(tabf.setInsertMark(tab, after)))) {
			tabf.setInsertMark(tab, after);
		}
	}
	private static Tab selected(TabF tabf) { mixin(S_TRACE);
		static if (is(typeof(tabf.getSelection()) == Tab)) {
			return tabf.getSelection();
		} else { mixin(S_TRACE);
			auto tabs = tabf.getSelection();
			return tabs && tabs.length ? tabs[0] : null;
		}
	}
	private static Rectangle boundsOnDisplay(Control ctrl) { mixin(S_TRACE);
		auto p = ctrl.toDisplay(0, 0);
		auto s = ctrl.getSize();
		return new Rectangle(p.x, p.y, s.x, s.y);
	}
	private static Rectangle boundsOnCanvas(Canvas canvas, Control ctrl) { mixin(S_TRACE);
		auto cvp = canvas.toDisplay(0, 0);
		auto cp = ctrl.toDisplay(0, 0);
		auto s = ctrl.getSize();
		return new Rectangle(cp.x - cvp.x, cp.y - cvp.y, s.x, s.y);
	}
	private void newTab(TabF tabf, Tab tab, int index) { mixin(S_TRACE);
		auto newTab = index != -1
			? new Tab(tabf, tab.getStyle(), index)
			: new Tab(tabf, tab.getStyle());
		auto c = tab.getControl();
		c.setParent(tabf);
		{ mixin(S_TRACE);
			_onNewTab = true;
			scope (exit) _onNewTab = false;
			tab.setControl(null);
		}
		newTab.setControl(c);
		newTab.setText(tab.getText());
		newTab.setImage(tab.getImage());
		tabf.setSelection(newTab);
		if (tabf.getShell() is tabf.getDisplay().getActiveShell()) { mixin(S_TRACE);
			tabf.setFocus();
		}
	}
	private class DTL : DropTargetAdapter {
		private Canvas _canvas;
		this (Canvas canvas) { _canvas = canvas; }
		override void dragEnter(DropTargetEvent e) { mixin(S_TRACE);
			dragOver(e);
		}
		override void dragLeave(DropTargetEvent e) { mixin(S_TRACE);
			e.detail = DND.DROP_NONE;
			_drawPos = DPos.NONE;
			_drawTabf = null;
			_canvas.redraw();
			foreach (canvas; _subCanvas.byValue()) canvas.redraw();
		}
		private TabF getTabf(int x, int y) { mixin(S_TRACE);
			auto d = _canvas.getDisplay();
			auto cc = d.getCursorControl();
			if (!cc) return null;
			auto shell = cc.getShell();
			auto isSubShell = shell !is _comp.getShell();
			foreach (t; _tabfList) { mixin(S_TRACE);
				if (isSubShell && t.getShell() !is shell) continue;
				if (boundsOnDisplay(t).contains(x, y)) { mixin(S_TRACE);
					return t;
				}
			}
			return null;
		}
		override void dragOver(DropTargetEvent e) { mixin(S_TRACE);
			auto drawTabf = _drawTabf;
			auto dropPos = _dropPos;
			_dropPos = DPos.NONE;
			e.detail = DND.DROP_NONE;
			auto tabf = getTabf(e.x, e.y);
			_drawTabf = tabf;
			if (tabf) { mixin(S_TRACE);
				auto p = tabf.toControl(e.x, e.y);
				auto itm = tabf.getItem(p);
				if (itm) { mixin(S_TRACE);
					setInsertMark(tabf, itm, false);
					_dropPos = DPos.C;
				} else { mixin(S_TRACE);
					setInsertMark(tabf, null, false);
					auto ca = tabf.getClientArea();
					auto size = tabf.getSize();
					int x = p.x, y = p.y;
					int w = size.x, h = size.y;
					int xn = w - x, yn = h - y;
					if (y < ca.y || (tabf is _dragItm.getParent() && tabf.getItemCount() == 1)) { mixin(S_TRACE);
						_dropPos = DPos.C;
						if (tabf.getItemCount() > 0) { mixin(S_TRACE);
							int index = tabf.getItemCount() - 1;
							setInsertMark(tabf, tabf.getItem(index), true);
						}
					} else if (y <= x && y <= xn && y < h / 3) { mixin(S_TRACE);
						_dropPos = DPos.N;
					} else if (xn <= y && xn <= yn && x > w - w / 3) { mixin(S_TRACE);
						_dropPos = DPos.E;
					} else if (yn <= x && yn <= xn && y > h - h / 3) { mixin(S_TRACE);
						_dropPos = DPos.S;
					} else if (x <= y && x <= yn && x < w / 3) { mixin(S_TRACE);
						_dropPos = DPos.W;
					} else if (0 <= x && 0 <= y && x < w && y < h) { mixin(S_TRACE);
						_dropPos = DPos.C;
					}
				}
				if (!canDrop(tabf)) _dropPos = DPos.NONE;
				if (_dropPos != DPos.NONE) e.detail = DND.DROP_MOVE;
			}
			if (_dropPos != dropPos || _drawTabf !is drawTabf) { mixin(S_TRACE);
				_drawPos = _dropPos;
				_canvas.redraw();
				foreach (canvas; _subCanvas.byValue()) canvas.redraw();
			}
		}
		override void drop(DropTargetEvent e) { mixin(S_TRACE);
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
			auto key = keyFromCtrl(_dragItm.getControl());
			auto shell1 = _dragItm.getParent().getShell();
			auto shell2 = dropTarg.getShell();
			int putCenter() { mixin(S_TRACE);
				auto dropItm = dropTarg.getItem(dropTarg.toControl(e.x, e.y));
				if (dropItm is _dragItm) return DND.DROP_NONE;
				int i1 = dropItm ? .cCountUntil!("a is b")(dropTarg.getItems(), dropItm) : dropTarg.getItemCount();
				if (dropTarg is _dragItm.getParent()) { mixin(S_TRACE);
					int i2 = .cCountUntil!("a is b")(dropTarg.getItems(), _dragItm);
					if (i2 + 1 == i1) return DND.DROP_NONE;
				}
				foreach (moveShell; movingShellEvent) { mixin(S_TRACE);
					moveShell(key);
				}
				newTab(dropTarg, _dragItm, dropItm ? i1 : -1);
				if (shell1 !is shell2) { mixin(S_TRACE);
					foreach (moveShell; moveShellEvent) { mixin(S_TRACE);
						moveShell(shell1, key);
					}
				}
				return DND.DROP_MOVE;
			}
			int nSash(int style, bool before) { mixin(S_TRACE);
				if (dropTarg is _dragItm.getParent() && dropTarg.getItemCount() == 1) { mixin(S_TRACE);
					return DND.DROP_NONE;
				}
				if (newPaneName) { mixin(S_TRACE);
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
				foreach (moveShell; movingShellEvent) { mixin(S_TRACE);
					moveShell(key);
				}
				string newKey = newTabfKey(prefix(this.outer.key(_dragItm.getParent())));
				auto tabf = newSash(dropTarg, style, before, 1, 1, newKey);
				newTab(tabf, _dragItm, -1);
				if (tabf.getShell() is tabf.getDisplay().getActiveShell()) { mixin(S_TRACE);
					tabf.setFocus();
				}
				getArea(tabf).layout(true);
				if (shell1 !is shell2) { mixin(S_TRACE);
					foreach (moveShell; moveShellEvent) { mixin(S_TRACE);
						moveShell(shell1, key);
					}
				}
				return DND.DROP_MOVE;
			}
			switch (_dropPos) {
			case DPos.N: { mixin(S_TRACE);
				e.detail = nSash(SWT.VERTICAL, true);
			} break;
			case DPos.E: { mixin(S_TRACE);
				e.detail = nSash(SWT.HORIZONTAL, false);
			} break;
			case DPos.S: { mixin(S_TRACE);
				e.detail = nSash(SWT.VERTICAL, false);
			} break;
			case DPos.W: { mixin(S_TRACE);
				e.detail = nSash(SWT.HORIZONTAL, true);
			} break;
			case DPos.C: { mixin(S_TRACE);
				e.detail = putCenter();
			} break;
			default: break;
			}
		}
	}
	private bool _onNewTab = false;
	private class SelTab : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto tabf = cast(TabF) e.widget;
			if (tabf.isFocusControl()) selectTab(tabf);
		}
	}
	private class ClickTab : MouseAdapter {
		override void mouseDown(MouseEvent e) { mixin(S_TRACE);
			auto tabf = cast(TabF) e.widget;
			if (tabf.getShell() is tabf.getDisplay().getActiveShell()) { mixin(S_TRACE);
				tabf.setFocus();
			}
		}
		override void mouseUp(MouseEvent e) { mixin(S_TRACE);
			if (e.button != 2) return;
			auto tabf = cast(TabF)e.widget;
			auto ca = tabf.getClientArea();
			if (ca.y <= e.y) return;
			auto tab = tabf.getItem(new Point(e.x, e.y));
			if (!tab) return;
			auto ctrl = tab.getControl();
			if (!ctrl) return;
			auto key = keyFromCtrl(ctrl);
			if (!key) return;
			if (closeTabWithMiddleClick && !closeTabWithMiddleClick(key)) return;
			close(key);
		}
	}
	private class FocusL : Listener {
		private Shell _deactivatedShell = null;
		override void handleEvent(Event e) { mixin(S_TRACE);
			// サブウィンドウ操作中にメインウィンドウのツールバーを
			// クリックした場合は選択中タブの変更を通知しない
			if (e.type is SWT.Deactivate) { mixin(S_TRACE);
				if (auto shell = cast(Shell)e.widget) { mixin(S_TRACE);
					_deactivatedShell = shell;
				}
				return;
			}
			if (_deactivatedShell && e.type is SWT.FocusIn) return;
			if (_deactivatedShell && e.type is SWT.MouseDown) { mixin(S_TRACE);
				_deactivatedShell = null;
				if (auto toolbar = cast(ToolBar)e.widget) { mixin(S_TRACE);
					toolbar.setFocus();
					return;
				}
			}
			_deactivatedShell = null;

			void control(Control ctrl) { mixin(S_TRACE);
				auto shell = ctrl.getShell();
				if (shell !is area.getShell() && !_subShells.contains!"a is b"(shell)) return;
				auto pane = cast(Composite) ctrl;
				if (!pane) pane = ctrl.getParent();
				while (pane) { mixin(S_TRACE);
					auto tabf = cast(TabF) pane;
					if (tabf && tabf in _tabfs) { mixin(S_TRACE);
						selectTab(tabf);
						break;
					}
					pane = pane.getParent();
				}
			}
			auto ctrl = cast(Control)e.display.getFocusControl();
			if (ctrl) { mixin(S_TRACE);
				control(ctrl);
			} else { mixin(S_TRACE);
				_oldSel = "";
			}
		}
	}
	private string _oldSel = "";
	private void selectTab(TabF tabf) { mixin(S_TRACE);
		if (_onNewTab) return;
		auto tab = selected(tabf);
		if (!tab) return;
		if (tab.isDisposed()) return;
		auto shell = tabf.getShell();
		if (shell !is _comp.getShell()) { mixin(S_TRACE);
			shell.setText(tab.getText());
			shell.setImage(tab.getImage());
		}
		auto ctrl = tab.getControl();
		auto key = keyFromCtrl(ctrl);
		if (!key.length) return;
		if (_oldSel != key) { mixin(S_TRACE);
			_oldSel = key;
			foreach (ls; selectEvent) { mixin(S_TRACE);
				ls(_ctrls[ctrl]);
			}
		}
	}
	private TabF newSash(Composite targ, int style, bool before, int lWeight, int rWeight, string key) { mixin(S_TRACE);
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
		if (before) { mixin(S_TRACE);
			r = newTabf(nSash, key);
			targ.setParent(nSash);
		} else { mixin(S_TRACE);
			targ.setParent(nSash);
			r = newTabf(nSash, key);
		}
		nSash.setWeights([lWeight, rWeight]);
		return r;
	}

	private static class Tabf {
		string key;
		int select;
		Tabi[] tabs;
	}
	private static struct Tabi {
		string key;
		string name;
	}
	private static class Sashf {
		string key;
		bool vertical;
		int lWeight;
		int rWeight;
		Sashf lSash;
		Tabf lTabf;
		Sashf rSash;
		Tabf rTabf;
	}
	private static class Area {
		Sashf sash;
		Tabf tabf;
		SubWindow[] subShells;
	}
	private static struct SubWindow {
		Area area;
		int x;
		int y;
		int width;
		int height;
	}
	private Area _tree = null;
	private void saveTree() { mixin(S_TRACE);
		auto area = new Area;
		saveTree(_area.getChildren()[0], area.sash, area.tabf);
		assert ((area.sash || area.tabf) && !(area.sash && area.tabf), "dockingfolder#saveTree 1");
		foreach (shell, subArea; _subAreas) {
			auto bounds = shell.getBounds();
			auto sub = new Area;
			saveTree(subArea.getChildren()[0], sub.sash, sub.tabf);
			auto parPos = _comp.getShell().getLocation();
			area.subShells ~= SubWindow(sub, bounds.x - parPos.x, bounds.y - parPos.y, bounds.width, bounds.height);
		}
		_tree = area;
	}
	private void saveTree(Control c, out Sashf sa, out Tabf ta) { mixin(S_TRACE);
		auto sash = cast(SplitPane) c;
		if (sash) { mixin(S_TRACE);
			sa = new Sashf;
			ta = null;
			sa.key = _sashs[sash];
			sa.vertical = (sash.getStyle() & SWT.VERTICAL) != 0;
			auto weights = sash.getWeights();
			sa.lWeight = weights[0];
			sa.rWeight = weights[1];
			bool left = true;
			assert (sash.getChildren().length == 3, "dockingfolder#saveTree 2");
			foreach (child; sash.getChildren()) { mixin(S_TRACE);
				if (!(cast(Sash) child)) { mixin(S_TRACE);
					if (left) { mixin(S_TRACE);
						saveTree(child, sa.lSash, sa.lTabf);
						left = false;
					} else { mixin(S_TRACE);
						saveTree(child, sa.rSash, sa.rTabf);
						break;
					}
				}
			}
			assert ((sa.lSash || sa.lTabf) && !(sa.lSash && sa.lTabf), "dockingfolder#saveTree 3");
			assert ((sa.rSash || sa.rTabf) && !(sa.rSash && sa.rTabf), "dockingfolder#saveTree 4");
		} else { mixin(S_TRACE);
			ta = new Tabf;
			sa = null;
			auto tabf = cast(TabF) c;
			assert (tabf, "dockingfolder#saveTree 5");
			ta.key = _tabfs[tabf];
			ta.select = tabf.getSelectionIndex();
			ta.tabs.length = tabf.getItemCount();
			foreach (i, tab; tabf.getItems()) { mixin(S_TRACE);
				ta.tabs[i].key = _ctrls[tab.getControl()];
				ta.tabs[i].name = tab.getText();
			}
		}
	}

	/// XMLノードにして返す。dispose後も呼出し可能。
	/// excludeに含まれる文字列で開始されるタブは無視される。
	XNode toNode(string[] exclude = []) { mixin(S_TRACE);
		auto r = XNode.create("dockingFolder");
		toNodeImpl(r, exclude);
		return r;
	}
	/// ditto
	XNode toNode(ref XNode parent, string[] exclude = []) { mixin(S_TRACE);
		auto r = parent.newElement("dockingFolder");
		toNodeImpl(r, exclude);
		return r;
	}
	private void toNodeImpl(ref XNode r, string[] exclude) { mixin(S_TRACE);
		if (!_area.isDisposed()) { mixin(S_TRACE);
			saveTree();
		}

		if (_cMemories.length) { mixin(S_TRACE);
			auto ctrlM = r.newElement("controlMemories");
			foreach (key, memory; _cMemories) { mixin(S_TRACE);
				auto e = ctrlM.newElement("controlMemory", key);
				e.newAttr("pane", memory.pane);
				e.newAttr("pairPane", memory.pairPane);
				e.newAttr("dir", dirToString(memory.dir));
				e.newAttr("lWeight", memory.lWeight);
				e.newAttr("rWeight", memory.rWeight);
			}
		}
		if (_pMemories.length) { mixin(S_TRACE);
			auto paneM = r.newElement("paneMemories");
			foreach (key, memory; _pMemories) { mixin(S_TRACE);
				auto e = paneM.newElement("paneMemory", key);
				if (memory.isSubWindow) { mixin(S_TRACE);
					e.newAttr("subPaneKey", memory.subPaneKey);
					e.newAttr("x", memory.x);
					e.newAttr("y", memory.y);
					e.newAttr("width", memory.width);
					e.newAttr("height", memory.height);
				} else { mixin(S_TRACE);
					e.newAttr("pairPane", memory.pairPane);
					e.newAttr("dir", dirToString(memory.dir));
					e.newAttr("lWeight", memory.lWeight);
					e.newAttr("rWeight", memory.rWeight);
				}
			}
		}

		assert (_tree, "dockingfolder#toNodeImpl");
		if (_tree.sash) { mixin(S_TRACE);
			toNodeImpl(r, _tree.sash, exclude);
		} else { mixin(S_TRACE);
			toNodeImpl(r, _tree.tabf, exclude);
		}
		if (_tree.subShells.length) { mixin(S_TRACE);
			foreach (sub; _tree.subShells) { mixin(S_TRACE);
				auto e = r.newElement("subWindow");
				e.newAttr("x", sub.x);
				e.newAttr("y", sub.y);
				e.newAttr("width", sub.width);
				e.newAttr("height", sub.height);
				if (sub.area.sash) { mixin(S_TRACE);
					toNodeImpl(e, sub.area.sash, exclude);
				} else { mixin(S_TRACE);
					toNodeImpl(e, sub.area.tabf, exclude);
				}
			}
		}
	}
	private XNode toNodeImpl(ref XNode parent, Sashf sa, string[] exclude) { mixin(S_TRACE);
		auto r = parent.newElement("sash");
		r.newAttr("key", sa.key);
		r.newAttr("type", sa.vertical ? VERTICAL : HORIZONTAL);
		r.newAttr("lWeight", sa.lWeight);
		r.newAttr("rWeight", sa.rWeight);
		void n(Sashf sa, Tabf ta) { mixin(S_TRACE);
			if (sa) { mixin(S_TRACE);
				toNodeImpl(r, sa, exclude);
			} else { mixin(S_TRACE);
				toNodeImpl(r, ta, exclude);
			}
		}
		n(sa.lSash, sa.lTabf);
		n(sa.rSash, sa.rTabf);
		return r;
	}
	private XNode toNodeImpl(ref XNode parent, Tabf ta, string[] exclude) { mixin(S_TRACE);
		auto r = parent.newElement("tabs");
		if (ta.select >= 0) r.newAttr("select", ta.select);
		r.newAttr("key", ta.key);
		bool sc(string name) { mixin(S_TRACE);
			foreach (ex; exclude) { mixin(S_TRACE);
				if (std.string.startsWith(name, ex)) return true;
			}
			return false;
		}
		foreach (tab; ta.tabs) { mixin(S_TRACE);
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
		/// サブウィンドウ用パラメータ。
		int x = SWT.DEFAULT;
		int y = SWT.DEFAULT; /// ditto
		int width = SWT.DEFAULT; /// ditto
		int height = SWT.DEFAULT; /// ditto
		void delegate(Shell, Rectangle) addSubWindow = null; /// ditto
		Shell shell = null; /// ditto
		private void createSub() { mixin(S_TRACE);
			if (par) return;
			r.createSubWindow(shell, par);
			addSubWindow(shell, new Rectangle(x, y, width, height));
		}
		void sash(ref XNode node) { mixin(S_TRACE);
			createSub();
			string type = node.attr("type", true);
			auto key = node.attr("key", false, r.newSashKey);
			/// FIXME: たまに type == VERTICAL の所でアクセス違反が起きる？
			auto sash = new SplitPane(par, type == VERTICAL ? SWT.VERTICAL : SWT.HORIZONTAL);
			r.putSashTable(sash, key);
			Proc proc;
			proc.r = r;
			proc.par = sash;
			proc.create = create;
			proc.addRemoveList = addRemoveList;
			proc.shell = shell;
			node.onTag["sash"] = &proc.sash;
			node.onTag["tabs"] = &proc.tabs;
			node.parse();
			sash.setWeights([node.attr!(int)("lWeight", true), node.attr!(int)("rWeight", true)]);
		}
		void tabs(ref XNode node) { mixin(S_TRACE);
			createSub();
			auto key = node.attr("key", true);
			auto tabf = r.newTabf(par, key);
			node.onTag["tab"] = (ref XNode node) { mixin(S_TRACE);
				auto key = node.attr("key", true);
				auto v = create(tabf, key);
				if (v) { mixin(S_TRACE);
					auto name = node.attr("name", true);
					r.addImpl(v, name, null, key, false, NewCtrlLocation.Last, true);
					if (shell && shell.getText() == "") { mixin(S_TRACE);
						shell.setText(name);
					}
				}
			};
			node.parse();
			auto i = node.attr!(int)("select", false, -1);
			if (0 < tabf.getItemCount()) { mixin(S_TRACE);
				i = std.algorithm.max(i, 0);
				i = std.algorithm.min(i, tabf.getItemCount() - 1);
				tabf.setSelection(i);
			} else { mixin(S_TRACE);
				addRemoveList(key, tabf);
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
			void delegate(Composite, string) createPaneEvent = null) { mixin(S_TRACE);
		assert (node.name == "dockingFolder", "dockingfolder#fromNode");
		DockingFolder r = null;
		try { mixin(S_TRACE);
			r = new DockingFolder(parent, style, false);

			node.onTag["controlMemories"] = (ref XNode node) { mixin(S_TRACE);
				node.onTag["controlMemory"] = (ref XNode e) { mixin(S_TRACE);
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
			node.onTag["paneMemories"] = (ref XNode node) { mixin(S_TRACE);
				node.onTag["paneMemory"] = (ref XNode e) { mixin(S_TRACE);
					string key = e.value;
					PaneMemory memory;
					memory.pairPane = e.attr("pairPane", false);
					memory.isSubWindow = memory.pairPane == "";
					if (memory.isSubWindow) { mixin(S_TRACE);
						memory.subPaneKey = e.attr("subPaneKey", false, key);
						memory.x = e.attr!int("x", false, SWT.DEFAULT);
						memory.y = e.attr!int("y", false, SWT.DEFAULT);
						memory.width = e.attr!int("width", false, SWT.DEFAULT);
						memory.height = e.attr!int("height", false, SWT.DEFAULT);
					} else { mixin(S_TRACE);
						memory.dir = stringToDir(e.attr("dir", false));
						string lw = e.attr("lWeight", false);
						string rw = e.attr("rWeight", false);
						if (lw.length && isNumeric(lw)) memory.lWeight = .parse!int(lw);
						if (rw.length && isNumeric(rw)) memory.rWeight = .parse!int(rw);
					}
					r._pMemories[key] = memory;
				};
				node.parse();
			};

			if (createPaneEvent) r.createPaneEvent ~= createPaneEvent;
			TabF[] removeList;
			Shell[] subShells;
			Rectangle[] subShellRects;
			void addRemoveList(string key, TabF tabf) { mixin(S_TRACE);
				if (r.vanish(key) && (!canVanish || canVanish(r, key))) { mixin(S_TRACE);
					removeList ~= tabf;
				}
			}
			Proc proc;
			proc.r = r;
			proc.par = r._area;
			proc.create = create;
			proc.addRemoveList = &addRemoveList;
			node.onTag["sash"] = &proc.sash;
			node.onTag["tabs"] = &proc.tabs;
			node.onTag["subWindow"] = (ref XNode node) { mixin(S_TRACE);
				Proc proc;
				proc.r = r;
				proc.par = null;
				proc.create = create;
				proc.addRemoveList = &addRemoveList;
				proc.x = node.attr!int("x", false, SWT.DEFAULT);
				proc.y = node.attr!int("y", false, SWT.DEFAULT);
				proc.width = node.attr!int("width", false, SWT.DEFAULT);
				proc.height = node.attr!int("height", false, SWT.DEFAULT);
				proc.addSubWindow = (Shell shell, Rectangle rect) { mixin(S_TRACE);
					subShells ~= shell;
					subShellRects ~= rect;
				};
				node.onTag["sash"] = &proc.sash;
				node.onTag["tabs"] = &proc.tabs;
				node.parse();
			};
			node.parse();
			foreach (tabf; removeList) { mixin(S_TRACE);
				r.removeTabf(tabf, true);
			}
			r._comp.getShell().addShellListener(new class ShellAdapter {
				override void shellActivated(ShellEvent e) { mixin(S_TRACE);
					r._comp.getShell().removeShellListener(this);
					foreach (i, shell; subShells) { mixin(S_TRACE);
						if (!shell.isDisposed()) { mixin(S_TRACE);
							auto parPos = r._comp.getShell().getLocation();
							auto b = subShellRects[i];
							b.x += parPos.x;
							b.y += parPos.y;
							intoDisplay(b.x, b.y, b.width, b.height);
							shell.setBounds(b);
							if (r.getTabs(r._subAreas[shell]).length) { mixin(S_TRACE);
								r.updateSubShellTitle(shell);
								shell.setVisible(true);
							}
						}
					}
				}
			});
			return r;
		} catch (Throwable e) {
			printStackTrace();
			debugln(e);
			if (r && r.area) { mixin(S_TRACE);
				r._canSave = false;
				r.area.dispose();
			}
			throw e;
		}
	}
}
