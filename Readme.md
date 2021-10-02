# What Is It?

This CLI AHK script shows a so-called toast message which automatically disappears.
It is best suited for calling from other programs, batch files, etc.

I built this script by scraping my private libraries (mainly cToast, cGetOpt),
so some portions might look superfluous or overly complex.

## Usage

These parameters are accepted (defaults marked with *):

* **message** (your message)
* **timeout** (in ms, 3500*)
* **animDuration** (fadeout time, 500*, 0 to disable)
* **posX** (CENTER*, LEFT, RIGHT)
* **posY** (CENTER, BOTTOM*, TOP)
* **fontName** (Verdana)
* **fontSize** (14)
* **fontWeight** (100-900, 600*)
* **fgColor** (RGB in Hex, 0xF9F1A5*)
* **bgColor** (RGB in Hex, 0x2C2C2C*)
* **everyMon** (false* if not specified)

All parameters can be specified with single (-) or double dash (--). Equals sign (=) is optional.

```batch
cuToaster -message "Hello ""World"" with double quotes" -fontName "Times New Roman" -posX=CENTER -posY BOTTOM -animDuration 0
```

*Note*: If your program, script, batch, etc. needs to continue immediately
without waiting this script to hide the toast text, you might want to use
"start" or similar techniques, e.g. in a .cmd/.bat file:

```batch
rem do something long running
start CuToaster -message "Operation finished!"
rem do something else
```

# License

(c) cuneytyilmaz.com 2021

Homepage: https://github.com/cy-gh/CuToaster

Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)

https://creativecommons.org/licenses/by-sa/4.0/

# Related

If you need standard Windows style balloon tips instead, check out:

* https://www.nirsoft.net/utils/nircmd.html - TrayBalloon command
* https://resource.dopus.com/t/how-to-show-a-user-message-that-automatically-disappears/18448/4?u=cyilmaz

# Credits

Basic idea for cToast from engunneer's script at http://www.autohotkey.com/board/topic/21510-toaster-popups/#entry140824
which I wrapped with multi-monitor, CLI parameters, etc. support

Toast icon: https://desciclopedia.org/wiki/Arquivo:Toast.png

Figlets by: https://textart.io/figlet?font=colossal
