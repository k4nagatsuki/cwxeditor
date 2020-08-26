// This file is converted to D from lhafile the Python library
// written by Hidekazu Ohnishi.
// http://trac.neotitans.net/wiki/lhafile
//
// License:
//
// Copyright (c) 2010 Hidekazu Ohnishi.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
//      copyright notice, this list of conditions and the following
//      disclaimer in the documentation and/or other materials provided
//      with the distribution.
//
//    * Neither the name of the author nor the names of its contributors
//      may be used to endorse or promote products derived from this
//      software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/**
Lhafile, extension extract lzh file.
Its interface is likey zipfile module is include in regular python environment.
*/
module lhafile.lhafile;

import std.algorithm;
import std.datetime;
import std.exception;
import std.file;
import std.path;
import std.string;
import std.utf;

import cwx.binary;
import cwx.sjis;

import lhafile.lzhlib;


@property
bool isLhaFile(string fileName) {
    try {
        new LhaFile(fileName);
    } catch (Exception) {
        return false;
    }
    return true;
}

class BadLhafile : Exception {
    this (string msg) {
        super (msg);
    }
}


class LhaInfo {
    string origFileName;
    string fileName;
    string directory;
    bool isDirectory;
    SysTime dateTime;
    string compressType;
    string comment;
    string extra;
    string createSystem;
    string createVersion;
    string extractVersion;
    string reserved;
    int flagBits;
    int volume;
    int internalAttr;
    int externalAttr;
    long headerOffset;
    size_t fileOffset;
    int crc;
    size_t compressSize;
    size_t fileSize;

    override
    const
    string toString() {
        return .format("%s %s %08X %d %04X", this.fileName, this.fileSize,
            this.fileOffset, this.compressSize, this.crc);
    }
}

alias LhaFileCallback = void delegate(void* args, long pos, long fileSize, LhaInfo info);

class LhaFile {

    static immutable SUPPORTED_COMPRESS_TYPE = [ "-lhd-", "-lh0-", "-lh5-", "-lh6-", "-lh7-" ];

    private LhaInfo[] fileList;
    private LhaInfo[string] nameToInfo;
    private string fileName;
    private string mode;
    private ByteIO fp;
    private long fileSize;

    /// Open the LZH file.
    this (string fileName, LhaFileCallback callback = null, void* args = null) {
        this (fileName, ByteIO(.read(fileName)), callback, args);
    }
    /// ditto
    this (string fileName, ByteIO file, LhaFileCallback callback = null, void* args = null) {
        this.mode = "r";
        this.fileName = fileName;
        this.fp = file;

        // Get file size
        this.fileSize = this.fp.length;

        this._GetContents(callback, args);
    }

    private void _GetContents(LhaFileCallback callback, void* args) {
        LhaInfo info;
        while ((info = this._RealGetContent()) !is null) {
            if (!SUPPORTED_COMPRESS_TYPE.find(info.compressType)) {
                throw new Exception(.format("Unsupported file is contained %s", info.compressType));
            }
            if (callback) {
                callback(args, this.fp.pointer, this.fileSize, info);
            }
            this.fileList ~= info;
            this.nameToInfo[info.fileName] = info;
        }
    }

