
module cwx.area;

import cwx.utils;
import cwx.event;
import cwx.usecounter;
import cwx.background;
import cwx.xml;
import cwx.card;
import cwx.path;

import std.math;
import std.conv;

/// エリア等の所持者を示すインタフェース。
interface AreaOwner : CWXPath {
	@property
	Area[] areas();
}
/// ditto
interface BattleOwner : CWXPath {
	@property
	Battle[] battles();
}
/// ditto
interface PackageOwner : CWXPath {
	@property
	Package[] packages();
}

/// XMLテキストを元にエリアを生成して返す。
/// Params:
/// xml = XMLテキスト。
/// sameId = 貼り紙のID。
/// sameSummary = 生成するエリアが元々属していた貼り紙が、sameIdが指す貼り紙と同一であるか。
/// Returns: エリア。エリアでない場合はnull。
/// Throws:
/// XmlException = パース失敗。
/// IllegalArgumentException = 数値であるべきデータが数値でない。
AbstractArea createAreaFromXML(string xml, string summId, out bool sameSummary, string ver) {
	try {
		scope e = XNode.parse(xml);
		auto id = e.attr("summaryId", false);
		sameSummary = id && id == summId;
		switch (e.name) {
		case "Area": return Area.createFromNode(e, ver);
		case "Battle": return Battle.createFromNode(e, ver);
		case "Package": return Package.createFromNode(e, ver);
		default: return null;
		}
	} catch (Exception e) {
		return null;
	}
}

/// メニューカードとエネミーカードの親クラス。
public abstract class AbstractSpCard : AbstractEventTreeOwner, IFlagUser {
private:
	int _x, _y;
	real _scale;
	FlagUser _user;
public:
	/// 唯一のコンストラクタ。
	this (string flag, int x, int y, real scale) {
		_user = new FlagUser(this);
		_user.flag = flag;
		_x = x;
		_y = y;
		_scale = scale;
	}
	/// このカードの所属先を返す。
	@property
	AbstractArea abstractOwner();
	/// ditto
	@property
	const
	const(AbstractArea) abstractOwner();

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
	override bool canHasFireKeyCode() {return true;}

	/// 表示フラグ。
	@property
	void flag(string flag) {
		if (_user.flag != flag) changed();
		_user.flag = flag;
	}
	/// ditto
	@property
	const
	string flag() {
		return _user.flag;
	}
	/// X座標。
	@property
	const
	int x() {
		return _x;
	}
	/// ditto
	@property
	void x(int x) {
		if (_x != x) changed();
		_x = x;
	}
	/// Y座標。
	@property
	const
	int y() {
		return _y;
	}
	/// ditto
	@property
	void y(int y) {
		if (_y != y) changed();
		_y = y;
	}
	/// スケール。1.0が標準。0.75～2.0。
	@property
	const
	real scale() {
		return _scale;
	}
	/// ditto
	@property
	void scale(real scale) {
		if (cast(int) (_scale * 100) != cast(int) (scale * 100)) {
			changed();
			_scale = scale;
		}
	}

	@property
	override void setUseCounter(UseCounter uc) {
		_user.setUseCounter(uc);
		super.setUseCounter(uc);
	}
	override void removeUseCounter() {
		_user.removeUseCounter();
		super.removeUseCounter();
	}
	override void change(FlagId id) {
		_user.change(id);
	}

	/// 指定されたノードにProperty情報を追加する。
	const
	protected void appendProp(ref XNode pNode, XMLOption opt) {
		assert (pNode.name == "Property", pNode.name ~ " != Property");
		pNode.newElement("Flag", _user.flag);
		auto ln = pNode.newElement("Location");
		ln.newAttr("left", _x);
		ln.newAttr("top", _y);
		pNode.newElement("Size").newAttr("scale", to!(string)(cast(int) rndtol(_scale * 100.0)) ~ "%");
	}
	/// 指定されたノードからProperty情報を読み出す。
	protected static void loadProp(ref XNode pNode, out string flag, out int x, out int y, out real scale) {
		flag = "";
		x = 0;
		y = 0;
		scale = 1.0;
		assert (pNode.name == "Property", pNode.name ~ " != Property");
		pNode.onTag["Flag"] = (ref XNode n) {flag = n.value;};
		pNode.onTag["Location"] = (ref XNode n) {
			x = n.attr!(int)("left", true);
			y = n.attr!(int)("top", true);
		};
		pNode.onTag["Size"] = (ref XNode n) {
			string val = n.attr("scale", true);
			if (val.length < 2u) throw new Exception("scale error: " ~ val);
			if (val[$ - 1] == '%') {
				val = val[0 .. $ - 1];
			}
			scale = to!(real)(val) / 100.0;
		};
		pNode.parse();
	}
}

/// バトルに配置するカード。
public class EnemyCard : AbstractSpCard, ICastUser {
private:
	Battle _owner = null;
	bool _escape;
	CastUser _user;
public:
	/// XML要素名。
	immutable XML_NAME = "EnemyCard";
	/// XML要素名(複数)。
	immutable XML_NAME_M = "EnemyCards";

