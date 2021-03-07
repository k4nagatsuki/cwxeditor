
module cwx.expression;

import cwx.flag;
import cwx.msgutils;
import cwx.path;
import cwx.props;
import cwx.summary;
import cwx.textholder;
import cwx.types;
import cwx.usecounter;
import cwx.utils;

import std.algorithm;
import std.array;
import std.ascii;
import std.conv;
import std.math;
import std.random;
import std.regex;
import std.string;
import std.typecons;
import std.utf;

/// 式。
class Expression : CWXPath, ISimpleTextHolder, ChgFlagCallback, ChgStepCallback, ChgVariantCallback,
	ChgCouponCallback, ChgGossipCallback {
private:
	string _text;
	FlagUser[] _flags;
	StepUser[] _steps;
	VariantUser[] _variants;
	CouponUser[] _coupons;
	GossipUser[] _gossips;
	UseCounter _uc = null;
	CWXPath _ucOwner = null;
	void delegate() _changed = null;
	const(Part)[] _expr;

public:
	/// 変更ハンドラを登録する。
	@property
	void changeHandler(void delegate() change) { mixin(S_TRACE);
		_changed = change;
	}
	override
	void changed() { mixin(S_TRACE);
		if (_changed) _changed();
	}

	@property
	override
	const string text() { return _text; }
	@property
	override
	void text(string text) { mixin(S_TRACE);
		text = text.replace("\r\n", "\n").replace("\r", "\n");
		if (_text == text) return;
		changed();
		removeTextUseCounter();

		_text = text;

		_flags = [];
		_steps = [];
		_variants = [];
		_coupons = [];
		_gossips = [];

		ExprError[] err;
		_expr = .parseExpression(null, text, err);
		void recurse(const(Part)[] expr) { mixin(S_TRACE);
			foreach (t; expr) { mixin(S_TRACE);
				if (auto expr2 = cast(Expr)t) { mixin(S_TRACE);
					recurse(expr2.parts);
					continue;
				}
				auto func = cast(Function)t;
				if (!func) continue;
				if (func.args.length == 0) continue;
				recurse(func.args);
				if (func.funcName.toLower() == "findcoupon") { mixin(S_TRACE);
					if (func.args.length < 2) continue;
					auto a = cast(StringValue)func.args[1];
					if (!a) continue;
					auto id = a.strVal;
					if (id == "") continue;
					auto u = new CouponUser(this, true);
					if (_uc) u.setUseCounter(_uc, _ucOwner);
					u.coupon = id;
					_coupons ~= u;
					continue;
				}
				auto a = cast(StringValue)func.args[0];
				if (!a) continue;
				auto id = a.strVal;
				if (id == "") continue;
				switch (func.funcName.toLower()) {
				case "var":
					auto u = new VariantUser(this);
					if (_uc) u.setUseCounter(_uc);
					u.variant = id;
					_variants ~= u;
					break;
				case "flagvalue":
				case "flagtext":
					auto u = new FlagUser(this);
					if (_uc) u.setUseCounter(_uc);
					u.flag = id;
					_flags ~= u;
					break;
				case "stepvalue":
				case "steptext":
				case "stepmax":
					auto u = new StepUser(this);
					if (_uc) u.setUseCounter(_uc);
					u.step = id;
					_steps ~= u;
					break;
				case "findgossip":
					auto u = new GossipUser(this, true);
					if (_uc) u.setUseCounter(_uc, _ucOwner);
					u.gossip = id;
					_gossips ~= u;
					break;
				default:
					break;
				}
			}
		}
		recurse(_expr);
	} unittest { mixin(UTPerf);
		auto exp = new Expression;
		exp.text = `VAR("testvar")~@"testvar"~FlagValue("testflag")~FlagText("testflag")~StepValue("teststep")~StepText("TestStep")~StepMax("TESTSTEP")`;
		assert (std.algorithm.sort(exp.flagsInText).array() == ["testflag", "testflag"]);
		assert (std.algorithm.sort(exp.stepsInText).array() == ["TESTSTEP", "TestStep", "teststep"]);
		assert (std.algorithm.sort(exp.variantsInText).array() == ["testvar", "testvar"]);
		auto uc = new UseCounter(null);
		exp.setUseCounter(uc, null);
		uc.change(toFlagId("testflag"), toFlagId("_replflag_"));
		uc.change(toStepId("TestStep"), toStepId("RplStp"));
		uc.change(toVariantId("testvar"), toVariantId("_replvar_"));
		assert (exp.text == `VAR("_replvar_")~@"_replvar_"~FlagValue("_replflag_")~FlagText("_replflag_")~StepValue("teststep")~StepText("RplStp")~StepMax("TESTSTEP")`, exp.text);
		assert (std.algorithm.sort(exp.flagsInText).array() == ["_replflag_", "_replflag_"]);
		assert (std.algorithm.sort(exp.stepsInText).array() == ["RplStp", "TESTSTEP", "teststep"]);
		assert (std.algorithm.sort(exp.variantsInText).array() == ["_replvar_", "_replvar_"]);

		exp.text = `var("テストコモン1") + min(99999999.999, @"テストコモン1" * @"テストコモン1") + @"テストコモン1"`;
		assert (std.algorithm.sort(exp.flagsInText).array() == []);
		assert (std.algorithm.sort(exp.stepsInText).array() == []);
		assert (std.algorithm.sort(exp.variantsInText).array() == ["テストコモン1", "テストコモン1", "テストコモン1", "テストコモン1"]);
		uc.change(toVariantId("テストコモン1"), toVariantId("コモン2"));
		assert (exp.text == `var("コモン2") + min(99999999.999, @"コモン2" * @"コモン2") + @"コモン2"`, exp.text);
		assert (std.algorithm.sort(exp.flagsInText).array() == []);
		assert (std.algorithm.sort(exp.stepsInText).array() == []);
		assert (std.algorithm.sort(exp.variantsInText).array() == ["コモン2", "コモン2", "コモン2", "コモン2"]);

		exp.text = `FINDCOUPON(SELECTED(), "test*")~FINDGOSSIP("TEST*")`;
		assert (std.algorithm.sort(exp.couponsInText).array() == ["test*"]);
		assert (std.algorithm.sort(exp.gossipsInText).array() == ["TEST*"]);
		uc.change(toCouponId("test*"), toCouponId("TESTCOUPON"));
		uc.change(toGossipId("TEST*"), toGossipId("TESTGOSSIP"));
		assert (exp.text == `FINDCOUPON(SELECTED(), "TESTCOUPON")~FINDGOSSIP("TESTGOSSIP")`, exp.text);
		assert (std.algorithm.sort(exp.couponsInText).array() == ["TESTCOUPON"]);
		assert (std.algorithm.sort(exp.gossipsInText).array() == ["TESTGOSSIP"]);
	}

	/// 式にあるエラーを検出して返す。
	const
	ExprError[] getExpressionErrors(in CProps prop, in VariableInfo vInfo) { mixin(S_TRACE);
		ExprError[] err;
		auto expr = .parseExpression(prop, text, err);
		if (err.length) return err;
		if (!expr.length) return err;
		.calculate(prop, EvalMode.TypeCheck, vInfo, expr, err);
		return err;
	}

	/// 戻り値のタイプを推論して返す。
	/// 推論できない場合はVariantVal(false)を返す。
	const
	VariantVal returnValue(in CProps prop) { mixin(S_TRACE);
		ExprError[] err;
		string[char] names;
		VarValue[string] flags, steps, variants, sysSteps;
		auto vInfo = VariableInfo(prop, null, null, "1.50", names, flags, steps, variants, sysSteps);
		return .partToVariantVal(.calculate(prop, EvalMode.TypeCheck, vInfo, _expr, err));
	}

	@property
	override
	const string[] flagsInText() { mixin(S_TRACE);
		return .map!(u => u.flag)(_flags).array();
	}
	@property
	override
	const string[] stepsInText() { mixin(S_TRACE);
		return .map!(u => u.step)(_steps).array();
	}
	@property
	override
	const string[] variantsInText() { mixin(S_TRACE);
		return .map!(u => u.variant)(_variants).array();
	}

	@property
	const string[] couponsInText() { mixin(S_TRACE);
		return .map!(u => u.coupon)(_coupons).array();
	}
	@property
	const string[] gossipsInText() { mixin(S_TRACE);
		return .map!(u => u.gossip)(_gossips).array();
	}

	/// 使用回数カウンタ。
	@property
	inout
	inout(UseCounter) useCounter() { return _uc; }

	@property
	override
	inout
	inout(CWXPath) ucOwner() { return _ucOwner; }
	@property
	override
	void setUseCounter(UseCounter uc, CWXPath ucOwner) { mixin(S_TRACE);
		.each!(u => u.setUseCounter(uc))(_flags);
		.each!(u => u.setUseCounter(uc))(_steps);
		.each!(u => u.setUseCounter(uc))(_variants);
		.each!(u => u.setUseCounter(uc, ucOwner))(_coupons);
		.each!(u => u.setUseCounter(uc, ucOwner))(_gossips);
		_uc = uc;
		_ucOwner = ucOwner;
	}
	private void removeTextUseCounter() { mixin(S_TRACE);
		.each!(u => u.removeUseCounter())(_flags);
		.each!(u => u.removeUseCounter())(_steps);
		.each!(u => u.removeUseCounter())(_variants);
		.each!(u => u.removeUseCounter())(_coupons);
		.each!(u => u.removeUseCounter())(_gossips);
	}
	override
	void removeUseCounter() { mixin(S_TRACE);
		removeTextUseCounter();
		_uc = null;
		_ucOwner = null;
	}

	/// 個別に状態変数パスを変更する。
	void changeInText(size_t index, FlagId id) { mixin(S_TRACE);
		_flags[index].change(id);
	}
	/// ditto
	void changeInText(size_t index, StepId id) { mixin(S_TRACE);
		_steps[index].change(id);
	}
	/// ditto
	void changeInText(size_t index, VariantId id) { mixin(S_TRACE);
		_variants[index].change(id);
	}
	/// ditto
	void changeInText(size_t index, CouponId id) { mixin(S_TRACE);
		_coupons[index].change(id);
	}
	/// ditto
	void changeInText(size_t index, GossipId id) { mixin(S_TRACE);
		_gossips[index].change(id);
	}

	private void changeCallbackImpl(ID)(ID oldVal, ID newVal) { mixin(S_TRACE);
		string[size_t] repls;
		void recurse(const(Part)[] expr) { mixin(S_TRACE);
			foreach (t; expr) { mixin(S_TRACE);
				if (auto expr2 = cast(Expr)t) { mixin(S_TRACE);
					recurse(expr2.parts);
					continue;
				}
				auto func = cast(Function)t;
				if (!func) continue;
				if (func.args.length == 0) continue;
				recurse(func.args);
				static if (is(ID:CouponId)) {
					if (func.funcName.toLower() == "findcoupon") { mixin(S_TRACE);
						if (func.args.length < 2) continue;
						auto a = cast(StringValue)func.args[1];
						if (!a) continue;
						auto id = a.strVal;
						if (id != cast(string)oldVal) continue;
						repls[a.token.index] = a.token.token;
						continue;
					}
				}
				auto a = cast(StringValue)func.args[0];
				if (!a) continue;
				auto id = a.strVal;
				if (id != cast(string)oldVal) continue;
				switch (func.funcName.toLower()) {
				case "var":
					static if (is(ID:VariantId)) {
						repls[a.token.index] = a.token.token;
					}
					break;
				case "flagvalue":
				case "flagtext":
					static if (is(ID:FlagId)) {
						repls[a.token.index] = a.token.token;
					}
					break;
				case "stepvalue":
				case "steptext":
				case "stepmax":
					static if (is(ID:StepId)) {
						repls[a.token.index] = a.token.token;
					}
					break;
				case "findgossip":
					static if (is(ID:GossipId)) {
						repls[a.token.index] = a.token.token;
					}
					break;
				default:
					break;
				}
			}
		}
		recurse(_expr);
		if (repls.length == 0) return;
		auto text2 = text;
		foreach_reverse (index; std.algorithm.sort(repls.keys)) { mixin(S_TRACE);
			auto token = repls[index];
			text2 = text2[0 .. index] ~ "\"" ~ (cast(string)newVal).replace("\"", "\"\"") ~ "\"" ~ text2[index + token.length .. $];
		}
		text = text2;
	}

	override
	bool changeCallback(FlagId oldVal, FlagId newVal) { mixin(S_TRACE);
		changeCallbackImpl(oldVal, newVal);
		changed();
		return true;
	}
	override
	bool changeCallback(StepId oldVal, StepId newVal) { mixin(S_TRACE);
		changeCallbackImpl(oldVal, newVal);
		changed();
		return true;
	}
	override
	bool changeCallback(VariantId oldVal, VariantId newVal) { mixin(S_TRACE);
		changeCallbackImpl(oldVal, newVal);
		changed();
		return true;
	}
	override
	bool changeCallback(CouponId oldVal, CouponId newVal) { mixin(S_TRACE);
		changeCallbackImpl(oldVal, newVal);
		changed();
		return true;
	}
	override
	bool changeCallback(GossipId oldVal, GossipId newVal) { mixin(S_TRACE);
		changeCallbackImpl(oldVal, newVal);
		changed();
		return true;
	}

	/// このSimpleTextHolderの所持者。
	@property
	CWXPath owner() { return _owner; }
	private CWXPath _owner = null;
	@property
	package void owner(CWXPath owner) { _owner = owner; }
	@property
	string cwxPath(bool id) { mixin(S_TRACE);
		if (_owner) { mixin(S_TRACE);
			return cpjoin(_owner, "expr", id);
		}
		return "";
	}
	CWXPath findCWXPath(string path) { mixin(S_TRACE);
		if (cpempty(path)) return this;
		return null;
	}
	@property
	inout
	inout(CWXPath)[] cwxChilds() { return []; }
	@property
	CWXPath cwxParent() { return _owner; }
}

/// 実行モード。
enum EvalMode {
	All, /// 全ての処理を実行する。
	TypeCheck, /// 型のチェックのみ行う。
}

