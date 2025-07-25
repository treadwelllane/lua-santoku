#ifndef TK_LUA_UTILS_H
#define TK_LUA_UTILS_H

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdint.h>
#include <limits.h>
#include <math.h>
#include <errno.h>
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>

#include <santoku/klib.h>

#define tk_pp_str(x) #x
#define tk_pp_xstr(x) tk_pp_str(x)
#define tk_pp_strcat2(a, b) a##_##b
#define tk_pp_strcat(a, b) tk_pp_strcat2(a, b)

#define tk_lua_hash_string(s) (kh_str_hash_func(s))
#define tk_lua_hash_integer(s) (kh_int64_hash_func(s))

static inline uint64_t tk_lua_hash_double (double x)
{
  // Ensure -0.0 == +0.0
  if (x == 0.0) x = 0.0;
  uint64_t bits;
  memcpy(&bits, &x, sizeof(bits));
  return tk_lua_hash_integer(bits);
}

static inline uint64_t tk_lua_hash_mix (uint64_t x) {
  x ^= x >> 33;
  x *= 0xff51afd7ed558ccdULL;
  x ^= x >> 33;
  x *= 0xc4ceb9fe1a85ec53ULL;
  x ^= x >> 33;
  return x;
}

static inline uint64_t tk_lua_hash_128 (
  uint64_t lo,
  uint64_t hi
) {
  uint64_t x = lo ^ (hi + 0x9e3779b97f4a7c15ULL + (lo << 6) + (lo >> 2));
  x ^= x >> 33;
  x *= 0xff51afd7ed558ccdULL;
  x ^= x >> 33;
  x *= 0xc4ceb9fe1a85ec53ULL;
  x ^= x >> 33;
  return x;
}

// TODO: allow caching of function lookups
static inline void tk_lua_callmod (
  lua_State *L,
  int nargs,
  int nret,
  const char *smod,
  const char *sfn
) {
  lua_getglobal(L, "require"); // arg req
  lua_pushstring(L, smod); // arg req smod
  lua_call(L, 1, 1); // arg mod
  lua_pushstring(L, sfn); // args mod sfn
  lua_gettable(L, -2); // args mod fn
  lua_remove(L, -2); // args fn
  lua_insert(L, - nargs - 1); // fn args
  lua_call(L, nargs, nret); // results
}


static inline int tk_lua_errno (lua_State *L, int err)
{
  lua_pushstring(L, strerror(errno));
  lua_pushinteger(L, err);
  tk_lua_callmod(L, 2, 0, "santoku.error", "error");
  return 0;
}

static inline int tk_lua_error (lua_State *L, const char *err)
{
  lua_pushstring(L, err);
  tk_lua_callmod(L, 1, 0, "santoku.error", "error");
  return 0;
}

static inline int tk_lua_errmalloc (lua_State *L)
{
  lua_pushstring(L, "Error in malloc");
  tk_lua_callmod(L, 1, 0, "santoku.error", "error");
  return 0;
}

static inline int tk_lua_absindex (lua_State *L, int i)
{
  if (i < 0 && i > LUA_REGISTRYINDEX)
    i += lua_gettop(L) + 1;
  return i;
}

static inline int tk_lua_ref (lua_State *L, int i)
{
  lua_pushvalue(L, i);
  return luaL_ref(L, LUA_REGISTRYINDEX);
}

static inline void tk_lua_unref (lua_State *L, int r)
{
  luaL_unref(L, LUA_REGISTRYINDEX, r);
}

static inline void tk_lua_deref (lua_State *L, int r)
{
  lua_rawgeti(L, LUA_REGISTRYINDEX, r);
}

static inline int tk_lua_verror (lua_State *L, int n, ...) {
  va_list args;
  va_start(args, n);
  for (int i = 0; i < n; i ++) {
    const char *str = va_arg(args, const char *);
    lua_pushstring(L, str);
  }
  va_end(args);
  tk_lua_callmod(L, n, 0, "santoku.error", "error");
  return 0;
}

