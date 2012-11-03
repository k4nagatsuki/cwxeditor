
module cwx.skin;

import cwx.race;
import cwx.utils;
import cwx.props;
import cwx.imagesize;
import cwx.xml;
import cwx.types;
import cwx.structs;
import cwx.features;
import cwx.background;
import cwx.sjis;

import std.exception;
import std.conv;
import std.ascii;
import std.file;
import std.path;
import std.utf;
import std.uni;
import std.string;
import std.array;
import std.regex : regex, match;

/// BgImageをBgImageSに変換する。
BgImageS[] createBgImageSs(in BgImage[] bgs) {
	BgImageS[] r;
	r.length = bgs.length;
	foreach (i, b; bgs) {
		r[i] = BgImageS(stripExtension(b.path), b.x, b.y, b.width, b.height, b.mask);
	}
	return r;
}
/// BgImageSをBgImageに変換する。
BgImage[] createBgImages(in Skin skin, in BgImageS[] bgs) {
	BgImage[] r;
	r.length = bgs.length;
	foreach (i, b; bgs) {
		auto path = skin.findImagePath(setExtension(b.name, skin.extImage), "");
		if (path.length) {
			path = abs2rel(nabs(path), skin.tableDir);
		} else {
			path = setExtension(b.name, skin.extImage);
		}
		r[i] = new BgImage(path, "", b.x, b.y, b.width, b.height, b.mask);
	}
	return r;
}

