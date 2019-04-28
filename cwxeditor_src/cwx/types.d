
module cwx.types;

import cwx.perf;

immutable LAYER_BACK_CELL = 0; /// 背景レイヤ。
immutable LAYER_MENU_CARD = 100; /// メニューカード・エネミーカードのレイヤ。
immutable LAYER_PLAYER_CARD = 200; /// プレイヤーカードのレイヤ。
immutable LAYER_FORE_CELL = 400; /// カードより手前の背景レイヤ(1.60)。
immutable LAYER_MESSAGE = 1000; /// メッセージレイヤ。

/// アクションカードのタイプ。
enum ActionCardType {
	Exchange = 0, /// カード交換。
	Attack = 1, /// 攻撃。
	PowerfulAttack = 2, /// 渾身の一撃。
	CriticalAttack = 3, /// 会心の一撃。
	Feint = 4, /// フェイント。
	Defense = 5, /// 防御。
	Distance = 6, /// 見切り。
	Confuse = -1, /// 混乱。
	RunAway = 7, /// 逃走。
}

/// 効果関連の例外。
class MotionException : Exception {
public:
	this(string msg) { mixin(S_TRACE);
		super(msg);
	}
}

/// 精神状態。
enum Mentality {
	NORMAL, /// 正常。
	SLEEP, /// 睡眠。
	CONFUSE, /// 混乱。
	OVERHEAT, /// 激昂。
	BRAVE, /// 勇敢。
	PANIC /// 恐慌。
}
/// ditto
Mentality toMentality(string s) { mixin(S_TRACE);
	switch (s) {
	case "Normal": return Mentality.NORMAL;
	case "Panic": return Mentality.PANIC;
	case "Brave": return Mentality.BRAVE;
	case "Overheat": return Mentality.OVERHEAT;
	case "Confuse": return Mentality.CONFUSE;
	case "Sleep": return Mentality.SLEEP;
	default: throw new Exception("Unknown Mentality: " ~ s);
	}
}
/// ditto
string fromMentality(Mentality m) { mixin(S_TRACE);
	final switch (m) {
	case Mentality.NORMAL: return "Normal";
	case Mentality.PANIC: return "Panic";
	case Mentality.BRAVE: return "Brave";
	case Mentality.OVERHEAT: return "Overheat";
	case Mentality.CONFUSE: return "Confuse";
	case Mentality.SLEEP: return "Sleep";
	}
}

/// 効果属性。
enum EffectType {
	PHYSIC, /// 物理。
	MAGIC, /// 魔法。
	MAGICAL_PHYSIC, /// 魔法的物理。
	PHYSICAL_MAGIC, /// 物理的魔法。
	NONE, /// 無。
}
/// 文字列から効果属性を生成。
EffectType toEffectType(string name) { mixin(S_TRACE);
	switch (name) {
	case "Physic":
		return EffectType.PHYSIC;
	case "Magic":
		return EffectType.MAGIC;
	case "MagicalPhysic":
		return EffectType.MAGICAL_PHYSIC;
	case "PhysicalMagic":
		return EffectType.PHYSICAL_MAGIC;
	case "None":
	case "Normal": // BUG: 古いスキンで「カード交換」「逃走」に設定されている
		return EffectType.NONE;
	default:
		throw new MotionException("Unknown effecttype: " ~ name);
	}
}
/// 効果属性を文字列に変換。
string fromEffectType(EffectType etyp) { mixin(S_TRACE);
	final switch (etyp) {
	case EffectType.PHYSIC:
		return "Physic";
	case EffectType.MAGIC:
		return "Magic";
	case EffectType.MAGICAL_PHYSIC:
		return "MagicalPhysic";
	case EffectType.PHYSICAL_MAGIC:
		return "PhysicalMagic";
	case EffectType.NONE:
		return "None";
	}
}
/// 抵抗属性。
enum Resist {
	AVOID, /// 回避。
	RESIST, /// 抵抗。
	UNFAIL, /// 必中。
}
/// 文字列から抵抗属性を生成。
Resist toResist(string name) { mixin(S_TRACE);
	switch (name) {
	case "Avoid":
		return Resist.AVOID;
	case "Resist":
		return Resist.RESIST;
	case "Unfail":
		return Resist.UNFAIL;
	default:
		throw new MotionException("Unknown resist: " ~ name);
	}
}
/// 抵抗属性から文字列へ変換。
string fromResist(Resist resist) { mixin(S_TRACE);
	final switch (resist) {
	case Resist.AVOID:
		return "Avoid";
	case Resist.RESIST:
		return "Resist";
	case Resist.UNFAIL:
		return "Unfail";
	}
}
/// 視覚効果。
enum CardVisual {
	NONE, /// 無し。
	REVERSE, /// 反転。
	HORIZONTAL, /// 横震動。
	VERTICAL, /// 縦振動。
}
/// 文字列から視覚効果を生成。
CardVisual toCardVisual(string name) { mixin(S_TRACE);
	switch (name) {
	case "None":
		return CardVisual.NONE;
	case "Reverse":
		return CardVisual.REVERSE;
	case "Horizontal":
		return CardVisual.HORIZONTAL;
	case "Vertical":
		return CardVisual.VERTICAL;
	default:
		throw new MotionException("Unknown cardvisual: " ~ name);
	}
}
/// 視覚効果から文字列へ変換。
string fromCardVisual(CardVisual vis) { mixin(S_TRACE);
	final switch (vis) {
	case CardVisual.NONE:
		return "None";
	case CardVisual.REVERSE:
		return "Reverse";
	case CardVisual.HORIZONTAL:
		return "Horizontal";
	case CardVisual.VERTICAL:
		return "Vertical";
	}
}
/// 効果属性。
enum Element {
	ALL, /// 全。
	HEALTH, /// 肉体。
	MIND, /// 精神。
	MIRACLE, /// 神聖。
	MAGIC, /// 魔法。
	FIRE, /// 炎。
	ICE, /// 冷気。
}
/// 文字列から効果属性を生成。
Element toElement(string name) { mixin(S_TRACE);
	switch (name) {
	case "All":
		return Element.ALL;
	case "Health":
		return Element.HEALTH;
	case "Mind":
		return Element.MIND;
	case "Miracle":
		return Element.MIRACLE;
	case "Magic":
		return Element.MAGIC;
	case "Fire":
		return Element.FIRE;
	case "Ice":
		return Element.ICE;
	default:
		throw new MotionException("Unknown element: " ~ name);
	}
}
/// 効果属性から文字列へ変換。
string fromElement(Element el) { mixin(S_TRACE);
	final switch (el) {
	case Element.ALL:
		return "All";
	case Element.HEALTH:
		return "Health";
	case Element.MIND:
		return "Mind";
	case Element.MIRACLE:
		return "Miracle";
	case Element.MAGIC:
		return "Magic";
	case Element.FIRE:
		return "Fire";
	case Element.ICE:
		return "Ice";
	}
}
/// 効果計算。
enum DamageType {
	LEVEL_RATIO, /// レベル比。
	NORMAL, /// 値の直接指定。
	MAX, /// 最大値。
	FIXED, /// 固定値(Wsn.1)。
}
/// 文字列から効果計算方式を生成。
DamageType toDamageType(string name) { mixin(S_TRACE);
	switch (name) {
	case "LevelRatio":
		return DamageType.LEVEL_RATIO;
	case "Normal":
		return DamageType.NORMAL;
	case "Max":
		return DamageType.MAX;
	case "Fixed":
		return DamageType.FIXED;
	default:
		throw new MotionException("Unknown damagetype: " ~ name);
	}
}
/// 効果計算方式を文字列へ変換。
string fromDamageType(DamageType dtyp) { mixin(S_TRACE);
	final switch (dtyp) {
	case DamageType.LEVEL_RATIO:
		return "LevelRatio";
	case DamageType.NORMAL:
		return "Normal";
	case DamageType.MAX:
		return "Max";
	case DamageType.FIXED:
		return "Fixed";
	}
}

