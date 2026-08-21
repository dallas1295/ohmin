package main

import "core:fmt"
import "core:os"
import "core:strings"

library: [dynamic]string

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
			fmt.eprintf("skipping: %s: %v\n", err_path, err)
			continue
		}

		// convert the names to lower case for edgecase .MP4 vs .mp4 or .flac vs .FLAC
		// NOTE: Lowers delete should be changed to an eventual dynamic allocator when we start parsing
		// metadata for library
		lower, case_err := strings.to_lower(stuff.name)
		defer delete(lower)
		if case_err != nil {
			fmt.eprintf("Error converting path: %s:%v\n", stuff.name, case_err)
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
			append(&library, filepath)
		case:
			fmt.eprintf("skipping: %s", stuff.fullpath)
		}
	}
	return true
}


// delete our global library for shutdown
uninit_library :: proc() {
	for path in library {
		delete(path)
	}
	delete(library)
}