	/// 唯一のコンストラクタ。
	this (ulong id, bool escape, string flag, int x, int y, real scale) {
		super(flag, x, y, scale);
		_user = new CastUser(this);
		_user.casts = id;
		_escape = escape;
	}
	@property
	string cwxPath(bool id) {
		return _owner ? cpjoin(_owner, "enemycard", .cCountUntil!("a is b")(_owner.cards, this), id) : "";
	}
	@property
	CWXPath cwxParent() {return _owner;}

	@property
	override size_t[] areaPath() {
		if (_owner) {
			return [.cCountUntil!("a is b")(_owner.cards, this) + 1];
		} else {
			return [];
		}
	}
	@property
	override AbstractArea abstractOwner() {
		return _owner;
	}
	@property
	const
	override const(AbstractArea) abstractOwner() {
		return _owner;
	}
	/// このカードの所属先を返す。
	@property
	Battle owner() {
		return _owner;
	}
	/// ditto
	@property
	const
	const(Battle) owner() {
		return _owner;
	}

	/// 逃走するか否か。
	@property
	const
	bool escape() {
		return _escape;
	}
	/// ditto
	@property
	void escape(bool escape) {
		if (_escape != escape) changed();
		_escape = escape;
	}
	/// キャストID。
	@property
	const
	ulong id() {
		return _user.casts;
	}
	/// ditto
	@property
	void id(ulong id) {
		if (_user.casts != id) changed();
		_user.casts = id;
	}

	@property
	override void setUseCounter(UseCounter uc) {
		_user.setUseCounter(uc);
		super.setUseCounter(uc);
	}
	override void removeUseCounter() {
		_user.removeUseCounter();
		super.removeUseCounter();
	}
	override void change(CastId id) {
		_user.change(id);
	}

	static EnemyCard[] createCardsFromNode(ref XNode node, string ver) {
		assert (node.name == CastCard.XML_NAME_M);
		EnemyCard[] cards;
		node.onTag["CastCard"] = (ref XNode cNode) {
			cNode.onTag["Property"] = (ref XNode pNode) {
				string idStr = pNode.childText("Id", false);
				if (idStr) {
					cards ~= new EnemyCard(to!(ulong)(idStr), false, "", 0, 0, 1.0);
				}
			};
			cNode.parse();
		};
		node.parse();
		return cards;
	}

	/// XMLノードにして返す。
	const
	XNode toNode(XMLOption opt) {
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e, opt);
		return e;
	}
	/// XMLノード(EnemyCards)にインスタンスのデータを追加する。
	const
	XNode toNode(ref XNode node, XMLOption opt) {
		assert (node.name == XML_NAME_M, node.name ~ " != EnemyCards");
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e, opt);
		return e;
	}
	const
	private void toNodeImpl(ref XNode e, XMLOption opt) {
		e.newAttr("escape", fromBool(escape));
		auto pe = e.newElement("Property");
		pe.newElement("Id", _user.casts);
		appendProp(pe, opt);
		appendEventsToNode(e, opt);
	}
	/// XMLノード(EnemyCard)からインスタンスを生成。
	/// Throws:
	/// AreaException = nodeがMenuCardでない。またはデータが不足している。
	/// IllegalArgmentException = 数値であるべきデータが数値でない。
	static EnemyCard createFromNode(ref XNode node, string ver) {
		if (node.name != XML_NAME) throw new AreaException("Node is not EnemyCard");

		bool getId = false;

		long id;
		bool escape = false;
		string flag = "";
		int x = 0, y = 0;
		real scale = 1.0;
		EventTree[] evt;

		auto escStr = node.attr("escape", false);
		escape = escStr ? parseBool(escStr) : false;
		node.onTag["Property"] = (ref XNode pNode) {
			pNode.onTag["Id"] = (ref XNode n) {
				id = to!(long)(n.value);
				getId = true;
			};
			loadProp(pNode, flag, x, y, scale);
		};
		node.onTag["Events"] = (ref XNode node) {
			evt = loadEventsFromNode(node, ver);
		};
		node.parse();
		if (!getId) throw new AreaException("EnemyCard ID not found");
		auto r = new EnemyCard(id, escape, flag, x, y, scale);
		r.addAll(evt);

		return r;
	}
}

/// エリアに配置するカード。
public class MenuCard : AbstractSpCard, IPathUser {
private:
	Area _owner;
	string _name;
	string _desc;
	PathUser _user;
	/// PC画像を表示する場合はその位置(1～6)。
	/// 0の場合はPC画像を使用しない。
	uint _pcNumber = 0;

public:
	/// XML要素名。
	immutable XML_NAME = "MenuCard";
	/// XML要素名(複数)。
	immutable XML_NAME_M = "MenuCards";