static inline bool tk_lua_optboolean (lua_State *L, int i, char *name, bool def)
{
  if (lua_type(L, i) < 1)
    return def;
  if (lua_type(L, i) != LUA_TBOOLEAN)
    tk_lua_verror(L, 2, name, "value is not a boolean");
  bool b = lua_toboolean(L, -1);
  lua_pop(L, 1);
  return b;
}

static inline bool tk_lua_foptboolean (lua_State *L, int i, char *name, char *field, bool def)
{
  lua_getfield(L, i, field);
  if (lua_type(L, -1) < 1)
    return def;
  if (lua_type(L, -1) != LUA_TBOOLEAN)
    tk_lua_verror(L, 3, name, field, "field is not a boolean");
  bool b = lua_toboolean(L, -1);
  lua_pop(L, 1);
  return b;
}

static inline lua_Integer tk_lua_checkposinteger (lua_State *L, int i)
{
  lua_Integer l = luaL_checkinteger(L, i);
  if (l < 0)
    luaL_error(L, "value can't be negative");
  return l;
}

// TODO: include the field name in error
static inline lua_Integer tk_lua_ftype (lua_State *L, int i, char *field)
{
  lua_getfield(L, i, field);
  int t = lua_type(L, -1);
  lua_pop(L, 1);
  return t;
}

static inline void tk_lua_checktype (lua_State *L, int i, char *name, int t)
{
  if (lua_type(L, i) != t)
    tk_lua_verror(L, 3, name, "value is not of type", lua_typename(L, i));
}

static inline void tk_lua_fchecktype (lua_State *L, int i, char *name, char *field, int t)
{
  lua_getfield(L, i, field);
  if (lua_type(L, -1) != t)
    tk_lua_verror(L, 4, name, field, "field is not of type", lua_typename(L, i));
  lua_pop(L, 1);
}

static inline void *tk_lua_checkuserdata (lua_State *L, int i, char *mt, const char *name)
{
  void *ud = lua_touserdata(L, i);
  if (ud == NULL) {
    tk_lua_verror(L, 2, name, "value is not a userdata");
    return NULL;
  }
  if (!lua_getmetatable(L, i)) {
    tk_lua_verror(L, 2, name, "value has no metatable");
    return NULL;
  }
  luaL_getmetatable(L, mt); // mt0 mt1
  int equal = lua_rawequal(L, -1, -2);
  lua_getfield(L, -2, "__name"); // mt0 mt1 n0
  const char *mt1;
  if (lua_isnil(L, -1))
    mt1 = "(unknown)";
  else
    mt1 = lua_tostring(L, -1);
  lua_pop(L, 3); //
  if (!equal) {
    tk_lua_verror(L, 3, name, "value is not of type", mt, mt1);
    return NULL;
  }
  return ud;
}

static const char *tk_lua_eph_key_suffix = "_lookup";

static inline void tk_lua_add_ephemeron (lua_State *L, const char *eph_key, int idx_parent, int idx_ephemeron)
{
  idx_parent = tk_lua_absindex(L, idx_parent);
  idx_ephemeron = tk_lua_absindex(L, idx_ephemeron);
  lua_getfield(L, LUA_REGISTRYINDEX, eph_key); // eph
  if (lua_isnil(L, -1)) {
    lua_pop(L, 1); //
    lua_newtable(L); // eph
    lua_newtable(L); // eph mt
    lua_pushliteral(L, "k"); // eph mt k
    lua_setfield(L, -2, "__mode"); // eph mt
    lua_setmetatable(L, -2); // eph
    lua_pushvalue(L, -1); // eph eph
    lua_setfield(L, LUA_REGISTRYINDEX, eph_key); // eph
  }
  lua_pushvalue(L, idx_parent); // eph parent
  lua_rawget(L, -2); // eph t
  if (lua_isnil(L, -1)) {
    lua_pop(L, 1); // eph
    lua_newtable(L);  // eph t
    lua_pushvalue(L, idx_parent); // eph t parent
    lua_pushvalue(L, -2);  // eph t parent t
    lua_rawset(L, -4); // eph t
  }
  lua_pushvalue(L, idx_ephemeron); // eph t child
  lua_pushboolean(L, true); // eph t child true
  lua_rawset(L, -3); // eph t
  char u_key[256];
  snprintf(u_key, sizeof(u_key), "%s%s", eph_key, tk_lua_eph_key_suffix);
  lua_getfield(L, LUA_REGISTRYINDEX, u_key); // eph t lookup
  if (lua_isnil(L, -1)) {
    lua_pop(L, 1); // eph t
    lua_newtable(L); // eph t lookup
    lua_newtable(L); // eph t lookup mt
    lua_pushliteral(L, "v");
    lua_setfield(L, -2, "__mode");  // eph t lookup mt
    lua_setmetatable(L, -2); // eph t lookup
    lua_pushvalue(L, -1); // eph t lookup lookup
    lua_setfield(L, LUA_REGISTRYINDEX, u_key); // eph t lookup
  }
  lua_pushlightuserdata(L, lua_touserdata(L, idx_ephemeron)); // eph t lookup key
  lua_pushvalue(L, idx_ephemeron); // eph t lookup key value
  lua_rawset(L, -3); // eph t lookup
  lua_pop(L, 3); //
}

