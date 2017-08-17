
module cwx.editor.gui.sound;

import std.algorithm : min;
import std.utf;
import std.stdint;
import std.stdio;
import std.string;
import std.conv;
import std.path;
import std.exception;
import std.file;
import std.process : environment;
import core.memory;
import core.stdc.stdio;
import core.stdc.stdlib;
import core.stdc.string;

import core.sync.mutex;
import core.stdc.wchar_;

import cwx.utils;

alias double c_double;

enum {
	SOUND_TYPE_AUTO = 0,
	SOUND_TYPE_SDL = 1,
	SOUND_TYPE_APP = 3,
	SOUND_TYPE_SAME_BGM = -1
}
version (Windows) {
	enum {
		SOUND_TYPE_MCI = 2,
		SOUND_TYPE_BASS = 4,
	}
} else {
	private alias uint DWORD;
}
private immutable CWBGM = "cwbgm";
private immutable CWSE = "cwse";

version (Windows) {
	import std.windows.charset;
	import core.sys.windows.windows;
	private extern (Windows) {
		alias __gshared DWORD MCIERROR;
		alias __gshared nothrow MCIERROR function(LPCWSTR, LPWSTR, UINT, HANDLE) mciSendStringW;
		BOOL UnregisterClassA(LPCSTR, HINSTANCE);
	}
	private const __gshared MCI_NOTIFY_SUCCESSFUL = 0x0001;
	private const __gshared MM_MCINOTIFY = 0x03B9;
	/// playBGM()は_mciNotifyHandleに設定されたウィンドウに対して
	/// 再生イベントを通知する。
	private HWND _mciNotifyHandleBGM = null;
	private HWND _mciNotifyHandleSE = null; /// ditto
	/// ditto
	nothrow
	private extern (Windows) LRESULT mciNotifyWndProcBGM(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
		return mciNotifyImpl(hWnd, message, wParam, lParam, _mciNotifyHandleBGM, CWBGM, _bgmPlayingMCI);
	}
	/// ditto
	nothrow
	private extern (Windows) LRESULT mciNotifyWndProcSE(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
		return mciNotifyImpl(hWnd, message, wParam, lParam, _mciNotifyHandleSE, CWSE, _sePlayingMCI);
	}
	nothrow
	private LRESULT mciNotifyImpl(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam, HWND handler, string name, bool playingMCI) {
		try {
			if (!handler || !winmm || !_mciSendString || !playingMCI || MM_MCINOTIFY != message || MCI_NOTIFY_SUCCESSFUL != wParam) {
				return DefWindowProcW(hWnd, message, wParam, lParam);
			}
			auto loops = loopCounts.get(name, 1);
			if (loops != 1) {
				if (0 < loops) loopCounts[name] = loops - 1;
				auto seek = ("seek " ~ to!wstring(name) ~ " to 0\0"w).ptr;
				if (loops == 1) {
					auto play = ("play " ~ to!wstring(name) ~ "\0"w).ptr;
					_mciSendString(seek, null, 0, null);
					_mciSendString(play, null, 0, null);
				} else {
					auto play = ("play " ~ to!wstring(name) ~ " notify\0"w).ptr;
					_mciSendString(seek, null, 0, null);
					_mciSendString(play, null, 0, handler);
				}
			} else {
				auto stop = ("stop " ~ to!wstring(name) ~ "\0"w).ptr;
				_mciSendString(stop, null, 0, null);
			}
		} catch (Exception) {
			// 例外を握りつぶす
		}
		return DefWindowProcW(hWnd, message, wParam, lParam);
	}
}
private extern (C) {
	immutable c_uint SDL_INIT_AUDIO = 0x10;
	immutable c_uint SDL_INIT_NOPARACHUTE  = 0x00100000;
	immutable ushort AUDIO_U8 = 0x0008;
	immutable ushort AUDIO_S8 = 0x8008;
	immutable ushort AUDIO_U16LSB = 0x0010;
	immutable ushort AUDIO_S16LSB = 0x8010;
	immutable ushort AUDIO_U16MSB = 0x1010;
	immutable ushort AUDIO_S16MSB = 0x9010;
	immutable ushort AUDIO_U16 = AUDIO_U16LSB;
	immutable ushort AUDIO_S16 = AUDIO_S16LSB;
	version (LittleEndian) {
		const __gshared ushort MIX_DEFAULT_FORMAT = AUDIO_S16LSB;
 	} else { mixin(S_TRACE);
		const __gshared ushort MIX_DEFAULT_FORMAT = AUDIO_S16MSB;
	}
	alias uint Uint32;
	alias ushort Uint16;
	alias ubyte Uint8;
	alias void Mix_Music;
	struct Mix_Chunk {
		c_int allocated;
		Uint8 *abuf;
		Uint32 alen;
		Uint8 volume;
	}

	immutable MIX_MAX_VOLUME = 128;

	struct SDL_RWops {}

	alias void function() SDL_SetMainReady;
	alias c_int function(Uint32) SDL_Init;
	alias char* function() SDL_GetError;
	alias void function() SDL_Quit;
	alias c_int function(c_int, Uint16, c_int, c_int) Mix_OpenAudio;
	alias void function() Mix_CloseAudio;
	alias c_int function(c_int numchans) Mix_AllocateChannels;
	alias Mix_Music* function(const char* file) Mix_LoadMUS;
	alias Mix_Chunk* function(Uint8* mem) Mix_QuickLoad_WAV;
	alias c_int function(Mix_Music* music, c_int loops) Mix_PlayMusic;
	alias c_int function(Mix_Music* music, c_int loops, c_int ms) Mix_FadeInMusic;
	alias c_int function(c_int channel, Mix_Chunk *chunk, c_int loops, c_int ticks) Mix_PlayChannelTimed;
	alias c_int function(c_int channel, Mix_Chunk *chunk, c_int loops, c_int ms, c_int ticks) Mix_FadeInChannelTimed;
	alias c_int function(Mix_Chunk* chunk, c_int volume) Mix_VolumeChunk;
	alias c_int function(c_int volume) Mix_VolumeMusic;
	alias c_int function(c_int channel, c_int volume) Mix_Volume;
	alias void function(Mix_Music* music) Mix_FreeMusic;
	alias c_int function() Mix_HaltMusic;
	alias c_int function(c_int channel) Mix_HaltChannel;
	alias void function(Mix_Chunk* chunk) Mix_FreeChunk;
	alias Mix_Chunk* function(SDL_RWops* src, c_int freesrc) Mix_LoadWAV_RW;
	alias SDL_RWops* function(const char* file, const char* mode) SDL_RWFromFile;
	alias c_int function(c_int *frequency, Uint16 *format, c_int *channels) Mix_QuerySpec;
	alias void function() Mix_RewindMusic;
	alias c_int function(c_double position) Mix_SetMusicPosition;
	alias c_int function() Mix_PlayingMusic;

	immutable SDL_FREQUENCY = 44100;
	immutable SDL_FORMAT = MIX_DEFAULT_FORMAT;
	immutable SDL_CHANNELS = 2;
	immutable SDL_CHUNKSIZE = 4092;
}

private __gshared void* sdl = null;
private __gshared void* mixer = null;
private __gshared c_int sdl_frequency = 0;
private __gshared Uint16 sdl_format = 0;
private __gshared c_int sdl_channels = 0;

