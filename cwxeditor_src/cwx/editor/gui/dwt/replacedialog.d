
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
import cwx.menu;
import cwx.jpy;
import cwx.cab;
import cwx.features;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;

import std.ascii;
import std.conv;
import std.array;
import std.string;
import std.file;
import std.path;
import std.regex : Regex, regex, RegexMatch, match;
import std.utf;
import std.algorithm : uniq;
import std.traits;

import org.eclipse.swt.all;

import java.lang.all;

private class CWXPathString {
	string scPath;
	CWXPath path;
	string array;
	this (string scPath, CWXPath path, string array) {
		this.scPath = scPath;
		this.path = path;
		this.array = array;
	}
}
private class FilePathString {
	string scPath;
	string array;
	this (string scPath, string array) {
		this.scPath = scPath;
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
			size_t dmy = 0;
			foreach_reverse (u; _uArr) u.undo();
			if (_path) addResult(_path, dmy);
			if (_filePath) addResult(_filePath, dmy);
		}
		void redo() {
			size_t dmy = 0;
			foreach_reverse (u; _uArr) u.redo();
			if (_path) addResult(_path, dmy);
			if (_filePath) addResult(_filePath, dmy);
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
	bool _inUndo = false;
	Undo[] _rUndo;
	void delegate()[] _after;
	core.thread.Thread _uiThread;

	Commons _comm;
	Props _prop;
	Summary _summ;
	UndoManager _undo;

	Summary _grepSumm = null;
	Skin _grepSkin = null;
	string _grepFile = "";
	bool _inGrep = false;

	bool _cancel = false;

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
	CTabItem _tabGrep;
	Button _find;
	Button _replace;
	Button _close;
	Button _rangeAllCheck;

	bool ignoreMod = false;

	Composite _textGrp1, _textGrp2, _textFromComp, _grepFromComp;
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
	Combo _grepDir;
	Button _grepSubDir;

	Button _notIgnoreCase;
	Button _useRegex;
	Button _useWildcard;
	Button _exact;
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

	Button[] _noSummText;

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

	bool _notIgnoreCaseSel;
	bool _exactSel;
	bool _summarySel;
	bool _msgSel;
	bool _cardNameSel;
	bool _cardDescSel;
	bool _eventSel;
	bool _startSel;
	bool _flagSel;
	bool _couponSel;
	bool _gossipSel;
	bool _endSel;
	bool _areaSel;
	bool _keyCodeSel;
	bool _fileSel;
	bool _commentSel;
	string _fromText;
	string _toText;

	bool _flagDirOnRange = false;

	bool _resultRedraw = true;
	void resultRedraw(bool val) {
		if (!_win || _win.isDisposed()) return;
		if (_resultRedraw !is val) {
			_resultRedraw = val;
			_result.setRedraw(val);
		}
	}

	class AddResultPath : Runnable {
		size_t count = 0;
		string path;
		string desc;
		void run() {
			if (cancel) return;
			if (!_win || _win.isDisposed()) return;
			if (_inProc && !_prop.var.etc.searchResultRealtime) resultRedraw(false);
			auto itm = new TableItem(_result, SWT.NONE);
			auto summ = _grepSumm ? _grepSumm : _summ;
			auto fullPath = std.path.buildPath(summ.scenarioPath, path);
			if (_grepSumm) {
				if (!_grepSkin) _grepSkin = findSkin(_comm, _prop, summ);
				itm.setImage(fimage(fullPath, _grepSkin));
			} else {
				itm.setImage(fimage(fullPath, _comm.skin));
			}
			string scPath = null;
			string text = encodePath(path);
			itm.setText(0, text);
			if (desc.length) {
				itm.setText(2, desc);
				itm.setImage(2, _prop.images.warning);
			}
			if (_grepSumm) {
				scPath = _grepSumm.useTemp ? _grepSumm.zipName : _grepSumm.scenarioPath;
				text = .tryFormat(_prop.msgs.grepScenario, _grepSumm.scenarioName, scPath);
				itm.setText(2, text);
				itm.setImage(2, _prop.images.summary);
			}
			itm.setData(new FilePathString(scPath, path));
			refResultStatus(count, false);
		}
	}
	class AddResultCWXPath : Runnable {
		CWXPath path;
		int index;
		string desc;
		size_t count = 0;
		void run() {
			if (cancel) return;
			if (!_win || _win.isDisposed()) return;
			if (_inProc && !_prop.var.etc.searchResultRealtime) resultRedraw(false);
			auto itm = new TableItem(_result, SWT.NONE, -1 == index ? _result.getItemCount() : index);
			string text1, text2;
			Image img1, img2;
			getPathParams(path, text1, text2, img1, img2);
			itm.setImage(0, img1);
			itm.setText(0, text1);
			itm.setImage(1, img2);
			itm.setText(1, text2);
			if (desc.length) {
				itm.setText(2, desc);
				itm.setImage(2, _prop.images.warning);
			}
			string scPath = null;
			if (_grepSumm) {
				scPath = _grepSumm.useTemp ? _grepSumm.zipName : _grepSumm.scenarioPath;
				itm.setText(2, .tryFormat(_prop.msgs.grepScenario, _grepSumm.scenarioName, scPath));
				itm.setImage(2, _prop.images.summary);
			}
			itm.setData(new CWXPathString(scPath, _grepSumm ? null : path, path.cwxPath(true)));
			refResultStatus(count, false);
		}
	}
	class AddResultMsg : Runnable {
		string name;
		Image delegate() image;
		int index;
		size_t count = 0;
		void run() {
			if (cancel) return;
			if (!_win || _win.isDisposed()) return;
			if (_inProc && !_prop.var.etc.searchResultRealtime) resultRedraw(false);
			auto itm = new TableItem(_result, SWT.NONE, -1 == index ? _result.getItemCount() : index);
			itm.setText(name);
			itm.setImage(image());
			refResultStatus(count, false);
		}
	}
	class AddResultUse : Runnable {
		string name;
		uint use;
		Image delegate() image;
		int index;
		size_t count = 0;
		void run() {
			if (cancel) return;
			if (!_win || _win.isDisposed()) return;
			if (_inProc && !_prop.var.etc.searchResultRealtime) resultRedraw(false);
			auto itm = new TableItem(_result, SWT.NONE, -1 == index ? _result.getItemCount() : index);
			itm.setText(0, name);
			itm.setImage(0, image());
			itm.setText(1, .text(use));
			refResultStatus(count, false);
		}
	}
	Display _display;

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
		if (!_summ) {
			_fromID.removeAll();
			_fromID.setEnabled(false);
			_fromIDVal.setEnabled(false);
			_toID.removeAll();
			_toID.setEnabled(false);
			_toIDVal.setEnabled(false);
			return;
		}
		_fromID.setEnabled(true);
		_toID.setEnabled(true);
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
		if (!_summ) return [];
		return _summ.allMaterials(_comm.skin, _prop.var.etc.ignorePaths, _prop.var.etc.logicalSort, scenarioOnly);
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
			updateDefaultButton();
		}
	}
	class SelID : SelectionAdapter {
		private Spinner _spn;
		this (Spinner spn) {_spn = spn;}
		override void widgetSelected(SelectionEvent e) {
			auto combo = cast(Combo) e.widget;
			_spn.setEnabled(combo.getSelectionIndex() == 0);
			_comm.refreshToolBar();
			updateDefaultButton();
		}
	}
	class SelIDKind : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			setupIDs();
			_prop.var.etc.searchIDKind = _idKind.getSelectionIndex();
			_comm.refreshToolBar();
			updateDefaultButton();
		}
	}
	private void tabChanged() {
		auto sel = _tabf.getSelection();
		if (!sel) return;

		_parent.setRedraw(false);
		scope (exit) _parent.setRedraw(true);

		_prop.var.etc.searchPlan = _tabf.getSelectionIndex();
		if (sel is _tabText || sel is _tabGrep) {
			auto comp = _comps[sel is _tabGrep ? _tabGrep : _tabText];
			if (_textGrp1.getParent() !is comp) _textGrp1.setParent(comp);
			if (_textGrp2.getParent() !is comp) _textGrp2.setParent(comp);
			auto fromComp = sel is _tabGrep ? _grepFromComp : _textFromComp;
			if (_from.getParent() !is fromComp) {
				_from.setParent(fromComp);
			}
		}
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
		_range.setEnabled(sel !is _tabUnuse && sel !is _tabGrep);
		_rangeAllCheck.setEnabled(_range.getEnabled());
		_comm.refreshToolBar();
		updateDefaultButton();
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
			auto fl = new Label(grp, SWT.NONE);
			fl.setText(_prop.msgs.replFrom);
			_textFromComp = new Composite(grp, SWT.NONE);
			_textFromComp.setLayout(new FillLayout);
			_from = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN);
			_from.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			createTextMenu!Combo(_comm, _prop, _from, &catchMod);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_textFromComp.setLayoutData(gd);
			auto lt = new Label(grp, SWT.NONE);
			lt.setText(_prop.msgs.replTo);
			_to = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN);
			_to.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			createTextMenu!Combo(_comm, _prop, _to, &catchMod);
			_to.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}
		{
			auto grp = new Group(comp2, SWT.NONE);
			_textGrp1 = grp;
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			grp.setLayoutData(gd);
			grp.setText(_prop.msgs.replCond);
			grp.setLayout(new GridLayout(2, false));
			_notIgnoreCase = new Button(grp, SWT.CHECK);
			_notIgnoreCase.setText(_prop.msgs.replNotIgnoreCase);
			_exact = new Button(grp, SWT.CHECK);
			_exact.setText(_prop.msgs.replExactMatch);
			_useWildcard = new Button(grp, SWT.CHECK);
			_useWildcard.setText(_prop.msgs.replWildcard);
			_useWildcard.addSelectionListener(new SelWildcard);
			auto gdw = new GridData;
			gdw.horizontalSpan = 2;
			_useWildcard.setLayoutData(gdw);
			_useRegex = new Button(grp, SWT.CHECK);
			_useRegex.setText(_prop.msgs.replRegExp);
			_useRegex.addSelectionListener(new SelRegex);
			auto gdr = new GridData;
			gdr.horizontalSpan = 2;
			_useRegex.setLayoutData(gdr);
		}
		{
			auto grp = new Group(comp2, SWT.NONE);
			_textGrp2 = grp;
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			grp.setLayoutData(gd);
			grp.setText(_prop.msgs.replTextTarget);
			grp.setLayout(zeroGridLayout(1, true));
			auto checked = new LCheck;
			_checked ~= checked;
			{
				auto btns = addButtonLine(grp);
				Button createB(string text, char accr, bool summ = false) {
					auto b = new Button(btns, SWT.CHECK);
					b.setText(text ~ "(&" ~ accr ~ ")");
					checked.buttons ~= b;
					b.addSelectionListener(checked);
					if (!summ) _noSummText ~= b;
					return b;
				}
				_summary = createB(_prop.msgs.replTextSummary, '1', true);
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
	void constructGrep(CTabFolder tabf) {
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
			grp.setText(_prop.msgs.grepText);
			grp.setLayout(new GridLayout(2, false));
			auto fl = new Label(grp, SWT.NONE);
			fl.setText(_prop.msgs.grepFrom);
			_grepFromComp = new Composite(grp, SWT.NONE);
			_grepFromComp.setLayout(new FillLayout);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_grepFromComp.setLayoutData(gd);
		}
		{
			auto grp = new Group(comp2, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setText(_prop.msgs.grepTarget);
			grp.setLayout(new GridLayout(4, false));

			_grepDir = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN);
			_grepDir.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			createTextMenu!Combo(_comm, _prop, _grepDir, &catchMod);
			_grepDir.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			auto grepDirRef = new Button(grp, SWT.PUSH);
			grepDirRef.setText(_prop.msgs.reference);
			.listener(grepDirRef, SWT.Selection, {
				selectDir(_prop, _grepDir, _prop.msgs.grepDir, _prop.msgs.grepDirDesc, _grepDir.getText());
			});
			createOpenButton(_comm, grp, {return _prop.toAppAbs(_grepDir.getText());}, true);

			auto grepCurrent = new Button(grp, SWT.PUSH);
			grepCurrent.setText(_prop.msgs.grepCurrent);
			.listener(grepCurrent, SWT.Selection, &setGrepCurrentDir);
			_grepSubDir = new Button(grp, SWT.CHECK);
			auto gd = new GridData(GridData.HORIZONTAL_ALIGN_END);
			gd.horizontalSpan = 4;
			_grepSubDir.setLayoutData(gd);
			_grepSubDir.setText(_prop.msgs.grepSubDir);
			.listener(_grepDir, SWT.Modify, {
				if (ignoreMod) return;
				_prop.var.etc.grepDir = _grepDir.getText();
			});
			.listener(_grepSubDir, SWT.Selection, {
				if (ignoreMod) return;
				_prop.var.etc.grepSubDir = _grepSubDir.getSelection();
			});
		}

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText(_prop.msgs.replGrep);
		tab.setControl(comp);
		_tabGrep = tab;

		auto gd = new GridData(GridData.FILL_BOTH);
		comp2.setLayoutData(gd);
		_comps[tab] = comp2;
	}
	void setGrepCurrentDir() {
		if (_summ) {
			auto sc = _summ.scenarioPath.dirName();
			if (_summ.useTemp) sc = _summ.zipName.dirName();
			_grepDir.setText(sc);
		}
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
	static CWXPath[] rangeTree(Summary summ) {
		CWXPath[] r;
		r ~= summ;
		r ~= summ.flagDirRoot;
		foreach (a; summ.areas) r ~= a;
		foreach (a; summ.battles) r ~= a;
		foreach (a; summ.packages) r ~= a;
		foreach (a; summ.casts) {
			r ~= a;
			foreach (c; a.skills) {
				if (0 != c.linkId) continue;
				r ~= c;
			}
			foreach (c; a.items) {
				if (0 != c.linkId) continue;
				r ~= c;
			}
			foreach (c; a.beasts) {
				if (0 != c.linkId) continue;
				r ~= c;
			}
		}
		foreach (a; summ.skills) r ~= a;
		foreach (a; summ.items) r ~= a;
		foreach (a; summ.beasts) r ~= a;
		foreach (a; summ.infos) r ~= a;
		return r;
	}
	void refreshRangeTree() {
		if (!_summ) {
			_range.removeAll();
			return;
		}
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
			string text1, text2;
			Image img1, img2;
			getPathParams(path, text1, text2, img1, img2, false);
			itm.setText(name);
			itm.setImage(img1);
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
		updateDefaultButton();
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
		_uiThread = core.thread.Thread.getThis();
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

		_display = shell.getDisplay();

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
			setupIDs();
		}
		_undo.reset();
		_comm.refreshToolBar();
		updateDefaultButton();
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
		} else if (tab is _tabGrep) {
			_from.setFocus();
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
			constructGrep(_tabf);
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
			auto comp = new Composite(left, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(2, false));
			comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			auto realtime = new Button(comp, SWT.CHECK);
			realtime.setText(_prop.msgs.searchResultRealtime);
			realtime.setSelection(_prop.var.etc.searchResultRealtime);
			.listener(realtime, SWT.Selection, {
				_prop.var.etc.searchResultRealtime = realtime.getSelection();
				if (_prop.var.etc.searchResultRealtime) {
					resultRedraw(true);
				} else if (_inProc) {
					resultRedraw(false);
				}
			});
			auto openDlg = new Button(comp, SWT.CHECK);
			openDlg.setText(_prop.msgs.searchOpenDialog);
			openDlg.setSelection(_prop.var.etc.searchOpenDialog);
			openDlg.addSelectionListener(new class SelectionAdapter {
				override void widgetSelected(SelectionEvent e) {
					_prop.var.etc.searchOpenDialog = openDlg.getSelection();
				}
			});
		}
		{
			auto grp = new Group(right, SWT.NONE);
			grp.setText(_prop.msgs.searchRange);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(1, true));
			_range = new Tree(grp, SWT.SINGLE | SWT.BORDER | SWT.VIRTUAL | SWT.CHECK);
			initTree(_comm, _range, false);
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
			auto gl = new GridLayout(4, true);
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
			_replace = createButton(_prop.msgs.replace, &replace);
			_comm.put(_replace, &canReplace);
			_close = createButton(_prop.msgs.replaceExit, &exit);
			auto cancel = createButton(_prop.msgs.searchCancel, {
				_cancel = true;
				resultRedraw(true);
			});
			_comm.put(cancel, &canCancel);
			updateDefaultButton();
		}

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		setComboItems(_from, _prop.var.etc.searchHistories.dup);
		setComboItems(_to, _prop.var.etc.replaceHistories.dup);
		setComboItems(_grepDir, _prop.var.etc.grepDirHistories.dup);
		_notIgnoreCase.setSelection(_prop.var.etc.replaceTextNotIgnoreCase);
		_exact.setSelection(_prop.var.etc.replaceTextExactMatch);
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
		if (_prop.var.etc.grepDir.length) {
			_grepDir.setText(_prop.var.etc.grepDir);
		} else {
			setGrepCurrentDir();
		}
		_grepSubDir.setSelection(_prop.var.etc.grepSubDir);

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
		_contents[CType.SUBSTITUTE_STEP].setSelection(_prop.var.etc.searchContentsSubstituteStep);
		_contents[CType.SUBSTITUTE_FLAG].setSelection(_prop.var.etc.searchContentsSubstituteFlag);
		_contents[CType.BRANCH_STEP_CMP].setSelection(_prop.var.etc.searchContentsBranchStepCmp);
		_contents[CType.BRANCH_FLAG_CMP].setSelection(_prop.var.etc.searchContentsBranchFlagCmp);
		_contents[CType.BRANCH_RANDOM_SELECT].setSelection(_prop.var.etc.searchContentsBranchRandomSelect);

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
	private void updateDefaultButton() {
		if (!_find || !_close) return;
		_win.setDefaultButton(_find);
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
			_cancel = true;
			_comm.changed.remove(&changed);
			_comm.refScenario.remove(&summary);
			saveWin();
			_prop.var.etc.replaceTextNotIgnoreCase = _notIgnoreCase.getSelection();
			_prop.var.etc.replaceTextExactMatch = _exact.getSelection();
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
			_prop.var.etc.searchContentsSubstituteStep = _contents[CType.SUBSTITUTE_STEP].getSelection();
			_prop.var.etc.searchContentsSubstituteFlag = _contents[CType.SUBSTITUTE_FLAG].getSelection();
			_prop.var.etc.searchContentsBranchStepCmp = _contents[CType.BRANCH_STEP_CMP].getSelection();
			_prop.var.etc.searchContentsBranchFlagCmp = _contents[CType.BRANCH_FLAG_CMP].getSelection();
			_prop.var.etc.searchContentsBranchRandomSelect = _contents[CType.BRANCH_RANDOM_SELECT].getSelection();

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
		if (!_inUndo && !_inProc) {
			_undo.reset();
		}
		auto thr = core.thread.Thread.getThis();
		if (&_uiThread !is &thr) return;
		if (_inGrep) return;
		if (_inUndo) return;
		if (_inProc) {
			_cancel = true;
		} else {
			_comm.refreshToolBar();
			updateDefaultButton();
		}
	}
	private void undo() {
		if (!_undo.canUndo) return;
		scope (exit) {
			_comm.refreshToolBar();
			updateDefaultButton();
		}
		_inProc = true;
		scope (exit) _inProc = false;
		_inUndo = true;
		scope (exit) _inUndo = false;
		resultRedraw(false);
		scope (exit) resultRedraw(true);
		reset(false);
		_undo.undo();
		refContentText();
		_status.setText(.tryFormat(_prop.msgs.replaceUndo, .formatNum(_result.getItemCount())));
		_comm.replText.call();
	}
	private void redo() {
		if (!_undo.canRedo) return;
		scope (exit) {
			_comm.refreshToolBar();
			updateDefaultButton();
		}
		_inProc = true;
		scope (exit) _inProc = false;
		_inUndo = true;
		scope (exit) _inUndo = false;
		resultRedraw(false);
		scope (exit) resultRedraw(true);
		reset(false);
		_undo.redo();
		refContentText();
		_status.setText(.tryFormat(_prop.msgs.replaceRedo, .formatNum(_result.getItemCount())));
		_comm.replText.call();
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
	private void reset(bool removeColumns = true) {
		if (!_inUndo && !_inProc) {
			_undo.reset();
		}
		_result.removeAll();
		if (removeColumns && _result.getColumnCount()) {
			foreach (column; _result.getColumns()) {
				column.dispose();
			}
			_result.setHeaderVisible(false);
		}
		if (_replMode) {
			_status.setText(_prop.msgs.replResultEmpty);
		} else {
			_status.setText(_prop.msgs.searchResultEmpty);
		}
		_comm.refreshToolBar();
		updateDefaultButton();
	}
	@property
	private bool canFind() {
		if (_inProc) return false;
		if (!_tabf || _tabf.isDisposed()) return false;
		auto sel = _tabf.getSelection();
		if (!sel) return false;
		if (sel is _tabText) {
			return _summ && _from.getText().length > 0;
		} else if (sel is _tabID) {
			return _summ && getID(_fromID, _fromIDVal, _fromIDTbl) !is 0;
		} else if (sel is _tabPath) {
			return _summ && _fromPath.getText().length > 0;
		} else if (sel is _tabContents) {
			return _summ !is null;
		} else if (sel is _tabCoupon) {
			return _summ !is null;
		} else if (sel is _tabUnuse) {
			return _summ !is null;
		} else if (sel is _tabError) {
			return _summ !is null;
		} else if (sel is _tabGrep) {
			return true;
		} else assert (0);
	}
	@property
	private bool canReplace() {
		if (_inProc) return false;
		if (!_tabf || _tabf.isDisposed()) return false;
		auto sel = _tabf.getSelection();
		if (!sel) return false;
		if (!_summ) return false;
		return canFind && (sel is _tabText || sel is _tabID || sel is _tabPath);
	}
	private bool canCancel() {
		return _inProc;
	}
	private void replaceImpl() {
		_rUndo.length = 0;
		_after.length = 0;

		_notIgnoreCaseSel = _notIgnoreCase.getSelection();
		_exactSel = _exact.getSelection();
		_summarySel = _summary.getSelection();
		_msgSel = _msg.getSelection();
		_cardNameSel = _cardName.getSelection();
		_cardDescSel = _cardDesc.getSelection();
		_eventSel = _event.getSelection();
		_startSel = _start.getSelection();
		_flagSel = _flag.getSelection();
		_couponSel = _coupon.getSelection();
		_gossipSel = _gossip.getSelection();
		_endSel = _end.getSelection();
		_areaSel = _area.getSelection();
		_keyCodeSel = _keyCode.getSelection();
		_fileSel = _file.getSelection();
		_commentSel = _comment.getSelection();
		_fromText = _from.getText();
		_toText = _to.getText();

		_flagDirOnRange = false;
		foreach (itm; _range.getItems()) {
			if (itm.getChecked()) {
				auto root = cast(FlagDir) itm.getData();
				if (root) {
					_flagDirOnRange = true;
					break;
				}
			}
		}

		_cancel = false;
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
		} else if (_tabf.getSelection() is _tabGrep) {
			grepImpl();
		} else assert (0);
	}
	private void after() {
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
		updateDefaultButton();
	}
	@property
	private CWXPath[] searchRange() {
		CWXPath[] r;
		void recurse(TreeItem itm) {
			r ~= cast(CWXPath) itm.getData();
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
		return r;
	}
	private void searchAll(CWXPath path, ref uint count,
			void delegate(CWXPath path, ref uint count) dlg) {
		if (cancel) return;
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

	@property
	private bool cancel() {
		return _cancel;
	}

	private void setResultStatus(uint count) {
		if (count > 0) {
			if (_replMode && _summ) {
				_summ.changed();
				_comm.refUseCount.call();
			}
		}
		_inProc = false;
		resultRedraw(true);
		refResultStatus(count, true);
	}
	private void refResultStatus(uint count, bool force) {
		if (!_prop.var.etc.searchResultRealtime) {
			if (!force && 0 != (count % _prop.var.etc.searchResultRefreshCount)) return;
		}
		_display.syncExec(new class Runnable {
			void run() {
				if (!_win || _win.isDisposed()) return;
				if (!_tabf.getSelection()) return;
				string text;
				string num = .formatNum(count);
				if (_replMode) {
					string kind = _tabf.getSelection().getText();
					text = .tryFormat(_prop.msgs.replResult, num, kind);
				} else {
					if (_grepSumm) {
						text = .tryFormat(_prop.msgs.searchResultGrep2, num, _grepFile);
					} else if (_grepFile.length) {
						text = .tryFormat(_prop.msgs.searchResultGrep1, num, _grepFile);
					} else {
						string kind = _tabf.getSelection().getText();
						text = .tryFormat(_prop.msgs.searchResult, num, kind);
					}
				}
				_status.setText(text);
			}
		});
	}
	@property
	private bool[CWXPath] rangeTable() {
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
		return range;
	}
	private bool dec(CWXPath path, in bool[CWXPath] range) {
		assert (path);
		auto p = path in range;
		if (p) {
			return *p;
		}
		return dec(path.cwxParent, range);
	}
	private void replaceIDImpl2(ID)(ID from, ID to) {
		if (!_summ) return;
		reset();

		static if (is(ID:PathId)) {
			new FullTableColumn(_result, SWT.NONE);
		} else {
			_result.setHeaderVisible(true);
			auto mainColumn = new TableColumn(_result, SWT.NONE);
			mainColumn.setText(_prop.msgs.searchResultColumnMain);
			saveColumnWidth!("prop.var.etc.searchResultColumnMain")(_prop, mainColumn);
			auto subColumn = new TableColumn(_result, SWT.NONE);
			subColumn.setText(_prop.msgs.searchResultColumnParent);
			saveColumnWidth!("prop.var.etc.searchResultColumnParent")(_prop, subColumn);
		}

		auto range = rangeTable;

		auto uc = _summ.useCounter;
		auto users = uc.values(from);
		_inProc = true;
		scope (exit) _inProc = false;
		size_t count = 0;

		auto cursors = setWaitCursors(_win);
		auto thr = new core.thread.Thread({
			auto exit = new class Runnable {
				override void run() {
					_inProc = false;
					setResultStatus(count);
					if (count) {
						static if (is(ID : PathId)) {
							_comm.replPath.call(cast(string) from, cast(string) to);
						} else {
							_comm.replID.call();
						}
					}
					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);

			try {
				foreach (u; users) {
					if (!dec(u.owner, range)) continue;
					if (_replMode) {
						u.id = to;
						storeID(u.owner, u, from, to, &u.id);
					}
					addResult(u.owner, count);
				}
			} catch (Throwable e) {
				debugln(e);
			}
		});
		thr.start();
	}
	private ulong getID(Combo combo, Spinner spn, ulong[int] tbl) {
		if (!_summ) return 0;
		if (combo.getSelectionIndex() == 0) {
			return spn.getSelection();
		} else {
			auto p = combo.getSelectionIndex() in tbl;
			if (!p) return 0;
			return *p;
		}
	}
	private void replaceIDImpl() {
		if (!_summ) return;
		ulong from = getID(_fromID, _fromIDVal, _fromIDTbl);
		ulong to = getID(_toID, _toIDVal, _toIDTbl);
		if (0 == from) return;
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
		if (!_summ) return;
		if (!_fromPath.getText().length) return;
		auto from = toPathId(_fromPath.getText());
		auto to = toPathId(_toPath.getText());
		if (from == to) _replMode = false;
		replaceIDImpl2(from, to);
	}

	private void searchCouponImpl(KeyType)(in KeyType[] keys, UseCounter uc, in bool[CWXPath] rangeT, Image delegate() image, ref uint count) {
		foreach (key; keys.dup.sort) {
			if (cancel) break;
			uint use = 0;
			foreach (u; uc.values(key)) {
				if (dec(u.owner, rangeT)) {
					use++;
				}
			}
			if (use) {
				addResult(key, use, image, count);
			}
		}
	}
	private void searchCoupon() {
		if (!_summ) return;
		uint count = 0;
		reset();

		_result.setHeaderVisible(true);
		auto mainColumn = new TableColumn(_result, SWT.NONE);
		mainColumn.setText(_prop.msgs.searchResultColumnCoupon);
		saveColumnWidth!("prop.var.etc.searchResultColumnMain")(_prop, mainColumn);
		auto subColumn = new TableColumn(_result, SWT.NONE);
		subColumn.setText(_prop.msgs.searchResultColumnCouponCount);
		saveColumnWidth!("prop.var.etc.searchResultColumnCouponCount")(_prop, subColumn);

		bool cCouponSel = _cCoupon.getSelection();
		bool cKeyCodeSel = _cKeyCode.getSelection();
		bool cGossipSel = _cGossip.getSelection();
		bool cEndSel = _cEnd.getSelection();

		auto rangeT = rangeTable;
		auto uc = _summ.useCounter;
		void search() {
			if (cCouponSel) {
				searchCouponImpl(uc.coupon.keys, uc, rangeT, &_prop.images.couponNormal, count);
			}
			if (cGossipSel) {
				searchCouponImpl(uc.gossip.keys, uc, rangeT, &_prop.images.gossip, count);
			}
			if (cEndSel) {
				searchCouponImpl(uc.completeStamp.keys, uc, rangeT, &_prop.images.endScenario, count);
			}
			if (cKeyCodeSel) {
				searchCouponImpl(uc.keyCode.keys, uc, rangeT, &_prop.images.keyCode, count);
			}
		}

		_inProc = true;
		_comm.refreshToolBar();
		updateDefaultButton();
		auto cursors = setWaitCursors(_win);
		auto thr = new core.thread.Thread({
			auto exit = new class Runnable {
				override void run() {
					_inProc = false;
					setResultStatus(count);
					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);
			try {
				search();
			} catch (Throwable e) {
				debugln(e);
			}
		});
		thr.start();
	}

	private void searchContents() {
		if (!_summ) return;
		uint count = 0;
		reset();

		_result.setHeaderVisible(true);
		auto mainColumn = new TableColumn(_result, SWT.NONE);
		mainColumn.setText(_prop.msgs.searchResultColumnMain);
		saveColumnWidth!("prop.var.etc.searchResultColumnMain")(_prop, mainColumn);
		auto subColumn = new TableColumn(_result, SWT.NONE);
		subColumn.setText(_prop.msgs.searchResultColumnParent);
		saveColumnWidth!("prop.var.etc.searchResultColumnParent")(_prop, subColumn);

		auto range = searchRange;

		_inProc = true;
		_comm.refreshToolBar();
		updateDefaultButton();
		auto cursors = setWaitCursors(_win);
		bool[CType] contents;
		foreach (type; EnumMembers!CType) {
			contents[type] = _contents[type].getSelection();
		}
		auto thr = new core.thread.Thread({
			auto exit = new class Runnable {
				override void run() {
					_inProc = false;
					setResultStatus(count);
					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);
			try {
				foreach (path; range) {
					searchAll(path, count, (CWXPath path, ref uint count) {
						if (cancel) return;
						auto c = cast(Content) path;
						if (!c) return;
						assert (c.type in _contents);
						if (!contents[c.type]) return;
						addResult(path, count);
					});
				}
			} catch (Throwable e) {
				debugln(e);
			}
		});
		thr.start();
	}

	private void searchUnuseImpl2(string ToId, T)(T[] all, ref uint count) {
		if (!_summ) return;
		foreach (o; all) {
			if (cancel) break;
			if (_summ.useCounter.get(mixin (ToId)) == 0) {
				addResult(o, count);
			}
		}
	}
	private void searchUnuseImpl() {
		if (!_summ) return;
		_replMode = false;
		uint count = 0;
		reset();

		new FullTableColumn(_result, SWT.NONE);

		auto range = searchRange();

		bool unuseFlagSel = _unuseFlag.getSelection();
		bool unuseStepSel = _unuseStep.getSelection();
		bool unuseAreaSel = _unuseArea.getSelection();
		bool unuseBattleSel = _unuseBattle.getSelection();
		bool unusePackageSel = _unusePackage.getSelection();
		bool unuseCastSel = _unuseCast.getSelection();
		bool unuseSkillSel = _unuseSkill.getSelection();
		bool unuseItemSel = _unuseItem.getSelection();
		bool unuseBeastSel = _unuseBeast.getSelection();
		bool unuseInfoSel = _unuseInfo.getSelection();
		bool unuseStartSel = _unuseStart.getSelection();
		bool unusePathSel = _unusePath.getSelection();

		void search() {
			if (unuseFlagSel) {
				searchUnuseImpl2!("toFlagId(o.path)")(_summ.flagDirRoot.allFlags, count);
			}
			if (unuseStepSel) {
				searchUnuseImpl2!("toStepId(o.path)")(_summ.flagDirRoot.allSteps, count);
			}
			if (unuseAreaSel) {
				searchUnuseImpl2!("toAreaId(o.id)")(_summ.areas, count);
			}
			if (unuseBattleSel) {
				searchUnuseImpl2!("toBattleId(o.id)")(_summ.battles, count);
			}
			if (unusePackageSel) {
				searchUnuseImpl2!("toPackageId(o.id)")(_summ.packages, count);
			}
			if (unuseCastSel) {
				searchUnuseImpl2!("toCastId(o.id)")(_summ.casts, count);
			}
			if (unuseSkillSel) {
				searchUnuseImpl2!("toSkillId(o.id)")(_summ.skills, count);
			}
			if (unuseItemSel) {
				searchUnuseImpl2!("toItemId(o.id)")(_summ.items, count);
			}
			if (unuseBeastSel) {
				searchUnuseImpl2!("toBeastId(o.id)")(_summ.beasts, count);
			}
			if (unuseInfoSel) {
				searchUnuseImpl2!("toInfoId(o.id)")(_summ.infos, count);
			}
			if (unuseStartSel) {
				foreach (path; range) {
					searchAll(path, count, (CWXPath path, ref uint count) {
						if (cancel) return;
						auto et = cast(EventTree) path;
						if (et) {
							foreach (s; et.starts[1 .. $]) {
								if (et.startUseCounter.get(toStartId(s.name)) == 0) {
									addResult(s, count);
								}
							}
						}
					});
				}
			}
			if (unusePathSel) {
				auto files = _summ.notUsedFiles(_comm.skin, _prop.var.etc.ignorePaths, _prop.var.etc.logicalSort);
				foreach (file; files) {
					if (cancel) break;
					addResult(encodePath(file), count);
				}
			}
		}

		_inProc = true;
		_comm.refreshToolBar();
		updateDefaultButton();
		auto cursors = setWaitCursors(_win);
		auto thr = new core.thread.Thread({
			auto exit = new class Runnable {
				override void run() {
					_inProc = false;
					setResultStatus(count);
					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);
			try {
				search();
			} catch (Throwable e) {
				debugln(e);
			}
		});
		thr.start();
	}
	private void searchErrorImpl() {
		if (!_summ) return;
		uint count = 0;
		auto froot = _summ.flagDirRoot;
		auto sPath = _summ.scenarioPath;
		auto skin = _comm.skin;
		reset();

		_result.setHeaderVisible(true);
		auto mainColumn = new TableColumn(_result, SWT.NONE);
		mainColumn.setText(_prop.msgs.searchResultColumnError);
		saveColumnWidth!("prop.var.etc.searchResultColumnMain")(_prop, mainColumn);
		auto subColumn = new TableColumn(_result, SWT.NONE);
		subColumn.setText(_prop.msgs.searchResultColumnParent);
		saveColumnWidth!("prop.var.etc.searchResultColumnParent")(_prop, subColumn);
		auto descColumn = new TableColumn(_result, SWT.NONE);
		descColumn.setText(_prop.msgs.searchResultColumnErrorDesc);
		saveColumnWidth!("prop.var.etc.searchResultColumnErrorDesc")(_prop, descColumn);

		auto range = searchRange;

		void search(CWXPath path) {
			searchAll(path, count, (CWXPath path, ref uint count) {
				if (cancel) return;
				auto summ = cast(Summary) path;
				if (summ) {
					if (summ.imagePath != "" && !isBinImg(summ.imagePath) && !skin.findPath(summ.imagePath, skin.extImage, skin.tableDir, sPath).length) {
						addResult(path, count, _prop.msgs.searchErrorImageNotFound);
						return;
					}
					if (summ.levelMin > summ.levelMax) {
						addResult(path, count, _prop.msgs.searchErrorReversalLevel);
						return;
					}
					if (!summ.area(summ.startArea)) {
						addResult(path, count, _prop.msgs.searchErrorStartAreaNotFound);
						return;
					}
				}
				auto flagDir = cast(FlagDir) path;
				if (flagDir) {
					if (flagDir.parent is froot && _prop.sys.isSystemVar(flagDir.name)) {
						addResult(path, count, _prop.msgs.searchErrorSystemName);
						return;
					}
				}
				auto flag = cast(Flag) path;
				if (flag) {
					if (flag.parent is froot && _prop.sys.isSystemVar(flag.name)) {
						addResult(path, count, _prop.msgs.searchErrorSystemName);
						return;
					}
				}
				auto step = cast(Step) path;
				if (step) {
					if (step.parent is froot && _prop.sys.isSystemVar(step.name)) {
						addResult(path, count, _prop.msgs.searchErrorSystemName);
						return;
					}
				}
				auto casts = cast(CastCard) path;
				if (casts) {
					bool r = false;
					foreach (c; casts.skills) {
						if (0 != c.linkId && !_summ.skill(c.linkId)) {
							addResult(path, count, _prop.msgs.searchErrorLinkIdNotFound);
							r = true;
						}
					}
					foreach (c; casts.items) {
						if (0 != c.linkId && !_summ.item(c.linkId)) {
							addResult(path, count, _prop.msgs.searchErrorLinkIdNotFound);
							r = true;
						}
					}
					foreach (c; casts.beasts) {
						if (0 != c.linkId && !_summ.beast(c.linkId)) {
							addResult(path, count, _prop.msgs.searchErrorLinkIdNotFound);
							r = true;
						}
					}
					if (r) return;
				}
				auto card = cast(Card) path;
				if (card) {
					if (card.path != "" && !isBinImg(card.path) && !skin.findPath(card.path, skin.extImage, skin.tableDir, sPath).length) {
						addResult(path, count, _prop.msgs.searchErrorImageNotFound);
						return;
					}
				}
				auto bi = cast(BgImage) path;
				if (bi) {
					if (!bi.path.length) {
						addResult(path, count, _prop.msgs.searchErrorNoImage);
						return;
					}
					if (!skin.findPath(bi.path, skin.extImage, skin.tableDir, sPath).length) {
						addResult(path, count, _prop.msgs.searchErrorImageNotFound);
						return;
					}
					if (bi.flag != "" && !froot.findFlag(bi.flag)) {
						addResult(path, count, _prop.msgs.searchErrorFlagNotFound);
						return;
					}
				}
				auto mc = cast(MenuCard) path;
				if (mc) {
					if (mc.path != "" && !isBinImg(mc.path) && !skin.findPath(mc.path, skin.extImage, skin.tableDir, sPath).length) {
						addResult(path, count, _prop.msgs.searchErrorImageNotFound);
						return;
					}
					if (mc.flag != "" && !froot.findFlag(mc.flag)) {
						addResult(path, count, _prop.msgs.searchErrorFlagNotFound);
						return;
					}
					if (0 != mc.pcNumber && !_summ.legacy) {
						addResult(path, count, _prop.msgs.searchErrorPCNumber);
						return;
					}
				}
				auto ec = cast(EnemyCard) path;
				if (ec) {
					if (ec.id == 0) {
						addResult(path, count, _prop.msgs.searchErrorNoCast);
						return;
					}
					if (!_summ.cwCast(ec.id)) {
						addResult(path, count, _prop.msgs.searchErrorCastNotFound);
						return;
					}
					if (ec.flag != "" && !froot.findFlag(ec.flag)) {
						addResult(path, count, _prop.msgs.searchErrorFlagNotFound);
						return;
					}
				}
				auto c = cast(Content) path;
				if (!c) return;
				if (_summ.legacy && c.type == CType.WAIT && !c.next.length) {
					addResult(path, count, _prop.msgs.searchErrorIgnoreWait);
					return;
				}
				if (c.detail.owner && c.detail.nextType != CNextType.TEXT) {
					auto set = new HashSet!(string);
					foreach (cld; c.next) {
						if (cld.name == "") continue;
						if (set.contains(cld.name)) {
							addResult(path, count, _prop.msgs.searchErrorDupNextContent);
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
								addResult(path, count, _prop.msgs.searchErrorNoRCouponsDialog);
								return;
							}
							string err = checkTextRes(dlg.fontsInText, dlg.flagsInText, dlg.stepsInText);
							if (err) {
								addResult(path, count, err);
								return;
							}
						}
					}
				}
				string textErr = checkTextRes(c.fontsInText, c.flagsInText, c.stepsInText);
				if (textErr) {
					addResult(path, count, textErr);
					return;
				}
				bool hasStart() {
					foreach (s; c.tree.starts) {
						if (s.name == c.start) return true;
					}
					return false;
				}
				if (c.flag != "" && !froot.findFlag(c.flag)) {
					addResult(path, count, _prop.msgs.searchErrorFlagNotFound);
					return;
				}
				if (c.step != "" && !froot.findStep(c.step)) {
					addResult(path, count, _prop.msgs.searchErrorStepNotFound);
					return;
				}
				if (c.type == CType.TALK_MESSAGE && c.talkerC == Talker.IMAGE
						&& c.cardPath != "" && !skin.findPath(c.cardPath, skin.extImage, skin.tableDir, sPath).length) {
					addResult(path, count, _prop.msgs.searchErrorImageNotFound);
					return;
				}
				if (c.bgmPath != "" && !skin.findPath(c.bgmPath, skin.extBgm, skin.bgmDir, sPath).length) {
					addResult(path, count, _prop.msgs.searchErrorBGMNotFound);
					return;
				}
				if (c.soundPath != "" && !skin.findPath(c.soundPath, skin.extSound, skin.seDir, sPath).length) {
					addResult(path, count, _prop.msgs.searchErrorSENotFound);
					return;
				}
				if (c.area != 0 && !_summ.area(c.area)) {
					addResult(path, count, _prop.msgs.searchErrorAreaNotFound);
					return;
				}
				if (c.battle != 0 && !_summ.battle(c.battle)) {
					addResult(path, count, _prop.msgs.searchErrorBattleNotFound);
					return;
				}
				if (c.packages != 0 && !_summ.cwPackage(c.packages)) {
					addResult(path, count, _prop.msgs.searchErrorPackageNotFound);
					return;
				}
				if (c.casts != 0 && !_summ.cwCast(c.casts)) {
					addResult(path, count, _prop.msgs.searchErrorCastNotFound);
					return;
				}
				if (c.item != 0 && !_summ.item(c.item)) {
					addResult(path, count, _prop.msgs.searchErrorItemNotFound);
					return;
				}
				if (c.skill != 0 && !_summ.skill(c.skill)) {
					addResult(path, count, _prop.msgs.searchErrorSkillNotFound);
					return;
				}
				if (c.beast != 0 && !_summ.beast(c.beast)) {
					addResult(path, count, _prop.msgs.searchErrorBeastNotFound);
					return;
				}
				if (c.info != 0 && !_summ.info(c.info)) {
					addResult(path, count, _prop.msgs.searchErrorInfoNotFound);
					return;
				}
				if (c.start != "" && !hasStart()) {
					addResult(path, count, _prop.msgs.searchErrorStartNotFound);
					return;
				}
				foreach (m; c.motions) {
					if (m.type == MType.SUMMON_BEAST && !m.beast) {
						addResult(path, count, _prop.msgs.searchErrorNoBeast);
						return;
					}
					if (m.type == MType.SUMMON_BEAST && m.beast && 0 != m.beast.linkId && !_summ.beast(m.beast.linkId)) {
						addResult(path, count, _prop.msgs.searchErrorLinkIdNotFound);
						return;
					}
				}
				if (c.flag2 != "" && !froot.findFlag(c.flag2)) {
					addResult(path, count, _prop.msgs.searchErrorFlagNotFound);
					return;
				}
				if (c.step2 != "" && !froot.findStep(c.step2)) {
					addResult(path, count, _prop.msgs.searchErrorStepNotFound);
					return;
				}
				if (c.flag != "" && c.flag == c.flag2) {
					addResult(path, count, _prop.msgs.searchErrorSouceIsTarget);
					return;
				}
				if (c.step != "" && c.step == c.step2) {
					addResult(path, count, _prop.msgs.searchErrorSouceIsTarget);
					return;
				}
				if ((c.type is CType.GET_COUPON || c.type is CType.LOSE_COUPON) && _prop.sys.isCouponType(c.coupon, CouponType.System)) {
					addResult(path, count, _prop.msgs.searchErrorSystemName);
					return;
				}
				if (c.levelMin > c.levelMax) {
					addResult(path, count, _prop.msgs.searchErrorReversalLevel);
					return;
				}
			});
		}
		void searchFileErrors() {
			string sPath = _summ.scenarioPath;
			string[string] digests;
			void recurse(string file) {
				try {
					bool dir = .isDir(file);
					if (_summ.isSystemFile(file, dir)) return;
					if (containsPath(_prop.var.etc.ignorePaths, file.baseName())) return;
					if (dir) {
						foreach (string sub; clistdir(file)) {
							recurse(file.buildPath(sub));
						}
					} else {
						auto size = file.getSize();
						if (!size) {
							addResult(abs2rel(file, sPath), count, _prop.msgs.searchErrorEmptyFile);
							return;
						}
						auto digest = file.fileToMD5Digest();
						if (!digest.length) return;
						digest = .format("%s-%s", digest, size);

						auto p = digest in digests;
						if (!p) {
							digests[digest] = file;
							return;
						}
						addResult(abs2rel(file, sPath), count, .tryFormat(_prop.msgs.searchErrorDupFile, abs2rel(*p, sPath)));
					}
				} catch (Exception e) {
					debugln(e);
				}
			}
			recurse(sPath);
		}

		_inProc = true;
		_comm.refreshToolBar();
		updateDefaultButton();
		auto cursors = setWaitCursors(_win);
		auto thr = new core.thread.Thread({
			auto exit = new class Runnable {
				override void run() {
					_inProc = false;
					setResultStatus(count);
					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);
			try {
				foreach (path; range) {
					search(path);
				}
				searchFileErrors();
			} catch (Throwable e) {
				debugln(e);
			}
		});
		thr.start();
	}
	private void replaceTextImpl(CWXPath c, ref size_t count) {
		if (cancel) return;
		bool oldIgnoreMod = ignoreMod;
		ignoreMod = true;
		scope (exit) ignoreMod = oldIgnoreMod;
		size_t dmy = 0;
		auto summ = cast(Summary) c;
		if (summ) {
			bool sr = false;
			Undo[] uArr;
			if (_summarySel) {
				sr |= repl(null, summ.scenarioName, &summ.scenarioName, count, uArr);
				sr |= repl(null, summ.desc, &summ.desc, count, uArr);
			}
			if (_couponSel) {
				sr |= replRqCoupons(null, summ, count, uArr);
			}
			if (sr) {
				if (_replMode) store(summ, uArr);
				addResult(summ, dmy);
			}
		}
		auto cc = cast(CastCard) c;
		if (cc) {
			Undo[] uArr;
			bool r = replCard!(CastCard)(null, cc, count, uArr);
			if (_couponSel) {
				Coupon[] coupons = null;
				if (_replMode) coupons = new Coupon[cc.coupons.length];
				foreach (i, cp; cc.coupons) {
					Coupon cp2 = null;
					r |= repl(null, cp.name,
						(string t) {cp2 = new Coupon(t, cp.value);}, count, uArr);
					if (_replMode) coupons[i] = cp2 ? cp2 : new Coupon(cp);
				}
				if (_replMode) cc.coupons = coupons;
			}
			if (r) {
				if (_replMode) store(cc, uArr);
				addResult(cc, dmy);
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
			if (_areaSel) {
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
		if (f && _flagSel) {
			Undo[] uArr = new Undo[0];
			bool r = replFlagName!Flag(f.parent, f, count, uArr);
			r |= repl(null, f.on, &f.on, count, uArr);
			r |= repl(null, f.off, &f.off, count, uArr);
			if (r) {
				if (_replMode) store(f, uArr);
				addResult(f, dmy);
			}
		}
		auto s = cast(Step) c;
		if (s && _flagSel) {
			Undo[] uArr;
			bool r = replFlagName!Step(s.parent, s, count, uArr);
			foreach (i, v; s.values) {
				r |= repl(null, v, (string t) {s.setValue(i, t);}, count, uArr);
			}
			if (r) {
				if (_replMode) store(s, uArr);
				addResult(s, dmy);
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
	private void initText(string from, string to) {
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
	}
	private void exitText() {
		if (!_win || _win.isDisposed()) return;
		_wildcard = null;
		_regex = typeof(_regex).init;
		_regexTarg = false;
		_toTemp = ""d;
	}
	private static void addHist(Combo combo, void delegate(string[]) set,
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
	private void replaceTextImpl() {
		if (!_summ) return;
		string from = _from.getText();
		string to = _to.getText();
		if (!from.length) return;
		initText(from, to);

		size_t count = 0;
		reset();

		_result.setHeaderVisible(true);
		auto mainColumn = new TableColumn(_result, SWT.NONE);
		mainColumn.setText(_prop.msgs.searchResultColumnMain);
		saveColumnWidth!("prop.var.etc.searchResultColumnMain")(_prop, mainColumn);
		auto subColumn = new TableColumn(_result, SWT.NONE);
		subColumn.setText(_prop.msgs.searchResultColumnParent);
		saveColumnWidth!("prop.var.etc.searchResultColumnParent")(_prop, subColumn);

		auto range = searchRange;
		bool jptx = _jptx.getSelection();
		_inProc = true;
		_comm.refreshToolBar();
		updateDefaultButton();
		addHist(_from, (string[] s) {_prop.var.etc.searchHistories = s;},
			{return _prop.var.etc.searchHistories.dup;},
			_prop.var.etc.searchHistoryMax, from);
		if (_replMode) {
			addHist(_to, (string[] s) {_prop.var.etc.replaceHistories = s;},
				{return _prop.var.etc.replaceHistories.dup;},
				_prop.var.etc.searchHistoryMax, to);
		}
		_comm.refSearchHistories.call(this);

		void search() {
			foreach (path; range) {
				searchAll(path, count, &replaceTextImpl);
			}
			if (jptx) {
				foreach (string file; .dirEntries(_summ.scenarioPath, SpanMode.depth, false)) {
					if (cancel) break;
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
								file = abs2rel(file, _summ.scenarioPath);
								size_t dmy = 0;
								addResult(file, dmy);
								store(file, uArr);
							}
						} catch (Exception e) {
							debugln(e);
						}
					}
				}
			}
		}

		auto cursors = setWaitCursors(_win);
		auto thr = new core.thread.Thread({
			auto exit = new class Runnable {
				override void run() {
					_inProc = false;
					setResultStatus(count);
					exitText();
					if (_replMode && !_after.length) _comm.replText.call();

					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);

			try {
				search();
			} catch (Throwable e) {
				debugln(e);
			}
		});
		thr.start();
	}
	private void grepImpl() {
		string from = _from.getText();
		auto dirBase = _grepDir.getText();
		auto dir = _prop.toAppAbs(dirBase);
		initText(from, "");
		_replMode = false;

		size_t count = 0;
		reset();

		_result.setHeaderVisible(true);
		auto mainColumn = new TableColumn(_result, SWT.NONE);
		mainColumn.setText(_prop.msgs.searchResultColumnMain);
		saveColumnWidth!("prop.var.etc.searchResultColumnMain")(_prop, mainColumn);
		auto subColumn = new TableColumn(_result, SWT.NONE);
		subColumn.setText(_prop.msgs.searchResultColumnParent);
		saveColumnWidth!("prop.var.etc.searchResultColumnParent")(_prop, subColumn);
		auto scColumn = new TableColumn(_result, SWT.NONE);
		scColumn.setText(_prop.msgs.searchResultColumnScenario);
		saveColumnWidth!("prop.var.etc.searchResultColumnScenario")(_prop, scColumn);

		if (!dir.exists()) return;
		LoadOption opt;
		opt.doubleIO = _prop.var.etc.doubleIO;
		opt.cardOnly = false;
		opt.textOnly = true;
		opt.expandXMLs = false;
		opt.summaryOnly = true;
		foreach (b; _noSummText) {
			if (b.getSelection()) {
				opt.summaryOnly = false;
				break;
			}
		}
		if (0 == from.length) {
			opt.summaryOnly = true;
		}
		bool jptx = _jptx.getSelection();
		bool subDir = _grepSubDir.getSelection();

		void findSumm(string summFile) {
			if (cancel) return;
			_grepFile = summFile;
			scope (exit) _grepFile = "";
			refResultStatus(count, true);
			auto summ = Summary.loadScenarioFromFile(_prop.parent, opt, summFile, _prop.tempPath);
			if (!summ) return;
			_grepSumm = summ;
			scope (exit) {
				_grepSumm.delTemp();
				_grepSumm = null;
				_grepSkin = null;
				delete _grepSumm;
				core.memory.GC.collect();
			}
			if (!_fromText.length) {
				addResult(summ, count);
				return;
			}
			refResultStatus(count, true);
			auto range = rangeTree(summ);
			foreach (path; range) {
				if (cancel) return;
				searchAll(path, count, &replaceTextImpl);
			}
			if (jptx) {
				foreach (string file; .dirEntries(summ.scenarioPath, SpanMode.depth, false)) {
					if (cancel) break;
					if (cfnmatch(.extension(file), ".jptx")) {
						bool isSJIS;
						string value = readJPYFile(file, isSJIS);
						auto jText = jptxText(value);
						Undo[] uArr;
						string file2 = file;
						bool r = repl(null, jText, null, count, uArr, true);
						if (r) {
							file = abs2rel(file, summ.scenarioPath);
							size_t dmy = 0;
							addResult(file, dmy);
						}
					}
				}
			}
			refResultStatus(count, true);
		}
		void recurse(string dir, uint rec) {
			if (cancel) return;
			if (dir.buildPath("Summary.xml").exists() || dir.buildPath("Summary.wsm").exists()) {
				try {
					findSumm(dir);
				} catch (Exception e) {
					debugln(e);
				}
			}
			foreach (file; clistdir(dir)) {
				if (cancel) break;
				try {
					file = dir.buildPath(file);
					if (file.isDir()) {
						if (subDir || 0 == rec) recurse(file, rec + 1);
					} else {
						auto ext = file.extension();
						if (cfnmatch(ext, ".wsn") || cfnmatch(ext, ".zip") || (canUncab && cfnmatch(ext, ".cab"))) {
							findSumm(file);
						}
					}
				} catch (Exception e) {
					debugln(e);
				}
			}
		}
		_inProc = true;
		_inGrep = true;
		_comm.refreshToolBar();
		updateDefaultButton();
		addHist(_from, (string[] s) {_prop.var.etc.searchHistories = s;},
			{return _prop.var.etc.searchHistories.dup;},
			_prop.var.etc.searchHistoryMax, from);
		addHist(_grepDir, (string[] s) {_prop.var.etc.grepDirHistories = s;},
			{return _prop.var.etc.grepDirHistories.dup;},
			_prop.var.etc.searchHistoryMax, dirBase);
		_comm.refSearchHistories.call(this);
		auto cursors = setWaitCursors(_win);
		auto thr = new core.thread.Thread({
			auto exit = new class Runnable {
				override void run() {
					_inProc = false;
					_inGrep = false;
					exitText();
					setResultStatus(count);
					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);
			try {
				recurse(dir, 0);
			} catch (Throwable e) {
				debugln(e);
			}
		});
		thr.start();
	}
	private void refSearchHistories(Object sender) {
		if (sender is this) return;
		string ft = _from.getText();
		string tt = _to.getText();
		setComboItems(_from, _prop.var.etc.searchHistories.dup);
		setComboItems(_to, _prop.var.etc.replaceHistories.dup);
		setComboItems(_grepDir, _prop.var.etc.grepDirHistories.dup);
		_from.setText(ft);
		_to.setText(tt);
	}
	private Regex!(dchar) _regex;
	private bool _regexTarg = false;
	private Wildcard _wildcard = null;
	private dstring _toTemp = ""d;
	private string fTextRepl(string s) {
		if (_regexTarg) {
			return toUTF8(std.regex.replace(toUTF32(s), _regex, _toTemp));
		}
		string to = _toText;
		if (_wildcard) {
			return _wildcard.replace(s, to);
		}
		string from = _fromText;
		if (_notIgnoreCaseSel) {
			if (_exactSel) {
				return 0 == cmp(s, from) ? to : from;
			} else {
				return .replace(s, from, to);
			}
		} else {
			if (_exactSel) {
				return 0 == icmp(s, from) ? to : from;
			} else {
				return .ireplace(s, from, to);
			}
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
 				debugln(_fromText, " -> ", s);
				throw e;
			}
			return c;
		}
		if (_wildcard) {
			return _wildcard.count(s);
		}
		string from = _fromText;
		if (_notIgnoreCaseSel) {
			if (_exactSel) {
				return 0 == cmp(s, from) ? 1 : 0;
			} else {
				return std.algorithm.count(s, from);
			}
		} else {
			if (_exactSel) {
				return 0 == icmp(s, from) ? 1 : 0;
			} else {
				return .icount(s, from);
			}
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
			if (cast(CWXPathString) d !is null || cast(FilePathString) d !is null) {
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
				if (rp.scPath !is null) {
					exec(_prop.parent.appPath ~ " " ~ rp.scPath ~ " " ~ path);
					return;
				}
				if (!_summ) return;
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
			if (!_summ) return;
			auto p = cast(FilePathString) d;
			if (p) {
				auto path = nabs(std.path.buildPath(_summ.scenarioPath, p.array));
				if (p.scPath !is null) {
					exec(_prop.parent.appPath ~ " -selectfile " ~ p.array ~ " " ~ p.scPath);
					return;
				}
				if (_comm.openFilePath(path, false)) {
					_win.setActive();
					return;
				}
				MessageBox.showWarning(.tryFormat(_prop.msgs.filePathOpenError, path), _prop.msgs.dlgTitWarning, _win);
				return;
			}
		}
	}
	Image fimage(string file, Skin skin) {
		try {
			if (.exists(file)) {
				if (.isDir(file)) {
					return _prop.images.folder;
				} else if (skin.isCardImage(file, false)) {
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
			string[] line;
			foreach (i; 0 .. _result.getColumnCount()) {
				line ~= itm.getText(i).replace("\n", .newline);
			}
			t ~= std.string.join(line, "\t");
		}
		if (!t.length) return;
		auto text = new ArrayWrapperString(std.string.join(t, .newline));
		_comm.clipboard.setContents([text], [TextTransfer.getInstance()]);
		_comm.refreshToolBar();
		updateDefaultButton();
	}
	private void addResult(string path, ref size_t count, string desc = "") {
		if (cancel) return;
		count++;
		auto addResultPath = new AddResultPath;
		addResultPath.path = path;
		addResultPath.desc = desc;
		addResultPath.count = count;
		_display.syncExec(addResultPath);
	}
	private void refContentText() {
		foreach (itm; _result.getItems()) {
			auto c = cast(CWXPathString) itm.getData();
			if (c) {
				string text1, text2;
				Image img1, img2;
				getPathParams(c.path, text1, text2, img1, img2);
				itm.setImage(0, img1);
				itm.setText(0, text1);
				itm.setImage(1, img2);
				itm.setText(1, text2);
			}
		}
	}
	private void getPathParams(CWXPath path, out string text, out string text2, out Image img, out Image img2, bool par = false) {
		auto summ = _grepSumm ? _grepSumm : _summ;
		img = null;
		text = par ? "" : "*Error*";
		if (!path) return;
		auto sum = cast(Summary) path;
		if (sum && !par) {
			img = _prop.images.summary;
			text = .tryFormat(_prop.msgs.searchResultSummary, sum.desc.singleLine);
		}
		auto bgi = cast(BgImage) path;
		if (bgi && !par) {
			img = _prop.images.backs;
			auto p = bgi.path == "" ? _prop.msgs.noSelectImage : encodePath(bgi.path);
			text = .tryFormat(_prop.msgs.searchResultBgImage, p);
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
			if (ski.linkId != 0) ski = summ.skill(ski.linkId);
			if (!ski) return;
			img = _prop.images.skill;
			text = .tryFormat(_prop.msgs.searchResultIds, _prop.msgs.skill, ski.id, ski.name);
		}
		auto ite = cast(ItemCard) path;
		if (ite) {
			if (ite.linkId != 0) ite = summ.item(ite.linkId);
			if (!ite) return;
			img = _prop.images.item;
			text = .tryFormat(_prop.msgs.searchResultIds, _prop.msgs.item, ite.id, ite.name);
		}
		auto bea = cast(BeastCard) path;
		if (bea) {
			if (bea.linkId != 0) bea = summ.beast(bea.linkId);
			if (!bea) return;
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
			text = .contentText(_comm, con, summ);
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
				text = .contentText(_comm, c, summ);
			}
		}
		auto sdlg = cast(SDialog) path;
		if (sdlg && !par) {
			con = sdlg.parent;
			assert (con);
			img = _prop.images.content(con.type);
			string t = sdlg.text.singleLine;
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
		if (fld) {
			img = _prop.images.flagDir;
			string fldPath = fld.path;
			if ("" == fldPath) {
				// Rootディレクトリ
				text = _prop.msgs.flagsAndSteps;
			} else {
				text = .tryFormat(_prop.msgs.searchResultFlagDir, fldPath);
			}
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
				auto card = summ.cwCast(ene.id);
				if (card) {
					cName = card ? card.name : .tryFormat(_prop.msgs.noCast, ene.id);
				}
			}
			text = .tryFormat(_prop.msgs.searchResultEnemyCard, cName);
		}
		assert (par || img);
		string parText = "", dummy;
		Image parImg, dummyImg;
		getPathParams(path.cwxParent, parText, dummy, parImg, dummyImg, true);
		if (parText != "") {
			if (text == "") {
				text = parText;
				img = parImg;
			} else {
				text2 = parText;
				img2 = parImg;
			}
		}
	}
	private void addResult(CWXPath path, ref size_t count, string desc = "", int index = -1) {
		if (cancel) return;
		count++;
		auto addResultCWXPath = new AddResultCWXPath;
		addResultCWXPath.path = path;
		addResultCWXPath.index = index;
		addResultCWXPath.desc = desc;
		addResultCWXPath.count = count;
		_display.syncExec(addResultCWXPath);
	}
	private void addResult(string name, Image delegate() image, ref size_t count, int index = -1) {
		if (cancel) return;
		count++;
		auto addResultMsg = new AddResultMsg;
		addResultMsg.name = name;
		addResultMsg.image = image;
		addResultMsg.index = index;
		addResultMsg.count = count;
		_display.syncExec(addResultMsg);
	}
	private void addResult(string name, uint use, Image delegate() image, ref size_t count, int index = -1) {
		if (cancel) return;
		count++;
		auto addResultUse = new AddResultUse;
		addResultUse.name = name;
		addResultUse.use = use;
		addResultUse.image = image;
		addResultUse.index = index;
		addResultUse.count = count;
		_display.syncExec(addResultUse);
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
				size_t dmy = 0;
				addResult(path, dmy);
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
				size_t dmy = 0;
				addResult(targ, dmy);
			}
			return true;
		}
		return false;
	}

	private bool replKeyCode(C)(CWXPath path, C targ, ref size_t count, ref Undo[] uArr) {
		if (_keyCodeSel) {
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
					size_t dmy = 0;
					addResult(path, dmy);
				}
				return true;
			}
		}
		return false;
	}

	private bool replBgImage(CWXPath path, BgImage back, ref size_t count, ref Undo[] uArr) {
		bool r = false;
		Undo[] uArr2;
		if (_flagSel) {
			if (_flagDirOnRange) {
				r |= repl(null, back.flag, null, count, uArr2);
			} else {
				r |= repl(null, back.flag, &back.flag, count, uArr2);
			}
		}
		if (_fileSel) {
			r |= replFilePath(back.path, &back.path, count, uArr2);
		}
		if (r && path) {
			if (_replMode) store(path, uArr2);
			size_t dmy = 0;
			addResult(path, dmy);
		} else {
			uArr ~= uArr2;
		}
		return r;
	}
	private bool replCard(C)(CWXPath path, C card, ref size_t count, ref Undo[] uArr) {
		bool r = false;
		static if (is(typeof(card.linkId))) {
			if (card.linkId != 0) return r;
		}
		Undo[] uArr2;
		if (_cardNameSel) {
			r |= repl(null, card.name, &card.name, count, uArr2);
		}
		if (_cardDescSel) {
			r |= repl(null, card.desc, &card.desc, count, uArr2);
		}
		if (_flagSel) {
			static if (is (C : IFlagUser)) {
				if (_flagDirOnRange) {
					r |= repl(null, card.flag, null, count, uArr2);
				} else {
					r |= repl(null, card.flag, &card.flag, count, uArr2);
				}
			}
		}
		if (_fileSel) {
			r |= replFilePath(card.path, &card.path, count, uArr2);
		}
		static if (is (C : EffectCard)) {
			r |= replKeyCode!(C)(null, card, count, uArr2);
		}
		if (r && path) {
			if (_replMode) store(path, uArr2);
			size_t dmy = 0;
			addResult(path, dmy);
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
		if (_eventSel && eo && eo.detail.nextType == CNextType.TEXT) {
			r |= repl(null, e.name, &e.name, count, uArr2);
		}
		if (_flagSel) {
			if (_flagDirOnRange) {
				// Flag/StepについてはUseCounter経由で置換される
				r |= repl(null, e.flag, null, count, uArr2);
				r |= repl(null, e.step, null, count, uArr2);
				r |= repl(null, e.flag2, null, count, uArr2);
				r |= repl(null, e.step2, null, count, uArr2);
			} else {
				r |= repl(null, e.flag, &e.flag, count, uArr2);
				r |= repl(null, e.step, &e.step, count, uArr2);
				r |= repl(null, e.flag2, &e.flag, count, uArr2);
				r |= repl(null, e.step2, &e.step, count, uArr2);
			}
		}
		if (_startSel) {
			r |= repl(null, e.start, &e.start, count, uArr2);
			if (e.type == CType.START) {
				r |= repl(null, e.name, &e.name, count, uArr2);
			}
		}
		if (_couponSel) {
			r |= repl(null, e.coupon, &e.coupon, count, uArr2);
		}
		if (_gossipSel) {
			r |= repl(null, e.gossip, &e.gossip, count, uArr2);
		}
		if (_endSel) {
			r |= repl(null, e.completeStamp, &e.completeStamp, count, uArr2);
		}
		if (_msgSel) {
			r |= repl(null, e.text, &e.text, count, uArr2);
		}
		bool replInText(ITextHolder th, ref Undo[] uArr) {
			Undo[] nArr;
			bool r = false;
			string old = th.text;
			if (_fileSel) {
				auto ps = th.fontsInText;
				foreach (i, p; ps) {
					auto c = decodeFontPath(p);
					string ext = .extension(p);
					r |= repl(null, .to!string(c), (string s) {
						dstring ds = .to!dstring(s);
						if (!ds.length) return;
						th.changeInText(i, toPathId(encodeFontPath(ds[0], ext)));
					}, count, nArr);
				}
				uArr ~= new StrUndo(old, th.text, &th.text);
			}
			if (_flagSel && !_msgSel) {
				if (_flagDirOnRange) {
					// Flag/StepについてはUseCounter経由で置換される
					auto fps = th.flagsInText;
					foreach (i, p; fps) {
						r |= repl(null, p, null, count, nArr);
					}
					auto sps = th.stepsInText;
					foreach (i, p; sps) {
						r |= repl(null, p, null, count, nArr);
					}
				} else {
					auto fps = th.flagsInText;
					foreach (i, p; fps) {
						r |= repl(null, p, (string n) {th.changeInText(i, toFlagId(p));}, count, nArr);
					}
					auto sps = th.stepsInText;
					foreach (i, p; sps) {
						r |= repl(null, p, (string n) {th.changeInText(i, toStepId(p));}, count, nArr);
					}
				}
			}
			return r;
		}
		r |= replInText(e, uArr2);
		bool rDlg = false;
		if (_msgSel || _couponSel || _fileSel || _flagSel) {
			auto dlgs = e.dialogs;
			foreach (dlg; dlgs) {
				Undo[] uArrDlg;
				auto put = dlg;
				if (_msgSel && repl(dlg, dlg.text, &dlg.text, count, uArrDlg, true)) {
					rDlg = true;
					put = null;
				}
				if (_couponSel && replRqCoupons!(typeof(dlg))(put, dlg, count, uArrDlg, true)) {
					rDlg = true;
					put = null;
				}
				if (replInText(dlg, uArrDlg)) {
					size_t dmy = 0;
					if (put) addResult(put, dmy);
					rDlg = true;
					put = null;
				}
				if (_replMode && !put) {
					store(dlg, uArrDlg);
				}
			}
		}
		if (_fileSel) {
			r |= replFilePath(e.cardPath, &e.cardPath, count, uArr2);
			r |= replFilePath(e.bgmPath, &e.bgmPath, count, uArr2);
			r |= replFilePath(e.soundPath, &e.soundPath, count, uArr2);
		}
		if (_commentSel) {
			r |= repl(null, e.comment, &e.comment, count, uArr2);
		}
		if (r) {
			if (_replMode) {
				store(e, uArr2);
			}
			size_t dmy = 0;
			addResult(e, dmy);
		}
	}
}
