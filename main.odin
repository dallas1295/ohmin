package main

import "core:fmt"
import "core:os"
import md "metadata"
import pl "player"
import rl "vendor:raylib"

KEY_REPEAT_DELAY :: 0.35
KEY_REPEAT_RATE :: 0.08

// This functions whole approach is to make up the gap in Raylib's key repeat logic
// repeat_key get's frame time to create an OS-like key repeat based on the globals defined below so i can change if i want
repeat_key :: proc(ft: ^f64, key: rl.KeyboardKey) -> bool {
	if rl.IsKeyPressed(key) {
		ft^ = -rl.GetTime()
		return true
	}
	if !rl.IsKeyDown(key) {
		return false
	}
	t := rl.GetTime()
	if ft^ < 0 {
		if t + ft^ >= KEY_REPEAT_DELAY {
			ft^ = t
			return true
		}
	} else if t - ft^ > KEY_REPEAT_RATE {
		ft^ = t
		return true
	}
	return false
}

main :: proc() {
	// Get home envirment and attach default Music location (for now this is hardcoded)
	home := os.get_env("HOME", context.allocator)
	lib_path := fmt.aprintf("%s/Music", home)

	// Init the library at our ~/Music path
	lib_ok := pl.init_library(lib_path)
	defer pl.uninit_library(); delete(lib_path)
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
	if !pl.engine_init() {
		fmt.eprintf("failed to initialize audio engine")
	}

	rep_up, rep_down: f64

	defer pl.engine_close()

	for !rl.WindowShouldClose() {
		free_all(context.temp_allocator)
		rl.BeginDrawing()

		rl.ClearBackground(rl.DARKGRAY)

		// easier to scale the UI with these
		w := f32(rl.GetScreenWidth())
		h := f32(rl.GetScreenHeight())

		rl.DrawText(rl.TextFormat("loaded: %d tracks", len(pl.library)), 10, 60, 20, rl.BLACK)


		// put in the center of the window, scaled from whatever the cover size is
		if md.art_loaded {
			src := rl.Rectangle{0, 0, f32(md.art_tex.width), f32(md.art_tex.height)}
			dst := rl.Rectangle{10, h - 105, 100, 100}
			rl.DrawTexturePro(md.art_tex, src, dst, rl.Vector2{}, 0, rl.WHITE)
		}

		// now-playing nothing loaded until the first play, so guard on curr_idx
		if pl.curr_idx >= 0 {
			// title via TextFormat zero-allocated
			// big title on top, artist--album under it, both left-justified
			rl.DrawText(
				rl.TextFormat("%s", pl.library[pl.curr_idx].title),
				120,
				i32(h - 85),
				28,
				rl.BLACK,
			)
			rl.DrawText(
				rl.TextFormat(
					"%s -- %s",
					pl.library[pl.curr_idx].artist,
					pl.library[pl.curr_idx].album,
				),
				120,
				i32(h - 50),
				20,
				rl.BLACK,
			)
		}

		// position text: "1:23 / 4:05"
		ctime := rl.TextFormat(
			"%d:%02d / %d:%02d",
			int(pl.track_pos) / 60,
			int(pl.track_pos) % 60,
			int(pl.track_len) / 60,
			int(pl.track_len) % 60,
		)

		// time right-justified, even with the artist--album line (h - 50)
		tw := i32(rl.MeasureText(ctime, 20))
		rl.DrawText(ctime, i32(w) - 10 - tw, i32(h - 50), 20, rl.BLACK)
		// progress bar, only once length is known (track_len > 0)
		if pl.len_known {
			// bar right-justified under the time, width matches the time text
			rl.DrawRectangle(120, i32(h - 25), i32(w - 125), 8, rl.GRAY)
			bar_w := (w - 125) * (pl.track_pos / pl.track_len)
			rl.DrawRectangle(120, i32(h - 25), i32(bar_w), 8, rl.BLACK)

		}

		vol := rl.TextFormat("%d:%%", int(pl.volume * 100))
		rl.DrawText(vol, (1 / 2), i32(h - 115), 5, rl.BLACK)
		rl.DrawRectangle(2, i32(h - 105), 5, 100, rl.GRAY)
		filled_h := 100 * pl.volume
		rl.DrawRectangle(2, i32((h - 5) - filled_h), 5, i32(filled_h), rl.BLACK)


		rl.EndDrawing()

		key := rl.GetKeyPressed()
		#partial switch key {
		case .SPACE:
			pl.play_pause()
		case .L:
			pl.play_next()
		case .RIGHT:
			pl.play_next()
		case .H:
			pl.play_previous()
		case .LEFT:
			pl.play_previous()
		case .EQUAL:
			pl.toggle_autoplay()
		case:
		//Empty
		}

		if repeat_key(&rep_down, .DOWN) {
			pl.volume_down()
		}
		if repeat_key(&rep_up, .UP) {
			pl.volume_up()
		}

		pl.handle_autoplay()
		if pl.curr_idx >= 0 {
			md.handle_art(pl.curr_idx, pl.library[pl.curr_idx].path)
		}
	}


	if md.art_loaded {
		rl.UnloadTexture(md.art_tex)
	}

	rl.CloseWindow()
}
