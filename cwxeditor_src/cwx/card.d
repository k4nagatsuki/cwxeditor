
module cwx.card;

import cwx.coupon;
import cwx.event;
import cwx.motion;
import cwx.utils;
import cwx.usecounter;
import cwx.types;
import cwx.race;
import cwx.xml;
import cwx.utils;
import cwx.path;
import cwx.structs;
import cwx.system;

import std.algorithm;
import std.array;
import std.exception;
import std.typecons;
import std.conv;

/// データをXML化する時のオプション。
class XMLOption {
	const System sys; /// 対象システム情報。
	string dataVersion = LATEST_VERSION; /// WSNバージョン。
	bool includeCard = false; /// リンク先のカードの実体を格納する。
	bool noLinkId = false; /// 実体を格納した時、参照IDを削除する。
	const(SkillCard) delegate(ulong) skill = null; /// IDからスキルカードを取得。
	const(ItemCard) delegate(ulong) item = null; /// IDからアイテムカードを取得。
	const(BeastCard) delegate(ulong) beast = null; /// IDから召喚獣カードを取得。
	uint[ulong] nestCount; /// 召喚獣カードのCWXパスとネストされた回数。
	bool shallow = false; /// イベントコンテントのコピーの際、子コンテントを無視する。

	/// インスタンスを生成する。
	this (const System sys, string dataVersion) { mixin(S_TRACE);
		this.sys = sys;
		this.dataVersion = dataVersion;
	}

	/// 指定されたデータバージョンがシナリオのデータバージョン以下か。
	const
	bool isTargetVersion(string ver) { mixin(S_TRACE);
		return .isTargetVersion(dataVersion, ver);
	}
}

/// XML化時に上書きするデータ。
class OverData {
	ulong id = 0UL; /// ID。0の場合は上書きしない。
	ulong linkId = 0UL; /// 参照ID。0の場合は上書きしない。
	bool overHold = false; /// ホールド状態を上書きするか。
	bool hold = false; /// ホールド状態。
}

public:

/// カード画像のデータ。
class CardImage : IPathUser {
	CardImageType type = CardImageType.File;
	private uint _pcNumber = 0;
	private Talker _talker = Talker.SELECTED;
	private PathUser _path = null;
	private CardImagePosition _positionType = CardImagePosition.Default;

	/// パスを示すオブジェクトを指定してインスタンスを生成。
	private this (IPathUser cwxPath) { mixin(S_TRACE);
		_path = new PathUser(cwxPath);
	}
	/// コピーコンストラクタ。ownerなど一部データはコピーされない。
	this (IPathUser cwxPath, in CardImage base) { mixin(S_TRACE);
		this (cwxPath);
		type = base.type;
		final switch (base.type) {
		case CardImageType.File:
			_path.path = base.path;
			_positionType = base.positionType;
			break;
		case CardImageType.PCNumber:
			_pcNumber = base.pcNumber;
			break;
		case CardImageType.Talker:
			_talker = base.talker;
			break;
		}
	}
	/// パスを指定してインスタンスを生成。
	this (string path, CardImagePosition positionType) { mixin(S_TRACE);
		this (cast(IPathUser)null);
		type = CardImageType.File;
		_path.path = path;
		_positionType = positionType;
	}
	/// PC番号を指定してインスタンスを生成。
	this (uint pcNumber) { mixin(S_TRACE);
		this (cast(IPathUser)null);
		type = CardImageType.PCNumber;
		_pcNumber = pcNumber;
	}
	/// 話者を指定してインスタンスを生成。
	this (Talker talker) { mixin(S_TRACE);
		this (cast(IPathUser)null);
		type = CardImageType.Talker;
		_talker = talker;
	}

	/// 使用回数カウンタ。
	@property
	UseCounter useCounter() { return _path.useCounter; }
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { _path.setUseCounter(uc); }
	/// ditto
	void removeUseCounter() { _path.removeUseCounter(); }

	override bool change(PathId newVal) { return _path.change(newVal); }

	/// ファイルパス。
	@property
	const
	string path() { return _path.path; }

	/// 配置形式。
	@property
	const
	CardImagePosition positionType() { return _positionType; }

	/// PC画像を表示する場合はその位置(1～6)。
	/// 0の場合はPC画像を使用しない。
	@property
	const
	uint pcNumber() { mixin(S_TRACE);
		return _pcNumber;
	}

	/// 話者。
	@property
	const
	Talker talker() { mixin(S_TRACE);
		return _talker;
	}

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto c = cast(const CardImage)o;
		return c
			&& c.type == type
			&& c.pcNumber == pcNumber
			&& c.path == path
			&& c.talker == talker
			&& c.positionType == positionType;
	}
	override
	const
	@safe
	hash_t toHash() {
		hash_t hash = toPathId(_path.path).toHash();
		hash = (hash * 9) + type;
		hash = (hash * 9) + _pcNumber;
		hash = (hash * 9) + _talker;
		hash = (hash * 9) + _positionType;
		return hash;
	}

	@property
	override
	string cwxPath(bool id) { return _path.cwxPath(id); }
	override
	CWXPath findCWXPath(string path) { return _path.findCWXPath(path); }
	@property
	override
	inout
	inout(CWXPath)[] cwxChilds() { return _path.cwxChilds; }
	@property
	override
	CWXPath cwxParent() { return _path.cwxParent; }
	override
	void changed() { _path.changed(); }

	/// pNodeにImagePath要素またはImagePaths要素から
	/// インスタンス群を生成してpathsに追加するハンドラを登録する。
	/// attrをtrueにした場合、ImagePath要素ではなくpath属性を使用する。
	static void setOnTag(ref XNode pNode, ref CardImage[] paths, bool attr = false) { mixin(S_TRACE);
		void convPath(string pathTemp, string posTypeTemp) { mixin(S_TRACE);
			CardImage path = null;
			if (pathTemp && endsWith(pathTemp, "??" ~ fromTalker(Talker.SELECTED))) { mixin(S_TRACE);
				path = new CardImage(Talker.SELECTED);
			} else if (pathTemp && endsWith(pathTemp, "??" ~ fromTalker(Talker.UNSELECTED))) { mixin(S_TRACE);
				path = new CardImage(Talker.UNSELECTED);
			} else if (pathTemp && endsWith(pathTemp, "??" ~ fromTalker(Talker.RANDOM))) { mixin(S_TRACE);
				path = new CardImage(Talker.RANDOM);
			} else if (pathTemp && endsWith(pathTemp, "??" ~ fromTalker(Talker.CARD))) { mixin(S_TRACE);
				path = new CardImage(Talker.CARD);
			} else if (pathTemp && endsWith(pathTemp, "??" ~ fromTalker(Talker.VALUED))) { mixin(S_TRACE);
				path = new CardImage(Talker.VALUED);
			} else if (pathTemp && pathTemp != "") { mixin(S_TRACE);
				switch (posTypeTemp) {
				case "Center":
					path = new CardImage(decodePath(pathTemp), CardImagePosition.Center);
					break;
				case "TopLeft":
					path = new CardImage(decodePath(pathTemp), CardImagePosition.TopLeft);
					break;
				default:
					path = new CardImage(decodePath(pathTemp), CardImagePosition.Default);
					break;
				}
			}
			if (path) { mixin(S_TRACE);
				paths ~= path;
			}
		}
		auto imgPath = (ref XNode n) { mixin(S_TRACE);
			convPath(n.value, n.attr("positiontype", false, "Default"));
		};
		auto pcNum = (ref XNode node) { mixin(S_TRACE);
			paths ~= new CardImage(.to!uint(node.value));
		};
		if (attr) { mixin(S_TRACE);
			auto path = pNode.attr("path", false, "");
			convPath(path, pNode.attr("positiontype", false, "Default"));
			auto pcNumber = pNode.attr!uint("pcNumber", false, 0);
			if (pcNumber != 0) { mixin(S_TRACE);
				paths ~= new CardImage(pcNumber);
			}
		} else { mixin(S_TRACE);
			pNode.onTag["ImagePath"] = imgPath;
			pNode.onTag["PCNumber"] = pcNum;
		}
		if (pNode.name != "ImagePaths") { mixin(S_TRACE);
			pNode.onTag["ImagePaths"] = (ref XNode n) { mixin(S_TRACE);
				n.onTag["ImagePath"] = imgPath;
				n.onTag["PCNumber"] = pcNum;
				n.parse();
			};
		}
	}

	/// ImagePaths要素からCardImageの配列を作成する。
	static CardImage[] createFromNode(ref XNode node) { mixin(S_TRACE);
		CardImage[] paths;
		setOnTag(node, paths, false);
		node.parse();
		return paths;
	}

	/// pNodeにpathsのデータを追加する。
	/// attrをtrueにした場合、ImagePath要素ではなくpath属性を使用する。
	static void toNode(ref XNode pNode, in CardImage[] paths, bool attr = false) { mixin(S_TRACE);
		if (paths.length == 0) { mixin(S_TRACE);
			if (attr) { mixin(S_TRACE);
				pNode.newAttr("path", "");
			} else { mixin(S_TRACE);
				pNode.newElement("ImagePath", "");
			}
		} else if (paths.length <= 1) { mixin(S_TRACE);
			putToNode(pNode, paths[0], attr);
		} else { mixin(S_TRACE);
			auto imp = pNode.newElement("ImagePaths", "");
			foreach (path; paths) { mixin(S_TRACE);
				putToNode(imp, path, false);
			}
		}
	}
	/// pathsからImagePaths要素を作成する。
	static XNode toNode(in CardImage[] paths) { mixin(S_TRACE);
		auto imp = XNode.create("ImagePaths");
		foreach (path; paths) { mixin(S_TRACE);
			putToNode(imp, path, false);
		}
		return imp;
	}
	private static void putToNode(ref XNode pNode, in CardImage path, bool attr) { mixin(S_TRACE);
		final switch (path.type) {
		case CardImageType.File:
			void putPosType(ref XNode n) { mixin(S_TRACE);
				final switch (path.positionType) {
				case CardImagePosition.Center:
					n.newAttr("positiontype", "Center");
					break;
				case CardImagePosition.TopLeft:
					n.newAttr("positiontype", "TopLeft");
					break;
				case CardImagePosition.Default:
					break;
				}
			}
			if (attr) { mixin(S_TRACE);
				pNode.newAttr("path", encodePath(path.path));
				putPosType(pNode);
			} else { mixin(S_TRACE);
				auto n = pNode.newElement("ImagePath", encodePath(path.path));
				putPosType(n);
			}
			break;
		case CardImageType.PCNumber:
			if (attr) { mixin(S_TRACE);
				pNode.newAttr("path", "");
				pNode.newAttr("pcNumber", path.pcNumber);
			} else { mixin(S_TRACE);
				if (pNode.name != "ImagePaths") pNode.newElement("ImagePath", "");
				pNode.newElement("PCNumber", .text(path.pcNumber));
			}
			break;
		case CardImageType.Talker:
			if (attr) { mixin(S_TRACE);
				pNode.newAttr("path", "Material/??" ~ fromTalker(path.talker));
			} else { mixin(S_TRACE);
				pNode.newElement("ImagePath", "Material/??" ~ fromTalker(path.talker));
			}
			break;
		}
	}
}

/// カードの所持者である事を示すインタフェース。
interface CastOwner : CWXPath {
	@property
	inout
	inout(CastCard)[] casts();
	inout
	inout(CastCard) cwCast(ulong id);
}
interface SkillOwner : CWXPath {
	@property
	inout
	inout(SkillCard)[] skills();
	inout
	inout(SkillCard) skill(ulong id);
}
interface ItemOwner : CWXPath {
	@property
	inout
	inout(ItemCard)[] items();
	inout
	inout(ItemCard) item(ulong id);
}
interface BeastOwner : CWXPath {
	@property
	inout
	inout(BeastCard)[] beasts();
	inout
	inout(BeastCard) beast(ulong id);
}
interface InfoOwner : CWXPath {
	@property
	inout
	inout(InfoCard)[] infos();
	inout
	inout(InfoCard) info(ulong id);
}

/// カード絡みの例外。
class CardException : Exception {
public:
	this (string msg) { mixin(S_TRACE);
		super(msg);
	}
}

