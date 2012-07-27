
module cwx.motion;

import cwx.types;
import cwx.card;
import cwx.usecounter;
import cwx.xml;
import cwx.path;

import std.algorithm;

private bool static_this_completed = false;
private void static_this () {
	if (static_this_completed) return;
	string _(string v) {return v;}
	_MOTION_DETAILS = [
		MType.HEAL:MDetail("Heal", [MArg.VALUE_TYPE:_("damagetype"), MArg.U_VALUE:"value"]),
		MType.DAMAGE:MDetail("Damage", [MArg.VALUE_TYPE:_("damagetype"), MArg.U_VALUE:"value"]),
		MType.ABSORB:MDetail("Absorb", [MArg.VALUE_TYPE:_("damagetype"), MArg.U_VALUE:"value"]),
		MType.PARALYZE:MDetail("Paralyze", [MArg.VALUE_TYPE:_("damagetype"), MArg.U_VALUE:"value"]),
		MType.DIS_PARALYZE:MDetail("DisParalyze", [MArg.VALUE_TYPE:_("damagetype"), MArg.U_VALUE:"value"]),
		MType.POISON:MDetail("Poison", [MArg.VALUE_TYPE:_("damagetype"), MArg.U_VALUE:"value"]),
		MType.DIS_POISON:MDetail("DisPoison", [MArg.VALUE_TYPE:_("damagetype"), MArg.U_VALUE:"value"]),
		MType.GET_SKILL_POWER:MDetail("GetSkillPower"),
		MType.LOSE_SKILL_POWER:MDetail("LoseSkillPower"),
		MType.SLEEP:MDetail("Sleep", [MArg.ROUND:"duration"]),
		MType.CONFUSE:MDetail("Confuse", [MArg.ROUND:"duration"]),
		MType.OVERHEAT:MDetail("Overheat", [MArg.ROUND:"duration"]),
		MType.BRAVE:MDetail("Brave", [MArg.ROUND:"duration"]),
		MType.PANIC:MDetail("Panic", [MArg.ROUND:"duration"]),
		MType.NORMAL:MDetail("Normal"),
		MType.BIND:MDetail("Bind", [MArg.ROUND:"duration"]),
		MType.DIS_BIND:MDetail("DisBind"),
		MType.SILENCE:MDetail("Silence", [MArg.ROUND:"duration"]),
		MType.DIS_SILENCE:MDetail("DisSilence"),
		MType.FACE_UP:MDetail("FaceUp", [MArg.ROUND:"duration"]),
		MType.FACE_DOWN:MDetail("FaceDown"),
		MType.ANTI_MAGIC:MDetail("AntiMagic", [MArg.ROUND:"duration"]),
		MType.DIS_ANTI_MAGIC:MDetail("DisAntiMagic"),
		MType.ENHANCE_ACTION:MDetail("EnhanceAction", [MArg.ROUND:_("duration"), MArg.A_VALUE:"value"]),
		MType.ENHANCE_AVOID:MDetail("EnhanceAvoid", [MArg.ROUND:_("duration"), MArg.A_VALUE:"value"]),
		MType.ENHANCE_RESIST:MDetail("EnhanceResist", [MArg.ROUND:_("duration"), MArg.A_VALUE:"value"]),
		MType.ENHANCE_DEFENSE:MDetail("EnhanceDefense", [MArg.ROUND:_("duration"), MArg.A_VALUE:"value"]),
		MType.VANISH_TARGET:MDetail("VanishTarget"),
		MType.VANISH_CARD:MDetail("VanishCard"),
		MType.VANISH_BEAST:MDetail("VanishBeast"),
		MType.DEAL_ATTACK_CARD:MDetail("DealAttackCard"),
		MType.DEAL_POWERFUL_ATTACK_CARD:MDetail("DealPowerfulAttackCard"),
		MType.DEAL_CRITICAL_ATTACK_CARD:MDetail("DealCriticalAttackCard"),
		MType.DEAL_FEINT_CARD:MDetail("DealFeintCard"),
		MType.DEAL_DEFENSE_CARD:MDetail("DealDefenseCard"),
		MType.DEAL_DISTANCE_CARD:MDetail("DealDistanceCard"),
		MType.DEAL_CONFUSE_CARD:MDetail("DealConfuseCard"),
		MType.DEAL_SKILL_CARD:MDetail("DealSkillCard"),
		MType.SUMMON_BEAST:MDetail("SummonBeast", [MArg.BEAST:cast(string) null])
	];
	foreach (type, detail; _MOTION_DETAILS) {
		_MTYPE_MAP[detail.name] = type;
	}
}

