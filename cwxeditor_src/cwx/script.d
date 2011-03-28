
module cwx.script;

import cwx.props;
import cwx.types;
import cwx.summary;
import cwx.utils;
import cwx.event;
import cwx.motion;
import cwx.background;
import cwx.area;
import cwx.card;

import std.ctype;
import std.stdio;
import std.string;
import std.regexp;

/// スクリプトの解析途中に発生したエラー。
class CWXScriptException : Exception {
	this (string msg, string text, size_t errLine, size_t errPos, string file, size_t line) {
		super (msg, file, line);
		_text = text;
		_errLine = errLine;
		_errPos = errPos;
	}
	private string _text;
	/// 解析対象のテキスト。
	/// compile()以外から投げられた場合は""になる。
	string text() {return _text;}
	private size_t _errLine;
	/// エラー発生行。
	size_t errLine() {return _errLine;}
	private size_t _errPos;
	/// 行内の位置。
	size_t errPos() {return _errPos;}
}

/// スクリプトを解析し、コンテント群にして返す。
/// 解析中にエラーがあった場合はCWXScriptExceptionを投げる。
static Content[] compile(CProps prop, Summary summ, string script) {
	try {
		auto compiler = CWXScript(prop, summ);
		auto tokens = compiler.tokenize(script);
		auto nodes = compiler.analyzeSyntax(tokens);
		return compiler.analyzeSemantics(nodes);
	} catch (CWXScriptException e) {
		e._text = script;
		throw e;
	}
}

/// スクリプトからコンテントツリーを生成する。
struct CWXScript {
	private CProps _prop;
	private Summary _summ;

	/// コンテントツリーの親となる貼り紙を指定してインスタンスを生成。
	static CWXScript opCall(CProps prop, Summary summ) {
		CWXScript r;
		r._prop = prop;
		r._summ = summ;
		return r;
	}

	private static void throwError(string File = __FILE__, size_t Line = __LINE__)
			(lazy string message, in Token tok) {
		throwErrorToken(message, tok.line, tok.pos, tok.value);
	}
	private static void throwErrorToken(string File = __FILE__, size_t Line = __LINE__)
			(lazy string message, size_t line, size_t pos, string value) {
		throw new CWXScriptException(message, "", line, pos, File, Line);
	}

	/// Tokenの種別。
	static enum Kind {
		START, /// start
		IF, /// if
		FI, /// fi
		ELIF, /// elif
		SIF, /// sif
		O_BRA, /// [
		C_BRA, /// ]
		SYMBOL, /// キーワードや命令以外のシンボル。
		NUMBER, /// 数値。
		VAR_NAME, /// 変数名。
		EQ, /// =
		COMMA, /// comma
		STRING, /// 文字列。
		PLU, /// +
		MIN, /// -
		MUL, /// *
		DIV, /// /
		RES, /// %
		CAT, /// ~
		O_PAR, /// (
		C_PAR /// )
	}
	/// スクリプトのトークン。
	static struct Token {
		size_t line; /// トークンのある行。
		size_t pos; /// 行内の位置。
		Kind kind; /// 種別。
		string value; /// 値。
		/// 文字列表現。
		string toString() {
			return .format("Token {line %d : %d, %s, %s}", line, pos, to!(string)(cast(int) kind), value);
		}
		/// oと等しいか。
		int opEquals(Token* o) {
			return line == o.line && pos == o.pos && kind == o.kind && value == o.value;
		}
	}
	private string[] wrap(string line, size_t width) {
		if (width > 0) {
			string[] lines;
			while (lengthJ(line) > width) {
				auto l = sliceJ(line, 0, width);
				if (!l.length) {
					l = sliceJ(line, 0, width + 1);
				}
				lines ~= l;
				line = line[l.length .. $];
			}
			lines ~= line;
			return lines;
		}
		return [line];
	}
	private size_t stringCenter(string[] linesBase, size_t width) {
		string[] lines;
		if (width > 0) {
			foreach (line; linesBase) {
				lines ~= wrap(line, width);
			}
		} else {
			lines = linesBase;
		}
		int ln;
		int lc = cast(int) lineCount(lines);
		if (lc > 0 && lc < _prop.looks.messageLine) {
			int lnt = cast(int) _prop.looks.messageLine - (lc - 1);
			ln = lnt / 2 + 1;
		} else {
			ln = 0;
		}
		return ln > 0 ? ln : 0;
	}
	/// Tokenの値を文字列として解釈して返す。
	/// 文字列を囲う記号に加え、
	/// 行頭にあるタブ文字や一定数の空白が取り除かれる。
	private string stringValue(in Token tok, size_t width) {
		string decode(string s, char esc) {
			char[] buf = new char[s.length];
			size_t len = 0;
			bool escape = false;
			foreach (char c; s) {
				if (!escape && c == esc) {
					escape = true;
				} else {
					buf[len] = c;
					len++;
					escape = false;
				}
			}
			if (escape) {
				buf[len] = esc;
				len++;
			}
			return buf[0 .. len];
		}
		if (tok.kind !is Kind.STRING || tok.value.length < 2) {
			throwError(_prop.msgs.scriptErrorInvalidString, tok);
		}
		if (tok.value[0] == '@') {
			char[] buf;
			auto linesBase = .splitlines(tok.value[0 .. $ - 1]);
			string firstLine = linesBase[0];
			string[] lines;
			foreach (i, line; linesBase[1 .. $]) {
				line = .stripl(line);
				line = decode(line, tok.value[0]);
				if (line.length >= 1 && line[0] == '\\') {
					line = line[1 .. $];
				}
				lines ~= wrap(line, width);
			}
			if (firstLine.length > 1) {
				auto lnStr = std.string.tolower(.strip(firstLine[1 .. $]));
				bool isNum = .isNumeric(lnStr);
				if (!isNum && icmp(lnStr, "c") != 0 && icmp(lnStr, "center") != 0) {
					throwError(_prop.msgs.scriptErrorInvalidStr, tok);
				}
				int ln;
				if (isNum) {
					ln = .to!(int)(lnStr);
				} else {
					ln = stringCenter(lines, 0);
				}
				if (ln > 0) {
					buf.length = ln - 1;
				}
				buf[] = '\n';
			}
			foreach (i, line; lines) {
				if (i > 0) buf ~= '\n';;
				buf ~= line;
			}
			return buf;
		}
		return decode(tok.value[1 .. $ - 1], tok.value[0]);
	} unittest {
		CWXScript s;
		assert (s.stringValue(Token(0, 0, Kind.STRING, `"abc"`), 0) == "abc");
		assert (s.stringValue(Token(0, 0, Kind.STRING, `"a""bc"`), 0) == "a\"bc");
		assert (s.stringValue(Token(0, 0, Kind.STRING, `'ab''c'`), 0) == "ab'c");
		assert (s.stringValue(Token(0, 2, Kind.STRING, "@ 3\n\t\tte@@st\n   t\\e\\st\n\\   a\n\\\\   a@"), false)
			 == "\n\nte@st\nt\\e\\st\n   a\n\\   a");
	}

	/// textをTokenに分割する。
	Token[] tokenize(string text) {
		Token[] r;
		text = .replace(text, "\r\n", "\n");
		text = .replace(text, "\r", "\n");
		auto reg = RegExp("(" ~ std.string.join(TOKENS, ")|(") ~ ")", "i");
		size_t i = 0;
		size_t hits = 0;
		size_t pos = 0;
		string post;
		bool spaceAfter = false;
		foreach (token; reg.search(text)) {
			if (token.pre.length - hits > 0) {
				throwErrorToken(_prop.msgs.scriptErrorInvalidToken, i, pos, "");
			}
			post = token.post;
			auto str = token.match(0);
			void retCount() {
				size_t count = .count(str, "\n");
				if (count > 0) {
					pos = str.length - std.string.rfind(str, '\n') - 1;
					i += count;
				} else {
					pos += str.length;
				}
			}
			auto c = str[0];
			if (isalpha(c) || c == '_') {
				spaceAfter = false;
				// symbol
				switch (std.string.tolower(str)) {
				case "start":
					r ~= Token(i, pos, Kind.START, str);
					break;
				case "if":
					r ~= Token(i, pos, Kind.IF, str);
					break;
				case "elif":
					r ~= Token(i, pos, Kind.ELIF, str);
					break;
				case "fi":
					r ~= Token(i, pos, Kind.FI, str);
					break;
				case "sif":
					r ~= Token(i, pos, Kind.SIF, str);
					break;
				default:
					r ~= Token(i, pos, Kind.SYMBOL, str);
					break;
				}
				pos += str.length;
			} else if (c == '$') {
				spaceAfter = false;
				r ~= Token(i, pos, Kind.VAR_NAME, str);
				pos += str.length;
			} else if (c == '=') {
				spaceAfter = false;
				r ~= Token(i, pos, Kind.EQ, str);
				pos += str.length;
			} else if (c == '[') {
				// open bracket
				spaceAfter = false;
				r ~= Token(i, pos, Kind.O_BRA, str);
				pos += str.length;
			} else if (c == ']') {
				// close bracket
				spaceAfter = false;
				r ~= Token(i, pos, Kind.C_BRA, str);
				pos += str.length;
			} else if (isdigit(c)) {
				// number
				spaceAfter = false;
				r ~= Token(i, pos, Kind.NUMBER, str);
				pos += str.length;
			} else if (c == '@' || c == '"' || c == '\'') {
				// string
				if (!spaceAfter && r.length && r[$ - 1].kind is Kind.STRING
						&& r[$ - 1].value[$ - 1] == c) {
					// 直前のstringに結合
					r[$ - 1].value ~= str;
				} else {
					r ~= Token(i, pos, Kind.STRING, str);
				}
				spaceAfter = false;
				retCount;
			} else if (isspace(c)) {
				// whitespace
				spaceAfter = true;
				retCount;
			} else if (c == '+') {
				// plus
				spaceAfter = false;
				r ~= Token(i, pos, Kind.PLU, str);
				pos += str.length;
			} else if (c == '-') {
				// minus
				spaceAfter = false;
				r ~= Token(i, pos, Kind.MIN, str);
				pos += str.length;
			} else if (c == '*') {
				// multiply
				spaceAfter = false;
				r ~= Token(i, pos, Kind.MUL, str);
				pos += str.length;
			} else if (c == '/') {
				if (str.length >= 2 && str[1] == '*') {
					// multi line comment
					spaceAfter = true;
					retCount;
				} else if (str.length >= 2 && str[1] == '/') {
					// line comment
					spaceAfter = true;
					i++;
					pos = 0;
				} else {
					// divide
					spaceAfter = false;
					r ~= Token(i, pos, Kind.DIV, str);
					pos += str.length;
				}
			} else if (c == '%') {
				// residue
				spaceAfter = false;
				r ~= Token(i, pos, Kind.RES, str);
				pos += str.length;
			} else if (c == '~') {
				// cat
				spaceAfter = false;
				r ~= Token(i, pos, Kind.CAT, str);
				pos += str.length;
			} else if (c == '(') {
				// open paren
				spaceAfter = false;
				r ~= Token(i, pos, Kind.O_PAR, str);
				pos += str.length;
			} else if (c == ')') {
				// close paren
				spaceAfter = false;
				r ~= Token(i, pos, Kind.C_PAR, str);
				pos += str.length;
			} else if (c == ',') {
				// comma
				spaceAfter = false;
				r ~= Token(i, pos, Kind.COMMA, str);
				pos += str.length;
			} else {
				assert (0);
			}
			hits += str.length;
		}
		if (post.length) throwErrorToken(_prop.msgs.scriptErrorInvalidToken, i, pos, "");
		return r;
	} unittest {
		CWXScript s;
		assert (s.tokenize("/*\n*/").length == 0);
		assert (s.tokenize("/* */start, 12.3 \ntest1 [$void] =\"str\ning//\"\n\r //comment\nELIF if\n1/2+3*4%(5-6)")
			== [
				Token(0, 5, Kind.START, "start"),
				Token(0, 10, Kind.COMMA, ","),
				Token(0, 12, Kind.NUMBER, "12.3"),
				Token(1, 0, Kind.SYMBOL, "test1"),
				Token(1, 6, Kind.O_BRA, "["),
				Token(1, 7, Kind.VAR_NAME, "$void"),
				Token(1, 12, Kind.C_BRA, "]"),
				Token(1, 14, Kind.EQ, "="),
				Token(1, 15, Kind.STRING, "\"str\ning//\""),
				Token(5, 0, Kind.ELIF, "ELIF"),
				Token(5, 5, Kind.IF, "if"),
				Token(6, 0, Kind.NUMBER, "1"),
				Token(6, 1, Kind.DIV, "/"),
				Token(6, 2, Kind.NUMBER, "2"),
				Token(6, 3, Kind.PLU, "+"),
				Token(6, 4, Kind.NUMBER, "3"),
				Token(6, 5, Kind.MUL, "*"),
				Token(6, 6, Kind.NUMBER, "4"),
				Token(6, 7, Kind.RES, "%"),
				Token(6, 8, Kind.O_PAR, "("),
				Token(6, 9, Kind.NUMBER, "5"),
				Token(6, 10, Kind.MIN, "-"),
				Token(6, 11, Kind.NUMBER, "6"),
				Token(6, 12, Kind.C_PAR, ")")
			]);
	}