static inline void tk_lua_get_ephemeron (lua_State *L, const char *eph_key, void *e)
{
  char u_key[256];
  snprintf(u_key, sizeof(u_key), "%s%s", eph_key, tk_lua_eph_key_suffix);
  lua_getfield(L, LUA_REGISTRYINDEX, u_key); // lookup
  if (lua_isnil(L, -1))
    return;
  lua_pushlightuserdata(L, e); // lookup e
  lua_gettable(L, -2); // lookup v
  lua_remove(L, -2); // v
}

static inline void tk_lua_register (lua_State *L, luaL_Reg *regs, int nup)
{
  while (true) {
    if ((*regs).name == NULL)
      break;
    for (int i = 0; i < nup; i ++)
      lua_pushvalue(L, -nup); // t upsa upsb
    lua_pushcclosure(L, (*regs).func, nup); // t upsa fn
    lua_setfield(L, -nup - 2, (*regs).name); // t
    regs ++;
  }
  lua_pop(L, nup);
}

#define tk_lua_newuserdata(L, t, mt, fns, gc) \
  (tk_lua_newuserdata_(L, sizeof(t), mt, fns, gc))
static inline void *tk_lua_newuserdata_ (
  lua_State *L,
  size_t s,
  char *mt,
  luaL_Reg *fns,
  lua_CFunction gc
) {
  void *v = lua_newuserdata(L, s);
  if (!v)
    tk_lua_verror(L, 2, "newuserdata failed", mt);
  memset(v, 0, s);
  if (luaL_newmetatable(L, mt)) {
    lua_pushstring(L, mt);
    lua_setfield(L, -2, "__name");
    lua_pushcfunction(L, gc);
    lua_setfield(L, -2, "__gc");
    if (fns != NULL) {
      lua_newtable(L);
      tk_lua_register(L, fns, 0);
      lua_setfield(L, -2, "__index");
    }
  }
  lua_setmetatable(L, -2);
  return v;
}

static inline void *tk_lua_testuserdata (lua_State *L, int idx, const char *tname)
{
  void *ud = lua_touserdata(L, idx);
  if (ud == NULL) return NULL;
  if (!lua_getmetatable(L, idx)) return NULL;
  luaL_getmetatable(L, tname);
  int equal = lua_rawequal(L, -1, -2);
  lua_pop(L, 2);
  return equal ? ud : NULL;
}

// TODO: include the field name in error
static inline void *tk_lua_fcheckuserdata (lua_State *L, int i, char *field, char *mt)
{
  lua_getfield(L, i, field);
  void *p = luaL_checkudata(L, -1, mt);
  lua_pop(L, 1);
  return p;
}

static inline lua_Integer tk_lua_fcheckinteger (lua_State *L, int i, char *name, char *field)
{
  lua_getfield(L, i, field);
  if (lua_type(L, -1) != LUA_TNUMBER)
    tk_lua_verror(L, 3, name, field, "field is not a positive integer");
  lua_Integer l = luaL_checkinteger(L, -1);
  lua_pop(L, 1);
  return l;
}