/// エリア等に属さない独立したカードの親クラス。
abstract class Card : CWXPath, IPathUser {
private:
	ulong _id;
	string _name;
	string _desc;
	void delegate() _change = null;
	bool _changed = false;
	CardImage[] _paths;
	UseCounter _useCounter = null;
public:
	/// 唯一のコンストラクタ。
	/// Params:
	/// id = カードID。
	/// name = 名前。
	/// imagePaths = カード画像。
	/// desc = 解説。
	this (ulong id, string name, in CardImage[] paths, string desc) { mixin(S_TRACE);
		_id = id;
		_name = name;
		_desc = desc;
		this.paths = paths;
	}
	/// cからパラメータをコピーする。
	protected void shallowCopyCard(in Card c) { mixin(S_TRACE);
		id = c.id;
		name = c.name;
		desc = c.desc;
		paths = c.paths;
	}

	/// ディープコピーを作成する。
	@property
	const
	abstract
	Card dup();

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto c = cast(const Card) o;
		if (!c) return false;
		return id == c.id
			&& equalsExcludeIdCard(c);
	}
	/// ID以外を比較する。
	const
	protected bool equalsExcludeIdCard(const(Card) c) { mixin(S_TRACE);
		if (!c) return false;
		return name == c.name
			&& desc == c.desc
			&& paths == c.paths;
	}

	/// IDを除く内部データをクリアする。
	protected void clearData() { mixin(S_TRACE);
		name = "";
		desc = "";
		paths = [];
	}

	/// 変更ハンドラを登録する。
	@property
	void changeHandler(void delegate() change) { mixin(S_TRACE);
		_change = change;
	}
	/// 変更ハンドラを返す。
	@property
	protected void delegate() changeHandler() { mixin(S_TRACE);
		return &changed;
	}
	/// 変更を通知する。
	void changed() { mixin(S_TRACE);
		if (_change) { mixin(S_TRACE);
			_change();
			_changed = true;
		}
	}
	/// 変更されているか。
	@property
	const
	bool isChanged() { return _changed; }
	/// 変更状態をリセットする。
	void resetChanged() { mixin(S_TRACE);
		_changed = false;
	}

	/// 使用回数カウンタ。
	@property
	UseCounter useCounter() { mixin(S_TRACE);
		return _useCounter;
	}
	/// 使用回数カウンタを登録する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		_useCounter = uc;
		foreach (path; _paths) { mixin(S_TRACE);
			path.setUseCounter(uc);
		}
	}
	/// 使用回数カウンタを取り除く。
	void removeUseCounter() { mixin(S_TRACE);
		_useCounter = null;
		foreach (path; _paths) { mixin(S_TRACE);
			path.removeUseCounter();
		}
	}
	/// 画像パスの変更を通知する。
	bool change(PathId id) { mixin(S_TRACE);
		foreach (path; _paths) { mixin(S_TRACE);
			path.change(id);
		}
		return true;
	}

	/// カードID。
	@property
	void id(ulong id) { mixin(S_TRACE);
		if (_id != id) { mixin(S_TRACE);
			changed();
		}
		_id = id;
	}
	/// ditto
	@property
	const
	ulong id() { mixin(S_TRACE);
		return _id;
	}

	/// カード名。
	@property
	const
	string name() { mixin(S_TRACE);
		return _name;
	}
	/// ditto
	@property
	void name(string name) { mixin(S_TRACE);
		if (_name != name) changed();
		_name = name;
	}

	/// カード画像。
	@property
	const
	CardImage[] paths() { mixin(S_TRACE);
		return .map!(a => new CardImage(null, a))(_paths).array();
	}
	/// ditto
	@property
	void paths(in CardImage[] paths) { mixin(S_TRACE);
		if (_paths == paths) return;
		changed();
		foreach (u; _paths) { mixin(S_TRACE);
			u.removeUseCounter();
		}
		_paths = [];
		foreach (path; paths) { mixin(S_TRACE);
			auto u = new CardImage(this, path);
			if (useCounter) u.setUseCounter(useCounter);
			_paths ~= u;
		}
	}

	/// このカードと強く関係するファイルパスを返す。
	/// そのようなファイルが無い場合は""を返す。
	@property
	const
	string connectedFile() { mixin(S_TRACE);
		foreach (path; _paths) { mixin(S_TRACE);
			if (path.path != "" && !path.path.isBinImg) return path.path;
		}
		return "";
	}

	/// 解説。
	@property
	const
	string desc() { mixin(S_TRACE);
		return _desc;
	}
	/// ditto
	@property
	void desc(string desc) { mixin(S_TRACE);
		if (_desc != desc) changed();
		_desc = desc;
	}

	/// nodeからID情報を抽出する。存在しない場合は0。
	static ulong readId(ref XNode node) { mixin(S_TRACE);
		auto pNode = node.child("Property", false);
		if (!pNode.valid) return 0UL;
		string idStr = pNode.childText("Id", false);
		if (!idStr) return 0UL;
		return to!(ulong)(idStr);
	}
	/// nodeからID、参照先ID、ホールド情報を抽出する。存在しない場合は0。
	private static ulong readLinkInfo(ref XNode node, out ulong linkId, out bool hold) { mixin(S_TRACE);
		auto pNode = node.child("Property", false);
		if (!pNode.valid) return 0UL;
		ulong id = 0UL;
		linkId = 0UL;
		hold = false;
		pNode.onTag["Id"] = (ref XNode e) { mixin(S_TRACE);
			id = to!ulong(e.value);
		};
		pNode.onTag["LinkId"] = (ref XNode e) { mixin(S_TRACE);
			linkId = to!ulong(e.value);
		};
		pNode.onTag["Hold"] = (ref XNode e) { mixin(S_TRACE);
			hold = parseBool(e.value);
		};
		pNode.parse();
		return id;
	}

	/// 自身をXMLノードにして指定されたノードに追加する。
	const
	abstract
	XNode toNode(ref XNode parent, XMLOption opt);

	/// 指定されたXMLノードにProperty情報を追加する。
	const
	protected XNode setProp(ref XNode node, XMLOption opt, in OverData od = null) { mixin(S_TRACE);
		auto pNode = node.newElement("Property");
		pNode.newElement("Id", od && od.id != 0UL ? od.id : id);
		pNode.newElement("Name", name);
		CardImage.toNode(pNode, _paths);
		pNode.newElement("Description", encodeLf(desc));
		return pNode;
	}
	/// 指定されたXMLノードからProperty情報を読み出す。
	protected void loadProp(ref XNode pNode, in XMLInfo ver) { mixin(S_TRACE);
		string idStr = null;
		pNode.onTag["Id"] = (ref XNode n) { idStr = n.value; };
		CardImage[] paths;
		CardImage.setOnTag(pNode, paths);
		_name = null;
		pNode.onTag["Name"] = (ref XNode n) {_name = n.value;};
		pNode.onTag["Description"] = (ref XNode n) {_desc = decodeLf2(n.value);};
		pNode.parse();
		this.paths = paths;
		if (!idStr) throw new CardException("Id not found");
		if (!_name) _name = "";
		_id = to!(ulong)(idStr);
	}

	const
	override int opCmp(Object o) { mixin(S_TRACE);
		return cast(int) _id - cast(int) (cast(Card) o)._id;
	}

	const
	override hash_t toHash() {
		hash_t hash = 0;
		foreach (c; typeid(this).name) {
			hash = hash * 37 + c;
		}
		return cast(hash_t)(hash * 37 + _id);
	}
}

/// キャストカード。
class CastCard : Card, SkillOwner, ItemOwner, BeastOwner, CouponsOwner, ICouponUser {
private:
	mixin RaceParam!(true);

	uint _lev;
	uint _life;
	uint _lifeMax;

	Mentality _mentali = Mentality.NORMAL;
	uint _mentaliRound = 0;
	uint _para = 0;
	uint _poi = 0;
	uint _bindRound = 0;
	uint _slntRound = 0;
	uint _faceUpRound = 0;
	uint _antiMgcRound = 0;
	int[Enhance] _rEnh;
	uint[Enhance] _rEnhRound;
	Coupon[] _coupons;
	ItemCard[] _items;
	SkillCard[] _skills;
	BeastCard[] _beasts;

	template CArray(C) {
		static if (is(C : ItemCard)) {
			alias _items CArray;
		} else static if (is(C : SkillCard)) {
			alias _skills CArray;
		} else static if (is(C : BeastCard)) {
			alias _beasts CArray;
		} else static assert (0);
	}
public:
	/// キャストカードのXML要素名。
	static const string XML_NAME = "CastCard";
	/// キャストカード群のXML要素名。
	static const string XML_NAME_M = "CastCards";
	static alias toCastId toID;

	alias Card.changeHandler changeHandler;
	@property
	override void changeHandler(void delegate() change) { mixin(S_TRACE);
		super.changeHandler = change;
		foreach (c; _items) { mixin(S_TRACE);
			c.changeHandler = changeHandler;
		}
		foreach (c; _skills) { mixin(S_TRACE);
			c.changeHandler = changeHandler;
		}
		foreach (c; _beasts) { mixin(S_TRACE);
			c.changeHandler = changeHandler;
		}
	}

