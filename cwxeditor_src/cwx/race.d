
module cwx.race;

import cwx.coupon;
import cwx.utils;
import cwx.types;
import cwx.xml;
import cwx.system;

/// 1レベル毎のEP増加量の標準値。
immutable DEFAULT_EP_PER_LEVEL = 10u;

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
	double _levelCoefficient = 1.0;
	uint _epPerLevel = DEFAULT_EP_PER_LEVEL;
	mixin RaceParam!(false);
	Coupon[] _coupons;
	this () {}
public:
	/// XMLノードから種族を生成。
	static Race fromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		auto r = new Race;
		r._name = null;
		node.onTag["Name"] = (ref XNode node) { r._name = node.value; };
		node.onTag["Description"] = (ref XNode node) { r._desc = decodeLf2(node.value); };
		node.onTag["Feature"] = (ref XNode node) { r.loadFeature(node, ver); };
		node.onTag["Ability"] = (ref XNode node) { r.loadAbility(node, ver); };
		node.onTag[Coupon.XML_NAME_M] = (ref XNode node) { mixin(S_TRACE);
			node.onTag[Coupon.XML_NAME] = (ref XNode node) { mixin(S_TRACE);
				auto coupon = Coupon.fromNode(node, ver);
				coupon.owner = r;
				r._coupons ~= coupon;
			};
			node.parse();
		};
		node.onTag["Coefficient"] = (ref XNode node) { mixin(S_TRACE);
			r._levelCoefficient = node.attr!double("level", false, 1.0);
			r._epPerLevel = node.attr!uint("ep", false, 10);
		};
		node.parse();
		if (!r._name) throw new Exception("Race name not found.");
		return r;
	}
	/// 種族名。
	@property
	const
	string name() { return _name; }
	/// 解説。
	@property
	const
	string desc() { return _desc; }

	/// レベル判定式に掛ける係数。
	@property
	const
	double levelCoefficient() { return _levelCoefficient; }
	/// １レベル毎のEP獲得量。
	@property
	const
	uint epPerLevel() { return _epPerLevel; }

	/// 初期クーポン。
	@property
	inout
	inout(Coupon)[] coupons() { return _coupons; }
}