	/// 唯一のコンストラクタ。
	/// Params:
	/// name = カード名。
	/// path = 画像のファイルパス。
	/// desc = 解説。無しの場合は""。
	/// flag = フラグ。無しの場合は""。
	/// x = X座標。
	/// y = Y座標。
	/// scale = スケール。通常0.75～2.0。
	this (string name, string path, string desc, string flag,
			int x, int y, real scale) {
		super(flag, x, y, scale);
				_user = new PathUser(this);
		_user.path = path;
		_name = name;
		_desc = desc;
	}
	@property
	string cwxPath(bool id) {
		return _owner ? cpjoin(_owner, "menucard", .cCountUntil!("a is b")(_owner.cards, this), id) : "";
	}
	@property
	CWXPath cwxParent() {return _owner;}

	@property
	override size_t[] areaPath() {
		if (_owner) {
			return [.cCountUntil!("a is b")(_owner.cards, this) + 1];
		} else {
			return [];
		}
	}
	@property
	override AbstractArea abstractOwner() {
		return _owner;
	}
	@property
	const
	override const(AbstractArea) abstractOwner() {
		return _owner;
	}
	/// このカードの所属先を返す。
	@property
	Area owner() {
		return _owner;
	}
	/// ditto
	@property
	const
	const(Area) owner() {
		return _owner;
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
	/// 説明。
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
	/// 画像ファイルパス。
	@property
	const
	string path() {
		return _user.path;
	}
	/// ditto
	@property
	void path(string path) {
		if (_user.path != path) changed();
		_user.path = path;
	}

	/// PC画像を表示する場合はその位置(1～6)。
	/// 0の場合はPC画像を使用しない。
	@property
	const
	uint pcNumber() {
		return _pcNumber;
	}
	/// ditto
	@property
	void pcNumber(uint pcNumber) {
		if (_pcNumber != pcNumber) changed();
		_pcNumber = pcNumber;
	}

	@property
	override void setUseCounter(UseCounter uc) {
		_user.setUseCounter(uc);
		super.setUseCounter(uc);
	}
	override void removeUseCounter() {
		_user.removeUseCounter();
		super.removeUseCounter();
	}
	override void change(PathId id) {
		_user.change(id);
	}

	static MenuCard[] createFromCardNode(ref XNode node, bool copyDesc, string ver) {
		MenuCard parse(ref XNode node) {
			auto pNode = node.child("Property", false);
			if (!pNode.valid) return null;
			string name = null;
			string path = "";
			string desc = "";
			uint pcNumber = 0;
			pNode.onTag["Name"] = (ref XNode node) {name = node.value;};
			pNode.onTag["ImagePath"] = (ref XNode node) {path = decodePath(node.value);};
			if (copyDesc) {
				pNode.onTag["Description"] = (ref XNode node) {
					desc = decodeLf2(node.value);
				};
			}
			pNode.onTag["PCNumber"] = (ref XNode node) {pcNumber = .to!uint(node.value);};
			pNode.parse();
			if (!name) return null;
			auto r = new MenuCard(name, path, desc, "", 0, 0, 1.0);
			r.pcNumber = pcNumber;
			return r;
		}
		auto pNode = node.child("Property", false);
		if (pNode.valid) {
			auto card = parse(node);
			return card ? [card] : [];
		} else {
			MenuCard[] r;
			node.onTag[null] = (ref XNode node) {
				auto card = parse(node);
				if (card) r ~= card;
			};
			node.parse();
			return r;
		}
	}

	/// XMLノードにして返す。
	const
	XNode toNode(XMLOption opt) {
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e, opt);
		return e;
	}
	/// XMLノード(MenuCards)にインスタンスのデータを追加する。
	const
	XNode toNode(ref XNode node, XMLOption opt) {
		assert (node.name == XML_NAME_M, node.name ~ " != MenuCards");
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e, opt);
		return e;
	}
	const
	private void toNodeImpl(ref XNode e, XMLOption opt) {
		auto pe = e.newElement("Property");
		pe.newElement("Name", _name);
		pe.newElement("ImagePath", encodePath(_user.path));
		pe.newElement("Description", encodeLf(_desc));
		pe.newElement("PCNumber", .text(_pcNumber));
		appendProp(pe, opt);
		appendEventsToNode(e, opt);
	}

	/// XMLノード(MenuCard)からインスタンスを生成。
	/// Throws:
	/// AreaException = nodeがMenuCardでない。またはデータが不足している。
	/// IllegalArgmentException = 数値であるべきデータが数値でない。
	static MenuCard createFromNode(ref XNode node, string ver) {
		if (node.name != XML_NAME) throw new AreaException("Node is not MenuCard");

		string name = null;
		string path = "";
		string desc = "";
		string flag = "";
		int x = 0, y = 0;
		real scale = 1.0;
		uint pcNumber = 0;
		EventTree[] evt;

		node.onTag["Property"] = (ref XNode pNode) {
			pNode.onTag["Name"] = (ref XNode n) {name = n.value;};
			pNode.onTag["ImagePath"] = (ref XNode n) {path = decodePath(n.value);};
			pNode.onTag["Description"] = (ref XNode n) {desc = decodeLf2(n.value);};
			pNode.onTag["PCNumber"] = (ref XNode n) {pcNumber = .to!uint(n.value);};
			loadProp(pNode, flag, x, y, scale);
		};
		node.onTag["Events"] = (ref XNode node) {
			evt = loadEventsFromNode(node, ver);
		};
		node.parse();
		if (name is null) name = "";
		auto r = new MenuCard(name, path, desc, flag, x, y, scale);
		r.pcNumber = pcNumber;
		r.addAll(evt);

		return r;
	}
}

