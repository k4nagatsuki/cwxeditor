
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
	Normal, /// 正常。
	Sleep, /// 睡眠。
	Confuse, /// 混乱。
	Overheat, /// 激昂。
	Brave, /// 勇敢。
	Panic /// 恐慌。
}
/// ditto
Mentality toMentality(string s) { mixin(S_TRACE);
	switch (s) {
	case "Normal": return Mentality.Normal;
	case "Panic": return Mentality.Panic;
	case "Brave": return Mentality.Brave;
	case "Overheat": return Mentality.Overheat;
	case "Confuse": return Mentality.Confuse;
	case "Sleep": return Mentality.Sleep;
	default: throw new Exception("Unknown Mentality: " ~ s);
	}
}
/// ditto
string fromMentality(Mentality m) { mixin(S_TRACE);
	final switch (m) {
	case Mentality.Normal: return "Normal";
	case Mentality.Panic: return "Panic";
	case Mentality.Brave: return "Brave";
	case Mentality.Overheat: return "Overheat";
	case Mentality.Confuse: return "Confuse";
	case Mentality.Sleep: return "Sleep";
	}
}

/// 効果属性。
enum EffectType {
	Physic, /// 物理。
	Magic, /// 魔法。
	MagicalPhysic, /// 魔法的物理。
	PhysicalMagic, /// 物理的魔法。
	None, /// 無。
}
/// 文字列から効果属性を生成。
EffectType toEffectType(string name) { mixin(S_TRACE);
	switch (name) {
	case "Physic":
		return EffectType.Physic;
	case "Magic":
		return EffectType.Magic;
	case "MagicalPhysic":
		return EffectType.MagicalPhysic;
	case "PhysicalMagic":
		return EffectType.PhysicalMagic;
	case "None":
	case "Normal": // BUG: 古いスキンで「カード交換」「逃走」に設定されている
		return EffectType.None;
	default:
		throw new MotionException("Unknown effecttype: " ~ name);
	}
}
/// 効果属性を文字列に変換。
string fromEffectType(EffectType etyp) { mixin(S_TRACE);
	final switch (etyp) {
	case EffectType.Physic:
		return "Physic";
	case EffectType.Magic:
		return "Magic";
	case EffectType.MagicalPhysic:
		return "MagicalPhysic";
	case EffectType.PhysicalMagic:
		return "PhysicalMagic";
	case EffectType.None:
		return "None";
	}
}
/// 抵抗属性。
enum Resist {
	Avoid, /// 回避。
	Resist, /// 抵抗。
	Unfail, /// 必中。
}
/// 文字列から抵抗属性を生成。
Resist toResist(string name) { mixin(S_TRACE);
	switch (name) {
	case "Avoid":
		return Resist.Avoid;
	case "Resist":
		return Resist.Resist;
	case "Unfail":
		return Resist.Unfail;
	default:
		throw new MotionException("Unknown resist: " ~ name);
	}
}
/// 抵抗属性から文字列へ変換。
string fromResist(Resist resist) { mixin(S_TRACE);
	final switch (resist) {
	case Resist.Avoid:
		return "Avoid";
	case Resist.Resist:
		return "Resist";
	case Resist.Unfail:
		return "Unfail";
	}
}
/// 視覚効果。
enum CardVisual {
	None, /// 無し。
	Reverse, /// 反転。
	Horizontal, /// 横震動。
	Vertical, /// 縦振動。
}
/// 文字列から視覚効果を生成。
CardVisual toCardVisual(string name) { mixin(S_TRACE);
	switch (name) {
	case "None":
		return CardVisual.None;
	case "Reverse":
		return CardVisual.Reverse;
	case "Horizontal":
		return CardVisual.Horizontal;
	case "Vertical":
		return CardVisual.Vertical;
	default:
		throw new MotionException("Unknown cardvisual: " ~ name);
	}
}
/// 視覚効果から文字列へ変換。
string fromCardVisual(CardVisual vis) { mixin(S_TRACE);
	final switch (vis) {
	case CardVisual.None:
		return "None";
	case CardVisual.Reverse:
		return "Reverse";
	case CardVisual.Horizontal:
		return "Horizontal";
	case CardVisual.Vertical:
		return "Vertical";
	}
}
/// 効果属性。
enum Element {
	All, /// 全。
	Health, /// 肉体。
	Mind, /// 精神。
	Miracle, /// 神聖。
	Magic, /// 魔法。
	Fire, /// 炎。
	Ice, /// 冷気。
}
/// 文字列から効果属性を生成。
Element toElement(string name) { mixin(S_TRACE);
	switch (name) {
	case "All":
		return Element.All;
	case "Health":
		return Element.Health;
	case "Mind":
		return Element.Mind;
	case "Miracle":
		return Element.Miracle;
	case "Magic":
		return Element.Magic;
	case "Fire":
		return Element.Fire;
	case "Ice":
		return Element.Ice;
	default:
		throw new MotionException("Unknown element: " ~ name);
	}
}
/// 効果属性から文字列へ変換。
string fromElement(Element el) { mixin(S_TRACE);
	final switch (el) {
	case Element.All:
		return "All";
	case Element.Health:
		return "Health";
	case Element.Mind:
		return "Mind";
	case Element.Miracle:
		return "Miracle";
	case Element.Magic:
		return "Magic";
	case Element.Fire:
		return "Fire";
	case Element.Ice:
		return "Ice";
	}
}
/// 効果計算。
enum DamageType {
	LevelRatio, /// レベル比。
	Normal, /// 値の直接指定。
	Max, /// 最大値。
	Fixed, /// 固定値(Wsn.1)。
}
/// 文字列から効果計算方式を生成。
DamageType toDamageType(string name) { mixin(S_TRACE);
	switch (name) {
	case "LevelRatio":
		return DamageType.LevelRatio;
	case "Normal":
		return DamageType.Normal;
	case "Max":
		return DamageType.Max;
	case "Fixed":
		return DamageType.Fixed;
	default:
		throw new MotionException("Unknown damagetype: " ~ name);
	}
}
/// 効果計算方式を文字列へ変換。
string fromDamageType(DamageType dtyp) { mixin(S_TRACE);
	final switch (dtyp) {
	case DamageType.LevelRatio:
		return "LevelRatio";
	case DamageType.Normal:
		return "Normal";
	case DamageType.Max:
		return "Max";
	case DamageType.Fixed:
		return "Fixed";
	}
}

