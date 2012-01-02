/**
D2のstd.xmlをD1から使用できるように改造したモジュールである。
ライセンス等は以降にあるオリジナルの記述を参照の事。

-gオプションでOPTLINKがエラーを吐くため、xml.dを分割。
*/

// Written in the D programming language.

/**
Classes and functions for creating and parsing XML

The basic architecture of this module is that there are standalone functions,
classes for constructing an XML document from scratch (Tag, Element and
Document), and also classes for parsing a pre-existing XML file (ElementParser
and DocumentParser). The parsing classes <i>may</i> be used to build a
Document, but that is not their primary purpose. The handling capabilities of
DocumentParser and ElementParser are sufficiently customizable that you can
make them do pretty much whatever you want.

Example: This example creates a DOM (Document Object Model) tree
    from an XML file.
------------------------------------------------------------------------------
import std.xml;
import std.stdio;
import std.string;

// books.xml is used in various samples throughout the Microsoft XML Core
// Services (MSXML) SDK.
//
// See http://msdn2.microsoft.com/en-us/library/ms762271(VS.85).aspx

void main()
{
    string s = cast(string)std.file.read("books.xml");

    // Check for well-formedness
    check(s);

    // Make a DOM tree
    auto doc = new Document(s);

    // Plain-print it
    writefln(doc);
}
------------------------------------------------------------------------------

Example: This example does much the same thing, except that the file is
    deconstructed and reconstructed by hand. This is more work, but the
    techniques involved offer vastly more power.
------------------------------------------------------------------------------
import std.xml;
import std.stdio;
import std.string;

struct Book
{
    string id;
    string author;
    string title;
    string genre;
    string price;
    string pubDate;
    string description;
}

void main()
{
    string s = cast(string)std.file.read("books.xml");

    // Check for well-formedness
    check(s);

    // Take it apart
    Book[] books;

    auto xml = new DocumentParser(s);
    xml.onStartTag["book"] = (ElementParser xml)
    {
        Book book;
        book.id = xml.tag.attr["id"];

        xml.onEndTag["author"]       = (in Element e) { book.author      = e.text(); };
        xml.onEndTag["title"]        = (in Element e) { book.title       = e.text(); };
        xml.onEndTag["genre"]        = (in Element e) { book.genre       = e.text(); };
        xml.onEndTag["price"]        = (in Element e) { book.price       = e.text(); };
        xml.onEndTag["publish-date"] = (in Element e) { book.pubDate     = e.text(); };
        xml.onEndTag["description"]  = (in Element e) { book.description = e.text(); };

        xml.parse();

        books ~= book;
    };
    xml.parse();

    // Put it back together again;
    auto doc = new Document(new Tag("catalog"));
    foreach(book;books)
    {
        auto element = new Element("book");
        element.tag.attr["id"] = book.id;

        element ~= new Element("author",      book.author);
        element ~= new Element("title",       book.title);
        element ~= new Element("genre",       book.genre);
        element ~= new Element("price",       book.price);
        element ~= new Element("publish-date",book.pubDate);
        element ~= new Element("description", book.description);

        doc ~= element;
    }

    // Pretty-print it
    writefln(join(doc.pretty(3),"\n"));
}
-------------------------------------------------------------------------------
Macros:
    WIKI=Phobos/StdXml

Copyright: Copyright Janice Caron 2008 - 2009.
License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
Authors:   Janice Caron
Source:    $(PHOBOSSRC std/_xml.d)
*/
/*
         Copyright Janice Caron 2008 - 2009.
Distributed under the Boost Software License, Version 1.0.
   (See accompanying file LICENSE_1_0.txt or copy at
         http://www.boost.org/LICENSE_1_0.txt)
*/
module d2std.xml2;

import d2std.xml;

import std.array;
import std.ascii;
import std.string;
import std.encoding;

/**
 * Class representing an XML document.
 *
 * Standards: $(LINK2 http://www.w3.org/TR/1998/REC-xml-19980210, XML 1.0)
 *
 */
class Document : Element
{
    /**
     * Contains all text which occurs before the root element.
     * Defaults to &lt;?xml version="1.0"?&gt;
     */
    string prolog = "<?xml version=\"1.0\"?>";
    /**
     * Contains all text which occurs after the root element.
     * Defaults to the empty string
     */
    string epilog;

