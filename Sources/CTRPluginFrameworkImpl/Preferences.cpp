#include "CTRPluginFramework/System/Controller.hpp"
#include "CTRPluginFrameworkImpl/Preferences.hpp"
#include <cmath>
#include "ctrulib/result.h"
#include <cstring>
#include "CTRPluginFrameworkImpl/Menu/PluginMenuImpl.hpp"

namespace CTRPluginFramework
{
    BMPImage    *Preferences::topBackgroundImage = nullptr;
    BMPImage    *Preferences::bottomBackgroundImage = nullptr;
    u32         Preferences::MenuHotkeys = static_cast<u32>(Key::Select);
    u32         Preferences::ScreenshotKeys = static_cast<u32>(Key::Start);
    bool        Preferences::InjectBOnMenuClose = false;
    bool        Preferences::DrawTouchCursor = false;
    bool        Preferences::DrawTouchCoord = false;
    bool        Preferences::EcoMemoryMode = false;
    bool        Preferences::DisplayFilesLoading = false;
    bool        Preferences::AutoSaveCheats = false;
    bool        Preferences::AutoSaveFavorites = false;
    bool        Preferences::AutoLoadCheats = false;
    bool        Preferences::AutoLoadFavorites = false;
    bool        Preferences::_cheatsAlreadyLoaded = false;
    bool        Preferences::_favoritesAlreadyLoaded = false;
    bool        Preferences::_bmpCanBeLoaded = true;
    bool        Preferences::ShowBottomFps = false;
    bool        Preferences::ShowTopFps = false;
    bool        Preferences::UseFloatingBtn = false;
    FwkSettings Preferences::Settings;
    std::string Preferences::CheatsFile;
    std::string Preferences::ScreenshotPath;
    std::string Preferences::ScreenshotPrefix;

    static const char *g_signature = "CTRPF\0\0";

    BMPImage *RegionFromCenter(BMPImage *img, int maxX, int maxY)
    {
        BMPImage *temp = new BMPImage(maxX, maxY);

        u32 cx = img->Width() / 2;
        u32 cy = img->Height() / 2;

        img->RoiFromCenter(cx, cy, maxX, maxY, *temp);

        delete img;
        return (temp);
    }

    BMPImage *UpSampleUntilItsEnough(BMPImage *img, int maxX, int maxY)
    {
        BMPImage *temp = new BMPImage(img->Width() * 2, img->Height() * 2);

        img->UpSample(*temp);
        delete img;

        if (temp->Width() < maxX || temp->Height() < maxY)
            return (UpSampleUntilItsEnough(temp, maxX, maxY));
        return (temp);
    }

    /*BMPImage *UpSampleThenCrop(BMPImage *img, int maxX, int maxY)
    {
        BMPImage *temp = UpSampleUntilItsEnough(img, maxX, maxY);

        BMPImage *res =  new BMPImage(maxX, maxY);

        u32 cx = temp->Width() / 2;
        u32 cy = temp->Height() / 2;

        temp->RoiFromCenter(cx, cy, maxX, maxY, *res);

        delete temp;

        return (res);
    }*/

    float GetRatio(int width, int height, int maxX, int maxY)
    {
        if (width >= height)
            return ((float)width / maxX);
        return ((float)height / maxY);
    }

    BMPImage *PostProcess(BMPImage *img, int maxX, int maxY)
    {
        int width = img->Width();
        int height = img->Height();

        if (width == maxX && height == maxY)
            return img;

        float ratio = GetRatio(width, height, maxX, maxY);

        int newWidth = (int)(ceilf((float)width / ratio));
        int newHeight = (int)(ceilf((float)height / ratio));

        BMPImage *temp = new BMPImage(newWidth, newHeight);

        img->Resample(*temp, newWidth, newHeight);
        delete img;

        if (newWidth != maxX || newHeight != maxY)
        {
            BMPImage *res = new BMPImage(*temp, maxX, maxY);
            delete temp;
            return res;
        }

        return (temp);
    }

