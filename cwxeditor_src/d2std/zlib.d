/**
D2のstd.zipをD1から使用できるように改造したモジュールである。
ライセンス等は以降にあるオリジナルの記述を参照の事。
*/

// Written in the D programming language.

/**
 * Compress/decompress data using the $(WEB www.zlib.net, zlib library).
 *
 * References:
 *  $(WEB en.wikipedia.org/wiki/Zlib, Wikipedia)
 *
 * Macros:
 *  WIKI = Phobos/StdZlib
 *
 * Copyright: Copyright Digital Mars 2000 - 2011.
 * License:   $(WEB www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   $(WEB digitalmars.com, Walter Bright)
 * Source:    $(PHOBOSSRC std/_zlib.d)
 */
/*          Copyright Digital Mars 2000 - 2011.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */
module d2std.zlib;

//debug=zlib;       // uncomment to turn on debugging printf's

import etc.c.zlib;

// Values for 'mode'

enum
{
    Z_NO_FLUSH      = 0,
    Z_SYNC_FLUSH    = 2,
    Z_FULL_FLUSH    = 3,
    Z_FINISH        = 4,
}

/*************************************
 * Errors throw a ZlibException.
 */

class ZlibException : Exception
{
    this(int errnum)
    {   string msg;

        switch (errnum)
        {
            case Z_STREAM_END:      msg = "stream end"; break;
            case Z_NEED_DICT:       msg = "need dict"; break;
            case Z_ERRNO:           msg = "errno"; break;
            case Z_STREAM_ERROR:    msg = "stream error"; break;
            case Z_DATA_ERROR:      msg = "data error"; break;
            case Z_MEM_ERROR:       msg = "mem error"; break;
            case Z_BUF_ERROR:       msg = "buf error"; break;
            case Z_VERSION_ERROR:   msg = "version error"; break;
            default:                msg = "unknown error";  break;
        }
        super(msg);
    }
}

/**************************************************
 * Compute the Adler32 checksum of the data in buf[]. adler is the starting
 * value when computing a cumulative checksum.
 */

uint adler32(uint adler, NGCArray!ubyte buf)
{
    import std.range : chunks;
    foreach(chunk; buf[].chunks(0xFFFF0000))
    {
        adler = etc.c.zlib.adler32(adler, chunk.ptr, cast(uint)chunk.length);
    }
    return adler;
}

unittest
{
    debug(zlib) writeln("d2std.zip.unittest: ", __LINE__);

    scope(exit) assert (d2std.zlib.allocCount == 0);

    auto data = NGCArray!ubyte([1,2,3,4,5,6,7,8,9,10]);
    scope(exit) data.free();

    uint adler;

    debug(zlib) printf("D.zlib.adler32.unittest\n");
    adler = adler32(0u, data);
    debug(zlib) printf("adler = %x\n", adler);
    assert(adler == 0xdc0037);
}

/*********************************
 * Compute the CRC32 checksum of the data in buf[]. crc is the starting value
 * when computing a cumulative checksum.
 */

uint crc32(uint crc, NGCArray!ubyte buf)
{
    import std.range : chunks;
    foreach(chunk; buf[].chunks(0xFFFF0000))
    {
        crc = etc.c.zlib.crc32(crc, chunk.ptr, cast(uint)chunk.length);
    }
    return crc;
}

unittest
{
    debug(zlib) writeln("d2std.zip.unittest: ", __LINE__);

    scope(exit) assert (d2std.zlib.allocCount == 0);

    auto data = NGCArray!ubyte([1,2,3,4,5,6,7,8,9,10]);
    scope(exit)data.free();

    uint crc;

    debug(zlib) printf("D.zlib.crc32.unittest\n");
    crc = crc32(0u, data);
    debug(zlib) printf("crc = %x\n", crc);
    assert(crc == 0x2520577b);
}

/*********************************************
 * Compresses the data in srcbuf[] using compression _level level.
 * The default value
 * for level is 6, legal values are 1..9, with 1 being the least compression
 * and 9 being the most.
 * Returns the compressed data.
 */

NGCArray!ubyte compress(in NGCArray!ubyte srcbuf, int level)
in
{
    assert(-1 <= level && level <= 9);
}
body
{
    auto destlen = srcbuf.length + ((srcbuf.length + 1023) / 1024) + 12;
    auto destbuf = NGCArray!ubyte(destlen);
    auto err = etc.c.zlib.compress2(destbuf.ptr, &destlen, cast(ubyte *)srcbuf.ptr, srcbuf.length, level);
    if (err)
    {   destbuf.free();
        throw new ZlibException(err);
    }

    destbuf.length = destlen;
    return destbuf;
}

