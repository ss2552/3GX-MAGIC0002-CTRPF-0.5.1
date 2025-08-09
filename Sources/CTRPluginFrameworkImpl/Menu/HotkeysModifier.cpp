#include "CTRPluginFrameworkImpl/Menu/HotkeysModifier.hpp"
#include "CTRPluginFrameworkImpl/Graphics/Icon.hpp"
#include "CTRPluginFrameworkImpl/Graphics/Renderer.hpp"
#include "CTRPluginFrameworkImpl/Graphics/Window.hpp"
#include "CTRPluginFramework/System/Controller.hpp"
#include "Unicode.h"
#include "CTRPluginFramework/System/System.hpp"
#include "CTRPluginFrameworkImpl/Preferences.hpp"

namespace CTRPluginFramework
{
    static const Key ktable[14] =
    {
        ZL, L, DPadUp, DPadLeft, DPadRight, DPadDown, Start,
        ZR, R, X, Y, A, B, Select
    };

    static const char *stable[14] =
    {
        FONT_ZL, FONT_L, FONT_DU, FONT_DL, FONT_DR, FONT_DD, "Start",
        FONT_ZR, FONT_R, FONT_X, FONT_Y, FONT_A, FONT_B, "Select"
    };

    static int    GetIndex(int code)
    {
        for (int i = 0; i < 14; ++i)
            if (ktable[i] == code)
                return (i);

        return (0); ///< shouldn"t happen (unsafe code, bad)
    }

    HotkeysModifier::HotkeysModifier(u32 &keys, const std::string &message) :
    _keys(keys), _message(message)
    {
        for (int i = 0, posY = 32; i < 7; ++i, posY += 25)
            _checkboxs.push_back(Button(Button::Icon, IntRect(30, posY, 20, 20), Icon::DrawCheckBox));
        for (int i = 0, posY = 32; i < 7; ++i, posY += 25)
            _checkboxs.push_back(Button(Button::Icon, IntRect(200, posY, 20, 20), Icon::DrawCheckBox));

        for (int i = 0; i < 16; ++i)
        {
            if (keys & (1u << i))
            {
                _checkboxs[GetIndex(1u << i)].SetState(true);
            }
        }

        if (!System::IsNew3DS())
        {
            // Disable ZL & ZR on O3DS
            _checkboxs[0].Enable(false);
            _checkboxs[7].Enable(false);
        }
    }

    HotkeysModifier::~HotkeysModifier()
    {
    }

    void    HotkeysModifier::operator()(void)
    {
        while (!Window::BottomWindow.MustClose() || !_keys)
        {
            Controller::Update();
            _DrawTop();
            _DrawBottom();
            Renderer::EndFrame();
            _Update();

            _keys = 0;

            for (int i = 0; i < 14; i++)
            {
                if (_checkboxs[i].GetState())
                    _keys |= ktable[i];
            }
        }
    }

    void    HotkeysModifier::_DrawTop(void) const
    {
        Renderer::SetTarget(TOP);
        Window::TopWindow.Draw("Hotkey Modifier");

        int posY = 61;
        Renderer::DrawSysStringReturn((const u8*)_message.c_str(), 40, posY, 300, Preferences::Settings.MainTextColor);
    }

    void    HotkeysModifier::_DrawBottom(void)
    {
        Renderer::SetTarget(BOTTOM);
        Window::BottomWindow.Draw();

        // Draw CheckBoxes
        for (Button &cb : _checkboxs)
            cb.Draw();

        int skip = !System::IsNew3DS();

        // Draw labels
        for (int i = 0 + skip, posY = 32 + (skip * 25); i < 7; ++i, posY += 9)
            Renderer::DrawSysString(stable[i], 50, posY, 290, Preferences::Settings.MainTextColor);
        for (int i = 7 + skip, posY = 32 + (skip * 25); i < 14; ++i, posY += 9)
            Renderer::DrawSysString(stable[i], 220, posY, 290, Preferences::Settings.MainTextColor);
    }

    void    HotkeysModifier::_Update(void)
    {
        bool        isTouched = Touch::IsDown();
        IntVector   touchPos(Touch::GetPosition());

        for (Button &cb : _checkboxs)
            cb.Update(isTouched, touchPos);

        Window::BottomWindow.Update(isTouched, touchPos);
    }
}