/// メンバの選択。
struct Target {
public:
	/// メンバ種別。
	enum M {
		SELECTED, /// 選択中メンバ。
		UNSELECTED, /// 非選択メンバ。
		RANDOM, /// ランダムメンバ。
		PARTY, /// 全員。
	}
	M m; /// メンバ種別。
	bool sleep; /// 睡眠時有効可否。
	/// Targetを生成する。
	static Target opCall(M m, bool sleep) {
		Target r;
		r.m = m;
		r.sleep = sleep;
		return r;
	}
	const
	bool opEquals(const(Target) t) { mixin(S_TRACE);
		return t.m == m && t.sleep == sleep;
	}
private:
}
/// 文字列から対象メンバを生成。
Target toTarget(string name) { mixin(S_TRACE);
	switch (name) {
	case "Selected":
		return Target(Target.M.SELECTED, false);
	case "Unselected":
		return Target(Target.M.UNSELECTED, false);
	case "Random":
		return Target(Target.M.RANDOM, false);
	case "Party":
		return Target(Target.M.PARTY, false);
	case "SelectedSleep":
		return Target(Target.M.SELECTED, true);
	case "UnselectedSleep":
		return Target(Target.M.UNSELECTED, true);
	case "RandomSleep":
		return Target(Target.M.RANDOM, true);
	case "PartySleep":
		return Target(Target.M.PARTY, true);
	default:
		throw new MotionException("Unknown targetm: " ~ name);
	}
}
/// 対象メンバを文字列へ変換。
string fromTarget(Target targ) { mixin(S_TRACE);
	string targetText(string text, bool sleep) { mixin(S_TRACE);
		return sleep ? text ~ "Sleep" : text;
	}
	final switch (targ.m) {
	case Target.M.SELECTED:
		return targetText("Selected", targ.sleep);
	case Target.M.UNSELECTED:
		return targetText("Unselected", targ.sleep);
	case Target.M.RANDOM:
		return targetText("Random", targ.sleep);
	case Target.M.PARTY:
		return targetText("Party", targ.sleep);
	}
}