private __gshared uint _bgmVolume = 100;
private __gshared uint _seVolume = 100;

private __gshared Mutex mutex = null;

private T getSymbol(T)(void* mod, string name) { mixin(S_TRACE);
	void* symbol = dlsym(mod, name);
	if (!symbol) throw new Exception("Symbol " ~ name ~ " is not found.");
	T r = cast(T) symbol;
	if (!r) throw new Exception("Symbol " ~ name ~ " is invalid function.");
	return r;
}

private __gshared bool _bgmPlayingMCI = false;
private __gshared bool _sePlayingMCI = false;
version (Windows) {
	private __gshared Mutex winmmSync = null;
	private __gshared void* winmm = null;
	private __gshared mciSendStringW _mciSendString = null;
	private void initWinmm() { mixin(S_TRACE);
		if (winmm) return;
		version (Console) {
			debug std.stdio.writeln("Initialize winmm.dll Start");
		}
		disposeSound();
		winmm = dlopen("winmm.dll");
		if (!winmm) { mixin(S_TRACE);
			debugln("error: winmm.dll initialize");
		}
		_mciSendString = getSymbol!(mciSendStringW)(winmm, "mciSendStringW");
		if (!_mciSendString) { mixin(S_TRACE);
			debugln("mciSendStringW() not found");
			dlclose(winmm);
			winmm = null;
			return;
		}
		if (!_mciNotifyHandleBGM) { mixin(S_TRACE);
			WNDCLASSA wc;
			wc.lpszClassName = "MCIHandlerBGM\0".ptr;
			wc.lpfnWndProc = &mciNotifyWndProcBGM;
			if (!RegisterClassA(&wc)) { mixin(S_TRACE);
				debugln("RegisterClass() failure");
				return;
			}
			_mciNotifyHandleBGM = CreateWindowA(wc.lpszClassName, null, 0, 0, 0, 0, 0, null, null, null, null);
			if (!_mciNotifyHandleBGM) { mixin(S_TRACE);
				debugln("CreateWindow() failure");
			}
		}
		if (!_mciNotifyHandleSE) { mixin(S_TRACE);
			WNDCLASSA wc;
			wc.lpszClassName = "MCIHandlerSE\0".ptr;
			wc.lpfnWndProc = &mciNotifyWndProcSE;
			if (!RegisterClassA(&wc)) { mixin(S_TRACE);
				debugln("RegisterClass() failure");
				return;
			}
			_mciNotifyHandleSE = CreateWindowA(wc.lpszClassName, null, 0, 0, 0, 0, 0, null, null, null, null);
			if (!_mciNotifyHandleSE) { mixin(S_TRACE);
				debugln("CreateWindow() failure");
			}
		}
		version (Console) {
			debug std.stdio.writeln("Initialize winmm.dll End");
		}
	}
	private void disposeWinmm() { mixin(S_TRACE);
		if (!winmm) return;
		try { mixin(S_TRACE);
			version (Console) {
				debug std.stdio.writeln("Release winmm.dll Start");
			}
			dlclose(winmm);
			winmm = null;
			version (Console) {
				debug std.stdio.writeln("Release winmm.dll Exit");
			}
		} catch (Throwable e) {
			printStackTrace();
			debugln(e);
		}
	}
}
private void initSdl() { mixin(S_TRACE);
	if (sdl && mixer) return;
	disposeSound();
	version (Console) {
		debug std.stdio.writeln("Initialize SDL_mixer Start");
	}
	version (Windows) {
		version (Win64) {
			static immutable SDL = "SDL2.dll";
			static immutable MIXER = "SDL2_mixer.dll";
			static immutable DIR = "x64";
		} else {
			static immutable SDL = "SDL.dll";
			static immutable MIXER = "SDL_mixer.dll";
			static immutable DIR = "x86";
		}
		auto path = .environment.get("PATH", "");
		if (path != "") path ~= ";";
		path ~= thisExePath().dirName().buildPath(DIR);
		.environment["PATH"] = path;
	} else { mixin(S_TRACE);
		static immutable SDL = "libSDL2.so";
		static immutable MIXER = "libSDL2_mixer.so";
	}
	sdl = dlopen(SDL);
	mixer = dlopen(MIXER);
	if (sdl && mixer) { mixin(S_TRACE);
		try { mixin(S_TRACE);
			// FIXME: SDL2で必要
			//getSymbol!(SDL_SetMainReady)(sdl, "SDL_SetMainReady")();
			if (0 == getSymbol!(SDL_Init)(sdl, "SDL_Init")(SDL_INIT_AUDIO)) { mixin(S_TRACE);
				if (0 == getSymbol!(Mix_OpenAudio)(mixer, "Mix_OpenAudio")(SDL_FREQUENCY, SDL_FORMAT, SDL_CHANNELS, SDL_CHUNKSIZE)) { mixin(S_TRACE);
					if (0 < getSymbol!(Mix_AllocateChannels)(mixer, "Mix_AllocateChannels")(2)) { mixin(S_TRACE);
						if (0 != getSymbol!(Mix_QuerySpec)(mixer, "Mix_QuerySpec")(&sdl_frequency, &sdl_format, &sdl_channels)) { mixin(S_TRACE);
							version (Console) {
								debug std.stdio.writeln("Initialize SDL_mixer End");
							}
							return;
						}
					}
					getSymbol!(Mix_CloseAudio)(mixer, "Mix_CloseAudio")();
				}
				printSDLError();
				getSymbol!(SDL_Quit)(sdl, "SDL_Quit")();
			} else { mixin(S_TRACE);
				printSDLError();
			}
		} catch (Throwable e) {
			printStackTrace();
			debugln(e);
		}
	} else { mixin(S_TRACE);
		if (!sdl) debugln("not found: " ~ SDL);
		if (!mixer) debugln("not found: " ~ MIXER);
	}
	if (sdl) { mixin(S_TRACE);
		dlclose(sdl);
		sdl = null;
	}
	if (mixer) { mixin(S_TRACE);
		dlclose(mixer);
		mixer = null;
	}
	debugln("error: SDL_mixer initialize");
}

void disposeSdl() { mixin(S_TRACE);
	if (!sdl) return;
	try { mixin(S_TRACE);
		version (Console) {
			debug std.stdio.writeln("Release SDL_mixer Start");
		}
		try { mixin(S_TRACE);
			if (mixer) getSymbol!(Mix_CloseAudio)(mixer, "Mix_CloseAudio")();
			if (sdl) getSymbol!(SDL_Quit)(sdl, "SDL_Quit")();
		} catch (Exception e) {
			printStackTrace();
			debugln(e.msg);
		}
		if (mixer) { mixin(S_TRACE);
			dlclose(mixer);
			mixer = null;
		}
		if (sdl) { mixin(S_TRACE);
			dlclose(sdl);
			sdl = null;
		}
		version (Console) {
			debug std.stdio.writeln("Release SDL_mixer Exit");
		}
	} catch (Throwable e) {
		printStackTrace();
		debugln(e);
	}
}

/// 使用中の音声DLLを解放する。
void disposeSound() { mixin(S_TRACE);
	stopBGM();
	stopSE();
	disposeWinmm();
	disposeSdl();
	version (Windows) {
		disposeBass();
	}
}