/// メンバの選択。
struct Target {
public:
	/// メンバ種別。
	enum M {
		Selected, /// 選択中メンバ。
		Unselected, /// 非選択メンバ。
		Random, /// ランダムメンバ。
		Party, /// 全員。
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
		return Target(Target.M.Selected, false);
	case "Unselected":
		return Target(Target.M.Unselected, false);
	case "Random":
		return Target(Target.M.Random, false);
	case "Party":
		return Target(Target.M.Party, false);
	case "SelectedSleep":
		return Target(Target.M.Selected, true);
	case "UnselectedSleep":
		return Target(Target.M.Unselected, true);
	case "RandomSleep":
		return Target(Target.M.Random, true);
	case "PartySleep":
		return Target(Target.M.Party, true);
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
	case Target.M.Selected:
		return targetText("Selected", targ.sleep);
	case Target.M.Unselected:
		return targetText("Unselected", targ.sleep);
	case Target.M.Random:
		return targetText("Random", targ.sleep);
	case Target.M.Party:
		return targetText("Party", targ.sleep);
	}
}

/// 精神要素。
enum Mental {
	Aggressive, /// 好戦
	Unaggressive, /// 平和
	Cheerful, /// 社交
	Uncheerful, /// 内向
	Brave, /// 勇敢
	Unbrave, /// 臆病
	Cautious, /// 慎重
	Uncautious, /// 大胆
	Trickish, /// 狡猾
	Untrickish, /// 正直
}
/// 文字列から精神要素を生成。
Mental toMental(string name) { mixin(S_TRACE);
	switch (name) {
	case "Aggressive":
		return Mental.Aggressive;
	case "Unaggressive":
		return Mental.Unaggressive;
	case "Cheerful":
		return Mental.Cheerful;
	case "Uncheerful":
		return Mental.Uncheerful;
	case "Brave":
		return Mental.Brave;
	case "Unbrave":
		return Mental.Unbrave;
	case "Cautious":
		return Mental.Cautious;
	case "Uncautious":
		return Mental.Uncautious;
	case "Trickish":
		return Mental.Trickish;
	case "Untrickish":
		return Mental.Untrickish;
	default:
		throw new MotionException("Unknown mental: " ~ name);
	}
}
///精神要素を文字列へ変換。
string fromMental(Mental m) { mixin(S_TRACE);
	final switch (m) {
	case Mental.Aggressive:
		return "Aggressive";
	case Mental.Unaggressive:
		return "Unaggressive";
	case Mental.Cheerful:
		return "Cheerful";
	case Mental.Uncheerful:
		return "Uncheerful";
	case Mental.Brave:
		return "Brave";
	case Mental.Unbrave:
		return "Unbrave";
	case Mental.Cautious:
		return "Cautious";
	case Mental.Uncautious:
		return "Uncautious";
	case Mental.Trickish:
		return "Trickish";
	case Mental.Untrickish:
		return "Untrickish";
	}
}
/// 精神要素の対立側を返す。
Mental reverseMental(Mental m) { mixin(S_TRACE);
	final switch (m) {
	case Mental.Aggressive:
		return Mental.Unaggressive;
	case Mental.Unaggressive:
		return Mental.Aggressive;
	case Mental.Cheerful:
		return Mental.Uncheerful;
	case Mental.Uncheerful:
		return Mental.Cheerful;
	case Mental.Brave:
		return Mental.Unbrave;
	case Mental.Unbrave:
		return Mental.Brave;
	case Mental.Cautious:
		return Mental.Uncautious;
	case Mental.Uncautious:
		return Mental.Cautious;
	case Mental.Trickish:
		return Mental.Untrickish;
	case Mental.Untrickish:
		return Mental.Trickish;
	}
}
/// 肉体要素。
enum Physical {
	Dex, /// 敏捷度。
	Agl, /// 器用度。
	Int, /// 知力。
	Str, /// 膂力。
	Vit, /// 生命力。
	Min, /// 精神力。
}
/// 文字列から肉体要素を生成。
Physical toPhysical(string name) { mixin(S_TRACE);
	switch (name) {
	case "Dex":
		return Physical.Dex;
	case "Agl":
		return Physical.Agl;
	case "Int":
		return Physical.Int;
	case "Str":
		return Physical.Str;
	case "Vit":
		return Physical.Vit;
	case "Min":
		return Physical.Min;
	default:
		throw new MotionException("Unknown physical: " ~ name);
	}
}
/// 肉体要素を文字列へ変換。
string fromPhysical(Physical p) { mixin(S_TRACE);
	final switch (p) {
	case Physical.Dex:
		return "Dex";
	case Physical.Agl:
		return "Agl";
	case Physical.Int:
		return "Int";
	case Physical.Str:
		return "Str";
	case Physical.Vit:
		return "Vit";
	case Physical.Min:
		return "Min";
	}
}
/// 状態。
enum Status {
	Active, /// 行動可能。
	Inactive, /// 行動不可。
	Alive, /// 生存。
	Dead, /// 非生存。
	Fine, /// 健康。
	Injured, /// 負傷。
	HeavyInjured, /// 重症。
	Unconscious, /// 意識不明。
	Poison, /// 中毒。
	Sleep, /// 睡眠。
	Bind, /// 呪縛。
	Paralyze, /// 麻痺/石化。
	Confuse, /// 混乱(CardWirth Extender 1.30～)。
	Overheat, /// 激昂(CardWirth Extender 1.30～)。
	Brave, /// 勇敢(CardWirth Extender 1.30～)。
	Panic, /// 恐慌(CardWirth Extender 1.30～)。
	Silence, /// 沈黙(CardWirth 1.50)。
	FaceUp, /// 暴露(CardWirth 1.50)。
	AntiMagic, /// 魔法無効化(CardWirth 1.50)。
	UpAction, /// 行動力上昇(CardWirth 1.50)。
	UpAvoid, /// 回避力上昇(CardWirth 1.50)。
	UpResist, /// 抵抗力上昇(CardWirth 1.50)。
	UpDefense, /// 防御力上昇(CardWirth 1.50)。
	DownAction, /// 行動力低下(CardWirth 1.50)。
	DownAvoid, /// 回避力低下(CardWirth 1.50)。
	DownResist, /// 抵抗力低下(CardWirth 1.50)。
	DownDefense, /// 防御力低下(CardWirth 1.50)。
	None, /// 状態指定無し。
}
/// 文字列から状態を生成。
Status toStatus(string name) { mixin(S_TRACE);
	switch (name) {
	case "Active":
		return Status.Active;
	case "Inactive":
		return Status.Inactive;
	case "Alive":
		return Status.Alive;
	case "Dead":
		return Status.Dead;
	case "Fine":
		return Status.Fine;
	case "Injured":
		return Status.Injured;
	case "HeavyInjured":
		return Status.HeavyInjured;
	case "Unconscious":
		return Status.Unconscious;
	case "Poison":
		return Status.Poison;
	case "Sleep":
		return Status.Sleep;
	case "Bind":
		return Status.Bind;
	case "Paralyze":
		return Status.Paralyze;
	case "Confuse":
		return Status.Confuse;
	case "Overheat":
		return Status.Overheat;
	case "Brave":
		return Status.Brave;
	case "Panic":
		return Status.Panic;
	case "Silence":
		return Status.Silence;
	case "FaceUp":
		return Status.FaceUp;
	case "AntiMagic":
		return Status.AntiMagic;
	case "UpAction":
		return Status.UpAction;
	case "UpAvoid":
		return Status.UpAvoid;
	case "UpResist":
		return Status.UpResist;
	case "UpDefense":
		return Status.UpDefense;
	case "DownAction":
		return Status.DownAction;
	case "DownAvoid":
		return Status.DownAvoid;
	case "DownResist":
		return Status.DownResist;
	case "DownDefense":
		return Status.DownDefense;
	case "None":
		return Status.None;
	default:
		throw new MotionException("Unknown status: " ~ name);
	}
}
/// 状態を文字列へ変換。
string fromStatus(Status stat) { mixin(S_TRACE);
	final switch (stat) {
	case Status.Active:
		return "Active";
	case Status.Inactive:
		return "Inactive";
	case Status.Alive:
		return "Alive";
	case Status.Dead:
		return "Dead";
	case Status.Fine:
		return "Fine";
	case Status.Injured:
		return "Injured";
	case Status.HeavyInjured:
		return "HeavyInjured";
	case Status.Unconscious:
		return "Unconscious";
	case Status.Poison:
		return "Poison";
	case Status.Sleep:
		return "Sleep";
	case Status.Bind:
		return "Bind";
	case Status.Paralyze:
		return "Paralyze";
	case Status.Confuse:
		return "Confuse";
	case Status.Overheat:
		return "Overheat";
	case Status.Brave:
		return "Brave";
	case Status.Panic:
		return "Panic";
	case Status.Silence:
		return "Silence";
	case Status.FaceUp:
		return "FaceUp";
	case Status.AntiMagic:
		return "AntiMagic";
	case Status.UpAction:
		return "UpAction";
	case Status.UpAvoid:
		return "UpAvoid";
	case Status.UpResist:
		return "UpResist";
	case Status.UpDefense:
		return "UpDefense";
	case Status.DownAction:
		return "DownAction";
	case Status.DownAvoid:
		return "DownAvoid";
	case Status.DownResist:
		return "DownResist";
	case Status.DownDefense:
		return "DownDefense";
	case Status.None:
		return "None";
	}
}
/// 適用範囲。
enum Range {
	Selected, /// 選択中メンバ。
	Random, /// 誰か一人。
	Party, /// パーティ全員。
	Backpack, /// 荷物袋。
	PartyAndBackpack, /// 全員と荷物袋。
	Field, /// フィールド全体。
	CouponHolder, /// 称号所有者(Wsn.2)。
	CardTarget, /// カードの効果対象(Wsn.2)。
	SelectedCard, /// 選択カード(Wsn.3)。
}
/// 文字列から適用範囲を生成。
Range toRange(string name) { mixin(S_TRACE);
	switch (name) {
	case "Selected":
		return Range.Selected;
	case "Random":
		return Range.Random;
	case "Party":
		return Range.Party;
	case "Backpack":
		return Range.Backpack;
	case "PartyAndBackpack":
		return Range.PartyAndBackpack;
	case "Field":
		return Range.Field;
	case "CouponHolder":
		return Range.CouponHolder;
	case "CardTarget":
		return Range.CardTarget;
	case "SelectedCard":
		return Range.SelectedCard;
	default:
		throw new MotionException("Unknown targets: " ~ name);
	}
}
/// 適用範囲を文字列へ変換。
string fromRange(Range r) { mixin(S_TRACE);
	final switch (r) {
	case Range.Selected:
		return "Selected";
	case Range.Random:
		return "Random";
	case Range.Party:
		return "Party";
	case Range.Backpack:
		return "Backpack";
	case Range.PartyAndBackpack:
		return "PartyAndBackpack";
	case Range.Field:
		return "Field";
	case Range.CouponHolder:
		return "CouponHolder";
	case Range.CardTarget:
		return "CardTarget";
	case Range.SelectedCard:
		return "SelectedCard";
	}
}
/// 効果対象や話者選択時に現れる適用範囲。
Range[] RANGE_MEMBER = [Range.Selected, Range.Random, Range.Party];

