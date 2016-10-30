/*
This file is converted to D from lhafile the Python library
written by Hidekazu Ohnishi.
http://trac.neotitans.net/wiki/lhafile

License:

lzhlib - lzh library modules for lhafile
Copyright (c) 2010 Hidekazu Ohnishi.
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of the author nor the names of its contributors
      may be used to endorse or promote products derived from this
      software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module lhafile.lzhlib;

private:

import std.string;
import std.algorithm;

import cwx.binary;

alias long Py_off_t;

enum FILE_BUFFER_SIZE = 64 * 1024;

/* ===================================================================== */
/* Constant definitions. */

enum lzhlib_compress_type {
    COMPRESS_TYPE_LH0 = 1,
    COMPRESS_TYPE_LH5,
    COMPRESS_TYPE_LH6,
    COMPRESS_TYPE_LH7,
}

enum {
    ERR_UNEXPECT_EOF = 1,
    ERR_OUT_OF_RANGE,
    ERR_VALUE_ERROR,
    ERR_OUT_OF_MEMORY,
    ERR_IO_ERROR,
    ERR_BIT_LENGTH_TABLE_ERROR,
    ERR_BIT_PATTERN_TABLE_ERROR,
    ERR_BIT_LENGTH_SIZE_ERROR,
    ERR_DATA_ERROR,
    ERR_BUFFER_OVER_FLOW,
}

static immutable lzhlib_error_msg = [
    "Unexpehct EOF. It is seemed this file is broken",
    "It is seemd the compressed data is too short",
    "Input argument error",
    "Out of mwmoey",
    "I/O error is happend",
    "Lzh file is seemed broken",
    "Lzh file is seemed broken",
    "Lzh file is seemed broken",
    "Can't write file",
    "Buffer overflow will happened",
];

enum bit_stream_err_type {
    NO_ERROR = 0,
    BIT_STREAM_ERR_OVERFLOW = 0x01,
    BIT_STREAM_ERR_IOERROR = 0x02,
}


/* ===================================================================== */
/* Structure definitions. */

struct bit_stream_reader {
    ByteIO fp;
    ubyte[] read_buf;
    ubyte* buf, end;
    uint cache;
    int bit;
    int remain_bit;
    Py_off_t pos;
    int eof;
}

struct bit_stream_writer {
    ByteIO fp;
    ubyte[] write_buf;
    ubyte* start, buf, end;
    Py_off_t pos;
    int crc16;
    bit_stream_err_type error;
}

struct bit_length_table {
    ubyte[] table;
    int bitMax;
}

struct bit_pattern_table {
    int[510] table;
    size_t len;
    int[17] _freqTable;
    int[17] _weight;
    int[17] _startPattern;
}

struct huffman_decoder {
    int bitMax;
    int bitlength;
    ushort[65536] blen_code;
    bit_length_table _blt;
    bit_pattern_table _bpt;
}



/* ===================================================================== */
/* crc16 */