    /**
     * Constructs a Document by parsing XML text.
     *
     * This function creates a complete DOM (Document Object Model) tree.
     *
     * The input to this function MUST be valid XML.
     * This is enforced by DocumentParser's in contract.
     *
     * Params:
     *      s = the complete XML text.
     */
    this(string s)
    in
    {
        assert(s.length != 0);
    }
    body
    {
        auto xml = new DocumentParser(s);
        string tagString = xml.tag.tagString;

        this(xml.tag);
        prolog = s[0 .. tagString.ptr - s.ptr];
        parse(xml);
        epilog = *xml.s;
    }

    /**
     * Constructs a Document from a Tag.
     *
     * Params:
     *      tag = the start tag of the document.
     */
    this(const(Tag) tag)
    {
        super(tag);
    }

    const
    {
        /**
         * Compares two Documents for equality
         *
         * Examples:
         * --------------
         * Document d1,d2;
         * if (d1 == d2) { }
         * --------------
         */
        override bool opEquals(Object o)
        {
            const doc = toType!(const Document)(o);
            return
                (prolog != doc.prolog            ) ? false : (
                (super  != cast(const Element)doc) ? false : (
                (epilog != doc.epilog            ) ? false : (
            true )));
        }

        /**
         * Compares two Documents
         *
         * You should rarely need to call this function. It exists so that
         * Documents can be used as associative array keys.
         *
         * Examples:
         * --------------
         * Document d1,d2;
         * if (d1 < d2) { }
         * --------------
         */
        override int opCmp(Object o)
        {
            const doc = toType!(const Document)(o);
            return
                ((prolog != doc.prolog            )
                    ? ( prolog < doc.prolog             ? -1 : 1 ) :
                ((super  != cast(const Element)doc)
                    ? ( cast()super  < cast(const Element)doc ? -1 : 1 ) :
                ((epilog != doc.epilog            )
                    ? ( epilog < doc.epilog             ? -1 : 1 ) :
            0 )));
        }

        /**
         * Returns the hash of a Document
         *
         * You should rarely need to call this function. It exists so that
         * Documents can be used as associative array keys.
         */
        override hash_t toHash()
        {
            return hash(prolog, hash(epilog, (cast()super).toHash()));
        }

        /**
         * Returns the string representation of a Document. (That is, the
         * complete XML of a document).
         */
        override string toString()
        {
            return prolog ~ super.toString() ~ epilog;
        }
    }
}

/**
 * Class representing an XML element.
 *
 * Standards: $(LINK2 http://www.w3.org/TR/1998/REC-xml-19980210, XML 1.0)
 */
class Element : Item
{
    Tag tag; /// The start tag of the element
    Item[] items; /// The element's items
    Text[] texts; /// The element's text items
    CData[] cdatas; /// The element's CData items
    Comment[] comments; /// The element's comments
    ProcessingInstruction[] pis; /// The element's processing instructions
    Element[] elements; /// The element's child elements

    /**
     * Constructs an Element given a name and a string to be used as a Text
     * interior.
     *
     * Params:
     *      name = the name of the element.
     *      interior = (optional) the string interior.
     *
     * Examples:
     * -------------------------------------------------------
     * auto element = new Element("title","Serenity")
     *     // constructs the element <title>Serenity</title>
     * -------------------------------------------------------
     */
    this(string name, string interior=null)
    {
        this(new Tag(name));
        if (interior.length != 0) opCatAssign(new Text(interior));
    }

    /**
     * Constructs an Element from a Tag.
     *
     * Params:
     *      tag = the start or empty tag of the element.
     */
    this(const(Tag) tag_)
    {
        this.tag = new Tag(tag_.name);
        tag.type = TagType.EMPTY;
        foreach(k,v;tag_.attr) tag.attr[k] = v;
        tag.tagString = tag_.tagString;
    }

    /**
     * Append a text item to the interior of this element
     *
     * Params:
     *      item = the item you wish to append.
     *
     * Examples:
     * --------------
     * Element element;
     * element ~= new Text("hello");
     * --------------
     */
    void opCatAssign(Text item)
    {
        texts ~= item;
        appendItem(item);
    }