private MDetail[MType] _MOTION_DETAILS;
@property
private MDetail[MType] MOTION_DETAILS() {
	static_this();
	return _MOTION_DETAILS;
}
private MType[string] _MTYPE_MAP;
@property
private MType[string] MTYPE_MAP() {
	static_this();
	return _MTYPE_MAP;
}

struct MDetail {
	string name;
	string[MArg] args;
	bool rmdur;

	/// argを使用するコンテントであればtrueを返す。
	const
	bool use(MArg arg) {return (arg in args) != null;}
	/// argを使用する際の属性名を返す。
	/// 子要素を使用する等の理由で属性名が存在しない場合はnullを返す。
	const
	string attr(MArg arg) {return args[arg];}

	static MDetail opCall(string name) {
		string[MArg] args;
		return MDetail(name, args);
	}
	static MDetail opCall(string name, string[MArg] args) {
		MDetail r;
		r.name = name;
		r.args = args;
		return r;
	}
}

/// 一連の効果の保持者の親クラス。
class MotionUser {
private:
	Motion[] _motions;
	void delegate() _change = null;
	UseCounter _uc = null;
	MotionOwner _cwxPath;
public:
	/// パスを示すオブジェクトを指定してインスタンスを生成。
	this (MotionOwner cwxPath) {_cwxPath = cwxPath;}
	@property
	string cwxPath(bool id) {return _cwxPath.cwxPath(id);}

	/// 変更ハンドラを登録する。
	@property
	void changeHandler(void delegate() change) {
		_change = change;
	}
	/// 変更ハンドラ。
	protected void changed() {
		if (_change) _change();
	}

	/// 使用回数カウンタ。
	@property
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) {
		foreach (m; _motions) {
			m.setUseCounter(uc);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		foreach (m; _motions) {
			m.removeUseCounter();
		}
		_uc = null;
	}
	/// 効果の中にあるファイルパスに該当するものがあれば更新する。
	void change(PathId id) {
		foreach (m; _motions) {
			m.change(id);
		}
	}
	/// 効果群。
	@property
	void motions(Motion[] motions) {
		if (_motions != motions) {
			changed();
			foreach (m; _motions) {
				m.changeHandler = null;
				m.removeUseCounter();
				m._owner = null;
			}
			foreach (m; motions) {
				m.changeHandler = _change;
				if (_uc) m.setUseCounter(_uc);
				m._owner = _cwxPath;
			}
			_motions = motions;
		}
	}
	/// ditto
	@property
	Motion[] motions() {
		return _motions;
	}
	/// ditto
	@property
	const
	const(Motion)[] motions() {
		return _motions;
	}
}

/// 効果の所持者である事を示すインタフェース。
interface MotionOwner : CWXPath {
	@property
	Motion[] motions();
	@property
	const
	const(Motion)[] motions();
}

/// 効果クラス。
class Motion : CWXPath, BeastOwner {
private:
	MType _type;

	UseCounter _uc = null;
	void delegate () _change = null;

	Element _el = Element.ALL;

	DamageType _dtyp = DamageType.LEVEL_RATIO;
	uint _uValue = 1u;
	int _aValue = 0;
	uint _round = 10u;
	BeastCard _beast = null;
	uint _maxNest = maxNest_init;

	MotionOwner _owner = null;
public:
	static const XML_NAME = "Motion";

	/// 唯一のコンストラクタ。
	this (MType type, Element el) {
		_type = type;
		_el = el;
	}
	/// 効果の種類。
	@property
	const
	MType type() {return _type;}
	/// 効果の概要。
	@property
	const
	MDetail detail() {
		static_this();
		return MOTION_DETAILS[type];
	}