/// mixinによって種族絡みのパラメータを付与する。
template RaceParam(bool Set) {
	private {
		bool _automaton = false; /// 心を持たない
		bool _constructure = false; /// 魔法生物
		bool _undead = false; /// 命を持たない
		bool _unholy = false; /// 不浄な存在
		bool _weaponRes = false, _magicRes = false; /// 武器・魔法が効かない
		bool[Element] _res;
		bool[Element] _weak;
		uint[Physical] _phy;
		double[Mental] _mtl;
		int[Enhance] _dEnh; /// デフォルトの能力修正
	}

	/// rからパラメータをコピーする。
	void copyRaceParam(T)(T r) { mixin(S_TRACE);
		automaton = r.automaton;
		constructure = r.constructure;
		undead = r.undead;
		unholy = r.unholy;
		weaponResist = r.weaponResist;
		magicResist = r.magicResist;
		resist(Element.Fire, r.resist(Element.Fire));
		resist(Element.Ice, r.resist(Element.Ice));
		weakness(Element.Fire, r.weakness(Element.Fire));
		weakness(Element.Ice, r.weakness(Element.Ice));
		physical(Physical.Dex, r.physical(Physical.Dex));
		physical(Physical.Agl, r.physical(Physical.Agl));
		physical(Physical.Int, r.physical(Physical.Int));
		physical(Physical.Str, r.physical(Physical.Str));
		physical(Physical.Vit, r.physical(Physical.Vit));
		physical(Physical.Min, r.physical(Physical.Min));
		mental(Mental.Aggressive, r.mental(Mental.Aggressive));
		mental(Mental.Cheerful, r.mental(Mental.Cheerful));
		mental(Mental.Brave, r.mental(Mental.Brave));
		mental(Mental.Cautious, r.mental(Mental.Cautious));
		mental(Mental.Trickish, r.mental(Mental.Trickish));
		defaultEnhance(Enhance.Avoid, r.defaultEnhance(Enhance.Avoid));
		defaultEnhance(Enhance.Resist, r.defaultEnhance(Enhance.Resist));
		defaultEnhance(Enhance.Defense, r.defaultEnhance(Enhance.Defense));
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
			&& resist(Element.Fire) == r.resist(Element.Fire)
			&& resist(Element.Ice) == r.resist(Element.Ice)
			&& weakness(Element.Fire) == r.weakness(Element.Fire)
			&& weakness(Element.Ice) == r.weakness(Element.Ice)
			&& physical(Physical.Dex) == r.physical(Physical.Dex)
			&& physical(Physical.Agl) == r.physical(Physical.Agl)
			&& physical(Physical.Int) == r.physical(Physical.Int)
			&& physical(Physical.Str) == r.physical(Physical.Str)
			&& physical(Physical.Vit) == r.physical(Physical.Vit)
			&& physical(Physical.Min) == r.physical(Physical.Min)
			&& mental(Mental.Aggressive) == r.mental(Mental.Aggressive)
			&& mental(Mental.Cheerful) == r.mental(Mental.Cheerful)
			&& mental(Mental.Brave) == r.mental(Mental.Brave)
			&& mental(Mental.Cautious) == r.mental(Mental.Cautious)
			&& mental(Mental.Trickish) == r.mental(Mental.Trickish)
			&& defaultEnhance(Enhance.Avoid) ==r.defaultEnhance(Enhance.Avoid)
			&& defaultEnhance(Enhance.Resist) == r.defaultEnhance(Enhance.Resist)
			&& defaultEnhance(Enhance.Defense) == r.defaultEnhance(Enhance.Defense);
	}

	public {
		/// 命を持たないか。
		@property
		const
		bool undead() { return _undead; }
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
		bool automaton() { return _automaton; }
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
		bool unholy() { return _unholy; }
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
		bool constructure() { return _constructure; }
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
		bool weaponResist() { return _weaponRes; }
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
		bool magicResist() { return _magicRes; }
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
		bool resist(Element el) { return _res.get(el, false); }
		static if (Set) {
			/// ditto
			void resist(Element el, bool res) { mixin(S_TRACE);
				if (_res.get(el, false) != res) changed();
				_res[el] = res;
				if (res) weakness(el, false);
			}
		}
		/// 炎/冷気が弱点。
		const
		bool weakness(Element el) { return _weak.get(el, false); }
		static if (Set) {
			/// ditto
			void weakness(Element el, bool weak) { mixin(S_TRACE);
				if (_weak.get(el, false) != weak) changed();
				_weak[el] = weak;
				if (weak) resist(el, false);
			}
		}
		/// 身体能力。
		const
		uint physical(Physical phy) { return _phy[phy]; }
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
			case Mental.Aggressive, Mental.Cheerful, Mental.Brave, Mental.Cautious, Mental.Trickish:
				return _mtl[m];
			case Mental.Unaggressive:
				return _mtl[Mental.Aggressive] * -1;
			case Mental.Uncheerful:
				return _mtl[Mental.Cheerful] * -1;
			case Mental.Unbrave:
				return _mtl[Mental.Brave] * -1;
			case Mental.Uncautious:
				return _mtl[Mental.Cautious] * -1;
			case Mental.Untrickish:
				return _mtl[Mental.Trickish] * -1;
			}
		}
		static if (Set) {
			/// ditto
			void mental(Mental m, double val) { mixin(S_TRACE);
				final switch (m) {
				case Mental.Aggressive, Mental.Cheerful, Mental.Brave, Mental.Cautious, Mental.Trickish:
					if (_mtl[m] != val) changed();
					_mtl[m] = val;
					break;
				case Mental.Unaggressive, Mental.Uncheerful, Mental.Unbrave, Mental.Uncautious, Mental.Untrickish:
					if (_mtl[m] != val * -1) changed();
					_mtl[m] = val * -1;
					break;
				}
			}
		}
		/// 常に掛かっている能力ボーナス。
		const
		int defaultEnhance(Enhance enh) { return _dEnh.get(enh, 0); }
		static if (Set) {
			/// ditto
			void defaultEnhance(Enhance enh, int dEnh) { mixin(S_TRACE);
				if (_dEnh.get(enh, 0) != dEnh) changed();
				_dEnh[enh] = dEnh;
			}
		}
	}
	private void constructRace() { mixin(S_TRACE);
		_res[Element.Fire] = false;
		_res[Element.Ice] = false;
		_weak[Element.Fire] = false;
		_weak[Element.Ice] = false;
		_phy[Physical.Dex] = 0;
		_phy[Physical.Agl] = 0;
		_phy[Physical.Int] = 0;
		_phy[Physical.Str] = 0;
		_phy[Physical.Vit] = 0;
		_phy[Physical.Min] = 0;
		_mtl[Mental.Aggressive] = 0;
		_mtl[Mental.Cheerful] = 0;
		_mtl[Mental.Brave] = 0;
		_mtl[Mental.Cautious] = 0;
		_mtl[Mental.Trickish] = 0;
		_dEnh[Enhance.Avoid] = 0;
		_dEnh[Enhance.Resist] = 0;
		_dEnh[Enhance.Defense] = 0;
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
		r.newAttr("fire", fromBool(_res.get(Element.Fire, false)));
		r.newAttr("ice", fromBool(_res.get(Element.Ice, false)));
		auto w = fNode.newElement("Weakness");
		w.newAttr("fire", fromBool(_weak.get(Element.Fire, false)));
		w.newAttr("ice", fromBool(_weak.get(Element.Ice, false)));
	}
	const
	private void setAbility(ref XNode parent) { mixin(S_TRACE);
		auto aNode = parent.newElement("Ability");
		auto phy = aNode.newElement("Physical");
		phy.newAttr("dex", _phy[Physical.Dex]);
		phy.newAttr("agl", _phy[Physical.Agl]);
		phy.newAttr("int", _phy[Physical.Int]);
		phy.newAttr("str", _phy[Physical.Str]);
		phy.newAttr("vit", _phy[Physical.Vit]);
		phy.newAttr("min", _phy[Physical.Min]);
		auto mtl = aNode.newElement("Mental");
		mtl.newAttr("aggressive", _mtl[Mental.Aggressive]);
		mtl.newAttr("cheerful", _mtl[Mental.Cheerful]);
		mtl.newAttr("brave", _mtl[Mental.Brave]);
		mtl.newAttr("cautious", _mtl[Mental.Cautious]);
		mtl.newAttr("trickish", _mtl[Mental.Trickish]);
		auto enh = aNode.newElement("Enhance");
		enh.newAttr("avoid", _dEnh.get(Enhance.Avoid, false));
		enh.newAttr("resist", _dEnh.get(Enhance.Resist, false));
		enh.newAttr("defense", _dEnh.get(Enhance.Defense, false));
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
			_res[Element.Fire] = parseBool(rNode.attr("fire", true));
			_res[Element.Ice] = parseBool(rNode.attr("ice", true));
		};
		fNode.onTag["Weakness"] = (ref XNode wNode) { mixin(S_TRACE);
			_weak[Element.Fire] = parseBool(wNode.attr("fire", true));
			_weak[Element.Ice] = parseBool(wNode.attr("ice", true));
		};
		fNode.parse();
	}
	private void loadAbility(ref XNode aNode, in XMLInfo ver) { mixin(S_TRACE);
		assert (aNode.name == "Ability");
		aNode.onTag["Physical"] = (ref XNode phyNode) { mixin(S_TRACE);
			_phy[Physical.Dex] = phyNode.attr!(int)("dex", true);
			_phy[Physical.Agl] = phyNode.attr!(int)("agl", true);
			_phy[Physical.Int] = phyNode.attr!(int)("int", true);
			_phy[Physical.Str] = phyNode.attr!(int)("str", true);
			_phy[Physical.Vit] = phyNode.attr!(int)("vit", true);
			_phy[Physical.Min] = phyNode.attr!(int)("min", true);
		};
		aNode.onTag["Mental"] = (ref XNode mtlNode) { mixin(S_TRACE);
			_mtl[Mental.Aggressive] = mtlNode.attr!(double)("aggressive", true);
			_mtl[Mental.Cheerful] = mtlNode.attr!(double)("cheerful", true);
			_mtl[Mental.Brave] = mtlNode.attr!(double)("brave", true);
			_mtl[Mental.Cautious] = mtlNode.attr!(double)("cautious", true);
			_mtl[Mental.Trickish] = mtlNode.attr!(double)("trickish", true);
		};
		aNode.onTag["Enhance"] = (ref XNode enhNode) { mixin(S_TRACE);
			_dEnh[Enhance.Avoid] = enhNode.attr!(int)("avoid", true);
			_dEnh[Enhance.Resist] = enhNode.attr!(int)("resist", true);
			_dEnh[Enhance.Defense] = enhNode.attr!(int)("defense", true);
		};
		aNode.parse();
	}
}
