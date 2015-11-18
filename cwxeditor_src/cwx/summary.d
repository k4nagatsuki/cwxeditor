
module cwx.summary;

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
import cwx.system;
import cwx.structs;
import cwx.types;
import cwx.binary;

import lhafile.lhafile;

import core.thread;

import std.algorithm;
import std.array;
import std.file;
import std.path;
import d2std.zip;
import std.datetime;
import std.stdio;
import std.string;
import std.utf;
import std.traits;
import std.exception;
import std.conv;
import std.parallelism;

public:

/// 貼り紙関連の例外。
class SummaryException : Exception {
public:
	this (string msg) { mixin(S_TRACE);
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

/// 読込時オプション。
struct LoadOption {
	bool doubleIO = false; /// 読込みの多重化を行うか。
	bool cardOnly = false; /// エリア・バトル・パッケージを無視するか。
	bool textOnly = false; /// 素材を無視するか。
	bool expandXMLs = true; /// XMLファイルを展開するか。
	bool summaryOnly = false; /// 概要のみを読み込むか。
	/// ロードが進行する毎に呼び出される関数を指定する。
	void delegate(string sName, string fileName) processFunc = null;
}

/// 保存時オプション。
struct SaveOption {
	bool doubleIO = false; /// 書込みの多重化を行うか。
	bool saveInnerImagePath = false; /// 格納イメージの参照先を保存するか。
	bool saveChangedOnly = false; /// 更新されたファイルだけを保存するか。
	bool backup = false; /// 保存時バックアップを行うか。
	string backupDir = ""; /// 保存時バックアップ先。
	bool archiveInNewThread = false; /// 保存後の圧縮を別スレッドで行うか。
	void delegate() savedCallback = null; /// 保存完了通知を受け取る場合は設定する。
}

/// 貼り紙。シナリオの情報が入る。
class Summary : CWXPath, AreaOwner, BattleOwner, PackageOwner, CastOwner, SkillOwner, ItemOwner, BeastOwner, InfoOwner, IAreaUser, IPathUser, ICouponUser {
private:
	string _id;

	bool _expandXMLs; /// XMLファイルを展開するか。
	bool _useTemp = true; /// 一時ディレクトリに展開しているか。
	File _lock; /// 一時ディレクトリロック用オブジェクト。
	string _zipName = ""; /// 圧縮されているシナリオなら、元ファイルのパス。再圧縮できない場合は""。
	string _origZipName = ""; /// 圧縮されているシナリオなら、元ファイルのパス。
	string _tempPath = ""; /// 圧縮されているシナリオなら、一時展開先のパス。
	bool _legacy = false; /// クラシックなシナリオか。
	bool _inSaving = false; /// 保存中ならtrue。

	/// ファイル・ディレクトリの更新チェック用のパス一覧。
	SysTime[string] _checkPaths, _noSaveCheckPaths;

	string _sPath = null;
	string _sname = "";
	string _author = ""; /// 作者名。
	CardImage[] _imgPaths; /// 貼り紙画像のパス。
	string _desc = ""; /// 貼り紙の文章。
	uint _levMin = 0; /// 推奨レベル(下)。
	uint _levMax = 0; /// 推奨レベル(上)。
	uint _rCouponNum = 0; /// 前提クーポン必要数。
	CouponUser[] _rCoupons = []; /// 前提クーポン。
	AreaUser _startAreaId; /// スタートエリアのID。
	// TODO Tag
	string _type;
	string _dataVersion = DEFAULT_VERSION;

	FlagDir _froot; /// フラグとステップのデータ。

	Area[] _area; /// エリア。
	Package[] _pkg; /// パッケージ。
	Battle[] _btl; /// バトル。

	CastCard[] _cast; /// キャスト。
	SkillCard[] _skl; /// スキル。
	ItemCard[] _itm; /// アイテム。
	BeastCard[] _bst; /// 召喚獣。
	InfoCard[] _info; /// 情報。

	EvTemplate[] _eventTemplates; /// イベントテンプレート。

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

	void changeHandler() { mixin(S_TRACE);
		if (!_change) { mixin(S_TRACE);
			_change = true;
			foreach (dlg; changedEvent) { mixin(S_TRACE);
				dlg();
			}
		}
		foreach (dlg; changedEventForce) { mixin(S_TRACE);
			dlg();
		}
	}

	this (string sPath) { mixin(S_TRACE);
		_sPath = sPath;
		auto o = this;
		_id = format("%08X", &o) ~ "-" ~ to!(string)(Clock.currTime());
		_uc = new UseCounter;
		_froot = new FlagDir(this);
		_froot.changeHandler = &changeHandler;
		_startAreaId = new AreaUser(this);
		_startAreaId.setUseCounter(_uc);
	}
public:
	/// シナリオ名、スキン、シナリオのパスを指定してインスタンスを生成。
	this (string sname, string type, string sPath, bool temp, bool legacy) { mixin(S_TRACE);
		this(sPath);
		_type = type;
		_sname = sname;
		_legacy = legacy;
		_useTemp = temp;
		if (_useTemp) { mixin(S_TRACE);
			_tempPath = _sPath;
			lock(_tempPath, _useTemp);
		}
	}

	/// XMLファイルを展開しているか。
	@property
	const
	bool expandXMLs() {return _expandXMLs;}
	/// 現在のscenarioPathは一時展開先か。
	@property
	const
	bool useTemp() {return _useTemp;}
	/// 元の圧縮ファイル名は何か。圧縮されていないシナリオの場合は""。
	/// 再圧縮できない場合も""となる。
	@property
	const
	string zipName() {return _zipName;}
	/// ditto
	@property
	void zipName(string zipName) {_zipName = zipName;}
	/// 元の圧縮ファイル名は何か。圧縮されていないシナリオの場合は""。
	@property
	const
	string origZipName() {return _origZipName;}
	/// クラシックな形式のシナリオか。
	@property
	const
	bool legacy() {return _legacy;}

	/// 一時ディレクトリを作成する。
	static string createTempDirFromName(string tempPath, string name) { mixin(S_TRACE);
		auto temp = createNewFileName(std.path.buildPath(tempPath, name), true);
		mkdirRecurse(temp);
		return temp;
	}
	/// 一時ディレクトリを展開する。
	static string createTempDir(string tempPath, string name, bool createLockFile = true) { mixin(S_TRACE);
		auto base = cleanFileName(name);
		auto temp = createNewFileName(std.path.buildPath(tempPath, base), true);
		mkdirRecurse(temp);
		if (createLockFile) typeof(this).createLockFile(temp);
		return temp;
	}
	/// tempにロックファイルを作成する。
	static void createLockFile(string temp) { mixin(S_TRACE);
		std.file.write(std.path.buildPath(temp, "cwxeditor.lock"), []);
	}

	/// tempPathにシナリオを新規作成する。
	static Summary createScenario(const System sys, string tempPath, string name, Skin skin) { mixin(S_TRACE);
		auto p = Summary.createTempDir(tempPath, name);
		auto mFPath = std.path.buildPath(p, skin.materialPath);
		if (!exists(mFPath) || !isDir(mFPath)) std.file.mkdir(mFPath);
		auto summ = new Summary(name, skin.type, p, true, false);
		if (summ.expandXMLs) { mixin(S_TRACE);
			SaveOption opt;
			summ.saveXMLsImpl(summ.scenarioPath, sys, opt, true);
		}
		summ.refCheckPaths();
		return summ;
	}

	/// シナリオを読込む。
	static Summary loadScenarioFromFile(in CProps prop, in LoadOption opt, string fname, string tempPath,
			string delegate() classicDir = null,
			Summary old = null, void delegate(uint) setMax = null, void delegate(uint) worked = null, string newName = null) { mixin(S_TRACE);
		string[string][string] xmls;
		bool expand = opt.expandXMLs;
		bool scTemplate = classicDir !is null;
		bool classic = false;
		string fext = fname.extension().toLower();

		string isXMLSystem(string path) { mixin(S_TRACE);
			// CABの場合はメモリ上に展開できないため必ずファイルを展開する必要がある
			if (cfnmatch(fext, ".cab")) return path;
			if (!cfnmatch(.extension(path), ".xml")) return null;
			auto dir = dirName(path).baseName();
			if (!isScenarioSystemDir(dir)) return null;
			return dir.buildPath(path.baseName());
		}
		string expandDir;
		string expandName(string path, bool isDir) { mixin(S_TRACE);
			if (opt.summaryOnly) { mixin(S_TRACE);
				if (classic) { mixin(S_TRACE);
					if (cfnmatch(path.baseName(), "Summary.wsm")) return path;
				} else { mixin(S_TRACE);
					if (cfnmatch(path.baseName(), "Summary.xml")) return path;
				}
				return "";
			}
			if (!opt.textOnly) return path;
			auto ext = path.extension();
			if (cfnmatch(ext, ".jptx")) return path;
			if (classic) { mixin(S_TRACE);
				if (cfnmatch(ext, ".wsm") || cfnmatch(ext, ".wid") || cfnmatch(ext, ".wex")) return path;
			} else { mixin(S_TRACE);
				if (cfnmatch(path.baseName(), "Summary.xml")) return path;
				if (auto path2 = isXMLSystem(path)) return path2;
			}
			if (!isDir) { mixin(S_TRACE);
				// 素材が見つからないというエラーを避けるため、ダミーの空ファイルを作る
				auto p = expandDir.buildPath(path);
				string dir = p.dirName();
				if (!dir.exists()) dir.mkdirRecurse();
				std.file.write(p, []);
			}
			return "";
		}
		string findSummaryDir(string temp, string summary) {
			foreach (string file; temp.dirEntries(SpanMode.depth)) {
				if (.cfnmatch(file.baseName(), summary)) return file.dirName();
			}
			return temp;
		}
		string sunzip(string fname, ZipArchive arc, out bool cancel, out string summPath) { mixin(S_TRACE);
			cancel = false;
			auto temp = createTempDir(tempPath, baseName(stripExtension(fname)), false);
			expandDir = temp;
			if (expand) { mixin(S_TRACE);
				.unzip(temp, arc, &expandName, setMax, worked);
			} else { mixin(S_TRACE);
				.unzip(arc, (string path, ubyte[] data, bool isDir) { mixin(S_TRACE);
					path = expandName(path, isDir);
					if (!path.length) return;
					if (!isDir) { mixin(S_TRACE);
						auto file = path.baseName();
						if (cfnmatch(file, "Summary.xml")) { mixin(S_TRACE);
							xmls[""][file.idup] = cast(string)data.idup;
						} else if (auto path2 = isXMLSystem(path)) { mixin(S_TRACE);
							xmls[dirName(path2).idup][baseName(path2).idup] = cast(string)data.idup;
						} else { mixin(S_TRACE);
							path = std.path.buildPath(temp, path);
							string parent = dirName(path);
							if (!exists(parent)) mkdirRecurse(parent);
							std.file.write(path, data);
						}
					} else if (!isScenarioSystemDir(path)) { mixin(S_TRACE);
						path = std.path.buildPath(temp, path);
						if (!exists(path)) mkdirRecurse(path);
					}
				}, setMax, worked);
			}
			summPath = findSummaryDir(temp, "Summary.xml");
			createLockFile(temp);
			return temp;
		}
		bool scArc(ZipArchive arc, string ext) { mixin(S_TRACE);
			foreach (am; arc.directory) { mixin(S_TRACE);
				string name;
				try {
					cwx.utils.validate(am.name);
					name = am.name;
				} catch (Exception e) {
					name = touni(am.name, false, "__");
				}
				name = replace(name, "/", dirSeparator);
				if (cfnmatch(baseName(name), setExtension("Summary", ext))) { mixin(S_TRACE);
					return true;
				}
			}
			return false;
		}
		bool scArcLHA(LhaFile arc, string ext) { mixin(S_TRACE);
			foreach (name; arc.nameList) { mixin(S_TRACE);
				if (cfnmatch(baseName(name), setExtension("Summary", ext))) { mixin(S_TRACE);
					return true;
				}
			}
			return false;
		}
		string suncab(string fname, string summName, out string summPath, out bool canArchive) { mixin(S_TRACE);
			classic = true;
			string temp;
			auto ext = .extension(fname);
			canArchive = true;
			if (canUncab && .cfnmatch(ext, ".cab")) { mixin(S_TRACE);
				temp = createTempDir(tempPath, baseName(stripExtension(fname)), false);
				expandDir = temp;
				if (!.uncab(fname, temp, (string file) {return expandName(file, false);})) { mixin(S_TRACE);
					delAll(temp);
					return null;
				}
			} else if (.cfnmatch(ext, ".lzh") || .cfnmatch(ext, ".lha")) { mixin(S_TRACE);
				// LHA
				canArchive = false; // 圧縮は不可
				ubyte* ptr = null;
				auto bin = readBinaryFrom!ubyte(fname, ptr);
				scope (exit) freeAll(ptr);
				auto arc = new LhaFile(fname, ByteIO(cast(void[])bin));
				scope (exit) destroy(arc);
				auto isSc = scArcLHA(arc, ".wsm");
				if (!isSc) return null;
				temp = createTempDir(tempPath, baseName(stripExtension(fname)), false);
				try { mixin(S_TRACE);
					expandDir = temp;
					.unlha(temp, arc, &expandName);
				} catch (Exception e) { mixin(S_TRACE);
					printStackTrace();
					debugln(e);
					delAll(temp);
					return null;
				}
			} else { mixin(S_TRACE);
				// zipと仮定
				ubyte* ptr = null;
				auto bin = readBinaryFrom!ubyte(fname, ptr);
				scope (exit) freeAll(ptr);
				auto arc = new ZipArchive(cast(void[])bin);
				scope (exit) destroy(arc);
				auto isSc = scArc(arc, ".wsm");
				if (!isSc) return null;
				temp = createTempDir(tempPath, baseName(stripExtension(fname)), false);
				try { mixin(S_TRACE);
					expandDir = temp;
					.unzip(temp, arc, &expandName);
				} catch (Exception e) { mixin(S_TRACE);
					printStackTrace();
					debugln(e);
					delAll(temp);
					return null;
				}
			}
			summPath = findSummaryDir(temp, summName);
			if (!.exists(std.path.buildPath(summPath, summName))) { mixin(S_TRACE);
				delAll(temp);
				return null;
			}
			if (!scTemplate) { mixin(S_TRACE);
				createLockFile(temp);
			}
			return temp;
		}
		Summary load(string p) { mixin(S_TRACE);
			Summary r;
			if (expand || fext == ".cab") { mixin(S_TRACE);
				r = Summary.fromXMLs(prop.sys, std.path.buildPath(p, "Summary.xml"), opt);
			} else { mixin(S_TRACE);
				r = Summary.fromXMLs(prop.sys, p, xmls, opt);
				r._oldXMLs = xmls;
			}
			return r;
		}
		Summary loadLegacy(string p) { mixin(S_TRACE);
			Summary r = loadLScenario(p, "", prop.sys, opt, newName);
			return r;
		}
		Summary createFromTemplate(Summary r) { mixin(S_TRACE);
			// テンプレートからの生成
			string scDir = classicDir();
			if (!.exists(scDir)) mkdirRecurse(scDir);
			if (scDir) { mixin(S_TRACE);
				copyAll(r.scenarioPath, scDir);
				if (r.useTemp) { mixin(S_TRACE);
					r._useTemp = false;
					delAll(r.scenarioPath);
				}
				r._sPath = scDir;
				r._zipName = "";
				r._origZipName = "";
				r._tempPath = scDir;
				r.refCheckPaths();
				r.repairID0();
				return r;
			}
			return null;
		}
		Summary legacyCommon() { mixin(S_TRACE);
			string summPath;
			bool canArchive;
			string fn = suncab(fname, "Summary.wsm", summPath, canArchive);
			if (fn) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					Summary r = loadLegacy(summPath);
					r._expandXMLs = false;
					r._useTemp = true;
					r._legacy = true;
					r._zipName = canArchive ? fname : "";
					r._origZipName = fname;
					r._tempPath = fn;
					r.refCheckPaths();
					r.repairID0();
					if (scTemplate) { mixin(S_TRACE);
						return createFromTemplate(r);
					} else { mixin(S_TRACE);
						r.lock(r._tempPath, r._useTemp);
						return r;
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
					delAll(fn);
					throw e;
				}
			}
			if (opt.textOnly) return null;
			throw new SummaryException(.tryFormat(prop.msgs.notScenario, fname));
		}
		if (fname) { mixin(S_TRACE);
			if (newName || exists(fname)) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					if (isDir(fname)) { mixin(S_TRACE);
						if (exists(std.path.buildPath(fname, "Summary.xml"))) { mixin(S_TRACE);
							fname = std.path.buildPath(fname, "Summary.xml");
						} else if (exists(std.path.buildPath(fname, "Summary.wsm"))) { mixin(S_TRACE);
							fname = std.path.buildPath(fname, "Summary.wsm");
						}
					}
					Summary ll(string fname) { mixin(S_TRACE);
						auto r = loadLegacy(fname);
						r._expandXMLs = false;
						r._useTemp = false;
						r._legacy = true;
						r._zipName = "";
						r._origZipName = "";
						if (scTemplate) { mixin(S_TRACE);
							return createFromTemplate(r);
						} else { mixin(S_TRACE);
							r.refCheckPaths();
							r.repairID0();
							return r;
						}
					}
					if (cfnmatch(baseName(fname), "Summary.wsm")) { mixin(S_TRACE);
						return ll(dirName(fname));
 					} else if (cfnmatch(baseName(fname), "Summary.xml")) { mixin(S_TRACE);
						expand = true;
						auto r = load(dirName(fname));
						r._expandXMLs = true;
						r._useTemp = false;
						r._legacy = false;
						r._zipName = "";
						r._origZipName = "";
						if (scTemplate) { mixin(S_TRACE);
							auto temp = createTempDir(tempPath, fname.dirName().baseName());
							copyAll(r.scenarioPath, temp);
							r._tempPath = temp;
							r._useTemp = true;
							r.lock(r._tempPath, r._useTemp);
						}
						r.refCheckPaths();
						r.repairID0();
						return r;
					} else if (isDir(fname)) { mixin(S_TRACE);
						return ll(fname);
					} else { mixin(S_TRACE);
						string zipname = fname;
						string summPath;
						string fn = "";
						auto ext = .extension(fname);
						if (canUncab && .cfnmatch(ext, ".cab")) { mixin(S_TRACE);
							if (cabHasFile(fname, "Summary.xml")) { mixin(S_TRACE);
								classic = false;
								bool canArchive;
								fn = suncab(fname, "Summary.xml", summPath, canArchive);
							}
						} else if (.cfnmatch(ext, ".lzh") || .cfnmatch(ext, ".lha")) {
	 						return legacyCommon();
						} else { mixin(S_TRACE);
							ubyte* ptr = null;
							auto bin = readBinaryFrom!ubyte(fname, ptr);
							scope (exit) freeAll(ptr);
							auto arc = new ZipArchive(cast(void[])bin);
							scope (exit) destroy(arc);
							auto isSc = scArc(arc, ".xml");
							if (isSc) { mixin(S_TRACE);
								bool cancel;
								classic = false;
								fn = sunzip(baseName(fname), arc, cancel, summPath);
								if (cancel) { mixin(S_TRACE);
									delAll(dirName(fname));
									return null;
								}
							}
						}
						if (fn.length) { mixin(S_TRACE);
							try { mixin(S_TRACE);
								Summary r = load(summPath);
								r._expandXMLs = expand;
								r._useTemp = true;
								r._zipName = zipname;
								r._origZipName = zipname;
								r._tempPath = fn;
								r._legacy = false;
								r.lock(r._tempPath, r._useTemp);
								if (scTemplate) { mixin(S_TRACE);
									r._zipName = "";
									r._origZipName = "";
								}
								r.refCheckPaths();
								r.repairID0();
								return r;
							} catch (Exception e) {
								printStackTrace();
								debugln(e);
								delAll(fn);
								throw e;
							}
						} else { mixin(S_TRACE);
	 						return legacyCommon();
						}
					}
				} catch (ZipException e) {
					printStackTrace();
					debugln(e);
					throw new SummaryException(.tryFormat(prop.msgs.zipError, fname));
				} catch (FileLoadException e) {
					printStackTrace();
					debugln(e);
					throw new SummaryException(.tryFormat(prop.msgs.loadError, e.path));
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
					throw new SummaryException(.tryFormat(prop.msgs.loadError, fname));
				}
			} else { mixin(S_TRACE);
				throw new SummaryException(.tryFormat(prop.msgs.loadError, fname));
			}
		}
		return null;
	}
	private void lock(string tempPath, bool useTemp) { mixin(S_TRACE);
		assert (!_lock.isOpen);
		if (useTemp) { mixin(S_TRACE);
			_lock = File(std.path.buildPath(tempPath, "cwxeditor.lock"), "wb");
		}
	}
	/// 一時展開先を削除する。
	void delTemp() { mixin(S_TRACE);
		if (useTemp) { mixin(S_TRACE);
			if (_inSaving) { mixin(S_TRACE);
				.task({ mixin(S_TRACE);
					while (_inSaving) Thread.sleep(dur!"msecs"(1));
					delTemp();
				}).executeInNewThread();
				return;
			}
			_lock.close();
			try { mixin(S_TRACE);
				delAll(_tempPath.length ? _tempPath : scenarioPath, true);
				_useTemp = false;
				_zipName = "";
				_origZipName = "";
				_tempPath = "";
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
				std.file.write(std.path.buildPath(_tempPath, "cwxeditor.lock"), []);
			}
		}
	}

	/// シナリオに変更があった際に発生するイベントのハンドラ。
	/// すでに変更済みであった場合は通知されない。
	void delegate()[] changedEvent;
	/// シナリオに変更があった際に発生するイベントのハンドラ。
	/// すでに変更済みであっても通知される。
	void delegate()[] changedEventForce;

	@property
	override string cwxPath(bool id) {return "";}
	override CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		switch (cate) {
		case "area": { mixin(S_TRACE);
			auto index = cpindex(path);
			return index < areas.length ? areas[index].findCWXPath(cpbottom(path)) : null;
		}
		case "area:id": { mixin(S_TRACE);
			auto area = area(cpindex(path));
			return area ? area.findCWXPath(cpbottom(path)) : null;
		}
		case "battle": { mixin(S_TRACE);
			auto index = cpindex(path);
			return index < battles.length ? battles[index].findCWXPath(cpbottom(path)) : null;
		}
		case "battle:id": { mixin(S_TRACE);
			auto area = battle(cpindex(path));
			return area ? area.findCWXPath(cpbottom(path)) : null;
		}
		case "package": { mixin(S_TRACE);
			auto index = cpindex(path);
			return index < packages.length ? packages[index].findCWXPath(cpbottom(path)) : null;
		}
		case "package:id": { mixin(S_TRACE);
			auto area = cwPackage(cpindex(path));
			return area ? area.findCWXPath(cpbottom(path)) : null;
		}
		case "castcard": { mixin(S_TRACE);
			auto index = cpindex(path);
			return index < casts.length ? casts[index].findCWXPath(cpbottom(path)) : null;
		}
		case "castcard:id": { mixin(S_TRACE);
			auto card = cwCast(cpindex(path));
			return card ? card.findCWXPath(cpbottom(path)) : null;
		}
		case "skillcard": { mixin(S_TRACE);
			auto index = cpindex(path);
			return index < skills.length ? skills[index].findCWXPath(cpbottom(path)) : null;
		}
		case "skillcard:id": { mixin(S_TRACE);
			auto card = skill(cpindex(path));
			return card ? card.findCWXPath(cpbottom(path)) : null;
		}
		case "itemcard": { mixin(S_TRACE);
			auto index = cpindex(path);
			return index < items.length ? items[index].findCWXPath(cpbottom(path)) : null;
		}
		case "itemcard:id": { mixin(S_TRACE);
			auto card = item(cpindex(path));
			return card ? card.findCWXPath(cpbottom(path)) : null;
		}
		case "beastcard": { mixin(S_TRACE);
			auto index = cpindex(path);
			return index < beasts.length ? beasts[index].findCWXPath(cpbottom(path)) : null;
		}
		case "beastcard:id": { mixin(S_TRACE);
			auto card = beast(cpindex(path));
			return card ? card.findCWXPath(cpbottom(path)) : null;
		}
		case "infocard": { mixin(S_TRACE);
			auto index = cpindex(path);
			return index < infos.length ? infos[index].findCWXPath(cpbottom(path)) : null;
		}
		case "infocard:id": { mixin(S_TRACE);
			auto card = info(cpindex(path));
			return card ? card.findCWXPath(cpbottom(path)) : null;
		}
		case "variable": { mixin(S_TRACE);
			return flagDirRoot.findCWXPath(cpbottom(path));
		}
		default: break;
		}
		return null;
	}
	@property
	inout
	override inout(CWXPath)[] cwxChilds() { mixin(S_TRACE);
		inout(CWXPath)[] r;
		foreach (a; _area) r ~= a;
		foreach (a; _btl) r ~= a;
		foreach (a; _pkg) r ~= a;
		foreach (a; _cast) r ~= a;
		foreach (a; _skl) r ~= a;
		foreach (a; _itm) r ~= a;
		foreach (a; _bst) r ~= a;
		foreach (a; _info) r ~= a;
		r ~= flagDirRoot;
		return r;
	}
	@property
	CWXPath cwxParent() {return null;}

	/// マシン上で一意なID。
	@property
	const
	string id() { mixin(S_TRACE);
		return _id;
	}
	/// このシナリオが変更済みであればtrueを返す。
	@property
	const
	bool isChanged() { mixin(S_TRACE);
		return _change;
	}
	/// 変更状態をリセットする。
	void resetChanged() { mixin(S_TRACE);
		if (_change) { mixin(S_TRACE);
			refCheckPaths();
			_change = false;
			void recurse(CWXPath path) { mixin(S_TRACE);
				if (auto a = cast(AbstractArea)path) { mixin(S_TRACE);
					a.resetChanged();
				} else if (auto a = cast(Card)path) { mixin(S_TRACE);
					a.resetChanged();
				}
				foreach (child; path.cwxChilds) recurse(child);
			}
			recurse(this);
		}
	}
	/// 変更を通知する。
	void changed() { mixin(S_TRACE);
		changeHandler();
	}
	/// 変更されたファイル単位のリソースの一覧を返す。
	@property
	HashSet!Object changedResources() { mixin(S_TRACE);
		Object topRes(CWXPath path) { mixin(S_TRACE);
			while (!cast(Summary)path.cwxParent) { mixin(S_TRACE);
				path = path.cwxParent;
			}
			return cast(Object)path;
		}
		auto set = new HashSet!Object;
		if (isChanged) set.add(this);
		foreach (a; _area) if (a.isChanged) set.add(a);
		foreach (a; _btl) if (a.isChanged) set.add(a);
		foreach (a; _pkg) if (a.isChanged) set.add(a);
		foreach (a; _cast) if (a.isChanged) set.add(a);
		foreach (a; _skl) { mixin(S_TRACE);
			if (a.isChanged) { mixin(S_TRACE);
				set.add(a);
				if (!isTargetVersion("1")) { mixin(S_TRACE);
					foreach (user; useCounter.values(a.toID(a.id))) set.add(topRes(user.owner));
				}
			}
		}
		foreach (a; _itm) { mixin(S_TRACE);
			if (a.isChanged) { mixin(S_TRACE);
				set.add(a);
				if (!isTargetVersion("1")) { mixin(S_TRACE);
					foreach (user; useCounter.values(a.toID(a.id))) set.add(topRes(user.owner));
				}
			}
		}
		foreach (a; _bst) { mixin(S_TRACE);
			if (a.isChanged) { mixin(S_TRACE);
				set.add(a);
				if (!isTargetVersion("1")) { mixin(S_TRACE);
					foreach (user; useCounter.values(a.toID(a.id))) set.add(topRes(user.owner));
				}
			}
		}
		foreach (a; _info) if (a.isChanged) set.add(a);

		if (legacy) { mixin(S_TRACE);
			auto newAllPaths = allPaths;
			foreach (pathId; useCounter.path.keys) { mixin(S_TRACE);
				if (pathId.isBinImg) continue;
				auto path = cast(string)pathId;
				if (path == "") continue;
				static if (0 == filenameCharCmp('A', 'a')) {
					path = path.toLower();
				}
				auto p1 = path in newAllPaths;
				auto p2 = path in _noSaveCheckPaths;
				if ((!p1 && !p2) || (p1 && !p2) || (!p1 && p2) || (*p1 != *p2)) { mixin(S_TRACE);
					foreach (user; useCounter.values(toPathId(path))) { mixin(S_TRACE);
						auto owner = user.owner;
						if (cast(Card)owner || cast(AbstractSpCard)owner) { mixin(S_TRACE);
							set.add(topRes(user.owner));
						}
					}
				}
			}
		}
		return set;
	}
	/// このシナリオが持つ使用回数カウンタ。
	@property
	UseCounter useCounter() { mixin(S_TRACE);
		return _uc;
	}

	/// クラシックなシナリオで極めて稀に
	/// IDが0のリソースがあるので、補正する。
	private void repairID0() { mixin(S_TRACE);
		auto area0 = area(0);
		auto battle0 = battle(0);
		auto package0 = cwPackage(0);
		auto cast0 = cwCast(0);
		auto skill0 = skill(0);
		auto item0 = item(0);
		auto beast0 = beast(0);
		auto info0 = info(0);

		if (!(area0 || battle0 || package0 || cast0 || skill0 || item0 || beast0 || info0)) return;

		if (area0) add(area0);
		if (battle0) add(battle0);
		if (package0) add(package0);
		if (cast0) add(cast0);
		if (skill0) add(skill0);
		if (item0) add(item0);
		if (beast0) add(beast0);
		if (info0) add(info0);
		void recurse(CWXPath path) { mixin(S_TRACE);
			if (area0) { mixin(S_TRACE);
				if (auto c = cast(Content)path) { mixin(S_TRACE);
					if (c.detail.use(CArg.AREA) && c.area == 0) {
						c.area = area0.id;
					}
				} else if (auto c = cast(Summary)path) { mixin(S_TRACE);
					if (c.startArea == 0) { mixin(S_TRACE);
						c.startArea = area0.id;
					}
				}
			}
			if (battle0) { mixin(S_TRACE);
				if (auto c = cast(Content)path) { mixin(S_TRACE);
					if (c.detail.use(CArg.BATTLE) && c.battle == 0) { mixin(S_TRACE);
						c.battle = battle0.id;
					}
				}
			}
			if (package0) { mixin(S_TRACE);
				if (auto c = cast(Content)path) { mixin(S_TRACE);
					if (c.detail.use(CArg.PACKAGE) && c.packages == 0) { mixin(S_TRACE);
						c.packages = package0.id;
					}
				}
			}
			if (cast0) { mixin(S_TRACE);
				if (auto c = cast(Content)path) { mixin(S_TRACE);
					if (c.detail.use(CArg.CAST) && c.casts == 0) { mixin(S_TRACE);
						c.casts = cast0.id;
					}
				} else if (auto c = cast(EnemyCard)path) { mixin(S_TRACE);
					if (c.id == 0) { mixin(S_TRACE);
						c.id = cast0.id;
					}
				}
			}
			if (skill0) { mixin(S_TRACE);
				if (auto c = cast(Content)path) { mixin(S_TRACE);
					if (c.detail.use(CArg.SKILL) && c.skill == 0) { mixin(S_TRACE);
						c.skill = skill0.id;
					}
				}
			}
			if (item0) { mixin(S_TRACE);
				if (auto c = cast(Content)path) { mixin(S_TRACE);
					if (c.detail.use(CArg.ITEM) && c.item == 0) { mixin(S_TRACE);
						c.item = item0.id;
					}
				}
			}
			if (beast0) { mixin(S_TRACE);
				if (auto c = cast(Content)path) { mixin(S_TRACE);
					if (c.detail.use(CArg.BEAST) && c.beast == 0) { mixin(S_TRACE);
						c.beast = beast0.id;
					}
				}
			}
			if (info0) { mixin(S_TRACE);
				if (auto c = cast(Content)path) { mixin(S_TRACE);
					if (c.detail.use(CArg.INFO) && c.info == 0) { mixin(S_TRACE);
						c.info = info0.id;
					}
				}
			}
			foreach (c; path.cwxChilds) { mixin(S_TRACE);
				recurse(c);
			}
		}
		recurse(this);
	}

	/// シナリオのシステムファイルまたはディレクトリであればtrueを返す。
	const
	bool isSystemFile(string p) { mixin(S_TRACE);
		return isSystemFile(p, .exists(p) && .isDir(p));
	}
	const
	bool isSystemFile(string p, bool isdir) { mixin(S_TRACE);
		if (!isdir && useTemp && .cfnmatch(baseName(p), "cwxeditor.lock")) { mixin(S_TRACE);
			return true;
		}
		if (legacy) { mixin(S_TRACE);
			if (isdir) return false;
			auto ext = .extension(p);
			return .cfnmatch(ext, ".wid") || .cfnmatch(ext, ".wex") || .cfnmatch(ext, ".wsm");
		} else { mixin(S_TRACE);
			string fl = baseName(p);
			if (isdir) { mixin(S_TRACE);
				return isScenarioSystemDir(fl);
			} else { mixin(S_TRACE);
				return cast(bool) .cfnmatch(fl, "Summary.xml");
			}
		}
		return false;
	}
	/// シナリオ内に含まれるシステムファイル・ディレクトリ以外のパスを返す。
	@property
	SysTime[string] allPaths() { mixin(S_TRACE);
		SysTime[string] fcs;
		try { mixin(S_TRACE);
			foreach (file; scenarioPath.dirEntries(SpanMode.depth)) { mixin(S_TRACE);
				if (isSystemFile(file)) continue;
				auto key = file[scenarioPath.length + 1 .. $];
				static if (0 == filenameCharCmp('A', 'a')) {
					key = key.toLower();
				}
				fcs[key] = file.timeLastModified;
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
		return fcs;
	}
	/// シナリオ内のファイルまたはディレクトリが更新されているかチェックする。
	void checkPathsIsChanged(bool saveInnerImagePath) { mixin(S_TRACE);
		if (needCheckPaths) { mixin(S_TRACE);
			auto cp = _checkPaths;
			_checkPaths = allPaths;
			if (((legacy && !saveInnerImagePath) || useTemp) && cp != _checkPaths) { mixin(S_TRACE);
				changed();
			}
		}
	}
	/// 更新チェック用のパス一覧を最新状態にする。
	private void refCheckPaths() { mixin(S_TRACE);
		if (needCheckPaths) { mixin(S_TRACE);
	 		_checkPaths = allPaths;
			_noSaveCheckPaths = _checkPaths;
		}
	}
	@property
	private bool needCheckPaths() { mixin(S_TRACE);
		return true;
	}

	/// 圧縮して保存した事を通知する。
	private void toArchive(string zipName, string scenarioPath, bool expandXMLs) { mixin(S_TRACE);
		_expandXMLs = expandXMLs;
		_useTemp = true;
		_zipName = zipName;
		_origZipName = zipName;
		_legacy = false;
		this.scenarioPath = scenarioPath;
		_tempPath = scenarioPath;
		if (!_lock.isOpen) lock(_tempPath, true);
	}

	/// データバージョン。
	@property
	const
	string dataVersion() {return _dataVersion;}
	/// ditto
	@property
	void dataVersion(string ver) { mixin(S_TRACE);
		if (_dataVersion != ver) { mixin(S_TRACE);
			changed();

			foreach (a; _area) a.changed();
			foreach (a; _btl) a.changed();
			foreach (a; _pkg) a.changed();
			foreach (a; _cast) a.changed();
			foreach (a; _skl) a.changed();
			foreach (a; _itm) a.changed();
			foreach (a; _bst) a.changed();
			foreach (a; _info) a.changed();

			_dataVersion = ver;
		}
	}

	/// 指定されたデータバージョンがシナリオのデータバージョン以下か。
	/// クラシックなシナリオの場合は常にfalseとなる。
	const
	bool isTargetVersion(string ver) { mixin(S_TRACE);
		return !legacy && XMLOption.isTargetVersion(dataVersion, ver);
	}

	private void setNamesOne(C : EffectCard)(ref C card, string newAuthor, string newScenario) { mixin(S_TRACE);
		if (card.scenario == scenarioName && card.author == author) { mixin(S_TRACE);
			card.author = newAuthor;
			card.scenario = newScenario;
			foreach (m; card.motions) { mixin(S_TRACE);
				auto beast = m.beast;
				if (beast) { mixin(S_TRACE);
					setNamesOne(beast, newAuthor, newScenario);
					setContentNames([beast], newAuthor, newScenario);
				}
			}
		}
	}
	private void setNames(C)(C[] cards, string newAuthor, string newScenario) { mixin(S_TRACE);
		foreach (ref card; cards) { mixin(S_TRACE);
			setNamesOne(card, newAuthor, newScenario);
		}
		setContentNames(cards, newAuthor, newScenario);
	}
	private void setContentNames(C : EventTreeOwner)(C[] etos, string newAuthor, string newScenario) { mixin(S_TRACE);
		void setContentNames2(Content c) { mixin(S_TRACE);
			foreach (m; c.motions) { mixin(S_TRACE);
				auto beast = m.beast;
				if (beast) { mixin(S_TRACE);
					setNamesOne(beast, newAuthor, newScenario);
					setContentNames([beast], newAuthor, newScenario);
				}
			}
			foreach (n; c.next) setContentNames2(n);
		}
		foreach (ref eto; etos) { mixin(S_TRACE);
			foreach (ref tree; eto.trees) { mixin(S_TRACE);
				foreach (ref start; tree.starts) { mixin(S_TRACE);
					setContentNames2(start);
				}
			}
		}
	}
	/// シナリオ名と作者名を設定する。
	void setBaseParams(string newScenarioName, string newAuthor) { mixin(S_TRACE);
		setNames(skills, newAuthor, newScenarioName);
		setNames(items, newAuthor, newScenarioName);
		setNames(beasts, newAuthor, newScenarioName);
		foreach (card; casts) { mixin(S_TRACE);
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
	string author() { mixin(S_TRACE);
		return _author;
	}
	/// ditto
	@property
	void author(string author) { mixin(S_TRACE);
		setBaseParams(scenarioName, author);
	}

	/// シナリオのタイプ。スキンを決定する。
	@property
	const
	string type() { mixin(S_TRACE);
		return _type;
	}
	/// ditto
	@property
	void type(string type) { mixin(S_TRACE);
		/// クラシックなシナリオの場合はタイプは保存されない
		if (_type != type && !legacy) changeHandler();
		_type = type;
	}

	/// 貼紙の画像。
	@property
	const
	CardImage[] imagePaths() { mixin(S_TRACE);
		return .map!(a => new CardImage(null, a))(_imgPaths).array();
	}
	/// ditto
	@property
	void imagePaths(in CardImage[] paths) { mixin(S_TRACE);
		if (imagePaths == paths) return;
		changeHandler();
		foreach (u; _imgPaths) { mixin(S_TRACE);
			u.removeUseCounter();
		}
		_imgPaths = [];
		foreach (path; paths) { mixin(S_TRACE);
			auto u = new CardImage(this, path);
			if (useCounter) u.setUseCounter(useCounter);
			_imgPaths ~= u;
		}
	}

	/// シナリオの解説。
	@property
	void desc(string desc) { mixin(S_TRACE);
		if (_desc != desc) changeHandler();
		_desc = desc;
	}
	/// ditto
	@property
	const
	string desc() { mixin(S_TRACE);
		return _desc;
	}

	/// 推奨レベル(低)
	@property
	void levelMin(uint levMin) { mixin(S_TRACE);
		if (_levMin != levMin) changeHandler();
		_levMin = levMin;
	}
	/// ditto
	@property
	const
	uint levelMin() { mixin(S_TRACE);
		return _levMin;
	}

	/// 推奨レベル(高)
	@property
	void levelMax(uint levMax) { mixin(S_TRACE);
		if (_levMax != levMax) changeHandler();
		_levMax = levMax;
	}
	/// ditto
	@property
	const
	uint levelMax() { mixin(S_TRACE);
		return _levMax;
	}

	/// 開始条件クーポンの必要数。
	@property
	void rCouponNum(uint rCouponNum) { mixin(S_TRACE);
		if (_rCouponNum != rCouponNum) changeHandler();
		_rCouponNum = rCouponNum;
	}
	/// ditto
	@property
	const
	uint rCouponNum() { mixin(S_TRACE);
		return _rCouponNum;
	}

	/// 開始条件クーポンの一覧。
	@property
	void rCoupons(string[] rCoupons) { mixin(S_TRACE);
		if (this.rCoupons != rCoupons) { mixin(S_TRACE);
			changeHandler();
			foreach (c; _rCoupons) { mixin(S_TRACE);
				c.removeUseCounter();
			}
			_rCoupons.length = rCoupons.length;
			foreach (i, ref c; _rCoupons) { mixin(S_TRACE);
				c = new CouponUser(this);
				c.coupon = rCoupons[i];
				if (useCounter) { mixin(S_TRACE);
					c.setUseCounter = useCounter;
				}
			}
		}
	}
	/// ditto
	@property
	const
	string[] rCoupons() { mixin(S_TRACE);
		auto r = new string[_rCoupons.length];
		foreach (i, ref c; r) { mixin(S_TRACE);
			c = _rCoupons[i].coupon;
		}
		return r;
	}

	/// シナリオの開始エリア。
	@property
	void startArea(ulong startAreaId) { mixin(S_TRACE);
		if (_startAreaId.area != startAreaId) changeHandler();
		_startAreaId.area = startAreaId;
	}
	/// ditto
	@property
	const
	ulong startArea() { mixin(S_TRACE);
		return _startAreaId.area;
	}

	/// シナリオに含まれるエリア。
	@property
	Area[] areas() { mixin(S_TRACE);
		return _area;
	}
	/// シナリオに含まれるパッケージ。
	@property
	Package[] packages() { mixin(S_TRACE);
		return _pkg;
	}
	/// シナリオに含まれるバトル。
	@property
	Battle[] battles() { mixin(S_TRACE);
		return _btl;
	}

	private static C find(C)(C[] arr, ulong id) { mixin(S_TRACE);
		auto index = qsearch!((a, b) => dcmp(a.id, b))(arr, id);
		return index == -1 ? null : arr[index];
	}

	/// キャスト。
	@property
	inout
	inout(CastCard)[] casts() { mixin(S_TRACE);
		return _cast;
	}
	/// ditto
	inout
	inout(CastCard) cwCast(ulong id) { mixin(S_TRACE);
		return find(_cast, id);
	}

	/// スキル。
	@property
	inout
	inout(SkillCard)[] skills() { mixin(S_TRACE);
		return _skl;
	}
	/// ditto
	inout
	inout(SkillCard) skill(ulong id) { mixin(S_TRACE);
		return find(_skl, id);
	}

	/// アイテム。
	@property
	inout
	inout(ItemCard)[] items() { mixin(S_TRACE);
		return _itm;
	}
	/// ditto
	inout
	inout(ItemCard) item(ulong id) { mixin(S_TRACE);
		return find(_itm, id);
	}

	/// 召喚獣。
	@property
	inout
	inout(BeastCard)[] beasts() { mixin(S_TRACE);
		return _bst;
	}
	/// ditto
	inout
	inout(BeastCard) beast(ulong id) { mixin(S_TRACE);
		return find(_bst, id);
	}

	/// 情報カード。
	@property
	inout
	inout(InfoCard)[] infos() { mixin(S_TRACE);
		return _info;
	}
	/// ditto
	inout
	inout(InfoCard) info(ulong id) { mixin(S_TRACE);
		return find(_info, id);
	}

	private static bool hasId(T)(const T[] arr, ulong id) { mixin(S_TRACE);
		return qsearch!((a, b) => dcmp(a.id, b))(arr, id) != -1;
	}

	/// 指定された要素のindexを検索する。
	const
	ptrdiff_t indexOf(T)(in T c) { mixin(S_TRACE);
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
		} else { mixin(S_TRACE);
			static assert (0);
		}
	}

	/// エリア。
	Area area(ulong id) { mixin(S_TRACE);
		return find(_area, id);
	}
	const
	const(Area) area(ulong id) { mixin(S_TRACE);
		return find!(const Area)(_area, id);
	}
	/// バトル。
	Battle battle(ulong id) { mixin(S_TRACE);
		return find(_btl, id);
	}
	const
	const(Battle) battle(ulong id) { mixin(S_TRACE);
		return find!(const Battle)(_btl, id);
	}
	/// パッケージ。
	Package cwPackage(ulong id) { mixin(S_TRACE);
		return find(_pkg, id);
	}
	const
	const(Package) cwPackage(ulong id) { mixin(S_TRACE);
		return find!(const Package)(_pkg, id);
	}

	/// 指定されたIDのエリア・バトル・パッケージがあればtrue。
	const
	bool hasAreaId(ulong id) { mixin(S_TRACE);
		return hasId!(const Area)(_area, id);
	}
	/// ditto
	const
	bool hasBattleId(ulong id) { mixin(S_TRACE);
		return hasId!(const Battle)(_btl, id);
	}
	/// ditto
	const
	bool hasPackageId(ulong id) { mixin(S_TRACE);
		return hasId!(const Package)(_pkg, id);
	}

	/// 指定された召喚獣カードと同等の性能を持つ召喚獣カードを探して返す。
	/// 見つからなければnullを返す。
	const
	const(BeastCard) findSameBeast(in BeastCard beast) { mixin(S_TRACE);
		if (0 != beast.linkId) { mixin(S_TRACE);
			return this.beast(beast.linkId);
		}
		foreach (b; _bst) { mixin(S_TRACE);
			if (beast.equalsExcludeId(b)) return b;
		}
		return null;
	}

	private static ulong newIdImpl(T)(in T[] arr) { mixin(S_TRACE);
		return arr.length > 0 ? arr[$ - 1].id + 1 : 1;
	}
	/// 今現在このシナリオに含まれていないTのIDを生成して返す。
	@property
	const
	ulong newId(T)() { mixin(S_TRACE);
		static if (is (T == CastCard)) {
			return newIdImpl!(const CastCard)(_cast);
		} else static if (is (T == SkillCard)) {
			return newIdImpl!(const SkillCard)(_skl);
		} else static if (is (T == ItemCard)) {
			return newIdImpl!(const ItemCard)(_itm);
		} else static if (is (T == BeastCard)) {
			return newIdImpl!(const BeastCard)(_bst);
		} else static if (is (T == InfoCard)) {
			return newIdImpl!(const InfoCard)(_info);
		} else static if (is (T == Area)) {
			return newIdImpl!(const Area)(_area);
		} else static if (is (T == Battle)) {
			return newIdImpl!(const Battle)(_btl);
		} else static if (is (T == Package)) {
			return newIdImpl!(const Package)(_pkg);
		} else { mixin(S_TRACE);
			static assert (0);
		}
	}
	/// ditto
	@property
	const
	ulong newAreaId() { mixin(S_TRACE);
		return newIdImpl!(const Area)(_area);
	}
	/// ditto
	@property
	const
	ulong newBattleId() { mixin(S_TRACE);
		return newIdImpl!(const Battle)(_btl);
	}
	/// ditto
	@property
	const
	ulong newPackageId() { mixin(S_TRACE);
		return newIdImpl!(const Package)(_pkg);
	}

	private ulong insertImpl(T, alias ToID)(ref T[] arr, int index, T c) { mixin(S_TRACE);
		if (arr.length == index) { mixin(S_TRACE);
			return addImpl!(T, ToID)(arr, c, true);
		} else { mixin(S_TRACE);
			ulong tempId = 0;
			bool remv = false;
			foreach (i, c_; arr) { mixin(S_TRACE);
				if (c_ is c) { mixin(S_TRACE);
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
			if ((0 < index && c.id <= arr[index - 1].id) || (index < arr.length && arr[index].id <= c.id)) {
				c.id = index == 0 ? 1L : arr[index - 1].id() + 1L;
			}
			arr = arr[0 .. index] ~ c ~ arr[index .. $];
			ulong chg[ulong];
			for (size_t i = index + 1; i < arr.length; i++) { mixin(S_TRACE);
				if (arr[i - 1].id == arr[i].id) { mixin(S_TRACE);
					ulong o = arr[i].id();
					arr[i].id = arr[i].id + 1L;
					chg[o] = arr[i].id;
				}
			}
			static if (is(typeof(c.hold))) {
				c.hold = false;
			}
			static if (is(typeof(c.linkId))) {
				c.linkId = 0;
			}
			c.setUseCounter = _uc;
			c.changeHandler = &changeHandler;
			c.owner = this;
			changeHandler();
			foreach_reverse (o; chg.keys.sort) { mixin(S_TRACE);
				_uc.change(ToID(o), ToID(chg[o]));
			}
			if (remv) { mixin(S_TRACE);
				_uc.change(ToID(tempId), ToID(c.id));
			}
			return oldId;
		}
	}
	/// このシナリオにカード・エリア等を挿入する。
	ulong insert(int index, CastCard c) { mixin(S_TRACE);
		return insertImpl!(CastCard, toCastId)(_cast, index, c);
	}
	/// ditto
	ulong insert(int index, SkillCard c) { mixin(S_TRACE);
		return insertImpl!(SkillCard, toSkillId)(_skl, index, c);
	}
	/// ditto
	ulong insert(int index, ItemCard c) { mixin(S_TRACE);
		return insertImpl!(ItemCard, toItemId)(_itm, index, c);
	}
	/// ditto
	ulong insert(int index, BeastCard c) { mixin(S_TRACE);
		return insertImpl!(BeastCard, toBeastId)(_bst, index, c);
	}
	/// ditto
	ulong insert(int index, InfoCard c) { mixin(S_TRACE);
		return insertImpl!(InfoCard, toInfoId)(_info, index, c);
	}
	/// ditto
	ulong insert(int index, Area c) { mixin(S_TRACE);
		return insertImpl!(Area, toAreaId)(_area, index, c);
	}
	/// ditto
	ulong insert(int index, Battle c) { mixin(S_TRACE);
		return insertImpl!(Battle, toBattleId)(_btl, index, c);
	}
	/// ditto
	ulong insert(int index, Package c) { mixin(S_TRACE);
		return insertImpl!(Package, toPackageId)(_pkg, index, c);
	}

	private ulong addImpl(T, alias ToID)(ref T[] arr, T area, bool forceNewId) { mixin(S_TRACE);
		if (arr.length > 0 && arr[$ - 1] is area) return area.id;
		auto oldId = area.id;
		auto newId = area.id;
		if (forceNewId || (arr.length > 0 && arr[$ - 1].id >= area.id) ) { mixin(S_TRACE);
			newId = newIdImpl(arr);
		}
		foreach (i, c_; arr) { mixin(S_TRACE);
			if (c_ is area) { mixin(S_TRACE);
				removeImpl(arr, area);
				_uc.change(ToID(oldId), ToID(newId));
				break;
			}
		}
		if (area.id != newId) area.id = newId;
		static if (is(typeof(area.hold))) {
			area.hold = false;
		}
		static if (is(typeof(area.linkId))) {
			area.linkId = 0;
		}
		arr ~= area;
		area.setUseCounter = _uc;
		area.changeHandler = &changeHandler;
		area.owner = this;
		area.changed();
		return oldId;
	}

	/// このシナリオにカード・エリア等を追加する。
	ulong add(Area area, bool forceNewId = true) { mixin(S_TRACE);
		auto id = addImpl!(Area, toAreaId)(_area, area, forceNewId);
		if (areas.length == 1) { mixin(S_TRACE);
			startArea = area.id;
		}
		return id;
	}
	/// ditto
	ulong add(Battle btl, bool forceNewId = true) { mixin(S_TRACE);
		return addImpl!(Battle, toBattleId)(_btl, btl, forceNewId);
	}
	/// ditto
	ulong add(Package pkg, bool forceNewId = true) { mixin(S_TRACE);
		return addImpl!(Package, toPackageId)(_pkg, pkg, forceNewId);
	}
	/// ditto
	ulong add(CastCard c, bool forceNewId = true) { mixin(S_TRACE);
		return addImpl!(CastCard, toCastId)(_cast, c, forceNewId);
	}
	/// ditto
	ulong add(SkillCard c, bool forceNewId = true) { mixin(S_TRACE);
		return addImpl!(SkillCard, toSkillId)(_skl, c, forceNewId);
	}
	/// ditto
	ulong add(ItemCard c, bool forceNewId = true) { mixin(S_TRACE);
		return addImpl!(ItemCard, toItemId)(_itm, c, forceNewId);
	}
	/// ditto
	ulong add(BeastCard c, bool forceNewId = true) { mixin(S_TRACE);
		return addImpl!(BeastCard, toBeastId)(_bst, c, forceNewId);
	}
	/// ditto
	ulong add(InfoCard c, bool forceNewId = true) { mixin(S_TRACE);
		return addImpl!(InfoCard, toInfoId)(_info, c, forceNewId);
	}

	private void removeImpl(T)(ref T[] arr, T area) { mixin(S_TRACE);
		auto i = qsearch!((a, b) => dcmp(a.id, b.id))(arr, area);
		if (i == -1) return;
		arr = arr[0 .. i] ~ arr[i + 1 .. $];
		area.removeUseCounter();
		area.changeHandler = null;
		area.owner = null;
		changeHandler();
	}

	/// カード・エリア等を除去する。
	void remove(CastCard c) { mixin(S_TRACE);
		removeImpl(_cast, c);
	}
	/// ditto
	void remove(SkillCard c) { mixin(S_TRACE);
		removeImpl(_skl, c);
	}
	/// ditto
	void remove(ItemCard c) { mixin(S_TRACE);
		removeImpl(_itm, c);
	}
	/// ditto
	void remove(BeastCard c) { mixin(S_TRACE);
		removeImpl(_bst, c);
	}
	/// ditto
	void remove(InfoCard c) { mixin(S_TRACE);
		removeImpl(_info, c);
	}
	/// ditto
	void remove(Area a) { mixin(S_TRACE);
		removeImpl(_area, a);
		if (a.id == startArea) { mixin(S_TRACE);
			startArea = areas.length > 0 ? areas[0].id : 0;
		}
	}
	/// ditto
	void remove(Battle a) { mixin(S_TRACE);
		removeImpl(_btl, a);
	}
	/// ditto
	void remove(Package a) { mixin(S_TRACE);
		removeImpl(_pkg, a);
	}
	/// ditto
	void remove(AbstractArea area) { mixin(S_TRACE);
		if (cast(Area) area) { mixin(S_TRACE);
			remove(cast(Area) area);
		} else if (cast(Package) area) { mixin(S_TRACE);
			remove(cast(Package) area);
		} else { mixin(S_TRACE);
			assert (cast(Battle) area);
			remove(cast(Battle) area);
		}
	}

	/// index1とindex2を交換する。
	void swap(A)(int index1, int index2) { mixin(S_TRACE);
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

	/// シナリオに付属するイベントテンプレート。
	@property
	void eventTemplates(EvTemplate[] v) { mixin(S_TRACE);
		if (_eventTemplates != v) { mixin(S_TRACE);
			changeHandler();
			_eventTemplates = v;
		}
	}
	/// ditto
	@property
	inout
	inout(EvTemplate)[] eventTemplates() { return _eventTemplates; }

	const
	private string summaryToXML(in XMLOption opt) { mixin(S_TRACE);
		auto root = XNode.create("Summary");
		if (dataVersion != "") root.newAttr("dataVersion", dataVersion);
		auto pNode = root.newElement("Property");
		pNode.newElement("Name", _sname);
		CardImage.toNode(pNode, _imgPaths);
		pNode.newElement("Author", _author);
		pNode.newElement("Description", encodeLf(_desc));
		auto lv = pNode.newElement("Level");
		lv.newAttr("min", _levMin);
		lv.newAttr("max", _levMax);
		auto rc = pNode.newElement("RequiredCoupons", encodeLf(rCoupons));
		rc.newAttr("number", _rCouponNum);
		pNode.newElement("StartAreaId", _startAreaId.area);
		pNode.newElement("Tags");
		pNode.newElement("Type", _type);
		flagDirRoot.toNodeAll(root);
		root.newElement("Labels");
		auto et = root.newElement("EventTemplates");
		foreach (t; _eventTemplates) { mixin(S_TRACE);
			t.toNode(et);
		}
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
	string[string][string] toXMLs(const System sys) { mixin(S_TRACE);
		auto opt = new XMLOption(sys, dataVersion);
		opt.includeCard = !isTargetVersion("1");
		opt.skill = (id) => this.skill(id);
		opt.item = (id) => this.item(id);
		opt.beast = (id) => this.beast(id);

		string e = "";
		string[string] s = ["Summary.xml":summaryToXML(opt)];
		string[string][string] r = [e:s];

		void put(string parent, string[string] p) { mixin(S_TRACE);
			if (p.length) { mixin(S_TRACE);
				r[parent] = p;
			}
		}
		put(PATH_AREA, toXMLsImpl!(const Area)(_area, opt));
		put(PATH_BATTLE, toXMLsImpl!(const Battle)(_btl, opt));
		put(PATH_PACKAGE, toXMLsImpl!(const Package)(_pkg, opt));

		put(PATH_CAST, toXMLsImpl!(const CastCard)(_cast, opt));
		put(PATH_SKILL, toXMLsImpl!(const SkillCard)(_skl, opt));
		put(PATH_ITEM, toXMLsImpl!(const ItemCard)(_itm, opt));
		put(PATH_BEAST, toXMLsImpl!(const BeastCard)(_bst, opt));
		put(PATH_INFO, toXMLsImpl!(const InfoCard)(_info, opt));

		return r;
	}
	private static string[string] toXMLsImpl(A)(in A[] targs, XMLOption opt) { mixin(S_TRACE);
		string[string] r;
		foreach (targ; targs) { mixin(S_TRACE);
			auto fname = format("%02d", targ.id) ~ ".xml";
			r[fname] = targ.toXML(opt);
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
	void saveXMLs(string path, const System sys, in SaveOption opt) { mixin(S_TRACE);
		saveXMLsImpl(path, sys, opt, true);
	}
	private void saveXMLsImpl(string path, const System sys, in SaveOption opt, bool callSaved) { mixin(S_TRACE);
		if (callSaved) _inSaving = true;
		scope (exit) {
			if (callSaved) {
				_inSaving = false;
				if (opt.savedCallback) opt.savedCallback();
			}
		}
		string summFile = std.path.buildPath(path, "Summary.xml");

		bool canBackup = opt.backup && (!opt.backupDir.exists() || opt.backupDir.isDir());
		if (canBackup) { mixin(S_TRACE);
			foreach (file; clistdir(opt.backupDir)) { mixin(S_TRACE);
				.delAll(opt.backupDir.buildPath(file));
			}
			if (summFile.exists() && !summFile.isDir()) { mixin(S_TRACE);
				summFile.copy(opt.backupDir.buildPath(summFile.baseName()));
			}
		}

		auto xOpt = new XMLOption(sys, dataVersion);
		xOpt.includeCard = !isTargetVersion("1");
		xOpt.skill = (id) => skill(id);
		xOpt.item = (id) => item(id);
		xOpt.beast = (id) => beast(id);
		std.file.write(summFile, summaryToXML(xOpt));

		HashSet!Object changed = null;
		if (opt.saveChangedOnly) changed = changedResources;
		saveXML(std.path.buildPath(path, PATH_AREA), _area, opt, xOpt, changed);
		saveXML(std.path.buildPath(path, PATH_BATTLE), _btl, opt, xOpt, changed);
		saveXML(std.path.buildPath(path, PATH_PACKAGE), _pkg, opt, xOpt, changed);

		saveXML(std.path.buildPath(path, PATH_CAST), _cast, opt, xOpt, changed);
		saveXML(std.path.buildPath(path, PATH_SKILL), _skl, opt, xOpt, changed);
		saveXML(std.path.buildPath(path, PATH_ITEM), _itm, opt, xOpt, changed);
		saveXML(std.path.buildPath(path, PATH_BEAST), _bst, opt, xOpt, changed);
		saveXML(std.path.buildPath(path, PATH_INFO), _info, opt, xOpt, changed);
	}
	/// ditto
	void saveXMLs(const System sys, in SaveOption opt) { mixin(S_TRACE);
		saveXMLs(_sPath, sys, opt);
	}
	private static void delAllXML(A)(string p, in A[string] saveSet, in SaveOption opt) { mixin(S_TRACE);
		bool canBackup = opt.backup && (!opt.backupDir.exists() || opt.backupDir.isDir());
		string backupDir = "";
		if (canBackup) { mixin(S_TRACE);
			backupDir = opt.backupDir.buildPath(p.baseName());
		}
		foreach (t; clistdir(p)) { mixin(S_TRACE);
			auto file = std.path.buildPath(p, t);
			if (saveSet && t in saveSet) continue;
			if (isDir(file) || !cfnmatch(.extension(file), ".xml")) continue;

			if (canBackup) { mixin(S_TRACE);
				if (!backupDir.exists()) backupDir.mkdirRecurse();
				auto backFile = backupDir.buildPath(t);
				file.copy(backFile);
			}

			std.file.remove(file);
		}
	}
	private static void saveXML(A)(string path, A[] targs, in SaveOption opt, XMLOption xOpt, HashSet!Object changed) { mixin(S_TRACE);
		if (targs.length == 0) { mixin(S_TRACE);
			if (exists(path) && isDir(path)) { mixin(S_TRACE);
				delAllXML!Object(path, null, opt);
				if (clistdir(path).length == 0) { mixin(S_TRACE);
					rmdir(path);
				}
			}
		} else { mixin(S_TRACE);
			A[string] saveSet;
			foreach (targ; targs) { mixin(S_TRACE);
				auto p = createFileI(path, targ.name, ".xml", format("%02d", targ.id) ~ "_", true);
				saveSet[p.baseName()] = targ;
			}
			if (exists(path) && isDir(path)) { mixin(S_TRACE);
				delAllXML!A(path, saveSet, opt);
			} else { mixin(S_TRACE);
				mkdir(path);
			}
			foreach (name, a; saveSet) { mixin(S_TRACE);
				auto p = path.buildPath(name);
				if (!opt.saveChangedOnly || !p.exists() || !p.isFile() || changed.contains(cast(Object)a)) { mixin(S_TRACE);
					std.file.write(p, a.toXML(xOpt));
				}
			}
		}
	}

	private static Summary summaryFromXML(const System sys, string sPath, string xml) { mixin(S_TRACE);
		scope summNode = XNode.parse(xml);
		if (summNode.name == "Summary") { mixin(S_TRACE);
			auto summ = new Summary(sPath);
			summ.dataVersion = summNode.attr("dataVersion", false, "");
			summNode.onTag["Property"] = (ref XNode propNode) { mixin(S_TRACE);
				propNode.onTag["Name"] = (ref XNode node) {summ._sname = node.value;};
				CardImage[] paths;
				CardImage.setOnTag(propNode, paths);
				propNode.onTag["Author"] = (ref XNode node) {summ._author = node.value;};
				propNode.onTag["Description"] = (ref XNode node) {summ._desc = decodeLf2(node.value);};
				propNode.onTag["Level"] = (ref XNode node) { mixin(S_TRACE);
					summ._levMin = node.attr!(uint)("min", true);
					summ._levMax = node.attr!(uint)("max", true);
				};
				string[] rCoupons;
				propNode.onTag["RequiredCoupons"] = (ref XNode node) { mixin(S_TRACE);
					summ._rCouponNum = node.attr!(uint)("number", true);
					rCoupons = decodeLf(node.value);
				};
				propNode.onTag["StartAreaId"] = (ref XNode node) {summ._startAreaId.area = node.valueTo!(ulong);};
				propNode.onTag["Type"] = (ref XNode node) {summ._type = node.value;};
				propNode.parse();
				summ.imagePaths = paths;
				summ.rCoupons = rCoupons;
			};
			EvTemplate[] evTemps;
			summNode.onTag["EventTemplates"] = (ref XNode node) { mixin(S_TRACE);
				node.onTag["eventTemplate"] = (ref XNode node) { mixin(S_TRACE);
					EvTemplate tmpl;
					tmpl.fromNode(node);
					evTemps ~= tmpl;
				};
				node.parse();
			};
			summ._froot = FlagDir.fromXmlNode(summNode, summ, &summ.changeHandler, new XMLInfo(sys, summ.dataVersion));
			summ._eventTemplates = evTemps;
			return summ;
		}
		throw new SummaryException("File is not summary: " ~ sPath);
	}
	private void checkStartArea() { mixin(S_TRACE);
		if (hasId(areas, startArea)) {
			_startAreaId.area = areas.length > 0 ? areas[0].id : 0;
		}
	}

	private void loadXMLCommon(A)(string xml, string name, ref A[] areas,
			UseCounter uc, void delegate() change, in XMLInfo ver) { mixin(S_TRACE);
		auto doc = XNode.parse(xml);
		if (doc.name == name) { mixin(S_TRACE);
			auto area = A.createFromNode(doc, ver);
			if (uc) area.setUseCounter = uc;
			if (change) area.changeHandler = change;
			area.owner = this;
			areas ~= area;
		}
	}
	private void loadXML1(A)(string targPath, string name, ref A[] areas,
			UseCounter uc, void delegate() change, in XMLInfo ver) { mixin(S_TRACE);
		if (exists(targPath)) { mixin(S_TRACE);
			foreach (p; clistdir(targPath)) { mixin(S_TRACE);
				p = std.path.buildPath(targPath, p);
				if (!isDir(p) && cfnmatch(.extension(p), ".xml")) { mixin(S_TRACE);
					try { mixin(S_TRACE);
						loadXMLCommon(std.file.readText(p), name, areas, uc, change, ver);
					} catch (Exception e) {
						printStackTrace();
						debugln(e);
						throw new FileLoadException(p, e);
					}
				}
			}
			// ID順でソート。
			areas.sort;
		}
	}
	private void loadXML2(A)(string[string][string] xmls,
			string dirName, string name, ref A[] areas,
			UseCounter uc, void delegate() change, in XMLInfo ver) { mixin(S_TRACE);
		auto dir = dirName in xmls;
		if (!dir) return;
		foreach (file, xml; *dir) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				loadXMLCommon(xml, name, areas, uc, change, ver);
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
				throw new Exception(std.path.buildPath(dirName, file));
			}
		}
		// ID順でソート。
		areas.sort;
	}

	/// XMLを元にしたインスタンス。
	/// Params:
	/// sPath = シナリオディレクトリのパス。
	/// xmls = シナリオの各XMLデータ。
	/// Throws:
	/// SummaryException = xmlsにSummary定義のXML文書が含まれていない、または壊れている。
	/// XmlException = XMLパースエラー発生時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	private static Summary fromXMLs(const System sys, string sPath, string[string][string] xmls, in LoadOption opt) { mixin(S_TRACE);
		auto parent = "" in xmls;
		if (!parent) throw new SummaryException("invalid xmls");
		auto summXML = "Summary.xml" in *parent;
		if (!summXML) throw new SummaryException("invalid parent of xmls");
		Summary summ = summaryFromXML(sys, sPath, *summXML);

		auto ver = new XMLInfo(sys, summ.dataVersion);
		if (opt.summaryOnly) return summ;
		if (!opt.cardOnly) { mixin(S_TRACE);
			summ.loadXML2(xmls, PATH_AREA, "Area", summ._area, summ.useCounter, &summ.changeHandler, ver);
			summ.checkStartArea();
			summ.loadXML2(xmls, PATH_BATTLE, "Battle", summ._btl, summ.useCounter, &summ.changeHandler, ver);
			summ.loadXML2(xmls, PATH_PACKAGE, "Package", summ._pkg, summ.useCounter, &summ.changeHandler, ver);
		}

		summ.loadXML2(xmls, PATH_CAST, "CastCard", summ._cast, summ.useCounter, &summ.changeHandler, ver);
		summ.loadXML2(xmls, PATH_SKILL, "SkillCard", summ._skl, summ.useCounter, &summ.changeHandler, ver);
		summ.loadXML2(xmls, PATH_ITEM, "ItemCard", summ._itm, summ.useCounter, &summ.changeHandler, ver);
		summ.loadXML2(xmls, PATH_BEAST, "BeastCard", summ._bst, summ.useCounter, &summ.changeHandler, ver);
		summ.loadXML2(xmls, PATH_INFO, "InfoCard", summ._info, summ.useCounter, &summ.changeHandler, ver);

		return summ;
	}
	private static void fromXMLs(const System sys, Summary summ, in LoadOption opt) { mixin(S_TRACE);
		if (opt.summaryOnly) return;
		auto path = summ.scenarioPath;
		auto ver = new XMLInfo(sys, summ.dataVersion);
		if (!opt.cardOnly) { mixin(S_TRACE);
			summ.loadXML1(std.path.buildPath(path, PATH_AREA), "Area", summ._area, summ.useCounter, &summ.changeHandler, ver);
			summ.checkStartArea();
			summ.loadXML1(std.path.buildPath(path, PATH_BATTLE), "Battle", summ._btl, summ.useCounter, &summ.changeHandler, ver);
			summ.loadXML1(std.path.buildPath(path, PATH_PACKAGE), "Package", summ._pkg, summ.useCounter, &summ.changeHandler, ver);
		}

		summ.loadXML1(std.path.buildPath(path, PATH_CAST), "CastCard", summ._cast, summ.useCounter, &summ.changeHandler, ver);
		summ.loadXML1(std.path.buildPath(path, PATH_SKILL), "SkillCard", summ._skl, summ.useCounter, &summ.changeHandler, ver);
		summ.loadXML1(std.path.buildPath(path, PATH_ITEM), "ItemCard", summ._itm, summ.useCounter, &summ.changeHandler, ver);
		summ.loadXML1(std.path.buildPath(path, PATH_BEAST), "BeastCard", summ._bst, summ.useCounter, &summ.changeHandler, ver);
		summ.loadXML1(std.path.buildPath(path, PATH_INFO), "InfoCard", summ._info, summ.useCounter, &summ.changeHandler, ver);
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
	private static Summary fromXMLs(const System sys, string path, in LoadOption opt) { mixin(S_TRACE);
		auto summ = summaryFromXML(sys, dirName(path), std.file.readText(path));
		if (opt.summaryOnly) return summ;
		fromXMLs(sys, summ, opt);
		return summ;
	}

	/// XMLファイルまたはクラシックなシナリオを再読込し、新しいSummaryを生成して返す。
	Summary reloadXMLs(const System sys, in LoadOption opt) { mixin(S_TRACE);
		Summary summ;
		if (legacy) { mixin(S_TRACE);
			summ = loadLScenario(scenarioPath, "", sys, opt, scenarioName);
		} else { mixin(S_TRACE);
			summ = summaryFromXML(sys, scenarioPath,
				std.file.readText(std.path.buildPath(scenarioPath, "Summary.xml")));
			fromXMLs(sys, summ, opt);
		}
		summ._expandXMLs = expandXMLs;
		summ._zipName = zipName;
		summ._origZipName = zipName;
		summ._useTemp = useTemp;
		summ._legacy = legacy;
		if (useTemp) { mixin(S_TRACE);
			summ._lock = _lock;
		}
		summ.refCheckPaths();
		return summ;
	}

	/// フラグとステップのルートディレクトリ。
	@property
	inout
	inout(FlagDir) flagDirRoot() { mixin(S_TRACE);
		return _froot;
	}

	/// シナリオのディレクトリ。
	@property
	const
	string scenarioPath() { mixin(S_TRACE);
		return _sPath;
	}
	/// シナリオのディレクトリ。
	@property
	void scenarioPath(string sPath) { mixin(S_TRACE);
		_sPath = sPath;
	}
	/// シナリオ名。
	@property
	const
	string scenarioName() { mixin(S_TRACE);
		return _sname;
	}
	/// ditto
	@property
	void scenarioName(string scenarioName) { mixin(S_TRACE);
		setBaseParams(scenarioName, author);
	}

	/// カード画像のマップを生成して返す。
	const
	private string[][immutable(ubyte[])] cardImgTable(string mtdir, in Skin skin, UseCounter uc, out ubyte*[] ptrs) { mixin(S_TRACE);
		string[][immutable(ubyte[])] r;
		foreach (file; clistdir(mtdir)) { mixin(S_TRACE);
			if (skin.isCardImage(std.path.buildPath(mtdir, file), true)) { mixin(S_TRACE);
				ubyte* ptr = null;
				auto mBytes = readBinaryFrom!ubyte(std.path.buildPath(mtdir, file), ptr);
				ptrs ~= ptr;
				auto bytes = assumeUnique(mBytes);
				r[bytes] ~= std.path.buildPath(skin.materialPath, file);
			}
		}
		foreach (key, v; r.values) { mixin(S_TRACE);
			if (v.length > 1u) { mixin(S_TRACE);
				string[] nv;
				foreach (file; v) { mixin(S_TRACE);
					if (!cwx.utils.istartsWith(baseName(file), "font_")) { mixin(S_TRACE);
						/// font_X.bmpはやむを得ずコピーした可能性があるため優先的に除外
						nv ~= file;
					}
				}
				r.values[key] = nv;
			}
			if (v.length > 1u) { mixin(S_TRACE);
				string[] nv;
				int maxCount = -1;
				foreach (file; v) { mixin(S_TRACE);
					/// 使用回数が多い方を優先
					int c = cast(int) uc.path.values(toPathId(file)).length;
					if (c >= maxCount) { mixin(S_TRACE);
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
	private bool moveBinImg(ref string[][immutable(ubyte[])] cis, PathUser targ, string fname, string mt, in Skin toSkin) { mixin(S_TRACE);
		string img = targ.path;
		if (isBinImg(img)) { mixin(S_TRACE);
			auto bytes = strToBImg(img);
			string[] *files = bytes in cis;
			if (files) { mixin(S_TRACE);
				assert (files.length);
				targ.path = (*files)[0u];
			} else { mixin(S_TRACE);
				auto file = createFileI(mt, fname, ".bmp", "", false);
				std.file.write(file, bytes);
				targ.path = std.path.buildPath(toSkin.materialPath, baseName(file));
				cis[assumeUnique(bytes)] ~= targ.path;
				return true;
			}
		}
		return false;
	}
	/// クラシックなシナリオをXML形式のシナリオに変換する。
	public string classicToX(in CProps prop, string temp, string tempPath, in Skin toSkin, out string[] copyFail) { mixin(S_TRACE);
		.enforce(legacy);
		copyFail = [];
		auto uc = useCounter;
		string mt;
		if (std.path.buildPath(scenarioPath, toSkin.materialPath).exists()) { mixin(S_TRACE);
			// 元々Materialディレクトリが存在する
			mt = temp;
		} else { mixin(S_TRACE);
			mt = std.path.buildPath(temp, toSkin.materialPath);
			try { mixin(S_TRACE);
				if (!mt.exists()) mkdirRecurse(mt);
			} catch (Exception e) {
				// 稀な条件でMaterialだけ生成されない場合がある模様
				printStackTrace();
				debugln(e);
			}
			if (!.exists(mt)) { mixin(S_TRACE);
				mt = temp;
			}
		}
		foreach (file; clistdir(scenarioPath)) { mixin(S_TRACE);
			if (cfnmatch(file, "cwxeditor.lock")) { mixin(S_TRACE);
				continue;
			}
			auto p = std.path.buildPath(scenarioPath, file);
			try { mixin(S_TRACE);
				if (isDir(p)) { mixin(S_TRACE);
					auto top = std.path.buildPath(mt, baseName(p));
					mkdir(top);
					copyAll(p, top, true);
				} else if (!cfnmatch(.extension(p), ".wsm") && !cfnmatch(.extension(p), ".wid") && !cfnmatch(.extension(p), ".wex")) { mixin(S_TRACE);
					if (toSkin.isCardImage(p, true)
							|| toSkin.isBgImage(p)
							|| toSkin.isBGM(p)
							|| toSkin.isSE(p)) { mixin(S_TRACE);
						copy(p, std.path.buildPath(mt, baseName(p)));
					} else { mixin(S_TRACE);
						copy(p, std.path.buildPath(temp, baseName(p)));
					}
				}
			} catch (Exception ex) {
				printStackTrace();
				debugln(ex);
				copyFail ~= p;
			}
		}
		if (!mt.cfnmatch(temp)) { mixin(S_TRACE);
			foreach (key; uc.path.keys) { mixin(S_TRACE);
				if (key.isBinImg) continue;
				auto p = std.path.buildPath(scenarioPath, cast(string)key);
				if (p.exists()) { mixin(S_TRACE);
					uc.change(key, toPathId(std.path.buildPath(toSkin.materialPath, cast(string)key)));
				}
			}
			ubyte*[] ptrs;
			auto table = cardImgTable(mt, toSkin, uc, ptrs);
			foreach (p; uc.path.keys) { mixin(S_TRACE);
				if (p.isBinImg) { mixin(S_TRACE);
					int i = 0;
					foreach (ipu; uc.path.values(p)) { mixin(S_TRACE);
						auto v = cast(PathUser)ipu;
						assert (v);
						if (moveBinImg(table, v, "@simage(" ~ to!(string)(i + 1) ~ ")", mt, toSkin)) { mixin(S_TRACE);
							i++;
						}
					}
				}
			}
			freeAll(ptrs);
		}
		return temp;
	}
	/// 新規にシナリオのディレクトリを作成し、現在のファイルをコピーする。
	private string toNewDirectory(in CProps prop, string fileOrDir, string tempPath, out string[] copyFail, out bool useTemp) { mixin(S_TRACE);
		copyFail = [];
		bool isDir;
		string sPath, zipName;
		string ext = fileOrDir.extension();
		string baseName = fileOrDir.baseName();
		if (.cfnmatch(baseName, "Summary.wsm") || .cfnmatch(baseName, "Summary.xml")) { mixin(S_TRACE);
			isDir = true;
			sPath = fileOrDir.dirName();
			zipName = "";
			_origZipName = "";
		} else if (!(.exists(fileOrDir) && .isDir(fileOrDir)) && (ext.cfnmatch(".zip") || ext.cfnmatch(".cab") || ext.cfnmatch(".wsn"))) { mixin(S_TRACE);
			isDir = false;
			sPath = Summary.createTempDirFromName(tempPath, fileOrDir.baseName().stripExtension());
			zipName = fileOrDir;
			_origZipName = fileOrDir;
		} else { mixin(S_TRACE);
			isDir = true;
			sPath = fileOrDir;
			zipName = "";
			_origZipName = fileOrDir;
		}
		auto list = clistdir(scenarioPath);
		if (!.exists(sPath)) mkdirRecurse(sPath);
		useTemp = !isDir;
		foreach (file; list) { mixin(S_TRACE);
			string p;
			try { mixin(S_TRACE);
				auto full = scenarioPath.buildPath(file);
				if (isSystemFile(full)) continue;
				p = sPath.buildPath(file);
				full.copyAll(p, true);
			} catch (Exception ex) {
				printStackTrace();
				debugln(ex);
				copyFail ~= p;
			}
		}
		return sPath;
	}
	/// 保存場所が決まっている場合はtrue。
	@property
	const
	bool isSaved() { mixin(S_TRACE);
		return !useTemp || zipName.length;
	}
	/// 上書き保存。
	void saveOverwrite(in CProps prop, in Skin skin, in SaveOption opt) in { mixin(S_TRACE);
		assert (isSaved);
	} body { mixin(S_TRACE);
		saveProc(prop, skin, opt, useTemp, zipName, scenarioPath, scenarioPath, legacy, false, expandXMLs, false);
	}
	/// 名前をつけて保存。
	void saveWithName(in CProps prop, in Skin skin, in SaveOption opt, string fname, string tempPath,
			bool defExpandXMLs, Skin defSkin, void delegate(string) showWarn, bool classic) { mixin(S_TRACE);
		SaveOption opt2 = opt;
		opt2.saveChangedOnly = false; // 部分保存ができるのは上書き時のみ
		if (classic) { mixin(S_TRACE);
			// クラシック形式で保存
			string[] copyFail;
			bool useTemp;
			auto sPath = toNewDirectory(prop, fname, tempPath, copyFail, useTemp);
			foreach (fail; copyFail) { mixin(S_TRACE);
				// 一部コピー失敗しても中断しない
				showWarn(.tryFormat(prop.msgs.fileCopyError, fail));
			}
			string zipName = useTemp ? fname : "";
			string temp = sPath;
			scope (failure) {
				if (useTemp) delAll(temp);
			}
			saveProc(prop, skin, opt2, useTemp, zipName, temp, sPath, true, false, defExpandXMLs, true);
		} else if (fname.baseName().cfnmatch("Summary.xml") || (fname.exists() && fname.isDir())) { mixin(S_TRACE);
			// 新しく指定ディレクトリに保存(クラシック形式からXML形式への変換も含む)
			string[] copyFail;
			bool useTemp = false;
			string sPath;
			string temp = (fname.exists() && fname.isDir()) ? fname : fname.dirName();
			if (!temp.exists()) temp.mkdirRecurse();
			bool toX = false;
			if (this.legacy) { mixin(S_TRACE);
				sPath = classicToX(prop, temp, tempPath, defSkin, copyFail);
				toX = true;
			} else { mixin(S_TRACE);
				sPath = toNewDirectory(prop, fname, tempPath, copyFail, useTemp);
			}
			foreach (fail; copyFail) { mixin(S_TRACE);
				// 一部コピー失敗しても中断しない
				showWarn(.tryFormat(prop.msgs.fileCopyError, fail));
			}
			assert (!useTemp);
			string zipName = "";
			saveProc(prop, skin, opt2, useTemp, zipName, temp, sPath, false, false, defExpandXMLs, true, { mixin(S_TRACE);
				if (!type.length) { mixin(S_TRACE);
					type = defSkin.type;
					resetChanged();
				}
			});
		} else if (this.legacy) { mixin(S_TRACE);
			// クラシック形式からXML形式に変換
			string[] copyFail;
			auto temp = Summary.createTempDir(tempPath, zipName ? zipName.baseName().stripExtension() : scenarioPath.dirName().baseName());
			temp = classicToX(prop, temp, tempPath, defSkin, copyFail);
			foreach (fail; copyFail) { mixin(S_TRACE);
				// 一部コピー失敗しても中断しない
				showWarn(.tryFormat(prop.msgs.fileCopyError, fail));
			}
			scope (failure) delAll(temp);
			if (!type.length) type = defSkin.type;
			saveProc(prop, skin, opt2, true, fname, temp, scenarioPath, legacy, true, defExpandXMLs, true);
		} else if (useTemp) { mixin(S_TRACE);
			// 新しいアーカイブを作成
			string oldZip = _zipName;
			string oldOrigZip = _origZipName;
			_zipName = fname;
			_origZipName = fname;
			scope (failure) {
				_zipName = oldZip;
				_origZipName = oldOrigZip;
			}
			saveProc(prop, skin, opt2, false, zipName, scenarioPath, scenarioPath, legacy, false, defExpandXMLs, true);
		} else { mixin(S_TRACE);
			// 展開済みシナリオからアーカイブに変換
			auto oldPath = scenarioPath;
			auto p = createTempDir(tempPath, oldPath.dirName().baseName());
			copyAll(oldPath, p);
			scenarioPath = p;
			scope (failure) {
				scenarioPath = oldPath;
				delAll(p);
			}
			saveProc(prop, skin, opt2, true, fname, p, scenarioPath, legacy, false, defExpandXMLs, true);
		}
	}
	private void saveProc(in CProps prop, in Skin skin, in SaveOption opt, bool archive,
			string zipName, string temp, string sPath, bool legacy, bool legacyToX, bool defExpandXMLs, bool releaseLock, void delegate() after = null) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			_inSaving = true;
			auto callSaved = true;
			scope (exit) {
				if (after) after();
				if (callSaved) {
					_inSaving = false;
					if (opt.savedCallback) opt.savedCallback();
				}
			}
			void releaseLockFile() { mixin(S_TRACE);
				if (releaseLock && _lock.isOpen) { mixin(S_TRACE);
					_lock.close();
				}
			}
			bool expand = false;
			if (legacy && !legacyToX) { mixin(S_TRACE);
				auto oldPath = scenarioPath;
				scenarioPath = sPath;
				scope (failure) scenarioPath = oldPath;
				saveLScenario(this, skin, prop.sys, opt);
				bool useTemp = archive;
				.enforce(useTemp == (0 < zipName.length));
				if (useTemp) { mixin(S_TRACE);
					void t1() { mixin(S_TRACE);
						scope (exit) {
							_inSaving = false;
							if (opt.savedCallback) opt.savedCallback();
						}
						if (cfnmatch(.extension(zipName), ".cab")) { mixin(S_TRACE);
							.cab(temp, zipName, (string file) { mixin(S_TRACE);
								return !cfnmatch(baseName(file), "cwxeditor.lock");
							});
						} else { mixin(S_TRACE);
							.zip(temp, zipName, true, [std.path.buildPath(temp, "cwxeditor.lock")], true);
						}
						releaseLockFile();
						if (useTemp && !_lock.isOpen) { mixin(S_TRACE);
							lock(sPath, useTemp);
						}
					}
					if (opt.archiveInNewThread) { mixin(S_TRACE);
						.task(&t1).executeInNewThread();
						callSaved = false;
					} else { mixin(S_TRACE);
						t1();
					}
				} else { mixin(S_TRACE);
					releaseLockFile();
					if (useTemp && !_lock.isOpen) { mixin(S_TRACE);
						lock(sPath, useTemp);
					}
				}
				_expandXMLs = false;
				_useTemp = useTemp;
				_zipName = zipName;
				_origZipName = zipName;
				_tempPath = temp;
				_legacy = true;
				_type = "";
			} else if (archive || useTemp || legacyToX) { mixin(S_TRACE);
				auto oldPath = scenarioPath;
				if (expandXMLs) { mixin(S_TRACE);
					saveXMLsImpl(_sPath, prop.sys, opt, false);
					expand = true;
				} else if (legacyToX && defExpandXMLs) { mixin(S_TRACE);
					scenarioPath = temp;
					saveXMLsImpl(_sPath, prop.sys, opt, false);
					expand = true;
				} else if (legacyToX) { mixin(S_TRACE);
					scenarioPath = temp;
				}
				scope (failure) scenarioPath = oldPath;
				void t2() { mixin(S_TRACE);
					scope (exit) {
						_inSaving = false;
						if (opt.savedCallback) opt.savedCallback();
					}
					auto lock = std.path.buildPath(scenarioPath, "cwxeditor.lock");
					ubyte*[] data;
					scope arc = .zip(scenarioPath, false, [lock], false, data);
					if (!expand) { mixin(S_TRACE);
						auto xmls = toXMLs(prop.sys);
						foreach (path, files; xmls) { mixin(S_TRACE);
							foreach (name, xml; files) { mixin(S_TRACE);
								auto p = std.path.buildPath(path, name);
								arc.addMember(.archive(p, cast(ubyte[]) xml, false));
							}
						}
						_oldXMLs = xmls;
					}
					auto b = arc.build();
					std.file.write(zipName, b);
					destroy(arc);
					freeAll(data);
				}
				if (opt.archiveInNewThread) { mixin(S_TRACE);
					.task(&t2).executeInNewThread();
					callSaved = false;
				} else { mixin(S_TRACE);
					t2();
				}
			} else if (expandXMLs || !useTemp) { mixin(S_TRACE);
				auto oldPath = scenarioPath;
				scenarioPath = sPath;
				scope (failure) scenarioPath = oldPath;
				saveXMLsImpl(_sPath, prop.sys, opt, false);
				releaseLockFile();
				_useTemp = useTemp;
				_zipName = zipName;
				_origZipName = zipName;
				_tempPath = temp;
				_legacy = false;
			}
			if (legacyToX) dataVersion = DEFAULT_VERSION;
			if (legacyToX || (!useTemp && archive)) { mixin(S_TRACE);
				_useTemp = true;
				refCheckPaths();
				resetChanged();
				void t3() { mixin(S_TRACE);
					scope (exit) {
						_inSaving = false;
						if (opt.savedCallback) opt.savedCallback();
					}
					toArchive(zipName, temp, expand);
				}
				if (opt.archiveInNewThread) { mixin(S_TRACE);
					.task(&t3).executeInNewThread();
					callSaved = false;
				} else { mixin(S_TRACE);
					t3();
				}
			} else {
				refCheckPaths();
				resetChanged();
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			throw new SummaryException(.tryFormat(prop.msgs.saveError, scenarioName));
		}
	}
	/// シナリオのフォルダのアーカイブを作成する。
	ZipArchive createZipData(in string[] ignorePaths, bool useSysEnc, bool isWsn, out ubyte*[] data) { mixin(S_TRACE);
		auto lock = std.path.buildPath(scenarioPath, "cwxeditor.lock");
		auto arc = .zip(scenarioPath, !isWsn, (string file) { mixin(S_TRACE);
			return cfnmatch(file, lock)
				|| containsPath(ignorePaths, file.baseName());
		}, useSysEnc, data);
		if (useTemp && !expandXMLs) { mixin(S_TRACE);
			foreach (path, files; _oldXMLs) { mixin(S_TRACE);
				foreach (name, xml; files) { mixin(S_TRACE);
					auto p = std.path.buildPath(path, name);
					if (!isWsn) p = scenarioPath.baseName().buildPath(p);
					arc.addMember(.archive(p, cast(ubyte[]) xml, false, useSysEnc));
				}
			}
		}
		return arc;
	}
	/// データを保存せずにシナリオのフォルダのアーカイブを作成する。
	void createZip(string zipName, in string[] ignorePaths, bool useSysEnc) { mixin(S_TRACE);
		ubyte*[] tempData;
		auto arc = createZipData(ignorePaths, useSysEnc, zipName.extension().toLower() == ".wsn", tempData);
		std.file.write(zipName, arc.build());
		destroy(arc);
		freeAll(tempData);
	}
	/// データを保存せずにシナリオのフォルダのアーカイブを作成する。
	/// 非展開のXMLファイルは一時的に展開される。
	void createCab(string cabName, in string[] ignorePaths) { mixin(S_TRACE);
		string[] tempDirs;
		string[] tempFiles;
		if (useTemp && !expandXMLs) { mixin(S_TRACE);
			foreach (path, files; _oldXMLs) { mixin(S_TRACE);
				foreach (name, xml; files) { mixin(S_TRACE);
					auto dir = std.path.buildPath(scenarioPath, path);
					auto p = std.path.buildPath(dir, name);
					if (!.exists(dir)) { mixin(S_TRACE);
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

		.cab(scenarioPath, cabName, (string file) { mixin(S_TRACE);
			return !cfnmatch(baseName(file), "cwxeditor.lock")
				&& !containsPath(ignorePaths, file.baseName());
		});
	}

	/// ファイルシステム上に展開されなかったXMLデータ。
	private string[string][string] _oldXMLs;

	/// シナリオディレクトリ内の未使用ファイル・ディレクトリのリストを返す。
	string[] notUsedFiles(in Skin skin, in string[] ignorePaths, bool logicalSort) { mixin(S_TRACE);
		string[] r;
		int dirS(string p) { mixin(S_TRACE);
			if (isSystemFile(p) || .containsPath(ignorePaths, baseName(p))) { mixin(S_TRACE);
				return 1;
			}
			if (.isDir(p)) { mixin(S_TRACE);
				string[] list = clistdir(p);
				if (logicalSort) { mixin(S_TRACE);
					list = cwx.utils.sort!(fnncmp)(list);
				} else { mixin(S_TRACE);
					list = cwx.utils.sort!(fncmp)(list);
				}
				int c = 0;
				foreach (string file; list) { mixin(S_TRACE);
					c += dirS(p.buildPath(file));
				}
				auto rel = abs2rel(p, scenarioPath);
				if ("" == rel || cfnmatch(rel, skin.materialPath)) { mixin(S_TRACE);
					c++;
				}
				if (0 == c) { mixin(S_TRACE);
					// 未使用ディレクトリ
					r ~= rel;
				}
				return c;
			} else { mixin(S_TRACE);
				if (!skin.isMaterial(p)) { mixin(S_TRACE);
					return 1;
				}
				auto p2 = abs2rel(p, scenarioPath);
				auto pathId = toPathId(p2);
				if (0 == useCounter.get(pathId)) { mixin(S_TRACE);
					r ~= p2;
					return 0;
				}
				return 1;
			}
		}
		dirS(scenarioPath);
		return r;
	}
	/// 指定されたパスがシナリオ内に存在しているか。
	/// シナリオ内には存在せずスキンに存在しているような場合はfalseとなる。
	const
	bool hasMaterial(string path, in string[] ignorePaths) {
		if (path == "") return false;
		if (.containsPath(ignorePaths, baseName(path))) return false;
		path = nabs(scenarioPath).buildPath(path);
		if (isSystemFile(path)) return false;
		return path.exists() && path.isFile();
	}
	/// 素材の一覧を返す。
	string[] allMaterials(in Skin skin, in string[] ignorePaths, bool logicalSort, bool scenarioOnly) { mixin(S_TRACE);
		auto sPath = nabs(scenarioPath);
		auto tbl = new HashSet!(PathId);
		string[] paths;
		void find(string p) { mixin(S_TRACE);
			if (isSystemFile(p) || .containsPath(ignorePaths, baseName(p))) { mixin(S_TRACE);
				return;
			}
			if (.isDir(p)) { mixin(S_TRACE);
				string[] list = clistdir(p);
				if (logicalSort) { mixin(S_TRACE);
					list = cwx.utils.sort!(fnncmp)(list);
				} else { mixin(S_TRACE);
					list = cwx.utils.sort!(fncmp)(list);
				}
				foreach (l; list) { mixin(S_TRACE);
					find(std.path.buildPath(p, l));
				}
			} else if (skin.isMaterial(p)) { mixin(S_TRACE);
				auto path = abs2rel(p, sPath);
				paths ~= encodePath(path);
				tbl.add(toPathId(path));
			}
		}
		find(sPath);
		if (!scenarioOnly) { mixin(S_TRACE);
			foreach (p; skin.tables(logicalSort)) { mixin(S_TRACE);
				tbl.add(toPathId(p));
				paths ~= encodePath(p);
			}
			foreach (p; skin.musics(logicalSort)) { mixin(S_TRACE);
				tbl.add(toPathId(p));
				paths ~= encodePath(p);
			}
			foreach (p; skin.sounds(logicalSort)) { mixin(S_TRACE);
				tbl.add(toPathId(p));
				paths ~= encodePath(p);
			}
			foreach (path; useCounter.path.keys) { mixin(S_TRACE);
				auto p = cast(string) path;
				if (!path.isBinImg && !tbl.contains(path)) { mixin(S_TRACE);
					paths ~= encodePath(p);
				}
			}
		}
		return paths;
	}

	override void change(AreaId id) { }

	override void change(PathId id) { }

	override void change(CouponId id) { }
}

/// ファイル読み込み時の例外。
public class FileLoadException : Exception {
private:
	string _path;
	Exception _e;
public:
	/// 読み込み対象のパスと発生した例外からインスタンスを生成。
	this (string path, Exception e) { mixin(S_TRACE);
		super(e.msg);
		_path = path;
		_e = e;
	}
	/// 読み込み対象パス。
	@property
	const
	string path() { mixin(S_TRACE);
		return _path;
	}
	/// 例外。
	@property
	Exception e() { mixin(S_TRACE);
		return _e;
	}
	@property
	const
	const(Exception) e() { mixin(S_TRACE);
		return _e;
	}
}

/// シナリオのシステムディレクトリ
/// (Area, Battle, Package, CastCard, SkillCard, ItemCard, BeastCard, InfoCard)
/// であればtrueを返す。
bool isScenarioSystemDir(string dir) { mixin(S_TRACE);
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
void decScenarioPath(ref string scenarioPath, ref string[] openPaths, bool eventPriority) { mixin(S_TRACE);
	if (scenarioPath && cfnmatch(.extension(scenarioPath), ".wid")) { mixin(S_TRACE);
		ulong id;
		auto type = cwx.cwl.getType(scenarioPath, id);
		if (type) { mixin(S_TRACE);
			string ts;
			if (type is typeid(Area)) { mixin(S_TRACE);
				ts = "area";
			} else if (type is typeid(Battle)) { mixin(S_TRACE);
				ts = "battle";
			} else if (type is typeid(Package)) { mixin(S_TRACE);
				ts = "package";
			} else if (type is typeid(CastCard)) { mixin(S_TRACE);
				ts = "castcard";
			} else if (type is typeid(SkillCard)) { mixin(S_TRACE);
				ts = "skillcard";
			} else if (type is typeid(ItemCard)) { mixin(S_TRACE);
				ts = "itemcard";
			} else if (type is typeid(BeastCard)) { mixin(S_TRACE);
				ts = "beastcard";
			} else if (type is typeid(InfoCard)) { mixin(S_TRACE);
				ts = "infocard";
			}
			ts ~= ":id:" ~ to!(string)(id);
			if (eventPriority) { mixin(S_TRACE);
				if (type is typeid(Area)) { mixin(S_TRACE);
					ts = cpaddattr(ts, "eventview");
				} else if (type is typeid(Battle)) { mixin(S_TRACE);
					ts = cpaddattr(ts, "eventview");
				}
			}
			openPaths ~= ts;
		}
		scenarioPath = dirName(scenarioPath);
	} else if (scenarioPath && cfnmatch(.extension(scenarioPath), ".wex")) { mixin(S_TRACE);
		scenarioPath = dirName(scenarioPath);
	}
}