static immutable int[256] _crc16Table =
[
    0x0000, 0xC0C1, 0xC181, 0x0140, 0xC301, 0x03C0, 0x0280, 0xC241,
    0xC601, 0x06C0, 0x0780, 0xC741, 0x0500, 0xC5C1, 0xC481, 0x0440,
    0xCC01, 0x0CC0, 0x0D80, 0xCD41, 0x0F00, 0xCFC1, 0xCE81, 0x0E40,
    0x0A00, 0xCAC1, 0xCB81, 0x0B40, 0xC901, 0x09C0, 0x0880, 0xC841,
    0xD801, 0x18C0, 0x1980, 0xD941, 0x1B00, 0xDBC1, 0xDA81, 0x1A40,
    0x1E00, 0xDEC1, 0xDF81, 0x1F40, 0xDD01, 0x1DC0, 0x1C80, 0xDC41,
    0x1400, 0xD4C1, 0xD581, 0x1540, 0xD701, 0x17C0, 0x1680, 0xD641,
    0xD201, 0x12C0, 0x1380, 0xD341, 0x1100, 0xD1C1, 0xD081, 0x1040,
    0xF001, 0x30C0, 0x3180, 0xF141, 0x3300, 0xF3C1, 0xF281, 0x3240,
    0x3600, 0xF6C1, 0xF781, 0x3740, 0xF501, 0x35C0, 0x3480, 0xF441,
    0x3C00, 0xFCC1, 0xFD81, 0x3D40, 0xFF01, 0x3FC0, 0x3E80, 0xFE41,
    0xFA01, 0x3AC0, 0x3B80, 0xFB41, 0x3900, 0xF9C1, 0xF881, 0x3840,
    0x2800, 0xE8C1, 0xE981, 0x2940, 0xEB01, 0x2BC0, 0x2A80, 0xEA41,
    0xEE01, 0x2EC0, 0x2F80, 0xEF41, 0x2D00, 0xEDC1, 0xEC81, 0x2C40,
    0xE401, 0x24C0, 0x2580, 0xE541, 0x2700, 0xE7C1, 0xE681, 0x2640,
    0x2200, 0xE2C1, 0xE381, 0x2340, 0xE101, 0x21C0, 0x2080, 0xE041,
    0xA001, 0x60C0, 0x6180, 0xA141, 0x6300, 0xA3C1, 0xA281, 0x6240,
    0x6600, 0xA6C1, 0xA781, 0x6740, 0xA501, 0x65C0, 0x6480, 0xA441,
    0x6C00, 0xACC1, 0xAD81, 0x6D40, 0xAF01, 0x6FC0, 0x6E80, 0xAE41,
    0xAA01, 0x6AC0, 0x6B80, 0xAB41, 0x6900, 0xA9C1, 0xA881, 0x6840,
    0x7800, 0xB8C1, 0xB981, 0x7940, 0xBB01, 0x7BC0, 0x7A80, 0xBA41,
    0xBE01, 0x7EC0, 0x7F80, 0xBF41, 0x7D00, 0xBDC1, 0xBC81, 0x7C40,
    0xB401, 0x74C0, 0x7580, 0xB541, 0x7700, 0xB7C1, 0xB681, 0x7640,
    0x7200, 0xB2C1, 0xB381, 0x7340, 0xB101, 0x71C0, 0x7080, 0xB041,
    0x5000, 0x90C1, 0x9181, 0x5140, 0x9301, 0x53C0, 0x5280, 0x9241,
    0x9601, 0x56C0, 0x5780, 0x9741, 0x5500, 0x95C1, 0x9481, 0x5440,
    0x9C01, 0x5CC0, 0x5D80, 0x9D41, 0x5F00, 0x9FC1, 0x9E81, 0x5E40,
    0x5A00, 0x9AC1, 0x9B81, 0x5B40, 0x9901, 0x59C0, 0x5880, 0x9841,
    0x8801, 0x48C0, 0x4980, 0x8941, 0x4B00, 0x8BC1, 0x8A81, 0x4A40,
    0x4E00, 0x8EC1, 0x8F81, 0x4F40, 0x8D01, 0x4DC0, 0x4C80, 0x8C41,
    0x4400, 0x84C1, 0x8581, 0x4540, 0x8701, 0x47C0, 0x4680, 0x8641,
    0x8201, 0x42C0, 0x4380, 0x8341, 0x4100, 0x81C1, 0x8081, 0x4040,
];

private int
crc16(ubyte* data, int len, int crc){
    for(; len > 0 ; data++, len--){
    crc = (crc >> 8) ^ _crc16Table[(crc ^ *data) & 0xFF];
    }

    return crc;
}

/* ===================================================================== */
/* lzh decode */


/* BITSTREAM OPERATIONS */

private int
bit_stream_reader_init_fileio(ref bit_stream_reader self, ref ByteIO file)
{
    int error_no = 0;
    int i;
    ubyte* buf, end;
    uint cache;
	auto read_obj = new ubyte[.min(FILE_BUFFER_SIZE, file.length - file.pointer)];

    /* Read ahead data */
    try {
        file.read(read_obj);
    } catch (Exception) {
        destroy(read_obj);
        error_no = ERR_VALUE_ERROR;
        goto error;
    }

    self.fp = file;
    self.read_buf = read_obj;
    self.bit = 0;
    self.pos = 0;

    buf = read_obj.ptr;
    end = buf + read_obj.length;

    /* Fill Cache */
    cache = 0;
    self.remain_bit = 0;
    for(i=0; i < uint.sizeof && buf != end; i++){
        cache = (cache << 8) | *buf++;
        self.remain_bit += 8;
    }

    self.buf = buf;
    self.end = end;
    self.cache = cache;
    if(buf == end){
        self.eof = 1;
        self.cache <<= (8 * uint.sizeof - self.remain_bit);
    }else{
        self.remain_bit = 0;
        self.eof = 0;
    }

    return 0;

error:
    destroy(read_obj);

    return error_no;
}