/// 式の解析途中に発生したエラー。
struct ExprError {
	/// エラーメッセージ。
	string message;
	/// エラー発生行。
	size_t errLine;
	/// 行内の位置。
	size_t errPos;
	/// エラーチェック箇所の __FILE__
	string file;
	/// エラーチェック箇所の __LINE__
	size_t line;
}
/// ditto
class ExprException : Exception {
	this (string file, size_t line, string expression, const ExprError[] errors) { mixin(S_TRACE);
		super ("expression error", file, line);
		_expression = expression;
		_errors = errors;
	}
	private string _expression;
	private const(ExprError[]) _errors;

	/// 解析対象の式。
	@property
	const
	string expression() { return _expression; }
	/// 発生したエラーの配列。
	@property
	const
	const(ExprError[]) errors() { return _errors; }
}

/// 式のトークン。
private struct Token {
	bool entity; /// 式文字列内に実体を持つ？
	size_t line; /// トークンのある行。
	size_t pos; /// 行内の位置。
	size_t index; /// スクリプト全体での位置。
	string token; /// トークンを構成する文字列。
}

/// 式の構成部品。
private abstract class Part {
	const Token token;

	this (in Token token) { this.token = token; }

	@property
	const
	string stringValue() { throw new Exception("No supported.", __FILE__, __LINE__); }

	override
	const
	string toString() { return "Part"; }
}
/// 式。
private class Expr : Part {
	const(Part)[] parts;

	this (in Token token, in Part[] parts) { mixin(S_TRACE);
		super (token);
		this.parts = parts;
	}

	override
	const
	string toString() { return "[" ~ .map!(a => a.toString())(parts).join(", ") ~ "]"; }
}
/// 値。
private class NumberValue : Part {
	const double numVal;

	this (in Token token, double numVal) { mixin(S_TRACE);
		super (token);
		this.numVal = numVal;
	}

	@property
	const
	override
	string stringValue() { return .variantValueToPreviewTextImpl(VariantType.Number, numVal, "", false, []); }

	override
	const
	string toString() { return stringValue; }
}
/// ditto
private class StringValue : Part {
	const string strVal;

	this (in Token token, string strVal) { mixin(S_TRACE);
		super (token);
		this.strVal = strVal;
	}

	@property
	const
	override
	string stringValue() { return strVal; }

	override
	const
	string toString() { return "\"" ~ strVal.replace("\"", "\"\"") ~ "\""; }
}
/// ditto
private class BooleanValue : Part {
	const bool boolVal;

	this (in Token token, bool boolVal) { mixin(S_TRACE);
		super (token);
		this.boolVal = boolVal;
	}

	@property
	const
	override
	string stringValue() { return boolVal ? "TRUE" : "FALSE"; }

	override
	const
	string toString() { return stringValue; }
}
/// ditto
private class ListValue : Part {
	const Part[] listVal;

	this (in Token token, const(Part)[] listVal) { mixin(S_TRACE);
		super (token);
		this.listVal = listVal;
	}

	@property
	const
	override
	string stringValue() { return "LIST(" ~ listVal.map!(v => v.toString()).join(", ") ~ ")"; }

	override
	const
	string toString() { return stringValue; }
}
/// エラーチェック時に一時的に使用される不明型。
private class UnknownValue : Part {
	this (in Token token) { mixin(S_TRACE);
		super (token);
	}

	@property
	const
	override
	string stringValue() { return ""; }

	override
	const
	string toString() { return "Unknown"; }
}

/// 関数の名前と引数。
private class Function : Part {
	private static immutable typeof(&.funcLen)[string] FUNCS;
	shared static this () {
		FUNCS = [
			// Wsn.4
			"len": &.funcLen,
			"find": &.funcFind,
			"left": &.funcLeft,
			"right": &.funcRight,
			"mid": &.funcMid,
			"str": &.funcStr,
			"value": &.funcValue,
			"int": &.funcInt,
			"if": &.funcIf,
			"dice": &.funcDice,
			"max": &.funcMax,
			"min": &.funcMin,
			"var": &.funcVar,
			"flagvalue": &.funcFlagValue,
			"flagtext": &.funcFlagText,
			"stepvalue": &.funcStepValue,
			"steptext": &.funcStepText,
			"stepmax": &.funcStepMax,
			"selected": &.funcSelected,
			"casttype": &.funcCastType,
			"castname": &.funcCastName,
			"findcoupon": &.funcFindCoupon,
			"coupontext": &.funcCouponText,
			"findgossip": &.funcFindGossip,
			"gossiptext": &.funcGossipText,
			"partyname": &.funcPartyName,
			// Wsn.5
			"list": &.funcList,
			"at": &.funcAt,
			"llen": &.funcLLen,
			"lfind": &.funcLFind,
			"lleft": &.funcLLeft,
			"lright": &.funcLRight,
			"lmid": &.funcLMid,
			"partymoney": &.funcPartyMoney,
			"yadoname": &.funcYadoName,
		];
	}

	const string funcName;
	const Part[] args;

	this (in Token token, string funcName, in Part[] args) { mixin(S_TRACE);
		super (token);
		this.funcName = funcName;
		this.args = args;
	}

	/// 関数を実行する。
	const
	const(Part) call(in CProps prop, EvalMode mode, in VariableInfo vInfo, ref ExprError[] err) { mixin(S_TRACE);
		const(Part)[] args;
		foreach (arg; this.args) { mixin(S_TRACE);
			if (auto func = cast(Function)arg) { mixin(S_TRACE);
				args ~= func.call(prop, mode, vInfo, err);
			} else if (auto expr = cast(Expr)arg) { mixin(S_TRACE);
				args ~= .calculate(prop, mode, vInfo, expr.parts, err);
			} else { mixin(S_TRACE);
				args ~= arg;
			}
		}

		auto p = funcName.toLower() in FUNCS;
		if (p) { mixin(S_TRACE);
			return (*p)(prop, mode, vInfo, this, args, err);
		} else { mixin(S_TRACE);
			err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorFunctionIsNotDefined : "Function is not defined: %s", funcName), token.line, token.pos, __FILE__, __LINE__);
			return new NumberValue(token, 0);
		}
	}

	override
	const
	string toString() { mixin(S_TRACE);
		return "%s(%s)".format(funcName, .map!(a => (cast(Object)a).toString())(args).join(", "));
	}
}
/// 単項演算子。
private class UnaryOperator : Part {
	const string operator;

	this (in Token token, string operator) { mixin(S_TRACE);
		super (token);
		this.operator = operator;
	}

	/// 演算を実行する。
	const
	const(Part) call(in CProps prop, in Part rhs, ref ExprError[] err) { mixin(S_TRACE);
		final switch (operator.toLower()) {
		case "+":
			if (auto num = cast(NumberValue)rhs) { mixin(S_TRACE);
				return new NumberValue(token, num.numVal);
			} else { mixin(S_TRACE);
				if (!cast(UnknownValue)rhs) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorValueIsNotNumber : "Value is not number: %s", rhs.token.token), rhs.token.line, rhs.token.pos, __FILE__, __LINE__);
				return new NumberValue(token, 0);
			}
		case "-":
			if (auto num = cast(NumberValue)rhs) { mixin(S_TRACE);
				return new NumberValue(token, -num.numVal);
			} else { mixin(S_TRACE);
				if (!cast(UnknownValue)rhs) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorValueIsNotNumber : "Value is not number: %s", rhs.token.token), rhs.token.line, rhs.token.pos, __FILE__, __LINE__);
				return new NumberValue(token, 0);
			}
		case "not":
			if (auto boolVal = cast(BooleanValue)rhs) { mixin(S_TRACE);
				return new BooleanValue(token, !boolVal.boolVal);
			} else { mixin(S_TRACE);
				if (!cast(UnknownValue)rhs) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorValueIsNotBoolean : "Value is not boolean: %s", rhs.token.token), rhs.token.line, rhs.token.pos, __FILE__, __LINE__);
				return new BooleanValue(token, false);
			}
		}
	}

	override
	const
	string toString() { mixin(S_TRACE);
		return "UOp(%s, %s:%s)".format(operator, token.line, token.pos);
	}
}
/// 二項演算子。
private class Operator : Part {
	const string operator;

	this (in Token token, string operator) { mixin(S_TRACE);
		super (token);
		this.operator = operator;
	}