	/// インスタンスを生成する。
	/// Params:
	/// id = カードID。
	/// name = 名前。
	/// imagePaths = 画像のパス。
	/// desc = 解説。
	/// lev = レベル。
	/// lifeMax = ヒットポイント最大値。
	this (ulong id, string name, in CardImage[] imagePaths, string desc, uint lev, uint lifeMax) { mixin(S_TRACE);
		super(id, name, imagePaths, desc);
		_lev = lev;
		_life = lifeMax;
		_lifeMax = lifeMax;

		constructRace();
		_rEnh[Enhance.ACTION] = 0;
		_rEnh[Enhance.AVOID] = 0;
		_rEnh[Enhance.RESIST] = 0;
		_rEnh[Enhance.DEFENSE] = 0;
		_rEnhRound[Enhance.ACTION] = 0;
		_rEnhRound[Enhance.AVOID] = 0;
		_rEnhRound[Enhance.RESIST] = 0;
		_rEnhRound[Enhance.DEFENSE] = 0;
	}
	this (ulong id, string name, in CardImage[] imagePaths, string desc) { mixin(S_TRACE);
		this (id, name, imagePaths, desc, 1, 1);
	}
	/// cからパラメータをコピーする。
	void shallowCopy(in CastCard c) { mixin(S_TRACE);
		shallowCopyCard(c);
		copyRaceParam(c);
		level = c.level;
		life = c.life;
		lifeMax = c.lifeMax;
		mentality = c.mentality;
		mentalityRound = c.mentalityRound;
		paralyze = c.paralyze;
		poison = c.poison;
		bindRound = c.bindRound;
		silenceRound = c.silenceRound;
		faceUpRound = c.faceUpRound;
		antiMagicRound = c.antiMagicRound;
		enhance(Enhance.ACTION, c.enhance(Enhance.ACTION));
		enhanceRound(Enhance.ACTION, c.enhanceRound(Enhance.ACTION));
		enhance(Enhance.AVOID, c.enhance(Enhance.AVOID));
		enhanceRound(Enhance.AVOID, c.enhanceRound(Enhance.AVOID));
		enhance(Enhance.RESIST, c.enhance(Enhance.RESIST));
		enhanceRound(Enhance.RESIST, c.enhanceRound(Enhance.RESIST));
		enhance(Enhance.DEFENSE, c.enhance(Enhance.DEFENSE));
		enhanceRound(Enhance.DEFENSE, c.enhanceRound(Enhance.DEFENSE));
		Coupon[] cps;
		foreach (cp; c.coupons) { mixin(S_TRACE);
			cps ~= new Coupon(cp);
		}
		coupons = cps;
	}
	/// ditto
	void deepCopy(in CastCard c) { mixin(S_TRACE);
		shallowCopy(c);
		foreach (s; c.skills) { mixin(S_TRACE);
			add(s.dup);
		}
		foreach (s; c.items) { mixin(S_TRACE);
			add(s.dup);
		}
		foreach (s; c.beasts) { mixin(S_TRACE);
			add(s.dup);
		}
	}

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto c = cast(const CastCard) o;
		if (!c) return false;
		if (!super.opEquals(o)) return false;
		return eqImpl(c);
	}
	/// ID以外を比較する。
	const
	bool equalsExcludeId(const(CastCard) c) { mixin(S_TRACE);
		if (!super.equalsExcludeIdCard(c)) return false;
		return eqImpl(c);
	}
	const
	private bool eqImpl(ref const(CastCard) c) { mixin(S_TRACE);
		if (!equalsRace(c)) return false;
		return level == c.level
			&& life == c.life
			&& lifeMax == c.lifeMax
			&& mentality == c.mentality
			&& mentalityRound == c.mentalityRound
			&& paralyze == c.paralyze
			&& poison == c.poison
			&& bindRound == c.bindRound
			&& silenceRound == c.silenceRound
			&& faceUpRound == c.faceUpRound
			&& antiMagicRound == c.antiMagicRound
			&& enhance(Enhance.ACTION) == c.enhance(Enhance.ACTION)
			&& enhanceRound(Enhance.ACTION) == c.enhanceRound(Enhance.ACTION)
			&& enhance(Enhance.AVOID) == c.enhance(Enhance.AVOID)
			&& enhanceRound(Enhance.AVOID) == c.enhanceRound(Enhance.AVOID)
			&& enhance(Enhance.RESIST) == c.enhance(Enhance.RESIST)
			&& enhanceRound(Enhance.RESIST) == c.enhanceRound(Enhance.RESIST)
			&& enhance(Enhance.DEFENSE) == c.enhance(Enhance.DEFENSE)
			&& enhanceRound(Enhance.DEFENSE) == c.enhanceRound(Enhance.DEFENSE)
			&& coupons == c.coupons
			&& skills == c.skills
			&& items == c.items
			&& beasts == c.beasts;
	}

	/// ディープコピーを作成する。
	@property
	const
	override
	CastCard dup() { mixin(S_TRACE);
		auto copy = new CastCard(0UL, "", [], "");
		copy.deepCopy(this);
		return copy;
	}

	override bool change(CouponId id) { return true; }

	/// 使用回数カウンタ。
	@property
	override
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		foreach (c; _items) { mixin(S_TRACE);
			c.setUseCounter = uc;
		}
		foreach (c; _skills) { mixin(S_TRACE);
			c.setUseCounter = uc;
		}
		foreach (c; _beasts) { mixin(S_TRACE);
			c.setUseCounter = uc;
		}
		foreach (c; _coupons) { mixin(S_TRACE);
			c.setUseCounter = uc;
		}
		super.setUseCounter = uc;
	}
	/// ditto
	@property
	override
	UseCounter useCounter() { mixin(S_TRACE);
		return super.useCounter;
	}
	/// ditto
	override
	void removeUseCounter() { mixin(S_TRACE);
		foreach (c; _items) { mixin(S_TRACE);
			c.removeUseCounter();
		}
		foreach (c; _skills) { mixin(S_TRACE);
			c.removeUseCounter();
		}
		foreach (c; _beasts) { mixin(S_TRACE);
			c.removeUseCounter();
		}
		foreach (c; _coupons) { mixin(S_TRACE);
			c.removeUseCounter();
		}
		super.removeUseCounter();
	}
	/// レベル。
	@property
	const
	uint level() {return _lev;}
	/// ditto
			@property
	void level(uint lev) { mixin(S_TRACE);
		if (_lev != lev) changed();
		_lev = lev;
	}
	/// ヒットポイント。
	@property
	const
	uint life() {return _life;}
	/// ditto
			@property
	void life(uint life) { mixin(S_TRACE);
		if (_life != life) changed();
		_life = life;
	}
	/// ヒットポイント最大値。
	@property
	const
	uint lifeMax() {return _lifeMax;}
	/// ditto
			@property
	void lifeMax(uint lifeMax) { mixin(S_TRACE);
		if (_lifeMax != lifeMax) changed();
		_lifeMax = lifeMax;
	}
	// 適性値を返す。
	const
	int aptitude(Physical phy, Mental m) { mixin(S_TRACE);
		auto mVal = mental(m);
		if (cast(int)mVal != mVal) { mixin(S_TRACE);
			mVal = mVal < 0 ? mVal + 0.5 : mVal - 0.5;
		}
		return physical(phy) + cast(int)mVal;
	}

	/// 所持するクーポン。
	@property
	inout
	inout(Coupon)[] coupons() {return _coupons;}
	/// ditto
	@property
	void coupons(Coupon[] coupons) { mixin(S_TRACE);
		if (_coupons != coupons) changed();
		foreach (c; _coupons) { mixin(S_TRACE);
			c.owner = null;
			c.removeUseCounter();
		}
		foreach (c; coupons) { mixin(S_TRACE);
			c.owner = this;
			if (useCounter) { mixin(S_TRACE);
				c.setUseCounter = useCounter;
			}
		}
		_coupons = coupons;
	}

	private C addImpl(C)(ref C[] arr, C c, bool newCard) { mixin(S_TRACE);
		if (contains!("a is b")(arr, c)) { mixin(S_TRACE);
			remove(c);
			newCard = true;
		}
		if (!newCard) c = c.dup;
		if (arr.length > 0 && arr[$ - 1].id >= c.id) { mixin(S_TRACE);
			c.id = arr[$ - 1].id + 1L;
		}
		if (useCounter) { mixin(S_TRACE);
			c.setUseCounter = useCounter;
		}
		c.changeHandler = changeHandler;
		c.owner = this;
		arr ~= c;
		changed();
		return c;
	}
	private void removeCImpl(C)(ref C[] arr, C card) { mixin(S_TRACE);
		foreach (i, c; arr) { mixin(S_TRACE);
			if (c is card) { mixin(S_TRACE);
				arr[i].removeUseCounter();
				arr[i].changeHandler = null;
				arr[i].owner = null;
				arr = arr[0 .. i] ~ arr[i + 1 .. $];
				changed();
			}
		}
	}
	private void removeImpl(C)(ref C[] arr, ulong id) { mixin(S_TRACE);
		foreach (i, c; arr) { mixin(S_TRACE);
			if (c.id == id) { mixin(S_TRACE);
				arr[i].removeUseCounter();
				arr[i].changeHandler = null;
				arr[i].owner = null;
				arr = arr[0 .. i] ~ arr[i + 1 .. $];
				changed();
			}
		}
	}
	const
	private C findImpl(C)(C[] arr, ulong id) { mixin(S_TRACE);
		foreach (c; arr) { mixin(S_TRACE);
			if (c.id == id) { mixin(S_TRACE);
				return c;
			}
		}
		return null;
	}
	private T insertImpl(T, alias ToID)(ref T[] arr, size_t index, T c, bool newCard) { mixin(S_TRACE);
		if (arr.length == index) { mixin(S_TRACE);
			return addImpl!(T)(arr, c, newCard);
		} else { mixin(S_TRACE);
			auto oldIdx = indexOf(c);
			if (oldIdx >= 0) { mixin(S_TRACE);
				remove(c);
				newCard = true;
				if (oldIdx < index) index--;
			}
			if (!newCard) c = c.dup;
			c.id(index == 0 ? 1L : arr[index - 1].id() + 1L);
			arr = arr[0 .. index] ~ c ~ arr[index .. $];
			for (size_t i = index + 1; i < arr.length; i++) { mixin(S_TRACE);
				if (arr[i - 1].id == arr[i].id) { mixin(S_TRACE);
					ulong o = arr[i].id();
					arr[i].id = arr[i].id + 1L;
				}
			}
			c.setUseCounter = useCounter;
			c.changeHandler = changeHandler;
			c.owner = this;
			changed();
			return c;
		}
	}

	/// 所持アイテム。
	@property
	inout
	inout(ItemCard)[] items() {return _items;}
	/// ditto
	ItemCard add(ItemCard card, bool newCard = false) {return addImpl(_items, card, newCard);}
	/// ditto
	void removeItem(ulong id) {removeImpl(_items, id);}
	/// ditto
	inout
	inout(ItemCard) item(ulong id) { mixin(S_TRACE);
		return findImpl(_items, id);
	}
	/// ditto
	void remove(ItemCard c) { mixin(S_TRACE);
		removeCImpl(_items, c);
	}
	/// ditto
	ItemCard insert(size_t index, ItemCard c, bool newCard = false) { mixin(S_TRACE);
		return insertImpl!(ItemCard, toItemId)(_items, index, c, newCard);
	}
	/// 所持スキル。
	@property
	inout
	inout(SkillCard)[] skills() {return _skills;}
	/// ditto
	SkillCard add(SkillCard card, bool newCard = false) {return addImpl(_skills, card, newCard);}
	/// ditto
	void removeSkill(ulong id) {removeImpl(_skills, id);}
	/// ditto
	inout
	inout(SkillCard) skill(ulong id) { mixin(S_TRACE);
		return findImpl(_skills, id);
	}
	/// ditto
	void remove(SkillCard c) { mixin(S_TRACE);
		removeCImpl(_skills, c);
	}
	/// ditto
	SkillCard insert(size_t index, SkillCard c, bool newCard = false) { mixin(S_TRACE);
		return insertImpl!(SkillCard, toSkillId)(_skills, index, c, newCard);
	}
	/// 所持召喚獣。
	@property
	inout
	inout(BeastCard)[] beasts() {return _beasts;}
	/// ditto
	BeastCard add(BeastCard card, bool newCard = false) {return addImpl(_beasts, card, newCard);}
	/// ditto
	void removeBeast(ulong id) {removeImpl(_beasts, id);}
	/// ditto
	inout
	inout(BeastCard) beast(ulong id) { mixin(S_TRACE);
		return findImpl(_beasts, id);
	}
	/// ditto
	void remove(BeastCard c) { mixin(S_TRACE);
		removeCImpl(_beasts, c);
	}
	/// ditto
	BeastCard insert(size_t index, BeastCard c, bool newCard = false) { mixin(S_TRACE);
		return insertImpl!(BeastCard, toBeastId)(_beasts, index, c, newCard);
	}

	/// 指定された要素のindexを検索する。
	const
	ptrdiff_t indexOf(T)(in T c) { mixin(S_TRACE);
		static if (is (T == SkillCard)) {
			return .cCountUntil!("a is b")(_skills, c);
		} else static if (is (T == ItemCard)) {
			return .cCountUntil!("a is b")(_items, c);
		} else static if (is (T == BeastCard)) {
			return .cCountUntil!("a is b")(_beasts, c);
		} else { mixin(S_TRACE);
			static assert (0);
		}
	}

	/// index1とindex2を交換する。
	void swap(C)(size_t index1, size_t index2) { mixin(S_TRACE);
		if (index1 == index2) return;
		enforce(0 <= index1 && index1 < CArray!C.length);
		enforce(0 <= index2 && index2 < CArray!C.length);
		changed();

		ulong id1 = CArray!C[index1].id;
		ulong id2 = CArray!C[index2].id;
		std.algorithm.swap(CArray!C[index1], CArray!C[index2]);

		CArray!C[index1].id = id1;
		CArray!C[index2].id = id2;
	}
	/// ditto
	alias swap!SkillCard swapSkill;
	/// ditto
	alias swap!ItemCard swapItem;
	/// ditto
	alias swap!BeastCard swapBeast;

	/// 精神状態。
	@property
	const
	Mentality mentality() {return _mentali;}
	/// ditto
	@property
	void mentality(Mentality mentali) { mixin(S_TRACE);
		if (_mentali != mentali) changed();
		_mentali = mentali;
	}
	/// 精神異常の残り時間。
	@property
	const
	uint mentalityRound() {return _mentaliRound;}
	/// ditto
	@property
	void mentalityRound(uint round) { mixin(S_TRACE);
		if (_mentaliRound != round) changed();
		_mentaliRound = round;
	}
	/// 麻痺の値。
	@property
	const
	uint paralyze() {return _para;}
	/// ditto
	@property
	void paralyze(uint value) { mixin(S_TRACE);
		if (_para != value) changed();
		_para = value;
	}
	/// 毒の値。
	@property
	const
	uint poison() {return _poi;}
	/// ditto
	@property
	void poison(uint value) { mixin(S_TRACE);
		if (_poi != value) changed();
		_poi = value;
	}
	/// 呪縛の残り時間。
	@property
	const
	uint bindRound() {return _bindRound;}
	/// ditto
	@property
	void bindRound(uint round) { mixin(S_TRACE);
		if (_bindRound != round) changed();
		_bindRound = round;
	}
	/// 沈黙の残り時間。
	@property
	const
	uint silenceRound() {return _slntRound;}
	/// ditto
	@property
	void silenceRound(uint round) { mixin(S_TRACE);
		if (_slntRound != round) changed();
		_slntRound = round;
	}
	/// 暴露の残り時間。
	@property
	const
	uint faceUpRound() {return _faceUpRound;}
	/// ditto
	@property
	void faceUpRound(uint round) { mixin(S_TRACE);
		if (_faceUpRound != round) changed();
		_faceUpRound = round;
	}
	/// 魔法無効状態の残り時間。
	@property
	const
	uint antiMagicRound() {return _antiMgcRound;}
	/// ditto
	@property
	void antiMagicRound(uint round) { mixin(S_TRACE);
		if (_antiMgcRound != round) changed();
		_antiMgcRound = round;
	}
	/// 能力値ボーナスの値。
	const
	int enhance(Enhance enh) {return _rEnh[enh];}
	/// ditto
	void enhance(Enhance enh, int value) { mixin(S_TRACE);
		if (_rEnh[enh] != value) changed();
		_rEnh[enh] = value;
	}
	/// 能力値ボーナスの残り時間。
	const
	uint enhanceRound(Enhance enh) {return _rEnhRound[enh];}
	/// ditto
	void enhanceRound(Enhance enh, uint round) { mixin(S_TRACE);
		if (_rEnhRound[enh] != round) changed();
		_rEnhRound[enh] = round;
	}

	/// XMLテキストに変換する。
	const
	string toXML(XMLOption opt) { mixin(S_TRACE);
		return toNode(opt).text;
	}
	/// XMLノードに変換する。
	const
	XNode toNode(XMLOption opt) { mixin(S_TRACE);
		auto n = XNode.create(XML_NAME);
		n.newAttr("dataVersion", opt.dataVersion);
		toNodeImpl(n, opt);
		return n;
	}
	/// 自身をXMLノードにして指定されたノードに追加する。
	const
	override
	XNode toNode(ref XNode parent, XMLOption opt) { mixin(S_TRACE);
		auto cNode = parent.newElement(XML_NAME);
		cNode.newAttr("dataVersion", opt.dataVersion);
		toNodeImpl(cNode, opt);
		return cNode;
	}
	const
	private void toNodeImpl(ref XNode cNode, XMLOption opt) { mixin(S_TRACE);
		auto pNode = setProp(cNode, opt, null);
		pNode.newElement("Level", level);
		pNode.newElement("Life", life).newAttr("max", lifeMax);
		setFeature(pNode);
		setAbility(pNode);
		{ mixin(S_TRACE);
			auto sNode = pNode.newElement("Status");
			sNode.newElement("Mentality", fromMentality(mentality)).newAttr("duration", mentalityRound);
			sNode.newElement("Paralyze", paralyze);
			sNode.newElement("Poison", poison);
			sNode.newElement("Bind").newAttr("duration", bindRound);
			sNode.newElement("Silence").newAttr("duration", silenceRound);
			sNode.newElement("FaceUp").newAttr("duration", faceUpRound);
			sNode.newElement("AntiMagic").newAttr("duration", antiMagicRound);
		}
		{ mixin(S_TRACE);
			auto eNode = pNode.newElement("Enhance");
			eNode.newElement("Action", enhance(Enhance.ACTION))
				.newAttr("duration", enhanceRound(Enhance.ACTION));
			eNode.newElement("Avoid", enhance(Enhance.AVOID))
				.newAttr("duration", enhanceRound(Enhance.AVOID));
			eNode.newElement("Resist", enhance(Enhance.RESIST))
				.newAttr("duration", enhanceRound(Enhance.RESIST));
			eNode.newElement("Defense", enhance(Enhance.DEFENSE))
				.newAttr("duration", enhanceRound(Enhance.DEFENSE));
		}
		{ mixin(S_TRACE);
			auto cpNode = pNode.newElement(Coupon.XML_NAME_M);
			foreach (c; _coupons) { mixin(S_TRACE);
				c.toNode(cpNode);
			}
		}
		{ mixin(S_TRACE);
			auto cardNode = cNode.newElement("ItemCards");
			foreach (c; _items) { mixin(S_TRACE);
				c.toNode(cardNode, opt);
			}
		}
		{ mixin(S_TRACE);
			auto cardNode = cNode.newElement("SkillCards");
			foreach (c; _skills) { mixin(S_TRACE);
				c.toNode(cardNode, opt);
			}
		}
		{ mixin(S_TRACE);
			auto cardNode = cNode.newElement("BeastCards");
			foreach (c; _beasts) { mixin(S_TRACE);
				c.toNode(cardNode, opt);
			}
		}
	}

	/// XMLノードからインスタンスを生成する。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static CastCard createFromNode(XNode cNode, in XMLInfo ver) { mixin(S_TRACE);
		if (cNode.name != XML_NAME) throw new CardException("Node is not cast card: " ~ cNode.name);
		auto r = new CastCard(0, "", [], "", 1, 1);
		cNode.onTag["Property"] = (ref XNode pNode) { mixin(S_TRACE);
			pNode.onTag["Level"] = (ref XNode n) {r._lev = n.valueTo!(int);};
			pNode.onTag["Life"] = (ref XNode n) { mixin(S_TRACE);
				r._life = n.valueTo!(int);
				r._lifeMax = n.attr!(int)("max", true);
			};
			pNode.onTag["Feature"] = (ref XNode n) {r.loadFeature(n, ver);};
			pNode.onTag["Ability"] = (ref XNode n) {r.loadAbility(n, ver);};

			pNode.onTag["Status"] = (ref XNode sNode) { mixin(S_TRACE);
				sNode.onTag["Mentality"] = (ref XNode n) { mixin(S_TRACE);
					r.mentality = toMentality(n.value);
					r.mentalityRound = n.attr!(int)("duration", true);
				};
				sNode.onTag["Paralyze"] = (ref XNode n) { mixin(S_TRACE);
					r.paralyze = n.valueTo!(int);
				};
				sNode.onTag["Poison"] = (ref XNode n) { mixin(S_TRACE);
					r.poison = n.valueTo!(int);
				};
				sNode.onTag["Bind"] = (ref XNode n) { mixin(S_TRACE);
					r.bindRound =  n.attr!(int)("duration", true);
				};
				sNode.onTag["Silence"] = (ref XNode n) { mixin(S_TRACE);
					r.silenceRound =  n.attr!(int)("duration", true);
				};
				sNode.onTag["FaceUp"] = (ref XNode n) { mixin(S_TRACE);
					r.faceUpRound =  n.attr!(int)("duration", true);
				};
				sNode.onTag["AntiMagic"] = (ref XNode n) { mixin(S_TRACE);
					r.antiMagicRound =  n.attr!(int)("duration", true);
				};
				sNode.parse();
			};
			pNode.onTag["Enhance"] = (ref XNode n) { mixin(S_TRACE);
				void setEnh(ref XNode n, Enhance enh) { mixin(S_TRACE);
					r.enhance(enh, n.valueTo!(int));
					r.enhanceRound(enh, n.attr!(int)("duration", true));
				}
				n.onTag["Action"] = (ref XNode n) {setEnh(n, Enhance.ACTION);};
				n.onTag["Avoid"] = (ref XNode n) {setEnh(n, Enhance.AVOID);};
				n.onTag["Resist"] = (ref XNode n) {setEnh(n, Enhance.RESIST);};
				n.onTag["Defense"] = (ref XNode n) {setEnh(n, Enhance.DEFENSE);};
				n.parse();
			};
			Coupon[] coupons;
			pNode.onTag[Coupon.XML_NAME_M] = (ref XNode n) { mixin(S_TRACE);
				n.onTag[Coupon.XML_NAME] = (ref XNode n) { mixin(S_TRACE);
					coupons ~= Coupon.fromNode(n, ver);
				};
				n.parse();
			};
			r.loadProp(pNode, ver);
			r.coupons = coupons;
		};

		cNode.onTag["ItemCards"] = (ref XNode n) { mixin(S_TRACE);
			n.onTag[ItemCard.XML_NAME] = (ref XNode n) { mixin(S_TRACE);
				auto c = ItemCard.createFromNode(n, ver);
				c.owner = r;
				r._items ~= c;
			};
			n.parse();
			.sort(r._items);
		};
		cNode.onTag["SkillCards"] = (ref XNode n) { mixin(S_TRACE);
			n.onTag[SkillCard.XML_NAME] = (ref XNode n) { mixin(S_TRACE);
				auto c = SkillCard.createFromNode(n, ver);
				c.owner = r;
				r._skills ~= c;
			};
			n.parse();
			.sort(r._skills);
		};
		cNode.onTag["BeastCards"] = (ref XNode n) { mixin(S_TRACE);
			n.onTag[BeastCard.XML_NAME] = (ref XNode n) { mixin(S_TRACE);
				auto c = BeastCard.createFromNode(n, ver);
				c.owner = r;
				r._beasts ~= c;
			};
			n.parse();
			.sort(r._beasts);
		};
		cNode.parse();
		return r;
	}

	private CastOwner _owner = null;
	@property
	package void owner(CastOwner owner) {_owner = owner;}
	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		if (id) { mixin(S_TRACE);
			return _owner ? cpjoinid(_owner, "castcard", this.id) : "";
		} else { mixin(S_TRACE);
			return _owner ? cpjoin(_owner, "castcard", .cCountUntil!("a is b")(_owner.casts, this), id) : "";
		}
	}
	CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		switch (cate) {
		case "skillcard": { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= skills.length) return null;
			return skills[index].findCWXPath(cpbottom(path));
		}
		case "skillcard:id": { mixin(S_TRACE);
			auto card = skill(cpindex(path));
			return card ? card.findCWXPath(cpbottom(path)) : null;
		}
		case "itemcard": { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= items.length) return null;
			return items[index].findCWXPath(cpbottom(path));
		}
		case "itemcard:id": { mixin(S_TRACE);
			auto card = item(cpindex(path));
			return card ? card.findCWXPath(cpbottom(path)) : null;
		}
		case "beastcard": { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= beasts.length) return null;
			return beasts[index].findCWXPath(cpbottom(path));
		}
		case "beastcard:id": { mixin(S_TRACE);
			auto card = beast(cpindex(path));
			return card ? card.findCWXPath(cpbottom(path)) : null;
		}
		default: break;
		}
		return null;
	}
	@property
	inout
	inout(CWXPath)[] cwxChilds() { mixin(S_TRACE);
		inout(CWXPath)[] r;
		foreach (a; skills) r ~= a;
		foreach (a; items) r ~= a;
		foreach (a; beasts) r ~= a;
		return r;
	}
	@property
	CWXPath cwxParent() {return _owner;}
}