	private enum CRKind {STR, INT, REAL}
	private static struct CalcResult {
		CRKind kind;
		union {
			string str;
			long numInt;
			real numReal;
		}
		void cat(in CProps prop, in Token tok, ref CalcResult rval) {
			switch (kind) {
			case CRKind.STR: break;
			case CRKind.INT: str = to!(string)(numInt); break;
			case CRKind.REAL: str = to!(string)(numReal); break;
			default: assert (0);
			}
			switch (rval.kind) {
			case CRKind.STR:
				str ~= rval.str;
				break;
			case CRKind.INT:
				str ~= to!(string)(rval.numInt);
				break;
			case CRKind.REAL:
				str ~= to!(string)(rval.numReal);
				break;
			default: assert (0);
			}
			kind = CRKind.STR;
		}
		private void calc(string Calc, bool ChkDiv)(in CProps prop, in Token tok, ref CalcResult rval) {
			if (kind is CRKind.STR || rval.kind is CRKind.STR) {
				throwError(prop.msgs.scriptErrorInvalidNumber, tok);
			}
			static if (ChkDiv) {
				if ((rval.kind is CRKind.REAL ? rval.numReal : rval.numInt) == 0) {
					throwError(prop.msgs.scriptErrorZeroDivision, tok);
				}
			}
			if (kind is CRKind.REAL || rval.kind is CRKind.REAL) {
				real lvalue = kind is CRKind.REAL ? numReal : numInt;
				real rvalue = rval.kind is CRKind.REAL ? rval.numReal : rval.numInt;
				mixin ("numReal = lvalue " ~ Calc ~ " rvalue;");
				kind = CRKind.REAL;
			} else {
				assert (kind is CRKind.INT && rval.kind is CRKind.INT);
				mixin ("numInt " ~ Calc ~ "= rval.numInt;");
			}
		}
		public alias calc!("+", false) add;
		public alias calc!("-", false) min;
		public alias calc!("*", false) mul;
		public alias calc!("/", true) div;
		public alias calc!("%", true) res;
		int opEquals(int val) {
			return opEquals(cast(long) val);
		}
		int opEquals(long val) {
			switch (kind) {
			case CRKind.STR: return false;
			case CRKind.INT: return numInt == val;
			case CRKind.REAL: return numReal == val;
			default: assert (0);
			}
		}
		int opEquals(real val) {
			switch (kind) {
			case CRKind.STR: return false;
			case CRKind.INT: return numInt == val;
			case CRKind.REAL: return numReal == val;
			default: assert (0);
			}
		}
		int opEquals(string val) {
			return kind is CRKind.STR && str == val;
		}
		string toString() {
			switch (kind) {
			case CRKind.STR: return str;
			case CRKind.INT: return to!(string)(numInt);
			case CRKind.REAL: return to!(string)(numReal);
			default: assert (0);
			}
		}
	}
	private const OPE_LEVEL_MAX = 2;
	private CalcResult calcNum(in Token[] tokens, ref size_t i, Token[string] varTable, size_t strWidth) {
		assert (i < tokens.length);
		auto tok = tokens[i];
		if (tok.kind is Kind.VAR_NAME) {
			try {
				auto vt = var(tok, varTable);
				CalcResult r;
				if (vt.kind is Kind.STRING) {
					r.kind = CRKind.STR;
					r.str = stringValue(vt, strWidth);
				} else if (std.string.find(vt.value, '.') != -1) {
					r.kind = CRKind.REAL;
					r.numReal = to!(real)(vt.value);
				} else {
					r.kind = CRKind.INT;
					r.numInt = to!(long)(vt.value);
				}
				return r;
			} catch (Exception e) {
				throwError(_prop.msgs.scriptErrorReqNumber, tok);
			}
		}
		bool min = false;
		if (tok.kind is Kind.PLU) {
			i++;
			if (tokens[i].kind !is Kind.NUMBER) {
				throwError(_prop.msgs.scriptErrorInvalidNumber, tok);
			}
		} else if (tok.kind is Kind.MIN) {
			i++;
			if (tokens[i].kind !is Kind.NUMBER) {
				throwError(_prop.msgs.scriptErrorInvalidNumber, tok);
			}
			min = true;
		}
		if (tokens.length <= i || !(tokens[i].kind is Kind.NUMBER || tokens[i].kind is Kind.STRING)) {
			throwError(_prop.msgs.scriptErrorInvalidNumber, tok);
		}
		try {
			CalcResult r;
			if (tokens[i].kind is Kind.NUMBER) {
				if (std.string.find(tokens[i].value, '.') != -1) {
					r.kind = CRKind.REAL;
					r.numReal = to!(real)(tokens[i].value);
					if (min) r.numReal = -r.numReal;
				} else {
					r.kind = CRKind.INT;
					r.numInt = to!(long)(tokens[i].value);
					if (min) r.numInt = -r.numInt;
				}
			} else {
				assert (tokens[i].kind is Kind.STRING);
				r.kind = CRKind.STR;
				r.str = stringValue(tokens[i], 0);
			}
			i++;
			return r;
		} catch (Exception e) {
			throwError(_prop.msgs.scriptErrorReqNumber, tokens[i]);
		}
		assert (0);
	}
	private CalcResult calcPar(in Token[] tokens, ref size_t i, Token[string] varTable, size_t strWidth) {
		assert (i < tokens.length);
		auto tok = tokens[i];
		switch (tok.kind) {
		case Kind.O_PAR:
			i++;
			auto r = calcImpl(0, tokens, i, varTable, strWidth);
			if (tokens[i].kind !is Kind.C_PAR) {
				throwError(_prop.msgs.scriptErrorCloseParenNotFound, tok);
			}
			i++;
			return r;
		default:
			return calcNum(tokens, i, varTable, strWidth);
		}
	}
	private CalcResult calcImpl(size_t opeLevel, in Token[] tokens, ref size_t i, Token[string] varTable, size_t strWidth) {
		assert (i < tokens.length);
		CalcResult r;
		if (opeLevel >= OPE_LEVEL_MAX) {
			r = calcPar(tokens, i, varTable, strWidth);
		} else {
			r = calcImpl(opeLevel + 1, tokens, i, varTable, strWidth);
		}
		while (i < tokens.length) {
			auto tok = tokens[i];
			switch (opeLevel) {
			case 0:
				switch (tok.kind) {
				case Kind.CAT:
					i++;
					r.cat(_prop, tok, calcImpl(1, tokens, i, varTable, strWidth));
					break;
				default:
					return r;
				}
				break;
			case 1:
				switch (tok.kind) {
				case Kind.PLU:
					i++;
					r.add(_prop, tok, calcImpl(1, tokens, i, varTable, strWidth));
					break;
				case Kind.MIN:
					i++;
					r.min(_prop, tok, calcImpl(1, tokens, i, varTable, strWidth));
					break;
				default:
					return r;
				}
				break;
			case 2:
				switch (tok.kind) {
				case Kind.MUL:
					i++;
					r.mul(_prop, tok, calcPar(tokens, i, varTable, strWidth));
					break;
				case Kind.DIV:
					i++;
					r.div(_prop, tok, calcPar(tokens, i, varTable, strWidth));
					break;
				case Kind.RES:
					i++;
					r.res(_prop, tok, calcPar(tokens, i, varTable, strWidth));
					break;
				default:
					return r;
				}
				break;
			default: assert (0);
			}
		}
		return r;
	}
	/// tokensを計算式と看做し、計算結果の値を返す。
	CalcResult calc(in Token[] tokens, ref size_t i, Token[string] varTable, size_t strWidth) {
		assert (i < tokens.length);
		return calcImpl(0, tokens, i, varTable, strWidth);
	} unittest {
		size_t i;
		Token[] tokens;
		Token[string] varTable;
		varTable["$abc"] = Token(0, 0, Kind.NUMBER, "15");
		CWXScript s;
		i = 0;
		assert (s.calc(s.tokenize("(-42)"), i, varTable, 0) == -42);
		i = 0;
		assert (s.calc(s.tokenize("2*2+3"), i, varTable, 0) == 7);
		i = 0;
		assert (s.calc(s.tokenize("2*(2+3)"), i, varTable, 0) == 10);
		i = 0;
		assert (s.calc(s.tokenize("1+2*3"), i, varTable, 0) == 7);
		i = 0;
		assert (s.calc(s.tokenize("(1+2)*3"), i, varTable, 0) == 9);
		i = 0;
		assert (s.calc(s.tokenize("-3-3"), i, varTable, 0) == -6);
		i = 0;
		assert (s.calc(s.tokenize("2 * 3 % 4"), i, varTable, 0) == 2);
		i = 0;
		assert (s.calc(s.tokenize("3 + -3-3"), i, varTable, 0) == -3);
		i = 0;
		assert (s.calc(s.tokenize("1+2 * 3 % 4"), i, varTable, 0) == 3);
		i = 0;
		assert (s.calc(s.tokenize("1+2 ~ 3 % 4"), i, varTable, 0) == "33");
		i = 0;
		tokens = s.tokenize("1+2 * 3 % 4 + -3-$abc $abc");
		assert (s.calc(tokens, i, varTable, 0) == -15);
		assert (tokens[i].value == "$abc");
		i = 0;
		tokens = s.tokenize("(1+2) * 3 % 4 + (-3-3) if");
		assert (s.calc(tokens, i, varTable, 0) == -5);
		assert (tokens[i].value == "if");
	}

	private static struct Keywords {
		CType[string] keywords;
		string[CType] commands;
	}
	private static const Keywords KEYS;
	static this () {
		KEYS = Keywords([
			cast(string) "start":CType.START,
			cast(string) "gobattle":CType.START_BATTLE,
			cast(string) "endsc":CType.END,
			cast(string) "gameover":CType.END_BAD_END,
			cast(string) "goarea":CType.CHANGE_AREA,
			cast(string) "chback":CType.CHANGE_BG_IMAGE,
			cast(string) "effect":CType.EFFECT,
			cast(string) "break":CType.EFFECT_BREAK,
			cast(string) "gostart":CType.LINK_START,
			cast(string) "gopack":CType.LINK_PACKAGE,
			cast(string) "msg":CType.TALK_MESSAGE,
			cast(string) "dialog":CType.TALK_DIALOG,
			cast(string) "bgm":CType.PLAY_BGM,
			cast(string) "se":CType.PLAY_SOUND,
			cast(string) "wait":CType.WAIT,
			cast(string) "elapse":CType.ELAPSE_TIME,
			cast(string) "callstart":CType.CALL_START,
			cast(string) "callpack":CType.CALL_PACKAGE,
			cast(string) "brflag":CType.BRANCH_FLAG,
			cast(string) "brstepm":CType.BRANCH_MULTI_STEP,
			cast(string) "brstept":CType.BRANCH_STEP,
			cast(string) "selmember":CType.BRANCH_SELECT,
			cast(string) "brability":CType.BRANCH_ABILITY,
			cast(string) "brrandom":CType.BRANCH_RANDOM,
			cast(string) "brlevel":CType.BRANCH_LEVEL,
			cast(string) "brstatus":CType.BRANCH_STATUS,
			cast(string) "brcount":CType.BRANCH_PARTY_NUMBER,
			cast(string) "brarea":CType.BRANCH_AREA,
			cast(string) "brbattle":CType.BRANCH_BATTLE,
			cast(string) "bronbattle":CType.BRANCH_IS_BATTLE,
			cast(string) "brcast":CType.BRANCH_CAST,
			cast(string) "britem":CType.BRANCH_ITEM,
			cast(string) "brskill":CType.BRANCH_SKILL,
			cast(string) "brinfo":CType.BRANCH_INFO,
			cast(string) "brbeast":CType.BRANCH_BEAST,
			cast(string) "brmoney":CType.BRANCH_MONEY,
			cast(string) "brcoupon":CType.BRANCH_COUPON,
			cast(string) "brstamp":CType.BRANCH_COMPLETE_STAMP,
			cast(string) "brgossip":CType.BRANCH_GOSSIP,
			cast(string) "setflag":CType.SET_FLAG,
			cast(string) "setstep":CType.SET_STEP,
			cast(string) "stepup":CType.SET_STEP_UP,
			cast(string) "stepdown":CType.SET_STEP_DOWN,
			cast(string) "revflag":CType.REVERSE_FLAG,
			cast(string) "chkflag":CType.CHECK_FLAG,
			cast(string) "getcast":CType.GET_CAST,
			cast(string) "getitem":CType.GET_ITEM,
			cast(string) "getskill":CType.GET_SKILL,
			cast(string) "getinfo":CType.GET_INFO,
			cast(string) "getbeast":CType.GET_BEAST,
			cast(string) "getmoney":CType.GET_MONEY,
			cast(string) "getcoupon":CType.GET_COUPON,
			cast(string) "getstamp":CType.GET_COMPLETE_STAMP,
			cast(string) "getgossip":CType.GET_GOSSIP,
			cast(string) "losecast":CType.LOSE_CAST,
			cast(string) "loseitem":CType.LOSE_ITEM,
			cast(string) "loseskill":CType.LOSE_SKILL,
			cast(string) "loseinfo":CType.LOSE_INFO,
			cast(string) "losebeast":CType.LOSE_BEAST,
			cast(string) "losemoney":CType.LOSE_MONEY,
			cast(string) "losecoupon":CType.LOSE_COUPON,
			cast(string) "losestamp":CType.LOSE_COMPLETE_STAMP,
			cast(string) "losegossip":CType.LOSE_GOSSIP,
			cast(string) "showparty":CType.SHOW_PARTY,
			cast(string) "hideparty":CType.HIDE_PARTY,
			cast(string) "redraw":CType.REDISPLAY
		]);
		foreach (name, type; KEYS.keywords) {
			KEYS.commands[type] = name;
		}
	}

