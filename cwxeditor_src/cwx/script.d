
module cwx.script;

import cwx.props;
import cwx.types;
import cwx.summary;
import cwx.utils;
import cwx.event;
import cwx.motion;
import cwx.background;

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
			(string message, in Token tok) {
		throwErrorToken(message, tok.line, tok.pos, tok.value);
	}
	private static void throwErrorToken(string File = __FILE__, size_t Line = __LINE__)
			(string message, size_t line, size_t pos, string value) {
		throw new CWXScriptException(message, "", line, pos, File, Line);
	}

	/// Tokenの種別。
	static enum Kind {
		START, /// start
		IF, /// if
		FI, /// fi
		ELIF, /// elif
		O_BRA, /// [
		C_BRA, /// ]
		SYMBOL, /// キーワードや命令以外のシンボル。
		NUMBER, /// 数値。
		VAR_NAME, /// 変数名。
		EQ, /// =
		STRING, /// 文字列。
		PLU, /// +
		MIN, /// -
		MUL, /// *
		DIV, /// /
		RES, /// %
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
	/// Tokenの値を文字列として解釈して返す。
	/// 文字列を囲う記号に加え、
	/// 行頭にあるタブ文字や一定数の空白が取り除かれる。
	private string stringValue(Token tok) {
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
				buf[len] = '\\';
				len++;
			}
			return buf[0 .. len];
		}
		.enforce(tok.kind is Kind.STRING && tok.value.length >= 2,
			new Exception("Invalid string: " ~ tok.value, __FILE__, __LINE__));
		if (tok.value[0] == '@') {
			char[] buf;
			auto lines = .splitlines(tok.value[0 .. $ - 1]);
			foreach (i, line; lines[1 .. $]) {
				while (line.startsWith("\t")) line = line[1 .. $];
				while (line.startsWith("    ")) line = line[4 .. $];
				lines[i + 1] = line;
			}
			if (lines[0].length > 1) {
				auto lnStr = std.string.tolower(.strip(lines[0][1 .. $]));
				bool isNum = .isNumeric(lnStr);
				if (!isNum && lnStr != "center") {
					throwError(_prop.msgs.scriptErrorInvalidStr, tok);
				}
				int ln;
				if (isNum) {
					ln = .to!(int)(lnStr);
				} else {
					int lc = cast(int) lineCount(lines[1 .. $]);
					if (lc > 0 && lc < _prop.looks.messageLine) {
						int lnt = cast(int) _prop.looks.messageLine - (lc - 1);
						ln = lnt / 2 + 1;
					} else {
						ln = 0;
					}
				}
				if (ln > 0) {
					buf.length = ln - 1;
				}
				buf[] = '\n';
			}
			foreach (i, line; lines[1 .. $]) {
				if (i > 0) buf ~= '\n';;
				buf ~= line;
			}
			return decode(buf, tok.value[0]);
		}
		return decode(tok.value[1 .. $ - 1], tok.value[0]);
	} unittest {
		CWXScript s;
		assert (s.stringValue(Token(0, 0, Kind.STRING, `"abc"`)) == "abc");
		assert (s.stringValue(Token(0, 0, Kind.STRING, `'ab''c'`)) == "ab'c");
		assert (s.stringValue(Token(0, 2, Kind.STRING, "@ 3\n\t\tte@@st\n\t\tt\\e\\st@"))
			 == "\n\nte@st\nt\\e\\st");
	}

	/// textをTokenに分割する。
	Token[] tokenize(string text) {
		Token[] r;
		text = .replace(text, "\r\n", "\n");
		text = .replace(text, "\r", "\n");
		auto reg = RegExp("(" ~ std.string.join([
			`[A-Za-z_][A-Za-z_0-9]*`, // symbol or keyword
			`\$[A-Za-z_0-9]+`, // variable
			`=`, // equql
			`[0-9]+(\.[0-9]+)?`, // number
			`\[`, // open bracket
			`\]`, // close bracket
			`"([^"]|\\")*"`, // string
			`'([^']|\\')*'`, // string
			`@[ \t]*([0-9]*|[Cc][Ee][Nn][Tt][Ee][Rr])[ \t]*\n(([^@]|\\@)*\n)?[ \t]*@`, // string
			`[ \t\r\n]+`, // whitespace
			`\+`,// plus
			`-`, // minus
			`\*`, // multiply
			`\/`, // divide
			`%`, // residue
			`\(`, // open paren
			`\)`, // close paren
			`;.*(\n|$)` // comment
		], ")|(") ~ ")");
		size_t i = 0;
		size_t hits = 0;
		size_t pos = 0;
		string post;
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
				default:
					r ~= Token(i, pos, Kind.SYMBOL, str);
					break;
				}
				pos += str.length;
			} else if (c == '$') {
				r ~= Token(i, pos, Kind.VAR_NAME, str);
				pos += str.length;
			} else if (c == '=') {
				r ~= Token(i, pos, Kind.EQ, str);
				pos += str.length;
			} else if (c == '[') {
				// open bracket
				r ~= Token(i, pos, Kind.O_BRA, str);
				pos += str.length;
			} else if (c == ']') {
				// close bracket
				r ~= Token(i, pos, Kind.C_BRA, str);
				pos += str.length;
			} else if (isdigit(c)) {
				// number
				r ~= Token(i, pos, Kind.NUMBER, str);
				pos += str.length;
			} else if (c == '@' || c == '"' || c == '\'') {
				// string
				r ~= Token(i, pos, Kind.STRING, str);
				retCount;
			} else if (isspace(c)) {
				// whitespace
				retCount;
			} else if (c == '+') {
				// plus
				r ~= Token(i, pos, Kind.PLU, str);
				pos += str.length;
			} else if (c == '-') {
				// minus
				r ~= Token(i, pos, Kind.MIN, str);
				pos += str.length;
			} else if (c == '*') {
				// multiply
				r ~= Token(i, pos, Kind.MUL, str);
				pos += str.length;
			} else if (c == '/') {
				// divide
				r ~= Token(i, pos, Kind.DIV, str);
				pos += str.length;
			} else if (c == '%') {
				// residue
				r ~= Token(i, pos, Kind.RES, str);
				pos += str.length;
			} else if (c == '(') {
				// open paren
				r ~= Token(i, pos, Kind.O_PAR, str);
				pos += str.length;
			} else if (c == ')') {
				// close paren
				r ~= Token(i, pos, Kind.C_PAR, str);
				pos += str.length;
			} else if (c == ';') {
				// comment
				i++;
				pos = 0;
			} else {
				assert (0);
			}
			hits += str.length;
		}
		if (post.length) throwErrorToken(_prop.msgs.scriptErrorInvalidToken, i, pos, "");
		return r;
	} unittest {
		CWXScript s;
		assert (s.tokenize("start 12.3 \ntest1 [$void] =\"str\ning;\"\n\r ;comment\nELIF if\n1/2+3*4%(5-6)")
			== [
				Token(0, 0, Kind.START, "start"),
				Token(0, 6, Kind.NUMBER, "12.3"),
				Token(1, 0, Kind.SYMBOL, "test1"),
				Token(1, 6, Kind.O_BRA, "["),
				Token(1, 7, Kind.VAR_NAME, "$void"),
				Token(1, 12, Kind.C_BRA, "]"),
				Token(1, 14, Kind.EQ, "="),
				Token(1, 15, Kind.STRING, "\"str\ning;\""),
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

	private const OPE_LEVEL_MAX = 1;
	private real calcNum(in Token[] tokens, ref size_t i, Token[string] varTable) {
		assert (i < tokens.length);
		auto tok = tokens[i];
		if (tok.kind is Kind.VAR_NAME) {
			return to!(real)(var(tok, varTable).value);
		}
		bool min = false;
		if (tok.kind is Kind.PLU) {
			i++;
		} else if (tok.kind is Kind.MIN) {
			min = true;
			i++;
		}
		if (tokens.length <= i || tokens[i].kind !is Kind.NUMBER) {
			throwError(_prop.msgs.scriptErrorInvalidNumber, tok);
		}
		real r = to!(real)(tokens[i].value);
		i++;
		return min ? -r : r;
	}
	private real calcPar(in Token[] tokens, ref size_t i, Token[string] varTable) {
		assert (i < tokens.length);
		auto tok = tokens[i];
		switch (tok.kind) {
		case Kind.O_PAR:
			i++;
			real r = calcImpl(0, tokens, i, varTable);
			if (tokens[i].kind !is Kind.C_PAR) {
				throwError(_prop.msgs.scriptErrorCloseParenNotFound, tok);
			}
			i++;
			return r;
		default:
			return calcNum(tokens, i, varTable);
		}
	}
	private real calcImpl(size_t opeLevel, in Token[] tokens, ref size_t i, Token[string] varTable) {
		assert (i < tokens.length);
		real r;
		if (opeLevel >= OPE_LEVEL_MAX) {
			r = calcPar(tokens, i, varTable);
		} else {
			r = calcImpl(opeLevel + 1, tokens, i, varTable);
		}
		while (i < tokens.length) {
			auto tok = tokens[i];
			real chkDiv(real val) {
				if (val == 0.0) throwError(_prop.msgs.scriptErrorZeroDivision, tok);
				return val;
			}
			switch (opeLevel) {
			case 0:
				switch (tok.kind) {
				case Kind.PLU:
					i++;
					r += calcImpl(1, tokens, i, varTable);
					break;
				case Kind.MIN:
					i++;
					r -= calcImpl(1, tokens, i, varTable);
					break;
				default: return r;
				}
				break;
			case 1:
				switch (tok.kind) {
				case Kind.MUL:
					i++;
					r *= calcPar(tokens, i, varTable);
					break;
				case Kind.DIV:
					i++;
					r /= chkDiv(calcPar(tokens, i, varTable));
					break;
				case Kind.RES:
					i++;
					r %= chkDiv(calcPar(tokens, i, varTable));
					break;
				default: return r;
				}
				break;
			default: assert (0);
			}
		}
		return r;
	}
	/// tokensを計算式と看做し、計算結果の値を返す。
	real calc(in Token[] tokens, ref size_t i, Token[string] varTable) {
		assert (i < tokens.length);
		return calcImpl(0, tokens, i, varTable);
	} unittest {
		size_t i;
		Token[] tokens;
		Token[string] varTable;
		varTable["$abc"] = Token(0, 0, Kind.NUMBER, "15");
		CWXScript s;

		i = 0;
		assert (s.calc(s.tokenize("(-42)"), i, varTable) == -42);
		i = 0;
		assert (s.calc(s.tokenize("2*2+3"), i, varTable) == 7);
		i = 0;
		assert (s.calc(s.tokenize("2*(2+3)"), i, varTable) == 10);
		i = 0;
		assert (s.calc(s.tokenize("1+2*3"), i, varTable) == 7);
		i = 0;
		assert (s.calc(s.tokenize("(1+2)*3"), i, varTable) == 9);
		i = 0;
		assert (s.calc(s.tokenize("-3-3"), i, varTable) == -6);
		i = 0;
		assert (s.calc(s.tokenize("2 * 3 % 4"), i, varTable) == 2);
		i = 0;
		assert (s.calc(s.tokenize("3 + -3-3"), i, varTable) == -3);
		i = 0;
		assert (s.calc(s.tokenize("1+2 * 3 % 4"), i, varTable) == 3);
		i = 0;
		tokens = s.tokenize("1+2 * 3 % 4 + -3-$abc $abc");
		assert (s.calc(tokens, i, varTable) == -15);
		assert (tokens[i].value == "$abc");
		i = 0;
		tokens = s.tokenize("(1+2) * 3 % 4 + (-3-3) if");
		assert (s.calc(tokens, i, varTable) == -5);
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
			cast(string) "chgback":CType.CHANGE_BG_IMAGE,
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
		Token text = Token(0, 0, Kind.STRING, `""`); /// テキスト。
		Node[] attr; /// 属性。
		Node[] childs; /// 子ノード。
		alias childs values; /// ノードがVALUESの場合は格納されたVALUEノードの配列。
		Token[] calc; /// 計算式。
		alias calc var; /// 変数。
		Node[] beforeVars; /// ノードの直前に宣言された変数群。
		/// oと等しいか。
		int opEquals(Node* o) {
			return type == o.type && token == &o.token && text == &o.text
				&& attr == o.attr && childs == o.childs && calc == o.calc
				&& beforeVars == o.beforeVars;
		}
		/// 文字列表現。
		string toString() {return code("    ");}
		/// このノードをスクリプトコードにして返す。
		string code(string indent) {return code("    ", "");}
		private string code(string indent, string indentValue) {
			string calcCode() {
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
					return .format("%s%s = %s", token.value, indentValue, calcCode);
				}
			} else if (type is NodeType.VALUE) {
				if (var.length <= 1) {
					return token.value;
				} else {
					return calcCode;
				}
			} else if (type is NodeType.VALUES) {
				string vals = "[";
				foreach (i, c; values) {
					if (i > 0) vals ~= " ";
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
				attrs = " " ~ text.value;
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
			foreach (c; childs) {
				if (c.type !is NodeType.VAR_SET) {
					clen++;
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
						buf ~= .format("%s%s %s\n", indentValue, f, c.text.value);
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
	private string attrValue(in Node node, Token[string] varTable) {
		switch (node.token.kind) {
		case Kind.SYMBOL: return std.string.tolower(node.token.value);
		case Kind.STRING: return stringValue(node.token);
		case Kind.VAR_NAME, Kind.NUMBER, Kind.PLU, Kind.MIN, Kind.O_PAR:
			size_t i = 0;
			return to!(string)(calc(node.calc, i, varTable));
		case Kind.O_BRA: return "";
		default: throwError(_prop.msgs.scriptErrorInvalidAttr, node.token);
		}
		assert (0);
	}
	/// 変数値をTokenとして返す。
	private Token varValue(in Node node, Token[string] varTable) {
		if (!node.var.length) {
			throwError(_prop.msgs.scriptErrorInvalidVar, node.token);
		}
		switch (node.var[0].kind) {
		case Kind.STRING: return node.var[0];
		case Kind.VAR_NAME, Kind.NUMBER, Kind.PLU, Kind.MIN, Kind.O_PAR:
			size_t i = 0;
			Token tok = node.var[0];
			tok.kind = Kind.NUMBER;
			tok.value = to!(string)(calc(node.var, i, varTable));
			return tok;
		default: throwError(_prop.msgs.scriptErrorInvalidVarVal, node.var[0]);
		}
		assert (0);
	}
	private static Token var(in Node node, in Token[string] varTable) {
		return var(node.token, varTable);
	}
	private static Token var(in Token tok, in Token[string] varTable) {
		if (tok.kind is Kind.VAR_NAME) {
			auto ptr = std.string.tolower(tok.value) in varTable;
			if (ptr) return var(*ptr, varTable);
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
			if (tokens.length <= i) {
				throwError(_prop.msgs.scriptErrorNoStartText, tok);
			}
			Node node;
			node.type = NodeType.START;
			node.token = tok;
			node.text = tokens[i];
			node.beforeVars = vars;
			i++;
			c: while (i < tokens.length) {
				string cText = "";
				switch (tokens[i].kind) {
				case Kind.START, Kind.FI, Kind.VAR_NAME: break c;
				case Kind.IF, Kind.ELIF, Kind.SYMBOL:
					node.childs ~= analyzeSyntaxBranch(tokens, i, KEYS);
					continue;
				case Kind.O_BRA, Kind.C_BRA, Kind.NUMBER, Kind.STRING:
					throwError(_prop.msgs.scriptErrorInvalidStatement, tokens[i]);
					break;
				default: assert (0);
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
    chgback ['mapofwirth.bmp' ''  0 0 632 420]
            ['definn.bmp' '' 50 50 200*2 260]
            ['card.bmp' 'card\mate1' 230 50 74 94 mask]
    hideparty
    $var2 = 3.5
    wait  ($var2 + 1.5)
    msg M
    @ 3
    Talk!
    Talk!
    Talk!
    @
    brflag 'card\mate1'
    if true
        $var3 = 'what?'
        showparty
        endsc true
        $var_dummy = noshing
    elif false
        gameover    ; comment1
    fi
elif 'def' effect 1  2 3 + 2
fi
; comment2
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
			~ "    chgback ['mapofwirth.bmp' '' 0 0 632 420]\n"
			~ "            ['definn.bmp' '' 50 50 200 * 2 260]\n"
			~ "            ['card.bmp' 'card\\mate1' 230 50 74 94 mask]\n"
			~ "    hideparty\n"
			~ "    $var2 = 3.5\n"
			~ "    wait ($var2 + 1.5)\n"
			~ "    msg M @ 3\n"
			~ "    Talk!\n"
			~ "    Talk!\n"
			~ "    Talk!\n"
			~ "    @\n"
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
    gameover    ; comment1
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
		switch (tok.kind) {
		case Kind.START: return r;
		case Kind.NUMBER, Kind.STRING, Kind.ELIF, Kind.FI, Kind.O_BRA, Kind.C_BRA:
			throwError(_prop.msgs.scriptErrorInvalidBranch, tok);
			break;
		case Kind.IF, Kind.VAR_NAME:
			while (i < tokens.length) {
				Token text;
				if (tokens[i].kind !is Kind.VAR_NAME) {
					i++;
					if (tokens.length <= i) {
						throwError(_prop.msgs.scriptErrorNoIfText, tok);
					}
					text = tokens[i];
					i++;
					if (tokens.length <= i) {
						throwError(_prop.msgs.scriptErrorNoIfContents, tok);
					}
				}
				auto node = analyzeSyntaxStatement(tokens, i, keys);
				node.text = text;
				r ~= node;
				if (tokens.length <= i) return r;
				switch (tokens[i].kind) {
				case Kind.START: return r;
				case Kind.FI: i++; return r;
				case Kind.ELIF: continue;
				case Kind.VAR_NAME: continue;
				case Kind.IF, Kind.O_BRA, Kind.C_BRA, Kind.SYMBOL, Kind.NUMBER, Kind.STRING:
					throwError(_prop.msgs.scriptErrorInvalidStatement, tokens[i]);
					break;
				}
			}
			break;
		case Kind.SYMBOL:
			r ~= analyzeSyntaxStatement(tokens, i, keys);
			break;
		default: assert (0);
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
			if (tokens.length <= i) return node;
			if (tokens[i].kind is Kind.START) return node;
			i = j;
			if (tokens[i].kind is Kind.IF || tokens[i].kind is Kind.SYMBOL) {
				node.childs ~= analyzeSyntaxBranch(tokens, i, keys);
				node.childs[0].beforeVars = cVars;
				break;
			}
			break;
		case Kind.IF, Kind.SYMBOL:
			node.childs ~= analyzeSyntaxBranch(tokens, i, keys);
			break;
		case Kind.O_BRA, Kind.C_BRA, Kind.NUMBER, Kind.STRING:
			assert (0);
		default: assert (0);
		}
		return node;
	}
	private Node[] analyzeSyntaxAttr(in Token[] tokens, ref size_t i, in Keywords keys) {
		Node[] r;
		while (i < tokens.length) {
			auto tok = tokens[i];
			switch (tok.kind) {
			case Kind.O_BRA:
				r ~= analyzeSyntaxBrackets(tokens, i, keys);
				i++;
				break;
			case Kind.START, Kind.IF, Kind.ELIF, Kind.FI:
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
			case Kind.C_BRA, Kind.C_PAR, Kind.EQ, Kind.MUL, Kind.DIV, Kind.RES:
				throwError(_prop.msgs.scriptErrorInvalidAttr, tok);
				break;
			default: assert (0);
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
		tokens = s.tokenize(`area 1 "="if "next"`);
		i = 0;
		auto arr = [
			Node(NodeType.VALUE, Token(0, 0, Kind.SYMBOL, "area")),
			Node(NodeType.VALUE, Token(0, 5, Kind.NUMBER, "1")),
			Node(NodeType.VALUE, Token(0, 7, Kind.STRING, `"="`))
		];
		arr[0].var ~= arr[0].token;
		arr[1].var ~= arr[1].token;
		arr[2].var ~= arr[2].token;
		assert (s.analyzeSyntaxAttr(tokens, i, KEYS) == arr);
		assert (tokens[i].kind is Kind.IF);
		tokens = s.tokenize(`area 1 "="Start`);
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
			switch (tok.kind) {
			case Kind.C_BRA: return r;
			case Kind.O_BRA:
				r.values ~= analyzeSyntaxBrackets(tokens, i, keys);
				i++;
				break;
			case Kind.SYMBOL, Kind.NUMBER, Kind.STRING, Kind.VAR_NAME, Kind.O_PAR, Kind.PLU, Kind.MIN:
				auto node = Node(NodeType.VALUE, tok);
				node.var = analyzeSyntaxValue(tokens, i, keys);
				r.values ~= node;
				break;
			case Kind.START, Kind.IF, Kind.FI, Kind.ELIF, Kind.EQ:
				throwError(_prop.msgs.scriptErrorInvalidValuesClose, tok);
				break;
			default: assert (0);
			}
		}
		throwError("Close bracket not forund", o);
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
			case Kind.VAR_NAME, Kind.NUMBER:
				if (!num) return r;
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
				if (!num && calcin) return r;
				r ~= tok;
				i++;
				calcin = true;
				break;
			case Kind.C_PAR:
				if (num) throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
				r ~= tok;
				i++;
				break;
			case Kind.MUL, Kind.DIV, Kind.RES:
				if (num) throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
				r ~= tok;
				num = true;
				i++;
				break;
			case Kind.SYMBOL, Kind.STRING:
				if (!calcin) {
					r ~= tok;
					i++;
				}
				return r;
			case Kind.O_BRA, Kind.C_BRA:
			case Kind.START, Kind.IF, Kind.FI, Kind.ELIF, Kind.EQ:
				return r;
			default: assert (0);
			}
		}
		return r;
	}

	private T parseAttr(T, bool Within = false)(in Node[] attr, ref size_t i, lazy T defValue, in Token[string] varTable) {
		if (attr.length <= i) return defValue;
		auto tok = var(attr[i], varTable);
		auto value = attrValue(attr[i], varTable);
		static if (is(T == string)) {
			i++;
			return value;
		} else static if (isVArray!(T)) {
			T r;
			while (i < attr.length && attr[i].type is NodeType.VALUES) {
				r ~= parseAttr!(typeof(T[0]), Within)(attr, i, typeof(T[0]).init, varTable);
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
			i++;
			return parseTalker!(Within)(attr[i], varTable);
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
			string path = parseAttr!(string)(vals, j, "", varTable);
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
					r.rCoupons = parseAttr!(string[])(vals, j, [], varTable);
				} else {
					r.rCoupons = std.string.split(parseAttr!(string)(vals, j, "", varTable), ";");
				}
			}
			r.text = parseAttr!(string)(vals, j, r.text, varTable);
			i++;
			return r;
		} else static if (is(T == int)) {
			if (value == "all") return 0; // カード削除用
			i++;
			return to!(int)(value);
		} else static if (is(T == ulong)) {
			i++;
			return to!(ulong)(value);
		} else static assert (0);
	}
	private void parseAttrTalker(in Node[] attr, ref size_t i, ref Talker t, ref string cardPath, in Token[string] varTable) {
		if (attr.length <= i) return;
		auto tok = var(attr[i], varTable);
		auto value = attrValue(attr[i], varTable);
		if (tok.kind is Kind.STRING) {
			t = Talker.IMAGE;
			cardPath = value;
			i++;
			return;
		}
		cardPath = "";
		t = parseTalker!(false)(attr[i], varTable);
		i++;
	}
	private Talker parseTalker(bool Within)(in Node node, in Token[string] varTable) {
		auto tok = var(node, varTable);
		auto value = attrValue(node, varTable);
		switch (value) {
		case "n", "none":
			static if (Within) goto default;
			return Talker.NARRATION;
		case "m", "selected": return Talker.SELECTED;
		case "u", "unselected": return Talker.UNSELECTED;
		case "r", "random": return Talker.RANDOM;
		case "c", "card":
			static if (Within) goto default;
			return Talker.CARD;
		default: throwError(_prop.msgs.scriptErrorInvalidTalker, tok);
		}
		assert (0);
	}
	private string parseNextValue(in Node node, in Keywords keys, in Token[string] varTable) {
		auto value = var(node.text, varTable);
		string r;
		if (value.kind is Kind.SYMBOL) {
			auto valStr = std.string.tolower(value.value);
			if (valStr in keys.keywords) {
				throwError(_prop.msgs.scriptErrorUndefinedSymbol, node.text);
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
				throwError(_prop.msgs.scriptErrorUndefinedSymbol, node.text);
			}
		} else {
			r = stringValue(value);
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
	private Content[] analyzeSemanticsImpl(in Node[] nodes, in Keywords keys, in Token[string] varTable) {
		Content[] r;
		varTable = dupAssocArray(varTable);
		foreach (node; nodes) {
			foreach (var; node.beforeVars) {
				if (var.type !is NodeType.VAR_SET) {
					throwError(_prop.msgs.scriptErrorInvalidVar, var.token);
				}
				varTable[std.string.tolower(node.token.value)] = varValue(var, varTable);
			}
			if (node.type is NodeType.VAR_SET) {
				varTable[std.string.tolower(node.token.value)] = varValue(node, varTable);
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
				string path = c.cardPath;
				parseAttrTalker(node.attr, i, t, path, varTable);
				c.talkerC = t;
				c.cardPath = path;
			}
			if (detail.use(CArg.TEXT)) {
				c.text = parseAttr!(string)(node.attr, i, c.text, varTable);
			}
			if (detail.use(CArg.TALKER_NC)) {
				c.talkerNC = parseAttr!(Talker, true)(node.attr, i, c.talkerNC, varTable);
			}
			if (detail.use(CArg.DIALOGS)) {
				c.dialogs = parseAttr!(SDialog[])(node.attr, i, c.dialogs, varTable);
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
				c.bgmPath = parseAttr!(string)(node.attr, i, c.bgmPath, varTable);
			}
			if (detail.use(CArg.SOUND_PATH)) {
				c.soundPath = parseAttr!(string)(node.attr, i, c.soundPath, varTable);
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
		toScriptImpl(buf, cs, indent, "", KEYS, legacy);
		return buf;
	}
	string encodeString(string s) {
		return std.string.replace(s, "\"", "\\\"");
	}
	private void toAttr(bool Within = false, T)(ref char[] attrs, T value, string command, string indentValue, bool space = true) {
		if (space) attrs ~= " ";
		static if (is(T == string)) {
			auto lines = splitlines(value);
			if (lines.length == 0) {
				attrs ~= `""`;
			} else if (lines.length == 1) {
				attrs ~= `"` ~ encodeString(lines[0]) ~ `"`;
			} else {
				size_t lns = 0;
				foreach (i, line; lines) {
					if (line.length) {
						lns = i;
						break;
					}
				}
				attrs ~= "@";
				if (lns > 0) {
					attrs ~= " " ~ to!(string)(lns + 1);
					lines = lines[lns .. $];
				}
				attrs ~= "\n";
				bool spaceLine = false;
				foreach (line; lines) {
					line = std.string.replace(line, "@", "\\@");
					if (line.length && (line[0] == ' ' || line[0] == '\t')) {
						line = "\\" ~ line;
					}
					attrs ~= indentValue ~ line ~ "\n";
					spaceLine = line.length == 0;
				}
				if (spaceLine) {
					attrs ~= "@";
				} else {
					attrs ~= indentValue ~ "@";
				}
			}
		} else static if (isVArray!(T)) {
			foreach (i, v; value) {
				toAttr(attrs, v, command, indentValue, i > 0);
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
				toAttr(attrs, value.sleep, command, indentValue);
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
			return toAttrTalker(attrs, value, "", false);
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
			attrs ~= "[";
			toAttr(attrs, value.path, command, indentValue, false);
			toAttr(attrs, value.flag, command, indentValue);
			toAttr(attrs, value.x, command, indentValue);
			toAttr(attrs, value.y, command, indentValue);
			toAttr(attrs, value.width, command, indentValue);
			toAttr(attrs, value.height, command, indentValue);
			toAttr(attrs, value.mask, command, indentValue);
			attrs ~= "]";
		} else static if (is(T == Motion)) {
			auto detail = value.detail;
			attrs ~= "[";
			toAttr(attrs, value.type, command, indentValue, false);
			if (detail.use(MArg.VALUE_TYPE)) {
				toAttr(attrs, value.damageType, command, indentValue);
			}
			if (detail.use(MArg.U_VALUE)) {
				toAttr(attrs, value.uValue, command, indentValue);
			}
			if (detail.use(MArg.A_VALUE)) {
				toAttr(attrs, value.aValue, command, indentValue);
			}
			if (detail.use(MArg.ROUND)) {
				toAttr(attrs, value.round, command, indentValue);
			}
			if (detail.use(MArg.BEAST)) {
				ulong id = 0UL;
				if (value.beast) {
					auto beast = _summ.findSomeBeast(value.beast);
					if (beast) id = beast.id;
				}
				toAttr(attrs, id, command, indentValue);
			}
			toAttr(attrs, value.element, command, indentValue);
			attrs ~= "]";
		} else static if (is(T == SDialog)) {
			attrs ~= "[";
			bool semic = false;
			foreach (c; value.rCoupons) {
				if (std.string.find(c, ";") >= 0) {
					semic = true;
					break;
				}
			}
			if (semic) {
				attrs ~= "[";
				foreach (i, c; value.rCoupons) {
					if (i > 0) attrs ~= " ";
					attrs ~= `"` ~ encodeString(c) ~ `"`;
				}
				attrs ~= "]";
			} else {
				attrs ~= std.string.join(value.rCoupons, ";");
			}
			toAttr(attrs, value.text, command, indentValue);
			attrs ~= "]";
		} else static if (is(T == int)) {
			if (value < 0) attrs ~= "(";
			attrs ~= to!(string)(value);
			if (value < 0) attrs ~= ")";
		} else static if (is(T == uint)) {
			attrs ~= to!(string)(value);
		} else static if (is(T == ulong)) {
			attrs ~= to!(string)(value);
		} else static assert (0);
	}
	private void toAttrTalker(ref char[] attrs, Talker t, string cardPath, bool space) {
		if (space) attrs ~= " ";
		switch (t) {
		case Talker.NARRATION: attrs ~= "none"; break;
		case Talker.SELECTED: attrs ~= "M"; break;
		case Talker.UNSELECTED: attrs ~= "U"; break;
		case Talker.RANDOM: attrs ~= "R"; break;
		case Talker.CARD: attrs ~= "C"; break;
		case Talker.IMAGE: attrs ~= `"` ~ encodeString(cardPath) ~ `"`; break;
		default: assert (0);
		}
	}
	private void toScriptImpl(ref char[] buf, in Content[] cs, string indent, string indentValue, in Keywords keys, bool legacy) {
		foreach (i, c; cs) {
			if (i > 0) buf ~= "\n";
			buf ~= indentValue;
			auto detail = c.detail;
			string command = keys.commands[c.type];
			buf ~= command;
			char[] attrs;
			if (c.type is CType.START) {
				attrs ~= ` "` ~ encodeString(c.name) ~ `"`;
			}
			if (detail.use(CArg.TALKER_C)) {
				toAttrTalker(attrs, c.talkerC, c.cardPath, true);
			}
			if (detail.use(CArg.TEXT)) {
				toAttr(attrs, c.text, command, indentValue);
			}
			if (detail.use(CArg.TALKER_NC)) {
				toAttr!(true)(attrs, c.talkerNC, command, indentValue);
			}
			if (detail.use(CArg.DIALOGS)) {
				toAttr(attrs, c.dialogs, command, indentValue);
			}
			if (detail.use(CArg.BG_IMAGES)) {
				toAttr(attrs, c.backs, command, indentValue);
			}
			if (detail.use(CArg.MOTIONS)) {
				toAttr(attrs, c.motions, command, indentValue);
			}
			if (detail.use(CArg.TARGET_NS)) {
				toAttr!(true)(attrs, c.targetNS, command, indentValue);
			}
			if (detail.use(CArg.TARGET_S)) {
				toAttr(attrs, c.targetS, command, indentValue);
			}
			if (detail.use(CArg.RANGE)) {
				toAttr(attrs, c.range, command, indentValue);
			}
			if (detail.use(CArg.AREA)) {
				toAttr(attrs, c.area, command, indentValue);
			}
			if (detail.use(CArg.BATTLE)) {
				toAttr(attrs, c.battle, command, indentValue);
			}
			if (detail.use(CArg.PACKAGE)) {
				toAttr(attrs, c.packages, command, indentValue);
			}
			if (detail.use(CArg.CAST)) {
				toAttr(attrs, c.casts, command, indentValue);
			}
			if (detail.use(CArg.ITEM)) {
				toAttr(attrs, c.item, command, indentValue);
			}
			if (detail.use(CArg.SKILL)) {
				toAttr(attrs, c.skill, command, indentValue);
			}
			if (detail.use(CArg.INFO)) {
				toAttr(attrs, c.info, command, indentValue);
			}
			if (detail.use(CArg.BEAST)) {
				toAttr(attrs, c.beast, command, indentValue);
			}
			if (detail.use(CArg.START)) {
				toAttr(attrs, c.start, command, indentValue);
			}
			if (detail.use(CArg.COMPLETE)) {
				toAttr(attrs, c.complete, command, indentValue);
			}
			if (detail.use(CArg.MONEY)) {
				toAttr(attrs, c.money, command, indentValue);
			}
			if (detail.use(CArg.COUPON)) {
				toAttr(attrs, c.coupon, command, indentValue);
			}
			if (detail.use(CArg.COUPON_VALUE)) {
				toAttr(attrs, c.couponValue, command, indentValue);
			}
			if (detail.use(CArg.COMPLETE_STAMP)) {
				toAttr(attrs, c.completeStamp, command, indentValue);
			}
			if (detail.use(CArg.GOSSIP)) {
				toAttr(attrs, c.gossip, command, indentValue);
			}
			if (detail.use(CArg.FLAG)) {
				toAttr(attrs, c.flag, command, indentValue);
			}
			if (detail.use(CArg.FLAG_VALUE)) {
				toAttr(attrs, c.flagValue, command, indentValue);
			}
			if (detail.use(CArg.STEP)) {
				toAttr(attrs, c.step, command, indentValue);
			}
			if (detail.use(CArg.STEP_VALUE)) {
				toAttr(attrs, c.stepValue, command, indentValue);
			}
			if (detail.use(CArg.CARD_NUMBER)) {
				toAttr(attrs, c.cardNumber, command, indentValue);
			}
			if (detail.use(CArg.CARD_VISUAL)) {
				toAttr(attrs, c.cardVisual, command, indentValue);
			}
			if (detail.use(CArg.UNSIGNED_LEVEL)) {
				toAttr(attrs, c.unsignedLevel, command, indentValue);
			}
			if (detail.use(CArg.SIGNED_LEVEL)) {
				toAttr(attrs, c.signedLevel, command, indentValue);
			}
			if (detail.use(CArg.PHYSICAL)) {
				toAttr(attrs, c.physical, command, indentValue);
			}
			if (detail.use(CArg.MENTAL)) {
				toAttr(attrs, c.mental, command, indentValue);
			}
			if (detail.use(CArg.WAIT)) {
				toAttr(attrs, c.wait, command, indentValue);
			}
			if (detail.use(CArg.PERCENT)) {
				toAttr(attrs, c.percent, command, indentValue);
			}
			if (detail.use(CArg.TARGET_ALL)) {
				toAttr(attrs, c.targetAll, command, indentValue);
			}
			if (detail.use(CArg.RANDOM)) {
				toAttr(attrs, c.random, command, indentValue);
			}
			if (detail.use(CArg.AVERAGE)) {
				toAttr(attrs, c.average, command, indentValue);
			}
			if (detail.use(CArg.PARTY_NUMBER)) {
				toAttr(attrs, c.partyNumber, command, indentValue);
			}
			if (detail.use(CArg.SUCCESS_RATE)) {
				toAttr(attrs, c.successRate, command, indentValue);
			}
			if (detail.use(CArg.EFFECT_TYPE)) {
				toAttr(attrs, c.effectType, command, indentValue);
			}
			if (detail.use(CArg.RESIST)) {
				toAttr(attrs, c.resist, command, indentValue);
			}
			if (detail.use(CArg.STATUS)) {
				toAttr(attrs, c.status, command, indentValue);
			}
			if (detail.use(CArg.BGM_PATH)) {
				toAttr(attrs, c.bgmPath, command, indentValue);
			}
			if (detail.use(CArg.SOUND_PATH)) {
				toAttr(attrs, c.soundPath, command, indentValue);
			}
			if (!legacy) {
				if (detail.use(CArg.TRANSITION_SPEED)) {
					toAttr(attrs, c.transitionSpeed, command, indentValue);
				}
				if (detail.use(CArg.TRANSITION)) {
					toAttr(attrs, c.transition, command, indentValue);
				}
			}
			bool useIf = c.next.length > 1;
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
			buf ~= attrs;
			foreach (idx, chld; c.next) {
				if (useIf) {
					buf ~= "\n" ~ indentValue;
					buf ~= idx == 0 ? "if " : "elif ";
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
					toScriptImpl(buf, [chld], indent, indentValue ~ indent, keys, legacy);
				} else {
					buf ~= "\n";
					if (c.type is CType.START) {
						toScriptImpl(buf, [chld], indent, indentValue ~ indent, keys, legacy);
					} else {
						toScriptImpl(buf, [chld], indent, indentValue, keys, legacy);
					}
				}
			}
			if (useIf) {
				buf ~= "\n" ~ indentValue ~ "fi";
			}
		}
	}
}
