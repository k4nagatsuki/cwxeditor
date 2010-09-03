
module cwx.summary;

import std.file;
import std.stream;
import std.path;
import std.zip;
import std.date;
import std.string;

import cwx.cwl;
import cwx.flag;
import cwx.utils;
import cwx.area;
import cwx.card;
import cwx.usecounter;
import cwx.props;
import cwx.archive;
import cwx.xml;
import cwx.skin;
import cwx.path;

public:

/// 貼り紙関連の例外。
class SummaryException : Exception {
public:
	this(string msg) {
		super(msg);
	}
}

public const {
	/// エリアのファイルを保管するディレクトリ名。
	string PATH_AREA = "Area";
	/// パッケージのファイルを保管するディレクトリ名。
	string PATH_PACKAGE = "Package";
	/// バトルのファイルを保管するディレクトリ名。
	string PATH_BATTLE = "Battle";
	/// キャストカードのファイルを保管するディレクトリ名。
	string PATH_CAST = "CastCard";
	/// アイテムカードのファイルを保管するディレクトリ名。
	string PATH_ITEM = "ItemCard";
	/// スキルカードのファイルを保管するディレクトリ名。
	string PATH_SKILL = "SkillCard";
	/// 召喚獣カードのファイルを保管するディレクトリ名。
	string PATH_BEAST = "BeastCard";
	/// 情報カードのファイルを保管するディレクトリ名。
	string PATH_INFO = "InfoCard";
}

