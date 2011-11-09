
module cwx.editor.gui.sound;

import std.loader;
import std.utf;
import std.stdint;

import cwx.sjis;
import cwx.utils : cdebugln, debugln, enforce;

version (Windows) {
	import std.windows.charset;
	import std.c.windows.windows;
	private extern (Windows) {
		alias __gshared DWORD MCIERROR;
		alias __gshared MCIERROR function(LPCWSTR, LPWSTR, UINT, HANDLE) mciSendStringW;
	}
	private const __gshared MCI_NOTIFY_SUCCESSFUL = 0x0001;
	private const __gshared MM_MCINOTIFY = 0x03B9;
	/// playBGM()はmciNotifyHandleに設定されたウィンドウに対して
	/// 再生イベントを通知する。
	/// 通知先が直ちにhandleSoundMessage()を呼び出す事により、
	/// MCIでループ再生を行なう事ができる。
	public HWND mciNotifyHandle = INVALID_HANDLE_VALUE;
	/// ditto
	void handleSoundMessage(int msg, int wParam) {
		if (INVALID_HANDLE_VALUE == mciNotifyHandle) return;
		if (!winmm || !_mciSendString) return;
		if (!_playingMCI) return;
		if (MM_MCINOTIFY != msg || MCI_NOTIFY_SUCCESSFUL != wParam) return;
		synchronized (winmmSync) {
			static const __gshared SEEK = "seek cws to 0\0"w.ptr;
			static const __gshared PLAY = "play cws notify\0"w.ptr;
			_mciSendString(SEEK, null, 0, null);
			_mciSendString(PLAY, null, 0, mciNotifyHandle);
		}
	}
}
private extern (C) {
	const __gshared uint SDL_INIT_AUDIO = 0x10;
	const __gshared ushort AUDIO_S16LSB = 0x8010;
	const __gshared ushort AUDIO_S16MSB = 0x9010;
	version (LittleEndian) {
		const __gshared ushort MIX_DEFAULT_FORMAT = AUDIO_S16LSB;
 	} else {
		const __gshared ushort MIX_DEFAULT_FORMAT = AUDIO_S16MSB;
	}
	alias uint Uint32;
	alias ushort Uint16;
	alias ubyte Uint8;
	alias void Mix_Music;
	alias void Mix_Chunk;

	alias intptr_t function(Uint32) SDL_Init;
	alias void function() SDL_Quit;
	alias intptr_t function(intptr_t, Uint16, intptr_t, intptr_t) Mix_OpenAudio;
	alias void function() Mix_CloseAudio;
	alias intptr_t function(intptr_t numchans) Mix_AllocateChannels;
	alias Mix_Music* function(const char* file) Mix_LoadMUS;
	alias Mix_Chunk* function(Uint8* mem) Mix_QuickLoad_WAV;
	alias intptr_t function(Mix_Music* music, intptr_t loops) Mix_PlayMusic;
	alias intptr_t function(intptr_t channel, Mix_Chunk *chunk, intptr_t loops, intptr_t ticks) Mix_PlayChannelTimed;
	alias intptr_t function(Mix_Chunk *chunk, intptr_t volume) Mix_VolumeChunk;
	alias void function(Mix_Music* music) Mix_FreeMusic;
	alias intptr_t function() Mix_HaltMusic;
	alias intptr_t function(intptr_t channel) Mix_HaltChannel;
	alias void function(Mix_Chunk *chunk) Mix_FreeChunk;
}

private __gshared HXModule sdl = null;
private __gshared HXModule mixer = null;

private T getSymbol(T)(HXModule mod, string name) {
	void* symbol = ExeModule_GetSymbol(mod, name);
	if (!symbol) throw new Exception("Symbol " ~ name ~ " is not found.");
	T r = cast(T) symbol;
	if (!r) throw new Exception("Symbol " ~ name ~ " is invalid function.");
	return r;
}

version (Windows) {
	private __gshared Object winmmSync = null;
	private __gshared HXModule winmm = null;
	private __gshared mciSendStringW _mciSendString = null;
	private __gshared bool _playingMCI = false;
	private void initWinmm() {
		if (winmm) return;
		winmmSync = new Object;
		winmm = ExeModule_Load("winmm.dll");
		if (!winmm) {
			debugln("error: winmm.dll initialize");
		}
		_mciSendString = getSymbol!(mciSendStringW)(winmm, "mciSendStringW");
		if (!_mciSendString) {
			debugln("mciSendStringW() not found");
			ExeModule_Release(winmm);
			winmm = null;
		}
	}
}
private void initSdl() {
	if (sdl && mixer) return;
	version (Windows) {
		static __gshared const SDL = "SDL.dll";
		static __gshared const MIXER = "SDL_mixer.dll";
	} else {
		static __gshared const SDL = "SDL.so";
		static __gshared const MIXER = "SDL_mixer.so";
	}
	sdl = ExeModule_Load(SDL);
	mixer = ExeModule_Load(MIXER);
	if (sdl && mixer) {
		try {
			if (0 == getSymbol!(SDL_Init)(sdl, "SDL_Init")(SDL_INIT_AUDIO)) {
				if (0 == getSymbol!(Mix_OpenAudio)(mixer, "Mix_OpenAudio")(44100, MIX_DEFAULT_FORMAT, 2, 4092)) {
					if (0 < getSymbol!(Mix_AllocateChannels)(mixer, "Mix_AllocateChannels")(1)) {
						return;
					}
					getSymbol!(Mix_CloseAudio)(mixer, "Mix_CloseAudio")();
				}
				getSymbol!(SDL_Quit)(sdl, "SDL_Quit")();
			}
		} catch (Throwable e) {
			debugln(e);
		}
	} else {
		if (!sdl) debugln("not found: " ~ SDL);
		if (!mixer) debugln("not found: " ~ MIXER);
	}
	if (sdl) {
		ExeModule_Release(sdl);
		sdl = null;
	}
	if (mixer) {
		ExeModule_Release(mixer);
		mixer = null;
	}
	debugln("error: SDL_mixer initialize");
}
shared static this () {
	try {
		version (Windows) {
			initWinmm();
		}
		initSdl();
	} catch (Throwable e) {
		debugln(e);
	}
}