/// スキル・アイテム・召喚獣といった、「効果」のあるカードの親クラス。
abstract class EffectCard : Card, EventTreeOwner, MotionOwner, IPathUser, IKeyCodeUser {
private:
	string _scenario = "";
	string _author = "";
	Physical _phy = Physical.DEX;
	Mental _mtl = Mental.AGGRESSIVE;
	CardTarget _targ = CardTarget.NONE;
	bool _allRange = false;
	bool _spell = false;
	EffectType _effTyp = EffectType.PHYSIC;
	Resist _res = Resist.AVOID;
	int _suc = 0;
	CardVisual _vis = CardVisual.NONE;
	int[Enhance] _enh;
	PathUser _se1;
	PathUser _se2;
	uint _volume1 = 100;
	uint _volume2 = 100;
	uint _loopCount1 = 1;
	uint _loopCount2 = 1;
	KeyCodeUser[] _keyCodes = [];
	Premium _premi = Premium.NORMAL;
	MotionUser _muser;
	AbstractEventTreeOwner _ceto;
	class CETO : AbstractEventTreeOwner {
		override
		@property
		protected EventTreeOwner con() {return this.outer;}
		@property
		const
		override bool canHasFireEnter() {return false;}
		@property
		const
		override bool canHasFireLose() {return false;}
		@property
		const
		override bool canHasFireEscape() {return false;}
		@property
		const
		override bool canHasFireEveryRound() {return false;}
		@property
		const
		override bool canHasFireRound0() {return false;}
		@property
		const
		override bool canHasFireRound() {return false;}
		@property
		const
		override bool canHasFireKeyCode() {return false;}
		@property
		override size_t[] areaPath() {return [0];}
		@property
		string cwxPath(bool id) {return this.outer.cwxPath(id);}
		@property
		CWXPath cwxParent() {return this.outer.cwxParent();}
	}
public:
	/// 唯一のコンストラクタ。
	/// Params:
	/// id = カードID。
	/// name = 名前。
	/// imagePaths = 画像のパス。
	/// desc = 解説。
	this (ulong id, string name, in CardImage[] imagePaths, string desc) { mixin(S_TRACE);
		super(id, name, imagePaths, desc);
		_ceto = new CETO;
		_muser = new MotionUser(this);
		_se1 = new PathUser(this);
		_se2 = new PathUser(this);
		_enh = [Enhance.AVOID:0, Enhance.RESIST:0, Enhance.DEFENSE:0];
	}
	/// cからパラメータをコピーする。
	protected void shallowCopyEffectCard(in EffectCard c) { mixin(S_TRACE);
		shallowCopyCard(c);
		linkId = c.linkId;
		scenario = c.scenario;
		author = c.author;
		physical = c.physical;
		mental = c.mental;
		target = c.target;
		allRange = c.allRange;
		spell = c.spell;
		effectType = c.effectType;
		resist = c.resist;
		successRate = c.successRate;
		visual = c.visual;
		enhance(Enhance.AVOID, c.enhance(Enhance.AVOID));
		enhance(Enhance.RESIST, c.enhance(Enhance.RESIST));
		enhance(Enhance.DEFENSE, c.enhance(Enhance.DEFENSE));
		soundPath1 = c.soundPath1;
		volume1 = c.volume1;
		loopCount1 = c.loopCount1;
		soundPath2 = c.soundPath2;
		volume2 = c.volume2;
		loopCount2 = c.loopCount2;
		keyCodes = c.keyCodes;
		premium = c.premium;
		Motion[] ms;
		foreach (m; c.motions) { mixin(S_TRACE);
			ms ~= m.dup;
		}
		motions = ms;
	}
	/// ditto
	protected void deepCopyEffectCard(in EffectCard c) { mixin(S_TRACE);
		shallowCopyEffectCard(c);
		foreach (tree; c.trees) { mixin(S_TRACE);
			add(tree.dup);
		}
	}
	/// IDを除く内部データをクリアする。
	protected override void clearData() { mixin(S_TRACE);
		super.clearData();
		_ceto.clearEvents();
		linkId = 0;
		scenario = "";
		author = "";
		physical = Physical.DEX;
		mental = Mental.AGGRESSIVE;
		target = CardTarget.NONE;
		allRange = false;
		spell = false;
		effectType = EffectType.PHYSIC;
		resist = Resist.AVOID;
		successRate = 0;
		visual = CardVisual.NONE;
		enhance(Enhance.AVOID, 0);
		enhance(Enhance.RESIST, 0);
		enhance(Enhance.DEFENSE, 0);
		soundPath1 = "";
		volume1 = 100;
		loopCount1 = 1;
		soundPath2 = "";
		volume2 = 100;
		loopCount2 = 1;
		keyCodes = [];
		premium = Premium.NORMAL;
		motions = [];
	}

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto c = cast(const EffectCard) o;
		if (!c) return false;
		if (0 != linkId) return linkId == c.linkId;
		if (!super.opEquals(o)) return false;
		return eqImpl(c);
	}
	/// ID以外を比較する。
	const
	protected bool equalsExcludeIdEffect(const(EffectCard) c) { mixin(S_TRACE);
		if (!c) return false;
		if (0 != linkId) return linkId == c.linkId;
		if (!super.equalsExcludeIdCard(c)) return false;
		return eqImpl(c);
	}
	const
	private bool eqImpl(const(EffectCard) c) { mixin(S_TRACE);
		return linkId == c.linkId
			&& scenario == c.scenario
			&& author == c.author
			&& physical == c.physical
			&& mental == c.mental
			&& target == c.target
			&& allRange == c.allRange
			&& spell == c.spell
			&& effectType == c.effectType
			&& resist == c.resist
			&& successRate == c.successRate
			&& visual == c.visual
			&& enhance(Enhance.AVOID) == c.enhance(Enhance.AVOID)
			&& enhance(Enhance.RESIST) == c.enhance(Enhance.RESIST)
			&& enhance(Enhance.DEFENSE) == c.enhance(Enhance.DEFENSE)
			&& soundPath1 == c.soundPath1
			&& volume1 == c.volume1
			&& loopCount1 == c.loopCount1
			&& soundPath2 == c.soundPath2
			&& volume2 == c.volume2
			&& loopCount2 == c.loopCount2
			&& keyCodes == c.keyCodes
			&& premium == c.premium
			&& motions == c.motions
			&& trees == c.trees;
	}

	@property
	const
	abstract ulong linkId();
	@property
	abstract void linkId(ulong);

	/// カードが属するシナリオ名、及びカードの製作者。
	/// 他のシナリオからのインポート等があるため、
	/// 現在のシナリオと同一になるとは限らない。
	@property
	const
	string scenario() {return _scenario;}
	/// ditto
	@property
	void scenario(string scenario) { mixin(S_TRACE);
		if (_scenario != scenario) changed();
		_scenario = scenario;
	}
	/// ditto
	@property
	const
	string author() {return _author;}
	/// ditto
	@property
	void author(string author) { mixin(S_TRACE);
		if (_author != author) changed();
		_author = author;
	}

	/// カードの適正。肉体要素。
	@property
	const
	Physical physical() {return _phy;}
	/// ditto
	@property
	void physical(Physical phy) { mixin(S_TRACE);
		if (_phy != phy) changed();
		_phy = phy;
	}
	/// カードの適正。精神要素。
	@property
	const
	Mental mental() {return _mtl;}
	/// ditto
	@property
	void mental(Mental mtl) { mixin(S_TRACE);
		if (_mtl != mtl) changed();
		_mtl = mtl;
	}

	/// カードの標的。
	@property
	const
	CardTarget target() {return _targ;}
	/// ditto
	@property
	void target(CardTarget targ) { mixin(S_TRACE);
		if (_targ != targ) changed();
		_targ = targ;
	}
	/// 全体が標的となるか。
	@property
	const
	bool allRange() {return _allRange;}
	/// ditto
	@property
	void allRange(bool allRange) { mixin(S_TRACE);
		if (_allRange != allRange) changed();
		_allRange = allRange;
	}
	/// 使用時に発声が必要か。
	@property
	const
	bool spell() {return _spell;}
	/// ditto
	@property
	void spell(bool spell) { mixin(S_TRACE);
		if (_spell != spell) changed();
		_spell = spell;
	}
	/// 効果のタイプ。物理、魔法、魔法的物理、物理的魔法。
	@property
	const
	EffectType effectType() {return _effTyp;}
	/// ditto
	@property
	void effectType(EffectType effTyp) { mixin(S_TRACE);
		if (_effTyp != effTyp) changed();
		_effTyp = effTyp;
	}
	/// 回避属性。回避か抵抗か。
	@property
	const
	Resist resist() {return _res;}
	/// ditto
	@property
	void resist(Resist res) { mixin(S_TRACE);
		if (_res != res) changed();
		_res = res;
	}
	/// 成功率。-5～+5。
	@property
	const
	int successRate() {return _suc;}
	/// ditto
	@property
	void successRate(int suc) { mixin(S_TRACE);
		if (_suc != suc) changed();
		_suc = suc;
	}
	/// カードの視覚効果。
	@property
	const
	CardVisual visual() {return _vis;}
	/// ditto
	@property
	void visual(CardVisual vis) { mixin(S_TRACE);
		if (_vis != vis) changed();
		_vis = vis;
	}
	/// 使用時の能力値ボーナス。
	const
	int enhance(Enhance enh) {return _enh[enh];}
	/// ditto
	void enhance(Enhance enh, int val) { mixin(S_TRACE);
		if (_enh[enh] != val) changed();
		_enh[enh] = val;
	}
	/// 使用時サウンド。
	@property
	const
	string soundPath1() {return _se1.path;}
	/// ditto
	@property
	void soundPath1(string path) { mixin(S_TRACE);
		if (_se1.path != path) changed();
		_se1.path = path;
	}
	/// 使用時サウンドの音量(%)。
	@property
	void volume1(uint volume1) { mixin(S_TRACE);
		if (_volume1 != volume1) changed();
		_volume1 = volume1;
	}
	/// ditto
	@property
	const
	uint volume1() { return _volume1; }
	/// 使用時サウンドのループ回数。0で無限ループ。
	@property
	void loopCount1(uint loopCount1) { mixin(S_TRACE);
		if (_loopCount1 != loopCount1) changed();
		_loopCount1 = loopCount1;
	}
	/// ditto
	@property
	const
	uint loopCount1() { return _loopCount1; }

	/// 命中時サウンド。
	@property
	const
	string soundPath2() {return _se2.path;}
	/// ditto
	@property
	void soundPath2(string path) { mixin(S_TRACE);
		if (_se2.path != path) changed();
		_se2.path = path;
	}
	/// 命中時サウンドの音量(%)。
	@property
	void volume2(uint volume2) { mixin(S_TRACE);
		if (_volume2 != volume2) changed();
		_volume2 = volume2;
	}
	/// ditto
	@property
	const
	uint volume2() { return _volume2; }
	/// 命中時サウンドのループ回数。0で無限ループ。
	@property
	void loopCount2(uint loopCount2) { mixin(S_TRACE);
		if (_loopCount2 != loopCount2) changed();
		_loopCount2 = loopCount2;
	}
	/// ditto
	@property
	const
	uint loopCount2() { return _loopCount2; }

	/// キーコード。
	@property
	const
	string[] keyCodes() { mixin(S_TRACE);
		auto r = new string[_keyCodes.length];
		foreach (i, ref kc; r) { mixin(S_TRACE);
			kc = _keyCodes[i].keyCode;
		}
		return r;
	}
	/// ditto
	@property
	void keyCodes(string[] keyCodes) { mixin(S_TRACE);
		if (this.keyCodes != keyCodes) { mixin(S_TRACE);
			changed();
			foreach (c; _keyCodes) { mixin(S_TRACE);
				c.removeUseCounter();
			}
			_keyCodes.length = keyCodes.length;
			foreach (i, ref c; _keyCodes) { mixin(S_TRACE);
				c = new KeyCodeUser(this);
				c.keyCode = keyCodes[i];
				if (useCounter) { mixin(S_TRACE);
					c.setUseCounter = useCounter;
				}
			}
		}
	}
	/// カードの希少価値。
	@property
	const
	Premium premium() {return _premi;}
	/// ditto
	@property
	void premium(Premium premi) { mixin(S_TRACE);
		if (_premi != premi) changed();
		_premi = premi;
	}
	/// カードの効果。
	@property
	inout
	inout(Motion)[] motions() {return _muser.motions;}
	/// ditto
	@property
	void motions(Motion[] motions) { mixin(S_TRACE);
		_muser.motions = motions;
	}
	alias Card.changeHandler changeHandler;
 	@property
	override void changeHandler(void delegate() change) { mixin(S_TRACE);
		super.changeHandler = change;
		_ceto.changeHandler = changeHandler;
		_muser.changeHandler = changeHandler;
	}
	@property
	override void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		setUseCounterImpl(uc);
		_ceto.setUseCounter = uc;
		_muser.setUseCounter = uc;
		_se1.setUseCounter = uc;
		_se2.setUseCounter = uc;
		foreach (ref kc; _keyCodes) { mixin(S_TRACE);
			kc.setUseCounter = uc;
		}
		super.setUseCounter = uc;
	}
	@property
	override void removeUseCounter() { mixin(S_TRACE);
		removeUseCounterImpl();
		_ceto.removeUseCounter();
		_muser.removeUseCounter();
		_se1.removeUseCounter();
		_se2.removeUseCounter();
		foreach (ref kc; _keyCodes) { mixin(S_TRACE);
			kc.removeUseCounter();
		}
		super.removeUseCounter();
	}
	protected abstract void setUseCounterImpl(UseCounter uc);
	protected abstract void removeUseCounterImpl();

	override bool change(KeyCodeId id) { return true; }

	@property
	inout
	override inout(EventTree)[] trees() {return _ceto.trees;}

	@property
	const
	override bool canHasFireEnter() {return _ceto.canHasFireEnter;}
	@property
	const
	override bool canHasFireLose() {return _ceto.canHasFireLose;}
	@property
	const
	override bool canHasFireEscape() {return _ceto.canHasFireEscape;}
	@property
	const
	override bool canHasFireEveryRound() {return _ceto.canHasFireEveryRound;}
	@property
	const
	override bool canHasFireRound0() {return _ceto.canHasFireRound0;}
	@property
	const
	override bool canHasFireRound() {return _ceto.canHasFireRound;}
	@property
	const
	override bool canHasFireKeyCode() {return _ceto.canHasFireKeyCode;}
	@property
	override size_t[] areaPath() {return _ceto.areaPath;}
	EventTree etFromPath(size_t[] path) { mixin(S_TRACE);
		if (path[0] == 0) { mixin(S_TRACE);
			return trees[path[1]];
		}
		assert (0);
	}
	@property
	const
	override bool isEmpty() {return _ceto.isEmpty;}

	override void add(EventTree evt) {return _ceto.add(evt);}
	override void insert(size_t index, EventTree evt) {return _ceto.insert(index, evt);}
	override void removeEvent(size_t index) {return _ceto.removeEvent(index);}
	override void remove(EventTree et) {return _ceto.remove(et);}
	override void swapEventTree(size_t index1, size_t index2) {return _ceto.swapEventTree(index1, index2);}

	/// 指定されたXMLノードに効果カード関連の情報を追加する。
	const
	protected XNode setEffProp(ref XNode node, XMLOption opt, in OverData od = null) { mixin(S_TRACE);
		if (0 != linkId && (!opt || !opt.includeCard)) { mixin(S_TRACE);
			auto pNode = node.newElement("Property");
			pNode.newElement("Id", od && od.id != 0UL ? od.id : id);
			pNode.newElement("LinkId", od && od.linkId != 0UL ? od.linkId : linkId);
			return pNode;
		} else { mixin(S_TRACE);
			auto pNode = setProp(node, opt, od);
			pNode.newElement("LinkId", od && od.linkId != 0UL ? od.linkId : linkId);
			pNode.newElement("Scenario", scenario);
			pNode.newElement("Author", author);
			auto a = pNode.newElement("Ability");
			a.newAttr("physical", fromPhysical(physical));
			a.newAttr("mental", fromMental(mental));
			pNode.newElement("Target", fromCardTarget(target)).newAttr("allrange", fromBool(allRange));
			pNode.newElement("EffectType", fromEffectType(effectType)).newAttr("spell", fromBool(spell));
			pNode.newElement("ResistType", fromResist(resist));
			pNode.newElement("SuccessRate", successRate);
			pNode.newElement("VisualEffect", fromCardVisual(visual));
			auto enh = pNode.newElement("Enhance");
			enh.newAttr("avoid", enhance(Enhance.AVOID));
			enh.newAttr("resist", enhance(Enhance.RESIST));
			enh.newAttr("defense", enhance(Enhance.DEFENSE));
			auto se1 = pNode.newElement("SoundPath", encodePath(soundPath1));
			if (volume1 != 100) se1.newAttr("volume", volume1);
			if (loopCount1 != 1) se1.newAttr("loopcount", loopCount1);
			auto se2 = pNode.newElement("SoundPath2", encodePath(soundPath2));
			if (volume2 != 100) se2.newAttr("volume", volume2);
			if (loopCount2 != 1) se2.newAttr("loopcount", loopCount2);
			pNode.newElement("KeyCodes", encodeLf(keyCodes, false));
			pNode.newElement("Premium", fromPremium(premium));
			auto mNode = node.newElement("Motions");
			foreach (m; _muser.motions) { mixin(S_TRACE);
				m.toNode(mNode, opt);
			}
			_ceto.appendEventsToNode(node, opt);
			return pNode;
		}
	}
	/// 指定されたXMLノードから効果カード関連のデータを読み出す。
	protected void loadEffProp(ref XNode pNode, in XMLInfo ver) { mixin(S_TRACE);
		assert (pNode.name == "Property");
		pNode.onTag["LinkId"] = (ref XNode n) {linkId = .to!ulong(n.value);};
		pNode.onTag["Scenario"] = (ref XNode n) {_scenario = n.value;};
		pNode.onTag["Author"] = (ref XNode n) {_author = n.value;};
		pNode.onTag["Ability"] = (ref XNode n) { mixin(S_TRACE);
			_phy = toPhysical(n.attr("physical", true));
			_mtl = toMental(n.attr("mental", true));
		};
		pNode.onTag["Target"] = (ref XNode n) { mixin(S_TRACE);
			_targ = toCardTarget(n.value);
			_allRange = parseBool(n.attr("allrange", true));
		};
		pNode.onTag["EffectType"] = (ref XNode n) { mixin(S_TRACE);
			_effTyp = toEffectType(n.value);
			_spell = parseBool(n.attr("spell", true));
		};
		pNode.onTag["ResistType"] = (ref XNode n) {_res = toResist(n.value);};
		pNode.onTag["SuccessRate"] = (ref XNode n) {_suc = n.valueTo!(int);};
		pNode.onTag["VisualEffect"] = (ref XNode n) {_vis = toCardVisual(n.value);};
		pNode.onTag["Enhance"] = (ref XNode n) { mixin(S_TRACE);
			_enh[Enhance.AVOID] = n.attr!(int)("avoid", true);
			_enh[Enhance.RESIST] = n.attr!(int)("resist", true);
			_enh[Enhance.DEFENSE] = n.attr!(int)("defense", true);
		};
		pNode.onTag["SoundPath"] = (ref XNode n) { mixin(S_TRACE);
			_se1.path = decodePath(n.value);
			_volume1 = n.attr!uint("volume", false, 100);
			_loopCount1 = n.attr!uint("loopcount", false, 1);
		};
		pNode.onTag["SoundPath2"] = (ref XNode n) { mixin(S_TRACE);
			_se2.path = decodePath(n.value);
			_volume2 = n.attr!uint("volume", false, 100);
			_loopCount2 = n.attr!uint("loopcount", false, 1);
		};
		pNode.onTag["KeyCodes"] = (ref XNode n) {keyCodes = decodeLf(n.value, true);};
		pNode.onTag["Premium"] = (ref XNode n) {_premi = toPremium(n.value);};
		loadProp(pNode, ver);
	}
	/// ditto
	protected void loadEffV(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		node.onTag["Motions"] = (ref XNode n) { mixin(S_TRACE);
			Motion[] motions;
			n.onTag["Motion"] = (ref XNode n) { mixin(S_TRACE);
				motions ~= Motion.createFromNode(n, ver);
			};
			n.parse();
			_muser.motions = motions;
		};
		node.onTag["Events"] = (ref XNode n) { mixin(S_TRACE);
			_ceto.addAll(AbstractEventTreeOwner.loadEventsFromNode(n, ver));
		};
		node.parse();
	}
	CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		switch (cate) {
		case "event": { mixin(S_TRACE);
			return _ceto.findCWXPath(path);
		}
		case "motion": { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= motions.length) return null;
			return motions[index].findCWXPath(cpbottom(path));
		}
		default: break;
		}
		return null;
	}
	@property
	inout
	inout(CWXPath)[] cwxChilds() { mixin(S_TRACE);
		if (linkId) return [];
		inout(CWXPath)[] r;
		foreach (a; motions) r ~= a;
		r ~= _ceto.cwxChilds;
		return r;
	}
}

