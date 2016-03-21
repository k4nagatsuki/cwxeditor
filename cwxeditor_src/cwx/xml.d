
module cwx.xml;

import cwx.perf;
import cwx.utils : debugln;

import std.conv;
import std.string;
import d2std.xml;

/// XML文書処理用の構造体。
struct XNode {
	private Element _el = null;

	private static E ps(E)(ElementParser ep) { mixin(S_TRACE);
		auto e = new E(ep.tag);
		ep.onText((string text) {e ~= new Text(text);});
		ep.onCData((string cdata) {e ~= new CData(cdata);});
		ep.onComment((string comment) {e ~= new Comment(comment);});
		ep.onPI((string pi) {e ~= new ProcessingInstruction(pi);});
		ep.onXI((string xi) {e.items ~= new XMLInstruction(xi);});
		ep.onStartTag[null] = (ElementParser ep) {e ~= ps!(Element)(ep);};
		ep.parse();
		return e;
	}
	/// xmlの処理を開始する。
	static XNode parse(string xml) { mixin(S_TRACE);
		if (!xml.stripLeft().startsWith("<")) throw new Exception("Invalid XML: " ~ xml);
		XNode node;
		node._el = ps!(Document)(new DocumentParser(xml));
		return node;
	}
	/// 新規にDOMを生成する。
	static XNode create(string rootName, string value = "") { mixin(S_TRACE);
		XNode node;
		node._el = new Document(new Tag(rootName));
		node._el ~= new Text(value);
		return node;
	}

	/// 現在処理中の要素の名前。
	@property
	const
	string name() {return _el.tag.name;}
	/// 現在処理中の要素のテキスト。
	@property
	const
	string value() { mixin(S_TRACE);
		string r = _el.text();
		if (r == "\n") r = "";
		return r;
	}
	/// ditto
	@property
	void value(string text) { mixin(S_TRACE);
		_el ~= new Text(text);
	}
	/// ditto
	@property
	const
	T valueTo(T)() {return to!(T)(value);}

	/// 子要素を生成する。
	XNode newElement(T = string)(string name, T value = T.init) { mixin(S_TRACE);
		auto e = new Element(name, to!(string)(value));
		_el ~= e;
		return XNode(e, null);
	}
	/// 属性を生成する。
	void newAttr(T)(string name, T value) { mixin(S_TRACE);
		_el.tag.attr[name] = to!(string)(value);
	}
	/// 属性nameの値を返す。
	/// nothingIsErrorにtrueを指定すると、nameが存在しなかった際に例外を投げる。
	const
	T attr(T = string)(string name, bool nothingIsError, lazy T defaultValue = T.init) { mixin(S_TRACE);
		auto p = name in _el.tag.attr;
		if (nothingIsError && !p) throw new Exception(name ~ " not found");
		if (!p) return defaultValue;
		return to!(T)(*p);
	}
	/// 属性nameが存在すればtrueを返す。
	const
	bool hasAttr(string name) { return (name in _el.tag.attr) !is null; }
	/// 子要素nameを一つだけ探し出してテキストを返す。
	T childText(T = string)(string name, bool nothingIsError) { mixin(S_TRACE);
		auto node = child(name, nothingIsError);
		return node.valid ? node.value : null;
	}
	/// 子要素nameを一つだけ探し出して返す。
	XNode child(string name, bool nothingIsError) { mixin(S_TRACE);
		foreach (el; _el.elements) { mixin(S_TRACE);
			if (el.tag.name == name) { mixin(S_TRACE);
				return XNode(el);
			}
		}
		if (nothingIsError) throw new Exception(name ~ " not found");
		return XNode(null);
	}
	/// 有効なXNodeであればtrue。
	@property
	const
	bool valid() {return _el !is null;}
	/// 要素名と、その要素を発見した際に処理を行うハンドラを登録する。
	/// 要素名にnullを指定する事により、特に指定された要素以外を
	/// 処理するハンドラを登録できる。
	void delegate(ref XNode)[string] onTag;
	/// 子要素を探し、結果をハンドラに渡す。
	void parse() { mixin(S_TRACE);
		foreach (el; _el.elements) { mixin(S_TRACE);
			auto p = el.tag.name in onTag;
			if (!p) p = null in onTag;
			XNode node;
			node._el = el;
			if (p) (*p)(node);
		}
		typeof(onTag) init;
		onTag = init;
	}

	/// 処理中の要素が文書ルートであればtrue。
	@property
	const
	bool isRoot() {return cast(Document) _el !is null;}

	/// 文書全体をテキストにして返す。
	/// ルート要素以外では使用不可。
	@property
	const
	string text() { mixin(S_TRACE);
		if (!isRoot) throw new Exception("Node is not Root: " ~ name);
		return (cast(Document) _el).prolog ~ "\n" ~ std.string.join(_el.pretty(0), "\n");
	}
}
