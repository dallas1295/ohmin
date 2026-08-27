package player

import md "../metadata"
import "core:fmt"
import "core:os"
import "core:sort"
import "core:strings"

library: [dynamic]md.Track


// Initial library sorting will only return every single song in ~/Music without sorting
init_library :: proc(lib_path: string) -> bool {
	w := os.walker_create(lib_path)
	defer os.walker_destroy(&w)
	for {

		// begin walking library, if something doesn't work continue
		stuff, ok := os.walker_walk(&w)
		if !ok {
			break
		}

		// this get's any errs from our walk prints them out and continues
		if err_path, err := os.walker_error(&w); err != nil {
			// DEBUG
			// fmt.eprintf("skipping: %s: %v\n", err_path, err)
			continue
		}

		// convert the names to lower case for edgecase .MP4 vs .mp4 or .flac vs .FLAC
		lower, case_err := strings.to_lower(stuff.name)
		defer delete(lower)
		if case_err != nil {
			// DEBUG
			// fmt.eprintf("Error converting path: %s:%v\n", stuff.name, case_err)
			return false
		}

		// if the extension is supported we append it to our library, if not we continue but note that we couldn't use it
		switch os.ext(lower) {
		case ".flac", ".mp3", ".wav":
			filepath, ferr := strings.clone(stuff.fullpath)
			if ferr != nil {
				fmt.eprintf("Error adding: %s, cause: %v\n", stuff.name, ferr)
				continue
			}
			track, terr := md.scan_track(filepath)
			if terr != nil {
				fmt.eprintfln("Error parsing file: %s, cause: %v", filepath, terr)
				delete(filepath)
				continue
			}

			append(&library, track)
		case:
		// fmt.eprintf("skipping: %s", stuff.fullpath)
		}
	}
	sort.quick_sort_proc(library[:], track_compare)
	return true
}


// delete our global library for shutdown
uninit_library :: proc() {
	for track in library {
		delete(track.path)
		delete(track.title)
		delete(track.artist)
		delete(track.album)
	}
	delete(library)
}