/// スキルカード。
class SkillCard : EffectCard, ISkillUser {
private:
	SkillUser _linkId;
	uint _level = 0;
	bool _hold = false;
	int _useLimit = 0;
public:
	/// スキルカードのXML要素名。
	static const string XML_NAME = "SkillCard";
	/// スキルカード群のXML要素名。
	static const string XML_NAME_M = "SkillCards";
	static alias toSkillId toID;
	/// 唯一のコンストラクタ。
	/// Params:
	/// id = カードID。
	/// name = 名前。
	/// imagePaths = 画像のパス。
	/// desc = 解説。
	this (ulong id, string name, in CardImage[] imagePaths, string desc) { mixin(S_TRACE);
		super(id, name, imagePaths, desc);
		_linkId = new SkillUser(this);
	}
	/// cからパラメータをコピーする。
	void shallowCopy(in SkillCard c) { mixin(S_TRACE);
		shallowCopyEffectCard(c);
		level = c.level;
		hold = c.hold;
		useLimit = c.useLimit;
	}
	/// ditto
	void deepCopy(in SkillCard c) { mixin(S_TRACE);
		deepCopyEffectCard(c);
		level = c.level;
		hold = c.hold;
		useLimit = c.useLimit;
	}
	/// IDを除く内部データをクリアする。
	override void clearData() { mixin(S_TRACE);
		super.clearData();
		level = 0;
		hold = false;
		useLimit = 0;
	}

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto c = cast(const SkillCard) o;
		if (!c) return false;
		if (0 != linkId) return linkId == c.linkId && hold == c.hold;
		return eqImpl(c) && super.opEquals(o);
	}
	/// ID以外を比較する。
	const
	bool equalsExcludeId(const(SkillCard) c) { mixin(S_TRACE);
		if (!c) return false;
		if (0 != linkId) return linkId == c.linkId && hold == c.hold;
		return eqImpl(c) && super.equalsExcludeIdEffect(c);
	}
	const
	private bool eqImpl(const(SkillCard) c) { mixin(S_TRACE);
		return level == c.level
			&& hold == c.hold
			&& useLimit == c.useLimit;
	}

	/// 持ち札である時のリンク先ID。0の場合は実体を持つ。
	@property
	const
	override ulong linkId() {return _linkId.skill;}
	/// ditto
	@property
	override void linkId(ulong linkId) { mixin(S_TRACE);
		if (_linkId.skill != linkId) changed();
		_linkId.skill = linkId;
	}
	protected override void setUseCounterImpl(UseCounter uc) { mixin(S_TRACE);
		_linkId.setUseCounter(uc);
	}
	protected override void removeUseCounterImpl() { mixin(S_TRACE);
		_linkId.removeUseCounter();
	}

	/// レベル。
	@property
	const
	uint level() {return _level;}
	/// ditto
	@property
	void level(uint level) { mixin(S_TRACE);
		if (_level != level) changed();
		_level = level;
	}

	/// 残り使用回数。
	@property
	const
	uint useLimit() {return _useLimit;}
	/// ditto
	@property
	void useLimit(uint useLimit) { mixin(S_TRACE);
		if (_useLimit != useLimit) changed();
		_useLimit = useLimit;
	}

	/// ホールド状態か。
	@property
	const
	bool hold() {return _hold;}
	/// ditto
	@property
	void hold(bool hold) { mixin(S_TRACE);
		if (_hold != hold) changed();
		_hold = hold;
	}

	override bool change(SkillId id) { return true; }

	/// XMLテキストに変換する。
	const
	string toXML(XMLOption opt) { mixin(S_TRACE);
		return toNode(opt).text;
	}
	/// コピーを生成する。
	@property
	const
	override
	SkillCard dup() { mixin(S_TRACE);
		auto copy = new SkillCard(0UL, "", [], "");
		copy.deepCopy(this);
		return copy;
	}
	/// XMLノードに変換する。
	const
	XNode toNode(XMLOption opt) { mixin(S_TRACE);
		auto n = XNode.create(XML_NAME);
		n.newAttr("dataVersion", opt.dataVersion);
		toNodeImpl(n, opt, null);
		return n;
	}
	/// 自身をXMLノードにして指定されたノードに追加する。
	const
	override
	XNode toNode(ref XNode parent, XMLOption opt) { return toNode(parent, opt, null); }
	/// ditto
	const
	XNode toNode(ref XNode parent, XMLOption opt, in OverData od) { mixin(S_TRACE);
		auto cNode = parent.newElement(XML_NAME);
		cNode.newAttr("dataVersion", opt.dataVersion);
		toNodeImpl(cNode, opt, od);
		return cNode;
	}
	const
	private void toNodeImpl(ref XNode cNode, XMLOption opt, in OverData od = null) { mixin(S_TRACE);
		if (0 != linkId && opt && opt.includeCard) { mixin(S_TRACE);
			auto od2 = new OverData;
			od2.id = id;
			if (!opt.noLinkId) od2.linkId = linkId;
			od2.overHold = true;
			od2.hold = hold;
			auto c2 = .rebindable(opt.skill(linkId));
			if (!c2) c2 = new SkillCard(id, "", [], "");
			c2.toNodeImpl(cNode, opt, od2);
			return;
		}
		auto pNode = setEffProp(cNode, opt, od);
		if (0 == linkId || (opt && opt.includeCard)) { mixin(S_TRACE);
			pNode.newElement("Level", level);
			pNode.newElement("UseLimit", useLimit);
		}
		pNode.newElement("Hold", fromBool(od && od.overHold ? od.hold : hold));
	}

	/// XMLノードからインスタンスを生成する。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static SkillCard createFromNode(ref XNode cNode, in XMLInfo ver) { mixin(S_TRACE);
		if (cNode.name != XML_NAME) throw new CardException("Node is not skill card: " ~ cNode.name);
		auto r = new SkillCard(0, "", [], "");
		ulong id = 0UL, linkId = 0UL;
		bool hold = false;
		id = readLinkInfo(cNode, linkId, hold);
		if (0 != linkId) { mixin(S_TRACE);
			r.id = id;
			r.linkId = linkId;
			r.hold = hold;
			return r;
		}
		cNode.onTag["Property"] = (ref XNode pNode) { mixin(S_TRACE);
			pNode.onTag["Level"] = (ref XNode n) {r._level = n.valueTo!(int);};
			pNode.onTag["UseLimit"] = (ref XNode n) {r._useLimit = n.valueTo!(int);};
			pNode.onTag["Hold"] = (ref XNode n) {r._hold = parseBool(n.value);};
			r.loadEffProp(pNode, ver);
		};
		r.loadEffV(cNode, ver);
		return r;
	}

	private SkillOwner _owner = null;
	@property
	package void owner(SkillOwner owner) {_owner = owner;}
	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		if (id) { mixin(S_TRACE);
			return _owner ? cpjoinid(_owner, "skillcard", this.id) : "";
		} else { mixin(S_TRACE);
			return _owner ? cpjoin(_owner, "skillcard", .cCountUntil!("a is b")(_owner.skills, this), id) : "";
		}
	}
	@property
	CWXPath cwxParent() {return _owner;}

	override
	CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		if (linkId) { mixin(S_TRACE);
			auto summ = cast(SkillOwner).cwxTop(this);
			return summ ? summ.skill(linkId).findCWXPath(path) : null;
		}
		return super.findCWXPath(path);
	}
}

