# Do-While Parser

## Пример выражения:
```cpp
do { 
    do print(++b); 
    while(++a < 10); 
} while (++b < 4);
```

## Грамматика 

1. **DWS’** → DWS
2. **DWS** → do Action W
3. **Action** → Print
4. **Action** → Block
5. **Action** → DWS
6. **W** → while (E);
7. **W** → while (E’);
8. **Block** → {DWS}
9. **Print** → print(INC);
10. **E** → INC < I;
11. **E’** → INC > I;
12. **INC** → ++VAR;

## Инструкция по сборке и запуску

1. mkdir build && cd build
2. cmake ..
3. ninja
4. ./do_while_parser.exe

