
module cwx.skin;

import cwx.cwl;
import cwx.race;
import cwx.utils;
import cwx.props;
import cwx.imagesize;
import cwx.xml;
import cwx.types;

import std.ctype;
import std.file;
import std.path;
import std.utf;
import std.uni;

public:

class Skin {
	static Skin find(Summary)(CProps prop, string enginePath, Summary summ)
	out (skin) {
		assert (summ.legacy == skin.legacy);
	} body {
		if (summ.legacy) {
			return legacySkin(prop, enginePath, summ.scenarioPath);
		}
		return table(prop, enginePath)[summ.type];
	}

	private static Skin[string][string] skinTable;
	static Skin[string] table(CProps prop, string enginePath) {
		enginePath = nabs(enginePath);
		auto p = enginePath in skinTable;
		if (p) {
			return *p;
		} else {
			auto skinsDir = std.path.join(getDirName(enginePath), "Data" ~ sep ~ "Skin" ~ sep);
			Skin[string] r;
			foreach (skinDir; clistdir(skinsDir)) {
				skinDir = std.path.join(skinsDir, skinDir);
				if (!isdir(skinDir)) continue;
				auto file = std.path.join(skinDir, "Skin.xml");
				if (!exists(file)) continue;
				try {
					auto skin = new Skin(prop, file, enginePath);
					r[skin.type] = skin;
				} catch (Exception e) {
					debugln(e);
				}
			}
			skinTable[enginePath] = r;
			return r;
		}
	}
	private static Skin[string] lSkins;
	static Skin legacySkin(CProps prop, string enginePath, string sPath) {
		string resDir, lEnginePath;
		findLegacy(sPath, resDir, lEnginePath);
		resDir = resDir.length ? nabs(resDir) : "";
		lEnginePath = nabs(lEnginePath);
		auto p = resDir in lSkins;
		if (p) {
			return *p;
		} else {
			auto skin = new Skin(prop, table(prop, enginePath)["MedievalFantasy"].skinFile, enginePath);
			skin._extImg = "bmp";
			skin._extBgm = "mid";
			skin._extSound = "wav";
			skin._legacy = true;
			skin._legacyPath = resDir;
			skin._legacyEngine = lEnginePath;
			lSkins[resDir] = skin;
			return skin;
		}
	}
	/// 指定されたシナリオが属すCardWirthを検索し、
	/// そのリソースディレクトリとエンジンのパスを返す。
	private static void findLegacy(string scPath, out string resDir, out string enginePath) {
		auto path = getDirName(scPath);
		bool chk() {
			auto p = path;
			if (std.file.exists(join(p, "Data" ~ sep ~ "Table" ~ sep ~ "MapOfWirth.BMP"))) {
				resDir = join(p, "Data");
				return true;
			}
			for (char c = 'A'; c < 'Z'; c++) {
				if (std.file.exists(join(p, "D_" ~ c ~ "1" ~ sep ~ "Table" ~ sep ~ "MapOfWirth.BMP"))) {
					resDir = join(p, "D_" ~ c ~ "1");
					return true;
				}
				if (std.file.exists(join(p, [c] ~ "_dt" ~ sep ~ "Table" ~ sep ~ "MapOfWirth.BMP"))) {
					resDir = join(p, [c] ~ "_dt");
					return true;
				}
			}
			return false;
		}
		while (!chk) {
			auto old = path;
			path = getDirName(path);
			if (old == path) {
				resDir ="";
				enginePath = "";
				return;
			}
		}
		auto cw = join(path, "CardWirth.exe");
		if (std.file.exists(cw)) {
			enginePath = cw;
		} else {
			foreach (file; clistdir(path)) {
				if ((file.length > "Wirth.exe".length
						&& fnmatch(file[$ - "Wirth.exe".length .. $], "Wirth.exe"))
						|| (fnmatch(getExt(file), "exe")
						&& file.length > "CardWirth_".length
						&& fnmatch(file[$ - "CardWirth_".length .. $], "CardWirth_"))) {
					enginePath = join(path, file);
					return;
				}
			}
			enginePath = "";
		}
	}
	private bool _legacy = false;
	private string _legacyPath = "";
	private string _legacyEngine = "";