private void
bit_stream_reader_close(ref bit_stream_reader self)
{
    destroy(self.read_buf);
    self.read_buf = null;
}

private Py_off_t
bit_stream_reader_pos(ref bit_stream_reader self)
{
    return self.pos;
}

private int
bit_stream_reader_pre_fetch(ref bit_stream_reader self, int n)
{
    return cast(int)(self.cache >> (8 * int.sizeof - n));
}

private int
bit_stream_reader_fetch(ref bit_stream_reader self, int n)
{
    int ret;

    if(n > 16 || n <= 0){
        if(n == 0){
            return 0;
        }
        return -2;
    }

    ret = cast(int)(self.cache >> (8 * int.sizeof - n));
    self.cache <<= n;
    self.bit += n;

    if(self.eof){
        if(self.bit > self.remain_bit){
            return -1;
        }
    }else if(uint.sizeof * 8 - self.bit <= 16){
        self.cache >>= self.bit;

        /* if remain data cahce size is under 16 then read ahead */
        while(uint.sizeof * 8 - self.bit <= 16){
            if(self.buf == self.end){
                auto read_obj = new ubyte[.min(FILE_BUFFER_SIZE, self.fp.length - self.fp.pointer)];

                /* free old buffer */
                destroy(self.read_buf);
                self.read_buf = null;

                /* read ahead data*/
                try {
                    self.fp.read(read_obj);
                } catch (Exception) {
                    destroy(read_obj);
                    ret = ERR_VALUE_ERROR;
                    goto error;
                }

                self.buf = read_obj.ptr;
                self.end = self.buf + read_obj.length;

                if(self.buf != self.end){
                    self.read_buf = read_obj;
                }else{
                    /* this condition means eof */
                    self.eof = 1;
                    self.remain_bit = uint.sizeof * 8;
                    break;
                }
            }
            self.cache <<= 8;
            self.cache |= *self.buf++;
            self.bit -= 8;
            self.pos += 1;
        }

        self.cache <<= self.bit;
    }

error:
    return ret;
}


private int
bit_stream_writer_init_fileio(ref bit_stream_writer self, ref ByteIO file)
{
    int error_no = 0;

    ubyte* buf, end;
    ubyte[] write_obj;

    /* Allocate write buffer */
    write_obj = new ubyte[65556];

    self.fp = file;
    self.write_buf = write_obj;
    self.crc16 = 0;
    self.pos = 0;

    buf = write_obj.ptr;
    end = buf + write_obj.length;

    self.start = buf;
    self.buf = buf;
    self.end = end;

    self.error = bit_stream_err_type.NO_ERROR;

    return 0;

error:

    return error_no;
}

private int
bit_stream_writer_flush(ref bit_stream_writer self)
{
    int error_no = 0;
    ubyte[] write_obj = null;
    int s;

    if(self.write_buf){
        s = cast(int)(self.buf - self.start);

        if(s > 0){
            self.crc16 = crc16(self.start, s, self.crc16);
            write_obj = self.write_buf[0 .. s];

            try {
                self.fp.write(write_obj);
            } catch (Exception) {
                error_no = ERR_IO_ERROR;
                goto error;
            }
        }

        self.buf = self.start;
    }

error:

    return error_no;
}

private int
bit_stream_writer_close(ref bit_stream_writer self)
{
    int error_no = 0;

    error_no = bit_stream_writer_flush(self);

    destroy(self.write_buf);
    self.write_buf = null;

    return error_no;
}


private int
bit_stream_writer_overflow(ref bit_stream_writer self)
{
    return ((self.error & bit_stream_err_type.BIT_STREAM_ERR_OVERFLOW) != 0);
}

private int
bit_stream_writer_ioerror(ref bit_stream_writer self)
{
    return ((self.error & bit_stream_err_type.BIT_STREAM_ERR_IOERROR) != 0);
}

private Py_off_t
bit_stream_writer_pos(ref bit_stream_writer self)
{
    return self.pos;
}

private int
bit_stream_writer_crc(ref bit_stream_writer self)
{
    return self.crc16;
}