	/// ノードの型。
	enum NodeType {
		VAR_SET, /// 変数の設定。
		START, /// イベントツリーの起点。
		COMMAND, /// イベントコンテント。
		VALUES, /// VALUEの配列。
		VALUE, /// 配列の値。
	}

	/// スクリプトの解析結果として生成されるノード。
	struct Node {
		NodeType type; /// 型。
		Token token; /// 先頭のToken。
		Token[] texts = []; /// テキスト。
		Node[] attr; /// 属性。
		Node[] childs; /// 子ノード。
		alias childs values; /// ノードがVALUESの場合は格納されたVALUEノードの配列。
		Token[] calc; /// 計算式。
		alias calc var; /// 変数。
		Node[] beforeVars; /// ノードの直前に宣言された変数群。
		/// oと等しいか。
		int opEquals(Node* o) {
			return type == o.type && token == &o.token && texts == o.texts
				&& attr == o.attr && childs == o.childs && calc == o.calc
				&& beforeVars == o.beforeVars;
		}
		/// 文字列表現。
		string toString() {return code("    ");}
		/// このノードをスクリプトコードにして返す。
		string code(string indent) {return code("    ", "");}
		private string code(string indent, string indentValue) {
			string calcCode(Token[] calc) {
				char[] calcBuf;
				foreach (i, tok; calc) {
					if ((tok.kind is Kind.C_PAR)
							|| (i > 0 && calc[i - 1].kind is Kind.O_PAR)) {
						calcBuf ~= tok.value;
					} else {
						if (i > 0) calcBuf ~= " ";
						calcBuf ~= tok.value;
					}
				}
				return calcBuf;
			}
			if (type is NodeType.VAR_SET) {
				enforce(var.length > 0, new Exception("Invalid node", __FILE__, __LINE__));
				if (var[0].kind is Kind.STRING) {
					return .format("%s%s = %s", indentValue, token.value, var[0].value);
				} else {
					return .format("%s%s = %s", token.value, indentValue, calcCode(calc));
				}
			} else if (type is NodeType.VALUE) {
				if (var.length <= 1) {
					return token.value;
				} else {
					return calcCode(calc);
				}
			} else if (type is NodeType.VALUES) {
				string vals = "[";
				foreach (i, c; values) {
					if (i > 0) vals ~= ", ";
					vals ~= c.code(indent);
				}
				vals ~= "]";
				return vals;
			}
			string buf = "";
			foreach (var; beforeVars) {
				buf ~= .format("%s%s\n", indentValue, var.code(indent));
			}
			string attrs = "";
			if (token.kind is Kind.START) {
				attrs = " " ~ calcCode(texts);
			} else {
				foreach (i, a; attr) {
					auto ac = a.code(indent);
					if (a.type is NodeType.VALUES && i > 0) {
						attrs ~= "\n";
						attrs ~= indentValue;
						attrs ~= .rjustify("", token.value.length + 1);
						attrs ~= ac;
					} else {
						attrs ~= " ";
						attrs ~= ac;
					}
				}
			}
			buf ~= .format("%s%s%s", indentValue, token.value, attrs);
			size_t clen = 0;
			Node first;
			bool setFirst = false;
			foreach (c; childs) {
				if (c.type !is NodeType.VAR_SET) {
					clen++;
					if (!setFirst) {
						first = c;
						setFirst = true;
					}
				}
			}
			if (clen > 1) {
				size_t j = 0;
				foreach (c; childs) {
					if (c.type is NodeType.VAR_SET) {
						buf ~= "\n";
						buf ~= c.code(indent, indentValue);
					} else {
						buf ~= "\n";
						string f = j == 0 ? "if" : "elif";
						buf ~= .format("%s%s %s\n", indentValue, f, calcCode(c.texts));
						buf ~= c.code(indent, indentValue ~ indent);
						j++;
					}
				}
				if (clen) {
					buf ~= "\n";
					buf ~= indentValue;
				}
				buf ~= "fi";
			} else if (clen == 1) {
				if (first.texts.length) {
					buf ~= "\n";
					buf ~= indentValue;
					buf ~= "sif ";
					buf ~= calcCode(first.texts);
				}
				if (token.kind is Kind.START) {
					indentValue ~= indent;
				}
				foreach (i, c; childs) {
					buf ~= "\n";
					buf ~= c.code(indent, indentValue);
				}
			}
			return buf;
		}
	}

	/// 属性値を文字列にして返す。
	private string attrValue(in Node node, Token[string] varTable, size_t strWidth) {
		switch (node.token.kind) {
		case Kind.SYMBOL: return std.string.tolower(node.token.value);
		case Kind.VAR_NAME:
			auto tok = var(node.token, varTable);
			if (tok.kind is Kind.STRING) {
				return stringValue(tok, strWidth);
			} else if (tok.kind is Kind.SYMBOL) {
				return std.string.tolower(tok.value);
			}
			goto case Kind.NUMBER;
		case Kind.STRING, Kind.NUMBER, Kind.PLU, Kind.MIN, Kind.O_PAR:
			size_t i = 0;
			auto r = calc(node.calc, i, varTable, strWidth);
			switch (r.kind) {
			case CRKind.STR: return r.str;
			case CRKind.INT: return to!(string)(r.numInt);
			case CRKind.REAL: return to!(string)(r.numReal);
			default: assert (0);
			}
		case Kind.O_BRA: return "";
		default: throwError(_prop.msgs.scriptErrorInvalidAttr, node.token);
		}
		assert (0);
	}
	/// 変数値をTokenとして返す。
	private Token varValue(in Node node, in Token[] toks, Token[string] varTable, size_t strWidth) {
		if (!toks.length) {
			throwError(_prop.msgs.scriptErrorInvalidVar, node.token);
		}
		switch (toks[0].kind) {
		case Kind.VAR_NAME:
			if (toks.length > 1) goto case Kind.NUMBER;
			auto tok = var(toks[0], varTable);
			if (tok.kind is Kind.STRING || tok.kind is Kind.SYMBOL) {
				return tok;
			}
			goto case Kind.NUMBER;
		case Kind.STRING, Kind.NUMBER, Kind.PLU, Kind.MIN, Kind.O_PAR:
			size_t i = 0;
			Token tok = toks[0];
			auto r = calc(toks, i, varTable, strWidth);
			tok.kind = r.kind is CRKind.STR ? Kind.STRING : Kind.NUMBER;
			switch (r.kind) {
			case CRKind.STR:
				tok.value = `"` ~ encodeString(r.str) ~ `"`;
				break;
			case CRKind.INT:
				tok.value = to!(string)(r.numInt);
				break;
			case CRKind.REAL:
				tok.value = to!(string)(r.numReal);
				break;
			default: assert (0);
			}
			return tok;
		case Kind.SYMBOL:
			return toks[0];
		default:
			throwError(_prop.msgs.scriptErrorInvalidVarVal, toks[0]);
		}
		assert (0);
	}
	private Token var(in Node node, in Token[string] varTable) {
		return var(node.token, varTable);
	}
	private Token var(in Token tok, in Token[string] varTable) {
		if (tok.kind is Kind.VAR_NAME) {
			auto ptr = std.string.tolower(tok.value) in varTable;
			if (ptr) return var(*ptr, varTable);
			throwError(_prop.msgs.scriptErrorUndefinedVar, tok);
		}
		return tok;
	}

	/// tokensを解釈し、Nodeのツリーに再編成する。
	Node[] analyzeSyntax(in Token[] tokens) {
		Node[] r;
		size_t i = 0;
		Node[] vars;
		while (i < tokens.length) {
			auto tok = tokens[i];
			if (tok.kind is Kind.VAR_NAME) {
				vars ~= analyzeSyntaxVar(tokens, i, KEYS);
				continue;
			}
			if (tok.kind !is Kind.START) {
				r ~= analyzeSyntaxBranch(tokens, i, KEYS);
				r[$ - 1].beforeVars = vars;
				vars = [];
				continue;
			}
			i++;
			Node node;
			node.type = NodeType.START;
			node.token = tok;
			node.texts = analyzeSyntaxValue(tokens, i, KEYS);
			if (!node.texts.length) {
				throwError(_prop.msgs.scriptErrorNoStartText, tok);
			}
			node.beforeVars = vars;
			c: while (i < tokens.length) {
				string cText = "";
				switch (tokens[i].kind) {
				case Kind.START, Kind.FI, Kind.VAR_NAME: break c;
				case Kind.IF, Kind.ELIF, Kind.SYMBOL, Kind.SIF:
					node.childs ~= analyzeSyntaxBranch(tokens, i, KEYS);
					continue;
				default:
					throwError(_prop.msgs.scriptErrorInvalidStatement, tokens[i]);
				}
			}
			r ~= node;
			vars = [];
		}
		return r;
	} unittest {
		CWXScript s;
		string statement
= `
$var1 = 'oops'
Start "First start"
if 'abc'
    chback ['mapofwirth.bmp', '',  0, 0, 632, 420],
           ['definn.bmp', '', 50, 50, 200*2, 260],
           ['card.bmp', 'card\mate1', 230, 50, 74, 94, mask]
    hideparty
    $var2 = 3.5
    wait  ($var2 + 1.5)
    msg M
    @ 3
    Talk!
    Talk!
    Talk!
    @
    sif "Single IF"
    brflag 'card\mate1'
    if true
        $var3 = 'what?'
        showparty
        endsc true
        $var_dummy = noshing
    elif false
        gameover    // comment1
    fi
elif 'def' effect 1,  2, 3 + 2
fi
// comment2
$var4 = true
start "second start"
    showparty
    getskill 1`;
		auto tokens = s.tokenize(statement);
		auto starts = s.analyzeSyntax(tokens);
		assert (starts[0].code("    ")
			== "$var1 = 'oops'\n"
			~ "Start \"First start\"\n"
			~ "if 'abc'\n"
			~ "    chback ['mapofwirth.bmp', '', 0, 0, 632, 420]\n"
			~ "           ['definn.bmp', '', 50, 50, 200 * 2, 260]\n"
			~ "           ['card.bmp', 'card\\mate1', 230, 50, 74, 94, mask]\n"
			~ "    hideparty\n"
			~ "    $var2 = 3.5\n"
			~ "    wait ($var2 + 1.5)\n"
			~ "    msg M @ 3\n"
			~ "    Talk!\n"
			~ "    Talk!\n"
			~ "    Talk!\n"
			~ "    @\n"
			~ "    sif \"Single IF\"\n"
			~ "    brflag 'card\\mate1'\n"
			~ "    if true\n"
			~ "        $var3 = 'what?'\n"
			~ "        showparty\n"
			~ "        endsc true\n"
			~ "    elif false\n"
			~ "        gameover\n"
			~ "    fi\n"
			~ "elif 'def'\n"
			~ "    effect 1 2 3 + 2\n"
			~ "fi");
		assert (starts[1].code("    ")
			== "$var4 = true\n"
			~ "start \"second start\"\n"
			~ "    showparty\n"
			~ "    getskill 1");

		string statement2
= `
brflag 'card\mate1'
if true
    $var3 = 'what?'
    showparty
    endsc true
    $var_dummy = noshing
elif false
    gameover    // comment1
fi`;
		auto tokens2 = s.tokenize(statement2);
		auto contents = s.analyzeSyntax(tokens2);
		assert (contents[0].code("    ")
			== "brflag 'card\\mate1'\n"
			~ "if true\n"
			~ "    $var3 = 'what?'\n"
			~ "    showparty\n"
			~ "    endsc true\n"
			~ "elif false\n"
			~ "    gameover\n"
			~ "fi");
	}

