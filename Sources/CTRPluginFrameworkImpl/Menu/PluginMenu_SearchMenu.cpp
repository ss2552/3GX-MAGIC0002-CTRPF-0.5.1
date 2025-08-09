#include "CTRPluginFrameworkImpl/Menu/PluginMenu_SearchMenu.hpp"
#include "CTRPluginFramework/Menu/Keyboard.hpp"
#include "CTRPluginFrameworkImpl/Graphics.hpp"
#include "CTRPluginFramework/System/Process.hpp"

#include <cstdlib>
#include <ctime>
#include "CTRPluginFramework/Menu/MessageBox.hpp"
#include "CTRPluginFramework/Utils/StringExtensions.hpp"
#include "Unicode.h"
#include "CTRPluginFramework/System/System.hpp"
#include "CTRPluginFrameworkImpl/Menu/PluginMenuActionReplay.hpp"
#include "CTRPluginFrameworkImpl/Preferences.hpp"

#include <cstring>

namespace CTRPluginFramework
{
    SearchMenu::SearchMenu(Search* &curSearch, HexEditor &hexEditor, bool &inEditor, bool &useHexInput) :
        _currentSearch(curSearch),
        _submenu{ { "Show game" }},
        _hexEditor(hexEditor),
        _inEditor(inEditor),
	    _useHexInput(useHexInput)
    {
        _index = 0;
        _selector = 0;
        _alreadyExported = false;
    }

    /*
    ** ProcessEvent
    ****************/
    bool    SearchMenu::ProcessEvent(EventList &eventList, Time &delta)
    {
        static Clock    _fastScroll;
        static Clock    _startFastScroll;

        bool isSubMenuOpen = _submenu.IsOpen();
        for (int i = 0; i < eventList.size(); i++)
        {
            Event &event = eventList[i];

            _submenu.ProcessEvent(event);

            if (isSubMenuOpen)
                continue;

            if (event.type == Event::EventType::KeyPressed
                && event.key.code == Key::B)
                return (true);
            // Pressed
            if (event.type == Event::EventType::KeyPressed)
            {
                //if (_currentSearch != nullptr)
                {
                    switch (event.key.code)
                    {
                        case Key::DPadUp:
                        {
                            _selector = std::max((int)(_selector - 1),(int)(0));
                            _startFastScroll.Restart();
                            break;
                        }
                        case Key::CPadDown:
                        {
                            _selector = std::min((int)(_selector + 5), (int)(_resultsAddress.size() - 1));
                            _startFastScroll.Restart();
                            break;
                        }
                        case Key::CPadUp:
                        {
                            _selector = std::max((int)(_selector - 5), (int)(0));
                            _startFastScroll.Restart();
                            break;
                        }
                        case Key::DPadDown:
                        {
                            _selector = std::min((int)(_selector + 1), (int)(_resultsAddress.size() - 1));
                            _startFastScroll.Restart();
                            break;
                        }
                        case Key::DPadLeft:
                        {
                            _index = std::max((int)(_index + _selector - 500), (int)(0));
                            _selector = 0;
                            _startFastScroll.Restart();
                            Update();
                            break;
                        }
                        case Key::DPadRight:
                        {
                            _index = std::min((int)(_index + _selector + 500),(int)(_currentSearch->ResultsCount / 500 * 500));
                            _selector = 0;
                            _startFastScroll.Restart();
                            Update();
                            break;
                        }
                        case Key::B:
                        {
                            return (true);
                        }
                        default: break;
                    } // end switch
                } // end if
            }
            // Hold
            else if (event.type == Event::EventType::KeyDown)
            {
                if (_currentSearch != nullptr && _startFastScroll.HasTimePassed(Seconds(0.5f)) && _fastScroll.HasTimePassed(Seconds(0.1f)))
                {
                    switch (event.key.code)
                    {
                        case Key::CPadDown:
                        {
                            _selector = std::min((int)(_selector + 5), (int)(_resultsAddress.size() - 1));

                            int  half = _resultsAddress.size() / 2;

                            if (_selector > half)
                            {
                                u32 bakIndex = _index;
                                _index = std::min((int)(_index + half), (int)(_currentSearch->ResultsCount / 500 * 500));
                                _selector -= _index - bakIndex;
                                Update();
                            }

                            _fastScroll.Restart();

                            break;
                        }
                        case Key::CPadUp:
                        {
                            _selector = std::max((int)(_selector - 5), (int)(0));

                            int  half = _resultsAddress.size() / 2;

                            if (_selector < half && _index > 0)
                            {
                                u32 bakIndex = _index;
                                _index = std::max((int)(_index - half), (int)(0));
                                _selector += bakIndex - _index;
                                Update();
                            }

                            _fastScroll.Restart();
                            break;
                        }
                        case Key::DPadUp:
                        {
                            _selector = std::max((int)(_selector - 1),(int)(0));
                            _fastScroll.Restart();
                            break;
                        }
                        case Key::DPadDown:
                        {
                            _selector = std::min((int)(_selector + 1),(int)(_resultsAddress.size() - 1));
                            _fastScroll.Restart();
                            break;
                        }
                        case Key::DPadLeft:
                        {
                            _index = std::max((int)(_index + _selector - 500),(int)(0));
                            _selector = 0;
                            _fastScroll.Restart();
                            Update();
                            break;
                        }
                        case Key::DPadRight:
                        {
                            _index = std::min((int)(_index + _selector + 500),(int)(_currentSearch->ResultsCount / 500 * 500));
                            _selector = 0;
                            _fastScroll.Restart();
                            Update();
                            break;
                        }
                        default: break;
                    } // end switch
                } // end if
            }
        }

        if (_submenu.IsOpen())
        {
            switch (_submenu())
            {
            case 0:
                if (_submenu.OptionsCount() == 1)
                    _ShowGame();
                else
                    _Edit();
                break;
            case 1:
                _JumpInEditor();
                break;
            case 2:
                _NewCheat();
                break;
            case 3:
                _Export();
                break;
            case 4:
                _ExportAll();
                break;
            case 5:
            {
                Converter *inst = Converter::Instance();

                if (inst)
                    (*inst)();
                break;
            }
            case 6:
                _ShowGame();
                break;
            default:
                break;
            }
        }
        return (false);
    }