private void
bit_stream_writer_write(ref bit_stream_writer self, int c)
{
    self.pos++;
    *self.buf++ = cast(ubyte)c;

    if(self.buf == self.end){
        int s;

        s = cast(int)(self.buf - self.start);
        self.crc16 = crc16(self.start, s, self.crc16);

        try {
            self.fp.write(self.write_buf);
        } catch (Exception) {
            self.error |= bit_stream_err_type.BIT_STREAM_ERR_OVERFLOW;
        }

        self.buf = self.start;
    }
}


/* BIT LENGTH TABLE OPERATIONS */

private int
bit_length_table_init(ref bit_length_table self, ubyte[] s)
{
    int error_no = 0;
    int bitMax = 0;
    int blen, i;

    for(i = 0; i < s.length; i++){
        blen = s[i];
        if(bitMax < blen){
            bitMax = blen;
        }
    }

    if( bitMax == 0 || bitMax > 16 || s.length == 0){
        error_no = ERR_BIT_LENGTH_TABLE_ERROR;
        goto error;
    }

    self.table = s;
    self.bitMax = bitMax;

error:
    return error_no;
}

private ubyte[]
bit_length_table_table(ref bit_length_table self){
    return self.table;
}

private int
bit_length_table_bitMax(ref bit_length_table self){
    return self.bitMax;
}

private int
bit_length_table_table_num(ref bit_length_table self, int i){
    return self.table[i];
}


/* BIT PATTERN TABLE OPERATIONS */

private int
bit_pattern_table_init(ref bit_pattern_table self, ref bit_length_table blt)
{
    int error_no = 0;
    int i, ptn, w, bl;
    int bitMax;
    size_t tableMax;

    int* table = self.table.ptr;
    int* freqTable = self._freqTable.ptr;
    int* weight = self._weight.ptr;
    int* startPattern = self._startPattern.ptr;

    bitMax = bit_length_table_bitMax(blt);
    tableMax = bit_length_table_table(blt).length;

    freqTable[0 .. bitMax + 1] = 0;
    weight[0 .. bitMax + 1] = 0;
    startPattern[0 .. bitMax + 1] = 0;

    for(i = 0; i < bit_length_table_table(blt).length; i++){
        bl = bit_length_table_table_num(blt, i);
        if(bl == 0){
            continue;
        }
        freqTable[bl] += 1;
    }

    ptn = 0;
    w = 1 << (bitMax - 1);
    for(i = 1; i <= bitMax ; i++){
        startPattern[i] = ptn;
        weight[i] = w;

        ptn += (w * freqTable[i]);
        w >>= 1;
    }

    if(ptn > (1 << bitMax)){
        error_no = ERR_BIT_PATTERN_TABLE_ERROR;
        goto error;
    }

    /* Make bit pattern table */
    for(i = 0 ; i < tableMax ; i++){
        bl = bit_length_table_table_num(blt, i);
        if(bl == 0){
            table[i] = 0;
            continue;
        }

        ptn = startPattern[bl];
        table[i] = ptn >> (bitMax - bl);
        startPattern[bl] += weight[bl];
    }

    self.len = tableMax;

error:
    return error_no;
}

private int
bit_pattern_table_table_num(ref bit_pattern_table self, int i){
    return self.table[i];
}


/* HUFFMAN DECODER OPERATIONS */

private int
huffman_decoder_init(ref huffman_decoder self, ubyte[] s)
{
    int error_no = 0;
    int i;
    int bitMax;
    int ptn, blen;
    ushort* blen_code = self.blen_code.ptr;

    error_no = bit_length_table_init(self._blt, s);
    if(error_no != 0){
        goto error;
    }

    error_no = bit_pattern_table_init(self._bpt, self._blt);
    if(error_no != 0){
        goto error;
    }

    bitMax = bit_length_table_bitMax(self._blt);

    blen_code[0 .. (1 << cast(int)bitMax)] = 0;

    for(i = 0; i < bit_length_table_table(self._blt).length; i++){
        blen = bit_length_table_table_num(self._blt, i);
        if(blen == 0){
            continue;
        }

        ptn = bit_pattern_table_table_num(self._bpt, i) << (bitMax - blen);

        blen_code[ptn] = cast(ushort)((blen << 11) | i);

    }

    if(bitMax == 1){
        if(blen_code[1] == 0){
            blen_code[0] &= 0x1FF;
        }
    }

    blen = *blen_code++;
    for(i = 1; i < (1 << bitMax) ; i++, blen_code++){
        if(*blen_code == 0){
            *blen_code = cast(ushort)blen;
        }else{
            blen = *blen_code;
        }
    }

    self.bitMax = bitMax;

error:
    return error_no;
}