    /**
     * Append a CData item to the interior of this element
     *
     * Params:
     *      item = the item you wish to append.
     *
     * Examples:
     * --------------
     * Element element;
     * element ~= new CData("hello");
     * --------------
     */
    void opCatAssign(CData item)
    {
        cdatas ~= item;
        appendItem(item);
    }

    /**
     * Append a comment to the interior of this element
     *
     * Params:
     *      item = the item you wish to append.
     *
     * Examples:
     * --------------
     * Element element;
     * element ~= new Comment("hello");
     * --------------
     */
    void opCatAssign(Comment item)
    {
        comments ~= item;
        appendItem(item);
    }

    /**
     * Append a processing instruction to the interior of this element
     *
     * Params:
     *      item = the item you wish to append.
     *
     * Examples:
     * --------------
     * Element element;
     * element ~= new ProcessingInstruction("hello");
     * --------------
     */
    void opCatAssign(ProcessingInstruction item)
    {
        pis ~= item;
        appendItem(item);
    }

    /**
     * Append a complete element to the interior of this element
     *
     * Params:
     *      item = the item you wish to append.
     *
     * Examples:
     * --------------
     * Element element;
     * Element other = new Element("br");
     * element ~= other;
     *    // appends element representing <br />
     * --------------
     */
    void opCatAssign(Element item)
    {
        elements ~= item;
        appendItem(item);
    }

    private void appendItem(Item item)
    {
        items ~= item;
        if (tag.type == TagType.EMPTY && !item.isEmptyXML)
            tag.type = TagType.START;
    }

    private void parse(ElementParser xml)
    {
        xml.onText = (string s) { opCatAssign(new Text(s)); };
        xml.onCData = (string s) { opCatAssign(new CData(s)); };
        xml.onComment = (string s) { opCatAssign(new Comment(s)); };
        xml.onPI = (string s) { opCatAssign(new ProcessingInstruction(s)); };

        xml.onStartTag[null] = (ElementParser xml)
        {
            auto e = new Element(xml.tag);
            e.parse(xml);
            opCatAssign(e);
        };

        xml.parse();
    }

    /**
     * Compares two Elements for equality
     *
     * Examples:
     * --------------
     * Element e1,e2;
     * if (e1 == e2) { }
     * --------------
     */
    override bool opEquals(Object o)
    {
        const element = toType!(const Element)(o);
        auto len = items.length;
        if (len != element.items.length) return false;
        foreach (i; 0 .. len)
        {
            if (!items[i].opEquals(element.items[i])) return false;
        }
        return true;
    }

    /**
     * Compares two Elements
     *
     * You should rarely need to call this function. It exists so that Elements
     * can be used as associative array keys.
     *
     * Examples:
     * --------------
     * Element e1,e2;
     * if (e1 < e2) { }
     * --------------
     */
    override int opCmp(Object o)
    {
        const element = toType!(const Element)(o);
        for (uint i=0; ; ++i)
        {
            if (i == items.length && i == element.items.length) return 0;
            if (i == items.length) return -1;
            if (i == element.items.length) return 1;
            if (items[i] != element.items[i])
                return items[i].opCmp(element.items[i]);
        }
    }

    /**
     * Returns the hash of an Element
     *
     * You should rarely need to call this function. It exists so that Elements
     * can be used as associative array keys.
     */
    override hash_t toHash()
    {
        hash_t hash = tag.toHash();
        foreach(item;items) hash += item.toHash();
        return hash;
    }