/// アイテムカード。
class ItemCard : EffectCard, IItemUser {
private:
	ItemUser _linkId;
	int[Enhance] _oEnh;
	uint _price = 0;
	uint _useLimit = 0;
	uint _useLimitMax = 0;
	bool _hold = false;
public:
	/// アイテムカードのXML要素名。
	static const string XML_NAME = "ItemCard";
	/// アイテムカード群のXML要素名。
	static const string XML_NAME_M = "ItemCards";
	static alias toItemId toID;
	/// 唯一のコンストラクタ。
	/// Params:
	/// id = カードID。
	/// name = 名前。
	/// imagePaths = 画像のパス。
	/// desc = 解説。
	this (ulong id, string name, in CardImage[] imagePaths, string desc) { mixin(S_TRACE);
		super(id, name, imagePaths, desc);
		_linkId = new ItemUser(this);
		_oEnh = [Enhance.AVOID:0, Enhance.RESIST:0, Enhance.DEFENSE:0];
	}
	private void copyImpl(in ItemCard c) { mixin(S_TRACE);
		enhanceOwner(Enhance.AVOID, c.enhanceOwner(Enhance.AVOID));
		enhanceOwner(Enhance.RESIST, c.enhanceOwner(Enhance.RESIST));
		enhanceOwner(Enhance.DEFENSE, c.enhanceOwner(Enhance.DEFENSE));
		price = c.price;
		useLimit = c.useLimit;
		useLimitMax = c.useLimitMax;
		hold = c.hold;
	}
	/// cからパラメータをコピーする。
	void shallowCopy(in ItemCard c) { mixin(S_TRACE);
		shallowCopyEffectCard(c);
		copyImpl(c);
	}
	/// ditto
	void deepCopy(in ItemCard c) { mixin(S_TRACE);
		deepCopyEffectCard(c);
		copyImpl(c);
	}
	/// IDを除く内部データをクリアする。
	override void clearData() { mixin(S_TRACE);
		super.clearData();
		enhanceOwner(Enhance.AVOID, 0);
		enhanceOwner(Enhance.RESIST, 0);
		enhanceOwner(Enhance.DEFENSE, 0);
		price = 0;
		useLimit = 0;
		useLimitMax = 0;
		hold = false;
	}

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto c = cast(const ItemCard) o;
		if (!c) return false;
		if (0 != linkId) return linkId == c.linkId && hold == c.hold;
		return eqImpl(c) && super.opEquals(o);
	}
	/// ID以外を比較する。
	const
	bool equalsExcludeId(const(ItemCard) c) { mixin(S_TRACE);
		if (!c) return false;
		if (0 != linkId) return linkId == c.linkId && hold == c.hold;
		return eqImpl(c) && super.equalsExcludeIdEffect(c);
	}
	const
	private bool eqImpl(const(ItemCard) c) { mixin(S_TRACE);
		return enhanceOwner(Enhance.AVOID) == c.enhanceOwner(Enhance.AVOID)
			&& enhanceOwner(Enhance.RESIST) == c.enhanceOwner(Enhance.RESIST)
			&& enhanceOwner(Enhance.DEFENSE) == c.enhanceOwner(Enhance.DEFENSE)
			&& price == c.price
			&& useLimit == c.useLimit
			&& useLimitMax == c.useLimitMax
			&& hold == c.hold;
	}

	/// 持ち札である時のリンク先ID。0の場合は実体を持つ。
	@property
	const
	override ulong linkId() {return _linkId.item;}
	/// ditto
	@property
	override void linkId(ulong linkId) { mixin(S_TRACE);
		if (_linkId.item != linkId) changed();
		_linkId.item = linkId;
	}
	protected override void setUseCounterImpl(UseCounter uc) { mixin(S_TRACE);
		_linkId.setUseCounter(uc);
	}
	protected override void removeUseCounterImpl() { mixin(S_TRACE);
		_linkId.removeUseCounter();
	}

	/// 使用回数。0で無制限。
	@property
	const
	uint useLimit() {return _useLimit;}
	/// ditto
	@property
	void useLimit(uint useLimit) { mixin(S_TRACE);
		if (_useLimit != useLimit) changed();
		_useLimit = useLimit;
	}

	/// 最大使用回数。0で無制限。
	@property
	const
	uint useLimitMax() {return _useLimitMax;}
	/// ditto
	@property
	void useLimitMax(uint useLimitMax) { mixin(S_TRACE);
		if (_useLimitMax != useLimitMax) changed();
		_useLimitMax = useLimitMax;
	}

	/// 値段。
	@property
	const
	uint price() {return _price;}
	/// ditto
	@property
	void price(uint price) { mixin(S_TRACE);
		if (_price != price) changed();
		_price = price;
	}

	/// 所持者の能力値ボーナス。
	const
	int enhanceOwner(Enhance enh) {return _oEnh[enh];}
	/// ditto
	void enhanceOwner(Enhance enh, int val) { mixin(S_TRACE);
		if (_oEnh[enh] != val) changed();
		_oEnh[enh] = val;
	}

	/// ホールド状態か。
	@property
	const
	bool hold() {return _hold;}
	/// ditto
	@property
	void hold(bool hold) { mixin(S_TRACE);
		if (_hold != hold) changed();
		_hold = hold;
	}

	override bool change(ItemId id) { return true; }

	/// XMLテキストに変換する。
	const
	string toXML(XMLOption opt) { mixin(S_TRACE);
		return toNode(opt).text;
	}
	/// コピーを生成する。
	@property
	const
	override
	ItemCard dup() { mixin(S_TRACE);
		auto copy = new ItemCard(0UL, "", [], "");
		copy.deepCopy(this);
		return copy;
	}
	/// XMLノードに変換する。
	const
	XNode toNode(XMLOption opt) { mixin(S_TRACE);
		auto n = XNode.create(XML_NAME);
		n.newAttr("dataVersion", opt.dataVersion);
		toNodeImpl(n, opt, null);
		return n;
	}
	/// 自身をXMLノードにして指定されたノードに追加する。
	const
	override
	XNode toNode(ref XNode parent, XMLOption opt) { return toNode(parent, opt, null); }
	/// ditto
	const
	XNode toNode(ref XNode parent, XMLOption opt, in OverData od = null) { mixin(S_TRACE);
		auto cNode = parent.newElement(XML_NAME);
		cNode.newAttr("dataVersion", opt.dataVersion);
		toNodeImpl(cNode, opt, od);
		return cNode;
	}
	const
	private void toNodeImpl(ref XNode cNode, XMLOption opt, in OverData od) { mixin(S_TRACE);
		if (0 != linkId && opt && opt.includeCard) { mixin(S_TRACE);
			auto od2 = new OverData;
			od2.id = id;
			if (!opt.noLinkId) od2.linkId = linkId;
			od2.overHold = true;
			od2.hold = hold;
			auto c2 = .rebindable(opt.item(linkId));
			if (!c2) c2 = new ItemCard(id, "", [], "");
			c2.toNodeImpl(cNode, opt, od2);
			return;
		}
		auto pNode = setEffProp(cNode, opt, od);
		if (0 == linkId || (opt && opt.includeCard)) { mixin(S_TRACE);
			pNode.newElement("UseLimit", useLimit).newAttr("max", useLimitMax);
			pNode.newElement("Price", price);
			auto eo = pNode.newElement("EnhanceOwner");
			eo.newAttr("avoid", enhanceOwner(Enhance.AVOID));
			eo.newAttr("resist", enhanceOwner(Enhance.RESIST));
			eo.newAttr("defense", enhanceOwner(Enhance.DEFENSE));
		}
		pNode.newElement("Hold", fromBool(od && od.overHold ? od.hold : hold));
	}

	/// XMLノードからインスタンスを生成する。
	/// Params:
	/// cNode = XMLノード。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static ItemCard createFromNode(ref XNode cNode, in XMLInfo ver) { mixin(S_TRACE);
		if (cNode.name != XML_NAME) throw new CardException("Node is not item card: " ~ cNode.name);
		auto r = new ItemCard(0, "", [], "");
		ulong id = 0UL, linkId = 0UL;
		bool hold = false;
		id = readLinkInfo(cNode, linkId, hold);
		if (0 != linkId) { mixin(S_TRACE);
			r.id = id;
			r.linkId = linkId;
			r.hold = hold;
			return r;
		}
		cNode.onTag["Property"] = (ref XNode pNode) { mixin(S_TRACE);
			pNode.onTag["UseLimit"] = (ref XNode n) { mixin(S_TRACE);
				r._useLimit = n.valueTo!(int);
				r._useLimitMax = n.attr!(int)("max", true);
			};
			pNode.onTag["Price"] = (ref XNode n) {r._price = n.valueTo!(int);};
			pNode.onTag["EnhanceOwner"] = (ref XNode n) { mixin(S_TRACE);
				r._oEnh[Enhance.AVOID] = n.attr!(int)("avoid", true);
				r._oEnh[Enhance.RESIST] = n.attr!(int)("resist", true);
				r._oEnh[Enhance.DEFENSE] = n.attr!(int)("defense", true);
			};
			pNode.onTag["Hold"] = (ref XNode n) {r._hold = parseBool(n.value);};
			r.loadEffProp(pNode, ver);
		};
		r.loadEffV(cNode, ver);
		return r;
	}

	private ItemOwner _owner = null;
	@property
	package void owner(ItemOwner owner) {_owner = owner;}
	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		if (id) { mixin(S_TRACE);
			return _owner ? cpjoinid(_owner, "itemcard", this.id) : "";
		} else { mixin(S_TRACE);
			return _owner ? cpjoin(_owner, "itemcard", .cCountUntil!("a is b")(_owner.items, this), id) : "";
		}
	}
	@property
	CWXPath cwxParent() {return _owner;}

	override
	CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		if (linkId) { mixin(S_TRACE);
			auto summ = cast(ItemOwner).cwxTop(this);
			return summ ? summ.item(linkId).findCWXPath(path) : null;
		}
		return super.findCWXPath(path);
	}
}