private int
huffman_decoder_decode(ref huffman_decoder self, ref bit_stream_reader bs)
{
    int bits, blen, code;

    bits = bit_stream_reader_pre_fetch(bs, self.bitMax);
    blen = self.blen_code[bits] >> 11;
    code = self.blen_code[bits] & 0x1FF;
    bit_stream_reader_fetch(bs, blen);

    return code;
}

/* LZH DECODE OPERATIONS */

private int eofCheck(int c) {
    int error_no = 0;
    if(c < 0){
        if(c == -1){
            error_no = ERR_UNEXPECT_EOF;
        }else if(c == -2){
            error_no = ERR_OUT_OF_RANGE;
        }
    }
    return error_no;
}

private int
decodeUnary7(ref bit_stream_reader bs, ref int unary_code)
{
    int error_no = 0;
    int c, code;

    code = bit_stream_reader_fetch(bs, 3);
    if ((error_no = eofCheck(code)) != 0) goto error;

    if(code == 7){
        while((c = bit_stream_reader_fetch(bs, 1)) == 1){
            code += 1;
        }
        if ((error_no = eofCheck(c)) != 0) goto error;
    }

    unary_code = code;

error:
    return error_no;
}


private int
decodeBitLengthDecoder(ref bit_stream_reader bs, ubyte[] blenlen19)
{
    int error_no = 0;
    int i, c;
    int blenSize, blenLeafCode, nmax;


    blenSize = bit_stream_reader_fetch(bs, 5);
    if ((error_no = eofCheck(blenSize)) != 0) goto error;
    if(blenSize > 19){
        error_no = ERR_BIT_LENGTH_SIZE_ERROR;
        goto error;
    }

    if(blenSize == 0){
        blenLeafCode = bit_stream_reader_fetch(bs, 5);
        if ((error_no = eofCheck(blenLeafCode)) != 0) goto error;
        if(blenLeafCode >= 19){
            error_no = ERR_BIT_LENGTH_SIZE_ERROR;
            goto error;
        }
        blenlen19[] = 0;
        blenlen19[blenLeafCode] = 1;
    }else{
        i = 0;

        while(i < blenSize){
            error_no = decodeUnary7(bs, c);

            if(error_no != 0){
                goto error;
            }

            blenlen19[i] = cast(ubyte)c;
            i += 1;

            if(i == 3){
                nmax = bit_stream_reader_fetch(bs, 2);
                if ((error_no = eofCheck(nmax)) != 0) goto error;

                while(nmax > 0){
                    blenlen19[i] = 0;
                    i += 1;
                    nmax -= 1;
                }
            }
        }

        while(i < 19){
            blenlen19[i] = 0;
            i += 1;
        }
    }

error:
    return error_no;

}

private int
decodeBitLengthLiteral(ref bit_stream_reader bs, ubyte[] blenlen510, ref huffman_decoder bitlen_decoder)
{
    int error_no = 0;
    int i, n, code, c, leafCode;

    n = bit_stream_reader_fetch(bs, 9);
    if ((error_no = eofCheck(n)) != 0) goto error;

    if(n == 0){
        leafCode = bit_stream_reader_fetch(bs, 9);
        if ((error_no = eofCheck(leafCode)) != 0) goto error;

        blenlen510[] = 0;
        blenlen510[leafCode] = 1;
    }else{
        i = 0;

        while(i < n){
            code = huffman_decoder_decode(bitlen_decoder, bs);

            if(code > 2){
                blenlen510[i] = cast(ubyte)(code - 2);
                i += 1;
                continue;
            }else if(code == 0){
                blenlen510[i] = 0;
                i += 1;
                continue;
            }else if(code == 1){
                c = bit_stream_reader_fetch(bs, 4);
                if ((error_no = eofCheck(c)) != 0) goto error;
                c += 3;
            }else if(code == 2){
                c = bit_stream_reader_fetch(bs, 9);
                if ((error_no = eofCheck(c)) != 0) goto error;
                c += 20;
            }else{
                error_no = ERR_DATA_ERROR;
                goto error;
            }

            while(c > 0){
                c -= 1;
                blenlen510[i] = 0;
                i += 1;
            }
        }

        while(i < 510){
            blenlen510[i] = 0;
            i += 1;
        }
    }

error:
    return error_no;
}

