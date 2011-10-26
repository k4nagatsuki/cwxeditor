
module cwx.skin;

import cwx.cwl;
import cwx.race;
import cwx.utils;
import cwx.props;
import cwx.imagesize;
import cwx.xml;
import cwx.types;

import std.ascii;
import std.file;
import std.path;
import std.utf;
import std.uni;

public:

class Skin {
	static Skin find(in CProps prop, string enginePath, string type, string sPath, bool legacy) {
		if (legacy && !type.length) {
			return findLegacySkin(prop, enginePath, sPath);
		}
		static Skin[string] emptySkins;
		auto tbl = table(prop, enginePath);
		auto p = type in tbl;
		if (p) return *p;
		auto pp = enginePath in emptySkins;
		if (pp) return *pp;
		auto r = new Skin(prop, enginePath);
		emptySkins[enginePath] = r;
		return r;
	}
	static Skin find2(Summary)(in CProps prop, string enginePath, in Summary summ) {
		return find(prop, enginePath, summ.type, summ.scenarioPath, summ.legacy);
	}

	private static Skin[string][string] skinTable;
	static Skin[string] table(const(CProps) prop, string enginePath) {
		if (!enginePath.length || !.exists(enginePath)) {
			Skin[string] tbl;
			return tbl;
		}
		enginePath = nabs(enginePath);
		auto p = enginePath in skinTable;
		if (p) {
			return *p;
		} else {
			auto skinsDir = std.path.buildPath(dirName(enginePath), buildPath("Data", "Skin") ~ sep);
			Skin[string] r;
			if (.exists(skinsDir) && .isDir(skinsDir)) {
				try {
					foreach (skinDir; clistdir(skinsDir)) {
						skinDir = std.path.buildPath(skinsDir, skinDir);
						if (!isDir(skinDir)) continue;
						auto file = std.path.buildPath(skinDir, "Skin.xml");
						if (!exists(file)) continue;
						try {
							auto skin = new Skin(prop, file, enginePath);
							r[skin.type] = skin;
						} catch (Exception e) {
							debugln(e);
						}
					}
				} catch (Exception e) {
					debugln(e);
				}
			}
			skinTable[enginePath] = r;
			return r;
		}
	}
	private static string lSkinsKey = null;
	private static Skin[string] lSkins;
	static Skin createLegacySkin(in CProps prop, string enginePath, string lEnginePath, string dataDirName, string execute) {
		// 標準のスキンをベースにする
		if (enginePath.length) enginePath = prop.toAppAbs(enginePath);
		if (lEnginePath.length) lEnginePath = prop.toAppAbs(lEnginePath);
		auto tbl = table(prop, enginePath);
		auto sp = "MedievalFantasy" in tbl;
		Skin skin;
		if (sp) {
			skin = new Skin(prop, sp.skinFile, enginePath);
		} else {
			skin = new Skin(prop, enginePath);
		}
		skin.setupLegacy(lEnginePath, lEnginePath.dirName.buildPath(dataDirName));
		skin._execute = execute;
		return skin;
	}
	static Skin findLegacySkin(in CProps prop, string enginePath, string sPath) {
		if (!lSkinsKey) {
			lSkinsKey = enginePath;
		} else if (enginePath != lSkinsKey) {
			typeof(lSkins) init;
			lSkins = init;
			lSkinsKey = enginePath;
		}
		string resDir, lEnginePath;
		findLegacy(sPath, resDir, lEnginePath);
		resDir = resDir.length ? nabs(resDir) : "";
		lEnginePath = lEnginePath.length ? nabs(lEnginePath) : "";
		auto p = resDir in lSkins;
		if (p) {
			return *p;
		} else {
			string dataDirName = resDir.length ? abs2rel(lEnginePath.dirName, resDir) : "";
			auto skin = createLegacySkin(prop, enginePath, lEnginePath, dataDirName, "");
			lSkins[resDir] = skin;
			return skin;
		}
	}
	private void setupLegacy(string lEnginePath, string resDir) {
		_extImg = "bmp";
		_extBgm = "mid";
		_extSound = "wav";
		_legacy = true;
		_legacyPath = resDir;
		_legacyEngine = lEnginePath;
		if (!('A' in _spChars)) _spChars['A'] = "";
		if (!('C' in _spChars)) _spChars['C'] = "";
		if (!('D' in _spChars)) _spChars['D'] = "";
		if (!('E' in _spChars)) _spChars['E'] = "";
		if (!('F' in _spChars)) _spChars['F'] = "";
		if (!('G' in _spChars)) _spChars['G'] = "";
		if (!('H' in _spChars)) _spChars['H'] = "";
		if (!('J' in _spChars)) _spChars['J'] = "";
		if (!('K' in _spChars)) _spChars['K'] = "";
		if (!('L' in _spChars)) _spChars['L'] = "";
		if (!('N' in _spChars)) _spChars['N'] = "";
		if (!('O' in _spChars)) _spChars['O'] = "";
		if (!('P' in _spChars)) _spChars['P'] = "";
		if (!('Q' in _spChars)) _spChars['Q'] = "";
		if (!('S' in _spChars)) _spChars['S'] = "";
		if (!('W' in _spChars)) _spChars['W'] = "";
		if (!('X' in _spChars)) _spChars['X'] = "";
		if (!('Z' in _spChars)) _spChars['Z'] = "";
	}
	/// 指定されたディレクトリにリソースディレクトリが
	/// 含まれていればディレクトリ名を返す。
	static string findResDir(string path) {
		auto p = path;
		if (std.file.exists(buildPath(p, buildPath("Data", "Table") ~ sep ~ "MapOfWirth.BMP"))) {
			return "Data";
		}
		for (char c = 'A'; c < 'Z'; c++) {
			if (std.file.exists(buildPath(p, buildPath("D_" ~ c ~ "1", "Table") ~ sep ~ "MapOfWirth.BMP"))) {
				return "D_" ~ c ~ "1";
			}
			if (std.file.exists(buildPath(p, [c] ~ buildPath("_dt", "Table") ~ sep ~ "MapOfWirth.BMP"))) {
				return [c].idup ~ "_dt";
			}
		}
		return "";
	}
	/// 指定されたディレクトリにクラシックエンジンとリソースディレクトリが
	/// 含まれていればtrueを返す。
	static bool hasClassicEngine(string path, out string resDir, out string enginePath) {
		auto r = findResDir(path);
		if (!r.length) return false;
		resDir = buildPath(path, r);

		auto cw = buildPath(path, "CardWirth.exe");
		if (std.file.exists(cw)) {
			enginePath = cw;
			return true;
		} else {
			auto list = clistdir(path);
			foreach (file; list) {
				if (fnendsWith(file, "Wirth.exe")) {
					enginePath = buildPath(path, file);
					return true;
				}
			}
			foreach (file; list) {
				if (cfnmatch(cwx.utils.getExt(file), "exe") && fnstartsWith(file, "CardWirth_")) {
					enginePath = buildPath(path, file);
					return true;
				}
			}
			foreach (file; list) {
				if (cfnmatch(cwx.utils.getExt(file), "exe") && fnstartsWith(file, "CW")) {
					enginePath = buildPath(path, file);
					return true;
				}
			}
			enginePath = "";
			resDir = "";
			return false;
		}
	}

