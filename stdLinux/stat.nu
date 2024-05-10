def stat [target] {
  let format = [
    [ permissions_octal a ]
    [ permissions A ]
    [ blocks b ]
    [ block_size B ]
    [ security_context c ]
    [ device_number d ]
    [ device_number_hex D ]
    [ raw_mode f ]
    [ file_type F ]
    [ group_owner_id g ]
    [ group_owner_name G ]
    [ hard_links_count h ]
    [ inode_number i ]
    [ mount_point m ]
    [ name n ]
    [ dereferenced_name N ]
    [ optimal_xfer_size_hint o ]
    [ total_size_bytes s ]
    [ major_device_type t ]
    [ minor_device_type T ]
    [ user_owner_id u ]
    [ user_owner_name U ]
    [ creation_time w ]
    [ creation_time_epoch W ]
    [ access_time x ]
    [ access_time_epoch X ]
    [ modification_time y ]
    [ modification_time_epoch Y]
    [ status_change_time z ]
    [ status_change_time_epoch Z ]
  ]
  | each {|format| str join ":%"}
  | str join "\n"

  ^stat --printf $format $target
  | lines
  | parse '{field}:{value}'
  | transpose -dr
}