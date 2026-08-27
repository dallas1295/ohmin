package metadata

import tag "../deps/taglib"
import tj "../deps/turbojpeg"
import "core:fmt"
import "core:image"
import "core:image/jpeg"
import "core:image/png"
import "core:mem"
import "core:strings"
import rl "vendor:raylib"


art_tex: rl.Texture2D
art_loaded := false
last_art_idx := -1

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

handle_art :: proc(curr_idx: int, path: string) {
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
	art, err := get_album_art(path)
	defer delete(art)
	if err != nil || len(art) == 0 do return

	// Load the artwork based on the metadata
	if !load_art(art) do load_progressive_jpeg(art)
}

// NOTE: The odin compiled raylib version doesn't have jpeg enable for some reason SO...
// I use the image package to load the image from bytes if there's an error we just return
load_art :: proc(art: []u8) -> bool {
	img, ierr := image.load_from_bytes(art)
	if ierr != nil do return false
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
	return true
}

// NOTE: Odin's core:image library doesn't support progressive JPEGS that breaks my metadata-focused approach.
// Because of this restriction I use turbojpeg's handling as an alternative, when image errors
load_progressive_jpeg :: proc(art: []u8) -> bool {
	// initialize the turbojpeg decompression handler
	handler := tj.Init(i32(tj.INIT.DECOMPRESS))
	if handler == nil do return false
	defer tj.Destroy(handler)

	// get the data without opening the image yet
	if tj.DecompressHeader(handler, raw_data(art), len(art)) != 0 {
		fmt.eprintfln("turbojpeg error: %s", tj.GetErrorStr(handler))
		return false
	}
	// retrieve information needed for texture creation and decompression
	w := tj.Get(handler, i32(tj.PARAM.JPEGWIDTH))
	h := tj.Get(handler, i32(tj.PARAM.JPEGHEIGHT))
	px := make([]u8, w * h * 3)
	defer delete(px)

	// decompress the image
	if tj.Decompress8(handler, raw_data(art), len(art), raw_data(px), w * 3, i32(tj.PF.RGB)) != 0 {
		fmt.eprintfln("turbojpeg error: %s", tj.GetErrorStr(handler))
		return false
	}

	// now we convert our raw pixel data into the rl:Image
	rlimg := rl.Image {
		data    = raw_data(px),
		width   = w,
		height  = h,
		mipmaps = 1,
		format  = .UNCOMPRESSED_R8G8B8,
	}

	// convert the image into a texture load it and flip our art_loaded to true
	art_tex = rl.LoadTextureFromImage(rlimg)
	art_loaded = true
	return true
}