shared static this () { mixin(S_TRACE);
	mutex = new Mutex;
	version (Windows) {
		winmmSync = new Mutex;
	}
}

private __gshared bool bgmOnLegacy = false;
private __gshared Mix_Music* bgmMusic = null;
private __gshared Mix_Chunk* bgmChunk = null;
private __gshared c_int bgmChannel = -1;
private __gshared clock_t bgmStart = 0;

private __gshared bool seOnLegacy = false;
private __gshared Mix_Music* seMusic = null;
private __gshared Mix_Chunk* seChunk = null;
private __gshared c_int seChannel = -1;
private __gshared clock_t seStart = 0;

private bool isPlaying(in Mix_Chunk* chunk, bool playingMCI, string mciName, HSTREAM bassStream) { mixin(S_TRACE);
	version (Windows) {
		if (bassStream) { mixin(S_TRACE);
			auto v = .getSymbol!(BASS_ChannelIsActive)(bass, "BASS_ChannelIsActive")(bassStream);
			return v !is BASS_ACTIVE_STOPPED;
		}
		if (playingMCI) { mixin(S_TRACE);
			wchar[1024] buf;
			_mciSendString(toUTFz!(wchar*)("status " ~ mciName ~ " mode\0"), buf.ptr, buf.length, null);
			return buf[0 .. wcslen(buf.ptr)] != "stopped"w;
		}
	}
	if (mixer) { mixin(S_TRACE);
		if (chunk) { mixin(S_TRACE);
			return true;
		}
		return .getSymbol!(Mix_PlayingMusic)(mixer, "Mix_PlayingMusic")() != 0;
	}
	return false;
}
private ulong pos(in Mix_Chunk* chunk, clock_t start, bool playingMCI, string mciName, HSTREAM bassStream) { mixin(S_TRACE);
	version (Windows) {
		if (bassStream) { mixin(S_TRACE);
			auto v = .getSymbol!(BASS_ChannelGetPosition)(bass, "BASS_ChannelGetPosition")(bassStream, BASS_POS_BYTE);
			if (0 <= v) { mixin(S_TRACE);
				auto sec = .getSymbol!(BASS_ChannelBytes2Seconds)(bass, "BASS_ChannelBytes2Seconds")(bassStream, v);
				if (0 <= sec) return to!ulong(sec * 1000.0);
			}
		}
		if (playingMCI) { mixin(S_TRACE);
			wchar[1024] len;
			_mciSendString(toUTFz!(wchar*)("status " ~ mciName ~ " position"), len.ptr, len.length, null);
			return to!ulong(len[0 .. wcslen(len.ptr)]);
		}
	}
	if (chunk) { mixin(S_TRACE);
		auto now = .clock();
		if (start < now) { mixin(S_TRACE);
			auto tim = now - start;
			return to!ulong(cast(real)tim / CLOCKS_PER_SEC * 1000.0) % len(chunk, playingMCI, mciName, bassStream);
		}
	}
	return 0;
}
private void setPos(in Mix_Chunk* chunk, bool playingMCI, string mciName, HSTREAM bassStream, ulong msecs, HWND mciHandler) { mixin(S_TRACE);
	version (Windows) {
		if (bassStream) { mixin(S_TRACE);
			auto pos = .getSymbol!(BASS_ChannelSeconds2Bytes)(bass, "BASS_ChannelSeconds2Bytes")(bassStream, msecs / 1000.0);
			if (0 <= pos) { mixin(S_TRACE);
				.getSymbol!(BASS_ChannelSetPosition)(bass, "BASS_ChannelSetPosition")(bassStream, pos, BASS_POS_BYTE);
			}
		}
		if (playingMCI) { mixin(S_TRACE);
			_mciSendString(toUTFz!(wchar*)("seek " ~ mciName ~ " to " ~ .text(msecs) ~ "\0"), null, 0, null);
			_mciSendString(toUTFz!(wchar*)("play " ~ mciName ~ " notify\0"), null, 0, mciHandler);
		}
	}
	if (chunk) { mixin(S_TRACE);
		getSymbol!(Mix_RewindMusic)(mixer, "Mix_RewindMusic")();
		getSymbol!(Mix_SetMusicPosition)(mixer, "Mix_SetMusicPosition")(msecs * 1000.0);
	}
}
private ulong len(in Mix_Chunk* chunk, bool playingMCI, string mciName, HSTREAM bassStream) { mixin(S_TRACE);
	version (Windows) {
		if (bassStream) { mixin(S_TRACE);
			auto v = getSymbol!(BASS_ChannelGetLength)(bass, "BASS_ChannelGetLength")(bassStream, BASS_POS_BYTE);
			if (0 <= v) { mixin(S_TRACE);
				auto sec = getSymbol!(BASS_ChannelBytes2Seconds)(bass, "BASS_ChannelBytes2Seconds")(bassStream, v);
				if (0 <= sec) return to!ulong(sec * 1000.0);
			}
		}
		if (playingMCI) { mixin(S_TRACE);
			wchar[1024] len;
			_mciSendString(toUTFz!(wchar*)("status " ~ mciName ~ " length"), len.ptr, len.length, null);
			return to!ulong(len[0 .. wcslen(len.ptr)]);
		}
	}
	if (chunk) { mixin(S_TRACE);
		auto bps = sdl_frequency * ((sdl_format & 0xFF) == 0x08 ? 1 : 2) * sdl_channels;
		return chunk.alen * 1000UL / bps;
	}
	return 0;
}

/// 現在再生中のBGMの再生位置(msecs)。
@property
ulong bgmPos() { mixin(S_TRACE);
	return pos(bgmChunk, bgmStart, _bgmPlayingMCI, CWBGM, bassBGMStream);
}
/// ditto
@property
void bgmPos(ulong pos) { mixin(S_TRACE);
	setPos(bgmChunk, _bgmPlayingMCI, CWBGM, bassBGMStream, pos, _mciNotifyHandleBGM);
	bgmVolume = _bgmVolume; // フェードイン中であればキャンセル
}
/// 現在再生中のBGMの再生時間(msecs)を取得する。
@property
ulong bgmLen() { mixin(S_TRACE);
	return len(bgmChunk, _bgmPlayingMCI, CWBGM, bassBGMStream);
}
/// 現在再生中の効果音の再生位置(msecs)。
@property
ulong sePos() { mixin(S_TRACE);
	return pos(seChunk, seStart, _sePlayingMCI, CWSE, bassSEStream);
}
/// ditto
@property
void sePos(ulong pos) { mixin(S_TRACE);
	setPos(seChunk, _sePlayingMCI, CWSE, bassSEStream, pos, _mciNotifyHandleSE);
	seVolume = _seVolume; // フェードイン中であればキャンセル
}
/// 現在再生中の効果音の再生時間(msecs)を取得する。
@property
ulong seLen() { mixin(S_TRACE);
	return len(seChunk, _sePlayingMCI, CWSE, bassSEStream);
}

/// BGMが再生中か。
@property
bool isBGMPlaying() { return isPlaying(bgmChunk, _bgmPlayingMCI, CWBGM, bassBGMStream); }

