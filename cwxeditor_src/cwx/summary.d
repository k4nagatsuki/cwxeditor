
module cwx.summary;

import std.array;
import std.file;
import std.stream;
import std.path;
import std.zip;
import std.datetime;
import std.string;
import std.utf;
import std.traits;
import std.exception;

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
import cwx.cab;
import cwx.sjis;
import cwx.event;

public:

/// 貼り紙関連の例外。
class SummaryException : Exception {
public:
	this (string msg) {
		super (msg);
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
		void loadXMLCommon(A)(string xml, string name, ref A[] areas,
				UseCounter uc, void delegate() change, string ver) {
			auto doc = XNode.parse(xml);
			if (doc.name == name) {
				auto area = A.createFromNode(doc, ver);
				if (uc) area.setUseCounter = uc;
				if (change) area.changeHandler = change;
				area.owner = this;
				areas ~= area;
			}
		}
		void loadXML1(A)(string targPath, string name, ref A[] areas,
				UseCounter uc, void delegate() change, string ver) {
			if (exists(targPath)) {
				foreach (p; clistdir(targPath)) {
					p = std.path.buildPath(targPath, p);
					if (!isDir(p) && cfnmatch(cwx.utils.getExt(p), "xml")) {
						try {
							loadXMLCommon(std.file.readText(p), name, areas, uc, change, ver);
						} catch (Exception e) {
							throw new FileLoadException(p, e);
						}
					}
				}
				// ID順でソート。
				areas.sort;
			}
		}
		void loadXML2(A)(string[string][string] xmls,
				string dirName, string name, ref A[] areas,
				UseCounter uc, void delegate() change, string ver) {
			auto dir = dirName in xmls;
			if (!dir) return;
			foreach (file, xml; *dir) {
				try {
					loadXMLCommon(xml, name, areas, uc, change, ver);
				} catch (Exception e) {
					throw new Exception(std.path.buildPath(dirName, file));
				}
			}
			// ID順でソート。
			areas.sort;
		}
		static C find(C)(C[] arr, ulong id) {
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
			@property
			CastCard[] casts() {
				return _cast;
			}
			/// ditto
			CastCard cwCast(ulong id) {
				return find(_cast, id);
			}
			/// ditto
			const
			const(CastCard) cwCast(ulong id) {
				return find(_cast, id);
			}
		}
		static if (UseSkill) {
			/// スキル。
			@property
			SkillCard[] skills() {
				return _skl;
			}
			/// ditto
			SkillCard skill(ulong id) {
				return find(_skl, id);
			}
			/// ditto
			const
			const(SkillCard) skill(ulong id) {
				return find(_skl, id);
			}
		}
		static if (UseItem) {
			/// アイテム。
			@property
			ItemCard[] items() {
				return _itm;
			}
			/// ditto
			ItemCard item(ulong id) {
				return find(_itm, id);
			}
			/// ditto
			const
			const(ItemCard) item(ulong id) {
				return find(_itm, id);
			}
		}
		static if (UseBeast) {
			/// 召喚獣。
			@property
			BeastCard[] beasts() {
				return _bst;
			}
			/// ditto
			BeastCard beast(ulong id) {
				return find(_bst, id);
			}
			const
			const(BeastCard) beast(ulong id) {
				return find(_bst, id);
			}
		}
		static if (UseInfo) {
			/// 情報カード。
			@property
			InfoCard[] infos() {
				return _info;
			}
			/// ditto
			InfoCard info(ulong id) {
				return find(_info, id);
			}
			/// ditto
			const
			const(InfoCard) info(ulong id) {
				return find(_info, id);
			}
		}
	}

	// 以降は圧縮シナリオ・一時展開関係のAPI。
	private bool _expandXMLs;
	private bool _useTemp = true;
	private File _lock = null;
	private string _zipName = "";
	private string _tempPath = "";
	private bool _legacy = false;

	/// XMLファイルを展開しているか。
	@property
	const
	bool expandXMLs() {return _expandXMLs;}
	/// 現在のscenarioPathは一時展開先か。
	@property
	const
	bool useTemp() {return _useTemp;}
	/// 元の圧縮ファイル名は何か。圧縮されていないシナリオの場合は""。
	@property
	const
	string zipName() {return _zipName;}
	/// ditto
	@property
	void zipName(string zipName) {_zipName = zipName;}
	/// クラシックな形式のシナリオか。
	@property
	const
	bool legacy() {return _legacy;}

	alias typeof(this) S;

	static string createTempDir(string tempPath, string name, bool createLockFile = true) {
		string base = cwx.utils.toHex(name);
		base = base.length > 15 ? base[0 .. 15] : base;
		base = "cwxeditor_temp_" ~ base;
		auto temp = createNewFileName(std.path.buildPath(tempPath, base), true);
		mkdirRecurse(temp);
		if (createLockFile) typeof(this).createLockFile(temp);
		return temp;
	}
	static void createLockFile(string temp) {
		std.file.write(std.path.buildPath(temp, "cwxeditor.lock"), []);
	}

	static Summary createScenario(string tempPath, string name, Skin skin) {
		auto p = Summary.createTempDir(tempPath, name);
		auto mFPath = std.path.buildPath(p, skin.materialPath);
		if (!exists(mFPath) || !isDir(mFPath)) std.file.mkdir(mFPath);
		auto summ = new Summary(name, skin.type, p, true, false);
		if (summ.expandXMLs) {
			summ.saveXMLs(summ.scenarioPath);
		}
		return summ;
	}