	private alias Tuple!(bool, "valid", string, "lhs", string, "rhs") StrVals;
	private alias Tuple!(bool, "valid", double, "lhs", double, "rhs") NumVals;
	private alias Tuple!(bool, "valid", bool, "lhs", bool, "rhs") BoolVals;
	private static StrVals strValsImpl(in CProps prop, in Part lhs, in Part rhs, ref ExprError[] err) { mixin(S_TRACE);
		if (auto l = cast(StringValue)lhs) { mixin(S_TRACE);
			if (auto r = cast(StringValue)rhs) { mixin(S_TRACE);
				return StrVals(true, l.strVal, r.strVal);
			} else { mixin(S_TRACE);
				if (!cast(UnknownValue)rhs) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorValueIsNotString : "Value is not string: %s", rhs.token.token), rhs.token.line, rhs.token.pos, __FILE__, __LINE__);
			}
		} else { mixin(S_TRACE);
			if (!cast(UnknownValue)lhs) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorValueIsNotString : "Value is not string: %s", lhs.token.token), lhs.token.line, lhs.token.pos, __FILE__, __LINE__);
		}
		return StrVals(false, "", "");
	}
	private static NumVals numValsImpl(in CProps prop, in Part lhs, in Part rhs, ref ExprError[] err) { mixin(S_TRACE);
		if (auto l = cast(NumberValue)lhs) { mixin(S_TRACE);
			if (auto r = cast(NumberValue)rhs) { mixin(S_TRACE);
				return NumVals(true, l.numVal, r.numVal);
			} else { mixin(S_TRACE);
				if (!cast(UnknownValue)rhs) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorValueIsNotNumber : "Value is not number: %s", rhs.token.token), rhs.token.line, rhs.token.pos, __FILE__, __LINE__);
			}
		} else { mixin(S_TRACE);
			if (!cast(UnknownValue)lhs) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorValueIsNotNumber : "Value is not number: %s", lhs.token.token), lhs.token.line, lhs.token.pos, __FILE__, __LINE__);
		}
		return NumVals(false, 0, 0);
	}
	private static BoolVals boolValsImpl(in CProps prop, in Part lhs, in Part rhs, ref ExprError[] err) { mixin(S_TRACE);
		if (auto l = cast(BooleanValue)lhs) { mixin(S_TRACE);
			if (auto r = cast(BooleanValue)rhs) { mixin(S_TRACE);
				return BoolVals(true, l.boolVal, r.boolVal);
			} else { mixin(S_TRACE);
				if (!cast(UnknownValue)rhs) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorValueIsNotBoolean : "Value is not boolean: %s", rhs.token.token), rhs.token.line, rhs.token.pos, __FILE__, __LINE__);
			}
		} else { mixin(S_TRACE);
			if (!cast(UnknownValue)lhs) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorValueIsNotBoolean : "Value is not boolean: %s", lhs.token.token), lhs.token.line, lhs.token.pos, __FILE__, __LINE__);
		}
		return BoolVals(false, false, false);
	}
	private static const(ListValue) listValImpl(in CProps prop, in Part rhs, ref ExprError[] err) { mixin(S_TRACE);
		auto r = cast(ListValue)rhs;
		if (!r) { mixin(S_TRACE);
			if (!cast(UnknownValue)rhs) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorValueIsNotList : "Value is not list: %s", rhs.token.token), rhs.token.line, rhs.token.pos, __FILE__, __LINE__);
		}
		return r;
	}

	private static bool equalsImpl(in CProps prop, EvalMode mode, in Part lhs, in Part rhs, string operator, bool inList, ref ExprError[] err) { mixin(S_TRACE);
		ExprError[] err2;
		scope (exit) {
			if (!inList) err ~= err2;
		}
		if (cast(ListValue)lhs) { mixin(S_TRACE);
			auto l = listValImpl(prop, lhs, err2);
			if (!l) return false;
			auto r = listValImpl(prop, rhs, err2);
			if (!r) return false;
			foreach (i; 0 .. .min(l.listVal.length, r.listVal.length)) { mixin(S_TRACE);
				auto b = equalsImpl(prop, mode, l.listVal[i], r.listVal[i], "=", true, err2);
				if (!b) { mixin(S_TRACE);
					if (operator == "<>") b = true;
					return b;
				}
			}
			auto b = l.listVal.length == r.listVal.length;
			if (operator == "<>") b = !b;
			return b;
		}
		auto r = false;
		if (!inList && (cast(StringValue)lhs || cast(StringValue)rhs)) { mixin(S_TRACE);
			r = lhs.stringValue == rhs.stringValue;
		} else if (cast(StringValue)lhs) { mixin(S_TRACE);
			auto n = strValsImpl(prop, lhs, rhs, err2);
			if (n.valid) { mixin(S_TRACE);
				r = n.lhs == n.rhs;
			} else { mixin(S_TRACE);
				r = false;
			}
		} else if (cast(BooleanValue)lhs) { mixin(S_TRACE);
			auto n = boolValsImpl(prop, lhs, rhs, err2);
			if (n.valid) { mixin(S_TRACE);
				r = n.lhs is n.rhs;
			} else { mixin(S_TRACE);
				r = false;
			}
		} else { mixin(S_TRACE);
			auto n = numValsImpl(prop, lhs, rhs, err2);
			if (n.valid) { mixin(S_TRACE);
				r = n.lhs == n.rhs;
			} else { mixin(S_TRACE);
				r = false;
			}
		}
		if (operator == "<>") r = !r;
		return r;
	}

	/// 演算を実行する。
	const
	const(Part) call(in CProps prop, EvalMode mode, in Part lhs, in Part rhs, ref ExprError[] err) { mixin(S_TRACE);
		return callImpl(prop, token, mode, lhs, rhs, operator, err);
	}
	/// ditto
	private static const(Part) callImpl(in CProps prop, in Token token, EvalMode mode, in Part lhs, in Part rhs, string operator, ref ExprError[] err) { mixin(S_TRACE);
		NumVals numVals() { return numValsImpl(prop, lhs, rhs, err); }
		BoolVals boolVals() { return boolValsImpl(prop, lhs, rhs, err); }
		const(ListValue) listVal(in Part rhs) { return listValImpl(prop, rhs, err); }

		final switch (operator.toLower()) {
		case "+":
			auto n = numVals();
			if (n.valid) { mixin(S_TRACE);
				return new NumberValue(token, n.lhs + n.rhs);
			} else { mixin(S_TRACE);
				return new NumberValue(token, 0);
			}
		case "-":
			auto n = numVals();
			if (n.valid) { mixin(S_TRACE);
				return new NumberValue(token, n.lhs - n.rhs);
			} else { mixin(S_TRACE);
				return new NumberValue(token, 0);
			}
		case "*":
			auto n = numVals();
			if (n.valid) { mixin(S_TRACE);
				return new NumberValue(token, n.lhs * n.rhs);
			} else { mixin(S_TRACE);
				return new NumberValue(token, 0);
			}
		case "/":
			auto n = numVals();
			if (n.valid) { mixin(S_TRACE);
				if (n.rhs == 0) { mixin(S_TRACE);
					if (mode !is EvalMode.TypeCheck) err ~= ExprError(prop ? prop.msgs.expressionErrorDivisionByZero : "Division by zero.", rhs.token.line, rhs.token.pos, __FILE__, __LINE__);
				} else { mixin(S_TRACE);
					return new NumberValue(token, n.lhs / n.rhs);
				}
			}
			return new NumberValue(token, 0);
		case "%":
			auto n = numVals();
			if (n.valid) { mixin(S_TRACE);
				if (n.rhs == 0) { mixin(S_TRACE);
					if (mode !is EvalMode.TypeCheck) err ~= ExprError(prop ? prop.msgs.expressionErrorDivisionByZero : "Division by zero.", rhs.token.line, rhs.token.pos, __FILE__, __LINE__);
				} else { mixin(S_TRACE);
					return new NumberValue(token, n.lhs % n.rhs);
				}
			}
			return new NumberValue(token, 0);
		case "~":
			if (auto l = cast(ListValue)lhs) { mixin(S_TRACE);
				if (auto r = cast(ListValue)rhs) { mixin(S_TRACE);
					return new ListValue(token, l.listVal ~ r.listVal);
				} else { mixin(S_TRACE);
					return new ListValue(token, l.listVal ~ rhs);
				}
			} else if (auto r = cast(ListValue)rhs) { mixin(S_TRACE);
				return new ListValue(token, lhs ~ r.listVal);
			}
			return new StringValue(token, lhs.stringValue ~ rhs.stringValue);
		case "<=":
			if (auto l = cast(ListValue)lhs) { mixin(S_TRACE);
				auto r = listVal(rhs);
				if (!r) return new BooleanValue(token, false);
				foreach (i; 0 .. .min(l.listVal.length, r.listVal.length)) { mixin(S_TRACE);
					auto b = cast(BooleanValue)callImpl(prop, token, mode, l.listVal[i], r.listVal[i], "<", err);
					if (b.boolVal) return b;
				}
				return new BooleanValue(token, l.listVal.length <= r.listVal.length);
			}
			auto n = numVals();
			if (n.valid) { mixin(S_TRACE);
				return new BooleanValue(token, n.lhs <= n.rhs);
			} else { mixin(S_TRACE);
				return new BooleanValue(token, false);
			}
		case ">=":
			if (auto l = cast(ListValue)lhs) { mixin(S_TRACE);
				auto r = listVal(rhs);
				if (!r) return new BooleanValue(token, false);
				foreach (i; 0 .. .min(l.listVal.length, r.listVal.length)) { mixin(S_TRACE);
					auto b = cast(BooleanValue)callImpl(prop, token, mode, l.listVal[i], r.listVal[i], ">", err);
					if (b.boolVal) return b;
				}
				return new BooleanValue(token, l.listVal.length >= r.listVal.length);
			}
			auto n = numVals();
			if (n.valid) { mixin(S_TRACE);
				return new BooleanValue(token, n.lhs >= n.rhs);
			} else { mixin(S_TRACE);
				return new BooleanValue(token, false);
			}
		case "<":
			if (auto l = cast(ListValue)lhs) { mixin(S_TRACE);
				auto r = listVal(rhs);
				if (!r) return new BooleanValue(token, false);
				foreach (i; 0 .. .min(l.listVal.length, r.listVal.length)) { mixin(S_TRACE);
					auto b = cast(BooleanValue)callImpl(prop, token, mode, l.listVal[i], r.listVal[i], "<", err);
					if (b.boolVal) return b;
				}
				return new BooleanValue(token, l.listVal.length < r.listVal.length);
			}
			auto n = numVals();
			if (n.valid) { mixin(S_TRACE);
				return new BooleanValue(token, n.lhs < n.rhs);
			} else { mixin(S_TRACE);
				return new BooleanValue(token, false);
			}
		case ">":
			if (auto l = cast(ListValue)lhs) { mixin(S_TRACE);
				auto r = listVal(rhs);
				if (!r) return new BooleanValue(token, false);
				foreach (i; 0 .. .min(l.listVal.length, r.listVal.length)) { mixin(S_TRACE);
					auto b = cast(BooleanValue)callImpl(prop, token, mode, l.listVal[i], r.listVal[i], ">", err);
					if (b.boolVal) return b;
				}
				return new BooleanValue(token, l.listVal.length > r.listVal.length);
			}
			auto n = numVals();
			if (n.valid) { mixin(S_TRACE);
				return new BooleanValue(token, n.lhs > n.rhs);
			} else { mixin(S_TRACE);
				return new BooleanValue(token, false);
			}
		case "=", "<>":
			auto r = equalsImpl(prop, mode, lhs, rhs, operator, false, err);
			return new BooleanValue(token, r);
		case "and":
			auto n = boolVals();
			if (n.valid) { mixin(S_TRACE);
				return new BooleanValue(token, n.lhs && n.rhs);
			} else { mixin(S_TRACE);
				return new BooleanValue(token, false);
			}
		case "or":
			auto n = boolVals();
			if (n.valid) { mixin(S_TRACE);
				return new BooleanValue(token, n.lhs || n.rhs);
			} else { mixin(S_TRACE);
				return new BooleanValue(token, false);
			}
		}
	}

	override
	const
	string toString() { mixin(S_TRACE);
		return "Op(%s, %s:%s)".format(operator, token.line, token.pos);
	}
}

/// sを式として解析し、スタックを生成する。
private const(Part)[] parseExpression(in CProps prop, string s, ref ExprError[] err) { mixin(S_TRACE);
	Token[] tokens;
	size_t bPos = 0;
	size_t line = 1;
	size_t pos = 1;
	auto s2 = s.replace("\r\n", "\n").replace("\r", "\n");
	static immutable RE = .ctRegex!("[0-9]+(\\.[0-9]+)?|[a-z_][a-z_0-9]*|[\\+\\-\\*\\/\\%\\~]|[\\(\\)]|,|\\@?\"([^\"]|\"\")*\"|or|and|<=|>=|<>|<|>|=|true|false|\\n|\\s+", "i");
	foreach (m; .matchAll(s2, RE)) { mixin(S_TRACE);
		if (m.pre.length != bPos) { mixin(S_TRACE);
			err ~= ExprError(prop ? prop.msgs.expressionErrorInvalidCharacter : "Invalid character.", line, pos, __FILE__, __LINE__);
		}
		bPos = m.pre.length + m.hit.length;
		auto t = m.hit;
		if (t.byDchar().any!(c => !c.isWhite())) { mixin(S_TRACE);
			tokens ~= Token(true, line, pos, m.pre.length, t);
		}
		if (t == "\n") { mixin(S_TRACE);
			line += 1;
			pos = 1;
		} else { mixin(S_TRACE);
			pos += t.length;
		}
	}

	size_t i = 0;
	auto expr = .parseSemantics(prop, tokens, i, err);
	if (i != tokens.length) { mixin(S_TRACE);
		err ~= ExprError(prop ? prop.msgs.expressionErrorInvalidSemantics : "Invalid semantics.", line, pos, __FILE__, __LINE__);
	}
	return expr;
}

/// 関数の引数列をパースする。
private const(Part)[] parseArguments(in CProps prop, ref Token[] tokens, ref size_t i, ref ExprError[] err) { mixin(S_TRACE);
	i++;
	if (tokens.length <= i) { mixin(S_TRACE);
		err ~= ExprError(prop ? prop.msgs.expressionErrorInvalidFunctionCall : "Invalid function call.", tokens[i - 1].line, tokens[i - 1].pos, __FILE__, __LINE__);
		return [];
	}
	auto t = tokens[i].token;
	if (t != "(") { mixin(S_TRACE);
		err ~= ExprError(prop ? prop.msgs.expressionErrorNeedOpenParen : "Need open paren.", tokens[i].line, tokens[i].pos, __FILE__, __LINE__);
		return [];
	}
	const(Part)[] args;
	while (i + 1 < tokens.length && tokens[i].token != ")") { mixin(S_TRACE);
		i++;
		auto t2 = tokens[i];
		if (t2.token == ")") { mixin(S_TRACE);
			break;
		}
		auto arg = .parseSemantics(prop, tokens, i, err);
		if (arg.length) { mixin(S_TRACE);
			args ~= arg.length == 1 ? arg[0] : new Expr(t2, arg);
		} else { mixin(S_TRACE);
			err ~= ExprError(prop ? prop.msgs.expressionErrorNoArgument : "No argument.", t2.line, t2.pos, __FILE__, __LINE__);
		}
	}
	i++;
	return args;
}

/// 構文解析を行う。
private const(Part)[] parseSemantics(in CProps prop, ref Token[] tokens, ref size_t i, ref ExprError[] err) { mixin(S_TRACE);
	const(Part)[] num;
	Tuple!(size_t, int, bool, Token)[] op;

	auto isOp = true;
	size_t parLevel = 0;
	auto opLevel = 0;
	if (tokens.length <= i) return [];
	auto t0 = tokens[i];

	mLoop: while (i < tokens.length) { mixin(S_TRACE);
		auto t = tokens[i].token;
		auto line = tokens[i].line;
		auto pos = tokens[i].pos;
		auto unary = false;

		switch (t.toLower()) {
		case "not": mixin(S_TRACE);
			if (!isOp) err ~= ExprError(prop ? prop.msgs.expressionErrorNeedBoolean : "Need boolean.", line, pos, __FILE__, __LINE__);
			// 真偽値反転演算子
			opLevel = 2;
			unary = true;
			break;
		case "-", "+": mixin(S_TRACE);
			if (isOp) { mixin(S_TRACE);
				// 単項演算子
				opLevel = 99;
				unary = true;
			} else { mixin(S_TRACE);
				// 加算・減算演算子
				opLevel = 4;
			}
			break;
		case "~": mixin(S_TRACE);
			if (isOp) err ~= ExprError(prop ? prop.msgs.expressionErrorNeedSymbolOrNumber : "Need symbol or number.", line, pos, __FILE__, __LINE__);
			// 連結子
			opLevel = 4;
			break;
		case "/", "*", "%": mixin(S_TRACE);
			if (isOp) err ~= ExprError(prop ? prop.msgs.expressionErrorNeedSymbolOrNumber : "Need symbol or number.", line, pos, __FILE__, __LINE__);
			// 優先の高い演算子
			opLevel = 5;
			break;
		case "<=", ">=", "<>", "<", ">", "=": mixin(S_TRACE);
			if (isOp) err ~= ExprError(prop ? prop.msgs.expressionErrorNeedSymbolOrNumber : "Need symbol or number.", line, pos, __FILE__, __LINE__);
			// 比較演算子
			opLevel = 3;
			break;
		case "and": mixin(S_TRACE);
			if (isOp) err ~= ExprError(prop ? prop.msgs.expressionErrorNeedSymbolOrNumber : "Need symbol or number.", line, pos, __FILE__, __LINE__);
			// AND演算子
			opLevel = 1;
			break;
		case "or": mixin(S_TRACE);
			if (isOp) err ~= ExprError(prop ? prop.msgs.expressionErrorNeedSymbolOrNumber : "Need symbol or number.", line, pos, __FILE__, __LINE__);
			// OR演算子
			opLevel = 0;
			break;
		case "(": mixin(S_TRACE);
			if (!isOp) err ~= ExprError(prop ? prop.msgs.expressionErrorNeedOperator : "Need operator.", line, pos, __FILE__, __LINE__);
			// 開き括弧
			parLevel++;
			i++;
			continue;
		case ")": mixin(S_TRACE);
			if (isOp) err ~= ExprError(prop ? prop.msgs.expressionErrorNeedSymbolOrNumber : "Need symbol or number.", line, pos, __FILE__, __LINE__);
			// 閉じ括弧
			if (parLevel <= 0) { mixin(S_TRACE);
				break mLoop;
			} else { mixin(S_TRACE);
				parLevel--;
				i++;
				continue;
			}
		case ",": mixin(S_TRACE);
			// カンマ区切り
			if (parLevel <= 0) { mixin(S_TRACE);
				break mLoop;
			} else if (isOp) { mixin(S_TRACE);
				err ~= ExprError(prop ? prop.msgs.expressionErrorNeedSymbolOrNumber : "Need symbol or number.", line, pos, __FILE__, __LINE__);
				i++;
			} else { mixin(S_TRACE);
				err ~= ExprError(prop ? prop.msgs.expressionErrorNeedOperator : "Need operator.", line, pos, __FILE__, __LINE__);
				i++;
			}
			continue;
		case "true", "false": mixin(S_TRACE);
			if (!isOp) err ~= ExprError(prop ? prop.msgs.expressionErrorNeedOperator : "Need operator.", line, pos, __FILE__, __LINE__);
			// 真偽値
			num ~= new BooleanValue(tokens[i], t.toLower() == "true");
			isOp = false;
			i++;
			continue;
		default: mixin(S_TRACE);
			if (t[0] == '"') { mixin(S_TRACE);
				if (!isOp) err ~= ExprError(prop ? prop.msgs.expressionErrorNeedOperator : "Need operator.", line, pos, __FILE__, __LINE__);
				// 文字列
				assert (t[$ - 1] == '"');
				num ~= new StringValue(tokens[i], t[1 .. $ - 1].replace("\"\"", "\""));
				isOp = false;
				i++;
			} else if (t[0] == '@') { mixin(S_TRACE);
				if (!isOp) err ~= ExprError(prop ? prop.msgs.expressionErrorNeedOperator : "Need operator.", line, pos, __FILE__, __LINE__);
				// 汎用変数
				assert (t[1] == '"');
				assert (t[$ - 1] == '"');
				auto t2 = tokens[i];
				num ~= new Function(t2, "var", [new StringValue(Token(true, t2.line, t2.pos, t2.index + 1, t2.token[1 .. $]), t[2 .. $ - 1].replace("\"\"", "\""))]);
				isOp = false;
				i++;
			} else if (t[0].isDigit()) { mixin(S_TRACE);
				if (!isOp) err ~= ExprError(prop ? prop.msgs.expressionErrorNeedOperator : "Need operator.", line, pos, __FILE__, __LINE__);
				// 数値
				try {
					num ~= new NumberValue(tokens[i], .to!double(t));
					isOp = false;
					i++;
				} catch (Exception e) {
					printStackTrace();
					debugln(e);
					err ~= ExprError(prop ? prop.msgs.expressionErrorInvalidNumber : "Invalid number.", line, pos, __FILE__, __LINE__);
					isOp = false;
					i++;
				}
			} else { mixin(S_TRACE);
				if (!isOp) err ~= ExprError(prop ? prop.msgs.expressionErrorNeedOperator : "Need operator.", line, pos, __FILE__, __LINE__);
				// その他シンボル
				// 現在は関数呼び出しのみ
				num ~= new Function(tokens[i], t, .parseArguments(prop, tokens, i, err));
				isOp = false;
			}
			continue;
		}
		auto opVal = .tuple(parLevel, opLevel, unary, tokens[i]);
		while (op.length && opVal.slice!(0, 2) <= op[$ - 1].slice!(0, 2)) { mixin(S_TRACE);
			if (unary && op[$ - 1][2]) { mixin(S_TRACE);
				break;
			}
			auto tpl = op[$ - 1];
			op = op[0 .. $ - 1];
			auto t2 = tpl[3];
			if (tpl[2]) { mixin(S_TRACE);
				num ~= new UnaryOperator(t2, t2.token);
			} else { mixin(S_TRACE);
				num ~= new Operator(t2, t2.token);
			}
		}
		op ~= opVal;
		isOp = true;

		i++;
	}

	while (op.length) { mixin(S_TRACE);
		auto tpl = op[$ - 1];
		op = op[0 .. $ - 1];
		auto t2 = tpl[3];
		if (tpl[2]) { mixin(S_TRACE);
			num ~= new UnaryOperator(t2, t2.token);
		} else { mixin(S_TRACE);
			num ~= new Operator(t2, t2.token);
		}
	}
	return num;
}

