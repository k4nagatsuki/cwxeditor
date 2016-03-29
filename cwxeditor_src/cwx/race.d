
module cwx.race;

import cwx.coupon;
import cwx.utils;
import cwx.types;
import cwx.xml;
import cwx.system;

/// 種族関連の例外。
class RaceException : Exception {
public:
	this (string msg) { mixin(S_TRACE);
		super(msg);
	}
}

/// 種族。
class Race : CouponsOwner {
private:
	string _name;
	string _desc;
	mixin RaceParam!(false);
	Coupon[] _coupons;
	this () {}
public:
	/// XMLノードから種族を生成。
	static Race fromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		auto r = new Race;
		r._name = null;
		node.onTag["Name"] = (ref XNode node) {r._name = node.value;};
		node.onTag["Description"] = (ref XNode node) {r._desc = decodeLf2(node.value);};
		node.onTag["Feature"] = (ref XNode node) {r.loadFeature(node, ver);};
		node.onTag["Ability"] = (ref XNode node) {r.loadAbility(node, ver);};
		node.onTag[Coupon.XML_NAME_M] = (ref XNode node) { mixin(S_TRACE);
			node.onTag[Coupon.XML_NAME] = (ref XNode node) { mixin(S_TRACE);
				auto coupon = Coupon.fromNode(node, ver);
				coupon.owner = r;
				r._coupons ~= coupon;
			};
		};
		node.parse();
		if (!r._name) throw new Exception("Race name not found.");
		return r;
	}
	/// 種族名。
	@property
	const
	string name() {return _name;}
	/// 解説。
	@property
	const
	string desc() {return _desc;}
	/// 初期クーポン。
	@property
	inout
	inout(Coupon)[] coupons() {return _coupons;}
}

