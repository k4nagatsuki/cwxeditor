
module cwx.xml;

import cwx.perf;
import cwx.utils : debugln;

import std.array;
import std.conv;
import std.string;
import std.typecons;

import dxml.parser;
import dxml.util;
import dxml.writer;

/// XML文書処理用の構造体。
struct XNode {
	private static class Node {
		alias Tuple!(string, "name", string, "value") Attr;

		EntityType type;
		string name;
		string value;
		string[string] hasAttr;
		Attr[] attrs;
		Node[] children;

		this (EntityType type, string name, string value = "") { mixin(S_TRACE);
			this.type = type;
			this.name = name;
			this.value = value;
		}
		void newAttr(string name, string value) { mixin(S_TRACE);
			if (name in hasAttr) throw new Exception(name ~ " is duplicated.");
			attrs ~= Attr(name, value);
			hasAttr[name] = value;
		}
	}

	private Node _node = null;
	private bool _isRoot = false;

	private static Node parseElement(Parser, Attrs)(ref Parser parser, string name, Attrs attrs) { mixin(S_TRACE);
		auto node = new Node(EntityType.elementStart, name, "");
		foreach (ref attr; attrs) node.newAttr(attr.name, attr.value.decodeXML());
		while (!parser.empty) { mixin(S_TRACE);
			auto e = parser.front;
			parser.popFront();
			final switch (e.type) {
			case EntityType.cdata:
			case EntityType.comment:
			case EntityType.pi:
				node.children ~= new Node(e.type, e.name, e.text);
				break;
			case EntityType.text:
				node.value ~= e.text.decodeXML();
				break;
			case EntityType.elementEmpty:
				node.children ~= new Node(EntityType.elementStart, e.name, "");
				foreach (ref attr; e.attributes) node.children[$ - 1].newAttr(attr.name, attr.value.decodeXML());
				break;
			case EntityType.elementStart:
				node.children ~= parseElement(parser, e.name, e.attributes);
				break;
			case EntityType.elementEnd:
				return node;
			}
		}
		throw new Exception("End tag not found: <" ~ name ~ ">");
	}
	/// xmlの処理を開始する。
	static XNode parse(string xml) { mixin(S_TRACE);
		xml = xml.stripLeft();
		if (!xml.startsWith("<")) throw new Exception("Invalid XML: " ~ xml);
		XNode node;
		if (xml[1..$].indexOf("<") == -1) throw new Exception("Invalid XML: " ~ xml);
		auto parser = .parseXML(xml);
		while (!parser.empty && parser.front.type !is EntityType.elementStart) { mixin(S_TRACE);
			parser.popFront();
		}
		if (parser.empty) return node;

		auto e = parser.front;
		parser.popFront();
		node._node = parseElement(parser, e.name, e.attributes);
		node._isRoot = true;
		return node;
	}
	/// 新規にDOMを生成する。
	static XNode create(string rootName, string value = "") { mixin(S_TRACE);
		XNode node;
		node._node = new Node(EntityType.elementStart, rootName, value);
		node._isRoot = true;
		return node;
	}

	/// 現在処理中の要素の名前。
	@property
	const
	string name() { return _node.name; }

	/// 現在処理中の要素のテキスト。
	@property
	const
	string value() { mixin(S_TRACE);
		return _node.value == "\n" ? "" : _node.value;
	}
	/// ditto
	@property
	void value(string text) { mixin(S_TRACE);
		_node.value = text;
	}
	/// ditto
	@property
	const
	T valueTo(T)() { return .to!T(value); }

	/// 子要素を生成する。
	XNode newElement(T = string)(string name, T value = T.init) { mixin(S_TRACE);
		_node.children ~= new Node(EntityType.elementStart, name, .to!string(value));
		return XNode(_node.children[$ - 1]);
	}

	/// 属性を生成する。
	void newAttr(T)(string name, T value) { mixin(S_TRACE);
		_node.newAttr(name, .to!string(value));
	}
	/// 属性nameの値を返す。
	/// nothingIsErrorにtrueを指定すると、nameが存在しなかった際に例外を投げる。
	const
	T attr(T = string)(string name, bool nothingIsError, lazy T defaultValue = T.init) { mixin(S_TRACE);
		auto p = name in _node.hasAttr;
		if (nothingIsError && !p) throw new Exception(name ~ " is not found");
		if (!p) return defaultValue;
		return .to!T(*p);
	}
	/// 属性nameが存在すればtrueを返す。
	const
	bool hasAttr(string name) { return (name in _node.hasAttr) !is null; }

