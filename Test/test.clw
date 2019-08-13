  PROGRAM

!  PRAGMA('project(#pragma define(_SVDllMode_ => 0))')
!  PRAGMA('project(#pragma define(_SVLinkMode_ => 1))')

  INCLUDE('cwcefex.inc'), ONCE
  INCLUDE('abresize.inc'), ONCE

  MAP
    MainAppFrame()
    ShowBrowser()
  END


  CODE
  MainAppFrame()
  
MainAppFrame                  PROCEDURE()
AppFrame                        APPLICATION('Application'),AT(,,682,447),CENTER,MASK,SYSTEM,MAX, |
                                  ICON('WAFRAME.ICO'),STATUS(-1,80,120,45),FONT('Segoe UI',9),RESIZE
                                  MENUBAR,USE(?Menubar)
                                    MENU('&File'),USE(?FileMenu)
                                      ITEM('&Print Setup ...'),USE(?PrintSetup),MSG('Setup printer'), |
                                        STD(STD:PrintSetup)
                                      ITEM(''),SEPARATOR,USE(?SEPARATOR1)
                                      ITEM('E&xit'),USE(?Exit),MSG('Exit this application'),STD(STD:Close)
                                    END
                                    MENU('&Edit'),USE(?EditMenu)
                                      ITEM('Cu&t'),USE(?Cut),MSG('Remove item to Windows Clipboard'),STD(STD:Cut)
                                      ITEM('&Copy'),USE(?Copy),MSG('Copy item to Windows Clipboard'),STD(STD:Copy)
                                      ITEM('&Paste'),USE(?Paste),MSG('Paste contents of Windows Clipboard'), |
                                        STD(STD:Paste)
                                    END
                                    MENU('&Window'),USE(?WindowMenu),STD(STD:WindowList)
                                      ITEM('T&ile'),USE(?Tile),MSG('Make all open windows visible'), |
                                        STD(STD:TileWindow)
                                      ITEM('&Cascade'),USE(?Cascade),MSG('Stack all open windows'),STD(STD:CascadeWindow) |
            
                                      ITEM('&Arrange Icons'),USE(?Arrange),MSG('Align all window icons'), |
                                        STD(STD:ArrangeIcons)
                                    END
                                    MENU('&Help'),USE(?HelpMenu)
                                      ITEM('&Contents'),USE(?Helpindex),MSG('View the contents of the help file'), |
                                        STD(STD:HelpIndex)
                                      ITEM('&Search for Help On...'),USE(?HelpSearch),MSG('Search for help on ' & |
                                        'a subject'),STD(STD:HelpSearch)
                                      ITEM('&How to Use Help'),USE(?HelpOnHelp),MSG('How to use Windows Help'), |
                                        STD(STD:HelpOnHelp)
                                    END
                                  END
                                  TOOLBAR,AT(0,0,682,21),USE(?TOOLBAR1)
                                    BUTTON('Open Browser'),AT(11,2),USE(?bShowBrowser)
                                  END
                                END
   
cef                             TCefRuntime

  CODE
  OPEN(AppFrame)

  IF cef.Init() <> S_OK
    HALT()
  END
  
  !- set CEF properties before Initialize call
  
  
  !- redirect log to subfolder CWCEF\debug.log
  cef.SetLogFile('.\CWCEF\debug.log')
  
  !- create GPUCache in subfolder
  cef.SetCachePath('.\CWCEF')
  
  !- change CEF locale to Russian
  cef.SetLocale('ru')

  !- initialize CEF
  cef.Initialize()

  ACCEPT
    CASE ACCEPTED()
    OF ?bShowBrowser
      START(ShowBrowser)
    END
  END
    
  !- shutdown CEF
  cef.Shutdown()
  cef.Kill()

ShowBrowser                   PROCEDURE()
url                             STRING(255)

Window                          WINDOW('CWCEF test'),AT(,,454,307),GRAY,SYSTEM,FONT('Segoe UI',9),IMM,RESIZE,MDI
                                  REGION,AT(14,21,423,255),USE(?PANEL1)
                                  BUTTON('Back'),AT(14,2),USE(?bBack),DISABLE
                                  PROMPT('Address:'),AT(59,6),USE(?PROMPT1)
                                  ENTRY(@s255),AT(89,4,265),USE(url)
                                  BUTTON('Go!'),AT(358,3),USE(?bGo),DEFAULT
                                  BUTTON('Close'),AT(398,284,39),USE(?bClose),STD(STD:Close)
                                END

browser                         CLASS(TCefBrowser)
OnAddressChanged                  PROCEDURE(STRING pAddress), PROTECTED, DERIVED
OnLoadingStateChanged             PROCEDURE(BOOL pCanGoBack, BOOL pCanGoForward, BOOL pIsLoading, BOOL pCanReload), PROTECTED, DERIVED
OnTitleChanged                    PROCEDURE(STRING pTitle), PROTECTED, DERIVED
                                END

Resizer                         WindowResizeClass
  CODE
  !- initial url
  url = 'https://github.com/mikeduglas?tab=repositories'
 
  OPEN(Window)
  
  !- set resizer
  Window{PROP:MinWidth} = 450
  Window{PROP:MinHeight} = 200
  
  Resizer.Init(AppStrategy:Surface)
  Resizer.SetStrategy(?PANEL1, Resize:FixLeft+Resize:FixTop, Resize:ConstantRight + Resize:ConstantBottom)
  
  !- init browser
  browser.InitControl(Window, ?PANEL1)
  browser.Unlock('Mike, unlock me please!')

  !- load default url
  POST(EVENT:Accepted, ?bGo)

  ACCEPT
    CASE EVENT()
    OF EVENT:Sized
      Resizer.Resize()
    END
    
    CASE ACCEPTED()
    OF ?bBack
      browser.Back()
    OF ?bGo
      browser.LoadUrl(CLIP(url))
    END
  END
  
  browser.KillControl()
  
browser.OnAddressChanged      PROCEDURE(STRING pAddress)
  CODE
  !- change address string
  CHANGE(?url, pAddress)
  
browser.OnLoadingStateChanged PROCEDURE(BOOL pCanGoBack, BOOL pCanGoForward, BOOL pIsLoading, BOOL pCanReload)
  CODE
  IF NOT pIsLoading
    !- disable Back button if CanGoBack = false
    ?bBack{PROP:Disable} = CHOOSE(NOT SELF.CanGoBack())
  END
  
browser.OnTitleChanged        PROCEDURE(STRING pTitle)
  CODE
  Window{PROP:Text} = pTitle