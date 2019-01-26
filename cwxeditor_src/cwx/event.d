
module cwx.event;

import cwx.types;
import cwx.utils;
import cwx.motion;
import cwx.background;
import cwx.usecounter;
import cwx.xml;
import cwx.path;
import cwx.props;
import cwx.msgutils;
import cwx.card;
import cwx.coupon;
import cwx.textholder;
import cwx.system;
import cwx.summary;
import cwx.flag;
import cwx.structs;

import std.algorithm;
import std.datetime;
import std.exception;
import std.string;
import std.traits;
import std.typecons;
import std.conv;
import std.range;

private bool static_this_completed = false;
private void static_this () { mixin(S_TRACE);
	if (static_this_completed) return;
	static_this_completed = true;

	_CTYPE_GROUP = [
		CTypeGroup.Terminal:[
			CType.START,
			CType.START_BATTLE,
			CType.END,
			CType.END_BAD_END,
			CType.CHANGE_AREA,
			CType.EFFECT_BREAK,
			CType.LINK_START,
			CType.LINK_PACKAGE,
		], CTypeGroup.Standard:[
			CType.TALK_MESSAGE,
			CType.TALK_DIALOG,
			CType.PLAY_BGM,
			CType.PLAY_SOUND,
			CType.WAIT,
			CType.ELAPSE_TIME,
			CType.EFFECT,
			CType.CALL_START,
			CType.CALL_PACKAGE,
		], CTypeGroup.Data:[
			CType.BRANCH_FLAG,
			CType.SET_FLAG,
			CType.REVERSE_FLAG,
			CType.BRANCH_MULTI_STEP,
			CType.BRANCH_STEP,
			CType.SET_STEP,
			CType.SET_STEP_UP,
			CType.SET_STEP_DOWN,
			CType.SUBSTITUTE_STEP,
			CType.SUBSTITUTE_FLAG,
			CType.BRANCH_STEP_CMP,
			CType.BRANCH_FLAG_CMP,
			CType.CHECK_FLAG,
			CType.CHECK_STEP,
		], CTypeGroup.Utility:[
			CType.BRANCH_SELECT,
			CType.BRANCH_ABILITY,
			CType.BRANCH_RANDOM,
			CType.BRANCH_MULTI_RANDOM, // Wsn.2
			CType.BRANCH_LEVEL,
			CType.BRANCH_STATUS,
			CType.BRANCH_PARTY_NUMBER,
			CType.BRANCH_AREA,
			CType.BRANCH_BATTLE,
			CType.BRANCH_IS_BATTLE,
			CType.BRANCH_RANDOM_SELECT,
			CType.BRANCH_ROUND,
		], CTypeGroup.Branch:[
			CType.BRANCH_CAST,
			CType.BRANCH_ITEM,
			CType.BRANCH_SKILL,
			CType.BRANCH_INFO,
			CType.BRANCH_BEAST,
			CType.BRANCH_MONEY,
			CType.BRANCH_COUPON,
			CType.BRANCH_MULTI_COUPON, // Wsn.2
			CType.BRANCH_COMPLETE_STAMP,
			CType.BRANCH_GOSSIP,
			CType.BRANCH_KEY_CODE,
		], CTypeGroup.Get:[
			CType.GET_CAST,
			CType.GET_ITEM,
			CType.GET_SKILL,
			CType.GET_INFO,
			CType.GET_BEAST,
			CType.GET_MONEY,
			CType.GET_COUPON,
			CType.GET_COMPLETE_STAMP,
			CType.GET_GOSSIP,
		], CTypeGroup.Lost:[
			CType.LOSE_CAST,
			CType.LOSE_ITEM,
			CType.LOSE_SKILL,
			CType.LOSE_INFO,
			CType.LOSE_BEAST,
			CType.LOSE_MONEY,
			CType.LOSE_COUPON,
			CType.LOSE_COMPLETE_STAMP,
			CType.LOSE_GOSSIP,
		], CTypeGroup.Visual:[
			CType.SHOW_PARTY,
			CType.HIDE_PARTY,
			CType.MOVE_CARD,
			CType.CHANGE_BG_IMAGE,
			CType.MOVE_BG_IMAGE,
			CType.REPLACE_BG_IMAGE,
			CType.LOSE_BG_IMAGE,
			CType.REDISPLAY,
		]
	];

	string _(string v) { return v; }
	_CONTENT_DETAILS = [
		CType.START:CDetail("Start", "", CNextType.NONE, true),
		CType.START_BATTLE:CDetail("Start", "Battle", CNextType.NONE, false, [CArg.BATTLE:"id"]),
		CType.END:CDetail("End", "", CNextType.NONE, false, [CArg.COMPLETE:"complete"]),
		CType.END_BAD_END:CDetail("End", "BadEnd", CNextType.NONE, false),
		CType.CHANGE_AREA:CDetail("Change", "Area", CNextType.NONE, false, [CArg.AREA:_("id"), CArg.TRANSITION:"transition", CArg.TRANSITION_SPEED:"transitionspeed"]),
		CType.CHANGE_BG_IMAGE:CDetail("Change", "BgImage", CNextType.NONE, true, [CArg.BG_IMAGES:_(null), CArg.TRANSITION:"transition", CArg.TRANSITION_SPEED:"transitionspeed"]),
		CType.EFFECT:CDetail("Effect", "", CNextType.NONE, true, [CArg.SIGNED_LEVEL:_("level"), CArg.RANGE:"targetm", CArg.EFFECT_TYPE:"effecttype", CArg.RESIST:"resisttype",
			CArg.SUCCESS_RATE:"successrate", CArg.SOUND_PATH:_("sound"), CArg.SOUND_VOLUME:"volume", CArg.SOUND_LOOP_COUNT:"loopcount", CArg.CARD_VISUAL:"visual",
			CArg.IGNITE:"ignite", CArg.HOLDING_COUPON:"holdingcoupon", CArg.REF_ABILITY:"refability", CArg.PHYSICAL:"physical", CArg.MENTAL:"mental", CArg.CARD_SPEED:"cardspeed", CArg.OVERRIDE_CARD_SPEED:"overridecardspeed",
			CArg.KEY_CODES:null, CArg.MOTIONS:null]),
		CType.EFFECT_BREAK:CDetail("Effect", "Break", CNextType.NONE, false, [CArg.CONSUME_CARD:"consumecard"]),
		CType.LINK_START:CDetail("Link", "Start", CNextType.NONE, false, [CArg.START:"link"]),
		CType.LINK_PACKAGE:CDetail("Link", "Package", CNextType.NONE, false, [CArg.PACKAGE:"link"]),
		CType.TALK_MESSAGE:CDetail("Talk", "Message", CNextType.TEXT, true, [CArg.TALKER_C:_("path"), CArg.TEXT:null, CArg.SELECTION_COLUMNS:"columns", CArg.BOUNDARY_CHECK:"boundarycheck", CArg.CENTERING_X:"centeringx", CArg.CENTERING_Y:"centeringy", CArg.SELECT_TALKER:"selecttalker"]),
		CType.TALK_DIALOG:CDetail("Talk", "Dialog", CNextType.TEXT, true, [CArg.TALKER_NC:_("targetm"), CArg.DIALOGS:null, CArg.COUPONS:null, CArg.INIT_VALUE:"initialValue", CArg.SELECTION_COLUMNS:"columns", CArg.BOUNDARY_CHECK:"boundarycheck", CArg.CENTERING_X:"centeringx", CArg.CENTERING_Y:"centeringy", CArg.SELECT_TALKER:"selecttalker"]),
		CType.PLAY_BGM:CDetail("Play", "Bgm", CNextType.NONE, true, [CArg.BGM_PATH:"path", CArg.BGM_CHANNEL:"channel", CArg.BGM_VOLUME:"volume", CArg.BGM_LOOP_COUNT:"loopcount", CArg.BGM_FADE_IN:"fadein"]),
		CType.PLAY_SOUND:CDetail("Play", "Sound", CNextType.NONE, true, [CArg.SOUND_PATH:"path", CArg.SOUND_CHANNEL:"channel", CArg.SOUND_VOLUME:"volume", CArg.SOUND_LOOP_COUNT:"loopcount", CArg.SOUND_FADE_IN:"fadein"]),
		CType.WAIT:CDetail("Wait", "", CNextType.NONE, true, [CArg.WAIT:"value"]),
		CType.ELAPSE_TIME:CDetail("Elapse", "Time", CNextType.NONE, true),
		CType.CALL_START:CDetail("Call", "Start", CNextType.NONE, true, [CArg.START:"call"]),
		CType.CALL_PACKAGE:CDetail("Call", "Package", CNextType.NONE, true, [CArg.PACKAGE:"call"]),
		CType.BRANCH_FLAG:CDetail("Branch", "Flag", CNextType.BOOL, true, [CArg.FLAG:"flag"]),
		CType.BRANCH_MULTI_STEP:CDetail("Branch", "MultiStep", CNextType.STEP, true, [CArg.STEP:"step"]),
		CType.BRANCH_STEP:CDetail("Branch", "Step", CNextType.BOOL, true, [CArg.STEP:_("step"), CArg.STEP_VALUE:"value"]),
		CType.BRANCH_SELECT:CDetail("Branch", "Select", CNextType.BOOL, true, [CArg.TARGET_ALL:_("targetall"), CArg.SELECTION_METHOD:null, CArg.COUPONS:null, CArg.INIT_VALUE:"initialValue"]),
		CType.BRANCH_ABILITY:CDetail("Branch", "Ability", CNextType.BOOL, true, [CArg.TARGET_S:_("targetm"), CArg.MENTAL:"mental", CArg.PHYSICAL:"physical", CArg.SIGNED_LEVEL:"value", CArg.INVERT_RESULT:"invert"]),
		CType.BRANCH_RANDOM:CDetail("Branch", "Random", CNextType.BOOL, true, [CArg.PERCENT:"value"]),
		CType.BRANCH_LEVEL:CDetail("Branch", "Level", CNextType.BOOL, true, [CArg.AVERAGE:_("average"), CArg.UNSIGNED_LEVEL:"value"]),
		CType.BRANCH_STATUS:CDetail("Branch", "Status", CNextType.BOOL, true, [CArg.RANGE:_("targetm"), CArg.STATUS:"status", CArg.INVERT_RESULT:"invert"]),
		CType.BRANCH_PARTY_NUMBER:CDetail("Branch", "PartyNumber", CNextType.BOOL, true, [CArg.PARTY_NUMBER:"value"]),
		CType.BRANCH_AREA:CDetail("Branch", "Area", CNextType.ID_AREA, true),
		CType.BRANCH_BATTLE:CDetail("Branch", "Battle", CNextType.ID_BATTLE, true),
		CType.BRANCH_IS_BATTLE:CDetail("Branch", "IsBattle", CNextType.BOOL, true),
		CType.BRANCH_CAST:CDetail("Branch", "Cast", CNextType.BOOL, true, [CArg.CAST:"id"]),
		CType.BRANCH_ITEM:CDetail("Branch", "Item", CNextType.BOOL, true, [CArg.ITEM:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number", CArg.SELECT_CARD:"selectcard", CArg.INVERT_RESULT:"invert"]),
		CType.BRANCH_SKILL:CDetail("Branch", "Skill", CNextType.BOOL, true, [CArg.SKILL:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number", CArg.SELECT_CARD:"selectcard", CArg.INVERT_RESULT:"invert"]),
		CType.BRANCH_INFO:CDetail("Branch", "Info", CNextType.BOOL, true, [CArg.INFO:"id"]),
		CType.BRANCH_BEAST:CDetail("Branch", "Beast", CNextType.BOOL, true, [CArg.BEAST:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number", CArg.SELECT_CARD:"selectcard", CArg.INVERT_RESULT:"invert"]),
		CType.BRANCH_MONEY:CDetail("Branch", "Money", CNextType.BOOL, true, [CArg.MONEY:"value"]),
		CType.BRANCH_COUPON:CDetail("Branch", "Coupon", CNextType.BOOL, true, [CArg.RANGE:"targets", CArg.COUPON_NAMES:null, CArg.MATCHING_TYPE:"matchingtype", CArg.INVERT_RESULT:"invert"]),
		CType.BRANCH_COMPLETE_STAMP:CDetail("Branch", "CompleteStamp", CNextType.BOOL, true, [CArg.COMPLETE_STAMP:"scenario"]),
		CType.BRANCH_GOSSIP:CDetail("Branch", "Gossip", CNextType.BOOL, true, [CArg.GOSSIP:"gossip"]),
		CType.SET_FLAG:CDetail("Set", "Flag", CNextType.NONE, true, [CArg.FLAG:_("flag"), CArg.FLAG_VALUE:"value", CArg.CARD_SPEED:"cardspeed", CArg.OVERRIDE_CARD_SPEED:"overridecardspeed"]),
		CType.SET_STEP:CDetail("Set", "Step", CNextType.NONE, true, [CArg.STEP:_("step"), CArg.STEP_VALUE:"value"]),
		CType.SET_STEP_UP:CDetail("Set", "StepUp", CNextType.NONE, true, [CArg.STEP:"step"]),
		CType.SET_STEP_DOWN:CDetail("Set", "StepDown", CNextType.NONE, true, [CArg.STEP:"step"]),
		CType.REVERSE_FLAG:CDetail("Reverse", "Flag", CNextType.NONE, true, [CArg.FLAG:"flag", CArg.CARD_SPEED:"cardspeed", CArg.OVERRIDE_CARD_SPEED:"overridecardspeed"]),
		CType.CHECK_FLAG:CDetail("Check", "Flag", CNextType.NONE, true, [CArg.FLAG:"flag"]),
		CType.GET_CAST:CDetail("Get", "Cast", CNextType.NONE, true, [CArg.CAST:"id", CArg.START_ACTION:"startaction"]),
		CType.GET_ITEM:CDetail("Get", "Item", CNextType.NONE, true, [CArg.ITEM:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.GET_SKILL:CDetail("Get", "Skill", CNextType.NONE, true, [CArg.SKILL:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.GET_INFO:CDetail("Get", "Info", CNextType.NONE, true, [CArg.INFO:"id"]),
		CType.GET_BEAST:CDetail("Get", "Beast", CNextType.NONE, true, [CArg.BEAST:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.GET_MONEY:CDetail("Get", "Money", CNextType.NONE, true, [CArg.MONEY:"value"]),
		CType.GET_COUPON:CDetail("Get", "Coupon", CNextType.NONE, true, [CArg.COUPON:_("coupon"), CArg.RANGE:"targets", CArg.COUPON_VALUE:"value", CArg.HOLDING_COUPON:"holdingcoupon"]),
		CType.GET_COMPLETE_STAMP:CDetail("Get", "CompleteStamp", CNextType.NONE, true, [CArg.COMPLETE_STAMP:"scenario"]),
		CType.GET_GOSSIP:CDetail("Get", "Gossip", CNextType.NONE, true, [CArg.GOSSIP:"gossip"]),
		CType.LOSE_CAST:CDetail("Lose", "Cast", CNextType.NONE, true, [CArg.CAST:"id"]),
		CType.LOSE_ITEM:CDetail("Lose", "Item", CNextType.NONE, true, [CArg.ITEM:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.LOSE_SKILL:CDetail("Lose", "Skill", CNextType.NONE, true, [CArg.SKILL:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.LOSE_INFO:CDetail("Lose", "Info", CNextType.NONE, true, [CArg.INFO:"id"]),
		CType.LOSE_BEAST:CDetail("Lose", "Beast", CNextType.NONE, true, [CArg.BEAST:_("id"), CArg.RANGE:"targets", CArg.CARD_NUMBER:"number"]),
		CType.LOSE_MONEY:CDetail("Lose", "Money", CNextType.NONE, true, [CArg.MONEY:"value"]),
		CType.LOSE_COUPON:CDetail("Lose", "Coupon", CNextType.NONE, true, [CArg.COUPON:_("coupon"), CArg.RANGE:"targets", CArg.HOLDING_COUPON:"holdingcoupon"]),
		CType.LOSE_COMPLETE_STAMP:CDetail("Lose", "CompleteStamp", CNextType.NONE, true, [CArg.COMPLETE_STAMP:"scenario"]),
		CType.LOSE_GOSSIP:CDetail("Lose", "Gossip", CNextType.NONE, true, [CArg.GOSSIP:"gossip"]),
		CType.SHOW_PARTY:CDetail("Show", "Party", CNextType.NONE, true, [CArg.CARD_SPEED:"cardspeed"]),
		CType.HIDE_PARTY:CDetail("Hide", "Party", CNextType.NONE, true, [CArg.CARD_SPEED:"cardspeed"]),
		CType.REDISPLAY:CDetail("Redisplay", "", CNextType.NONE, true, [CArg.TRANSITION:_("transition"), CArg.TRANSITION_SPEED:"transitionspeed"]),
		CType.SUBSTITUTE_STEP:CDetail(["Substitute", "Sbustitute"], "Step", CNextType.NONE, true, [CArg.STEP:"from", CArg.STEP_2:"to"]),
		CType.SUBSTITUTE_FLAG:CDetail(["Substitute", "Sbustitute"], "Flag", CNextType.NONE, true, [CArg.FLAG:"from", CArg.FLAG_2:"to", CArg.CARD_SPEED:"cardspeed", CArg.OVERRIDE_CARD_SPEED:"overridecardspeed"]),
		CType.BRANCH_STEP_CMP:CDetail("Branch", "StepValue", CNextType.TRIO, true, [CArg.STEP:"from", CArg.STEP_2:"to"]),
		CType.BRANCH_FLAG_CMP:CDetail("Branch", "FlagValue", CNextType.BOOL, true, [CArg.FLAG:"from", CArg.FLAG_2:"to"]),
		CType.BRANCH_RANDOM_SELECT:CDetail("Branch", "RandomSelect", CNextType.BOOL, true, [CArg.CAST_RANGE:null, CArg.LEVEL_MIN:"minLevel", CArg.LEVEL_MAX:"maxLevel", CArg.STATUS:"status", CArg.INVERT_RESULT:"invert"]),
		CType.BRANCH_KEY_CODE:CDetail("Branch", "KeyCode", CNextType.BOOL, true, [CArg.KEY_CODE_RANGE:"targetkc", CArg.TARGET_IS_SKILL:"skill", CArg.TARGET_IS_ITEM:"item", CArg.TARGET_IS_BEAST:"beast", CArg.TARGET_IS_HAND:"hand", CArg.KEY_CODE:"keyCode", CArg.SELECT_CARD:"selectcard", CArg.INVERT_RESULT:"invert"]),
		CType.CHECK_STEP:CDetail("Check", "Step", CNextType.NONE, true, [CArg.STEP:"step", CArg.STEP_VALUE:"value", CArg.COMPARISON_4:"comparison"]),
		CType.BRANCH_ROUND:CDetail("Branch", "Round", CNextType.BOOL, true, [CArg.ROUND:"round", CArg.COMPARISON_3:"comparison"]),
		CType.MOVE_BG_IMAGE:CDetail("Move", "BgImage", CNextType.NONE, true, [CArg.CELL_NAME:"cellname", CArg.POSITION_TYPE:"positiontype", CArg.X:"x", CArg.Y:"y", CArg.SIZE_TYPE:"sizetype", CArg.WIDTH:"width", CArg.HEIGHT:"height", CArg.TRANSITION:"transition", CArg.TRANSITION_SPEED:"transitionspeed", CArg.DO_ANIME:"doanime", CArg.IGNORE_EFFECT_BOOSTER:"ignoreeffectbooster"]),
		CType.REPLACE_BG_IMAGE:CDetail("Replace", "BgImage", CNextType.NONE, true, [CArg.CELL_NAME:"cellname", CArg.BG_IMAGES:_(null), CArg.TRANSITION:"transition", CArg.TRANSITION_SPEED:"transitionspeed", CArg.DO_ANIME:"doanime", CArg.IGNORE_EFFECT_BOOSTER:"ignoreeffectbooster"]),
		CType.LOSE_BG_IMAGE:CDetail("Lose", "BgImage", CNextType.NONE, true, [CArg.CELL_NAME:"cellname", CArg.TRANSITION:"transition", CArg.TRANSITION_SPEED:"transitionspeed", CArg.DO_ANIME:"doanime", CArg.IGNORE_EFFECT_BOOSTER:"ignoreeffectbooster"]),
		CType.BRANCH_MULTI_COUPON:CDetail("Branch", "MultiCoupon", CNextType.COUPON, true , [CArg.RANGE:"targets"]), // Wsn.2
		CType.BRANCH_MULTI_RANDOM:CDetail("Branch", "MultiRandom", CNextType.NONE, true), // Wsn.2
		CType.MOVE_CARD:CDetail("Move", "Card", CNextType.NONE, true, [CArg.CARD_GROUP:"cardgroup", CArg.POSITION_TYPE:"positiontype", CArg.X:"x", CArg.Y:"y", CArg.SCALE:"scale", CArg.LAYER:"layer", CArg.CARD_SPEED:"cardspeed", CArg.OVERRIDE_CARD_SPEED:"overridecardspeed"]), // Wsn.3
	];
	foreach (cType, detail; _CONTENT_DETAILS) { mixin(S_TRACE);
		foreach (name; detail.names) { mixin(S_TRACE);
			_CTYPE_MAP[name][detail.type] = cType; mixin(S_TRACE);
		}
	}
}

private CType[][CTypeGroup] _CTYPE_GROUP;
/// コンテントタイプの分類毎の配列。
@property
CType[][CTypeGroup] CTYPE_GROUP() { mixin(S_TRACE);
	static_this();
	return _CTYPE_GROUP;
}

private CDetail[CType] _CONTENT_DETAILS;
/// コンテントタイプ毎の情報。
@property
private CDetail[CType] CONTENT_DETAILS() { mixin(S_TRACE);
	static_this();
	return _CONTENT_DETAILS;
}
private CType[string][string] _CTYPE_MAP;
/// コンテントタイプと要素名・属性名の対応表。
@property
private CType[string][string] CTYPE_MAP() { mixin(S_TRACE);
	static_this();
	return _CTYPE_MAP;
}

struct CDetail {
	/// 要素名。要素名が後から変更された時のために複数持つ。
	/// 保存時は先頭の名前を使う。
	string[] names;
	string type; /// 属性名。
	CNextType nextType; /// 後続パラメータのタイプ。
	bool owner; /// 後続コンテントを持てるか。

	string[CArg] args;
	/// argを使用するコンテントであればtrueを返す。
	const
	bool use(CArg arg) {return (arg in args) != null;}
	/// argを使用する際の属性名を返す。
	/// 子要素を使用する等の理由で属性名が存在しない場合はnullを返す。
	const
	string attr(CArg arg) {return args[arg];}

	static CDetail opCall(string name, string type, CNextType nextType, bool owner) {
		string[CArg] args;
		return CDetail([name], type, nextType, owner, args);
	}
	static CDetail opCall(string name, string type, CNextType nextType, bool owner, string[CArg] args) {
		return CDetail([name], type, nextType, owner, args);
	}
	static CDetail opCall(string[] names, string type, CNextType nextType, bool owner, string[CArg] args) {
		CDetail r;
		r.names = names;
		r.type = type;
		r.nextType = nextType;
		r.owner = owner;
		r.args = args;
		return r;
	}
	static CDetail fromType(CType type) { mixin(S_TRACE);
		return CONTENT_DETAILS[type];
	}
}

/// 分岐主体のイベントコンテントか。
@property
bool isBranchContent(CType cType) { mixin(S_TRACE);
	if (cType is CType.BRANCH_MULTI_RANDOM) return true;
	auto d = CDetail.fromType(cType);
	return !(d.nextType == CNextType.NONE || d.nextType == CNextType.TEXT);
}

/// スタートのID。
alias string StartId;
/// 文字列をスタートIDに変換。
StartId toStartId(string start) {return start;}
/// スタートコンテントの使用者。
alias User!(StartId) IStartUser;
/// スタートコンテントの使用回数カウンタ。
alias UCCont!(StartId, IStartUser) SUseCounter;

/// 口調分け条件とメッセージ内容を持つクラス。
static class SDialog : CWXPath, IPathUser, IFlagUser, IStepUser, ICouponUser, ITextHolder {
private:
	CouponUser[] _rCoupons = [];
	TextHolder _text;
	Content _parent;
public:
	/// XML名。
	static const XML_NAME = "Dialog";

	/// コンストラクタ。
	this (string text = "", string[] rCoupons = []) { mixin(S_TRACE);
		_text = new TextHolder;
		_text.changeHandler = { mixin(S_TRACE);
			if (_parent) _parent.changed();
		};
		_text.text = text;
		_text.owner = this;
		this.rCoupons = rCoupons;
	}
	/// コピーコンストラクタ。
	this (in SDialog base) { mixin(S_TRACE);
		this (base.text, base.rCoupons);
	}

	/// コピーを生成する。
	@property
	const
	SDialog dup() { return new SDialog(this); }

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto d = cast(const(SDialog)) o;
		return d && d.rCoupons == rCoupons && d.text == text;
	}
	/// メッセージ。
	@property
	const
	string text() { mixin(S_TRACE);
		return _text.text;
	}
	/// ditto
	@property
	void text(string text) { mixin(S_TRACE);
		if (_parent && _text.text != text) _parent.changed();
		_text.text = text;
	}
	/// 口調分け条件クーポン群。
	@property
	const
	string[] rCoupons() { mixin(S_TRACE);
		auto r = new string[_rCoupons.length];
		foreach (i, ref c; r) { mixin(S_TRACE);
			c = _rCoupons[i].coupon;
		}
		return r;
	}
	/// ditto
	@property
	void rCoupons(string[] rCoupons) { mixin(S_TRACE);
		if (this.rCoupons != rCoupons) { mixin(S_TRACE);
			if (_parent) _parent.changed();
			foreach (c; _rCoupons) { mixin(S_TRACE);
				c.removeUseCounter();
			}
			_rCoupons.length = rCoupons.length;
			foreach (i, ref c; _rCoupons) { mixin(S_TRACE);
				c = new CouponUser(this);
				c.coupon = rCoupons[i];
				if (useCounter) { mixin(S_TRACE);
					c.setUseCounter = useCounter;
				}
			}
		}
	}
	/// このSDialogを所持するSpeak。
	@property
	Content parent() { mixin(S_TRACE);
		return _parent;
	}
	/// ditto
	@property
	void parent(Content s) { mixin(S_TRACE);
		_parent = s;
	}
	/// 使用回数カウンタ。
	@property
	UseCounter useCounter() {return _text.useCounter;}
	/// 使用回数カウンタを設定・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		_text.setUseCounter(uc);
		foreach (ref c; _rCoupons) { mixin(S_TRACE);
			c.setUseCounter = useCounter;
		}
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		_text.removeUseCounter();
		foreach (ref c; _rCoupons) { mixin(S_TRACE);
			c.removeUseCounter();
		}
	}
	override bool change(PathId id) { mixin(S_TRACE);
		return _text.change(id);
	}
	override bool change(FlagId id) { mixin(S_TRACE);
		return _text.change(id);
	}
	override bool change(StepId id) { mixin(S_TRACE);
		return _text.change(id);
	}
	override bool change(CouponId id) { return true; }

	protected override void changed() { }

	/// テキスト内で使用されているfont_X.png等のパス。
	@property
	const
	override string[] fontsInText() { return _text.fontsInText; }
	/// テキスト内で使用されているフラグのパス。
	@property
	const
	override string[] flagsInText() { return _text.flagsInText; }
	/// テキスト内で使用されているステップのパス。
	@property
	const
	override string[] stepsInText() { return _text.stepsInText; }
	/// テキスト内で使用されている色。
	@property
	const
	const(char)[] colorsInText() { return _text.colorsInText; }
	/// テキスト内のfont_X.bmp・フラグ・ステップを置換する。
	override void changeInText(size_t index, PathId id) { mixin(S_TRACE);
		_text.changeInText(index, id);
	}
	/// ditto
	override void changeInText(size_t index, FlagId id) { mixin(S_TRACE);
		_text.changeInText(index, id);
	}
	/// ditto
	override void changeInText(size_t index, StepId id) { mixin(S_TRACE);
		_text.changeInText(index, id);
	}
	const
	XNode toNode() { mixin(S_TRACE);
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	const
	void toNode(ref XNode node) { mixin(S_TRACE);
		assert (node.name == "Dialogs", node.name ~ " != Dialogs");
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	const
	private void toNodeImpl(ref XNode e) { mixin(S_TRACE);
		assert (e.name == XML_NAME, e.name ~ " != " ~ XML_NAME);
		e.newElement("RequiredCoupons", encodeLf(rCoupons, true));
		e.newElement("Text", encodeLf(text));
	}
	static SDialog createFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		assert (node.name == XML_NAME, node.name ~ " != " ~ XML_NAME);
		string[] rCoupons;
		string text;
		node.onTag["RequiredCoupons"] = (ref XNode n) { mixin(S_TRACE);
			rCoupons = decodeLf(n.value);
		};
		node.onTag["Text"] = (ref XNode n) { mixin(S_TRACE);
			text = decodeLf2(n.value);
		};
		node.parse();
		return new SDialog(text, rCoupons);
	}
	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		return _parent ? cpjoin(_parent, "dialog", .cCountUntil!("a is b")(_parent.dialogs, this), id) : "";
	}
	override CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		if (cate == "text") { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index > 0) return null;
			return _text.findCWXPath(cpbottom(path));
		}
		return null;
	}
	@property
	inout
	inout(CWXPath)[] cwxChilds() { return _text.cwxChilds; }
	@property
	CWXPath cwxParent() { return _parent; }
}

class Content : CWXPath, IPathUser, IAreaUser, IBattleUser, IPackageUser,
		IFlagUser, IStepUser,
		ICastUser, IItemUser, ISkillUser, IBeastUser, IInfoUser,
		ICouponUser, IGossipUser, ICompleteStampUser, IKeyCodeUser,
		ICellNameUser, ICardGroupUser, IStartUser,
		MotionOwner, BgImageOwner, ITextHolder, ISimpleTextHolder,
		CouponsOwner, ChgAreaCallback, ChgBattleCallback, ChgCouponCallback {
	private EventTree _tree = null;

	/// 型と後続テキストnameを指定してインスタンスを生成。
	this (CType type, string name) { mixin(S_TRACE);
		static ulong idCount = 0;
		_id = .objectIDValue(this) ~ "-" ~ .to!string(idCount);
		idCount++;
		_type = type;
		_name = new SimpleTextHolder("name");
		_name.changeHandler = &changed;
		_name.text = name;
		_name.owner = this;

		// イベントタイプによって初期値が異なる
		switch (type) {
		case CType.TALK_DIALOG:
			initValue = 1;
			break;
		default:
			if (detail.use(CArg.COUPON) || detail.use(CArg.COUPON_NAMES) || type is CType.BRANCH_MULTI_COUPON) { mixin(S_TRACE);
				range = Range.SELECTED;
			}
			break;
		}

		validate();
	}
	/// cからパラメータをコピーする。
	void shallowCopy(in Content c) { mixin(S_TRACE);
		this.comment = c.comment;

		this.area = c.area;
		this.battle = c.battle;
		this.packages = c.packages;
		this.flag = c.flag;
		this.step = c.step;
		this.cardPaths = c.cardPaths;
		this.bgmPath = c.bgmPath;
		this.bgmChannel = c.bgmChannel;
		this.bgmVolume = c.bgmVolume;
		this.bgmLoopCount = c.bgmLoopCount;
		this.bgmFadeIn = c.bgmFadeIn;
		this.soundPath = c.soundPath;
		this.soundChannel = c.soundChannel;
		this.soundVolume = c.soundVolume;
		this.soundLoopCount = c.soundLoopCount;
		this.soundFadeIn = c.soundFadeIn;
		this.casts = c.casts;
		this.item = c.item;
		this.skill = c.skill;
		this.beast = c.beast;
		this.info = c.info;

		this.start = c.start;
		this.coupon = c.coupon;
		this.gossip = c.gossip;
		this.completeStamp = c.completeStamp;

		this.mental = c.mental;
		this.physical = c.physical;
		this.status = c.status;
		this.range = c.range;
		this.cardVisual = c.cardVisual;
		this.effectType = c.effectType;
		this.resist = c.resist;
		this.transition = c.transition;

		this.targetAll = c.targetAll;
		this.selectionMethod = c.selectionMethod;
		this.average = c.average;
		this.complete = c.complete;

		this.unsignedLevel = c.unsignedLevel;
		this.signedLevel = c.signedLevel;
		this.successRate = c.successRate;
		this.transitionSpeed = c.transitionSpeed;
		this.cardSpeed = c.cardSpeed;
		this.overrideCardSpeed = c.overrideCardSpeed;
		this.percent = c.percent;
		this.flagValue = c.flagValue;
		this.stepValue = c.stepValue;
		this.couponValue = c.couponValue;
		this.partyNumber = c.partyNumber;
		this.cardNumber = c.cardNumber;
		this.money = c.money;
		this.wait = c.wait;

		this.flag2 = c.flag2;
		this.step2 = c.step2;
		this.castRange = c.castRange.dup;
		this.levelMin = c.levelMin;
		this.levelMax = c.levelMax;

		this.keyCodeRange = c.keyCodeRange;
		this.targetIsSkill = c.targetIsSkill;
		this.targetIsItem = c.targetIsItem;
		this.targetIsBeast = c.targetIsBeast;
		this.targetIsHand = c.targetIsHand;
		this.keyCode = c.keyCode;

		this.initValue = c.initValue;

		this.comparison4 = c.comparison4;
		this.comparison3 = c.comparison3;

		this.round = c.round;

		this.cellName = c.cellName;
		this.cardGroup = c.cardGroup;
		this.positionType = c.positionType;
		this.x = c.x;
		this.y = c.y;
		this.sizeType = c.sizeType;
		this.width = c.width;
		this.height = c.height;
		this.scale = c.scale;
		this.layer = c.layer;

		this.doAnime = c.doAnime;
		this.ignoreEffectBooster = c.ignoreEffectBooster;

		this.selectionColumns = c.selectionColumns;
		this.centeringX = c.centeringX;
		this.centeringY = c.centeringY;
		this.boundaryCheck = c.boundaryCheck;
		this.startAction = c.startAction;
		this.ignite = c.ignite;
		this.keyCodes = c.keyCodes.dup;

		this.couponNames = c.couponNames.dup;
		this.matchingType = c.matchingType;

		this.holdingCoupon = c.holdingCoupon;
		this.refAbility = c.refAbility;

		this.selectCard = c.selectCard;
		this.selectTalker = c.selectTalker;
		this.invertResult = c.invertResult;

		this.consumeCard = c.consumeCard;

		Motion[] motions;
		foreach (m; c.motions) { mixin(S_TRACE);
			motions ~= m.dup;
		}
		this.motions = motions;

		this.text = c.text;
		SDialog[] dialogs;
		foreach (d; c.dialogs) { mixin(S_TRACE);
			dialogs ~= new SDialog(d);
		}
		this.dialogs = dialogs;

		this.targetS = c.targetS;
		this.talkerNC = c.talkerNC;

		BgImage[] backs;
		foreach (b; c.backs) { mixin(S_TRACE);
			backs ~= b.dup;
		}
		this.backs = backs;

		Coupon[] coupons;
		foreach (coupon; c.coupons) { mixin(S_TRACE);
			coupons ~= new Coupon(coupon);
		}
		this.coupons = coupons;
	}
	/// ディープコピーを生成する。
	@property
	const
	Content dup() { mixin(S_TRACE);
		auto copy = new Content(type, name);
		copy.shallowCopy(this);

		foreach (c; next) { mixin(S_TRACE);
			copy.add(null, c.dup);
		}

		return copy;
	}

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto c = cast(const(Content))o;
		if (!c) return false;
		auto d = detail;
		return type == c.type
			&& name == c.name
			&& comment == c.comment

			&& (!d.use(CArg.AREA) || area == c.area)
			&& (!d.use(CArg.BATTLE) || battle == c.battle)
			&& (!d.use(CArg.PACKAGE) || packages == c.packages)
			&& (!d.use(CArg.FLAG) || flag == c.flag)
			&& (!d.use(CArg.STEP) || step == c.step)
			&& (!d.use(CArg.TALKER_C) || cardPaths == c.cardPaths)
			&& (!d.use(CArg.BGM_PATH) || bgmPath == c.bgmPath)
			&& (!d.use(CArg.BGM_CHANNEL) || bgmChannel == c.bgmChannel)
			&& (!d.use(CArg.BGM_VOLUME) || bgmVolume == c.bgmVolume)
			&& (!d.use(CArg.BGM_LOOP_COUNT) || bgmLoopCount == c.bgmLoopCount)
			&& (!d.use(CArg.BGM_FADE_IN) || bgmFadeIn == c.bgmFadeIn)
			&& (!d.use(CArg.SOUND_PATH) || soundPath == c.soundPath)
			&& (!d.use(CArg.SOUND_CHANNEL) || soundChannel == c.soundChannel)
			&& (!d.use(CArg.SOUND_VOLUME) || soundVolume == c.soundVolume)
			&& (!d.use(CArg.SOUND_LOOP_COUNT) || soundLoopCount == c.soundLoopCount)
			&& (!d.use(CArg.SOUND_FADE_IN) || soundFadeIn == c.soundFadeIn)
			&& (!d.use(CArg.CAST) || casts == c.casts)
			&& (!d.use(CArg.ITEM) || item == c.item)
			&& (!d.use(CArg.SKILL) || skill == c.skill)
			&& (!d.use(CArg.BEAST) || beast == c.beast)
			&& (!d.use(CArg.INFO) || info == c.info)

			&& (!d.use(CArg.START) || start == c.start)
			&& (!d.use(CArg.COUPON) || coupon == c.coupon)
			&& (!d.use(CArg.GOSSIP) || gossip == c.gossip)
			&& (!d.use(CArg.COMPLETE_STAMP) || completeStamp == c.completeStamp)

			&& (!d.use(CArg.MENTAL) || mental == c.mental)
			&& (!d.use(CArg.PHYSICAL) || physical == c.physical)
			&& (!d.use(CArg.STATUS) || status == c.status)
			&& (!d.use(CArg.RANGE) || range == c.range)
			&& (!d.use(CArg.CARD_VISUAL) || cardVisual == c.cardVisual)
			&& (!d.use(CArg.EFFECT_TYPE) || effectType == c.effectType)
			&& (!d.use(CArg.RESIST) || resist == c.resist)
			&& (!d.use(CArg.TRANSITION) || transition == c.transition)

			&& (!d.use(CArg.TARGET_ALL) || targetAll == c.targetAll)
			&& (!d.use(CArg.SELECTION_METHOD) || selectionMethod == c.selectionMethod)
			&& (!d.use(CArg.AVERAGE) || average == c.average)
			&& (!d.use(CArg.COMPLETE) || complete == c.complete)

			&& (!d.use(CArg.UNSIGNED_LEVEL) || unsignedLevel == c.unsignedLevel)
			&& (!d.use(CArg.SIGNED_LEVEL) || signedLevel == c.signedLevel)
			&& (!d.use(CArg.SUCCESS_RATE) || successRate == c.successRate)
			&& (!d.use(CArg.TRANSITION_SPEED) || transitionSpeed == c.transitionSpeed)
			&& (!d.use(CArg.CARD_SPEED) || cardSpeed == c.cardSpeed)
			&& (!d.use(CArg.OVERRIDE_CARD_SPEED) || overrideCardSpeed == c.overrideCardSpeed)
			&& (!d.use(CArg.PERCENT) || percent == c.percent)
			&& (!d.use(CArg.FLAG_VALUE) || flagValue == c.flagValue)
			&& (!d.use(CArg.STEP_VALUE) || stepValue == c.stepValue)
			&& (!d.use(CArg.COUPON_VALUE) || couponValue == c.couponValue)
			&& (!d.use(CArg.PARTY_NUMBER) || partyNumber == c.partyNumber)
			&& (!d.use(CArg.CARD_NUMBER) || cardNumber == c.cardNumber)
			&& (!d.use(CArg.MONEY) || money == c.money)
			&& (!d.use(CArg.WAIT) || wait == c.wait)

			&& (!d.use(CArg.FLAG_2) || flag2 == c.flag2)
			&& (!d.use(CArg.STEP_2) || step2 == c.step2)
			&& (!d.use(CArg.CAST_RANGE) || castRange == c.castRange)
			&& (!d.use(CArg.LEVEL_MIN) || levelMin == c.levelMin)
			&& (!d.use(CArg.LEVEL_MAX) || levelMax == c.levelMax)

			&& (!d.use(CArg.KEY_CODE_RANGE) || keyCodeRange == c.keyCodeRange)
			&& (!d.use(CArg.TARGET_IS_SKILL) || targetIsSkill == c.targetIsSkill)
			&& (!d.use(CArg.TARGET_IS_ITEM) || targetIsItem == c.targetIsItem)
			&& (!d.use(CArg.TARGET_IS_BEAST) || targetIsBeast == c.targetIsBeast)
			&& (!d.use(CArg.TARGET_IS_HAND) || targetIsHand == c.targetIsHand)
			&& (!d.use(CArg.KEY_CODE) || keyCode == c.keyCode)

			&& (!d.use(CArg.INIT_VALUE) || initValue == c.initValue)

			&& (!d.use(CArg.COMPARISON_4) || comparison4 == c.comparison4)
			&& (!d.use(CArg.COMPARISON_3) || comparison3 == c.comparison3)

			&& (!d.use(CArg.ROUND) || round == c.round)

			&& (!d.use(CArg.CELL_NAME) || cellName == c.cellName)
			&& (!d.use(CArg.CARD_GROUP) || cardGroup == c.cardGroup)
			&& (!d.use(CArg.POSITION_TYPE) || positionType == c.positionType)
			&& (!d.use(CArg.X) || x == c.x)
			&& (!d.use(CArg.Y) || y == c.y)
			&& (!d.use(CArg.SIZE_TYPE) || sizeType == c.sizeType)
			&& (!d.use(CArg.WIDTH) || width == c.width)
			&& (!d.use(CArg.HEIGHT) || height == c.height)
			&& (!d.use(CArg.SCALE) || scale == c.scale)
			&& (!d.use(CArg.LAYER) || layer == c.layer)

			&& (!d.use(CArg.DO_ANIME) || doAnime == c.doAnime)
			&& (!d.use(CArg.IGNORE_EFFECT_BOOSTER) || ignoreEffectBooster == c.ignoreEffectBooster)

			&& (!d.use(CArg.SELECTION_COLUMNS) || selectionColumns == c.selectionColumns)
			&& (!d.use(CArg.CENTERING_X) || centeringX == c.centeringX)
			&& (!d.use(CArg.CENTERING_Y) || centeringY == c.centeringY)
			&& (!d.use(CArg.BOUNDARY_CHECK) || boundaryCheck == c.boundaryCheck)
			&& (!d.use(CArg.START_ACTION) || startAction == c.startAction)
			&& (!d.use(CArg.IGNITE) || ignite == c.ignite)
			&& (!d.use(CArg.KEY_CODES) || keyCodes == c.keyCodes)

			&& (!d.use(CArg.COUPON_NAMES) || couponNames == c.couponNames)
			&& (!d.use(CArg.MATCHING_TYPE) || matchingType == c.matchingType)

			&& (!d.use(CArg.HOLDING_COUPON) || holdingCoupon == c.holdingCoupon)
			&& (!d.use(CArg.REF_ABILITY) || refAbility == c.refAbility)

			&& (!d.use(CArg.SELECT_CARD) || selectCard == c.selectCard)
			&& (!d.use(CArg.SELECT_TALKER) || selectTalker == c.selectTalker)
			&& (!d.use(CArg.INVERT_RESULT) || invertResult == c.invertResult)

			&& (!d.use(CArg.CONSUME_CARD) || consumeCard == c.consumeCard)

			&& (!d.use(CArg.MOTIONS) || motions == c.motions)

			&& (!d.use(CArg.TEXT) || text == c.text)

			&& (!d.use(CArg.DIALOGS) || dialogs == c.dialogs)

			&& (!d.use(CArg.TARGET_S) || targetS == c.targetS)
			&& (!d.use(CArg.TALKER_NC) || talkerNC == c.talkerNC)

			&& (!d.use(CArg.BG_IMAGES) || backs == c.backs)

			&& (!d.use(CArg.COUPONS) || coupons == c.coupons)

			&& next == c.next;
	}

	private string _id;
	/// イベントID。ドラッグ&ドロップ等でイベントを移動するとき、
	/// 自分自身を識別するために使用する。
	@property
	const
	string eventId() { return _id; }

	private CType _type;
	/// コンテントの型。
	@property
	const
	CType type() { return _type; }
	/// コンテントの概要。
	@property
	const
	CDetail detail() { return CONTENT_DETAILS[type]; }

	/// スタートコンテントの場合、ツリーが変更された回数をカウントする。
	private ulong _updateCounter = 0;
	@property
	const
	ulong updateCounter() { return _updateCounter; }

	/// プロパティを正規化する。
	private void validate() { mixin(S_TRACE);
		if (CType.BRANCH_STATUS is type) { mixin(S_TRACE);
			if (Status.NONE is _status) _status = Status.ACTIVE;
		}
		if (CType.EFFECT is type) { mixin(S_TRACE);
			switch (range) {
			case Range.SELECTED:
			case Range.RANDOM:
			case Range.PARTY:
			case Range.COUPON_HOLDER:
			case Range.CARD_TARGET:
				break;
			default:
				_range = Range.SELECTED;
				break;
			}
		}
		switch (type) {
		case CType.BRANCH_STATUS:
			switch (range) {
			case Range.SELECTED:
			case Range.RANDOM:
			case Range.PARTY:
				break;
			default:
				_range = Range.SELECTED;
				break;
			}
			break;
		case CType.GET_COUPON:
		case CType.LOSE_COUPON:
			switch (range) {
			case Range.SELECTED:
			case Range.RANDOM:
			case Range.PARTY:
			case Range.COUPON_HOLDER:
				break;
			default:
				_range = Range.SELECTED;
				break;
			}
			break;
		case CType.BRANCH_COUPON:
		case CType.BRANCH_MULTI_COUPON:
			switch (range) {
			case Range.SELECTED:
			case Range.RANDOM:
			case Range.PARTY:
			case Range.FIELD:
				break;
			default:
				_range = Range.SELECTED;
				break;
			}
			break;
		case CType.BRANCH_SKILL:
		case CType.BRANCH_ITEM:
		case CType.BRANCH_BEAST:
		case CType.GET_SKILL:
		case CType.GET_ITEM:
		case CType.GET_BEAST:
		case CType.LOSE_SKILL:
		case CType.LOSE_ITEM:
		case CType.LOSE_BEAST:
			switch (range) {
			case Range.SELECTED:
			case Range.RANDOM:
			case Range.PARTY:
			case Range.BACKPACK:
			case Range.PARTY_AND_BACKPACK:
			case Range.FIELD:
			case Range.SELECTED_CARD: // Wsn.3
				break;
			default:
				_range = Range.SELECTED;
				break;
			}
			break;
		default:
			break;
		}
		if (CType.BRANCH_KEY_CODE is type) { mixin(S_TRACE);
			switch (keyCodeRange) {
			case Range.SELECTED:
			case Range.RANDOM:
			case Range.BACKPACK:
			case Range.PARTY_AND_BACKPACK:
			case Range.SELECTED_CARD: // Wsn.3
				break;
			default:
				_keyCodeRange = Range.PARTY_AND_BACKPACK;
				break;
			}
		}
	}

	/// 型変換が可能であればtrue。
	const
	bool canConvert(CType type) { mixin(S_TRACE);
		if (type == this.type) return false;
		if (type == CType.START || this.type == CType.START) return false;
		return _next.length ? CONTENT_DETAILS[type].owner : true;
	}

	private static void resetValue(CArg Arg, T, T Init)(in CDetail d, in CDetail oldd, void delegate(T) set, in Content base, lazy const T baseValue) { mixin(S_TRACE);
		if (!d.use(Arg)) { mixin(S_TRACE);
			set(Init);
		} else if (base && d.use(Arg) && !oldd.use(Arg)) { mixin(S_TRACE);
			static if (is(typeof(set(baseValue)))) {
				set(baseValue);
			} else static if (isVArray!T && is(typeof(set(baseValue.dup)))) {
				set(baseValue.dup);
			} else static if (isVArray!T || is(ElementType!baseValue:Object)) {
				T vals;
				foreach (v; baseValue) vals ~= v.dup;
				set(vals);
			} else static assert(0, T.stringof);
		}
	}
	/// コンテントの型を変換。
	void convertType(CType type, in Content base, in CProps prop, DialogStatus dialogStatus) { mixin(S_TRACE);
		if (!canConvert(type)) throw new Exception("can not convert: " ~ prop.msgs.contentName(type));
		if (_type == type) return;
		changed();
		auto od = detail;
		_type = type;
		foreach (n; next) { mixin(S_TRACE);
			validText(prop, n);
		}

		if (_suc) { mixin(S_TRACE);
			if (od.use(CArg.START) && !detail.use(CArg.START)) { mixin(S_TRACE);
				_suc.remove(toStartId(_start), this);
			} else if (!od.use(CArg.START) && detail.use(CArg.START)) { mixin(S_TRACE);
				_suc.add(toStartId(_start), this);
			}
		}

		auto d = detail;
		resetValue!(CArg.AREA, ulong, 0)(d, od, &area, base, base.area);
		resetValue!(CArg.BATTLE, ulong, 0)(d, od, &battle, base, base.battle);
		resetValue!(CArg.PACKAGE, ulong, 0)(d, od, &packages, base, base.packages);
		resetValue!(CArg.FLAG, string, "")(d, od, &flag, base, base.flag);
		resetValue!(CArg.STEP, string, "")(d, od, &step, base, base.step);
		resetValue!(CArg.TALKER_C, const(CardImage)[], [])(d, od, &cardPaths, base, base.cardPaths);
		resetValue!(CArg.BGM_PATH, string, "")(d, od, &bgmPath, base, base.bgmPath);
		resetValue!(CArg.BGM_CHANNEL, uint, 0)(d, od, &bgmChannel, base, base.bgmChannel);
		resetValue!(CArg.BGM_VOLUME, uint, 100)(d, od, &bgmVolume, base, base.bgmVolume);
		resetValue!(CArg.BGM_LOOP_COUNT, uint, 0)(d, od, &bgmLoopCount, base, base.bgmLoopCount);
		resetValue!(CArg.BGM_FADE_IN, uint, 0)(d, od, &bgmFadeIn, base, base.bgmFadeIn);
		resetValue!(CArg.SOUND_PATH, string, "")(d, od, &soundPath, base, base.soundPath);
		resetValue!(CArg.SOUND_CHANNEL, uint, 0)(d, od, &soundChannel, base, base.soundChannel);
		resetValue!(CArg.SOUND_VOLUME, uint, 100)(d, od, &soundVolume, base, base.soundVolume);
		resetValue!(CArg.SOUND_LOOP_COUNT, uint, 1)(d, od, &soundLoopCount, base, base.soundLoopCount);
		resetValue!(CArg.SOUND_FADE_IN, uint, 0)(d, od, &soundFadeIn, base, base.soundFadeIn);
		resetValue!(CArg.CAST, ulong, 0)(d, od, &casts, base, base.casts);
		resetValue!(CArg.ITEM, ulong, 0)(d, od, &item, base, base.item);
		resetValue!(CArg.SKILL, ulong, 0)(d, od, &skill, base, base.skill);
		resetValue!(CArg.BEAST, ulong, 0)(d, od, &beast, base, base.beast);
		resetValue!(CArg.INFO, ulong, 0)(d, od, &info, base, base.info);

		resetValue!(CArg.START, string, "")(d, od, &start, base, base.start);
		resetValue!(CArg.GOSSIP, string, "")(d, od, &gossip, base, base.gossip);
		resetValue!(CArg.COMPLETE_STAMP, string, "")(d, od, &completeStamp, base, base.completeStamp);

		resetValue!(CArg.MENTAL, Mental, Mental.init)(d, od, &mental, base, base.mental);
		resetValue!(CArg.PHYSICAL, Physical, Physical.init)(d, od, &physical, base, base.physical);
		resetValue!(CArg.STATUS, Status, Status.ACTIVE)(d, od, &status, base, base.status);
		if (d.use(CArg.COUPON) || type is CType.BRANCH_MULTI_COUPON) { mixin(S_TRACE);
			resetValue!(CArg.RANGE, Range, Range.SELECTED)(d, od, &range, base, base.range);
		} else { mixin(S_TRACE);
			resetValue!(CArg.RANGE, Range, Range.FIELD)(d, od, &range, base, base.range);
		}
		resetValue!(CArg.CARD_VISUAL, CardVisual, CardVisual.NONE)(d, od, &cardVisual, base, base.cardVisual);
		resetValue!(CArg.EFFECT_TYPE, EffectType, EffectType.NONE)(d, od, &effectType, base, base.effectType);
		resetValue!(CArg.RESIST, Resist, Resist.UNFAIL)(d, od, &resist, base, base.resist);
		resetValue!(CArg.TRANSITION, Transition, Transition.DEFAULT)(d, od, &transition, base, base.transition);

		resetValue!(CArg.TARGET_ALL, bool, false)(d, od, &targetAll, base, base.targetAll);
		resetValue!(CArg.SELECTION_METHOD, SelectionMethod, SelectionMethod.Manual)(d, od, &selectionMethod, base, base.selectionMethod);
		resetValue!(CArg.AVERAGE, bool, false)(d, od, &average, base, base.average);
		resetValue!(CArg.COMPLETE, bool, false)(d, od, &complete, base, base.complete);

		resetValue!(CArg.UNSIGNED_LEVEL, int, 1)(d, od, &unsignedLevel, base, base.unsignedLevel);
		resetValue!(CArg.SIGNED_LEVEL, int, 0)(d, od, &signedLevel, base, base.signedLevel);
		resetValue!(CArg.SUCCESS_RATE, int, 5)(d, od, &successRate, base, base.successRate);
		resetValue!(CArg.TRANSITION_SPEED, int, 5u)(d, od, &transitionSpeed, base, base.transitionSpeed);
		resetValue!(CArg.CARD_SPEED, int, -1)(d, od, &cardSpeed, base, base.cardSpeed);
		resetValue!(CArg.OVERRIDE_CARD_SPEED, bool, false)(d, od, &overrideCardSpeed, base, base.overrideCardSpeed);
		resetValue!(CArg.PERCENT, int, 50u)(d, od, &percent, base, base.percent);
		resetValue!(CArg.FLAG_VALUE, bool, true)(d, od, &flagValue, base, base.flagValue);
		resetValue!(CArg.STEP_VALUE, int, 0)(d, od, &stepValue, base, base.stepValue);
		resetValue!(CArg.COUPON_VALUE, int, 0)(d, od, &couponValue, base, base.couponValue);
		resetValue!(CArg.PARTY_NUMBER, int, 2)(d, od, &partyNumber, base, base.partyNumber);
		resetValue!(CArg.CARD_NUMBER, int, 1)(d, od, &cardNumber, base, base.cardNumber);
		resetValue!(CArg.MONEY, int, 0)(d, od, &money, base, base.money);
		resetValue!(CArg.WAIT, int, 10)(d, od, &wait, base, base.wait);

		resetValue!(CArg.FLAG_2, string, "")(d, od, &flag2, base, base.flag2);
		resetValue!(CArg.STEP_2, string, "")(d, od, &step2, base, base.step2);
		resetValue!(CArg.CAST_RANGE, CastRange[], [CastRange.PARTY])(d, od, &castRange, base, base.castRange);
		resetValue!(CArg.LEVEL_MIN, int, 0)(d, od, &levelMin, base, base.levelMin);
		resetValue!(CArg.LEVEL_MAX, int, 0)(d, od, &levelMax, base, base.levelMax);

		resetValue!(CArg.KEY_CODE_RANGE, Range, Range.PARTY_AND_BACKPACK)(d, od, &keyCodeRange, base, base.keyCodeRange);
		resetValue!(CArg.TARGET_IS_SKILL, bool, true)(d, od, &targetIsSkill, base, base.targetIsSkill);
		resetValue!(CArg.TARGET_IS_ITEM, bool, true)(d, od, &targetIsItem, base, base.targetIsItem);
		resetValue!(CArg.TARGET_IS_BEAST, bool, true)(d, od, &targetIsBeast, base, base.targetIsBeast);
		resetValue!(CArg.TARGET_IS_HAND, bool, false)(d, od, &targetIsHand, base, base.targetIsHand);
		resetValue!(CArg.KEY_CODE, string, "")(d, od, &keyCode, base, base.keyCode);

		if (type is CType.TALK_DIALOG) { mixin(S_TRACE);
			resetValue!(CArg.INIT_VALUE, int, 1)(d, od, &initValue, base, base.initValue);
		} else { mixin(S_TRACE);
			resetValue!(CArg.INIT_VALUE, int, 0)(d, od, &initValue, base, base.initValue);
		}

		resetValue!(CArg.COMPARISON_4, Comparison4, Comparison4.Eq)(d, od, &comparison4, base, base.comparison4);
		resetValue!(CArg.COMPARISON_3, Comparison3, Comparison3.Eq)(d, od, &comparison3, base, base.comparison3);

		resetValue!(CArg.ROUND, uint, 0)(d, od, &round, base, base.round);

		resetValue!(CArg.CELL_NAME, string, "")(d, od, &cellName, base, base.cellName);
		resetValue!(CArg.CARD_GROUP, string, "")(d, od, &cardGroup, base, base.cardGroup);
		resetValue!(CArg.POSITION_TYPE, CoordinateType, CoordinateType.None)(d, od, &positionType, base, base.positionType);
		resetValue!(CArg.X, int, 0)(d, od, &x, base, base.x);
		resetValue!(CArg.Y, int, 0)(d, od, &y, base, base.y);
		resetValue!(CArg.SIZE_TYPE, CoordinateType, CoordinateType.None)(d, od, &sizeType, base, base.sizeType);
		resetValue!(CArg.WIDTH, int, 0)(d, od, &width, base, base.width);
		resetValue!(CArg.HEIGHT, int, 0)(d, od, &height, base, base.height);
		resetValue!(CArg.SCALE, int, -1)(d, od, &scale, base, base.scale);
		resetValue!(CArg.LAYER, int, -1)(d, od, &layer, base, base.layer);

		resetValue!(CArg.DO_ANIME, bool, false)(d, od, &doAnime, base, base.doAnime);
		resetValue!(CArg.IGNORE_EFFECT_BOOSTER, bool, true)(d, od, &ignoreEffectBooster, base, base.ignoreEffectBooster);

		resetValue!(CArg.SELECTION_COLUMNS, uint, 1)(d, od, &selectionColumns, base, base.selectionColumns);
		resetValue!(CArg.CENTERING_X, bool, false)(d, od, &centeringX, base, base.centeringX);
		resetValue!(CArg.CENTERING_Y, bool, false)(d, od, &centeringY, base, base.centeringY);
		resetValue!(CArg.BOUNDARY_CHECK, bool, false)(d, od, &boundaryCheck, base, base.boundaryCheck);
		resetValue!(CArg.START_ACTION, StartAction, StartAction.NextRound)(d, od, &startAction, base, base.startAction);
		resetValue!(CArg.IGNITE, bool, false)(d, od, &ignite, base, base.ignite);
		resetValue!(CArg.KEY_CODES, string[], [])(d, od, &keyCodes, base, base.keyCodes);

		resetValue!(CArg.MATCHING_TYPE, MatchingType, MatchingType.And)(d, od, &matchingType, base, base.matchingType);

		resetValue!(CArg.HOLDING_COUPON, string, "")(d, od, &holdingCoupon, base, base.holdingCoupon);
		resetValue!(CArg.REF_ABILITY, bool, false)(d, od, &refAbility, base, base.refAbility);

		resetValue!(CArg.SELECT_CARD, bool, false)(d, od, &selectCard, base, base.selectCard);
		resetValue!(CArg.SELECT_TALKER, bool, false)(d, od, &selectTalker, base, base.selectTalker);
		resetValue!(CArg.INVERT_RESULT, bool, false)(d, od, &invertResult, base, base.invertResult);

		resetValue!(CArg.CONSUME_CARD, bool, true)(d, od, &consumeCard, base, base.consumeCard);

		resetValue!(CArg.MOTIONS, Motion[], [])(d, od, &motions, base, base.motions);

		// セリフ・メッセージ間の変換
		auto resetText = true;
		auto resetDialogs = true;
		if (d.use(CArg.TEXT) && !d.use(CArg.DIALOGS) && dialogs.length) { mixin(S_TRACE);
			auto text = "";
			final switch (dialogStatus) {
			case DialogStatus.Top:
				text = dialogs[0].text;
				break;
			case DialogStatus.Under:
				text = dialogs[$ - 1].text;
				break;
			case DialogStatus.UnderWithCoupon:
				auto exists = false;
				foreach_reverse (dlg; dialogs) { mixin(S_TRACE);
					if (dlg.rCoupons.length) { mixin(S_TRACE);
						text = dlg.text;
						exists = true;
						break;
					}
				}
				if (!exists) text = dialogs[$ - 1].text;
				break;
			}
			this.text = text;
			if (text != "") resetText = false;
		} else if (d.use(CArg.DIALOGS) && !d.use(CArg.TEXT)) { mixin(S_TRACE);
			if (text == "") { mixin(S_TRACE);
				dialogs = [new SDialog];
			} else { mixin(S_TRACE);
				dialogs = base ? .map!(a => a.dup)(base.dialogs).array() : [new SDialog];
				final switch (dialogStatus) {
				case DialogStatus.Top:
					dialogs[0].text = text;
					break;
				case DialogStatus.Under:
					dialogs[$ - 1].text = text;
					break;
				case DialogStatus.UnderWithCoupon:
					auto exists = false;
					foreach_reverse (dlg; dialogs) { mixin(S_TRACE);
						if (dlg.rCoupons.length) { mixin(S_TRACE);
							dlg.text = text;
							exists = true;
							break;
						}
					}
					if (!exists) dialogs[$ - 1].text = text;
					break;
				}
				resetDialogs = false;
			}
		}

		if (resetText) resetValue!(CArg.TEXT, string, "")(d, od, &text, base, base.text);
		if (resetDialogs) resetValue!(CArg.DIALOGS, SDialog[], [])(d, od, &dialogs, base, base.dialogs);

		resetValue!(CArg.TARGET_S, Target, Target(Target.M.SELECTED, false))(d, od, &targetS, base, base.targetS);
		resetValue!(CArg.TALKER_NC, Talker, Talker.SELECTED)(d, od, &talkerNC, base, base.talkerNC);

		resetValue!(CArg.BG_IMAGES, BgImage[], [])(d, od, &backs, base, base.backs);

		resetValue!(CArg.COUPONS, Coupon[], [])(d, od, &coupons, base, base.coupons);

		if ((type is CType.GET_COUPON || type is CType.LOSE_COUPON) && range is Range.FIELD) { mixin(S_TRACE);
			// 称号獲得・喪失コンテントでは「フィールド全体」は使用不可
			range = Range.SELECTED;
		}
		if (type is CType.BRANCH_COUPON && !od.use(CArg.RANGE)) { mixin(S_TRACE);
			// CArg.RANGEが無いイベントコンテントから称号分岐コンテントへ変換した場合、
			// rangeの初期値がRange.FIELDになっているので、Range.SELECTEDにしておく
			range = Range.SELECTED;
		}

		// 称号関係の相互変換
		auto resetCoupon = true;
		auto resetCouponNames = true;
		if (od.use(CArg.COUPON) && d.use(CArg.COUPON_NAMES)) { mixin(S_TRACE);
			if (coupon != "") { mixin(S_TRACE);
				couponNames = [coupon];
				resetCouponNames = false;
			}
		} else if (od.use(CArg.COUPON_NAMES) && d.use(CArg.COUPON)) { mixin(S_TRACE);
			if (couponNames.length && couponNames[0] != "") { mixin(S_TRACE);
				coupon = couponNames[0];
				resetCoupon = false;
			}
		}
		if (resetCoupon) resetValue!(CArg.COUPON, string, "")(d, od, &coupon, base, base.coupon);
		if (resetCouponNames) resetValue!(CArg.COUPON_NAMES, string[], [])(d, od, &couponNames, base, base.couponNames);

		validate();
	}

	private SimpleTextHolder _name;
	/// テキスト。
	@property
	private void setNameImpl(string name, bool fromCallback) { mixin(S_TRACE);
		if (_name.text != name) { mixin(S_TRACE);
			changed();
			if (type is CType.START && tree) { mixin(S_TRACE);
				tree._startNames.remove(this.name);
				tree._startNames[name] = this;
			}
			if (_type is CType.START && _tree) { mixin(S_TRACE);
				_tree.startUseCounter.change(toStartId(_name.text), toStartId(name), true);
			}
			_name.text = name;

			if (!fromCallback && parent && parent.detail.nextType is CNextType.ID_AREA) { mixin(S_TRACE);
				branchAreaCondition = icmp(name, "Default") == 0 ? 0UL : to!ulong(name);
			}
			if (!fromCallback && parent && parent.detail.nextType is CNextType.ID_BATTLE) { mixin(S_TRACE);
				branchBattleCondition = icmp(name, "Default") == 0 ? 0UL : to!ulong(name);
			}
			// Wsn.2
			if (!fromCallback && parent && parent.detail.nextType is CNextType.COUPON) { mixin(S_TRACE);
				branchCouponCondition = name;
			}
		}
	}
	/// ditto
	void setName(in CProps prop, string name) { mixin(S_TRACE);
		setNameImpl(name, false);
		if (parent) { mixin(S_TRACE);
			parent.validText(prop, this);
		}
	}
	/// ditto
	@property
	const
	string name() { return _name.text; }

	/// nameを後続コンテントとして適切な名前に変換して返す。
	private void validText(in CProps prop, Content n) { mixin(S_TRACE);
		if (!prop) return;
		string selectName(string[] selectable, string def) { mixin(S_TRACE);
			foreach (nn; next) { mixin(S_TRACE);
				if (nn is n) continue;
				cwx.utils.remove(selectable, nn.name);
			}
			return selectable.length ? selectable[0] : def;
		}
		bool setNum() { mixin(S_TRACE);
			if (prop.sys.evtChildDefault != n.name && !std.string.isNumeric(n.name) || n.name == "0") { mixin(S_TRACE);
				n.setNameImpl(prop.sys.evtChildDefault, false);
				return true;
			}
			return false;
		}
		auto root = this.cwxParent;
		while (root && root.cwxParent) root = root.cwxParent;
		auto summ = cast(Summary)root;

		final switch (detail.nextType) {
		case CNextType.NONE: n.setNameImpl("", false); break;
		case CNextType.TEXT: break;
		case CNextType.BOOL: { mixin(S_TRACE);
			if (prop.sys.evtChildTrue != n.name && prop.sys.evtChildFalse != n.name) { mixin(S_TRACE);
				n.setNameImpl(selectName([prop.sys.evtChildTrue, prop.sys.evtChildFalse], prop.sys.evtChildTrue), false);
			}
		} break;
		case CNextType.STEP: { mixin(S_TRACE);
			if (prop.sys.evtChildDefault != n.name && !std.string.isNumeric(n.name)) { mixin(S_TRACE);
				int num = prop.looks.stepMaxCount;
				if (summ) { mixin(S_TRACE);
					auto step = summ.flagDirRoot.findStep(this.step);
					if (step) num = step.count;
				}
				string[] array;
				uint start = 0;
				foreach (ct; next) { mixin(S_TRACE);
					if (std.string.isNumeric(ct.name)) { mixin(S_TRACE);
						try {
							auto value = .to!uint(ct.name);
							start = .max(value + 1, start);
							num = .max(value, num);
						} catch (ConvException e) {
							// 処理無し
							printStackTrace();
						}
					}
				}
				start = .min(num, start);
				foreach (i; .iota(start, num)) { mixin(S_TRACE);
					array ~= .text(i);
				}
				array ~= prop.sys.evtChildDefault;
				n.setNameImpl(selectName(array, prop.sys.evtChildDefault), false);
			}
		} break;
		case CNextType.ID_AREA: { mixin(S_TRACE);
			if (setNum() && summ) { mixin(S_TRACE);
				string[] array;
				foreach (a; summ.areas) { mixin(S_TRACE);
					array ~= .text(a.id);
				}
				array ~= prop.sys.evtChildDefault;
				n.setNameImpl(selectName(array, prop.sys.evtChildDefault), false);
			}
		} break;
		case CNextType.ID_BATTLE: { mixin(S_TRACE);
			if (setNum() && summ) { mixin(S_TRACE);
				string[] array;
				foreach (a; summ.battles) { mixin(S_TRACE);
					array ~= .text(a.id);
				}
				array ~= prop.sys.evtChildDefault;
				n.setNameImpl(selectName(array, prop.sys.evtChildDefault), false);
			}
		} break;
		case CNextType.TRIO: { mixin(S_TRACE);
			if (prop.sys.evtChildGreater != n.name && prop.sys.evtChildLesser != n.name && prop.sys.evtChildEq != n.name) { mixin(S_TRACE);
				n.setNameImpl(selectName([prop.sys.evtChildGreater, prop.sys.evtChildLesser, prop.sys.evtChildEq], prop.sys.evtChildGreater), false);
			}
		} break;
		case CNextType.COUPON: break; // Wsn.2
		}
	}

	/// 専らシナリオ作者が参考のために記すコンテントのコメント。
	private string _comment = "";
	/// ditto
	@property
	const
	string comment() {return _comment;}
	/// ditto
	@property
	void comment(string v) { mixin(S_TRACE);
		if (_comment == v) return;
		changed();
		_comment = v;
	}

	private Content _parent = null;
	/// 親イベント。
	@property
	private void parent(Content parent) in { mixin(S_TRACE);
		assert (!parent || parent.detail.owner);
		assert (parent !is this);
		assert (type !is CType.START);
	} body { mixin(S_TRACE);
		if (_parent is parent) return;
		bool oldAreaBr = _parent && _parent.detail.nextType == CNextType.ID_AREA;
		bool newAreaBr = parent && parent.detail.nextType == CNextType.ID_AREA;
		bool oldBattleBr = _parent && _parent.detail.nextType == CNextType.ID_BATTLE;
		bool newBattleBr = parent && parent.detail.nextType == CNextType.ID_BATTLE;
		bool oldCouponBr = _parent && _parent.detail.nextType == CNextType.COUPON;
		bool newCouponBr = parent && parent.detail.nextType == CNextType.COUPON;
		if (!oldAreaBr && newAreaBr) { mixin(S_TRACE);
			if (icmp(name, "default") == 0) { mixin(S_TRACE);
				branchAreaCondition = 0;
			} else if (std.string.isNumeric(name)) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					branchAreaCondition = to!(ulong)(name);
				} catch (Exception) { mixin(S_TRACE);
					printStackTrace();
					branchAreaCondition = 0;
				}
			}
		} else if (oldAreaBr && !newAreaBr) { mixin(S_TRACE);
			branchAreaCondition = 0;
		}
		if (!oldBattleBr && newBattleBr) { mixin(S_TRACE);
			if (icmp(name, "default") == 0) { mixin(S_TRACE);
				branchBattleCondition = 0;
			} else if (std.string.isNumeric(name)) { mixin(S_TRACE);
				try { mixin(S_TRACE);
					branchBattleCondition = to!(ulong)(name);
				} catch (Exception) { mixin(S_TRACE);
					printStackTrace();
					branchBattleCondition = 0;
				}
			}
		} else if (oldBattleBr && !newBattleBr) { mixin(S_TRACE);
			branchBattleCondition = 0;
		}
		// Wsn.2
		if (!oldCouponBr && newCouponBr) { mixin(S_TRACE);
			branchCouponCondition = name;
		} else if (oldCouponBr && !newCouponBr) { mixin(S_TRACE);
			branchCouponCondition = "";
		}
		_parent = parent;
	}
	/// ditto
	@property
	Content parent() { return _parent; }
	/// ditto
	@property
	const
	const(Content) parent() { return _parent; }
	@property
	override string cwxPath(bool id) { mixin(S_TRACE);
		if (_parent) { mixin(S_TRACE);
			// 再帰は回避する
			auto c = this;
			size_t[] paths;
			while (c.parent) { mixin(S_TRACE);
				paths ~= .countUntil!("a is b")(c.parent.next, c);
				c = c.parent;
			}
			char[] path;
			foreach_reverse (i; paths) path = .cpjoin2(path, [], i);
			auto ip = .assumeUnique(path);
			return .cpjoin(c, ip, id);
		} else if (_tree) { mixin(S_TRACE);
			return .cpjoin(_tree, .countUntil!("a is b")(_tree.starts, this), id);
		}
		return "";
	}
	override CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (.cpempty(path)) return this;
		auto cate = .cpcategory(path);
		auto c = this;
		if (cate == "") { mixin(S_TRACE);
			// 再帰は回避する
			while (cate == "") { mixin(S_TRACE);
				auto index = .cpindex(path);
				if (index >= c.next.length) return null;
				c = c.next[index];
				path = .cpbottom(path);
				if (.cpempty(path)) return c;
				cate = .cpcategory(path);
			}
		}
		switch (cate) {
		case "motion": { mixin(S_TRACE);
			auto index = .cpindex(path);
			if (index >= c.motions.length) return null;
			return c.motions[index].findCWXPath(.cpbottom(path));
		}
		case "dialog": { mixin(S_TRACE);
			auto index = .cpindex(path);
			if (index >= c.dialogs.length) return null;
			return c.dialogs[index].findCWXPath(.cpbottom(path));
		}
		case "text": { mixin(S_TRACE);
			auto index = .cpindex(path);
			if (index > 0) return null;
			return c._text.findCWXPath(.cpbottom(path));
		}
		case "name": { mixin(S_TRACE);
			auto index = .cpindex(path);
			if (index > 0) return null;
			return c._name.findCWXPath(.cpbottom(path));
		}
		case "background": { mixin(S_TRACE);
			auto index = .cpindex(path);
			if (index >= c.backs.length) return null;
			return c.backs[index];
		}
		default: break;
		}
		return null;
	}
	@property
	inout
	inout(CWXPath)[] cwxChilds() { mixin(S_TRACE);
		inout(CWXPath)[] r;
		foreach (a; next) r ~= a;
		foreach (a; dialogs) r ~= a;
		if (_text) r ~= _text;
		foreach (a; motions) r ~= a;
		foreach (a; backs) r ~= a;
		foreach (a; coupons) r ~= a;
		return r;
	}
	@property
	CWXPath cwxParent() { mixin(S_TRACE);
		if (_parent) { mixin(S_TRACE);
			return _parent;
		} else if (_tree) { mixin(S_TRACE);
			return _tree;
		}
		return null;
	}

	/// EventTreeからこのコンテントに到達するまでのindex群を返す。
	@property
	size_t[] ctPath() { mixin(S_TRACE);
		if (parent) { mixin(S_TRACE);
			auto c = this;
			size_t[] r;
			while (c.parent) { mixin(S_TRACE);
				assert (.contains!("a is b")(c.parent.next, c));
				r ~= .countUntil!("a is b")(c.parent.next, c);
				c = c.parent;
			}
			assert (c.tree !is null);
			r ~= .countUntil!("a is b")(c.tree.starts, c);
			std.algorithm.reverse(r);
			return r;
		} else { mixin(S_TRACE);
			assert (contains!("a is b")(_tree.starts, this));
			return [.countUntil!("a is b")(_tree.starts, this)];
		}
	}
	/// このコンテントが属すツリーを返す。
	@property
	EventTree tree() { mixin(S_TRACE);
		auto ps = parentStart;
		if (ps) return ps._tree;
		return null;
	}
	/// ditto
	@property
	const
	const(EventTree) tree() { mixin(S_TRACE);
		auto ps = parentStart;
		if (ps) return ps._tree;
		return null;
	}
	/// このコンテントが属すスタートコンテントを返す。
	@property
	Content parentStart() { mixin(S_TRACE);
		if (type is CType.START) return this;
		if (!parent) return null;
		return parent.parentStart;
	}
	/// ditto
	@property
	const
	const(Content) parentStart() { mixin(S_TRACE);
		Rebindable!(typeof(return)) c = this;
		while (c) { mixin(S_TRACE);
			if (c.type is CType.START) return c;
			c = c.parent;
		}
		return null;
	}
	/// パスを辿って子孫のコンテントを返す。
	Content fromPath(size_t[] path) { mixin(S_TRACE);
		auto c = this;
		while (true) { mixin(S_TRACE);
			if (!path.length) return c;
			if (path.length == 1) return c.next[path[0]];
			c = c.next[path[0]];
			path = path[1 .. $];
		}
	}
	/// このコンテントが指定されたコンテントそのもの、
	/// もしくは子孫であればtrueを返す。
	bool isDescendant(in Content c) { mixin(S_TRACE);
		auto cc = this;
		while (cc) { mixin(S_TRACE);
			if (cc is c) return true;
			cc = cc.parent;
		}
		return false;
	}

	private Content[] _next = [];
	/// 後続イベント群。
	@property
	inout
	inout(Content)[] next() {return _next;}

	/// このコンテントを親にしたツリーの
	/// イベントコンテント数を再帰的にカウントする。
	@property
	const
	size_t countChildren() { mixin(S_TRACE);
		auto c = .rebindable(this);
		size_t count = 0;
		while (c.next.length) { mixin(S_TRACE);
			count += c.next.length;
			if (c.next.length == 1) { mixin(S_TRACE);
				// 再帰回避
				c = c.next[0];
			} else { mixin(S_TRACE);
				foreach (n; c.next) { mixin(S_TRACE);
					count += n.countChildren();
				}
				break;
			}
		}
		return count;
	}

	/// このコンテントを親にしたツリーにある
	/// イベントコンテントをリスト化して返す。
	@property
	Content[] allChildren() { mixin(S_TRACE);
		Content[] r;
		auto c = .rebindable(this);
		while (c.next.length) { mixin(S_TRACE);
			if (c.next.length == 1) { mixin(S_TRACE);
				// 再帰回避
				r ~= c.next[0];
				c = c.next[0];
			} else { mixin(S_TRACE);
				foreach (n; c.next) { mixin(S_TRACE);
					r ~= n;
					r ~= n.allChildren;
				}
				break;
			}
		}
		return r;
	}

	/// 後続コンテントのインデックスを交換する。
	void swapContent(size_t index1, size_t index2) { mixin(S_TRACE);
		if (index1 != index2) changed();
		auto temp = _next[index1];
		_next[index1] = _next[index2];
		_next[index2] = temp;
	}

	/// 後続コンテントを追加する。
	void add(in CProps prop, Content c) { mixin(S_TRACE);
		if (c.parent) c.parent.remove(c);
		validText(prop, c);
		c.parent = this;
		if (_uc !is null) c.setUseCounter(useCounter);
		if (_suc !is null) c.setSUseCounter(startUseCounter);
		c.changeHandler = changeHandler;
		_next ~= c;
		changed();
	}
	/// ditto
	void insert(in CProps prop, size_t index, Content c) { mixin(S_TRACE);
		if (next.length == index) { mixin(S_TRACE);
			add(prop, c);
		} else { mixin(S_TRACE);
			if (c.parent) c.parent.remove(c);
			validText(prop, c);
			c.parent = this;
			if (_uc !is null) c.setUseCounter(useCounter);
			if (_suc !is null) c.setSUseCounter(startUseCounter);
			c.changeHandler = changeHandler;
			_next = _next[0 .. index] ~ c ~ _next[index .. $];
			changed();
		}
	}

	/// 後続コンテントを除外する。
	void remove(size_t index) { mixin(S_TRACE);
		if (_uc !is null) _next[index].removeUseCounter();
		if (_suc !is null) _next[index].removeSUseCounter();
		_next[index].changeHandler = null;
		_next[index].parent = null;
		_next = _next[0 .. index] ~ _next[index + 1 .. $];
		changed();
	}
	/// ditto
	void remove(Content c) { mixin(S_TRACE);
		foreach (i, ct; _next) { mixin(S_TRACE);
			if (c is ct) { mixin(S_TRACE);
				remove(i);
				return;
			}
		}
		assert (0);
	}

	/// このイベントコンテントと強く関係するリソースを返す。
	/// そのようなリソースが無い場合はnullを返す。
	inout
	inout(CWXPath) connectedResource(Summary)(inout(Summary) summ) { mixin(S_TRACE);
		auto d = detail;
		if (d.use(CArg.AREA)) return cast(typeof(return))summ.area(area);
		if (d.use(CArg.BATTLE)) return cast(typeof(return))summ.battle(battle);
		if (d.use(CArg.PACKAGE)) return cast(typeof(return))summ.cwPackage(packages);
		if (d.use(CArg.FLAG)) return cast(typeof(return))summ.flagDirRoot.findFlag(flag);
		if (d.use(CArg.STEP)) return cast(typeof(return))summ.flagDirRoot.findStep(step);
		if (d.use(CArg.CAST)) return cast(typeof(return))summ.cwCast(casts);
		if (d.use(CArg.ITEM)) return cast(typeof(return))summ.item(item);
		if (d.use(CArg.SKILL)) return cast(typeof(return))summ.skill(skill);
		if (d.use(CArg.BEAST)) return cast(typeof(return))summ.beast(beast);
		if (d.use(CArg.INFO)) return cast(typeof(return))summ.info(info);
		if (d.use(CArg.START)) return tree ? cast(typeof(return))tree.start(start) : null;
		if (d.use(CArg.FLAG_2)) return cast(typeof(return))summ.flagDirRoot.findFlag(flag2);
		if (d.use(CArg.STEP_2)) return cast(typeof(return))summ.flagDirRoot.findStep(step2);

		return null;
	}

	/// このイベントコンテントと強く関係するIDを返す。
	CouponId[] connectedCoupons() { mixin(S_TRACE);
		auto d = detail;
		CouponId[] r;
		if (d.use(CArg.COUPON)) r ~= toCouponId(coupon);
		if (d.use(CArg.COUPONS)) { mixin(S_TRACE);
			foreach (coupon; coupons) { mixin(S_TRACE);
				r ~= toCouponId(coupon.name);
			}
		}
		if (d.use(CArg.COUPON_NAMES)) { mixin(S_TRACE);
			foreach (name; couponNames) { mixin(S_TRACE);
				r ~= toCouponId(name);
			}
		}
		return r;
	}
	/// ditto
	GossipId[] connectedGossips() { mixin(S_TRACE);
		auto d = detail;
		GossipId[] r;
		if (d.use(CArg.GOSSIP)) r ~= toGossipId(gossip);
		return r;
	}
	/// ditto
	CompleteStampId[] connectedCompleteStamps() { mixin(S_TRACE);
		auto d = detail;
		CompleteStampId[] r;
		if (d.use(CArg.COMPLETE_STAMP)) r ~= toCompleteStampId(completeStamp);
		return r;
	}
	/// ditto
	KeyCodeId[] connectedKeyCodes() { mixin(S_TRACE);
		auto d = detail;
		KeyCodeId[] r;
		if (d.use(CArg.KEY_CODE)) r ~= toKeyCodeId(keyCode);
		if (d.use(CArg.KEY_CODES)) { mixin(S_TRACE);
			foreach (keyCode; keyCodes) { mixin(S_TRACE);
				r ~= toKeyCodeId(keyCode);
			}
		}
		return r;
	}
	/// ditto
	CellNameId[] connectedCellNames() { mixin(S_TRACE);
		auto d = detail;
		CellNameId[] r;
		if (d.use(CArg.CELL_NAME)) r ~= toCellNameId(cellName);
		return r;
	}
	/// ditto
	CardGroupId[] connectedCardGroups() { mixin(S_TRACE);
		auto d = detail;
		CardGroupId[] r;
		if (d.use(CArg.CARD_GROUP)) r ~= toCardGroupId(cardGroup);
		return r;
	}

	/// このイベントコンテントと強く関係するファイルパスを返す。
	/// そのようなファイルが無い場合は""を返す。
	@property
	const
	string connectedFile() { mixin(S_TRACE);
		auto d = detail;
		if (d.use(CArg.TALKER_C)) { mixin(S_TRACE);
			foreach (path; _cardPaths) { mixin(S_TRACE);
				if (path.path != "" && !path.path.isBinImg) return path.path;
			}
		}
		if (d.use(CArg.BGM_PATH)) return bgmPath;
		if (d.use(CArg.SOUND_PATH)) return soundPath;

		return "";
	}

	private void setValUCs(T)(T val, UseCounter uc = null, Content c = null) { mixin(S_TRACE);
		static if (is(typeof(val.owner(this)))) {
			val.owner = this;
		}
		static if (is(typeof(val.changeHandler(null)))) {
			val.changeHandler = changeHandler;
		}
		static if (!is(T : Motion)) {
			static if (is(typeof(val.setUseCounter(uc)))) {
				if (val.useCounter || !uc) { mixin(S_TRACE);
					val.removeUseCounter();
				}
				if (uc) { mixin(S_TRACE);
					val.setUseCounter(uc);
				}
				static if (is(typeof(val.parent))) {
					if (c && val.parent) throw new EventException("used other event.");
					val.parent = c;
				}
			} else static if (!is(T : string) && is(typeof(val[0u]))) {
				foreach (vc; val) { mixin(S_TRACE);
					setValUCs(vc, uc, c);
				}
			}
		}
	}
	/// Example:
	/// ---
	/// mixin Prop!(AreaUser, "area", 0UL, ".area", ".area", true);
	///
	/// private AreaUser _area;
	/// void area(ulong val) { mixin(S_TRACE);
	/// 	scope (exit) validate();
	/// 	if (!_area) _area = new AreaUser(this);
	/// 	if (_area.area != val) changed();
	/// 	setValUCs(this._area.area, null, null);
	/// 	setValUCs(val, _uc, this);
	/// 	_area.area = val;
	/// }
	/// ulong area() { mixin(S_TRACE);
	/// 	return _area ? _area.area : 0UL;
	/// }
	/// ---
	private template Prop(T, T2, string Name, T2 Def, string Set = "", string Get = "", bool New = false, bool Callback = false) {
		static if (New) {
			mixin ("private " ~ T.stringof ~ " _" ~ Name ~ ";");
		} else {
			mixin ("private " ~ T.stringof ~ " _" ~ Name ~ " = Def;");
		}
		mixin ("@property void " ~ Name ~ "(" ~ T2.stringof ~ " val) {"
			~ "scope (exit) validate();"
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
				~ "    _" ~ Name ~ " = new " ~ T.stringof ~ (Callback ? "(this, true);" : "(this);")
				~ "    setValUCs(_" ~ Name ~ ", _uc, this);"
				~ "}"
			) : "")
			~ "if (_" ~ Name ~ Get ~ " != val) changed();"
			~ "setValUCs(this._" ~ Name ~ Get ~ ");"
			~ "setValUCs(val, _uc, this);"
			~ "_" ~ Name ~ Set ~ " = val;"
		~ "}");
		static if (New) {
			static if (is(T2 == string)) {
				mixin ("@property const T2 " ~ Name ~ "() {return _" ~ Name ~ " ? _" ~ Name ~ Get ~ " : Def;}");
			} else static if (isVArray!T2) {
				mixin ("@property inout inout(ElementType!T2)[] " ~ Name ~ "() {return _" ~ Name ~ " ? _" ~ Name ~ Get ~ " : cast(typeof(return))Def;}");
			} else {
				mixin ("@property inout inout(T2) " ~ Name ~ "() {return _" ~ Name ~ " ? _" ~ Name ~ Get ~ " : " ~ Def.stringof ~ ";}");
			}
		} else {
			static if (__VERSION__ <= 2060 && isVArray!T2) {
				mixin ("@property " ~ ElementType!T.stringof ~ "[] " ~ Name ~ "() const {return cast(T2)_" ~ Name ~ Get ~ ";}");
			} else static if (isVArray!T2) {
				mixin ("@property inout inout(ElementType!T2)[] " ~ Name ~ "() {return _" ~ Name ~ Get ~ ";}");
			} else {
				mixin ("@property inout inout(T2) " ~ Name ~ "() {return _" ~ Name ~ Get ~ ";}");
			}
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
	@property
	void start(string start) { mixin(S_TRACE);
		if (_start != start) { mixin(S_TRACE);
			changed();
			if (_suc && detail.use(CArg.START)) { mixin(S_TRACE);
				_suc.remove(toStartId(_start), this);
				_suc.add(toStartId(start), this);
			}
			_start = start;
		}
	}
	/// ditto
	@property
	const
	string start() {return _start;}

	/// エリアID。
	mixin Prop!(AreaUser, ulong, "area", 0UL, ".area", ".area", true);
	/// バトルID。
	mixin Prop!(BattleUser, ulong, "battle", 0UL, ".battle", ".battle", true);
	/// パッケージID。
	mixin Prop!(PackageUser, ulong, "packages", 0UL, ".packages", ".packages", true);
	/// フラグ。
	mixin Prop!(FlagUser, string, "flag", "", ".flag", ".flag", true);
	/// ステップ。
	mixin Prop!(StepUser, string, "step", "", ".step", ".step", true);
	/// 話者(カード画像含む)。
	private CardImage[] _cardPaths;
	@property
	void cardPaths(const(CardImage)[] cardPaths) { mixin(S_TRACE);
		if (cardPaths == this.cardPaths) return;
		changed();
		scope (exit) validate();
		foreach (cardPath; _cardPaths) { mixin(S_TRACE);
			setValUCs(cardPath, null, null);
		}
		_cardPaths = [];
		foreach (cardPath; cardPaths) { mixin(S_TRACE);
			auto u = new CardImage(this, cardPath);
			setValUCs(u, _uc, this);
			_cardPaths ~= u;
		}
	}
	@property
	const
	CardImage[] cardPaths() { mixin(S_TRACE);
		return .map!(a => new CardImage(cast(IPathUser)null, a))(_cardPaths).array();
	}
	/// BGMパス。
	mixin Prop!(PathUser, string, "bgmPath", "", ".path", ".path", true);
	/// BGM再生チャンネル(Wsn.1)。
	mixin Prop!(uint, "bgmChannel", 0);
	mixin MaxMin!(uint, "bgmChannel", 1, 0);
	/// BGM音量(%)(Wsn.1)。
	mixin Prop!(uint, "bgmVolume", 100);
	mixin MaxMin!(uint, "bgmVolume", 100, 0);
	/// BGMループ回数(Wsn.1)。0は無限ループ。
	mixin Prop!(uint, "bgmLoopCount", 0);
	/// BGMフェードイン時間(ミリ秒)(Wsn.1)。
	mixin Prop!(uint, "bgmFadeIn", 0);
	/// SEパス。
	mixin Prop!(PathUser, string, "soundPath", "", ".path", ".path", true);
	/// SE再生チャンネル(Wsn.1)。
	mixin Prop!(uint, "soundChannel", 0);
	mixin MaxMin!(uint, "soundChannel", 1, 0);
	/// SE音量(%)(Wsn.1)。
	mixin Prop!(uint, "soundVolume", 100);
	mixin MaxMin!(uint, "soundVolume", 100, 0);
	/// SEループ回数(Wsn.1)。
	mixin Prop!(uint, "soundLoopCount", 1);
	mixin MaxMin!(uint, "soundLoopCount", int.max, 1);
	/// SEフェードイン時間(ミリ秒)(Wsn.1)。
	mixin Prop!(uint, "soundFadeIn", 0);
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
	mixin Prop!(CouponUser, string, "coupon", "", ".coupon", ".coupon", true);
	/// ゴシップ。
	mixin Prop!(GossipUser, string, "gossip", "", ".gossip", ".gossip", true);
	/// 終了印。
	mixin Prop!(CompleteStampUser, string, "completeStamp", "", ".completeStamp", ".completeStamp", true);

	/// 精神系能力。
	mixin Prop!(Mental, "mental", Mental.init);
	/// 肉体系能力。
	mixin Prop!(Physical, "physical", Physical.init);
	/// 状態。
	mixin Prop!(Status, "status", Status.NONE);
	/// 範囲。
	mixin Prop!(Range, "range", Range.FIELD);
	/// カード視覚効果。
	mixin Prop!(CardVisual, "cardVisual", CardVisual.NONE);
	/// 対象(睡眠者判定含む)。
	mixin Prop!(Target, "targetS", Target(Target.M.SELECTED, false));
	/// 話者(カード画像を含めない)。
	mixin Prop!(Talker, "talkerNC", Talker.SELECTED);
	private bool check_talkerNC(Talker val) { mixin(S_TRACE);
		final switch (val) {
		case Talker.SELECTED, Talker.UNSELECTED, Talker.RANDOM, Talker.VALUED: return true;
		case Talker.CARD: return false;
		}
	}
	/// 効果タイプ。
	mixin Prop!(EffectType, "effectType", EffectType.NONE);
	/// 抵抗属性。
	mixin Prop!(Resist, "resist", Resist.UNFAIL);
	/// 背景切替方式。
	mixin Prop!(Transition, "transition", Transition.DEFAULT);

	/// 全員を対象とするか。
	mixin Prop!(bool, "targetAll", false);
	/// 対象選択方法。
	mixin Prop!(SelectionMethod, "selectionMethod", SelectionMethod.Manual);
	/// 平均を取るか。
	mixin Prop!(bool, "average", false);
	/// 済印を付けるか否か。
	mixin Prop!(bool, "complete", false);

	/// レベル。
	mixin Prop!(int, "unsignedLevel", 1);
	mixin MaxMin!(int, "unsignedLevel", int.max, 1);
	/// マイナスにする事が可能なレベル。
	mixin Prop!(int, "signedLevel", 0);
	mixin MaxMin!(int, "signedLevel", int.max, int.min);
	/// 命中補正。-5～+5。
	mixin Prop!(int, "successRate", 5);
	mixin MaxMin!(int, "successRate", 5, -5);
	/// 背景切替スピード。0～10で、0はアニメーション無しと等価。
	mixin Prop!(int, "transitionSpeed", 5u);
	mixin MaxMin!(int, "transitionSpeed", 10, 0);
	/// カードスピード(Wsn.4)。0～10で、小さいほど速い。
	/// -1でエンジンの設定に従う。
	mixin Prop!(int, "cardSpeed", -1);
	mixin MaxMin!(int, "cardSpeed", 10, -1);
	/// カード本体の速度設定よりも優先する(Wsn.4)。
	mixin Prop!(bool, "overrideCardSpeed", false);
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
	mixin MaxMin!(int, "couponValue", int.max, int.min);
	/// 人数。
	mixin Prop!(int, "partyNumber", 2);
	mixin MaxMin!(int, "partyNumber", int.max, 1);
	/// カード枚数。
	mixin Prop!(int, "cardNumber", 1u);
	mixin MaxMin!(int, "cardNumber", int.max, 0);
	/// 金額。
	mixin Prop!(int, "money", 0u);
	mixin MaxMin!(int, "money", int.max, 0);
	/// 停止時間。0.1秒単位。
	mixin Prop!(int, "wait", 10);
	mixin MaxMin!(int, "wait", int.max, 0);

	/// 操作対象フラグ(CardWirth Extender 1.30～)。
	mixin Prop!(FlagUser, string, "flag2", "", ".flag", ".flag", true);
	/// 操作対象ステップ(CardWirth Extender 1.30～)。
	mixin Prop!(StepUser, string, "step2", "", ".step", ".step", true);
	/// ランダム選択範囲(CardWirth Extender 1.30～)。
	mixin Prop!(CastRange[], "castRange", [CastRange.PARTY]);
	/// 下限レベル(CardWirth Extender 1.30～)。
	mixin Prop!(int, "levelMin", 0);
	mixin MaxMin!(int, "levelMin", int.max, 0);
	/// 上限レベル(CardWirth Extender 1.30～)。
	mixin Prop!(int, "levelMax", 0);
	mixin MaxMin!(int, "levelMax", int.max, 0);

	/// キーコード所持判定範囲(CardWirth 1.50)。
	mixin Prop!(Range, "keyCodeRange", Range.PARTY_AND_BACKPACK);
	private bool check_keyCodeRange(Range val) { mixin(S_TRACE);
		switch (val) {
		case Range.SELECTED:
		case Range.RANDOM:
		case Range.BACKPACK:
		case Range.PARTY_AND_BACKPACK:
		case Range.SELECTED_CARD: // Wsn.3
			return true;
		default:
			return false;
		}
	}
	/// 効果カード種別(CardWirth 1.50 / Wsn.2でHandを追加し複数選択可能に)。
	mixin Prop!(bool, "targetIsSkill", true);
	mixin Prop!(bool, "targetIsItem", true);
	mixin Prop!(bool, "targetIsBeast", true);
	mixin Prop!(bool, "targetIsHand", false);
	/// キーコード(CardWirth 1.50)。
	mixin Prop!(KeyCodeUser, string, "keyCode", "", ".keyCode", ".keyCode", true);

	/// 範囲指定用クーポン名(Wsn.2)。
	mixin Prop!(CouponUser, string, "holdingCoupon", "", ".coupon", ".coupon", true);

	/// 評価メンバ初期値(CardWirth 1.50)。
	mixin Prop!(int, "initValue", 0);

	/// 4路比較条件(CardWirth 1.50)。
	mixin Prop!(Comparison4, "comparison4", Comparison4.Eq);
	/// 3路比較条件(CardWirth 1.50)。
	mixin Prop!(Comparison3, "comparison3", Comparison3.Eq);

	/// ラウンド(CardWirth 1.50)。
	mixin Prop!(uint, "round", 0);

	/// セル名称(Wsn.1)。
	mixin Prop!(CellNameUser, string, "cellName", "", ".cellName", ".cellName", true);
	/// メニューカードグループ(Wsn.2)。
	mixin Prop!(CardGroupUser, string, "cardGroup", "", ".cardGroup", ".cardGroup", true);
	/// 位置形式(Wsn.1)。
	mixin Prop!(CoordinateType, "positionType", CoordinateType.None);
	/// X座標(Wsn.1)。
	mixin Prop!(int, "x", 0);
	/// Y座標(Wsn.1)。
	mixin Prop!(int, "y", 0);
	/// サイズ形式(Wsn.1)。
	mixin Prop!(CoordinateType, "sizeType", CoordinateType.None);
	/// 幅(Wsn.1)。
	mixin Prop!(int, "width", 0);
	/// 高さ(Wsn.1)。
	mixin Prop!(int, "height", 0);
	/// スケール(Wsn.3)。
	mixin Prop!(int, "scale", -1);
	/// レイヤ(Wsn.3)。
	mixin Prop!(int, "layer", -1);

	/// JPY1アニメーションを実行する(Wsn.1)。
	mixin Prop!(bool, "doAnime", false);
	/// エフェクトブースター関係のセルを無視する(Wsn.1)。
	mixin Prop!(bool, "ignoreEffectBooster", false);

	/// 後続選択肢の列数(Wsn.1)。
	mixin Prop!(uint, "selectionColumns", 1);
	mixin MaxMin!(uint, "selectionColumns", uint.max, 1u);
	/// メッセージを横方向にセンタリングする(Wsn.2)。
	mixin Prop!(bool, "centeringX", false);
	/// メッセージを縦方向にセンタリングする(Wsn.2)。
	mixin Prop!(bool, "centeringY", false);
	/// メッセージの禁則処理を行う(Wsn.2)。
	mixin Prop!(bool, "boundaryCheck", false);

	/// キャスト同行時の戦闘行動開始タイミング(Wsn.2)。
	mixin Prop!(StartAction, "startAction", StartAction.NextRound);

	/// イベントの発火有無(Wsn.2)。
	mixin Prop!(bool, "ignite", false);
	/// イベント発火のキーコード(Wsn.2)。
	mixin Prop!(KeyCodesUser, string[], "keyCodes", [], ".keyCodes", ".keyCodes", true);

	/// 複数のクーポン名(Wsn.2)。
	mixin Prop!(CouponNamesUser, string[], "couponNames", [], ".couponNames", ".couponNames", true);
	/// マッチングタイプ(Wsn.2)。
	mixin Prop!(MatchingType, "matchingType", MatchingType.And);

	/// 選択メンバの能力参照(Wsn.2)。
	mixin Prop!(bool, "refAbility", false);

	/// 選択カードを変更する(Wsn.3)。
	mixin Prop!(bool, "selectCard", false);
	/// 話者を選択する(Wsn.3)。
	mixin Prop!(bool, "selectTalker", false);

	/// 条件に合わない場合に成功とする(Wsn.4)。
	mixin Prop!(bool, "invertResult", false);

	/// 使用中のカードを消費するか(Wsn.3)。
	mixin Prop!(bool, "consumeCard", true);

	/// 背景画像群。
	mixin Prop!(BgImage[], "backs", []);

	/// 得点付きクーポン群(CardWirth 1.50)。
	mixin Prop!(Coupon[], "coupons", []);

	/// エリア分岐で使用するエリアID。
	mixin Prop!(AreaUser, ulong, "branchAreaCondition", 0UL, ".area", ".area", true, true);
	/// バトル分岐で使用するバトルID。
	mixin Prop!(BattleUser, ulong, "branchBattleCondition", 0UL, ".battle", ".battle", true, true);
	/// クーポン多岐分岐条件名(Wsn.2)。
	mixin Prop!(CouponUser, string, "branchCouponCondition", "", ".coupon", ".coupon", true, true);

	private void delegate() _change;
	/// 変更ハンドラを登録する。
	@property
	void changeHandler(void delegate() change) { mixin(S_TRACE);
		// 再帰は回避する
		auto c = this;
		while (true) { mixin(S_TRACE);
			c._change = change;
			if (c.next.length == 1) { mixin(S_TRACE);
				c = c.next[0];
			} else { mixin(S_TRACE);
				foreach (cc; c.next) { mixin(S_TRACE);
					cc.changeHandler = changeHandler;
				}
				break;
			}
		}
	}
	/// 変更ハンドラ。
	@property
	private void delegate() changeHandler() { mixin(S_TRACE);
		return &changed;
	}
	/// 変更を通知する。
	protected override void changed() { mixin(S_TRACE);
		if (_change) _change();
		if (type is CType.START) _updateCounter++;
	}

	private UseCounter _uc = null;
	private void setUseCounterImpl(T)(ref T v, UseCounter uc) { mixin(S_TRACE);
		static if (is(T : EventTree)) {
			return;
		} else {
			static if (is(T : Content)) if (parent is v) return;
			static if (is(typeof(v.setUseCounter(uc)))) {
				static if (is(typeof(v is null))) if (!v) return;
				if (uc) { mixin(S_TRACE);
					v.setUseCounter(uc);
				} else { mixin(S_TRACE);
					v.removeUseCounter();
				}
			} else static if (!isSomeString!(T) && is(typeof(v[0u]))) {
				foreach (i, vc; v) { mixin(S_TRACE);
					setUseCounterImpl(vc, uc);
					v[i] = vc;
				}
			}
		}
	}
	/// 使用回数カウンタを設定・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		auto c = this;
		while (true) { mixin(S_TRACE);
			foreach (v; c.tupleof) { mixin(S_TRACE);
				static if (!is(typeof(v):Content[])) { mixin(S_TRACE);
					c.setUseCounterImpl(v, uc);
				}
			}
			c._uc = uc;
			if (c._next.length == 1) {
				c = c._next[0];
			} else {
				foreach (n; c._next) {
					n.setUseCounter(uc);
				}
				break;
			}
		}
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		setUseCounter(null);
		_uc = null;
	}
	/// 使用回数カウンタを返す。存在しない場合はnullを返す。
	@property
	UseCounter useCounter() {return _uc;}

	private SUseCounter _suc = null;
	/// スタートの使用回数カウンタを設定・除去する。
	@property
	void setSUseCounter(SUseCounter suc) { mixin(S_TRACE);
		if (_suc is suc) return;
		// 再帰は回避する
		auto c = this;
		while (true) { mixin(S_TRACE);
			if (suc && c.detail.use(CArg.START)) { mixin(S_TRACE);
				suc.add(toStartId(c._start), c);
			}
			if (c._suc && c.detail.use(CArg.START)) { mixin(S_TRACE);
				c._suc.remove(toStartId(c._start), c);
			}
			c._suc = suc;
			if (c.next.length == 1) { mixin(S_TRACE);
				c = c.next[0];
			} else { mixin(S_TRACE);
				foreach (cc; c.next) { mixin(S_TRACE);
					cc.setSUseCounter(suc);
				}
				break;
			}
		}
	}
	/// ditto
	void removeSUseCounter() { mixin(S_TRACE);
		if (!_suc) return;
		// 再帰は回避する
		auto c = this;
		while (true) { mixin(S_TRACE);
			if (c._suc && c.detail.use(CArg.START)) { mixin(S_TRACE);
				c._suc.remove(toStartId(c._start), c);
			}
			c._suc = null;
			if (c.next.length == 1) { mixin(S_TRACE);
				c = c.next[0];
			} else {
				foreach (cc; c.next) { mixin(S_TRACE);
					cc.removeSUseCounter();
				}
				break;
			}
		}
	}
	/// スタートの使用回数カウンタ。
	@property
	SUseCounter startUseCounter() { return _suc; }
	override bool change(StartId newVal) { mixin(S_TRACE);
		_start = newVal;
		return true;
	}

	private void idChangeImpl(T, Id)(ref T v, Id id) { mixin(S_TRACE);
		static if (is(T : EventTree)) {
			return;
		} else {
			static if (is(T : Content)) if (parent is v) return;
			static if (is(typeof(v.change(id)))) {
				static if (is(typeof(v is null))) if (!v) return;
				v.change(id);
			} else static if (!isSomeString!(T) && is(typeof(v[0u]))) {
				foreach (i, vc; v) { mixin(S_TRACE);
					idChangeImpl(vc, id);
					v[i] = vc;
				}
			}
		}
	}
	private bool idChange(Id)(Id id) { mixin(S_TRACE);
		foreach (v; this.tupleof) { mixin(S_TRACE);
			idChangeImpl(v, id);
		}
		return true;
	}
	override bool change(PathId id) { return idChange(id); }
	override bool change(AreaId id) { return idChange(id); }
	override bool change(BattleId id) { return idChange(id); }
	override bool change(PackageId id) { return idChange(id); }
	override bool change(FlagId id) { return idChange(id); }
	override bool change(StepId id) { return idChange(id); }
	override bool change(CastId id) { return idChange(id); }
	override bool change(ItemId id) { return idChange(id); }
	override bool change(SkillId id) { return idChange(id); }
	override bool change(BeastId id) { return idChange(id); }
	override bool change(InfoId id) { return idChange(id); }
	override bool change(CouponId id) { return idChange(id); }
	override bool change(GossipId id) { return idChange(id); }
	override bool change(CompleteStampId id) { return idChange(id); }
	override bool change(KeyCodeId id) { return idChange(id); }
	override bool change(CellNameId id) { return idChange(id); }
	override bool change(CardGroupId id) { return idChange(id); }

	override bool changeCallback(AreaId oldVal, AreaId newVal) { mixin(S_TRACE);
		auto id = icmp(name, "Default") == 0 ? 0UL : to!ulong(name);
		if (parent && parent.detail.nextType is CNextType.ID_AREA && AreaId(id) == oldVal) { mixin(S_TRACE);
			setNameImpl(newVal == 0UL ? "Default" : to!string(newVal), true);
		}
		return true;
	}
	override bool changeCallback(BattleId oldVal, BattleId newVal) { mixin(S_TRACE);
		auto id = icmp(name, "Default") == 0 ? 0UL : to!ulong(name);
		if (parent && parent.detail.nextType is CNextType.ID_BATTLE && BattleId(id) == oldVal) { mixin(S_TRACE);
			setNameImpl(newVal == 0UL ? "Default" : to!string(newVal), true);
		}
		return true;
	}
	override bool changeCallback(CouponId oldVal, CouponId newVal) { mixin(S_TRACE);
		if (parent && parent.detail.nextType is CNextType.COUPON && CouponId(name) == oldVal) { mixin(S_TRACE);
			setNameImpl(newVal, true);
		}
		return true;
	}

	/// テキスト内で使用されているfont_X.png等のパス。
	@property
	const
	override string[] fontsInText() { mixin(S_TRACE);
		if (!_text) return [];
		return _text.fontsInText;
	}
	/// テキスト内で使用されているフラグのパス。
	@property
	const
	override string[] flagsInText() { mixin(S_TRACE);
		if (!_text) return [];
		return _text.flagsInText;
	}
	/// テキスト内で使用されているステップのパス。
	@property
	const
	override string[] stepsInText() { mixin(S_TRACE);
		if (!_text) return [];
		return _text.stepsInText;
	}
	/// テキスト内で使用されている色。
	@property
	const
	const(char)[] colorsInText() { return _text ? _text.colorsInText : []; }
	/// テキスト内のfont_X.bmp・フラグ・ステップを置換する。
	override void changeInText(size_t index, PathId id) { mixin(S_TRACE);
		if (_text) _text.changeInText(index, id);
	}

	/// 選択肢内で使用されている選択メンバ名等のパス。
	@property
	const
	char[] namesInName() { mixin(S_TRACE);
		return parent && parent.detail.nextType is CNextType.TEXT ? _name.namesInText : [];
	}
	/// 選択肢内で使用されているフラグのパス。
	@property
	const
	string[] flagsInName() { mixin(S_TRACE);
		return parent && parent.detail.nextType is CNextType.TEXT ? _name.flagsInText : [];
	}
	/// 選択肢内で使用されているステップのパス。
	@property
	const
	string[] stepsInName() { mixin(S_TRACE);
		return parent && parent.detail.nextType is CNextType.TEXT ? _name.stepsInText : [];
	}

	/// ditto
	override void changeInText(size_t index, FlagId id) { mixin(S_TRACE);
		if (_text) _text.changeInText(index, id);
		_name.changeInText(index, id);
	}
	/// ditto
	override void changeInText(size_t index, StepId id) { mixin(S_TRACE);
		if (_text) _text.changeInText(index, id);
		_name.changeInText(index, id);
	}

	/// コンテントをXMLテキストにして返す。
	const
	string toXML(XMLOption opt) { mixin(S_TRACE);
		return toNode(opt).text;
	}
	/// コンテントをXMLノードにして返す。
	const
	XNode toNode(XMLOption opt) { mixin(S_TRACE);
		auto d = this.detail;
		if ((!opt || opt.isTargetVersion("1")) && next.length == 1) { mixin(S_TRACE);
			auto doc = XNode.create("ContentsLine");
			auto node = doc.newElement(d.names[0]);
			toNodeImpl(node, d, opt, doc);
			doc.newAttr("contentId", _id);
			return doc;
		} else { mixin(S_TRACE);
			auto doc = XNode.create(d.names[0]);
			auto invalidNode = XNode.init;
			toNodeImpl(doc, d, opt, invalidNode);
			doc.newAttr("contentId", _id);
			return doc;
		}
	}
	/// enにパラメータ属性を生成する。
	const
	private void atnPut(CArg ARG, string Name, string From)(ref XNode en, in CDetail d) { mixin(S_TRACE);
		if (d.use(ARG)) { mixin(S_TRACE);
			mixin ("en.newAttr(d.attr(ARG), " ~ From ~ "(this." ~ Name ~ "));");
		}
	}
	/// enにパラメータ属性を生成する。
	/// 初期値と同値であれば生成しない。
	const
	private void atnPutD(CArg ARG, string Name, string From, alias DefValue)(ref XNode en, in CDetail d) { mixin(S_TRACE);
		if (d.use(ARG) && mixin("this." ~ Name) != DefValue) { mixin(S_TRACE);
			mixin ("en.newAttr(d.attr(ARG), " ~ From ~ "(this." ~ Name ~ "));");
		}
	}
	/// 指定されたXMLノードにインスタンスのデータを追加する。
	const
	XNode toNode(ref XNode parent, XMLOption opt) { mixin(S_TRACE);
		auto d = this.detail;
		if ((!opt || opt.isTargetVersion("1")) && next.length == 1) { mixin(S_TRACE);
			auto e = parent.newElement("ContentsLine");
			auto node = e.newElement(d.names[0]);
			toNodeImpl(node, d, opt, e);
			return e;
		} else { mixin(S_TRACE);
			auto e = parent.newElement(d.names[0]);
			auto invalidNode = XNode.init;
			toNodeImpl(e, d, opt, invalidNode);
			return e;
		}
	}
	const
	private void putNodeData(ref XNode e, in CDetail d, XMLOption opt) { mixin(S_TRACE);
		if (d.type.length) e.newAttr("type", d.type);
		if (name.length) e.newAttr("name", name);
		if (comment.length) e.newAttr("comment", comment);

		// 単純データ
		atnPut!(CArg.AREA, "area", "")(e, d);
		atnPut!(CArg.BATTLE, "battle", "")(e, d);
		atnPut!(CArg.PACKAGE, "packages", "")(e, d);
		atnPut!(CArg.FLAG, "flag", "")(e, d);
		atnPut!(CArg.STEP, "step", "")(e, d);
		atnPut!(CArg.BGM_PATH, "bgmPath", "encodePath")(e, d);
		atnPut!(CArg.BGM_CHANNEL, "bgmChannel", "")(e, d);
		atnPut!(CArg.BGM_VOLUME, "bgmVolume", "")(e, d);
		atnPut!(CArg.BGM_LOOP_COUNT, "bgmLoopCount", "")(e, d);
		atnPut!(CArg.BGM_FADE_IN, "bgmFadeIn", "")(e, d);
		atnPut!(CArg.SOUND_PATH, "soundPath", "encodePath")(e, d);
		atnPut!(CArg.SOUND_CHANNEL, "soundChannel", "")(e, d);
		atnPut!(CArg.SOUND_VOLUME, "soundVolume", "")(e, d);
		atnPut!(CArg.SOUND_LOOP_COUNT, "soundLoopCount", "")(e, d);
		atnPut!(CArg.SOUND_FADE_IN, "soundFadeIn", "")(e, d);
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

		atnPut!(CArg.FLAG_2, "flag2", "")(e, d);
		atnPut!(CArg.STEP_2, "step2", "")(e, d);
		atnPut!(CArg.LEVEL_MIN, "levelMin", "")(e, d);
		atnPut!(CArg.LEVEL_MAX, "levelMax", "")(e, d);

		atnPut!(CArg.KEY_CODE_RANGE, "keyCodeRange", "fromRange")(e, d);
		atnPut!(CArg.KEY_CODE, "keyCode", "")(e, d);

		atnPut!(CArg.INIT_VALUE, "initValue", "")(e, d);

		atnPut!(CArg.COMPARISON_4, "comparison4", "fromComparison4")(e, d);
		atnPut!(CArg.COMPARISON_3, "comparison3", "fromComparison3")(e, d);

		atnPut!(CArg.ROUND, "round", "")(e, d);

		atnPutD!(CArg.CELL_NAME, "cellName", "", "")(e, d);
		atnPutD!(CArg.CARD_GROUP, "cardGroup", "", "")(e, d);
		atnPutD!(CArg.POSITION_TYPE, "positionType", "fromCoordinateType", CoordinateType.None)(e, d);
		atnPutD!(CArg.X, "x", "", 0)(e, d);
		atnPutD!(CArg.Y, "y", "", 0)(e, d);
		atnPutD!(CArg.SIZE_TYPE, "sizeType", "fromCoordinateType", CoordinateType.None)(e, d);
		atnPutD!(CArg.WIDTH, "width", "", 0)(e, d);
		atnPutD!(CArg.HEIGHT, "height", "", 0)(e, d);
		atnPutD!(CArg.SCALE, "scale", "", -1)(e, d);
		atnPutD!(CArg.LAYER, "layer", "", -1)(e, d);

		atnPutD!(CArg.DO_ANIME, "doAnime", "fromBool", true)(e, d);
		atnPutD!(CArg.IGNORE_EFFECT_BOOSTER, "ignoreEffectBooster", "fromBool", false)(e, d);

		atnPutD!(CArg.SELECTION_COLUMNS, "selectionColumns", "", 1)(e, d);
		atnPutD!(CArg.CENTERING_X, "centeringX", "fromBool", false)(e, d);
		atnPutD!(CArg.CENTERING_Y, "centeringY", "fromBool", false)(e, d);
		atnPutD!(CArg.BOUNDARY_CHECK, "boundaryCheck", "fromBool", false)(e, d);
		atnPutD!(CArg.START_ACTION, "startAction", "", StartAction.Now)(e, d);
		atnPutD!(CArg.IGNITE, "ignite", "fromBool", false)(e, d);
		atnPutD!(CArg.HOLDING_COUPON, "holdingCoupon", "", "")(e, d);
		atnPutD!(CArg.REF_ABILITY, "refAbility", "", false)(e, d);

		atnPutD!(CArg.SELECT_CARD, "selectCard", "fromBool", false)(e, d);
		atnPutD!(CArg.SELECT_TALKER, "selectTalker", "fromBool", false)(e, d);
		atnPutD!(CArg.INVERT_RESULT, "invertResult", "fromBool", false)(e, d);

		atnPutD!(CArg.CONSUME_CARD, "consumeCard", "fromBool", true)(e, d);

		atnPutD!(CArg.OVERRIDE_CARD_SPEED, "overrideCardSpeed", "fromBool", false)(e, d);

		// 多少複雑なもの
		if (d.use(CArg.MOTIONS)) { mixin(S_TRACE);
			auto me = e.newElement("Motions");
			foreach (m; motions) { mixin(S_TRACE);
				m.toNode(me, opt);
			}
		}

		if (d.use(CArg.TEXT)) e.newElement("Text", encodeLf(text));
		if (d.use(CArg.DIALOGS)) { mixin(S_TRACE);
			auto de = e.newElement("Dialogs");
			foreach (dlg; dialogs) { mixin(S_TRACE);
				dlg.toNode(de);
			}
		}

		atnPut!(CArg.TARGET_S, "targetS", "fromTarget")(e, d);
		if (d.use(CArg.TALKER_C)) { mixin(S_TRACE);
			CardImage.toNode(e, _cardPaths, true);
		}
		atnPut!(CArg.TALKER_NC, "talkerNC", "fromTalker")(e, d);

		if (d.use(CArg.BG_IMAGES)) { mixin(S_TRACE);
			BgImage.toNode(backs, type is CType.CHANGE_BG_IMAGE, e, opt);
		}

		if (d.use(CArg.CAST_RANGE)) { mixin(S_TRACE);
			auto ce = e.newElement("CastRanges");
			foreach (c; castRange) { mixin(S_TRACE);
				ce.newElement("CastRange", fromCastRange(c));
			}
		}

		if (d.use(CArg.COUPONS)) { mixin(S_TRACE);
			auto ce = e.newElement(Coupon.XML_NAME_M);
			foreach (c; coupons) { mixin(S_TRACE);
				c.toNode(ce);
			}
		}
		if (d.use(CArg.SELECTION_METHOD)) { mixin(S_TRACE);
			if ((opt && opt.isTargetVersion("1")) || selectionMethod is SelectionMethod.Valued) { mixin(S_TRACE);
				e.newAttr("method", fromSelectionMethod(selectionMethod));
			} else { mixin(S_TRACE);
				e.newAttr("random", fromBool(selectionMethod is SelectionMethod.Random));
			}
		}

		if (d.use(CArg.KEY_CODES)) { mixin(S_TRACE);
			e.newElement("KeyCodes", encodeLf(keyCodes, false));
		}

		if (cardSpeed != -1) { mixin(S_TRACE);
			// -1は未指定。エンジンの設定に従う。あえて指定する場合の値はDefaultとなる。
			atnPut!(CArg.CARD_SPEED, "cardSpeed", "")(e, d);
		}

		// Wsn.2以降はキーコード所持分岐の探索対象を複数選択可能になった
		if (type is CType.BRANCH_KEY_CODE) { mixin(S_TRACE);
			// Wsn.1以前のために"effectCardType"も付加しておく
			auto effectCardType = EffectCardType.ALL;
			if (targetIsSkill && targetIsItem && targetIsBeast && !targetIsHand) { mixin(S_TRACE);
				effectCardType = EffectCardType.ALL;
				e.newAttr("effectCardType", fromEffectCardType(effectCardType));
			} else if (targetIsSkill && !targetIsItem && !targetIsBeast && !targetIsHand) { mixin(S_TRACE);
				effectCardType = EffectCardType.SKILL;
				e.newAttr("effectCardType", fromEffectCardType(effectCardType));
			} else if (!targetIsSkill && targetIsItem && !targetIsBeast && !targetIsHand) { mixin(S_TRACE);
				effectCardType = EffectCardType.ITEM;
				e.newAttr("effectCardType", fromEffectCardType(effectCardType));
			} else if (!targetIsSkill && !targetIsItem && targetIsBeast && !targetIsHand) { mixin(S_TRACE);
				effectCardType = EffectCardType.BEAST;
				e.newAttr("effectCardType", fromEffectCardType(effectCardType));
			} else { mixin(S_TRACE);
				atnPut!(CArg.TARGET_IS_SKILL, "targetIsSkill", "fromBool")(e, d);
				atnPut!(CArg.TARGET_IS_ITEM, "targetIsItem", "fromBool")(e, d);
				atnPut!(CArg.TARGET_IS_BEAST, "targetIsBeast", "fromBool")(e, d);
				atnPut!(CArg.TARGET_IS_HAND, "targetIsHand", "fromBool")(e, d);
			}
		} else { mixin(S_TRACE);
			atnPut!(CArg.TARGET_IS_SKILL, "targetIsSkill", "fromBool")(e, d);
			atnPut!(CArg.TARGET_IS_ITEM, "targetIsItem", "fromBool")(e, d);
			atnPut!(CArg.TARGET_IS_BEAST, "targetIsBeast", "fromBool")(e, d);
			atnPut!(CArg.TARGET_IS_HAND, "targetIsHand", "fromBool")(e, d);
		}
		// Wsn.2以降はクーポン分岐が複数クーポン指定になった
		if (d.use(CArg.COUPON_NAMES)) { mixin(S_TRACE);
			if (couponNames.length > 1) { mixin(S_TRACE);
				auto ce = e.newElement(Coupon.XML_NAME_M);
				foreach (c; couponNames) { mixin(S_TRACE);
					ce.newElement(Coupon.XML_NAME, c);
				}
			} else { mixin(S_TRACE);
				e.newAttr("coupon", couponNames.length ? couponNames[0] : "");
			}
		}
		if (d.use(CArg.COUPON_NAMES) && 1 < couponNames.length) { mixin(S_TRACE);
			// 複数クーポンが指定されている場合は必ず条件を出力
			atnPut!(CArg.MATCHING_TYPE, "matchingType", "fromMatchingType")(e, d);
		} else { mixin(S_TRACE);
			atnPutD!(CArg.MATCHING_TYPE, "matchingType", "fromMatchingType", MatchingType.And)(e, d);
		}
	}
	const
	private void toNodeImpl(ref XNode parent, CDetail d, XMLOption opt, ref XNode contentsLine) { mixin(S_TRACE);
		Rebindable!(const(Content)) c = this;
		auto e = parent;
		while (true) { mixin(S_TRACE);
			c.putNodeData(e, d, opt);
			XNode ce;
			if (contentsLine.valid && c.next.length == 1) { mixin(S_TRACE);
				assert (!opt || opt.isTargetVersion("1"));
				ce = contentsLine;
			} else if (c.next.length) { mixin(S_TRACE);
				ce = e.newElement("Contents");
			}
			if (!opt || !opt.shallow) { mixin(S_TRACE);
				if (c.next.length == 1) { mixin(S_TRACE);
					c = c.next[0];
					d = c.detail;
					e = ce.newElement(d.names[0]);
					continue;
				} else if (c.next.length) { mixin(S_TRACE);
					foreach (sub; c.next) { mixin(S_TRACE);
						sub.toNode(ce, opt);
					}
				}
			}
			break;
		}
	}
	/// XMLノード(Contents)の直下にある全てのイベントを、
	/// 後続のツリーを全て含めて生成する。
	static void createContentsFromNode(ref XNode node, in XMLInfo ver, void delegate(Content) appender) { mixin(S_TRACE);
		assert (node.name == "Contents", node.name ~ " != Contents");
		node.onTag[null] = (ref XNode en) { mixin(S_TRACE);
			auto c = createFromNode(en, ver);
			if (c) appender(c);
		};
		node.parse();
	}
	/// XMLテキストからイベントを生成する。
	static Content createFromXML(string xml, in XMLInfo ver, out string id) { mixin(S_TRACE);
		id = "";
		auto en = XNode.parse(xml);
		id = en.attr("contentId", false);
		return createFromNode(en, ver);
	}
	/// デフォルト値指定無し。
	private static bool cfnPut(CArg ARG, string Name, string To)(in XNode en, in CDetail d, ref Content c) { mixin(S_TRACE);
		if (d.use(ARG)) { mixin(S_TRACE);
			auto name = d.attr(ARG);
			if (en.hasAttr(name)) { mixin(S_TRACE);
				mixin ("c." ~ Name ~ " = " ~ To ~ "(en.attr(name, true));");
				return true;
			}
		}
		return false;
	}
	/// デフォルト値指定あり。
	private static bool cfnPutD(CArg ARG, string Name, string To, alias DefValue)(in XNode en, in CDetail d, ref Content c) { mixin(S_TRACE);
		if (d.use(ARG)) { mixin(S_TRACE);
			auto name = d.attr(ARG);
			if (en.hasAttr(name)) { mixin(S_TRACE);
				mixin ("c." ~ Name ~ " = " ~ To ~ "(en.attr(name, true));");
				return true;
			} else { mixin(S_TRACE);
				auto a = DefValue;
				mixin ("c." ~ Name ~ " = a;");
				return true;
			}
		}
		return false;
	}
	/// XMLノードからイベントを生成する。
	static Content createFromNode(ref XNode en, in XMLInfo ver, bool nextContent = true) { mixin(S_TRACE);
		if (en.name == "ContentsLine") { mixin(S_TRACE);
			Content r = null;
			Content c = null;
			en.onTag[null] = (ref XNode en) { mixin(S_TRACE);
				if (!nextContent && c) return;
				auto c2 = createFromNode(en, ver);
				if (c) { mixin(S_TRACE);
					c.add(null, c2);
				} else { mixin(S_TRACE);
					r = c2;
				}
				c = c2;
			};
			en.parse();
			return r;
		}
		auto nmap = en.name in CTYPE_MAP;
		if (!nmap) return null;
		auto t = en.attr("type", false) in *nmap;
		if (!t) return null;
		auto cType = *t;
		auto d = CONTENT_DETAILS[cType];
		string name = en.attr("name", false);
		auto r = new Content(cType, name);
		// BUG: 2.10以前のバグで\rが混在する可能性があるため置換
		r.comment = en.attr("comment", false).replace("\r\n", "\n").replace("\r", "");

		// 単純データ
		cfnPut!(CArg.AREA, "area", "to!(ulong)")(en, d, r);
		cfnPut!(CArg.BATTLE, "battle", "to!(ulong)")(en, d, r);
		cfnPut!(CArg.PACKAGE, "packages", "to!(ulong)")(en, d, r);
		cfnPut!(CArg.FLAG, "flag", "")(en, d, r);
		cfnPut!(CArg.STEP, "step", "")(en, d, r);
		cfnPut!(CArg.BGM_PATH, "bgmPath", "decodePath")(en, d, r);
		cfnPut!(CArg.BGM_CHANNEL, "bgmChannel", "to!(uint)")(en, d, r);
		cfnPut!(CArg.BGM_VOLUME, "bgmVolume", "to!(uint)")(en, d, r);
		cfnPut!(CArg.BGM_LOOP_COUNT, "bgmLoopCount", "to!(uint)")(en, d, r);
		cfnPut!(CArg.BGM_FADE_IN, "bgmFadeIn", "to!(uint)")(en, d, r);
		cfnPut!(CArg.SOUND_PATH, "soundPath", "decodePath")(en, d, r);
		cfnPut!(CArg.SOUND_CHANNEL, "soundChannel", "to!(uint)")(en, d, r);
		cfnPut!(CArg.SOUND_VOLUME, "soundVolume", "to!(uint)")(en, d, r);
		cfnPut!(CArg.SOUND_LOOP_COUNT, "soundLoopCount", "to!(uint)")(en, d, r);
		cfnPut!(CArg.SOUND_FADE_IN, "soundFadeIn", "to!(uint)")(en, d, r);
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

		cfnPut!(CArg.FLAG_2, "flag2", "")(en, d, r);
		cfnPut!(CArg.STEP_2, "step2", "")(en, d, r);
		cfnPut!(CArg.LEVEL_MIN, "levelMin", "to!(int)")(en, d, r);
		cfnPut!(CArg.LEVEL_MAX, "levelMax", "to!(int)")(en, d, r);

		cfnPut!(CArg.KEY_CODE_RANGE, "keyCodeRange", "toRange")(en, d, r);
		cfnPut!(CArg.KEY_CODE, "keyCode", "")(en, d, r);

		cfnPut!(CArg.INIT_VALUE, "initValue", "to!(int)")(en, d, r);

		cfnPut!(CArg.COMPARISON_4, "comparison4", "toComparison4")(en, d, r);
		cfnPut!(CArg.COMPARISON_3, "comparison3", "toComparison3")(en, d, r);

		cfnPut!(CArg.ROUND, "round", "to!(uint)")(en, d, r);

		cfnPutD!(CArg.CELL_NAME, "cellName", "", "")(en, d, r);
		cfnPutD!(CArg.CARD_GROUP, "cardGroup", "", "")(en, d, r);
		cfnPutD!(CArg.POSITION_TYPE, "positionType", "toCoordinateType", CoordinateType.None)(en, d, r);
		cfnPutD!(CArg.X, "x", "to!(int)", 0)(en, d, r);
		cfnPutD!(CArg.Y, "y", "to!(int)", 0)(en, d, r);
		cfnPutD!(CArg.SIZE_TYPE, "sizeType", "toCoordinateType", CoordinateType.None)(en, d, r);
		cfnPutD!(CArg.WIDTH, "width", "to!(int)", 0)(en, d, r);
		cfnPutD!(CArg.HEIGHT, "height", "to!(int)", 0)(en, d, r);
		cfnPutD!(CArg.SCALE, "scale", "to!(int)", -1)(en, d, r);
		cfnPutD!(CArg.LAYER, "layer", "to!(int)", -1)(en, d, r);

		cfnPutD!(CArg.DO_ANIME, "doAnime", "parseBool", true)(en, d, r);
		cfnPutD!(CArg.IGNORE_EFFECT_BOOSTER, "ignoreEffectBooster", "parseBool", false)(en, d, r);

		cfnPutD!(CArg.SELECTION_COLUMNS, "selectionColumns", "to!(uint)", 1)(en, d, r);
		cfnPutD!(CArg.CENTERING_X, "centeringX", "parseBool", false)(en, d, r);
		cfnPutD!(CArg.CENTERING_Y, "centeringY", "parseBool", false)(en, d, r);
		cfnPutD!(CArg.BOUNDARY_CHECK, "boundaryCheck", "parseBool", false)(en, d, r);
		cfnPutD!(CArg.IGNITE, "ignite", "parseBool", false)(en, d, r);
		cfnPutD!(CArg.HOLDING_COUPON, "holdingCoupon", "", "")(en, d, r);
		cfnPutD!(CArg.REF_ABILITY, "refAbility", "parseBool", false)(en, d, r);

		cfnPutD!(CArg.SELECT_CARD, "selectCard", "parseBool", false)(en, d, r);
		cfnPutD!(CArg.SELECT_TALKER, "selectTalker", "parseBool", false)(en, d, r);
		cfnPutD!(CArg.INVERT_RESULT, "invertResult", "parseBool", false)(en, d, r);

		cfnPutD!(CArg.CONSUME_CARD, "consumeCard", "parseBool", true)(en, d, r);

		cfnPutD!(CArg.OVERRIDE_CARD_SPEED, "overrideCardSpeed", "parseBool", false)(en, d, r);

		// CardWirthではラウンドイベントで加入したメンバは次ラウンドから
		// 行動を開始するが、CardWirthPy 1では即時に行動していた。
		// その挙動を前提にしたWsn.1シナリオが作られている可能性があるので、
		// Wsn.2で`startaction`属性を設けて挙動を制御可能にする。
		//  * Wsnシナリオで`startaction`が無い場合(Wsn.1以前)は、
		//    `startaction="Now"`として扱う。
		//  * クラシックなシナリオを変換した時は`startaction="NextRound"`とする。
		// ここはXMLデータのパースなので、初期値を`Now`しておく。
		cfnPutD!(CArg.START_ACTION, "startAction", "toStartAction", StartAction.Now)(en, d, r);

		// 多少複雑なもの
		if (d.use(CArg.TRANSITION)) { mixin(S_TRACE);
			// 歴史的経緯から、transitionは値が存在しない可能性がある
			auto s = en.attr(d.attr(CArg.TRANSITION), false);
			if (s.length) r.transition = toTransition(s);
		}
		if (d.use(CArg.TRANSITION_SPEED)) { mixin(S_TRACE);
			auto s = en.attr(d.attr(CArg.TRANSITION_SPEED), false);
			if (s.length) r.transitionSpeed = to!(int)(s);
		}
		if (d.use(CArg.MOTIONS)) { mixin(S_TRACE);
			en.onTag["Motions"] = (ref XNode node) { mixin(S_TRACE);
				Motion[] motions;
				node.onTag["Motion"] = (ref XNode node) { mixin(S_TRACE);
					motions ~= Motion.createFromNode(node, ver);
				};
				node.parse();
				r.motions = motions;
			};
		}
		if (d.use(CArg.TEXT)) { mixin(S_TRACE);
			en.onTag["Text"] = (ref XNode node) {r.text = decodeLf2(node.value);};
		}
		if (d.use(CArg.DIALOGS)) { mixin(S_TRACE);
			en.onTag["Dialogs"] = (ref XNode node) { mixin(S_TRACE);
				SDialog[] dlgs;
				node.onTag["Dialog"] = (ref XNode node) { mixin(S_TRACE);
					dlgs ~= SDialog.createFromNode(node, ver);
				};
				node.parse();
				if (dlgs.length == 0) dlgs ~= new SDialog;
				r.dialogs = dlgs;
			};
		}
		if (d.use(CArg.CARD_SPEED)) { mixin(S_TRACE);
			// Defaultまたは0～10
			auto attrName = d.attr(CArg.CARD_SPEED);
			if (en.hasAttr(attrName)) { mixin(S_TRACE);
				if (en.attr!string(attrName, true) == "Default") { mixin(S_TRACE);
					r.cardSpeed = -1;
				} else { mixin(S_TRACE);
					r.cardSpeed = en.attr!int(attrName, true);
				}
			}
		}

		Target loadTarget(bool canSleep = true) { mixin(S_TRACE);
			auto targ = toTarget(en.attr("targetm", true));
			if (!canSleep && targ.sleep) targ = Target(targ.m, false);
			return targ;
		}
		if (d.use(CArg.TARGET_S)) r.targetS = loadTarget(true);
		if (d.use(CArg.TALKER_NC)) { mixin(S_TRACE);
			auto targetm = en.attr("targetm", false, "");
			foreach (talker; [Talker.SELECTED, Talker.UNSELECTED, Talker.RANDOM, Talker.VALUED]) { mixin(S_TRACE);
				if (targetm == fromTalker(talker)) { mixin(S_TRACE);
					r.talkerNC = talker;
					break;
				}
			}
		}
		CardImage[] cardPaths;
		if (d.use(CArg.TALKER_C)) { mixin(S_TRACE);
			CardImage.setOnTag(en, cardPaths, true);
		}

		if (d.use(CArg.BG_IMAGES)) { mixin(S_TRACE);
			en.onTag["BgImages"] = (ref XNode node) { mixin(S_TRACE);
				r.backs = BgImage.bgImagesFromNode(node, cType is CType.CHANGE_BG_IMAGE, ver);
			};
		}

		if (d.use(CArg.CAST_RANGE)) { mixin(S_TRACE);
			en.onTag["CastRanges"] = (ref XNode node) { mixin(S_TRACE);
				CastRange[] castRange;
				node.onTag["CastRange"] = (ref XNode node) { mixin(S_TRACE);
					castRange ~= toCastRange(node.value);
				};
				node.parse();
				r.castRange = castRange;
			};
		}

		if (d.use(CArg.COUPONS)) { mixin(S_TRACE);
			en.onTag[Coupon.XML_NAME_M] = (ref XNode node) { mixin(S_TRACE);
				Coupon[] coupons;
				bool[string] names;
				node.onTag[Coupon.XML_NAME] = (ref XNode node) { mixin(S_TRACE);
					auto coupon = Coupon.fromNode(node, ver);
					if (coupon && coupon.name !in names) { mixin(S_TRACE);
						names[coupon.name] = true;
						coupons ~= coupon;
					}
				};
				node.parse();
				r.coupons = coupons;
			};
		}

		if (d.use(CArg.SELECTION_METHOD)) { mixin(S_TRACE);
			if (en.hasAttr("method")) { mixin(S_TRACE);
				r.selectionMethod = toSelectionMethod(en.attr("method", false, fromSelectionMethod(SelectionMethod.Manual)));
			} else { mixin(S_TRACE);
				r.selectionMethod = parseBool(en.attr("random", false, fromBool(false))) ? SelectionMethod.Random : SelectionMethod.Manual;
			}
		}

		if (d.use(CArg.KEY_CODES)) { mixin(S_TRACE);
			en.onTag["KeyCodes"] = (ref XNode n) { mixin(S_TRACE);
				r.keyCodes = decodeLf(n.value, true);
			};
		}

		bool hasTarget = false;
		hasTarget |= cfnPut!(CArg.TARGET_IS_SKILL, "targetIsSkill", "parseBool")(en, d, r);
		hasTarget |= cfnPut!(CArg.TARGET_IS_ITEM, "targetIsItem", "parseBool")(en, d, r);
		hasTarget |= cfnPut!(CArg.TARGET_IS_BEAST, "targetIsBeast", "parseBool")(en, d, r);
		hasTarget |= cfnPut!(CArg.TARGET_IS_HAND, "targetIsHand", "parseBool")(en, d, r);
		if (cType is CType.BRANCH_KEY_CODE) { mixin(S_TRACE);
			// Wsn.2以降はキーコード所持分岐の探索対象を複数選択可能になったが、
			// 該当するパラメータが無い場合はWsn.1以前と仮定して読み込む
			if (!hasTarget && en.hasAttr("effectCardType")) { mixin(S_TRACE);
				auto effectCardType = toEffectCardType(en.attr("effectCardType", true));
				final switch (effectCardType) {
				case EffectCardType.ALL:
					r.targetIsSkill = true;
					r.targetIsItem = true;
					r.targetIsBeast = true;
					r.targetIsHand = false;
					break;
				case EffectCardType.SKILL:
					r.targetIsSkill = true;
					r.targetIsItem = false;
					r.targetIsBeast = false;
					r.targetIsHand = false;
					break;
				case EffectCardType.ITEM:
					r.targetIsSkill = false;
					r.targetIsItem = true;
					r.targetIsBeast = false;
					r.targetIsHand = false;
					break;
				case EffectCardType.BEAST:
					r.targetIsSkill = false;
					r.targetIsItem = false;
					r.targetIsBeast = true;
					r.targetIsHand = false;
					break;
				case EffectCardType.HAND:
					r.targetIsSkill = false;
					r.targetIsItem = false;
					r.targetIsBeast = false;
					r.targetIsHand = true;
					break;
				}
			}
		}
		// Wsn.2以降はクーポン分岐が複数クーポン指定になった(Wsn.2)
		if (d.use(CArg.COUPON_NAMES)) { mixin(S_TRACE);
			bool[string] names;
			if (en.hasAttr("coupon") && en.attr("coupon", true) != "") { mixin(S_TRACE);
				auto coupon = en.attr("coupon", true);
				r.couponNames = [coupon];
				names[coupon] = true;
			}
			en.onTag[Coupon.XML_NAME_M] = (ref XNode node) { mixin(S_TRACE);
				string[] couponNames;
				node.onTag[Coupon.XML_NAME] = (ref XNode node) { mixin(S_TRACE);
					if (node.value !in names) { mixin(S_TRACE);
						names[node.value] = true;
						couponNames ~= node.value;
					}
				};
				node.parse();
				r.couponNames = r.couponNames ~ couponNames;
			};
		}
		cfnPut!(CArg.MATCHING_TYPE, "matchingType", "toMatchingType")(en, d, r);

		if (d.owner && nextContent) { mixin(S_TRACE);
			en.onTag["Contents"] = (ref XNode node) { mixin(S_TRACE);
				Content.createContentsFromNode(node, ver, (c) => r.add(null, c));
			};
		}

		en.parse();

		// パース後にpathsの中身が入るのでここで設定
		if (d.use(CArg.TALKER_C)) { mixin(S_TRACE);
			r.cardPaths = cardPaths;
		}
		return r;
	}
}

/// キーコード発火条件とキーコード本体の組み合わせ。
private struct FKeyCodeU {
	KeyCodeUser user; /// キーコード。
	FKCKind kind; /// 発火条件。
	const
	bool opEquals(in FKeyCode kc) { mixin(S_TRACE);
		return user.keyCode == kc.keyCode && kind == kc.kind;
	}
}

/// イベントツリー。発火条件と実行するイベント群を持つ。
public class EventTree : IKeyCodeUser {
private:
	string _id;

	EventTreeOwner _owner;

	/// 開始条件群
	bool _enter = false;
	bool _escape = false;
	bool _lose = false;
	bool _everyRound = 0;
	bool _round0 = false;
	uint[] _rounds;

	FKeyCodeU[] _keyCodes;
	MatchingType _keyCodeMatchingType = MatchingType.Or;
	Content[string] _startNames;

	Content[] _starts;
	UseCounter _uc;
	SUseCounter _suc;
	void delegate() _change = null;

	this () { mixin(S_TRACE);
		_suc = new SUseCounter;
		static ulong idCount = 0;
		_id = .objectIDValue(this) ~ "-" ~ to!string(idCount);
		idCount++;
	}
public:
	/// イベントツリー名を指定してインスタンスを生成。
	this (string name) { mixin(S_TRACE);
		this (new Content(CType.START, name));
	}
	/// スタートコンテントを指定してインスタンスを生成。
	/// startがすでにイベントツリーに所属している場合、
	/// コピーが生成される。
	this (Content start) in { mixin(S_TRACE);
		assert (start.type == CType.START);
	} body { mixin(S_TRACE);
		this ();
		if (start.tree) { mixin(S_TRACE);
			start = start.dup;
		}
		add(start);
	}
	/// スタートコンテント群を指定してインスタンスを生成。
	this (Content[] starts) in { mixin(S_TRACE);
		foreach (c; starts) { mixin(S_TRACE);
			assert (c.type is CType.START);
		}
	} body { mixin(S_TRACE);
		this ();
		_starts = starts;
		foreach (s; _starts) { mixin(S_TRACE);
			if (s._tree) s._tree._startNames.remove(s.name);
			s._tree = this;
			s.setSUseCounter(_suc);
		}
		foreach (start; starts) _startNames[start.name] = start;
	}

	/// イベントツリーのID。
	@property
	const
	string eventTreeId() { return _id; }

	/// このツリーの所有者。
	@property
	inout
	inout(EventTreeOwner) owner() { return _owner; }

	/// ディープコピーを作成する。
	@property
	const
	EventTree dup() { mixin(S_TRACE);
		auto copy = new EventTree;
		copy._id = _id;
		copy.enter = fireEnter;
		copy.escape = fireEscape;
		copy.lose = fireLose;
		copy.everyRound = fireEveryRound;
		copy.round0 = fireRound0;
		copy.rounds = rounds.dup;
		copy.keyCodes = keyCodes.dup;
		copy.keyCodeMatchingType = keyCodeMatchingType;
		foreach (s; starts) { mixin(S_TRACE);
			copy.add(s.dup);
		}
		return copy;
	}
	/// baseの発火条件を現在の発火条件に上書きする。
	void copyIgnitions(in EventTree base) { mixin(S_TRACE);
		enter = base.fireEnter;
		escape = base.fireEscape;
		lose = base.fireLose;
		everyRound = base.fireEveryRound;
		round0 = base.fireRound0;
		rounds = base.rounds.dup;
		keyCodes = base.keyCodes.dup;
		keyCodeMatchingType = base.keyCodeMatchingType;
	}

	override
	bool opEquals(Object o) { mixin(S_TRACE);
		auto c = cast(const(EventTree)) o;
		if (!c) return false;
		return fireEnter == c.fireEnter
			&& fireEscape == c.fireEscape
			&& fireLose == c.fireLose
			&& fireEveryRound == c.fireEveryRound
			&& fireRound0 == c.fireRound0
			&& rounds == c.rounds
			&& keyCodes == c.keyCodes
			&& keyCodeMatchingType == c.keyCodeMatchingType
			&& starts == c.starts;
	}

	@property
	override string cwxPath(bool id) { mixin(S_TRACE);
		return _owner ? cpjoin(_owner, "event", .cCountUntil!("a is b")(_owner.trees, this), id) : "";
	}
	CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		if (cate == "") { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= _starts.length) return null;
			return _starts[index].findCWXPath(cpbottom(path));
		}
		return null;
	}
	@property
	inout
	inout(CWXPath)[] cwxChilds() { mixin(S_TRACE);
		inout(CWXPath)[] r;
		foreach (a; starts) r ~= a;
		return r;
	}
	@property
	CWXPath cwxParent() {return _owner;}

	/// 変更ハンドラを登録する。
	@property
	void changeHandler(void delegate() change) { mixin(S_TRACE);
		foreach (s; _starts) { mixin(S_TRACE);
			s.changeHandler = change;
		}
		_change = change;
	}
	/// 変更ハンドラを返す。
	@property
	protected void delegate() changeHandler() { mixin(S_TRACE);
		return _change;
	}
	/// 変更を通知する。
	protected void changed() { mixin(S_TRACE);
		if (_change) _change();
	}

	override bool change(KeyCodeId id) { return true; }

	/// スタートコンテントのみが含まれている場合はtrue。
	@property
	const
	bool isEmpty() { mixin(S_TRACE);
		foreach (s; _starts) { mixin(S_TRACE);
			if (s.next.length) return false;
		}
		return true;
	}

	/// イベントツリー名。
	/// 最初のスタートコンテントのテキストと常に一致する。
	@property
	void name(string name) { mixin(S_TRACE);
		if (_starts[0].name != name) { mixin(S_TRACE);
			changed();
			_startNames.remove(_starts[0].name);
			name = .createNewName(name, (string name) { mixin(S_TRACE);
				return name !in _startNames;
			});
			_starts[0].setNameImpl(name, false);
			_startNames[name] = _starts[0];
		}
	}
	/// ditto
	@property
	const
	string name() { mixin(S_TRACE);
		return _starts[0].name;
	}

	/// スタートコンテントのインデックスを交換。
	void swapStart(size_t index1, size_t index2) { mixin(S_TRACE);
		if (index1 != index2) changed();
		auto temp = _starts[index1];
		_starts[index1] = _starts[index2];
		_starts[index2] = temp;
	}
	/// キーコードのインデックスを交換。
	void swapKeyCode(size_t index1, size_t index2) { mixin(S_TRACE);
		if (index1 != index2) changed();
		auto temp = _keyCodes[index1];
		_keyCodes[index1] = _keyCodes[index2];
		_keyCodes[index2] = temp;
	}

	/// スタートコンテントを追加する。
	void add(Content evt) in { mixin(S_TRACE);
		assert (evt.type is CType.START);
	} body { mixin(S_TRACE);
		if (_uc !is null) { mixin(S_TRACE);
			evt.setUseCounter(_uc);
		}
		if (evt._tree) evt._tree._startNames.remove(evt.name);
		evt.setSUseCounter(_suc);
		evt._tree = this;
		evt.changeHandler = changeHandler;
		_starts ~= evt;
		_startNames[evt.name] = evt;
		changed();
	}
	/// ditto
	void insert(size_t index, Content evt) in { mixin(S_TRACE);
		assert (evt.type is CType.START);
	} body { mixin(S_TRACE);
		if (_uc !is null) { mixin(S_TRACE);
			evt.setUseCounter(_uc);
		}
		if (evt._tree) evt._tree._startNames.remove(evt.name);
		evt.setSUseCounter(_suc);
		evt._tree = this;
		evt.changeHandler = changeHandler;
		_starts = _starts[0u .. index] ~ evt ~ _starts[index .. $];
		_startNames[evt.name] = evt;
		changed();
	}
	const
	string[] startNames() { return _startNames.keys(); }
	/// スタートコンテントを除外。
	void remove(size_t index) in { mixin(S_TRACE);
		assert (_starts.length > 1);
	} body { mixin(S_TRACE);
		removeProc(_starts[index]);
		_starts = _starts[0 .. index] ~ _starts[index + 1 .. $];
	}
	private void removeProc(Content c) { mixin(S_TRACE);
		if (_uc !is null) { mixin(S_TRACE);
			c.removeUseCounter();
		}
		c.removeSUseCounter();
		c._tree = null;
		c.changeHandler = null;
		_startNames.remove(c.name);
		changed();
	}
	/// ditto
	void remove(Content start) in { mixin(S_TRACE);
		assert (start.type is CType.START);
	} body { mixin(S_TRACE);
		foreach (i, s; _starts) { mixin(S_TRACE);
			if (s is start) { mixin(S_TRACE);
				remove(i);
				return;
			}
		}
		assert (0);
	}
	/// スタートコンテント群。
	@property
	inout
	inout(Content)[] starts() out (r) { mixin(S_TRACE);
		foreach (c; r) { mixin(S_TRACE);
			assert (c.type is CType.START);
		}
	} body { mixin(S_TRACE);
		return _starts;
	}
	/// ditto
	@property
	void starts(Content[] starts) { mixin(S_TRACE);
		changed();
		foreach (s; _starts) { mixin(S_TRACE);
			removeProc(s);
		}
		_starts = [];
		foreach (s; starts) { mixin(S_TRACE);
			add(s);
		}
	}
	/// 指定された名前のスタートコンテントがあるか。
	const
	bool hasStart(string name) { mixin(S_TRACE);
		return (name in _startNames) !is null;
	}
	/// 指定された名前のスタートコンテントを探して返す。
	inout
	inout(Content) start(string name) { mixin(S_TRACE);
		auto p = name in _startNames;
		return p ? *p : null;
	}
	/// 属するエリア等からの相対パスを返す。
	@property
	size_t[] areaPath() { mixin(S_TRACE);
		if (_owner) { mixin(S_TRACE);
			return _owner.areaPath ~ cast(size_t) .cCountUntil!("a is b")(_owner.trees, this);
		} else { mixin(S_TRACE);
			return [];
		}
	}
	/// パスを辿ってコンテントを返す。
	Content fromPath(size_t[] path) { mixin(S_TRACE);
		if (!path.length) return null;
		if (path.length == 1) return starts[path[0]];
		return starts[path[0]].fromPath(path[1 .. $]);
	}

	/// 指定されたインデックスのキーコードを差し替える。
	void setKeyCode(size_t index, FKeyCode keyCode) { mixin(S_TRACE);
		if (_keyCodes[index] != keyCode) { mixin(S_TRACE);
			changed();
			_keyCodes[index].user.keyCode = keyCode.keyCode;
			_keyCodes[index].kind = keyCode.kind;
		}
	}

	/// 使用回数カウンタ。
	@property
	UseCounter useCounter() {return _uc;}
	/// 使用回数カウンタを設定する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		foreach (s; starts) { mixin(S_TRACE);
			s.setUseCounter(uc);
		}
		foreach (kc; _keyCodes) { mixin(S_TRACE);
			kc.user.setUseCounter(uc);
		}
		_uc = uc;
	}
	/// 使用回数カウンタを外す。
	void removeUseCounter() { mixin(S_TRACE);
		foreach (s; starts) { mixin(S_TRACE);
			s.removeUseCounter();
		}
		foreach (kc; _keyCodes) { mixin(S_TRACE);
			kc.user.removeUseCounter();
		}
		_uc = null;
	}

	/// スタートの使用回数カウンタ。
	@property
	SUseCounter startUseCounter() {return _suc;}

	/// エリア到着時・クリック時・パッケージ開始時・勝利・死亡時に発火するか。
	@property
	void enter(bool enter) { mixin(S_TRACE);
		if (_enter != enter) changed();
		_enter = enter;
	}
	/// ditto
	@property
	const
	bool fireEnter() { mixin(S_TRACE);
		return _enter;
	}

	/// 逃走時に発火するか。
	@property
	void escape(bool escape) { mixin(S_TRACE);
		if (_escape != escape) changed();
		_escape = escape;
	}
	/// ditto
	@property
	const
	bool fireEscape() { mixin(S_TRACE);
		return _escape;
	}

	/// 敗北時に発火するか。
	@property
	void lose(bool lose) { mixin(S_TRACE);
		if (_lose != lose) changed();
		_lose = lose;
	}
	/// ditto
	@property
	const
	bool fireLose() { mixin(S_TRACE);
		return _lose;
	}

	/// 毎ラウンドに発火するか。
	@property
	void everyRound(bool everyRound) { mixin(S_TRACE);
		if (_everyRound != everyRound) changed();
		_everyRound = everyRound;
	}
	/// ditto
	@property
	const
	bool fireEveryRound() { mixin(S_TRACE);
		return _everyRound;
	}

	/// 戦闘開始時に発火するか。
	@property
	void round0(bool round0) { mixin(S_TRACE);
		if (_round0 != round0) changed();
		_round0 = round0;
	}
	/// ditto
	@property
	const
	bool fireRound0() { mixin(S_TRACE);
		return _round0;
	}

	/// 発火ラウンドを追加。追加できた場合はtrueを返す。
	bool addRound(uint round) { mixin(S_TRACE);
		if (!fireRound(round)) { mixin(S_TRACE);
			changed();
			_rounds ~= round;
			return true;
		}
		return false;
	}
	/// 発火ラウンド群を追加。追加できた発火ラウンドの配列を返す。
	uint[] addRounds(uint[] rounds) { mixin(S_TRACE);
		auto s = new HashSet!(uint);
		foreach (r; _rounds) s.add(r);
		uint[] rounds2;
		foreach (r; rounds) { mixin(S_TRACE);
			if (s.contains(r)) continue;
			s.add(r);
			rounds2 ~= r;
		}
		if (!rounds2.length) return rounds2;
		rounds = s.toArray();
		std.algorithm.sort(rounds);
		changed();
		_rounds = rounds;
		return rounds2;
	}
	/// ラウンド発火条件をソートする。
	void sortRounds() { mixin(S_TRACE);
		if (!cwx.utils.isSorted(_rounds)) { mixin(S_TRACE);
			changed();
			std.algorithm.sort(_rounds);
		}
	}
	/// 指定されたラウンドで発火するか。
	const
	bool fireRound(uint round) { mixin(S_TRACE);
		foreach (r; _rounds) { mixin(S_TRACE);
			if (r == round) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
	}
	/// 発火ラウンド群。
	@property
	uint[] rounds() { mixin(S_TRACE);
		return _rounds;
	}
	/// ditto
	@property
	const
	const(uint)[] rounds() { mixin(S_TRACE);
		return _rounds;
	}
	/// ditto
	@property
	void rounds(uint[] rounds) { mixin(S_TRACE);
		if (_rounds != rounds) changed();
		_rounds = rounds;
	}
	/// 発火ラウンドを除去。
	void removeRound(uint round) { mixin(S_TRACE);
		foreach (i, r; _rounds) { mixin(S_TRACE);
			if (r == round) { mixin(S_TRACE);
				changed();
				_rounds = _rounds[0 .. i] ~ _rounds[i + 1 .. $];
				return;
			}
		}
		assert (0);
	}
	/// ditto
	void removeRoundsAll() { mixin(S_TRACE);
		changed();
		_rounds.length = 0;
	}

	/// 発火キーコードを追加。
	/// Returns: 追加できた場合はtrue。
	bool addKeyCode(FKeyCode keyCode, ptrdiff_t insertIndex = -1) { mixin(S_TRACE);
		if (!fireKeyCode(keyCode)) { mixin(S_TRACE);
			changed();
			auto user = new KeyCodeUser(this);
			if (useCounter) user.setUseCounter = useCounter;
			user.keyCode = keyCode.keyCode;
			if (insertIndex < 0 || _keyCodes.length <= insertIndex) { mixin(S_TRACE);
				_keyCodes ~= FKeyCodeU(user, keyCode.kind);
			} else { mixin(S_TRACE);
				_keyCodes.insertInPlace(insertIndex, FKeyCodeU(user, keyCode.kind));
			}
			return true;
		}
		return false;
	}
	/// 発火キーコード群を追加。追加できた発火キーコードの配列を返す。
	FKeyCode[] addKeyCodes(in FKeyCode[] keyCodes, ptrdiff_t insertIndex = -1) { mixin(S_TRACE);
		bool[FKeyCode] eKeyCodes;
		foreach (keyCode; this.keyCodes) eKeyCodes[keyCode] = true;
		FKeyCode[] keyCodes2;
		foreach (keyCode; keyCodes) { mixin(S_TRACE);
			if (keyCode in eKeyCodes) continue;
			if (keyCode.keyCode == "") continue;
			keyCodes2 ~= keyCode;
		}
		if (!keyCodes2.length) return [];

		changed();
		FKeyCodeU[] users;
		foreach (keyCode; keyCodes2) {
			auto user = new KeyCodeUser(this);
			if (useCounter) user.setUseCounter = useCounter;
			user.keyCode = keyCode.keyCode;
			users ~= FKeyCodeU(user, keyCode.kind);
		}
		if (insertIndex < 0 || _keyCodes.length <= insertIndex) { mixin(S_TRACE);
			_keyCodes ~= users;
		} else { mixin(S_TRACE);
			_keyCodes.insertInPlace(insertIndex, users);
		}
		return keyCodes2;
	}
	/// 指定されたキーコードで発火するか。
	const
	bool fireKeyCode(in FKeyCode keyCode) { mixin(S_TRACE);
		foreach (kc; _keyCodes) { mixin(S_TRACE);
			if (kc == keyCode) { mixin(S_TRACE);
				return true;
			}
		}
		return false;
	}
	/// 発火キーコード群。
	@property
	const
	FKeyCode[] keyCodes() { mixin(S_TRACE);
		auto r = new FKeyCode[_keyCodes.length];
		foreach (i, ref kc; r) { mixin(S_TRACE);
			kc = FKeyCode(_keyCodes[i].user.keyCode, _keyCodes[i].kind);
		}
		return r;
	}
	/// ditto
	@property
	void keyCodes(in FKeyCode[] keyCodes) { mixin(S_TRACE);
		if (this.keyCodes != keyCodes) { mixin(S_TRACE);
			changed();
			foreach (c; _keyCodes) { mixin(S_TRACE);
				c.user.removeUseCounter();
			}
			_keyCodes.length = keyCodes.length;
			foreach (i, ref c; _keyCodes) { mixin(S_TRACE);
				c = FKeyCodeU(new KeyCodeUser(this), keyCodes[i].kind);
				c.user.keyCode = keyCodes[i].keyCode;
				if (useCounter) { mixin(S_TRACE);
					c.user.setUseCounter = useCounter;
				}
			}
		}
	}
	/// 発火キーコードを除去。
	void removeKeyCode(in FKeyCode keyCode) { mixin(S_TRACE);
		foreach (i, kc; _keyCodes) { mixin(S_TRACE);
			if (kc == keyCode) { mixin(S_TRACE);
				changed();
				kc.user.removeUseCounter();
				_keyCodes = _keyCodes[0 .. i] ~ _keyCodes[i + 1 .. $];
				return;
			}
		}
		assert (0);
	}
	/// ditto
	void removeKeyCodesAll() { mixin(S_TRACE);
		changed();
		foreach (kc; _keyCodes) { mixin(S_TRACE);
			kc.user.removeUseCounter();
		}
		_keyCodes.length = 0;
	}
	/// キーコード判定条件。
	@property
	void keyCodeMatchingType(MatchingType type) { mixin(S_TRACE);
		if (_keyCodeMatchingType != type) changed();
		_keyCodeMatchingType = type;
	}
	/// ditto
	@property
	const
	MatchingType keyCodeMatchingType() { mixin(S_TRACE);
		return _keyCodeMatchingType;
	}

	/// イベントツリーをXMLテキストにする。
	const
	string toXML(XMLOption opt) { mixin(S_TRACE);
		return toNode(opt).text;
	}
	/// イベントツリーをXMLノードにする。
	const
	XNode toNode(XMLOption opt) { mixin(S_TRACE);
		auto doc = XNode.create("Event");
		toNodeImpl(doc, opt);
		return doc;
	}
	/// 指定されたXMLノード(Events)にこのインスタンスのデータを追加する。
	const
	void toNode(ref XNode node, XMLOption opt) { mixin(S_TRACE);
		assert (node.name == "Events", node.name ~ " != Events");
		auto e = node.newElement("Event");
		toNodeImpl(e, opt);
	}
	const
	private void toNodeImpl(ref XNode node, XMLOption opt) { mixin(S_TRACE);
		assert (node.name == "Event", node.name ~ " != Event");
		if (_enter || _escape || _lose || _everyRound || _round0 || _rounds.length > 0 || _keyCodes.length > 0) { mixin(S_TRACE);
			auto ig = node.newElement("Ignitions");
			if (MatchingType.Or !is keyCodeMatchingType) { mixin(S_TRACE);
				ig.newAttr("keyCodeMatchingType", fromMatchingType(keyCodeMatchingType));
			}
			string[] nums;
			if (_enter) nums ~= "1";
			if (_escape) nums ~= "2";
			if (_lose) nums ~= "3";
			if (_everyRound) nums ~= "4";
			if (_round0) nums ~= "5";
			foreach (r; _rounds) { mixin(S_TRACE);
				nums ~= ("-" ~ to!(string)(r));
			}
			ig.newElement("Number", encodeLf(nums, false));
			string[] keyCodes;
			foreach (u; _keyCodes) { mixin(S_TRACE);
				keyCodes ~= opt.sys.convFireKeyCode(FKeyCode(u.user.keyCode, u.kind));
			}
			ig.newElement("KeyCodes", encodeLf(keyCodes));
		}
		auto c = node.newElement("Contents");
		foreach (st; _starts) { mixin(S_TRACE);
			st.toNode(c, opt);
		}
	}

	/// XMLテキストからインスタンスを生成。
	static EventTree fromXML(string xml, in XMLInfo ver) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			scope doc = XNode.parse(xml);
			if (doc.name == "Event") { mixin(S_TRACE);
				return createFromNode(doc, ver);
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
		return null;
	}
	/// XMLノードからインスタンスを生成。
	/// スタートコンテントが一つも無かった場合はnullを返す。
	static EventTree createFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		assert (node.name == "Event", node.name ~ " != Event");
		auto r = new EventTree;
		node.onTag["Contents"] = (ref XNode node) { mixin(S_TRACE);
			Content.createContentsFromNode(node, ver, (c) => r.add(c));
		};
		node.onTag["Ignitions"] = (ref XNode node) { mixin(S_TRACE);
			r.keyCodeMatchingType = toMatchingType(node.attr("keyCodeMatchingType", false, fromMatchingType(r.keyCodeMatchingType)));
			node.onTag["Number"] = (ref XNode n) { mixin(S_TRACE);
				foreach (v; decodeLf(n.value)) { mixin(S_TRACE);
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
					case "4":
						r._everyRound = true;
						break;
					case "5":
						r._round0 = true;
						break;
					default:
						if (v.length > 1 && v[0] == '-') { mixin(S_TRACE);
							r._rounds ~= to!(int)(v[1 .. $]);
						}
						break;
					}
				}
			};
			node.onTag["KeyCodes"] = (ref XNode n) { mixin(S_TRACE);
				auto val = n.value;
				if (val.length > 0) { mixin(S_TRACE);
					foreach (kc; decodeLf(val)) { mixin(S_TRACE);
						auto kind = ver.sys.fireKeyCodeKindRef(kc);
						r.addKeyCode(FKeyCode(kc, kind));
					}
				}
			};
			node.parse();
		};
		node.parse();
		return r.starts.length > 0 ? r : null;
	}

	private static XNode fireToNode(string name, string att = null, string value = null) { mixin(S_TRACE);
		auto e = XNode.create(name);
		if (att && value) { mixin(S_TRACE);
			e.newAttr(att, value);
		}
		return e;
	}
	/// 「到着時発火」をXMLノード化する。
	static XNode enterToNode() {return fireToNode("IgniteWithEnter");}
	/// 「逃走時発火」をXMLノード化する。
	static XNode escapeToNode() {return fireToNode("IgniteWithRunAway");}
	/// 「敗北時発火」をXMLノード化する。
	static XNode loseToNode() {return fireToNode("IgniteWithLose");}
	/// 「毎ラウンド発火」をXMLノード化する。
	static XNode everyRoundToNode() {return fireToNode("IgniteWithEveryRound");}
	/// 「戦闘開始時発火」をXMLノード化する。
	static XNode round0ToNode() {return fireToNode("IgniteWithRound0");}
	/// 「発火ラウンド」をXMLノード化する。
	static XNode roundToNode(uint round) { mixin(S_TRACE);
		return roundsToNode([round]);
	}
	/// 「発火キーコード」をXMLノード化する。
	static XNode keyCodeToNode(FKeyCode keyCode, in System sys) { mixin(S_TRACE);
		auto str = sys.convFireKeyCode(keyCode);
		return keyCodesToNode([str]);
	}
	private static bool fireFromNode(ref XNode node, string name, bool delegate() has, void delegate(bool) fire) { mixin(S_TRACE);
		if (node.name == name && !has()) { mixin(S_TRACE);
			fire(true);
			return true;
		}
		return false;
	}
	/// 「到着時発火」「クリック時発火」「死亡時発火」をXMLノードからロードし、成功すればtrueを返す。
	bool enterFromNode(EventTreeOwner owner, ref XNode node) { mixin(S_TRACE);
		return owner.canHasFireEnter && fireFromNode(node, "IgniteWithEnter", &fireEnter, &enter);
	}
	/// 「逃走時発火」をXMLノードからロードし、成功すればtrueを返す。
	bool escapeFromNode(EventTreeOwner owner, ref XNode node) { mixin(S_TRACE);
		return owner.canHasFireEscape && fireFromNode(node, "IgniteWithRunAway", &fireEscape, &escape);
	}
	/// 「敗北時発火」をXMLノードからロードし、成功すればtrueを返す。
	bool loseFromNode(EventTreeOwner owner, ref XNode node) { mixin(S_TRACE);
		return owner.canHasFireLose && fireFromNode(node, "IgniteWithLose", &fireLose, &lose);
	}
	/// 「毎ラウンド発火」をXMLノードからロードし、成功すればtrueを返す。
	bool everyRoundFromNode(EventTreeOwner owner, ref XNode node) { mixin(S_TRACE);
		return owner.canHasFireEveryRound && fireFromNode(node, "IgniteWithEveryRound", &fireEveryRound, &everyRound);
	}
	/// 「戦闘開始時発火」をXMLノードからロードし、成功すればtrueを返す。
	bool round0FromNode(EventTreeOwner owner, ref XNode node) { mixin(S_TRACE);
		return owner.canHasFireRound0 && fireFromNode(node, "IgniteWithRound0", &fireRound0, &round0);
	}
	/// 「発火ラウンド」をXMLノードからロードし、追加に成功した発火ラウンドの配列を返す。
	uint[] roundsFromNode(EventTreeOwner owner, ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
		if (owner.canHasFireRound) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				if (node.name == ROUNDS_XML_NAME) { mixin(S_TRACE);
					auto rounds = .roundsFromNode(node, ver);
					rounds = addRounds(rounds);
					if (rounds.length) { mixin(S_TRACE);
						sortRounds();
						return rounds;
					}
				}
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
		return [];
	}
	/// 「発火キーコード」をXMLノードからロードし、追加に成功した発火キーコードの配列を返す。
	FKeyCode[] keyCodesFromNode(EventTreeOwner owner, ref XNode node, in XMLInfo ver, in System sys, ptrdiff_t insertIndex = -1) { mixin(S_TRACE);
		if (owner.canHasFireKeyCode) { mixin(S_TRACE);
			try { mixin(S_TRACE);
				if (node.name == KEY_CODES_XML_NAME) { mixin(S_TRACE);
					auto keyCodes = .keyCodesFromNode(node, ver);
					auto keyCodes2 = new FKeyCode[keyCodes.length];
					foreach (i, keyCode; keyCodes) { mixin(S_TRACE);
						auto kind = sys.fireKeyCodeKindRef(keyCode);
						keyCodes2[i] = FKeyCode(keyCode, kind);
					}
					return addKeyCodes(keyCodes2, insertIndex);
				}
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
			}
		}
		return [];
	}
}

/// イベントツリーの所持者。エリアや効果カード等。
public interface EventTreeOwner : CWXPath {
	/// イベントツリー群。
	@property
	inout
	inout(EventTree)[] trees();

	/// 発火条件「到着」「クリック」「死亡」に対応しているか。
	@property
	const
	bool canHasFireEnter();
	/// 発火条件「敗北」に対応しているか。
	@property
	const
	bool canHasFireLose();
	/// 発火条件「逃走」に対応しているか。
	@property
	const
	bool canHasFireEscape();
	/// 発火条件「毎ラウンド」に対応しているか。
	@property
	const
	bool canHasFireEveryRound();
	/// 発火条件「戦闘開始」に対応しているか。
	@property
	const
	bool canHasFireRound0();
	/// 発火条件「ラウンド」に対応しているか。
	@property
	const
	bool canHasFireRound();
	/// 発火条件「キーコード」に対応しているか。
	@property
	const
	bool canHasFireKeyCode();

	/// イベントツリーを追加・除去する。
	void add(EventTree evt);
	/// ditto
	void insert(size_t index, EventTree evt);
	/// ditto
	void removeEvent(size_t index);
	/// ditto
	void remove(EventTree et);
	/// イベントツリーのインデックスを交換。
	void swapEventTree(size_t index1, size_t index2);

	/// 属すエリア等からの相対パス。
	@property
	size_t[] areaPath();

	/// EventTreeが含まれていないか。
	/// 内容が空のEventTreeしか持たない場合もtrueとなる。
	@property
	const
	bool isEmpty();
}

/// EventTreeOwnerの仮の実装。
public abstract class AbstractEventTreeOwner : EventTreeOwner {
private:
	EventTree[] _evts;
	UseCounter _uc;
	void delegate() _change;
public:
	@property
	override abstract size_t[] areaPath();

	CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		auto cate = cpcategory(path);
		if (cate == "event") { mixin(S_TRACE);
			auto index = cpindex(path);
			if (index >= _evts.length) return null;
			return _evts[index].findCWXPath(cpbottom(path));
		}
		return null;
	}
	@property
	inout
	inout(CWXPath)[] cwxChilds() { mixin(S_TRACE);
		inout(CWXPath)[] r;
		foreach (a; trees) r ~= a;
		return r;
	}

	/// ownerのイベントツリーをコピーしてこのインスタンスに上書きする。
	protected void deepCopyEventTreeOwner(in EventTreeOwner owner) { mixin(S_TRACE);
		while (trees.length) removeEvent(0);
		EventTree[] evts;
		foreach (tree; owner.trees) evts ~= tree.dup;
		addAll(evts);
	}

	/// 使用回数カウンタ。
	@property
	UseCounter useCounter() { mixin(S_TRACE);
		return _uc;
	}
	/// 変更ハンドラを登録する。
	@property
	void changeHandler(void delegate() change) { mixin(S_TRACE);
		foreach (e; _evts) { mixin(S_TRACE);
			e.changeHandler = &changed;
		}
		_change = change;
	}
	/// 変更ハンドラ。
	@property
	protected void delegate() changeHandler() { mixin(S_TRACE);
		return &changed;
	}
	/// 変更を通知する。
	void changed() { mixin(S_TRACE);
		if (_change) _change();
	}
	/// 委譲によって使用する場合は委譲元を返す。
	@property
	protected EventTreeOwner con() {return this;}

	@property
	inout
	inout(EventTree)[] trees() { mixin(S_TRACE);
		return _evts;
	}

	void swapEventTree(size_t index1, size_t index2) { mixin(S_TRACE);
		if (index1 != index2) changed();
		auto temp = _evts[index1];
		_evts[index1] = _evts[index2];
		_evts[index2] = temp;
	}

	void addAll(EventTree[] evts) { mixin(S_TRACE);
		foreach (e; evts) { mixin(S_TRACE);
			add(e);
		}
	}
	private void addCmn(EventTree evt) { mixin(S_TRACE);
		if (!canHasFireEnter) evt.enter = false;
		if (!canHasFireLose) evt.lose = false;
		if (!canHasFireEscape) evt.escape = false;
		if (!canHasFireEveryRound) evt.everyRound = false;
		if (!canHasFireRound0) evt.round0 = false;
		if (!canHasFireRound) evt.removeRoundsAll();
		if (!canHasFireKeyCode) evt.removeKeyCodesAll();

		if (_uc !is null) { mixin(S_TRACE);
			evt.setUseCounter(_uc);
		}
		evt.changeHandler = changeHandler;
		evt._owner = con;
		changed();
	}
	void add(EventTree evt) { mixin(S_TRACE);
		addCmn(evt);
		_evts ~= evt;
	}
	void insert(size_t index, EventTree evt) { mixin(S_TRACE);
		if (_evts.length == index) { mixin(S_TRACE);
			add(evt);
		} else { mixin(S_TRACE);
			addCmn(evt);
			_evts = _evts[0 .. index] ~ evt ~ _evts[index .. $];
		}
	}
	/// このクラスを継承する場合、「到着」「クリック」「死亡」は有効になる。
	@property
	const
	bool canHasFireEnter() {return true;}
	@property
	const
	abstract bool canHasFireLose();
	@property
	const
	abstract bool canHasFireEscape();
	@property
	const
	abstract bool canHasFireEveryRound();
	@property
	const
	abstract bool canHasFireRound0();
	@property
	const
	abstract bool canHasFireRound();
	@property
	const
	abstract bool canHasFireKeyCode();

	void clearEvents() { mixin(S_TRACE);
		if (!_evts.length) return;
		changed();
		foreach (evt; _evts) { mixin(S_TRACE);
			if (_uc !is null) { mixin(S_TRACE);
				evt.removeUseCounter();
			}
			evt.changeHandler = null;
			evt._owner = null;
		}
		_evts = [];
	}
	void removeEvent(size_t index) { mixin(S_TRACE);
		if (_uc !is null) { mixin(S_TRACE);
			_evts[index].removeUseCounter();
		}
		_evts[index].changeHandler = null;
		_evts[index]._owner = null;
		_evts = _evts[0 .. index] ~ _evts[index + 1 .. $];
		changed();
	}
	void remove(EventTree et) { mixin(S_TRACE);
		foreach (i, t; _evts) { mixin(S_TRACE);
			if (t is et) { mixin(S_TRACE);
				removeEvent(i);
				return;
			}
		}
		assert (0);
	}

	/// 使用回数カウンタを登録・除去する。
	@property
	void setUseCounter(UseCounter uc) { mixin(S_TRACE);
		foreach (tree; _evts) { mixin(S_TRACE);
			tree.setUseCounter(uc);
		}
		_uc = uc;
	}
	/// ditto
	void removeUseCounter() { mixin(S_TRACE);
		foreach (tree; _evts) { mixin(S_TRACE);
			tree.removeUseCounter();
		}
		_uc = null;
	}

	/// XMLノードからイベントツリーを読み出して返す。
	static EventTree[] loadEventsFromNode(XNode node, in XMLInfo ver) { mixin(S_TRACE);
		assert (node.name == "Events");
		EventTree[] r;
		node.onTag["Event"] = (ref XNode node) { mixin(S_TRACE);
			auto tree = EventTree.createFromNode(node, ver);
			if (tree) r ~= tree;
		};
		node.parse();
		return r;
	}
	/// XMLノードにイベントツリー群のデータを追加する。
	const
	void appendEventsToNode(ref XNode node, XMLOption opt) { mixin(S_TRACE);
		auto ee = node.newElement("Events");
		foreach (evt; _evts) { mixin(S_TRACE);
			evt.toNode(ee, opt);
		}
	}

	@property
	const
	override bool isEmpty() { mixin(S_TRACE);
		foreach (tree; trees) { mixin(S_TRACE);
			if (!tree.isEmpty) return false;
		}
		return true;
	}
}

/// 状態変数を初期化するイベントツリーを生成する。
Content createInitVariablesTree(in FlagDir dir) { mixin(S_TRACE);
	return createInitVariablesTree(dir.allFlags(), dir.allSteps());
}
/// ditto
Content createInitVariablesTree(in cwx.flag.Flag[] flags, in Step[] steps) { mixin(S_TRACE);
	return createInitVariablesTreeImpl!(CType.SET_FLAG, CType.SET_STEP)(flags, steps, (f) => f.onOff, (s) => s.select);
}
/// フラグの値を設定するイベントツリーを生成する。
Content createSetFlagTree(in FlagDir dir, bool onOff) { mixin(S_TRACE);
	return createSetFlagTree(dir.allFlags(), onOff);
}
/// ditto
Content createSetFlagTree(in cwx.flag.Flag[] flags, bool onOff) { mixin(S_TRACE);
	return createInitVariablesTreeImpl!(CType.SET_FLAG, CType.SET_STEP)(flags, [], (f) => onOff, null);
}
/// ステップの値を設定するイベントツリーを生成する。
Content createSetStepTree(in FlagDir dir, uint select) { mixin(S_TRACE);
	return createSetStepTree(dir.allSteps(), select);
}
/// ditto
Content createSetStepTree(in Step[] steps, uint select) { mixin(S_TRACE);
	return createInitVariablesTreeImpl!(CType.SET_FLAG, CType.SET_STEP)([], steps, null, (s) => select);
}
/// フラグを反転するイベントツリーを生成する。
Content createReverseFlagTree(in FlagDir dir) { mixin(S_TRACE);
	return createReverseFlagTree(dir.allFlags());
}
/// ditto
Content createReverseFlagTree(in cwx.flag.Flag[] flags) { mixin(S_TRACE);
	return createInitVariablesTreeImpl!(CType.REVERSE_FLAG, CType.SET_STEP)(flags, [], null, null);
}
/// ステップを加算するイベントツリーを生成する。
Content createSetStepUpTree(in FlagDir dir) { mixin(S_TRACE);
	return createSetStepUpTree(dir.allSteps());
}
/// ditto
Content createSetStepUpTree(in Step[] steps) { mixin(S_TRACE);
	return createInitVariablesTreeImpl!(CType.SET_FLAG, CType.SET_STEP_UP)([], steps, null, null);
}
/// ステップを減算するイベントツリーを生成する。
Content createSetStepDownTree(in FlagDir dir) { mixin(S_TRACE);
	return createSetStepDownTree(dir.allSteps());
}
/// ditto
Content createSetStepDownTree(in Step[] steps) { mixin(S_TRACE);
	return createInitVariablesTreeImpl!(CType.SET_FLAG, CType.SET_STEP_DOWN)([], steps, null, null);
}
private Content createInitVariablesTreeImpl(CType TypeF, CType TypeS)(in cwx.flag.Flag[] flags, in Step[] steps,
		bool delegate(in cwx.flag.Flag) getValueF, uint delegate(in Step) getValueS) { mixin(S_TRACE);
	Content[] r;
	foreach (step; steps) { mixin(S_TRACE);
		auto c = new Content(TypeS, "");
		c.step = step.path;
		if (getValueS) c.stepValue = getValueS(step);
		if (r.length) r[$-1].add(null, c);
		r ~= c;
	}
	foreach (flag; flags) { mixin(S_TRACE);
		auto c = new Content(TypeF, "");
		c.flag = flag.path;
		if (getValueF) c.flagValue = getValueF(flag);
		if (r.length) r[$-1].add(null, c);
		r ~= c;
	}
	return r.length ? r[0] : null;
}

/// イベント関連の例外。
public class EventException : Exception {
public:
	this (string msg) { mixin(S_TRACE);
		super(msg);
	}
}

/// イベントコンテントの初期値設定
struct ContentInitializer {
	static const XML_NAME = "contentInitializer";

	string dataVersion;
	Content[CType] initializer;

	/// XMLノードとして取り扱うための関数群。
	const
	XNode toNode() { mixin(S_TRACE);
		auto e = XNode.create(XML_NAME);
		toNodeImpl(e);
		return e;
	}
	/// ditto
	const
	void toNode(ref XNode node) { mixin(S_TRACE);
		auto e = node.newElement(XML_NAME);
		toNodeImpl(e);
	}
	/// ditto
	const
	private void toNodeImpl(ref XNode e) { mixin(S_TRACE);
		e.newAttr("dataVersion", dataVersion);
		foreach (c; initializer) { mixin(S_TRACE);
			c.toNode(e, null);
		}
	}
	/// ditto
	void fromNode(ref XNode node) { mixin(S_TRACE);
		if (node.name != XML_NAME) throw new Exception("Node is not content initializer");
		dataVersion = node.attr!(string)("dataVersion", true);
		initializer = null;
		node.onTag[null] = (ref XNode node) { mixin(S_TRACE);
			auto c = Content.createFromNode(node, null);
			initializer[c.type] = c;
		};
		node.parse();
	}
}

/// ラウンド発火条件群のXML要素名。
immutable ROUNDS_XML_NAME = "Number";

/// Number要素からラウンド群を取得する。
uint[] roundsFromNode(ref XNode node, in XMLInfo ver) { mixin(S_TRACE);
	if (!node.valid) return [];
	if (node.name != ROUNDS_XML_NAME) return [];
	uint[] rounds;
	foreach (t; .decodeLf(node.value, true)) { mixin(S_TRACE);
		auto v = .to!int(t);
		if (v < 0) rounds ~= -v;
	}
	return rounds;
}
/// ラウンド発火条件群をXML要素化し、nodeに追加する。
void roundsToNode(ref XNode node, in uint[] rounds) { mixin(S_TRACE);
	node.newElement(ROUNDS_XML_NAME, .encodeLf(.map!(r => .text(-cast(int)r))(rounds).array()));
}
/// ラウンド発火条件群をXML要素化する。
XNode roundsToNode(in uint[] rounds) { mixin(S_TRACE);
	return XNode.create(ROUNDS_XML_NAME, .encodeLf(.map!(r => .text(-cast(int)r))(rounds).array()));
}
/// ラウンド発火条件群をXML文書化する。
string roundsToXML(in uint[] rounds) { mixin(S_TRACE);
	auto node = roundsToNode(rounds);
	return node.text;
}
