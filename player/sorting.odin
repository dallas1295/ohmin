package player

import md "../metadata"
import "core:sort"
import "core:unicode"
import "core:unicode/utf8"

// NOTE: At the moment this is just the default sorting on launch to sort artist -> year -> album -> track_num
track_compare :: proc(a, b: md.Track) -> int {
	if c := compare_to_lower(a.artist, b.artist); c != 0 {
		return c
	}
	if c := sort.compare_u32s(a.year, b.year); c != 0 {
		return c
	}
	if c := compare_to_lower(a.album, b.album); c != 0 {
		return c
	}
	if c := sort.compare_u32s(a.track, b.track); c != 0 {
		return c
	}
	return sort.compare_strings(a.path, b.path)
}

// takes in a and b strings converts them to their rune and lengths and lowers the rune then compares to return which
compare_to_lower :: proc(a, b: string) -> int {
	i, j: int
	for i < len(a) && j < len(b) {
		ra, ia := utf8.decode_rune(a[i:])
		rb, ib := utf8.decode_rune(b[j:])
		fa := unicode.to_lower(ra)
		fb := unicode.to_lower(rb)
		if fa != fb do return fa < fb ? -1 : 1
		i += ia
		j += ib
	}

	if i < len(a) do return 1
	if j < len(b) do return -1
	return 0
}
