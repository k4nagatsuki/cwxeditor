
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
import cwx.coupon;
import cwx.structs;

import std.algorithm;
import std.conv;
import std.array;
import std.ascii;
import std.stdio;
import std.string;
import std.regex;
import std.exception;
import std.traits;

/// スクリプトの解析途中に発生したエラー。
struct CWXSError {
	/// エラーメッセージ。
	string message;
	/// エラー発生行。
	int errLine;
	/// 行内の位置。
	int errPos;
	/// エラーチェック箇所の __FILE__
	string file;
	/// エラーチェック箇所の __LINE__
	size_t line;
}

/// ditto
class CWXScriptException : Exception {
	this (string file, size_t line, string text, const CWXSError[] errors, bool over100) {
		super ("cwx script error", file, line);
		_text = text;
		_errors = errors;
		_over100 = over100;
	}
	private string _text;
	private const(CWXSError[]) _errors;
	private bool _over100;

	/// 解析対象のテキスト。
	@property
	const
	string text() {return _text;}
	/// 発生したエラーの配列。
	@property
	const
	const(CWXSError[]) errors() {return _errors;}
	/// エラーが100件を超えたか。
	@property
	const
	bool over100() {return _over100;}
}

/// 空変数への設定値。
struct VarSet {
	string var; /// 変数名。
	string value; /// 設定値。
}

/// コンパイルオプション。
struct CompileOption {
	bool linkId = false; /// カードを参照で設定するか。
	int startLine = 0; /// スクリプトの論理的な開始行(通常0)。
	int startPos = 0; /// スクリプトの論理的な開始位置(通常0)。
	int addLines = 0; /// スクリプトに追加した行数(通常0)。
}

/// スクリプトを解析し、コンテント群にして返す。
/// 解析中にエラーがあった場合はCWXScriptExceptionを投げる。
static Content[] compile(const(CProps) prop, const(Summary) summ, string script, in CompileOption opt) {
	auto compiler = new CWXScript(prop, summ, script);
	auto tokens = compiler.tokenize(script, opt);
	if (compiler.errors.length) throw new CWXScriptException(__FILE__, __LINE__, script, compiler.errors, false);
	auto nodes = compiler.analyzeSyntax(tokens);
	if (compiler.errors.length) throw new CWXScriptException(__FILE__, __LINE__, script, compiler.errors, false);
	auto r = compiler.analyzeSemantics(nodes, opt);
	if (compiler.errors.length) throw new CWXScriptException(__FILE__, __LINE__, script, compiler.errors, false);
	return r;
}

/// スクリプトからコンテントツリーを生成する。
class CWXScript {
	private const(CProps) _prop;
	private const(Summary) _summ;
	private string _text;
	private size_t _maxError;
	private size_t _autoWrap;
	/// 唯一のコンストラクタ。
	this (const(CProps) prop, const(Summary) summ, string text = "", size_t maxError = 100, size_t autoWrap = 250) {
		_prop = prop;
		_summ = summ;
		_text = text;
		_maxError = maxError;
		_autoWrap = autoWrap;
	}
	private CWXSError[] _errors;
	/// 各メソッド呼び出しで蓄積されたエラーを返す。
	@property
	const
	const(CWXSError[]) errors() {return _errors;}

	/// sをスクリプト内での文字列表現に変換する。
	static string createString(string s) {
		return "\"" ~ std.array.replace(s, "\"", "\"\"") ~ "\"";
	}

	private void throwError(string File = __FILE__, size_t Line = __LINE__)
			(lazy string message, in Token tok) {
		throwErrorToken!(File, Line)(message, tok.line, tok.pos, tok.value);
	}
	private void throwErrorToken(string File = __FILE__, size_t Line = __LINE__)
			(lazy string message, int line, int pos, string value) {
		if (!_maxError) return;
		if (_errors.length && _errors[$ - 1].errLine == line && _errors[$ - 1].errPos == pos) {
			// 同一箇所でのエラーは一つだけにする
			return;
		}
		string msg;
		if (!_prop || !_prop.msgs) {
			msg = "";
		} else {
			msg = message;
		}
		if (_maxError <= _errors.length) {
			throw new CWXScriptException(__FILE__, __LINE__, _text, errors, true);
		}
		_errors ~= CWXSError(msg, line, pos, File, Line);
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
		C_PAR, /// )
		COMMENT /// コメント
	}

