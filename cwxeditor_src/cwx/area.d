
module cwx.area;

import cwx.utils;
import cwx.event;
import cwx.usecounter;
import cwx.background;
import cwx.xml;
import cwx.card;
import cwx.path;
import cwx.system;
import cwx.types;
import cwx.textholder;

import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.math;
import std.string;
import std.traits;

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
/// scenarioPath = シナリオのパス。
/// sameSummary = 生成するエリアが元々属していたシナリオが、scenarioPathが指すシナリオと同一であるか。
/// Returns: エリア。エリアでない場合はnull。
/// Throws:
/// XmlException = パース失敗。
/// IllegalArgumentException = 数値であるべきデータが数値でない。
AbstractArea[] createAreasFromNode(ref XNode e, string scenarioPath, out bool sameSummary, out bool fromTable, in XMLInfo ver) { mixin(S_TRACE);
	try { mixin(S_TRACE);
		auto sPath = e.attr("scenarioPath", false);
		sameSummary = scenarioPath != "" && sPath != "" && .cfnmatch(.nabs(scenarioPath), .nabs(scenarioPath));
		AbstractArea[] areas;
		void load(ref XNode e) { mixin(S_TRACE);
			switch (e.name) {
			case "Area": areas ~= Area.createFromNode(e, ver); break;
			case "Battle": areas ~= Battle.createFromNode(e, ver); break;
			case "Package": areas ~= Package.createFromNode(e, ver); break;
			default: break;
			}
		}
		switch (e.name) {
		case "Table":
			fromTable = true;
			e.onTag[null] = &load;
			e.parse();
			break;
		default:
			fromTable = false;
			load(e);
			break;
		}
		return areas;
	} catch (Exception e) {
		printStackTrace();
		debugln(e);
		return [];
	}
}

/// メニューカードとエネミーカードの親クラス。
public abstract class AbstractSpCard : AbstractEventTreeOwner {
private:
	int _x, _y;
	uint _scale;
	int _layer = LAYER_MENU_CARD;
	FlagUser _user;
	CardGroupUser _cardGroup;
	int _animationSpeed = -1;

public:

	/// 唯一のコンストラクタ。
	this (string flag, int x, int y, uint scale, int layer, string cardGroup, int animationSpeed) { mixin(S_TRACE);
		_user = new FlagUser(this);
		_user.flag = flag;
		_x = x;
		_y = y;
		_scale = scale;
		_layer = layer;
		_cardGroup = new CardGroupUser(this);
		_cardGroup.cardGroup = cardGroup;
		_animationSpeed = animationSpeed;
	}
	/// このカードの所属先を返す。
	@property
	inout
	inout(AbstractArea) abstractOwner();

	/// ディープコピーを返す。
	@property
	const
	AbstractSpCard dup();

	@property
	const
	override bool canHasFireLose() { return false; }
	@property
	const
	override bool canHasFireEscape() { return false; }
	@property
	const
	override bool canHasFireEveryRound() { return false; }
	@property
	const
	override bool canHasFireRoundEnd() { return false; }
	@property
	const
	override bool canHasFireRound0() { return false; }
	@property
	const
	override bool canHasFireRound() { return false; }
	@property
	const
	override bool canHasFireKeyCode() { return true; }

	/// 表示フラグ。
	@property
	void flag(string flag) { mixin(S_TRACE);
		if (_user.flag != flag) changed();
		_user.flag = flag;
	}
	/// ditto
	@property
	const
	string flag() { mixin(S_TRACE);
		return _user.flag;
	}
	/// X座標。
	@property
	const
	int x() { mixin(S_TRACE);
		return _x;
	}
	/// ditto
	@property
	void x(int x) { mixin(S_TRACE);
		if (_x != x) changed();
		_x = x;
	}
	/// Y座標。
	@property
	const
	int y() { mixin(S_TRACE);
		return _y;
	}
	/// ditto
	@property
	void y(int y) { mixin(S_TRACE);
		if (_y != y) changed();
		_y = y;
	}
	/// スケール(%)。
	@property
	const
	uint scale() { mixin(S_TRACE);
		return _scale;
	}
	/// ditto
	@property
	void scale(uint scale) { mixin(S_TRACE);
		if (_scale != scale) { mixin(S_TRACE);
			changed();
			_scale = scale;
		}
	}

	/// セルの表示レイヤ。
	// 値が大きいほど手前に表示される。
	// デフォルト値はLAYER_MENU_CARD。
	@property
	const
	int layer() { return _layer; }
	/// ditto
	@property
	void layer(int v) { mixin(S_TRACE);
		if (_layer != v) changed();
		_layer = v;
	}

	/// イベントからの操作で指定するためのカードグループ名。
	@property
	void cardGroup(string cardGroup) { mixin(S_TRACE);
		if (_cardGroup.cardGroup != cardGroup) changed();
		_cardGroup.cardGroup = cardGroup;
	}
	/// ditto
	@property
	const
	string cardGroup() { mixin(S_TRACE);
		return _cardGroup.cardGroup;
	}

	/// アニメーション速度(Wsn.4)。0～10で、小さい方が速い。
	/// -1ならエンジン設定に従う。
	@property
	const
	int animationSpeed() { return _animationSpeed; }
	/// ditto
	@property
	void animationSpeed(int v) { mixin(S_TRACE);
		if (_animationSpeed != v) changed();
		_animationSpeed = v;
	}

	/// このカードと強く関係するリソースを返す。
	/// そのようなリソースが無い場合はnullを返す。
	inout
	inout(CWXPath) connectedResource(inout(CastOwner) summ) { mixin(S_TRACE);
		return null;
	}

	/// このカードと強く関係するファイルパスを返す。
	/// そのようなファイルが無い場合は""を返す。
	@property
	const
	string connectedFile() { mixin(S_TRACE);
		return "";
	}

	@property
	override void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		_user.setUseCounter(uc);
		_cardGroup.setUseCounter(uc);
		super.setUseCounter(uc);
	}
	override void removeUseCounter() { mixin(S_TRACE);
		_user.removeUseCounter();
		_cardGroup.removeUseCounter();
		super.removeUseCounter();
	}

	/// 指定されたノードにProperty情報を追加する。
	const
	protected void appendProp(ref XNode pNode, XMLOption opt) { mixin(S_TRACE);
		assert (pNode.name == "Property", pNode.name ~ " != Property");
		pNode.newElement("Flag", _user.flag);
		auto ln = pNode.newElement("Location");
		ln.newAttr("left", _x);
		ln.newAttr("top", _y);
		pNode.newElement("Size").newAttr("scale", to!(string)(_scale) ~ "%");
		if (layer != LAYER_MENU_CARD) pNode.newElement("Layer", layer);
		if (cardGroup != "") pNode.newElement("CardGroup", cardGroup);
		if (animationSpeed != -1) pNode.newElement("DealingSpeed", animationSpeed);
	}
	/// 指定されたノードからProperty情報を読み出す。
	protected static void loadProp(ref XNode pNode, out string flag, out int x, out int y, out uint scale, out int layer, out string cardGroup, out int animationSpeed) { mixin(S_TRACE);
		flag = "";
		x = 0;
		y = 0;
		scale = 100;
		layer = LAYER_MENU_CARD;
		cardGroup = "";
		animationSpeed = -1;
		assert (pNode.name == "Property", pNode.name ~ " != Property");
		pNode.onTag["Flag"] = (ref XNode n) { flag = n.value; };
		pNode.onTag["Location"] = (ref XNode n) { mixin(S_TRACE);
			x = n.attr!(int)("left", true);
			y = n.attr!(int)("top", true);
		};
		pNode.onTag["Size"] = (ref XNode n) { mixin(S_TRACE);
			string val = n.attr("scale", true);
			if (val.length < 2u) throw new Exception("scale error: " ~ val);
			if (val[$ - 1] == '%') { mixin(S_TRACE);
				val = val[0 .. $ - 1];
			}
			scale = to!(uint)(val);
		};
		pNode.onTag["Layer"] = (ref XNode n) { mixin(S_TRACE);
			layer = n.valueTo!int();
		};
		pNode.onTag["CardGroup"] = (ref XNode n) { mixin(S_TRACE);
			cardGroup = n.value;
		};
		pNode.onTag["DealingSpeed"] = (ref XNode n) { mixin(S_TRACE);
			if (n.value == "Default") { mixin(S_TRACE);
				animationSpeed = -1;
			} else { mixin(S_TRACE);
				animationSpeed = n.valueTo!int;
			}
		};
		pNode.parse();
	}
}