/// 精神要素。
enum Mental {
	AGGRESSIVE, /// 好戦
	UNAGGRESSIVE, /// 平和
	CHEERFUL, /// 社交
	UNCHEERFUL, /// 内向
	BRAVE, /// 勇敢
	UNBRAVE, /// 臆病
	CAUTIOUS, /// 慎重
	UNCAUTIOUS, /// 大胆
	TRICKISH, /// 狡猾
	UNTRICKISH, /// 正直
}
/// 文字列から精神要素を生成。
Mental toMental(string name) { mixin(S_TRACE);
	switch (name) {
	case "Aggressive":
		return Mental.AGGRESSIVE;
	case "Unaggressive":
		return Mental.UNAGGRESSIVE;
	case "Cheerful":
		return Mental.CHEERFUL;
	case "Uncheerful":
		return Mental.UNCHEERFUL;
	case "Brave":
		return Mental.BRAVE;
	case "Unbrave":
		return Mental.UNBRAVE;
	case "Cautious":
		return Mental.CAUTIOUS;
	case "Uncautious":
		return Mental.UNCAUTIOUS;
	case "Trickish":
		return Mental.TRICKISH;
	case "Untrickish":
		return Mental.UNTRICKISH;
	default:
		throw new MotionException("Unknown mental: " ~ name);
	}
}
///精神要素を文字列へ変換。
string fromMental(Mental m) { mixin(S_TRACE);
	final switch (m) {
	case Mental.AGGRESSIVE:
		return "Aggressive";
	case Mental.UNAGGRESSIVE:
		return "Unaggressive";
	case Mental.CHEERFUL:
		return "Cheerful";
	case Mental.UNCHEERFUL:
		return "Uncheerful";
	case Mental.BRAVE:
		return "Brave";
	case Mental.UNBRAVE:
		return "Unbrave";
	case Mental.CAUTIOUS:
		return "Cautious";
	case Mental.UNCAUTIOUS:
		return "Uncautious";
	case Mental.TRICKISH:
		return "Trickish";
	case Mental.UNTRICKISH:
		return "Untrickish";
	}
}
/// 精神要素の対立側を返す。
Mental reverseMental(Mental m) { mixin(S_TRACE);
	final switch (m) {
	case Mental.AGGRESSIVE:
		return Mental.UNAGGRESSIVE;
	case Mental.UNAGGRESSIVE:
		return Mental.AGGRESSIVE;
	case Mental.CHEERFUL:
		return Mental.UNCHEERFUL;
	case Mental.UNCHEERFUL:
		return Mental.CHEERFUL;
	case Mental.BRAVE:
		return Mental.UNBRAVE;
	case Mental.UNBRAVE:
		return Mental.BRAVE;
	case Mental.CAUTIOUS:
		return Mental.UNCAUTIOUS;
	case Mental.UNCAUTIOUS:
		return Mental.CAUTIOUS;
	case Mental.TRICKISH:
		return Mental.UNTRICKISH;
	case Mental.UNTRICKISH:
		return Mental.TRICKISH;
	}
}
/// 肉体要素。
enum Physical {
	DEX, /// 敏捷度。
	AGL, /// 器用度。
	INT, /// 知力。
	STR, /// 膂力。
	VIT, /// 生命力。
	MIN, /// 精神力。
}
/// 文字列から肉体要素を生成。
Physical toPhysical(string name) { mixin(S_TRACE);
	switch (name) {
	case "Dex":
		return Physical.DEX;
	case "Agl":
		return Physical.AGL;
	case "Int":
		return Physical.INT;
	case "Str":
		return Physical.STR;
	case "Vit":
		return Physical.VIT;
	case "Min":
		return Physical.MIN;
	default:
		throw new MotionException("Unknown physical: " ~ name);
	}
}
/// 肉体要素を文字列へ変換。
string fromPhysical(Physical p) { mixin(S_TRACE);
	final switch (p) {
	case Physical.DEX:
		return "Dex";
	case Physical.AGL:
		return "Agl";
	case Physical.INT:
		return "Int";
	case Physical.STR:
		return "Str";
	case Physical.VIT:
		return "Vit";
	case Physical.MIN:
		return "Min";
	}
}
/// 状態。
enum Status {
	ACTIVE, /// 行動可能。
	INACTIVE, /// 行動不可。
	ALIVE, /// 生存。
	DEAD, /// 非生存。
	FINE, /// 健康。
	INJURED, /// 負傷。
	HEAVY_INJURED, /// 重症。
	UNCONSCIOUS, /// 意識不明。
	POISON, /// 中毒。
	SLEEP, /// 睡眠。
	BIND, /// 呪縛。
	PARALYZE, /// 麻痺/石化。
	CONFUSE, /// 混乱(CardWirth Extender 1.30～)。
	OVERHEAT, /// 激昂(CardWirth Extender 1.30～)。
	BRAVE, /// 勇敢(CardWirth Extender 1.30～)。
	PANIC, /// 恐慌(CardWirth Extender 1.30～)。
	SILENCE, /// 沈黙(CardWirth 1.50)。
	FACE_UP, /// 暴露(CardWirth 1.50)。
	ANTI_MAGIC, /// 魔法無効化(CardWirth 1.50)。
	UP_ACTION, /// 行動力上昇(CardWirth 1.50)。
	UP_AVOID, /// 回避力上昇(CardWirth 1.50)。
	UP_RESIST, /// 抵抗力上昇(CardWirth 1.50)。
	UP_DEFENSE, /// 防御力上昇(CardWirth 1.50)。
	DOWN_ACTION, /// 行動力低下(CardWirth 1.50)。
	DOWN_AVOID, /// 回避力低下(CardWirth 1.50)。
	DOWN_RESIST, /// 抵抗力低下(CardWirth 1.50)。
	DOWN_DEFENSE, /// 防御力低下(CardWirth 1.50)。
	NONE, /// 状態指定無し。
}
/// 文字列から状態を生成。
Status toStatus(string name) { mixin(S_TRACE);
	switch (name) {
	case "Active":
		return Status.ACTIVE;
	case "Inactive":
		return Status.INACTIVE;
	case "Alive":
		return Status.ALIVE;
	case "Dead":
		return Status.DEAD;
	case "Fine":
		return Status.FINE;
	case "Injured":
		return Status.INJURED;
	case "HeavyInjured":
		return Status.HEAVY_INJURED;
	case "Unconscious":
		return Status.UNCONSCIOUS;
	case "Poison":
		return Status.POISON;
	case "Sleep":
		return Status.SLEEP;
	case "Bind":
		return Status.BIND;
	case "Paralyze":
		return Status.PARALYZE;
	case "Confuse":
		return Status.CONFUSE;
	case "Overheat":
		return Status.OVERHEAT;
	case "Brave":
		return Status.BRAVE;
	case "Panic":
		return Status.PANIC;
	case "Silence":
		return Status.SILENCE;
	case "FaceUp":
		return Status.FACE_UP;
	case "AntiMagic":
		return Status.ANTI_MAGIC;
	case "UpAction":
		return Status.UP_ACTION;
	case "UpAvoid":
		return Status.UP_AVOID;
	case "UpResist":
		return Status.UP_RESIST;
	case "UpDefense":
		return Status.UP_DEFENSE;
	case "DownAction":
		return Status.DOWN_ACTION;
	case "DownAvoid":
		return Status.DOWN_AVOID;
	case "DownResist":
		return Status.DOWN_RESIST;
	case "DownDefense":
		return Status.DOWN_DEFENSE;
	case "None":
		return Status.NONE;
	default:
		throw new MotionException("Unknown status: " ~ name);
	}
}
/// 状態を文字列へ変換。
string fromStatus(Status stat) { mixin(S_TRACE);
	final switch (stat) {
	case Status.ACTIVE:
		return "Active";
	case Status.INACTIVE:
		return "Inactive";
	case Status.ALIVE:
		return "Alive";
	case Status.DEAD:
		return "Dead";
	case Status.FINE:
		return "Fine";
	case Status.INJURED:
		return "Injured";
	case Status.HEAVY_INJURED:
		return "HeavyInjured";
	case Status.UNCONSCIOUS:
		return "Unconscious";
	case Status.POISON:
		return "Poison";
	case Status.SLEEP:
		return "Sleep";
	case Status.BIND:
		return "Bind";
	case Status.PARALYZE:
		return "Paralyze";
	case Status.CONFUSE:
		return "Confuse";
	case Status.OVERHEAT:
		return "Overheat";
	case Status.BRAVE:
		return "Brave";
	case Status.PANIC:
		return "Panic";
	case Status.SILENCE:
		return "Silence";
	case Status.FACE_UP:
		return "FaceUp";
	case Status.ANTI_MAGIC:
		return "AntiMagic";
	case Status.UP_ACTION:
		return "UpAction";
	case Status.UP_AVOID:
		return "UpAvoid";
	case Status.UP_RESIST:
		return "UpResist";
	case Status.UP_DEFENSE:
		return "UpDefense";
	case Status.DOWN_ACTION:
		return "DownAction";
	case Status.DOWN_AVOID:
		return "DownAvoid";
	case Status.DOWN_RESIST:
		return "DownResist";
	case Status.DOWN_DEFENSE:
		return "DownDefense";
	case Status.NONE:
		return "None";
	}
}
/// 適用範囲。
enum Range {
	SELECTED, /// 選択中メンバ。
	RANDOM, /// 誰か一人。
	PARTY, /// パーティ全員。
	BACKPACK, /// 荷物袋。
	PARTY_AND_BACKPACK, /// 全員と荷物袋。
	FIELD, /// フィールド全体。
	COUPON_HOLDER, /// 称号所有者(Wsn.2)。
	CARD_TARGET, /// カードの効果対象(Wsn.2)。
	SELECTED_CARD, /// 選択カード(Wsn.3)。
}
/// 文字列から適用範囲を生成。
Range toRange(string name) { mixin(S_TRACE);
	switch (name) {
	case "Selected":
		return Range.SELECTED;
	case "Random":
		return Range.RANDOM;
	case "Party":
		return Range.PARTY;
	case "Backpack":
		return Range.BACKPACK;
	case "PartyAndBackpack":
		return Range.PARTY_AND_BACKPACK;
	case "Field":
		return Range.FIELD;
	case "CouponHolder":
		return Range.COUPON_HOLDER;
	case "CardTarget":
		return Range.CARD_TARGET;
	case "SelectedCard":
		return Range.SELECTED_CARD;
	default:
		throw new MotionException("Unknown targets: " ~ name);
	}
}
/// 適用範囲を文字列へ変換。
string fromRange(Range r) { mixin(S_TRACE);
	final switch (r) {
	case Range.SELECTED:
		return "Selected";
	case Range.RANDOM:
		return "Random";
	case Range.PARTY:
		return "Party";
	case Range.BACKPACK:
		return "Backpack";
	case Range.PARTY_AND_BACKPACK:
		return "PartyAndBackpack";
	case Range.FIELD:
		return "Field";
	case Range.COUPON_HOLDER:
		return "CouponHolder";
	case Range.CARD_TARGET:
		return "CardTarget";
	case Range.SELECTED_CARD:
		return "SelectedCard";
	}
}
/// 効果対象や話者選択時に現れる適用範囲。
Range[] RANGE_MEMBER = [Range.SELECTED, Range.RANDOM, Range.PARTY];