/// エリア・パッケージ・バトルの親クラス。
public abstract class AbstractArea : AbstractEventTreeOwner {
	ulong _id;
	string _name;
public:
	/// 唯一のコンストラクタ。
	this (ulong id, string name) {
		_id = id;
		_name = name;
	}
	/// エリアID。
	@property
	const
	ulong id() {
		return _id;
	}
	/// ditto
	@property
	void id(ulong id) {
		if (_id != id) changed();
		_id = id;
	}
	/// エリア名。
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

	const
	override int opCmp(Object o) {
		return cast(int) _id - cast(int) (cast(const(AbstractArea)) o)._id;
	}

	@property
	const
	abstract string rootName();

	@property
	override size_t[] areaPath() {return [0];}

	/// XMLテキスト化して返す。
	/// Params:
	/// summId = テキストに付与するID。nullを指定すると付与しない。
	const
	string toXML(XMLOption opt, string summId = null) {
		scope doc = XNode.create(rootName);
		toNodeImpl(doc, opt);
		if (summId) doc.newAttr("summaryId", summId);
		return doc.text;
	}

	/// XMLノード化して返す。
	const
	XNode toNode(XMLOption opt) {
		auto e = XNode.create(rootName);
		toNodeImpl(e, opt);
		return e;
	}
	const
	XNode toNode(ref XNode parent, XMLOption opt) {
		auto e = parent.newElement(rootName);
		toNodeImpl(e, opt);
		return e;
	}
	const
	abstract void toNodeImpl(ref XNode e, XMLOption opt);

	/// toXML()でsummIdを指定されたノードを渡すと、summIdを読み出して返す。
	static string summaryId(in XNode node) {
		return node.attr("summaryId", false, "");
	}

	/// 指定されたノードにProperty情報を追加する。
	const
	protected void appendProp(ref XNode pNode, XMLOption opt) {
		assert (pNode.name == "Property", pNode.name ~ " != Property");
		pNode.newElement("Id", _id);
		pNode.newElement("Name", _name);
	}
	/// 指定されたノードからProperty情報を読み出す。
	protected static void loadProp(ref XNode aNode, out ulong id, out string name, out string path) {
		string idStr = null;
		name = null;
		path = "";
		aNode.onTag["Property"] = (ref XNode pNode) {
			pNode.onTag["Id"] = (ref XNode n) {
				idStr = n.value;
			};
			pNode.onTag["Name"] = (ref XNode n) {
				name = n.value;
			};
			pNode.onTag["MusicPath"] = (ref XNode n) {
				path = decodePath(n.value);
			};
			pNode.parse();
		};
		aNode.parse();
		if (idStr is null) throw new AreaException("Id not found");
		if (name is null) throw new AreaException("Name not found");
		id = to!(long)(idStr);
	}
}

/// エリア。
public class Area : AbstractArea, BgImageOwner {
private:
	BgImage[] _bgImgs;
	MenuCard[] _cards;
	bool _auto = false;

public:
	static const XML_NAME = "Area";
	alias toAreaId toID;

	/// 唯一のコンストラクタ。
	this (ulong id, string name) {
		super(id, name);
	}
	@property
	protected override void delegate() changeHandler() {return super.changeHandler;}
	@property
	override void changeHandler(void delegate() change) {
		foreach (b; _bgImgs) {
			b.changeHandler = change;
		}
		foreach (c; _cards) {
			c.changeHandler = change;
		}
		super.changeHandler = change;
	}

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
	override bool canHasFireKeyCode() {return true;}
	EventTree etFromPath(size_t[] path) {
		if (path[0] == 0) {
			return trees[path[1]];
		} else {
			return cards[path[0] - 1].trees[path[1]];
		}
	}

	/// メニューカードのインデックスを交換する。
	void swapCards(int index1, int index2) {
		if (index1 != index2) changed();
		auto temp = _cards[index1];
		_cards[index1] = _cards[index2];
		_cards[index2] = temp;
	}
	/// 背景イメージのインデックスを交換する。
	void swapBacks(int index1, int index2) {
		if (index1 != index2) changed();
		auto temp = _bgImgs[index1];
		_bgImgs[index1] = _bgImgs[index2];
		_bgImgs[index2] = temp;
	}