    private LhaInfo _RealGetContent() {
        auto filesize = this.fileSize;
        auto initial_pos = fp.pointer;
        auto is_read = (long x) => fp.pointer + x < fileSize;
        if (fp.pointer == filesize - 1) {
            return null;
        }
        if (!is_read(26)) {
            throw new BadLhafile("Header is broken");
        }
        // Check OS level
        fp.seek(20);
        auto os_level = fp.readUByteL;
        fp.seek(-21);
        if (os_level != 0 && os_level != 1 && os_level != 2) {
            throw new BadLhafile(.format("this file level is out of support range %d", os_level));
        }
        ubyte header_size;
        ubyte checksum;
        auto signature = new ubyte[5];
        uint skip_size;
        uint file_size;
        auto modify_time = new ubyte[4];
        ubyte reserved;
        ushort ext_header_size;
        size_t extra_data_size;
        int compress_size;
        ushort all_header_size;
        uint modify_time_i;
        ushort crc;
        ubyte os_identifier;
        int sum_ext_header_size = 0;
        ubyte[] directory = null;
        ubyte[] comment = null;
        ubyte[] filename;
        if (os_level == 0 || os_level == 1) {
            header_size = fp.readUByteL;
            checksum = fp.readUByteL;
            fp.read(signature);
            skip_size = fp.readUIntL;
            file_size = fp.readUIntL;
            fp.read(modify_time);
            reserved = fp.readUByteL;
            os_level = fp.readUByteL;
            auto filename_length = fp.readUByteL;
            if (is_read(filename_length + 2)) {
                filename = new ubyte[filename_length]; fp.read(filename);
                crc = fp.readUShortL;
            }
            if (os_level == 0) {
                ext_header_size = 0;
            } else if (os_level == 1) {
                extra_data_size = header_size - (5+4+4+2+2+1+1+1+filename_length+2+1+2);
                os_identifier = fp.readUByteL;
                auto extra_data = new ubyte[extra_data_size]; fp.read(extra_data);
                ext_header_size = fp.readUShortL();
            }
            compress_size = skip_size - sum_ext_header_size;
        } else if (os_level == 2) {
            all_header_size = fp.readUShortL;
            fp.read(signature);
            compress_size = fp.readUIntL;
            file_size = fp.readUIntL;
            modify_time_i = fp.readUIntL;
            reserved = fp.readUByteL;
            os_level = fp.readUByteL;
            crc = fp.readUShortL;
            os_identifier = fp.readUByteL;
            ext_header_size = fp.readUShortL;
        }
        while (ext_header_size != 0) {
            sum_ext_header_size += ext_header_size;
            if (!is_read(ext_header_size)) {
                throw new BadLhafile("File is broken");
            }
            auto ext = fp.readUByteL;
            if (ext == 0x00) {
                // Common header
                auto dummy = new ubyte[ext_header_size - 3]; fp.read(dummy);
                ext_header_size = fp.readUShortL;
            } else if (ext == 0x01) {
                // Filename header
                filename = new ubyte[ext_header_size - 3]; fp.read(filename);
                ext_header_size = fp.readUShortL;
            } else if (ext == 0x02) {
                // Directory name header
                directory = new ubyte[ext_header_size - 3]; fp.read(directory);
                ext_header_size = fp.readUShortL;
            } else if (ext == 0x3F) {
                // Comment header
                comment = new ubyte[ext_header_size - 3]; fp.read(comment);
                ext_header_size = fp.readUShortL;
            } else if (ext == 0x40) {
                // Attribute Header
                if (ext_header_size != 5) {
                    throw new BadLhafile("file is broken");
                }
                auto attr = fp.readUShortL;
                ext_header_size = fp.readUShortL;
            } else {
                // Skip the other
                auto dummy = new ubyte[ext_header_size - 3]; fp.read(dummy);
                ext_header_size = fp.readUShortL;
            }
        }
        // skip to next header
        auto file_offset = fp.pointer;
        if (os_level == 0 || os_level == 1) {
            compress_size = skip_size - sum_ext_header_size;
        }
        if (!is_read(compress_size)) {
            throw new BadLhafile("Compress data is too short");
        }
        fp.seek(compress_size);
        // modify_time
        SysTime date_time, create_time;
        if (os_level == 0 || os_level == 1) {
            auto year = (modify_time[3] >> 1) + 1980;
            auto month = ((modify_time[3] << 8 | modify_time[2]) >> 5) & 0x0F;
            auto day  = modify_time[2] & 0x1F;
            auto hour = modify_time[1] >> 3;
            auto minute = ((modify_time[1] << 8 | modify_time[0]) >> 5) & 0x2F;
            auto second = (modify_time[0] & 0x1F) * 2;

            //print(os_level, year, month, day, hour, minute, second)
            try {
                date_time = SysTime(DateTime(year, month, day, hour, minute, second));
            } catch (Exception) {
                date_time = SysTime(DateTime(1970, 1, 1));
            }
            create_time = date_time;
        } else if (os_level == 2) {
            date_time = SysTime(unixTimeToStdTime(modify_time_i));
            create_time = date_time;
        }
        auto info = new LhaInfo();
        string decode(in ubyte[] b) {
            auto s = cast(const char[])b;
            try {
                s.validate();
                return .assumeUnique(s);
            } catch (UTFException) {
                return s.touni(false, "__");
            }
        }
        auto sDirectory = directory.split(0xff).map!(decode).join(.dirSeparator).replace("\\", .dirSeparator);
        auto sFileName = decode(filename).replace("\\", .dirSeparator);
        string path;
        auto isDirectory = (0 == sFileName.length || sFileName.endsWith(.dirSeparator));
        if (directory) {
            path = sFileName ? sDirectory.buildPath(sFileName) : sDirectory;
        } else {
            path = sFileName;
        }
        info.directory = .assumeUnique(sDirectory);
        info.fileName = path;
        info.isDirectory = isDirectory;
        info.compressSize = compress_size;
        info.fileSize = file_size;
        info.crc = crc;
        info.headerOffset = initial_pos;
        info.fileOffset = file_offset;
        info.externalAttr = 0;
        info.internalAttr = 0;
        info.reserved = "";
        info.comment = comment is null ? "" : decode(comment);
        info.compressType = decode(signature);
        info.dateTime = date_time;

        if (info.fileName.find("\0")) {
            auto splitted = info.fileName.split("\0");
            if (2 <= splitted.length) {
                info.fileName = splitted[0];
                info.comment = splitted[1];
            }
        }
        info.directory = info.directory.chomp(.dirSeparator);
        info.fileName = info.fileName.chomp(.dirSeparator);

        return info;
    }

