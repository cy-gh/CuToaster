#Warn All
#Warn UseUnsetLocal, Off
#Warn LocalSameAsGlobal, Off

new cMain().Start()
return

class cMain {
    __New() {
        OutputDebug, Hello
        if (!A_Args.Length()) {
            ; no parameters or empty string passed
            _usageText =
            ( LTrim Join
                This CLI AHK script shows a so-called toast message which automatically disappears.`n
                It is best suited for calling from other programs, batch files, etc.`n`n

                Usage:`n
                CuToaster -|--OPTION[=]VALUE`n`n

                These parameters are accepted (defaults marked with *):`n`n
                * message (your message)`n
                * timeout (in ms, 3500*)`n
                * animDuration (fadeout time, 500*, 0 to disable)`n
                * posX (CENTER*, LEFT, RIGHT)`n
                * posY (CENTER, BOTTOM*, TOP)`n
                * fontName (Verdana)`n
                * fontSize (14)`n
                * fontWeight (100-900, 600*)`n
                * fgColor (RGB in Hex, 0xF9F1A5*)`n
                * bgColor (RGB in Hex, 0x2C2C2C*)`n
                * everyMon (false* if not specified)`n`n

                All parameters can be specified with single (-) or double dash (--). Equals sign (=) is optional.`n`n

                Sample:`n
                CuToaster -message "Long-running ""backup job"" finished!" -timeout 10000 -fontSize 36
            )
            MsgBox, , % "CuToaster", % _usageText
            ExitApp, 1
        }
        this.aDefinition:= [ "s=message"
                            , "i=timeout"
                            , "i=animDuration"
                            , "s=posX"
                            , "s=posY"
                            , "s=fontName"
                            , "i=fontSize"
                            , "i=fontWeight"
                            , "s=fgColor"
                            , "s=bgColor"
                            , "b!everyMon" ]
        this.oParams    := cGetOpt.GetLong(this.aDefinition, A_Args)
    }
    Start() {
        new cToast(this.oParams).Show(this.oParams.message)
    }
}

; cToast
/*
    88888888888  .d88888b.         d8888  .d8888b. 88888888888
        888     d88P" "Y88b       d88888 d88P  Y88b    888
        888     888     888      d88P888 Y88b.         888
        888     888     888     d88P 888  "Y888b.      888
        888     888     888    d88P  888     "Y88b.    888
        888     888     888   d88P   888       "888    888
        888     Y88b. .d88P  d8888888888 Y88b  d88P    888
        888      "Y88888P"  d88P     888  "Y8888P"     888
*/
class cToast {
    ; Credits to engunneer (http://www.autohotkey.com/board/topic/21510-toaster-popups/#entry140824)
    static AW_BLEND := 0x00080000
    static AW_HIDE  := 0x00010000
    __New(pParams := "") {
        this.message        := pParams.HasKey("message")        ? pParams.message       : ""
        this.timeout        := pParams.HasKey("timeout")        ? pParams.timeout       : 3500
        this.animDuration   := pParams.HasKey("animDuration")   ? pParams.animDuration  : 500           ; Watch out! Long durations (> 500ms) could cause troubles as the program freezes during the animation.
        this.posX           := pParams.HasKey("posX")           ? pParams.posX          : "CENTER"      ; One of LEFT, CENTER, RIGHT
        this.posY           := pParams.HasKey("posY")           ? pParams.posY          : "CENTER"      ; One of TOP, CENTER, BOTTOM
        this.fontName       := pParams.HasKey("fontName")       ? pParams.fontName      : "Verdana"
        this.fontSize       := pParams.HasKey("fontSize")       ? pParams.fontSize      : 14
        this.fontWeight     := pParams.HasKey("fontWeight")     ? pParams.fontWeight    : 600
        this.fgColor        := pParams.HasKey("fgColor")        ? pParams.fgColor       : "0xF9F1A5"
        this.bgColor        := pParams.HasKey("bgColor")        ? pParams.bgColor       : "0x2C2C2C"
        this.everyMon       := pParams.HasKey("everyMon")       ? pParams.everyMon      : false

        this.monCount       := this.everyMon ? this.MonitorGetCount() : 1
        this.guiNames       := []
        this.guiHandles     := []
        Loop, % this.monCount
        {
    		this.guiNames[A_Index]    := "ToastGUI_" A_Index
        }
    }
    ; Display a toast popup on each monitor
    Show(pMessage) {
        if(!this.monCount) {
            MsgBox, , A_ThisFunc, % "Do not call this method directly, initialize via new cToast() first"
            return
        }

    	fontSize    := this.fontSize
    	fontWeight  := this.fontWeight
    	fgColor     := this.fgColor
    	bgColor     := this.bgColor

    	_dhw_prev := this.DetectHiddenWindows(true)
    	; For each monitor we need to create and draw the GUI of the toast
    	Loop, % this.monCount
        {
    		_gui_name := this.guiNames[A_Index]
            _monres := this.MonitorGetWorkArea(A_Index)        ; AHK2-compatible functions defined in Function.ahk

    		Gui, %_gui_name%:Destroy
            Gui, %_gui_name%:-Caption +LastFound +ToolWindow +AlwaysOnTop
            Gui, %_gui_name%:Margin, 0 0
            Gui, %_gui_name%:Color, %bgColor%
            Gui, %_gui_name%:Font, c%fgColor% s%fontSize% w%fontWeight% q5, % this.fontName     ; q5 max, cleartype quality
            Gui, %_gui_name%:Add, Text, xp+25 yp+20, % pMessage
            Gui, %_gui_name%:Show, Hide NoActivate
            WinSet, Transparent, 0, % "ahk_id " this.guiHandles[A_Index]

            this.guiHandles[A_Index] := WinExist()

    		oCloseToastPopupFn := ObjBindMethod(this, "CloseToastPopup", _gui_name, this.guiHandles[A_Index])
    		OnMessage(0x201, oCloseToastPopupFn)

    		this.WinGetPos(GUIX, GUIY, GUIW, GUIH)

    		; GUIW := GUIW <= _monres.right - _monres.left - 20 ? GUIW + 20 : _monres.right - _monres.left
    		; GUIH := GUIH <= _monres.bottom - _monres.top - 15 ? GUIH + 15 : _monres.bottom - _monres.top
            GUIW += 20
    		GUIH += 15
            if (this.posX = "LEFT") {
                NewX := _monres.left
            } else if (this.posX = "RIGHT") {
                NewX := _monres.right - GUIW
            } else {
                NewX := Round((_monres.right + _monres.left - GUIW) / 2)
            }
            if (this.posY = "TOP") {
                NewY := _monres.top
            } else if (this.posY = "BOTTOM") {
                NewY := _monres.bottom - GUIH - 10
            } else {
                NewY := Round((_monres.top + _monres.bottom - GUIH) / 2)
            }
            Gui, %_gui_name%:Show, Hide NoActivate x%NewX% y%NewY% w%GUIW% h%GUIH%
            ; use either AnimateWindow or WinSet Transparent but not both
            ; if you use WinSet Transparent, the fadeout animation does not work either
            if (this.animDuration) {
                _dllres := DllCall("AnimateWindow", "UInt", pGUIHandle, "Int", this.animDuration, "UInt", cToast.AW_BLEND)
            }

            if (this.timeout) {
                this.SetTimer(oCloseToastPopupFn, -this.timeout)
            }
    	}
        this.DetectHiddenWindows(_dhw_prev)
    }
    CloseToastPopup(pGUIName, pGUIHandle) {
    	Loop, % this.monCount
        {
            if (this.animDuration) {
                _dllres := DllCall("AnimateWindow", "UInt", pGUIHandle, "Int", this.animDuration, "UInt", cToast.AW_BLEND | cToast.AW_HIDE)
            }
    		Gui, %pGUIName%:Destroy
    	}
        ExitApp
    }
    MonitorGetCount() {
        SysGet, v, MonitorCount
        return v
    }
    MonitorGetWorkArea(N := 0, ByRef Left := "", ByRef Top := "", ByRef Right := "", ByRef Bottom := "") {
        SysGet, v, MonitorWorkArea, %N%
        if (!vLeft && !vTop && !vRight && !vBottom) {
            return false
        }
        Left   := vLeft
        Top    := vTop
        Right  := vRight
        Bottom := vBottom
        _res   := { left: vLeft, right: vRight, top: vTop, bottom: vBottom }
        return _res
    }
    DetectHiddenWindows(pBool) {
        v := A_DetectHiddenWindows
        if (pBool) {
            DetectHiddenWindows, On
        } else {
            DetectHiddenWindows, Off
        }
        return v
    }
    WinGetPos(ByRef X := "", ByRef Y := "", ByRef Width := "", ByRef Height := "", WinTitle := "", WinText := "", ExcludeTitle := "", ExcludeText := "") {
        WinGetPos, X, Y, Width, Height, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
        return { l: X, t: Y, w: Width, h: Height}
    }
    SetTimer(pLabel, pPeriodOnOffDelete := "", pPriority := 0) {
        _period := pPeriodOnOffDelete
        if (this.Is(pPeriodOnOffDelete, "integer")) {
            _period := pPeriodOnOffDelete
        } else if (pPeriodOnOffDelete = "Off" || pPeriodOnOffDelete	= false) {
            _period := "Off"
        } else if (pPeriodOnOffDelete = "On" || pPeriodOnOffDelete	= true) {
            _period := "On"
        } else if (pPeriodOnOffDelete = "Delete") {
            _period := "Delete"
        }
        SetTimer, %pLabel%, %pPeriodOnOffDelete%, %pPriority%
    }
    Is(ByRef var, type) {
        If var is %type%
            Return, true
    }
} ; end class cToast



; cGetOptLong.ahk
/*
     .d8888b.  8888888888 88888888888  .d88888b.  8888888b. 88888888888
    d88P  Y88b 888            888     d88P" "Y88b 888   Y88b    888
    888    888 888            888     888     888 888    888    888
    888        8888888        888     888     888 888   d88P    888
    888  88888 888            888     888     888 8888888P"     888
    888    888 888            888     888     888 888           888
    Y88b  d88P 888            888     Y88b. .d88P 888           888
     "Y8888P88 8888888888     888      "Y88888P"  888           888
*/
class cGetOpt {
    static EXIT_WITH_WRONG_PARAMS       := 0x01
    static EXIT_WITH_MALFORMED_SYNTAX   := 0x02
    static EXIT_WITH_UNRECOGNIZED       := 0x03
    static EXIT_WITH_DUPLICATE          := 0x04
    static EXIT_MANDATORY_VAL_MISSING   := 0x05
    static EXIT_VALUE_INDETERMINATE     := 0x10

    class cUtil {
        ShowError(pMessage, pTitle := "", pExitCode := 0) {
            _title := pTitle ? pTitle : A_ThisFunc
            MsgBox,, % _title, % pMessage
            if (pExitCode) {
                ExitApp, % pExitCode
            }
        }
    }

    _GetArrayToUse(pParamsArray) {
        ; use the given array instead of A_Args (for tests, etc.)
        local _argsArr
        if (pParamsArray and pParamsArray.Length()) {
            _argsArr := pParamsArray
        } else if (A_Args.Length()) {
            _argsArr := A_Args.Clone()
        }
        if (!_argsArr.Length()) {
            cUtil.ShowError("Arguments array could not be determined"
                , A_ThisFunc
                , cGetOpt.EXIT_WITH_WRONG_PARAMS)
        }
        return _argsArr
    }

    _StripQuotes(pString) {
        return RegExReplace(pString, "^(""|')(.+)\1", "$2")
    }

    _SplitToTokensAndStripQuotes(pString) {
        _tokens     := StrSplit(pString, "=", " `t", 2)     ; split the value to max 2 parts
        _tokens[1]  := this._StripQuotes(_tokens[1])
        _tokens[2]  := this._StripQuotes(_tokens[2])
        return _tokens
    }

    GetLong(ByRef oDefinitionObject, pParamsArray := false) {
        _argsArr := this._GetArrayToUse(pParamsArray)

        ; PARSE
        ; build the definition object
        _outOptObj := {}
        for _def_idx, _def_obj in oDefinitionObject {
            ; find out the expected type of current definition
            if (!RegExMatch(_def_obj, "O)^(?P<type>[sifb*])(?P<count>[=:!+@%$])(?P<name>[a-zA-Z0-9_\-|+]+)", _oMatches)) {
                cUtil.ShowError("Malformed argument definition:`n" _def_obj
                    , A_ThisFunc
                    , cGetOpt.EXIT_WITH_MALFORMED_SYNTAX)
            }
            if (IsObject(_outOptObj[_oMatches.name]) && _outOptObj[_oMatches.name].HasKey("key")) {
                cUtil.ShowError("Duplicate argument definition:`n" _def_obj "`n" _outOptObj[_oMatches.name]["key"]
                    , A_ThisFunc
                    , cGetOpt.EXIT_WITH_DUPLICATE)
            }
            _outOptObj[_oMatches.name] := { "key": _oMatches.name, "type": _oMatches.type, "count": _oMatches.count, "used": false }
        }

        ; VALIDATE
        ; iterate over CLI arguments and try to find a matching definition
        enum_args := _argsArr._NewEnum()
        while (enum_args[_arg_idx, _arg_val]) {
            ; first argument is always assumed to be a name
            ; strip any preceeding - or --
            if (SubStr(_arg_val, 1, 2) == "--") {
                _arg_val := SubStr(_arg_val, 3)
            } else if (SubStr(_arg_val, 1, 1) == "-") {
                _arg_val := SubStr(_arg_val, 2)
            }

            ; check if value is directly appended to the name
            if (RegExMatch(_arg_val, "O)([^+ ]+)(\++)", _oIncremental)) {
                _arg_key := _oIncremental.Value(1)
                _arg_val := StrLen(_oIncremental.Value(2))
            } else {
                _argTokens := StrSplit(_arg_val, "=", , 2) ; max 2 parts
                _arg_key := _argTokens[1]
                _arg_val := _argTokens[2]
            }

            ; iterate over definition keys and check if the argument name is a known definition
            _def_found      := false
            for _def_key, _def_obj in _outOptObj {
                ; if the definition includes | we search with InStr, otherwise must be == match
                if (InStr(_def_key, "|") && InStr(_def_key, _arg_key) || _def_key == _arg_key) {
                    _def_found := true
                    ; delete old value so that we don't re-use multi-values (split with | )
                    _outOptObj.Delete(_def_key)
                    ; and insert new
                    _replace_obj      := _def_obj
                    _replace_obj.key  := _arg_key
                    _replace_obj.used := true
                    _outOptObj[_arg_key] := _replace_obj
                }
            }

            _current_val := false
            ; if there is a value attached to the key, use it, otherwise search for value(s) until we hit the next argument key
            if (_arg_val) {
                _current_val := _arg_val
                if (_outOptObj[_arg_key].count == "=") {                                    ; mandatory value
                    _outOptObj[_arg_key].value   := this._StripQuotes(_current_val)
                } else if (_outOptObj[_arg_key].count == ":") {                             ; optional value
                    _outOptObj[_arg_key].value   := this._StripQuotes(_current_val)
                } else if (_outOptObj[_arg_key].count == "!") {                             ; boolean
                    _outOptObj[_arg_key].value   := true
                } else if (_outOptObj[_arg_key].count == "+") {                             ; incrementable
                    _outOptObj[_arg_key].value   := _current_val
                } else if (_outOptObj[_arg_key].count == "@") {                             ; array
                    if (!_outOptObj[_arg_key].value)
                         _outOptObj[_arg_key].value := []
                    _outOptObj[_arg_key].value.push(this._StripQuotes(_current_val))
                } else if (_outOptObj[_arg_key].count == "%") {                             ; hash
                    if (!_outOptObj[_arg_key].value)
                         _outOptObj[_arg_key].value := {}
                    _tokens := this._SplitToTokensAndStripQuotes(_current_val)              ; split the value to max 2 parts
                    _outOptObj[_arg_key].value[_tokens[1]] := _tokens[2]
                } else {
                    cUtil.ShowError("Value type indeterminate for " _arg_key ":`n" "_current_val: " _current_val
                        , A_ThisFunc
                        , cGetOpt.EXIT_VALUE_INDETERMINATE)
                }
                _outOptObj[_arg_key].used   := true
            } else if (_outOptObj[_arg_key].count == "!") {                             ; boolean
                _outOptObj[_arg_key].value  := true
                _outOptObj[_arg_key].used   := true
            } else {
                _i := _arg_idx + 1
                ; search forewards from the next argument for a value
                while (_i <= _argsArr.Length()) {
                    _current_val := _argsArr[_i]
                    ; exit at first new key
                    if (SubStr(_current_val, 1, 1) == "-") {
                        if (_outOptObj[_arg_key].count == "=") {
                            ; mandatory value not found
                            cUtil.ShowError("Mandatory value not supplied for " _arg_key ":`n" "_current_val: " _current_val
                                , A_ThisFunc
                                , cGetOpt.EXIT_MANDATORY_VAL_MISSING)
                        }
                        break
                    }


                    if (_outOptObj[_arg_key].count == "=") {                                ; mandatory value
                        _outOptObj[_arg_key].value   := this._StripQuotes(_current_val)
                        enum_args[_arg_key, _arg_val]                                       ; skip this value, ignore enum return value
                        break
                    } else if (_outOptObj[_arg_key].count == ":") {                         ; optional value
                        _outOptObj[_arg_key].value   := this._StripQuotes(_current_val)
                        enum_args[_arg_key, _arg_val]                                       ; skip this value, ignore enum return value
                        break
                    } else if (_outOptObj[_arg_key].count == "!") {                         ; boolean

                        _outOptObj[_arg_key].value   := true
                    } else if (_outOptObj[_arg_key].count == "+") {                         ; incrementable
                        _outOptObj[_arg_key].value   := _current_val
                    } else if (_outOptObj[_arg_key].count == "@") {                         ; array
                        if (!_outOptObj[_arg_key].value)
                             _outOptObj[_arg_key].value := []
                        _outOptObj[_arg_key].value.push(this._StripQuotes(_current_val))
                        enum_args[_arg_key, _arg_val]                                       ; skip this value, ignore enum return value
                    } else if (_outOptObj[_arg_key].count == "%") {                         ; hash
                        if (!_outOptObj[_arg_key].value)
                             _outOptObj[_arg_key].value := {}
                        _tokens := this._SplitToTokensAndStripQuotes(_current_val)          ; split the value to max 2 parts
                        _outOptObj[_arg_key].value[_tokens[1]] := _tokens[2]
                        enum_args[_arg_key, _arg_val]                                       ; skip this value, ignore enum return value
                    } else {
                        cUtil.ShowError("Value type indeterminate for " _arg_key ":`n" "_current_val: " _current_val
                            , A_ThisFunc
                            , cGetOpt.EXIT_VALUE_INDETERMINATE)
                    }
                    _outOptObj[_arg_key].used := true
                    _i++
                }
            }

            if (!_def_found) {
                cUtil.ShowError("Unrecognized argument:`n" _argsArr[_arg_idx] "`nCannot continue", A_ThisFunc, cGetOpt.EXIT_WITH_UNRECOGNIZED)
            }
        }

        ; clean up: remove unused arguments
        _resObj := {}
        for _k, _o in _outOptObj {
            if (_o.used) {
                ;_outOptObj.Delete(_k)
                _resObj[_k] := _o.value
            }
        }
        return _resObj
    }
}