/// バトルに配置するカード。
public class EnemyCard : AbstractSpCard {
private:
	Battle _owner = null;
	bool[ActionCardType] _actions; // Wsn.4
	CastUser _user;
	bool _isOverrideName = false;
	SimpleTextHolder _overrideName;
	bool _isOverrideImage = false;
	CardImage[] _overrideImages;
public:
	/// XML要素名。
	static immutable XML_NAME = "EnemyCard";
	/// XML要素名(複数)。
	static immutable XML_NAME_M = "EnemyCards";

	/// 唯一のコンストラクタ。
	this (ulong id, in bool[ActionCardType] actions, string flag, int x, int y, uint scale,
			int layer, string cardGroup, int animationSpeed,
			bool isOverrideName, string overrideName, bool isOverrideImage, in CardImage[] overrideImages) { mixin(S_TRACE);
		super (flag, x, y, scale, layer, cardGroup, animationSpeed);
		_user = new CastUser(this);
		_user.casts = id;
		this.actions = actions;
		_isOverrideName = isOverrideName;
		_overrideName = new SimpleTextHolder;
		_overrideName.changeHandler = &changed;
		_overrideName.text = overrideName;
		_overrideName.owner = this;
		_isOverrideImage = isOverrideImage;
		this.overrideImages = overrideImages;
	}
	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		return _owner ? cpjoin(_owner, "enemycard", .cCountUntil!("a is b")(_owner.cards, this), id) : "";
	}
	@property
	CWXPath cwxParent() { return _owner; }

	@property
	const
	override
	AbstractSpCard dup() { mixin(S_TRACE);
		auto r = new EnemyCard(id, actions, flag, x, y, scale, layer, cardGroup, animationSpeed,
			isOverrideName, overrideName, isOverrideImage, overrideImages);
		r.deepCopyEventTreeOwner(this);
		return r;
	}

	@property
	override size_t[] areaPath() { mixin(S_TRACE);
		if (_owner) { mixin(S_TRACE);
			return [.cCountUntil!("a is b")(_owner.cards, this) + 2];
		} else { mixin(S_TRACE);
			return [];
		}
	}
	@property
	override
	inout
	inout(AbstractArea) abstractOwner() { mixin(S_TRACE);
		return _owner;
	}
	/// このカードの所属先を返す。
	@property
	inout
	inout(Battle) owner() { mixin(S_TRACE);
		return _owner;
	}

	/// 各種アクションカードを所持するか(Wsn.4)。
	@property
	const
	const(bool[ActionCardType]) actions() { mixin(S_TRACE);
		return _actions;
	}
	/// ditto
	@property
	void actions(in bool[ActionCardType] actions) { mixin(S_TRACE);
		bool[ActionCardType] actions2;
		foreach (type, value; actions) { mixin(S_TRACE);
			auto defValue = type !is ActionCardType.RunAway;
			if (defValue != value) { mixin(S_TRACE);
				actions2[type] = value;
			}
		}
		if (_actions == actions2) return;
		changed();
		_actions = null;
		foreach (key, value; actions2) action(key, value);
	}
	/// ditto
	const
	bool action(ActionCardType type) { return _actions.get(type, type !is ActionCardType.RunAway); }
	/// ditto
	void action(ActionCardType type, bool value) { mixin(S_TRACE);
		if (action(type) is value) return;
		changed();
		auto defValue = type !is ActionCardType.RunAway;
		if (defValue != value) { mixin(S_TRACE);
			_actions[type] = value;
		} else if (type in _actions) { mixin(S_TRACE);
			_actions.remove(type);
		}
	}

	/// キャストID。
	@property
	const
	ulong id() { mixin(S_TRACE);
		return _user.casts;
	}
	/// ditto
	@property
	void id(ulong id) { mixin(S_TRACE);
		if (_user.casts != id) changed();
		_user.casts = id;
	}

	/// 名前を上書きをするか(Wsn.4)。
	@property
	const
	bool isOverrideName() { mixin(S_TRACE);
		return _isOverrideName;
	}
	/// ditto
	@property
	void isOverrideName(bool isOverrideName) { mixin(S_TRACE);
		if (_isOverrideName != isOverrideName) changed();
		_isOverrideName = isOverrideName;
	}
	/// 上書きする名前(Wsn.4)。
	@property
	const
	string overrideName() { mixin(S_TRACE);
		return _overrideName.text;
	}
	/// ditto
	@property
	void overrideName(string overrideName) { mixin(S_TRACE);
		if (_overrideName.text != overrideName) changed();
		_overrideName.text = overrideName;
	}

	/// 上書き名内で使用されている状態変数のパス。
	@property
	const
	string[] flagsInText() { return _overrideName.flagsInText; }
	/// ditto
	@property
	const
	string[] stepsInText() { return _overrideName.stepsInText; }
	/// ditto
	@property
	const
	string[] variantsInText() { return _overrideName.variantsInText; }

	/// イメージを上書きをするか(Wsn.4)。
	@property
	const
	bool isOverrideImage() { mixin(S_TRACE);
		return _isOverrideImage;
	}
	/// ditto
	@property
	void isOverrideImage(bool isOverrideImage) { mixin(S_TRACE);
		if (_isOverrideImage != isOverrideImage) changed();
		_isOverrideImage = isOverrideImage;
	}
	/// 上書きするイメージ(Wsn.4)。
	@property
	const
	CardImage[] overrideImages() { mixin(S_TRACE);
		return .map!(a => new CardImage(cast(CWXPath)null, a))(_overrideImages).array();
	}
	/// ditto
	@property
	void overrideImages(in CardImage[] paths) { mixin(S_TRACE);
		if (this.overrideImages == paths) return;
		changed();
		foreach (u; _overrideImages) { mixin(S_TRACE);
			u.removeUseCounter();
		}
		_overrideImages = [];
		foreach (path; paths) { mixin(S_TRACE);
			auto u = new CardImage(this, path);
			if (useCounter) u.setUseCounter(useCounter);
			_overrideImages ~= u;
		}
	}

	@property
	override
	const
	string connectedFile() { mixin(S_TRACE);
		foreach (path; _overrideImages) { mixin(S_TRACE);
			if (path.path != "" && !path.path.isBinImg) return path.path;
		}
		return "";
	}

	override
	inout
	inout(CWXPath) connectedResource(inout(CastOwner) summ) { mixin(S_TRACE);
		return summ.cwCast(id);
	}

	@property
	override void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		_user.setUseCounter(uc);
		_overrideName.setUseCounter(uc);
		foreach (path; _overrideImages) { mixin(S_TRACE);
			path.setUseCounter(uc);
		}
		super.setUseCounter(uc);
	}
	override void removeUseCounter() { mixin(S_TRACE);
		_user.removeUseCounter();
		_overrideName.removeUseCounter();
		foreach (path; _overrideImages) { mixin(S_TRACE);
			path.removeUseCounter();
		}
		super.removeUseCounter();
	}

	static EnemyCard[] createCardsFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		assert (node.name == CastCard.XML_NAME_M);
		EnemyCard[] cards;
		node.onTag["CastCard"] = (ref XNode cNode) { mixin(S_TRACE);
			cNode.onTag["Property"] = (ref XNode pNode) { mixin(S_TRACE);
				string idStr = pNode.childText("Id", false);
				if (idStr) { mixin(S_TRACE);
					cards ~= new EnemyCard(to!(ulong)(idStr), (bool[ActionCardType]).init, "", 0, 0, 100, LAYER_MENU_CARD, "", -1, false, "", false, []);
				}
			};
			cNode.parse();
		};
		node.parse();
		return cards;
	}

	/// XMLノードにして返す。
	const
	XNode toNode(XMLOption opt) { mixin(S_TRACE);
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e, opt);
		return e;
	}
	/// XMLノード(EnemyCards)にインスタンスのデータを追加する。
	const
	XNode toNode(ref XNode node, XMLOption opt) { mixin(S_TRACE);
		assert (node.name == XML_NAME_M, node.name ~ " != EnemyCards");
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e, opt);
		return e;
	}
	const
	private void toNodeImpl(ref XNode e, XMLOption opt) { mixin(S_TRACE);
		auto pe = e.newElement("Property");
		pe.newElement("Id", _user.casts);
		if (isOverrideName || overrideName.length) { mixin(S_TRACE);
			auto ne = pe.newElement("Name", overrideName);
			ne.newAttr("override", fromBool(isOverrideName));
		}
		if (isOverrideImage || _overrideImages.length) { mixin(S_TRACE);
			auto cie = CardImage.toNode(pe, _overrideImages, false, true);
			cie.newAttr("override", fromBool(isOverrideImage));
		}
		auto allActions = true;
		foreach (type, value; actions) { mixin(S_TRACE);
			if (type is ActionCardType.RunAway) continue;
			if (value) continue;
			allActions = false;
			break;
		}
		if (allActions || (opt && !opt.isTargetVersion("4"))) { mixin(S_TRACE);
			// Wsn.3以前のデータバージョンでは必ずescape属性を生成する
			e.newAttr("escape", fromBool(actions.get(ActionCardType.RunAway, false)));
		}
		if (!allActions) { mixin(S_TRACE);
			auto ae = pe.newElement("Actions");
			foreach (type, value; actions) { mixin(S_TRACE);
				auto defValue = type !is ActionCardType.RunAway;
				if (value !is defValue) { mixin(S_TRACE);
					auto ae2 = ae.newElement("Action", fromBool(value));
					ae2.newAttr("id", cast(int)type);
				}
			}
		}
		appendProp(pe, opt);
		appendEventsToNode(e, opt);
	}
	/// XMLノード(EnemyCard)からインスタンスを生成。
	/// Throws:
	/// AreaException = nodeがMenuCardでない。またはデータが不足している。
	/// IllegalArgmentException = 数値であるべきデータが数値でない。
	static EnemyCard createFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		if (node.name != XML_NAME) throw new AreaException("Node is not EnemyCard");

		bool getId = false;

		long id;
		string flag = "";
		int x = 0, y = 0;
		uint scale = 100;
		int layer = LAYER_MENU_CARD;
		string cardGroup = "";
		int animationSpeed = -1;
		bool isOverrideName = false;
		string overrideName = "";
		bool isOverrideImage = false;
		CardImage[] overrideImages = [];
		bool[ActionCardType] actions;
		EventTree[] evt;

		auto escStr = node.attr("escape", false);
		if (escStr && escStr != "") actions[ActionCardType.RunAway] = parseBool(escStr);
		node.onTag["Property"] = (ref XNode pNode) { mixin(S_TRACE);
			pNode.onTag["Id"] = (ref XNode n) { mixin(S_TRACE);
				id = to!(ulong)(n.value);
				getId = true;
			};
			pNode.onTag["Name"] = (ref XNode n) { mixin(S_TRACE);
				overrideName = n.value;
				isOverrideName = n.attr("override", false, false);
			};
			CardImage.setOnTag(pNode, overrideImages, isOverrideImage, false);
			pNode.onTag["Actions"] = (ref XNode n) { mixin(S_TRACE);
				if (n.name != "Action") return;
				actions[cast(ActionCardType)(n.attr!int("type", true))] = parseBool(n.text);
			};
			loadProp(pNode, flag, x, y, scale, layer, cardGroup, animationSpeed);
		};
		node.onTag["Events"] = (ref XNode node) { mixin(S_TRACE);
			evt = loadEventsFromNode(node, ver);
		};
		node.parse();
		if (!getId) throw new AreaException("EnemyCard ID not found");
		auto r = new EnemyCard(id, actions, flag, x, y, scale, layer, cardGroup, animationSpeed,
			isOverrideName, overrideName, isOverrideImage, overrideImages);
		r.addAll(evt);

		return r;
	}
}