	/// オート配置か否か。
	@property
	const
	bool spAuto() {
		return _auto;
	}
	/// ditto
	@property
	void spAuto(bool spAuto) {
		if (_auto != spAuto) changed();
		_auto = spAuto;
	}

	/// メニューカード群。
	@property
	MenuCard[] cards() {
		return _cards;
	}
	/// ditto
	@property
	const
	const(MenuCard)[] cards() {
		return _cards;
	}
	/// 背景画像群。
	@property
	BgImage[] backs() {
		return _bgImgs;
	}
	/// ditto
	@property
	const
	const(BgImage)[] backs() {
		return _bgImgs;
	}

	/// メニューカードを追加する。
	void append(MenuCard card) {
		card.changeHandler = changeHandler;
		if (useCounter) card.setUseCounter = useCounter;
		card._owner = this;
		_cards ~= card;
		changed();
	}
	/// ditto
	void insert(int index, MenuCard card) {
		if (_cards.length == index) {
			append(card);
		} else {
			card.changeHandler = changeHandler;
			if (useCounter) card.setUseCounter = useCounter;
			card._owner = this;
			_cards = _cards[0 .. index] ~ card ~ _cards[index .. $];
			changed();
		}
	}
	/// メニューカードを除去する。
	void removeCard(int index) {
		_cards[index].changeHandler = null;
		_cards[index].removeUseCounter();
		_cards[index]._owner = null;
		_cards = _cards[0 .. index] ~ _cards[index + 1 .. $];
		changed();
	}

	/// 背景画像を追加する。
	void append(BgImage back) {
		back.changeHandler = changeHandler;
		if (useCounter) back.setUseCounter = useCounter;
		back.owner = this;
		_bgImgs ~= back;
		changed();
	}
	/// ditto
	void insert(int index, BgImage back) {
		if (_bgImgs.length == index) {
			append(back);
		} else {
			back.changeHandler = changeHandler;
			if (useCounter) back.setUseCounter = useCounter;
			back.owner = this;
			_bgImgs = _bgImgs[0 .. index] ~ back ~ _bgImgs[index .. $];
			changed();
		}
	}
	/// ditto
	void set(int index, BgImage back) {
		_bgImgs[index].changeHandler = null;
		_bgImgs[index].removeUseCounter();
		_bgImgs[index].owner = null;
		back.changeHandler = changeHandler;
		if (useCounter) back.setUseCounter = useCounter;
		back.owner = this;
		_bgImgs[index] = back;
		changed();
	}
	/// 背景画像を除去する。
	void removeBgImage(int index) {
		_bgImgs[index].changeHandler = null;
		_bgImgs[index].removeUseCounter();
		_bgImgs[index].owner = null;
		_bgImgs = _bgImgs[0 .. index] ~ _bgImgs[index + 1 .. $];
		changed();
	}

	@property
	override void setUseCounter(UseCounter uc) {
		foreach (c; _cards) {
			c.setUseCounter(uc);
		}
		foreach (bg; _bgImgs) {
			bg.setUseCounter(uc);
		}
		super.setUseCounter(uc);
	}

	override void removeUseCounter() {
		foreach (c; _cards) {
			c.removeUseCounter();
		}
		foreach (bg; _bgImgs) {
			bg.removeUseCounter();
		}
		super.removeUseCounter();
	}

	@property
	const
	override string rootName() {return "Area";}

	const
	override void toNodeImpl(ref XNode e, XMLOption opt) {
		auto pNode = e.newElement("Property");
		appendProp(pNode, opt);

		BgImage.toNode(_bgImgs, e);
		auto ce = e.newElement("MenuCards");
		ce.newAttr("spreadtype", _auto ? "Auto" : "Custom");
		foreach (c; _cards) {
			c.toNode(ce, opt);
		}
		appendEventsToNode(e, opt);
	}