/*********************************************
 * ditto
 */

NGCArray!ubyte compress(in NGCArray!ubyte buf)
{
    return compress(buf, Z_DEFAULT_COMPRESSION);
}

/*********************************************
 * Decompresses the data in srcbuf[].
 * Params:
 *  srcbuf  = buffer containing the compressed data.
 *  destlen = size of the uncompressed data.
 *            It need not be accurate, but the decompression will be faster
 *            if the exact size is supplied.
 *  winbits = the base two logarithm of the maximum window size.
 * Returns: the decompressed data.
 */

NGCArray!ubyte uncompress(NGCArray!ubyte srcbuf, size_t destlen = 0u, int winbits = 15)
{
    import std.conv : to;
    int err;
    NGCArray!ubyte destbuf;

    if (!destlen)
        destlen = srcbuf.length * 2 + 1;

    etc.c.zlib.z_stream zs;
    zs.next_in = srcbuf.ptr;
    zs.avail_in = to!uint(srcbuf.length);
    err = etc.c.zlib.inflateInit2(&zs, winbits);
    if (err)
    {
        throw new ZlibException(err);
    }

    size_t olddestlen = 0u;

    loop:
    while (true)
    {
        destbuf.length = destlen;
        zs.next_out = &destbuf.ptr[olddestlen];
        zs.avail_out = to!uint(destlen - olddestlen);
        olddestlen = destlen;

        err = etc.c.zlib.inflate(&zs, Z_NO_FLUSH);
        switch (err)
        {
            case Z_OK:
                destlen = destbuf.length * 2;
                continue loop;

            case Z_STREAM_END:
                destbuf.length = zs.total_out;
                err = etc.c.zlib.inflateEnd(&zs);
                if (err != Z_OK)
                    throw new ZlibException(err);
                return destbuf;

            default:
                etc.c.zlib.inflateEnd(&zs);
                throw new ZlibException(err);
        }
    }
    assert(0);
}

