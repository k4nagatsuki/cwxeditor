
module cwx.editor.gui.dwt.xmlbytestransfer;

import cwx.editor.gui.dwt.dprops;

import org.eclipse.swt.all;

import java.lang.all;

import std.algorithm;
import std.string;
import std.array;
import std.ascii;
import std.exception;

class ClipData {
	this (Clipboard clipboard) {
		this.clipboard = clipboard;
	}
	Clipboard clipboard = null;
	alias clipboard this;
	private string memory = "";
	private bool _memoryMode = false;
	@property
	const
	bool memoryMode() {return _memoryMode;}
	@property
	void memoryMode(bool mode) {
		_memoryMode = mode;
		if (!mode) {
			memory = "";
		}
	}
}

private static const string XML_HEADER_S = `<?xml `;
private static const(byte)[] XML_HEADER = cast(byte[]) XML_HEADER_S;

string sysRet(string text) {
	static if ("\n" == newline) {
		return text;
	} else {
		return std.array.replace(text, "\n", newline);
	}
}

bool isXMLBytes(Object o) {
	if (!o) return false;
	auto awb = cast(ArrayWrapperByte) o;
	if (!awb) return false;
	return std.algorithm.startsWith(awb.array, XML_HEADER);
}

void XMLtoCB(Props prop, ClipData cb, string xml) {
	if (cb.memoryMode) {
		cb.memory = xml;
	} else if (prop.var.etc.xmlCopy) {
		cb.setContents([new ArrayWrapperString(sysRet(xml))], [TextTransfer.getInstance()]);
	} else {
		cb.setContents([bytesFromXML(xml)], [XMLBytesTransfer.getInstance()]);
	}
}

string CBtoXML(ClipData cb) {
	if (cb.memoryMode) {
		return cb.memory;
	}
	auto c = cb.getContents(XMLBytesTransfer.getInstance());
	if (c !is null && isXMLBytes(c)) {
		return bytesToXML(c);
	}
	c = cb.getContents(TextTransfer.getInstance());
	if (c !is null) {
		auto aws = cast(ArrayWrapperString) c;
		string head = XML_HEADER_S;
		if (aws && std.algorithm.startsWith(aws.array, head)) {
			auto r = aws.array;
			return assumeUnique(r);
		}
	}
	return null;
}
bool CBisXML(Clipboard cb) {
	if (CBisXMLOnly(cb)) {
		return true;
	}
	auto c = cb.getContents(TextTransfer.getInstance());
	if (c && std.algorithm.startsWith((cast(ArrayWrapperString) c).array, XML_HEADER)) {
		return true;
	}
	return false;
}
bool CBisXMLOnly(Clipboard cb) {
	auto c = cb.getContents(XMLBytesTransfer.getInstance());
	if (c && isXMLBytes(c)) {
		return true;
	}
	return false;
}

ArrayWrapperByte bytesFromXML(string xml) {
	return new ArrayWrapperByte(cast(byte[]) xml);
}

string bytesToXML(Object o) {
	assert (isXMLBytes(o));
	return sysRet(cast(string) (cast(ArrayWrapperByte) o).array);
}

class XMLBytesTransfer : ByteArrayTransfer {
	private static const TYPE_NAME = "cwx.editor.XMLBytes";
	private static int TYPE_ID;
	private static XMLBytesTransfer INSTANCE;
	private static bool static_this_completed = false;
	private static void static_this () {
		if (static_this_completed) return;
		static_this_completed = true;
		TYPE_ID = registerType(TYPE_NAME);
		INSTANCE = new XMLBytesTransfer;
	}
	private this() {}
	static XMLBytesTransfer getInstance() {
		static_this();
		return INSTANCE;
	}

	override
	int[] getTypeIds() {
		static_this();
		return [TYPE_ID];
	}
	override
	string[] getTypeNames() {
		static_this();
		return [TYPE_NAME];
	}
}
