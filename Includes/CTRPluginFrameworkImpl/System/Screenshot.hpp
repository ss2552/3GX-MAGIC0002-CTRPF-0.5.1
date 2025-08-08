#ifndef CTRPLUGINFRAMEWORKIMPL_SYSTEM_SCREENSHOT_HPP
#define CTRPLUGINFRAMEWORKIMPL_SYSTEM_SCREENSHOT_HPP

#include "types.h"
#include "CTRPluginFramework/System/Clock.hpp"
#include "CTRPluginFramework/System/Task.hpp"
#include "ctrulib/synchronization.h"

#include <string>


namespace CTRPluginFramework
{
    class Screenshot
    {
    public:

        // Return true if the OSD must exit
        static void     Initialize(void);
        static bool     OSDCallback(u32 isBottom, void* addr, void* addrB, int stride, int format);
        static s32      TaskCallback(void *arg);
        static void     UpdateFileCount(void);

        static bool         IsEnabled;
        static u32          Hotkeys;
        static u32          Screens;
        static Time         Timer;
        static std::string  Path;
        static std::string  Prefix;

    private:

        static u32          _count;
        static u32          _mode;
        static u32          _filecount;
        static u32          _display;
        static Clock        _timer;
        static Task         _task;

        static LightEvent   _readyEvent;
        static LightEvent   _resumeEvent;
    };
}

#endif
