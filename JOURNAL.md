## My attempts at building upstream wine 10.5
### attempt 1
- Using the same ./configure command causes it to not find the libraries properly
- Only happens during runtime, builds perfectly fine

### Attempt 2
- Using defining DYLD_FALLBACK_LIBRARY_PATH to Frameworks in wineskin wrapper causes it to take like 5 minutes, but it works.
- Using the dylibs in /usr/bin/lib also works, and also takes several minutes
- I think this is because of wineboot because it logs `0154:err:environ:run_wineboot boot event wait timed out`

### Attempt 3
- Change nothing from step 2, but the wineboot wait times have disappeared for an unexplainable reason


### Notes
- "works" means notepad.exe starts properly

`002c:err:winediag:getaddrinfo Failed to resolve your host name IP` happens lol.
See https://forum.winehq.org/viewtopic.php?p=146757

when I built into a custom prefix, I got:
`0140:err:module:dlopen_dll invalid .so library "/Users/ethan/gh/build-wine-test/testprefix/dosdevices/z:/Users/ethan/gh/build-wine-test/testprefix/bin/winecfg", too old?`
Melon suggested I just remake the prefix

Idk

inotify: https://github.com/NixOS/nixpkgs/blob/1750f3c1c89488e2ffdd47cab9d05454dddfb734/pkgs/by-name/li/libinotify-kqueue/package.nix#L44


### To-do
- Graphics drivers (vkd3d, moltenvkcx, dxmt, possibly d3dmetal)
- Esync & Msync


### Mono: fixing wineboot
- We originally got a wineboot time out event, because apparently there is a prompt to install mono, but it is hidden because it is silent
- This was fixed by actually just updating the version of mono so that it would be detected