/// mixinによって種族絡みのパラメータを付与する。
template RaceParam(bool Set) {
	private {
		bool _automaton = false; /// 心を持たない
		bool _constructure = false; /// 魔法生物
		bool _undead = false; /// 命を持たない
		bool _unholy = false; /// 不浄な存在
		bool _weaponRes = false, _magicRes = false; /// 武器・魔法が効かない
		bool _res[Element];
		bool _weak[Element];
		uint _phy[Physical];
		double _mtl[Mental];
		int _dEnh[Enhance]; /// デフォルトの能力修正
	}

	/// rからパラメータをコピーする。
	void copyRaceParam(T)(T r) { mixin(S_TRACE);
		automaton = r.automaton;
		constructure = r.constructure;
		undead = r.undead;
		unholy = r.unholy;
		weaponResist = r.weaponResist;
		magicResist = r.magicResist;
		resist(Element.FIRE, r.resist(Element.FIRE));
		resist(Element.ICE, r.resist(Element.ICE));
		weakness(Element.FIRE, r.weakness(Element.FIRE));
		weakness(Element.ICE, r.weakness(Element.ICE));
		physical(Physical.DEX, r.physical(Physical.DEX));
		physical(Physical.AGL, r.physical(Physical.AGL));
		physical(Physical.INT, r.physical(Physical.INT));
		physical(Physical.STR, r.physical(Physical.STR));
		physical(Physical.VIT, r.physical(Physical.VIT));
		physical(Physical.MIN, r.physical(Physical.MIN));
		mental(Mental.AGGRESSIVE, r.mental(Mental.AGGRESSIVE));
		mental(Mental.CHEERFUL, r.mental(Mental.CHEERFUL));
		mental(Mental.BRAVE, r.mental(Mental.BRAVE));
		mental(Mental.CAUTIOUS, r.mental(Mental.CAUTIOUS));
		mental(Mental.TRICKISH, r.mental(Mental.TRICKISH));
		defaultEnhance(Enhance.AVOID, r.defaultEnhance(Enhance.AVOID));
		defaultEnhance(Enhance.RESIST, r.defaultEnhance(Enhance.RESIST));
		defaultEnhance(Enhance.DEFENSE, r.defaultEnhance(Enhance.DEFENSE));
	}

	/// パラメータを比較する。
	const
	bool equalsRace(T)(T r) { mixin(S_TRACE);
		return automaton == r.automaton
			&& constructure == r.constructure
			&& undead == r.undead
			&& unholy == r.unholy
			&& weaponResist == r.weaponResist
			&& magicResist == r.magicResist
			&& resist(Element.FIRE) == r.resist(Element.FIRE)
			&& resist(Element.ICE) == r.resist(Element.ICE)
			&& weakness(Element.FIRE) == r.weakness(Element.FIRE)
			&& weakness(Element.ICE) == r.weakness(Element.ICE)
			&& physical(Physical.DEX) == r.physical(Physical.DEX)
			&& physical(Physical.AGL) == r.physical(Physical.AGL)
			&& physical(Physical.INT) == r.physical(Physical.INT)
			&& physical(Physical.STR) == r.physical(Physical.STR)
			&& physical(Physical.VIT) == r.physical(Physical.VIT)
			&& physical(Physical.MIN) == r.physical(Physical.MIN)
			&& mental(Mental.AGGRESSIVE) == r.mental(Mental.AGGRESSIVE)
			&& mental(Mental.CHEERFUL) == r.mental(Mental.CHEERFUL)
			&& mental(Mental.BRAVE) == r.mental(Mental.BRAVE)
			&& mental(Mental.CAUTIOUS) == r.mental(Mental.CAUTIOUS)
			&& mental(Mental.TRICKISH) == r.mental(Mental.TRICKISH)
			&& defaultEnhance(Enhance.AVOID) ==r.defaultEnhance(Enhance.AVOID)
			&& defaultEnhance(Enhance.RESIST) == r.defaultEnhance(Enhance.RESIST)
			&& defaultEnhance(Enhance.DEFENSE) == r.defaultEnhance(Enhance.DEFENSE);
	}

	public {
		/// 命を持たないか。
		@property
		const
		bool undead() {return _undead;}
		static if (Set) {
			/// ditto
			@property
			void undead(bool undead) { mixin(S_TRACE);
				if (_undead != undead) changed();
				_undead = undead;
			}
		}
		/// 心を持たないか。
		@property
		const
		bool automaton() {return _automaton;}
		static if (Set) {
			/// ditto
			@property
			void automaton(bool automaton) { mixin(S_TRACE);
				if (_automaton != automaton) changed();
				_automaton = automaton;
			}
		}
		/// 不浄な存在か。
		@property
		const
		bool unholy() {return _unholy;}
		static if (Set) {
			/// ditto
			@property
			void unholy(bool unholy) { mixin(S_TRACE);
				if (_unholy != unholy) changed();
				_unholy = unholy;
			}
		}
		/// 魔法生物か。
		@property
		const
		bool constructure() {return _constructure;}
		static if (Set) {
			/// ditto
			@property
			void constructure(bool constructure) { mixin(S_TRACE);
				if (_constructure != constructure) changed();
				_constructure = constructure;
			}
		}
		/// 武器が効かないか。
		@property
		const
		bool weaponResist() {return _weaponRes;}
		static if (Set) {
			/// ditto
			@property
			void weaponResist(bool weaponRes) { mixin(S_TRACE);
				if (_weaponRes != weaponRes) changed();
				_weaponRes = weaponRes;
			}
		}
		/// 魔法が効かないか。
		@property
		const
		bool magicResist() {return _magicRes;}
		static if (Set) {
			/// ditto
			@property
			void magicResist(bool magicRes) { mixin(S_TRACE);
				if (_magicRes != magicRes) changed();
				_magicRes = magicRes;
			}
		}
		/// 炎/冷気が無効。
		const
		bool resist(Element el) {return _res[el];}
		static if (Set) {
			/// ditto
			void resist(Element el, bool res) { mixin(S_TRACE);
				if (_res[el] != res) changed();
				_res[el] = res;
				if (res) weakness(el, false);
			}
		}
		/// 炎/冷気が弱点。
		const
		bool weakness(Element el) {return _weak[el];}
		static if (Set) {
			/// ditto
			void weakness(Element el, bool weak) { mixin(S_TRACE);
				if (_weak[el] != weak) changed();
				_weak[el] = weak;
				if (weak) resist(el, false);
			}
		}
		/// 身体能力。
		const
		uint physical(Physical phy) {return _phy[phy];}
		static if (Set) {
			/// ditto
			void physical(Physical phy, uint val) { mixin(S_TRACE);
				if (_phy[phy] != val) changed();
				_phy[phy] = val;
			}
		}
		/// 精神傾向。
		const
		double mental(Mental m) { mixin(S_TRACE);
			final switch (m) {
			case Mental.AGGRESSIVE, Mental.CHEERFUL, Mental.BRAVE, Mental.CAUTIOUS, Mental.TRICKISH:
				return _mtl[m];
			case Mental.UNAGGRESSIVE:
				return _mtl[Mental.AGGRESSIVE] * -1;
			case Mental.UNCHEERFUL:
				return _mtl[Mental.CHEERFUL] * -1;
			case Mental.UNBRAVE:
				return _mtl[Mental.BRAVE] * -1;
			case Mental.UNCAUTIOUS:
				return _mtl[Mental.CAUTIOUS] * -1;
			case Mental.UNTRICKISH:
				return _mtl[Mental.TRICKISH] * -1;
			}
		}
		static if (Set) {
			/// ditto
			void mental(Mental m, double val) { mixin(S_TRACE);
				final switch (m) {
				case Mental.AGGRESSIVE, Mental.CHEERFUL, Mental.BRAVE, Mental.CAUTIOUS, Mental.TRICKISH:
					if (_mtl[m] != val) changed();
					_mtl[m] = val;
					break;
				case Mental.UNAGGRESSIVE, Mental.UNCHEERFUL, Mental.UNBRAVE, Mental.UNCAUTIOUS, Mental.UNTRICKISH:
					if (_mtl[m] != val * -1) changed();
					_mtl[m] = val * -1;
					break;
				}
			}
		}
		/// 常に掛かっている能力ボーナス。
		const
		int defaultEnhance(Enhance enh) {return _dEnh[enh];}
		static if (Set) {
			/// ditto
			void defaultEnhance(Enhance enh, int dEnh) { mixin(S_TRACE);
				if (_dEnh[enh] != dEnh) changed();
				_dEnh[enh] = dEnh;
			}
		}
	}
	private void constructRace() { mixin(S_TRACE);
		_res[Element.FIRE] = false;
		_res[Element.ICE] = false;
		_weak[Element.FIRE] = false;
		_weak[Element.ICE] = false;
		_phy[Physical.DEX] = 0;
		_phy[Physical.AGL] = 0;
		_phy[Physical.INT] = 0;
		_phy[Physical.STR] = 0;
		_phy[Physical.VIT] = 0;
		_phy[Physical.MIN] = 0;
		_mtl[Mental.AGGRESSIVE] = 0;
		_mtl[Mental.CHEERFUL] = 0;
		_mtl[Mental.BRAVE] = 0;
		_mtl[Mental.CAUTIOUS] = 0;
		_mtl[Mental.TRICKISH] = 0;
		_dEnh[Enhance.AVOID] = 0;
		_dEnh[Enhance.RESIST] = 0;
		_dEnh[Enhance.DEFENSE] = 0;
	}
	const
	private void setFeature(ref XNode parent) { mixin(S_TRACE);
		auto fNode = parent.newElement("Feature");
		auto t = fNode.newElement("Type");
		t.newAttr("undead", fromBool(_undead));
		t.newAttr("automaton", fromBool(_automaton));
		t.newAttr("unholy", fromBool(_unholy));
		t.newAttr("constructure", fromBool(_constructure));
		auto ne = fNode.newElement("NoEffect");
		ne.newAttr("weapon", fromBool(_weaponRes));
		ne.newAttr("magic", fromBool(_magicRes));
		auto r = fNode.newElement("Resist");
		r.newAttr("fire", fromBool(_res[Element.FIRE]));
		r.newAttr("ice", fromBool(_res[Element.ICE]));
		auto w = fNode.newElement("Weakness");
		w.newAttr("fire", fromBool(_weak[Element.FIRE]));
		w.newAttr("ice", fromBool(_weak[Element.ICE]));
	}
	const
	private void setAbility(ref XNode parent) { mixin(S_TRACE);
		auto aNode = parent.newElement("Ability");
		auto phy = aNode.newElement("Physical");
		phy.newAttr("dex", _phy[Physical.DEX]);
		phy.newAttr("agl", _phy[Physical.AGL]);
		phy.newAttr("int", _phy[Physical.INT]);
		phy.newAttr("str", _phy[Physical.STR]);
		phy.newAttr("vit", _phy[Physical.VIT]);
		phy.newAttr("min", _phy[Physical.MIN]);
		auto mtl = aNode.newElement("Mental");
		mtl.newAttr("aggressive", _mtl[Mental.AGGRESSIVE]);
		mtl.newAttr("cheerful", _mtl[Mental.CHEERFUL]);
		mtl.newAttr("brave", _mtl[Mental.BRAVE]);
		mtl.newAttr("cautious", _mtl[Mental.CAUTIOUS]);
		mtl.newAttr("trickish", _mtl[Mental.TRICKISH]);
		auto enh = aNode.newElement("Enhance");
		enh.newAttr("avoid", _dEnh[Enhance.AVOID]);
		enh.newAttr("resist", _dEnh[Enhance.RESIST]);
		enh.newAttr("defense", _dEnh[Enhance.DEFENSE]);
	}
	private void loadFeature(ref XNode fNode, in XMLInfo ver) { mixin(S_TRACE);
		assert (fNode.name == "Feature");
		fNode.onTag["Type"] = (ref XNode tNode) { mixin(S_TRACE);
			_undead = parseBool(tNode.attr("undead", true));
			_automaton = parseBool(tNode.attr("automaton", true));
			_unholy = parseBool(tNode.attr("unholy", true));
			_constructure = parseBool(tNode.attr("constructure", true));
		};
		fNode.onTag["NoEffect"] = (ref XNode neNode) { mixin(S_TRACE);
			_weaponRes = parseBool(neNode.attr("weapon", true));
			_magicRes = parseBool(neNode.attr("magic", true));
		};
		fNode.onTag["Resist"] = (ref XNode rNode) { mixin(S_TRACE);
			_res[Element.FIRE] = parseBool(rNode.attr("fire", true));
			_res[Element.ICE] = parseBool(rNode.attr("ice", true));
		};
		fNode.onTag["Weakness"] = (ref XNode wNode) { mixin(S_TRACE);
			_weak[Element.FIRE] = parseBool(wNode.attr("fire", true));
			_weak[Element.ICE] = parseBool(wNode.attr("ice", true));
		};
		fNode.parse();
	}
	private void loadAbility(ref XNode aNode, in XMLInfo ver) { mixin(S_TRACE);
		assert (aNode.name == "Ability");
		aNode.onTag["Physical"] = (ref XNode phyNode) { mixin(S_TRACE);
			_phy[Physical.DEX] = phyNode.attr!(int)("dex", true);
			_phy[Physical.AGL] = phyNode.attr!(int)("agl", true);
			_phy[Physical.INT] = phyNode.attr!(int)("int", true);
			_phy[Physical.STR] = phyNode.attr!(int)("str", true);
			_phy[Physical.VIT] = phyNode.attr!(int)("vit", true);
			_phy[Physical.MIN] = phyNode.attr!(int)("min", true);
		};
		aNode.onTag["Mental"] = (ref XNode mtlNode) { mixin(S_TRACE);
			_mtl[Mental.AGGRESSIVE] = mtlNode.attr!(double)("aggressive", true);
			_mtl[Mental.CHEERFUL] = mtlNode.attr!(double)("cheerful", true);
			_mtl[Mental.BRAVE] = mtlNode.attr!(double)("brave", true);
			_mtl[Mental.CAUTIOUS] = mtlNode.attr!(double)("cautious", true);
			_mtl[Mental.TRICKISH] = mtlNode.attr!(double)("trickish", true);
		};
		aNode.onTag["Enhance"] = (ref XNode enhNode) { mixin(S_TRACE);
			_dEnh[Enhance.AVOID] = enhNode.attr!(int)("avoid", true);
			_dEnh[Enhance.RESIST] = enhNode.attr!(int)("resist", true);
			_dEnh[Enhance.DEFENSE] = enhNode.attr!(int)("defense", true);
		};
		aNode.parse();
	}
}