	/// スクリプトのトークン。
	static struct Token {
		int line; /// トークンのある行。
		int pos; /// 行内の位置。
		size_t index; /// スクリプト全体での位置。
		Kind kind; /// 種別。
		string value; /// 値。
		string comment = ""; /// 直前のコメント。
		/// 文字列表現。
		const
		string toString() {
			return .format("Token {line %d : %d, %d, %s, %s, %s}", line, pos, index, to!(string)(kind), value, comment);
		}
		/// oと等しいか。
		const
		bool opEquals(ref const(Token) o) {
			return line == o.line && pos == o.pos && index == o.index && kind == o.kind && value == o.value && comment == o.comment;
		}
	}
	private static string[] wrap(string line, size_t width) {
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
	const
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
		string decode(in char[] s, char esc) {
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
			buf = buf[0 .. len];
			return assumeUnique(buf);
		}
		if (tok.kind !is Kind.STRING || tok.value.length < 2) {
			throwError(_prop.msgs.scriptErrorInvalidString, tok);
		}
		if (tok.value[0] == '@') {
			char[] buf;
			auto linesBase = .splitLines!string(tok.value[0 .. $ - 1].idup);
			string firstLine = linesBase[0];
			string[] lines;
			string[] resultLines;
			foreach (i, line; linesBase[1 .. $]) {
				line = .astripl(line);
				line = decode(line, tok.value[0]);
				if (line.length >= 1 && line[0] == '\\') {
					line = line[1 .. $];
				}
				resultLines ~= line;
				lines ~= wrap(line, width);
			}
			if (firstLine.length > 1) {
				auto lnStr = std.string.toLower(.astrip(firstLine[1 .. $]));
				bool isNum = std.string.isNumeric(lnStr);
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
			foreach (i, line; resultLines) {
				if (i > 0) buf ~= '\n';
				buf ~= line;
			}
			return assumeUnique(buf);
		}
		return decode(tok.value[1 .. $ - 1], tok.value[0]);
	} unittest {
		debug mixin(UTPerf);
		auto s = new CWXScript(new CProps("", null), null);
		assert (s.stringValue(Token(0, 0, 0, Kind.STRING, `"abc"`), 0) == "abc");
		assert (s.stringValue(Token(0, 0, 0, Kind.STRING, `"a""bc"`), 0) == "a\"bc");
		assert (s.stringValue(Token(0, 0, 0, Kind.STRING, `'ab''c'`), 0) == "ab'c");
		assert (s.stringValue(Token(0, 2, 0, Kind.STRING, "@ 3\n\t\tte@@st\n   t\\e\\st\n\\   a\n\\\\   a@"), false)
			 == "\n\nte@st\nt\\e\\st\n   a\n\\   a");
		assert (s.stringValue(Token(0, 0, 0, Kind.STRING, "@\nabcabc\n@"), 3) == "abcabc", s.stringValue(Token(0, 0, 0, Kind.STRING, "@\nabcabc\n@"), 3));
	}

	/// textから冒頭の空変数群を取得する。
	/// 読込まれた分のスクリプトはtextから除かれる。
	string[] eatEmptyVars(ref string text, ref CompileOption opt) {
		auto tokens = tokenizeImpl(text, true, opt);
		// コメントを取り除く
		Token[] tokens2;
		foreach (tok; tokens) {
			if (tok.kind !is Kind.COMMENT) {
				tokens2 ~= tok;
			}
		}
		string[] r;
		size_t index = 0;
		size_t len = 0;
		opt.startLine = 0;
		opt.startPos = 0;
		// 空の変数のみを取得するため、'='が現れたらその場で処理終了
		foreach (i, tok; tokens2) {
			if (tok.kind is Kind.EQ) {
				throwError(_prop.msgs.scriptErrorInvalidSyntax, tok);
				break;
			} else if (tok.kind is Kind.VAR_NAME) {
				if (i + 1 < tokens2.length && tokens2[i + 1].kind is Kind.EQ) {
					break;
				}
				index = tok.index;
				len = tok.value.length;
				opt.startLine = tok.line;
				opt.startPos = tok.pos + len;
				r ~= tok.value;
			}
		}
		text = text[index + len .. $];
		return r;
	} unittest {
		debug mixin(UTPerf);
		CompileOption opt;
		auto s = new CWXScript(new CProps("", null), null);
		auto str = "/*c1*/ $test1 $test2 //$test3\n$test4// aaa\n$test5 = a $test6 endsc true";
		auto vars = s.eatEmptyVars(str, opt);
		assert (vars == ["$test1", "$test2", "$test4"], .text(vars));
		assert (str == "// aaa\n$test5 = a $test6 endsc true", str);
		assert (opt.startLine == 1);
		assert (opt.startPos == 6);
	}
	/// textに変数 = 初期化値の定義を追加する。
	static string pushVars(string text, in VarSet[] varTable, ref CompileOption opt) {
		string[] lines;
		opt.addLines = 0;
		foreach (t; varTable) {
			string v = t.value;
			if (!v.length) v = `""`;
			auto l = t.var ~ " = " ~ v;
			lines ~= l;
			opt.addLines += v.splitLines().length;
		}
		lines ~= text;
		opt.startLine -= opt.addLines;
		return lines.join("\n");
	} unittest {
		CompileOption opt;
		VarSet[] varSet = [VarSet("$a", "1"), VarSet("$b", "2")];
		auto r = pushVars("aaa bbb", varSet, opt);
		assert (r == "$a = 1\n$b = 2\naaa bbb", r);
		assert (opt.startLine == -2, .text(opt.startLine));
	}

	/// textをTokenに分割する。
	Token[] tokenize(string text, in CompileOption opt = CompileOption.init) {
		return tokenizeImpl(text, false, opt);
	} unittest {
		debug mixin(UTPerf);
		auto s = new CWXScript(new CProps("", null), null);
		auto tokens = s.tokenize("");
		assert (tokens == [], to!string(tokens));
		tokens = s.tokenize("/*/*\n*/*/");
		assert (tokens == [Token(0, 0, 0, Kind.COMMENT, "/*/*\n*/*/", "")], to!string(tokens));
		tokens = s.tokenize("/*c*/start, 12.3 \ntest1 [$void] =\"str\ning//\"\n\r //comment\nELIF if\n1/2+3*4%(5-6)");
		assert (tokens
			== [
				Token(0, 0, 0, Kind.COMMENT, "/*c*/", ""),
				Token(0, 5, 5, Kind.START, "start", "c"),
				Token(0, 10, 10, Kind.COMMA, ","),
				Token(0, 12, 12, Kind.NUMBER, "12.3"),
				Token(1, 0, 18, Kind.SYMBOL, "test1"),
				Token(1, 6, 24, Kind.O_BRA, "["),
				Token(1, 7, 25, Kind.VAR_NAME, "$void"),
				Token(1, 12, 30, Kind.C_BRA, "]"),
				Token(1, 14, 32, Kind.EQ, "="),
				Token(1, 15, 33, Kind.STRING, "\"str\ning//\""),
				Token(4, 1, 47, Kind.COMMENT, "//comment\n", ""),
				Token(5, 0, 57, Kind.ELIF, "ELIF", "comment\n"),
				Token(5, 5, 62, Kind.IF, "if"),
				Token(6, 0, 65, Kind.NUMBER, "1"),
				Token(6, 1, 66, Kind.DIV, "/"),
				Token(6, 2, 67, Kind.NUMBER, "2"),
				Token(6, 3, 68, Kind.PLU, "+"),
				Token(6, 4, 69, Kind.NUMBER, "3"),
				Token(6, 5, 70, Kind.MUL, "*"),
				Token(6, 6, 71, Kind.NUMBER, "4"),
				Token(6, 7, 72, Kind.RES, "%"),
				Token(6, 8, 73, Kind.O_PAR, "("),
				Token(6, 9, 74, Kind.NUMBER, "5"),
				Token(6, 10, 75, Kind.MIN, "-"),
				Token(6, 11, 76, Kind.NUMBER, "6"),
				Token(6, 12, 77, Kind.C_PAR, ")")
			], to!string(tokens));
	}
	private Token[] tokenizeImpl(ref string text, bool eatEmptyVarMode, in CompileOption opt) {
		if (!text.length) return [];
		Token[] r;
		text = std.array.replace(text, "\r\n", "\n");
		text = std.array.replace(text, "\r", "\n");
		string dtext = text;
		auto reg = .regex("(" ~ std.string.join(TOKENS.dup, ")|(") ~ ")", "gi");
		size_t i = 0;
		size_t hits = 0;
		size_t pos = 0;
		size_t index = 0;
		int commentLevel = 0;
		size_t lastCommentLine = 0;
		size_t lastCommentPos = 0;
		size_t lastCommentIndex = 0;
		string post;
		bool spaceAfter = false;
		string docComment = "";
		string fullComment = "";
		@property int sLine() {return cast(int) i + opt.startLine;}
		@property int sPos() {return (cast(int) i == opt.addLines) ? (cast(int) pos + opt.startPos) : pos;}
		foreach (token; .match(dtext, reg)) {
			post = token.post;
			string pre = token.pre;
			index = pre.length;
			auto dstr = token.hit;
			void retCount2(string dstr) {
				size_t count = .count(dstr, "\n");
				if (count > 0) {
					pos = dstr.length - std.string.lastIndexOf(dstr, '\n') - 1;
					i += count;
				} else {
					pos += dstr.length;
				}
			}
			void retCount() {
				retCount2(dstr);
			}
			auto c = dstr[0];
			string str = to!string(dstr);

			if (cast(int) pre.length - cast(int) hits > 0) {
				if (0 < commentLevel) {
					/// in comment
					retCount2(pre[hits .. $]);
					hits = pre.length;
				} else {
					string lpre = pre;
					if (lpre.length && (lpre[$ - 1] == '@' || lpre[$ - 1] == '"' || lpre[$ - 1] == '\'')) {
						throwErrorToken(_prop.msgs.scriptErrorUnCloseString, sLine, sPos, "");
						return r;
					} else {
						throwErrorToken(_prop.msgs.scriptErrorInvalidToken, sLine, sPos, "");
					}
				}
			}
			if (0 < commentLevel) {
				fullComment ~= .text(pre[hits .. $]) ~ str;
			}
			bool commentStart = false;
			if (str == "/*") {
				// multi line comment (open)
				spaceAfter = true;
				if (commentLevel == 0) {
					commentStart = true;
					lastCommentLine = i;
					lastCommentPos = pos;
					lastCommentIndex = index;
				}
				pos += dstr.length;
				if (0 == commentLevel) fullComment = str;
				commentLevel++;
			} else if (str == "*/") {
				// multi line comment (close)
				spaceAfter = true;
				pos += dstr.length;
				if (commentLevel <= 0) {
					throwErrorToken(_prop.msgs.scriptErrorUnOpenComment, sLine, sPos, str);
				}
				commentLevel--;
				if (0 == commentLevel) {
					r ~= Token(lastCommentLine, lastCommentPos, lastCommentIndex, Kind.COMMENT, fullComment, "");
				}
			} else if (0 < commentLevel) {
				spaceAfter = true;
				retCount();
 			} else if (isAlpha(c) || c == '_') {
 				if (eatEmptyVarMode) return r;
				spaceAfter = false;
				// symbol
				switch (std.string.toLower(dstr)) {
				case "start":
					r ~= Token(sLine, sPos, index, Kind.START, str, docComment);
					break;
				case "if":
					r ~= Token(sLine, sPos, index, Kind.IF, str, docComment);
					break;
				case "elif":
					r ~= Token(sLine, sPos, index, Kind.ELIF, str, docComment);
					break;
				case "fi":
					r ~= Token(sLine, sPos, index, Kind.FI, str, docComment);
					break;
				case "sif":
					r ~= Token(sLine, sPos, index, Kind.SIF, str, docComment);
					break;
				default:
					r ~= Token(sLine, sPos, index, Kind.SYMBOL, str, docComment);
					break;
				}
				pos += dstr.length;
 				docComment = "";
			} else if (c == '$') {
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.VAR_NAME, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '=') {
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.EQ, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '[') {
 				if (eatEmptyVarMode) return r;
				// open bracket
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.O_BRA, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == ']') {
 				if (eatEmptyVarMode) return r;
				// close bracket
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.C_BRA, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (isDigit(c)) {
 				if (eatEmptyVarMode) return r;
				// number
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.NUMBER, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '@' || c == '"' || c == '\'') {
 				if (eatEmptyVarMode) return r;
				// string
				if (!spaceAfter && r.length && r[$ - 1].kind is Kind.STRING
						&& r[$ - 1].value[$ - 1] == c) {
					// 直前のstringに結合
					r[$ - 1].value ~= str;
				} else {
					r ~= Token(sLine, sPos, index, Kind.STRING, str, docComment);
				}
				spaceAfter = false;
				retCount();
 				docComment = "";
			} else if (isWhite(c)) {
				// whitespace
				spaceAfter = true;
				retCount();
			} else if (c == '+') {
 				if (eatEmptyVarMode) return r;
				// plus
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.PLU, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '-') {
 				if (eatEmptyVarMode) return r;
				// minus
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.MIN, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '*') {
 				if (eatEmptyVarMode) return r;
				// multiply
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.MUL, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '/') {
				if (dstr.length >= 2 && str[1] == '/') {
					// line comment
					spaceAfter = true;
					r ~= Token(sLine, sPos, index, Kind.COMMENT, str, "");
					i++;
					pos = 0;
					if (2 < str.length) docComment ~= str[2 .. $];
				} else {
 					if (eatEmptyVarMode) return r;
					// divide
					spaceAfter = false;
					r ~= Token(sLine, sPos, index, Kind.DIV, str, docComment);
					pos += dstr.length;
 					docComment = "";
				}
			} else if (c == '%') {
 				if (eatEmptyVarMode) return r;
				// residue
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.RES, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '~') {
 				if (eatEmptyVarMode) return r;
				// cat
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.CAT, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '(') {
 				if (eatEmptyVarMode) return r;
				// open paren
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.O_PAR, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == ')') {
 				if (eatEmptyVarMode) return r;
				// close paren
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.C_PAR, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == ',') {
 				if (eatEmptyVarMode) return r;
				// comma
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.COMMA, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else {
				assert (0);
			}
			if (!commentStart && 0 < commentLevel) {
				docComment ~= str;
			}
			hits += dstr.length;
		}
		if (0 < commentLevel) {
			throwErrorToken(_prop.msgs.scriptErrorUnCloseComment, lastCommentLine, lastCommentPos, "");
		}
		if (post.length) throwErrorToken(_prop.msgs.scriptErrorInvalidToken, sLine, sPos, "");
		return r;
	}

	private enum CRKind {STR, INT, REAL}
	private class CalcResult {
		CRKind kind = CRKind.INT;
		union {
			string str;
			long numInt;
			real numReal;
		}
		this () {
			numInt = 0;
		}
		void cat(in CProps prop, in Token tok, in CalcResult rval) {
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
		private void calc(string Calc, bool ChkDiv)(in CProps prop, in Token tok, in CalcResult rval) {
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
			} else if (kind is CRKind.INT && rval.kind is CRKind.INT) {
				mixin ("numInt " ~ Calc ~ "= rval.numInt;");
			} else {
				throwError(prop.msgs.scriptErrorInvalidNumber, tok);
			}
		}
		public alias calc!("+", false) add;
		public alias calc!("-", false) min;
		public alias calc!("*", false) mul;
		public alias calc!("/", true) div;
		public alias calc!("%", true) res;
		const
		bool opEquals(ref const(CalcResult) val) {
			if (kind !is val.kind) return false;
			final switch (kind) {
			case CRKind.STR: return str == val.str;
			case CRKind.INT: return numInt == val.numInt;
			case CRKind.REAL: return numReal == val.numReal;
			}
		}
		const
		bool opEquals(int val) {
			return opEquals(cast(long) val);
		}
		const
		bool opEquals(long val) {
			final switch (kind) {
			case CRKind.STR: return false;
			case CRKind.INT: return numInt == val;
			case CRKind.REAL: return numReal == val;
			}
		}
		const
		bool opEquals(real val) {
			final switch (kind) {
			case CRKind.STR: return false;
			case CRKind.INT: return numInt == val;
			case CRKind.REAL: return numReal == val;
			}
		}
		const
		bool opEquals(string val) {
			return kind is CRKind.STR && str == val;
		}
		override
		const
		string toString() {
			final switch (kind) {
			case CRKind.STR: return str;
			case CRKind.INT: return to!(string)(numInt);
			case CRKind.REAL: return to!(string)(numReal);
			}
		}
	}
	private const OPE_LEVEL_MAX = 2;
	private CalcResult calcNum(in Token[] tokens, ref size_t i, in const(Node)[][string] varTable, size_t strWidth) {
		assert (i < tokens.length);
		auto tok = tokens[i];
		if (tok.kind is Kind.VAR_NAME) {
			i++;
			try {
				auto vt = var(tok, varTable);
				auto r = new CalcResult;
				if (vt.kind is Kind.STRING) {
					r.kind = CRKind.STR;
					r.str = stringValue(vt, strWidth);
				} else if (std.string.indexOf(vt.value, '.') != -1) {
					r.kind = CRKind.REAL;
					r.numReal = to!(real)(vt.value);
				} else {
					r.kind = CRKind.INT;
					r.numInt = to!(long)(vt.value);
				}
				return r;
			} catch (Exception e) {
				throwError(_prop.msgs.scriptErrorReqNumber, tok);
				auto r = new CalcResult;
				r.kind = CRKind.INT;
				r.numInt = 0;
				return r;
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
		auto r = new CalcResult;
		try {
			if (tokens[i].kind is Kind.NUMBER) {
				if (std.string.indexOf(tokens[i].value, '.') != -1) {
					r.kind = CRKind.REAL;
					r.numReal = to!(real)(tokens[i].value);
					if (min) r.numReal = -r.numReal;
				} else {
					r.kind = CRKind.INT;
					r.numInt = to!(long)(tokens[i].value);
					if (min) r.numInt = -r.numInt;
				}
			} else if (tokens[i].kind is Kind.STRING) {
				r.kind = CRKind.STR;
				r.str = stringValue(tokens[i], strWidth);
			} else {
				throwError(_prop.msgs.scriptErrorReqNumber, tokens[i]);
			}
			i++;
			return r;
		} catch (Exception e) {
			throwError(_prop.msgs.scriptErrorReqNumber, tokens[i]);
		}
		return r;
	}
	private CalcResult calcPar(in Token[] tokens, ref size_t i, in const(Node)[][string] varTable, size_t strWidth) {
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
	private CalcResult calcImpl(size_t opeLevel, in Token[] tokens, ref size_t i, in const(Node)[][string] varTable, size_t strWidth) {
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
					if (tokens.length < i) {
						throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
						return r;
					}
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
					if (tokens.length < i) {
						throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
						return r;
					}
					r.add(_prop, tok, calcImpl(1, tokens, i, varTable, strWidth));
					break;
				case Kind.MIN:
					i++;
					if (tokens.length < i) {
						throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
						return r;
					}
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
					if (tokens.length <= i) {
						throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
						return r;
					}
					r.mul(_prop, tok, calcPar(tokens, i, varTable, strWidth));
					break;
				case Kind.DIV:
					i++;
					if (tokens.length <= i) {
						throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
						return r;
					}
					r.div(_prop, tok, calcPar(tokens, i, varTable, strWidth));
					break;
				case Kind.RES:
					i++;
					if (tokens.length <= i) {
						throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
						return r;
					}
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
	CalcResult calc(in Token[] tokens, ref size_t i, in const(Node)[][string] varTable, size_t strWidth) {
		assert (i < tokens.length);
		return calcImpl(0, tokens, i, varTable, strWidth);
	} unittest {
		debug mixin(UTPerf);
		size_t i;
		Token[] tokens;
		const(Node)[][string] varTable;
		varTable["$abc"] = [Node(NodeType.VALUE, Token(0, 0, 0, Kind.NUMBER, "15"))];
		varTable["$s"] = [Node(NodeType.VALUE, Token(0, 0, 0, Kind.NUMBER, "0"))];
		auto s = new CWXScript(new CProps("", null), null);
		i = 0;
		assert (s.calc(s.tokenize("10 * $abc"), i, varTable, 0) == 150);
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
		tokens = s.tokenize("1 + $s");
		assert (s.calc(tokens, i, varTable, 0) == 1);
		i = 0;
		tokens = s.tokenize("$s + 1");
		assert (s.calc(tokens, i, varTable, 0) == 1);
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
		immutable CType[string] keywords;
		immutable string[CType] commands;
	}
	private static shared immutable Keywords KEYS;
	shared static this () {
		auto keywords = [
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
			cast(string) "redraw":CType.REDISPLAY,
			cast(string) "cpstep":CType.SUBSTITUTE_STEP,
			cast(string) "cpflag":CType.SUBSTITUTE_FLAG,
			cast(string) "cmpstep":CType.BRANCH_STEP_CMP,
			cast(string) "cmpflag":CType.BRANCH_FLAG_CMP,
			cast(string) "selrandom":CType.BRANCH_RANDOM_SELECT,
			cast(string) "brkeycode":CType.BRANCH_KEY_CODE,
			cast(string) "chkstep":CType.CHECK_STEP,
			cast(string) "brround":CType.BRANCH_ROUND,
		];
		string[CType] commands;
		foreach (name, type; keywords) {
			commands[type] = name;
		}
		KEYS = Keywords(.assumeUnique(keywords), .assumeUnique(commands));
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
		const(Node)[] texts = []; /// テキスト。
		const(Node)[] attr; /// 属性。
		const(Node)[] childs; /// 子ノード。
		bool nextIsChild; /// 唯一の子ノードが次にあるか。
		alias childs values; /// ノードがVALUESの場合は格納されたVALUEノードの配列。
		const(Token)[] calc; /// 計算式。
		alias calc var; /// 変数。
		alias texts value; /// 変数値。
		const(Node)[] beforeVars; /// ノードの直前に宣言された変数群。
		/// oと等しいか。
		const
		bool opEquals(ref const(Node) o) {
			return type == o.type && token == o.token && texts == o.texts
				&& attr == o.attr && childs == o.childs && calc == o.calc
				&& beforeVars == o.beforeVars;
		}
		/// コピーを生成する。
		@property
		const
		Node dup() {
			return Node(type, token, texts.dup, attr.dup, childs.dup, nextIsChild, calc.dup, beforeVars.dup);
		}
		/// 文字列表現。
		const
		string toString() {return token.toString();}
		/// ノード群をスクリプトコードにして返す。
		static string code(string indent, in Node[] array) {return code("    ", "", "", array, "sif");}
		private static string code(string indent, string bIndentValue, string indentValue, in Node[] array, string ifString) {
			string calcCode(in Node[] calc) {
				char[] calcBuf;
				enforce(1 == calc.length);
				foreach (i, tok; calc[0].calc) {
					if ((tok.kind is Kind.C_PAR)
							|| (i > 0 && calc[0].calc[i - 1].kind is Kind.O_PAR)) {
						calcBuf ~= tok.value;
					} else {
						if (i > 0) calcBuf ~= " ";
						calcBuf ~= tok.value;
					}
				}
				return assumeUnique(calcBuf);
			}
			string buf = "";
			if (!array.length) return buf;

			foreach (node; array) {
				if (buf.length) {
					buf ~= "\n";
				}
				if (node.type is NodeType.COMMAND && node.texts.length) {
					buf ~= .format("%s%s %s\n", ifString == "sif" ? indentValue : bIndentValue, ifString, calcCode(node.texts));
					ifString = "sif";
				}
				if (node.type is NodeType.VAR_SET) {
					enforce(node.value.length > 0, new Exception("Invalid node", __FILE__, __LINE__));
					if (node.value[0].token.kind is Kind.STRING) {
						buf ~= .format("%s%s = %s", indentValue, node.token.value, node.value[0].token.value);
					} else {
						buf ~= .format("%s%s = %s", node.token.value, indentValue, calcCode(node.value));
					}
					continue;
				} else if (node.type is NodeType.VALUE) {
					if (node.var.length <= 1) {
						buf ~= node.token.value;
					} else {
						buf ~= calcCode([node]);
					}
					continue;
				} else if (node.type is NodeType.VALUES) {
					string vals = "[";
					foreach (i, c; node.values) {
						if (i > 0) vals ~= ", ";
						vals ~= Node.code(indent, [c]);
					}
					vals ~= "]";
					buf ~= vals;
					continue;
				}
				foreach (i, var; node.beforeVars) {
					buf ~= .format("%s%s\n", indentValue, Node.code(indent, [var]));
				}
				string attrs = "";
				if (node.token.kind is Kind.START) {
					attrs = " " ~ calcCode(node.texts);
				} else {
					foreach (i, a; node.attr) {
						auto ac = Node.code(indent, [a]);
						if (a.type is NodeType.VALUES && i > 0) {
							attrs ~= "\n";
							attrs ~= indentValue;
							attrs ~= .rightJustify("", node.token.value.length + 1);
							attrs ~= ac;
						} else {
							attrs ~= i == 0 ? " " : ", ";
							attrs ~= ac;
						}
					}
				}
				buf ~= .format("%s%s%s", indentValue, node.token.value, attrs);

				if (node.nextIsChild) continue;

				bool startBlock = true;
				bool nextIsStartPoint = true;
				const(Node)[][] block;
				foreach (i, c; node.childs) {
					if (startBlock && nextIsStartPoint) {
						block ~= new const(Node)[0];
					}
					startBlock = false;
					if (c.type !is NodeType.VAR_SET) {
						nextIsStartPoint = !c.nextIsChild;
						startBlock = true;
					}
					block[$ - 1] ~= c;
				}
				if (block.length > 1) {
					foreach (i, b; block) {
						string f = i == 0 ? "if" : "elif";
						buf ~= "\n";
						buf ~= Node.code(indent, indentValue, indentValue ~ indent, b, f);
					}
					buf ~= "\n";
					buf ~= indentValue ~ "fi";
				} else if (block.length == 1) {
					buf ~= "\n";
					buf ~= Node.code(indent, indentValue, node.token.kind is Kind.START ? indentValue ~ indent : indentValue, block[0], "sif");
				}
			}
			return buf;
		}
	}

	/// 属性値を文字列にして返す。
	private string attrValue(in Node node, in const(Node)[][string] varTable, size_t strWidth) {
		switch (node.token.kind) {
		case Kind.SYMBOL: return std.string.toLower(node.token.value);
		case Kind.VAR_NAME:
			if (1 < node.calc.length) goto case Kind.STRING;
			auto nodes = var(node, varTable);
			if (!nodes.length) return "";
			auto tok = nodes[0].token;
			if (tok.kind is Kind.STRING) {
				return stringValue(tok, strWidth);
			} else if (tok.kind is Kind.SYMBOL) {
				return std.string.toLower(tok.value);
			}
			return attrValue(nodes[0], varTable, strWidth);
		case Kind.STRING, Kind.NUMBER, Kind.PLU, Kind.MIN, Kind.O_PAR:
			size_t i = 0;
			auto r = calc(node.calc, i, varTable, strWidth);
			final switch (r.kind) {
			case CRKind.STR: return r.str;
			case CRKind.INT: return to!(string)(r.numInt);
			case CRKind.REAL: return to!(string)(r.numReal);
			}
		case Kind.O_BRA: return "";
		case Kind.COMMA: return "";
		default:
			throwError(_prop.msgs.scriptErrorInvalidAttr, node.token);
			return "";
		}
		assert (0);
	}
	/// 変数値を返す。
	private const(Node)[] varValue(in Node node, const(Node)[] values, in const(Node)[][string] varTable, size_t strWidth) {
		if (!values.length) {
			throwError(_prop.msgs.scriptErrorInvalidVar, node.token);
			return values;
		}
		const(Node)[] r;
		foreach (v; values) {
			const(Node)[] vs;
			if (v.token.kind is Kind.VAR_NAME) {
				vs ~= var(v, varTable);
			} else {
				vs = [v];
			}
			foreach (v2; vs) {
				switch (v2.token.kind) {
				case Kind.STRING, Kind.NUMBER, Kind.PLU, Kind.MIN, Kind.O_PAR:
					// 値。計算もここで行う
					size_t i = 0;
					Node rNode = v2.dup;
					auto cr = calc(v2.calc, i, varTable, strWidth);
					rNode.token.kind = cr.kind is CRKind.STR ? Kind.STRING : Kind.NUMBER;
					final switch (cr.kind) {
					case CRKind.STR:
						rNode.token.value = createString(cr.str);
						break;
					case CRKind.INT:
						rNode.token.value = to!(string)(cr.numInt);
						break;
					case CRKind.REAL:
						rNode.token.value = to!(string)(cr.numReal);
						break;
					}
					r ~= rNode;
					break;
				default:
					r ~= v2;
					break;
				}
			}
		}
		return r;
	}
	private const(Node)[] var(in Node[] nodes, in const(Node)[][string] varTable) {
		const(Node)[] r;
		foreach (node; nodes) {
			r ~= var(node, varTable);
		}
		return r;
	}
	private const(Node)[] var(in Node node, in const(Node)[][string] varTable) {
		if (node.token.kind is Kind.VAR_NAME) {
			auto ptr = std.string.toLower(node.token.value) in varTable;
			if (ptr) {
				const(Node)[] r;
				foreach (v; *ptr) {
					r ~= var(v, varTable);
				}
				return r;
			}
			throwError(_prop.msgs.scriptErrorUndefinedVar, node.token);
			return [];
		}
		return [node];
	}
	private Token var(in Token tok, in const(Node)[][string] varTable) {
		if (tok.kind is Kind.VAR_NAME) {
			auto ptr = std.string.toLower(tok.value) in varTable;
			if (ptr && ptr.length) return var((*ptr)[0].token, varTable);
			throwError(_prop.msgs.scriptErrorUndefinedVar, tok);
		}
		return tok;
	}

	/// tokensを解釈し、Nodeのツリーに再編成する。
	Node[] analyzeSyntax(in Token[] tokens) {
		Node[] r;
		size_t i = 0;
		Node[] vars;
		const(Token)[] tokens2;
		foreach (ref tok; tokens) {
			if (tok.kind !is Kind.COMMENT) {
				tokens2 ~= tok;
			}
		}
		while (i < tokens2.length) {
			vars ~= eatVarSet(tokens2, i, KEYS);
			if (tokens2.length <= i) {
				break;
			}
			Token tok = tokens2[i];
			if (tok.kind !is Kind.START) {
				r ~= analyzeSyntaxBranch(tokens2, i, KEYS, vars);
				continue;
			}
			i++;
			Node node;
			node.type = NodeType.START;
			node.token = tok;
			node.texts = analyzeSyntaxAttr(tokens2, i, KEYS);
			if (!node.texts.length) {
				throwError(_prop.msgs.scriptErrorNoStartText, tok);
			}
			node.beforeVars = vars;
			vars = [];
			node.nextIsChild = false;
			c: while (i < tokens2.length) {
				vars ~= eatVarSet(tokens2, i, KEYS);
				string cText = "";
				switch (tokens2[i].kind) {
				case Kind.START, Kind.FI: break c;
				case Kind.IF, Kind.ELIF, Kind.SYMBOL, Kind.SIF:
					node.childs ~= analyzeSyntaxBranch(tokens2, i, KEYS, vars);
					continue;
				default:
					throwError(_prop.msgs.scriptErrorInvalidStatement, tokens2[i]);
					i++;
				}
			}
			r ~= node;
		}
		return r;
	} unittest {
		debug mixin(UTPerf);
		auto s = new CWXScript(new CProps("", null), null);
		string statement
= `
$var1 = 'oops'
Start "First start"
if 'abc'
    chback ['mapofwirth.bmp', '',  0, 0, 632, 420]
           ['definn.bmp', '', 50, 50, 200*2, 260]
           ['card.bmp', 'card\mate1', 230, 50, 74, 94, mask],
           1
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
        $var_dummy = nothing
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
		assert (Node.code("    ", starts)
			== "$var1 = 'oops'\n"
			~ "Start \"First start\"\n"
			~ "if 'abc'\n"
			~ "    chback ['mapofwirth.bmp', '', 0, 0, 632, 420]\n"
			~ "           ['definn.bmp', '', 50, 50, 200 * 2, 260]\n"
			~ "           ['card.bmp', 'card\\mate1', 230, 50, 74, 94, mask], 1\n"
			~ "    hideparty\n"
			~ "    $var2 = 3.5\n"
			~ "    wait ($var2 + 1.5)\n"
			~ "    msg M, @ 3\n"
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
			~ "        $var_dummy = nothing\n" /* 文法構造上、宣言箇所はここへ移動 */
			~ "        gameover\n"
			~ "    fi\n"
			~ "elif 'def'\n"
			~ "    effect 1, 2, 3 + 2\n"
			~ "fi\n"
			~ "$var4 = true\n"
			~ "start \"second start\"\n"
			~ "    showparty\n"
			~ "    getskill 1", Node.code("    ", starts));

		string statement2
= `
brflag 'card\mate1'
if true
    $var3 = 'what?'
    showparty
    endsc true
    $var_dummy = nothing
elif false
    gameover    // comment1
fi`;
		auto tokens2 = s.tokenize(statement2);
		auto contents = s.analyzeSyntax(tokens2);
		assert (Node.code("    ", contents)
			== "brflag 'card\\mate1'\n"
			~ "if true\n"
			~ "    $var3 = 'what?'\n"
			~ "    showparty\n"
			~ "    endsc true\n"
			~ "elif false\n"
			~ "    $var_dummy = nothing\n"
			~ "    gameover\n"
			~ "fi");

		// 無限ループに陥るバグの修正テスト
		s.analyzeSyntax(s.tokenize("dialog M, @c\n...\n@]"));

		string statement3 = `chback [] goarea 1`;
		auto tokens3 = s.tokenize(statement3);
		auto contents2 = s.analyzeSyntax(tokens3);
		assert (contents2.length == 2);
		assert (contents2[0].nextIsChild);
		assert (!contents2[1].nextIsChild);
	}

	private Node[] analyzeSyntaxBranch(in Token[] tokens, ref size_t i, in Keywords keys, ref Node[] vars) {
		Node[] r;
		auto tok = tokens[i];
		switch (tok.kind) {
		case Kind.START: return r;
		case Kind.IF, Kind.VAR_NAME:
			while (i < tokens.length) {
				Node[] texts;
				if (tokens[i].kind is Kind.IF || tokens[i].kind is Kind.ELIF) {
					i++;
					texts = analyzeSyntaxAttr(tokens, i, keys);
					if (!texts.length) {
						throwError(_prop.msgs.scriptErrorNoIfText, tok);
					}
					if (tokens.length <= i) {
						throwError(_prop.msgs.scriptErrorNoIfContents, tok);
					}
				}
				auto node = analyzeSyntaxStatement(tokens, i, keys, vars);
				if (node.length) {
					node[0].texts = texts;
				}
				r ~= node;
				if (tokens.length <= i) return r;
				switch (tokens[i].kind) {
				case Kind.START: return r;
				case Kind.FI:
					i++;
					return r;
				case Kind.ELIF: continue;
				case Kind.VAR_NAME: continue;
				default:
					throwError(_prop.msgs.scriptErrorInvalidStatement, tokens[i]);
					i++;
				}
			}
			break;
		case Kind.SYMBOL, Kind.SIF:
			r ~= analyzeSyntaxStatement(tokens, i, keys, vars);
			break;
		default:
			throwError(_prop.msgs.scriptErrorInvalidBranch, tok);
			i++;
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
	private Node[] analyzeSyntaxStatement(in Token[] tokens, ref size_t i, in Keywords keys, ref Node[] vars) {
		Node[] r;
		while (true) {
			assert (i < tokens.length);
			vars ~= eatVarSet(tokens, i, keys);
			Token tok = tokens[i];
			Node[] sifTexts;
			if (tok.kind is Kind.SIF) {
				i++;
				if (tokens.length <= i) {
					throwError(_prop.msgs.scriptErrorNoSifText, tok);
					return r;
				}
				sifTexts = analyzeSyntaxAttr(tokens, i, keys);
				if (tokens.length <= i) {
					throwError(_prop.msgs.scriptErrorInvalidSif, tok);
				}
				tok = tokens[i];
			} else if (tok.kind !is Kind.SYMBOL) {
				throwError(_prop.msgs.scriptErrorInvalidStatement, tok);
			}
			Node node;
			node.type = NodeType.COMMAND;
			node.token = tok;
			node.texts = sifTexts;
			node.nextIsChild = false;
			auto symbol = std.string.toLower(tok.value);
			if (!(symbol in keys.keywords)) {
				throwError(_prop.msgs.scriptErrorInvalidKeyword, tok);
			}
			node.beforeVars = vars;
			vars = [];
			i++;
			if (tokens.length <= i) return r ~ node;
			node.attr = analyzeSyntaxAttr(tokens, i, keys);
			vars ~= eatVarSet(tokens, i, keys);
			if (tokens.length <= i) return r ~ node;
			switch (tokens[i].kind) {
			case Kind.START, Kind.ELIF, Kind.FI:
				return r ~ node;
			case Kind.IF:
				node.childs ~= analyzeSyntaxBranch(tokens, i, keys, vars);
				return r ~ node;
			case Kind.SIF, Kind.SYMBOL:
				node.nextIsChild = true;
				r ~= node;
				continue;
			default:
				throwError(_prop.msgs.scriptErrorInvalidStatement, tok);
				return r ~ node;
			}
		}
		return r;
	}
	private Node[] analyzeSyntaxAttr(in Token[] tokens, ref size_t i, in Keywords keys) {
		Node[] r;
		while (i < tokens.length) {
			Token tok = tokens[i];
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
				if (std.string.toLower(tok.value) in keys.keywords) return r;
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
			case Kind.COMMA:
				// いきなり','が現れた場合は長さ0の配列とする
				Node node;
				node.type = NodeType.VALUES;
				node.token = tok;
				node.var = [];
				r ~= node;
				break;
			default:
				throwError(_prop.msgs.scriptErrorInvalidAttr, tok);
				i++;
			}
		}
		return r;
	} unittest {
		debug mixin(UTPerf);
		auto s = new CWXScript(new CProps("", null), null);
		Token[] tokens;
		size_t i;
		tokens = s.tokenize(`goarea`);
		i = 0;
		assert (s.analyzeSyntaxAttr(tokens, i, KEYS).length == 0);
		tokens = s.tokenize(`area, 1, "="if "next"`);
		i = 0;
		auto arr = [
			Node(NodeType.VALUE, Token(0, 0, 0, Kind.SYMBOL, "area")),
			Node(NodeType.VALUE, Token(0, 6, 6, Kind.NUMBER, "1")),
			Node(NodeType.VALUE, Token(0, 9, 9, Kind.STRING, `"="`))
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
			Token tok = tokens[i];
			if (tok.kind is Kind.C_BRA) {
				return r;
			}
			if (r.values.length > 0) {
				if (tok.kind is Kind.COMMA) {
					i++;
				}
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
				i++;
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
		node.value = analyzeSyntaxAttr(tokens, i, keys);
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
				if (num) return r;
				r ~= tok;
				i++;
				break;
			case Kind.MUL, Kind.DIV, Kind.RES, Kind.CAT:
				if (num) return r;
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
				i++;
			}
		}
		return r;
	}

	private T parseAttr(T, bool Within = false)(in CompileOption opt, in Node[] attr, ref size_t i, lazy T defValue, in const(Node)[][string] varTable, size_t msgWidth) {
		if (attr.length <= i) return defValue;
		static if (is(T == string)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			if (attr[i].token.kind is Kind.SYMBOL && value == "stop") {
				/// BGM停止用
				i++;
				return "";
			} else if (attr[i].token.kind is Kind.SYMBOL && value == "random") {
				/// ステップ・フラグ代入のランダム値
				i++;
				return _prop.sys.randomValue;
			}
			i++;
			return value;
		} else static if (is(T == CastRange[])) {
			T r;
			crw: while (i < attr.length) {
				auto value = attrValue(attr[i], varTable, msgWidth);
				switch (value) {
				case "field": r ~= [CastRange.PARTY, CastRange.ENEMY, CastRange.NPC]; break;
				case "party", "t", "team": r ~= CastRange.PARTY; break;
				case "enemy": r ~= CastRange.ENEMY; break;
				case "npc": r ~= CastRange.NPC; break;
				default: break crw;
				}
				i++;
			}
			r = r.sort().uniq().array();
			return r;
		} else static if (isVArray!(T)) {
			T r;
			while (i < attr.length) {
				auto values = var(attr[i], varTable);
				size_t i2 = 0;
				if (values.length <= i2 || values[0].type !is NodeType.VALUES) break;
				while (i2 < values.length) {
					if (!values.length) break;
					if (values[0].token.kind is Kind.COMMA) {
						// 空の配列
						break;
					}
					r ~= parseAttr!(typeof(T[0]), Within)(opt, values, i2, typeof(T[0]).init, varTable, msgWidth);
					if (0 == i2) break;
				}
				i++;
			}
			return r;
		} else static if (is(T == bool)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "true", "yes", "on", "all", "random", "average", "complete":
				i++;
				return true;
			case "false", "no", "off", "active", "manual", "max", "nocomplete":
				i++;
				return false;
			default: throwError(_prop.msgs.scriptErrorInvalidBoolVal, attr[i].token);
			}
		} else static if (is(T == Transition)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "default": i++; return Transition.DEFAULT;
			case "none": i++; return Transition.NONE;
			case "fade": i++; return Transition.FADE;
			case "dissolve": i++; return Transition.PIXEL_DISSOLVE;
			case "blinds": i++; return Transition.BLINDS;
			default: throwError(_prop.msgs.scriptErrorInvalidTransition, attr[i].token);
			}
		} else static if (is(T == Range)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
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
			default: throwError(_prop.msgs.scriptErrorInvalidRange, attr[i].token);
			}
		} else static if (is(T == Status)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
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
			case "confuse": i++; return Status.CONFUSE;
			case "overheat": i++; return Status.OVERHEAT;
			case "brave": i++; return Status.BRAVE;
			case "panic": i++; return Status.PANIC;
			case "silence": i++; return Status.SILENCE;
			case "faceup": i++; return Status.FACE_UP;
			case "antimagic": i++; return Status.ANTI_MAGIC;
			case "upaction": i++; return Status.UP_ACTION;
			case "upavoid": i++; return Status.UP_AVOID;
			case "upresist": i++; return Status.UP_RESIST;
			case "updefense": i++; return Status.UP_DEFENSE;
			case "downaction": i++; return Status.DOWN_ACTION;
			case "downavoid": i++; return Status.DOWN_AVOID;
			case "downresist": i++; return Status.DOWN_RESIST;
			case "downdefense": i++; return Status.DOWN_DEFENSE;
			case "none": i++; return Status.NONE;
			default: throwError(_prop.msgs.scriptErrorInvalidStatus, attr[i].token);
			}
		} else static if (is(T == Target)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			bool sleep = false;
			static if (!Within) {
				// 睡眠者対象
				size_t j = i + 1;
				sleep = parseAttr!(bool)(opt, attr, j, false, varTable, msgWidth);
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
			default: throwError(_prop.msgs.scriptErrorInvalidTarget, attr[i].token);
			}
		} else static if (is(T == EffectType)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "physic": i++; return EffectType.PHYSIC;
			case "magic": i++; return EffectType.MAGIC;
			case "mphysic": i++; return EffectType.MAGICAL_PHYSIC;
			case "pmagic": i++; return EffectType.PHYSICAL_MAGIC;
			case "none": i++; return EffectType.NONE;
			default: throwError(_prop.msgs.scriptErrorInvalidEffectType, attr[i].token);
			}
		} else static if (is(T == Resist)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "avoid": i++; return Resist.AVOID;
			case "resist": i++; return Resist.RESIST;
			case "unfail": i++; return Resist.UNFAIL;
			default: throwError(_prop.msgs.scriptErrorInvalidResist, attr[i].token);
			}
		} else static if (is(T == CardVisual)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "none": i++; return CardVisual.NONE;
			case "reverse": i++; return CardVisual.REVERSE;
			case "hswing": i++; return CardVisual.HORIZONTAL;
			case "vswing": i++; return CardVisual.VERTICAL;
			default: throwError(_prop.msgs.scriptErrorInvalidCardVisual, attr[i].token);
			}
		} else static if (is(T == Mental)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
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
			default: throwError(_prop.msgs.scriptErrorInvalidMental, attr[i].token);
			}
		} else static if (is(T == Physical)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "dex": i++; return Physical.DEX;
			case "agl": i++; return Physical.AGL;
			case "int": i++; return Physical.INT;
			case "str": i++; return Physical.STR;
			case "vit": i++; return Physical.VIT;
			case "min": i++; return Physical.MIN;
			default: throwError(_prop.msgs.scriptErrorInvalidPhysical, attr[i].token);
			}
		} else static if (is(T == Talker)) {
			return parseTalker!(Within)(attr, i, varTable);
		} else static if (is(T == MType)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
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
			case "resetmind": i++; return MType.NORMAL;
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
			case "cancelaction": i++; return MType.CANCEL_ACTION;
			default: throwError(_prop.msgs.scriptErrorInvalidMotionType, attr[i].token);
			}
		} else static if (is(T == Element)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "all": i++; return Element.ALL;
			case "phy": i++; return Element.HEALTH;
			case "mind": i++; return Element.MIND;
			case "holy": i++; return Element.MIRACLE;
			case "magic": i++; return Element.MAGIC;
			case "fire": i++; return Element.FIRE;
			case "ice": i++; return Element.ICE;
			default: throwError(_prop.msgs.scriptErrorInvalidElement, attr[i].token);
			}
		} else static if (is(T == DamageType)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "level": i++; return DamageType.LEVEL_RATIO;
			case "value": i++; return DamageType.NORMAL;
			case "max": i++; return DamageType.MAX;
			default: throwError(_prop.msgs.scriptErrorInvalidDamageType, attr[i].token);
			}
		} else static if (is(T == EffectCardType)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "all": i++; return EffectCardType.ALL;
			case "skill": i++; return EffectCardType.SKILL;
			case "item": i++; return EffectCardType.ITEM;
			case "beast": i++; return EffectCardType.BEAST;
			default: throwError(_prop.msgs.scriptErrorInvalidEffectCardType, attr[i].token);
			}
		} else static if (is(T == Comparison4)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "=": i++; return Comparison4.Eq;
			case "<>", "!=": i++; return Comparison4.Ne;
			case ">": i++; return Comparison4.Lt;
			case "<": i++; return Comparison4.Gt;
			default: throwError(_prop.msgs.scriptErrorInvalidComparison4, attr[i].token);
			}
		} else static if (is(T == Comparison3)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "=": i++; return Comparison3.Eq;
			case ">": i++; return Comparison3.Lt;
			case "<": i++; return Comparison3.Gt;
			default: throwError(_prop.msgs.scriptErrorInvalidComparison3, attr[i].token);
			}
		} else static if (is(T == BlendMode)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "normal": i++; return BlendMode.Normal;
			case "add": i++; return BlendMode.Add;
			case "sub": i++; return BlendMode.Subtract;
			case "mul": i++; return BlendMode.Multiply;
			default: throwError(_prop.msgs.scriptErrorInvalidBlendMode, attr[i].token);
			}
		} else static if (is(T == GradientDir)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "none": i++; return GradientDir.None;
			case "h", "horizontal": i++; return GradientDir.LeftToRight;
			case "v", "vertical": i++; return GradientDir.TopToBottom;
			default: throwError(_prop.msgs.scriptErrorInvalidGradientDir, attr[i].token);
			}
		} else static if (is(T == CRGB)) {
			if (attr[i].type is NodeType.VALUES) {
				auto vals = attr[i].values;
				size_t j = 0;
				int r = parseAttr!(int)(opt, vals, j, defValue.r, varTable, msgWidth);
				int g = parseAttr!(int)(opt, vals, j, defValue.g, varTable, msgWidth);
				int b = parseAttr!(int)(opt, vals, j, defValue.b, varTable, msgWidth);
				int a = parseAttr!(int)(opt, vals, j, defValue.a, varTable, msgWidth);
				i++;
				return CRGB(r, g, b, a);
			} else {
				string value = parseAttr!(string)(opt, attr, i, "#000000", varTable, msgWidth);
				value = value.toLower();
				if (value.startsWith("#") && (7 == value.length || 9 == value.length)) {
					foreach (c; value[1..$]) {
						if (!(('0' <= c && c <= '9') || ('a' <= c && c <= 'f'))) {
							throwError(_prop.msgs.scriptErrorInvalidColor, attr[i].token);
							return defValue;
						}
					}
					int r = parse!int(value[1..3], 16);
					int g = parse!int(value[3..5], 16);
					int b = parse!int(value[5..7], 16);
					int a = 255;
					if (9 == value.length) {
						a = parse!int(value[7..9], 16);
					}
					return CRGB(r, g, b, a);
				} else {
					throwError(_prop.msgs.scriptErrorInvalidColor, attr[i].token);
					return defValue;
				}
			}
		} else static if (is(T == BgImage)) {
			if (attr[i].type !is NodeType.VALUES) {
				throwError(_prop.msgs.scriptErrorInvalidBgImage, attr[i].token);
				return defValue;
			}
			auto vals = attr[i].values.dup;
			string type = "image";
			if (vals && vals[0].token.kind is Kind.SYMBOL) {
				type = attrValue(vals[0], varTable, msgWidth);
				vals = vals[1..$];
			}
			BgImage r;
			size_t j = 0;
			switch (type) {
			case "image":
				string path = decodePath(parseAttr!(string)(opt, vals, j, "", varTable, msgWidth));
				string flag = parseAttr!(string)(opt, vals, j, "", varTable, msgWidth);
				int x = parseAttr!(int)(opt, vals, j, 0, varTable, msgWidth);
				int y = parseAttr!(int)(opt, vals, j, 0, varTable, msgWidth);
				auto size = _prop.looks.viewSize;
				int w = parseAttr!(int)(opt, vals, j, cast(int) size.width, varTable, msgWidth);
				int h = parseAttr!(int)(opt, vals, j, cast(int) size.height, varTable, msgWidth);
				bool mask = parseAttr!(bool)(opt, vals, j, false, varTable, msgWidth);
				r = new ImageCell(path, flag, x, y, w, h, mask);
				break;
			case "text":
				string text = parseAttr!(string)(opt, vals, j, "", varTable, msgWidth);
				string fontName = parseAttr!(string)(opt, vals, j, "", varTable, msgWidth);
				int size = parseAttr!(int)(opt, vals, j, 18, varTable, msgWidth);
				CRGB color = parseAttr!(CRGB)(opt, vals, j, CRGB(0, 0, 0, 255), varTable, msgWidth);
				bool bold = false, italic = false, underline = false, strike = false, vertical = false;
				BorderingType borderingType = BorderingType.None;
				bgtw: while (j < vals.length) {
					if (vals[j].token.kind !is Kind.SYMBOL) break;
					switch (attrValue(vals[j], varTable, msgWidth)) {
					case "bold": j++; bold = true; break;
					case "italic": j++; italic = true; break;
					case "underline", "uline": j++; underline = true; break;
					case "strike": j++; strike = true; break;
					case "vertical": j++; vertical = true; break;
					case "border1": j++; borderingType = BorderingType.Outline; break;
					case "border2": j++; borderingType = BorderingType.Inline; break;
					default: break bgtw;
					}
				}
				CRGB borderingColor = CRGB(255, 255, 255, 255);
				int borderingWidth = 1;
				final switch (borderingType) {
				case BorderingType.None: break;
				case BorderingType.Outline:
					borderingColor = parseAttr!(CRGB)(opt, vals, j, borderingColor, varTable, msgWidth);
					break;
				case BorderingType.Inline:
					borderingColor = parseAttr!(CRGB)(opt, vals, j, borderingColor, varTable, msgWidth);
					borderingWidth = parseAttr!(int)(opt, vals, j, borderingWidth, varTable, msgWidth);
					break;
				}
				string flag = parseAttr!(string)(opt, vals, j, "", varTable, msgWidth);
				int x = parseAttr!(int)(opt, vals, j, 0, varTable, msgWidth);
				int y = parseAttr!(int)(opt, vals, j, 0, varTable, msgWidth);
				int w = parseAttr!(int)(opt, vals, j, cast(int) _prop.looks.viewSize.width, varTable, msgWidth);
				int h = parseAttr!(int)(opt, vals, j, cast(int) _prop.looks.viewSize.height, varTable, msgWidth);
				r = new TextCell(text, fontName, size, color, bold, italic, underline, strike, vertical,
					borderingType, borderingColor, borderingWidth, flag, x, y, w, h, false);
				break;
			case "color":
				BlendMode blendMode = parseAttr!(BlendMode)(opt, vals, j, BlendMode.Normal, varTable, msgWidth);
				CRGB color1 = parseAttr!(CRGB)(opt, vals, j, CRGB(255, 255, 255, 255), varTable, msgWidth);
				GradientDir gradientDir = GradientDir.None;
				CRGB color2 = CRGB(0, 0, 0, 255);
				if (j < vals.length && vals[j].token.kind is Kind.SYMBOL) {
					gradientDir = parseAttr!(GradientDir)(opt, vals, j, gradientDir, varTable, msgWidth);
					color2 = parseAttr!(CRGB)(opt, vals, j, color2, varTable, msgWidth);
				}
				string flag = parseAttr!(string)(opt, vals, j, "", varTable, msgWidth);
				int x = parseAttr!(int)(opt, vals, j, 0, varTable, msgWidth);
				int y = parseAttr!(int)(opt, vals, j, 0, varTable, msgWidth);
				auto size = _prop.looks.viewSize;
				int w = parseAttr!(int)(opt, vals, j, cast(int) size.width, varTable, msgWidth);
				int h = parseAttr!(int)(opt, vals, j, cast(int) size.height, varTable, msgWidth);
				r = new ColorCell(blendMode, gradientDir, color1, color2, flag, x, y, w, h, false);
				break;
			default:
				throwError(_prop.msgs.scriptErrorInvalidBgImage, attr[i].token);
				return defValue;
			}
			i++;
			return r;
		} else static if (is(T == Motion)) {
			if (attr[i].type !is NodeType.VALUES) {
				throwError(_prop.msgs.scriptErrorInvalidMotion, attr[i].token);
			}
			size_t j = 0;
			auto vals = attr[i].values;
			MType type = parseAttr!(MType)(opt, vals, j, MType.HEAL, varTable, msgWidth);
			auto r = new Motion(type, Element.ALL);
			auto detail = r.detail;
			if (detail.use(MArg.VALUE_TYPE)) {
				r.damageType = parseAttr!(DamageType)(opt, vals, j, r.damageType, varTable, msgWidth);
			}
			if (detail.use(MArg.U_VALUE)) {
				r.uValue = parseAttr!(int)(opt, vals, j, cast(int) r.uValue, varTable, msgWidth);
			}
			if (detail.use(MArg.A_VALUE)) {
				r.aValue = parseAttr!(int)(opt, vals, j, r.aValue, varTable, msgWidth);
			}
			if (detail.use(MArg.ROUND)) {
				r.round = parseAttr!(int)(opt, vals, j, r.round, varTable, msgWidth);
			}
			if (detail.use(MArg.BEAST)) {
				ulong beast = parseAttr!(ulong)(opt, vals, j, 0UL, varTable, msgWidth);
				if (beast != 0 && _summ) {
					if (opt.linkId) {
						r.beast = new BeastCard(1UL, "", "", "");
						r.beast.linkId = beast;
					} else {
						r.beast = _summ.beast(beast);
					}
				}
			}
			r.element = parseAttr!(Element)(opt, vals, j, Element.ALL, varTable, msgWidth);
			i++;
			return r;
		} else static if (is(T == SDialog)) {
			if (attr[i].type !is NodeType.VALUES) {
				throwError(_prop.msgs.scriptErrorInvalidDialog, attr[i].token);
			}
			size_t j = 0;
			auto vals = attr[i].values;
			auto r = new SDialog;
			if (vals.length > 2) {
				// 複数の条件クーポン
				string[] cs;
				foreach (v; vals[0 .. $ - 1]) {
					cs ~= parseAttr!(string)(opt, vals, j, "", varTable, msgWidth);
				}
				r.rCoupons = cs;
			} else if (vals.length > 1) {
				// 一つの条件クーポン
				if (vals[j].type is NodeType.VALUES) {
					// 互換性のため、複合パラメータを解釈する
					string[] cs;
					foreach (v; vals[j].values) {
						cs ~= attrValue(v, varTable, 0);
					}
					r.rCoupons = cs;
					j++;
				} else {
					// ';'で分割されるパターン
					r.rCoupons = std.string.split(parseAttr!(string)(opt, vals, j, "", varTable, msgWidth), ";");
				}
			}
			r.text = parseAttr!(string)(opt, vals, j, r.text, varTable, msgWidth);
			i++;
			return r;
		} else static if (is(T == Coupon)) {
			if (attr[i].type !is NodeType.VALUES) {
				string name = attrValue(attr[i], varTable, msgWidth);
				i++;
				return new Coupon(name, 1);
			}
			size_t j = 0;
			auto vals = attr[i].values;
			string name = parseAttr!(string)(opt, vals, j, "", varTable, msgWidth);
			int value = parseAttr!(int)(opt, vals, j, 0, varTable, msgWidth);
			auto r = new Coupon(name, value);
			i++;
			return r;
		} else static if (is(T == int)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			if (attr[i].token.kind is Kind.SYMBOL && value == "all") {
				return 0; // カード削除用
			}
			try {
				auto r = to!(int)(value);
				i++;
				return r;
			} catch (Exception e) {
				throwError(_prop.msgs.scriptErrorReqNumber, attr[i].token);
			}
		} else static if (is(T == ulong)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			try {
				auto r = to!(ulong)(value);
				i++;
				return r;
			} catch (Exception e) {
				throwError(_prop.msgs.scriptErrorReqID, attr[i].token);
			}
		} else static assert (0, T.stringof);
		return T.init;
	}
	private void parseAttrTalker(in Node[] attr, ref size_t i, ref Talker t, ref string cardPath, in const(Node)[][string] varTable) {
		if (attr.length <= i) return;
		auto nodes = var(attr[i], varTable);
		auto value = attrValue(attr[i], varTable, 0);
		if (nodes.length && nodes[0].token.kind is Kind.STRING) {
			t = Talker.IMAGE;
			cardPath = value;
			i++;
			return;
		}
		cardPath = "";
		t = parseTalker!(false)(attr, i, varTable);
	}
	private Talker parseTalker(bool Within)(in Node[] attr, ref size_t i, in const(Node)[][string] varTable) {
		auto node = attr[i];
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
		case "v", "valued": i++; return Talker.VALUED;
		default:
			throwError(_prop.msgs.scriptErrorInvalidTalker, node.token);
			i++;
		}
		return Talker.NARRATION;
	}
	private string parseNextValue(in Node node, in Keywords keys, in const(Node)[][string] varTable) {
		if (!node.texts.length) return "";
		auto nodes = varValue(node, node.texts, varTable, 0);
		if (!nodes.length) return "";
		auto value = nodes[0].token;
		string r;
		if (value.kind is Kind.SYMBOL) {
			auto valStr = std.string.toLower(value.value);
			if (valStr in keys.keywords) {
				throwError(_prop.msgs.scriptErrorUndefinedSymbol, node.token);
			}
			switch (valStr) {
			case "default":
				r = _prop.sys.evtChildDefault;
				break;
			case "select", "over", "true", "success", "yes", "has", "on":
				r = _prop.sys.evtChildTrue;
				break;
			case "cancel", "under", "false", "failure", "no", "hasnot", "off":
				r = _prop.sys.evtChildFalse;
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
	Content[] analyzeSemantics(in Node[] nodes, in CompileOption opt) {
		const(Node)[][string] varTable;
		size_t autoWrapCount = 0;
		string[] startNames;
		Content[] dummy;
		return analyzeSemanticsImpl(opt, nodes, KEYS, varTable, 0, autoWrapCount, startNames, dummy, true);
	}
	private Content[] analyzeSemanticsImpl(in CompileOption opt, in Node[] nodes, in Keywords keys, ref const(Node)[][string] varTable, size_t stack, ref size_t autoWrapCount, ref string[] startNames, ref Content[] topGroup, bool isTop) {
		Content[] r;
		auto commentReg = .regex(`^[\s|\*|\/]*(.*)[\s|\*|\/]*$`);
		string parseComment(string comment) {
			string r = "";
			foreach (i, line; splitLines!string(comment)) {
				auto m = .match(line, commentReg);
				if (!m.empty) {
					line = m.captures[1];
				}
				if (r.length || line.length) {
					r ~= line;
					r ~= "\n";
				}
			}
			return lastRet(r);
		}
		Content lastParent = null;
		bool nextIsChild = false;
		foreach (node; nodes) {
			foreach (var; node.beforeVars) {
				if (var.type !is NodeType.VAR_SET) {
					throwError(_prop.msgs.scriptErrorInvalidVar, var.token);
				}
				if (var.value.length) {
					varTable[std.string.toLower(var.token.value)] = this.var(var.value, varTable);
				} else {
					throwError(_prop.msgs.scriptErrorNoVarVal, var.token);
				}
			}
			if (node.type is NodeType.VAR_SET) {
				if (node.value.length) {
					varTable[std.string.toLower(node.token.value)] = var(node.value, varTable);
				} else {
					throwError(_prop.msgs.scriptErrorNoVarVal, node.token);
				}
				continue;
			}
			if (node.type !is NodeType.COMMAND && node.type !is NodeType.START) {
				throwError(_prop.msgs.scriptErrorInvalidCommand, node.token);
			}
			if (node.type is NodeType.START) {
				stack = 0;
			}
			string val = std.string.toLower(node.token.value);
			auto cmdPtr = val in KEYS.keywords;
			if (!cmdPtr) {
				throwError(_prop.msgs.scriptErrorInvalidCommand, node.token);
			}
			string comment = node.token.comment;
			auto c = new Content(*cmdPtr, parseNextValue(node, keys, varTable));
			if (node.type is NodeType.START) {
				c.name = createNewName(c.name, (string name) {
					foreach (sn; startNames) {
						if (0 == icmp(sn, name)) {
							return false;
						}
					}
					return true;
				});
				startNames ~= c.name;
			}
			c.comment = parseComment(comment);
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
				c.text = parseAttr!(string)(opt, node.attr, i, c.text, varTable,
					c.talkerC is Talker.NARRATION ? _prop.looks.messageLen : _prop.looks.messageImageLen);
			}
			if (detail.use(CArg.TALKER_NC)) {
				c.talkerNC = parseAttr!(Talker, true)(opt, node.attr, i, c.talkerNC, varTable, 0);
			}
			if (detail.use(CArg.DIALOGS)) {
				c.dialogs = parseAttr!(SDialog[])(opt, node.attr, i, c.dialogs, varTable, _prop.looks.messageImageLen);
				if (!c.dialogs.length) {
					c.dialogs = [new SDialog];
				}
			}
			if (detail.use(CArg.BG_IMAGES)) {
				c.backs = parseAttr!(BgImage[])(opt, node.attr, i, c.backs, varTable, 0);
			}
			if (detail.use(CArg.TARGET_NS)) {
				c.targetNS = parseAttr!(Target, true)(opt, node.attr, i, c.targetNS, varTable, 0);
			}
			if (detail.use(CArg.TARGET_S)) {
				c.targetS = parseAttr!(Target)(opt, node.attr, i, c.targetS, varTable, 0);
			}
			if (detail.use(CArg.RANGE)) {
				c.range = parseAttr!(Range)(opt, node.attr, i, c.range, varTable, 0);
			}
			if (detail.use(CArg.CAST_RANGE)) {
				c.castRange = parseAttr!(CastRange[])(opt, node.attr, i, c.castRange, varTable, 0);
			}
			if (detail.use(CArg.KEY_CODE_RANGE)) {
				c.keyCodeRange = parseAttr!(Range)(opt, node.attr, i, c.keyCodeRange, varTable, 0);
			}
			if (detail.use(CArg.EFFECT_CARD_TYPE)) {
				c.effectCardType = parseAttr!(EffectCardType)(opt, node.attr, i, c.effectCardType, varTable, 0);
			}
			if (detail.use(CArg.AREA)) {
				c.area = parseAttr!(ulong)(opt, node.attr, i, c.area, varTable, 0);
			}
			if (detail.use(CArg.BATTLE)) {
				c.battle = parseAttr!(ulong)(opt, node.attr, i, c.battle, varTable, 0);
			}
			if (detail.use(CArg.PACKAGE)) {
				c.packages = parseAttr!(ulong)(opt, node.attr, i, c.packages, varTable, 0);
			}
			if (detail.use(CArg.CAST)) {
				c.casts = parseAttr!(ulong)(opt, node.attr, i, c.casts, varTable, 0);
			}
			if (detail.use(CArg.ITEM)) {
				c.item = parseAttr!(ulong)(opt, node.attr, i, c.item, varTable, 0);
			}
			if (detail.use(CArg.SKILL)) {
				c.skill = parseAttr!(ulong)(opt, node.attr, i, c.skill, varTable, 0);
			}
			if (detail.use(CArg.INFO)) {
				c.info = parseAttr!(ulong)(opt, node.attr, i, c.info, varTable, 0);
			}
			if (detail.use(CArg.BEAST)) {
				c.beast = parseAttr!(ulong)(opt, node.attr, i, c.beast, varTable, 0);
			}
			if (detail.use(CArg.START)) {
				c.start = parseAttr!(string)(opt, node.attr, i, c.start, varTable, 0);
			}
			if (detail.use(CArg.COMPLETE)) {
				c.complete = parseAttr!(bool)(opt, node.attr, i, c.complete, varTable, 0);
			}
			if (detail.use(CArg.MONEY)) {
				c.money = parseAttr!(int)(opt, node.attr, i, c.money, varTable, 0);
			}
			if (detail.use(CArg.COUPON)) {
				c.coupon = parseAttr!(string)(opt, node.attr, i, c.coupon, varTable, 0);
			}
			if (detail.use(CArg.COUPON_VALUE)) {
				c.couponValue = parseAttr!(int)(opt, node.attr, i, c.couponValue, varTable, 0);
			}
			if (detail.use(CArg.COMPLETE_STAMP)) {
				c.completeStamp = parseAttr!(string)(opt, node.attr, i, c.completeStamp, varTable, 0);
			}
			if (detail.use(CArg.GOSSIP)) {
				c.gossip = parseAttr!(string)(opt, node.attr, i, c.gossip, varTable, 0);
			}
			if (detail.use(CArg.KEY_CODE)) {
				c.keyCode = parseAttr!(string)(opt, node.attr, i, c.keyCode, varTable, 0);
			}
			if (detail.use(CArg.FLAG)) {
				c.flag = parseAttr!(string)(opt, node.attr, i, c.flag, varTable, 0);
			}
			if (detail.use(CArg.FLAG_2)) {
				c.flag2 = parseAttr!(string)(opt, node.attr, i, c.flag2, varTable, 0);
			}
			if (detail.use(CArg.STEP)) {
				c.step = parseAttr!(string)(opt, node.attr, i, c.step, varTable, 0);
			}
			if (detail.use(CArg.STEP_2)) {
				c.step2 = parseAttr!(string)(opt, node.attr, i, c.step2, varTable, 0);
			}
			if (detail.use(CArg.COMPARISON_4)) {
				c.comparison4 = parseAttr!(Comparison4)(opt, node.attr, i, c.comparison4, varTable, 0);
			}
			if (detail.use(CArg.COMPARISON_3)) {
				c.comparison3 = parseAttr!(Comparison3)(opt, node.attr, i, c.comparison3, varTable, 0);
			}
			if (detail.use(CArg.FLAG_VALUE)) {
				c.flagValue = parseAttr!(bool)(opt, node.attr, i, c.flagValue, varTable, 0);
			}
			if (detail.use(CArg.STEP_VALUE)) {
				c.stepValue = parseAttr!(int)(opt, node.attr, i, c.stepValue, varTable, 0);
			}
			if (detail.use(CArg.CARD_NUMBER)) {
				c.cardNumber = parseAttr!(int)(opt, node.attr, i, c.cardNumber, varTable, 0);
			}
			if (detail.use(CArg.MOTIONS)) {
				c.motions = parseAttr!(Motion[])(opt, node.attr, i, c.motions, varTable, 0);
			}
			if (detail.use(CArg.CARD_VISUAL)) {
				c.cardVisual = parseAttr!(CardVisual)(opt, node.attr, i, c.cardVisual, varTable, 0);
			}
			if (detail.use(CArg.UNSIGNED_LEVEL)) {
				c.unsignedLevel = parseAttr!(int)(opt, node.attr, i, c.unsignedLevel, varTable, 0);
			}
			if (detail.use(CArg.SIGNED_LEVEL)) {
				c.signedLevel = parseAttr!(int)(opt, node.attr, i, c.signedLevel, varTable, 0);
			}
			if (detail.use(CArg.LEVEL_MIN)) {
				c.levelMin = parseAttr!(int)(opt, node.attr, i, c.levelMin, varTable, 0);
			}
			if (detail.use(CArg.LEVEL_MAX)) {
				c.levelMax = parseAttr!(int)(opt, node.attr, i, c.levelMax, varTable, 0);
			}
			if (detail.use(CArg.PHYSICAL)) {
				c.physical = parseAttr!(Physical)(opt, node.attr, i, c.physical, varTable, 0);
			}
			if (detail.use(CArg.MENTAL)) {
				c.mental = parseAttr!(Mental)(opt, node.attr, i, c.mental, varTable, 0);
			}
			if (detail.use(CArg.WAIT)) {
				c.wait = parseAttr!(int)(opt, node.attr, i, c.wait, varTable, 0);
			}
			if (detail.use(CArg.PERCENT)) {
				c.percent = parseAttr!(int)(opt, node.attr, i, c.percent, varTable, 0);
			}
			if (detail.use(CArg.TARGET_ALL)) {
				c.targetAll = parseAttr!(bool)(opt, node.attr, i, c.targetAll, varTable, 0);
			}
			if (detail.use(CArg.RANDOM)) {
				c.random = parseAttr!(bool)(opt, node.attr, i, c.random, varTable, 0);
			}
			if (detail.use(CArg.AVERAGE)) {
				c.average = parseAttr!(bool)(opt, node.attr, i, c.average, varTable, 0);
			}
			if (detail.use(CArg.PARTY_NUMBER)) {
				c.partyNumber = parseAttr!(int)(opt, node.attr, i, c.partyNumber, varTable, 0);
			}
			if (detail.use(CArg.SUCCESS_RATE)) {
				c.successRate = parseAttr!(int)(opt, node.attr, i, c.successRate, varTable, 0);
			}
			if (detail.use(CArg.EFFECT_TYPE)) {
				c.effectType = parseAttr!(EffectType)(opt, node.attr, i, c.effectType, varTable, 0);
			}
			if (detail.use(CArg.RESIST)) {
				c.resist = parseAttr!(Resist)(opt, node.attr, i, c.resist, varTable, 0);
			}
			if (detail.use(CArg.STATUS)) {
				c.status = parseAttr!(Status)(opt, node.attr, i, c.status, varTable, 0);
			}
			if (detail.use(CArg.BGM_PATH)) {
				c.bgmPath = encodePath(parseAttr!(string)(opt, node.attr, i, decodePath(c.bgmPath), varTable, 0));
			}
			if (detail.use(CArg.SOUND_PATH)) {
				c.soundPath = encodePath(parseAttr!(string)(opt, node.attr, i, decodePath(c.soundPath), varTable, 0));
			}
			if (detail.use(CArg.TRANSITION_SPEED)) {
				c.transitionSpeed = parseAttr!(int)(opt, node.attr, i, c.transitionSpeed, varTable, 0);
			}
			if (detail.use(CArg.TRANSITION)) {
				c.transition = parseAttr!(Transition)(opt, node.attr, i, c.transition, varTable, 0);
			}
			if (detail.use(CArg.INIT_VALUE)) {
				c.initValue = parseAttr!(int)(opt, node.attr, i, c.initValue, varTable, 0);
			}
			if (detail.use(CArg.COUPONS)) {
				c.coupons = parseAttr!(Coupon[])(opt, node.attr, i, c.coupons, varTable, 0);
			}
			if (detail.use(CArg.ROUND)) {
				c.round = parseAttr!(int)(opt, node.attr, i, c.round, varTable, 0);
			}
			Content autoWrap(Content c) {
				if (!c.detail.owner) {
					throwError(_prop.msgs.scriptErrorCanNotHaveContent, node.token);
				}
				if (_autoWrap <= stack) {
					autoWrapCount++;
					stack = 0;
					auto s = new Content(CType.START, .createNewName(.format("Auto wrap (%d)", autoWrapCount), (string name) {
						foreach (sn; startNames) {
							if (0 == icmp(sn, name)) {
								return false;
							}
						}
						return true;
					}));
					startNames ~= s.name;
					auto link = new Content(CType.LINK_START, c.name);
					link.start = s.name;
					c.add(link);
					if (isTop) {
						r ~= s;
					} else {
						topGroup ~= s;
					}
					return s;
				}
				return c;
			}
			if (nextIsChild) {
				/// 一つ前の分析結果は nextIsChild is true 。
				auto parent = autoWrap(lastParent);
				parent.add(c);
				stack++;
			} else {
				r ~= c;
			}
			if (node.childs.length) {
				auto parent = autoWrap(c);
				foreach (chld; analyzeSemanticsImpl(opt, node.childs, keys, varTable, stack + 1, autoWrapCount, startNames, isTop ? r : topGroup, false)) {
					parent.add(chld);
				}
			}
			nextIsChild = node.nextIsChild;
			if (nextIsChild) {
				lastParent = c;
			}
		}
		return r;
	}
	const
	string toScript(in Content[] cs, string evtChildOK, bool legacy, string indent = "\t") {
		char[] buf;
		auto table = new VarTable;
		toScriptImpl(evtChildOK, buf, cs, indent, "", KEYS, table, legacy);
		auto vars = table.vars();
		if (vars.length) {
			buf = std.string.join(vars, "\n") ~ "\n\n" ~ buf;
		}
		return assumeUnique(buf);
	}
	const
	private string[] toAttr(bool Within = false, T)(T value, string command, string indentValue, VarTable vars, size_t strWidth = 0) {
		string[] attrs;
		static if (is(Unqual!(T) == Symbol)) {
			attrs ~= value;
		} else static if (is(Unqual!(T) == string)) {
			string attr;
			auto lines = splitLines!string(value.idup);
			if (lines.length == 0) {
				attr ~= `""`;
			} else if (lines.length == 1) {
				attr ~= createString(lines[0]);
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
					line = std.array.replace(line, "@", "@@");
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
			attrs = [attrs.join(" ")];
		} else static if (is(T : bool)) {
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
		} else static if (is(T : Range)) {
			switch (value) {
			case Range.SELECTED: attrs ~= "M"; break;
			case Range.RANDOM: attrs ~= "R"; break;
			case Range.PARTY: attrs ~= "T"; break;
			case Range.BACKPACK: attrs ~= "backpack"; break;
			case Range.PARTY_AND_BACKPACK: attrs ~= "party"; break;
			case Range.FIELD: attrs ~= "field"; break;
			default: assert (0);
			}
		} else static if (is(T : CastRange)) {
			switch (value) {
			case CastRange.PARTY: attrs ~= "party"; break;
			case CastRange.ENEMY: attrs ~= "enemy"; break;
			case CastRange.NPC: attrs ~= "npc"; break;
			default: assert (0);
			}
		} else static if (is(T : Status)) {
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
			case Status.CONFUSE: attrs ~= "confuse"; break;
			case Status.OVERHEAT: attrs ~= "overheat"; break;
			case Status.BRAVE: attrs ~= "brave"; break;
			case Status.PANIC: attrs ~= "panic"; break;
			case Status.SILENCE: attrs ~= "silence"; break;
			case Status.FACE_UP: attrs ~= "faceup"; break;
			case Status.ANTI_MAGIC: attrs ~= "antimagic"; break;
			case Status.UP_ACTION: attrs ~= "upaction"; break;
			case Status.UP_AVOID: attrs ~= "upavoid"; break;
			case Status.UP_RESIST: attrs ~= "upresist"; break;
			case Status.UP_DEFENSE: attrs ~= "updefense"; break;
			case Status.DOWN_ACTION: attrs ~= "downaction"; break;
			case Status.DOWN_AVOID: attrs ~= "downavoid"; break;
			case Status.DOWN_RESIST: attrs ~= "downresist"; break;
			case Status.DOWN_DEFENSE: attrs ~= "downdefense"; break;
			case Status.NONE: attrs ~= "none"; break;
			default: assert (0);
			}
		} else static if (is(T : Target)) {
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
		} else static if (is(T : EffectType)) {
			switch (value) {
			case EffectType.PHYSIC: attrs ~= "physic"; break;
			case EffectType.MAGIC: attrs ~= "magic"; break;
			case EffectType.MAGICAL_PHYSIC: attrs ~= "mphysic"; break;
			case EffectType.PHYSICAL_MAGIC: attrs ~= "pmagic"; break;
			case EffectType.NONE: attrs ~= "none"; break;
			default: assert (0);
			}
		} else static if (is(T : Resist)) {
			switch (value) {
			case Resist.AVOID: attrs ~= "avoid"; break;
			case Resist.RESIST: attrs ~= "resist"; break;
			case Resist.UNFAIL: attrs ~= "unfail"; break;
			default: assert (0);
			}
		} else static if (is(T : CardVisual)) {
			switch (value) {
			case CardVisual.NONE: attrs ~= "none"; break;
			case CardVisual.REVERSE: attrs ~= "reverse"; break;
			case CardVisual.HORIZONTAL: attrs ~= "hswing"; break;
			case CardVisual.VERTICAL: attrs ~= "vswing"; break;
			default: assert (0);
			}
		} else static if (is(T : Mental)) {
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
		} else static if (is(T : Physical)) {
			switch (value) {
			case Physical.DEX: attrs ~= "dex"; break;
			case Physical.AGL: attrs ~= "agl"; break;
			case Physical.INT: attrs ~= "int"; break;
			case Physical.STR: attrs ~= "str"; break;
			case Physical.VIT: attrs ~= "vit"; break;
			case Physical.MIN: attrs ~= "min"; break;
			default: assert (0);
			}
		} else static if (is(T : Talker)) {
			attrs ~= toAttrTalker(value, "");
		} else static if (is(T : MType)) {
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
			case MType.NORMAL: attrs ~= "resetmind"; break;
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
			case MType.CANCEL_ACTION: attrs ~= "cancelaction"; break;
			default: assert (0);
			}
		} else static if (is(T : Element)) {
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
		} else static if (is(T : DamageType)) {
			switch (value) {
			case DamageType.LEVEL_RATIO: attrs ~= "level"; break;
			case DamageType.NORMAL: attrs ~= "value"; break;
			case DamageType.MAX: attrs ~= "max"; break;
			default: assert (0);
			}
		} else static if (is(T : EffectCardType)) {
			switch (value) {
			case EffectCardType.ALL: attrs ~= "all"; break;
			case EffectCardType.SKILL: attrs ~= "skill"; break;
			case EffectCardType.ITEM: attrs ~= "item"; break;
			case EffectCardType.BEAST: attrs ~= "beast"; break;
			default: assert (0);
			}
		} else static if (is(T : Comparison4)) {
			switch (value) {
			case Comparison4.Eq: attrs ~= createString("="); break;
			case Comparison4.Ne: attrs ~= createString("<>"); break;
			case Comparison4.Lt: attrs ~= createString(">"); break;
			case Comparison4.Gt: attrs ~= createString("<"); break;
			default: assert (0);
			}
		} else static if (is(T : Comparison3)) {
			switch (value) {
			case Comparison3.Eq: attrs ~= createString("="); break;
			case Comparison3.Lt: attrs ~= createString(">"); break;
			case Comparison3.Gt: attrs ~= createString("<"); break;
			default: assert (0);
			}
		} else static if (is(T : BlendMode)) {
			final switch (value) {
			case BlendMode.Normal: attrs ~= "normal"; break;
			case BlendMode.Mask: attrs ~= "normal"; break; // MaskはNormalと同様
			case BlendMode.Add: attrs ~= "add"; break;
			case BlendMode.Subtract: attrs ~= "sub"; break;
			case BlendMode.Multiply: attrs ~= "mul"; break;
			}
		} else static if (is(T : GradientDir)) {
			final switch (value) {
			case GradientDir.None: attrs ~= "none"; break;
			case GradientDir.LeftToRight: attrs ~= "horizontal"; break;
			case GradientDir.TopToBottom: attrs ~= "vertical"; break;
			}
		} else static if (is(T : CRGB)) {
			if (value.a == 255) {
				attrs ~= createString(.tryFormat("#%02X%02X%02X", value.r, value.g, value.b));
			} else {
				attrs ~= createString(.tryFormat("#%02X%02X%02X%02X", value.r, value.g, value.b, value.a));
			}
		} else static if (is(Unqual!(T) : BgImage)) {
			string[] attrs2;
			auto ic = cast(ImageCell) value;
			if (ic) {
				attrs2 ~= toAttr(encodePath(ic.path), command, indentValue, vars);
			}
			auto tc = cast(TextCell) value;
			if (tc) {
				attrs2 ~= "text";
				attrs2 ~= toAttr(tc.text, command, indentValue, vars);
				attrs2 ~= toAttr(tc.fontName, command, indentValue, vars);
				attrs2 ~= toAttr(tc.size, command, indentValue, vars);
				attrs2 ~= toAttr(tc.color, command, indentValue, vars);
				string[] style = [];
				if (tc.bold) style ~= "bold";
				if (tc.italic) style ~= "italic";
				if (tc.underline) style ~= "underline";
				if (tc.strike) style ~= "strike";
				if (tc.vertical) style ~= "vertical";
				final switch (tc.borderingType) {
				case BorderingType.None:
					attrs2 ~= std.string.join(style, " ");
					break;
				case BorderingType.Outline:
					style ~= "border1";
					attrs2 ~= std.string.join(style, " ");
					attrs2 ~= toAttr(tc.borderingColor, command, indentValue, vars);
					break;
				case BorderingType.Inline:
					style ~= "border2";
					attrs2 ~= std.string.join(style, " ");
					attrs2 ~= toAttr(tc.borderingColor, command, indentValue, vars);
					attrs2 ~= toAttr(tc.borderingWidth, command, indentValue, vars);
					break;
				}
			}
			auto cc = cast(ColorCell) value;
			if (cc) {
				attrs2 ~= "color";
				attrs2 ~= toAttr(cc.blendMode, command, indentValue, vars);
				attrs2 ~= toAttr(cc.color1, command, indentValue, vars);
				final switch (cc.gradientDir) {
				case GradientDir.None:
					break;
				case GradientDir.LeftToRight:
				case GradientDir.TopToBottom:
					attrs2 ~= toAttr(cc.gradientDir, command, indentValue, vars);
					attrs2 ~= toAttr(cc.color2, command, indentValue, vars);
					break;
				}
			}
			attrs2 ~= toAttr(value.flag, command, indentValue, vars);
			attrs2 ~= toAttr(value.x, command, indentValue, vars);
			attrs2 ~= toAttr(value.y, command, indentValue, vars);
			attrs2 ~= toAttr(value.width, command, indentValue, vars);
			attrs2 ~= toAttr(value.height, command, indentValue, vars);
			if (ic) {
				attrs2 ~= toAttr(ic.mask, command, indentValue, vars);
			}
			attrs ~= "[" ~ std.string.join(attrs2, ", ") ~ "]";
		} else static if (is(Unqual!(T) : Motion)) {
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
				if (value.beast) {
					attrs2 ~= toAttr(vars.id(_summ.findSameBeast(value.beast), value.beast.linkId), command, indentValue, vars);
				} else {
					attrs2 ~= toAttr(cast(Symbol) "0", command, indentValue, vars);
				}
			}
			attrs2 ~= toAttr(value.element, command, indentValue, vars);
			attrs ~= "[" ~ std.string.join(attrs2, ", ") ~ "]";
		} else static if (is(Unqual!(T) : SDialog)) {
			string[] attrs2;
			bool semic = false;
			foreach (c; value.rCoupons) {
				if (std.string.indexOf(c, ";") >= 0) {
					semic = true;
					break;
				}
			}
			if (semic) {
				attrs2 ~= "[" ~ std.string.join(toAttr(value.rCoupons, command, indentValue, vars), ", ") ~ "]";
			} else {
				attrs2 ~= createString(std.string.join(value.rCoupons.dup, ";"));
			}
			attrs2 ~= toAttr(value.text, command, indentValue, vars, strWidth);
			attrs ~= "[" ~ std.string.join(attrs2, ", ") ~ "]";
		} else static if (is(Unqual!(T) : Coupon)) {
			string[] attrs2;
			attrs2 ~= createString(value.name);
			attrs2 ~= to!(string)(value.value);
			attrs ~= "[" ~ std.string.join(attrs2, ", ") ~ "]";
		} else static if (is(T : int)) {
			attrs ~= to!(string)(value);
		} else static if (is(T : uint)) {
			attrs ~= to!(string)(value);
		} else static if (is(T : ulong)) {
			attrs ~= to!(string)(value);
		} else static assert (0);
		return attrs;
	}
	const
	private string toAttrTalker(Talker t, string cardPath) {
		switch (t) {
		case Talker.NARRATION: return "none";
		case Talker.SELECTED: return "M";
		case Talker.UNSELECTED: return "U";
		case Talker.RANDOM: return "R";
		case Talker.CARD: return "C";
		case Talker.IMAGE: return createString(encodePath(cardPath));
		case Talker.VALUED: return "V";
		default: assert (0);
		}
	}
	private struct Symbol {
		string symbol;
		alias symbol this;
	}
	private static class VarTable {
		bool useVar = true;
		bool useCenter = true;
		private Symbol idVar(string Name, A)(in A a, ulong id, ref string[ulong] tbl, ref ulong[string] tblR) {
			if (!useVar || !a) return Symbol(to!(string)(id));
			auto p = a.id in tbl;
			if (p) return Symbol(*p);
			string base = "$" ~ Name ~ "_" ~ validVarName(a.name);
			string name = base;
			size_t i = 1;
			while (name in tblR) {
				i++;
				name = base ~ "_" ~ to!(string)(i);
			}
			tbl[a.id] = name;
			tblR[name] = a.id;
			return Symbol(name);
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
		Symbol id(in Area a, ulong id) {return idVar!("area")(a, id, _areas, _areasR);}
		Symbol id(in Battle a, ulong id) {return idVar!("battle")(a, id, _battles, _battlesR);}
		Symbol id(in Package a, ulong id) {return idVar!("pack")(a, id, _packages, _packagesR);}
		Symbol id(in CastCard a, ulong id) {return idVar!("cast")(a, id, _casts, _castsR);}
		Symbol id(in SkillCard a, ulong id) {return idVar!("skill")(a, id, _skills, _skillsR);}
		Symbol id(in ItemCard a, ulong id) {return idVar!("item")(a, id, _items, _itemsR);}
		Symbol id(in BeastCard a, ulong id) {return idVar!("beast")(a, id, _beasts, _beastsR);}
		Symbol id(in InfoCard a, ulong id) {return idVar!("info")(a, id, _infos, _infosR);}
		private static string[] vars(in string[ulong] arr) {
			string[] r;
			foreach (id; arr.keys.sort) {
				r ~= arr[id] ~ " = " ~ to!(string)(id);
			}
			return r;
		}
		const
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
	const
	private void toScriptImpl(string evtChildOK, ref char[] buf, in Content[] cs, string indent, string indentValue, in Keywords keys, VarTable vars, bool legacy) {
		foreach (i, c; cs) {
			if (i > 0) buf ~= "\n\n";
			buf ~= indentValue;
			auto detail = c.detail;
			if (c.comment.length) {
				foreach (line; splitLines!string(lastRet(c.comment))) {
					buf ~= "// " ~ line;
					buf ~= "\n";
					buf ~= indentValue;
				}
			}
			string command = keys.commands[c.type];
			buf ~= command;
			string[] attrs;
			if (c.type is CType.START) {
				attrs ~= createString(c.name);
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
			if (detail.use(CArg.TARGET_NS)) {
				attrs ~= toAttr!(true)(c.targetNS, command, indentValue, vars);
			}
			if (detail.use(CArg.TARGET_S)) {
				attrs ~= toAttr(c.targetS, command, indentValue, vars);
			}
			if (detail.use(CArg.RANGE)) {
				attrs ~= toAttr(c.range, command, indentValue, vars);
			}
			if (detail.use(CArg.CAST_RANGE)) {
				attrs ~= toAttr(c.castRange, command, indentValue, vars);
			}
			if (detail.use(CArg.KEY_CODE_RANGE)) {
				attrs ~= toAttr(c.keyCodeRange, command, indentValue, vars);
			}
			if (detail.use(CArg.EFFECT_CARD_TYPE)) {
				attrs ~= toAttr(c.effectCardType, command, indentValue, vars);
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
				auto a = _summ.cwPackage(c.packages);
				attrs ~= toAttr(vars.id(a, c.packages), command, indentValue, vars);
			}
			if (detail.use(CArg.CAST)) {
				auto a = _summ.cwCast(c.casts);
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
			if (detail.use(CArg.KEY_CODE)) {
				attrs ~= toAttr(c.keyCode, command, indentValue, vars);
			}
			if (detail.use(CArg.GOSSIP)) {
				attrs ~= toAttr(c.gossip, command, indentValue, vars);
			}
			if (detail.use(CArg.FLAG)) {
				if (_prop && _prop.sys.randomValue == c.flag) {
					attrs ~= toAttr(Symbol("random"), command, indentValue, vars);
				} else {
					attrs ~= toAttr(c.flag, command, indentValue, vars);
				}
			}
			if (detail.use(CArg.FLAG_2)) {
				if (_prop && _prop.sys.randomValue == c.flag2) {
					attrs ~= toAttr(Symbol("random"), command, indentValue, vars);
				} else {
					attrs ~= toAttr(c.flag2, command, indentValue, vars);
				}
			}
			if (detail.use(CArg.STEP)) {
				if (_prop && _prop.sys.randomValue == c.step) {
					attrs ~= toAttr(Symbol("random"), command, indentValue, vars);
				} else {
					attrs ~= toAttr(c.step, command, indentValue, vars);
				}
			}
			if (detail.use(CArg.STEP_2)) {
				if (_prop && _prop.sys.randomValue == c.step2) {
					attrs ~= toAttr(Symbol("random"), command, indentValue, vars);
				} else {
					attrs ~= toAttr(c.step2, command, indentValue, vars);
				}
			}
			if (detail.use(CArg.COMPARISON_4)) {
				attrs ~= toAttr(c.comparison4, command, indentValue, vars);
			}
			if (detail.use(CArg.COMPARISON_3)) {
				attrs ~= toAttr(c.comparison3, command, indentValue, vars);
			}
			if (detail.use(CArg.FLAG_VALUE)) {
				attrs ~= toAttr(c.flagValue, command, indentValue, vars);
			}
			if (detail.use(CArg.STEP_VALUE)) {
				attrs ~= toAttr(c.stepValue, command, indentValue, vars);
			}
			if (detail.use(CArg.CARD_NUMBER)) {
				if (c.cardNumber != 0) {
					attrs ~= toAttr(c.cardNumber, command, indentValue, vars);
				} else {
					attrs ~= toAttr(Symbol("all"), command, indentValue, vars);
				}
			}
			if (detail.use(CArg.MOTIONS)) {
				attrs ~= toAttr(c.motions, command, indentValue, vars);
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
			if (detail.use(CArg.LEVEL_MIN)) {
				attrs ~= toAttr(c.levelMin, command, indentValue, vars);
			}
			if (detail.use(CArg.LEVEL_MAX)) {
				attrs ~= toAttr(c.levelMax, command, indentValue, vars);
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
					attrs ~= toAttr(Symbol("stop"), command, indentValue, vars);
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
			if (detail.use(CArg.INIT_VALUE)) {
				attrs ~= toAttr(c.initValue, command, indentValue, vars);
			}
			if (detail.use(CArg.COUPONS)) {
				attrs ~= toAttr(c.coupons, command, indentValue, vars);
			}
			if (detail.use(CArg.ROUND)) {
				attrs ~= toAttr(c.round, command, indentValue, vars);
			}
			bool useIf = c.next.length > 1;
			bool useSif = c.next.length == 1 && c.next[0].name.length;
			if (!useIf) {
				foreach (chld; c.next) {
					if (chld.name.length) {
						if (detail.nextType is CNextType.TEXT && chld.name == evtChildOK) {
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
					final switch (detail.nextType) {
					case CNextType.NONE:
						buf ~= `""`;
						break;
					case CNextType.TEXT:
						buf ~= createString(chld.name);
						break;
					case CNextType.BOOL:
						buf ~= icmp(chld.name, _prop.sys.evtChildTrue) == 0 ? "true" : "false";
						break;
					case CNextType.STEP:
					case CNextType.ID_AREA:
					case CNextType.ID_BATTLE:
						if (icmp(chld.name, _prop.sys.evtChildDefault) == 0) {
							buf ~= "default";
						} else {
							buf ~= chld.name;
						}
						break;
					case CNextType.TRIO:
						buf ~= createString(chld.name);
						break;
					}
					buf ~= "\n";
					auto nextIndent = useSif ? indentValue : indentValue ~ indent;
					toScriptImpl(evtChildOK, buf, [chld], indent, nextIndent, keys, vars, legacy);
				} else {
					buf ~= "\n";
					if (c.type is CType.START) {
						toScriptImpl(evtChildOK, buf, [chld], indent, indentValue ~ indent, keys, vars, legacy);
					} else {
						toScriptImpl(evtChildOK, buf, [chld], indent, indentValue, keys, vars, legacy);
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
	return assumeUnique(buf);
}

private const string[] TOKENS = [
	`[a-z_][a-z_0-9]*`, // symbol or keyword
	"\\$[^\b\t\n\v\f\r !\"#$%&\'\\(\\)*+,\\-./:;<=>?@\\[\\\\\\]^`{}|~]+", // variable
	`=`, // equql
	`[0-9]+(\.[0-9]+)?`, // number
	`\[`, // open bracket
	`\]`, // close bracket
	`,`, // comma
	"\"(\"\"|[^\"])*?\"", // string
	"'(''|[^'])*?'", // string
	`@[ \t]*([0-9]+|c|center)?[ \t]*\n(([^@]|@@|\n)*\n)?[ \t]*@`, // string
	`[ \t\r\n]+`, // whitespace
	`\+`, // plus
	`-`, // minus
	`\*\/?`, // multiply or comment end
	`\/(\/.*(\n|$)|\*)?`, // divide or comment start
	`%`, // residue
	`~`, // cat
	`\(`, // open paren
	`\)` // close paren
];