	private CProps _prop;
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

	private this(CProps prop, string skinFile, string enginePath) {
		_prop = prop;
		_enginePath = enginePath;
		loadFromXML(skinFile);
	}
	string name() {return _name;}
	string type() {return _type;}
	string skinFile() {return _skinFile;}

	/// リソース画像のパス。
	string resSummary(out bool mask, out bool rMask) {
		return join(tableDir, addExt("Bill", _legacyPath.length ? extImage : resExtImage));
	}
	/// ditto
	string resMenuCard(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "NORMAL", resExtImage));}

	/// ditto
	string resCastCard(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "LARGE", resExtImage));}
	/// ditto
	string resCastCardInjury(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "INJURY", resExtImage));}
	/// ditto
	string resCastCardDanger(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "DANGER", resExtImage));}
	/// ditto
	string resCastCardFaint(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "FAINT", resExtImage));}
	/// ditto
	string resCastCardBind(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "BIND", resExtImage));}
	/// ditto
	string resCastCardParaly(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "PARALY", resExtImage));}
	/// ditto
	string resCastCardPetrif(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "PETRIF", resExtImage));}
	/// ditto
	string resCastCardSleep(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "SLEEP", resExtImage));}
	/// ditto
	string resLifeBar(out bool mask, out bool rMask) {return join(resourceDir, addExt("Status" ~ sep ~ "LIFEBAR", resExtImage));}
	/// ditto
	string resLifeGuage(out bool mask, out bool rMask) {return join(resourceDir, addExt("Status" ~ sep ~ "LIFEGUAGE", resExtImage));}
	/// ditto
	string resEnhanceUp(out bool mask, out bool rMask, Enhance enh) {
		switch (enh) {
		case Enhance.ACTION: return join(resourceDir, addExt("Status" ~ sep ~ "UP0", resExtImage));
		case Enhance.AVOID: return join(resourceDir, addExt("Status" ~ sep ~ "UP1", resExtImage));
		case Enhance.RESIST: return join(resourceDir, addExt("Status" ~ sep ~ "UP2", resExtImage));
		case Enhance.DEFENSE: return join(resourceDir, addExt("Status" ~ sep ~ "UP3", resExtImage));
		default: assert (0);
		}
	}
	/// ditto
	string resEnhanceDown(out bool mask, out bool rMask, Enhance enh) {
		switch (enh) {
		case Enhance.ACTION: return join(resourceDir, addExt("Status" ~ sep ~ "DOWN0", resExtImage));
		case Enhance.AVOID: return join(resourceDir, addExt("Status" ~ sep ~ "DOWN1", resExtImage));
		case Enhance.RESIST: return join(resourceDir, addExt("Status" ~ sep ~ "DOWN2", resExtImage));
		case Enhance.DEFENSE: return join(resourceDir, addExt("Status" ~ sep ~ "DOWN3", resExtImage));
		default: assert (0);
		}
	}
	/// ditto
	string resMentality(out bool mask, out bool rMask, Mentality mtly) {
		switch (mtly) {
		case Mentality.NORMAL: return join(resourceDir, addExt("Status" ~ sep ~ "MIND0", resExtImage));
		case Mentality.SLEEP: return join(resourceDir, addExt("Status" ~ sep ~ "MIND1", resExtImage));
		case Mentality.CONFUSE: return join(resourceDir, addExt("Status" ~ sep ~ "MIND2", resExtImage));
		case Mentality.OVERHEAT: return join(resourceDir, addExt("Status" ~ sep ~ "MIND3", resExtImage));
		case Mentality.BRAVE: return join(resourceDir, addExt("Status" ~ sep ~ "MIND4", resExtImage));
		case Mentality.PANIC: return join(resourceDir, addExt("Status" ~ sep ~ "MIND5", resExtImage));
		default: assert (0);
		}
	}
	/// ditto
	string resBind(out bool mask, out bool rMask) {return join(resourceDir, addExt("Status" ~ sep ~ "MAGIC0", resExtImage));}
	/// ditto
	string resSilence(out bool mask, out bool rMask) {return join(resourceDir, addExt("Status" ~ sep ~ "MAGIC1", resExtImage));}
	/// ditto
	string resFaceUp(out bool mask, out bool rMask) {return join(resourceDir, addExt("Status" ~ sep ~ "MAGIC2", resExtImage));}
	/// ditto
	string resAntiMagic(out bool mask, out bool rMask) {return join(resourceDir, addExt("Status" ~ sep ~ "MAGIC3", resExtImage));}
	/// ditto
	string resParalyze(out bool mask, out bool rMask) {return join(resourceDir, addExt("Status" ~ sep ~ "BODY1", resExtImage));}
	/// ditto
	string resPoison(out bool mask, out bool rMask) {return join(resourceDir, addExt("Status" ~ sep ~ "BODY0", resExtImage));}
	/// ditto
	string resSummon(out bool mask, out bool rMask) {return join(resourceDir, addExt("Status" ~ sep ~ "SUMMON", resExtImage));}

	/// ditto
	string resItemCard(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "ITEM", resExtImage));}
	/// ditto
	string resSkillCard(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "SKILL", resExtImage));}
	/// ditto
	string resBeastCard(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "BEAST", resExtImage));}
	/// ditto
	string resInfoCard(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "INFO", resExtImage));}
	/// ditto
	string resCardHold(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "HOLD", resExtImage));}
	/// ditto
	string resCardPenalty(out bool mask, out bool rMask) {return join(resourceDir, addExt("CardBg" ~ sep ~ "PENALTY", resExtImage));}
	/// ditto
	string resRare(out bool mask, out bool rMask) {
		mask = true;
		rMask = true;
		return join(resourceDir, addExt("CardBg" ~ sep ~ "RARE", resExtImage));
	}
	/// ditto
	string resPremier(out bool mask, out bool rMask) {
		mask = true;
		rMask = true;
		return join(resourceDir, addExt("CardBg" ~ sep ~ "PREMIER", resExtImage));
	}
	/// ditto
	string resAptVeryHigh(out bool mask, out bool rMask) {
		mask = true;
		return join(resourceDir, addExt("Stone" ~ sep ~ "HAND3", resExtImage));
	}
	/// ditto
	string resAptHigh(out bool mask, out bool rMask) {
		mask = true;
		return join(resourceDir, addExt("Stone" ~ sep ~ "HAND2", resExtImage));
	}
	/// ditto
	string resAptNormal(out bool mask, out bool rMask) {
		mask = true;
		return join(resourceDir, addExt("Stone" ~ sep ~ "HAND1", resExtImage));
	}
	/// ditto
	string resAptLow(out bool mask, out bool rMask) {
		mask = true;
		return join(resourceDir, addExt("Stone" ~ sep ~ "HAND0", resExtImage));
	}
	/// ditto
	string resUse0(out bool mask, out bool rMask) {
		mask = true;
		return join(resourceDir, addExt("Stone" ~ sep ~ "HAND5", resExtImage));
	}
	/// ditto
	string resUse1(out bool mask, out bool rMask) {
		mask = true;
		return join(resourceDir, addExt("Stone" ~ sep ~ "HAND6", resExtImage));
	}
	/// ditto
	string resUse2(out bool mask, out bool rMask) {
		mask = true;
		return join(resourceDir, addExt("Stone" ~ sep ~ "HAND7", resExtImage));
	}
	/// ditto
	string resUse3(out bool mask, out bool rMask) {
		mask = true;
		return join(resourceDir, addExt("Stone" ~ sep ~ "HAND8", resExtImage));
	}
	/// ditto
	string resUse4(out bool mask, out bool rMask) {
		mask = true;
		return join(resourceDir, addExt("Stone" ~ sep ~ "HAND9", resExtImage));
	}

	/// CardWirth本体のパス。
	/// クラシックなシナリオの編集中は、そのシナリオが
	/// 属すと思われるパスを返す。
	string engine() {return _legacyEngine.length ? _legacyEngine : _enginePath;}

	/// クラシックなシナリオの編集中は、拡張子を除く所属エンジンのパスを返す。
	/// 所属エンジンが無いか、クラシックでないシナリオの編集中であれば""を返す。
	string legacyName() {return _legacyEngine.length ? getName(getBaseName(_legacyEngine)) : "";}

	/// クラシックなCardWirthEditorで作成されたシナリオのスキンならtrue。
	bool legacy() {return _legacy;}

	/// シナリオの素材を置くディレクトリの標準。シナリオのルートからの相対パス。
	string materialPath() {
		return legacy ? "" : "Material";
	}

	/// pathが効果音として使用可能か。
	bool isSE(string path) {
		auto ext = getExt(path);
		if (legacy && !fnmatch(ext, "wav")) return false;
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
	bool isBGM(string path) {
		auto ext = getExt(path);
		if (legacy && !fnmatch(ext, "mid")
				&& !fnmatch(ext, "midi")) {
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
			return true;
		default:
			return false;
		}
	}
	/// pathがカード画像として使用可能か。
	bool isCardImage(string path) {
		if (isBinImg(path)) return true;
		if (legacy && !fnmatch(getExt(path), "bmp")) return false;
		try {
			uint x, y;
			return imageSize(path, x, y)
				&& x == _prop.looks.cardSize.width && y == _prop.looks.cardSize.height;
		} catch (Exception e) {
		}
		return false;
	}

	/// pathが背景画像として使用可能か。
	bool isBgImage(string path) {
		auto ext = getExt(path);
		if (fnmatch(ext, "jpy1")
				|| fnmatch(ext, "jptx")
				|| fnmatch(ext, "jpdc")) {
			return true;
		}
		if (legacy && !fnmatch(ext, "bmp")
				&& !fnmatch(ext, "jpg")
				&& !fnmatch(ext, "jpeg")) {
			return false;
		}
		try {
			uint x, y;
			return imageSize(path, x, y);
		} catch (Exception e) {
		}
		return false;
	}

	/// 特殊文字の情報。
	string[dchar] spChars() {return _spChars;}

	private bool has(alias isT)(string dir, bool forceRefresh) {
		return list!(isT)(dir, forceRefresh).length > 0;
	}

	/// 各種の素材がdirに含まれていればtrueを返す。
	bool hasCardImage(string dir, bool forceRefresh) {return has!(isCardImage)(dir, forceRefresh);}
	/// ditto
	bool hasBgImage(string dir, bool forceRefresh) {return has!(isBgImage)(dir, forceRefresh);}
	/// ditto
	bool hasBGM(string dir, bool forceRefresh) {return has!(isBGM)(dir, forceRefresh);}
	/// ditto
	bool hasSE(string dir, bool forceRefresh) {return has!(isSE)(dir, forceRefresh);}

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
			fp = std.path.join(dir, fp);
			if (isT(fp)) {
				r ~= getBaseName(fp);
			}
		}
		r = r.sort;
		putCache(dir, r);
		return r;
	}

	/// dirに含まれるカード画像の一覧。
	string[] cards(string dir, bool forceRefresh) {return list!(isCardImage)(dir, forceRefresh);}

	/// 標準の背景画像。
	string[] tables(bool forceRefresh = false) {return list!(isBgImage)(tableDir, forceRefresh);}

	/// dirに含まれる背景画像の一覧。
	string[] tables(string dir, bool forceRefresh) {return list!(isBgImage)(dir, forceRefresh);}

	/// 標準のBGM。
	string[] musics(bool forceRefresh = false) {return list!(isBGM)(bgmDir, forceRefresh);}

	/// dirに含まれるBGMの一覧。
	string[] musics(string dir, bool forceRefresh) {return list!(isBGM)(dir, forceRefresh);}

	/// 標準のSE。
	string[] sounds(bool forceRefresh = false) {return list!(isSE)(seDir, forceRefresh);}

	/// dirに含まれるSEの一覧。
	string[] sounds(string dir, bool forceRefresh) {return list!(isSE)(dir, forceRefresh);}

	/// 標準の背景画像のディレクトリ。
	string tableDir() {
		if (_legacyPath.length) {
			return std.path.join(_legacyPath, "Table");
		}
		return std.path.join(_path, "Table");
	}
	/// 標準のBGMのディレクトリ。
	string bgmDir() {
		if (_legacyPath.length) {
			return std.path.join(_legacyPath, "Midi");
		}
		return std.path.join(_path, "Bgm");
	}
	/// 標準のSEのディレクトリ。
	string seDir() {
		if (_legacyPath.length) {
			return std.path.join(_legacyPath, "Wave");
		}
		return std.path.join(_path, "Sound");
	}
	/// その他リソースのディレクトリ。
	string resourceDir() {
		return std.path.join(_path, "Resource" ~ sep ~ "Image");
	}

	/// 標準画像の拡張子。
	string extImage() {return _extImg;}
	/// 標準BGMの拡張子。
	string extBgm() {return _extBgm;}
	/// 標準SEの拡張子。
	string extSound() {return _extSound;}
	/// 標準リソース画像の拡張子。
	string resExtImage() {return _resExtImg;}

	/// 種族。
	Race[] races() {
		return _races;
	}

	/// エリア等を作成した際、最初に配置されている背景画像の名前。
	string firstBgImage() {return addExt("MapOfWirth", extImage);}

	/// バトルを作成した際、最初に設定されているBGMの名前。
	string defBattle() {return addExt("DefBattle", extBgm);}

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
	string findImagePathF(string path, string sPath, out bool def = false) {
		return findPathF(path, extImage, tableDir, sPath, def);
	}
	/// ditto
	string findImagePath(string path, string sPath) {
		bool dummy;
		return findImagePathF(path, sPath, dummy);
	}
	/// ditto
	string findPathF(string path, string ext, string defDir, string sPath, out bool def = false) {
		if (path.length == 0) return "";
		if (isBinImg(path)) return path;
		string p;
		if (sPath && sPath.length) {
			p = std.path.join(sPath, path);
			if (exists(p)) {
				return p;
			}
		}
		def = true;
		p = std.path.join(defDir, getBaseName(path));
		if (exists(p)) {
			return p;
		}
		string f(string ext) {
			p = addExt(p, ext);
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
		return "";
	}
	/// ditto
	string findPath(string path, string ext, string defDir, string sPath) {
		bool dummy;
		return findPathF(path, ext, defDir, sPath, dummy);
	}

	/// XMLファイルからスキンデータをロードする。
	void loadFromXML(string fname) {
		try {
			_path = getDirName(fname);
			_skinFile = fname;
			scope sNode = XNode.parse(cast(string) std.file.read(fname));
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
			_spChars = typeof(_spChars).init;
			auto fd = std.path.join(resourceDir, "Font");
			foreach (path; clistdir(fd)) {
				path = std.path.join(fd, path);
				if (!isdir(path) && fnmatch(getExt(path), _resExtImg)) {
					_spChars[toUniUpper(toUTF32(getBaseName(path))[0])] = path;
				}
			}
		} catch (Exception e) {
			debugln(e);
		}
	}
}
