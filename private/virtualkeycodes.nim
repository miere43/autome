import tables

var t = initTable[char, DWORD](256)
for some in 97..122:
  echo "map ", some.char, " -> ", some - 32
  t.add(some.char, (some - 32).DWORD)

proc translate(c: char): DWORD =
  t[c]