	static S loadScenarioFromFile(in CProps prop, bool doubleIO, string fname, bool expand, string tempPath,
			string delegate() createClassicDir = null,
			S old = null, void delegate(uint) setMax = null, void delegate(uint) worked = null, string newName = null) {
		string[string][string] xmls;
		bool scTemplate = createClassicDir !is null;
		string sunzip(string fname, ZipArchive arc, out bool cancel = false) {
			auto temp = createTempDir(tempPath, baseName(stripExtension(fname)));
			if (expand) {
				.unzip(temp, arc, setMax, worked);
			} else {
				.unzip(arc, (string path, ubyte[] data, bool isDir) {
					if (!isDir) {
						if (cfnmatch(path, "Summary.xml")) {
							xmls[""][path] = cast(string) data;
						} else if (cfnmatch(cwx.utils.getExt(path), "xml") && isScenarioSystemDir(dirName(path))) {
							xmls[dirName(path)][baseName(path)] = cast(string) data;
						} else {
							path = std.path.buildPath(temp, path);
							string parent = dirName(path);
							if (!exists(parent)) mkdirRecurse(parent);
							std.file.write(path, data);
						}
					} else if (!isScenarioSystemDir(path)) {
						path = std.path.buildPath(temp, path);
						if (!exists(path)) mkdirRecurse(path);
					}
				}, setMax, worked);
			}
			return temp;
		}
		ZipArchive scArc(string fname, string ext) {
			auto arc = new ZipArchive(std.file.read(fname));
			foreach (am; arc.directory) {
				string name;
				try {
					.validate(am.name);
					name = am.name;
				} catch {
					name = touni(am.name);
				}
				name = replace(name, "/", sep);
				if (cfnmatch(baseName(name), setExtension("Summary", ext))) {
					return arc;
				}
			}
			return null;
		}
		string suncab(string fname, out string summPath) {
			string temp;
			if (cfnmatch(cwx.utils.getExt(fname), "cab")) {
				temp = createTempDir(tempPath, baseName(stripExtension(fname)), false);
				if (!.uncab(fname, temp)) {
					delAll(temp);
					return null;
				}
			} else {
				// zipと仮定
				auto arc = scArc(fname, "wsm");
				if (!arc) return null;
				temp = createTempDir(tempPath, baseName(stripExtension(fname)), false);
				try {
					.unzip(temp, arc);
				} catch {
					delAll(temp);
					return null;
				}
			}
			summPath = temp;
			auto ld = clistdir(temp);
			if (ld.length == 1 && isDir(std.path.buildPath(temp, ld[0]))) {
				// ディレクトリを一つ挟んでいる
				summPath = std.path.buildPath(temp, ld[0]);
			}
			if (!.exists(std.path.buildPath(summPath, "Summary.wsm"))) {
				delAll(temp);
				return null;
			}
			if (!scTemplate) {
				createLockFile(temp);
			}
			return temp;
		}
		S load(string p) {
			S r;
			if (expand) {
				r = S.fromXMLs(std.path.buildPath(p, "Summary.xml"));
			} else {
				r = S.fromXMLs(p, xmls);
				static if (is(S : Summary)) {
					r._oldXMLs = xmls;
				}
			}
			return r;
		}
		S loadLegacy(string p) {
			S r = loadLScenario!(S)(p, "", doubleIO, newName);
			return r;
		}
		S createFromTemplate(S r) {
			// テンプレートからの生成
			string scDir = createClassicDir();
			if (scDir) {
				copyAll(r.scenarioPath, scDir);
				if (r.useTemp) {
					r._useTemp = false;
					delAll(r.scenarioPath);
				}
				r._sPath = scDir;
				r._zipName = "";
				r._tempPath = scDir;
				return r;
			}
			return null;
		}
		S legacyCommon() {
			string summPath;
			string fn = suncab(fname, summPath);
			if (fn) {
				try {
					S r = loadLegacy(summPath);
					r._expandXMLs = false;
					r._useTemp = true;
					r._legacy = true;
					r._zipName = fname;
					r._tempPath = fn;
					if (scTemplate) {
						return createFromTemplate(r);
					} else {
						r.lock();
						return r;
					}
				} catch (Exception e) {
					delAll(fn);
					throw e;
				}
			}
			throw new SummaryException(.tryFormat(prop.msgs.notScenario, fname));
		}
		if (fname) {
			if (newName || exists(fname)) {
				try {
					if (isDir(fname)) {
						if (exists(std.path.buildPath(fname, "Summary.xml"))) {
							fname = std.path.buildPath(fname, "Summary.xml");
						} else if (exists(std.path.buildPath(fname, "Summary.wsm"))) {
							fname = std.path.buildPath(fname, "Summary.wsm");
						}
					}
					S ll(string fname) {
						auto r = loadLegacy(fname);
						r._expandXMLs = false;
						r._useTemp = false;
						r._legacy = true;
						r._zipName = "";
						if (scTemplate) {
							return createFromTemplate(r);
						} else {
							return r;
						}
					}
					if (cfnmatch(baseName(fname), "Summary.wsm")) {
						return ll(dirName(fname));
 					} else if (canUncab && cfnmatch(cwx.utils.getExt(fname), "cab")) {
 						return legacyCommon();
					} else if (cfnmatch(baseName(fname), "Summary.xml")) {
						expand = true;
						auto r = load(dirName(fname));
						r._expandXMLs = true;
						r._useTemp = false;
						r._legacy = false;
						r._zipName = "";
						if (scTemplate) {
							auto temp = createTempDir(tempPath, r.scenarioName);
							copyAll(r.scenarioPath, temp);
							r._tempPath = temp;
							r._useTemp = true;
							r.lock();
						}
						return r;
					} else if (isDir(fname)) {
						return ll(fname);
					} else {
						auto arc = scArc(fname, "xml");
						if (arc) {
							bool cancel;
							string zipname = fname;
							fname = sunzip(baseName(fname), arc, cancel);
							if (fname.length) {
								try {
									S r = load(fname);
									r._expandXMLs = expand;
									r._useTemp = true;
									r._zipName = zipname;
									r._tempPath = fname;
									r._legacy = false;
									r.lock();
									if (scTemplate) {
										r._zipName = "";
									}
									return r;
								} catch (Exception e) {
									delAll(fname);
									throw e;
								}
							} else if (cancel) {
								delAll(dirName(fname));
								return null;
							}
						} else {
							return legacyCommon();
						}
					}
				} catch (ZipException e) {
					debugln(e);
					throw new SummaryException(.tryFormat(prop.msgs.zipError, fname));
				} catch (FileLoadException e) {
					debugln(e);
					throw new SummaryException(.tryFormat(prop.msgs.loadError, e.path));
				} catch (Exception e) {
					debugln(e);
					throw new SummaryException(.tryFormat(prop.msgs.loadError, fname));
				}
			} else {
				throw new SummaryException(.tryFormat(prop.msgs.loadError, fname));
			}
		}
		return null;
	}
	private void lock() {
		assert (!_lock);
		if (useTemp) {
			_lock = new File(std.path.buildPath(_tempPath, "cwxeditor.lock"), FileMode.OutNew);
		}
	}
	/// 一時展開先を削除する。
	void delTemp() {
		if (useTemp) {
			_lock.close();
			_lock = null;
			try {
				delAll(_tempPath.length ? _tempPath : scenarioPath, true);
				_useTemp = false;
				_zipName = null;
				_tempPath = "";
			} catch (Exception e) {
				debugln(e);
				std.file.write(std.path.buildPath(_tempPath, "cwxeditor.lock"), []);
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
				auto card = cwCast(cpindex(path));
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
	@property
	private CWXPath[] cwxChildsImpl() {
		CWXPath[] r;
		static if (UseCast) r ~= cast(CWXPath[]) casts;
		static if (UseSkill) r ~= cast(CWXPath[]) skills;
		static if (UseItem) r ~= cast(CWXPath[]) items;
		static if (UseBeast) r ~= cast(CWXPath[]) beasts;
		static if (UseInfo) r ~= cast(CWXPath[]) infos;
		return r;
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
	/// Aに対応する配列。
	template CArray(A) {
		static if (is(A : Area)) {
			alias _area CArray;
		} else static if (is(A : Battle)) {
			alias _btl CArray;
		} else static if (is(A : Package)) {
			alias _pkg CArray;
		} else static if (is(A : CastCard)) {
			alias _cast CArray;
		} else static if (is(A : SkillCard)) {
			alias _skl CArray;
		} else static if (is(A : ItemCard)) {
			alias _itm CArray;
		} else static if (is(A : BeastCard)) {
			alias _bst CArray;
		} else static if (is(A : InfoCard)) {
			alias _info CArray;
		} else static assert (0);
	}

	UseCounter _uc;
	bool _change = false;

	void changeHandler() {
		if (!_change) {
			_change = true;
			foreach (dlg; changedEvent) {
				dlg();
			}
		}
		foreach (dlg; changedEventForce) {
			dlg();
		}
	}

	this (string sPath) {
		_sPath = sPath;
		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime());
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
	this (string sname, string type, string sPath, bool temp, bool legacy) {
		this(sPath);
		_type = type;
		_sname = sname;
		_legacy = legacy;
		_useTemp = temp;
		if (_useTemp) {
			_tempPath = _sPath;
			lock();
		}
	}

	/// シナリオに変更があった際に発生するイベントのハンドラ。
	/// すでに変更済みであった場合は通知されない。
	void delegate()[] changedEvent;
	/// シナリオに変更があった際に発生するイベントのハンドラ。
	/// すでに変更済みであっても通知される。
	void delegate()[] changedEventForce;

	@property
	override string cwxPath() {return "";}
	override CWXPath findCWXPath(string path) {
		if (cpempty(path)) return this;
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
			auto area = cwPackage(cpindex(path));
			return area ? area.findCWXPath(cpbottom(path)) : null;
		}
		case "variable": {
			return flagDirRoot.findCWXPath(cpbottom(path));
		}
		default: break;
		}
		return findCWXPathImpl(path, cate);
	}
	@property
	override CWXPath[] cwxChilds() {
		CWXPath[] r;
		r ~= cast(CWXPath[]) areas;
		r ~= cast(CWXPath[]) battles;
		r ~= cast(CWXPath[]) packages;
		r ~= cwxChildsImpl;
		r ~= flagDirRoot;
		return r;
	}
	@property
	CWXPath cwxParent() {return null;}

	/// マシン上で一意なID。
	@property
	const
	string id() {
		return _id;
	}
	/// このシナリオが変更済みであればtrueを返す。
	@property
	const
	bool isChanged() {
		return _change;
	}
	/// 変更状態をリセットする。
	void resetChanged() {
		_change = false;
	}
	/// 変更を通知する。
	void changed() {
		changeHandler();
	}
	/// このシナリオが持つ使用回数カウンタ。
	@property
	UseCounter useCounter() {
		return _uc;
	}

	/// シナリオのシステムファイルまたはディレクトリであればtrueを返す。
	const
	bool isSystemFile(string p) {
		return isSystemFile(p, cast(bool) .isDir(p));
	}
	const
	bool isSystemFile(string p, bool isdir) {
		if (!isdir && useTemp && .cfnmatch(baseName(p), "cwxeditor.lock")) {
			return true;
		}
		if (legacy) {
			if (isdir) return false;
			auto ext = cwx.utils.getExt(p);
			return .cfnmatch(ext, "wid") || .cfnmatch(ext, "wsm");
		} else {
			string fl = baseName(p);
			if (isdir) {
				return isScenarioSystemDir(fl);
			} else {
				return cast(bool) .cfnmatch(fl, "Summary.xml");
			}
		}
		return false;
	}

	/// 圧縮して保存した事を通知する。
	private void toArchive(string zipName, string scenarioPath, bool expandXMLs) {
		_expandXMLs = expandXMLs;
		_useTemp = true;
		_zipName = zipName;
		_legacy = false;
		this.scenarioPath = scenarioPath;
		_tempPath = scenarioPath;
		lock();
	}

	/// データバージョン。
	@property
	const
	string dataVersion() {return _dataVersion;}
	@property
	/// ditto
	private void dataVersion(string ver) {_dataVersion = ver;}

	private void setNamesOne(C : EffectCard)(ref C card, string newAuthor, string newScenario) {
		if (card.scenario == scenarioName && card.author == author) {
			card.author = newAuthor;
			card.scenario = newScenario;
		}
	}
	private void setNames(C)(C[] cards, string newAuthor, string newScenario) {
		foreach (ref card; cards) {
			setNamesOne(card, newAuthor, newScenario);
		}
		setContentNames(cards, newAuthor, newScenario);
	}
	private void setContentNames(C : EventTreeOwner)(C[] etos, string newAuthor, string newScenario) {
		void setContentNames(Content c) {
			foreach (m; c.motions) {
				auto beast = m.beast;
				if (beast) {
					setNamesOne(beast, newAuthor, newScenario);
				}
			}
			foreach (n; c.next) setContentNames(n);
		}
		foreach (ref eto; etos) {
			foreach (ref tree; eto.trees) {
				foreach (ref start; tree.starts) {
					setContentNames(start);
				}
			}
		}
	}
	/// シナリオ名と作者名を設定する。
	void setBaseParams(string newScenarioName, string newAuthor) {
		setNames(skills, newAuthor, newScenarioName);
		setNames(items, newAuthor, newScenarioName);
		setNames(beasts, newAuthor, newScenarioName);
		foreach (card; casts) {
			setNames(card.skills, newAuthor, newScenarioName);
			setNames(card.items, newAuthor, newScenarioName);
			setNames(card.beasts, newAuthor, newScenarioName);
		}
		setContentNames(areas, newAuthor, newScenarioName);
		foreach (area; areas) setContentNames(area.cards, newAuthor, newScenarioName);
		setContentNames(battles, newAuthor, newScenarioName);
		foreach (area; battles) setContentNames(area.cards, newAuthor, newScenarioName);
		setContentNames(packages, newAuthor, newScenarioName);

		_sname = newScenarioName;
		_author = newAuthor;
	}

	/// シナリオの作者名。
	@property
	const
	string author() {
		return _author;
	}
	/// ditto
	@property
	void author(string author) {
		setBaseParams(scenarioName, author);
	}

	/// シナリオのタイプ。スキンを決定する。
	@property
	const
	string type() {
		return _type;
	}
	/// ditto
	@property
	void type(string type) {
		if (_type != type) changeHandler();
		_type = type;
	}

	/// 貼り紙の画像パス。
	@property
	void imagePath(string imgPath) {
		if (_imgPath.path != imgPath) changeHandler();
		_imgPath.path = imgPath;
	}
	/// ditto
	@property
	const
	string imagePath() {
		return _imgPath.path;
	}

	/// シナリオの解説。
	@property
	void desc(string desc) {
		if (_desc != desc) changeHandler();
		_desc = desc;
	}
	/// ditto
	@property
	const
	string desc() {
		return _desc;
	}

	/// 推奨レベル(低)
	@property
	void levelMin(uint levMin) {
		if (_levMin != levMin) changeHandler();
		_levMin = levMin;
	}
	/// ditto
	@property
	const
	uint levelMin() {
		return _levMin;
	}

	/// 推奨レベル(高)
	@property
	void levelMax(uint levMax) {
		if (_levMax != levMax) changeHandler();
		_levMax = levMax;
	}
	/// ditto
	@property
	const
	uint levelMax() {
		return _levMax;
	}

	/// 開始条件クーポンの必要数。
	@property
	void rCouponNum(uint rCouponNum) {
		if (_rCouponNum != rCouponNum) changeHandler();
		_rCouponNum = rCouponNum;
	}
	/// ditto
	@property
	const
	uint rCouponNum() {
		return _rCouponNum;
	}

	/// 開始条件クーポンの一覧。
	@property
	void rCoupons(string[] rCoupons) {
		if (_rCoupons != rCoupons) changeHandler();
		_rCoupons = rCoupons;
	}
	/// ditto
	@property
	string[] rCoupons() {
		return _rCoupons;
	}

	/// シナリオの開始エリア。
	@property
	void startArea(ulong startAreaId) {
		if (_startAreaId.area != startAreaId) changeHandler();
		_startAreaId.area = startAreaId;
	}
	/// ditto
	@property
	const
	ulong startArea() {
		return _startAreaId.area;
	}

	/// シナリオに含まれるエリア。
	@property
	Area[] areas() {
		return _area;
	}
	/// シナリオに含まれるパッケージ。
	@property
	Package[] packages() {
		return _pkg;
	}
	/// シナリオに含まれるバトル。
	@property
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
	const
	int indexOf(T)(in T c) {
		static if (is (T == CastCard)) {
			return .cCountUntil!("a is b")(_cast, c);
		} else static if (is (T == SkillCard)) {
			return .cCountUntil!("a is b")(_skl, c);
		} else static if (is (T == ItemCard)) {
			return .cCountUntil!("a is b")(_itm, c);
		} else static if (is (T == BeastCard)) {
			return .cCountUntil!("a is b")(_bst, c);
		} else static if (is (T == InfoCard)) {
			return .cCountUntil!("a is b")(_info, c);
		} else static if (is (T == Area)) {
			return .cCountUntil!("a is b")(_area, c);
		} else static if (is (T == Battle)) {
			return .cCountUntil!("a is b")(_btl, c);
		} else static if (is (T == Package)) {
			return .cCountUntil!("a is b")(_pkg, c);
		} else {
			static assert (0);
		}
	}

	/// エリア。
	Area area(ulong id) {
		return find(_area, id);
	}
	const
	const(Area) area(ulong id) {
		return find(_area, id);
	}
	/// バトル。
	Battle battle(ulong id) {
		return find(_btl, id);
	}
	const
	const(Battle) battle(ulong id) {
		return find(_btl, id);
	}
	/// パッケージ。
	Package cwPackage(ulong id) {
		return find(_pkg, id);
	}
	const
	const(Package) cwPackage(ulong id) {
		return find(_pkg, id);
	}

	/// 指定されたIDのエリア・バトル・パッケージがあればtrue。
	const
	bool hasAreaId(ulong id) {
		return hasId(_area, id);
	}
	/// ditto
	const
	bool hasBattleId(ulong id) {
		return hasId(_btl, id);
	}
	/// ditto
	const
	bool hasPackageId(ulong id) {
		return hasId(_pkg, id);
	}

	/// 指定された召喚獣カードと同等の性能を持つ召喚獣カードを探して返す。
	/// 見つからなければnullを返す。
	const
	const(BeastCard) findSomeBeast(in BeastCard beast) {
		string a = beast.toXML(1UL);
		foreach (b; _bst) {
			if (a == b.toXML(1UL)) return b;
		}
		return null;
	}

	/// 今現在このシナリオに含まれていないTのIDを生成して返す。
	@property
	const
	ulong newId(T)() {
		static if (is (T == CastCard)) {
			return newIdImpl(_cast);
		} else static if (is (T == SkillCard)) {
			return newIdImpl(_skl);
		} else static if (is (T == ItemCard)) {
			return newIdImpl(_itm);
		} else static if (is (T == BeastCard)) {
			return newIdImpl(_bst);
		} else static if (is (T == InfoCard)) {
			return newIdImpl(_info);
		} else static if (is (T == Area)) {
			return newIdImpl(_area);
		} else static if (is (T == Battle)) {
			return newIdImpl(_btl);
		} else static if (is (T == Package)) {
			return newIdImpl(_pkg);
		} else {
			static assert (0);
		}
	}
	/// ditto
	@property
	const
	ulong newAreaId() {
		return newIdImpl(_area);
	}
	/// ditto
	@property
	const
	ulong newBattleId() {
		return newIdImpl(_btl);
	}
	/// ditto
	@property
	const
	ulong newPackageId() {
		return newIdImpl(_pkg);
	}
	private static ulong newIdImpl(T)(T[] arr) {
		return arr.length > 0 ? arr[$ - 1].id + 1 : 1;
	}

	private ulong insertImpl(T, alias ToID)(ref T[] arr, int index, T c) {
		if (arr.length == index) {
			return addImpl!(T, ToID)(arr, c, true);
		} else {
			ulong tempId = 0;
			bool remv = false;
			foreach (i, c_; arr) {
				if (c_ is c) {
					if (i == index) return c.id;
					remv = true;
					tempId = arr[$ - 1].id + 2L;
					_uc.change(ToID(c.id), ToID(tempId));
					removeImpl(arr, c);
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
			changeHandler();
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
		return insertImpl!(CastCard, toCastId)(_cast, index, c);
	}
	/// ditto
	ulong insert(int index, SkillCard c) {
		return insertImpl!(SkillCard, toSkillId)(_skl, index, c);
	}
	/// ditto
	ulong insert(int index, ItemCard c) {
		return insertImpl!(ItemCard, toItemId)(_itm, index, c);
	}
	/// ditto
	ulong insert(int index, BeastCard c) {
		return insertImpl!(BeastCard, toBeastId)(_bst, index, c);
	}
	/// ditto
	ulong insert(int index, InfoCard c) {
		return insertImpl!(InfoCard, toInfoId)(_info, index, c);
	}
	/// ditto
	ulong insert(int index, Area c) {
		return insertImpl!(Area, toAreaId)(_area, index, c);
	}
	/// ditto
	ulong insert(int index, Battle c) {
		return insertImpl!(Battle, toBattleId)(_btl, index, c);
	}
	/// ditto
	ulong insert(int index, Package c) {
		return insertImpl!(Package, toPackageId)(_pkg, index, c);
	}

	private ulong addImpl(T, alias ToID)(ref T[] arr, T area, bool forceNewId) {
		if (arr.length > 0 && arr[$ - 1] is area) return area.id;
		auto oldId = area.id;
		if (forceNewId || (arr.length > 0 && arr[$ - 1].id >= area.id) ) {
			area.id = newIdImpl(arr);
		}
		foreach (i, c_; arr) {
			if (c_ is area) {
				removeImpl(arr, area);
				_uc.change(ToID(oldId), ToID(area.id));
				break;
			}
		}
		arr ~= area;
		area.setUseCounter = _uc;
		area.changeHandler = &changeHandler;
		area.owner = this;
		changeHandler();
		return oldId;
	}

	/// このシナリオにカード・エリア等を追加する。
	ulong add(Area area, bool forceNewId = true) {
		auto id = addImpl!(Area, toAreaId)(_area, area, forceNewId);
		if (areas.length == 1) {
			startArea = id;
		}
		return id;
	}
	/// ditto
	ulong add(Battle btl, bool forceNewId = true) {
		return addImpl!(Battle, toBattleId)(_btl, btl, forceNewId);
	}
	/// ditto
	ulong add(Package pkg, bool forceNewId = true) {
		return addImpl!(Package, toPackageId)(_pkg, pkg, forceNewId);
	}
	/// ditto
	ulong add(CastCard c, bool forceNewId = true) {
		return addImpl!(CastCard, toCastId)(_cast, c, forceNewId);
	}
	/// ditto
	ulong add(SkillCard c, bool forceNewId = true) {
		return addImpl!(SkillCard, toSkillId)(_skl, c, forceNewId);
	}
	/// ditto
	ulong add(ItemCard c, bool forceNewId = true) {
		return addImpl!(ItemCard, toItemId)(_itm, c, forceNewId);
	}
	/// ditto
	ulong add(BeastCard c, bool forceNewId = true) {
		return addImpl!(BeastCard, toBeastId)(_bst, c, forceNewId);
	}
	/// ditto
	ulong add(InfoCard c, bool forceNewId = true) {
		return addImpl!(InfoCard, toInfoId)(_info, c, forceNewId);
	}

	private void removeImpl(T)(ref T[] arr, T area) {
		foreach (i, a; arr) {
			if (a.id == area.id) {
				arr = arr[0 .. i] ~ arr[i + 1 .. $];
				area.removeUseCounter();
				area.changeHandler = null;
				area.owner = null;
				changeHandler();
				return;
			}
		}
	}

	/// カード・エリア等を除去する。
	void remove(CastCard c) {
		removeImpl(_cast, c);
	}
	/// ditto
	void remove(SkillCard c) {
		removeImpl(_skl, c);
	}
	/// ditto
	void remove(ItemCard c) {
		removeImpl(_itm, c);
	}
	/// ditto
	void remove(BeastCard c) {
		removeImpl(_bst, c);
	}
	/// ditto
	void remove(InfoCard c) {
		removeImpl(_info, c);
	}
	/// ditto
	void remove(Area a) {
		removeImpl(_area, a);
		if (a.id == startArea) {
			startArea = areas.length > 0 ? areas[0].id : 0;
		}
	}
	/// ditto
	void remove(Battle a) {
		removeImpl(_btl, a);
	}
	/// ditto
	void remove(Package a) {
		removeImpl(_pkg, a);
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

	/// index1とindex2を交換する。
	void swap(A)(int index1, int index2) {
		if (index1 == index2) return;
		enforce(0 <= index1 && index1 < CArray!A.length);
		enforce(0 <= index2 && index2 < CArray!A.length);

		ulong id1 = CArray!A[index1].id;
		ulong id2 = CArray!A[index2].id;
		std.algorithm.swap(CArray!A[index1], CArray!A[index2]);

		// ID置換
		CArray!A[index1].id = id1;
		CArray!A[index2].id = id2;
		_uc.change(A.toID(id1), A.toID(ulong.max));
		_uc.change(A.toID(id2), A.toID(id1));
		_uc.change(A.toID(ulong.max), A.toID(id2));

		changeHandler();
	}
	/// ditto
	alias swap!CastCard swapCast;
	/// ditto
	alias swap!SkillCard swapSkill;
	/// ditto
	alias swap!ItemCard swapItem;
	/// ditto
	alias swap!BeastCard swapBeast;
	/// ditto
	alias swap!InfoCard swapInfo;

	const
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
	const
	string[string][string] toXMLs() {
		string e = "";
		string[string] s = ["Summary.xml":summaryToXML()];
		string[string][string] r = [e:s];

		void put(string parent, string[string] p) {
			if (p.length) {
				r[parent] = p;
			}
		}
		put(PATH_AREA, toXMLsImpl(_area));
		put(PATH_BATTLE, toXMLsImpl(_btl));
		put(PATH_PACKAGE, toXMLsImpl(_pkg));

		put(PATH_CAST, toXMLsImpl(_cast));
		put(PATH_SKILL, toXMLsImpl(_skl));
		put(PATH_ITEM, toXMLsImpl(_itm));
		put(PATH_BEAST, toXMLsImpl(_bst));
		put(PATH_INFO, toXMLsImpl(_info));

		return r;
	}
	private static string[string] toXMLsImpl(A)(A[] targs) {
		string[string] r;
		foreach (targ; targs) {
			auto fname = format("%02d", targ.id) ~ ".xml";
			r[fname] = targ.toXML();
		}
		return r;
	}
	/// 指定されたパスにXML形式でシナリオを上書き保存する。
	/// Area、Battle、Package、CastCard、SkillCard、ItemCard、BeastCard、InfoCard
	/// の各ディレクトリにある*.xmlは一旦全て削除される。
	/// Params:
	/// path = 保存先のパス。
	/// Throws:
	/// FileException = ファイル削除時・保存時例外発生時。
	void saveXMLs(string path) {
		std.file.write(std.path.buildPath(path, "Summary.xml"), summaryToXML());

		saveXML(std.path.buildPath(path, PATH_AREA), _area);
		saveXML(std.path.buildPath(path, PATH_BATTLE), _btl);
		saveXML(std.path.buildPath(path, PATH_PACKAGE), _pkg);

		saveXML(std.path.buildPath(path, PATH_CAST), _cast);
		saveXML(std.path.buildPath(path, PATH_SKILL), _skl);
		saveXML(std.path.buildPath(path, PATH_ITEM), _itm);
		saveXML(std.path.buildPath(path, PATH_BEAST), _bst);
		saveXML(std.path.buildPath(path, PATH_INFO), _info);
	}
	/// ditto
	void saveXMLs() {
		saveXMLs(_sPath);
	}
	private static void delAllXML(string p) {
		foreach (t; clistdir(p)) {
			t = std.path.buildPath(p, t);
			if (!isDir(t) && cfnmatch(cwx.utils.getExt(t), "xml")) {
				std.file.remove(t);
			}
		}
	}
	private static void saveXML(A)(string path, A[] targs) {
		if (targs.length == 0) {
			if (exists(path) && isDir(path)) {
				delAllXML(path);
				if (clistdir(path).length == 0) {
					rmdir(path);
				}
			}
		} else {
			if (exists(path) && isDir(path)) {
				delAllXML(path);
			} else {
				mkdir(path);
			}
			foreach (targ; targs) {
				auto p = createFileI(path, targ.name, "xml", format("%02d", targ.id) ~ "_");
				std.file.write(p, targ.toXML());
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
				propNode.parse();
			};
			summ._froot = FlagDir.fromXmlNode(summNode, summ, &summ.changeHandler, summ.dataVersion);
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

		summ.loadXML2(xmls, PATH_AREA, "Area", summ._area, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		summ.checkStartArea();
		summ.loadXML2(xmls, PATH_BATTLE, "Battle", summ._btl, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		summ.loadXML2(xmls, PATH_PACKAGE, "Package", summ._pkg, summ.useCounter, &summ.changeHandler, summ.dataVersion);

		summ.loadXML2(xmls, PATH_CAST, "CastCard", summ._cast, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		summ.loadXML2(xmls, PATH_SKILL, "SkillCard", summ._skl, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		summ.loadXML2(xmls, PATH_ITEM, "ItemCard", summ._itm, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		summ.loadXML2(xmls, PATH_BEAST, "BeastCard", summ._bst, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		summ.loadXML2(xmls, PATH_INFO, "InfoCard", summ._info, summ.useCounter, &summ.changeHandler, summ.dataVersion);

		return summ;
	}
	private static void fromXMLs(Summary summ) {
		auto path = summ.scenarioPath;
		summ.loadXML1(std.path.buildPath(path, PATH_AREA), "Area", summ._area, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		summ.checkStartArea();
		summ.loadXML1(std.path.buildPath(path, PATH_BATTLE), "Battle", summ._btl, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		summ.loadXML1(std.path.buildPath(path, PATH_PACKAGE), "Package", summ._pkg, summ.useCounter, &summ.changeHandler, summ.dataVersion);

		summ.loadXML1(std.path.buildPath(path, PATH_CAST), "CastCard", summ._cast, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		summ.loadXML1(std.path.buildPath(path, PATH_SKILL), "SkillCard", summ._skl, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		summ.loadXML1(std.path.buildPath(path, PATH_ITEM), "ItemCard", summ._itm, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		summ.loadXML1(std.path.buildPath(path, PATH_BEAST), "BeastCard", summ._bst, summ.useCounter, &summ.changeHandler, summ.dataVersion);
		summ.loadXML1(std.path.buildPath(path, PATH_INFO), "InfoCard", summ._info, summ.useCounter, &summ.changeHandler, summ.dataVersion);
	}

	/// XMLを元にしたインスタンスを返す。
	/// Params:
	/// path = Summary.xmlのパス。
	/// Throws:
	/// SummaryException = ファイルはSummary定義のXML文書ではない。
	/// FileException = ファイル読込み例外発生時。
	/// XmlException = XMLパースエラー発生時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	/// FileLoadException = Summary.xml以外での読込例外発生時。
	private static Summary fromXMLs(string path) {
		auto summ = summaryFromXML(dirName(path), std.file.readText(path));
		fromXMLs(summ);
		return summ;
	}

	/// XMLファイルまたはクラシックなシナリオを再読込し、新しいSummaryを生成して返す。
	Summary reloadXMLs(bool doubleIO) {
		Summary summ;
		if (legacy) {
			summ = loadLScenario!(S)(scenarioPath, "", doubleIO, scenarioName);
		} else {
			summ = summaryFromXML(scenarioPath,
				std.file.readText(std.path.buildPath(scenarioPath, "Summary.xml")));
			fromXMLs(summ);
		}
		summ._expandXMLs = expandXMLs;
		summ._zipName = zipName;
		summ._useTemp = useTemp;
		summ._legacy = legacy;
		if (useTemp) {
			summ._lock = _lock;
		}
		return summ;
	}

	/// フラグとステップのルートディレクトリ。
	@property
	FlagDir flagDirRoot() {
		return _froot;
	}
	/// ditto
	@property
	const
	const(FlagDir) flagDirRoot() {
		return _froot;
	}

	mixin STemplate!(true, true, true, true, true);

	/// シナリオのディレクトリ。
	@property
	const
	string scenarioPath() {
		return _sPath;
	}
	/// シナリオのディレクトリ。
	@property
	void scenarioPath(string sPath) {
		_sPath = sPath;
	}
	/// シナリオ名。
	@property
	const
	string scenarioName() {
		return _sname;
	}
	/// ditto
	@property
	void scenarioName(string scenarioName) {
		setBaseParams(scenarioName, author);
	}

	/// カード画像のマップを生成して返す。
	const
	private string[][immutable(ubyte[])] cardImgTable(string mtdir, Skin skin, UseCounter uc) {
		string[][immutable(ubyte[])] r;
		foreach (file; clistdir(mtdir)) {
			if (skin.isCardImage(std.path.buildPath(mtdir, file))) {
				auto mBytes = cast(ubyte[]) std.file.read(std.path.buildPath(mtdir, file));
				auto bytes = assumeUnique(mBytes);
				r[bytes] ~= std.path.buildPath(skin.materialPath, file);
			}
		}
		foreach (key, v; r.values) {
			if (v.length > 1u) {
				string[] nv;
				foreach (file; v) {
					if (!cwx.utils.fnstartsWith(baseName(file), "font_")) {
						/// font_X.bmpはやむを得ずコピーした可能性があるため優先的に除外
						nv ~= file;
					}
				}
				r.values[key] = nv;
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
	const
	private bool moveBinImg(ref string[][immutable(ubyte[])] cis, PathUser targ, string fname, string mt, Skin toSkin) {
		string img = targ.path;
		if (isBinImg(img)) {
			auto bytes = strToBImg(img);
			string[] *files = bytes in cis;
			if (files) {
				assert (files.length);
				targ.path = (*files)[0u];
			} else {
				auto file = createFileI(mt, fname, "bmp", "");
				std.file.write(file, bytes);
				targ.path = std.path.buildPath(toSkin.materialPath, baseName(file));
				cis[assumeUnique(bytes)] ~= targ.path;
				return true;
			}
		}
		return false;
	}
	public string classicToX(in CProps prop, string tempPath, Skin toSkin, out string[] copyFail) {
		copyFail = [];
		auto uc = useCounter;
		auto temp = Summary.createTempDir(tempPath, scenarioName);
		auto mt = std.path.buildPath(temp, toSkin.materialPath);
		try {
			mkdirRecurse(mt);
		} catch (Exception e) {
			// 稀な条件でMaterialだけ生成されない場合がある模様
			debugln(e);
		}
		if (!.exists(mt)) {
			mt = temp;
		}
		foreach (file; clistdir(scenarioPath)) {
			if (cfnmatch(file, "cwxeditor.lock")) {
				continue;
			}
			auto p = std.path.buildPath(scenarioPath, file);
			try {
				if (isDir(p)) {
					auto top = std.path.buildPath(mt, baseName(p));
					mkdir(top);
					copyAll(p, top);
				} else if (!cfnmatch(cwx.utils.getExt(p), "wsm") && !cfnmatch(cwx.utils.getExt(p), "wid")) {
					if (toSkin.isCardImage(p)
							|| toSkin.isBgImage(p)
							|| toSkin.isBGM(p)
							|| toSkin.isSE(p)) {
						copy(p, std.path.buildPath(mt, baseName(p)));
					} else {
						copy(p, std.path.buildPath(temp, baseName(p)));
					}
				}
			} catch (Exception ex) {
				debugln(ex);
				copyFail ~= p;
			}
		}
		foreach (key; uc.path.keys) {
			uc.change(key, toPathId(std.path.buildPath(toSkin.materialPath, cast(string) key)));
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
	@property
	const
	bool isSaved() {
		return !useTemp || zipName.length;
	}
	/// 上書き保存。
	void saveOverwrite(in CProps prop, bool doubleIO, bool saveInnerImagePath) in {
		assert (isSaved);
	} body {
		saveProc(prop, doubleIO, saveInnerImagePath, false, zipName, scenarioPath, false, expandXMLs);
	}
	/// 名前をつけて保存。
	void saveWithName(in CProps prop, bool doubleIO, bool saveInnerImagePath, string fname, string tempPath,
			bool defExpandXMLs, Skin defSkin, void delegate(string) showWarn) in {
		assert (cfnmatch(cwx.utils.getExt(fname), "wsn"));
	} body {
		if (legacy) {
			// クラシック形式からXML形式に変換
			string[] copyFail;
			auto temp = classicToX(prop, tempPath, defSkin, copyFail);
			foreach (fail; copyFail) {
				// 一部コピー失敗しても中断しない
				showWarn(.tryFormat(prop.msgs.fileCopyError, fail));
			}
			scope (failure) delAll(temp);
			if (!type.length) type = defSkin.type;
			saveProc(prop, doubleIO, saveInnerImagePath, true, fname, temp, true, defExpandXMLs);
		} else if (useTemp) {
			// 新しいアーカイブを作成
			string oldZip = _zipName;
			_zipName = fname;
			scope (failure) _zipName = oldZip;
			saveProc(prop, doubleIO, saveInnerImagePath, false, zipName, scenarioPath, false, defExpandXMLs);
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
			saveProc(prop, doubleIO, saveInnerImagePath, true, fname, p, false, defExpandXMLs);
		}
	}
	private void saveProc(in CProps prop, bool doubleIO, bool saveInnerImagePath, bool archive,
			string zipName, string temp, bool legacyToX, bool defExpandXMLs) {
		try {
			bool expand = false;
			if (legacy && !legacyToX) {
				saveLScenario(this, doubleIO, saveInnerImagePath);
				if (useTemp) {
					if (cfnmatch(cwx.utils.getExt(zipName), "cab")) {
						.cab(temp, zipName, (string file) {
							return !cfnmatch(baseName(file), "cwxeditor.lock");
						});
					} else {
						.zip(temp, zipName, true, [std.path.buildPath(temp, "cwxeditor.lock")], true);
					}
					_zipName = zipName;
				}
			} else if (archive || useTemp || legacyToX) {
				auto oldPath = scenarioPath;
				if (expandXMLs) {
					saveXMLs();
					expand = true;
				} else if (legacyToX && defExpandXMLs) {
					scenarioPath = temp;
					scope (failure) scenarioPath = oldPath;
					saveXMLs();
					expand = true;
				}
				auto lock = std.path.buildPath(scenarioPath, "cwxeditor.lock");
				scope arc = .zip(scenarioPath, false, [lock]);
				if (!expand) {
					auto xmls = toXMLs();
					foreach (path, files; xmls) {
						foreach (name, xml; files) {
							auto p = std.path.buildPath(path, name);
							arc.addMember(.archive(p, cast(ubyte[]) xml, false));
						}
					}
					_oldXMLs = xmls;
				}
				std.file.write(zipName, arc.build());
			} else {
				assert (expandXMLs);
				saveXMLs();
			}
			dataVersion = LATEST_VERSION;
			resetChanged();
			if (legacyToX || (!useTemp && archive)) {
				toArchive(zipName, temp, expand);
			}
		} catch (Exception e) {
			debugln(e);
			throw new SummaryException(.tryFormat(prop.msgs.saveError, scenarioName));
		}
	}
	/// データを保存せずにシナリオのフォルダのアーカイブを作成する。
	void createZip(string zipName, in string[] ignorePaths, bool useSysEnc) {
		auto lock = std.path.buildPath(scenarioPath, "cwxeditor.lock");
		auto arc = .zip(scenarioPath, true, (string file) {
			return cfnmatch(file, lock)
				|| containsPath(ignorePaths, file.baseName);
		}, useSysEnc);
		if (useTemp && !expandXMLs) {
			foreach (path, files; _oldXMLs) {
				foreach (name, xml; files) {
					auto p = std.path.buildPath(path, name);
					arc.addMember(.archive(p, cast(ubyte[]) xml, false, useSysEnc));
				}
			}
		}
		std.file.write(zipName, arc.build());
	}
	/// データを保存せずにシナリオのフォルダのアーカイブを作成する。
	/// 非展開のXMLファイルは一時的に展開される。
	void createCab(string cabName, in string[] ignorePaths) {
		string[] tempDirs;
		string[] tempFiles;
		if (useTemp && !expandXMLs) {
			foreach (path, files; _oldXMLs) {
				foreach (name, xml; files) {
					auto dir = std.path.buildPath(scenarioPath, path);
					auto p = std.path.buildPath(dir, name);
					if (!.exists(dir)) {
						mkdir(dir);
						tempDirs ~= p;
					}
					std.file.write(p, xml);
					tempFiles ~= p;
				}
			}
		}
		scope (exit) {
			foreach (p; tempDirs) {
				delAll(p);
			}
			foreach (p; tempFiles) {
				delAll(p);
			}
		}

		.cab(scenarioPath, cabName, (string file) {
			return !cfnmatch(baseName(file), "cwxeditor.lock")
				&& !containsPath(ignorePaths, file.baseName);
		});
	}

	/// ファイルシステム上に展開されなかったXMLデータ。
	private string[string][string] _oldXMLs;

	/// シナリオディレクトリ内の未使用ファイル・ディレクトリのリストを返す。
	string[] notUsedFiles(in Skin skin, in string[] ignorePaths, bool logicalSort) {
		string[] r;
		int dirS(string p) {
			if (.isDir(p)) {
				string[] list = clistdir(p);
				if (logicalSort) {
					list = sort!(fnncmp)(list);
				} else {
					list = sort!(fncmp)(list);
				}
				int c = 0;
				foreach (string file; list) {
					c += dirS(p.buildPath(file));
				}
				auto rel = abs2rel(scenarioPath, p);
				if ("" == rel || fnmatch(rel, skin.materialPath)) {
					c++;
				}
				if (0 == c) {
					// 未使用ディレクトリ
					r ~= rel;
				}
				return c;
			} else {
				if (isSystemFile(p) || containsPath(ignorePaths, baseName(p))) {
					return 1;
				}
				if (!skin.isMaterial(p)) {
					return 1;
				}
				auto p2 = abs2rel(scenarioPath, p);
				auto pathId = toPathId(p2);
				if (0 == useCounter.get(pathId)) {
					r ~= p2;
					return 0;
				}
				return 1;
			}
		}
		dirS(scenarioPath);
		return r;
	}
}

/// カードのみのシナリオデータ。
template CardContainer(bool UseCast, bool UseSkill, bool UseItem, bool UseBeast, bool UseInfo) {
	mixin ("class CardContainer : CWXPath"
		~ (UseCast ? ", CastOwner" : "")
		~ (UseSkill ? ", SkillOwner" : "")
		~ (UseItem ? ", ItemOwner" : "")
		~ (UseBeast ? ", BeastOwner" : "")
		~ (UseInfo ? ", InfoOwner" : "")
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

	/// Aに対応する配列。
	template CArray(A) {
		static if (UseCast && is(A : CastCard)) {
			alias _cast CArray;
		} else static if (UseSkill && is(A : SkillCard)) {
			alias _skl CArray;
		} else static if (UseItem && is(A : ItemCard)) {
			alias _itm CArray;
		} else static if (UseBeast && is(A : BeastCard)) {
			alias _bst CArray;
		} else static if (UseInfo && is(A : InfoCard)) {
			alias _info CArray;
		} else static assert (0);
	}
public:
	mixin STemplate!(UseCast, UseSkill, UseItem, UseBeast, UseInfo);

	/// 唯一のコンストラクタ。
	this (string sPath, string sname, bool legacy) {
		_id = format("%08X", &this) ~ "-" ~ to!(string)(Clock.currTime());
		_sPath = sPath;
		_sname = sname;
		_legacy = legacy;
	}
	@property
	override string cwxPath() {return "";}
	override CWXPath findCWXPath(string path) {
		if (cpempty(path)) return this;
		return findCWXPathImpl(path, cpcategory(path));
	}
	@property
	override CWXPath[] cwxChilds() {return cwxChildsImpl;}
	@property
	CWXPath cwxParent() {return null;}

	/// マシン上で一意なID。
	@property
	const
	string id() {
		return _id;
	}
	/// スキン。
	@property
	const
	string type() {return _type;}

	/// シナリオのディレクトリ。
	@property
	const
	string scenarioPath() {
		return _sPath;
	}
	/// シナリオ名。
	@property
	const
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
	const
	int indexOf(T)(in T c) {
		static if (UseCast && is (T == CastCard)) {
			return .cCountUntil!("a is b")(_cast, c);
		} else static if (UseSkill && is (T == SkillCard)) {
			return .cCountUntil!("a is b")(_skl, c);
		} else static if (UseItem && is (T == ItemCard)) {
			return .cCountUntil!("a is b")(_itm, c);
		} else static if (UseBeast && is (T == BeastCard)) {
			return .cCountUntil!("a is b")(_bst, c);
		} else static if (UseInfo && is (T == InfoCard)) {
			return .cCountUntil!("a is b")(_info, c);
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
			node.parse();
		};
		summNode.parse();
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

			static if (UseCast) cc.loadXML2!(CastCard)(xmls, PATH_CAST, CastCard.XML_NAME, cc._cast, null, null, ver);
			static if (UseSkill) cc.loadXML2!(SkillCard)(xmls, PATH_SKILL, SkillCard.XML_NAME, cc._skl, null, null, ver);
			static if (UseItem) cc.loadXML2!(ItemCard)(xmls, PATH_ITEM, ItemCard.XML_NAME, cc._itm, null, null, ver);
			static if (UseBeast) cc.loadXML2!(BeastCard)(xmls, PATH_BEAST, BeastCard.XML_NAME, cc._bst, null,null, ver);
			static if (UseInfo) cc.loadXML2!(InfoCard)(xmls, PATH_INFO, InfoCard.XML_NAME, cc._info, null, null, ver);

			return cc;
		}
		throw new SummaryException("File is not summary");
	}

	/// XMLを元にしたインスタンス。
	/// Params:
	/// path = Summary.xmlのパス。
	/// Throws:
	/// SummaryException = ファイルはSummary定義のXML文書ではない。
	/// FileException = ファイル読込み例外発生時。
	/// XmlException = XMLパースエラー発生時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	/// FileLoadException = Summary.xml以外での読込例外発生時。
	static CardContainer fromXMLs(string path) {
		scope summNode = XNode.parse(std.file.readText(path));
		if (summNode.name == "Summary") {
			string par = dirName(path);
			string ver;
			auto cc = fromNode(summNode, par, ver);

			static if (UseCast) cc.loadXML1!(CastCard)(std.path.buildPath(par, PATH_CAST), CastCard.XML_NAME, cc._cast, null, null, ver);
			static if (UseSkill) cc.loadXML1!(SkillCard)(std.path.buildPath(par, PATH_SKILL), SkillCard.XML_NAME, cc._skl, null, null, ver);
			static if (UseItem) cc.loadXML1!(ItemCard)(std.path.buildPath(par, PATH_ITEM), ItemCard.XML_NAME, cc._itm, null, null, ver);
			static if (UseBeast) cc.loadXML1!(BeastCard)(std.path.buildPath(par, PATH_BEAST), BeastCard.XML_NAME, cc._bst, null,null, ver);
			static if (UseInfo) cc.loadXML1!(InfoCard)(std.path.buildPath(par, PATH_INFO), InfoCard.XML_NAME, cc._info, null, null, ver);

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
	this (string path, Exception e) {
		super(e.msg);
		_path = path;
		_e = e;
	}
	/// 読み込み対象パス。
	@property
	const
	string path() {
		return _path;
	}
	/// 例外。
	@property
	Exception e() {
		return _e;
	}
	@property
	const
	const(Exception) e() {
		return _e;
	}
}

/// シナリオのシステムディレクトリ
/// (Area, Battle, Package, CastCard, SkillCard, ItemCard, BeastCard, InfoCard)
/// であればtrueを返す。
bool isScenarioSystemDir(string dir) {
	return cfnmatch(dir, PATH_AREA)
		|| cfnmatch(dir, PATH_PACKAGE)
		|| cfnmatch(dir, PATH_BATTLE)
		|| cfnmatch(dir, PATH_CAST)
		|| cfnmatch(dir, PATH_SKILL)
		|| cfnmatch(dir, PATH_ITEM)
		|| cfnmatch(dir, PATH_BEAST)
		|| cfnmatch(dir, PATH_INFO);
}

/// シナリオ関連ファイルのパスを分解し、シナリオフォルダと
/// パスに含まれるリソースパスに分ける。
void decScenarioPath(ref string scenarioPath, ref string[] openPaths) {
	if (scenarioPath && cfnmatch(cwx.utils.getExt(scenarioPath), "wid")) {
		ulong id;
		auto type = cwx.cwl.getType(scenarioPath, id);
		if (type) {
			string ts;
			if (type is typeid(Area)) {
				ts = "area";
			} else if (type is typeid(Battle)) {
				ts = "battle";
			} else if (type is typeid(Package)) {
				ts = "package";
			} else if (type is typeid(CastCard)) {
				ts = "castcard";
			} else if (type is typeid(SkillCard)) {
				ts = "skillcard";
			} else if (type is typeid(ItemCard)) {
				ts = "itemcard";
			} else if (type is typeid(BeastCard)) {
				ts = "beastcard";
			} else if (type is typeid(InfoCard)) {
				ts = "infocard";
			}
			ts ~= ":id:" ~ to!(string)(id);
			openPaths ~= ts;
		}
		scenarioPath = dirName(scenarioPath);
	}
}
