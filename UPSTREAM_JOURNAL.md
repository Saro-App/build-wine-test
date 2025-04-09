## My attempts at building upstream wine 10.5
### attempt 1
- Using the same ./configure command causes it to not find the libraries properly
- Only happens during runtime, builds perfectly fine

### Attempt 2
- Using defining DYLD_FALLBACK_LIBRARY_PATH to Frameworks in wineskin wrapper causes it to take like 5 minutes, but it works.
- Using the dylibs in /usr/bin/lib also works, and also takes several minutes
- I think this is because of wineboot because it logs `0154:err:environ:run_wineboot boot event wait timed out`


### Notes
- "works" means notepad.exe starts properly