/// コモンの値を取り回すための構造体。
struct VariantVal {
	bool valid; /// 有効な値か。
	VariantType type; /// 型。
	double numVal = 0; /// 数値。
	string strVal = ""; /// 文字列値
	bool boolVal = false; /// 真偽値。
	const(VariantVal)[] listVal = []; /// リスト。

	/// 有効かどうかを指定して初期化する。
	this (bool valid) {
		this.valid = valid;
	}
	/// 型を指定して初期化する。
	this (VariantType type) { mixin(S_TRACE);
		this.valid = true;
		this.type = type;
	}
	/// vの値によって初期化する。
	this (in Variant v) { mixin(S_TRACE);
		this.valid = true;
		this.type = v.type;
		this.numVal = v.numVal;
		this.strVal = v.strVal;
		this.boolVal = v.boolVal;
		this.listVal = v.listVal;
	}
}

/// 計算中に評価される状態変数の値を取得するための情報。
struct VariableInfo {
	/// シナリオはwsnVer以上のWSN形式か。
	bool delegate(string wsnVer) isTargetWsnVersion;

	/// 状態変数が実在するか。
	private const bool delegate(string path) existsFlag;
	/// ditto
	private const bool delegate(string path) existsStep;
	/// ditto
	private const bool delegate(string path) existsVariant;
	/// フラグのテキストを取得。
	private const string delegate(string path, bool value) flagText;
	/// ステップのテキストを取得。
	private const string delegate(string path, uint value) stepText;
	/// ステップの値を最大値を取得。
	private const uint delegate(string path) stepMax;

	/// コモン値を取得。
	const VariantVal delegate(string path) variantValue;
	/// フラグの値を取得。
	const bool delegate(string path) flagValue;
	/// ステップの値を取得。
	const uint delegate(string path) stepValue;
	/// 選択メンバの番号を取得。
	const uint delegate() selectedPlayerCardNumber;

	/// クーポンの検索。
	const uint delegate(uint castNumber, string pattern, uint startPos) findCoupon;
	/// クーポンの取得。
	const string delegate(uint castNumber, uint couponNumber) couponText;
	/// ゴシップの検索。
	const uint delegate(string pattern, uint startPos) findGossip;
	/// ゴシップの取得。
	const string delegate(uint gossipNumber) gossipText;

	/// キャラクター名を取得。
	const string delegate(uint) castName;
	/// パーティ名の取得。
	const string delegate() partyName;
	/// 拠点名の取得。
	const string delegate() yadoName;

	/// インスタンスを生成する。
	this (in CProps prop, in Summary summ, in UseCounter uc, string targVer, string[char] names, VarValue[string] flags, VarValue[string] steps, VarValue[string] variants, VarValue[string] sysSteps) { mixin(S_TRACE);
		isTargetWsnVersion = (string wsnVer) { mixin(S_TRACE);
			return prop ? prop.isTargetVersion(summ, targVer, wsnVer) : true;
		};
		existsFlag = path => .findVar!(cwx.flag.Flag)(summ ? summ.flagDirRoot : null, uc, path) !is null;
		existsStep = path => .findVar!Step(summ ? summ.flagDirRoot : null, uc, path)  !is null;
		existsVariant = path => .findVar!Variant(summ ? summ.flagDirRoot : null, uc, path) !is null;
		variantValue = path => summ ? VariantVal(.findVar!Variant(summ ? summ.flagDirRoot : null, uc, path)) : VariantVal(false);
		flagText = (path, value) { mixin(S_TRACE);
			if (!summ) return "";
			auto f = .findVar!(cwx.flag.Flag)(summ ? summ.flagDirRoot : null, uc, path);
			auto s = value ? f.on : f.off;
			if (f.expandSPChars) s = .simpleFormatMsg(s, flags, steps, variants, sysSteps, names, ver => prop.isTargetVersion(summ, targVer, ver), prop.sys.prefixSystemVarName);
			return s;
		};
		flagValue = (path) { mixin(S_TRACE);
			auto f = .findVar!(cwx.flag.Flag)(summ ? summ.flagDirRoot : null, uc, path);
			return f ? f.onOff : false;
		};
		stepText = (path, value) { mixin(S_TRACE);
			if (!summ) return "";
			auto f = .findVar!Step(summ ? summ.flagDirRoot : null, uc, path);
			auto s = f.getValue(value);
			if (f.expandSPChars) s = .simpleFormatMsg(s, flags, steps, variants, sysSteps, names, ver => prop.isTargetVersion(summ, targVer, ver), prop.sys.prefixSystemVarName);
			return s;
		};
		stepValue = (path) { mixin(S_TRACE);
			auto f = .findVar!Step(summ ? summ.flagDirRoot : null, uc, path);
			return f ? f.select : 0u;
		};
		stepMax = (path) { mixin(S_TRACE);
			auto f = .findVar!Step(summ ? summ.flagDirRoot : null, uc, path);
			return f ? f.count : 0u;
		};
		selectedPlayerCardNumber = () => 0u;

		findCoupon = (castNumber, pattern, startPos) => 0u;
		couponText = (castNumber, couponNumber) => "";
		findGossip = (pattern, startPos) => 0u;
		gossipText = (gossipNumber) => "";

		castName = (castNumber) => "";
		partyName = () => "";
		yadoName = () => "";
	}
}

/// exprを実行して結果の値を返す。
private const(Part) calculate(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Part[] expr, ref ExprError[] err) { mixin(S_TRACE);
	const(Part)[] op;
	foreach (t; expr) { mixin(S_TRACE);
		if (auto func = cast(Function)t) { mixin(S_TRACE);
			op ~= func.call(prop, mode, vInfo, err);
		} else if (auto operator = cast(UnaryOperator)t) { mixin(S_TRACE);
			if (!op.length) { mixin(S_TRACE);
				err ~= ExprError(prop ? prop.msgs.expressionErrorInvalidSemantics : "Invalid semantics.", t.token.line, t.token.pos, __FILE__, __LINE__);
				return new NumberValue(t.token, 0);
			}
			auto rhs = op[$ - 1];
			op = op[0 .. $ - 1];
			op ~= operator.call(prop, rhs, err);
		} else if (auto operator = cast(Operator)t) { mixin(S_TRACE);
			if (!op.length) { mixin(S_TRACE);
				err ~= ExprError(prop ? prop.msgs.expressionErrorInvalidSemantics : "Invalid semantics.", t.token.line, t.token.pos, __FILE__, __LINE__);
				return new NumberValue(t.token, 0);
			}
			auto rhs = op[$ - 1];
			op = op[0 .. $ - 1];
			if (!op.length) { mixin(S_TRACE);
				err ~= ExprError(prop ? prop.msgs.expressionErrorInvalidSemantics : "Invalid semantics.", t.token.line, t.token.pos, __FILE__, __LINE__);
				return new NumberValue(t.token, 0);
			}
			auto lhs = op[$ - 1];
			op = op[0 .. $ - 1];
			op ~= operator.call(prop, mode, lhs, rhs, err);
		} else { mixin(S_TRACE);
			op ~= t;
		}
	}
	if (!op.length) { mixin(S_TRACE);
		return new NumberValue(Token(false), 0);
	}
	return op[$ - 1];
}

/// expressionをパースして実行する。
VariantVal eval(in CProps prop, EvalMode mode, in VariableInfo vInfo, string expression) { mixin(S_TRACE);
	ExprError[] err;
	auto expr = .parseExpression(prop, expression, err);
	if (err.length) throw new ExprException(__FILE__, __LINE__, expression, err);
	if (!expr.length) return VariantVal(false);
	auto r = .calculate(prop, mode, vInfo, expr, err);
	if (err.length) throw new ExprException(__FILE__, __LINE__, expression, err);
	return .partToVariantVal(r);
}
/// 値を表すPartをVariantValへ変換する。
private VariantVal partToVariantVal(in Part r) { mixin(S_TRACE);
	if (auto a = cast(NumberValue)r) { mixin(S_TRACE);
		auto val = VariantVal(VariantType.Number);
		val.numVal = a.numVal;
		return val;
	} else if (auto a = cast(StringValue)r) { mixin(S_TRACE);
		auto val = VariantVal(VariantType.String);
		val.strVal = a.strVal;
		return val;
	} else if (auto a = cast(BooleanValue)r) { mixin(S_TRACE);
		auto val = VariantVal(VariantType.Boolean);
		val.boolVal = a.boolVal;
		return val;
	} else if (auto a = cast(ListValue)r) { mixin(S_TRACE);
		auto val = VariantVal(VariantType.List);
		val.listVal = a.listVal.map!(a => a.partToVariantVal()).array();
		return val;
	} else if (auto a = cast(UnknownValue)r) { mixin(S_TRACE);
		return VariantVal(false);
	} else assert (0);
}

/// 対象バージョンでなければエラーを追加する。
private void checkWsnVersion(in VariableInfo vInfo, in Function func, string wsnVer, lazy string errMsg, ref ExprError[] err) { mixin(S_TRACE);
	if (vInfo.isTargetWsnVersion && !vInfo.isTargetWsnVersion(wsnVer)) { mixin(S_TRACE);
		err ~= ExprError(errMsg, func.token.line, func.token.pos, __FILE__, __LINE__);
	}
}
/// ditto
private void checkWsnVersionForFunctionExists(in CProps prop, in VariableInfo vInfo, in Function func, string wsnVer, ref ExprError[] err) { mixin(S_TRACE);
	checkWsnVersion(vInfo, func, wsnVer, .tryFormat(prop ? prop.msgs.expressionErrorFunctionIsNotExistsInTargetVersion : "Function %1$s is not exists in Wsn.%2$s.", func.funcName, wsnVer), err);
}