// TODO: include the field name in error
static inline lua_Integer tk_lua_fchecknumber (lua_State *L, int i, char *field)
{
  lua_getfield(L, i, field);
  lua_Integer n = luaL_checknumber(L, -1);
  lua_pop(L, 1);
  return n;
}

static inline int tk_error (
  lua_State *L,
  const char *label,
  int err
) {
  lua_pushstring(L, label);
  lua_pushstring(L, strerror(err));
  tk_lua_callmod(L, 2, 0, "santoku.error", "error");
  return 1;
}

static inline double tk_lua_optnumber (lua_State *L, int i, char *name, double def)
{
  if (lua_type(L, i) < 1)
    return def;
  if (lua_type(L, i) != LUA_TNUMBER)
    tk_lua_verror(L, 2, name, "value is not a number");
  lua_Number l = luaL_checknumber(L, i);
  return l;
}

static inline double tk_lua_fcheckdouble (lua_State *L, int i, char *name, char *field)
{
  lua_getfield(L, i, field);
  if (lua_type(L, -1) != LUA_TNUMBER)
    tk_lua_verror(L, 3, name, field, "field is not a number");
  lua_Number l = luaL_checknumber(L, -1);
  lua_pop(L, 1);
  return l;
}

static inline double tk_lua_foptnumber (lua_State *L, int i, char *name, char *field, double def)
{
  lua_getfield(L, i, field);
  if (lua_type(L, -1) < 1) {
    lua_pop(L, 1);
    return def;
  }
  if (lua_type(L, -1) != LUA_TNUMBER)
    tk_lua_verror(L, 3, name, field, "field is not a number");
  lua_Number l = luaL_checknumber(L, -1);
  lua_pop(L, 1);
  return l;
}

static inline bool tk_lua_checkboolean (lua_State *L, int i)
{
  if (lua_type(L, i) < 1)
    return false;
  luaL_checktype(L, i, LUA_TBOOLEAN);
  return lua_toboolean(L, i);
}

static inline bool tk_lua_fcheckboolean (lua_State *L, int i, char *name, char *field)
{
  lua_getfield(L, i, field);
  if (lua_type(L, -1) != LUA_TBOOLEAN)
    tk_lua_verror(L, 3, name, field, "field is not a boolean");
  luaL_checktype(L, -1, LUA_TBOOLEAN);
  bool n = lua_toboolean(L, -1);
  lua_pop(L, 1);
  return n;
}

static uint64_t const tk_fast_multiplier = 6364136223846793005u;
static uint64_t tk_fast_mcg_state = 0xcafef00dd15ea5e5u;

static inline uint32_t tk_fast_random ()
{
  uint64_t x = tk_fast_mcg_state;
  unsigned int count = (unsigned int) (x >> 61);
  tk_fast_mcg_state = x * tk_fast_multiplier;
  return (uint32_t) ((x ^ x >> 22) >> (22 + count));
}

static inline double tk_fast_normal (double mean, double variance)
{
  double u1 = (double) (tk_fast_random() + 1) / ((double) UINT32_MAX + 1);
  double u2 = (double) tk_fast_random() / UINT32_MAX;
  double n1 = sqrt(-2 * log(u1)) * sin(8 * atan(1) * u2);
  return mean + sqrt(variance) * n1;
}

static inline bool tk_lua_streq (lua_State *L, int i, char *str)
{
  i = tk_lua_absindex(L, i);
  lua_pushstring(L, str);
  int r = lua_equal(L, i, -1);
  lua_pop(L, 1);
  return r == 1;
}

static inline const char *tk_lua_checkstring (lua_State *L, int i, char *name)
{
  if (lua_type(L, i) != LUA_TSTRING)
    tk_lua_verror(L, 3, name, "value is not a string");
  return luaL_checkstring(L, i);
}

static inline const char *tk_lua_checklstring (lua_State *L, int i, size_t *lp, char *name)
{
  if (lua_type(L, i) != LUA_TSTRING)
    tk_lua_verror(L, 2, name, "value is not a string");
  const char *s = luaL_checklstring(L, 1, lp);
  return s;
}