	private Node[] analyzeSyntaxBranch(in Token[] tokens, ref size_t i, in Keywords keys) {
		Node[] r;
		auto tok = tokens[i];
		bool sif = false;
		switch (tok.kind) {
		case Kind.START: return r;
		case Kind.SIF:
			sif = true;
			goto case Kind.IF;
		case Kind.IF, Kind.VAR_NAME:
			while (i < tokens.length) {
				Token[] texts;
				if (tokens[i].kind is Kind.IF || tokens[i].kind is Kind.ELIF || tokens[i].kind is Kind.SIF) {
					i++;
					texts = analyzeSyntaxValue(tokens, i, keys);
					if (!texts.length) {
						throwError(_prop.msgs.scriptErrorNoIfText, tok);
					}
					if (tokens.length <= i) {
						throwError(_prop.msgs.scriptErrorNoIfContents, tok);
					}
				}
				auto node = analyzeSyntaxStatement(tokens, i, keys);
				node.texts = texts;
				r ~= node;
				if (sif) return r;
				if (tokens.length <= i) return r;
				switch (tokens[i].kind) {
				case Kind.START: return r;
				case Kind.FI: i++; return r;
				case Kind.ELIF: continue;
				case Kind.VAR_NAME: continue;
				default:
					throwError(_prop.msgs.scriptErrorInvalidStatement, tokens[i]);
				}
			}
			break;
		case Kind.SYMBOL:
			r ~= analyzeSyntaxStatement(tokens, i, keys);
			break;
		default:
			throwError(_prop.msgs.scriptErrorInvalidBranch, tok);
			break;
		}
		return r;
	}
	private Node[] eatVarSet(in Token[] tokens, ref size_t i, in Keywords keys) {
		Node[] r;
		while (i < tokens.length && tokens[i].kind is Kind.VAR_NAME) {
			r ~= analyzeSyntaxVar(tokens, i, keys);
		}
		return r;
	}
	private Node analyzeSyntaxStatement(in Token[] tokens, ref size_t i, in Keywords keys) {
		assert (i < tokens.length);
		auto vars = eatVarSet(tokens, i, keys);
		auto tok = tokens[i];
		if (tok.kind !is Kind.SYMBOL) {
			throwError(_prop.msgs.scriptErrorInvalidStatement, tok);
		}
		Node node;
		node.type = NodeType.COMMAND;
		node.token = tok;
		auto symbol = std.string.tolower(tok.value);
		if (!(symbol in keys.keywords)) {
			throwError(_prop.msgs.scriptErrorInvalidKeyword, tok);
		}
		node.beforeVars = vars;
		i++;
		if (tokens.length <= i) return node;
		node.attr = analyzeSyntaxAttr(tokens, i, keys);
		if (tokens.length <= i) return node;
		switch (tokens[i].kind) {
		case Kind.START, Kind.ELIF, Kind.FI:
			break;
		case Kind.VAR_NAME:
			size_t j = i;
			auto cVars = eatVarSet(tokens, j, keys);
			if (tokens.length <= j) return node;
			if (tokens[j].kind is Kind.START) return node;
			i = j;
			if (tokens[i].kind is Kind.IF || tokens[i].kind is Kind.SIF || tokens[i].kind is Kind.SYMBOL) {
				node.childs ~= analyzeSyntaxBranch(tokens, i, keys);
				node.childs[0].beforeVars = cVars;
				break;
			}
			break;
		case Kind.IF, Kind.SIF, Kind.SYMBOL:
			node.childs ~= analyzeSyntaxBranch(tokens, i, keys);
			break;
		default:
			throwError(_prop.msgs.scriptErrorInvalidStatement, tok);
		}
		return node;
	}
	private Node[] analyzeSyntaxAttr(in Token[] tokens, ref size_t i, in Keywords keys) {
		Node[] r;
		while (i < tokens.length) {
			auto tok = tokens[i];
			if (r.length > 0 && tok.kind is Kind.COMMA) {
				i++;
				tok = tokens[i];
			}
			switch (tok.kind) {
			case Kind.O_BRA:
				r ~= analyzeSyntaxBrackets(tokens, i, keys);
				i++;
				break;
			case Kind.START, Kind.IF, Kind.ELIF, Kind.FI, Kind.SIF:
				return r;
			case Kind.SYMBOL, Kind.NUMBER, Kind.STRING, Kind.PLU, Kind.MIN, Kind.O_PAR:
				if (std.string.tolower(tok.value) in keys.keywords) return r;
				Node node;
				node.type = NodeType.VALUE;
				node.token = tok;
				node.var = analyzeSyntaxValue(tokens, i, keys);
				r ~= node;
				break;
			case Kind.VAR_NAME:
				if (i + 1 < tokens.length && tokens[i + 1].kind is Kind.EQ) {
					return r;
				}
				goto case Kind.SYMBOL;
			default:
				throwError(_prop.msgs.scriptErrorInvalidAttr, tok);
			}
		}
		return r;
	} unittest {
		CWXScript s;
		Token[] tokens;
		size_t i;
		tokens = s.tokenize(`goarea`);
		i = 0;
		assert (s.analyzeSyntaxAttr(tokens, i, KEYS).length == 0);
		tokens = s.tokenize(`area, 1, "="if "next"`);
		i = 0;
		auto arr = [
			Node(NodeType.VALUE, Token(0, 0, Kind.SYMBOL, "area")),
			Node(NodeType.VALUE, Token(0, 6, Kind.NUMBER, "1")),
			Node(NodeType.VALUE, Token(0, 9, Kind.STRING, `"="`))
		];
		arr[0].var ~= arr[0].token;
		arr[1].var ~= arr[1].token;
		arr[2].var ~= arr[2].token;
		assert (s.analyzeSyntaxAttr(tokens, i, KEYS) == arr);
		assert (tokens[i].kind is Kind.IF);
		tokens = s.tokenize(`area, 1, "="Start`);
		i = 0;
		assert (s.analyzeSyntaxAttr(tokens, i, KEYS) == arr);
		assert (tokens[i].value == "Start");
	}
	private Node analyzeSyntaxBrackets(in Token[] tokens, ref size_t i, in Keywords keys) {
		assert (i < tokens.length);
		auto o = tokens[i];
		if (o.kind !is Kind.O_BRA) {
			throwError(_prop.msgs.scriptErrorInvalidValuesOpen, o);
		}
		Node r;
		r.type = NodeType.VALUES;
		r.token = o;
		i++;
		while (i < tokens.length) {
			auto tok = tokens[i];
			if (tok.kind is Kind.C_BRA) {
				return r;
			}
			if (r.values.length > 0) {
				if (tok.kind !is Kind.COMMA) {
					throwError(_prop.msgs.scriptErrorCommaNotFound, tok);
				}
				i++;
				tok = tokens[i];
			}
			switch (tok.kind) {
			case Kind.O_BRA:
				r.values ~= analyzeSyntaxBrackets(tokens, i, keys);
				i++;
				break;
			case Kind.SYMBOL, Kind.NUMBER, Kind.STRING, Kind.VAR_NAME, Kind.O_PAR, Kind.PLU, Kind.MIN:
				auto node = Node(NodeType.VALUE, tok);
				node.var = analyzeSyntaxValue(tokens, i, keys);
				r.values ~= node;
				break;
			default:
				throwError(_prop.msgs.scriptErrorInvalidValuesClose, tok);
			}
		}
		throwError(_prop.msgs.scriptErrorCloseBracketNotFound, o);
		return r;
	}
	private Node analyzeSyntaxVar(in Token[] tokens, ref size_t i, in Keywords keys) {
		assert (i < tokens.length);
		auto tok = tokens[i];
		if (tok.kind !is Kind.VAR_NAME) {
			throwError(_prop.msgs.scriptErrorInvalidVar, tok);
		}
		i++;
		if (tokens.length <= i || tokens[i].kind !is Kind.EQ) {
			throwError(_prop.msgs.scriptErrorNoVarSet, tokens[i]);
		}
		Node node;
		node.type = NodeType.VAR_SET;
		node.token = tok;
		i++;
		if (tokens.length <= i) {
			throwError(_prop.msgs.scriptErrorNoVarVal, tok);
		}
		node.var = analyzeSyntaxValue(tokens, i, keys);
		return node;
	}
	private Token[] analyzeSyntaxValue(in Token[] tokens, ref size_t i, in Keywords keys) {
		Token[] r;
		bool calcin = false;
		bool num = true;
		while (i < tokens.length) {
			auto tok = tokens[i];
			switch (tok.kind) {
			case Kind.VAR_NAME:
				if (!num) return r;
				goto case Kind.NUMBER;
			case Kind.NUMBER, Kind.STRING:
				if (!num) throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
				r ~= tok;
				i++;
				calcin = true;
				num = false;
				break;
			case Kind.PLU, Kind.MIN:
				if (num) {
					r ~= tok;
					i++;
					r ~= tokens[i];
					i++;
					calcin = true;
					num = false;
					break;
				} else {
					goto case Kind.MUL;
				}
			case Kind.O_PAR:
				if (!num && calcin) throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
				r ~= tok;
				i++;
				calcin = true;
				break;
			case Kind.C_PAR:
				if (num) throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
				r ~= tok;
				i++;
				break;
			case Kind.MUL, Kind.DIV, Kind.RES, Kind.CAT:
				if (num) throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
				r ~= tok;
				num = true;
				i++;
				break;
			case Kind.COMMA:
				if (!r.length) throwError(_prop.msgs.scriptErrorInvalidValue, tok);
				return r;
			case Kind.SYMBOL:
				if (!calcin) {
					r ~= tok;
					i++;
				}
				return r;
			case Kind.O_BRA, Kind.C_BRA:
			case Kind.START, Kind.IF, Kind.FI, Kind.ELIF, Kind.SIF, Kind.EQ:
				return r;
			default:
				throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
			}
		}
		return r;
	}

