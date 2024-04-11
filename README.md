# `str unindent` 

*Description:* Removes common indentation from a multi-line string. This allows strings in code to have indentation which aligns with the code block, but is removed in a logical and consistent manner when the string is used.

*Example:*

```Nushell
> let intro = "
          * Welcome to Nushell *

    Taking the Unix philosophy of shells,
    where pipes connect simple commands
    together, and bring it to the modern
    style of development.
  "
> $intro | str unindent
```

Result:

```Nothing
      * Welcome to Nushell *

Taking the Unix philosophy of shells,
where pipes connect simple commands
together, and bring it to the modern
style of development.
```

*Notes, features, and limitations:*

* If the first or last lines consist only of whitespace, they are discarded.
* Other lines consisting only of whitespace are disregarded when calculating indentation level. 
* Tabs (`\t`) are not considered at the moment for indentation purposes; only spaces.