    @property
    const
    string lhaName() {
        return this.fileName;
    }

    @property
    const
	const(char[])[] nameList() {
        string[] list = [];
        foreach (d; this.fileList) {
            if (SUPPORTED_COMPRESS_TYPE.find(d.compressType)) {
                list ~= d.fileName;
            }
        }
        return list;
    }

    @property
    const
    const(LhaInfo)[] infoList() {
        return this.fileList;
    }

    /// Return file bytes (as a string) for 'name'.
    ubyte[] read(string name) {
        //if (!this.fp) {
        //    throw new Exception("Attempt to read LZH archive that was already closed");
        //}
        auto info = this.nameToInfo.get(name, null);
        if (!info) {
            throw new Exception(.format("%s is not existed in archive.", name));
        } else if (SUPPORTED_COMPRESS_TYPE.find(info.compressType)) {
            this.fp.pointer = info.fileOffset;
            auto iBytes = new ubyte[info.compressSize];
            this.fp.read(iBytes);
            auto fin = ByteIO(iBytes);
            auto fout = ByteIO();
            auto session = new LZHDecodeSession(fin, fout, info.compressType, info.compressSize, info.fileSize, info.crc);
            while (!session.do_next()) {
                // Pass
            }
            auto outsize = session.output_pos;
            auto crc = session.crc16;
            if (outsize != info.fileSize) {
                throw new BadLhafile(.format("%s output_size is not matched %d/%d %s",
                    name, outsize, info.fileSize, info.compressType));
            }
            if (crc != info.crc) {
                throw new BadLhafile("crc is not matched");
            }

            return session.expandedData;

        } else if (info.compressType == "-lhd-") {
            throw new Exception("name is directory");
        } else {
            throw new Exception("Unsupport format");
        }
    }
}
