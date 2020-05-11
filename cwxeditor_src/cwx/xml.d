
module cwx.xml;

import cwx.perf;
import cwx.utils : debugln;

import std.conv;
import std.string;
import std.xml;

/// XML文書処理用の構造体。
struct XNode {
	private Element _el = null;

	private static E ps(E)(ElementParser ep) { mixin(S_TRACE);
		auto e = new E(ep.tag);
		ep.onText((string text) { e ~= new Text(text); });
		ep.onCData((string cdata) { e ~= new CData(cdata); });
		ep.onComment((string comment) { e ~= new Comment(comment); });
		ep.onPI((string pi) { e ~= new ProcessingInstruction(pi); });
		ep.onXI((string xi) { e.items ~= new XMLInstruction(xi); });
		ep.onStartTag[null] = (ElementParser ep) { e ~= ps!(Element)(ep); };
		ep.parse();
		return e;
	}
	/// xmlの処理を開始する。
	static XNode parse(string xml) { mixin(S_TRACE);
		xml = xml.stripLeft();
		if (!xml.startsWith("<")) throw new Exception("Invalid XML: " ~ xml);
		XNode node;
		if (xml[1..$].indexOf("<") == -1) throw new Exception("Invalid XML: " ~ xml);
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
	string name() { return _el.tag.name; }

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
	T valueTo(T)() { return to!(T)(value); }

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

	unittest {
		debug mixin(UTPerf);
		auto node0 = XNode.create("xnode");
		node0.newAttr("xnode_attr1", "attr1");
		node0.newAttr("xnode_attr2", 2);
		auto ce = node0.newElement("children");
		ce.newAttr("children_attr", true);
		auto cce1 = ce.newElement("child", true);
		cce1.newAttr("child_attr", 12.25);
		auto cce2 = ce.newElement("child");
		cce2.newAttr("child_attr", "attr5");
		auto xml = node0.text;

		auto node = XNode.parse(xml);
		assert (node.valid);
		assert (node.name == "xnode");
		assert (!node.hasAttr("xnode_attr0"));
		assert (node.hasAttr("xnode_attr1"));
		assert (node.attr("xnode_attr1", true) == "attr1");
		assert (node.attr("xnode_attr0", false, "def") == "def");
		try {
			node.attr("xnode_attr0", true);
			assert (0);
		} catch (Exception e) { }
		assert (node.hasAttr("xnode_attr2"));
		assert (node.attr!int("xnode_attr2", true) == 2);
		auto ce2 = node.child("children", true);
		assert (ce2.name == "children");
		assert (ce2.valid);
		assert (ce2.hasAttr("children_attr"));
		assert (ce2.attr!bool("children_attr", true));
		auto count = 0;
		ce2.onTag["child"] = (ref node) {
			if (count == 0) {
				assert (node.name == "child");
				assert (node.value == "true");
				assert (node.valueTo!bool);
				assert (!node.hasAttr("xnode_attr1"));
				assert (node.attr("xnode_attr1", false, "def") == "def");
				try {
					node.attr("xnode_attr1", true);
					assert (0);
				} catch (Exception e) { }
				assert (node.hasAttr("child_attr"));
				assert (node.attr!double("child_attr", true) == 12.25);
			} else if (count == 1) {
				assert (node.name == "child");
				assert (node.value == "");
				assert (!node.hasAttr("xnode_attr1"));
				assert (node.attr("xnode_attr1", false, "def") == "def");
				try {
					node.attr("xnode_attr1", true);
					assert (0);
				} catch (Exception e) { }
				assert (node.hasAttr("child_attr"));
				assert (node.attr("child_attr", true) == "attr5");
			} else assert (0);
			count++;
		};
		ce2.parse();
		assert (count == 2);
	}

	/// 子要素nameを一つだけ探し出してテキストを返す。
	T childText(T = string)(string name, bool nothingIsError) { mixin(S_TRACE);
		auto node = child(name, nothingIsError);
		return node.valid ? node.value : null;
	} unittest {
		debug mixin(UTPerf);
		auto xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<xnode>\n<children attr0=\"???\">text_children\n<child attr1=\"1\" attr2=\"attr\">text_child</child>\n<child/>\n</children>\n</xnode>";
		auto node = XNode.parse(xml);
		assert (node.valid);
		node.parse();
		assert (!node.childText("child", false));
		try {
			node.childText("child", true);
			assert (0);
		} catch (Exception e) { }
		auto cNode = node.child("children", true);
		assert (!cNode.childText("children", false));
		try {
			cNode.childText("children", true);
			assert (0);
		} catch (Exception e) { }
		assert (cNode.childText("child", true) == "text_child");
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
	} unittest {
		debug mixin(UTPerf);
		auto xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<xnode>\n<children attr0=\"???\">\n<child attr1=\"1\" attr2=\"attr\"/>\n<child/>\n</children>\n</xnode>";
		auto node = XNode.parse(xml);
		assert (node.valid);
		node.parse();
		assert (!node.child("child", false).valid);
		try {
			node.child("child", true);
			assert (0);
		} catch (Exception e) { }
		auto cNode = node.child("children", true);
		assert (cNode.valid);
		assert (cNode.hasAttr("attr0"));
		assert (cNode.attr("attr0", true) == "???");
		cNode.parse();
		assert (!cNode.child("children", false).valid);
		try {
			cNode.child("children", true);
			assert (0);
		} catch (Exception e) { }
		auto ccNode = cNode.child("child", true);
		assert (ccNode.valid);
		assert (ccNode.hasAttr("attr1"));
		assert (ccNode.attr("attr1", true) == "1");
		assert (ccNode.hasAttr("attr2"));
		assert (ccNode.attr("attr2", true) == "attr");
	}

	/// 有効なXNodeであればtrue。
	@property
	const
	bool valid() { return _el !is null; }

	/// 要素名と、その要素を発見した際に処理を行うハンドラを登録する。
	/// 要素名にnullを指定する事により、特に指定された要素以外を
	/// 処理するハンドラを登録できる。
	void delegate(ref XNode)[string] onTag;

	/// 子要素を探し、結果をハンドラに渡す。
	void parse() { mixin(S_TRACE);
		if (onTag.length == 0) return;
		foreach (el; _el.elements) { mixin(S_TRACE);
			auto p = el.tag.name in onTag;
			if (!p) p = null in onTag;
			XNode node;
			node._el = el;
			if (p) (*p)(node);
		}
		onTag = null;
	} unittest {
		debug mixin(UTPerf);
		auto xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<xnode>\n<children attr0=\"???\">\n<child attr1=\"1\" attr2=\"attr\"/>\n<child/>\n</children>\n</xnode>";
		auto node = XNode.parse(xml);
		assert (node.valid);
		auto count0 = 0;
		node.onTag["children"] = (ref node) { mixin(S_TRACE);
			assert (node.valid);
			assert (!node.isRoot);
			assert (node.hasAttr("attr0"));
			assert (node.attr("attr0", true) == "???");
			auto count1 = 0;
			node.onTag["child"] = (ref node) { mixin(S_TRACE);
				assert (!node.isRoot);
				if (count1 == 0) { mixin(S_TRACE);
					assert (node.hasAttr("attr1"));
					assert (node.hasAttr("attr2"));
					assert (node.attr("attr1", true) == "1");
					assert (node.attr("attr2", true) == "attr");
				} else if (count1 == 1) { mixin(S_TRACE);
					assert (!node.hasAttr("attr1"));
					assert (!node.hasAttr("attr2"));
				} else assert (0);
				count1++;
			};
			node.parse();
			assert (count1 == 2);
			count0++;
		};
		node.onTag["child"] = (ref node) { mixin(S_TRACE);
			assert (0);
		};
		node.parse();
		assert (count0 == 1);
	}

	/// 処理中の要素が文書ルートであればtrue。
	@property
	const
	bool isRoot() { mixin(S_TRACE);
		return cast(Document)_el !is null;
	} unittest {
		debug mixin(UTPerf);
		auto xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<xnode>\n<children attr0=\"???\">\n<child attr1=\"1\" attr2=\"attr\"/>\n</children>\n</xnode>";
		auto node = XNode.parse(xml);
		assert (node.valid);
		assert (node.isRoot);
		node.onTag["children"] = (ref node) { mixin(S_TRACE);
			assert (!node.isRoot);
			node.onTag["child"] = (ref node) { mixin(S_TRACE);
				assert (!node.isRoot);
			};
			node.parse();
		};
		node.parse();
		assert (node.child("children", true).valid);
		assert (!node.child("children", true).isRoot);
	}

	/// 文書全体をテキストにして返す。
	/// ルート要素以外では使用不可。
	@property
	const
	string text() { mixin(S_TRACE);
		if (!isRoot) throw new Exception("Node is not Root: " ~ name);
		return (cast(Document)_el).prolog ~ "\n" ~ std.string.join(_el.pretty(0), "\n");
	} unittest {
		debug mixin(UTPerf);
		auto xml = "<?xml version=\"1.0\"?>\n<xnode>\n<children attr0=\"???\">\n<child attr1=\"1\" attr2=\"attr\" />\n<child />\n</children>\n</xnode>";
		auto node = XNode.parse(xml);
		assert (node.valid);
		assert (xml == node.text, node.text);
	}
}
