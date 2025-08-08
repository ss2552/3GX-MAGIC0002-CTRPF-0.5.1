#ifndef CTRPLUGINFRAMEWORKIMPL_PROCESSIMPL_HPP
#define CTRPLUGINFRAMEWORKIMPL_PROCESSIMPL_HPP

#include "ctrulib/svc.h"
#include "ctrulib/synchronization.h"
#include "CTRPluginFrameworkImpl/System/Kernel.hpp"
#include "CTRPluginFramework/System/Mutex.hpp"
#include <vector>

namespace CTRPluginFramework
{
    #define MEMPERM_RW (MEMPERM_READ | MEMPERM_WRITE)
    #define MEMPERM_RWX (MEMPERM_RW | MEMPERM_EXECUTE)

    static inline bool      operator<(const MemInfo& left, const MemInfo& right)
    {
        return left.base_addr < right.base_addr
            || (left.base_addr == right.base_addr && left.size < right.size);
    }

    static inline bool      operator>(const MemInfo& left, const MemInfo& right)
    {
        return left.base_addr > right.base_addr
            || (left.base_addr == right.base_addr && left.size > right.size);
    }

    static inline bool      operator<=(const MemInfo& left, const MemInfo& right)
    {
        return left.base_addr < right.base_addr
            || (left.base_addr == right.base_addr && left.size <= right.size);
    }

    static inline bool      operator>=(const MemInfo& left, const MemInfo& right)
    {
        return left.base_addr > right.base_addr
            || (left.base_addr == right.base_addr && left.size >= right.size);
    }

    static inline bool      operator==(const MemInfo& left, const MemInfo& right)
    {
        return left.base_addr == right.base_addr && left.size == right.size;
    }

    static inline bool      operator!=(const MemInfo& left, const MemInfo& right)
    {
        return left.base_addr != right.base_addr || left.size != right.size;
    }

    class ProcessImpl
    {
    public:
        // Pause the current process
        static void     Pause(bool useFading);
        // Unpause the current process
        static void     Play(bool forced);

        static void     Initialize(void);

        static bool     PatchProcess(u32 addr, u8 *patch, u32 length, u8 *original);
        static void     GetHandleTable(KProcessHandleTable &table, std::vector<HandleDescriptor> &handleDescriptors);
        static void     GetGameThreads(std::vector<KThread *> &threads);
        static void     LockGameThreads(void);
        static void     UnlockGameThreads(void);

        static void     UpdateMemRegions(void);
        static bool     IsValidAddress(const u32 address);
        static u32      GetPAFromVA(const u32 address);
        static MemInfo  GetMemRegion(const u32 address);
        static MemInfo  GetNextRegion(const MemInfo &region);
        static MemInfo  GetPreviousRegion(const MemInfo &region);

        static Handle       ProcessHandle;
        static u32          IsPaused;
        static u32          ProcessId;
        static u64          TitleId;

        static KThread *    MainThread;
        static KProcess *   KProcessPtr;
        static KCodeSet     CodeSet;

        static MemInfo      InvalidRegion;
        static Mutex        MemoryMutex;
        static std::vector<MemInfo>     MemRegions;
    };
}

#endif