/// 召喚獣カード。
class BeastCard : EffectCard, IBeastUser {
private:
	BeastUser _linkId;
	uint _useLimit = 0;
public:
	/// 召喚獣カードのXML要素名。
	static const string XML_NAME = "BeastCard";
	/// 召喚獣カード群のXML要素名。
	static const string XML_NAME_M = "BeastCards";
	static alias toBeastId toID;
	/// 唯一のコンストラクタ。
	/// Params:
	/// id = カードID。
	/// name = 名前。
	/// imagePaths = 画像のパス。
	/// desc = 解説。
	this (ulong id, string name, in CardImage[] imagePaths, string desc) { mixin(S_TRACE);
		super(id, name, imagePaths, desc);
		_linkId = new BeastUser(this);
	}
	/// cからパラメータをコピーする。
	void shallowCopy(in BeastCard c) { mixin(S_TRACE);
		shallowCopyEffectCard(c);
		copyImpl(c);
	}
	/// ditto
	void deepCopy(in BeastCard c) { mixin(S_TRACE);
		deepCopyEffectCard(c);
		copyImpl(c);
	}
	private void copyImpl(in BeastCard c) {
		useLimit = c.useLimit;
	}
	/// IDを除く内部データをクリアする。
	override void clearData() { mixin(S_TRACE);
		super.clearData();
		useLimit = 0;
	}

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto c = cast(const BeastCard) o;
		if (!c) return false;
		if (0 != linkId) return linkId == c.linkId;
		return eqImpl(c) && super.opEquals(o);
	}
	/// ID以外を比較する。
	const
	bool equalsExcludeId(const(BeastCard) c) { mixin(S_TRACE);
		if (!c) return false;
		if (0 != linkId) return linkId == c.linkId;
		return eqImpl(c) && super.equalsExcludeIdEffect(c);
	}
	const
	private bool eqImpl(const(BeastCard) c) { mixin(S_TRACE);
		return useLimit == c.useLimit;
	}

	/// 持ち札である時のリンク先ID。0の場合は実体を持つ。
	@property
	const
	override ulong linkId() {return _linkId.beast;}
	/// ditto
	@property
	override void linkId(ulong linkId) { mixin(S_TRACE);
		if (_linkId.beast != linkId) changed();
		_linkId.beast = linkId;
	}
	protected override void setUseCounterImpl(UseCounter uc) { mixin(S_TRACE);
		_linkId.setUseCounter(uc);
	}
	protected override void removeUseCounterImpl() { mixin(S_TRACE);
		_linkId.removeUseCounter();
	}

	/// 使用回数。0で無制限。
	@property
	const
	uint useLimit() {return _useLimit;}
	/// ditto
	@property
	void useLimit(uint useLimit) { mixin(S_TRACE);
		if (_useLimit != useLimit) changed();
		_useLimit = useLimit;
	}

	/// 付帯能力か。
	/// 最初からキャストカードが所有している召喚獣カード、
	/// もしくは召喚獣カード取得コンテントで取得したカードは
	/// 付帯能力となる。召喚獣召喚効果で取得したカードは
	/// 一般の召喚獣となる。
	/// エディタ上では、イベントの処理結果という概念が無いため、
	/// キャストカードが所有している場合に限り付帯能力として扱う。
	@property
	const
	bool isOption() { mixin(S_TRACE);
		return cast(CastCard)_owner !is null && !useLimit;
	}

	override bool change(BeastId id) { return true; }

	/// XMLテキストに変換する。
	const
	string toXML(XMLOption opt) { mixin(S_TRACE);
		return toNode(opt).text;
	}
	/// XMLノードに変換する。
	const
	XNode toNode(XMLOption opt) { mixin(S_TRACE);
		auto n = XNode.create(XML_NAME);
		n.newAttr("dataVersion", opt.dataVersion);
		toNodeImpl(n, opt, null);
		return n;
	}
	/// 自身をXMLノードにして指定されたノードに追加する。
	const
	override
	XNode toNode(ref XNode parent, XMLOption opt) { return toNode(parent, opt, null); }
	/// ditto
	const
	XNode toNode(ref XNode parent, XMLOption opt, in OverData od = null) { mixin(S_TRACE);
		auto cNode = parent.newElement(XML_NAME);
		cNode.newAttr("dataVersion", opt.dataVersion);
		toNodeImpl(cNode, opt, od);
		return cNode;
	}
	const
	private void toNodeImpl(ref XNode cNode, XMLOption opt, in OverData od) { mixin(S_TRACE);
		assert (cNode.name == XML_NAME);
		if (0 != linkId && opt && opt.includeCard) { mixin(S_TRACE);
			auto od2 = new OverData;
			od2.id = id;
			if (!opt.noLinkId) od2.linkId = linkId;
			auto c2 = .rebindable(opt.beast(linkId));
			if (!c2) c2 = new BeastCard(id, "", [], "");
			c2.toNodeImpl(cNode, opt, od2);
			return;
		}
		auto pNode = setEffProp(cNode, opt, od);
		if (0 == linkId || (opt && opt.includeCard)) { mixin(S_TRACE);
			pNode.newElement("UseLimit", useLimit);
		}
	}
	/// コピーを生成する。
	@property
	const
	override
	BeastCard dup() { mixin(S_TRACE);
		auto copy = new BeastCard(0UL, "", [], "");
		copy.deepCopy(this);
		return copy;
	}
	/// XMLテキストに変換する。
	const
	string toXML(XMLOption opt, in OverData od = null) { mixin(S_TRACE);
		auto n = XNode.create(XML_NAME);
		n.newAttr("dataVersion", opt.dataVersion);
		toNodeImpl(n, opt, od);
		return n.text;
	}
	/// XMLノードからインスタンスを生成する。
	/// Params:
	/// cNode = XMLノード。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static BeastCard createFromNode(ref XNode cNode, in XMLInfo ver) { mixin(S_TRACE);
		if (cNode.name != XML_NAME) throw new CardException("Node is not beast card: " ~ cNode.name);
		auto r = new BeastCard(0, "", [], "");
		ulong id = 0UL, linkId = 0UL;
		bool hold = false;
		id = readLinkInfo(cNode, linkId, hold);
		if (0 != linkId) { mixin(S_TRACE);
			r.id = id;
			r.linkId = linkId;
			return r;
		}
		cNode.onTag["Property"] = (ref XNode pNode) { mixin(S_TRACE);
			pNode.onTag["UseLimit"] = (ref XNode n) { r._useLimit = n.valueTo!int; };
			r.loadEffProp(pNode, ver);
		};
		r.loadEffV(cNode, ver);
		return r;
	}

	private BeastOwner _owner = null;
	@property
	package void owner(BeastOwner owner) {_owner = owner;}
	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		if (id) { mixin(S_TRACE);
			return _owner ? cpjoinid(_owner, "beastcard", this.id) : "";
		} else { mixin(S_TRACE);
			return _owner ? cpjoin(_owner, "beastcard", .cCountUntil!("a is b")(_owner.beasts, this), id) : "";
		}
	}
	@property
	CWXPath cwxParent() {return _owner;}

	override
	CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		if (linkId) { mixin(S_TRACE);
			auto summ = cast(BeastOwner).cwxTop(this);
			return summ ? summ.beast(linkId).findCWXPath(path) : null;
		}
		return super.findCWXPath(path);
	}
}

