package metadata

import tag "../deps/taglib"
import "core:fmt"
import "core:mem"
import "core:strings"

Track :: struct {
	path:   string,
	title:  string,
	artist: string,
	album:  string,
	year:   u32,
	track:  u32,
}

Track_Error :: enum {
	FILE_NOT_VALID,
	FILE_UNREADABLE,
}
scan_track :: proc(path: string) -> (Track, Track_Error) {cpath := strings.clone_to_cstring(path)
	defer delete(cpath)

	file := tag.file_new(cpath)
	// If file is nil it means it couldn't open
	if file == nil {
		return Track{}, .FILE_UNREADABLE}
	defer tag.file_free(file)

	// if the file_is_valid is 0 it means the file isn't what it says it is
	if tag.file_is_valid(file) == 0 {
		return Track{}, .FILE_NOT_VALID
	}

	// get the metadata
	t := tag.file_tag(file)

	title: string
	if title_c := tag.tag_title(t); title_c != nil {
		title, _ = strings.clone_from_cstring(title_c)
	}
	if len(title) == 0 {
		title = strings.clone("Unknown Title")
	}

	artist: string
	if artist_c := tag.tag_artist(t); artist_c != nil {
		artist, _ = strings.clone_from_cstring(artist_c)
	}
	if len(artist) == 0 {
		artist = strings.clone("Unknown Artist")
	}

	album: string
	if album_c := tag.tag_album(t); album_c != nil {
		album, _ = strings.clone_from_cstring(album_c)
	}
	if len(album) == 0 {
		album = strings.clone("Unknown Album")
	}

	year := tag.tag_year(t)
	track_num := tag.tag_track(t)

	tag.tag_free_strings()

	return Track{path, title, artist, album, year, track_num}, nil
}