    int     Preferences::OpenConfigFile(File &settings, Header &header)
    {

        if (File::Open(settings, "CTRPFData.bin") == 0 && settings.GetSize() > 0)
        {
             // Check version
            int     res = 0;

            if (settings.Read(&header, sizeof(u32) * 6)) return (-2);

            // Check file
            if (header.size != settings.GetSize() || memcmp(g_signature, header.sig, 8))
                return (-1);

            if (header.version != SETTINGS_VERSION)
            {
                ProcessImpl::Pause(false);

                MessageBox msgBox(Color::Yellow << "Warning\n\n" << ResetColor()
                    << "CTRPFData.bin version mismatch.\n"
                    << "Do you want to save it as CTRPFData.bin.bak to retrieve some data ?", DialogType::DialogYesNo);

                if (msgBox())
                {
                    settings.Close();
                    if (File::Rename("CTRPFData.bin", "CTRPFData.bin.bak") == File::OPResult::SUCCESS)
                    {
                        MessageBox("Operation succeeded")();
                    }
                    else
                        MessageBox("Operation failed")();
                }

                ProcessImpl::Play(false);
                return (-1);
            }

            // Rewind file
            settings.Rewind();

            res = settings.Read(&header, sizeof(Header));

            return (res);
        }

        return (-1);
    }

    void    Preferences::LoadSettings(void)
    {
        File    settings;
        Header  header = { 0 };

        if (OpenConfigFile(settings, header) == 0)
        {
            MenuHotkeys = header.hotkeys;
            AutoLoadCheats = (header.flags & (u64)SettingsFlags::AutoLoadCheats) != 0;
            AutoLoadFavorites = (header.flags & (u64)SettingsFlags::AutoLoadFavorites) != 0;
            AutoSaveCheats = (header.flags & (u64)SettingsFlags::AutoSaveCheats) != 0;
            AutoSaveFavorites = (header.flags & (u64)SettingsFlags::AutoSaveFavorites) != 0;
            DrawTouchCursor = (header.flags & (u64)SettingsFlags::DrawTouchCursor) != 0;
            ShowBottomFps = (header.flags & (u64)SettingsFlags::ShowBottomFps) != 0;
            ShowTopFps = (header.flags & (u64)SettingsFlags::ShowTopFps) != 0;
            UseFloatingBtn = (header.flags & (u64)SettingsFlags::UseFloatingButton) != 0;
        }

        // Check that hotkeys aren't 0
        if (MenuHotkeys == 0)
            MenuHotkeys = Key::Select;
    }

    void    Preferences::LoadSavedEnabledCheats(void)
    {
        File    settings;
        Header  header = { 0 };

        if (_cheatsAlreadyLoaded)
        {
            MessageBox("Error\nCheats already loaded")();
            return;
        }

        if (OpenConfigFile(settings, header) == 0)
        {
            if (header.enabledCheatsCount != 0)
                PluginMenuImpl::LoadEnabledCheatsFromFile(header, settings);
            _cheatsAlreadyLoaded = true;
        }
    }

    void    Preferences::LoadSavedFavorites(void)
    {
        File    settings;
        Header  header = { 0 };

        if (_favoritesAlreadyLoaded)
        {
            MessageBox("Error\nFavorites already loaded")();
            return;
        }

        if (OpenConfigFile(settings, header) == 0)
        {
            if (header.favoritesCount != 0)
                PluginMenuImpl::LoadFavoritesFromFile(header, settings);
            _favoritesAlreadyLoaded = true;
        }
    }

    void    Preferences::LoadHotkeysFromFile(void)
    {
        File    settings;
        Header  header = { 0 };

        if (OpenConfigFile(settings, header) == 0)
        {
            if (header.hotkeysCount != 0)
                PluginMenuImpl::LoadHotkeysFromFile(header, settings);
        }
    }