private void printSDLError(string File = __FILE__, int Line = __LINE__)() { mixin(S_TRACE);
	auto str = getSymbol!(SDL_GetError)(sdl, "SDL_GetError")();
	debugln!(File, Line)(str[0..strlen(str)]);
}

private void play(ref Mix_Music* music, ref Mix_Chunk* chunk, ref clock_t start, ref c_int channel, string mciName, ref bool onLegacy, ref bool playingMCI, string file, bool isBGM, uint loopCount, bool spLoop, int soundPlayType, uint volume, uint fadeIn, ref HSTREAM bassStream) { mixin(S_TRACE);
	stop(music, chunk, channel, mciName, onLegacy, playingMCI, bassStream);
	version (Windows) {
		if (SOUND_TYPE_BASS == soundPlayType) { mixin(S_TRACE);
			// BASSがロードされている場合はBASSで再生する
			initBass();
			if (playBass(file, loopCount, spLoop, bassStream, volume, fadeIn, mciName)) { mixin(S_TRACE);
				lastSoundType = soundPlayType;
				return;
			}
			// ここへ来たら再生失敗
		}
	}
	static immutable mciType = [".mid", ".midi", ".mp3", ".wav"];
	auto ext = file.extension().toLower();
	if (soundPlayType == SOUND_TYPE_MCI && !mciType.contains(ext)) { mixin(S_TRACE);
		soundPlayType = SOUND_TYPE_SDL;
	}
	try { mixin(S_TRACE);
		version (Windows) {
			if (SOUND_TYPE_MCI != soundPlayType) initSdl();
			if (SOUND_TYPE_MCI == soundPlayType || !sdl) { mixin(S_TRACE);
				initWinmm();
				winmmSync.lock();
				scope (exit) winmmSync.unlock();
				onLegacy = true;
				// typeにmpegvideoを指定するとリピート再生や音量の調節ができるが、
				// 一部環境でアプリケーションが丸ごと落ちる
				enforce(0 == _mciSendString(toUTFz!(wchar*)("open \"" ~ file ~ "\" alias " ~ mciName), null, 0, null),
					new Exception("MCI open: " ~ file));
/+				if (0 != _mciSendString(toUTFz!(wchar*)(.format("setaudio %s volume to %d", mciName, volume * 10)), null, 0, null)) { mixin(S_TRACE);
					debugln("error MCI setaudio");
				}
+/				_mciSendString(toUTFz!(wchar*)("set " ~ mciName ~ " time format milliseconds"), null, 0, null);
				string p = "play " ~ mciName;
				auto handler = isBGM ? _mciNotifyHandleBGM : _mciNotifyHandleSE;
				loopCounts[mciName] = loopCount;
				if (handler) { mixin(S_TRACE);
					p ~= " notify";
					enforce(0 == _mciSendString(toUTFz!(wchar*)(p), null, 0, handler),
						new Exception("MCI play: " ~ file));
				} else { mixin(S_TRACE);
					enforce(0 == _mciSendString(toUTFz!(wchar*)(p), null, 0, null),
						new Exception("MCI play: " ~ file));
				}
				playingMCI = true;
				lastSoundType = SOUND_TYPE_MCI;
				return;
			}
		} else {
			initSdl();
		}
	} catch (Exception e) {
		printStackTrace();
		debugln(e.msg);
	}
	onLegacy = false;
	try { mixin(S_TRACE);
		if (sdl) { mixin(S_TRACE);
			if (file.length > 0 && !music) { mixin(S_TRACE);
				const char* filez = (file ~ "\0").ptr;
				version (Windows) {
					const char* filez2 = toMBSz(file);
				}

				if (isBGM || isMidi(file) || file.extension() == ".mp3") { mixin(S_TRACE);
					music = getSymbol!(Mix_LoadMUS)(mixer, "Mix_LoadMUS")(filez);
					if (!music) { mixin(S_TRACE);
						debugln("error: Mix_LoadMUS, 1" ~ file);
						printSDLError();
						version (Windows) {
							// 別のエンコーディングで再トライ
							music = getSymbol!(Mix_LoadMUS)(mixer, "Mix_LoadMUS")(filez2);
						}
					}
					if (!music) { mixin(S_TRACE);
						debugln("error: Mix_LoadMUS, 2, " ~ file);
						printSDLError();
						return;
					}
					getSymbol!(Mix_VolumeMusic)(mixer, "Mix_VolumeMusic")(.roundTo!c_int((volume / 100.0) * MIX_MAX_VOLUME));
					if (0 != getSymbol!(Mix_FadeInMusic)(mixer, "Mix_FadeInMusic")(music, cast(int)loopCount - 1, fadeIn)) { mixin(S_TRACE);
						debugln("error: Mix_FadeInMusic, " ~ file);
						printSDLError();
						return;
					}
				} else { mixin(S_TRACE);
					auto ops = getSymbol!(SDL_RWFromFile)(sdl, "SDL_RWFromFile")(filez, "rb".toStringz());
					if (!ops) { mixin(S_TRACE);
						debugln("error: SDL_RWFromFile 1, " ~ file);
						printSDLError();
						version (Windows) {
							ops = getSymbol!(SDL_RWFromFile)(sdl, "SDL_RWFromFile")(filez2, "rb".toStringz());
						}
					}
					if (!ops) { mixin(S_TRACE);
						debugln("error: SDL_RWFromFile 2, " ~ file);
						printSDLError();
						return;
					}
					chunk = getSymbol!(Mix_LoadWAV_RW)(mixer, "Mix_LoadWAV_RW")(ops, 1);
					if (!chunk) { mixin(S_TRACE);
						debugln("error: Mix_LoadWAV_RW, " ~ file);
						printSDLError();
						return;
					}
					getSymbol!(Mix_VolumeChunk)(mixer, "Mix_VolumeChunk")(chunk, .roundTo!c_int((volume / 100.0) * MIX_MAX_VOLUME));
					channel = getSymbol!(Mix_FadeInChannelTimed)(mixer, "Mix_FadeInChannelTimed")(channel, chunk, cast(int)loopCount - 1, fadeIn, 0);
					if (-1 == channel) { mixin(S_TRACE);
						debugln("error: Mix_FadeInChannelTimed, " ~ file);
						printSDLError();
						return;
					}
				}
				start = .clock();
				lastSoundType = SOUND_TYPE_SDL;
			}
		}
	} catch (Exception e) {
		printStackTrace();
		debugln(e.msg);
	}
}