private int
decodeBitLengthDistance(ref bit_stream_reader bs, ubyte[] blenlen_distance, int dispos_bit, int dis_bit)
{
    int error_no = 0;
    int i, unary;
    int leafCode, tableSize;

    tableSize = bit_stream_reader_fetch(bs, dis_bit);
    if ((error_no = eofCheck(tableSize)) != 0) goto error;

    if(tableSize == 0){
        leafCode = bit_stream_reader_fetch(bs, dis_bit);
        if ((error_no = eofCheck(leafCode)) != 0) goto error;

        blenlen_distance[] = 0;
        blenlen_distance[leafCode] = 1;
    }else{
        i = 0;

        while(i < tableSize){
            error_no = decodeUnary7(bs, unary);
            if(error_no != 0){
                goto error;
            }
            blenlen_distance[i] = cast(ubyte)unary;

            i += 1;
        }

        while(i <= dispos_bit){
            blenlen_distance[i] = 0;
            i += 1;
        }
    }

error:
    return error_no;
}


/*
 *
 */

public class LZHDecodeSession {
    private ByteIO fin;
    private ByteIO fout;
    private lzhlib_compress_type compress_type;
    private Py_off_t info_compress_size;
    private Py_off_t info_file_size;
    private int      info_crc;


    private bit_stream_reader in_;
    private bit_stream_writer out_;

    private huffman_decoder distance_decoder;
    private huffman_decoder literal_decoder;
    private alias bitlen_decoder = distance_decoder;

    private ubyte[] bitlen_distance;
    private ubyte[18] _bitlen_distance_buf;
    private ubyte[19] bitlen19;
    private ubyte[510] bitlen510;

    private ubyte[65536] dic_buf;
    private int dic_pos;
    private int dic_size;
    private int blockSize;

    private int finish;
    private int error_no;

    private int dic_bit;
    private int dispos_bit;
    private int dis_bit;

    bool
    do_next()
    {
        int error_no = 0;
        int loop, code, srcpos, mlen, bitl, dist;
        bool ret;

        /* */
        if(this.error_no){
            goto exception;
        }

        if(this.finish){
            return true;
        }

        loop = 64*1024;

        if(this.compress_type == lzhlib_compress_type.COMPRESS_TYPE_LH0){
            /* This code is slow, but this happens a little */
            while(loop > 0){
                code = bit_stream_reader_fetch(this.in_, 8);
                if(code == -1){
                    this.finish = 1;
                    break;
                }
                bit_stream_writer_write(this.out_, code);
                loop -= 1;
            }
        }else{
            while(loop > 0){
                if(this.blockSize <= 0){
                    /* Delayed check for tuning */
                    if(bit_stream_writer_overflow(this.out_) != 0){
                        error_no = ERR_BUFFER_OVER_FLOW;
                        break;
                    }

                    if(bit_stream_writer_ioerror(this.out_) != 0){
                        error_no = ERR_IO_ERROR;
                        break;
                    }

                    /* Read blockSize */
                    this.blockSize = bit_stream_reader_fetch(this.in_, 16);

                    if(this.blockSize == -1){
                        this.finish = 1;
                        break;
                    }else{
                        /* Create bitlen_decoder for literal_decoder */
                        error_no = decodeBitLengthDecoder(this.in_, this.bitlen19);
                        if(error_no != 0){goto error;}

                        error_no = huffman_decoder_init(this.bitlen_decoder, this.bitlen19);
                        if(error_no != 0){goto error;}

                        /* Create literal decoder */
                        error_no = decodeBitLengthLiteral(this.in_, this.bitlen510, this.bitlen_decoder);
                        if(error_no != 0){goto error;}

                        error_no = huffman_decoder_init(this.literal_decoder, this.bitlen510);
                        if(error_no != 0){goto error;}

                        /* Create distance decoder */
                        error_no = decodeBitLengthDistance(this.in_, this.bitlen_distance, this.dispos_bit, this.dis_bit);
                        if(error_no != 0){goto error;}

                        error_no = huffman_decoder_init(this.distance_decoder, this.bitlen_distance);
                        if(error_no != 0){goto error;}

                    }
                }

                code = huffman_decoder_decode(this.literal_decoder, this.in_);
                this.blockSize -= 1;

                if(code < 256){
                    this.dic_buf[this.dic_pos++] = cast(ubyte)code;
                    bit_stream_writer_write(this.out_, code);
                    loop -=1;

                    this.dic_pos &= (this.dic_size -1);
                    continue;
                }

                mlen = code - 256 + 3;
                bitl = huffman_decoder_decode(this.distance_decoder, this.in_);

                if(bitl == 0){
                    dist = 1;
                }else{
                    dist = bit_stream_reader_fetch(this.in_, bitl - 1);
                    if ((error_no = eofCheck(dist)) != 0) goto error;
                    dist += (1 << (bitl - 1));
                    dist += 1;
                }

                srcpos = this.dic_pos - dist;
                if(srcpos < 0){
                    srcpos += this.dic_size;
                }

                for(; mlen > 0 ; mlen--){
                    code = this.dic_buf[this.dic_pos++] = this.dic_buf[srcpos++];
                    bit_stream_writer_write(this.out_, code);
                    loop -= 1;

                    this.dic_pos &= (this.dic_size -1);
                    srcpos &= (this.dic_size -1);
                }
            }
        }

error:

        if(error_no != 0){
            this.error_no = error_no;
            bit_stream_reader_close(this.in_);
            bit_stream_writer_close(this.out_);
            goto exception;
        }

        if(this.finish){
            bit_stream_reader_close(this.in_);
            error_no = bit_stream_writer_close(this.out_);
            if(error_no != 0){
                this.error_no = error_no;
                goto exception;
            }

            ret = true;
        }else{
            ret = false;
        }
        return ret;

exception:
        throw new Exception(.format("internal error code = %d", this.error_no));
    }