static inline const char *tk_lua_fchecklstring (lua_State *L, int i, size_t *lp, char *name, char *field)
{
  lua_getfield(L, i, field);
  if (lua_type(L, -1) != LUA_TSTRING)
    tk_lua_verror(L, 3, name, field, "field is not a string");
  const char *s = luaL_checklstring(L, -1, lp);
  lua_pop(L, 1);
  return s;
}

static inline const char *tk_lua_fcheckstring (lua_State *L, int i, char *name, char *field)
{
  lua_getfield(L, i, field);
  if (lua_type(L, -1) != LUA_TSTRING)
    tk_lua_verror(L, 3, name, field, "field is not a string");
  const char *s = luaL_checkstring(L, -1);
  lua_pop(L, 1);
  return s;
}

static inline void *tk_realloc (
  lua_State *L,
  void *p,
  size_t s
) {
  if (s == 0) {
    free(p);
    return NULL;
  }
  p = realloc(p, s);
  if (!p) {
    tk_error(L, "realloc failed", ENOMEM);
    return NULL;
  } else {
    return p;
  }
}

static inline void *tk_malloc (
  lua_State *L,
  size_t s
) {
  if (s == 0)
    return NULL;
  void *p = malloc(s);
  if (!p) {
    tk_error(L, "malloc failed", ENOMEM);
    return NULL;
  } else {
    return p;
  }
}

static inline double tk_lua_checkdouble (lua_State *L, int i, char *name)
{
  if (lua_type(L, i) != LUA_TNUMBER)
    tk_lua_verror(L, 2, name, "value is not a number");
  lua_Number l = luaL_checknumber(L, i);
  return (double) l;
}

static inline double tk_lua_checkposdouble (lua_State *L, int i, char *name)
{
  if (lua_type(L, i) != LUA_TNUMBER)
    tk_lua_verror(L, 2, name, "value is not a positive number");
  lua_Number l = luaL_checknumber(L, i);
  if (l < 0)
    tk_lua_verror(L, 2, name, "value is not a positive number");
  return (double) l;
}

static inline const char *tk_lua_optstring (lua_State *L, int i, char *name, char *def)
{
  if (lua_type(L, i) < 1)
    return def;
  if (lua_type(L, i) != LUA_TSTRING)
    tk_lua_verror(L, 2, name, "value is not a string");
  return luaL_checkstring(L, i);
}

static inline double tk_lua_optposdouble (lua_State *L, int i, char *name, double def)
{
  if (lua_type(L, i) < 1)
    return def;
  lua_Number l = luaL_checknumber(L, i);
  if (l < 0)
    tk_lua_verror(L, 2, name, "value is not a positive number");
  return (double) l;
}

static inline double tk_lua_fcheckposdouble (lua_State *L, int i, char *name, char *field)
{
  lua_getfield(L, i, field);
  if (lua_type(L, -1) != LUA_TNUMBER)
    tk_lua_verror(L, 3, name, field, "field is not a positive number");
  lua_Number l = luaL_checknumber(L, -1);
  if (l < 0)
    tk_lua_verror(L, 3, name, field, "field is not a positive number");
  lua_pop(L, 1);
  return l;
}

static inline double tk_lua_foptposdouble (lua_State *L, int i, char *name, char *field, double def)
{
  lua_getfield(L, i, field);
  if (lua_type(L, -1) < 1) {
    lua_pop(L, 1);
    return def;
  }
  if (lua_type(L, -1) != LUA_TNUMBER)
    tk_lua_verror(L, 3, name, field, "field is not a positive number");
  lua_Number l = luaL_checknumber(L, -1);
  if (l < 0)
    tk_lua_verror(L, 3, name, field, "field is not a positive number");
  lua_pop(L, 1);
  return l;
}

static inline lua_Integer tk_lua_checkinteger (lua_State *L, int i, char *name)
{
  if (lua_type(L, i) != LUA_TNUMBER)
    tk_lua_verror(L, 2, name, "value is not an integer");
  lua_Integer l = luaL_checkinteger(L, i);
  return l;
}

static inline lua_Integer tk_lua_foptinteger (lua_State *L, int i, char *name, char *field, lua_Integer def)
{
  lua_getfield(L, i, field);
  if (lua_type(L, -1) < 1) {
    lua_pop(L, 1);
    return def;
  }
  if (lua_type(L, -1) != LUA_TNUMBER)
    tk_lua_verror(L, 3, name, field, "field is not an integer");
  lua_Integer l = luaL_checkinteger(L, -1);
  lua_pop(L, 1);
  return l;
}

