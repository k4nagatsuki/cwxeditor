
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
import std.range : ElementType;
import std.typecons;

/// スクリプトの解析途中に発生したエラー。
struct CWXSError {
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
class CWXScriptException : Exception {
	this (string file, size_t line, string text, const CWXSError[] errors, bool over100) { mixin(S_TRACE);
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
	string text() { return _text; }
	/// 発生したエラーの配列。
	@property
	const
	const(CWXSError[]) errors() { return _errors; }
	/// エラーが100件を超えたか。
	@property
	const
	bool over100() { return _over100; }
}

/// 空変数への設定値。
struct VarSet {
	string var; /// 変数名。
	string value; /// 設定値。
}

/// コンパイルオプション。
struct CompileOption {
	bool linkId = false; /// カードを参照で設定するか。
	ptrdiff_t startLine = 0; /// スクリプトの論理的な開始行(通常0)。
	ptrdiff_t startPos = 0; /// スクリプトの論理的な開始位置(通常0)。
	ptrdiff_t addLines = 0; /// スクリプトに追加した行数(通常0)。
}

/// スクリプトを解析し、コンテント群にして返す。
/// 解析中にエラーがあった場合はCWXScriptExceptionを投げる。
Content[] compile(const(CProps) prop, const(Summary) summ, string script, in CompileOption opt) { mixin(S_TRACE);
	auto compiler = new CWXScript(prop, summ, script);
	auto tokens = compiler.tokenize(script, opt);
	if (compiler.errors.length) throw new CWXScriptException(__FILE__, __LINE__, script, compiler.errors, false);
	auto nodes = compiler.analyzeSyntax(tokens);
	if (compiler.errors.length) throw new CWXScriptException(__FILE__, __LINE__, script, compiler.errors, false);
	auto r = compiler.analyzeSemantics(nodes, opt);
	if (compiler.errors.length) throw new CWXScriptException(__FILE__, __LINE__, script, compiler.errors, false);
	return r;
}

/// スクリプトに含まれる最初のイベントコンテントのタイプを返す。
/// タイプが検出できない場合は-1を返す。
CType firstContentType(const(CProps) prop, const(Summary) summ, string script) { mixin(S_TRACE);
	CompileOption opt;
	auto compiler = new CWXScript(prop, summ, script);
	auto tokens = compiler.tokenize(script, opt);
	if (compiler.errors.length) return cast(CType)-1;
	foreach (ref token; tokens) { mixin(S_TRACE);
		if (token.kind is CWXScript.Kind.START) return CType.Start;
		if (token.kind is CWXScript.Kind.SYMBOL) { mixin(S_TRACE);
			auto p = token.value.toLower() in CWXScript.KEYS.keywords;
			if (p) { mixin(S_TRACE);
				return *p;
			}
		}
	}
	return cast(CType)-1;
}

/// スクリプトからコンテントツリーを生成する。
class CWXScript {
	private const(CProps) _prop;
	private const(Summary) _summ;
	private string _text;
	private size_t _maxError;
	private size_t _autoWrap;
	/// 唯一のコンストラクタ。
	this (const(CProps) prop, const(Summary) summ, string text = "", size_t maxError = 100, size_t autoWrap = 250) { mixin(S_TRACE);
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
	const(CWXSError[]) errors() { return _errors; }

	/// sをスクリプト内での文字列表現に変換する。
	static string createString(string s, bool useSingleQuote = false) { mixin(S_TRACE);
		if (useSingleQuote) { mixin(S_TRACE);
			return "'" ~ std.array.replace(s, "'", "''") ~ "'";
		} else { mixin(S_TRACE);
			return "\"" ~ std.array.replace(s, "\"", "\"\"") ~ "\"";
		}
	}

	private void throwError(string File = __FILE__, size_t Line = __LINE__)
			(lazy string message, in Token tok) { mixin(S_TRACE);
		throwErrorToken!(File, Line)(message, tok.line, tok.pos, tok.value);
	}
	private void throwErrorToken(string File = __FILE__, size_t Line = __LINE__)
			(lazy string message, size_t line, size_t pos, string value) { mixin(S_TRACE);
		if (!_maxError) return;
		if (_errors.length && _errors[$ - 1].errLine == line && _errors[$ - 1].errPos == pos) { mixin(S_TRACE);
			// 同一箇所でのエラーは一つだけにする
			return;
		}
		string msg;
		if (!_prop || !_prop.msgs) { mixin(S_TRACE);
			msg = "";
		} else { mixin(S_TRACE);
			msg = message;
		}
		if (_maxError <= _errors.length) { mixin(S_TRACE);
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
		size_t line; /// トークンのある行。
		size_t pos; /// 行内の位置。
		size_t index; /// スクリプト全体での位置。
		Kind kind; /// 種別。
		string value; /// 値。
		string comment = ""; /// 直前のコメント。
		/// 文字列表現。
		const
		string toString() { mixin(S_TRACE);
			return .format("Token {line %d : %d, %d, %s, %s, %s}", line, pos, index, to!(string)(kind), value, comment);
		}
		/// oと等しいか。
		const
		bool opEquals(ref const(Token) o) { mixin(S_TRACE);
			return line == o.line && pos == o.pos && index == o.index && kind == o.kind && value == o.value && comment == o.comment;
		}
	}
	private static string[] wrap(string line, size_t width) { mixin(S_TRACE);
		if (width > 0) { mixin(S_TRACE);
			string[] lines;
			while (lengthJ(line) > width) { mixin(S_TRACE);
				auto l = sliceJ(line, 0, width);
				if (!l.length) { mixin(S_TRACE);
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
	private size_t stringCenter(string[] linesBase, size_t width) { mixin(S_TRACE);
		string[] lines;
		if (width > 0) { mixin(S_TRACE);
			foreach (line; linesBase) { mixin(S_TRACE);
				lines ~= wrap(line, width);
			}
		} else { mixin(S_TRACE);
			lines = linesBase;
		}
		int ln;
		int lc = cast(int) lineCount(lines);
		if (lc > 0 && lc < _prop.looks.messageLine) { mixin(S_TRACE);
			int lnt = cast(int) _prop.looks.messageLine - (lc - 1);
			ln = lnt / 2 + 1;
		} else { mixin(S_TRACE);
			ln = 0;
		}
		return ln > 0 ? ln : 0;
	}
	/// Tokenの値を文字列として解釈して返す。
	/// 文字列を囲う記号に加え、
	/// 行頭にあるタブ文字や一定数の空白が取り除かれる。
	private string stringValue(in Token tok, size_t width) { mixin(S_TRACE);
		string decode(in char[] s, char esc) { mixin(S_TRACE);
			char[] buf = new char[s.length];
			size_t len = 0;
			bool escape = false;
			foreach (char c; s) { mixin(S_TRACE);
				if (!escape && c == esc) { mixin(S_TRACE);
					escape = true;
				} else { mixin(S_TRACE);
					buf[len] = c;
					len++;
					escape = false;
				}
			}
			if (escape) { mixin(S_TRACE);
				buf[len] = esc;
				len++;
			}
			buf = buf[0 .. len];
			return assumeUnique(buf);
		}
		if (tok.kind !is Kind.STRING || tok.value.length < 2) { mixin(S_TRACE);
			throwError(_prop.msgs.scriptErrorInvalidString, tok);
		}
		if (tok.value[0] == '@') { mixin(S_TRACE);
			char[] buf;
			auto linesBase = .splitLines(tok.value[0 .. $ - 1].idup);
			string firstLine = linesBase[0];
			string[] lines;
			string[] resultLines;
			foreach (i, line; linesBase[1 .. $]) { mixin(S_TRACE);
				line = .astripl(line);
				line = decode(line, tok.value[0]);
				if (line.length >= 1 && line[0] == '\\') { mixin(S_TRACE);
					line = line[1 .. $];
				}
				resultLines ~= line;
				lines ~= wrap(line, width);
			}
			if (firstLine.length > 1) { mixin(S_TRACE);
				auto lnStr = std.string.toLower(.astrip(firstLine[1 .. $]));
				bool isNum = std.string.isNumeric(lnStr);
				if (!isNum && icmp(lnStr, "c") != 0 && icmp(lnStr, "center") != 0) { mixin(S_TRACE);
					throwError(_prop.msgs.scriptErrorInvalidStr, tok);
				}
				ptrdiff_t ln;
				if (isNum) { mixin(S_TRACE);
					ln = .to!(ptrdiff_t)(lnStr);
				} else { mixin(S_TRACE);
					ln = stringCenter(lines, 0);
				}
				if (ln > 0) { mixin(S_TRACE);
					buf.length = ln - 1;
				}
				buf[] = '\n';
			}
			foreach (i, line; resultLines) { mixin(S_TRACE);
				if (i > 0) buf ~= '\n';
				buf ~= line;
			}
			return assumeUnique(buf);
		}
		return decode(tok.value[1 .. $ - 1], tok.value[0]);
	} unittest { mixin(S_TRACE);
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
	string[] eatEmptyVars(ref string text, ref CompileOption opt) { mixin(S_TRACE);
		auto tokens = tokenizeImpl(text, true, opt);
		// コメントを取り除く
		Token[] tokens2;
		foreach (tok; tokens) { mixin(S_TRACE);
			if (tok.kind !is Kind.COMMENT) { mixin(S_TRACE);
				tokens2 ~= tok;
			}
		}
		string[] r;
		size_t index = 0;
		size_t len = 0;
		opt.startLine = 0;
		opt.startPos = 0;
		// 空の変数のみを取得するため、'='が現れたらその場で処理終了
		foreach (i, tok; tokens2) { mixin(S_TRACE);
			if (tok.kind is Kind.EQ) { mixin(S_TRACE);
				throwError(_prop.msgs.scriptErrorInvalidSyntax, tok);
				break;
			} else if (tok.kind is Kind.VAR_NAME) { mixin(S_TRACE);
				if (i + 1 < tokens2.length && tokens2[i + 1].kind is Kind.EQ) { mixin(S_TRACE);
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
	} unittest { mixin(S_TRACE);
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
	static string pushVars(string text, in VarSet[] varTable, ref CompileOption opt) { mixin(S_TRACE);
		string[] lines;
		opt.addLines = 0;
		foreach (t; varTable) { mixin(S_TRACE);
			string v = t.value;
			if (!v.length) v = `""`;
			auto l = t.var ~ " = " ~ v;
			lines ~= l;
			opt.addLines += v.splitLines().length;
		}
		lines ~= text;
		opt.startLine -= opt.addLines;
		return lines.join("\n");
	} unittest { mixin(S_TRACE);
		CompileOption opt;
		VarSet[] varSet = [VarSet("$a", "1"), VarSet("$b", "2")];
		auto r = pushVars("aaa bbb", varSet, opt);
		assert (r == "$a = 1\n$b = 2\naaa bbb", r);
		assert (opt.startLine == -2, .text(opt.startLine));
	}

	/// textをTokenに分割する。
	Token[] tokenize(string text, in CompileOption opt = CompileOption.init) { mixin(S_TRACE);
		return tokenizeImpl(text, false, opt);
	} unittest { mixin(S_TRACE);
		debug mixin(UTPerf);
		auto s = new CWXScript(new CProps("", null), null);
		auto tokens = s.tokenize("");
		assert (tokens == [], to!string(tokens));
		tokens = s.tokenize("/* */");
		assert (tokens == [Token(0, 0, 0, Kind.COMMENT, "/* */", "")], to!string(tokens));
		tokens = s.tokenize("/* <> */");
		assert (tokens == [Token(0, 0, 0, Kind.COMMENT, "/* <> */", "")], to!string(tokens));
		tokens = s.tokenize("/* <> */start \"\"");
		assert (tokens == [
			Token(0, 0, 0, Kind.COMMENT, "/* <> */", ""),
			Token(0, 10, 8, Kind.START, "start", " <> "),
			Token(0, 16, 14, Kind.STRING, "\"\""),
		], to!string(tokens));
		tokens = s.tokenize("/* <- テスト -> */");
		assert (tokens == [Token(0, 0, 0, Kind.COMMENT, "/* <- テスト -> */", "")], to!string(tokens));
		tokens = s.tokenize("/*/*\n*/*/");
		assert (tokens == [Token(0, 0, 0, Kind.COMMENT, "/*/*\n*/*/", "")], to!string(tokens));
		tokens = s.tokenize("/*/*\nテスト\n*/*/");
		assert (tokens == [Token(0, 0, 0, Kind.COMMENT, "/*/*\nテスト\n*/*/", "")], to!string(tokens));
		tokens = s.tokenize("/*c*/start, 12.3 \ntest1 [$void] =\"str\ning//\"\n\r //comment\nELIF if\n1/2+3*4%(5-6)");
		assert (Token(0, 12, 12, Kind.NUMBER, "12.3") == tokens[3]);
		auto tokens2 = [
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
		];
		assert (tokens2.length == 26, to!string(tokens2.length));
		assert (tokens.length == tokens2.length);
		assert (tokens == tokens2, tokens.to!string() ~ " != " ~ tokens2.to!string());
	}
	private Token[] tokenizeImpl(ref string text, bool eatEmptyVarMode, in CompileOption opt) { mixin(S_TRACE);
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
		string post, pre;
		bool spaceAfter = false;
		string docComment = "";
		string fullComment = "";
		@property ptrdiff_t sLine() { return cast(ptrdiff_t)i + opt.startLine; }
		@property ptrdiff_t sPos() { return (cast(ptrdiff_t)i == opt.addLines) ? (cast(ptrdiff_t)pos + opt.startPos) : pos; }
		auto maches = .match(dtext, reg);
		if (!maches && dtext.length) { mixin(S_TRACE);
			throwErrorToken(_prop.msgs.scriptErrorInvalidToken, sLine, sPos, "");
			return r;
		}
		foreach (token; maches) { mixin(S_TRACE);
			if (0 < token.pre.length - index) { mixin(S_TRACE);
				if (0 < commentLevel) { mixin(S_TRACE);
					fullComment ~= token.pre[index .. $];
					docComment ~= token.pre[index .. $];
				} else { mixin(S_TRACE);
					auto li = std.string.lastIndexOf(pre, '\n');
					pos = li == -1 ? pre.length : pre.length - li;
					throwErrorToken(_prop.msgs.scriptErrorInvalidToken, sLine, sPos, "");
					return r;
				}
			}
			post = token.post;
			pre = token.pre;
			pos += pre.length - index;
			index = pre.length;
			auto dstr = token.hit;
			void retCount2(string dstr) { mixin(S_TRACE);
				size_t count = .count(dstr, "\n");
				if (0 < count) { mixin(S_TRACE);
					pos = dstr.length - std.string.lastIndexOf(dstr, '\n') - 1;
					i += count;
				} else { mixin(S_TRACE);
					pos += dstr.length;
				}
			}
			void retCount() { mixin(S_TRACE);
				retCount2(dstr);
			}
			auto c = dstr[0];
			string str = to!string(dstr);
			if (cast(int)pre.length - cast(int)hits > 0) { mixin(S_TRACE);
				if (0 < commentLevel) { mixin(S_TRACE);
					/// in comment
					retCount2(pre[hits .. $]);
					hits = pre.length;
				} else { mixin(S_TRACE);
					string lpre = pre;
					if (lpre.length && (lpre[$ - 1] == '@' || lpre[$ - 1] == '"' || lpre[$ - 1] == '\'')) { mixin(S_TRACE);
						throwErrorToken(_prop.msgs.scriptErrorUnCloseString, sLine, sPos, "");
						return r;
					} else { mixin(S_TRACE);
						throwErrorToken(_prop.msgs.scriptErrorInvalidToken, sLine, sPos, "");
					}
				}
			}
			if (0 < commentLevel) { mixin(S_TRACE);
				fullComment ~= .text(pre[hits .. $]) ~ str;
			}
			bool commentStart = false;
			if (str == "/*") { mixin(S_TRACE);
				// multi line comment (open)
				spaceAfter = true;
				if (commentLevel == 0) { mixin(S_TRACE);
					commentStart = true;
					lastCommentLine = i;
					lastCommentPos = pos;
					lastCommentIndex = index;
				}
				pos += dstr.length;
				if (0 == commentLevel) fullComment = str;
				commentLevel++;
			} else if (str == "*/") { mixin(S_TRACE);
				// multi line comment (close)
				spaceAfter = true;
				pos += dstr.length;
				if (commentLevel <= 0) { mixin(S_TRACE);
					throwErrorToken(_prop.msgs.scriptErrorUnOpenComment, sLine, sPos, str);
				}
				commentLevel--;
				if (0 == commentLevel) { mixin(S_TRACE);
					r ~= Token(lastCommentLine, lastCommentPos, lastCommentIndex, Kind.COMMENT, fullComment, "");
				}
			} else if (0 < commentLevel) { mixin(S_TRACE);
				spaceAfter = true;
				retCount();
 			} else if (std.ascii.isAlpha(c) || c == '_') { mixin(S_TRACE);
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
			} else if (c == '$') { mixin(S_TRACE);
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.VAR_NAME, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '=') { mixin(S_TRACE);
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.EQ, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '[') { mixin(S_TRACE);
 				if (eatEmptyVarMode) return r;
				// open bracket
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.O_BRA, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == ']') { mixin(S_TRACE);
 				if (eatEmptyVarMode) return r;
				// close bracket
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.C_BRA, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (isDigit(c)) { mixin(S_TRACE);
 				if (eatEmptyVarMode) return r;
				// number
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.NUMBER, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '@' || c == '"' || c == '\'') { mixin(S_TRACE);
 				if (eatEmptyVarMode) return r;
				// string
				if (!spaceAfter && r.length && r[$ - 1].kind is Kind.STRING
						&& r[$ - 1].value[$ - 1] == c) { mixin(S_TRACE);
					// 直前のstringに結合
					r[$ - 1].value ~= str;
				} else { mixin(S_TRACE);
					r ~= Token(sLine, sPos, index, Kind.STRING, str, docComment);
				}
				spaceAfter = false;
				retCount();
 				docComment = "";
			} else if (std.ascii.isWhite(c)) { mixin(S_TRACE);
				// whitespace
				spaceAfter = true;
				retCount();
			} else if (c == '+') { mixin(S_TRACE);
 				if (eatEmptyVarMode) return r;
				// plus
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.PLU, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '-') { mixin(S_TRACE);
 				if (eatEmptyVarMode) return r;
				// minus
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.MIN, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '*') { mixin(S_TRACE);
 				if (eatEmptyVarMode) return r;
				// multiply
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.MUL, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '/') { mixin(S_TRACE);
				if (dstr.length >= 2 && str[1] == '/') { mixin(S_TRACE);
					// line comment
					spaceAfter = true;
					r ~= Token(sLine, sPos, index, Kind.COMMENT, str, "");
					i++;
					pos = 0;
					if (2 < str.length) docComment ~= str[2 .. $];
				} else { mixin(S_TRACE);
 					if (eatEmptyVarMode) return r;
					// divide
					spaceAfter = false;
					r ~= Token(sLine, sPos, index, Kind.DIV, str, docComment);
					pos += dstr.length;
 					docComment = "";
				}
			} else if (c == '%') { mixin(S_TRACE);
 				if (eatEmptyVarMode) return r;
				// residue
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.RES, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '~') { mixin(S_TRACE);
 				if (eatEmptyVarMode) return r;
				// cat
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.CAT, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == '(') { mixin(S_TRACE);
 				if (eatEmptyVarMode) return r;
				// open paren
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.O_PAR, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == ')') { mixin(S_TRACE);
 				if (eatEmptyVarMode) return r;
				// close paren
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.C_PAR, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else if (c == ',') { mixin(S_TRACE);
 				if (eatEmptyVarMode) return r;
				// comma
				spaceAfter = false;
				r ~= Token(sLine, sPos, index, Kind.COMMA, str, docComment);
				pos += dstr.length;
 				docComment = "";
			} else { mixin(S_TRACE);
				assert (0);
			}
			if (!commentStart && 0 < commentLevel) { mixin(S_TRACE);
				docComment ~= str;
			}
			hits += dstr.length;
			index += dstr.length;
		}
		if (0 < commentLevel) { mixin(S_TRACE);
			throwErrorToken(_prop.msgs.scriptErrorUnCloseComment, lastCommentLine, lastCommentPos, "");
		}
		if (post.length) throwErrorToken(_prop.msgs.scriptErrorInvalidToken, sLine, sPos, "");
		return r;
	}

	private enum CRKind { STR, INT, REAL }
	private class CalcResult {
		CRKind kind = CRKind.INT;
		union {
			string str;
			long numInt;
			real numReal;
		}
		this () { mixin(S_TRACE);
			numInt = 0;
		}
		void cat(in CProps prop, in Token tok, in CalcResult rval) { mixin(S_TRACE);
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
		private void calc(string Calc, bool ChkDiv)(in CProps prop, in Token tok, in CalcResult rval) { mixin(S_TRACE);
			if (kind is CRKind.STR || rval.kind is CRKind.STR) { mixin(S_TRACE);
				throwError(prop.msgs.scriptErrorInvalidNumber, tok);
			}
			static if (ChkDiv) {
				if ((rval.kind is CRKind.REAL ? rval.numReal : rval.numInt) == 0) { mixin(S_TRACE);
					throwError(prop.msgs.scriptErrorZeroDivision, tok);
				}
			}
			if (kind is CRKind.REAL || rval.kind is CRKind.REAL) { mixin(S_TRACE);
				real lvalue = kind is CRKind.REAL ? numReal : numInt;
				real rvalue = rval.kind is CRKind.REAL ? rval.numReal : rval.numInt;
				mixin("numReal = lvalue " ~ Calc ~ " rvalue;");
				kind = CRKind.REAL;
			} else if (kind is CRKind.INT && rval.kind is CRKind.INT) { mixin(S_TRACE);
				mixin("numInt " ~ Calc ~ "= rval.numInt;");
			} else { mixin(S_TRACE);
				throwError(prop.msgs.scriptErrorInvalidNumber, tok);
			}
		}
		public alias calc!("+", false) add;
		public alias calc!("-", false) min;
		public alias calc!("*", false) mul;
		public alias calc!("/", true) div;
		public alias calc!("%", true) res;
		const
		bool opEquals(ref const(CalcResult) val) { mixin(S_TRACE);
			if (kind !is val.kind) return false;
			final switch (kind) {
			case CRKind.STR: return str == val.str;
			case CRKind.INT: return numInt == val.numInt;
			case CRKind.REAL: return numReal == val.numReal;
			}
		}
		const
		bool opEquals(int val) { mixin(S_TRACE);
			return opEquals(cast(long) val);
		}
		const
		bool opEquals(long val) { mixin(S_TRACE);
			final switch (kind) {
			case CRKind.STR: return false;
			case CRKind.INT: return numInt == val;
			case CRKind.REAL: return numReal == val;
			}
		}
		const
		bool opEquals(real val) { mixin(S_TRACE);
			final switch (kind) {
			case CRKind.STR: return false;
			case CRKind.INT: return numInt == val;
			case CRKind.REAL: return numReal == val;
			}
		}
		const
		bool opEquals(string val) { mixin(S_TRACE);
			return kind is CRKind.STR && str == val;
		}
		override
		const
		string toString() { mixin(S_TRACE);
			final switch (kind) {
			case CRKind.STR: return str;
			case CRKind.INT: return to!(string)(numInt);
			case CRKind.REAL: return to!(string)(numReal);
			}
		}
	}
	private static immutable OPE_LEVEL_MAX = 2;
	private CalcResult calcNum(in Token[] tokens, ref size_t i, in const(Node)[][string] varTable, size_t strWidth) { mixin(S_TRACE);
		assert (i < tokens.length);
		auto tok = tokens[i];
		if (tok.kind is Kind.VAR_NAME) { mixin(S_TRACE);
			i++;
			try { mixin(S_TRACE);
				auto vt = var(tok, varTable);
				auto r = new CalcResult;
				if (vt.kind is Kind.STRING) { mixin(S_TRACE);
					r.kind = CRKind.STR;
					r.str = stringValue(vt, strWidth);
				} else if (std.string.indexOf(vt.value, '.') != -1) { mixin(S_TRACE);
					r.kind = CRKind.REAL;
					r.numReal = to!(real)(vt.value);
				} else { mixin(S_TRACE);
					r.kind = CRKind.INT;
					r.numInt = to!(long)(vt.value);
				}
				return r;
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
				throwError(_prop.msgs.scriptErrorReqNumber, tok);
				auto r = new CalcResult;
				r.kind = CRKind.INT;
				r.numInt = 0;
				return r;
			}
		}
		bool min = false;
		if (tok.kind is Kind.PLU) { mixin(S_TRACE);
			i++;
			if (tokens[i].kind !is Kind.NUMBER) { mixin(S_TRACE);
				throwError(_prop.msgs.scriptErrorInvalidNumber, tok);
			}
		} else if (tok.kind is Kind.MIN) { mixin(S_TRACE);
			i++;
			if (tokens[i].kind !is Kind.NUMBER) { mixin(S_TRACE);
				throwError(_prop.msgs.scriptErrorInvalidNumber, tok);
			}
			min = true;
		}
		if (tokens.length <= i || !(tokens[i].kind is Kind.NUMBER || tokens[i].kind is Kind.STRING)) { mixin(S_TRACE);
			throwError(_prop.msgs.scriptErrorInvalidNumber, tok);
		}
		auto r = new CalcResult;
		try { mixin(S_TRACE);
			if (tokens[i].kind is Kind.NUMBER) { mixin(S_TRACE);
				if (std.string.indexOf(tokens[i].value, '.') != -1) { mixin(S_TRACE);
					r.kind = CRKind.REAL;
					r.numReal = to!(real)(tokens[i].value);
					if (min) r.numReal = -r.numReal;
				} else { mixin(S_TRACE);
					r.kind = CRKind.INT;
					r.numInt = to!(long)(tokens[i].value);
					if (min) r.numInt = -r.numInt;
				}
			} else if (tokens[i].kind is Kind.STRING) { mixin(S_TRACE);
				r.kind = CRKind.STR;
				r.str = stringValue(tokens[i], strWidth);
			} else { mixin(S_TRACE);
				throwError(_prop.msgs.scriptErrorReqNumber, tokens[i]);
			}
			i++;
			return r;
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
			throwError(_prop.msgs.scriptErrorReqNumber, tokens[i]);
		}
		return r;
	}
	private CalcResult calcPar(in Token[] tokens, ref size_t i, in const(Node)[][string] varTable, size_t strWidth) { mixin(S_TRACE);
		assert (i < tokens.length);
		auto tok = tokens[i];
		switch (tok.kind) {
		case Kind.O_PAR:
			i++;
			auto r = calcImpl(0, tokens, i, varTable, strWidth);
			if (tokens[i].kind !is Kind.C_PAR) { mixin(S_TRACE);
				throwError(_prop.msgs.scriptErrorCloseParenNotFound, tok);
			}
			i++;
			return r;
		default:
			return calcNum(tokens, i, varTable, strWidth);
		}
	}
	private CalcResult calcImpl(size_t opeLevel, in Token[] tokens, ref size_t i, in const(Node)[][string] varTable, size_t strWidth) { mixin(S_TRACE);
		assert (i < tokens.length);
		CalcResult r;
		if (opeLevel >= OPE_LEVEL_MAX) { mixin(S_TRACE);
			r = calcPar(tokens, i, varTable, strWidth);
		} else { mixin(S_TRACE);
			r = calcImpl(opeLevel + 1, tokens, i, varTable, strWidth);
		}
		while (i < tokens.length) { mixin(S_TRACE);
			auto tok = tokens[i];
			switch (opeLevel) {
			case 0:
				switch (tok.kind) {
				case Kind.CAT:
					i++;
					if (tokens.length < i) { mixin(S_TRACE);
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
					if (tokens.length < i) { mixin(S_TRACE);
						throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
						return r;
					}
					r.add(_prop, tok, calcImpl(1, tokens, i, varTable, strWidth));
					break;
				case Kind.MIN:
					i++;
					if (tokens.length < i) { mixin(S_TRACE);
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
					if (tokens.length <= i) { mixin(S_TRACE);
						throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
						return r;
					}
					r.mul(_prop, tok, calcPar(tokens, i, varTable, strWidth));
					break;
				case Kind.DIV:
					i++;
					if (tokens.length <= i) { mixin(S_TRACE);
						throwError(_prop.msgs.scriptErrorInvalidCalc, tok);
						return r;
					}
					r.div(_prop, tok, calcPar(tokens, i, varTable, strWidth));
					break;
				case Kind.RES:
					i++;
					if (tokens.length <= i) { mixin(S_TRACE);
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
	CalcResult calc(in Token[] tokens, ref size_t i, in const(Node)[][string] varTable, size_t strWidth) { mixin(S_TRACE);
		assert (i < tokens.length);
		return calcImpl(0, tokens, i, varTable, strWidth);
	} unittest { mixin(S_TRACE);
		debug mixin(UTPerf);
		size_t i;
		Token[] tokens;
		const(Node)[][string] varTable;
		auto tok = Token(0, 0, 0, Kind.NUMBER, "15");
		varTable["$abc"] = [Node(NodeType.VALUE, tok)];
		tok = Token(0, 0, 0, Kind.NUMBER, "0");
		varTable["$s"] = [Node(NodeType.VALUE, tok)];
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
	shared static this () { mixin(S_TRACE);
		auto keywords = [
			cast(string) "start":CType.Start,
			cast(string) "gobattle":CType.StartBattle,
			cast(string) "endsc":CType.End,
			cast(string) "gameover":CType.EndBadEnd,
			cast(string) "goarea":CType.ChangeArea,
			cast(string) "chback":CType.ChangeBgImage,
			cast(string) "effect":CType.Effect,
			cast(string) "break":CType.EffectBreak,
			cast(string) "gostart":CType.LinkStart,
			cast(string) "gopack":CType.LinkPackage,
			cast(string) "msg":CType.TalkMessage,
			cast(string) "dialog":CType.TalkDialog,
			cast(string) "bgm":CType.PlayBgm,
			cast(string) "se":CType.PlaySound,
			cast(string) "wait":CType.Wait,
			cast(string) "elapse":CType.ElapseTime,
			cast(string) "callstart":CType.CallStart,
			cast(string) "callpack":CType.CallPackage,
			cast(string) "brflag":CType.BranchFlag,
			cast(string) "brstepm":CType.BranchMultiStep,
			cast(string) "brstept":CType.BranchStep,
			cast(string) "selmember":CType.BranchSelect,
			cast(string) "brability":CType.BranchAbility,
			cast(string) "brrandom":CType.BranchRandom,
			cast(string) "brlevel":CType.BranchLevel,
			cast(string) "brstatus":CType.BranchStatus,
			cast(string) "brcount":CType.BranchPartyNumber,
			cast(string) "brarea":CType.BranchArea,
			cast(string) "brbattle":CType.BranchBattle,
			cast(string) "bronbattle":CType.BranchIsBattle,
			cast(string) "brcast":CType.BranchCast,
			cast(string) "britem":CType.BranchItem,
			cast(string) "brskill":CType.BranchSkill,
			cast(string) "brinfo":CType.BranchInfo,
			cast(string) "brbeast":CType.BranchBeast,
			cast(string) "brmoney":CType.BranchMoney,
			cast(string) "brcoupon":CType.BranchCoupon,
			cast(string) "brstamp":CType.BranchCompleteStamp,
			cast(string) "brgossip":CType.BranchGossip,
			cast(string) "setflag":CType.SetFlag,
			cast(string) "setstep":CType.SetStep,
			cast(string) "stepup":CType.SetStepUp,
			cast(string) "stepdown":CType.SetStepDown,
			cast(string) "revflag":CType.ReverseFlag,
			cast(string) "chkflag":CType.CheckFlag,
			cast(string) "getcast":CType.GetCast,
			cast(string) "getitem":CType.GetItem,
			cast(string) "getskill":CType.GetSkill,
			cast(string) "getinfo":CType.GetInfo,
			cast(string) "getbeast":CType.GetBeast,
			cast(string) "getmoney":CType.GetMoney,
			cast(string) "getcoupon":CType.GetCoupon,
			cast(string) "getstamp":CType.GetCompleteStamp,
			cast(string) "getgossip":CType.GetGossip,
			cast(string) "losecast":CType.LoseCast,
			cast(string) "loseitem":CType.LoseItem,
			cast(string) "loseskill":CType.LoseSkill,
			cast(string) "loseinfo":CType.LoseInfo,
			cast(string) "losebeast":CType.LoseBeast,
			cast(string) "losemoney":CType.LoseMoney,
			cast(string) "losecoupon":CType.LoseCoupon,
			cast(string) "losestamp":CType.LoseCompleteStamp,
			cast(string) "losegossip":CType.LoseGossip,
			cast(string) "showparty":CType.ShowParty,
			cast(string) "hideparty":CType.HideParty,
			cast(string) "redraw":CType.Redisplay,
			cast(string) "cpstep":CType.SubstituteStep,
			cast(string) "cpflag":CType.SubstituteFlag,
			cast(string) "cmpstep":CType.BranchStepCmp,
			cast(string) "cmpflag":CType.BranchFlagCmp,
			cast(string) "selrandom":CType.BranchRandomSelect,
			cast(string) "brkeycode":CType.BranchKeyCode,
			cast(string) "chkstep":CType.CheckStep,
			cast(string) "brround":CType.BranchRound,
			cast(string) "mvback":CType.MoveBgImage, // Wsn.1
			cast(string) "rplback":CType.ReplaceBgImage, // Wsn.1
			cast(string) "loseback":CType.LoseBgImage, // Wsn.1
			cast(string) "brcouponm":CType.BranchMultiCoupon, // Wsn.2
			cast(string) "brrandomm":CType.BranchMultiRandom, // Wsn.2
			cast(string) "mvcard":CType.MoveCard, // Wsn.3
			cast(string) "chenv":CType.ChangeEnvironment, // Wsn.4
			cast(string) "brvar":CType.BranchVariant, // Wsn.4
			cast(string) "setvar":CType.SetVariant, // Wsn.4
			cast(string) "chkvar":CType.CheckVariant, // Wsn.4
		];
		string[CType] commands;
		foreach (name, type; keywords) { mixin(S_TRACE);
			commands[type] = name;
		}
		KEYS = Keywords(.assumeUnique(keywords), .assumeUnique(commands));
	}

	/// ノードの型。
	enum NodeType {
		VAR_SET, /// 変数の設定。
		START, /// イベントツリーの起点。
		COMMAND, /// イベントコンテント。
		ARRAY, /// 配列。
		VALUES, /// 複合値。
		VALUE, /// 値。
	}

	/// スクリプトの解析結果として生成されるノード。
	struct Node {
		NodeType type; /// 型。
		Token token; /// 先頭のToken。
		const(Node)[] texts = []; /// テキスト。
		const(Node)[] attr; /// 属性。
		const(Node)[] childs; /// 子ノード。
		bool nextIsChild; /// 唯一の子ノードが次にあるか。
		alias childs values; /// ノードがARRAYかVALUESの場合は格納されたVALUEノードの配列。
		const(Token)[] calc; /// 計算式。
		alias calc var; /// 変数。
		alias texts value; /// 変数値。
		const(Node)[] beforeVars; /// ノードの直前に宣言された変数群。
		/// oと等しいか。
		const
		bool opEquals(ref const(Node) o) { mixin(S_TRACE);
			return type == o.type && token == o.token && texts == o.texts
				&& attr == o.attr && childs == o.childs && calc == o.calc
				&& beforeVars == o.beforeVars;
		}
		/// コピーを生成する。
		@property
		const
		Node dup() { mixin(S_TRACE);
			return Node(type, token, texts.dup, attr.dup, childs.dup, nextIsChild, calc.dup, beforeVars.dup);
		}
		/// 文字列表現。
		const
		string toString() {
			auto r = "Node {" ~ .text(type);
			r ~= ", " ~ token.toString();
			r ~= ", " ~ .text(texts);
			r ~= ", " ~ .text(attr);
			r ~= ", " ~ .text(childs);
			r ~= "}";
			return r;
		}
		/// ノード群をスクリプトコードにして返す。
		static string code(string indent, in Node[] array) { return code("    ", "", "", array, "sif"); }
		private static string code(string indent, string bIndentValue, string indentValue, in Node[] array, string ifString) { mixin(S_TRACE);
			string calcCode(in Node[] calc) { mixin(S_TRACE);
				char[] calcBuf;
				enforce(1 == calc.length);
				foreach (i, tok; calc[0].calc) { mixin(S_TRACE);
					if ((tok.kind is Kind.C_PAR)
							|| (i > 0 && calc[0].calc[i - 1].kind is Kind.O_PAR)) { mixin(S_TRACE);
						calcBuf ~= tok.value;
					} else { mixin(S_TRACE);
						if (i > 0) calcBuf ~= " ";
						calcBuf ~= tok.value;
					}
				}
				return assumeUnique(calcBuf);
			}
			string buf = "";
			if (!array.length) return buf;

			foreach (node; array) { mixin(S_TRACE);
				if (buf.length) { mixin(S_TRACE);
					buf ~= "\n";
				}
				if (node.type is NodeType.COMMAND && node.texts.length) { mixin(S_TRACE);
					buf ~= .format("%s%s %s\n", ifString == "sif" ? indentValue : bIndentValue, ifString, calcCode(node.texts));
					ifString = "sif";
				}
				if (node.type is NodeType.VAR_SET) { mixin(S_TRACE);
					enforce(node.value.length > 0, new Exception("Invalid node", __FILE__, __LINE__));
					if (node.value[0].token.kind is Kind.STRING) { mixin(S_TRACE);
						buf ~= .format("%s%s = %s", indentValue, node.token.value, node.value[0].token.value);
					} else { mixin(S_TRACE);
						buf ~= .format("%s%s = %s", node.token.value, indentValue, calcCode(node.value));
					}
					continue;
				} else if (node.type is NodeType.VALUE) { mixin(S_TRACE);
					if (node.var.length <= 1) { mixin(S_TRACE);
						buf ~= node.token.value;
					} else { mixin(S_TRACE);
						buf ~= calcCode([node]);
					}
					continue;
				} else if (node.type is NodeType.VALUES) { mixin(S_TRACE);
					string vals = "[";
					foreach (i, c; node.values) { mixin(S_TRACE);
						if (i > 0) vals ~= ", ";
						vals ~= Node.code(indent, [c]);
					}
					vals ~= "]";
					buf ~= vals;
					continue;
				} else if (node.type is NodeType.ARRAY) { mixin(S_TRACE);
					string[] vals = [];
					foreach (i, c; node.values) { mixin(S_TRACE);
						vals ~= Node.code(indent, [c]);
					}
					buf ~= std.string.join(vals, " ");
					continue;
				}
				foreach (i, var; node.beforeVars) { mixin(S_TRACE);
					buf ~= .format("%s%s\n", indentValue, Node.code(indent, [var]));
				}
				string attrs = "";
				if (node.token.kind is Kind.START) { mixin(S_TRACE);
					attrs = " " ~ calcCode(node.texts);
				} else { mixin(S_TRACE);
					foreach (i, a; node.attr) { mixin(S_TRACE);
						auto ac = Node.code(indent, [a]);
						if (a.type is NodeType.VALUES && i > 0) { mixin(S_TRACE);
							attrs ~= "\n";
							attrs ~= indentValue;
							attrs ~= .rightJustify("", node.token.value.length + 1);
							attrs ~= ac;
						} else { mixin(S_TRACE);
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
				foreach (i, c; node.childs) { mixin(S_TRACE);
					if (startBlock && nextIsStartPoint) { mixin(S_TRACE);
						block ~= new const(Node)[0];
					}
					startBlock = false;
					if (c.type !is NodeType.VAR_SET) { mixin(S_TRACE);
						nextIsStartPoint = !c.nextIsChild;
						startBlock = true;
					}
					block[$ - 1] ~= c;
				}
				if (block.length > 1) { mixin(S_TRACE);
					foreach (i, b; block) { mixin(S_TRACE);
						string f = i == 0 ? "if" : "elif";
						buf ~= "\n";
						buf ~= Node.code(indent, indentValue, indentValue ~ indent, b, f);
					}
					buf ~= "\n";
					buf ~= indentValue ~ "fi";
				} else if (block.length == 1) { mixin(S_TRACE);
					buf ~= "\n";
					buf ~= Node.code(indent, indentValue, node.token.kind is Kind.START ? indentValue ~ indent : indentValue, block[0], "sif");
				}
			}
			return buf;
		}
	}

	/// 属性値を文字列にして返す。
	private string attrValue(in Node node, in const(Node)[][string] varTable, size_t strWidth) { mixin(S_TRACE);
		switch (node.token.kind) {
		case Kind.SYMBOL: return std.string.toLower(node.token.value);
		case Kind.VAR_NAME:
			if (1 < node.calc.length) goto case Kind.STRING;
			auto nodes = var(node, varTable);
			if (!nodes.length) return "";
			auto tok = nodes[0].token;
			if (tok.kind is Kind.STRING) { mixin(S_TRACE);
				return stringValue(tok, strWidth);
			} else if (tok.kind is Kind.SYMBOL) { mixin(S_TRACE);
				return std.string.toLower(tok.value);
			}
			return attrValue(nodes[0], varTable, strWidth);
		case Kind.STRING, Kind.NUMBER, Kind.PLU, Kind.MIN, Kind.O_PAR:
			size_t i = 0;
			if (!node.calc.length) { mixin(S_TRACE);
				throwError(_prop.msgs.scriptErrorInvalidAttr, node.token);
				return "";
			}
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
	private const(Node)[] varValue(in Node node, const(Node)[] values, in const(Node)[][string] varTable, size_t strWidth) { mixin(S_TRACE);
		if (!values.length) { mixin(S_TRACE);
			throwError(_prop.msgs.scriptErrorInvalidVar, node.token);
			return values;
		}
		const(Node)[] r;
		foreach (v; values) { mixin(S_TRACE);
			const(Node)[] vs;
			if (v.token.kind is Kind.VAR_NAME) { mixin(S_TRACE);
				vs ~= var(v, varTable);
			} else { mixin(S_TRACE);
				vs = [v];
			}
			foreach (v2; vs) { mixin(S_TRACE);
				switch (v2.token.kind) {
				case Kind.STRING, Kind.NUMBER, Kind.PLU, Kind.MIN, Kind.O_PAR:
					// 値。計算もここで行う
					size_t i = 0;
					Node rNode = v2.dup;
					if (!v2.calc.length) { mixin(S_TRACE);
						throwError(_prop.msgs.scriptErrorInvalidAttr, v2.token);
						break;
					}
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
	private const(Node)[] var(in Node[] nodes, in const(Node)[][string] varTable) { mixin(S_TRACE);
		const(Node)[] r;
		foreach (node; nodes) { mixin(S_TRACE);
			r ~= var(node, varTable);
		}
		return r;
	}
	private const(Node)[] var(in Node node, in const(Node)[][string] varTable) { mixin(S_TRACE);
		if (node.token.kind is Kind.VAR_NAME) { mixin(S_TRACE);
			auto ptr = std.string.toLower(node.token.value) in varTable;
			if (ptr) { mixin(S_TRACE);
				const(Node)[] r;
				foreach (v; *ptr) { mixin(S_TRACE);
					r ~= var(v, varTable);
				}
				return r;
			}
			throwError(_prop.msgs.scriptErrorUndefinedVar, node.token);
			return [];
		}
		return [node];
	}
	private Token var(in Token tok, in const(Node)[][string] varTable) { mixin(S_TRACE);
		if (tok.kind is Kind.VAR_NAME) { mixin(S_TRACE);
			auto ptr = std.string.toLower(tok.value) in varTable;
			if (ptr && ptr.length) { mixin(S_TRACE);
				return var((*ptr)[0].token, varTable);
			}
			throwError(_prop.msgs.scriptErrorUndefinedVar, tok);
		}
		return tok;
	}

	/// tokensを解釈し、Nodeのツリーに再編成する。
	Node[] analyzeSyntax(in Token[] tokens) { mixin(S_TRACE);
		Node[] r;
		size_t i = 0;
		Node[] vars;
		const(Token)[] tokens2;
		foreach (ref tok; tokens) { mixin(S_TRACE);
			if (tok.kind !is Kind.COMMENT) { mixin(S_TRACE);
				tokens2 ~= tok;
			}
		}
		while (i < tokens2.length) { mixin(S_TRACE);
			vars ~= eatVarSet(tokens2, i, KEYS);
			if (tokens2.length <= i) { mixin(S_TRACE);
				break;
			}
			Token tok = tokens2[i];
			if (tok.kind !is Kind.START) { mixin(S_TRACE);
				r ~= analyzeSyntaxBranch(tokens2, i, KEYS, vars);
				continue;
			}
			i++;
			Node node;
			node.type = NodeType.START;
			node.token = tok;
			node.texts = analyzeSyntaxAttr(tokens2, i, KEYS);
			if (!node.texts.length) { mixin(S_TRACE);
				throwError(_prop.msgs.scriptErrorNoStartText, tok);
			}
			node.beforeVars = vars;
			vars = [];
			node.nextIsChild = false;
			c: while (i < tokens2.length) { mixin(S_TRACE);
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
	} unittest { mixin(S_TRACE);
		debug mixin(UTPerf);
		auto s = new CWXScript(new CProps("", null), null);

		string statement0
= `msg 'a.bmp' 'b.bmp', 'Msg.'
msg M, @ 3
Talk!
Talk!
Talk!
@`;
		auto tokens0 = s.tokenize(statement0);
		auto starts0 = s.analyzeSyntax(tokens0);
		assert (Node.code("    ", starts0)
			== "msg 'a.bmp' 'b.bmp', 'Msg.'\n"
			~ "msg M, @ 3\n"
			~ "Talk!\n"
			~ "Talk!\n"
			~ "Talk!\n"
			~ "@", Node.code("    ", starts0));

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
    msg 'a.bmp' 'b.bmp', 'Msg.'
    msg M, @ 3
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
			~ "    chback ['mapofwirth.bmp', '', 0, 0, 632, 420] ['definn.bmp', '', 50, 50, 200 * 2, 260] ['card.bmp', 'card\\mate1', 230, 50, 74, 94, mask], 1\n"
			~ "    hideparty\n"
			~ "    $var2 = 3.5\n"
			~ "    wait ($var2 + 1.5)\n"
			~ "    msg 'a.bmp' 'b.bmp', 'Msg.'\n"
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

	private Node[] analyzeSyntaxBranch(in Token[] tokens, ref size_t i, in Keywords keys, ref Node[] vars) { mixin(S_TRACE);
		Node[] r;
		auto tok = tokens[i];
		switch (tok.kind) {
		case Kind.START: return r;
		case Kind.IF, Kind.VAR_NAME:
			while (i < tokens.length) { mixin(S_TRACE);
				Node[] texts;
				if (tokens[i].kind is Kind.IF || tokens[i].kind is Kind.ELIF) { mixin(S_TRACE);
					i++;
					texts = analyzeSyntaxAttr(tokens, i, keys);
					if (tokens.length <= i) { mixin(S_TRACE);
						throwError(_prop.msgs.scriptErrorNoIfContents, tok);
					}
				}
				auto node = analyzeSyntaxStatement(tokens, i, keys, vars);
				if (node.length) { mixin(S_TRACE);
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
	private Node[] eatVarSet(in Token[] tokens, ref size_t i, in Keywords keys) { mixin(S_TRACE);
		Node[] r;
		while (i < tokens.length && tokens[i].kind is Kind.VAR_NAME) { mixin(S_TRACE);
			r ~= analyzeSyntaxVar(tokens, i, keys);
		}
		return r;
	}
	private Node[] analyzeSyntaxStatement(in Token[] tokens, ref size_t i, in Keywords keys, ref Node[] vars) { mixin(S_TRACE);
		Node[] r;
		while (true) { mixin(S_TRACE);
			assert (i < tokens.length);
			vars ~= eatVarSet(tokens, i, keys);
			Token tok = tokens[i];
			Node[] sifTexts;
			if (tok.kind is Kind.SIF) { mixin(S_TRACE);
				i++;
				if (tokens.length <= i) { mixin(S_TRACE);
					sifTexts = [];
				} else { mixin(S_TRACE);
					sifTexts = analyzeSyntaxAttr(tokens, i, keys);
					if (tokens.length <= i) { mixin(S_TRACE);
						throwError(_prop.msgs.scriptErrorInvalidSif, tok);
					}
				}
				tok = tokens[i];
			} else if (tok.kind !is Kind.SYMBOL) { mixin(S_TRACE);
				throwError(_prop.msgs.scriptErrorInvalidStatement, tok);
			}
			Node node;
			node.type = NodeType.COMMAND;
			node.token = tok;
			node.texts = sifTexts;
			node.nextIsChild = false;
			auto symbol = std.string.toLower(tok.value);
			if (!(symbol in keys.keywords)) { mixin(S_TRACE);
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
	}
	private Node[] analyzeSyntaxAttr(in Token[] tokens, ref size_t i, in Keywords keys) { mixin(S_TRACE);
		Node[] r;
		auto lastKind = Kind.COMMA;
		while (i < tokens.length) { mixin(S_TRACE);
			Token tok = tokens[i];
			if (r.length > 0 && tok.kind is Kind.COMMA) { mixin(S_TRACE);
				lastKind = Kind.COMMA;
				i++;
				if (tokens.length <= i) return r;
				tok = tokens[i];
			}
			void putArray(ref Node node) { mixin(S_TRACE);
				if (lastKind == Kind.COMMA || r.length == 0) { mixin(S_TRACE);
					// 一つ目の要素
					r ~= node;
				} else if (r[$ - 1].type == NodeType.ARRAY) { mixin(S_TRACE);
					// 配列に追加
					r[$ - 1].values ~= node;
				} else { mixin(S_TRACE);
					// 最初の値を配列の先頭に置き、その次に現在の値を置く
					Node value2 = node;
					node.token = r[$ - 1].token;
					node.type = NodeType.ARRAY;
					node.values = [r[$ - 1], value2];
					r[$ - 1] = node;
				}
			}
			switch (tok.kind) {
			case Kind.O_BRA:
				auto node = analyzeSyntaxBrackets(tokens, i, keys);
				putArray(node);
				break;
			case Kind.START, Kind.IF, Kind.ELIF, Kind.FI, Kind.SIF, Kind.C_BRA:
				return r;
			case Kind.SYMBOL, Kind.NUMBER, Kind.STRING, Kind.PLU, Kind.MIN, Kind.O_PAR:
				if (std.string.toLower(tok.value) in keys.keywords) { mixin(S_TRACE);
					return r;
				}
				Node node;
				node.type = NodeType.VALUE;
				node.token = tok;
				node.var = analyzeSyntaxValue(tokens, i, keys);
				putArray(node);
				break;
			case Kind.VAR_NAME:
				if (i + 1 < tokens.length && tokens[i + 1].kind is Kind.EQ) { mixin(S_TRACE);
					return r;
				}
				goto case Kind.SYMBOL;
			case Kind.COMMA:
				// いきなり','が現れた場合は長さ0の配列とする
				Node node;
				node.type = NodeType.ARRAY;
				node.token = tok;
				node.var = [];
				r ~= node;
				i++;
				break;
			default:
				throwError(_prop.msgs.scriptErrorInvalidAttr, tok);
				i++;
			}
			lastKind = tok.kind;
		}
		return r;
	} unittest { mixin(S_TRACE);
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
	private Node analyzeSyntaxBrackets(in Token[] tokens, ref size_t i, in Keywords keys) { mixin(S_TRACE);
		assert (i < tokens.length);
		auto o = tokens[i];
		if (o.kind !is Kind.O_BRA) { mixin(S_TRACE);
			throwError(_prop.msgs.scriptErrorInvalidValuesOpen, o);
		}
		Node r;
		r.type = NodeType.VALUES;
		r.token = o;
		i++;
		r.values = analyzeSyntaxAttr(tokens, i, keys);
		if (tokens.length <= i || tokens[i].kind != Kind.C_BRA) { mixin(S_TRACE);
			throwError(_prop.msgs.scriptErrorCloseBracketNotFound, o);
		} else { mixin(S_TRACE);
			i++;
		}
		return r;
	}
	private Node analyzeSyntaxVar(in Token[] tokens, ref size_t i, in Keywords keys) { mixin(S_TRACE);
		assert (i < tokens.length);
		auto tok = tokens[i];
		if (tok.kind !is Kind.VAR_NAME) { mixin(S_TRACE);
			throwError(_prop.msgs.scriptErrorInvalidVar, tok);
		}
		i++;
		if (tokens.length <= i || tokens[i].kind !is Kind.EQ) { mixin(S_TRACE);
			throwError(_prop.msgs.scriptErrorNoVarSet, tokens[i]);
		}
		Node node;
		node.type = NodeType.VAR_SET;
		node.token = tok;
		i++;
		if (tokens.length <= i) { mixin(S_TRACE);
			throwError(_prop.msgs.scriptErrorNoVarVal, tok);
		}
		node.value = analyzeSyntaxAttr(tokens, i, keys);
		return node;
	}
	private Token[] analyzeSyntaxValue(in Token[] tokens, ref size_t i, in Keywords keys) { mixin(S_TRACE);
		Token[] r;
		bool calcin = false;
		bool num = true;
		while (i < tokens.length) { mixin(S_TRACE);
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
				if (num) { mixin(S_TRACE);
					r ~= tok;
					i++;
					r ~= tokens[i];
					i++;
					calcin = true;
					num = false;
					break;
				} else { mixin(S_TRACE);
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
				if (!calcin) { mixin(S_TRACE);
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

	private T parseAttr(T, bool Within = false)(in CompileOption opt, in Node[] attr, ref size_t i, lazy T defValue, in const(Node)[][string] varTable, size_t msgWidth) { mixin(S_TRACE);
		if (attr.length <= i) return defValue;
		static if (is(T == string)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			if (attr[i].token.kind is Kind.SYMBOL && value == "stop") { mixin(S_TRACE);
				/// BGM停止用
				i++;
				return "";
			} else if (attr[i].token.kind is Kind.SYMBOL && value == "random") { mixin(S_TRACE);
				/// ステップ・フラグ代入のランダム値
				i++;
				return _prop.sys.randomValue;
			} else if (attr[i].token.kind is Kind.SYMBOL && (value == "m" || value == "selected")) { mixin(S_TRACE);
				/// 選択メンバ番号(Wsn.2)
				i++;
				return _prop.sys.selectedPlayerCardNumber;
			}
			i++;
			return value;
		} else static if (is(T == CastRange[])) {
			T r;
			crw: while (i < attr.length) { mixin(S_TRACE);
				auto value = attrValue(attr[i], varTable, msgWidth);
				switch (value) {
				case "field": r ~= [CastRange.Party, CastRange.Enemy, CastRange.Npc]; break;
				case "party", "t", "team": r ~= CastRange.Party; break;
				case "enemy": r ~= CastRange.Enemy; break;
				case "npc": r ~= CastRange.Npc; break;
				default: break crw;
				}
				i++;
			}
			r = r.sort().uniq().array();
			return r;
		} else static if (isVArray!(T)) {
			T r;
			if (i < attr.length) { mixin(S_TRACE);
				auto values = var(attr[i], varTable);
				if (values.length) { mixin(S_TRACE);
					size_t i2 = 0;
					if (values[0].type is NodeType.ARRAY) { mixin(S_TRACE);
						values = values[0].values;
					}
					while (i2 < values.length) { mixin(S_TRACE);
						if (!values.length) break;
						if (values[0].token.kind is Kind.COMMA) { mixin(S_TRACE);
							// 空の配列
							break;
						}
						r ~= parseAttr!(ElementType!(T), Within)(opt, values, i2, ElementType!(T).init, varTable, msgWidth);
						if (0 == i2) break;
					}
				}
				i++;
			}
			return r;
		} else static if (is(T == bool)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "true", "yes", "on", "all", "average", "complete":
				i++;
				return true;
			case "false", "no", "off", "active", "max", "nocomplete":
				i++;
				return false;
			default: throwError(_prop.msgs.scriptErrorInvalidBoolVal, attr[i].token);
			}
			return T.init;
		} else static if (is(T == Transition)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "default": i++; return Transition.Default;
			case "none": i++; return Transition.None;
			case "blinds", "thread": i++; return Transition.Blinds;
			case "dissolve", "shave": i++; return Transition.PixelDissolve;
			case "fade": i++; return Transition.Fade;
			default: throwError(_prop.msgs.scriptErrorInvalidTransition, attr[i].token);
			}
			return T.init;
		} else static if (is(T == Range)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "m", "selected": i++; return Range.Selected;
			case "r", "random", "one": i++; return Range.Random;
			case "t", "team": i++; return Range.Party;
			case "coupon": i++; return Range.CouponHolder;
			case "card": i++; return Range.CardTarget;
			case "backpack":
				static if (Within) goto default;
				i++;
				return Range.Backpack;
			case "party":
				static if (Within) goto case "team";
				i++;
				return Range.PartyAndBackpack;
			case "field":
				static if (Within) goto default;
				i++;
				return Range.Field;
			case "selcard": i++; return Range.SelectedCard;
			default: throwError(_prop.msgs.scriptErrorInvalidRange, attr[i].token);
			}
			return T.init;
		} else static if (is(T == Status)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "active": i++; return Status.Active;
			case "inactive": i++; return Status.Inactive;
			case "alive": i++; return Status.Alive;
			case "dead": i++; return Status.Dead;
			case "fine": i++; return Status.Fine;
			case "injured": i++; return Status.Injured;
			case "heavyinjured": i++; return Status.HeavyInjured;
			case "unconscious": i++; return Status.Unconscious;
			case "poison": i++; return Status.Poison;
			case "sleep": i++; return Status.Sleep;
			case "bind": i++; return Status.Bind;
			case "paralyze": i++; return Status.Paralyze;
			case "confuse": i++; return Status.Confuse;
			case "overheat": i++; return Status.Overheat;
			case "brave": i++; return Status.Brave;
			case "panic": i++; return Status.Panic;
			case "silence": i++; return Status.Silence;
			case "faceup": i++; return Status.FaceUp;
			case "antimagic": i++; return Status.AntiMagic;
			case "upaction": i++; return Status.UpAction;
			case "upavoid": i++; return Status.UpAvoid;
			case "upresist": i++; return Status.UpResist;
			case "updefense": i++; return Status.UpDefense;
			case "downaction": i++; return Status.DownAction;
			case "downavoid": i++; return Status.DownAvoid;
			case "downresist": i++; return Status.DownResist;
			case "downdefense": i++; return Status.DownDefense;
			case "none": i++; return Status.None;
			default: throwError(_prop.msgs.scriptErrorInvalidStatus, attr[i].token);
			}
			return T.init;
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
				return Target(Target.M.Selected, sleep);
			case "r", "random", "one":
				i++;
				static if (!Within) i++;
				return Target(Target.M.Random, sleep);
			case "u", "unselected":
				i++;
				static if (!Within) i++;
				return Target(Target.M.Unselected, sleep);
			case "t", "team":
				i++;
				static if (!Within) i++;
				return Target(Target.M.Party, sleep);
			default: throwError(_prop.msgs.scriptErrorInvalidTarget, attr[i].token);
			}
			return T.init;
		} else static if (is(T == EffectType)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "physic": i++; return EffectType.Physic;
			case "magic": i++; return EffectType.Magic;
			case "mphysic": i++; return EffectType.MagicalPhysic;
			case "pmagic": i++; return EffectType.PhysicalMagic;
			case "none": i++; return EffectType.None;
			default: throwError(_prop.msgs.scriptErrorInvalidEffectType, attr[i].token);
			}
			return T.init;
		} else static if (is(T == Resist)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "avoid": i++; return Resist.Avoid;
			case "resist": i++; return Resist.Resist;
			case "unfail": i++; return Resist.Unfail;
			default: throwError(_prop.msgs.scriptErrorInvalidResist, attr[i].token);
			}
			return T.init;
		} else static if (is(T == CardVisual)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "none": i++; return CardVisual.None;
			case "reverse": i++; return CardVisual.Reverse;
			case "hswing": i++; return CardVisual.Horizontal;
			case "vswing": i++; return CardVisual.Vertical;
			default: throwError(_prop.msgs.scriptErrorInvalidCardVisual, attr[i].token);
			}
			return T.init;
		} else static if (is(T == Mental)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "agg": i++; return Mental.Aggressive;
			case "unagg": i++; return Mental.Unaggressive;
			case "cheerf": i++; return Mental.Cheerful;
			case "uncheerf": i++; return Mental.Uncheerful;
			case "brave": i++; return Mental.Brave;
			case "unbrave": i++; return Mental.Unbrave;
			case "caut": i++; return Mental.Cautious;
			case "uncaut": i++; return Mental.Uncautious;
			case "trick": i++; return Mental.Trickish;
			case "untrick": i++; return Mental.Untrickish;
			default: throwError(_prop.msgs.scriptErrorInvalidMental, attr[i].token);
			}
			return T.init;
		} else static if (is(T == Physical)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "dex": i++; return Physical.Dex;
			case "agl": i++; return Physical.Agl;
			case "int": i++; return Physical.Int;
			case "str": i++; return Physical.Str;
			case "vit": i++; return Physical.Vit;
			case "min": i++; return Physical.Min;
			default: throwError(_prop.msgs.scriptErrorInvalidPhysical, attr[i].token);
			}
			return T.init;
		} else static if (is(T == Talker)) {
			return parseTalker!(Within)(attr, i, varTable);
		} else static if (is(T == MType)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "heal": i++; return MType.Heal;
			case "damage": i++; return MType.Damage;
			case "absorb": i++; return MType.Absorb;
			case "paralyze": i++; return MType.Paralyze;
			case "disparalyze": i++; return MType.DisParalyze;
			case "poison": i++; return MType.Poison;
			case "dispoison": i++; return MType.DisPoison;
			case "getspilit": i++; return MType.GetSkillPower;
			case "losespilit": i++; return MType.LoseSkillPower;
			case "sleep": i++; return MType.Sleep;
			case "confuse": i++; return MType.Confuse;
			case "overheat": i++; return MType.Overheat;
			case "brave": i++; return MType.Brave;
			case "panic": i++; return MType.Panic;
			case "resetmind": i++; return MType.Normal;
			case "bind": i++; return MType.Bind;
			case "disbind": i++; return MType.DisBind;
			case "silence": i++; return MType.Silence;
			case "dissilence": i++; return MType.DisSilence;
			case "faceup": i++; return MType.FaceUp;
			case "facedown": i++; return MType.FaceDown;
			case "antimagic": i++; return MType.AntiMagic;
			case "disantimagic": i++; return MType.DisAntiMagic;
			case "enhaction": i++; return MType.EnhanceAction;
			case "enhavoid": i++; return MType.EnhanceAvoid;
			case "enhresist": i++; return MType.EnhanceResist;
			case "enhdefense": i++; return MType.EnhanceDefense;
			case "vantarget": i++; return MType.VanishTarget;
			case "vancard": i++; return MType.VanishCard;
			case "vanbeast": i++; return MType.VanishBeast;
			case "dealattack": i++; return MType.DealAttackCard;
			case "dealpowerful": i++; return MType.DealPowerfulAttackCard;
			case "dealcritical": i++; return MType.DealCriticalAttackCard;
			case "dealfeint": i++; return MType.DealFeintCard;
			case "dealdefense": i++; return MType.DealDefenseCard;
			case "dealdistance": i++; return MType.DealDistanceCard;
			case "dealconfuse": i++; return MType.DealConfuseCard;
			case "dealskill": i++; return MType.DealSkillCard;
			case "summon": i++; return MType.SummonBeast;
			case "cancelaction": i++; return MType.CancelAction;
			case "noeffect", "none": i++; return MType.NoEffect;
			default: throwError(_prop.msgs.scriptErrorInvalidMotionType, attr[i].token);
			}
			return T.init;
		} else static if (is(T == Element)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "all": i++; return Element.All;
			case "phy": i++; return Element.Health;
			case "mind": i++; return Element.Mind;
			case "holy": i++; return Element.Miracle;
			case "magic": i++; return Element.Magic;
			case "fire": i++; return Element.Fire;
			case "ice": i++; return Element.Ice;
			default: throwError(_prop.msgs.scriptErrorInvalidElement, attr[i].token);
			}
			return T.init;
		} else static if (is(T == DamageType)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "level": i++; return DamageType.LevelRatio;
			case "value": i++; return DamageType.Normal;
			case "max": i++; return DamageType.Max;
			default: throwError(_prop.msgs.scriptErrorInvalidDamageType, attr[i].token);
			}
			return T.init;
		} else static if (is(T == EffectCardType)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "all": i++; return EffectCardType.All;
			case "skill": i++; return EffectCardType.Skill;
			case "item": i++; return EffectCardType.Item;
			case "beast": i++; return EffectCardType.Beast;
			case "hand": i++; return EffectCardType.Hand;
			default: throwError(_prop.msgs.scriptErrorInvalidEffectCardType, attr[i].token);
			}
			return T.init;
		} else static if (is(T == Comparison4)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "=": i++; return Comparison4.Eq;
			case "<>", "!=": i++; return Comparison4.Ne;
			case ">": i++; return Comparison4.Lt;
			case "<": i++; return Comparison4.Gt;
			default: throwError(_prop.msgs.scriptErrorInvalidComparison4, attr[i].token);
			}
			return T.init;
		} else static if (is(T == Comparison3)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "=": i++; return Comparison3.Eq;
			case ">": i++; return Comparison3.Lt;
			case "<": i++; return Comparison3.Gt;
			default: throwError(_prop.msgs.scriptErrorInvalidComparison3, attr[i].token);
			}
			return T.init;
		} else static if (is(T == BlendMode)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "normal": i++; return BlendMode.Normal;
			case "add": i++; return BlendMode.Add;
			case "sub": i++; return BlendMode.Subtract;
			case "mul": i++; return BlendMode.Multiply;
			default: throwError(_prop.msgs.scriptErrorInvalidBlendMode, attr[i].token);
			}
			return T.init;
		} else static if (is(T == GradientDir)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "none": i++; return GradientDir.None;
			case "h", "horizontal": i++; return GradientDir.LeftToRight;
			case "v", "vertical": i++; return GradientDir.TopToBottom;
			default: throwError(_prop.msgs.scriptErrorInvalidGradientDir, attr[i].token);
			}
			return T.init;
		} else static if (is(T == SelectionMethod)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "manual": i++; return SelectionMethod.Manual;
			case "random": i++; return SelectionMethod.Random;
			case "valued": i++; return SelectionMethod.Valued;
			default: throwError(_prop.msgs.scriptErrorInvalidSelectionMethod, attr[i].token);
			}
			return T.init;
		} else static if (is(T == StartAction)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "now": i++; return StartAction.Now;
			case "current": i++; return StartAction.CurrentRound;
			case "next": i++; return StartAction.NextRound;
			default: throwError(_prop.msgs.scriptErrorInvalidStartAction, attr[i].token);
			}
			return T.init;
		} else static if (is(T == CRGB)) {
			if (attr[i].type is NodeType.VALUES) { mixin(S_TRACE);
				auto vals = var(attr[i].values, varTable);
				size_t j = 0;
				int r = parseAttr!(int)(opt, vals, j, defValue.r, varTable, msgWidth);
				int g = parseAttr!(int)(opt, vals, j, defValue.g, varTable, msgWidth);
				int b = parseAttr!(int)(opt, vals, j, defValue.b, varTable, msgWidth);
				int a = parseAttr!(int)(opt, vals, j, defValue.a, varTable, msgWidth);
				i++;
				return CRGB(r, g, b, a);
			} else { mixin(S_TRACE);
				string value = parseAttr!(string)(opt, attr, i, "#000000", varTable, msgWidth);
				value = value.toLower();
				if (value.startsWith("#") && (7 == value.length || 9 == value.length)) { mixin(S_TRACE);
					foreach (c; value[1..$]) { mixin(S_TRACE);
						if (!(('0' <= c && c <= '9') || ('a' <= c && c <= 'f'))) { mixin(S_TRACE);
							throwError(_prop.msgs.scriptErrorInvalidColor, attr[i].token);
							return defValue;
						}
					}
					string val = value[1..3];
					int r = parse!int(val, 16);
					val = value[3..5];
					int g = parse!int(val, 16);
					val = value[5..7];
					int b = parse!int(val, 16);
					int a = 255;
					if (9 == value.length) { mixin(S_TRACE);
						val = value[7..9];
						a = parse!int(val, 16);
					}
					return CRGB(r, g, b, a);
				} else { mixin(S_TRACE);
					throwError(_prop.msgs.scriptErrorInvalidColor, attr[i].token);
					return defValue;
				}
			}
		} else static if (is(T == BgImage)) {
			if (attr[i].type !is NodeType.VALUES) { mixin(S_TRACE);
				throwError(_prop.msgs.scriptErrorInvalidBgImage, attr[i].token);
				return defValue;
			}
			auto vals = var(attr[i].values, varTable);
			string type = "image";
			if (vals && vals[0].token.kind is Kind.SYMBOL) { mixin(S_TRACE);
				type = attrValue(vals[0], varTable, msgWidth);
				vals = vals[1..$];
			}
			BgImage r;
			size_t j = 0;
			switch (type) {
			case "image":
				string path = decodePath(parseAttr!(string)(opt, vals, j, "", varTable, msgWidth));
				r = new ImageCell(path, "", 0, 0, 0, 0, false);
				break;
			case "text":
				string text = parseAttr!(string)(opt, vals, j, "", varTable, msgWidth);
				string fontName = parseAttr!(string)(opt, vals, j, "", varTable, msgWidth);
				int size = parseAttr!(int)(opt, vals, j, 18, varTable, msgWidth);
				CRGB color = parseAttr!(CRGB)(opt, vals, j, CRGB(0, 0, 0, 255), varTable, msgWidth);
				bool bold = false, italic = false, underline = false, strike = false, vertical = false, antialias = false;
				BorderingType borderingType = BorderingType.None;
				UpdateType updateType = UpdateType.Fixed;
				if (j < vals.length) { mixin(S_TRACE);
					if (vals[j].values.length || vals[j].type is NodeType.ARRAY) { mixin(S_TRACE);
						auto array = var(vals[j].values, varTable);
						auto j2 = 0;
						bgtw: while (j2 < array.length) { mixin(S_TRACE);
							switch (attrValue(array[j2], varTable, msgWidth)) {
							case "bold": j2++; bold = true; break;
							case "italic": j2++; italic = true; break;
							case "underline", "uline": j2++; underline = true; break;
							case "strike": j2++; strike = true; break;
							case "vertical": j2++; vertical = true; break;
							case "antialias": j2++; antialias = true; break;
							case "border1": j2++; borderingType = BorderingType.Outline; break;
							case "border2": j2++; borderingType = BorderingType.Inline; break;
							default:
								throwError(_prop.msgs.scriptErrorInvalidKeyword2, array[j2].token);
								return new ImageCell("", "", 0, 0, 0, 0, false);
							}
						}
						j++;
					} else if (vals[j].token.kind is Kind.SYMBOL) { mixin(S_TRACE);
						switch (attrValue(vals[j], varTable, 0)) {
						case "bold": bold = true; break;
						case "italic": italic = true; break;
						case "underline", "uline": underline = true; break;
						case "strike": strike = true; break;
						case "vertical": vertical = true; break;
						case "antialias": antialias = true; break;
						case "border1": borderingType = BorderingType.Outline; break;
						case "border2": borderingType = BorderingType.Inline; break;
						default:
							throwError(_prop.msgs.scriptErrorInvalidKeyword2, vals[j].token);
							return new ImageCell("", "", 0, 0, 0, 0, false);
						}
						j++;
					} else { mixin(S_TRACE);
						throwError(_prop.msgs.scriptErrorInvalidArray, vals[j].token);
						return new ImageCell("", "", 0, 0, 0, 0, false);
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
				r = new TextCell(text, fontName, size, color, bold, italic, underline, strike, vertical, antialias,
					borderingType, borderingColor, borderingWidth, updateType, "", 0, 0, 0, 0, false);
				break;
			case "color":
				BlendMode blendMode = parseAttr!(BlendMode)(opt, vals, j, BlendMode.Normal, varTable, msgWidth);
				CRGB color1 = parseAttr!(CRGB)(opt, vals, j, CRGB(255, 255, 255, 255), varTable, msgWidth);
				GradientDir gradientDir = GradientDir.None;
				CRGB color2 = color1;
				if (j < vals.length && vals[j].token.kind is Kind.SYMBOL) { mixin(S_TRACE);
					gradientDir = parseAttr!(GradientDir)(opt, vals, j, gradientDir, varTable, msgWidth);
					color2 = parseAttr!(CRGB)(opt, vals, j, color2, varTable, msgWidth);
				}
				r = new ColorCell(blendMode, gradientDir, color1, color2, "", 0, 0, 0, 0, false);
				break;
			case "pc":
				auto pcNumber = parseAttr!(int)(opt, vals, j, 1, varTable, msgWidth);
				auto expand = parseAttr!(bool)(opt, vals, j, false, varTable, msgWidth);
				r = new PCCell(pcNumber, expand, "", 0, 0, 0, 0, false);
				break;
			default:
				throwError(_prop.msgs.scriptErrorInvalidBgImage, attr[i].token);
				return defValue;
			}
			r.flag = parseAttr!(string)(opt, vals, j, "", varTable, msgWidth);
			r.x = parseAttr!(int)(opt, vals, j, 0, varTable, msgWidth);
			r.y = parseAttr!(int)(opt, vals, j, 0, varTable, msgWidth);
			auto size = _prop.looks.viewSize;
			r.width = parseAttr!(int)(opt, vals, j, cast(int) size.width, varTable, msgWidth);
			r.height = parseAttr!(int)(opt, vals, j, cast(int) size.height, varTable, msgWidth);
			if (cast(ImageCell)r) {
				r.mask = parseAttr!(bool)(opt, vals, j, r.mask, varTable, msgWidth);
			}
			r.cellName = parseAttr!(string)(opt, vals, j, r.cellName, varTable, msgWidth);
			r.layer = parseAttr!(int)(opt, vals, j, r.layer, varTable, msgWidth);
			if (auto ic = cast(ImageCell)r) { mixin(S_TRACE);
				ic.smoothing = parseAttr!(Smoothing)(opt, vals, j, ic.smoothing, varTable, msgWidth);
			} else if (auto pc = cast(PCCell)r) { mixin(S_TRACE);
				pc.smoothing = parseAttr!(Smoothing)(opt, vals, j, pc.smoothing, varTable, msgWidth);
			}
			if (auto tc = cast(TextCell)r) { mixin(S_TRACE);
				tc.updateType = parseAttr!(UpdateType)(opt, vals, j, tc.updateType, varTable, msgWidth);
			}
			i++;
			return r;
		} else static if (is(T == Motion)) {
			if (attr[i].type !is NodeType.VALUES) { mixin(S_TRACE);
				throwError(_prop.msgs.scriptErrorInvalidMotion, attr[i].token);
			}
			size_t j = 0;
			auto vals = var(attr[i].values, varTable);
			MType type = parseAttr!(MType)(opt, vals, j, MType.Heal, varTable, msgWidth);
			auto r = new Motion(type, Element.All);
			auto detail = r.detail;
			if (detail.use(MArg.ValueType)) { mixin(S_TRACE);
				r.damageType = parseAttr!(DamageType)(opt, vals, j, r.damageType, varTable, msgWidth);
			}
			if (detail.use(MArg.UValue)) { mixin(S_TRACE);
				r.uValue = parseAttr!(int)(opt, vals, j, cast(int) r.uValue, varTable, msgWidth);
			}
			if (detail.use(MArg.AValue)) { mixin(S_TRACE);
				r.aValue = parseAttr!(int)(opt, vals, j, r.aValue, varTable, msgWidth);
			}
			if (detail.use(MArg.Round)) { mixin(S_TRACE);
				r.round = parseAttr!(int)(opt, vals, j, r.round, varTable, msgWidth);
			}
			if (detail.use(MArg.Beast)) { mixin(S_TRACE);
				ulong beast = parseAttr!(ulong)(opt, vals, j, 0UL, varTable, msgWidth);
				if (beast != 0 && _summ) { mixin(S_TRACE);
					if (opt.linkId) { mixin(S_TRACE);
						r.beast = new BeastCard(_prop ? _prop.sys : null, 1UL, "", [], "");
						r.beast.linkId = beast;
					} else { mixin(S_TRACE);
						r.beast = _summ.beast(beast);
					}
				}
			}
			r.element = parseAttr!(Element)(opt, vals, j, Element.All, varTable, msgWidth);
			i++;
			return r;
		} else static if (is(T == SDialog)) {
			if (attr[i].type !is NodeType.VALUES) { mixin(S_TRACE);
				throwError(_prop.msgs.scriptErrorInvalidDialog, attr[i].token);
			}
			size_t j = 0;
			auto vals = var(attr[i].values, varTable);
			auto r = new SDialog;
			if (vals.length) { mixin(S_TRACE);
				if (vals[0].type is NodeType.ARRAY) { mixin(S_TRACE);
					// 複数の条件クーポン
					r.rCoupons = parseAttr!(string[])(opt, vals, j, [], varTable, msgWidth);
				} else { mixin(S_TRACE);
					// 一つの条件クーポン
					// ';'で分割される
					r.rCoupons = std.string.split(parseAttr!(string)(opt, vals, j, "", varTable, msgWidth), ";");
				}
			}
			r.text = parseAttr!(string)(opt, vals, j, r.text, varTable, msgWidth);
			i++;
			return r;
		} else static if (is(T == Coupon)) {
			if (attr[i].type !is NodeType.VALUES) { mixin(S_TRACE);
				string name = attrValue(attr[i], varTable, msgWidth);
				i++;
				return new Coupon(name, 1);
			}
			size_t j = 0;
			auto vals = var(attr[i].values, varTable);
			string name = parseAttr!(string)(opt, vals, j, "", varTable, msgWidth);
			int value = parseAttr!(int)(opt, vals, j, 0, varTable, msgWidth);
			auto r = new Coupon(name, value);
			i++;
			return r;
		} else static if (is(T:CoordinateType)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "none": i++; return CoordinateType.None;
			case "abs", "absolute": i++; return CoordinateType.Absolute;
			case "rel", "relative": i++; return CoordinateType.Relative;
			case "per", "percent", "percentage": i++; return CoordinateType.Percentage;
			default: throwError(_prop.msgs.scriptErrorInvalidCoordinateType, attr[i].token);
			}
			return T.init;
		} else static if (is(T == CardImage)) {
			CardImage imgPath = null;
			if (attr[i].token.kind == Kind.STRING) { mixin(S_TRACE);
				auto value = parseAttr!(string)(opt, attr, i, "", varTable, 0);
				imgPath = new CardImage(decodePath(value), CardImagePosition.Default);
			} else if (attr[i].token.kind == Kind.SYMBOL) { mixin(S_TRACE);
				auto value = attrValue(attr[i], varTable, 0);
				if (value == "n" || value == "none") { mixin(S_TRACE);
					imgPath = new CardImage("", CardImagePosition.Default);
					i++;
				} else { mixin(S_TRACE);
					imgPath = new CardImage(parseTalker!(false)(attr, i, varTable));
				}
			} else if (attr[i].type is NodeType.VALUES) { mixin(S_TRACE);
				size_t j = 0;
				auto vals = var(attr[i].values, varTable);
				auto path = parseAttr!(string)(opt, vals, j, "", varTable, 0);
				auto posType = parseAttr!(CardImagePosition)(opt, vals, j, CardImagePosition.Default, varTable, 0);
				i++;
				imgPath = new CardImage(decodePath(path), posType);
			} else { mixin(S_TRACE);
				imgPath = new CardImage("", CardImagePosition.Default);
				i++;
			}
			return imgPath;
		} else static if (is(T:CardImagePosition)) {
			if (attr[i].token.kind == Kind.SYMBOL) { mixin(S_TRACE);
				switch (attrValue(attr[i], varTable, 0)) {
				case "center":
					i++;
					return CardImagePosition.Center;
				case "topleft":
					i++;
					return CardImagePosition.TopLeft;
				case "default":
					i++;
					return CardImagePosition.Default;
				default:
					throwError(_prop.msgs.scriptErrorInvalidCardImagePosition, attr[i].token);
					break;
				}
			}
			return T.init;
		} else static if (is(T:Smoothing)) {
			if (attr[i].token.kind == Kind.SYMBOL) { mixin(S_TRACE);
				switch (attrValue(attr[i], varTable, 0)) {
				case "default":
					i++;
					return Smoothing.Default;
				default:
					return parseAttr!bool(opt, attr, i, true, varTable, 0) ? Smoothing.True : Smoothing.False;
				}
			}
			return T.init;
		} else static if (is(T == MatchingType)) { // Wsn.2
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "and": i++; return MatchingType.And;
			case "or": i++; return MatchingType.Or;
			default: throwError(_prop.msgs.scriptErrorInvalidMatchingType, attr[i].token);
			}
			return T.init;
		} else static if (is(T:UpdateType)) { // Wsn.4
			if (attr[i].token.kind == Kind.SYMBOL) { mixin(S_TRACE);
				switch (attrValue(attr[i], varTable, 0)) {
				case "fixed":
					i++;
					return UpdateType.Fixed;
				case "variables":
					i++;
					return UpdateType.Variables;
				case "all":
					i++;
					return UpdateType.All;
				default:
					throwError(_prop.msgs.scriptErrorInvalidUpdateType, attr[i].token);
				}
			}
			return defValue;
		} else static if (is(T:EnvironmentStatus)) { // Wsn.4
			if (attr[i].token.kind == Kind.SYMBOL) { mixin(S_TRACE);
				switch (attrValue(attr[i], varTable, 0)) {
				case "none":
					i++;
					return EnvironmentStatus.NotSet;
				case "on":
					i++;
					return EnvironmentStatus.Enable;
				case "off":
					i++;
					return EnvironmentStatus.Disable;
				default:
					throwError(_prop.msgs.scriptErrorInvalidEnvironmentStatus, attr[i].token);
				}
			}
			return defValue;
		} else static if (is(T:VariableType)) { // Wsn.4
			if (attr[i].token.kind == Kind.SYMBOL) { mixin(S_TRACE);
				switch (attrValue(attr[i], varTable, 0)) {
				case "flag":
					i++;
					return VariableType.Flag;
				case "step":
					i++;
					return VariableType.Step;
				case "variant", "var":
					i++;
					return VariableType.Variant;
				default:
					throwError(_prop.msgs.scriptErrorInvalidVariableType, attr[i].token);
				}
			}
			return defValue;
		} else static if (is(T == AbsorbTo)) { // Wsn.4
			auto value = attrValue(attr[i], varTable, msgWidth);
			switch (value) {
			case "none": i++; return AbsorbTo.None;
			case "m", "selected": i++; return AbsorbTo.Selected;
			default: throwError(_prop.msgs.scriptErrorInvalidAbsorbTo, attr[i].token);
			}
			return T.init;
		} else static if (is(T == int)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			if (attr[i].token.kind is Kind.SYMBOL && value == "all") { mixin(S_TRACE);
				i++;
				return 0; // カード削除用
			}
			if (attr[i].token.kind is Kind.SYMBOL && value == "none") { mixin(S_TRACE);
				i++;
				return -1; // スケール・レイヤ用
			}
			if (attr[i].token.kind is Kind.SYMBOL && value == "default") { mixin(S_TRACE);
				i++;
				return -1; // カード速度用
			}
			try { mixin(S_TRACE);
				auto r = to!(int)(value);
				i++;
				return r;
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
				throwError(_prop.msgs.scriptErrorReqNumber, attr[i].token);
			}
			return T.init;
		} else static if (is(T == ulong)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			try { mixin(S_TRACE);
				auto r = to!(ulong)(value);
				i++;
				return r;
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
				throwError(_prop.msgs.scriptErrorReqID, attr[i].token);
			}
			return T.init;
		} else static if (is(T == real)) {
			auto value = attrValue(attr[i], varTable, msgWidth);
			try { mixin(S_TRACE);
				auto r = to!(real)(value);
				i++;
				return r;
			} catch (Exception e) {
				printStackTrace();
				debugln(e);
				throwError(_prop.msgs.scriptErrorReqNumber, attr[i].token);
			}
			return T.init;
		} else static assert (0, T.stringof);
	}

	private Talker parseTalker(bool Within)(in Node[] attr, ref size_t i, in const(Node)[][string] varTable) { mixin(S_TRACE);
		auto node = attr[i];
		auto value = attrValue(node, varTable, 0);
		switch (value) {
		case "n", "none":
			goto default;
		case "m", "selected": i++; return Talker.Selected;
		case "u", "unselected": i++; return Talker.Unselected;
		case "r", "random": i++; return Talker.Random;
		case "c", "card":
			static if (Within) {
				goto default;
			} else {
				i++;
				return Talker.Card;
			}
		case "v", "valued": i++; return Talker.Valued;
		default:
			throwError(_prop.msgs.scriptErrorInvalidTalker, node.token);
			i++;
		}
		return Talker.Selected;
	}

	private Tuple!(VariableType, "targetType", string, "path") parseVariableType(in CompileOption opt, in Node[] attr, ref size_t i, in const(Node)[][string] varTable) { mixin(S_TRACE);
		auto node = attr[i];
		if (attr[i].token.kind == Kind.STRING) { mixin(S_TRACE);
			auto path = parseAttr!(string)(opt, attr, i, "", varTable, 0);
			return typeof(return)(VariableType.Variant, path);
		} else if (attr[i].token.kind is Kind.SYMBOL) { mixin(S_TRACE);
			auto targ = parseAttr!(VariableType)(opt, attr, i, VariableType.Variant, varTable, 0);
			auto path = parseAttr!(string)(opt, attr, i, "", varTable, 0);
			return typeof(return)(targ, path);
		} else { mixin(S_TRACE);
			i++;
			return typeof(return)(VariableType.Variant, "");
		}
	}

	private string parseNextValue(in Node node, in Keywords keys, in const(Node)[][string] varTable) { mixin(S_TRACE);
		if (!node.texts.length) return "";
		auto nodes = varValue(node, node.texts, varTable, 0);
		if (!nodes.length) return "";
		auto value = nodes[0].token;
		string r;
		if (value.kind is Kind.SYMBOL) { mixin(S_TRACE);
			auto valStr = std.string.toLower(value.value);
			if (valStr in keys.keywords) { mixin(S_TRACE);
				return "";
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
			case "none":
				r = "";
				break;
			default:
				throwError(_prop.msgs.scriptErrorUndefinedSymbol, node.token);
			}
		} else { mixin(S_TRACE);
			switch (value.kind) {
			case Kind.STRING: r = stringValue(value, 0); break;
			case Kind.NUMBER: r = to!(string)(value.value); break;
			default: throwError(_prop.msgs.scriptErrorInvalidValue, value);
			}
		}
		return r;
	}

	/// Nodeツリーをコンテント群にして返す。
	Content[] analyzeSemantics(in Node[] nodes, in CompileOption opt) { mixin(S_TRACE);
		const(Node)[][string] varTable;
		size_t autoWrapCount = 0;
		string[] startNames;
		Content[] dummy;
		return analyzeSemanticsImpl(opt, nodes, KEYS, varTable, 0, autoWrapCount, startNames, dummy, true);
	}
	private Content[] analyzeSemanticsImpl(in CompileOption opt, in Node[] nodes, in Keywords keys, ref const(Node)[][string] varTable, size_t stack, ref size_t autoWrapCount, ref string[] startNames, ref Content[] topGroup, bool isTop) { mixin(S_TRACE);
		Content[] r;
		string parseComment(string comment) { mixin(S_TRACE);
			string[] r;
			foreach (line; .splitLines(comment)) { mixin(S_TRACE);
				line = line.stripRight();
				if (r.length == 0 && line == "") continue;
				r ~= line;
			}
			// 全行の行頭に同じ空白文字が並んでいたら削る
			w: while (r.length && r[0] != "" && std.ascii.isWhite(r[0][0])) { mixin(S_TRACE);
				auto firstSpace = r[0][0];
				foreach (ref line; r) { mixin(S_TRACE);
					if (line == "") continue;
					if (line[0] != firstSpace) { mixin(S_TRACE);
						break w;
					}
				}
				foreach (ref line; r) line = line == "" ? line : line[1 .. $];
			}
			return lastRet(std.string.join(r, "\n"));
		}
		Content lastParent = null;
		bool nextIsChild = false;
		foreach (node; nodes) { mixin(S_TRACE);
			foreach (var; node.beforeVars) { mixin(S_TRACE);
				if (var.type !is NodeType.VAR_SET) { mixin(S_TRACE);
					throwError(_prop.msgs.scriptErrorInvalidVar, var.token);
				}
				if (var.value.length) { mixin(S_TRACE);
					varTable[std.string.toLower(var.token.value)] = this.var(var.value, varTable);
				} else { mixin(S_TRACE);
					throwError(_prop.msgs.scriptErrorNoVarVal, var.token);
				}
			}
			if (node.type is NodeType.VAR_SET) { mixin(S_TRACE);
				if (node.value.length) { mixin(S_TRACE);
					varTable[std.string.toLower(node.token.value)] = var(node.value, varTable);
				} else { mixin(S_TRACE);
					throwError(_prop.msgs.scriptErrorNoVarVal, node.token);
				}
				continue;
			}
			if (node.type !is NodeType.COMMAND && node.type !is NodeType.START) { mixin(S_TRACE);
				throwError(_prop.msgs.scriptErrorInvalidCommand, node.token);
			}
			if (node.type is NodeType.START) { mixin(S_TRACE);
				stack = 0;
			}
			string val = std.string.toLower(node.token.value);
			auto cmdPtr = val in KEYS.keywords;
			if (!cmdPtr) { mixin(S_TRACE);
				throwError(_prop.msgs.scriptErrorInvalidCommand, node.token);
			}
			string comment = node.token.comment;
			auto c = new Content(*cmdPtr, parseNextValue(node, keys, varTable));
			if (node.type is NodeType.START) { mixin(S_TRACE);
				c.setName(_prop, createNewName(c.name, (string name) { mixin(S_TRACE);
					foreach (sn; startNames) { mixin(S_TRACE);
						if (sn == name) { mixin(S_TRACE);
							return false;
						}
					}
					return true;
				}));
				startNames ~= c.name;
			}
			c.comment = parseComment(comment);
			size_t i = 0;
			auto detail = c.detail;
			if (detail.use(CArg.TalkerC)) { mixin(S_TRACE);
				CardImage[] paths;
				foreach (path; parseAttr!(CardImage[])(opt, node.attr, i, c.cardPaths, varTable, 0)) {
					final switch (path.type) {
					case CardImageType.File:
						if (path.path != "") paths ~= path;
						break;
					case CardImageType.PCNumber:
						if (0 < path.pcNumber) paths ~= path;
						break;
					case CardImageType.Talker:
						paths ~= path;
						break;
					}
				}
				c.cardPaths = paths;
			}
			if (detail.use(CArg.Text)) { mixin(S_TRACE);
				c.text = parseAttr!(string)(opt, node.attr, i, c.text, varTable,
					c.cardPaths.length ? _prop.looks.messageImageLen : _prop.looks.messageLen);
			}
			if (detail.use(CArg.TalkerNC)) { mixin(S_TRACE);
				c.talkerNC = parseAttr!(Talker, true)(opt, node.attr, i, c.talkerNC, varTable, 0);
			}
			if (detail.use(CArg.Dialogs)) { mixin(S_TRACE);
				c.dialogs = parseAttr!(SDialog[])(opt, node.attr, i, c.dialogs, varTable, _prop.looks.messageImageLen);
				if (!c.dialogs.length) { mixin(S_TRACE);
					c.dialogs = [new SDialog];
				}
			}
			if (detail.use(CArg.CellName)) { mixin(S_TRACE);
				c.cellName = parseAttr!(string)(opt, node.attr, i, c.cellName, varTable, 0);
			}
			if (detail.use(CArg.CardGroup)) { mixin(S_TRACE);
				c.cardGroup = parseAttr!(string)(opt, node.attr, i, c.cardGroup, varTable, 0);
			}
			if (detail.use(CArg.PositionType)) { mixin(S_TRACE);
				c.positionType = parseAttr!(CoordinateType)(opt, node.attr, i, c.positionType, varTable, 0);
			}
			if (detail.use(CArg.X)) { mixin(S_TRACE);
				c.x = parseAttr!(int)(opt, node.attr, i, c.x, varTable, 0);
			}
			if (detail.use(CArg.Y)) { mixin(S_TRACE);
				c.y = parseAttr!(int)(opt, node.attr, i, c.y, varTable, 0);
			}
			if (detail.use(CArg.SizeType)) { mixin(S_TRACE);
				c.sizeType = parseAttr!(CoordinateType)(opt, node.attr, i, c.sizeType, varTable, 0);
			}
			if (detail.use(CArg.Width)) { mixin(S_TRACE);
				c.width = parseAttr!(int)(opt, node.attr, i, c.width, varTable, 0);
			}
			if (detail.use(CArg.Height)) { mixin(S_TRACE);
				c.height = parseAttr!(int)(opt, node.attr, i, c.height, varTable, 0);
			}
			if (detail.use(CArg.Scale)) { mixin(S_TRACE);
				c.scale = parseAttr!(int)(opt, node.attr, i, c.scale, varTable, 0);
			}
			if (detail.use(CArg.Layer)) { mixin(S_TRACE);
				c.layer = parseAttr!(int)(opt, node.attr, i, c.layer, varTable, 0);
			}
			if (detail.use(CArg.BgImages)) { mixin(S_TRACE);
				c.backs = parseAttr!(BgImage[])(opt, node.attr, i, c.backs, varTable, 0);
			}
			if (detail.use(CArg.TargetS)) { mixin(S_TRACE);
				c.targetS = parseAttr!(Target)(opt, node.attr, i, c.targetS, varTable, 0);
			}
			if (detail.use(CArg.Range)) { mixin(S_TRACE);
				c.range = parseAttr!(Range)(opt, node.attr, i, c.range, varTable, 0);
			}
			if (detail.use(CArg.CastRange)) { mixin(S_TRACE);
				c.castRange = parseAttr!(CastRange[])(opt, node.attr, i, c.castRange, varTable, 0);
			}
			if (detail.use(CArg.KeyCodeRange)) { mixin(S_TRACE);
				c.keyCodeRange = parseAttr!(Range)(opt, node.attr, i, c.keyCodeRange, varTable, 0);
			}
			if (detail.use(CArg.TargetIsSkill) || detail.use(CArg.TargetIsItem) || detail.use(CArg.TargetIsBeast) || detail.use(CArg.TargetIsHand)) { mixin(S_TRACE);
				auto effectCardTypes = parseAttr!(EffectCardType[])(opt, node.attr, i, [], varTable, 0);
				if (detail.use(CArg.TargetIsSkill)) c.targetIsSkill = false;
				if (detail.use(CArg.TargetIsItem)) c.targetIsItem = false;
				if (detail.use(CArg.TargetIsBeast)) c.targetIsBeast = false;
				if (detail.use(CArg.TargetIsHand)) c.targetIsHand = false;
				foreach (effectCardType; effectCardTypes) { mixin(S_TRACE);
					final switch (effectCardType) {
					case EffectCardType.All:
						if (detail.use(CArg.TargetIsSkill)) c.targetIsSkill = true;
						if (detail.use(CArg.TargetIsItem)) c.targetIsItem = true;
						if (detail.use(CArg.TargetIsBeast)) c.targetIsBeast = true;
						break;
					case EffectCardType.Skill:
						if (detail.use(CArg.TargetIsSkill)) c.targetIsSkill = true;
						break;
					case EffectCardType.Item:
						if (detail.use(CArg.TargetIsItem)) c.targetIsItem = true;
						break;
					case EffectCardType.Beast:
						if (detail.use(CArg.TargetIsBeast)) c.targetIsBeast = true;
						break;
					case EffectCardType.Hand:
						if (detail.use(CArg.TargetIsHand)) c.targetIsHand = true;
						break;
					}
				}
			}
			if (detail.use(CArg.HoldingCoupon) && c.range is Range.CouponHolder) { mixin(S_TRACE);
				c.holdingCoupon = parseAttr!(string)(opt, node.attr, i, c.holdingCoupon, varTable, 0);
			}
			if (detail.use(CArg.Area)) { mixin(S_TRACE);
				c.area = parseAttr!(ulong)(opt, node.attr, i, c.area, varTable, 0);
			}
			if (detail.use(CArg.Battle)) { mixin(S_TRACE);
				c.battle = parseAttr!(ulong)(opt, node.attr, i, c.battle, varTable, 0);
			}
			if (detail.use(CArg.Package)) { mixin(S_TRACE);
				c.packages = parseAttr!(ulong)(opt, node.attr, i, c.packages, varTable, 0);
			}
			if (detail.use(CArg.Cast)) { mixin(S_TRACE);
				c.casts = parseAttr!(ulong)(opt, node.attr, i, c.casts, varTable, 0);
			}
			if (detail.use(CArg.Item)) { mixin(S_TRACE);
				c.item = parseAttr!(ulong)(opt, node.attr, i, c.item, varTable, 0);
			}
			if (detail.use(CArg.Skill)) { mixin(S_TRACE);
				c.skill = parseAttr!(ulong)(opt, node.attr, i, c.skill, varTable, 0);
			}
			if (detail.use(CArg.Info)) { mixin(S_TRACE);
				c.info = parseAttr!(ulong)(opt, node.attr, i, c.info, varTable, 0);
			}
			if (detail.use(CArg.Beast)) { mixin(S_TRACE);
				c.beast = parseAttr!(ulong)(opt, node.attr, i, c.beast, varTable, 0);
			}
			if (detail.use(CArg.Start)) { mixin(S_TRACE);
				c.start = parseAttr!(string)(opt, node.attr, i, c.start, varTable, 0);
			}
			if (detail.use(CArg.Complete)) { mixin(S_TRACE);
				c.complete = parseAttr!(bool)(opt, node.attr, i, c.complete, varTable, 0);
			}
			if (detail.use(CArg.Money)) { mixin(S_TRACE);
				c.money = parseAttr!(int)(opt, node.attr, i, c.money, varTable, 0);
			}
			if (detail.use(CArg.Coupon)) { mixin(S_TRACE);
				c.coupon = parseAttr!(string)(opt, node.attr, i, c.coupon, varTable, 0);
			}
			if (detail.use(CArg.CouponValue)) { mixin(S_TRACE);
				c.couponValue = parseAttr!(int)(opt, node.attr, i, c.couponValue, varTable, 0);
			}
			if (detail.use(CArg.CompleteStamp)) { mixin(S_TRACE);
				c.completeStamp = parseAttr!(string)(opt, node.attr, i, c.completeStamp, varTable, 0);
			}
			if (detail.use(CArg.Gossip)) { mixin(S_TRACE);
				c.gossip = parseAttr!(string)(opt, node.attr, i, c.gossip, varTable, 0);
			}
			if (detail.use(CArg.KeyCode)) { mixin(S_TRACE);
				c.keyCode = parseAttr!(string)(opt, node.attr, i, c.keyCode, varTable, 0);
			}

			if (detail.use(CArg.Flag) && detail.use(CArg.Step) && detail.use(CArg.Variant)) { mixin(S_TRACE);
				auto targ = parseVariableType(opt, node.attr, i, varTable);
				final switch (targ.targetType) {
				case VariableType.Flag:
					c.flag = targ.path;
					break;
				case VariableType.Step:
					c.step = targ.path;
					break;
				case VariableType.Variant:
					c.variant = targ.path;
					break;
				}
			} else { mixin(S_TRACE);
				if (detail.use(CArg.Flag)) { mixin(S_TRACE);
					c.flag = parseAttr!(string)(opt, node.attr, i, c.flag, varTable, 0);
				}
				if (detail.use(CArg.Step)) { mixin(S_TRACE);
					c.step = parseAttr!(string)(opt, node.attr, i, c.step, varTable, 0);
				}
				if (detail.use(CArg.Variant)) { mixin(S_TRACE);
					c.variant = parseAttr!(string)(opt, node.attr, i, c.variant, varTable, 0);
				}
			}
			if (detail.use(CArg.Flag2)) { mixin(S_TRACE);
				c.flag2 = parseAttr!(string)(opt, node.attr, i, c.flag2, varTable, 0);
			}
			if (detail.use(CArg.Step2)) { mixin(S_TRACE);
				c.step2 = parseAttr!(string)(opt, node.attr, i, c.step2, varTable, 0);
			}
			if (detail.use(CArg.Comparison4)) { mixin(S_TRACE);
				c.comparison4 = parseAttr!(Comparison4)(opt, node.attr, i, c.comparison4, varTable, 0);
			}
			if (detail.use(CArg.Comparison3)) { mixin(S_TRACE);
				c.comparison3 = parseAttr!(Comparison3)(opt, node.attr, i, c.comparison3, varTable, 0);
			}
			if (detail.use(CArg.FlagValue)) { mixin(S_TRACE);
				c.flagValue = parseAttr!(bool)(opt, node.attr, i, c.flagValue, varTable, 0);
			}
			if (detail.use(CArg.StepValue)) { mixin(S_TRACE);
				c.stepValue = parseAttr!(int)(opt, node.attr, i, c.stepValue, varTable, 0);
			}
			if (detail.use(CArg.CardNumber)) { mixin(S_TRACE);
				c.cardNumber = parseAttr!(int)(opt, node.attr, i, c.cardNumber, varTable, 0);
			}
			if (detail.use(CArg.SelectCard)) { mixin(S_TRACE);
				c.selectCard = parseAttr!(bool)(opt, node.attr, i, c.selectCard, varTable, 0);
			}
			if (detail.use(CArg.Motions)) { mixin(S_TRACE);
				c.motions = parseAttr!(Motion[])(opt, node.attr, i, c.motions, varTable, 0);
			}
			if (detail.use(CArg.CardVisual)) { mixin(S_TRACE);
				c.cardVisual = parseAttr!(CardVisual)(opt, node.attr, i, c.cardVisual, varTable, 0);
			}
			if (detail.use(CArg.UnsignedLevel)) { mixin(S_TRACE);
				c.unsignedLevel = parseAttr!(int)(opt, node.attr, i, c.unsignedLevel, varTable, 0);
			}
			if (detail.use(CArg.SignedLevel)) { mixin(S_TRACE);
				c.signedLevel = parseAttr!(int)(opt, node.attr, i, c.signedLevel, varTable, 0);
			}
			if (detail.use(CArg.LevelMin)) { mixin(S_TRACE);
				c.levelMin = parseAttr!(int)(opt, node.attr, i, c.levelMin, varTable, 0);
			}
			if (detail.use(CArg.LevelMax)) { mixin(S_TRACE);
				c.levelMax = parseAttr!(int)(opt, node.attr, i, c.levelMax, varTable, 0);
			}
			if (detail.use(CArg.Wait)) { mixin(S_TRACE);
				c.wait = parseAttr!(int)(opt, node.attr, i, c.wait, varTable, 0);
			}
			if (detail.use(CArg.Percent)) { mixin(S_TRACE);
				c.percent = parseAttr!(int)(opt, node.attr, i, c.percent, varTable, 0);
			}
			if (detail.use(CArg.TargetAll)) { mixin(S_TRACE);
				c.targetAll = parseAttr!(bool)(opt, node.attr, i, c.targetAll, varTable, 0);
			}
			if (detail.use(CArg.SelectionMethod)) { mixin(S_TRACE);
				c.selectionMethod = parseAttr!(SelectionMethod)(opt, node.attr, i, c.selectionMethod, varTable, 0);
			}
			if (detail.use(CArg.Average)) { mixin(S_TRACE);
				c.average = parseAttr!(bool)(opt, node.attr, i, c.average, varTable, 0);
			}
			if (detail.use(CArg.PartyNumber)) { mixin(S_TRACE);
				c.partyNumber = parseAttr!(int)(opt, node.attr, i, c.partyNumber, varTable, 0);
			}
			if (detail.use(CArg.SuccessRate)) { mixin(S_TRACE);
				c.successRate = parseAttr!(int)(opt, node.attr, i, c.successRate, varTable, 0);
			}
			if (detail.use(CArg.EffectType)) { mixin(S_TRACE);
				c.effectType = parseAttr!(EffectType)(opt, node.attr, i, c.effectType, varTable, 0);
			}
			if (detail.use(CArg.Resist)) { mixin(S_TRACE);
				c.resist = parseAttr!(Resist)(opt, node.attr, i, c.resist, varTable, 0);
			}
			if (detail.use(CArg.Status)) { mixin(S_TRACE);
				c.status = parseAttr!(Status)(opt, node.attr, i, c.status, varTable, 0);
			}
			if (detail.use(CArg.BgmPath)) { mixin(S_TRACE);
				c.bgmPath = encodePath(parseAttr!(string)(opt, node.attr, i, decodePath(c.bgmPath), varTable, 0));
			}
			if (detail.use(CArg.BgmChannel)) { mixin(S_TRACE);
				c.bgmChannel = parseAttr!(int)(opt, node.attr, i, c.bgmChannel, varTable, 0);
			}
			if (detail.use(CArg.BgmFadeIn)) { mixin(S_TRACE);
				c.bgmFadeIn = roundTo!uint(parseAttr!(real)(opt, node.attr, i, c.bgmFadeIn / 100.0, varTable, 0) * 100.0);
			}
			if (detail.use(CArg.BgmVolume)) { mixin(S_TRACE);
				c.bgmVolume = parseAttr!(int)(opt, node.attr, i, c.bgmVolume, varTable, 0);
			}
			if (detail.use(CArg.BgmLoopCount)) { mixin(S_TRACE);
				c.bgmLoopCount = parseAttr!(int)(opt, node.attr, i, c.bgmLoopCount, varTable, 0);
			}
			if (detail.use(CArg.SoundPath)) { mixin(S_TRACE);
				c.soundPath = encodePath(parseAttr!(string)(opt, node.attr, i, decodePath(c.soundPath), varTable, 0));
			}
			if (detail.use(CArg.SoundChannel)) { mixin(S_TRACE);
				c.soundChannel = parseAttr!(int)(opt, node.attr, i, c.soundChannel, varTable, 0);
			}
			if (detail.use(CArg.SoundFadeIn)) { mixin(S_TRACE);
				c.soundFadeIn = roundTo!uint(parseAttr!(real)(opt, node.attr, i, c.soundFadeIn / 100.0, varTable, 0) * 100.0);
			}
			if (detail.use(CArg.SoundVolume)) { mixin(S_TRACE);
				c.soundVolume = parseAttr!(int)(opt, node.attr, i, c.soundVolume, varTable, 0);
			}
			if (detail.use(CArg.SoundLoopCount)) { mixin(S_TRACE);
				c.soundLoopCount = parseAttr!(int)(opt, node.attr, i, c.soundLoopCount, varTable, 0);
			}
			if (detail.use(CArg.RefAbility)) { mixin(S_TRACE);
				c.refAbility = parseAttr!(bool)(opt, node.attr, i, c.refAbility, varTable, 0);
			}
			if (detail.use(CArg.Physical)) { mixin(S_TRACE);
				c.physical = parseAttr!(Physical)(opt, node.attr, i, c.physical, varTable, 0);
			}
			if (detail.use(CArg.Mental)) { mixin(S_TRACE);
				c.mental = parseAttr!(Mental)(opt, node.attr, i, c.mental, varTable, 0);
			}
			if (detail.use(CArg.Round)) { mixin(S_TRACE);
				c.round = parseAttr!(int)(opt, node.attr, i, c.round, varTable, 0);
			}
			if (detail.use(CArg.TransitionSpeed)) { mixin(S_TRACE);
				c.transitionSpeed = parseAttr!(int)(opt, node.attr, i, c.transitionSpeed, varTable, 0);
			}
			if (detail.use(CArg.Transition)) { mixin(S_TRACE);
				c.transition = parseAttr!(Transition)(opt, node.attr, i, c.transition, varTable, 0);
			}
			if (detail.use(CArg.DoAnime)) { mixin(S_TRACE);
				c.doAnime = parseAttr!(bool)(opt, node.attr, i, c.doAnime, varTable, 0);
			}
			if (detail.use(CArg.IgnoreEffectBooster)) { mixin(S_TRACE);
				c.ignoreEffectBooster = parseAttr!(bool)(opt, node.attr, i, c.ignoreEffectBooster, varTable, 0);
			}
			if (c.talkerNC is Talker.Valued || c.selectionMethod is SelectionMethod.Valued) { mixin(S_TRACE);
				if (detail.use(CArg.InitValue)) { mixin(S_TRACE);
					c.initValue = parseAttr!(int)(opt, node.attr, i, c.initValue, varTable, 0);
				}
				if (detail.use(CArg.Coupons)) { mixin(S_TRACE);
					Coupon[] coupons;
					bool[string] s;
					foreach (coupon; parseAttr!(Coupon[])(opt, node.attr, i, c.coupons, varTable, 0)) { mixin(S_TRACE);
						if (coupon.name !in s) { mixin(S_TRACE);
							s[coupon.name] = true;
							coupons ~= coupon;
						}
					}
					c.coupons = coupons;
				}
			}
			if (detail.use(CArg.SelectionColumns)) { mixin(S_TRACE);
				c.selectionColumns = parseAttr!(int)(opt, node.attr, i, c.selectionColumns, varTable, 0);
			}
			if (detail.use(CArg.BoundaryCheck)) { mixin(S_TRACE);
				c.boundaryCheck = parseAttr!(bool)(opt, node.attr, i, c.boundaryCheck, varTable, 0);
			}
			if (detail.use(CArg.CenteringX)) { mixin(S_TRACE);
				c.centeringX = parseAttr!(bool)(opt, node.attr, i, c.centeringX, varTable, 0);
			}
			if (detail.use(CArg.CenteringY)) { mixin(S_TRACE);
				c.centeringY = parseAttr!(bool)(opt, node.attr, i, c.centeringY, varTable, 0);
			}
			if (detail.use(CArg.SelectTalker)) { mixin(S_TRACE);
				c.selectTalker = parseAttr!(bool)(opt, node.attr, i, c.selectTalker, varTable, 0);
			}
			if (detail.use(CArg.InvertResult)) { mixin(S_TRACE);
				c.invertResult = parseAttr!(bool)(opt, node.attr, i, c.invertResult, varTable, 0);
			}
			if (detail.use(CArg.StartAction)) { mixin(S_TRACE);
				c.startAction = parseAttr!(StartAction)(opt, node.attr, i, c.startAction, varTable, 0);
			}
			if (detail.use(CArg.Ignite)) { mixin(S_TRACE);
				c.ignite = parseAttr!(bool)(opt, node.attr, i, c.ignite, varTable, 0);
			}
			if (detail.use(CArg.KeyCodes)) { mixin(S_TRACE);
				c.keyCodes = parseAttr!(string[])(opt, node.attr, i, c.keyCodes, varTable, 0);
			}
			if (detail.use(CArg.CouponNames)) { mixin(S_TRACE);
				string[] names;
				bool[string] s;
				foreach (name; parseAttr!(string[])(opt, node.attr, i, names, varTable, 0)) { mixin(S_TRACE);
					if (name !in s) { mixin(S_TRACE);
						s[name] = true;
						names ~= name;
					}
				}
				c.couponNames = names;
			}
			if (detail.use(CArg.MatchingType)) { mixin(S_TRACE);
				c.matchingType = parseAttr!(MatchingType)(opt, node.attr, i, c.matchingType, varTable, 0);
			}
			if (detail.use(CArg.ExpandSPChars)) { mixin(S_TRACE);
				c.expandSPChars = parseAttr!(bool)(opt, node.attr, i, c.expandSPChars, varTable, 0);
			}
			if (detail.use(CArg.ConsumeCard)) { mixin(S_TRACE);
				c.consumeCard = parseAttr!(bool)(opt, node.attr, i, c.consumeCard, varTable, 0);
			}
			if (detail.use(CArg.CardSpeed)) { mixin(S_TRACE);
				c.cardSpeed = parseAttr!(int)(opt, node.attr, i, c.cardSpeed, varTable, 0);
			}
			if (detail.use(CArg.OverrideCardSpeed)) { mixin(S_TRACE);
				c.overrideCardSpeed = parseAttr!(bool)(opt, node.attr, i, c.overrideCardSpeed, varTable, 0);
			}
			if (detail.use(CArg.InitialEffect)) { mixin(S_TRACE);
				c.initialEffect = parseAttr!(bool)(opt, node.attr, i, c.initialEffect, varTable, 0);
			}
			if (detail.use(CArg.InitialSoundPath)) { mixin(S_TRACE);
				c.initialSoundPath = encodePath(parseAttr!(string)(opt, node.attr, i, decodePath(c.initialSoundPath), varTable, 0));
			}
			if (detail.use(CArg.InitialSoundChannel)) { mixin(S_TRACE);
				c.initialSoundChannel = parseAttr!(int)(opt, node.attr, i, c.initialSoundChannel, varTable, 0);
			}
			if (detail.use(CArg.InitialSoundFadeIn)) { mixin(S_TRACE);
				c.initialSoundFadeIn = roundTo!uint(parseAttr!(real)(opt, node.attr, i, c.initialSoundFadeIn / 100.0, varTable, 0) * 100.0);
			}
			if (detail.use(CArg.InitialSoundVolume)) { mixin(S_TRACE);
				c.initialSoundVolume = parseAttr!(int)(opt, node.attr, i, c.initialSoundVolume, varTable, 0);
			}
			if (detail.use(CArg.InitialSoundLoopCount)) { mixin(S_TRACE);
				c.initialSoundLoopCount = parseAttr!(int)(opt, node.attr, i, c.initialSoundLoopCount, varTable, 0);
			}
			if (detail.use(CArg.AbsorbTo)) { mixin(S_TRACE);
				c.absorbTo = parseAttr!(AbsorbTo)(opt, node.attr, i, c.absorbTo, varTable, 0);
			}
			if (detail.use(CArg.BackpackEnabled)) { mixin(S_TRACE);
				c.backpackEnabled = parseAttr!(EnvironmentStatus)(opt, node.attr, i, c.backpackEnabled, varTable, 0);
			}
			if (detail.use(CArg.Expression)) { mixin(S_TRACE);
				c.expression = parseAttr!(string)(opt, node.attr, i, c.expression, varTable, 0);
			}

			Content autoWrap(Content c) { mixin(S_TRACE);
				if (_autoWrap <= stack) { mixin(S_TRACE);
					autoWrapCount++;
					stack = 0;
					auto s = new Content(CType.Start, .createNewName(.format("Auto wrap (%d)", autoWrapCount), (string name) { mixin(S_TRACE);
						foreach (sn; startNames) { mixin(S_TRACE);
							if (sn == name) { mixin(S_TRACE);
								return false;
							}
						}
						return true;
					}));
					startNames ~= s.name;
					auto link = new Content(CType.LinkStart, c.name);
					link.start = s.name;
					c.add(_prop, link);
					if (isTop) { mixin(S_TRACE);
						r ~= s;
					} else { mixin(S_TRACE);
						topGroup ~= s;
					}
					return s;
				}
				return c;
			}
			if (nextIsChild) { mixin(S_TRACE);
				/// 一つ前の分析結果は nextIsChild is true 。
				if (!lastParent.detail.owner) { mixin(S_TRACE);
					throwError(.tryFormat(_prop.msgs.scriptErrorCanNotHaveContent, _prop.msgs.contentName(lastParent.type)), node.token);
				} else { mixin(S_TRACE);
					auto parent = autoWrap(lastParent);
					parent.add(_prop, c);
					stack++;
				}
			} else { mixin(S_TRACE);
				r ~= c;
			}
			if (node.childs.length) { mixin(S_TRACE);
				if (!detail.owner) { mixin(S_TRACE);
					throwError(.tryFormat(_prop.msgs.scriptErrorCanNotHaveContent, _prop.msgs.contentName(c.type)), node.token);
				} else { mixin(S_TRACE);
					auto parent = autoWrap(c);
					foreach (chld; analyzeSemanticsImpl(opt, node.childs, keys, varTable, stack + 1, autoWrapCount, startNames, isTop ? r : topGroup, false)) { mixin(S_TRACE);
						parent.add(_prop, chld);
					}
				}
			}
			nextIsChild = node.nextIsChild;
			if (nextIsChild) { mixin(S_TRACE);
				lastParent = c;
			}
		}
		return r;
	}
	const
	string toScript(in Content[] cs, string evtChildOK, bool legacy, string indent = "\t") { mixin(S_TRACE);
		char[] buf;
		auto table = new VarTable;
		foreach (i, c; cs) { mixin(S_TRACE);
			if (0 < i) buf ~= "\n\n";
			toScriptImpl(evtChildOK, buf, c, indent, "", KEYS, table, legacy);
		}
		auto vars = table.vars();
		if (vars.length) { mixin(S_TRACE);
			buf = std.string.join(vars, "\n") ~ "\n\n" ~ buf;
		}
		return assumeUnique(buf);
	}
	const
	private string[] toAttr(bool Within = false, T)(T value, string indentValue, VarTable vars, size_t strWidth = 0, bool useLinePos = true, bool useSingleQuote = false) { mixin(S_TRACE);
		string[] attrs;
		static if (is(Unqual!(T) == Symbol)) {
			attrs ~= value;
		} else static if (is(Unqual!(T) == string)) {
			string attr;
			auto lines = splitLines(value.idup);
			if (lines.length == 0) { mixin(S_TRACE);
				attr ~= `""`;
			} else if (lines.length == 1) { mixin(S_TRACE);
				attr ~= createString(lines[0], useSingleQuote);
			} else { mixin(S_TRACE);
				size_t lns = 0;
				foreach (i, line; lines) { mixin(S_TRACE);
					if (line.length) { mixin(S_TRACE);
						lns = i;
						break;
					}
				}
				attr ~= "@";
				if (lns > 0 && useLinePos) { mixin(S_TRACE);
					if (vars.useCenter && lns + 1 == stringCenter(lines, strWidth)) { mixin(S_TRACE);
						attr ~= " center";
					} else { mixin(S_TRACE);
						attr ~= " " ~ to!(string)(lns + 1);
					}
					lines = lines[lns .. $];
				}
				attr ~= "\n";
				bool spaceLine = false;
				foreach (line; lines) { mixin(S_TRACE);
					line = std.array.replace(line, "@", "@@");
					if (line.length && (line[0] == ' ' || line[0] == '\t' || line[0] == '\\')) { mixin(S_TRACE);
						line = "\\" ~ line;
					}
					attr ~= indentValue ~ line ~ "\n";
					spaceLine = line.length == 0;
				}
				if (spaceLine) { mixin(S_TRACE);
					attr ~= "@";
				} else { mixin(S_TRACE);
					attr ~= indentValue ~ "@";
				}
			}
			attrs ~= attr;
		} else static if (isVArray!(T)) {
			foreach (i, v; value) { mixin(S_TRACE);
				attrs ~= toAttr(v, indentValue, vars, strWidth);
			}
			attrs = [attrs.join(" ")];
		} else static if (is(T : bool)) {
			attrs ~= value ? "true": "false";
		} else static if (is(T : Transition)) {
			switch (value) {
			case Transition.Default: attrs ~= "default"; break;
			case Transition.None: attrs ~= "none"; break;
			case Transition.Blinds: attrs ~= "thread"; break;
			case Transition.PixelDissolve: attrs ~= "shave"; break;
			case Transition.Fade: attrs ~= "fade"; break;
			default: assert (0);
			}
		} else static if (is(T : Range)) {
			switch (value) {
			case Range.Selected: attrs ~= "M"; break;
			case Range.Random: attrs ~= "R"; break;
			case Range.Party: attrs ~= "T"; break;
			case Range.Backpack: attrs ~= "backpack"; break;
			case Range.PartyAndBackpack: attrs ~= "party"; break;
			case Range.Field: attrs ~= "field"; break;
			case Range.CouponHolder: attrs ~= "coupon"; break; // Wsn.2
			case Range.CardTarget: attrs ~= "card"; break; // Wsn.2
			case Range.SelectedCard: attrs ~= "selcard"; break; // Wsn.3
			default: assert (0);
			}
		} else static if (is(T : CastRange)) {
			switch (value) {
			case CastRange.Party: attrs ~= "party"; break;
			case CastRange.Enemy: attrs ~= "enemy"; break;
			case CastRange.Npc: attrs ~= "npc"; break;
			default: assert (0);
			}
		} else static if (is(T : Status)) {
			switch (value) {
			case Status.Active: attrs ~= "active"; break;
			case Status.Inactive: attrs ~= "inactive"; break;
			case Status.Alive: attrs ~= "alive"; break;
			case Status.Dead: attrs ~= "dead"; break;
			case Status.Fine: attrs ~= "fine"; break;
			case Status.Injured: attrs ~= "injured"; break;
			case Status.HeavyInjured: attrs ~= "heavyinjured"; break;
			case Status.Unconscious: attrs ~= "unconscious"; break;
			case Status.Poison: attrs ~= "poison"; break;
			case Status.Sleep: attrs ~= "sleep"; break;
			case Status.Bind: attrs ~= "bind"; break;
			case Status.Paralyze: attrs ~= "paralyze"; break;
			case Status.Confuse: attrs ~= "confuse"; break;
			case Status.Overheat: attrs ~= "overheat"; break;
			case Status.Brave: attrs ~= "brave"; break;
			case Status.Panic: attrs ~= "panic"; break;
			case Status.Silence: attrs ~= "silence"; break;
			case Status.FaceUp: attrs ~= "faceup"; break;
			case Status.AntiMagic: attrs ~= "antimagic"; break;
			case Status.UpAction: attrs ~= "upaction"; break;
			case Status.UpAvoid: attrs ~= "upavoid"; break;
			case Status.UpResist: attrs ~= "upresist"; break;
			case Status.UpDefense: attrs ~= "updefense"; break;
			case Status.DownAction: attrs ~= "downaction"; break;
			case Status.DownAvoid: attrs ~= "downavoid"; break;
			case Status.DownResist: attrs ~= "downresist"; break;
			case Status.DownDefense: attrs ~= "downdefense"; break;
			case Status.None: attrs ~= "none"; break;
			default: assert (0);
			}
		} else static if (is(T : Target)) {
			switch (value.m) {
			case Target.M.Selected: attrs ~= "M"; break;
			case Target.M.Random: attrs ~= "R"; break;
			case Target.M.Unselected: attrs ~= "U"; break;
			case Target.M.Party: attrs ~= "T"; break;
			default: assert (0);
			}
			static if (!Within) {
				attrs ~= toAttr(value.sleep, indentValue, vars);
			}
		} else static if (is(T : EffectType)) {
			switch (value) {
			case EffectType.Physic: attrs ~= "physic"; break;
			case EffectType.Magic: attrs ~= "magic"; break;
			case EffectType.MagicalPhysic: attrs ~= "mphysic"; break;
			case EffectType.PhysicalMagic: attrs ~= "pmagic"; break;
			case EffectType.None: attrs ~= "none"; break;
			default: assert (0);
			}
		} else static if (is(T : Resist)) {
			switch (value) {
			case Resist.Avoid: attrs ~= "avoid"; break;
			case Resist.Resist: attrs ~= "resist"; break;
			case Resist.Unfail: attrs ~= "unfail"; break;
			default: assert (0);
			}
		} else static if (is(T : CardVisual)) {
			switch (value) {
			case CardVisual.None: attrs ~= "none"; break;
			case CardVisual.Reverse: attrs ~= "reverse"; break;
			case CardVisual.Horizontal: attrs ~= "hswing"; break;
			case CardVisual.Vertical: attrs ~= "vswing"; break;
			default: assert (0);
			}
		} else static if (is(T : Mental)) {
			switch (value) {
			case Mental.Aggressive: attrs ~= "agg"; break;
			case Mental.Unaggressive: attrs ~= "unagg"; break;
			case Mental.Cheerful: attrs ~= "cheerf"; break;
			case Mental.Uncheerful: attrs ~= "uncheerf"; break;
			case Mental.Brave: attrs ~= "brave"; break;
			case Mental.Unbrave: attrs ~= "unbrave"; break;
			case Mental.Cautious: attrs ~= "caut"; break;
			case Mental.Uncautious: attrs ~= "uncaut"; break;
			case Mental.Trickish: attrs ~= "trick"; break;
			case Mental.Untrickish: attrs ~= "untrick"; break;
			default: assert (0);
			}
		} else static if (is(T : Physical)) {
			switch (value) {
			case Physical.Dex: attrs ~= "dex"; break;
			case Physical.Agl: attrs ~= "agl"; break;
			case Physical.Int: attrs ~= "int"; break;
			case Physical.Str: attrs ~= "str"; break;
			case Physical.Vit: attrs ~= "vit"; break;
			case Physical.Min: attrs ~= "min"; break;
			default: assert (0);
			}
		} else static if (is(T : Talker)) {
			attrs ~= toAttrTalker([new CardImage(value)], indentValue, vars);
		} else static if (is(T : MType)) {
			switch (value) {
			case MType.Heal: attrs ~= "heal"; break;
			case MType.Damage: attrs ~= "damage"; break;
			case MType.Absorb: attrs ~= "absorb"; break;
			case MType.Paralyze: attrs ~= "paralyze"; break;
			case MType.DisParalyze: attrs ~= "disparalyze"; break;
			case MType.Poison: attrs ~= "poison"; break;
			case MType.DisPoison: attrs ~= "dispoison"; break;
			case MType.GetSkillPower: attrs ~= "getspilit"; break;
			case MType.LoseSkillPower: attrs ~= "losespilit"; break;
			case MType.Sleep: attrs ~= "sleep"; break;
			case MType.Confuse: attrs ~= "confuse"; break;
			case MType.Overheat: attrs ~= "overheat"; break;
			case MType.Brave: attrs ~= "brave"; break;
			case MType.Panic: attrs ~= "panic"; break;
			case MType.Normal: attrs ~= "resetmind"; break;
			case MType.Bind: attrs ~= "bind"; break;
			case MType.DisBind: attrs ~= "disbind"; break;
			case MType.Silence: attrs ~= "silence"; break;
			case MType.DisSilence: attrs ~= "dissilence"; break;
			case MType.FaceUp: attrs ~= "faceup"; break;
			case MType.FaceDown: attrs ~= "facedown"; break;
			case MType.AntiMagic: attrs ~= "antimagic"; break;
			case MType.DisAntiMagic: attrs ~= "disantimagic"; break;
			case MType.EnhanceAction: attrs ~= "enhaction"; break;
			case MType.EnhanceAvoid: attrs ~= "enhavoid"; break;
			case MType.EnhanceResist: attrs ~= "enhresist"; break;
			case MType.EnhanceDefense: attrs ~= "enhdefense"; break;
			case MType.VanishTarget: attrs ~= "vantarget"; break;
			case MType.VanishCard: attrs ~= "vancard"; break;
			case MType.VanishBeast: attrs ~= "vanbeast"; break;
			case MType.DealAttackCard: attrs ~= "dealattack"; break;
			case MType.DealPowerfulAttackCard: attrs ~= "dealpowerful"; break;
			case MType.DealCriticalAttackCard: attrs ~= "dealcritical"; break;
			case MType.DealFeintCard: attrs ~= "dealfeint"; break;
			case MType.DealDefenseCard: attrs ~= "dealdefense"; break;
			case MType.DealDistanceCard: attrs ~= "dealdistance"; break;
			case MType.DealConfuseCard: attrs ~= "dealconfuse"; break;
			case MType.DealSkillCard: attrs ~= "dealskill"; break;
			case MType.SummonBeast: attrs ~= "summon"; break;
			case MType.CancelAction: attrs ~= "cancelaction"; break;
			case MType.NoEffect: attrs ~= "noeffect"; break;
			default: assert (0);
			}
		} else static if (is(T : Element)) {
			switch (value) {
			case Element.All: attrs ~= "all"; break;
			case Element.Health: attrs ~= "phy"; break;
			case Element.Mind: attrs ~= "mind"; break;
			case Element.Miracle: attrs ~= "holy"; break;
			case Element.Magic: attrs ~= "magic"; break;
			case Element.Fire: attrs ~= "fire"; break;
			case Element.Ice: attrs ~= "ice"; break;
			default: assert (0);
			}
		} else static if (is(T : DamageType)) {
			switch (value) {
			case DamageType.LevelRatio: attrs ~= "level"; break;
			case DamageType.Normal: attrs ~= "value"; break;
			case DamageType.Max: attrs ~= "max"; break;
			default: assert (0);
			}
		} else static if (is(T : EffectCardType)) {
			switch (value) {
			case EffectCardType.All: attrs ~= "all"; break;
			case EffectCardType.Skill: attrs ~= "skill"; break;
			case EffectCardType.Item: attrs ~= "item"; break;
			case EffectCardType.Beast: attrs ~= "beast"; break;
			case EffectCardType.Hand: attrs ~= "hand"; break;
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
		} else static if (is(T : SelectionMethod)) {
			final switch (value) {
			case SelectionMethod.Manual: attrs ~= "manual"; break;
			case SelectionMethod.Random: attrs ~= "random"; break;
			case SelectionMethod.Valued: attrs ~= "valued"; break;
			}
		} else static if (is(T:StartAction)) {
			switch (value) {
			case StartAction.Now: attrs ~= "now"; break;
			case StartAction.CurrentRound: attrs ~= "current"; break;
			case StartAction.NextRound: attrs ~= "next"; break;
			default: assert (0);
			}
		} else static if (is(T:Smoothing)) {
			switch (value) {
			case Smoothing.Default: attrs ~= "default"; break;
			case Smoothing.True: attrs ~= "true"; break;
			case Smoothing.False: attrs ~= "false"; break;
			default: assert (0);
			}
		} else static if (is(T : CRGB)) {
			if (value.a == 255) { mixin(S_TRACE);
				attrs ~= createString(.tryFormat("#%02X%02X%02X", value.r, value.g, value.b));
			} else { mixin(S_TRACE);
				attrs ~= createString(.tryFormat("#%02X%02X%02X%02X", value.r, value.g, value.b, value.a));
			}
		} else static if (is(Unqual!(T) : BgImage)) {
			string[] attrs2;
			auto ic = cast(ImageCell)value;
			if (ic) { mixin(S_TRACE);
				attrs2 ~= toAttr(encodePath(ic.path), indentValue, vars);
			}
			auto tc = cast(TextCell)value;
			if (tc) { mixin(S_TRACE);
				attrs2 ~= "text";
				attrs2 ~= toAttr(tc.text, indentValue, vars);
				attrs2 ~= toAttr(tc.fontName, indentValue, vars);
				attrs2 ~= toAttr(tc.size, indentValue, vars);
				attrs2 ~= toAttr(tc.color, indentValue, vars);
				string[] style = [];
				if (tc.bold) style ~= "bold";
				if (tc.italic) style ~= "italic";
				if (tc.underline) style ~= "underline";
				if (tc.strike) style ~= "strike";
				if (tc.vertical) style ~= "vertical";
				if (tc.antialias) style ~= "antialias";
				final switch (tc.borderingType) {
				case BorderingType.None:
					attrs2 ~= std.string.join(style, " ");
					break;
				case BorderingType.Outline:
					style ~= "border1";
					attrs2 ~= std.string.join(style, " ");
					attrs2 ~= toAttr(tc.borderingColor, indentValue, vars);
					break;
				case BorderingType.Inline:
					style ~= "border2";
					attrs2 ~= std.string.join(style, " ");
					attrs2 ~= toAttr(tc.borderingColor, indentValue, vars);
					attrs2 ~= toAttr(tc.borderingWidth, indentValue, vars);
					break;
				}
			}
			auto cc = cast(ColorCell)value;
			if (cc) { mixin(S_TRACE);
				attrs2 ~= "color";
				attrs2 ~= toAttr(cc.blendMode, indentValue, vars);
				attrs2 ~= toAttr(cc.color1, indentValue, vars);
				final switch (cc.gradientDir) {
				case GradientDir.None:
					break;
				case GradientDir.LeftToRight:
				case GradientDir.TopToBottom:
					attrs2 ~= toAttr(cc.gradientDir, indentValue, vars);
					attrs2 ~= toAttr(cc.color2, indentValue, vars);
					break;
				}
			}
			auto pc = cast(PCCell)value;
			if (pc) { mixin(S_TRACE);
				attrs2 ~= "pc";
				attrs2 ~= toAttr(pc.pcNumber, indentValue, vars);
				attrs2 ~= toAttr(pc.expand, indentValue, vars);
			}
			attrs2 ~= toAttr(value.flag, indentValue, vars);
			attrs2 ~= toAttr(value.x, indentValue, vars);
			attrs2 ~= toAttr(value.y, indentValue, vars);
			attrs2 ~= toAttr(value.width, indentValue, vars);
			attrs2 ~= toAttr(value.height, indentValue, vars);
			if (ic) { mixin(S_TRACE);
				attrs2 ~= toAttr(ic.mask, indentValue, vars);
			}
			attrs2 ~= toAttr(value.cellName, indentValue, vars);
			attrs2 ~= toAttr(value.layer, indentValue, vars);
			if (ic) { mixin(S_TRACE);
				attrs2 ~= toAttr(ic.smoothing, indentValue, vars);
			}
			if (pc) { mixin(S_TRACE);
				attrs2 ~= toAttr(pc.smoothing, indentValue, vars);
			}
			if (tc) { mixin(S_TRACE);
				attrs2 ~= toAttr(tc.updateType, indentValue, vars);
			}
			attrs ~= "[" ~ std.string.join(attrs2, ", ") ~ "]";
		} else static if (is(Unqual!(T) : Motion)) {
			auto detail = value.detail;
			string[] attrs2;
			attrs2 ~= toAttr(value.type, indentValue, vars);
			if (detail.use(MArg.ValueType)) { mixin(S_TRACE);
				attrs2 ~= toAttr(value.damageType, indentValue, vars);
			}
			if (detail.use(MArg.UValue)) { mixin(S_TRACE);
				attrs2 ~= toAttr(value.uValue, indentValue, vars);
			}
			if (detail.use(MArg.AValue)) { mixin(S_TRACE);
				attrs2 ~= toAttr(value.aValue, indentValue, vars);
			}
			if (detail.use(MArg.Round)) { mixin(S_TRACE);
				attrs2 ~= toAttr(value.round, indentValue, vars);
			}
			if (detail.use(MArg.Beast)) { mixin(S_TRACE);
				if (value.beast && _summ) { mixin(S_TRACE);
					attrs2 ~= toAttr(vars.id(_summ.findSameBeast(value.beast), value.beast.linkId), indentValue, vars);
				} else { mixin(S_TRACE);
					attrs2 ~= toAttr(cast(Symbol) "0", indentValue, vars);
				}
			}
			attrs2 ~= toAttr(value.element, indentValue, vars);
			attrs ~= "[" ~ std.string.join(attrs2, ", ") ~ "]";
		} else static if (is(Unqual!(T) : SDialog)) {
			string[] attrs2;
			bool semic = false;
			foreach (c; value.rCoupons) { mixin(S_TRACE);
				if (std.string.indexOf(c, ";") >= 0) { mixin(S_TRACE);
					semic = true;
					break;
				}
			}
			if (semic) { mixin(S_TRACE);
				attrs2 ~= std.string.join(toAttr(value.rCoupons, indentValue, vars), " ");
			} else { mixin(S_TRACE);
				attrs2 ~= createString(std.string.join(value.rCoupons.dup, ";"));
			}
			attrs2 ~= toAttr(value.text, indentValue, vars, strWidth);
			attrs ~= "[" ~ std.string.join(attrs2, ", ") ~ "]";
		} else static if (is(Unqual!(T) : Coupon)) {
			string[] attrs2;
			attrs2 ~= createString(value.name);
			attrs2 ~= to!(string)(value.value);
			attrs ~= "[" ~ std.string.join(attrs2, ", ") ~ "]";
		} else static if (is(T:CoordinateType)) {
			final switch (value) {
			case CoordinateType.None: attrs ~= "none"; break;
			case CoordinateType.Absolute: attrs ~= "abs"; break;
			case CoordinateType.Relative: attrs ~= "rel"; break;
			case CoordinateType.Percentage: attrs ~= "per"; break;
			}
		} else static if (is(T : MatchingType)) { //Wsn.2
			switch (value) {
			case MatchingType.And: attrs ~= "and"; break;
			case MatchingType.Or: attrs ~= "or"; break;
			default: assert (0);
			}
		} else static if (is(T : UpdateType)) { //Wsn.4
			final switch (value) {
			case UpdateType.Fixed: attrs ~= "fixed"; break;
			case UpdateType.Variables: attrs ~= "variables"; break;
			case UpdateType.All: attrs ~= "all"; break;
			}
		} else static if (is(T:EnvironmentStatus)) { //Wsn.4
			final switch (value) {
			case EnvironmentStatus.NotSet: attrs ~= "none"; break;
			case EnvironmentStatus.Enable: attrs ~= "on"; break;
			case EnvironmentStatus.Disable: attrs ~= "off"; break;
			}
		} else static if (is(T:VariableType)) { //Wsn.4
			final switch (value) {
			case VariableType.Flag: attrs ~= "flag"; break;
			case VariableType.Step: attrs ~= "step"; break;
			case VariableType.Variant: attrs ~= "variant"; break;
			}
		} else static if (is(T:AbsorbTo)) { //Wsn.4
			final switch (value) {
			case AbsorbTo.None: attrs ~= "none"; break;
			case AbsorbTo.Selected: attrs ~= "M"; break;
			}
		} else static if (is(T : int)) {
			attrs ~= to!(string)(value);
		} else static if (is(T : uint)) {
			attrs ~= to!(string)(value);
		} else static if (is(T : ulong)) {
			attrs ~= to!(string)(value);
		} else static if (is(T : real)) {
			attrs ~= .formatReal(value, 3);
		} else static assert (0);
		return attrs;
	}
	const
	private string toAttrTalker(in CardImage[] cardPaths, string indentValue, VarTable vars) { mixin(S_TRACE);
		if (!cardPaths.length) return "none";
		string[] r;
		foreach (cardPath; cardPaths) { mixin(S_TRACE);
			final switch (cardPath.type) {
			case CardImageType.File:
				final switch (cardPath.positionType) {
				case CardImagePosition.Center:
					r ~= ("[" ~ createString(encodePath(cardPath.path)) ~ ", center" ~ "]");
					break;
				case CardImagePosition.TopLeft:
					r ~= ("[" ~ createString(encodePath(cardPath.path)) ~ ", topleft" ~ "]");
					break;
				case CardImagePosition.Default:
					r ~= toAttr(encodePath(cardPath.path), indentValue, vars);
					break;
				}
				break;
			case CardImageType.PCNumber:
				// 非対応
				break;
			case CardImageType.Talker:
				final switch (cardPath.talker) {
				case Talker.Selected: r ~= "M"; break;
				case Talker.Unselected: r ~= "U"; break;
				case Talker.Random: r ~= "R"; break;
				case Talker.Card: r ~= "C"; break;
				case Talker.Valued: r ~= "V"; break;
				}
				break;
			}
		}
		return std.string.join(r, " ");
	}
	const
	private string[] toAttrVariableType(string flag, string step, string variant) { mixin(S_TRACE);
		if (variant != "") {
			return [createString(variant)];
		} else if (step != "") { mixin(S_TRACE);
			return ["step", createString(step)];
		} else if (flag != "") { mixin(S_TRACE);
			return ["flag", createString(flag)];
		} else { mixin(S_TRACE);
			return [createString("")];
		}
	}
	private struct Symbol {
		string symbol;
		alias symbol this;
	}
	private static class VarTable {
		bool useVar = true;
		bool useCenter = true;
		private Symbol idVar(string Name, A)(in A a, ulong id, ref string[ulong] tbl, ref ulong[string] tblR) { mixin(S_TRACE);
			if (!useVar || !a) return Symbol(to!(string)(id));
			auto p = a.id in tbl;
			if (p) return Symbol(*p);
			string base = "$" ~ Name ~ "_" ~ validVarName(a.name);
			string name = base;
			size_t i = 1;
			while (name in tblR) { mixin(S_TRACE);
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
		Symbol id(in Area a, ulong id) { return idVar!("area")(a, id, _areas, _areasR); }
		Symbol id(in Battle a, ulong id) { return idVar!("battle")(a, id, _battles, _battlesR); }
		Symbol id(in Package a, ulong id) { return idVar!("pack")(a, id, _packages, _packagesR); }
		Symbol id(in CastCard a, ulong id) { return idVar!("cast")(a, id, _casts, _castsR); }
		Symbol id(in SkillCard a, ulong id) { return idVar!("skill")(a, id, _skills, _skillsR); }
		Symbol id(in ItemCard a, ulong id) { return idVar!("item")(a, id, _items, _itemsR); }
		Symbol id(in BeastCard a, ulong id) { return idVar!("beast")(a, id, _beasts, _beastsR); }
		Symbol id(in InfoCard a, ulong id) { return idVar!("info")(a, id, _infos, _infosR); }
		private static string[] vars(in string[ulong] arr) { mixin(S_TRACE);
			string[] r;
			foreach (id; std.algorithm.sort(arr.keys)) { mixin(S_TRACE);
				r ~= arr[id] ~ " = " ~ to!(string)(id);
			}
			return r;
		}
		const
		string[] vars() { mixin(S_TRACE);
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
	private void toScriptImpl(string evtChildOK, ref char[] buf, in Content content, string indent, string indentValue, in Keywords keys, VarTable vars, bool legacy) { mixin(S_TRACE);
		Rebindable!(const(Content)) c = content;
		while (true) { mixin(S_TRACE);
			buf ~= indentValue;
			auto detail = c.detail;
			if (c.comment.length) { mixin(S_TRACE);
				foreach (line; splitLines(lastRet(c.comment))) { mixin(S_TRACE);
					buf ~= "// " ~ line;
					buf ~= "\n";
					buf ~= indentValue;
				}
			}
			string command = keys.commands[c.type];
			buf ~= command;
			string[] attrs;
			if (c.type is CType.Start) { mixin(S_TRACE);
				attrs ~= createString(c.name);
			}
			size_t msgLen = 0;
			if (detail.use(CArg.TalkerC)) { mixin(S_TRACE);
				attrs ~= toAttrTalker(c.cardPaths, indentValue, vars);
				if (c.cardPaths.length) { mixin(S_TRACE);
					msgLen = _prop.looks.messageImageLen;
				} else { mixin(S_TRACE);
					msgLen = _prop.looks.messageLen;
				}
			}
			if (detail.use(CArg.Text)) { mixin(S_TRACE);
				attrs ~= toAttr(c.text, indentValue, vars, msgLen);
			}
			if (detail.use(CArg.TalkerNC)) { mixin(S_TRACE);
				attrs ~= toAttr!(true)(c.talkerNC, indentValue, vars);
				msgLen = _prop.looks.messageImageLen;
			}
			if (detail.use(CArg.Dialogs)) { mixin(S_TRACE);
				attrs ~= toAttr(c.dialogs, indentValue, vars, msgLen);
			}
			if (detail.use(CArg.CellName)) { mixin(S_TRACE);
				attrs ~= toAttr(c.cellName, indentValue, vars);
			}
			if (detail.use(CArg.CardGroup)) { mixin(S_TRACE);
				attrs ~= toAttr(c.cardGroup, indentValue, vars);
			}
			if (detail.use(CArg.PositionType)) { mixin(S_TRACE);
				attrs ~= toAttr(c.positionType, indentValue, vars);
			}
			if (detail.use(CArg.X)) { mixin(S_TRACE);
				attrs ~= toAttr(c.x, indentValue, vars);
			}
			if (detail.use(CArg.Y)) { mixin(S_TRACE);
				attrs ~= toAttr(c.y, indentValue, vars);
			}
			if (detail.use(CArg.SizeType)) { mixin(S_TRACE);
				attrs ~= toAttr(c.sizeType, indentValue, vars);
			}
			if (detail.use(CArg.Width)) { mixin(S_TRACE);
				attrs ~= toAttr(c.width, indentValue, vars);
			}
			if (detail.use(CArg.Height)) { mixin(S_TRACE);
				attrs ~= toAttr(c.height, indentValue, vars);
			}
			if (detail.use(CArg.Scale)) { mixin(S_TRACE);
				if (c.scale == -1) { mixin(S_TRACE);
					attrs ~= toAttr(Symbol("none"), indentValue, vars);
				} else { mixin(S_TRACE);
					attrs ~= toAttr(c.scale, indentValue, vars);
				}
			}
			if (detail.use(CArg.Layer)) { mixin(S_TRACE);
				if (c.layer == -1) { mixin(S_TRACE);
					attrs ~= toAttr(Symbol("none"), indentValue, vars);
				} else { mixin(S_TRACE);
					attrs ~= toAttr(c.layer, indentValue, vars);
				}
			}
			if (detail.use(CArg.BgImages)) { mixin(S_TRACE);
				attrs ~= toAttr(c.backs, indentValue, vars);
			}
			if (detail.use(CArg.TargetS)) { mixin(S_TRACE);
				attrs ~= toAttr(c.targetS, indentValue, vars);
			}
			if (detail.use(CArg.Range)) { mixin(S_TRACE);
				attrs ~= toAttr(c.range, indentValue, vars);
			}
			if (detail.use(CArg.CastRange)) { mixin(S_TRACE);
				attrs ~= toAttr(c.castRange, indentValue, vars);
			}
			if (detail.use(CArg.KeyCodeRange)) { mixin(S_TRACE);
				attrs ~= toAttr(c.keyCodeRange, indentValue, vars);
			}
			if (detail.use(CArg.TargetIsSkill) || detail.use(CArg.TargetIsItem) || detail.use(CArg.TargetIsBeast) || detail.use(CArg.TargetIsHand)) { mixin(S_TRACE);
				EffectCardType[] effectCardTypes;
				if (detail.use(CArg.TargetIsSkill) && c.targetIsSkill) { mixin(S_TRACE);
					effectCardTypes ~= EffectCardType.Skill;
				}
				if (detail.use(CArg.TargetIsItem) && c.targetIsItem) { mixin(S_TRACE);
					effectCardTypes ~= EffectCardType.Item;
				}
				if (detail.use(CArg.TargetIsBeast) && c.targetIsBeast) { mixin(S_TRACE);
					effectCardTypes ~= EffectCardType.Beast;
				}
				if (detail.use(CArg.TargetIsHand) && c.targetIsHand) { mixin(S_TRACE);
					effectCardTypes ~= EffectCardType.Hand;
				}
				attrs ~= toAttr(effectCardTypes, indentValue, vars);
			}
			if (detail.use(CArg.HoldingCoupon) && c.range is Range.CouponHolder) { mixin(S_TRACE);
				attrs ~= toAttr(c.holdingCoupon, indentValue, vars);
			}
			if (detail.use(CArg.Area)) { mixin(S_TRACE);
				auto a = _summ ? _summ.area(c.area) : null;
				attrs ~= toAttr(vars.id(a, c.area), indentValue, vars);
			}
			if (detail.use(CArg.Battle)) { mixin(S_TRACE);
				auto a = _summ ? _summ.battle(c.battle) : null;
				attrs ~= toAttr(vars.id(a, c.battle), indentValue, vars);
			}
			if (detail.use(CArg.Package)) { mixin(S_TRACE);
				auto a = _summ ? _summ.cwPackage(c.packages) : null;
				attrs ~= toAttr(vars.id(a, c.packages), indentValue, vars);
			}
			if (detail.use(CArg.Cast)) { mixin(S_TRACE);
				auto a = _summ ? _summ.cwCast(c.casts) : null;
				attrs ~= toAttr(vars.id(a, c.casts), indentValue, vars);
			}
			if (detail.use(CArg.Item)) { mixin(S_TRACE);
				auto a = _summ ? _summ.item(c.item) : null;
				attrs ~= toAttr(vars.id(a, c.item), indentValue, vars);
			}
			if (detail.use(CArg.Skill)) { mixin(S_TRACE);
				auto a = _summ ? _summ.skill(c.skill) : null;
				attrs ~= toAttr(vars.id(a, c.skill), indentValue, vars);
			}
			if (detail.use(CArg.Info)) { mixin(S_TRACE);
				auto a = _summ ? _summ.info(c.info) : null;
				attrs ~= toAttr(vars.id(a, c.info), indentValue, vars);
			}
			if (detail.use(CArg.Beast)) { mixin(S_TRACE);
				auto a = _summ ? _summ.beast(c.beast) : null;
				attrs ~= toAttr(vars.id(a, c.beast), indentValue, vars);
			}
			if (detail.use(CArg.Start)) { mixin(S_TRACE);
				attrs ~= toAttr(c.start, indentValue, vars);
			}
			if (detail.use(CArg.Complete)) { mixin(S_TRACE);
				attrs ~= toAttr(c.complete, indentValue, vars);
			}
			if (detail.use(CArg.Money)) { mixin(S_TRACE);
				attrs ~= toAttr(c.money, indentValue, vars);
			}
			if (detail.use(CArg.Coupon)) { mixin(S_TRACE);
				attrs ~= toAttr(c.coupon, indentValue, vars);
			}
			if (detail.use(CArg.CouponValue)) { mixin(S_TRACE);
				attrs ~= toAttr(c.couponValue, indentValue, vars);
			}
			if (detail.use(CArg.CompleteStamp)) { mixin(S_TRACE);
				attrs ~= toAttr(c.completeStamp, indentValue, vars);
			}
			if (detail.use(CArg.KeyCode)) { mixin(S_TRACE);
				attrs ~= toAttr(c.keyCode, indentValue, vars);
			}
			if (detail.use(CArg.Gossip)) { mixin(S_TRACE);
				attrs ~= toAttr(c.gossip, indentValue, vars);
			}
			if (detail.use(CArg.Flag) && detail.use(CArg.Step) && detail.use(CArg.Variant)) { mixin(S_TRACE);
				attrs ~= toAttrVariableType(c.flag, c.step, c.variant);
			} else { mixin(S_TRACE);
				if (detail.use(CArg.Flag)) { mixin(S_TRACE);
					if (_prop && .icmp(_prop.sys.randomValue, c.flag) == 0) { mixin(S_TRACE);
						attrs ~= toAttr(Symbol("random"), indentValue, vars);
					} else { mixin(S_TRACE);
						attrs ~= toAttr(c.flag, indentValue, vars);
					}
				}
				if (detail.use(CArg.Step)) { mixin(S_TRACE);
					if (_prop && .icmp(_prop.sys.randomValue, c.step) == 0) { mixin(S_TRACE);
						attrs ~= toAttr(Symbol("random"), indentValue, vars);
					} else if (_prop && .icmp(_prop.sys.selectedPlayerCardNumber, c.step) == 0) { mixin(S_TRACE);
						attrs ~= toAttr(Symbol("selected"), indentValue, vars); // Wsn.2
					} else { mixin(S_TRACE);
						attrs ~= toAttr(c.step, indentValue, vars);
					}
				}
				if (detail.use(CArg.Variant)) { mixin(S_TRACE);
					attrs ~= toAttr(c.variant, indentValue, vars);
				}
			}
			if (detail.use(CArg.Flag2)) { mixin(S_TRACE);
				attrs ~= toAttr(c.flag2, indentValue, vars);
			}
			if (detail.use(CArg.Step2)) { mixin(S_TRACE);
				attrs ~= toAttr(c.step2, indentValue, vars);
			}
			if (detail.use(CArg.Comparison4)) { mixin(S_TRACE);
				attrs ~= toAttr(c.comparison4, indentValue, vars);
			}
			if (detail.use(CArg.Comparison3)) { mixin(S_TRACE);
				attrs ~= toAttr(c.comparison3, indentValue, vars);
			}
			if (detail.use(CArg.FlagValue)) { mixin(S_TRACE);
				attrs ~= toAttr(c.flagValue, indentValue, vars);
			}
			if (detail.use(CArg.StepValue)) { mixin(S_TRACE);
				attrs ~= toAttr(c.stepValue, indentValue, vars);
			}
			if (detail.use(CArg.CardNumber)) { mixin(S_TRACE);
				if (c.cardNumber != 0) { mixin(S_TRACE);
					attrs ~= toAttr(c.cardNumber, indentValue, vars);
				} else { mixin(S_TRACE);
					attrs ~= toAttr(Symbol("all"), indentValue, vars);
				}
			}
			if (detail.use(CArg.SelectCard)) { mixin(S_TRACE);
				attrs ~= toAttr(c.selectCard, indentValue, vars);
			}
			if (detail.use(CArg.Motions)) { mixin(S_TRACE);
				attrs ~= toAttr(c.motions, indentValue, vars);
			}
			if (detail.use(CArg.CardVisual)) { mixin(S_TRACE);
				attrs ~= toAttr(c.cardVisual, indentValue, vars);
			}
			if (detail.use(CArg.UnsignedLevel)) { mixin(S_TRACE);
				attrs ~= toAttr(c.unsignedLevel, indentValue, vars);
			}
			if (detail.use(CArg.SignedLevel)) { mixin(S_TRACE);
				attrs ~= toAttr(c.signedLevel, indentValue, vars);
			}
			if (detail.use(CArg.LevelMin)) { mixin(S_TRACE);
				attrs ~= toAttr(c.levelMin, indentValue, vars);
			}
			if (detail.use(CArg.LevelMax)) { mixin(S_TRACE);
				attrs ~= toAttr(c.levelMax, indentValue, vars);
			}
			if (detail.use(CArg.Wait)) { mixin(S_TRACE);
				attrs ~= toAttr(c.wait, indentValue, vars);
			}
			if (detail.use(CArg.Percent)) { mixin(S_TRACE);
				attrs ~= toAttr(c.percent, indentValue, vars);
			}
			if (detail.use(CArg.TargetAll)) { mixin(S_TRACE);
				attrs ~= toAttr(c.targetAll, indentValue, vars);
			}
			if (detail.use(CArg.SelectionMethod)) { mixin(S_TRACE);
				attrs ~= toAttr(c.selectionMethod, indentValue, vars);
			}
			if (detail.use(CArg.Average)) { mixin(S_TRACE);
				attrs ~= toAttr(c.average, indentValue, vars);
			}
			if (detail.use(CArg.PartyNumber)) { mixin(S_TRACE);
				attrs ~= toAttr(c.partyNumber, indentValue, vars);
			}
			if (detail.use(CArg.SuccessRate)) { mixin(S_TRACE);
				attrs ~= toAttr(c.successRate, indentValue, vars);
			}
			if (detail.use(CArg.EffectType)) { mixin(S_TRACE);
				attrs ~= toAttr(c.effectType, indentValue, vars);
			}
			if (detail.use(CArg.Resist)) { mixin(S_TRACE);
				attrs ~= toAttr(c.resist, indentValue, vars);
			}
			if (detail.use(CArg.Status)) { mixin(S_TRACE);
				attrs ~= toAttr(c.status, indentValue, vars);
			}
			if (detail.use(CArg.BgmPath)) { mixin(S_TRACE);
				if (c.bgmPath.length) { mixin(S_TRACE);
					attrs ~= toAttr(encodePath(c.bgmPath), indentValue, vars);
				} else { mixin(S_TRACE);
					attrs ~= toAttr(Symbol("stop"), indentValue, vars);
				}
			}
			if (detail.use(CArg.BgmChannel)) { mixin(S_TRACE);
				attrs ~= toAttr(c.bgmChannel, indentValue, vars);
			}
			if (detail.use(CArg.BgmFadeIn)) { mixin(S_TRACE);
				attrs ~= toAttr(c.bgmFadeIn / 100.0, indentValue, vars);
			}
			if (detail.use(CArg.BgmVolume)) { mixin(S_TRACE);
				attrs ~= toAttr(c.bgmVolume, indentValue, vars);
			}
			if (detail.use(CArg.BgmLoopCount)) { mixin(S_TRACE);
				attrs ~= toAttr(c.bgmLoopCount, indentValue, vars);
			}
			if (detail.use(CArg.SoundPath)) { mixin(S_TRACE);
				attrs ~= toAttr(encodePath(c.soundPath), indentValue, vars);
			}
			if (detail.use(CArg.SoundChannel)) { mixin(S_TRACE);
				attrs ~= toAttr(c.soundChannel, indentValue, vars);
			}
			if (detail.use(CArg.SoundFadeIn)) { mixin(S_TRACE);
				attrs ~= toAttr(c.soundFadeIn / 100.0, indentValue, vars);
			}
			if (detail.use(CArg.SoundVolume)) { mixin(S_TRACE);
				attrs ~= toAttr(c.soundVolume, indentValue, vars);
			}
			if (detail.use(CArg.SoundLoopCount)) { mixin(S_TRACE);
				attrs ~= toAttr(c.soundLoopCount, indentValue, vars);
			}
			if (detail.use(CArg.RefAbility)) { mixin(S_TRACE);
				attrs ~= toAttr(c.refAbility, indentValue, vars);
			}
			if (detail.use(CArg.Physical)) { mixin(S_TRACE);
				attrs ~= toAttr(c.physical, indentValue, vars);
			}
			if (detail.use(CArg.Mental)) { mixin(S_TRACE);
				attrs ~= toAttr(c.mental, indentValue, vars);
			}
			if (detail.use(CArg.Round)) { mixin(S_TRACE);
				attrs ~= toAttr(c.round, indentValue, vars);
			}
			if (!legacy) { mixin(S_TRACE);
				if (detail.use(CArg.TransitionSpeed)) { mixin(S_TRACE);
					attrs ~= toAttr(c.transitionSpeed, indentValue, vars);
				}
				if (detail.use(CArg.Transition)) { mixin(S_TRACE);
					attrs ~= toAttr(c.transition, indentValue, vars);
				}
				if (detail.use(CArg.DoAnime)) { mixin(S_TRACE);
					attrs ~= toAttr(c.doAnime, indentValue, vars);
				}
				if (detail.use(CArg.IgnoreEffectBooster)) { mixin(S_TRACE);
					attrs ~= toAttr(c.ignoreEffectBooster, indentValue, vars);
				}
			}
			if (c.talkerNC is Talker.Valued || c.selectionMethod is SelectionMethod.Valued) { mixin(S_TRACE);
				// 評価メンバ
				if (detail.use(CArg.InitValue)) { mixin(S_TRACE);
					attrs ~= toAttr(c.initValue, indentValue, vars);
				}
				if (detail.use(CArg.Coupons)) { mixin(S_TRACE);
					attrs ~= toAttr(c.coupons, indentValue, vars);
				}
			}
			if (detail.use(CArg.SelectionColumns)) { mixin(S_TRACE);
				attrs ~= toAttr(c.selectionColumns, indentValue, vars);
			}
			if (detail.use(CArg.BoundaryCheck)) { mixin(S_TRACE);
				attrs ~= toAttr(c.boundaryCheck, indentValue, vars);
			}
			if (detail.use(CArg.CenteringX)) { mixin(S_TRACE);
				attrs ~= toAttr(c.centeringX, indentValue, vars);
			}
			if (detail.use(CArg.CenteringY)) { mixin(S_TRACE);
				attrs ~= toAttr(c.centeringY, indentValue, vars);
			}
			if (detail.use(CArg.SelectTalker)) { mixin(S_TRACE);
				attrs ~= toAttr(c.selectTalker, indentValue, vars);
			}
			if (detail.use(CArg.InvertResult)) { mixin(S_TRACE);
				attrs ~= toAttr(c.invertResult, indentValue, vars);
			}
			if (detail.use(CArg.StartAction)) { mixin(S_TRACE);
				attrs ~= toAttr(c.startAction, indentValue, vars);
			}
			if (detail.use(CArg.Ignite)) { mixin(S_TRACE);
				attrs ~= toAttr(c.ignite, indentValue, vars);
			}
			if (detail.use(CArg.KeyCodes)) { mixin(S_TRACE);
				attrs ~= toAttr(c.keyCodes, indentValue, vars);
			}
			if (detail.use(CArg.CouponNames)) { mixin(S_TRACE);
				attrs ~= toAttr(c.couponNames, indentValue, vars);
			}
			if (detail.use(CArg.MatchingType)) { mixin(S_TRACE);
				attrs ~= toAttr(c.matchingType, indentValue, vars);
			}
			if (detail.use(CArg.ExpandSPChars)) { mixin(S_TRACE);
				attrs ~= toAttr(c.expandSPChars, indentValue, vars);
			}
			if (detail.use(CArg.ConsumeCard)) { mixin(S_TRACE);
				attrs ~= toAttr(c.consumeCard, indentValue, vars);
			}
			if (detail.use(CArg.CardSpeed)) { mixin(S_TRACE);
				if (c.cardSpeed == -1) { mixin(S_TRACE);
					attrs ~= "default";
				} else { mixin(S_TRACE);
					attrs ~= toAttr(c.cardSpeed, indentValue, vars);
				}
			}
			if (detail.use(CArg.OverrideCardSpeed)) { mixin(S_TRACE);
				attrs ~= toAttr(c.overrideCardSpeed, indentValue, vars);
			}
			if (detail.use(CArg.InitialEffect)) { mixin(S_TRACE);
				attrs ~= toAttr(c.initialEffect, indentValue, vars);
			}
			if (detail.use(CArg.InitialSoundPath)) { mixin(S_TRACE);
				attrs ~= toAttr(encodePath(c.initialSoundPath), indentValue, vars);
			}
			if (detail.use(CArg.InitialSoundChannel)) { mixin(S_TRACE);
				attrs ~= toAttr(c.initialSoundChannel, indentValue, vars);
			}
			if (detail.use(CArg.InitialSoundFadeIn)) { mixin(S_TRACE);
				attrs ~= toAttr(c.initialSoundFadeIn / 100.0, indentValue, vars);
			}
			if (detail.use(CArg.InitialSoundVolume)) { mixin(S_TRACE);
				attrs ~= toAttr(c.initialSoundVolume, indentValue, vars);
			}
			if (detail.use(CArg.InitialSoundLoopCount)) { mixin(S_TRACE);
				attrs ~= toAttr(c.initialSoundLoopCount, indentValue, vars);
			}
			if (detail.use(CArg.AbsorbTo)) { mixin(S_TRACE);
				attrs ~= toAttr(c.absorbTo, indentValue, vars);
			}
			if (detail.use(CArg.BackpackEnabled)) { mixin(S_TRACE);
				attrs ~= toAttr(c.backpackEnabled, indentValue, vars);
			}
			if (detail.use(CArg.Expression)) { mixin(S_TRACE);
				attrs ~= toAttr(c.expression, indentValue, vars, 0, false, true);
			}

			bool useIf = c.next.length > 1;
			bool useSif = c.next.length == 1 && c.next[0].name.length;
			if (!useIf) { mixin(S_TRACE);
				foreach (chld; c.next) { mixin(S_TRACE);
					if (chld.name.length) { mixin(S_TRACE);
						if (detail.nextType is CNextType.Text && chld.name == evtChildOK) { mixin(S_TRACE);
							continue;
						}
						useIf = true;
						break;
					}
				}
			}
			if (attrs.length) { mixin(S_TRACE);
				buf ~= " " ~ std.string.join(attrs, ", ");
			}
			void addIfs(size_t idx, in Content chld) { mixin(S_TRACE);
				buf ~= "\n" ~ indentValue;
				if (useSif) { mixin(S_TRACE);
					buf ~= "sif";
				} else { mixin(S_TRACE);
					buf ~= idx == 0 ? "if" : "elif";
				}
				if (detail.nextType !is CNextType.None) { mixin(S_TRACE);
					buf ~= " ";
				}
				final switch (detail.nextType) {
				case CNextType.None:
					break;
				case CNextType.Text:
					buf ~= createString(chld.name);
					break;
				case CNextType.Bool:
					buf ~= icmp(chld.name, _prop.sys.evtChildTrue) == 0 ? "true" : "false";
					break;
				case CNextType.Step:
				case CNextType.IdArea:
				case CNextType.IdBattle:
					if (icmp(chld.name, _prop.sys.evtChildDefault) == 0) { mixin(S_TRACE);
						buf ~= "default";
					} else { mixin(S_TRACE);
						buf ~= chld.name;
					}
					break;
				case CNextType.Trio:
					buf ~= createString(chld.name);
					break;
				case CNextType.Coupon: // Wsn.2
					buf ~= chld.name == "" ? "none" : createString(chld.name);
					break;
				}
			}
			if ((!useIf || useSif) && c.next.length == 1) { mixin(S_TRACE);
				if (useIf) { mixin(S_TRACE);
					addIfs(0, c.next[0]);
				}
				buf ~= "\n";
				if (c.type is CType.Start) { mixin(S_TRACE);
					indentValue ~= indent;
				}
				c = c.next[0];
				continue; // 再帰の回避
			} else { mixin(S_TRACE);
				foreach (idx, chld; c.next) { mixin(S_TRACE);
					if (useIf) { mixin(S_TRACE);
						addIfs(idx, chld);
						buf ~= "\n";
						auto nextIndent = useSif ? indentValue : indentValue ~ indent;
						toScriptImpl(evtChildOK, buf, chld, indent, nextIndent, keys, vars, legacy);
					} else { mixin(S_TRACE);
						buf ~= "\n";
						if (c.type is CType.Start) { mixin(S_TRACE);
							toScriptImpl(evtChildOK, buf, chld, indent, indentValue ~ indent, keys, vars, legacy);
						} else { mixin(S_TRACE);
							toScriptImpl(evtChildOK, buf, chld, indent, indentValue, keys, vars, legacy);
						}
					}
				}
				if (useIf && !useSif) { mixin(S_TRACE);
					buf ~= "\n" ~ indentValue ~ "fi";
				}
				break;
			}
		}
	}
}

private string validVarName(string name) { mixin(S_TRACE);
	char[] buf;
	buf.length = name.length;
	foreach (i, char c; name) { mixin(S_TRACE);
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

/// CWXスクリプトのキーワード情報。
struct CWXScriptKeyword {
	string keyword; /// キーワード。
	string type; /// キーワードのタイプ名。
	string name; /// キーワード名。
}

/// キーワード情報の一覧を返す。
CWXScriptKeyword[] keywordInfos(in CProps prop, in ElementOverride[Element] eTbl) { mixin(S_TRACE);
	return [
		// TRUE/FALSE
		CWXScriptKeyword("true", "", prop.msgs.flagOn),
		CWXScriptKeyword("false", "", prop.msgs.flagOff),

		// 背景切替方式
		CWXScriptKeyword("default", prop.msgs.transition, prop.msgs.transitionName(Transition.Default)),
		CWXScriptKeyword("none", prop.msgs.transition, prop.msgs.transitionName(Transition.None)),
		CWXScriptKeyword("thread", prop.msgs.transition, prop.msgs.transitionName(Transition.Blinds)),
		CWXScriptKeyword("shave", prop.msgs.transition, prop.msgs.transitionName(Transition.PixelDissolve)),
		CWXScriptKeyword("fade", prop.msgs.transition, prop.msgs.transitionName(Transition.Fade)),

		// 文字装飾
		CWXScriptKeyword("bold", prop.msgs.fontStyle, prop.msgs.bold),
		CWXScriptKeyword("italic", prop.msgs.fontStyle, prop.msgs.italic),
		CWXScriptKeyword("underline", prop.msgs.fontStyle, prop.msgs.underline),
		CWXScriptKeyword("strike", prop.msgs.fontStyle, prop.msgs.strike),
		CWXScriptKeyword("vertical", prop.msgs.fontStyle, prop.msgs.vertical),
		CWXScriptKeyword("antialias", prop.msgs.fontStyle, prop.msgs.antialias),
		CWXScriptKeyword("border1", prop.msgs.bordering, prop.msgs.borderingTypeName(BorderingType.Outline)),
		CWXScriptKeyword("border2", prop.msgs.bordering, prop.msgs.borderingTypeName(BorderingType.Inline)),

		// 色合成方式
		CWXScriptKeyword("normal", prop.msgs.blendMode, prop.msgs.blendModeName(BlendMode.Normal)),
		CWXScriptKeyword("add", prop.msgs.blendMode, prop.msgs.blendModeName(BlendMode.Add)),
		CWXScriptKeyword("sub", prop.msgs.blendMode, prop.msgs.blendModeName(BlendMode.Subtract)),
		CWXScriptKeyword("mul", prop.msgs.blendMode, prop.msgs.blendModeName(BlendMode.Multiply)),

		// グラデーション方向
		CWXScriptKeyword("none", prop.msgs.gradient, prop.msgs.gradientDirName(GradientDir.None)),
		CWXScriptKeyword("h", prop.msgs.gradient, prop.msgs.gradientDirName(GradientDir.LeftToRight)),
		CWXScriptKeyword("v", prop.msgs.gradient, prop.msgs.gradientDirName(GradientDir.TopToBottom)),

		// 効果
		CWXScriptKeyword("heal", prop.msgs.motion, prop.msgs.motionName(MType.Heal)),
		CWXScriptKeyword("damage", prop.msgs.motion, prop.msgs.motionName(MType.Damage)),
		CWXScriptKeyword("absorb", prop.msgs.motion, prop.msgs.motionName(MType.Absorb)),
		CWXScriptKeyword("paralyze", prop.msgs.motion, prop.msgs.motionName(MType.Paralyze)),
		CWXScriptKeyword("disparalyze", prop.msgs.motion, prop.msgs.motionName(MType.DisParalyze)),
		CWXScriptKeyword("poison", prop.msgs.motion, prop.msgs.motionName(MType.Poison)),
		CWXScriptKeyword("dispoison", prop.msgs.motion, prop.msgs.motionName(MType.DisPoison)),
		CWXScriptKeyword("getspilit", prop.msgs.motion, prop.msgs.motionName(MType.GetSkillPower)),
		CWXScriptKeyword("losespilit", prop.msgs.motion, prop.msgs.motionName(MType.LoseSkillPower)),
		CWXScriptKeyword("sleep", prop.msgs.motion, prop.msgs.motionName(MType.Sleep)),
		CWXScriptKeyword("confuse", prop.msgs.motion, prop.msgs.motionName(MType.Confuse)),
		CWXScriptKeyword("overheat", prop.msgs.motion, prop.msgs.motionName(MType.Overheat)),
		CWXScriptKeyword("brave", prop.msgs.motion, prop.msgs.motionName(MType.Brave)),
		CWXScriptKeyword("panic", prop.msgs.motion, prop.msgs.motionName(MType.Panic)),
		CWXScriptKeyword("resetmind", prop.msgs.motion, prop.msgs.motionName(MType.Normal)),
		CWXScriptKeyword("bind", prop.msgs.motion, prop.msgs.motionName(MType.Bind)),
		CWXScriptKeyword("disbind", prop.msgs.motion, prop.msgs.motionName(MType.DisBind)),
		CWXScriptKeyword("silence", prop.msgs.motion, prop.msgs.motionName(MType.Silence)),
		CWXScriptKeyword("dissilence", prop.msgs.motion, prop.msgs.motionName(MType.DisSilence)),
		CWXScriptKeyword("faceup", prop.msgs.motion, prop.msgs.motionName(MType.FaceUp)),
		CWXScriptKeyword("facedown", prop.msgs.motion, prop.msgs.motionName(MType.FaceDown)),
		CWXScriptKeyword("antimagic", prop.msgs.motion, prop.msgs.motionName(MType.AntiMagic)),
		CWXScriptKeyword("disantimagic", prop.msgs.motion, prop.msgs.motionName(MType.DisAntiMagic)),
		CWXScriptKeyword("enhaction", prop.msgs.motion, prop.msgs.motionName(MType.EnhanceAction)),
		CWXScriptKeyword("enhavoid", prop.msgs.motion, prop.msgs.motionName(MType.EnhanceAvoid)),
		CWXScriptKeyword("enhresist", prop.msgs.motion, prop.msgs.motionName(MType.EnhanceDefense)),
		CWXScriptKeyword("enhdefense", prop.msgs.motion, prop.msgs.motionName(MType.EnhanceResist)),
		CWXScriptKeyword("vantarget", prop.msgs.motion, prop.msgs.motionName(MType.VanishTarget)),
		CWXScriptKeyword("vancard", prop.msgs.motion, prop.msgs.motionName(MType.VanishCard)),
		CWXScriptKeyword("vanbeast", prop.msgs.motion, prop.msgs.motionName(MType.VanishBeast)),
		CWXScriptKeyword("dealattack", prop.msgs.motion, prop.msgs.motionName(MType.DealAttackCard)),
		CWXScriptKeyword("dealpowerful", prop.msgs.motion, prop.msgs.motionName(MType.DealPowerfulAttackCard)),
		CWXScriptKeyword("dealcritical", prop.msgs.motion, prop.msgs.motionName(MType.DealCriticalAttackCard)),
		CWXScriptKeyword("dealfeint", prop.msgs.motion, prop.msgs.motionName(MType.DealFeintCard)),
		CWXScriptKeyword("dealdefense", prop.msgs.motion, prop.msgs.motionName(MType.DealDefenseCard)),
		CWXScriptKeyword("dealdistance", prop.msgs.motion, prop.msgs.motionName(MType.DealDistanceCard)),
		CWXScriptKeyword("dealconfuse", prop.msgs.motion, prop.msgs.motionName(MType.DealConfuseCard)),
		CWXScriptKeyword("dealskill", prop.msgs.motion, prop.msgs.motionName(MType.DealSkillCard)),
		CWXScriptKeyword("cancelaction", prop.msgs.motion, prop.msgs.motionName(MType.CancelAction)),
		CWXScriptKeyword("summon", prop.msgs.motion, prop.msgs.motionName(MType.SummonBeast)),
		CWXScriptKeyword("noeffect", prop.msgs.motion, prop.msgs.motionName(MType.NoEffect)),

		// 効果値計算方式
		CWXScriptKeyword("level", prop.msgs.calcType, prop.msgs.damageTypeName(DamageType.LevelRatio)),
		CWXScriptKeyword("value", prop.msgs.calcType, prop.msgs.damageTypeName(DamageType.Normal)),
		CWXScriptKeyword("max", prop.msgs.calcType, prop.msgs.damageTypeName(DamageType.Max)),

		// 属性
		CWXScriptKeyword("all", prop.msgs.motionElement, Element.All in eTbl && eTbl[Element.All].name != "" ? eTbl[Element.All].name : prop.msgs.elementName(Element.All)),
		CWXScriptKeyword("phy", prop.msgs.motionElement, Element.Health in eTbl && eTbl[Element.Health].name != "" ? eTbl[Element.Health].name : prop.msgs.elementName(Element.Health)),
		CWXScriptKeyword("mind", prop.msgs.motionElement, Element.Mind in eTbl && eTbl[Element.Mind].name != "" ? eTbl[Element.Mind].name : prop.msgs.elementName(Element.Mind)),
		CWXScriptKeyword("holy", prop.msgs.motionElement, Element.Miracle in eTbl && eTbl[Element.Miracle].name != "" ? eTbl[Element.Miracle].name : prop.msgs.elementName(Element.Miracle)),
		CWXScriptKeyword("magic", prop.msgs.motionElement, Element.Magic in eTbl && eTbl[Element.Magic].name != "" ? eTbl[Element.Magic].name : prop.msgs.elementName(Element.Magic)),
		CWXScriptKeyword("fire", prop.msgs.motionElement, Element.Fire in eTbl && eTbl[Element.Fire].name != "" ? eTbl[Element.Fire].name : prop.msgs.elementName(Element.Fire)),
		CWXScriptKeyword("ice", prop.msgs.motionElement, Element.Ice in eTbl && eTbl[Element.Ice].name != "" ? eTbl[Element.Ice].name : prop.msgs.elementName(Element.Ice)),

		// 視覚効果
		CWXScriptKeyword("none", prop.msgs.effectVisual, prop.msgs.cardVisualName(CardVisual.None)),
		CWXScriptKeyword("reverse", prop.msgs.effectVisual, prop.msgs.cardVisualName(CardVisual.Reverse)),
		CWXScriptKeyword("hswing", prop.msgs.effectVisual, prop.msgs.cardVisualName(CardVisual.Horizontal)),
		CWXScriptKeyword("vswing", prop.msgs.effectVisual, prop.msgs.cardVisualName(CardVisual.Vertical)),

		// 効果属性
		CWXScriptKeyword("physic", prop.msgs.elementProps, prop.msgs.effectTypeName(EffectType.Physic)),
		CWXScriptKeyword("magic", prop.msgs.elementProps, prop.msgs.effectTypeName(EffectType.Magic)),
		CWXScriptKeyword("mphysic", prop.msgs.elementProps, prop.msgs.effectTypeName(EffectType.MagicalPhysic)),
		CWXScriptKeyword("pmagic", prop.msgs.elementProps, prop.msgs.effectTypeName(EffectType.PhysicalMagic)),
		CWXScriptKeyword("none", prop.msgs.elementProps, prop.msgs.effectTypeName(EffectType.None)),

		// 抵抗属性
		CWXScriptKeyword("avoid", prop.msgs.resistProps, prop.msgs.resistName(Resist.Avoid)),
		CWXScriptKeyword("resist", prop.msgs.resistProps, prop.msgs.resistName(Resist.Resist)),
		CWXScriptKeyword("unfail", prop.msgs.resistProps, prop.msgs.resistName(Resist.Unfail)),

		// 話者
		CWXScriptKeyword("none", prop.msgs.talker, prop.msgs.scTalkerNameNarration),
		CWXScriptKeyword("M", prop.msgs.talker, prop.msgs.talkerName(Talker.Selected)),
		CWXScriptKeyword("U", prop.msgs.talker, prop.msgs.talkerName(Talker.Unselected)),
		CWXScriptKeyword("R", prop.msgs.talker, prop.msgs.talkerName(Talker.Random)),
		CWXScriptKeyword("C", prop.msgs.talker, prop.msgs.talkerName(Talker.Card)),
		CWXScriptKeyword("V", prop.msgs.talker, prop.msgs.scTalkerNameValued),

		// 適用範囲
		CWXScriptKeyword("M", prop.msgs.range, prop.msgs.rangeName(Range.Selected)),
		CWXScriptKeyword("R", prop.msgs.range, prop.msgs.rangeName(Range.Random)),
		CWXScriptKeyword("T", prop.msgs.range, prop.msgs.rangeName(Range.Party)),
		CWXScriptKeyword("backpack", prop.msgs.range, prop.msgs.rangeName(Range.Backpack)),
		CWXScriptKeyword("party", prop.msgs.range, prop.msgs.rangeName(Range.PartyAndBackpack)),
		CWXScriptKeyword("field", prop.msgs.range, prop.msgs.rangeName(Range.Field)),
		CWXScriptKeyword("selcard", prop.msgs.range, prop.msgs.rangeName(Range.SelectedCard)),

		// 身体特性
		CWXScriptKeyword("dex", prop.msgs.aptPhysical, prop.msgs.physicalName(Physical.Dex)),
		CWXScriptKeyword("agl", prop.msgs.aptPhysical, prop.msgs.physicalName(Physical.Agl)),
		CWXScriptKeyword("int", prop.msgs.aptPhysical, prop.msgs.physicalName(Physical.Int)),
		CWXScriptKeyword("str", prop.msgs.aptPhysical, prop.msgs.physicalName(Physical.Str)),
		CWXScriptKeyword("vit", prop.msgs.aptPhysical, prop.msgs.physicalName(Physical.Vit)),
		CWXScriptKeyword("min", prop.msgs.aptPhysical, prop.msgs.physicalName(Physical.Min)),

		// 精神特性
		CWXScriptKeyword("agg", prop.msgs.aptMental, prop.msgs.mentalName(Mental.Aggressive)),
		CWXScriptKeyword("unagg", prop.msgs.aptMental, prop.msgs.mentalName(Mental.Unaggressive)),
		CWXScriptKeyword("cheerf", prop.msgs.aptMental, prop.msgs.mentalName(Mental.Cheerful)),
		CWXScriptKeyword("uncheerf", prop.msgs.aptMental, prop.msgs.mentalName(Mental.Uncheerful)),
		CWXScriptKeyword("brave", prop.msgs.aptMental, prop.msgs.mentalName(Mental.Brave)),
		CWXScriptKeyword("unbrave", prop.msgs.aptMental, prop.msgs.mentalName(Mental.Unbrave)),
		CWXScriptKeyword("caut", prop.msgs.aptMental, prop.msgs.mentalName(Mental.Cautious)),
		CWXScriptKeyword("uncaut", prop.msgs.aptMental, prop.msgs.mentalName(Mental.Uncautious)),
		CWXScriptKeyword("trick", prop.msgs.aptMental, prop.msgs.mentalName(Mental.Trickish)),
		CWXScriptKeyword("untrick", prop.msgs.aptMental, prop.msgs.mentalName(Mental.Untrickish)),

		// 状態
		CWXScriptKeyword("none", prop.msgs.status, prop.msgs.statusName(Status.None)),
		CWXScriptKeyword("active", prop.msgs.status, prop.msgs.statusName(Status.Active)),
		CWXScriptKeyword("inactive", prop.msgs.status, prop.msgs.statusName(Status.Inactive)),
		CWXScriptKeyword("alive", prop.msgs.status, prop.msgs.statusName(Status.Alive)),
		CWXScriptKeyword("dead", prop.msgs.status, prop.msgs.statusName(Status.Dead)),
		CWXScriptKeyword("fine", prop.msgs.status, prop.msgs.statusName(Status.Fine)),
		CWXScriptKeyword("injured", prop.msgs.status, prop.msgs.statusName(Status.Injured)),
		CWXScriptKeyword("heavyinjured", prop.msgs.status, prop.msgs.statusName(Status.HeavyInjured)),
		CWXScriptKeyword("unconscious", prop.msgs.status, prop.msgs.statusName(Status.Unconscious)),
		CWXScriptKeyword("poison", prop.msgs.status, prop.msgs.statusName(Status.Poison)),
		CWXScriptKeyword("sleep", prop.msgs.status, prop.msgs.statusName(Status.Sleep)),
		CWXScriptKeyword("bind", prop.msgs.status, prop.msgs.statusName(Status.Bind)),
		CWXScriptKeyword("paralyze", prop.msgs.status, prop.msgs.statusName(Status.Paralyze)),
		CWXScriptKeyword("confuse", prop.msgs.status, prop.msgs.statusName(Status.Confuse)),
		CWXScriptKeyword("overheat", prop.msgs.status, prop.msgs.statusName(Status.Overheat)),
		CWXScriptKeyword("brave", prop.msgs.status, prop.msgs.statusName(Status.Brave)),
		CWXScriptKeyword("panic", prop.msgs.status, prop.msgs.statusName(Status.Panic)),
		CWXScriptKeyword("silence", prop.msgs.status, prop.msgs.statusName(Status.Silence)),
		CWXScriptKeyword("faceup", prop.msgs.status, prop.msgs.statusName(Status.FaceUp)),
		CWXScriptKeyword("antimagic", prop.msgs.status, prop.msgs.statusName(Status.AntiMagic)),
		CWXScriptKeyword("upaction", prop.msgs.status, prop.msgs.statusName(Status.UpAction)),
		CWXScriptKeyword("upavoid", prop.msgs.status, prop.msgs.statusName(Status.UpAvoid)),
		CWXScriptKeyword("upresit", prop.msgs.status, prop.msgs.statusName(Status.UpResist)),
		CWXScriptKeyword("updefense", prop.msgs.status, prop.msgs.statusName(Status.UpDefense)),
		CWXScriptKeyword("downaction", prop.msgs.status, prop.msgs.statusName(Status.DownAction)),
		CWXScriptKeyword("downavoid", prop.msgs.status, prop.msgs.statusName(Status.DownAvoid)),
		CWXScriptKeyword("downresit", prop.msgs.status, prop.msgs.statusName(Status.DownResist)),
		CWXScriptKeyword("downdefense", prop.msgs.status, prop.msgs.statusName(Status.DownDefense)),

		// 選択対象
		CWXScriptKeyword("party", prop.msgs.selectMember, .tryFormat(prop.msgs.castRange1, prop.msgs.castRangeName(CastRange.Party))),
		CWXScriptKeyword("enemy", prop.msgs.selectMember, .tryFormat(prop.msgs.castRange1, prop.msgs.castRangeName(CastRange.Enemy))),
		CWXScriptKeyword("npc", prop.msgs.selectMember, .tryFormat(prop.msgs.castRange1, prop.msgs.castRangeName(CastRange.Npc))),

		// カード種類
		CWXScriptKeyword("all", prop.msgs.cardType, prop.msgs.effectCardTypeName(EffectCardType.All)),
		CWXScriptKeyword("skill", prop.msgs.cardType, prop.msgs.effectCardTypeName(EffectCardType.Skill)),
		CWXScriptKeyword("item", prop.msgs.cardType, prop.msgs.effectCardTypeName(EffectCardType.Item)),
		CWXScriptKeyword("beast", prop.msgs.cardType, prop.msgs.effectCardTypeName(EffectCardType.Beast)),
		CWXScriptKeyword("hand", prop.msgs.cardType, prop.msgs.effectCardTypeName(EffectCardType.Hand)),

		// マッチングタイプ (Wsn.2)
		CWXScriptKeyword("and", prop.msgs.matchingType, prop.msgs.matchingTypeName(MatchingType.And)),
		CWXScriptKeyword("or", prop.msgs.matchingType, prop.msgs.matchingTypeName(MatchingType.Or)),

		// 更新タイプ(Wsn.4)
		CWXScriptKeyword("fixed", prop.msgs.updateType, prop.msgs.updateTypeName(UpdateType.Fixed)),
		CWXScriptKeyword("variables", prop.msgs.updateType, prop.msgs.updateTypeName(UpdateType.Variables)),
		CWXScriptKeyword("all", prop.msgs.updateType, prop.msgs.updateTypeName(UpdateType.All)),

		// 状況設定(Wsn.4)
		CWXScriptKeyword("none", prop.msgs.environmentStatus, prop.msgs.environmentStatusName(EnvironmentStatus.NotSet)),
		CWXScriptKeyword("on", prop.msgs.environmentStatus, prop.msgs.environmentStatusName(EnvironmentStatus.Enable)),
		CWXScriptKeyword("off", prop.msgs.environmentStatus, prop.msgs.environmentStatusName(EnvironmentStatus.Disable)),

		// 状態変数タイプ(Wsn.4)
		CWXScriptKeyword("flag", prop.msgs.variableType, prop.msgs.variableTypeName(VariableType.Flag)),
		CWXScriptKeyword("step", prop.msgs.variableType, prop.msgs.variableTypeName(VariableType.Step)),
		CWXScriptKeyword("variant", prop.msgs.variableType, prop.msgs.variableTypeName(VariableType.Variant)),
	];
}