    @property
    long input_file_size() { return info_compress_size; }
    @property
    long input_pos() { return in_.pos; }
    @property
    long output_file_size() { return info_file_size; }
    @property
    long output_pos() { return out_.pos; }
    @property
    long crc16() { return out_.crc16; }
	@property
	ubyte[] expandedData() { return out_.fp.bytes; }

    this (ref ByteIO fin, ref ByteIO fout, string compress_type, Py_off_t compress_size, Py_off_t file_size, int crc)
    {
        int error_no;

        /* Initialize these so we can test them in dealloc if init fails */
        this.fin = null;
        this.fout = null;

        /* compress_type */
        if(compress_type.startsWith("-lh0-")){
            this.compress_type = lzhlib_compress_type.COMPRESS_TYPE_LH0;
            this.dic_size = 0;
        }else if(compress_type.startsWith("-lh5-")){
            this.compress_type = lzhlib_compress_type.COMPRESS_TYPE_LH5;
            this.dic_size = 8192;
            this.dic_bit = 13;
            this.dispos_bit = 14;
            this.dis_bit = 4;
        }else if(compress_type.startsWith("-lh6-")){
            this.compress_type = lzhlib_compress_type.COMPRESS_TYPE_LH6;
            this.dic_size = 32768;
            this.dic_bit = 15;
            this.dispos_bit = 16;
            this.dis_bit = 5;
        }else if(compress_type.startsWith("-lh7-")){
            this.compress_type = lzhlib_compress_type.COMPRESS_TYPE_LH7;
            this.dic_size = 65536;
            this.dic_bit = 16;
            this.dispos_bit = 17;
            this.dis_bit = 5;
        }else{
            throw new Exception("Unsupported compress type");
        }

        /* Initialize each buffer and decoder */
        bitlen_distance = this._bitlen_distance_buf[0 .. this.dispos_bit + 1];

        /* */
        this.finish = 0;
        this.error_no = 0;

        this.dic_pos = 0;

        this.blockSize = 0;

        this.info_compress_size = compress_size;
        this.info_file_size     = file_size;
        this.info_crc           = crc;

        this.fin = fin;
        this.fout = fout;

        error_no = bit_stream_reader_init_fileio(this.in_, this.fin);
        if(error_no != 0){
            throw new Exception("bit_stream_reader_init_fileio");
        }

        error_no = bit_stream_writer_init_fileio(this.out_, this.fout);
        if(error_no != 0){
            bit_stream_reader_close(this.in_);
            throw new Exception("bit_stream_writer_init_fileio");
        }
    }

    ~this()
    {
        /* If decode is not finished */
        if(!this.finish && this.error_no == 0){
            bit_stream_reader_close(this.in_);
            bit_stream_writer_close(this.out_);
        }
    }
}