	/// XMLファイルからエリアデータをロードする。
	/// Params:
	/// path = XMLファイルパス。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// FileException = ファイル読込み例外発生時。
	/// XmlException = XMLパースエラー発生時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static Area loadFromXML(string path, string ver) {
		scope doc = XNode.parse(std.file.readText(path));
		if (doc.name == "Area") {
			return createFromNode(doc, ver);
		}
		throw new AreaException("File is not area");
	}

	/// XMLノードからインスタンスを生成する。
	/// Params:
	/// aNode = XMLノード。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static Area createFromNode(ref XNode aNode, string ver) {
		if (aNode.name != "Area") throw new AreaException("Node is not area: " ~ aNode.name);
		ulong id;
		string name;
		bool spAuto;
		BgImage[] bgImgs;
		MenuCard[] cards;
		EventTree[] evt;
		string path;
		aNode.onTag["MenuCards"] = (ref XNode n) {
			spAuto = n.attr("spreadtype", true) == "Auto";
			n.onTag["MenuCard"] = (ref XNode mcn) {
				cards ~= MenuCard.createFromNode(mcn, ver);
			};
			n.parse();
		};
		aNode.onTag["BgImages"] = (ref XNode n) {
			bgImgs = BgImage.bgImagesFromNode(n, ver);
		};
		aNode.onTag["Events"] = (ref XNode n) {
			evt = loadEventsFromNode(n, ver);
		};
		loadProp(aNode, id, name, path);

		auto r = new Area(id, name);
		r.spAuto = spAuto;
		foreach (c; cards) r.append(c);
		foreach (b; bgImgs) r.append(b);
		r.addAll(evt);

		return r;
	}

	/// メニューカード群をXMLデータにして返す。
	static string CtoXML(MenuCard[] cards, XMLOption opt) {
		return CtoNode(cards, opt).text;
	}
	/// ditto
	static XNode CtoNode(MenuCard[] cards, XMLOption opt) {
		return CBtoNode(cards, [], opt);
	}
	/// 背景イメージ群をXMLデータにして返す。
	static string BtoXML(BgImage[] backs) {
		return BtoNode(backs).text;
	}
	/// ditto
	static XNode BtoNode(BgImage[] backs) {
		return CBtoNode([], backs, null);
	}
	/// メニューカード群と背景イメージ群をXMLデータにして返す。
	static string CBtoXML(MenuCard[] cards, BgImage[] backs, XMLOption opt) {
		return CBtoNode(cards, backs, opt).text;
	}
	/// ditto
	static XNode CBtoNode(MenuCard[] cards, BgImage[] backs, XMLOption opt) {
		auto e = XNode.create("MenuCardsAndBgImages");
		if (cards.length > 0) {
			auto me = e.newElement("MenuCards");
			foreach (c; cards) {
				c.toNode(me, opt);
			}
		}
		if (backs.length > 0) {
			auto be = e.newElement("BgImages");
			foreach (b; backs) {
				b.toNode(be);
			}
		}
		return e;
	}

	/// XMLテキストからメニューカードと背景画像を生成する。
	/// XMLテキストはArea.CBtoXML(MenuCard, BgImages)で生成したものでなければならない。
	/// それ以外のXMLテキストを指定した場合は失敗し、falseを返す。(例外は投げない)
	/// Params:
	/// xml = XMLテキスト。
	/// Returns: 成功したか。
	/// See_Also: Area.CBtoXML(MenuCard, BgImages)
	static bool CBfromXML(string xml, out MenuCard[] cards, out BgImage[] backs) {
		try {
			scope doc = XNode.parse(xml);
			return CBfromXML(doc, cards, backs);
		} catch (Exception e) {
			debugln(e);
		}
		return false;
	}
	/// ditto
	static bool CBfromXML(ref XNode node, out MenuCard[] cards, out BgImage[] backs) {
		try {
			if (node.name == "MenuCardsAndBgImages") {
				node.onTag["MenuCards"] = (ref XNode node) {
					node.onTag["MenuCard"] = (ref XNode n) {
						cards ~= MenuCard.createFromNode(n, LATEST_VERSION);
					};
					node.parse();
				};
				node.onTag["BgImages"] = (ref XNode node) {
					node.onTag["BgImage"] = (ref XNode n) {
						backs ~= BgImage.createFromNode(n, LATEST_VERSION);
					};
					node.parse();
				};
				node.parse();
				return true;
			}
		} catch (Exception e) {
			debugln(e);
		}
		return false;
	}
	private AreaOwner _owner = null;
	@property
	package void owner(AreaOwner owner) {_owner = owner;}
	@property
	string cwxPath(bool id) {
		if (id) {
			return _owner ? cpjoinid(_owner, "area", this.id) : "";
		} else {
			return _owner ? cpjoin(_owner, "area", .cCountUntil!("a is b")(_owner.areas, this), id) : "";
		}
	}
	override
	CWXPath findCWXPath(string path) {
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		switch (cate) {
		case "menucard": {
			auto index = cpindex(path);
			if (index >= cards.length) return null;
			return cards[index].findCWXPath(cpbottom(path));
		}
		case "background": {
			auto index = cpindex(path);
			if (index >= backs.length) return null;
			return backs[index].findCWXPath(cpbottom(path));
		}
		default: break;
		}
		return super.findCWXPath(path);
	}
	@property
	override
	CWXPath[] cwxChilds() {
		CWXPath[] r;
		r ~= cast(CWXPath[]) cards;
		r ~= cast(CWXPath[]) backs;
		r ~= super.cwxChilds;
		return r;
	}
	@property
	CWXPath cwxParent() {return _owner;}
}

/// パッケージ。
public class Package : AbstractArea {
public:
	static const XML_NAME = "Package";
	alias toPackageId toID;

	/// 唯一のコンストラクタ。
	this (ulong id, string name) {
		super (id, name);
	}
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
	EventTree etFromPath(size_t[] path) {
		if (path[0] == 0) {
			return trees[path[1]];
		}
		assert (0);
	}

