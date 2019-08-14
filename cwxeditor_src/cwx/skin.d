
module cwx.skin;

import cwx.background;
import cwx.card;
import cwx.coupon;
import cwx.features;
import cwx.imagesize;
import cwx.props;
import cwx.race;
import cwx.sjis;
import cwx.structs;
import cwx.system;
import cwx.types;
import cwx.utils;
import cwx.xml;

import std.algorithm;
import std.array;
import std.ascii;
import std.conv;
import std.exception;
import std.file;
import std.path;
import std.range;
import std.regex : regex, match;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;
import std.uni;
import std.utf;

/// BgImageをBgImageSに変換する。
BgImageS[] createBgImageSs(in BgImage[] bgs) { mixin(S_TRACE);
	BgImageS[] r;
	foreach (i, bg; bgs) { mixin(S_TRACE);
		BgImageS s;
		s.x = bg.x;
		s.y = bg.y;
		s.width = bg.width;
		s.height = bg.height;
		s.mask = bg.mask;
		s.layer = bg.layer;
		s.cellName = bg.cellName;
		auto ic = cast(ImageCell)bg;
		if (ic) { mixin(S_TRACE);
			s.type = "image";
			s.name = stripExtension(ic.path);
		}
		auto tc = cast(TextCell)bg;
		if (tc) { mixin(S_TRACE);
			s.type = "text";
			s.text = tc.text;
			s.fontName = tc.fontName;
			s.size = tc.size;
			s.color = tc.color;
			s.bold = tc.bold;
			s.italic = tc.italic;
			s.underline = tc.underline;
			s.strike = tc.strike;
			s.vertical = tc.vertical;
			s.antialias = tc.antialias;
			s.borderingType = tc.borderingType;
			s.borderingColor = tc.borderingColor;
			s.borderingWidth = tc.borderingWidth;
			s.updateType = tc.updateType;
		}
		auto cc = cast(ColorCell)bg;
		if (cc) { mixin(S_TRACE);
			s.type = "color";
			s.blendMode = cc.blendMode;
			s.gradientDir = cc.gradientDir;
			s.color1 = cc.color1;
			s.color2 = cc.color2;
		}
		auto pc = cast(PCCell)bg;
		if (pc) { mixin(S_TRACE);
			s.type = "pc";
			s.pcNumber = pc.pcNumber;
			s.expand = pc.expand;
		}
		r ~= s;
	}
	return r;
}
/// BgImageSをBgImageに変換する。
BgImage[] createBgImages(in Skin skin, in BgImageS[] bgs) { mixin(S_TRACE);
	BgImage[] r;
	r.length = bgs.length;
	foreach (i, b; bgs) { mixin(S_TRACE);
		switch (b.type) {
		case "image":
			size_t defIndex = 0;
			auto path = skin.findImagePath(setExtension(b.name, ".bmp"), "", LATEST_VERSION, defIndex);
			if (path.length) { mixin(S_TRACE);
				path = abs2rel(nabs(path), skin.tableDirs[defIndex]);
			} else { mixin(S_TRACE);
				path = setExtension(b.name, ".bmp");
			}
			r[i] = new ImageCell(path, "", b.x, b.y, b.width, b.height, b.mask);
			break;
		case "text":
			r[i] = new TextCell(b.text, b.fontName, b.size, b.color,
				b.bold, b.italic, b.underline, b.strike, b.vertical, b.antialias,
				b.borderingType, b.borderingColor, b.borderingWidth, b.updateType,
				"", b.x, b.y, b.width, b.height, b.mask);
			break;
		case "color":
			r[i] = new ColorCell(b.blendMode, b.gradientDir, b.color1, b.color2,
				"", b.x, b.y, b.width, b.height, b.mask);
			break;
		case "pc":
			r[i] = new PCCell(b.pcNumber, b.expand, "", b.x, b.y, b.width, b.height, b.mask);
			break;
		default:
			throw new Exception("Unknown type: " ~ b.type);
		}
		r[i].layer = b.layer;
		r[i].cellName = b.cellName;
	}
	return r;
}

/// リソースのマスク方式。
enum MaskType {
	NoMask, /// 背景を透明にしない。
	NormalMask, /// 左上のピクセルを透明色にする。
	RightMask, /// 右上のピクセルを透明色にする。
	Mask1_1, /// (1, 1)のピクセルを透明色にする。
}

