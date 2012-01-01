
module cwx.card;

import cwx.coupon;
import cwx.event;
import cwx.motion;
import cwx.flag;
import cwx.utils;
import cwx.usecounter;
import cwx.types;
import cwx.race;
import cwx.xml;
import cwx.utils;
import cwx.path;

import std.algorithm;
import std.exception;

public:

/// カードの所持者である事を示すインタフェース。
interface CastOwner : CWXPath {
	@property
	CastCard[] casts();
}
interface SkillOwner : CWXPath {
	@property
	SkillCard[] skills();
}
interface ItemOwner : CWXPath {
	@property
	ItemCard[] items();
}
interface BeastOwner : CWXPath {
	@property
	BeastCard[] beasts();
}
interface InfoOwner : CWXPath {
	@property
	InfoCard[] infos();
}

/// カード絡みの例外。
class CardException : Exception {
public:
	this (string msg) {
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
	PathUser _path;
public:
	/// 唯一のコンストラクタ。
	/// Params:
	/// id = カードID。
	/// name = 名前。
	/// imagePath = 画像のパス。
	/// desc = 解説。
	this (ulong id, string name, string imagePath, string desc) {
		_id = id;
		_name = name;
		_desc = desc;
		_path = new PathUser(this);
		_path.path = imagePath;
	}
	/// cからパラメータをコピーする。
	protected void shallowCopyCard(Card c) {
		id = c.id;
		name = c.name;
		desc = c.desc;
		path = c.path;
	}
	/// 変更ハンドラを登録する。
	@property
	void changeHandler(void delegate() change) {
		_change = change;
	}
	/// 変更ハンドラを返す。
	@property
	protected void delegate() changeHandler() {
		return _change;
	}
	/// 変更を通知する。
	protected void changed() {
		if (_change) _change();
	}
	/// 使用回数カウンタ。
	@property
	UseCounter useCounter() {
		return _path.useCounter;
	}
	/// 使用回数カウンタを登録する。
	@property
	void setUseCounter(UseCounter uc) {
		_path.setUseCounter(uc);
	}
	/// 使用回数カウンタを取り除く。
	void removeUseCounter() {
		_path.removeUseCounter();
	}
	/// 画像パスの変更を通知する。
	void change(PathId id) {
		_path.change(id);
	}

	/// カードID。
	@property
	void id(ulong id) {
		if (_id != id) changed();
		_id = id;
	}
	/// ditto
	@property
	const
	ulong id() {
		return _id;
	}

	/// カード名。
	@property
	const
	string name() {
		return _name;
	}
	/// ditto
	@property
	void name(string name) {
		if (_name != name) changed();
		_name = name;
	}

	/// カード画像。
	@property
	const
	string path() {
		return _path.path;
	}
	/// ditto
	@property
	void path(string path) {
		if (_path.path != path) changed();
		_path.path = path;
	}

	/// 解説。
	@property
	const
	string desc() {
		return _desc;
	}
	/// ditto
	@property
	void desc(string desc) {
		if (_desc != desc) changed();
		_desc = desc;
	}

	/// nodeからID情報を抽出する。存在しない場合は0。
	static ulong readId(ref XNode node) {
		auto pNode = node.child("Property", false);
		if (!pNode.valid) return 0UL;
		string idStr = pNode.childText("Id", false);
		if (!idStr) return 0UL;
		return to!(ulong)(idStr);
	}

	/// 指定されたXMLノードにProperty情報を追加する。
	const
	protected XNode setProp(ref XNode node, ulong forceId = 0UL) {
		auto pNode = node.newElement("Property");
		pNode.newElement("Id", forceId == 0UL ? id : forceId);
		pNode.newElement("Name", name);
		pNode.newElement("ImagePath", encodePath(path));
		pNode.newElement("Description", encodeLf(desc));
		return pNode;
	}
	/// 指定されたXMLノードからProperty情報を読み出す。
	protected void loadProp(ref XNode pNode, string ver) {
		string idStr = null;
		pNode.onTag["Id"] = (ref XNode n) {idStr = n.value;};
		pNode.onTag["ImagePath"] = (ref XNode n) {_path.path = decodePath(n.value);};
		_name = null;
		pNode.onTag["Name"] = (ref XNode n) {_name = n.value;};
		pNode.onTag["Description"] = (ref XNode n) {_desc = decodeLf2(n.value);};
		pNode.parse();
		if (!idStr) throw new CardException("Id not found");
		if (!_name) _name = "";
		_id = to!(long)(idStr);
	}

	const
	override int opCmp(Object o) {
		return cast(int) _id - cast(int) (cast(Card) o)._id;
	}
}

/// キャストカード。
class CastCard : Card, SkillOwner, ItemOwner, BeastOwner {
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
	int _rEnh[Enhance];
	uint _rEnhRound[Enhance];
	Coupon[] _coupon;
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
	@property
	protected override void delegate() changeHandler() {return super.changeHandler;}
	@property
	override void changeHandler(void delegate() change) {
		foreach (c; _items) {
			c.changeHandler = change;
		}
		foreach (c; _skills) {
			c.changeHandler = change;
		}
		foreach (c; _beasts) {
			c.changeHandler = change;
		}
		super.changeHandler = change;
	}
	/// インスタンスを生成する。
	/// Params:
	/// id = カードID。
	/// name = 名前。
	/// imagePath = 画像のパス。
	/// desc = 解説。
	/// lev = レベル。
	/// lifeMax = ヒットポイント最大値。
	this (ulong id, string name, string imagePath, string desc, uint lev, uint lifeMax) {
		super(id, name, imagePath, desc);
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
	this (ulong id, string name, string imagePath, string desc) {
		this (id, name, imagePath, desc, 1, 1);
	}
	/// cからパラメータをコピーする。
	void shallowCopy(CastCard c) {
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
		enhance(Enhance.ACTION,  c.enhance(Enhance.ACTION));
		enhanceRound(Enhance.ACTION,  c.enhanceRound(Enhance.ACTION));
		enhance(Enhance.AVOID,  c.enhance(Enhance.AVOID));
		enhanceRound(Enhance.AVOID,  c.enhanceRound(Enhance.AVOID));
		enhance(Enhance.RESIST,  c.enhance(Enhance.RESIST));
		enhanceRound(Enhance.RESIST,  c.enhanceRound(Enhance.RESIST));
		enhance(Enhance.DEFENSE,  c.enhance(Enhance.DEFENSE));
		enhanceRound(Enhance.DEFENSE,  c.enhanceRound(Enhance.DEFENSE));
		Coupon[] cps;
		foreach (cp; c.coupons) {
			cps ~= new Coupon(cp);
		}
		coupons = cps;
	}
	/// 使用回数カウンタ。
	@property
	void setUseCounter(UseCounter uc) {
		foreach (c; _items) {
			c.setUseCounter = uc;
		}
		foreach (c; _skills) {
			c.setUseCounter = uc;
		}
		foreach (c; _beasts) {
			c.setUseCounter = uc;
		}
		super.setUseCounter = uc;
	}
	/// ditto
	@property
	UseCounter useCounter() {
		return super.useCounter;
	}
	/// ditto
	void removeUseCounter() {
		foreach (c; _items) {
			c.removeUseCounter();
		}
		foreach (c; _skills) {
			c.removeUseCounter();
		}
		foreach (c; _beasts) {
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
	void level(uint lev) {
		if (_lev != lev) changed();
		_lev = lev;
	}
	/// ヒットポイント。
	@property
	const
	uint life() {return _life;}
	/// ditto
			@property
	void life(uint life) {
		if (_life != life) changed();
		_life = life;
	}
	/// ヒットポイント最大値。
	@property
	const
	uint lifeMax() {return _lifeMax;}
	/// ditto
			@property
	void lifeMax(uint lifeMax) {
		if (_lifeMax != lifeMax) changed();
		_lifeMax = lifeMax;
	}
	// 適性値を返す。
	const
	int aptitude(Physical phy, Mental m) {
		return physical(phy) + mental(m);
	}

	/// 所持するクーポン。
	@property
	Coupon[] coupons() {return _coupon;}
	/// ditto
	@property
	void coupons(Coupon[] coupon) {
		if (_coupon != coupon) changed();
		_coupon = coupon;
	}

	private C __add(C)(ref C[] arr, C c) {
		if (contains!("a is b")(arr, c)) {
			remove(c);
		}
		scope doc = XNode.create(C.XML_NAME);
		c.toNodeImpl(doc);
		c = C.createFromNode(doc, LATEST_VERSION);
		if (arr.length > 0 && arr[$ - 1].id >= c.id) {
			c.id = arr[$ - 1].id + 1L;
		}
		if (useCounter) {
			c.setUseCounter = useCounter;
		}
		c.changeHandler = changeHandler;
		c.owner = this;
		arr ~= c;
		changed();
		return c;
	}
	private void __removeC(C)(ref C[] arr, C card) {
		foreach (i, c; arr) {
			if (c is card) {
				arr[i].removeUseCounter();
				arr[i].changeHandler = null;
				arr[i].owner = null;
				arr = arr[0 .. i] ~ arr[i + 1 .. $];
				changed();
			}
		}
	}
	private void __remove(C)(ref C[] arr, ulong id) {
		foreach (i, c; arr) {
			if (c.id == id) {
				arr[i].removeUseCounter();
				arr[i].changeHandler = null;
				arr[i].owner = null;
				arr = arr[0 .. i] ~ arr[i + 1 .. $];
				changed();
			}
		}
	}
	const
	private C __find(C)(C[] arr, ulong id) {
		foreach (c; arr) {
			if (c.id == id) {
				return c;
			}
		}
		return null;
	}
	private T __insert(T, alias ToID)(ref T[] arr, int index, T c) {
		if (arr.length == index) {
			return __add!(T)(arr, c);
		} else {
			int oldIdx = indexOf(c);
			if (oldIdx >= 0) {
				remove(c);
				if (oldIdx < index) index--;
			}
			c.id(index == 0 ? 1L : arr[index - 1].id() + 1L);
			arr = arr[0 .. index] ~ c ~ arr[index .. $];
			for (size_t i = index + 1; i < arr.length; i++) {
				if (arr[i - 1].id == arr[i].id) {
					ulong o = arr[i].id();
					arr[i].id = arr[i].id + 1L;
				}
			}
			c.setUseCounter = useCounter;
			c.changeHandler = changeHandler;
			c.owner = this;
			changeHandler;
			return c;
		}
	}

	/// 所持アイテム。
	@property
	ItemCard[] items() {return _items;}
	/// ditto
	ItemCard add(ItemCard card) {return __add(_items, card);}
	/// ditto
	void removeItem(ulong id) {__remove(_items, id);}
	/// ditto
	ItemCard item(ulong id) {
		return __find(_items, id);
	}
	/// ditto
	void remove(ItemCard c) {
		__removeC(_items, c);
	}
	/// ditto
	ItemCard insert(int index, ItemCard c) {
		return __insert!(ItemCard, toItemId)(_items, index, c);
	}
	/// 所持スキル。
	@property
	SkillCard[] skills() {return _skills;}
	/// ditto
	SkillCard add(SkillCard card) {return __add(_skills, card);}
	/// ditto
	void removeSkill(ulong id) {__remove(_skills, id);}
	/// ditto
	SkillCard skill(ulong id) {
		return __find(_skills, id);
	}
	/// ditto
	void remove(SkillCard c) {
		__removeC(_skills, c);
	}
	/// ditto
	SkillCard insert(int index, SkillCard c) {
		return __insert!(SkillCard, toSkillId)(_skills, index, c);
	}
	/// 所持召喚獣。
	@property
	BeastCard[] beasts() {return _beasts;}
	/// ditto
	BeastCard add(BeastCard card) {return __add(_beasts, card);}
	/// ditto
	void removeBeast(ulong id) {__remove(_beasts, id);}
	/// ditto
	BeastCard beast(ulong id) {
		return __find(_beasts, id);
	}
	/// ditto
	void remove(BeastCard c) {
		__removeC(_beasts, c);
	}
	/// ditto
	BeastCard insert(int index, BeastCard c) {
		return __insert!(BeastCard, toBeastId)(_beasts, index, c);
	}

	/// 指定された要素のindexを検索する。
	const
	int indexOf(T)(in T c) {
		static if (is (T == SkillCard)) {
			return .cCountUntil!("a is b")(_skills, c);
		} else static if (is (T == ItemCard)) {
			return .cCountUntil!("a is b")(_items, c);
		} else static if (is (T == BeastCard)) {
			return .cCountUntil!("a is b")(_beasts, c);
		} else {
			static assert (0);
		}
	}

	/// index1とindex2を交換する。
	void swap(C)(int index1, int index2) {
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
	void mentality(Mentality mentali) {
		if (_mentali != mentali) changed();
		_mentali = mentali;
	}
	/// 精神異常の残り時間。
	@property
	const
	uint mentalityRound() {return _mentaliRound;}
	/// ditto
	@property
	void mentalityRound(uint round) {
		if (_mentaliRound != round) changed();
		_mentaliRound = round;
	}
	/// 麻痺の値。
	@property
	const
	uint paralyze() {return _para;}
	/// ditto
	@property
	void paralyze(uint value) {
		if (_para != value) changed();
		_para = value;
	}
	/// 毒の値。
	@property
	const
	uint poison() {return _poi;}
	/// ditto
	@property
	void poison(uint value) {
		if (_poi != value) changed();
		_poi = value;
	}
	/// 呪縛の残り時間。
	@property
	const
	uint bindRound() {return _bindRound;}
	/// ditto
	@property
	void bindRound(uint round) {
		if (_bindRound != round) changed();
		_bindRound = round;
	}
	/// 沈黙の残り時間。
	@property
	const
	uint silenceRound() {return _slntRound;}
	/// ditto
	@property
	void silenceRound(uint round) {
		if (_slntRound != round) changed();
		_slntRound = round;
	}
	/// 暴露の残り時間。
	@property
	const
	uint faceUpRound() {return _faceUpRound;}
	/// ditto
	@property
	void faceUpRound(uint round) {
		if (_faceUpRound != round) changed();
		_faceUpRound = round;
	}
	/// 魔法無効状態の残り時間。
	@property
	const
	uint antiMagicRound() {return _antiMgcRound;}
	/// ditto
	@property
	void antiMagicRound(uint round) {
		if (_antiMgcRound != round) changed();
		_antiMgcRound = round;
	}
	/// 能力値ボーナスの値。
	const
	int enhance(Enhance enh) {return _rEnh[enh];}
	/// ditto
	void enhance(Enhance enh, int value) {
		if (_rEnh[enh] != value) changed();
		_rEnh[enh] = value;
	}
	/// 能力値ボーナスの残り時間。
	const
	uint enhanceRound(Enhance enh) {return _rEnhRound[enh];}
	/// ditto
	void enhanceRound(Enhance enh, uint round) {
		if (_rEnhRound[enh] != round) changed();
		_rEnhRound[enh] = round;
	}

	/// XMLテキストに変換する。
	const
	string toXML() {
		return toNode().text;
	}
	/// XMLノードに変換する。
	const
	XNode toNode() {
		auto n = XNode.create(XML_NAME);
		toNodeImpl(n);
		return n;
	}
	/// 自身をXMLノードにして指定されたノードに追加する。
	const
	XNode toNode(ref XNode parent) {
		auto cNode = parent.newElement(XML_NAME);
		toNodeImpl(cNode);
		return cNode;
	}
	const
	private void toNodeImpl(ref XNode cNode) {
		auto pNode = setProp(cNode, id);
		pNode.newElement("Level", level);
		pNode.newElement("Life", life).newAttr("max", lifeMax);
		setFeature(pNode);
		setAbility(pNode);
		{
			auto sNode = pNode.newElement("Status");
			sNode.newElement("Mentality", fromMentality(mentality)).newAttr("duration", mentalityRound);
			sNode.newElement("Paralyze", paralyze);
			sNode.newElement("Poison", poison);
			sNode.newElement("Bind").newAttr("duration", bindRound);
			sNode.newElement("Silence").newAttr("duration", silenceRound);
			sNode.newElement("FaceUp").newAttr("duration", faceUpRound);
			sNode.newElement("AntiMagic").newAttr("duration", antiMagicRound);
		}
		{
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
		{
			auto cpNode = pNode.newElement("Coupons");
			foreach (c; _coupon) {
				c.toNode(cpNode);
			}
		}
		{
			auto cardNode = cNode.newElement("ItemCards");
			foreach (c; _items) {
				c.toNode(cardNode);
			}
		}
		{
			auto cardNode = cNode.newElement("SkillCards");
			foreach (c; _skills) {
				c.toNode(cardNode);
			}
		}
		{
			auto cardNode = cNode.newElement("BeastCards");
			foreach (c; _beasts) {
				c.toNode(cardNode);
			}
		}
	}

	/// XMLノードからインスタンスを生成する。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static CastCard createFromNode(XNode cNode, string ver) {
		if (cNode.name != XML_NAME) throw new CardException("Node is not cast card: " ~ cNode.name);
		auto r = new CastCard(0, "", "", "", 1, 1);
		cNode.onTag["Property"] = (ref XNode pNode) {
			pNode.onTag["Level"] = (ref XNode n) {r._lev = n.valueTo!(int);};
			pNode.onTag["Life"] = (ref XNode n) {
				r._life = n.valueTo!(int);
				r._lifeMax = n.attr!(int)("max", true);
			};
			pNode.onTag["Feature"] = (ref XNode n) {r.loadFeature(n, ver);};
			pNode.onTag["Ability"] = (ref XNode n) {r.loadAbility(n, ver);};

			pNode.onTag["Status"] = (ref XNode sNode) {
				sNode.onTag["Mentality"] = (ref XNode n) {
					r.mentality = toMentality(n.value);
					r.mentalityRound = n.attr!(int)("duration", true);
				};
				sNode.onTag["Paralyze"] = (ref XNode n) {
					r.paralyze = n.valueTo!(int);
				};
				sNode.onTag["Poison"] = (ref XNode n) {
					r.poison = n.valueTo!(int);
				};
				sNode.onTag["Bind"] = (ref XNode n) {
					r.bindRound =  n.attr!(int)("duration", true);
				};
				sNode.onTag["Silence"] = (ref XNode n) {
					r.silenceRound =  n.attr!(int)("duration", true);
				};
				sNode.onTag["FaceUp"] = (ref XNode n) {
					r.faceUpRound =  n.attr!(int)("duration", true);
				};
				sNode.onTag["AntiMagic"] = (ref XNode n) {
					r.antiMagicRound =  n.attr!(int)("duration", true);
				};
			};
			pNode.onTag["Enhance"] = (ref XNode n) {
				void setEnh(ref XNode n, Enhance enh) {
					r.enhance(enh, n.valueTo!(int));
					r.enhanceRound(enh, n.attr!(int)("duration", true));
				}
				n.onTag["Action"] = (ref XNode n) {setEnh(n, Enhance.ACTION);};
				n.onTag["Avoid"] = (ref XNode n) {setEnh(n, Enhance.AVOID);};
				n.onTag["Resist"] = (ref XNode n) {setEnh(n, Enhance.RESIST);};
				n.onTag["Defense"] = (ref XNode n) {setEnh(n, Enhance.DEFENSE);};
				n.parse();
			};
			pNode.onTag["Coupons"] = (ref XNode n) {
				n.onTag["Coupon"] = (ref XNode n) {
					r._coupon ~= Coupon.fromNode(n, ver);
				};
				n.parse();
			};
			r.loadProp(pNode, ver);
		};

		cNode.onTag["ItemCards"] = (ref XNode n) {
			n.onTag[ItemCard.XML_NAME] = (ref XNode n) {
				r._items ~= ItemCard.createFromNode(n, ver);
			};
			n.parse();
			r._items.sort;
		};
		cNode.onTag["SkillCards"] = (ref XNode n) {
			n.onTag[SkillCard.XML_NAME] = (ref XNode n) {
				r._skills ~= SkillCard.createFromNode(n, ver);
			};
			n.parse();
			r._skills.sort;
		};
		cNode.onTag["BeastCards"] = (ref XNode n) {
			n.onTag[BeastCard.XML_NAME] = (ref XNode n) {
				r._beasts ~= BeastCard.createFromNode(n, ver);
			};
			n.parse();
			r._beasts.sort;
		};
		cNode.parse();
		return r;
	}

	private CastOwner _owner = null;
	@property
	package void owner(CastOwner owner) {_owner = owner;}
	@property
	string cwxPath() {
		return _owner ? cpjoin(_owner, "castcard", .cCountUntil!("a is b")(_owner.casts, this)) : "";
	}
	CWXPath findCWXPath(string path) {
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		switch (cate) {
		case "skillcard": {
			auto index = cpindex(path);
			if (index >= skills.length) return null;
			return skills[index].findCWXPath(cpbottom(path));
		}
		case "skillcard:id": {
			auto card = skill(cpindex(path));
			return card ? card.findCWXPath(cpbottom(path)) : null;
		}
		case "itemcard": {
			auto index = cpindex(path);
			if (index >= items.length) return null;
			return items[index].findCWXPath(cpbottom(path));
		}
		case "itemcard:id": {
			auto card = item(cpindex(path));
			return card ? card.findCWXPath(cpbottom(path)) : null;
		}
		case "beastcard": {
			auto index = cpindex(path);
			if (index >= beasts.length) return null;
			return beasts[index].findCWXPath(cpbottom(path));
		}
		case "beastcard:id": {
			auto card = beast(cpindex(path));
			return card ? card.findCWXPath(cpbottom(path)) : null;
		}
		default: break;
		}
		return null;
	}
	@property
	CWXPath[] cwxChilds() {
		CWXPath[] r;
		r ~= cast(CWXPath[]) skills;
		r ~= cast(CWXPath[]) items;
		r ~= cast(CWXPath[]) beasts;
		return r;
	}
	@property
	CWXPath cwxParent() {return _owner;}
}

/// スキル・アイテム・召喚獣といった、「効果」のあるカードの親クラス。
private abstract class EffectCard : Card, EventTreeOwner, MotionOwner, IPathUser {
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
	string[] _keyCodes = [];
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
		override bool canHasFireRound() {return false;}
		@property
		const
		override bool canHasFireKeyCode() {return false;}
		@property
		override size_t[] areaPath() {return [0];}
		@property
		string cwxPath() {return this.outer.cwxPath();}
		@property
		CWXPath cwxParent() {return this.outer.cwxParent();}
	}
public:
	/// 唯一のコンストラクタ。
	/// Params:
	/// id = カードID。
	/// name = 名前。
	/// imagePath = 画像のパス。
	/// desc = 解説。
	this (ulong id, string name, string imagePath, string desc) {
		super(id, name, imagePath, desc);
		_ceto = new CETO;
		_muser = new MotionUser(this);
		_se1 = new PathUser(this);
		_se2 = new PathUser(this);
		_enh = [Enhance.AVOID:0, Enhance.RESIST:0, Enhance.DEFENSE:0];
	}
	/// cからパラメータをコピーする。
	protected void shallowCopyEffectCard(EffectCard c) {
		shallowCopyCard(c);
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
		soundPath2 = c.soundPath2;
		keyCodes = c.keyCodes.dup;
		premium = c.premium;
		Motion[] ms;
		foreach (m; c.motions) {
			ms ~= m.dup;
		}
		motions = ms;
	}

	/// カードが属するシナリオ名、及びカードの製作者。
	/// 他のシナリオからのインポート等があるため、
	/// 現在のシナリオと同一になるとは限らない。
	@property
	const
	string scenario() {return _scenario;}
	/// ditto
	@property
	void scenario(string scenario) {
		if (_scenario != scenario) changed();
		_scenario = scenario;
	}
	/// ditto
	@property
	const
	string author() {return _author;}
	/// ditto
	@property
	void author(string author) {
		if (_author != author) changed();
		_author = author;
	}

	/// カードの適正。肉体要素。
	@property
	const
	Physical physical() {return _phy;}
	/// ditto
	@property
	void physical(Physical phy) {
		if (_phy != phy) changed();
		_phy = phy;
	}
	/// カードの適正。精神要素。
	@property
	const
	Mental mental() {return _mtl;}
	/// ditto
	@property
	void mental(Mental mtl) {
		if (_mtl != mtl) changed();
		_mtl = mtl;
	}

	/// カードの標的。
	@property
	const
	CardTarget target() {return _targ;}
	/// ditto
	@property
	void target(CardTarget targ) {
		if (_targ != targ) changed();
		_targ = targ;
	}
	/// 全体が標的となるか。
	@property
	const
	bool allRange() {return _allRange;}
	/// ditto
	@property
	void allRange(bool allRange) {
		if (_allRange != allRange) changed();
		_allRange = allRange;
	}
	/// 使用時に発声が必要か。
	@property
	const
	bool spell() {return _spell;}
	/// ditto
	@property
	void spell(bool spell) {
		if (_spell != spell) changed();
		_spell = spell;
	}
	/// 効果のタイプ。物理、魔法、魔法的物理、物理的魔法。
	@property
	const
	EffectType effectType() {return _effTyp;}
	/// ditto
	@property
	void effectType(EffectType effTyp) {
		if (_effTyp != effTyp) changed();
		_effTyp = effTyp;
	}
	/// 回避属性。回避か抵抗か。
	@property
	const
	Resist resist() {return _res;}
	/// ditto
	@property
	void resist(Resist res) {
		if (_res != res) changed();
		_res = res;
	}
	/// 成功率。-5～+5。
	@property
	const
	int successRate() {return _suc;}
	/// ditto
	@property
	void successRate(int suc) {
		if (_suc != suc) changed();
		_suc = suc;
	}
	/// カードの視覚効果。
	@property
	const
	CardVisual visual() {return _vis;}
	/// ditto
	@property
	void visual(CardVisual vis) {
		if (_vis != vis) changed();
		_vis = vis;
	}
	/// 使用時の能力値ボーナス。
	const
	int enhance(Enhance enh) {return _enh[enh];}
	/// ditto
	void enhance(Enhance enh, int val) {
		if (_enh[enh] != val) changed();
		_enh[enh] = val;
	}
	/// 使用時サウンド。
	@property
	const
	string soundPath1() {return _se1.path;}
	/// ditto
	@property
	void soundPath1(string path) {
		if (_se1.path != path) changed();
		_se1.path = path;
	}
	/// 命中時サウンド。
	@property
	const
	string soundPath2() {return _se2.path;}
	/// ditto
	@property
	void soundPath2(string path) {
		if (_se2.path != path) changed();
		_se2.path = path;
	}
	/// キーコード。
	@property
	string[] keyCodes() {return _keyCodes;}
	/// ditto
	@property
	void keyCodes(string[] keyCodes) {
		if (_keyCodes != keyCodes) changed();
		_keyCodes = keyCodes;
	}
	/// カードの希少価値。
	@property
	const
	Premium premium() {return _premi;}
	/// ditto
	@property
	void premium(Premium premi) {
		if (_premi != premi) changed();
		_premi = premi;
	}
	/// カードの効果。
	@property
	Motion[] motions() {return _muser.motions;}
	/// ditto
	@property
	const
	const(Motion)[] motions() {return _muser.motions;}
	/// ditto
	@property
	void motions(Motion[] motions) {
		_muser.motions = motions;
	}
	@property
	override void changeHandler(void delegate() change) {
		_ceto.changeHandler = change;
		_muser.changeHandler = change;
		super.changeHandler = change;
	}
	@property
	protected override void delegate() changeHandler() {
		return super.changeHandler;
	}
	@property
	override void setUseCounter(UseCounter uc) {
		_ceto.setUseCounter = uc;
		_muser.setUseCounter = uc;
		super.setUseCounter = uc;
	}
	@property
	override void removeUseCounter() {
		_ceto.removeUseCounter();
		_muser.removeUseCounter();
		super.removeUseCounter();
	}

	@property
	override EventTree[] trees() {return _ceto.trees;}

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
	override bool canHasFireRound() {return _ceto.canHasFireRound;}
	@property
	const
	override bool canHasFireKeyCode() {return _ceto.canHasFireKeyCode;}
	@property
	override size_t[] areaPath() {return _ceto.areaPath;}
	EventTree etFromPath(size_t[] path) {
		if (path[0] == 0) {
			return trees[path[1]];
		}
		assert (0);
	}

	override void add(EventTree evt) {return _ceto.add(evt);}
	override void insert(int index, EventTree evt) {return _ceto.insert(index, evt);}
	override void removeEvent(int index) {return _ceto.removeEvent(index);}
	override void remove(EventTree et) {return _ceto.remove(et);}
	override void swapEventTree(int index1, int index2) {return _ceto.swapEventTree(index1, index2);}

	/// 指定されたXMLノードに効果カード関連の情報を追加する。
	const
	protected XNode setEffProp(ref XNode node, ulong forceId = 0UL) {
		auto pNode = setProp(node, forceId);
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
		pNode.newElement("SoundPath", encodePath(soundPath1));
		pNode.newElement("SoundPath2", encodePath(soundPath2));
		pNode.newElement("KeyCodes", encodeLf(_keyCodes, false));
		pNode.newElement("Premium", fromPremium(premium));
		auto mNode = node.newElement("Motions");
		foreach (m; _muser.motions) {
			m.toNode(mNode);
		}
		_ceto.appendEventsToNode(node);
		return pNode;
	}
	/// 指定されたXMLノードから効果カード関連のデータを読み出す。
	protected void loadEffProp(ref XNode pNode, string ver) {
		assert (pNode.name == "Property");
		pNode.onTag["Scenario"] = (ref XNode n) {_scenario = n.value;};
		pNode.onTag["Author"] = (ref XNode n) {_author = n.value;};
		pNode.onTag["Ability"] = (ref XNode n) {
			_phy = toPhysical(n.attr("physical", true));
			_mtl = toMental(n.attr("mental", true));
		};
		pNode.onTag["Target"] = (ref XNode n) {
			_targ = toCardTarget(n.value);
			_allRange = parseBool(n.attr("allrange", true));
		};
		pNode.onTag["EffectType"] = (ref XNode n) {
			_effTyp = toEffectType(n.value);
			_spell = parseBool(n.attr("spell", true));
		};
		pNode.onTag["ResistType"] = (ref XNode n) {_res = toResist(n.value);};
		pNode.onTag["SuccessRate"] = (ref XNode n) {_suc = n.valueTo!(int);};
		pNode.onTag["VisualEffect"] = (ref XNode n) {_vis = toCardVisual(n.value);};
		pNode.onTag["Enhance"] = (ref XNode n) {
			_enh[Enhance.AVOID] = n.attr!(int)("avoid", true);
			_enh[Enhance.RESIST] = n.attr!(int)("resist", true);
			_enh[Enhance.DEFENSE] = n.attr!(int)("defense", true);
		};
		pNode.onTag["SoundPath"] = (ref XNode n) {_se1.path = decodePath(n.value);};
		pNode.onTag["SoundPath2"] = (ref XNode n) {_se2.path = decodePath(n.value);};
		pNode.onTag["KeyCodes"] = (ref XNode n) {_keyCodes = decodeLf(n.value);};
		pNode.onTag["Premium"] = (ref XNode n) {_premi = toPremium(n.value);};
		loadProp(pNode, ver);
	}
	/// ditto
	protected void loadEffV(ref XNode node, string ver) {
		node.onTag["Motions"] = (ref XNode n) {
			Motion[] motions;
			n.onTag["Motion"] = (ref XNode n) {
				motions ~= Motion.createFromNode(n, ver);
			};
			n.parse();
			_muser.motions = motions;
		};
		node.onTag["Events"] = (ref XNode n) {
			_ceto.addAll(AbstractEventTreeOwner.loadEventsFromNode(n, ver));
		};
		node.parse();
	}
	CWXPath findCWXPath(string path) {
		if (cpempty(path)) return this;
		return _ceto.findCWXPath(path);
	}
	@property
	CWXPath[] cwxChilds() {
		CWXPath[] r;
		r ~= cast(CWXPath[]) motions;
		r ~= _ceto.cwxChilds;
		return r;
	}
}

/// スキルカード。
class SkillCard : EffectCard {
private:
	uint _level;
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
	/// imagePath = 画像のパス。
	/// desc = 解説。
	this (ulong id, string name, string imagePath, string desc) {
		super(id, name, imagePath, desc);
	}
	/// cからパラメータをコピーする。
	void shallowCopy(SkillCard c) {
		shallowCopyEffectCard(c);
		level = c.level;
		hold = c.hold;
		useLimit = c.useLimit;
	}

	/// レベル。
	@property
	const
	uint level() {return _level;}
	/// ditto
	@property
	void level(uint level) {
		if (_level != level) changed();
		_level = level;
	}

	/// 残り使用回数。
	@property
	const
	uint useLimit() {return _useLimit;}
	/// ditto
	@property
	void useLimit(uint useLimit) {
		if (_useLimit != useLimit) changed();
		_useLimit = useLimit;
	}

	/// ホールド状態か。
	@property
	const
	bool hold() {return _hold;}
	/// ditto
	@property
	void hold(bool hold) {
		if (_hold != hold) changed();
		_hold = hold;
	}

	/// XMLテキストに変換する。
	const
	string toXML() {
		return toNode().text;
	}
	/// XMLノードに変換する。
	const
	XNode toNode() {
		auto n = XNode.create(XML_NAME);
		toNodeImpl(n);
		return n;
	}
	/// 自身をXMLノードにして指定されたノードに追加する。
	const
	XNode toNode(ref XNode parent) {
		auto cNode = parent.newElement(XML_NAME);
		toNodeImpl(cNode);
		return cNode;
	}
	const
	private void toNodeImpl(ref XNode cNode) {
		auto pNode = setEffProp(cNode, 0UL);
		pNode.newElement("Level", level);
		pNode.newElement("UseLimit", useLimit);
		pNode.newElement("Hold", fromBool(hold));
	}

	/// XMLノードからインスタンスを生成する。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static SkillCard createFromNode(ref XNode cNode, string ver) {
		if (cNode.name != XML_NAME) throw new CardException("Node is not skill card: " ~ cNode.name);
		auto r = new SkillCard(0, "", "", "");
		cNode.onTag["Property"] = (ref XNode pNode) {
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
	string cwxPath() {
		return _owner ? cpjoin(_owner, "skillcard", .cCountUntil!("a is b")(_owner.skills, this)) : "";
	}
	@property
	CWXPath cwxParent() {return _owner;}
}

/// アイテムカード。
class ItemCard : EffectCard {
private:
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
	/// imagePath = 画像のパス。
	/// desc = 解説。
	this (ulong id, string name, string imagePath, string desc) {
		super(id, name, imagePath, desc);
		_oEnh = [Enhance.AVOID:0, Enhance.RESIST:0, Enhance.DEFENSE:0];
	}
	/// cからパラメータをコピーする。
	void shallowCopy(ItemCard c) {
		shallowCopyEffectCard(c);
		enhanceOwner(Enhance.AVOID, c.enhanceOwner(Enhance.AVOID));
		enhanceOwner(Enhance.RESIST, c.enhanceOwner(Enhance.RESIST));
		enhanceOwner(Enhance.DEFENSE, c.enhanceOwner(Enhance.DEFENSE));
		price = c.price;
		useLimit = c.useLimit;
		useLimitMax = c.useLimitMax;
		hold = c.hold;
	}

	/// 使用回数。0で無制限。
	@property
	const
	uint useLimit() {return _useLimit;}
	/// ditto
	@property
	void useLimit(uint useLimit) {
		if (_useLimit != useLimit) changed();
		_useLimit = useLimit;
	}

	/// 最大使用回数。0で無制限。
	@property
	const
	uint useLimitMax() {return _useLimitMax;}
	/// ditto
	@property
	void useLimitMax(uint useLimitMax) {
		if (_useLimitMax != useLimitMax) changed();
		_useLimitMax = useLimitMax;
	}

	/// 値段。
	@property
	const
	uint price() {return _price;}
	/// ditto
	@property
	void price(uint price) {
		if (_price != price) changed();
		_price = price;
	}

	/// 所持者の能力値ボーナス。
	const
	int enhanceOwner(Enhance enh) {return _oEnh[enh];}
	/// ditto
	void enhanceOwner(Enhance enh, int val) {
		if (_oEnh[enh] != val) changed();
		_oEnh[enh] = val;
	}

	/// ホールド状態か。
	@property
	const
	bool hold() {return _hold;}
	/// ditto
	@property
	void hold(bool hold) {
		if (_hold != hold) changed();
		_hold = hold;
	}

	/// XMLテキストに変換する。
	const
	string toXML() {
		return toNode().text;
	}
	/// XMLノードに変換する。
	const
	XNode toNode() {
		auto n = XNode.create(XML_NAME);
		toNodeImpl(n);
		return n;
	}
	/// 自身をXMLノードにして指定されたノードに追加する。
	const
	XNode toNode(ref XNode parent) {
		auto cNode = parent.newElement(XML_NAME);
		toNodeImpl(cNode);
		return cNode;
	}
	const
	private void toNodeImpl(ref XNode cNode) {
		auto pNode = setEffProp(cNode, 0UL);
		pNode.newElement("UseLimit", useLimit).newAttr("max", useLimitMax);
		pNode.newElement("Price", price);
		auto eo = pNode.newElement("EnhanceOwner");
		eo.newAttr("avoid", enhanceOwner(Enhance.AVOID));
		eo.newAttr("resist", enhanceOwner(Enhance.RESIST));
		eo.newAttr("defense", enhanceOwner(Enhance.DEFENSE));
		pNode.newElement("Hold", fromBool(hold));
	}

	/// XMLノードからインスタンスを生成する。
	/// Params:
	/// cNode = XMLノード。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static ItemCard createFromNode(ref XNode cNode, string ver) {
		if (cNode.name != XML_NAME) throw new CardException("Node is not item card: " ~ cNode.name);
		auto r = new ItemCard(0, "", "", "");
		cNode.onTag["Property"] = (ref XNode pNode) {
			pNode.onTag["UseLimit"] = (ref XNode n) {
				r._useLimit = n.valueTo!(int);
				r._useLimitMax = n.attr!(int)("max", true);
			};
			pNode.onTag["Price"] = (ref XNode n) {r._price = n.valueTo!(int);};
			pNode.onTag["EnhanceOwner"] = (ref XNode n) {
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
	string cwxPath() {
		return _owner ? cpjoin(_owner, "itemcard", .cCountUntil!("a is b")(_owner.items, this)) : "";
	}
	@property
	CWXPath cwxParent() {return _owner;}
}

/// 召喚獣カード。
class BeastCard : EffectCard {
private:
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
	/// imagePath = 画像のパス。
	/// desc = 解説。
	this (ulong id, string name, string imagePath, string desc) {
		super(id, name, imagePath, desc);
	}
	/// cからパラメータをコピーする。
	void shallowCopy(BeastCard c) {
		shallowCopyEffectCard(c);
		useLimit = c.useLimit;
	}

	/// 使用回数。0で無制限。
	@property
	const
	uint useLimit() {return _useLimit;}
	/// ditto
	@property
	void useLimit(uint useLimit) {
		if (_useLimit != useLimit) changed();
		_useLimit = useLimit;
	}

	/// XMLテキストに変換する。
	const
	string toXML() {
		return toNode().text;
	}
	/// XMLノードに変換する。
	const
	XNode toNode() {
		auto n = XNode.create(XML_NAME);
		toNodeImpl(n);
		return n;
	}
	/// 自身をXMLノードにして指定されたノードに追加する。
	const
	XNode toNode(ref XNode parent) {
		auto cNode = parent.newElement(XML_NAME);
		toNodeImpl(cNode);
		return cNode;
	}
	const
	private void toNodeImpl(ref XNode cNode, ulong forceId = 0UL) {
		assert (cNode.name == XML_NAME);
		auto pNode = setEffProp(cNode, forceId);
		pNode.newElement("UseLimit", useLimit);
	}
	/// コピーを生成する。
	@property
	const
	BeastCard dup() {
		auto node = XNode.create(BeastCard.XML_NAME);
		toNodeImpl(node);
		return BeastCard.createFromNode(node, LATEST_VERSION);
	}
	/// XMLテキストに変換する。
	const
	string toXML(ulong forceId = 0UL) {
		auto n = XNode.create(XML_NAME);
		toNodeImpl(n, forceId);
		return n.text;
	}
	/// XMLノードからインスタンスを生成する。
	/// Params:
	/// cNode = XMLノード。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static BeastCard createFromNode(ref XNode cNode, string ver) {
		if (cNode.name != XML_NAME) throw new CardException("Node is not beast card: " ~ cNode.name);
		auto r = new BeastCard(0, "", "", "");
		cNode.onTag["Property"] = (ref XNode pNode) {
			pNode.onTag["UseLimit"] = (ref XNode n) {r._useLimit = n.valueTo!(int);};
			r.loadEffProp(pNode, ver);
		};
		r.loadEffV(cNode, ver);
		return r;
	}

	private BeastOwner _owner = null;
	@property
	package void owner(BeastOwner owner) {_owner = owner;}
	@property
	string cwxPath() {
		return _owner ? cpjoin(_owner, "beastcard", .cCountUntil!("a is b")(_owner.beasts, this)) : "";
	}
	@property
	CWXPath cwxParent() {return _owner;}
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
	/// imagePath = 画像のパス。
	/// desc = 解説。
	this (ulong id, string name, string imagePath, string desc) {
		super(id, name, imagePath, desc);
	}
	/// cからパラメータをコピーする。
	void shallowCopy(InfoCard c) {
		shallowCopyCard(c);
	}

	/// XMLテキストに変換する。
	const
	string toXML() {
		return toNode().text;
	}
	/// XMLノードに変換する。
	const
	XNode toNode() {
		auto n = XNode.create(XML_NAME);
		toNodeImpl(n);
		return n;
	}
	/// 自身をXMLノードにして指定されたノードに追加する。
	const
	XNode toNode(ref XNode parent) {
		auto cNode = parent.newElement(XML_NAME);
		toNodeImpl(cNode);
		return cNode;
	}
	const
	private void toNodeImpl(ref XNode cNode) {
		setProp(cNode);
	}
	/// XMLノードからインスタンスを生成する。
	/// Params:
	/// cNode = XMLノード。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static InfoCard createFromNode(ref XNode cNode, string ver) {
		if (cNode.name != XML_NAME) throw new CardException("Node is not info card: " ~ cNode.name);
		auto r = new InfoCard(0, "", "", "");
		cNode.onTag["Property"] = (ref XNode node) {
			r.loadProp(node, ver);
		};
		cNode.parse();
		return r;
	}

	private InfoOwner _owner = null;
	@property
	package void owner(InfoOwner owner) {_owner = owner;}
	@property
	string cwxPath() {
		return _owner ? cpjoin(_owner, "infocard", .cCountUntil!("a is b")(_owner.infos, this)) : "";
	}
	CWXPath findCWXPath(string path) {
		if (cpempty(path)) return this;
		return null;
	}
	@property
	CWXPath[] cwxChilds() {return [];}
	@property
	CWXPath cwxParent() {return _owner;}
}