	override void add(EventTree evt) {
		evt.lose = false;
		evt.escape = false;
		evt.removeKeyCodesAll();
		evt.removeRoundsAll();
		super.add(evt);
	}

	@property
	const
	override string rootName() {return "Package";}
	const
	override void toNodeImpl(ref XNode e, XMLOption opt) {
		auto pNode = e.newElement("Property");
		appendProp(pNode, opt);
		appendEventsToNode(e, opt);
	}

	/// XMLファイルからパッケージデータをロードする。
	/// Params:
	/// path = XMLファイルパス。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// FileException = ファイル読込み例外発生時。
	/// XmlException = XMLパースエラー発生時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static Package loadFromXML(string path, string ver) {
		scope doc = XNode.parse(std.file.readText(path));
		if (doc.name == "Package") {
			return createFromNode(doc, ver);
		}
		throw new AreaException("File is not package");
	}

	/// XMLノードを元にインスタンスを生成する。
	/// Params:
	/// aNode = XMLノード。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static Package createFromNode(ref XNode aNode, string ver) {
		if (aNode.name != "Package") throw new AreaException("Node is not package: " ~ aNode.name);
		ulong id;
		string name;
		string path;
		EventTree[] evt;
		aNode.onTag["Events"] = (ref XNode node) {
			evt = loadEventsFromNode(node, ver);
		};
		loadProp(aNode, id, name, path);
		auto r = new Package(id, name);
		r.addAll(evt);

		return r;
	}
	private PackageOwner _owner = null;
	@property
	package void owner(PackageOwner owner) {_owner = owner;}
	@property
	string cwxPath(bool id) {
		if (id) {
			return _owner ? cpjoinid(_owner, "package", this.id) : "";
		} else {
			return _owner ? cpjoin(_owner, "package", .cCountUntil!("a is b")(_owner.packages, this), id) : "";
		}
	}
	@property
	CWXPath cwxParent() {return _owner;}
}

/// バトル。
public class Battle : AbstractArea, IPathUser {
private:
	EnemyCard[] _cards;
	bool _auto;
	PathUser _music;
public:
	static const XML_NAME = "Battle";
	alias toBattleId toID;

	/// 唯一のコンストラクタ。
	/// Params:
	///  music = BGMのファイルパス。
	this (ulong id, string name, string music) {
		super(id, name);
		_music = new PathUser(this);
		_music.path = music;
	}
	@property
	protected override void delegate() changeHandler() {return super.changeHandler;}
	@property
	override void changeHandler(void delegate() change) {
		foreach (c; _cards) {
			c.changeHandler = change;
		}
		super.changeHandler = change;
	}
	@property
	const
	override bool canHasFireLose() {return true;}
	@property
	const
	override bool canHasFireEscape() {return true;}
	@property
	const
	override bool canHasFireEveryRound() {return true;}
	@property
	const
	override bool canHasFireRound0() {return true;}
	@property
	const
	override bool canHasFireRound() {return true;}
	@property
	const
	override bool canHasFireKeyCode() {return true;}
	EventTree etFromPath(size_t[] path) {
		if (path[0] == 0) {
			return trees[path[1]];
		} else {
			return cards[path[0] - 1].trees[path[1]];
		}
	}

	/// BGMのファイルパス。
	@property
	void music(string music) {
		if (_music.path != music) changed();
		_music.path = music;
	}
	/// ditto
	@property
	const
	string music() {
		return _music.path;
	}

	/// エネミーカードを追加する。
	void append(EnemyCard card) {
		card.changeHandler = changeHandler;
		if (useCounter) card.setUseCounter = useCounter;
		card._owner = this;
		_cards ~= card;
		changed();
	}
	/// ditto
	void insert(int index, EnemyCard card) {
		if (_cards.length == index) {
			append(card);
		} else {
			card.changeHandler = changeHandler;
			if (useCounter) card.setUseCounter = useCounter;
			card._owner = this;
			_cards = _cards[0 .. index] ~ card ~ _cards[index .. $];
			changed();
		}
	}
	/// エネミーカードを除去する。
	void removeCard(int index) {
		_cards[index].changeHandler = null;
		_cards[index].removeUseCounter();
		_cards[index]._owner = null;
		_cards = _cards[0 .. index] ~ _cards[index + 1 .. $];
		changed();
	}

	/// エネミーカードのインデックスを交換する。
	void swapCards(int index1, int index2) {
		if (index1 != index2) changed();
		auto temp = _cards[index1];
		_cards[index1] = _cards[index2];
		_cards[index2] = temp;
	}
	/// エネミーカード群。
	@property
	EnemyCard[] cards() {
		return _cards;
	}

	/// オート配置か否か。
	@property
	const
	bool spAuto() {
		return _auto;
	}
	/// ditto
	@property
	void spAuto(bool spAuto) {
		if (_auto != spAuto) changed();
		_auto = spAuto;
	}

	@property
	override void setUseCounter(UseCounter uc) {
		foreach (c; _cards) {
			c.setUseCounter(uc);
		}
		_music.setUseCounter(uc);
		super.setUseCounter(uc);
	}