/// エリアに配置するカード。
public class MenuCard : AbstractSpCard {
private:
	Area _owner;
	SimpleTextHolder _name;
	string _desc;
	CardImage[] _paths;
	bool _expandSPChars = false;

public:
	/// XML要素名。
	static immutable XML_NAME = "MenuCard";
	/// XML要素名(複数)。
	static immutable XML_NAME_M = "MenuCards";

	/// 唯一のコンストラクタ。
	/// Params:
	/// name = カード名。
	/// expandSPChars = 特殊文字を展開する(Wsn.4)。
	/// paths = カード画像。
	/// desc = 解説。無しの場合は""。
	/// flag = フラグ。無しの場合は""。
	/// x = X座標。
	/// y = Y座標。
	/// scale = スケール(%)。
	/// layer = 表示レイヤ。
	/// cardGroup = 所属カードグループ。
	/// animationSpeed = アニメーション速度(最速0～最遅10)。-1ならエンジン設定に従う。
	this (string name, bool expandSPChars, in CardImage[] paths, string desc, string flag,
			int x, int y, int scale, int layer, string cardGroup, int animationSpeed) { mixin(S_TRACE);
		super (flag, x, y, scale, layer, cardGroup, animationSpeed);
		this.paths = paths;
		_name = new SimpleTextHolder;
		_name.changeHandler = &changed;
		_name.text = name;
		_name.owner = this;
		_expandSPChars = expandSPChars;
		_desc = desc;
	}
	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		return _owner ? cpjoin(_owner, "menucard", .cCountUntil!("a is b")(_owner.cards, this), id) : "";
	}
	@property
	CWXPath cwxParent() { return _owner; }

	@property
	const
	override
	AbstractSpCard dup() { mixin(S_TRACE);
		auto r = new MenuCard(name, expandSPChars, paths, desc, flag, x, y, scale, layer, cardGroup, animationSpeed);
		r.deepCopyEventTreeOwner(this);
		return r;
	}

	@property
	override size_t[] areaPath() { mixin(S_TRACE);
		if (_owner) { mixin(S_TRACE);
			return [.cCountUntil!("a is b")(_owner.cards, this) + 2];
		} else { mixin(S_TRACE);
			return [];
		}
	}
	@property
	override
	inout
	inout(AbstractArea) abstractOwner() { mixin(S_TRACE);
		return _owner;
	}
	/// このカードの所属先を返す。
	@property
	inout
	inout(Area) owner() { mixin(S_TRACE);
		return _owner;
	}

	/// カード名。
	@property
	const
	string name() { mixin(S_TRACE);
		return _name.text;
	}
	/// ditto
	@property
	void name(string name) { mixin(S_TRACE);
		if (_name.text != name) changed();
		_name.text = name;
	}

	/// 特殊文字を展開するか(Wsn.4)。
	@property
	const
	bool expandSPChars() { return _expandSPChars; }
	/// ditto
	@property
	void expandSPChars(bool val) { mixin(S_TRACE);
		if (val != _expandSPChars) { mixin(S_TRACE);
			changed();
			_expandSPChars = val;
			if (_expandSPChars && useCounter) { mixin(S_TRACE);
				_name.setUseCounter(useCounter);
			} else { mixin(S_TRACE);
				_name.removeUseCounter();
			}
		}
	}

	/// 名前で使用されている状態変数のパス。
	@property
	const
	string[] flagsInText() { return expandSPChars ? _name.flagsInText : []; }
	/// ditto
	@property
	const
	string[] stepsInText() { return expandSPChars ? _name.stepsInText : []; }
	/// ditto
	@property
	const
	string[] variantsInText() { return expandSPChars ? _name.variantsInText : []; }

	/// 説明。
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

	/// 画像ファイルパス。
	@property
	const
	CardImage[] paths() { mixin(S_TRACE);
		return .map!(a => new CardImage(cast(CWXPath)null, a))(_paths).array();
	}
	/// ditto
	@property
	void paths(in CardImage[] paths) { mixin(S_TRACE);
		if (this.paths == paths) return;
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

	@property
	override
	const
	string connectedFile() { mixin(S_TRACE);
		foreach (path; _paths) { mixin(S_TRACE);
			if (path.path != "" && !path.path.isBinImg) return path.path;
		}
		return "";
	}

	@property
	override void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		foreach (path; _paths) { mixin(S_TRACE);
			path.setUseCounter(uc);
		}
		if (expandSPChars) { mixin(S_TRACE);
			_name.setUseCounter(uc);
		}
		super.setUseCounter(uc);
	}
	override void removeUseCounter() { mixin(S_TRACE);
		foreach (path; _paths) { mixin(S_TRACE);
			path.removeUseCounter();
		}
		_name.removeUseCounter();
		super.removeUseCounter();
	}

	/// メニューカード以外のカードデータからメニューカードを生成する。
	static MenuCard[] createFromCardNode(ref XNode node, bool copyDesc, in XMLInfo ver) { mixin(S_TRACE);
		MenuCard parse(ref XNode node) { mixin(S_TRACE);
			auto pNode = node.child("Property", false);
			if (!pNode.valid) return null;
			auto create = false;
			auto name = "";
			auto desc = "";
			bool expandSPChars = false;
			CardImage[] paths;
			pNode.onTag["Name"] = (ref XNode node) { mixin(S_TRACE);
				name = node.value;
				create = true;
			};
			CardImage.setOnTag(pNode, paths, false);
			if (copyDesc) { mixin(S_TRACE);
				pNode.onTag["Description"] = (ref XNode node) { mixin(S_TRACE);
					desc = decodeLf2(node.value);
				};
			}
			pNode.parse();
			if (!create) return null;
			return new MenuCard(name, expandSPChars, paths, desc, "", 0, 0, 100, LAYER_MENU_CARD, "", -1);
		}
		auto pNode = node.child("Property", false);
		if (pNode.valid) { mixin(S_TRACE);
			auto card = parse(node);
			return card ? [card] : [];
		} else { mixin(S_TRACE);
			MenuCard[] r;
			node.onTag[null] = (ref XNode node) { mixin(S_TRACE);
				auto card = parse(node);
				if (card) r ~= card;
			};
			node.parse();
			return r;
		}
	}

	/// XMLノードにして返す。
	const
	XNode toNode(XMLOption opt) { mixin(S_TRACE);
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e, opt);
		return e;
	}
	/// XMLノード(MenuCards)にインスタンスのデータを追加する。
	const
	XNode toNode(ref XNode node, XMLOption opt) { mixin(S_TRACE);
		assert (node.name == XML_NAME_M, node.name ~ " != MenuCards");
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e, opt);
		return e;
	}
	const
	private void toNodeImpl(ref XNode e, XMLOption opt) { mixin(S_TRACE);
		auto pNode = e.newElement("Property");
		auto nNode = pNode.newElement("Name", name);
		if (expandSPChars) nNode.newAttr("spchars", expandSPChars);
		CardImage.toNode(pNode, _paths);
		pNode.newElement("Description", encodeLf(_desc));
		appendProp(pNode, opt);
		appendEventsToNode(e, opt);
	}

	/// XMLノード(MenuCard)からインスタンスを生成。
	/// Throws:
	/// AreaException = nodeがMenuCardでない。またはデータが不足している。
	/// IllegalArgmentException = 数値であるべきデータが数値でない。
	static MenuCard createFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		if (node.name != XML_NAME) throw new AreaException("Node is not MenuCard");

		string name = null;
		bool expandSPChars = false;
		CardImage[] paths;
		string desc = "";
		string flag = "";
		int x = 0, y = 0;
		uint scale = 100;
		int layer = LAYER_MENU_CARD;
		string cardGroup = "";
		int animationSpeed = -1;
		EventTree[] evt;

		node.onTag["Property"] = (ref XNode pNode) { mixin(S_TRACE);
			pNode.onTag["Name"] = (ref XNode n) { mixin(S_TRACE);
				name = n.value;
				expandSPChars = n.attr!bool("spchars", false, false);
			};
			CardImage.setOnTag(pNode, paths, false);
			pNode.onTag["Description"] = (ref XNode n) { desc = decodeLf2(n.value); };
			loadProp(pNode, flag, x, y, scale, layer, cardGroup, animationSpeed);
		};
		node.onTag["Events"] = (ref XNode node) { mixin(S_TRACE);
			evt = loadEventsFromNode(node, ver);
		};
		node.parse();
		if (name is null) name = "";
		auto r = new MenuCard(name, expandSPChars, paths, desc, flag, x, y, scale, layer, cardGroup, animationSpeed);
		r.addAll(evt);

		return r;
	}
}