    const
    {
        /**
         * Returns the decoded interior of an element.
         *
         * The element is assumed to containt text <i>only</i>. So, for
         * example, given XML such as "&lt;title&gt;Good &amp;amp;
         * Bad&lt;/title&gt;", will return "Good &amp; Bad".
         *
         * Params:
         *      mode = (optional) Mode to use for decoding. (Defaults to LOOSE).
         *
         * Throws: DecodeException if decode fails
         */
        string text(DecodeMode mode=DecodeMode.LOOSE)
        {
            string buffer;
            foreach(item;items)
            {
                Text t = cast(Text)item;
                if (t is null) throw new DecodeException(item.toString());
                buffer ~= decode(t.toString(),mode);
            }
            return buffer;
        }

        /**
         * Returns an indented string representation of this item
         *
         * Params:
         *      indent = (optional) number of spaces by which to indent this
         *          element. Defaults to 2.
         */
        override string[] pretty(uint indent=2)
        {

            if (isEmptyXML) return [ tag.toEmptyString() ];

            if (items.length == 1)
            {
                Text t = cast(Text)(items[0]);
                if (t !is null)
                {
                    return [tag.toStartString() ~ t.toString() ~ tag.toEndString()];
                }
            }

            string[] a = [ tag.toStartString() ];
            foreach(item;items)
            {
                string[] b = item.pretty(indent);
                foreach(s;b)
                {
                    a ~= rightJustify(s,s.length + indent);
                }
            }
            a ~= tag.toEndString();
            return a;
        }

        /**
         * Returns the string representation of an Element
         *
         * Examples:
         * --------------
         * auto element = new Element("br");
         * writefln(element.toString()); // writes "<br />"
         * --------------
         */
        override string toString()
        {
            if (isEmptyXML) return tag.toEmptyString();

            string buffer = tag.toStartString();
            foreach (item;items) { buffer ~= item.toString(); }
            buffer ~= tag.toEndString();
            return buffer;
        }

        override @property bool isEmptyXML() { return items.length == 0; }
    }
}

/**
 * Tag types.
 *
 * $(DDOC_ENUM_MEMBERS START) Used for start tags
 * $(DDOC_ENUM_MEMBERS END) Used for end tags
 * $(DDOC_ENUM_MEMBERS EMPTY) Used for empty tags
 *
 */
enum TagType { START, END, EMPTY };

/**
 * Class representing an XML tag.
 *
 * Standards: $(LINK2 http://www.w3.org/TR/1998/REC-xml-19980210, XML 1.0)
 *
 * The class invariant guarantees
 * <ul>
 * <li> that $(B type) is a valid enum TagType value</li>
 * <li> that $(B name) consists of valid characters</li>
 * <li> that each attribute name consists of valid characters</li>
 * </ul>
 */
class Tag
{
    TagType type = TagType.START;   /// Type of tag
    string name;                    /// Tag name
    string[string] attr;            /// Associative array of attributes
    package string tagString;

    invariant()
    {
        string s;
        string t;

        assert(type == TagType.START
            || type == TagType.END
            || type == TagType.EMPTY);

        s = name;
        try { checkName(s,t); }
        catch(Err e) { assert(false,"Invalid tag name:" ~ e.toString()); }

        foreach(k,v;attr)
        {
            s = k;
            try { checkName(s,t); }
            catch(Err e)
                { assert(false,"Invalid atrribute name:" ~ e.toString()); }
        }
    }

    /**
     * Constructs an instance of Tag with a specified name and type
     *
     * The constructor does not initialize the attributes. To initialize the
     * attributes, you access the $(B attr) member variable.
     *
     * Params:
     *      name = the Tag's name
     *      type = (optional) the Tag's type. If omitted, defaults to
     *          TagType.START.
     *
     * Examples:
     * --------------
     * auto tag = new Tag("img",Tag.EMPTY);
     * tag.attr["src"] = "http://example.com/example.jpg";
     * --------------
     */
    this(string name, TagType type=TagType.START)
    {
        this.name = name;
        this.type = type;
    }

    /* Private constructor (so don't ddoc this!)
     *
     * Constructs a Tag by parsing the string representation, e.g. "<html>".
     *
     * The string is passed by reference, and is advanced over all characters
     * consumed.
     *
     * The second parameter is a dummy parameter only, required solely to
     * distinguish this constructor from the public one.
     */
    package this(ref string s, bool dummy)
    {
        tagString = s;
        try
        {
            reqc(s,'<');
            if (optc(s,'/')) type = TagType.END;
            name = munch(s,"^/>"~whitespace);
            munch(s,whitespace);
            while(s.length > 0 && s[0] != '>' && s[0] != '/')
            {
                string key = munch(s,"^="~whitespace);
                munch(s,whitespace);
                reqc(s,'=');
                munch(s,whitespace);
                reqc(s,'"');
                string val = decode(munch(s,"^\""), DecodeMode.LOOSE);
                reqc(s,'"');
                munch(s,whitespace);
                attr[key] = val;
            }
            if (optc(s,'/'))
            {
                if (type == TagType.END) throw new TagException("");
                type = TagType.EMPTY;
            }
            reqc(s,'>');
            tagString.length = (s.ptr - tagString.ptr);
        }
        catch(XMLException e)
        {
            tagString.length = (s.ptr - tagString.ptr);
            throw new TagException(tagString);
        }
    }

