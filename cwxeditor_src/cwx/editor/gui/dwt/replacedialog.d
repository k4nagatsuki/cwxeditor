
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
import cwx.textholder;
import cwx.system;
import cwx.warning;

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.splitpane;
import cwx.editor.gui.dwt.undo;
import cwx.editor.gui.dwt.dmenu;
import cwx.editor.gui.dwt.chooser;
import cwx.editor.gui.dwt.incsearch;

import std.ascii;
import std.conv;
import std.array;
import std.string;
import std.file;
import std.path;
import std.regex : Regex, regex, RegexMatch, match;
import std.utf;
import std.algorithm : uniq, swap;
import std.traits;
import std.typecons : Tuple;

import org.eclipse.swt.all;

import java.lang.all;

private class CWXPathString {
	string scPath;
	CWXPath path;
	string array;
	this (string scPath, CWXPath path, string array) { mixin(S_TRACE);
		this.scPath = scPath;
		this.path = path;
		this.array = array;
	}
}
private class FilePathString {
	string scPath;
	string array;
	this (string scPath, string array) { mixin(S_TRACE);
		this.scPath = scPath;
		this.array = array;
	}
}

private class FKeyCodesUndo : TUndo!(FKeyCode[]) {
	this (FKeyCode[] old, FKeyCode[] n, void delegate(FKeyCode[]) set) { mixin(S_TRACE);
		super (old.dup, n.dup, set, (FKeyCode[] v) {return v.dup;});
	}
}

private class CouponsUndo : TUndo!(Coupon[]) {
	this (Coupon[] old, Coupon[] n, void delegate(Coupon[]) set) { mixin(S_TRACE);
		super (old.dup, n.dup, set, (Coupon[] v) {return v.dup;});
	}
}

/// 検索と置換を行うダイアログ。
class ReplaceDialog {
private:
	class UndoRepl : UndoArr {
		this (Undo[] array, bool rev = true) { mixin(S_TRACE);
			super (array, rev);
		}
		override void undo() { mixin(S_TRACE);
			reset(false);
			super.undo();
			refContentText();
			_status.setText(.tryFormat(_prop.msgs.replaceUndo, .formatNum(_result.getItemCount())));
			_comm.replText.call();
		}
		override void redo() { mixin(S_TRACE);
			reset(false);
			super.redo();
			refContentText();
			_status.setText(.tryFormat(_prop.msgs.replaceRedo, .formatNum(_result.getItemCount())));
			_comm.replText.call();
		}
	}

	class RUndo : Undo {
		private CWXPath _path = null;
		private string _filePath = null;
		private Undo[] _uArr;
		this (CWXPath path, Undo[] uArr) { mixin(S_TRACE);
			_path = path;
			_uArr = uArr;
		}
		this (string filePath, Undo[] uArr) { mixin(S_TRACE);
			_filePath = filePath;
			_uArr = uArr;
		}
		void undo() { mixin(S_TRACE);
			size_t dmy = 0;
			foreach_reverse (u; _uArr) u.undo();
			if (_path) addResult(_path, dmy);
			if (_filePath) addResult(_filePath, dmy);
		}
		void redo() { mixin(S_TRACE);
			size_t dmy = 0;
			foreach_reverse (u; _uArr) u.redo();
			if (_path) addResult(_path, dmy);
			if (_filePath) addResult(_filePath, dmy);
		}
		void dispose() { mixin(S_TRACE);
			foreach (u; _uArr) u.dispose();
		}
	}

	void store(string filePath, Undo[] uArr) { mixin(S_TRACE);
		_rUndo ~= new RUndo(filePath, uArr);
	}
	void store(CWXPath path, Undo[] uArr) { mixin(S_TRACE);
		_rUndo ~= new RUndo(path, uArr);
	}
	void store(CWXPath path, string o, string n, void delegate(string) set) { mixin(S_TRACE);
		_rUndo ~= new RUndo(path, [new StrUndo(o, n, set)]);
	}
	void store(CWXPath path, string[] o, string[] n, void delegate(string[]) set) { mixin(S_TRACE);
		_rUndo ~= new RUndo(path, [new StrArrUndo(o, n, set)]);
	}
	void store(CWXPath path, FKeyCode[] o, FKeyCode[] n, void delegate(FKeyCode[]) set) { mixin(S_TRACE);
		_rUndo ~= new RUndo(path, [new FKeyCodesUndo(o, n, set)]);
	}
	void store(CWXPath path, Coupon[] o, Coupon[] n, void delegate(Coupon[]) set) { mixin(S_TRACE);
		_rUndo ~= new RUndo(path, [new CouponsUndo(o, n, set)]);
	}
	void storeID(User, Id)(CWXPath path, User u, Id from, Id to, void delegate(Id) set) { mixin(S_TRACE);
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
	int _grepCount = -1;
	Skin _grepSkin = null;
	string _grepFile = "";
	bool _inGrep = false;
	void delegate() _sendReloadProps = null;

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
	CTabItem _lastFind = null;
	Button _find;
	Button _replace;
	Button _close;
	Button _rangeAllCheck;

	bool ignoreMod = false;

	Composite _textGrp1, _textGrp2, _textFromComp, _grepFromComp;
	Combo _from;
	Combo _to;
	IncSearch _fromIncSearch = null;
	IncSearch _toIncSearch = null;

	Combo _idKind;
	Combo _fromID;
	Composite _fromIDComp;
	Spinner _fromIDVal;
	ulong[int] _fromIDTbl;
	Combo _toID;
	Composite _toIDComp;
	Spinner _toIDVal;
	ulong[int] _toIDTbl;
	IncSearch _fromIDIncSearch = null;
	IncSearch _toIDIncSearch = null;

	Combo _fromPath;
	Combo _toPath;
	IncSearch _fromPathIncSearch = null;
	IncSearch _toPathIncSearch = null;

	Combo _grepDir;
	Button _grepSubDir;

	Button _notIgnoreCase;
	Button _useRegex;
	Button _useWildcard;
	Button _exact;
	Button _ignoreReturnCode;
	class SelRegex : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			if (_useRegex.getSelection()) { mixin(S_TRACE);
				_useWildcard.setSelection(false);
			}
		}
	}
	class SelWildcard : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			if (_useWildcard.getSelection()) { mixin(S_TRACE);
				_useRegex.setSelection(false);
			}
		}
	}
	class SelIgnoreReturnCode : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			_comm.refreshToolBar();
		}
	}
	@property
	const
	bool catchMod() {return !ignoreMod;}

	/// 貼紙
	Button _summary;
	/// シナリオ名
	Button _scenario;
	/// 作者名
	Button _author;
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
	// FIXME: CardWirth 1.60 セル名称