/// キャスト選択範囲。CardWirth Extender 1.30～
enum CastRange {
	Party = 0b0001, /// パーティ全体。
	Enemy = 0b0010, /// 敵全体。
	Npc   = 0b0100, /// 同行キャスト全体。
}
/// 文字列からキャスト選択範囲を生成。
CastRange toCastRange(string name) { mixin(S_TRACE);
	switch (name) {
	case "Party":
		return CastRange.Party;
	case "Enemy":
		return CastRange.Enemy;
	case "Npc":
		return CastRange.Npc;
	default:
		throw new MotionException("Unknown targets: " ~ name);
	}
}
/// キャスト選択範囲を文字列へ変換。
string fromCastRange(CastRange r) { mixin(S_TRACE);
	final switch (r) {
	case CastRange.Party:
		return "Party";
	case CastRange.Enemy:
		return "Enemy";
	case CastRange.Npc:
		return "Npc";
	}
}
/// 能力修正。
enum Enhance {
	Action, /// 行動。
	Avoid, /// 回避。
	Resist, /// 抵抗。
	Defense, /// 防御。
}
/// 文字列から能力修正種別を生成。
Enhance toEnhance(string name) { mixin(S_TRACE);
	switch (name) {
	case "Action":
		return Enhance.Action;
	case "Avoid":
		return Enhance.Avoid;
	case "Resist":
		return Enhance.Resist;
	case "Defense":
		return Enhance.Defense;
	default:
		throw new Exception("Unknown enhance: " ~ name);
	}
}
/// 能力修正種別を文字列へ変換。
string fromEnhance(Enhance r) { mixin(S_TRACE);
	final switch (r) {
	case Enhance.Action:
		return "Action";
	case Enhance.Avoid:
		return "Avoid";
	case Enhance.Resist:
		return "Resist";
	case Enhance.Defense:
		return "Defense";
	}
}
/// カードの希少度。
enum Premium {
	Normal, /// 日用品。
	Rare, /// 希少品。
	Premium, /// 貴重品。
}
/// 文字列から希少度を生成。
Premium toPremium(string name) { mixin(S_TRACE);
	switch (name) {
	case "Normal":
		return Premium.Normal;
	case "Rare":
		return Premium.Rare;
	case "Premium":
		return Premium.Premium;
	default:
		throw new Exception("Unknown premium: " ~ name);
	}
}
/// 希少度を文字列へ変換。
string fromPremium(Premium r) { mixin(S_TRACE);
	final switch (r) {
	case Premium.Normal:
		return "Normal";
	case Premium.Rare:
		return "Rare";
	case Premium.Premium:
		return "Premium";
	}
}
/// カード効果の標的。
enum CardTarget {
	None, /// 対象無し。
	User, /// 使用者。
	Party, /// 味方。
	Enemy, /// 敵方。
	Both, /// 双方。
}
/// 文字列からカード効果標的を生成。
CardTarget toCardTarget(string name) { mixin(S_TRACE);
	switch (name) {
	case "None":
		return CardTarget.None;
	case "User":
		return CardTarget.User;
	case "Party":
		return CardTarget.Party;
	case "Enemy":
		return CardTarget.Enemy;
	case "Both":
		return CardTarget.Both;
	default:
		throw new Exception("Unknown card target: " ~ name);
	}
}
/// カード効果標的を文字列へ変換。
string fromCardTarget(CardTarget r) { mixin(S_TRACE);
	final switch (r) {
	case CardTarget.None:
		return "None";
	case CardTarget.User:
		return "User";
	case CardTarget.Party:
		return "Party";
	case CardTarget.Enemy:
		return "Enemy";
	case CardTarget.Both:
		return "Both";
	}
}