	private T parseAttr(T, bool Within = false)(in Node[] attr, ref size_t i, lazy T defValue, in Token[string] varTable, size_t msgWidth = 0) {
		if (attr.length <= i) return defValue;
		auto tok = var(attr[i], varTable);
		auto value = attrValue(attr[i], varTable, msgWidth);
		static if (is(T == string)) {
			if (attr[i].token.kind is Kind.SYMBOL && value == "stop") {
				/// BGM停止用
				i++;
				return "";
			}
			i++;
			return value;
		} else static if (isVArray!(T)) {
			T r;
			while (i < attr.length) {
				if (attr[i].type !is NodeType.VALUES) break;
				size_t i2 = i;
				r ~= parseAttr!(typeof(T[0]), Within)(attr, i, typeof(T[0]).init, varTable);
				if (i2 == i) break;
			}
			return r;
		} else static if (is(T == bool)) {
			switch (value) {
			case "true", "yes", "on", "all", "random", "average", "complete":
				i++;
				return true;
			case "false", "no", "off", "active", "manual", "max", "nocomplete":
				i++;
				return false;
			default: throwError(_prop.msgs.scriptErrorInvalidBoolVal, tok);
			}
		} else static if (is(T == Transition)) {
			switch (value) {
			case "default": i++; return Transition.DEFAULT;
			case "none": i++; return Transition.NONE;
			case "fade": i++; return Transition.FADE;
			case "dissolve": i++; return Transition.PIXEL_DISSOLVE;
			case "blinds": i++; return Transition.BLINDS;
			default: throwError(_prop.msgs.scriptErrorInvalidTransition, tok);
			}
		} else static if (is(T == Range)) {
			switch (value) {
			case "m", "selected": i++; return Range.SELECTED;
			case "r", "random", "one": i++; return Range.RANDOM;
			case "t", "team": i++; return Range.PARTY;
			case "backpack":
				static if (Within) goto default;
				i++;
				return Range.BACKPACK;
			case "party":
				static if (Within) goto case "team";
				i++;
				return Range.PARTY_AND_BACKPACK;
			case "field":
				static if (Within) goto default;
				i++;
				return Range.FIELD;
			default: throwError(_prop.msgs.scriptErrorInvalidRange, tok);
			}
		} else static if (is(T == Status)) {
			switch (value) {
			case "active": i++; return Status.ACTIVE;
			case "inactive": i++; return Status.INACTIVE;
			case "alive": i++; return Status.ALIVE;
			case "dead": i++; return Status.DEAD;
			case "fine": i++; return Status.FINE;
			case "injured": i++; return Status.INJURED;
			case "heavyinjured": i++; return Status.HEAVY_INJURED;
			case "unconscious": i++; return Status.UNCONSCIOUS;
			case "poison": i++; return Status.POISON;
			case "sleep": i++; return Status.SLEEP;
			case "bind": i++; return Status.BIND;
			case "paralyze": i++; return Status.PARALYZE;
			default: throwError(_prop.msgs.scriptErrorInvalidStatus, tok);
			}
		} else static if (is(T == Target)) {
			bool sleep = false;
			static if (!Within) {
				// 睡眠者対象
				size_t j = i + 1;
				sleep = parseAttr!(bool)(attr, j, false, varTable);
			}
			switch (value) {
			case "m", "selected":
				i++;
				static if (!Within) i++;
				return Target(Target.M.SELECTED, sleep);
			case "r", "random", "one":
				i++;
				static if (!Within) i++;
				return Target(Target.M.RANDOM, sleep);
			case "u", "unselected":
				i++;
				static if (!Within) i++;
				return Target(Target.M.UNSELECTED, sleep);
			case "t", "team":
				i++;
				static if (!Within) i++;
				return Target(Target.M.PARTY, sleep);
			default: throwError(_prop.msgs.scriptErrorInvalidTarget, tok);
			}
		} else static if (is(T == EffectType)) {
			switch (value) {
			case "physic": i++; return EffectType.PHYSIC;
			case "magic": i++; return EffectType.MAGIC;
			case "mphysic": i++; return EffectType.MAGICAL_PHYSIC;
			case "pmagic": i++; return EffectType.PHYSICAL_MAGIC;
			case "none": i++; return EffectType.NONE;
			default: throwError(_prop.msgs.scriptErrorInvalidEffectType, tok);
			}
		} else static if (is(T == Resist)) {
			switch (value) {
			case "avoid": i++; return Resist.AVOID;
			case "resist": i++; return Resist.RESIST;
			case "unfail": i++; return Resist.UNFAIL;
			default: throwError(_prop.msgs.scriptErrorInvalidResist, tok);
			}
		} else static if (is(T == CardVisual)) {
			switch (value) {
			case "none": i++; return CardVisual.NONE;
			case "reverse": i++; return CardVisual.REVERSE;
			case "hswing": i++; return CardVisual.HORIZONTAL;
			case "vswing": i++; return CardVisual.VERTICAL;
			default: throwError(_prop.msgs.scriptErrorInvalidCardVisual, tok);
			}
		} else static if (is(T == Mental)) {
			switch (value) {
			case "agg": i++; return Mental.AGGRESSIVE;
			case "unagg": i++; return Mental.UNAGGRESSIVE;
			case "cheerf": i++; return Mental.CHEERFUL;
			case "uncheerf": i++; return Mental.UNCHEERFUL;
			case "brave": i++; return Mental.BRAVE;
			case "unbrave": i++; return Mental.UNBRAVE;
			case "caut": i++; return Mental.CAUTIOUS;
			case "uncaut": i++; return Mental.UNCAUTIOUS;
			case "trick": i++; return Mental.TRICKISH;
			case "untrick": i++; return Mental.UNTRICKISH;
			default: throwError(_prop.msgs.scriptErrorInvalidMental, tok);
			}
		} else static if (is(T == Physical)) {
			switch (value) {
			case "dex": i++; return Physical.DEX;
			case "agl": i++; return Physical.AGL;
			case "int": i++; return Physical.INT;
			case "str": i++; return Physical.STR;
			case "vit": i++; return Physical.VIT;
			case "min": i++; return Physical.MIN;
			default: throwError(_prop.msgs.scriptErrorInvalidPhysical, tok);
			}
		} else static if (is(T == Talker)) {
			return parseTalker!(Within)(attr, i, varTable);
		} else static if (is(T == MType)) {
			switch (value) {
			case "heal": i++; return MType.HEAL;
			case "damage": i++; return MType.DAMAGE;
			case "absorb": i++; return MType.ABSORB;
			case "paralyze": i++; return MType.PARALYZE;
			case "disparalyze": i++; return MType.DIS_PARALYZE;
			case "poison": i++; return MType.POISON;
			case "dispoison": i++; return MType.DIS_POISON;
			case "getspilit": i++; return MType.GET_SKILL_POWER;
			case "losespilit": i++; return MType.LOSE_SKILL_POWER;
			case "sleep": i++; return MType.SLEEP;
			case "confuse": i++; return MType.CONFUSE;
			case "overheat": i++; return MType.OVERHEAT;
			case "brave": i++; return MType.BRAVE;
			case "panic": i++; return MType.PANIC;
			case "resetfeel": i++; return MType.NORMAL;
			case "bind": i++; return MType.BIND;
			case "disbind": i++; return MType.DIS_BIND;
			case "silence": i++; return MType.SILENCE;
			case "dissilence": i++; return MType.DIS_SILENCE;
			case "faceup": i++; return MType.FACE_UP;
			case "facedown": i++; return MType.FACE_DOWN;
			case "antimagic": i++; return MType.ANTI_MAGIC;
			case "disantimagic": i++; return MType.DIS_ANTI_MAGIC;
			case "enhaction": i++; return MType.ENHANCE_ACTION;
			case "enhavoid": i++; return MType.ENHANCE_AVOID;
			case "enhresist": i++; return MType.ENHANCE_RESIST;
			case "enhdefense": i++; return MType.ENHANCE_DEFENSE;
			case "vantarget": i++; return MType.VANISH_TARGET;
			case "vancard": i++; return MType.VANISH_CARD;
			case "vanbeast": i++; return MType.VANISH_BEAST;
			case "dealattack": i++; return MType.DEAL_ATTACK_CARD;
			case "dealpowerful": i++; return MType.DEAL_POWERFUL_ATTACK_CARD;
			case "dealcritical": i++; return MType.DEAL_CRITICAL_ATTACK_CARD;
			case "dealfeint": i++; return MType.DEAL_FEINT_CARD;
			case "dealdefense": i++; return MType.DEAL_DEFENSE_CARD;
			case "dealdistance": i++; return MType.DEAL_DISTANCE_CARD;
			case "dealconfuse": i++; return MType.DEAL_CONFUSE_CARD;
			case "dealskill": i++; return MType.DEAL_SKILL_CARD;
			case "summon": i++; return MType.SUMMON_BEAST;
			default: throwError(_prop.msgs.scriptErrorInvalidMotionType, tok);
			}
		} else static if (is(T == Element)) {
			switch (value) {
			case "all": i++; return Element.ALL;
			case "phy": i++; return Element.HEALTH;
			case "mind": i++; return Element.MIND;
			case "holy": i++; return Element.MIRACLE;
			case "magic": i++; return Element.MAGIC;
			case "fire": i++; return Element.FIRE;
			case "ice": i++; return Element.ICE;
			default: throwError(_prop.msgs.scriptErrorInvalidElement, tok);
			}
		} else static if (is(T == DamageType)) {
			switch (value) {
			case "level": i++; return DamageType.LEVEL_RATIO;
			case "value": i++; return DamageType.NORMAL;
			case "max": i++; return DamageType.MAX;
			default: throwError(_prop.msgs.scriptErrorInvalidDamageType, tok);
			}
		} else static if (is(T == BgImage)) {
			if (attr[i].type !is NodeType.VALUES) {
				throwError(_prop.msgs.scriptErrorInvalidBgImage, tok);
			}
			size_t j = 0;
			auto vals = attr[i].values;
			string path = decodePath(parseAttr!(string)(vals, j, "", varTable));
			string flag = parseAttr!(string)(vals, j, "", varTable);
			int x = parseAttr!(int)(vals, j, 0, varTable);
			int y = parseAttr!(int)(vals, j, 0, varTable);
			auto size = _prop.looks.viewSize;
			int w = parseAttr!(int)(vals, j, size.width, varTable);
			int h = parseAttr!(int)(vals, j, size.height, varTable);
			bool mask = parseAttr!(bool)(vals, j, false, varTable);
			auto r = new BgImage(path, flag, x, y, w, h, mask);
			i++;
			return r;
		} else static if (is(T == Motion)) {
			if (attr[i].type !is NodeType.VALUES) {
				throwError(_prop.msgs.scriptErrorInvalidMotion, tok);
			}
			size_t j = 0;
			auto vals = attr[i].values;
			MType type = parseAttr!(MType)(vals, j, MType.HEAL, varTable);
			auto r = new Motion(type, Element.ALL);
			auto detail = r.detail;
			if (detail.use(MArg.VALUE_TYPE)) {
				r.damageType = parseAttr!(DamageType)(vals, j, r.damageType, varTable);
			}
			if (detail.use(MArg.U_VALUE)) {
				r.uValue = parseAttr!(int)(vals, j, r.uValue, varTable);
			}
			if (detail.use(MArg.A_VALUE)) {
				r.aValue = parseAttr!(int)(vals, j, r.aValue, varTable);
			}
			if (detail.use(MArg.ROUND)) {
				r.round = parseAttr!(int)(vals, j, r.round, varTable);
			}
			if (detail.use(MArg.BEAST)) {
				ulong beast = parseAttr!(ulong)(vals, j, 0, varTable);
				if (beast != 0 && _summ) r.beast = _summ.beast(beast);
			}
			r.element = parseAttr!(Element)(vals, j, Element.ALL, varTable);
			i++;
			return r;
		} else static if (is(T == SDialog)) {
			if (attr[i].type !is NodeType.VALUES) {
				throwError(_prop.msgs.scriptErrorInvalidDialog, tok);
			}
			size_t j = 0;
			auto vals = attr[i].values;
			auto r = new SDialog;
			if (vals.length > 1) {
				if (vals[j].type is NodeType.VALUES) {
					string[] cs;
					foreach (v; vals[j].values) {
						cs ~= attrValue(v, varTable, 0);
					}
					r.rCoupons = cs;
					j++;
				} else {
					r.rCoupons = std.string.split(parseAttr!(string)(vals, j, "", varTable), ";");
				}
			}
			r.text = parseAttr!(string)(vals, j, r.text, varTable, msgWidth);
			i++;
			return r;
		} else static if (is(T == int)) {
			if (attr[i].token.kind is Kind.SYMBOL && value == "all") {
				return 0; // カード削除用
			}
			try {
				auto r = to!(int)(value);
				i++;
				return r;
			} catch (Exception e) {
				throwError(_prop.msgs.scriptErrorReqNumber, tok);
			}
		} else static if (is(T == ulong)) {
			try {
				auto r = to!(ulong)(value);
				i++;
				return r;
			} catch (Exception e) {
				throwError(_prop.msgs.scriptErrorReqID, tok);
			}
		} else static assert (0);
	}
	private void parseAttrTalker(in Node[] attr, ref size_t i, ref Talker t, ref string cardPath, in Token[string] varTable) {
		if (attr.length <= i) return;
		auto tok = var(attr[i], varTable);
		auto value = attrValue(attr[i], varTable, 0);
		if (tok.kind is Kind.STRING) {
			t = Talker.IMAGE;
			cardPath = value;
			i++;
			return;
		}
		cardPath = "";
		t = parseTalker!(false)(attr, i, varTable);
	}
	private Talker parseTalker(bool Within)(in Node[] attr, ref size_t i, in Token[string] varTable) {
		auto node = attr[i];
		auto tok = var(node, varTable);
		auto value = attrValue(node, varTable, 0);
		switch (value) {
		case "n", "none":
			static if (Within) goto default;
			i++;
			return Talker.NARRATION;
		case "m", "selected": i++; return Talker.SELECTED;
		case "u", "unselected": i++; return Talker.UNSELECTED;
		case "r", "random": i++; return Talker.RANDOM;
		case "c", "card":
			static if (Within) goto default;
			i++;
			return Talker.CARD;
		default: throwError(_prop.msgs.scriptErrorInvalidTalker, tok);
		}
		assert (0);
	}
	private string parseNextValue(in Node node, in Keywords keys, in Token[string] varTable) {
		if (!node.texts.length) return "";
		auto value = varValue(node, node.texts, varTable, 0);
		string r;
		if (value.kind is Kind.SYMBOL) {
			auto valStr = std.string.tolower(value.value);
			if (valStr in keys.keywords) {
				throwError(_prop.msgs.scriptErrorUndefinedSymbol, node.token);
			}
			switch (valStr) {
			case "default":
				r = _prop.msgs.evtChildDefault;
				break;
			case "select", "over", "true", "success", "yes", "has", "on":
				r = _prop.msgs.evtChildTrue;
				break;
			case "cancel", "under", "false", "failure", "no", "hasnot", "off":
				r = _prop.msgs.evtChildFalse;
				break;
			default:
				throwError(_prop.msgs.scriptErrorUndefinedSymbol, node.token);
			}
		} else {
			switch (value.kind) {
			case Kind.STRING: r = stringValue(value, 0); break;
			case Kind.NUMBER: r = to!(string)(value.value); break;
			default: throwError(_prop.msgs.scriptErrorInvalidValue, value);
			}
		}
		return r;
	}