unittest
{
    debug(zlib) writeln("d2std.zip.unittest: ", __LINE__);

    scope(exit) assert (d2std.zlib.allocCount == 0);

    NGCArray!ubyte src = NGCArray!ubyte(cast(ubyte[])
"the quick brown fox jumps over the lazy dog\r
the quick brown fox jumps over the lazy dog\r
");
    scope(exit) src.free();
    NGCArray!ubyte dst;
    scope(exit) dst.free();
    NGCArray!ubyte result;
    scope(exit) result.free();

    //arrayPrint(src);
    dst = compress(src);
    //arrayPrint(dst);
    result = uncompress(dst);
    //arrayPrint(result);
    assert(result[] == src[]);
}

unittest
{
    debug(zlib) writeln("d2std.zip.unittest: ", __LINE__);

    scope(exit) assert (d2std.zlib.allocCount == 0);

    NGCArray!ubyte src = NGCArray!ubyte(1000000);
    scope(exit) src.free();
    NGCArray!ubyte dst;
    scope(exit) dst.free();
    NGCArray!ubyte result;
    scope(exit) result.free();

    src.ptr[0 .. src.length] = 0x80;
    dst = compress(src);
    assert(dst.length*2 + 1 < src.length);
    result = uncompress(dst);
    assert(result[] == src[]);
}

/+
void arrayPrint(ubyte[] array)
{
    //printf("array %p,%d\n", cast(void*)array, array.length);
    for (size_t i = 0; i < array.length; i++)
    {
        printf("%02x ", array[i]);
        if (((i + 1) & 15) == 0)
            printf("\n");
    }
    printf("\n\n");
}
+/

/// the header format the compressed stream is wrapped in
enum HeaderFormat {
    deflate, /// a standard zlib header
    gzip, /// a gzip file format header
    determineFromData /// used when decompressing. Try to automatically detect the stream format by looking at the data
}

/*********************************************
 * Used when the data to be compressed is not all in one buffer.
 */

class Compress
{
    import std.conv: to;

  private:
    z_stream zs;
    int level = Z_DEFAULT_COMPRESSION;
    int inited;
    immutable bool gzip;

    void error(int err)
    {
        if (inited)
        {   deflateEnd(&zs);
            inited = 0;
        }
        throw new ZlibException(err);
    }

  public:

    /**
     * Construct. level is the same as for D.zlib.compress(). header can be used to make a gzip compatible stream.
     */
    this(int level, HeaderFormat header = HeaderFormat.deflate)
    in
    {
        assert(1 <= level && level <= 9);
    }
    body
    {
        this.level = level;
        this.gzip = header == HeaderFormat.gzip;
    }

    /// ditto
    this(HeaderFormat header = HeaderFormat.deflate)
    {
        this.gzip = header == HeaderFormat.gzip;
    }

    ~this()
    {   int err;

        if (inited)
        {
            inited = 0;
            deflateEnd(&zs);
        }
    }

    /**
     * Compress the data in buf and return the compressed data.
     * The buffers
     * returned from successive calls to this should be concatenated together.
     */
    const(NGCArray!ubyte) compress(in NGCArray!ubyte buf)
    {   int err;
        NGCArray!ubyte destbuf;

        if (buf.length == 0)
            return NGCArray!ubyte(0);

        if (!inited)
        {
            err = deflateInit2(&zs, level, Z_DEFLATED, 15 + (gzip ? 16 : 0), 8, Z_DEFAULT_STRATEGY);
            if (err)
                error(err);
            inited = 1;
        }

        destbuf = NGCArray!ubyte(zs.avail_in + buf.length);
        zs.next_out = destbuf.ptr;
        zs.avail_out = to!uint(destbuf.length);

        NGCArray!ubyte buf2;
        if (zs.avail_in) {
            buf2 = NGCArray!ubyte(zs.avail_in + buf.length);
            buf2.ptr[0 .. zs.avail_in] = zs.next_in[0 .. zs.avail_in];
            buf2.ptr[zs.avail_in .. buf2.length] = buf.ptr[0 .. buf.length];
        } else {
            buf2.putSlice(cast()buf);
        }
        scope(exit) buf2.free();

        zs.next_in = cast(typeof(zs.next_in)) buf2.ptr;
        zs.avail_in = to!uint(buf2.length);

        err = deflate(&zs, Z_NO_FLUSH);
        if (err != Z_STREAM_END && err != Z_OK)
        {   destbuf.free();
            error(err);
        }
        destbuf.length = destbuf.length - zs.avail_out;
        return destbuf;
    }
}

/******
 * Used when the data to be decompressed is not all in one buffer.
 */

class UnCompress
{
    import std.conv: to;

  private:
    z_stream zs;
    int inited;
    int done;
    size_t destbufsize;

    HeaderFormat format;

    void error(int err)
    {
        if (inited)
        {   inflateEnd(&zs);
            inited = 0;
        }
        throw new ZlibException(err);
    }

  public:

    /**
     * Construct. destbufsize is the same as for D.zlib.uncompress().
     */
    this(uint destbufsize)
    {
        this.destbufsize = destbufsize;
    }

    /** ditto */
    this(HeaderFormat format = HeaderFormat.determineFromData)
    {
        this.format = format;
    }

    ~this()
    {   int err;

        if (inited)
        {
            inited = 0;
            inflateEnd(&zs);
        }
        done = 1;
    }

    /**
     * Decompress the data in buf and return the decompressed data.
     * The buffers returned from successive calls to this should be concatenated
     * together.
     */
    NGCArray!ubyte uncompress(NGCArray!ubyte buf)
    in
    {
        assert(!done);
    }
    body
    {   int err;
        NGCArray!ubyte destbuf;

        if (buf.length == 0)
            return NGCArray!ubyte();

        if (!inited)
        {
        int windowBits = 15;
        if(format == HeaderFormat.gzip)
            windowBits += 16;
            else if(format == HeaderFormat.determineFromData)
            windowBits += 32;

            err = inflateInit2(&zs, windowBits);
            if (err)
                error(err);
            inited = 1;
        }

        if (!destbufsize)
            destbufsize = to!uint(buf.length) * 2;
        destbuf = NGCArray!ubyte(zs.avail_in * 2 + destbufsize);
        zs.next_out = destbuf.ptr;
        zs.avail_out = to!uint(destbuf.length);

        NGCArray!ubyte buf2;
        if (zs.avail_in) {
            buf2 = NGCArray!ubyte(zs.avail_in + buf.length);
            buf2.ptr[0 .. zs.avail_in] = zs.next_in[0 .. zs.avail_in];
            buf2.ptr[zs.avail_in .. buf2.length] = buf.ptr[0 .. buf.length];
        } else {
            buf2.putSlice(buf);
        }
        scope(exit) buf2.free();

        zs.next_in = buf2.ptr;
        zs.avail_in = to!uint(buf2.length);

        err = inflate(&zs, Z_NO_FLUSH);
        if (err != Z_STREAM_END && err != Z_OK)
        {   destbuf.free();
            error(err);
        }
        destbuf.length = destbuf.length - zs.avail_out;
        return destbuf;
    }
}

/* ========================== unittest ========================= */

private import std.stdio;
private import std.random;

unittest // by Dave
{
    debug(zlib) writeln("d2std.zip.unittest: ", __LINE__);

    scope(exit) assert (d2std.zlib.allocCount == 0);

    bool CompressThenUncompress (NGCArray!ubyte src)
    {
        NGCArray!ubyte dst = d2std.zlib.compress(src);
        scope(exit) dst.free();
        double ratio = (dst.length / cast(double)src.length);
        debug(zlib) writef("src.length: %1$d, dst: %2$d, Ratio = %3$f", src.length, dst.length, ratio);
        NGCArray!ubyte uncompressedBuf;
        scope(exit) uncompressedBuf.free();
        uncompressedBuf = d2std.zlib.uncompress(dst);
        assert(src.length == uncompressedBuf.length);
        assert(src[] == uncompressedBuf[]);

        return true;
    }


    // smallish buffers
    for(int idx = 0; idx < 25; idx++) {
        NGCArray!ubyte buf = NGCArray!ubyte(uniform(0, 100));
        scope(exit) buf.free();

        // Alternate between more & less compressible
        foreach(ref ubyte c; buf)
            c = cast(ubyte) (' ' + (uniform(0, idx % 2 ? 91 : 2)));

        if(CompressThenUncompress(buf)) {
            debug(zlib) writeln("; Success.");
        } else {
            return;
        }
    }

    // larger buffers
    for(int idx = 0; idx < 25; idx++) {
        NGCArray!ubyte buf = NGCArray!ubyte(uniform(0, 1000/*0000*/));
        scope(exit) buf.free();

        // Alternate between more & less compressible
        foreach(ref ubyte c; buf)
            c = cast(ubyte) (' ' + (uniform(0, idx % 2 ? 91 : 10)));

        if(CompressThenUncompress(buf)) {
            debug(zlib) writefln("; Success.");
        } else {
            return;
        }
    }

    debug(zlib) writefln("PASSED d2std.zlib.unittest");
}

static size_t allocCount = 0;

struct NGCArray(T) {
    private import core.stdc.stdlib;
    private import core.stdc.string;
    private import std.exception: enforce;

    private T* _basePtr = null;
    T* ptr = null;
    size_t _length = 0;

    this (size_t length) {
        this.length = length;
    }

    this (T[] array) {
        this (array.length);
        ptr[0 .. length] = array[];
    }

    const
    @property size_t length() { return _length; }
    @property void length(size_t length) {
        if (!ptr) {
            std.exception.enforce(!_basePtr);
            _basePtr = cast(T*)core.stdc.stdlib.malloc(length * T.sizeof);
            allocCount++;
            core.stdc.string.memset(cast(void*)_basePtr, 0, length * T.sizeof);
        } else {
            std.exception.enforce(_basePtr);
            std.exception.enforce(ptr == _basePtr);
            if (_length < length) {
                _basePtr = cast(T*)core.stdc.stdlib.realloc(cast(void*)_basePtr, length * T.sizeof);
            }
        }
        ptr = _basePtr;
        _length = length;
    }

    void free() {
        if (_basePtr) {
            core.stdc.stdlib.free(_basePtr);
            _basePtr = null;
            allocCount--;
        }
        ptr = null;
        _length = 0;
    }

    void slice(size_t i, size_t j) {
        ptr += i;
        _length = j - i;
    }

    void putSlice(NGCArray!T array) {
        putSlice(array, 0, array.length);
    }

    void putSlice(NGCArray!T array, size_t i, size_t j) {
        free();
        ptr = array.ptr + i;
        _length = j - i;
    }

    void opSliceAssign(T[] array, size_t i, size_t j) {
        ptr[i .. j] = array[];
    }
    T[] opSlice() { return ptr[0 .. length]; }
    T[] opSlice(size_t i, size_t j) { return ptr[i .. j]; }

    void opAssign(NGCArray!T array) {
        free();
        _basePtr = array._basePtr;
        ptr = array.ptr;
        _length = array._length;
    }
    void opAssign(T[] array) {
        free();
        ptr = array.ptr;
        _length = array.length;
    }
}