/// キャスト選択範囲。CardWirth Extender 1.30～
enum CastRange {
	PARTY = 0b0001, /// パーティ全体。
	ENEMY = 0b0010, /// 敵全体。
	NPC   = 0b0100, /// 同行キャスト全体。
}
/// 文字列からキャスト選択範囲を生成。
CastRange toCastRange(string name) { mixin(S_TRACE);
	switch (name) {
	case "Party":
		return CastRange.PARTY;
	case "Enemy":
		return CastRange.ENEMY;
	case "Npc":
		return CastRange.NPC;
	default:
		throw new MotionException("Unknown targets: " ~ name);
	}
}
/// キャスト選択範囲を文字列へ変換。
string fromCastRange(CastRange r) { mixin(S_TRACE);
	final switch (r) {
	case CastRange.PARTY:
		return "Party";
	case CastRange.ENEMY:
		return "Enemy";
	case CastRange.NPC:
		return "Npc";
	}
}
/// 能力修正。
enum Enhance {
	ACTION, /// 行動。
	AVOID, /// 回避。
	RESIST, /// 抵抗。
	DEFENSE, /// 防御。
}
/// 文字列から能力修正種別を生成。
Enhance toEnhance(string name) { mixin(S_TRACE);
	switch (name) {
	case "Action":
		return Enhance.ACTION;
	case "Avoid":
		return Enhance.AVOID;
	case "Resist":
		return Enhance.RESIST;
	case "Defense":
		return Enhance.DEFENSE;
	default:
		throw new Exception("Unknown enhance: " ~ name);
	}
}
/// 能力修正種別を文字列へ変換。
string fromEnhance(Enhance r) { mixin(S_TRACE);
	final switch (r) {
	case Enhance.ACTION:
		return "Action";
	case Enhance.AVOID:
		return "Avoid";
	case Enhance.RESIST:
		return "Resist";
	case Enhance.DEFENSE:
		return "Defense";
	}
}
/// カードの希少度。
enum Premium {
	NORMAL, /// 日用品。
	RARE, /// 希少品。
	PREMIUM, /// 貴重品。
}
/// 文字列から希少度を生成。
Premium toPremium(string name) { mixin(S_TRACE);
	switch (name) {
	case "Normal":
		return Premium.NORMAL;
	case "Rare":
		return Premium.RARE;
	case "Premium":
		return Premium.PREMIUM;
	default:
		throw new Exception("Unknown premium: " ~ name);
	}
}
/// 希少度を文字列へ変換。
string fromPremium(Premium r) { mixin(S_TRACE);
	final switch (r) {
	case Premium.NORMAL:
		return "Normal";
	case Premium.RARE:
		return "Rare";
	case Premium.PREMIUM:
		return "Premium";
	}
}
/// カード効果の標的。
enum CardTarget {
	NONE, /// 対象無し。
	USER, /// 使用者。
	PARTY, /// 味方。
	ENEMY, /// 敵方。
	BOTH, /// 双方。
}
/// 文字列からカード効果標的を生成。
CardTarget toCardTarget(string name) { mixin(S_TRACE);
	switch (name) {
	case "None":
		return CardTarget.NONE;
	case "User":
		return CardTarget.USER;
	case "Party":
		return CardTarget.PARTY;
	case "Enemy":
		return CardTarget.ENEMY;
	case "Both":
		return CardTarget.BOTH;
	default:
		throw new Exception("Unknown card target: " ~ name);
	}
}
/// カード効果標的を文字列へ変換。
string fromCardTarget(CardTarget r) { mixin(S_TRACE);
	final switch (r) {
	case CardTarget.NONE:
		return "None";
	case CardTarget.USER:
		return "User";
	case CardTarget.PARTY:
		return "Party";
	case CardTarget.ENEMY:
		return "Enemy";
	case CardTarget.BOTH:
		return "Both";
	}
}

/// メッセージの話者。
enum Talker {
	SELECTED, /// 選択中メンバ。
	UNSELECTED, /// 非選択メンバ。
	RANDOM, /// ランダムメンバ。
	CARD, /// カード。
	VALUED, /// 評価メンバ。
}

/// Talkerを文字列に変換する。
string fromTalker(Talker talker) { mixin(S_TRACE);
	final switch (talker) {
	case Talker.SELECTED:
		return "Selected";
	case Talker.UNSELECTED:
		return "Unselected";
	case Talker.RANDOM:
		return "Random";
	case Talker.CARD:
		return "Card";
	case Talker.VALUED:
		return "Valued";
	}
}

/// 背景遷移エフェクト。
enum Transition {
	DEFAULT, /// ユーザ指定。
	NONE, /// アニメーション無し。
	BLINDS, /// ブラインド式。
	PIXEL_DISSOLVE, /// ピクセルディゾルブ式。
	FADE, /// フェード式。
}
/// ditto
Transition[] ALL_TRANSITION = [
	Transition.DEFAULT,
	Transition.NONE,
	Transition.BLINDS,
	Transition.PIXEL_DISSOLVE,
	Transition.FADE,
];
/// 文字列から背景遷移エフェクトを生成。
Transition toTransition(string name) { mixin(S_TRACE);
	switch (name) {
	case "Default":
		return Transition.DEFAULT;
	case "None":
		return Transition.NONE;
	case "Blinds":
		return Transition.BLINDS;
	case "PixelDissolve":
		return Transition.PIXEL_DISSOLVE;
	case "Fade":
		return Transition.FADE;
	default:
		throw new Exception("Unknown transition: " ~ name);
	}
}
/// 背景遷移エフェクトを文字列へ変換。
string fromTransition(Transition t) { mixin(S_TRACE);
	final switch (t) {
	case Transition.DEFAULT:
		return "Default";
	case Transition.NONE:
		return "None";
	case Transition.BLINDS:
		return "Blinds";
	case Transition.PIXEL_DISSOLVE:
		return "PixelDissolve";
	case Transition.FADE:
		return "Fade";
	}
}

/// 効果カードタイプ。
enum EffectCardType {
	ALL, /// 全種類。
	SKILL, /// 特殊技能。
	ITEM, /// アイテム。
	BEAST, /// 召喚獣。
	HAND, /// 手札(Wsn.2)。
}
/// ditto
EffectCardType toEffectCardType(string name) { mixin(S_TRACE);
	switch (name) {
	case "All":   return EffectCardType.ALL;
	case "Skill": return EffectCardType.SKILL;
	case "Item":  return EffectCardType.ITEM;
	case "Beast": return EffectCardType.BEAST;
	case "Hand":  return EffectCardType.HAND;
	default: throw new Exception("Unknown card type: " ~ name);
	}
}
/// ditto
string fromEffectCardType(EffectCardType t) { mixin(S_TRACE);
	final switch (t) {
	case EffectCardType.ALL:   return "All";
	case EffectCardType.SKILL: return "Skill";
	case EffectCardType.ITEM:  return "Item";
	case EffectCardType.BEAST: return "Beast";
	case EffectCardType.HAND:  return "Hand";
	}
}

/// 4路比較条件(CardWirth 1.30)。
enum Comparison4 {
	Eq, /// nであれば。
	Ne, /// nでなければ。
	Lt, /// nより大きければ。
	Gt, /// nより小さければ。
}
/// ditto
Comparison4 toComparison4(string name) { mixin(S_TRACE);
	switch (name) {
	case "=": return Comparison4.Eq;
	case "<>": return Comparison4.Ne;
	case "<": return Comparison4.Lt;
	case ">": return Comparison4.Gt;
	default: throw new Exception("Unknown 4 way comparison: " ~ name);
	}
}
/// ditto
string fromComparison4(Comparison4 t) { mixin(S_TRACE);
	final switch (t) {
	case Comparison4.Eq: return "=";
	case Comparison4.Ne: return "<>";
	case Comparison4.Lt: return "<";
	case Comparison4.Gt: return ">";
	}
}

/// 3路比較条件(CardWirth 1.30)。
enum Comparison3 {
	Eq, /// nである。
	Lt, /// nより大きい。
	Gt, /// nより小さい。
}
/// ditto
Comparison3 toComparison3(string name) { mixin(S_TRACE);
	switch (name) {
	case "=": return Comparison3.Eq;
	case "<": return Comparison3.Lt;
	case ">": return Comparison3.Gt;
	default: throw new Exception("Unknown 3 way comparison: " ~ name);
	}
}
/// ditto
string fromComparison3(Comparison3 t) { mixin(S_TRACE);
	final switch (t) {
	case Comparison3.Eq: return "=";
	case Comparison3.Lt: return "<";
	case Comparison3.Gt: return ">";
	}
}

