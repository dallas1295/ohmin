package main

import "core:fmt"
import "core:image"
import "core:image/jpeg"
import "core:image/png"
import "core:mem"
import "core:strings"
import tag "deps/taglib"
import rl "vendor:raylib"

art_tex: rl.Texture2D
art_loaded := false
last_art_idx := -1

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

scan_track :: proc(path: string) -> (Track, Track_Error) {
	cpath := strings.clone_to_cstring(path)
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

get_album_art :: proc(path: string) -> ([]u8, Track_Error) {
	cpath := strings.clone_to_cstring(path)
	defer delete(cpath)

	file := tag.file_new(cpath)
	// If file is nil it means it couldn't open
	if file == nil {
		return nil, .FILE_UNREADABLE}
	defer tag.file_free(file)

	// if the file_is_valid is 0 it means the file isn't what it says it is
	if tag.file_is_valid(file) == 0 {
		return nil, .FILE_NOT_VALID
	}

	// get the PICTURE property from the metadata
	prop := tag.complex_property_get(file, "PICTURE")
	if prop == nil {
		fmt.eprintfln("[art] %s | NO PICTURE property", path)
		return nil, nil
	}
	defer tag.complex_property_free(prop)

	// get the data from our tag so we can convert it.
	pic: tag.TagLib_Complex_Property_Picture_Data
	tag.picture_from_complex_property(prop, &pic)
	if pic.size == 0 {
		return nil, nil
	}

	// next we make the byte allocation for it then copy the into it's own allocation
	artwork := make([]u8, pic.size)
	mem.copy(raw_data(artwork), rawptr(pic.data), int(pic.size))

	return artwork, nil
}

handle_art :: proc() {
	// if we're not initialized we don't load anything
	if curr_idx < 0 do return

	// if nothing changes frame to frame we do nothing
	if curr_idx == last_art_idx do return
	last_art_idx = curr_idx

	// if something has changed we need to UnloadTexture the previous artwork and flip our art_loaded
	if art_loaded {
		rl.UnloadTexture(art_tex)
		art_loaded = false
	}

	// we then get the curr_idx's path and get_album_art tag.
	// defer the deletion then error handle (if there's no art we just move on)
	art, err := get_album_art(library[curr_idx].path)
	defer delete(art)
	if err != nil || len(art) == 0 do return

	// FIXME: Progessive JPEG do not work with odin's imagel lib (libjpeg??????)
	// NOTE: The odin compiled raylib version doesn't have jpeg enable for some reason SO...
	// I use the image package ot load the image from bytes if there's an error we just return
	img, ierr := image.load_from_bytes(art)
	if ierr != nil do return
	defer image.destroy(img)

	// now we convert our image:Image into the rl:Image
	rlimg := rl.Image {
		data    = raw_data(img.pixels.buf),
		width   = i32(img.width),
		height  = i32(img.height),
		mipmaps = 1,
		format  = img.channels == 3 ? .UNCOMPRESSED_R8G8B8 : .UNCOMPRESSED_R8G8B8A8,
	}

	// convert the image into a texture load it and flip our art_loaded to true
	art_tex = rl.LoadTextureFromImage(rlimg)
	art_loaded = true
}