    /*
    ** Draw
    ********/
    void    SearchMenu::Draw(void)
    {
        const Color    &black = Color::Black;
        const Color    &blank = Color::White;
        const Color    &darkgrey = Color::DarkGrey;
        const Color    &gainsboro = Color::Gainsboro;
        const Color    &silver = Color::Silver;
        const Color    &textcolor = Preferences::Settings.MainTextColor;
        //static IntRect  background(30, 20, 340, 200);

        /*330
        ADDRESS (8 * 6) = 48 + 10   = 58 + 20
        OLD (16 * 6 ) = 96 + 10     = 106 + 20
        NEW (16 * 6) = 96 + 10      = 106 + 20
                                    = 270 = 330*/

        int posY = 51;

        if (_currentSearch != nullptr)
        {
            std::string str = "Step: " + std::to_string(_currentSearch->Step);
            Renderer::DrawString((char *)str.c_str(), 37, posY, textcolor);
            str = "Hit(s): " + std::to_string(_currentSearch->ResultsCount);
            Renderer::DrawString((char *)str.c_str(), 37, posY, textcolor);
        }

        posY = 80;
        /*************     Columns headers    ********************************/
        /**/    // Name
        /**/    Renderer::DrawRect(35, 75, 78, 20, darkgrey);
        /**/    Renderer::DrawString((char *)"Address", 53, posY, black);
        /**/    posY = 80;
        /**/
        /**/    // New value
        /**/    Renderer::DrawRect(113, 75, 126, 20, darkgrey);
        /**/    Renderer::DrawString((char *)"New Value", 149, posY, black);
        /**/    posY = 80;
        /**/
        /**/    // OldValue
        /**/    Renderer::DrawRect(239, 75, 126, 20, darkgrey);
        /**/    Renderer::DrawString((char *)"Old Value", 275, posY, black);
        /**/
        /**********************************************************************/

        posY = 95;
        /*************************     Grid    ********************************/
        /**/    for (int i = 0; i < 10; i++)
        /**/    {
        /**/        const Color &c = i % 2 ? gainsboro : blank;
        /**/        Renderer::DrawRect(35, posY, 330, 10, c);
        /**/        posY += 10;
        /**/    }
        /**/
        /**********************************************************************/

        posY = 203;
        Renderer::DrawString((char *)"Options:", 260, posY, textcolor);
        posY -= 14;
        Renderer::DrawSysString((char *)"\uE002", 320, posY, 380, textcolor);

        if (_currentSearch == nullptr || _resultsAddress.size() == 0 || _resultsNewValue.size() == 0)
        {
            _submenu.Draw();
            return;
        }


        posY = 95;
        int posX1 = 47;
        int posX2 = 113;
        int posX3 = 239;

        int start = std::max((int)0, (int)_selector - 5);

        int end = std::min((int)_resultsAddress.size(), (int)(start + 10));

        for (int i = start; i < end; i++)
        {
            if (i >= _resultsAddress.size())
                return;

            // Selector
            if (i == _selector)
                Renderer::DrawRect(35, 95 + (i - start) * 10, 330, 10, silver);

            int pos = posX1;
            int posy = posY;

            // Address
            Renderer::DrawString((char *)_resultsAddress[i].c_str(), pos, posy, black);

            // newval
            posy = posY;
            std::string &nval = _resultsNewValue[i];
            pos = posX2 + (126 - (nval.size() * 6)) / 2;
            Renderer::DrawString((char *)nval.c_str(), pos, posy, black);

            if (i >= _resultsOldValue.size())
            {
                posY += 10;
                continue;
            }

            // oldval
            std::string &oval = _resultsOldValue[i];
            pos = posX3 + (126 - (oval.size() * 6)) / 2;
            Renderer::DrawString((char *)oval.c_str(), pos, posY, black);
        }

        start += _index;
        std::string str = std::to_string(start) + "-" + std::to_string(std::min((u32)(start + 10), (u32)_currentSearch->ResultsCount))
                    + " / " + std::to_string(_currentSearch->ResultsCount);
        posY = 196;
        Renderer::DrawString((char *)str.c_str(), 37, posY, textcolor);

        _submenu.Draw();
    }