/// 引数のチェックを行う。
private bool checkArgCount(in CProps prop, in Function func, in Part[] args, size_t count, ref ExprError[] err) { mixin(S_TRACE);
	if (args.length != count) { mixin(S_TRACE);
		err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorInvalidArgumentCount : "Invalid argument count: %s, %s", func.funcName.toUpper(), count), func.token.line, func.token.pos, __FILE__, __LINE__);
		return false;
	}
	return true;
}
/// ditto
private bool checkArgCount2(in CProps prop, in Function func, in Part[] args, size_t countMin, size_t countMax, ref ExprError[] err) { mixin(S_TRACE);
	if (args.length < countMin || countMax < args.length) { mixin(S_TRACE);
		err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorInvalidArgumentCount2 : "Invalid argument count: %s, %s-%s", func.funcName.toUpper(), countMin, countMax), func.token.line, func.token.pos, __FILE__, __LINE__);
		return false;
	}
	return true;
}
/// ditto
private const(NumberValue) checkNumber(in CProps prop, in Function func, in Part[] args, size_t index, ref ExprError[] err) { mixin(S_TRACE);
	if (auto a = cast(NumberValue)args[index]) { mixin(S_TRACE);
		return a;
	}
	if (cast(UnknownValue)args[index]) return new NumberValue(args[index].token, 0);
	err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorArgumentIsNotNumber : "Argument is not number: %s, %s", func.funcName.toUpper(), index + 1), args[index].token.line, args[index].token.pos, __FILE__, __LINE__);
	return null;
}
/// ditto
private const(StringValue) checkString(in CProps prop, in Function func, in Part[] args, size_t index, ref ExprError[] err) { mixin(S_TRACE);
	if (auto a = cast(StringValue)args[index]) { mixin(S_TRACE);
		return a;
	}
	if (cast(UnknownValue)args[index]) return new StringValue(args[index].token, "");
	err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorArgumentIsNotString : "Argument is not string: %s, %s", func.funcName.toUpper(), index + 1), args[index].token.line, args[index].token.pos, __FILE__, __LINE__);
	return null;
}
/// ditto
private const(BooleanValue) checkBoolean(in CProps prop, in Function func, in Part[] args, size_t index, ref ExprError[] err) { mixin(S_TRACE);
	if (auto a = cast(BooleanValue)args[index]) { mixin(S_TRACE);
		return a;
	}
	if (cast(UnknownValue)args[index]) return new BooleanValue(args[index].token, false);
	err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorArgumentIsNotBoolean : "Argument is not boolean: %s, %s", func.funcName.toUpper(), index + 1), args[index].token.line, args[index].token.pos, __FILE__, __LINE__);
	return null;
}
/// ditto
private const(ListValue) checkList(in CProps prop, in Function func, in Part[] args, size_t index, ref ExprError[] err) { mixin(S_TRACE);
	if (auto a = cast(ListValue)args[index]) { mixin(S_TRACE);
		return a;
	}
	if (cast(UnknownValue)args[index]) return null;
	err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorArgumentIsNotList : "Argument is not list: %s, %s", func.funcName.toUpper(), index + 1), args[index].token.line, args[index].token.pos, __FILE__, __LINE__);
	return null;
}
/// ditto
private const(NumberValue) checkMinValue(in CProps prop, EvalMode mode, in Function func, in Part[] args, size_t index, double minValue, ref ExprError[] err) { mixin(S_TRACE);
	auto a = checkNumber(prop, func, args, index, err);
	if (!a) return null;
	if (a.numVal < minValue) { mixin(S_TRACE);
		if (mode !is EvalMode.TypeCheck) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorMinimumValue : "Minimum value: %s, %s, %s < %s", func.funcName.toUpper(), index + 1, minValue, a.numVal), args[index].token.line, args[index].token.pos, __FILE__, __LINE__);
		return null;
	}
	return a;
}
/// ditto
private const(NumberValue)[] checkAllNumber(in CProps prop, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	const(NumberValue)[] numVals;
	foreach (i, arg; args) { mixin(S_TRACE);
		auto a = checkNumber(prop, func, args, i, err);
		if (!a) return [];
		numVals ~= a;
	}
	return numVals;
}

/// 引数中の最大の値を返す。
private const(Part) funcMax(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (args.length == 0) { mixin(S_TRACE);
		err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorNoArgumentWithFunctionName : "No argument: %s", func.funcName.toUpper()), func.token.line, func.token.pos, __FILE__, __LINE__);
		return new NumberValue(func.token, 0);
	}
	auto numVals = .checkAllNumber(prop, func, args, err);
	if (numVals.length == 0) return new NumberValue(func.token, 0);
	return new NumberValue(func.token, .reduce!((a, b) => .max(a, b))(.map!(a => a.numVal)(numVals)));
}

/// 引数中の最小の値を返す。
private const(Part) funcMin(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (args.length == 0) { mixin(S_TRACE);
		err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorNoArgumentWithFunctionName : "No argument: %s", func.funcName.toUpper()), func.token.line, func.token.pos, __FILE__, __LINE__);
		return new NumberValue(func.token, 0);
	}
	auto numVals = .checkAllNumber(prop, func, args, err);
	if (numVals.length == 0) return new NumberValue(func.token, 0);
	return new NumberValue(func.token, .reduce!((a, b) => .min(a, b))(.map!(a => a.numVal)(numVals)));
}

/// 文字列の文字数を返す。
private const(Part) funcLen(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 1, err)) return new NumberValue(func.token, 0);
	auto a = checkString(prop, func, args, 0, err);
	if (!a) return new NumberValue(func.token, 0);
	return new NumberValue(func.token, a.strVal.codeLength!dchar);
}

/// 文字列内を検索する。
private const(Part) funcFind(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount2(prop, func, args, 2, 3, err)) return new NumberValue(func.token, 0);
	auto a = checkString(prop, func, args, 0, err);
	if (!a) return new NumberValue(func.token, 0);
	auto t = checkString(prop, func, args, 1, err);
	if (!t) return new NumberValue(func.token, 0);
	size_t start = 0;
	if (2 < args.length) { mixin(S_TRACE);
		auto s = checkMinValue(prop, mode, func, args, 2, 0, err);
		if (!s) return new NumberValue(func.token, 0);
		start = cast(size_t)s.numVal;
		if (start == 0) return new NumberValue(func.token, 0);
		start--;
		if (t.strVal.codeLength!dchar <= start) return new NumberValue(func.token, 0);
		start = .toUTFindex(t.strVal, start);
	}
	if (a.strVal == "" && t.strVal != "") { mixin(S_TRACE);
		return new NumberValue(func.token, .toUCSindex(t.strVal, start) + 1);
	}
	auto r = t.strVal[start .. $].indexOf(a.strVal);
	if (r == -1) return new NumberValue(func.token, 0);
	r += start;
	return new NumberValue(func.token, .toUCSindex(t.strVal, r) + 1);
}

/// 文字列の左側を取り出す。
private const(Part) funcLeft(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 2, err)) return new StringValue(func.token, "");
	auto s = checkString(prop, func, args, 0, err);
	if (!s) return new StringValue(func.token, "");
	auto n = checkMinValue(prop, mode, func, args, 1, 0, err);
	if (!n) return new StringValue(func.token, "");

	auto a = s.strVal.toUTF32();
	auto v = .min(cast(size_t)n.numVal, a.length);
	return new StringValue(func.token, a[0 .. v].text);
}

/// 文字列の右側を取り出す。
private const(Part) funcRight(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 2, err)) return new StringValue(func.token, "");
	auto s = checkString(prop, func, args, 0, err);
	if (!s) return new StringValue(func.token, "");
	auto n = checkMinValue(prop, mode, func, args, 1, 0, err);
	if (!n) return new StringValue(func.token, "");

	auto a = s.strVal.toUTF32();
	auto v = a.length - .min(cast(size_t)n.numVal, a.length);
	return new StringValue(func.token, a[v .. $].text);
}

/// 文字列の[N1-1:N1+N2]の範囲を取り出す。
private const(Part) funcMid(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount2(prop, func, args, 2, 3, err)) return new StringValue(func.token, "");
	auto s = checkString(prop, func, args, 0, err);
	if (!s) return new StringValue(func.token, "");
	auto a1 = checkMinValue(prop, mode, func, args, 1, 1, err);
	if (!a1) return new StringValue(func.token, "");
	auto n1 = cast(size_t)a1.numVal;
	auto v = n1 - 1;
	auto a = s.strVal.toUTF32();

	if (a.length + 1 <= n1) { mixin(S_TRACE);
		a = ""d;
	} else { mixin(S_TRACE);
		a = a[v .. $];

		if (args.length == 3) { mixin(S_TRACE);
			auto a2 = checkMinValue(prop, mode, func, args, 2, 0, err);
			if (!a2) return new StringValue(func.token, "");
			auto n2 = cast(size_t)a2.numVal;

			v = .min(n2, a.length);
			a = a[0 .. v];
		}
	}
	return new StringValue(func.token, a.text);
}

/// 引数を文字列に変換する。
private const(Part) funcStr(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 1, err)) return new StringValue(func.token, "");
	return new StringValue(func.token, args[0].stringValue);
}

private double toValue(in CProps prop, EvalMode mode, in Part arg, ref ExprError[] err) { mixin(S_TRACE);
	if (auto a = cast(NumberValue)arg) { mixin(S_TRACE);
		return a.numVal;
	} else if (auto a = cast(StringValue)arg) { mixin(S_TRACE);
		static immutable N = .ctRegex!("^\\s*-?([0-9]+(\\.[0-9]*)?|([0-9]*\\.)?[0-9]+)\\s*$");
		auto m = .match(a.strVal, N);
		if (!m.empty && m.hit == a.strVal) { mixin(S_TRACE);
			try {
				return .to!double(a.strVal.filter!(a => !a.isWhite()));
			} catch (ConvException e) { mixin(S_TRACE);
				if (mode !is EvalMode.TypeCheck) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorConversionToNumber : "Conversion to number error: %s", a.strVal), a.token.line, a.token.pos, __FILE__, __LINE__);
			}
		} else { mixin(S_TRACE);
			if (mode !is EvalMode.TypeCheck) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorConversionToNumber : "Conversion to number error: %s", a.strVal), a.token.line, a.token.pos, __FILE__, __LINE__);
		}
	} else { mixin(S_TRACE);
		if (!cast(UnknownValue)arg) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorConversionToNumber : "Conversion to number error: %s", arg.token.token), arg.token.line, arg.token.pos, __FILE__, __LINE__);
	}
	return 0;
}

/// 引数を数値化する。
private const(Part) funcValue(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 1, err)) return new NumberValue(func.token, 0);
	return new NumberValue(func.token, .toValue(prop, mode, args[0], err));
}

/// 引数を整数化する。
private const(Part) funcInt(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 1, err)) return new NumberValue(func.token, 0);
	return new NumberValue(func.token, cast(double)cast(long).toValue(prop, mode, args[0], err));
}

/// args[0]がtrueであればargs[1]を、そうでなければargs[2]を返す。
private const(Part) funcIf(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 3, err)) return new NumberValue(func.token, 0);
	auto a = checkBoolean(prop, func, args, 0, err);
	if (mode is EvalMode.TypeCheck) { mixin(S_TRACE);
		// trueとfalseで型が一致していない場合は Unknown型を返す。
		if (cast(NumberValue)args[1] && cast(NumberValue)args[2]) return args[1];
		if (cast(BooleanValue)args[1] && cast(BooleanValue)args[2]) return args[1];
		if (cast(StringValue)args[1] && cast(StringValue)args[2]) return args[1];
		return new UnknownValue(func.token);
	}
	if (!a) return args[1];
	return a.boolVal ? args[1] : args[2];
}

/// コモンの値を読む。
private const(Part) funcVar(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (mode !is EvalMode.TypeCheck) { mixin(S_TRACE);
		if (!vInfo.existsVariant) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
		if (!vInfo.variantValue) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
	}
	if (!checkArgCount(prop, func, args, 1, err)) return mode is EvalMode.All ? new NumberValue(func.token, 0) : new UnknownValue(func.token);
	auto a = checkString(prop, func, args, 0, err);
	if (!a) return new NumberValue(func.token, 0);
	if (mode is EvalMode.TypeCheck) return new UnknownValue(func.token);
	auto path = a.strVal;
	if (!vInfo.existsVariant(path)) { mixin(S_TRACE);
		if (mode !is EvalMode.TypeCheck) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorVariantNotFound : "Variant not found: %s", path), a.token.line, a.token.pos, __FILE__, __LINE__);
		return new NumberValue(func.token, 0);
	}
	auto val = vInfo.variantValue(path);
	return variantValToValueObj(func.token, val);
}
private const(Part) variantValToValueObj(in Token token, in VariantVal val) { mixin(S_TRACE);
	assert (val.valid);
	final switch (val.type) {
	case VariantType.Number:
		return new NumberValue(token, val.numVal);
	case VariantType.String:
		return new StringValue(token, val.strVal);
	case VariantType.Boolean:
		return new BooleanValue(token, val.boolVal);
	case VariantType.List:
		return new ListValue(token, val.listVal.map!(val => variantValToValueObj(token, val))().array());
	}
}

/// フラグの値を読む。
private const(Part) funcFlagValue(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (mode !is EvalMode.TypeCheck) { mixin(S_TRACE);
		if (!vInfo.existsFlag) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
		if (!vInfo.flagValue) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
	}
	if (!checkArgCount(prop, func, args, 1, err)) return new BooleanValue(func.token, false);
	auto a = checkString(prop, func, args, 0, err);
	if (!a) return new BooleanValue(func.token, false);
	if (mode is EvalMode.TypeCheck) return new BooleanValue(func.token, false);
	auto path = a.strVal;
	if (!vInfo.existsFlag(path)) { mixin(S_TRACE);
		if (mode !is EvalMode.TypeCheck) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorFlagNotFound : "Flag not found: %s", path), a.token.line, a.token.pos, __FILE__, __LINE__);
		return new BooleanValue(func.token, false);
	}
	return new BooleanValue(func.token, vInfo.flagValue(path));
}

/// フラグの値の文字列を読む。
private const(Part) funcFlagText(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (mode !is EvalMode.TypeCheck) { mixin(S_TRACE);
		if (!vInfo.existsFlag) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
		if (!vInfo.flagValue) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
		if (!vInfo.flagText) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
	}
	if (!checkArgCount2(prop, func, args, 1, 2, err)) return new StringValue(func.token, "");
	auto a = checkString(prop, func, args, 0, err);
	if (!a) return new StringValue(func.token, "");
	if (mode is EvalMode.TypeCheck) return new StringValue(func.token, "");
	auto path = a.strVal;
	if (!vInfo.existsFlag(path)) { mixin(S_TRACE);
		if (mode !is EvalMode.TypeCheck) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorFlagNotFound : "Flag not found: %s", path), a.token.line, a.token.pos, __FILE__, __LINE__);
		return new StringValue(func.token, "");
	}
	if (args.length == 2) { mixin(S_TRACE);
		auto b = checkBoolean(prop, func, args, 1, err);
		if (!b) return new StringValue(func.token, "");
		return new StringValue(func.token, vInfo.flagText(path, b.boolVal));
	} else { mixin(S_TRACE);
		return new StringValue(func.token, vInfo.flagText(path, vInfo.flagValue(path)));
	}
}

/// ステップの値を読む。
private const(Part) funcStepValue(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (mode !is EvalMode.TypeCheck) { mixin(S_TRACE);
		if (!vInfo.existsStep) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
		if (!vInfo.stepValue) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
	}
	if (!checkArgCount(prop, func, args, 1, err)) return new NumberValue(func.token, 0);
	auto a = checkString(prop, func, args, 0, err);
	if (!a) return new NumberValue(func.token, 0);
	if (mode is EvalMode.TypeCheck) return new NumberValue(func.token, 0);
	auto path = a.strVal;
	if (!vInfo.existsStep(path)) { mixin(S_TRACE);
		if (mode !is EvalMode.TypeCheck) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorStepNotFound : "Step not found: %s", path), a.token.line, a.token.pos, __FILE__, __LINE__);
		return new NumberValue(func.token, 0);
	}
	return new NumberValue(func.token, vInfo.stepValue(path));
}

