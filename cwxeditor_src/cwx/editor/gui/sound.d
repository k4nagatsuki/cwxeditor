
module cwx.editor.gui.sound;

import std.algorithm : min;
import std.utf;
import std.stdint;
import std.string;
import std.conv;
import std.path;
import std.exception;
import std.file;
import std.process : environment;
import std.c.stdio;
import std.c.string;

import core.sync.mutex;
import core.stdc.wchar_;

import cwx.utils;

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

version (Windows) {
	import std.windows.charset;
	import std.c.windows.windows;
	private extern (Windows) {
		alias __gshared DWORD MCIERROR;
		alias __gshared nothrow MCIERROR function(LPCWSTR, LPWSTR, UINT, HANDLE) mciSendStringW;
	}
	private const __gshared MCI_NOTIFY_SUCCESSFUL = 0x0001;
	private const __gshared MM_MCINOTIFY = 0x03B9;
	/// playBGM()は_mciNotifyHandleに設定されたウィンドウに対して
	/// 再生イベントを通知する。
	private HWND _mciNotifyHandle = null;
	/// ditto
	nothrow
	private extern (Windows) LRESULT mciNotifyWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
		if (!_mciNotifyHandle || !winmm || !_mciSendString || !_bgmPlayingMCI || MM_MCINOTIFY != message || MCI_NOTIFY_SUCCESSFUL != wParam) {
			return DefWindowProcW(hWnd, message, wParam, lParam);
		}
		static const __gshared SEEK = "seek cws to 0\0"w.ptr;
		static const __gshared PLAY = "play cws notify\0"w.ptr;
		_mciSendString(SEEK, null, 0, null);
		_mciSendString(PLAY, null, 0, _mciNotifyHandle);
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
	alias c_int function(c_int channel, Mix_Chunk *chunk, c_int loops, c_int ticks) Mix_PlayChannelTimed;
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
		synchronized {
			if (winmm) return;
			winmmSync = new Mutex;
			winmm = dlopen("winmm.dll");
		}
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
		WNDCLASS wc;
		wc.lpszClassName = "MCIHandler\0".ptr;
		wc.lpfnWndProc = &mciNotifyWndProc;
		if (!RegisterClassA(&wc)) { mixin(S_TRACE);
			debugln("RegisterClass() failure");
			return;
		}
		_mciNotifyHandle = CreateWindowA(wc.lpszClassName, null, 0, 0, 0, 0, 0, null, null, null, null);
		if (!_mciNotifyHandle) { mixin(S_TRACE);
			debugln("CreateWindow() failure");
		}
	}
}
private void initSdl() { mixin(S_TRACE);
	if (sdl && mixer) return;
	version (Windows) {
		version (Win64) {
			static __gshared const SDL = "SDL2.dll";
			static __gshared const MIXER = "SDL2_mixer.dll";
			auto path = .environment.get("PATH", "");
			if (path != "") path ~= ";";
			path ~= thisExePath().dirName().buildPath("x64");
			.environment["PATH"] = path;
		} else {
			static __gshared const SDL = "SDL.dll";
			static __gshared const MIXER = "SDL_mixer.dll";
		}
	} else { mixin(S_TRACE);
		static __gshared const SDL = "libSDL2.so";
		static __gshared const MIXER = "libSDL2_mixer.so";
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
void initSound() { mixin(S_TRACE);
	try { mixin(S_TRACE);
		synchronized {
			if (!mutex) mutex = new Mutex;
		}
		version (Windows) {
			initWinmm();
		}
		initSdl();
	} catch (Throwable e) {
		printStackTrace();
		debugln(e);
	}
}

shared static ~this () { mixin(S_TRACE);
	try { mixin(S_TRACE);
		version (Console) {
			debug std.stdio.writeln("Release DLLs for sound Start");
		}
		if (sdl) { mixin(S_TRACE);
			// FIXME: WindowsでVirtualMIDISynthを使用していると以下の二件の
			//        呼び出しで停止するため、システムに任せる
			version (Windows) {} else {
				try { mixin(S_TRACE);
					if (mixer) getSymbol!(Mix_CloseAudio)(mixer, "Mix_CloseAudio")();
					if (sdl) getSymbol!(SDL_Quit)(sdl, "SDL_Quit")();
				} catch (Exception e) {
					printStackTrace();
					debugln(e.msg);
				}
				if (mixer) dlclose(mixer);
				if (sdl) dlclose(sdl);
			}
		}
		version (Windows) {
			if (winmm) { mixin(S_TRACE);
				dlclose(winmm);
			}
		}
		disposeBass();
		version (Console) {
			debug std.stdio.writeln("Release DLLs for sound Exit");
		}
	} catch (Throwable e) {
		printStackTrace();
		debugln(e);
	}
}

private __gshared bool bgmOnLegacy = false;
private __gshared Mix_Music* bgmMusic = null;
private __gshared Mix_Chunk* bgmChunk = null;
private __gshared c_int bgmChannel = -1;

private __gshared bool seOnLegacy = false;
private __gshared Mix_Music* seMusic = null;
private __gshared Mix_Chunk* seChunk = null;
private __gshared c_int seChannel = -1;

private ulong pos(in Mix_Chunk* chunk, bool playingMCI, string mciName, HSTREAM bassStream) { mixin(S_TRACE);
	version (Windows) {
		if (bassStream) { mixin(S_TRACE);
			return _BASS_StreamGetFilePosition(bassStream, BASS_FILEPOS_CURRENT);
		}
		if (playingMCI) { mixin(S_TRACE);
			wchar[1024] len;
			_mciSendString(toUTFz!(wchar*)("status " ~ mciName ~ " position"), len.ptr, len.length, null);
			return to!ulong(len[0 .. wcslen(len.ptr)]);
		}
		if (chunk) { mixin(S_TRACE);
			// TODO
		}
	}
	return 0;
}
private ulong len(in Mix_Chunk* chunk, bool playingMCI, string mciName, HSTREAM bassStream) { mixin(S_TRACE);
	version (Windows) {
		if (bassStream) { mixin(S_TRACE);
			return _BASS_StreamGetFilePosition(bassStream, BASS_FILEPOS_END);
		}
		if (playingMCI) { mixin(S_TRACE);
			wchar[1024] len;
			_mciSendString(toUTFz!(wchar*)("status " ~ mciName ~ " length"), len.ptr, len.length, null);
			return to!ulong(len[0 .. wcslen(len.ptr)]);
		}
		if (chunk) { mixin(S_TRACE);
			auto bps = sdl_frequency * ((sdl_format & 0xFF) == 0x08 ? 1 : 2) * sdl_channels;
			return chunk.alen * 1000UL / bps;
		}
	}
	return 0;
}

/// 現在再生中のBGMの再生位置(msecs)を取得する。
@property
ulong bgmPos() { mixin(S_TRACE);
	version (Windows) {
		return pos(bgmChunk, _bgmPlayingMCI, "cwbgm", bassBGMStream);
	} else {
		return 0;
	}
}
/// 現在再生中のBGMの再生時間(msecs)を取得する。
@property
ulong bgmLen() { mixin(S_TRACE);
	version (Windows) {
		return len(bgmChunk, _bgmPlayingMCI, "cwbgm", bassBGMStream);
	} else {
		return 0;
	}
}
/// 現在再生中の効果音の再生位置(msecs)を取得する。
@property
ulong sePos() { mixin(S_TRACE);
	version (Windows) {
		return pos(seChunk, _sePlayingMCI, "cwse", bassSEStream);
	} else {
		return 0;
	}
}
/// 現在再生中の効果音の再生時間(msecs)を取得する。
@property
ulong seLen() { mixin(S_TRACE);
	version (Windows) {
		return len(seChunk, _sePlayingMCI, "cwse", bassSEStream);
	} else {
		return 0;
	}
}

private void printSDLError(string File = __FILE__, int Line = __LINE__)() { mixin(S_TRACE);
	auto str = getSymbol!(SDL_GetError)(sdl, "SDL_GetError")();
	debugln!(File, Line)(str[0..strlen(str)]);
}

private void play(ref Mix_Music* music, ref Mix_Chunk* chunk, ref c_int channel, string mciName, ref bool onLegacy, ref bool playingMCI, string file, bool loop, int soundPlayType, uint volume, ref HSTREAM bassStream) { mixin(S_TRACE);
	stop(music, chunk, channel, mciName, onLegacy, playingMCI, bassStream);
	version (Windows) {
		if (SOUND_TYPE_BASS == soundPlayType) { mixin(S_TRACE);
			// BASSがロードされている場合はBASSで再生する
			if (playBass(file, loop, bassStream, volume)) { mixin(S_TRACE);
				return;
			}
			// ここへ来たら再生失敗
		}
	}
	try { mixin(S_TRACE);
		version (Windows) {
			if (winmm && (SOUND_TYPE_MCI == soundPlayType || !sdl)) { mixin(S_TRACE);
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
				if (loop && _mciNotifyHandle) { mixin(S_TRACE);
					p ~= " notify";
					enforce(0 == _mciSendString(toUTFz!(wchar*)(p), null, 0, _mciNotifyHandle),
						new Exception("MCI play: " ~ file));
				} else { mixin(S_TRACE);
					enforce(0 == _mciSendString(toUTFz!(wchar*)(p), null, 0, null),
						new Exception("MCI play: " ~ file));
				}
				playingMCI = true;
				return;
			}
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

				if (loop) { mixin(S_TRACE);
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
					if (0 != getSymbol!(Mix_PlayMusic)(mixer, "Mix_PlayMusic")(music, -1)) { mixin(S_TRACE);
						debugln("error: Mix_PlayMusic, " ~ file);
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
					channel = getSymbol!(Mix_PlayChannelTimed)(mixer, "Mix_PlayChannelTimed")(channel, chunk, 0, -1);
					if (-1 == channel) { mixin(S_TRACE);
						debugln("error: Mix_PlayChannelTimed, " ~ file);
						printSDLError();
						return;
					}
				}
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

/// 指定されたディレクトリにあるBASSのDLLをロードし、初期化する。
bool initBass(string dir, in string[] soundFonts) { mixin(S_TRACE);
	if (!mutex) return false;
	version (Windows) {
		mutex.lock();
		scope (exit) mutex.unlock();
		if (bass) { mixin(S_TRACE);
			_toggleInitBass = true;
			_initBassDir = dir;
			_initBassSFont = soundFonts.dup;
			return true;
		}
		try { mixin(S_TRACE);
			if (!bass) { mixin(S_TRACE);
				bass = dlopen(dir.buildPath("bass.dll"));
				if (!bass) { mixin(S_TRACE);
					bass = dlopen("bass.dll");
					if (!bass) { mixin(S_TRACE);
						disposeBass();
						return false;
					}
				}
				if (soundFonts.length) { mixin(S_TRACE);
					// 読込失敗でも続行
					bassMidi = dlopen(dir.buildPath("bassmidi.dll"));
					if (!bassMidi) { mixin(S_TRACE);
						bassMidi = dlopen("bassmidi.dll");
					}
				}
				if (!getSymbol!(BASS_Init)(bass, "BASS_Init")(-1, 44100, BASS_DEFAULT, null, null)) { mixin(S_TRACE);
					disposeBass();
					return false;
				}
			}
			_BASS_StreamGetFilePosition = getSymbol!(BASS_StreamGetFilePosition)(bass, "BASS_StreamGetFilePosition");
			if (!bassMidi || !soundFonts.length || !loadBassSoundFont(soundFonts)) { mixin(S_TRACE);
				// MIDI再生のみ無効とする
				return true;
			}
			return true;
		} catch (Exception e) {
			printStackTrace();
			debugln(e);
		}
	}
	return false;
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
void disposeBass() { mixin(S_TRACE);
	if (!mutex) return;
	mutex.lock();
	scope (exit) mutex.unlock();
	version (Windows) {
		_toggleDisposeBass = false;
		try { mixin(S_TRACE);
			stopBGM();
			stopSE();
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
		if (_toggleInitBass) { mixin(S_TRACE);
			_toggleInitBass = false;
			initBass(_initBassDir, _initBassSFont);
			_initBassDir = "";
			_initBassSFont = [];
		}
	}
}
/// BGMと音声の停止後にdisposeBass()を行う。
void toggleDisposeBass() { mixin(S_TRACE);
	version (Windows) {
		if (!mutex) return;
		mutex.lock();
		scope (exit) mutex.unlock();
		if (bassBGMStream || bassSEStream) { mixin(S_TRACE);
			_toggleDisposeBass = true;
		} else { mixin(S_TRACE);
			disposeBass();
		}
	}
}

// BASS関係
version (Windows) {
	private __gshared void* bass = null;
	private __gshared void* bassMidi = null;
	private __gshared BASS_MIDI_FONT[] soundFonts = [];
	private __gshared HSTREAM bassBGMStream = 0;
	private __gshared HSTREAM bassSEStream = 0;
	private __gshared _toggleDisposeBass = false;
	private __gshared _toggleInitBass = false;
	private __gshared _initBassDir = "";
	private __gshared const(string)[] _initBassSFont = [];
}

/// fileがMIDIファイルであればtrue。
bool isMidi(string file) { mixin(S_TRACE);
	switch (file.extension().toLower()) {
	case ".mid", ".midi":
		return true;
	default:
		return false;
	}
}

private bool playBass(string file, bool loop, ref DWORD stream, uint volume) { mixin(S_TRACE);
	version (Windows) {
		try { mixin(S_TRACE);
			if (!bass) return false;
			stopBass(stream);
			if (!.canPlayBass(file)) { mixin(S_TRACE);
				return false;
			}
			bool midi = isMidi(file);
			int flag = loop ? BASS_SAMPLE_LOOP : BASS_DEFAULT;
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
			volume = .min(100, volume);
			if (!getSymbol!(BASS_ChannelSetAttribute)(bass, "BASS_ChannelSetAttribute")(stream, BASS_ATTRIB_VOL, volume / 100.0F)) { mixin(S_TRACE);
				debugln("BASS_ChannelSetAttribute");
			}
			if (!getSymbol!(BASS_ChannelPlay)(bass, "BASS_ChannelPlay")(stream, loop)) { mixin(S_TRACE);
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
private void stopBass(ref DWORD stream) { mixin(S_TRACE);
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
			BYTE Data4[8];
		}
		struct BASS_MIDI_FONT {
			HSOUNDFONT font;
			c_int preset;
			c_int bank;
		}
		alias DWORD HSTREAM;
		alias DWORD HSOUNDFONT;
		alias ulong QWORD;
		immutable BASS_DEVICE_DEFAULT = 2;
		immutable BASS_DEFAULT = 0;
		immutable BASS_SAMPLE_LOOP = 4;
		immutable BASS_ATTRIB_VOL = 2;
		immutable BASS_FILEPOS_CURRENT = 0;
		immutable BASS_FILEPOS_END = 2;
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
		alias QWORD function(HSTREAM handle, DWORD mode) BASS_StreamGetFilePosition;
		BASS_StreamGetFilePosition _BASS_StreamGetFilePosition;
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
		return bass !is null && !_toggleDisposeBass;
	}
	return false;
}
/// BASSでfileを再生できる状態であればtrue。
bool canPlayBass(string file) { mixin(S_TRACE);
	version (Windows) {
		if (!mutex) return false;
		mutex.lock();
		scope (exit) mutex.unlock();
		return .useBass && (isMidi(file) ? (bassMidi && soundFonts.length) : true);
	}
	return false;
}

/// BGMを再生する。
void playBGM(string path, int soundPlayType) { mixin(S_TRACE);
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
		play(bgmMusic, bgmChunk, bgmChannel, "cwbgm", bgmOnLegacy, _bgmPlayingMCI, path, true, soundPlayType, _bgmVolume, bass);
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
		stop(bgmMusic, bgmChunk, bgmChannel, "cwbgm", bgmOnLegacy, _bgmPlayingMCI, bass);
	} catch (Throwable e) {
		printStackTrace();
		debugln(e);
	}
	version (Windows) {
		if (_toggleDisposeBass && !bassBGMStream && !bassSEStream) { mixin(S_TRACE);
			disposeBass();
		}
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
			if (!getSymbol!(BASS_ChannelSetAttribute)(bass, "BASS_ChannelSetAttribute")(bassBGMStream, BASS_ATTRIB_VOL, _bgmVolume / 100.0F)) { mixin(S_TRACE);
				debugln("BASS_ChannelSetAttribute");
			}
		}
/+		if (_mciSendString) { mixin(S_TRACE);
			winmmSync.lock();
			scope (exit) winmmSync.unlock();
			if (0 != _mciSendString(toUTFz!(wchar*)(.format("setaudio %s volume to %d", "cwbgm", _bgmVolume * 10)), null, 0, null)) { mixin(S_TRACE);
				debugln("error MCI setaudio");
			}
		}
+/	}
}

/// 効果音を再生する。
void playSE(string path, int soundPlayType) { mixin(S_TRACE);
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
		play(seMusic, seChunk, seChannel, "cwse", seOnLegacy, _sePlayingMCI, path, false, soundPlayType, _seVolume, bass);
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
		stop(seMusic, seChunk, seChannel, "cwse", seOnLegacy, _sePlayingMCI, bass);
	} catch (Throwable e) {
		printStackTrace();
		debugln(e);
	}
	version (Windows) {
		if (_toggleDisposeBass && !bassBGMStream && !bassSEStream) { mixin(S_TRACE);
			disposeBass();
		}
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
			if (!getSymbol!(BASS_ChannelSetAttribute)(bass, "BASS_ChannelSetAttribute")(bassSEStream, BASS_ATTRIB_VOL, _seVolume / 100.0F)) { mixin(S_TRACE);
				debugln("BASS_ChannelSetAttribute");
			}
		}
/+		if (_mciSendString) { mixin(S_TRACE);
			winmmSync.lock();
			scope (exit) winmmSync.unlock();
			if (0 != _mciSendString(toUTFz!(wchar*)(.format("setaudio %s volume to %d", "cwse", _seVolume * 10)), null, 0, null)) { mixin(S_TRACE);
				debugln("error MCI setaudio");
			}
		}
+/	}
}