/// エリア・パッケージ・バトルの親クラス。
public abstract class AbstractArea : AbstractEventTreeOwner {
	ulong _id;
	string _name;
	bool _changed = false;
public:
	/// 唯一のコンストラクタ。
	this (ulong id, string name) { mixin(S_TRACE);
		_id = id;
		_name = name;
	}

	/// 変更を通知する。
	override void changed() { mixin(S_TRACE);
		if (changeHandler) { mixin(S_TRACE);
			_changed = true;
			super.changed();
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

	/// ディープコピーを返す。
	@property
	const
	abstract AbstractArea dup();

	/// エリアID。
	@property
	const
	ulong id() { mixin(S_TRACE);
		return _id;
	}
	/// ditto
	@property
	void id(ulong id) { mixin(S_TRACE);
		if (_id != id) changed();
		_id = id;
	}
	/// エリア名。
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

	/// 名前を'\'で分割してディレクトリ構造と看做した時、
	/// このエリアが属するディレクトリ名。
	@property
	const
	string dirName() { mixin(S_TRACE);
		return toDirName(_name);
	}
	/// ditto
	@property
	void dirName(string name) { mixin(S_TRACE);
		if (name != "" && name[$ - 1] != '\\') name ~= "\\";
		this.name = name ~ baseName;
	}
	/// ditto
	static string toDirName(string name) { mixin(S_TRACE);
		ptrdiff_t i = .lastIndexOf(name, '\\');
		if (i == -1) return "";
		return name[0 .. i];
	}

	/// 名前を'\'で分割してディレクトリ構造と看做した時、
	/// このエリアからディレクトリパスを除いた名前。
	@property
	const
	string baseName() { mixin(S_TRACE);
		return toBaseName(_name);
	}
	/// ditto
	@property
	void baseName(string name) { mixin(S_TRACE);
		name = name.replace("\\", "");
		this.name = _name[0 .. $ - baseName.length] ~ name;
	}
	/// ditto
	static string toBaseName(string name) { mixin(S_TRACE);
		ptrdiff_t i = .lastIndexOf(name, '\\');
		if (i == -1) return name;
		return name[i + 1 .. $];
	}

	/// 並び順によってイベントビューを検索して返す。
	abstract EventTree etFromPath(size_t[] path);

	const
	override int opCmp(Object o) { mixin(S_TRACE);
		return cast(int) _id - cast(int) (cast(const(AbstractArea)) o)._id;
	}

	@property
	const
	abstract string rootName();

	@property
	override size_t[] areaPath() { return [0]; }

	/// XMLテキスト化して返す。
	const
	string toXML(XMLOption opt) { mixin(S_TRACE);
		auto doc = XNode.create(rootName);
		doc.newAttr("dataVersion", opt.dataVersion);
		toNodeImpl(doc, opt);
		return doc.text;
	}

	/// XMLノード化して返す。
	const
	XNode toNode(XMLOption opt) { mixin(S_TRACE);
		auto e = XNode.create(rootName);
		e.newAttr("dataVersion", opt.dataVersion);
		toNodeImpl(e, opt);
		return e;
	}
	const
	XNode toNode(ref XNode parent, XMLOption opt, string parentPath = "", string cutPath = "") { mixin(S_TRACE);
		auto e = parent.newElement(rootName);
		e.newAttr("dataVersion", opt.dataVersion);
		toNodeImpl(e, opt, parentPath, cutPath);
		return e;
	}
	const
	abstract void toNodeImpl(ref XNode e, XMLOption opt, string parentPath = "", string cutPath = "");

	/// 指定されたノードにProperty情報を追加する。
	const
	protected void appendProp(ref XNode pNode, XMLOption opt, string parentPath, string cutPath) { mixin(S_TRACE);
		assert (pNode.name == "Property", pNode.name ~ " != Property");
		pNode.newElement("Id", _id);
		string name = _name;
		if (cutPath != "" && istartsWith(name, cutPath ~ "\\")) {
			name = name[cutPath.length + 1 .. $];
		}
		if (parentPath != "") {
			name = parentPath ~ "\\" ~ name;
		}
		pNode.newElement("Name", name);
	}
	/// 指定されたノードからProperty情報を読み出す。
	protected static void loadProp(ref XNode aNode, out ulong id, out string name) { mixin(S_TRACE);
		string idStr = null;
		name = null;
		aNode.onTag["Property"] = (ref XNode pNode) { mixin(S_TRACE);
			pNode.onTag["Id"] = (ref XNode n) { mixin(S_TRACE);
				idStr = n.value;
			};
			pNode.onTag["Name"] = (ref XNode n) { mixin(S_TRACE);
				name = n.value;
			};
			pNode.parse();
		};
		aNode.parse();
		if (idStr is null) throw new AreaException("Id not found");
		if (name is null) name = "";
		id = to!(ulong)(idStr);
	}

	const
	override hash_t toHash() {
		hash_t hash = 0;
		foreach (c; typeid(this).name) {
			hash = hash * 37 + c;
		}
		return cast(hash_t)(hash * 37 + _id);
	}

	const
	override
	bool opEquals(Object o) {
		return this is o;
	}
}

/// プレイヤーカードのキーコード・死亡時イベント(Wsn.2)。
class PlayerCardEvents : AbstractEventTreeOwner {
	/// プレイヤーカードイベントが属するエリア・バトル。
	private AbstractArea _owner;

	/// 唯一のコンストラクタ。
	this (AbstractArea owner) { mixin(S_TRACE);
		_owner = owner;
	}

	/// プレイヤーカードイベントが属するエリア・バトル。
	inout
	inout(AbstractArea) owner() { return _owner; }

	@property
	const
	override bool canHasFireLose() { return false; }
	@property
	const
	override bool canHasFireEscape() { return false; }
	@property
	const
	override bool canHasFireEveryRound() { return false; }
	@property
	const
	override bool canHasFireRoundEnd() { return false; }
	@property
	const
	override bool canHasFireRound0() { return false; }
	@property
	const
	override bool canHasFireRound() { return false; }
	@property
	const
	override bool canHasFireKeyCode() { return true; }

	@property
	override size_t[] areaPath() { return [1]; }

	/// XMLノード化して返す。
	const
	void toNode(ref XNode e, XMLOption opt) { mixin(S_TRACE);
		auto ce = e.newElement("PlayerCardEvents");
		appendEventsToNode(ce, opt);
	}

	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		return _owner ? .cpjoin(_owner, "playercard", id) : "";
	}

	@property
	CWXPath cwxParent() { return _owner; }
}

/// エリア。
public class Area : AbstractArea, BgImageOwner {
private:
	BgImage[] _bgImgs; /// 背景セル。
	MenuCard[] _cards; /// メニューカード。
	bool _auto = false; /// カードの配置方法(カスタムはfalse・自動はtrue)。

