#!/bin/sh
# Prints the pkg-config name of the Lua the installed Hyprland is linked
# against. The plugin shares Hyprland's lua_State, so it has to be compiled
# with that Lua's headers: where both lua5.4 and a newer `lua` are installed
# (Arch/CachyOS with Lua 5.5), picking lua5.4 just because it exists builds
# against the wrong one.
set -eu

fallback() {
    if pkg-config --exists 'lua5.4 >= 5.4'; then echo lua5.4; else echo lua; fi
    exit 0
}

bin=${HYPRLAND_BIN:-$(command -v Hyprland 2>/dev/null || command -v hyprland 2>/dev/null || true)}
[ -n "$bin" ] && command -v readelf >/dev/null 2>&1 || fallback

# e.g. liblua.so.5.5, liblua5.4.so.5.4, liblua.so.5.4
soname=$(readelf -d "$bin" 2>/dev/null | sed -n 's/.*(NEEDED).*\[\(liblua[^]]*\)\].*/\1/p' | head -n 1)
version=$(printf '%s\n' "$soname" | sed -n 's/.*\.so\.\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p')
[ -n "$version" ] || fallback

for pkg in "lua$version" "lua-$version" lua; do
    if pkg-config --exists "$pkg" && [ "$(pkg-config --modversion "$pkg" | cut -d. -f1,2)" = "$version" ]; then
        echo "$pkg"
        exit 0
    fi
done

echo "detect-lua-pkg: Hyprland uses Lua $version ($soname) but no matching development files were found" >&2
fallback