/// 画像合成モード(CardWirth 1.50)。
enum BlendMode {
	Normal, /// 標準。
	Mask, /// 無効。
	Add, /// 加算。
	Subtract, /// 減算。
	Multiply, /// 乗算。
}
/// ditto
BlendMode toBlendMode(string name) { mixin(S_TRACE);
	switch (name) {
	case "Normal": return BlendMode.Normal;
	case "Mask": return BlendMode.Mask;
	case "Add": return BlendMode.Add;
	case "Subtract": return BlendMode.Subtract;
	case "Multiply": return BlendMode.Multiply;
	default: throw new Exception("Unknown blend mode: " ~ name);
	}
}
/// ditto
string fromBlendMode(BlendMode t) { mixin(S_TRACE);
	final switch (t) {
	case BlendMode.Normal: return "Normal";
	case BlendMode.Mask: return "Mask";
	case BlendMode.Add: return "Add";
	case BlendMode.Subtract: return "Subtract";
	case BlendMode.Multiply: return "Multiply";
	}
}

/// グラデーション方向(CardWirth 1.50)。
enum GradientDir {
	None, /// グラデーション無し。
	LeftToRight, /// 左から右へ。
	TopToBottom, /// 上から下へ。
}
/// ditto
GradientDir toGradientDir(string name) { mixin(S_TRACE);
	switch (name) {
	case "None": return GradientDir.None;
	case "LeftToRight": return GradientDir.LeftToRight;
	case "TopToBottom": return GradientDir.TopToBottom;
	default: throw new Exception("Unknown gradient dir: " ~ name);
	}
}
/// ditto
string fromGradientDir(GradientDir t) { mixin(S_TRACE);
	final switch (t) {
	case GradientDir.None: return "None";
	case GradientDir.LeftToRight: return "LeftToRight";
	case GradientDir.TopToBottom: return "TopToBottom";
	}
}

/// 縁取りタイプ(CardWirth 1.50)。
enum BorderingType {
	None, /// 縁取り無し。
	Outline, /// 外側を縁取り。
	Inline, /// 内側を縁取り。
}
/// ditto
BorderingType toBorderingType(string name) { mixin(S_TRACE);
	switch (name) {
	case "None": return BorderingType.None;
	case "Outline": return BorderingType.Outline;
	case "Inline": return BorderingType.Inline;
	default: throw new Exception("Unknown bordering type: " ~ name);
	}
}
/// ditto
string fromBorderingType(BorderingType t) { mixin(S_TRACE);
	final switch (t) {
	case BorderingType.None: return "None";
	case BorderingType.Outline: return "Outline";
	case BorderingType.Inline: return "Inline";
	}
}

/// 座標タイプ(Wsn.1)。
enum CoordinateType {
	None, /// 座標指定無効。
	Absolute, /// 絶対位置。
	Relative, /// 相対位置。
	Percentage, /// パーセンテージ。
}
/// ditto
CoordinateType toCoordinateType(string name) { mixin(S_TRACE);
	switch (name) {
	case "None": return CoordinateType.None;
	case "Absolute": return CoordinateType.Absolute;
	case "Relative": return CoordinateType.Relative;
	case "Percentage": return CoordinateType.Percentage;
	default: throw new Exception("Unknown coordinate type: " ~ name);
	}
}
/// ditto
string fromCoordinateType(CoordinateType t) { mixin(S_TRACE);
	final switch (t) {
	case CoordinateType.None: return "None";
	case CoordinateType.Absolute: return "Absolute";
	case CoordinateType.Relative: return "Relative";
	case CoordinateType.Percentage: return "Percentage";
	}
}

/// メンバ選択方法。
enum SelectionMethod {
	Manual, /// 手動で選択。
	Random, /// ランダムで選択。
	Valued, /// 評価条件で選択(Wsn.1)。
}
/// ditto
SelectionMethod toSelectionMethod(string name) { mixin(S_TRACE);
	switch (name) {
	case "Manual": return SelectionMethod.Manual;
	case "Random": return SelectionMethod.Random;
	case "Valued": return SelectionMethod.Valued;
	default: throw new Exception("Unknown selection method: " ~ name);
	}
}
/// ditto
string fromSelectionMethod(SelectionMethod t) { mixin(S_TRACE);
	final switch (t) {
	case SelectionMethod.Manual: return "Manual";
	case SelectionMethod.Random: return "Random";
	case SelectionMethod.Valued: return "Valued";
	}
}

/// キャスト同行時の戦闘行動開始タイミング(Wsn.2)。
enum StartAction {
	Now, /// 即時に行動する(無指定の場合のデフォルト)。
	CurrentRound, /// ラウンドイベントで加入した場合はそのラウンドから行動する。
	NextRound, /// 次ラウンドから行動する(クラシックなシナリオのデフォルト)。
}
/// ditto
StartAction toStartAction(string name) { mixin(S_TRACE);
	switch (name) {
	case "Now": return StartAction.Now;
	case "CurrentRound": return StartAction.CurrentRound;
	case "NextRound": return StartAction.NextRound;
	default: throw new Exception("Unknown start action: " ~ name);
	}
}
/// ditto
string fromStartAction(StartAction t) { mixin(S_TRACE);
	final switch (t) {
	case StartAction.Now: return "Now";
	case StartAction.CurrentRound: return "CurrentRound";
	case StartAction.NextRound: return "NextRound";
	}
}

/// 背景セルのスムージング設定(Wsn.2)。
enum Smoothing {
	Default, /// エンジンの設定を使用する。
	True, /// 強制的にスムージングする。
	False, /// 強制的にスムージングしない。
}
/// ditto
Smoothing toSmoothing(string name) { mixin(S_TRACE);
	switch (name) {
	case "Default": return Smoothing.Default;
	case "True": return Smoothing.True;
	case "False": return Smoothing.False;
	default: throw new Exception("Unknown smoothing: " ~ name);
	}
}
/// ditto
string fromSmoothing(Smoothing t) { mixin(S_TRACE);
	final switch (t) {
	case Smoothing.Default: return "Default";
	case Smoothing.True: return "True";
	case Smoothing.False: return "False";
	}
}

/// 発動時の視覚効果(Wsn.4)。
enum ShowStyle {
	Invisible, /// 表示しない。
	Center, /// 画面中央に表示。
	FrontOfUser, /// 使用者の手前に表示。
}
/// ditto
ShowStyle toShowStyle(string name) { mixin(S_TRACE);
	switch (name) {
	case "Invisible": return ShowStyle.Invisible;
	case "Center": return ShowStyle.Center;
	case "FrontOfUser": return ShowStyle.FrontOfUser;
	default: throw new Exception("Unknown show style: " ~ name);
	}
}
/// ditto
string fromShowStyle(ShowStyle t) { mixin(S_TRACE);
	final switch (t) {
	case ShowStyle.Invisible: return "Invisible";
	case ShowStyle.Center: return "Center";
	case ShowStyle.FrontOfUser: return "FrontOfUser";
	}
}