    void    SearchMenu::Update(void)
    {
        _resultsAddress.clear();
        _resultsNewValue.clear();
        _resultsOldValue.clear();

        if (_currentSearch == nullptr)
        {
            _selector = 0;
            _index = 0;
            if (_submenu.OptionsCount() > 1)
                _submenu.ChangeOptions({ "Show game" });
            return;
        }

        if (_submenu.OptionsCount() == 1 && !_currentSearch->IsFirstUnknownSearch())
        {
            _submenu.ChangeOptions({ "Edit", "Jump in editor", "New cheat", "Export", "Export all", "Converter", "Show Game" });
        }

        if (_index + _selector >= _currentSearch->ResultsCount)
        {
            _index = 0;
            _selector = 0;
        }

        _currentSearch->ReadResults(_index, _resultsAddress, _resultsNewValue, _resultsOldValue);

        if (_selector >= _resultsAddress.size())
            _selector = 0;

        // If the results are empty try again from the start of the results
        if (_resultsAddress.empty() && _currentSearch->ResultsCount > 0)
        {
            _index = 0;
            _selector = 0;
            Update();
        }
    }

    void    SearchMenu::_OpenExportFile(void)
    {
        if (_export.IsOpen())
            return;

        if (File::Open(_export, "ExportedAddresses.txt", File::WRITE | File::APPEND))
        {
            File::Open(_export, "ExportedAddresses.txt", File::WRITE | File::CREATE);
        }
    }

    void    SearchMenu::_NewCheat(void)
    {
        u32         address = strtoul(_resultsAddress[_selector].c_str(), NULL, 16);
        u32         value = 0;
        u8          codetype = 0;
        SearchFlags type = _currentSearch->GetType();

        if (type == SearchFlags::U8)
        {
            codetype = 0x20;
            u8 val8 = 0;
            Process::Read8(address, val8);
            value = val8;
        }
        else if (type == SearchFlags::U16)
        {
            codetype = 0x10;
            u16 val16 = 0;
            Process::Read16(address, val16);
            value = val16;
        }
        else
            Process::Read32(address, value);

        PluginMenuActionReplay::NewARCode(codetype, address, value);

    }

