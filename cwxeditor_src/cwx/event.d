
module cwx.event;

import cwx.types;
import cwx.utils;
import cwx.motion;
import cwx.background;
import cwx.usecounter;
import cwx.xml;
import cwx.path;
import cwx.props;

import std.date;
import std.string;

enum CType {
	START,
	START_BATTLE,
	END,
	END_BAD_END,
	CHANGE_AREA,
	CHANGE_BG_IMAGE,
	EFFECT,
	EFFECT_BREAK,
	LINK_START,
	LINK_PACKAGE,
	TALK_MESSAGE,
	TALK_DIALOG,
	PLAY_BGM,
	PLAY_SOUND,
	WAIT,
	ELAPSE_TIME,
	CALL_START,
	CALL_PACKAGE,
	BRANCH_FLAG,
	BRANCH_MULTI_STEP,
	BRANCH_STEP,
	BRANCH_SELECT,
	BRANCH_ABILITY,
	BRANCH_RANDOM,
	BRANCH_LEVEL,
	BRANCH_STATUS,
	BRANCH_PARTY_NUMBER,
	BRANCH_AREA,
	BRANCH_BATTLE,
	BRANCH_IS_BATTLE,
	BRANCH_CAST,
	BRANCH_ITEM,
	BRANCH_SKILL,
	BRANCH_INFO,
	BRANCH_BEAST,
	BRANCH_MONEY,
	BRANCH_COUPON,
	BRANCH_COMPLETE_STAMP,
	BRANCH_GOSSIP,
	SET_FLAG,
	SET_STEP,
	SET_STEP_UP,
	SET_STEP_DOWN,
	REVERSE_FLAG,
	CHECK_FLAG,
	GET_CAST,
	GET_ITEM,
	GET_SKILL,
	GET_INFO,
	GET_BEAST,
	GET_MONEY,
	GET_COUPON,
	GET_COMPLETE_STAMP,
	GET_GOSSIP,
	LOSE_CAST,
	LOSE_ITEM,
	LOSE_SKILL,
	LOSE_INFO,
	LOSE_BEAST,
	LOSE_MONEY,
	LOSE_COUPON,
	LOSE_COMPLETE_STAMP,
	LOSE_GOSSIP,
	SHOW_PARTY,
	HIDE_PARTY,
	REDISPLAY
}

enum CArg {
	AREA,
	BATTLE,
	PACKAGE,
	FLAG,
	STEP,
	BGM_PATH,
	SOUND_PATH,
	CAST,
	ITEM,
	SKILL,
	BEAST,
	INFO,
	MOTIONS,
	TEXT,
	DIALOGS,
	START,
	COUPON,
	GOSSIP,
	COMPLETE_STAMP,
	MENTAL,
	PHYSICAL,
	STATUS,
	RANGE,
	CARD_VISUAL,
	TARGET_S,
	TARGET_NS,
	TALKER_C,
	TALKER_NC,
	EFFECT_TYPE,
	RESIST,
	TRANSITION,
	TARGET_ALL,
	RANDOM,
	AVERAGE,
	COMPLETE,
	UNSIGNED_LEVEL,
	SIGNED_LEVEL,
	SUCCESS_RATE,
	TRANSITION_SPEED,
	PERCENT,
	FLAG_VALUE,
	STEP_VALUE,
	COUPON_VALUE,
	PARTY_NUMBER,
	CARD_NUMBER,
	MONEY,
	WAIT,
	BG_IMAGES
}

/// 後続コンテントのnameの型。
enum CNextType {
	NONE, /// 無し。
	TEXT, /// テキスト。
	BOOL, /// True/False。
	STEP, /// ステップ値。
	ID_AREA, /// エリアID。
	ID_BATTLE /// バトルID。
}