private void stop(ref Mix_Music* music, ref Mix_Chunk* chunk, ref c_int channel, string mciName, bool onLegacy, ref bool playingMCI, ref HSTREAM bassStream) { mixin(S_TRACE);
	try { mixin(S_TRACE);
		version (Windows) {
			stopBass(bassStream);
			if (onLegacy && playingMCI) { mixin(S_TRACE);
				winmmSync.lock();
				scope (exit) winmmSync.unlock();
				playingMCI = false;
				_mciSendString(toUTFz!(wchar*)("stop " ~ mciName), null, 0, null);
				_mciSendString(toUTFz!(wchar*)("close " ~ mciName), null, 0, null);
				return;
			}
		}
		if (sdl) { mixin(S_TRACE);
			if (music) { mixin(S_TRACE);
				if (0 == getSymbol!(Mix_HaltMusic)(mixer, "Mix_HaltMusic")()) { mixin(S_TRACE);
					getSymbol!(Mix_FreeMusic)(mixer, "Mix_FreeMusic")(music);
					music = null;
				} else { mixin(S_TRACE);
					debugln("error: Mix_HaltMusic");
					printSDLError();
				}
			}
			if (-1 != channel) { mixin(S_TRACE);
				getSymbol!(Mix_HaltChannel)(mixer, "Mix_HaltChannel")(channel);
				channel = -1;
			}
			if (chunk) { mixin(S_TRACE);
				getSymbol!(Mix_FreeChunk)(mixer, "Mix_FreeChunk")(chunk);
				chunk = null;
			}
		}
	} catch (Exception e) {
		printStackTrace();
		debugln(e.msg);
	}
}

__gshared void delegate()[] stopBGMEvent;
__gshared void delegate()[] stopSEEvent;

/// 最後に選択された音声再生方式。
version (Windows) {
	__gshared int lastSoundType = SOUND_TYPE_MCI;
} else {
	__gshared int lastSoundType = SOUND_TYPE_SDL;
}

/// 指定されたディレクトリにあるBASSのDLLをロードし、初期化する。
bool initBass(string bassDir, in string[] bassSoundFonts) { mixin(S_TRACE);
	_initBassDir = bassDir;
	_initBassSFont = bassSoundFonts.dup;
	disposeBass();
	return _initBassDir.buildPath("bass.dll").exists() && _initBassDir.buildPath("bassmidi.dll").exists();
}

