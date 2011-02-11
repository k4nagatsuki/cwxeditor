
module cwx.editor.gui.dwt.xmlbytestransfer;

import std.compat;

import cwx.editor.gui.dwt.props;

import org.eclipse.swt.dnd.Clipboard;
import org.eclipse.swt.dnd.TextTransfer;
import org.eclipse.swt.dnd.ByteArrayTransfer;
import java.lang.all;

private static const string XML_HEADER_S = `<?xml `;
private static const byte[] XML_HEADER = cast(byte[]) XML_HEADER_S;

bool isXMLBytes(Object o) {
	if (!o) return false;
	auto awb = cast(ArrayWrapperByte) o;
	if (!awb) return false;
	return cwx.utils.startsWith(awb.array, XML_HEADER);
}

void XMLtoCB(Props prop, Clipboard cb, string xml) {
	if (prop.var.etc.xmlCopy) {
		cb.setContents([new ArrayWrapperString(xml)], [TextTransfer.getInstance]);
	} else {
		cb.setContents([bytesFromXML(xml)], [XMLBytesTransfer.getInstance]);
	}
}

string CBtoXML(Clipboard cb) {
	auto c = cb.getContents(XMLBytesTransfer.getInstance);
	if (c !is null && isXMLBytes(c)) {
		return bytesToXML(c);
	}
	c = cb.getContents(TextTransfer.getInstance);
	if (c !is null) {
		auto aws = cast(ArrayWrapperString) c;
		if (aws && cwx.utils.startsWith(aws.array, XML_HEADER_S)) {
			return aws.array;
		}
	}
	return null;
}

ArrayWrapperByte bytesFromXML(string xml) {
	return new ArrayWrapperByte(cast(byte[]) xml);
}

string bytesToXML(Object o) {
	assert (isXMLBytes(o));
	return cast(string) (cast(ArrayWrapperByte) o).array;
}

class XMLBytesTransfer : ByteArrayTransfer {
	private static const TYPE_NAME = "cwx.editor.XMLBytes";
	private static const int TYPE_ID;
	private static XMLBytesTransfer INSTANCE;
	static this () {
		TYPE_ID = registerType(TYPE_NAME);
		INSTANCE = new XMLBytesTransfer;
	}
	private this() {}
	static XMLBytesTransfer getInstance() {return INSTANCE;}

	int[] getTypeIds() {return [TYPE_ID];}
	string[] getTypeNames() {return [TYPE_NAME];}
}