/// ステップの値の文字列を読む。
private const(Part) funcStepText(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (mode !is EvalMode.TypeCheck) { mixin(S_TRACE);
		if (!vInfo.existsStep) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
		if (!vInfo.stepValue) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
		if (!vInfo.stepText) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
		if (!vInfo.stepMax) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
	}
	if (!checkArgCount2(prop, func, args, 1, 2, err)) return new StringValue(func.token, "");
	auto a = checkString(prop, func, args, 0, err);
	if (!a) return new StringValue(func.token, "");
	if (mode is EvalMode.TypeCheck) return new StringValue(func.token, "");
	auto path = a.strVal;
	if (!vInfo.existsFlag(path)) { mixin(S_TRACE);
		if (mode !is EvalMode.TypeCheck) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorStepNotFound : "Step not found: %s", path), a.token.line, a.token.pos, __FILE__, __LINE__);
		return new StringValue(func.token, "");
	}
	if (args.length == 2) { mixin(S_TRACE);
		auto b = checkNumber(prop, func, args, 1, err);
		if (!b) return new StringValue(func.token, "");
		auto value = cast(uint)b.numVal;
		if (vInfo.stepMax(path) < value) { mixin(S_TRACE);
			if (mode !is EvalMode.TypeCheck) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorInvalidStepValue : "InvalidStepValue: %s[%s]", path, value), a.token.line, a.token.pos, __FILE__, __LINE__);
			return new StringValue(func.token, "");
		}
		return new StringValue(func.token, vInfo.stepText(path, value));
	} else { mixin(S_TRACE);
		return new StringValue(func.token, vInfo.stepText(path, vInfo.stepValue(path)));
	}
}

/// ステップの最大値を取得する。
private const(Part) funcStepMax(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (mode !is EvalMode.TypeCheck) { mixin(S_TRACE);
		if (!vInfo.existsStep) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
		if (!vInfo.stepMax) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
	}
	if (!checkArgCount(prop, func, args, 1, err)) return new NumberValue(func.token, 0);
	auto a = checkString(prop, func, args, 0, err);
	if (!a) return new NumberValue(func.token, 0);
	if (mode is EvalMode.TypeCheck) return new NumberValue(func.token, 0);
	auto path = a.strVal;
	if (!vInfo.existsStep(path)) { mixin(S_TRACE);
		if (mode !is EvalMode.TypeCheck) err ~= ExprError(.tryFormat(prop ? prop.msgs.expressionErrorStepNotFound : "Step not found: %s", path), a.token.line, a.token.pos, __FILE__, __LINE__);
		return new NumberValue(func.token, 0);
	}
	return new NumberValue(func.token, vInfo.stepMax(path));
}

/// ダイスを振って結果の値を返す。
private const(Part) funcDice(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 2, err)) return new NumberValue(func.token, 0);
	auto t = checkMinValue(prop, mode, func, args, 0, 0, err);
	if (!t) return new NumberValue(func.token, 0);
	auto s = checkMinValue(prop, mode, func, args, 1, 0, err);
	if (!s) return new NumberValue(func.token, 0);

	auto times = cast(size_t)t.numVal;
	auto sides = cast(size_t)s.numVal;
	if (times <= 0 || sides <= 0) { mixin(S_TRACE);
		return new NumberValue(func.token, 0);
	}
	if (mode is EvalMode.TypeCheck) return new NumberValue(func.token, times);

	size_t result = 0;
	foreach (i; 0 .. times) { mixin(S_TRACE);
		result = .uniform(cast(size_t)0, sides) + 1;
	}
	return new NumberValue(func.token, result);
}

/// 選択メンバの番号を返す。
private const(Part) funcSelected(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 0, err)) return new NumberValue(func.token, 0);
	if (mode is EvalMode.TypeCheck) return new NumberValue(func.token, 0);
	if (mode !is EvalMode.TypeCheck) { mixin(S_TRACE);
		if (!vInfo.selectedPlayerCardNumber) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
	}
	return new NumberValue(func.token, vInfo.selectedPlayerCardNumber());
}

/// キャラクターのタイプを返す(プレイヤー=1, エネミー=2, 同行キャスト=3)。
/// 該当者がいない場合は0を返す。
private const(Part) funcCastType(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 1, err)) return new NumberValue(func.token, 0);
	auto n = checkMinValue(prop, mode, func, args, 0, 0, err);
	if (!n) return new NumberValue(func.token, 0);
	auto v = cast(uint)n.numVal;
	if (v == 0) return new NumberValue(func.token, 0);
	return new NumberValue(func.token, v <= prop.looks.partyMax ? 1 : 0);
}

/// キャラクターの名前を返す。
/// 該当者がいない場合は0を返す。
private const(Part) funcCastName(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 1, err)) return new StringValue(func.token, "");
	auto n = checkMinValue(prop, mode, func, args, 0, 0, err);
	if (!n) return new StringValue(func.token, "");
	auto v = cast(uint)n.numVal;
	if (v == 0) return new StringValue(func.token, "");
	return new StringValue(func.token, vInfo.castName(v));
}

/// クーポンを検索する。
private const(Part) funcFindCoupon(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (mode !is EvalMode.TypeCheck) { mixin(S_TRACE);
		if (!vInfo.findCoupon) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
	}
	if (!checkArgCount2(prop, func, args, 2, 3, err)) return new NumberValue(func.token, 0);
	auto n = checkMinValue(prop, mode, func, args, 0, 0, err);
	if (!n) return new NumberValue(func.token, 0);
	auto p = checkString(prop, func, args, 1, err);
	if (!p) return new NumberValue(func.token, 0);
	if (mode is EvalMode.TypeCheck) return new NumberValue(func.token, 0);

	if (args.length < 3) { mixin(S_TRACE);
		if (mode is EvalMode.TypeCheck) return new NumberValue(func.token, 0);
		return new NumberValue(func.token, vInfo.findCoupon(cast(uint)n.numVal, p.strVal, 1));
	} else { mixin(S_TRACE);
		auto pos = checkMinValue(prop, mode, func, args, 2, 0, err);
		if (!pos) return new NumberValue(func.token, 0);
		if (cast(uint)pos.numVal == 0) return new NumberValue(func.token, 0);
		if (mode is EvalMode.TypeCheck) return new NumberValue(func.token, 0);
		return new NumberValue(func.token, vInfo.findCoupon(cast(uint)n.numVal, p.strVal, cast(uint)pos.numVal));
	}
}

/// クーポン名を取得する。
private const(Part) funcCouponText(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (mode !is EvalMode.TypeCheck) { mixin(S_TRACE);
		if (!vInfo.couponText) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
	}
	if (!checkArgCount(prop, func, args, 2, err)) return new StringValue(func.token, "");
	auto n = checkMinValue(prop, mode, func, args, 0, 0, err);
	if (!n) return new NumberValue(func.token, 0);
	auto cn = checkMinValue(prop, mode, func, args, 1, 0, err);
	if (!cn) return new NumberValue(func.token, 0);
	if (mode is EvalMode.TypeCheck) return new StringValue(func.token, "");

	return new StringValue(func.token, vInfo.couponText(cast(uint)n.numVal, cast(uint)cn.numVal));
}

/// ゴシップを検索する。
private const(Part) funcFindGossip(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (mode !is EvalMode.TypeCheck) { mixin(S_TRACE);
		if (!vInfo.findGossip) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
	}
	if (!checkArgCount2(prop, func, args, 1, 2, err)) return new NumberValue(func.token, 0);
	auto p = checkString(prop, func, args, 0, err);
	if (!p) return new NumberValue(func.token, 0);

	if (args.length < 2) { mixin(S_TRACE);
		if (mode is EvalMode.TypeCheck) return new NumberValue(func.token, 0);
		return new NumberValue(func.token, vInfo.findGossip(p.strVal, 1));
	} else { mixin(S_TRACE);
		auto pos = checkMinValue(prop, mode, func, args, 1, 0, err);
		if (!pos) return new NumberValue(func.token, 0);
		if (cast(uint)pos.numVal == 0) return new NumberValue(func.token, 0);
		if (mode is EvalMode.TypeCheck) return new NumberValue(func.token, 0);
		return new NumberValue(func.token, vInfo.findGossip(p.strVal, cast(uint)pos.numVal));
	}
}

/// ゴシップ名を取得する。
private const(Part) funcGossipText(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (mode !is EvalMode.TypeCheck) { mixin(S_TRACE);
		if (!vInfo.gossipText) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
	}
	if (!checkArgCount(prop, func, args, 1, err)) return new StringValue(func.token, "");
	auto gn = checkMinValue(prop, mode, func, args, 0, 0, err);
	if (!gn) return new NumberValue(func.token, 0);
	if (mode is EvalMode.TypeCheck) return new StringValue(func.token, "");

	return new StringValue(func.token, vInfo.gossipText(cast(uint)gn.numVal));
}

/// パーティ名を取得する。
private const(Part) funcPartyName(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (mode !is EvalMode.TypeCheck) { mixin(S_TRACE);
		if (!vInfo.partyName) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
	}
	if (!checkArgCount(prop, func, args, 0, err)) return new StringValue(func.token, "");
	if (mode is EvalMode.TypeCheck) return new StringValue(func.token, "");

	return new StringValue(func.token, vInfo.partyName());
}

/// 引数からリストを生成する。
private const(Part) funcList(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	.checkWsnVersionForFunctionExists(prop, vInfo, func, "5", err);
	return new ListValue(func.token, args);
}

/// リストの要素を取り出す。
private const(Part) funcAt(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 2, err)) return new UnknownValue(func.token);
	.checkWsnVersionForFunctionExists(prop, vInfo, func, "5", err);
	auto l = checkList(prop, func, args, 0, err);
	if (!l) return new UnknownValue(func.token);

	auto a = checkMinValue(prop, mode, func, args, 1, 1, err);
	if (!a) return new UnknownValue(func.token);
	auto index = cast(size_t)a.numVal - 1;

	if (l.listVal.length <= index) { mixin(S_TRACE);
		err ~= ExprError(.tryFormat(prop ? .tryFormat(prop.msgs.expressionErrorListIndexIsOutOfRange, index + 1, l.listVal.length) : "List index is out of range: %s, %s", func.funcName.toUpper(), 1), a.token.line, a.token.pos, __FILE__, __LINE__);
		return new UnknownValue(func.token);
	}
	return l.listVal[index];
}

/// リストの長さを返す。
private const(Part) funcLLen(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 1, err)) return new NumberValue(func.token, 0);
	auto a = checkList(prop, func, args, 0, err);
	if (!a) return new NumberValue(func.token, 0);
	return new NumberValue(func.token, a.listVal.length);
}

/// リスト内を検索する。
private const(Part) funcLFind(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount2(prop, func, args, 2, 3, err)) return new NumberValue(func.token, 0);
	auto l = checkList(prop, func, args, 1, err);
	if (!l) return new NumberValue(func.token, 0);
	size_t start = 0;
	if (2 < args.length) { mixin(S_TRACE);
		auto s = checkMinValue(prop, mode, func, args, 2, 0, err);
		if (!s) return new NumberValue(func.token, 0);
		start = cast(size_t)s.numVal;
		if (start == 0) return new NumberValue(func.token, 0);
		start--;
		if (l.listVal.length <= start) return new NumberValue(func.token, 0);
	}
	foreach (i, v; l.listVal[start .. $]) { mixin(S_TRACE);
		ExprError[] err2;
		if (Operator.equalsImpl(prop, mode, v, args[0], "=", true, err2)) { mixin(S_TRACE);
			return new NumberValue(func.token, i + start + 1);
		}
	}
	return new NumberValue(func.token, 0);
}

/// リストの左側を取り出す。
private const(Part) funcLLeft(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 2, err)) return new ListValue(func.token, []);
	auto l = checkList(prop, func, args, 0, err);
	if (!l) return new ListValue(func.token, []);
	auto n = checkMinValue(prop, mode, func, args, 1, 0, err);
	if (!n) return new ListValue(func.token, []);
	auto v = .min(cast(size_t)n.numVal, l.listVal.length);
	return new ListValue(func.token, l.listVal[0 .. v]);
}

/// リストの右側を取り出す。
private const(Part) funcLRight(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount(prop, func, args, 2, err)) return new ListValue(func.token, []);
	auto l = checkList(prop, func, args, 0, err);
	if (!l) return new ListValue(func.token, []);
	auto n = checkMinValue(prop, mode, func, args, 1, 0, err);
	if (!n) return new ListValue(func.token, []);

	auto v = l.listVal.length - .min(cast(size_t)n.numVal, l.listVal.length);
	return new ListValue(func.token, l.listVal[v .. $]);
}

/// リストの[N1-1:N1+N2]の範囲を取り出す。
private const(Part) funcLMid(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	if (!checkArgCount2(prop, func, args, 2, 3, err)) return new ListValue(func.token, []);
	auto l = checkList(prop, func, args, 0, err);
	if (!l) return new ListValue(func.token, []);
	auto a1 = checkMinValue(prop, mode, func, args, 1, 1, err);
	if (!a1) return new ListValue(func.token, []);
	auto n1 = cast(size_t)a1.numVal;
	auto v = n1 - 1;

	if (l.listVal.length + 1 <= n1) { mixin(S_TRACE);
		return new ListValue(func.token, []);
	} else { mixin(S_TRACE);
		auto a = l.listVal[v .. $];

		if (args.length == 3) { mixin(S_TRACE);
			auto a2 = checkMinValue(prop, mode, func, args, 2, 0, err);
			if (!a2) return new ListValue(func.token, []);
			auto n2 = cast(size_t)a2.numVal;

			v = .min(n2, a.length);
			a = a[0 .. v];
		}
		return new ListValue(func.token, a);
	}
}