/// メッセージの話者。
enum Talker {
	Selected, /// 選択中メンバ。
	Unselected, /// 非選択メンバ。
	Random, /// ランダムメンバ。
	Card, /// カード。
	Valued, /// 評価メンバ。
}

/// Talkerを文字列に変換する。
string fromTalker(Talker talker) { mixin(S_TRACE);
	final switch (talker) {
	case Talker.Selected:
		return "Selected";
	case Talker.Unselected:
		return "Unselected";
	case Talker.Random:
		return "Random";
	case Talker.Card:
		return "Card";
	case Talker.Valued:
		return "Valued";
	}
}

/// 背景遷移エフェクト。
enum Transition {
	Default, /// ユーザ指定。
	None, /// アニメーション無し。
	Blinds, /// ブラインド式。
	PixelDissolve, /// ピクセルディゾルブ式。
	Fade, /// フェード式。
}
/// ditto
Transition[] ALL_TRANSITION = [
	Transition.Default,
	Transition.None,
	Transition.Blinds,
	Transition.PixelDissolve,
	Transition.Fade,
];
/// 文字列から背景遷移エフェクトを生成。
Transition toTransition(string name) { mixin(S_TRACE);
	switch (name) {
	case "Default":
		return Transition.Default;
	case "None":
		return Transition.None;
	case "Blinds":
		return Transition.Blinds;
	case "PixelDissolve":
		return Transition.PixelDissolve;
	case "Fade":
		return Transition.Fade;
	default:
		throw new Exception("Unknown transition: " ~ name);
	}
}
/// 背景遷移エフェクトを文字列へ変換。
string fromTransition(Transition t) { mixin(S_TRACE);
	final switch (t) {
	case Transition.Default:
		return "Default";
	case Transition.None:
		return "None";
	case Transition.Blinds:
		return "Blinds";
	case Transition.PixelDissolve:
		return "PixelDissolve";
	case Transition.Fade:
		return "Fade";
	}
}

