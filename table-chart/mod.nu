use std repeat

export def chart [ 
  columnName:string
  --width (-w):int = 20
  --char (-c):string = '*'
] {
  let table = $in
  let maxWidth = $width
  
  let max = $table | get $columnName | math max

  $table | insert Graph {|row|
      let percentOfMax = ($row | get $columnName) / $max
      let width = (( $maxWidth * $percentOfMax ) | math round )
      
      # If the value is greater than 0, at least show a 1 pixel bar
      let width = ( if ($percentOfMax > 0) and ($width == 0) { 1 } else { $width } )

      # returns the properly sized bar
      $char | repeat $width | str join
  }
}