/// パーティーの所持金を返す。パーティー非編成時は -1 を返す。
private const(Part) funcPartyMoney(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	.checkWsnVersionForFunctionExists(prop, vInfo, func, "5", err);
	return new NumberValue(func.token, 0);
}

/// 拠点名を返す。拠点無しの場合は空文字列を返す。
private const(Part) funcYadoName(in CProps prop, EvalMode mode, in VariableInfo vInfo, in Function func, in Part[] args, ref ExprError[] err) { mixin(S_TRACE);
	.checkWsnVersionForFunctionExists(prop, vInfo, func, "5", err);
	if (mode !is EvalMode.TypeCheck) { mixin(S_TRACE);
		if (!vInfo.yadoName) throw new Exception(func.funcName.toUpper() ~ " is not callable.", __FILE__, __LINE__);
	}
	if (!checkArgCount(prop, func, args, 0, err)) return new StringValue(func.token, "");
	if (mode is EvalMode.TypeCheck) return new StringValue(func.token, "");

	return new StringValue(func.token, vInfo.yadoName());
}

/// 入力支援用に関数の引数の型を表現する。
enum ArgType {
	Number, /// 数値。
	String, /// 文字列。
	Boolean, /// 真偽値。
	List, /// リスト。
	NumberOrString, /// 数値または文字列。
	Any, /// 任意の型。
	Flag, /// フラグ名。
	Step, /// ステップ名。
	Variant, /// コモン名。
	VariantRef, /// コモン参照。
	NoArgument, /// 不指定。
}
/// 入力支援用の引数定義。
struct ArgDef {
	ArgType type; /// 引数型。
	string name; /// 引数名。
	string initValue; /// 入力欄の初期値。
	bool optional = false; /// 省略可能。
	bool varArg = false; /// 可変個。
}
/// 入力支援用の関数定義。
struct FuncDef {
	FunctionCategory[] category; /// 所属カテゴリ。
	string name; /// 関数名。
	string desc; /// 解説。
	string shortDesc; /// 一行解説。
	string example; /// 記述例。
	ArgDef[] args; /// 引数定義。
	ArgType returnType; /// 戻り値の型。
}

/// 全ての関数定義を返す。
immutable(FuncDef[]) functionDefinitions(in CProps prop) { mixin(S_TRACE);
	return [
		// Wsn.4
		FuncDef([FunctionCategory.StringOperation], "LEN", prop.msgs.funcDescLen, prop.msgs.funcShortDescLen, prop.msgs.funcExampleLen, [
			ArgDef(ArgType.String, prop.msgs.exprStringDesc, "", false),
		], ArgType.Number),
		FuncDef([FunctionCategory.StringOperation], "FIND", prop.msgs.funcDescFind, prop.msgs.funcShortDescFind, prop.msgs.funcExampleFind, [
			ArgDef(ArgType.String, prop.msgs.exprFindStringDesc, "", false),
			ArgDef(ArgType.String, prop.msgs.exprTargetStringDesc, "", false),
			ArgDef(ArgType.Number, prop.msgs.exprFindStartPositionDesc, "1", true),
		], ArgType.Number),
		FuncDef([FunctionCategory.StringOperation], "LEFT", prop.msgs.funcDescLeft, prop.msgs.funcShortDescLeft, prop.msgs.funcExampleLeft, [
			ArgDef(ArgType.String, prop.msgs.exprStringDesc, "", false),
			ArgDef(ArgType.Number, prop.msgs.exprStringLengthDesc, "0", false),
		], ArgType.String),
		FuncDef([FunctionCategory.StringOperation], "RIGHT", prop.msgs.funcDescRight, prop.msgs.funcShortDescRight, prop.msgs.funcExampleRight, [
			ArgDef(ArgType.String, prop.msgs.exprStringDesc, "", false),
			ArgDef(ArgType.Number, prop.msgs.exprStringLengthDesc, "0", false),
		], ArgType.String),
		FuncDef([FunctionCategory.StringOperation], "MID", prop.msgs.funcDescMid, prop.msgs.funcShortDescMid, prop.msgs.funcExampleMid, [
			ArgDef(ArgType.String, prop.msgs.exprStringDesc, "", false),
			ArgDef(ArgType.Number, prop.msgs.exprStringPositionDesc, "1", false),
			ArgDef(ArgType.Number, prop.msgs.exprStringLengthDesc, "0", true),
		], ArgType.String),
		FuncDef([FunctionCategory.StringOperation, FunctionCategory.Conversion], "STR", prop.msgs.funcDescStr, prop.msgs.funcShortDescStr, prop.msgs.funcExampleStr, [
			ArgDef(ArgType.Any, prop.msgs.exprAnyValueDesc, "", false),
		], ArgType.String),
		FuncDef([FunctionCategory.NumberOperation, FunctionCategory.Conversion], "VALUE", prop.msgs.funcDescValue, prop.msgs.funcShortDescValue, prop.msgs.funcExampleValue, [
			ArgDef(ArgType.NumberOrString, prop.msgs.exprValueArgDesc, "0", false),
		], ArgType.Number),
		FuncDef([FunctionCategory.NumberOperation, FunctionCategory.Conversion], "INT", prop.msgs.funcDescInt, prop.msgs.funcShortDescInt, prop.msgs.funcExampleInt, [
			ArgDef(ArgType.NumberOrString, prop.msgs.exprValueArgDesc, "0", false),
		], ArgType.Number),
		FuncDef([FunctionCategory.ListOperation], "LIST", prop.msgs.funcDescList, prop.msgs.funcShortDescList, prop.msgs.funcExampleList, [
			ArgDef(ArgType.Any, prop.msgs.exprAnyValueDesc, "", false, true),
		], ArgType.List), // Wsn.5
		FuncDef([FunctionCategory.ListOperation], "AT", prop.msgs.funcDescAt, prop.msgs.funcShortDescAt, prop.msgs.funcExampleAt, [
			ArgDef(ArgType.List, prop.msgs.exprListDesc, "", false),
			ArgDef(ArgType.Number, prop.msgs.exprListPositionDesc, "1", false),
		], ArgType.Any), // Wsn.5
		FuncDef([FunctionCategory.ListOperation], "LLEN", prop.msgs.funcDescLLen, prop.msgs.funcShortDescLLen, prop.msgs.funcExampleLLen, [
			ArgDef(ArgType.List, prop.msgs.exprListDesc, "", false),
		], ArgType.Number), // Wsn.5
		FuncDef([FunctionCategory.ListOperation], "LFIND", prop.msgs.funcDescLFind, prop.msgs.funcShortDescLFind, prop.msgs.funcExampleLFind, [
			ArgDef(ArgType.Any, prop.msgs.exprAnyFindValueDesc, "", false),
			ArgDef(ArgType.List, prop.msgs.exprListDesc, "", false),
			ArgDef(ArgType.Number, prop.msgs.exprFindStartPositionDesc, "1", true),
		], ArgType.List), // Wsn.5
		FuncDef([FunctionCategory.ListOperation], "LLEFT", prop.msgs.funcDescLLeft, prop.msgs.funcShortDescLLeft, prop.msgs.funcExampleLLeft, [
			ArgDef(ArgType.List, prop.msgs.exprListDesc, "", false),
			ArgDef(ArgType.Number, prop.msgs.exprListLengthDesc, "0", false),
		], ArgType.List), // Wsn.5
		FuncDef([FunctionCategory.ListOperation], "LRIGHT", prop.msgs.funcDescLRight, prop.msgs.funcShortDescLRight, prop.msgs.funcExampleLRight, [
			ArgDef(ArgType.List, prop.msgs.exprListDesc, "", false),
			ArgDef(ArgType.Number, prop.msgs.exprListLengthDesc, "0", false),
		], ArgType.List), // Wsn.5
		FuncDef([FunctionCategory.ListOperation], "LMID", prop.msgs.funcDescLMid, prop.msgs.funcShortDescLMid, prop.msgs.funcExampleLMid, [
			ArgDef(ArgType.List, prop.msgs.exprListDesc, "", false),
			ArgDef(ArgType.Number, prop.msgs.exprListPositionDesc, "1", false),
			ArgDef(ArgType.Number, prop.msgs.exprListLengthDesc, "0", true),
		], ArgType.List), // Wsn.5
		FuncDef([FunctionCategory.Etc], "IF", prop.msgs.funcDescIf, prop.msgs.funcShortDescIf, prop.msgs.funcExampleIf, [
			ArgDef(ArgType.Boolean, prop.msgs.exprBooleanDesc, "TRUE", false),
			ArgDef(ArgType.Any, prop.msgs.exprIfTrueDesc, "", false),
			ArgDef(ArgType.Any, prop.msgs.exprIfFalseDesc, "", false),
		], ArgType.Any),
		FuncDef([FunctionCategory.NumberOperation], "DICE", prop.msgs.funcDescDice, prop.msgs.funcShortDescDice, prop.msgs.funcExampleDice, [
			ArgDef(ArgType.Number, prop.msgs.exprDiceTimesDesc, "1", false),
			ArgDef(ArgType.Number, prop.msgs.exprDiceSidesDesc, "6", false),
		], ArgType.Number),
		FuncDef([FunctionCategory.NumberOperation], "MAX", prop.msgs.funcDescMax, prop.msgs.funcShortDescMax, prop.msgs.funcExampleMax, [
			ArgDef(ArgType.Number, prop.msgs.exprVariableLengthNumberDesc, "0", false, true),
		], ArgType.Number),
		FuncDef([FunctionCategory.NumberOperation], "MIN", prop.msgs.funcDescMin, prop.msgs.funcShortDescMin, prop.msgs.funcExampleMin, [
			ArgDef(ArgType.Number, prop.msgs.exprVariableLengthNumberDesc, "0", false, true),
		], ArgType.Number),
		FuncDef([FunctionCategory.VariableOperation], "VAR", prop.msgs.funcDescVar, prop.msgs.funcShortDescVar, prop.msgs.funcExampleVar, [
			ArgDef(ArgType.Variant, prop.msgs.exprVariantDesc, "", false),
		], ArgType.Any),
		FuncDef([FunctionCategory.VariableOperation], "FLAGVALUE", prop.msgs.funcDescFlagValue, prop.msgs.funcShortDescFlagValue, prop.msgs.funcExampleFlagValue, [
			ArgDef(ArgType.Flag, prop.msgs.exprFlagDesc, "", false),
		], ArgType.Boolean),
		FuncDef([FunctionCategory.VariableOperation], "FLAGTEXT", prop.msgs.funcDescFlagText, prop.msgs.funcShortDescFlagText, prop.msgs.funcExampleFlagText, [
			ArgDef(ArgType.Flag, prop.msgs.exprFlagDesc, "", false),
			ArgDef(ArgType.Boolean, prop.msgs.exprFlagValueDesc, "TRUE", true),
		], ArgType.String),
		FuncDef([FunctionCategory.VariableOperation], "STEPVALUE", prop.msgs.funcDescStepValue, prop.msgs.funcShortDescStepValue, prop.msgs.funcExampleStepValue, [
			ArgDef(ArgType.Step, prop.msgs.exprStepDesc, "", false),
		], ArgType.Number),
		FuncDef([FunctionCategory.VariableOperation], "STEPTEXT", prop.msgs.funcDescStepText, prop.msgs.funcShortDescStepText, prop.msgs.funcExampleStepText, [
			ArgDef(ArgType.Step, prop.msgs.exprStepDesc, "", false),
			ArgDef(ArgType.Number, prop.msgs.exprStepValueDesc, "0", true),
		], ArgType.String),
		FuncDef([FunctionCategory.VariableOperation], "STEPMAX", prop.msgs.funcDescStepMax, prop.msgs.funcShortDescStepMax, prop.msgs.funcExampleStepMax, [
			ArgDef(ArgType.Step, prop.msgs.exprStepDesc, "", false),
		], ArgType.Number),
		FuncDef([FunctionCategory.CardInformation], "SELECTED", prop.msgs.funcDescSelected, prop.msgs.funcShortDescSelected, prop.msgs.funcExampleSelected, [
		], ArgType.Number),
		FuncDef([FunctionCategory.CardInformation], "CASTTYPE", prop.msgs.funcDescCastType, prop.msgs.funcShortDescCastType, prop.msgs.funcExampleCastType, [
			ArgDef(ArgType.Number, prop.msgs.exprCastNumberDesc, "1", false),
		], ArgType.Number),
		FuncDef([FunctionCategory.CardInformation], "CASTNAME", prop.msgs.funcDescCastName, prop.msgs.funcShortDescCastName, prop.msgs.funcExampleCastName, [
			ArgDef(ArgType.Number, prop.msgs.exprCastNumberDesc, "1", false),
		], ArgType.String),
		FuncDef([FunctionCategory.CouponInformation], "FINDCOUPON", prop.msgs.funcDescFindCoupon, prop.msgs.funcShortDescFindCoupon, prop.msgs.funcExampleFindCoupon, [
			ArgDef(ArgType.Number, prop.msgs.exprCastNumberDesc, "1", false),
			ArgDef(ArgType.String, prop.msgs.exprFindPatternDesc, "*", false),
			ArgDef(ArgType.Number, prop.msgs.exprFindStartPositionDesc, "", true),
		], ArgType.Number),
		FuncDef([FunctionCategory.CouponInformation], "COUPONTEXT", prop.msgs.funcDescCouponText, prop.msgs.funcShortDescCouponText, prop.msgs.funcExampleCouponText, [
			ArgDef(ArgType.Number, prop.msgs.exprCastNumberDesc, "1", false),
			ArgDef(ArgType.Number, prop.msgs.exprCouponNumberDesc, "1", false),
		], ArgType.String),
		FuncDef([FunctionCategory.CouponInformation], "FINDGOSSIP", prop.msgs.funcDescFindGossip, prop.msgs.funcShortDescFindGossip, prop.msgs.funcExampleFindGossip, [
			ArgDef(ArgType.String, prop.msgs.exprFindPatternDesc, "*", false),
			ArgDef(ArgType.Number, prop.msgs.exprFindStartPositionDesc, "", true),
		], ArgType.Number),
		FuncDef([FunctionCategory.CouponInformation], "GOSSIPTEXT", prop.msgs.funcDescGossipText, prop.msgs.funcShortDescGossipText, prop.msgs.funcExampleGossipText, [
			ArgDef(ArgType.Number, prop.msgs.exprGossipNumberDesc, "1", false),
		], ArgType.String),
		FuncDef([FunctionCategory.Etc], "PARTYNAME", prop.msgs.funcDescPartyName, prop.msgs.funcShortDescPartyName, prop.msgs.funcExamplePartyName, [
		], ArgType.String),
		FuncDef([FunctionCategory.Etc], "PARTYMONEY", prop.msgs.funcDescPartyMoney, prop.msgs.funcShortDescPartyMoney, prop.msgs.funcExamplePartyMoney, [
		], ArgType.Number), // Wsn.5
		FuncDef([FunctionCategory.Etc], "YADONAME", prop.msgs.funcDescYadoName, prop.msgs.funcShortDescYadoName, prop.msgs.funcExampleYadoName, [
		], ArgType.String), // Wsn.5
	];
}