/// 効果カードタイプ。
enum EffectCardType {
	All, /// 全種類。
	Skill, /// 特殊技能。
	Item, /// アイテム。
	Beast, /// 召喚獣。
	Hand, /// 手札(Wsn.2)。
}
/// ditto
EffectCardType toEffectCardType(string name) { mixin(S_TRACE);
	switch (name) {
	case "All":   return EffectCardType.All;
	case "Skill": return EffectCardType.Skill;
	case "Item":  return EffectCardType.Item;
	case "Beast": return EffectCardType.Beast;
	case "Hand":  return EffectCardType.Hand;
	default: throw new Exception("Unknown card type: " ~ name);
	}
}
/// ditto
string fromEffectCardType(EffectCardType t) { mixin(S_TRACE);
	final switch (t) {
	case EffectCardType.All:   return "All";
	case EffectCardType.Skill: return "Skill";
	case EffectCardType.Item:  return "Item";
	case EffectCardType.Beast: return "Beast";
	case EffectCardType.Hand:  return "Hand";
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

/// 吸収効果での吸収者(Wsn.4)。
enum AbsorbTo {
	None, /// 吸収者無し。
	Selected, /// 選択メンバ。
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
	Start,
	StartBattle,
	End,
	EndBadEnd,
	ChangeArea,
	ChangeBgImage,
	Effect,
	EffectBreak,
	LinkStart,
	LinkPackage,
	TalkMessage,
	TalkDialog,
	PlayBgm,
	PlaySound,
	Wait,
	ElapseTime,
	CallStart,
	CallPackage,
	BranchFlag,
	BranchMultiStep,
	BranchStep,
	BranchSelect,
	BranchAbility,
	BranchRandom,
	BranchLevel,
	BranchStatus,
	BranchPartyNumber,
	BranchArea,
	BranchBattle,
	BranchIsBattle,
	BranchCast,
	BranchItem,
	BranchSkill,
	BranchInfo,
	BranchBeast,
	BranchMoney,
	BranchCoupon,
	BranchCompleteStamp,
	BranchGossip,
	SetFlag,
	SetStep,
	SetStepUp,
	SetStepDown,
	ReverseFlag,
	CheckFlag,
	GetCast,
	GetItem,
	GetSkill,
	GetInfo,
	GetBeast,
	GetMoney,
	GetCoupon,
	GetCompleteStamp,
	GetGossip,
	LoseCast,
	LoseItem,
	LoseSkill,
	LoseInfo,
	LoseBeast,
	LoseMoney,
	LoseCoupon,
	LoseCompleteStamp,
	LoseGossip,
	ShowParty,
	HideParty,
	Redisplay,
	SubstituteStep, /// ステップ代入(CardWirth Extender 1.30)。
	SubstituteFlag, /// フラグ代入(CardWirth Extender 1.30)。
	BranchStepCmp, /// ステップ値分岐(CardWirth Extender 1.30)。
	BranchFlagCmp, /// フラグ値分岐(CardWirth Extender 1.30)。
	BranchRandomSelect, /// ランダム選択(CardWirth Extender 1.30)。
	BranchKeyCode, /// キーコード所持分岐(CardWirth 1.50)。
	CheckStep, /// ステップ判定(CardWirth 1.50)。
	BranchRound, /// ラウンド分岐(CardWirth 1.50)。
	MoveBgImage, /// 背景再配置(Wsn.1)。
	ReplaceBgImage, /// 背景置換(Wsn.1)。
	LoseBgImage, /// 背景削除(Wsn.1)。
	BranchMultiCoupon, /// クーポン多岐分岐(Wsn.2)。
	BranchMultiRandom, /// ランダム多岐分岐(Wsn.2)。
	MoveCard, /// カード再配置(Wsn.3)。
	ChangeEnvironment, /// 状況設定(Wsn.4)。
	BranchVariant, /// コモン分岐(Wsn.4)。
	SetVariant, /// コモン設定(Wsn.4)。
	CheckVariant, /// コモン判定(Wsn.4)。
}

/// WSN形式のシナリオでのみ使用できるイベントコンテントか。
@property
bool isWsnContent(CType cType) { mixin(S_TRACE);
	with (CType) switch (cType) {
	case MoveBgImage: // Wsn.1
	case ReplaceBgImage: // Wsn.1
	case LoseBgImage: // Wsn.1
	case BranchMultiCoupon: // Wsn.2
	case BranchMultiRandom: // Wsn.2
	case MoveCard: // Wsn.3
	case ChangeEnvironment: // Wsn.4
	case BranchVariant: // Wsn.4
	case SetVariant: // Wsn.4
	case CheckVariant: // Wsn.4
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
	Area,
	Battle,
	Package,
	Flag,
	Step,
	BgmPath,
	BgmChannel,
	BgmVolume,
	BgmLoopCount,
	BgmFadeIn,
	SoundPath,
	SoundChannel,
	SoundVolume,
	SoundLoopCount,
	SoundFadeIn,
	Cast,
	Item,
	Skill,
	Beast,
	Info,
	Motions,
	Text,
	Dialogs,
	Start,
	Coupon,
	Gossip,
	CompleteStamp,
	Mental,
	Physical,
	Status,
	Range,
	CardVisual,
	TargetS,
	TalkerC,
	TalkerNC,
	EffectType,
	Resist,
	Transition,
	TargetAll,
	SelectionMethod,
	Average,
	Complete,
	UnsignedLevel,
	SignedLevel,
	SuccessRate,
	TransitionSpeed,
	Percent,
	FlagValue,
	StepValue,
	CouponValue,
	PartyNumber,
	CardNumber,
	Money,
	Wait,
	BgImages,
	Step2, /// 操作ターゲットステップ(CardWirth Extender 1.30～)。
	Flag2, /// 操作ターゲットフラグ(CardWirth Extender 1.30～)。
	CastRange, /// キャスト選択範囲(CardWirth Extender 1.30～)。
	LevelMin, /// 下限レベル(CardWirth Extender 1.30～)。
	LevelMax, /// 上限レベル(CardWirth Extender 1.30～)。
	KeyCodeRange, /// キーコード所持判定範囲(CardWirth 1.50)。
	KeyCode, /// キーコード(CardWirth 1.50)。
	Coupons, /// 得点付きクーポン群(CardWirth 1.50)。
	InitValue, /// 評価メンバ初期点(CardWirth 1.50)。
	Comparison4, /// 4路比較条件(CardWirth 1.50)。
	Comparison3, /// 3路比較条件(CardWirth 1.50)。
	Round, /// ラウンド(CardWirth 1.50)。
	CellName, /// セル名称(Wsn.1)。
	PositionType, /// 位置形式(Wsn.1)。
	X, /// 位置(Wsn.1)。
	Y, /// 位置(Wsn.1)。
	SizeType, /// サイズ形式(Wsn.1)。
	Width, /// サイズ(Wsn.1)。
	Height, /// サイズ(Wsn.1)。
	DoAnime, /// JPY1アニメーションを実行する(Wsn.1)。
	IgnoreEffectBooster, /// エフェクトブースター関係のセルを無視する(Wsn.1)。
	SelectionColumns, /// 後続選択肢の列数(Wsn.1)。
	StartAction, /// キャスト同行時の戦闘行動開始タイミング(Wsn.2)。
	Ignite, /// イベントの発火有無(Wsn.2)。
	KeyCodes, /// イベント発火のキーコード(Wsn.2)。
	TargetIsSkill, /// 特殊技能カードが対象か(Wsn.2)。
	TargetIsItem, /// アイテムカードが対象か(Wsn.2)。
	TargetIsBeast, /// 召喚獣カードが対象か(Wsn.2)。
	TargetIsHand, /// 戦闘時の手札が対象か(Wsn.2)。
	HoldingCoupon, /// 範囲で称号所持者を指定した時の称号名(Wsn.2)。
	RefAbility, /// 選択メンバの能力参照(Wsn.2)。
	CenteringX, /// メッセージを横方向に中央寄せして表示する(Wsn.2)。
	CenteringY, /// メッセージを縦方向に中央寄せして表示する(Wsn.2)。
	BoundaryCheck, /// メッセージの禁則処理(Wsn.2)。
	CouponNames, /// 複数クーポン名(Wsn.2)。
	MatchingType, /// マッチングタイプ(Wsn.2)。
	SelectCard, /// 選択カードを変更する(Wsn.3)。
	SelectTalker, /// 話者を選択する(Wsn.3)。
	CardGroup, /// カードグループ(Wsn.3)。
	Scale, /// スケール(Wsn.3)。
	Layer, /// レイヤ(Wsn.3)。
	ConsumeCard, /// 使用中のカードを消費する(Wsn.3)。
	InvertResult, /// 条件に合わない場合に成功とする(Wsn.4)。
	CardSpeed, /// カードアニメーション速度(Wsn.4)。
	OverrideCardSpeed, /// 速度設定をカード本体の設定より優先する(Wsn.4)。
	BackpackEnabled, /// 荷物袋の使用可否(Wsn.4)。
	Variant, /// コモン(Wsn.4)。
	Expression, /// 式(Wsn.4)。
	ExpandSPChars, /// クーポン・ゴシップで特殊文字を展開する(Wsn.4)。
	InitialEffect, /// 初期効果の有無(Wsn.4)。
	InitialSoundPath, /// 初期音声(Wsn.4)。
	InitialSoundChannel, /// 初期音声再生チャネル(未使用)。
	InitialSoundVolume, /// 初期音声音量(Wsn.4)。
	InitialSoundLoopCount, /// 初期音声再生回数(Wsn.4)。
	InitialSoundFadeIn, /// 初期音声フェードイン時間(未使用)。
	AbsorbTo, /// 吸収効果での吸収者(Wsn.4)。
}

/// 後続コンテントのnameの型。
enum CNextType {
	None, /// 無し。
	Text, /// テキスト。
	Bool, /// True/False。
	Step, /// ステップ値。
	IdArea, /// エリアID。
	IdBattle, /// バトルID。
	Trio, /// 大なり、少なり、一致(CardWirth Extender 1.30)。
	Coupon, /// 称号(Wsn.2)。
}
/// ditto
CNextType toCNextType(string name) { mixin(S_TRACE);
	switch (name) {
	case "None": return CNextType.None;
	case "Text": return CNextType.Text;
	case "Bool": return CNextType.Bool;
	case "Step": return CNextType.Step;
	case "IdArea": return CNextType.IdArea;
	case "IdBattle": return CNextType.IdBattle;
	case "Trio": return CNextType.Trio;
	case "Coupon": return CNextType.Coupon;
	default: throw new Exception("Unknown content next type: " ~ name);
	}
}
/// ditto
string fromCNextType(CNextType t) { mixin(S_TRACE);
	final switch (t) {
	case CNextType.None: return "None";
	case CNextType.Text: return "Text";
	case CNextType.Bool: return "Bool";
	case CNextType.Step: return "Step";
	case CNextType.IdArea: return "IdArea";
	case CNextType.IdBattle: return "IdBattle";
	case CNextType.Trio: return "Trio";
	case CNextType.Coupon: return "Coupon";
	}
}

enum MType {
	Heal,
	Damage,
	Absorb,
	Paralyze,
	DisParalyze,
	Poison,
	DisPoison,
	GetSkillPower,
	LoseSkillPower,
	Sleep,
	Confuse,
	Overheat,
	Brave,
	Panic,
	Normal,
	Bind,
	DisBind,
	Silence,
	DisSilence,
	FaceUp,
	FaceDown,
	AntiMagic,
	DisAntiMagic,
	EnhanceAction,
	EnhanceAvoid,
	EnhanceResist,
	EnhanceDefense,
	VanishTarget,
	VanishCard,
	VanishBeast,
	DealAttackCard,
	DealPowerfulAttackCard,
	DealCriticalAttackCard,
	DealFeintCard,
	DealDefenseCard,
	DealDistanceCard,
	DealConfuseCard,
	DealSkillCard,
	SummonBeast,
	CancelAction, // CardWirth 1.50
	NoEffect, // Wsn.2
}

enum MArg {
	ValueType, /// レベル比・直接等、値のタイプ。
	UValue, /// ダメージ・回復量。
	AValue, /// ボーナス値。
	Round, /// 継続ラウンド数。
	Beast /// 召喚獣カード。
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
	EditImportHistory,
	EditExecutedPartyHistory,
	PutParty,
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
	AddItem,
	DelItem,
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
	ConvertCouponType,
	ConvertCouponTypeNormal,
	ConvertCouponTypeHide,
	ConvertCouponTypeSystem,
	ConvertCouponTypeDur,
	ConvertCouponTypeDurBattle,
	CopyTypeConvertedCoupon,
	CopyTypeConvertedCouponNormal,
	CopyTypeConvertedCouponHide,
	CopyTypeConvertedCouponSystem,
	CopyTypeConvertedCouponDur,
	CopyTypeConvertedCouponDurBattle,
	AddInitialCoupons,
	ReverseSignOfValues,
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
	SortWithPosition,
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
	CopyColor1ToColor2,
	CopyColor2ToColor1,
	ExchangeColors,
	StopBGM,
	PlayBGM,
	NewEvent,
	NewEventWithDialog,
	KeyCodeTiming,
	KeyCodeTimingUse,
	KeyCodeTimingSuccess,
	KeyCodeTimingFailure,
	KeyCodeTimingHasNot,
	CopyTimingConvertedKeyCode,
	CopyTimingConvertedKeyCodeUse,
	CopyTimingConvertedKeyCodeSuccess,
	CopyTimingConvertedKeyCodeFailure,
	CopyTimingConvertedKeyCodeHasNot,
	AddKeyCodesByFeatures,
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
	SelectImportSource,
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
	EditSelection,
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
	SelectIcon,
	SelectPresetIcon,
	DeleteIcon,
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
