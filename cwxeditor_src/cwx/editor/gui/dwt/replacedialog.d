
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

import cwx.editor.gui.dwt.dprops;
import cwx.editor.gui.dwt.dutils;
import cwx.editor.gui.dwt.centerlayout;
import cwx.editor.gui.dwt.customtable;
import cwx.editor.gui.dwt.commons;
import cwx.editor.gui.dwt.dskin;
import cwx.editor.gui.dwt.splitpane;

import std.conv;
import std.array;
import std.string;
import std.file;
import std.path;
import std.regex;
import std.utf;

import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Text;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Group;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.MessageBox;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.TreeItem;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Spinner;
import org.eclipse.swt.custom.CTabFolder;
import org.eclipse.swt.custom.CTabItem;
import org.eclipse.swt.events.ShellAdapter;
import org.eclipse.swt.events.ShellEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.KeyAdapter;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.RowLayout;
import org.eclipse.swt.layout.RowData;
import org.eclipse.swt.graphics.Image;
import java.lang.all;

private class CWXPathString {
	string array;
	this (string array) {
		this.array = array;
	}
}

/// 検索と置換を行うダイアログ。
class ReplaceDialog {
private:
	Commons _comm;
	Props _prop;
	Summary _summ;

	Shell _win;
	Composite _parent;
	CTabFolder _tabf;
	CTabItem _tabText;
	CTabItem _tabID;
	CTabItem _tabPath;
	CTabItem _tabUnuse;
	CTabItem _tabError;
	Button _replace;
	Button _rangeAllCheck;

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
			if (_useRegex.getSelection) {
				_useWildcard.setSelection = false;
			}
		}
	}
	class SelWildcard : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			if (_useWildcard.getSelection) {
				_useRegex.setSelection = false;
			}
		}
	}

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

	Table _result;
	Tree _range;

	Composite[CTabItem] _comps;

	Label _status;

	bool summary() {return _summary.getSelection;}
	bool msg() {return _msg.getSelection;}
	bool cardName() {return _cardName.getSelection;}
	bool cardDesc() {return _cardDesc.getSelection;}
	bool event() {return _event.getSelection;}
	bool start() {return _start.getSelection;}
	bool flag() {return _flag.getSelection;}
	bool coupon() {return _coupon.getSelection;}
	bool gossip() {return _gossip.getSelection;}
	bool end() {return _end.getSelection;}
	bool area() {return _area.getSelection;}
	bool keyCode() {return _keyCode.getSelection;}
	bool file() {return _file.getSelection;}
	bool comment() {return _comment.getSelection;}

	bool unuseFlag() {return _unuseFlag.getSelection;}
	bool unuseStep() {return _unuseStep.getSelection;}
	bool unuseArea() {return _unuseArea.getSelection;}
	bool unuseBattle() {return _unuseBattle.getSelection;}
	bool unusePackage() {return _unusePackage.getSelection;}
	bool unuseCast() {return _unuseCast.getSelection;}
	bool unuseSkill() {return _unuseSkill.getSelection;}
	bool unuseItem() {return _unuseItem.getSelection;}
	bool unuseBeast() {return _unuseBeast.getSelection;}
	bool unuseInfo() {return _unuseInfo.getSelection;}
	bool unuseStart() {return _unuseStart.getSelection;}
	bool unusePath() {return _unusePath.getSelection;}

	class ML : MouseAdapter {
		public override void mouseDoubleClick(MouseEvent e) {
			if (_result.isFocusControl && e.button == 1) {
				openPath;
			}
		}
	}
	class KL : KeyAdapter {
		public override void keyPressed(KeyEvent e) {
			if (_result.isFocusControl && e.character == SWT.CR) {
				openPath;
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
		string oldSel = combo.getText;
		combo.removeAll;
		combo.add(_prop.msgs.replSetID);
		foreach (i, a; arr) {
			combo.add(to!(string)(a.id) ~ "." ~ a.name);
			tbl2[i + 1] = a.id;
		}
		combo.select = arr.length ? 1 : 0;
		if (oldSel) {
			auto i = combo.indexOf(oldSel);
			if (i >= 0) combo.select = i;
		}
		spn.setEnabled = combo.getSelectionIndex == 0;
		tbl = tbl2;
	}
	private void setupIDsImpl1(T)(T[] arr) {
		setupIDsImpl2(arr, _fromID, _fromIDVal, _fromIDTbl);
		setupIDsImpl2(arr, _toID, _toIDVal, _toIDTbl);
	}
	private void setupIDs() {
		switch (_idKind.getSelectionIndex) {
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
				auto path = abs2rel(sPath, p);
				paths ~= encodePath(path);
				tbl.add(toPathId(path));
			}
		}
		find(sPath);
		if (!scenarioOnly) {
			auto skin = _comm.skin;
			foreach (p; skin.tables) {
				tbl.add(toPathId(p));
				paths ~= encodePath(p);
			}
			foreach (p; skin.musics) {
				tbl.add(toPathId(p));
				paths ~= encodePath(p);
			}
			foreach (p; skin.sounds) {
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
		string[] paths = [""] ~ allMaterials(false);
		void setPaths(Combo combo) {
			auto old = combo.getText;
			combo.setItems(paths);
			combo.setText = old;
		}
		setPaths(_fromPath);
		setPaths(_toPath);
	}
	class SListener : ShellAdapter {
		override void shellActivated(ShellEvent e) {
			setupIDs;
			setupPaths;
		}
	}
	class SelID : SelectionAdapter {
		private Spinner _spn;
		this (Spinner spn) {_spn = spn;}
		override void widgetSelected(SelectionEvent e) {
			auto combo = cast(Combo) e.widget;
			_spn.setEnabled = combo.getSelectionIndex == 0;
		}
	}
	class SelIDKind : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			setupIDs;
		}
	}
	private void tabChanged() {
		auto sel = _tabf.getSelection;
		if (!sel) return;
		foreach (tab, comp; _comps) {
			auto gd = cast(GridData) comp.getLayoutData;
			if (tab is sel) {
				gd.heightHint= SWT.DEFAULT;
			} else {
				gd.heightHint= 0;
			}
		}
		_parent.layout(true);
		_replace.setEnabled = sel !is _tabUnuse && sel !is _tabError;
		_range.setEnabled = sel !is _tabUnuse;
		_rangeAllCheck.setEnabled = _range.getEnabled;
	}
	class TSListener : SelectionAdapter {
		override void widgetSelected(SelectionEvent e) {
			tabChanged;
		}
	}
	LCheck[] _checked;
	class LCheck : SelectionAdapter {
		Button[] buttons;
		private Button _all = null;
		class AllCheck : SelectionAdapter {
			override void widgetSelected(SelectionEvent e) {
				foreach (b; buttons) {
					b.setSelection = _all.getSelection;
				}
			}
		}
		void check() {
			bool checked = true;
			foreach (b; buttons) {
				checked &= b.getSelection;
			}
			_all.setSelection = checked;
		}
		override void widgetSelected(SelectionEvent e) {
			assert (_all);
			check;
		}
		void createAlls(Composite parent) {
			_all = new Button(parent, SWT.CHECK);
			_all.setText = _prop.msgs.allCheck;
			_all.addSelectionListener(new AllCheck);
			check;
		}
	}
	Composite addButtonLine(Composite grp) {
		auto comp = new Composite(grp, SWT.NONE);
		comp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		auto rl = new RowLayout(SWT.HORIZONTAL);
		rl.wrap = true;
		rl.pack = false;
		comp.setLayout = rl;
		return comp;
	}
	void constructText(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout = new GridLayout(1, true);
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout = zeroGridLayout(1, true);
		{
			auto grp = new Group(comp2, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setText = _prop.msgs.replText;
			grp.setLayout = new GridLayout(2, false);
			auto lf = new Label(grp, SWT.NONE);
			lf.setText = _prop.msgs.replFrom;
			_from = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN);
			_from.setVisibleItemCount = 20;
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.nameWidth;
			_from.setLayoutData = gd;
			auto lt = new Label(grp, SWT.NONE);
			lt.setText = _prop.msgs.replTo;
			_to = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN);
			_to.setVisibleItemCount = 20;
			_to.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		{
			auto grp = new Group(comp2, SWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			grp.setLayoutData = gd;
			grp.setText = _prop.msgs.replCond;
			grp.setLayout = new GridLayout(1, true);
			_notIgnoreCase = new Button(grp, SWT.CHECK);
			_notIgnoreCase.setText = _prop.msgs.replNotIgnoreCase;
			_useWildcard = new Button(grp, SWT.CHECK);
			_useWildcard.setText = _prop.msgs.replWildcard;
			_useWildcard.addSelectionListener(new SelWildcard);
			_useRegex = new Button(grp, SWT.CHECK);
			_useRegex.setText = _prop.msgs.replRegExp;
			_useRegex.addSelectionListener(new SelRegex);
		}
		{
			auto grp = new Group(comp2, SWT.NONE);
			auto gd = new GridData(GridData.FILL_HORIZONTAL);
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			grp.setLayoutData = gd;
			grp.setText = _prop.msgs.replTextTarget;
			grp.setLayout = zeroGridLayout(1, true);
			auto checked = new LCheck;
			_checked ~= checked;
			{
				auto btns = addButtonLine(grp);
				Button createB(string text) {
					auto b = new Button(btns, SWT.CHECK);
					b.setText = text;
					checked.buttons ~= b;
					b.addSelectionListener(checked);
					return b;
				}
				_summary = createB(_prop.msgs.replTextSummary);
				_msg = createB(_prop.msgs.replTextMessage);
				_cardName = createB(_prop.msgs.replTextCardName);
				_cardDesc = createB(_prop.msgs.replTextCardDesc);
				_event = createB(_prop.msgs.replTextEventText);
				_start = createB(_prop.msgs.replTextStart);
				_flag = createB(_prop.msgs.replTextFlagAndStep);
				_coupon = createB(_prop.msgs.replTextCoupon);
				_gossip = createB(_prop.msgs.replTextGossip);
				_end = createB(_prop.msgs.replTextEndScenario);
				_area = createB(_prop.msgs.replTextAreaName);
				_keyCode = createB(_prop.msgs.replTextKeyCode);
				_file = createB(_prop.msgs.replTextFile);
				_comment = createB(_prop.msgs.replTextComment);
			}
			auto sep = new Label(grp, SWT.SEPARATOR | SWT.HORIZONTAL);
			sep.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			{
				auto btns = addButtonLine(grp);
				checked.createAlls(btns);
			}
		}

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText = _prop.msgs.replForText;
		tab.setControl = comp;
		_tabText = tab;

		auto gd = new GridData(GridData.FILL_BOTH);
		comp2.setLayoutData = gd;
		_comps[tab] = comp2;
	}
	void constructID(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout = new GridLayout(1, true);
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout = zeroGridLayout(1, true);
		{
			auto grp = new Group(comp2, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setText = _prop.msgs.replID;
			grp.setLayout = new GridLayout(3, false);
			{
				auto l = new Label(grp, SWT.NONE);
				l.setText = _prop.msgs.replIDKind;
				_idKind = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				_idKind.setVisibleItemCount = 20;
				_idKind.add(_prop.msgs.replIDArea);
				_idKind.add(_prop.msgs.replIDBattle);
				_idKind.add(_prop.msgs.replIDPackage);
				_idKind.add(_prop.msgs.replIDCast);
				_idKind.add(_prop.msgs.replIDSkill);
				_idKind.add(_prop.msgs.replIDItem);
				_idKind.add(_prop.msgs.replIDBeast);
				_idKind.add(_prop.msgs.replIDInfo);
				_idKind.select = 0;
				auto gd = new GridData;
				gd.horizontalSpan = 2;
				_idKind.setLayoutData = gd;
				_idKind.addSelectionListener(new SelIDKind);
			}
			{
				auto sep = new Label(grp, SWT.SEPARATOR | SWT.HORIZONTAL);
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.horizontalSpan = 3;
				sep.setLayoutData = gd;
			}
			void setupID(string text, ref Combo combo, ref Spinner spn) {
				auto l = new Label(grp, SWT.NONE);
				l.setText = text;
				combo = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN | SWT.READ_ONLY);
				combo.setVisibleItemCount = 20;
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = _prop.var.etc.nameWidth;
				combo.setLayoutData = gd;
				spn = new Spinner(grp, SWT.BORDER);
				spn.setMinimum = 1;
				spn.setMaximum = _prop.looks.idMax;
				combo.addSelectionListener(new SelID(spn));
			}
			setupID(_prop.msgs.replFrom, _fromID, _fromIDVal);
			setupID(_prop.msgs.replTo, _toID, _toIDVal);
		}

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText = _prop.msgs.replForID;
		tab.setControl = comp;
		_tabID = tab;

		auto gd = new GridData(GridData.FILL_BOTH);
		gd.heightHint = 0;
		comp2.setLayoutData = gd;
		_comps[tab] = comp2;
	}
	void constructPath(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout = new GridLayout(1, true);
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout = zeroGridLayout(1, true);
		{
			auto grp = new Group(comp2, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setText = _prop.msgs.replPath;
			grp.setLayout = new GridLayout(2, false);
			Combo setupPath(string text) {
				auto l = new Label(grp, SWT.NONE);
				l.setText = text;
				auto combo = new Combo(grp, SWT.BORDER | SWT.DROP_DOWN);
				combo.setVisibleItemCount = 20;
				auto gd = new GridData(GridData.FILL_HORIZONTAL);
				gd.widthHint = _prop.var.etc.nameWidth;
				combo.setLayoutData = gd;
				return combo;
			}
			_fromPath = setupPath(_prop.msgs.replFrom);
			_toPath = setupPath(_prop.msgs.replTo);
		}

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText = _prop.msgs.replForPath;
		tab.setControl = comp;
		_tabPath = tab;

		auto gd = new GridData(GridData.FILL_BOTH);
		gd.heightHint = 0;
		comp2.setLayoutData = gd;
		_comps[tab] = comp2;
	}
	void constructUnuse(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout = new GridLayout(1, true);
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout = zeroGridLayout(1, true);
		{
			auto grp = new Group(comp2, SWT.NONE);
			grp.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			grp.setText = _prop.msgs.replUnuseTarget;
			grp.setLayout = zeroGridLayout(1, true);
			auto checked = new LCheck;
			_checked ~= checked;
			{
				auto btns = addButtonLine(grp);
				Button createB(string text) {
					auto b = new Button(btns, SWT.CHECK);
					b.setText = text;
					checked.buttons ~= b;
					b.addSelectionListener(checked);
					return b;
				}
				_unuseFlag = createB(_prop.msgs.replUnuseFlag);
				_unuseStep = createB(_prop.msgs.replUnuseStep);
				_unuseArea = createB(_prop.msgs.replUnuseArea);
				_unuseBattle = createB(_prop.msgs.replUnuseBattle);
				_unusePackage = createB(_prop.msgs.replUnusePackage);
				_unuseCast = createB(_prop.msgs.replUnuseCast);
				_unuseSkill = createB(_prop.msgs.replUnuseSkill);
				_unuseItem = createB(_prop.msgs.replUnuseItem);
				_unuseBeast = createB(_prop.msgs.replUnuseBeast);
				_unuseInfo = createB(_prop.msgs.replUnuseInfo);
				_unuseStart = createB(_prop.msgs.replUnuseStart);
				_unusePath = createB(_prop.msgs.replUnusePath);
			}
			auto sep = new Label(grp, SWT.SEPARATOR | SWT.HORIZONTAL);
			sep.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			{
				auto btns = addButtonLine(grp);
				checked.createAlls(btns);
			}
		}

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText = _prop.msgs.replForUnuse;
		tab.setControl = comp;
		_tabUnuse = tab;

		auto gd = new GridData(GridData.FILL_BOTH);
		gd.heightHint = 0;
		comp2.setLayoutData = gd;
		_comps[tab] = comp2;
	}
	void constructError(CTabFolder tabf) {
		auto comp = new Composite(tabf, SWT.NONE);
		comp.setLayout = new GridLayout(1, true);
		auto comp2 = new Composite(comp, SWT.NONE);
		comp2.setLayout = zeroGridLayout(1, true);
		{
			auto l = new Label(comp2, SWT.WRAP);
			l.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			l.setText = _prop.msgs.replError;
		}

		auto tab = new CTabItem(tabf, SWT.NONE);
		tab.setText = _prop.msgs.replForError;
		tab.setControl = comp;
		_tabError = tab;

		auto gd = new GridData(GridData.FILL_BOTH);
		gd.heightHint = 0;
		comp2.setLayoutData = gd;
		_comps[tab] = comp2;
	}

	void refFunc(bool Del, A : CWXPath)(A a) {
		bool recurse(TreeItem itm) {
			if (a is itm.getData) {
				static if (Del) {
					itm.dispose();
				} else {
					itm.setText = a.name;
				}
				return true;
			} else {
				foreach (child; itm.getItems) {
					if (recurse(child)) {
						return true;
					}
				}
				return false;
			}
		}
		foreach (child; _range.getItems) {
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
		auto selItm = _range.getSelection;
		if (selItm.length) {
			sel = cast(CWXPath) selItm[0].getData;
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
			itm.setText = name;
			itm.setImage = img;
			itm.setData = cast(Object) path;
			itm.setChecked = true;
			if (sel is path) {
				_range.setSelection = [itm];
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
				add(par, c.name, c);
			}
			foreach (c; a.items) {
				add(par, c.name, c);
			}
			foreach (c; a.beasts) {
				add(par, c.name, c);
			}
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
		_range.showSelection;
	}
	void refreshRangeAllCheck() {
		bool recurse(TreeItem itm) {
			if (!itm.getChecked) {
				return true;
			} else {
				foreach (child; itm.getItems) {
					if (recurse(child)) {
						return true;
					}
				}
				return false;
			}
		}
		foreach (child; _range.getItems) {
			if (recurse(child)) {
				_rangeAllCheck.setSelection = false;
				return;
			}
		}
		_rangeAllCheck.setSelection = true;
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
				itm.setChecked = _rangeAllCheck.getSelection;
				foreach (child; itm.getItems) {
					recurse(child);
				}
			}
			foreach (child; _range.getItems) {
				recurse(child);
			}
		}
	}
public:
	this(Commons comm, Props prop, Shell shell, Summary summ) {
		_comm = comm;
		_prop = prop;
		_summ = summ;
		_win = new Shell(shell, SWT.SHELL_TRIM);
		if (shell) {
			_win.setImeInputMode = shell.getImeInputMode;
		}
		_win.setText = _prop.msgs.dlgTitReplaceText;
		_win.setImage = prop.images.menuReplaceText;
		setup;
		_win.open;
		_win.setActive;
	}
	Shell widget() {
		return _win;
	}
	void summary(Summary summ) {
		if (!_win.isDisposed) {
			_summ = summ;
			_result.removeAll;
		}
	}

	void replaceText(string from) {
		reset;
		_from.setText = from;
		_to.setText = "";
		_tabf.setSelection = _tabText;
		tabChanged;
		_from.setFocus;
	}
	void replacePath(string from) {
		reset;
		_fromPath.setText = from;
		_toPath.setText = "";
		_tabf.setSelection = _tabPath;
		tabChanged;
		_fromPath.setFocus;
	}

	private void setup() {
		_win.addShellListener(new SListener);
		_win.setLayout = zeroGridLayout(1, true);
		auto area = new Composite(_win, SWT.NONE);
		area.setLayoutData = new GridData(GridData.FILL_BOTH);
		area.setLayout = windowGridLayout(2, false);

		auto sash = new SplitPane(area, SWT.HORIZONTAL);
		sash.setLayoutData = new GridData(GridData.FILL_BOTH);

		auto left = new Composite(sash, SWT.NONE);
		left.setLayout = windowGridLayout(1, true);
		_parent = left;
		auto right = new Composite(sash, SWT.NONE);
		right.setLayout = windowGridLayout(1, true);

		_tabf = new CTabFolder(left, SWT.BORDER);
		{
			_tabf.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			constructText(_tabf);
			constructID(_tabf);
			constructPath(_tabf);
			constructUnuse(_tabf);
			constructError(_tabf);
			_tabf.addSelectionListener(new TSListener);
		}
		{
			_result = new Table(left, SWT.BORDER | SWT.SINGLE | SWT.FULL_SELECTION | SWT.V_SCROLL | SWT.VIRTUAL);
			auto gd = new GridData(GridData.FILL_BOTH);
			gd.widthHint = _prop.var.etc.searchResultTableWidth;
			gd.heightHint = _prop.var.etc.searchResultTableHeight;
			_result.setLayoutData = gd;
			_result.addMouseListener = new ML;
			_result.addKeyListener = new KL;
			new FullTableColumn(_result, SWT.NONE);
		}
		{
			auto grp = new Group(right, SWT.NONE);
			grp.setText = _prop.msgs.searchRange;
			grp.setLayoutData = new GridData(GridData.FILL_BOTH);
			grp.setLayout = new GridLayout(1, true);
			_range = new Tree(grp, SWT.SINGLE | SWT.BORDER | SWT.VIRTUAL | SWT.CHECK);
			_range.addSelectionListener(new RefRangeAllCheck);
			_range.setLayoutData = new GridData(GridData.FILL_BOTH);
			refreshRangeTree();
			_rangeAllCheck = new Button(grp, SWT.CHECK);
			_rangeAllCheck.setText = _prop.msgs.allCheckRange;
			refreshRangeAllCheck();
			_rangeAllCheck.addSelectionListener(new RangeAllCheck);
		}
		{
			auto sep = new Label(_win, SWT.SEPARATOR | SWT.HORIZONTAL);
			sep.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
		}
		{
			auto bArea = new Composite(_win, SWT.NONE);
			bArea.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			bArea.setLayout = new GridLayout(2, false);
			_status = new Label(bArea, SWT.NONE);
			_status.setText = _prop.msgs.searchResult(0, "");
			_status.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
			auto comp = new Composite(bArea, SWT.NONE);
			comp.setLayoutData = new GridData(GridData.HORIZONTAL_ALIGN_END);
			auto gl = new GridLayout(3, true);
			gl.marginWidth = 0;
			gl.marginHeight = 0;
			comp.setLayout = gl;
			Button createButton(string text, void delegate() push) {
				auto b = new Button(comp, SWT.PUSH);
				b.setLayoutData = new GridData(GridData.FILL_HORIZONTAL);
				b.setText = text;
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
			_win.setDefaultButton(createButton(_prop.msgs.search, &search));
			_replace = createButton(_prop.msgs.replace, &replace);
			createButton(_prop.msgs.replaceExit, &exit);
		}
		_from.setItems(_prop.var.etc.searchHistories.dup);
		_to.setItems(_prop.var.etc.replaceHistories.dup);
		_notIgnoreCase.setSelection = _prop.var.etc.replaceTextNotIgnoreCase;
		_useRegex.setSelection = _prop.var.etc.replaceTextRegExp;
		_useWildcard.setSelection = _prop.var.etc.replaceTextWildcard;
		_summary.setSelection = _prop.var.etc.replaceTextSummary;
		_msg.setSelection = _prop.var.etc.replaceTextMessage;
		_cardName.setSelection = _prop.var.etc.replaceTextCardName;
		_cardDesc.setSelection = _prop.var.etc.replaceTextCardDescription;
		_event.setSelection = _prop.var.etc.replaceTextEventText;
		_flag.setSelection = _prop.var.etc.replaceTextFlagAndStep;
		_start.setSelection = _prop.var.etc.replaceTextStart;
		_coupon.setSelection = _prop.var.etc.replaceTextCoupon;
		_gossip.setSelection = _prop.var.etc.replaceTextGossip;
		_end.setSelection = _prop.var.etc.replaceTextEndScenario;
		_area.setSelection = _prop.var.etc.replaceTextAreaName;
		_keyCode.setSelection = _prop.var.etc.replaceTextKeyCode;
		_file.setSelection = _prop.var.etc.replaceTextFile;
		_comment.setSelection = _prop.var.etc.replaceTextComment;
		_unuseFlag.setSelection = _prop.var.etc.searchUnusedFlag;
		_unuseStep.setSelection = _prop.var.etc.searchUnusedStep;
		_unuseArea.setSelection = _prop.var.etc.searchUnusedArea;
		_unuseBattle.setSelection = _prop.var.etc.searchUnusedBattle;
		_unusePackage.setSelection = _prop.var.etc.searchUnusedPackage;
		_unuseCast.setSelection = _prop.var.etc.searchUnusedCast;
		_unuseSkill.setSelection = _prop.var.etc.searchUnusedSkill;
		_unuseItem.setSelection = _prop.var.etc.searchUnusedItem;
		_unuseBeast.setSelection = _prop.var.etc.searchUnusedBeast;
		_unuseInfo.setSelection = _prop.var.etc.searchUnusedInfo;
		_unuseStart.setSelection = _prop.var.etc.searchUnusedStart;
		_unusePath.setSelection = _prop.var.etc.searchUnusedPath;
		foreach (l; _checked) {
			l.check;
		}

		sash.addDisposeListener(new SashDispose);
		sash.setWeights = [_prop.var.etc.replaceRangeSashL, _prop.var.etc.replaceRangeSashR];

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

		_comm.refScenario.add(&refreshScenario);
		_win.addDisposeListener(new DL);
		auto cs = _win.computeSize(SWT.DEFAULT, SWT.DEFAULT);
		auto size = _prop.var.replaceDlg;
		if (size.width != SWT.DEFAULT) cs.x = size.width;
		if (size.height != SWT.DEFAULT) cs.y = size.height;
		_win.setSize = cs;
	}
	private class SashDispose : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			auto sash = cast(SplitPane) e.widget;
			auto ws = sash.getWeights;
			_prop.var.etc.replaceRangeSashL = ws[0];
			_prop.var.etc.replaceRangeSashR = ws[1];
		}
	}
	private class DL : DisposeListener {
		override void widgetDisposed(DisposeEvent e) {
			_comm.refScenario.remove(&refreshScenario);
			if (!_win.getMaximized) {
				auto s = _win.getSize;
				_prop.var.replaceDlg.width = s.x;
				_prop.var.replaceDlg.height = s.y;
			}
			_prop.var.etc.replaceTextNotIgnoreCase = _notIgnoreCase.getSelection;
			_prop.var.etc.replaceTextRegExp = _useRegex.getSelection;
			_prop.var.etc.replaceTextWildcard = _useWildcard.getSelection;
			_prop.var.etc.replaceTextSummary = _summary.getSelection;
			_prop.var.etc.replaceTextMessage = _msg.getSelection;
			_prop.var.etc.replaceTextCardName = _cardName.getSelection;
			_prop.var.etc.replaceTextCardDescription = _cardDesc.getSelection;
			_prop.var.etc.replaceTextEventText = _event.getSelection;
			_prop.var.etc.replaceTextStart = _start.getSelection;
			_prop.var.etc.replaceTextFlagAndStep = _flag.getSelection;
			_prop.var.etc.replaceTextCoupon = _coupon.getSelection;
			_prop.var.etc.replaceTextGossip = _gossip.getSelection;
			_prop.var.etc.replaceTextEndScenario = _end.getSelection;
			_prop.var.etc.replaceTextAreaName = _area.getSelection;
			_prop.var.etc.replaceTextKeyCode = _keyCode.getSelection;
			_prop.var.etc.replaceTextFile = _file.getSelection;
			_prop.var.etc.replaceTextComment = _comment.getSelection;
			_prop.var.etc.searchUnusedFlag = _unuseFlag.getSelection;
			_prop.var.etc.searchUnusedStep = _unuseStep.getSelection;
			_prop.var.etc.searchUnusedArea = _unuseArea.getSelection;
			_prop.var.etc.searchUnusedBattle = _unuseBattle.getSelection;
			_prop.var.etc.searchUnusedPackage = _unusePackage.getSelection;
			_prop.var.etc.searchUnusedCast = _unuseCast.getSelection;
			_prop.var.etc.searchUnusedSkill = _unuseSkill.getSelection;
			_prop.var.etc.searchUnusedItem = _unuseItem.getSelection;
			_prop.var.etc.searchUnusedBeast = _unuseBeast.getSelection;
			_prop.var.etc.searchUnusedInfo = _unuseInfo.getSelection;
			_prop.var.etc.searchUnusedStart = _unuseStart.getSelection;
			_prop.var.etc.searchUnusedPath = _unusePath.getSelection;

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
		}
	}
	private void refreshScenario(Summary summ) {
		if (!summ) {
			_win.close();
		} else {
			_summ = summ;
		}
	}
	private void search() {
		_replMode = false;
		replaceImpl;
	}
	private void replace() {
		_replMode = true;
		replaceImpl;
	}
	private void reset() {
		_result.removeAll;
		if (_replMode) {
			_status.setText = _prop.msgs.replResult(0, "");
		} else {
			_status.setText = _prop.msgs.searchResult(0, "");
		}
	}
	private void replaceImpl() {
		if (_tabf.getSelection is _tabText) {
			replaceTextImpl;
		} else if (_tabf.getSelection is _tabID) {
			replaceIDImpl;
		} else if (_tabf.getSelection is _tabPath) {
			replacePathImpl;
		} else if (_tabf.getSelection is _tabUnuse) {
			searchUnuseImpl;
		} else if (_tabf.getSelection is _tabError) {
			searchErrorImpl;
		} else assert (0);
	}
	private void searchRange(ref uint count,
			void delegate(CWXPath path, ref uint count) dlg) {
		void recurse(TreeItem itm) {
			auto path = cast(CWXPath) itm.getData;
			searchAll(path, count, dlg);
			foreach (child; itm.getItems) {
				if (child.getChecked) {
					recurse(child);
				}
			}
		}
		foreach (itm; _range.getItems) {
			if (itm.getChecked) {
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
				if (m.beast) {
					searchAll(m.beast, count, dlg);
				}
			}
		}
	}

	private void setResultStatus(uint count) {
		if (count > 0) {
			if (_replMode) _summ.changed;
			_comm.refUseCount.call;
		}
		string kind = _tabf.getSelection.getText;
		if (_replMode) {
			_status.setText = _prop.msgs.replResult(count, kind);
		} else {
			_status.setText = _prop.msgs.searchResult(count, kind);
		}
	}
	private void replaceIDImpl2(ID)(ID from, ID to) {
		auto uc = _summ.useCounter;
		auto users = uc.values(from);
		if (_replMode) uc.change(from, to, true);
		_result.setRedraw = false;
		scope (exit) _result.setRedraw = true;
		foreach (user; users) {
			addResult(user.owner);
		}
		setResultStatus(users.length);
		if (users.length) _comm.replID.call;
	}
	private void replaceIDImpl() {
		ulong getID(Combo combo, Spinner spn, ulong[int] tbl) {
			if (combo.getSelectionIndex == 0) {
				return spn.getSelection;
			} else {
				return tbl[combo.getSelectionIndex];
			}
		}
		ulong from = getID(_fromID, _fromIDVal, _fromIDTbl);
		ulong to = getID(_toID, _toIDVal, _toIDTbl);
		if (from == to) _replMode = false;
		reset;
		switch (_idKind.getSelectionIndex) {
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
		if (!_fromPath.getText.length) return;
		auto from = toPathId(_fromPath.getText);
		auto to = toPathId(_toPath.getText);
		if (from == to) _replMode = false;
		auto uc = _summ.useCounter;
		auto users = uc.values(from);
		if (_replMode) uc.change(from, to, true);
		_result.setRedraw = false;
		scope (exit) _result.setRedraw = true;
		reset;
		foreach (user; users) {
			addResult(user.owner);
		}
		setResultStatus(users.length);
		if (users.length) _comm.replPath.call(cast(string) from, cast(string) to);
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
		_result.setRedraw = false;
		scope (exit) _result.setRedraw = true;
		reset;
		if (unuseFlag) {
			searchUnuseImpl2!("toFlagId(o.path)")(_summ.flagDirRoot.allFlags, count);
		}
		if (unuseStep) {
			searchUnuseImpl2!("toStepId(o.path)")(_summ.flagDirRoot.allSteps, count);
		}
		if (unuseArea) {
			searchUnuseImpl2!("toAreaId(o.id)")(_summ.areas, count);
		}
		if (unuseBattle) {
			searchUnuseImpl2!("toBattleId(o.id)")(_summ.battles, count);
		}
		if (unusePackage) {
			searchUnuseImpl2!("toPackageId(o.id)")(_summ.packages, count);
		}
		if (unuseCast) {
			searchUnuseImpl2!("toCastId(o.id)")(_summ.casts, count);
		}
		if (unuseSkill) {
			searchUnuseImpl2!("toSkillId(o.id)")(_summ.skills, count);
		}
		if (unuseItem) {
			searchUnuseImpl2!("toItemId(o.id)")(_summ.items, count);
		}
		if (unuseBeast) {
			searchUnuseImpl2!("toBeastId(o.id)")(_summ.beasts, count);
		}
		if (unuseInfo) {
			searchUnuseImpl2!("toInfoId(o.id)")(_summ.infos, count);
		}
		if (unuseStart) {
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
		if (unusePath) {
			searchUnuseImpl2!("toPathId(o)")(allMaterials(true), count);
		}
		setResultStatus(count);
	}
	private void searchErrorImpl() {
		uint count = 0;
		auto froot = _summ.flagDirRoot;
		auto sPath = _summ.scenarioPath;
		auto skin = _comm.skin;
		reset;
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
				if (!_summ.casts(ec.id)) {
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
			if (c.packages != 0 && !_summ.packages(c.packages)) {
				addResult(path, _prop.msgs.searchErrorPackageNotFound);
				count++;
				return;
			}
			if (c.casts != 0 && !_summ.casts(c.casts)) {
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
			}
		});
		_result.setRedraw = false;
		scope (exit) _result.setRedraw = true;
		setResultStatus(count);
	}
	private void replaceTextImpl(CWXPath c, ref size_t count) {
		auto summ = cast(Summary) c;
		if (summ) {
			bool sr = false;
			if (summary) {
				sr |= repl(null, summ.scenarioName, &summ.scenarioName, count);
				sr |= repl(null, summ.desc, &summ.desc, count);
			}
			if (coupon) {
				sr |= replRqCoupons!(Summary)(null, _summ, count);
			}
			if (sr) addResult(summ);
		}
		auto cc = cast(CastCard) c;
		if (cc) {
			bool r = replCard!(CastCard)(null, cc, count);
			if (coupon) {
				auto coupons = cc.coupons.dup;
				foreach (i, cp; coupons) {
					r |= repl(null, cp.name,
						(string t) {cp = new Coupon(t, cp.value);}, count);
					if (_replMode) coupons[i] = cp;
				}
				cc.coupons = coupons;
			}
			if (r) addResult(cc);
		}
		auto eff = cast(EffectCard) c;
		if (eff) {
			replCard(eff, eff, count);
		}
		auto info = cast(InfoCard) c;
		if (info) {
			replCard(info, info, count);
		}
		auto a = cast(AbstractArea) c;
		if (a) {
			if (area) {
				repl(a, a.name, &a.name, count);
			}
		}
		auto menu = cast(MenuCard) c;
		if (menu) {
			replCard(menu, menu, count);
		}
		auto back = cast(BgImage) c;
		if (back) {
			replBgImage(back, back, count);
		}
		auto f = cast(Flag) c;
		if (f) {
			string old = f.name;
			replFlagName(f.parent, f, count);
			_summ.useCounter.change(toFlagId(old), toFlagId(f.name));
			bool r = false;
			r |= repl(null, f.on, &f.on, count);
			r |= repl(null, f.off, &f.off, count);
			if (r) addResult(f);
		}
		auto s = cast(Step) c;
		if (s) {
			string old = s.name;
			replFlagName(s.parent, s, count);
			_summ.useCounter.change(toStepId(old), toStepId(s.name));
			bool r = false;
			foreach (i, v; s.values) {
				r |= repl(null, v, (string t) {s.setValue(i, t);}, count);
			}
			if (r) addResult(s);
		}
		auto et = cast(EventTree) c;
		if (et) {
			replKeyCode(et, et, count);
		}
		auto content = cast(Content) c;
		if (content) {
			replContent(content, count);
		}
	}
	private void replaceTextImpl() {
		string from = _from.getText;
		string to = _to.getText;
		if (!from.length) return;
		if (_useRegex.getSelection) {
			try {
				_regex = .regex!(dstring)(toUTF32(from), _notIgnoreCase.getSelection ? "gm" : "gim");
				_regexTarg = true;
				_toTemp = toUTF32(to);
			} catch (Exception e) {
				MessageBox.showWarning
					(_prop.msgs.regexError ~ "\n" ~ e.msg,
					_prop.msgs.dlgTitWarning, _win);
				return;
			}
		} else if (_useWildcard.getSelection) {
			_wildcard = Wildcard(from, !_notIgnoreCase.getSelection);
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
		_result.setRedraw = false;
		scope (exit) _result.setRedraw = true;
		reset;
		searchRange(count, &replaceTextImpl);
		setResultStatus(count);
		if (count > 0) _comm.replText.call;

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
				combo.setItems(list);
				combo.select = 0;
			}
		}
		addHist(_from, &_prop.var.etc.searchHistories,
			{return _prop.var.etc.searchHistories.dup;},
			_prop.var.etc.searchHistoryMax, from);
		if (_replMode) {
			addHist(_to, &_prop.var.etc.replaceHistories,
				{return _prop.var.etc.replaceHistories.dup;},
				_prop.var.etc.searchHistoryMax, to);
		}
	}
	private Regex!(dchar) _regex;
	private bool _regexTarg = false;
	private Wildcard _wildcard = null;
	private dstring _toTemp = ""d;
	/// FIXME: std.regex.replace()がdstringでコンパイルエラーになる。
	private static dstring impReplace(dstring s, Regex!(dchar) regex, dstring to) {
		dstring r = "";
		RegexMatch!(dstring) match;
		foreach (m; .match(s, regex)) {
			match = m;
			r ~= m.pre;
			r ~= to;
		}
		return r ~ match.post;
	}
	private string fTextRepl(string s) {
		if (_regexTarg) {
			return toUTF8(impReplace(toUTF32(s), _regex, _toTemp));
		}
		string to = _to.getText;
		if (_wildcard) {
			return _wildcard.replace(s, to);
		}
		string from = _from.getText;
		if (_notIgnoreCase.getSelection) {
			return .replace(s, from, to);
		} else {
			return .ireplace(s, from, to);
		}
	}
	private size_t fTextCount(string s) {
		if (_regexTarg) {
			size_t c = 0;
			foreach (m; std.regex.match(toUTF32(s), _regex)) {
				c++;
			}
			return c;
		}
		if (_wildcard) {
			return _wildcard.count(s);
		}
		string from = _from.getText;
		if (_notIgnoreCase.getSelection) {
			return std.algorithm.count(s, from);
		} else {
			return .icount(s, from);
		}
	}
	private void exit() {
		_win.close;
	}
	private bool _replMode = false;

	private void openPath() {
		auto itms = _result.getSelection;
		if (itms.length) {
			auto rp = cast(CWXPathString) itms[0].getData;
			if (rp) {
				auto path = rp.array;
				try {
					if (_comm.openCWXPath(path)) {
						_win.setActive;
						return;
					}
				} catch (Exception e) {
					debugln(e);
				}
				MessageBox.showWarning(_prop.msgs.cwxPathOpenError(path), _prop.msgs.dlgTitWarning, _win);
			} else {
				auto p = cast(PathString) itms[0].getData;
				assert (p);
				auto path = nabs(std.path.buildPath(_summ.scenarioPath, p.array));
				if (_comm.openFilePath(path)) {
					_win.setActive;
					return;
				}
				MessageBox.showWarning(_prop.msgs.filePathOpenError(path), _prop.msgs.dlgTitWarning, _win);
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
		} catch {}
		return _prop.images.unknown;
	}
	private void addResult(string path) {
		auto itm = new TableItem(_result, SWT.NONE);
		itm.setImage = fimage(std.path.buildPath(_summ.scenarioPath, path));
		itm.setText = encodePath(path);
		itm.setData = new PathString(path);
	}
	private void getPathParams(CWXPath path, out string text, out Image img) {
		img = null;
		text = "*Error*";
		auto sum = cast(Summary) path;
		if (sum) {
			img = _prop.images.summary;
			text = _prop.msgs.summary;
		}
		auto bgi = cast(BgImage) path;
		if (bgi) {
			img = _prop.images.backs;
			text = _prop.msgs.searchResultBgImage(bgi);
		}
		auto are = cast(Area) path;
		if (are) {
			img = _prop.images.area;
			text = _prop.msgs.searchResultIds(are);
		}
		auto bat = cast(Battle) path;
		if (bat) {
			img = _prop.images.battle;
			text = _prop.msgs.searchResultIds(bat);
		}
		auto pac = cast(Package) path;
		if (pac) {
			img = _prop.images.packages;
			text = _prop.msgs.searchResultIds(pac);
		}
		auto cas = cast(CastCard) path;
		if (cas) {
			img = _prop.images.casts;
			text = _prop.msgs.searchResultIds(cas);
		}
		auto ski = cast(SkillCard) path;
		if (ski) {
			img = _prop.images.skill;
			text = _prop.msgs.searchResultIds(ski);
		}
		auto ite = cast(ItemCard) path;
		if (ite) {
			img = _prop.images.item;
			text = _prop.msgs.searchResultIds(ite);
		}
		auto bea = cast(BeastCard) path;
		if (bea) {
			img = _prop.images.beast;
			text = _prop.msgs.searchResultIds(bea);
		}
		auto inf = cast(InfoCard) path;
		if (inf) {
			img = _prop.images.info;
			text = _prop.msgs.searchResultIds(inf);
		}
		auto con = cast(Content) path;
		if (con) {
			img = _prop.images.content(con.type);
			text = _prop.msgs.contentText(con, _summ);
		}
		auto tex = cast(TextHolder) path;
		if (tex) {
			Content c = cast(Content) tex.owner;
			if (!c) {
				auto dlg = cast(SDialog) tex.owner;
				if (dlg) c = dlg.parent;
			}
			if (c) {
				img = _prop.images.content(c.type);
				text = _prop.msgs.contentText(c, _summ);
			}
		}
		auto fla = cast(Flag) path;
		if (fla) {
			img = _prop.images.flag;
			text = _prop.msgs.searchResultFlags(fla);
		}
		auto ste = cast(Step) path;
		if (ste) {
			img = _prop.images.step;
			text = _prop.msgs.searchResultFlags(ste);
		}
		auto fld = cast(FlagDir) path;
		if (fld) {
			img = _prop.images.flagDir;
			text = _prop.msgs.searchResultFlags(fld);
		}
		auto eve = cast(EventTree) path;
		if (eve) {
			img = _prop.images.eventTree;
			text = _prop.msgs.searchResultEventTree(eve);
		}
		auto men = cast(MenuCard) path;
		if (men) {
			img = _prop.images.cards;
			text = _prop.msgs.searchResultMenuCard(men);
		}
		auto ene = cast(EnemyCard) path;
		if (ene) {
			img = _prop.images.cards;
			text = _prop.msgs.searchResultEnemyCard(ene, _summ);
		}
		assert (img);
	}
	private void addResult(CWXPath path, string desc = "") {
		auto itm = new TableItem(_result, SWT.NONE);
		string text;
		Image img;
		getPathParams(path, text, img);
		itm.setImage = img;
		if (desc.length) text = desc ~ " - " ~ text;
		itm.setText = text;
		itm.setData = new CWXPathString(path.cwxPath);
	}
	private bool repl(CWXPath path, string text, void delegate(string) set, ref size_t count) {
		auto c = fTextCount(text);
		count += c;
		if (c > 0) {
			if (_replMode) set(fTextRepl(text));
			if (path) addResult(path);
			return true;
		}
		return false;
	}
	private bool replFilePath(string text, void delegate(string) set, ref size_t count) {
		auto c = fTextCount(encodePath(text));
		count += c;
		if (c > 0) {
			if (_replMode) set(fTextRepl(decodePath(text)));
			return true;
		}
		return false;
	}

	private bool replFlagName(F)(FlagDir parent, F flag, ref size_t count) {
		string text = flag.name;
		auto c = fTextCount(text);
		count += c;
		if (c > 0) {
			if (_replMode) flag.name = parent.validName(fTextRepl(text));
			addResult(flag);
			return true;
		}
		return false;
	}

	private bool replRqCoupons(C)(CWXPath path, C targ, ref size_t count) {
		string[] coupons = targ.rCoupons;
		bool r = false;
		foreach (i, cp; coupons) {
			r |= repl(null, cp, (string t) {cp = t;}, count);
			if (_replMode) coupons[i] = cp;
		}
		if (r) {
			if (_replMode) targ.rCoupons = coupons;
			if (path) addResult(targ);
			return true;
		}
		return false;
	}

	private bool replKeyCode(C)(CWXPath path, C targ, ref size_t count) {
		if (keyCode) {
			auto kcs = targ.keyCodes.dup;
			bool r = false;
			foreach (i, kc; kcs) {
				r |= repl(null, kc, (string t) {kc = t;}, count);
				if (_replMode) kcs[i] = kc;
			}
			if (r) {
				if (_replMode) targ.keyCodes = kcs;
				if (path) addResult(path);
				return true;
			}
		}
		return false;
	}

	private bool replBgImage(CWXPath path, BgImage back, ref size_t count) {
		string from = _from.getText;
		string to = _to.getText;
		bool r = false;
		if (flag) {
			r |= repl(null, back.flag, &back.flag, count);
		}
		if (file) {
			r |= replFilePath(back.path, &back.path, count);
		}
		if (r && path) {
			addResult(path);
		}
		return r;
	}
	private bool replCard(C)(CWXPath path, C card, ref size_t count) {
		string from = _from.getText;
		string to = _to.getText;
		bool r = false;
		if (cardName) {
			r |= repl(null, card.name, &card.name, count);
		}
		if (cardDesc) {
			r |= repl(null, card.desc, &card.desc, count);
		}
		if (flag) {
			static if (is (C : IFlagUser)) {
				r |= repl(null, card.flag, &card.flag, count);
			}
		}
		if (file) {
			r |= replFilePath(card.path, &card.path, count);
		}
		static if (is (C : EffectCard)) {
			r |= replKeyCode!(C)(null, card, count);
		}
		if (r && path) {
			addResult(path);
		}
		return r;
	}
	void replContent(Content e, ref size_t count) {
		auto eo = e.parent;
		assert (!eo || eo.detail.owner);
		string from = _from.getText;
		string to = _to.getText;
		bool r = false;
		if (event && (!eo || eo.detail.nextType == CNextType.TEXT)) {
			r |= repl(null, e.name, &e.name, count);
		}
		if (flag) {
			r |= repl(null, e.flag, &e.flag, count);
			r |= repl(null, e.step, &e.step, count);
		}
		if (start) {
			r |= repl(null, e.start, &e.start, count);
			if (e.type == CType.START) {
				r |= repl(null, e.name, &e.name, count);
			}
		}
		if (coupon) {
			r |= repl(null, e.coupon, &e.coupon, count);
		}
		if (gossip) {
			r |= repl(null, e.gossip, &e.gossip, count);
		}
		if (end) {
			r |= repl(null, e.completeStamp, &e.completeStamp, count);
		}
		if (msg) {
			r |= repl(null, e.text, &e.text, count);
			auto dlgs = e.dialogs;
			foreach (dlg; dlgs) {
				if (msg) {
					r |= repl(null, dlg.text, &dlg.text, count);
				}
				if (coupon) {
					r |= replRqCoupons!(typeof(dlg))(null, dlg, count);
				}
			}
		}
		if (file) {
			r |= replFilePath(e.cardPath, &e.cardPath, count);
			r |= replFilePath(e.bgmPath, &e.bgmPath, count);
			r |= replFilePath(e.soundPath, &e.soundPath, count);
		}
		if (comment) {
			r |= repl(null, e.comment, &e.comment, count);
		}
		if (r) {
			addResult(e);
		}
	}
}