    const
    {
        /**
         * Compares two Tags for equality
         *
         * You should rarely need to call this function. It exists so that Tags
         * can be used as associative array keys.
         *
         * Examples:
         * --------------
         * Tag tag1,tag2
         * if (tag1 == tag2) { }
         * --------------
         */
        override bool opEquals(Object o)
        {
            const tag = toType!(const Tag)(o);
            return
                (name != tag.name) ? false : (
                (attr != tag.attr) ? false : (
                (type != tag.type) ? false : (
            true )));
        }

        /**
         * Compares two Tags
         *
         * Examples:
         * --------------
         * Tag tag1,tag2
         * if (tag1 < tag2) { }
         * --------------
         */
        override int opCmp(Object o)
        {
            const tag = toType!(const Tag)(o);
            return
                ((name != tag.name) ? ( name < tag.name ? -1 : 1 ) :
                ((attr != tag.attr) ? ( attr < tag.attr ? -1 : 1 ) :
                ((type != tag.type) ? ( type < tag.type ? -1 : 1 ) :
            0 )));
        }

        /**
         * Returns the hash of a Tag
         *
         * You should rarely need to call this function. It exists so that Tags
         * can be used as associative array keys.
         */
        override hash_t toHash()
        {
            hash_t hash = 0;
            foreach(dchar c;name) hash = hash * 11 + c;
            return hash;
        }

        /**
         * Returns the string representation of a Tag
         *
         * Examples:
         * --------------
         * auto tag = new Tag("book",TagType.START);
         * writefln(tag.toString()); // writes "<book>"
         * --------------
         */
        override string toString()
        {
            if (isEmpty) return toEmptyString();
            return (isEnd) ? toEndString() : toStartString();
        }

        private
        {
            string toNonEndString()
            {
                string s = "<" ~ name;
                foreach(key,val;attr)
                    s ~= format(" %s=\"%s\"",key,encode(val));
                return s;
            }

            string toStartString() { return toNonEndString() ~ ">"; }

            string toEndString() { return "</" ~ name ~ ">"; }

            string toEmptyString() { return toNonEndString() ~ " />"; }
        }

        /**
         * Returns true if the Tag is a start tag
         *
         * Examples:
         * --------------
         * if (tag.isStart) { }
         * --------------
         */
        @property bool isStart() { return type == TagType.START; }

        /**
         * Returns true if the Tag is an end tag
         *
         * Examples:
         * --------------
         * if (tag.isEnd) { }
         * --------------
         */
        @property bool isEnd()   { return type == TagType.END;   }

        /**
         * Returns true if the Tag is an empty tag
         *
         * Examples:
         * --------------
         * if (tag.isEmpty) { }
         * --------------
         */
        @property bool isEmpty() { return type == TagType.EMPTY; }
    }
}

/**
 * Class representing a comment
 */
class Comment : Item
{
    private string content;

    /**
     * Construct a comment
     *
     * Params:
     *      content = the body of the comment
     *
     * Throws: CommentException if the comment body is illegal (contains "--"
     * or exactly equals "-")
     *
     * Examples:
     * --------------
     * auto item = new Comment("This is a comment");
     *    // constructs <!--This is a comment-->
     * --------------
     */
    this(string content)
    {
        if (content == "-" || content.indexOf("==") != -1)
            throw new CommentException(content);
        this.content = content;
    }

    /**
     * Compares two comments for equality
     *
     * Examples:
     * --------------
     * Comment item1,item2;
     * if (item1 == item2) { }
     * --------------
     */
    override bool opEquals(Object o)
    {
        const item = toType!(const Item)(o);
        const t = cast(Comment)item;
        return t !is null && content == t.content;
    }

    /**
     * Compares two comments
     *
     * You should rarely need to call this function. It exists so that Comments
     * can be used as associative array keys.
     *
     * Examples:
     * --------------
     * Comment item1,item2;
     * if (item1 < item2) { }
     * --------------
     */
    override int opCmp(Object o)
    {
        const item = toType!(const Item)(o);
        const t = cast(Comment)item;
        return t !is null && (content != t.content
            ? (content < t.content ? -1 : 1 ) : 0 );
    }

