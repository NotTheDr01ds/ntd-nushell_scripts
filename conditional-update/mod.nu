# Simply a DRY function to prevent writing this
# code once for each and again for par-each
def buildUpdaterClosure [
  columnName: string
  --where: closure
  --to: closure
] {
    {|row|
        if ($row | do $where $row ) {
          # ($row | do $to $row) is a bit of a strange pattern
          # It allows us to Accept either a closure argument *or* pipeline $in
          update $columnName ($row | do $to $row)
        } else {
          $row
        }
    }
}

export def "conditionally update" [
  columnName: string
  --where: closure
  --to: closure
  --parallel (-p)
] {
    if $parallel {
        par-each (buildUpdaterClosure $columnName --where $where --to $to)
    } else {
        each (buildUpdaterClosure $columnName --where $where --to $to)
    }
}