	PlayerCardEvents _playerEvents; /// プレイヤーカードのキーコード・死亡時イベント(Wsn.2)。

public:
	static immutable XML_NAME = "Area";
	alias toAreaId toID;

	/// 唯一のコンストラクタ。
	this (ulong id, string name) { mixin(S_TRACE);
		super (id, name);
		_playerEvents = new PlayerCardEvents(this);
	}
	@property
	protected override void delegate() changeHandler() { return super.changeHandler; }
	@property
	override void changeHandler(void delegate() change) { mixin(S_TRACE);
		foreach (b; _bgImgs) { mixin(S_TRACE);
			b.changeHandler = changeHandler;
		}
		foreach (c; _cards) { mixin(S_TRACE);
			c.changeHandler = changeHandler;
		}
		playerEvents.changeHandler = changeHandler;
		super.changeHandler = change;
	}

	@property
	const
	override
	AbstractArea dup() { mixin(S_TRACE);
		auto r = new Area(id, name);
		r.spAuto = spAuto;
		foreach (c; cards) r.append(cast(MenuCard)c.dup);
		foreach (b; backs) r.append(b.dup);
		r.playerEvents.deepCopyEventTreeOwner(playerEvents);
		r.deepCopyEventTreeOwner(this);
		return r;
	}

	@property
	const
	override bool canHasFireLose() { return false; }
	@property
	const
	override bool canHasFireEscape() { return false; }
	@property
	const
	override bool canHasFireEveryRound() { return false; }
	@property
	const
	override bool canHasFireRoundEnd() { return false; }
	@property
	const
	override bool canHasFireRound0() { return false; }
	@property
	const
	override bool canHasFireRound() { return false; }
	@property
	const
	override bool canHasFireKeyCode() { return true; }
	override EventTree etFromPath(size_t[] path) { mixin(S_TRACE);
		if (path[0] == 0) { mixin(S_TRACE);
			return trees[path[1]];
		} else if (path[0] == 1) { mixin(S_TRACE);
			return playerEvents.trees[path[1]];
		} else { mixin(S_TRACE);
			return cards[path[0] - 2].trees[path[1]];
		}
	}

	/// プレイヤーカードのキーコード・死亡時イベント(Wsn.2)。
	@property
	inout
	inout(PlayerCardEvents) playerEvents() { return _playerEvents; }

	/// メニューカードのインデックスを交換する。
	void swapCards(size_t index1, size_t index2) { mixin(S_TRACE);
		if (index1 != index2) changed();
		auto temp = _cards[index1];
		_cards[index1] = _cards[index2];
		_cards[index2] = temp;
	}
	/// 背景イメージのインデックスを交換する。
	void swapBacks(size_t index1, size_t index2) { mixin(S_TRACE);
		if (index1 != index2) changed();
		auto temp = _bgImgs[index1];
		_bgImgs[index1] = _bgImgs[index2];
		_bgImgs[index2] = temp;
	}

	/// オート配置か否か。
	@property
	const
	bool spAuto() { mixin(S_TRACE);
		return _auto;
	}
	/// ditto
	@property
	void spAuto(bool spAuto) { mixin(S_TRACE);
		if (_auto != spAuto) changed();
		_auto = spAuto;
	}

	/// メニューカード群。
	@property
	inout
	inout(MenuCard)[] cards() { mixin(S_TRACE);
		return _cards;
	}
	/// 背景画像群。
	@property
	inout
	inout(BgImage)[] backs() { mixin(S_TRACE);
		return _bgImgs;
	}

	/// メニューカードを追加する。
	void append(MenuCard card) { mixin(S_TRACE);
		card.changeHandler = changeHandler;
		if (useCounter) card.setUseCounter = useCounter;
		card._owner = this;
		_cards ~= card;
		changed();
	}
	/// ditto
	void insert(size_t index, MenuCard card) { mixin(S_TRACE);
		if (_cards.length == index) { mixin(S_TRACE);
			append(card);
		} else { mixin(S_TRACE);
			card.changeHandler = changeHandler;
			if (useCounter) card.setUseCounter = useCounter;
			card._owner = this;
			_cards = _cards[0 .. index] ~ card ~ _cards[index .. $];
			changed();
		}
	}
	/// メニューカードを除去する。
	void removeCard(size_t index) { mixin(S_TRACE);
		_cards[index].changeHandler = null;
		_cards[index].removeUseCounter();
		_cards[index]._owner = null;
		_cards = _cards[0 .. index] ~ _cards[index + 1 .. $];
		changed();
	}