private template STemplate(bool UseCast, bool UseSkill, bool UseItem, bool UseBeast, bool UseInfo) {
	private {
		static if (UseCast) CastCard[] _cast; /// キャスト
		static if (UseSkill) SkillCard[] _skl; /// スキル
		static if (UseItem) ItemCard[] _itm; /// アイテム
		static if (UseBeast) BeastCard[] _bst; /// 召喚獣
		static if (UseInfo) InfoCard[] _info; /// 情報
		static void __loadXMLCommon(A)(string xml, string name, ref A[] areas,
				UseCounter uc, void delegate() change, string ver) {
			auto doc = XNode.parse(xml);
			if (doc.name == name) {
				auto area = A.createFromNode(doc, ver);
				if (uc) area.setUseCounter = uc;
				if (change) area.changeHandler = change;
				areas ~= area;
			}
		}
		static void __loadXML1(A)(string targPath, string name, ref A[] areas,
				UseCounter uc, void delegate() change, string ver) {
			if (exists(targPath)) {
				foreach (p; clistdir(targPath)) {
					p = std.path.join(targPath, p);
					if (!isdir(p) && fnmatch(getExt(p), "xml")) {
						try {
							__loadXMLCommon(cast(string) std.file.read(p), name, areas, uc, change, ver);
						} catch (Exception e) {
							throw new FileLoadException(p, e);
						}
					}
				}
				// ID順でソート。
				areas.sort;
			}
		}
		static void __loadXML2(A)(string[string][string] xmls,
				string dirName, string name, ref A[] areas,
				UseCounter uc, void delegate() change, string ver) {
			auto dir = dirName in xmls;
			if (!dir) return;
			foreach (file, xml; *dir) {
				try {
					__loadXMLCommon(xml, name, areas, uc, change, ver);
				} catch (Exception e) {
					throw new Exception(std.path.join(dirName, file));
				}
			}
			// ID順でソート。
			areas.sort;
		}
		static C __find(C)(C[] arr, ulong id) {
			foreach (c; arr) {
				if (c.id == id) {
					return c;
				}
			}
			return null;
		}
	}
	public {
		static if (UseCast) {
			/// キャスト。
			CastCard[] casts() {
				return _cast;
			}
			/// ditto
			CastCard casts(ulong id) {
				return __find(_cast, id);
			}
		}
		static if (UseSkill) {
			/// スキル。
			SkillCard[] skills() {
				return _skl;
			}
			/// ditto
			SkillCard skill(ulong id) {
				return __find(_skl, id);
			}
		}
		static if (UseItem) {
			/// アイテム。
			ItemCard[] items() {
				return _itm;
			}
			/// ditto
			ItemCard item(ulong id) {
				return __find(_itm, id);
			}
		}
		static if (UseBeast) {
			/// 召喚獣。
			BeastCard[] beasts() {
				return _bst;
			}
			/// ditto
			BeastCard beast(ulong id) {
				return __find(_bst, id);
			}
		}
		static if (UseInfo) {
			/// 情報カード。
			InfoCard[] infos() {
				return _info;
			}
			/// ditto
			InfoCard info(ulong id) {
				return __find(_info, id);
			}
		}
	}

	// 以降は圧縮シナリオ・一時展開関係のAPI。
	private bool _expandXMLs;
	private bool _useTemp = true;
	private File _lock = null;
	private string _zipName = "";
	private bool _legacy = false;

	/// XMLファイルを展開しているか。
	bool expandXMLs() {return _expandXMLs;}
	/// 現在のscenarioPathは一時展開先か。
	bool useTemp() {return _useTemp && !_legacy;}
	/// 元の圧縮ファイル名は何か。圧縮されていないシナリオの場合は""。
	string zipName() {return _zipName;}
	/// ditto
	void zipName(string zipName) {_zipName = zipName;}
	/// クラシックな形式のシナリオか。
	bool legacy() {return _legacy;}

	alias typeof(this) S;

	static string createTempDir(string tempPath, string name) {
		string base = cwx.utils.toHex(name);
		base = base.length > 15 ? base[0 .. 15] : base;
		auto temp = createNewFileName(std.path.join(tempPath, base), true);
		mkdirRecurse(temp);
		std.file.write(std.path.join(temp, "cwxeditor.lock"), []);
		return temp;
	}

	static S loadScenarioFromFile(CProps prop, string fname, bool expand, string tempPath, S old,
			void delegate(uint) setMax, void delegate(uint) worked) {
		string[string][string] xmls;
		string sunzip(string fname, ZipArchive arc, out bool cancel = false) {
			auto temp = createTempDir(tempPath, getBaseName(getName(fname)));
			if (expand) {
				.unzip(temp, arc, setMax, worked);
			} else {
				.unzip(arc, (string path, ubyte[] data, bool isDir) {
					if (!isDir) {
						if (fnmatch(path, "Summary.xml")) {
							xmls[""][path] = cast(string) data;
						} else if (fnmatch(getExt(path), "xml") && isScenarioSystemDir(getDirName(path))) {
							xmls[getDirName(path)][getBaseName(path)] = cast(string) data;
						} else {
							path = std.path.join(temp, path);
							string parent = getDirName(path);
							if (!exists(parent)) mkdirRecurse(parent);
							std.file.write(path, data);
						}
					} else if (!isScenarioSystemDir(path)) {
						path = std.path.join(temp, path);
						if (!exists(path)) mkdirRecurse(path);
					}
				}, setMax, worked);
			}
			return temp;
		}
		S load(string p) {
			S r;
			if (expand) {
				r = S.fromXMLs(std.path.join(p, "Summary.xml"));
			} else {
				r = S.fromXMLs(p, xmls);
			}
			if (old) old.delTemp;
			return r;
		}
		S loadLegacy(string p) {
			S r = loadLScenario!(S)(p, "MedievalFantasy");
			if (old) old.delTemp;
			return r;
		}
		if (fname) {
			if (exists(fname)) {
				try {
					if (isdir(fname)) {
						if (exists(std.path.join(fname, "Summary.xml"))) {
							fname = std.path.join(fname, "Summary.xml");
						} else if (exists(std.path.join(fname, "Summary.wsm"))) {
							fname = std.path.join(fname, "Summary.wsm");
						}
					}
					if (fnmatch(getBaseName(fname), "Summary.wsm")) {
						auto r = loadLegacy(getDirName(fname));
						r._expandXMLs = false;
						r._useTemp = false;
						r._legacy = true;
						r._zipName = "";
						return r;
					} else if (fnmatch(getBaseName(fname), "Summary.xml")) {
						expand = true;
						auto r = load(getDirName(fname));
						r._expandXMLs = true;
						r._useTemp = false;
						r._legacy = false;
						r._zipName = "";
						return r;
					} else {
						scope arc = new ZipArchive(std.file.read(fname));
						foreach (am; arc.directory) {
							if (am.name == "Summary.xml") {
								bool cancel;
								string zipname = fname;
								fname = sunzip(getBaseName(fname), arc, cancel);
								if (fname.length) {
									try {
										S r = load(fname);
										r._expandXMLs = expand;
										r._useTemp = true;
										r._zipName = zipname;
										r._legacy = false;
										r.lock;
										return r;
									} catch (Exception e) {
										delAll(fname);
										throw e;
									}
								} else if (cancel) {
									delAll(getDirName(fname));
									return null;
								}
							}
						}
						// シナリオの圧縮ファイルではない。
						throw new SummaryException(prop.msgs.notScenario(fname));
					}
				} catch (ZipException e) {
					debugln(e);
					throw new SummaryException(prop.msgs.zipError(fname));
				} catch (FileLoadException e) {
					debugln(e);
					throw new SummaryException(prop.msgs.loadError(e.path));
				} catch (Exception e) {
					debugln(e);
					throw new SummaryException(prop.msgs.loadError(fname));
				}
			} else {
				throw new SummaryException(prop.msgs.loadError(fname));
			}
		}
		return null;
	}
	private void lock() {
		assert (!_lock);
		if (useTemp) {
			_lock = new File(std.path.join(scenarioPath, "cwxeditor.lock"), FileMode.OutNew);
		}
	}
	/// 一時展開先を削除する。
	void delTemp() {
		if (useTemp) {
			_lock.close;
			try {
				delAll(scenarioPath, true);
				_useTemp = false;
				_zipName = null;
			} catch (Exception e) {
				debugln(e.toString);
				lock;
			}
		}
	}
	private CWXPath findCWXPathImpl(string path, string cate) {
		switch (cate) {
		case "castcard": {
			static if (UseCast) {
				auto index = cpindex(path);
				return index < casts.length ? casts[index].findCWXPath(cpbottom(path)) : null;
			}
		}
		case "castcard:id": {
			static if (UseCast) {
				auto card = casts(cpindex(path));
				return card ? card.findCWXPath(cpbottom(path)) : null;
			}
		}
		case "skillcard": {
			static if (UseSkill) {
				auto index = cpindex(path);
				return index < skills.length ? skills[index].findCWXPath(cpbottom(path)) : null;
			}
		}
		case "skillcard:id": {
			static if (UseSkill) {
				auto card = skill(cpindex(path));
				return card ? card.findCWXPath(cpbottom(path)) : null;
			}
		}
		case "itemcard": {
			static if (UseItem) {
				auto index = cpindex(path);
				return index < items.length ? items[index].findCWXPath(cpbottom(path)) : null;
			}
		}
		case "itemcard:id": {
			static if (UseItem) {
				auto card = item(cpindex(path));
				return card ? card.findCWXPath(cpbottom(path)) : null;
			}
		}
		case "beastcard": {
			static if (UseBeast) {
				auto index = cpindex(path);
				return index < beasts.length ? beasts[index].findCWXPath(cpbottom(path)) : null;
			}
		}
		case "beastcard:id": {
			static if (UseBeast) {
				auto card = beast(cpindex(path));
				return card ? card.findCWXPath(cpbottom(path)) : null;
			}
		}
		case "infocard": {
			static if (UseInfo) {
				auto index = cpindex(path);
				return index < infos.length ? infos[index].findCWXPath(cpbottom(path)) : null;
			}
		}
		case "infocard:id": {
			static if (UseInfo) {
				auto card = info(cpindex(path));
				return card ? card.findCWXPath(cpbottom(path)) : null;
			}
		}
		default: break;
		}
		return null;
	}
}

