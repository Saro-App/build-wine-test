Error: `configure: error: libgnutls 64-bit development files not found,  no schannel support.`

- https://forums.gentoo.org/viewtopic-p-8818894.html?sid=77ad69e49cdb837207d172ee5ecd044d
- https://forum.winehq.org/viewtopic.php?t=33196

`export PKG_CONFIG_PATH="/usr/local/Cellar/pkgconf/2.4.3/lib/pkgconfig/"`

Passing `--enable-win64` to configure does not help

Gonna try just passing CFLAGS/LDFLAGS with the pkgconfig directly

It's still getting the arm files???
```
configure:17039: checking for gnutls_cipher_init
configure:17039: arch -x86_64 cc -m64 -o conftest   -I/opt/homebrew/Cellar/gnutls/3.8.4/include -I/opt/homebrew/Cellar/nettle/3.10.1/include -I/opt/homebrew/Cellar/libtasn1/4.20.0/include -I/opt/homebrew/Cellar/libidn2/2.3.7/include -I/opt/homebrew/Cellar/p11-kit/0.25.5/include/p11-kit-1  conftest.c  -L/opt/homebrew/Cellar/gnutls/3.8.4/lib -lgnutls >&5
ld: warning: ignoring file '/opt/homebrew/Cellar/gnutls/3.8.4/lib/libgnutls.30.dylib': found architecture 'arm64', required architecture 'x86_64'
Undefined symbols for architecture x86_64:
  "_gnutls_cipher_init", referenced from:
      _main in conftest-794f47.o
ld: symbol(s) not found for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
configure:17039: $? = 1
```

Using `export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"` got it past the configure stage. It's in the make stage.
I have no hope it'll work.

Also gonna try `-j$(sysctl -n hw.logicalcpu)` if it makes it faster

Got it working, it even built in CI.
Next need to actually upload more artifacts, build for win64, figure out why stuff like --with-pcap works when we dont install libpcap

Also need to get libinotify and gstreamer working

Also working on gecko and mono