/+	Button _cCellName;
+/
	Table _result;
	TableTextEdit _edit;
	Tree _range;

	Composite[CTabItem] _comps;

	ToolItem[CType] _contents;

	Label _status;

	bool _notIgnoreCaseSel;
	bool _exactSel;
	bool _ignoreReturnCodeSel;
	bool _summarySel;
	bool _scenarioSel;
	bool _authorSel;
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
	bool _jptxSel;
	string _fromText;
	string _toText;

	bool _flagDirOnRange = false;

	bool _resultRedraw = true;
	void resultRedraw(bool val) { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) return;
		if (_resultRedraw !is val) { mixin(S_TRACE);
			_resultRedraw = val;
			_result.setRedraw(val);
		}
	}

	class AddResultPath : Runnable {
		size_t count = 0;
		string path;
		string desc;
		void run() { mixin(S_TRACE);
			if (cancel) return;
			if (!_win || _win.isDisposed()) return;
			if (_inProc && !_prop.var.etc.searchResultRealtime) resultRedraw(false);
			auto itm = new TableItem(_result, SWT.NONE);
			auto summ = _grepSumm ? _grepSumm : _summ;
			auto fullPath = std.path.buildPath(summ.scenarioPath, path);
			if (_grepSumm) { mixin(S_TRACE);
				if (!_grepSkin) _grepSkin = findSkin(_comm, _prop, summ);
				itm.setImage(fimage(fullPath, _grepSkin));
			} else { mixin(S_TRACE);
				itm.setImage(fimage(fullPath, _comm.skin));
			}
			string scPath = null;
			string text = encodePath(path);
			itm.setText(0, text);
			if (desc.length) { mixin(S_TRACE);
				itm.setText(2, desc);
				itm.setImage(2, _prop.images.warning);
			}
			if (_grepSumm) { mixin(S_TRACE);
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
		void run() { mixin(S_TRACE);
			if (cancel) return;
			if (!_win || _win.isDisposed()) return;
			if (_inProc && !_prop.var.etc.searchResultRealtime) resultRedraw(false);
			addResultImpl(path, index, desc);
			refResultStatus(count, false);
		}
	}
	private void addResultImpl(CWXPath path, int index = -1, string desc = "") {
		auto itm = new TableItem(_result, SWT.NONE, -1 == index ? _result.getItemCount() : index);
		string text1, text2;
		Image img1, img2;
		getPathParams(path, text1, text2, img1, img2);
		itm.setImage(0, img1);
		itm.setText(0, text1);
		itm.setImage(1, img2);
		itm.setText(1, text2);
		if (desc.length) { mixin(S_TRACE);
			itm.setText(2, desc);
			itm.setImage(2, _prop.images.warning);
		}
		string scPath = null;
		if (_grepSumm) { mixin(S_TRACE);
			scPath = _grepSumm.useTemp ? _grepSumm.zipName : _grepSumm.scenarioPath;
			itm.setText(2, .tryFormat(_prop.msgs.grepScenario, _grepSumm.scenarioName, scPath));
			itm.setImage(2, _prop.images.summary);
		}
		itm.setData(new CWXPathString(scPath, _grepSumm ? null : path, path.cwxPath(true)));
	}
	class AddResultMsg : Runnable {
		string name;
		Image delegate() image;
		int index;
		size_t count = 0;
		void run() { mixin(S_TRACE);
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
		void run() { mixin(S_TRACE);
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
		public override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (_result.isFocusControl() && e.button == 1) { mixin(S_TRACE);
				openPath();
			}
		}
	}
	class KL : KeyAdapter {
		public override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			if (_result.isFocusControl() && e.character == SWT.CR) { mixin(S_TRACE);
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
	static const ID_FLAG = 8;
	static const ID_STEP = 9;
	static const ID_COUPON = 10;
	static const ID_GOSSIP = 11;
	static const ID_COMPLETE_STAMP = 12;
	static const ID_KEY_CODE = 13;
	// FIXME: CardWirth 1.60 セル名称
/+	static const ID_CELL_NAME = 14;
+/	private void setupIDsImpl2(T)(T[] arr, Combo combo, Spinner spn, ref ulong[int] tbl, bool clear, IncSearch incSearch) { mixin(S_TRACE);
		ulong[int] tbl2;
		string oldSel = clear ? "" : combo.getText();
		combo.removeAll();
		static if (is(T:Flag) || is(T:Step)) {
			auto set = new HashSet!string;
			if (_summ) { mixin(S_TRACE);
				static if (is(T:Flag)) {
					foreach (key; _summ.useCounter.flag.keys) { mixin(S_TRACE);
						if (_prop.sys.randomValue == cast(string)key) continue;
						if (!incSearch.match(cast(string)key)) continue;
						set.add(cast(string)key);
					}
				} else static if (is(T:Step)) {
					foreach (key; _summ.useCounter.step.keys) { mixin(S_TRACE);
						if (_prop.sys.randomValue == cast(string)key) continue;
						if (!incSearch.match(cast(string)key)) continue;
						set.add(cast(string)key);
					}
				} else static assert (0);
			}
			foreach (i, a; arr) { mixin(S_TRACE);
				auto p = a.path;
				if (p == "") continue;
				if (!incSearch.match(p)) continue;
				combo.add(p);
				set.remove(p);
			}
			bool delegate(string a, string b) cmps;
			if (_prop.var.etc.logicalSort) { mixin(S_TRACE);
				cmps = (a, b) => incmp(a, b) < 0;
			} else { mixin(S_TRACE);
				cmps = (a, b) => icmp(a, b) < 0;
			}
			foreach (p; .sortDlg(set.array(), cmps)) { mixin(S_TRACE);
				if (p == "") continue;
				if (!incSearch.match(p)) continue;
				combo.add(p);
			}
			combo.setText(oldSel);
			if (combo.getText() == "" && combo.getItemCount()) { mixin(S_TRACE);
				combo.select(0);
			}
			spn.setEnabled(false);
		} else static if (is(T:CouponId) || is(T:GossipId) || is(T:CompleteStampId) || is(T:KeyCodeId) || is(T:CellNameId)) {
			string[] arr2;
			static if (is(T:CouponId)) {
				arr2 = .allCoupons(_comm, _summ, CouponComboType.AllCoupons);
			} else static if (is(T:GossipId)) {
				arr2 = .allGossips(_comm, _summ);
			} else static if (is(T:CompleteStampId)) {
				arr2 = .allCompleteStamps(_comm, _summ);
			} else static if (is(T:KeyCodeId)) {
				arr2 = .allKeyCodes(_comm, _summ);
			} else static if (is(T:CellNameId)) {
				arr2 = .allCellNames(_comm, _summ);
			} else static assert (0);
			foreach (a; arr2) {
				if (!incSearch.match(a)) continue;
				combo.add(a);
			}
			combo.setText(oldSel);
			if (combo.getText() == "" && combo.getItemCount()) { mixin(S_TRACE);
				combo.select(0);
			}
			spn.setEnabled(false);
		} else {
			combo.add(_prop.msgs.defaultSelection(_prop.msgs.replSetID));
			foreach (i, a; arr) { mixin(S_TRACE);
				if (!incSearch.match(a.name)) continue;
				combo.add(to!(string)(a.id) ~ "." ~ a.name);
				tbl2[i + 1] = a.id;
			}
			combo.select(1 < combo.getItemCount() ? 1 : 0);
			if (oldSel) { mixin(S_TRACE);
				auto i = combo.indexOf(oldSel);
				if (i >= 0) combo.select(i);
			}
			spn.setEnabled(combo.getSelectionIndex() == 0);
		}
		tbl = tbl2;
	}
	private void setupIDsImpl1(T)(T[] arr, bool clear, bool from, bool to) { mixin(S_TRACE);
		if (from) setupIDsImpl2(arr, _fromID, _fromIDVal, _fromIDTbl, clear, _fromIDIncSearch);
		if (to) setupIDsImpl2(arr, _toID, _toIDVal, _toIDTbl, clear, _toIDIncSearch);
	}
	private void setupIDs(bool clear, bool from, bool to) { mixin(S_TRACE);
		if (!_summ) { mixin(S_TRACE);
			_fromID.removeAll();
			_fromID.setEnabled(false);
			_fromIDVal.setEnabled(false);
			_toID.removeAll();
			_toID.setEnabled(false);
			_toIDVal.setEnabled(false);
			return;
		}
		if (from) _fromID.setEnabled(true);
		if (to) _toID.setEnabled(true);
		switch (_idKind.getSelectionIndex()) {
		case ID_AREA: setupIDsImpl1(_summ.areas, clear, from, to); break;
		case ID_BATTLE: setupIDsImpl1(_summ.battles, clear, from, to); break;
		case ID_PACKAGE: setupIDsImpl1(_summ.packages, clear, from, to); break;
		case ID_CAST: setupIDsImpl1(_summ.casts, clear, from, to); break;
		case ID_SKILL: setupIDsImpl1(_summ.skills, clear, from, to); break;
		case ID_ITEM: setupIDsImpl1(_summ.items, clear, from, to); break;
		case ID_BEAST: setupIDsImpl1(_summ.beasts, clear, from, to); break;
		case ID_INFO: setupIDsImpl1(_summ.infos, clear, from, to); break;
		case ID_FLAG: setupIDsImpl1(_summ.flagDirRoot.allFlags, clear, from, to); break;
		case ID_STEP: setupIDsImpl1(_summ.flagDirRoot.allSteps, clear, from, to); break;
		case ID_COUPON: setupIDsImpl1(_summ.useCounter.coupon.keys, clear, from, to); break;
		case ID_GOSSIP: setupIDsImpl1(_summ.useCounter.gossip.keys, clear, from, to); break;
		case ID_COMPLETE_STAMP: setupIDsImpl1(_summ.useCounter.completeStamp.keys, clear, from, to); break;
		case ID_KEY_CODE: setupIDsImpl1(_summ.useCounter.keyCode.keys, clear, from, to); break;
		// FIXME: CardWirth 1.60 セル名称
/+		case ID_CELL_NAME: setupIDsImpl1(_summ.useCounter.cellName.keys, clear, from, to); break;
+/		default: assert (0);
		}
	}
	private void fromIDIncSearch() { mixin(S_TRACE);
		.forceFocus(_fromID, true);
		_fromIDIncSearch.startIncSearch();
	}
	private void toIDIncSearch() { mixin(S_TRACE);
		.forceFocus(_toID, true);
		_toIDIncSearch.startIncSearch();
	}

	private string[] _lastMaterialPaths;
	private string[] allMaterials(bool scenarioOnly) { mixin(S_TRACE);
		if (!_summ) return [];
		return _summ.allMaterials(_comm.skin, _prop.var.etc.ignorePaths, _prop.var.etc.logicalSort, scenarioOnly);
	}
	private void setupPaths() { mixin(S_TRACE);
		bool oldIgnoreMod = ignoreMod;
		ignoreMod = true;
		scope (exit) ignoreMod = oldIgnoreMod;

		_lastMaterialPaths = [""] ~ allMaterials(false);
		setupPathsImpl(true, true);
	}
	private void setupPathsImpl(bool from, bool to) {
		void setPaths(Combo combo, IncSearch incSearch) { mixin(S_TRACE);
			auto old = combo.getText();
			combo.removeAll();
			foreach (path; _lastMaterialPaths) {
				if (!incSearch.match(path)) continue;
				combo.add(path);
			}
			combo.setText(old);
		}
		if (from) setPaths(_fromPath, _fromPathIncSearch);
		if (to) setPaths(_toPath, _toPathIncSearch);
	}
	class SListener : ShellAdapter {
		override void shellActivated(ShellEvent e) { mixin(S_TRACE);
			setupIDs(false, true, true);
			setupPaths();
			_comm.refreshToolBar();
		}
	}
	class SelID : SelectionAdapter {
		private Spinner _spn;
		this (Spinner spn) {_spn = spn;}
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			auto combo = cast(Combo) e.widget;
			_spn.setEnabled(combo.getSelectionIndex() == 0);
			_comm.refreshToolBar();
		}
	}
	class SelIDKind : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			selIDKind();
		}
	}
	void selIDKind() {
		updateIDCombo();
		setupIDs(true, true, true);
		_prop.var.etc.searchIDKind = _idKind.getSelectionIndex();
		_comm.refreshToolBar();
	}
	@property
	private bool idKindIsString() {
		auto index = _idKind.getSelectionIndex();
		// FIXME: CardWirth 1.60 セル名称 ここから
/+		return index == ID_FLAG || index == ID_STEP || index == ID_COUPON || index == ID_GOSSIP || index == ID_COMPLETE_STAMP || index == ID_KEY_CODE || index == ID_CELL_NAME;
+/		return index == ID_FLAG || index == ID_STEP || index == ID_COUPON || index == ID_GOSSIP || index == ID_COMPLETE_STAMP || index == ID_KEY_CODE;
		// FIXME: CardWirth 1.60 セル名称 ここまで
	}
	private void updateIDCombo() { mixin(S_TRACE);
		if (idKindIsString) { mixin(S_TRACE);
			if (_fromID && !(_fromID.getStyle() & SWT.READ_ONLY)) return;
			if (_fromID) { mixin(S_TRACE);
				_fromID.dispose();
				_toID.dispose();
			}
			
			_fromID = new Combo(_fromIDComp, SWT.BORDER | SWT.DROP_DOWN);
			_fromID.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			_toID = new Combo(_toIDComp, SWT.BORDER | SWT.DROP_DOWN);
			_toID.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
		} else { mixin(S_TRACE);
			if (_fromID && (_fromID.getStyle() & SWT.READ_ONLY)) return;
			if (_fromID) { mixin(S_TRACE);
				_fromID.dispose();
				_toID.dispose();
			}
			_fromID = new Combo(_fromIDComp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			_fromID.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			_fromID.addSelectionListener(new SelID(_fromIDVal));
			_toID = new Combo(_toIDComp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
			_toID.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			_toID.addSelectionListener(new SelID(_toIDVal));
		}
		auto fMenu = new Menu(_win, SWT.POP_UP);
		_fromID.setMenu(fMenu);
		createMenuItem(_comm, fMenu, MenuID.IncSearch, &fromIDIncSearch, null);
		new MenuItem(fMenu, SWT.SEPARATOR);
		createTextMenu!Combo(_comm, _prop, _fromID, &catchMod);

		auto tMenu = new Menu(_win, SWT.POP_UP);
		_toID.setMenu(tMenu);
		createMenuItem(_comm, tMenu, MenuID.IncSearch, &toIDIncSearch, null);
		new MenuItem(tMenu, SWT.SEPARATOR);
		createTextMenu!Combo(_comm, _prop, _toID, &catchMod);

		_fromIDIncSearch = new IncSearch(_comm, _fromID);
		_fromIDIncSearch.modEvent ~= () => setupIDs(false, true, false);
		_toIDIncSearch = new IncSearch(_comm, _toID);
		_toIDIncSearch.modEvent ~= () => setupIDs(false, false, true);

		_fromIDComp.layout();
		_toIDComp.layout();
	}
	private void tabChanged() { mixin(S_TRACE);
		auto sel = _tabf.getSelection();
		if (!sel) return;

		_parent.setRedraw(false);
		scope (exit) _parent.setRedraw(true);

		_prop.var.etc.searchPlan = _tabf.getSelectionIndex();
		if (sel is _tabText || sel is _tabGrep) { mixin(S_TRACE);
			auto comp = _comps[sel is _tabGrep ? _tabGrep : _tabText];
			if (_textGrp1.getParent() !is comp) _textGrp1.setParent(comp);
			if (_textGrp2.getParent() !is comp) _textGrp2.setParent(comp);
			auto fromComp = sel is _tabGrep ? _grepFromComp : _textFromComp;
			if (_from.getParent() !is fromComp) { mixin(S_TRACE);
				_from.setParent(fromComp);
			}
		}
		foreach (tab, comp; _comps) { mixin(S_TRACE);
			auto gd = cast(GridData) comp.getLayoutData();
			if (tab is sel) { mixin(S_TRACE);
				gd.heightHint= SWT.DEFAULT;
			} else { mixin(S_TRACE);
				gd.heightHint= 0;
			}
		}
		_parent.layout(true);
		_replace.setEnabled(!(sel is _tabText && _ignoreReturnCode.getSelection()) && sel !is _tabContents && sel !is _tabCoupon && sel !is _tabUnuse && sel !is _tabError);
		_range.setEnabled(sel !is _tabUnuse && sel !is _tabGrep);
		_rangeAllCheck.setEnabled(_range.getEnabled());
		_comm.refreshToolBar();
	}
	class TSListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			tabChanged();
		}
	}
	LCheck[] _checked;
	class LCheck : SelectionAdapter {
		Widget[] buttons;
		private Button _all = null;
		private void setSelection(Widget b, bool s) { mixin(S_TRACE);
			auto button = cast(Button) b;
			if (button) button.setSelection(s);
			auto ti = cast(ToolItem) b;
			if (ti) ti.setSelection(s);
		}
		private bool getSelection(Widget b) { mixin(S_TRACE);
			auto button = cast(Button) b;
			if (button) return button.getSelection();
			auto ti = cast(ToolItem) b;
			if (ti) return ti.getSelection();
			assert (0);
		}
		class AllCheck : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
				foreach (b; buttons) { mixin(S_TRACE);
					setSelection(b, _all.getSelection());
				}
			}
		}
		void check() { mixin(S_TRACE);
			bool checked = true;
			foreach (b; buttons) { mixin(S_TRACE);
				checked &= getSelection(b);
			}
			_all.setSelection(checked);
		}
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			assert (_all);
			check();
		}
		void createAlls(Composite parent, string text) { mixin(S_TRACE);
			_all = new Button(parent, SWT.CHECK);
			_all.setText(text);
			_all.addSelectionListener(new AllCheck);
			check();
		}
	}
	Composite addButtonLine(Composite grp) { mixin(S_TRACE);
		auto comp = new Composite(grp, SWT.NONE);
		comp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		auto rl = new RowLayout(SWT.HORIZONTAL);
		rl.wrap = true;
		rl.pack = false;
		comp.setLayout(rl);
		return comp;
	}
	void constructText(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		auto comp2gl = windowGridLayout(1, true);
		comp2gl.marginWidth = 0;
		comp2gl.marginHeight = 0;
		comp2.setLayout(comp2gl);
		{ mixin(S_TRACE);
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
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_textFromComp.setLayoutData(gd);
			auto lt = new Label(grp, SWT.NONE);
			lt.setText(_prop.msgs.replTo);
			_to = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN);
			_to.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
			_to.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

			auto fMenu = new Menu(_win, SWT.POP_UP);
			_from.setMenu(fMenu);
			createMenuItem(_comm, fMenu, MenuID.IncSearch, {
				.forceFocus(_from, true);
				_fromIncSearch.startIncSearch();
			}, null);
			new MenuItem(fMenu, SWT.SEPARATOR);
			createTextMenu!Combo(_comm, _prop, _from, &catchMod);

			auto tMenu = new Menu(_win, SWT.POP_UP);
			_to.setMenu(tMenu);
			createMenuItem(_comm, tMenu, MenuID.IncSearch, {
				.forceFocus(_to, true);
				_toIncSearch.startIncSearch();
			}, null);
			new MenuItem(tMenu, SWT.SEPARATOR);
			createTextMenu!Combo(_comm, _prop, _to, &catchMod);

			_fromIncSearch = new IncSearch(_comm, _from);
			_fromIncSearch.modEvent ~= &updateFromHistory;
			_toIncSearch = new IncSearch(_comm, _to);
			_toIncSearch.modEvent ~= &updateToHistory;
		}
		{ mixin(S_TRACE);
			auto grp = new Group(comp2, SWT.NONE);
			_textGrp1 = grp;
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			grp.setLayoutData(gd);
			grp.setText(_prop.msgs.replCond);
			grp.setLayout(new GridLayout(3, false));
			_notIgnoreCase = new Button(grp, SWT.CHECK);
			_notIgnoreCase.setText(_prop.msgs.replNotIgnoreCase);
			_exact = new Button(grp, SWT.CHECK);
			_exact.setText(_prop.msgs.replExactMatch);
			_ignoreReturnCode = new Button(grp, SWT.CHECK);
			_ignoreReturnCode.setText(_prop.msgs.replIgnoreReturnCode);
			_ignoreReturnCode.addSelectionListener(new SelIgnoreReturnCode);
			_useWildcard = new Button(grp, SWT.CHECK);
			_useWildcard.setText(_prop.msgs.replWildcard);
			_useWildcard.addSelectionListener(new SelWildcard);
			auto gdw = new GridData;
			gdw.horizontalSpan = 3;
			_useWildcard.setLayoutData(gdw);
			_useRegex = new Button(grp, SWT.CHECK);
			_useRegex.setText(_prop.msgs.replRegExp);
			_useRegex.addSelectionListener(new SelRegex);
			auto gdr = new GridData;
			gdr.horizontalSpan = 3;
			_useRegex.setLayoutData(gdr);
		}
		{ mixin(S_TRACE);
			auto grp = new Group(comp2, SWT.NONE);
			_textGrp2 = grp;
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			grp.setLayoutData(gd);
			grp.setText(_prop.msgs.replTextTarget);
			grp.setLayout(zeroGridLayout(1, true));
			auto checked = new LCheck;
			_checked ~= checked;
			{ mixin(S_TRACE);
				auto btns = addButtonLine(grp);
				Button createB(string text, char accr, bool summ = false) { mixin(S_TRACE);
					auto b = new Button(btns, SWT.CHECK);
					b.setText(text ~ "(&" ~ accr ~ ")");
					checked.buttons ~= b;
					b.addSelectionListener(checked);
					if (!summ) _noSummText ~= b;
					return b;
				}
				_summary = createB(_prop.msgs.replTextSummary, '1', true);
				_scenario = createB(_prop.msgs.replTextScenario, '2');
				_author = createB(_prop.msgs.replTextAuthor, '3');
				_msg = createB(_prop.msgs.replTextMessage, '4');
				_cardName = createB(_prop.msgs.replTextCardName, '5');
				_cardDesc = createB(_prop.msgs.replTextCardDesc, '6');
				_event = createB(_prop.msgs.replTextEventText, '7');
				_start = createB(_prop.msgs.replTextStart, '8');
				_flag = createB(_prop.msgs.replTextFlagAndStep, '9');
				_coupon = createB(_prop.msgs.replTextCoupon, 'A');
				_gossip = createB(_prop.msgs.replTextGossip, 'B');
				_end = createB(_prop.msgs.replTextEndScenario, 'D');
				_area = createB(_prop.msgs.replTextAreaName, 'E');
				_keyCode = createB(_prop.msgs.replTextKeyCode, 'G');
				_file = createB(_prop.msgs.replTextFile, 'H');
				_comment = createB(_prop.msgs.replTextComment, 'I');
				_jptx = createB(_prop.msgs.replTextJptx, 'K');
			}
			auto sep = new Label(grp, SWT.SEPARATOR | SWT.HORIZONTAL);
			sep.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			{ mixin(S_TRACE);
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
	void constructID(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout(zeroGridLayout(1, true));
		{ mixin(S_TRACE);
			auto grp = new Group(comp2, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setText(_prop.msgs.replID);
			grp.setLayout(new GridLayout(3, false));
			{ mixin(S_TRACE);
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
				_idKind.add(_prop.msgs.replIDFlag);
				_idKind.add(_prop.msgs.replIDStep);
				_idKind.add(_prop.msgs.replIDCoupon);
				_idKind.add(_prop.msgs.replIDGossip);
				_idKind.add(_prop.msgs.replIDCompleteStamp);
				_idKind.add(_prop.msgs.replIDKeyCode);
				// FIXME: CardWirth 1.60 セル名称
/+				_idKind.add(_prop.msgs.replIDCellName);
+/				_idKind.select(0);
				if (0 <= _prop.var.etc.searchIDKind && _prop.var.etc.searchIDKind < _idKind.getItemCount()) { mixin(S_TRACE);
					_idKind.select(_prop.var.etc.searchIDKind);
				}
				auto gd = new GridData;
				gd.horizontalSpan = 2;
				_idKind.setLayoutData(gd);
				_idKind.addSelectionListener(new SelIDKind);
			}
			{ mixin(S_TRACE);
				auto sep = new Label(grp, SWT.SEPARATOR | SWT.HORIZONTAL);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 3;
				sep.setLayoutData(gd);
			}
			void setupID(string text, ref Composite comboComp, ref Spinner spn) { mixin(S_TRACE);
				auto l = new Label(grp, SWT.NONE);
				l.setText(text);
				comboComp = new Composite(grp, SWT.NONE);
				auto cl = new CenterLayout(SWT.HORIZONTAL | SWT.VERTICAL, 0);
				cl.fillHorizontal = true;
				cl.fillVertical = true;
				comboComp.setLayout(cl);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = _prop.var.etc.nameWidth;
				comboComp.setLayoutData(gd);
				spn = new Spinner(grp, SWT.BORDER);
				initSpinner(spn);
				spn.setMinimum(1);
				spn.setMaximum(_prop.looks.idMax);
			}
			setupID(_prop.msgs.replFrom, _fromIDComp, _fromIDVal);
			setupID(_prop.msgs.replTo, _toIDComp, _toIDVal);
			updateIDCombo();
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
	void constructPath(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout(zeroGridLayout(1, true));
		{ mixin(S_TRACE);
			auto grp = new Group(comp2, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setText(_prop.msgs.replPath);
			grp.setLayout(new GridLayout(2, false));
			Combo setupPath(string text, ref IncSearch incSearch) { mixin(S_TRACE);
				auto l = new Label(grp, SWT.NONE);
				l.setText(text);
				auto combo = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN);
				combo.setVisibleItemCount(_prop.var.etc.comboVisibleItemCount);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = _prop.var.etc.nameWidth;
				combo.setLayoutData(gd);

				auto menu = new Menu(_win, SWT.POP_UP);
				combo.setMenu(menu);
				createMenuItem(_comm, menu, MenuID.IncSearch, {
					.forceFocus(combo, true);
					incSearch.startIncSearch();
				}, null);
				new MenuItem(menu, SWT.SEPARATOR);
				createTextMenu!Combo(_comm, _prop, combo, &catchMod);

				incSearch = new IncSearch(_comm, combo);

				return combo;
			}
			_fromPath = setupPath(_prop.msgs.replFrom, _fromPathIncSearch);
			_fromPathIncSearch.modEvent ~= () => setupPathsImpl(true, false);
			_toPath = setupPath(_prop.msgs.replTo, _toPathIncSearch);
			_fromPathIncSearch.modEvent ~= () => setupPathsImpl(false, true);
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
	void constructContents(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout(zeroGridLayout(1, true));
		{ mixin(S_TRACE);
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
			foreach (cGrp, cs; CTYPE_GROUP) { mixin(S_TRACE);
				foreach (cType; cs) { mixin(S_TRACE);
					auto text = _prop.msgs.contentName(cType);
					auto img = _prop.images.content(cType);
					void delegate() func = null;
					auto ti = createToolItem2(_comm, bar, text, img, func, null, SWT.CHECK);
					_contents[cType] = ti;
					checked.buttons ~= ti;
					ti.addSelectionListener(checked);
				}
				if (cGrp < CTypeGroup.max) { mixin(S_TRACE);
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
	void constructCoupon(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		auto comp2gl = windowGridLayout(1, true);
		comp2gl.marginWidth = 0;
		comp2gl.marginHeight = 0;
		comp2.setLayout(comp2gl);
		{ mixin(S_TRACE);
			auto grp = new Group(comp2, SWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			grp.setLayoutData(gd);
			grp.setText(_prop.msgs.searchRange);
			grp.setLayout(zeroGridLayout(1, true));
			auto checked = new LCheck;
			_checked ~= checked;
			{ mixin(S_TRACE);
				auto btns = addButtonLine(grp);
				Button createB(string text, char accr) { mixin(S_TRACE);
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
				// FIXME: CardWirth 1.60 セル名称
/+				_cCellName = createB(_prop.msgs.replTextCellName, '5');
+/			}
			auto sep = new Label(grp, SWT.SEPARATOR | SWT.HORIZONTAL);
			sep.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			{ mixin(S_TRACE);
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
	void constructUnuse(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout(zeroGridLayout(1, true));
		{ mixin(S_TRACE);
			auto grp = new Group(comp2, SWT.NONE);
			grp.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
			grp.setText(_prop.msgs.replUnuseTarget);
			grp.setLayout(zeroGridLayout(1, true));
			auto checked = new LCheck;
			_checked ~= checked;
			{ mixin(S_TRACE);
				auto btns = addButtonLine(grp);
				Button createB(string text, char accr) { mixin(S_TRACE);
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
			{ mixin(S_TRACE);
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
	void constructError(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout(zeroGridLayout(1, true));
		{ mixin(S_TRACE);
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
	void constructGrep(CTabFolder tabf) { mixin(S_TRACE);
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout(new GridLayout(1, true));
		auto comp2 = new Composite(comp, SWT.NONE);
		auto comp2gl = windowGridLayout(1, true);
		comp2gl.marginWidth = 0;
		comp2gl.marginHeight = 0;
		comp2.setLayout(comp2gl);

		{ mixin(S_TRACE);
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
		{ mixin(S_TRACE);
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
			.listener(grepDirRef, SWT.Selection, { mixin(S_TRACE);
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
			.listener(_grepDir, SWT.Modify, { mixin(S_TRACE);
				if (ignoreMod) return;
				_prop.var.etc.grepDir = _grepDir.getText();
			});
			.listener(_grepSubDir, SWT.Selection, { mixin(S_TRACE);
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
	void setGrepCurrentDir() { mixin(S_TRACE);
		if (_summ) { mixin(S_TRACE);
			auto sc = _summ.scenarioPath.dirName();
			if (_summ.useTemp) sc = _summ.zipName.dirName();
			_grepDir.setText(sc);
		}
	}

	void refFunc(bool Del, A : CWXPath)(A a) { mixin(S_TRACE);
		bool recurse(TreeItem itm) { mixin(S_TRACE);
			if (a is itm.getData()) { mixin(S_TRACE);
				static if (Del) {
					itm.dispose();
				} else { mixin(S_TRACE);
					itm.setText(a.name);
				}
				return true;
			} else { mixin(S_TRACE);
				foreach (child; itm.getItems()) { mixin(S_TRACE);
					if (recurse(child)) { mixin(S_TRACE);
						return true;
					}
				}
				return false;
			}
		}
		foreach (child; _range.getItems()) { mixin(S_TRACE);
			if (recurse(child)) { mixin(S_TRACE);
				return;
			}
		}
		static if (!Del) {
			// 追加
			refreshRangeTree();
		}
	}
	void delArea(Area a) { mixin(S_TRACE);
		refFunc!true(a);
	}
	void delBattle(Battle a) { mixin(S_TRACE);
		refFunc!true(a);
	}
	void delPackage(Package a) { mixin(S_TRACE);
		refFunc!true(a);
	}
	void delCast(CastCard a) { mixin(S_TRACE);
		refFunc!true(a);
	}
	void delSkill(CWXPath owner, SkillCard a) { mixin(S_TRACE);
		refFunc!true(a);
	}
	void delItem(CWXPath owner, ItemCard a) { mixin(S_TRACE);
		refFunc!true(a);
	}
	void delBeast(CWXPath owner, BeastCard a) { mixin(S_TRACE);
		refFunc!true(a);
	}
	void delInfo(InfoCard a) { mixin(S_TRACE);
		refFunc!true(a);
	}
	void refArea(Area a) { mixin(S_TRACE);
		if (_prop.var.etc.showAreaDirTree) {
			refreshRangeTree();
		} else {
			refFunc!false(a);
		}
	}
	void refBattle(Battle a) { mixin(S_TRACE);
		if (_prop.var.etc.showAreaDirTree) {
			refreshRangeTree();
		} else {
			refFunc!false(a);
		}
	}
	void refPackage(Package a) { mixin(S_TRACE);
		if (_prop.var.etc.showAreaDirTree) {
			refreshRangeTree();
		} else {
			refFunc!false(a);
		}
	}
	void refCast(CastCard a) { mixin(S_TRACE);
		refFunc!false(a);
	}
	void refSkill(SkillCard a) { mixin(S_TRACE);
		refFunc!false(a);
	}
	void refItem(ItemCard a) { mixin(S_TRACE);
		refFunc!false(a);
	}
	void refBeast(BeastCard a) { mixin(S_TRACE);
		refFunc!false(a);
	}
	void refInfo(InfoCard a) { mixin(S_TRACE);
		refFunc!false(a);
	}
	static CWXPath[] rangeTree(Summary summ) { mixin(S_TRACE);
		CWXPath[] r;
		r ~= summ;
		r ~= summ.flagDirRoot;
		foreach (a; summ.areas) r ~= a;
		foreach (a; summ.battles) r ~= a;
		foreach (a; summ.packages) r ~= a;
		foreach (a; summ.casts) { mixin(S_TRACE);
			r ~= a;
			foreach (c; a.skills) { mixin(S_TRACE);
				if (0 != c.linkId) continue;
				r ~= c;
			}
			foreach (c; a.items) { mixin(S_TRACE);
				if (0 != c.linkId) continue;
				r ~= c;
			}
			foreach (c; a.beasts) { mixin(S_TRACE);
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
	void refreshRangeTree() { mixin(S_TRACE);
		_range.setRedraw(false);
		scope (exit) _range.setRedraw(true);
		if (!_summ) { mixin(S_TRACE);
			_range.removeAll();
			return;
		}
		CWXPath sel = null;
		auto selItm = _range.getSelection();
		if (selItm.length) { mixin(S_TRACE);
			sel = cast(CWXPath)selItm[0].getData();
		}
		_range.removeAll();
		TreeItem add(TreeItem par, string name, CWXPath path) { mixin(S_TRACE);
			TreeItem itm;
			if (par) { mixin(S_TRACE);
				itm = new TreeItem(par, SWT.NONE);
			} else { mixin(S_TRACE);
				itm = new TreeItem(_range, SWT.NONE);
			}
			string text1, text2;
			Image img1, img2;
			getPathParams(path, text1, text2, img1, img2, false);
			itm.setText(name);
			itm.setImage(img1);
			itm.setData(cast(Object) path);
			itm.setChecked(true);
			if (sel is path) { mixin(S_TRACE);
				_range.setSelection([itm]);
			}
			return itm;
		}
		add(null, _prop.msgs.summary, _summ);
		add(null, _prop.msgs.flagsAndSteps, _summ.flagDirRoot);
		if (_prop.var.etc.showAreaDirTree) { mixin(S_TRACE);
			TreeItem[string] itmTable;
			auto dirSet = new HashSet!string;
			auto dirSet2 = new HashSet!string;
			void put1(string dirName) { mixin(S_TRACE);
				auto l = dirName.toLower();
				if (dirSet2.contains(l)) return;
				dirSet.add(dirName);
				dirSet2.add(l);
			}
			foreach (a; _summ.areas) put1(a.dirName);
			foreach (a; _summ.battles) put1(a.dirName);
			foreach (a; _summ.packages) put1(a.dirName);
			bool delegate(string, string) cmps;
			if (_prop.var.etc.logicalSort) {
				cmps = (a, b) => incmp(a, b) < 0;
			} else {
				cmps = (a, b) => icmp(a, b) < 0;
			}
			foreach (dirName; .sortDlg(dirSet.toArray(), cmps)) { mixin (S_TRACE);
				auto dirs = .split(dirName, "\\");
				TreeItem itm = null;
				foreach (i, dir; dirs) { mixin (S_TRACE);
					auto fPath = dirs[0 .. i + 1].join("\\");
					auto path = fPath.toLower();
					auto p = path in itmTable;
					if (p) { mixin (S_TRACE);
						itm = *p;
					} else { mixin (S_TRACE);
						TreeItem sub;
						if (itm) { mixin (S_TRACE);
							sub = new TreeItem(itm, SWT.NONE);
						} else { mixin (S_TRACE);
							sub = new TreeItem(_range, SWT.NONE);
						}
						sub.setText(dir);
						sub.setImage(_prop.images.areaDir);
						sub.setChecked(true);
						itm = sub;
						itmTable[path] = sub;
					}
				}
				itmTable[dirName.toLower()] = itm;
			}
			void put(A)(A[] arr) { mixin (S_TRACE);
				foreach (a; arr) { mixin (S_TRACE);
					add(itmTable[a.dirName.toLower()], .tryFormat("%s.%s", a.id, a.baseName), a);
				}
			}
			put(_summ.areas);
			put(_summ.battles);
			put(_summ.packages);
		} else { mixin(S_TRACE);
			foreach (a; _summ.areas) add(null, a.name, a);
			foreach (a; _summ.battles) add(null, a.name, a);
			foreach (a; _summ.packages) add(null, a.name, a);
		}
		foreach (a; _summ.casts) { mixin(S_TRACE);
			auto par = add(null, .tryFormat("%s.%s", a.id, a.name), a);
			foreach (c; a.skills) { mixin(S_TRACE);
				if (0 != c.linkId) continue;
				add(par, .tryFormat("%s.%s", c.id, c.name), c);
			}
			foreach (c; a.items) { mixin(S_TRACE);
				if (0 != c.linkId) continue;
				add(par, .tryFormat("%s.%s", c.id, c.name), c);
			}
			foreach (c; a.beasts) { mixin(S_TRACE);
				if (0 != c.linkId) continue;
				add(par, .tryFormat("%s.%s", c.id, c.name), c);
			}
		}
		foreach (a; _summ.skills) { mixin(S_TRACE);
			add(null, .tryFormat("%s.%s", a.id, a.name), a);
		}
		foreach (a; _summ.items) { mixin(S_TRACE);
			add(null, .tryFormat("%s.%s", a.id, a.name), a);
		}
		foreach (a; _summ.beasts) { mixin(S_TRACE);
			add(null, .tryFormat("%s.%s", a.id, a.name), a);
		}
		foreach (a; _summ.infos) { mixin(S_TRACE);
			add(null, .tryFormat("%s.%s", a.id, a.name), a);
		}
		_range.treeExpandedAll();
		_range.showSelection();
		_comm.refreshToolBar();
	}
	void refreshRangeAllCheck() { mixin(S_TRACE);
		bool recurse(TreeItem itm) { mixin(S_TRACE);
			if (!itm.getChecked()) { mixin(S_TRACE);
				return true;
			} else { mixin(S_TRACE);
				foreach (child; itm.getItems()) { mixin(S_TRACE);
					if (recurse(child)) { mixin(S_TRACE);
						return true;
					}
				}
				return false;
			}
		}
		foreach (child; _range.getItems()) { mixin(S_TRACE);
			if (recurse(child)) { mixin(S_TRACE);
				_rangeAllCheck.setSelection(false);
				return;
			}
		}
		_rangeAllCheck.setSelection(true);
	}
	class RefRangeAllCheck : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			if (SWT.CHECK != e.detail) return;
			auto par = (cast(TreeItem)e.item);
			// アイテムが単なるコンテナであれば
			// 下のアイテムの状態を一括で切り替える
			if (par && !par.getData()) { mixin(S_TRACE);
				void recurse(TreeItem itm) { mixin(S_TRACE);
					itm.setChecked(par.getChecked());
					foreach (child; itm.getItems()) recurse(child);
				}
				foreach (itm; par.getItems()) { mixin(S_TRACE);
					recurse(itm);
				}
			}
			// 上のアイテムが単なるコンテナであれば
			// 下のアイテムの状態によってチェック状態を切り替える
			while (par && par.getParentItem() && !par.getParentItem().getData()) { mixin(S_TRACE);
				bool same = true;
				void recurse2(TreeItem itm) { mixin(S_TRACE);
					if (itm.getChecked() != par.getChecked()) { mixin(S_TRACE);
						same = false;
						return;
					}
					foreach (child; itm.getItems()) recurse2(child);
				}
				foreach (itm; par.getParentItem().getItems()) { mixin(S_TRACE);
					recurse2(itm);
				}
				if (!same) break;
				par.getParentItem().setChecked(par.getChecked());
				par = par.getParentItem();
			}
			refreshRangeAllCheck();
		}
	}
	class RangeAllCheck : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
			void recurse(TreeItem itm) { mixin(S_TRACE);
				itm.setChecked(_rangeAllCheck.getSelection());
				foreach (child; itm.getItems()) { mixin(S_TRACE);
					recurse(child);
				}
			}
			foreach (child; _range.getItems()) { mixin(S_TRACE);
				recurse(child);
			}
		}
	}
	void refUndoMax() { mixin(S_TRACE);
		_undo.max = _prop.var.etc.undoMaxReplace;
	}
public:
	this (Commons comm, Props prop, Shell shell, Summary summ, void delegate() sendReloadProps) { mixin(S_TRACE);
		_uiThread = core.thread.Thread.getThis();
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_undo = new UndoManager(_prop.var.etc.undoMaxReplace);
		_sendReloadProps = sendReloadProps;
		_win = new Shell(shell, SWT.SHELL_TRIM);
		_win.setText(_prop.msgs.dlgTitReplaceText);
		_win.setImage(prop.images.menu(MenuID.Find));

		_display = shell.getDisplay();

		setup();
		_win.open();
		_win.setActive();
	}
	@property
	Shell widget() { mixin(S_TRACE);
		return _win;
	}
	@property
	void summary(Summary summ) { mixin(S_TRACE);
		if (_win.isDisposed()) return;
		if (!summ) { mixin(S_TRACE);
			_win.close();
		} else { mixin(S_TRACE);
			_summ = summ;
			reset();
			refreshRangeTree();
			setupIDs(true, true, true);
		}
		_undo.reset();
		_comm.refreshToolBar();
	}

	void open() { mixin(S_TRACE);
		reset();
		tabChanged();
		auto tab = _tabf.getSelection();
		if (tab is _tabText) { mixin(S_TRACE);
			_from.setFocus();
		} else if (tab is _tabID) { mixin(S_TRACE);
			_idKind.setFocus();
		} else if (tab is _tabPath) { mixin(S_TRACE);
			_fromPath.setFocus();
		} else if (tab is _tabContents) { mixin(S_TRACE);
			// Nothing
		} else if (tab is _tabCoupon) { mixin(S_TRACE);
			// Nothing
		} else if (tab is _tabUnuse) { mixin(S_TRACE);
			// Nothing
		} else if (tab is _tabError) { mixin(S_TRACE);
			// Nothing
		} else if (tab is _tabGrep) { mixin(S_TRACE);
			_from.setFocus();
		} else assert (0);
	}
	void replaceText(string from, bool start = false) { mixin(S_TRACE);
		reset();
		_from.setText(from);
		_to.setText("");
		_tabf.setSelection(_tabText);
		tabChanged();
		_from.setFocus();
		if (start) { mixin(S_TRACE);
			search();
		}
	}
	void replacePath(string from, bool start = false) { mixin(S_TRACE);
		reset();
		_fromPath.setText(from);
		_toPath.setText("");
		_tabf.setSelection(_tabPath);
		tabChanged();
		_fromPath.setFocus();
		if (start) { mixin(S_TRACE);
			search();
		}
	}
	void replaceID(ID)(ID from, bool start = false) { mixin(S_TRACE);
		reset();
		static if (is(ID:AreaId)) {
			_idKind.select(ID_AREA);
		} else static if (is(ID:BattleId)) {
			_idKind.select(ID_BATTLE);
		} else static if (is(ID:PackageId)) {
			_idKind.select(ID_PACKAGE);
		} else static if (is(ID:CastId)) {
			_idKind.select(ID_CAST);
		} else static if (is(ID:SkillId)) {
			_idKind.select(ID_SKILL);
		} else static if (is(ID:ItemId)) {
			_idKind.select(ID_ITEM);
		} else static if (is(ID:BeastId)) {
			_idKind.select(ID_BEAST);
		} else static if (is(ID:InfoId)) {
			_idKind.select(ID_INFO);
		} else static if (is(ID:FlagId)) {
			_idKind.select(ID_FLAG);
		} else static if (is(ID:StepId)) {
			_idKind.select(ID_STEP);
		} else static if (is(ID:CouponId)) {
			_idKind.select(ID_COUPON);
		} else static if (is(ID:GossipId)) {
			_idKind.select(ID_GOSSIP);
		} else static if (is(ID:CompleteStampId)) {
			_idKind.select(ID_COMPLETE_STAMP);
		} else static if (is(ID:KeyCodeId)) {
			_idKind.select(ID_KEY_CODE);
		} else static if (is(ID:CellNameId)) {
			// FIXME: CardWirth 1.60 セル名称
/+			_idKind.select(ID_CELL_NAME);
+/		} else static assert (0);
		selIDKind();
		static if (is(typeof(from.id):ulong)) {
			bool sel = false;
			foreach (index, id; _fromIDTbl) { mixin(S_TRACE);
				if (id == from.id) { mixin(S_TRACE);
					_fromID.select(index);
					sel = true;
					break;
				}
			}
			if (!sel) return;
		} else {
			_fromID.setText(cast(string)from);
		}
		_tabf.setSelection(_tabID);
		tabChanged();
		_fromID.setFocus();
		if (start) { mixin(S_TRACE);
			search();
		}
	}

	private void openRangePath() { mixin(S_TRACE);
		auto sels = _range.getSelection();
		if (!sels.length) return;
		auto data = cast(CWXPath)sels[0].getData();
		if (!data) return;
		string path = data.cwxPath(true);
		path = cpaddattr(path, "shallow");
		auto r = _comm.openCWXPath(path, false);
		if (!r) { mixin(S_TRACE);
			MessageBox.showWarning(.tryFormat(_prop.msgs.cwxPathOpenError, path), _prop.msgs.dlgTitWarning, _win);
		}
	}
	private class OpenPath : MouseAdapter, KeyListener {
		override void mouseDoubleClick(MouseEvent e) { mixin(S_TRACE);
			if (1 == e.button) { mixin(S_TRACE);
				openRangePath();
			}
		}
		override void keyReleased(KeyEvent e) {}
		override void keyPressed(KeyEvent e) { mixin(S_TRACE);
			if (SWT.CR == e.character) openRangePath();
		}
	}
	private void setup() { mixin(S_TRACE);
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
		{ mixin(S_TRACE);
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
		{ mixin(S_TRACE);
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
			_edit = new TableTextEdit(_comm, _prop, _result, 0, &couponEditEnd, &canCouponEdit);
		}
		{ mixin(S_TRACE);
			auto comp = new Composite(left, SWT.NONE);
			comp.setLayout(zeroMarginGridLayout(2, false));
			comp.setLayoutData(new GridData(GridData.HORIZONTAL_ALIGN_END));
			auto realtime = new Button(comp, SWT.CHECK);
			realtime.setText(_prop.msgs.searchResultRealtime);
			realtime.setSelection(_prop.var.etc.searchResultRealtime);
			.listener(realtime, SWT.Selection, { mixin(S_TRACE);
				_prop.var.etc.searchResultRealtime = realtime.getSelection();
				if (_prop.var.etc.searchResultRealtime) { mixin(S_TRACE);
					resultRedraw(true);
				} else if (_inProc) { mixin(S_TRACE);
					resultRedraw(false);
				}
			});
			auto openDlg = new Button(comp, SWT.CHECK);
			openDlg.setText(_prop.msgs.searchOpenDialog);
			openDlg.setSelection(_prop.var.etc.searchOpenDialog);
			openDlg.addSelectionListener(new class SelectionAdapter {
				override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
					_prop.var.etc.searchOpenDialog = openDlg.getSelection();
				}
			});
		}
		{ mixin(S_TRACE);
			auto grp = new Group(right, SWT.NONE);
			grp.setText(_prop.msgs.searchRange);
			grp.setLayoutData(new GridData(GridData.FILL_BOTH));
			grp.setLayout(new GridLayout(1, true));
			_range = new Tree(grp, SWT.SINGLE | SWT.BORDER | SWT.VIRTUAL | SWT.CHECK);
			initTree(_comm, _range, false);
			_range.addSelectionListener(new RefRangeAllCheck);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = 0;
			gd.heightHint = 0;
			_range.setLayoutData(gd);
			refreshRangeTree();
			_rangeAllCheck = new Button(grp, SWT.CHECK);
			_rangeAllCheck.setText(_prop.msgs.allCheckRange);
			refreshRangeAllCheck();
			_rangeAllCheck.addSelectionListener(new RangeAllCheck);
			auto openPath = new OpenPath;
			_range.addKeyListener(openPath);
			_range.addMouseListener(openPath);
			auto menu = new Menu(_win, SWT.POP_UP);
			createMenuItem(_comm, menu, MenuID.OpenAtView, &openRangePath, () => _range.getSelection().length > 0 && cast(CWXPath)_range.getSelection()[0].getData());
			_range.setMenu(menu);
		}
		{ mixin(S_TRACE);
			auto sep = new Label(_win, SWT.SEPARATOR | SWT.HORIZONTAL);
			sep.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
		}
		{ mixin(S_TRACE);
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
			Button createButton(string text, void delegate() push) { mixin(S_TRACE);
				auto b = new Button(comp, SWT.PUSH);
				b.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));
				b.setText(text);
				auto sa = new class SelectionAdapter {
					private void delegate() push;
					override void widgetSelected(SelectionEvent e) { mixin(S_TRACE);
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
			_close = createButton(_prop.msgs.dlgTextClose, &exit);
			auto cancel = createButton(_prop.msgs.searchCancel, { mixin(S_TRACE);
				_cancel = true;
				resultRedraw(true);
			});
			_comm.put(cancel, &canCancel);
		}
		auto d = _tabf.getDisplay();
		auto keyFilter = new class Listener {
			override void handleEvent(Event e) { mixin(S_TRACE);
				auto fc = d.getFocusControl();
				if (!fc || !_tabf.isDescendant(fc)) return;
				if (e.character == SWT.CR) { mixin(S_TRACE);
					search();
				}
			}
		};
		d.addFilter(SWT.KeyDown, keyFilter);
		.listener(_tabf, SWT.Dispose, { mixin(S_TRACE);
			d.removeFilter(SWT.KeyDown, keyFilter);
		});

		ignoreMod = true;
		scope (exit) ignoreMod = false;
		setComboItems(_from, _prop.var.etc.searchHistories.dup);
		setComboItems(_to, _prop.var.etc.replaceHistories.dup);
		setComboItems(_grepDir, _prop.var.etc.grepDirHistories.dup);
		_notIgnoreCase.setSelection(_prop.var.etc.replaceTextNotIgnoreCase);
		_exact.setSelection(_prop.var.etc.replaceTextExactMatch);
		_ignoreReturnCode.setSelection(_prop.var.etc.replaceTextIgnoreReturnCode);
		_useRegex.setSelection(_prop.var.etc.replaceTextRegExp);
		_useWildcard.setSelection(_prop.var.etc.replaceTextWildcard);
		_summary.setSelection(_prop.var.etc.replaceTextSummary);
		_scenario.setSelection(_prop.var.etc.replaceTextScenario);
		_author.setSelection(_prop.var.etc.replaceTextAuthor);
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
		if (_prop.var.etc.grepDir.length) { mixin(S_TRACE);
			_grepDir.setText(_prop.var.etc.grepDir);
		} else { mixin(S_TRACE);
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
		_contents[CType.BRANCH_KEY_CODE].setSelection(_prop.var.etc.searchContentsBranchKeyCode);
		_contents[CType.CHECK_STEP].setSelection(_prop.var.etc.searchContentsCheckStep);
		_contents[CType.BRANCH_ROUND].setSelection(_prop.var.etc.searchContentsBranchRound);

		_cCoupon.setSelection(_prop.var.etc.replaceNameCoupon);
		_cGossip.setSelection(_prop.var.etc.replaceNameGossip);
		_cEnd.setSelection(_prop.var.etc.replaceNameEndScenario);
		_cKeyCode.setSelection(_prop.var.etc.replaceNameKeyCode);
		// FIXME: CardWirth 1.60 セル名称
/+		_cCellName.setSelection(_prop.var.etc.replaceNameCellName);
+/
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
		foreach (l; _checked) { mixin(S_TRACE);
			l.check();
		}
		_tabf.setSelection(0);
		if (0 <= _prop.var.etc.searchPlan && _prop.var.etc.searchPlan < _tabf.getItemCount()) { mixin(S_TRACE);
			_tabf.setSelection(_prop.var.etc.searchPlan);
		}

		sash.addDisposeListener(new SashDispose);
		sash.setWeights([_prop.var.etc.replaceRangeSashL, _prop.var.etc.replaceRangeSashR]);

		_comm.refTableViewStyle.add(&refreshRangeTree);
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
	private void saveWin() { mixin(S_TRACE);
		auto winProps = _prop.var.replaceDlg;
		if (!_win.getMaximized()) { mixin(S_TRACE);
			winProps.width = _win.getSize().x;
			winProps.height = _win.getSize().y;
			winProps.x = _win.getBounds().x - _win.getParent().getBounds().x;
			winProps.y = _win.getBounds().y - _win.getParent().getBounds().y;
		}
		winProps.maximized = _win.getMaximized();
	}
	private class SashDispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			auto sash = cast(SplitPane) e.widget;
			auto ws = sash.getWeights();
			_prop.var.etc.replaceRangeSashL = ws[0];
			_prop.var.etc.replaceRangeSashR = ws[1];
		}
	}
	private class DL : DisposeListener {
		override void widgetDisposed(DisposeEvent e) { mixin(S_TRACE);
			_cancel = true;
			_comm.changed.remove(&changed);
			_comm.refScenario.remove(&summary);
			saveWin();
			_prop.var.etc.replaceTextNotIgnoreCase = _notIgnoreCase.getSelection();
			_prop.var.etc.replaceTextExactMatch = _exact.getSelection();
			_prop.var.etc.replaceTextIgnoreReturnCode = _ignoreReturnCode.getSelection();
			_prop.var.etc.replaceTextRegExp = _useRegex.getSelection();
			_prop.var.etc.replaceTextWildcard = _useWildcard.getSelection();
			_prop.var.etc.replaceTextSummary = _summary.getSelection();
			_prop.var.etc.replaceTextScenario = _scenario.getSelection();
			_prop.var.etc.replaceTextAuthor = _author.getSelection();
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
			_prop.var.etc.searchContentsBranchKeyCode = _contents[CType.BRANCH_KEY_CODE].getSelection();
			_prop.var.etc.searchContentsCheckStep = _contents[CType.CHECK_STEP].getSelection();
			_prop.var.etc.searchContentsBranchRound = _contents[CType.BRANCH_ROUND].getSelection();

			_prop.var.etc.replaceNameCoupon = _cCoupon.getSelection();
			_prop.var.etc.replaceNameGossip = _cGossip.getSelection();
			_prop.var.etc.replaceNameEndScenario = _cEnd.getSelection();
			_prop.var.etc.replaceNameKeyCode = _cKeyCode.getSelection();
			// FIXME: CardWirth 1.60 セル名称
/+			_prop.var.etc.replaceNameCellName = _cCellName.getSelection();
+/
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

			_comm.refTableViewStyle.remove(&refreshRangeTree);
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
	private void changed() { mixin(S_TRACE);
		if (!_inUndo && !_inProc) { mixin(S_TRACE);
			_undo.reset();
		}
		auto thr = core.thread.Thread.getThis();
		if (&_uiThread !is &thr) return;
		if (_inGrep) return;
		if (_inUndo) return;
		if (_inProc) { mixin(S_TRACE);
			_cancel = true;
		} else { mixin(S_TRACE);
			_comm.refreshToolBar();
		}
	}
	private void undo() { mixin(S_TRACE);
		if (!_undo.canUndo) return;
		scope (exit) {
			_comm.refreshToolBar();
		}
		_inProc = true;
		scope (exit) _inProc = false;
		_inUndo = true;
		scope (exit) _inUndo = false;
		resultRedraw(false);
		scope (exit) resultRedraw(true);
		_undo.undo();
		_comm.updateJpy1Files();
	}
	private void redo() { mixin(S_TRACE);
		if (!_undo.canRedo) return;
		scope (exit) {
			_comm.refreshToolBar();
		}
		_inProc = true;
		scope (exit) _inProc = false;
		_inUndo = true;
		scope (exit) _inUndo = false;
		resultRedraw(false);
		scope (exit) resultRedraw(true);
		_undo.redo();
		_comm.updateJpy1Files();
	}
	/// 外部で検索した結果を表示する。
	void setFindResult(CWXPath[] paths, string kind) { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) return;
		resultRedraw(false);
		scope (exit) resultRedraw(true);
		reset();
		initReplaceText();
		foreach (path; paths) { mixin(S_TRACE);
			addResultImpl(path);
		}
		refResultStatusImpl(paths.length, kind);
	}
	private void search() { mixin(S_TRACE);
		auto c = _win.getDisplay().getFocusControl();
		_replMode = false;
		replaceImpl();
		if (c) .forceFocus(c, false);
	}
	private void replace() { mixin(S_TRACE);
		auto c = _win.getDisplay().getFocusControl();
		_replMode = true;
		replaceImpl();
		if (c) .forceFocus(_replace, false);
	}
	private void reset(bool removeColumns = true) { mixin(S_TRACE);
		if (!_inUndo && !_inProc) { mixin(S_TRACE);
			_undo.reset();
		}
		_result.removeAll();
		_grepCount = -1;
		if (removeColumns && _result.getColumnCount()) { mixin(S_TRACE);
			foreach (column; _result.getColumns()) { mixin(S_TRACE);
				column.dispose();
			}
			_result.setHeaderVisible(false);
		}
		if (_replMode) { mixin(S_TRACE);
			_status.setText(_prop.msgs.replResultEmpty);
		} else { mixin(S_TRACE);
			_status.setText(_prop.msgs.searchResultEmpty);
		}
		_lastFind = null;
		_comm.refreshToolBar();
	}
	@property
	private bool canFind() { mixin(S_TRACE);
		if (_inProc) return false;
		if (!_tabf || _tabf.isDisposed()) return false;
		auto sel = _tabf.getSelection();
		if (!sel) return false;
		if (sel is _tabText) { mixin(S_TRACE);
			return _summ && _from.getText().length > 0;
		} else if (sel is _tabID) { mixin(S_TRACE);
			return _summ && canReplID();
		} else if (sel is _tabPath) { mixin(S_TRACE);
			return _summ && _fromPath.getText().length > 0;
		} else if (sel is _tabContents) { mixin(S_TRACE);
			return _summ !is null;
		} else if (sel is _tabCoupon) { mixin(S_TRACE);
			return _summ !is null;
		} else if (sel is _tabUnuse) { mixin(S_TRACE);
			return _summ !is null;
		} else if (sel is _tabError) { mixin(S_TRACE);
			return _summ !is null;
		} else if (sel is _tabGrep) { mixin(S_TRACE);
			return true;
		} else assert (0);
	}
	@property
	private bool canReplace() { mixin(S_TRACE);
		if (_inProc) return false;
		if (!_tabf || _tabf.isDisposed()) return false;
		auto sel = _tabf.getSelection();
		if (!sel) return false;
		if (!_summ) return false;
		return canFind && ((sel is _tabText && !_ignoreReturnCode.getSelection()) || sel is _tabID || sel is _tabPath);
	}
	private bool canCancel() { mixin(S_TRACE);
		return _inProc;
	}
	private void replaceImpl() { mixin(S_TRACE);
		if (_inProc) return;
		_rUndo.length = 0;
		_after.length = 0;

		_notIgnoreCaseSel = _notIgnoreCase.getSelection();
		_exactSel = _exact.getSelection();
		_ignoreReturnCodeSel = _ignoreReturnCode.getSelection();
		_summarySel = _summary.getSelection();
		_scenarioSel = _scenario.getSelection();
		_authorSel = _author.getSelection();
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
		_jptxSel = _jptx.getSelection();
		_fromText = _from.getText();
		_toText = _to.getText();

		_flagDirOnRange = false;
		foreach (itm; _range.getItems()) { mixin(S_TRACE);
			if (itm.getChecked()) { mixin(S_TRACE);
				auto root = cast(FlagDir) itm.getData();
				if (root) { mixin(S_TRACE);
					_flagDirOnRange = true;
					break;
				}
			}
		}

		_cancel = false;
		if (_tabf.getSelection() is _tabText) { mixin(S_TRACE);
			replaceTextImpl();
		} else if (_tabf.getSelection() is _tabID) { mixin(S_TRACE);
			replaceIDImpl();
		} else if (_tabf.getSelection() is _tabPath) { mixin(S_TRACE);
			replacePathImpl();
		} else if (_tabf.getSelection() is _tabContents) { mixin(S_TRACE);
			searchContents();
		} else if (_tabf.getSelection() is _tabCoupon) { mixin(S_TRACE);
			searchCoupon();
		} else if (_tabf.getSelection() is _tabUnuse) { mixin(S_TRACE);
			searchUnuseImpl();
		} else if (_tabf.getSelection() is _tabError) { mixin(S_TRACE);
			searchErrorImpl();
		} else if (_tabf.getSelection() is _tabGrep) { mixin(S_TRACE);
			grepImpl();
		} else assert (0);
	}
	private bool cautionReplace(string name1, string name2) { mixin(S_TRACE);
		if (_replMode && _prop.var.etc.cautionBeforeReplace) { mixin(S_TRACE);
			auto dlg = new MessageBox(_win, SWT.ICON_QUESTION | SWT.YES | SWT.NO);
			dlg.setMessage(.tryFormat(_prop.msgs.cautionOfReplace, name1, name2));
			dlg.setText(_prop.msgs.dlgTitQuestion);
			return SWT.YES == dlg.open();
		}
		return true;
	}
	private void after() { mixin(S_TRACE);
		foreach (a; _after) a();
		if (_after.length) { mixin(S_TRACE);
			refContentText();
			if (_replMode) _comm.replText.call();
		}
		if (_replMode && _rUndo.length) { mixin(S_TRACE);
			_undo ~= new UndoRepl(_rUndo, false);
		}
		_rUndo = [];
		_after = [];
		_comm.refreshToolBar();
	}
	@property
	private CWXPath[] searchRange() { mixin(S_TRACE);
		CWXPath[] r;
		void recurse(TreeItem itm) { mixin(S_TRACE);
			auto data = cast(CWXPath)itm.getData();
			if (data) r ~= data;
			foreach (child; itm.getItems()) { mixin(S_TRACE);
				if (child.getChecked()) { mixin(S_TRACE);
					recurse(child);
				}
			}
		}
		foreach (itm; _range.getItems()) { mixin(S_TRACE);
			if (itm.getChecked()) { mixin(S_TRACE);
				recurse(itm);
			}
		}
		return r;
	}
	private void searchAll(CWXPath path, ref uint count,
			void delegate(CWXPath path, ref uint count) dlg) { mixin(S_TRACE);
		if (cancel) return;
		dlg(path, count);
		// _rangeに含まれる要素は再帰的検索から除外する
		auto fdir = cast(FlagDir) path;
		if (fdir) { mixin(S_TRACE);
			foreach (o; fdir.flags) searchAll(o, count, dlg);
			foreach (o; fdir.steps) searchAll(o, count, dlg);
			foreach (o; fdir.subDirs) searchAll(o, count, dlg);
		}
		auto eto = cast(EventTreeOwner) path;
		if (eto) { mixin(S_TRACE);
			foreach (o; eto.trees) searchAll(o, count, dlg);
		}
		auto et = cast(EventTree) path;
		if (et) { mixin(S_TRACE);
			foreach (o; et.starts) searchAll(o, count, dlg);
		}
		auto c = cast(Content) path;
		if (c) { mixin(S_TRACE);
			foreach (o; c.backs) searchAll(o, count, dlg);
			foreach (o; c.next) searchAll(o, count, dlg);
		}
		auto area = cast(Area) path;
		if (area) { mixin(S_TRACE);
			foreach (o; area.cards) searchAll(o, count, dlg);
			foreach (o; area.backs) searchAll(o, count, dlg);
		}
		auto battle = cast(Battle) path;
		if (battle) { mixin(S_TRACE);
			foreach (o; battle.cards) searchAll(o, count, dlg);
		}
		auto mo = cast(MotionOwner) path;
		if (mo) { mixin(S_TRACE);
			foreach (m; mo.motions) { mixin(S_TRACE);
				if (m.beast && 0 == m.beast.linkId) { mixin(S_TRACE);
					searchAll(m.beast, count, dlg);
				}
			}
		}
	}

	@property
	private bool cancel() { mixin(S_TRACE);
		return _cancel;
	}

	private void setResultStatus(uint count) { mixin(S_TRACE);
		if (count > 0) { mixin(S_TRACE);
			if (_replMode && _summ) { mixin(S_TRACE);
				_summ.changed();
				_comm.refUseCount.call();
			}
		}
		_inProc = false;
		resultRedraw(true);
		refResultStatus(count, true);
	}
	private void refResultStatus(uint count, bool force) { mixin(S_TRACE);
		if (!_prop.var.etc.searchResultRealtime) { mixin(S_TRACE);
			if (!force && 0 != (count % _prop.var.etc.searchResultRefreshCount)) return;
		}
		_display.syncExec(new class Runnable {
			void run() { mixin(S_TRACE);
				if (!_win || _win.isDisposed()) return;
				if (!_tabf.getSelection()) return;
				refResultStatusImpl(count, _tabf.getSelection().getText());
			}
		});
	}
	private void refResultStatusImpl(uint count, string kind) { mixin(S_TRACE);
		string text;
		string num = .formatNum(count);
		if (_replMode) { mixin(S_TRACE);
			text = .tryFormat(_prop.msgs.replResult, num, kind);
		} else { mixin(S_TRACE);
			if (_grepSumm) { mixin(S_TRACE);
				text = .tryFormat(_prop.msgs.searchResultGrep2, _grepCount, num, _grepFile);
			} else if (_grepFile.length) { mixin(S_TRACE);
				text = .tryFormat(_prop.msgs.searchResultGrep1, _grepCount, num, _grepFile);
			} else if (0 <= _grepCount) { mixin(S_TRACE);
				text = .tryFormat(_prop.msgs.searchResultGrep3, _grepCount, num, kind);
			} else { mixin(S_TRACE);
				text = .tryFormat(_prop.msgs.searchResult, num, kind);
			}
		}
		_status.setText(text);
	}
	@property
	private bool[CWXPath] rangeTable() { mixin(S_TRACE);
		bool[CWXPath] range;
		void recurse(TreeItem itm) { mixin(S_TRACE);
			auto data = cast(CWXPath)itm.getData();
			if (data) range[data] = itm.getChecked();
			foreach (cItm; itm.getItems()) { mixin(S_TRACE);
				recurse(cItm);
			}
		}
		foreach (itm; _range.getItems()) { mixin(S_TRACE);
			recurse(itm);
		}
		return range;
	}
	private bool dec(CWXPath path, in bool[CWXPath] range) { mixin(S_TRACE);
		assert (path);
		auto p = path in range;
		if (p) { mixin(S_TRACE);
			return *p;
		}
		return dec(path.cwxParent, range);
	}
	private void replaceIDImpl2(ID)(ID from, ID to) { mixin(S_TRACE);
		if (!_summ) return;
		reset();
		_lastFind = _tabf.getSelection();

		_result.setHeaderVisible(true);
		auto mainColumn = new TableColumn(_result, SWT.NONE);
		mainColumn.setText(_prop.msgs.searchResultColumnMain);
		saveColumnWidth!("prop.var.etc.searchResultColumnMain")(_prop, mainColumn);
		auto subColumn = new TableColumn(_result, SWT.NONE);
		subColumn.setText(_prop.msgs.searchResultColumnParent);
		saveColumnWidth!("prop.var.etc.searchResultColumnParent")(_prop, subColumn);

		auto range = rangeTable;

		auto uc = _summ.useCounter;
		auto users = uc.values(from);
		_inProc = true;
		scope (exit) _inProc = false;
		size_t count = 0;

		auto cursors = setWaitCursors(_win);
		auto thr = new core.thread.Thread({ mixin(S_TRACE);
			auto exit = new class Runnable {
				override void run() { mixin(S_TRACE);
					_inProc = false;
					setResultStatus(count);
					if (count) { mixin(S_TRACE);
						_comm.replID.call();
					}
					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);

			try { mixin(S_TRACE);
				foreach (u; users) { mixin(S_TRACE);
					if (!dec(u.owner, range)) continue;
					if (_replMode) { mixin(S_TRACE);
						static if (is(ID:FlagId)) {
							u.flag = cast(string)to;
							storeID(u.owner, u, cast(string)from, cast(string)to, &u.flag);
						} else static if (is(ID:StepId)) {
							u.step = cast(string)to;
							storeID(u.owner, u, cast(string)from, cast(string)to, &u.step);
						} else static if (is(ID:CouponId)) {
							u.coupon = cast(string)to;
							storeID(u.owner, u, cast(string)from, cast(string)to, &u.coupon);
						} else static if (is(ID:GossipId)) {
							u.gossip = cast(string)to;
							storeID(u.owner, u, cast(string)from, cast(string)to, &u.gossip);
						} else static if (is(ID:CompleteStampId)) {
							u.completeStamp = cast(string)to;
							storeID(u.owner, u, cast(string)from, cast(string)to, &u.completeStamp);
						} else static if (is(ID:KeyCodeId)) {
							u.keyCode = cast(string)to;
							storeID(u.owner, u, cast(string)from, cast(string)to, &u.keyCode);
						// FIXME: CardWirth 1.60 セル名称
/+						} else static if (is(ID:CellNameId)) {
							u.cellName = cast(string)to;
							storeID(u.owner, u, cast(string)from, cast(string)to, &u.cellName);
+/						} else {
							u.id = to;
							storeID(u.owner, u, from, to, &u.id);
						}
					}
					addResult(u.owner, count);
				}
			} catch (Throwable e) {
				printStackTrace();
				debugln(e);
			}
		});
		thr.start();
	}
	private bool canReplID() {
		if (idKindIsString) {
			return _fromID.getText() != "";
		} else {
			return getID(_fromID, _fromIDVal, _fromIDTbl) !is 0;
		}
	}
	private ulong getID(Combo combo, Spinner spn, ulong[int] tbl) { mixin(S_TRACE);
		if (!_summ) return 0;
		if (combo.getSelectionIndex() == 0) { mixin(S_TRACE);
			return spn.getSelection();
		} else { mixin(S_TRACE);
			auto p = combo.getSelectionIndex() in tbl;
			if (!p) return 0;
			return *p;
		}
	}
	private string getIDName(Combo combo, Spinner spn) { mixin(S_TRACE);
		if (combo.getSelectionIndex() == 0) { mixin(S_TRACE);
			auto id = spn.getSelection();
			string objName = _idKind.getText();
			return .tryFormat(_prop.msgs.idValue, id, objName);
		} else { mixin(S_TRACE);
			return .tryFormat(_prop.msgs.replaceValue, combo.getText());
		}
	}
	private void replaceIDImpl() { mixin(S_TRACE);
		if (!_summ) return;
		int index = _idKind.getSelectionIndex();
		if (idKindIsString) {
			string from = _fromID.getText();
			string to = _toID.getText();
			if (from == "") return;
			if (from == to) _replMode = false;
			if (!cautionReplace(from, to)) return;
			switch (_idKind.getSelectionIndex()) {
			case ID_FLAG: replaceIDImpl2(toFlagId(from), toFlagId(to)); break;
			case ID_STEP: replaceIDImpl2(toStepId(from), toStepId(to)); break;
			case ID_COUPON: replaceIDImpl2(toCouponId(from), toCouponId(to)); break;
			case ID_GOSSIP: replaceIDImpl2(toGossipId(from), toGossipId(to)); break;
			case ID_COMPLETE_STAMP: replaceIDImpl2(toCompleteStampId(from), toCompleteStampId(to)); break;
			case ID_KEY_CODE: replaceIDImpl2(toKeyCodeId(from), toKeyCodeId(to)); break;
			// FIXME: CardWirth 1.60 セル名称
/+			case ID_CELL_NAME: replaceIDImpl2(toCellNameId(from), toCellNameId(to)); break;
+/			default: assert (0);
			}
		} else {
			ulong from = getID(_fromID, _fromIDVal, _fromIDTbl);
			ulong to = getID(_toID, _toIDVal, _toIDTbl);
			if (0 == from) return;
			if (from == to) _replMode = false;
			if (!cautionReplace(getIDName(_fromID, _fromIDVal), getIDName(_toID, _toIDVal))) return;
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
	}
	private void replacePathImpl() { mixin(S_TRACE);
		if (!_summ) return;
		if (!_fromPath.getText().length) return;
		string toText = _toPath.getText();
		string fromName = .tryFormat(_prop.msgs.replaceValue, _fromPath.getText());
		string toName = toText.length ? .tryFormat(_prop.msgs.replaceValue, toText) : _prop.msgs.emptyPath;
		if (!cautionReplace(fromName, toName)) return;
		auto from = toPathId(_fromPath.getText());
		auto to = toPathId(_toPath.getText());
		if (from == to) _replMode = false;
		reset();
		_lastFind = _tabf.getSelection();

		new FullTableColumn(_result, SWT.NONE);

		auto range = rangeTable;

		auto uc = _summ.useCounter;
		_inProc = true;
		scope (exit) _inProc = false;
		size_t count = 0;

		auto cursors = setWaitCursors(_win);
		auto thr = new core.thread.Thread({ mixin(S_TRACE);
			string[2][] fromTos;
			auto exit = new class Runnable {
				override void run() { mixin(S_TRACE);
					_inProc = false;
					setResultStatus(count);
					if (count) { mixin(S_TRACE);
						foreach (fromTo; std.algorithm.uniq(fromTos)) { mixin(S_TRACE);
							_comm.replPath.call(fromTo[0], fromTo[1]);
						}
					}
					_comm.updateJpy1Files();
					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);

			try { mixin(S_TRACE);
				auto wildcard = Wildcard((cast(string)from).encodePath(), 0 == filenameCharCmp('A', 'a'));
				foreach (key; uc.path.keys) { mixin(S_TRACE);
					if (wildcard.match((cast(string)key).encodePath())) { mixin(S_TRACE);
						foreach (u; uc.path.values(key)) { mixin(S_TRACE);
							if (!cast(Jpy1Sec)u && !dec(u.owner, range)) continue;
							if (_replMode) { mixin(S_TRACE);
								auto id = u.path;
								u.path = cast(string)to;
								storeID(u.owner, u, cast(string)id, cast(string)to, (string id) { mixin(S_TRACE);
									u.path = id;
								});
								fromTos ~= [cast(string)id, cast(string)to];
							}
							addResult(u.owner, count);
						}
					}
				}
			} catch (Throwable e) {
				printStackTrace();
				debugln(e);
			}
		});
		thr.start();
	}

	private void couponEditEnd(TableItem itm, int column, string text) { mixin(S_TRACE);
		auto uc = _summ.useCounter;
		if (itm.getImage() is _prop.images.couponNormal) { mixin(S_TRACE);
			renameCoupon(itm, toCouponId(itm.getText()), toCouponId(text), uc.coupon);
			_comm.refCoupons.call();
		} else if (itm.getImage() is _prop.images.gossip) { mixin(S_TRACE);
			renameCoupon(itm, toGossipId(itm.getText()), toGossipId(text), uc.gossip);
			_comm.refGossips.call();
		} else if (itm.getImage() is _prop.images.endScenario) { mixin(S_TRACE);
			renameCoupon(itm, toCompleteStampId(itm.getText()), toCompleteStampId(text), uc.completeStamp);
			_comm.refCompleteStamps.call();
		} else if (itm.getImage() is _prop.images.keyCode) { mixin(S_TRACE);
			renameCoupon(itm, toKeyCodeId(itm.getText()), toKeyCodeId(text), uc.keyCode);
			_comm.refKeyCodes.call();
		} else { mixin(S_TRACE);
			// FIXME: CardWirth 1.60 セル名称
/+			renameCoupon(itm, toCellNameId(itm.getText()), toCellNameId(text), uc.cellName);
			_comm.refCellNames.call();
+/		}
		_comm.replText.call();
	}
	private bool canCouponEdit(TableItem itm, int column) { mixin(S_TRACE);
		return _lastFind is _tabCoupon;
	}
	struct CouponParams {
		Image image;
		string name;
		uint count;
	}
	class CouponUndo(User, KeyType) : Undo {
		private CouponParams[] _results;
		private KeyType _oldVal, _newVal;
		private UCCont!(KeyType, User) _uc;
		User[] users;
		this (KeyType oldVal, KeyType newVal, UCCont!(KeyType, User) uc) { mixin(S_TRACE);
			_oldVal = oldVal;
			_newVal = newVal;
			_uc = uc;
			save();
		}
		private void save() { mixin(S_TRACE);
			_results = [];
			foreach (itm; _result.getItems()) { mixin(S_TRACE);
				_results ~= CouponParams(itm.getImage(), itm.getText(), itm.getText(1).to!uint());
			}
		}
		private void impl() { mixin(S_TRACE);
			resultRedraw(false);
			scope(exit) resultRedraw(true);
			auto results = _results;
			save();

			foreach (u; users) { mixin(S_TRACE);
				_uc.remove(_newVal, u);
				u.change(_oldVal);
				_uc.add(_oldVal, u);
			}

			foreach (i, r; results) { mixin(S_TRACE);
				auto itm = i < _result.getItemCount() ? _result.getItem(i) : new TableItem(_result, SWT.NONE);
				itm.setImage(r.image);
				itm.setText(r.name);
				itm.setText(1, r.count.text());
			}
			while (results.length < _result.getItemCount()) { mixin(S_TRACE);
				_result.getItem(results.length).dispose();
			}

			.swap(_oldVal, _newVal);
			refResultStatus(_result.getItemCount(), false);
			_comm.replText.call();
			_summ.changed();
		}
		void undo() { mixin(S_TRACE);
			impl();
		}
		void redo() { mixin(S_TRACE);
			impl();
		}
		void dispose() { }
	}
	private void renameCoupon(KeyType, UC)(TableItem itm, KeyType oldVal, KeyType newVal, UC uc) { mixin(S_TRACE);
		if (cast(string)oldVal == cast(string)newVal) return;
		if (cast(string)newVal == "") return;
		_inProc = true;
		scope (exit) _inProc = false;
		auto rangeT = rangeTable;
		auto undo = new CouponUndo!(ForeachType!(typeof(uc.values(oldVal))), KeyType)(oldVal, newVal, uc);
		foreach (u; uc.values(oldVal)) { mixin(S_TRACE);
			if (dec(u.owner, rangeT)) { mixin(S_TRACE);
				uc.remove(oldVal, u);
				u.change(newVal);
				uc.add(newVal, u);
				undo.users ~= u;
				itm.setText(0, cast(string)newVal);
			}
		}
		_undo ~= undo;
		// 変更の結果、他のキーと同一の名前になったら統合する
		foreach (i, itm2; _result.getItems()) { mixin(S_TRACE);
			if (itm is itm2) continue;
			if (itm.getImage() !is itm2.getImage()) continue;
			if (itm.getText() == itm2.getText()) { mixin(S_TRACE);
				_result.select(i);
				_result.showSelection();
				itm2.setText(1, uc.get(newVal).text());
				itm.dispose();
				break;
			}
		}
		_summ.changed();
	}
	private void searchCouponImpl(KeyType)(in KeyType[] keys, UseCounter uc, in bool[CWXPath] rangeT, Image delegate() image, ref uint count) { mixin(S_TRACE);
		foreach (key; keys.dup.sort) { mixin(S_TRACE);
			if (cancel) break;
			uint use = 0;
			foreach (u; uc.values(key)) { mixin(S_TRACE);
				if (dec(u.owner, rangeT)) { mixin(S_TRACE);
					use++;
				}
			}
			if (use) { mixin(S_TRACE);
				addResult(key, use, image, count);
			}
		}
	}
	private void searchCoupon() { mixin(S_TRACE);
		if (!_summ) return;
		uint count = 0;
		reset();
		_lastFind = _tabf.getSelection();

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
		// FIXME: CardWirth 1.60 セル名称
/+		bool cCellName = _cCellName.getSelection();
+/
		auto rangeT = rangeTable;
		auto uc = _summ.useCounter;
		void search() { mixin(S_TRACE);
			if (cCouponSel) { mixin(S_TRACE);
				searchCouponImpl(uc.coupon.keys, uc, rangeT, &_prop.images.couponNormal, count);
			}
			if (cGossipSel) { mixin(S_TRACE);
				searchCouponImpl(uc.gossip.keys, uc, rangeT, &_prop.images.gossip, count);
			}
			if (cEndSel) { mixin(S_TRACE);
				searchCouponImpl(uc.completeStamp.keys, uc, rangeT, &_prop.images.endScenario, count);
			}
			if (cKeyCodeSel) { mixin(S_TRACE);
				searchCouponImpl(uc.keyCode.keys, uc, rangeT, &_prop.images.keyCode, count);
			}
			// FIXME: CardWirth 1.60 セル名称
/+			if (cCellName) { mixin(S_TRACE);
				searchCouponImpl(uc.cellName.keys, uc, rangeT, &_prop.images.backs, count);
			}
+/		}

		_inProc = true;
		_comm.refreshToolBar();
		auto cursors = setWaitCursors(_win);
		auto thr = new core.thread.Thread({ mixin(S_TRACE);
			auto exit = new class Runnable {
				override void run() { mixin(S_TRACE);
					_inProc = false;
					setResultStatus(count);
					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);
			try { mixin(S_TRACE);
				search();
			} catch (Throwable e) {
				printStackTrace();
				debugln(e);
			}
		});
		thr.start();
	}

	private void searchContents() { mixin(S_TRACE);
		if (!_summ) return;
		uint count = 0;
		reset();
		_lastFind = _tabf.getSelection();

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
		auto cursors = setWaitCursors(_win);
		bool[CType] contents;
		foreach (type; EnumMembers!CType) { mixin(S_TRACE);
			// FIXME: CardWirth 1.60 ここから
			switch (type) {
			case CType.MOVE_BG_IMAGE: /// 背景再配置(CardWirth 1.60)。
			case CType.REPLACE_BG_IMAGE: /// 背景交換(CardWirth 1.60)。
			case CType.LOSE_BG_IMAGE: /// 背景削除(CardWirth 1.60)。
				continue;
			default:
				break;
			}
			// FIXME: CardWirth 1.60 ここまで
			contents[type] = _contents[type].getSelection();
		}
		auto thr = new core.thread.Thread({ mixin(S_TRACE);
			auto exit = new class Runnable {
				override void run() { mixin(S_TRACE);
					_inProc = false;
					setResultStatus(count);
					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);
			try { mixin(S_TRACE);
				foreach (path; range) { mixin(S_TRACE);
					searchAll(path, count, (CWXPath path, ref uint count) { mixin(S_TRACE);
						if (cancel) return;
						auto c = cast(Content) path;
						if (!c) return;
						assert (c.type in _contents);
						if (!contents[c.type]) return;
						addResult(path, count);
					});
				}
			} catch (Throwable e) {
				printStackTrace();
				debugln(e);
			}
		});
		thr.start();
	}

	private void searchUnuseImpl2(string ToId, T)(T[] all, ref uint count) { mixin(S_TRACE);
		if (!_summ) return;
		foreach (o; all) { mixin(S_TRACE);
			if (cancel) break;
			if (_summ.useCounter.get(mixin (ToId)) == 0) { mixin(S_TRACE);
				addResult(o, count);
			}
		}
	}
	private void searchUnuseImpl() { mixin(S_TRACE);
		if (!_summ) return;
		_replMode = false;
		uint count = 0;
		reset();
		_lastFind = _tabf.getSelection();

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

		void search() { mixin(S_TRACE);
			if (unuseFlagSel) { mixin(S_TRACE);
				searchUnuseImpl2!("toFlagId(o.path)")(_summ.flagDirRoot.allFlags, count);
			}
			if (unuseStepSel) { mixin(S_TRACE);
				searchUnuseImpl2!("toStepId(o.path)")(_summ.flagDirRoot.allSteps, count);
			}
			if (unuseAreaSel) { mixin(S_TRACE);
				searchUnuseImpl2!("toAreaId(o.id)")(_summ.areas, count);
			}
			if (unuseBattleSel) { mixin(S_TRACE);
				searchUnuseImpl2!("toBattleId(o.id)")(_summ.battles, count);
			}
			if (unusePackageSel) { mixin(S_TRACE);
				searchUnuseImpl2!("toPackageId(o.id)")(_summ.packages, count);
			}
			if (unuseCastSel) { mixin(S_TRACE);
				searchUnuseImpl2!("toCastId(o.id)")(_summ.casts, count);
			}
			if (unuseSkillSel) { mixin(S_TRACE);
				searchUnuseImpl2!("toSkillId(o.id)")(_summ.skills, count);
			}
			if (unuseItemSel) { mixin(S_TRACE);
				searchUnuseImpl2!("toItemId(o.id)")(_summ.items, count);
			}
			if (unuseBeastSel) { mixin(S_TRACE);
				searchUnuseImpl2!("toBeastId(o.id)")(_summ.beasts, count);
			}
			if (unuseInfoSel) { mixin(S_TRACE);
				searchUnuseImpl2!("toInfoId(o.id)")(_summ.infos, count);
			}
			if (unuseStartSel) { mixin(S_TRACE);
				foreach (path; range) { mixin(S_TRACE);
					searchAll(path, count, (CWXPath path, ref uint count) { mixin(S_TRACE);
						if (cancel) return;
						auto et = cast(EventTree) path;
						if (et) { mixin(S_TRACE);
							foreach (s; et.starts[1 .. $]) { mixin(S_TRACE);
								if (et.startUseCounter.get(toStartId(s.name)) == 0) { mixin(S_TRACE);
									addResult(s, count);
								}
							}
						}
					});
				}
			}
			if (unusePathSel) { mixin(S_TRACE);
				auto files = _summ.notUsedFiles(_comm.skin, _prop.var.etc.ignorePaths, _prop.var.etc.logicalSort);
				foreach (file; files) { mixin(S_TRACE);
					if (cancel) break;
					addResult(encodePath(file), count);
				}
			}
		}

		_inProc = true;
		_comm.refreshToolBar();
		auto cursors = setWaitCursors(_win);
		auto thr = new core.thread.Thread({ mixin(S_TRACE);
			auto exit = new class Runnable {
				override void run() { mixin(S_TRACE);
					_inProc = false;
					setResultStatus(count);
					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);
			try { mixin(S_TRACE);
				search();
			} catch (Throwable e) {
				printStackTrace();
				debugln(e);
			}
		});
		thr.start();
	}
	private void searchErrorImpl() { mixin(S_TRACE);
		if (!_summ) return;
		uint count = 0;
		auto froot = _summ.flagDirRoot;
		auto sPath = _summ.scenarioPath;
		auto skin = _comm.skin;
		auto targVer = _prop.var.etc.targetVersion;
		reset();
		_lastFind = _tabf.getSelection();

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

		void search(CWXPath path) { mixin(S_TRACE);
			searchAll(path, count, (CWXPath path, ref uint count) { mixin(S_TRACE);
				if (cancel) return;
				auto warnings = .warnings(_prop.parent, skin, _summ, path, targVer);
				foreach (warning; warnings) { mixin(S_TRACE);
					addResult(path, count, warning);
				}
			});
		}
		void searchFileErrors() { mixin(S_TRACE);
			string sPath = _summ.scenarioPath;
			string[string] digests;
			void recurse(string file) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					bool dir = .isDir(file);
					if (_summ.isSystemFile(file, dir)) return;
					if (containsPath(_prop.var.etc.ignorePaths, file.baseName())) return;
					if (dir) { mixin(S_TRACE);
						foreach (string sub; clistdir(file)) { mixin(S_TRACE);
							recurse(file.buildPath(sub));
						}
					} else { mixin(S_TRACE);
						auto size = file.getSize();
						if (!size) { mixin(S_TRACE);
							addResult(abs2rel(file, sPath), count, _prop.msgs.searchErrorEmptyFile);
							return;
						}
						auto digest = file.fileToMD5Digest();
						if (!digest.length) return;
						digest = .format("%s-%s", digest, size);

						if (auto p = digest in digests) { mixin(S_TRACE);
							addResult(abs2rel(file, sPath), count, .tryFormat(_prop.msgs.searchErrorDupFile, .encodePath(abs2rel(*p, sPath))));
							return;
						}
						digests[digest] = file;

						try { mixin(S_TRACE);
							switch (file.extension().toLower()) {
							case ".jpy1": mixin(S_TRACE);
								Jpy1.load(_prop.parent, _summ.scenarioPath, file);
								break;
							case ".jptx": mixin(S_TRACE);
								Jptx.load(_prop.parent, file);
								break;
							case ".jpdc": mixin(S_TRACE);
								Jpdc.load(_prop.parent, file);
								break;
							default:
								break;
							}
						} catch (EffectBoosterError e) { mixin(S_TRACE);
							printStackTrace();
							debugln(e);
							auto path = abs2rel(file, sPath);
							foreach (err; e.errors) { mixin(S_TRACE);
								addResult(path, count, .tryFormat(_prop.msgs.jpyErrorInfoWithoutFile, err.msg, err.line));
							}
						}
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
			recurse(sPath);
		}

		_inProc = true;
		_comm.refreshToolBar();
		auto cursors = setWaitCursors(_win);
		auto thr = new core.thread.Thread({ mixin(S_TRACE);
			auto exit = new class Runnable {
				override void run() { mixin(S_TRACE);
					_inProc = false;
					setResultStatus(count);
					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);
			try { mixin(S_TRACE);
				foreach (path; range) { mixin(S_TRACE);
					search(path);
				}
				searchFileErrors();
			} catch (Throwable e) {
				printStackTrace();
				debugln(e);
			}
		});
		thr.start();
	}
	private void replaceTextImpl(CWXPath c, ref size_t count) { mixin(S_TRACE);
		if (cancel) return;
		bool oldIgnoreMod = ignoreMod;
		ignoreMod = true;
		scope (exit) ignoreMod = oldIgnoreMod;
		size_t dmy = 0;
		auto summ = cast(Summary) c;
		if (summ) { mixin(S_TRACE);
			bool sr = false;
			Undo[] uArr;
			if (_summarySel) { mixin(S_TRACE);
				sr |= repl(null, summ.desc, &summ.desc, count, uArr);
			}
			if (_scenarioSel) { mixin(S_TRACE);
				sr |= repl(null, summ.scenarioName, &summ.scenarioName, count, uArr);
			}
			if (_authorSel) { mixin(S_TRACE);
				sr |= repl(null, summ.author, &summ.author, count, uArr);
			}
			if (_couponSel) { mixin(S_TRACE);
				sr |= replRqCoupons(null, summ, count, uArr);
			}
			if (sr) { mixin(S_TRACE);
				if (_replMode) store(summ, uArr);
				addResult(summ, dmy);
			}
		}
		auto cc = cast(CastCard) c;
		if (cc) { mixin(S_TRACE);
			Undo[] uArr;
			bool r = replCard!(CastCard)(null, cc, count, uArr);
			if (_couponSel) { mixin(S_TRACE);
				Coupon[] coupons = null;
				if (_replMode) coupons = new Coupon[cc.coupons.length];
				foreach (i, cp; cc.coupons) { mixin(S_TRACE);
					Coupon cp2 = null;
					r |= repl(null, cp.name,
						(string t) {cp2 = new Coupon(t, cp.value);}, count, uArr);
					if (_replMode) coupons[i] = cp2 ? cp2 : new Coupon(cp);
				}
				if (_replMode) cc.coupons = coupons;
			}
			if (r) { mixin(S_TRACE);
				if (_replMode) store(cc, uArr);
				addResult(cc, dmy);
			}
		}
		Undo[] nArr;
		auto eff = cast(EffectCard) c;
		if (eff) { mixin(S_TRACE);
			replCard(eff, eff, count, nArr);
		}
		auto info = cast(InfoCard) c;
		if (info) { mixin(S_TRACE);
			replCard(info, info, count, nArr);
		}
		auto a = cast(AbstractArea) c;
		if (a) { mixin(S_TRACE);
			if (_areaSel) { mixin(S_TRACE);
				repl(a, a.name, &a.name, count, nArr);
			}
		}
		auto menu = cast(MenuCard) c;
		if (menu) { mixin(S_TRACE);
			replCard(menu, menu, count, nArr);
		}
		auto back = cast(BgImage) c;
		if (back) { mixin(S_TRACE);
			replBgImage(back, back, count, nArr);
		}
		auto f = cast(Flag) c;
		if (f && _flagSel) { mixin(S_TRACE);
			Undo[] uArr = new Undo[0];
			bool r = replFlagName!Flag(f.parent, f, count, uArr);
			r |= repl(null, f.on, &f.on, count, uArr);
			r |= repl(null, f.off, &f.off, count, uArr);
			if (r) { mixin(S_TRACE);
				if (_replMode) store(f, uArr);
				addResult(f, dmy);
			}
		}
		auto s = cast(Step) c;
		if (s && _flagSel) { mixin(S_TRACE);
			Undo[] uArr;
			bool r = replFlagName!Step(s.parent, s, count, uArr);
			foreach (i, v; s.values) { mixin(S_TRACE);
				r |= repl(null, v, (string t) {s.setValue(i, t);}, count, uArr);
			}
			if (r) { mixin(S_TRACE);
				if (_replMode) store(s, uArr);
				addResult(s, dmy);
			}
		}
		auto et = cast(EventTree) c;
		if (et) { mixin(S_TRACE);
			replFKeyCode(et, et, count, nArr);
		}
		auto content = cast(Content) c;
		if (content) { mixin(S_TRACE);
			replContent(content, count);
		}
	}
	private void initText(string from, string to) { mixin(S_TRACE);
		if (_useRegex.getSelection()) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				_regex = .regex!(dstring)(toUTF32(from), _notIgnoreCase.getSelection() ? "gm" : "gim");
				_regexTarg = true;
				_toTemp = toUTF32(to);
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
				MessageBox.showWarning
					(_prop.msgs.regexError ~ "\n" ~ e.msg,
					_prop.msgs.dlgTitWarning, _win);
				return;
			}
		} else if (_useWildcard.getSelection()) { mixin(S_TRACE);
			_wildcard = Wildcard(from, !_notIgnoreCase.getSelection());
		} else { mixin(S_TRACE);
			if (from == to) _replMode = false;
		}
	}
	private void exitText() { mixin(S_TRACE);
		if (!_win || _win.isDisposed()) return;
		_wildcard = null;
		_regex = typeof(_regex).init;
		_regexTarg = false;
		_toTemp = ""d;
	}
	private static bool addHist(Combo combo, void delegate(string[]) set,
			string[] delegate() get, int max, string text) { mixin(S_TRACE);
		if (text.length) { mixin(S_TRACE);
			string[] list = get();
			if (.contains(list, text)) { mixin(S_TRACE);
				list = cwx.utils.remove(list, text);
			}
			list = [text] ~ list;
			if (list.length > max) { mixin(S_TRACE);
				list = list[0 .. $ - 1];
			}
			set(list);
			setComboItems(combo, list);
			combo.select(0);
			return true;
		}
		return false;
	}
	private void initReplaceText() {
		_result.setHeaderVisible(true);
		auto mainColumn = new TableColumn(_result, SWT.NONE);
		mainColumn.setText(_prop.msgs.searchResultColumnMain);
		saveColumnWidth!("prop.var.etc.searchResultColumnMain")(_prop, mainColumn);
		auto subColumn = new TableColumn(_result, SWT.NONE);
		subColumn.setText(_prop.msgs.searchResultColumnParent);
		saveColumnWidth!("prop.var.etc.searchResultColumnParent")(_prop, subColumn);
	}
	private void replaceTextImpl() { mixin(S_TRACE);
		if (!_summ) return;
		string from = _from.getText();
		string to = _to.getText();
		if (!from.length) return;
		string fromName = from.length ? .tryFormat(_prop.msgs.replaceValue, from) : _prop.msgs.emptyText;
		string toName = to.length ? .tryFormat(_prop.msgs.replaceValue, to) : _prop.msgs.emptyText;
		if (!cautionReplace(fromName, toName)) return;
		initText(from, to);

		size_t count = 0;
		reset();
		_lastFind = _tabf.getSelection();

		initReplaceText();

		auto range = searchRange;
		_inProc = true;
		_comm.refreshToolBar();
		bool addH = addHist(_from, (string[] s) {_prop.var.etc.searchHistories = s;},
			{return _prop.var.etc.searchHistories.dup;},
			_prop.var.etc.searchHistoryMax, from);
		if (_replMode) { mixin(S_TRACE);
			addH |= addHist(_to, (string[] s) {_prop.var.etc.replaceHistories = s;},
				{return _prop.var.etc.replaceHistories.dup;},
				_prop.var.etc.searchHistoryMax, to);
		}
		_comm.refSearchHistories.call(this);
		if (addH && _sendReloadProps) _sendReloadProps();

		void search() { mixin(S_TRACE);
			foreach (path; range) { mixin(S_TRACE);
				searchAll(path, count, &replaceTextImpl);
			}
			if (_jptxSel) { mixin(S_TRACE);
				foreach (string file; .dirEntries(_summ.scenarioPath, SpanMode.depth, false)) { mixin(S_TRACE);
					if (cancel) break;
					if (cfnmatch(.extension(file), ".jptx")) { mixin(S_TRACE);
						try { mixin(S_TRACE);
							bool isSJIS;
							auto errInfo = new EffectBoosterError;
							string value = readJPYFile(file, _prop.parent, errInfo, isSJIS);
							auto jText = jptxText(value);
							Undo[] uArr;
							string file2 = file;
							bool r = repl(null, jText, (string jText) { mixin(S_TRACE);
								string value = jptxText(value, jText);
								try { mixin(S_TRACE);
									writeJPYFile(file2, value, isSJIS);
								} catch (Exception e) {
									printStackTrace();
									debugln(e);
								}
							}, count, uArr, true);
							if (r) { mixin(S_TRACE);
								file = abs2rel(file, _summ.scenarioPath);
								size_t dmy = 0;
								addResult(file, dmy);
								store(file, uArr);
							}
						} catch (Exception e) {
							printStackTrace();
							debugln(e);
						}
					}
				}
			}
		}

		auto cursors = setWaitCursors(_win);
		auto thr = new core.thread.Thread({ mixin(S_TRACE);
			auto exit = new class Runnable {
				override void run() { mixin(S_TRACE);
					_inProc = false;
					setResultStatus(count);
					exitText();
					if (_replMode && !_after.length) _comm.replText.call();

					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);

			try { mixin(S_TRACE);
				search();
			} catch (Throwable e) {
				printStackTrace();
				debugln(e);
			}
		});
		thr.start();
	}
	private void grepImpl() { mixin(S_TRACE);
		string from = _from.getText();
		auto dirBase = _grepDir.getText();
		auto dir = _prop.toAppAbs(dirBase);
		initText(from, "");
		_replMode = false;

		size_t count = 0;
		reset();
		_grepCount = 0;
		_lastFind = _tabf.getSelection();

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
		foreach (b; _noSummText) { mixin(S_TRACE);
			if (b.getSelection()) { mixin(S_TRACE);
				opt.summaryOnly = false;
				break;
			}
		}
		if (0 == from.length) { mixin(S_TRACE);
			opt.summaryOnly = true;
		}
		bool subDir = _grepSubDir.getSelection();

		void findSumm(string summFile) { mixin(S_TRACE);
			if (cancel) return;
			_grepFile = summFile;
			scope (exit) _grepFile = "";
			refResultStatus(count, true);
			auto summ = Summary.loadScenarioFromFile(_prop.parent, opt, summFile, _prop.tempPath);
			if (!summ) return;
			_grepSumm = summ;
			_grepCount++;
			scope (exit) {
				summ.delTemp();
				_grepSkin = null;
				destroy(summ);
				_grepSumm = null;
				core.memory.GC.collect();
				core.memory.GC.minimize();
			}
			if (!_fromText.length) { mixin(S_TRACE);
				addResult(summ, count);
				return;
			}
			refResultStatus(count, true);
			auto range = rangeTree(summ);
			foreach (path; range) { mixin(S_TRACE);
				if (cancel) return;
				searchAll(path, count, &replaceTextImpl);
			}
			if (_jptxSel) { mixin(S_TRACE);
				foreach (string file; .dirEntries(summ.scenarioPath, SpanMode.depth, false)) { mixin(S_TRACE);
					if (cancel) break;
					if (cfnmatch(.extension(file), ".jptx")) { mixin(S_TRACE);
						bool isSJIS;
						auto errInfo = new EffectBoosterError;
						try { mixin(S_TRACE);
							string value = readJPYFile(file, _prop.parent, errInfo, isSJIS);
							auto jText = jptxText(value);
							Undo[] uArr;
							string file2 = file;
							bool r = repl(null, jText, null, count, uArr, true);
							if (r) { mixin(S_TRACE);
								file = abs2rel(file, summ.scenarioPath);
								size_t dmy = 0;
								addResult(file, dmy);
							}
						} catch (Exception e) {
							printStackTrace();
							debugln(e);
						}
					}
				}
			}
			refResultStatus(count, true);
		}
		void recurse(string dir, uint rec) { mixin(S_TRACE);
			if (cancel) return;
			if (dir.buildPath("Summary.xml").exists() || dir.buildPath("Summary.wsm").exists()) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					findSumm(dir);
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
			foreach (file; clistdir(dir)) { mixin(S_TRACE);
				if (cancel) break;
				try { mixin(S_TRACE);
					file = dir.buildPath(file);
					if (file.isDir()) { mixin(S_TRACE);
						if (subDir || 0 == rec) recurse(file, rec + 1);
					} else { mixin(S_TRACE);
						auto ext = file.extension();
						if (cfnmatch(ext, ".wsn") || cfnmatch(ext, ".zip") || (canUncab && cfnmatch(ext, ".cab"))) { mixin(S_TRACE);
							findSumm(file);
						}
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
		}
		_inProc = true;
		_inGrep = true;
		_comm.refreshToolBar();
		bool addH = addHist(_from, (string[] s) {_prop.var.etc.searchHistories = s;},
			{return _prop.var.etc.searchHistories.dup;},
			_prop.var.etc.searchHistoryMax, from);
		addH |= addHist(_grepDir, (string[] s) {_prop.var.etc.grepDirHistories = s;},
			{return _prop.var.etc.grepDirHistories.dup;},
			_prop.var.etc.searchHistoryMax, dirBase);
		_comm.refSearchHistories.call(this);
		if (addH && _sendReloadProps) _sendReloadProps();
		auto cursors = setWaitCursors(_win);
		auto thr = new core.thread.Thread({ mixin(S_TRACE);
			auto exit = new class Runnable {
				override void run() { mixin(S_TRACE);
					_inProc = false;
					_inGrep = false;
					exitText();
					setResultStatus(count);
					resetCursors(cursors);
					after();
				}
			};
			scope (exit) _display.syncExec(exit);
			try { mixin(S_TRACE);
				recurse(dir, 0);
			} catch (Throwable e) {
				printStackTrace();
				debugln(e);
			}
		});
		thr.start();
	}
	private void refSearchHistories(Object sender) { mixin(S_TRACE);
		if (sender is this) return;
		updateFromHistory();
		updateToHistory();
		setComboItems(_grepDir, _prop.var.etc.grepDirHistories.dup);
	}
	private void updateFromHistory() {
		string ft = _from.getText();
		_from.removeAll();
		foreach (hist; _prop.var.etc.searchHistories) {
			if (!_fromIncSearch.match(hist)) continue;
			_from.add(hist);
		}
		_from.setText(ft);
	}
	private void updateToHistory() {
		string tt = _to.getText();
		_to.removeAll();
		foreach (hist; _prop.var.etc.replaceHistories) {
			if (!_toIncSearch.match(hist)) continue;
			_to.add(hist);
		}
		_to.setText(tt);
	}
	private Regex!(dchar) _regex;
	private bool _regexTarg = false;
	private Wildcard _wildcard = null;
	private dstring _toTemp = ""d;
	private string fTextRepl(string s) { mixin(S_TRACE);
		if (_regexTarg) { mixin(S_TRACE);
			return toUTF8(std.regex.replace(toUTF32(s), _regex, _toTemp));
		}
		string to = _toText;
		if (_wildcard) { mixin(S_TRACE);
			return _wildcard.replace(s, to);
		}
		string from = _fromText;
		if (_notIgnoreCaseSel) { mixin(S_TRACE);
			if (_exactSel) { mixin(S_TRACE);
				return 0 == cmp(s, from) ? to : from;
			} else { mixin(S_TRACE);
				return .replace(s, from, to);
			}
		} else { mixin(S_TRACE);
			if (_exactSel) { mixin(S_TRACE);
				return 0 == icmp(s, from) ? to : from;
			} else { mixin(S_TRACE);
				return .ireplace(s, from, to);
			}
		}
	}
	private size_t fTextCount(string s) { mixin(S_TRACE);
		if (_ignoreReturnCodeSel) s = .singleLine(s);
		if (_regexTarg) { mixin(S_TRACE);
			size_t c = 0;
			try { mixin(S_TRACE);
				foreach (m; std.regex.match(toUTF32(s), _regex)) { mixin(S_TRACE);
					c++;
				}
			} catch (Throwable e) {
				printStackTrace();
 				debugln(_fromText, " -> ", s);
				throw e;
			}
			return c;
		}
		if (_wildcard) { mixin(S_TRACE);
			return _wildcard.count(s);
		}
		string from = _fromText;
		if (_notIgnoreCaseSel) { mixin(S_TRACE);
			if (_exactSel) { mixin(S_TRACE);
				return 0 == cmp(s, from) ? 1 : 0;
			} else { mixin(S_TRACE);
				return std.algorithm.count(s, from);
			}
		} else { mixin(S_TRACE);
			if (_exactSel) { mixin(S_TRACE);
				return 0 == icmp(s, from) ? 1 : 0;
			} else { mixin(S_TRACE);
				return .icount(s, from);
			}
		}
	}
	private void exit() { mixin(S_TRACE);
		_win.close();
	}
	private bool _replMode = false;

	private bool canOpenPath() { mixin(S_TRACE);
		auto sels = _result.getSelection();
		if (!sels.length) return false;
		foreach (itm; sels) { mixin(S_TRACE);
			auto d = itm.getData();
			if (cast(CWXPathString) d !is null || cast(FilePathString) d !is null) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
	}
	private void openPath() { mixin(S_TRACE);
		auto i = _result.getSelectionIndex();
		if (-1 == i) return;
		foreach (itm; [_result.getItem(i)] ~ _result.getItems()) { mixin(S_TRACE);
			auto d = itm.getData();
			auto rp = cast(CWXPathString) d;
			if (rp) { mixin(S_TRACE);
				auto path = rp.array;
				if (_prop.var.etc.searchOpenDialog) { mixin(S_TRACE);
					path = cpaddattr(path, "opendialog");
				}
				if (rp.scPath !is null) { mixin(S_TRACE);
					exec("\"" ~ _prop.parent.appPath ~ "\" \"" ~ rp.scPath ~ "\" " ~ path);
					return;
				}
				if (!_summ) return;
				try { mixin(S_TRACE);
					if (_comm.openCWXPath(path, false)) { mixin(S_TRACE);
						if (!_prop.var.etc.searchOpenDialog) _win.setActive();
						return;
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
				MessageBox.showWarning(.tryFormat(_prop.msgs.cwxPathOpenError, path), _prop.msgs.dlgTitWarning, _win);
				return;
			}
			if (!_summ) return;
			auto p = cast(FilePathString) d;
			if (p) { mixin(S_TRACE);
				auto path = nabs(std.path.buildPath(_summ.scenarioPath, p.array));
				if (p.scPath !is null) { mixin(S_TRACE);
					exec("\"" ~ _prop.parent.appPath ~ "\" -selectfile \"" ~ p.array ~ "\" \"" ~ p.scPath ~ "\"");
					return;
				}
				if (_comm.openFilePath(path, false)) { mixin(S_TRACE);
					_win.setActive();
					return;
				}
				MessageBox.showWarning(.tryFormat(_prop.msgs.filePathOpenError, path), _prop.msgs.dlgTitWarning, _win);
				return;
			}
		}
	}
	Image fimage(string file, Skin skin) { mixin(S_TRACE);
		return .fimage(_prop, file, skin);
	}
	private void copyResult() { mixin(S_TRACE);
		string[] t;
		foreach (itm; _result.getSelection()) { mixin(S_TRACE);
			string[] line;
			foreach (i; 0 .. _result.getColumnCount()) { mixin(S_TRACE);
				line ~= itm.getText(i).replace("\n", .newline);
			}
			t ~= std.string.join(line, "\t");
		}
		if (!t.length) return;
		auto text = new ArrayWrapperString(std.string.join(t, .newline));
		_comm.clipboard.setContents([text], [TextTransfer.getInstance()]);
		_comm.refreshToolBar();
	}
	private void addResult(string path, ref size_t count, string desc = "") { mixin(S_TRACE);
		if (cancel) return;
		count++;
		auto addResultPath = new AddResultPath;
		addResultPath.path = path;
		addResultPath.desc = desc;
		addResultPath.count = count;
		_display.syncExec(addResultPath);
	}
	private void refContentText() { mixin(S_TRACE);
		foreach (itm; _result.getItems()) { mixin(S_TRACE);
			auto c = cast(CWXPathString) itm.getData();
			if (c) { mixin(S_TRACE);
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
	private void getPathParams(CWXPath path, out string text, out string text2, out Image img, out Image img2, bool par = false) { mixin(S_TRACE);
		if (!path) return;
		auto summ = _grepSumm ? _grepSumm : _summ;
		getSymbols(_comm, summ, path, text, text2, img, img2, par);
	}
	private void addResult(CWXPath path, ref size_t count, string desc = "", int index = -1) { mixin(S_TRACE);
		if (cancel) return;
		count++;
		auto addResultCWXPath = new AddResultCWXPath;
		addResultCWXPath.path = path;
		addResultCWXPath.index = index;
		addResultCWXPath.desc = desc;
		addResultCWXPath.count = count;
		_display.syncExec(addResultCWXPath);
	}
	private void addResult(string name, Image delegate() image, ref size_t count, int index = -1) { mixin(S_TRACE);
		if (cancel) return;
		count++;
		auto addResultMsg = new AddResultMsg;
		addResultMsg.name = name;
		addResultMsg.image = image;
		addResultMsg.index = index;
		addResultMsg.count = count;
		_display.syncExec(addResultMsg);
	}
	private void addResult(string name, uint use, Image delegate() image, ref size_t count, int index = -1) { mixin(S_TRACE);
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
	private bool repl(CWXPath path, string text, void delegate(string) set, ref size_t count, ref Undo[] uArr, bool storeToArr = false) { mixin(S_TRACE);
		auto c = fTextCount(text);
		count += c;
		if (c > 0) { mixin(S_TRACE);
			string n;
			if (_replMode && set) { mixin(S_TRACE);
				n = fTextRepl(text);
				if (!path || storeToArr) uArr ~= new StrUndo(text, n, set);
				set(n);
			}
			if (path) { mixin(S_TRACE);
				if (_replMode && set && !storeToArr) store(path, text, n, set);
				size_t dmy = 0;
				addResult(path, dmy);
			}
			return true;
		}
		return false;
	}
	private bool replFilePath(string text, void delegate(string) set, ref size_t count, ref Undo[] uArr) { mixin(S_TRACE);
		auto c = fTextCount(encodePath(text));
		count += c;
		if (c > 0) { mixin(S_TRACE);
			if (_replMode) { mixin(S_TRACE);
				auto o = decodePath(text);
				string n = fTextRepl(o);
				uArr ~= new StrUndo(o, n, set);
				set(n);
			}
			return true;
		}
		return false;
	}

	private bool replFlagName(F)(FlagDir parent, F flag, ref size_t count, ref Undo[] uArr) { mixin(S_TRACE);
		string text = flag.name;
		auto c = fTextCount(text);
		count += c;
		if (c > 0) { mixin(S_TRACE);
			if (_replMode) { mixin(S_TRACE);
				string oldPath = flag.path;
				string n = fTextRepl(text);
				uArr ~= new StrUndo(text, n, (string name) { mixin(S_TRACE);
					auto parent = flag.parent;
					if (parent) { mixin(S_TRACE);
						flag.name = parent.validName(name);
					} else { mixin(S_TRACE);
						flag.name = name;
					}
				});
				flag.name = parent.validName(n);
				_after ~= { mixin(S_TRACE);
					string newPath = flag.path;
					auto oldID = F.toID(oldPath);
					auto newID = F.toID(newPath);
					foreach (v; _summ.useCounter.values(oldID)) { mixin(S_TRACE);
						v.id = newID;
						storeID(null, v, oldID, newID, &v.id);
					}
				};
			}
			return true;
		}
		return false;
	}

	private bool replRqCoupons(C)(CWXPath path, C targ, ref size_t count, ref Undo[] uArr, bool storeToArr = false) { mixin(S_TRACE);
		string[] coupons = targ.rCoupons;
		string[] old = coupons.dup;
		bool r = false;
		foreach (i, cp; coupons) { mixin(S_TRACE);
			Undo[] nArr;
			r |= repl(null, cp, (string t) {cp = t;}, count, nArr);
			if (_replMode) coupons[i] = cp;
		}
		if (r) { mixin(S_TRACE);
			if (_replMode) { mixin(S_TRACE);
				if (!path || storeToArr) uArr ~= new StrArrUndo(old, coupons.dup, &targ.rCoupons);
				targ.rCoupons = coupons;
			}
			if (path) { mixin(S_TRACE);
				if (_replMode && !storeToArr) store(path, old, coupons.dup, &targ.rCoupons);
				size_t dmy = 0;
				addResult(targ, dmy);
			}
			return true;
		}
		return false;
	}

	private bool replKeyCode(C)(CWXPath path, C targ, ref size_t count, ref Undo[] uArr) { mixin(S_TRACE);
		if (_keyCodeSel) { mixin(S_TRACE);
			auto kcs = targ.keyCodes.dup;
			auto old = targ.keyCodes.dup;
			bool r = false;
			Undo[] nArr;
			foreach (i, kc; kcs) { mixin(S_TRACE);
				r |= repl(null, kc, (string t) {kc = t;}, count, nArr);
				if (_replMode) kcs[i] = kc;
			}
			if (r) { mixin(S_TRACE);
				if (_replMode) { mixin(S_TRACE);
					if (!path) uArr ~= new StrArrUndo(old, kcs.dup, &targ.keyCodes);
					targ.keyCodes = kcs;
				}
				if (path) { mixin(S_TRACE);
					if (_replMode) store(path, old, kcs.dup, &targ.keyCodes);
					size_t dmy = 0;
					addResult(path, dmy);
				}
				return true;
			}
		}
		return false;
	}
	private bool replFKeyCode(C)(CWXPath path, C targ, ref size_t count, ref Undo[] uArr) { mixin(S_TRACE);
		if (_keyCodeSel) { mixin(S_TRACE);
			auto kcs = targ.keyCodes.dup;
			auto old = targ.keyCodes.dup;
			bool r = false;
			Undo[] nArr;
			foreach (i, fkc; kcs) { mixin(S_TRACE);
				auto kc = _prop.sys.convFireKeyCode(fkc);
				r |= repl(null, kc, (string t) {kc = t;}, count, nArr);
				if (_replMode) kcs[i] = _prop.sys.toFKeyCode(kc);
			}
			if (r) { mixin(S_TRACE);
				if (_replMode) { mixin(S_TRACE);
					if (!path) uArr ~= new FKeyCodesUndo(old, kcs.dup, (FKeyCode[] fkc) {targ.keyCodes = fkc;});
					targ.keyCodes = kcs;
				}
				if (path) { mixin(S_TRACE);
					if (_replMode) store(path, old, kcs.dup, (FKeyCode[] fkc) {targ.keyCodes = fkc;});
					size_t dmy = 0;
					addResult(path, dmy);
				}
				return true;
			}
		}
		return false;
	}
	private bool replCoupons(C)(CWXPath path, C targ, ref size_t count, ref Undo[] uArr) { mixin(S_TRACE);
		if (_couponSel) { mixin(S_TRACE);
			auto coupons = targ.coupons.dup;
			auto old = targ.coupons.dup;
			bool r = false;
			Undo[] nArr;
			foreach (i, coupon; coupons) { mixin(S_TRACE);
				r |= repl(null, coupon.name, (string t) {coupon = new Coupon(t, coupon.value);}, count, nArr);
				if (_replMode) coupons[i] = coupon;
			}
			if (r) { mixin(S_TRACE);
				if (_replMode) { mixin(S_TRACE);
					if (!path) uArr ~= new CouponsUndo(old, coupons.dup, &targ.coupons);
					targ.coupons = coupons;
				}
				if (path) { mixin(S_TRACE);
					if (_replMode) store(path, old, coupons.dup, &targ.coupons);
					size_t dmy = 0;
					addResult(path, dmy);
				}
				return true;
			}
		}
		return false;
	}

	private bool replBgImage(CWXPath path, BgImage back, ref size_t count, ref Undo[] uArr) { mixin(S_TRACE);
		bool r = false;
		Undo[] uArr2;
		if (_flagSel) { mixin(S_TRACE);
			if (_flagDirOnRange) { mixin(S_TRACE);
				r |= repl(null, back.flag, null, count, uArr2);
			} else { mixin(S_TRACE);
				r |= repl(null, back.flag, &back.flag, count, uArr2);
			}
		}
		auto ic = cast(ImageCell) back;
		if (ic && _fileSel) { mixin(S_TRACE);
			r |= replFilePath(ic.path, &ic.path, count, uArr2);
		}
		auto tc = cast(TextCell) back;
		if (tc) { mixin(S_TRACE);
			if (_jptxSel) { mixin(S_TRACE);
				r |= repl(null, tc.text, &tc.text, count, uArr2, true);
			}
			r |= replFlagsInText(tc, count, uArr2);
		}
		if (r && path) { mixin(S_TRACE);
			if (_replMode) store(path, uArr2);
			size_t dmy = 0;
			addResult(path, dmy);
		} else { mixin(S_TRACE);
			uArr ~= uArr2;
		}
		return r;
	}
	private bool replCard(C)(CWXPath path, C card, ref size_t count, ref Undo[] uArr) { mixin(S_TRACE);
		bool r = false;
		static if (is(typeof(card.linkId))) {
			if (card.linkId != 0) return r;
		}
		Undo[] uArr2;
		if (_cardNameSel) { mixin(S_TRACE);
			r |= repl(null, card.name, &card.name, count, uArr2);
		}
		if (_cardDescSel) { mixin(S_TRACE);
			r |= repl(null, card.desc, &card.desc, count, uArr2);
		}
		static if (is(C:EffectCard)) {
			if (_scenarioSel) { mixin(S_TRACE);
				r |= repl(null, card.scenario, &card.scenario, count, uArr2);
			}
			if (_authorSel) { mixin(S_TRACE);
				r |= repl(null, card.author, &card.author, count, uArr2);
			}
		}
		if (_flagSel) { mixin(S_TRACE);
			static if (is (C : IFlagUser)) {
				if (_flagDirOnRange) { mixin(S_TRACE);
					r |= repl(null, card.flag, null, count, uArr2);
				} else { mixin(S_TRACE);
					r |= repl(null, card.flag, &card.flag, count, uArr2);
				}
			}
		}
		if (_fileSel) { mixin(S_TRACE);
			r |= replFilePath(card.path, &card.path, count, uArr2);
		}
		static if (is (C : EffectCard)) {
			r |= replKeyCode!(C)(null, card, count, uArr2);
		}
		if (r && path) { mixin(S_TRACE);
			if (_replMode) store(path, uArr2);
			size_t dmy = 0;
			addResult(path, dmy);
		} else { mixin(S_TRACE);
			uArr ~= uArr2;
		}
		return r;
	}
	bool replFontsInText(ITextHolder th, ref size_t count, ref Undo[] uArr) { mixin(S_TRACE);
		Undo[] nArr;
		bool r = false;
		string old = th.text;
		if (_fileSel) { mixin(S_TRACE);
			auto ps = th.fontsInText;
			foreach (i, p; ps) { mixin(S_TRACE);
				auto c = decodeFontPath(p);
				string ext = .extension(p);
				r |= repl(null, .to!string(c), (string s) { mixin(S_TRACE);
					dstring ds = .to!dstring(s);
					if (!ds.length) return;
					th.changeInText(i, toPathId(encodeFontPath(ds[0], ext)));
				}, count, nArr);
			}
			uArr ~= new StrUndo(old, th.text, &th.text);
		}
		return r;
	}
	bool replFlagsInText(ISimpleTextHolder th, ref size_t count, ref Undo[] uArr) { mixin(S_TRACE);
		Undo[] nArr;
		bool r = false;
		if (_flagSel && !_msgSel) { mixin(S_TRACE);
			if (_flagDirOnRange) { mixin(S_TRACE);
				// Flag/StepについてはUseCounter経由で置換される
				auto fps = th.flagsInText;
				foreach (i, p; fps) { mixin(S_TRACE);
					r |= repl(null, p, null, count, nArr);
				}
				auto sps = th.stepsInText;
				foreach (i, p; sps) { mixin(S_TRACE);
					r |= repl(null, p, null, count, nArr);
				}
			} else { mixin(S_TRACE);
				auto fps = th.flagsInText;
				foreach (i, p; fps) { mixin(S_TRACE);
					r |= repl(null, p, (string n) {th.changeInText(i, toFlagId(p));}, count, nArr);
				}
				auto sps = th.stepsInText;
				foreach (i, p; sps) { mixin(S_TRACE);
					r |= repl(null, p, (string n) {th.changeInText(i, toStepId(p));}, count, nArr);
				}
			}
		}
		return r;
	}
	void replContent(Content e, ref size_t count) { mixin(S_TRACE);
		auto eo = e.parent;
		auto d = e.detail;
		assert (!eo || eo.detail.owner);
		bool r = false;
		Undo[] uArr2;
		if (_eventSel && eo && eo.detail.nextType == CNextType.TEXT) { mixin(S_TRACE);
			r |= repl(null, e.name, &e.name, count, uArr2);
		}
		if (_flagSel) { mixin(S_TRACE);
			if (_flagDirOnRange) { mixin(S_TRACE);
				// Flag/StepについてはUseCounter経由で置換される
				if (d.use(CArg.FLAG)) r |= repl(null, e.flag, null, count, uArr2);
				if (d.use(CArg.STEP)) r |= repl(null, e.step, null, count, uArr2);
				if (d.use(CArg.FLAG_2)) r |= repl(null, e.flag2, null, count, uArr2);
				if (d.use(CArg.STEP_2)) r |= repl(null, e.step2, null, count, uArr2);
			} else { mixin(S_TRACE);
				if (d.use(CArg.FLAG)) r |= repl(null, e.flag, &e.flag, count, uArr2);
				if (d.use(CArg.STEP)) r |= repl(null, e.step, &e.step, count, uArr2);
				if (d.use(CArg.FLAG_2)) r |= repl(null, e.flag2, &e.flag, count, uArr2);
				if (d.use(CArg.STEP_2)) r |= repl(null, e.step2, &e.step, count, uArr2);
			}
		}
		if (_startSel) { mixin(S_TRACE);
			if (d.use(CArg.START)) r |= repl(null, e.start, &e.start, count, uArr2);
			if (e.type == CType.START) { mixin(S_TRACE);
				r |= repl(null, e.name, &e.name, count, uArr2);
			}
		}
		if (_couponSel) { mixin(S_TRACE);
			if (d.use(CArg.COUPON)) r |= repl(null, e.coupon, &e.coupon, count, uArr2);
			if (d.use(CArg.COUPONS)) r |= replCoupons(null, e, count, uArr2);
		}
		if (_gossipSel) { mixin(S_TRACE);
			if (d.use(CArg.GOSSIP)) r |= repl(null, e.gossip, &e.gossip, count, uArr2);
		}
		if (_endSel) { mixin(S_TRACE);
			if (d.use(CArg.COMPLETE_STAMP)) r |= repl(null, e.completeStamp, &e.completeStamp, count, uArr2);
		}
		if (_msgSel) { mixin(S_TRACE);
			if (d.use(CArg.TEXT)) r |= repl(null, e.text, &e.text, count, uArr2);
		}
		if (d.use(CArg.TEXT)) r |= replFontsInText(e, count, uArr2);
		if (d.use(CArg.TEXT)) r |= replFlagsInText(e, count, uArr2);
		bool rDlg = false;
		if (_msgSel || _couponSel || _fileSel || _flagSel) { mixin(S_TRACE);
			auto dlgs = e.dialogs;
			foreach (dlg; dlgs) { mixin(S_TRACE);
				Undo[] uArrDlg;
				auto put = dlg;
				if (_msgSel && repl(dlg, dlg.text, &dlg.text, count, uArrDlg, true)) { mixin(S_TRACE);
					rDlg = true;
					put = null;
				}
				if (_couponSel && replRqCoupons!(typeof(dlg))(put, dlg, count, uArrDlg, true)) { mixin(S_TRACE);
					rDlg = true;
					put = null;
				}
				bool dr = replFontsInText(dlg, count, uArrDlg);
				dr |= replFlagsInText(dlg, count, uArrDlg);
				if (dr) { mixin(S_TRACE);
					size_t dmy = 0;
					if (put) addResult(put, dmy);
					rDlg = true;
					put = null;
				}
				if (_replMode && !put) { mixin(S_TRACE);
					store(dlg, uArrDlg);
				}
			}
		}
		if (_fileSel) { mixin(S_TRACE);
			if (d.use(CArg.TALKER_C)) r |= replFilePath(e.cardPath, &e.cardPath, count, uArr2);
			if (d.use(CArg.BGM_PATH)) r |= replFilePath(e.bgmPath, &e.bgmPath, count, uArr2);
			if (d.use(CArg.SOUND_PATH)) r |= replFilePath(e.soundPath, &e.soundPath, count, uArr2);
		}
		if (_commentSel) { mixin(S_TRACE);
			r |= repl(null, e.comment, &e.comment, count, uArr2);
		}
		if (r) { mixin(S_TRACE);
			if (_replMode) { mixin(S_TRACE);
				store(e, uArr2);
			}
			size_t dmy = 0;
			addResult(e, dmy);
		}
	}
}