    void    Preferences::LoadBackgrounds(void)
    {
        if (!_bmpCanBeLoaded)
            return;

        Task    task([](void *arg UNUSED)
        {
            std::string source;

            if (FwkSettings::Header->isDefaultPlugin)
                source = "/luma/plugins/ActionReplay/";

            // Try to load top background
            if (!EcoMemoryMode && File::Exists(source + "TopBackground.bmp"))
            {
                BMPImage *image = new BMPImage(source + "TopBackground.bmp");

                if (image->IsLoaded())
                    image = PostProcess(image, 340, 200);
                else
                {
                    delete image;
                    image = nullptr;
                }

                topBackgroundImage = image;
            }

            // Try to load bottom background
            if (!EcoMemoryMode && File::Exists(source + "BottomBackground.bmp"))
            {
                BMPImage *image = new BMPImage(source + "BottomBackground.bmp");

                if (image->IsLoaded())
                    image = PostProcess(image, 280, 200);
                else
                {
                    delete image;
                    image = nullptr;
                }

                bottomBackgroundImage = image;
            }

            // Update Window�
            Window::UpdateBackgrounds();

            return (s32)0;
        });

        task.Start();

        _bmpCanBeLoaded = false;
    }

    void    Preferences::UnloadBackgrounds(void)
    {
        if (bottomBackgroundImage || topBackgroundImage)
            _bmpCanBeLoaded = true;

        if (bottomBackgroundImage)
        {
            delete bottomBackgroundImage;
            bottomBackgroundImage = nullptr;
        }

        if (topBackgroundImage)
        {
            delete topBackgroundImage;
            topBackgroundImage = nullptr;
        }

        // Update Window
        Window::UpdateBackgrounds();
    }

    void    Preferences::WriteSettings(void)
    {
        OSDImpl::DrawSaveIcon = true;

        File    settings;
        int     mode = File::READ | File::WRITE | File::CREATE | File::TRUNCATE | File::SYNC;
        Header  header = { 0 };

        memcpy(header.sig, g_signature, 8);
        header.version = SETTINGS_VERSION;

        if (AutoSaveCheats) header.flags |= (u64)SettingsFlags::AutoSaveCheats;
        if (AutoLoadCheats) header.flags |= (u64)SettingsFlags::AutoLoadCheats;
        if (AutoSaveFavorites) header.flags |= (u64)SettingsFlags::AutoSaveFavorites;
        if (AutoLoadFavorites) header.flags |= (u64)SettingsFlags::AutoLoadFavorites;
        if (DrawTouchCursor) header.flags |= (u64)SettingsFlags::DrawTouchCursor;
        if (ShowBottomFps) header.flags |= (u64)SettingsFlags::ShowBottomFps;
        if (ShowTopFps) header.flags |= (u64)SettingsFlags::ShowTopFps;
        if (UseFloatingBtn) header.flags |= (u64)SettingsFlags::UseFloatingButton;

        header.hotkeys = MenuHotkeys;

        if (File::Open(settings, "CTRPFData.bin", mode) == 0)
        {
            if (settings.Write(&header, sizeof(Header)) != 0) goto error;

            if (AutoSaveCheats) PluginMenuExecuteLoop::WriteEnabledCheatsToFile(header, settings);///PluginMenuImpl::WriteEnabledCheatsToFile(header, settings);
            if (AutoSaveFavorites) PluginMenuImpl::WriteFavoritesToFile(header, settings);
            PluginMenuImpl::WriteHotkeysToFile(header, settings);

            header.size = settings.Tell();

            settings.Rewind();
            settings.Write(&header, sizeof(Header));
        }

    error:

        PluginMenuActionReplay::SaveCodes();
        OSDImpl::DrawSaveIcon = false;
        return;
    }

    void    Preferences::Initialize(void)
    {
        LoadBackgrounds();
    }
}