	/// 指定されたシナリオが属すCardWirthを検索し、
	/// そのリソースディレクトリとエンジンのパスを返す。
	static bool findLegacy(string scPath, out string resDir, out string enginePath) {
		auto path = dirName(scPath);
		while (!hasClassicEngine(path, resDir, enginePath)) {
			auto old = path;
			path = dirName(path);
			if (old == path) {
				resDir ="";
				enginePath = "";
				return false;
			}
		}
		return true;
	}
	private bool _legacy = false;
	private string _legacyPath = "";
	private string _legacyEngine = "";
	private string _execute = "";

	private const(CProps) _prop;
	private string _enginePath;

	private string _path;
	private string _skinFile;
	private string _name;
	private string _type;
	private string _author;
	private string _desc;
	private string _extImg = "png";
	private string _resExtImg = "png";
	private string _extBgm = "mid";
	private string _resExtBgm = "mid";
	private string _extSound = "wav";
	private string _resExtSound = "wav";
	private string[dchar] _spChars;
	private Race[] _races;

	/// 空のスキンを生成する。
	this (const(CProps) prop, string enginePath) {
		_prop = prop;
		_enginePath = enginePath;
	}
	private this (const(CProps) prop, string skinFile, string enginePath) {
		this (prop, enginePath);
		if (skinFile.length) {
			loadFromXML(skinFile);
		}
	}
	const
	string name() {return _name;}
	const
	string type() {return _type;}
	const
	string skinFile() {return _skinFile;}