/// テキストセルの再表示時の更新内容(Wsn.4)。
enum UpdateType {
	Fixed, /// 最初に表示した内容に固定。
	Variables, /// 状態変数値を更新する。
	All, /// 全て更新する。
}
/// ditto
UpdateType toUpdateType(string name) { mixin(S_TRACE);
	switch (name) {
	case "Fixed": return UpdateType.Fixed;
	case "Variables": return UpdateType.Variables;
	case "All": return UpdateType.All;
	default: throw new Exception("Unknown update type: " ~ name);
	}
}
/// ditto
string fromUpdateType(UpdateType t) { mixin(S_TRACE);
	final switch (t) {
	case UpdateType.Fixed: return "Fixed";
	case UpdateType.Variables: return "Variables";
	case UpdateType.All: return "All";
	}
}

/// 状況設定・使用可否(Wsn.4)。
enum EnvironmentStatus {
	NotSet, /// 設定しない。
	Enable, /// 有効にする。
	Disable, /// 無効にする。
}
/// ditto
EnvironmentStatus toEnvironmentStatus(string name) { mixin(S_TRACE);
	switch (name) {
	case "NotSet": return EnvironmentStatus.NotSet;
	case "Enable": return EnvironmentStatus.Enable;
	case "Disable": return EnvironmentStatus.Disable;
	default: throw new Exception("Unknown environment status: " ~ name);
	}
}
/// ditto
string fromEnvironmentStatus(EnvironmentStatus t) { mixin(S_TRACE);
	final switch (t) {
	case EnvironmentStatus.NotSet: return "NotSet";
	case EnvironmentStatus.Enable: return "Enable";
	case EnvironmentStatus.Disable: return "Disable";
	}
}

/// 状態変数のタイプ。
enum VariableType {
	Flag, /// フラグ。
	Step, /// ステップ。
	Variant, /// コモン。
}

/// コモンの型(Wsn.4)。
enum VariantType {
	Number, /// 数値。
	String, /// 文字列。
	Boolean, /// 真偽値。
}
/// ditto
VariantType toVariantType(string name) { mixin(S_TRACE);
	switch (name) {
	case "Number": return VariantType.Number;
	case "String": return VariantType.String;
	case "Boolean": return VariantType.Boolean;
	default: throw new Exception("Unknown variant type: " ~ name);
	}
}
/// ditto
string fromVariantType(VariantType t) { mixin(S_TRACE);
	final switch (t) {
	case VariantType.Number: return "Number";
	case VariantType.String: return "String";
	case VariantType.Boolean: return "Boolean";
	}
}

/// 状態変数の初期化タイミング(Wsn.4)。
enum VariableInitialization {
	Leave, /// シナリオ終了時。
	Complete, /// 済印をつけた時。
	EventExit, /// イベント終了時。
	None, /// 初期化しない。
}
/// ditto
VariableInitialization toVariableInitialization(string name) { mixin(S_TRACE);
	switch (name) {
	case "Leave": return VariableInitialization.Leave;
	case "Complete": return VariableInitialization.Complete;
	case "EventExit": return VariableInitialization.EventExit;
	case "None": return VariableInitialization.None;
	default: throw new Exception("Unknown variable initialization: " ~ name);
	}
}
/// ditto
string fromVariableInitialization(VariableInitialization t) { mixin(S_TRACE);
	final switch (t) {
	case VariableInitialization.Leave: return "Leave";
	case VariableInitialization.Complete: return "Complete";
	case VariableInitialization.EventExit: return "EventExit";
	case VariableInitialization.None: return "None";
	}
}

/// 関数のカテゴリ。
enum FunctionCategory {
	StringOperation, /// 文字列操作。
	NumberOperation, /// 数値操作。
	Conversion, /// 型変換。
	VariableOperation, /// 状態変数。
	CardInformation, /// カード情報。
	CouponInformation, /// 称号情報。
	Etc, /// その他。
}

/// 発火条件キーコードの種別。
enum FKCKind {
	Use, /// 使用時。
	Success, /// 成功時。
	Failure, /// 失敗時。
	HasNot, /// 不保有。
}

/// コンテントのタイプ。
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
	REDISPLAY,
	SUBSTITUTE_STEP, /// ステップ代入(CardWirth Extender 1.30)。
	SUBSTITUTE_FLAG, /// フラグ代入(CardWirth Extender 1.30)。
	BRANCH_STEP_CMP, /// ステップ値分岐(CardWirth Extender 1.30)。
	BRANCH_FLAG_CMP, /// フラグ値分岐(CardWirth Extender 1.30)。
	BRANCH_RANDOM_SELECT, /// ランダム選択(CardWirth Extender 1.30)。
	BRANCH_KEY_CODE, /// キーコード所持分岐(CardWirth 1.50)。
	CHECK_STEP, /// ステップ判定(CardWirth 1.50)。
	BRANCH_ROUND, /// ラウンド分岐(CardWirth 1.50)。
	MOVE_BG_IMAGE, /// 背景再配置(Wsn.1)。
	REPLACE_BG_IMAGE, /// 背景置換(Wsn.1)。
	LOSE_BG_IMAGE, /// 背景削除(Wsn.1)。
	BRANCH_MULTI_COUPON, /// クーポン多岐分岐(Wsn.2)。
	BRANCH_MULTI_RANDOM, /// ランダム多岐分岐(Wsn.2)。
	MOVE_CARD, /// カード再配置(Wsn.3)。
	CHANGE_ENVIRONMENT, /// 状況設定(Wsn.4)。
	BRANCH_VARIANT, /// コモン分岐(Wsn.4)。
	SET_VARIANT, /// コモン設定(Wsn.4)。
	CHECK_VARIANT, /// コモン判定(Wsn.4)。
}

/// WSN形式のシナリオでのみ使用できるイベントコンテントか。
@property
bool isWsnContent(CType cType) { mixin(S_TRACE);
	with (CType) switch (cType) {
	case MOVE_BG_IMAGE: // Wsn.1
	case REPLACE_BG_IMAGE: // Wsn.1
	case LOSE_BG_IMAGE: // Wsn.1
	case BRANCH_MULTI_COUPON: // Wsn.2
	case BRANCH_MULTI_RANDOM: // Wsn.2
	case MOVE_CARD: // Wsn.3
	case CHANGE_ENVIRONMENT: // Wsn.4
	case BRANCH_VARIANT: // Wsn.4
	case SET_VARIANT: // Wsn.4
	case CHECK_VARIANT: // Wsn.4
		return true;
	default:
		return false;
	}
}

/// コンテントタイプの分類。
enum CTypeGroup {
	Terminal = 0, /// 開始/終端。
	Standard = 1, /// 基本。
	Data = 2, /// 変数操作/分岐。
	Utility = 3, /// 状況分岐。
	Branch = 4, /// 保有分岐。
	Get = 5, /// 取得。
	Lost = 6, /// 喪失。
	Visual = 7, // 外観操作。
	Variant = 8, // 演算。
}

