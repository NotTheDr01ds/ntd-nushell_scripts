# `str unindent` 

*Description:* Removes common indentation from a multi-line string

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
      * Welcome to Nushell *

Taking the Unix philosophy of shells,
where pipes connect simple commands
together, and bring it to the modern
style of development.
```