unittest { mixin(UTPerf);
	auto prop = new CProps("", null);
	VariableInfo vInfo;
	bool checkN(in VariantVal r, double val) { return r.type is VariantType.Number && r.numVal.approxEqual(val); }
	bool checkS(in VariantVal r, string val) { return r.type is VariantType.String && r.strVal == val; }
	bool checkB(in VariantVal r, bool val) { return r.type is VariantType.Boolean && r.boolVal is val; }

	assert (checkN(.eval(prop, EvalMode.All, vInfo, "--5"), 5));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "---5"), -5));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "-(--5)"), -5));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "-- min(100,23)+5"), 28));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "+-Min(100,23)+ - 5"), -28));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "max (45, 42, 100.5,  23 ) + 0.123"), 100.623));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "mAX(45,42,100.5,23)+0.123 = 100.623"), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "max(45,42,100.5,23)+0.123 <> 100.623"), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "true or false"), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "tRUe and faLSE"), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "true and true or false and false"), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "((true and true) or false) and false"), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "not false and true or false and false"), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "not false or false"), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "not not (false or false)"), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "not not not true"), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "not 1 = 2"), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "not 1 + 2 = 3"), false));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "(not true) ~ \"&\" ~ (not true)"), "FALSE&FALSE"));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "(5+8) % 3"), 1));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "5 + 8%3"), 7));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "-2+22*2"), 42));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "9/3"), 3));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "4<=5"), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "4<=4"), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "4<=3"), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "5>=4"), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "4>=4"), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "3>=4"), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "4<5"), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "4<4"), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "4<3"), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "5>4"), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "4>4"), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "3>4"), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "5=4"), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "4=4"), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "3=4"), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "5<>4"), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "4<>4"), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, "3<>4"), true));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "LEN(\"TESTあいうえお\")"), 9));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"対象文字列\", \"対象文字列\")"), 1));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"文字\", \"対象文字列\")"), 3));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"文じ\", \"対象文字列\")"), 0));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"文字\", \"対象文字列\", 3)"), 3));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"文字\", \"対象文字列\", 4)"), 0));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"文字\", \"対象文字列\", 0)"), 0));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"列\", \"対象文字列\", 5)"), 5));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"列\", \"対象文字列\", 6)"), 0));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"\", \"対象文字列\")"), 1));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"\", \"対象文字列\", 5)"), 5));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"\", \"対象文字列\", 6)"), 0));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"字\", \"A象B文C字D列\")"), 6));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"字\", \"A象B文C字D列\", 6)"), 6));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"字\", \"A象B文C字D列\", 7)"), 0));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "FIND(\"\", \"\")"), 0));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "LEFT(\"あいうえお\", 0)"), ""));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "LEFT(\"あいうえお\", 3)"), "あいう"));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "LEFT(\"あいうえお\", 8)"), "あいうえお"));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "RIGHT(\"あいうえお\", 0)"), ""));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "RIGHT(\"あいうえお\", 3)"), "うえお"));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "RIGHT(\"あいうえお\", 8)"), "あいうえお"));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "MID(\"あいうえお\", 2, 3)"), "いうえ"));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "MID(\"あいうえお\", 5, 3)"), "お"));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "MID(\"あいうえお\", 6, 3)"), ""));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "MID(\"あいうえお\", 3)"), "うえお"));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "MID(\"あいうえお\", 5)"), "お"));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "MID(\"あいうえお\", 6)"), ""));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "MID(\"あいうえお\", 7)"), ""));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "STR(\"あいうえお\")"), "あいうえお"));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "STR(42)"), "42"));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, "STR(42.42 + 5)"), "47.42"));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "VALUE(42.42 + 5)"), 47.42));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "VALUE(42)"), 42));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "VALUE(\"42\")"), 42));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "VALUE(\"42.123\")"), 42.123));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "INT(\"42.123\")"), 42));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "INT(\"42.9\")"), 42));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "INT(\" -42.9  \")"), -42));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "IF(1=2,99,88)"), 88));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, "IF(2=2,99,88)"), 99));

	auto l1 = .eval(prop, EvalMode.All, vInfo, `LIST("STR", 42, TRUE)`);
	assert (l1.type == VariantType.List);
	assert (l1.listVal.length == 3);
	assert (checkS(l1.listVal[0], "STR"));
	assert (checkN(l1.listVal[1], 42));
	assert (checkB(l1.listVal[2], true));

	auto l2 = .eval(prop, EvalMode.All, vInfo, `LIST(LIST(1, 2, 3), LIST(3, 4, 5))`);
	assert (l2.type == VariantType.List);
	assert (l2.listVal.length == 2);
	assert (l2.listVal[0].type == VariantType.List);
	assert (l2.listVal[0].listVal.length == 3);
	assert (checkN(l2.listVal[0].listVal[0], 1));
	assert (checkN(l2.listVal[0].listVal[1], 2));
	assert (checkN(l2.listVal[0].listVal[2], 3));
	assert (l2.listVal[1].type == VariantType.List);
	assert (l2.listVal[1].listVal.length == 3);
	assert (checkN(l2.listVal[1].listVal[0], 3));
	assert (checkN(l2.listVal[1].listVal[1], 4));
	assert (checkN(l2.listVal[1].listVal[2], 5));

	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) = LIST(1, 2, 3)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) = LIST(1, "2", 3)`), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) = LIST(1, 2)`), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2) = LIST(1, 2, 3)`), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) <> LIST(1, 2, 3)`), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) <> LIST(1, "2", 3)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) <> LIST(1, 2)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2) <> LIST(1, 2, 3)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) < LIST(1, 2, 3)`), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) < LIST(1, 2)`), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) < LIST(1, 3)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2) < LIST(1, 2, 3)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) <= LIST(1, 2, 3)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) <= LIST(1, 2)`), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) <= LIST(1, 3)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2) <= LIST(1, 2, 3)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) > LIST(1, 2, 3)`), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) > LIST(1, 2)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2) > LIST(1, 2, 3)`), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 3) > LIST(1, 2, 3)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) >= LIST(1, 2, 3)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) >= LIST(1, 2)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2) >= LIST(1, 2, 3)`), false));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 3) >= LIST(1, 2, 3)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) ~ LIST(4, 5, 6) = LIST(1, 2, 3, 4, 5, 6)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LIST(1, 2, 3) ~ LIST(4, 5, 6) ~ LIST(7) = LIST(1, 2, 3, 4, 5, 6, 7)`), true));

	assert (checkB(.eval(prop, EvalMode.All, vInfo, `AT(LIST(TRUE, 42, "STR"), 1)`), true));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, `AT(LIST(TRUE, 42, "STR"), 2)`), 42));
	assert (checkS(.eval(prop, EvalMode.All, vInfo, `AT(LIST(TRUE, 42, "STR"), 3)`), "STR"));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, `LLEN(LIST(1, 2, 3))`), 3));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LLEFT(LIST(1, 2, 3), 2) = LIST(1, 2)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LRIGHT(LIST(1, 2, 3), 2) = LIST(2, 3)`), true));
	assert (checkB(.eval(prop, EvalMode.All, vInfo, `LMID(LIST(1, 2, 3, 4), 2, 2) = LIST(2, 3)`), true));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, `LFIND(3, LIST(1, 2, 3, 4))`), 3));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, `LFIND(5, LIST(1, 2, 3, 4))`), 0));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, `LFIND("TEST", LIST(1, 2, "TEST", 4))`), 3));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, `LFIND(LIST(99), LIST(1, 2, LIST(99), 4))`), 3));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, `LFIND(42, LIST(42, 42, 4, 42), 3)`), 4));
	assert (checkN(.eval(prop, EvalMode.All, vInfo, `LFIND(42, LIST(42, 42, 42, 4), 3)`), 3));
}

/// vの値の文字列表現(式内に記述できるもの)を返す。
@property
string variantValueToText(in Variant v) { mixin(S_TRACE);
	return variantValueToTextImpl(v.type, v.numVal, v.strVal, v.boolVal, v.listVal);
}
/// ditto
@property
string variantValueToText(in VariantVal v) { mixin(S_TRACE);
	return variantValueToTextImpl(v.type, v.numVal, v.strVal, v.boolVal, v.listVal);
}
/// ditto
private string variantValueToTextImpl(VariantType type, double numVal, string strVal, bool boolVal, in VariantVal[] listVal) { mixin(S_TRACE);
	final switch (type) {
	case VariantType.Number:
		auto r = .format("%." ~ .text(Variant.DECIMAL_PLACES) ~ "f", numVal).stripRight("0").stripRight(".");
		if (r == "") r = "0";
		return r;
	case VariantType.String:
		return `"%s"`.format(strVal.replace("\"", "\"\""));
	case VariantType.Boolean:
		return boolVal.text().toUpper();
	case VariantType.List:
		return "LIST(" ~ listVal.map!(v => v.variantValueToText()).join(", ") ~ ")";
	}
} unittest { mixin(UTPerf);
	assert (.variantValueToTextImpl(VariantType.Number, 12.345, "", false, []) == "12.345");
	assert (.variantValueToTextImpl(VariantType.Number, 100.000, "", false, []) == "100");
	assert (.variantValueToTextImpl(VariantType.Number, 100.010, "", false, []) == "100.01");
	assert (.variantValueToTextImpl(VariantType.Number, 100.12345600001, "", false, []) == "100.123456");
	assert (.variantValueToTextImpl(VariantType.Number, 0.0, "", false, []) == "0");
	assert (.variantValueToTextImpl(VariantType.Number, 0.000000000000001, "", false, []) == "0");
	assert (.variantValueToTextImpl(VariantType.Number, 0.01, "", false, []) == "0.01");
	assert (.variantValueToTextImpl(VariantType.String, 0, "TEST", false, []) == "\"TEST\"");
	assert (.variantValueToTextImpl(VariantType.String, 0, "TE\"ST", false, []) == "\"TE\"\"ST\"");
	assert (.variantValueToTextImpl(VariantType.Boolean, 0, "", true, []) == "TRUE");
	assert (.variantValueToTextImpl(VariantType.Boolean, 0, "", false, []) == "FALSE");
	auto v1 = VariantVal(VariantType.Number);
	v1.numVal = 42.0;
	auto v2 = VariantVal(VariantType.String);
	v2.strVal = "STR";
	auto v3 = VariantVal(VariantType.Boolean);
	v3.boolVal = true;
	auto v4 = VariantVal(VariantType.List);
	auto vv1 = VariantVal(VariantType.Number);
	vv1.numVal = 42.1;
	auto vv2 = VariantVal(VariantType.String);
	vv2.strVal = "STR2";
	auto vv3 = VariantVal(VariantType.Boolean);
	vv3.boolVal = false;
	v4.listVal = [vv1, vv2, vv3];
	assert (.variantValueToTextImpl(VariantType.List, 0, "", false, [v1, v2, v3, v4]) == `LIST(42, "STR", TRUE, LIST(42.1, "STR2", FALSE))`);
}
/// 文字列表現textからコモン値を生成する。
@property
VariantVal variantValueFromText(string text) { mixin(S_TRACE);
	static immutable NUM = .ctRegex!("^((\\+|-)?[0-9]+(\\.[0-9]+)?)$");
	static immutable STR = .ctRegex!("^\"([^\"]|\"\")*\"$");
	static immutable BOOL = .ctRegex!("^(true|false)$", "i");
	if (auto m = .match(text, NUM)) { mixin(S_TRACE);
		if (!m.empty) { mixin(S_TRACE);
			try {
				auto v = VariantVal(VariantType.Number);
				v.numVal = .to!double(m.hit);
				return v;
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
				return VariantVal(false);
			}
		}
	}
	if (auto m = .match(text, STR)) { mixin(S_TRACE);
		if (!m.empty) { mixin(S_TRACE);
			auto v = VariantVal(VariantType.String);
			v.strVal = m.hit[1 .. $ - 1].replace("\"\"", "\"");
			return v;
		}
	}
	if (auto m = .match(text, BOOL)) { mixin(S_TRACE);
		if (!m.empty) { mixin(S_TRACE);
			auto v = VariantVal(VariantType.Boolean);
			v.boolVal = m.hit.toLower() == "true";
			return v;
		}
	}
	// TODO: list?
	return VariantVal(false);
}

/// vの値の文字列表現(STR(v)の結果)を返す。
@property
string variantValueToPreviewText(in cwx.flag.Variant v) { mixin(S_TRACE);
	return variantValueToPreviewTextImpl(v.type, v.numVal, v.strVal, v.boolVal, v.listVal);
}
/// ditto
@property
string variantValueToPreviewText(in VariantVal v) { mixin(S_TRACE);
	return variantValueToPreviewTextImpl(v.type, v.numVal, v.strVal, v.boolVal, v.listVal);
}
private string variantValueToPreviewTextImpl(VariantType type, double numVal, string strVal, bool boolVal, in VariantVal[] listVal) { mixin(S_TRACE);
	final switch (type) {
	case VariantType.Number:
		return .variantValueToTextImpl(type, numVal, strVal, boolVal, listVal);
	case VariantType.String:
		return strVal;
	case VariantType.Boolean:
		return boolVal.text().toUpper();
	case VariantType.List:
		return "LIST(" ~ listVal.map!(v => v.variantValueToPreviewText()).join(", ") ~ ")";
	}
}