	/// 背景画像を追加する。
	void append(BgImage back) { mixin(S_TRACE);
		back.changeHandler = changeHandler;
		if (useCounter) back.setUseCounter = useCounter;
		back.owner = this;
		_bgImgs ~= back;
		changed();
	}
	/// ditto
	void insert(size_t index, BgImage back) { mixin(S_TRACE);
		if (_bgImgs.length == index) { mixin(S_TRACE);
			append(back);
		} else { mixin(S_TRACE);
			back.changeHandler = changeHandler;
			if (useCounter) back.setUseCounter = useCounter;
			back.owner = this;
			_bgImgs = _bgImgs[0 .. index] ~ back ~ _bgImgs[index .. $];
			changed();
		}
	}
	/// ditto
	void set(size_t index, BgImage back) { mixin(S_TRACE);
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
	void removeBgImage(size_t index) { mixin(S_TRACE);
		_bgImgs[index].changeHandler = null;
		_bgImgs[index].removeUseCounter();
		_bgImgs[index].owner = null;
		_bgImgs = _bgImgs[0 .. index] ~ _bgImgs[index + 1 .. $];
		changed();
	}

	@property
	override void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		foreach (c; _cards) { mixin(S_TRACE);
			c.setUseCounter(uc);
		}
		foreach (bg; _bgImgs) { mixin(S_TRACE);
			bg.setUseCounter(uc);
		}
		playerEvents.setUseCounter(uc);
		super.setUseCounter(uc);
	}

	override void removeUseCounter() { mixin(S_TRACE);
		foreach (c; _cards) { mixin(S_TRACE);
			c.removeUseCounter();
		}
		foreach (bg; _bgImgs) { mixin(S_TRACE);
			bg.removeUseCounter();
		}
		playerEvents.removeUseCounter();
		super.removeUseCounter();
	}

	@property
	const
	override string rootName() { return "Area"; }