	/// リソース画像のパス。
	const
	string resSummary(out bool mask, out bool rMask) {
		return buildPath(tableDir, setExtension("Bill", _legacyPath.length ? extImage : resExtImage));
	}
	/// ditto
	const
	string resMenuCard(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "NORMAL"), resExtImage));}

	/// ditto
	const
	string resCastCard(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "LARGE"), resExtImage));}
	/// ditto
	const
	string resCastCardInjury(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "INJURY"), resExtImage));}
	/// ditto
	const
	string resCastCardDanger(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "DANGER"), resExtImage));}
	/// ditto
	const
	string resCastCardFaint(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "FAINT"), resExtImage));}
	/// ditto
	const
	string resCastCardBind(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "BIND"), resExtImage));}
	/// ditto
	const
	string resCastCardParaly(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "PARALY"), resExtImage));}
	/// ditto
	const
	string resCastCardPetrif(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "PETRIF"), resExtImage));}
	/// ditto
	const
	string resCastCardSleep(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "SLEEP"), resExtImage));}
	/// ditto
	const
	string resLifeBar(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("Status", "LIFEBAR"), resExtImage));}
	/// ditto
	const
	string resLifeGuage(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("Status", "LIFEGUAGE"), resExtImage));}
	/// ditto
	const
	string resEnhanceUp(out bool mask, out bool rMask, Enhance enh) {
		switch (enh) {
		case Enhance.ACTION: return buildPath(resourceDir, setExtension(buildPath("Status", "UP0"), resExtImage));
		case Enhance.AVOID: return buildPath(resourceDir, setExtension(buildPath("Status", "UP1"), resExtImage));
		case Enhance.RESIST: return buildPath(resourceDir, setExtension(buildPath("Status", "UP2"), resExtImage));
		case Enhance.DEFENSE: return buildPath(resourceDir, setExtension(buildPath("Status", "UP3"), resExtImage));
		default: assert (0);
		}
	}
	/// ditto
	const
	string resEnhanceDown(out bool mask, out bool rMask, Enhance enh) {
		switch (enh) {
		case Enhance.ACTION: return buildPath(resourceDir, setExtension(buildPath("Status", "DOWN0"), resExtImage));
		case Enhance.AVOID: return buildPath(resourceDir, setExtension(buildPath("Status", "DOWN1"), resExtImage));
		case Enhance.RESIST: return buildPath(resourceDir, setExtension(buildPath("Status", "DOWN2"), resExtImage));
		case Enhance.DEFENSE: return buildPath(resourceDir, setExtension(buildPath("Status", "DOWN3"), resExtImage));
		default: assert (0);
		}
	}
	/// ditto
	const
	string resMentality(out bool mask, out bool rMask, Mentality mtly) {
		switch (mtly) {
		case Mentality.NORMAL: return buildPath(resourceDir, setExtension(buildPath("Status", "MIND0"), resExtImage));
		case Mentality.SLEEP: return buildPath(resourceDir, setExtension(buildPath("Status", "MIND1"), resExtImage));
		case Mentality.CONFUSE: return buildPath(resourceDir, setExtension(buildPath("Status", "MIND2"), resExtImage));
		case Mentality.OVERHEAT: return buildPath(resourceDir, setExtension(buildPath("Status", "MIND3"), resExtImage));
		case Mentality.BRAVE: return buildPath(resourceDir, setExtension(buildPath("Status", "MIND4"), resExtImage));
		case Mentality.PANIC: return buildPath(resourceDir, setExtension(buildPath("Status", "MIND5"), resExtImage));
		default: assert (0);
		}
	}
	/// ditto
	const
	string resBind(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("Status", "MAGIC0"), resExtImage));}
	/// ditto
	const
	string resSilence(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("Status", "MAGIC1"), resExtImage));}
	/// ditto
	const
	string resFaceUp(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("Status", "MAGIC2"), resExtImage));}
	/// ditto
	const
	string resAntiMagic(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("Status", "MAGIC3"), resExtImage));}
	/// ditto
	const
	string resParalyze(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("Status", "BODY1"), resExtImage));}
	/// ditto
	const
	string resPoison(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("Status", "BODY0"), resExtImage));}
	/// ditto
	const
	string resSummon(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("Status", "SUMMON"), resExtImage));}

	/// ditto
	const
	string resItemCard(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "ITEM"), resExtImage));}
	/// ditto
	const
	string resSkillCard(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "SKILL"), resExtImage));}
	/// ditto
	const
	string resBeastCard(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "BEAST"), resExtImage));}
	/// ditto
	const
	string resInfoCard(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "INFO"), resExtImage));}
	/// ditto
	const
	string resCardHold(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "HOLD"), resExtImage));}
	/// ditto
	const
	string resCardPenalty(out bool mask, out bool rMask) {return buildPath(resourceDir, setExtension(buildPath("CardBg", "PENALTY"), resExtImage));}
	/// ditto
	const
	string resRare(out bool mask, out bool rMask) {
		mask = true;
		rMask = true;
		return buildPath(resourceDir, setExtension(buildPath("CardBg", "RARE"), resExtImage));
	}
	/// ditto
	const
	string resPremier(out bool mask, out bool rMask) {
		mask = true;
		rMask = true;
		return buildPath(resourceDir, setExtension(buildPath("CardBg", "PREMIER"), resExtImage));
	}
	/// ditto
	const
	string resAptVeryHigh(out bool mask, out bool rMask) {
		mask = true;
		return buildPath(resourceDir, setExtension(buildPath("Stone", "HAND3"), resExtImage));
	}
	/// ditto
	const
	string resAptHigh(out bool mask, out bool rMask) {
		mask = true;
		return buildPath(resourceDir, setExtension(buildPath("Stone", "HAND2"), resExtImage));
	}
	/// ditto
	const
	string resAptNormal(out bool mask, out bool rMask) {
		mask = true;
		return buildPath(resourceDir, setExtension(buildPath("Stone", "HAND1"), resExtImage));
	}
	/// ditto
	const
	string resAptLow(out bool mask, out bool rMask) {
		mask = true;
		return buildPath(resourceDir, setExtension(buildPath("Stone", "HAND0"), resExtImage));
	}
	/// ditto
	const
	string resUse0(out bool mask, out bool rMask) {
		mask = true;
		return buildPath(resourceDir, setExtension(buildPath("Stone", "HAND5"), resExtImage));
	}
	/// ditto
	const
	string resUse1(out bool mask, out bool rMask) {
		mask = true;
		return buildPath(resourceDir, setExtension(buildPath("Stone", "HAND6"), resExtImage));
	}
	/// ditto
	const
	string resUse2(out bool mask, out bool rMask) {
		mask = true;
		return buildPath(resourceDir, setExtension(buildPath("Stone", "HAND7"), resExtImage));
	}
	/// ditto
	const
	string resUse3(out bool mask, out bool rMask) {
		mask = true;
		return buildPath(resourceDir, setExtension(buildPath("Stone", "HAND8"), resExtImage));
	}
	/// ditto
	const
	string resUse4(out bool mask, out bool rMask) {
		mask = true;
		return buildPath(resourceDir, setExtension(buildPath("Stone", "HAND9"), resExtImage));
	}

	/// CardWirth本体のパス。
	/// クラシックなシナリオの編集中は、そのシナリオが
	/// 属すと思われるパスを返す。
	const
	string engine() {
		if (_legacyEngine.length) {
			return legacyEngine();
		} else {
			return _enginePath;
		}
	}

	/// クラシックなCardWirth本体のパス。
	/// 所属エンジンが無いか、クラシックでないシナリオの編集中であれば""を返す。
	const
	string legacyEngine() {
		if (!_legacyEngine.length) return "";
		return _legacyEngine;
	}

	/// エンジンを実行する際のパス。
	const
	string executeEngine() {
		if (_legacyEngine.length) {
			if (_execute.length) {
				return _legacyEngine.dirName.buildPath(_execute);
			}
			return legacyEngine();
		} else {
			return _enginePath;
		}
	}

	/// クラシックなシナリオの編集中は、拡張子を除く所属エンジンのパスを返す。
	/// 所属エンジンが無いか、クラシックでないシナリオの編集中であれば""を返す。
	const
	string legacyName() {return _legacyEngine.length ? stripExtension(baseName(_legacyEngine)) : "";}

	/// クラシックなCardWirthのDataディレクトリのパス。
	const
	string legacyDataPath() {return _legacyPath;}

	/// クラシックなCardWirthEditorで作成されたシナリオのスキンならtrue。
	const
	bool legacy() {return _legacy;}

	/// エンジン内のリソースを使用している場合はtrue。
	const
	bool useLegacyRes() {
		version (Windows) {
			return legacyEngine.length > 0;
		}
		return false;
	}

	/// シナリオの素材を置くディレクトリの標準。シナリオのルートからの相対パス。
	const
	string materialPath() {
		return legacy ? "" : "Material";
	}

	/// pathがシナリオ素材であればtrueを返す。
	/// checkがfalseの場合、拡張子による判断のみを行う。
	/// checkをtrueにすると、ファイルの存在と内容をチェックする。
	/// (現行バージョンでは内容チェックは背景イメージのみ)
	const
	bool isMaterial(string path, bool check = false) {
		return isSE(path, check) || isBGM(path, check) || isBgImage(path, check);
	}

	/// pathが効果音として使用可能か。
	const
	bool isSE(string path, bool check = false) {
		auto ext = cwx.utils.getExt(path);
		if (legacy && !cfnmatch(ext, "wav")) return false;
		// pygameの仕様で効果音にMP3は使えない
		switch (toLower(ext)) {
		case "aiff": // AIFF
		case "mid", "midi": // MIDI
		case "mod", "s3m", "xm", "it", "mt2", "669", "med": // MOD
		case "ogg", "ogv", "oga", "ogx": // Ogg
		case "voc": // VOC
		case "wav": // WAV/RIFF
			return true;
		default:
			return false;
		}
	}
	/// pathがBGMとして使用可能か。
	const
	bool isBGM(string path, bool check = false) {
		auto ext = cwx.utils.getExt(path);
		if (legacy && !cfnmatch(ext, "mid")
				&& !cfnmatch(ext, "midi")
				&& !cfnmatch(ext, "mpg")) {
			return false;
		}
		switch (toLower(ext)) {
		case "aiff": // AIFF
		case "mid", "midi": // MIDI
		case "mod", "s3m", "xm", "it", "mt2", "669", "med": // MOD
		case "mp3": // MP3
		case "ogg", "ogv", "oga", "ogx": // Ogg
		case "voc": // VOC
		case "wav": // WAV/RIFF
		case "mpg": // MPEG
			return true;
		default:
			return false;
		}
	}
	/// pathがカード画像として使用可能か。
	const
	bool isCardImage(string path) {
		if (isBinImg(path)) return true;
		if (legacy && !cfnmatch(cwx.utils.getExt(path), "bmp")) return false;
		try {
			uint x, y;
			return imageSize(path, x, y)
				&& x == _prop.looks.cardSize.width && y == _prop.looks.cardSize.height;
		} catch (Exception e) {
		}
		return false;
	}

	/// pathが背景画像として使用可能か。
	const
	bool isBgImage(string path, bool check = false) {
		auto ext = cwx.utils.getExt(path);
		if (cfnmatch(ext, "jpy1")
				|| cfnmatch(ext, "jptx")
				|| cfnmatch(ext, "jpdc")) {
			return true;
		}
		if (legacy && !cfnmatch(ext, "bmp")
				&& !cfnmatch(ext, "jpg")
				&& !cfnmatch(ext, "jpeg")) {
			return false;
		}
		if (check) {
			try {
				uint x, y;
				return imageSize(path, x, y);
			} catch (Exception e) {
			}
		} else {
			return isImageExt(path);
		}
		return false;
	}

	/// 特殊文字の情報。
	const
	const(string[dchar]) spChars() {return _spChars;}

	const
	private bool has(alias isT)(string dir) {
		foreach (file; clistdir(dir)) {
			if (isT(std.path.buildPath(dir, file))) return true;
		}
		return false;
	}

	/// 各種の素材がdirに含まれていればtrueを返す。
	const
	bool hasCardImage(string dir) {return has!(isCardImage)(dir);}
	/// ditto
	const
	bool hasBgImage(string dir) {return has!(isBgImage)(dir);}
	/// ditto
	const
	bool hasBGM(string dir) {return has!(isBGM)(dir);}
	/// ditto
	const
	bool hasSE(string dir) {return has!(isSE)(dir);}

	const
	private string[] list(alias isT)(string dir, bool forceRefresh) {
		mixin FileCache!(string[]);
		if (!forceRefresh) {
			auto ca = cache(dir);
			if (ca) {
				return ca.value;
			}
		}
		string[] r;
		foreach (fp; clistdir(dir)) {
			fp = std.path.buildPath(dir, fp);
			if (isT(fp)) {
				r ~= baseName(fp);
			}
		}
		r = r.sort;
		putCache(dir, r);
		return r;
	}

	/// dirに含まれるカード画像の一覧。
	const
	string[] cards(string dir, bool forceRefresh) {return list!(isCardImage)(dir, forceRefresh);}

	/// 標準の背景画像。
	const
	string[] tables(bool forceRefresh = false) {return list!(isBgImage)(tableDir, forceRefresh);}

	/// dirに含まれる背景画像の一覧。
	const
	string[] tables(string dir, bool forceRefresh) {return list!(isBgImage)(dir, forceRefresh);}

	/// 標準のBGM。
	const
	string[] musics(bool forceRefresh = false) {return list!(isBGM)(bgmDir, forceRefresh);}

	/// dirに含まれるBGMの一覧。
	const
	string[] musics(string dir, bool forceRefresh) {return list!(isBGM)(dir, forceRefresh);}

	/// 標準のSE。
	const
	string[] sounds(bool forceRefresh = false) {return list!(isSE)(seDir, forceRefresh);}

	/// dirに含まれるSEの一覧。
	const
	string[] sounds(string dir, bool forceRefresh) {return list!(isSE)(dir, forceRefresh);}

	/// 標準素材ディレクトリのルート。
	const
	string resDir() {
		if (_legacyPath.length) {
			return _legacyPath;
		}
		return _path;
	}
	/// 標準の背景画像のディレクトリ。
	const
	string tableDir() {
		if (_legacyPath.length) {
			return std.path.buildPath(_legacyPath, "Table");
		}
		return std.path.buildPath(_path, "Table");
	}
	/// 標準のBGMのディレクトリ。
	const
	string bgmDir() {
		if (_legacyPath.length) {
			return std.path.buildPath(_legacyPath, "Midi");
		}
		return std.path.buildPath(_path, "Bgm");
	}
	/// 標準のSEのディレクトリ。
	const
	string seDir() {
		if (_legacyPath.length) {
			return std.path.buildPath(_legacyPath, "Wave");
		}
		return std.path.buildPath(_path, "Sound");
	}
	/// その他リソースのディレクトリ。
	const
	string resourceDir() {
		return std.path.buildPath(_path, buildPath("Resource", "Image"));
	}

	/// 標準画像の拡張子。
	const
	string extImage() {return _extImg;}
	/// 標準BGMの拡張子。
	const
	string extBgm() {return _extBgm;}
	/// 標準SEの拡張子。
	const
	string extSound() {return _extSound;}
	/// 標準リソース画像の拡張子。
	const
	string resExtImage() {return _resExtImg;}

	/// 種族。
	Race[] races() {
		return _races.dup;
	}

	/// バトルを作成した際、最初に設定されているBGMの名前。
	const
	string defBattle() {return setExtension("DefBattle", extBgm);}

	/// 指定されたパスを元に、まずシナリオのディレクトリを、
	/// 無ければ本体付属のディレクトリを検索し、見つかったパスを返す。
	/// 付属ディレクトリに見つからなければ拡張子をスキン指定のものに
	/// 変更し、再度付属ディレクトリを検索する。
	/// それでも見つからなければ""を返す。
	/// Params:
	/// path = 検索対象のパス。
	/// sPath = シナリオのディレクトリ。
	/// def = 結果がシナリオのフォルダ内であればfalseが、
	///       本体の付属ディレクトリ内であればtrueが入る。
	/// Returns: ファイルパス。見つからなかった場合は""。
	const
	string findImagePathF(string path, string sPath, out bool def = false) {
		return findPathF(path, extImage, tableDir, sPath, def);
	}
	/// ditto
	const
	string findImagePath(string path, string sPath) {
		bool dummy;
		return findImagePathF(path, sPath, dummy);
	}
	/// ditto
	const
	string findPathF(string path, string ext, string defDir, string sPath, out bool def = false) {
		if (path.length == 0) return "";
		if (isBinImg(path)) return path;
		string p;
		if (sPath && sPath.length) {
			p = std.path.buildPath(sPath, path);
			if (exists(p)) {
				return p;
			}
		}
		def = true;
		p = std.path.buildPath(defDir, baseName(path));
		if (exists(p)) {
			return p;
		}
		if (!legacy) {
			string f(string ext) {
				p = setExtension(p, ext);
				return exists(p) ? p : "";
			}
			string r = f(ext);
			if (r.length) return r;
			if (ext == _extImg) {
				return f(_resExtImg);
			} else if (ext == _extBgm) {
				return f(_resExtBgm);
			} else if (ext == _extSound) {
				return f(_resExtSound);
			}
		}
		return "";
	}
	/// ditto
	const
	string findPath(string path, string ext, string defDir, string sPath) {
		bool dummy;
		return findPathF(path, ext, defDir, sPath, dummy);
	}

	/// XMLファイルからスキンデータをロードする。
	void loadFromXML(string fname) {
		try {
			_path = dirName(fname);
			_skinFile = fname;
			scope sNode = XNode.parse(std.file.readText(fname));
			_races.length = 0;
			sNode.onTag["Property"] = (ref XNode pNode) {
				pNode.onTag["Name"] = (ref XNode n) {_name = n.value;};
				pNode.onTag["Type"] = (ref XNode n) {_type = n.value;};
				pNode.onTag["Author"] = (ref XNode n) {_author = n.value;};
				pNode.onTag["Description"] = (ref XNode n) {_desc = n.value;};
				pNode.onTag["Extension"] = (ref XNode n) {
					void readExt(string name, ref string ext1, ref string ext2) {
						string ext = n.attr(name, false);
						if (!ext && !ext.length) return;
						if (ext[0] == '.') ext = ext[1 .. $];
						ext1 = ext;
						ext2 = ext;
					}
					readExt("image", _extImg, _resExtImg);
					readExt("bgm", _extBgm, _resExtBgm);
					readExt("sound", _extSound, _resExtSound);
				};
				pNode.parse;
			};
			sNode.onTag["Races"] = (ref XNode node) {
				node.onTag["Race"] = (ref XNode node) {
					_races ~= Race.fromNode(node, LATEST_VERSION);
				};
				node.parse;
			};
			sNode.parse;
			typeof(_spChars) spCharsInit;
			_spChars = spCharsInit;
			auto fd = std.path.buildPath(resourceDir, "Font");
			foreach (path; clistdir(fd)) {
				path = std.path.buildPath(fd, path);
				if (!isDir(path) && cfnmatch(cwx.utils.getExt(path), _resExtImg)) {
					_spChars[toUniUpper(toUTF32(baseName(path))[0])] = path;
				}
			}
		} catch (Exception e) {
			debugln(e);
		}
	}
}