    void    SearchMenu::_Edit(void)
    {
        Keyboard keyboard;

        keyboard.DisplayTopScreen = false;
		keyboard.IsHexadecimal(_useHexInput);

        u32 address = strtoul(_resultsAddress[_selector].c_str(), NULL, 16);

        switch (_currentSearch->GetType())
        {
            case SearchFlags::U8:
            {
                u8 value = *(u8 *)(address);//strtoul(_resultsNewValue[_selector].c_str(), NULL, 16);

                int res = keyboard.Open(value, value);

                if (res != -1)
                {
                    if (Process::CheckAddress(address))
                        *(u8 *)(address) = value;
                }
                break;
            }
            case SearchFlags::U16:
            {
                u16 value = *(u16 *)(address);//strtoul(_resultsNewValue[_selector].c_str(), NULL, 16);

                int res = keyboard.Open(value, value);

                if (res != -1)
                {
                    if (Process::CheckAddress(address))
                        *(u16 *)(address) = value;
                }
                break;
            }
            case SearchFlags::U32:
            {
                u32 value = *(u32 *)(address);//strtoul(_resultsNewValue[_selector].c_str(), NULL, 16);

                int res = keyboard.Open(value, value);

                if (res != -1)
                {
                    if (Process::CheckAddress(address))
                        *(u32 *)(address) = value;
                }
                break;
            }
          /*  case SearchFlags::U64:
            {
                u64 value = *(u64 *)(address);//strtoull(_resultsNewValue[_selector].c_str(), NULL, 16);

                int res = keyboard.Open(value, value);

                if (res != -1)
                {
                    if (Process::CheckAddress(address))
                        *(u64 *)(address) = value;
                }
                break;
            }*/
            case SearchFlags::Float:
            {
                float value = *(float *)(address);//strtof(_resultsNewValue[_selector].c_str(), NULL);

                int res = keyboard.Open(value, value);

                if (res != -1)
                {
                    if (Process::CheckAddress(address))
                        *(float *)(address) = value;
                }
                break;
            }
           /* case SearchFlags::Double:
            {
                double value = *(double *)(address);//strtod(_resultsNewValue[_selector].c_str(), NULL);

                int res = keyboard.Open(value, value);

                if (res != -1)
                {
                    if (Process::CheckAddress(address))
                        *(double *)(address) = value;
                }
                break;
            }*/
            default:
                break;
        }
    }

    void    SearchMenu::_JumpInEditor(void)
    {
        u32 address = strtoul(_resultsAddress[_selector].c_str(), NULL, 16);

        _hexEditor.Goto(address, true);
        _inEditor = true;
    }

    void    SearchMenu::_Export(void)
    {
        if (!_alreadyExported)
        {
            if (!_export.IsOpen())
                _OpenExportFile();
            _export.WriteLine("");
            time_t t = time(NULL);
            char *ct = ctime(&t);

            ct[strlen(ct)] = '\0';
            std::string text = ct;

            text += " :\r\n";
            _export.WriteLine(text);
            _alreadyExported = true;
        }
        std::string str = _resultsAddress[_selector] +" : " + _resultsNewValue[_selector];
        _export.WriteLine(str);
    }

    void    SearchMenu::_ExportAll(void)
    {
        if (!_alreadyExported)
        {
            if (!_export.IsOpen())
                _OpenExportFile();

            _export.WriteLine("");
           /* time_t t = time(NULL);
            char *ct = ctime(&t);

            ct[strlen(ct)] = '\0';
            std::string text = ct;

            text += " :\r\n";
            _export.WriteLine(text);*/
            _alreadyExported = true;
        }

        std::string out;

        for (int i = _selector; i < _selector + 10; i++)
        {
            if (i >= _resultsAddress.size())
                break;
            out += _resultsAddress[i] +" : " + _resultsNewValue[i] + "\r\n";
        }
        _export.Write(out.c_str(), out.size());
    }

    void    SearchMenu::_ShowGame(void)
    {
        MessageBox(Color::Green << "Info", "Press " FONT_B " to return to the menu.")();

        ScreenImpl::Clean();

        while (true)
        {
            Controller::Update();
            if (Controller::IsKeyPressed(Key::B))
                break;
        }

       /* float fade = 0.03f;
        Clock t = Clock();
        Time limit = Seconds(1) / 10.f;
        Time delta;
        float pitch = 0.0006f;

        while (fade <= 0.3f)
        {
            delta = t.Restart();
            fade += pitch * delta.AsMilliseconds();

            ScreenImpl::Top->Fade(fade);
            ScreenImpl::Bottom->Fade(fade);

            ScreenImpl::Top->SwapBuffer(true, true);
            ScreenImpl::Bottom->SwapBuffer(true, true);
            gspWaitForVBlank();
            if (System::IsNew3DS())
                while (t.GetElapsedTime() < limit);
        }*/
        ScreenImpl::ApplyFading();
    }
}