	unittest {
		debug mixin(UTPerf);
		auto node0 = XNode.create("xnode");
		node0.newAttr("xnode_attr1", "attr&1");
		node0.newAttr("xnode_attr2", 2);
		auto ce = node0.newElement("children");
		ce.newAttr("children_attr", true);
		auto cce1 = ce.newElement("child", true);
		cce1.newAttr("child_attr", 12.25);
		auto cce2 = ce.newElement("child", "1&2");
		cce2.newAttr("child_attr", "attr\"5");
		auto xml = node0.text;

		assert (xml == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<xnode xnode_attr1=\"attr&amp;1\" xnode_attr2=\"2\">\n<children children_attr=\"true\">\n<child child_attr=\"12.25\">true</child>\n<child child_attr=\"attr&quot;5\">1&amp;2</child>\n</children>\n</xnode>");

		auto node = XNode.parse(xml);
		assert (node.valid);
		assert (node.name == "xnode");
		assert (!node.hasAttr("xnode_attr0"));
		assert (node.hasAttr("xnode_attr1"));
		assert (node.attr("xnode_attr1", true) == "attr&1");
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
				assert (node.value == "1&2");
				assert (!node.hasAttr("xnode_attr1"));
				assert (node.attr("xnode_attr1", false, "def") == "def");
				try {
					node.attr("xnode_attr1", true);
					assert (0);
				} catch (Exception e) { }
				assert (node.hasAttr("child_attr"));
				assert (node.attr("child_attr", true) == "attr\"5");
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
		foreach (ref c; _node.children) { mixin(S_TRACE);
			if (c.name == name) { mixin(S_TRACE);
				return XNode(c);
			}
		}
		if (nothingIsError) throw new Exception(name ~ " is not found");
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
	bool valid() { return _node !is null; }

	/// 要素名と、その要素を発見した際に処理を行うハンドラを登録する。
	/// 要素名にnullを指定する事により、特に指定された要素以外を
	/// 処理するハンドラを登録できる。
	void delegate(ref XNode)[string] onTag;

	/// 子要素を探し、結果をハンドラに渡す。
	void parse() { mixin(S_TRACE);
		if (onTag.length == 0) return;
		foreach (ref c; _node.children) { mixin(S_TRACE);
			auto p = c.name in onTag;
			if (!p) p = null in onTag;
			XNode node;
			node._node = c;
			if (p) (*p)(node);
		}
		onTag = null;
	} unittest {
		debug mixin(UTPerf);
		auto xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<xnode>\n<children attr0=\"&amp;&amp;&amp;\">\n<child attr1=\"1\" attr2=\"attr\"/>\n<child>1&amp;2</child>\n</children>\n</xnode>";
		auto node = XNode.parse(xml);
		assert (node.valid);
		auto count0 = 0;
		node.onTag["children"] = (ref node) { mixin(S_TRACE);
			assert (node.valid);
			assert (!node.isRoot);
			assert (node.hasAttr("attr0"));
			assert (node.attr("attr0", true) == "&&&");
			auto count1 = 0;
			node.onTag["child"] = (ref node) { mixin(S_TRACE);
				assert (!node.isRoot);
				if (count1 == 0) { mixin(S_TRACE);
					assert (node.hasAttr("attr1"));
					assert (node.hasAttr("attr2"));
					assert (node.attr("attr1", true) == "1");
					assert (node.attr("attr2", true) == "attr");
					assert (node.value == "");
				} else if (count1 == 1) { mixin(S_TRACE);
					assert (!node.hasAttr("attr1"));
					assert (!node.hasAttr("attr2"));
					assert (node.value == "1&2");
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
		return _isRoot;
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
		auto a = .appender!string();
		a.writeXMLDecl!string();
		auto writer = .xmlWriter(a, "");
		void writeElement(ref const Node node) { mixin(S_TRACE);
			assert (node.type is EntityType.elementStart);
			writer.openStartTag(node.name, Newline.yes);
			foreach (attr; node.attrs) { mixin(S_TRACE);
				writer.writeAttr(attr.name, attr.value.encodeAttr());
			}
			if (node.children.length == 0 && node.value == "") { mixin(S_TRACE);
				writer.closeStartTag(EmptyTag.yes);
				return;
			}
			writer.closeStartTag();
			if (node.value != "") writer.writeText(node.value.encodeText(), Newline.no);

			foreach (ref c; node.children) { mixin(S_TRACE);
				final switch (c.type) {
				case EntityType.cdata:
					writer.writeCDATA(c.value);
					break;
				case EntityType.comment:
					writer.writeComment(c.value);
					break;
				case EntityType.pi:
					writer.writePI(c.value);
					break;
				case EntityType.elementStart:
					writeElement(c);
					break;
				case EntityType.elementEmpty:
					assert (0);
				case EntityType.text:
					assert (0);
				case EntityType.elementEnd:
					assert (0);
				}
			}
			writer.writeEndTag(node.name, node.children.length ? Newline.yes : Newline.no);
		}
		writeElement(_node);
		return writer.output.data;
	} unittest {
		debug mixin(UTPerf);
		auto xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<xnode>\n<children attr0=\"&amp;&amp;&amp;\">\n<child attr1=\"1\" attr2=\"attr\"/>\n<child>1&amp;2</child>\n</children>\n</xnode>";
		auto node = XNode.parse(xml);
		assert (node.valid);
		assert (xml == node.text, node.text);
	}
}
