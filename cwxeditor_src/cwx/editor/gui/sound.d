
module cwx.editor.gui.sound;

import std.compat;
import std.loader;
import std.utf;

import cwx.sjis;
import cwx.utils : debugln, enforce;

version (Windows) {
	import std.c.windows.windows;
	private extern (Windows) {
		alias DWORD MCIERROR;
		alias MCIERROR function(LPCWSTR, LPWSTR, UINT, HANDLE) mciSendStringW;
	}
}
private extern (C) {
	const uint SDL_INIT_AUDIO = 0x10;
	version (LittleEndian) {
		const ushort MIX_DEFAULT_FORMAT = AUDIO_S16LSB;
 	} else {
		const ushort MIX_DEFAULT_FORMAT = AUDIO_S16MSB;
	}
	const ushort AUDIO_S16LSB = 0x8010;
	const ushort AUDIO_S16MSB = 0x9010;

	alias int function(uint) SDL_Init;
	alias void function() SDL_Quit;
	alias int function(int, ushort, int, int) Mix_OpenAudio;
	alias void function() Mix_CloseAudio;
	alias int function(int numchans) Mix_AllocateChannels;
	struct Mix_Music {}
	alias Mix_Music* function(char* file) Mix_LoadMUS;
	alias int function(Mix_Music* music, int loops) Mix_PlayMusic;
	alias void function(Mix_Music* music) Mix_FreeMusic;
	alias int function() Mix_HaltMusic;
}

private HXModule sdl = null;
private HXModule mixer = null;

private T getSymbol(T)(HXModule mod, string name) {
	void* symbol = ExeModule_GetSymbol(mod, name);
	if (!symbol) throw new Exception("Symbol " ~ name ~ " is not found.");
	T r = cast(T) symbol;
	if (!r) throw new Exception("Symbol " ~ name ~ " is not found.");
	return r;
}

version (Windows) {
	private HXModule winmm = null;
	private void initWinmm() {
		winmm = ExeModule_Load("winmm.dll");
		if (!winmm) {
			debugln("error: winmm.dll initialize");
		}
	}
}
private void initSdl() {
	version (Windows) {
		static const SDL = "SDL.dll";
		static const MIXER = "SDL_mixer.dll";
	} else {
		static const SDL = "SDL.so";
		static const MIXER = "SDL_mixer.so";
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
		} catch (Exception e) {
			debugln(e.msg);
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
static this() {
	version (Windows) {
		initWinmm;
	}
	initSdl;
}

static ~this() {
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
}

version (Windows) {
	private bool onLegacy = false;
}
private Mix_Music *music = null;

private void __play(string file, bool loop, bool legacy) {
	stopBGM;
	onLegacy = legacy;
	try {
		version (Windows) {
			if (winmm && legacy) {
				auto ss = getSymbol!(mciSendStringW)(winmm, "mciSendStringW");
				if (!ss) throw new Exception("mciSendStringW()");
				// mpegvideoにするとなぜかopenが成功する上repeatが利くようになる
				enforce(0 == ss(toUTF16z("open \"" ~ file ~ "\" alias s type mpegvideo"), null, 0, null),
					new Exception("MCI open: " ~ file));
				string p = "play s";
				if (loop) p ~= " repeat";
				enforce(0 == ss(toUTF16z(p), null, 0, null),
					new Exception("MCI open: " ~ file));
				return;
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
					music = getSymbol!(Mix_LoadMUS)(mixer, "Mix_LoadMUS")(tosjisz(file));
				} else {
					music = getSymbol!(Mix_LoadMUS)(mixer, "Mix_LoadMUS")((file ~ "\0").ptr);
				}
				if (!music) {
					debugln("error: Mix_LoadMUS, " ~ file);
					return;
				}
				if (0 != getSymbol!(Mix_PlayMusic)(mixer, "Mix_PlayMusic")(music, loop ? -1 : 0)) {
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
		if (onLegacy) {
			auto ss = getSymbol!(mciSendStringW)(winmm, "mciSendStringW");
			if (!ss) throw new Exception("mciSendStringW()");
			ss(toUTF16z("stop s"), null, 0, null);
			ss(toUTF16z("close s"), null, 0, null);
		} else if (sdl && music) {
			if (0 == getSymbol!(Mix_HaltMusic)(mixer, "Mix_HaltMusic")()) {
				getSymbol!(Mix_FreeMusic)(mixer, "Mix_FreeMusic")(music);
				music = null;
			} else {
				debugln("error: Mix_HaltMusic");
			}
		}
	} catch (Exception e) {
		debugln(e);
	}
}

/// BGMを再生する。
void playBGM(string path, bool legacy) {
	__play(path, true, legacy);
}

/// BGMを停止する。
void stopBGM() {
	__stop;
}

/// 効果音を再生する。
void playSE(string path, bool legacy) {
	__play(path, false, legacy);
}

/// 効果音を停止する。
void stopSE() {
	__stop;
}