enum CArg {
	AREA,
	BATTLE,
	PACKAGE,
	FLAG,
	STEP,
	BGM_PATH,
	BGM_CHANNEL,
	BGM_VOLUME,
	BGM_LOOP_COUNT,
	BGM_FADE_IN,
	SOUND_PATH,
	SOUND_CHANNEL,
	SOUND_VOLUME,
	SOUND_LOOP_COUNT,
	SOUND_FADE_IN,
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
	TALKER_C,
	TALKER_NC,
	EFFECT_TYPE,
	RESIST,
	TRANSITION,
	TARGET_ALL,
	SELECTION_METHOD,
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
	BG_IMAGES,
	STEP_2, /// 操作ターゲットステップ(CardWirth Extender 1.30～)。
	FLAG_2, /// 操作ターゲットフラグ(CardWirth Extender 1.30～)。
	CAST_RANGE, /// キャスト選択範囲(CardWirth Extender 1.30～)。
	LEVEL_MIN, /// 下限レベル(CardWirth Extender 1.30～)。
	LEVEL_MAX, /// 上限レベル(CardWirth Extender 1.30～)。
	KEY_CODE_RANGE, /// キーコード所持判定範囲(CardWirth 1.50)。
	KEY_CODE, /// キーコード(CardWirth 1.50)。
	COUPONS, /// 得点付きクーポン群(CardWirth 1.50)。
	INIT_VALUE, /// 評価メンバ初期点(CardWirth 1.50)。
	COMPARISON_4, /// 4路比較条件(CardWirth 1.50)。
	COMPARISON_3, /// 3路比較条件(CardWirth 1.50)。
	ROUND, /// ラウンド(CardWirth 1.50)。
	CELL_NAME, /// セル名称(Wsn.1)。
	POSITION_TYPE, /// 位置形式(Wsn.1)。
	X, /// 位置(Wsn.1)。
	Y, /// 位置(Wsn.1)。
	SIZE_TYPE, /// サイズ形式(Wsn.1)。
	WIDTH, /// サイズ(Wsn.1)。
	HEIGHT, /// サイズ(Wsn.1)。
	DO_ANIME, /// JPY1アニメーションを実行する(Wsn.1)。
	IGNORE_EFFECT_BOOSTER, /// エフェクトブースター関係のセルを無視する(Wsn.1)。
	SELECTION_COLUMNS, /// 後続選択肢の列数(Wsn.1)。
	START_ACTION, /// キャスト同行時の戦闘行動開始タイミング(Wsn.2)。
	IGNITE, /// イベントの発火有無(Wsn.2)。
	KEY_CODES, /// イベント発火のキーコード(Wsn.2)。
	TARGET_IS_SKILL, /// 特殊技能カードが対象か(Wsn.2)。
	TARGET_IS_ITEM, /// アイテムカードが対象か(Wsn.2)。
	TARGET_IS_BEAST, /// 召喚獣カードが対象か(Wsn.2)。
	TARGET_IS_HAND, /// 戦闘時の手札が対象か(Wsn.2)。
	HOLDING_COUPON, /// 範囲で称号所持者を指定した時の称号名(Wsn.2)。
	REF_ABILITY, /// 選択メンバの能力参照(Wsn.2)。
	CENTERING_X, /// メッセージを横方向に中央寄せして表示する(Wsn.2)。
	CENTERING_Y, /// メッセージを縦方向に中央寄せして表示する(Wsn.2)。
	BOUNDARY_CHECK, /// メッセージの禁則処理(Wsn.2)。
	COUPON_NAMES, /// 複数クーポン名(Wsn.2)。
	MATCHING_TYPE, /// マッチングタイプ(Wsn.2)。
	SELECT_CARD, /// 選択カードを変更する(Wsn.3)。
	SELECT_TALKER, /// 話者を選択する(Wsn.3)。
	CARD_GROUP, /// カードグループ(Wsn.3)。
	SCALE, /// スケール(Wsn.3)。
	LAYER, /// レイヤ(Wsn.3)。
	CONSUME_CARD, /// 使用中のカードを消費する(Wsn.3)。
	INVERT_RESULT, /// 条件に合わない場合に成功とする(Wsn.4)。
	CARD_SPEED, /// カードアニメーション速度(Wsn.4)。
	OVERRIDE_CARD_SPEED, /// 速度設定をカード本体の設定より優先する(Wsn.4)。
	BACKPACK_ENABLED, /// 荷物袋の使用可否(Wsn.4)。
	VARIANT, /// コモン(Wsn.4)。
	EXPRESSION, /// 式(Wsn.4)。
	EXPAND_SP_CHARS, /// クーポン・ゴシップで特殊文字を展開する(Wsn.4)。
	INITIAL_EFFECT, /// 初期効果の有無(Wsn.4)。
	INITIAL_SOUND_PATH, /// 初期音声(Wsn.4)。
	INITIAL_SOUND_CHANNEL, /// 初期音声再生チャネル(未使用)。
	INITIAL_SOUND_VOLUME, /// 初期音声音量(Wsn.4)。
	INITIAL_SOUND_LOOP_COUNT, /// 初期音声再生回数(Wsn.4)。
	INITIAL_SOUND_FADE_IN, /// 初期音声フェードイン時間(未使用)。
}

/// 後続コンテントのnameの型。
enum CNextType {
	NONE, /// 無し。
	TEXT, /// テキスト。
	BOOL, /// True/False。
	STEP, /// ステップ値。
	ID_AREA, /// エリアID。
	ID_BATTLE, /// バトルID。
	TRIO, /// 大なり、少なり、一致(CardWirth Extender 1.30)。
	COUPON, /// 称号(Wsn.2)。
}
/// ditto
CNextType toCNextType(string name) { mixin(S_TRACE);
	switch (name) {
	case "None": return CNextType.NONE;
	case "Text": return CNextType.TEXT;
	case "Bool": return CNextType.BOOL;
	case "Step": return CNextType.STEP;
	case "IdArea": return CNextType.ID_AREA;
	case "IdBattle": return CNextType.ID_BATTLE;
	case "Trio": return CNextType.TRIO;
	case "Coupon": return CNextType.COUPON;
	default: throw new Exception("Unknown content next type: " ~ name);
	}
}
/// ditto
string fromCNextType(CNextType t) { mixin(S_TRACE);
	final switch (t) {
	case CNextType.NONE: return "None";
	case CNextType.TEXT: return "Text";
	case CNextType.BOOL: return "Bool";
	case CNextType.STEP: return "Step";
	case CNextType.ID_AREA: return "IdArea";
	case CNextType.ID_BATTLE: return "IdBattle";
	case CNextType.TRIO: return "Trio";
	case CNextType.COUPON: return "Coupon";
	}
}

enum MType {
	HEAL,
	DAMAGE,
	ABSORB,
	PARALYZE,
	DIS_PARALYZE,
	POISON,
	DIS_POISON,
	GET_SKILL_POWER,
	LOSE_SKILL_POWER,
	SLEEP,
	CONFUSE,
	OVERHEAT,
	BRAVE,
	PANIC,
	NORMAL,
	BIND,
	DIS_BIND,
	SILENCE,
	DIS_SILENCE,
	FACE_UP,
	FACE_DOWN,
	ANTI_MAGIC,
	DIS_ANTI_MAGIC,
	ENHANCE_ACTION,
	ENHANCE_AVOID,
	ENHANCE_RESIST,
	ENHANCE_DEFENSE,
	VANISH_TARGET,
	VANISH_CARD,
	VANISH_BEAST,
	DEAL_ATTACK_CARD,
	DEAL_POWERFUL_ATTACK_CARD,
	DEAL_CRITICAL_ATTACK_CARD,
	DEAL_FEINT_CARD,
	DEAL_DEFENSE_CARD,
	DEAL_DISTANCE_CARD,
	DEAL_CONFUSE_CARD,
	DEAL_SKILL_CARD,
	SUMMON_BEAST,
	CANCEL_ACTION, // CardWirth 1.50
	NO_EFFECT, // Wsn.2
}