static inline unsigned int tk_lua_checkunsigned (lua_State *L, int i, char *name)
{
  if (lua_type(L, i) != LUA_TNUMBER)
    tk_lua_verror(L, 2, name, "value is not a positive integer");
  lua_Integer l = luaL_checkinteger(L, i);
  if (l < 0)
    tk_lua_verror(L, 2, name, "value is not a positive integer");
  if (l > UINT_MAX)
    luaL_error(L, "value is too large");
  return (unsigned int) l;
}

static inline unsigned int tk_lua_fcheckunsigned (lua_State *L, int i, char *name, char *field)
{
  lua_getfield(L, i, field);
  if (lua_type(L, -1) != LUA_TNUMBER)
    tk_lua_verror(L, 3, name, field, "field is not a positive integer");
  lua_Integer l = luaL_checkinteger(L, -1);
  if (l < 0)
    tk_lua_verror(L, 3, name, field, "field is not a positive integer");
  lua_pop(L, 1);
  return l;
}

static inline unsigned int tk_lua_foptunsigned (lua_State *L, int i, char *name, char *field, unsigned int def)
{
  lua_getfield(L, i, field);
  if (lua_type(L, -1) < 1) {
    lua_pop(L, 1);
    return def;
  }
  if (lua_type(L, -1) != LUA_TNUMBER)
    tk_lua_verror(L, 3, name, field, "field is not a positive integer");
  lua_Integer l = luaL_checkinteger(L, -1);
  if (l < 0)
    tk_lua_verror(L, 3, name, field, "field is not a positive integer");
  lua_pop(L, 1);
  return l;
}

static inline unsigned int tk_lua_optunsigned (lua_State *L, int i, char *name, unsigned int def)
{
  if (lua_type(L, i) < 1)
    return def;
  if (lua_type(L, i) != LUA_TNUMBER)
    tk_lua_verror(L, 2, name, "value is not a positive integer");
  lua_Integer l = luaL_checkinteger(L, i);
  if (l < 0)
    tk_lua_verror(L, 2, name, "value is not a positive integer");
  return l;
}

static inline FILE *tk_lua_tmpfile (lua_State *L)
{
  FILE *fh = tmpfile();
  if (fh) return fh;
  int e = errno;
  lua_settop(L, 0);
  lua_pushstring(L, "Error opening tmpfile");
  lua_pushstring(L, strerror(e));
  lua_pushinteger(L, e);
  tk_lua_callmod(L, 3, 0, "santoku.error", "error");
  return NULL;
}

static inline FILE *tk_lua_fmemopen (lua_State *L, char *data, size_t size, const char *flag)
{
  FILE *fh = fmemopen(data, size, flag);
  if (fh) return fh;
  int e = errno;
  lua_settop(L, 0);
  lua_pushstring(L, "Error opening string as file");
  lua_pushstring(L, strerror(e));
  lua_pushinteger(L, e);
  tk_lua_callmod(L, 3, 0, "santoku.error", "error");
  return NULL;
}

static inline FILE *tk_lua_fopen (lua_State *L, const char *fp, const char *flag)
{
  FILE *fh = fopen(fp, flag);
  if (fh) return fh;
  int e = errno;
  lua_settop(L, 0);
  lua_pushstring(L, "Error opening file");
  lua_pushstring(L, fp);
  lua_pushstring(L, strerror(e));
  lua_pushinteger(L, e);
  tk_lua_callmod(L, 4, 0, "santoku.error", "error");
  return NULL;
}

static inline void tk_lua_fclose (lua_State *L, FILE *fh)
{
  if (!fclose(fh)) return;
  int e = errno;
  lua_settop(L, 0);
  lua_pushstring(L, "Error closing file");
  lua_pushstring(L, strerror(e));
  lua_pushinteger(L, e);
  tk_lua_callmod(L, 3, 0, "santoku.error", "error");
}