	const
	override void toNodeImpl(ref XNode e, XMLOption opt, string parentPath = "", string cutPath = "") { mixin(S_TRACE);
		auto pNode = e.newElement("Property");
		appendProp(pNode, opt, parentPath, cutPath);

		playerEvents.toNode(e, opt);

		BgImage.toNode(_bgImgs, true, e, opt);
		auto ce = e.newElement("MenuCards");
		ce.newAttr("spreadtype", _auto ? "Auto" : "Custom");
		foreach (c; _cards) { mixin(S_TRACE);
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
	static Area loadFromXML(string path, in XMLInfo ver) { mixin(S_TRACE);
		scope doc = XNode.parse(std.file.readText(path));
		if (doc.name == "Area") { mixin(S_TRACE);
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
	static Area createFromNode(ref XNode aNode, in XMLInfo ver) { mixin(S_TRACE);
		if (aNode.name != "Area") throw new AreaException("Node is not area: " ~ aNode.name);
		ulong id;
		string name;
		bool spAuto;
		BgImage[] bgImgs;
		MenuCard[] cards;
		EventTree[] evt;
		EventTree[] playerEventTrees;

		aNode.onTag["PlayerCardEvents"] = (ref XNode n) { mixin(S_TRACE);
			n.onTag["Events"] = (ref XNode n) { mixin(S_TRACE);
				playerEventTrees = loadEventsFromNode(n, ver);
			};
			n.parse();
		};
		aNode.onTag["MenuCards"] = (ref XNode n) { mixin(S_TRACE);
			spAuto = n.attr("spreadtype", true) == "Auto";
			n.onTag["MenuCard"] = (ref XNode mcn) { mixin(S_TRACE);
				cards ~= MenuCard.createFromNode(mcn, ver);
			};
			n.parse();
		};
		aNode.onTag["BgImages"] = (ref XNode n) { mixin(S_TRACE);
			bgImgs = BgImage.bgImagesFromNode(n, true, ver);
		};
		aNode.onTag["Events"] = (ref XNode n) { mixin(S_TRACE);
			evt = loadEventsFromNode(n, ver);
		};
		loadProp(aNode, id, name);

		auto r = new Area(id, name);
		r.addAll(evt);
		r.playerEvents.addAll(playerEventTrees);
		r.spAuto = spAuto;
		foreach (c; cards) r.append(c);
		foreach (b; bgImgs) r.append(b);

		return r;
	}

	/// メニューカード群をXMLデータにして返す。
	static string CtoXML(MenuCard[] cards, XMLOption opt) { mixin(S_TRACE);
		return CtoNode(cards, opt).text;
	}
	/// ditto
	static XNode CtoNode(MenuCard[] cards, XMLOption opt) { mixin(S_TRACE);
		return CBtoNode(cards, [], opt);
	}
	/// 背景イメージ群をXMLデータにして返す。
	static string BtoXML(BgImage[] backs, XMLOption opt) { mixin(S_TRACE);
		return BtoNode(backs, opt).text;
	}
	/// ditto
	static XNode BtoNode(BgImage[] backs, XMLOption opt) { mixin(S_TRACE);
		return CBtoNode([], backs, opt);
	}
	/// メニューカード群と背景イメージ群をXMLデータにして返す。
	static string CBtoXML(MenuCard[] cards, BgImage[] backs, XMLOption opt) { mixin(S_TRACE);
		return CBtoNode(cards, backs, opt).text;
	}
	/// ditto
	static XNode CBtoNode(MenuCard[] cards, BgImage[] backs, XMLOption opt) { mixin(S_TRACE);
		auto e = XNode.create("MenuCardsAndBgImages");
		if (cards.length > 0) { mixin(S_TRACE);
			auto me = e.newElement("MenuCards");
			foreach (c; cards) { mixin(S_TRACE);
				c.toNode(me, opt);
			}
		}
		if (backs.length > 0) { mixin(S_TRACE);
			auto be = e.newElement("BgImages");
			foreach (b; backs) { mixin(S_TRACE);
				b.toNode(be, opt);
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
	static bool CBfromXML(string xml, out MenuCard[] cards, out BgImage[] backs, in XMLInfo ver) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			scope doc = XNode.parse(xml);
			return CBfromXML(doc, cards, backs, ver);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
		return false;
	}
	/// ditto
	static bool CBfromXML(ref XNode node, out MenuCard[] cards, out BgImage[] backs, in XMLInfo ver) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			if (node.name == "MenuCardsAndBgImages") { mixin(S_TRACE);
				node.onTag["MenuCards"] = (ref XNode node) { mixin(S_TRACE);
					node.onTag["MenuCard"] = (ref XNode n) { mixin(S_TRACE);
						cards ~= MenuCard.createFromNode(n, ver);
					};
					node.parse();
				};
				node.onTag["BgImages"] = (ref XNode node) { mixin(S_TRACE);
					node.onTag[null] = (ref XNode n) { mixin(S_TRACE);
						backs ~= BgImage.createFromNode(n, ver);
					};
					node.parse();
				};
				node.parse();
				return true;
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
		return false;
	}
	private AreaOwner _owner = null;
	@property
	package void owner(AreaOwner owner) { _owner = owner; }
	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		if (id) { mixin(S_TRACE);
			return _owner ? cpjoinid(_owner, "area", this.id) : "";
		} else { mixin(S_TRACE);
			return _owner ? cpjoin(_owner, "area", .cCountUntil!("a is b")(_owner.areas, this), id) : "";
		}
	}
	override
	CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		switch (cate) {
		case "playercard": { mixin(S_TRACE);
			return playerEvents.findCWXPath(cpbottom(path));
		}
		case "menucard": { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= cards.length) return null;
			return cards[index].findCWXPath(cpbottom(path));
		}
		case "background": { mixin(S_TRACE);
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
	inout
	inout(CWXPath)[] cwxChilds() { mixin(S_TRACE);
		inout(CWXPath)[] r;
		r ~= playerEvents;
		foreach (a; cards) r ~= a;
		foreach (a; backs) r ~= a;
		r ~= super.cwxChilds;
		return r;
	}
	@property
	CWXPath cwxParent() { return _owner; }
}

/// パッケージ。
public class Package : AbstractArea {
public:
	static immutable XML_NAME = "Package";
	alias toPackageId toID;

	/// 唯一のコンストラクタ。
	this (ulong id, string name) { mixin(S_TRACE);
		super (id, name);
	}

	@property
	const
	override
	AbstractArea dup() { mixin(S_TRACE);
		auto r = new Package(id, name);
		r.deepCopyEventTreeOwner(this);
		return r;
	}

	@property
	const
	override bool canHasFireEnter() { return false; }
	@property
	const
	override bool canHasFireLose() { return false; }
	@property
	const
	override bool canHasFireEscape() { return false; }
	@property
	const
	override bool canHasFireRoundEnd() { return false; }
	@property
	const
	override bool canHasFireEveryRound() { return false; }
	@property
	const
	override bool canHasFireRound0() { return false; }
	@property
	const
	override bool canHasFireRound() { return false; }
	@property
	const
	override bool canHasFireKeyCode() { return false; }
	override EventTree etFromPath(size_t[] path) { mixin(S_TRACE);
		if (path[0] == 0) { mixin(S_TRACE);
			return trees[path[1]];
		}
		assert (0);
	}

	override void add(EventTree evt) { mixin(S_TRACE);
		evt.lose = false;
		evt.escape = false;
		evt.removeKeyCodesAll();
		evt.removeRoundsAll();
		super.add(evt);
	}

	@property
	const
	override string rootName() { return "Package"; }
	const
	override void toNodeImpl(ref XNode e, XMLOption opt, string parentPath = "", string cutPath = "") { mixin(S_TRACE);
		auto pNode = e.newElement("Property");
		appendProp(pNode, opt, parentPath, cutPath);
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
	static Package loadFromXML(string path, in XMLInfo ver) { mixin(S_TRACE);
		scope doc = XNode.parse(std.file.readText(path));
		if (doc.name == "Package") { mixin(S_TRACE);
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
	static Package createFromNode(ref XNode aNode, in XMLInfo ver) { mixin(S_TRACE);
		if (aNode.name != "Package") throw new AreaException("Node is not package: " ~ aNode.name);
		ulong id;
		string name;
		EventTree[] evt;
		aNode.onTag["Events"] = (ref XNode node) { mixin(S_TRACE);
			evt = loadEventsFromNode(node, ver);
		};
		loadProp(aNode, id, name);
		auto r = new Package(id, name);
		r.addAll(evt);

		return r;
	}
	private PackageOwner _owner = null;
	@property
	package void owner(PackageOwner owner) { _owner = owner; }
	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		if (id) { mixin(S_TRACE);
			return _owner ? cpjoinid(_owner, "package", this.id) : "";
		} else { mixin(S_TRACE);
			return _owner ? cpjoin(_owner, "package", .cCountUntil!("a is b")(_owner.packages, this), id) : "";
		}
	}
	@property
	CWXPath cwxParent() { return _owner; }
}

/// バトル。
public class Battle : AbstractArea {
private:
	EnemyCard[] _cards;
	bool _auto;
	PathUser _music;
	bool _continueBGM = false;
	uint _volume = 100;
	uint _loopCount = 0;
	uint _fadeIn = 0;
	bool _possibleToRunAway = true; /// PCの逃走可否(Wsn.3)。

	PlayerCardEvents _playerEvents; /// プレイヤーカードのキーコード・死亡時イベント(Wsn.2)。
public:
	static immutable XML_NAME = "Battle";
	alias toBattleId toID;

	/// 唯一のコンストラクタ。
	/// Params:
	///  music = BGMのファイルパス。
	this (ulong id, string name, string music) { mixin(S_TRACE);
		super (id, name);
		_music = new PathUser(this);
		_music.path = music;
		_playerEvents = new PlayerCardEvents(this);
	}
	@property
	protected override void delegate() changeHandler() { return super.changeHandler; }
	@property
	override void changeHandler(void delegate() change) { mixin(S_TRACE);
		foreach (c; _cards) { mixin(S_TRACE);
			c.changeHandler = changeHandler;
		}
		playerEvents.changeHandler = changeHandler;
		super.changeHandler = change;
	}

	@property
	const
	override
	AbstractArea dup() { mixin(S_TRACE);
		auto r = new Battle(id, name, music);
		r.spAuto = spAuto;
		r.possibleToRunAway = possibleToRunAway;
		r.continueBGM = continueBGM;
		foreach (c; cards) r.append(cast(EnemyCard)c.dup);
		r.playerEvents.deepCopyEventTreeOwner(playerEvents);
		r.deepCopyEventTreeOwner(this);
		return r;
	}

	@property
	const
	override bool canHasFireLose() { return true; }
	@property
	const
	override bool canHasFireEscape() { return true; }
	@property
	const
	override bool canHasFireEveryRound() { return true; }
	@property
	const
	override bool canHasFireRoundEnd() { return true; }
	@property
	const
	override bool canHasFireRound0() { return true; }
	@property
	const
	override bool canHasFireRound() { return true; }
	@property
	const
	override bool canHasFireKeyCode() { return true; }
	override EventTree etFromPath(size_t[] path) { mixin(S_TRACE);
		if (path[0] == 0) { mixin(S_TRACE);
			return trees[path[1]];
		} else if (path[0] == 1) { mixin(S_TRACE);
			return playerEvents.trees[path[1]];
		} else { mixin(S_TRACE);
			return cards[path[0] - 2].trees[path[1]];
		}
	}

	/// プレイヤーカードのキーコード・死亡時イベント(Wsn.2)。
	@property
	inout
	inout(PlayerCardEvents) playerEvents() { return _playerEvents; }

	/// BGMのファイルパス。
	@property
	void music(string music) { mixin(S_TRACE);
		if (_music.path != music) changed();
		_music.path = music;
	}
	/// ditto
	@property
	const
	string music() { mixin(S_TRACE);
		return _music.path;
	}
	/// BGMの音量(%)。
	@property
	void volume(uint volume) { mixin(S_TRACE);
		if (_volume != volume) changed();
		_volume = volume;
	}
	/// ditto
	@property
	const
	uint volume() { return _volume; }
	/// BGMのループ回数。0で無限ループ。
	@property
	void loopCount(uint loopCount) { mixin(S_TRACE);
		if (_loopCount != loopCount) changed();
		_loopCount = loopCount;
	}
	/// ditto
	@property
	const
	uint loopCount() { return _loopCount; }
	/// BGMのフェードイン時間(ミリ秒)。
	@property
	void fadeIn(uint fadeIn) { mixin(S_TRACE);
		if (_fadeIn != fadeIn) changed();
		_fadeIn = fadeIn;
	}
	/// ditto
	@property
	const
	uint fadeIn() { return _fadeIn; }

	/// BGMを継続再生するか(Wsn.3)。
	/// 継続再生する場合、BGM関係の他のパラメータは無視される。
	@property
	void continueBGM(bool value) { mixin(S_TRACE);
		if (_continueBGM != value) changed();
		_continueBGM = value;
	}
	/// ditto
	@property
	const
	bool continueBGM() { return _continueBGM; }

	/// エネミーカードを追加する。
	void append(EnemyCard card) { mixin(S_TRACE);
		card.changeHandler = changeHandler;
		if (useCounter) card.setUseCounter = useCounter;
		card._owner = this;
		_cards ~= card;
		changed();
	}
	/// ditto
	void insert(size_t index, EnemyCard card) { mixin(S_TRACE);
		if (_cards.length == index) { mixin(S_TRACE);
			append(card);
		} else { mixin(S_TRACE);
			card.changeHandler = changeHandler;
			if (useCounter) card.setUseCounter = useCounter;
			card._owner = this;
			_cards = _cards[0 .. index] ~ card ~ _cards[index .. $];
			changed();
		}
	}
	/// エネミーカードを除去する。
	void removeCard(size_t index) { mixin(S_TRACE);
		_cards[index].changeHandler = null;
		_cards[index].removeUseCounter();
		_cards[index]._owner = null;
		_cards = _cards[0 .. index] ~ _cards[index + 1 .. $];
		changed();
	}

	/// エネミーカードのインデックスを交換する。
	void swapCards(size_t index1, size_t index2) { mixin(S_TRACE);
		if (index1 != index2) changed();
		auto temp = _cards[index1];
		_cards[index1] = _cards[index2];
		_cards[index2] = temp;
	}
	/// エネミーカード群。
	@property
	EnemyCard[] cards() { mixin(S_TRACE);
		return _cards;
	}
	/// ditto
	@property
	const
	const(EnemyCard)[] cards() { mixin(S_TRACE);
		return _cards;
	}

	/// オート配置か否か。
	@property
	const
	bool spAuto() { mixin(S_TRACE);
		return _auto;
	}
	/// ditto
	@property
	void spAuto(bool spAuto) { mixin(S_TRACE);
		if (_auto != spAuto) changed();
		_auto = spAuto;
	}

	/// PCの逃走が可能か。
	@property
	const
	bool possibleToRunAway() { mixin(S_TRACE);
		return _possibleToRunAway;
	}
	/// ditto
	@property
	void possibleToRunAway(bool possibleToRunAway) { mixin(S_TRACE);
		if (_possibleToRunAway != possibleToRunAway) changed();
		_possibleToRunAway = possibleToRunAway;
	}

	@property
	override void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		foreach (c; _cards) { mixin(S_TRACE);
			c.setUseCounter(uc);
		}
		_music.setUseCounter(uc);
		playerEvents.setUseCounter(uc);
		super.setUseCounter(uc);
	}

	override void removeUseCounter() { mixin(S_TRACE);
		foreach (c; _cards) { mixin(S_TRACE);
			c.removeUseCounter();
		}
		_music.removeUseCounter();
		playerEvents.removeUseCounter();
		super.removeUseCounter();
	}

	@property
	const
	override string rootName() { return "Battle"; }
	const
	override void toNodeImpl(ref XNode e, XMLOption opt, string parentPath = "", string cutPath = "") { mixin(S_TRACE);
		auto pe = e.newElement("Property");
		appendProp(pe, opt, parentPath, cutPath);

		if (!possibleToRunAway) { mixin(S_TRACE);
			pe.newElement("RunAway", fromBool(possibleToRunAway));
		}

		playerEvents.toNode(e, opt);

		auto me = pe.newElement("MusicPath", encodePath(_music.path));
		if (volume != 100) me.newAttr("volume", volume);
		if (loopCount != 0) me.newAttr("loopcount", loopCount);
		if (fadeIn != 0) me.newAttr("fadein", fadeIn);
		if (continueBGM) me.newAttr("continue", fromBool(continueBGM));

		auto ce = e.newElement("EnemyCards");
		ce.newAttr("spreadtype", _auto ? "Auto" : "Custom");
		foreach (c; _cards) { mixin(S_TRACE);
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
	static Battle loadFromXML(string path, in XMLInfo ver) { mixin(S_TRACE);
		scope doc = XNode.parse(std.file.readText(path));
		if (doc.name == "Battle") { mixin(S_TRACE);
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
	static Battle createFromNode(ref XNode aNode, in XMLInfo ver) { mixin(S_TRACE);
		if (aNode.name != "Battle") throw new AreaException("Node is not battle: " ~ aNode.name);
		ulong id;
		string name;
		string music;
		bool spAuto;
		bool possibleToRunAway = true;
		uint volume = 100;
		uint loopCount = 0;
		uint fadeIn = 0;
		bool continueBGM = false;
		EnemyCard[] cards;
		EventTree[] evt;
		EventTree[] playerEventTrees;

		aNode.onTag["PlayerCardEvents"] = (ref XNode n) { mixin(S_TRACE);
			n.onTag["Events"] = (ref XNode n) { mixin(S_TRACE);
				playerEventTrees = loadEventsFromNode(n, ver);
			};
			n.parse();
		};
		aNode.onTag["EnemyCards"] = (ref XNode node) { mixin(S_TRACE);
			spAuto = node.attr("spreadtype", false) == "Auto";
			node.onTag["EnemyCard"] = (ref XNode ecn) { mixin(S_TRACE);
				cards ~= EnemyCard.createFromNode(ecn, ver);
			};
			node.parse();
		};
		aNode.onTag["Events"] = (ref XNode node) { mixin(S_TRACE);
			evt = loadEventsFromNode(node, ver);
		};

		string idStr = null;
		aNode.onTag["Property"] = (ref XNode pNode) { mixin(S_TRACE);
			pNode.onTag["Id"] = (ref XNode n) { mixin(S_TRACE);
				idStr = n.value;
			};
			pNode.onTag["Name"] = (ref XNode n) { mixin(S_TRACE);
				name = n.value;
			};
			pNode.onTag["MusicPath"] = (ref XNode n) { mixin(S_TRACE);
				music = decodePath(n.value);
				volume = n.attr!uint("volume", false, 100);
				loopCount = n.attr!uint("loopcount", false, 0);
				fadeIn = n.attr!uint("fadein", false, 0);
				continueBGM = n.attr!bool("continue", false, false);
			};
			pNode.onTag["RunAway"] = (ref XNode n) { mixin(S_TRACE);
				possibleToRunAway = n.valueTo!bool;
			};
			pNode.parse();
		};
		aNode.parse();
		if (idStr is null) throw new AreaException("Id not found");
		if (name is null) name = "";

		id = to!(ulong)(idStr);

		auto r = new Battle(id, name, music);
		r.addAll(evt);
		r.playerEvents.addAll(playerEventTrees);
		foreach (c; cards) r.append(c);
		r.spAuto = spAuto;
		r.possibleToRunAway = possibleToRunAway;
		r.volume = volume;
		r.loopCount = loopCount;
		r.fadeIn = fadeIn;
		r.continueBGM = continueBGM;

		return r;
	}

	/// エネミーカード群をXMLデータにして返す。
	static string CtoXML(EnemyCard[] cards, XMLOption opt) { mixin(S_TRACE);
		return CtoNode(cards, opt).text;
	}
	/// ditto
	static XNode CtoNode(EnemyCard[] cards, XMLOption opt) { mixin(S_TRACE);
		auto doc = XNode.create("EnemyCards");
		foreach (c; cards) { mixin(S_TRACE);
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
	static bool CfromXML(string xml, out EnemyCard[] cards, in XMLInfo ver) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			scope doc = XNode.parse(xml);
			return CfromXML(doc, cards, ver);
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
		return false;
	}
	/// ditto
	static bool CfromXML(ref XNode node, out EnemyCard[] cards, in XMLInfo ver) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			if (node.name == "EnemyCards") { mixin(S_TRACE);
				node.onTag["EnemyCard"] = (ref XNode n) { mixin(S_TRACE);
					cards ~= EnemyCard.createFromNode(n, ver);
				};
				node.parse();
				return true;
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
		return false;
	}
	private BattleOwner _owner = null;
	@property
	package void owner(BattleOwner owner) { _owner = owner; }
	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		if (id) { mixin(S_TRACE);
			return _owner ? cpjoinid(_owner, "battle", this.id) : "";
		} else { mixin(S_TRACE);
			return _owner ? cpjoin(_owner, "battle", .cCountUntil!("a is b")(_owner.battles, this), id) : "";
		}
	}
	override
	CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		switch (cate) {
		case "playercard": { mixin(S_TRACE);
			return playerEvents.findCWXPath(cpbottom(path));
		}
		case "enemycard": { mixin(S_TRACE);
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
	inout
	inout(CWXPath)[] cwxChilds() { mixin(S_TRACE);
		inout(CWXPath)[] r;
		r ~= playerEvents;
		foreach (a; _cards) r ~= a;
		r ~= super.cwxChilds;
		return r;
	}
	@property
	CWXPath cwxParent() { return _owner; }
}