enum MArg {
	VALUE_TYPE, /// レベル比・直接等、値のタイプ。
	U_VALUE, /// ダメージ・回復量。
	A_VALUE, /// ボーナス値。
	ROUND, /// 継続ラウンド数。
	BEAST /// 召喚獣カード。
}

/// メニューのID。
enum MenuID {
	None = 0,

	File,
	Edit,
	View,
	Tool,
	Table,
	Variable,
	Help,
	Card,
	CardsAndBacks,

	DelNotUsedFile,
	CreateSubWindow,
	LeftPane,
	RightPane,
	ClosePane,
	ClosePaneExcept,
	ClosePaneLeft,
	ClosePaneRight,
	ClosePaneAll,
	New,
	Open,
	NewAtNewWindow,
	OpenAtNewWindow,
	Close,
	CloseWin,
	Save,
	SaveAs,
	Reload,
	EditScenarioHistory,
	OpenDir,
	OpenBackupDir,
	OpenPlace,
	SaveImage,
	IncludeImage,
	LookImages,
	EditLayers,
	AddLayer,
	RemoveLayer,
	ChangeVH,
	SelectConnectedResource,
	Find,
	FindID,
	IncSearch,
	CloseIncSearch,
	EditProp,
	ShowProp,
	Refresh,
	Undo,
	Redo,
	Cut,
	Copy,
	Paste,
	Delete,
	Cut1Content,
	Copy1Content,
	Delete1Content,
	PasteInsert,
	Clone,
	SelectAll,
	CopyAll,
	ToXMLText,
	TableView,
	VarView,
	CardView,
	CastView,
	SkillView,
	ItemView,
	BeastView,
	InfoView,
	FileView,
	CouponView,
	GossipView,
	CompleteStampView,
	KeyCodeView,
	CellNameView,
	CardGroupView,
	ExecEngine,
	ExecEngineAuto,
	ExecEngineMain,
	ExecEngineWithParty,
	ExecEngineWithLastParty,
	DeleteNotExistsParties,
	OuterTools,
	Settings,
	VersionInfo,
	LockToolBar,
	ResetToolBar,
	CopyAsText,
	OpenAtView,
	EventToPackage,
	StartToPackage,
	WrapTree,
	CreateContent,
	ConvertContent,
	CGroupTerminal,
	CGroupStandard,
	CGroupData,
	CGroupUtility,
	CGroupBranch,
	CGroupGet,
	CGroupLost,
	CGroupVisual,
	CGroupVariant,
	EditSummary,
	NewAreaDir,
	NewArea,
	NewBattle,
	NewPackage,
	ReNumberingAll,
	ReNumbering,
	EditScene,
	EditSceneDup,
	EditEvent,
	EditEventDup,
	SetStartArea,
	NewFlagDir,
	NewFlag,
	NewStep,
	NewVariant,
	CreateStepValues,
	PutSPChar,
	PutFlagValue,
	PutStepValue,
	PutVariantValue,
	PutColor,
	PutSkinSPChar,
	PutImageFont,
	CreateVariableEventTree,
	InitVariablesTree,
	CopyVariablePath,
	Up,
	Down,
	Reverse,
	SwapToParent,
	SwapToChild,
	OverDialog,
	UnderDialog,
	CreateDialog,
	DeleteDialog,
	CopyToAllDialogs,
	CopyToUpperDialogs,
	CopyToLowerDialogs,
	ShowParty,
	ShowMsg,
	ShowRefCards,
	FixedCards,
	FixedCells,
	FixedBackground,
	ShowGrid,
	ShowEnemyCardProp,
	ShowCard,
	ShowBack,
	NewMenuCard,
	NewEnemyCard,
	NewBack,
	NewTextCell,
	NewColorCell, // Wsn.1
	NewPCCell,
	AutoArrange,
	ManualArrange,
	PossibleToRunAway, // Wsn.3
	Mask,
	Escape,
	ChangePos,
	PosTop,
	PosBottom,
	PosLeft,
	PosRight,
	PosEven,
	NearTop,
	NearBottom,
	NearLeft,
	NearRight,
	NearCenterH,
	NearCenterV,
	NearCenter,
	ScaleMin,
	ScaleMiddle,
	ScaleMax,
	ScaleBig,
	ScaleSmall,
	ExpandBack,
	StopBGM,
	PlayBGM,
	NewEvent,
	NewEventWithDialog,
	KeyCodeTiming,
	KeyCodeTimingUse,
	KeyCodeTimingSuccess,
	KeyCodeTimingFailure,
	KeyCodeTimingHasNot,
	KeyCodeCond,
	KeyCodeCondOr,
	KeyCodeCondAnd,
	AddRangeOfRound,
	OpenAtTableView,
	OpenAtVarView,
	OpenAtCardView,
	OpenAtFileView,
	OpenAtEventView,
	Comment,
	ShowCardProp,
	ShowCardImage,
	ShowCardDetail,
	OpenImportSource,
	NewCast,
	NewSkill,
	NewItem,
	NewBeast,
	NewInfo,
	Import,
	OpenHand,
	AddHand,
	RemoveRef,
	EditEventAtTimeOfUsing,
	Hold,
	PlaySE,
	StopSE,
	NewDir,
	CopyFilePath,
	CreateArchive,
	PutQuick,
	PutSelect,
	PutContinue,
	ToScript,
	ToScriptAll,
	ToScript1Content,
	EvTemplates,
	EvTemplatesOfScenario,
	Expand,
	Collapse,
	SelectCurrentEvent,
	ResetValues,
	ResetValuesAll,
	CustomizeToolBar,
	AddTool,
	AddToolBar,
	AddToolGroup,
	ResetToolBarSettings,
	DeleteNotExistsHistory,
}

/// 格納カード・イメージのインポートオプション。
enum ImportTypeIncluded {
	Exclude, /// 外部出力する。
	Include, /// 外部にあれば格納する。
	AsIs, /// 格納されたままにしておく。
}
/// ファイル・状態変数のインポートオプション。
enum ImportTypeReference1 {
	Rename, /// インポートし、被った場合は名前を変更する。
	NoOverwrite, /// インポートするが、被った場合はインポートしない。
	Overwrite, /// インポートする。被った場合は上書きする。
	NoImport, /// インポートしない。
}
/// エリア類・カード類のインポートオプション。
enum ImportTypeReference2 {
	Rename, /// 新しいIDでインポートする。
	NoImport, /// インポートしない。
}

/// カード画像のタイプ。
enum CardImageType {
	PCNumber, /// PCの画像。
	File, /// ファイル。
	Talker /// 話者キャラクタ。
}
/// カード画像の配置形式(Wsn.2)。
enum CardImagePosition {
	Default, /// 指定無し(クラシックな位置に合わせる)。
	Center, /// 中央寄せ。
	TopLeft /// 左上起点。
}
/// マッチングタイプ(Wsn.2)。
enum MatchingType {
	And, /// 全てに一致。
	Or   /// どれか一つに一致。
}
/// 文字列からマッチングタイプを生成。
MatchingType toMatchingType(string name) { mixin(S_TRACE);
	switch (name) {
	case "And":
		return MatchingType.And;
	case "Or":
		return MatchingType.Or;
	default:
		throw new MotionException("Unknown matchingType: " ~ name);
	}
}
/// マッチングタイプを文字列へ変換。
string fromMatchingType(MatchingType r) { mixin(S_TRACE);
	final switch (r) {
	case MatchingType.And:
		return "And";
	case MatchingType.Or:
		return "Or";
	}
}