static this () {
	string _(string v) {return v;}
	CONTENT_DETAILS = [
		CType.START:CDetail("Start", "", CNextType.NONE, true),
		CType.START_BATTLE:CDetail("Start", "Battle", CNextType.NONE, false, [CArg.BATTLE:"id"]),
		CType.END:CDetail("End", "", CNextType.NONE, false, [CArg.COMPLETE:"complete"]),
		CType.END_BAD_END:CDetail("End", "BadEnd", CNextType.NONE, false),
		CType.CHANGE_AREA:CDetail("Change", "Area", CNextType.NONE, false, [CArg.AREA:_("id"), CArg.TRANSITION:"transition", CArg.TRANSITION_SPEED:"transitionspeed"]),
		CType.CHANGE_BG_IMAGE:CDetail("Change", "BgImage", CNextType.NONE, true, [CArg.BG_IMAGES:_(null), CArg.TRANSITION:"transition", CArg.TRANSITION_SPEED:"transitionspeed"]),
		CType.EFFECT:CDetail("Effect", "", CNextType.NONE, true, [CArg.SIGNED_LEVEL:_("level"), CArg.TARGET_NS:"targetm", CArg.EFFECT_TYPE:"effecttype", CArg.RESIST:"resisttype",
			CArg.SUCCESS_RATE:"successrate", CArg.SOUND_PATH:_("sound"), CArg.CARD_VISUAL:"visual", CArg.MOTIONS:null]),
		CType.EFFECT_BREAK:CDetail("Effect", "Break", CNextType.NONE, false),
		CType.LINK_START:CDetail("Link", "Start", CNextType.NONE, false, [CArg.START:"link"]),
		CType.LINK_PACKAGE:CDetail("Link", "Package", CNextType.NONE, false, [CArg.PACKAGE:"link"]),
		CType.TALK_MESSAGE:CDetail("Talk", "Message", CNextType.TEXT, true, [CArg.TALKER_C:_("path"), CArg.TEXT:null]),
		CType.TALK_DIALOG:CDetail("Talk", "Dialog", CNextType.TEXT, true, [CArg.TALKER_NC:_("targetm"), CArg.DIALOGS:null]),
		CType.PLAY_BGM:CDetail("Play", "Bgm", CNextType.NONE, true, [CArg.BGM_PATH:"path"]),
		CType.PLAY_SOUND:CDetail("Play", "Sound", CNextType.NONE, true, [CArg.SOUND_PATH:"path"]),
		CType.WAIT:CDetail("Wait", "", CNextType.NONE, true, [CArg.WAIT:"value"]),
		CType.ELAPSE_TIME:CDetail("Elapse", "Time", CNextType.NONE, true),
		CType.CALL_START:CDetail("Call", "Start", CNextType.NONE, true, [CArg.START:"call"]),
		CType.CALL_PACKAGE:CDetail("Call", "Package", CNextType.NONE, true, [CArg.PACKAGE:"call"]),
		CType.BRANCH_FLAG:CDetail("Branch", "Flag", CNextType.BOOL, true, [CArg.FLAG:"flag"]),
		CType.BRANCH_MULTI_STEP:CDetail("Branch", "MultiStep", CNextType.STEP, true, [CArg.STEP:"step"]),
		CType.BRANCH_STEP:CDetail("Branch", "Step", CNextType.BOOL, true, [CArg.STEP:_("step"), CArg.STEP_VALUE:"value"]),
		CType.BRANCH_SELECT:CDetail("Branch", "Select", CNextType.BOOL, true, [CArg.TARGET_ALL:_("targetall"), CArg.RANDOM:"random"]),
		CType.BRANCH_ABILITY:CDetail("Branch", "Ability", CNextType.BOOL, true, [CArg.TARGET_S:_("targetm"), CArg.MENTAL:"mental", CArg.PHYSICAL:"physical", CArg.SIGNED_LEVEL:"value"]),
		CType.BRANCH_RANDOM:CDetail("Branch", "Random", CNextType.BOOL, true, [CArg.PERCENT:"value"]),
		CType.BRANCH_LEVEL:CDetail("Branch", "Level", CNextType.BOOL, true, [CArg.AVERAGE:_("average"), CArg.UNSIGNED_LEVEL:"value"]),
		CType.BRANCH_STATUS:CDetail("Branch", "Status", CNextType.BOOL, true, [CArg.TARGET_NS:_("targetm"), CArg.STATUS:"status"]),
		CType.BRANCH_PARTY_NUMBER:CDetail("Branch", "PartyNumber", CNextType.BOOL, true, [CArg.PARTY_NUMBER:"value"]),
		CType.BRANCH_AREA:CDetail("Branch", "Area", CNextType.ID_AREA, true),
		CType.BRANCH_BATTLE:CDetail("Branch", "Battle", CNextType.ID_BATTLE, true),
		CType.BRANCH_IS_BATTLE:CDetail("Branch", "IsBattle", CNextType.BOOL, true),
		CType.BRANCH_CAST:CDetail("Branch", "Cast", CNextType.BOOL, true, [CArg.CAST:"id"]),
		CType.BRANCH_ITEM:CDetail("Branch", "Item", CNextType.BOOL, true, [CArg.ITEM:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.BRANCH_SKILL:CDetail("Branch", "Skill", CNextType.BOOL, true, [CArg.SKILL:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.BRANCH_INFO:CDetail("Branch", "Info", CNextType.BOOL, true, [CArg.INFO:"id"]),
		CType.BRANCH_BEAST:CDetail("Branch", "Beast", CNextType.BOOL, true, [CArg.BEAST:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.BRANCH_MONEY:CDetail("Branch", "Money", CNextType.BOOL, true, [CArg.MONEY:"value"]),
		CType.BRANCH_COUPON:CDetail("Branch", "Coupon", CNextType.BOOL, true, [CArg.COUPON:_("coupon"), CArg.RANGE:"targets"]),
		CType.BRANCH_COMPLETE_STAMP:CDetail("Branch", "CompleteStamp", CNextType.BOOL, true, [CArg.COMPLETE_STAMP:"scenario"]),
		CType.BRANCH_GOSSIP:CDetail("Branch", "Gossip", CNextType.BOOL, true, [CArg.GOSSIP:"gossip"]),
		CType.SET_FLAG:CDetail("Set", "Flag", CNextType.NONE, true, [CArg.FLAG:_("flag"), CArg.FLAG_VALUE:"value"]),
		CType.SET_STEP:CDetail("Set", "Step", CNextType.NONE, true, [CArg.STEP:_("step"), CArg.STEP_VALUE:"value"]),
		CType.SET_STEP_UP:CDetail("Set", "StepUp", CNextType.NONE, true, [CArg.STEP:"step"]),
		CType.SET_STEP_DOWN:CDetail("Set", "StepDown", CNextType.NONE, true, [CArg.STEP:"step"]),
		CType.REVERSE_FLAG:CDetail("Reverse", "Flag", CNextType.NONE, true, [CArg.FLAG:"flag"]),
		CType.CHECK_FLAG:CDetail("Check", "Flag", CNextType.NONE, true, [CArg.FLAG:"flag"]),
		CType.GET_CAST:CDetail("Get", "Cast", CNextType.NONE, true, [CArg.CAST:"id"]),
		CType.GET_ITEM:CDetail("Get", "Item", CNextType.NONE, true, [CArg.ITEM:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.GET_SKILL:CDetail("Get", "Skill", CNextType.NONE, true, [CArg.SKILL:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.GET_INFO:CDetail("Get", "Info", CNextType.NONE, true, [CArg.INFO:"id"]),
		CType.GET_BEAST:CDetail("Get", "Beast", CNextType.NONE, true, [CArg.BEAST:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.GET_MONEY:CDetail("Get", "Money", CNextType.NONE, true, [CArg.MONEY:"value"]),
		CType.GET_COUPON:CDetail("Get", "Coupon", CNextType.NONE, true, [CArg.COUPON:_("coupon"), CArg.RANGE:"targets", CArg.COUPON_VALUE:"value"]),
		CType.GET_COMPLETE_STAMP:CDetail("Get", "CompleteStamp", CNextType.NONE, true, [CArg.COMPLETE_STAMP:"scenario"]),
		CType.GET_GOSSIP:CDetail("Get", "Gossip", CNextType.NONE, true, [CArg.GOSSIP:"gossip"]),
		CType.LOSE_CAST:CDetail("Lose", "Cast", CNextType.NONE, true, [CArg.CAST:"id"]),
		CType.LOSE_ITEM:CDetail("Lose", "Item", CNextType.NONE, true, [CArg.ITEM:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.LOSE_SKILL:CDetail("Lose", "Skill", CNextType.NONE, true, [CArg.SKILL:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.LOSE_INFO:CDetail("Lose", "Info", CNextType.NONE, true, [CArg.INFO:"id"]),
		CType.LOSE_BEAST:CDetail("Lose", "Beast", CNextType.NONE, true, [CArg.BEAST:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.LOSE_MONEY:CDetail("Lose", "Money", CNextType.NONE, true, [CArg.MONEY:"value"]),
		CType.LOSE_COUPON:CDetail("Lose", "Coupon", CNextType.NONE, true, [CArg.COUPON:_("coupon"), CArg.RANGE:"targets"]),
		CType.LOSE_COMPLETE_STAMP:CDetail("Lose", "CompleteStamp", CNextType.NONE, true, [CArg.COMPLETE_STAMP:"scenario"]),
		CType.LOSE_GOSSIP:CDetail("Lose", "Gossip", CNextType.NONE, true, [CArg.GOSSIP:"gossip"]),
		CType.SHOW_PARTY:CDetail("Show", "Party", CNextType.NONE, true),
		CType.HIDE_PARTY:CDetail("Hide", "Party", CNextType.NONE, true),
		CType.REDISPLAY:CDetail("Redisplay", "", CNextType.NONE, true, [CArg.TRANSITION:_("transition"), CArg.TRANSITION_SPEED:"transitionspeed"])
	];
	foreach (cType, ref detail; CONTENT_DETAILS) {
		CTYPE_MAP[detail.name][detail.type] = cType;
	}
}

CDetail[CType] CONTENT_DETAILS;
private CType[string][string] CTYPE_MAP;

struct CDetail {
	string name;
	string type;
	CNextType nextType;
	bool owner;

	string[CArg] args;
	/// argを使用するコンテントであればtrueを返す。
	bool use(CArg arg) {return (arg in args) != null;}
	/// argを使用する際の属性名を返す。
	/// 子要素を使用する等の理由で属性名が存在しない場合はnullを返す。
	string attr(CArg arg) {return args[arg];}

	static CDetail opCall(string name, string type, CNextType nextType, bool owner) {
		string[CArg] args;
		return CDetail(name, type, nextType, owner, args);
	}
	static CDetail opCall(string name, string type, CNextType nextType, bool owner, string[CArg] args) {
		CDetail r;
		r.name = name;
		r.type = type;
		r.nextType = nextType;
		r.owner = owner;
		r.args = args;
		return r;
	}
	static CDetail fromType(CType type) {
		return CONTENT_DETAILS[type];
	}
}

/// スタートのID。
typedef string StartId;
/// 文字列をスタートIDに変換。
StartId toStartId(string start) {return cast(StartId) start;}
/// スタートコンテントの使用者。
alias User!(StartId) IStartUser;
/// スタートコンテントの使用回数カウンタ。
alias UCCont!(StartId, IStartUser) SUseCounter;

/// メッセージやダイアログが持つテキスト。
private class TextHolder : CWXPath, IPathUser, IFlagUser, IStepUser, ChgPathCallback, ChgFlagCallback, ChgStepCallback {
private:
	string _text;
	PathUser[] _fontusers;
	FlagUser[] _flagusers;
	StepUser[] _stepusers;
	UseCounter _uc;
public:
	/// テキスト。
	string text() {
		return _text;
	}
	/// ditto
	void text(string text) {
		if (_text != text) {
			string[] flags;
			string[] steps;
			string[] fonts;
			textUseItems(text, flags, steps, fonts);
			removeTextUseCounter;
			_fontusers = [];
			foreach (f; fonts) {
				auto u = new PathUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.path = f;
				_fontusers ~= u;
			}
			_flagusers = [];
			foreach (f; flags) {
				auto u = new FlagUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.flag = f;
				_flagusers ~= u;
			}
			_stepusers = [];
			foreach (s; steps) {
				auto u = new StepUser(this);
				if (_uc !is null) u.setUseCounter(_uc);
				u.step = s;
				_stepusers ~= u;
			}
			_text = text;
		}
	}
	/// 使用回数カウンタ。
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを設定する。
	void setUseCounter(UseCounter uc) {
		foreach (u; _fontusers) {
			u.setUseCounter(uc);
		}
		foreach (u; _flagusers) {
			u.setUseCounter(uc);
		}
		foreach (u; _stepusers) {
			u.setUseCounter(uc);
		}
		_uc = uc;
	}
	private void removeTextUseCounter() {
		if (_uc) {
			foreach (u; _fontusers) {
				u.removeUseCounter;
			}
			foreach (u; _flagusers) {
				u.removeUseCounter;
			}
			foreach (u; _stepusers) {
				u.removeUseCounter;
			}
		}
	}
	/// 使用回数カウンタを除去。
	void removeUseCounter() {
		removeTextUseCounter;
		_uc = null;
	}
	void change(PathId id) {
		foreach (u; _fontusers) {
			u.change(id);
		}
	}
	void change(FlagId id) {
		foreach (u; _flagusers) {
			u.change(id);
		}
	}
	void change(StepId id) {
		foreach (u; _stepusers) {
			u.change(id);
		}
	}
	override void changeCallback(PathId oldVal, PathId newVal) {
		_text = replTextUseFont(_text, cast(string) oldVal, cast(string) newVal);
	}
	override void changeCallback(FlagId oldVal, FlagId newVal) {
		_text = replTextUseFlag(_text, cast(string) oldVal, cast(string) newVal);
	}
	override void changeCallback(StepId oldVal, StepId newVal) {
		_text = replTextUseStep(_text, cast(string) oldVal, cast(string) newVal);
	}
	/// このTextHolderの所持者。
	CWXPath owner() {return _owner;}
	private CWXPath _owner = null;
	private void owner(CWXPath owner) {_owner = owner;}
	string cwxPath() {
		if (_owner) {
			return cpjoin(_owner, "text");
		}
		return "";
	}
	CWXPath findCWXPath(string path) {
		if (path == "") return this;
		return null;
	}
	CWXPath[] cwxChilds() {return [];}
}

/// 口調分け条件とメッセージ内容を持つクラス。
static class SDialog : CWXPath, IPathUser, IFlagUser, IStepUser {
private:
	string[] _rCoupons;
	TextHolder _text;
	Content _parent;
public:
	/// XML名。
	static const XML_NAME = "Dialog";

	/// 唯一のコンストラクタ。
	this(string text = "", string[] rCoupons = []) {
		_text = new TextHolder;
		_text.text = text;
		_text.owner = this;
		_rCoupons = rCoupons;
	}
	override int opEquals(Object o) {
		auto d = cast(SDialog) o;
		return d && d.rCoupons == rCoupons && d.text == text;
	}
	/// メッセージ。
	string text() {
		return _text.text;
	}
	/// ditto
	void text(string text) {
		if (_parent && _text.text != text) _parent.changed;
		_text.text = text;
	}
	/// 口調分け条件クーポン群。
	string[] rCoupons() {
		return _rCoupons;
	}
	/// ditto
	void rCoupons(string[] rCoupons) {
		if (_parent && _rCoupons != rCoupons) _parent.changed;
		_rCoupons = rCoupons;
	}
	/// このSDialogを所持するSpeak。
	Content parent() {
		return _parent;
	}
	/// ditto
	void parent(Content s) {
		_parent = s;
	}
	/// 使用回数カウンタ。
	UseCounter useCounter() {return _text.useCounter;}
	/// 使用回数カウンタを設定・除去する。
	void setUseCounter(UseCounter uc) {
		_text.setUseCounter(uc);
	}
	/// ditto
	void removeUseCounter() {
		_text.removeTextUseCounter;
	}
	void change(PathId id) {
		_text.change(id);
	}
	void change(FlagId id) {
		_text.change(id);
	}
	void change(StepId id) {
		_text.change(id);
	}
	XNode toNode() {
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	void toNode(ref XNode node) {
		assert (node.name == "Dialogs", node.name ~ " != Dialogs");
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	private void toNodeImpl(ref XNode e) {
		assert (e.name == XML_NAME, e.name ~ " != " ~ XML_NAME);
		e.newElement("RequiredCoupons", encodeLf(rCoupons, true));
		e.newElement("Text", encodeLf(text));
	}
	static SDialog createFromNode(ref XNode node, string ver) {
		assert (node.name == XML_NAME, node.name ~ " != " ~ XML_NAME);
		string[] rCoupons;
		string text;
		node.onTag["RequiredCoupons"] = (ref XNode n) {
			rCoupons = decodeLf(n.value);
		};
		node.onTag["Text"] = (ref XNode n) {
			text = decodeLf2(n.value);
		};
		node.parse;
		return new SDialog(text, rCoupons);
	}
	string cwxPath() {
		return _parent ? cpjoin(_parent, "dialog", indexOf!("a is b")(_parent.dialogs, this)) : "";
	}
	override CWXPath findCWXPath(string path) {
		if (path == "") return this;
		auto cate = cpcategory(path);
		if (cate == "text") {
			auto index = cpindex(path);
			if (index > 0) return null;
			return _text.findCWXPath(cpbottom(path));
		}
		return null;
	}
	CWXPath[] cwxChilds() {return _text.cwxChilds;}
}

class Content : CWXPath, IPathUser, IAreaUser, IBattleUser, IPackageUser,
		IFlagUser, IStepUser,
		ICastUser, IItemUser, ISkillUser, IBeastUser, IInfoUser, IStartUser,
		MotionOwner, BgImageOwner {
	private EventTree _tree = null;

	/// 型と後続テキストnameを指定してインスタンスを生成。
	this (CType type, string name) {
		_id = format("%08X", &this) ~ "-" ~ to!(string)(getUTCtime);
		_type = type;
		_name = name;
	}
	private string _id;
	/// イベントID。ドラッグ&ドロップ等でイベントを移動するとき、
	/// 自分自身を識別するために使用する。
	string eventId() {return _id;}

	private CType _type;
	/// コンテントの型。
	CType type() {return _type;}
	/// コンテントの概要。
	CDetail detail() {return CONTENT_DETAILS[type];}

	/// 型変換が可能であればtrue。
	bool canConvert(CType type) {
		if (type == this.type) return false;
		if (type == CType.START || this.type == CType.START) return false;
		return next.length ? CONTENT_DETAILS[type].owner : true;
	}

	private void resetValue(CArg Arg, T, T Init)(in CDetail d, void delegate(T) set) {
		if (!d.use(Arg)) {
			set(Init);
		}
	}
	/// コンテントの型を変換。
	void type(CType type, CProps prop) {
		if (!canConvert(type)) throw new Exception("can not convert: " ~ prop.msgs.content(type));
		if (_type == type) return;
		changed;
		auto od = detail;
		auto d = CONTENT_DETAILS[type];
		foreach (n; next) {
			void setNum() {
				if (prop.msgs.evtChildDefault != n.name && !isNumeric(n.name) || n.name == "0") {
					n.name = prop.msgs.evtChildDefault;
				}
			}
			switch (d.nextType) {
			case CNextType.NONE: n.name = ""; break;
			case CNextType.TEXT: break;
			case CNextType.BOOL: {
				if (prop.msgs.evtChildTrue != n.name && prop.msgs.evtChildFalse != n.name) {
					n.name = prop.msgs.evtChildTrue;
				}
			} break;
			case CNextType.STEP: {
				if (prop.msgs.evtChildDefault != n.name && !isNumeric(n.name)) {
					n.name = prop.msgs.evtChildDefault;
				}
			} break;
			case CNextType.ID_AREA: {
				setNum;
				if (n.name != prop.msgs.evtChildDefault) {
					try {
						n.area = to!(ulong)(n.name);
					} catch {
						n.area = 0;
					}
				} else {
					n.area = 0;
				}
			} break;
			case CNextType.ID_BATTLE: {
				setNum;
				if (n.name != prop.msgs.evtChildDefault) {
					try {
						n.battle = to!(ulong)(n.name);
					} catch {
						n.battle = 0;
					}
				} else {
					n.battle = 0;
				}
			} break;
			}
		}
		_type = type;

		resetValue!(CArg.AREA, ulong, 0)(d, &area);
		resetValue!(CArg.BATTLE, ulong, 0)(d, &battle);
		resetValue!(CArg.PACKAGE, ulong, 0)(d, &packages);
		resetValue!(CArg.FLAG, string, "")(d, &flag);
		resetValue!(CArg.STEP, string, "")(d, &step);
		resetValue!(CArg.BGM_PATH, string, "")(d, &bgmPath);
		resetValue!(CArg.SOUND_PATH, string, "")(d, &soundPath);
		resetValue!(CArg.CAST, ulong, 0)(d, &casts);
		resetValue!(CArg.ITEM, ulong, 0)(d, &item);
		resetValue!(CArg.SKILL, ulong, 0)(d, &skill);
		resetValue!(CArg.BEAST, ulong, 0)(d, &beast);
		resetValue!(CArg.INFO, ulong, 0)(d, &info);

		resetValue!(CArg.START, string, "")(d, &start);
		resetValue!(CArg.COUPON, string, "")(d, &coupon);
		resetValue!(CArg.GOSSIP, string, "")(d, &gossip);
		resetValue!(CArg.COMPLETE_STAMP, string, "")(d, &completeStamp);

		resetValue!(CArg.MENTAL, Mental, Mental.init)(d, &mental);
		resetValue!(CArg.PHYSICAL, Physical, Physical.init)(d, &physical);
		resetValue!(CArg.STATUS, Status, Status.ACTIVE)(d, &status);
		resetValue!(CArg.RANGE, Range, Range.SELECTED)(d, &range);
		resetValue!(CArg.CARD_VISUAL, CardVisual, CardVisual.NONE)(d, &cardVisual);
		resetValue!(CArg.EFFECT_TYPE, EffectType, EffectType.NONE)(d, &effectType);
		resetValue!(CArg.RESIST, Resist, Resist.UNFAIL)(d, &resist);
		resetValue!(CArg.TRANSITION, Transition, Transition.DEFAULT)(d, &transition);

		resetValue!(CArg.TARGET_ALL, bool, true)(d, &targetAll);
		resetValue!(CArg.RANDOM, bool, false)(d, &random);
		resetValue!(CArg.AVERAGE, bool, false)(d, &average);
		resetValue!(CArg.COMPLETE, bool, false)(d, &complete);

		resetValue!(CArg.UNSIGNED_LEVEL, int, 0)(d, &unsignedLevel);
		resetValue!(CArg.SIGNED_LEVEL, int, 0)(d, &signedLevel);
		resetValue!(CArg.SUCCESS_RATE, int, 5)(d, &successRate);
		resetValue!(CArg.TRANSITION_SPEED, int, 5u)(d, &transitionSpeed);
		resetValue!(CArg.PERCENT, int, 50u)(d, &percent);
		resetValue!(CArg.FLAG_VALUE, bool, true)(d, &flagValue);
		resetValue!(CArg.STEP_VALUE, int, 0)(d, &stepValue);
		resetValue!(CArg.COUPON_VALUE, int, 0)(d, &couponValue);
		resetValue!(CArg.PARTY_NUMBER, int, 1)(d, &partyNumber);
		resetValue!(CArg.CARD_NUMBER, int, 1)(d, &cardNumber);
		resetValue!(CArg.MONEY, int, 0)(d, &money);
		resetValue!(CArg.WAIT, int, 0)(d, &wait);

		resetValue!(CArg.MOTIONS, Motion[], [])(d, &motions);

		resetValue!(CArg.TEXT, string, "")(d, &text);
		resetValue!(CArg.DIALOGS, SDialog[], [])(d, &dialogs);

		resetValue!(CArg.TARGET_S, Target, Target(Target.M.SELECTED, true))(d, &targetS);
		resetValue!(CArg.TARGET_NS, Target, Target(Target.M.SELECTED, false))(d, &targetNS);
		resetValue!(CArg.TALKER_C, Talker, Talker.NARRATION)(d, &talkerC);
		resetValue!(CArg.TALKER_NC, Talker, Talker.SELECTED)(d, &talkerNC);

		resetValue!(CArg.BG_IMAGES, BgImage[], [])(d, &backs);
	}

	private string _name;
	/// テキスト。
	void name(string name) {
		if (_name != name) {
			changed;
			if (_type is CType.START && _tree) {
				_tree.startUseCounter.change(toStartId(_name), toStartId(name), true);
			}
		}
		_name = name;
	}
	/// ditto
	string name() {return _name;}

	private Content _parent = null;
	/// 親イベント。
	private void parent(Content parent) in {
		assert (!parent || parent.detail.owner);
	} body {
		if (_parent is parent) return;
		bool oldAreaBr = _parent && _parent.detail.nextType == CNextType.ID_AREA;
		bool oldBattleBr = _parent && _parent.detail.nextType == CNextType.ID_BATTLE;
		bool newAreaBr = parent && parent.detail.nextType == CNextType.ID_AREA;
		bool newBattleBr = parent && parent.detail.nextType == CNextType.ID_BATTLE;
		if (!oldAreaBr && newAreaBr) {
			if (icmp(name, "default") == 0) {
				area = 0;
			} else if (isNumeric(name)) {
				try {
					area = to!(ulong)(name);
				} catch {
					area = 0;
				}
			}
		} else if (oldAreaBr && !newAreaBr) {
			area = 0;
		}
		if (!oldBattleBr && newBattleBr) {
			if (icmp(name, "default") == 0) {
				battle = 0;
			} else if (isNumeric(name)) {
				try {
					battle = to!(ulong)(name);
				} catch {
					battle = 0;
				}
			}
		} else if (oldBattleBr && !newBattleBr) {
			battle = 0;
		}
		_parent = parent;
	}
	/// ditto
	Content parent() {return _parent;}
	override string cwxPath() {
		if (_parent) {
			return cpjoin(_parent, indexOf!("a is b")(_parent.next, this));
		} else if (_tree) {
			return cpjoin(_tree, indexOf!("a is b")(_tree.starts, this));
		}
		return "";
	}
	override CWXPath findCWXPath(string path) {
		if (path == "") return this;
		auto cate = cpcategory(path);
		switch (cate) {
		case "": {
			auto index = cpindex(path);
			if (index >= _next.length) return null;
			return _next[index].findCWXPath(cpbottom(path));
		}
		case "dialog": {
			auto index = cpindex(path);
			if (index >= dialogs.length) return null;
			return dialogs[index].findCWXPath(cpbottom(path));
		}
		case "text": {
			auto index = cpindex(path);
			if (index > 0) return null;
			return _text.findCWXPath(cpbottom(path));
		}
		default: break;
		}
		return null;
	}
	CWXPath[] cwxChilds() {
		CWXPath[] r;
		r ~= cast(CWXPath[]) next;
		r ~= cast(CWXPath[]) dialogs;
		r ~= _text;
		r ~= cast(CWXPath[]) motions;
		r ~= cast(CWXPath[]) backs;
		return r;
	}

	/// EventTreeからこのコンテントに到達するまでのindex群を返す。
	size_t[] ctPath() {
		if (parent) {
			assert (contains!("a is b")(parent.next, this));
			size_t[] r = parent.ctPath;
			r ~= indexOf!("a is b")(parent.next, this);
			return r;
		} else {
			assert (contains!("a is b")(_tree.starts, this));
			return [indexOf!("a is b")(_tree.starts, this)];
		}
	}
	/// このコンテントが属すツリーを返す。
	EventTree tree() {
		auto ps = parentStart;
		if (ps) return ps._tree;
		return null;
	}
	/// このコンテントが属すスタートコンテントを返す。
	Content parentStart() {
		if (type is CType.START) return this;
		if (!parent) return null;
		return parent.parentStart;
	}
	/// パスを辿って子孫のコンテントを返す。
	Content fromPath(size_t[] path) {
		if (!path.length) return this;
		if (path.length == 1) return next[path[0]];
		return next[path[0]].fromPath(path[1 .. $]);
	}

	private Content[] _next = [];
	/// 後続イベント群。
	Content[] next() {return _next;}

	/// 後続コンテントのインデックスを交換する。
	void swapContent(int index1, int index2) {
		if (index1 != index2) changed;
		auto temp = _next[index1];
		_next[index1] = _next[index2];
		_next[index2] = temp;
	}

	/// 後続コンテントを追加する。
	void add(Content c) {
		if (c.parent) c.parent.remove(c);
		c.parent = this;
		if (_uc !is null) c.setUseCounter(useCounter);
		if (_suc !is null) c.setSUseCounter(startUseCounter);
		c.changeHandler = changeHandler;
		_next ~= c;
		changed;
	}
	/// ditto
	void insert(int index, Content c) {
		if (next.length == index) {
			add(c);
		} else {
			if (c.parent) c.parent.remove(c);
			c.parent = this;
			if (_uc !is null) c.setUseCounter(useCounter);
			if (_suc !is null) c.setSUseCounter(startUseCounter);
			c.changeHandler = changeHandler;
			_next = _next[0 .. index] ~ c ~ _next[index .. $];
			changed;
		}
	}

	/// 後続コンテントを除外する。
	void remove(int index) {
		if (_uc !is null) _next[index].removeUseCounter;
		if (_suc !is null) _next[index].removeSUseCounter;
		_next[index].changeHandler = null;
		_next[index].parent = null;
		_next = _next[0 .. index] ~ _next[index + 1 .. $];
		changed;
	}
	/// ditto
	void remove(Content c) {
		foreach (i, ct; _next) {
			if (c is ct) {
				remove(i);
				return;
			}
		}
		assert (0);
	}

	private void setValUCs(T)(T val, UseCounter uc = null, Content c = null) {
		static if (is(typeof(val.owner(this)))) {
			val.owner = this;
		}
		static if (is(typeof(val.setUseCounter(uc)))) {
			if (val.useCounter || !uc) {
				val.removeUseCounter;
			}
			if (uc) {
				val.setUseCounter(uc);
			}
			static if (is(typeof(val.parent))) {
				if (c && val.parent) throw new EventException("used other event.");
				val.parent = c;
			}
		} else static if (!is(T : string) && is(typeof(val[0u]))) {
			foreach (vc; val) {
				setValUCs(vc, uc, c);
			}
		}
	}
	/// Example:
	/// ---
	/// mixin Prop!(AreaUser, "area", 0UL, ".area", ".area", true);
	/// 
	/// private AreaUser _area;
	/// void area(ulong val) {
	/// 	if (!_area) _area = new AreaUser(this);
	/// 	if (_area.area != val) changed;
	/// 	setValUCs(this._area.area, null, null);
	/// 	setValUCs(val, _uc, this);
	/// 	_area.area = val;
	/// }
	/// ulong area() {
	/// 	return _area ? _area.area : 0UL;
	/// }
	/// ---
	private template Prop(T, T2, string Name, T2 Def, string Set = "", string Get = "", bool New = false) {
		static if (New) {
			mixin ("private " ~ T.stringof ~ " _" ~ Name ~ ";");
		} else {
			mixin ("private " ~ T.stringof ~ " _" ~ Name ~ " = Def;");
		}
		mixin ("void " ~ Name ~ "(" ~ T2.stringof ~ " val) {"
			~ "static if (is(typeof(check_" ~ Name ~ "(val)))) {"
			~ "    if (!check_" ~ Name ~ "(val)) throw new EventException(\"Invalid " ~ Name ~ "\");"
			~ "}"
			~ "static if (is(typeof(" ~ Name ~ "_max))) {"
			~ "    if (" ~ Name ~ "_max < val) val = " ~ Name ~ "_max;"
			~ "}"
			~ "static if (is(typeof(" ~ Name ~ "_min))) {"
			~ "    if (" ~ Name ~ "_min > val) val = " ~ Name ~ "_min;"
			~ "}"
			~ (New ? (is(typeof(new T))
				? "if (!_" ~ Name ~ ") _" ~ Name ~ " = new " ~ T.stringof ~ ";"
				~ "setValUCs(_" ~ Name ~ ", _uc, this);"
				: "if (!_" ~ Name ~ ") {"
				~ "    _" ~ Name ~ " = new " ~ T.stringof ~ "(this);"
				~ "    setValUCs(_" ~ Name ~ ", _uc, this);"
				~ "    static if (is(T == AreaUser)) _" ~ Name ~ ".handleChange = &areaChg;"
				~ "    static if (is(T == BattleUser)) _" ~ Name ~ ".handleChange = &battleChg;"
				~ "}"
			) : "")
			~ "if (_" ~ Name ~ Get ~ " != val) changed;"
			~ "setValUCs(this._" ~ Name ~ Get ~ ");"
			~ "setValUCs(val, _uc, this);"
			~ "_" ~ Name ~ Set ~ " = val;"
		"}");
		static if (New) {
			mixin (T2.stringof ~ " " ~ Name ~ "() {return _" ~ Name ~ " ? _" ~ Name ~ Get ~ " : Def;}");
		} else {
			mixin (T2.stringof ~ " " ~ Name ~ "() {return _" ~ Name ~ Get ~ ";}");
		}
	}
	private template Prop(T, string Name, T Def) {
		mixin Prop!(T, T, Name, Def);
	}
	private template MaxMin(T, string Name, T Max, T Min) {
		mixin ("static const T " ~ Name ~ "_max = Max;");
		mixin ("static const T " ~ Name ~ "_min = Min;");
	}

	private string _start = "";
	/// スタート名。
	void start(string start) {
		if (_suc) {
			if (_start) _suc.remove(toStartId(_start), this);
			if (start) _suc.add(toStartId(start), this);
		}
		_start = start;
	}
	/// ditto
	string start() {return _start;}

	/// エリアID。
	mixin Prop!(AreaUser, ulong, "area", 0UL, ".area", ".area", true);
	private bool check_area(ulong id) {
		areaChg(toAreaId(id));
		return true;
	}
	private void areaChg(AreaId id) {
		if (area != id && _parent && _parent.detail.nextType == CNextType.ID_AREA) {
			_name = id == 0 ? "Default" : to!(string)(cast(ulong) id);
		}
	}
	/// バトルID。
	mixin Prop!(BattleUser, ulong, "battle", 0UL, ".battle", ".battle", true);
	private bool check_battle(ulong id) {
		battleChg(toBattleId(id));
		return true;
	}
	private void battleChg(BattleId id) {
		if (battle != id && _parent && _parent.detail.nextType == CNextType.ID_BATTLE) {
			_name = id == 0 ? "Default" : to!(string)(cast(ulong) id);
		}
	}
	/// パッケージID。
	mixin Prop!(PackageUser, ulong, "packages", 0UL, ".packages", ".packages", true);
	/// フラグ。
	mixin Prop!(FlagUser, string, "flag", "", ".flag", ".flag", true);
	/// ステップ。
	mixin Prop!(StepUser, string, "step", "", ".step", ".step", true);
	/// カード画像パス。
	mixin Prop!(PathUser, string, "cardPath", "", ".path", ".path", true);
	/// BGMパス。
	mixin Prop!(PathUser, string, "bgmPath", "", ".path", ".path", true);
	/// SEパス。
	mixin Prop!(PathUser, string, "soundPath", "", ".path", ".path", true);
	/// キャストID。
	mixin Prop!(CastUser, ulong, "casts", 0UL, ".casts", ".casts", true);
	/// アイテムID。
	mixin Prop!(ItemUser, ulong, "item", 0UL, ".item", ".item", true);
	/// スキルID。
	mixin Prop!(SkillUser, ulong, "skill", 0UL, ".skill", ".skill", true);
	/// 召喚獣ID。
	mixin Prop!(BeastUser, ulong, "beast", 0UL, ".beast", ".beast", true);
	/// 情報ID。
	mixin Prop!(InfoUser, ulong, "info", 0UL, ".info", ".info", true);

	/// 効果。
	mixin Prop!(MotionUser, Motion[], "motions", [], ".motions", ".motions", true);

	/// メッセージ。
	mixin Prop!(TextHolder, string, "text", "", ".text", ".text", true);
	/// ダイアログ。
	mixin Prop!(SDialog[], "dialogs", []);

	/// クーポン名。
	mixin Prop!(string, "coupon", "");
	/// ゴシップ。
	mixin Prop!(string, "gossip", "");
	/// 終了印。
	mixin Prop!(string, "completeStamp", "");

	/// 精神系能力。
	mixin Prop!(Mental, "mental", Mental.init);
	/// 肉体系能力。
	mixin Prop!(Physical, "physical", Physical.init);
	/// 状態。
	mixin Prop!(Status, "status", Status.ACTIVE);
	/// 範囲。
	mixin Prop!(Range, "range", Range.SELECTED);
	/// カード視覚効果。
	mixin Prop!(CardVisual, "cardVisual", CardVisual.NONE);
	/// 対象(睡眠者判定含む)。
	mixin Prop!(Target, "targetS", Target(Target.M.SELECTED, true));
	/// 対象(睡眠者判定を行わない)。
	mixin Prop!(Target, "targetNS", Target(Target.M.SELECTED, false));
	private bool check_targetNS(Target val) {return !val.sleep;}
	/// 話者(カード画像含む)。
	mixin Prop!(Talker, "talkerC", Talker.NARRATION);
	/// 話者(カード画像を含めない)。
	mixin Prop!(Talker, "talkerNC", Talker.SELECTED);
	private bool check_talkerNC(Talker val) {
		switch (val) {
		case Talker.SELECTED, Talker.UNSELECTED, Talker.RANDOM: return true;
		case Talker.NARRATION, Talker.CARD, Talker.IMAGE: return false;
		default: assert (0);
		}
	}
	/// 効果タイプ。
	mixin Prop!(EffectType, "effectType", EffectType.NONE);
	/// 抵抗属性。
	mixin Prop!(Resist, "resist", Resist.UNFAIL);
	/// 背景切替方式。
	mixin Prop!(Transition, "transition", Transition.DEFAULT);

	/// 全員を対象とするか。
	mixin Prop!(bool, "targetAll", true);
	/// 対象をランダムに選ぶか。
	mixin Prop!(bool, "random", false);
	/// 平均を取るか。
	mixin Prop!(bool, "average", false);
	/// 済印を付けるか否か。
	mixin Prop!(bool, "complete", false);

	/// レベル。
	mixin Prop!(int, "unsignedLevel", 1);
	mixin MaxMin!(int, "unsignedLevel", 99, 1);
	/// マイナスにする事が可能なレベル。
	mixin Prop!(int, "signedLevel", 0);
	mixin MaxMin!(int, "signedLevel", 99, -99);
	/// 命中補正。-5～+5。
	mixin Prop!(int, "successRate", 5);
	mixin MaxMin!(int, "successRate", 5, -5);
	/// 背景切替スピード。0～10で、0はアニメーション無しと等価。
	mixin Prop!(int, "transitionSpeed", 5u);
	mixin MaxMin!(int, "transitionSpeed", 10, 0);
	/// 百分率値。
	mixin Prop!(int, "percent", 50u);
	mixin MaxMin!(int, "percent", 100, 0);
	/// フラグ値。
	mixin Prop!(bool, "flagValue", true);
	/// ステップ値。
	mixin Prop!(int, "stepValue", 0u);
	mixin MaxMin!(int, "stepValue", int.max, 0);
	/// クーポン点。
	mixin Prop!(int, "couponValue", 0);
	mixin MaxMin!(int, "couponValue", 999, -999);
	/// 人数。
	mixin Prop!(int, "partyNumber", 1u);
	mixin MaxMin!(int, "partyNumber", int.max, 1);
	/// カード枚数。
	mixin Prop!(int, "cardNumber", 1u);
	mixin MaxMin!(int, "cardNumber", 99, 0);
	/// 金額。
	mixin Prop!(int, "money", 0u);
	mixin MaxMin!(int, "money", 999999, 0);
	/// 停止時間。0.1秒単位。
	mixin Prop!(int, "wait", 0u);
	mixin MaxMin!(int, "wait", 1000, 0);

	/// 背景画像群。
	mixin Prop!(BgImage[], "backs", []);

	private void delegate() _change;
	/// 変更ハンドラを登録する。
	void changeHandler(void delegate() change) {
		foreach (c; _next) {
			c.changeHandler = change;
		}
		_change = change;
	}
	/// 変更ハンドラ。
	private void delegate() changeHandler() {
		return _change;
	}
	/// 変更を通知する。
	private void changed() {
		if (_change) _change();
	}

	private UseCounter _uc = null;
	private void setUseCounterImpl(T)(ref T v, UseCounter uc) {
		static if (is(T : EventTree)) return;
		static if (is(T : Content)) if (parent is v) return;
		static if (is(typeof(v.setUseCounter(uc)))) {
			static if (is(typeof(v is null))) if (!v) return;
			if (uc) {
				v.setUseCounter(uc);
			} else {
				v.removeUseCounter;
			}
		} else static if (!is(v : string) && is(typeof(v[0u]))) {
			foreach (ref vc; v) {
				setUseCounterImpl(vc, uc);
			}
		}
	}
	/// 使用回数カウンタを設定・除去する。
	void setUseCounter(UseCounter uc) {
		foreach (v; this.tupleof) {
			setUseCounterImpl(v, uc);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		setUseCounter(null);
		_uc = null;
	}
	/// 使用回数カウンタを返す。存在しない場合はnullを返す。
	UseCounter useCounter() {return _uc;}

	private SUseCounter _suc = null;
	/// スタートの使用回数カウンタを設定・除去する。
	void setSUseCounter(SUseCounter suc) {
		if (_suc is suc) return;
		if (suc && _start) {
			suc.add(toStartId(_start), this);
		}
		if (_suc && _start) {
			_suc.remove(toStartId(_start), this);
		}
		foreach (c; next) {
			c.setSUseCounter(suc);
		}
		_suc = suc;
	}
	/// ditto
	void removeSUseCounter() {
		if (_suc && _start) {
			_suc.remove(toStartId(_start), this);
		}
		foreach (c; next) {
			c.removeSUseCounter;
		}
		_suc = null;
	}
	/// スタートの使用回数カウンタ。
	SUseCounter startUseCounter() {return _suc;}
	override void change(StartId newVal) {
		_start = newVal;
	}

	private void idChangeImpl(T, Id)(ref T v, Id id) {
		static if (is(T : EventTree)) return;
		static if (is(T : Content)) if (parent is v) return;
		static if (is(typeof(v.change(id)))) {
			static if (is(typeof(v is null))) if (!v) return;
			v.change(id);
		} else static if (!is(v : string) && is(typeof(v[0u]))) {
			foreach (ref vc; v) {
				idChangeImpl(vc, id);
			}
		}
	}
	private void idChange(Id)(Id id) {
		foreach (v; this.tupleof) {
			idChangeImpl(v, id);
		}
	}
	override void change(PathId id) {idChange(id);}
	override void change(AreaId id) {idChange(id);}
	override void change(BattleId id) {idChange(id);}
	override void change(PackageId id) {idChange(id);}
	override void change(FlagId id) {idChange(id);}
	override void change(StepId id) {idChange(id);}
	override void change(CastId id) {idChange(id);}
	override void change(ItemId id) {idChange(id);}
	override void change(SkillId id) {idChange(id);}
	override void change(BeastId id) {idChange(id);}
	override void change(InfoId id) {idChange(id);}

	/// コンテントをXMLテキストにして返す。
	string toXML() {
		return toNode.text;
	}
	/// コンテントをXMLノードにして返す。
	XNode toNode() {
		auto d = this.detail;
		auto doc = XNode.create(d.name);
		toNodeImpl(doc, d);
		doc.newAttr("contentId", _id);
		return doc;
	}
	private void atnPut(CArg ARG, string Name, string From)(ref XNode en, in CDetail d) {
		if (d.use(ARG)) {
			mixin ("en.newAttr(d.attr(ARG), " ~ From ~ "(this." ~ Name ~ "));");
		}
	}
	/// 指定されたXMLノードにインスタンスのデータを追加する。
	XNode toNode(ref XNode parent) {
		auto d = this.detail;
		auto e = parent.newElement(d.name);
		toNodeImpl(e, d);
		return e;
	}
	private void toNodeImpl(ref XNode e, in CDetail d) {
		if (d.type.length) e.newAttr("type", d.type);
		if (name.length) e.newAttr("name", name);

		// 単純データ
		atnPut!(CArg.AREA, "area", "")(e, d);
		atnPut!(CArg.BATTLE, "battle", "")(e, d);
		atnPut!(CArg.PACKAGE, "packages", "")(e, d);
		atnPut!(CArg.FLAG, "flag", "")(e, d);
		atnPut!(CArg.STEP, "step", "")(e, d);
		atnPut!(CArg.BGM_PATH, "bgmPath", "encodePath")(e, d);
		atnPut!(CArg.SOUND_PATH, "soundPath", "encodePath")(e, d);
		atnPut!(CArg.CAST, "casts", "")(e, d);
		atnPut!(CArg.ITEM, "item", "")(e, d);
		atnPut!(CArg.SKILL, "skill", "")(e, d);
		atnPut!(CArg.BEAST, "beast", "")(e, d);
		atnPut!(CArg.INFO, "info", "")(e, d);

		atnPut!(CArg.START, "start", "")(e, d);
		atnPut!(CArg.COUPON, "coupon", "")(e, d);
		atnPut!(CArg.GOSSIP, "gossip", "")(e, d);
		atnPut!(CArg.COMPLETE_STAMP, "completeStamp", "")(e, d);

		atnPut!(CArg.MENTAL, "mental", "fromMental")(e, d);
		atnPut!(CArg.PHYSICAL, "physical", "fromPhysical")(e, d);
		atnPut!(CArg.STATUS, "status", "fromStatus")(e, d);
		atnPut!(CArg.RANGE, "range", "fromRange")(e, d);
		atnPut!(CArg.CARD_VISUAL, "cardVisual", "fromCardVisual")(e, d);
		atnPut!(CArg.EFFECT_TYPE, "effectType", "fromEffectType")(e, d);
		atnPut!(CArg.RESIST, "resist", "fromResist")(e, d);
		atnPut!(CArg.TRANSITION, "transition", "fromTransition")(e, d);

		atnPut!(CArg.TARGET_ALL, "targetAll", "fromBool")(e, d);
		atnPut!(CArg.RANDOM, "random", "fromBool")(e, d);
		atnPut!(CArg.AVERAGE, "average", "fromBool")(e, d);
		atnPut!(CArg.COMPLETE, "complete", "fromBool")(e, d);

		atnPut!(CArg.UNSIGNED_LEVEL, "unsignedLevel", "")(e, d);
		atnPut!(CArg.SIGNED_LEVEL, "signedLevel", "")(e, d);
		atnPut!(CArg.SUCCESS_RATE, "successRate", "")(e, d);
		atnPut!(CArg.TRANSITION_SPEED, "transitionSpeed", "")(e, d);
		atnPut!(CArg.PERCENT, "percent", "")(e, d);
		atnPut!(CArg.FLAG_VALUE, "flagValue", "fromBool")(e, d);
		atnPut!(CArg.STEP_VALUE, "stepValue", "")(e, d);
		atnPut!(CArg.COUPON_VALUE, "couponValue", "")(e, d);
		atnPut!(CArg.PARTY_NUMBER, "partyNumber", "")(e, d);
		atnPut!(CArg.CARD_NUMBER, "cardNumber", "")(e, d);
		atnPut!(CArg.MONEY, "money", "")(e, d);
		atnPut!(CArg.WAIT, "wait", "")(e, d);

		// 多少複雑なもの
		if (d.use(CArg.MOTIONS)) {
			auto me = e.newElement("Motions");
			foreach (m; motions) {
				m.toNode(me);
			}
		}

		if (d.use(CArg.TEXT)) e.newElement("Text", encodeLf(text));
		if (d.use(CArg.DIALOGS)) {
			auto de = e.newElement("Dialogs");
			foreach (dlg; dialogs) {
				dlg.toNode(de);
			}
		}

		atnPut!(CArg.TARGET_NS, "targetNS", "fromTarget")(e, d);
		atnPut!(CArg.TARGET_S, "targetS", "fromTarget")(e, d);
		if (d.use(CArg.TALKER_C)) {
			switch (talkerC) {
			case Talker.NARRATION:
				e.newAttr(d.attr(CArg.TALKER_C), "");
				break;
			case Talker.SELECTED, Talker.UNSELECTED, Talker.RANDOM, Talker.CARD:
				e.newAttr(d.attr(CArg.TALKER_C), "Material/??" ~ fromTalker(talkerC));
				break;
			case Talker.IMAGE:
				e.newAttr("path", encodePath(cardPath));
				break;
			}
		}
		atnPut!(CArg.TALKER_NC, "talkerNC", "fromTalker")(e, d);

		if (d.use(CArg.BG_IMAGES)) BgImage.toNode(backs, e);

		auto ce = e.newElement("Contents");
		foreach (sub; _next) {
			sub.toNode(ce);
		}
	}
	/// XMLノード(Contents)の直下にある全てのイベントを、
	/// 後続のツリーを全て含めて生成する。
	static Content[] createContentsFromNode(ref XNode node, string ver) {
		assert (node.name == "Contents", node.name ~ " != Contents");
		Content[] r;
		node.onTag[null] = (ref XNode en) {
			r ~= createFromNode(en, ver);
		};
		node.parse;
		return r;
	}
	/// XMLテキストからイベントを生成する。
	static Content createFromXML(string xml, string ver, out string id) {
		id = "";
		auto en = XNode.parse(xml);
		id = en.attr("contentId", false);
		return createFromNode(en, ver);
	}
	private static void cfnPut(CArg ARG, string Name, string To)(in XNode en, in CDetail d, ref Content c) {
		if (d.use(ARG)) {
			mixin ("c." ~ Name ~ " = " ~ To ~ "(en.attr(d.attr(ARG), true));");
		}
	}
	/// XMLノードからイベントを生成する。
	static Content createFromNode(ref XNode en, string ver) {
		auto nmap = en.name in CTYPE_MAP;
		if (!nmap) return null;
		auto t = en.attr("type", false) in *nmap;
		if (!t) return null;
		auto cType = *t;
		auto d = CONTENT_DETAILS[cType];
		string name = en.attr("name", false);
		auto r = new Content(cType, name);

		// 単純データ
		cfnPut!(CArg.AREA, "area", "to!(ulong)")(en, d, r);
		cfnPut!(CArg.BATTLE, "battle", "to!(ulong)")(en, d, r);
		cfnPut!(CArg.PACKAGE, "packages", "to!(ulong)")(en, d, r);
		cfnPut!(CArg.FLAG, "flag", "")(en, d, r);
		cfnPut!(CArg.STEP, "step", "")(en, d, r);
		cfnPut!(CArg.BGM_PATH, "bgmPath", "decodePath")(en, d, r);
		cfnPut!(CArg.SOUND_PATH, "soundPath", "decodePath")(en, d, r);
		cfnPut!(CArg.CAST, "casts", "to!(ulong)")(en, d, r);
		cfnPut!(CArg.ITEM, "item", "to!(ulong)")(en, d, r);
		cfnPut!(CArg.SKILL, "skill", "to!(ulong)")(en, d, r);
		cfnPut!(CArg.BEAST, "beast", "to!(ulong)")(en, d, r);
		cfnPut!(CArg.INFO, "info", "to!(ulong)")(en, d, r);

		cfnPut!(CArg.START, "start", "")(en, d, r);
		cfnPut!(CArg.COUPON, "coupon", "")(en, d, r);
		cfnPut!(CArg.GOSSIP, "gossip", "")(en, d, r);
		cfnPut!(CArg.COMPLETE_STAMP, "completeStamp", "")(en, d, r);

		cfnPut!(CArg.MENTAL, "mental", "toMental")(en, d, r);
		cfnPut!(CArg.PHYSICAL, "physical", "toPhysical")(en, d, r);
		cfnPut!(CArg.STATUS, "status", "toStatus")(en, d, r);
		cfnPut!(CArg.RANGE, "range", "toRange")(en, d, r);
		cfnPut!(CArg.CARD_VISUAL, "cardVisual", "toCardVisual")(en, d, r);
		cfnPut!(CArg.EFFECT_TYPE, "effectType", "toEffectType")(en, d, r);
		cfnPut!(CArg.RESIST, "resist", "toResist")(en, d, r);

		cfnPut!(CArg.TARGET_ALL, "targetAll", "parseBool")(en, d, r);
		cfnPut!(CArg.RANDOM, "random", "parseBool")(en, d, r);
		cfnPut!(CArg.AVERAGE, "average", "parseBool")(en, d, r);
		cfnPut!(CArg.COMPLETE, "complete", "parseBool")(en, d, r);

		cfnPut!(CArg.UNSIGNED_LEVEL, "unsignedLevel", "to!(int)")(en, d, r);
		cfnPut!(CArg.SIGNED_LEVEL, "signedLevel", "to!(int)")(en, d, r);
		cfnPut!(CArg.SUCCESS_RATE, "successRate", "to!(int)")(en, d, r);
		cfnPut!(CArg.PERCENT, "percent", "to!(int)")(en, d, r);
		cfnPut!(CArg.FLAG_VALUE, "flagValue", "parseBool")(en, d, r);
		cfnPut!(CArg.STEP_VALUE, "stepValue", "to!(int)")(en, d, r);
		cfnPut!(CArg.COUPON_VALUE, "couponValue", "to!(int)")(en, d, r);
		cfnPut!(CArg.PARTY_NUMBER, "partyNumber", "to!(int)")(en, d, r);
		cfnPut!(CArg.CARD_NUMBER, "cardNumber", "to!(int)")(en, d, r);
		cfnPut!(CArg.MONEY, "money", "to!(int)")(en, d, r);
		cfnPut!(CArg.WAIT, "wait", "to!(int)")(en, d, r);

		// 多少複雑なもの
		if (d.use(CArg.TRANSITION)) {
			// 歴史的経緯から、transitionは値が存在しない可能性がある
			auto s = en.attr(d.attr(CArg.TRANSITION), false);
			if (s.length) r.transition = toTransition(s);
		}
		if (d.use(CArg.TRANSITION_SPEED)) {
			auto s = en.attr(d.attr(CArg.TRANSITION_SPEED), false);
			if (s.length) r.transitionSpeed = to!(int)(s);
		}
		if (d.use(CArg.MOTIONS)) {
			en.onTag["Motions"] = (ref XNode node) {
				Motion[] motions;
				node.onTag["Motion"] = (ref XNode node) {
					motions ~= Motion.createFromNode(node, ver);
				};
				node.parse;
				r.motions = motions;
			};
		}

		if (d.use(CArg.TEXT)) {
			en.onTag["Text"] = (ref XNode node) {r.text = decodeLf2(node.value);};
		}
		if (d.use(CArg.DIALOGS)) {
			en.onTag["Dialogs"] = (ref XNode node) {
				SDialog[] dlgs;
				node.onTag["Dialog"] = (ref XNode node) {
					dlgs ~= SDialog.createFromNode(node, ver);
				};
				node.parse;
				if (dlgs.length == 0) dlgs ~= new SDialog;
				r.dialogs = dlgs;
			};
		}

		Target loadTarget(bool canSleep = true) {
			auto targ = toTarget(en.attr("targetm", true));
			if (!canSleep && targ.sleep) targ = Target(targ.m, false);
			return targ;
		}
		if (d.use(CArg.TARGET_S)) r.targetS = loadTarget(true);
		if (d.use(CArg.TARGET_NS)) r.targetNS = loadTarget(false);
		if (d.use(CArg.TALKER_C) || d.use(CArg.TALKER_NC)) {
			Talker talker;
			string path;
			loadTalker(en, talker, path);
			if (d.use(CArg.TALKER_NC)) {
				// TALKER_NCは画像を使用しないため不正
				if (path) throw new EventException("invalid talker: " ~ path);
				r.talkerNC = talker;
			}
			if (d.use(CArg.TALKER_C)) {
				r.talkerC = talker;
			}
			r.cardPath = path;
		}

		if (d.use(CArg.BG_IMAGES)) {
			en.onTag["BgImages"] = (ref XNode node) {
				r.backs = BgImage.bgImagesFromNode(node, ver);
			};
		}

		if (d.owner) {
			en.onTag["Contents"] = (ref XNode node) {
				foreach (c; createContentsFromNode(node, ver)) {
					r.add(c);
				}
			};
		}
		en.parse;
		return r;
	}
}

/// 指定されたXMLノードからtargetmと話者のデータを読み込む。
private void loadTalker(in XNode node, out Talker talker, out string path = null) {
	string t = node.attr("targetm", false);
	if (t.length == 0) {
		auto pathTemp = node.attr("path", false);
		if (!pathTemp || !pathTemp.length) {
			talker = Talker.NARRATION;
		} else if (endsWith(pathTemp, "??Selected")) {
			talker = Talker.SELECTED;
		} else if (endsWith(pathTemp, "??Unselected")) {
			talker = Talker.UNSELECTED;
		} else if (endsWith(pathTemp, "??Random")) {
			talker = Talker.RANDOM;
		} else if (endsWith(pathTemp, "??Card")) {
			talker = Talker.CARD;
		} else {
			talker = Talker.IMAGE;
			path = decodePath(pathTemp);
		}
	} else {
		switch (t) {
		case "Selected":
			talker = Talker.SELECTED;
			break;
		case "Unselected":
			talker = Talker.UNSELECTED;
			break;
		case "Random":
			talker = Talker.RANDOM;
			break;
		case "Card":
			talker = Talker.CARD;
			break;
		default:
			throw new EventException("Unknown targetm: " ~ t);
		}
	}
}
/// Talkerを文字列に変換する。
private string fromTalker(Talker talker) {
	switch (talker) {
	case Talker.SELECTED:
		return "Selected";
	case Talker.UNSELECTED:
		return "Unselected";
	case Talker.RANDOM:
		return "Random";
	case Talker.CARD:
		return "Card";
	}
}

/// イベントツリー。発火条件と実行するイベント群を持つ。
public class EventTree : CWXPath {
private:
	EventTreeOwner _owner;

	/// 開始条件群
	bool _enter = false;
	bool _escape = false;
	bool _lose = false;
	uint[] _rounds;

	string[] _keyCodes;

	Content[] _starts;
	UseCounter _uc;
	SUseCounter _suc;
	void delegate() _change = null;

	this(Content[] starts) in {
		foreach (c; starts) {
			assert (c.type is CType.START);
		}
	} body {
		_suc = new SUseCounter;
		_starts = starts;
		foreach (s; _starts) {
			s._tree = this;
			s.setSUseCounter(_suc);
		}
	}
	this() {
		_suc = new SUseCounter;
	}
public:
	/// イベントツリー名を指定してインスタンスを生成。
	this(string name) {
		this(new Content(CType.START, name));
	}
	/// スタートコンテントを指定してインスタンスを生成。
	/// startがすでにイベントツリーに所属している場合、
	/// コピーが生成される。
	this(Content start) in {
		assert (start.type == CType.START);
	} body {
		_suc = new SUseCounter;
		if (start.tree) {
			start = start.createFromNode(start.toNode, LATEST_VERSION);
		}
		add(start);
	}
	EventTreeOwner owner() {return _owner;}
	override string cwxPath() {
		return _owner ? cpjoin(_owner, "event", indexOf!("a is b")(_owner.trees, this)) : "";
	}
	CWXPath findCWXPath(string path) {
		if (path == "") return this;
		auto cate = cpcategory(path);
		if (cate == "") {
			auto index = cpindex(path);
			if (index >= _starts.length) return null;
			return _starts[index].findCWXPath(cpbottom(path));
		}
		return null;
	}
	CWXPath[] cwxChilds() {
		CWXPath[] r;
		r ~= cast(CWXPath[]) starts;
		return r;
	}
	/// 変更ハンドラを登録する。
	void changeHandler(void delegate() change) {
		foreach (s; _starts) {
			s.changeHandler = change;
		}
		_change = change;
	}
	/// 変更ハンドラを返す。
	protected void delegate() changeHandler() {
		return _change;
	}
	/// 変更を通知する。
	protected void changed() {
		if (_change) _change();
	}

	/// イベントツリー名。
	/// 最初のスタートコンテントのテキストと常に一致する。
	void name(string name) {
		if (_starts[0].name != name) changed;
		_starts[0].name = name;
	}
	/// ditto
	string name() {
		return _starts[0].name;
	}

	/// スタートコンテントのインデックスを交換。
	void swapStart(int index1, int index2) {
		if (index1 != index2) changed;
		auto temp = _starts[index1];
		_starts[index1] = _starts[index2];
		_starts[index2] = temp;
	}
	/// キーコードのインデックスを交換。
	void swapKeyCode(int index1, int index2) {
		if (index1 != index2) changed;
		auto temp = _keyCodes[index1];
		_keyCodes[index1] = _keyCodes[index2];
		_keyCodes[index2] = temp;
	}

	/// スタートコンテントを追加する。
	void add(Content evt) in {
		assert (evt.type is CType.START);
	} body {
		if (_uc !is null) {
			evt.setUseCounter(_uc);
		}
		evt.setSUseCounter(_suc);
		evt._tree = this;
		evt.changeHandler = changeHandler;
		_starts ~= evt;
		changed;
	}
	/// ditto
	void insert(int index, Content evt) in {
		assert (evt.type is CType.START);
	} body {
		if (_uc !is null) {
			evt.setUseCounter(_uc);
		}
		evt.setSUseCounter(_suc);
		evt._tree = this;
		evt.changeHandler = changeHandler;
		_starts = _starts[0u .. index] ~ evt ~ _starts[index .. $];
		changed;
	}
	/// スタートコンテントを除外。
	void remove(int index) in {
		assert (_starts.length > 1);
	} body {
		if (_uc !is null) {
			_starts[index].removeUseCounter;
		}
		_starts[index].removeSUseCounter;
		_starts[index]._tree = null;
		_starts[index].changeHandler = null;
		_starts = _starts[0 .. index] ~ _starts[index + 1 .. $];
	}
	/// ditto
	void remove(Content start) in {
		assert (start.type is CType.START);
	} body {
		foreach (i, s; _starts) {
			if (s is start) {
				remove(i);
				return;
			}
		}
		assert (0);
	}
	/// スタートコンテント群。
	Content[] starts() out (r) {
		foreach (c; r) {
			assert (c.type is CType.START);
		}
	} body {
		return _starts;
	}
	/// 属するエリア等からの相対パスを返す。
	size_t[] areaPath() {
		if (_owner) {
			return _owner.areaPath ~ cast(size_t) indexOf!("a is b")(_owner.trees, this);
		} else {
			return [];
		}
	}
	/// パスを辿ってコンテントを返す。
	Content fromPath(size_t[] path) {
		if (!path.length) return null;
		if (path.length == 1) return starts[path[0]];
		return starts[path[0]].fromPath(path[1 .. $]);
	}

	/// 指定されたインデックスのキーコードを差し替える。
	void setKeyCode(int index, string keyCode) {
		if (_keyCodes[index] != keyCode) changed;
		_keyCodes[index] = keyCode;
	}

	/// 使用回数カウンタを設定する。
	void setUseCounter(UseCounter uc) {
		foreach (s; starts) {
			s.setUseCounter(uc);
		}
		_uc = uc;
	}
	/// 使用回数カウンタを外す。
	void removeUseCounter() {
		foreach (s; starts) {
			s.removeUseCounter;
		}
		_uc = null;
	}

	/// スタートの使用回数カウンタ。
	SUseCounter startUseCounter() {return _suc;}

	/// エリア到着時・クリック時・パッケージ開始時・勝利・死亡時に発火するか。
	void enter(bool enter) {
		if (_enter != enter) changed;
		_enter = enter;
	}
	/// ditto
	bool fireEnter() {
		return _enter;
	}

	/// 逃走時に発火するか。
	void escape(bool escape) {
		if (_escape != escape) changed;
		_escape = escape;
	}
	/// ditto
	bool fireEscape() {
		return _escape;
	}

	/// 敗北時に発火するか。
	void lose(bool lose) {
		if (_lose != lose) changed;
		_lose = lose;
	}
	/// ditto
	bool fireLose() {
		return _lose;
	}

	/// 発火ラウンドを追加。追加できた場合はtrueを返す。
	bool addRound(uint round) {
		if (!fireRound(round)) {
			changed;
			_rounds ~= round;
			return true;
		}
		return false;
	}
	/// ditto
	bool addRounds(uint[] rounds) {
		auto s = new HashSet!(uint);
		foreach (r; _rounds) s.add(r);
		foreach (r; rounds) s.add(r);
		rounds = s.toArray.sort;
		if (rounds != _rounds) {
			changed;
			_rounds = rounds;
			return true;
		}
		return false;
	}
	/// 指定されたラウンドで発火するか。
	bool fireRound(uint round) {
		foreach (r; _rounds) {
			if (r == round) {
				return true;
			}
		}
		return false;
	}
	/// 発火ラウンド群。
	uint[] rounds() {
		return _rounds;
	}
	/// 発火ラウンドを除去。
	void removeRound(uint round) {
		foreach (i, r; _rounds) {
			if (r == round) {
				_rounds = _rounds[0 .. i] ~ _rounds[i + 1 .. $];
				return;
			}
		}
		assert (0);
	}
	/// ditto
	void removeRoundsAll() {
		_rounds.length = 0;
	}

	/// 発火キーコードを追加。
	/// Returns: 追加できた場合はtrue。
	bool addKeyCode(string keyCode) {
		if (!fireKeyCode(keyCode)) {
			changed;
			_keyCodes ~= keyCode;
			return true;
		}
		return false;
	}
	/// 指定されたキーコードで発火するか。
	bool fireKeyCode(string keyCode) {
		foreach (kc; _keyCodes) {
			if (kc == keyCode) {
				return true;
			}
		}
		return false;
	}
	/// 発火キーコード群。
	string[] keyCodes() {
		return _keyCodes;
	}
	/// ditto
	void keyCodes(string[] keyCodes) {
		if (_keyCodes != keyCodes) changed;
		_keyCodes = keyCodes;
	}
	/// 発火キーコードを除去。
	void removeKeyCode(string keyCode) {
		foreach (i, kc; _keyCodes) {
			if (kc == keyCode) {
				_keyCodes = _keyCodes[0 .. i] ~ _keyCodes[i + 1 .. $];
				return;
			}
		}
		assert (0);
	}
	/// ditto
	void removeKeyCodesAll() {
		_keyCodes.length = 0;
	}

	/// イベントツリーをXMLテキストにする。
	string toXML() {
		return toNode.text;
	}
	/// イベントツリーをXMLノードにする。
	XNode toNode() {
		auto doc = XNode.create("Event");
		__toNode(doc);
		return doc;
	}
	/// 指定されたXMLノード(Events)にこのインスタンスのデータを追加する。
	void toNode(ref XNode node) {
		assert (node.name == "Events", node.name ~ " != Events");
		__toNode(node.newElement("Event"));
	}
	private void __toNode(ref XNode node) {
		assert (node.name == "Event", node.name ~ " != Event");
		if (_enter || _escape || _lose || _rounds.length > 0 || _keyCodes.length > 0) {
			auto ig = node.newElement("Ignitions");
			string[] nums;
			if (_enter) nums ~= "1";
			if (_escape) nums ~= "2";
			if (_lose) nums ~= "3";
			foreach (r; _rounds) {
				nums ~= ("-" ~ to!(string)(r));
			}
			ig.newElement("Number", encodeLf(nums, false));
			ig.newElement("KeyCodes", encodeLf(_keyCodes));
		}
		auto c = node.newElement("Contents");
		foreach (st; _starts) {
			st.toNode(c);
		}
	}

	/// XMLテキストからインスタンスを生成。
	static EventTree fromXML(string xml, string ver) {
		try {
			scope doc = XNode.parse(xml);
			if (doc.name == "Event") {
				return createFromNode(doc, ver);
			}
		} catch {}
		return null;
	}
	/// XMLノードからインスタンスを生成。
	/// スタートコンテントが一つも無かった場合はnullを返す。
	static EventTree createFromNode(ref XNode node, string ver) {
		assert (node.name == "Event", node.name ~ " != Event");
		auto r = new EventTree;
		node.onTag["Contents"] = (ref XNode node) {
			node.onTag["Start"] = (ref XNode node) {
				r.add(Content.createFromNode(node, ver));
			};
			node.parse;
		};
		node.onTag["Ignitions"] = (ref XNode node) {
			node.onTag["Number"] = (ref XNode n) {
				foreach (v; decodeLf(n.value)) {
					switch (v) {
					case "1":
						r._enter = true;
						break;
					case "2":
						r._escape = true;
						break;
					case "3":
						r._lose = true;
						break;
					default:
						if (v.length > 1 && v[0] == '-') {
							r._rounds ~= to!(int)(v[1 .. $]);
						}
						break;
					}
				}
			};
			node.onTag["KeyCodes"] = (ref XNode n) {
				auto val = n.value;
				if (val.length > 0) {
					foreach (kc; decodeLf(val)) {
						r.addKeyCode = kc;
					}
				}
			};
			node.parse;
		};
		node.parse;
		return r.starts.length > 0 ? r : null;
	}

	private static string __fireToXML(string name, string att = null, string value = null) {
		auto e = XNode.create(name);
		if (att && value) {
			e.newAttr(att, value);
		}
		return e.text;
	}
	/// 「到着時発火」をXMLテキスト化する。
	static string enterToXML() {return __fireToXML("FireEnter");}
	/// 「逃走時発火」をXMLテキスト化する。
	static string escapeToXML() {return __fireToXML("FireEscape");}
	/// 「敗北時発火」をXMLテキスト化する。
	static string loseToXML() {return __fireToXML("FireLose");}
	/// 「発火ラウンド」をXMLテキスト化する。
	static string roundToXML(uint round) {
		return __fireToXML("FireRound", "round", to!(string)(round));
	}
	/// 「発火キーコード」をXMLテキスト化する。
	static string keyCodeToXML(string keyCode) {
		return __fireToXML("FireKeyCode", "keyCode", keyCode);
	}
	private static bool __fireFromXML(string xml, string name, void delegate(bool) fire) {
		try {
			auto node = XNode.parse(xml);
			if (node.name == name) {
				fire(true);
				return true;
			}
		} catch {}
		return false;
	}
	/// 「到着時発火」をXMLテキストからロードし、成功すればtrueを返す。
	bool enterFromXML(EventTreeOwner owner, string xml) {
		return owner.canHasFireEnter && __fireFromXML(xml, "FireEnter", &enter);
	}
	/// 「逃走時発火」をXMLテキストからロードし、成功すればtrueを返す。
	bool escapeFromXML(EventTreeOwner owner, string xml) {
		return owner.canHasFireEscape && __fireFromXML(xml, "FireEscape", &escape);
	}
	/// 「敗北時発火」をXMLテキストからロードし、成功すればtrueを返す。
	bool loseFromXML(EventTreeOwner owner, string xml) {
		return owner.canHasFireLose && __fireFromXML(xml, "FireLose", &lose);
	}
	/// 「発火ラウンド」をXMLテキストからロードし、成功すればtrueを返す。
	int roundFromXML(EventTreeOwner owner, string xml) {
		if (owner.canHasFireRound) {
			try {
				auto node = XNode.parse(xml);
				if (node.name == "FireRound") {
					int r = node.attr!(int)("round", true);
					addRound(r);
					return r;
				}
			} catch {}
		}
		return -1;
	}
	/// 「発火キーコード」をXMLテキストからロードし、成功すればtrueを返す。
	string keyCodeFromXML(EventTreeOwner owner, string xml) {
		if (owner.canHasFireKeyCode) {
			try {
				auto node = XNode.parse(xml);
				if (node.name == "FireKeyCode") {
					string r = node.attr("keyCode", true);
					addKeyCode(r);
					return r;
				}
			} catch {}
		}
		return null;
	}
}

/// イベントツリーの所持者。エリアや効果カード等。
public interface EventTreeOwner : CWXPath {
	/// イベントツリー群。
	EventTree[] trees();

	/// 発火条件「到着時」に対応しているか。
	bool canHasFireEnter();
	/// 発火条件「敗北時」に対応しているか。
	bool canHasFireLose();
	/// 発火条件「逃走時」に対応しているか。
	bool canHasFireEscape();
	/// 発火条件「ラウンド」に対応しているか。
	bool canHasFireRound();
	/// 発火条件「キーコード」に対応しているか。
	bool canHasFireKeyCode();

	/// イベントツリーを追加・除去する。
	void add(EventTree evt);
	/// ditto
	void insert(int index, EventTree evt);
	/// ditto
	void removeEvent(int index);
	/// ditto
	void remove(EventTree et);
	/// イベントツリーのインデックスを交換。
	void swapEventTree(int index1, int index2);

	/// 属すエリア等からの相対パス。
	size_t[] areaPath();
}

/// EventTreeOwnerの仮の実装。
public abstract class AbstractEventTreeOwner : EventTreeOwner {
private:
	EventTree[] _evts;
	UseCounter _uc;
	void delegate() _change;
public:
	override abstract size_t[] areaPath();

	CWXPath findCWXPath(string path) {
		if (path == "") return this;
		auto cate = cpcategory(path);
		if (cate == "event") {
			auto index = cpindex(path);
			if (index >= _evts.length) return null;
			return _evts[index].findCWXPath(cpbottom(path));
		}
		return null;
	}
	CWXPath[] cwxChilds() {
		CWXPath[] r;
		r ~= cast(CWXPath[]) trees;
		return r;
	}

	/// 使用回数カウンタ。
	UseCounter useCounter() {
		return _uc;
	}
	/// 変更ハンドラを登録する。
	void changeHandler(void delegate() change) {
		foreach (e; _evts) {
			e.changeHandler = change;
		}
		_change = change;
	}
	/// 変更ハンドラ。
	protected void delegate() changeHandler() {
		return _change;
	}
	/// 変更を通知する。
	protected void changed() {
		if (_change) _change();
	}
	/// 委譲によって使用する場合は委譲元を返す。
	protected EventTreeOwner con() {return this;}

	EventTree[] trees() {
		return _evts;
	}

	void swapEventTree(int index1, int index2) {
		if (index1 != index2) changed;
		auto temp = _evts[index1];
		_evts[index1] = _evts[index2];
		_evts[index2] = temp;
	}

	void addAll(EventTree[] evts) {
		foreach (e; evts) {
			add(e);
		}
	}
	private void addCmn(EventTree evt) {
		if (!canHasFireEnter) evt.enter = false;
		if (!canHasFireLose) evt.lose = false;
		if (!canHasFireEscape) evt.escape = false;
		if (!canHasFireRound) evt.removeRoundsAll;
		if (!canHasFireKeyCode) evt.removeKeyCodesAll;

		if (_uc !is null) {
			evt.setUseCounter(_uc);
		}
		evt.changeHandler = changeHandler;
		evt._owner = con;
		changed;
	}
	void add(EventTree evt) {
		addCmn(evt);
		_evts ~= evt;
	}
	void insert(int index, EventTree evt) {
		if (_evts.length == index) {
			add(evt);
		} else {
			addCmn(evt);
			_evts = _evts[0 .. index] ~ evt ~ _evts[index .. $];
		}
	}
	/// このクラスを継承する場合、「到着時」は有効になる。
	bool canHasFireEnter() {return true;}
	abstract bool canHasFireLose();
	abstract bool canHasFireEscape();
	abstract bool canHasFireRound();
	abstract bool canHasFireKeyCode();

	void removeEvent(int index) {
		if (_uc !is null) {
			_evts[index].removeUseCounter;
		}
		_evts[index].changeHandler = null;
		_evts[index]._owner = null;
		_evts = _evts[0 .. index] ~ _evts[index + 1 .. $];
		changed;
	}
	void remove(EventTree et) {
		foreach (i, t; _evts) {
			if (t is et) {
				removeEvent(i);
				return;
			}
		}
		assert (0);
	}

	/// 使用回数カウンタを登録・除去する。
	void setUseCounter(UseCounter uc) {
		foreach (tree; _evts) {
			tree.setUseCounter(uc);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() {
		foreach (tree; _evts) {
			tree.removeUseCounter;
		}
		_uc = null;
	}

	/// XMLノードからイベントツリーを読み出して返す。
	static EventTree[] loadEventsFromNode(XNode node, string ver) {
		assert (node.name == "Events");
		EventTree[] r;
		node.onTag["Event"] = (ref XNode node) {
			auto tree = EventTree.createFromNode(node, ver);
			if (tree) r ~= tree;
		};
		node.parse;
		return r;
	}
	/// XMLノードにイベントツリー群のデータを追加する。
	void appendEventsToNode(ref XNode node) {
		auto ee = node.newElement("Events");
		foreach (evt; _evts) {
			evt.toNode(ee);
		}
	}
}

/// イベント関連の例外。
public class EventException : Exception {
public:
	this(string msg) {
		super(msg);
	}
}