	/// Nodeツリーをコンテント群にして返す。
	Content[] analyzeSemantics(in Node[] nodes) {
		Token[string] varTable;
		auto cs = analyzeSemanticsImpl(nodes, KEYS, varTable);
		if (cs.length) {
			bool starts = cs[0].type is CType.START;
			foreach (c; cs[1 .. $]) {
				if ((c.type is CType.START) !is starts) {
					if (starts) {
						throwError(_prop.msgs.scriptErrorStartsMixedContent, nodes[0].token);
					} else {
						throwError(_prop.msgs.scriptErrorContentsMixedStart, nodes[0].token);
					}
				}
			}
		}
		return cs;
	}
	private Content[] analyzeSemanticsImpl(in Node[] nodes, in Keywords keys, Token[string] varTable) {
		Content[] r;
		foreach (node; nodes) {
			foreach (var; node.beforeVars) {
				if (var.type !is NodeType.VAR_SET) {
					throwError(_prop.msgs.scriptErrorInvalidVar, var.token);
				}
				varTable[std.string.tolower(var.token.value)] = varValue(var, var.var, varTable, 0);
			}
			if (node.type is NodeType.VAR_SET) {
				varTable[std.string.tolower(node.token.value)] = varValue(node, node.var, varTable, 0);
				continue;
			}
			if (node.type !is NodeType.COMMAND && node.type !is NodeType.START) {
				throwError(_prop.msgs.scriptErrorInvalidCommand, node.token);
			}
			string val = std.string.tolower(node.token.value);
			auto cmdPtr = val in KEYS.keywords;
			if (!cmdPtr) {
				throwError(_prop.msgs.scriptErrorInvalidCommand, node.token);
			}
			auto c = new Content(*cmdPtr, parseNextValue(node, keys, varTable));
			size_t i = 0;
			auto detail = c.detail;
			if (detail.use(CArg.TALKER_C)) {
				Talker t = c.talkerC;
				string path = encodePath(c.cardPath);
				parseAttrTalker(node.attr, i, t, path, varTable);
				c.talkerC = t;
				c.cardPath = decodePath(path);
			}
			if (detail.use(CArg.TEXT)) {
				c.text = parseAttr!(string)(node.attr, i, c.text, varTable,
					c.talkerC is Talker.NARRATION ? _prop.looks.messageLen : _prop.looks.messageImageLen);
			}
			if (detail.use(CArg.TALKER_NC)) {
				c.talkerNC = parseAttr!(Talker, true)(node.attr, i, c.talkerNC, varTable);
			}
			if (detail.use(CArg.DIALOGS)) {
				c.dialogs = parseAttr!(SDialog[])(node.attr, i, c.dialogs, varTable, _prop.looks.messageImageLen);
				if (!c.dialogs.length) {
					c.dialogs = [new SDialog];
				}
			}
			if (detail.use(CArg.BG_IMAGES)) {
				c.backs = parseAttr!(BgImage[])(node.attr, i, c.backs, varTable);
			}
			if (detail.use(CArg.MOTIONS)) {
				c.motions = parseAttr!(Motion[])(node.attr, i, c.motions, varTable);
			}
			if (detail.use(CArg.TARGET_NS)) {
				c.targetNS = parseAttr!(Target, true)(node.attr, i, c.targetNS, varTable);
			}
			if (detail.use(CArg.TARGET_S)) {
				c.targetS = parseAttr!(Target)(node.attr, i, c.targetS, varTable);
			}
			if (detail.use(CArg.RANGE)) {
				c.range = parseAttr!(Range)(node.attr, i, c.range, varTable);
			}
			if (detail.use(CArg.AREA)) {
				c.area = parseAttr!(ulong)(node.attr, i, c.area, varTable);
			}
			if (detail.use(CArg.BATTLE)) {
				c.battle = parseAttr!(ulong)(node.attr, i, c.battle, varTable);
			}
			if (detail.use(CArg.PACKAGE)) {
				c.packages = parseAttr!(ulong)(node.attr, i, c.packages, varTable);
			}
			if (detail.use(CArg.CAST)) {
				c.casts = parseAttr!(ulong)(node.attr, i, c.casts, varTable);
			}
			if (detail.use(CArg.ITEM)) {
				c.item = parseAttr!(ulong)(node.attr, i, c.item, varTable);
			}
			if (detail.use(CArg.SKILL)) {
				c.skill = parseAttr!(ulong)(node.attr, i, c.skill, varTable);
			}
			if (detail.use(CArg.INFO)) {
				c.info = parseAttr!(ulong)(node.attr, i, c.info, varTable);
			}
			if (detail.use(CArg.BEAST)) {
				c.beast = parseAttr!(ulong)(node.attr, i, c.beast, varTable);
			}
			if (detail.use(CArg.START)) {
				c.start = parseAttr!(string)(node.attr, i, c.start, varTable);
			}
			if (detail.use(CArg.COMPLETE)) {
				c.complete = parseAttr!(bool)(node.attr, i, c.complete, varTable);
			}
			if (detail.use(CArg.MONEY)) {
				c.money = parseAttr!(int)(node.attr, i, c.money, varTable);
			}
			if (detail.use(CArg.COUPON)) {
				c.coupon = parseAttr!(string)(node.attr, i, c.coupon, varTable);
			}
			if (detail.use(CArg.COUPON_VALUE)) {
				c.couponValue = parseAttr!(int)(node.attr, i, c.couponValue, varTable);
			}
			if (detail.use(CArg.COMPLETE_STAMP)) {
				c.completeStamp = parseAttr!(string)(node.attr, i, c.completeStamp, varTable);
			}
			if (detail.use(CArg.GOSSIP)) {
				c.gossip = parseAttr!(string)(node.attr, i, c.gossip, varTable);
			}
			if (detail.use(CArg.FLAG)) {
				c.flag = parseAttr!(string)(node.attr, i, c.flag, varTable);
			}
			if (detail.use(CArg.FLAG_VALUE)) {
				c.flagValue = parseAttr!(bool)(node.attr, i, c.flagValue, varTable);
			}
			if (detail.use(CArg.STEP)) {
				c.step = parseAttr!(string)(node.attr, i, c.step, varTable);
			}
			if (detail.use(CArg.STEP_VALUE)) {
				c.stepValue = parseAttr!(int)(node.attr, i, c.stepValue, varTable);
			}
			if (detail.use(CArg.CARD_NUMBER)) {
				c.cardNumber = parseAttr!(int)(node.attr, i, c.cardNumber, varTable);
			}
			if (detail.use(CArg.CARD_VISUAL)) {
				c.cardVisual = parseAttr!(CardVisual)(node.attr, i, c.cardVisual, varTable);
			}
			if (detail.use(CArg.UNSIGNED_LEVEL)) {
				c.unsignedLevel = parseAttr!(int)(node.attr, i, c.unsignedLevel, varTable);
			}
			if (detail.use(CArg.SIGNED_LEVEL)) {
				c.signedLevel = parseAttr!(int)(node.attr, i, c.signedLevel, varTable);
			}
			if (detail.use(CArg.PHYSICAL)) {
				c.physical = parseAttr!(Physical)(node.attr, i, c.physical, varTable);
			}
			if (detail.use(CArg.MENTAL)) {
				c.mental = parseAttr!(Mental)(node.attr, i, c.mental, varTable);
			}
			if (detail.use(CArg.WAIT)) {
				c.wait = parseAttr!(int)(node.attr, i, c.wait, varTable);
			}
			if (detail.use(CArg.PERCENT)) {
				c.percent = parseAttr!(int)(node.attr, i, c.percent, varTable);
			}
			if (detail.use(CArg.TARGET_ALL)) {
				c.targetAll = parseAttr!(bool)(node.attr, i, c.targetAll, varTable);
			}
			if (detail.use(CArg.RANDOM)) {
				c.random = parseAttr!(bool)(node.attr, i, c.random, varTable);
			}
			if (detail.use(CArg.AVERAGE)) {
				c.average = parseAttr!(bool)(node.attr, i, c.average, varTable);
			}
			if (detail.use(CArg.PARTY_NUMBER)) {
				c.partyNumber = parseAttr!(int)(node.attr, i, c.partyNumber, varTable);
			}
			if (detail.use(CArg.SUCCESS_RATE)) {
				c.successRate = parseAttr!(int)(node.attr, i, c.successRate, varTable);
			}
			if (detail.use(CArg.EFFECT_TYPE)) {
				c.effectType = parseAttr!(EffectType)(node.attr, i, c.effectType, varTable);
			}
			if (detail.use(CArg.RESIST)) {
				c.resist = parseAttr!(Resist)(node.attr, i, c.resist, varTable);
			}
			if (detail.use(CArg.STATUS)) {
				c.status = parseAttr!(Status)(node.attr, i, c.status, varTable);
			}
			if (detail.use(CArg.BGM_PATH)) {
				c.bgmPath = encodePath(parseAttr!(string)(node.attr, i, decodePath(c.bgmPath), varTable));
			}
			if (detail.use(CArg.SOUND_PATH)) {
				c.soundPath = encodePath(parseAttr!(string)(node.attr, i, decodePath(c.soundPath), varTable));
			}
			if (detail.use(CArg.TRANSITION_SPEED)) {
				c.transitionSpeed = parseAttr!(int)(node.attr, i, c.transitionSpeed, varTable);
			}
			if (detail.use(CArg.TRANSITION)) {
				c.transition = parseAttr!(Transition)(node.attr, i, c.transition, varTable);
			}
			foreach (chld; analyzeSemanticsImpl(node.childs, keys, varTable)) {
				if (!c.detail.owner) {
					throwError(_prop.msgs.scriptErrorCanNotHaveContent, node.token);
				}
				c.add(chld);
			}
			r ~= c;
		}
		return r;
	}
	string toScript(in Content[] cs, bool legacy, string indent = "\t") {
		char[] buf;
		auto table = new VarTable;
		toScriptImpl(buf, cs, indent, "", KEYS, table, legacy);
		auto vars = table.vars;
		if (vars.length) {
			buf = std.string.join(table.vars, "\n") ~ "\n\n" ~ buf;
		}
		return buf;
	}
	string encodeString(string s) {
		return std.string.replace(s, "\"", "\"\"");
	}
	private string[] toAttr(bool Within = false, T)(T value, string command, string indentValue, VarTable vars, size_t strWidth = 0) {
		string[] attrs;
		static if (is(T == Symbol)) {
			attrs ~= value;
		} else static if (is(T == string)) {
			string attr;
			auto lines = splitlines(value);
			if (lines.length == 0) {
				attr ~= `""`;
			} else if (lines.length == 1) {
				attr ~= `"` ~ encodeString(lines[0]) ~ `"`;
			} else {
				size_t lns = 0;
				foreach (i, line; lines) {
					if (line.length) {
						lns = i;
						break;
					}
				}
				attr ~= "@";
				if (lns > 0) {
					if (vars.useCenter && lns + 1 == stringCenter(lines, strWidth)) {
						attr ~= " center";
					} else {
						attr ~= " " ~ to!(string)(lns + 1);
					}
					lines = lines[lns .. $];
				}
				attr ~= "\n";
				bool spaceLine = false;
				foreach (line; lines) {
					line = std.string.replace(line, "@", "@@");
					if (line.length && (line[0] == ' ' || line[0] == '\t' || line[0] == '\\')) {
						line = "\\" ~ line;
					}
					attr ~= indentValue ~ line ~ "\n";
					spaceLine = line.length == 0;
				}
				if (spaceLine) {
					attr ~= "@";
				} else {
					attr ~= indentValue ~ "@";
				}
			}
			attrs ~= attr;
		} else static if (isVArray!(T)) {
			foreach (i, v; value) {
				attrs ~= toAttr(v, command, indentValue, vars, strWidth);
			}
		} else static if (is(T == bool)) {
			attrs ~= value ? "true": "false";
		} else static if (is(T == Transition)) {
			switch (value) {
			case Transition.DEFAULT: attrs ~= "default"; break;
			case Transition.NONE: attrs ~= "none"; break;
			case Transition.FADE: attrs ~= "fade"; break;
			case Transition.PIXEL_DISSOLVE: attrs ~= "dissolve"; break;
			case Transition.BLINDS: attrs ~= "blinds"; break;
			default: assert (0);
			}
		} else static if (is(T == Range)) {
			switch (value) {
			case Range.SELECTED: attrs ~= "M"; break;
			case Range.RANDOM: attrs ~= "R"; break;
			case Range.PARTY: attrs ~= "T"; break;
			case Range.BACKPACK: attrs ~= "backpack"; break;
			case Range.PARTY_AND_BACKPACK: attrs ~= "party"; break;
			case Range.FIELD: attrs ~= "field"; break;
			default: assert (0);
			}
		} else static if (is(T == Status)) {
			switch (value) {
			case Status.ACTIVE: attrs ~= "active"; break;
			case Status.INACTIVE: attrs ~= "inactive"; break;
			case Status.ALIVE: attrs ~= "alive"; break;
			case Status.DEAD: attrs ~= "dead"; break;
			case Status.FINE: attrs ~= "fine"; break;
			case Status.INJURED: attrs ~= "injured"; break;
			case Status.HEAVY_INJURED: attrs ~= "heavyinjured"; break;
			case Status.UNCONSCIOUS: attrs ~= "unconscious"; break;
			case Status.POISON: attrs ~= "poison"; break;
			case Status.SLEEP: attrs ~= "sleep"; break;
			case Status.BIND: attrs ~= "bind"; break;
			case Status.PARALYZE: attrs ~= "paralyze"; break;
			default: assert (0);
			}
		} else static if (is(T == Target)) {
			switch (value.m) {
			case Target.M.SELECTED: attrs ~= "M"; break;
			case Target.M.RANDOM: attrs ~= "R"; break;
			case Target.M.UNSELECTED: attrs ~= "U"; break;
			case Target.M.PARTY: attrs ~= "T"; break;
			default: assert (0);
			}
			static if (!Within) {
				attrs ~= toAttr(value.sleep, command, indentValue, vars);
			}
		} else static if (is(T == EffectType)) {
			switch (value) {
			case EffectType.PHYSIC: attrs ~= "physic"; break;
			case EffectType.MAGIC: attrs ~= "magic"; break;
			case EffectType.MAGICAL_PHYSIC: attrs ~= "mphysic"; break;
			case EffectType.PHYSICAL_MAGIC: attrs ~= "pmagic"; break;
			case EffectType.NONE: attrs ~= "none"; break;
			default: assert (0);
			}
		} else static if (is(T == Resist)) {
			switch (value) {
			case Resist.AVOID: attrs ~= "avoid"; break;
			case Resist.RESIST: attrs ~= "resist"; break;
			case Resist.UNFAIL: attrs ~= "unfail"; break;
			default: assert (0);
			}
		} else static if (is(T == CardVisual)) {
			switch (value) {
			case CardVisual.NONE: attrs ~= "none"; break;
			case CardVisual.REVERSE: attrs ~= "reverse"; break;
			case CardVisual.HORIZONTAL: attrs ~= "hswing"; break;
			case CardVisual.VERTICAL: attrs ~= "vswing"; break;
			default: assert (0);
			}
		} else static if (is(T == Mental)) {
			switch (value) {
			case Mental.AGGRESSIVE: attrs ~= "agg"; break;
			case Mental.UNAGGRESSIVE: attrs ~= "unagg"; break;
			case Mental.CHEERFUL: attrs ~= "cheerf"; break;
			case Mental.UNCHEERFUL: attrs ~= "uncheerf"; break;
			case Mental.BRAVE: attrs ~= "brave"; break;
			case Mental.UNBRAVE: attrs ~= "unbrave"; break;
			case Mental.CAUTIOUS: attrs ~= "caut"; break;
			case Mental.UNCAUTIOUS: attrs ~= "uncaut"; break;
			case Mental.TRICKISH: attrs ~= "trick"; break;
			case Mental.UNTRICKISH: attrs ~= "untrick"; break;
			default: assert (0);
			}
		} else static if (is(T == Physical)) {
			switch (value) {
			case Physical.DEX: attrs ~= "dex"; break;
			case Physical.AGL: attrs ~= "agl"; break;
			case Physical.INT: attrs ~= "int"; break;
			case Physical.STR: attrs ~= "str"; break;
			case Physical.VIT: attrs ~= "vit"; break;
			case Physical.MIN: attrs ~= "min"; break;
			default: assert (0);
			}
		} else static if (is(T == Talker)) {
			attrs ~= toAttrTalker(value, "");
		} else static if (is(T == MType)) {
			switch (value) {
			case MType.HEAL: attrs ~= "heal"; break;
			case MType.DAMAGE: attrs ~= "damage"; break;
			case MType.ABSORB: attrs ~= "absorb"; break;
			case MType.PARALYZE: attrs ~= "paralyze"; break;
			case MType.DIS_PARALYZE: attrs ~= "disparalyze"; break;
			case MType.POISON: attrs ~= "poison"; break;
			case MType.DIS_POISON: attrs ~= "dispoison"; break;
			case MType.GET_SKILL_POWER: attrs ~= "getspilit"; break;
			case MType.LOSE_SKILL_POWER: attrs ~= "losespilit"; break;
			case MType.SLEEP: attrs ~= "sleep"; break;
			case MType.CONFUSE: attrs ~= "confuse"; break;
			case MType.OVERHEAT: attrs ~= "overheat"; break;
			case MType.BRAVE: attrs ~= "brave"; break;
			case MType.PANIC: attrs ~= "panic"; break;
			case MType.NORMAL: attrs ~= "resetfeel"; break;
			case MType.BIND: attrs ~= "bind"; break;
			case MType.DIS_BIND: attrs ~= "disbind"; break;
			case MType.SILENCE: attrs ~= "silence"; break;
			case MType.DIS_SILENCE: attrs ~= "dissilence"; break;
			case MType.FACE_UP: attrs ~= "faceup"; break;
			case MType.FACE_DOWN: attrs ~= "facedown"; break;
			case MType.ANTI_MAGIC: attrs ~= "antimagic"; break;
			case MType.DIS_ANTI_MAGIC: attrs ~= "disantimagic"; break;
			case MType.ENHANCE_ACTION: attrs ~= "enhaction"; break;
			case MType.ENHANCE_AVOID: attrs ~= "enhavoid"; break;
			case MType.ENHANCE_RESIST: attrs ~= "enhresist"; break;
			case MType.ENHANCE_DEFENSE: attrs ~= "enhdefense"; break;
			case MType.VANISH_TARGET: attrs ~= "vantarget"; break;
			case MType.VANISH_CARD: attrs ~= "vancard"; break;
			case MType.VANISH_BEAST: attrs ~= "vanbeast"; break;
			case MType.DEAL_ATTACK_CARD: attrs ~= "dealattack"; break;
			case MType.DEAL_POWERFUL_ATTACK_CARD: attrs ~= "dealpowerful"; break;
			case MType.DEAL_CRITICAL_ATTACK_CARD: attrs ~= "dealcritical"; break;
			case MType.DEAL_FEINT_CARD: attrs ~= "dealfeint"; break;
			case MType.DEAL_DEFENSE_CARD: attrs ~= "dealdefense"; break;
			case MType.DEAL_DISTANCE_CARD: attrs ~= "dealdistance"; break;
			case MType.DEAL_CONFUSE_CARD: attrs ~= "dealconfuse"; break;
			case MType.DEAL_SKILL_CARD: attrs ~= "dealskill"; break;
			case MType.SUMMON_BEAST: attrs ~= "summon"; break;
			default: assert (0);
			}
		} else static if (is(T == Element)) {
			switch (value) {
			case Element.ALL: attrs ~= "all"; break;
			case Element.HEALTH: attrs ~= "phy"; break;
			case Element.MIND: attrs ~= "mind"; break;
			case Element.MIRACLE: attrs ~= "holy"; break;
			case Element.MAGIC: attrs ~= "magic"; break;
			case Element.FIRE: attrs ~= "fire"; break;
			case Element.ICE: attrs ~= "ice"; break;
			default: assert (0);
			}
		} else static if (is(T == DamageType)) {
			switch (value) {
			case DamageType.LEVEL_RATIO: attrs ~= "level"; break;
			case DamageType.NORMAL: attrs ~= "value"; break;
			case DamageType.MAX: attrs ~= "max"; break;
			default: assert (0);
			}
		} else static if (is(T == BgImage)) {
			string[] attrs2;
			attrs2 ~= toAttr(encodePath(value.path), command, indentValue, vars);
			attrs2 ~= toAttr(value.flag, command, indentValue, vars);
			attrs2 ~= toAttr(value.x, command, indentValue, vars);
			attrs2 ~= toAttr(value.y, command, indentValue, vars);
			attrs2 ~= toAttr(value.width, command, indentValue, vars);
			attrs2 ~= toAttr(value.height, command, indentValue, vars);
			attrs2 ~= toAttr(value.mask, command, indentValue, vars);
			attrs ~= "[" ~ std.string.join(attrs2, ", ") ~ "]";
		} else static if (is(T == Motion)) {
			auto detail = value.detail;
			string[] attrs2;
			attrs2 ~= toAttr(value.type, command, indentValue, vars);
			if (detail.use(MArg.VALUE_TYPE)) {
				attrs2 ~= toAttr(value.damageType, command, indentValue, vars);
			}
			if (detail.use(MArg.U_VALUE)) {
				attrs2 ~= toAttr(value.uValue, command, indentValue, vars);
			}
			if (detail.use(MArg.A_VALUE)) {
				attrs2 ~= toAttr(value.aValue, command, indentValue, vars);
			}
			if (detail.use(MArg.ROUND)) {
				attrs2 ~= toAttr(value.round, command, indentValue, vars);
			}
			if (detail.use(MArg.BEAST)) {
				BeastCard b = null;
				if (value.beast) {
					b = _summ.findSomeBeast(value.beast);
				}
				attrs2 ~= toAttr(vars.id(b, 0UL), command, indentValue, vars);
			}
			attrs2 ~= toAttr(value.element, command, indentValue, vars);
			attrs ~= "[" ~ std.string.join(attrs2, ", ") ~ "]";
		} else static if (is(T == SDialog)) {
			string[] attrs2;
			bool semic = false;
			foreach (c; value.rCoupons) {
				if (std.string.find(c, ";") >= 0) {
					semic = true;
					break;
				}
			}
			if (semic) {
				attrs2 ~= "[" ~ std.string.join(toAttr(value.rCoupons, command, indentValue, vars), ", ") ~ "]";
			} else {
				attrs2 ~= `"` ~ encodeString(std.string.join(value.rCoupons, ";")) ~ `"`;
			}
			attrs2 ~= toAttr(value.text, command, indentValue, vars, strWidth);
			attrs ~= "[" ~ std.string.join(attrs2, ", ") ~ "]";
		} else static if (is(T == int)) {
			attrs ~= to!(string)(value);
		} else static if (is(T == uint)) {
			attrs ~= to!(string)(value);
		} else static if (is(T == ulong)) {
			attrs ~= to!(string)(value);
		} else static assert (0);
		return attrs;
	}
	private string toAttrTalker(Talker t, string cardPath) {
		switch (t) {
		case Talker.NARRATION: return "none";
		case Talker.SELECTED: return "M";
		case Talker.UNSELECTED: return "U";
		case Talker.RANDOM: return "R";
		case Talker.CARD: return "C";
		case Talker.IMAGE: return `"` ~ encodeString(cardPath) ~ `"`;
		default: assert (0);
		}
	}
	private typedef string Symbol;
	private static class VarTable {
		bool useVar = true;
		bool useCenter = true;
		private Symbol idVar(string Name, A)(A a, ulong id, ref string[ulong] tbl, ref ulong[string] tblR) {
			if (!useVar || !a) return cast(Symbol) to!(string)(id);
			auto p = a.id in tbl;
			if (p) return cast(Symbol) *p;
			string base = "$" ~ Name ~ "_" ~ validVarName(a.name);
			string name = base;
			size_t i = 1;
			while (name in tblR) {
				i++;
				name = base ~ "_" ~ to!(string)(i);
			}
			tbl[a.id] = name;
			tblR[name] = a.id;
			return cast(Symbol) name;
		}
		private string[ulong] _areas;
		private ulong[string] _areasR;
		private string[ulong] _battles;
		private ulong[string] _battlesR;
		private string[ulong] _packages;
		private ulong[string] _packagesR;
		private string[ulong] _casts;
		private ulong[string] _castsR;
		private string[ulong] _skills;
		private ulong[string] _skillsR;
		private string[ulong] _items;
		private ulong[string] _itemsR;
		private string[ulong] _beasts;
		private ulong[string] _beastsR;
		private string[ulong] _infos;
		private ulong[string] _infosR;
		Symbol id(Area a, ulong id) {return idVar!("area")(a, id, _areas, _areasR);}
		Symbol id(Battle a, ulong id) {return idVar!("battle")(a, id, _battles, _battlesR);}
		Symbol id(Package a, ulong id) {return idVar!("pack")(a, id, _packages, _packagesR);}
		Symbol id(CastCard a, ulong id) {return idVar!("cast")(a, id, _casts, _castsR);}
		Symbol id(SkillCard a, ulong id) {return idVar!("skill")(a, id, _skills, _skillsR);}
		Symbol id(ItemCard a, ulong id) {return idVar!("item")(a, id, _items, _itemsR);}
		Symbol id(BeastCard a, ulong id) {return idVar!("beast")(a, id, _beasts, _beastsR);}
		Symbol id(InfoCard a, ulong id) {return idVar!("info")(a, id, _infos, _infosR);}
		private static string[] vars(string[ulong] arr) {
			string[] r;
			foreach (id; arr.keys.sort) {
				r ~= arr[id] ~ " = " ~ to!(string)(id);
			}
			return r;
		}
		string[] vars() {
			string[] r;
			r ~= vars(_areas);
			r ~= vars(_battles);
			r ~= vars(_packages);
			r ~= vars(_casts);
			r ~= vars(_skills);
			r ~= vars(_items);
			r ~= vars(_beasts);
			r ~= vars(_infos);
			return r;
		}
	}
	private void toScriptImpl(ref char[] buf, in Content[] cs, string indent, string indentValue, in Keywords keys, VarTable vars, bool legacy) {
		foreach (i, c; cs) {
			if (i > 0) buf ~= "\n\n";
			buf ~= indentValue;
			auto detail = c.detail;
			string command = keys.commands[c.type];
			buf ~= command;
			string[] attrs;
			if (c.type is CType.START) {
				attrs ~= `"` ~ encodeString(c.name) ~ `"`;
			}
			size_t msgLen = 0;
			if (detail.use(CArg.TALKER_C)) {
				attrs ~= toAttrTalker(c.talkerC, c.cardPath);
				if (c.talkerC is Talker.NARRATION) {
					msgLen = _prop.looks.messageLen;
				} else {
					msgLen = _prop.looks.messageImageLen;
				}
			}
			if (detail.use(CArg.TEXT)) {
				attrs ~= toAttr(c.text, command, indentValue, vars, msgLen);
			}
			if (detail.use(CArg.TALKER_NC)) {
				attrs ~= toAttr!(true)(c.talkerNC, command, indentValue, vars);
				msgLen = _prop.looks.messageImageLen;
			}
			if (detail.use(CArg.DIALOGS)) {
				attrs ~= toAttr(c.dialogs, command, indentValue, vars, msgLen);
			}
			if (detail.use(CArg.BG_IMAGES)) {
				attrs ~= toAttr(c.backs, command, indentValue, vars);
			}
			if (detail.use(CArg.MOTIONS)) {
				attrs ~= toAttr(c.motions, command, indentValue, vars);
			}
			if (detail.use(CArg.TARGET_NS)) {
				attrs ~= toAttr!(true)(c.targetNS, command, indentValue, vars);
			}
			if (detail.use(CArg.TARGET_S)) {
				attrs ~= toAttr(c.targetS, command, indentValue, vars);
			}
			if (detail.use(CArg.RANGE)) {
				attrs ~= toAttr(c.range, command, indentValue, vars);
			}
			if (detail.use(CArg.AREA)) {
				auto a = _summ.area(c.area);
				attrs ~= toAttr(vars.id(a, c.area), command, indentValue, vars);
			}
			if (detail.use(CArg.BATTLE)) {
				auto a = _summ.battle(c.battle);
				attrs ~= toAttr(vars.id(a, c.battle), command, indentValue, vars);
			}
			if (detail.use(CArg.PACKAGE)) {
				auto a = _summ.packages(c.packages);
				attrs ~= toAttr(vars.id(a, c.packages), command, indentValue, vars);
			}
			if (detail.use(CArg.CAST)) {
				auto a = _summ.casts(c.casts);
				attrs ~= toAttr(vars.id(a, c.casts), command, indentValue, vars);
			}
			if (detail.use(CArg.ITEM)) {
				auto a = _summ.item(c.item);
				attrs ~= toAttr(vars.id(a, c.item), command, indentValue, vars);
			}
			if (detail.use(CArg.SKILL)) {
				auto a = _summ.skill(c.skill);
				attrs ~= toAttr(vars.id(a, c.skill), command, indentValue, vars);
			}
			if (detail.use(CArg.INFO)) {
				auto a = _summ.info(c.info);
				attrs ~= toAttr(vars.id(a, c.info), command, indentValue, vars);
			}
			if (detail.use(CArg.BEAST)) {
				auto a = _summ.beast(c.beast);
				attrs ~= toAttr(vars.id(a, c.beast), command, indentValue, vars);
			}
			if (detail.use(CArg.START)) {
				attrs ~= toAttr(c.start, command, indentValue, vars);
			}
			if (detail.use(CArg.COMPLETE)) {
				attrs ~= toAttr(c.complete, command, indentValue, vars);
			}
			if (detail.use(CArg.MONEY)) {
				attrs ~= toAttr(c.money, command, indentValue, vars);
			}
			if (detail.use(CArg.COUPON)) {
				attrs ~= toAttr(c.coupon, command, indentValue, vars);
			}
			if (detail.use(CArg.COUPON_VALUE)) {
				attrs ~= toAttr(c.couponValue, command, indentValue, vars);
			}
			if (detail.use(CArg.COMPLETE_STAMP)) {
				attrs ~= toAttr(c.completeStamp, command, indentValue, vars);
			}
			if (detail.use(CArg.GOSSIP)) {
				attrs ~= toAttr(c.gossip, command, indentValue, vars);
			}
			if (detail.use(CArg.FLAG)) {
				attrs ~= toAttr(c.flag, command, indentValue, vars);
			}
			if (detail.use(CArg.FLAG_VALUE)) {
				attrs ~= toAttr(c.flagValue, command, indentValue, vars);
			}
			if (detail.use(CArg.STEP)) {
				attrs ~= toAttr(c.step, command, indentValue, vars);
			}
			if (detail.use(CArg.STEP_VALUE)) {
				attrs ~= toAttr(c.stepValue, command, indentValue, vars);
			}
			if (detail.use(CArg.CARD_NUMBER)) {
				if (c.cardNumber != 0) {
					attrs ~= toAttr(c.cardNumber, command, indentValue, vars);
				} else {
					attrs ~= toAttr(cast(Symbol) "all", command, indentValue, vars);
				}
			}
			if (detail.use(CArg.CARD_VISUAL)) {
				attrs ~= toAttr(c.cardVisual, command, indentValue, vars);
			}
			if (detail.use(CArg.UNSIGNED_LEVEL)) {
				attrs ~= toAttr(c.unsignedLevel, command, indentValue, vars);
			}
			if (detail.use(CArg.SIGNED_LEVEL)) {
				attrs ~= toAttr(c.signedLevel, command, indentValue, vars);
			}
			if (detail.use(CArg.PHYSICAL)) {
				attrs ~= toAttr(c.physical, command, indentValue, vars);
			}
			if (detail.use(CArg.MENTAL)) {
				attrs ~= toAttr(c.mental, command, indentValue, vars);
			}
			if (detail.use(CArg.WAIT)) {
				attrs ~= toAttr(c.wait, command, indentValue, vars);
			}
			if (detail.use(CArg.PERCENT)) {
				attrs ~= toAttr(c.percent, command, indentValue, vars);
			}
			if (detail.use(CArg.TARGET_ALL)) {
				attrs ~= toAttr(c.targetAll, command, indentValue, vars);
			}
			if (detail.use(CArg.RANDOM)) {
				attrs ~= toAttr(c.random, command, indentValue, vars);
			}
			if (detail.use(CArg.AVERAGE)) {
				attrs ~= toAttr(c.average, command, indentValue, vars);
			}
			if (detail.use(CArg.PARTY_NUMBER)) {
				attrs ~= toAttr(c.partyNumber, command, indentValue, vars);
			}
			if (detail.use(CArg.SUCCESS_RATE)) {
				attrs ~= toAttr(c.successRate, command, indentValue, vars);
			}
			if (detail.use(CArg.EFFECT_TYPE)) {
				attrs ~= toAttr(c.effectType, command, indentValue, vars);
			}
			if (detail.use(CArg.RESIST)) {
				attrs ~= toAttr(c.resist, command, indentValue, vars);
			}
			if (detail.use(CArg.STATUS)) {
				attrs ~= toAttr(c.status, command, indentValue, vars);
			}
			if (detail.use(CArg.BGM_PATH)) {
				if (c.bgmPath.length) {
					attrs ~= toAttr(encodePath(c.bgmPath), command, indentValue, vars);
				} else {
					attrs ~= toAttr(cast(Symbol) "stop", command, indentValue, vars);
				}
			}
			if (detail.use(CArg.SOUND_PATH)) {
				attrs ~= toAttr(encodePath(c.soundPath), command, indentValue, vars);
			}
			if (!legacy) {
				if (detail.use(CArg.TRANSITION_SPEED)) {
					attrs ~= toAttr(c.transitionSpeed, command, indentValue, vars);
				}
				if (detail.use(CArg.TRANSITION)) {
					attrs ~= toAttr(c.transition, command, indentValue, vars);
				}
			}
			bool useIf = c.next.length > 1;
			bool useSif = c.next.length == 1 && c.next[0].name.length;
			if (!useIf) {
				foreach (chld; c.next) {
					if (chld.name.length) {
						if (detail.nextType is CNextType.TEXT && chld.name == _prop.msgs.evtChildOK) {
							continue;
						}
						useIf = true;
						break;
					}
				}
			}
			if (attrs.length) {
				buf ~= " " ~ std.string.join(attrs, ", ");
			}
			foreach (idx, chld; c.next) {
				if (useIf) {
					buf ~= "\n" ~ indentValue;
					if (useSif) {
						buf ~= "sif ";
					} else {
						buf ~= idx == 0 ? "if " : "elif ";
					}
					switch (detail.nextType) {
					case CNextType.NONE:
						buf ~= `""`;
						break;
					case CNextType.TEXT:
						buf ~= `"` ~ encodeString(chld.name) ~ `"`;
						break;
					case CNextType.BOOL:
						buf ~= icmp(chld.name, _prop.msgs.evtChildTrue) == 0 ? "true" : "false";
						break;
					case CNextType.STEP:
					case CNextType.ID_AREA:
					case CNextType.ID_BATTLE:
						if (icmp(chld.name, _prop.msgs.evtChildDefault) == 0) {
							buf ~= "default";
						} else {
							buf ~= chld.name;
						}
						break;
					default: assert (0);
					}
					buf ~= "\n";
					auto nextIndent = useSif ? indentValue : indentValue ~ indent;
					toScriptImpl(buf, [chld], indent, nextIndent, keys, vars, legacy);
				} else {
					buf ~= "\n";
					if (c.type is CType.START) {
						toScriptImpl(buf, [chld], indent, indentValue ~ indent, keys, vars, legacy);
					} else {
						toScriptImpl(buf, [chld], indent, indentValue, keys, vars, legacy);
					}
				}
			}
			if (useIf && !useSif) {
				buf ~= "\n" ~ indentValue ~ "fi";
			}
		}
	}
}