/// シナリオの外観の情報。
class Skin {
	/// 設定に該当するスキンを探す。
	static Skin find(in CProps prop, string enginePath, string type, string sPath, bool legacy, string classicEngineRegex, string classicDataDirRegex, string classicMatchKey, in ClassicEngine[] cEngines, string defaultSkin) { mixin(S_TRACE);
		if (legacy && !type.length) { mixin(S_TRACE);
			return findLegacySkin(prop, enginePath, sPath, classicEngineRegex, classicDataDirRegex, classicMatchKey, cEngines, defaultSkin);
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
	static Skin[string] table(const(CProps) prop, string enginePath) { mixin(S_TRACE);
		if (!enginePath.length || !.exists(enginePath)) { mixin(S_TRACE);
			Skin[string] tbl;
			return tbl;
		}
		enginePath = nabs(enginePath);
		auto p = enginePath in skinTable;
		if (p) { mixin(S_TRACE);
			return *p;
		} else { mixin(S_TRACE);
			auto skinsDir = std.path.buildPath(dirName(enginePath), buildPath("Data", "Skin"));
			Skin[string] r;
			if (.exists(skinsDir) && .isDir(skinsDir)) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					foreach (skinDir; clistdir(skinsDir)) { mixin(S_TRACE);
						skinDir = std.path.buildPath(skinsDir, skinDir);
						if (!isDir(skinDir)) continue;
						auto file = std.path.buildPath(skinDir, "Skin.xml");
						if (!exists(file)) continue;
						try { mixin(S_TRACE);
							auto skin = new Skin(prop, file, enginePath);
							r[file] = skin;
						} catch (Exception e) {
							printStackTrace();
							debugln(e);
						}
					}
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
				}
			}
			skinTable[enginePath] = r;
			return r;
		}
	}
	/// クラシックなエンジンのスキンを返す。
	static Skin createLegacySkin(in CProps prop, string enginePath, string lEnginePath, string dataDirName, string execute, in ClassicEngine[] cEngines, string defaultSkin) { mixin(S_TRACE);
		// 標準のスキンをベースにする
		if (enginePath.length) enginePath = prop.toAppAbs(enginePath);
		if (lEnginePath.length) lEnginePath = nabs(prop.toAppAbs(lEnginePath));
		auto tbl = table(prop, enginePath);
		auto sp = defaultSkin in tbl;
		ClassicEngine cEngine;
		foreach (ce; cEngines) { mixin(S_TRACE);
			if (cfnmatch(nabs(prop.toAppAbs(ce.enginePath)), lEnginePath)) { mixin(S_TRACE);
				cEngine = ce.dup;
				break;
			}
		}
		Skin skin;
		if (sp) { mixin(S_TRACE);
			skin = new Skin(prop, sp.skinFile, enginePath);
		} else { mixin(S_TRACE);
			skin = new Skin(prop, enginePath);
		}
		skin.setupLegacy(lEnginePath, lEnginePath.dirName().buildPath(dataDirName), cEngine);
		skin._execute = execute;
		return skin;
	}
	/// クラシックなエンジンのスキンを探して返す。
	static Skin findLegacySkin(in CProps prop, string enginePath, string sPath, string classicEngineRegex, string classicDataDirRegex, string classicMatchKey, in ClassicEngine[] cEngines, string defaultSkin) { mixin(S_TRACE);
		string resDir, lEnginePath;
		findLegacy(sPath, resDir, lEnginePath, classicEngineRegex, classicDataDirRegex, classicMatchKey, cEngines);
		resDir = resDir.length ? nabs(resDir) : "";
		lEnginePath = lEnginePath.length ? nabs(lEnginePath) : "";

		string dataDirName = resDir.length ? abs2rel(resDir, lEnginePath.dirName()) : "";
		return createLegacySkin(prop, enginePath, lEnginePath, dataDirName, "", cEngines, defaultSkin);
	}
	private void setupLegacy(string lEnginePath, string resDir, ClassicEngine cEngine) { mixin(S_TRACE);
		_cEngine = cEngine;
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
	private static bool canAccess(string file) { mixin(S_TRACE);
		version (Windows) {
			import core.sys.windows.windows;
			immutable INVALID_FILE_ATTRIBUTES = -1;
			if (INVALID_FILE_ATTRIBUTES == GetFileAttributesW(toUTFz!(wchar*)(file))) { mixin(S_TRACE);
				return false;
			}
		}
		return true;
	}
	/// 指定されたディレクトリにリソースディレクトリが
	/// 含まれていればディレクトリ名を返す。
	static string findResDir(string path, string classicDataDirRegex, string classicMatchKey) { mixin(S_TRACE);
		auto p = path;
		auto regDir = .regex(to!dstring(classicDataDirRegex), 0 == filenameCharCmp('A', 'a') ? "i" : "");
		foreach (dir; clistdir(path)) { mixin(S_TRACE);
			auto pd = path.buildPath(dir);
			if (!canAccess(pd)) continue;
			try { mixin(S_TRACE);
				if (.isDir(pd)) { mixin(S_TRACE);
					if (!to!dstring(dir).match(regDir).empty && pd.buildPath(classicMatchKey).exists()) { mixin(S_TRACE);
						return dir;
					}
				}
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
		return "";
	}
	/// 指定されたディレクトリにクラシックエンジンとリソースディレクトリが
	/// 含まれていればtrueを返す。
	static bool hasClassicEngine(string path, out string resDir, out string enginePath, string classicEngineRegex, string classicDataDirRegex, string classicMatchKey, in ClassicEngine[] cEngines) { mixin(S_TRACE);
		foreach (cEngine; cEngines) { mixin(S_TRACE);
			string e = cEngine.enginePath.baseName();
			if (.isAbsolute(cEngine.dataDirName) ? true : .exists(path.buildPath(cEngine.dataDirName))) { mixin(S_TRACE);
				auto p = path.buildPath(e);
				if (p.exists()) { mixin(S_TRACE);
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

		foreach (file; clistdir(path)) { mixin(S_TRACE);
			string p = path.buildPath(file);
			if (!canAccess(p)) continue;
			try { mixin(S_TRACE);
				if (!.isDir(p) && !to!dstring(file).match(regExe).empty) { mixin(S_TRACE);
					enginePath = p;
					return true;
				}
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}

		enginePath = "";
		resDir = "";
		return false;
	}

	/// 指定されたシナリオが属すCardWirthを検索し、
	/// そのリソースディレクトリとエンジンのパスを返す。
	static bool findLegacy(string scPath, out string resDir, out string enginePath, string classicEngineRegex, string classicDataDirRegex, string classicMatchKey, in ClassicEngine[] cEngines) { mixin(S_TRACE);
		auto path = dirName(scPath);
		while (!hasClassicEngine(path, resDir, enginePath, classicEngineRegex, classicDataDirRegex, classicMatchKey, cEngines)) { mixin(S_TRACE);
			auto old = path;
			path = dirName(path);
			if (old == path) { mixin(S_TRACE);
				resDir ="";
				enginePath = "";
				return false;
			}
		}
		return true;
	}
	/// 指定されたシナリオが属すCardWirthPyを検索し、そのパスを返す。
	static string findCardWirthPy(string scPath, string exeName, string dataName) { mixin(S_TRACE);
		auto path = dirName(scPath);
		while (!path.buildPath(exeName).exists() || !path.buildPath(dataName).exists()) { mixin(S_TRACE);
			auto old = path;
			path = dirName(path);
			if (old == path) { mixin(S_TRACE);
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
	private ModData[Sex] _sexes;
	private ModData[Period] _periods;
	private ModData[Nature] _natures;
	private ModData[Makings] _makings;
	private string _number1Coupon = "";
	private ActionCard[ActionCardType] _actionCards;

	private static immutable _extImg = [
		".bmp", ".jpg", ".jpeg", ".png", ".gif",
		".jpy1", ".jpdc", ".jptx",
	];
	private static immutable _extBgm = [
		".aiff", // AIFF
		".mid", ".midi", // MIDI
		".mod", ".s3m", ".xm", ".it", ".mt2", ".669", ".med", // MOD
		".mp3", // MP3
		".ogg", ".ogv", ".oga", ".ogx", // Ogg
		".voc", // VOC
		".wav" // WAV/RIFF
	];
	private static immutable _extSound = _extBgm;

	private string _path;
	private string _skinFile;
	private string _name;
	private string _type;
	private string _author;
	private string _desc;
	private bool _sourceOfMaterialsIsClassicEngine = false;
	private string[dchar] _spChars;
	private Race[] _races;

	/// 空のスキンを生成する。
	this (const(CProps) prop, string enginePath) { mixin(S_TRACE);
		_prop = prop;
		_enginePath = enginePath;
	}
	private this (const(CProps) prop, string skinFile, string enginePath) { mixin(S_TRACE);
		this (prop, enginePath);
		if (skinFile.length) { mixin(S_TRACE);
			loadFromXML(prop, skinFile, new XMLInfo(prop.sys, LATEST_VERSION));
		}
	}
	/// スキンの名称。クラシックの場合は""。
	@property
	const
	string name() { return _name; }
	/// スキンのタイプ。クラシックの場合は""。
	@property
	const
	string type() { return _type; }
	/// スキンのファイル名。クラシックの場合は""。
	@property
	const
	string skinFile() { return _skinFile; }
	/// スキンのパス。クラシックの場合はlegacyDataPathで代替する。
	@property
	const
	string path() { return _path; }
	/// 含まれる素材はクラシックなエンジンからそのまま持ってきたものか。
	@property
	const
	bool sourceOfMaterialsIsClassicEngine() { return _sourceOfMaterialsIsClassicEngine; }

	/// スキンが存在しない時に使用される空スキンか。
	@property
	const
	bool isEmpty() { return !(_path.length || _legacyPath.length); }

	private static string findResource(string dir, string name, in string[] exts) { mixin(S_TRACE);
		foreach (ext; exts) {
			auto path = dir.buildPath(name).setExtension(ext);
			if (path.exists()) return path;
		}
		return "";
	}

	/// リソース画像のパス。
	const
	string resSummary(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		foreach (tableDir; tableDirs) { mixin(S_TRACE);
			auto path = findResource(tableDir, "Bill", extImage);
			if (path.length) return path;
		}
		return "";
	}
	/// ditto
	const
	string resMenuCard(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "NORMAL"), extImage);
	}

	/// ditto
	const
	string resCastCard(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "LARGE"), extImage);
	}
	/// ditto
	const
	string resCastCardInjury(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "INJURY"), extImage);
	}
	/// ditto
	const
	string resCastCardDanger(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "DANGER"), extImage);
	}
	/// ditto
	const
	string resCastCardFaint(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "FAINT"), extImage);
	}
	/// ditto
	const
	string resCastCardBind(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "BIND"), extImage);
	}
	/// ditto
	const
	string resCastCardParaly(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "PARALY"), extImage);
	}
	/// ditto
	const
	string resCastCardPetrif(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "PETRIF"), extImage);
	}
	/// ditto
	const
	string resCastCardSleep(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "SLEEP"), extImage);
	}
	/// ditto
	const
	string resLifeBar(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("Status", "LIFEBAR"), extImage);
	}
	/// ditto
	const
	string resLifeGuage(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("Status", "LIFEGUAGE"), extImage);
	}
	/// ditto
	const
	string resLifeGuage2(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NormalMask;
		return findResource(resourceDir, buildPath("Status", "LIFEGUAGE2"), extImage);
	}
	/// ditto
	const
	string resLifeGuage2Mask(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NormalMask;
		return findResource(resourceDir, buildPath("Status", "LIFEGUAGE2_MASK"), extImage);
	}
	/// ditto
	const
	string resEnhanceUp(out MaskType maskType, Enhance enh) { mixin(S_TRACE);
		maskType = MaskType.Mask1_1;
		switch (enh) {
		case Enhance.Action: return findResource(resourceDir, buildPath("Status", "UP0"), extImage);
		case Enhance.Avoid: return findResource(resourceDir, buildPath("Status", "UP1"), extImage);
		case Enhance.Resist: return findResource(resourceDir, buildPath("Status", "UP2"), extImage);
		case Enhance.Defense: return findResource(resourceDir, buildPath("Status", "UP3"), extImage);
		default: assert (0);
		}
	}
	/// ditto
	const
	string resEnhanceDown(out MaskType maskType, Enhance enh) { mixin(S_TRACE);
		maskType = MaskType.Mask1_1;
		switch (enh) {
		case Enhance.Action: return findResource(resourceDir, buildPath("Status", "DOWN0"), extImage);
		case Enhance.Avoid: return findResource(resourceDir, buildPath("Status", "DOWN1"), extImage);
		case Enhance.Resist: return findResource(resourceDir, buildPath("Status", "DOWN2"), extImage);
		case Enhance.Defense: return findResource(resourceDir, buildPath("Status", "DOWN3"), extImage);
		default: assert (0);
		}
	}
	/// ditto
	const
	string resMentality(out MaskType maskType, Mentality mtly) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		switch (mtly) {
		case Mentality.Normal: return findResource(resourceDir, buildPath("Status", "MIND0"), extImage);
		case Mentality.Sleep: return findResource(resourceDir, buildPath("Status", "MIND1"), extImage);
		case Mentality.Confuse: return findResource(resourceDir, buildPath("Status", "MIND2"), extImage);
		case Mentality.Overheat: return findResource(resourceDir, buildPath("Status", "MIND3"), extImage);
		case Mentality.Brave: return findResource(resourceDir, buildPath("Status", "MIND4"), extImage);
		case Mentality.Panic: return findResource(resourceDir, buildPath("Status", "MIND5"), extImage);
		default: assert (0);
		}
	}
	/// ditto
	const
	string resBind(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("Status", "MAGIC0"), extImage);
	}
	/// ditto
	const
	string resSilence(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("Status", "MAGIC1"), extImage);
	}
	/// ditto
	const
	string resFaceUp(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("Status", "MAGIC2"), extImage);
	}
	/// ditto
	const
	string resAntiMagic(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("Status", "MAGIC3"), extImage);
	}
	/// ditto
	const
	string resParalyze(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("Status", "BODY1"), extImage);
	}
	/// ditto
	const
	string resPoison(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("Status", "BODY0"), extImage);
	}
	/// ditto
	const
	string resSummon(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("Status", "SUMMON"), extImage);
	}

	/// ditto
	const
	string resItemCard(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "ITEM"), extImage);
	}
	/// ditto
	const
	string resSkillCard(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "SKILL"), extImage);
	}
	/// ditto
	const
	string resBeastCard(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "BEAST"), extImage);
	}
	/// ditto
	const
	string resOptionCard(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "OPTION"), extImage);
	}
	/// ditto
	const
	string resInfoCard(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "INFO"), extImage);
	}
	/// ditto
	const
	string resCardHold(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "HOLD"), extImage);
	}
	/// ditto
	const
	string resCardPenalty(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NoMask;
		return findResource(resourceDir, buildPath("CardBg", "PENALTY"), extImage);
	}
	/// ditto
	const
	string resRare(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.RightMask;
		return findResource(resourceDir, buildPath("CardBg", "RARE"), extImage);
	}
	/// ditto
	const
	string resPremier(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.RightMask;
		return findResource(resourceDir, buildPath("CardBg", "PREMIER"), extImage);
	}
	/// ditto
	const
	string resAptVeryHigh(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NormalMask;
		return findResource(resourceDir, buildPath("Stone", "HAND3"), extImage);
	}
	/// ditto
	const
	string resAptHigh(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NormalMask;
		return findResource(resourceDir, buildPath("Stone", "HAND2"), extImage);
	}
	/// ditto
	const
	string resAptNormal(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NormalMask;
		return findResource(resourceDir, buildPath("Stone", "HAND1"), extImage);
	}
	/// ditto
	const
	string resAptLow(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NormalMask;
		return findResource(resourceDir, buildPath("Stone", "HAND0"), extImage);
	}
	/// ditto
	const
	string resUse0(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NormalMask;
		return findResource(resourceDir, buildPath("Stone", "HAND5"), extImage);
	}
	/// ditto
	const
	string resUse1(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NormalMask;
		return findResource(resourceDir, buildPath("Stone", "HAND6"), extImage);
	}
	/// ditto
	const
	string resUse2(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NormalMask;
		return findResource(resourceDir, buildPath("Stone", "HAND7"), extImage);
	}
	/// ditto
	const
	string resUse3(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NormalMask;
		return findResource(resourceDir, buildPath("Stone", "HAND8"), extImage);
	}
	/// ditto
	const
	string resUse4(out MaskType maskType) { mixin(S_TRACE);
		maskType = MaskType.NormalMask;
		return findResource(resourceDir, buildPath("Stone", "HAND9"), extImage);
	}

	/// CardWirth本体のパス。
	/// クラシックなシナリオの編集中は、そのシナリオが
	/// 属すと思われるパスを返す。
	@property
	const
	string engine() { mixin(S_TRACE);
		if (_legacyEngine.length) { mixin(S_TRACE);
			return legacyEngine();
		} else { mixin(S_TRACE);
			return _enginePath;
		}
	}

	/// クラシックなCardWirth本体のパス。
	/// 所属エンジンが無いか、クラシックでないシナリオの編集中であれば""を返す。
	@property
	const
	string legacyEngine() { mixin(S_TRACE);
		if (!_legacyEngine.length) return "";
		return _legacyEngine;
	}

	/// エンジンを実行する際のパス。
	@property
	const
	string executeEngine() { mixin(S_TRACE);
		if (_legacyEngine.length) { mixin(S_TRACE);
			if (_execute.length) { mixin(S_TRACE);
				return _legacyEngine.dirName().buildPath(_execute);
			}
			return legacyEngine();
		} else { mixin(S_TRACE);
			return _enginePath;
		}
	}

	/// クラシックなシナリオの編集中は、拡張子を除く所属エンジンのパスを返す。
	/// 所属エンジンが無いか、クラシックでないシナリオの編集中であれば""を返す。
	@property
	const
	string legacyName() { return _legacyEngine.length ? stripExtension(baseName(_legacyEngine)) : ""; }

	/// クラシックなCardWirthのDataディレクトリのパス。
	@property
	const
	string legacyDataPath() { return _legacyPath; }

	/// クラシックなCardWirthEditorで作成されたシナリオのスキンならtrue。
	@property
	const
	bool legacy() { return _legacy; }

	/// エンジンの設定を読み込んで返す。
	const
	string[string] loadEngineSettings() { mixin(S_TRACE);
		typeof(return) r;
		if (_legacyEngine.length) { mixin(S_TRACE);
			auto ini = _legacyEngine.dirName().buildPath("cwex.ini");
			if (!ini.exists()) { mixin(S_TRACE);
				ini = _legacyEngine.dirName().buildPath("CardWirth.cfg");
				if (!ini.exists()) return r;
			}
			char* ptr = null;
			scope (exit) {
				if (ptr) freeAll(ptr);
			}
			string iniText;
			try { mixin(S_TRACE);
				iniText = std.file.readText(ini);
			} catch (UTFException e) {
				printStackTrace();
				debugln(e);
				// ここではMS932を想定
				iniText = .touni(readBinaryFrom!char(ini, ptr));
			}
			/// UTF-8とは限らないため、バイナリで読み込む
			foreach (line; iniText.splitLines()) { mixin(S_TRACE);
				auto ln = line.split("=");
				if (2 != ln.length) continue;
				auto key = ln[0].strip();
				auto value = ln[1].strip();
				r[.toLower(assumeUnique(key))] = assumeUnique(value);
			}
		}
		// 1.50
		if ("musicvol" in r && "musicapi" !in r) { mixin(S_TRACE);
			r["musicapi"] = "bass";
		}
		if ("soundvol" in r && "soundapi" !in r) { mixin(S_TRACE);
			r["soundapi"] = "bass";
		}
		return r;
	}

	/// CWPyのSettings.xmlからサウンドフォントのリストを読み込んで返す。
	const
	string[] loadSoundFonts() { mixin(S_TRACE);
		if (!_enginePath.length) return [];
		auto path = _enginePath.dirName().buildPath("Settings.xml");
		if (!path.exists()) return [];
		auto node = XNode.parse(std.file.readText(path));
		string[] r;
		node.onTag["SoundFonts"] = (ref XNode node) { mixin(S_TRACE);
			node.onTag["SoundFont"] = (ref XNode node) { mixin(S_TRACE);
				if (node.attr!bool("enabled", false, true) && node.value != "") { mixin(S_TRACE);
					r ~= node.value;
				}
			};
			node.parse();
		};
		node.parse();
		return r;
	}

	/// エンジン内のリソースを使用している場合はtrue。
	@property
	const
	bool useLegacyRes() { mixin(S_TRACE);
		version (Windows) {
			return legacyEngine.length > 0;
		} else {
			return false;
		}
	}

	/// シナリオの素材を置くディレクトリの標準。シナリオのルートからの相対パス。
	@property
	const
	string materialPath() { mixin(S_TRACE);
		return legacy ? "" : "Material";
	}

	/// pathがシナリオ素材であればtrueを返す。
	/// checkがfalseの場合、拡張子による判断のみを行う。
	/// checkをtrueにすると、ファイルの存在と内容をチェックする。
	/// (現行バージョンでは内容チェックは背景イメージのみ)
	const
	bool isMaterial(string path, bool check = false) { mixin(S_TRACE);
		return isSE(path, check) || isBGM(path, check) || isBgImage(path, false, check);
	}

	/// pathが効果音として使用可能か。
	const
	bool isSE(string path, bool check = false) { mixin(S_TRACE);
		auto ext = .toLower(.extension(path));
		if (legacy) { mixin(S_TRACE);
			switch (ext) {
			case ".mp3": // MP3
			case ".ogg", ".ogv", ".oga", ".ogx": // Ogg
			case ".wav": // WAV/RIFF
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
			return true;
		default:
			return false;
		}
	}
	/// pathを使用する際の警告(一部環境で再生不可等)。
	static string[] warningSE(in CProps prop, string path, bool legacy, string targVer) { mixin(S_TRACE);
		if (path == "") return [];
		auto ext = .toLower(.extension(path));
		string[] r;
		if (legacy) { mixin(S_TRACE);
			switch (ext) {
			case ".ogg", ".ogv", ".oga", ".ogx": // Ogg
				if (!prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
					r ~= prop.msgs.oggMayNotCorrespond;
				}
				break;
			default:
				break;
			}
		}
		if (!_extSound.contains(ext)) { mixin(S_TRACE);
			r ~= prop.msgs.warningInvalidFileExtensionSound;
		}
		return r;
	}
	/// pathがBGMとして使用可能か。
	const
	bool isBGM(string path, bool check = false) { mixin(S_TRACE);
		auto ext = .toLower(.extension(path));
		if (legacy) { mixin(S_TRACE);
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
	static string[] warningBGM(in CProps prop, string path, bool legacy, string targVer) { mixin(S_TRACE);
		if (path == "") return [];
		auto ext = .toLower(.extension(path));
		string[] r;
		if (legacy) { mixin(S_TRACE);
			switch (ext) {
			case ".mp3": // MP3
				if (!prop.targetVersion("1.29", targVer)) { mixin(S_TRACE);
					r ~= prop.msgs.mp3LoopMayNotCorrespond;
				}
				break;
			case ".ogg", ".ogv", ".oga", ".ogx": // Ogg
				if (!prop.targetVersion("1.50", targVer)) { mixin(S_TRACE);
					r ~= prop.msgs.oggMayNotCorrespond;
				}
				break;
			default:
				break;
			}
		}
		if (!_extBgm.contains(ext)) { mixin(S_TRACE);
			r ~= prop.msgs.warningInvalidFileExtensionSound;
		}
		return r;
	}
	/// pathがカード画像として使用可能か。
	const
	bool isCardImage(string path, bool ignoreSize) { mixin(S_TRACE);
		string ext;
		ubyte[] bin;
		if (isBinImg(path)) { mixin(S_TRACE);
			bin = strToBImg(path);
			ext = imageType(bin);
		} else { mixin(S_TRACE);
			ext = .extension(path);
		}
		ext = .toLower(ext);
		if (legacy && ext != ".bmp" && ext != ".png" && ext != ".gif") { mixin(S_TRACE);
			return false;
		}
		if (ignoreSize) return isImageExt(path);
		try { mixin(S_TRACE);
			uint x, y;
			if (bin) { mixin(S_TRACE);
				if (!imageSize!(ubyte[])(bin, x, y)) return false;
			} else { mixin(S_TRACE);
				if (!imageSize(path, x, y)) return false;
			}
			return x == _prop.looks.cardSize.width && y == _prop.looks.cardSize.height;
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
		return false;
	}

	/// pathが背景画像として使用可能か。
	const
	bool isBgImage(string path, bool excludeCardSize = false, bool check = false) { mixin(S_TRACE);
		if (isBinImg(path)) return true;
		auto ext = .toLower(.extension(path));
		if (ext == ".jpy1"
				|| ext == ".jptx"
				|| ext == ".jpdc") { mixin(S_TRACE);
			return true;
		}
		if (legacy && ext != ".bmp"
				&& ext != ".jpg"
				&& ext != ".jpeg"
				&& ext != ".png"
				&& ext != ".gif") { mixin(S_TRACE);
			return false;
		}
		if (excludeCardSize && isCardImage(path, false)) { mixin(S_TRACE);
			return false;
		}
		if (check) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				uint x, y;
				return imageSize(path, x, y);
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		} else { mixin(S_TRACE);
			return isImageExt(path);
		}
		return false;
	}
	/// pathを使用する際の警告(一部環境で表示不可等)。
	static string[] warningImage(in CProps prop, string path, bool legacy, bool includeType, string targVer) { mixin(S_TRACE);
		if (path == "") return [];
		string[] r;
		string ext;
		if (path.isBinImg) { mixin(S_TRACE);
			auto bin =  cast(ubyte[])strToBImg(path);
			ext = imageType(bin);
			includeType = true;
		} else { mixin(S_TRACE);
			ext = .toLower(.extension(path));
		}
		if (legacy) { mixin(S_TRACE);
			switch (ext) {
			case ".png": // PNG
				if (includeType) {
					r ~= prop.msgs.warningIncludedPNGImage;
				} else { mixin(S_TRACE);
					if (!prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
						r ~= prop.msgs.pngMayNotCorrespond;
					}
				}
				break;
			case ".gif": // GIF
				if (includeType) {
					r ~= prop.msgs.warningIncludedGIFImage;
				} else { mixin(S_TRACE);
					if (!prop.targetVersion("1.30", targVer)) { mixin(S_TRACE);
						r ~= prop.msgs.gifMayNotCorrespond;
					}
				}
				break;
			default:
				break;
			}
		}
		if (!path.isBinImg && !_extImg.contains(ext)) { mixin(S_TRACE);
			r ~= prop.msgs.warningInvalidFileExtensionImage;
		}
		return r;
	}

	/// 特殊文字の情報。
	@property
	const
	const(string[dchar]) spChars() { return _spChars; }

	/// 指定バージョンで使用可能なWSN標準素材が入ったディレクトリ群。
	const
	private string[] wsnResDirs(in string[] dNames, string wsnVer) { mixin(S_TRACE);
		if (wsnVer == "" || _enginePath == "" || !_enginePath.exists()) return [];
		auto engineDir = _enginePath.dirName();
		string[] r;
		foreach (ver; VERSIONS) { mixin(S_TRACE);
			if (ver == "") continue;
			if (!isTargetVersion(wsnVer, ver)) continue;
			foreach (dName; dNames) { mixin(S_TRACE);
				auto dir = engineDir.buildPath("Data/Materials/Wsn.%s/%s".format(ver, dName));
				if (dir.exists()) r ~= dir;
			}
		}
		return r;
	}
	/// ditto
	@property
	const
	string[] wsnTableDirs(string wsnVer) { return wsnResDirs(["Table"], wsnVer); }
	/// ditto
	@property
	const
	string[] wsnMusicDirs(string wsnVer) { return wsnResDirs(["Bgm", "BgmAndSound"], wsnVer); }
	/// ditto
	@property
	const
	string[] wsnSoundDirs(string wsnVer) { return wsnResDirs(["Sound", "BgmAndSound"], wsnVer); }

	const
	private bool has(alias isT, Arg ...)(string dir, bool forceRefresh, Arg args) { mixin(S_TRACE);
		synchronized (this) { mixin(S_TRACE);
			static struct Has {
				Arg args;
				bool result;
			}
			mixin FileCache!(Has);
			if (!forceRefresh) { mixin(S_TRACE);
				auto ca = cache(dir);
				if (ca && ca.value.args == args) { mixin(S_TRACE);
					return ca.value.result;
				}
			}

			bool r = false;
			if (dir.exists() && dir.isDir()) { mixin(S_TRACE);
				foreach (file; dir.dirEntries(SpanMode.shallow)) { mixin(S_TRACE);
					if (isT(file, args)) { mixin(S_TRACE);
						r = true;
						break;
					}
				}
			}
			putCache(dir, Has(args, r));
			return r;
		}
	}

	/// 各種の素材がdirに含まれていればtrueを返す。
	const
	bool hasCardImage(string dir, bool forceRefresh, bool ignoreSize) { return has!(isCardImage)(dir, forceRefresh, ignoreSize); }
	/// ditto
	const
	bool hasBgImage(string dir, bool forceRefresh, bool excludeCardSize) { return has!(isBgImage)(dir, forceRefresh, excludeCardSize); }
	/// ditto
	const
	bool hasBGM(string dir, bool forceRefresh) { return has!(isBGM)(dir, forceRefresh); }
	/// ditto
	const
	bool hasSE(string dir, bool forceRefresh) { return has!(isSE)(dir, forceRefresh); }

	/// 指定バージョンのWSN標準素材が存在すればtrueを返す。
	const
	private bool hasWsnRes(alias isT, Arg...)(in string[] dirs, string wsnVer, bool forceRefresh, Arg args) { mixin(S_TRACE);
		if (wsnVer == "" || !_enginePath.exists()) return false;
		auto engineDir = _enginePath.dirName();
		string[] r;

		foreach (dir; dirs) { mixin(S_TRACE);
			if (has!(isT)(dir, forceRefresh, args)) return true;
		}
		return false;
	}
	const
	bool hasWsnCardImage(string wsnVer, bool forceRefresh, bool ignoreSize) { mixin(S_TRACE);
		return hasWsnRes!(isCardImage)(wsnTableDirs(wsnVer), wsnVer, forceRefresh, ignoreSize);
	}
	/// ditto
	const
	bool hasWsnBgImage(string wsnVer, bool forceRefresh, bool excludeCardSize) { mixin(S_TRACE);
		return hasWsnRes!(isBgImage)(wsnTableDirs(wsnVer), wsnVer, forceRefresh, excludeCardSize);
	}
	/// ditto
	const
	bool hasWsnBGM(string wsnVer, bool forceRefresh) { mixin(S_TRACE);
		return hasWsnRes!(isBGM)(wsnMusicDirs(wsnVer), wsnVer, forceRefresh);
	}
	/// ditto
	const
	bool hasWsnSE(string wsnVer, bool forceRefresh) { mixin(S_TRACE);
		return hasWsnRes!(isSE)(wsnSoundDirs(wsnVer), wsnVer, forceRefresh);
	}

	const
	private string[] list(alias isT, bool UseFlag = false)(in string[] dirs, bool logicalSort, bool forceRefresh, bool flag, bool sort = true) { mixin(S_TRACE);
		string[] r;
		foreach (dir; dirs) r ~= listImpl!(isT, UseFlag)(dir, forceRefresh, flag);
		if (sort) { mixin(S_TRACE);
			if (logicalSort) { mixin(S_TRACE);
				r = cwx.utils.sort!(fnncmp)(r);
			} else { mixin(S_TRACE);
				r = cwx.utils.sort!(fncmp)(r);
			}
		}
		return r;
	}

	const
	private string[] listImpl(alias isT, bool UseFlag = false)(string dir, bool forceRefresh, bool flag) { mixin(S_TRACE);
		synchronized (this) { mixin(S_TRACE);
			static struct Files {
				bool flag;
				string[] files;
			}
			mixin FileCache!(Files);
			if (!forceRefresh) { mixin(S_TRACE);
				auto ca = cache(dir);
				if (ca && ca.value.flag == flag) { mixin(S_TRACE);
					return ca.value.files;
				}
			}
			string[] r;
			foreach (fp; clistdir(dir)) { mixin(S_TRACE);
				fp = std.path.buildPath(dir, fp);
				static if (UseFlag) {
					if (isT(fp, flag)) { mixin(S_TRACE);
						r ~= baseName(fp);
					}
				} else { mixin(S_TRACE);
					if (isT(fp)) { mixin(S_TRACE);
						r ~= baseName(fp);
					}
				}
			}
			putCache(dir, Files(flag, r));
			return r;
		}
	}

	/// dirに含まれるカード画像の一覧。
	const
	string[] cards(string dir, bool logicalSort, bool forceRefresh, bool ignoreSize) { mixin(S_TRACE);
		return list!(isCardImage, true)([dir], logicalSort, forceRefresh, ignoreSize);
	}

	/// 標準の背景画像。
	const
	string[] tables(bool logicalSort, bool forceRefresh = false, bool excludeCardSize = false) { mixin(S_TRACE);
		return list!(isBgImage, true)(tableDirs, logicalSort, forceRefresh, excludeCardSize, false);
	}

	/// dirに含まれる背景画像の一覧。
	const
	string[] tables(string dir, bool logicalSort, bool forceRefresh, bool excludeCardSize) { mixin(S_TRACE);
		return list!(isBgImage, true)([dir], logicalSort, forceRefresh, excludeCardSize, false);
	}

	/// 標準のBGM。
	const
	string[] musics(bool logicalSort, bool forceRefresh = false) { mixin(S_TRACE);
		return list!(isBGM)(bgmDirs, logicalSort, forceRefresh, false);
	}

	/// dirに含まれるBGMの一覧。
	const
	string[] musics(string dir, bool logicalSort, bool forceRefresh) { mixin(S_TRACE);
		return list!(isBGM)([dir], logicalSort, forceRefresh, false);
	}

	/// 標準のSE。
	const
	string[] sounds(bool logicalSort, bool forceRefresh = false) { mixin(S_TRACE);
		return list!(isSE)(seDirs, logicalSort, forceRefresh, false);
	}

	/// dirに含まれるSEの一覧。
	const
	string[] sounds(string dir, bool logicalSort, bool forceRefresh) { mixin(S_TRACE);
		return list!(isSE)([dir], logicalSort, forceRefresh, false);
	}

	/// WSNの標準素材の一覧。
	const
	private string[] wsnList(alias isT, bool UseFlag)(in string[] dirs, string wsnVer, bool logicalSort, bool forceRefresh, bool flag) { mixin(S_TRACE);
		if (wsnVer == "" || !_enginePath.exists()) return [];
		auto engineDir = _enginePath.dirName();
		return list!(isT, UseFlag)(dirs, logicalSort, forceRefresh, flag, true);
	}
	/// ditto
	const
	string[] wsnCards(string wsnVer, bool logicalSort, bool forceRefresh, bool ignoreSize) { mixin(S_TRACE);
		return wsnList!(isCardImage, true)(wsnTableDirs(wsnVer), wsnVer, logicalSort, forceRefresh, ignoreSize);
	}
	/// ditto
	const
	string[] wsnTables(string wsnVer, bool logicalSort, bool forceRefresh, bool excludeCardSize) { mixin(S_TRACE);
		return wsnList!(isBgImage, true)(wsnTableDirs(wsnVer), wsnVer, logicalSort, forceRefresh, excludeCardSize);
	}
	/// ditto
	const
	string[] wsnMusics(string wsnVer, bool logicalSort, bool forceRefresh) { mixin(S_TRACE);
		return wsnList!(isBGM, false)(wsnMusicDirs(wsnVer), wsnVer, logicalSort, forceRefresh, false);
	}
	/// ditto
	const
	string[] wsnSounds(string wsnVer, bool logicalSort, bool forceRefresh) { mixin(S_TRACE);
		return wsnList!(isSE, false)(wsnSoundDirs(wsnVer), wsnVer, logicalSort, forceRefresh, false);
	}

	/// 標準素材ディレクトリのルート。
	@property
	const
	string resDir() { mixin(S_TRACE);
		if (_legacyPath.length) { mixin(S_TRACE);
			return _legacyPath;
		}
		return _path;
	}
	/// 標準の背景画像のディレクトリ。
	@property
	const
	string[] tableDirs() { mixin(S_TRACE);
		if (_legacyPath.length) { mixin(S_TRACE);
			return [std.path.buildPath(_legacyPath, "Table")];
		}
		return [std.path.buildPath(_path, "Table")];
	}
	/// 標準のBGMのディレクトリ。
	@property
	const
	string[] bgmDirs() { mixin(S_TRACE);
		if (_legacyPath.length) { mixin(S_TRACE);
			return [std.path.buildPath(_legacyPath, "Midi")];
		}
		return [std.path.buildPath(_path, "Bgm"), std.path.buildPath(_path, "BgmAndSound")];
	}
	/// 標準のSEのディレクトリ。
	@property
	const
	string[] seDirs() { mixin(S_TRACE);
		if (_legacyPath.length) { mixin(S_TRACE);
			return [std.path.buildPath(_legacyPath, "Wave")];
		}
		return [std.path.buildPath(_path, "Sound"), std.path.buildPath(_path, "BgmAndSound")];
	}
	/// その他リソースのディレクトリ。
	@property
	const
	string resourceDir() { mixin(S_TRACE);
		return std.path.buildPath(_path, buildPath("Resource", "Image"));
	}

	/// 標準画像の拡張子。
	@property
	const
	const(string)[] extImage() { return _extImg; }
	/// 標準BGMの拡張子。
	@property
	const
	const(string)[] extBgm() { return _extBgm; }
	/// 標準SEの拡張子。
	@property
	const
	const(string)[] extSound() { return _extSound; }

	/// 種族。
	@property
	inout
	inout(Race)[] races() { mixin(S_TRACE);
		return _races;
	}

	/// バトルを作成した際、最初に設定されているBGMの名前。
	@property
	const
	string defBattle(string sPath, string wsnVer) { return findPath("DefBattle.mid", extBgm, bgmDirs, sPath, wsnVer, wsnMusicDirs(wsnVer)).baseName(); }

	/// 指定されたパスを元に、まずシナリオのディレクトリを、
	/// 無ければ本体付属のディレクトリを検索し、見つかったパスを返す。
	/// 付属ディレクトリに見つからなければ拡張子をスキン指定のものに
	/// 変更し、再度付属ディレクトリを検索する。
	/// それでも見つからなければ""を返す。
	/// Params:
	/// path = 検索対象のパス。
	/// sPath = シナリオのディレクトリ。
	/// isSkinMaterial = 結果がスキンまたはクラシックなエンジンの付属ディレクトリ内であればtrue。
	/// isEngineMaterial = 結果がエンジンの付属ディレクトリ内であればtrue。
	/// Returns: ファイルパス。見つからなかった場合は""。
	const
	string findImagePathF(string path, string sPath, string wsnVer, out bool isSkinMaterial, out bool isEngineMaterial) { mixin(S_TRACE);
		isSkinMaterial = false;
		isEngineMaterial = false;
		return findPathF(path, extImage, tableDirs, sPath, wsnVer, wsnTableDirs(wsnVer), isSkinMaterial, isEngineMaterial);
	}
	/// ditto
	const
	string findImagePath(string path, string sPath, string wsnVer) { mixin(S_TRACE);
		bool dummy;
		return findImagePathF(path, sPath, wsnVer, dummy, dummy);
	}
	/// ditto
	const
	string findImagePath(string path, string sPath, string wsnVer, out size_t defIndex) { mixin(S_TRACE);
		bool dummy;
		return findPathF(path, extImage, tableDirs, sPath, wsnVer, wsnTableDirs(wsnVer), dummy, dummy, defIndex);
	}
	/// ditto
	const
	string findPathF(string path, in string[] exts, in string[] defDirs, string sPath, string wsnVer, in string[] wsnDirs, out bool isSkinMaterial, out bool isEngineMaterial) { mixin(S_TRACE);
		size_t defIndex;
		return findPathF(path, exts, defDirs, sPath, wsnVer, wsnDirs, isSkinMaterial, isEngineMaterial, defIndex);
	}
	/// ditto
	const
	string findPathF(string path, in string[] exts, in string[] defDirs, string sPath, string wsnVer, in string[] wsnDirs, out bool isSkinMaterial, out bool isEngineMaterial, out size_t defIndex) { mixin(S_TRACE);
		isSkinMaterial = false;
		isEngineMaterial = false;
		if (path.length == 0) return "";
		if (isBinImg(path)) return path;
		string p;
		if (sPath && sPath.length) { mixin(S_TRACE);
			p = std.path.buildPath(sPath, path);
			if (exists(p)) { mixin(S_TRACE);
				return p;
			}
		}
		isSkinMaterial = true;
		foreach (i, defDir; defDirs) { mixin(S_TRACE);
			p = std.path.buildPath(defDir, baseName(path));
			if (exists(p)) { mixin(S_TRACE);
				defIndex = i;
				return p;
			}
			foreach (ext; exts) { mixin(S_TRACE);
				p = setExtension(p, ext);
				if (exists(p)) { mixin(S_TRACE);
					defIndex = i;
					return p;
				}
			}
		}
		isSkinMaterial = false;
		if (!legacy && _enginePath != "" && _enginePath.exists() && wsnVer != "") { mixin(S_TRACE);
			isEngineMaterial = true;
			auto engineDir = _enginePath.dirName();
			foreach (defDir; defDirs) { mixin(S_TRACE);
				auto dName = defDir.baseName();
				foreach (dir; wsnDirs) { mixin(S_TRACE);
					p = std.path.buildPath(dir, baseName(path));
					if (exists(p)) { mixin(S_TRACE);
						return p;
					}
					foreach (ext; exts) { mixin(S_TRACE);
						p = setExtension(p, ext);
						if (exists(p)) return p;
					}
				}
			}
			isEngineMaterial = false;
		}

		return "";
	}
	/// ditto
	const
	string findPath(string path, in string[] exts, in string[] defDirs, string sPath, string wsnVer, in string[] wsnDirs) { mixin(S_TRACE);
		bool dummy;
		return findPathF(path, exts, defDirs, sPath, wsnVer, wsnDirs, dummy, dummy);
	}
	/// 指定された素材がスキン付属のディレクトリに存在するものか。
	const
	bool isSkinResource(string path, in string[] exts, in string[] defDirs, string sPath) { mixin(S_TRACE);
		bool r, dummy;
		findPathF(path, exts, defDirs, sPath, "", [], r, dummy);
		return r;
	}

	/// 標準のメッセージ送りテキストを返す。
	@property
	const
	string evtChildOK() { return _cEngine.okText is null ? _prop.sys.evtChildOK(legacyName) : _cEngine.okText; }

	/// このスキンでの特徴の一覧を返す。
	@property
	const
	Sex[] allSexes() { mixin(S_TRACE);
		return iota(0, _sexes ? _sexes.length : 2).map!(a => Sex(a))().array();
	}
	/// ditto
	@property
	const
	Period[] allPeriods() { mixin(S_TRACE);
		return iota(0, _periods ? _periods.length : 4).map!(a => Period(a))().array();
	}
	/// ditto
	@property
	const
	Nature[] allNatures() { mixin(S_TRACE);
		return iota(0, _natures ? _natures.length : 12).map!(a => Nature(a))().array();
	}
	/// ditto
	@property
	const
	auto normalNatures() { mixin(S_TRACE);
		if (_natures) { mixin(S_TRACE);
			Nature[] arr;
			foreach (e, f; _natures) { mixin(S_TRACE);
				if (!f.special) { mixin(S_TRACE);
					arr ~= e;
				}
			}
			return arr;
		}
		return iota(0, 6).map!(a => Nature(a))().array();
	}
	/// ditto
	@property
	const
	auto extraNatures() { mixin(S_TRACE);
		if (_natures) { mixin(S_TRACE);
			Nature[] arr;
			foreach (e, f; _natures) { mixin(S_TRACE);
				if (f.special) { mixin(S_TRACE);
					arr ~= e;
				}
			}
			return arr;
		}
		return iota(6, 12).map!(a => Nature(a))().array();
	}
	/// ditto
	@property
	const
	auto allMakings() { mixin(S_TRACE);
		return iota(0, _makings ? _makings.length : 48).map!(a => Makings(a))();
	}
	/// ditto
	@property
	const
	auto leftMakings() { mixin(S_TRACE);
		return iota(0, _makings ? _makings.length : 48, 2).map!(a => Makings(a))();
	}
	/// ditto
	@property
	const
	auto rightMakings() { mixin(S_TRACE);
		return iota(1, _makings ? _makings.length : 48, 2).map!(a => Makings(a))();
	}
	/// ditto
	@property
	const
	Makings reverseMakings(Makings m) { mixin(S_TRACE);
		return Makings((m & 1) ? (m - 1) : (m + 1));
	}

	/// このスキンでの特徴の名前を返す。
	const
	string sexName(Sex e) { mixin(S_TRACE);
		if (auto p = (e in _sexes)) return p.name;
		return _cEngine.sexName.get(_prop.sys.sexName(e, ""), _prop.sys.sexName(e, legacyName));
	}
	/// ditto
	const
	string periodName(Period e) { mixin(S_TRACE);
		if (auto p = (e in _periods)) return p.name;
		return _cEngine.periodName.get(_prop.sys.periodName(e, ""), _prop.sys.periodName(e, legacyName));
	}
	/// ditto
	const
	string natureName(Nature e) { mixin(S_TRACE);
		if (auto p = (e in _natures)) return p.name;
		return _cEngine.natureName.get(_prop.sys.natureName(e, ""), _prop.sys.natureName(e, legacyName));
	}
	/// ditto
	const
	string makingsName(Makings e) { mixin(S_TRACE);
		if (auto p = (e in _makings)) return p.name;
		return _cEngine.makingsName.get(_prop.sys.makingsName(e, ""), _prop.sys.makingsName(e, legacyName));
	}
	/// ditto
	const
	string featureName(E)(E e) { mixin(S_TRACE);
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
	string sexCoupon(Sex e) { mixin(S_TRACE);
		return _prop.sys.convCoupon(sexName(e), CouponType.Hide, false);
	}
	/// ditto
	const
	string periodCoupon(Period e) { mixin(S_TRACE);
		return _prop.sys.convCoupon(periodName(e), CouponType.Hide, false);
	}
	/// ditto
	const
	string natureCoupon(Nature e) { mixin(S_TRACE);
		return _prop.sys.convCoupon(natureName(e), CouponType.Hide, false);
	}
	/// ditto
	const
	string makingsCoupon(Makings e) { mixin(S_TRACE);
		return _prop.sys.convCoupon(makingsName(e), CouponType.Hide, false);
	}

	/// 特徴の能力修正値を返す。
	const
	int physicalMod(E)(E e, Physical phy) { mixin(S_TRACE);
		static if (is(E:Sex)) {
			auto pyArr = _sexes;
			auto arr = _cEngine.physicalModSex;
		} else static if (is(E:Period)) {
			auto pyArr = _periods;
			auto arr = _cEngine.physicalModPeriod;
		} else static if (is(E:Nature)) {
			auto pyArr = _natures;
			auto arr = _cEngine.physicalModNature;
		} else static if (is(E:Makings)) {
			auto pyArr = _makings;
			auto arr = _cEngine.physicalModMakings;
		} else static assert (0);

		if (auto p = (e in pyArr)) { mixin(S_TRACE);
			if (auto p2 = (phy in p.physical)) { mixin(S_TRACE);
				return *p2;
			}
		}
		if (auto p1 = (e in arr)) { mixin(S_TRACE);
			if (auto p2 = (phy in *p1)) { mixin(S_TRACE);
				return *p2;
			}
		}
		const(int[Physical]) init;
		return _prop.sys.physicalMod!E(legacyName).get(e, init).get(phy, 0);
	}
	/// ditto
	const
	real mentalMod(E)(E e, Mental mtl) { mixin(S_TRACE);
		switch (mtl) {
		case Mental.Unaggressive, Mental.Uncheerful, Mental.Unbrave,
				Mental.Uncautious, Mental.Untrickish:
			return mentalMod(e, reverseMental(mtl)) * -1.0;
		default:
		}

		static if (is(E:Sex)) {
			auto pyArr = _sexes;
			auto arr = _cEngine.mentalModSex;
		} else static if (is(E:Period)) {
			auto pyArr = _periods;
			auto arr = _cEngine.mentalModPeriod;
		} else static if (is(E:Nature)) {
			auto pyArr = _natures;
			auto arr = _cEngine.mentalModNature;
		} else static if (is(E:Makings)) {
			auto pyArr = _makings;
			auto arr = _cEngine.mentalModMakings;
		} else static assert (0);

		if (auto p = (e in pyArr)) { mixin(S_TRACE);
			if (auto p2 = (mtl in p.mental)) { mixin(S_TRACE);
				return *p2;
			}
		}
		if (auto p1 = (e in arr)) { mixin(S_TRACE);
			if (auto p2 = (mtl in *p1)) { mixin(S_TRACE);
				return *p2;
			}
		}
		const(real[Mental]) init;
		return _prop.sys.mentalMod!E(legacyName).get(e, init).get(mtl, 0.0);
	}

	/// 年代ごとの初期クーポンを返す。
	@property
	const
	const(Coupon)[] periodInitialCoupons(in System sys, Period p) { mixin(S_TRACE);
		if (!legacy) { mixin(S_TRACE);
			auto pt = _periods.get(p, null);
			return pt ? pt.coupons : [];
		}
		return sys.periodInitialCoupons(p, legacyName);
	}

	/// パーティ先頭のメンバを指すシステムクーポンを返す。
	@property
	const
	string number1Coupon(in System sys) { mixin(S_TRACE);
		if (!legacy && _number1Coupon != "") { mixin(S_TRACE);
			return _number1Coupon;
		}
		return sys.number1Coupon(legacyName);
	}

	/// couponがシステムクーポン名であれば、スキン定義に応じて置換する。
	const
	string replaceSystemCouponName(in System sys, string coupon) { mixin(S_TRACE);
		if (coupon == sys.number1Coupon("")) { mixin(S_TRACE);
			return number1Coupon(sys);
		}
		return coupon;
	}

	/// アクションカードのデータ。
	/// クラシックなシナリオの場合はnullになる。
	const
	const(ActionCard) actionCard(ActionCardType type) { mixin(S_TRACE);
		return _actionCards.get(type, null);
	}
	/// アクションカード名を返す。
	const
	string actionCardName(in System sys, ActionCardType type) { mixin(S_TRACE);
		auto card = actionCard(type);
		if (card) return card.name;
		return _cEngine.actionCardName.get(type, sys.actionCardName(type, legacyName));
	}
	/// アクションカードの適性情報を返す。
	const
	Aptitude actionCardAptitude(in System sys, ActionCardType type) { mixin(S_TRACE);
		auto card = actionCard(type);
		if (card) return Aptitude(card.physical, card.mental);
		return sys.actionCardAptitude(type);
	}
	/// スキンが持つアクションカードの一覧を返す。
	const
	const(ActionCardType)[] actionCardTypes() { mixin(S_TRACE);
		ActionCardType[] r;
		if (legacy || !_actionCards.length) { mixin(S_TRACE);
			foreach (type; EnumMembers!ActionCardType) r ~= type;
		} else { mixin(S_TRACE);
			r = _actionCards.keys();
			.sort(r);
		}
		ActionCardType[] r2;
		foreach (type; r) { mixin(S_TRACE);
			// 一般
			if (type !is ActionCardType.RunAway && 0 <= type) r2 ~= type;
		}
		foreach (type; r) { mixin(S_TRACE);
			// 混乱等
			if (type < 0) r2 ~= type;
		}
		foreach (type; r) { mixin(S_TRACE);
			// 逃走
			if (type is ActionCardType.RunAway) r2 ~= type;
		}
		return r2;
	}

	/// スキンの基本情報以外のデータを読み込む。
	private Rebindable!(const(XMLInfo)) _ver = null;
	void initialize() { mixin(S_TRACE);
		if (_ver is null) return;
		auto fd = std.path.buildPath(resourceDir, "Font");
		foreach (path; clistdir(fd)) { mixin(S_TRACE);
			if (path.noScaledPath != "") continue;
			path = std.path.buildPath(fd, path);
			if (!isDir(path) && .isImageExt(path)) { mixin(S_TRACE);
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
		foreach (file; .dirEntries(_path.buildPath("Resource").buildPath("Xml").buildPath("ActionCard"), SpanMode.shallow)) { mixin(S_TRACE);
			if (!file.isFile) return;
			if (file.extension.toLower() != ".xml") continue;
			try {
				auto node = XNode.parse(std.file.readText(file));
				if (node.name != ActionCard.XML_NAME) return;
				auto card = ActionCard.createFromNode(node, _ver);
				_actionCards[card.actionCardType] = card;
			} catch (Exception e) {
				printStackTrace();
				debugln(file.baseName);
				debugln(e);
			}
		}
		_ver = null;
	}

	/// XMLファイルからスキンデータをロードする。
	void loadFromXML(const(CProps) prop, string fname, in XMLInfo ver) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			_ver = ver;
			_path = dirName(fname);
			_skinFile = fname;
			auto sNode = XNode.parse(std.file.readText(fname));
			_races.length = 0;
			_sexes = null;
			_periods = null;
			_natures = null;
			_makings = null;
			_number1Coupon = "";
			_actionCards = null;
			_spChars = null;
			_sourceOfMaterialsIsClassicEngine = false;
			sNode.onTag["Property"] = (ref XNode pNode) { mixin(S_TRACE);
				pNode.onTag["Name"] = (ref XNode n) { _name = n.value; };
				pNode.onTag["Type"] = (ref XNode n) { _type = n.value; };
				pNode.onTag["Author"] = (ref XNode n) { _author = n.value; };
				pNode.onTag["Description"] = (ref XNode n) { _desc = n.value; };
				pNode.onTag["SourceOfMaterialsIsClassicEngine"] = (ref XNode n) { mixin(S_TRACE);
					_sourceOfMaterialsIsClassicEngine = .parseBool(n.value);
				};
				pNode.parse();
			};
			sNode.onTag["Races"] = (ref XNode node) { mixin(S_TRACE);
				node.onTag["Race"] = (ref XNode node) { mixin(S_TRACE);
					_races ~= Race.fromNode(node, ver);
				};
				node.parse();
			};
			sNode.onTag["Sexes"] = (ref XNode node) { mixin(S_TRACE);
				node.onTag["Sex"] = (ref XNode node) { mixin(S_TRACE);
					_sexes[Sex(_sexes.length)] = ModData.fromNode(node, ver);
				};
				node.parse();
			};
			sNode.onTag["Periods"] = (ref XNode node) { mixin(S_TRACE);
				node.onTag["Period"] = (ref XNode node) { mixin(S_TRACE);
					_periods[Period(_periods.length)] = ModData.fromNode(node, ver);
				};
				node.parse();
			};
			sNode.onTag["Natures"] = (ref XNode node) { mixin(S_TRACE);
				node.onTag["Nature"] = (ref XNode node) { mixin(S_TRACE);
					_natures[Nature(_natures.length)] = ModData.fromNode(node, ver);
				};
				node.parse();
			};
			sNode.onTag["Makings"] = (ref XNode node) { mixin(S_TRACE);
				node.onTag["Making"] = (ref XNode node) { mixin(S_TRACE);
					_makings[Makings(_makings.length)] = ModData.fromNode(node, ver);
				};
				node.parse();
			};
			sNode.onTag["Messages"] = (ref XNode node) { mixin(S_TRACE);
				node.onTag["Message"] = (ref XNode node) { mixin(S_TRACE);
					if (node.attr("key", false, "") == "number_1_coupon") { mixin(S_TRACE);
						_number1Coupon = node.value;
					}
				};
				node.parse();
			};
			sNode.parse();
		} catch (Exception e) {
			printStackTrace();
			debugln(fname);
			debugln(e);
		}
	}
}

/// 特性による能力変動のデータ。
private class ModData {
	private string _name = ""; /// 特性名。
	private bool _special = false; /// 特殊型か。型特性である時のみ有効。
	private int[Physical] _physical; /// 身体能力の変動値。
	private double[Mental] _mental; /// 精神特徴の変動値。
	private Coupon[] _coupons; /// 初期クーポン。

	private this () { }

	/// 特性名。
	@property
	const
	string name() { return _name; }

	/// 特殊型か。型特性である時のみ有効。
	@property
	const
	bool special() { return _special; }

	/// 身体能力の変動値。
	@property
	const
	const(int[Physical]) physical() { return _physical; }

	/// 精神特徴の変動値。
	@property
	const
	const(double[Mental]) mental() { return _mental; }

	/// 初期クーポン
	@property
	const
	const(Coupon)[] coupons() { return _coupons; }

	/// nodeからデータを生成する。
	static ModData fromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		auto mod = new ModData;
		mod._special = node.attr!bool("special", false, false);

		node.onTag["Name"] = (ref XNode node) { mixin(S_TRACE);
			mod._name = node.value;
		};
		node.onTag["Physical"] = (ref XNode node) { mixin(S_TRACE);
			mod._physical[Physical.Agl] = node.attr!int("agl", false, 0);
			mod._physical[Physical.Dex] = node.attr!int("dex", false, 0);
			mod._physical[Physical.Int] = node.attr!int("int", false, 0);
			mod._physical[Physical.Min] = node.attr!int("min", false, 0);
			mod._physical[Physical.Str] = node.attr!int("str", false, 0);
			mod._physical[Physical.Vit] = node.attr!int("vit", false, 0);
		};
		node.onTag["Mental"] = (ref XNode node) { mixin(S_TRACE);
			mod._mental[Mental.Aggressive] = node.attr!double("aggressive", false, 0);
			mod._mental[Mental.Brave] = node.attr!double("brave", false, 0);
			mod._mental[Mental.Cautious] = node.attr!double("cautious", false, 0);
			mod._mental[Mental.Cheerful] = node.attr!double("cheerful", false, 0);
			mod._mental[Mental.Trickish] = node.attr!double("trickish", false, 0);
		};
		node.onTag[Coupon.XML_NAME_M] = (ref XNode node) { mixin(S_TRACE);
			node.onTag[Coupon.XML_NAME] = (ref XNode node) { mixin(S_TRACE);
				mod._coupons ~= Coupon.fromNode(node, ver);
			};
			node.parse();
		};
		node.parse();

		return mod;
	}
}