/// 情報カード。
class InfoCard : Card {
public:
	/// 情報カードのXML要素名。
	static const string XML_NAME = "InfoCard";
	/// 情報カード群のXML要素名。
	static const string XML_NAME_M = "InfoCards";
	static alias toInfoId toID;
	/// 唯一のコンストラクタ。
	/// Params:
	/// id = カードID。
	/// name = 名前。
	/// imagePaths = 画像のパス。
	/// desc = 解説。
	this (ulong id, string name, in CardImage[] imagePaths, string desc) { mixin(S_TRACE);
		super(id, name, imagePaths, desc);
	}
	/// cからパラメータをコピーする。
	void shallowCopy(in InfoCard c) { mixin(S_TRACE);
		shallowCopyCard(c);
	}
	/// ditto
	alias shallowCopy deepCopy;

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto c = cast(const InfoCard) o;
		if (!c) return false;
		return super.opEquals(o);
	}
	/// ID以外を比較する。
	const
	bool equalsExcludeId(const(InfoCard) c) { mixin(S_TRACE);
		if (!c) return false;
		return super.equalsExcludeIdCard(c);
	}

	/// ディープコピーを作成する。
	@property
	const
	override
	InfoCard dup() { mixin(S_TRACE);
		auto copy = new InfoCard(0UL, "", [], "");
		copy.deepCopy(this);
		return copy;
	}

	/// XMLテキストに変換する。
	const
	string toXML(XMLOption opt) { mixin(S_TRACE);
		return toNode(opt).text;
	}
	/// XMLノードに変換する。
	const
	XNode toNode(XMLOption opt) { mixin(S_TRACE);
		auto n = XNode.create(XML_NAME);
		n.newAttr("dataVersion", opt.dataVersion);
		toNodeImpl(n, opt);
		return n;
	}
	/// 自身をXMLノードにして指定されたノードに追加する。
	const
	override
	XNode toNode(ref XNode parent, XMLOption opt) { mixin(S_TRACE);
		auto cNode = parent.newElement(XML_NAME);
		cNode.newAttr("dataVersion", opt.dataVersion);
		toNodeImpl(cNode, opt);
		return cNode;
	}
	const
	private void toNodeImpl(ref XNode cNode, XMLOption opt) { mixin(S_TRACE);
		setProp(cNode, opt);
	}
	/// XMLノードからインスタンスを生成する。
	/// Params:
	/// cNode = XMLノード。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static InfoCard createFromNode(ref XNode cNode, in XMLInfo ver) { mixin(S_TRACE);
		if (cNode.name != XML_NAME) throw new CardException("Node is not info card: " ~ cNode.name);
		auto r = new InfoCard(0, "", [], "");
		cNode.onTag["Property"] = (ref XNode node) { mixin(S_TRACE);
			r.loadProp(node, ver);
		};
		cNode.parse();
		return r;
	}

	private InfoOwner _owner = null;
	@property
	package void owner(InfoOwner owner) {_owner = owner;}
	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		if (id) { mixin(S_TRACE);
			return _owner ? cpjoinid(_owner, "infocard", this.id) : "";
		} else { mixin(S_TRACE);
			return _owner ? cpjoin(_owner, "infocard", .cCountUntil!("a is b")(_owner.infos, this), id) : "";
		}
	}
	CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		return null;
	}
	@property
	inout
	inout(CWXPath)[] cwxChilds() {return [];}
	@property
	CWXPath cwxParent() {return _owner;}
}

/// キーコード群のXML要素名。
immutable KEY_CODES_XML_NAME = "KeyCodes";

/// KeyCodes要素からキーコード群を取得する。
string[] keyCodesFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
	if (!node.valid) return [];
	if (node.name != KEY_CODES_XML_NAME) return [];
	return decodeLf(node.value, true);
}
/// キーコード群をXML要素化し、nodeに追加する。
void keyCodesToNode(ref XNode node, in string[] keyCodes) { mixin(S_TRACE);
	node.newElement(KEY_CODES_XML_NAME, encodeLf(keyCodes));
}
/// キーコード群をXML要素化する。
XNode keyCodesToNode(in string[] keyCodes) { mixin(S_TRACE);
	return XNode.create(KEY_CODES_XML_NAME, encodeLf(keyCodes));
}
/// キーコード群をXML文書化する。
string keyCodesToXML(in string[] keyCodes) { mixin(S_TRACE);
	auto node = keyCodesToNode(keyCodes);
	return node.text;
}
