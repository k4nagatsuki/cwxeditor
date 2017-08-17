
#include <Windows.h>
#include <stdint.h>

typedef DWORD HSYNC;
typedef DWORD HSTREAM;
typedef int64_t QWORD;
typedef BOOL (__stdcall *BASS_ChannelSetPosition)(HSTREAM handle, QWORD pos, DWORD mode);
static const int BASS_POS_BYTE = 0;

static QWORD loopStarts[2];
static int32_t loopCounts[2];

static BOOL (__stdcall *_BASS_ChannelSetPosition)(HSTREAM handle, QWORD pos, DWORD mode);

void set_BASS_ChannelSetPosition(BASS_ChannelSetPosition func) {
    _BASS_ChannelSetPosition = func;
}

void setLoopStart(size_t index, QWORD loopStart) {
    loopStarts[index] = loopStart;
}

void setLoopCount(size_t index, int32_t loopCount) {
    loopCounts[index] = loopCount;
}

void __stdcall bassLoop(HSYNC handle, DWORD channel, DWORD data, void *user) {
    size_t index = (size_t)user;
    QWORD pos = loopStarts[index];
    int32_t loops = loopCounts[index];
    if (loops != 1) {
        if (0 < loops) loopCounts[index] = loops - 1;
        _BASS_ChannelSetPosition(channel, pos, BASS_POS_BYTE);
    }
}