private string validVarName(string name) {
	char[] buf;
	buf.length = name.length;
	foreach (i, char c; name) {
		switch (c) {
			case '\0', '\b', '\t', '\n', '\v', '\f', '\r', ' ', '!',
				'"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',',
				'-', '.', '/', ':', ';', '<', '=', '>', '?', '@', '[',
				'\\', ']', '^', '`', '{', '}', '|', '~':
			buf[i] = '_';
			break;
		default:
			buf[i] = c;
			break;
		}
	}
	return buf;
}

private const string[] TOKENS = [
	`[a-z_][a-z_0-9]*`, // symbol or keyword
	"\\$[^\b\t\n\v\f\r !\"#$%&\'\\(\\)*+,\\-./:;<=>?@\\[\\\\\\]^`{}|~]+", // variable
	`=`, // equql
	`[0-9]+(\.[0-9]+)?`, // number
	`\[`, // open bracket
	`\]`, // close bracket
	`,`, // comma
	`"(""|[^"])*?"`, // string
	`'(''|[^'])*?'`, // string
	`@[ \t]*([0-9]+|c|center)?[ \t]*\n(([^@]|@@|\n)*\n)?[ \t]*@`, // string
	`[ \t\r\n]+`, // whitespace
	`\+`,// plus
	`-`, // minus
	`\*`, // multiply
	`\/(\*(.|\n)*?\*\/|\/.*(\n|$)|)`, // divide or comment
	`%`, // residue
	`~`, // cat
	`\(`, // open paren
	`\)` // close paren
];
