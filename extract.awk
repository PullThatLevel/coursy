# - Simple awk .crs mod extractor
#Give it a .crs as data and it outputs a table with
#all mods in the format: {time,len,len_or_end,mod}
# - PullThatLevel (2020)

BEGIN { FS = ":"; print("{") }

/^\/+/ {
    gsub(/^\/+/, "")
    print("\t--" $0)
}

/^#MODS:/ {
    modType = substr($3, 1, 1)
    for(i=2; i<=4; ++i) gsub(/^.*=|;$/, "", $i)
    
    print("\t{" $2 "," $3 ",'" modType "','" $4 "'},")
}

END { print("}") }