shared static ~this () {
	try {
		if (sdl) {
			try {
				getSymbol!(Mix_CloseAudio)(mixer, "Mix_CloseAudio")();
				getSymbol!(SDL_Quit)(sdl, "SDL_Quit")();
			} catch (Exception e) {
				debugln(e.msg);
			}
			ExeModule_Release(mixer);
			ExeModule_Release(sdl);
		}
	} catch (Throwable e) {
		debugln(e);
	}
}

private __gshared bool onLegacy = false;
private __gshared Mix_Music *music = null;
private __gshared Mix_Chunk *chunk = null;
private __gshared intptr_t channel = -1;

private void __play(string file, bool loop, bool legacy) {
	stopBGM;
	try {
		version (Windows) {
			if (winmm && (legacy || !sdl)) {
				synchronized (winmmSync) {
					onLegacy = true;
					// typeにmpegvideoを指定するとリピート再生する事もできるが、
					// 一部環境でアプリケーションが丸ごと落ちる
					enforce(0 == _mciSendString(toUTFz!(wchar*)("open \"" ~ file ~ "\" alias cws"), null, 0, null),
						new Exception("MCI open: " ~ file));
					string p = "play cws";
					if (loop && INVALID_HANDLE_VALUE != mciNotifyHandle) {
						p ~= " notify";
						enforce(0 == _mciSendString(toUTFz!(wchar*)(p), null, 0, mciNotifyHandle),
							new Exception("MCI play: " ~ file));
					} else {
						enforce(0 == _mciSendString(toUTFz!(wchar*)(p), null, 0, null),
							new Exception("MCI play: " ~ file));
					}
					_playingMCI = true;
					return;
				}
			}
		}
	} catch (Exception e) {
		debugln(e.msg);
	}
	onLegacy = false;
	try {
		if (sdl) {
			if (file.length > 0 && !music) {
				version (Windows) {
					// Unicodeで日本語パスを渡すと失敗するので変換しておく
					const char* filez = toMBSz(file);
				} else {
					const char* filez = (file ~ "\0").ptr;
				}
				music = getSymbol!(Mix_LoadMUS)(mixer, "Mix_LoadMUS")(filez);
				if (!music) {
					debugln("error: Mix_LoadMUS, " ~ file);
					return;
				}
				if (0 != getSymbol!(Mix_PlayMusic)(mixer, "Mix_PlayMusic")(music, loop ? -1 : 1)) {
					debugln("error: Mix_PlayMusic, " ~ file);
					return;
				}
			}
		}
	} catch (Exception e) {
		debugln(e.msg);
	}
}

private void __stop() {
	try {
		version (Windows) {
			if (onLegacy) {
				synchronized (winmmSync) {
					_playingMCI = false;
					_mciSendString(toUTFz!(wchar*)("stop cws"), null, 0, null);
					_mciSendString(toUTFz!(wchar*)("close cws"), null, 0, null);
					return;
				}
			}
		}
		if (sdl) {
			if (music) {
				if (0 == getSymbol!(Mix_HaltMusic)(mixer, "Mix_HaltMusic")()) {
					getSymbol!(Mix_FreeMusic)(mixer, "Mix_FreeMusic")(music);
					music = null;
				} else {
					debugln("error: Mix_HaltMusic");
				}
			}
			if (-1 == channel) {
				getSymbol!(Mix_HaltChannel)(mixer, "Mix_HaltChannel")(channel);
				channel = -1;
			}
			if (chunk) {
				getSymbol!(Mix_FreeChunk)(mixer, "Mix_FreeChunk")(chunk);
				chunk = null;
			}
		}
	} catch (Exception e) {
		debugln(e.msg);
	}
}

/// BGMを再生する。
void playBGM(string path, bool legacy) {
	try {
		__play(path, true, legacy);
	} catch (Throwable e) {
		debugln(e);
	}
}

/// BGMを停止する。
void stopBGM() {
	try {
		__stop;
	} catch (Throwable e) {
		debugln(e);
	}
}

/// 効果音を再生する。
void playSE(string path, bool legacy) {
	try {
		__play(path, false, legacy);
	} catch (Throwable e) {
		debugln(e);
	}
}

/// 効果音を停止する。
void stopSE() {
	try {
		__stop;
	} catch (Throwable e) {
		debugln(e);
	}
}