/// 貼り紙。シナリオの情報が入る。
class Summary : CWXPath, AreaOwner, BattleOwner, PackageOwner,
		CastOwner, SkillOwner, ItemOwner, BeastOwner, InfoOwner {
private:
	string _id;

	string _sPath = null;
	string _sname = "";
	string _author = ""; /// 作者名
	PathUser _imgPath; /// 貼り紙画像のパス
	string _desc = ""; /// 貼り紙の文章
	uint _levMin = 0; /// 推奨レベル(下)
	uint _levMax = 0; /// 推奨レベル(上)
	uint _rCouponNum = 0; /// 前提クーポン必要数
	string[] _rCoupons = []; /// 前提クーポン
	AreaUser _startAreaId; /// スタートエリアのID
	// TODO Tag
	string _type;
	string _dataVersion;

	FlagDir _froot; /// フラグとステップのデータ

	Area[] _area; /// エリア
	Package[] _pkg; /// パッケージ
	Battle[] _btl; /// バトル

	UseCounter _uc;
	bool _change = false;

	void changeHandler() {
		_change = true;
	}

	this(string sPath) {
		_sPath = sPath;
		_id = format("%08X", &this) ~ "-" ~ to!(string)(getUTCtime);
		_uc = new UseCounter;
		_froot = new FlagDir(this);
		_froot.changeHandler = &changeHandler;
		_startAreaId = new AreaUser(this);
		_startAreaId.setUseCounter(_uc);
		_imgPath = new PathUser(this);
		_imgPath.setUseCounter(_uc);
	}
public:
	/// シナリオ名、スキン、シナリオのパスを指定してインスタンスを生成。
	this(string sname, string type, string sPath, bool legacy) {
		this(sPath);
		_type = type;
		_sname = sname;
		_legacy = legacy;
		_useTemp = !legacy;
		lock;
	}
	override string cwxPath() {return "";}
	override CWXPath findCWXPath(string path) {
		if (path == "") return this;
		auto cate = cpcategory(path);
		switch (cate) {
		case "area": {
			auto index = cpindex(path);
			return index < areas.length ? areas[index].findCWXPath(cpbottom(path)) : null;
		}
		case "area:id": {
			auto area = area(cpindex(path));
			return area ? area.findCWXPath(cpbottom(path)) : null;
		}
		case "battle": {
			auto index = cpindex(path);
			return index < battles.length ? battles[index].findCWXPath(cpbottom(path)) : null;
		}
		case "battle:id": {
			auto area = battle(cpindex(path));
			return area ? area.findCWXPath(cpbottom(path)) : null;
		}
		case "package": {
			auto index = cpindex(path);
			return index < packages.length ? packages[index].findCWXPath(cpbottom(path)) : null;
		}
		case "package:id": {
			auto area = packages(cpindex(path));
			return area ? area.findCWXPath(cpbottom(path)) : null;
		}
		default: break;
		}
		return findCWXPathImpl(path, cate);
	}
	/// マシン上で一意なID。
	string id() {
		return _id;
	}
	/// このシナリオが変更済みであればtrueを返す。
	bool isChanged() {
		return _change;
	}
	/// 変更状態をリセットする。
	void resetChanged() {
		_change = false;
	}
	/// 変更を通知する。
	void changed() {
		_change = true;
	}
	/// このシナリオが持つ使用回数カウンタ。
	UseCounter useCounter() {
		return _uc;
	}

	/// 圧縮して保存した事を通知する。
	private void toArchive(string zipName, string scenarioPath, bool expandXMLs) in {
		assert (_zipName == "");
	} body {
		_expandXMLs = expandXMLs;
		_useTemp = true;
		_zipName = zipName;
		_legacy = false;
		this.scenarioPath = scenarioPath;
		lock;
	}

	/// データバージョン。
	string dataVersion() {return _dataVersion;}
	/// ditto
	private void dataVersion(string ver) {_dataVersion = ver;}

	/// シナリオの作者名。
	void author(string author) {
		if (_author != author) changeHandler;
		_author = author;
	}
	/// ditto
	string author() {
		return _author;
	}

	/// シナリオのタイプ。スキンを決定する。
	string type() {
		return _type;
	}
	/// ditto
	void type(string type) {
		if (_type != type) changeHandler;
		_type = type;
	}

	/// 貼り紙の画像パス。
	void imagePath(string imgPath) {
		if (_imgPath.path != imgPath) changeHandler;
		_imgPath.path = imgPath;
	}
	/// ditto
	string imagePath() {
		return _imgPath.path;
	}

	/// シナリオの解説。
	void desc(string desc) {
		if (_desc != desc) changeHandler;
		_desc = desc;
	}
	/// ditto
	string desc() {
		return _desc;
	}

	/// 推奨レベル(低)
	void levelMin(uint levMin) {
		if (_levMin != levMin) changeHandler;
		_levMin = levMin;
	}
	/// ditto
	uint levelMin() {
		return _levMin;
	}

	/// 推奨レベル(高)
	void levelMax(uint levMax) {
		if (_levMax != levMax) changeHandler;
		_levMax = levMax;
	}
	/// ditto
	uint levelMax() {
		return _levMax;
	}

	/// 開始条件クーポンの必要数。
	void rCouponNum(uint rCouponNum) {
		if (_rCouponNum != rCouponNum) changeHandler;
		_rCouponNum = rCouponNum;
	}
	/// ditto
	uint rCouponNum() {
		return _rCouponNum;
	}

	/// 開始条件クーポンの一覧。
	void rCoupons(string[] rCoupons) {
		if (_rCoupons != rCoupons) changeHandler;
		_rCoupons = rCoupons;
	}
	/// ditto
	string[] rCoupons() {
		return _rCoupons;
	}

	/// シナリオの開始エリア。
	void startArea(ulong startAreaId) {
		if (_startAreaId.area != startAreaId) changeHandler;
		_startAreaId.area = startAreaId;
	}
	/// ditto
	ulong startArea() {
		return _startAreaId.area;
	}

	/// シナリオに含まれるエリア。
	Area[] areas() {
		return _area;
	}
	/// シナリオに含まれるパッケージ。
	Package[] packages() {
		return _pkg;
	}
	/// シナリオに含まれるバトル。
	Battle[] battles() {
		return _btl;
	}

	private static bool hasId(T)(T[] arr, ulong id) {
		foreach (a; arr) {
			if (a.id == id) {
				return true;
			}
		}
		return false;
	}

	/// 指定された要素のindexを検索する。
	int indexOf(T)(T c) {
		static if (is (T == CastCard)) {
			return .indexOf!("a is b")(_cast, c);
		} else static if (is (T == SkillCard)) {
			return .indexOf!("a is b")(_skl, c);
		} else static if (is (T == ItemCard)) {
			return .indexOf!("a is b")(_itm, c);
		} else static if (is (T == BeastCard)) {
			return .indexOf!("a is b")(_bst, c);
		} else static if (is (T == InfoCard)) {
			return .indexOf!("a is b")(_info, c);
		} else static if (is (T == Area)) {
			return .indexOf!("a is b")(_area, c);
		} else static if (is (T == Battle)) {
			return .indexOf!("a is b")(_btl, c);
		} else static if (is (T == Package)) {
			return .indexOf!("a is b")(_pkg, c);
		} else {
			static assert (0);
		}
	}

	/// エリア。
	Area area(ulong id) {
		return __find(_area, id);
	}
	/// バトル。
	Battle battle(ulong id) {
		return __find(_btl, id);
	}
	/// パッケージ。
	Package packages(ulong id) {
		return __find(_pkg, id);
	}

	/// 指定されたIDのエリア・バトル・パッケージがあればtrue。
	bool hasAreaId(ulong id) {
		return hasId(_area, id);
	}
	/// ditto
	bool hasBattleId(ulong id) {
		return hasId(_btl, id);
	}
	/// ditto
	bool hasPackageId(ulong id) {
		return hasId(_pkg, id);
	}

	/// 今現在このシナリオに含まれていないTのIDを生成して返す。
	ulong newId(T)() {
		static if (is (T == CastCard)) {
			return __newId(_cast);
		} else static if (is (T == SkillCard)) {
			return __newId(_skl);
		} else static if (is (T == ItemCard)) {
			return __newId(_itm);
		} else static if (is (T == BeastCard)) {
			return __newId(_bst);
		} else static if (is (T == InfoCard)) {
			return __newId(_info);
		} else static if (is (T == Area)) {
			return __newId(_area);
		} else static if (is (T == Battle)) {
			return __newId(_btl);
		} else static if (is (T == Package)) {
			return __newId(_pkg);
		} else {
			static assert (0);
		}
	}
	/// ditto
	ulong newAreaId() {
		return __newId(_area);
	}
	/// ditto
	ulong newBattleId() {
		return __newId(_btl);
	}
	/// ditto
	ulong newPackageId() {
		return __newId(_pkg);
	}
	private static ulong __newId(T)(T[] arr) {
		return arr.length > 0 ? arr[$ - 1].id + 1 : 1;
	}

	private ulong __insert(T, alias ToID)(ref T[] arr, int index, T c) {
		if (arr.length == index) {
			return __add!(T, ToID)(arr, c, true);
		} else {
			ulong tempId = 0;
			bool remv = false;
			foreach (i, c_; arr) {
				if (c_ is c) {
					if (i == index) return c.id;
					remv = true;
					tempId = arr[$ - 1].id + 2L;
					_uc.change(ToID(c.id), ToID(tempId));
					__remove(arr, c);
					if (i <= index) index--;
					break;
				}
			}
			ulong oldId = c.id;
			c.id(index == 0 ? 1L : arr[index - 1].id() + 1L);
			arr = arr[0 .. index] ~ c ~ arr[index .. $];
			ulong chg[ulong];
			for (size_t i = index + 1; i < arr.length; i++) {
				if (arr[i - 1].id == arr[i].id) {
					ulong o = arr[i].id();
					arr[i].id = arr[i].id + 1L;
					chg[o] = arr[i].id;
				}
			}
			c.setUseCounter = _uc;
			c.changeHandler = &changeHandler;
			c.owner = this;
			changeHandler;
			foreach_reverse (o; chg.keys.sort) {
				_uc.change(ToID(o), ToID(chg[o]));
			}
			if (remv) {
				_uc.change(ToID(tempId), ToID(c.id));
			}
			return oldId;
		}
	}
	/// このシナリオにカード・エリア等を挿入する。
	ulong insert(int index, CastCard c) {
		return __insert!(CastCard, toCastId)(_cast, index, c);
	}
	/// ditto
	ulong insert(int index, SkillCard c) {
		return __insert!(SkillCard, toSkillId)(_skl, index, c);
	}
	/// ditto
	ulong insert(int index, ItemCard c) {
		return __insert!(ItemCard, toItemId)(_itm, index, c);
	}
	/// ditto
	ulong insert(int index, BeastCard c) {
		return __insert!(BeastCard, toBeastId)(_bst, index, c);
	}
	/// ditto
	ulong insert(int index, InfoCard c) {
		return __insert!(InfoCard, toInfoId)(_info, index, c);
	}
	/// ditto
	ulong insert(int index, Area c) {
		return __insert!(Area, toAreaId)(_area, index, c);
	}
	/// ditto
	ulong insert(int index, Battle c) {
		return __insert!(Battle, toBattleId)(_btl, index, c);
	}
	/// ditto
	ulong insert(int index, Package c) {
		return __insert!(Package, toPackageId)(_pkg, index, c);
	}

	private ulong __add(T, alias ToID)(ref T[] arr, T area, bool forceNewId) {
		if (arr.length > 0 && arr[$ - 1] is area) return area.id;
		auto oldId = area.id;
		if (forceNewId || (arr.length > 0 && arr[$ - 1].id >= area.id) ) {
			area.id = __newId(arr);
		}
		foreach (i, c_; arr) {
			if (c_ is area) {
				__remove(arr, area);
				_uc.change(ToID(oldId), ToID(area.id));
				break;
			}
		}
		arr ~= area;
		area.setUseCounter = _uc;
		area.changeHandler = &changeHandler;
		area.owner = this;
		changeHandler;
		return oldId;
	}

	/// このシナリオにカード・エリア等を追加する。
	ulong add(Area area, bool forceNewId = true) {
		auto id = __add!(Area, toAreaId)(_area, area, forceNewId);
		if (areas.length == 1) {
			startArea = id;
		}
		return id;
	}
	/// ditto
	ulong add(Battle btl, bool forceNewId = true) {
		return __add!(Battle, toBattleId)(_btl, btl, forceNewId);
	}
	/// ditto
	ulong add(Package pkg, bool forceNewId = true) {
		return __add!(Package, toPackageId)(_pkg, pkg, forceNewId);
	}
	/// ditto
	ulong add(CastCard c, bool forceNewId = true) {
		return __add!(CastCard, toCastId)(_cast, c, forceNewId);
	}
	/// ditto
	ulong add(SkillCard c, bool forceNewId = true) {
		return __add!(SkillCard, toSkillId)(_skl, c, forceNewId);
	}
	/// ditto
	ulong add(ItemCard c, bool forceNewId = true) {
		return __add!(ItemCard, toItemId)(_itm, c, forceNewId);
	}
	/// ditto
	ulong add(BeastCard c, bool forceNewId = true) {
		return __add!(BeastCard, toBeastId)(_bst, c, forceNewId);
	}
	/// ditto
	ulong add(InfoCard c, bool forceNewId = true) {
		return __add!(InfoCard, toInfoId)(_info, c, forceNewId);
	}

	private void __remove(T)(ref T[] arr, T area) {
		foreach (i, a; arr) {
			if (a.id == area.id) {
				arr = arr[0 .. i] ~ arr[i + 1 .. $];
				area.removeUseCounter;
				area.changeHandler = null;
				area.owner = null;
				changeHandler;
				return;
			}
		}
	}

	/// カード・エリア等を除去する。
	void remove(CastCard c) {
		__remove(_cast, c);
	}
	/// ditto
	void remove(SkillCard c) {
		__remove(_skl, c);
	}
	/// ditto
	void remove(ItemCard c) {
		__remove(_itm, c);
	}
	/// ditto
	void remove(BeastCard c) {
		__remove(_bst, c);
	}
	/// ditto
	void remove(InfoCard c) {
		__remove(_info, c);
	}
	/// ditto
	void remove(Area a) {
		__remove(_area, a);
		if (a.id == startArea) {
			startArea = areas.length > 0 ? areas[0].id : 0;
		}
	}
	/// ditto
	void remove(Battle a) {
		__remove(_btl, a);
	}
	/// ditto
	void remove(Package a) {
		__remove(_pkg, a);
	}
	/// ditto
	void remove(AbstractArea area) {
		if (cast(Area) area) {
			remove(cast(Area) area);
		} else if (cast(Package) area) {
			remove(cast(Package) area);
		} else {
			assert (cast(Battle) area);
			remove(cast(Battle) area);
		}
	}

	private string summaryToXML() {
		auto root = XNode.create("Summary");
		auto pNode = root.newElement("Property");
		pNode.newElement("Name", _sname);
		pNode.newElement("ImagePath", encodePath(_imgPath.path));
		pNode.newElement("Author", _author);
		pNode.newElement("Description", encodeLf(_desc));
		auto lv = pNode.newElement("Level");
		lv.newAttr("min", _levMin);
		lv.newAttr("max", _levMax);
		auto rc = pNode.newElement("RequiredCoupons", encodeLf(_rCoupons));
		rc.newAttr("number", _rCouponNum);
		pNode.newElement("StartAreaId", _startAreaId.area);
		pNode.newElement("Tags");
		pNode.newElement("Type", _type);
		flagDirRoot.toNodeAll(root);
		root.newElement("Labels");
		return root.text;
	}
	/// XML形式のシナリオデータを返す。
	/// 戻り値の連想配列の内容は次のようになる。
	/// ---
	/// [
	/// 	"":["Summary.xml":(貼り紙のXML表現)],
	/// 	"Area/":["01_aaa.xml":(エリアaaaのXML表現), "02_bbb.xml":(エリアbbbのXML表現) ...],
	/// 	"Battle/":["01_ccc.xml":(バトルcccのXML表現), "02_ddd.xml":(バトルdddのXML表現) ...],
	/// 	  :
	/// 	  :
	/// 	"InfoCard/":["01_eee.xml":(情報カードeeeのXML表現) ...]
	/// ]
	/// ---
	string[string][string] toXMLs() {
		string[string][string] r = ["":["Summary.xml":summaryToXML]];

		void put(string parent, string[string] p) {
			if (p.length) {
				r[parent] = p;
			}
		}
		put(PATH_AREA, __toXMLs(_area));
		put(PATH_BATTLE, __toXMLs(_btl));
		put(PATH_PACKAGE, __toXMLs(_pkg));

		put(PATH_CAST, __toXMLs(_cast));
		put(PATH_SKILL, __toXMLs(_skl));
		put(PATH_ITEM, __toXMLs(_itm));
		put(PATH_BEAST, __toXMLs(_bst));
		put(PATH_INFO, __toXMLs(_info));

		return r;
	}
	private static string[string] __toXMLs(A)(A[] targs) {
		string[string] r;
		foreach (targ; targs) {
			auto fname = format("%02d", targ.id) ~ ".xml";
			r[fname] = targ.toXML;
		}
		return r;
	}
	/// 指定されたパスにXML形式でシナリオを上書き保存する。
	/// Area、Battle、Package、CastCard、SkillCard、ItemCard、BeastCard、InfoCard
	/// の各ディレクトリにある*.xmlは一旦全て削除される。
	/// Params:
	/// path = 保存先のパス。
	/// Throws:
	/// IOException = ファイル削除時・保存時例外発生時。
	void saveXMLs(string path) {
		std.file.write(std.path.join(path, "Summary.xml"), summaryToXML);

		__saveXML(std.path.join(path, PATH_AREA), _area);
		__saveXML(std.path.join(path, PATH_BATTLE), _btl);
		__saveXML(std.path.join(path, PATH_PACKAGE), _pkg);

		__saveXML(std.path.join(path, PATH_CAST), _cast);
		__saveXML(std.path.join(path, PATH_SKILL), _skl);
		__saveXML(std.path.join(path, PATH_ITEM), _itm);
		__saveXML(std.path.join(path, PATH_BEAST), _bst);
		__saveXML(std.path.join(path, PATH_INFO), _info);
	}
	/// ditto
	void saveXMLs() {
		saveXMLs(_sPath);
	}
	private static void delAllXML(string p) {
		foreach (t; clistdir(p)) {
			t = std.path.join(p, t);
			if (!isdir(t) && fnmatch(getExt(t), "xml")) {
				std.file.remove(t);
			}
		}
	}
	private static void __saveXML(A)(string path, A[] targs) {
		if (targs.length == 0) {
			if (exists(path) && isdir(path)) {
				delAllXML(path);
				if (clistdir(path).length == 0) {
					rmdir(path);
				}
			}
		} else {
			if (exists(path) && isdir(path)) {
				delAllXML(path);
			} else {
				mkdir(path);
			}
			foreach (targ; targs) {
				auto p = createFileI(path, targ.name, "xml", format("%02d", targ.id) ~ "_");
				std.file.write(p, targ.toXML);
			}
		}
	}

	private static Summary summaryFromXML(string sPath, string xml) {
		scope summNode = XNode.parse(xml);
		if (summNode.name == "Summary") {
			auto summ = new Summary(sPath);
			string ver = summNode.attr("dataVersion", false);
			summ.dataVersion = ver ? ver : "";
			summNode.onTag["Property"] = (ref XNode propNode) {
				propNode.onTag["Name"] = (ref XNode node) {summ._sname = node.value;};
				propNode.onTag["ImagePath"] = (ref XNode node) {summ._imgPath.path = decodePath(node.value);};
				propNode.onTag["Author"] = (ref XNode node) {summ._author = node.value;};
				propNode.onTag["Description"] = (ref XNode node) {summ._desc = decodeLf2(node.value);};
				propNode.onTag["Level"] = (ref XNode node) {
					summ._levMin = node.attr!(uint)("min", true);
					summ._levMax = node.attr!(uint)("max", true);
				};
				propNode.onTag["RequiredCoupons"] = (ref XNode node) {
					summ._rCouponNum = node.attr!(uint)("number", true);
					summ._rCoupons = decodeLf(node.value);
				};
				propNode.onTag["StartAreaId"] = (ref XNode node) {summ._startAreaId.area = node.valueTo!(ulong);};
				propNode.onTag["Type"] = (ref XNode node) {summ._type = node.value;};
				propNode.parse;
			};
			summ._froot = FlagDir.fromXmlNode(summNode, &summ.changeHandler, summ.dataVersion);
			return summ;
		}
		throw new SummaryException("File is not summary: " ~ sPath);
	}
	private void checkStartArea() {
		foreach (area; areas) {
			if (area.id == startArea) {
				return;
			}
		}
		_startAreaId.area = areas.length > 0 ? areas[0].id : 0;
	}

	/// XMLを元にしたインスタンス。
	/// Params:
	/// sPath = シナリオディレクトリのパス。
	/// xmls = シナリオの各XMLデータ。
	/// Throws:
	/// SummaryException = xmlsにSummary定義のXML文書が含まれていない、または壊れている。
	/// XmlException = XMLパースエラー発生時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	private static Summary fromXMLs(string sPath, string[string][string] xmls) {
		auto parent = "" in xmls;
		if (!parent) throw new SummaryException("invalid xmls");
		auto summXML = "Summary.xml" in *parent;
		if (!summXML) throw new SummaryException("invalid parent of xmls");
		Summary summ = summaryFromXML(sPath, *summXML);

		__loadXML2(xmls, PATH_AREA, "Area", summ._area, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		summ.checkStartArea;
		__loadXML2(xmls, PATH_BATTLE, "Battle", summ._btl, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		__loadXML2(xmls, PATH_PACKAGE, "Package", summ._pkg, summ.useCounter, &summ.changeHandler, summ.dataVersion);

		__loadXML2(xmls, PATH_CAST, "CastCard", summ._cast, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		__loadXML2(xmls, PATH_SKILL, "SkillCard", summ._skl, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		__loadXML2(xmls, PATH_ITEM, "ItemCard", summ._itm, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		__loadXML2(xmls, PATH_BEAST, "BeastCard", summ._bst, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		__loadXML2(xmls, PATH_INFO, "InfoCard", summ._info, summ.useCounter, &summ.changeHandler, summ.dataVersion);

		return summ;
	}
	private static void fromXMLs(Summary summ) {
		auto path = summ.scenarioPath;
		__loadXML1(std.path.join(path, PATH_AREA), "Area", summ._area, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		summ.checkStartArea;
		__loadXML1(std.path.join(path, PATH_BATTLE), "Battle", summ._btl, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		__loadXML1(std.path.join(path, PATH_PACKAGE), "Package", summ._pkg, summ.useCounter, &summ.changeHandler, summ.dataVersion);

		__loadXML1(std.path.join(path, PATH_CAST), "CastCard", summ._cast, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		__loadXML1(std.path.join(path, PATH_SKILL), "SkillCard", summ._skl, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		__loadXML1(std.path.join(path, PATH_ITEM), "ItemCard", summ._itm, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		__loadXML1(std.path.join(path, PATH_BEAST), "BeastCard", summ._bst, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		__loadXML1(std.path.join(path, PATH_INFO), "InfoCard", summ._info, summ.useCounter, &summ.changeHandler, summ.dataVersion);
	}

	/// XMLを元にしたインスタンスを返す。
	/// Params:
	/// path = Summary.xmlのパス。
	/// Throws:
	/// SummaryException = ファイルはSummary定義のXML文書ではない。
	/// IOException = ファイル読込み例外発生時。
	/// XmlException = XMLパースエラー発生時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	/// FileLoadException = Summary.xml以外での読込例外発生時。
	private static Summary fromXMLs(string path) {
		auto summ = summaryFromXML(getDirName(path), cast(string) std.file.read(path));
		fromXMLs(summ);
		return summ;
	}

	/// XMLファイルを再読込し、新しいSummaryを生成して返す。
	Summary reloadXMLs() {
		auto summ = summaryFromXML(scenarioPath,
			cast(string) std.file.read(std.path.join(scenarioPath, "Summary.xml")));
		summ._expandXMLs = expandXMLs;
		summ._zipName = zipName;
		summ._useTemp = useTemp;
		summ._legacy = legacy;
		fromXMLs(summ);
		if (useTemp) {
			summ._lock = _lock;
		}
		return summ;
	}

	/// フラグとステップのルートディレクトリ。
	FlagDir flagDirRoot() {
		return _froot;
	}

	mixin STemplate!(true, true, true, true, true);

	/// シナリオのディレクトリ。
	string scenarioPath() {
		return _sPath;
	}
	/// シナリオのディレクトリ。
	void scenarioPath(string sPath) {
		_sPath = sPath;
	}
	/// シナリオ名。
	string scenarioName() {
		return _sname;
	}
	/// シナリオ名。
	void scenarioName(string sname) {
		if (_sname != sname) changeHandler;
		_sname = sname;
	}

	/// カード画像のマップを生成して返す。
	private string[][byte[]] cardImgTable(string mtdir, Skin skin, UseCounter uc) {
		string[][byte[]] r;
		foreach (file; clistdir(mtdir)) {
			if (skin.isCardImage(std.path.join(mtdir, file))) {
				r[cast(byte[]) std.file.read(std.path.join(mtdir, file))] ~= std.path.join(skin.materialPath, file);
			}
		}
		foreach (ref v; r.values) {
			if (v.length > 1u) {
				string[] nv;
				foreach (file; v) {
					if (!cwx.utils.fnstartsWith(getBaseName(file), "font_")) {
						/// font_X.bmpはやむを得ずコピーした可能性があるため優先的に除外
						nv ~= file;
					}
				}
				v = nv;
			}
			if (v.length > 1u) {
				string[] nv;
				int maxCount = -1;
				foreach (file; v) {
					/// 使用回数が多い方を優先
					int c = cast(int) uc.path.values(toPathId(file)).length;
					if (c >= maxCount) {
						nv ~= file;
						maxCount = c;
					}
				}
				v = nv.length > 1u ? nv.sort : nv;
			}
		}
		return r;
	}
	private bool moveBinImg(ref string[][byte[]] cis, PathUser targ, string fname, string mt, Skin toSkin) {
		string img = targ.path;
		if (isBinImg(img)) {
			byte[] bytes = strToBImg(img);
			string[] *files = bytes in cis;
			if (files) {
				assert (files.length);
				targ.path = (*files)[0u];
			} else {
				auto file = createFileI(mt, fname, "bmp", "");
				std.file.write(file, bytes);
				targ.path = std.path.join(toSkin.materialPath, getBaseName(file));
				cis[bytes] ~= targ.path;
				return true;
			}
		}
		return false;
	}
	public string classicToX(CProps prop, string tempPath, Skin toSkin, out string[] copyFail) {
		copyFail = [];
		auto uc = useCounter;
		auto temp = Summary.createTempDir(tempPath, scenarioName);
		auto mt = std.path.join(temp, toSkin.materialPath);
		mkdir(mt);
		foreach (file; clistdir(scenarioPath)) {
			auto p = std.path.join(scenarioPath, file);
			try {
				if (isdir(p)) {
					copy(p, std.path.join(temp, getBaseName(p)));
				} else if (!fnmatch(getExt(p), "wsm") && !fnmatch(getExt(p), "wid")) {
					if (toSkin.isCardImage(p)
							|| toSkin.isBgImage(p)
							|| toSkin.isBGM(p)
							|| toSkin.isSE(p)) {
						copy(p, std.path.join(mt, getBaseName(p)));
						uc.change(toPathId(getBaseName(p)), toPathId(std.path.join(toSkin.materialPath, getBaseName(p))));
					} else {
						copy(p, std.path.join(temp, getBaseName(p)));
					}
				}
			} catch (Exception ex) {
				debugln(ex);
				copyFail ~= p;
			}
		}
		scope table = cardImgTable(mt, toSkin, uc);
		foreach (p; uc.path.keys) {
			if (p.isBinImg) {
				int i = 0;
				foreach (ipu; uc.path.values(p)) {
					auto v = cast(PathUser) ipu;
					assert (v);
					if (moveBinImg(table, v, "@simage(" ~ to!(string)(i + 1) ~ ")", mt, toSkin)) {
						i++;
					}
				}
			}
		}
		return temp;
	}
	/// 保存場所が決まっている場合はtrue。
	bool isSaved() {
		return !useTemp || zipName.length;
	}
	/// 上書き保存。
	void saveOverwrite(CProps prop) in {
		assert (isSaved);
	} body {
		saveProc(prop, false, zipName, scenarioPath, false, expandXMLs);
	}
	/// 名前をつけて保存。
	void saveWithName(CProps prop, string fname, string tempPath,
			bool defExpandXMLs, Skin defSkin, void delegate(string) showWarn) in {
		assert (fnmatch(getExt(fname), "wsn"));
	} body {
		if (legacy) {
			// クラシック形式からXML形式に変換
			string[] copyFail;
			auto temp = classicToX(prop, tempPath, defSkin, copyFail);
			foreach (fail; copyFail) {
				// 一部コピー失敗しても中断しない
				showWarn(prop.msgs.fileCopyError(fail));
			}
			scope (failure) delAll(temp);
			saveProc(prop, true, fname, temp, true, defExpandXMLs);
		} else if (useTemp) {
			// 新しいアーカイブを作成
			string oldZip = _zipName;
			_zipName = fname;
			scope (failure) _zipName = oldZip;
			saveProc(prop, false, zipName, scenarioPath, false, defExpandXMLs);
		} else {
			// 展開済みシナリオからアーカイブに変換
			auto oldPath = scenarioPath;
			auto p = createTempDir(tempPath, scenarioName);
			copyAll(oldPath, p);
			scenarioPath = p;
			scope (failure) {
				scenarioPath = oldPath;
				delAll(p);
			}
			saveProc(prop, true, fname, p, false, defExpandXMLs);
		}
	}
	private void saveProc(CProps prop, bool archive, string zipName, string temp,
			bool legacyToX, bool defExpandXMLs) {
		try {
			bool expand = false;
			if (legacy && !legacyToX) {
				saveLScenario(this);
			} else if (archive || useTemp || legacyToX) {
				auto oldPath = scenarioPath;
				if (expandXMLs) {
					saveXMLs;
					expand = true;
				} else if (legacyToX && defExpandXMLs) {
					scenarioPath = temp;
					scope (failure) scenarioPath = oldPath;
					saveXMLs;
					expand = true;
				}
				auto lock = std.path.join(scenarioPath, "cwxeditor.lock");
				scope arc = .zip(scenarioPath, false, [lock]);
				if (!expand) {
					foreach (path, files; toXMLs) {
						foreach (name, xml; files) {
							auto p = std.path.join(path, name);
							arc.addMember(.archive(p, cast(ubyte[]) xml, false));
						}
					}
				}
				std.file.write(zipName, arc.build);
			} else {
				assert (expandXMLs);
				saveXMLs;
			}
			dataVersion = LATEST_VERSION;
			resetChanged;
			if (legacyToX || (!useTemp && archive)) {
				toArchive(zipName, temp, expand);
			}
		} catch (Exception e) {
			debugln(e);
			throw new SummaryException(prop.msgs.saveError(scenarioName));
		}
	}
}

/// カードのみのシナリオデータ。
template CardContainer(bool UseCast, bool UseSkill, bool UseItem, bool UseBeast, bool UseInfo) {
	mixin ("class CardContainer : CWXPath"
		~ (UseCast ? ", CastOwner" : "")
		~ (UseCast ? ", SkillOwner" : "")
		~ (UseCast ? ", ItemOwner" : "")
		~ (UseCast ? ", BeastOwner" : "")
		~ (UseCast ? ", InfoOwner" : "")
		~ "{"
		~ "    mixin CardContainerImpl!(UseCast, UseSkill, UseItem, UseBeast, UseInfo);"
		~ "}");
}
private template CardContainerImpl(bool UseCast, bool UseSkill, bool UseItem, bool UseBeast, bool UseInfo) {
private:
	string _sPath;
	string _sname;
	string _id;
	string _type = "";
	bool _legacy;
public:
	mixin STemplate!(UseCast, UseSkill, UseItem, UseBeast, UseInfo);

	/// 唯一のコンストラクタ。
	this(string sPath, string sname, bool legacy) {
		_id = format("%08X", &this) ~ "-" ~ to!(string)(getUTCtime);
		_sPath = sPath;
		_sname = sname;
		_legacy = legacy;
	}
	override string cwxPath() {return "";}
	override CWXPath findCWXPath(string path) {
		if (path == "") return this;
		return findCWXPathImpl(path, cpcategory(path));
	}
	/// マシン上で一意なID。
	string id() {
		return _id;
	}
	/// クラシックな形式ならtrue。
	bool legacy() {return _legacy;}
	/// スキン。
	string type() {return _type;}

	/// シナリオのディレクトリ。
	string scenarioPath() {
		return _sPath;
	}
	/// シナリオ名。
	string scenarioName() {
		return _sname;
	}

	/// カードを追加する。
	static if (UseCast) void add(CastCard c) {_cast ~= c;}
	/// ditto
	static if (UseSkill) void add(SkillCard c) {_skl ~= c;}
	/// ditto
	static if (UseItem) void add(ItemCard c) {_itm ~= c;}
	/// ditto
	static if (UseBeast) void add(BeastCard c) {_bst ~= c;}
	/// ditto
	static if (UseInfo) void add(InfoCard c) {_info ~= c;}

	/// 指定された要素のindexを検索する。
	int indexOf(T)(T c) {
		static if (UseCast && is (T == CastCard)) {
			return .indexOf!("a is b")(_cast, c);
		} else static if (UseSkill && is (T == SkillCard)) {
			return .indexOf!("a is b")(_skl, c);
		} else static if (UseItem && is (T == ItemCard)) {
			return .indexOf!("a is b")(_itm, c);
		} else static if (UseBeast && is (T == BeastCard)) {
			return .indexOf!("a is b")(_bst, c);
		} else static if (UseInfo && is (T == InfoCard)) {
			return .indexOf!("a is b")(_info, c);
		} else {
			static assert (0);
		}
	}

	private static CardContainer fromNode(ref XNode summNode, string sPath, out string ver) {
		string sname = null;
		string type = "";
		ver = summNode.attr("dataVersion", false);
		if (!ver) ver = "";
		summNode.onTag["Property"] = (ref XNode node) {
			node.onTag["Name"] = (ref XNode node) {sname = node.value;};
			node.onTag["Type"] = (ref XNode node) {type = node.value;};
			node.parse;
		};
		summNode.parse;
		if (!sname) throw new SummaryException("Scenario name is not found: " ~ sPath);
		auto cc = new CardContainer(sPath, sname, false);
		cc._type = type;
		return cc;
	}

	/// XMLを元にしたインスタンス。
	/// Params:
	/// sPath = シナリオディレクトリのパス。
	/// xmls = シナリオの各XMLデータ。
	/// Throws:
	/// SummaryException = xmlsにSummary定義のXML文書が含まれていない、または壊れている。
	/// XmlException = XMLパースエラー発生時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static CardContainer fromXMLs(string sPath, string[string][string] xmls) {
		auto parent = "" in xmls;
		if (!parent) throw new SummaryException("invalid xmls");
		auto summXML = "Summary.xml" in *parent;
		if (!summXML) throw new SummaryException("invalid parent of xmls");
		scope summNode = XNode.parse(*summXML);
		if (summNode.name == "Summary") {
			string ver;
			auto cc = fromNode(summNode, sPath, ver);

			static if (UseCast) __loadXML2!(CastCard)(xmls, PATH_CAST, CastCard.XML_NAME, cc._cast, null, null, ver);
			static if (UseSkill) __loadXML2!(SkillCard)(xmls, PATH_SKILL, SkillCard.XML_NAME, cc._skl, null, null, ver);
			static if (UseItem) __loadXML2!(ItemCard)(xmls, PATH_ITEM, ItemCard.XML_NAME, cc._itm, null, null, ver);
			static if (UseBeast) __loadXML2!(BeastCard)(xmls, PATH_BEAST, BeastCard.XML_NAME, cc._bst, null,null, ver);
			static if (UseInfo) __loadXML2!(InfoCard)(xmls, PATH_INFO, InfoCard.XML_NAME, cc._info, null, null, ver);

			return cc;
		}
		throw new SummaryException("File is not summary");
	}

	/// XMLを元にしたインスタンス。
	/// Params:
	/// path = Summary.xmlのパス。
	/// Throws:
	/// SummaryException = ファイルはSummary定義のXML文書ではない。
	/// IOException = ファイル読込み例外発生時。
	/// XmlException = XMLパースエラー発生時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	/// FileLoadException = Summary.xml以外での読込例外発生時。
	static CardContainer fromXMLs(string path) {
		scope summNode = XNode.parse(cast(string) std.file.read(path));
		if (summNode.name == "Summary") {
			string par = getDirName(path);
			string ver;
			auto cc = fromNode(summNode, par, ver);

			static if (UseCast) __loadXML1!(CastCard)(std.path.join(par, PATH_CAST), CastCard.XML_NAME, cc._cast, null, null, ver);
			static if (UseSkill) __loadXML1!(SkillCard)(std.path.join(par, PATH_SKILL), SkillCard.XML_NAME, cc._skl, null, null, ver);
			static if (UseItem) __loadXML1!(ItemCard)(std.path.join(par, PATH_ITEM), ItemCard.XML_NAME, cc._itm, null, null, ver);
			static if (UseBeast) __loadXML1!(BeastCard)(std.path.join(par, PATH_BEAST), BeastCard.XML_NAME, cc._bst, null,null, ver);
			static if (UseInfo) __loadXML1!(InfoCard)(std.path.join(par, PATH_INFO), InfoCard.XML_NAME, cc._info, null, null, ver);

			return cc;
		}
		throw new SummaryException("File is not summary: " ~ path);
	}
}
alias CardContainer!(true, true, true, true, true) Importable;
alias CardContainer!(false, true, true, true, false) HandCards;
unittest {
	new Importable("", "", false);
	new HandCards("", "", false);
}

/// ファイル読み込み時の例外。
public class FileLoadException : Exception {
private:
	string _path;
	Exception _e;
public:
	/// 読み込み対象のパスと発生した例外からインスタンスを生成。
	this(string path, Exception e) {
		super(e.msg);
		_path = path;
		_e = e;
	}
	/// 読み込み対象パス。
	string path() {
		return _path;
	}
	/// 例外。
	Exception e() {
		return _e;
	}
}

/// シナリオのシステムディレクトリ
/// (Area, Battle, Package, CastCard, SkillCard, ItemCard, BeastCard, InfoCard)
/// であればtrueを返す。
bool isScenarioSystemDir(string dir) {
	return std.path.fnmatch(dir, PATH_AREA)
		|| std.path.fnmatch(dir, PATH_PACKAGE)
		|| std.path.fnmatch(dir, PATH_BATTLE)
		|| std.path.fnmatch(dir, PATH_CAST)
		|| std.path.fnmatch(dir, PATH_SKILL)
		|| std.path.fnmatch(dir, PATH_ITEM)
		|| std.path.fnmatch(dir, PATH_BEAST)
		|| std.path.fnmatch(dir, PATH_INFO);
}
