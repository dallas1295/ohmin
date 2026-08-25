// TODO: volume, sorting out the library, progressive jpeg, cache library?, fix the time bar on the bottom, learn how to generate lists for clicking thoruhg

package main

import "core:fmt"
import "core:os"

import rl "vendor:raylib"

main :: proc() {
	// Get home envirment and attach default Music location (for now this is hardcoded)
	home := os.get_env("HOME", context.allocator)
	lib_path := fmt.aprintf("%s/Music", home)

	// Init the library at our ~/Music path
	lib_ok := init_library(lib_path)
	defer uninit_library()

	delete(lib_path)
	delete(home)

	if !lib_ok {
		fmt.printf("Error loading library, closing now..")
		return
	}

	// Initialize raylib
	rl.InitWindow(800, 600, "Ohmin Audio")

	// minimum window size so the bottom stack can't overlap the art/counter
	rl.SetWindowMinSize(640, 480)

	// Initialize the engine for playback
	if !engine_init() {
		fmt.eprintf("failed to initialize audio engine")
	}
	defer engine_close()

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)
		rl.BeginDrawing()

		rl.ClearBackground(rl.DARKGRAY)

		// easier to scale the UI with these
		w := f32(rl.GetScreenWidth())
		h := f32(rl.GetScreenHeight())

		rl.DrawText(rl.TextFormat("loaded: %d tracks", len(library)), 10, 60, 20, rl.BLACK)


		// put in the center of the window, scaled from whatever the cover size is
		if art_loaded {
			src := rl.Rectangle{0, 0, f32(art_tex.width), f32(art_tex.height)}
			dst := rl.Rectangle {
				f32(rl.GetScreenWidth() - 350) / 2,
				f32(rl.GetScreenHeight() - 350) / 2,
				350,
				350,
			}
			rl.DrawTexturePro(art_tex, src, dst, rl.Vector2{}, 0, rl.WHITE)
		}

		// now-playing nothing loaded until the first play, so guard on curr_idx
		if curr_idx >= 0 {
			// title via TextFormat zero-allocated
			// big title on top, artist--album under it, both left-justified
			rl.DrawText(
				rl.TextFormat("%s", library[curr_idx].title),
				10,
				i32(h - 85),
				28,
				rl.BLACK,
			)
			rl.DrawText(
				rl.TextFormat("%s -- %s", library[curr_idx].artist, library[curr_idx].album),
				10,
				i32(h - 50),
				20,
				rl.BLACK,
			)
		}

		// position text: "1:23 / 4:05"
		ctime := rl.TextFormat(
			"%d:%02d / %d:%02d",
			int(track_pos) / 60,
			int(track_pos) % 60,
			int(track_len) / 60,
			int(track_len) % 60,
		)

		// time right-justified, even with the artist--album line (h - 50)
		tw := i32(rl.MeasureText(ctime, 20))
		rl.DrawText(ctime, i32(w) - 10 - tw, i32(h - 50), 20, rl.BLACK)
		// progress bar, only once length is known (track_len > 0)
		if len_known {
			// bar right-justified under the time, width matches the time text
			bar_w := f32(tw) * (track_pos / track_len)
			rl.DrawRectangle(i32(w) - 10 - tw, i32(h - 25), i32(bar_w), 8, rl.BLACK)
		}

		rl.EndDrawing()

		key := rl.GetKeyPressed()
		#partial switch key {
		case .SPACE:
			play_pause()
		case .L:
			play_next()
		case .H:
			play_previous()
		case .EQUAL:
			toggle_autoplay()
		case:
		//Empty
		}

		handle_autoplay()
		handle_art()
	}

	if art_loaded {
		rl.UnloadTexture(art_tex)
	}

	rl.CloseWindow()
}