private void initBass() { mixin(S_TRACE);
	if (bass) return;
	version (Windows) {
		version (Console) {
			debug std.stdio.writeln("Initialize BASS Audio Start");
		}
		disposeSound();
		if (!_initBassSFont.length) return;
		mutex.lock();
		scope (exit) mutex.unlock();
		try { mixin(S_TRACE);
			bass = dlopen(_initBassDir.buildPath("bass.dll"));
			if (!bass) { mixin(S_TRACE);
				bass = dlopen("bass.dll");
				if (!bass) { mixin(S_TRACE);
					disposeBass();
					return;
				}
			}
			// 読込失敗でも続行
			bassMidi = dlopen(_initBassDir.buildPath("bassmidi.dll"));
			if (!bassMidi) { mixin(S_TRACE);
				bassMidi = dlopen("bassmidi.dll");
				if (!bassMidi) { mixin(S_TRACE);
					disposeBass();
					return;
				}
			}
			if (!getSymbol!(BASS_Init)(bass, "BASS_Init")(-1, 44100, BASS_DEVICE_DEFAULT, null, null)) { mixin(S_TRACE);
				disposeBass();
				return;
			}
			if (!loadBassSoundFont(_initBassSFont)) { mixin(S_TRACE);
				disposeBass();
				return;
			}
			set_BASS_ChannelSetPosition(getSymbol!(BASS_ChannelSetPosition)(bass, "BASS_ChannelSetPosition"));

		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
		version (Console) {
			debug std.stdio.writeln("Initialize BASS Audio End");
		}
	}
}
/// BASSのMIDI再生で使用するサウンドフォントを変更する。
private bool loadBassSoundFont(in string[] soundFonts) { mixin(S_TRACE);
	version (Windows) {
		try { mixin(S_TRACE);
			if (!bassMidi) return false;
			releaseBassSoundFont();
			foreach (soundFont; soundFonts) { mixin(S_TRACE);
				auto sfont = getSymbol!(BASS_MIDI_FontInit)(bassMidi, "BASS_MIDI_FontInit")(soundFont.toMBSz(), 0);
				if (!sfont) continue;
				.soundFonts ~= BASS_MIDI_FONT(sfont, -1, 0);
			}
			return 0 < .soundFonts.length;
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
	return false;
}
private void releaseBassSoundFont() { mixin(S_TRACE);
	version (Windows) {
		if (!bassMidi) return;
		try { mixin(S_TRACE);
			foreach (sf; soundFonts) { mixin(S_TRACE);
				if (!getSymbol!(BASS_MIDI_FontFree)(bassMidi, "BASS_MIDI_FontFree")(sf.font)) { mixin(S_TRACE);
					debugln("BASS_MIDI_FontFree error");
				}
			}
			soundFonts = [];
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
}
/// BASSのサウンドフォントとDLLを解放する。
private void disposeBass() { mixin(S_TRACE);
	if (!bass) return;
	version (Console) {
		debug std.stdio.writeln("Release BASS Audio Start");
	}
	mutex.lock();
	scope (exit) mutex.unlock();
	version (Windows) {
		try { mixin(S_TRACE);
			stopBGM();
			stopSE();
			set_BASS_ChannelSetPosition(null);
			if (bassMidi) { mixin(S_TRACE);
				releaseBassSoundFont();
				dlclose(bassMidi);
				bassMidi = null;
			}
			if (bass) { mixin(S_TRACE);
				if (!getSymbol!(BASS_Free)(bass, "BASS_Free")())  { mixin(S_TRACE);
					debugln("BASS_Free");
				}
				dlclose(bass);
				bass = null;
			}
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
	version (Console) {
		debug std.stdio.writeln("Release BASS Audio End");
	}
}

// BASS関係
version (Windows) {
	private __gshared void* bass = null;
	private __gshared void* bassMidi = null;
	private __gshared BASS_MIDI_FONT[] soundFonts = [];
	private __gshared HSTREAM bassBGMStream = 0;
	private __gshared HSTREAM bassSEStream = 0;
	private __gshared _initBassDir = "";
	private __gshared const(string)[] _initBassSFont = [];
	private __gshared uint[string] loopCounts;
	private __gshared ptrdiff_t[string] loopStarts;

	private __gshared ptrdiff_t[2] loopEnds;
	// FIXME: GCが動くとbassLoopコールバックでアクセス違反。
	//        GCを無効にする事で対策できるが、確実にメモリ不足に陥る。
	//        Cのオブジェクト上にループ処理を配置する事で問題を回避する。
	private __gshared extern (C) void setLoopStart(size_t index, ulong loopStart);
	private __gshared extern (C) void setLoopCount(size_t index, uint loopCount);
	private __gshared extern (C) void set_BASS_ChannelSetPosition(BASS_ChannelSetPosition func);
	private __gshared extern (Windows) void bassLoop(HSYNC handle, DWORD channel, DWORD data, void* user);
/+	private __gshared extern (Windows) void bassLoop(HSYNC handle, DWORD channel, DWORD data, void* user) {
		assert (_BASS_ChannelSetPosition !is null);
		auto loopKey = fromStringz(cast(immutable(char)*)user);
		auto pos = loopStarts[loopKey];
		auto loops = loopCounts[loopKey];
		if (loops != 1) { mixin(S_TRACE);
			if (0 < loops) loopCounts[loopKey] = loops - 1;
			_BASS_ChannelSetPosition(channel, pos, BASS_POS_BYTE);
		} else { mixin(S_TRACE);
			//core.memory.GC.enable();
		}
	}
+/
}

/// fileがMIDIファイルであればtrue。
bool isMidi(string file) { mixin(S_TRACE);
	return file.exists() && cast(char[])std.file.read(file, 4) == "MThd";
}

private bool playBass(string file, uint loopCount, bool spLoop, ref DWORD stream, uint volume, uint fadeIn, string loopKey) { mixin(S_TRACE);
	version (Windows) {
		try { mixin(S_TRACE);
			if (!bass) return false;
			stopBass(stream);
			if (!.canPlayBass(file)) { mixin(S_TRACE);
				return false;
			}
			bool midi = isMidi(file);
			int flag = BASS_MUSIC_STOPBACK | BASS_MUSIC_POSRESET | BASS_MUSIC_PRESCAN;
			if (midi) { mixin(S_TRACE);
				stream = getSymbol!(BASS_MIDI_StreamCreateFile)(bassMidi, "BASS_MIDI_StreamCreateFile")(false, file.toMBSz(), 0, 0, flag, 44100);
				if (!stream) { mixin(S_TRACE);
					debugln("error: BASS_MIDI_StreamCreateFile 1, " ~ file);
					stream = getSymbol!(BASS_MIDI_StreamCreateFile)(bassMidi, "BASS_MIDI_StreamCreateFile")(false, file.toStringz(), 0, 0, flag, 44100);
				}
				if (!stream) { mixin(S_TRACE);
					debugln("error: BASS_MIDI_StreamCreateFile 2, " ~ file);
				}
			} else { mixin(S_TRACE);
				stream = getSymbol!(BASS_StreamCreateFile)(bass, "BASS_StreamCreateFile")(false, file.toMBSz(), 0, 0, flag);
				if (!stream) { mixin(S_TRACE);
					debugln("error: BASS_StreamCreateFile 1, " ~ file);
					stream = getSymbol!(BASS_StreamCreateFile)(bass, "BASS_StreamCreateFile")(false, file.toStringz(), 0, 0, flag);
				}
				if (!stream) { mixin(S_TRACE);
					debugln("error: BASS_StreamCreateFile 2, " ~ file);
				}
			}
			if (!stream) return false;
			if (midi) { mixin(S_TRACE);
				if (!getSymbol!(BASS_MIDI_StreamSetFonts)(bassMidi, "BASS_MIDI_StreamSetFonts")(stream, soundFonts.ptr, cast(c_int)soundFonts.length)) { mixin(S_TRACE);
					stopBass(stream);
					return false;
				}
			}

			// 任意位置ループ
			ptrdiff_t loopStart = -1, loopEnd = -1;
			if (spLoop) getLoopInfo(file, midi, stream, loopStart, loopEnd);
			auto BASS_ChannelSetSync = getSymbol!(BASS_ChannelSetSync)(bass, "BASS_ChannelSetSync");

			size_t loopIndex = 0;
			switch (loopKey) {
			case "cwbgm": loopIndex = 0; break;
			case "cwse": loopIndex = 1; break;
			default: throw new Exception("Invalid loop key: " ~ loopKey);
			}
			setLoopCount(loopIndex, loopCount);

			//core.memory.GC.disable();
			if (loopStart != -1 && loopEnd != -1) { mixin(S_TRACE);
				setLoopStart(loopIndex, loopStart);
				loopEnds[loopIndex] = loopEnd;
				BASS_ChannelSetSync(stream, BASS_SYNC_POS | BASS_SYNC_MIXTIME, loopEnd, &bassLoop, cast(void*)loopIndex);
				BASS_ChannelSetSync(stream, BASS_SYNC_END | BASS_SYNC_MIXTIME, 0, &bassLoop, cast(void*)loopIndex);
			} else if (loopStart != -1) { mixin(S_TRACE);
				setLoopStart(loopIndex, loopStart);
				loopEnds[loopIndex] = -1;
				BASS_ChannelSetSync(stream, BASS_SYNC_END | BASS_SYNC_MIXTIME, 0, &bassLoop, cast(void*)loopIndex);
			} else { mixin(S_TRACE);
				setLoopStart(loopIndex, 0);
				loopEnds[loopIndex] = -1;
				BASS_ChannelSetSync(stream, BASS_SYNC_END | BASS_SYNC_MIXTIME, 0, &bassLoop, cast(void*)loopIndex);
			}

			volume = .min(100, volume);
			if (0 < fadeIn) {
				if (!getSymbol!(BASS_ChannelSetAttribute)(bass, "BASS_ChannelSetAttribute")(stream, BASS_ATTRIB_VOL, 0)) { mixin(S_TRACE);
					debugln("BASS_ChannelSetAttribute");
				}
				if (!getSymbol!(BASS_ChannelSlideAttribute)(bass, "BASS_ChannelSlideAttribute")(stream, BASS_ATTRIB_VOL, volume / 100.0F, fadeIn)) { mixin(S_TRACE);
					debugln("BASS_ChannelSlideAttribute");
				}
			} else {
				if (!getSymbol!(BASS_ChannelSetAttribute)(bass, "BASS_ChannelSetAttribute")(stream, BASS_ATTRIB_VOL, volume / 100.0F)) { mixin(S_TRACE);
					debugln("BASS_ChannelSetAttribute");
				}
			}
			if (!getSymbol!(BASS_ChannelPlay)(bass, "BASS_ChannelPlay")(stream, false)) { mixin(S_TRACE);
				stopBass(stream);
				return false;
			}
			return true;
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
	return false;
}
private void getLoopInfo(string file, bool midi, HSTREAM stream, out ptrdiff_t loopStart, out ptrdiff_t loopEnd) { mixin(S_TRACE);
	loopStart = -1;
	loopEnd = -1;

	BASS_CHANNELINFO info;
	if (!getSymbol!(BASS_ChannelGetInfo)(bass, "BASS_ChannelGetInfo")(stream, &info)) { mixin(S_TRACE);
		return;
	}
	auto sampPerBytes = 44100.0 / info.freq;
	auto sampToBytes = info.chans;
	if (info.flags & BASS_SAMPLE_FLOAT) {
		sampToBytes *= 4;
	} else if (info.flags & BASS_SAMPLE_8BITS) {
		sampToBytes *= 1;
	} else {
		sampToBytes *= 2;
	}
	ptrdiff_t posToBytes(ptrdiff_t pos) { mixin(S_TRACE);
		return cast(ptrdiff_t)((pos / sampPerBytes) * sampToBytes);
	}

	// 吉里吉里形式(*.sliファイル)によってループ位置を指定する
	auto sli = file ~ ".sli";
	if (sli.exists() && sli.isFile()) { mixin(S_TRACE);
		foreach (line; std.file.readText(sli).splitLines()) { mixin(S_TRACE);
			line = line.strip();
			if (line == "" || line.startsWith("#")) continue;
			if (!line.startsWith("Link")) continue;
			line = line["Link".length .. $];
			auto start = line.indexOf("{");
			auto end = line.lastIndexOf("}");
			if (start == -1 || end == -1 || end < start) continue;
			line = line[start + 1 .. end];
			auto secs = line.split(";");
			foreach (sec; secs) { mixin(S_TRACE);
				auto keyValue = sec.split("=");
				if (keyValue.length < 2) continue;
				if (keyValue[0].strip() == "From") { mixin(S_TRACE);
					loopEnd = posToBytes(keyValue[1].to!ptrdiff_t());
				} else if (keyValue[0].strip() == "To") { mixin(S_TRACE);
					loopStart = posToBytes(keyValue[1].to!ptrdiff_t());
				}
			}
			if (0 <= loopStart) return;
		}
	}

	if (midi) { mixin(S_TRACE);
		// RPGツクールのMIDI拡張イベント(CC#111)によってループ位置を指定する
		auto BASS_MIDI_StreamGetEvents = getSymbol!(BASS_MIDI_StreamGetEvents)(bassMidi, "BASS_MIDI_StreamGetEvents");
		auto count = BASS_MIDI_StreamGetEvents(stream, -1, MIDI_EVENT_CONTROL, null);
		if (count) { mixin(S_TRACE);
			auto events = new BASS_MIDI_EVENT[count];
			count = BASS_MIDI_StreamGetEvents(stream, -1, MIDI_EVENT_CONTROL, events.ptr);
			foreach (i; 0 .. count) { mixin(S_TRACE);
				if ((events[i].param & 0xFF) == 111) { mixin(S_TRACE);
					loopStart = events[i].pos;
					loopEnd = -1;
				}
			}
		}
	}

	// RPGツクールVXのOgg Vorbisコメント埋め込み形式によってループ位置を指定する
	auto comments = getSymbol!(BASS_ChannelGetTags)(bass, "BASS_ChannelGetTags")(stream, BASS_TAG_OGG);
	if (comments) { mixin(S_TRACE);
		ptrdiff_t loopLength = -1;
		while (*comments) { mixin(S_TRACE);
			auto comment = fromStringz(comments);
			auto keyValue = comment.split("=");
			if (keyValue[0].strip() == "LOOPSTART") { mixin(S_TRACE);
				loopStart = keyValue[1].to!ptrdiff_t();
			} else if (keyValue[0].strip() == "LOOPLENGTH") { mixin(S_TRACE);
				loopLength = keyValue[1].to!ptrdiff_t();
			}
			comments += comment.length + 1;
		}
		if (0 <= loopStart) { mixin(S_TRACE);
			loopEnd = posToBytes(loopLength + loopStart);
			loopStart = posToBytes(loopStart);
			return;
		}
	}
}

private void stopBass(ref DWORD stream) { mixin(S_TRACE);
	//core.memory.GC.enable();
	version (Windows) {
		try { mixin(S_TRACE);
			if (!bass) return;
			if (!stream) return;
			if (!getSymbol!(BASS_ChannelStop)(bass, "BASS_ChannelStop")(stream)) { mixin(S_TRACE);
				debugln("BASS_ChannelStop");
			}
			if (!getSymbol!(BASS_StreamFree)(bass, "BASS_StreamFree")(stream)) { mixin(S_TRACE);
				debugln("BASS_StreamFree");
			}
			stream = 0;
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
}

version (Windows) {
	private extern (Windows) {
		struct GUID {
			DWORD Data1;
			WORD Data2;
			WORD Data3;
			BYTE[8] Data4;
		}
		struct BASS_MIDI_FONT {
			HSOUNDFONT font;
			c_int preset;
			c_int bank;
		}
		alias DWORD HSTREAM;
		alias DWORD HSOUNDFONT;
		alias DWORD HSYNC;
		alias DWORD HPLUGIN;
		alias DWORD HSAMPLE;
		alias ulong QWORD;
		immutable BASS_DEVICE_DEFAULT = 0;
		immutable BASS_DEVICE_8BITS = 1;
		immutable BASS_DEVICE_MONO = 2;
		immutable BASS_DEVICE_3D = 4;
		immutable BASS_DEFAULT = 0;
		immutable BASS_SAMPLE_LOOP = 4;
		immutable BASS_ATTRIB_VOL = 2;
		immutable BASS_FILEPOS_CURRENT = 0;
		immutable BASS_FILEPOS_END = 2;
		immutable BASS_POS_BYTE = 0;
		immutable BASS_SYNC_POS = 0;
		immutable BASS_SYNC_END = 2;
		immutable BASS_SYNC_MUSICPOS = 10;
		immutable BASS_SYNC_MIXTIME = 0x40000000;
		immutable BASS_TAG_OGG = 2;
		immutable MIDI_EVENT_CONTROL = 64;
		immutable BASS_SAMPLE_8BITS = 1;
		immutable BASS_SAMPLE_FLOAT = 256;
		immutable BASS_ACTIVE_STOPPED = 0;
		immutable BASS_MUSIC_RAMP = 0x200;
		immutable BASS_MUSIC_RAMPS = 0x400;
		immutable BASS_MUSIC_POSRESET = 0x8000;
		immutable BASS_MUSIC_PRESCAN = 0x20000;
		immutable BASS_MUSIC_STOPBACK = 0x80000;
		immutable BASS_STREAM_DECODE = 0x200000;
		struct  BASS_MIDI_EVENT {
			DWORD event;
			DWORD param;
			DWORD chan;
			DWORD tick;
			DWORD pos;
		}
		struct BASS_CHANNELINFO {
			DWORD freq;
			DWORD chans;
			DWORD flags;
			DWORD ctype;
			DWORD origres;
			HPLUGIN plugin;
			HSAMPLE sample;
			char* filename;
		}
		alias BOOL function(HSTREAM handle, BASS_MIDI_FONT *fonts, DWORD count) BASS_MIDI_StreamSetFonts;
		alias HSOUNDFONT function(const void *file, DWORD flags) BASS_MIDI_FontInit;
		alias BOOL function(HSOUNDFONT handle) BASS_MIDI_FontFree;
		alias BOOL function(int device, DWORD freq, DWORD flags, HWND win, GUID* clsid) BASS_Init;
		alias BOOL function(DWORD handle, BOOL restart) BASS_ChannelPlay;
		alias BOOL function(DWORD handle) BASS_ChannelStop;
		alias HSTREAM function(BOOL mem, const void* file, QWORD offset, QWORD length, DWORD flags) BASS_StreamCreateFile;
		alias BOOL function(HSTREAM handle) BASS_StreamFree;
		alias BOOL function() BASS_Free;
		alias HSTREAM function(BOOL mem, const void* file, QWORD offset, QWORD length, DWORD flags, DWORD freq) BASS_MIDI_StreamCreateFile;
		alias BOOL function(float volume) BASS_SetVolume;
		alias BOOL function(DWORD handle, DWORD attrib, float value) BASS_ChannelSetAttribute;
		alias BOOL function(DWORD handle, DWORD attrib, float value, DWORD time) BASS_ChannelSlideAttribute;
		alias DWORD function(HSTREAM handle, int track, DWORD filter, BASS_MIDI_EVENT* events) BASS_MIDI_StreamGetEvents;
		alias HSYNC function(DWORD handle, DWORD type, QWORD param, SYNCPROC proc, void* user) BASS_ChannelSetSync;
		alias void function(HSYNC handle, DWORD channel, DWORD data, void* user) SYNCPROC;
		alias char* function(DWORD handle, DWORD tags) BASS_ChannelGetTags;
		alias BOOL function(DWORD handle, BASS_CHANNELINFO* info) BASS_ChannelGetInfo;

		alias QWORD function(HSTREAM handle, DWORD mode) BASS_ChannelGetLength;
		alias QWORD function(HSTREAM handle, DWORD mode) BASS_ChannelGetPosition;
		alias BOOL function(HSTREAM handle, QWORD pos, DWORD mode) BASS_ChannelSetPosition;
		alias c_double function(HSTREAM handle, QWORD pos) BASS_ChannelBytes2Seconds;
		alias QWORD function(HSTREAM handle, c_double pos) BASS_ChannelSeconds2Bytes;
		alias DWORD function(DWORD handle) BASS_ChannelIsActive;
	}
} else {
	private alias c_int HSTREAM;
}

/// BASSを使用する状態であればtrue。
@property
bool useBass() { mixin(S_TRACE);
	version (Windows) {
		if (!mutex) return false;
		mutex.lock();
		scope (exit) mutex.unlock();
		return bass !is null;
	}
	return false;
}
/// BASSでfileを再生できる状態であればtrue。
bool canPlayBass(string file) { mixin(S_TRACE);
	version (Windows) {
		if (!mutex) return false;
		if (!_initBassSFont.length) return false;
		mutex.lock();
		scope (exit) mutex.unlock();
		initBass();
		return .useBass && (isMidi(file) ? (bassMidi && soundFonts.length) : true);
	}
	return false;
}

/// BGMを再生する。
void playBGM(string path, uint fadeIn, uint loopCount, int soundPlayType, bool spLoop) { mixin(S_TRACE);
	if (!mutex) return;
	try { mixin(S_TRACE);
		mutex.lock();
		scope (exit) mutex.unlock();
		version (Windows) {
			HSTREAM bass = bassBGMStream;
			scope (exit) bassBGMStream = bass;
		} else { mixin(S_TRACE);
			HSTREAM bass = 0;
		}
		play(bgmMusic, bgmChunk, bgmStart, bgmChannel, CWBGM, bgmOnLegacy, _bgmPlayingMCI, path, true, loopCount, spLoop, soundPlayType, _bgmVolume, fadeIn, bass);
	} catch (Throwable e) {
		printStackTrace();
		debugln(e);
	}
}

/// BGMを停止する。
void stopBGM() { mixin(S_TRACE);
	if (!mutex) return;
	try { mixin(S_TRACE);
		mutex.lock();
		scope (exit) mutex.unlock();
		version (Windows) {
			HSTREAM bass = bassBGMStream;
			scope (exit) bassBGMStream = bass;
		} else { mixin(S_TRACE);
			HSTREAM bass = 0;
		}
		stop(bgmMusic, bgmChunk, bgmChannel, CWBGM, bgmOnLegacy, _bgmPlayingMCI, bass);
	} catch (Throwable e) {
		printStackTrace();
		debugln(e);
	}
	if (inStopBGM) return;
	inStopBGM = true;
	scope (exit) inStopBGM = false;
	foreach (dlg; stopBGMEvent) { mixin(S_TRACE);
		dlg();
	}
}
private __gshared inStopBGM = false;

/// BGMの音量(%)を設定する。
@property
void bgmVolume(uint volume) { mixin(S_TRACE);
	if (!mutex) return;
	mutex.lock();
	scope (exit) mutex.unlock();
	_bgmVolume = .min(volume, 100);
	if (mixer) { mixin(S_TRACE);
		auto sdlvol = .roundTo!c_int((_bgmVolume / 100.0) * MIX_MAX_VOLUME);
		getSymbol!(Mix_VolumeMusic)(mixer, "Mix_VolumeMusic")(sdlvol);
	}
	version (Windows) {
		if (bassBGMStream) { mixin(S_TRACE);
			if (!getSymbol!(BASS_ChannelSlideAttribute)(bass, "BASS_ChannelSlideAttribute")(bassBGMStream, BASS_ATTRIB_VOL, _bgmVolume / 100.0F, 0)) { mixin(S_TRACE);
				debugln("BASS_ChannelSlideAttribute");
			}
		}
/+		if (_mciSendString) { mixin(S_TRACE);
			winmmSync.lock();
			scope (exit) winmmSync.unlock();
			if (0 != _mciSendString(toUTFz!(wchar*)(.format("setaudio %s volume to %d", CWBGM, _bgmVolume * 10)), null, 0, null)) { mixin(S_TRACE);
				debugln("error MCI setaudio");
			}
		}
+/	}
}

/// 効果音を再生する。
void playSE(string path, uint fadeIn, uint loopCount, int soundPlayType, bool spLoop) { mixin(S_TRACE);
	if (!mutex) return;
	try { mixin(S_TRACE);
		mutex.lock();
		scope (exit) mutex.unlock();
		version (Windows) {
			HSTREAM bass = bassSEStream;
			scope (exit) bassSEStream = bass;
		} else { mixin(S_TRACE);
			HSTREAM bass = 0;
		}
		play(seMusic, seChunk, seStart, seChannel, CWSE, seOnLegacy, _sePlayingMCI, path, false, loopCount, spLoop, soundPlayType, _seVolume, fadeIn, bass);
	} catch (Throwable e) {
		printStackTrace();
		debugln(e);
	}
}

/// 効果音を停止する。
void stopSE() { mixin(S_TRACE);
	if (!mutex) return;
	try { mixin(S_TRACE);
		mutex.lock();
		scope (exit) mutex.unlock();
		version (Windows) {
			HSTREAM bass = bassSEStream;
			scope (exit) bassSEStream = bass;
		} else { mixin(S_TRACE);
			HSTREAM bass = 0;
		}
		stop(seMusic, seChunk, seChannel, CWSE, seOnLegacy, _sePlayingMCI, bass);
	} catch (Throwable e) {
		printStackTrace();
		debugln(e);
	}
	if (inStopSE) return;
	inStopSE = true;
	scope (exit) inStopSE = false;
	foreach (dlg; stopSEEvent) { mixin(S_TRACE);
		dlg();
	}
}
private __gshared inStopSE = false;

/// 効果音の音量(%)を設定する。
@property
void seVolume(uint volume) { mixin(S_TRACE);
	if (!mutex) return;
	mutex.lock();
	scope (exit) mutex.unlock();
	_seVolume = .min(volume, 100);
	if (mixer && -1 != seChannel) { mixin(S_TRACE);
		auto sdlvol =.roundTo!c_int((_seVolume / 100.0) * MIX_MAX_VOLUME);
		getSymbol!(Mix_Volume)(mixer, "Mix_Volume")(seChannel, sdlvol);
	}
	version (Windows) {
		if (bassSEStream) { mixin(S_TRACE);
			if (!getSymbol!(BASS_ChannelSlideAttribute)(bass, "BASS_ChannelSlideAttribute")(bassSEStream, BASS_ATTRIB_VOL, _seVolume / 100.0F, 0)) { mixin(S_TRACE);
				debugln("BASS_ChannelSlideAttribute");
			}
		}
/+		if (_mciSendString) { mixin(S_TRACE);
			winmmSync.lock();
			scope (exit) winmmSync.unlock();
			if (0 != _mciSendString(toUTFz!(wchar*)(.format("setaudio %s volume to %d", CWSE, _seVolume * 10)), null, 0, null)) { mixin(S_TRACE);
				debugln("error MCI setaudio");
			}
		}
+/	}
}