static inline void tk_lua_fwrite (lua_State *L, void *data, size_t size, size_t memb, FILE *fh)
{
  fwrite(data, size, memb, fh);
  if (!ferror(fh)) return;
  int e = errno;
  lua_settop(L, 0);
  lua_pushstring(L, "Error writing to file");
  lua_pushstring(L, strerror(e));
  lua_pushinteger(L, e);
  tk_lua_callmod(L, 3, 0, "santoku.error", "error");
}

static inline void tk_lua_fread (lua_State *L, void *data, size_t size, size_t memb, FILE *fh)
{
  size_t r = fread(data, size, memb, fh);
  if (!ferror(fh) || !r) return;
  int e = errno;
  lua_settop(L, 0);
  lua_pushstring(L, "Error reading from file");
  lua_pushstring(L, strerror(e));
  lua_pushinteger(L, e);
  tk_lua_callmod(L, 3, 0, "santoku.error", "error");
}

static inline void tk_lua_fseek (lua_State *L, size_t size, size_t memb, FILE *fh)
{
  int r = fseek(fh, (long) (size * memb), SEEK_CUR);
  if (!ferror(fh) || !r) return;
  int e = errno;
  lua_settop(L, 0);
  lua_pushstring(L, "Error reading from file");
  lua_pushstring(L, strerror(e));
  lua_pushinteger(L, e);
  tk_lua_callmod(L, 3, 0, "santoku.error", "error");
}

static inline char *tk_lua_fslurp (lua_State *L, FILE *fh, size_t *len)
{
  if (fseek(fh, 0, SEEK_END) != 0) {
    tk_lua_errno(L, errno);
    return NULL;
  }
  long size = ftell(fh);
  if (size < 0) {
    tk_lua_errno(L, errno);
    return NULL;
  }
  if (fseek(fh, 0, SEEK_SET) != 0) {
    tk_lua_errno(L, errno);
    return NULL;
  }
  char *buffer = malloc((size_t) size);
  if (!buffer) {
    tk_lua_errmalloc(L);
    return NULL;
  }
  if (fread(buffer, 1, (size_t) size, fh) != (size_t) size) {
    free(buffer);
    tk_lua_errno(L, errno);
    return NULL;
  }
  *len = (size_t) size;
  return buffer;
}

static inline void *tk_malloc_aligned (
  lua_State *L,
  size_t s,
  size_t a
) {
  void *p = NULL;
  if (posix_memalign((void **)&p, a, s) != 0)
    tk_error(L, "malloc failed", ENOMEM);
  return p;
}

static inline const void *tk_lua_optustring (lua_State *L, int i, char *name, void *d)
{
  void *r = d;
  if (lua_type(L, i) == LUA_TSTRING)
    r = (void *) luaL_checkstring(L, i);
  else if (lua_type(L, i) == LUA_TLIGHTUSERDATA)
    r = (void *) lua_touserdata(L, i);
  else if (lua_type(L, i) > 0)
    tk_lua_verror(L, 2, name, "field is not a string or light userdata");
  return r;
}

static inline const void *tk_lua_foptustring (lua_State *L, int i, char *name, char *field, void *d)
{
  lua_getfield(L, i, field);
  void *r = d;
  if (lua_type(L, -1) == LUA_TSTRING)
    r = (void *) luaL_checkstring(L, -1);
  else if (lua_type(L, -1) == LUA_TLIGHTUSERDATA)
    r = (void *) lua_touserdata(L, -1);
  else if (lua_type(L, -1) > 0)
    tk_lua_verror(L, 3, name, field, "field is not a string or light userdata");
  lua_pop(L, 1);
  return r;
}

static inline const void *tk_lua_checkustring (lua_State *L, int i, char *name)
{
  void *r = (void *) tk_lua_optustring(L, i, name, NULL);
  if (r == NULL)
    tk_lua_verror(L, 2, name, "value is not a string or light userdata");
  return r;
}

static inline const void *tk_lua_fcheckustring (lua_State *L, int i, char *name, char *field)
{
  void *r = (void *) tk_lua_foptustring(L, i, name, field, NULL);
  if (r == NULL)
    tk_lua_verror(L, 3, name, field, "field is not a string or light userdata");
  return r;
}

#endif