	/// 変更ハンドラを登録する。
	@property
	void changeHandler(void delegate() change) {
		if (_beast) _beast.changeHandler = change;
		_change = change;
	}
	/// 使用回数カウンタ。
	@property
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) {
		if (_beast) {
			_beast.setUseCounter(uc);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		if (_beast) {
			_beast.removeUseCounter();
		}
		_uc = null;
	}

	/// コピーを作成する。
	@property
	const
	Motion dup() {
		auto r = new Motion(type, element);
		r.damageType = damageType;
		r.uValue = uValue;
		r.aValue = aValue;
		r.round = round;
		r.maxNest = maxNest;
		if (_beast) {
			r.beast = _beast.dup;
		}
		return r;
	}
	const
	bool opEquals(ref const(Object) o) {
		auto m = cast(const(Motion)) o;
		if (!m) return false;
		if (m.type != type) return false;
		if (m.element != element) return false;
		if (m.damageType != damageType) return false;
		if (m.uValue != uValue) return false;
		if (m.aValue != aValue) return false;
		if (m.round != round) return false;
		if (m.maxNest != maxNest) return false;
		if (_beast) {
			if (m._beast) {
				return _beast == m._beast;
			}
			return false;
		} else {
			return !m._beast;
		}
	}
	private static int roundValue(int val, int max, int min) {
		if (val > max) return max;
		if (val < min) return min;
		return val;
	}

	/// 効果属性。
	@property
	const
	Element element() {return _el;}
	/// ditto
	@property
	void element(Element el) {_el = el;}

	/// 値の形式。
	@property
	const
	DamageType damageType() {return _dtyp;}
	/// ditto
	@property
	void damageType(DamageType dtyp) {_dtyp = dtyp;}
	/// ダメージ・回復値。
	@property
	const
	uint uValue() {return _uValue;}
	/// ditto
	static const uValue_min = 1;
	/// ditto
	static const uValue_max = int.max;
	/// ditto
	@property
	void uValue(int val) {
		_uValue = roundValue(val, uValue_max, uValue_min);
	}
	/// ボーナス・ペナルティ値。
	@property
	const
	int aValue() {return _aValue;}
	/// ditto
	static const aValue_min = -10;
	/// ditto
	static const aValue_max = 10;
	/// ditto
	@property
	void aValue(int val) {
		_aValue = roundValue(val, aValue_max, aValue_min);
	}
	/// ラウンド数。
	@property
	const
	int round() {return _round;}
	/// ditto
	@property
	void round(int val) {
		_round = roundValue(val, round_max, round_min);
	}
	/// ditto
	static const round_min = 1;
	/// ditto
	static const round_max = int.max;
	/// 召喚獣。
	@property
	BeastCard beast() {return _beast;}
	/// ditto
	@property
	const
	const(BeastCard) beast() {return _beast;}
	/// ditto
	@property
	BeastCard[] beasts() {return _beast ? [_beast] : [];}
	/// ditto
	@property
	const
	const(BeastCard)[] beasts() {return _beast ? [_beast] : [];}
	/// ditto
	@property
	void beast(in BeastCard beast) {
		if (_beast) {
			_beast.changeHandler = null;
			_beast.removeUseCounter();
			_beast.owner = null;
		}
		if (beast) {
			setBeastImpl(beast.dup);
		} else {
			_beast = null;
		}
	}
	/// XMLノードから召喚獣を読み出して設定する。
	/// ノードから生成された召喚獣のIDを返す。
	ulong setBeastFromNode(ref XNode node, string ver) {
		assert (node.name == "BeastCard", "setBeastFromNode: " ~ node.name);
		auto b = BeastCard.createFromNode(node, ver);
		ulong bid = b.id;
		setBeastImpl(b);
		return bid;
	}
	private void setBeastImpl(BeastCard beast) {
		_beast = beast;
		_beast.id = 1L;
		_beast.changeHandler = _change;
		if (_uc) _beast.setUseCounter(_uc);
		_beast.owner = this;
	}
	/// 召喚獣カードの画像イメージのパスが該当するものであれば更新する。
	void change(PathId id) {
		_beast.change(id);
	}

	/// 参照IDを使用する時、同一の召喚獣カードを何回までネストできるか。
	@property
	const
	uint maxNest() {return _maxNest;}
	/// ditto
	@property
	void maxNest(uint val) {
		_maxNest = roundValue(val, maxNest_max, maxNest_min);
	}
	/// ネスト可能回数の初期値、最小値、最大値。
	static immutable maxNest_init = 1;
	/// ditto
	static immutable maxNest_min = 0;
	/// ditto
	static immutable maxNest_max = 999;

	/// XMLテキスト化して返す。
	const
	string toXML(XMLOption opt) {
		return toNode(opt).text;
	}
	/// XMLノード化して返す。
	const
	XNode toNode(XMLOption opt) {
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e, opt);
		return e;
	}
	/// XMLノードに自身のデータをノード化して追加し、
	/// そのノードを返す。
	const
	XNode toNode(ref XNode node, XMLOption opt) {
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e, opt);
		return e;
	}
	const
	private XNode toNodeImpl(ref XNode e, XMLOption opt) {
		auto d = detail;
		e.newAttr("type", d.name);
		e.newAttr("element", fromElement(element));
		if (d.use(MArg.VALUE_TYPE)) e.newAttr(d.attr(MArg.VALUE_TYPE), fromDamageType(damageType));
		if (d.use(MArg.U_VALUE)) e.newAttr(d.attr(MArg.U_VALUE), uValue);
		if (d.use(MArg.A_VALUE)) e.newAttr(d.attr(MArg.A_VALUE), aValue);
		if (d.use(MArg.ROUND)) e.newAttr(d.attr(MArg.ROUND), round);
		if (d.use(MArg.BEAST)) {
			auto be = e.newElement("Beasts");
			be.newAttr("maxNest", maxNest);
			if (_beast) {
				if (opt && opt.includeCard && 0 != _beast.linkId) {
				// FIXME: リンクに失敗する
//					auto nestCount = opt.nestCount.get(_beast.linkId, 0) + 1;
					auto p = _beast.linkId in opt.nestCount;
					uint nestCount = p ? *p : 0;
					nestCount++;

					opt.nestCount[_beast.linkId] = nestCount;
					if (nestCount <= maxNest) {
						_beast.toNode(be, opt);
					}
					if (1 >= nestCount) {
						opt.nestCount.remove(_beast.linkId);
					} else {
						opt.nestCount[_beast.linkId] = nestCount - 1;
					}
				} else {
					_beast.toNode(be, opt);
				}
			}
		}
		return e;
	}

	/// XMLノードからインスタンスを生成して返す。
	static Motion createFromNode(ref XNode node, string ver) {
		static_this();
		string elStr = null;
		auto type = MTYPE_MAP[node.attr("type", true)];
		auto d = MOTION_DETAILS[type];
		auto r = new Motion(type, toElement(node.attr("element", true)));
		if (d.use(MArg.VALUE_TYPE)) r.damageType = toDamageType(node.attr(d.attr(MArg.VALUE_TYPE), true));
		if (d.use(MArg.U_VALUE)) r.uValue = node.attr!(uint)(d.attr(MArg.U_VALUE), true);
		if (d.use(MArg.A_VALUE)) r.aValue = node.attr!(int)(d.attr(MArg.A_VALUE), true);
		if (d.use(MArg.ROUND)) r.round = node.attr!(uint)(d.attr(MArg.ROUND), true);
		if (d.use(MArg.BEAST)) {
			node.onTag["Beasts"] = (ref XNode node) {
				int maxNestInit = maxNest_init;
				r.maxNest = node.attr("maxNest", false, maxNestInit);
				node.onTag["BeastCard"] = (ref XNode node) {
					r.setBeastFromNode(node, ver);
				};
				node.parse();
			};
			node.parse();
		}
		return r;
	}

	@property
	override string cwxPath(bool id) {
		return _owner ? cpjoin(_owner, "motion", .countUntil!("a is b")(_owner.motions, this), id) : "";
	}
	override CWXPath findCWXPath(string path) {
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		switch (cate) {
		case "beastcard": {
			auto index = cpindex(path);
			return index == 0 && beast ? beast.findCWXPath(cpbottom(path)) : null;
		}
		case "beastcard:id": {
			return beast && beast.id == cpindex(path) ? beast.findCWXPath(cpbottom(path)) : null;
		}
		default: break;
		}
		return null;
	}
	@property
	CWXPath[] cwxChilds() {
		CWXPath[] r;
		if (_beast) r ~= _beast;
		return r;
	}
	@property
	CWXPath cwxParent() {return _owner;}
}