	override void removeUseCounter() {
		foreach (c; _cards) {
			c.removeUseCounter();
		}
		_music.removeUseCounter();
		super.removeUseCounter();
	}

	override void change(PathId id) {
		_music.change(id);
	}

	@property
	const
	override string rootName() {return "Battle";}
	const
	override void toNodeImpl(ref XNode e, XMLOption opt) {
		auto pe = e.newElement("Property");
		appendProp(pe, opt);
		pe.newElement("MusicPath", encodePath(_music.path));
	
		auto ce = e.newElement("EnemyCards");
		ce.newAttr("spreadtype", _auto ? "Auto" : "Custom");
		foreach (c; _cards) {
			c.toNode(ce, opt);
		}

		appendEventsToNode(e, opt);
	}

	/// XMLファイルからバトルデータをロードする。
	/// Params:
	/// path = XMLファイルパス。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// FileException = ファイル読込み例外発生時。
	/// XmlException = XMLパースエラー発生時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static Battle loadFromXML(string path, string ver) {
		scope doc = XNode.parse(std.file.readText(path));
		if (doc.name == "Battle") {
			return createFromNode(doc, ver);
		}
		throw new AreaException("File is not battle");
	}

	/// XMLノードを元にインスタンスを生成する。
	/// Params:
	/// aNode = XMLノード。
	/// Throws:
	/// AreaException = XML内のデータ不足時。
	/// IllegalArgmentException = XML文書内で数値であるべきデータが数値でない。
	static Battle createFromNode(ref XNode aNode, string ver) {
		if (aNode.name != "Battle") throw new AreaException("Node is not battle: " ~ aNode.name);
		ulong id;
		string name;
		string music;
		bool spAuto;
		EnemyCard[] cards;
		EventTree[] evt;
		aNode.onTag["EnemyCards"] = (ref XNode node) {
			spAuto = node.attr("spreadtype", false) == "Auto";
			node.onTag["EnemyCard"] = (ref XNode ecn) {
				cards ~= EnemyCard.createFromNode(ecn, ver);
			};
			node.parse();
		};
		aNode.onTag["Events"] = (ref XNode node) {
			evt = loadEventsFromNode(node, ver);
		};
		loadProp(aNode, id, name, music);
		auto r = new Battle(id, name, music);
		r.addAll(evt);
		foreach (c; cards) r.append(c);
		r.spAuto = spAuto;

		return r;
	}

	/// エネミーカード群をXMLデータにして返す。
	static string CtoXML(EnemyCard[] cards, XMLOption opt) {
		return CtoNode(cards, opt).text;
	}
	/// ditto
	static XNode CtoNode(EnemyCard[] cards, XMLOption opt) {
		auto doc = XNode.create("EnemyCards");
		foreach (c; cards) {
			c.toNode(doc, opt);
		}
		return doc;
	}

	/// XMLテキストからエネミーカードを生成する。
	/// XMLテキストはBattle.CtoXML(EnemyCard)で生成したものでなければならない。
	/// それ以外のXMLテキストを指定した場合は失敗し、falseを返す。(例外は投げない)
	/// Params:
	/// xml = XMLテキスト。
	/// Returns: 成功したか。
	/// See_Also: Battle.CtoXML(EnemyCard)
	static bool CfromXML(string xml, out EnemyCard[] cards) {
		try {
			scope doc = XNode.parse(xml);
			return CfromXML(doc, cards);
		} catch (Exception e) {
			debugln(e);
		}
		return false;
	}
	/// ditto
	static bool CfromXML(ref XNode node, out EnemyCard[] cards) {
		try {
			if (node.name == "EnemyCards") {
				node.onTag["EnemyCard"] = (ref XNode n) {
					cards ~= EnemyCard.createFromNode(n, LATEST_VERSION);
				};
				node.parse();
				return true;
			}
		} catch (Exception e) {
			debugln(e);
		}
		return false;
	}
	private BattleOwner _owner = null;
	@property
	package void owner(BattleOwner owner) {_owner = owner;}
	@property
	string cwxPath(bool id) {
		if (id) {
			return _owner ? cpjoinid(_owner, "battle", this.id) : "";
		} else {
			return _owner ? cpjoin(_owner, "battle", .cCountUntil!("a is b")(_owner.battles, this), id) : "";
		}
	}
	override
	CWXPath findCWXPath(string path) {
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		switch (cate) {
		case "enemycard": {
			auto index = cpindex(path);
			if (index >= cards.length) return null;
			return cards[index].findCWXPath(cpbottom(path));
		}
		default: break;
		}
		return super.findCWXPath(path);
	}
	@property
	override
	CWXPath[] cwxChilds() {
		CWXPath[] r;
		r ~= cast(CWXPath[]) cards;
		r ~= super.cwxChilds;
		return r;
	}
	@property
	CWXPath cwxParent() {return _owner;}
}