/// シナリオの外観の情報。
class Skin {
	/// 設定に該当するスキンを探す。
	static Skin find(in CProps prop, string enginePath, string type, string sPath, bool legacy, string classicEngineRegex, string classicDataDirRegex, string classicMatchKey, in ClassicEngine[] cEngines) {
		if (legacy && !type.length) {
			return findLegacySkin(prop, enginePath, sPath, classicEngineRegex, classicDataDirRegex, classicMatchKey, cEngines);
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

	private static Skin[string][string] skinTable;
	/// スキンの一覧を返す。
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
			auto skinsDir = std.path.buildPath(dirName(enginePath), buildPath("Data", "Skin"));
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
	/// クラシックなエンジンのスキンを返す。
	static Skin createLegacySkin(in CProps prop, string enginePath, string lEnginePath, string dataDirName, string execute, in ClassicEngine[] cEngines) {
		// 標準のスキンをベースにする
		if (enginePath.length) enginePath = prop.toAppAbs(enginePath);
		if (lEnginePath.length) lEnginePath = nabs(prop.toAppAbs(lEnginePath));
		auto tbl = table(prop, enginePath);
		auto sp = "MedievalFantasy" in tbl;
		ClassicEngine cEngine;
		foreach (ce; cEngines) {
			if (cfnmatch(nabs(prop.toAppAbs(ce.enginePath)), lEnginePath)) {
				cEngine = ce.dup;
				break;
			}
		}
		Skin skin;
		if (sp) {
			skin = new Skin(prop, sp.skinFile, enginePath);
		} else {
			skin = new Skin(prop, enginePath);
		}
		skin.setupLegacy(lEnginePath, lEnginePath.dirName().buildPath(dataDirName), cEngine);
		skin._execute = execute;
		return skin;
	}
	/// クラシックなエンジンのスキンを探して返す。
	static Skin findLegacySkin(in CProps prop, string enginePath, string sPath, string classicEngineRegex, string classicDataDirRegex, string classicMatchKey, in ClassicEngine[] cEngines) {
		string resDir, lEnginePath;
		findLegacy(sPath, resDir, lEnginePath, classicEngineRegex, classicDataDirRegex, classicMatchKey, cEngines);
		resDir = resDir.length ? nabs(resDir) : "";
		lEnginePath = lEnginePath.length ? nabs(lEnginePath) : "";

		string dataDirName = resDir.length ? abs2rel(resDir, lEnginePath.dirName()) : "";
		return createLegacySkin(prop, enginePath, lEnginePath, dataDirName, "", cEngines);
	}
	private void setupLegacy(string lEnginePath, string resDir, ClassicEngine cEngine) {
		_cEngine = cEngine;
		_extImg = ".bmp";
		_extBgm = ".mid";
		_extSound = ".wav";
		_legacy = true;
		_legacyPath = resDir;
		_legacyEngine = lEnginePath;
		if (!('A' in _spChars)) _spChars['A'] = "";
		if (!('B' in _spChars)) _spChars['B'] = "";
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
	/// ファイルにアクセス可能か。
	private static bool canAccess(string file) {
		version (Windows) {
			import std.c.windows.windows;
			immutable INVALID_FILE_ATTRIBUTES = -1;
			if (INVALID_FILE_ATTRIBUTES == GetFileAttributesW(toUTFz!(wchar*)(file))) {
				return false;
			}
		}
		return true;
	}
	/// 指定されたディレクトリにリソースディレクトリが
	/// 含まれていればディレクトリ名を返す。
	static string findResDir(string path, string classicDataDirRegex, string classicMatchKey) {
		auto p = path;
		auto regDir = .regex(to!dstring(classicDataDirRegex), 0 == filenameCharCmp('A', 'a') ? "i" : "");
		foreach (dir; clistdir(path)) {
			auto pd = path.buildPath(dir);
			if (!canAccess(pd)) continue;
			try {
				if (.isDir(pd)) {
					if (!to!dstring(dir).match(regDir).empty && pd.buildPath(classicMatchKey).exists()) {
						return dir;
					}
				}
			} catch (Exception e) {
				debugln(e);
			}
		}
		return "";
	}
	/// 指定されたディレクトリにクラシックエンジンとリソースディレクトリが
	/// 含まれていればtrueを返す。
	static bool hasClassicEngine(string path, out string resDir, out string enginePath, string classicEngineRegex, string classicDataDirRegex, string classicMatchKey, in ClassicEngine[] cEngines) {
		foreach (cEngine; cEngines) {
			string e = cEngine.enginePath.baseName();
			if (.isAbsolute(cEngine.dataDirName) ? true : .exists(path.buildPath(cEngine.dataDirName))) {
				auto p = path.buildPath(e);
				if (p.exists()) {
					enginePath = p;
					resDir = path.buildPath(cEngine.dataDirName);
					return true;
				}
			}
		}
		auto r = findResDir(path, classicDataDirRegex, classicMatchKey);
		if (!r.length) return false;
		resDir = buildPath(path, r);

		auto regExe = .regex(to!dstring(classicEngineRegex), 0 == filenameCharCmp('A', 'a') ? "i" : "");

		foreach (file; clistdir(path)) {
			string p = path.buildPath(file);
			if (!canAccess(p)) continue;
			try {
				if (!.isDir(p) && !to!dstring(file).match(regExe).empty) {
					enginePath = p;
					return true;
				}
			} catch (Exception e) {
				debugln(e);
			}
		}

		enginePath = "";
		resDir = "";
		return false;
	}

	/// 指定されたシナリオが属すCardWirthを検索し、
	/// そのリソースディレクトリとエンジンのパスを返す。
	static bool findLegacy(string scPath, out string resDir, out string enginePath, string classicEngineRegex, string classicDataDirRegex, string classicMatchKey, in ClassicEngine[] cEngines) {
		auto path = dirName(scPath);
		while (!hasClassicEngine(path, resDir, enginePath, classicEngineRegex, classicDataDirRegex, classicMatchKey, cEngines)) {
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
	/// 指定されたシナリオが属すCardWirthPyを検索し、そのパスを返す。
	static string findCardWirthPy(string scPath, string exeName, string dataName) {
		auto path = dirName(scPath);
		while (!path.buildPath(exeName).exists() || !path.buildPath(dataName).exists()) {
			auto old = path;
			path = dirName(path);
			if (old == path) {
				return "";
			}
		}
		return path.buildPath(exeName);
	}

	private bool _legacy = false;
	private string _legacyPath = "";
	private string _legacyEngine = "";
	private string _execute = "";

	private const(CProps) _prop;
	private string _enginePath;
	private ClassicEngine _cEngine;

	private string _path;
	private string _skinFile;
	private string _name;
	private string _type;
	private string _author;
	private string _desc;
	private string _extImg = ".png";
	private string _resExtImg = ".png";
	private string _extBgm = ".mid";
	private string _resExtBgm = ".mid";
	private string _extSound = ".wav";
	private string _resExtSound = ".wav";
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
	@property
	const
	string name() {return _name;}
	@property
	const
	string type() {return _type;}
	@property
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
	@property
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
	@property
	const
	string legacyEngine() {
		if (!_legacyEngine.length) return "";
		return _legacyEngine;
	}

	/// エンジンを実行する際のパス。
	@property
	const
	string executeEngine() {
		if (_legacyEngine.length) {
			if (_execute.length) {
				return _legacyEngine.dirName().buildPath(_execute);
			}
			return legacyEngine();
		} else {
			return _enginePath;
		}
	}

	/// クラシックなシナリオの編集中は、拡張子を除く所属エンジンのパスを返す。
	/// 所属エンジンが無いか、クラシックでないシナリオの編集中であれば""を返す。
	@property
	const
	string legacyName() {return _legacyEngine.length ? stripExtension(baseName(_legacyEngine)) : "";}

	/// クラシックなCardWirthのDataディレクトリのパス。
	@property
	const
	string legacyDataPath() {return _legacyPath;}

	/// クラシックなCardWirthEditorで作成されたシナリオのスキンならtrue。
	@property
	const
	bool legacy() {return _legacy;}

	/// エンジンの設定を読み込んで返す。
	const
	string[string] loadEngineSettings() {
		typeof(return) r;
		if (_legacyEngine.length) {
			auto ini = _legacyEngine.dirName().buildPath("cwex.ini");
			if (!ini.exists()) return r;
			string iniText;
			try {
				iniText = std.file.readText(ini);
			} catch (UTFException e) {
				// ここではMS932を想定
				iniText = .touni(cast(char[]) std.file.read(ini));
			}
			/// UTF-8とは限らないため、バイナリで読み込む
			foreach (line; iniText.splitLines()) {
				auto ln = line.split("=");
				if (2 != ln.length) continue;
				auto key = ln[0].strip();
				auto value = ln[1].strip();
				r[.toLower(assumeUnique(key))] = assumeUnique(value);
			}
		}
		return r;
	}

	/// エンジン内のリソースを使用している場合はtrue。
	@property
	const
	bool useLegacyRes() {
		version (Windows) {
			return legacyEngine.length > 0;
		}
		return false;
	}

	/// シナリオの素材を置くディレクトリの標準。シナリオのルートからの相対パス。
	@property
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
		auto ext = .toLower(.extension(path));
		if (legacy) {
			switch (ext) {
			case ".mp3": // MP3
			case ".ogg", ".ogv", ".oga", ".ogx": // Ogg
			case ".wav": // WAV/RIFF
				return true;
			default:
				return false;
			}
		}
		// pygameの仕様で効果音にMP3は使えない
		switch (ext) {
		case ".aiff": // AIFF
		case ".mid", ".midi": // MIDI
		case ".mod", ".s3m", ".xm", ".it", ".mt2", ".669", ".med": // MOD
		case ".ogg", ".ogv", ".oga", ".ogx": // Ogg
		case ".voc": // VOC
		case ".wav": // WAV/RIFF
			return true;
		default:
			return false;
		}
	}
	/// pathを使用する際の警告(一部環境で再生不可等)。
	static string[] warningSE(in CProps prop, string path, bool legacy) {
		auto ext = .toLower(.extension(path));
		if (legacy) {
			switch (ext) {
			case ".ogg", ".ogv", ".oga", ".ogx": // Ogg
				return [prop.msgs.oggMayNotCorrespond];
			default:
				return [];
			}
		}
		return [];
	}
	/// pathがBGMとして使用可能か。
	const
	bool isBGM(string path, bool check = false) {
		auto ext = .toLower(.extension(path));
		if (legacy) {
			switch (ext) {
			case ".mid", ".midi": // MIDI
			case ".mp3": // MP3
			case ".ogg", ".ogv", ".oga", ".ogx": // Ogg
			case ".wav": // WAV/RIFF
			case ".mpg": // MPEG
				return true;
			default:
				return false;
			}
		}
		switch (ext) {
		case ".aiff": // AIFF
		case ".mid", ".midi": // MIDI
		case ".mod", ".s3m", ".xm", ".it", ".mt2", ".669", ".med": // MOD
		case ".mp3": // MP3
		case ".ogg", ".ogv", ".oga", ".ogx": // Ogg
		case ".voc": // VOC
		case ".wav": // WAV/RIFF
		case ".mpg": // MPEG
			return true;
		default:
			return false;
		}
	}
	/// pathを使用する際の警告(一部環境で再生不可等)。
	static string[] warningBGM(in CProps prop, string path, bool legacy) {
		auto ext = .toLower(.extension(path));
		if (legacy) {
			switch (ext) {
			case ".mp3": // MP3
				return [prop.msgs.mp3LoopMayNotCorrespond];
			case ".ogg", ".ogv", ".oga", ".ogx": // Ogg
				return [prop.msgs.oggMayNotCorrespond];
			default:
				return [];
			}
		}
		return [];
	}
	/// pathがカード画像として使用可能か。
	const
	bool isCardImage(string path, bool ignoreSize) {
		if (isBinImg(path)) return true;
		if (legacy && !cfnmatch(.extension(path), ".bmp")) return false;
		if (ignoreSize) return true;
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
		auto ext = .extension(path);
		if (cfnmatch(ext, ".jpy1")
				|| cfnmatch(ext, ".jptx")
				|| cfnmatch(ext, ".jpdc")) {
			return true;
		}
		if (legacy && !cfnmatch(ext, ".bmp")
				&& !cfnmatch(ext, ".jpg")
				&& !cfnmatch(ext, ".jpeg")) {
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
	/// pathを使用する際の警告(一部環境で表示不可等)。
	static string[] warningImage(in CProps prop, string path, bool legacy) {
		auto ext = .toLower(.extension(path));
		if (legacy) {
			switch (ext) {
			case ".png": // PNG
				return [prop.msgs.pngMayNotCorrespond];
			default:
				return [];
			}
		}
		return [];
	}

	/// 特殊文字の情報。
	@property
	const
	const(string[dchar]) spChars() {return _spChars;}

	const
	private bool has(alias isT, Arg ...)(string dir, Arg args) {
		foreach (file; clistdir(dir)) {
			if (isT(std.path.buildPath(dir, file), args)) return true;
		}
		return false;
	}

	/// 各種の素材がdirに含まれていればtrueを返す。
	const
	bool hasCardImage(string dir, bool ignoreSize) {return has!(isCardImage)(dir, ignoreSize);}
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
	private string[] list(alias isT, bool UseFlag = false)(string dir, bool logicalSort, bool forceRefresh, bool flag) {
		synchronized {
			static struct Files {
				bool logicalSort;
				bool flag;
				string[] files;
			}
			mixin FileCache!(Files);
			if (!forceRefresh) {
				auto ca = cache(dir);
				if (ca && ca.value.logicalSort == logicalSort && ca.value.flag == flag) {
					return ca.value.files;
				}
			}
			string[] r;
			foreach (fp; clistdir(dir)) {
				fp = std.path.buildPath(dir, fp);
				static if (UseFlag) {
					if (isT(fp, flag)) {
						r ~= baseName(fp);
					}
				} else {
					if (isT(fp)) {
						r ~= baseName(fp);
					}
				}
			}
			if (logicalSort) {
				r = sort!(fnncmp)(r);
			} else {
				r = sort!(fncmp)(r);
			}
			putCache(dir, Files(logicalSort, flag, r));
			return r;
		}
	}

	/// dirに含まれるカード画像の一覧。
	const
	string[] cards(string dir, bool logicalSort, bool forceRefresh, bool ignoreSize) {return list!(isCardImage, true)(dir, logicalSort, forceRefresh, ignoreSize);}

	/// 標準の背景画像。
	const
	string[] tables(bool logicalSort, bool forceRefresh = false) {return list!(isBgImage)(tableDir, logicalSort, forceRefresh, false);}

	/// dirに含まれる背景画像の一覧。
	const
	string[] tables(string dir, bool logicalSort, bool forceRefresh) {return list!(isBgImage)(dir, logicalSort, forceRefresh, false);}

	/// 標準のBGM。
	const
	string[] musics(bool logicalSort, bool forceRefresh = false) {return list!(isBGM)(bgmDir, logicalSort, forceRefresh, false);}

	/// dirに含まれるBGMの一覧。
	const
	string[] musics(string dir, bool logicalSort, bool forceRefresh) {return list!(isBGM)(dir, logicalSort, forceRefresh, false);}

	/// 標準のSE。
	const
	string[] sounds(bool logicalSort, bool forceRefresh = false) {return list!(isSE)(seDir, logicalSort, forceRefresh, false);}

	/// dirに含まれるSEの一覧。
	const
	string[] sounds(string dir, bool logicalSort, bool forceRefresh) {return list!(isSE)(dir, logicalSort, forceRefresh, false);}

	/// 標準素材ディレクトリのルート。
	@property
	const
	string resDir() {
		if (_legacyPath.length) {
			return _legacyPath;
		}
		return _path;
	}
	/// 標準の背景画像のディレクトリ。
	@property
	const
	string tableDir() {
		if (_legacyPath.length) {
			return std.path.buildPath(_legacyPath, "Table");
		}
		return std.path.buildPath(_path, "Table");
	}
	/// 標準のBGMのディレクトリ。
	@property
	const
	string bgmDir() {
		if (_legacyPath.length) {
			return std.path.buildPath(_legacyPath, "Midi");
		}
		return std.path.buildPath(_path, "Bgm");
	}
	/// 標準のSEのディレクトリ。
	@property
	const
	string seDir() {
		if (_legacyPath.length) {
			return std.path.buildPath(_legacyPath, "Wave");
		}
		return std.path.buildPath(_path, "Sound");
	}
	/// その他リソースのディレクトリ。
	@property
	const
	string resourceDir() {
		return std.path.buildPath(_path, buildPath("Resource", "Image"));
	}

	/// 標準画像の拡張子。
	@property
	const
	string extImage() {return _extImg;}
	/// 標準BGMの拡張子。
	@property
	const
	string extBgm() {return _extBgm;}
	/// 標準SEの拡張子。
	@property
	const
	string extSound() {return _extSound;}
	/// 標準リソース画像の拡張子。
	@property
	const
	string resExtImage() {return _resExtImg;}

	/// 種族。
	@property
	Race[] races() {
		return _races.dup;
	}

	/// バトルを作成した際、最初に設定されているBGMの名前。
	@property
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
			if (cfnmatch(ext, _extImg)) {
				return f(_resExtImg);
			} else if (cfnmatch(ext, _extBgm)) {
				return f(_resExtBgm);
			} else if (cfnmatch(ext, _extSound)) {
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

	/// 標準のメッセージ送りテキストを返す。
	@property
	const
	string evtChildOK() {return _cEngine.okText is null ? _prop.sys.evtChildOK(legacyName) : _cEngine.okText;}

	/// このスキンでの特徴の名前を返す。
	const
	string sexName(Sex e) {
		return _cEngine.sexName.get(_prop.sys.sexName(e, ""), _prop.sys.sexName(e, legacyName));
	}
	/// ditto
	const
	string periodName(Period e) {
		return _cEngine.periodName.get(_prop.sys.periodName(e, ""), _prop.sys.periodName(e, legacyName));
	}
	/// ditto
	const
	string natureName(Nature e) {
		return _cEngine.natureName.get(_prop.sys.natureName(e, ""), _prop.sys.natureName(e, legacyName));
	}
	/// ditto
	const
	string makingsName(Makings e) {
		return _cEngine.makingsName.get(_prop.sys.makingsName(e, ""), _prop.sys.makingsName(e, legacyName));
	}
	/// ditto
	const
	string featureName(E)(E e) {
		static if (is(E:Sex)) {
			return sexName(e);
		} else static if (is(E:Period)) {
			return periodName(e);
		} else static if (is(E:Nature)) {
			return natureName(e);
		} else static if (is(E:Makings)) {
			return makingsName(e);
		} else static assert (0);
	}

	/// このスキンでの特徴のクーポンを返す。
	const
	string sexCoupon(Sex e) {
		return _prop.sys.convCoupon(sexName(e), CouponType.Hide, false);
	}
	/// ditto
	const
	string periodCoupon(Period e) {
		return _prop.sys.convCoupon(periodName(e), CouponType.Hide, false);
	}
	/// ditto
	const
	string natureCoupon(Nature e) {
		return _prop.sys.convCoupon(natureName(e), CouponType.Hide, false);
	}
	/// ditto
	const
	string makingsCoupon(Makings e) {
		return _prop.sys.convCoupon(makingsName(e), CouponType.Hide, false);
	}

	/// 特徴の能力修正値を返す。
	const
	int physicalMod(E)(E e, Physical phy) {
		static if (is(E:Sex)) {
			auto arr = _cEngine.physicalModSex;
		} else static if (is(E:Period)) {
			auto arr = _cEngine.physicalModPeriod;
		} else static if (is(E:Nature)) {
			auto arr = _cEngine.physicalModNature;
		} else static if (is(E:Makings)) {
			auto arr = _cEngine.physicalModMakings;
		} else static assert (0);

		if (auto p1 = (e in arr)) {
			if (auto p2 = (phy in *p1)) {
				return *p2;
			}
		}

		const(int[Physical]) init;
		return _prop.sys.physicalMod!E(legacyName).get(e, init).get(phy, 0);
	}
	/// ditto
	const
	real mentalMod(E)(E e, Mental mtl) {
		switch (mtl) {
		case Mental.UNAGGRESSIVE, Mental.UNCHEERFUL, Mental.UNBRAVE,
				Mental.UNCAUTIOUS, Mental.UNTRICKISH:
			return mentalMod(e, reverseMental(mtl)) * -1.0;
		default:
		}

		static if (is(E:Sex)) {
			auto arr = _cEngine.mentalModSex;
		} else static if (is(E:Period)) {
			auto arr = _cEngine.mentalModPeriod;
		} else static if (is(E:Nature)) {
			auto arr = _cEngine.mentalModNature;
		} else static if (is(E:Makings)) {
			auto arr = _cEngine.mentalModMakings;
		} else static assert (0);

		if (auto p1 = (e in arr)) {
			if (auto p2 = (mtl in *p1)) {
				return *p2;
			}
		}

		const(real[Mental]) init;
		return _prop.sys.mentalMod!E(legacyName).get(e, init).get(mtl, 0.0);
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
						if (ext[0] != '.') ext = "." ~ ext;
						ext1 = ext;
						ext2 = ext;
					}
					readExt("image", _extImg, _resExtImg);
					readExt("bgm", _extBgm, _resExtBgm);
					readExt("sound", _extSound, _resExtSound);
				};
				pNode.parse();
			};
			sNode.onTag["Races"] = (ref XNode node) {
				node.onTag["Race"] = (ref XNode node) {
					_races ~= Race.fromNode(node, LATEST_VERSION);
				};
				node.parse();
			};
			sNode.parse();
			typeof(_spChars) spCharsInit;
			_spChars = spCharsInit;
			auto fd = std.path.buildPath(resourceDir, "Font");
			foreach (path; clistdir(fd)) {
				path = std.path.buildPath(fd, path);
				if (!isDir(path) && cfnmatch(.extension(path), _resExtImg)) {
					auto dp = toUTF32(stripExtension(baseName(path)));
					auto c = std.uni.toUpper(dp[0]);
					switch (c) {
					case 'M', 'R', 'U', 'C', 'I', 'T', 'Y':
						c = std.uni.toUpper(dp[$ - 1]);
						break;
					default:
						break;
					}
					_spChars[c] = path;
				}
			}
		} catch (Exception e) {
			debugln(e);
		}
	}
}