    /**
     * Returns the hash of a Comment
     *
     * You should rarely need to call this function. It exists so that Comments
     * can be used as associative array keys.
     */
    override hash_t toHash() { return hash(content); }

    /**
     * Returns a string representation of this comment
     */
    override const string toString() { return "<!--" ~ content ~ "-->"; }

    override @property const bool isEmptyXML() { return false; } /// Returns false always
}

/**
 * Class representing a Character Data section
 */
class CData : Item
{
    private string content;

    /**
     * Construct a chraracter data section
     *
     * Params:
     *      content = the body of the character data segment
     *
     * Throws: CDataException if the segment body is illegal (contains "]]>")
     *
     * Examples:
     * --------------
     * auto item = new CData("<b>hello</b>");
     *    // constructs <![CDATA[<b>hello</b>]]>
     * --------------
     */
    this(string content)
    {
        if (content.indexOf("]]>") != -1) throw new CDataException(content);
        this.content = content;
    }

    /**
     * Compares two CDatas for equality
     *
     * Examples:
     * --------------
     * CData item1,item2;
     * if (item1 == item2) { }
     * --------------
     */
    override bool opEquals(Object o)
    {
        const item = toType!(const Item)(o);
        const t = cast(CData)item;
        return t !is null && content == t.content;
    }

    /**
     * Compares two CDatas
     *
     * You should rarely need to call this function. It exists so that CDatas
     * can be used as associative array keys.
     *
     * Examples:
     * --------------
     * CData item1,item2;
     * if (item1 < item2) { }
     * --------------
     */
    override int opCmp(Object o)
    {
        const item = toType!(const Item)(o);
        const t = cast(CData)item;
        return t !is null && (content != t.content
            ? (content < t.content ? -1 : 1 ) : 0 );
    }

    /**
     * Returns the hash of a CData
     *
     * You should rarely need to call this function. It exists so that CDatas
     * can be used as associative array keys.
     */
    override hash_t toHash() { return hash(content); }

    /**
     * Returns a string representation of this CData section
     */
    override const string toString() { return cdata ~ content ~ "]]>"; }

    override @property const bool isEmptyXML() { return false; } /// Returns false always
}

/**
 * Class representing a text (aka Parsed Character Data) section
 */
class Text : Item
{
    private string content;

    /**
     * Construct a text (aka PCData) section
     *
     * Params:
     *      content = the text. This function encodes the text before
     *      insertion, so it is safe to insert any text
     *
     * Examples:
     * --------------
     * auto Text = new CData("a < b");
     *    // constructs a &lt; b
     * --------------
     */
    this(string content)
    {
        this.content = encode(content);
    }

    /**
     * Compares two text sections for equality
     *
     * Examples:
     * --------------
     * Text item1,item2;
     * if (item1 == item2) { }
     * --------------
     */
    override bool opEquals(Object o)
    {
        const item = toType!(const Item)(o);
        const t = cast(Text)item;
        return t !is null && content == t.content;
    }

    /**
     * Compares two text sections
     *
     * You should rarely need to call this function. It exists so that Texts
     * can be used as associative array keys.
     *
     * Examples:
     * --------------
     * Text item1,item2;
     * if (item1 < item2) { }
     * --------------
     */
    override int opCmp(Object o)
    {
        const item = toType!(const Item)(o);
        const t = cast(Text)item;
        return t !is null
            && (content != t.content ? (content < t.content ? -1 : 1 ) : 0 );
    }

    /**
     * Returns the hash of a text section
     *
     * You should rarely need to call this function. It exists so that Texts
     * can be used as associative array keys.
     */
    override hash_t toHash() { return hash(content); }

    /**
     * Returns a string representation of this Text section
     */
    override const string toString() { return content; }

    /**
     * Returns true if the content is the empty string
     */
    override @property const bool isEmptyXML() { return content.length == 0; }
}

/**
 * Class representing an XML Instruction section
 */
class XMLInstruction : Item
{
    private string content;

