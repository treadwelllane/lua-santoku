      #include "lua.h"
      #include "lualib.h"
      #include "lauxlib.h"
    unsigned char data[] = {
  0x1b, 0x4c, 0x75, 0x61, 0x54, 0x00, 0x19, 0x93, 0x0d, 0x0a, 0x1a, 0x0a,
  0x04, 0x08, 0x08, 0x78, 0x56, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x28, 0x77, 0x40, 0x01, 0x80, 0x80, 0x80, 0x00,
  0x01, 0x06, 0x91, 0x51, 0x00, 0x00, 0x00, 0x0b, 0x00, 0x00, 0x00, 0x83,
  0x80, 0x00, 0x00, 0x44, 0x00, 0x02, 0x02, 0x8b, 0x00, 0x00, 0x00, 0x03,
  0x01, 0x01, 0x00, 0xc4, 0x00, 0x02, 0x02, 0x0e, 0x01, 0x01, 0x03, 0x44,
  0x01, 0x01, 0x02, 0x8e, 0x01, 0x00, 0x04, 0x00, 0x02, 0x02, 0x00, 0x83,
  0x82, 0x02, 0x00, 0xc4, 0x01, 0x03, 0x02, 0x94, 0x81, 0x03, 0x06, 0xcf,
  0x02, 0x00, 0x00, 0xc4, 0x01, 0x03, 0x01, 0xc6, 0x01, 0x01, 0x01, 0x87,
  0x04, 0x88, 0x72, 0x65, 0x71, 0x75, 0x69, 0x72, 0x65, 0x04, 0x8f, 0x73,
  0x61, 0x6e, 0x74, 0x6f, 0x6b, 0x75, 0x2e, 0x73, 0x74, 0x72, 0x69, 0x6e,
  0x67, 0x04, 0x84, 0x6c, 0x66, 0x73, 0x04, 0x8b, 0x63, 0x75, 0x72, 0x72,
  0x65, 0x6e, 0x74, 0x64, 0x69, 0x72, 0x04, 0x86, 0x73, 0x70, 0x6c, 0x69,
  0x74, 0x04, 0x82, 0x2f, 0x04, 0x85, 0x65, 0x61, 0x63, 0x68, 0x81, 0x01,
  0x00, 0x00, 0x81, 0x80, 0x86, 0x88, 0x00, 0x00, 0x02, 0x81, 0x47, 0x00,
  0x01, 0x00, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80,
  0x80
};
unsigned int data_len = 193;
      const char *reader (lua_State *L, void *data, size_t *sizep) {
        *sizep = data_len;
        return (const char *)data;
      }
    
      int main (int argc, char **argv) {
    
            lua_State *L = luaL_newstate();
        if (L == NULL)
          return 1;
        luaL_openlibs(L);
        int rc = 0;
    
        if (LUA_OK != (rc = luaL_loadbuffer(L, (const char *)data, data_len, "test/spec/santoku/bundle/test/test.luac")))
          goto err;
        lua_createtable(L, argc, 0);
        for (int i = 0; i < argc; i ++) {
          lua_pushstring(L, argv[i]);
          lua_pushinteger(L, argc + 1);
          lua_settable(L, -3);
        }
        lua_setglobal(L, "arg");
        if (LUA_OK != (rc = lua_pcall(L, 0, 0, 0)))
          goto err;
        goto end;
      err:
        fprintf(stderr, "%s\n", lua_tostring(L, -1));
      end:
              lua_close(L);
              return rc;
      }
    