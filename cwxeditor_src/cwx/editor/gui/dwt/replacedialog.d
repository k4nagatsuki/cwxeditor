
module cwx.editor.gui.dwt.replacedialog;

import cwx.area;
import cwx.summary;
import cwx.event;
import cwx.coupon;
import cwx.utils;
import cwx.card;
import cwx.motion;
import cwx.flag;
import cwx.usecounter;
import cwx.types;
import cwx.path;
import cwx.background;
import cwx.skin;
import cwx.msgutils;
import cwx.flag;
import cwx.menu;
import cwx.jpy;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;

import std.conv;
import std.array;
import std.string;
import std.file;
import std.path;
import std.regex : Regex, regex, RegexMatch, match;
import std.utf;
import std.algorithm : uniq;

import org.eclipse.swt.all;

import java.lang.all;

private class CWXPathString {
	CWXPath path;
	string array;
	this (CWXPath path, string array) {
		this.path = path;
		this.array = array;
	}
}

/// 検索と置換を行うダイアログ。
class ReplaceDialog {
private:
	class RUndo : Undo {
		private CWXPath _path = null;
		private string _filePath = null;
		private Undo[] _uArr;
		this (CWXPath path, Undo[] uArr) {
			_path = path;
			_uArr = uArr;
		}
		this (string filePath, Undo[] uArr) {
			_filePath = filePath;
			_uArr = uArr;
		}
		void undo() {
			foreach_reverse (u; _uArr) u.undo();
			if (_path) addResult(_path);
			if (_filePath) addResult(_filePath);
		}
		void redo() {
			foreach_reverse (u; _uArr) u.redo();
			if (_path) addResult(_path);
			if (_filePath) addResult(_filePath);
		}
		void dispose() {
			foreach (u; _uArr) u.dispose();
		}
	}

	void store(string filePath, Undo[] uArr) {
		_rUndo ~= new RUndo(filePath, uArr);
	}
	void store(CWXPath path, Undo[] uArr) {
		_rUndo ~= new RUndo(path, uArr);
	}
	void store(CWXPath path, string o, string n, void delegate(string) set) {
		_rUndo ~= new RUndo(path, [new StrUndo(o, n, set)]);
	}
	void store(CWXPath path, string[] o, string[] n, void delegate(string[]) set) {
		_rUndo ~= new RUndo(path, [new StrArrUndo(o, n, set)]);
	}
	void storeID(User, Id)(CWXPath path, User u, Id from, Id to, void delegate(Id) set) {
		_rUndo ~= new RUndo(path, [new TUndo!Id(from, to, set)]);
	}

	bool _inProc = false;
	Undo[] _rUndo;
	void delegate()[] _after;

	Commons _comm;
	Props _prop;
	Summary _summ;
	UndoManager _undo;

	Shell _win;
	Composite _parent;
	CTabFolder _tabf;
	CTabItem _tabText;
	CTabItem _tabID;
	CTabItem _tabPath;
	CTabItem _tabContents;
	CTabItem _tabCoupon;
	CTabItem _tabUnuse;
	CTabItem _tabError;
	Button _find;
	Button _replace;
	Button _rangeAllCheck;

	bool ignoreMod = false;

	Combo _from;
	Combo _to;
	Combo _idKind;
	Combo _fromID;
	Spinner _fromIDVal;
	ulong[int] _fromIDTbl;
	Combo _toID;
	Spinner _toIDVal;
	ulong[int] _toIDTbl;
	Combo _fromPath;
	Combo _toPath;