    /**
     * Construct an XML Instruction section
     *
     * Params:
     *      content = the body of the instruction segment
     *
     * Throws: XIException if the segment body is illegal (contains ">")
     *
     * Examples:
     * --------------
     * auto item = new XMLInstruction("ATTLIST");
     *    // constructs <!ATTLIST>
     * --------------
     */
    this(string content)
    {
        if (content.indexOf(">") != -1) throw new XIException(content);
        this.content = content;
    }

    /**
     * Compares two XML instructions for equality
     *
     * Examples:
     * --------------
     * XMLInstruction item1,item2;
     * if (item1 == item2) { }
     * --------------
     */
    override bool opEquals(Object o)
    {
        const item = toType!(const Item)(o);
        const t = cast(XMLInstruction)item;
        return t !is null && content == t.content;
    }

    /**
     * Compares two XML instructions
     *
     * You should rarely need to call this function. It exists so that
     * XmlInstructions can be used as associative array keys.
     *
     * Examples:
     * --------------
     * XMLInstruction item1,item2;
     * if (item1 < item2) { }
     * --------------
     */
    override int opCmp(Object o)
    {
        const item = toType!(const Item)(o);
        const t = cast(XMLInstruction)item;
        return t !is null
            && (content != t.content ? (content < t.content ? -1 : 1 ) : 0 );
    }

    /**
     * Returns the hash of an XMLInstruction
     *
     * You should rarely need to call this function. It exists so that
     * XmlInstructions can be used as associative array keys.
     */
    override hash_t toHash() { return hash(content); }

    /**
     * Returns a string representation of this XmlInstruction
     */
    override const string toString() { return "<!" ~ content ~ ">"; }

    override @property const bool isEmptyXML() { return false; } /// Returns false always
}

/**
 * Class representing a Processing Instruction section
 */
class ProcessingInstruction : Item
{
    private string content;

    /**
     * Construct a Processing Instruction section
     *
     * Params:
     *      content = the body of the instruction segment
     *
     * Throws: PIException if the segment body is illegal (contains "?>")
     *
     * Examples:
     * --------------
     * auto item = new ProcessingInstruction("php");
     *    // constructs <?php?>
     * --------------
     */
    this(string content)
    {
        if (content.indexOf("?>") != -1) throw new PIException(content);
        this.content = content;
    }

    /**
     * Compares two processing instructions for equality
     *
     * Examples:
     * --------------
     * ProcessingInstruction item1,item2;
     * if (item1 == item2) { }
     * --------------
     */
    override bool opEquals(Object o)
    {
        const item = toType!(const Item)(o);
        const t = cast(ProcessingInstruction)item;
        return t !is null && content == t.content;
    }

    /**
     * Compares two processing instructions
     *
     * You should rarely need to call this function. It exists so that
     * ProcessingInstructions can be used as associative array keys.
     *
     * Examples:
     * --------------
     * ProcessingInstruction item1,item2;
     * if (item1 < item2) { }
     * --------------
     */
    override int opCmp(Object o)
    {
        const item = toType!(const Item)(o);
        const t = cast(ProcessingInstruction)item;
        return t !is null
            && (content != t.content ? (content < t.content ? -1 : 1 ) : 0 );
    }

    /**
     * Returns the hash of a ProcessingInstruction
     *
     * You should rarely need to call this function. It exists so that
     * ProcessingInstructions can be used as associative array keys.
     */
    override hash_t toHash() { return hash(content); }

    /**
     * Returns a string representation of this ProcessingInstruction
     */
    override const string toString() { return "<?" ~ content ~ "?>"; }

    override @property const bool isEmptyXML() { return false; } /// Returns false always
}

/**
 * Abstract base class for XML items
 */
abstract class Item
{
    /// Compares with another Item of same type for equality
    abstract override bool opEquals(Object o);

    /// Compares with another Item of same type
    abstract override int opCmp(Object o);

    /// Returns the hash of this item
    abstract override hash_t toHash();

    /// Returns a string representation of this item
    abstract override const string toString();

    /**
     * Returns an indented string representation of this item
     *
     * Params:
     *      indent = number of spaces by which to indent child elements
     */
    const string[] pretty(uint indent)
    {
        string s = strip(toString());
        return s.length == 0 ? [] : [ s ];
    }

    /// Returns true if the item represents empty XML text
    abstract @property const bool isEmptyXML();
}