next we need to work on:
- gecko/mono -- I added these but idk if they work
- libinotify (gcenx's portfile for inotify)
- gstreamer (gcenx's portfile for wine-devel)
- all the graphics translations stuff

```
/bin/sh silicon-driver.sh /Users/ethan/gh/build-wine-test/sources/wine/.testprefix
cd sources/wine
make install
```
Then inside prefix
```
WINEDEBUG="+loaddll" WINEPREFIX="/Users/ethan/gh/build-wine-test/sources/wine/.testprefix" ./bin/wine64 winecfg 
WINEDEBUG="+loaddll" WINEPREFIX="/Users/ethan/gh/build-wine-test/sources/wine/.testprefix" ./bin/wine64 wineboot
```
Trying to see if wow64 will fix.

Also complaints that no freetype exists. Fixed pkg-config bad CPU type in build and added freetype2 to its arguments

Be careful if you accidently install arm freetype

I am hard coding the path to the dylib now in wine source
Getting format message failed though

```
make -j8 && make install -j8 && WINEDEBUG="+loaddll" WINEPREFIX="/Users/ethan/gh/build-wine-test/sources/wine/.testprefix" WINEPATH="/Users/ethan/gh/build-wine-test/sources/wine/.testprefix/lib/wine/x86_64-windows" .testprefix/bin/wine winecfg
```

Hardcode freetype dylib in dlls/win32u/freetype.c
dlls/ntdll/unix/env.c is where wineboot fails

_sigh_ I've isolated the error to creating the wineboot process:

```c
printf("actually cooked");
        status = NtCreateUserProcess( &process, &thread, PROCESS_ALL_ACCESS, THREAD_ALL_ACCESS,
                                      NULL, NULL, 0, THREAD_CREATE_FLAGS_CREATE_SUSPENDED, &params,
                                      &create_info, &ps_attr );
printf("%ld is like super sus", status);
```
`actually cooked1 is like super sus`

I don't know if this is relevant https://list.winehq.org/mailman3/hyperkitty/list/wine-bugs%40winehq.org/thread/TNPD7M66W27YIO3GE5F45GAYOQXK4UTI/

Isolated to `NtCreateUserProcess`
Asked chat to give me version with logging

```c
NTSTATUS WINAPI
NtCreateUserProcess(HANDLE *process_handle_ptr, HANDLE *thread_handle_ptr,
                    ACCESS_MASK process_access, ACCESS_MASK thread_access,
                    OBJECT_ATTRIBUTES *process_attr,
                    OBJECT_ATTRIBUTES *thread_attr, ULONG process_flags,
                    ULONG thread_flags, RTL_USER_PROCESS_PARAMETERS *params,
                    PS_CREATE_INFO *info, PS_ATTRIBUTE_LIST *ps_attr) {
  printf("NtCreateUserProcess: Entered function.\n");

  unsigned int status;
  BOOL success = FALSE;
  HANDLE file_handle, process_info = 0, process_handle = 0, thread_handle = 0;
  struct object_attributes *objattr;
  data_size_t attr_len;
  char *winedebug = NULL;
  struct startup_info_data *startup_info = NULL;
  ULONG startup_info_size, env_size;
  int unixdir, socketfd[2] = {-1, -1};
  struct pe_image_info pe_info;
  CLIENT_ID id;
  USHORT machine = 0;
  HANDLE parent = 0, debug = 0, token = 0;
  UNICODE_STRING redir, path = {0};
  OBJECT_ATTRIBUTES attr, empty_attr = {sizeof(empty_attr)};
  SIZE_T i, attr_count = (ps_attr->TotalLength - sizeof(ps_attr->TotalLength)) /
                         sizeof(PS_ATTRIBUTE);
  const PS_ATTRIBUTE *handles_attr = NULL, *jobs_attr = NULL;
  data_size_t handles_size, jobs_size;
  obj_handle_t *handles, *jobs;

  printf("NtCreateUserProcess: attr_count = %zu\n", attr_count);

  if (thread_flags & THREAD_CREATE_FLAGS_HIDE_FROM_DEBUGGER) {
    WARN("Invalid thread flags %#x.\n", (int)thread_flags);
    return STATUS_INVALID_PARAMETER;
  }

  if (thread_flags & ~THREAD_CREATE_FLAGS_CREATE_SUSPENDED)
    FIXME("Unsupported thread flags %#x.\n", (int)thread_flags);

  for (i = 0; i < attr_count; i++) {
    printf("Processing attribute %zu: type 0x%lx, size %lu\n", i,
           ps_attr->Attributes[i].Attribute,
           (unsigned long)ps_attr->Attributes[i].Size);
    switch (ps_attr->Attributes[i].Attribute) {
    case PS_ATTRIBUTE_PARENT_PROCESS:
      parent = ps_attr->Attributes[i].ValuePtr;
      printf("Set parent process: %p\n", parent);
      break;
    case PS_ATTRIBUTE_DEBUG_PORT:
      debug = ps_attr->Attributes[i].ValuePtr;
      printf("Set debug port: %p\n", debug);
      break;
    case PS_ATTRIBUTE_IMAGE_NAME:
      path.Length = ps_attr->Attributes[i].Size;
      path.Buffer = ps_attr->Attributes[i].ValuePtr;
      printf("Set image name: %.*S\n", (int)(path.Length/sizeof(WCHAR)), path.Buffer);
      break;
    case PS_ATTRIBUTE_TOKEN:
      token = ps_attr->Attributes[i].ValuePtr;
      printf("Set token: %p\n", token);
      break;
    case PS_ATTRIBUTE_HANDLE_LIST:
      if (process_flags & PROCESS_CREATE_FLAGS_INHERIT_HANDLES) {
        handles_attr = &ps_attr->Attributes[i];
        printf("Set handle list attribute.\n");
      }
      break;
    case PS_ATTRIBUTE_JOB_LIST:
      jobs_attr = &ps_attr->Attributes[i];
      printf("Set job list attribute.\n");
      break;
    case PS_ATTRIBUTE_MACHINE_TYPE:
      machine = ps_attr->Attributes[i].Value;
      printf("Set machine type: 0x%x\n", machine);
      break;
    default:
      if (ps_attr->Attributes[i].Attribute & PS_ATTRIBUTE_INPUT)
        FIXME("unhandled input attribute %lx\n",
              ps_attr->Attributes[i].Attribute);
      break;
    }
  }
  if (!process_attr)
    process_attr = &empty_attr;

  TRACE("%s image %s cmdline %s parent %p machine %x\n", debugstr_us(&path),
        debugstr_us(&params->ImagePathName), debugstr_us(&params->CommandLine),
        parent, machine);

  unixdir = get_unix_curdir(params);
  printf("Unix directory descriptor: %d\n", unixdir);

  InitializeObjectAttributes(&attr, &path, OBJ_CASE_INSENSITIVE, 0, 0);
  get_redirect(&attr, &redir);
  printf("Redirect obtained, redir.Buffer=%p\n", redir.Buffer);

  if ((status = get_pe_file_info(&attr, &file_handle, &pe_info))) {
    printf("get_pe_file_info returned status 0x%x\n", status);
    if (status == STATUS_INVALID_IMAGE_NOT_MZ &&
        !fork_and_exec(&attr, unixdir, params)) {
      memset(info, 0, sizeof(*info));
      free(redir.Buffer);
      printf("Process created via fork_and_exec; returning success.\n");
      return STATUS_SUCCESS;
    }
    goto done;
  }
  if (!machine) {
    machine = pe_info.machine;
    printf("Machine type defaulted to 0x%x\n", machine);
    if (is_arm64ec() && pe_info.is_hybrid &&
        machine == IMAGE_FILE_MACHINE_ARM64) {
      machine = main_image_info.Machine;
      printf("Adjusted machine type for ARM64EC: 0x%x\n", machine);
    }
  }
  if (!(startup_info =
            create_startup_info(attr.ObjectName, process_flags, params,
                                &pe_info, &startup_info_size))) {
    printf("create_startup_info failed.\n");
    goto done;
  }
  printf("Startup info created, size %lu\n", startup_info_size);
  env_size = get_env_size(params, &winedebug);
  printf("Environment size: %lu, winedebug: %s\n", env_size, winedebug ? winedebug : "(null)");

  if ((status = alloc_object_attributes(process_attr, &objattr, &attr_len))) {
    printf("alloc_object_attributes(process_attr) failed with status 0x%x\n", status);
    goto done;
  }

  if ((status = alloc_handle_list(handles_attr, &handles, &handles_size))) {
    printf("alloc_handle_list(handles) failed with status 0x%x\n", status);
    free(objattr);
    goto done;
  }

  if ((status = alloc_handle_list(jobs_attr, &jobs, &jobs_size))) {
    printf("alloc_handle_list(jobs) failed with status 0x%x\n", status);
    free(objattr);
    free(handles);
    goto done;
  }

  /* create the socket for the new process */
  printf("Creating socketpair...\n");
  if (socketpair(PF_UNIX, SOCK_STREAM, 0, socketfd) == -1) {
    printf("socketpair failed.\n");
    status = STATUS_TOO_MANY_OPENED_FILES;
    free(objattr);
    free(handles);
    free(jobs);
    goto done;
  }
#ifdef SO_PASSCRED
  else {
    int enable = 1;
    setsockopt(socketfd[0], SOL_SOCKET, SO_PASSCRED, &enable, sizeof(enable));
    printf("SO_PASSCRED set on socketfd[0].\n");
  }
#endif

  wine_server_send_fd(socketfd[1]);
  printf("Socket fd %d sent to wine server.\n", socketfd[1]);

  /* create the process on the server side */
  SERVER_START_REQ(new_process) {
    printf("Sending new_process request to wine server...\n");
    req->token = wine_server_obj_handle(token);
    req->debug = wine_server_obj_handle(debug);
    req->parent_process = wine_server_obj_handle(parent);
    req->flags = process_flags;
    req->socket_fd = socketfd[1];
    req->access = process_access;
    req->machine = machine;
    req->info_size = startup_info_size;
    req->handles_size = handles_size;
    req->jobs_size = jobs_size;
    wine_server_add_data(req, objattr, attr_len);
    wine_server_add_data(req, handles, handles_size);
    wine_server_add_data(req, jobs, jobs_size);
    wine_server_add_data(req, startup_info, startup_info_size);
    wine_server_add_data(req, params->Environment, env_size);
    if (!(status = wine_server_call(req))) {
      process_handle = wine_server_ptr_handle(reply->handle);
      id.UniqueProcess = ULongToHandle(reply->pid);
      printf("New process created: pid=%u\n", reply->pid);
    }
    process_info = wine_server_ptr_handle(reply->info);
    printf("Process info handle received: %p\n", process_info);
  }
  SERVER_END_REQ;
  close(socketfd[1]);
  free(objattr);
  free(handles);
  free(jobs);

  if (status) {
    switch (status) {
    case STATUS_INVALID_IMAGE_WIN_64:
      ERR("64-bit application %s not supported in 32-bit prefix\n",
          debugstr_us(&path));
      break;
    case STATUS_INVALID_IMAGE_FORMAT:
      ERR("%s not supported on this installation (machine %04x)\n",
          debugstr_us(&path), pe_info.machine);
      break;
    }
    printf("Server returned error status: 0x%x\n", status);
    goto done;
  }

  if ((status = alloc_object_attributes(thread_attr, &objattr, &attr_len)))
    goto done;

  SERVER_START_REQ(new_thread) {
    printf("Sending new_thread request to wine server...\n");
    req->process = wine_server_obj_handle(process_handle);
    req->access = thread_access;
    req->flags = thread_flags;
    req->request_fd = -1;
    wine_server_add_data(req, objattr, attr_len);
    if (!(status = wine_server_call(req))) {
      thread_handle = wine_server_ptr_handle(reply->handle);
      id.UniqueThread = ULongToHandle(reply->tid);
      printf("New thread created: tid=%u\n", reply->tid);
    }
  }
  SERVER_END_REQ;
  free(objattr);
  if (status)
    goto done;

  /* create the child process */
  printf("Spawning child process...\n");
  if ((status =
           spawn_process(params, socketfd[0], unixdir, winedebug, &pe_info)))
    goto done;

  close(socketfd[0]);
  socketfd[0] = -1;

  /* wait for the new process info to be ready */
  printf("Waiting for process info...\n");
  NtWaitForSingleObject(process_info, FALSE, NULL);
  SERVER_START_REQ(get_new_process_info) {
    req->info = wine_server_obj_handle(process_info);
    wine_server_call(req);
    success = reply->success;
    status = reply->exit_code;
    printf("Process info received: success=%d, exit_code=0x%x\n", success, status);
  }
  SERVER_END_REQ;

  if (!success) {
    if (!status)
      status = STATUS_INTERNAL_ERROR;
    printf("Process creation failed with status 0x%x\n", status);
    goto done;
  }

  TRACE("%s pid %04x tid %04x handles %p/%p\n", debugstr_us(&path),
        (int)HandleToULong(id.UniqueProcess),
        (int)HandleToULong(id.UniqueThread), process_handle, thread_handle);

  /* update output attributes */

  for (i = 0; i < attr_count; i++) {
    switch (ps_attr->Attributes[i].Attribute) {
    case PS_ATTRIBUTE_CLIENT_ID: {
      SIZE_T size = min(ps_attr->Attributes[i].Size, sizeof(id));
      memcpy(ps_attr->Attributes[i].ValuePtr, &id, size);
      if (ps_attr->Attributes[i].ReturnLength)
        *ps_attr->Attributes[i].ReturnLength = size;
      break;
    }
    case PS_ATTRIBUTE_IMAGE_INFO: {
      SECTION_IMAGE_INFORMATION info;
      SIZE_T size = min(ps_attr->Attributes[i].Size, sizeof(info));
      virtual_fill_image_information(&pe_info, &info);
      memcpy(ps_attr->Attributes[i].ValuePtr, &info, size);
      if (ps_attr->Attributes[i].ReturnLength)
        *ps_attr->Attributes[i].ReturnLength = size;
      break;
    }
    case PS_ATTRIBUTE_TEB_ADDRESS:
    default:
      if (!(ps_attr->Attributes[i].Attribute & PS_ATTRIBUTE_INPUT))
        FIXME("unhandled output attribute %lx\n",
              ps_attr->Attributes[i].Attribute);
      break;
    }
  }
  *process_handle_ptr = process_handle;
  *thread_handle_ptr = thread_handle;
  process_handle = thread_handle = 0;
  status = STATUS_SUCCESS;

done:
  printf("NtCreateUserProcess: Cleaning up and exiting with status 0x%x\n", status);
  if (file_handle)
    NtClose(file_handle);
  if (process_info)
    NtClose(process_info);
  if (process_handle)
    NtClose(process_handle);
  if (thread_handle)
    NtClose(thread_handle);
  if (socketfd[0] != -1)
    close(socketfd[0]);
  if (unixdir != -1)
    close(unixdir);
  free(startup_info);
  free(winedebug);
  free(redir.Buffer);
  return status;
}

```

We get:

```
actually cookedNtCreateUserProcess: Entered function.
NtCreateUserProcess: attr_count = 1
Processing attribute 0: type 0x20005, size 72
0024:err:environ:run_wineboot failed to start wineboot 1
```
This attribute is `PS_ATTRIBUTE_IMAGE_NAME`

ChatGPT rwote some undefined behavior in a printf along this. Now I get:

```
NtCreateUserProcess: Entered function.
NtCreateUserProcess: attr_count = 4
Processing attribute 0: type 0x20005, size 70
testing testing 123
Processing attribute 1: type 0x10003, size 16
Processing attribute 2: type 0x6, size 64
Processing attribute 3: type 0x2000b, size 8
Set handle list attribute.
Unix directory descriptor: 10
Redirect obtained, redir.Buffer=0x0
get_pe_file_info returned status 0xc0000034
NtCreateUserProcess: Cleaning up and exiting with status 0xc0000034
(null)
0024:trace:loaddll:build_module Loaded L"Z:\\Users\\ethan\\gh\\build-wine-test\\sources\\wine\\.testprefix\\lib\\wine\\x86_64-windows\\imm32.dll" at 00006FFFFD080000: builtin
NtCreateUserProcess: Entered function.
NtCreateUserProcess: attr_count = 3
Processing attribute 0: type 0x20005, size 196
testing testing 123
Processing attribute 1: type 0x10003, size 16
Processing attribute 2: type 0x6, size 64
Unix directory descriptor: 10
Redirect obtained, redir.Buffer=0x0
Machine type defaulted to 0x8664
Startup info created, size 760
Environment size: 5312, winedebug: WINEDEBUG=+trace,+loaddll
Creating socketpair...
Socket fd 11 sent to wine server.
Sending new_process request to wine server...
New process created: pid=48
Process info handle received: 0x70
Sending new_thread request to wine server...
New thread created: tid=52
Spawning child process...
Waiting for process info...
Process info received: success=0, exit_code=0x1
Process creation failed with status 0x1
NtCreateUserProcess: Cleaning up and exiting with status 0x1
0024:err:start:fatal_error FormatMessage failed
```

Modded it to print image name:
`image name: \??\C:\windows\system32\wineboot.exe`

So going to copy it into there
```sh
cp programs/wineboot/i386-windows/wineboot.exe .testprefix/drive_c/windows/system32/
WINEDEBUG="+trace,+loaddll" WINEPREFIX="/Users/ethan/gh/build-wine-test/sources/wine/.testprefix" WINEPATH="/Users/ethan/gh/build-wine-test/sources/wine/.testprefix/lib/wine/x86_64-windows" .testprefix/bin/wine start programs/winecfg/x86_64-windows/winecfg.exe
```

Running from the directory gives:

```
$ WINEDEBUG="+trace,+loaddll" WINEPREFIX="/Users/ethan/gh/build-wine-test/sources/wine/.testprefix" WINEPATH="/Users/ethan/gh/build-wine-test/sources/wine/.testprefix/lib/wine/x86_64-windows" ../../../bin/wine wineboot.exe
test
actually cookedNtCreateUserProcess: Entered function.
NtCreateUserProcess: attr_count = 1
Processing attribute 0: type 0x20005, size 72
testing testing 123 36
image name: \??\C:\windows\system32\wineboot.exe
0024:err:environ:run_wineboot failed to start wineboot 1
0024:err:environ:init_peb starting L"C:\\windows\\system32\\wineboot.exe" in experimental wow64 mode
0024:err:module:init_wow64 could not load L"C:\\windows\\system32\\wow64.dll", status c0000135
```

Copied in wow dll:

```
[I] ~/g/b/s/w/.t/l/w/x86_64-windows (main|✚1) $ cp wow64.dll ../../../drive_c/windows/system32/
[I] ~/g/b/s/w/.t/l/w/x86_64-windows (main|✚1) $ z -
[I] ~/g/b/s/wine (main|✚1) $ z system
[I] ~/g/b/s/w/.t/d/w/system32 (main|✚1) $ WINEDEBUG="+trace,+loaddll" WINEPREFIX="/Users/ethan/gh/build-wine-test/sources/wine/.testprefix" WINEPATH="/Users/ethan/gh/build-wine-test/sources/wine/.testprefix/lib/wine/x86_64-windows" ../../../bin/wine wineboot.exe
test
actually cookedNtCreateUserProcess: Entered function.
NtCreateUserProcess: attr_count = 1
Processing attribute 0: type 0x20005, size 72
testing testing 123 36
image name: \??\C:\windows\system32\wineboot.exe
0024:err:environ:run_wineboot failed to start wineboot 1
0024:err:environ:init_peb starting L"C:\\windows\\system32\\wineboot.exe" in experimental wow64 mode
0024:trace:loaddll:build_module Loaded L"C:\\windows\\system32\\wow64.dll" at 00006FFFFFAD0000: builtin
0024:err:wow:load_64bit_module failed to load dll c0000135

```