	Button _notIgnoreCase;
	Button _useRegex;
	Button _useWildcard;
	class SelRegex : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			if (_useRegex.getSelection()) {
				_useWildcard.setSelection(false);
			}
		}
	}
	class SelWildcard : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			if (_useWildcard.getSelection()) {
				_useRegex.setSelection(false);
			}
		}
	}
	@property
	const
	bool catchMod() {return !ignoreMod;}

	/// 貼り紙
	Button _summary;
	/// シナリオ出現条件
	Button _rCoupon;
	/// メッセージ
	Button _msg;
	/// カード名
	Button _cardName;
	/// カード解説
	Button _cardDesc;
	/// イベントテキスト
	Button _event;
	/// スタート名
	Button _start;
	/// フラグ/ステップ
	Button _flag;
	/// クーポン
	Button _coupon;
	/// ゴシップ
	Button _gossip;
	/// 終了印
	Button _end;
	/// エリア/バトル/パッケージ名
	Button _area;
	/// キーコード
	Button _keyCode;
	/// ファイル
	Button _file;
	/// コメント
	Button _comment;
	/// JPTXファイル
	Button _jptx;

	Button _unuseFlag;
	Button _unuseStep;
	Button _unuseArea;
	Button _unuseBattle;
	Button _unusePackage;
	Button _unuseCast;
	Button _unuseSkill;
	Button _unuseItem;
	Button _unuseBeast;
	Button _unuseInfo;
	Button _unuseStart;
	Button _unusePath;

	Button _cCoupon;
	Button _cGossip;
	Button _cEnd;
	Button _cKeyCode;

	Table _result;
	Tree _range;

	Composite[CTabItem] _comps;

	ToolItem[CType] _contents;

	Label _status;

	class ML : MouseAdapter {
		public override void mouseDoubleClick(MouseEvent e) {
			if (_result.isFocusControl() && e.button == 1) {
				openPath();
			}
		}
	}
	class KL : KeyAdapter {
		public override void keyPressed(KeyEvent e) {
			if (_result.isFocusControl() && e.character == SWT.CR) {
				openPath();
			}
		}
	}
	static const ID_AREA = 0;
	static const ID_BATTLE = 1;
	static const ID_PACKAGE = 2;
	static const ID_CAST = 3;
	static const ID_SKILL = 4;
	static const ID_ITEM = 5;
	static const ID_BEAST = 6;
	static const ID_INFO = 7;
	private void setupIDsImpl2(T)(T[] arr, Combo combo, Spinner spn, ref ulong[int] tbl) {
		ulong[int] tbl2;
		string oldSel = combo.getText();
		combo.removeAll();
		combo.add(_prop.msgs.replSetID);
		foreach (i, a; arr) {
			combo.add(to!(string)(a.id) ~ "." ~ a.name);
			tbl2[i + 1] = a.id;
		}
		combo.select(arr.length ? 1 : 0);
		if (oldSel) {
			auto i = combo.indexOf(oldSel);
			if (i >= 0) combo.select(i);
		}
		spn.setEnabled(combo.getSelectionIndex() == 0);
		tbl = tbl2;
	}
	private void setupIDsImpl1(T)(T[] arr) {
		setupIDsImpl2(arr, _fromID, _fromIDVal, _fromIDTbl);
		setupIDsImpl2(arr, _toID, _toIDVal, _toIDTbl);
	}
	private void setupIDs() {
		switch (_idKind.getSelectionIndex()) {
		case ID_AREA: setupIDsImpl1(_summ.areas); break;
		case ID_BATTLE: setupIDsImpl1(_summ.battles); break;
		case ID_PACKAGE: setupIDsImpl1(_summ.packages); break;
		case ID_CAST: setupIDsImpl1(_summ.casts); break;
		case ID_SKILL: setupIDsImpl1(_summ.skills); break;
		case ID_ITEM: setupIDsImpl1(_summ.items); break;
		case ID_BEAST: setupIDsImpl1(_summ.beasts); break;
		case ID_INFO: setupIDsImpl1(_summ.infos); break;
		default: assert (0);
		}
	}
	private string[] allMaterials(bool scenarioOnly) {
		auto sPath = nabs(_summ.scenarioPath);
		auto tbl = new HashSet!(PathId);
		string[] paths;
		void find(string p) {
			if (_summ.isSystemFile(p)
					|| containsPath(_prop.var.etc.ignorePaths, baseName(p))) {
				return;
			}
			if (.isDir(p)) {
				string[] list = clistdir(p);
				if (_prop.var.etc.logicalSort) {
					list = sort!(fnncmp)(list);
				} else {
					list = sort!(fncmp)(list);
				}
				foreach (l; list) {
					find(std.path.buildPath(p, l));
				}
			} else if (_comm.skin.isMaterial(p)) {
				auto path = relativePath(p, sPath);
				paths ~= encodePath(path);
				tbl.add(toPathId(path));
			}
		}
		find(sPath);
		if (!scenarioOnly) {
			auto skin = _comm.skin;
			foreach (p; skin.tables(_prop.var.etc.logicalSort)) {
				tbl.add(toPathId(p));
				paths ~= encodePath(p);
			}
			foreach (p; skin.musics(_prop.var.etc.logicalSort)) {
				tbl.add(toPathId(p));
				paths ~= encodePath(p);
			}
			foreach (p; skin.sounds(_prop.var.etc.logicalSort)) {
				tbl.add(toPathId(p));
				paths ~= encodePath(p);
			}
			foreach (path; _summ.useCounter.path.keys) {
				auto p = cast(string) path;
				if (!path.isBinImg && !tbl.contains(path)) {
					paths ~= encodePath(p);
				}
			}
		}
		return paths;
	}
	private void setupPaths() {
		bool oldIgnoreMod = ignoreMod;
		ignoreMod = true;
		scope (exit) ignoreMod = oldIgnoreMod;

		string[] paths = [""] ~ allMaterials(false);
		void setPaths(Combo combo) {
			auto old = combo.getText();
			setComboItems(combo, paths);
			combo.setText(old);
		}
		setPaths(_fromPath);
		setPaths(_toPath);
	}
	class SListener : ShellAdapter {
		override void shellActivated(ShellEvent e) {
			setupIDs();
			setupPaths();
			_comm.refreshToolBar();
		}
	}
	class SelID : SelectionAdapter {
		private Spinner _spn;
		this (Spinner spn) {_spn = spn;}
		override void widgetSelected(SelectionEvent e) {
			auto combo = cast(Combo) e.widget;
			_spn.setEnabled(combo.getSelectionIndex() == 0);
			_comm.refreshToolBar();
		}
	}
	class SelIDKind : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			setupIDs();
			_prop.var.etc.searchIDKind = _idKind.getSelectionIndex();
			_comm.refreshToolBar();
		}
	}
	private void tabChanged() {
		auto sel = _tabf.getSelection();
		if (!sel) return;
		_prop.var.etc.searchPlan = _tabf.getSelectionIndex();
		foreach (tab, comp; _comps) {
			auto gd = cast(GridData) comp.getLayoutData();
			if (tab is sel) {
				gd.heightHint= SWT.DEFAULT;
			} else {
				gd.heightHint= 0;
			}
		}
		_parent.layout(true);
		_replace.setEnabled(sel !is _tabContents && sel !is _tabCoupon && sel !is _tabUnuse && sel !is _tabError);
		_range.setEnabled(sel !is _tabUnuse);
		_rangeAllCheck.setEnabled(_range.getEnabled());
		_comm.refreshToolBar();
	}
	class TSListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			tabChanged();
		}
	}
	LCheck[] _checked;
	class LCheck : SelectionAdapter {
		Widget[] buttons;
		private Button _all = null;
		private void setSelection(Widget b, bool s) {
			auto button = cast(Button) b;
			if (button) button.setSelection(s);
			auto ti = cast(ToolItem) b;
			if (ti) ti.setSelection(s);
		}
		private bool getSelection(Widget b) {
			auto button = cast(Button) b;
			if (button) return button.getSelection();
			auto ti = cast(ToolItem) b;
			if (ti) return ti.getSelection();
			assert (0);
		}
		class AllCheck : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) {
				foreach (b; buttons) {
					setSelection(b, _all.getSelection());
				}
			}
		}
		void check() {
			bool checked = true;
			foreach (b; buttons) {
				checked &= getSelection(b);
			}
			_all.setSelection(checked);
		}
		override void widgetSelected(SelectionEvent e) {
			assert (_all);
			check();
		}
		void createAlls(Composite parent, string text) {
			_all = new Button(parent, SWT.CHECK);
			_all.setText(text);
			_all.addSelectionListener(new AllCheck);
			check();
		}
	}
	Composite addButtonLine(Composite grp) {
		auto comp = new Composite(grp, SWT.NONE);
		comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		auto rl = new RowLayout(SWT.HORIZONTAL);
		rl.wrap = true;
		rl.pack = false;
		comp.setLayout(rl);
		return comp;
	}
	void constructText(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		auto comp2gl = windowGridLayout(1, true);
		comp2gl.marginWidth = 0;
		comp2gl.marginHeight = 0;
		comp2.setLayout(comp2gl);
		{
			auto grp = new Group(comp2, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setText(_prop.msgs.replText);
			grp.setLayout(new GridLayout(2, false));
			auto lf = new Label(grp, SWT.NONE);
			lf.setText(_prop.msgs.replFrom);
			_from = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN);
			_from.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			createTextMenu!Combo(_comm, _prop, _from, &catchMod);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_from.setLayoutData(gd);
			auto lt = new Label(grp, SWT.NONE);
			lt.setText(_prop.msgs.replTo);
			_to = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN);
			_to.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			createTextMenu!Combo(_comm, _prop, _to, &catchMod);
			_to.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}
		{
			auto grp = new Group(comp2, SWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			grp.setLayoutData(gd);
			grp.setText(_prop.msgs.replCond);
			grp.setLayout(new GridLayout(1, true));
			_notIgnoreCase = new Button(grp, SWT.CHECK);
			_notIgnoreCase.setText(_prop.msgs.replNotIgnoreCase);
			_useWildcard = new Button(grp, SWT.CHECK);
			_useWildcard.setText(_prop.msgs.replWildcard);
			_useWildcard.addSelectionListener(new SelWildcard);
			_useRegex = new Button(grp, SWT.CHECK);
			_useRegex.setText(_prop.msgs.replRegExp);
			_useRegex.addSelectionListener(new SelRegex);
		}
		{
			auto grp = new Group(comp2, SWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			grp.setLayoutData(gd);
			grp.setText(_prop.msgs.replTextTarget);
			grp.setLayout(zeroGridLayout(1, true));
			auto checked = new LCheck;
			_checked ~= checked;
			{
				auto btns = addButtonLine(grp);
				Button createB(string text, char accr) {
					auto b = new Button(btns, SWT.CHECK);
					b.setText(text ~ "(&" ~ accr ~ ")");
					checked.buttons ~= b;
					b.addSelectionListener(checked);
					return b;
				}
				_summary = createB(_prop.msgs.replTextSummary, '1');
				_msg = createB(_prop.msgs.replTextMessage, '2');
				_cardName = createB(_prop.msgs.replTextCardName, '3');
				_cardDesc = createB(_prop.msgs.replTextCardDesc, '4');
				_event = createB(_prop.msgs.replTextEventText, '5');
				_start = createB(_prop.msgs.replTextStart, '6');
				_flag = createB(_prop.msgs.replTextFlagAndStep, '7');
				_coupon = createB(_prop.msgs.replTextCoupon, '8');
				_gossip = createB(_prop.msgs.replTextGossip, '9');
				_end = createB(_prop.msgs.replTextEndScenario, 'A');
				_area = createB(_prop.msgs.replTextAreaName, 'B');
				_keyCode = createB(_prop.msgs.replTextKeyCode, 'D');
				_file = createB(_prop.msgs.replTextFile, 'E');
				_comment = createB(_prop.msgs.replTextComment, 'G');
				_jptx = createB(_prop.msgs.replTextJptx, 'H');
			}
			auto sep = new Label(grp, SWT.SEPARATOR | SWT.HORIZONTAL);
			sep.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			{
				auto btns = addButtonLine(grp);
				checked.createAlls(btns, _prop.msgs.allCheck);
			}
		}

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.replForText);
		tab.setControl(comp);
		_tabText = tab;

		auto gd = new GridData(GridData.FILL_BOTH);
		comp2.setLayoutData(gd);
		_comps[tab] = comp2;
	}
	void constructID(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout(zeroGridLayout(1, true));
		{
			auto grp = new Group(comp2, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setText(_prop.msgs.replID);
			grp.setLayout(new GridLayout(3, false));
			{
				auto l = new Label(grp, SWT.NONE);
				l.setText(_prop.msgs.replIDKind);
				_idKind = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				_idKind.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				_idKind.add(_prop.msgs.replIDArea);
				_idKind.add(_prop.msgs.replIDBattle);
				_idKind.add(_prop.msgs.replIDPackage);
				_idKind.add(_prop.msgs.replIDCast);
				_idKind.add(_prop.msgs.replIDSkill);
				_idKind.add(_prop.msgs.replIDItem);
				_idKind.add(_prop.msgs.replIDBeast);
				_idKind.add(_prop.msgs.replIDInfo);
				_idKind.select(0);
				if (0 <= _prop.var.etc.searchIDKind && _prop.var.etc.searchIDKind < _idKind.getItemCount()) {
					_idKind.select(_prop.var.etc.searchIDKind);
				}
				auto gd = new GridData;
				gd.horizontalSpan = 2;
				_idKind.setLayoutData(gd);
				_idKind.addSelectionListener(new SelIDKind);
			}
			{
				auto sep = new Label(grp, SWT.SEPARATOR | SWT.HORIZONTAL);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 3;
				sep.setLayoutData(gd);
			}
			void setupID(string text, ref Combo combo, ref Spinner spn) {
				auto l = new Label(grp, SWT.NONE);
				l.setText(text);
				combo = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				combo.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = _prop.var.etc.nameWidth;
				combo.setLayoutData(gd);
				spn = new Spinner(grp, SWT.BORDER);
				spn.setMinimum(1);
				spn.setMaximum(_prop.looks.idMax);
				combo.addSelectionListener(new SelID(spn));
			}
			setupID(_prop.msgs.replFrom, _fromID, _fromIDVal);
			setupID(_prop.msgs.replTo, _toID, _toIDVal);
		}

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.replForID);
		tab.setControl(comp);
		_tabID = tab;

		auto gd = new GridData(GridData.FILL_BOTH);
		gd.heightHint = 0;
		comp2.setLayoutData(gd);
		_comps[tab] = comp2;
	}
	void constructPath(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout(zeroGridLayout(1, true));
		{
			auto grp = new Group(comp2, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setText(_prop.msgs.replPath);
			grp.setLayout(new GridLayout(2, false));
			Combo setupPath(string text) {
				auto l = new Label(grp, SWT.NONE);
				l.setText(text);
				auto combo = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN);
				combo.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				createTextMenu!Combo(_comm, _prop, combo, &catchMod);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = _prop.var.etc.nameWidth;
				combo.setLayoutData(gd);
				return combo;
			}
			_fromPath = setupPath(_prop.msgs.replFrom);
			_toPath = setupPath(_prop.msgs.replTo);
		}

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.replForPath);
		tab.setControl(comp);
		_tabPath = tab;

		auto gd = new GridData(GridData.FILL_BOTH);
		gd.heightHint = 0;
		comp2.setLayoutData(gd);
		_comps[tab] = comp2;
	}
	void constructContents(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout(zeroGridLayout(1, true));
		{
			auto grp = new Group(comp2, SWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			grp.setLayoutData(gd);
			grp.setText(_prop.msgs.searchRange);
			grp.setLayout(zeroGridLayout(1, true));
			auto checked = new LCheck;
			_checked ~= checked;

			auto comp3 = new Composite(grp, SWT.NONE);
			comp3.setLayoutData(new GridData(GridData.FILL_BOTH));
			comp3.setLayout(windowGridLayout(1, true));
			auto bar = new ToolBar(comp3, SWT.HORIZONTAL | SWT.FLAT | SWT.WRAP);
			_comm.put(bar);
			bar.setLayoutData(new GridData(GridData.FILL_BOTH));
			foreach (cGrp, cs; CTYPE_GROUP) {
				foreach (cType; cs) {
					auto text = _prop.msgs.contentName(cType);
					auto img = _prop.images.content(cType);
					void delegate() func = null;
					auto ti = createToolItem2(_comm, bar, text, img, func, null, SWT.CHECK);
					_contents[cType] = ti;
					checked.buttons ~= ti;
					ti.addSelectionListener(checked);
				}
				if (cGrp < CTypeGroup.max) {
					new ToolItem(bar, SWT.SEPARATOR);
				}
			}
			auto sep = new Label(grp, SWT.SEPARATOR | SWT.HORIZONTAL);
			sep.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

			auto btns = addButtonLine(grp);
			checked.createAlls(btns, _prop.msgs.allSelect);
		}

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.replContents);
		tab.setControl(comp);
		_tabContents = tab;

		auto gd = new GridData(GridData.FILL_BOTH);
		gd.heightHint = 0;
		comp2.setLayoutData(gd);
		_comps[tab] = comp2;
	}
	void constructCoupon(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		auto comp2gl = windowGridLayout(1, true);
		comp2gl.marginWidth = 0;
		comp2gl.marginHeight = 0;
		comp2.setLayout(comp2gl);
		{
			auto grp = new Group(comp2, SWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			grp.setLayoutData(gd);
			grp.setText(_prop.msgs.searchRange);
			grp.setLayout(zeroGridLayout(1, true));
			auto checked = new LCheck;
			_checked ~= checked;
			{
				auto btns = addButtonLine(grp);
				Button createB(string text, char accr) {
					auto b = new Button(btns, SWT.CHECK);
					b.setText(text ~ "(&" ~ accr ~ ")");
					checked.buttons ~= b;
					b.addSelectionListener(checked);
					return b;
				}
				_cCoupon = createB(_prop.msgs.replTextCoupon, '1');
				_cGossip = createB(_prop.msgs.replTextGossip, '2');
				_cEnd = createB(_prop.msgs.replTextEndScenario, '3');
				_cKeyCode = createB(_prop.msgs.replTextKeyCode, '4');
			}
			auto sep = new Label(grp, SWT.SEPARATOR | SWT.HORIZONTAL);
			sep.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			{
				auto btns = addButtonLine(grp);
				checked.createAlls(btns, _prop.msgs.allCheck);
			}
		}

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.replForCoupon);
		tab.setControl(comp);
		_tabCoupon = tab;

		auto gd = new GridData(GridData.FILL_BOTH);
		comp2.setLayoutData(gd);
		_comps[tab] = comp2;
	}
	void constructUnuse(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout(zeroGridLayout(1, true));
		{
			auto grp = new Group(comp2, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setText(_prop.msgs.replUnuseTarget);
			grp.setLayout(zeroGridLayout(1, true));
			auto checked = new LCheck;
			_checked ~= checked;
			{
				auto btns = addButtonLine(grp);
				Button createB(string text, char accr) {
					auto b = new Button(btns, SWT.CHECK);
					b.setText(text ~ "(&" ~ accr ~ ")");
					checked.buttons ~= b;
					b.addSelectionListener(checked);
					return b;
				}
				_unuseFlag = createB(_prop.msgs.replUnuseFlag, '1');
				_unuseStep = createB(_prop.msgs.replUnuseStep, '2');
				_unuseArea = createB(_prop.msgs.replUnuseArea, '3');
				_unuseBattle = createB(_prop.msgs.replUnuseBattle, '4');
				_unusePackage = createB(_prop.msgs.replUnusePackage, '5');
				_unuseCast = createB(_prop.msgs.replUnuseCast, '6');
				_unuseSkill = createB(_prop.msgs.replUnuseSkill, '7');
				_unuseItem = createB(_prop.msgs.replUnuseItem, '8');
				_unuseBeast = createB(_prop.msgs.replUnuseBeast, '9');
				_unuseInfo = createB(_prop.msgs.replUnuseInfo, 'A');
				_unuseStart = createB(_prop.msgs.replUnuseStart, 'B');
				_unusePath = createB(_prop.msgs.replUnusePath, 'C');
			}
			auto sep = new Label(grp, SWT.SEPARATOR | SWT.HORIZONTAL);
			sep.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			{
				auto btns = addButtonLine(grp);
				checked.createAlls(btns, _prop.msgs.allCheck);
			}
		}

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.replForUnuse);
		tab.setControl(comp);
		_tabUnuse = tab;

		auto gd = new GridData(GridData.FILL_BOTH);
		gd.heightHint = 0;
		comp2.setLayoutData(gd);
		_comps[tab] = comp2;
	}
	void constructError(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout(zeroGridLayout(1, true));
		{
			auto l = new Label(comp2, SWT.WRAP);
			l.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			l.setText(_prop.msgs.replError);
		}

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.replForError);
		tab.setControl(comp);
		_tabError = tab;

		auto gd = new GridData(GridData.FILL_BOTH);
		gd.heightHint = 0;
		comp2.setLayoutData(gd);
		_comps[tab] = comp2;
	}

	void refFunc(bool Del, A : CWXPath)(A a) {
		bool recurse(TreeItem itm) {
			if (a is itm.getData()) {
				static if (Del) {
					itm.dispose();
				} else {
					itm.setText(a.name);
				}
				return true;
			} else {
				foreach (child; itm.getItems()) {
					if (recurse(child)) {
						return true;
					}
				}
				return false;
			}
		}
		foreach (child; _range.getItems()) {
			if (recurse(child)) {
				return;
			}
		}
		static if (!Del) {
			// 追加
			refreshRangeTree();
		}
	}
	void delArea(Area a) {
		refFunc!true(a);
	}
	void delBattle(Battle a) {
		refFunc!true(a);
	}
	void delPackage(Package a) {
		refFunc!true(a);
	}
	void delCast(CastCard a) {
		refFunc!true(a);
	}
	void delSkill(SkillCard a) {
		refFunc!true(a);
	}
	void delItem(ItemCard a) {
		refFunc!true(a);
	}
	void delBeast(BeastCard a) {
		refFunc!true(a);
	}
	void delInfo(InfoCard a) {
		refFunc!true(a);
	}
	void refArea(Area a) {
		refFunc!false(a);
	}
	void refBattle(Battle a) {
		refFunc!false(a);
	}
	void refPackage(Package a) {
		refFunc!false(a);
	}
	void refCast(CastCard a) {
		refFunc!false(a);
	}
	void refSkill(SkillCard a) {
		refFunc!false(a);
	}
	void refItem(ItemCard a) {
		refFunc!false(a);
	}
	void refBeast(BeastCard a) {
		refFunc!false(a);
	}
	void refInfo(InfoCard a) {
		refFunc!false(a);
	}
	void refreshRangeTree() {
		CWXPath sel = null;
		auto selItm = _range.getSelection();
		if (selItm.length) {
			sel = cast(CWXPath) selItm[0].getData();
		}
		_range.removeAll();
		TreeItem add(TreeItem par, string name, CWXPath path) {
			TreeItem itm;
			if (par) {
				itm = new TreeItem(par, SWT.NONE);
			} else {
				itm = new TreeItem(_range, SWT.NONE);
			}
			string text;
			Image img;
			getPathParams(path, text, img);
			itm.setText(name);
			itm.setImage(img);
			itm.setData(cast(Object) path);
			itm.setChecked(true);
			if (sel is path) {
				_range.setSelection([itm]);
			}
			return itm;
		}
		add(null, _prop.msgs.summary, _summ);
		add(null, _prop.msgs.flagsAndSteps, _summ.flagDirRoot);
		foreach (a; _summ.areas) {
			add(null, a.name, a);
		}
		foreach (a; _summ.battles) {
			add(null, a.name, a);
		}
		foreach (a; _summ.packages) {
			add(null, a.name, a);
		}
		foreach (a; _summ.casts) {
			auto par = add(null, a.name, a);
			foreach (c; a.skills) {
				if (0 != c.linkId) continue;
				add(par, c.name, c);
			}
			foreach (c; a.items) {
				if (0 != c.linkId) continue;
				add(par, c.name, c);
			}
			foreach (c; a.beasts) {
				if (0 != c.linkId) continue;
				add(par, c.name, c);
			}
			par.setExpanded(true);
		}
		foreach (a; _summ.skills) {
			add(null, a.name, a);
		}
		foreach (a; _summ.items) {
			add(null, a.name, a);
		}
		foreach (a; _summ.beasts) {
			add(null, a.name, a);
		}
		foreach (a; _summ.infos) {
			add(null, a.name, a);
		}
		_range.showSelection();
		_comm.refreshToolBar();
	}
	void refreshRangeAllCheck() {
		bool recurse(TreeItem itm) {
			if (!itm.getChecked()) {
				return true;
			} else {
				foreach (child; itm.getItems()) {
					if (recurse(child)) {
						return true;
					}
				}
				return false;
			}
		}
		foreach (child; _range.getItems()) {
			if (recurse(child)) {
				_rangeAllCheck.setSelection(false);
				return;
			}
		}
		_rangeAllCheck.setSelection(true);
	}
	class RefRangeAllCheck : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			if (SWT.CHECK != e.detail) return;
			refreshRangeAllCheck();
		}
	}
	class RangeAllCheck : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			void recurse(TreeItem itm) {
				itm.setChecked(_rangeAllCheck.getSelection());
				foreach (child; itm.getItems()) {
					recurse(child);
				}
			}
			foreach (child; _range.getItems()) {
				recurse(child);
			}
		}
	}
	void refUndoMax() {
		_undo.max = _prop.var.etc.undoMaxReplace;
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ) {
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_undo = new UndoManager(_prop.var.etc.undoMaxReplace);
		_win = new Shell(shell, SWT.SHELL_TRIM);
		if (shell) {
			_win.setImeInputMode(shell.getImeInputMode());
		}
		_win.setText(_prop.msgs.dlgTitReplaceText);
		_win.setImage(prop.images.menu(MenuID.Find));
		setup();
		_win.open();
		_win.setActive();
	}
	@property
	Shell widget() {
		return _win;
	}
	@property
	void summary(Summary summ) {
		if (_win.isDisposed()) return;
		if (!summ) {
			_win.close();
		} else {
			_summ = summ;
			reset();
			refreshRangeTree();
		}
		_undo.reset();
		_comm.refreshToolBar();
	}

	void open() {
		reset();
		tabChanged();
		auto tab = _tabf.getSelection();
		if (tab is _tabText) {
			_from.setFocus();
		} else if (tab is _tabID) {
			_idKind.setFocus();
		} else if (tab is _tabPath) {
			_fromPath.setFocus();
		} else if (tab is _tabContents) {
			// Nothing
		} else if (tab is _tabCoupon) {
			// Nothing
		} else if (tab is _tabUnuse) {
			// Nothing
		} else if (tab is _tabError) {
			// Nothing
		} else assert (0);
	}
	void replaceText(string from, bool start = false) {
		reset();
		_from.setText(from);
		_to.setText("");
		_tabf.setSelection(_tabText);
		tabChanged();
		_from.setFocus();
		if (start) {
			search();
		}
	}
	void replacePath(string from) {
		reset();
		_fromPath.setText(from);
		_toPath.setText("");
		_tabf.setSelection(_tabPath);
		tabChanged();
		_fromPath.setFocus();
	}

	private void openRangePath() {
		auto sels = _range.getSelection();
		if (!sels.length) return;
		string path = (cast(CWXPath) sels[0].getData()).cwxPath(true);
		path = cpaddattr(path, "shallow");
		auto r = _comm.openCWXPath(path, false);
		if (!r) {
			MessageBox.showWarning(.tryFormat(_prop.msgs.cwxPathOpenError, path), _prop.msgs.dlgTitWarning, _win);
		}
	}
	private class OpenPath : MouseAdapter, KeyListener {
		override void mouseDoubleClick(MouseEvent e) {
			if (1 == e.button) {
				openRangePath();
			}
		}
		override void keyReleased(KeyEvent e) {}
		override void keyPressed(KeyEvent e) {
			if (SWT.CR == e.character) openRangePath();
		}
	}
	private void setup() {
		_win.addShellListener(new SListener);
		_win.setLayout(zeroGridLayout(1, true));
		auto area = new Composite(_win, SWT.NONE);
		area.setLayoutData(new GridData(GridData.FILL_BOTH));
		area.setLayout(windowGridLayout(2, false));

		auto sash = new SplitPane(area, SWT.HORIZONTAL);
		sash.setLayoutData(new GridData(GridData.FILL_BOTH));

		auto left = new Composite(sash, SWT.NONE);
		left.setLayout(windowGridLayout(1, true));
		_parent = left;
		auto right = new Composite(sash, SWT.NONE);
		right.setLayout(windowGridLayout(1, true));

		_tabf = new CTabFolder(left, SWT.BORDER);
		{
			_tabf.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			constructText(_tabf);
			constructID(_tabf);
			constructPath(_tabf);
			constructContents(_tabf);
			constructCoupon(_tabf);
			constructUnuse(_tabf);
			constructError(_tabf);
			_tabf.addSelectionListener(new TSListener);
		}
		{
			_result = new Table(left, SWT.BORDER | SWT.MULTI | SWT.FULL_SELECTION | SWT.V_SCROLL | SWT.VIRTUAL);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			gd.heightHint = _prop.var.etc.searchResultTableHeight;
			_result.setLayoutData(gd);
			_result.addMouseListener(new ML);
			_result.addKeyListener(new KL);
			new FullTableColumn(_result, SWT.NONE);
			auto menu = new Menu(_win, SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.Undo, &undo, &_undo.canUndo);
			createMenuItem(_comm, menu, MenuID.Redo, &redo, &_undo.canRedo);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.CopyAsText, &copyResult, () => _result.getSelectionIndex() != -1);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.SelectAll, &_result.selectAll, () => _result.getItemCount() > 0);
			new MenuItem(menu, SWT.SEPARATOR);
			createMenuItem(_comm, menu, MenuID.OpenAtView, &openPath, &canOpenPath);
			_result.setMenu(menu);
		}
		{
			auto openDlg = new Button(left, SWT.CHECK);
			openDlg.setText(_prop.msgs.searchOpenDialog);
			openDlg.setSelection(_prop.var.etc.searchOpenDialog);
			openDlg.addSelectionListener(new class SelectionAdapter {
				override void widgetSelected(SelectionEvent e) {
					_prop.var.etc.searchOpenDialog = openDlg.getSelection();
				}
			});
			openDlg.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
		}
		{
			auto grp = new Group(right, SWT.NONE);
			grp.setText(_prop.msgs.searchRange);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(1, true));
			_range = new Tree(grp, SWT.SINGLE | SWT.BORDER | SWT.VIRTUAL | SWT.CHECK);
			initTree(_range, false);
			_range.addSelectionListener(new RefRangeAllCheck);
			_range.setLayoutData(new GridData(GridData.FILL_BOTH));
			refreshRangeTree();
			_rangeAllCheck = new Button(grp, SWT.CHECK);
			_rangeAllCheck.setText(_prop.msgs.allCheckRange);
			refreshRangeAllCheck();
			_rangeAllCheck.addSelectionListener(new RangeAllCheck);
			auto openPath = new OpenPath;
			_range.addKeyListener(openPath);
			_range.addMouseListener(openPath);
			auto menu = new Menu(_win, SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.OpenAtView, &openRangePath, () => _range.getSelection().length > 0);
			_range.setMenu(menu);
		}
		{
			auto sep = new Label(_win, SWT.SEPARATOR | SWT.HORIZONTAL);
			sep.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}
		{
			auto bArea = new Composite(_win, SWT.NONE);
			bArea.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			bArea.setLayout(new GridLayout(2, false));
			_status = new Label(bArea, SWT.NONE);
			_status.setText(_prop.msgs.searchResultEmpty);
			_status.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			auto comp = new Composite(bArea, SWT.NONE);
			comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			auto gl = new GridLayout(3, true);
			gl.marginWidth = 0;
			gl.marginHeight = 0;
			comp.setLayout(gl);
			Button createButton(string text, void delegate() push) {
				auto b = new Button(comp, SWT.PUSH);
				b.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				b.setText(text);
				auto sa = new class SelectionAdapter {
					private void delegate() push;
					override void widgetSelected(SelectionEvent e) {
						push();
					}
				};
				sa.push = push;
				b.addSelectionListener(sa);
				return b;
			}
			_find = createButton(_prop.msgs.search, &search);
			_comm.put(_find, &canFind);
			_win.setDefaultButton(_find);
			_replace = createButton(_prop.msgs.replace, &replace);
			_comm.put(_replace, &canReplace);
			createButton(_prop.msgs.replaceExit, &exit);
		}
		setComboItems(_from, _prop.var.etc.searchHistories.dup);
		setComboItems(_to, _prop.var.etc.replaceHistories.dup);
		_notIgnoreCase.setSelection(_prop.var.etc.replaceTextNotIgnoreCase);
		_useRegex.setSelection(_prop.var.etc.replaceTextRegExp);
		_useWildcard.setSelection(_prop.var.etc.replaceTextWildcard);
		_summary.setSelection(_prop.var.etc.replaceTextSummary);
		_msg.setSelection(_prop.var.etc.replaceTextMessage);
		_cardName.setSelection(_prop.var.etc.replaceTextCardName);
		_cardDesc.setSelection(_prop.var.etc.replaceTextCardDescription);
		_event.setSelection(_prop.var.etc.replaceTextEventText);
		_flag.setSelection(_prop.var.etc.replaceTextFlagAndStep);
		_start.setSelection(_prop.var.etc.replaceTextStart);
		_coupon.setSelection(_prop.var.etc.replaceTextCoupon);
		_gossip.setSelection(_prop.var.etc.replaceTextGossip);
		_end.setSelection(_prop.var.etc.replaceTextEndScenario);
		_area.setSelection(_prop.var.etc.replaceTextAreaName);
		_keyCode.setSelection(_prop.var.etc.replaceTextKeyCode);
		_file.setSelection(_prop.var.etc.replaceTextFile);
		_comment.setSelection(_prop.var.etc.replaceTextComment);
		_jptx.setSelection(_prop.var.etc.replaceTextJptx);

		_contents[CType.START].setSelection(_prop.var.etc.searchContentsStart);
		_contents[CType.START_BATTLE].setSelection(_prop.var.etc.searchContentsStartBattle);
		_contents[CType.END].setSelection(_prop.var.etc.searchContentsEnd);
		_contents[CType.END_BAD_END].setSelection(_prop.var.etc.searchContentsEndBadEnd);
		_contents[CType.CHANGE_AREA].setSelection(_prop.var.etc.searchContentsChangeArea);
		_contents[CType.CHANGE_BG_IMAGE].setSelection(_prop.var.etc.searchContentsChangeBgImage);
		_contents[CType.EFFECT].setSelection(_prop.var.etc.searchContentsEffect);
		_contents[CType.EFFECT_BREAK].setSelection(_prop.var.etc.searchContentsEffectBreak);
		_contents[CType.LINK_START].setSelection(_prop.var.etc.searchContentsLinkStart);
		_contents[CType.LINK_PACKAGE].setSelection(_prop.var.etc.searchContentsLinkPackage);
		_contents[CType.TALK_MESSAGE].setSelection(_prop.var.etc.searchContentsTalkMessage);
		_contents[CType.TALK_DIALOG].setSelection(_prop.var.etc.searchContentsTalkDialog);
		_contents[CType.PLAY_BGM].setSelection(_prop.var.etc.searchContentsPlayBgm);
		_contents[CType.PLAY_SOUND].setSelection(_prop.var.etc.searchContentsPlaySound);
		_contents[CType.WAIT].setSelection(_prop.var.etc.searchContentsWait);
		_contents[CType.ELAPSE_TIME].setSelection(_prop.var.etc.searchContentsElapseTime);
		_contents[CType.CALL_START].setSelection(_prop.var.etc.searchContentsCallStart);
		_contents[CType.CALL_PACKAGE].setSelection(_prop.var.etc.searchContentsCallPackage);
		_contents[CType.BRANCH_FLAG].setSelection(_prop.var.etc.searchContentsBranchFlag);
		_contents[CType.BRANCH_MULTI_STEP].setSelection(_prop.var.etc.searchContentsBranchMultiStep);
		_contents[CType.BRANCH_STEP].setSelection(_prop.var.etc.searchContentsBranchStep);
		_contents[CType.BRANCH_SELECT].setSelection(_prop.var.etc.searchContentsBranchSelect);
		_contents[CType.BRANCH_ABILITY].setSelection(_prop.var.etc.searchContentsBranchAbility);
		_contents[CType.BRANCH_RANDOM].setSelection(_prop.var.etc.searchContentsBranchRandom);
		_contents[CType.BRANCH_LEVEL].setSelection(_prop.var.etc.searchContentsBranchLevel);
		_contents[CType.BRANCH_STATUS].setSelection(_prop.var.etc.searchContentsBranchStatus);
		_contents[CType.BRANCH_PARTY_NUMBER].setSelection(_prop.var.etc.searchContentsBranchPartyNumber);
		_contents[CType.BRANCH_AREA].setSelection(_prop.var.etc.searchContentsBranchArea);
		_contents[CType.BRANCH_BATTLE].setSelection(_prop.var.etc.searchContentsBranchBattle);
		_contents[CType.BRANCH_IS_BATTLE].setSelection(_prop.var.etc.searchContentsBranchIsBattle);
		_contents[CType.BRANCH_CAST].setSelection(_prop.var.etc.searchContentsBranchCast);
		_contents[CType.BRANCH_ITEM].setSelection(_prop.var.etc.searchContentsBranchItem);
		_contents[CType.BRANCH_SKILL].setSelection(_prop.var.etc.searchContentsBranchSkill);
		_contents[CType.BRANCH_INFO].setSelection(_prop.var.etc.searchContentsBranchInfo);
		_contents[CType.BRANCH_BEAST].setSelection(_prop.var.etc.searchContentsBranchBeast);
		_contents[CType.BRANCH_MONEY].setSelection(_prop.var.etc.searchContentsBranchMoney);
		_contents[CType.BRANCH_COUPON].setSelection(_prop.var.etc.searchContentsBranchCoupon);
		_contents[CType.BRANCH_COMPLETE_STAMP].setSelection(_prop.var.etc.searchContentsBranchCompleteStamp);
		_contents[CType.BRANCH_GOSSIP].setSelection(_prop.var.etc.searchContentsBranchGossip);
		_contents[CType.SET_FLAG].setSelection(_prop.var.etc.searchContentsSetFlag);
		_contents[CType.SET_STEP].setSelection(_prop.var.etc.searchContentsSetStep);
		_contents[CType.SET_STEP_UP].setSelection(_prop.var.etc.searchContentsSetStepUp);
		_contents[CType.SET_STEP_DOWN].setSelection(_prop.var.etc.searchContentsSetStepDown);
		_contents[CType.REVERSE_FLAG].setSelection(_prop.var.etc.searchContentsReverseFlag);
		_contents[CType.CHECK_FLAG].setSelection(_prop.var.etc.searchContentsCheckFlag);
		_contents[CType.GET_CAST].setSelection(_prop.var.etc.searchContentsGetCast);
		_contents[CType.GET_ITEM].setSelection(_prop.var.etc.searchContentsGetItem);
		_contents[CType.GET_SKILL].setSelection(_prop.var.etc.searchContentsGetSkill);
		_contents[CType.GET_INFO].setSelection(_prop.var.etc.searchContentsGetInfo);
		_contents[CType.GET_BEAST].setSelection(_prop.var.etc.searchContentsGetBeast);
		_contents[CType.GET_MONEY].setSelection(_prop.var.etc.searchContentsGetMoney);
		_contents[CType.GET_COUPON].setSelection(_prop.var.etc.searchContentsGetCoupon);
		_contents[CType.GET_COMPLETE_STAMP].setSelection(_prop.var.etc.searchContentsGetCompleteStamp);
		_contents[CType.GET_GOSSIP].setSelection(_prop.var.etc.searchContentsGetGossip);
		_contents[CType.LOSE_CAST].setSelection(_prop.var.etc.searchContentsLoseCast);
		_contents[CType.LOSE_ITEM].setSelection(_prop.var.etc.searchContentsLoseItem);
		_contents[CType.LOSE_SKILL].setSelection(_prop.var.etc.searchContentsLoseSkill);
		_contents[CType.LOSE_INFO].setSelection(_prop.var.etc.searchContentsLoseInfo);
		_contents[CType.LOSE_BEAST].setSelection(_prop.var.etc.searchContentsLoseBeast);
		_contents[CType.LOSE_MONEY].setSelection(_prop.var.etc.searchContentsLoseMoney);
		_contents[CType.LOSE_COUPON].setSelection(_prop.var.etc.searchContentsLoseCoupon);
		_contents[CType.LOSE_COMPLETE_STAMP].setSelection(_prop.var.etc.searchContentsLoseCompleteStamp);
		_contents[CType.LOSE_GOSSIP].setSelection(_prop.var.etc.searchContentsLoseGossip);
		_contents[CType.SHOW_PARTY].setSelection(_prop.var.etc.searchContentsShowParty);
		_contents[CType.HIDE_PARTY].setSelection(_prop.var.etc.searchContentsHideParty);
		_contents[CType.REDISPLAY].setSelection(_prop.var.etc.searchContentsRedisplay);

		_cCoupon.setSelection(_prop.var.etc.replaceNameCoupon);
		_cGossip.setSelection(_prop.var.etc.replaceNameGossip);
		_cEnd.setSelection(_prop.var.etc.replaceNameEndScenario);
		_cKeyCode.setSelection(_prop.var.etc.replaceNameKeyCode);

		_unuseFlag.setSelection(_prop.var.etc.searchUnusedFlag);
		_unuseStep.setSelection(_prop.var.etc.searchUnusedStep);
		_unuseArea.setSelection(_prop.var.etc.searchUnusedArea);
		_unuseBattle.setSelection(_prop.var.etc.searchUnusedBattle);
		_unusePackage.setSelection(_prop.var.etc.searchUnusedPackage);
		_unuseCast.setSelection(_prop.var.etc.searchUnusedCast);
		_unuseSkill.setSelection(_prop.var.etc.searchUnusedSkill);
		_unuseItem.setSelection(_prop.var.etc.searchUnusedItem);
		_unuseBeast.setSelection(_prop.var.etc.searchUnusedBeast);
		_unuseInfo.setSelection(_prop.var.etc.searchUnusedInfo);
		_unuseStart.setSelection(_prop.var.etc.searchUnusedStart);
		_unusePath.setSelection(_prop.var.etc.searchUnusedPath);
		foreach (l; _checked) {
			l.check();
		}
		_tabf.setSelection(0);
		if (0 <= _prop.var.etc.searchPlan && _prop.var.etc.searchPlan < _tabf.getItemCount()) {
			_tabf.setSelection(_prop.var.etc.searchPlan);
		}

		sash.addDisposeListener(new SashDispose);
		sash.setWeights([_prop.var.etc.replaceRangeSashL, _prop.var.etc.replaceRangeSashR]);

		_comm.refArea.add(&refArea);
		_comm.refBattle.add(&refBattle);
		_comm.refPackage.add(&refPackage);
		_comm.refCast.add(&refCast);
		_comm.refSkill.add(&refSkill);
		_comm.refItem.add(&refItem);
		_comm.refBeast.add(&refBeast);
		_comm.refInfo.add(&refInfo);
		_comm.delArea.add(&delArea);
		_comm.delBattle.add(&delBattle);
		_comm.delPackage.add(&delPackage);
		_comm.delCast.add(&delCast);
		_comm.delSkill.add(&delSkill);
		_comm.delItem.add(&delItem);
		_comm.delBeast.add(&delBeast);
		_comm.delInfo.add(&delInfo);
		_comm.refSearchHistories.add(&refSearchHistories);
		_comm.refContentText.add(&refContentText);
		_comm.refUndoMax.add(&refUndoMax);

		_comm.changed.add(&changed);
		_comm.refScenario.add(&summary);
		_win.addDisposeListener(new DL);
		auto cs = _win.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		auto size = _prop.var.replaceDlg;
		if (size.width != SWT.DEFAULT) cs.x = size.width;
		if (size.height != SWT.DEFAULT) cs.y = size.height;
		_win.setSize(cs);

		auto winProps = _prop.var.replaceDlg;
		_win.setMaximized(winProps.maximized);
		scope wp = _win.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		int width = winProps.width == SWT.DEFAULT ? wp.x : winProps.width;
		int height = winProps.height == SWT.DEFAULT ? wp.y : winProps.height;
		int x = winProps.x == SWT.DEFAULT ? _win.getBounds().x : winProps.x + _win.getParent().getBounds().x;
		int y = winProps.y == SWT.DEFAULT ? _win.getBounds().y : winProps.y + _win.getParent().getBounds().y;
		intoDisplay(x, y, width, height);
		_win.setBounds(x, y, width, height);
	}
	private void saveWin() {
		auto winProps = _prop.var.replaceDlg;
		if (!_win.getMaximized()) {
			winProps.width = _win.getSize().x;
			winProps.height = _win.getSize().y;
			winProps.x = _win.getBounds().x - _win.getParent().getBounds().x;
			winProps.y = _win.getBounds().y - _win.getParent().getBounds().y;
		}
		winProps.maximized = _win.getMaximized();
	}
	private class SashDispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto sash = cast(SplitPane) e.widget;
			auto ws = sash.getWeights();
			_prop.var.etc.replaceRangeSashL = ws[0];
			_prop.var.etc.replaceRangeSashR = ws[1];
		}
	}
	private class DL : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.changed.remove(&changed);
			_comm.refScenario.remove(&summary);
			saveWin();
			_prop.var.etc.replaceTextNotIgnoreCase = _notIgnoreCase.getSelection();
			_prop.var.etc.replaceTextRegExp = _useRegex.getSelection();
			_prop.var.etc.replaceTextWildcard = _useWildcard.getSelection();
			_prop.var.etc.replaceTextSummary = _summary.getSelection();
			_prop.var.etc.replaceTextMessage = _msg.getSelection();
			_prop.var.etc.replaceTextCardName = _cardName.getSelection();
			_prop.var.etc.replaceTextCardDescription = _cardDesc.getSelection();
			_prop.var.etc.replaceTextEventText = _event.getSelection();
			_prop.var.etc.replaceTextStart = _start.getSelection();
			_prop.var.etc.replaceTextFlagAndStep = _flag.getSelection();
			_prop.var.etc.replaceTextCoupon = _coupon.getSelection();
			_prop.var.etc.replaceTextGossip = _gossip.getSelection();
			_prop.var.etc.replaceTextEndScenario = _end.getSelection();
			_prop.var.etc.replaceTextAreaName = _area.getSelection();
			_prop.var.etc.replaceTextKeyCode = _keyCode.getSelection();
			_prop.var.etc.replaceTextFile = _file.getSelection();
			_prop.var.etc.replaceTextComment = _comment.getSelection();
			_prop.var.etc.replaceTextJptx = _jptx.getSelection();

			_prop.var.etc.searchContentsStart = _contents[CType.START].getSelection();
			_prop.var.etc.searchContentsStartBattle = _contents[CType.START_BATTLE].getSelection();
			_prop.var.etc.searchContentsEnd = _contents[CType.END].getSelection();
			_prop.var.etc.searchContentsEndBadEnd = _contents[CType.END_BAD_END].getSelection();
			_prop.var.etc.searchContentsChangeArea = _contents[CType.CHANGE_AREA].getSelection();
			_prop.var.etc.searchContentsChangeBgImage = _contents[CType.CHANGE_BG_IMAGE].getSelection();
			_prop.var.etc.searchContentsEffect = _contents[CType.EFFECT].getSelection();
			_prop.var.etc.searchContentsEffectBreak = _contents[CType.EFFECT_BREAK].getSelection();
			_prop.var.etc.searchContentsLinkStart = _contents[CType.LINK_START].getSelection();
			_prop.var.etc.searchContentsLinkPackage = _contents[CType.LINK_PACKAGE].getSelection();
			_prop.var.etc.searchContentsTalkMessage = _contents[CType.TALK_MESSAGE].getSelection();
			_prop.var.etc.searchContentsTalkDialog = _contents[CType.TALK_DIALOG].getSelection();
			_prop.var.etc.searchContentsPlayBgm = _contents[CType.PLAY_BGM].getSelection();
			_prop.var.etc.searchContentsPlaySound = _contents[CType.PLAY_SOUND].getSelection();
			_prop.var.etc.searchContentsWait = _contents[CType.WAIT].getSelection();
			_prop.var.etc.searchContentsElapseTime = _contents[CType.ELAPSE_TIME].getSelection();
			_prop.var.etc.searchContentsCallStart = _contents[CType.CALL_START].getSelection();
			_prop.var.etc.searchContentsCallPackage = _contents[CType.CALL_PACKAGE].getSelection();
			_prop.var.etc.searchContentsBranchFlag = _contents[CType.BRANCH_FLAG].getSelection();
			_prop.var.etc.searchContentsBranchMultiStep = _contents[CType.BRANCH_MULTI_STEP].getSelection();
			_prop.var.etc.searchContentsBranchStep = _contents[CType.BRANCH_STEP].getSelection();
			_prop.var.etc.searchContentsBranchSelect = _contents[CType.BRANCH_SELECT].getSelection();
			_prop.var.etc.searchContentsBranchAbility = _contents[CType.BRANCH_ABILITY].getSelection();
			_prop.var.etc.searchContentsBranchRandom = _contents[CType.BRANCH_RANDOM].getSelection();
			_prop.var.etc.searchContentsBranchLevel = _contents[CType.BRANCH_LEVEL].getSelection();
			_prop.var.etc.searchContentsBranchStatus = _contents[CType.BRANCH_STATUS].getSelection();
			_prop.var.etc.searchContentsBranchPartyNumber = _contents[CType.BRANCH_PARTY_NUMBER].getSelection();
			_prop.var.etc.searchContentsBranchArea = _contents[CType.BRANCH_AREA].getSelection();
			_prop.var.etc.searchContentsBranchBattle = _contents[CType.BRANCH_BATTLE].getSelection();
			_prop.var.etc.searchContentsBranchIsBattle = _contents[CType.BRANCH_IS_BATTLE].getSelection();
			_prop.var.etc.searchContentsBranchCast = _contents[CType.BRANCH_CAST].getSelection();
			_prop.var.etc.searchContentsBranchItem = _contents[CType.BRANCH_ITEM].getSelection();
			_prop.var.etc.searchContentsBranchSkill = _contents[CType.BRANCH_SKILL].getSelection();
			_prop.var.etc.searchContentsBranchInfo = _contents[CType.BRANCH_INFO].getSelection();
			_prop.var.etc.searchContentsBranchBeast = _contents[CType.BRANCH_BEAST].getSelection();
			_prop.var.etc.searchContentsBranchMoney = _contents[CType.BRANCH_MONEY].getSelection();
			_prop.var.etc.searchContentsBranchCoupon = _contents[CType.BRANCH_COUPON].getSelection();
			_prop.var.etc.searchContentsBranchCompleteStamp = _contents[CType.BRANCH_COMPLETE_STAMP].getSelection();
			_prop.var.etc.searchContentsBranchGossip = _contents[CType.BRANCH_GOSSIP].getSelection();
			_prop.var.etc.searchContentsSetFlag = _contents[CType.SET_FLAG].getSelection();
			_prop.var.etc.searchContentsSetStep = _contents[CType.SET_STEP].getSelection();
			_prop.var.etc.searchContentsSetStepUp = _contents[CType.SET_STEP_UP].getSelection();
			_prop.var.etc.searchContentsSetStepDown = _contents[CType.SET_STEP_DOWN].getSelection();
			_prop.var.etc.searchContentsReverseFlag = _contents[CType.REVERSE_FLAG].getSelection();
			_prop.var.etc.searchContentsCheckFlag = _contents[CType.CHECK_FLAG].getSelection();
			_prop.var.etc.searchContentsGetCast = _contents[CType.GET_CAST].getSelection();
			_prop.var.etc.searchContentsGetItem = _contents[CType.GET_ITEM].getSelection();
			_prop.var.etc.searchContentsGetSkill = _contents[CType.GET_SKILL].getSelection();
			_prop.var.etc.searchContentsGetInfo = _contents[CType.GET_INFO].getSelection();
			_prop.var.etc.searchContentsGetBeast = _contents[CType.GET_BEAST].getSelection();
			_prop.var.etc.searchContentsGetMoney = _contents[CType.GET_MONEY].getSelection();
			_prop.var.etc.searchContentsGetCoupon = _contents[CType.GET_COUPON].getSelection();
			_prop.var.etc.searchContentsGetCompleteStamp = _contents[CType.GET_COMPLETE_STAMP].getSelection();
			_prop.var.etc.searchContentsGetGossip = _contents[CType.GET_GOSSIP].getSelection();
			_prop.var.etc.searchContentsLoseCast = _contents[CType.LOSE_CAST].getSelection();
			_prop.var.etc.searchContentsLoseItem = _contents[CType.LOSE_ITEM].getSelection();
			_prop.var.etc.searchContentsLoseSkill = _contents[CType.LOSE_SKILL].getSelection();
			_prop.var.etc.searchContentsLoseInfo = _contents[CType.LOSE_INFO].getSelection();
			_prop.var.etc.searchContentsLoseBeast = _contents[CType.LOSE_BEAST].getSelection();
			_prop.var.etc.searchContentsLoseMoney = _contents[CType.LOSE_MONEY].getSelection();
			_prop.var.etc.searchContentsLoseCoupon = _contents[CType.LOSE_COUPON].getSelection();
			_prop.var.etc.searchContentsLoseCompleteStamp = _contents[CType.LOSE_COMPLETE_STAMP].getSelection();
			_prop.var.etc.searchContentsLoseGossip = _contents[CType.LOSE_GOSSIP].getSelection();
			_prop.var.etc.searchContentsShowParty = _contents[CType.SHOW_PARTY].getSelection();
			_prop.var.etc.searchContentsHideParty = _contents[CType.HIDE_PARTY].getSelection();
			_prop.var.etc.searchContentsRedisplay = _contents[CType.REDISPLAY].getSelection();

			_prop.var.etc.replaceNameCoupon = _cCoupon.getSelection();
			_prop.var.etc.replaceNameGossip = _cGossip.getSelection();
			_prop.var.etc.replaceNameEndScenario = _cEnd.getSelection();
			_prop.var.etc.replaceNameKeyCode = _cKeyCode.getSelection();

			_prop.var.etc.searchUnusedFlag = _unuseFlag.getSelection();
			_prop.var.etc.searchUnusedStep = _unuseStep.getSelection();
			_prop.var.etc.searchUnusedArea = _unuseArea.getSelection();
			_prop.var.etc.searchUnusedBattle = _unuseBattle.getSelection();
			_prop.var.etc.searchUnusedPackage = _unusePackage.getSelection();
			_prop.var.etc.searchUnusedCast = _unuseCast.getSelection();
			_prop.var.etc.searchUnusedSkill = _unuseSkill.getSelection();
			_prop.var.etc.searchUnusedItem = _unuseItem.getSelection();
			_prop.var.etc.searchUnusedBeast = _unuseBeast.getSelection();
			_prop.var.etc.searchUnusedInfo = _unuseInfo.getSelection();
			_prop.var.etc.searchUnusedStart = _unuseStart.getSelection();
			_prop.var.etc.searchUnusedPath = _unusePath.getSelection();

			_comm.refArea.remove(&refArea);
			_comm.refBattle.remove(&refBattle);
			_comm.refPackage.remove(&refPackage);
			_comm.refCast.remove(&refCast);
			_comm.refSkill.remove(&refSkill);
			_comm.refItem.remove(&refItem);
			_comm.refBeast.remove(&refBeast);
			_comm.refInfo.remove(&refInfo);
			_comm.delArea.remove(&delArea);
			_comm.delBattle.remove(&delBattle);
			_comm.delPackage.remove(&delPackage);
			_comm.delCast.remove(&delCast);
			_comm.delSkill.remove(&delSkill);
			_comm.delItem.remove(&delItem);
			_comm.delBeast.remove(&delBeast);
			_comm.delInfo.remove(&delInfo);
			_comm.refSearchHistories.remove(&refSearchHistories);
			_comm.refContentText.remove(&refContentText);
			_comm.refUndoMax.remove(&refUndoMax);
		}
	}
	private void changed() {
		if (!_inProc) {
			_undo.reset();
			_comm.refreshToolBar();
		}
	}
	private void undo() {
		if (!_undo.canUndo) return;
		_inProc = true;
		scope (exit) _inProc = false;
		reset();
		_undo.undo();
		refContentText();
		_status.setText(.tryFormat(_prop.msgs.replaceUndo, .formatNum(_result.getItemCount())));
		_comm.replText.call();
		_comm.refreshToolBar();
	}
	private void redo() {
		if (!_undo.canRedo) return;
		_inProc = true;
		scope (exit) _inProc = false;
		reset();
		_undo.redo();
		refContentText();
		_status.setText(.tryFormat(_prop.msgs.replaceRedo, .formatNum(_result.getItemCount())));
		_comm.replText.call();
		_comm.refreshToolBar();
	}
	private void search() {
		auto c = _win.getDisplay().getFocusControl();
		_replMode = false;
		replaceImpl();
		if (c) .forceFocus(c, false);
	}
	private void replace() {
		auto c = _win.getDisplay().getFocusControl();
		_replMode = true;
		replaceImpl();
		if (c) .forceFocus(_replace, false);
	}
	private void reset() {
		_result.removeAll();
		if (_replMode) {
			_status.setText(_prop.msgs.replResultEmpty);
		} else {
			_status.setText(_prop.msgs.searchResultEmpty);
		}
		_comm.refreshToolBar();
	}
	@property
	private bool canFind() {
		if (!_tabf || _tabf.isDisposed()) return false;
		auto sel = _tabf.getSelection();
		if (!sel) return false;
		if (sel is _tabText) {
			return _from.getText().length > 0;
		} else if (sel is _tabID) {
			return getID(_fromID, _fromIDVal, _fromIDTbl) !is 0;
		} else if (sel is _tabPath) {
			return _fromPath.getText().length > 0;
		} else if (sel is _tabContents) {
			return true;
		} else if (sel is _tabCoupon) {
			return true;
		} else if (sel is _tabUnuse) {
			return true;
		} else if (sel is _tabError) {
			return true;
		} else assert (0);
	}
	@property
	private bool canReplace() {
		if (!_tabf || _tabf.isDisposed()) return false;
		auto sel = _tabf.getSelection();
		if (!sel) return false;
		return canFind && (sel is _tabText || sel is _tabID || sel is _tabPath);
	}
	private void replaceImpl() {
		_inProc = true;
		scope (exit) _inProc = false;
		_rUndo.length = 0;
		_after.length = 0;
		if (_tabf.getSelection() is _tabText) {
			replaceTextImpl();
		} else if (_tabf.getSelection() is _tabID) {
			replaceIDImpl();
		} else if (_tabf.getSelection() is _tabPath) {
			replacePathImpl();
		} else if (_tabf.getSelection() is _tabContents) {
			searchContents();
		} else if (_tabf.getSelection() is _tabCoupon) {
			searchCoupon();
		} else if (_tabf.getSelection() is _tabUnuse) {
			searchUnuseImpl();
		} else if (_tabf.getSelection() is _tabError) {
			searchErrorImpl();
		} else assert (0);
		foreach (a; _after) a();
		if (_after.length) {
			refContentText();
			if (_replMode) _comm.replText.call();
		}
		if (_replMode && _rUndo.length) {
			_undo ~= new UndoArr(_rUndo, false);
		}
		_rUndo = [];
		_after = [];
		_comm.refreshToolBar();
	}
	private void searchRange(ref uint count,
			void delegate(CWXPath path, ref uint count) dlg) {
		void recurse(TreeItem itm) {
			auto path = cast(CWXPath) itm.getData();
			searchAll(path, count, dlg);
			foreach (child; itm.getItems()) {
				if (child.getChecked()) {
					recurse(child);
				}
			}
		}
		foreach (itm; _range.getItems()) {
			if (itm.getChecked()) {
				recurse(itm);
			}
		}
	}
	private void searchAll(CWXPath path, ref uint count,
			void delegate(CWXPath path, ref uint count) dlg) {
		dlg(path, count);
		// _rangeに含まれる要素は再帰的検索から除外する
		auto fdir = cast(FlagDir) path;
		if (fdir) {
			foreach (o; fdir.flags) searchAll(o, count, dlg);
			foreach (o; fdir.steps) searchAll(o, count, dlg);
			foreach (o; fdir.subDirs) searchAll(o, count, dlg);
		}
		auto eto = cast(EventTreeOwner) path;
		if (eto) {
			foreach (o; eto.trees) searchAll(o, count, dlg);
		}
		auto et = cast(EventTree) path;
		if (et) {
			foreach (o; et.starts) searchAll(o, count, dlg);
		}
		auto c = cast(Content) path;
		if (c) {
			foreach (o; c.backs) searchAll(o, count, dlg);
			foreach (o; c.next) searchAll(o, count, dlg);
		}
		auto area = cast(Area) path;
		if (area) {
			foreach (o; area.cards) searchAll(o, count, dlg);
			foreach (o; area.backs) searchAll(o, count, dlg);
		}
		auto battle = cast(Battle) path;
		if (battle) {
			foreach (o; battle.cards) searchAll(o, count, dlg);
		}
		auto mo = cast(MotionOwner) path;
		if (mo) {
			foreach (m; mo.motions) {
				if (m.beast && 0 == m.beast.linkId) {
					searchAll(m.beast, count, dlg);
				}
			}
		}
	}

	private void setResultStatus(uint count) {
		if (count > 0) {
			if (_replMode) _summ.changed();
			_comm.refUseCount.call();
		}
		string kind = _tabf.getSelection().getText();
		if (_replMode) {
			_status.setText(.tryFormat(_prop.msgs.replResult, .formatNum(count), kind));
		} else {
			_status.setText(.tryFormat(_prop.msgs.searchResult, .formatNum(count), kind));
		}
	}
	private void replaceIDImpl2(ID)(ID from, ID to) {
		reset();
		bool[CWXPath] range;
		void recurse(TreeItem itm) {
			range[cast(CWXPath) itm.getData()] = itm.getChecked();
			foreach (cItm; itm.getItems()) {
				recurse(cItm);
			}
		}
		foreach (itm; _range.getItems()) {
			recurse(itm);
		}
		bool dec(CWXPath path) {
			assert (path);
			auto p = path in range;
			if (p) {
				return *p;
			}
			return dec(path.cwxParent);
		}

		auto uc = _summ.useCounter;
		auto users = uc.values(from);
		_result.setRedraw(false);
		scope (exit) _result.setRedraw(true);
		size_t count = 0;
		foreach (u; users) {
			if (!dec(u.owner)) continue;
			if (_replMode) {
				u.id = to;
				storeID(u.owner, u, from, to, &u.id);
			}
			addResult(u.owner);
			count++;
		}
		setResultStatus(count);
		if (count) {
			static if (is(ID : PathId)) {
				_comm.replPath.call(cast(string) from, cast(string) to);
			} else {
				_comm.replID.call();
			}
		}
	}
	private ulong getID(Combo combo, Spinner spn, ulong[int] tbl) {
		if (combo.getSelectionIndex() == 0) {
			return spn.getSelection();
		} else {
			return tbl[combo.getSelectionIndex()];
		}
	}
	private void replaceIDImpl() {
		ulong from = getID(_fromID, _fromIDVal, _fromIDTbl);
		ulong to = getID(_toID, _toIDVal, _toIDTbl);
		if (from == to) _replMode = false;
		switch (_idKind.getSelectionIndex()) {
		case ID_AREA: replaceIDImpl2(toAreaId(from), toAreaId(to)); break;
		case ID_BATTLE: replaceIDImpl2(toBattleId(from), toBattleId(to)); break;
		case ID_PACKAGE: replaceIDImpl2(toPackageId(from), toPackageId(to)); break;
		case ID_CAST: replaceIDImpl2(toCastId(from), toCastId(to)); break;
		case ID_SKILL: replaceIDImpl2(toSkillId(from), toSkillId(to)); break;
		case ID_ITEM: replaceIDImpl2(toItemId(from), toItemId(to)); break;
		case ID_BEAST: replaceIDImpl2(toBeastId(from), toBeastId(to)); break;
		case ID_INFO: replaceIDImpl2(toInfoId(from), toInfoId(to)); break;
		default: assert (0);
		}
	}
	private void replacePathImpl() {
		if (!_fromPath.getText().length) return;
		auto from = toPathId(_fromPath.getText());
		auto to = toPathId(_toPath.getText());
		if (from == to) _replMode = false;
		replaceIDImpl2(from, to);
	}

	private void searchCoupon() {
		uint count = 0;
		reset();
		_result.setRedraw(false);
		scope (exit) _result.setRedraw(true);
		string[] coupons;
		string[] gossips;
		string[] scenarios;
		string[] keyCodes;
		searchRange(count, (CWXPath path, ref uint count) {
			auto summ = cast(Summary) path;
			if (summ) {
				if (_cCoupon.getSelection()) {
					coupons ~= summ.rCoupons;
				}
			}
			auto casts = cast(CastCard) path;
			if (casts) {
				if (_cCoupon.getSelection()) {
					foreach (c; casts.coupons) {
						coupons ~= c.name;
					}
				}
			}
			auto eff = cast(EffectCard) path;
			if (eff) {
				if (_cKeyCode.getSelection()) {
					keyCodes ~= eff.keyCodes;
				}
			}
			auto et = cast(EventTree) path;
			if (et) {
				if (_cKeyCode.getSelection()) {
					keyCodes ~= et.keyCodes;
				}
			}
			auto c = cast(Content) path;
			if (c) {
				if (_cCoupon.getSelection()) {
					if (c.coupon.length) coupons ~= c.coupon;
					foreach (dlg; c.dialogs) {
						coupons ~= dlg.rCoupons;
					}
				}
				if (_cGossip.getSelection()) {
					if (c.gossip.length) gossips ~= c.gossip;
				}
				if (_cEnd.getSelection()) {
					if (c.completeStamp.length) scenarios ~= c.completeStamp;
				}
			}
		});
		foreach (n; coupons.sort.uniq()) {
			if (!n.length) continue;
			addResult(n, _prop.images.couponNormal);
			count++;
		}
		foreach (n; gossips.sort.uniq()) {
			if (!n.length) continue;
			addResult(n, _prop.images.gossip);
			count++;
		}
		foreach (n; scenarios.sort.uniq()) {
			if (!n.length) continue;
			addResult(n, _prop.images.endScenario);
			count++;
		}
		foreach (n; keyCodes.sort.uniq()) {
			if (!n.length) continue;
			addResult(n, _prop.images.keyCode);
			count++;
		}
		setResultStatus(count);
	}

	private void searchContents() {
		uint count = 0;
		reset();
		_result.setRedraw(false);
		scope (exit) _result.setRedraw(true);
		searchRange(count, (CWXPath path, ref uint count) {
			auto c = cast(Content) path;
			if (!c) return;
			assert (c.type in _contents);
			if (!_contents[c.type].getSelection()) return;
			addResult(path);
			count++;
		});
		setResultStatus(count);
	}

	private void searchUnuseImpl2(string ToId, T)(T[] all, ref uint count) {
		foreach (o; all) {
			if (_summ.useCounter.get(mixin (ToId)) == 0) {
				addResult(o);
				count++;
			}
		}
	}
	private void searchUnuseImpl() {
		_replMode = false;
		uint count = 0;
		_result.setRedraw(false);
		scope (exit) _result.setRedraw(true);
		reset();
		if (_unuseFlag.getSelection()) {
			searchUnuseImpl2!("toFlagId(o.path)")(_summ.flagDirRoot.allFlags, count);
		}
		if (_unuseStep.getSelection()) {
			searchUnuseImpl2!("toStepId(o.path)")(_summ.flagDirRoot.allSteps, count);
		}
		if (_unuseArea.getSelection()) {
			searchUnuseImpl2!("toAreaId(o.id)")(_summ.areas, count);
		}
		if (_unuseBattle.getSelection()) {
			searchUnuseImpl2!("toBattleId(o.id)")(_summ.battles, count);
		}
		if (_unusePackage.getSelection()) {
			searchUnuseImpl2!("toPackageId(o.id)")(_summ.packages, count);
		}
		if (_unuseCast.getSelection()) {
			searchUnuseImpl2!("toCastId(o.id)")(_summ.casts, count);
		}
		if (_unuseSkill.getSelection()) {
			searchUnuseImpl2!("toSkillId(o.id)")(_summ.skills, count);
		}
		if (_unuseItem.getSelection()) {
			searchUnuseImpl2!("toItemId(o.id)")(_summ.items, count);
		}
		if (_unuseBeast.getSelection()) {
			searchUnuseImpl2!("toBeastId(o.id)")(_summ.beasts, count);
		}
		if (_unuseInfo.getSelection()) {
			searchUnuseImpl2!("toInfoId(o.id)")(_summ.infos, count);
		}
		if (_unuseStart.getSelection()) {
			searchRange(count, (CWXPath path, ref uint count) {
				auto et = cast(EventTree) path;
				if (et) {
					foreach (s; et.starts[1 .. $]) {
						if (et.startUseCounter.get(toStartId(s.name)) == 0) {
							addResult(s);
							count++;
						}
					}
				}
			});
		}
		if (_unusePath.getSelection()) {
			auto files = _summ.notUsedFiles(_comm.skin, _prop.var.etc.ignorePaths, _prop.var.etc.logicalSort);
			foreach (file; files) {
				addResult(encodePath(file));
				count++;
			}
		}
		setResultStatus(count);
	}
	private void searchErrorImpl() {
		uint count = 0;
		auto froot = _summ.flagDirRoot;
		auto sPath = _summ.scenarioPath;
		auto skin = _comm.skin;
		reset();
		_result.setRedraw(false);
		scope (exit) _result.setRedraw(true);
		searchRange(count, (CWXPath path, ref uint count) {
			auto summ = cast(Summary) path;
			if (summ) {
				if (summ.imagePath != "" && !isBinImg(summ.imagePath) && !skin.findPath(summ.imagePath, skin.extImage, skin.tableDir, sPath).length) {
					addResult(path, _prop.msgs.searchErrorImageNotFound);
					count++;
					return;
				}
				if (!summ.area(summ.startArea)) {
					addResult(path, _prop.msgs.searchErrorStartAreaNotFound);
					count++;
					return;
				}
			}
			auto casts = cast(CastCard) path;
			if (casts) {
				bool r = false;
				foreach (c; casts.skills) {
					if (0 != c.linkId && !_summ.skill(c.linkId)) {
						addResult(path, _prop.msgs.searchErrorLinkIdNotFound);
						count++;
						r = true;
					}
				}
				foreach (c; casts.items) {
					if (0 != c.linkId && !_summ.item(c.linkId)) {
						addResult(path, _prop.msgs.searchErrorLinkIdNotFound);
						count++;
						r = true;
					}
				}
				foreach (c; casts.beasts) {
					if (0 != c.linkId && !_summ.beast(c.linkId)) {
						addResult(path, _prop.msgs.searchErrorLinkIdNotFound);
						count++;
						r = true;
					}
				}
				if (r) return;
			}
			auto card = cast(Card) path;
			if (card) {
				if (card.path != "" && !isBinImg(card.path) && !skin.findPath(card.path, skin.extImage, skin.tableDir, sPath).length) {
					addResult(path, _prop.msgs.searchErrorImageNotFound);
					count++;
					return;
				}
			}
			auto bi = cast(BgImage) path;
			if (bi) {
				if (!bi.path.length) {
					addResult(path, _prop.msgs.searchErrorNoImage);
					count++;
					return;
				}
				if (!skin.findPath(bi.path, skin.extImage, skin.tableDir, sPath).length) {
					addResult(path, _prop.msgs.searchErrorImageNotFound);
					count++;
					return;
				}
				if (bi.flag != "" && !froot.findFlag(bi.flag)) {
					addResult(path, _prop.msgs.searchErrorFlagNotFound);
					count++;
					return;
				}
			}
			auto mc = cast(MenuCard) path;
			if (mc) {
				if (mc.path != "" && !isBinImg(mc.path) && !skin.findPath(mc.path, skin.extImage, skin.tableDir, sPath).length) {
					addResult(path, _prop.msgs.searchErrorImageNotFound);
					count++;
					return;
				}
				if (mc.flag != "" && !froot.findFlag(mc.flag)) {
					addResult(path, _prop.msgs.searchErrorFlagNotFound);
					count++;
					return;
				}
			}
			auto ec = cast(EnemyCard) path;
			if (ec) {
				if (ec.id == 0) {
					addResult(path, _prop.msgs.searchErrorNoCast);
					count++;
					return;
				}
				if (!_summ.cwCast(ec.id)) {
					addResult(path, _prop.msgs.searchErrorCastNotFound);
					count++;
					return;
				}
				if (ec.flag != "" && !froot.findFlag(ec.flag)) {
					addResult(path, _prop.msgs.searchErrorFlagNotFound);
					count++;
					return;
				}
			}
			auto c = cast(Content) path;
			if (!c) return;
			if (_summ.legacy && c.type == CType.WAIT && !c.next.length) {
				addResult(path, _prop.msgs.searchErrorIgnoreWait);
				count++;
				return;
			}
			if (c.detail.owner && c.detail.nextType != CNextType.TEXT) {
				auto set = new HashSet!(string);
				foreach (cld; c.next) {
					if (cld.name == "") continue;
					if (set.contains(cld.name)) {
						addResult(path, _prop.msgs.searchErrorDupNextContent);
						count++;
						return;
					}
					set.add(cld.name);
				}
			}
			auto spChars = _comm.skin.spChars;
			string checkTextRes(string[] fonts, string[] flags, string[] steps) {
				foreach (font; fonts) {
					dchar c = decodeFontPath(font);
					if (c in spChars) continue;
					if (!skin.findPath(font, skin.extImage, skin.tableDir, sPath).length) {
						return _prop.msgs.searchErrorSPFontNotFound;
					}
				}
				foreach (flag; flags) {
					if (!froot.findFlag(flag)) {
						return _prop.msgs.searchErrorFlagNotFound;
					}
				}
				foreach (step; steps) {
					if (!froot.findStep(step)) {
						return _prop.msgs.searchErrorStepNotFound;
					}
				}
				return null;
			}
			if (c.type == CType.TALK_DIALOG) {
				if (c.dialogs.length) {
					foreach (i, dlg; c.dialogs) {
						if (i + 1 < c.dialogs.length && !dlg.rCoupons.length) {
							// 最後以外にクーポンが設定されていない場合
							addResult(path, _prop.msgs.searchErrorNoRCouponsDialog);
							count++;
							return;
						}
						string err = checkTextRes(dlg.fontsInText, dlg.flagsInText, dlg.stepsInText);
						if (err) {
							addResult(path, err);
							count++;
							return;
						}
					}
				}
			}
			string textErr = checkTextRes(c.fontsInText, c.flagsInText, c.stepsInText);
			if (textErr) {
				addResult(path, textErr);
				count++;
				return;
			}
			bool hasStart() {
				foreach (s; c.tree.starts) {
					if (s.name == c.start) return true;
				}
				return false;
			}
			if (c.flag != "" && !froot.findFlag(c.flag)) {
				addResult(path, _prop.msgs.searchErrorFlagNotFound);
				count++;
				return;
			}
			if (c.step != "" && !froot.findStep(c.step)) {
				addResult(path, _prop.msgs.searchErrorStepNotFound);
				count++;
				return;
			}
			if (c.type == CType.TALK_MESSAGE && c.talkerC == Talker.IMAGE
					&& c.cardPath != "" && !skin.findPath(c.cardPath, skin.extImage, skin.tableDir, sPath).length) {
				addResult(path, _prop.msgs.searchErrorImageNotFound);
				count++;
				return;
			}
			if (c.bgmPath != "" && !skin.findPath(c.bgmPath, skin.extBgm, skin.bgmDir, sPath).length) {
				addResult(path, _prop.msgs.searchErrorBGMNotFound);
				count++;
				return;
			}
			if (c.soundPath != "" && !skin.findPath(c.soundPath, skin.extSound, skin.seDir, sPath).length) {
				addResult(path, _prop.msgs.searchErrorSENotFound);
				count++;
				return;
			}
			if (c.area != 0 && !_summ.area(c.area)) {
				addResult(path, _prop.msgs.searchErrorAreaNotFound);
				count++;
				return;
			}
			if (c.battle != 0 && !_summ.battle(c.battle)) {
				addResult(path, _prop.msgs.searchErrorBattleNotFound);
				count++;
				return;
			}
			if (c.packages != 0 && !_summ.cwPackage(c.packages)) {
				addResult(path, _prop.msgs.searchErrorPackageNotFound);
				count++;
				return;
			}
			if (c.casts != 0 && !_summ.cwCast(c.casts)) {
				addResult(path, _prop.msgs.searchErrorCastNotFound);
				count++;
				return;
			}
			if (c.item != 0 && !_summ.item(c.item)) {
				addResult(path, _prop.msgs.searchErrorItemNotFound);
				count++;
				return;
			}
			if (c.skill != 0 && !_summ.skill(c.skill)) {
				addResult(path, _prop.msgs.searchErrorSkillNotFound);
				count++;
				return;
			}
			if (c.beast != 0 && !_summ.beast(c.beast)) {
				addResult(path, _prop.msgs.searchErrorBeastNotFound);
				count++;
				return;
			}
			if (c.info != 0 && !_summ.info(c.info)) {
				addResult(path, _prop.msgs.searchErrorInfoNotFound);
				count++;
				return;
			}
			if (c.start != "" && !hasStart()) {
				addResult(path, _prop.msgs.searchErrorStartNotFound);
				count++;
				return;
			}
			foreach (m; c.motions) {
				if (m.type == MType.SUMMON_BEAST && !m.beast) {
					addResult(path, _prop.msgs.searchErrorNoBeast);
					count++;
					return;
				}
				if (m.type == MType.SUMMON_BEAST && m.beast && 0 != m.beast.linkId && !_summ.beast(m.beast.linkId)) {
					addResult(path, _prop.msgs.searchErrorLinkIdNotFound);
					count++;
					return;
				}
			}
		});
		setResultStatus(count);
	}
	private void replaceTextImpl(CWXPath c, ref size_t count) {
		bool oldIgnoreMod = ignoreMod;
		ignoreMod = true;
		scope (exit) ignoreMod = oldIgnoreMod;

		auto summ = cast(Summary) c;
		if (summ) {
			bool sr = false;
			Undo[] uArr;
			if (_summary.getSelection()) {
				sr |= repl(null, summ.scenarioName, &summ.scenarioName, count, uArr);
				sr |= repl(null, summ.desc, &summ.desc, count, uArr);
			}
			if (_coupon.getSelection()) {
				sr |= replRqCoupons!(Summary)(null, _summ, count, uArr);
			}
			if (sr) {
				if (_replMode) store(summ, uArr);
				addResult(summ);
			}
		}
		auto cc = cast(CastCard) c;
		if (cc) {
			Undo[] uArr;
			bool r = replCard!(CastCard)(null, cc, count, uArr);
			if (_coupon.getSelection()) {
				auto coupons = cc.coupons.dup;
				foreach (i, cp; coupons) {
					r |= repl(null, cp.name,
						(string t) {cp = new Coupon(t, cp.value);}, count, uArr);
					if (_replMode) coupons[i] = cp;
				}
				cc.coupons = coupons;
			}
			if (r) {
				if (_replMode) store(cc, uArr);
				addResult(cc);
			}
		}
		Undo[] nArr;
		auto eff = cast(EffectCard) c;
		if (eff) {
			replCard(eff, eff, count, nArr);
		}
		auto info = cast(InfoCard) c;
		if (info) {
			replCard(info, info, count, nArr);
		}
		auto a = cast(AbstractArea) c;
		if (a) {
			if (_area.getSelection()) {
				repl(a, a.name, &a.name, count, nArr);
			}
		}
		auto menu = cast(MenuCard) c;
		if (menu) {
			replCard(menu, menu, count, nArr);
		}
		auto back = cast(BgImage) c;
		if (back) {
			replBgImage(back, back, count, nArr);
		}
		auto f = cast(Flag) c;
		if (f && _flag.getSelection()) {
			Undo[] uArr = new Undo[0];
			bool r = replFlagName!Flag(f.parent, f, count, uArr);
			r |= repl(null, f.on, &f.on, count, uArr);
			r |= repl(null, f.off, &f.off, count, uArr);
			if (r) {
				if (_replMode) store(f, uArr);
				addResult(f);
			}
		}
		auto s = cast(Step) c;
		if (s && _flag.getSelection()) {
			Undo[] uArr;
			bool r = replFlagName!Step(s.parent, s, count, uArr);
			foreach (i, v; s.values) {
				r |= repl(null, v, (string t) {s.setValue(i, t);}, count, uArr);
			}
			if (r) {
				if (_replMode) store(s, uArr);
				addResult(s);
			}
		}
		auto et = cast(EventTree) c;
		if (et) {
			replKeyCode(et, et, count, nArr);
		}
		auto content = cast(Content) c;
		if (content) {
			replContent(content, count);
		}
	}
	private void replaceTextImpl() {
		string from = _from.getText();
		string to = _to.getText();
		if (!from.length) return;
		if (_useRegex.getSelection()) {
			try {
				_regex = .regex!(dstring)(toUTF32(from), _notIgnoreCase.getSelection() ? "gm" : "gim");
				_regexTarg = true;
				_toTemp = toUTF32(to);
			} catch (Exception e) {
				MessageBox.showWarning
					(_prop.msgs.regexError ~ "\n" ~ e.msg,
					_prop.msgs.dlgTitWarning, _win);
				return;
			}
		} else if (_useWildcard.getSelection()) {
			_wildcard = Wildcard(from, !_notIgnoreCase.getSelection());
		} else {
			if (from == to) _replMode = false;
		}
		scope (exit) {
			_regex = typeof(_regex).init;
			_regexTarg = false;
			_toTemp = ""d;
		}
		scope (exit) _wildcard = null;

		size_t count = 0;
		_result.setRedraw(false);
		scope (exit) _result.setRedraw(true);
		reset();
		searchRange(count, &replaceTextImpl);
		if (_jptx.getSelection()) {
			foreach (string file; .dirEntries(_summ.scenarioPath, SpanMode.depth, false)) {
				if (cfnmatch(.extension(file), ".jptx")) {
					try {
						bool isSJIS;
						string value = readJPYFile(file, isSJIS);
						auto jText = jptxText(value);
						Undo[] uArr;
						string file2 = file;
						bool r = repl(null, jText, (string jText) {
							string value = jptxText(value, jText);
							try {
								writeJPYFile(file2, value, isSJIS);
							} catch (Exception e) {
								debugln(e);
							}
						}, count, uArr, true);
						if (r) {
							file = relativePath(file, _summ.scenarioPath);
							addResult(file);
							store(file, uArr);
						}
					} catch (Exception e) {
						debugln(e);
					}
				}
			}
		}
		setResultStatus(count);
		if (_replMode && !_after.length) _comm.replText.call();

		static void addHist(Combo combo, void delegate(string[]) set,
				string[] delegate() get, int max, string text) {
			if (text.length) {
				string[] list = get();
				if (.contains(list, text)) {
					list = cwx.utils.remove(list, text);
				}
				list = [text] ~ list;
				if (list.length > max) {
					list = list[0 .. $ - 1];
				}
				set(list);
				setComboItems(combo, list);
				combo.select(0);
			}
		}
		addHist(_from, (string[] s) {_prop.var.etc.searchHistories = s;},
			{return _prop.var.etc.searchHistories.dup;},
			_prop.var.etc.searchHistoryMax, from);
		if (_replMode) {
			addHist(_to, (string[] s) {_prop.var.etc.replaceHistories = s;},
				{return _prop.var.etc.replaceHistories.dup;},
				_prop.var.etc.searchHistoryMax, to);
		}
		_comm.refSearchHistories.call(this);
	}
	private void refSearchHistories(Object sender) {
		if (sender is this) return;
		string ft = _from.getText();
		string tt = _to.getText();
		setComboItems(_from, _prop.var.etc.searchHistories.dup);
		setComboItems(_to, _prop.var.etc.replaceHistories.dup);
		_from.setText(ft);
		_to.setText(tt);
	}
	private Regex!(dchar) _regex;
	private bool _regexTarg = false;
	private Wildcard _wildcard = null;
	private dstring _toTemp = ""d;
	/// FIXME: std.regex.replace()がdstringでコンパイルエラーになる。
	private static dstring impReplace(dstring s, Regex!(dchar) regex, dstring to) {
		dstring r = "";
		dstring post = "";
		foreach (m; .match(s, regex)) {
			r ~= m.pre;
			r ~= to;
			r = m.post;
		}
		return r ~ post;
	}
	private string fTextRepl(string s) {
		if (_regexTarg) {
			return toUTF8(impReplace(toUTF32(s), _regex, _toTemp));
		}
		string to = _to.getText();
		if (_wildcard) {
			return _wildcard.replace(s, to);
		}
		string from = _from.getText();
		if (_notIgnoreCase.getSelection()) {
			return .replace(s, from, to);
		} else {
			return .ireplace(s, from, to);
		}
	}
	private size_t fTextCount(string s) {
		if (_regexTarg) {
			size_t c = 0;
			try {
				foreach (m; std.regex.match(toUTF32(s), _regex)) {
					c++;
				}
			} catch (Throwable e) {
 				debugln(_from.getText(), " -> ", s);
				throw e;
			}
			return c;
		}
		if (_wildcard) {
			return _wildcard.count(s);
		}
		string from = _from.getText();
		if (_notIgnoreCase.getSelection()) {
			return std.algorithm.count(s, from);
		} else {
			return .icount(s, from);
		}
	}
	private void exit() {
		_win.close();
	}
	private bool _replMode = false;

	private bool canOpenPath() {
		auto sels = _result.getSelection();
		if (!sels.length) return false;
		foreach (itm; sels) {
			auto d = itm.getData();
			if (cast(CWXPathString) d !is null || cast(PathString) d !is null) {
				return true;
			}
		}
		return false;
	}
	private void openPath() {
		auto i = _result.getSelectionIndex();
		if (-1 == i) return;
		foreach (itm; [_result.getItem(i)] ~ _result.getItems()) {
			auto d = itm.getData();
			auto rp = cast(CWXPathString) d;
			if (rp) {
				auto path = rp.array;
				if (_prop.var.etc.searchOpenDialog) {
					path = cpaddattr(path, "opendialog");
				}
				try {
					if (_comm.openCWXPath(path, false)) {
						if (!_prop.var.etc.searchOpenDialog) _win.setActive();
						return;
					}
				} catch (Exception e) {
					debugln(e);
				}
				MessageBox.showWarning(.tryFormat(_prop.msgs.cwxPathOpenError, path), _prop.msgs.dlgTitWarning, _win);
				return;
			}
			auto p = cast(PathString) d;
			if (p) {
				auto path = nabs(std.path.buildPath(_summ.scenarioPath, p.array));
				if (_comm.openFilePath(path, false)) {
					_win.setActive();
					return;
				}
				MessageBox.showWarning(.tryFormat(_prop.msgs.filePathOpenError, path), _prop.msgs.dlgTitWarning, _win);
				return;
			}
		}
	}
	Image fimage(string file) {
		try {
			if (.exists(file)) {
				auto skin = _comm.skin;
				if (.isDir(file)) {
					return _prop.images.folder;
				} else if (skin.isCardImage(file)) {
					return _prop.images.cards;
				} else if (skin.isBgImage(file)) {
					return _prop.images.backs;
				} else if (skin.isBGM(file)) {
					return _prop.images.bgm;
				} else if (skin.isSE(file)) {
					return _prop.images.se;
				}
			}
		} catch (Exception e) {
			debugln(e);
		}
		return _prop.images.unknown;
	}
	private void copyResult() {
		string[] t;
		foreach (itm; _result.getSelection()) {
			t ~= itm.getText().replace("\n", .newline);
		}
		if (!t.length) return;
		auto text = new ArrayWrapperString(std.string.join(t, .newline));
		_comm.clipboard.setContents([text], [TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}
	private void addResult(string path) {
		auto itm = new TableItem(_result, SWT.NONE);
		itm.setImage(fimage(std.path.buildPath(_summ.scenarioPath, path)));
		itm.setText(encodePath(path));
		itm.setData(new PathString(path));
	}
	private void refContentText() {
		foreach (itm; _result.getItems()) {
			auto c = cast(CWXPathString) itm.getData();
			if (c) {
				string text;
				Image img;
				getPathParams(c.path, text, img);
				itm.setText(text);
				itm.setImage(img);
			}
		}
	}
	private void getPathParams(CWXPath path, out string text, out Image img, bool par = false) {
		img = null;
		text = par ? "" : "*Error*";
		if (!path) return;
		auto sum = cast(Summary) path;
		if (sum && !par) {
			img = _prop.images.summary;
			text = _prop.msgs.summary;
		}
		auto bgi = cast(BgImage) path;
		if (bgi && !par) {
			img = _prop.images.backs;
			text = .tryFormat(_prop.msgs.searchResultBgImage, encodePath(bgi.path));
		}
		auto are = cast(Area) path;
		if (are) {
			img = _prop.images.area;
			text = .tryFormat(_prop.msgs.searchResultIds, _prop.msgs.area, are.id, are.name);
		}
		auto bat = cast(Battle) path;
		if (bat) {
			img = _prop.images.battle;
			text = .tryFormat(_prop.msgs.searchResultIds, _prop.msgs.battle, bat.id, bat.name);
		}
		auto pac = cast(Package) path;
		if (pac) {
			img = _prop.images.packages;
			text = .tryFormat(_prop.msgs.searchResultIds, _prop.msgs.cwPackage, pac.id, pac.name);
		}
		auto cas = cast(CastCard) path;
		if (cas) {
			img = _prop.images.casts;
			text = .tryFormat(_prop.msgs.searchResultIds, _prop.msgs.cwCast, cas.id, cas.name);
		}
		auto ski = cast(SkillCard) path;
		if (ski) {
			img = _prop.images.skill;
			text = .tryFormat(_prop.msgs.searchResultIds, _prop.msgs.skill, ski.id, ski.name);
		}
		auto ite = cast(ItemCard) path;
		if (ite) {
			img = _prop.images.item;
			text = .tryFormat(_prop.msgs.searchResultIds, _prop.msgs.item, ite.id, ite.name);
		}
		auto bea = cast(BeastCard) path;
		if (bea) {
			img = _prop.images.beast;
			text = .tryFormat(_prop.msgs.searchResultIds, _prop.msgs.beast, bea.id, bea.name);
		}
		auto inf = cast(InfoCard) path;
		if (inf) {
			img = _prop.images.info;
			text = .tryFormat(_prop.msgs.searchResultIds, _prop.msgs.info, inf.id, inf.name);
		}
		auto con = cast(Content) path;
		if (con && !par) {
			img = _prop.images.content(con.type);
			text = .contentText(_comm, con);
		}
		auto tex = cast(TextHolder) path;
		if (tex && !par) {
			Content c = cast(Content) tex.owner;
			if (!c) {
				auto dlg = cast(SDialog) tex.owner;
				if (dlg) c = dlg.parent;
			}
			if (c) {
				img = _prop.images.content(c.type);
				text = .contentText(_comm, c);
			}
		}
		auto sdlg = cast(SDialog) path;
		if (sdlg && !par) {
			con = sdlg.parent;
			assert (con);
			img = _prop.images.content(con.type);
			string t = std.array.replace(sdlg.text, "\n", "");
			if (sdlg.rCoupons.length) {
				text = .tryFormat(_prop.msgs.dialogText, t, std.string.join(sdlg.rCoupons.dup, " "));
			} else {
				text = .tryFormat(_prop.msgs.dialogTextNoCoupon, t);
			}
		}
		auto fla = cast(Flag) path;
		if (fla && !par) {
			img = _prop.images.flag;
			text = .tryFormat(_prop.msgs.searchResultFlag, fla.path);
		}
		auto ste = cast(Step) path;
		if (ste && !par) {
			img = _prop.images.step;
			text = .tryFormat(_prop.msgs.searchResultStep, ste.path);
		}
		auto fld = cast(FlagDir) path;
		if (fld && !par) {
			img = _prop.images.flagDir;
			text = .tryFormat(_prop.msgs.searchResultFlagDir, fld.path);
		}
		auto eve = cast(EventTree) path;
		if (eve && !par) {
			img = _prop.images.eventTree;
			text = .tryFormat(_prop.msgs.searchResultEventTree, eve.name);
		}
		auto men = cast(MenuCard) path;
		if (men) {
			img = _prop.images.cards;
			text = .tryFormat(_prop.msgs.searchResultMenuCard, men.name);
		}
		auto ene = cast(EnemyCard) path;
		if (ene) {
			img = _prop.images.cards;
			string cName = _prop.msgs.noSelectCast;
			if (0 != ene.id) {
				auto card = _summ.cwCast(ene.id);
				if (card) {
					cName = card ? card.name : .tryFormat(_prop.msgs.noCast, ene.id);
				}
			}
			text = .tryFormat(_prop.msgs.searchResultEnemyCard, cName);
		}
		assert (par || img);
		string parText = "";
		Image parImg;
		getPathParams(path.cwxParent, parText, parImg, true);
		if (parText != "") {
			if (text == "") {
				text = parText;
			} else {
				text ~= " @ " ~ parText;
			}
		}
	}
	private void addResult(CWXPath path, string desc = "", int index = -1) {
		auto itm = new TableItem(_result, SWT.NONE, -1 == index ? _result.getItemCount() : index);
		string text;
		Image img;
		getPathParams(path, text, img);
		itm.setImage(img);
		if (desc.length) text = desc ~ " - " ~ text;
		itm.setText(text);
		itm.setData(new CWXPathString(path, path.cwxPath(true)));
	}
	private void addResult(string name, Image image, int index = -1) {
		auto itm = new TableItem(_result, SWT.NONE, -1 == index ? _result.getItemCount() : index);
		itm.setText(name);
		itm.setImage(image);
	}
	private bool repl(CWXPath path, string text, void delegate(string) set, ref size_t count, ref Undo[] uArr, bool storeToArr = false) {
		auto c = fTextCount(text);
		count += c;
		if (c > 0) {
			string n;
			if (_replMode && set) {
				n = fTextRepl(text);
				if (!path || storeToArr) uArr ~= new StrUndo(text, n, set);
				set(n);
			}
			if (path) {
				if (_replMode && set && !storeToArr) store(path, text, n, set);
				addResult(path);
			}
			return true;
		}
		return false;
	}
	private bool replFilePath(string text, void delegate(string) set, ref size_t count, ref Undo[] uArr) {
		auto c = fTextCount(encodePath(text));
		count += c;
		if (c > 0) {
			if (_replMode) {
				auto o = decodePath(text);
				string n = fTextRepl(o);
				uArr ~= new StrUndo(o, n, set);
				set(n);
			}
			return true;
		}
		return false;
	}

	private bool replFlagName(F)(FlagDir parent, F flag, ref size_t count, ref Undo[] uArr) {
		string text = flag.name;
		auto c = fTextCount(text);
		count += c;
		if (c > 0) {
			if (_replMode) {
				string oldPath = flag.path;
				string n = fTextRepl(text);
				uArr ~= new StrUndo(text, n, (string name) {
					auto parent = flag.parent;
					if (parent) {
						flag.name = parent.validName(name);
					} else {
						flag.name = name;
					}
				});
				flag.name = parent.validName(n);
				_after ~= {
					string newPath = flag.path;
					auto oldID = F.toID(oldPath);
					auto newID = F.toID(newPath);
					foreach (v; _summ.useCounter.values(oldID)) {
						v.id = newID;
						storeID(null, v, oldID, newID, &v.id);
					}
				};
			}
			return true;
		}
		return false;
	}

	private bool replRqCoupons(C)(CWXPath path, C targ, ref size_t count, ref Undo[] uArr, bool storeToArr = false) {
		string[] coupons = targ.rCoupons;
		string[] old = coupons.dup;
		bool r = false;
		foreach (i, cp; coupons) {
			Undo[] nArr;
			r |= repl(null, cp, (string t) {cp = t;}, count, nArr);
			if (_replMode) coupons[i] = cp;
		}
		if (r) {
			if (_replMode) {
				if (!path || storeToArr) uArr ~= new StrArrUndo(old, coupons.dup, &targ.rCoupons);
				targ.rCoupons = coupons;
			}
			if (path) {
				if (_replMode && !storeToArr) store(path, old, coupons.dup, &targ.rCoupons);
				addResult(targ);
			}
			return true;
		}
		return false;
	}

	private bool replKeyCode(C)(CWXPath path, C targ, ref size_t count, ref Undo[] uArr) {
		if (_keyCode.getSelection()) {
			auto kcs = targ.keyCodes.dup;
			auto old = targ.keyCodes.dup;
			bool r = false;
			Undo[] nArr;
			foreach (i, kc; kcs) {
				r |= repl(null, kc, (string t) {kc = t;}, count, nArr);
				if (_replMode) kcs[i] = kc;
			}
			if (r) {
				if (_replMode) {
					if (!path) uArr ~= new StrArrUndo(old, kcs.dup, &targ.keyCodes);
					targ.keyCodes = kcs;
				}
				if (path) {
					if (_replMode) store(path, old, kcs.dup, &targ.keyCodes);
					addResult(path);
				}
				return true;
			}
		}
		return false;
	}

	private bool replBgImage(CWXPath path, BgImage back, ref size_t count, ref Undo[] uArr) {
		bool r = false;
		Undo[] uArr2;
		if (_flag.getSelection()) {
			r |= repl(null, back.flag, &back.flag, count, uArr2);
		}
		if (_file.getSelection()) {
			r |= replFilePath(back.path, &back.path, count, uArr2);
		}
		if (r && path) {
			if (_replMode) store(path, uArr2);
			addResult(path);
		} else {
			uArr ~= uArr2;
		}
		return r;
	}
	private bool replCard(C)(CWXPath path, C card, ref size_t count, ref Undo[] uArr) {
		bool r = false;
		Undo[] uArr2;
		if (_cardName.getSelection()) {
			r |= repl(null, card.name, &card.name, count, uArr2);
		}
		if (_cardDesc.getSelection()) {
			r |= repl(null, card.desc, &card.desc, count, uArr2);
		}
		if (_flag.getSelection()) {
			static if (is (C : IFlagUser)) {
				r |= repl(null, card.flag, &card.flag, count, uArr2);
			}
		}
		if (_file.getSelection()) {
			r |= replFilePath(card.path, &card.path, count, uArr2);
		}
		static if (is (C : EffectCard)) {
			r |= replKeyCode!(C)(null, card, count, uArr2);
		}
		if (r && path) {
			if (_replMode) store(path, uArr2);
			addResult(path);
		} else {
			uArr ~= uArr2;
		}
		return r;
	}
	void replContent(Content e, ref size_t count) {
		auto eo = e.parent;
		assert (!eo || eo.detail.owner);
		bool r = false;
		Undo[] uArr2;
		if (_event.getSelection() && (!eo || eo.detail.nextType == CNextType.TEXT)) {
			r |= repl(null, e.name, &e.name, count, uArr2);
		}
		if (_flag.getSelection()) {
			// Flag/StepについてはUseCounter経由で置換される
			r |= repl(null, e.flag, null, count, uArr2);
			r |= repl(null, e.step, null, count, uArr2);
		}
		if (_start.getSelection()) {
			r |= repl(null, e.start, &e.start, count, uArr2);
			if (e.type == CType.START) {
				r |= repl(null, e.name, &e.name, count, uArr2);
			}
		}
		if (_coupon.getSelection()) {
			r |= repl(null, e.coupon, &e.coupon, count, uArr2);
		}
		if (_gossip.getSelection()) {
			r |= repl(null, e.gossip, &e.gossip, count, uArr2);
		}
		if (_end.getSelection()) {
			r |= repl(null, e.completeStamp, &e.completeStamp, count, uArr2);
		}
		if (_msg.getSelection()) {
			r |= repl(null, e.text, &e.text, count, uArr2);
		}
		bool replInText(ITextHolder th, ref Undo[] uArr) {
			Undo[] nArr;
			bool r = false;
			string old = th.text;
			if (_file.getSelection()) {
				auto ps = th.fontsInText;
				foreach (i, p; ps) {
					auto c = decodeFontPath(p);
					string ext = cwx.utils.getExt(p);
					r |= repl(null, .to!string(c), (string s) {
						dstring ds = .to!dstring(s);
						if (!ds.length) return;
						th.changeInText(i, toPathId(encodeFontPath(ds[0], ext)));
					}, count, nArr);
				}
				uArr ~= new StrUndo(old, th.text, &th.text);
			}
			if (_flag.getSelection() && !_msg.getSelection()) {
				auto fps = th.flagsInText;
				foreach (i, p; fps) {
					r |= repl(null, p, null, count, nArr);
				}
				auto sps = th.stepsInText;
				foreach (i, p; sps) {
					r |= repl(null, p, null, count, nArr);
				}
			}
			return r;
		}
		r |= replInText(e, uArr2);
		bool rDlg = false;
		if (_msg.getSelection() || _coupon.getSelection() || _file.getSelection() || _flag.getSelection()) {
			auto dlgs = e.dialogs;
			foreach (dlg; dlgs) {
				Undo[] uArrDlg;
				auto put = dlg;
				if (_msg.getSelection() && repl(dlg, dlg.text, &dlg.text, count, uArrDlg, true)) {
					rDlg = true;
					put = null;
				}
				if (_coupon.getSelection() && replRqCoupons!(typeof(dlg))(put, dlg, count, uArrDlg, true)) {
					rDlg = true;
					put = null;
				}
				if (replInText(dlg, uArrDlg)) {
					if (put) addResult(put);
					rDlg = true;
					put = null;
				}
				if (_replMode && !put) {
					store(dlg, uArrDlg);
				}
			}
		}
		if (_file.getSelection()) {
			r |= replFilePath(e.cardPath, &e.cardPath, count, uArr2);
			r |= replFilePath(e.bgmPath, &e.bgmPath, count, uArr2);
			r |= replFilePath(e.soundPath, &e.soundPath, count, uArr2);
		}
		if (_comment.getSelection()) {
			r |= repl(null, e.comment, &e.comment, count, uArr2);
		}
		if (r) {
			if (_replMode) {
				store(e, uArr2);
			}
			addResult(e);
		}
	}
}
